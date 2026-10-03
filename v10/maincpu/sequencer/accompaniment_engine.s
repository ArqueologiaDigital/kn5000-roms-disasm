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
	calr	Rhythm_DispatchNote_Helper
	pop	xiz
	ret
Rhythm_DispatchNote_Helper:
	call	AccStyle_TempoLookupData_Helper
	ret

AccStyle_LookupTempoAndVelocity:
	push xhl
	push xwa
	xor xhl, xhl
	ld l, (0x90ea:16)
	cp l, 0xf
	jr ule, AccStyle_LookupTempo_ClampL
	xor l, l

AccStyle_LookupTempo_ClampL:
	sla l, 1
	ld xwa, AccStyle_TempoMultiplierTable
	ld	hl, (xwa+l)
	xor xwa, xwa
	ld a, (0x90eb:16)
	cp a, 0x4f
	jr ule, AccStyle_LookupTempo_AddAndStore
	xor a, a

AccStyle_LookupTempo_AddAndStore:
	add xhl, xwa
	sla xhl, 1
	add xhl, AccStyle_TempoWordTable
	ld wa, (xhl)
	ld (0x90ee:16), a
	ld (0x90ef:16), w
	pop xwa
	pop xhl
	ret

AccStyle_TempoMultiplierTable:
; AccStyle_TempoMultiplierTable (16 x LE16), 2026-09-02 (lane v10seq).
; AccStyle_LookupTempoAndVelocity: cp l,0xf else xor l,l / sla l,1 then
; ldw_sri off this label -- a WORD load at stride 2, and the bound gives
; exactly the 16 entries below: 0, 20, 40, ... 240, 260, 280, 360.
	.short 0x0000, 0x0014, 0x0028, 0x003c, 0x0050, 0x0064, 0x0078, 0x008c
	.short 0x00a0, 0x00b4, 0x00c8, 0x00dc, 0x00f0, 0x0104, 0x0118, 0x0168

AccStyle_LookupVelocityTable:
	push xhl
	push xwa
	cp (0x90ea:16), 128
	jr nc, AccStyle_Velocity_ExtendedRange
	xor xhl, xhl
	ld l, (0x90ea:16)
	sla xhl, 3
	xor xwa, xwa
	ld a, (0x90eb:16)
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, AccStyle_VelocityTableMain
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_ExtendedRange:
	cp (0x90ea:16), 240
	jr nc, AccStyle_Velocity_HighRange
	xor xhl, xhl
	ld l, (0x90ea:16)
	and l, 0x7f
	cp l, 0xb
	jr ule, AccStyle_Velocity_ExtClamp
	xor l, l

AccStyle_Velocity_ExtClamp:
	sla xhl, 3
	xor xwa, xwa
	ld a, (0x90eb:16)
	and a, 0x7
	add xhl, xwa
	sla xhl, 1
	add xhl, AccStyle_VelocityTableExt
	ld wa, (xhl)
	jr AccStyle_Velocity_StoreResult

AccStyle_Velocity_HighRange:
	xor xhl, xhl
	ld l, (0x90ea:16)
	and l, 0xf
	cp l, 4:i3
	jr ule, AccStyle_Velocity_HighClamp
	xor l, l

AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, AccStyle_VelocityTableHigh
	ld wa, (xhl)

AccStyle_Velocity_StoreResult:
	ld (0x90ee:16), a
	ld (0x90ef:16), w
	pop xwa
	pop xhl
	ret

AccStyle_CheckRecordMode:
	ld a, (0x32f1:16)
	cp a, 0xe
	jr nz, AccStyle_CheckRecordReturn
	ld a, (CURRENT_MODE:16)
	cp a, 0xe
	jr z, AccStyle_CheckRecordReturn
	or (0x34cd:16), 128

AccStyle_CheckRecordReturn:
	ret

AccStyle_DetectChanges:
	and (0x333b:16), 254
	bit 0, (0x3283:16)
	jrl nz, AccStyle_DetectChanges_CompareParams
	bit 1, (0x3283:16)
	jrl z, AccStyle_DetectChanges_CompareParams
	bit 4, (SEQ_TRANSPORT_STATE:16)
	jr z, AccStyle_DetectChanges_Init
	call NoteMap_SendAllNotesOff

AccStyle_DetectChanges_Init:
	ld (0x32e2:16), 0
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	call Rhythm_SendChanPressure
	calr Rhythm_SendResetMsg
	and (0x3314:16), 192
	and (0x3315:16), 192
	and (0x3312:16), 192
	and (0x3313:16), 192
	and (0x3316:16), 192
	and (0x3317:16), 192
	and (0x3318:16), 192
	and (0x335d:16), 192
	and (0x3326:16), 192
	and (0x3327:16), 192
	and (0x3284:16), 231
	xor a, a
	ld (0x3309:16), a
	ld (0x330a:16), a
	ld (0x330b:16), a
	ld (0x330c:16), a
	ld (0x330d:16), a
	ld (0x330e:16), a
	ld (0x330f:16), a
	ld (0x332b:16), 0
	and (0x3470:16), 2
	and (0x3329:16), 192
	ld a, (0xfc5f:16)
	and a, 0xfc
	jr z, AccStyle_DetectChanges_QueueDone
	and (0xfc5f:16), 3
	ld a, 0x0:opc
	ld w, 0x0:opc
	ld d, 0x5:opc
	ld e, 0x48:opc
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_QueueDone:
	bit 2, (0xfc60:16)
	jr z, AccStyle_DetectChanges_MarkDirty
	and (0xfc60:16), 251
	ld a, 0x0:opc
	ld w, 0x0:opc
	ld d, 0x6:opc
	ld e, 0x48:opc
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_MarkDirty:
	or (0x333b:16), 1

AccStyle_DetectChanges_CompareParams:
	bit 0, (0x32f3:16)
	jr nz, AccStyle_Compare_StyleNumber
	call Rhythm_SendChanPressure
	or (0x333b:16), 1
	jrl AccStyle_DetectChanges_Epilogue

AccStyle_Compare_StyleNumber:
	ld a, (0x32f5:16)
	cp a, (0x32f6:16)
	jr z, AccStyle_Compare_StyleNumDone
	or (0x333b:16), 1

AccStyle_Compare_StyleNumDone:
	ld a, (0x32f7:16)
	cp a, (0x32f8:16)
	jr z, AccStyle_Compare_Variation
	or (0x333b:16), 1

AccStyle_Compare_Variation:
	ld a, (0x32f9:16)
	and a, 0x7
	cp a, (0x32fa:16)
	jr z, AccStyle_Compare_VariationDone
	or (0x333b:16), 1

AccStyle_Compare_VariationDone:
	bit 7, (0x34cd:16)
	jr z, AccStyle_Compare_RegistrationFlag
	and (0x34cd:16), 127
	or (0x333b:16), 1

AccStyle_Compare_RegistrationFlag:
	ld a, (0x3335:16)
	xor a, (0x32f2:16)
	and a, 0x2
	cp a, 0:i3
	jr z, AccStyle_Compare_SplitA
	or (0x333b:16), 1
	jr AccStyle_DetectChanges_Epilogue

AccStyle_Compare_SplitA:
	ld a, (0x32ff:16)
	cp a, (0x3300:16)
	jr z, AccStyle_Compare_SplitADone
	or (0x333b:16), 1

AccStyle_Compare_SplitADone:
	ld a, (0x3301:16)
	cp a, (0x3302:16)
	jr z, AccStyle_Compare_LayerA
	or (0x333b:16), 1

AccStyle_Compare_LayerA:
	ld a, (0x3305:16)
	cp a, (0x3306:16)
	jr z, AccStyle_Compare_LayerADone
	or (0x333b:16), 1

AccStyle_Compare_LayerADone:
	ld a, (0x3307:16)
	cp a, (0x3308:16)
	jr z, AccStyle_Compare_TuningState
	or (0x333b:16), 1

AccStyle_Compare_TuningState:
	ld a, (0x33e8:16)
	xor a, (0x33e9:16)
	bit 0, a
	jr z, AccStyle_Compare_TuningDone
	or (0x333b:16), 1

AccStyle_Compare_TuningDone:
	call AccTuning_Toggle

AccStyle_DetectChanges_Epilogue:
	bit 0, (0x333b:16)
	jr z, AccStyle_DetectChanges_ClearFlags
	calr AccStyle_ApplyChanges

AccStyle_DetectChanges_ClearFlags:
	ld (0x3354:16), 0
	ld (0x3355:16), 0
	ld (0x335f:16), 0
	and (0x3357:16), 252
	and (0x3361:16), 120
	ret

AccStyle_ApplyChanges:
	calr AccStyle_ResetAllVoiceState
	and (0x3283:16), 251
	ld (1122:16), 0
	calr AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	ld a, (0x32f7:16)
	and a, 0x7f
	and a, 0x7
	ld (0x32e6:16), a
	ld (0x32e8:16), a
	ld a, (0x32f5:16)
	ld (0x32e5:16), a
	ld (0x32e7:16), a
	ld (0x3370:16), a
	call AccTuning_Init
	cp (0x32e5:16), 128
	jr nc, AccStyle_ApplyChanges_Extended
	calr AccStyle_ApplyStandardStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Extended:
	calr AccStyle_ApplyExtendedStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Finalize:
	calr AccBuf_InitKbd1WithMarkers
	ld a, (1075:16)
	ld (1112:16), a
	ld (0x32ec:16), 1
	call Rhythm_ProcessAllPartsAndLoad
	ret

AccStyle_ResetAllVoiceState:
	xor wa, wa
	ld (1045:16), a
	ld (1046:16), a
	ld (0x327f:16), a
	ld (0x3280:16), a
	ld (0x327d:16), wa
	ld (0x3328:16), a
	ld (0x32ab:16), a
	ld (0x32ac:16), a
	ld (0x32b1:16), a
	ld (0x32ad:16), a
	ld (0x32ae:16), a
	ld (0x32af:16), a
	ld (0x32b0:16), a
	ld (1076:16), a
	ld (1077:16), a
	ld (0x32b4:16), a
	ld (0x32b5:16), a
	ld (0x32b6:16), a
	ld (0x32bb:16), a
	ld (0x32b7:16), a
	ld (0x32b8:16), a
	ld (0x32b9:16), a
	ld (0x32ba:16), a
	ld (0x334d:16), a
	ld (0x32bd:16), a
	ld (0x32be:16), a
	ld (0x32bf:16), a
	ld (0x32c0:16), a
	ld (0x32c1:16), a
	ld (0x32c2:16), a
	ld (0x3385:16), a
	ld (0x3386:16), a
	ld (0x3387:16), a
	ld (0x3388:16), a
	ld (0x3389:16), a
	ld (0x338a:16), a
	call AccTone_CallWithSaveAll
	ret

AccStyle_ApplyStandardStyle:
	ld a, (0x3305:16)
	and a, 0x3
	ld (0x3338:16), a
	ld (0x333a:16), a
	ld a, (0x32e5:16)
	ld h, (0x32e6:16)
	call AccVoice_LookupWithOffset
	ld (0x32ce:16), xiy
	call AccVoice_SelectAndApplyPatch
	call AccVoice_ReadBankAssign
	ld xiy, (0x32ce:16)
	call Rhythm_UpdateTuningConfig
	ld xiy, (0x32ce:16)
	ld a, (0x32ff:16)
	and a, 0x7
	jr z, AccStyle_ApplyStd_LoadTuning
	calr AccVoice_SelectPartOffset
	jr AccStyle_ApplyStd_Return

AccStyle_ApplyStd_LoadTuning:
	calr AccStyle_SetupPartAddresses
	ld a, (0x32a3:16)
	ld w, 0x0:opc
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	or (0x332c:16), 63

AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	ld	a, (xiy+977)
	ld (0x3285:16), a
	ld (0x33d4:16), 1
	ld a, (0x32a3:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3287:16), wa
	ld (0x33d4:16), 2
	ld a, (0x32a4:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3289:16), wa
	ld (0x33d4:16), 4
	ld a, (0x32a5:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328b:16), wa
	ld (0x33d4:16), 8
	ld a, (0x32a6:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328d:16), wa
	ld (0x33d4:16), 16
	ld a, (0x32a7:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328f:16), wa
	ld (0x33d4:16), 32
	ld a, (0x32a8:16)
	calr AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3291:16), wa
	ld xwa, AccStyle_DefaultStream
	add xwa, 0x6
	ld (0x3293:16), xwa
	and (0x3316:16), 192
	and (0x3317:16), 192
	and (0x3318:16), 192
	ret

AccStyle_ApplyExtendedStyle:
	ld xiy, AccStyle_ExtStyleMap
	ld a, (0x32e5:16)
	and a, 0x7f
	cp a, 0x1d
	jr ule, AccStyle_ApplyExt_ClampIndex
	xor a, a

AccStyle_ApplyExt_ClampIndex:
	ld	a, (xiy+a)
	ld (0x3338:16), a
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	ld (0x32ce:16), xiy
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
	ld (0x32d3:16), xiy
	call AccVoice_SelectAndApplyPatch
	ld w, (0x32e5:16)
	call AccPatch_SetByChordIndex
	bit 0, (0x3363:16)
	jr nz, AccStyle_ApplyExt_CheckSplit
	call AccPedal_ProcessAllChanges

AccStyle_ApplyExt_CheckSplit:
	ld a, (0x32ff:16)
	and a, 0x7
	jrl z, Seq_ProcessAndContinue
	bit 0, (0x3363:16)
	jrl z, AccStyle_ApplyExt_SelectPart
	bit 1, (0x32ff:16)
	jr z, AccStyle_ApplyExt_CheckBit0
	ld a, (1075:16)
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 0, 0x03, 0xec, 0xe0
	jr z, AccStyle_ApplyExt_SelectPart
	and (0x32ff:16), 253
	and (0xfc5f:16), 247
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit0:
	bit 0, (0x32ff:16)
	jr z, AccStyle_ApplyExt_CheckBit1
	ld a, (0x3364:16)
	cp a, (1075:16)
	jr z, AccStyle_ApplyExt_UseSecondary
	and (0x32ff:16), 254
	and (0xfc5f:16), 251
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	jr Seq_ProcessAndContinue

AccStyle_ApplyExt_CheckBit1:
	ld a, (0x3366:16)
	cp a, (1075:16)
	jr z, AccStyle_ApplyExt_UseSecondary
	and (0x32ff:16), 251
	and (0xfc60:16), 251
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
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
	ld xiy, (0x32d3:16)
	calr AccVoice_SelectPartOffset

AccStyle_ApplyExt_UpdateTuning:
	ld xiy, (0x32d3:16)
	calr Rhythm_UpdateTuningConfig
	ret

AccVoice_SelectPartOffset:
	ldw hl, 0x20
	bit 0, (0x32ff:16)
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x22
	bit 1, (0x32ff:16)
	jr nz, AccVoice_SelectPartOffset_Resolved
	ldw hl, 0x420

AccVoice_SelectPartOffset_Resolved:
	calr AccStyle_SetupPartAddressesByHL
	cp (0x32e5:16), 128
	jr c, AccVoice_SelectPartOffset_Bound
	ld xiy, (0x32ce:16)
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_SelectPartOffset_Apply63

AccVoice_SelectPartOffset_Bound:
	ld a, (0x32a3:16)
	ld w, 0x3:opc
	bit 2, (0x32ff:16)
	jr z, AccVoice_SelectPartOffset_SetModeW
	ld w, 0x4:opc

AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	or (0x332c:16), 63
	bit 0, (0x32ff:16)
	jr z, AccVoice_SelectPartOffset_Bit1
	or (0x3316:16), 63
	and (0x3317:16), 192
	and (0x3318:16), 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Bit1:
	bit 1, (0x32ff:16)
	jr z, AccVoice_SelectPartOffset_Mode3
	and (0x3316:16), 192
	or (0x3317:16), 63
	and (0x3318:16), 192
	jr AccVoice_SelectPartOffset_Return

AccVoice_SelectPartOffset_Mode3:
	and (0x3316:16), 192
	and (0x3317:16), 192
	or (0x3318:16), 63

AccVoice_SelectPartOffset_Return:
	ret

AccStyle_SetupPartAddressesByHL:
	ld	a, (xiy+977)
	ld (0x3285:16), a
	ldfr_werp HL, 0x3c
	ld (0x33d4:16), 1
	call AccPart_GetParamAddr
	ld (0x3287:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 2
	call AccPart_GetParamAddr
	ld (0x3289:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 4
	call AccPart_GetParamAddr
	ld (0x328b:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 8
	call AccPart_GetParamAddr
	ld (0x328d:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 16
	call AccPart_GetParamAddr
	ld (0x328f:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 32
	call AccPart_GetParamAddr
	ld (0x3291:16), wa
	ld xwa, AccStyle_DefaultStream
	add xwa, 0x6
	ld (0x3293:16), xwa
	ret

AccStyle_UseSecondarySource:
	ld a, (0x3365:16)
	bit 0, (0x32ff:16)
	jr nz, AccStyle_UseSecondary_Resolve
	ld a, (0x3367:16)

AccStyle_UseSecondary_Resolve:
	call AccVoice_ResolveParamAddr
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	bit 0, (0x32ff:16)
	jr z, AccStyle_UseSecondary_Mode3
	or (0x3316:16), 63
	and (0x3317:16), 192
	and (0x3318:16), 192
	jr AccStyle_UseSecondary_Return

AccStyle_UseSecondary_Mode3:
	and (0x3316:16), 192
	and (0x3317:16), 192
	or (0x3318:16), 63

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
	ld xwa, AccStyle_DefaultStream
	add xwa, 0x6
	ld (0x3293:16), xwa
	ret

AccPart_ResetAndCopyTuning:
	ld xiy, (0x32ce:16)
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	and (0x3316:16), 192
	and (0x3317:16), 192
	and (0x3318:16), 192
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
	ld	(xhl+iy), 0xd0
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x01
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x10
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x01
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

Rhythm_SendResetMsg:
	ld a, 0xd8:opc
	ld w, 0x10:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	ld w, (0x32d8:16)
	ld a, (0x3338:16)
	calr Rhythm_LookupTuningByStyle
	ld (0x32a3:16), a
	ld (0x32a4:16), a
	ld (0x32a5:16), a
	ld (0x32a6:16), a
	ld (0x32a7:16), a
	ld (0x32a8:16), a
	ld w, (0x32d8:16)
	ld a, (0x3338:16)
	calr Rhythm_LookupTuningRange
	ret

Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, Rhythm_LookupTuningByStyle_Data
	ld	a, (xhl+a)
	ret

Rhythm_LookupTuningRange:
	cp (0x32e5:16), 128
	jr nc, Rhythm_LookupTuning_DefaultRange
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, Rhythm_LookupTuningRange_Data
	sla a, 1
	ld	hl, (xhl+a)
	ld	wa, (xiy+hl)
	jr Rhythm_StoreTuningRange

Rhythm_LookupTuning_DefaultRange:
	ld a, 0x39:opc
	ld w, 0x39:opc

Rhythm_StoreTuningRange:
	ld (0x333f:16), a
	ld (0x3340:16), w
	ret

Rhythm_LookupStyleIndex:
	ld xhl, Rhythm_LookupStyleIndex_Data
	cp w, 0x30
	jr c, Rhythm_LookupStyleIndex_Compute
	xor w, w

Rhythm_LookupStyleIndex_Compute:
	ld	w, (xhl+w)
	and w, 0x3
	ld xhl, Rhythm_LookupStyleIndex_Compute_Data
	ld	l, (xhl+w)
	xor h, h
	ret

AccVoice_LookupParamIndex:
	push xhl
	ld xhl, AccVoice_ParamIndexData
	and wa, 0x3
	ld	a, (xhl+wa)
	pop xhl
	ret

AccVoice_ParamIndexData:
; RE-FRAMED 2026-09-02 (lane v10seq). Was 60 lines of mnemonics
; (nop / pop sr / reti / add hl 994 / ldio / halt) with 18 undecodable
; bytes wedged between them as .byte. It is DATA: all five references to
; this block -- AccVoice_ParamIndexData and the positional labels +0x26
; +0x57 +0x5B +0x63 -- are `ld xhl, <label>`, an address taken; nothing
; in v10/maincpu calls or jumps to any of them.
; The layout below is the readers own indexing, and the bytes corroborate
; it: the +0x26 segment is exactly 48 entries long, matching its reader
; `cp w,0x30` bound, and holds nothing but 0/1/2; +0x5B is the ramp
; 0,5,10,...,35; and +0x63 reads as 8 LE16 words (0x03D2..0x03D8 then
; 0x07D2..0x07D8), matching its reader `sla a,1`.
; +0x00 (4 B). AccVoice_LookupParamIndex: ld xhl <here> / and wa 0x3 / ldb_sri -> byte[wa&3]
	.byte 0x00, 0x03, 0x04, 0x07	; |....|
; +0x04 (34 B). No reader found: nothing in the tree names this offset
	.byte 0xdb, 0xc8, 0xe2, 0x03, 0xd8, 0x12, 0xd7, 0x30, 0x98, 0xd8, 0x83, 0xc3, 0x07, 0xf4, 0xec, 0x21	; |.......0.......!|
	.byte 0xc9, 0xcf, 0xff, 0x6e, 0x0c, 0xd7, 0x30, 0x88, 0xd8, 0xc8, 0xe2, 0x03, 0xc3, 0x07, 0xf4, 0xe0	; |...n..0.........|
	.byte 0x21, 0x0e	; |!.|
; +0x26 (48 B). Rhythm_LookupStyleIndex: cp w 0x30 else xor w w / ldb_sri -> byte[w] with w < 48. Every value is 0 1 or 2
Rhythm_LookupStyleIndex_Data:
	.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01	; |................|
	.byte 0x01, 0x01, 0x01, 0x01, 0x02, 0x01, 0x01, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01	; |................|
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00	; |................|
; +0x56 (1 B). Gap between the 48-entry table and the next
	.byte 0x00	; |.|
; +0x57 (4 B). Rhythm_LookupStyleIndex: and w 0x3 / ldb_sri -> byte[w&3]
Rhythm_LookupStyleIndex_Compute_Data:
	.byte 0x00, 0x08, 0x04, 0x0c	; |....|
; +0x5B (8 B). Rhythm_LookupTuningByStyle: ldb_sri -> byte[a]. Ramp 0 5 10 ... 35
Rhythm_LookupTuningByStyle_Data:
	.byte 0x00, 0x05, 0x0a, 0x0f, 0x14, 0x19, 0x1e, 0x23	; |.......#|
; +0x63 (8 x LE16). Rhythm_LookupTuningRange: sla a 1 / ldw_sri -> word[a]
Rhythm_LookupTuningRange_Data:
	.short 0x03d2, 0x03d4, 0x03d6, 0x03d8, 0x07d2, 0x07d4, 0x07d6, 0x07d8

AccPart_GetVoiceParamOffsetTable:
	ld xhl, AccPart_VoiceParamDispatchTable
	ldfr_berp W, 0x31
	extz wa
	sla wa, 2
	ld	xhl, (xhl+wa)
	ldto_berp W, 0x31
	sla w, 1
	ld	hl, (xhl+w)
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
	; data, not code: AccPart_VoiceParamOffsets_BaseA is reached only as data (15 data), and its instruction decode held halt, normal (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x00, 0x00, 0x62, 0x00, 0xc4, 0x00, 0x26, 0x01, 0x26, 0x05, 0x57, 0x01, 0x57, 0x05
AccPart_VoiceParamOffsets_BaseB:
	; data, not code: AccPart_VoiceParamOffsets_BaseB is reached only as data (5 data), and its instruction decode held halt (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x31, 0x00, 0x93, 0x00, 0xf5, 0x00, 0x26, 0x01, 0x26, 0x05, 0x57, 0x01, 0x57, 0x05
AccPart_VoiceParamOffsets_ChordA:
	; data, not code: AccPart_VoiceParamOffsets_ChordA is reached only as data (15 data), and its instruction decode held halt, max (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x00, 0x04, 0x62, 0x04, 0xc4, 0x04, 0x26, 0x01, 0x26, 0x05, 0x57, 0x01, 0x57, 0x05
AccPart_VoiceParamOffsets_ChordB:
	; data, not code: AccPart_VoiceParamOffsets_ChordB is reached only as data (5 data), and its instruction decode held halt (scripts/converters/data_as_code_to_bytes.py).
	.byte	0x31, 0x04, 0x93, 0x04, 0xf5, 0x04, 0x26, 0x01, 0x26, 0x05, 0x57, 0x01, 0x57, 0x05

AccPart_LookupBoundVoiceParam:
	ld w, a
	calr AccStyle_ReadParamOffset
	ld xhl, AccPart_LookupBoundVoiceParam_Data
	cp a, 0x14
	jr c, AccPart_LookupBound_ComputeIdx
	ld xhl, AccPart_LookupBoundVoiceParam_Data_2

AccPart_LookupBound_ComputeIdx:
	sla w, 1
	ld	hl, (xhl+w)
	ret

AccStyle_ReadParamOffset:
	ld xhl, AccStyle_ReadParamOffset_Data
	sla w, 1
	ld	hl, (xhl+w)
	extz xhl
	add xhl, xiy
	cp (0x33d4:16), 1
	jr nz, AccStyle_ReadParamOff_Part2
	ld w, (xhl + 0:8)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part2:
	cp (0x33d4:16), 2
	jr nz, AccStyle_ReadParamOff_Part4
	ld w, (xhl + 0:8)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part4:
	cp (0x33d4:16), 4
	jr nz, AccStyle_ReadParamOff_Part8
	ld w, (xhl + 40)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part8:
	cp (0x33d4:16), 8
	jr nz, AccStyle_ReadParamOff_Part16
	ld w, (xhl + 80)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part16:
	cp (0x33d4:16), 16
	jr nz, AccStyle_ReadParamOff_Part32
	ld w, (xhl + 120)
	jr AccStyle_ReadParamRet

AccStyle_ReadParamOff_Part32:
	ld	w, (xhl+160)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	ld	xhl, AccStyle_ReadParamOffset_Data
	sla	a, 1
	ld	hl, (xhl+a)
	extz xhl
	add	xhl, xiy
	cp	(0x33d4:16), 1
	jr	nz, AccStyle_ReadParamOffset_Entry
	ld	a, (xhl+20)
	jr	AccStyle_ReadParamOffset_Return
AccStyle_ReadParamOffset_Entry:
	cp	(0x33d4:16), 2
	jr	nz, AccStyle_ReadParamOffset_Entry2
	ld	a, (xhl+20)
	jr	AccStyle_ReadParamOffset_Return
AccStyle_ReadParamOffset_Entry2:
	cp	(0x33d4:16), 4
	jr	nz, AccStyle_ReadParamOffset_Skip
	ld	a, (xhl+60)
	jr	AccStyle_ReadParamOffset_Return
AccStyle_ReadParamOffset_Skip:
	cp	(0x33d4:16), 8
	jr	nz, AccStyle_ReadParamOffset_Skip2
	ld	a, (xhl+100)
	jr	AccStyle_ReadParamOffset_Return
AccStyle_ReadParamOffset_Skip2:
	cp	(0x33d4:16), 16
	jr	nz, AccStyle_ReadParamOffset_Skip3
	ld	a, (xhl+140)
	jr	AccStyle_ReadParamOffset_Return
AccStyle_ReadParamOffset_Skip3:
	cp	(0x33d4:16), 32
	jr	nz, AccStyle_ReadParamOffset_Return
	ld a, (xhl+180)
AccStyle_ReadParamOffset_Return:
	ret
; AccStyle_ByteDataBlock +0x5C..+0xCB -- three tables of LE16 byte offsets into
; a style record (the offsets below are relative to AccStyle_ByteDataBlock,
; whose first 0x5C bytes are the routine above).
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/max/normal/`retd 4096`...
; mnemonics (data-as-code).  Readers:
;   AccStyle_ReadParamOffset: ld xhl, AccStyle_ReadParamOffset_Data / sla w,1 /
;       ldw_sri hl,(xhl+w) / extz xhl / add xhl,xiy -- entry W, a 16-bit
;       offset added to the style pointer XIY (the routine at
;       AccStyle_ByteDataBlock does the same with A).
;   AccPart_LookupBoundVoiceParam: xhl = AccPart_LookupBoundVoiceParam_Data when
;       A < 0x14, else AccPart_LookupBoundVoiceParam_Data_2; sla w,1 / ldw_sri hl,(xhl+w).
; The +0x5C table holds 0..19 and then 0x400..0x413 (a second bank 1 KB
; further on); +0xAC and +0xBC are the same two banks at stride 2.  Sizes:
; the reader offsets pin +0x5C at 40 entries and +0xAC at 8; +0xBC is the 16
; bytes up to AccVoice_ComputeParamAddr.
; readers in v9/v10 (address from the linked ELF): AccStyle_ReadParamOffset 0xF5659B,
;     AccPart_LookupBoundVoiceParam 0xF5657E
; +0x5C  40 x LE16: 0..19, then 0x400..0x413
AccStyle_ReadParamOffset_Data:
	.short 0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007, 0x0008, 0x0009
	.short 0x000a, 0x000b, 0x000c, 0x000d, 0x000e, 0x000f, 0x0010, 0x0011, 0x0012, 0x0013
	.short 0x0400, 0x0401, 0x0402, 0x0403, 0x0404, 0x0405, 0x0406, 0x0407, 0x0408, 0x0409
	.short 0x040a, 0x040b, 0x040c, 0x040d, 0x040e, 0x040f, 0x0410, 0x0411, 0x0412, 0x0413
; +0xAC  8 x LE16: 0, 2, 4 ... 14
AccPart_LookupBoundVoiceParam_Data:
	.short 0x0000, 0x0002, 0x0004, 0x0006, 0x0008, 0x000a, 0x000c, 0x000e
; +0xBC  8 x LE16: 0x400, 0x402 ... 0x40E
AccPart_LookupBoundVoiceParam_Data_2:
	.short 0x0400, 0x0402, 0x0404, 0x0406, 0x0408, 0x040a, 0x040c, 0x040e

AccVoice_ComputeParamAddr:
	cp a, 0xf
	jr nc, AccVoice_ParamAddr_Range0F_14
	ldw hl, 0x18
	bit 0, (0x3309:16)
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1a
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range0F_14:
	cp a, 0x14
	jr nc, AccVoice_ParamAddr_Range14_23
	ldw hl, 0x1c
	bit 0, (0x3309:16)
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x1e
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range14_23:
	cp a, 0x23
	jr nc, AccVoice_ParamAddr_Range23Plus
	ldw hl, 0x418
	bit 0, (0x3309:16)
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41a
	jr AccVoice_ReturnExtHL

AccVoice_ParamAddr_Range23Plus:
	ldw hl, 0x41c
	bit 0, (0x3309:16)
	jr nz, AccVoice_ReturnExtHL
	ldw hl, 0x41e

AccVoice_ReturnExtHL:
	extz xhl
	ret

AccTuning_SetAllFromLookup:
	calr AccTuning_FetchValue
	ld (0x32a3:16), a
	ld (0x32a4:16), a
	ld (0x32a5:16), a
	ld (0x32a6:16), a
	ld (0x32a7:16), a
	ld (0x32a8:16), a
	ret

AccTuning_FetchValue:
	ld xhl, AccTuning_ValueTable
	ld	a, (xhl+a)
	ret

AccTuning_ValueTable:
; AccTuning_ValueTable -- 40 x u8, value = 5 * (index / 5): five 0s, five 5s, ...
; five 35s.  ** RE-TYPED 2026-09-25 (lane accomp): was nop/halt/`ldw (10:8)`...
; mnemonics (data-as-code).  Read by AccTuning_FetchValue:
;     ld xhl, AccTuning_ValueTable / ld_rr8b a, xhl, a (= ld a,(xhl+a)) / ret
; i.e. entry A, returned in A.  Callers: AccTuning_SetAllFromLookup (stores it
; to the six bytes 0x32a3..0x32a8) and two more `call AccTuning_FetchValue`.
; 40 entries: the table ends where AccVoice_ProcessAllSixParts begins (its
; first byte, 0x1E, is a `calr`), and the step-of-5 pattern is complete at 40.
; readers in v9/v10 (address from the linked ELF): AccTuning_FetchValue 0xF5671E
; -- comments that sat inside this range before the re-type, in order:
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5672F-0xF56747 (24 B), unreached CODE-territory, was disassembled as 16 plausible-but-dead instruction lines; per=64% dist=5 near AccTuning_ValueTable+6
	.byte 0, 0, 0, 0, 0, 5, 5, 5, 5, 5
	.byte 10, 10, 10, 10, 10, 15, 15, 15, 15, 15
	.byte 20, 20, 20, 20, 20, 25, 25, 25, 25, 25
	.byte 30, 30, 30, 30, 30, 35, 35, 35, 35, 35

AccVoice_ProcessAllSixParts:
	calr AccVoice_SavePartState1
	calr AccVoice_ProcessEventLoop
	calr AccVoice_RestorePartState1
	ret

AccVoice_SavePartState1:
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x1:opc
	ld (0x33d4:16), a
	ld wa, (0x3297:16)
	ld (0x33d6:16), wa
	ld wa, (0x3287:16)
	ld (0x33d8:16), wa
	ld a, (0x32b5:16)
	ld (0x33da:16), a
	ld a, (0x32ab:16)
	ld (0x33db:16), a
	ld a, (0x32a3:16)
	ld (0x33d5:16), a
	ld a, (0x33eb:16)
	ld (0x33ea:16), a
	ret

AccVoice_RestorePartState1:
	ld wa, (0x33d6:16)
	ld (0x3297:16), wa
	ld wa, (0x33d8:16)
	ld (0x3287:16), wa
	ld a, (0x33da:16)
	ld (0x32b5:16), a
	ld a, (0x33db:16)
	ld (0x32ab:16), a
	ld a, (0x33d5:16)
	ld (0x32a3:16), a
	ld a, (0x33ea:16)
	ld (0x33eb:16), a
	ret


; -----------------------------------------------------------------------------
; Section: Voice Event Processing
; -----------------------------------------------------------------------------
; Per-voice event loop, event dispatch, and
; sound patch handling.
; -----------------------------------------------------------------------------

AccVoice_ProcessEventLoop:
	bit 0, (0x32f4:16)
	jr z, AccVoice_EventLoop_Active
	jr AccVoice_EventLoop_Idle

AccVoice_EventLoop_Active:
	calr AccVoice_DispatchByChannel
	bit 0, (0x32f4:16)
	jr z, AccVoice_EventLoop_Dispatch
	jr AccVoice_EventProcessingReturn

AccVoice_EventLoop_Dispatch:
	ld w, (0x33d4:16)
	ld iz, (0x33d6:16)
	call AccVoice_SelectByMask
	ld iy, (0x33d8:16)
	ld	a, (xhl+iy)
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
	cp (0x33d4:16), 1
	jr nz, AccVoice_DispatchCh_Kbd2
	bit 0, (0x332c:16)
	jr z, SoundPatch_NullRet
	calr AccKbd1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Kbd2:
	cp (0x33d4:16), 2
	jr nz, AccVoice_DispatchCh_Acc1
	bit 1, (0x332c:16)
	jr z, SoundPatch_NullRet
	calr AccKbd2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc1:
	cp (0x33d4:16), 4
	jr nz, AccVoice_DispatchCh_Acc2
	bit 2, (0x332c:16)
	jr z, SoundPatch_NullRet
	call AccCh1_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc2:
	cp (0x33d4:16), 8
	jr nz, AccVoice_DispatchCh_Acc3
	bit 3, (0x332c:16)
	jr z, SoundPatch_NullRet
	call AccCh2_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc3:
	cp (0x33d4:16), 16
	jr nz, AccVoice_DispatchCh_Acc4
	bit 4, (0x332c:16)
	jr z, SoundPatch_NullRet
	call AccCh3_ProcessNotes
	jr SoundPatch_NullRet

AccVoice_DispatchCh_Acc4:
	cp (0x33d4:16), 32
	jr nz, SoundPatch_NullRet
	bit 5, (0x332c:16)
	jr z, SoundPatch_NullRet
	call AccCh4_ProcessNotes
	jr SoundPatch_NullRet

SoundPatch_NullRet:
	ret

AccVoice_AdvanceAndCheckEnd:
	calr AccBuf_AdvanceNoPage
	inc 1, (0x32ed:16)
	cp (0x32ed:16), 32
	jr nz, AccVoice_AdvanceAndCheck_Return
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	ld (0x32f5:16), 255
	or (0x32f4:16), 33

AccVoice_AdvanceAndCheck_Return:
	ret

AccVoice_HandleNoteOnEvent:
	calr AccVoice_AdvanceWithSave
	ld w, (0x33db:16)
	calr AccVoice_LookupTableAddress
	ld bc, (0x327d:16)
	ld w, (0x33da:16)
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_NoteOn_InRange
	or (0x32f4:16), 1
	jr AccVoice_NoteOn_Return

AccVoice_NoteOn_InRange:
	calr AccMidi_Dispatch

AccVoice_NoteOn_Return:
	ret

AccVoice_HandleBarEndEvent:
	bit 1, (0x32f4:16)
	jr z, AccVoice_BarEnd_Process
	or (0x32f4:16), 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_Process:
	ld w, (0x33db:16)
	calr AccVoice_LookupExtParamAddr
	ld bc, (0x327d:16)
	ld w, (0x33da:16)
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccVoice_BarEnd_InRange
	or (0x32f4:16), 1
	jrl AccVoice_NullRet

AccVoice_BarEnd_InRange:
	or (0x32f4:16), 2
	ld a, (0x33db:16)
	inc 1, a
	ld w, a
	and a, 0xf
	cp a, (1075:16)
	jr z, AccVoice_BarEnd_NextPage
	ld (0x33db:16), w
	calr AccBuf_AdvanceNoPage
	jrl AccVoice_NullRet

AccVoice_BarEnd_NextPage:
	and w, 0xf0
	add w, 0x10
	ld (0x33db:16), w
	inc 1, (0x33da:16)
	calr AccBuf_AdvanceNoPage
	call AccVoice_IncrementBarWithSave
	calr AccPart_Reactivate
	and (0x3361:16), 251
	bit 0, (0x330c:16)
	jr nz, AccVoice_BarEnd_CheckChord94
	ld a, (0x330b:16)
	and a, 0x3
	jr z, AccVoice_BarEnd_CheckChord65

AccVoice_BarEnd_CheckChord94:
	ld a, (0x33d4:16)
	and a, (0x3326:16)
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckChord65:
	ld a, (0x3309:16)
	and a, 0x3
	jr nz, AccVoice_BarEnd_CheckChord95
	ld a, (0x330a:16)
	and a, 0xd
	jr z, AccVoice_BarEnd_CheckSync69

AccVoice_BarEnd_CheckChord95:
	ld a, (0x33d4:16)
	and a, (0x3327:16)
	jr nz, AccVoice_SetChordChangeFlags

AccVoice_BarEnd_CheckSync69:
	bit 0, (0x330d:16)
	jr nz, AccVoice_SetChordChangeFlags
	ld a, (0x335c:16)
	and a, 0x3f
	jr z, AccVoice_NullRet
	bit 7, (0x3361:16)
	jr nz, AccVoice_SetChordChangeFlags
	jr AccVoice_NullRet


; -----------------------------------------------------------------------------
; Section: Chord, Table & Address Lookup
; -----------------------------------------------------------------------------
; Chord change flags, voice table address lookup,
; and buffer advance routines.
; -----------------------------------------------------------------------------

AccVoice_SetChordChangeFlags:
	or (0x32f3:16), 128
	or (0x32f4:16), 1
	ld a, (0x3312:16)
	or a, (0x3313:16)
	and a, 0x3f
	jr z, AccVoice_NullRet
	bit 0, (0x3301:16)
	jr z, AccVoice_NullRet
	and (0x330e:16), 252
	or (0x330e:16), 1
	ld a, (0x33d4:16)
	and a, (0x3312:16)
	jr z, AccVoice_NullRet
	or (0x330e:16), 2

AccVoice_NullRet:
	ret

AccVoice_LookupTableAddress:
	ld xde, AccVoice_LookupTableAddress_Table
	and w, 0x7
	sla w, 1
	ld	de, (xde+w)
	xor w, w
	add de, wa
	ret

AccVoice_LookupExtParamAddr:
	ld xde, AccVoice_LookupTableAddress_Table
	and w, 0x7
	inc 1, w
	sla w, 1
	ld	de, (xde+w)
	ret

AccVoice_AdvanceWithSave:
	ld iy, (0x33d8:16)
	ld iz, (0x33d6:16)
	call AccBuf_AdvanceWithPageTurn
	ret

AccBuf_AdvanceNoPage:
	ld iy, (0x33d8:16)
	ld iz, (0x33d6:16)
	call AccBuf_Advance
	ld (0x33d6:16), iz
	ld (0x33d8:16), iy
	ret

AccVoice_HandleMarker83:
	ld w, (0x33d4:16)
	ld a, (0x3314:16)
	or a, (0x3315:16)
	and w, a
	jr nz, AccVoice_Marker83_Activate
	ld a, (0x33d4:16)
	and a, (0x3328:16)
	jr z, AccVoice_Marker83_CheckDeact

AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	calr AccPart_CheckAnyActive
	and a, (0x33d4:16)
	jr z, AccVoice_Marker83_NextPart
	calr AccPart_Deactivate
	jr AccVoice_Marker83_Return

AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	ld a, (0x33d4:16)
	or (0x332a:16), a
	or (0x3328:16), a
	or (0x32f4:16), 1
	ld a, (0x332a:16)
	and a, 0x3f
	cp a, 0x3f
	jr nz, AccVoice_ActivatePart_Return
	or (0x3283:16), 4
	and (0x332a:16), 192

AccVoice_ActivatePart_Return:
	ret

AccVoice_ActivateByteData:
	ld	a, (0x3470:16)
	and	a, 192
	jr	nz, AccVoice_ActivatePart_Skip
	ld	a, (0x33d4:16)
	and	a, (0x3329:16)
	jr	z, AccVoice_ActivatePart_Skip2
AccVoice_ActivatePart_Skip:
	calr	AccPart_ResolveWithPedal
	ld	a, (0x33d4:16)
	xor	a, 255
	and	(0x3329:16), a
	jr	AccVoice_ActivatePart_Return2
AccVoice_ActivatePart_Skip2:
	ld	a, (0x3316:16)
	or	a, (0x3317:16)
	or	a, (0x3318:16)
	and	a, (0x33d4:16)
	jr	nz, AccVoice_ActivatePart_Skip3
	bit	0, (0x3301:16)
	jr	z, AccVoice_ActivatePart_Skip3
	and	(0x330e:16), 252
	or	(0x330e:16), 1
	ld	a, (0x33d4:16)
	and	a, (0x3312:16)
	jr	z, AccVoice_ActivatePart_Entry
	or	(0x330e:16), 2
AccVoice_ActivatePart_Entry:
	or	(0x32f3:16), 128
	or	(0x32f4:16), 1
	jr	AccVoice_ActivatePart_Join
AccVoice_ActivatePart_Skip3:
	calr	AccPart_SelectSourceOrParam
	calr	AccPart_ResolveStyleAddr
AccVoice_ActivatePart_Join:
	ld	a, (0x33d4:16)
	xor	a, 255
	and	(0x3312:16), a
	and	(0x3313:16), a
	and	(0x3316:16), a
	and	(0x3317:16), a
	and	(0x3318:16), a
	ld	(0x33db:16), 0
	ld	(0x33ea:16), 0
AccVoice_ActivatePart_Return2:
	ret
	.byte 0xc1, 0xf4
	ldw	de, 318

AccPart_SelectSourceOrParam:
	cp (0x32e5:16), 128
	jr c, AccPart_SelectSource_Param
	calr AccPart_SelectSource
	jr AccPart_SelectSource_Done

AccPart_SelectSource_Param:
	calr AccPart_LoadParamOffsetTable

AccPart_SelectSource_Done:
	ld w, (0x33d4:16)
	ret

AccPart_AdvanceAndResolve:
	calr AccPart_IncrementIndex
	ld a, (0x33d4:16)
	and a, (0x335d:16)
	jr z, AccPart_AdvanceResolve_Done
	call AccVoice_InitPerChannel
	calr AccPart_LoadParamOffsetTable
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x335d:16), a
	call AccVoice_AssignPerPart

AccPart_AdvanceResolve_Done:
	calr AccPart_ResolveStyleAddr
	ret

AccPart_ResolveStyleAddr:
	cp (0x32e5:16), 128
	jr c, AccPart_ResolveStyle_Bound
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	ld (0x33d6:16), wa
	ldw (0x33d8:16), 6
	jr AccPart_ResolveStyle_Return

AccPart_ResolveStyle_Bound:
	ld xiy, (0x32ce:16)
	ld a, (0x33d5:16)
	call AccPart_LookupBoundVoiceParam
	calr AccPart_GetParamAddr
	ld (0x33d8:16), wa

AccPart_ResolveStyle_Return:
	ret

AccPart_IncrementIndex:
	cp (0x32e5:16), 128
	jr nc, AccPart_IncrementIndex_Return
	ld xiy, (0x32ce:16)
	inc 1, (0x33d5:16)
	xor xhl, xhl
	ld w, (0x33d5:16)
	call AccStyle_ReadParamOffset
	cp w, 0x83
	jr nz, AccPart_IncrementIndex_Return
	ld a, (0x33d5:16)
	call AccTuning_FetchValue
	ld (0x33d5:16), a

AccPart_IncrementIndex_Return:
	ret

AccPart_ResolveWithPedal:
	cp (0x32e5:16), 128
	jr c, AccPart_ResolveWithPedal_Bound
	bit 0, (0x3363:16)
	jr nz, AccPart_ResolveWithPedal_DirB
	calr AccPedal_DirectionA
	ld xiy, (0x32d3:16)
	calr AccPart_GetParamAddr
	ld (0x33d8:16), wa
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_DirB:
	ld w, (0x33d4:16)
	calr AccPedal_DirectionB
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	ld (0x33d6:16), wa
	ldw (0x33d8:16), 6
	jr AccPart_ResolveWithPedal_Return

AccPart_ResolveWithPedal_Bound:
	calr AccPedal_DirectionA
	ld xiy, (0x32ce:16)
	calr AccPart_GetParamAddr
	ld (0x33d8:16), wa

AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	ld xiy, (0x32ce:16)
	ld a, (0x33d5:16)
	ld w, 0x0:opc
	call AccPart_GetVoiceParamOffsetTable
	calr AccPart_LoadTuningByChannel
	ret

AccPart_LoadTuningByChannel:
	cp (0x33d4:16), 1
	jr nz, AccPart_LoadTuning_Kbd2
	call AccTuning_LoadAndApplyMaster
	or (0x332c:16), 1
	jr AccPart_NullRet

AccPart_LoadTuning_Kbd2:
	cp (0x33d4:16), 2
	jr nz, AccPart_LoadTuning_Acc1
	call AccTuning_LoadAndApplyMaster
	or (0x332c:16), 2
	jr AccPart_NullRet

AccPart_LoadTuning_Acc1:
	cp (0x33d4:16), 4
	jr nz, AccPart_LoadTuning_Acc2
	call AccTuning_LoadCoarseFromStyle
	or (0x332c:16), 4
	jr AccPart_NullRet

AccPart_LoadTuning_Acc2:
	cp (0x33d4:16), 8
	jr nz, AccPart_LoadTuning_Acc3
	call AccTuning_LoadFineFromStyle
	or (0x332c:16), 8
	jr AccPart_NullRet

AccPart_LoadTuning_Acc3:
	cp (0x33d4:16), 16
	jr nz, AccPart_LoadTuning_Acc4
	call AccTuning_LoadOctaveFromStyle
	or (0x332c:16), 16
	jr AccPart_NullRet

AccPart_LoadTuning_Acc4:
	cp (0x33d4:16), 32
	jr nz, AccPart_NullRet
	call AccTuning_LoadTransposeFromStyle
	or (0x332c:16), 32

AccPart_NullRet:
	ret

AccPart_GetFreeVoiceAddr:
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x33e0:16), a
	cp (0x33d4:16), 1
	jr nz, AccPart_FreeAddr_Kbd2
	ld wa, (xiy + 0:8)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Kbd2:
	cp (0x33d4:16), 2
	jr nz, AccPart_FreeAddr_Acc1
	ldw wa, 0xfffe
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc1:
	cp (0x33d4:16), 4
	jr nz, AccPart_FreeAddr_Acc2
	ld wa, (xiy + 4)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc2:
	cp (0x33d4:16), 8
	jr nz, AccPart_FreeAddr_Acc3
	ld wa, (xiy + 6)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc3:
	cp (0x33d4:16), 16
	jr nz, AccPart_FreeAddr_Acc4
	ld wa, (xiy + 8)
	jr AccPart_CheckEndOfDataMarker

AccPart_FreeAddr_Acc4:
	cp (0x33d4:16), 32
	jr nz, AccPart_CheckEndOfDataMarker
	ld wa, (xiy + 10)

AccPart_CheckEndOfDataMarker:
	cp wa, 0xfffe
	jr nz, AccPart_FreeAddr_Return
	ld a, (0x33d4:16)
	or (0x33e0:16), a
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
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x33e0:16), a
	cp (0x33d4:16), 1
	jr nz, AccPart_ParamAddr_Kbd2
	add hl, 0x118
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Kbd2:
	cp (0x33d4:16), 2
	jr nz, AccPart_ParamAddr_Acc1
	add hl, 0x13e
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc1:
	cp (0x33d4:16), 4
	jr nz, AccPart_ParamAddr_Acc2
	add hl, 0x164
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc2:
	cp (0x33d4:16), 8
	jr nz, AccPart_ParamAddr_Acc3
	add hl, 0x18a
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc3:
	cp (0x33d4:16), 16
	jr nz, AccPart_ParamAddr_Acc4
	add hl, 0x1b0
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_ParamAddr_Acc4:
	cp (0x33d4:16), 32
	jr nz, AccPart_SubtractBaseAddr
	add hl, 0x1d6
	ld	wa, (xiy+hl)
	jr AccPart_SubtractBaseAddr

AccPart_SubtractBaseAddr:
	sub wa, 0x8000
	add wa, 0x6
	ret

AccPart_SelectSource:
	ld xiy, (0x32ce:16)
	cp (0x33d4:16), 1
	jr z, AccPart_SelectKbd
	cp (0x33d4:16), 2
	jr nz, AccPart_CheckAcc1

AccPart_SelectKbd:
	add xiy, 0x18
	ld xix, 0x3246
	jr AccPart_CopyData

AccPart_CheckAcc1:
	cp (0x33d4:16), 4
	jr nz, AccPart_CheckAcc2
	add xiy, 0x20
	ld xix, 0x324d
	jr AccPart_CopyData

AccPart_CheckAcc2:
	cp (0x33d4:16), 8
	jr nz, AccPart_CheckAcc3
	add xiy, 0x28
	ld xix, 0x3254
	jr AccPart_CopyData

AccPart_CheckAcc3:
	cp (0x33d4:16), 16
	jr nz, AccPart_CheckAcc4
	add xiy, 0x30
	ld xix, 0x325b
	jr AccPart_CopyData

AccPart_CheckAcc4:
	cp (0x33d4:16), 32
	jr nz, AccPart_CheckAcc4
	add xiy, 0x38
	ld xix, 0x3262

AccPart_CopyData:
	ld bc, 7:i3
	ldir85
	ld a, (0x33d4:16)
	or (0x332c:16), a
	ret

AccPart_CheckAnyActive:
	ld a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	ret


; -----------------------------------------------------------------------------
; Section: Pedal Direction & MIDI Dispatch
; -----------------------------------------------------------------------------
; Pedal direction control (forward/reverse/alternate)
; and accompaniment MIDI event dispatch.
; -----------------------------------------------------------------------------

AccPedal_DirectionA:
	ld a, (0x3470:16)
	and a, 0xc0
	jr z, AccPedal_DirA_CheckBit1
	bit 7, (0x3470:16)
	jr z, AccPedal_DirA_SetForward
	bit 6, (0x3470:16)
	jr z, AccPedal_DirA_SetReverse

AccPedal_DirA_CheckBit1:
	bit 1, (0x32fb:16)
	jr nz, AccPedal_DirA_SetReverse

AccPedal_DirA_SetForward:
	or (0x3309:16), 1
	jr AccPedal_DirA_Apply

AccPedal_DirA_SetReverse:
	or (0x3309:16), 2

AccPedal_DirA_Apply:
	ld a, (0x33d5:16)
	call AccVoice_ComputeParamAddr
	and (0x3309:16), 252
	ret

AccPedal_DirectionB:
	ld a, (0x3470:16)
	and a, 0xc0
	jr z, AccPedal_DirB_CheckBit0
	bit 7, (0x3470:16)
	jr z, AccPedal_DirB_Alternate
	bit 6, (0x3470:16)
	jr z, AccPedal_DirB_InvertAndStore

AccPedal_DirB_CheckBit0:
	bit 0, (0x32fb:16)
	jr nz, AccPedal_DirB_Alternate

AccPedal_DirB_InvertAndStore:
	ld a, w
	xor w, 0xff
	and (0x3312:16), w
	ld w, (1075:16)
	cp w, (0x336a:16)
	jr nz, AccPedal_DirB_DefaultStyle
	or (0x3313:16), a
	ld a, (0x336b:16)
	jr AccPedal_DirB_Return

AccPedal_DirB_Alternate:
	ld a, w
	xor w, 0xff
	and (0x3313:16), w
	ld w, (1075:16)
	cp w, (0x3368:16)
	jr nz, AccPedal_DirB_DefaultStyle
	or (0x3312:16), a
	ld a, (0x3369:16)
	jr AccPedal_DirB_Return

AccPedal_DirB_DefaultStyle:
	ld a, (0x32e5:16)
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
	cp a, 0:i3
	jr nz, AccMidi_VelNonZero
	ld a, 0x1:opc

AccMidi_VelNonZero:
	ld e, a
	ld (0x33d2:16), a
	ld	a, (xhl+iy)
	ret

AccMidi_ParseNoteOn:
	calr AccMidi_ParseCommon
	cp (0x342d:16), 145
	jr nz, AccMidi_ParseNoteOn_StorePos
	ld	a, (xhl+iy)
	ld (0x3433:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3434:16), a
	call AccBuf_Advance

AccMidi_ParseNoteOn_StorePos:
	ld (0x33d8:16), iy
	ld (0x33d6:16), iz
	ret

AccMidi_ParseCommon:
	ld (0x342d:16), a
	call AccBuf_Advance
	ld (0x342e:16), e
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x342f:16), a
	cp (0x33d4:16), 1
	jr z, AccMidi_ParseCommon_ExtraFields
	cp (0x33d4:16), 2
	jr z, AccMidi_ParseCommon_ExtraFields
	call Rhythm_CheckVelocityThreshold

AccMidi_ParseCommon_ExtraFields:
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3430:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3431:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3432:16), a
	call AccBuf_Advance
	ret

AccMidi_SelectVelocitySource:
	ld a, (0x33d4:16)
	ld w, (0x333f:16)
	and a, (0x3316:16)
	jr nz, AccMidi_VelSource_Active
	and a, (0x3317:16)
	jr nz, AccMidi_VelSource_Active
	and a, (0x3318:16)
	jr nz, AccMidi_VelSource_Active
	and a, (0x3314:16)
	jr nz, AccMidi_VelSource_Active
	and a, (0x3315:16)
	jr z, AccMidi_VelSource_Store

AccMidi_VelSource_Active:
	ld w, (0x3340:16)

AccMidi_VelSource_Store:
	ld (0x33de:16), w
	ret

AccMidi_DispatchPerPart:
	cp (0x33d4:16), 1
	jr nz, AccMidi_DispatchKbd2
	calr AccKbd1_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchKbd2:
	cp (0x33d4:16), 2
	jr nz, AccMidi_DispatchAcc1
	calr AccKbd2_RingBufEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc1:
	cp (0x33d4:16), 4
	jr nz, AccMidi_DispatchAcc2
	call AccCh1_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc2:
	cp (0x33d4:16), 8
	jr nz, AccMidi_DispatchAcc3
	call AccCh2_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc3:
	cp (0x33d4:16), 16
	jr nz, AccMidi_DispatchAcc4
	call AccCh3_NoteOnEntry
	jr AccMidi_DispatchAcc4Return

AccMidi_DispatchAcc4:
	cp (0x33d4:16), 32
	jr nz, AccMidi_DispatchAcc4Return
	call AccCh4_NoteOnEntry

AccMidi_DispatchAcc4Return:
	ret

AccKbd1_RingBufEntry:
	calr AccKbd1_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccKbd1_RingBufReturn
	ld xhl, 0x2a94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd1_RingBufReturn:
	ret

AccKbd1_CheckEligible:
	and (0x33e1:16), 254
	bit 0, (0x33de:16)
	jr z, AccKbd1_CheckReturn
	bit 0, (0x3362:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x3307:16)
	jr z, AccKbd1_CheckReturn
	bit 4, (0x379b:16)
	jr z, AccKbd1_CheckRecording
	bit 2, (0x34cf:16)
	jr nz, AccKbd1_CheckReturn
	bit 7, (0x3558:16)
	jr z, AccKbd1_CheckRecording
	ld a, (0x3558:16)
	and a, 0x7f
	cp a, (0x342f:16)
	jr z, AccKbd1_CheckReturn
	cp a, 0x30
	jr nz, AccKbd1_CheckRecording
	cp (0x342f:16), 93
	jr z, AccKbd1_CheckReturn

AccKbd1_CheckRecording:
	bit 1, (0x3335:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccKbd1_CheckReturn
	ld xhl, 0x2a94
	calr AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ule, AccKbd1_CheckReturn
	or (0x33e1:16), 1

AccKbd1_CheckReturn:
	ret

AccBuf_WriteNoteEvent:
	ld a, (0x342d:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	cp a, 0:i3
	jr nz, AccBuf_WriteNote_VelNonZero
	ld a, 0x1:opc

AccBuf_WriteNote_VelNonZero:
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3432:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_ComputeFillLevel:
	ld wa, (xhl + 6)
	cp wa, (xhl + 4)
	jr c, AccBuf_FillLevel_Wrapped
	jr ugt, AccBuf_FillLevel_Simple
	ld wa, (xhl + 2)
	sub wa, (xhl + 0:8)
	inc 1, wa
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Wrapped:
	ld wa, (xhl + 2)
	sub wa, (xhl + 0:8)
	inc 1, wa
	sub wa, (xhl + 4)
	add wa, (xhl + 6)
	jr AccBuf_FillLevel_Store

AccBuf_FillLevel_Simple:
	sub wa, (xhl + 4)

AccBuf_FillLevel_Store:
	ld (0x3324:16), wa
	ret

AccTempo_PositionCompare:
	cp w, (0x32b4:16)
	jr nz, AccTempo_DiffBar
	cp bc, de
	jr c, AccTempo_SameBar
	ld a, 0x0:opc
	jr AccTempo_Return

AccTempo_SameBar:
	sub de, bc
	ld a, e
	cp d, 0:i3
	jr z, AccTempo_Return
	ld a, 0x60:opc
	jr AccTempo_Return

AccTempo_DiffBar:
	cp w, (0x32b4:16)
	jr c, AccTempo_BarZero
	cp w, 0xff
	jr nz, AccTempo_ComputeDelta
	cp (0x32b4:16), 0
	jr z, AccTempo_TooFar
	jr AccTempo_ComputeDelta

AccTempo_BarZero:
	cp w, 0:i3
	jr nz, AccTempo_TooFar
	cp (0x32b4:16), 255
	jr z, AccTempo_ComputeDelta

AccTempo_TooFar:
	ld a, 0x0:opc
	jr AccTempo_Return

AccTempo_ComputeDelta:
	xor xwa, xwa
	ld a, (1112:16)
	sla a, 1
	add xwa, AccVoice_LookupTableAddress_Table
	add de, (xwa)
	sub de, bc
	ld a, e
	cp d, 0:i3
	jr z, AccTempo_Return
	ld a, 0x60:opc

AccTempo_Return:
	ret

AccKbd1_ProcessNotes:
	calr AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccKbd1_ProcessReturn
	calr AccKbd1_ScanSlots
	calr AccKbd1_DrainRingBuf
	ld xiy, 0x3214
	ld xix, 0x322d
	ld bc, 5:i3
	ldir85
	ld a, (0x343c:16)
	ld (0x32ec:16), a
	call RhythmPart1_ProcessAccentData
	and (0x332c:16), 254

AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	ld a, 0x0:opc
	ld w, (0x33db:16)
	calr AccVoice_LookupTableAddress
	ld bc, (0x327d:16)
	ld w, (0x33da:16)
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ule, AccKbd1_TimingOK
	or (0x32f4:16), 1
	jr AccKbd1_TimingReturn

AccKbd1_TimingOK:
	ld (0x343c:16), a
	ld a, 0x5f:opc
	ld w, (1112:16)
	dec 1, w
	calr AccVoice_LookupTableAddress
	ld bc, (0x327d:16)
	ld w, (0x33da:16)
	dec 1, w
	calr AccTempo_PositionCompare
	ld (0x343b:16), a

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
	ld a, (0x343b:16)
	xor w, w
	ei 6
	add wa, (1120:16)
	sub a, (1124:16)
	jr pl, AccSlot_CompareAndUpdate
	cp w, 0:i3
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
	cp (0x3372:16), wa
	jr ule, AccSlot_RestoreInterrupts
	ld (0x3372:16), wa

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
	ld	a, (xhl+iy)
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
	ld	w, (xhl+iy)
	call Rhythm_AdvancePosition
	ld	e, (xhl+iy)
	pushw iy
	inc 1, iy
	cp iy, bc
	jr ule, AccBuf_NoteEvent_WrapPos
	ld iy, (xhl + 0:8)

AccBuf_NoteEvent_WrapPos:
	ld	d, (xhl+iy)
	popw iy
	ld a, (0x343b:16)
	ei 6
	add a, (1122:16)
	add w, (1124:16)
	sub a, w
	jr pl, AccBuf_NoteEvent_StoreTiming
	ld a, 0x0:opc

AccBuf_NoteEvent_StoreTiming:
	xor w, w
	cp de, wa
	jr ule, AccBuf_NoteEvent_SkipTiming
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), w
	jr AccBuf_NoteEvent_Return

AccBuf_NoteEvent_SkipTiming:
	call RingBuf_AdvanceIndex

AccBuf_NoteEvent_Return:
	ei 0
	ret

AccKbd2_CheckActive:
	ld	a, (0x33d4:16)
	and	a, (0x33e0:16)
	jr	z, AccBuf_ProcessNoteEvent_Return
	ld	a, (0x33d4:16)
	ld	w, (0x3314:16)
	or	w, (0x3315:16)
	and	w, a
	jr	z, AccBuf_ProcessNoteEvent_Skip
	or	(0x332a:16), a
	or	(0x3328:16), a
	jr	AccBuf_ProcessNoteEvent_Return
AccBuf_ProcessNoteEvent_Skip:
	ld	a, (0x33d4:16)
	xor	a, 255
	and	(0x3312:16), a
	and	(0x3313:16), a
	and	(0x3316:16), a
	and	(0x3317:16), a
	and	(0x3318:16), a
	and	(0x335d:16), a
	and	(0x3329:16), a
	ld	(0x33ea:16), 0
	ld	(0x33d6:16), 254
	ld	(0x33d8:16), 6
AccBuf_ProcessNoteEvent_Return:
	ret

AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x2:opc
	ld (0x33d4:16), a
	ld wa, (0x3299:16)
	ld (0x33d6:16), wa
	ld wa, (0x3289:16)
	ld (0x33d8:16), wa
	ld a, (0x32b6:16)
	ld (0x33da:16), a
	ld a, (0x32ac:16)
	ld (0x33db:16), a
	ld a, (0x32a4:16)
	ld (0x33d5:16), a
	ld a, (0x33ec:16)
	ld (0x33ea:16), a
	ret

AccKbd2_RestoreState:
	ld wa, (0x33d6:16)
	ld (0x3299:16), wa
	ld wa, (0x33d8:16)
	ld (0x3289:16), wa
	ld a, (0x33da:16)
	ld (0x32b6:16), a
	ld a, (0x33db:16)
	ld (0x32ac:16), a
	ld a, (0x33d5:16)
	ld (0x32a4:16), a
	ld a, (0x33ea:16)
	ld (0x33ec:16), a
	ret

AccKbd2_RingBufEntry:
	calr AccKbd2_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccKbd2_RingBufReturn
	ld xhl, 0x2b94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteNoteEvent

AccKbd2_RingBufReturn:
	ret

AccKbd2_CheckEligible:
	and (0x33e1:16), 254
	cp (0x32e5:16), 128
	jr nc, AccKbd2_CheckReturn
	bit 1, (0x33de:16)
	jr z, AccKbd2_CheckReturn
	bit 0, (0x3307:16)
	jr z, AccKbd2_CheckReturn
	bit 1, (0x3335:16)
	jr nz, AccKbd2_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccKbd2_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccKbd2_CheckReturn
	ld xhl, 0x2b94
	calr AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ule, AccKbd2_CheckReturn
	or (0x33e1:16), 1

AccKbd2_CheckReturn:
	ret

AccKbd2_ProcessNotes:
	calr AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccKbd2_ProcessReturn
	calr AccKbd2_ScanSlots
	calr AccKbd2_DrainRingBuf
	and (0x332c:16), 253

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
	ld	a, (xhl+iy)
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
	and (0x32f4:16), 252

AccSeq_ScanLoop:
	bit 0, (0x32f4:16)
	jrl nz, AccSeq_ScanDone
	ld xhl, (0x3293:16)
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
	ld w, (0x32b1:16)
	calr AccVoice_LookupTableAddress
	ld bc, (0x327d:16)
	ld w, (0x32bb:16)
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_NoteOn_TooFar
	calr AccSeq_ParseNoteEvent
	jr AccSeq_NoteOn_Continue

AccSeq_NoteOn_TooFar:
	or (0x32f4:16), 1

AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	bit 1, (0x32f4:16)
	jr z, AccSeq_EndOfBar_Process
	or (0x32f4:16), 1
	jr AccSeq_ScanLoop

AccSeq_EndOfBar_Process:
	ld w, (0x32b1:16)
	calr AccVoice_LookupExtParamAddr
	ld bc, (0x327d:16)
	ld w, (0x32bb:16)
	calr AccTempo_PositionCompare
	cp a, 0x18
	jr ugt, AccSeq_EndOfBar_TooFar
	or (0x32f4:16), 2
	ld a, (0x32b1:16)
	inc 1, a
	ld w, a
	and a, 0xf
	cp a, (1075:16)
	jr z, AccSeq_NextBarPage
	ld (0x32b1:16), w
	calr AccSeq_AdvancePointer
	jrl AccSeq_ScanLoop

AccSeq_NextBarPage:
	and w, 0xf0
	add w, 0x10
	ld (0x32b1:16), w
	inc 1, (0x32bb:16)
	ld xhl, AccStyle_DefaultStream
	add xhl, 0x6
	ld (0x3293:16), xhl
	jrl AccSeq_ScanLoop

AccSeq_EndOfBar_TooFar:
	or (0x32f4:16), 1
	jrl AccSeq_ScanLoop

AccSeq_ScanDone:
	ret

AccSeq_ReadNextByte:
	ld xhl, (0x3293:16)
	inc 1, xhl
	ld a, (xhl)
	ret

AccSeq_AdvancePointer:
	ld xhl, (0x3293:16)
	inc 1, xhl
	ld (0x3293:16), xhl
	ret

AccSeq_ResetToStart:
	ld xhl, AccStyle_DefaultStream
	add xhl, 0x6
	ld (0x3293:16), xhl
	ld a, (xhl)
	ret

AccSeq_ParseNoteEvent:
	cp a, 0:i3
	jr nz, AccSeq_ParseNote_VelNonZero
	ld a, 0x1:opc

AccSeq_ParseNote_VelNonZero:
	ld e, a
	ld xhl, (0x3293:16)
	ld a, (xhl)
	ld (0x342d:16), a
	calr AccSeq_AdvancePointer
	ld (0x342e:16), e
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	ld (0x342f:16), a
	calr AccSeq_AdvancePointer
	ld a, (xhl)
	ld (0x3430:16), a
	calr AccSeq_AdvancePointer
	ld a, 0x1:opc
	ld (0x3431:16), a
	calr AccSeq_AdvancePointer
	ld a, 0x0:opc
	ld (0x3432:16), a
	calr AccSeq_AdvancePointer
	ld a, (0x379b:16)
	and a, 0x3f
	jr z, AccSeq_ParseNote_CheckMode
	cp (CURRENT_TITLE:16), 181
	jr z, AccSeq_ParseNote_WriteToKbd2
	jr AccSeq_ParseNote_Return

AccSeq_ParseNote_CheckMode:
	ld a, (0x3335:16)
	cp a, 3:i3
	jr nz, AccSeq_ParseNote_CheckRec
	bit 0, (0x347a:16)
	jr z, AccSeq_ParseNote_WriteToKbd2

AccSeq_ParseNote_CheckRec:
	bit 0, (0x33e8:16)
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
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x4:opc
	ld (0x33d4:16), a
	ld wa, (0x329b:16)
	ld (0x33d6:16), wa
	ld wa, (0x328b:16)
	ld (0x33d8:16), wa
	ld a, (0x32b7:16)
	ld (0x33da:16), a
	ld a, (0x32ad:16)
	ld (0x33db:16), a
	ld a, (0x32a5:16)
	ld (0x33d5:16), a
	ld a, (0x33ed:16)
	ld (0x33ea:16), a
	ret

AccCh1_RestoreState:
	ld wa, (0x33d6:16)
	ld (0x329b:16), wa
	ld wa, (0x33d8:16)
	ld (0x328b:16), wa
	ld a, (0x33da:16)
	ld (0x32b7:16), a
	ld a, (0x33db:16)
	ld (0x32ad:16), a
	ld a, (0x33d5:16)
	ld (0x32a5:16), a
	ld a, (0x33ea:16)
	ld (0x33ed:16), a
	ret

AccVoice_AssignPerPart:
	cp (0x33d4:16), 1
	jr z, AccVoice_AssignReturn
	cp (0x33d4:16), 2
	jr z, AccVoice_AssignReturn
	ld a, (0x33d5:16)
	call AccTuning_FetchValue
	ld (0x3349:16), a
	calr AccVoice_ScanInstruments
	calr AccVoice_SendProgChange

AccVoice_AssignReturn:
	ret

AccVoice_ScanInstruments:
	ld e, (0x3349:16)
	ld (0x3333:16), 0

AccVoice_ScanLoop:
	cp e, (0x33d5:16)
	jr z, AccVoice_ScanDone
	ld xiy, (0x32ce:16)
	ld a, e
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld iy, wa
	ld a, (0x3285:16)
	call AccVoice_TableLookup
	call AccVoice_ScanForD3
	inc 1, e
	jr AccVoice_ScanLoop

AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	cp (0x33d4:16), 4
	jr nz, AccVoice_SendD4
	ld a, 0xd7:opc
	ld w, 0x3:opc
	ld e, (0x3333:16)
	ld (0x332f:16), e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD4:
	cp (0x33d4:16), 8
	jr nz, AccVoice_SendD5
	ld a, 0xd4:opc
	ld w, 0x3:opc
	ld e, (0x3333:16)
	ld (0x3330:16), e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD5:
	cp (0x33d4:16), 16
	jr nz, AccVoice_SendD6
	ld a, 0xd5:opc
	ld w, 0x3:opc
	ld e, (0x3333:16)
	ld (0x3331:16), e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccVoice_SendD6:
	ld a, 0xd6:opc
	ld w, 0x3:opc
	ld e, (0x3333:16)
	ld (0x3332:16), e
	call Rhythm_Send3ByteMsg
	jr AccCh_ReturnStub

AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	ld a, (0x342d:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccCh1_Padding:
	nop
	nop

AccCh1_NoteOnEntry:
	calr AccCh1_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh1_NoteOnReturn
	ld a, (0x32c3:16)
	ld (0x32cb:16), a
	ld a, (0x32c7:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 251
	or (0x32f4:16), 8
	ld xhl, 0x2c94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh1_NoteOnReturn:
	ret

AccCh1_CheckEligible:
	and (0x33e1:16), 254
	bit 2, (0x3362:16)
	jr nz, AccCh1_CheckReturn
	bit 1, (0x3307:16)
	jr z, AccCh1_CheckReturn
	bit 3, (0xc5a0:16)
	jr z, AccCh1_CheckReturn
	calr AccCh_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh1_CheckReturn
	bit 1, (0x3335:16)
	jr nz, AccCh1_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccCh1_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccCh1_CheckReturn
	ld xhl, 0x2c94
	call AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ugt, AccCh1_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh1_CheckReturn

AccCh1_SetReady:
	or (0x33e1:16), 1

AccCh1_CheckReturn:
	ret

AccBuf_WriteExtendedEvent:
	ld a, (0x3433:16)
	ld (0x3336:16), a
	ld a, (0x3434:16)
	ld (0x3337:16), a
	ld a, (0x342d:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x342f:16)
	ld (0x3435:16), a
	calr AccVoice_CheckStyle
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	cp a, 0:i3
	jr nz, AccBuf_ExtEvt_VelNonZero
	ld a, 0x1:opc

AccBuf_ExtEvt_VelNonZero:
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3432:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	calr AccBuf_ExtEvt_WriteExtra
	ld a, (0x3435:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccBuf_ExtEvt_WriteExtra:
	cp (0x342d:16), 144
	jr z, AccBuf_ExtEvt_ExtraReturn
	ld a, (0x3336:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3337:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex

AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	cp (0x32e5:16), 240
	jr c, AccVoice_CallCorrection

AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	push	xhl
	pushw	iy
	ld	a, (0x342f:16)
	bit	4, (0x32f4:16)
	jr	nz, AccVoice_CheckStyle_Skip2
	bit	3, (0x32f4:16)
	jr	z, AccVoice_CheckStyle_Skip
	call	Rhythm_CrossVoiceCorrect
AccVoice_CheckStyle_Skip:
	call	Rhythm_NoteRangeCheck
AccVoice_CheckStyle_Skip2:
	call	Rhythm_VelocityCompute
	popw	iy
	pop	xhl
	ret

AccVoice_CorrectNote:
	push xhl
	pushw iy
	ld a, (0x342f:16)
	bit 4, (0x32f4:16)
	jr nz, AccVoice_VelocityLookup
	bit 3, (0x32f4:16)
	jr z, AccVoice_NoteRangeCheck
	call Rhythm_CrossVoiceCorrect

AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	cp (0x342d:16), 145
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
	ld (0x342d:16), a
	call AccBuf_Advance
	ld (0x342e:16), e
	call AccBuf_Advance
	ld a, d
	and a, 0xf
	ld (0x342f:16), a
	ld	a, (xhl+iy)
	ld (0x3430:16), a
	call AccBuf_Advance
	ld (0x33d8:16), iy
	ld (0x33d6:16), iz
	ret

AccMidi_DispatchDType:
	cp (0x33d4:16), 1
	jr nz, AccMidi_DType_CheckKbd2
	jr AccMidi_DType_Return

AccMidi_DType_CheckKbd2:
	cp (0x33d4:16), 2
	jr nz, AccMidi_DType_CheckAcc1
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc1:
	cp (0x33d4:16), 4
	jr nz, AccMidi_DType_CheckAcc2
	calr AccCh1_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc2:
	cp (0x33d4:16), 8
	jr nz, AccMidi_DType_CheckAcc3
	calr AccCh2_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc3:
	cp (0x33d4:16), 16
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh3_DTypeEntry
	jr AccMidi_DType_Return

AccMidi_DType_CheckAcc4:
	cp (0x33d4:16), 32
	jr nz, AccMidi_DType_CheckAcc4
	calr AccCh4_DTypeEntry

AccMidi_DType_Return:
	ret

AccCh1_DTypeEntry:
	calr AccCh1_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh1_DTypeReturn
	ld xhl, 0x2c94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh1_DTypeReturn:
	ret

AccCh_CheckOverlap:
	ld a, 0x0:opc
	bit 2, (0x34cf:16)
	jr z, AccCh_OverlapReturn
	bit 3, (0x379b:16)
	jr z, AccCh_OverlapReturn
	ld a, 0x1:opc

AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	ldw (xhl + 0:8), 0xa
	ldw (xhl + 2), 0xff
	ldw (xhl + 4), 0xa
	ldw (xhl + 6), 0xa
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld (0x342d:16), 208
	ld a, (0x33d2:16)
	ld (0x342e:16), a
	ld (0x342f:16), 2
	ld (0x3430:16), 64
	calr AccBuf_Write3ByteEvent
	ld a, (0x33d2:16)
	ld (0x342e:16), a
	ld (0x342f:16), 1
	ld (0x3430:16), 0
	calr AccBuf_Write3ByteEvent
	ld a, (0x33d2:16)
	ld (0x342e:16), a
	ld (0x342f:16), 3
	ld (0x3430:16), 0
	calr AccBuf_Write3ByteEvent
	ld a, (0x33d2:16)
	ld (0x342e:16), a
	ld (0x342f:16), 5
	ld (0x3430:16), 127
	calr AccBuf_Write3ByteEvent
	ret

AccCh1_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccCh1_ProcessReturn
	calr AccCh1_ScanSlots
	calr AccCh1_DrainRingBuf
	calr AccCh1_InitProgChange
	ld xiy, 0x3219
	ld xix, 0x3232
	ld bc, 5:i3
	ldir85
	ld a, (0x343c:16)
	ld (0x32ec:16), a
	call RhythmPart2_ProcessAccentData
	and (0x332c:16), 251

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
	ld	a, (xhl+iy)
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
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x8:opc
	ld (0x33d4:16), a
	ld wa, (0x329d:16)
	ld (0x33d6:16), wa
	ld wa, (0x328d:16)
	ld (0x33d8:16), wa
	ld a, (0x32b8:16)
	ld (0x33da:16), a
	ld a, (0x32ae:16)
	ld (0x33db:16), a
	ld a, (0x32a6:16)
	ld (0x33d5:16), a
	ld a, (0x33ee:16)
	ld (0x33ea:16), a
	ret

AccCh2_RestoreState:
	ld wa, (0x33d6:16)
	ld (0x329d:16), wa
	ld wa, (0x33d8:16)
	ld (0x328d:16), wa
	ld a, (0x33da:16)
	ld (0x32b8:16), a
	ld a, (0x33db:16)
	ld (0x32ae:16), a
	ld a, (0x33d5:16)
	ld (0x32a6:16), a
	ld a, (0x33ea:16)
	ld (0x33ee:16), a
	ret

AccCh2_NoteOnEntry:
	calr AccCh2_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh2_NoteOnReturn
	ld a, (0x32c4:16)
	ld (0x32cb:16), a
	ld a, (0x32c8:16)
	ld (0x32cc:16), a
	or (0x32f4:16), 4
	and (0x32f4:16), 247
	ld xhl, 0x2d94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh2_NoteOnReturn:
	ret

AccCh2_CheckEligible:
	and (0x33e1:16), 254
	bit 3, (0x33de:16)
	jr z, AccCh2_CheckReturn
	bit 3, (0x3362:16)
	jr nz, AccCh2_CheckReturn
	bit 2, (0x3307:16)
	jr z, AccCh2_CheckReturn
	bit 0, (0x3310:16)
	jr z, AccCh2_CheckReturn
	bit 0, (0xc5a0:16)
	jr z, AccCh2_CheckReturn
	calr AccCh2_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh2_CheckReturn
	bit 1, (0x3335:16)
	jr nz, AccCh2_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccCh2_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccCh2_CheckReturn
	ld xhl, 0x2d94
	call AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ugt, AccCh2_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh2_CheckReturn

AccCh2_SetReady:
	or (0x33e1:16), 1

AccCh2_CheckReturn:
	ret

AccCh2_DTypeEntry:
	calr AccCh2_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh2_DTypeReturn
	ld xhl, 0x2d94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh2_DTypeReturn:
	ret

AccCh2_CheckOverlap:
	ld a, 0x0:opc
	bit 2, (0x34cf:16)
	jr z, AccCh2_OverlapReturn
	bit 0, (0x379b:16)
	jr z, AccCh2_OverlapReturn
	ld a, 0x1:opc

AccCh2_OverlapReturn:
	ret

AccCh2_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccCh2_ProcessReturn
	calr AccCh2_ScanSlots
	calr AccCh2_DrainRingBuf
	calr AccCh2_InitProgChange
	ld xiy, 0x321e
	ld xix, 0x3237
	ld bc, 5:i3
	ldir85
	ld a, (0x343c:16)
	ld (0x32ec:16), a
	call AccVoice_LoadRhythmParams_Part3
	and (0x332c:16), 247

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
	ld	a, (xhl+iy)
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
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x10:opc
	ld (0x33d4:16), a
	ld wa, (0x329f:16)
	ld (0x33d6:16), wa
	ld wa, (0x328f:16)
	ld (0x33d8:16), wa
	ld a, (0x32b9:16)
	ld (0x33da:16), a
	ld a, (0x32af:16)
	ld (0x33db:16), a
	ld a, (0x32a7:16)
	ld (0x33d5:16), a
	ld a, (0x33ef:16)
	ld (0x33ea:16), a
	ret

AccCh3_RestoreState:
	ld wa, (0x33d6:16)
	ld (0x329f:16), wa
	ld wa, (0x33d8:16)
	ld (0x328f:16), wa
	ld a, (0x33da:16)
	ld (0x32b9:16), a
	ld a, (0x33db:16)
	ld (0x32af:16), a
	ld a, (0x33d5:16)
	ld (0x32a7:16), a
	ld a, (0x33ea:16)
	ld (0x33ef:16), a
	ret

AccCh3_NoteOnEntry:
	calr AccCh3_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh3_NoteOnReturn
	ld a, (0x32c5:16)
	ld (0x32cb:16), a
	ld a, (0x32c9:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 251
	and (0x32f4:16), 247
	ld xhl, 0x2e94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh3_NoteOnReturn:
	ret

AccCh3_CheckEligible:
	and (0x33e1:16), 254
	bit 4, (0x33de:16)
	jr z, AccCh3_CheckReturn
	bit 4, (0x3362:16)
	jr nz, AccCh3_CheckReturn
	bit 3, (0x3307:16)
	jr z, AccCh3_CheckReturn
	bit 1, (0x3310:16)
	jr z, AccCh3_CheckReturn
	bit 1, (0xc5a0:16)
	jr z, AccCh3_CheckReturn
	calr AccCh3_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh3_CheckReturn
	bit 1, (0x3335:16)
	jr nz, AccCh3_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccCh3_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccCh3_CheckReturn
	ld xhl, 0x2e94
	call AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ugt, AccCh3_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh3_CheckReturn

AccCh3_SetReady:
	or (0x33e1:16), 1

AccCh3_CheckReturn:
	ret

AccCh3_DTypeEntry:
	calr AccCh3_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh3_DTypeReturn
	ld xhl, 0x2e94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh3_DTypeReturn:
	ret

AccCh3_CheckOverlap:
	ld a, 0x0:opc
	bit 2, (0x34cf:16)
	jr z, AccCh3_OverlapReturn
	bit 1, (0x379b:16)
	jr z, AccCh3_OverlapReturn
	ld a, 0x1:opc

AccCh3_OverlapReturn:
	ret

AccCh3_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccCh3_ProcessReturn
	calr AccCh3_ScanSlots
	calr AccCh3_DrainRingBuf
	calr AccCh3_InitProgChange
	ld xiy, 0x3223
	ld xix, 0x323c
	ld bc, 5:i3
	ldir85
	ld a, (0x343c:16)
	ld (0x32ec:16), a
	call AccVoice_LoadRhythmParams_Part4
	and (0x332c:16), 239

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
	ld	a, (xhl+iy)
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
	and (0x32f4:16), 252
	ld (0x32ed:16), 0
	ld a, 0x20:opc
	ld (0x33d4:16), a
	ld wa, (0x32a1:16)
	ld (0x33d6:16), wa
	ld wa, (0x3291:16)
	ld (0x33d8:16), wa
	ld a, (0x32ba:16)
	ld (0x33da:16), a
	ld a, (0x32b0:16)
	ld (0x33db:16), a
	ld a, (0x32a8:16)
	ld (0x33d5:16), a
	ld a, (0x33f0:16)
	ld (0x33ea:16), a
	ret

AccCh4_RestoreState:
	ld wa, (0x33d6:16)
	ld (0x32a1:16), wa
	ld wa, (0x33d8:16)
	ld (0x3291:16), wa
	ld a, (0x33da:16)
	ld (0x32ba:16), a
	ld a, (0x33db:16)
	ld (0x32b0:16), a
	ld a, (0x33d5:16)
	ld (0x32a8:16), a
	ld a, (0x33ea:16)
	ld (0x33f0:16), a
	ret

AccCh4_NoteOnEntry:
	calr AccCh4_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh4_NoteOnReturn
	ld a, (0x32c6:16)
	ld (0x32cb:16), a
	ld a, (0x32ca:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 251
	and (0x32f4:16), 247
	ld xhl, 0x2f94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_WriteExtendedEvent

AccCh4_NoteOnReturn:
	ret

AccCh4_CheckEligible:
	and (0x33e1:16), 254
	bit 5, (0x33de:16)
	jr z, AccCh4_CheckReturn
	bit 5, (0x3362:16)
	jr nz, AccCh4_CheckReturn
	bit 4, (0x3307:16)
	jr z, AccCh4_CheckReturn
	bit 2, (0x3310:16)
	jr z, AccCh4_CheckReturn
	bit 2, (0xc5a0:16)
	jr z, AccCh4_CheckReturn
	calr AccCh4_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh4_CheckReturn
	bit 1, (0x3335:16)
	jr nz, AccCh4_CheckReturn
	bit 0, (0x347a:16)
	jr nz, AccCh4_CheckReturn
	bit 0, (0x33e8:16)
	jr nz, AccCh4_CheckReturn
	ld xhl, 0x2f94
	call AccBuf_ComputeFillLevel
	cpw (0x3324:16), 16
	jr ugt, AccCh4_SetReady
	calr AccBuf_InitWithDefaults
	jr AccCh4_CheckReturn

AccCh4_SetReady:
	or (0x33e1:16), 1

AccCh4_CheckReturn:
	ret

AccCh4_DTypeEntry:
	calr AccCh4_CheckEligible
	bit 0, (0x33e1:16)
	jr z, AccCh4_DTypeReturn
	ld xhl, 0x2f94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	calr AccBuf_Write3ByteEvent

AccCh4_DTypeReturn:
	ret

AccCh4_CheckOverlap:
	ld a, 0x0:opc
	bit 2, (0x34cf:16)
	jr z, AccCh4_OverlapReturn
	bit 2, (0x379b:16)
	jr z, AccCh4_OverlapReturn
	ld a, 0x1:opc

AccCh4_OverlapReturn:
	ret

AccCh4_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x32f4:16)
	jr nz, AccCh4_ProcessReturn
	calr AccCh4_ScanSlots
	calr AccCh4_DrainRingBuf
	calr AccCh4_InitProgChange
	ld xiy, 0x3228
	ld xix, 0x3241
	ld bc, 5:i3
	ldir85
	ld a, (0x343c:16)
	ld (0x32ec:16), a
	call AccVoice_LoadRhythmParams_Part5
	and (0x332c:16), 223

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
	ld	a, (xhl+iy)
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
	ld (0x342d:16), 208
	ld a, (0x343c:16)
	ld (0x342e:16), a
	ld (0x342f:16), 2
	ld (0x3430:16), 64
	calr AccBuf_Write3ByteEvent
	ld a, (0x343c:16)
	ld (0x342e:16), a
	ld (0x342f:16), 1
	ld (0x3430:16), 0
	calr AccBuf_Write3ByteEvent
	ld a, (0x343c:16)
	ld (0x342e:16), a
	ld (0x342f:16), 3
	ld (0x3430:16), 0
	calr AccBuf_Write3ByteEvent
	ld a, (0x343c:16)
	ld (0x342e:16), a
	ld (0x342f:16), 5
	ld (0x3430:16), 127
	calr AccBuf_Write3ByteEvent
	ret

AccPart_Deactivate:
	ld a, (0x3470:16)
	and a, 0xc0
	jr nz, AccPart_Deactivate_WithPedal
	ld a, (0x33d4:16)
	and a, (0x3329:16)
	jr z, AccPart_Deactivate_NoPedal

AccPart_Deactivate_WithPedal:
	calr AccPart_ResolveWithPedal
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x3329:16), a
	jrl AccPart_DeactivateReturn

AccPart_Deactivate_NoPedal:
	ld a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	and a, (0x33d4:16)
	jr nz, AccPart_Deactivate_ActiveNote
	bit 0, (0x3301:16)
	jr nz, AccPart_Deactivate_WithSync
	bit 0, (0x330f:16)
	jr nz, AccPart_Deactivate_SetDone
	jr AccPart_Deactivate_SendOff

AccPart_Deactivate_WithSync:
	and (0x330e:16), 252
	or (0x330e:16), 1
	ld a, (0x33d4:16)
	and a, (0x3312:16)
	jr z, AccPart_Deactivate_SetDone
	or (0x330e:16), 2
	jr AccPart_Deactivate_SetDone

AccPart_Deactivate_ActiveNote:
	bit 0, (0x330f:16)
	jr z, AccPart_Deactivate_SendOff

AccPart_Deactivate_SetDone:
	or (0x32f3:16), 128
	or (0x32f4:16), 1
	jr AccPart_Deactivate_ClearMasks

AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x3312:16), a
	and (0x3313:16), a
	and (0x3316:16), a
	and (0x3317:16), a
	and (0x3318:16), a
	ld (0x33db:16), 0
	ld (0x33ea:16), 0

AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	ld a, (0x33d4:16)
	and a, (0x33e0:16)
	jr z, AccPart_ReactivateReturn
	ld a, (0x33d4:16)
	ld w, (0x3314:16)
	or w, (0x3315:16)
	and w, a
	jr z, AccPart_Reactivate_Inactive
	or (0x332a:16), a
	or (0x3328:16), a
	ld (0x33d6:16), 254
	ld (0x33d8:16), 6
	jr AccPart_ReactivateReturn

AccPart_Reactivate_Inactive:
	ld a, (0x33d4:16)
	xor a, 0xff
	and (0x3312:16), a
	and (0x3313:16), a
	and (0x3316:16), a
	and (0x3317:16), a
	and (0x3318:16), a
	and (0x335d:16), a
	and (0x3329:16), a
	ld (0x33ea:16), 0
	ld (0x33d6:16), 254
	ld (0x33d8:16), 6

AccPart_ReactivateReturn:
	ret

AccTick_Main:
	bit 2, (0x3283:16)
	jrl nz, AccTick_CheckCollect
	calr AccTempo_BarCompare
	bit 6, (0x32f4:16)
	jrl nz, AccTick_Return
	calr AccPedal_CheckCombined
	bit 6, (0x32f4:16)
	jrl nz, AccTick_Return
	call AccTuning_ApplyChange
	bit 7, (0x332c:16)
	jr z, AccTick_AfterSync
	call Rhythm_ProcessAllPartsAndLoad
	and (0x332c:16), 127

AccTick_AfterSync:
	call AccVoice_ProcessAllSixParts
	bit 5, (0x32f4:16)
	jrl nz, AccTick_Return
	call AccKbd2_ProcessEntry
	call AccSeq_ScanPattern
	bit 0, (0x347a:16)
	jr nz, AccTick_ProcessAccChannels
	bit 0, (0x3283:16)
	jr z, AccTick_CheckNoteOn
	ld wa, (0xc596:16)
	and wa, 0x200
	jr z, AccTick_CheckNoteOn

AccTick_ProcessAccChannels:
	call AccCh1_ProcessEntry
	call AccCh2_ProcessEntry
	call AccCh3_ProcessEntry
	call AccCh4_ProcessEntry

AccTick_CheckNoteOn:
	bit 7, (0x32f3:16)
	jr z, AccTick_CheckCollect
	and (0x32f3:16), 127
	call AccTempo_CalcPosition
	bit 0, (0x330e:16)
	jr nz, AccTick_DispatchNoteOn
	bit 0, (0x330f:16)
	jr nz, AccTick_DispatchNoteOn
	bit 0, (0x330d:16)
	jr nz, AccTick_DispatchNoteOn
	bit 0, (0x330c:16)
	jr nz, AccTick_DispatchNoteOn
	ld a, (0x3309:16)
	and a, 0x3
	jr nz, AccTick_DispatchNoteOn
	ld a, (0x330a:16)
	and a, 0xd
	jr nz, AccTick_DispatchNoteOn
	ld a, (0x330b:16)
	and a, 0x3
	jr z, AccTick_FlushAndRepeat

AccTick_DispatchNoteOn:
	call AccFlags_Aggregate

AccTick_FlushAndRepeat:
	call AccNote_FlushAll
	jrl AccTick_AfterSync

AccTick_CheckCollect:
	bit 2, (0x3283:16)
	jr z, AccTick_Return
	call AccState_CollectAll

AccTick_Return:
	ret

AccVelocity_CurveTable:
	.byte 0x0d, 0x1a, 0x33, 0x4d, 0x66, 0x80, 0x9a, 0xb3
	.byte 0xcc, 0xe6, 0xff

AccVoice_InitPerChannel:
	cp (0x33d4:16), 4
	jr nz, AccVoice_InitCh2
	calr AccVoice_InitCh1_D7
	jr AccVoice_InitReturn

AccVoice_InitCh2:
	cp (0x33d4:16), 8
	jr nz, AccVoice_InitCh3
	calr AccVoice_InitCh2_D4
	jr AccVoice_InitReturn

AccVoice_InitCh3:
	cp (0x33d4:16), 16
	jr nz, AccVoice_InitCh4
	calr AccVoice_InitCh3_D5
	jr AccVoice_InitReturn

AccVoice_InitCh4:
	cp (0x33d4:16), 32
	jr nz, AccVoice_InitReturn
	calr AccVoice_InitCh4_D6

AccVoice_InitReturn:
	ret

AccVoice_InitCh1_D7:
	pushw hl
	push xiy
	ld xhl, 0x2c94
	calr AccBuf_DrainAndReset
	ld a, 0xd7:opc
	ld w, 0x2:opc
	ld e, 0x40:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd7:opc
	ld w, 0x1:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd7:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld (0x332f:16), 0
	ld a, 0xd7:opc
	ld w, 0x5:opc
	ld e, 0x7f:opc
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccBuf_WriteD0WithVoice:
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0xd0
	call RingBuf_AdvanceIndex
	ld a, (0x32ea:16)
	ld (0x342e:16), a
	call RhythmAccent_UpdateRingBufPosition
	ld	(xhl+iy), 0x03
	call RingBuf_AdvanceIndex
	ld a, (0x3333:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ret

AccVoice_InitCh2_D4:
	pushw hl
	push xiy
	ld xhl, 0x2d94
	calr AccBuf_DrainAndReset
	ld a, 0xd4:opc
	ld w, 0x2:opc
	ld e, 0x40:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd4:opc
	ld w, 0x1:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd4:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld (0x3330:16), 0
	ld a, 0xd4:opc
	ld w, 0x5:opc
	ld e, 0x7f:opc
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh3_D5:
	pushw hl
	push xiy
	ld xhl, 0x2e94
	calr AccBuf_DrainAndReset
	ld a, 0xd5:opc
	ld w, 0x2:opc
	ld e, 0x40:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd5:opc
	ld w, 0x1:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd5:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld (0x3331:16), 0
	ld a, 0xd5:opc
	ld w, 0x5:opc
	ld e, 0x7f:opc
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccVoice_InitCh4_D6:
	pushw hl
	push xiy
	ld xhl, 0x2f94
	calr AccBuf_DrainAndReset
	ld a, 0xd6:opc
	ld w, 0x2:opc
	ld e, 0x40:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd6:opc
	ld w, 0x1:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld a, 0xd6:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ld (0x3332:16), 0
	ld a, 0xd6:opc
	ld w, 0x5:opc
	ld e, 0x7f:opc
	call Rhythm_Send3ByteMsg
	pop xiy
	popw hl
	ret

AccPedal_CheckCombined:
	bit 0, (0x330c:16)
	jr nz, AccPedal_CheckFlags
	ld a, (0x330b:16)
	and a, 0x3
	jr z, AccPedal_CheckDirection

AccPedal_CheckFlags:
	ld a, (0x3326:16)
	and a, 0x3f
	jr z, AccPedal_TriggerReInit

AccPedal_CheckDirection:
	ld a, (0x330a:16)
	and a, 0xd
	jr nz, AccPedal_CheckCounter
	ld a, (0x3309:16)
	and a, 0x3
	jr z, AccPedal_CombinedReturn

AccPedal_CheckCounter:
	ld a, (0x3327:16)
	and a, 0x3f
	jr nz, AccPedal_CombinedReturn

AccPedal_TriggerReInit:
	calr AccInit_FullReInit

AccPedal_CombinedReturn:
	ret

AccTick_ByteData:
	call	Rhythm_SendNoteOnMax
	call	AccompVoice_BulkReadRegisters
	calr	AccBuf_WriteAllNotesOff
	call	Rhythm_SendChanPressure
	calr	AccBuf_ResetAll4
	ld	a, (0x3312:16)
	or	a, (0x3313:16)
	and	a, 63
	jr	z, AccPedal_CheckCombined_Entry
	bit	0, (0x3301:16)
	jr	z, AccPedal_CheckCombined_Entry
	or	(0x330c:16), 1
	ld	a, (0x3312:16)
	and	a, 63
	jr	z, AccPedal_CheckCombined_Skip
	cp	(0x333a:16), 0
	jr	z, AccPedal_CheckCombined_Entry
	dec	1, (0x333a:16)
	jr	AccPedal_CheckCombined_Entry
AccPedal_CheckCombined_Skip:
	cp	(0x333a:16), 3
	jr	z, AccPedal_CheckCombined_Entry
	inc	1, (0x333a:16)
AccPedal_CheckCombined_Entry:
	bit	0, (0x330f:16)
	jr	nz, AccPedal_CheckCombined_Skip2
	bit	0, (0x330c:16)
	jr	z, AccPedal_CheckCombined_Skip3
	ld	a, (0x3326:16)
	and	a, 63
	jr	nz, AccPedal_CheckCombined_Skip3
AccPedal_CheckCombined_Skip2:
	calr	AccStyle_Init
	calr	AccVoice_SetupAllParts
	ld	a, (1075:16)
	ld	(1112:16), a
AccPedal_CheckCombined_Skip3:
	ld	a, (0x330a:16)
	and	a, 13
	jr	z, AccPedal_CheckCombined_Skip5
	calr	AccVoice_ResetAll
AccPedal_CheckCombined_Skip5:
	ld	a, (0x3309:16)
	and	a, 3
	jr	nz, AccPedal_CheckCombined_Join
	bit	6, (0x3470:16)
	jr	z, AccPedal_CheckCombined_Skip6
	or	(0x3309:16), 1
	jr	AccPedal_CheckCombined_Join
AccPedal_CheckCombined_Skip6:
	bit	7, (0x3470:16)
	jr	z, AccPedal_CheckCombined_Skip7
	or	(0x3309:16), 2
AccPedal_CheckCombined_Join:
	calr	AccVoice_SplitPointSetup
AccPedal_CheckCombined_Skip7:
	ld	a, (0x330b:16)
	and	a, 3
	jr	z, AccPedal_CheckCombined_Skip8
	calr	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	calr	AccVoice_ThirdLayer
AccPedal_CheckCombined_Skip8:
	and	(0x32ab:16), 240
	and	(0x32ac:16), 240
	and	(0x32ad:16), 240
	and	(0x32ae:16), 240
	and	(0x32af:16), 240
	and	(0x32b0:16), 240
	calr	AccSeq_DualPartScan
	bit	6, (0x32f4:16)
	jr	nz, AccPedal_CheckCombined_Skip4
	calr	AccSeq_FourChannelScan
AccPedal_CheckCombined_Skip4:
	or	(0x332c:16), 128
	ret

AccTempo_BarCompare:
	ld w, (0x32b5:16)
	cp w, (0x32b4:16)
	jr c, AccTempo_BarLess
	jr z, AccTempo_BarEqual
	jr ugt, AccTempo_BarGreater

AccTempo_BarLess:
	cp w, 0:i3
	jr nz, AccTempo_BarChanged
	cp (0x32b4:16), 255
	jr nz, AccTempo_BarChanged
	jr AccTempo_ComputeSubDelta

AccTempo_BarEqual:
	ld wa, (0x32e3:16)
	cp (0x3280:16), w
	jr c, AccTempo_ComputeSubDelta
	jr ugt, AccTempo_BarChanged
	cp (0x327f:16), a
	jr ule, AccTempo_ComputeSubDelta
	jr AccTempo_BarChanged

AccTempo_BarGreater:
	cp w, 0xff
	jr nz, AccTempo_ComputeSubDelta
	cp (0x32b4:16), 0
	jr nz, AccTempo_ComputeSubDelta

AccTempo_BarChanged:
	ld a, 0x1:opc
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	ld wa, (0x32e3:16)
	sub a, (0x327f:16)
	jr nc, AccTempo_StoreDelta
	add a, 0x60

AccTempo_StoreDelta:
	ld (0x32ea:16), a
	ld (0x32ec:16), a
	ret

AccSeq_DualPartScan:
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x3287:16)
	ld (0x33d8:16), wa
	ld a, (0x32ab:16)
	ld (0x33db:16), a
	ld iz, (0x3297:16)
	ld (0x33d6:16), iz
	ld w, 0x1:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x3297:16), wa
	ld a, (0x33db:16)
	ld (0x32ab:16), a
	ld wa, (0x33d8:16)
	ld (0x3287:16), wa
	bit 6, (0x32f4:16)
	jr nz, AccSeq_DualPartReturn
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x3289:16)
	ld (0x33d8:16), wa
	ld a, (0x32ac:16)
	ld (0x33db:16), a
	ld iz, (0x3299:16)
	ld (0x33d6:16), iz
	ld w, 0x2:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x3299:16), wa
	ld a, (0x33db:16)
	ld (0x32ac:16), a
	ld wa, (0x33d8:16)
	ld (0x3289:16), wa

AccSeq_DualPartReturn:
	ret

AccSeq_PatternScanner:
	ld iy, (0x33d8:16)
	ld iz, (0x33d6:16)
	and (0x32f4:16), 254
	xor bc, bc

AccSeq_ScannerLoop:
	bit 0, (0x32f4:16)
	jrl nz, AccSeq_Scanner_Done
	ld	a, (xhl+iy)
	cp a, 0x81
	jr nz, AccSeq_Scanner_EventType
	add b, 0x1
	xor c, c
	cp de, bc
	jr nc, AccSeq_Scanner_BarEnd
	or (0x32f4:16), 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_BarEnd:
	ld a, (0x33db:16)
	inc 1, a
	ld w, a
	and a, 0xf
	cp a, (1075:16)
	jr nz, AccSeq_Scanner_StorePos
	and w, 0xf0
	add w, 0x10

AccSeq_Scanner_StorePos:
	ld (0x33db:16), w
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
	or (0x32f4:16), 1
	jr AccSeq_ScannerLoop

AccSeq_Scanner_SkipFields:
	ld	a, (xhl+iy)
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
	ld	a, (xhl+iy)
	ld (0x3333:16), a
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Unknown:
	inc 1, (0x32ee:16)
	cp (0x32ee:16), 32
	jr c, AccSeq_Scanner_Skip1
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	ld (0x32f5:16), 255
	or (0x32f4:16), 65

AccSeq_Scanner_Skip1:
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Done:
	ld (0x33d6:16), iz
	ld (0x33d8:16), iy
	ret

AccSeq_ScannerPadding:
	nop
	nop

AccBuf_AdvanceWithPageTurn:
	pushw iy
	inc 1, iy
	ld	a, (xhl+iy)
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
	ld	a, (xhl+iy)
	cp a, 0x87
	jr nz, AccBuf_AdvanceSimpleReturn
	ld hl, (xhl + 3)
	ld iz, hl
	calr AccWave_BankResolve
	ld iy, 6:i3

AccBuf_AdvanceSimpleReturn:
	ret

AccSeq_FourChannelScan:
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x328b:16)
	ld (0x33d8:16), wa
	ld a, (0x32ad:16)
	ld (0x33db:16), a
	ld iz, (0x329b:16)
	ld (0x33d6:16), iz
	ld w, 0x4:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x329b:16), wa
	ld a, (0x33db:16)
	ld (0x32ad:16), a
	ld wa, (0x33d8:16)
	ld (0x328b:16), wa
	ld xhl, 0x2c94
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x32f4:16)
	jrl nz, AccSeq_FourChannelReturn
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x328d:16)
	ld (0x33d8:16), wa
	ld a, (0x32ae:16)
	ld (0x33db:16), a
	ld iz, (0x329d:16)
	ld (0x33d6:16), iz
	ld w, 0x8:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x329d:16), wa
	ld a, (0x33db:16)
	ld (0x32ae:16), a
	ld wa, (0x33d8:16)
	ld (0x328d:16), wa
	ld xhl, 0x2d94
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x32f4:16)
	jrl nz, AccSeq_FourChannelReturn
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x328f:16)
	ld (0x33d8:16), wa
	ld a, (0x32af:16)
	ld (0x33db:16), a
	ld iz, (0x329f:16)
	ld (0x33d6:16), iz
	ld w, 0x10:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x329f:16), wa
	ld a, (0x33db:16)
	ld (0x32af:16), a
	ld wa, (0x33d8:16)
	ld (0x328f:16), wa
	ld xhl, 0x2e94
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x32f4:16)
	jr nz, AccSeq_FourChannelReturn
	ld de, (0x32e3:16)
	ld (0x32ee:16), 0
	ld (0x3333:16), 0
	ld wa, (0x3291:16)
	ld (0x33d8:16), wa
	ld a, (0x32b0:16)
	ld (0x33db:16), a
	ld iz, (0x32a1:16)
	ld (0x33d6:16), iz
	ld w, 0x20:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x33d6:16)
	ld (0x32a1:16), wa
	ld a, (0x33db:16)
	ld (0x32b0:16), a
	ld wa, (0x33d8:16)
	ld (0x3291:16), wa
	ld xhl, 0x2f94
	calr AccBuf_WriteD0WithVoice

AccSeq_FourChannelReturn:
	ret

AccStyle_Init:
	ld a, (0x32e8:16)
	and a, 0x7f
	and a, 0x7
	ld (0x32e6:16), a
	ld a, (0x32e7:16)
	ld (0x32e5:16), a
	call AccTuning_Init
	cp (0x32e5:16), 128
	jr nc, AccStyle_ExtendedInit
	ld a, (0x333a:16)
	and a, 0x3
	ld (0x3338:16), a
	ld a, (0x32e5:16)
	ld h, (0x32e6:16)
	call AccVoice_LookupWithOffset
	ld (0x32ce:16), xiy
	call Rhythm_UpdateTuningConfig
	ld a, (0x32a3:16)
	ld w, 0x0:opc
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	or (0x332c:16), 63
	jr AccStyle_Finalize

AccStyle_ExtendedInit:
	ld xiy, AccStyle_ExtStyleMap
	ld a, (0x32e5:16)
	and a, 0x7f
	cp a, 0x1d
	jr ule, AccStyle_LookupTable
	xor a, a

AccStyle_LookupTable:
	ld	a, (xiy+a)
	ld (0x3338:16), a
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccVoice_ResolveParamAddr
	ld (0x32ce:16), xiy
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
	ld (0x32d3:16), xiy
	call Rhythm_UpdateTuningConfig
	ld xiy, (0x32ce:16)
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	ld w, (0x32e5:16)
	call AccPatch_SetByChordIndex

AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr AccInit_ClearAllFlags

AccInit_ClearAllFlags:
	and (0x330c:16), 254
	and (0x330d:16), 254
	and (0x330e:16), 252
	xor a, a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x334d:16), a
	ld (0x32bd:16), a
	ld (0x32be:16), a
	ld (0x32bf:16), a
	ld (0x32c0:16), a
	ld (0x32c1:16), a
	ld (0x32c2:16), a
	call AccTone_CallWithSaveAll
	ret

AccVoice_SetupAllParts:
	cp (0x32e5:16), 128
	jr c, AccVoice_SetupAll_Extended
	ld xiy, (0x32ce:16)
	jr AccVoice_SetupAll_Dispatch

AccVoice_SetupAll_Extended:
	ld xiy, (0x32ce:16)
	ld	a, (xiy+977)
	ld (0x3285:16), a

AccVoice_SetupAll_Dispatch:
	calr AccVoice_SetupKbd1
	calr AccVoice_SetupKbd2
	calr AccVoice_SetupAcc1
	calr AccVoice_SetupAcc2
	calr AccVoice_SetupAcc3
	calr AccVoice_SetupAcc4
	ret

AccVoice_SetupKbd1:
	and (0x32ab:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupKbd1_Free
	ld (0x33d4:16), 1
	ld a, (0x32a3:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3287:16), wa
	jr AccVoice_SetupKbd1_Return

AccVoice_SetupKbd1_Free:
	ld (0x33d4:16), 1
	call AccPart_GetFreeVoiceAddr
	ld (0x3297:16), wa
	ldw (0x3287:16), 6

AccVoice_SetupKbd1_Return:
	ret

AccVoice_SetupKbd2:
	and (0x32ac:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupKbd2_Free
	ld (0x33d4:16), 2
	ld a, (0x32a4:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3289:16), wa
	jr AccVoice_SetupKbd2_Return

AccVoice_SetupKbd2_Free:
	ld (0x33d4:16), 2
	call AccPart_GetFreeVoiceAddr
	ld (0x3299:16), wa
	ldw (0x3289:16), 6

AccVoice_SetupKbd2_Return:
	ret

AccVoice_SetupAcc1:
	and (0x32ad:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupAcc1_Free
	ld (0x33d4:16), 4
	ld a, (0x32a5:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328b:16), wa
	jr AccVoice_SetupAcc1_Return

AccVoice_SetupAcc1_Free:
	ld (0x33d4:16), 4
	call AccPart_GetFreeVoiceAddr
	ld (0x329b:16), wa
	ldw (0x328b:16), 6

AccVoice_SetupAcc1_Return:
	ret

AccVoice_SetupAcc2:
	and (0x32ae:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupAcc2_Free
	ld (0x33d4:16), 8
	ld a, (0x32a6:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328d:16), wa
	jr AccVoice_SetupAcc2_Return

AccVoice_SetupAcc2_Free:
	ld (0x33d4:16), 8
	call AccPart_GetFreeVoiceAddr
	ld (0x329d:16), wa
	ldw (0x328d:16), 6

AccVoice_SetupAcc2_Return:
	ret

AccVoice_SetupAcc3:
	and (0x32af:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupAcc3_Free
	ld (0x33d4:16), 16
	ld a, (0x32a7:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x328f:16), wa
	jr AccVoice_SetupAcc3_Return

AccVoice_SetupAcc3_Free:
	ld (0x33d4:16), 16
	call AccPart_GetFreeVoiceAddr
	ld (0x329f:16), wa
	ldw (0x328f:16), 6

AccVoice_SetupAcc3_Return:
	ret

AccVoice_SetupAcc4:
	and (0x32b0:16), 15
	cp (0x32e5:16), 128
	jr nc, AccVoice_SetupAcc4_Free
	ld (0x33d4:16), 32
	ld a, (0x32a8:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x3291:16), wa
	jrl AccVoice_SetupAcc4_Return

AccVoice_SetupAcc4_Free:
	ld (0x33d4:16), 32
	call AccPart_GetFreeVoiceAddr
	ld (0x32a1:16), wa
	ldw (0x3291:16), 6

AccVoice_SetupAcc4_Return:
	ret

AccVoice_ResetAll:
	and (0x32ab:16), 15
	and (0x32ac:16), 15
	and (0x32ad:16), 15
	and (0x32ae:16), 15
	and (0x32af:16), 15
	and (0x32b0:16), 15
	cp (0x32e5:16), 128
	jr c, AccVoice_Reset_UseStyle
	bit 0, (0x3363:16)
	jr z, AccVoice_Reset_UseSecondary
	calr AccVoice_Reassign
	jr AccVoice_Reset_SetMasks

AccVoice_Reset_UseSecondary:
	ld xiy, (0x32d3:16)
	jr AccVoice_Reset_SelectMode

AccVoice_Reset_UseStyle:
	ld xiy, (0x32ce:16)

AccVoice_Reset_SelectMode:
	ldw hl, 0x20
	bit 0, (0x330a:16)
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x22
	bit 2, (0x330a:16)
	jr nz, AccVoice_Reset_LoadParams
	ldw hl, 0x420

AccVoice_Reset_LoadParams:
	calr AccVoice_LoadAllParts
	cp (0x32e5:16), 128
	jr c, AccVoice_Reset_Extended
	ld xiy, (0x32ce:16)
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Reset_ApplyAll

AccVoice_Reset_Extended:
	ld a, (0x32a3:16)
	ld w, 0x3:opc
	bit 3, (0x330a:16)
	jr z, AccVoice_Reset_SetMode
	ld w, 0x4:opc

AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	or (0x332c:16), 63

AccVoice_Reset_SetMasks:
	bit 3, (0x330a:16)
	jrl nz, AccVoice_Reset_Mode3
	bit 2, (0x330a:16)
	jr nz, AccVoice_Reset_Mode2
	and (0x330a:16), 254
	or (0x3316:16), 63
	xor a, a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x3328:16), a
	ld (0x332a:16), a
	and (0x3283:16), 251
	jrl AccVoice_Reset_Return

AccVoice_Reset_Mode2:
	and (0x330a:16), 251
	or (0x3317:16), 63
	xor a, a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3316:16), a
	ld (0x3318:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x3328:16), a
	ld (0x332a:16), a
	and (0x3283:16), 251
	jr AccVoice_Reset_Return

AccVoice_Reset_Mode3:
	and (0x330a:16), 247
	or (0x3318:16), 63
	xor a, a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x3328:16), a
	ld (0x332a:16), a
	and (0x3283:16), 251

AccVoice_Reset_Return:
	ret

AccVoice_Reassign:
	bit 3, (0x330a:16)
	jrl nz, AccVoice_Reassign_Mode3
	bit 2, (0x330a:16)
	jr nz, AccVoice_Reassign_Mode2
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x3364:16)
	jr z, AccVoice_Reassign_MatchA
	and (0xfc5f:16), 251
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchA:
	ld a, (0x3365:16)
	call AccVoice_ResolveParamAddr
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode2:
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 1, 0x03, 0xec, 0xe0
	jr z, AccVoice_Reassign_Fallback
	and (0xfc5f:16), 247
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_Mode3:
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x3366:16)
	jr z, AccVoice_Reassign_MatchB
	and (0xfc60:16), 251
	ld e, 0x48:opc
	ld d, 0x6:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_Reassign_Apply

AccVoice_Reassign_MatchB:
	ld a, (0x3367:16)
	call AccVoice_ResolveParamAddr

AccVoice_Reassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	jr AccVoice_Reassign_Return

AccVoice_Reassign_Fallback:
	ld xiy, (0x32d3:16)
	ldw hl, 0x22
	calr AccVoice_LoadAllParts
	xor xhl, xhl
	ldw hl, 0x126
	call AccVoice_LoadTuningBlock
	or (0x332c:16), 63

AccVoice_Reassign_Return:
	ret

AccVoice_SplitPointSetup:
	and (0x32ab:16), 15
	and (0x32ac:16), 15
	and (0x32ad:16), 15
	and (0x32ae:16), 15
	and (0x32af:16), 15
	and (0x32b0:16), 15
	cp (0x32e5:16), 128
	jr c, AccVoice_Split_UseStyle
	bit 0, (0x3363:16)
	jr z, AccVoice_Split_UseSecondary
	calr AccVoice_SplitReassign
	jr AccVoice_Split_SetForward

AccVoice_Split_UseSecondary:
	ld xiy, (0x32d3:16)
	jr AccVoice_Split_LoadAndApply

AccVoice_Split_UseStyle:
	ld xiy, (0x32ce:16)

AccVoice_Split_LoadAndApply:
	ld a, (0x32a3:16)
	call AccVoice_ComputeParamAddr
	calr AccVoice_LoadAllParts
	ld a, (0x32a3:16)
	call AccTuning_SetAllFromLookup
	cp (0x32e5:16), 128
	jr c, AccVoice_Split_StyleMode
	ld xiy, (0x32ce:16)
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_Split_Apply63

AccVoice_Split_StyleMode:
	ld a, (0x32a3:16)
	ld w, 0x2:opc
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Split_Apply63:
	or (0x332c:16), 63

AccVoice_Split_SetForward:
	bit 0, (0x3309:16)
	jr z, AccVoice_Split_SetReverse
	and (0x3309:16), 254
	or (0x3312:16), 63
	xor a, a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3313:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x3328:16), a
	ld (0x332a:16), a
	and (0x3283:16), 251
	jr AccVoice_Split_Return

AccVoice_Split_SetReverse:
	and (0x3309:16), 253
	or (0x3313:16), 63
	xor a, a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3312:16), a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	ld (0x3328:16), a
	ld (0x332a:16), a
	and (0x3283:16), 251

AccVoice_Split_Return:
	ret

AccVoice_SplitReassign:
	bit 0, (0x3309:16)
	jr z, AccVoice_SplitReassign_Reverse
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x3368:16)
	jr z, AccVoice_SplitReassign_MatchFwd
	and (0xfc5f:16), 191
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchFwd:
	ld a, (0x3369:16)
	call AccVoice_ResolveParamAddr
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_Reverse:
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x336a:16)
	jr z, AccVoice_SplitReassign_MatchRev
	and (0xfc5f:16), 127
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_SplitReassign_Apply

AccVoice_SplitReassign_MatchRev:
	ld a, (0x336b:16)
	call AccVoice_ResolveParamAddr

AccVoice_SplitReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	ret

AccVoice_LoadAllParts:
	ld	a, (xiy+977)
	ld (0x3285:16), a
	ldfr_werp HL, 0x3c
	ld (0x33d4:16), 1
	call AccPart_GetParamAddr
	ld (0x3287:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 2
	call AccPart_GetParamAddr
	ld (0x3289:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 4
	call AccPart_GetParamAddr
	ld (0x328b:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 8
	call AccPart_GetParamAddr
	ld (0x328d:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 16
	call AccPart_GetParamAddr
	ld (0x328f:16), wa
	ldto_werp HL, 0x3c
	ld (0x33d4:16), 32
	call AccPart_GetParamAddr
	ld (0x3291:16), wa
	ret

AccInit_AllPartPositions:
	ld (0x33d4:16), 1
	call AccPart_GetFreeVoiceAddr
	ld (0x3297:16), wa
	ldw (0x3287:16), 6
	ld (0x33d4:16), 4
	call AccPart_GetFreeVoiceAddr
	ld (0x329b:16), wa
	ldw (0x328b:16), 6
	ld (0x33d4:16), 8
	call AccPart_GetFreeVoiceAddr
	ld (0x329d:16), wa
	ldw (0x328d:16), 6
	ld (0x33d4:16), 16
	call AccPart_GetFreeVoiceAddr
	ld (0x329f:16), wa
	ldw (0x328f:16), 6
	ld (0x33d4:16), 32
	call AccPart_GetFreeVoiceAddr
	ld (0x32a1:16), wa
	ldw (0x3291:16), 6
	ld (0x33d4:16), 2
	call AccPart_GetFreeVoiceAddr
	ld (0x3299:16), wa
	ldw (0x3289:16), 6
	ret

AccVoice_ThirdLayer:
	and (0x32ab:16), 15
	and (0x32ac:16), 15
	and (0x32ad:16), 15
	and (0x32ae:16), 15
	and (0x32af:16), 15
	and (0x32b0:16), 15
	cp (0x32e5:16), 128
	jr c, AccVoice_ThirdLayer_Style
	bit 0, (0x3363:16)
	jr z, AccVoice_ThirdLayer_Secondary
	calr AccVoice_ThirdLayerReassign
	jr AccVoice_ThirdLayer_SetMasks

AccVoice_ThirdLayer_Secondary:
	ld xiy, (0x32d3:16)
	jr AccVoice_ThirdLayer_SelectMode

AccVoice_ThirdLayer_Style:
	ld xiy, (0x32ce:16)

AccVoice_ThirdLayer_SelectMode:
	ldw hl, 0x24
	bit 0, (0x330b:16)
	jr nz, AccVoice_ThirdLayer_LoadParams
	ldw hl, 0x424

AccVoice_ThirdLayer_LoadParams:
	calr AccVoice_LoadAllParts
	ld a, (0x32a3:16)
	call AccTuning_SetAllFromLookup
	cp (0x32e5:16), 128
	jr c, AccVoice_ThirdLayer_StyleMode
	ld xiy, (0x32ce:16)
	call AccTuning_CopyAllPartsFromStyle
	jr AccVoice_ThirdLayer_Apply

AccVoice_ThirdLayer_StyleMode:
	ld a, (0x32a3:16)
	ld w, 0x5:opc
	bit 1, (0x330b:16)
	jr z, AccVoice_ThirdLayer_SetModeW
	ld w, 0x6:opc

AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	or (0x332c:16), 63

AccVoice_ThirdLayer_SetMasks:
	bit 0, (0x330b:16)
	jr z, AccVoice_ThirdLayer_Reverse
	and (0x330b:16), 254
	or (0x3314:16), 63
	xor a, a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3315:16), a
	ld (0x335d:16), a
	jr AccVoice_ThirdLayer_Return

AccVoice_ThirdLayer_Reverse:
	and (0x330b:16), 253
	or (0x3315:16), 63
	xor a, a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3314:16), a
	ld (0x335d:16), a

AccVoice_ThirdLayer_Return:
	ret

AccVoice_ThirdLayerReassign:
	bit 0, (0x330b:16)
	jr z, AccVoice_ThirdReassign_Reverse
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x336c:16)
	jr z, AccVoice_ThirdReassign_MatchFwd
	and (0xfc5f:16), 239
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchFwd:
	ld a, (0x336d:16)
	call AccVoice_ResolveParamAddr
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_Reverse:
	ld a, (0x32e5:16)
	and a, 0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x336e:16)
	jr z, AccVoice_ThirdReassign_MatchRev
	and (0xfc5f:16), 223
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x32ce:16)
	jr AccVoice_ThirdReassign_Apply

AccVoice_ThirdReassign_MatchRev:
	ld a, (0x336f:16)
	call AccVoice_ResolveParamAddr

AccVoice_ThirdReassign_Apply:
	calr AccInit_AllPartPositions
	call AccTuning_CopyAllPartsFromStyle
	or (0x332c:16), 63
	ret

AccBuf_WriteAllNotesOff:
	ld xhl, 0x2a94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0x9f
	call RingBuf_AdvanceIndex
	ld a, (0x32ea:16)
	ld (0x342e:16), a
	call RhythmAccent_UpdateRingBufPosition
	ld a, 0x7f:opc
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), a
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
	ld	a, (xhl+iy)
	cp a, 0xd0
	jr z, AccBuf_DrainReset_D0Found
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_D0Found:
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	ld	a, (xhl+iy)
	cp a, 2:i3
	jr nz, AccBuf_DrainReset_Sub1
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x40
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub1:
	cp a, 1:i3
	jr nz, AccBuf_DrainReset_Sub3
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub3:
	cp a, 3:i3
	jr nz, AccBuf_DrainReset_Sub5
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x00
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Sub5:
	cp a, 5:i3
	jr nz, AccBuf_DrainReset_Other
	call RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x7f
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Other:
	call RingBuf_AdvanceIndex
	jr AccBuf_DrainReset_Loop

AccBuf_DrainReset_Done:
	ret

AccTiming_CallHelper:
	bit 1, (0x3284:16)
	jr z, AccTiming_HelperReturn
	call SeqEvt_CallTimingHelper
	call Voice_UpdatePlayModeState
	call AccChord_ReadAndStoreKeys
	call AccChord_CompareAndSetDirty
	call Rhythm_CompareAndTrigger

AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	cp (0x32e5:16), 128
	jr c, AccVoice_SelectByMask_Default
	ldfr_berp W, 0x31
	and w, (0x3317:16)
	jr nz, AccVoice_SelectByMask_Default
	bit 0, (0x3363:16)
	jr nz, AccVoice_SelectByMask_Direct
	ld a, (0x3316:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	or a, (0x3328:16)
	andb_erp A, 0x31
	jr nz, AccVoice_SelectByMask_Default

AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	ld a, (0x3285:16)
	call AccVoice_TableLookup

AccVoice_SelectReturn:
	ret

AccWave_BankResolve_Short:
	cp	iz, 0xfffe
	jr	nz, AccVoice_SelectByMask_Skip
	ld	xhl, 0x095bc0
	jr	AccVoice_SelectByMask_Return
AccVoice_SelectByMask_Skip:
	extz	xiz
	ld	xhl, xiz
	sla	xhl, 8
	add	xhl, RHYTHM_PATTERN_BUF_B
AccVoice_SelectByMask_Return:
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
	ld	xix, (xix+wa)
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
	add xhl, (RHYTHM_ROM_BASE:16)
	ret

AccVoice_OffsetTable:
; AccVoice_OffsetTable (64 x LE32), 2026-09-02 (lane v10seq).
; AccVoice_TableLookup_Inner: cp a,0x3f else xor a,a / ld hl,wa /
; sll xhl,2 / add xhl,<this label> / ld xhl,(xhl) -- a LONG load at
; stride 4, and the bound gives exactly the 64 entries below.
	.long 0x00400000, 0x00410000, 0x00420000, 0x00430000
	.long 0x00440000, 0x00450000, 0x00460000, 0x00470000
	.long 0x00480000, 0x00490000, 0x004a0000, 0x004b0000
	.long 0x004c0000, 0x004d0000, 0x004e0000, 0x004f0000
	.long 0x00500000, 0x00510000, 0x00520000, 0x00530000
	.long 0x00540000, 0x00550000, 0x00560000, 0x00570000
	.long 0x00580000, 0x00590000, 0x005a0000, 0x005b0000
	.long 0x005c0000, 0x005d0000, 0x005e0000, 0x005f0000
	.long 0x00600000, 0x00610000, 0x00620000, 0x00630000
	.long 0x00640000, 0x00650000, 0x00660000, 0x00670000
	.long 0x00680000, 0x00690000, 0x006a0000, 0x006b0000
	.long 0x006c0000, 0x006d0000, 0x006e0000, 0x006f0000
	.long 0x00700000, 0x00710000, 0x00720000, 0x00730000
	.long 0x00740000, 0x00750000, 0x00760000, 0x00770000
	.long 0x00780000, 0x00790000, 0x007a0000, 0x007b0000
	.long 0x007c0000, 0x007d0000, 0x007e0000, 0x007f0000
AccState_CollectAll:
	bit 3, (1054:16)
	jrl nz, AccState_CollectReturn
	bit 2, (1054:16)
	jrl z, AccState_CollectReturn
	ld xhl, 0x3094
	xor iy, iy
	ld	a, (xhl+iy)

AccState_CollectKbd1_Loop:
	or	a, (xhl+iy)
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd1_Loop
	ld xhl, 0x30c4
	xor iy, iy

AccState_CollectKbd2_Loop:
	or	a, (xhl+iy)
	add iy, 0x6
	cp iy, 0x30
	jr c, AccState_CollectKbd2_Loop
	ld xhl, 0x30f4
	xor iy, iy

AccState_CollectAcc1_Loop:
	or	a, (xhl+iy)
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc1_Loop
	ld xhl, 0x313c
	xor iy, iy

AccState_CollectAcc2_Loop:
	or	a, (xhl+iy)
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc2_Loop
	ld xhl, 0x3184
	xor iy, iy

AccState_CollectAcc3_Loop:
	or	a, (xhl+iy)
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc3_Loop
	ld xhl, 0x31cc
	xor iy, iy

AccState_CollectAcc4_Loop:
	or	a, (xhl+iy)
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc4_Loop
	bit 7, a
	jr nz, AccState_CollectReturn
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr nz, AccState_CollectAcc4_Active
	cpw (0x28a8:16), 0
	jr nz, AccState_CollectAcc4_Active
	call AccWrap_PlayModeStopSync
	jr AccState_Apply

AccState_CollectAcc4_Active:
	call AccWrap_PlayModeStartPlay

AccState_Apply:
	call AccInit_CallF435A9
	ld a, (0xcedf:16)
	ld (0x8d42:16), a
	ld a, (0xcee0:16)
	ld (0x8d40:16), a
	call AccDisplay_RefreshIfDiskActive
	and (0xfc5f:16), 207
	and (0x3283:16), 251
	xor a, a
	ld (0x3314:16), a
	ld (0x3315:16), a
	ld (0x3312:16), a
	ld (0x3313:16), a
	ld (0x3316:16), a
	ld (0x3317:16), a
	ld (0x3318:16), a
	or (0x349f:16), 2

AccState_CollectReturn:
	ret

AccState_ScanLookupTable:
	nop
	normal
	push sr
	pop sr
	max
	nop
	normal
	push sr
	pop sr
	max
	nop
	normal
	push sr
	pop sr
	max
	nop
	normal
	push sr
	pop sr
	max
	nop
	nop
	nop
	nop
	.zero 10

AccVoice_ScanForD3:
	ld	a, (xhl+iy)
	cp a, 0x83
	jr z, AccVoice_ScanDone2
	cp a, 0xd3
	jr nz, AccVoice_ScanSkip
	call AccBuf_Advance
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3333:16), a

AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	ld	(0x33d4:16), 4
	ld	e, (0x3349:16)
	ld	(0x3333:16), 0
AccVoice_ScanForD3_Join:
	ld	xiy, (0x32ce:16)
	cp e, (12965:16)
	jr z, AccVoice_ScanForD3_Return
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x3285:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join
AccVoice_ScanForD3_Return:
	ret
	ld	(0x33d4:16), 8
	ld	e, (0x3349:16)
	ld	(0x3333:16), 0
AccVoice_ScanForD3_Join2:
	ld	xiy, (0x32ce:16)
	cp e, (12966:16)
	jr z, AccVoice_ScanForD3_Return2
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x3285:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join2
AccVoice_ScanForD3_Return2:
	ret
	ld	(0x33d4:16), 8
	ld	e, (0x3349:16)
	ld	(0x3333:16), 0
AccVoice_ScanForD3_Join3:
	ld	xiy, (0x32ce:16)
	cp e, (12967:16)
	jr z, AccVoice_ScanForD3_Return3
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x3285:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join3
AccVoice_ScanForD3_Return3:
	ret
	ld	(0x33d4:16), 8
	ld	e, (0x3349:16)
	ld	(0x3333:16), 0
AccVoice_ScanForD3_Join4:
	ld	xiy, (0x32ce:16)
	cp e, (12968:16)
	jr z, AccVoice_ScanForD3_Return4
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x3285:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join4
AccVoice_ScanForD3_Return4:
	ret
	.byte 0xc3, 0xf5, 0xd1
	pop	sr
	ld	a, 241:opc
	.byte 0x85
	ldw	de, 0xf141
	.byte 0xd4
	ldw	hl, 256
	ld	a, (0x32a3:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x3287:16), wa
	ld	(0x33d4:16), 2
	ld	a, (0x32a4:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x3289:16), wa
	ld	(0x33d4:16), 4
	ld	a, (0x32a5:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x328b:16), wa
	ld	(0x33d4:16), 8
	ld	a, (0x32a6:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x328d:16), wa
	ld	(0x33d4:16), 16
	ld	a, (0x32a7:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x328f:16), wa
	ld	(0x33d4:16), 32
	ld	l, (0x32a8:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x3291:16), wa
	ret

AccFlags_Aggregate:
	and (0x3326:16), 192
	and (0x3327:16), 192
	calr AccBuf_ResetAll4Positions
	bit 0, (0x330e:16)
	jr z, AccFlags_BuildIndex
	or (0x330d:16), 1
	bit 1, (0x330e:16)
	jr z, AccFlags_CheckDecay
	cp (0x333a:16), 0
	jr z, AccFlags_BuildIndex
	dec 1, (0x333a:16)
	jr AccFlags_BuildIndex

AccFlags_CheckDecay:
	cp (0x333a:16), 3
	jr z, AccFlags_BuildIndex
	inc 1, (0x333a:16)

AccFlags_BuildIndex:
	xor w, w
	ld a, (0x330a:16)
	and a, 0xd
	jr z, AccFlags_CheckDir65
	or w, 0x1

AccFlags_CheckDir65:
	ld a, (0x3309:16)
	and a, 0x3
	jr z, AccFlags_CheckDir67
	or w, 0x2

AccFlags_CheckDir67:
	ld a, (0x330b:16)
	and a, 0x3
	jr z, AccFlags_CheckNoteOn
	or w, 0x4

AccFlags_CheckNoteOn:
	bit 0, (0x330c:16)
	jr z, AccFlags_CheckSync69
	or w, 0x8
	bit 6, (0x3470:16)
	jr z, AccFlags_PedalBit7
	or w, 0x2
	or (0x3309:16), 1

AccFlags_PedalBit7:
	bit 7, (0x3470:16)
	jr z, AccFlags_CheckSync69
	or w, 0x2
	or (0x3309:16), 2

AccFlags_CheckSync69:
	bit 0, (0x330d:16)
	jr z, AccFlags_CheckSync71
	or w, 0x8

AccFlags_CheckSync71:
	bit 0, (0x330f:16)
	jr z, AccFlags_Dispatch
	or w, 0x8

AccFlags_Dispatch:
	and w, 0xf
	sla w, 2
	ld xhl, AccFlags_JumpTable
	ld	xwa, (xhl+w)
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
	and	(0x3316:16), 192
	and	(0x3317:16), 192
	and	(0x3318:16), 192
	and	(0x3312:16), 192
	and	(0x3313:16), 192
	jr	AccFlags_Handler9_Join
AccFlags_Handler4:
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	AccFlags_Handler9_Join
AccFlags_Handler8:
	call	AccStyle_Init
	call	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	call	AccVoice_ThirdLayer
	jr	t, AccFlags_Handler9_Join
AccFlags_Handler2:
	call	AccVoice_SplitPointSetup
	jr	AccFlags_Handler9_Join
AccFlags_Handler10:
	call	AccStyle_Init
	call	AccVoice_SplitPointSetup
	jr	t, AccFlags_Handler9_Join
AccFlags_Handler1:
	call	AccVoice_ResetAll
	jr	AccFlags_Handler9_Join
AccFlags_Handler9:
	call	AccStyle_Init
	call	AccVoice_ResetAll
AccFlags_Handler9_Join:
	call	Rhythm_Send_Ch90_7F_7E
	call	Rhythm_SendChanPressure
	calr	AccBuf_ResetByteData
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
	ld (xhl + 0:8), 0xa
	ld (xhl + 2), 0xff
	ldw wa, 0xa
	ldw bc, 0xa
	ei 6
	ld (xhl + 4), wa
	ld (xhl + 6), bc
	ei 0
	ret

AccBuf_ResetByteData:
	ld	a, 0:opc
	ld	xhl, 0x30f4
	xor	iy, iy
AccBuf_ResetByteData_Loop:
	ld	(xhl+iy), a
	add iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop
	ld	xhl, 0x313c
	xor	iy, iy
AccBuf_ResetByteData_Loop2:
	ld	(xhl+iy), a
	add iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop2
	ld	xhl, 0x3184
	xor	iy, iy
AccBuf_ResetByteData_Loop3:
	ld	(xhl+iy), a
	add iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop3
	ld	xhl, 0x31cc
	xor	iy, iy
AccBuf_ResetByteData_Loop4:
	ld	(xhl+iy), a
	add iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop4
	ret

AccNote_FlushAll:
	ld a, (0x332c:16)
	and a, 0x3f
	jr z, AccNote_FlushReturn
	call RhythmPart_CopyData
	call RhythmPart1_ProcessAccentData
	ld a, 0x1:opc
	ld (0x32ec:16), a
	call RhythmPart2_ProcessAccentData
	call AccVoice_LoadRhythmParams_Part3
	call AccVoice_LoadRhythmParams_Part4
	call AccVoice_LoadRhythmParams_Part5
	and (0x332c:16), 192

AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	ld a, 0x5f:opc
	ld w, (1112:16)
	dec 1, w
	call AccVoice_LookupTableAddress
	ld bc, (0x327d:16)
	ld w, (0x32b5:16)
	dec 1, w
	call AccTempo_PositionCompare
	ld (0x32ec:16), a
	ld (0x32ea:16), a
	ret

AccInit_FullReInit:
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	calr AccBuf_WriteAllNotesOff
	call Rhythm_SendChanPressure
	calr AccBuf_ResetAll4
	ld a, (0x3312:16)
	or a, (0x3313:16)
	and a, 0x3f
	jr z, AccInit_ReInit_CheckNoteOn
	bit 0, (0x3301:16)
	jr z, AccInit_ReInit_CheckNoteOn
	or (0x330c:16), 1
	ld a, (0x3312:16)
	and a, 0x3f
	jr z, AccInit_ReInit_AdjustDecay
	cp (0x333a:16), 0
	jr z, AccInit_ReInit_CheckNoteOn
	dec 1, (0x333a:16)
	jr AccInit_ReInit_CheckNoteOn

AccInit_ReInit_AdjustDecay:
	cp (0x333a:16), 3
	jr z, AccInit_ReInit_CheckNoteOn
	inc 1, (0x333a:16)

AccInit_ReInit_CheckNoteOn:
	bit 0, (0x330c:16)
	jr z, AccInit_ReInit_CheckModes
	ld a, (0x3326:16)
	and a, 0x3f
	jr nz, AccInit_ReInit_CheckModes
	calr AccStyle_Init
	calr AccVoice_SetupAllParts
	ld a, (1075:16)
	ld (1112:16), a

AccInit_ReInit_CheckModes:
	ld a, (0x330a:16)
	and a, 0xd
	jr z, AccInit_ReInit_CheckSplit
	calr AccVoice_ResetAll

AccInit_ReInit_CheckSplit:
	ld a, (0x3309:16)
	and a, 0x3
	jr nz, AccInit_ReInit_ApplySplit
	bit 6, (0x3470:16)
	jr z, AccInit_ReInit_CheckPedalBit7
	or (0x3309:16), 1
	jr AccInit_ReInit_ApplySplit

AccInit_ReInit_CheckPedalBit7:
	bit 7, (0x3470:16)
	jr z, AccInit_ReInit_CheckThird
	or (0x3309:16), 2

AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	ld a, (0x330b:16)
	and a, 0x3
	jr z, AccInit_ReInit_ClearHighBits
	calr AccTiming_CallHelper
	call AccInit_ResetSongCounter
	calr AccVoice_ThirdLayer

AccInit_ReInit_ClearHighBits:
	and (0x32ab:16), 240
	and (0x32ac:16), 240
	and (0x32ad:16), 240
	and (0x32ae:16), 240
	and (0x32af:16), 240
	and (0x32b0:16), 240
	calr AccSeq_DualPartScan
	bit 6, (0x32f4:16)
	jr nz, AccInit_ReInit_SetDirty
	calr AccSeq_FourChannelScan

AccInit_ReInit_SetDirty:
	or (0x332c:16), 128
	ret

AccInit_ResetSongCounter:
	cp (0x32e2:16), 0
	jr nz, AccInit_ResetSong_Store
	call SeqVoice_SendNoteOffAndFlush

AccInit_ResetSong_Store:
	ld (0x32e2:16), 0
	ret

AccInit_CallF435A9:
	call SeqVoice_SendNoteOffAndFlush
	ret

AccTuning_CheckChange:
	cp (0x32e5:16), 128
	jr nc, AccTuning_ChangeReturn
	ld a, (0x3391:16)
	xor a, (0x3392:16)
	bit 0, a
	jr z, AccTuning_ChangeReturn
	or (0x3393:16), 1

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
	ld (0x3254:16), a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7f
	ld (0x3255:16), w
	and a, 0x80
	srl a, 7
	ld (0x3257:16), a
	ld a, (xhl + 6)
	ld (0x325b:16), a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7f
	ld (0x325c:16), w
	and a, 0x80
	srl a, 7
	ld (0x325e:16), a
	ld a, (xhl + 8)
	ld (0x3262:16), a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7f
	ld (0x3263:16), w
	and a, 0x80
	srl a, 7
	ld (0x3265:16), a
	ld a, (xhl + 2)
	ld (0x324d:16), a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7f
	ld (0x324e:16), w
	and a, 0x80
	srl a, 7
	ld (0x3250:16), a
	ld a, (xhl + 0:8)
	ld (0x3246:16), a
	ld a, (xhl + 1)
	and a, 0x7f
	ld (0x3247:16), a

AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadMasterReturn
	ld a, (xhl + 0:8)
	ld (0x3246:16), a
	ld a, (xhl + 1)
	and a, 0x7f
	ld (0x3247:16), a

AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadCoarseReturn
	ld a, (xhl + 2)
	ld (0x324d:16), a
	ld a, (xhl + 3)
	ld w, a
	and w, 0x7f
	ld (0x324e:16), w
	and a, 0x80
	srl a, 7
	ld (0x3250:16), a

AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadFineReturn
	ld a, (xhl + 4)
	ld (0x3254:16), a
	ld a, (xhl + 5)
	ld w, a
	and w, 0x7f
	ld (0x3255:16), w
	and a, 0x80
	srl a, 7
	ld (0x3257:16), a

AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadOctaveReturn
	ld a, (xhl + 6)
	ld (0x325b:16), a
	ld a, (xhl + 7)
	ld w, a
	and w, 0x7f
	ld (0x325c:16), w
	and a, 0x80
	srl a, 7
	ld (0x325e:16), a

AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_LoadTransposeReturn
	ld a, (xhl + 8)
	ld (0x3262:16), a
	ld a, (xhl + 9)
	ld w, a
	and w, 0x7f
	ld (0x3263:16), w
	and a, 0x80
	srl a, 7
	ld (0x3265:16), a

AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	bit 0, (0x3393:16)
	jrl z, AccTuning_ApplyReturn
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bit 0, (0x3391:16)
	jr z, AccTuning_ApplyChange_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_ApplyChange_SelectMode

AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_ApplyChange_SelectMode:
	ld a, (0x3316:16)
	or a, (0x3317:16)
	and a, 0x3f
	jrl nz, AccTuning_Mode_078
	ld a, (0x3318:16)
	and a, 0x3f
	jr nz, AccTuning_Mode_080
	ld a, (0x3314:16)
	and a, 0x3f
	jr nz, AccTuning_Mode_076
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, AccTuning_Mode_077
	ld a, (0x3312:16)
	or a, (0x3313:16)
	and a, 0x3f
	jr nz, AccTuning_Mode_074
	ld a, (0x335d:16)
	and a, 0x3f
	jr nz, AccTuning_Mode_149
	jr AccTuning_Mode_None

AccTuning_Mode_078:
	ld w, 0x3:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_080:
	ld w, 0x4:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_076:
	ld w, 0x5:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_077:
	ld w, 0x6:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_074:
	ld w, 0x2:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_149:
	ld w, 0x1:opc
	jr AccTuning_ApplyVoice

AccTuning_Mode_None:
	ld w, 0x0:opc

AccTuning_ApplyVoice:
	ld a, (0x32a3:16)
	ld xiy, (0x32ce:16)
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	or (0x332c:16), 63
	or (0x332c:16), 128

AccTuning_ApplyReturn:
	and (0x3393:16), 254
	ret

AccTuning_Toggle:
	cp (0x32e5:16), 128
	jr nc, AccTuning_Toggle_NoStyle
	ld a, (0x3391:16)
	xor a, (0x3392:16)
	bit 0, a
	jr z, AccTuning_Toggle_CheckDirty
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bit 0, (0x3391:16)
	jr z, AccTuning_Toggle_ClearBit
	ormi8 (xhl + 1), 0x80
	jr AccTuning_Toggle_SetFlag

AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_Toggle_SetFlag:
	or (0x333b:16), 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_CheckDirty:
	bit 0, (0x3393:16)
	jr z, AccTuning_Toggle_Return
	and (0x3393:16), 254
	or (0x333b:16), 1
	jr AccTuning_Toggle_Return

AccTuning_Toggle_NoStyle:
	and (0x3391:16), 254
	call AccTuning_LEDOff

AccTuning_Toggle_Return:
	ret

AccTuning_SaveState:
	ld a, (0x3391:16)
	ld (0x3392:16), a
	ret

AccTuning_Init:
	push xwa
	push xhl
	cp (0x32e5:16), 128
	jr nc, AccTuning_Init_NoTuning
	call AccHelper_ComputeVoiceOffset
	add xhl, 0x1e7810
	bitm 7, (xhl + 1)
	jr z, AccTuning_Init_NoTuning
	or (0x3391:16), 1
	call AccTuning_LEDOn
	ld a, (0x3391:16)
	ld (0x3392:16), a
	jr AccTuning_Init_Epilogue

AccTuning_Init_NoTuning:
	and (0x3391:16), 254
	call AccTuning_LEDOff
	ld a, (0x3391:16)
	ld (0x3392:16), a

AccTuning_Init_Epilogue:
	pop xhl
	pop xwa
	ret

AccTuning_DisableIfNoStyle:
	cp (0x32e5:16), 128
	jr c, AccTuning_DisableReturn
	and (0x3391:16), 254
	call AccTuning_LEDOff

AccTuning_DisableReturn:
	ret

AccTuning_LEDOn:
	ld (0x3390:16), 1
	ld a, 0x4a:opc
	call CtrlPanel_SetIndicatorBit
	ret

AccTuning_LEDOff:
	ld (0x3390:16), 0
	ld a, 0x4a:opc
	call CtrlPanel_SetIndicatorBit
	ret

AccWrap_JumpTable:
	jp	AccWrap_JumpTable_Return2
	jp	AccWrap_JumpTable_Return
	jp	AccWrap_JumpTable_Return
	jp	AccWrap_JumpTable_Return
	jp	AccWrap_JumpTable_Return
AccWrap_JumpTable_Return:
	ret
AccWrap_JumpTable_Return2:
	ret
AccWrap_ReplayStop:
	jp	AccPedal_EventDispatch
AccWrap_ReplayStopAlt:
	jp	AccPedal_RawHandler_Join

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
	call	AccPos_ClearOnStart_Padding_Sub
	pop	xiz
	ret

AccWrap_FlagSync:
	jp AccFlags_SyncTo64607
AccWrap_PlayModeStopData2:
	jp	AccTempo_WriteMarker_Padding_Return

AccWrap_AutoPlayZoneTrack:
	push xiz
	call AccAutoPlay_ZoneTrack
	pop xiz
	ret

AccWrap_AutoPlayByteData:
	jp	AccAutoPlay_PeriodicCheck
	push	xiz
	calr	AccPlayMode_StopToSync2
	pop	xiz
	ret
	push	xiz
	calr	AccPlayMode_StopExprC
	pop	xiz
	ret

AccPedal_EventDispatch:
	ld a, (SWBTWR_PAYLOAD_1:16)
	ld (0x348a:16), a
	cp a, 5:i3
	jr z, AccPedal_TypeSustainOrExpr
	cp a, 6:i3
	jr z, AccPedal_TypeSustainOrExpr
	jr AccPedal_CheckType0

AccPedal_TypeSustainOrExpr:
	ld a, (SWBTWR_PAYLOAD_2:16)
	ld (0x347e:16), a
	ld a, (SWBTWR_PAYLOAD_3:16)
	cp a, 0xff
	jr nz, AccPedal_ParseValue
	xor a, a

AccPedal_ParseValue:
	ld (0x347f:16), a
	calr AccPedal_SustainHandler
	calr AccPedal_ExprToggle
	calr AccPedal_DistributeParams

AccPedal_CheckType0:
	ld a, (SWBTWR_PAYLOAD_1:16)
	cp a, 0:i3
	jr z, AccPedal_SavePosition
	cp a, 7:i3
	jr nz, AccPedal_EventReturn
	ld a, (SWBTWR_PAYLOAD_3:16)
	and a, 0x30
	cp a, 0:i3
	jr z, AccPedal_EventReturn

AccPedal_SavePosition:
	calr AccPos_SaveOnStop

AccPedal_EventReturn:
	ret

AccPedal_RawHandler:
	nop
	nop
AccPedal_RawHandler_Join:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 3:i3
	jr	nz, AccPedal_EventDispatch_Return
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, 7
	ld	(0x347e:16), a
	ld	a, (SWBTWR_PAYLOAD_3:16)
	ld	(0x347f:16), a
	ld	a, (SWBTWR_PAYLOAD_1:16)
	ld	(0x348a:16), a
AccPedal_EventDispatch_Return:
	ret
	nop
	nop

AccPedal_SustainHandler:
	cp (0x348a:16), 5
	jrl nz, AccPedal_SustainReturn
	ld a, (0x347e:16)
	and a, (0x347f:16)
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
	cp (0x7f0b:16), 0
	jr z, AccPedal_Sustain_CheckStyle
	call AccPlay_ToggleEntry
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckStyle:
	cp (CURRENT_TITLE:16), 111
	jr z, AccPedal_Sustain_SpecialStyle
	cp (CURRENT_TITLE:16), 112
	jr z, AccPedal_Sustain_SpecialStyle
	cp (CURRENT_TITLE:16), 113
	jr z, AccPedal_Sustain_SpecialStyle
	cp (CURRENT_TITLE:16), 114
	jr nz, AccPedal_Sustain_CheckPlay

AccPedal_Sustain_SpecialStyle:
	or (3381:16), 1
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckPlay:
	bit 2, (0x28a7:16)
	jr z, AccPedal_Sustain_CheckMultiStyle
	calr AccPlayMode_Dispatch
	bit 3, (3411:16)
	jr z, AccPedal_Sustain_PlayJump
	cp (3429:16), 0
	jr z, AccPedal_Sustain_PlayJump
	call AccPedal_ScanVoiceSlots
	ld a, 0x86:opc
	bit 1, (3411:16)
	jr nz, AccPedal_Sustain_WriteTempo
	ld a, 0x85:opc

AccPedal_Sustain_WriteTempo:
	calr AccTempo_WriteStopMarker

AccPedal_Sustain_PlayJump:
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckMultiStyle:
	cp (CURRENT_TITLE:16), 120
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 122
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 115
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 116
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 117
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 118
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 119
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 121
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 108
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 109
	jr z, AccPedal_Sustain_MultiMatch
	cp (CURRENT_TITLE:16), 110
	jr nz, AccPedal_Sustain_Normal

AccPedal_Sustain_MultiMatch:
	or (3381:16), 1
	jr AccPedal_SustainReturn

AccPedal_Sustain_Normal:
	bit 2, (0x28b2:16)
	jr nz, AccPedal_SustainReturn
	pushw wa
	calr AccPedal_StyleCheck
	cp a, 1:i3
	popw wa
	jr z, AccPedal_SustainReturn
	ei 6
	ld a, (1056:16)
	bit 2, a
	jr nz, AccPedal_Sustain_CallPlayMode
	bit 0, a
	jr z, AccPedal_Sustain_CallPlayMode
	xor a, a
	ld (1056:16), a
	ld (1054:16), a
	ld (SEQ_TRANSPORT_STATE:16), a
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
	cp (CURRENT_TITLE:16), 111
	jr z, AccPedal_StyleCheck_Ineligible
	cp (CURRENT_TITLE:16), 108
	jr c, AccPedal_StyleCheck_Extended
	cp (CURRENT_TITLE:16), 122
	jr ugt, AccPedal_StyleCheck_Extended
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Extended:
	cp (CURRENT_MODE:16), 19
	jr z, AccPedal_StyleCheck_Ineligible
	cp (CURRENT_TITLE:16), 120
	jr z, AccPedal_StyleCheck_Match120
	jr AccPedal_StyleCheck_Eligible

AccPedal_StyleCheck_Match120:
	jr AccPedal_StyleCheck_Ineligible

AccPedal_StyleCheck_Eligible:
	ld a, 0x0:opc
	jr AccPedal_StyleCheckReturn

AccPedal_StyleCheck_Ineligible:
	ld a, 0x1:opc

AccPedal_StyleCheckReturn:
	ret

AccPedal_ExprToggle:
	cp (0x348a:16), 5
	jr nz, AccPedal_ExprReturn
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 1, a
	jr z, AccPedal_ExprReturn
	ld a, 0x2:opc
	xor (0xfc5f:16), a
	cp (0x90f8:16), 255
	jr z, AccPedal_ExprReturn
	bit 3, (0xfd56:16)
	jr z, AccPedal_ExprReturn
	ld e, (0xfc5f:16)
	and e, 0x2
	ld xix, 0x38e8
	ld (xix + 0:8), 0x48
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
	cp (CURRENT_MODE:16), 14
	jr z, AccPedal_Distribute_JumpMain
	bit 0, (0x28a6:16)
	jr z, AccPedal_Distribute_ClearAll

AccPedal_Distribute_JumpMain:
	jp AccPedal_DistributeReturn

AccPedal_Distribute_ClearAll:
	xor wa, wa
	ld (0x3480:16), a
	ld (0x3481:16), a
	ld (0x3482:16), a
	ld (0x3483:16), a
	ld (0x3484:16), a
	ld (0x3485:16), a
	ld (0x3486:16), a
	ld (0x3487:16), a
	calr AccPedal_ProcessAllBits
	bit 3, (3411:16)
	jr z, AccPedal_Distribute_CheckRecord
	and (0xfc5f:16), 15
	ld (0x3481:16), 0
	ld (0x3483:16), 0
	ld (0x3485:16), 0
	ld (0x3487:16), 0

AccPedal_Distribute_CheckRecord:
	calr AccPedal_StateSync
	bit 3, (3411:16)
	jr z, AccPedal_DistributeReturn
	cp (3429:16), 0
	jr z, AccPedal_DistributeReturn
	xor wa, wa
	ld (0x3480:16), a
	ld (0x3481:16), a
	ld (0x3484:16), a
	ld (0x3485:16), a
	calr AccPedal_MapToAcc
	calr AccPedal_SendEvents

AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	nop
	nop

AccPedal_SendEvents:
	ld a, (0x3480:16)
	xor a, 0xff
	and a, (0x3481:16)
	cp a, 0:i3
	jr z, AccPedal_SendEvents_Group2
	ld b, 0x5:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3480:16)
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_Group2:
	ld a, (0x3484:16)
	xor a, 0xff
	and a, (0x3485:16)
	cp a, 0:i3
	jr z, AccPedal_SendEvents_OnSustain
	ld b, 0x6:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3484:16)
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnSustain:
	ld a, (0x3480:16)
	and a, (0x3481:16)
	cp a, 0:i3
	jr z, AccPedal_SendEvents_OnExpr
	ld b, 0x5:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3480:16)
	call MIDI_TransmitTempoCC

AccPedal_SendEvents_OnExpr:
	ld a, (0x3484:16)
	and a, (0x3485:16)
	cp a, 0:i3
	jr z, AccPedal_SendEventsReturn
	ld b, 0x6:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3484:16)
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
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit2_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 2, a
	jr z, AccPedal_Bit2_Off
	orw (4360:16), 4
	cp (0x90f8:16), 127
	jr z, AccPedal_Bit2_CheckPlay
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_CheckPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Bit2_Sostenuto
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_Sostenuto:
	calr AccPedal_SostenutoOn

AccPedal_Bit2_Off:
	bit 2, (0x347f:16)
	jr z, AccPedal_Bit2_Return
	bit 2, (0x347e:16)
	jr nz, AccPedal_Bit2_Return
	cp (0x90f8:16), 127
	jr z, AccPedal_Bit2_OffPlay
	calr AccPedal_SustainOff
	jr AccPedal_Bit2_Return

AccPedal_Bit2_OffPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Bit2_OffSostenuto
	calr AccPedal_SustainOff
	jr AccPedal_Bit2_Return

AccPedal_Bit2_OffSostenuto:
	calr AccPedal_SostenutoOff

AccPedal_Bit2_Return:
	ret

AccPedal_Bit2_Expression:
	cp (0x348a:16), 6
	jr nz, AccPedal_Expr_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 2, a
	jr z, AccPedal_Expr_Off
	ld de, 4:i3
	sla de, 8
	or (4360:16), de
	cp (0x90f8:16), 127
	jr z, AccPedal_Expr_CheckPlay
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_CheckPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Expr_Soft
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_Soft:
	calr AccPedal_SoftOn

AccPedal_Expr_Off:
	bit 2, (0x347f:16)
	jr z, AccPedal_Expr_Return
	bit 2, (0x347e:16)
	jr nz, AccPedal_Expr_Return
	cp (0x90f8:16), 127
	jr z, AccPedal_Expr_OffPlay
	calr AccPedal_ExprOff
	jr AccPedal_Expr_Return

AccPedal_Expr_OffPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Expr_OffSoft
	calr AccPedal_ExprOff
	jr AccPedal_Expr_Return

AccPedal_Expr_OffSoft:
	calr AccPedal_SoftOff

AccPedal_Expr_Return:
	ret

AccPedal_Bit7_Portamento:
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit7_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 7, a
	jr z, AccPedal_Bit7_Off
	orw (4360:16), 128
	bit 2, (1054:16)
	jr z, AccPedal_Bit7_Damper
	calr AccPedal_PortamentoOn
	jr AccPedal_Bit7_Off

AccPedal_Bit7_Damper:
	calr AccPedal_DamperOn

AccPedal_Bit7_Off:
	bit 7, (0x347f:16)
	jr z, AccPedal_Bit7_Return
	bit 7, (0x347e:16)
	jr nz, AccPedal_Bit7_Return
	bit 2, (1054:16)
	jr z, AccPedal_Bit7_OffDamper
	calr AccPedal_PortamentoOff
	jr AccPedal_Bit7_Return

AccPedal_Bit7_OffDamper:
	calr AccPedal_DamperOff

AccPedal_Bit7_Return:
	ret

AccPedal_Bit6_Hold:
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit6_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 6, a
	jr z, AccPedal_Bit6_HoldOff
	orw (4360:16), 64
	bit 2, (1054:16)
	jr z, AccPedal_Bit6_HoldOff
	calr AccPedal_HoldOn
	jr AccPedal_Bit6_HoldOff

AccPedal_Bit6_HoldOff:
	bit 6, (0x347f:16)
	jr z, AccPedal_Bit6_Return
	bit 6, (0x347e:16)
	jr nz, AccPedal_Bit6_Return
	bit 2, (1054:16)
	jr z, AccPedal_Bit6_Return
	calr AccPedal_HoldOff
	jr AccPedal_Bit6_Return

AccPedal_Bit6_Return:
	ret

AccPedal_Bit4_Sostenuto:
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit4_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 4, a
	jr z, AccPedal_Bit4_Off
	bit 2, (1054:16)
	jr z, AccPedal_Bit4_Off
	calr AccPedal_SostenutoOn

AccPedal_Bit4_Off:
	bit 4, (0x347f:16)
	jr z, AccPedal_Bit4_Return
	bit 4, (0x347e:16)
	jr nz, AccPedal_Bit4_Return
	bit 2, (1054:16)
	jr z, AccPedal_Bit4_Return
	calr AccPedal_SostenutoOff

AccPedal_Bit4_Return:
	ret

AccPedal_Bit5_Soft:
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit5_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 5, a
	jr z, AccPedal_Bit5_Off
	bit 2, (1054:16)
	jr z, AccPedal_Bit5_Off
	calr AccPedal_SoftOn

AccPedal_Bit5_Off:
	bit 5, (0x347f:16)
	jr z, AccPedal_Bit5_Return
	bit 5, (0x347e:16)
	jr nz, AccPedal_Bit5_Return
	bit 2, (1054:16)
	jr z, AccPedal_Bit5_Return
	calr AccPedal_SoftOff

AccPedal_Bit5_Return:
	ret

AccPedal_Bit3_Damper:
	cp (0x348a:16), 5
	jr nz, AccPedal_Bit3_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 3, a
	jr z, AccPedal_Bit3_Off
	calr AccPedal_DamperOn

AccPedal_Bit3_Off:
	bit 3, (0x347f:16)
	jr z, AccPedal_Bit3_Return
	bit 3, (0x347e:16)
	jr nz, AccPedal_Bit3_Return
	calr AccPedal_DamperOff

AccPedal_Bit3_Return:
	ret

AccPedal_StateSync:
	cp (0x90f8:16), 127
	jr z, AccPedal_Sync_SendEvents
	cp (0x90f8:16), 255
	jr nz, AccPedal_Sync_DispatchAll

AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	cp (0x90f8:16), 255
	jr z, AccPedal_Sync_Return
	call AccPedal_SendCtrl1
	call AccPedal_SendCtrl2
	call AccPedal_SendCtrl3
	call AccPedal_SendCtrl4

AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	ld a, (0x3482:16)
	xor a, 0xff
	and a, (0x3483:16)
	cp a, 0:i3
	jr z, AccPedal_SendCtrl1_Return
	bit 3, (0xfd56:16)
	jr z, AccPedal_SendCtrl1_CheckPort
	ld b, 0x5:opc
	ld d, a
	ld e, (0x3482:16)
	ld xix, 0x38e8
	ld (xix + 0:8), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl1_CheckPort:
	bit 4, (0xfd50:16)
	jr nz, AccPedal_SendCtrl1_Return
	ld a, (0x90e4:16)
	and a, 0x8f
	ld (0x90e5:16), a
	cp (0x90f8:16), 127
	jr nz, AccPedal_SendCtrl1_UpdateMask
	and (0x90e5:16), 127

AccPedal_SendCtrl1_UpdateMask:
	ld a, (0x3482:16)
	xor a, 0xff
	and a, (0x3483:16)
	ld b, 0x5:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3482:16)
	call MIDI_DispatchCC

AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	ld a, (0x3486:16)
	xor a, 0xff
	and a, (0x3487:16)
	cp a, 0:i3
	jr z, AccPedal_SendCtrl2_Return
	bit 3, (0xfd56:16)
	jr z, AccPedal_SendCtrl2_CheckPort
	ld b, 0x6:opc
	ld d, a
	ld e, (0x3486:16)
	ld xix, 0x38e8
	ld (xix + 0:8), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl2_CheckPort:
	bit 4, (0xfd50:16)
	jr nz, AccPedal_SendCtrl2_Return
	ld a, (0x90e4:16)
	and a, 0x8f
	ld (0x90e5:16), a
	cp (0x90f8:16), 127
	jr nz, AccPedal_SendCtrl2_UpdateMask
	and (0x90e5:16), 127

AccPedal_SendCtrl2_UpdateMask:
	ld a, (0x3486:16)
	xor a, 0xff
	and a, (0x3487:16)
	ld b, 0x6:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3486:16)
	call MIDI_DispatchCC

AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	ld a, (0x3482:16)
	and a, (0x3483:16)
	cp a, 0:i3
	jr z, AccPedal_SendCtrl3_Return
	bit 3, (0xfd56:16)
	jr z, AccPedal_SendCtrl3_CheckPort
	ld b, 0x5:opc
	ld d, a
	ld e, (0x3482:16)
	ld xix, 0x38e8
	ld (xix + 0:8), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl3_CheckPort:
	bit 4, (0xfd50:16)
	jr nz, AccPedal_SendCtrl3_Return
	ld a, (0x90e4:16)
	and a, 0x8f
	ld (0x90e5:16), a
	cp (0x90f8:16), 127
	jr nz, AccPedal_SendCtrl3_UpdateMask
	and (0x90e5:16), 127

AccPedal_SendCtrl3_UpdateMask:
	ld a, (0x3482:16)
	and a, (0x3483:16)
	ld b, 0x5:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3482:16)
	call MIDI_DispatchCC

AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	ld a, (0x3486:16)
	and a, (0x3487:16)
	cp a, 0:i3
	jr z, AccPedal_SendCtrl4_Return
	bit 3, (0xfd56:16)
	jr z, AccPedal_SendCtrl4_CheckPort
	ld b, 0x6:opc
	ld d, a
	ld e, (0x3486:16)
	ld xix, 0x38e8
	ld (xix + 0:8), 0x48
	ld (xix + 1), b
	ld (xix + 2), e
	ld (xix + 3), d
	push xix
	call MidiPkt_DispatchViaTable_4DCE
	inc 4, xsp

AccPedal_SendCtrl4_CheckPort:
	bit 4, (0xfd50:16)
	jr nz, AccPedal_SendCtrl4_Return
	ld a, (0x90e4:16)
	and a, 0x8f
	ld (0x90e5:16), a
	cp (0x90f8:16), 127
	jr nz, AccPedal_SendCtrl4_UpdateMask
	and (0x90e5:16), 127

AccPedal_SendCtrl4_UpdateMask:
	ld a, (0x3486:16)
	and a, (0x3487:16)
	ld b, 0x6:opc
	ld c, 0x48:opc
	ld d, a
	ld e, (0x3486:16)
	call MIDI_DispatchCC

AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	cp (0x348a:16), 5
	jr nz, AccPedal_MapToAcc_Send
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 6, a
	jr z, AccPedal_MapToAcc_Send
	call AccPedal_ScanVoiceSlots
	bit 1, (3411:16)
	jr z, AccPedal_MapToAcc_Send
	or (0x3481:16), 64
	or (0x3480:16), 64

AccPedal_MapToAcc_Send:
	cp (0x348a:16), 5
	jr nz, AccPedal_MapToAcc_UpdateMask
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 7, a
	jr z, AccPedal_MapToAcc_UpdateMask
	call AccPedal_ScanVoiceSlots
	bit 1, (3411:16)
	jr z, AccPedal_MapToAcc_CheckDir
	or (0x3481:16), 128
	or (0x3480:16), 128
	jr AccPedal_MapToAcc_UpdateMask

AccPedal_MapToAcc_CheckDir:
	or (0x3481:16), 8
	or (0x3480:16), 8

AccPedal_MapToAcc_UpdateMask:
	cp (0x348a:16), 5
	jr nz, AccPedal_MapToAcc_SetMask
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 2, a
	jr z, AccPedal_MapToAcc_SetMask
	call AccPedal_ScanVoiceSlots
	bit 1, (3411:16)
	jr z, AccPedal_MapToAcc_ClearMask
	or (0x3481:16), 16
	or (0x3480:16), 16
	jr AccPedal_MapToAcc_SetMask

AccPedal_MapToAcc_ClearMask:
	or (0x3481:16), 4
	or (0x3480:16), 4

AccPedal_MapToAcc_SetMask:
	cp (0x348a:16), 6
	jr nz, AccPedal_MapToAcc_Return
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 2, a
	jr z, AccPedal_MapToAcc_Return
	call AccPedal_ScanVoiceSlots
	bit 1, (3411:16)
	jr z, AccPedal_MapToAcc_Apply
	or (0x3481:16), 32
	or (0x3480:16), 32
	jr AccPedal_MapToAcc_Return

AccPedal_MapToAcc_Apply:
	or (0x3485:16), 4
	or (0x3484:16), 4

AccPedal_MapToAcc_Return:
	cp (0x348a:16), 5
	jr nz, AccPedal_MapPadding
	ld a, (0x347e:16)
	and a, (0x347f:16)
	bit 5, a
	jr z, AccPedal_MapPadding
	call AccPedal_ScanVoiceSlots
	bit 1, (3411:16)
	jr z, AccPedal_MapPadding
	or (0x3481:16), 32
	or (0x3480:16), 32
	jr AccPedal_MapPadding

AccPedal_MapPadding:
	ret

AccPedal_MapPadding2:
	nop
	nop

AccPedal_SustainOn:
	bit 2, (0x3470:16)
	jrl nz, AccPedal_SustainOn_AltRoute
	or (0x3470:16), 4
	bit 2, (0xfc5f:16)
	jr nz, AccPedal_SustainOn_SetMask
	or (0xfc5f:16), 4
	or (0x3482:16), 4
	or (0x3480:16), 4
	jr AccPedal_SustainOn_Update64607

AccPedal_SustainOn_SetMask:
	cp (0x90f8:16), 127
	jr nz, AccPedal_SustainOn_Update64607
	and (0xfc5f:16), 251
	and (0x3482:16), 251
	and (0x3480:16), 251

AccPedal_SustainOn_Update64607:
	or (0x3481:16), 4
	or (0x3483:16), 4
	bit 3, (0xfc5f:16)
	jr z, AccPedal_SustainOn_Post
	and (0xfc5f:16), 247
	and (0x3480:16), 247
	or (0x3481:16), 8
	and (0x3482:16), 247
	or (0x3483:16), 8

AccPedal_SustainOn_Post:
	bit 2, (0xfc60:16)
	jr z, AccPedal_SustainOn_Finalize
	and (0xfc60:16), 251
	and (0x3484:16), 251
	or (0x3485:16), 4
	and (0x3486:16), 251
	or (0x3487:16), 4

AccPedal_SustainOn_Finalize:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SustainOn_CheckAlt
	and (0xfc5f:16), 191

AccPedal_SustainOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SustainOn_AltRoute
	and (0xfc5f:16), 127

AccPedal_SustainOn_AltRoute:
	cp (0x90f8:16), 127
	jr z, AccPedal_SustainOn_Return
	and (0x3470:16), 251

AccPedal_SustainOn_Return:
	ret

AccPedal_SustainOff_Padding:
	nop
	nop

AccPedal_SustainOff:
	bit 2, (0x3470:16)
	jr z, AccPedal_SustainOff_Clear
	and (0x3470:16), 251

AccPedal_SustainOff_Clear:
	cp (0x90f8:16), 127
	jr z, AccPedal_SustainOff_Return
	and (0xfc5f:16), 251

AccPedal_SustainOff_Return:
	ret

AccPedal_ExprOn_Padding:
	nop
	nop

AccPedal_ExprOn:
	bit 0, (0x3470:16)
	jrl nz, AccPedal_ExprOn_AltRoute
	or (0x3470:16), 1
	bit 2, (0xfc60:16)
	jr nz, AccPedal_ExprOn_SetMask
	or (0xfc60:16), 4
	or (0x3486:16), 4
	or (0x3484:16), 4
	jr AccPedal_ExprOn_Update64607

AccPedal_ExprOn_SetMask:
	cp (0x90f8:16), 127
	jr nz, AccPedal_ExprOn_Update64607
	and (0xfc60:16), 251
	and (0x3486:16), 251
	and (0x3484:16), 251

AccPedal_ExprOn_Update64607:
	or (0x3485:16), 4
	or (0x3487:16), 4
	bit 3, (0xfc5f:16)
	jr z, AccPedal_ExprOn_Post
	and (0xfc5f:16), 247
	and (0x3480:16), 247
	or (0x3481:16), 8
	and (0x3482:16), 247
	or (0x3483:16), 8

AccPedal_ExprOn_Post:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_ExprOn_Finalize
	and (0xfc5f:16), 251
	and (0x3480:16), 251
	or (0x3481:16), 4
	and (0x3482:16), 251
	or (0x3483:16), 4

AccPedal_ExprOn_Finalize:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_ExprOn_CheckAlt
	and (0xfc5f:16), 191

AccPedal_ExprOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_ExprOn_AltRoute
	and (0xfc5f:16), 127

AccPedal_ExprOn_AltRoute:
	cp (0x90f8:16), 127
	jr z, AccPedal_ExprOn_Return
	and (0x3470:16), 254

AccPedal_ExprOn_Return:
	ret

AccPedal_ExprOff_Padding:
	nop
	nop

AccPedal_ExprOff:
	bit 0, (0x3470:16)
	jr z, AccPedal_ExprOff_Clear
	and (0x3470:16), 254

AccPedal_ExprOff_Clear:
	cp (0x90f8:16), 127
	jr z, AccPedal_ExprOff_Return
	and (0xfc60:16), 251

AccPedal_ExprOff_Return:
	ret

AccPedal_SostenutoOn_Padding:
	nop
	nop

AccPedal_SostenutoOn:
	bit 4, (0x3470:16)
	jrl nz, AccPedal_SostenutoOn_Return
	or (0x3470:16), 16
	or (0xfc5f:16), 16
	or (0x3481:16), 16
	or (0x3480:16), 16
	or (0x3483:16), 16
	or (0x3482:16), 16
	bit 5, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_SetMask
	and (0xfc5f:16), 223

AccPedal_SostenutoOn_SetMask:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_Update
	and (0xfc5f:16), 191

AccPedal_SostenutoOn_Update:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_Post
	and (0xfc5f:16), 127

AccPedal_SostenutoOn_Post:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_Finalize
	and (0xfc5f:16), 251
	or (0x3483:16), 4
	and (0x3482:16), 251
	or (0x3481:16), 4
	and (0x3480:16), 251

AccPedal_SostenutoOn_Finalize:
	bit 3, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_CheckAlt
	and (0xfc5f:16), 247
	or (0x3483:16), 8
	and (0x3482:16), 247
	or (0x3481:16), 8
	and (0x3480:16), 247

AccPedal_SostenutoOn_CheckAlt:
	bit 2, (0xfc60:16)
	jr z, AccPedal_SostenutoOn_Return
	and (0xfc60:16), 251
	or (0x3487:16), 4
	and (0x3486:16), 251
	or (0x3485:16), 4
	and (0x3484:16), 251

AccPedal_SostenutoOn_Return:
	ret

AccPedal_SostenutoOff_Padding:
	nop
	nop

AccPedal_SostenutoOff:
	bit 4, (0x3470:16)
	jr z, AccPedal_SostenutoOff_Return
	and (0x3470:16), 239
	or (0x3481:16), 16
	and (0x3480:16), 239
	or (0x3483:16), 16
	and (0x3482:16), 239

AccPedal_SostenutoOff_Return:
	ret

AccPedal_SostenutoOff_Padding2:
	nop
	nop

AccPedal_SoftOn:
	bit 5, (0x3470:16)
	jrl nz, AccPedal_SoftOn_Return
	or (0x3470:16), 32
	or (0xfc5f:16), 32
	or (0x3481:16), 32
	or (0x3480:16), 32
	or (0x3483:16), 32
	or (0x3482:16), 32
	bit 4, (0xfc5f:16)
	jr z, AccPedal_SoftOn_SetMask
	and (0xfc5f:16), 239

AccPedal_SoftOn_SetMask:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SoftOn_Update
	and (0xfc5f:16), 191

AccPedal_SoftOn_Update:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SoftOn_Post
	and (0xfc5f:16), 127

AccPedal_SoftOn_Post:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_SoftOn_Finalize
	and (0xfc5f:16), 251
	or (0x3483:16), 4
	and (0x3482:16), 251
	or (0x3481:16), 4
	and (0x3480:16), 251

AccPedal_SoftOn_Finalize:
	bit 3, (0xfc5f:16)
	jr z, AccPedal_SoftOn_CheckAlt
	and (0xfc5f:16), 247
	or (0x3483:16), 8
	and (0x3482:16), 247
	or (0x3481:16), 8
	and (0x3480:16), 247

AccPedal_SoftOn_CheckAlt:
	bit 2, (0xfc60:16)
	jr z, AccPedal_SoftOn_Return
	and (0xfc60:16), 251
	or (0x3487:16), 4
	and (0x3486:16), 251
	or (0x3485:16), 4
	and (0x3484:16), 251

AccPedal_SoftOn_Return:
	ret

AccPedal_SoftOff_Padding:
	nop
	nop

AccPedal_SoftOff:
	bit 5, (0x3470:16)
	jr z, AccPedal_SoftOff_Return
	and (0x3470:16), 223
	or (0x3481:16), 32
	and (0x3480:16), 223
	or (0x3483:16), 32
	and (0x3482:16), 223

AccPedal_SoftOff_Return:
	ret

AccPedal_HoldOn_Padding:
	nop
	nop

AccPedal_HoldOn:
	bit 6, (0x3470:16)
	jrl nz, AccPedal_HoldOn_Return
	or (0x3470:16), 64
	or (0xfc5f:16), 64
	or (0x3481:16), 64
	or (0x3480:16), 64
	or (0x3483:16), 64
	or (0x3482:16), 64
	bit 4, (0xfc5f:16)
	jr z, AccPedal_HoldOn_SetMask
	and (0xfc5f:16), 239

AccPedal_HoldOn_SetMask:
	bit 5, (0xfc5f:16)
	jr z, AccPedal_HoldOn_Update
	and (0xfc5f:16), 223

AccPedal_HoldOn_Update:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_HoldOn_Post
	and (0xfc5f:16), 251
	or (0x3483:16), 4
	and (0x3482:16), 251
	or (0x3481:16), 4
	and (0x3480:16), 251

AccPedal_HoldOn_Post:
	bit 3, (0xfc5f:16)
	jr z, AccPedal_HoldOn_Finalize
	and (0xfc5f:16), 247
	or (0x3483:16), 8
	and (0x3482:16), 247
	or (0x3481:16), 8
	and (0x3480:16), 247

AccPedal_HoldOn_Finalize:
	bit 2, (0xfc60:16)
	jr z, AccPedal_HoldOn_CheckAlt
	and (0xfc60:16), 251
	or (0x3487:16), 4
	and (0x3486:16), 251
	or (0x3485:16), 4
	and (0x3484:16), 251

AccPedal_HoldOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_HoldOn_Return
	and (0xfc5f:16), 127

AccPedal_HoldOn_Return:
	ret

AccPedal_HoldOff_Padding:
	nop
	nop

AccPedal_HoldOff:
	bit 6, (0x3470:16)
	jr z, AccPedal_HoldOff_Return
	and (0x3470:16), 191
	or (0x3481:16), 64
	and (0x3480:16), 191
	or (0x3483:16), 64
	and (0x3482:16), 191

AccPedal_HoldOff_Return:
	ret

AccPedal_HoldOff_Padding2:
	nop
	nop

AccPedal_DamperOn:
	bit 3, (0x3470:16)
	jrl nz, AccPedal_DamperOn_FinalCheck
	or (0x3470:16), 8
	bit 3, (0xfc5f:16)
	jr nz, AccPedal_DamperOn_SetMask
	or (0xfc5f:16), 8
	or (0x3482:16), 8
	or (0x3480:16), 8
	jr AccPedal_DamperOn_Update

AccPedal_DamperOn_SetMask:
	cp (0x90f8:16), 127
	jr nz, AccPedal_DamperOn_Update
	and (0xfc5f:16), 247
	and (0x3482:16), 247
	and (0x3480:16), 247

AccPedal_DamperOn_Update:
	or (0x3481:16), 8
	or (0x3483:16), 8
	bit 2, (0xfc5f:16)
	jr z, AccPedal_DamperOn_Post
	and (0xfc5f:16), 251
	and (0x3480:16), 251
	or (0x3481:16), 4
	and (0x3482:16), 251
	or (0x3483:16), 4

AccPedal_DamperOn_Post:
	bit 2, (0xfc60:16)
	jr z, AccPedal_DamperOn_Finalize
	and (0xfc60:16), 251
	and (0x3484:16), 251
	or (0x3485:16), 4
	and (0x3486:16), 251
	or (0x3487:16), 4

AccPedal_DamperOn_Finalize:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_DamperOn_CheckAlt
	and (0xfc5f:16), 191

AccPedal_DamperOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_DamperOn_AltRoute
	and (0xfc5f:16), 127

AccPedal_DamperOn_AltRoute:
	bit 4, (0xfc5f:16)
	jr z, AccPedal_DamperOn_Apply
	and (0xfc5f:16), 239

AccPedal_DamperOn_Apply:
	bit 5, (0xfc5f:16)
	jr z, AccPedal_DamperOn_FinalCheck
	and (0xfc5f:16), 223

AccPedal_DamperOn_FinalCheck:
	cp (0x90f8:16), 127
	jr z, AccPedal_DamperOn_Return
	and (0x3470:16), 247

AccPedal_DamperOn_Return:
	ret

AccPedal_DamperOff_Padding:
	nop
	nop

AccPedal_DamperOff:
	bit 3, (0x3470:16)
	jr z, AccPedal_DamperOff_Clear
	and (0x3470:16), 247

AccPedal_DamperOff_Clear:
	cp (0x90f8:16), 127
	jr z, AccPedal_DamperOff_Return
	and (0xfc5f:16), 247

AccPedal_DamperOff_Return:
	ret

AccPedal_DamperOff_Padding2:
	nop
	nop

AccPedal_PortamentoOn:
	bit 7, (0x3470:16)
	jrl nz, AccPedal_PortamentoOn_Return
	or (0x3470:16), 128
	or (0xfc5f:16), 128
	or (0x3481:16), 128
	or (0x3480:16), 128
	or (0x3483:16), 128
	or (0x3482:16), 128
	bit 4, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_SetMask
	and (0xfc5f:16), 239

AccPedal_PortamentoOn_SetMask:
	bit 5, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_Update
	and (0xfc5f:16), 223

AccPedal_PortamentoOn_Update:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_Post
	and (0xfc5f:16), 251
	or (0x3483:16), 4
	and (0x3482:16), 251
	or (0x3481:16), 4
	and (0x3480:16), 251

AccPedal_PortamentoOn_Post:
	bit 3, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_Finalize
	and (0xfc5f:16), 247
	or (0x3483:16), 8
	and (0x3482:16), 247
	or (0x3481:16), 8
	and (0x3480:16), 247

AccPedal_PortamentoOn_Finalize:
	bit 2, (0xfc60:16)
	jr z, AccPedal_PortamentoOn_CheckAlt
	and (0xfc60:16), 251
	or (0x3487:16), 4
	and (0x3486:16), 251
	or (0x3485:16), 4
	and (0x3484:16), 251

AccPedal_PortamentoOn_CheckAlt:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_Return
	and (0xfc5f:16), 191

AccPedal_PortamentoOn_Return:
	ret

AccPedal_PortamentoOff_Padding:
	nop
	nop

AccPedal_PortamentoOff:
	bit 7, (0x3470:16)
	jr z, AccPedal_PortamentoOff_Return
	and (0x3470:16), 127
	or (0x3481:16), 128
	and (0x3480:16), 127
	or (0x3483:16), 128
	and (0x3482:16), 127

AccPedal_PortamentoOff_Return:
	ret

AccPedal_PortamentoOff_Padding2:
	nop
	nop

AccAutoPlay_NoteDispatch:
	ld w, a
	ld a, c
	cp (0x7f0b:16), 0
	jr nz, AccAutoPlay_NoteDispatch_Process
	pushw wa
	calr AccPedal_StyleCheck
	cp a, 1:i3
	popw wa
	jr z, AccAutoPlay_NoteDispatch_Process
	bit 2, (0x28a7:16)
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
	cp c, 0:i3
	jr z, AccAutoPlay_NoteDispatch_Check
	or (0x3498:16), 1

AccAutoPlay_NoteDispatch_Check:
	or (0x3498:16), 128

AccAutoPlay_NoteDispatch_Process:
	cpw (0x28a8:16), 0
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 2, (1054:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 3, (0x28b3:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 0, (0x28b2:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 2, (0x28b1:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 0, (0x3498:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	and (0x28b3:16), 247
	call Audio_CheckSubsystemReady

AccAutoPlay_NoteDispatch_Return:
	ret

AccAutoPlay_SplitDetect:
	ld c, 0x0:opc
	cpw (0x28a8:16), 0
	jr z, AccAutoPlay_SplitDetect_Check
	bit 3, (0x28b3:16)
	jr z, AccAutoPlay_SplitDetect_Check
	bit 0, (0x28b2:16)
	jr nz, AccAutoPlay_SplitDetect_Return
	bit 2, (0x28b1:16)
	jr nz, AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Check:
	bit 7, w
	jr z, AccAutoPlay_SplitDetect_Process
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Upper
	ld c, 0x1:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Upper:
	ld c, 0x0:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Process:
	bit 0, (0xfd53:16)
	jr nz, AccAutoPlay_SplitDetect_NoSplit
	and w, 0xf
	ld l, (0xf9c3:16)
	and l, 0xf
	cp l, w
	jr z, AccAutoPlay_SplitDetect_Lower
	ld l, (0xfbe5:16)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Apply
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Apply
	ld c, 0x1:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Lower:
	push_a
	calr AccAutoPlay_ModeAvail
	pop_a
	cp l, a
	jr c, AccAutoPlay_SplitDetect_Apply
	ld c, 0x1:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Apply:
	ld c, 0x0:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_NoSplit:
	and w, 0xf
	ld l, (0xf9f7:16)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Store
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Store
	ld c, 0x1:opc
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Store:
	ld l, (0xfbe5:16)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Return
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Return
	ld c, 0x1:opc

AccAutoPlay_SplitDetect_Return:
	ret

AccAutoPlay_ZoneTrack:
	cp (0x7f0b:16), 0
	jr nz, AccAutoPlay_ZoneTrack_Update
	pushw wa
	calr AccPedal_StyleCheck
	cp a, 1:i3
	popw wa
	jr z, AccAutoPlay_ZoneTrack_Update
	bit 2, (0x28a7:16)
	jr nz, AccAutoPlay_ZoneTrack_Update
	calr AccAutoPlay_ZoneTrack_Apply
	ld hl, (0x349c:16)
	ld (0x349a:16), hl
	ld (0x349c:16), wa

AccAutoPlay_ZoneTrack_Update:
	ret

AccAutoPlay_ZoneTrack_Apply:
	ld xix, 0xceff
	ld wa, (xix + 2)
	cp wa, 0:i3
	jr nz, AccAutoPlay_ZoneTrack_Check
	ld l, 0x80:opc
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Check:
	cp wa, 1:i3
	jr nz, AccAutoPlay_ZoneTrack_Upper
	ld l, 0x0:opc
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Upper:
	ld l, 0xf0:opc

AccAutoPlay_ZoneTrack_Store:
	ld w, l
	calr AccAutoPlay_ZoneTrack_SetFlag
	ldw (0x38e8:16), 0
	ld bc, (xix + 0:8)
	ld e, 0x5:opc

AccAutoPlay_ZoneTrack_Clear:
	cp bc, 0:i3
	jr z, AccAutoPlay_ZoneTrack_Default
	ld	a, (xix+e)
	cp l, a
	jr c, AccAutoPlay_ZoneTrack_Finalize
	incw 1, (0x38e8:16)

AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	ld wa, (0x38e8:16)
	ret

AccAutoPlay_ZoneTrack_SetFlag:
	ld c, 0x0:opc
	bit 7, w
	jr z, AccAutoPlay_ZoneTrack_Done
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Done:
	bit 0, (0xfd53:16)
	jr nz, AccAutoPlay_ZoneTrack_Final
	calr AccAutoPlay_ModeAvail
	jr AccAutoPlay_ZoneTrack_Return2

AccAutoPlay_ZoneTrack_Final:
	ld l, 0x7f:opc

AccAutoPlay_ZoneTrack_Return2:
	ret

AccAutoPlay_ZoneTrack_Return:
	ret

AccAutoPlay_StateMachine:
	calr AccAutoPlay_TriggerCheck
	bit 6, (0x346e:16)
	jr z, AccAutoPlay_SM_CheckEligible
	cpw (0xf19e:16), 0
	jr z, AccAutoPlay_SM_CheckEligible
	cpw (0x28a8:16), 0
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_SetConfig
	bit 7, (0x346d:16)
	jr nz, AccAutoPlay_SM_CheckEligible
	calr AccAutoPlay_Disable

AccAutoPlay_SM_CheckEligible:
	ld (0x3474:16), 0
	calr AccAutoPlay_ActionDispatch
	bit 0, (0x3474:16)
	jr z, AccAutoPlay_SM_Return
	ld (0x3474:16), 0
	or (0x346e:16), 4
	calr AccReplay_FullRestart

AccAutoPlay_SM_Return:
	ret

AccAutoPlay_SM_Padding:
	nop
	nop

AccAutoPlay_TriggerCheck:
	bit 2, (0x28a7:16)
	jrl nz, AccAutoPlay_ModeAvail_Padding2
	calr AccAutoPlay_SetConfig
	bit 0, (0x3498:16)
	jrl z, AccAutoPlay_ModeAvail_Padding2
	bit 0, (0x3499:16)
	jrl nz, AccAutoPlay_Trigger_Activate
	bit 7, (0x346d:16)
	jr nz, AccAutoPlay_Trigger_Evaluate
	bit 2, (1054:16)
	jr nz, AccAutoPlay_Trigger_Process
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_Trigger_Process

AccAutoPlay_Trigger_Evaluate:
	calr AccAutoPlay_Configure

AccAutoPlay_Trigger_Process:
	or (0x3498:16), 1
	or (0x3499:16), 1
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Activate:
	bit 7, (0x3498:16)
	jr nz, AccAutoPlay_ModeAvail_Padding
	bit 7, (0x346d:16)
	jr z, AccAutoPlay_Trigger_Return
	cpw (0x349c:16), 0
	jr nz, AccAutoPlay_Trigger_Configure
	cpw (0x349a:16), 0
	jr z, AccAutoPlay_Trigger_Configure
	calr AccAutoPlay_SeqHandoff
	and (0x3498:16), 254
	and (0x3499:16), 254
	ldw (0x349a:16), 0
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Configure:
	cpw (0x349c:16), 0
	jr nz, AccAutoPlay_Trigger_Finalize
	cpw (0x349a:16), 0
	jr nz, AccAutoPlay_Trigger_Finalize
	ld (0x3498:16), 0
	ld (0x3499:16), 0

AccAutoPlay_Trigger_Finalize:
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Return:
	and (0x3498:16), 254
	and (0x3499:16), 254
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_ModeAvail_Padding:
	and (0x3498:16), 127

AccAutoPlay_ModeAvail_Padding2:
	ret

AccAutoPlay_ModeAvail_Padding3:
	nop
	nop

AccAutoPlay_ModeAvail:
	ld l, (0xfd02:16)
	and l, 0x3
	cp l, 0:i3
	jr nz, AccAutoPlay_ModeAvail_Process
	ld l, (0xfd03:16)
	and l, 0x7f
	dec 1, l
	cp l, 0xff
	jr nz, AccAutoPlay_ModeAvail_Check
	ld l, 0x0:opc

AccAutoPlay_ModeAvail_Check:
	jr AccAutoPlay_ModeAvail_SetMode

AccAutoPlay_ModeAvail_Process:
	push l
	ld xhl, 0:i3
	pop l
	add xhl, AccAutoPlay_ModeAvail_Extended_Code
	ld l, (xhl)

AccAutoPlay_ModeAvail_SetMode:
	cp (CURRENT_MODE:16), 14
	jr nz, AccAutoPlay_ModeAvail_Return
	ld l, 0x7f:opc

AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	nop
	nop
AccAutoPlay_ModeAvail_Extended_Code:
	push	xhl
	ldw	iz, 0x423b
	ld	xsp, 0xca041ef1
	jr	nz, 34
	bit	1, (0x346e:16)
	jr	z, 28
	bit	0, (0x3498:16)
	jr	z, 22
	bit	0, (0x3499:16)
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5AAE5-0xF5AAF5 (16 B), unreached CODE-territory, was disassembled as 5 plausible-but-dead instruction lines; per=67% dist=13 near AccAutoPlay_ModeAvail_Extended_Code+24
	jr	nz, 16
	calr	72
	ld	a, (0x3498:16)
	ld	(0x3499:16), a
	or	(0x3498:16), 1
	ret

AccAutoPlay_SetConfig:
	cpw (0x28a8:16), 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cpw (0xf19e:16), 0
	jr nz, AccAutoPlay_SetConfig_Apply
	cp (0x379b:16), 0
	jr nz, AccAutoPlay_SetConfig_Apply
	ld a, (0xfc5d:16)
	bit 3, a
	jr nz, AccAutoPlay_SetConfig_Apply
	and a, 0x7
	cp a, 0:i3
	jr z, AccAutoPlay_SetConfig_Apply
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_SetConfig_Apply
	or (0x346d:16), 128
	jr AccAutoPlay_SetConfig_Return

AccAutoPlay_SetConfig_Apply:
	ld (0x346d:16), 0

AccAutoPlay_SetConfig_Return:
	ret

AccAutoPlay_Configure:
	and (0x346e:16), 31
	cp (0x379b:16), 0
	jr nz, AccAutoPlay_Configure_Mode1
	cpw (0x28a8:16), 0
	jr nz, AccAutoPlay_Configure_Mode2
	cpw (0xf19e:16), 0
	jr z, AccAutoPlay_Configure_Mode1
	jr AccAutoPlay_Configure_Store

AccAutoPlay_Configure_Mode1:
	or (0x346e:16), 160
	calr AccAutoPlay_SubModeA
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Mode2:
	cpw (0xf19e:16), 0
	jr nz, AccAutoPlay_Configure_Store
	bit 2, (1056:16)
	jr z, AccAutoPlay_Configure_Apply
	or (0x346e:16), 128
	jr AccAutoPlay_Configure_Check

AccAutoPlay_Configure_Apply:
	or (0x346e:16), 224

AccAutoPlay_Configure_Check:
	jr AccAutoPlay_Configure_Return

AccAutoPlay_Configure_Store:
	bit 2, (1056:16)
	jr nz, AccAutoPlay_Configure_Return
	calr AccAutoPlay_ModeDecode
	calr AccAutoPlay_SubModeB

AccAutoPlay_Configure_Return:
	ret

AccAutoPlay_Configure_Extended:
	; --- Bit-flag conditional: check bits, and/clear (0x3498)/(0x3499) (54 bytes) ---
	nop
	nop
	bit	1, (0x346e:16)
	jr nz, AccAutoPlay_Configure_Final
	and	(0x3499:16), 254
	and	(0x3498:16), 254
	jr t, AccAutoPlay_Configure_Return2
AccAutoPlay_Configure_Final:
	bit	0, (0x3498:16)
	jr nz, AccAutoPlay_Configure_Return2
	bit	0, (0x3499:16)
	jr z, AccAutoPlay_Configure_Return2
	bit	7, (0x346d:16)
	jr z, AccAutoPlay_Configure_Done
	calr AccAutoPlay_SeqHandoff
AccAutoPlay_Configure_Done:
	and	(0x3499:16), 254
	and	(0x3498:16), 254
AccAutoPlay_Configure_Return2:
	ret
	nop
	nop


AccAutoPlay_PeriodicCheck:
	bit 1, (0xfc5f:16)
	jr nz, AccAutoPlay_Periodic_Evaluate
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Evaluate:
	bit 2, (0x346e:16)
	jr z, AccAutoPlay_Periodic_Process
	calr AccAutoPlay_SetConfig
	bit 7, (0x346d:16)
	jr nz, AccAutoPlay_Periodic_Padding
	calr AccAutoPlay_Disable
	jr AccAutoPlay_Periodic_Padding

AccAutoPlay_Periodic_Padding:
	and (0x346e:16), 251
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Process:
	cpw (0xf19e:16), 0
	jr nz, AccAutoPlay_Periodic_Toggle
	cpw (0x28a8:16), 0
	jr z, AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Toggle:
	calr AccAutoPlay_Disable

AccAutoPlay_Periodic_Return:
	ret

AccAutoPlay_Disable:
	and (0xfc5f:16), 253
	ld w, 0x2:opc
	ld a, 0x0:opc
	ld d, 0x5:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	ret

AccAutoPlay_Disable_Return:
	nop
	nop

AccAutoPlay_SubModeA:
	bit 7, (0x346d:16)
	jr z, AccAutoPlay_SubModeA_Return
	bit 2, (1054:16)
	jr nz, AccAutoPlay_SubModeA_Apply
	bit 0, (0x3283:16)
	jr z, AccAutoPlay_SubModeA_Check
	bit 1, (0x3283:16)
	jr z, AccAutoPlay_SubModeA_Check
	and (0x346d:16), 239
	or (0x346d:16), 1
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Check:
	and (0x346d:16), 239
	or (0x346d:16), 4
	jr AccAutoPlay_SubModeA_Return

AccAutoPlay_SubModeA_Apply:
	ld a, (1056:16)
	bit 2, a
	jr z, AccAutoPlay_SubModeA_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeA_Return
	and (1056:16), 247
	and (1054:16), 247
	and (0x346d:16), 239
	or (0x346d:16), 8

AccAutoPlay_SubModeA_Return:
	ret

AccAutoPlay_SubModeA_Padding:
	nop
	nop

AccAutoPlay_SubModeB:
	bit 7, (0x346d:16)
	jr z, AccAutoPlay_SubModeB_Return
	bit 2, (1054:16)
	jr nz, AccAutoPlay_SubModeB_Apply
	bit 0, (0x3283:16)
	jr z, AccAutoPlay_SubModeB_Check
	bit 1, (0x3283:16)
	jr z, AccAutoPlay_SubModeB_Check
	and (0x346d:16), 239
	or (0x346d:16), 2
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Check:
	and (0x346d:16), 239
	or (0x346d:16), 4
	jr AccAutoPlay_SubModeB_Return

AccAutoPlay_SubModeB_Apply:
	ld a, (1056:16)
	bit 2, a
	jr z, AccAutoPlay_SubModeB_Return
	bit 3, a
	jr z, AccAutoPlay_SubModeB_Return
	and (1056:16), 247
	and (1054:16), 247
	and (SEQ_TRANSPORT_STATE:16), 247
	and (0x346d:16), 239
	or (0x346d:16), 8

AccAutoPlay_SubModeB_Return:
	ret

AccAutoPlay_SubModeB_Padding:
	nop
	nop

AccAutoPlay_SeqHandoff:
	cp (0x379b:16), 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	cpw (0x28aa:16), 0
	jr nz, AccAutoPlay_SeqHandoff_Return
	bit 2, (1054:16)
	jr z, AccAutoPlay_SeqHandoff_Return
	and (0x346d:16), 247
	or (0x346d:16), 16
	cpw (0xf19e:16), 0
	jr nz, AccAutoPlay_SeqHandoff_Process
	bit 2, (1056:16)
	jr z, AccAutoPlay_SeqHandoff_Return
	ei 6
	calr AccPlayMode_StopToSync2
	ei 0
	jr AccAutoPlay_SeqHandoff_Return

AccAutoPlay_SeqHandoff_Process:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, AccAutoPlay_SeqHandoff_Return
	bit 2, (1054:16)
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
	ld a, (0x28a7:16)
	and a, 0x3
	cp a, 2:i3
	jr nz, AccAutoPlay_ModeDecode_Process
	or (0x346e:16), 160
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Process:
	cp a, 1:i3
	jr nz, AccAutoPlay_ModeDecode_Apply
	or (0x346e:16), 96
	jr AccAutoPlay_ModeDecode_Return

AccAutoPlay_ModeDecode_Apply:
	cp a, 3:i3
	jr nz, AccAutoPlay_ModeDecode_Return
	or (0x346e:16), 224

AccAutoPlay_ModeDecode_Return:
	ret

AccAutoPlay_ModeDecode_Padding:
	nop
	nop

AccAutoPlay_ActionDispatch:
	ld a, (0x346d:16)
	bit 7, a
	jr z, AccAutoPlay_Action_Check
	bit 2, (0x346d:16)
	jr z, AccAutoPlay_Action_Finalize
	and a, 0xfb
	or a, 0x8
	ld (0x346d:16), a

AccAutoPlay_Action_Check:
	ld a, (0x346e:16)
	ld b, a
	and a, 0xe0
	cp a, 0:i3
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
	bit 3, (0x346d:16)
	jr nz, AccAutoPlay_Action_Finalize

AccAutoPlay_Action_Finalize:
	and (0x346e:16), 31

AccAutoPlay_Action_Return:
	ret

AccAutoPlay_Action_Padding:
	nop
	nop

AccAutoPlay_DeferredAction:
	bit 7, (0x346d:16)
	jr z, AccAutoPlay_Deferred_Return
	bit 0, (0x346d:16)
	jr z, AccAutoPlay_Deferred_Process
	and (0x346d:16), 238
	or (0x346d:16), 8
	ei 6
	calr AccPlayMode_StartAccPlayFull
	ei 0
	calr AccReplay_FullRestart
	jr AccAutoPlay_Deferred_Return

AccAutoPlay_Deferred_Process:
	bit 1, (0x346d:16)
	jr z, AccAutoPlay_Deferred_Return
	and (0x346d:16), 237
	or (0x346d:16), 8
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
	bit 2, (1054:16)
	jr z, AccPlayMode_Dispatch_Check
	or l, 0x4

AccPlayMode_Dispatch_Check:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, AccPlayMode_Dispatch_Select
	or l, 0x8

AccPlayMode_Dispatch_Select:
	bit 2, (1056:16)
	jr z, AccPlayMode_Dispatch_Execute
	or l, 0x10

AccPlayMode_Dispatch_Execute:
	ld xwa, AccPlayMode_Dispatch_Execute_Data
	add xhl, xwa
	ld xwa, (xhl)
	call (xwa)
	ei 0
	ret

AccPlayMode_Dispatch_Table:
	.byte	0x00, 0x00
AccPlayMode_Dispatch_Execute_Data:	.byte	0x19, 0xae, 0xf5, 0x00, 0x4d, 0xaf
	.byte 0xf5, 0x00, 0xd0, 0xaf, 0xf5, 0x00, 0x04, 0xb0
	.byte 0xf5, 0x00, 0xb7, 0xaf, 0xf5, 0x00, 0x3c, 0xaf
	.byte 0xf5, 0x00, 0xb2, 0xaf, 0xf5, 0x00, 0x9d, 0xaf
	.byte 0xf5, 0x00, 0x0e, 0x00, 0x00

AccPlayMode_TransitionRouter:
	cpw (0x28a8:16), 0
	jr z, AccPlayMode_Router_Process
	cpw (0xf19e:16), 0
	jr z, AccPlayMode_Router_Check
	calr AccPlayMode_Router_Alt
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Check:
	calr AccPlayMode_StartRecording
	jr AccPlayMode_Router_Return

AccPlayMode_Router_Process:
	cpw (0xf19e:16), 0
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
	bit 2, (1056:16)
	jr nz, AccPlayMode_Router_AltPadding
	calr AccPlayMode_StartPlay
	jr AccPlayMode_Router_AltPadding

AccPlayMode_Router_AltPadding:
	ret

AccPlayMode_StartRecording_Padding:
	nop
	nop

AccPlayMode_StartRecording:
	bit 2, (1056:16)
	jr nz, AccPlayMode_StartRec_Apply
	bit 1, (0x28a7:16)
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
	bit 2, (1056:16)
	jr nz, AccPlayMode_StartAcc_Apply
	bit 1, (0x28a7:16)
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
	bit 2, (1056:16)
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
	bit 2, (0x28a7:16)
	jr nz, AccPlayMode_StartPlay_Return
	bit 1, (0x28a7:16)
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
	bit 2, (1054:16)
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
	bit 0, (1056:16)
	jr nz, AccPlayMode_StopExprB_Return
	bit 2, (1056:16)
	jr nz, AccPlayMode_StopExprB_Return
	bit 2, (0x28b2:16)
	jr nz, AccPlayMode_StopExprB_Process
	bit 1, (0x28b2:16)
	jr z, AccPlayMode_StopExprB_Process
	call SeqPlay_SetBarAndResetScroll
	ld (1054:16), 128
	or (0x28b2:16), 4
	jr AccPlayMode_StartAccPlay_Return

AccPlayMode_StopExprB_Process:
	ld (1056:16), 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StopExprB_Return:
	ld (SEQ_TRANSPORT_STATE:16), 1
	calr AccTempo_ClearSubPos

AccPlayMode_StartAccPlay:
	ld (1054:16), 1
	or (0x3474:16), 1
	calr AccTempo_ClearPositions
	ld a, 0x85:opc
	calr AccTempo_WriteStartMarker

AccPlayMode_StartAccPlay_Return:
	ret

AccPlayMode_StartAccPlay_Padding:
	nop
	nop

AccPlayMode_StopToSync2:
	bit 3, (1056:16)
	jr nz, AccPlayMode_StartPlay2
	bit 2, (1056:16)
	jr z, AccPlayMode_StartPlay2
	ld (1056:16), 12

AccPlayMode_StartPlay2:
	ld (1054:16), 12
	ld (0x3470:16), 0
	ld a, 0x86:opc
	calr AccTempo_WriteStartMarker
	ret

AccPlayMode_StartPlay2_Padding:
	nop
	nop

AccPlayMode_StartPlayFull:
	bit 2, (0x28b2:16)
	jr nz, AccPlayMode_StartPlayFull_Process
	bit 1, (0x28b2:16)
	jr z, AccPlayMode_StartPlayFull_Process
	call SeqPlay_SetBarAndResetScroll
	ld (1054:16), 128
	or (0x28b2:16), 4
	jr AccPlayMode_StartPlayFull_Return

AccPlayMode_StartPlayFull_Process:
	ld (SEQ_TRANSPORT_STATE:16), 1
	calr AccTempo_ClearSubPos
	bit 0, (1056:16)
	jr nz, AccPlayMode_StartPlayFull_Return
	bit 2, (1056:16)
	jr nz, AccPlayMode_StartPlayFull_Return
	ld (1056:16), 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StartPlayFull_Return:
	ret

AccPlayMode_StartPlayFull_Padding:
	nop
	nop

AccPlayMode_StopExprFull:
	ld (1054:16), 12
	bit 0, (0x28b2:16)
	jr nz, AccPlayMode_StopExprFull_Process
	or (0x347a:16), 4

AccPlayMode_StopExprFull_Process:
	ld a, 0x86:opc
	calr AccTempo_WriteStartMarker

AccPlayMode_StopExprC:
	ld (SEQ_TRANSPORT_STATE:16), 12
	bit 3, (1056:16)
	jr nz, AccPlayMode_StopExprC_Process
	bit 2, (1056:16)
	jr z, AccPlayMode_StopExprC_Process
	ld (1056:16), 12

AccPlayMode_StopExprC_Process:
	ld (0x3470:16), 0
	ret

AccPlayMode_StopExprC_Return:
	nop
	nop

AccPlayMode_StopExprD:
	ld (SEQ_TRANSPORT_STATE:16), 12
	ret

AccPlayMode_StopExprD_Return:
	nop
	nop

AccPlayMode_StartAccPlayFull:
	ld (1054:16), 1
	or (0x3474:16), 1
	calr AccTempo_ClearPositions
	ld a, 0x85:opc
	calr AccTempo_WriteStartMarker
	bit 0, (1056:16)
	jr nz, AccPlayMode_StartAccPlayFull_Return
	bit 2, (1056:16)
	jr nz, AccPlayMode_StartAccPlayFull_Return
	ld (1056:16), 1
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock

AccPlayMode_StartAccPlayFull_Return:
	ret

AccPlayMode_StartAccPlayFull_Padding:
	nop
	nop
	ld	(SEQ_TRANSPORT_STATE:16), 12
	ld	(1054:16), 12
	and	(0x3470:16), 15
	ld	a, 134:opc
	calr	AccTempo_WriteStartMarker
	ret
	nop
	nop

AccTempo_ClearCounters:
	xor wa, wa
	ei 6
	ld (1047:16), a
	ld (1048:16), wa
	ei 0
	ret

AccTempo_ClearPositions:
	xor wa, wa
	ei 6
	bit 0, (0x28a6:16)
	jr nz, AccTempo_ClearPositions_Loop
	ld (1045:16), a
	ld (1046:16), a

AccTempo_ClearPositions_Loop:
	ld (1076:16), a
	ld (1077:16), a
	ei 0
	and (0x28a6:16), 254
	ret

AccTempo_ClearSubPos:
	xor wa, wa
	ei 6
	bit 3, (0x28a7:16)
	jr nz, AccTempo_ClearSubPos_Loop
	ld (SEQ_BEAT_COUNT:16), wa
	ld (SEQ_BEAT_TICK:16), a

AccTempo_ClearSubPos_Loop:
	ei 0
	ret

AccSync_MidiClock:
	bit 2, (0xfd52:16)
	jr z, AccSync_MidiClock_Return
	ei 6
	bit 3, (0x28a7:16)
	jr z, AccSync_MidiClock_Update
	or (1065:16), 4
	jr AccSync_MidiClock_Apply

AccSync_MidiClock_Update:
	or (1065:16), 2

AccSync_MidiClock_Apply:
	call MIDI_SC0_TX_DISPATCH
	ei 0

AccSync_MidiClock_Return:
	ret

AccSync_MidiClock_Padding:
	nop
	nop

AccTempo_WriteStartMarker:
	cpw (0x28aa:16), 0
	jr z, AccTempo_WriteMarker_Return

AccTempo_WriteStopMarker:
	ei 6
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ld a, (SEQ_BEAT_TICK:16)
	pushw wa
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	ei 0

AccTempo_WriteMarker_Return:
	ret

AccTempo_WriteMarker_Padding:
	nop
	nop
AccTempo_WriteMarker_Padding_Return:
	ret

AccReplay_FullRestart:
	ld (0x3474:16), 0
	or (0x3491:16), 1
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
	cp wa, 0:i3
	jr nz, AccReplay_Restart_Snapshot
	inc 1, bc
	cp bc, 0x200
	jr c, AccReplay_Restart_WaitIdle
	jr AccReplay_Restart_ReInit

AccReplay_Restart_Snapshot:
	call RhythmBuf_DispatchWrap
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cp wa, 0:i3
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	calr AccTiming_AlignTo8Tick
	calr AccTempo_CheckSource
	call SeqTiming_Snapshot

AccReplay_Restart_Drain:
	xor wa, wa
	call RhythmBuf_CheckEmpty
	cp wa, 0:i3
	jr z, AccReplay_Restart_ReInit
	call RhythmBuf_DispatchWrap
	jr AccReplay_Restart_Drain

AccReplay_Restart_ReInit:
	and (0x3491:16), 254
	ret

AccReplay_Restart_Return:
	nop
	nop

AccTiming_AlignTo8Tick:
	pushw hl
	ldw bc, 0x8
	ld wa, (SYSTEM_TIMESTAMP:16)
	add wa, bc

AccTiming_Align_Compute:
	ld hl, wa
	sub hl, (SYSTEM_TIMESTAMP:16)
	cp hl, 0:i3
	jr le, AccTiming_Align_Return
	jr AccTiming_Align_Compute

AccTiming_Align_Return:
	popw hl
	ret

AccPlayMode_WaitIdle:
	xor bc, bc

AccPlayMode_WaitIdle_Check:
	bit 0, (1054:16)
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
	cp (1115:16), 1
	jr nz, AccTempo_CheckSource_Process
	cp (0xcedf:16), 0
	jr z, AccTempo_CheckSource_Process
	ld (1115:16), 0

AccTempo_CheckSource_Process:
	bit 0, (1115:16)
	jr z, AccTempo_CheckSource_Clear
	bit 2, (1054:16)
	jr nz, AccTempo_CheckSource_Return

AccTempo_CheckSource_Clear:
	call Seq_DispatcherEntry
	ld (1124:16), 0

AccTempo_CheckSource_Return:
	ret

AccTempo_CheckSource_Padding:
	nop
	nop

AccReplay_SavedPedal:
	ld a, (SWBTWR_PAYLOAD_1:16)
	pushw wa
	ld w, (SWBTWR_PAYLOAD_2:16)
	ld a, (SWBTWR_PAYLOAD_3:16)
	pushw wa
	ld a, (0x3488:16)
	ld (SWBTWR_PAYLOAD_1:16), a
	ld a, (0x3475:16)
	ld (SWBTWR_PAYLOAD_2:16), a
	ld a, (RHYTHM_VARIATION_INDEX:16)
	ld (SWBTWR_PAYLOAD_3:16), a
	ld a, (0x90f8:16)
	pushw wa
	ld (0x90f8:16), 0
	calr AccPedal_EventDispatch
	popw wa
	ld (0x90f8:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_2:16), w
	ld (SWBTWR_PAYLOAD_3:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_1:16), a
	xor a, a
	ld (0x3475:16), a
	ld (RHYTHM_VARIATION_INDEX:16), a
	ld (0x3488:16), a
	ld wa, 0:i3
	ld d, 0x5:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	ld wa, 0:i3
	ld d, 0x6:opc
	ld e, 0x48:opc
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
	ld a, (SWBTWR_PAYLOAD_1:16)
	pushw wa
	ld w, (SWBTWR_PAYLOAD_2:16)
	ld a, (SWBTWR_PAYLOAD_3:16)
	pushw wa
	cp l, 0:i3
	jr nz, AccReplay_SendPedal_Process
	ld (SWBTWR_PAYLOAD_1:16), 5
	ld (SWBTWR_PAYLOAD_2:16), 4
	ld (SWBTWR_PAYLOAD_3:16), 4
	jr AccReplay_SendPedal_Dispatch

AccReplay_SendPedal_Process:
	ld (SWBTWR_PAYLOAD_1:16), 6
	ld (SWBTWR_PAYLOAD_2:16), 4
	ld (SWBTWR_PAYLOAD_3:16), 4

AccReplay_SendPedal_Dispatch:
	ld a, (0x90f8:16)
	pushw wa
	ld (0x90f8:16), 0
	calr AccPedal_EventDispatch
	popw wa
	ld (0x90f8:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_2:16), w
	ld (SWBTWR_PAYLOAD_3:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_1:16), a
	ld wa, 0:i3
	ld d, 0x5:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	ld wa, 0:i3
	ld d, 0x6:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	call AudioMode_SetStereoFlags
	ret

AccReplay_SendPedal_Return:
	nop
	nop

AccReplay_SavedExpression:
	ld a, (SWBTWR_PAYLOAD_1:16)
	pushw wa
	ld w, (SWBTWR_PAYLOAD_2:16)
	ld a, (SWBTWR_PAYLOAD_3:16)
	pushw wa
	ld a, (0x3489:16)
	ld (SWBTWR_PAYLOAD_1:16), a
	ld a, (0x347c:16)
	ld (SWBTWR_PAYLOAD_2:16), a
	ld a, (0x347d:16)
	ld (SWBTWR_PAYLOAD_3:16), a
	ld a, (0x90f8:16)
	pushw wa
	ld (0x90f8:16), 255
	calr AccPedal_EventDispatch
	popw wa
	ld (0x90f8:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_2:16), w
	ld (SWBTWR_PAYLOAD_3:16), a
	popw wa
	ld (SWBTWR_PAYLOAD_1:16), a
	xor a, a
	ld (0x347c:16), a
	ld (0x347d:16), a
	ld (0x3489:16), a
	ld wa, 0:i3
	ld d, 0x5:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	ld wa, 0:i3
	ld d, 0x6:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	call AudioMode_SetStereoFlags
	ret

AccReplay_SavedExpr_Return:
	nop
	nop
	ld	xwa, RHYTHM_PATTERN_BUF_A
	add	xwa, 14
	ld	wa, (xwa)
	cp	wa, 0:i3
	jr	z, AccReplay_SendPedalType6_Return
	call	AccDemo_InitDone
AccReplay_SendPedalType6_Return:
	ret
	nop
	nop

AccReplay_FullStop:
	ld a, (0xfc5f:16)
	and a, 0xc
	ld c, (0xfc60:16)
	and c, 0x4
	or a, c
	cp a, 0:i3
	jr z, AccReplay_Stop_ClearPedals
	and (0xfc5f:16), 243
	ld wa, 0:i3
	ld d, 0x5:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent
	and (0xfc60:16), 251
	ld wa, 0:i3
	ld d, 0x6:opc
	ld e, 0x48:opc
	call SwbtWr_QueuePostEvent

AccReplay_Stop_ClearPedals:
	call Seq_DispatcherEntry
	cp (0x3479:16), 0
	jr z, AccReplay_Stop_ResetPosition
	ld a, (0x3479:16)
	add (1079:16), a
	ld (0x3479:16), 0

AccReplay_Stop_ResetPosition:
	and (1079:16), 7
	ld a, (1079:16)
	cp a, (1075:16)
	jr c, AccReplay_Stop_Rebuild
	sub a, (1075:16)
	ld (1079:16), a
	ld a, (1075:16)
	ld (0x3479:16), a

AccReplay_Stop_Rebuild:
	xor wa, wa
	ld (1045:16), a
	ld (1046:16), a
	or (0x34cd:16), 128
	or (0x347a:16), 1
	ld e, (1078:16)
	ld d, (1079:16)
	cp de, 0:i3
	jr z, AccReplay_Stop_Finalize
	sub e, 0x18
	jr nc, AccReplay_Stop_CheckMode
	add e, 0x60
	dec 1, d
	cp d, 0xff
	jr nz, AccReplay_Stop_CheckMode
	ld de, 0:i3

AccReplay_Stop_CheckMode:
	xor bc, bc
	and (0x347a:16), 127

AccReplay_Stop_Process:
	ld (1045:16), c
	ld (1046:16), b
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
	bit 7, (0x347a:16)
	jr nz, AccReplay_Stop_Finalize
	cp bc, de
	jr c, AccReplay_Stop_Process
	or (0x347a:16), 128
	cp bc, de
	jr z, AccReplay_Stop_Process
	ld bc, de
	jr AccReplay_Stop_Process

AccReplay_Stop_Finalize:
	ld a, (1078:16)
	ld (1045:16), a
	ld a, (1079:16)
	ld (1046:16), a
	and (0x347a:16), 254
	call Seq_DispatcherEntry
	ret

AccReplay_Stop_Return:
	nop
	nop

AccPos_SaveOnStop:
	ld a, (SWBTWR_PAYLOAD_3:16)
	cp a, 0:i3
	jr z, AccPos_SaveOnStop_Return
	bit 0, (0x28a6:16)
	jr z, AccPos_SaveOnStop_Return
	ei 6
	ld a, (1045:16)
	ld (1078:16), a
	ld a, (1046:16)
	ld (1079:16), a
	xor wa, wa
	ld (1045:16), a
	ld (1046:16), a
	ei 0
	calr AccReplay_FullStop

AccPos_SaveOnStop_Return:
	ret

AccPos_SaveOnStop_Padding:
	nop
	nop

AccPos_ClearOnStart:
	bit 0, (0x3283:16)
	jr nz, AccPos_ClearOnStart_Return
	xor wa, wa
	ei 6
	ld (1045:16), a
	ld (1046:16), a
	ei 0
	ld (1078:16), a
	ld (1079:16), a
	ld (0x3479:16), a
	or (0x34cd:16), 128
	call Seq_DispatcherEntry

AccPos_ClearOnStart_Return:
	ret

AccPos_ClearOnStart_Padding:
	nop
	nop
AccPos_ClearOnStart_Padding_Sub:
	cp	(CURRENT_MODE:16), 19
	jr	nz, AccPos_ClearOnStart_Padding_Sub_Skip
	and	(0x347a:16), 253
	and	(0x28a6:16), 254
	jr	AccPos_ClearOnStart_Padding_Sub_Return
AccPos_ClearOnStart_Padding_Sub_Skip:
	bit	1, (0x347a:16)
	jr	z, AccPos_ClearOnStart_Padding_Sub_Return
	ld	a, (0x3283:16)
	and	a, 3
	cp	a, 0:i3
	jr	nz, AccPos_ClearOnStart_Padding_Sub_Return
	ld	(0x3479:16), 0
	calr	AccReplay_FullStop
	and	(0x347a:16), 253
AccPos_ClearOnStart_Padding_Sub_Return:
	ret
	nop
	nop

AccFlags_SyncTo64607:
	ld e, (1056:16)
	and (0xfc5f:16), 254
	bit 2, e
	jr z, AccFlags_Sync_Process
	or (0xfc5f:16), 1

AccFlags_Sync_Process:
	ld a, e
	xor a, (0x347b:16)
	bit 2, a
	jr z, AccFlags_Sync_UpdateLED
	ld a, 0x22:opc
	call CtrlPanel_SetIndicatorBit

AccFlags_Sync_UpdateLED:
	ld (0x347b:16), e
	bit 0, (0x349e:16)
	jr z, AccFlags_Sync_Return
	and (0x349e:16), 254

AccFlags_Sync_Return:
	ret

AccFlags_Sync_Padding:
	nop
	nop

AccTiming_InitAllParts:
	ldw (0x3374:16), 0xff5f
	ldw (0x337c:16), 6
	ldw (0x337e:16), 48
	ld xbc, 0x3094
	calr AccKbdTiming_TableScan
	ld xbc, 0x30c4
	calr AccKbdTiming_TableScan
	ldw (0x337c:16), 9
	ldw (0x337e:16), 72
	ld (0x338c:16), 7
	ld xbc, 0x30f4
	calr AccAccTiming_TableScan
	ld (0x338c:16), 4
	ld xbc, 0x313c
	calr AccAccTiming_TableScan
	ld (0x338c:16), 5
	ld xbc, 0x3184
	calr AccAccTiming_TableScan
	ld (0x338c:16), 6
	ld xbc, 0x31cc
	calr AccAccTiming_TableScan
	ld wa, (0x3374:16)
	ld (0x3372:16), wa
	jr AccTiming_MasterTick_Return

AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	ld (0x3377:16), 95
	ldw (0x337c:16), 6
	ldw (0x337e:16), 48
	ld a, (0x3385:16)
	ld (0x3384:16), a
	ld xhl, 0x2a94
	ld xbc, 0x3094
	calr AccKbdTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x3385:16), a
	ld a, (0x3386:16)
	ld (0x3384:16), a
	ld xhl, 0x2b94
	ld xbc, 0x30c4
	calr AccKbdTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x3386:16), a
	ldw (0x337c:16), 9
	and (0x338d:16), 254
	ldw (0x337e:16), 72
	ld (0x338c:16), 7
	ld a, (0x3387:16)
	ld (0x3384:16), a
	ld a, (0x332f:16)
	ld (0x3333:16), a
	ld xhl, 0x2c94
	ld xbc, 0x30f4
	calr AccAccTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x3387:16), a
	ld a, (0x3333:16)
	ld (0x332f:16), a
	ld (0x338c:16), 4
	ld a, (0x3388:16)
	ld (0x3384:16), a
	ld a, (0x3330:16)
	ld (0x3333:16), a
	ld xhl, 0x2d94
	ld xbc, 0x313c
	calr AccAccTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x3388:16), a
	ld a, (0x3333:16)
	ld (0x3330:16), a
	ld (0x338c:16), 5
	ld a, (0x3389:16)
	ld (0x3384:16), a
	ld a, (0x3331:16)
	ld (0x3333:16), a
	ld xhl, 0x2e94
	ld xbc, 0x3184
	calr AccAccTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x3389:16), a
	ld a, (0x3333:16)
	ld (0x3331:16), a
	ld (0x338c:16), 6
	ld a, (0x338a:16)
	ld (0x3384:16), a
	ld a, (0x3332:16)
	ld (0x3333:16), a
	ld xhl, 0x2f94
	ld xbc, 0x31cc
	calr AccAccTiming_ScanRingBuf
	ld a, (0x3384:16)
	ld (0x338a:16), a
	ld a, (0x3333:16)
	ld (0x3332:16), a
	ld a, (0x3377:16)
	ld (0x3376:16), a
	jr AccKbdTiming_Ret

AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	ld (0x3a78:16), 255
	ld ix, (xhl + 6)

AccKbdTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccKbdTiming_ScanDone
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_ClassifyEvent
	ld ix, (xhl + 0:8)

AccKbdTiming_ClassifyEvent:
	ld w, a
	cp a, 0xdf
	jr z, AccKbdTiming_SpecialEvent
	cp a, 0x9f
	jr nz, AccKbdTiming_CheckNoteOn

AccKbdTiming_SpecialEvent:
	ld (0x3380:16), 2
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckNoteOn:
	cp a, 0x90
	jr nz, AccKbdTiming_CheckProgramChg
	ld (0x3380:16), 4
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckProgramChg:
	and a, 0xf0
	cp a, 0xc0
	jr nz, AccKbdTiming_CheckControl
	ld (0x3380:16), 5
	jr AccKbdTiming_StoreEventData

AccKbdTiming_CheckControl:
	cp a, 0xd0
	jrl nz, AccKbdTiming_SkipEvent
	ld (0x3380:16), 2

AccKbdTiming_StoreEventData:
	ld (0x3a79:16), a
	ld	a, (xhl+ix)
	ld (0x3378:16), ix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_CheckTimestamp
	ld ix, (xhl + 0:8)

AccKbdTiming_CheckTimestamp:
	cp a, (1117:16)
	jrl ugt, AccKbdTiming_TimestampOverflow
	ld a, w
	and a, 0xf0
	cp w, 0x9f
	jrl z, AccKbdTiming_WriteNonNote
	cp w, 0xdf
	jrl z, AccKbdTiming_WriteNonNote
	cp a, 0x90
	jrl nz, AccKbdTiming_WriteNonNote_Prep
	cp (0x3a78:16), 0
	jr nz, AccKbdTiming_NoteSlotScan
	pushw wa
	ld a, 0x8:opc
	ld (0x3a7c:16), a
	popw wa
	calr AccKbdTiming_CatchupReplay
	ld (0x3a78:16), 255

AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	cp iz, (0x337e:16)
	jr nc, AccKbdTiming_SlotOverflow
	bit	7, (xbc+iz)
	jr z, AccKbdTiming_WriteNoteEvent
	add iz, (0x337c:16)
	jr AccKbdTiming_SlotLoop

AccKbdTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ld a, (0x3384:16)
	sla xwa, 2
	add xwa, AccTiming_SlotOffsetTables
	ld iz, (xwa)
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	pushw iz
	inc 2, iz
	ld	w, (xbc+iz)
	and a, 0xf0
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	popw iz
	popw wa
	inc 1, (0x3384:16)
	cp (0x3384:16), 8
	jr c, AccKbdTiming_SlotOverflow_Done
	ld (0x3384:16), 0

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
	ld	(xbc+iz), a
	inc 1, iz
	ld a, 0x0:opc
	ld	(xbc+iz), a
	inc 1, iz
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte2
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	ld	(xbc+iz), a
	inc 1, iz
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte3
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	ld	(xbc+iz), a
	inc 1, iz
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ReadTiming
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNote_ReadTiming:
	ld	w, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_ClampTiming
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNote_ClampTiming:
	cp wa, 0xa
	jr ugt, AccKbdTiming_WriteNote_AddBase
	ldw wa, 0xa

AccKbdTiming_WriteNote_AddBase:
	add wa, (1118:16)
	cp a, 0x60
	jr c, AccKbdTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccKbdTiming_WriteNote_StoreTiming:
	ld	(xbc+iz), wa
	cp wa, (0x3372:16)
	jr nc, AccKbdTiming_WriteNote_UpdateReadPos
	ld (0x3372:16), wa

AccKbdTiming_WriteNote_UpdateReadPos:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_WriteNonNote_Prep:
	ld w, a
	or a, 0x8

AccKbdTiming_WriteNonNote:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte2
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte3
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xdf
	jr nz, AccKbdTiming_WriteNonNote_CheckType
	ld a, 0x0:opc
	ld (0x332f:16), a
	ld (0x3330:16), a
	ld (0x3331:16), a
	ld (0x3332:16), a
	jr AccKbdTiming_WriteNonNote_Done

AccKbdTiming_WriteNonNote_CheckType:
	cp w, 0x9f
	jr z, AccKbdTiming_WriteNonNote_Done
	cp w, 0xd0
	jr z, AccKbdTiming_WriteNonNote_Done
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte4
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNonNote_Byte4:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte5
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNonNote_Byte6
	ld ix, (xhl + 0:8)

AccKbdTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte

AccKbdTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccKbdTiming_EventLoop

AccKbdTiming_TimestampOverflow:
	cp (0x3a79:16), 192
	jr nz, AccKbdTiming_Overflow_SubBase
	ld (0x3a78:16), 0

AccKbdTiming_Overflow_SubBase:
	sub a, (1117:16)
	cp a, (0x3377:16)
	jr nc, AccKbdTiming_Overflow_CalcSkip
	ld (0x3377:16), a

AccKbdTiming_Overflow_CalcSkip:
	ld ix, (0x3378:16)
	ld	(xhl+ix), a
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_Overflow_AdvancePos
	ld ix, (xhl + 0:8)

AccKbdTiming_Overflow_AdvancePos:
	xor wa, wa
	ld a, (0x3380:16)
	add ix, wa
	cp ix, (xhl + 2)
	jrl ule, AccKbdTiming_EventLoop
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 0:8)
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
	ld	a, (xhl+ix)
	ld w, a
	and w, 0xf0
	cp w, 0xc0
	jr nz, AccKbdTiming_Catchup_SkipNonC0
	ld a, w
	or a, (0x3a7c:16)
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	calr AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr AccSeq_WriteByte
	calr AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
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
	ld ix, (xhl + 0:8)

AccKbdTiming_AdvancePos_Ret:
	ret

AccKbdTiming_TableScan:
	xor iz, iz

AccKbdTiming_TableScan_Loop:
	cp iz, (0x337e:16)
	jp nc, (AccKbdTiming_TableScan_Done:24)
	bit	7, (xbc+iz)
	jr z, AccKbdTiming_TableScan_NextSlot
	ld ix, iz
	ld	a, (xbc+ix)
	ld (0x3381:16), a
	inc 2, ix
	ld	a, (xbc+ix)
	ld (0x3382:16), a
	inc 1, ix
	ld	a, (xbc+ix)
	ld (0x3383:16), a
	inc 1, ix
	ld	wa, (xbc+ix)
	cp wa, (1118:16)
	jr gt, AccKbdTiming_TableScan_Decrement
	ld a, 0xf0:opc
	and a, (0x3381:16)
	or a, 0x8
	calr AccSeq_WriteByte
	ld a, (0x3382:16)
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	and	(xbc+iz), 0x7f
	jr AccKbdTiming_TableScan_NextSlot

AccKbdTiming_TableScan_Decrement:
	sub wa, (1118:16)
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	ld	(xbc+ix), wa
	cp wa, (0x3374:16)
	jr nc, AccKbdTiming_TableScan_NextSlot
	ld (0x3374:16), wa

AccKbdTiming_TableScan_NextSlot:
	add iz, (0x337c:16)
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
	ld (0x3a7a:16), 255
	ld ix, (xhl + 6)

AccAccTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccAccTiming_ScanDone
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 0:8)

AccAccTiming_ClassifyEvent:
	ld w, a
	cp a, 0x90
	jr nz, AccAccTiming_Check0x91
	ld (0x3380:16), 5
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x91:
	cp a, 0x91
	jr nz, AccAccTiming_Check0x92
	ld (0x3380:16), 7
	jr AccAccTiming_StoreEventData

AccAccTiming_Check0x92:
	cp a, 0x92
	jr nz, AccAccTiming_CheckProgramChg
	ld (0x3380:16), 6
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckProgramChg:
	and a, 0xf0
	cp a, 0xc0
	jr nz, AccAccTiming_CheckControl
	ld (0x3380:16), 5
	jr AccAccTiming_StoreEventData

AccAccTiming_CheckControl:
	cp a, 0xd0
	jrl nz, AccAccTiming_SkipEvent
	ld (0x3380:16), 2

AccAccTiming_StoreEventData:
	ld (0x3a7b:16), a
	ld	a, (xhl+ix)
	ld (0x337a:16), ix
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_CheckTimestamp
	ld ix, (xhl + 0:8)

AccAccTiming_CheckTimestamp:
	cp a, (1117:16)
	jrl ugt, AccAccTiming_TimestampOverflow
	ld a, w
	and a, 0xf0
	cp a, 0x90
	jrl nz, AccAccTiming_WriteNonNote
	cp (0x3a7a:16), 0
	jr nz, AccAccTiming_NoteSlotScan
	pushw wa
	ld a, (0x338c:16)
	ld (0x3a7c:16), a
	popw wa
	calr AccKbdTiming_CatchupReplay
	ld (0x3a7a:16), 255

AccAccTiming_NoteSlotScan:
	pushw wa
	ld	w, (xhl+ix)
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	cp iz, (0x337e:16)
	jr nc, AccAccTiming_NoteSlot_FindFree
	bit	7, (xbc+iz)
	jr z, AccAccTiming_NoteSlot_NextSlot
	ldfr_werp IZ, 0xfa
	add iz, 0x2
	cp	(xbc+iz), w
	ldto_werp IZ, 0xfa
	jr z, AccAccTiming_NoteSlot_SendNoteOff

AccAccTiming_NoteSlot_NextSlot:
	add iz, (0x337c:16)
	jr AccAccTiming_NoteSlot_Loop

AccAccTiming_NoteSlot_SendNoteOff:
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	and a, 0xf0
	or a, (0x338c:16)
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	bit 0, (0x338d:16)
	jr nz, AccAccTiming_NoteSlot_FindFree
	or (0x338d:16), 1
	ld a, 0x90:opc
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	calr AccSeq_WriteByte

AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	cp iz, (0x337e:16)
	jr nc, AccAccTiming_SlotOverflow
	bit	7, (xbc+iz)
	jr z, AccAccTiming_WriteNoteEvent
	add iz, (0x337c:16)
	jr AccAccTiming_NoteSlot_FreeLoop

AccAccTiming_SlotOverflow:
	pushw wa
	xor xwa, xwa
	ld a, (0x3384:16)
	sla xwa, 2
	add xwa, AccAccTiming_SlotOverflow_Data
	ld iz, (xwa)
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	pushw iz
	inc 2, iz
	ld	w, (xbc+iz)
	and a, 0xf0
	or a, (0x338c:16)
	calr AccSeq_WriteByte
	ld a, w
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	popw iz
	popw wa
	inc 1, (0x3384:16)
	cp (0x3384:16), 8
	jr c, AccAccTiming_SlotOverflow_Done
	ld (0x3384:16), 0

AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	or a, (0x338c:16)
	calr AccSeq_WriteByte
	ld a, w
	ld	(xbc+iz), a
	inc 1, iz
	ld a, 0x0:opc
	ld	(xbc+iz), a
	inc 1, iz
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte2
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	ld	(xbc+iz), a
	inc 1, iz
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte3
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	ld	(xbc+iz), a
	inc 1, iz
	pushw wa
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingLo
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_ReadTimingLo:
	ld	w, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_ReadTimingHi
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_ReadTimingHi:
	add wa, (1118:16)
	cp a, 0x60
	jr c, AccAccTiming_WriteNote_StoreTiming
	inc 1, w
	sub a, 0x60

AccAccTiming_WriteNote_StoreTiming:
	ld	(xbc+iz), wa
	inc 2, iz
	cp wa, (0x3372:16)
	jr nc, AccAccTiming_WriteNote_ExtraBytes
	ld (0x3372:16), wa

AccAccTiming_WriteNote_ExtraBytes:
	popw wa
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra1
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_StoreExtra1:
	ld	(xbc+iz), a
	inc 1, iz
	cp w, 0x90
	jr z, AccAccTiming_WriteNote_Done
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra2
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_StoreExtra2:
	ld	(xbc+iz), a
	inc 1, iz
	cp w, 0x92
	jr z, AccAccTiming_WriteNote_Done
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra3
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNote_StoreExtra3:
	ld	(xbc+iz), a
	inc 1, iz

AccAccTiming_WriteNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNonNote:
	ld w, a
	or a, (0x338c:16)
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte2
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNonNote_Byte2:
	calr AccSeq_WriteByte
	ld (0x3334:16), a
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte3
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNonNote_Byte3:
	calr AccSeq_WriteByte
	cp w, 0xd0
	jr nz, AccAccTiming_WriteNonNote_ExtBytes
	cp (0x3334:16), 3
	jr nz, AccAccTiming_WriteNonNote_Done
	ld (0x3333:16), a
	jr AccAccTiming_WriteNonNote_Done

AccAccTiming_WriteNonNote_ExtBytes:
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte5
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNonNote_Byte5:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte6
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNonNote_Byte6:
	calr AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNonNote_Byte7
	ld ix, (xhl + 0:8)

AccAccTiming_WriteNonNote_Byte7:
	calr AccSeq_WriteByte

AccAccTiming_WriteNonNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_TimestampOverflow:
	cp (0x3a7b:16), 192
	jr nz, AccAccTiming_Overflow_SubBase
	ld (0x3a7a:16), 0

AccAccTiming_Overflow_SubBase:
	sub a, (1117:16)
	cp a, (0x3377:16)
	jr nc, AccAccTiming_Overflow_CalcSkip
	ld (0x3377:16), a

AccAccTiming_Overflow_CalcSkip:
	ld ix, (0x337a:16)
	ld	(xhl+ix), a
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_Overflow_AdvancePos
	ld ix, (xhl + 0:8)

AccAccTiming_Overflow_AdvancePos:
	xor wa, wa
	ld a, (0x3380:16)
	add ix, wa
	cp ix, (xhl + 2)
	jrl ule, AccAccTiming_EventLoop
	sub ix, (xhl + 2)
	dec 1, ix
	add ix, (xhl + 0:8)
	jrl AccAccTiming_EventLoop

AccAccTiming_ScanDone:
	ret

AccAccTiming_TableScan:
	xor iz, iz

AccAccTiming_TableScan_Loop:
	cp iz, (0x337e:16)
	jp nc, (AccAccTiming_TableScan_Done:24)
	bit	7, (xbc+iz)
	jr z, AccAccTiming_TableScan_NextSlot
	ld ix, iz
	ld	a, (xbc+ix)
	ld (0x3381:16), a
	inc 2, ix
	ld	a, (xbc+ix)
	ld (0x3382:16), a
	inc 1, ix
	ld	a, (xbc+ix)
	ld (0x3383:16), a
	inc 1, ix
	ld	wa, (xbc+ix)
	cp wa, (1118:16)
	jr gt, AccAccTiming_TableScan_Decrement
	ld a, 0xf0:opc
	and a, (0x3381:16)
	or a, (0x338c:16)
	calr AccSeq_WriteByte
	ld a, (0x3382:16)
	calr AccSeq_WriteByte
	ld a, 0x0:opc
	calr AccSeq_WriteByte
	and	(xbc+iz), 0x7f
	jr AccAccTiming_TableScan_NextSlot

AccAccTiming_TableScan_Decrement:
	sub wa, (1118:16)
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	ld	(xbc+ix), wa
	cp wa, (0x3374:16)
	jr nc, AccAccTiming_TableScan_NextSlot
	ld (0x3374:16), wa

AccAccTiming_TableScan_NextSlot:
	add iz, (0x337c:16)
	jrl AccAccTiming_TableScan_Loop

AccAccTiming_TableScan_Done:
	ret

AccTiming_SlotOffsetTables:
; AccTiming_SlotOffsetTables -- two tables of 8 x LE32 slot offsets.
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/`ei 0`/incf/`calr 0`/`jp 0`
; mnemonics plus a 16-byte .byte tail (data-as-code).  Readers:
;   AccKbdTiming_SlotOverflow:  xor xwa,xwa / ld a,(0x3384) / sla xwa,2 /
;       add xwa, AccTiming_SlotOffsetTables / ld iz,(xwa)
;   AccAccTiming_SlotOverflow:  the same, from AccAccTiming_SlotOverflow_Data
; so entry (0x3384) (stride 4, low 16 bits used) becomes IZ, the byte offset
; of a note slot that the code then reads and writes through the SRI (xix+iz)
; forms.  The first table steps by 6 and the second by 9 -- consistent with
; the per-slot stride the two free-slot scans add (`add iz, (0x337c:16)`).
; Size: the +0x20 reader pins the first table at 8 entries; the second is
; the 32 bytes up to AccDir_Entry.
; readers in v9/v10 (address from the linked ELF): AccKbdTiming_SlotOverflow 0xF5B6D1,
;     AccAccTiming_SlotOverflow 0xF5BABA
; -- comments that sat inside this range before the re-type, in order:
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5BD66-0xF5BD76 (16 B), unreached CODE-territory, was disassembled as 13 plausible-but-dead instruction lines; per=75% dist=5 near AccAccTiming_SlotOverflow_Data+16
; +0x00  8 x LE32 = 0, 6, 12 ... 42 (stride 6) -- keyboard-timing slots
	.long 0x00000000, 0x00000006, 0x0000000c, 0x00000012
	.long 0x00000018, 0x0000001e, 0x00000024, 0x0000002a
; +0x20  8 x LE32 = 0, 9, 18 ... 63 (stride 9) -- accompaniment-timing slots
AccAccTiming_SlotOverflow_Data:
	.long 0x00000000, 0x00000009, 0x00000012, 0x0000001b
	.long 0x00000024, 0x0000002d, 0x00000036, 0x0000003f

AccDir_Entry:
	jp AccDir_Main

AccDir_PeriodicEntry:
	jp AccDir_PeriodicCheck

AccDir_Main:
	calr AccDir_ReadState
	cp (0x34a7:16), 0
	jr nz, AccDir_CheckLeftNote
	cp (0x34a8:16), 0
	jr z, AccDir_CheckLeftNote
	or (0x349f:16), 1

AccDir_CheckLeftNote:
	cp (0x34a9:16), 0
	jr nz, AccDir_CheckRightHandState
	cp (0x34aa:16), 0
	jr z, AccDir_CheckRightHandState
	or (0x349f:16), 8

AccDir_CheckRightHandState:
	ld a, (0x34a5:16)
	bit 0, a
	jr nz, AccDir_Finalize
	bit 1, a
	jr z, AccDir_Finalize
	and (0x349f:16), 246
	ld (0x34a6:16), 0

AccDir_Finalize:
	calr AccDir_AdjustDirection
	calr AccDir_SavePrevState
	ret

AccDir_Padding1:
	nop
	nop

AccDir_ReadState:
	ld a, (0xfc5a:16)
	ld (0x34a4:16), a
	ld a, (0x3312:16)
	and a, 0x3f
	ld (0x34a7:16), a
	ld a, (0x3313:16)
	and a, 0x3f
	ld (0x34a9:16), a
	ld a, (1045:16)
	ld (0x34a0:16), a
	ld a, (0x34a5:16)
	and a, 0xfe
	bit 0, (0x3283:16)
	jr z, AccDir_ReadState_StoreFlags
	or a, 0x1

AccDir_ReadState_StoreFlags:
	ld (0x34a5:16), a
	ld a, (0xfd99:16)
	bit 0, a
	jr nz, AccDir_ReadState_Ret
	and (0x349f:16), 246

AccDir_ReadState_Ret:
	ret

AccDir_Padding2:
	nop
	nop

AccDir_SavePrevState:
	ld a, (0x34a7:16)
	ld (0x34a8:16), a
	ld a, (0x34a9:16)
	ld (0x34aa:16), a
	ld a, (0x34a5:16)
	and a, 0xfd
	bit 0, a
	jr z, AccDir_SavePrevState_StoreFlags
	or a, 0x2

AccDir_SavePrevState_StoreFlags:
	ld (0x34a5:16), a
	ret

AccDir_Padding3:
	nop
	nop

AccDir_AdjustDirection:
	ld a, (0x349f:16)
	and a, 0x9
	cp a, 0:i3
	jp z, (AccDir_Adjust_Ret:24)
	bit 0, (0x349f:16)
	jr z, AccDir_Adjust_LeftHand
	and (0x349f:16), 254
	cp (0x34a4:16), 128
	jr nc, AccDir_Adjust_LeftHand
	ld w, (0xfd99:16)
	and w, 0x1
	ld a, (0xfc61:16)
	and a, 0x30
	srl a, 4
	cp w, 0:i3
	jr z, AccDir_Adjust_LeftHand
	dec 1, a
	cp a, 0xff
	jr nz, AccDir_Adjust_RightDec
	ld a, 0x0:opc

AccDir_Adjust_RightDec:
	sll a, 4
	and (0xfc61:16), 207
	or (0xfc61:16), a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	bit 3, (0x349f:16)
	jr z, AccDir_Adjust_SetChanged
	and (0x349f:16), 247
	cp (0x34a4:16), 128
	jr nc, AccDir_Adjust_SetChanged
	ld w, (0xfd99:16)
	and w, 0x1
	ld a, (0xfc61:16)
	and a, 0x30
	srl a, 4
	cp w, 0:i3
	jr z, AccDir_Adjust_SetChanged
	inc 1, a
	cp a, 4:i3
	jr c, AccDir_Adjust_LeftInc
	ld a, 0x3:opc

AccDir_Adjust_LeftInc:
	sll a, 4
	and (0xfc61:16), 207
	or (0xfc61:16), a
	calr AccDir_DispatchEvent

AccDir_Adjust_SetChanged:
	ld (0x34a6:16), 1

AccDir_Adjust_Ret:
	ret

AccDir_Padding4:
	nop
	nop

AccDir_DispatchEvent:
	ld w, (0xfd99:16)
	and w, 0x1
	cp w, 0:i3
	jr z, AccDir_DispatchEvent_Ret
	cp (0x34a4:16), 128
	jr nc, AccDir_DispatchEvent_Ret
	ld e, 0x48:opc
	ld d, 0x7:opc
	ld a, (0xfc61:16)
	ld w, 0x30:opc
	call SwbtWr_QueuePostEvent
	ld a, (0xfd99:16)
	and a, 0x70
	cp a, 0x10
	jr z, AccDir_DispatchEvent_Ret
	ld a, (0xfc61:16)
	and a, 0x30
	srl a, 4
	ld (0x8d54:16), a
	call EffectMode_ReinitWithFlag

AccDir_DispatchEvent_Ret:
	ret

AccDir_Padding5:
	nop
	nop

AccDir_PeriodicCheck:
	bit 4, (0x3284:16)
	jr z, AccDir_Periodic_Ret
	cp (0x34a6:16), 0
	jr z, AccDir_Periodic_CheckCountdown
	dec 1, (0x34a6:16)

AccDir_Periodic_CheckCountdown:
	cp (0x34a6:16), 0
	jr nz, AccDir_Periodic_Ret
	ld a, (1045:16)
	cp a, 0x5d
	jr nc, AccDir_Periodic_DisableAndReset
	cp a, 0x30
	jr ugt, AccDir_Periodic_Ret

AccDir_Periodic_DisableAndReset:
	and (0x3284:16), 239
	and (0x3284:16), 251
	call AudioMode_SetStereoFlags

AccDir_Periodic_Ret:
	ret

AccDir_JumpTable:
	nop
	nop
	call	AccProcess_InlinedCode
	ret

AccProcess_Entry:
	call AccProcess_TimerCompare
	ret

AccProcess_InlinedCode:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 18
	jp	nz, (0xf5bfe1:24)
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 1
	cp	a, 1:i3
	jp	nz, (0xf5bfe1:24)
	bit	0, (0x3490:16)
	jr	nz, AccProcess_Entry_Skip5
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	(RHYTHM_PATTERN_SEL_B:16), wa
	or	(0x3490:16), 1
	jr	AccProcess_Entry_Return
AccProcess_Entry_Skip5:
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	bc, (RHYTHM_PATTERN_SEL_B:16)
	cp	wa, bc
	jr	c, AccProcess_Entry_Skip6
	sub	wa, bc
	jr	AccProcess_Entry_Join
AccProcess_Entry_Skip6:
	and	xwa, 0xffff
	and	xbc, 0xffff
	add	xwa, 0x010000
	sub	xwa, xbc
AccProcess_Entry_Join:
	cp	wa, 750
	jr	c, AccProcess_Entry_Skip
	ldw	wa, 750
AccProcess_Entry_Skip:
	cp	wa, 100
	jr	ugt, AccProcess_Entry_Skip2
	ldw	wa, 100
AccProcess_Entry_Skip2:
	ld	bc, wa
	ld	xwa, 0x7530
	div	xwa, bc
	pushw	wa
	calr	AccProcess_Entry_Helper
	popw	wa
	ld	hl, (0x3494:16)
	ld	(0x3496:16), hl
	ld	hl, (0x3492:16)
	ld	(0x3494:16), hl
	ld	(0x3492:16), wa
	ld	wa, (SYSTEM_TIMESTAMP:16)
	ld	(RHYTHM_PATTERN_SEL_B:16), wa
AccProcess_Entry_Return:
	ret
AccProcess_Entry_Helper:
	ld	de, (0x3492:16)
	ld	bc, (0x3494:16)
	cp	de, 0:i3
	jr	nz, AccProcess_Entry_Skip3
	jp	AccProcess_InlinedCode_Join
AccProcess_Entry_Skip3:
	cp	bc, 0:i3
	jr	nz, AccProcess_Entry_Skip4
	add	wa, de
	srl	wa, 1
	jp	AccProcess_InlinedCode_Join
AccProcess_Entry_Skip4:
	add	wa, de
	add	wa, bc
	and	xwa, 0xffff
	div	wa, 3
AccProcess_InlinedCode_Join:
	ld	e, 72:opc
	ld	d, 8:opc
	call	SwbtWr_TrailingBytecode
	ret

AccProcess_TimerCompare:
	bit 0, (0x3490:16)
	jr z, AccProcess_Timer_Ret
	ld wa, (SYSTEM_TIMESTAMP:16)
	ld bc, (RHYTHM_PATTERN_SEL_B:16)
	cp wa, bc
	jr c, AccProcess_Timer_WrapCase
	sub wa, bc
	cp wa, 0x400
	jr c, AccProcess_Timer_Skip
	and (0x3490:16), 254
	xor wa, wa
	ld (0x3492:16), wa
	ld (0x3494:16), wa
	ld (0x3496:16), wa

AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	and xwa, 0xffff
	and xbc, 0xffff
	add xwa, 0x10000
	sub xwa, xbc
	cp wa, 0x400
	jr c, AccProcess_Timer_Ret
	and (0x3490:16), 254
	xor wa, wa
	ld (0x3492:16), wa
	ld (0x3494:16), wa
	ld (0x3496:16), wa

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
	add xwa, AccVoice_RomRecords13
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
	ld xix, AccVoice_ROMLookup_Data
	ld xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, (xix+hl)
	ld xix, 0x34ab
	ldw bc, 0xd
	ldir85
	ret

AccVoice_ROMLookup_OffsetTable:
	.byte	0x00, 0x00
AccVoice_ROMLookup_Data:	.byte	0xa0, 0x00, 0x00, 0x00, 0x00, 0x01


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
	ld xix, AccVoice_IndexedTableLookup_Data
	ld	xiy, (xix+hl)
	ld xix, AccVoice_IndexedTableLookup_Data_2
	add	xiy, (xix+hl)
	ld xix, 0x34ab
	ldw bc, 0xd
	ldir85
	ret

AccVoice_IndexedTableLookup_BaseOffsets:
; RE-FRAMED 2026-09-02 (lane v10seq), replacing three per-span
; data-as-code annotations left by lane V10DAC inside this block --
; 0xF5C1E6-0xF5C219, 0xF5C246-0xF5C279 and 0xF5C2A7-0xF5C2D8 -- with one
; typing of the whole table. The rest was still spelled as mnemonics.
; All three references to this block are `ld xix, <label>`; nothing calls
; or jumps into +0x02..+0x151.
; +0x00 (2 B) head; the table below is based at +0x02
	.byte 0x00, 0x00	; |..|
; +0x02 (84 x LE32). AccVoice_IndexedTableLookup: ld l,h / xor h,h / sla hl,2 then ld xix = this label / ld_sril3 -- stride 4.
AccVoice_IndexedTableLookup_Data:
	.long 0x00300000, 0x00300000, 0x00300000, 0x00300000
	.long 0x00300000, 0x00300000, 0x00300000, 0x00300000
	.long 0x00300000, 0x00300000, 0x00300000, 0x00300000
	.long 0x00319800, 0x00319800, 0x00319800, 0x00319800
	.long 0x00319800, 0x00319800, 0x00319800, 0x00319800
	.long 0x00319800, 0x00319800, 0x00319800, 0x00319800
	.long 0x00330000, 0x00330000, 0x00330000, 0x00330000
	.long 0x00330000, 0x00330000, 0x00330000, 0x00330000
	.long 0x00330000, 0x00330000, 0x00330000, 0x00330000
	.long 0x00349800, 0x00349800, 0x00349800, 0x00349800
	.long 0x00349800, 0x00349800, 0x00349800, 0x00349800
	.long 0x00349800, 0x00349800, 0x00349800, 0x00349800
	.long 0x00360000, 0x00360000, 0x00360000, 0x00360000
	.long 0x00360000, 0x00360000, 0x00360000, 0x00360000
	.long 0x00360000, 0x00360000, 0x00360000, 0x00360000
	.long 0x00379800, 0x00379800, 0x00379800, 0x00379800
	.long 0x00379800, 0x00379800, 0x00379800, 0x00379800
	.long 0x00379800, 0x00379800, 0x00379800, 0x00379800
	.long 0x00390000, 0x00390000, 0x00390000, 0x00390000
	.long 0x00390000, 0x00390000, 0x00390000, 0x00390000
	.long 0x00390000, 0x00390000, 0x00390000, 0x00390000
; AccVoice_IndexedTableLookup_BaseOffsets +0x152 (84 x LE32).
; RE-FRAMED 2026-09-02 (lane v10seq). Was ~270 lines of mnemonics.
; AccVoice_IndexedTableLookup: ld l,h / xor h,h / sla hl,2 then
; ld xix,<this label> / add_sril_rm -- stride 4, added to the parallel
; table at +0x02. 336 B = 84 entries, ending exactly where the routine
; that reads +0x2C8 begins. The values are the ramp 0xA0, 0x100, 0x160,
; ... step 0x60.
; Seven `naka_header NAKA_TYPE_0x00` invocations inside this range were a
; misframe and are gone: the macro emits 00 00 60 01, and each sat at an
; offset 2 mod 4 from this table base, i.e. straddling two entries. The
; bytes they emitted are unchanged.
AccVoice_IndexedTableLookup_Data_2:
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	.long 0x000000a0, 0x00000100, 0x00000160, 0x000001c0
	.long 0x00000220, 0x00000280, 0x000002e0, 0x00000340
	.long 0x000003a0, 0x00000400, 0x00000460, 0x000004c0
	sub	l, 140
	and	hl, 7
	sla	hl, 2
	ld	xix, AccVoice_IndexedTableLookup_BaseOffsets_Data
	ld	xiy, RHYTHM_PATTERN_BUF_A
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
; AccVoice_IndexedTableLookup_BaseOffsets +0x2C8 (8 x LE32).
; 2026-09-02 (lane v10seq). Read by the routine immediately above:
; sub l,140 / and hl,7 / sla hl,2 then ld xix,<this label> -- `and hl,7`
; gives exactly the 8 entries below, and 8*4 B ends where
; AccVoice_GetChannelCount begins.
AccVoice_IndexedTableLookup_BaseOffsets_Data:
	.long 0x00000bb0, 0x00000bd0, 0x00000bf0, 0x00000c10
	.long 0x00000c30, 0x00000bb0, 0x00000bb0, 0x00000bb0
AccVoice_GetChannelCount:
	push xix
	cp l, 0x10
	jr c, AccVoice_GetChannelCount_Lookup
	xor l, l

AccVoice_GetChannelCount_Lookup:
	and hl, 0x1f
	ld xix, AccVoice_GetChannelCount_Lookup_Data
	ld	l, (xix+hl)
	pop xix
	ret

AccVoice_ChannelCountTable:
	.byte	0x00, 0x00
AccVoice_GetChannelCount_Lookup_Data:	.byte	0x0f, 0x0c, 0x10, 0x09, 0x12, 0x0d
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
	add xwa, AccVoice_RomRecords16
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
	calr	AccVoice_Dispatch
	popw	hl
	ld	xix, 0:i3
	ldw	bc, 8
	ldirw
	ld	xiy, AccVoice_CopyFromROM_DataBlock_Data
	jr	c, AccVoice_CopyFromROM_Join
	ld	xiy, AccVoice_CopyFromROM_DataBlock_Data_2
AccVoice_CopyFromROM_Join:
	ld	wa, (xiy)
	ld	c, (xiy+2)
	cp	wa, 0xffff
	jr	z, AccVoice_CopyFromROM_Skip2
	cp	wa, hl
	jr	z, AccVoice_CopyFromROM_Skip
	add	iy, 3
	jr	AccVoice_CopyFromROM_Join
AccVoice_CopyFromROM_Skip:
	cp	c, 0:i3
	jr	nz, AccVoice_CopyFromROM_Skip3
	ld	(P0:8), 0:io
	ld	(1:8), 1:io
	jr	AccVoice_CopyFromROM_Skip2
AccVoice_CopyFromROM_Skip3:
	ld	(P2FC:8), 0:io
	ld	(P3:8), 1:io
AccVoice_CopyFromROM_Skip2:
	ld	xiy, 0:i3
	ret
; AccVoice_CopyFromROM_DataBlock +0x46.. -- two key/value tables searched by
; the routine above (AccVoice_CopyFromROM_DataBlock):
;     ld xiy, AccVoice_CopyFromROM_DataBlock_Data  (or _0x6D, chosen by carry)
;  l: ld wa,(xiy) / ld c,(xiy+2) / cp wa,0xffff / jr z,<none> / cp wa,hl /
;     jr z,<found> / add iy,3 / jr l
; so each record is {LE16 key, u8 value}, the key compared with HL and the
; value (C) tested for zero on a match; a key of 0xFFFF ends a table.
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/`pop sr`/max/`push sr`
; mnemonics (data-as-code).  Each table ends with two key-0xFFFF records
; (the reader stops at the first); the second table then starts at +0x6D,
; exactly the reader's other base.
; readers in v9/v10 (address from the linked ELF): AccVoice_CopyFromROM_DataBlock 0xF5C4C7
; +0x44  2 B between the routine's `ret` and the first table
	.byte 0x00, 0x00
; +0x46  table 0: 13 records {LE16 key, u8 value} ending in key-0xFFFF records
AccVoice_CopyFromROM_DataBlock_Data:
	.byte 0x03, 0x02, 0x00	; key 0x0203 -> 0
	.byte 0x04, 0x03, 0x00	; key 0x0304 -> 0
	.byte 0x04, 0x04, 0x00	; key 0x0404 -> 0
	.byte 0x05, 0x02, 0x00	; key 0x0205 -> 0
	.byte 0x06, 0x04, 0x00	; key 0x0406 -> 0
	.byte 0x06, 0x06, 0x01	; key 0x0606 -> 1
	.byte 0x0b, 0x03, 0x00	; key 0x030b -> 0
	.byte 0x0b, 0x04, 0x00	; key 0x040b -> 0
	.byte 0x0d, 0x02, 0x00	; key 0x020d -> 0
	.byte 0x0d, 0x07, 0x01	; key 0x070d -> 1
	.byte 0x0e, 0x01, 0x00	; key 0x010e -> 0
	.byte 0xff, 0xff, 0x00	; key 0xffff -> 0
	.byte 0xff, 0xff, 0x00	; key 0xffff -> 0
; +0x6d  table 1: 12 records {LE16 key, u8 value} ending in key-0xFFFF records
AccVoice_CopyFromROM_DataBlock_Data_2:
	.byte 0x03, 0x02, 0x00	; key 0x0203 -> 0
	.byte 0x04, 0x02, 0x00	; key 0x0204 -> 0
	.byte 0x04, 0x06, 0x00	; key 0x0604 -> 0
	.byte 0x05, 0x02, 0x00	; key 0x0205 -> 0
	.byte 0x0b, 0x02, 0x00	; key 0x020b -> 0
	.byte 0x0b, 0x05, 0x01	; key 0x050b -> 1
	.byte 0x0d, 0x02, 0x00	; key 0x020d -> 0
	.byte 0x0e, 0x07, 0x00	; key 0x070e -> 0
	.byte 0x0e, 0x09, 0x01	; key 0x090e -> 1
	.byte 0x0e, 0x0a, 0x01	; key 0x0a0e -> 1
	.byte 0xff, 0xff, 0x00	; key 0xffff -> 0
	.byte 0xff, 0xff, 0x00	; key 0xffff -> 0

AccStyle_Entry:
	jp AccStyle_Process
AccStyle_JumpTable:
	jp	AccStyle_ToggleBit0
	jp	AccStyle_ModeEnter
	jp	AccStyle_ModeExit
	jp	AccStyle_InlinedBlock_Helper

AccStyle_InitVRAM_Wrap:
	push xiz
	call AccStyle_InitVRAM
	pop xiz
	ret

AccStyle_JumpTable2:
	jp	AccStyle_IndexedLookup
	jp	AccStyle_SC0ByteSelect
	jp	AccStyle_SC0ByteSelect_Join
	jp	AccStyle_SC0ByteSelect_Join2
	jp	AccStyle_SC0ByteSelect_Join3
	jp	AccStyle_SC0ByteSelect_Join4
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
	ld a, (0x338e:16)
	and a, 0x1f
	jr z, AccStyle_Process_SaveState
	ld a, (0x338f:16)
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
	ld a, (0x338e:16)
	ld (0x338f:16), a
	ret

AccStyle_ToggleBit0:
	; --- Routine 1: XOR toggle bit 0 at (0x3391), conditional calls (51 bytes) ---
	cp	(CURRENT_MODE:16), 17
	jr nz, AccStyle_ToggleBit0_CheckC07D
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CheckC07D:
	cp	(SWBTWR_PAYLOAD_1:16), 6
	jr nz, AccStyle_ToggleBit0_Ret
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	bit 0, a
	jr z, AccStyle_ToggleBit0_Ret
	xor	(0x3391:16), 1
	bit	0, (0x3391:16)
	jr nz, AccStyle_ToggleBit0_CallOn
	call AccTuning_LEDOff
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CallOn:
	call AccTuning_LEDOn
AccStyle_ToggleBit0_Ret:
	ret
AccStyle_IndexedLookup:
	; --- Routine 2: indexed table lookup at 0xf5c8b4, store + DE/W setup (63 bytes) ---
	cp	(CURRENT_MODE:16), 17
	jr nz, AccStyle_IndexedLookup_Ret
	cp	(SWBTWR_PAYLOAD_1:16), 16
	jr nz, AccStyle_IndexedLookup_Ret
	ld	a, (0x338e:16)
	and a, 0x1f
	jr z, AccStyle_IndexedLookup_Ret
	ld	l, (0x338e:16)
	and l, 0x1f
	extz hl
	ld xwa, AccStyle_IndexedLookup_Data
	ld	a, (xwa+hl)
	cp	(PART_SELECT:16), a
	jr z, AccStyle_IndexedLookup_Ret
	ld	(PART_SELECT:16), a
	ld e, 0x90:opc
	ld d, 0x10:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent
AccStyle_IndexedLookup_Ret:
	ret


AccStyle_ModeEnter_Wrap:
	push xiz
	calr AccStyle_ModeEnter
	pop xiz
	ret

AccStyle_ModeEnter:
	cp (PREVIOUS_MODE:16), 17
	jr z, AccStyle_ModeEnter_Ret
	ld (0x338e:16), 0
	ld (0x338f:16), 0
	ld (0x339f:16), 0
	and (0x33d1:16), 254
	cpw (0xf19e:16), 0
	jr z, AccStyle_ModeEnter_SetFlags
	call SeqAcc_SetIndicator_PB
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	or (0x33d1:16), 1

AccStyle_ModeEnter_SetFlags:
	or (0x34cd:16), 8
	or (0x33d3:16), 1
	ld a, 0x4b:opc
	call CtrlPanel_SetIndicatorBit

AccStyle_ModeEnter_Ret:
	ret

AccStyle_ModeExit_Wrap:
	push xiz
	calr AccStyle_ModeExit
	pop xiz
	ret

AccStyle_ModeExit:
	cp (CURRENT_MODE:16), 17
	jr z, AccStyle_ModeExit_Ret
	ld (0x338e:16), 0
	ld (0x338f:16), 0
	ld (0x339f:16), 0
	and (0x34cd:16), 247
	bit 0, (0x33d1:16)
	jr z, AccStyle_ModeExit_ClearFlags
	and (0x33d1:16), 254
	call AccWrap_PlayModeDispatch
	call SeqAcc_RestorePlaybackState

AccStyle_ModeExit_ClearFlags:
	and (0x33d3:16), 252
	call PartSelect_UpdateDisplayState

AccStyle_ModeExit_Ret:
	ret

AccStyle_InlinedBlock:
	push	xiz
	calr	AccStyle_InlinedBlock_Helper
	pop	xiz
	ret
AccStyle_InlinedBlock_Helper:
	cp	(PREVIOUS_TITLE:16), 220
	jrl	z, AccStyle_InlinedBlock_Skip3
	cp	(0xfc5a:16), 128
	jr	c, AccStyle_InlinedBlock_Skip2
	ld	(0x339f:16), 1
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	ld	(GLOBAL_ERROR_CODE:16), 54
	call	DrumVoice_NotifyEE
	jrl	AccStyle_InlinedBlock_Return
AccStyle_InlinedBlock_Skip2:
	ld	(0x338e:16), 32
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 0x1e7810
	or	(xhl+1), 128
	calr	AccVoiceState_Snapshot
	call	AccTuning_LoadFromROM
	ld	e, (0x3246:16)
	ld	d, (0x3247:16)
	ld	xhl, 12820
	ld	(xhl), e
	ld	(xhl+1), d
	ld	e, (0x324d:16)
	ld	d, (0x324e:16)
	ld	a, (0x324f:16)
	ld	(0x342f:16), a
	ld	a, (0x3250:16)
	ld	(0x3430:16), a
	ld	a, (0x3251:16)
	ld	(0x3431:16), a
	ld	a, (0x3252:16)
	ld	(0x32c3:16), a
	ld	a, (0x3253:16)
	ld	(0x32c7:16), a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3219
	call	AccVoiceReg_StoreParamRecord
	ld	e, (0x3254:16)
	ld	d, (0x3255:16)
	ld	a, (0x3256:16)
	ld	(0x342f:16), a
	ld	a, (0x3257:16)
	ld	(0x3430:16), a
	ld	a, (0x3258:16)
	ld	(0x3431:16), a
	ld	a, (0x3259:16)
	ld	(0x32c3:16), a
	ld	a, (0x325a:16)
	ld	(0x32c7:16), a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x321e
	call	AccVoiceReg_StoreParamRecord
	ld	e, (0x325b:16)
	ld	d, (0x325c:16)
	ld	a, (0x325d:16)
	ld	(0x342f:16), a
	ld	a, (0x325e:16)
	ld	(0x3430:16), a
	ld	a, (0x325f:16)
	ld	(0x3431:16), a
	ld	a, (0x3260:16)
	ld	(0x32c3:16), a
	ld	a, (0x3261:16)
	ld	(0x32c7:16), a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3223
	call	AccVoiceReg_StoreParamRecord
	ld	e, (0x3262:16)
	ld	d, (0x3263:16)
	ld	a, (0x3264:16)
	ld	(0x342f:16), a
	ld	a, (0x3265:16)
	ld	(0x3430:16), a
	ld	a, (0x3266:16)
	ld	(0x3431:16), a
	ld	a, (0x3267:16)
	ld	(0x32c3:16), a
	ld	a, (0x3268:16)
	ld	(0x32c7:16), a
	call	Rhythm_PackVelocityHighBit
	ld	xhl, 0x3228
	call	AccVoiceReg_StoreParamRecord
	calr	AccVoiceReg_WritePart1
	calr	AccVoiceReg_WritePart2
	calr	AccVoiceReg_WritePart3
	calr	AccVoiceReg_WritePart4
	calr	AccVoiceReg_WritePart5
	ld	(0x338e:16), 1
	ld	a, 20:opc
	ld	(PART_SELECT:16), a
	ld	e, 144:opc
	ld	d, 16:opc
	ld	w, 255:opc
	call	SwbtWr_QueuePostEvent
AccStyle_InlinedBlock_Skip3:
	cp	(0x339f:16), 1
	jr	nz, AccStyle_InlinedBlock_Skip
	xor	wa, wa
	ld	a, 1:opc
	call	UI_PostPartChangeEvent
	jr	AccStyle_InlinedBlock_Return
AccStyle_InlinedBlock_Skip:
	ld	a, (0x338e:16)
	and	a, 31
	jr	z, AccStyle_InlinedBlock_Helper_Skip
	and	(0x33d3:16), 253
	or	(0x3391:16), 1
	call	AccTuning_LEDOn
	jr	AccStyle_InlinedBlock_Return
AccStyle_InlinedBlock_Helper_Skip:
	or	(0x33d3:16), 2
AccStyle_InlinedBlock_Return:
	ret
; AccStyle_InlinedBlock +0x1A0..+0x1FF -- two u8 tables after the routine above.
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/rcf/`ld (0:8),0:io`/push_a
; mnemonics (data-as-code).  The +0x1E0 table is read twice:
;   AccStyle_IndexedLookup ("Routine 2" above): l = (0x338e) & 0x1f /
;       ld xwa, AccStyle_IndexedLookup_Data / ld_rrb a, xwa, hl /
;       cp (0x8d3a), a
;   AccVoiceState_DispatchChange: ld xwa, AccStyle_IndexedLookup_Data /
;       ldb_sri E, 0x03, 0xe0, 0xec (c3 03 e0 ec 25 = ld e,(xwa+l)); E goes
;       to (0x90f7) before PartCtrl_WriteProgramChange
; so it maps the one-hot selector (0x338e) to the same 0x10..0x14 part codes
; AccPatch_PartNumberTable produces into (0x8d3a) -- in a different order.
; 32 entries: the `and l, 0x1f` of the first reader, ending at
; AccVoiceReg_WritePart3.
; readers in v9/v10 (address from the linked ELF): AccVoiceState_DispatchChange 0xF5CAF6
; +0x1A0  64 x u8 -- nonzero only at indices 2, 4, 8, 16, 32 (-> 1, 0x10, 8, 4, 2).
;          No reader found: no instruction holds this address (3-byte search
;          over the ROM), and no positional label names it.
	.byte 0x00, 0x00, 0x01, 0x00, 0x10, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x1E0  32 x u8 -- AccStyle_IndexedLookup_Data: one-hot index -> part code;
;          1 -> 0x14, 2 -> 0x13, 4 -> 0x10, 8 -> 0x11, 16 -> 0x12, else 0
AccStyle_IndexedLookup_Data:
	.byte 0x00, 0x14, 0x13, 0x00, 0x10, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

AccVoiceReg_WritePart3:
	cp (CURRENT_MODE:16), 17
	jr nz, AccVoiceReg_WritePart3_Ret
	ld a, (0x338e:16)
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart3_Ret
	ld a, (0x321e:16)
	ld w, (0x321f:16)
	bit 4, w
	jr z, AccVoiceReg_WritePart3_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart3_StoreBit4:
	ld (0xfb56:16), a
	and w, 0x7f
	and (0xfb57:16), 128
	or (0xfb57:16), w
	ld a, (0x3221:16)
	sla a, 6
	and a, 0x40
	and (0xfb5a:16), 191
	or (0xfb5a:16), a
	ld l, 0x4:opc
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart3_Ret:
	ret

AccVoiceReg_WritePart4:
	cp (CURRENT_MODE:16), 17
	jr nz, AccVoiceReg_WritePart4_Ret
	ld a, (0x338e:16)
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart4_Ret
	ld a, (0x3223:16)
	ld w, (0x3224:16)
	bit 4, w
	jr z, AccVoiceReg_WritePart4_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart4_StoreBit4:
	ld (0xfb70:16), a
	and w, 0x7f
	and (0xfb71:16), 128
	or (0xfb71:16), w
	ld a, (0x3226:16)
	sla a, 6
	and a, 0x40
	and (0xfb74:16), 191
	or (0xfb74:16), a
	ld l, 0x8:opc
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart4_Ret:
	ret

AccVoiceReg_WritePart5:
	cp (CURRENT_MODE:16), 17
	jr nz, AccVoiceReg_WritePart5_Ret
	ld a, (0x338e:16)
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart5_Ret
	ld a, (0x3228:16)
	ld w, (0x3229:16)
	bit 4, w
	jr z, AccVoiceReg_WritePart5_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart5_StoreBit4:
	ld (0xfb8a:16), a
	and w, 0x7f
	and (0xfb8b:16), 128
	or (0xfb8b:16), w
	ld a, (0x322b:16)
	sla a, 6
	and a, 0x40
	and (0xfb8e:16), 191
	or (0xfb8e:16), a
	ld l, 0x10:opc
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart5_Ret:
	ret

AccVoiceReg_WritePart2:
	cp (CURRENT_MODE:16), 17
	jr nz, AccVoiceReg_WritePart2_Ret
	ld a, (0x338e:16)
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart2_Ret
	ld a, (0x3219:16)
	ld w, (0x321a:16)
	bit 4, w
	jr z, AccVoiceReg_WritePart2_StoreBit4
	or a, 0x80
	and w, 0xef

AccVoiceReg_WritePart2_StoreBit4:
	ld (0xfba4:16), a
	and w, 0x7f
	and (0xfba5:16), 128
	or (0xfba5:16), w
	ld a, (0x321c:16)
	sla a, 6
	and a, 0x40
	and (0xfba8:16), 191
	or (0xfba8:16), a
	ld l, 0x2:opc
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart2_Ret:
	ret

AccVoiceReg_WritePart1:
	cp (CURRENT_MODE:16), 17
	jr nz, AccVoiceReg_WritePart1_Ret
	ld a, (0x338e:16)
	and a, 0x1f
	jr nz, AccVoiceReg_WritePart1_Ret
	ld a, (0x3214:16)
	or a, 0xf0
	ld w, (0x3215:16)
	and w, 0x7f
	ld (0xfbbe:16), a
	and (0xfbbf:16), 128
	or (0xfbbf:16), w
	ld l, 0x1:opc
	calr AccVoiceState_DispatchChange

AccVoiceReg_WritePart1_Ret:
	ret

AccVoiceState_Snapshot:
	calr AccHelper_ComputeVoiceOffset
	ld xiy, xhl
	add xiy, 0x1e7810
	ld a, (0xfbbe:16)
	ld w, (0xfbbf:16)
	and w, 0x7f
	ld (0x3395:16), wa
	and a, 0xf
	ld (xiy + 0:8), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	ld a, (0xfba4:16)
	ld w, (0xfba5:16)
	and w, 0x7f
	ld l, (0xfba8:16)
	and l, 0x40
	sla l, 1
	or w, l
	ld (0x3397:16), wa
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	ld a, (0xfb56:16)
	ld w, (0xfb57:16)
	and w, 0x7f
	ld l, (0xfb5a:16)
	and l, 0x40
	sla l, 1
	or w, l
	ld (0x3399:16), wa
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	ld a, (0xfb70:16)
	ld w, (0xfb71:16)
	and w, 0x7f
	ld l, (0xfb74:16)
	and l, 0x40
	sla l, 1
	or w, l
	ld (0x339b:16), wa
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	ld a, (0xfb8a:16)
	ld w, (0xfb8b:16)
	and w, 0x7f
	ld l, (0xfb8e:16)
	and l, 0x40
	sla l, 1
	or w, l
	ld (0x339d:16), wa
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	or (0x3393:16), 1
	ret

AccVoiceState_DispatchChange:
	push xiy
	ld xwa, AccStyle_IndexedLookup_Data
	ld	e, (xwa+l)
	extz hl
	sla hl, 2
	ld xwa, AccVoiceState_DispatchChange_Data
	ld	xwa, (xwa+hl)
	ld xiy, AccVoiceState_PartLookupTable
	ld	xiy, (xiy+hl)
	ld (0x90f7:16), e
	ld l, (xiy + 0:8)
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
	ld	(xwa+l), h
	ld a, (xiy + 1)
	and a, 0x7f
	ld w, 0x7f:opc
	ld d, 0x1:opc
	pushw wa
	pushw de
	push xhl
	call SwbtWr_QueuePostEvent
	pop xhl
	popw de
	popw wa
	ld a, (xiy + 0:8)
	and a, 0xff
	ld w, 0xff:opc
	ld d, 0x0:opc
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
AccVoiceState_DispatchChange_Data:
	.byte 0x00, 0x00, 0x00, 0x00, 0x6a, 0xff, 0x00, 0x00
	.byte 0x56, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x1a, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x2e, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x42, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 56

AccVoiceDelta_Part1:
	ld a, (0xfbbe:16)
	ld w, (0xfbbf:16)
	and w, 0x7f
	cp (0x3395:16), wa
	jr z, AccVoiceDelta_Part1_Store
	and a, 0xf
	ld (xiy + 0:8), a
	andmi8 (xiy + 1), 0x80
	or (xiy + 1), w
	or a, 0xf0
	or (0x3393:16), 1

AccVoiceDelta_Part1_Store:
	ld (0x3395:16), wa
	ret

AccVoiceDelta_Part2:
	ld a, (0xfba4:16)
	ld w, (0xfba5:16)
	and w, 0x7f
	ld l, (0xfba8:16)
	and l, 0x40
	sla l, 1
	or w, l
	cp (0x3397:16), wa
	jr z, AccVoiceDelta_Part2_Store
	ld (xiy + 2), a
	andmi8 (xiy + 3), 0x0
	or (xiy + 3), w
	or (0x3393:16), 1

AccVoiceDelta_Part2_Store:
	ld (0x3397:16), wa
	ret

AccVoiceDelta_Part3:
	ld a, (0xfb56:16)
	ld w, (0xfb57:16)
	and w, 0x7f
	ld l, (0xfb5a:16)
	and l, 0x40
	sla l, 1
	or w, l
	cp (0x3399:16), wa
	jr z, AccVoiceDelta_Part3_Store
	ld (xiy + 4), a
	andmi8 (xiy + 5), 0x0
	or (xiy + 5), w
	or (0x3393:16), 1

AccVoiceDelta_Part3_Store:
	ld (0x3399:16), wa
	ret

AccVoiceDelta_Part4:
	ld a, (0xfb70:16)
	ld w, (0xfb71:16)
	and w, 0x7f
	ld l, (0xfb74:16)
	and l, 0x40
	sla l, 1
	or w, l
	cp (0x339b:16), wa
	jr z, AccVoiceDelta_Part4_Store
	ld (xiy + 6), a
	andmi8 (xiy + 7), 0x0
	or (xiy + 7), w
	or (0x3393:16), 1

AccVoiceDelta_Part4_Store:
	ld (0x339b:16), wa
	ret

AccVoiceDelta_Part5:
	ld a, (0xfb8a:16)
	ld w, (0xfb8b:16)
	and w, 0x7f
	ld l, (0xfb8e:16)
	and l, 0x40
	sla l, 1
	or w, l
	cp (0x339d:16), wa
	jr z, AccVoiceDelta_Part5_Store
	ld (xiy + 8), a
	andmi8 (xiy + 9), 0x0
	or (xiy + 9), w
	or (0x3393:16), 1

AccVoiceDelta_Part5_Store:
	ld (0x339d:16), wa
	ret

AccStyle_InitVRAM:
	xor a, a
	ld xiy, AccStyle_RamImage_1E7800
	ld xix, 0x1e7800
	ldw bc, 0x7e0
	ldir85
	ret

AccStyle_SC0ByteSelect:
	.long Pad_AfterBitmap_Dredt0k_2
	rcf
	ld	a, (0x338e:16)
	and	a, 31
	jr	nz, AccStyle_SC0ByteSelect_Code_Skip
	ld	(0xe3de:16), 16
AccStyle_SC0ByteSelect_Code_Skip:
	ld	(0x338e:16), 1
	ret
AccStyle_SC0ByteSelect_Join:
	ld	(0xe3e0:16), 16
	ld	a, (0x338e:16)
	and	a, 31
	jr	nz, AccStyle_SC0ByteSelect_Code_Skip2
	ld	(0xe3de:16), 16
AccStyle_SC0ByteSelect_Code_Skip2:
	ld	(0x338e:16), 16
	ret
AccStyle_SC0ByteSelect_Join2:
	ld	(0xe3e0:16), 16
	ld	a, (0x338e:16)
	and	a, 31
	jr	nz, AccStyle_SC0ByteSelect_Code_Skip3
	.long Pad_AfterBitmap_Dredt0k
	rcf
AccStyle_SC0ByteSelect_Code_Skip3:
	ld	(0x338e:16), 8
	ret
AccStyle_SC0ByteSelect_Join3:
	ld	(0xe3e0:16), 16
	ld	a, (0x338e:16)
	and	a, 31
	jr	nz, AccStyle_SC0ByteSelect_Code_Skip4
	ld	(0xe3de:16), 16
AccStyle_SC0ByteSelect_Code_Skip4:
	ld	(0x338e:16), 4
	ret
AccStyle_SC0ByteSelect_Join4:
	ld	(0xe3e0:16), 16
	ld	a, (0x338e:16)
	and	a, 31
	jr	nz, AccStyle_SC0ByteSelect_Code_Skip5
	ld	(0xe3de:16), 16
AccStyle_SC0ByteSelect_Code_Skip5:
	ld	(0x338e:16), 2
	ret

AccHelper_ComputeVoiceOffset:
	xor xwa, xwa
	ld l, (0xfc5a:16)
	ld h, (0xfc5b:16)
	and h, 0x7
	ld (0x90f7:16), 72
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
	ldw (0x34d4:16), 190
	and (0x32f3:16), 254
	bit 7, (0x34d1:16)
	jr nz, AccDemo_Init_ConfigTimers
	call AccWidget_DispatchTable

AccDemo_Init_ConfigTimers:
	and (0x34d1:16), 127
	ld (0x39b6:16), 0
	ld (0x39b7:16), 10
	ret

AccDemo_Init_DataBlock:
	nop
	nop
	ld	xix, RHYTHM_PATTERN_BUF_A
	ld	(xix+2976), 0
	ld	(xix+2977), 1
	ld	(xix+2978), 2
	ld	(xix+2979), 3
	ret

AccDemo_LoadRhythm:
	ld xiy, Demo_StyleRhythmData
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x0
	ldw bc, 0x60
	ldir85
	ret

AccDemo_LoadVariation:
	ld a, 0x0:opc
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x60
	ld hl, 0:i3

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
	ld xiy, AccDemo_LoadVariation_EntryLoop_Data_2
	ldw bc, 0x34
	ldir85
	ld xiy, AccDemo_LoadVariation_EntryLoop_Data
	xor xde, xde
	ld e, a
	mul e, 0x10
	add xiy, xde
	ldw bc, 0x10
	ldir85
	ld xiy, AccDemo_SectionRecordTail
	ldw bc, 0x10
	ldir85
	add a, 0x1
	cp a, 0x1e
	jr lt, AccDemo_LoadVariation_EntryLoop
	ret

AccDemo_LoadVariation_DataBlock:
	ld	xiy, AccDemo_LoadVariation_DataBlock_Data
	ld	xix, RHYTHM_PATTERN_BUF_A
	add	xix, 2976
	ldw	bc, 160
	ldir85
	ret
	ld	xwa, 0:i3
	ld	xix, RHYTHM_PATTERN_BUF_A
	add	xix, 3136
	ld	xde, 0:i3
AccDemo_LoadVariation_Loop:
	ld qde, 6
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
	jr	lt, AccDemo_LoadVariation_Loop
	ret

AccDemo_LoadFillIn:
	ldw bc, 0x40
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x13c0
	ld xiy, AccDemo_LoadFillIn_Data
	ldir85
	ret

AccDemo_LoadVariationData:
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x1400
	ld a, 0x1e:opc

Demo_LoadVariationData:
	ld xiy, Demo_LoadVariationData_Data
	ldw bc, 0x100
	ldir85
	ld l, 0x4:opc

Demo_LoadVariationData_Inner:
	ld xiy, Demo_LoadVariationData_Inner_Data
	ldw bc, 0x100
	ldir85
	dec 1, l
	cp l, 0:i3
	jr gt, Demo_LoadVariationData_Inner
	dec 1, a
	cp a, 0:i3
	jr nz, Demo_LoadVariationData
	ret

Demo_LoadVariationC_Data:
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0xaa00
	ld a, 0xbe:opc

Demo_LoadVariationC_Loop:
	ld xiy, Demo_LoadVariationData_Inner_Data_2
	ldw bc, 0x100
	ldir85
	dec 1, a
	cp a, 0:i3
	jr nz, Demo_LoadVariationC_Loop
	ret

Demo_StyleRhythmData:
; Demo_StyleRhythmData -- the built-in DEMO/DEFAULT STYLE image, 0x674 (1,652) bytes.
; ** RE-TYPED 2026-09-25 (lane accomp): was disassembled as instructions
; (popw/nop/pop xde/push sr/swi 7/`jr f,0`/cpd ... -- 69 data-as-code markers in
; v10 alone).  It is DATA: nothing branches into it, and six copy loops read it
; with fixed offsets and lengths, which pin every segment below:
;   AccDemo_LoadRhythm           +0x000, 0x60 B      -> 0x94800+0x0000
;   AccDemo_LoadVariation        +0x060 + a*16, 16 B -> section record a (a=0..29)
;                                +0x240, 0x34 B      -> every section record
;                                +0x57C, 16 B        -> every section record
;   AccDemo_LoadVariation_DataBlock +0x274, 160 B    -> 0x94800+2976
;   AccDemo_LoadFillIn           +0x334, 0x40 B      -> 0x94800+0x13C0
;   Demo_LoadVariationData       +0x374, 0x100 B x30 and +0x474, 0x100 B x4 x30
;                                                    -> 0x94800+0x1400..
;   Demo_LoadVariationC_Data     +0x574, 0x100 B x190 -> 0x94800+0xAA00
; 0x94800 is also the base AccPatch_InitSlotChain_WithAddr stores to (0x39ae), so
; this is the style image the AccDemo_* loaders build in that RAM area.  The one
; interior offset a reader names by itself, +0x57C, is AccDemo_SectionRecordTail.
; 30 section names: AccDemo_LoadVariation's loop bound is `cp a, 0x1e`, and the
; order (A/B/C variation 1-4, then intro/fill-in/ending 1-2 per variation) is the
; order of the 30 seven-byte section-name cells in AccScreen_UIDataBlock.
; readers in v9/v10 (address from the linked ELF): AccDemo_LoadRhythm 0xF5CE7A,
;     AccDemo_LoadVariation 0xF5CE90, AccDemo_LoadVariation_DataBlock 0xF5CEF3,
;     AccDemo_LoadFillIn 0xF5CF68, Demo_LoadVariationData 0xF5CF8B,
;     Demo_LoadVariationC_Data 0xF5CFAE
; -- comments that sat inside this range before the re-type, in order:
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5D20D-0xF5D230 (35 B), unreached CODE-territory, was disassembled as 22 plausible-but-dead instruction lines; per=63% dist=10 near AccDemo_LoadVariation_EntryLoop_Data_2+1
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5D2E1-0xF5D300 (31 B), unreached CODE-territory, was disassembled as 23 plausible-but-dead instruction lines; per=100% dist=2 near AccDemo_LoadVariation_DataBlock_Data+161
; +0x000  0x60 B  -- AccDemo_LoadRhythm copies all 0x60 bytes to 0x94800+0x0000.
	.byte 0x48, 0x00, 0x4b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5a, 0x5a, 0x5a, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x00, 0x80, 0x16
	.byte 0x60, 0x00, 0x60, 0x00, 0x1e, 0x00, 0x00, 0x01, 0x54, 0x01, 0x40, 0x00, 0x00, 0x00, 0x80, 0x16
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x060  30 x 16 B  section names, one per accompaniment section in the
;                 order of AccScreen's section-name table (A/B/C variation 1-4,
;                 then intro/fill/ending per variation).  AccDemo_LoadVariation
;                 copies entry a*16 (a = 0..29) into each section record.
AccDemo_LoadVariation_EntryLoop_Data:
	.ascii "a-variation1    "
	.ascii "a-variation2    "
	.ascii "a-variation3    "
	.ascii "a-variation4    "
	.ascii "b-variation1    "
	.ascii "b-variation2    "
	.ascii "b-variation3    "
	.ascii "b-variation4    "
	.ascii "c-variation1    "
	.ascii "c-variation2    "
	.ascii "c-variation3    "
	.ascii "c-variation4    "
	.ascii " a-intro 1      "
	.ascii " a-intro 2      "
	.ascii " a-fill in 1    "
	.ascii " a-fill in 2    "
	.ascii " a-ending 1     "
	.ascii " a-ending 2     "
	.ascii " b-intro 1      "
	.ascii " b-intro 2      "
	.ascii " b-fill in 1    "
	.ascii " b-fill in 2    "
	.ascii " b-ending 1     "
	.ascii " b-ending 2     "
	.ascii " c-intro 1      "
	.ascii " c-intro 2      "
	.ascii " c-fill in 1    "
	.ascii " c-fill in 2    "
	.ascii " c-ending 1     "
	.ascii " c-ending 2     "
; +0x240  0x34 B  per-section record body -- AccDemo_LoadVariation copies these
;                 52 bytes into every one of the 30 section records.
AccDemo_LoadVariation_EntryLoop_Data_2:
	.byte 0x07, 0x03, 0x20, 0x00, 0x58, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x40, 0x00, 0x50, 0x00, 0x7f, 0x00, 0x28, 0x00, 0x40, 0x00, 0x50, 0x06
	.byte 0x7f, 0x00, 0x00, 0x00, 0x40, 0x00, 0x50, 0x06, 0x7f, 0x00, 0x1c, 0x00, 0x40
	.byte 0x00, 0x50, 0x06, 0x7f, 0x00, 0x1d, 0x00, 0x40, 0x00, 0x50, 0x06, 0x7f, 0x00
; +0x274  5 x 32 B  chord-map records -- AccDemo_LoadVariation_DataBlock copies
;                 these 160 bytes to 0x94800+2976.  Each record: index byte (0..4),
;                 three 0xFF, twelve zero bytes, a 16-character name.
AccDemo_LoadVariation_DataBlock_Data:
	.byte 0x00, 0xff, 0xff, 0xff
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
	.ascii "chord map 5     "
; +0x314  32 B    eight 4-byte groups 00 00 06 00.  None of the six copy loops
;                 covers these bytes: reader not established.
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
	.byte 0x00, 0x00, 0x06, 0x00
; +0x334  0x40 B  -- AccDemo_LoadFillIn copies all 64 bytes to 0x94800+0x13C0.
AccDemo_LoadFillIn_Data:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0x83, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x87
; +0x374  0x100 B -- Demo_LoadVariationData copies it once per section (30x),
;                 the first of five 0x100-byte copies per section from 0x94800+0x1400.
Demo_LoadVariationData_Data:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87, 0x90, 0x00, 0x43, 0x58, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43
	.byte 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03
	.byte 0x00, 0x81, 0x90, 0x00, 0x43, 0x58, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81
	.byte 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00
	.byte 0x43, 0x58, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40
	.byte 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x58, 0x03, 0x00
	.byte 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90, 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x90
	.byte 0x00, 0x43, 0x40, 0x03, 0x00, 0x81, 0x83
	.zero 136
	.byte 0x87
; +0x474  0x100 B -- Demo_LoadVariationData_Inner copies it 4x after each copy of
;                 the block above (1 + 4 = 5 x 0x100 per section).
Demo_LoadVariationData_Inner_Data:
	.byte 0x80, 0xff, 0xff, 0xff, 0xff, 0x87
	.fill 16, 1, 0x81
	.byte 0x83
	.zero 232
	.byte 0x87
; +0x574  0x100 B -- Demo_LoadVariationC_Loop copies it 0xBE (190) times to
;                 0x94800+0xAA00.  AccDemo_LoadVariation also reads 16 bytes of it
;                 at +0x57C (AccDemo_SectionRecordTail) into every section record.
Demo_LoadVariationData_Inner_Data_2:
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0x87
	.zero 2
; the 16 bytes AccDemo_LoadVariation copies into every section record (+0x57C of the image; all zero)
AccDemo_SectionRecordTail:
	.zero 247
	.byte 0x87

AccTone_LookupByProgram:
	sub a, 0xf0
	extz wa
	sla wa, 2
	lda xbc, (AccTone_LookupByProgram_Table_2:24)
	ld	xde, (xbc+wa)
	ld a, (xde)
	extz wa
	sla wa, 2
	lda xbc, (RhythmTiming_OffsetTable:24)
	ld xde, 0x94860
	add	xde, (xbc+wa)
	ld a, (xde + 12)
	extz wa
	lda xbc, (AccTone_LookupByProgram_Table:24)
	ld	l, (xbc+wa)
	ret

AccTone_ReadAndProcess:
	dec 4, xsp
	lda xbc, (0xfc5a:16)
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
	lda xbc, (AccTone_LookupByProgram_Table_2:24)
	ld	xwa, (xbc+wa)
	ld e, (xwa)
	extz de
	ld wa, de
	ld bc, 0:i3

AccTone_Process_CalcResult:
	calr AccTone_ExtendAndDispatch

AccTone_Process_Cleanup:
	inc 4, xsp
	ret

AccTone_NoteLookup:
	ldfr_berp A, 0xf4
	extz iy
	ld de, (4360:16)
	ld ix, de
	and ix, 0x4
	lda xhl, (AccTone_NoteLookup_Table:24)
	ld a, c
	add a, c
	mul iy, 0x28
	ld c, a
	extz bc
	ld wa, iy
	add wa, bc
	cp ix, 4:i3
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
	ld l, 0x0:opc
	cp de, 0x8
	ret nz
	ld l, 0x1:opc

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
	lda xde, (AccTone_ExtendAndDispatch_Body_Table_2:24)
	ld	xiy, (xde+bc)
	ld e, a
	extz de
	ld wa, de
	sla wa, 2
	lda xix, (RhythmTiming_OffsetTable:24)
	ld xiz, xiy
	add	xiz, (xix+wa)
	ld a, (xiz + 12)
	extz wa
	lda xhl, (AccTone_LookupByProgram_Table:24)
	ld	a, (xhl+wa)
	ldfr_berp A, 0xe2
	lda xiz, (AccTone_ExtendAndDispatch_Body_Table:24)
	ld	xbc, (xiz+bc)
	add de, 0x11
	ld	c, (xbc+de)
	ld wa, (4360:16)
	ld de, wa
	and de, 0x4
	extz bc
	cp de, 4:i3
	jr nz, AccTone_CheckBit10Flag
	lda xde, (AccTone_ExtendAndDispatch_Body_Table_3:24)
	ld	a, (xde+bc)
	extz wa
	sla wa, 2
	ld xiz, xiy
	add	xiz, (xix+wa)
	ld c, (xiz + 12)
	extz bc
	ldto_berp A, 0xe2
	cp	a, (xhl+bc)
	jr z, AccTone_FoundMatch_IncRet

AccTone_SetupExit:
	ld l, 0x0:opc

AccTone_ExtendAndDispatch_PopRet:
	pop xiz
	ret

AccTone_CheckBit10Flag:
	ld de, wa
	and de, 0x400
	cp de, 0x400
	jr nz, AccTone_CheckBit3Flag
	lda xde, (AccTone_ExtendAndDispatch_PopRet_Table:24)
	ld	a, (xde+bc)
	extz wa
	sla wa, 2
	ld xiz, xiy
	add	xiz, (xix+wa)
	ld c, (xiz + 12)
	extz bc
	ldto_berp A, 0xe2
	cp	a, (xhl+bc)
	jr nz, AccTone_SetupExit

AccTone_FoundMatch_IncRet:
	ld l, (xiz + 13)
	inc 1, l
	jr AccTone_ExtendAndDispatch_PopRet

AccTone_CheckBit3Flag:
	and wa, 0x8
	cp wa, 0x8
	jr nz, AccTone_SetupExit
	ldto_berp A, 0xe2
	extz wa
	lda xbc, (AccStyle_ApplyExt_SkipClamp_Table:24)
	bit	0, (xbc+wa)
	jr nz, AccTone_SetupExit
	ld l, 0x1:opc
	jr AccTone_ExtendAndDispatch_PopRet
	dec 4, xsp
	ld de, (4360:16)
	and de, 0x40c
	jrl z, AccTone_LookupFailed
	extz bc
	sla bc, 2
	lda xde, (AccTone_ExtendAndDispatch_Body_Table_2:24)
	ld	xde, (xde+bc)
	extz wa
	sla wa, 2
	lda xbc, (RhythmTiming_OffsetTable:24)
	add	xde, (xbc+wa)
	ld a, (xde + 12)
	extz wa
	lda xbc, (AccTone_LookupByProgram_Table:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (AccStyle_ApplyExt_SkipClamp_Table:24)
	bit	0, (xbc+wa)
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
	ld a, (0x32ff:16)
	cp a, 1:i3
	jr z, AccTone_DirectAddr_Mode1
	cp a, 2:i3
	jr z, AccTone_DirectAddr_Mode2

AccTone_DirectAddr_Mode1:
	ld l, 0x2:opc
	jr AccTone_LookupDone

AccTone_DirectAddr_Mode2:
	ld l, 0x1:opc
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
	ld l, 0x0:opc

AccTone_LookupDone:
	inc 4, xsp
	ret

AccTone_InlineBytecodeData:
	res	0, (0x341f:16)
	cp	(13079:16), 0
	scc	z, bc
	cp	(13078:16), 0
	scc	z, de
	and	de, bc
	cp	(13080:16), 0
	scc	z, bc
	and	bc, de
	cp	(13074:16), 0
	scc	z, de
	and	de, bc
	cp	(13075:16), 0
	scc	z, bc
	and	bc, de
	cp	(13076:16), 0
	scc	z, de
	and	de, bc
	cp	(13077:16), 0
	scc	z, wa
	and	wa, de
	ret	z
	cp	(13029:16), 240
	ret	c
	ld	a, (12928:16)
	cp	a, (13349:16)
	jr	z, AccTone_InlineBytecodeData_Skip
	res	0, (0x341e:16)
AccTone_InlineBytecodeData_Skip:
	bit	0, (0x341e:16)
	ret	nz
	calr	AccTone_InlineBytecodeData_Code_Helper
	ld	a, (13345:16)
	cp	a, (13354:16)
	jr	z, AccTone_InlineBytecodeData_Skip2
	set	0, (0x341f:16)
	set	0, (0x341e:16)
AccTone_InlineBytecodeData_Skip2:
	ldmm8	13345, 13354
	ldmm8	13344, 13355
	ret
AccTone_InlineBytecodeData_Code_Helper:
	ld	a, (13016:16)
	extz	wa
	lda	xbc, (AccTuning_ReadAndApplyOffset_Table:24)
	ld	a, (xbc+wa)
	ld	(13355:16), a
	ld	xbc, (13006:16)
	extz	wa
	ld	a, (xbc+wa)
	ld	(13354:16), a
	cp	a, 255
	ret	nz
	.byte 0x81, 0x19, 0x2a, 0x34
	ld	(13355:16), 0
	ret
AccTone_JumpTableData_Data:
	.byte 0xf1, 0x1f, 0x34, 0xc8
	ret	z
	call	Rhythm_SendChanPressure_Wrap
	call	AccBuf_ResetAll4_Wrap
	ld	a, (13345:16)
	extz	wa
	sla	wa, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xbc, 608352
	add	xbc, (xde+wa)
	ld	(13350:16), xbc
	ld	xwa, xbc
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	set	7, (0x332c:16)
	calr	AccTone_InlineBytecodeData_Code_Helper2
	ldmm8	13023, 13016
	ldmm8	13024, 13017
	ldmm8	13025, 13018
	res	0, (0x341f:16)
	ret
AccTone_InlineBytecodeData_Code_Helper2:
	calr	AccVoice_BarCounterBytecodeData
	and	(0x32ab:16), 240
	and	(0x32ac:16), 240
	and	(0x32ad:16), 240
	and	(0x32ae:16), 240
	and	(0x32af:16), 240
	and	(0x32b0:16), 240
	call	AccSeq_DualPartScan_Wrap
	bit	6, (0x32f4:16)
	ret	nz
	call	AccSeq_FourChannelScan_Wrap
	ret
AccVoice_BarCounterBytecodeData_Helper:
	extz	de
	sla	de, 2
	extz	bc
	sla	bc, 5
	ld	hl, bc
	add	hl, de
	ld	w, 0:opc
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ld	hl, (xbc+hl)
	ret
AccVoice_BarCounterBytecodeData_Helper2:
	extz	de
	sla	de, 2
	extz	bc
	sla	bc, 5
	ld	hl, bc
	add	hl, de
	ld	w, 0:opc
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+hl)
	ld	hl, (xwa+2)
	ret
AccTone_JumpTableData_Helper:
	dec	2, xsp
	push	xiz
	ld	a, (13029:16)
	sub	a, 240
	extz	wa
	sla	wa, 2
	lda	xbc, (AccTone_LookupByProgram_Table_2:24)
	ld	xwa, (xbc+wa)
	ld	(13006:16), xwa
	ld	a, (xwa)
	ld	(13297:16), a
	extz	wa
	lda	xbc, (AccStyle_ExtStyleMap:24)
	ld	(13112), (xbc+wa)
	ld	bc, wa
	sla	bc, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xwa, 608352
	add	xwa, (xde+bc)
	ld	(13298:16), xwa
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
	jr	z, AccTone_InlineBytecodeData_Code_Skip
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccTone_InlineBytecodeData_Code_Skip:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xwa, xhl
	call	Rhythm_UpdateTuningConfig_Wrap
	ld	a, (xiz+12)
	extz	wa
	lda	xbc, (AccTone_LookupByProgram_Table:24)
	ld	(1075), (xbc+wa)
	ld	a, (1075:16)
	extz	wa
	add	wa, wa
	lda	xbc, (AccVoice_LookupTableAddress_Table:24)
	ldw	(12923), (xbc+wa)
	ld	a, (13297:16)
	add	a, 128
	ld	(13356:16), a
	extz	wa
	call	AccPatch_SetByChordIndex_Wrap
	calr	AccTone_InlineBytecodeData_Code_Helper
	ld	a, (13354:16)
	ld	(13345:16), a
	ldmm8	13344, 13355
	ld	a, (13354:16)
	extz	wa
	sla	wa, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xbc, 608352
	add	xbc, (xde+wa)
	ld	(13350:16), xbc
	ld	xwa, xbc
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccTone_JumpTableData_Helper2:
	cp	(13029:16), 240
	ret	c
	calr	AccTone_InlineBytecodeData_Code_Helper
	ld	a, (13354:16)
	cp	a, (13345:16)
	ret	z
	.byte 0xf1, 0x3b, 0x33, 0xb8
	ret
AccTone_JumpTableData_Helper3:
	dec	2, xsp
	push	xiz
	ld	a, (13029:16)
	sub	a, 240
	extz	wa
	sla	wa, 2
	lda	xbc, (AccTone_LookupByProgram_Table_2:24)
	ld	xwa, (xbc+wa)
	ld	(13006:16), xwa
	ld	a, (xwa)
	ld	(13297:16), a
	extz	wa
	lda	xbc, (AccStyle_ExtStyleMap:24)
	ld	(13112), (xbc+wa)
	ld	bc, wa
	sla	bc, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xwa, 608352
	add	xwa, (xde+bc)
	ld	(13298:16), xwa
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
	jr	z, AccTone_InlineBytecodeData_Code_Skip2
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccTone_InlineBytecodeData_Code_Skip2:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xwa, xhl
	call	Rhythm_UpdateTuningConfig_Wrap
	ld	a, (xiz+12)
	extz	wa
	lda	xbc, (AccTone_LookupByProgram_Table:24)
	ld	(1075), (xbc+wa)
	ld	a, (1075:16)
	extz	wa
	add	wa, wa
	lda	xbc, (AccVoice_LookupTableAddress_Table:24)
	ldw	(12923), (xbc+wa)
	ld	a, (13297:16)
	add	a, 128
	ld	(13356:16), a
	extz	wa
	call	AccPatch_SetByChordIndex_Wrap
	calr	AccTone_InlineBytecodeData_Code_Helper
	ldmm8	13345, 13354
	ldmm8	13344, 13355
	bit	0, (0x3363:16)
	call	z, (0xf5e768:24)
	ld	c, (13345:16)
	extz	bc
	sla	bc, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xwa, 608352
	add	xwa, (xde+bc)
	ld	(13350:16), xwa
	calr	AccTone_InlineBytecodeData_Code_Helper3
	pop	xiz
	inc	2, xsp
	ret
AccTone_InlineBytecodeData_Code_Helper3:
	ld	c, (13055:16)
	ld	a, c
	and	a, 7
	jr	z, AccTone_InlineBytecodeData_Code_Entry
	bit	0, (0x3363:16)
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip
	cp	c, 1:i3
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip2
	cp	c, 4:i3
	jr	z, AccTone_InlineBytecodeData_Code_Entry2
	cp	c, 2:i3
	jr	nz, AccTone_InlineBytecodeData_Code_Helper3_Skip2
	ld	a, (1075:16)
	extz	wa
	lda	xbc, (AccStyle_ApplyExt_SkipClamp_Table:24)
	cp	(xbc+wa), 0x01
	jr	nz, AccTone_InlineBytecodeData_Code_Helper3_Skip
	calr AccTone_InlineBytecodeData_Code_Helper3_Helper
AccTone_InlineBytecodeData_Code_Entry:
	jr	AccTone_InlineBytecodeData_Code_Helper3_Join
AccTone_InlineBytecodeData_Code_Helper3_Skip:
	jr	AccTone_InlineBytecodeData_Code_Helper3_Join2
AccTone_InlineBytecodeData_Code_Entry2:
	ld	a, (0x433:16)
	cp	a, (0x3366:16)
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip3
	calr	AccTone_InlineBytecodeData_Code_Helper3_Helper3
	jr	AccTone_InlineBytecodeData_Code_Entry
AccTone_InlineBytecodeData_Code_Helper3_Skip2:
	ld	a, (0x433:16)
	cp	a, (0x3364:16)
	jr	nz, AccTone_InlineBytecodeData_Code_Helper3_Skip4
AccTone_InlineBytecodeData_Code_Helper3_Skip3:
	jp	AccTone_LookupByProgramWrapped_Join
AccTone_InlineBytecodeData_Code_Helper3_Skip4:
	calr	AccTone_InlineBytecodeData_Code_Helper3_Helper2
	jr	AccTone_InlineBytecodeData_Code_Entry
AccTone_InlineBytecodeData_Code_Helper3_Join:
	ld	xwa, (0x3426:16)
	call	AccPart_InitPositionsAndBase_Wrap
	ld	xwa, (0x3426:16)
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	and	(0x3316:16), 192
	and	(0x3317:16), 192
	and	(0x3318:16), 192
	ret
AccTone_InlineBytecodeData_Code_Helper3_Join2:
	dec	2, xsp
	pushw	iz
	ld	a, (0x32ff:16)
	cp	a, 4:i3
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip5
	cp	a, 2:i3
	jr	nz, AccTone_InlineBytecodeData_Code_Helper3_Skip6
	ldw	iz, 34
	jr	AccTone_InlineBytecodeData_Code_Helper3_Join3
AccTone_InlineBytecodeData_Code_Helper3_Skip5:
	ldw	iz, 1056
	jr	AccTone_InlineBytecodeData_Code_Helper3_Join3
AccTone_InlineBytecodeData_Code_Helper3_Skip6:
	ldw	iz, 32
AccTone_InlineBytecodeData_Code_Helper3_Join3:
	ld	xde, (0x33f2:16)
	lda	xwa, (xsp+2)
	ld	c, (xde+16)
	ld	(xwa), c
	ld	e, (xde+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip7
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccTone_InlineBytecodeData_Code_Helper3_Skip7:
	lda	xbc, (xsp+2)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xwa, xhl
	ld	bc, iz
	call	AccStyle_SetupPartAddressesByHL_Wrap
	ld	xwa, (0x33f2:16)
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	ld	a, (0x32ff:16)
	cp	a, 4:i3
	jr	z, AccTone_InlineBytecodeData_Code_Helper3_Skip8
	cp	a, 2:i3
	jr	nz, AccTone_InlineBytecodeData_Code_Helper3_Skip9
	and	(0x3316:16), 192
	or	(0x3317:16), 63
	jr	AccTone_InlineBytecodeData_Code_Helper3_Join4
AccTone_InlineBytecodeData_Code_Helper3_Skip8:
	and	(0x3316:16), 192
	and	(0x3317:16), 192
	or	(0x3318:16), 63
	jr	AccTone_InlineBytecodeData_Code_Helper3_Epilogue
AccTone_InlineBytecodeData_Code_Helper3_Skip9:
	or	(0x3316:16), 63
	and	(0x3317:16), 192
AccTone_InlineBytecodeData_Code_Helper3_Join4:
	and	(0x3318:16), 192
AccTone_InlineBytecodeData_Code_Helper3_Epilogue:
	popw	iz
	inc	2, xsp
	ret
AccTone_InlineBytecodeData_Code_Helper3_Helper:
	res	1, (0x32ff:16)
	res	3, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccTone_InlineBytecodeData_Code_Helper3_Helper2:
	res	0, (0x32ff:16)
	res	2, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccTone_InlineBytecodeData_Code_Helper3_Helper3:
	res	2, (0x32ff:16)
	res	2, (0xfc60:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 6:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper8:
	res	0, (0x32fd:16)
	res	4, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper9:
	res	1, (0x32fd:16)
	res	5, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper3:
	res	0, (0x32fb:16)
	res	6, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper10:
	res	1, (0x32fb:16)
	res	7, (0xfc5f:16)
	pushw	0
	ldw	wa, 72
	ld	bc, 5:i3
	ld	de, 0:i3
	call	AddswbWr
	ret
AccPedal_DirectionA_Wrap_Helper:
	cp	a, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Helper3_Skip
	ldw	(0x33d6:16), 65534
	jr	AccVoice_BarCounterBytecodeData_Helper3_Join
AccVoice_BarCounterBytecodeData_Helper3_Skip:
	extz	wa
	lda	xbc, (AccTone_InlineBytecodeData_Data:24)
	ld	a, (xbc+wa)
	ld	xbc, (0x3426:16)
	extz	wa
	add	wa, wa
	ldw	(13270), (xbc+wa)
AccVoice_BarCounterBytecodeData_Helper3_Join:
	ldw	(0x33d8:16), 6
	ret
AccPedal_DirectionA_Wrap_Helper2:
	ld	xix, (0x3426:16)
	ld	c, a
	extz	bc
	lda	xde, (AccTone_InlineBytecodeData_Data_2:24)
	ld	e, (xde+bc)
	extz	de
	ld	bc, de
	muls	bc, 7
	lda	xhl, (0x3246:16)
	lda	xhl, (xhl+bc)
	sla	de, 3
	add	de, 24
	exts	xde
	add	xde, xix
	ld	c, (xde)
	ld	(xhl), c
	ld	c, (xde+1)
	ld	(xhl+1), c
	ld	c, (xde+2)
	ld	(xhl+2), c
	ld	c, (xde+3)
	ld	(xhl+3), c
	ld	c, (xde+4)
	ld	(xhl+4), c
	ld	c, (xde+5)
	ld	(xhl+5), c
	ld	c, (xde+6)
	ld	(xhl+6), c
	or	(0x332c:16), a
	ret
AccVoice_ClearChannelStates:
	ld (0x33eb:16), 0
	ld (0x33ec:16), 0
	ld (0x33ed:16), 0
	ld (0x33ee:16), 0
	ld (0x33ef:16), 0
	ld (0x33f0:16), 0
	ret

AccVoice_IncrementBarCounter:
	ld a, (0x33ea:16)
	inc 1, a
	ld (0x33ea:16), a
	ld xbc, (0x3426:16)
	cp a, (xbc + 13)
	ret ule
	ld (0x33ea:16), 0
	ret
AccVoice_BarCounterBytecodeData:
	ld	(13280:16), 0
	ld	a, (13345:16)
	extz	wa
	ld	e, (13291:16)
	extz	de
	ld	bc, 0:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(12951:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip
	set	0, (0x33e0:16)
AccVoice_BarCounterBytecodeData_Skip:
	ld	a, (13345:16)
	extz	wa
	ld	e, (13291:16)
	extz	de
	ld	bc, 0:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(12935:16), hl
	ld	a, (13345:16)
	extz	wa
	ld	e, (13293:16)
	extz	de
	ld	bc, 1:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(12955:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip2
	set	2, (0x33e0:16)
AccVoice_BarCounterBytecodeData_Skip2:
	ld	a, (13345:16)
	extz	wa
	ld	e, (13293:16)
	extz	de
	ld	bc, 1:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(12939:16), hl
	ld	a, (13345:16)
	extz	wa
	ld	e, (13294:16)
	extz	de
	ld	bc, 2:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(12957:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip3
	set	3, (0x33e0:16)
AccVoice_BarCounterBytecodeData_Skip3:
	ld	a, (13345:16)
	extz	wa
	ld	e, (13294:16)
	extz	de
	ld	bc, 2:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(12941:16), hl
	ld	a, (13345:16)
	extz	wa
	ld	e, (13295:16)
	extz	de
	ld	bc, 3:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(12959:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip4
	set	4, (0x33e0:16)
AccVoice_BarCounterBytecodeData_Skip4:
	ld	a, (13345:16)
	extz	wa
	ld	e, (13295:16)
	extz	de
	ld	bc, 3:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(12943:16), hl
	ld	a, (13345:16)
	extz	wa
	ld	e, (13296:16)
	extz	de
	ld	bc, 4:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(12961:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip5
	set	5, (0x33e0:16)
AccVoice_BarCounterBytecodeData_Skip5:
	ld	a, (13345:16)
	extz	wa
	ld	e, (13296:16)
	extz	de
	ld	bc, 4:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(12945:16), hl
	ldw	(12953:16), 65534
	ldw	(12937:16), 6
	set	1, (0x33e0:16)
	ret
AccVoice_IncrementBarWithSave_Helper:
	dec	2, xsp
	push	xiz
	lda	xbc, (RhythmTiming_OffsetTable:24)
	bit	0, (0x3363:16)
	jr	z, AccVoice_BarCounterBytecodeData_Skip9
	ld	a, (13067:16)
	cp	a, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip7
	cp	a, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Skip7
	ld	a, (1075:16)
	cp	a, (13166:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip6
	ld	a, (13167:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip6:
	calr	AccVoice_BarCounterBytecodeData_Helper9
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jrl	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip7:
	ld	a, (1075:16)
	cp	a, (13164:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip8
	ld	a, (13165:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip8:
	calr	AccVoice_BarCounterBytecodeData_Helper8
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jr	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip9:
	ld	xde, (13298:16)
	lda	xwa, (xsp+4)
	ld	c, (xde+16)
	ld	(xwa), c
	ld	e, (xde+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, AccVoice_BarCounterBytecodeData_Skip10
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccVoice_BarCounterBytecodeData_Skip10:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xwa, xhl
	ld	c, (13067:16)
	cp	c, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip11
	cp	c, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Skip11
	ldw	bc, 1060
	jr	AccVoice_BarCounterBytecodeData_Join
AccVoice_BarCounterBytecodeData_Skip11:
	ldw	bc, 36
AccVoice_BarCounterBytecodeData_Join:
	call	AccVoice_LoadAllParts_Wrap
	ld	xwa, (13298:16)
AccVoice_BarCounterBytecodeData_Join2:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccVoice_IncrementBarWithSave_Helper2:
	dec	2, xsp
	push	xiz
	lda	xbc, (RhythmTiming_OffsetTable:24)
	bit	0, (0x3363:16)
	jr	z, AccVoice_BarCounterBytecodeData_Skip15
	ld	a, (13065:16)
	cp	a, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip13
	cp	a, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Skip13
	ld	a, (1075:16)
	cp	a, (13162:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip12
	ld	a, (13163:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip12:
	calr	AccVoice_BarCounterBytecodeData_Helper10
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jrl	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip13:
	ld	a, (1075:16)
	cp	a, (13160:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip14
	ld	a, (13161:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip14:
	calr	AccVoice_BarCounterBytecodeData_Helper3
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jr	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip15:
	ld	xde, (13298:16)
	lda	xwa, (xsp+4)
	ld	c, (xde+16)
	ld	(xwa), c
	ld	e, (xde+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, AccVoice_BarCounterBytecodeData_Skip16
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccVoice_BarCounterBytecodeData_Skip16:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	ld	a, (12963:16)
	extz	wa
	call	AccVoice_ComputeParamAddr_Wrap
	ld	bc, hl
	ld	xwa, xiz
	call	AccVoice_LoadAllParts_Wrap
	ld	xwa, (13298:16)
AccVoice_BarCounterBytecodeData_Join3:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x332c:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccVoice_IncrementBarWithSave_Helper3:
	dec	2, xsp
	push	xiz
	ld	xwa, (13298:16)
	lda	xiy, (RhythmTiming_OffsetTable:24)
	lda	xix, (xwa+17)
	ld	e, (xwa+16)
	lda	xhl, (xsp+4)
	lda	xbc, (xhl+1)
	bit	0, (0x3363:16)
	jrl	z, AccVoice_BarCounterBytecodeData_Skip23
	ld	a, (13066:16)
	cp	a, 1:i3
	jrl	z, AccVoice_BarCounterBytecodeData_Skip21
	cp	a, 4:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip18
	cp	a, 8
	jrl	nz, AccVoice_BarCounterBytecodeData_Skip21
	ld	a, (1075:16)
	cp	a, (13158:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip17
	ld	a, (13159:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xiy+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip17:
	calr	AccTone_InlineBytecodeData_Code_Helper3_Helper3
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jrl	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip18:
	ld	a, (1075:16)
	extz	wa
	lda	xiy, (AccStyle_ApplyExt_SkipClamp_Table:24)
	cp	(xiy+wa), 0x01
	jr	nz, AccVoice_BarCounterBytecodeData_Skip19
	calr	AccTone_InlineBytecodeData_Code_Helper3_Helper
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jrl	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip19:
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
	jr	z, AccVoice_BarCounterBytecodeData_Skip20
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccVoice_BarCounterBytecodeData_Skip20:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	ld	xwa, xiz
	ldw	bc, 34
	call	AccVoice_LoadAllParts_Wrap
	ld	xwa, xiz
	ld	xbc, 294
	call	AccVoice_LoadTuningBlock_Wrap
	jrl	AccVoice_BarCounterBytecodeData_Entry
AccVoice_BarCounterBytecodeData_Skip21:
	ld	a, (1075:16)
	cp	a, (13156:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip22
	ld	a, (13157:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xiy+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip22:
	calr	AccTone_InlineBytecodeData_Code_Helper3_Helper2
	ld	xwa, (13350:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (13350:16)
	jr	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip23:
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
	jr	z, AccVoice_BarCounterBytecodeData_Skip24
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccVoice_BarCounterBytecodeData_Skip24:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	ld	a, (13066:16)
	cp	a, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip26
	cp	a, 4:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip25
	cp	a, 8
	jr	nz, AccVoice_BarCounterBytecodeData_Skip26
	ldw	bc, 1056
	jr	AccVoice_BarCounterBytecodeData_Join4
AccVoice_BarCounterBytecodeData_Skip25:
	ldw	bc, 34
	jr	AccVoice_BarCounterBytecodeData_Join4
AccVoice_BarCounterBytecodeData_Skip26:
	ldw	bc, 32
AccVoice_BarCounterBytecodeData_Join4:
	ld	xwa, xiz
	call	AccVoice_LoadAllParts_Wrap
	ld	xwa, (13298:16)
AccVoice_BarCounterBytecodeData_Join5:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
AccVoice_BarCounterBytecodeData_Entry:
	or	(0x332c:16), 63
	pop	xiz
	inc	2, xsp
	ret

AccTuning_ReadAndApplyOffset:
	ld a, (0x3423:16)
	extz wa
	lda xbc, (AccTuning_ReadAndApplyOffset_Table:24)
	ld	(0x3422:16), (xbc+wa)
	ret

AccTuning_ComplexBytecodeData:
	dec	2, xsp
	push	xiz
	bit	0, (13155:16)
	jrl	z, AccTuning_ComplexBytecodeData_Skip5
	ld	c, (13424:16)
	ld	e, c
	and	e, 128
	ld	l, (13268:16)
	cpl	l
	cp	e, 128
	jr	z, AccTuning_ComplexBytecodeData_Skip
	ld	e, (13051:16)
	ld	a, e
	and	a, 2
	cp	a, 2:i3
	jr	nz, AccTuning_ComplexBytecodeData_Skip2
AccTuning_ComplexBytecodeData_Skip:
	and	(13074:16), l
	ld	a, (1075:16)
	cp	a, (13162:16)
	jr	nz, AccTuning_ComplexBytecodeData_Loop
	ld	a, (13268:16)
	or	(13075:16), a
	ld	e, (13163:16)
	jr	AccTuning_ComplexBytecodeData_Loop2
AccTuning_ComplexBytecodeData_Loop:
	ld	e, (13345:16)
AccTuning_ComplexBytecodeData_Loop2:
	ld	a, (13268:16)
	cp	a, 2:i3
	jr	nz, AccTuning_ComplexBytecodeData_Skip4
	ldw	(13270:16), 65534
	jr	AccTuning_ComplexBytecodeData_Join
AccTuning_ComplexBytecodeData_Skip2:
	and	c, 64
	cp	c, 64
	jr	z, AccTuning_ComplexBytecodeData_Skip3
	and	e, 1
	ld	a, e
	cp	a, 1:i3
	jr	nz, AccTuning_ComplexBytecodeData_Loop2
AccTuning_ComplexBytecodeData_Skip3:
	and	(13075:16), l
	ld	a, (1075:16)
	cp	a, (13160:16)
	jr nz, AccTuning_ComplexBytecodeData_Loop
	ld a, (13268:16)
	or (13074:16), a
	ld e, (13161:16)
	jr AccTuning_ComplexBytecodeData_Loop2
AccTuning_ComplexBytecodeData_Skip4:
	extz wa
	lda	xbc, (AccTone_InlineBytecodeData_Data:24)
	ld	l, (xbc+wa)
	ld	a, e
	extz	wa
	sla	wa, 2
	lda	xbc, (RhythmTiming_OffsetTable:24)
	ld	xde, 608352
	add	xde, (xbc+wa)
	extz	hl
	add	hl, hl
	ldw	(13270), (xde+hl)
AccTuning_ComplexBytecodeData_Join:
	ldw	(13272:16), 6
	jr	AccTuning_ComplexBytecodeData_Code_Epilogue
AccTuning_ComplexBytecodeData_Skip5:
	ld	xde, (13298:16)
	lda	xwa, (xsp+4)
	ld	c, (xde+16)
	ld	(xwa), c
	ld	e, (xde+17)
	ld	(xwa+1), e
	ld	l, (xwa)
	extz	hl
	extz	de
	sll	de, 8
	ld	bc, de
	or	bc, hl
	cp	bc, 520
	jr	z, AccTuning_ComplexBytecodeData_Code_Skip
	ld	c, (xwa)
	extz	bc
	or	de, bc
	cp	de, 792
	call	nz, (0xf5e6eb:24)
AccTuning_ComplexBytecodeData_Code_Skip:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	call	AccPedal_DirectionA_Wrap
	ld	xwa, xiz
	ld	bc, hl
	call	AccTuning_ComplexBytecodeData_Code_Helper3
	ld	(13272:16), hl
AccTuning_ComplexBytecodeData_Code_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
	ld	(13280:16), 0
	ld	e, (13291:16)
	extz	de
	sla	de, 2
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12951), (xbc+de)
	cpw	(12951:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Code_Skip2
	set	0, (0x33e0:16)
AccTuning_ComplexBytecodeData_Code_Skip2:
	ld	e, (13291:16)
	extz	de
	sla	de, 2
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12935), (xwa+2)
	ld	a, (13293:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 32
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12955), (xbc+de)
	cpw	(12955:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Code_Skip3
	set	2, (0x33e0:16)
AccTuning_ComplexBytecodeData_Code_Skip3:
	ld	a, (13293:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 32
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12939), (xwa+2)
	ld	a, (13294:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 64
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12957), (xbc+de)
	cpw	(12957:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Code_Skip4
	set	3, (0x33e0:16)
AccTuning_ComplexBytecodeData_Code_Skip4:
	ld	a, (13294:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 64
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12941), (xwa+2)
	ld	a, (13295:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 96
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12959), (xbc+de)
	cpw	(12959:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Code_Skip5
	set	4, (0x33e0:16)
AccTuning_ComplexBytecodeData_Code_Skip5:
	ld	a, (13295:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 96
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12943), (xwa+2)
	ld	a, (13296:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 128
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12961), (xbc+de)
	cpw	(12961:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Code_Skip6
	set	5, (0x33e0:16)
AccTuning_ComplexBytecodeData_Code_Skip6:
	ld	a, (13296:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 128
	ld	xwa, 0:i3
	ld	a, (13345:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12945), (xwa+2)
	ldw	(12953:16), 65534
	ldw	(12937:16), 6
	set	1, (0x33e0:16)
	ret
	calr	AccTuning_ComplexBytecodeData_Code_Helper
	ret
AccTuning_ComplexBytecodeData_Code_Helper:
	ret

AccTone_WriteProgramChange:
	push xiz
	ld xix, xwa
	ld l, (xbc)
	ld h, (xbc + 1)
	ld (0x90f7:16), 72
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
Rhythm_UpdateTuningConfig_Wrap:
	push	xiz
	ld	xiy, xwa
	call	Rhythm_UpdateTuningConfig
	pop	xiz
	ret
AccPatch_SetByChordIndex_Wrap:
	push	xiz
	ld	w, a
	call	AccPatch_SetByChordIndex
	pop	xiz
	ret
AccTuning_CopyAllPartsFromStyle_Wrap:
	push	xiz
	ld	xiy, xwa
	call	AccTuning_CopyAllPartsFromStyle
	pop	xiz
	ret
AccVoice_LoadTuningBlock_Wrap:
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccVoice_LoadTuningBlock
	pop	xiz
	ret
AccVoice_ComputeParamAddr_Wrap:
	push	xiz
	and	xwa, 255
	call	AccVoice_ComputeParamAddr
	and	xhl, 0xffff
	pop	xiz
	ret
AccPart_InitPositionsAndBase_Wrap:
	push	xiz
	ld	xiy, xwa
	call	AccPart_InitPositionsAndBase
	pop	xiz
	ret
AccInit_AllPartPositions_Wrap:
	push	xiz
	ld	xiy, xwa
	call	AccInit_AllPartPositions
	pop	xiz
	ret
	push	xiz
	call	AccPedal_ProcessAllChanges
	pop	xiz
	ret
AccStyle_SetupPartAddressesByHL_Wrap:
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 0xffff
	call	AccStyle_SetupPartAddressesByHL
	pop	xiz
	ret
AccVoice_LoadAllParts_Wrap:
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
Rhythm_SendChanPressure_Wrap:
	push	xiz
	call	Rhythm_SendChanPressure
	pop	xiz
	ret
AccBuf_ResetAll4_Wrap:
	push	xiz
	call	AccBuf_ResetAll4
	pop	xiz
	ret
AccSeq_DualPartScan_Wrap:
	push	xiz
	call	AccSeq_DualPartScan
	pop	xiz
	ret
AccSeq_FourChannelScan_Wrap:
	push	xiz
	call	AccSeq_FourChannelScan
	pop	xiz
	ret
AccPedal_DirectionA_Wrap:
	push	xiz
	call	AccPedal_DirectionA
	and	xhl, 0xffff
	pop	xiz
	ret
AccTuning_ComplexBytecodeData_Code_Helper3:
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
	ld	a, (0x33d4:16)
	call	AccPedal_DirectionA_Wrap_Helper
	.ascii "[ZYX^]\\"
	ret
	.ascii "<=>89:;è"
	.byte 0xd0
	ld	a, (0x33d4:16)
	call	AccPedal_DirectionA_Wrap_Helper2
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
	call	AccVoice_IncrementBarWithSave_Helper
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
	call	AccVoice_IncrementBarWithSave_Helper2
	.ascii "[ZYX^]\\"
	ret
	.ascii "<=>89:;"
	call	AccVoice_IncrementBarWithSave_Helper3
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
	ret
AccStyle_TempoLookupData_Helper:
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
	call	AccTone_JumpTableData_Helper3
	ret
	call	AccTone_JumpTableData_Helper2
	ret
	call	AccTone_JumpTableData_Helper
	ret
	call	AccTone_JumpTableData_Data
	ret
AccTone_LookupByProgramWrapped_Join:
	push	xiz
	call	AccStyle_UseSecondarySource
	pop	xiz
	ret
	push_f
	cp	xiy, xbc
	nop
	ldf 233
	lda xbc, (xwa0+:1)
	cp xiy, xbc
	nop
	ld	a, 233:opc
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
	ld (0x39b7:16), 10
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
	calr	AccDemo_InitDone_Helper
	calr	AccPatch_CountAvailableSlots
	or	(0x34cd:16), 128
	pop	xiz
	ret

AccDemo_InitWithFlag:
	push xiz
	or (0x34d1:16), 128
	call AccDemo_Init_Wrap
	pop xiz
	ret

AccPatch_MultiCallWrapper:
	push	xiz
	calr	AccPatch_MultiCallWrapper_Helper
	calr	AccPatch_ClearModeFlag
	pop	xiz
	ret
SeqVoice_StoreEntryDone_Helper:
	push	xiz
	calr	AccPatch_ClearModeFlag
	call	AccPatch_InitSlotChain_WithAddr
	pop	xiz
	ret
AccStyle_TableDataEntry_Helper2:
	push	xiz
	calr	AccPatch_ClearModeFlag
	pop	xiz
	ret

AccPatch_ClearModeFlag:
	ld (0x35d5:16), 0
	ret


Not_sure_maybe_SOFT_VERSION_related:
	.byte 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	ld	(0x35d5:16), 0
	ld	xwa, RHYTHM_PATTERN_BUF_A
	cp	hl, 0:i3
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Return
	ld	(0x35d5:16), 1
	call	Get_Firmware_Version
	cp	l, 255
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Return
	ld	(0x35d5:16), 0
Not_sure_maybe_SOFT_VERSION_related_Code_Return:
	ret
	.byte 0xc1, 0x9b, 0x37, 0x04, 0xc1
	ex_ff
	ldw	iz, 0xfe3c
	ld	(0x35d5:16), 0
	pushdi_b	(13526)
	ld	(0x34d6:16), 0
Not_sure_maybe_SOFT_VERSION_related_Code_Entry:
	cp	(0x34d6:16), 30
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Entry2
	ld	(0x379b:16), 16
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper
	ld	(0x379b:16), 8
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper
	ld	(0x379b:16), 1
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper
	ld	(0x379b:16), 2
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper
	ld	(0x379b:16), 4
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper
	inc	1, (0x34d6:16)
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Entry
Not_sure_maybe_SOFT_VERSION_related_Code_Entry2:
	pop	(0x34d6:16)
	pop	(0x379b:16)
	and	(0x3616:16), 254
	cp	(0x35d5:16), 0
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Return4
	calr	AccDemo_InitDone
Not_sure_maybe_SOFT_VERSION_related_Code_Return4:
	ret
Not_sure_maybe_SOFT_VERSION_related_Code_Helper:
	calr	AccPatch_InitCurrentSlotPointer
	calr	AccPatch_CheckAndInitDemo_Helper2
	ld	w, 0:opc
	mul	wa, c
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Helper
	cpw	(0x3612:16), 65535
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Skip
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Helper2
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Join
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Skip:
	calr	AccDemo_InitDone
	or	(0x3616:16), 1
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Join:
	bit	0, (0x3616:16)
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Skip2
	ld	(0x35d5:16), 1
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Skip2:
	and	(0x3616:16), 254
	ret
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Helper:
	ld	w, 0:opc
	ld	c, 0:opc
Not_sure_maybe_SOFT_VERSION_related_Code_Join:
	cp	c, a
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Return
	push	c
	pushw	wa
	calr	AccPatch_SlotScanByteData_Helper
	cp	a, 131
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Skip
	popw	wa
	pop	c
	inc	1, c
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Join
Not_sure_maybe_SOFT_VERSION_related_Code_Skip:
	popw	wa
	pop	c
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper2
	ld	w, b
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Return:
	ret
Not_sure_maybe_SOFT_VERSION_related_Code_Helper2:
	cp	c, a
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Skip2
	push	c
	push_a
	calr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper3
	cp	b, 1:i3
	jr	z, Not_sure_maybe_SOFT_VERSION_related_Code_Epilogue
	pop_a
	pop	c
	inc	1, c
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper2
Not_sure_maybe_SOFT_VERSION_related_Code_Skip2:
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Return2
Not_sure_maybe_SOFT_VERSION_related_Code_Epilogue:
	pop_a
	pop	c
Not_sure_maybe_SOFT_VERSION_related_Code_Return2:
	ret
Not_sure_maybe_SOFT_VERSION_related_Code_Helper3:
	ld	hl, (0x3612:16)
	calr	AccPatch_GetEntryAddr
	ld	hl, (0x3614:16)
	ld	(xix+hl), 0x81
	ld	wa, (13844:16)
	cp	wa, 254
	jr	nz, Not_sure_maybe_SOFT_VERSION_related_Code_Skip4
	cpw	(13524:16), 0
	jr	nz, Not_sure_maybe_SOFT_VERSION_related_Code_Skip3
	ld	b, 1:opc
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Return3
Not_sure_maybe_SOFT_VERSION_related_Code_Skip3:
	call	AccPatch_SeqAdvStep_WrapToNext
	ld	b, 0:opc
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Return3
Not_sure_maybe_SOFT_VERSION_related_Code_Skip4:
	inc	1, wa
	ld	(0x3614:16), wa
	ld	b, 0:opc
Not_sure_maybe_SOFT_VERSION_related_Code_Return3:
	ret
Not_sure_maybe_SOFT_VERSION_related_Code_Helper_Helper2:
	ld	hl, (0x3612:16)
	calr	AccPatch_GetEntryAddr
	ld	hl, (0x3614:16)
	ld	(xix+hl), 0x83
	ld	hl, (xix+3)
	ldw (xix+3), 65535
Not_sure_maybe_SOFT_VERSION_related_Code_Helper3_Join:
	cp	hl, 340
	jr	nc, Not_sure_maybe_SOFT_VERSION_related_Code_Helper3_Return
	calr	AccPatch_GetEntryAddr
	and	(xix), 127
	ld	hl, (xix+3)
	ldw	(xix+1), 65535
	ldw (xix+3), 65535
	jr	Not_sure_maybe_SOFT_VERSION_related_Code_Helper3_Join
Not_sure_maybe_SOFT_VERSION_related_Code_Helper3_Return:
	ret

AccPatch_CheckAndInitDemo:
	ld xiy, RHYTHM_PATTERN_BUF_A
	add xiy, 0xe
	ld wa, (xiy)
	cp wa, 0:i3
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
AccPatch_CheckAndInitDemo_Entry:
	cp	(0x34d6:16), 12
	jr	z, AccPatch_CheckAndInitDemo_Entry2
	ld	(0x379b:16), 16
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(0x379b:16), 8
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(0x379b:16), 1
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(0x379b:16), 2
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(0x379b:16), 4
	calr	AccPatch_CheckAndInitDemo_Helper
	inc	1, (0x34d6:16)
	jr	AccPatch_CheckAndInitDemo_Entry
AccPatch_CheckAndInitDemo_Entry2:
	pop	(0x34d6:16)
	pop	(0x379b:16)
	ret
AccPatch_CheckAndInitDemo_Helper:
	cp	(0x34d6:16), 12
	jr	nc, AccPatch_CheckAndInitDemo_Return
	calr	AccPatch_InitCurrentSlotPointer
	calr	AccPatch_SlotScanByteData
	calr	AccPatch_CheckAndInitDemo_Helper2
	ld	e, c
	ld	c, 1:opc
AccPatch_CheckAndInitDemo_Join:
	cp	c, e
	jr	z, AccPatch_CheckAndInitDemo_Return
	push	e
	push_a
	push	c
	calr	AccPatch_CheckAndInitDemo_Helper3
	pop	c
	push	c
	calr	AccPatch_CheckAndInitDemo_Helper4
	pop	c
	pop_a
	pop	e
	inc	1, c
	jr	AccPatch_CheckAndInitDemo_Join
AccPatch_CheckAndInitDemo_Return:
	ret

AccPatch_InitCurrentSlotPointer:
	calr AccPatch_GetCurrentSlotAddr
	ld a, (0x379b:16)
	calr MapBitFlagsToChannelOffset
	ld	hl, (xiy+w)
	ld (0x3612:16), hl
	ldw (0x3614:16), 6
	ret

AccPatch_SlotScanByteData:
	ld	c, 0:opc
AccPatch_SlotScanByteData_Join:
	cp	c, 8
	jr	z, AccPatch_SlotScanByteData_Return
	push	c
	calr	AccPatch_CheckAndInitDemo_Helper4
	pop	c
	inc	1, c
	jr	AccPatch_SlotScanByteData_Join
AccPatch_SlotScanByteData_Return:
	ret
AccPatch_SlotScanByteData_Helper:
	call	AccPatch_SeqReadByte
	cp	a, 129
	jr	z, AccPatch_SlotScanByteData_Skip
	cp	a, 131
	jr	z, AccPatch_SlotScanByteData_Return2
	push_a
	call	AccPatch_AdvanceSeqIndex
	pop_a
	bit	0, (0x3616:16)
	jr	nz, AccPatch_SlotScanByteData_Skip
	jr	AccPatch_SlotScanByteData_Helper
AccPatch_SlotScanByteData_Skip:
	push_a
	call	AccPatch_AdvanceSeqIndex
	pop_a
	jr	AccPatch_SlotScanByteData_Return2
AccPatch_SlotScanByteData_Return2:
	ret
AccPatch_CheckAndInitDemo_Helper2:
	calr	AccPatch_GetCurrentSlotAddr
	ld	xwa, 0:i3
	ld	a, (xiy+12)
	add	xwa, AccTone_LookupByProgram_Table
	ld	a, (xwa)
	ld	c, (xiy+13)
	inc	1, c
	ret
AccPatch_CheckAndInitDemo_Helper3:
	ld	c, 0:opc
AccPatch_SlotScanByteData_Join2:
	cp	c, a
	jr	z, AccPatch_SlotScanByteData_Return3
	push	c
	push_a
	calr	AccPatch_SlotScanByteData_Helper
	pop_a
	pop	c
	inc	1, c
	jr	AccPatch_SlotScanByteData_Join2
AccPatch_SlotScanByteData_Return3:
	ret
AccPatch_CheckAndInitDemo_Helper4:
	push	c
	ld	xwa, 0:i3
	ld	a, 160:opc
	ld	c, (0x34d6:16)
	mul	wa, c
	ld	xbc, 0:i3
	ld	c, (0x379b:16)
	and	c, 31
	srl	c, 1
	add	xbc, AccPatch_SlotScanByteData_Code
	ld	xde, 0:i3
	ld	e, (xbc)
	mul	de, 32
	add	xwa, xde
	add	xwa, 3136
	add	xwa, RHYTHM_PATTERN_BUF_A
	ld	xix, xwa
	pop	c
	sll	c, 2
	ld	wa, (0x3612:16)
	ld	(xix+c), wa
	ld	wa, (0x3614:16)
	inc	2, c
	ld	(xix+c), wa
	ret
AccPatch_SlotScanByteData_Code:
	push	sr
	pop	sr
	max
	nop
	normal
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
	ld xhl, 0:i3
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
	cp (CURRENT_TITLE:16), 178
	jr z, RhythmProc_StyleChange_Init
	jr RhythmProc_StyleChange_Ret

RhythmProc_StyleChange_Init:
	bit 2, (0x34cd:16)
	jr z, RhythmProc_StyleChange_Ret
	and (0x34cd:16), 251
	calr AccPatch_InitCurrentSlot
	calr AccPatch_UpdateAllChains
	call RhythmPatInit_LoadParams

RhythmProc_StyleChange_Ret:
	ret

RhythmProc_CheckPlayMode:
	cp (CURRENT_TITLE:16), 181
	jr z, RhythmProc_PlayMode_Compare
	ld a, (0x34cf:16)
	and a, 0xf3
	ld (0x34cf:16), a
	jr AccPatch_CopySlotsExit

RhythmProc_PlayMode_Compare:
	cp (0x3525:16), 181
	jr z, RhythmProc_PlayMode_SendTempo
	ld (0x35fe:16), 0
	ld a, (0x32b3:16)
	and a, 0x7
	ld (0x34dc:16), a

RhythmProc_PlayMode_SendTempo:
	bit 1, (0x34cf:16)
	jr z, AccPatch_DetectModeChange
	and (0x34cf:16), 253
	ld a, (0x34cf:16)
	and a, 0xc
	cp a, 0:i3
	jr nz, AccPatch_DetectModeChange
	ld a, (0x35fc:16)
	and a, 0xc
	cp a, 0:i3
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
	ld a, (0x32b3:16)
	and a, 0x7
	cp a, (0x34dc:16)
	jr z, AccPatch_CopySlotsExit
	ld (0x34dc:16), a
	cp (ACTIVE_TITLE:16), 181
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
	nop
	nop
	nop
	nop
	max
	max
	max
	max
	ld (P2:8), 8:io
	ld (P0:8), 0:io
	nop
	nop
	nop
	nop
	max
	max
	max
	max
	max
	max
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
	ld xhl, 0:i3
	ld l, (0x34d6:16)
	cp l, 0x1e
	jr c, AccPatch_GetSlotAddr_Valid
	ld l, 0x0:opc

AccPatch_GetSlotAddr_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ld xiy, RHYTHM_PATTERN_BUF_A
	add xiy, xhl
	ret

AccPatch_GetSlotAddr_Preserve:
	push	xwa
	push	xix
	xor	xhl, xhl
	ld	l, (0x34d6:16)
	cp	l, 30
	jr	c, AccPatch_GetSlotAddr_Preserve_Skip
	xor	l, l
AccPatch_GetSlotAddr_Preserve_Skip:
	mul	hl, 96
	add	xhl, 96
	ld	xiy, RHYTHM_PATTERN_BUF_A
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
	ld xhl, 0:i3
	popw hl
	sll xhl, 8
	ld xix, RHYTHM_PATTERN_BUF_B
	add xix, xhl
	popw hl

AccPatch_GetEntryAddr_Ret:
	ret

AccPatch_InitCurrentSlot:
	calr AccPatch_GetCurrentSlotAddr
	calr AccPatch_FreeAllChains
	calr AccPatch_CopyDefaultsForInit
	calr AccPatch_FillAllVoiceData
	or (0x34cd:16), 128
	calr AccPatch_ScanToSequenceStart
	ret

AccPatch_InitFromSlotIndex:
	push xiz
	calr AccPatch_InitFromIndex
	pop xiz
	ret

AccPatch_InitFromIndex:
	xor xhl, xhl
	ld l, (0x39ac:16)
	cp l, 0x1e
	jr c, AccPatch_InitFromIndex_Valid
	xor l, l

AccPatch_InitFromIndex_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ld xiy, (0x39ae:16)
	add xiy, xhl
	calr AccPatch_FreeAllChains_Alt
	calr AccPatch_CopyDefaultsToSlot
	calr AccPatch_FillAllSlots_Alt
	or (0x34cd:16), 128
	calr AccPatch_ScanSequenceToEnd
	ret

AccPatch_InitByteStub:
	push	xiz
	calr	AccPat_InitWorkAreaFromSlot
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	push xwa
	ld a, (0x34d6:16)
	ld (0x39ac:16), a
	ld xwa, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xwa
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
	cp a, 7:i3
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
	ld a, 0x0:opc
	ld w, (0x39ac:16)
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
	calr	AccPatch_GetSlotAddr_Preserve
	calr	AccPatch_FreeAllChains
	calr	AccPatch_CopyDefaultsForInit
	calr	AccPatch_FillAllVoiceData
	or	(0x34cd:16), 128
	calr	AccPatch_ScanToSequenceStart
	ret

AccPatch_FreeAllChains:
	ld hl, (xiy + 0:8)
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
	incw 1, (0x34d4:16)
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Done
	jr AccPatch_FreeChainLoop

AccPatch_FreeChain_Done:
	pop xiy
	ret

AccPatch_FillAllVoiceData:
	ld hl, (xiy + 0:8)
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
	ld xwa, 0:i3
	ld xbc, AccTone_LookupByProgram_Table
	ld	a, (xbc+hl)
	ld xbc, 0:i3
	ld b, (xiy + 13)
	inc 1, b
	mul wa, b
	popw hl
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	ld l, 0x81:opc

AccPatch_FillVoice_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cp wa, 0:i3
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
	cp a, 7:i3
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
	normal
	ld	w, 128:opc
	pop	xwa
	push	sr
	nop
	nop
	.zero 8
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF5EFB7-0xF5EFC7 (16 B), unreached CODE-territory, was disassembled as 12 plausible-but-dead instruction lines; per=100% dist=7 near AccPatch_DefaultSlotData+16
	.byte 0x00, 0x00, 0x00, 0x00, 0x28, 0x00, 0x40, 0x00, 0x50, 0x06, 0x7f, 0x00
	.byte 0x00, 0x00, 0x0c, 0x00
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
	ld a, 0x0:opc
	cp (0x34d6:16), 14
	jr nz, AccPatch_ClearSlot13_Idx0F
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx0F:
	cp (0x34d6:16), 15
	jr nz, AccPatch_ClearSlot13_Idx14
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx14:
	cp (0x34d6:16), 20
	jr nz, AccPatch_ClearSlot13_Idx15
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx15:
	cp (0x34d6:16), 21
	jr nz, AccPatch_ClearSlot13_Idx1A
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1A:
	cp (0x34d6:16), 26
	jr nz, AccPatch_ClearSlot13_Idx1B
	ld (xiy + 13), a

AccPatch_ClearSlot13_Idx1B:
	cp (0x34d6:16), 27
	jr nz, AccPatch_ClearSlot13_IdxDone
	ld (xiy + 13), a

AccPatch_ClearSlot13_IdxDone:
	ret

AccPatch_SetVoiceAndInit:
	calr AccPatch_GetCurrentSlotAddr
	ld a, (0x34d8:16)
	ld (xiy + 12), a
	push xiy
	calr AccPatch_InitAllSentinels
	pop xiy
	ld xhl, 0:i3
	ld l, (0x34d8:16)
	sll l, 1
	xor h, h
	add xhl, AccPatch_VoiceStrideTable
	ld wa, (xhl)
	ld (xiy + 16), wa
	calr AccPatch_CheckConfigType
	or (0x34cd:16), 128
	ret

AccPatch_VoiceStrideTable:
	.byte 0x00, 0x00, 0x58, 0x02, 0x08, 0x02, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03

AccPatch_CheckConfigType:
	cp (0x34d9:16), 6
	jr z, RhythmConfig_CheckAndSkip
	cp (0x34d9:16), 8
	jr z, RhythmConfig_CheckAndSkip
	cp (0x34d9:16), 4
	jr z, RhythmConfig_CheckAndSkip
	cp (0x34d9:16), 3
	jr z, RhythmConfig_CheckAndSkip
	jr AccPatch_CheckConfig_Done

RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	calr AccPatch_ReadVoiceStride
	ld xwa, 0:i3
	ld a, (0x34d9:16)
	ld b, (0x34d7:16)
	and b, 0x7
	inc 1, b
	mul wa, b
	ld c, a
	ld hl, (xiy + 0:8)
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
	cp b, 0:i3
	jr nz, AccPatch_WriteSentinel_Loop
	ld (xix), 0x83
	pop xiy
	ret

AccPatch_ReadVoiceStride:
	ld xhl, 0:i3
	ld l, (0x34d8:16)
	ld xbc, AccTone_LookupByProgram_Table
	add xbc, xhl
	ld a, (xbc)
	ld (0x34d9:16), a
	ret

RhythmProc_CheckRhythmEdit:
	cp (CURRENT_TITLE:16), 180
	jr nz, RhythmProc_RhythmEdit_Ret
	calr RhythmProc_CheckVoiceChange
	calr RhythmProc_CheckConfigBits

RhythmProc_RhythmEdit_Ret:
	ret

RhythmProc_CheckVoiceChange:
	bit 1, (0x34ce:16)
	jr z, RhythmProc_CheckVoiceUpdate
	and (0x34ce:16), 253
	calr AccPatch_SetVoiceAndInit

RhythmProc_CheckVoiceUpdate:
	bit 0, (0x34ce:16)
	jr z, RhythmProc_VoiceUpdate_Ret
	and (0x34ce:16), 254
	calr RhythmProc_UpdateVoiceSentinels

RhythmProc_VoiceUpdate_Ret:
	ret

RhythmProc_UpdateVoiceSentinels:
	calr AccPatch_GetCurrentSlotAddr
	ld a, (0x34d7:16)
	and a, 0x7
	ld (xiy + 13), a
	calr AccPatch_InitAllSentinels
	ret

RhythmProc_CheckConfigBits:
	bit 0, (0x34d2:16)
	jr z, RhythmProc_ConfigBit1
	and (0x34d2:16), 254
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xf0
	ld a, (0x34e9:16)
	and a, 0xf
	or (xiy + 14), a

RhythmProc_ConfigBit1:
	bit 1, (0x34d2:16)
	jr z, RhythmProc_ConfigBit2
	and (0x34d2:16), 253
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0xef
	bit 4, (0x34ea:16)
	jr z, RhythmProc_ConfigBit2
	ormi8 (xiy + 14), 0x10

RhythmProc_ConfigBit2:
	bit 2, (0x34d2:16)
	jr z, RhythmProc_ConfigBits_Done
	and (0x34d2:16), 251
	calr AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 14), 0x9f
	bit 5, (0x34ea:16)
	jr z, RhythmProc_ConfigBit2_SetBit6
	ormi8 (xiy + 14), 0x20

RhythmProc_ConfigBit2_SetBit6:
	bit 6, (0x34ea:16)
	jr z, RhythmProc_ConfigBits_Done
	ormi8 (xiy + 14), 0x40

RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr z, AccPatch_RebuildChannel_Done
	calr MapBitFlagsToChannelOffset
	ld (0x342e:16), w
	ld c, w
	push c
	calr AccPatch_GetCurrentSlotAddr
	pop c
	ld	hl, (xiy+c)
	ld (0x343d:16), hl
	calr AccPatch_FreeChainEntries
	ld xhl, 0:i3
	ld l, (0x34d8:16)
	add xhl, AccTone_LookupByProgram_Table
	ld a, (xhl)
	ld xhl, 0:i3
	ld l, (0x34d7:16)
	and l, 0x7
	inc 1, l
	mul hl, a
	and hl, 0x7f
	ld c, l
	ld hl, (0x343d:16)
	calr AccPatch_InitSlotSentinels
	calr AccPatch_ComputeSeqPosition
	ld (0x35fe:16), 0
	calr AccPatch_WriteRhythmInit
	bit 0, (0x3283:16)
	jr nz, AccPatch_RebuildChannel_Done
	or (0x34cd:16), 128

AccPatch_RebuildChannel_Done:
	ret

MapBitFlagsToChannelOffset:
	ld w, 0x0:opc
	bit 4, a
	jr nz, MapBitFlags_NullRet
	ld w, 0x4:opc
	bit 3, a
	jr nz, MapBitFlags_NullRet
	ld w, 0x6:opc
	bit 0, a
	jr nz, MapBitFlags_NullRet
	ld w, 0x8:opc
	bit 1, a
	jr nz, MapBitFlags_NullRet
	ld w, 0xa:opc

MapBitFlags_NullRet:
	ret

AccPatch_ComputeSeqPosition:
	ld xwa, 0:i3
	ld a, (0x32b3:16)
	ld c, (0x34d9:16)
	mul wa, c
	add a, (0x3280:16)
	ld l, a
	ld a, (0x327f:16)
	add a, 0x18
	cp a, 0x60
	jr lt, AccPatch_SeqPosition_Store
	inc 1, l
	ld xwa, 0:i3
	ld a, (0x34d9:16)
	ld c, (0x34d7:16)
	inc 1, c
	mul wa, c
	cp a, l
	jr nz, AccPatch_SeqPosition_Store
	ld l, 0x0:opc

AccPatch_SeqPosition_Store:
	ld xbc, 0:i3
	ld c, l
	ld hl, (0x343d:16)
	ld wa, 6:i3
	add wa, bc
	ld xhl, 0:i3
	ld l, (0x342e:16)
	sll l, 1
	add xhl, AccPatch_SeqBaseAddrTable
	ld xhl, (xhl)
	ld (xhl), wa
	ld xhl, 0:i3
	ld l, (0x342e:16)
	sll l, 1
	add xhl, AccPatch_SeqPosition_Store_Data
	ld xhl, (xhl)
	ld wa, (0x343d:16)
	ld (xhl), wa
	ret

AccPatch_SeqBaseAddrTable:
	.byte 0x87, 0x32, 0x00, 0x00, 0x89, 0x32, 0x00, 0x00
	.byte 0x8b, 0x32, 0x00, 0x00, 0x8d, 0x32, 0x00, 0x00
	.byte 0x8f, 0x32, 0x00, 0x00, 0x91, 0x32, 0x00, 0x00
AccPatch_SeqPosition_Store_Data:
	.byte 0x97, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x9b, 0x32, 0x00, 0x00, 0x9d, 0x32, 0x00, 0x00
	.byte 0x9f, 0x32, 0x00, 0x00, 0xa1, 0x32, 0x00, 0x00

AccPatch_WriteRhythmInit:
	ld l, (0x342e:16)
	cp l, 0:i3
	jr z, AccPatch_WriteRhythm_Done
	ld xhl, 0:i3
	ld l, (0x342e:16)
	add xhl, AccPatch_ChannelToParamTable
	ld a, (xhl)
	push_sd16b 0x2e, 0x34
	calr AccPatch_WriteRhythmParams
	popb_dd16 0x2e, 0x34
	ld xhl, 0:i3
	ld l, (0x342e:16)
	sll hl, 1
	add xhl, AccPatch_ChannelToRecordPtr
	ld xhl, (xhl)
	ld iy, (xhl + 4)
	ld (xhl + 6), iy

AccPatch_WriteRhythm_Done:
	ret

; Two tables indexed by the channel in (0x342E) -- 4, 6, 8 or 10 here.  AccPatch_ChannelToParamTable is read as a byte
;          at +channel (0xD7, 0xD4, 0xD5, 0xD6); AccPatch_ChannelToRecordPtr as a long at +channel*2, the RAM records
;          0x2C94-0x2F94, 0x100 apart (was the positional alias AccPatch_ChannelToParamTable + 16).
AccPatch_ChannelToParamTable:	.byte	0, 0, 0, 0, 0xd7, 0, 0xd4, 0, 0xd5, 0, 0xd6, 0, 0, 0, 0, 0
AccPatch_ChannelToRecordPtr:	.long	0, 0, 0x2c94, 0x2d94, 0x2e94, 0x2f94

AccPatch_WriteRhythmParams:
	calr AccPatch_FetchVolumeForChannel
	push_a
	ld xwa, 0:i3
	pop_a
	ld c, 0x0:opc

AccPatch_WriteRhythmParam_Loop:
	cp c, 6:i3
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
	ld	a, (xwa+c)
	push c
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	pop c
	inc 1, c
	ld xwa, AccPatch_RhythmParamDefaults
	ld	a, (xwa+c)
	cp c, 7:i3
	jr nz, AccPatch_WriteRhythmParam_Push
	ld a, (0x344d:16)

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
	normal
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
	ld a, 0x40:opc
	jr AccPatch_FetchVolume_Default

ToneGen_FetchSelectRestore:
	add xix, xiy
	ld a, (xix)

AccPatch_FetchVolume_Default:
	ld (0x344d:16), a
	pop xiy
	pop xix
	pop xhl
	pop xwa
	ret

RhythmProc_CheckStyleSwitch:
	cp (CURRENT_TITLE:16), 184
	jr z, RhythmProc_StyleSwitch_Call
	jr RhythmProc_StyleSwitch_Ret

RhythmProc_StyleSwitch_Call:
	call AccPat_DispatchNoteChange

RhythmProc_StyleSwitch_Ret:
	ret

RhythmProc_CheckRepeatFlag:
	cp (CURRENT_TITLE:16), 189
	jr nz, RhythmProc_RepeatFlag_Ret
	bit 1, (0x34d3:16)
	jr z, RhythmProc_RepeatFlag_Ret
	and (0x34d3:16), 253
	ld xiy, RHYTHM_PATTERN_BUF_A
	add xiy, 0x0
	add xiy, 0x10
	ld a, (xiy)
	and a, 0xfe
	bit 0, (0x34d3:16)
	jr z, RhythmProc_RepeatFlag_Store
	or a, 0x1

RhythmProc_RepeatFlag_Store:
	ld (xiy), a

RhythmProc_RepeatFlag_Ret:
	ret

RhythmProc_SavePrevState:
	ld a, (CURRENT_TITLE:16)
	ld (0x3525:16), a
	ld a, (0x379b:16)
	and a, 0x7f
	ld (0x3510:16), a
	ld a, (0x3283:16)
	ld (0x3601:16), a
	cp (CURRENT_MODE:16), 14
	jr z, RhythmProc_SavePrevState_Done
	ld (0x379b:16), 0

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
	ld (0x34d4:16), wa
	ret

AccPatch_CountSlotsAlt_Body:
	ld xix, (0x39ae:16)
	push xix
	ld xix, 0x69800
	ld (0x39ae:16), xix
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
	ld (0x34d4:16), wa
	pop xix
	ld (0x39ae:16), xix
	ret

AccPatch_MiscDataBlock:
	ld	xwa, 100
	mul	xwa, (0x34d4:16)	; XWA, (0x34d4) (unidasm; no llvm-mc spelling)
	ldw	hl, 190
	div	xwa, hl
	cp	a, 100
	jr	c, AccPatch_CountSlotsAlt_Body_Skip
	ld	a, 99:opc
AccPatch_CountSlotsAlt_Body_Skip:
	ld	(0x39ab:16), a
	ret

AccPatch_ProcessPartChanges:
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, AccPatch_PartChanges_MapLookup
	ld w, (0x3510:16)
	and w, 0x1f
	cp w, 0:i3
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
	ld a, (0x379b:16)
	and a, 0x1f
	ld xhl, 0:i3
	ld l, a
	add xhl, AccPatch_PartNumberTable
	ld a, (xhl)
	ld (PART_SELECT:16), a
	ld e, a
	ld a, (0x379b:16)
	ld w, (0x3510:16)
	and a, 0x1f
	and w, 0x1f
	cp w, a
	jr z, AccPatch_PartChanges_Update
	ld a, e
	ld e, 0x90:opc
	ld d, 0x10:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent

AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	ld a, (0x3510:16)
	bit 6, a
	jr z, AccPatch_PartChanges_Done
	ld w, (0x379b:16)
	bit 5, w
	jr z, AccPatch_PartChanges_Done
	call AccPatch_ReadRepeatBit
	calr AccPatch_UpdateAllChains

AccPatch_PartChanges_Done:
	ret

AccPatch_ReadRepeatBit:
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x0
	add xix, 0x10
	ld a, (xix)
	bit 0, a
	jr nz, AccPatch_SetRepeatBitOn
	and (0x34d3:16), 254
	jr AccPatch_SetRepeatBit_Done

AccPatch_SetRepeatBitOn:
	or (0x34d3:16), 1

AccPatch_SetRepeatBit_Done:
	ret

AccPatch_PartNumberTable:
; AccPatch_PartNumberTable -- 32 x u8, indexed by the one-hot selector
; (0x379b) & 0x1F.  ** RE-TYPED 2026-09-25 (lane accomp): was
; nop/rcf/scf/ccf/zcf/push_a mnemonics (data-as-code).  Read by
; AccPatch_PartChanges_MapLookup:
;     ld a,(0x379b) / and a,0x1f / ld l,a / add xhl, <this> / ld a,(xhl) /
;     ld (0x8d3a),a
; Only the five one-hot indices are non-zero: 1->0x10, 2->0x11, 4->0x12,
; 8->0x13, 16->0x14, i.e. it turns the selected bit into 0x10+bit.  32
; entries: pinned by `and a, 0x1f`, and the table ends exactly where
; AccPatch_UpdateAllChains begins.
; readers in v9/v10 (address from the linked ELF): AccPatch_PartChanges_MapLookup 0xF5F4DF
	.byte 0x00, 0x10, 0x11, 0x00, 0x12, 0x00, 0x00, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

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
	ld a, (xiy + 0:8)
	andmi8 (xix + 0:8), 0x0
	or (xix + 0:8), a
	ld e, a
	sll b, 1
	ld (0x34e1:16), e
	ld (0x34e2:16), d
	or (0x34e2:16), b
	push d
	push e
	ld a, d
	ld d, 0x1:opc
	ld w, 0x7f:opc
	ld e, 0x13:opc
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ld d, 0x0:opc
	ld w, 0xff:opc
	ld e, 0x13:opc
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	ld (0x90f7:16), 19
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff56
	ld	(xbc+l), h
	ld a, (xiy + 3)
	sla a, 6
	ld d, 0x4:opc
	ld w, 0x40:opc
	ld e, 0x13:opc
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
	ld a, (xiy + 0:8)
	or a, 0xf0
	andmi8 (xix + 0:8), 0x0
	or (xix + 0:8), a
	ld e, a
	sll b, 1
	ld (0x34df:16), e
	ld (0x34e0:16), d
	or (0x34e0:16), b
	push d
	push e
	ld a, d
	ld d, 0x1:opc
	ld w, 0x7f:opc
	ld e, 0x14:opc
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ld d, 0x0:opc
	ld w, 0xff:opc
	ld e, 0x14:opc
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	ld (0x90f7:16), 20
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff6a
	ld	(xbc+l), h
	ld a, (xiy + 3)
	sla a, 6
	ld d, 0x4:opc
	ld w, 0x40:opc
	ld e, 0x14:opc
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
	ld a, (xiy + 0:8)
	andmi8 (xix + 0:8), 0x0
	or (xix + 0:8), a
	ld e, a
	sll b, 1
	ld (0x34e3:16), e
	ld (0x34e4:16), d
	or (0x34e4:16), b
	push d
	push e
	ld a, d
	ld d, 0x1:opc
	ld w, 0x7f:opc
	ld e, 0x10:opc
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ld d, 0x0:opc
	ld w, 0xff:opc
	ld e, 0x10:opc
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	ld (0x90f7:16), 16
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff1a
	ld	(xbc+l), h
	ld a, (xiy + 3)
	sla a, 6
	ld d, 0x4:opc
	ld w, 0x40:opc
	ld e, 0x10:opc
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
	ld a, (xiy + 0:8)
	andmi8 (xix + 0:8), 0x0
	or (xix + 0:8), a
	ld e, a
	sll b, 1
	ld (0x34e5:16), e
	ld (0x34e6:16), d
	or (0x34e6:16), b
	push d
	push e
	ld a, d
	ld d, 0x1:opc
	ld w, 0x7f:opc
	ld e, 0x11:opc
	call SwbtWr_QueuePostEvent
	pop e
	push e
	ld a, e
	ld d, 0x0:opc
	ld w, 0xff:opc
	ld e, 0x11:opc
	call SwbtWr_QueuePostEvent
	pop e
	pop d
	ld h, d
	ld l, e
	ld (0x90f7:16), 17
	call PartCtrl_WriteProgramChange
	ld xbc, 0xff2e
	ld	(xbc+l), h
	ld a, (xiy + 3)
	sla a, 6
	ld d, 0x4:opc
	ld w, 0x40:opc
	ld e, 0x11:opc
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
	ld a, (xiy + 0:8)
	andmi8 (xix + 0:8), 0x0
	or (xix + 0:8), a
	ld e, a
	sll b, 1
	ld (0x34e7:16), e
	ld (0x34e8:16), d
	or (0x34e8:16), b
	push d
	push e
	ld a, d
	ld d, 0x1:opc
	ld w, 0x7f:opc
	ld e, 0x12:opc
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	push e
	ld a, e
	ld d, 0x0:opc
	ld w, 0xff:opc
	ld e, 0x12:opc
	push xiy
	call SwbtWr_QueuePostEvent
	pop xiy
	pop e
	pop d
	ld h, d
	ld l, e
	ld (0x90f7:16), 18
	push xiy
	call PartCtrl_WriteProgramChange
	pop xiy
	ld xbc, 0xff42
	ld	(xbc+l), h
	ld a, (xiy + 3)
	sla a, 6
	ld d, 0x4:opc
	ld w, 0x40:opc
	ld e, 0x12:opc
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
	ld w, (xix + 0:8)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncRhythm_HasBank
	ld h, 0x40:opc
	sll h, 1
	or a, h

AccPatch_SyncRhythm_HasBank:
	ld h, (0x34e1:16)
	ld l, (0x34e2:16)
	cp hl, wa
	jr z, AccPatch_SyncRhythm_Done
	pushw wa
	ld (xiy + 0:8), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	ld (0x34e1:16), w
	ld (0x34e2:16), a
	ld xix, 0x3219
	calr AccPatch_LoadVoiceParams

AccPatch_SyncRhythm_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Bass:
	push xiy
	add xiy, 0x18
	ld xix, 0xfbbe
	ld w, (xix + 0:8)
	and w, 0xff
	and w, 0xf
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncBass_HasBank
	ld h, 0x40:opc
	sll h, 1
	or a, h

AccPatch_SyncBass_HasBank:
	ld h, (0x34df:16)
	ld l, (0x34e0:16)
	cp hl, wa
	jr z, AccPatch_SyncBass_Done
	pushw wa
	ld (xiy + 0:8), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	ld (0x34df:16), w
	ld (0x34e0:16), a
	ld xix, 0x3214
	calr AccPatch_LoadVoiceParams

AccPatch_SyncBass_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc1:
	push xiy
	add xiy, 0x28
	ld xix, 0xfb56
	ld w, (xix + 0:8)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc1_HasBank
	ld h, 0x40:opc
	sll h, 1
	or a, h

AccPatch_SyncAcc1_HasBank:
	ld h, (0x34e3:16)
	ld l, (0x34e4:16)
	cp hl, wa
	jr z, AccPatch_SyncAcc1_Done
	pushw wa
	ld (xiy + 0:8), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	ld (0x34e3:16), w
	ld (0x34e4:16), a
	ld xix, 0x321e
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc1_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc2:
	push xiy
	add xiy, 0x30
	ld xix, 0xfb70
	ld w, (xix + 0:8)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc2_HasBank
	ld h, 0x40:opc
	sll h, 1
	or a, h

AccPatch_SyncAcc2_HasBank:
	ld h, (0x34e5:16)
	ld l, (0x34e6:16)
	cp hl, wa
	jr z, AccPatch_SyncAcc2_Done
	pushw wa
	ld (xiy + 0:8), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	ld (0x34e5:16), w
	ld (0x34e6:16), a
	ld xix, 0x3223
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc2_Done:
	pop xiy
	ret

AccPatch_SyncVoice_Acc3:
	push xiy
	add xiy, 0x38
	ld xix, 0xfb8a
	ld w, (xix + 0:8)
	and w, 0xff
	ld a, (xix + 1)
	and a, 0x7f
	bitm 6, (xix + 4)
	jr z, AccPatch_SyncAcc3_HasBank
	ld h, 0x40:opc
	sll h, 1
	or a, h

AccPatch_SyncAcc3_HasBank:
	ld h, (0x34e7:16)
	ld l, (0x34e8:16)
	cp hl, wa
	jr z, AccPatch_SyncAcc3_Done
	pushw wa
	ld (xiy + 0:8), w
	ld c, a
	and c, 0x7f
	ld (xiy + 1), c
	and a, 0x80
	srl a, 7
	ld (xiy + 3), a
	popw wa
	ld (0x34e7:16), w
	ld (0x34e8:16), a
	ld xix, 0x3228
	calr AccPatch_LoadVoiceParams

AccPatch_SyncAcc3_Done:
	pop xiy
	ret

AccPatch_LoadVoiceParams:
	ld e, (xiy + 0:8)
	ld d, (xiy + 1)
	ld a, (xiy + 2)
	ld (0x342f:16), a
	ld a, (xiy + 3)
	ld (0x3430:16), a
	ld a, (xiy + 4)
	ld (0x3431:16), a
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
	ld a, (0x342f:16)
	ld (xix + 2), a
	ld a, (0x3430:16)
	ld (xix + 3), a
	ld a, (0x3431:16)
	ld (xix + 4), a
	call AccVoice_LoadAllChannelParams
	ret

AccPatch_ComplexDataBlock:
	ld	a, (CURRENT_MODE:16)
	cp	a, 14
	jr	nz, AccPatch_CallParamLookup_Return
	calr	AccPatch_CallParamLookup_Helper
AccPatch_CallParamLookup_Return:
	ret
AccPatch_CallParamLookup_Helper:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip
	cp	(SWBTWR_PAYLOAD_2:16), 128
	jr	nc, AccPatch_CallParamLookup_Skip
	cp	(SWBTWR_PAYLOAD_3:16), 0
	jr	z, AccPatch_CallParamLookup_Skip
	ld	a, (CURRENT_TITLE:16)
	cp	a, 180
	jr	nz, AccPatch_CallParamLookup_Skip
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 0
	ld	a, (xiy+16)
	bit	0, a
	jr	nz, AccPatch_CallParamLookup_Skip
	call	RhythmVariation_Select_Helper
	ld	(0x3540:16), 7
AccPatch_CallParamLookup_Skip:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Return2
	cp	(SWBTWR_PAYLOAD_3:16), 0
	jr	z, AccPatch_CallParamLookup_Return2
	ld	a, (CURRENT_TITLE:16)
	cp	a, 184
	jr	nz, AccPatch_CallParamLookup_Return2
	call	TimeSig_DisplayStrings_Code_Sub
	call	AccPatch_ComplexDataBlock_Helper2
	call	RhythmVariation_Select_Helper
AccPatch_CallParamLookup_Return2:
	ret
AccDemo_InitDone_Helper:
	calr	AccPatch_CallParamLookup_Helper2
	ret
AccPatch_MultiCallWrapper_Helper:
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 0
	add	xiy, 0
	ld a, (xiy+0:8)
	cp a, 72
	jr	nz, AccPatch_CallParamLookup_Skip2
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip2
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip2
	jr	AccPatch_CallParamLookup_Return3
AccPatch_CallParamLookup_Skip2:
	call	AccDemo_Init_Wrap
AccPatch_CallParamLookup_Return3:
	ret
AccPatch_CallParamLookup_Helper2:
	add	xiy, 0
	add	xiy, 0
	ld a, (xiy+0:8)
	cp a, 72
	jr	nz, AccPatch_CallParamLookup_Entry
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Entry
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Entry
	call	AccPatch_CallParamLookup_Helper2_Helper
	jrl	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Entry:
	cp	(xiy), 76
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip
	cp	(xiy+1), 75
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip
	cp	(xiy+2), 69
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip
	call	AccPatch_CallParamLookup_Helper2_Helper
	call	AccPatch_ComplexDataBlock_Helper
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Helper2_Skip:
	ld a, (xiy+0:8)
	cp a, 71
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip2
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip2
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Helper2_Skip2
	call	AccPatch_CallParamLookup_Helper2_Helper
	call	AccPatch_ComplexDataBlock_Helper
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Helper2_Skip2:
	ld a, (xiy+0:8)
	cp a, 70
	jr	nz, AccPatch_CallParamLookup_Skip3
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip3
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip3
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip3:
	ld a, (xiy+0:8)
	cp a, 77
	jr	nz, AccPatch_CallParamLookup_Skip5
	ld	a, (xiy+1)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip5
	ld	a, (xiy+2)
	cp	a, 66
	jr	nz, AccPatch_CallParamLookup_Skip4
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip4:
	cp	a, 65
	jr	nz, AccPatch_CallParamLookup_Skip5
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip5:
	call	AccDemo_Init_Wrap
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Join:
	call	AccPatch_VoiceAssignDataBlock
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Return4:
	ret
AccPatch_CallParamLookup_Helper2_Helper:
	ret
AccPatch_ComplexDataBlock_Helper:
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 0
	add	xiy, 0
	ld	a, 72:opc
	ld	(xiy+0:8), a
	ld	a, 0:opc
	ld	(xiy+1), a
	ld	a, 75:opc
	ld	(xiy+2), a
	ret
	calr	AccPatch_GetCurrentSlotAddr
	calr	AccPatch_CopyDefaultsForInit
	calr	AccPatch_CallParamLookup_Helper3
	ret
AccPatch_CallParamLookup_Helper3:
	ld hl, (xiy+0:8)
	calr AccPatch_CallParamLookup_Helper4
	ld	hl, (xiy+4)
	calr	AccPatch_CallParamLookup_Helper4
	ld	hl, (xiy+6)
	calr	AccPatch_CallParamLookup_Helper4
	ld	hl, (xiy+8)
	calr	AccPatch_CallParamLookup_Helper4
	ld	hl, (xiy+10)
	calr	AccPatch_CallParamLookup_Helper4
	ret
AccPatch_CallParamLookup_Helper4:
	push	xiy
	calr	AccPatch_GetEntryAddr
	ldw (xix+3), 65535
	pushw	hl
	ld	l, (xiy+12)
	xor	h, h
	ld	xwa, 0:i3
	ld	xbc, AccTone_LookupByProgram_Table
	ld	a, (xbc+hl)
	ld xbc, 0:i3
	ld	b, (xiy+13)
	inc	1, b
	mul	wa, b
	popw	hl
	calr	AccPatch_GetEntryAddr
	add	xix, 6
	ld	l, 129:opc
AccPatch_CallParamLookup_Loop:
	ld	(xix), l
	dec	1, wa
	inc	1, xix
	cp	wa, 0:i3
	jr	nz, AccPatch_CallParamLookup_Loop
	ld	(xix), 131
	pop	xiy
	ret

AccPatch_FreeAllChains_Alt:
	ld hl, (xiy + 0:8)
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
	incw 1, (0x34d4:16)
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
	ld xhl, 0:i3
	popw hl
	sll xhl, 8
	ld xix, (0x39ae:16)
	add xix, 0x1400
	add xix, xhl
	popw hl

AccPatch_ResolveSlotAddr_Ret:
	ret

AccPatch_FillAllSlots_Alt:
	ld hl, (xiy + 0:8)
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
	ld xwa, 0:i3
	ld xbc, AccTone_LookupByProgram_Table
	ld	a, (xbc+hl)
	ld xbc, 0:i3
	ld b, (xiy + 13)
	inc 1, b
	mul wa, b
	popw hl
	calr AccPatch_ResolveSlotAddr
	add xix, 0x6
	ld l, 0x81:opc

AccPatch_FillSlot_Alt_Loop:
	ld (xix), l
	dec 1, wa
	inc 1, xix
	cp wa, 0:i3
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
	bit 0, (0x3616:16)
	jr nz, AccPatch_ScanSeq_StorePosAndRet
	jr AccPatch_ScanSeq_Loop

AccPatch_ScanSeq_StorePosAndRet:
	ld wa, (0x3612:16)
	ld (0x3606:16), wa
	ld wa, (0x3614:16)
	ld (0x3608:16), wa
	ret

AccPatch_SeqReadByte_Alt:
	push xix
	ld hl, (0x3612:16)
	calr AccPatch_ResolveSlotAddr
	ld hl, (0x3614:16)
	ld	a, (xix+hl)
	pop xix
	ret

AccPatch_SeqAdvance_Alt:
	ld wa, (0x3614:16)
	cp wa, 0xfe
	jr nz, AccPatch_SeqAdvance_Inc
	ld hl, (0x3612:16)
	calr AccPatch_ResolveSlotAddr
	ld wa, (xix + 3)
	ld (0x3612:16), wa
	cp wa, 0xffff
	jr nz, AccPatch_SeqAdvance_CheckLimit
	or (0x3616:16), 1

AccPatch_SeqAdvance_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_SeqAdvance_ResetBase
	or (0x3616:16), 1

AccPatch_SeqAdvance_ResetBase:
	ld wa, 6:i3
	jr AccPatch_SeqAdvance_Store

AccPatch_SeqAdvance_Inc:
	inc 1, wa

AccPatch_SeqAdvance_Store:
	ld (0x3614:16), wa
	ret

AccPatch_InitSlotPointer_Alt:
	xor xhl, xhl
	ld l, (0x39ac:16)
	cp l, 0x1e
	jr c, AccPatch_InitSlotAlt_Valid
	xor l, l

AccPatch_InitSlotAlt_Valid:
	mul hl, 0x60
	add xhl, 0x60
	ld xiy, (0x39ae:16)
	add xiy, xhl
	ld a, (0x379b:16)
	calr MapBitFlagsToChannelOffset
	ld	hl, (xiy+w)
	ld (0x3612:16), hl
	ldw (0x3614:16), 6
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
	ld hl, (0x3612:16)
	calr AccPatch_GetEntryAddr
	ld hl, (0x3614:16)
	ld	a, (xix+hl)
	pop xix
	ret

AccPatch_SeqDispatch_Padding:
	nop
	nop

AccPatch_AdvanceSeqIndex:
	ld wa, (0x3614:16)
	cp wa, 0xfe
	jr nz, AccPatch_AdvSeq_Inc
	ld hl, (0x3612:16)
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	ld (0x3612:16), wa
	cp wa, 0xffff
	jr nz, AccPatch_AdvSeq_CheckLimit
	or (0x3616:16), 1

AccPatch_AdvSeq_CheckLimit:
	cp wa, 0x154
	jr lt, AccPatch_AdvSeq_ResetBase
	or (0x3616:16), 1

AccPatch_AdvSeq_ResetBase:
	ld wa, 6:i3
	jr AccPatch_AdvSeq_Store

AccPatch_AdvSeq_Inc:
	inc 1, wa

AccPatch_AdvSeq_Store:
	ld (0x3614:16), wa
	ret

AccPatch_AdvSeq_Padding:
	nop
	nop

AccPatch_SeqDispatch_Main:
	ld a, (0x379b:16)
	cp a, (0x35fe:16)
	jr z, AccPatch_SeqDispatch_CheckEmpty
	calr AccPatch_ScanToSequenceStart
	calr AccPatch_InitAndLoadSequence

AccPatch_SeqDispatch_CheckEmpty:
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, AccPatch_SeqDispatch_CheckPlaying
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckPlaying:
	bit 0, (0x3283:16)
	jr nz, AccPatch_SeqDispatch_CheckStarted
	call TempoRingBuf_ReInitAndRet
	jrl AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_CheckStarted:
	bit 0, (0x3601:16)
	jr nz, AccPatch_SeqDispatch_ProcessFlags
	calr AccPatch_ResetSeqCounters
	calr AccPatch_InitCurrentSlotPointer
	ld wa, (0x3612:16)
	ld (0x3602:16), wa
	ld wa, (0x3614:16)
	ld (0x3604:16), wa

AccPatch_SeqDispatch_ProcessFlags:
	calr AccPatch_ReadModeFlags
	ld a, (0x34cf:16)
	and a, 0xc
	cp a, 0:i3
	jr nz, AccPatch_SeqDispatch_ModeChange
	ld a, (0x35fc:16)
	and a, 0xc
	cp a, 0:i3
	jr z, AccPatch_SeqDispatch_RunNotes

AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn

AccPatch_SeqDispatch_RunNotes:
	call AccPatch_CheckEmpty
	cp wa, 0:i3
	jr z, AccPatch_SyncStateAndReturn
	ldw (0x360a:16), 0
	ldw (0x360e:16), 0
	ld (0x35ff:16), 0
	calr AccPatch_EventDispatch_Nop
	cpw (0x360a:16), 0
	jr z, AccPatch_SeqDispatch_CheckQueued
	ld wa, (0x3602:16)
	ld (0x36fe:16), wa
	ld wa, (0x3604:16)
	ld (0x3700:16), wa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	ldw (0x360a:16), 0

AccPatch_SeqDispatch_CheckQueued:
	cpw (0x360e:16), 0
	jr z, AccPatch_SyncStateAndReturn
	calr AccPatch_DispatchQueuedNotes

AccPatch_SyncStateAndReturn:
	ld a, (0x379b:16)
	ld (0x35fe:16), a
	ret

AccPatch_SeqDispatch_MiscData:
	nop
	nop
	or	(0x34cf:16), 8
	ret
	.byte 0xc1, 0xcf
	ldw	ix, 0xf73c
	call	AccPatch_InitAndLoadSequence
	ret

AccPatch_ReadModeFlags:
	ld a, (0x34cf:16)
	and a, 0xf3
	ld (0x34cf:16), a
	cp (ACTIVE_TITLE:16), 181
	jr z, AccPatch_ReadModeFlags_Active
	jr AccPatch_SetFlagExit

AccPatch_ReadModeFlags_Active:
	ld xwa, (TRANSITION_PROGRESS:24)
	or xwa, (TRANSITION_TIMER:24)
	ld (4560:16), xwa
	ld xwa, (TRANSITION_TIMER:24)
	ld (0x39e0:16), xwa
	ld xwa, (4560:16)
	and xwa, 0x200
	cp xwa, 0x0
	jr z, AccPatch_ReadModeFlags_Check400
	ld xwa, (0x39e0:16)
	and xwa, 0x200
	cp xwa, 0x0
	jr nz, AccPatch_ReadModeFlags_Check400
	ld a, (0x34cf:16)
	or a, 0x4
	ld (0x34cf:16), a

AccPatch_ReadModeFlags_Check400:
	ld xwa, (4560:16)
	and xwa, 0x400
	cp xwa, 0x0
	jr z, AccPatch_SetFlagExit
	ld xwa, (0x39e0:16)
	and xwa, 0x400
	cp xwa, 0x0
	jr nz, AccPatch_SetFlagExit
	ld a, (0x34cf:16)
	or a, 0x8
	ld (0x34cf:16), a

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
	bit 0, (0x3616:16)
	jr nz, AccPatch_ScanSeq_StorePosition
	jr AccPatch_ScanSeq_ReadLoop

AccPatch_ScanSeq_StorePosition:
	ld wa, (0x3612:16)
	ld (0x3606:16), wa
	ld wa, (0x3614:16)
	ld (0x3608:16), wa
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
	djnz16 bc, AccPatch_InitSeq_ClearLoop
	ei 6
	bit 0, (0x364a:16)
	jr nz, AccPatch_InitSeq_LoadTempo
	call TempoRingBuf_ReInitAndRet

AccPatch_InitSeq_LoadTempo:
	ld a, (1077:16)
	ld c, (1046:16)
	ei 0
	and (0x364a:16), 254
	ld b, (0x34d9:16)
	mul wa, b
	add c, a
	xor b, b
	pushw bc
	calr AccPatch_InitCurrentSlotPointer
	popw bc
	cp bc, 0:i3
	jr z, AccPatch_InitSeq_AdvDone

AccPatch_InitSeq_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz16 bc, AccPatch_InitSeq_AdvLoop

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
	djnz16 bc, AccPatch_ResetSeqCounters_Loop
	ei 6
	ld a, (1077:16)
	ld c, (1046:16)
	ei 0
	and (0x364a:16), 254
	ld b, (0x34d9:16)
	mul wa, b
	add c, a
	xor b, b
	pushw bc
	call AccPatch_InitCurrentSlotPointer
	popw bc
	cp bc, 0:i3
	jr z, AccPatch_ResetSeqCounters_Done

AccPatch_ResetSeqCounters_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz16 bc, AccPatch_ResetSeqCounters_AdvLoop

AccPatch_ResetSeqCounters_Done:
	ret

AccPatch_ResetSeqCounters_AdvLoop_Pad:
	nop
	nop

AccPatch_ScanToSequenceEnd:
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ScanSeqEnd_HandleMarker
	calr AccPatch_AdvanceSeqIndex
	bit 0, (0x3616:16)
	jr nz, AccPatch_ScanDone
	jr AccPatch_ScanToSequenceEnd

AccPatch_ScanSeqEnd_HandleMarker:
	calr AccPatch_AdvanceSeqIndex
	bit 0, (0x3616:16)
	jr nz, AccPatch_ScanDone
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr nz, AccPatch_ScanDone
	calr AccPatch_MarkAllSlotsActive

AccPatch_ScanDone:
	ret

AccPatch_ScanDone_Pad:
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
	ld wa, (0x3612:16)
	ld (0x35da:16), wa
	ld wa, (0x3614:16)
	ld (0x35dc:16), wa
	ei 6
	ld a, (1077:16)
	ld (0x35f9:16), a
	ld wa, (1045:16)
	ld (0x3706:16), wa
	ei 0
	ld a, (0x34cf:16)
	ld w, (0x35fc:16)
	bit 2, a
	jr nz, AccPatch_UpdateSeqState_CheckXor
	bit 2, w
	jr nz, AccPatch_UpdateSeqState_CheckXor
	jr AccPatch_UpdateSeqState_CheckBit4

AccPatch_UpdateSeqState_CheckXor:
	ld c, a
	xor c, w
	and a, c
	cp a, 0:i3
	jr z, AccPatch_UpdateSeqState_AndCheck
	calr AccPatch_SeekToPosition
	or (0x35fd:16), 1
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_AndCheck:
	and w, c
	cp w, 0:i3
	jr z, AccPatch_UpdateSeqState_ResumeSeq
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_ResumeSeq:
	calr AccPatch_ResumeSequencePlayback
	jr AccPatch_LoadNextSequencePointers

AccPatch_UpdateSeqState_CheckBit4:
	bit 4, (0x379b:16)
	jr z, AccPatch_LoadNextSequencePointers
	ld a, (0x3558:16)
	ld (0x35fb:16), a
	bit 3, (0x34cf:16)
	jr z, AccPatch_UpdateSeqState_ClearBit7
	bit 7, (0x3558:16)
	jr nz, AccPatch_UpdateSeqState_ScanNoteOff
	calr AccPatch_ClearAndScanForNote
	jr AccPatch_UpdateSeqState_AfterScan

AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	and (0x3558:16), 127

AccPatch_UpdateSeqState_CompareBits:
	ld a, (0x3558:16)
	ld c, (0x35fb:16)
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
	ld wa, (0x35da:16)
	ld (0x3612:16), wa
	ld wa, (0x35dc:16)
	ld (0x3614:16), wa

AccPatch_UpdateSeqState_CheckBit3:
	bit 3, (0x34cf:16)
	jr nz, AccPatch_UpdateSeqState_StoreFlags
	bit 3, (0x35fc:16)
	jr z, AccPatch_UpdateSeqState_StoreFlags
	calr AccPatch_InitAndLoadSequence

AccPatch_UpdateSeqState_StoreFlags:
	ld a, (0x34cf:16)
	ld (0x35fc:16), a
	and (0x35fb:16), 253
	bit 0, (0x35fb:16)
	jr z, AccPatch_UpdateSeqState_Return
	or (0x35fb:16), 2

AccPatch_UpdateSeqState_Return:
	ret

AccPatch_UpdateSeqState_StoreFlags_Pad:
	nop
	nop

AccPatch_ClearAndScanForNote:
	and (0x3558:16), 127

AccPatch_ScanForActiveNote:
	call AccPatch_CheckEmpty
	cp wa, 0:i3
	jr z, AccPatch_ScanNote_Done
	ld bc, 1:i3
	calr TempoRingBuf_SkipBytes
	ld w, a
	and w, 0xf0
	cp w, 0x90
	jr nz, AccPatch_ScanNote_Continue
	ld bc, 2:i3
	calr TempoRingBuf_SkipBytes
	ld l, a
	push l
	ld bc, 1:i3
	calr TempoRingBuf_SkipBytes
	pop l
	cp a, 0:i3
	jr z, AccPatch_ScanNote_Continue
	or l, 0x80
	ld (0x3558:16), l
	call TempoRingBuf_ReInitAndRet

AccPatch_ScanNote_Continue:
	jr AccPatch_ScanForActiveNote

AccPatch_ScanNote_Done:
	ret

TempoRingBuf_SkipBytes:
	cp bc, 0:i3
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
	cp wa, 0:i3
	jr z, AccPatch_ScanForNoteOff_Done
	ld bc, 1:i3
	calr TempoRingBuf_SkipBytes
	ld w, a
	and w, 0xf0
	cp w, 0x90
	jr nz, AccPatch_ErrorExit
	ld bc, 2:i3
	calr TempoRingBuf_SkipBytes
	ld l, a
	ld h, (0x3558:16)
	and h, 0x7f
	cp h, l
	jr nz, AccPatch_ErrorExit
	ld bc, 1:i3
	calr TempoRingBuf_SkipBytes
	cp a, 0:i3
	jr nz, AccPatch_ErrorExit
	and (0x3558:16), 127
	call TempoRingBuf_ReInitAndRet

AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	calr AccPatch_SeekForwardSteps
	ld a, (0x3706:16)
	ld (0x36f8:16), a
	calr AccPatch_ParseSequenceHeader
	ld wa, (0x3612:16)
	ld (0x35de:16), wa
	ld wa, (0x3614:16)
	ld (0x35e0:16), wa
	ret

AccPatch_SeekForwardSteps:
	ld a, (0x35f9:16)
	ld c, (0x3707:16)
	ld b, (0x34d9:16)
	mul wa, b
	add c, a
	xor b, b
	pushw bc
	calr AccPatch_InitCurrentSlotPointer
	popw bc
	cp bc, 0:i3
	jr z, AccPatch_SeekFwd_Done

AccPatch_SeekFwd_AdvLoop:
	pushw bc
	calr AccPatch_ScanToSequenceEnd
	popw bc
	djnz16 bc, AccPatch_SeekFwd_AdvLoop

AccPatch_SeekFwd_Done:
	ret

AccPatch_SeekFwd_AdvLoop_Pad:
	nop
	nop

AccPatch_ParseSequenceHeader:
	ld wa, (0x3612:16)
	ld (0x36fa:16), wa
	ld wa, (0x3614:16)
	ld (0x36fc:16), wa
	calr AccPatch_SeqReadByte
	cp a, 0x81
	jr z, AccPatch_ParseHdr_RestorePos
	cp a, 0x83
	jr nz, AccPatch_ParseHdr_AdvanceAndCompare
	or (0x3616:16), 2
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_AdvanceAndCompare:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cp a, (0x36f8:16)
	jr ugt, AccPatch_ParseHdr_RestorePos

AccPatch_ParseHdr_AdvanceAndRead:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	bit 0, (0x3616:16)
	jr z, AccPatch_ParseHdr_CheckBit7
	jr AccPatch_ParseHdr_Return

AccPatch_ParseHdr_CheckBit7:
	bit 7, a
	jr z, AccPatch_ParseHdr_AdvanceAndRead
	jr AccPatch_ParseSequenceHeader

AccPatch_ParseHdr_RestorePos:
	ld wa, (0x36fa:16)
	ld (0x3612:16), wa
	ld wa, (0x36fc:16)
	ld (0x3614:16), wa

AccPatch_ParseHdr_Return:
	ret

AccPatch_ParseHdr_RestorePos_Pad:
	nop
	nop

AccPatch_ResumeSequencePlayback:
	and (0x35fd:16), 254
	calr AccPatch_PrepareSequencePlayback
	ld wa, (0x35de:16)
	ld (0x3612:16), wa
	ld wa, (0x35e0:16)
	ld (0x3614:16), wa
	ldw (0x360a:16), 0

AccPatch_ResumeSeq_ComparePos:
	ld wa, (0x3612:16)
	cp wa, (0x35e2:16)
	jr nz, AccPatch_ResumeSeq_ReadByte
	ld wa, (0x3614:16)
	cp wa, (0x35e4:16)
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
	ld bc, 6:i3
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip8:
	ldw bc, 0x8
	jr AccPatch_ResumeSeq_AddAndAdvance

AccPatch_ResumeSeq_Skip3:
	ld bc, 3:i3

AccPatch_ResumeSeq_AddAndAdvance:
	add (0x360a:16), bc

AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz16 bc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	calr AccPatch_CheckSequenceChanged
	calr AccPatch_AdvanceSeqIndex
	ld wa, (0x3612:16)
	ld (0x35de:16), wa
	ld wa, (0x3614:16)
	ld (0x35e0:16), wa
	calr AccPatch_SeqReadByte
	cp a, 0x83
	jr z, AccPatch_ResumeSeq_InitSlot
	cpw (0x360a:16), 0
	jr z, AccPatch_ResumeSeq_LoopBack
	calr AccPatch_PrepareSequencePlayback
	ldw (0x360a:16), 0

AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	calr AccPatch_InitCurrentSlotPointer
	ld wa, (0x3612:16)
	ld (0x35de:16), wa
	ld wa, (0x3614:16)
	ld (0x35e0:16), wa

AccPatch_ResumeSeq_Return:
	ret

AccPatch_ResumeSeq_InitSlot_Pad:
	nop
	nop

AccPatch_PrepareSequencePlayback:
	calr AccPatch_SeekForwardSteps
	ld a, (0x3706:16)
	ld (0x36f8:16), a
	calr AccPatch_ParseSequenceHeader
	ld wa, (0x3612:16)
	ld (0x35e2:16), wa
	ld wa, (0x3614:16)
	ld (0x35e4:16), wa
	ret

AccPatch_CheckSequenceChanged:
	cpw (0x360a:16), 0
	jr z, AccPatch_CheckChanged_Return
	ld wa, (0x35de:16)
	ld (0x365a:16), wa
	ld wa, (0x35e0:16)
	ld (0x3660:16), wa
	ld wa, (0x3612:16)
	ld (0x3658:16), wa
	ld wa, (0x3614:16)
	ld (0x365e:16), wa
	ld wa, (0x365a:16)
	cp wa, (0x3658:16)
	jr nz, AccPatch_CheckChanged_DoCopy
	ld wa, (0x3660:16)
	cp wa, (0x365e:16)
	jr nz, AccPatch_CheckChanged_DoCopy
	jr AccPatch_CheckChanged_Return

AccPatch_CheckChanged_DoCopy:
	calr AccPatch_CopySequenceEntry
	calr AccPatch_UpdateEntryFromTable
	ld wa, (0x35de:16)
	ld (0x3612:16), wa
	ld wa, (0x35e0:16)
	ld (0x3614:16), wa

AccPatch_CheckChanged_Return:
	ret

AccPatch_CheckChanged_DoCopy_Pad:
	nop
	nop

AccPatch_CopySequenceEntry:
	ld de, (0x3606:16)
	ld wa, (0x3608:16)
	ld (0x3662:16), wa
	ld hl, (0x3658:16)
	calr AccPatch_GetEntryAddr
	ld (0x3650:16), xix
	ld hl, (0x365a:16)
	calr AccPatch_GetEntryAddr
	ld (0x364c:16), xix
	calr AccPatch_SetupBlockCopyDispatch
	dec 1, ix
	ld (0x3704:16), ix
	ld wa, (0x365a:16)
	cp wa, (0x3606:16)
	jr z, AccPatch_CopyEntry_Store
	incw 1, (0x34d4:16)
	ld hl, (0x365a:16)
	calr AccPatch_GetEntryAddr
	ld wa, (xix + 3)
	ldw (xix + 3), 0xffff
	ld hl, wa
	calr AccPatch_GetEntryAddr
	andmi8 (xix), 0x7f
	ldw (xix + 1), 0xffff

AccPatch_CopyEntry_Store:
	ld wa, (0x365a:16)
	ld (0x3606:16), wa
	ld wa, (0x3704:16)
	ld (0x3608:16), wa
	ret

AccPatch_CopyEntry_Store_Pad:
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
	cp hl, (0x35de:16)
	jr z, AccPatch_UpdateEntry_CheckDE
	cpw (xix + 1), 0xffff
	jr z, AccPatch_NullRet
	calr AccPatch_AdjustTableEntryPos
	jr AccPatch_NullRet

AccPatch_UpdateEntry_CheckDE:
	cp de, (0x35e0:16)
	jr nc, AccPatch_UpdateEntry_AdjustOffset
	jr AccPatch_NullRet

AccPatch_UpdateEntry_AdjustOffset:
	sub de, (0x360a:16)
	cp de, 6:i3
	jr z, AccPatch_UpdateEntry_StoreDirect
	jr ugt, AccPatch_UpdateEntry_StoreDirect
	ld hl, 6:i3
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

AccPatch_NullRet_Pad:
	nop
	nop

AccPatch_LoadTablePointers:
	push xbc
	ld xbc, 0:i3
	ld c, (0x379b:16)
	sll bc, 2
	push xbc
	add xbc, AccPatch_LoadTablePointers_Data_2
	ld xix, xbc
	ld xix, (xix)
	pop xbc
	ld xiy, AccPatch_LoadTablePointers_Data
	add xiy, xbc
	ld xiy, (xiy)
	pop xbc
	ret

AccPatch_AdjustTableEntryPos:
	calr AccPatch_LoadTablePointers
	ld de, (xix)
	ld wa, (xiy)
	sub de, 0x6
	cp de, (0x360a:16)
	jr c, AccPatch_AdjustEntry_Overflow
	sub de, (0x360a:16)
	add de, 0x6
	ld (xix), de
	jr AccPatch_AdjustEntry_Return

AccPatch_AdjustEntry_Overflow:
	ld hl, (0x360a:16)
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
	ld wa, (0x35de:16)
	ld (0x3612:16), wa
	ld wa, (0x35e0:16)
	ld (0x3614:16), wa

AccPatch_ProcessSequenceEvents:
	ld wa, (0x3612:16)
	cp wa, (0x35e2:16)
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	ld wa, (0x3614:16)
	cp wa, (0x35e4:16)
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	jrl AccPatch_ProcessSeqEvt_StorePos

AccPatch_ProcessSeqEvt_SavePos:
	ld wa, (0x3612:16)
	ld (0x36fa:16), wa
	ld wa, (0x3614:16)
	ld (0x36fc:16), wa
	calr AccPatch_SeqReadByte
	ld (0x36f9:16), a
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
	ld (0x35fa:16), a
	ld bc, 6:i3
	cp (0x36f9:16), 145
	jr z, AccPatch_ProcessSeqEvt_AdvLoop
	ld bc, 4:i3

AccPatch_ProcessSeqEvt_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz16 bc, AccPatch_ProcessSeqEvt_AdvLoop
	ld a, (0x35fa:16)
	ld b, (0x3558:16)
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
	ld bc, 3:i3

AccPatch_ProcessSeqEvt_SkipDLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz16 bc, AccPatch_ProcessSeqEvt_SkipDLoop
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_SetSize:
	ldw (0x360a:16), 8
	cp (0x36f9:16), 145
	jr z, AccPatch_ProcessSeqEvt_StoreAndPrep
	ldw (0x360a:16), 6

AccPatch_ProcessSeqEvt_StoreAndPrep:
	ld wa, (0x36fa:16)
	ld (0x35de:16), wa
	ld wa, (0x36fc:16)
	ld (0x35e0:16), wa
	calr AccPatch_CheckSequenceChanged
	ldw (0x360a:16), 0
	calr AccPatch_PrepareSequencePlayback
	jrl AccPatch_ProcessSequenceEvents

AccPatch_ProcessSeqEvt_InitSlot:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ProcessSeqEvt_StorePos:
	ld wa, (0x3612:16)
	ld (0x35de:16), wa
	ld wa, (0x3614:16)
	ld (0x35e0:16), wa
	ret

AccPatch_ProcessSeqEvt_RetNop:
	ret

AccPatch_EventDispatch_Nop:
	nop

AccPatch_EventDispatchLoop:
	call AccPatch_CheckEmpty
	cp wa, 0:i3
	jr nz, AccPatch_EventDispatch_ReadCmd
	jrl AccPatch_EventDispatch_Done

AccPatch_EventDispatch_ReadCmd:
	call TempoRingBuf_PeekByte
	cp a, 0x81
	jr z, AccPatch_EventDispatch_EndMarker
	ld w, 0xf0:opc
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
	ld bc, 5:i3
	calr AccPatch_ReadRingBufBytes
	cp (0x36ed:16), 0
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
	bit 1, (0x364a:16)
	jr nz, AccPatch_EventDispatch_AdvSlots
	calr AccPatch_ScanToSequenceEnd

AccPatch_EventDispatch_AdvSlots:
	calr AccPatch_AdvanceSlotCounters
	and (0x364a:16), 253
	jr AccPatch_ContinueProcessing

AccPatch_ProcessMarkerCommand:
	ld bc, 3:i3
	calr AccPatch_ReadRingBufBytes
	calr AccPatch_ParseAndResolve
	calr AccPatch_ProcessMarkerEvent
	jr AccPatch_ContinueProcessing

AccPatch_ContinueProcessing:
	jrl AccPatch_EventDispatchLoop

AccPatch_EventDispatch_Done:
	ret

AccPatch_ContinueProcessing_Pad:
	nop
	nop

AccPatch_UpdatePlayback:
	cpw (0x360a:16), 0
	jr z, AccPatch_UpdatePlayback_CheckQueue
	ld wa, (0x3602:16)
	ld (0x36fe:16), wa
	ld wa, (0x3604:16)
	ld (0x3700:16), wa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	ldw (0x360a:16), 0

AccPatch_UpdatePlayback_CheckQueue:
	cpw (0x360e:16), 0
	jr z, AccPatch_UpdatePlayback_ClearStep
	calr AccPatch_DispatchQueuedNotes

AccPatch_UpdatePlayback_ClearStep:
	ld (0x35ff:16), 0
	ret

AccPatch_UpdatePlayback_ClearStep_Pad:
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

AccPatch_AdvSlotCtr_Store_Pad:
	nop
	nop

AccPatch_ReadRingBufBytes:
	ld xhl, 0:i3

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
	ld	(xiz+hl), a
	inc 1, hl
	jr AccPatch_ReadBuf_Loop

AccPatch_ReadBuf_Done:
	ret

AccPatch_ReadBuf_StoreAndNext_Pad:
	nop
	nop

AccPatch_ParseAndResolve:
	ld a, (0x36eb:16)
	ld (0x36f7:16), a
	ld (0x36f8:16), a
	calr AccPatch_LookupStepByDrumParam
	cp (0x35ff:16), 0
	jr z, AccPatch_ParseResolve_ParseHdr
	ld a, (0x3600:16)
	cp a, (0x36f8:16)
	jr z, AccPatch_ParseResolve_IncStep
	calr AccPatch_UpdatePlayback

AccPatch_ParseResolve_ParseHdr:
	calr AccPatch_ParseSequenceHeader
	ld wa, (0x3612:16)
	ld (0x3602:16), wa
	ld wa, (0x3614:16)
	ld (0x3604:16), wa

AccPatch_ParseResolve_IncStep:
	inc 1, (0x35ff:16)
	ld a, (0x36f8:16)
	ld (0x3600:16), a
	ret

AccPatch_ParseResolve_IncStep_Pad:
	nop
	nop

AccPatch_LookupStepByDrumParam:
	xor w, w
	ld iy, wa
	ld a, (0x34db:16)
	cp a, 0:i3
	jr z, AccPatch_SetStepDone
	ld wa, iy
	ld w, (0x34db:16)
	and w, 0x7
	call DrumParam_Wrapper
	cp a, 0x7f
	jr nz, AccPatch_LookupStep_StoreResult
	ld a, 0x0:opc
	ld (0x36f8:16), a
	ld (0x36eb:16), a
	bit 1, (0x364a:16)
	jr nz, AccPatch_SetStepDone
	or (0x364a:16), 2
	calr AccPatch_UpdatePlayback
	calr AccPatch_ScanToSequenceEnd
	jr AccPatch_SetStepDone

AccPatch_LookupStep_StoreResult:
	ld (0x36f8:16), a
	ld (0x36eb:16), a

AccPatch_SetStepDone:
	ret

AccPatch_SetStepDone_Pad:
	nop
	nop

AccPatch_CopyNoteStepsToSlots:
	ld xhl, 0x361a
	xor iy, iy

AccPatch_CopySteps_FindFreeSlot:
	bit	7, (xhl+iy)
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	ld de, iy
	cpw (0x34d4:16), 0
	jr z, AccPatch_CopySteps_Overflow
	ld (0x3431:16), 0
	ld (0x36ea:16), 144
	bit 4, (0x379b:16)
	jr nz, AccPatch_CopySteps_StartFetch
	calr AccPatch_TransposeNote

AccPatch_CopySteps_StartFetch:
	ld a, (0x36ea:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36eb:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36ec:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_UpdateSlotVoiceData
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36ed:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, 0x10:opc
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, 0x0:opc
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	bit 0, (0x3431:16)
	jr z, AccPatch_CopyStepsDone
	ld a, (0x36f0:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36f1:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	ld (GLOBAL_ERROR_CODE:16), 15
	call DrumVoice_NotifyEE
	ld a, 0x8:opc
	call MIDI_SendSysExCmd
	jr AccPatch_CopyStepsDone

AccPatch_TransposeNote:
	ld a, (0x34e9:16)
	and a, 0xf
	cp a, 0:i3
	jr z, AccPatch_Transpose_LookupTable
	calr AccPatch_ReadTransposeAmount
	cp a, (0x3a4e:16)
	jr ugt, AccPatch_Transpose_AddBack
	sub (0x36ec:16), a
	jr nc, AccPatch_Transpose_Done
	ld a, 0xc:opc
	add (0x36ec:16), a

AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	ld w, 0xc:opc
	sub w, a
	add (0x36ec:16), w

AccPatch_Transpose_LookupTable:
	ld xhl, 0:i3
	ld l, (0x36ec:16)
	add xhl, AccPatch_Transpose_LookupTable_Data
	ld a, (xhl)
	bit 4, (0x34ea:16)
	jr z, AccPatch_Transpose_CheckBit6
	ld w, a
	ld xhl, 0:i3
	ld l, a
	add xhl, AccPatch_Transpose_LookupTable_Data_2
	ld l, (xhl)
	bit 0, l
	jr z, AccPatch_Transpose_CheckBit6
	inc 1, w
	ld a, (0x36ec:16)
	inc 1, a
	ld (0x36ec:16), a
	ld a, w

AccPatch_Transpose_CheckBit6:
	bit 6, (0x34ea:16)
	jr z, AccPatch_Transpose_CheckBit5
	bit 3, (0x379b:16)
	jr z, AccPatch_Transpose_CheckBit5
	jr AccPatch_Transpose_SetDrumSplit

AccPatch_Transpose_CheckBit5:
	bit 5, (0x34ea:16)
	jr z, AccPatch_StoreDrumParams
	bit 3, (0x379b:16)
	jr nz, AccPatch_StoreDrumParams

AccPatch_Transpose_SetDrumSplit:
	cp a, 7:i3
	jr nz, AccPatch_StoreDrumParams
	ld (0x3431:16), 1
	ld (0x36f0:16), 3
	ld (0x36f1:16), 0
	jr AccPatch_StoreDrumParams_CheckSplit

AccPatch_StoreDrumParams:
	ld xhl, 0:i3
	ld l, a
	sll a, 1
	add l, a
	add xhl, AccPatch_StoreDrumParams_Data
	ld a, (xhl)
	ld (0x3431:16), a
	ld a, (xhl + 1)
	ld (0x36f0:16), a
	ld a, (xhl + 2)
	ld (0x36f1:16), a

AccPatch_StoreDrumParams_CheckSplit:
	bit 0, (0x3431:16)
	jr z, AccPatch_StoreDrumParams_Return
	ld (0x36ea:16), 145

AccPatch_StoreDrumParams_Return:
	ret

AccPatch_TransposeNoteTable:
; AccPatch_TransposeNoteTable -- two small tables read by the transpose path.
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/normal/scf mnemonics plus
; .zero/.byte fragments (data-as-code).  Readers:
;   AccPatch_Transpose_LookupTable: A = byte (0x36ec) of
;       AccPatch_Transpose_LookupTable_Data, then ld l,a / add xhl,
;       AccPatch_Transpose_LookupTable_Data_2 / ld l,(xhl) / bit 0,l -- when set, A
;       and (0x36ec) are incremented by one.
;   AccPatch_StoreDrumParams: ld l,a / sll a,1 / add l,a (l = 3a) / add xhl,
;       AccPatch_StoreDrumParams_Data, then (xhl), (xhl+1), (xhl+2) are
;       stored to (0x3431), (0x36f0), (0x36f1); bit 0 of (0x3431) then selects
;       `ld (0x36ea), 145`.
; Sizes: the +0x0E records are 3 bytes (the `3a` index) and 12 of them end
; exactly at AccPatch_ReadTransposeAmount; the flag table is the 12 bytes
; between the two reader offsets.  Only index 3 of the flag table and
; records 3, 4 and 11 are non-zero.
; readers in v9/v10 (address from the linked ELF): AccPatch_Transpose_LookupTable 0xF60874,
;     AccPatch_StoreDrumParams 0xF608D8
; +0x00  2 B, not addressed by either reader
	.byte 0x00, 0x00
; +0x02  12 x u8, flag byte per index (bit 0 tested)
AccPatch_Transpose_LookupTable_Data_2:
	.byte 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x0E  12 x 3-byte records {(0x3431), (0x36f0), (0x36f1)}
AccPatch_StoreDrumParams_Data:
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x11
	.byte 0x01, 0x00, 0x11
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x01, 0x11, 0x11

AccPatch_ReadTransposeAmount:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	call AccPatch_GetCurrentSlotAddr
	ld a, (0x379b:16)
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
	ld (0x3a4e:16), a
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
	ld hl, (0x360a:16)
	ld	(xiy+hl), a
	inc 1, hl
	ld (0x360a:16), hl
	ret

AccPatch_FetchStepData:
	ld	xiy, 0x36aa
	ld	hl, (0x360e:16)
	ld	(xiy+hl), a
	inc	1, hl
	ld	(0x360e:16), hl
	ret
AccPatch_SeqAdvanceStep:
	ld wa, (0x3614:16)
	cp wa, 0xfe
	jr nz, AccPatch_SeqAdvStep_Increment
	cpw (0x34d4:16), 0
	jr z, AccPatch_SeqAdvStep_Return
	calr AccPatch_SeqAdvStep_WrapToNext
	jr AccPatch_SeqAdvStep_Return

AccPatch_SeqAdvStep_Increment:
	inc 1, wa
	ld (0x3614:16), wa

AccPatch_SeqAdvStep_Return:
	ret

AccPatch_SeqAdvStep_WrapToNext:
	ld hl, (0x3612:16)
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
	ld (0x3612:16), hl
	ldw (0x3614:16), 6
	ret

AccPatch_SeqAdvStep_StorePos_Pad:
	nop
	nop

AccPatch_UpdateSlotVoiceData:
	ld xhl, 0x361a
	ld iy, de
	or a, 0x80
	ld	(xhl+iy), a
	pushw iy
	inc 1, iy
	ld	(xhl+iy), 0x00
	ld a, (0x36f7:16)
	inc 1, iy
	ld	(xhl+iy), a
	ld wa, (0x3612:16)
	inc 1, iy
	ld	(xhl+iy), wa
	ld wa, (0x3614:16)
	inc 2, iy
	ld	(xhl+iy), a
	popw iy
	ret

AccPatch_TransposeAndCopyNote:
	bit 4, (0x379b:16)
	jr nz, AccPatch_TransposeCopy_DoCopy
	calr AccPatch_TransposeNote

AccPatch_TransposeCopy_DoCopy:
	ld xiy, 0x36ea
	ld xix, 0x36aa
	ld xbc, 0:i3
	ld bc, (0x360e:16)
	add xix, xbc
	ld bc, 6:i3
	ldir85
	addw (0x360e:16), 6
	ret

AccPatch_TransposeCopy_DoCopy_Pad:
	nop
	nop

AccPatch_ProcessMarkerEvent:
	cpw (0x34d4:16), 0
	jr z, AccPatch_ProcessMarker_Return
	ld a, (0x36ea:16)
	cp a, 0xd4
	jr nz, AccPatch_ProcessMarker_CheckD3
	ld a, 0xd3:opc
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD3:
	cp a, 0xd3
	jr nz, AccPatch_ProcessMarker_CheckD5
	ld a, 0xd5:opc
	jr AccPatch_FetchSequence

AccPatch_ProcessMarker_CheckD5:
	cp a, 0xd5
	jr nz, AccPatch_FetchSequence
	ld a, 0xd4:opc
	jr AccPatch_FetchSequence

AccPatch_FetchSequence:
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36eb:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep
	ld a, (0x36ec:16)
	calr AccPatch_FetchStepEntry
	calr AccPatch_SeqAdvanceStep

AccPatch_ProcessMarker_Return:
	ret

AccPatch_FetchSequence_Pad:
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
AccPatch_SkipToMarker_Loop2:
	pushw	bc
	call	TempoRingBuf_ReadByteToA
	popw	bc
	dec	1, bc
	cp	bc, 0:i3
	jr	nz, AccPatch_SkipToMarker_Loop2
	ret
	ldw	(0x3610:16), 0
AccPatch_SkipToMarker_Loop:
	ld	xix, 0x36aa
	add ix, (13840:16)
	calr AccPatch_DispatchNoteToVoice
	ld	wa, (0x3610:16)
	add	wa, 6
	ld	(0x3610:16), wa
	cp wa, (13838:16)
	jr c, AccPatch_SkipToMarker_Loop
	ldw	(0x360e:16), 0
	ret

AccPatch_InitSlotAndCopyData:
	ld xhl, 0:i3
	ld l, (0x34d6:16)
	call AccPatch_GetCurrentSlotAddr
	andmi8 (xiy + 15), 0x7f
	ld de, (0x3602:16)
	ld hl, (0x3606:16)
	ld (0x3658:16), hl
	calr AccPatch_GetEntryAddr
	ld (0x3650:16), xix
	ld wa, (0x3608:16)
	ld (0x365e:16), wa
	ldw bc, 0xfe
	sub bc, wa
	ld (0x3702:16), bc
	cp bc, (0x360a:16)
	jr nc, AccPatch_InitSlot_SameBlock
	jr AccPatch_InitSlot_CrossBlock

AccPatch_InitSlot_SameBlock:
	ld hl, (0x3606:16)
	ld (0x365a:16), hl
	calr AccPatch_GetEntryAddr
	ld (0x364c:16), xix
	ld wa, (0x3608:16)
	add wa, (0x360a:16)
	ld (0x3660:16), wa
	jr AccPatch_InitSlot_StoreAddrs

AccPatch_InitSlot_CrossBlock:
	calr AccPatch_FindFreeEntrySlot
	ld (0x365a:16), wa
	ld hl, wa
	calr AccPatch_GetEntryAddr
	ld (0x364c:16), xix
	ld wa, (0x360a:16)
	sub wa, (0x3702:16)
	add wa, 0x5
	ld (0x3660:16), wa

AccPatch_InitSlot_StoreAddrs:
	ld wa, (0x365a:16)
	ld (0x3606:16), wa
	ld wa, (0x3660:16)
	ld (0x3608:16), wa
	calr AccPatch_CalcBlockCopySetup
	inc 1, ix
	ld (0x3704:16), ix
	ld hl, (0x3602:16)
	calr AccPatch_GetEntryAddr
	ld xwa, 0:i3
	ld wa, (0x3604:16)
	add xix, xwa
	ld xiy, 0x366a
	ld xbc, 0:i3
	ldw bc, 0xfe
	sub bc, (0x3604:16)
	inc 1, bc
	cp bc, (0x360a:16)
	jr c, AccPatch_InitSlot_SplitCopy
	ld xbc, 0:i3
	ld bc, (0x360a:16)
	ldir85
	jr AccPatch_InitSlot_Finalize

AccPatch_InitSlot_SplitCopy:
	ld wa, bc
	ldir85
	ld xbc, 0:i3
	ld bc, (0x360a:16)
	sub bc, wa
	ld hl, (0x3602:16)
	calr AccPatch_GetEntryAddr
	ld hl, (xix + 3)
	calr AccPatch_GetEntryAddr
	add xix, 0x6
	cp bc, 0:i3
	jr z, AccPatch_InitSlot_Finalize
	ldir85

AccPatch_InitSlot_Finalize:
	ld wa, (0x365a:16)
	ld (0x3602:16), wa
	ld wa, (0x3704:16)
	ld (0x3604:16), wa
	ret

AccPatch_InitSlot_Finalize_Pad:
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
	ld hl, (0x3606:16)
	pushw wa
	calr AccPatch_GetEntryAddr
	popw wa
	ld (xix + 3), wa
	pop xix
	ormi8 (xix), 0x80
	ld bc, (0x3606:16)
	ld (xix + 1), bc
	ldw (xix + 3), 0xffff
	decw 1, (0x34d4:16)
	ret

AccPatch_FindFreeSlot_Found_Pad:
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
	cp hl, (0x36fe:16)
	jr z, AccPatch_AdvPlayPos_CheckDE
	cpw (xix + 1), 0xffff
	jr nz, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_CheckDE:
	cp de, (0x3700:16)
	jr nc, AccPatch_AdvPlayPos_AddAndCheck
	jr AccPatch_StoreEntryPtr

AccPatch_AdvPlayPos_AddAndCheck:
	add de, (0x360a:16)
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
; AccPatch_AdvPlayPos_DataBlock -- two parallel 17-entry tables of RAM
; pointers, indexed by the one-hot selector (0x379b).
; ** RE-TYPED 2026-09-25 (lane accomp): was `.byte 0x9d` / `ldw de, 0` / nop
; runs (data-as-code).  Read by AccPatch_LoadTablePointers:
;     ld c,(0x379b) / sll bc,2 / add xbc, AccPatch_LoadTablePointers_Data_2 /
;     ld xix,(xbc) ... ld xiy, AccPatch_LoadTablePointers_Data / add xiy,xbc /
;     ld xiy,(xiy)
; so entry (0x379b) of each table is a 32-bit pointer.  Only the one-hot
; entries 1, 2, 4, 8 and 16 are non-zero (v9/v10: +0x07 gives 0x329D, 0x329F,
; 0x32A1, 0x329B, 0x3297 and +0x4B gives 0x328D, 0x328F, 0x3291, 0x328B,
; 0x3287) -- word variables two bytes apart, which AccPatch_AdjustTableEntryPos and its
; siblings then read and update through (xix)/(xiy).  17 entries each: the
; +0x4B reader offset minus +0x07 is 68 = 17*4, and 17*4 more bytes end
; exactly at AccPatch_AdvanceAllSteps.
; readers in v9/v10 (address from the linked ELF): AccPatch_LoadTablePointers 0xF604BD
; +0x00  7 zero bytes, not addressed by the reader
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x07  17 x LE32 -> XIY (RAM addresses)
AccPatch_LoadTablePointers_Data:
	.long 0x00000000, 0x0000329d, 0x0000329f, 0x00000000
	.long 0x000032a1, 0x00000000, 0x00000000, 0x00000000
	.long 0x0000329b, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x00003297
; +0x4B  17 x LE32 -> XIX (RAM addresses)
AccPatch_LoadTablePointers_Data_2:
	.long 0x00000000, 0x0000328d, 0x0000328f, 0x00000000
	.long 0x00003291, 0x00000000, 0x00000000, 0x00000000
	.long 0x0000328b, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x00003287

AccPatch_AdvanceAllSteps:
	ld xix, 0x361a

AccPatch_AdvAllSteps_Loop:
	bitm 7, (xix + 1)
	jr z, AccPatch_AdvAllSteps_Next
	ld bc, (0x360a:16)

AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz16 bc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	add xix, 0x6
	cp xix, 0x364a
	jr c, AccPatch_AdvAllSteps_Loop
	ret

AccPatch_AdvAllSteps_InnerLoop_Pad:
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
	ld wa, 6:i3
	jr AccPatch_AdvSingleStep_Store

AccPatch_AdvSingleStep_Inc:
	inc 1, wa

AccPatch_AdvSingleStep_Store:
	ld (xix + 5), a
	ret

AccPatch_AdvSingleStep_Store_Pad:
	nop
	nop

AccPatch_DispatchQueuedNotes:
	ld xix, 0x36aa

AccPatch_DispatchQueued_Loop:
	calr AccPatch_DispatchNoteToVoice
	add xix, 0x6
	ld xwa, xix
	sub xwa, 0x36aa
	cp wa, (0x360e:16)
	jr c, AccPatch_DispatchQueued_Loop
	ldw (0x360e:16), 0
	ret

AccPatch_DispatchQueuedNotes_Pad:
	nop
	nop

AccPatch_DispatchNoteToVoice:
	ld xhl, 0x361a
	ldw iy, 0x2a

AccPatch_DispatchNote_Loop:
	bit	7, (xhl+iy)
	jr z, AccPatch_DispatchNote_NextSlot
	ld	a, (xhl+iy)
	and a, 0x7f
	cp a, (xix + 2)
	jr nz, AccPatch_DispatchNote_NextSlot
	and	(xhl+iy), 0x7f
	inc 1, iy
	and	(xhl+iy), 0x7f
	ld	d, (xhl+iy)
	inc 1, iy
	ld	a, (xhl+iy)
	ld c, (xix + 1)
	cp c, a
	jr nc, AccPatch_DispatchNote_CalcVelocity
	add c, 0x60
	cp d, 0:i3
	jr z, AccPatch_DispatchNote_CalcVelocity
	dec 1, d

AccPatch_DispatchNote_CalcVelocity:
	sub c, a
	ld a, c
	calr AccPatch_WriteVelocityToSeq
	jr AccPatch_DispatchNote_Return

AccPatch_DispatchNote_NextSlot:
	sub iy, 0x6
	cp iy, 0:i3
	jr lt, AccPatch_DispatchNote_Return
	jr AccPatch_DispatchNote_Loop

AccPatch_DispatchNote_Return:
	ret

AccPatch_DispatchNote_NextSlot_Pad:
	nop
	nop

AccPatch_WriteVelocityToSeq:
	pushw de
	pushw wa
	ld wa, (0x3612:16)
	ld (0x36fa:16), wa
	ld wa, (0x3614:16)
	ld (0x36fc:16), wa
	inc 1, iy
	ld	wa, (xhl+iy)
	ld (0x3612:16), wa
	pushw iy
	inc 2, iy
	xor wa, wa
	ld	a, (xhl+iy)
	popw iy
	ld (0x3614:16), wa
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
	ld wa, (0x36fa:16)
	ld (0x3612:16), wa
	ld wa, (0x36fc:16)
	ld (0x3614:16), wa
	ret

AccPatch_WriteVel_RestorePos_Pad:
	nop
	nop

AccPatch_WriteSeqByte:
	push xix
	ld hl, (0x3612:16)
	calr AccPatch_GetEntryAddr
	push xwa
	ld xwa, 0:i3
	ld wa, (0x3614:16)
	add xix, xwa
	pop xwa
	ld (xix), a
	pop xix
	ret

AccPatch_WriteSeqByte_Pad:
	nop
	nop

AccPatch_CalcBlockCopySetup:
	ld (GLOBAL_ERROR_CODE:16), 0
	cp de, (0x3658:16)
	jr nz, AccPatch_CalcBlockCopy_DiffEntry
	ld iy, (0x365e:16)
	sub iy, 0x6
	inc 1, iy
	ld (0x3664:16), iy
	ld iy, (0x365e:16)
	ld ix, (0x3660:16)
	sub ix, 0x6
	inc 1, ix
	ld (0x3666:16), ix
	ld ix, (0x3660:16)
	calr AccPatch_CalcBlockCopyBounds
	jr AccPatch_CalcBlockCopy_Done

AccPatch_CalcBlockCopy_DiffEntry:
	ld wa, (0x3660:16)
	cp wa, (0x365e:16)
	jr ugt, AccPatch_CalcBlockCopy_Clamp
	jr z, AccPatch_CalcBlockCopy_StoreIY
	jr AccPatch_CalcBlockCopy_CheckIX

AccPatch_CalcBlockCopy_Clamp:
	calr AccPatch_CalcBlockCopy_Clamp_Helper
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_StoreIY:
	calr BlockCopy_SameEntry_Reverse
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_CheckIX:
	calr BlockCopy_IXFirst_Reverse

AccPatch_CalcBlockCopy_StoreIX:
	cp (GLOBAL_ERROR_CODE:16), 0
	jr nz, AccPatch_CalcBlockCopy_Done
	calr AccPatch_CalcBlockCopyBounds

AccPatch_CalcBlockCopy_Done:
	ret

AccPatch_CalcBlockCopy_Clamp_Helper:
	ld wa, (0x3660:16)
	sub wa, (0x365e:16)
	ld (0x3654:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	ld (0x3656:16), bc
	ld xix, 0:i3
	ld xiy, 0:i3
	ld iy, (0x365e:16)
	ld ix, (0x3660:16)
	ld bc, (0x365e:16)
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_CheckSameEntry:
	cp de, (0x3658:16)
	jr nz, BlockCopy_Rev_CopyDiffEntry
	jr BlockCopy_Rev_StoreBounds

BlockCopy_Rev_CopyDiffEntry:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_Rev_CopyRemainder
	jr DSP_SetupDone

BlockCopy_Rev_CopyRemainder:
	ld bc, (0x3656:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_Rev_CheckSameEntry
	jr DSP_SetupDone

BlockCopy_Rev_StoreBounds:
	ld wa, (0x3654:16)
	ld (0x3666:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	ld (0x3664:16), bc

DSP_SetupDone:
	ret

DSP_BlockCopyReverse:
	push xwa
	push xhl
	and xiy, 0xff
	and xix, 0xff
	ld xwa, (0x364c:16)
	ld xhl, (0x3650:16)
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	lddr85
	pop xhl
	pop xwa
	ld (0x3650:16), xhl
	ld (0x364c:16), xwa
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
	ld xwa, (0x364c:16)
	ld xhl, (0x3650:16)
	push xwa
	push xhl
	add xwa, xix
	ld xix, xwa
	add xhl, xiy
	ld xiy, xhl
	ldir85
	pop xhl
	pop xwa
	ld (0x3650:16), xhl
	ld (0x364c:16), xwa
	and xiy, 0xff
	and xix, 0xff
	pop xhl
	pop xwa
	ret

BlockCopy_SameEntry_Reverse:
	ld bc, (0x365e:16)
	sub bc, 0x6
	inc 1, bc
	ld iy, (0x365e:16)
	ld ix, (0x3660:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_SameEntry_AdvIY
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIY:
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_CheckDE:
	cp de, (0x3658:16)
	jr nz, BlockCopy_SameEntry_FullCopy
	jr BlockCopy_SameEntry_StoreBounds

BlockCopy_SameEntry_FullCopy:
	ldw bc, 0xff
	sub bc, 0x6
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_SameEntry_AdvIYLoop
	jr DSP_NullRet

BlockCopy_SameEntry_AdvIYLoop:
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_SameEntry_CheckDE
	jr DSP_NullRet

BlockCopy_SameEntry_StoreBounds:
	ldw bc, 0xff
	sub bc, 0x6
	ld (0x3666:16), bc
	ld (0x3664:16), bc

DSP_NullRet:
	ret

BlockCopy_IXFirst_Reverse:
	ld wa, (0x365e:16)
	sub wa, (0x3660:16)
	ld (0x3654:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	ld (0x3656:16), bc
	ld xix, 0:i3
	ld xiy, 0:i3
	ld iy, (0x365e:16)
	ld ix, (0x3660:16)
	ld bc, (0x3660:16)
	sub bc, 0x6
	inc 1, bc
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_IXFirst_CopyOffset
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_CheckDE:
	cp de, (0x3658:16)
	jr nz, BlockCopy_IXFirst_CopyRemainder
	jr BlockCopy_IXFirst_StoreBounds

BlockCopy_IXFirst_CopyRemainder:
	ld bc, (0x3656:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_IXFirst_CopyOffset2
	jr DSP_NullRet2

BlockCopy_IXFirst_CopyOffset2:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_IXFirst_CheckDE
	jr DSP_NullRet2

BlockCopy_IXFirst_StoreBounds:
	ld wa, (0x3656:16)
	ld (0x3666:16), wa
	ldw wa, 0xff
	sub wa, 0x6
	ld (0x3664:16), wa

DSP_NullRet2:
	ret

AccPatch_CalcBlockCopyBounds:
	ld wa, (0x3604:16)
	sub wa, 0x6
	ld bc, (0x3664:16)
	sub bc, wa
	ld (0x3668:16), bc
	cp (0x3666:16), bc
	jr nc, BlockCopyBounds_UseBC
	jr BlockCopyBounds_UseSmaller

BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	ld bc, (0x3666:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopyBounds_CopyRemainder
	jr BlockCopyBounds_Return

BlockCopyBounds_CopyRemainder:
	ld bc, (0x3668:16)
	sub bc, (0x3666:16)
	calr DSP_BlockCopyReverse

BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	push xix
	ld xiy, (0x3650:16)
	ld hl, (xiy + 1)
	ld (0x3658:16), hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 0:8)
	jr nz, AdvNextEntry_IY_StoreAndReset
	ld (GLOBAL_ERROR_CODE:16), 11
	jr AdvNextEntry_IY_Return

AdvNextEntry_IY_StoreAndReset:
	ld (0x3650:16), xix
	ld xiy, 0:i3
	ldw iy, 0xfe

AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	ld xix, (0x364c:16)
	ld hl, (xix + 1)
	ld (0x365a:16), hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix + 0:8)
	jr nz, AdvNextEntry_IX_StoreAndReset
	ld (GLOBAL_ERROR_CODE:16), 11
	jr AdvNextEntry_IX_Return

AdvNextEntry_IX_StoreAndReset:
	ld (0x364c:16), xix
	ld xix, 0:i3
	ldw ix, 0xfe

AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	ld (GLOBAL_ERROR_CODE:16), 0
	ld hl, (0x3658:16)
	calr AccPatch_GetEntryAddr
	ld (0x3650:16), xix
	cp de, (0x3658:16)
	jr nz, BlockCopyDisp_CompareOffsets
	ld xiy, 0:i3
	ldw iy, 0xff
	sub iy, (0x365e:16)
	ld (0x3664:16), iy
	ld iy, (0x365e:16)
	ld xix, 0:i3
	ldw ix, 0xff
	sub ix, (0x3660:16)
	ld (0x3666:16), ix
	ld ix, (0x3660:16)
	calr AccPatch_ForwardBlockCopy
	jr BlockCopyDisp_Return

BlockCopyDisp_CompareOffsets:
	ld wa, (0x3660:16)
	cp wa, (0x365e:16)
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
	cp (GLOBAL_ERROR_CODE:16), 0
	jr nz, BlockCopyDisp_Return
	calr AccPatch_ForwardBlockCopy

BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	ldw wa, 0xff
	sub wa, (0x3660:16)
	ldw bc, 0xff
	sub bc, (0x365e:16)
	sub wa, bc
	ld (0x3654:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	ld (0x3656:16), bc
	ld xiy, 0:i3
	ld iy, (0x365e:16)
	ld xix, 0:i3
	ld ix, (0x3660:16)
	ldw bc, 0xff
	sub bc, (0x365e:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CheckDE:
	cp de, (0x3658:16)
	jr nz, BlockCopy_FwdIYSmall_CopyOffset
	jr BlockCopy_FwdIYSmall_StoreBounds

BlockCopy_FwdIYSmall_CopyOffset:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIYSmall_CopyRem
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_CopyRem:
	ld bc, (0x3656:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIYSmall_CheckDE
	jr DSP_CopyDone

BlockCopy_FwdIYSmall_StoreBounds:
	ld wa, (0x3654:16)
	ld (0x3666:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	ld (0x3664:16), bc

DSP_CopyDone:
	ret

BlockCopy_FwdEqual:
	ldw bc, 0xff
	sub bc, (0x365e:16)
	ld xiy, 0:i3
	ld iy, (0x365e:16)
	ld xix, 0:i3
	ld ix, (0x3660:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdEqual_AdvIX
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIX:
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_CheckDE:
	cp de, (0x3658:16)
	jr nz, BlockCopy_FwdEqual_FullCopy
	jr BlockCopy_FwdEqual_StoreBounds

BlockCopy_FwdEqual_FullCopy:
	ldw bc, 0xff
	sub bc, 0x6
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdEqual_AdvIXLoop
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_AdvIXLoop:
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdEqual_CheckDE
	jr AccPatch_NullRet2

BlockCopy_FwdEqual_StoreBounds:
	ldw bc, 0xff
	sub bc, 0x6
	ld (0x3666:16), bc
	ld (0x3664:16), bc

AccPatch_NullRet2:
	ret

BlockCopy_FwdIXSmaller:
	ldw wa, 0xff
	sub wa, (0x365e:16)
	ldw bc, 0xff
	sub bc, (0x3660:16)
	sub wa, bc
	ld (0x3654:16), wa
	ldw bc, 0xff
	sub bc, 0x6
	sub bc, wa
	ld (0x3656:16), bc
	ld xiy, 0:i3
	ld iy, (0x365e:16)
	ld xix, 0:i3
	ld ix, (0x3660:16)
	ldw bc, 0xff
	sub bc, (0x3660:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIXSmall_CopyOff
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CheckDE:
	cp de, (0x3658:16)
	jr nz, BlockCopy_FwdIXSmall_CopyRem
	jr BlockCopy_FwdIXSmall_StoreBounds

BlockCopy_FwdIXSmall_CopyRem:
	ld bc, (0x3656:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIXSmall_CopyOff2
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_CopyOff2:
	ld bc, (0x3654:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, BlockCopy_FwdIXSmall_CheckDE
	jr AccPatch_NullRet3

BlockCopy_FwdIXSmall_StoreBounds:
	ld wa, (0x3656:16)
	ld (0x3666:16), wa
	ldw wa, 0xff
	sub wa, 0x6
	ld (0x3664:16), wa

AccPatch_NullRet3:
	ret

AccPatch_ForwardBlockCopy:
	cp (GLOBAL_ERROR_CODE:16), 0
	jr nz, AccPatch_DoneBlockCopy
	ldw wa, 0xfe
	sub wa, (0x3662:16)
	ld bc, (0x3664:16)
	sub bc, wa
	ld (0x3668:16), bc
	cp (0x3666:16), bc
	jr nc, FwdBlockCopy_UseFull
	jr FwdBlockCopy_UseSmaller

FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	ld bc, (0x3666:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (GLOBAL_ERROR_CODE:16), 0
	jr z, FwdBlockCopy_CopyRemainder
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_CopyRemainder:
	ld bc, (0x3668:16)
	sub bc, (0x3666:16)
	calr DSP_BlockCopyForward

AccPatch_DoneBlockCopy:
	ret

AccPatch_AdvancePrevEntry_IX:
	ld xix, (0x364c:16)
	ld hl, (xix + 3)
	ld (0x365a:16), hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IX_StoreAndReset
	ld (GLOBAL_ERROR_CODE:16), 11
	jr AdvPrevEntry_IX_Return

AdvPrevEntry_IX_StoreAndReset:
	ld (0x364c:16), xix
	ld xix, 0:i3
	ld ix, 6:i3

AdvPrevEntry_IX_Return:
	ret

AccPatch_AdvancePrevEntry_IY:
	push xix
	ld xix, (0x3650:16)
	ld hl, (xix + 3)
	ld (0x3658:16), hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr nz, AdvPrevEntry_IY_StoreAndReset
	ld (GLOBAL_ERROR_CODE:16), 11
	jr AdvPrevEntry_IY_Return

AdvPrevEntry_IY_StoreAndReset:
	ld (0x3650:16), xix
	ld xiy, 0:i3
	ld iy, 6:i3

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
	and (0x34d0:16), 239
	ld a, (0x379b:16)
	and a, 0x7f
	cp a, (0x3510:16)
	jr z, AccPlayback_CheckStyleMatch
	and a, 0x1f
	cp a, 0:i3
	jr z, AccPlayback_CheckStyleMatch
	or (0x34d0:16), 16

AccPlayback_CheckStyleMatch:
	ld a, (CURRENT_TITLE:16)
	cp a, 0xb6
	jr z, AccPlayback_CheckActiveStyle
	jrl AccPlayback_Finalize

AccPlayback_CheckActiveStyle:
	cp a, (0x3525:16)
	jr z, AccPlayback_CheckBit4
	ld (0x34fd:16), 0
	call TempoRingBuf_Init
	bit 0, (0x3283:16)
	jr nz, AccPlayback_GetSlotAddr
	or (0x34cd:16), 128

AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride

AccPlayback_CheckBit4:
	bit 4, (0x34d0:16)
	jr nz, AccPlayback_InitTimingVars
	ld a, (0x3525:16)
	cp a, 0xb6
	jr z, AccPlayback_CheckStateFlags

AccPlayback_InitTimingVars:
	ld a, 0x0:opc
	ld (0x34fa:16), a
	ld (0x34fc:16), a
	ld (0x34fb:16), a
	ld (0x3746:16), a
	ldw (0x3747:16), 1
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ScanToSequenceStart
	ld (0x3712:16), 4
	ld (0x3717:16), 255
	ld (0x3522:16), 0
	and (0x34cf:16), 127

AccPlayback_CheckStateFlags:
	and (0x34d0:16), 254
	ld a, (0x3713:16)
	and a, 0xc0
	cp a, 0:i3
	jr z, AccPlayback_CheckSkipInit
	or (0x34d0:16), 1
	calr AccPlayback_AdjustBeatPosition
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	or (0xe3e0:16), 16

AccPlayback_CheckSkipInit:
	bit 4, (0x34d0:16)
	jr nz, AccPlayback_ApplyChanges
	bit 0, (0x34d0:16)
	jr nz, AccPlayback_ApplyChanges
	ld a, (0x3525:16)
	cp a, 0xb6
	jr z, AccPlayback_CheckBit0_3

AccPlayback_ApplyChanges:
	and (0x34d0:16), 223
	calr AccPlayback_ProcessStyleChanges
	and (0x34d0:16), 254
	and (0x3713:16), 63

AccPlayback_CheckBit0_3:
	ld a, (0x3713:16)
	and a, 0x3
	cp a, 0:i3
	jr z, AccPlayback_ProcessMiscFlags
	calr AccPlayback_ProcessPartChanges
	and (0x3713:16), 252

AccPlayback_ProcessMiscFlags:
	ld a, (0x372d:16)
	and a, 0x3f
	cp a, 0:i3
	jr z, AccPlayback_RunPeriodicTasks
	calr AccPlayback_ProcessVoiceType5
	and (0x372d:16), 192

AccPlayback_RunPeriodicTasks:
	calr AccPlayback_ReadEventLoop
	calr AccPlayback_ProcessBit5Change
	calr AccPlayback_ProcessTempoAdvance

AccPlayback_Finalize:
	calr AccPlayback_UpdateRhythmSustain
	ret

AccPlayback_Finalize_Code:
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
	add xhl, RHYTHM_PATTERN_BUF_B
	ret

ToneGen_CalcBufferAddr_Pad:
	nop
	nop

AccPlayback_CalcTimingPosition:
	ld a, (0x34fa:16)
	inc 1, a
	xor w, w
	ld (0x371a:16), wa
	calr ToneGen_StepFwd_Alternate
	jr AccTiming_ComputeOffset
	ld a, 0x20:opc
	cp (0x34fb:16), 4
	jr c, AccTiming_StorePartA

AccTiming_StorePartA:
	ld (0x371c:16), a

AccTiming_ComputeOffset:
	ld w, (0x34fb:16)
	ld a, 0x8:opc
	muls wa, w
	ld h, a
	ld a, (0x34fc:16)
	xor w, w
	ld l, 0xc:opc
	div wa, l
	add h, a
	inc 1, h
	ld a, (0x34fa:16)
	sub a, (0x3746:16)
	ld w, 0x20:opc
	cp (0x34d9:16), 5
	jr c, AccTiming_UseFullBar
	ld w, 0x40:opc

AccTiming_UseFullBar:
	muls wa, w
	add h, a
	ld (0x370f:16), h
	jr AccTiming_CompareStyles
	cp h, 0x20
	jr ule, AccTiming_StoreResult
	sub h, 0x20

AccTiming_StoreResult:
	ld (0x370f:16), h

AccTiming_CompareStyles:
	ld a, (CURRENT_TITLE:16)
	cp a, (ACTIVE_TITLE:16)
	jr nz, AccTiming_Return

AccTiming_Return:
	ret

AccTiming_CompareStyles_Pad:
	nop
	nop

AccPlayback_AdjustBeatPosition:
	ld wa, (0x371a:16)
	dec 1, a
	bit 7, (0x3713:16)
	jr z, AccBeatAdj_CheckBit6
	inc 1, a
	cp a, (0x34d7:16)
	jr ule, AccBeatAdj_CheckBit6
	ld a, 0x0:opc

AccBeatAdj_CheckBit6:
	bit 6, (0x3713:16)
	jr z, AccBeatAdj_StoreAndClear
	dec 1, a
	cp a, 0xff
	jr nz, AccBeatAdj_StoreAndClear
	ld a, (0x34d7:16)

AccBeatAdj_StoreAndClear:
	ld (0x34fa:16), a
	ld (0x34fc:16), 0
	ld (0x34fb:16), 0
	ret

AccBeatAdj_StoreAndClear_Pad:
	nop
	nop

AccVoice_InitPatternBuffer:
	ld xhl, 0x372e
	ld wa, 0:i3
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
	ld a, (0x3746:16)
	ld w, (0x34d9:16)
	muls wa, w
	ld c, a
	jr ToneGen_SkipToNoteEntry
	ld a, (0x34fa:16)
	ld w, (0x34d9:16)
	muls wa, w
	ld c, a
	cp (0x34d9:16), 5
	jr c, ToneGen_SkipToNoteEntry
	cp (0x34fb:16), 4
	jr c, ToneGen_SkipToNoteEntry
	add c, 0x4

ToneGen_SkipToNoteEntry:
	pushw bc
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ld xix, 6:i3
	add xix, xhl
	popw bc

ToneGen_SkipLoop:
	cp c, 0:i3
	jr z, ToneGen_ParseAllEvents
	ld a, (xix)
	cp a, 0x81
	jr nz, ToneGen_SkipLoop_ReadNext
	dec 1, c

ToneGen_SkipLoop_ReadNext:
	calr ToneGen_ReadBufferWithIndirection
	jr ToneGen_SkipLoop

ToneGen_ParseAllEvents:
	ld (0x350e:16), 0
	ld c, (0x373e:16)
	calr ToneGen_ParseEventBuffer
	inc 1, (0x350e:16)
	ld c, (0x373f:16)
	calr ToneGen_ParseEventBuffer
	inc 1, (0x350e:16)
	ld c, (0x3740:16)
	calr ToneGen_ParseEventBuffer
	inc 1, (0x350e:16)
	ld c, (0x3741:16)
	calr ToneGen_ParseEventBuffer
	ld a, (CURRENT_TITLE:16)
	cp a, (ACTIVE_TITLE:16)
	jr nz, ToneGen_SaveRegsAndCall
	ld (0xe3e0:16), 16

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

ToneGen_SaveRegsAndCall_Pad:
	nop
	nop

ToneGen_ParseEventBuffer:
	ld (0x350f:16), 0

EventBuffer_ParseLoop:
	cp c, 0:i3
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	ld a, (xix)
	cp a, 0x81
	jr nz, EventBuffer_CheckNoteType
	dec 1, c
	inc 1, (0x350f:16)
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
	ld l, 0xc:opc
	div wa, l
	pushw bc
	push xix
	and a, 0x7
	ld c, a
	xor b, b
	ld xix, ToneGen_MapNoteToOctaveBitmask_Code
	ld	c, (xix+bc)
	jr ToneGen_MapNote_OrMask
	; Bit mask lookup table (powers of 2):
ToneGen_MapNoteToOctaveBitmask_Code:
	normal
	push	sr
	max
	ld	(P4:8), 32:io
	.byte 0x40, 0x80

ToneGen_MapNote_OrMask:
	ld l, (0x350f:16)
	xor h, h
	ld a, (0x350e:16)
	and a, 0x3
	sla a, 2
	add l, a
	ld xix, 0x372e
	ld	a, (xix+hl)
	or a, c
	ld	(xix+hl), a
	pop xix
	popw bc
	calr ToneGen_ReadBufferWithIndirection
	jrl EventBuffer_ParseLoop

ToneGen_ParseEvent_Done:
	ret

ToneGen_MapNote_OrMask_Pad:
	nop
	nop

AccPlayback_ProcessStyleChanges:
	ld (0x370f:16), 1
	ld (0x3712:16), 4
	ld (0x3717:16), 255
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
	ld a, 0x0:opc
	ld (0x34f7:16), a
	ld (0x34fb:16), a
	ld (0x34fc:16), a
	ld wa, (0x371a:16)
	dec 1, a
	ld (0x34fa:16), a
	call AccPatch_GetCurrentSlotAddr
	calr AccPlayback_CalcTimingPosition
	calr AccVoice_InitPatternBuffer
	ret

AccStyleChange_CheckPartCount:
	nop
	nop

AccPlayback_ProcessPartChanges:
	and (0x3522:16), 115
	cp (0x34fc:16), 0
	jr nz, AccPartChange_Bit1
	or (0x3522:16), 4

AccPartChange_Bit1:
	bit 0, (0x3713:16)
	jr nz, AccPartChange_CheckBit2
	calr ToneGen_ProcessWithRestore
	jrl ToneGen_UpdateAndInitPattern

AccPartChange_CheckBit2:
	bit 5, (0x34d0:16)
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
	jr ToneGen_CalcAndRestart_Join

AccPartChange_StoreResult:
	and (0x34d0:16), 223

ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

ToneGen_CalcAndRestart_Join:
	ld wa, (0x346b:16)
	ld (0x3514:16), wa
	ld wa, (0x3449:16)
	ld (0x3512:16), wa
	or (0x34d0:16), 32
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp a, 0x81
	jr nz, ToneGen_PushAndReadType
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
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
	cp a, 0:i3
	jr nz, ToneGen_CalcAndRestart
	ld wa, (0x346b:16)
	ld (0x3514:16), wa
	ld wa, (0x3449:16)
	ld (0x3512:16), wa
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	pushw wa
	push xhl
	calr ToneGen_AdvancePeriodWrap
	pop xhl
	popw wa

ToneGen_PushAndReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ld w, a
	ld (0x34fc:16), w
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_UpdateAndInitPattern:
	and (0x34cf:16), 127
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	or (0xe3e0:16), 16
	ret

ToneGen_VoiceSlotLookupTable:
	.byte	0x00, 0x00
ToneGen_ClassifyMono_MapChannel_Data:	.byte	0x00, 0x94, 0x95, 0x00, 0x96, 0x00
	.byte 0x00, 0x00, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x98

ToneGen_ProcessWithRestore:
	bit 5, (0x34d0:16)
	jr z, ToneGen_ProcessRestore_Direct
	calr ToneGen_RestoreFromSavedPos
	jr ToneGen_ProcessRestore_CalcPos

ToneGen_ProcessRestore_Direct:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots
	and (0x3522:16), 254

ToneGen_ProcessRestore_CalcPos:
	calr ToneGen_CalcNotePosition
	ld bc, (0x3520:16)
	cp bc, wa
	jr c, ToneGen_ProcessRestore_CheckDelta
	sub bc, wa
	cp bc, 0x200
	jr ugt, ToneGen_ProcessRestore_CheckDelta
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_CheckDelta:
	cp bc, 0:i3
	jr nz, ToneGen_ProcessRestore_ClearBit5
	bit 3, (0x3522:16)
	jr z, ToneGen_ProcessRestore_ClearBit5
	jr ToneGen_ProcessRestore_UseSaved

ToneGen_ProcessRestore_ClearBit5:
	and (0x34d0:16), 223

ToneGen_ProcessRestore_CalcNote:
	ld a, (0x34fc:16)
	ld e, a
	xor w, w
	ld l, 0xc:opc
	div wa, l
	cp w, 0:i3
	jr nz, ToneGen_ProcessRestore_AdjNote
	ld w, 0xc:opc

ToneGen_ProcessRestore_AdjNote:
	calr ToneGen_AdjustNoteWrap
	ld a, 0x4:opc
	ld (0x3712:16), a
	ld w, 0xff:opc
	ld (0x3717:16), 255
	jr ToneGen_ProcessRestore_Return

ToneGen_ProcessRestore_UseSaved:
	bit 0, (0x3522:16)
	jr nz, ToneGen_ProcessRestore_UseActive
	ld wa, (0x351a:16)
	ld (0x3514:16), wa
	ld (0x346b:16), wa
	ld wa, (0x351e:16)
	ld (0x3512:16), wa
	ld (0x3449:16), wa
	jr ToneGen_ProcessRestore_SetBit5

ToneGen_ProcessRestore_UseActive:
	ld wa, (0x346b:16)
	ld (0x3514:16), wa
	ld wa, (0x3449:16)
	ld (0x3512:16), wa

ToneGen_ProcessRestore_SetBit5:
	or (0x34d0:16), 32
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+wa)
	cp a, 0x81
	jr nz, ToneGen_ProcessRestore_ReadType
	bit 7, (0x34cf:16)
	jr z, ToneGen_ProcessRestore_JumpCalc
	and (0x34d0:16), 223
	and (0x34cf:16), 127

ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	pushw wa
	calr AccVoice_ReadCurrentToneType
	ld w, (0x34fc:16)
	sub w, a
	jr nc, ToneGen_ProcessRestore_WrapOctave
	add w, 0x60

ToneGen_ProcessRestore_WrapOctave:
	ld e, (0x34fc:16)
	calr ToneGen_AdjustNoteWrap
	popw wa
	calr ToneGen_ClassifyAndDispatch

ToneGen_ProcessRestore_Return:
	ret

ToneGen_ProcessRestore_WrapOctave_Pad:
	nop
	nop

ToneGen_RestoreFromSavedPos:
	ld iy, (0x3512:16)
	ld (0x3449:16), iy
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld a, 0x0:opc
	ld (0x3435:16), a
	and (0x3522:16), 253
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp a, 0x81
	jr nz, ToneGen_EventDispatchLoop
	or (0x3522:16), 2
	and (0x3522:16), 251

ToneGen_EventDispatchLoop:
	calr ToneGen_StepVoiceForward
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
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
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld ix, 6:i3
	ld (0x3449:16), ix
	ld (0x3435:16), 6
	jr ToneGen_EventDispatchLoop

ToneGen_CalcEventVelocity_WithFlags:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ld b, (0x34fb:16)
	bit 1, (0x3522:16)
	jr z, ToneGen_Velocity_SkipDec
	dec 1, b
	cp b, 0xff
	jr nz, ToneGen_Velocity_SkipDec
	ld b, (0x34d9:16)
	dec 1, b
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	dec 1, w
	cp w, 0xff
	jr nz, ToneGen_Velocity_Multiply
	ld w, (0x34d7:16)

ToneGen_Velocity_Multiply:
	muls wa, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	bit 7, (0x3522:16)
	jr nz, VoiceVelocity_CalcDone
	bit 2, (0x3522:16)
	jr z, ToneGen_Velocity_DefaultCalc
	or (0x3522:16), 2
	or (0x3522:16), 128
	jrl ToneGen_EventDispatchLoop

ToneGen_Velocity_DefaultCalc:
	ld c, 0x0:opc
	ld b, (0x34fb:16)
	dec 1, b
	cp b, 0xff
	jr nz, VoiceVelocity_CalcDone
	ld b, (0x34d9:16)
	dec 1, b

VoiceVelocity_CalcDone:
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	muls wa, w
	add b, a

ToneGen_Velocity_Store:
	ld (0x3520:16), bc
	or (0x3522:16), 1
	ret

ToneGen_Velocity_Store_Pad:
	nop
	nop

ToneGen_CalcNotePosition:
	ld a, (0x34fc:16)
	ld e, a
	xor w, w
	ld l, 0xc:opc
	div wa, l
	ld d, (0x34fb:16)
	ld bc, wa
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	muls wa, w
	add d, a
	ld wa, bc
	cp w, 0:i3
	jr nz, ToneGen_CalcPos_SubOctave
	ld w, 0xc:opc

ToneGen_CalcPos_SubOctave:
	ld a, e
	sub a, w
	jr nc, ToneGen_CalcPos_Return
	add a, 0x60
	dec 1, d
	cp d, 0xff
	jr nz, ToneGen_CalcPos_Return
	ld d, (0x34d9:16)
	dec 1, d
	or (0x3522:16), 8

ToneGen_CalcPos_Return:
	ld w, d
	ret

ToneGen_CalcPos_SubOctave_Pad:
	nop
	nop

ToneGen_AdjustNoteWrap:
	ld a, e
	sub a, w
	jr c, ToneGen_AdjWrap_AddOctave
	ld (0x34fc:16), a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_AddOctave:
	add a, 0x60
	ld (0x34fc:16), a
	ld a, (0x34fb:16)
	dec 1, a
	cp a, 0xff
	jr z, ToneGen_AdjWrap_WrapBar
	ld (0x34fb:16), a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapBar:
	ld a, (0x34d9:16)
	dec 1, a
	ld (0x34fb:16), a
	ld a, (0x34fa:16)
	dec 1, a
	cp a, 0xff
	jr z, ToneGen_AdjWrap_WrapMeasure
	ld (0x34fa:16), a
	jr SustainLevel_SetExit

ToneGen_AdjWrap_WrapMeasure:
	ld a, (0x34d7:16)
	and a, 0x7
	ld (0x34fa:16), a

SustainLevel_SetExit:
	ret

SustainLevel_SetExit_Pad:
	nop
	nop

ToneGen_ScanRestoredVoiceEvents:
	ld iy, (0x3512:16)
	ld (0x3449:16), iy
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld a, 0x0:opc
	ld (0x3435:16), a

ToneGen_ScanRestored_Loop:
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
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
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld ix, 6:i3
	ld (0x3449:16), ix
	ld (0x3435:16), 6
	jr ToneGen_ScanRestored_Loop

ToneGen_CalcEventVelocity_Restored:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	ld b, (0x34fb:16)
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	muls wa, w
	add b, a
	jr ToneGen_ScanRestored_Return

ToneGen_ScanRestored_EndMarker:
	ld c, 0x0:opc
	ld b, (0x34fb:16)
	inc 1, b
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	muls wa, w
	add b, a

ToneGen_ScanRestored_Return:
	ret

ToneGen_ScanRestored_EndMarker_Pad:
	nop
	nop

ToneGen_GetSlotIndex:
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, ToneGen_GetSlot_Lookup
	or a, 0x10
	ld (0x379b:16), a

ToneGen_GetSlot_Lookup:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ld	hl, (xiy+hl)
	ret

ToneGen_GetSlot_Lookup_Pad:
	nop
	nop

ToneGen_CalcNoteWithWrap:
	ld a, (0x34fc:16)
	ld e, a
	xor w, w
	ld l, 0xc:opc
	div wa, l
	ld a, e
	sub a, w
	add a, 0xc
	ld w, (0x34fb:16)
	cp a, 0x60
	jr nz, ToneGen_CalcWrap_Store
	ld a, 0x0:opc
	inc 1, w

ToneGen_CalcWrap_Store:
	ld hl, wa
	ld a, (0x34d9:16)
	ld w, (0x34fa:16)
	muls wa, w
	add h, a
	ld wa, hl
	ret

ToneGen_CalcWrap_Store_Pad:
	nop
	nop

ToneGen_RecalcAndRestart:
	ld a, (0x34fc:16)
	ld e, a
	xor w, w
	ld l, 0xc:opc
	div wa, l
	ld a, e
	sub a, w
	add a, 0xc
	calr ToneGen_StoreNoteOrWrap
	ld (0x3712:16), 4
	ld (0x3717:16), 255
	ret

ToneGen_RecalcAndRestart_Pad:
	nop
	nop

ToneGen_StoreNoteOrWrap:
	cp a, 0x60
	jr z, ToneGen_AdvancePeriodWrap
	ld (0x34fc:16), a
	jr PitchValidate_Exit

ToneGen_AdvancePeriodWrap:
	ld (0x34fc:16), 0
	ld a, (0x34fb:16)
	inc 1, a
	cp a, (0x34d9:16)
	jr z, ToneGen_PeriodWrap_NextBar
	ld (0x34fb:16), a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_NextBar:
	ld (0x34fb:16), 0
	ld a, (0x34fa:16)
	inc 1, a
	ld w, (0x34d7:16)
	and w, 0x7
	inc 1, w
	cp a, w
	jr z, ToneGen_PeriodWrap_ResetBar
	ld (0x34fa:16), a
	jr PitchValidate_Exit

ToneGen_PeriodWrap_ResetBar:
	ld (0x34fa:16), 0

PitchValidate_Exit:
	ret

ToneGen_PeriodWrap_ResetBar_Pad:
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

ToneGen_ClassifyStereoType_Pad:
	nop
	nop

ToneGen_ClassifyStereoEvent:
	ld a, 0x5:opc
	ld (0x3712:16), a
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	ld e, 0x1:opc
	cp a, 0xd2
	jr z, ToneGen_ClassifyStereoSlot_Common
	ld e, 0x2:opc
	cp a, 0xd1
	jr z, ToneGen_ClassifyStereoSlot_Common
	ld e, 0x3:opc
	cp a, 0xd3
	jr z, ToneGen_ClassifyStereoSlot_Common
	ld e, 0x4:opc
	cp a, 0xd4
	jr z, ToneGen_ClassifyStereoSlot_Common
	ld e, 0x5:opc
	cp a, 0xd5
	jr z, ToneGen_ClassifyStereoSlot_Common
	ld e, 0x6:opc

ToneGen_ClassifyStereoSlot_Common:
	ld (0x3720:16), e
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	ld (0x3721:16), a
	ret

ToneGen_ClassifyStereoSlot_Common_Pad:
	nop
	nop

ToneGen_ClassifyMonoEvent:
	ld a, 0x4:opc
	ld (0x3712:16), a
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	ld (0x3718:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	w, (xhl+wa)
	ld (0x3717:16), w
	ld a, (0x3718:16)
	ld de, wa
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, ToneGen_ClassifyMono_MapChannel
	or a, 0x10
	ld (0x379b:16), a

ToneGen_ClassifyMono_MapChannel:
	ld l, a
	xor h, h
	ld xiy, ToneGen_ClassifyMono_MapChannel_Data
	ld	a, (xiy+hl)
	cp (0x3518:16), 0
	jr z, ToneGen_ClassifyMono_WriteNew
	pushw de
	pushw wa
	ld a, (0x3516:16)
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, (0x3517:16)
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	ld a, 0x0:opc
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
	ld (0x3516:16), a
	ld (0x3517:16), e
	ld a, 0x10:opc
	ld (0x3518:16), a
	bit 4, (0x379b:16)
	jr z, ToneGen_ClassifyMono_Return
	ld a, (0x3718:16)
	ld w, (0xfbbe:16)
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	ld e, a
	xor d, d
	ld c, w
	xor b, b
	ld wa, 1:i3
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l
	ld (0x3718:16), a

ToneGen_ClassifyMono_Return:
	ret

ToneGen_ClassifyMono_WriteNew_Pad:
	nop
	nop

AccPlayback_ReadEventLoop:
	and (0x34d0:16), 127

AccPlayback_ReadEvt_CheckEmpty:
	call AccPatch_CheckEmpty
	cp wa, 0:i3
	jr z, AccPlayback_ReadEvt_CheckBit7
	bit 7, (0x34d0:16)
	jr nz, AccPlayback_ReadEvt_CheckBit7
	call TempoRingBuf_ReadByteToA
	cp a, 0x90
	jr nz, AccPlayback_ReadEvt_Continue
	calr AccPlayback_ProcessNoteOnEvent

AccPlayback_ReadEvt_Continue:
	jr AccPlayback_ReadEvt_CheckEmpty

AccPlayback_ReadEvt_CheckBit7:
	bit 7, (0x34d0:16)
	jr z, ToneGenSetup_Done
	cpw (0x34d4:16), 0
	jr nz, AccPlayback_ReadEvt_HasEntries
	ld (GLOBAL_ERROR_CODE:16), 15
	ld (0xe3dc:16), 238
	ld (0xe3de:16), 64
	and (0x34d0:16), 127
	ld a, 0x8:opc
	call MIDI_SendSysExCmd
	jr ToneGenSetup_Done

AccPlayback_ReadEvt_HasEntries:
	and (0x34d0:16), 223
	calr ToneGen_CalcTempo
	bit 4, (0x379b:16)
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
	ld (0x3712:16), 4
	ld (0x3717:16), 255
	ld a, (CURRENT_TITLE:16)
	cp a, (ACTIVE_TITLE:16)
	jr nz, ToneGenSetup_Done
	ld (0xe3e0:16), 16

ToneGenSetup_Done:
	ret

AccPlayback_ReadEvt_Return:
	nop
	nop

AccPlayback_ProcessNoteOnEvent:
	call TempoRingBuf_ReadByteToA
	call TempoRingBuf_ReadByteToA
	ld (0x342d:16), a
	call TempoRingBuf_ReadByteToA
	ld (0x342e:16), a
	call TempoRingBuf_ReadByteToA
	cp (0x342e:16), 0
	jr nz, AccPlayback_NoteOn_ReadParams
	jr AccPlayback_NoteOn_WriteVoice

AccPlayback_NoteOn_ReadParams:
	ld l, (0x34fd:16)
	cp l, 5:i3
	jr ugt, AccPlayback_NoteOn_Store
	xor h, h
	ld xiy, 0x3500
	ld a, (0x342d:16)
	ld	(xiy+hl), a
	ld a, (0x342e:16)
	pushw hl
	add hl, 0x6
	ld	(xiy+hl), a
	popw hl
	inc 1, l
	ld (0x34fd:16), l
	cp l, (0x34fe:16)
	jr ule, AccPlayback_NoteOn_Store
	ld (0x34fe:16), l

AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	ld a, (0x34fd:16)
	dec 1, a
	cp a, 0xff
	jr z, TimeoutCounter_CheckExit
	ld (0x34fd:16), a
	cp a, 0:i3
	jr nz, TimeoutCounter_CheckExit
	or (0x34d0:16), 128

TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	nop
	nop

AccPlayback_NoteOn_Check91:
	ld wa, 0:i3
	ld (0x360a:16), wa
	ld e, (0x34fe:16)
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366a

AccPlayback_NoteOn_WritePan:
	cp e, 0:i3
	jr z, AccPlayback_NoteOn_Return
	ld l, e
	dec 1, l
	addw (0x360a:16), 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	dec 1, e
	jr AccPlayback_NoteOn_WritePan

AccPlayback_NoteOn_Return:
	ret

AccPlayback_NoteOn_WritePan_Pad:
	nop
	nop

ToneGen_WriteVoiceEventEntry:
	ld a, (0x34fc:16)
	ld (xiy), a
	inc 1, xiy
	ld	a, (xix+hl)
	ld (xiy), a
	inc 1, xiy
	pushw hl
	add hl, 0x6
	ld	a, (xix+hl)
	ld (xiy), a
	popw hl
	inc 1, xiy
	ld a, (0x342d:16)
	ld (xiy), a
	inc 1, xiy
	ld a, (0x342e:16)
	ld (xiy), a
	inc 1, xiy
	ret

AccPlayback_AdvancePattern:
	nop
	nop

AccPlayback_AdvPattern_Loop:
	ld wa, 0:i3
	ld (0x360a:16), wa
	ld e, (0x34fe:16)
	xor h, h
	ld xix, 0x3500
	ld xiy, 0x366a

AccPlayback_AdvPattern_Check81:
	cp e, 0:i3
	jr z, AccPlayback_AdvPattern_Nop
	ld l, e
	dec 1, l
	calr AccPlayback_AdvanceRingBuffer
	bit 0, (0x3431:16)
	jr nz, AccPlayback_AdvPattern_Check90
	addw (0x360a:16), 6
	ld (xiy), 0x90
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	jr AccPlayback_AdvPattern_Done

AccPlayback_AdvPattern_Check90:
	addw (0x360a:16), 8
	ld (xiy), 0x91
	inc 1, xiy
	calr ToneGen_WriteVoiceEventEntry
	ld a, (0x3432:16)
	ld (xiy), a
	inc 1, xiy
	ld a, (0x3433:16)
	ld (xiy), a
	inc 1, xiy

AccPlayback_AdvPattern_Done:
	dec 1, e
	jr AccPlayback_AdvPattern_Check81

AccPlayback_AdvPattern_Nop:
	ret

AccPlayback_AdvPattern_Nop_Pad:
	nop
	nop

AccPlayback_AdvanceRingBuffer:
	ld a, (0x34e9:16)
	and a, 0xf
	cp a, 0:i3
	jr z, AccPlayback_TrackPosition
	call AccPatch_ReadTransposeAmount
	cp a, (0x3a4e:16)
	jr ugt, AccPlayback_AdvanceRingBuffer_Join
	sub	(xix+hl), a
	jr nc, AccPlayback_AdvRingBuf_Return
	ld a, 0xc:opc
	add	(xix+hl), a

AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

AccPlayback_AdvanceRingBuffer_Join:
	ld w, 0xc:opc
	sub w, a
	add	(xix+hl), w

AccPlayback_TrackPosition:
	ld	a, (xix+hl)
	push xix
	xor w, w
	ld xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+wa)
	pop xix
	bit 4, (0x34ea:16)
	jr z, AccPlayback_TrackPosition_Join
	ld c, a
	push xix
	xor w, w
	ld xix, AccPlayback_TrackPosition_Data
	ld	a, (xix+wa)
	pop xix
	bit 0, a
	jr z, AccPlayback_TrackPos_Return
	inc 1, c
	ld	a, (xix+hl)
	inc 1, a
	ld	(xix+hl), a

AccPlayback_TrackPos_Return:
	ld a, c

AccPlayback_TrackPosition_Join:
	bit 6, (0x34ea:16)
	jr z, AccPlayback_TrackPos_WrapCheck
	bit 3, (0x379b:16)
	jr z, AccPlayback_TrackPos_WrapCheck
	jr AccPlayback_TrackPos_WrapDone

AccPlayback_TrackPos_WrapCheck:
	bit 5, (0x34ea:16)
	jr z, ToneGen_LoadRhythmPatternParams
	bit 3, (0x379b:16)
	jr nz, ToneGen_LoadRhythmPatternParams

AccPlayback_TrackPos_WrapDone:
	cp a, 7:i3
	jr nz, ToneGen_LoadRhythmPatternParams
	ld (0x3431:16), 1
	ld (0x3432:16), 3
	ld (0x3433:16), 0
	jr AccPlayback_StyleRecalc_Return

ToneGen_LoadRhythmPatternParams:
	xor xbc, xbc
	ld c, a
	sla a, 1
	add c, a
	push xix
	ld xix, ToneGen_LoadRhythmPatternParams_Data
	add xix, xbc
	ld a, (xix)
	ld (0x3431:16), a
	ld a, (xix + 1)
	ld (0x3432:16), a
	ld a, (xix + 2)
	ld (0x3433:16), a
	pop xix

AccPlayback_StyleRecalc_Return:
	ret

ToneGen_LoadRhythmPatternParams_Pad:
; ToneGen_LoadRhythmPatternParams_Pad -- NOT padding; the name is historical (it is also the base of
; the __pad_F62002_0x* symbols in shared/positional_labels.s, so it is kept).
; ** RE-TYPED 2026-09-25 (lane accomp): was nop/normal/scf mnemonics
; (data-as-code).  The same two tables as AccPatch_TransposeNoteTable, read
; by the playback path instead of the patch path:
;   AccPlayback_TrackPosition: ld xix, AccPlayback_TrackPosition_Data / ldb_sri a,(xix+wa)
;       with A = a byte of AccPatch_Transpose_LookupTable_Data; bit 0 set ->
;       the note index is incremented.
;   ToneGen_LoadRhythmPatternParams: c = a, then sla a,1 / add c,a (3a) /
;       ld xix, ToneGen_LoadRhythmPatternParams_Data / add xix,xbc; (xix), (xix+1), (xix+2) are
;       stored to (0x3431), (0x3432), (0x3433).
; Sizes as in AccPatch_TransposeNoteTable: 12 flag bytes between the two
; reader offsets, then 12 three-byte records ending at
; AccPlayback_ProcessOngoingEvents.
; readers in v9/v10 (address from the linked ELF): AccPlayback_TrackPosition 0xF61F6E,
;     ToneGen_LoadRhythmPatternParams 0xF61FDB
; +0x00  2 B, not addressed by either reader
	.byte 0x00, 0x00
; +0x02  12 x u8, flag byte per index (bit 0 tested)
AccPlayback_TrackPosition_Data:
	.byte 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x0E  12 x 3-byte records {(0x3431), (0x3432), (0x3433)}
ToneGen_LoadRhythmPatternParams_Data:
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x01, 0x00, 0x11
	.byte 0x01, 0x00, 0x11
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00
	.byte 0x01, 0x11, 0x11

AccPlayback_ProcessOngoingEvents:
	andmi8 (xiy + 15), 0x7f
	calr ToneGen_ProcessVoiceSlots
	ld wa, (0x346b:16)
	ld (0x3602:16), wa
	xor w, w
	ld a, (0x3435:16)
	ld (0x3604:16), wa
	ld (0x3445:16), wa
	ld wa, (0x3602:16)
	ld (0x3447:16), wa
	ld wa, (0x360a:16)
	ld (0x344b:16), wa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	ld (0x34fe:16), 0
	bit 0, (0x3283:16)
	jr nz, ToneGen_NullRet
	cp (0x34fa:16), 0
	jr nz, ToneGen_NullRet
	cp (0x34fb:16), 0
	jr nz, ToneGen_NullRet
	cp (0x34fc:16), 48
	jr ugt, ToneGen_NullRet
	or (0x34cd:16), 128

ToneGen_NullRet:
	ret

AccPlayback_Ongoing_HandleType:
	nop
	nop

ToneGen_ProcessVoiceSlots:
	calr AccPlayback_Ongoing_AdvSlot
	calr ToneGen_GetSlotIndex
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ldw (0x3449:16), 6
	ld a, (0x34fa:16)
	ld w, (0x34d9:16)
	muls wa, w
	ld d, a
	ld a, (0x34fb:16)
	add d, a
	ld e, (0x34fc:16)
	and (0x32f4:16), 254
	xor bc, bc
	ld (0x3435:16), 6

AccPlayback_Ongoing_NoteOff:
	bit 0, (0x32f4:16)
	jr z, AccPlayback_Ongoing_NoteOffDone
	jrl AccPlayback_Ongoing_Return

AccPlayback_Ongoing_NoteOffDone:
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x81
	jr nz, AccPlayback_Ongoing_D2Type
	add b, 0x1
	xor c, c
	cp de, bc
	jr c, AccPlayback_Ongoing_D1Type
	calr ToneGen_StepToNextVoiceSlot
	jr AccPlayback_Ongoing_D1_Return

AccPlayback_Ongoing_D1Type:
	or (0x32f4:16), 1

AccPlayback_Ongoing_D1_Return:
	jr AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_D2Type:
	calr AccVoice_ReadCurrentToneType
	ld c, a
	cp de, bc
	jr ule, AccPlayback_Ongoing_StoreDone
	calr AccPlayback_Ongoing_D2Type_Helper
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
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
	or (0x32f4:16), 1

ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

ToneGen_StepVoiceReturn_Pad:
	nop
	nop

AccPlayback_Ongoing_AdvSlot:
	ld wa, (0x3608:16)
	dec 1, a
	ld (0x351c:16), a
	ld e, a
	ld wa, (0x3606:16)
	ld (0x351a:16), wa
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ld a, (0x351c:16)
	xor w, w
	ld (0x351e:16), wa
	ld a, (0x34d7:16)
	inc 1, a
	ld w, (0x34d9:16)
	muls wa, w
	dec 1, a
	ld b, a
	xor c, c
	ld (0x3520:16), bc
	ret

AccPlayback_Ongoing_AdvDone:
	nop
	nop

AccPlayback_Ongoing_D2Type_Helper:
	ld wa, (0x346b:16)
	ld (0x351a:16), wa
	ld a, (0x3435:16)
	ld (0x351c:16), a
	ld wa, (0x3449:16)
	ld (0x351e:16), wa
	ld (0x3520:16), bc
	ret

AccPlayback_UpdateVoiceState:
	nop
	nop

ToneGen_AdvanceSeqList:
	calr ToneGen_InitPlaybackState
	ld xhl, (0x3548:16)
	ld wa, (xhl)
	cp wa, (0x3447:16)
	jr z, AccPlayback_VoiceState_NoChange
	ld de, (0x3441:16)
	calr ToneGen_SearchVoiceBuffer
	jr AccPlayback_VoiceState_Changed

AccPlayback_VoiceState_NoChange:
	ld de, (0x3441:16)
	cp de, (0x3445:16)
	jr c, AccPlayback_VoiceState_Changed
	or (0x34d0:16), 64

AccPlayback_VoiceState_Changed:
	bit 6, (0x34d0:16)
	jr z, AccPlayback_VoiceState_Return
	ld wa, (0x344b:16)
	add de, wa
	cp de, 0xff
	jr nc, AccPlayback_VoiceState_CalcOff
	ld ix, (0x3441:16)
	ld wa, (0x344b:16)
	add ix, wa
	ld xhl, (0x354c:16)
	ld (xhl), ix
	jr AccPlayback_VoiceState_Return

AccPlayback_VoiceState_CalcOff:
	ld hl, (0x3534:16)
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ld xix, (0x3548:16)
	ld (xix), hl
	ld ix, 6:i3
	sub de, 0xff
	add ix, de
	ld xhl, (0x354c:16)
	ld (xhl), ix

AccPlayback_VoiceState_Return:
	ret

AccPlayback_VoiceState_CalcOff_Pad:
; AccPlayback_VoiceState_CalcOff_Pad -- NOT padding; the name is historical (base of the
; __pad_F62230_0x* symbols in shared/positional_labels.s, so it is kept).
; ** RE-TYPED 2026-09-25 (lane accomp): was `.byte 0x9d` / `ldw de,0` / nop
; runs (data-as-code).  Two parallel 17-entry tables of RAM pointers, indexed
; by the one-hot selector (0x379b) & 0x1F -- the playback-side twin of
; AccPatch_AdvPlayPos_DataBlock.  Read by ToneGen_InitPlaybackState:
;     ld a,(0x379b) / and a,0x1f (0 becomes 0x10) / sla a,2 / ld l,a /
;     ld xix, ToneGen_InitPlay_SetupTables_Data / ld_sril3 xix,(xix+hl) / ld (0x3548),xix
;     ld xix, ToneGen_InitPlay_SetupTables_Data_2 / ld_sril3 xix,(xix+hl) / ld (0x354c),xix
; and the two pointers are then dereferenced as words into (0x3441) and
; (0x3534).  Only the one-hot entries 1, 2, 4, 8 and 16 are non-zero, and they
; are the same ten pointers as AccPatch_AdvPlayPos_DataBlock's (checked on the
; v10 bytes).
; 17 entries each: 0x46 - 0x02 = 68 = 17*4, and 17*4 more bytes end exactly
; at ToneGen_SearchVoiceBuffer.
; readers in v9/v10 (address from the linked ELF): ToneGen_InitPlaybackState 0xF6249A
; +0x00  2 B, not addressed by the reader
	.byte 0x00, 0x00
; +0x02  17 x LE32 -> (0x3548)
ToneGen_InitPlay_SetupTables_Data:
	.long 0x00000000, 0x0000329d, 0x0000329f, 0x00000000
	.long 0x000032a1, 0x00000000, 0x00000000, 0x00000000
	.long 0x0000329b, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x00003297
; +0x46  17 x LE32 -> (0x354c)
ToneGen_InitPlay_SetupTables_Data_2:
	.long 0x00000000, 0x0000328d, 0x0000328f, 0x00000000
	.long 0x00003291, 0x00000000, 0x00000000, 0x00000000
	.long 0x0000328b, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x00003287

ToneGen_SearchVoiceBuffer:
	call AccPatch_GetCurrentSlotAddr
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, ToneGen_SearchBuf_MapChannel
	or a, 0x10
	ld (0x379b:16), a

ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ld	wa, (xiy+hl)

ToneGen_SearchBuf_CompareLoop:
	cp wa, (0x3447:16)
	jr nz, ToneGen_SearchBuf_CheckEnd
	or (0x34d0:16), 64
	jr ToneGen_SearchBuf_Return

ToneGen_SearchBuf_CheckEnd:
	cp wa, (0x3534:16)
	jr nz, ToneGen_SearchBuf_FollowChain
	jr ToneGen_SearchBuf_Return

ToneGen_SearchBuf_FollowChain:
	ld hl, wa
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 3)
	jr ToneGen_SearchBuf_CompareLoop

ToneGen_SearchBuf_Return:
	ret

ToneGen_SearchBuf_FollowChain_Pad:
	nop
	nop

AccPlayback_ProcessBit5Change:
	bit 5, (0x3713:16)
	jr nz, AccBit5_CheckBit5Active
	jrl AccBit5_Return

AccBit5_CheckBit5Active:
	bit 5, (0x34d0:16)
	jr nz, AccBit5_InitAndScan
	jrl FlagClear_Exit

AccBit5_InitAndScan:
	and (0x34d0:16), 223
	and (0x34cf:16), 127
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x365a:16), wa
	ld (0x3530:16), wa
	ld iy, (0x3512:16)
	ld (0x344b:16), iy
	ld (0x3449:16), iy
	ld (0x3660:16), iy
	ld wa, iy
	ld (0x3435:16), a
	ld iy, (0x3512:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x81
	jrl z, FlagClear_Exit
	ld (0x344d:16), 6
	cp a, 0x90
	jr z, AccBit5_StepTwice
	ld (0x344d:16), 8
	cp a, 0x91
	jr z, AccBit5_StepOnce
	ld (0x344d:16), 3
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
	ld wa, (0x346b:16)
	ld (0x3658:16), wa
	ld (0x3532:16), wa
	xor w, w
	ld a, (0x3435:16)
	ld (0x365e:16), wa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ld (0x3712:16), 4
	ld (0x3717:16), 255
	ld (0xe3e0:16), 16

FlagClear_Exit:
	and (0x3713:16), 223

AccBit5_Return:
	ret

AccVoice_InitPlaybackState_Pad:
	nop
	nop

ToneGen_ScanVoicePosition:
	calr ToneGen_InitPlaybackState
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	ld de, hl
	calr ToneGen_CalcBufferAddr
	ld c, 0x3:opc
	ld iy, 3:i3
	ld (0x3523:16), 0

ToneGen_ScanPos_CompareLoop:
	cp iy, (0x344b:16)
	jr nz, ToneGen_ScanPos_CheckEnd
	cp de, (0x3530:16)
	jr nz, ToneGen_ScanPos_CheckEnd
	or (0x3523:16), 1
	jr VoiceState_CheckExit

ToneGen_ScanPos_CheckEnd:
	cp iy, (0x3449:16)
	jr nz, VoiceState_CheckExit
	cp de, (0x3532:16)
	jr nz, VoiceState_CheckExit
	or (0x3523:16), 2

VoiceState_CheckExit:
	cp iy, (0x3441:16)
	jr nz, ToneGen_ScanPos_AdvanceStep
	cp de, (0x3534:16)
	jr nz, ToneGen_ScanPos_AdvanceStep
	jr ToneGen_ScanPos_ProcessFlags

ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	ld a, (0x3523:16)
	and a, 0x3
	cp a, 0:i3
	jr z, PlaybackState_InitDone
	bit 1, (0x3523:16)
	jr nz, ToneGen_ScanPos_AdjustBit1
	ld iy, (0x344b:16)
	ld xix, (0x354c:16)
	ld (xix), iy
	ld xix, (0x3548:16)
	ld (xix), de
	ld (0x3435:16), c
	jr PlaybackState_InitDone

ToneGen_ScanPos_AdjustBit1:
	ld iy, (0x344d:16)
	and iy, 0xff
	ld wa, iy
	sub c, a
	jr c, ToneGen_ScanPos_WrapBlock
	cp c, 6:i3
	jr c, ToneGen_ScanPos_WrapBlock
	ld (0x3435:16), c
	ld xix, (0x354c:16)
	ld wa, (xix)
	sub wa, iy
	ld (xix), wa
	ld xix, (0x3548:16)
	ld (xix), de
	jr PlaybackState_InitDone

ToneGen_ScanPos_WrapBlock:
	sub c, 0x7
	ld (0x3435:16), c
	ld hl, de
	calr ToneGen_CalcBufferAddr
	ld wa, (xhl + 1)
	ld xix, (0x3548:16)
	ld (xix), wa
	xor w, w
	ld a, c
	ld xix, (0x354c:16)
	ld (xix), iy

PlaybackState_InitDone:
	ret

PlaybackState_InitDone_Pad:
	nop
	nop

ToneGen_InitPlaybackState:
	and (0x34d0:16), 191
	ld a, (0x379b:16)
	and a, 0x1f
	cp a, 0:i3
	jr nz, ToneGen_InitPlay_SetupTables
	or a, 0x10
	ld (0x379b:16), a

ToneGen_InitPlay_SetupTables:
	sla a, 2
	ld l, a
	xor h, h
	ld xix, ToneGen_InitPlay_SetupTables_Data
	ld	xix, (xix+hl)
	ld (0x3548:16), xix
	ld xix, ToneGen_InitPlay_SetupTables_Data_2
	ld	xix, (xix+hl)
	ld (0x354c:16), xix
	ld hl, (xix)
	ld (0x3441:16), hl
	ld xix, (0x3548:16)
	ld hl, (xix)
	ld (0x3534:16), hl
	ret

ToneGen_InitPlay_SetupTables_Pad:
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
	ld iy, 6:i3
	ld c, 0x6:opc

ToneGen_AdvVoiceStep_Return:
	ret

ToneGen_AdvanceVoiceStep_Pad:
	nop
	nop

AccPlayback_ProcessTempoAdvance:
	bit 2, (0x3713:16)
	jr z, AccPlayback_TempoAdv_Return
	and (0x34d0:16), 223
	calr ToneGen_CalcTempo
	calr ToneGen_AdvanceByTempo
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ld (0x3712:16), 4
	ld (0x3717:16), 255
	ld (0xe3e0:16), 16
	and (0x3713:16), 251

AccPlayback_TempoAdv_Return:
	ret

AccPlayback_ProcessTempoAdvance_Pad:
	nop
	nop

ToneGen_CalcTempo:
	ld l, (0x3714:16)
	cp l, 0:i3
	jr nz, ToneGen_CalcTempo_Lookup
	ld l, 0x6:opc

ToneGen_CalcTempo_Lookup:
	sla l, 1
	xor h, h
	push xix
	ld xix, ToneGen_CalcTempo_Lookup_Data
	ld	de, (xix+hl)
	ld l, (0x3715:16)
	sla l, 1
	ld	bc, (xix+hl)
	add de, bc
	pop xix
	ld wa, de
	ld l, 0x60:opc
	div wa, l
	ld (0x342f:16), w
	ld (0x3430:16), a
	ld a, (0x3716:16)
	cp a, 1:i3
	jr nz, ToneGen_CalcTempo_Mode0
	sla de, 2
	ld wa, de
	xor de, de
	ld hl, 5:i3
	ldfr_werp DE, 0xe2
	div xwa, hl
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode0:
	cp a, 0:i3
	jr nz, ToneGen_CalcTempo_Mode2
	ld wa, de
	sla wa, 4
	add wa, de
	add wa, de
	add wa, de
	xor de, de
	ldw hl, 0x14
	ldfr_werp DE, 0xe2
	div xwa, hl
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode2:
	cp a, 2:i3
	jr nz, ToneGen_CalcTempo_Mode3
	srl de, 1
	ld wa, de
	jr ToneGen_CalcTempoBeatsAndTicks

ToneGen_CalcTempo_Mode3:
	srl de, 2
	ld wa, de

ToneGen_CalcTempoBeatsAndTicks:
	ld l, 0x60:opc
	div wa, l
	ld (0x342d:16), w
	ld (0x342e:16), a
	or (0x34cf:16), 128
	ret

ToneGen_CalcTempo_DataTable:
	.byte	0x00, 0x00
ToneGen_CalcTempo_Lookup_Data:	.byte	0x00, 0x00, 0x08, 0x00, 0x0c, 0x00
	.byte 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00
	.byte 0x40, 0x00, 0x60, 0x00, 0xc0, 0x00, 0x80, 0x01
	.byte 0x00, 0x03, 0x80, 0x04, 0x00, 0x06

ToneGen_AdvanceByTempo:
	ld a, (0x342f:16)
	ld w, (0x3430:16)
	add a, (0x34fc:16)
	cp a, 0x60
	jr c, ToneGen_AdvTempo_StoreNote
	sub a, 0x60
	inc 1, w

ToneGen_AdvTempo_StoreNote:
	ld (0x34fc:16), a
	add w, (0x34fb:16)
	ld l, (0x34d9:16)
	ld h, (0x34d7:16)
	and h, 0x7
	inc 1, h

ToneGen_AdvTempo_WrapLoop:
	cp w, l
	jr c, ToneGen_AdvTempo_StoreBeat
	sub w, l
	inc 1, (0x34fa:16)
	cp h, (0x34fa:16)
	jr nz, ToneGen_AdvTempo_Continue
	ld (0x34fa:16), 0

ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	ld (0x34fb:16), w
	ret

ToneGen_AdvTempo_StoreBeat_Pad:
	nop
	nop

AccPlayback_UpdateRhythmSustain:
	ld a, (0x3518:16)
	cp a, 0:i3
	jr z, AccPlayback_RhythmSust_Return
	dec 1, a
	ld (0x3518:16), a
	cp a, 0:i3
	jr nz, AccPlayback_RhythmSust_Return
	ld a, (0x3516:16)
	ld e, (0x3517:16)
	ld d, 0x0:opc
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

AccPlayback_UpdateRhythmSustain_Pad:
	nop
	nop

AccPlayback_ProcessVoiceType5:
	bit 5, (0x34d0:16)
	jr z, AccVoice_DispatchType5Handler
	cp (0x3712:16), 4
	jr nz, AccVoice_DispatchType5Handler
	ld a, (0x372d:16)
	and a, 0xc
	cp a, 0:i3
	jr z, AccVoiceType5_CheckBit01
	calr ToneGen_AdjustVoiceVelocity

AccVoiceType5_CheckBit01:
	ld a, (0x372d:16)
	and a, 0x3
	cp a, 0:i3
	jr z, AccVoice_DispatchType5Handler
	calr ToneGen_AdjustVolumePan

AccVoice_DispatchType5Handler:
	bit 5, (0x34d0:16)
	jr z, TempoCheck_Exit
	cp (0x3712:16), 5
	jr nz, TempoCheck_Exit
	ld a, (0x372d:16)
	and a, 0x30
	cp a, 0:i3
	jr z, TempoCheck_Exit
	calr ToneGen_ProcessStereoType

TempoCheck_Exit:
	ret

AccVoice_DispatchType5Handler_Pad:
	nop
	nop

ToneGen_AdjustVoiceVelocity:
	ld wa, (0x3512:16)
	ld (0x3449:16), wa
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x3435:16), 0
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp a, 0x81
	jrl z, ToneGen_AdjVel_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	bit 4, (0x379b:16)
	jr z, ToneGen_AdjVel_CheckBit2
	ld w, (0xfbbe:16)
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	xor d, d
	ld e, a
	ld c, w
	xor b, b
	ld wa, 1:i3
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l

ToneGen_AdjVel_CheckBit2:
	bit 2, (0x372d:16)
	jr z, ToneGen_AdjVel_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVel_ClampHigh
	ld a, 0x7f:opc

ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_AdjVel_StoreAndParam
	ld a, 0x0:opc

ToneGen_AdjVel_StoreAndParam:
	ld e, a
	bit 4, (0x379b:16)
	jr z, ToneGen_AdjVel_WriteToBuffer
	ld w, (0xfbbe:16)
	push xwa
	push xbc
	push xde
	push xix
	push xiy
	xor bc, bc
	ld c, w
	ld wa, 2:i3
	xor d, d
	call Param_SignExtendReturn
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xwa
	ld a, l

ToneGen_AdjVel_WriteToBuffer:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	pushw ix
	ld ix, (0x3449:16)
	ld	(xhl+ix), a
	ld (0x3718:16), e
	popw ix
	push xde
	call AccScreen_DrawInit_StackWrap
	pop xde
	ld a, (0x379b:16)
	and a, 0xf
	cp a, 0:i3
	jr z, ToneGen_AdjVel_Return
	calr ToneGen_WriteMultiChanParam

ToneGen_AdjVel_Return:
	ret

ToneGen_AdjVel_WriteToBuffer_Pad:
	nop
	nop

ToneGen_AdjustVolumePan:
	ld wa, (0x3512:16)
	ld (0x3449:16), wa
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x3435:16), 0
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp a, 0x81
	jr z, ToneGen_AdjVol_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	bit 0, (0x372d:16)
	jr z, ToneGen_AdjVol_Decrement
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_AdjVol_ClampHigh
	ld a, 0x7f:opc

ToneGen_AdjVol_ClampHigh:
	jr ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_Decrement:
	dec 1, a
	cp a, 0:i3
	jr z, ToneGen_AdjVol_ClampLow
	cp a, 0xff
	jr nz, ToneGen_AdjVol_WriteToBuffer

ToneGen_AdjVol_ClampLow:
	ld a, 0x1:opc

ToneGen_AdjVol_WriteToBuffer:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	pushw ix
	ld ix, (0x3449:16)
	ld	(xhl+ix), a
	ld (0x3717:16), a
	popw ix
	call AccScreen_UpdateBeat_StackWrap

ToneGen_AdjVol_Return:
	ret

ToneGen_AdjVol_WriteToBuffer_Pad:
	nop
	nop

ToneGen_ProcessStereoType:
	ld wa, (0x3512:16)
	ld (0x3449:16), wa
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x3435:16), 0
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp a, 0x81
	jr z, ToneGen_Stereo_Return
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	c, (xhl+wa)
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x3449:16)
	ld	a, (xhl+wa)
	cp c, 0xd3
	jr z, ToneGen_Stereo_ClampLow
	bit 4, (0x372d:16)
	jr z, ToneGen_Stereo_Increment
	inc 1, a
	cp a, 0x80
	jr c, ToneGen_Stereo_CheckInc
	ld a, 0x7f:opc

ToneGen_Stereo_CheckInc:
	jr ToneGen_Stereo_Decrement

ToneGen_Stereo_Increment:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_Stereo_Decrement
	ld a, 0x0:opc

ToneGen_Stereo_Decrement:
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_ClampLow:
	bit 4, (0x372d:16)
	jr z, ToneGen_Stereo_Store
	ld a, 0x7f:opc
	jr ToneGen_Stereo_WriteParam

ToneGen_Stereo_Store:
	ld a, 0x0:opc

ToneGen_Stereo_WriteParam:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	pushw ix
	ld ix, (0x3449:16)
	ld	(xhl+ix), a
	ld (0x3721:16), a
	popw ix
	call AccScreen_DrawMeasure_StackWrap

ToneGen_Stereo_Return:
	ret

ToneGen_Stereo_WriteParam_Code:
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
	jp16 6214
	popw ix
	popw hl
	scf
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
	ld	(PEFC:8), 60:io
	ld	xwa, 0x4906053f
	max
	.ascii "JHmnopqrstuvwxyz{|}~"
	jrl	nc, 14
	nop
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	jp	0x09121d
	ldw	(P2FC:8), 3340:io
	ret
	normal
	push	sr
	pop	sr
	max
	halt
	reti
	retd	4368
	push_a
	pop_a
	ex_ff
	ldf	24
	pop_f
	jp16 7708
	.ascii "FGmnopqrstuvwxyz{|}~"
	.byte 0x7f

ToneGen_WriteMultiChanParam:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld iy, (0x3512:16)
	ld	d, (xhl+iy)
	xor h, h
	ld l, e
	push xix
	ld xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+hl)
	pop xix
	ld e, 0x90:opc
	bit 6, (0x34ea:16)
	jr z, ToneGen_MultiChan_Compare
	bit 3, (0x379b:16)
	jr z, ToneGen_MultiChan_Compare
	jr ToneGen_MultiChan_AdjustVel

ToneGen_MultiChan_Compare:
	bit 5, (0x34ea:16)
	jr z, AccVoice_ResolveNoteOnOffType
	bit 3, (0x379b:16)
	jr nz, AccVoice_ResolveNoteOnOffType

ToneGen_MultiChan_AdjustVel:
	cp a, 7:i3
	jr nz, AccVoice_ResolveNoteOnOffType
	ld e, 0x91:opc
	jr ToneGen_MultiChan_CheckBit4

AccVoice_ResolveNoteOnOffType:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, ToneGen_LoadRhythmPatternParams_Data
	add xix, xhl
	ld a, (xix)
	pop xix
	cp a, 0:i3
	jr z, ToneGen_MultiChan_CheckBit4
	ld e, 0x91:opc

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
	calr ToneGen_CompareVoiceBlocks_Helper
	calr ToneGen_CompareVoiceBlocks_Helper2
	calr ToneGen_CompareVoiceBlocks_Helper3
	calr ToneGen_StepWithBoundsCheck
	ret

ToneGen_MultiChan_Return:
	nop
	nop

ToneGen_CompareVoiceBlocks_Helper:
	ld wa, (0x3512:16)
	ld (0x3449:16), wa
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x3435:16), 0
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x3436:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x3437:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x3438:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x3439:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x343a:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x343b:16), a
	ret

ToneGen_VoiceParamDisp_Return:
	nop
	nop

ToneGen_CompareVoiceBlocks_Helper2:
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld (0x365a:16), wa
	ld (0x3530:16), wa
	ld iy, (0x3512:16)
	ld (0x344b:16), iy
	ld (0x3449:16), iy
	ld (0x3660:16), iy
	ld wa, iy
	ld (0x3435:16), a
	ld (0x344d:16), 6
	ld iy, (0x3512:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x90
	jr z, ToneGen_CalcBeatSubdivision
	ld (0x344d:16), 8
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot

ToneGen_CalcBeatSubdivision:
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld wa, (0x346b:16)
	ld (0x3658:16), wa
	ld (0x3532:16), wa
	xor w, w
	ld a, (0x3435:16)
	ld (0x365e:16), wa
	calr ToneGen_ScanVoicePosition
	call AccPatch_CopySequenceEntry
	ret

ToneGen_CalcBeat_Return:
	nop
	nop

ToneGen_CompareVoiceBlocks_Helper3:
	ld xiy, 0x366a
	ld a, (0x3436:16)
	ld (xiy), a
	ld a, (0x3437:16)
	ld (xiy + 1), a
	ld a, (0x3438:16)
	ld (xiy + 2), a
	ld a, (0x3439:16)
	ld (xiy + 3), a
	ld a, (0x343a:16)
	ld (xiy + 4), a
	ld a, (0x343b:16)
	ld (xiy + 5), a
	ld a, (0x3438:16)
	xor h, h
	ld l, a
	push xix
	ld xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+hl)
	pop xix
	bit 6, (0x34ea:16)
	jr z, ToneGen_ReadBufferUtility
	bit 3, (0x379b:16)
	jr z, ToneGen_ReadBufferUtility
	jr ToneGen_ReadBufUtil_Loop

ToneGen_ReadBufferUtility:
	bit 5, (0x34ea:16)
	jr z, AccVoice_WriteNoteEventToBuffer
	bit 3, (0x379b:16)
	jr nz, AccVoice_WriteNoteEventToBuffer

ToneGen_ReadBufUtil_Loop:
	cp a, 7:i3
	jr nz, AccVoice_WriteNoteEventToBuffer
	ld (xiy), 0x91
	ld (xiy + 6), 0x3
	ld (xiy + 7), 0x0
	jr AccVoice_WriteNoteEventToBuffer_Join

AccVoice_WriteNoteEventToBuffer:
	xor xhl, xhl
	ld l, a
	sla a, 1
	add l, a
	push xix
	ld xix, ToneGen_LoadRhythmPatternParams_Data
	add xix, xhl
	ld a, (xix)
	ld (xiy), 0x90
	cp a, 0:i3
	jr z, ToneGen_ReadBufUtil_Return
	ld (xiy), 0x91
	ld a, (xix + 1)
	ld (xiy + 6), a
	ld a, (xix + 2)
	ld (xiy + 7), a

ToneGen_ReadBufUtil_Return:
	pop xix

AccVoice_WriteNoteEventToBuffer_Join:
	ret

AccVoice_WriteNoteEventToBuffer_Pad:
	nop
	nop

ToneGen_StepWithBoundsCheck:
	cpw (0x34d4:16), 0
	jr z, ToneGen_SeqAdvanceMain
	ld xiy, 0x366a
	ld a, (xiy)
	ldw (0x360a:16), 6
	cp a, 0x90
	jr z, ToneGen_StepBounds_Return
	ldw (0x360a:16), 8

ToneGen_StepBounds_Return:
	ld wa, (0x3514:16)
	ld (0x346b:16), wa
	ld iy, (0x3512:16)
	ld wa, iy
	ld (0x3435:16), a
	ld wa, (0x346b:16)
	ld (0x3602:16), wa
	xor w, w
	ld a, (0x3435:16)
	ld (0x3604:16), wa
	ld wa, (0x3604:16)
	ld (0x3445:16), wa
	ld wa, (0x3602:16)
	ld (0x3447:16), wa
	ld wa, (0x360a:16)
	ld (0x344b:16), wa
	call AccPatch_InitSlotAndCopyData
	calr ToneGen_AdvanceSeqList
	jr ToneGen_SeqAdv_Return

ToneGen_SeqAdvanceMain:
	ld (GLOBAL_ERROR_CODE:16), 15
	ld (0xe3dc:16), 238
	ld (0xe3de:16), 64
	ld a, 0x8:opc
	call MIDI_SendSysExCmd

ToneGen_SeqAdv_Return:
	ret

ToneGen_SeqAdvanceMain_Pad:
	nop
	nop

AccVoice_ReadCurrentToneType:
	push xiy
	push xhl
	xor xiy, xiy
	ld iy, (0x3449:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	add xhl, xiy
	ld a, (xhl + 1)
	cp a, 0x87
	jr nz, ToneGen_InterpolateParam
	ld hl, (0x346b:16)
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
	ld iy, (0x3449:16)
	inc 1, iy
	inc 1, (0x3435:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x87
	jr z, ToneGen_Interp_StoreResult
	cp a, 0x83
	jr nz, ToneGen_Interp_WrapPoint
	jr ToneGen_Interp_CheckExit

ToneGen_Interp_StoreResult:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld hl, (xhl + 3)
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld iy, 6:i3
	ld (0x3435:16), 6
	jr ToneGen_Interp_WrapPoint

ToneGen_Interp_CheckExit:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_GetSlotIndex
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld iy, 6:i3
	ld (0x3435:16), 6

ToneGen_Interp_WrapPoint:
	ld (0x3449:16), iy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Done:
	nop
	nop

ToneGen_StepToNextStereoSlot:
	push xiy
	push xhl
	ld iy, (0x3449:16)
	inc 1, iy
	inc 1, (0x3435:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x87
	jr nz, ToneGen_Interp_Return
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_Return:
	inc 1, iy
	inc 1, (0x3435:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x87
	jr nz, ToneGen_Interp_OverflowCheck
	calr ToneGen_StepToNextBuffer

ToneGen_Interp_OverflowCheck:
	ld (0x3449:16), iy
	pop xhl
	pop xiy
	ret

ToneGen_Interp_OverflowDone:
	nop
	nop

ToneGen_StepToNextBuffer:
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	xor iy, iy
	ld hl, (xhl + 3)
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld iy, 6:i3
	ld (0x3435:16), 6
	ret

ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, ToneGen_StepToNextBuffer_Return
	ld iy, (xhl+0:8)
ToneGen_StepToNextBuffer_Return:
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

ToneGen_ReadBufferWithIndirection_Pad:
	nop
	nop

ToneGen_StepVoiceForward:
	push xiy
	push xhl
	ld iy, (0x3449:16)
	dec 1, iy
	dec 1, (0x3435:16)
	ld hl, (0x346b:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp a, 0x87
	jr nz, ToneGen_StepFwd_WrapDone
	ld hl, (xhl + 1)
	cp hl, 0xffff
	jr z, ToneGen_StepFwd_CheckWrap
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ldw iy, 0xfe
	ld (0x3435:16), 254
	jr ToneGen_StepFwd_WrapDone

ToneGen_StepFwd_CheckWrap:
	ld hl, (0x3606:16)
	ld (0x346b:16), hl
	calr ToneGen_CalcBufferAddr
	ld hl, (0x3608:16)
	dec 1, hl
	ld iy, hl
	ld (0x3435:16), l

ToneGen_StepFwd_WrapDone:
	ld (0x3449:16), iy
	pop xhl
	pop xiy
	ret

ToneGen_StepFwd_Exit:
	nop
	nop

ToneGen_StepFwd_Alternate:
	ld e, (0x371a:16)
	ld d, (0x3747:16)
	ld c, (0x3746:16)
	ld b, (0x34d7:16)
	cp (0x34d9:16), 4
	jr ugt, ToneGen_StepAlt_Overflow
	cp b, 3:i3
	jr ugt, ToneGen_StepAlt_CheckBeat
	ld c, 0x0:opc
	jr ToneGen_StepAlt_Return

ToneGen_StepAlt_CheckBeat:
	calr ToneGen_StepAlt_CheckBeat_Helper
	calr ChordDetect_CheckDescending
	calr ChordDetect_CheckRoot1
	calr ChordDetect_CheckInversion1

ToneGen_StepAlt_Return:
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_Overflow:
	cp b, 1:i3
	jr ugt, ToneGen_StepAlt_OverflowDone
	ld c, 0x0:opc
	jr ToneGen_StepAlt_StoreResult

ToneGen_StepAlt_OverflowDone:
	calr ChordDetect_CheckAscending
	calr ChordDetect_CheckMirror
	calr ChordDetect_CheckRoot2
	calr ChordDetect_CheckInversion2

ToneGen_StepAlt_StoreResult:
	ld (0x3746:16), c
	xor d, d
	ld (0x3747:16), de
	calr AccPlayback_DetectMeasurePos
	ret

ToneGen_StepAlt_Done:
	nop
	nop

ToneGen_StepAlt_CheckBeat_Helper:
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

RhythmParam_CheckExit6_Pad:
	nop
	nop

ChordDetect_CheckDescending:
	cp c, 0:i3
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

ToneGen_NullRet2_Pad:
	nop
	nop

ChordDetect_CheckRoot1:
	cp c, 0:i3
	jr nz, RhythmParam_CheckExit5
	cp d, 1:i3
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

RhythmParam_CheckExit5_Pad:
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
	cp e, 1:i3
	jr nz, RhythmParam_CheckExit4
	ld c, 0x0:opc

RhythmParam_CheckExit4:
	ret

RhythmParam_CheckExit4_Pad:
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

RhythmParam_CheckExit3_Pad:
	nop
	nop

ChordDetect_CheckMirror:
	cp c, 0:i3
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

Rhythm_NullRet_Pad:
	nop
	nop

ChordDetect_CheckRoot2:
	cp c, 0:i3
	jr nz, RhythmParam_CheckExit2
	cp d, 1:i3
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

RhythmParam_CheckExit2_Pad:
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
	cp e, 1:i3
	jr nz, RhythmParam_ValidExit
	ld c, 0x0:opc

RhythmParam_ValidExit:
	ret

RhythmParam_ValidExit_Pad:
	nop
	nop

AccPlayback_DetectMeasurePos:
	ld a, c
	inc 1, a
	cp (0x34d9:16), 4
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
	ld (0x3746:16), c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SetUpper:
	ld c, e
	sub c, 0x3
	dec 1, c
	ld (0x3746:16), c
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
	ld (0x3746:16), c
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallUpper:
	ld c, e
	sub c, 0x1
	dec 1, c
	ld (0x3746:16), c

RhythmChannel_NullRet:
	ret

RhythmChannel_NullRet_Pad:
	nop
	nop

AccPlayback_InitPartAssignment:
	xor wa, wa
	ld (0x373e:16), wa
	ld (0x3740:16), wa
	ld (0x3742:16), wa
	ld (0x3744:16), wa
	jr AccPlayback_PartAssign_Check4
	ld a, (0x34d9:16)
	cp a, 4:i3
	jr ule, AccPlayback_PartAssign_Store
	cp (0x34fb:16), 4
	jr nc, AccPlayback_PartAssign_Sub4
	ld a, 0x4:opc
	jr AccPlayback_PartAssign_Store

AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	ld (0x373e:16), a
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_Check4:
	cp (0x34d9:16), 4
	jrl ugt, AccPlayback_PartAssign_LargeBeat
	cp (0x34d7:16), 2
	jr ugt, AccPlayback_PartAssign_LargeMeasure
	cp (0x3746:16), 0
	jr z, AccPlayback_PartAssign_SmallPart
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_SmallPart:
	ld a, (0x34d9:16)
	ld (0x373e:16), a
	ld (0x3742:16), 1
	cp (0x34d7:16), 1
	jr c, AccPlayback_PartAssign_Check2
	ld (0x373f:16), a
	ld (0x3743:16), 2

AccPlayback_PartAssign_Check2:
	cp (0x34d7:16), 2
	jr c, AccPlayback_PartAssign_Check3
	ld (0x3740:16), a
	ld (0x3744:16), 3

AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	ld a, (0x34d7:16)
	sub a, (0x3746:16)
	cp a, 2:i3
	jr gt, AccPlayback_PartAssign_FullSetup
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_FullSetup:
	ld a, (0x34d9:16)
	ld (0x373e:16), a
	ld (0x373f:16), a
	ld (0x3740:16), a
	ld (0x3741:16), a
	ld a, (0x3746:16)
	inc 1, a
	ld (0x3742:16), a
	inc 1, a
	ld (0x3743:16), a
	inc 1, a
	ld (0x3744:16), a
	inc 1, a
	ld (0x3745:16), a
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat:
	cp (0x34d7:16), 0
	jr nz, AccPlayback_PartAssign_LargeBeat2
	cp (0x3746:16), 0
	jr nz, RhythmFunc_NullRet
	ld (0x373e:16), 4
	ld a, (0x34d9:16)
	sub a, 0x4
	ld (0x373f:16), a
	ld (0x3742:16), 1
	jr RhythmFunc_NullRet

AccPlayback_PartAssign_LargeBeat2:
	ld a, (0x34d7:16)
	sub a, (0x3746:16)
	cp a, 0:i3
	jr le, RhythmFunc_NullRet
	ld (0x373e:16), 4
	ld a, (0x34d9:16)
	sub a, 0x4
	ld (0x373f:16), a
	ld (0x3740:16), 4
	ld (0x3741:16), a
	ld a, (0x3746:16)
	inc 1, a
	ld (0x3742:16), a
	inc 1, a
	ld (0x3744:16), a

RhythmFunc_NullRet:
	ret

; CmStep_DebugShowHexBytes -- on title 0xB6 (TITLE_CMSTEP) only, print six RAM bytes (0x370F, 0x371A, 0x3718,
;          0x3717, 0x3714, 0x3715) as two hex digits each at fixed screen positions (IX 480, 6962, 6967 ...).
;          A debug readout: CmStep_DebugPrintHexByte splits the byte with CmStep_DebugSplitHexDigits and passes
;          each digit to CmStep_DebugPutCharStub, which is a bare `ret` -- nothing is drawn.  No call, jump or
;          pointer reaches the block; its branches are symbolic because a trace seeded at its first byte
;          reaches each of them and its target (notes/r3-trace-2026-10-02, --seed).  Was named as data
;          (AccPlayback_PartAssign_DataBlock).
CmStep_DebugShowHexBytes:
	nop
	nop
	cp	(ACTIVE_TITLE:16), 182
	jr	z, CmStep_DebugShowHexBytes_OnCmStep
	jr	CmStep_DebugShowHexBytes_Return
CmStep_DebugShowHexBytes_OnCmStep:
	ld	a, (0x370f:16)
	ldw	ix, 480
	calr	CmStep_DebugPrintHexByte
	ld	a, (0x371a:16)
	ldw	ix, 6962
	calr	CmStep_DebugPrintHexByte
	ld	a, (0x3718:16)
	ldw	ix, 6967
	calr	CmStep_DebugPrintHexByte
	ld	a, (0x3717:16)
	ldw	ix, 6972
	calr	CmStep_DebugPrintHexByte
	ld	a, (0x3714:16)
	ldw	ix, 6977
	calr	CmStep_DebugPrintHexByte
	ld	a, (0x3715:16)
	ldw	ix, 6982
	calr	CmStep_DebugPrintHexByte
CmStep_DebugShowHexBytes_Return:
	ret
	nop
	nop
CmStep_DebugPrintHexByte:
	calr	CmStep_DebugSplitHexDigits
	pushw	ix
	ld	a, d
	calr	CmStep_DebugPutCharStub
	popw	ix
	inc	1, ix
	ld	a, e
	calr	CmStep_DebugPutCharStub
	ret
	nop
	nop
CmStep_DebugPutCharStub:
	ret
	nop
	nop
CmStep_DebugSplitHexDigits:
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

AccPat_ShiftAndMask_Pad:
	nop
	nop

AccPat_IndexToAddress:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, RHYTHM_PATTERN_BUF_B
	ret

AccPat_InlineFunctions_DataBlock:
	nop
	nop
AccPat_IndexToAddress_Sub2:
	and	xhl, 0xffff
	sla	xhl, 8
	add	xhl, RHYTHM_PATTERN_BUF_B
	ret
	push	xwa
	push	xix
	ld	wa, hl
	and	xhl, 4095
	sla	xhl, 8
	and	wa, 0xf000
	srl	wa, 10
	ld	xix, AccPat_InlineFunctions_DataBlock_Code
	ld	xix, (xix+wa)
	add	xhl, xix
	pop	xix
	pop	xwa
	ret
AccPat_InlineFunctions_DataBlock_Code:
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
AccPat_IndexToAddress_Sub:
	push	xiz
	calr	AccPat_DispatchNoteChange
	pop	xiz
	ret

AccPat_DispatchNoteChange:
	bit 0, (0x34d1:16)
	jr nz, AccPat_Dispatch_AllocAndProcess
	jp AccPat_Dispatch_Return

AccPat_Dispatch_AllocAndProcess:
	ld xwa, 0x800
	push xwa
	call Malloc
	add xsp, 0x4
	ld (0x3564:16), xhl
	ld a, (0x34ed:16)
	ld w, (0x34ee:16)
	pushw wa
	and (0x34d1:16), 254
	and (0x35b0:16), 254
	ld a, (0x34ed:16)
	cp a, 0x80
	jr c, AccPat_Dispatch_LowRange
	cp a, 0xa0
	jrl nc, AccPat_CleanupAndFree
	cp (0x34ef:16), 26
	jr nz, AccPat_Dispatch_CalcAccent
	calr AccWidget_ProcessSpecialCmd
	jrl AccPat_CleanupAndFree

AccPat_Dispatch_CalcAccent:
	calr AccPat_CalcAccentVelocity
	ld a, (0x34ed:16)
	and a, 0x7f
	cp a, (0x34d6:16)
	jr z, AccPat_CleanupAndFree
	cp a, 0x1e
	jr nc, AccPat_CleanupAndFree
	or (0x34cd:16), 128
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	jr AccPat_Dispatch_CheckBit0

AccPat_Dispatch_LowRange:
	or (0x34cd:16), 128
	cp (0x34ef:16), 26
	jr nz, AccPat_Dispatch_InitWorkArea
	calr RhythmROM_LoadDrumKit
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	bit 0, (0x35b0:16)
	jr nz, AccPat_Dispatch_InitSlot
	cp (CURRENT_TITLE:16), 184
	jr nz, AccPat_CleanupAndFree
	ld (GLOBAL_ERROR_CODE:16), 20
	call DrumVoice_NotifyEE
	jr AccPat_CleanupAndFree

AccPat_Dispatch_InitSlot:
	call AccPatch_InitCurrentSlot
	ld (GLOBAL_ERROR_CODE:16), 23
	call DrumVoice_NotifyEE
	ld a, 0x8:opc
	call MIDI_SendSysExCmd

AccPat_CleanupAndFree:
	popw wa
	ld (0x34ed:16), a
	ld (0x34ee:16), w
	ld xwa, (0x3564:16)
	push xwa
	call Free
	add xsp, 0x4

AccPat_Dispatch_Return:
	ret

AccPat_CleanupAndFree_Pad:
	nop
	nop

DualVoice_ParamLoadDone:
	push xiz
	calr AccPatch_LoadDualVoiceParams
	pop xiz
	ret

AccPatch_LoadDualVoiceParams:
	ld l, (0x39ac:16)
	cp l, 0x1e
	jr c, AccPat_DualVoice_ClampIndex
	xor l, l

AccPat_DualVoice_ClampIndex:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add xiy, (0x39ae:16)
	add xiy, 0x60
	ld (0x355c:16), xiy
	ld l, (0x39ad:16)
	cp l, 0x1e
	jr c, AccPat_DualVoice_ClampIndex2
	xor l, l

AccPat_DualVoice_ClampIndex2:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add xiy, (0x39b2:16)
	add xiy, 0x60
	ld (0x3560:16), xiy
	ld xiy, (0x355c:16)
	add xiy, 0xc
	ld xix, (0x3560:16)
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
	ld	l, (0x34ed:16)
	and	l, 127
	cp	l, 30
	jr	c, AccPatch_LoadDualVoiceParams_Skip2
	xor	l, l
AccPatch_LoadDualVoiceParams_Skip2:
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 96
	ld	(0x355c:16), xiy
	ld	l, (0x34d6:16)
	cp	l, 30
	jr	c, AccPatch_LoadDualVoiceParams_Skip
	xor	l, l
AccPatch_LoadDualVoiceParams_Skip:
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 96
	ld	(0x3560:16), xiy
	ret
AccPat_DualVoice_ReadParamsA:
	ld xiy, (0x355c:16)
	ld hl, (xiy + 0:8)
	ld (0x35a4:16), hl
	ld hl, (xiy + 4)
	ld (0x35a6:16), hl
	ld hl, (xiy + 6)
	ld (0x35a8:16), hl
	ld hl, (xiy + 8)
	ld (0x35aa:16), hl
	ld hl, (xiy + 10)
	ld (0x35ac:16), hl
	ret

AccPat_DualVoice_ReadParamsA_Pad:
	nop
	nop

AccPatch_LoadDualVoiceParamsB:
	ld xiy, (0x3560:16)
	ld hl, (xiy + 0:8)
	ld (0x3598:16), hl
	ld hl, (xiy + 4)
	ld (0x359a:16), hl
	ld hl, (xiy + 6)
	ld (0x359c:16), hl
	ld hl, (xiy + 8)
	ld (0x359e:16), hl
	ld hl, (xiy + 10)
	ld (0x35a0:16), hl
	ret

AccPatch_LoadDualVoiceParamsB_Pad:
	nop
	nop

AccPat_DualVoice_CopyAllBanks:
	ld iy, (0x35a4:16)
	ld ix, (0x3598:16)
	calr ToneBank_CopyEntry
	ld iy, (0x35a6:16)
	ld ix, (0x359a:16)
	calr ToneBank_CopyEntry
	ld iy, (0x35a8:16)
	ld ix, (0x359c:16)
	calr ToneBank_CopyEntry
	ld iy, (0x35aa:16)
	ld ix, (0x359e:16)
	calr ToneBank_CopyEntry
	ld iy, (0x35ac:16)
	ld ix, (0x35a0:16)
	calr ToneBank_CopyEntry
	ret

AccPat_DualVoice_CopyAllBanks_Pad:
	nop
	nop

ToneBank_CopyEntry:
	ld (0x3596:16), ix
	ld (0x35a2:16), iy
	ld hl, iy
	ld xwa, (0x39ae:16)
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	ld (0x35ae:16), wa
	ld hl, (0x3596:16)
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ld hl, (0x35a2:16)
	ld xwa, (0x39ae:16)
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xf9
	ldir85

ToneBank_CopyEntry_Join:
	cpw (0x35ae:16), 0xffff
	jrl z, ToneBank_CopyComplete_Return
	calr ToneBank_CopyChunk_Return
	bit 0, (0x35b0:16)
	jr nz, ToneBank_CopyComplete_Return
	decw 1, (0x34d4:16)
	ld hl, de
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	ormi8 (xhl), 0x80
	ld hl, (0x3596:16)
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	ld (xhl + 3), de
	ld hl, de
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	ld wa, (0x3596:16)
	ld (xhl + 1), wa
	ld (0x3596:16), de
	ld wa, (0x35ae:16)
	ld (0x35a2:16), wa
	ld hl, wa
	ld xwa, (0x39ae:16)
	calr ToneBank_ComputeEntryAddress
	ld wa, (xhl + 3)
	ld (0x35ae:16), wa
	calr AccPat_ShiftAndMask
	ld hl, (0x3596:16)
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	ld xix, xhl
	ld hl, (0x35a2:16)
	ld xwa, (0x39ae:16)
	calr ToneBank_ComputeEntryAddress
	ld xiy, xhl
	add xiy, 0x6
	add xix, 0x6
	ldw bc, 0xf9
	ldir85
	jrl ToneBank_CopyEntry_Join

ToneBank_CopyComplete_Return:
	ld hl, (0x3596:16)
	ld xwa, (0x39b2:16)
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

ToneBank_ComputeEntryAddress_Join:
	cp de, 0x154
	jr nc, ToneBank_ComputeAddr_CheckRange
	ld hl, de
	ld xwa, (0x39b2:16)
	calr ToneBank_ComputeEntryAddress
	bitm 7, (xhl)
	jr z, ToneBank_ComputeAddr_Return
	inc 1, de
	jr ToneBank_ComputeEntryAddress_Join

ToneBank_ComputeAddr_CheckRange:
	or (0x35b0:16), 1

ToneBank_ComputeAddr_Return:
	ret

AccFill_ProcessDone_Helper:
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
	or (0x35b0:16), 1

ToneBank_SwapCopy_Pad:
	ret

ToneBank_SwapCopy_Pad_Code:
	nop
	nop
	ldw	de, 150
AccFill_ProcessDone_Helper_Join:
	cp	de, 340
	jr	nc, AccFill_ProcessDone_Helper_Skip
	ld	hl, de
	calr	AccPat_IndexToAddress_Sub2
	bit	7, (xhl)
	jr	z, AccFill_ProcessDone_Helper_Skip2
	inc	1, de
	jr	AccFill_ProcessDone_Helper_Join
AccFill_ProcessDone_Helper_Skip:
	or	(0x35b0:16), 1
AccFill_ProcessDone_Helper_Skip2:
	or	de, 0x8000
	ret

RhythmROM_PatternDispatcher:
	and (0x35b0:16), 249
	ld l, (0x34ed:16)
	ld h, (0x34ee:16)
	call VoiceParam_ClampAndValidate_Tramp
	ld (0x34ed:16), l
	ld (0x34ee:16), h
	sla l, 1
	sla hl, 1
	ld xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	ld (0x355a:16), wa
	add hl, 0x2
	ld	wa, (xiy+hl)
	ld (0x355c:16), wa
	ld l, (0x34d6:16)
	cp l, 0x1e
	jr c, AccPat_CalcAccentVelocity_Body
	xor l, l

AccPat_CalcAccentVelocity_Body:
	sla l, 2
	xor h, h
	ld xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add xiy, RHYTHM_PATTERN_BUF_A
	add xiy, 0x60
	ld (0x3560:16), xiy
	calr RhythmROM_LoadPattern
	cp (0x34ef:16), 0
	jr z, RhythmROM_LoadAndInit
	cp (0x34ef:16), 1
	jr z, RhythmROM_LoadAndInit
	cp (0x34ef:16), 2
	jr z, RhythmROM_LoadAndInit
	cp (0x34ef:16), 3
	jr z, RhythmROM_LoadAndInit
	calr AccPat_CalcAccentVelocity_Body_Helper
	calr AccPatch_LoadDualVoiceParamsB
	calr VoiceSlot_Resolve_Loop
	jr AccPat_CalcAccent_Return

RhythmROM_LoadAndInit:
	calr DrumKit_DataTable_Entry0
	calr AccPatch_LoadDualVoiceParamsB
	calr AccSection_ProcessEntry

AccPat_CalcAccent_Return:
	ret

RhythmROM_LoadAndInit_Pad:
	nop
	nop

RhythmROM_LoadPattern:
	ld wa, (0x355a:16)
	ld w, a
	calr RhythmROM_CalcPatternAddr
	xor xiy, xiy
	ld iy, (0x355c:16)
	add xiy, xix
	ld xix, (0x3564:16)
	ldw bc, 0x400
	ldirw
	ld l, (0x34ef:16)
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, RhythmROM_LoadPattern_Data
	xor xwa, xwa
	ld	wa, (xix+hl)
	jr RhythmROM_PatternDisp_ReadByte
; RhythmROM_LoadPattern +0x34 -- 16 x LE16 byte offsets into the rhythm pattern
; buffer.  ** RE-TYPED 2026-09-25 (lane accomp): was `xor de,(0x03d803:24)`,
; reti, neg wa ... and -- by this lane's own third re-frame pass, now undone --
; two `.byte` "xor HL,(rD3L+QB0)" readings (data-as-code).  Read by the
; routine it sits in, RhythmROM_LoadPattern:
;     ld l,(0x34ef) / and l,0xf / xor h,h / sla hl,1 /
;     ld xix, RhythmROM_LoadPattern_Data / xor xwa,xwa / ldw_sri WA,(xix+hl)
; then RhythmROM_PatternDisp_ReadByte adds WA to the pointer in (0x3564) and
; reads the byte there.  16 entries: `and l, 0xf`; the table ends exactly at
; RhythmROM_PatternDisp_ReadByte.  The label RhythmROM_PatternDisp_InitLoop
; that sat inside it (a symboliser target of a phantom branch, referenced
; nowhere) is dropped.
; readers in v9/v10 (address from the linked ELF): RhythmROM_LoadPattern 0xF6358D,
;     RhythmROM_PatternDisp_ReadByte 0xF635E1
RhythmROM_LoadPattern_Data:
	.short 0x03d2, 0x03d8, 0x07d2, 0x07d8, 0x03d3, 0x07d3, 0x03d3, 0x07d3
	.short 0x03d2, 0x03d2, 0x03d8, 0x03d8, 0x07d2, 0x07d2, 0x07d8, 0x07d8

RhythmROM_PatternDisp_ReadByte:
	ld xiy, (0x3564:16)
	add xiy, xwa
	ld a, (xiy)
	ld (0x35b1:16), a
	ld xiy, (0x3564:16)
	ld xix, (0x3560:16)
	add xix, 0xc
	ld	a, (xiy+976)
	ld (xix), a
	inc 1, xix
	push xix
	calr RhythmROM_PatternDisp_ReadByte_Helper
	pop xix
	ld (xix), a
	inc 1, xix
	ld a, 0x20:opc
	ld (xix), a
	inc 1, xix
	ld a, 0x0:opc
	ld (xix), a
	inc 1, xix
	ld a, (0x34ed:16)
	ld (xix), a
	inc 1, xix
	ld a, (0x34ee:16)
	ld (xix), a
	inc 1, xix
	ld l, (0x34ef:16)
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, RhythmROM_PatternDisp_CheckCmd
	xor xwa, xwa
	ld	wa, (xix+hl)
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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF63652-0xF63663 (17 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=4 near RhythmROM_PatternDisp_CheckCmd+15
	.byte 0x07, 0x0c, 0x03, 0x0c, 0x03, 0x3d, 0x03, 0x3d, 0x03, 0x0c, 0x07, 0x0c
	.byte 0x07, 0x3d, 0x07, 0x3d, 0x07

RhythmROM_PatternDisp_Handle90:
	ld xiy, (0x3564:16)
	add xiy, xwa
	ld xix, (0x3560:16)
	add xix, 0x18
	ld a, 0x5:opc

RhythmROM_PatternDisp_Check91:
	ld bc, 7:i3
	ldir85
	inc 1, xix
	dec 1, a
	cp a, 0:i3
	jr nz, RhythmROM_PatternDisp_Check91
	ld xix, (0x3560:16)
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
	ld a, (0x34ed:16)
	ld (0x90ea:16), a
	ld a, (0x34ee:16)
	ld (0x90eb:16), a
	call Rhythm_DispatchNote_Finalize
	ld h, (0x90ef:16)
	ld l, (0x90ee:16)
	call AccVoice_DispatchEntry
	ld xiy, 0x34ab
	ld xix, (0x3560:16)
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
	add xix, (RHYTHM_ROM_BASE:16)
	add xix, xwa
	ret

RhythmROM_PatternDisp_Return:
	nop
	nop

RhythmROM_PatternDisp_ReadByte_Helper:
	ld xhl, (0x3564:16)
	add xhl, 0x118
	calr RhythmROM_CountEntries
	ld (0x35b3:16), e
	ld a, (0x34ef:16)
	cp a, 0:i3
	jr z, RhythmROM_InitPattern
	cp a, 1:i3
	jr z, RhythmROM_InitPattern
	cp a, 2:i3
	jr z, RhythmROM_InitPattern
	cp a, 3:i3
	jr z, RhythmROM_InitPattern
	jr RhythmROM_InitPattern_Join

RhythmROM_InitPattern:
	ld xhl, (0x3560:16)
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, AccFill_AdvanceAndCheck_Code
	ld	l, (xhl+wa)
	ld a, 0x7:opc
	cp l, (0x35b3:16)
	jr nz, RhythmVoice_WriteParam_Return
	or (0x35b0:16), 2
	ld a, 0x3:opc

RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

RhythmROM_InitPattern_Join:
	ld xhl, (0x3564:16)
	add xhl, 0x138
	cp a, 4:i3
	jr z, RhythmROM_ProcessPattern
	ld xhl, (0x3564:16)
	add xhl, 0x13c
	cp a, 6:i3
	jr z, RhythmROM_ProcessPattern
	ld xhl, (0x3564:16)
	add xhl, 0x538
	cp a, 5:i3
	jr z, RhythmROM_ProcessPattern
	ld xhl, (0x3564:16)
	add xhl, 0x53c
	cp a, 7:i3
	jr z, RhythmROM_ProcessPattern
	jr RhythmVoice_SetupChannels

RhythmROM_ProcessPattern:
	calr RhythmROM_CountEntries
	ld xhl, (0x3560:16)
	xor wa, wa
	ld a, (xhl + 12)
	ld xhl, AccFill_AdvanceAndCheck_Code
	ld	a, (xhl+wa)
	ex8 a, e
	xor w, w
	div wa, e
	dec 1, a
	cp w, 0:i3
	jr z, RhythmROM_NullRet
	ld a, 0x8:opc
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
	ld xhl, (0x3564:16)
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

RhythmVoice_WriteBuf_Clamp_Code:
	nop
	nop
	ld	c, 16:opc
	ld	a, (xiy)
	jr	nz, 3
	ld	(xiy), 32
	jr	nz, 3
	ld	(xiy), 32
	dec	1, bc
	inc	1, iy
	cp	bc, 0:i3
	jr	nz, -20
	ret
	nop
	nop

DrumKit_DataTable_Entry0:
	ld xix, (0x3564:16)
	ld xiy, (0x3564:16)
	cp (0x34ef:16), 0
	jr nz, DrumKit_DataTable_Entry1
	add xix, 0x0
	add xiy, 0x118

DrumKit_DataTable_Entry1:
	cp (0x34ef:16), 1
	jr nz, DrumKit_DataTable_Entry2
	add xix, 0xf
	add xiy, 0x118

DrumKit_DataTable_Entry2:
	cp (0x34ef:16), 2
	jr nz, DrumKit_DataTable_Entry3
	add xix, 0x400
	add xiy, 0x518

DrumKit_DataTable_Entry3:
	cp (0x34ef:16), 3
	jr nz, DrumKit_DataTable_Entry4
	add xix, 0x40f
	add xiy, 0x518

DrumKit_DataTable_Entry4:
	ld xhl, 0:i3
	bit 0, (0x35b1:16)
	jr nz, DrumKit_DataTable_Entry5
	ld xhl, 0x26

DrumKit_DataTable_Entry5:
	add xhl, xiy
	ld a, (xix + 0:8)
	calr ToneData_LookupEffectParam
	ld (0x358c:16), a
	ld (0x356a:16), hl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 40)
	calr ToneData_LookupEffectParam
	ld (0x358d:16), a
	ld (0x356c:16), hl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 80)
	calr ToneData_LookupEffectParam
	ld (0x358e:16), a
	ld (0x356e:16), hl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 120)
	calr ToneData_LookupEffectParam
	ld (0x358f:16), a
	ld (0x3570:16), hl
	ld xhl, 0xbe
	add xhl, xiy
	ld	a, (xix+160)
	calr ToneData_LookupEffectParam
	ld (0x3590:16), a
	ld (0x3572:16), hl
	ld xhl, 0:i3
	bit 0, (0x35b1:16)
	jr nz, DrumKit_DataTable_Entry6
	ld xhl, 0x26

DrumKit_DataTable_Entry6:
	add xhl, xiy
	ld a, (xix + 1)
	calr ToneData_LookupEffectParam
	ld (0x3591:16), a
	ld (0x3574:16), hl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 41)
	calr ToneData_LookupEffectParam
	ld (0x3592:16), a
	ld (0x3576:16), hl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 81)
	calr ToneData_LookupEffectParam
	ld (0x3593:16), a
	ld (0x3578:16), hl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 121)
	calr ToneData_LookupEffectParam
	ld (0x3594:16), a
	ld (0x357a:16), hl
	ld xhl, 0xbe
	add xhl, xiy
	ld	a, (xix+161)
	calr ToneData_LookupEffectParam
	ld (0x3595:16), a
	ld (0x357c:16), hl
	ld xhl, 0:i3
	bit 0, (0x35b1:16)
	jr nz, DrumKit_DataTable_Entry7
	ld xhl, 0x26

DrumKit_DataTable_Entry7:
	add xhl, xiy
	ld a, (xix + 2)
	calr ToneData_LookupEffectParam
	ld (0x35c0:16), a
	ld (0x35b6:16), hl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 42)
	calr ToneData_LookupEffectParam
	ld (0x35c1:16), a
	ld (0x35b8:16), hl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 82)
	calr ToneData_LookupEffectParam
	ld (0x35c2:16), a
	ld (0x35ba:16), hl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 122)
	calr ToneData_LookupEffectParam
	ld (0x35c3:16), a
	ld (0x35bc:16), hl
	ld xhl, 0xbe
	add xhl, xiy
	ld	a, (xix+162)
	calr ToneData_LookupEffectParam
	ld (0x35c4:16), a
	ld (0x35be:16), hl
	ld xhl, 0:i3
	bit 0, (0x35b1:16)
	jr nz, DrumKit_DataTable_Entry8
	ld xhl, 0x26

DrumKit_DataTable_Entry8:
	add xhl, xiy
	ld a, (xix + 3)
	calr ToneData_LookupEffectParam
	ld (0x35d0:16), a
	ld (0x35c6:16), hl
	ld xhl, 0x4c
	add xhl, xiy
	ld a, (xix + 43)
	calr ToneData_LookupEffectParam
	ld (0x35d1:16), a
	ld (0x35c8:16), hl
	ld xhl, 0x72
	add xhl, xiy
	ld a, (xix + 83)
	calr ToneData_LookupEffectParam
	ld (0x35d2:16), a
	ld (0x35ca:16), hl
	ld xhl, 0x98
	add xhl, xiy
	ld a, (xix + 123)
	calr ToneData_LookupEffectParam
	ld (0x35d3:16), a
	ld (0x35cc:16), hl
	ld xhl, 0xbe
	add xhl, xiy
	ld	a, (xix+163)
	calr ToneData_LookupEffectParam
	ld (0x35d4:16), a
	ld (0x35ce:16), hl
	ret

RhythmROM_LoadKit_InitLDA:
	nop
	nop

ToneData_LookupEffectParam:
	sla a, 1
	xor w, w
	ld	hl, (xhl+wa)
	push xix
	ld xix, (0x3564:16)
	add xix, 0x3d1
	ld a, (xix)
	pop xix
	ret

RhythmROM_LoadKit_Return:
	nop
	nop

AccPat_CalcAccentVelocity_Body_Helper:
	ld xix, (0x3564:16)
	add xix, 0x3d1
	ld a, (xix)
	ld (0x358c:16), a
	ld (0x358d:16), a
	ld (0x358e:16), a
	ld (0x358f:16), a
	ld (0x3590:16), a
	calr ToneData_LookupEffectParam_Helper
	ld xiy, (0x3564:16)
	xor xhl, xhl
	ld hl, (0x35b4:16)
	add xiy, xhl
	ld xhl, 0:i3
	bit 0, (0x35b1:16)
	jr nz, RhythmROM_LoadKit_CopyLoop
	ld xhl, 0x26

RhythmROM_LoadKit_CopyLoop:
	add xhl, xiy
	ld hl, (xhl)
	ld (0x356a:16), hl
	ld xhl, 0x4c
	add xhl, xiy
	ld hl, (xhl)
	ld (0x356c:16), hl
	ld xhl, 0x72
	add xhl, xiy
	ld hl, (xhl)
	ld (0x356e:16), hl
	ld xhl, 0x98
	add xhl, xiy
	ld hl, (xhl)
	ld (0x3570:16), hl
	ld xhl, 0xbe
	add xhl, xiy
	ld hl, (xhl)
	ld (0x3572:16), hl
	ret

RhythmROM_LoadKit_CopyReturn:
	nop
	nop

ToneData_LookupEffectParam_Helper:
	ld l, (0x34ef:16)
	and l, 0xf
	xor h, h
	sla hl, 1
	ld xix, ToneData_EffectParamWords
	ld	wa, (xix+hl)
	ld (0x35b4:16), wa
	ret

	nop
	nop
; ToneData_EffectParamWords -- 16 words: ToneData_LookupEffectParam_Helper stores entry [(0x34EF) & 15] to
;          (0x35B4).  Was named VoiceSlot_ResolveIndex and decoded as `.zero 8 / nop / nop / push xwa /
;          normal ...`; its reader used the positional alias VoiceSlot_ResolveIndex_0x2.
ToneData_EffectParamWords:
	.short	0, 0, 0, 0, 0x0138, 0x0538, 0x013c, 0x053c
	.short	0x0130, 0x0132, 0x0134, 0x0136, 0x0530, 0x0532, 0x0534, 0x0536
	ret
	nop
	nop

VoiceSlot_Resolve_Loop:
	ld w, (0x358c:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356a:16)
	ld de, (0x3598:16)
	bit 0, (0x35b1:16)
	jr nz, VoiceSlot_Resolve_CheckA
	bit 1, (0x35b1:16)
	jr nz, VoiceSlot_Resolve_CheckA
	jr VoiceSlot_Resolve_CheckB

VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	and (0x35b0:16), 251
	ld w, (0x358d:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356c:16)
	ld de, (0x359a:16)
	bit 2, (0x35b1:16)
	jr z, VoiceSlot_Resolve_CheckC
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreB

VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	and (0x35b0:16), 251
	ld w, (0x358e:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356e:16)
	ld de, (0x359c:16)
	bit 3, (0x35b1:16)
	jr z, VoiceSlot_Resolve_CheckD
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreC

VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	and (0x35b0:16), 251
	ld w, (0x358f:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3570:16)
	ld de, (0x359e:16)
	bit 4, (0x35b1:16)
	jr z, VoiceSlot_Resolve_CheckE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreD

VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	and (0x35b0:16), 251
	ld w, (0x3590:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3572:16)
	ld de, (0x35a0:16)
	bit 5, (0x35b1:16)
	jr z, VoiceSlot_Resolve_StoreE
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_Done

VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	and (0x35b0:16), 251
	ret

VoiceSlot_Resolve_StoreE_Code:
	nop
	nop
	ld	w, (0x358c:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x356a:16)
	ld	ix, (0x3580:16)
	ld	de, (0x3598:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3591:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3574:16)
	calr	RhythmBuf_LoadPattern
	and	(0x35b0:16), 251
	ld	w, (0x358d:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x356c:16)
	ld	ix, (0x3582:16)
	ld	de, (0x359a:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3592:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3576:16)
	calr	RhythmBuf_LoadPattern
	and	(0x35b0:16), 251
	ld	w, (0x358e:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x356e:16)
	ld	ix, (0x3584:16)
	ld	de, (0x359c:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3593:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3578:16)
	calr	RhythmBuf_LoadPattern
	and	(0x35b0:16), 251
	ld	w, (0x358f:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3570:16)
	ld	ix, (0x3586:16)
	ld	de, (0x359e:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3594:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x357a:16)
	calr	RhythmBuf_LoadPattern
	and	(0x35b0:16), 251
	ld	w, (0x3590:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3572:16)
	ld	ix, (0x3588:16)
	ld	de, (0x35a0:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3595:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x357c:16)
	calr	RhythmBuf_LoadPattern
	and	(0x35b0:16), 251
	ret
	nop
	nop

AccSection_ProcessEntry:
	ld w, (0x358c:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356a:16)
	ld de, (0x3598:16)
	bit 0, (0x35b1:16)
	jr nz, AccSection_Process_Loop
	bit 1, (0x35b1:16)
	jr nz, AccSection_Process_Loop
	jr AccSection_Process_Return

AccSection_Process_Loop:
	calr RhythmBuf_LoadPattern
	ld w, (0x3591:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3574:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35c0:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35b6:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35d0:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35c6:16)
	calr RhythmBuf_LoadPattern
	jr AccSection_ProcessEntry_Join

AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join:
	and (0x35b0:16), 251
	ld w, (0x358d:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356c:16)
	ld de, (0x359a:16)
	bit 2, (0x35b1:16)
	jr z, AccSection_Process2_Return
	calr RhythmBuf_LoadPattern
	ld w, (0x3592:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3576:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35c1:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35b8:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35d1:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35c8:16)
	calr RhythmBuf_LoadPattern
	jr AccSection_ProcessEntry_Join2

AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join2:
	and (0x35b0:16), 251
	ld w, (0x358e:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x356e:16)
	ld de, (0x359c:16)
	bit 3, (0x35b1:16)
	jr z, AccSection_Process3_Return
	calr RhythmBuf_LoadPattern
	ld w, (0x3593:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3578:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35c2:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35ba:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35d2:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35ca:16)
	calr RhythmBuf_LoadPattern
	jr AccSection_ProcessEntry_Join3

AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join3:
	and (0x35b0:16), 251
	ld w, (0x358f:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3570:16)
	ld de, (0x359e:16)
	bit 4, (0x35b1:16)
	jr z, AccSection_Process4_Return
	calr RhythmBuf_LoadPattern
	ld w, (0x3594:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x357a:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35c3:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35bc:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35d3:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35cc:16)
	calr RhythmBuf_LoadPattern
	jr AccSection_ProcessEntry_Join4

AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join4:
	and (0x35b0:16), 251
	ld w, (0x3590:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x3572:16)
	ld de, (0x35a0:16)
	bit 5, (0x35b1:16)
	jr z, AccSection_Process5_Return
	calr RhythmBuf_LoadPattern
	ld w, (0x3595:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x357c:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35c4:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35be:16)
	calr RhythmBuf_LoadPattern
	ld w, (0x35d4:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x35ce:16)
	calr RhythmBuf_LoadPattern
	jr AccSection_ProcessEntry_Join5

AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join5:
	and (0x35b0:16), 251
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
	bit 0, (0x35b0:16)
	jr z, AccFill_CheckPattern
	jp AccFill_AdvCheck_Done

AccFill_CheckPattern:
	add iy, 0x6
	and xiy, 0xffff
	add xiy, xix
	bit 2, (0x35b0:16)
	jr z, AccFill_ProcessEntry
	jr AccFill_ProcessDone

AccFill_ProcessEntry:
	or (0x35b0:16), 4
	ld (0x3596:16), de
	ld xiz, 6:i3

AccFill_ProcessDone:
	ld a, (xiy)
	ld hl, (0x3596:16)
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a

AccFill_ProcessDone_Join:
	cp a, 0x83
	jr z, AccFill_AdvCheck_Return
	inc 1, xiy
	inc 1, xiz
	cp xiz, 0xfe
	jr ule, AccFill_AdvanceAndCheck
	calr AccFill_ProcessDone_Helper
	bit 0, (0x35b0:16)
	jr nz, AccFill_AdvCheck_Return
	push xiy
	ld hl, (0x3596:16)
	calr AccPat_IndexToAddress
	ld xiy, 3:i3
	add xiy, xhl
	ld (xiy), de
	ld hl, de
	calr AccPat_IndexToAddress
	ld xiy, 1:i3
	add xiy, xhl
	ld wa, (0x3596:16)
	ld (xiy), wa
	ld (0x3596:16), de
	ormi8 (xhl), 0x80
	decw 1, (0x34d4:16)
	ld xiz, 6:i3
	pop xiy

AccFill_AdvanceAndCheck:
	ld a, (xiy)
	ld hl, de
	calr AccPat_IndexToAddress
	add xhl, xiz
	ld (xhl), a
	jr AccFill_ProcessDone_Join

AccFill_AdvCheck_Return:
	ldw wa, 0xffff
	ld hl, de
	calr AccPat_IndexToAddress
	ld xiy, 3:i3

AccFill_AdvCheck_Done:
	ret

AccFill_AdvanceAndCheck_Pad:
	nop
	nop
AccFill_AdvanceAndCheck_Code:
	push	sr
	.byte 0x04, 0x06
	ld	(1:8), 2:io
	pop	sr
	max
	halt
	ei	7
	ld	(1:8), 2:io
	pop	sr
	max
	halt
	ei	7
	.byte 0x08

RhythmBuf_FillEmptyPattern:
	ld xiy, (0x3560:16)
	ld l, (xiy + 12)
	xor h, h
	ld xix, AccFill_AdvanceAndCheck_Code
	ld	w, (xix+hl)
	ld a, (xiy + 13)
	and a, 0x7
	inc 1, a
	mul wa, w
	push xwa
	ld hl, de
	calr AccPat_IndexToAddress
	pop xwa
	add xhl, 0x6
	ld e, a
	ld a, 0x81:opc

StyleConvert_ReloadParams:
	ld (xhl), a
	inc 1, xhl
	dec 1, e
	cp e, 0:i3
	jr nz, StyleConvert_ReloadParams
	ld (xhl), 0x83
	ret

StyleConvert_Reload_Loop:
	nop
	nop
	cp	(0x34ef:16), 16
	jr	ule, RhythmBuf_FillEmptyPattern_Return
	ld	a, 123:opc
	cp	(0x34ed:16), 132
	jr	c, RhythmBuf_FillEmptyPattern_Skip
	add	a, 6
	cp	(0x34ed:16), 136
	jr	c, RhythmBuf_FillEmptyPattern_Skip
	add	a, 6
RhythmBuf_FillEmptyPattern_Skip:
	add	a, (0x34ef:16)
	ld	(0x34ed:16), a
RhythmBuf_FillEmptyPattern_Return:
	ret
	nop
	nop

AccPat_CalcAccentVelocity:
	cp (0x34ef:16), 19
	jr ule, StyleConvert_Reload_Return
	ld a, 0x78:opc
	cp (0x34ed:16), 132
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6
	cp (0x34ed:16), 136
	jr c, StyleConvert_Reload_CheckEnd
	add a, 0x6

StyleConvert_Reload_CheckEnd:
	add a, (0x34ef:16)
	ld (0x34ed:16), a
	jr StyleConvert_Reload_Done

StyleConvert_Reload_Return:
	cp (0x34ef:16), 16
	jr c, StyleConvert_Reload_Done
	ld a, 0x70:opc
	cp (0x34ed:16), 132
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4
	cp (0x34ed:16), 136
	jr c, StyleConvert_Reload_Fallback
	add a, 0x4

StyleConvert_Reload_Fallback:
	add a, (0x34ef:16)
	ld (0x34ed:16), a

StyleConvert_Reload_Done:
	ret

StyleConvert_Reload_Fallback_Code2:
	ld	l, (0x34ed:16)
	ld	h, (0x34ee:16)
	call	VoiceParam_ClampAndValidate_Tramp
	ld	de, hl
	ld	xiy, StyleConvert_Reload_Fallback_Code
	xor	hl, hl
AccPat_CalcAccentVelocity_Join2:
	ld	wa, (xiy+hl)
	cp wa, 65535
	jr	z, AccPat_CalcAccentVelocity_Skip9
	cp	wa, de
	jr	z, AccPat_CalcAccentVelocity_Skip8
	add	hl, 2
	jr	AccPat_CalcAccentVelocity_Join2
AccPat_CalcAccentVelocity_Skip8:
	ld	a, 1:opc
	jr	AccPat_CalcAccentVelocity_Return
AccPat_CalcAccentVelocity_Skip9:
	ld	a, 0:opc
AccPat_CalcAccentVelocity_Return:
	ret
	nop
	nop
StyleConvert_Reload_Fallback_Code:
	ei	0
	ei	1
	ei	2
	ei	3
	reti
	nop
	reti
	normal
	reti
	push	sr
	swi	7
	swi	7
	swi	7
	swi	7
	ld	l, (0x34ed:16)
	ld	h, (0x34d6:16)
	cp	l, 128
	jr	nc, AccPat_CalcAccentVelocity_Skip12
	cp	h, 12
	jr	nc, AccPat_CalcAccentVelocity_Skip11
	ld	a, 0:opc
	ld	w, (0xfc61:16)
	jr	z, AccPat_CalcAccentVelocity_Skip10
	ld	a, 1:opc
AccPat_CalcAccentVelocity_Skip10:
	jr	AccPat_CalcAccentVelocity_Join
AccPat_CalcAccentVelocity_Skip11:
	ld	a, (0x34d6:16)
	sub	a, 12
	and	a, 3
	ld	w, (0xfc61:16)
	jr	z, AccPat_CalcAccentVelocity_Skip
	or	a, 4
AccPat_CalcAccentVelocity_Skip:
	xor	hl, hl
	ld	l, a
	jr	AccPat_CalcAccentVelocity_Join
AccPat_CalcAccentVelocity_Skip12:
	cp	h, 12
	jr	nc, AccPat_CalcAccentVelocity_Skip13
	ld	a, 0:opc
	jr	AccPat_CalcAccentVelocity_Join
AccPat_CalcAccentVelocity_Skip13:
	ld	a, (0x34d6:16)
	sub	a, 12
	and	a, 3
	xor	hl, hl
	ld	l, a
AccPat_CalcAccentVelocity_Join:
	ld	(0x34ef:16), a
	ret
	nop
	nop
	max
	ld	(9:8), 6:io
	max
	ld	(9:8), 6:io
	ret
	.byte 0xf1
	decw	6, (0xc834:16)
	max
	jp	StyleConvert_Reload_Fallback_Return
	ld	l, (0x34d6:16)
	ld	a, (0x34ed:16)
	ld	w, (0x34ee:16)
	pushw	hl
	pushw	wa
	cp	(0x34ed:16), 128
	jr	c, AccPat_CalcAccentVelocity_Skip14
	jp	StyleConvert_Reload_Fallback_Join
AccPat_CalcAccentVelocity_Skip14:
	cp	(0x34d6:16), 0
	jr	z, AccPat_CalcAccentVelocity_Skip15
	jp	StyleConvert_Reload_Fallback_Join
AccPat_CalcAccentVelocity_Skip15:
	ld	(0x34d6:16), 0
	ld	(0x34d6:16), 6
	ld	(0x34d6:16), 7
	ld	(0x34d6:16), 8
	ld	(0x34d6:16), 9
	and	(0x35b0:16), 247
	ld	(0x34ef:16), 0
	ld	(0x34d6:16), 0
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
	bit	0, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip2
	or	(0x35b0:16), 8
AccPat_CalcAccentVelocity_Skip2:
	ld	(0x34ef:16), 4
	ld	(0x34d6:16), 6
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
	bit	0, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip3
	or	(0x35b0:16), 8
AccPat_CalcAccentVelocity_Skip3:
	ld	(0x34ef:16), 8
	ld	(0x34d6:16), 7
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
	bit	0, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip4
	or	(0x35b0:16), 8
AccPat_CalcAccentVelocity_Skip4:
	ld	(0x34ef:16), 9
	ld	(0x34d6:16), 8
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
	bit	0, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip5
	or	(0x35b0:16), 8
AccPat_CalcAccentVelocity_Skip5:
	ld	(0x34ef:16), 6
	ld	(0x34d6:16), 9
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
	bit	0, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip6
	or	(0x35b0:16), 8
AccPat_CalcAccentVelocity_Skip6:
	bit	3, (0x35b0:16)
	jr	z, AccPat_CalcAccentVelocity_Skip7
	or	(0x35b0:16), 1
AccPat_CalcAccentVelocity_Skip7:
	jr	AccPat_CalcAccentVelocity_Join3
StyleConvert_Reload_Fallback_Join:
	ld	(0x34ef:16), 0
	or	(0x34d1:16), 1
	calr	AccPat_DispatchNoteChange
AccPat_CalcAccentVelocity_Join3:
	popw	wa
	popw	hl
	ld	(0x34ee:16), w
	ld	(0x34ed:16), a
	ld	(0x34d6:16), l
StyleConvert_Reload_Fallback_Return:
	ret
	nop
	nop

AccWidget_DispatchTable:
	ld xiy, 0x9b4000
	ld xix, RHYTHM_PATTERN_BUF_A
	ldw bc, 0x8000
	ldirw
	jp AccWidget_Dispatch_Return

AccWidget_Dispatch_Return:
	ret

AccWidget_DispatchTable_Pad:
	nop
	nop

AccWidget_ProcessSpecialCmd:
	cp (0x34ee:16), 0
	jr nz, AccWidget_ProcessSpecialCmd_Join
	ld a, (0x34ed:16)
	and a, 0x7f
	ld xix, DrumKit_GroupAssignTable
	ld	a, (xix+a)
	ld w, (0x34d6:16)
	sub w, 0x1e
	cp a, w
	jrl z, DrumKit_Return

AccWidget_ProcessSpecialCmd_Join:
	ld a, (0x34ed:16)
	ld w, (0x34ee:16)
	ld l, (0x34ef:16)
	ld h, (0x34d6:16)
	pushw wa
	pushw hl
	or (0x34cd:16), 128
	ld (0x34ef:16), 16
	ld l, (0x34d6:16)
	sub l, 0x1e
	ld (0x39a5:16), l
	ld xix, AccWidget_ProcessSpecialCmd_Data
	ld	l, (xix+l)
	ld (0x34d6:16), l
	ld (0x39a6:16), l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 17
	ld l, (0x39a6:16)
	inc 1, l
	ld (0x34d6:16), l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 18
	ld l, (0x39a6:16)
	add l, 0x2
	ld (0x34d6:16), l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 19
	ld l, (0x39a6:16)
	add l, 0x3
	ld (0x34d6:16), l
	calr AccPat_CalcAccentVelocity
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 20
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_2
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 21
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_3
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 22
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_4
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 23
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_5
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 24
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_6
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_ErrorFallbackLoop
	ld (0x34ef:16), 25
	ld a, (0x34ed:16)
	pushw wa
	calr AccPat_CalcAccentVelocity
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_7
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	ld a, (0x34ed:16)
	and a, 0x7f
	ld (0x39ac:16), a
	ld a, (0x34d6:16)
	ld (0x39ad:16), a
	push xix
	ld xix, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xix
	ld (0x39b2:16), xix
	pop xix
	calr AccPatch_LoadDualVoiceParams
	popw wa
	ld (0x34ed:16), a
	bit 0, (0x35b0:16)
	jr z, DrumKit_SetErrorCode20

DrumKit_ErrorFallbackLoop:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_ErrorFallbackSlotIter:
	ld a, (0x39a5:16)
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ld	a, (xwa+c)
	ld (0x34d6:16), a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xa
	jr c, DrumKit_ErrorFallbackSlotIter
	ld (GLOBAL_ERROR_CODE:16), 23
	call DrumVoice_NotifyEE
	ld a, 0x8:opc
	call MIDI_SendSysExCmd
	jr DrumKit_RestoreRegisters

DrumKit_SetErrorCode20:
	ld (GLOBAL_ERROR_CODE:16), 20
	call DrumVoice_NotifyEE

DrumKit_RestoreRegisters:
	popw hl
	popw wa
	ld (0x34ef:16), l
	ld (0x34d6:16), h
	ld (0x34ee:16), w
	ld (0x34ed:16), a

DrumKit_Return:
	ret

DrumKit_GroupAssignTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01
	.byte 0x02, 0x02, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.byte	0x02, 0x02, 0x02, 0x02, 0x02, 0x02
RhythmROM_LoadDrumKit_Data:	.byte	0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte	0x08, 0x08, 0x08, 0x08
AccWidget_ProcessSpecialCmd_Data:	.byte	0x00, 0x04, 0x08
AccWidget_ProcessSpecialCmd_Data_2:	.byte	0x0c
	.byte	0x12, 0x18
AccWidget_ProcessSpecialCmd_Data_3:	.byte	0x0d, 0x13, 0x19
AccWidget_ProcessSpecialCmd_Data_4:	.byte	0x0e, 0x14, 0x1a
AccWidget_ProcessSpecialCmd_Data_5:
	.byte	0x0f, 0x15, 0x1b
AccWidget_ProcessSpecialCmd_Data_6:	.byte	0x10, 0x16, 0x1c
AccWidget_ProcessSpecialCmd_Data_7:	.byte	0x11, 0x17
	.byte 0x1d

RhythmROM_LoadDrumKit:
	ld a, (0x34ed:16)
	ld w, (0x34ee:16)
	ld l, (0x34ef:16)
	ld h, (0x34d6:16)
	pushw wa
	pushw hl
	ld (0x34ef:16), 0
	ld l, (0x34d6:16)
	sub l, 0x1e
	ld (0x39a5:16), l
	sll l, 2
	ld xix, RhythmROM_LoadDrumKit_Data
	ld	l, (xix+l)
	ld (0x34d6:16), l
	ld (0x39a6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 1
	ld l, (0x39a6:16)
	inc 1, l
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 2
	ld l, (0x39a6:16)
	add l, 0x2
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 3
	ld l, (0x39a6:16)
	add l, 0x3
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 4
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_2
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 5
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_3
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 10
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_4
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 11
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_5
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jrl nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 6
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_6
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jr nz, DrumKit_PatternLoadFailed
	ld (0x34ef:16), 7
	ld l, (0x39a5:16)
	ld xix, AccWidget_ProcessSpecialCmd_Data_7
	ld	l, (xix+l)
	ld (0x34d6:16), l
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher
	bit 0, (0x35b0:16)
	jr z, DrumKit_AllPatternsOK

DrumKit_PatternLoadFailed:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_FallbackSlotLoop:
	ld a, (0x39a5:16)
	ld w, a
	sll a, 3
	sll w, 1
	add a, w
	extz wa
	extz xwa
	add xwa, xix
	ld	a, (xwa+c)
	ld (0x34d6:16), a
	push xbc
	push xix
	call AccPat_InitWorkAreaFromSlot
	pop xix
	pop xbc
	inc 1, c
	cp c, 0xa
	jr c, DrumKit_FallbackSlotLoop
	ld (GLOBAL_ERROR_CODE:16), 23
	call DrumVoice_NotifyEE
	ld a, 0x8:opc
	call MIDI_SendSysExCmd
	jr DrumKit_Epilogue

DrumKit_AllPatternsOK:
	ld (GLOBAL_ERROR_CODE:16), 20
	call DrumVoice_NotifyEE

DrumKit_Epilogue:
	popw hl
	popw wa
	ld (0x34d6:16), h
	ld (0x34ef:16), l
	ld (0x34ee:16), w
	ld (0x34ed:16), a
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
	ld xhl, 0:i3
	and w, 0x7
	sll w, 2
	ld l, w
	add xhl, DrumParam_Lookup_Data
	ld xhl, (xhl)
	push_a
	ld xwa, 0:i3
	pop_a
	add xhl, xwa
	ld a, (xhl)
	pop xhl
	ret

DrumParam_PointerTableAndData:
; DrumParam_PointerTableAndData -- eight per-parameter byte arrays and the
; table of their addresses.  ** RE-TYPED 2026-09-25 (lane accomp): was
; `ld xsp, 0x49db00f6` / `jrl nc, 32639` / swi ... (data-as-code) plus .fill
; runs.  Read by DrumParam_Lookup:
;     and w,7 / sll w,2 / ld l,w / add xhl, DrumParam_Lookup_Data /
;     ld xhl,(xhl) / ... / add xhl,xwa (xwa = A zero-extended) / ld a,(xhl)
; i.e. array W&7, element A.  Every pointer lands inside this block, so the
; eight addresses below are written relative to the label and the arrays are
; emitted at the offsets they point to.  Array lengths are the distances
; between consecutive targets (the last runs to the block's end); the
; element meaning per array is not established here.
; readers in v9/v10 (address from the linked ELF): DrumParam_Lookup 0xF6474C
; -- comments that sat inside this range before the re-type, in order:
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF64859-0xF64869 (16 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=71% dist=3 near DrumParam_Lookup_Data+238
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF64979-0xF64989 (16 B), unreached CODE-territory, was disassembled as 14 plausible-but-dead instruction lines; per=71% dist=3 near DrumParam_Lookup_Data+526
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF649D3-0xF649F9 (38 B), unreached CODE-territory, was disassembled as 25 plausible-but-dead instruction lines; per=72% dist=6 near DrumParam_Lookup_Data+616
; +0x00  2 B, not addressed by the reader
	.byte 0x00, 0x00
; +0x02  8 x LE32 -- the address of array k, k = W & 7
DrumParam_Lookup_Data:
	.long DrumParam_PointerTableAndData + 0x32	; array 0
	.long DrumParam_PointerTableAndData + 0x272	; array 1
	.long DrumParam_PointerTableAndData + 0x152	; array 2
	.long DrumParam_PointerTableAndData + 0x212	; array 3
	.long DrumParam_PointerTableAndData + 0xf2	; array 4
	.long DrumParam_PointerTableAndData + 0x1b2	; array 5
	.long DrumParam_PointerTableAndData + 0x92	; array 6
	.long DrumParam_PointerTableAndData + 0x32	; array 7
; +0x022  16 B -- not pointed at by the table
	.fill 16, 1, 0xf4
; +0x032  96 B -- array 0, 7
	.zero 48
	.fill 48, 1, 0x7f
; +0x092  96 B -- array 6
	.zero 24
	.fill 48, 1, 0x30
	.fill 24, 1, 0x7f
; +0x0f2  96 B -- array 4
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.fill 24, 1, 0x18
	.fill 24, 1, 0x30
	.fill 24, 1, 0x48
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
; +0x152  96 B -- array 2
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c
	.byte 0x0c, 0x0c, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x24, 0x24
	.byte 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c
	.byte 0x3c, 0x3c, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x54, 0x54
	.byte 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
; +0x1b2  96 B -- array 5
	.zero 16
	.fill 32, 1, 0x20
	.fill 32, 1, 0x40
	.fill 16, 1, 0x7f
; +0x212  96 B -- array 3
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.fill 16, 1, 0x10
	.fill 16, 1, 0x20
	.fill 16, 1, 0x30
	.fill 16, 1, 0x40
	.fill 16, 1, 0x50
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
; +0x272  96 B -- array 1
	.byte 0x00, 0x00, 0x00, 0x00, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x10, 0x10, 0x10, 0x10
	.byte 0x10, 0x10, 0x10, 0x10, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x50, 0x50, 0x50, 0x50
	.byte 0x50, 0x50, 0x50, 0x50, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x7f, 0x7f, 0x7f, 0x7f

DrumKitInit_Wrapper:
	push xiz
	call DrumKitInit_Entry
	pop xiz
	ret

DrumKitInit_Entry:
	ld a, 0x48:opc
	call CtrlPanel_SetIndicatorBit
	cp (PREVIOUS_MODE:16), 14
	jr nz, DrumKitInit_Setup
	jrl DrumKitInit_Return

DrumKitInit_Setup:
	ld (0x34f1:16), 0
	ld (0x34db:16), 0
	ld (0x3714:16), 4
	ld (0x3715:16), 0
	ld (0x3716:16), 1
	call AccWrap_PlayModeDispatch
	or (0x28a7:16), 4
	ld (0x379b:16), 64
	ld a, (0xfc5a:16)
	ld (0x34ed:16), a
	ld a, (0xfc5b:16)
	ld (0x34ee:16), a
	ld a, (0xfc5a:16)
	ld (0x352b:16), a
	ld a, (0xfc5b:16)
	ld (0x352c:16), a
	calr DrumKit_SendProgramChange
	bit 2, (0xfc5f:16)
	jr nz, DrumKitInit_ClearAssignFlags
	bit 3, (0xfc5f:16)
	jr z, DrumKitInit_CheckExtAssign

DrumKitInit_ClearAssignFlags:
	and (0xfc5f:16), 243
	ld d, 0x5:opc
	ld e, 0x48:opc
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_CheckExtAssign:
	bit 2, (0xfc60:16)
	jr z, DrumKitInit_FinalSetup
	and (0xfc60:16), 251
	ld d, 0x6:opc
	ld e, 0x48:opc
	xor wa, wa
	call SwbtWr_QueuePostEvent

DrumKitInit_FinalSetup:
	call AccPatch_CountSlots_Wrapper
	ld (0x350c:16), 0
	call SeqAcc_SetIndicator_PB
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	and (0xe3e2:16), 158
	or (0x34cd:16), 64

DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	ld xhl, 0:i3
	ld l, (0x34d6:16)
	cp l, 0x1e
	jr c, DrumKit_SendPC_MaskAndSend
	sub l, 0x1e
	sll l, 2

DrumKit_SendPC_MaskAndSend:
	and l, 0x1f
	add l, 0x80
	ld xbc, 0xfc5a
	ld a, 0x0:opc
	ld	(xbc+a), l
	ld a, 0x1:opc
	ld	h, (xbc+a)
	and h, 0x80
	ld	(xbc+a), h
	calr DrumKit_PostMidiEvents
	ret

DrumKitExit_Wrapper:
	push xiz
	call DrumKitExit_Entry
	pop xiz
	ret

DrumKitExit_Entry:
	ld a, 0x48:opc
	call CtrlPanel_SetIndicatorBit
	cp (CURRENT_MODE:16), 14
	jr nz, DrumKitExit_CheckState1
	jrl DrumKitExit_Return

DrumKitExit_CheckState1:
	cp (CURRENT_MODE:16), 1
	jr z, DrumKitExit_ClearFlags
	and (0x8d88:16), 254

DrumKitExit_ClearFlags:
	and (0x28a7:16), 251
	and (0xe3e2:16), 254
	and (0xe3e2:16), 247
	and (0xe3e2:16), 223
	ld (0x34f1:16), 0
	ld (0x379b:16), 0
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
	bit 6, (0x34cd:16)
	jr z, DrumKitExit_PostRestore
	and (0x34cd:16), 191
	ld a, (0x352b:16)
	ld (0xfc5a:16), a
	ld a, (0x352c:16)
	and a, 0x7f
	and (0xfc5b:16), 128
	or (0xfc5b:16), a
	calr DrumKit_PostMidiEvents

DrumKitExit_PostRestore:
	call AccWrap_PlayModeDispatch
	calr DrumKit_ValidateBank
	call SeqAcc_RestorePlaybackState
	cpw (0x28a8:16), 0
	jr nz, DrumKitExit_ExtraInit
	cpw (0xf19e:16), 0
	jr nz, DrumKitExit_ExtraInit
	jr DrumKitExit_CheckAutoPlay

DrumKitExit_ExtraInit:
	call AccWrap_PlayModeDispatch

DrumKitExit_CheckAutoPlay:
	bit 0, (0x3283:16)
	jr nz, DrumKitExit_Return
	or (0x34cd:16), 128

DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
CmEsyTtl_Dispatch_Helper:
	push	xiz
	call	DrumKit_ValidateBank
	pop	xiz
	ret

DrumKit_ValidateBank:
	ld a, (0xfc5a:16)
	cp a, 0x80
	jr c, DrumKit_ValidateBank_Return
	cp a, 0x8b
	jr ule, DrumKit_ValidateBank_Return
	cp a, 0x91
	jr ugt, DrumKit_ValidateBank_Mid
	ld l, 0x80:opc
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_Mid:
	cp a, 0x97
	jr ugt, DrumKit_ValidateBank_High
	ld l, 0x84:opc
	jr DrumKit_ValidateBank_Apply

DrumKit_ValidateBank_High:
	ld l, 0x88:opc

DrumKit_ValidateBank_Apply:
	push l
	calr DrumKit_StoreAndSendBank
	pop l
	and l, 0x1f
	ld (0x34d6:16), l
	calr DrumKit_SendProgramChange

DrumKit_ValidateBank_Return:
	ret

DrumKit_StoreAndSendBank:
	ld (0xfc5a:16), l
	and (0xfc5b:16), 128
	ld h, 0x0:opc
	call PartCtrl_WriteProgramChange
	ld xix, 0xff92
	ld	(xix+l), h
	call DrumKit_PostMidiEvents
	ret

DrumKit_PostMidiEvents:
	ld e, 0x48:opc
	ld a, (0xfc5b:16)
	and a, 0x7f
	ld d, 0x1:opc
	ld w, 0x0:opc
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	ld h, a
	ld e, 0x48:opc
	ld a, (0xfc5a:16)
	and a, 0xff
	ld d, 0x0:opc
	ld w, 0x0:opc
	push h
	push_a
	call SwbtWr_QueuePostEvent
	pop_a
	pop h
	ld l, a
	ld (0x90f7:16), 72
	call PartCtrl_WriteProgramChange
	ld c, 0x48:opc
	call MIDI_SetupChannelParams
	ret

DrumKit_UpdateStatusFlags:
	ld w, (0x34f1:16)
	and w, 0xc2
	bit 7, w
	jr z, DrumKit_StoreStatus
	ld a, (0x379b:16)
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
	ld (0x34f1:16), w
	ret

DrumKit_InlineCode1:
	push	xiz
	call	DrumKit_InlineCode1_Helper
	pop	xiz
	ret
DrumKit_InlineCode1_Helper:
	ret
CmpBkslTtl_Dispatch_Helper:
	push	xiz
	call	DrumKit_InlineCode1_Data
	pop	xiz
	ret
DrumKit_InlineCode1_Data:
	cp	(PREVIOUS_TITLE:16), 177
	jr	z, DrumKit_InlineCode1_Data_Skip
	calr	DrumKit_UpdateStatusFlags_Helper2
	ld	(0x379b:16), 64
	and	(0x34cd:16), 191
	calr	DrumKit_UpdateStatusFlags_Helper
DrumKit_InlineCode1_Data_Skip:
	and	(0xe3e2:16), 158
	ret
DrumKit_UpdateStatusFlags_Helper:
	ld	e, (0x34cd:16)
	and	e, 48
	ld	xhl, 0:i3
	ld	l, (0x34d6:16)
	ld	xwa, DrumKit_InlineCode1_Code
	add	xwa, xhl
	ld	a, (xwa)
	cp	a, e
	jr	z, DrumKit_UpdateStatusFlags_Return
	cp	e, 0:i3
	jr	nz, DrumKit_UpdateStatusFlags_Helper_Skip
	ld	l, 0:opc
	jr	DrumKit_UpdateStatusFlags_Helper_Join
DrumKit_UpdateStatusFlags_Helper_Skip:
	cp	e, 32
	jr	nz, DrumKit_UpdateStatusFlags_Helper_Skip2
	ld	l, 4:opc
	jr	DrumKit_UpdateStatusFlags_Helper_Join
DrumKit_UpdateStatusFlags_Helper_Skip2:
	ld	l, 8:opc
DrumKit_UpdateStatusFlags_Helper_Join:
	ld	(0x34d6:16), l
	calr	DrumKit_SendProgramChange
DrumKit_UpdateStatusFlags_Return:
	ret
DrumKit_InlineCode1_Code:
	nop
	nop
	nop
	nop
	ld	w, 32:opc
	ld	w, 32:opc
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
DrumKit_InlineCode1_Sub:
	push	xiz
	call	DrumKit_UpdateStatusFlags_Helper2
	pop	xiz
	ret
DrumKit_UpdateStatusFlags_Helper2:
	xor	xwa, xwa
	xor	xde, xde
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 0:i3
	jr	nz, DrumKit_UpdateStatusFlags_Return2
	ld	a, 2:opc
	ld	w, 7:opc
	ld	e, 72:opc
	ld	d, 3:opc
	call	SwbtWr_TrailingBytecode
	ld	a, 8:opc
	or	(0xfc5d:16), a
	ld	w, 8:opc
	ld	e, 72:opc
	ld	d, 3:opc
	call	SwbtWr_QueuePostEvent
DrumKit_UpdateStatusFlags_Return2:
	ret

DrumSlot_DispatchWrapper:
	push xiz
	call DrumSlot_Dispatch
	pop xiz
	ret

DrumSlot_Dispatch:
	cp hl, 0xa
	jr c, DrumSlot_ClampAndLookup
	ld hl, 0:i3

DrumSlot_ClampAndLookup:
	ld xiy, DrumSlot_HandlerTable
	pushw hl
	sll hl, 2
	ld	xwa, (xiy+hl)
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
	ld	e, (0x34cd:16)
	and e, 0x30
	cp	e, 0:i3
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
	ld	(0x34d6:16), l
	ret
DrumSlot_OffsetCalc_Extended:
	; --- Offset calc 2: add 8/0x0e/0x14 to L based on (0x34cd) bits 5:4 (33 bytes) ---
	ld	e, (0x34cd:16)
	and e, 0x30
	cp	e, 0:i3
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
	ld	(0x34d6:16), l
	ret
RhythmPatInit_Wrapper:
	; --- Push XIZ wrapper for inner routine (7 bytes) ---
	push xiz
	call RhythmPatInit_Entry
	pop xiz
	ret
RhythmPatInit_Entry:
	; --- Conditional init: check (0x8d37), calr, store, optional call (39 bytes) ---
	cp	(PREVIOUS_TITLE:16), 178
	jr z, RhythmPatInit_Cleanup
	calr RhythmPatInit_LoadParams
	ld	(0x379b:16), 32
	cp	(PREVIOUS_TITLE:16), 181
	jr nz, RhythmPatInit_Cleanup
	call AccWrap_PlayModeDispatch
	or	(0x28a7:16), 4
	jr t, RhythmPatInit_Cleanup
RhythmPatInit_Cleanup:
	and	(0xe3e2:16), 158
	ret


RhythmPatInit_LoadParams:
	call AccPatch_GetCurrentSlotAddr
	ld a, (xiy + 12)
	ld (0x34d8:16), a
	ld l, a
	ld xwa, RhythmPatInit_KitIndexTable
	ld	a, (xwa+l)
	ld (0x34d9:16), a
	ld a, (xiy + 13)
	ld (0x34d7:16), a
	and (0x34ce:16), 127
	ld a, (xiy + 15)
	bit 7, a
	jr z, RhythmPatInit_FlagBit7
	or (0x34ce:16), 128

RhythmPatInit_FlagBit7:
	ld a, (xiy + 14)
	ld w, a
	and a, 0xf
	ld (0x34e9:16), a
	and (0x34ea:16), 143
	bit 4, w
	jr z, RhythmPatInit_Tempo4
	or (0x34ea:16), 16

RhythmPatInit_Tempo4:
	bit 5, w
	jr z, RhythmPatInit_Tempo5
	or (0x34ea:16), 32

RhythmPatInit_Tempo5:
	bit 6, w
	jr z, RhythmPatInit_CopyChannels
	or (0x34ea:16), 64

RhythmPatInit_CopyChannels:
	add xiy, 0x40
	ld xix, 0x34bc
	ld xbc, 0xd
	ldir85
	ld (xix+), 0x00
	ld (xix+), 0x00
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
	and (0xe3e2:16), 247
	ld xwa, RhythmFillIn_PatternTable
	cp hl, 4:i3
	jr c, RhythmFillIn_LookupAndApply
	sub hl, 0x4

RhythmFillIn_LookupAndApply:
	ld	a, (xwa+hl)
	ld (0x379b:16), a
	calr DrumKit_UpdateStatusFlags
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState
	ret

RhythmFillIn_PatternTable:
	rcf
	max
	push	sr
	normal
	ld	(P4:8), 16:io
	rcf
RhythmFillIn_PatternTable_Sub:
	push	xiz
	call	RhythmFillIn_PatternTable_Sub_Helper
	pop	xiz
	ret
RhythmFillIn_PatternTable_Sub_Helper:
	and	(0x28a7:16), 251
	and	(0xe3e2:16), 254
	cp	(PREVIOUS_TITLE:16), 181
	jr	z, RhythmFillIn_Select_Return
	or	(0x8d88:16), 1
	bit	0, (0x3283:16)
	jr	nz, RhythmFillIn_Select_Return
	or	(0x34cd:16), 128
	call	Seq_DispatcherEntry
	cp	(PREVIOUS_TITLE:16), 178
	jr	nz, RhythmFillIn_Select_Return
	call	AccWrap_PlayModeStartAccPlay
RhythmFillIn_Select_Return:
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
	or (0xe3e2:16), 8
	inc 1, (0x34db:16)
	cp (0x34db:16), 4
	jr nz, RhythmMute_State1
	ld (0x34db:16), 0
	jr RhythmMute_StateDone

RhythmMute_State1:
	cp (0x34db:16), 1
	jr nz, RhythmMute_State8
	ld (0x34db:16), 4
	jr RhythmMute_StateDone

RhythmMute_State8:
	cp (0x34db:16), 8
	jr nz, RhythmMute_StateDone
	ld (0x34db:16), 1

RhythmMute_StateDone:
	ret

RhythmMute_InlineCode:
	or	(0xe3e2:16), 8
	bit	7, w
	jr	nz, RhythmMute_StateMachine_Skip3
	cp	(0x34db:16), 0
	jr	nz, RhythmMute_StateMachine_Skip
	ld	(0x34db:16), 4
	jr	RhythmMute_StateMachine_Join
RhythmMute_StateMachine_Skip:
	cp	(0x34db:16), 3
	jr	nz, RhythmMute_StateMachine_Skip2
	ld	(0x34db:16), 0
	jr	RhythmMute_StateMachine_Join
RhythmMute_StateMachine_Skip2:
	cp	(0x34db:16), 7
	jr	z, RhythmMute_StateMachine_Join
	inc	1, (0x34db:16)
RhythmMute_StateMachine_Join:
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip3:
	cp	(0x34db:16), 0
	jr	nz, RhythmMute_StateMachine_Skip4
	ld	(0x34db:16), 3
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip4:
	cp	(0x34db:16), 4
	jr	nz, RhythmMute_StateMachine_Skip5
	ld	(0x34db:16), 0
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip5:
	cp	(0x34db:16), 1
	jr	z, RhythmMute_StateMachine_Return
	dec	1, (0x34db:16)
RhythmMute_StateMachine_Return:
	ret
RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	bit 7, (0x34f1:16)
	jr nz, RhythmSolo_Disable
	ld (0x34f1:16), 128
	jr RhythmSolo_UpdateStatus

RhythmSolo_Disable:
	ld (0x34f1:16), 0

RhythmSolo_UpdateStatus:
	calr DrumKit_UpdateStatusFlags
	bit 0, (0x3283:16)
	jr nz, RhythmSolo_Return
	or (0x34cd:16), 128

RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	ld a, (0x34cf:16)
	and a, 0xc
	cp a, 0:i3
	jr nz, RhythmVariation_Return
	ld a, (0x35fc:16)
	and a, 0xc
	cp a, 0:i3
	jr nz, RhythmVariation_Return
	and hl, 0xf
	ld xwa, RhythmFillIn_PatternTable
	ld	a, (xwa+hl)
	ld (0x379b:16), a
	calr DrumKit_UpdateStatusFlags
	bit 0, (0x3283:16)
	jr nz, RhythmVariation_PostDispatch
	or (0x34cd:16), 128

RhythmVariation_PostDispatch:
	call AudioInit_SelectAndDispatch
	call AudioMode_ResetVoiceState

RhythmVariation_Return:
	ret

RhythmVariation_InlineCode:
	calr	DrumKit_UpdateStatusFlags
	ret
AccScreen_DataBlock_Helper:
	push	xiz
	calr	RhythmVariation_Select_Helper4
	pop	xiz
	ret
RhythmVariation_Select_Helper4:
	cp	(PREVIOUS_TITLE:16), 182
	jr	z, RhythmVariation_Select_Skip4
	ld	(0x3712:16), 4
	or	(0x8d88:16), 1
RhythmVariation_Select_Skip4:
	and	(0xe3e2:16), 254
	or	(0x34cd:16), 8
	ret
AccScreen_DataBlock_Helper2:
	push	xiz
	calr	RhythmVariation_Select_Helper5
	pop	xiz
	ret
RhythmVariation_Select_Helper5:
	and	(0x34cd:16), 247
	ret
AccScreen_DataBlock_Helper3:
	push	xiz
	calr	RhythmVariation_Select_Helper6
	pop	xiz
	ret
RhythmVariation_Select_Helper6:
	ld	xhl, 0:i3
	ld	l, (0x379b:16)
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_Code
	ld	a, (xhl)
	ld	(0x379b:16), a
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	DrumKit_UpdateStatusFlags
	ret
RhythmVariation_InlineCode_Code:
	nop
	ld	(1:8), 0:io
	push	sr
	nop
	nop
	nop
	ld	(P0:8), 0:io
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
RhythmVariation_InlineCode_Sub:
	push	xiz
	calr	RhythmVariation_InlineCode_Sub_Helper
	pop	xiz
	ret
RhythmVariation_InlineCode_Sub_Helper:
	ld	xhl, 0:i3
	ld	l, (0x379b:16)
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_Code2
	ld	a, (xhl)
	ld	(0x379b:16), a
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	DrumKit_UpdateStatusFlags
	ret
RhythmVariation_InlineCode_Code2:
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
	calr	RhythmVariation_InlineCode_Sub_Helper_Helper
	pop	xiz
	ret
RhythmVariation_InlineCode_Sub_Helper_Helper:
	cp	(0x3712:16), 4
	jr	z, RhythmVariation_InlineCode_Sub_Helper_Skip
	jr	RhythmVariation_Select_Return
RhythmVariation_InlineCode_Sub_Helper_Skip:
	bit	7, w
	jr	nz, RhythmVariation_InlineCode_Sub_Helper_Skip2
	inc	1, (0x3714:16)
	cp	(0x3714:16), 13
	jr	ule, RhythmVariation_Select_Join
	ld	(0x3714:16), 13
	jr	RhythmVariation_Select_Join
RhythmVariation_InlineCode_Sub_Helper_Skip2:
	dec	1, (0x3714:16)
	cp	(0x3714:16), 1
	jr	ge, RhythmVariation_Select_Join
	ld	(0x3714:16), 1
RhythmVariation_Select_Join:
	jr	RhythmVariation_Select_Return
RhythmVariation_Select_Return:
	ret
	push	xiz
	calr	RhythmVariation_Select_Helper2
	pop	xiz
	ret
RhythmVariation_Select_Helper2:
	cp	(0x3712:16), 4
	jr	nz, RhythmVariation_Select_Return2
	bit	7, w
	jr	nz, RhythmVariation_Select_Skip
	inc	1, (0x3715:16)
	cp	(0x3715:16), 13
	jr	ule, RhythmVariation_Select_Join2
	ld	(0x3715:16), 13
	jr	RhythmVariation_Select_Join2
RhythmVariation_Select_Skip:
	dec	1, (0x3715:16)
	cp	(0x3715:16), 255
	jr	nz, RhythmVariation_Select_Join2
	ld	(0x3715:16), 0
RhythmVariation_Select_Join2:
	jr	RhythmVariation_Select_Return2
RhythmVariation_Select_Return2:
	ret
	push	xiz
	calr	RhythmVariation_Select_Helper3
	pop	xiz
	ret
RhythmVariation_Select_Helper3:
	cp	(0x3712:16), 4
	jr	z, RhythmVariation_Select_Skip2
	jr	RhythmVariation_Select_Join4
RhythmVariation_Select_Skip2:
	bit	7, w
	jr	nz, RhythmVariation_Select_Skip3
	inc	1, (0x3716:16)
	cp	(0x3716:16), 3
	jr	ule, RhythmVariation_Select_Join3
	ld	(0x3716:16), 3
	jr	RhythmVariation_Select_Join3
RhythmVariation_Select_Skip3:
	dec	1, (0x3716:16)
	cp	(0x3716:16), 255
	jr	nz, RhythmVariation_Select_Join3
	ld	(0x3716:16), 0
RhythmVariation_Select_Join3:
	jr	RhythmVariation_Select_Return3
RhythmVariation_Select_Join4:
	bit	7, w
	jr	nz, RhythmVariation_Select_Entry
	or	(0x372d:16), 16
	jr	RhythmVariation_Select_Return3
RhythmVariation_Select_Entry:
	or	(0x372d:16), 32
RhythmVariation_Select_Return3:
	ret
CmpSetTtl_Dispatch_Helper:
	push	xiz
	call	RhythmVariation_Select_Entry_Data
	pop	xiz
	ret
RhythmVariation_Select_Entry_Data:
	cp	(PREVIOUS_TITLE:16), 180
	jr	z, RhythmVariation_Select_Entry_Data_Skip
	ld	(13632:16), 1
	call	AccPatch_GetCurrentSlotAddr
	ld	l, (xiy+16)
	and	l, 255
	ld	h, (xiy+17)
	and	h, 127
	calr	TimeSig_DisplayStrings_Code_Sub2
	calr	DrumKit_PostMidiEvents
RhythmVariation_Select_Entry_Data_Skip:
	calr	RhythmVariation_Select_Helper
	ret

RhythmConfig_ReturnStub:
	ret

RhythmConfig_InlineCode2:
	push	xiz
	call	RhythmConfig_InlineCode2_Data
	pop	xiz
	ret
RhythmConfig_InlineCode2_Data:
	cp	(CURRENT_TITLE:16), 180
	jr	z, RhythmConfig_InlineCode2_Data_Return
	calr	DrumKit_SendProgramChange
RhythmConfig_InlineCode2_Data_Return:
	ret

DrumTempo_Adjust:
	push xiz
	push xix
	ld a, (0x3540:16)
	bit 7, w
	jr nz, DrumTempo_Decrement
	ld l, 0x6:opc
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, 0x10
	bitm 0, (xix)
	jr nz, DrumTempo_CheckMax
	cp (0x34d6:16), 11
	jr ugt, DrumTempo_CheckMax
	ld l, 0x8:opc

DrumTempo_CheckMax:
	cp a, l
	jr z, DrumTempo_Done
	inc 1, a
	jr DrumTempo_Store

DrumTempo_Decrement:
	cp a, 1:i3
	jr z, DrumTempo_Done
	dec 1, a

DrumTempo_Store:
	ld (0x3540:16), a

DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	push xiz
	xor hl, hl
	ld l, (0x3540:16)
	cp l, 1:i3
	jr nc, DrumVoice_ClampMin
	ld l, 0x1:opc

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
	or (0x8d88:16), 1
	pushw hl
	ld xhl, 0:i3
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
	bit	7, (0x34ce:16)
	jr	z, DrumVoice_Handler0_Skip
	bit	7, w
	jr	nz, DrumVoice_Handler0_Code_Skip
	inc	1, (0x34d7:16)
	cp	(0x34d7:16), 7
	jr	ule, DrumVoice_Handler0_Code_Entry
	ld	(0x34d7:16), 7
	jr	DrumVoice_Handler0_Code_Entry
DrumVoice_Handler0_Code_Skip:
	dec	1, (0x34d7:16)
	cp	(0x34d7:16), 0
	jr	ge, DrumVoice_Handler0_Code_Entry
	ld	(0x34d7:16), 0
DrumVoice_Handler0_Code_Entry:
	or	(0x34ce:16), 1
	jr	DrumVoice_Handler0_Code_Return
DrumVoice_Handler0_Skip:
	ld	(GLOBAL_ERROR_CODE:16), 19
	calr	DrumVoice_NotifyEE
DrumVoice_Handler0_Code_Return:
	ret
DrumVoice_Handler1:
	bit	7, (0x34ce:16)
	jr	z, DrumVoice_Handler1_Skip
	bit	7, w
	jr	nz, DrumVoice_Handler1_Code_Skip
	inc	1, (0x34d8:16)
	cp	(0x34d8:16), 11
	jr	ule, DrumVoice_Handler1_Code_Entry
	ld	(0x34d8:16), 11
	jr	DrumVoice_Handler1_Code_Entry
DrumVoice_Handler1_Code_Skip:
	dec	1, (0x34d8:16)
	cp	(0x34d8:16), 4
	jr	ge, DrumVoice_Handler1_Code_Entry
	ld	(0x34d8:16), 4
DrumVoice_Handler1_Code_Entry:
	or	(0x34ce:16), 2
	jr	DrumVoice_Handler1_Return
DrumVoice_Handler1_Skip:
	ld	(GLOBAL_ERROR_CODE:16), 19
	calr	DrumVoice_NotifyEE
DrumVoice_Handler1_Return:
	ret
DrumVoice_Handler2:
	or	(0xe3e2:16), 8
	bit	7, w
	jr	nz, DrumVoice_Handler2_Skip
	inc	1, (0x34e9:16)
	cp	(0x34e9:16), 11
	jr	ule, DrumVoice_Handler2_Join
	ld	(0x34e9:16), 11
	jr	DrumVoice_Handler2_Join
DrumVoice_Handler2_Skip:
	dec	1, (0x34e9:16)
	cp	(0x34e9:16), 0
	jr	ge, DrumVoice_Handler2_Join
	ld	(0x34e9:16), 0
DrumVoice_Handler2_Join:
	or	(0x34d2:16), 1
	ret
DrumVoice_Handler3:
	or	(0xe3e2:16), 8
	bit	7, w
	jr	nz, DrumVoice_Handler3_Entry
	or	(0x34ea:16), 16
	jr	DrumVoice_Handler3_Join
DrumVoice_Handler3_Entry:
	and	(0x34ea:16), 239
DrumVoice_Handler3_Join:
	or	(0x34d2:16), 2
	ret
DrumVoice_Handler5:
	and	(0xe3e2:16), 247
	bit	7, w
	jr	nz, DrumVoice_Handler5_Skip
	bit	5, (0x34ea:16)
	jr	nz, DrumVoice_Handler5_Return
	or	(0x34ea:16), 32
	or	(0x34d2:16), 4
	jr	DrumVoice_Handler5_Return
DrumVoice_Handler5_Skip:
	bit	5, (0x34ea:16)
	jr	z, DrumVoice_Handler5_Return
	and	(0x34ea:16), 223
	or	(0x34d2:16), 4
DrumVoice_Handler5_Return:
	ret
DrumVoice_Handler4:
	and	(0xe3e2:16), 247
	bit	7, w
	jr	nz, DrumVoice_Handler4_Code_Entry
	bit	6, (0x34ea:16)
	jr	nz, DrumVoice_Handler4_Return
	or	(0x34ea:16), 64
	or	(0x34d2:16), 4
	jr	DrumVoice_Handler4_Return
DrumVoice_Handler4_Code_Entry:
	bit	6, (0x34ea:16)
	jr	z, DrumVoice_Handler4_Return
	and	(0x34ea:16), 191
	or	(0x34d2:16), 4
DrumVoice_Handler4_Return:
	ret
	or	(0xe3e2:16), 8
	ld	a, (0x34ea:16)
	and	a, 96
	bit	7, w
	jr	nz, DrumVoice_Handler4_Code_Skip4
	cp	a, 0:i3
	jr	nz, DrumVoice_Handler4_Code_Skip
	ld	a, 64:opc
	jr	DrumVoice_Handler4_Code_Join
DrumVoice_Handler4_Code_Skip:
	cp	a, 64
	jr	nz, DrumVoice_Handler4_Code_Skip2
	ld	a, 32:opc
	jr	DrumVoice_Handler4_Code_Join
DrumVoice_Handler4_Code_Skip2:
	cp	a, 32
	jr	nz, DrumVoice_Handler4_Code_Skip3
	ld	a, 96:opc
	jr	DrumVoice_Handler4_Code_Join
DrumVoice_Handler4_Code_Skip3:
	cp	a, 96
	jr	nz, DrumVoice_Handler4_Code_Join
	ld	a, 96:opc
DrumVoice_Handler4_Code_Join:
	jr	DrumVoice_Handler4_Code_Entry2
DrumVoice_Handler4_Code_Skip4:
	cp	a, 0:i3
	jr	nz, DrumVoice_Handler4_Code_Skip5
	ld	a, 0:opc
	jr	DrumVoice_Handler4_Code_Entry2
DrumVoice_Handler4_Code_Skip5:
	cp	a, 64
	jr	nz, DrumVoice_Handler4_Code_Skip6
	ld	a, 0:opc
	jr	DrumVoice_Handler4_Code_Entry2
DrumVoice_Handler4_Code_Skip6:
	cp	a, 32
	jr	nz, DrumVoice_Handler4_Code_Skip7
	ld	a, 64:opc
	jr	DrumVoice_Handler4_Code_Entry2
DrumVoice_Handler4_Code_Skip7:
	cp	a, 96
	jr	nz, DrumVoice_Handler4_Code_Entry2
	ld	a, 32:opc
DrumVoice_Handler4_Code_Entry2:
	and	(0x34ea:16), 159
	or	(0x34ea:16), a
	or	(0x34d2:16), 4
	ret
DrumVoice_Handler6:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 1927
	ldw	(0xe3e4:16), 1670
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, DrumVoice_Handler6_Return
	calr	DrumVoice_Handler6_Helper
	calr	DrumKit_PostMidiEvents
	calr	RhythmVariation_Select_Helper
DrumVoice_Handler6_Return:
	ret
DrumVoice_Handler7:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 1927
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, DrumVoice_Handler7_Return
	calr	DrumVoice_Handler7_Helper2
	calr	DrumKit_PostMidiEvents
	calr	RhythmVariation_Select_Helper
DrumVoice_Handler7_Return:
	ret
	push	xiz
	bit	0, (0x34d3:16)
	jr	nz, DrumVoice_Handler7_Epilogue
	cp	(0x34d6:16), 12
	jr	nc, DrumVoice_Handler7_Epilogue
	calr	DrumVoice_Handler7_Helper
DrumVoice_Handler7_Epilogue:
	pop	xiz
	ret
DrumVoice_Handler7_Helper:
	or	(0x8d88:16), 1
	and	(0xe3e2:16), 247
	ld	xiy, RHYTHM_PATTERN_BUF_A
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, DrumVoice_Handler7_Code_Return
	cp	(0x34d6:16), 12
	jr	nc, DrumVoice_Handler7_Code_Return
	calr	DrumVoice_Handler7_Helper_Helper
DrumVoice_Handler7_Code_Return:
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
	and	(0xe3e2:16), 254
	ret
CmpNcpTtl_Dispatch_Helper:
	push	xiz
	call	DrumVoice_Handler7_Data
	pop	xiz
	ret
DrumVoice_Handler7_Data:
	cp	(PREVIOUS_TITLE:16), 184	; TT_CMPNCP
	jr	z, DrumVoice_Handler7_Data_Code_Skip
	calr	DrumVoice_Handler7_Code_Helper2
	ld	l, (0x34ed:16)
	ld	h, (0x34ee:16)
	calr	DrumVoice_Handler7_Data_Code_Helper
	calr	DrumKit_PostMidiEvents
	and	(0x34cd:16), 191
DrumVoice_Handler7_Data_Code_Skip:
	calr	TimeSig_DisplayStrings_Code_Sub
	calr	DrumVoice_Handler7_Code_Helper
	calr	DrumVoice_Handler7_Code_Helper2
	ret
DrumVoice_Handler7_Code_Helper:
	ld	a, (0xfc5a:16)
	and	a, 255
	cp	a, 128
	jr	c, DrumVoice_Handler7_Code_Return2
	cp	a, 128
	jr	z, DrumVoice_Handler7_Code_Return2
	cp	a, 132
	jr	z, DrumVoice_Handler7_Code_Return2
	cp	a, 136
	jr	z, DrumVoice_Handler7_Code_Return2
	and	a, 127
	ld	xix, CmpNcp_ProgramGroupBase
	ld	a, (xix+a)
	ld (64602:16), a
	ld (13549:16), a
	and	a, 127
	ld	(0xffa1:16), a
	ld	(0xffbf:16), a
	calr	DrumKit_PostMidiEvents
DrumVoice_Handler7_Code_Return2:
	ret
CmpNcp_ProgramGroupBase:
	; (0xFC5A) & 0x7F -> the first program of its group of four: 0x81..0x83 -> 0x80, 0x85..0x87 ->
	; 0x84, 0x89..0x8B -> 0x88.  DrumVoice_Handler7_Code_Helper returns before the lookup for
	; values below 0x80 and for 0x80, 0x84 and 0x88 themselves.
	.byte	0x80, 0x80, 0x80, 0x80, 0x84, 0x84, 0x84, 0x84, 0x88, 0x88, 0x88, 0x88
DrumVoice_Handler7_Data_2_Sub:
	push	xiz
	call	DrumVoice_Handler7_Data_3
	pop	xiz
	ret
DrumVoice_Handler7_Data_3:
	cp	(CURRENT_TITLE:16), 184	; TT_CMPNCP
	jr	z, DrumVoice_Handler7_Code_Return3
	calr	DrumKit_SendProgramChange
DrumVoice_Handler7_Code_Return3:
	ret
CmpNcpTtl_Dispatch2_Helper:
	push	xiz
	call	DrumVoice_Handler7_Data_3_Helper
	pop	xiz
	ret
DrumVoice_Handler7_Data_3_Helper:
	ld	a, (0x39a7:16)
	bit	7, w
	jr	z, DrumVoice_Handler7_Code_Skip
	cp	a, 2:i3
	jr	z, DrumVoice_Handler7_Code_Return4
	inc	1, a
	jr	DrumVoice_Handler7_Code_Join
DrumVoice_Handler7_Code_Skip:
	cp	a, 0:i3
	jr	z, DrumVoice_Handler7_Code_Return4
	dec	1, a
DrumVoice_Handler7_Code_Join:
	ld	(0x39a7:16), a
DrumVoice_Handler7_Code_Return4:
	ret
CmpNcpTtl_Dispatch2_Helper2:
	push	xiz
	call	DrumVoice_Handler7_Data_3_Helper2
	pop	xiz
	ret
DrumVoice_Handler7_Data_3_Helper2:
	ld	a, (0x39a7:16)
	sll	a, 1
	ld	xix, CmpNcp_ItemA_HandlerIndex
	ld	hl, (xix+a)
	call	DrumVoice_Handler7_Data_3_Helper5
	ret
CmpNcp_ItemA_HandlerIndex:
	; (0x39A7), stepped between 0 and 2 by DrumVoice_Handler7_Data_3_Helper -> the
	; CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper2 dispatches.
	; Reached through CmpNcpTtl_Dispatch2_Helper / _Helper2.
	.short	0, 1, 2
DrumVoice_Handler7_Data_3_Sub:
	push	xiz
	call	DrumVoice_Handler7_Data_3_Helper3
	pop	xiz
	ret
DrumVoice_Handler7_Data_3_Helper3:
	ld	a, (0x39a8:16)
	bit	7, w
	jr	z, DrumVoice_Handler7_Data_3_Helper3_Skip
	cp	a, 1:i3
	jr	z, DrumVoice_Handler7_Code_Return5
	inc	1, a
	jr	DrumVoice_Handler7_Code_Join2
DrumVoice_Handler7_Data_3_Helper3_Skip:
	cp	a, 0:i3
	jr	z, DrumVoice_Handler7_Code_Return5
	dec	1, a
DrumVoice_Handler7_Code_Join2:
	ld	(0x39a8:16), a
DrumVoice_Handler7_Code_Return5:
	ret
CmpNcpTtl_Dispatch2_Helper3:
	push	xiz
	call	DrumVoice_Handler7_Data_3_Helper4
	pop	xiz
	ret
DrumVoice_Handler7_Data_3_Helper4:
	ld	a, (0x39a8:16)
	sll	a, 1
	ld	xix, CmpNcp_ItemB_HandlerIndex
	ld	hl, (xix+a)
	call	DrumVoice_Handler7_Data_3_Helper5
	ret
CmpNcp_ItemB_HandlerIndex:
	; (0x39A8), stepped between 0 and 1 by DrumVoice_Handler7_Data_3_Helper3 -> the
	; CmpNcp_ItemHandlerTable index that DrumVoice_Handler7_Data_3_Helper4 dispatches.
	; Reached through CmpNcpTtl_Dispatch2_Helper3.
	.short	3, 4
	push	xiz
	call	DrumVoice_Handler7_Data_3_Helper5
	pop	xiz
	ret
DrumVoice_Handler7_Data_3_Helper5:
	pushw	hl
	ld	xhl, 0:i3
	popw	hl
	and	hl, 7
	sll	hl, 2
	add	xhl, CmpNcp_ItemHandlerTable
	ld	xhl, (xhl)
	call	(xhl)
	ret
CmpNcp_ItemHandlerTable:
	; DrumVoice_Handler7_Data_3_Helper5 calls entry (HL & 7).  DrumVoice_Handler7_Data_3_Helper2
	; and _Helper4 pass 0..4 from the two tables above; the wrapper just before
	; DrumVoice_Handler7_Data_3_Helper5 passes its caller's HL.  5 and 6 are DrumVoice_NullHandler;
	; an index of 7 would read the first four bytes of CmpNcp_ItemHandler0.  Each handler sets bits
	; of (0xE3E2) and stores its own word in (0xE3E4): 0x0080, 0x0181, 0x0282, 0x8505, 0x0686.
	; This table and the five handlers were decoded as code (`jrl ule, ...`, `.byte 0xc1, 0xe2,
	; 0xe3 / push xiz` ...) until 2026-10-03.
	.long	CmpNcp_ItemHandler0
	.long	CmpNcp_ItemHandler1
	.long	CmpNcp_ItemHandler2
	.long	CmpNcp_ItemHandler3
	.long	CmpNcp_ItemHandler4
	.long	DrumVoice_NullHandler
	.long	DrumVoice_NullHandler
CmpNcp_ItemHandler0:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 0x0080
	calr	889
	calr	62875
	calr	1200
	calr	1384
	ret
CmpNcp_ItemHandler1:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 0x0181
	calr	1010
	calr	62846
	calr	1171
	ret
CmpNcp_ItemHandler2:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 0x0282
	calr	1359
	ret
CmpNcp_ItemHandler3:
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 0x8505
	calr	1573
	ret
CmpNcp_ItemHandler4:
	or	(0xe3e2:16), 8
	or	(0xe3e2:16), 1
	ldw	(0xe3e4:16), 0x0686
	calr	1668
	ret
	push	xiz
	call	DrumVoice_Handler7_Data_4
	pop	xiz
	ret
DrumVoice_Handler7_Data_4:
	cp	(PREVIOUS_TITLE:16), 189	; TT_CMMODE
	jr	z, DrumVoice_Handler7_Code_Entry
	and	(0x34cd:16), 191
	ld	xix, RHYTHM_PATTERN_BUF_A
	add	xix, 16
	ld	a, (xix)
	and	(0x34d3:16), 254
	bit	0, a
	jr	z, DrumVoice_Handler7_Code_Entry
	or	(0x34d3:16), 1
DrumVoice_Handler7_Code_Entry:
	and	(0xe3e2:16), 222
	ret
	ret
	ret
	push	xiz
	call	DrumVoice_Handler7_Code_Entry_Data
	pop	xiz
	ret
DrumVoice_Handler7_Code_Entry_Data:
	cp	(PREVIOUS_TITLE:16), 187	; TT_CMBEND
	jr	z, DrumVoice_Handler7_Code_Entry_Data_Code_Entry
	and	(0x34cd:16), 191
DrumVoice_Handler7_Code_Entry_Data_Code_Entry:
	cp	(ACTIVE_TITLE_PREVIOUS:16), 187	; TT_CMBEND
	jr	z, DrumVoice_Handler7_Code_Entry_Data_Join
DrumVoice_Handler7_Code_Entry_Data_Join:
	and	(0xe3e2:16), 254
	ret
	or	(0xe3e2:16), 8
	ld	a, (0xfdba:16)
	and	a, 15
	ld	w, a
	cp	hl, 0:i3
	jr	nz, DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Skip
	inc	1, a
	cp	a, 13
	jr	c, DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Join
	ld	a, 12:opc
	jr	DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Join
DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Skip:
	dec	1, a
	cp	a, 255
	jr	nz, DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Join
	ld	a, 0:opc
DrumVoice_Handler7_Code_Entry_Data_Code_Entry_Code_Join:
	ld	(0xfdba:16), a
	cp	a, w
	jr	z, DrumVoice_Handler7_Code_Return6
	ld	w, 15:opc
	ld	e, 145:opc
	ld	d, 4:opc
	call	SwbtWr_QueuePostEvent
DrumVoice_Handler7_Code_Return6:
	ret
	ret
	ld	(0x34d6:16), 0
	calr	DrumKit_SendProgramChange
	ret
DrumVoice_Handler6_Helper:
	push	w
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	ld	a, 72:opc
	ld	(0x90f7:16), a
	call	PartCtrl_WriteProgramChange
	pop	w
	bit	7, w
	jr	nz, DrumVoice_Handler7_Code_Skip2
	inc	1, l
	cp	l, 14
	jr	c, DrumVoice_Handler7_Code_Join3
	ld	l, 13:opc
	jr	DrumVoice_Handler7_Code_Join3
DrumVoice_Handler7_Code_Skip2:
	dec	1, l
	cp	l, 255
	jr	nz, DrumVoice_Handler7_Code_Join3
	ld	l, 0:opc
DrumVoice_Handler7_Code_Join3:
	ld	xix, 0xff92
	ld	h, (xix+l)
	ld a, 72:opc
	ld	(0x90f6:16), a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	ld	(0xfc5a:16), l
	and	h, 127
	ld	(0xfc5b:16), h
	ret
RhythmVariation_Select_Helper:
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	sll	l, 1
	sll	hl, 1
	ld	xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	add hl, 2
	ld	xde, 0:i3
	ld	de, (xiy+hl)
	ld w, a
	and xwa, 65280
	sll	xwa, 8
	ld	xix, 0x400000
	add	xix, xwa
	add	xix, xde
	jr	DrumVoice_Handler7_Code_Join4
DrumVoice_Handler7_Code_Join4:
	ld	a, (xix+976)
	ld	(0x34f0:16), a
	ret
DrumVoice_Handler7_Helper2:
	push	w
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	ld	a, 72:opc
	ld	(0x90f7:16), a
	call	PartCtrl_WriteProgramChange
	ld	a, h
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	ld	(0x342d:16), l
	popw	hl
	pop	w
	bit	7, w
	jr	nz, DrumVoice_Handler7_Code_Skip3
	inc	1, a
	cp a, (13357:16)
	jr ule, DrumVoice_Handler7_Code_Join5
	ld a, (13357:16)
	jr DrumVoice_Handler7_Code_Join5
DrumVoice_Handler7_Code_Skip3:
	dec 1, a
	cp a, 255
	jr	nz, DrumVoice_Handler7_Code_Join5
	ld	a, 0:opc
DrumVoice_Handler7_Code_Join5:
	ld	h, a
	ld	xwa, 0xff92
	ld	(xwa+l), h
	ld	a, 72:opc
	ld	(0x90f6:16), a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	ld	(0xfc5a:16), l
	and	h, 127
	ld	(0xfc5b:16), h
	ret
DrumVoice_Handler7_Helper_Helper:
	ld	l, (0x34f0:16)
	and	l, 31
	xor	h, h
	sll	hl, 3
	ld	xbc, TimeSig_DisplayStrings
	add	xbc, 7
	ld	w, (xbc+hl)
	ld l, (13528:16)
	and l, 31
	xor	h, h
	sll	hl, 3
	ld	xbc, TimeSig_DisplayStrings
	add	xbc, 7
	ld	a, (xbc+hl)
	cp a, w
	jr	nz, DrumVoice_Handler7_Code_Skip4
	call	AccPatch_GetCurrentSlotAddr
	ld	a, (0xfc5a:16)
	and	a, 255
	ld	(xiy+16), a
	ld	a, (0xfc5b:16)
	and	a, 127
	ld	(xiy+17), a
	ld	(GLOBAL_ERROR_CODE:16), 21
	calr	DrumVoice_NotifyEE
	jr	DrumVoice_Handler7_Code_Return7
DrumVoice_Handler7_Code_Skip4:
	ld	(GLOBAL_ERROR_CODE:16), 22
	calr	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
DrumVoice_Handler7_Code_Return7:
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
	ld a, 0xee:opc
	call SoundCtrl_SendCommand
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

TimeSig_DisplayStrings:
; TimeSig_DisplayStrings +0x00..+0xC7 -- 20 time-signature records of 10 bytes:
; a 9-character display name "(n/d)+0 " and one byte that is the bar length in
; quarter notes (2/2 -> 4, 3/4 -> 3, 6/8 -> 3, 14/8 -> 7, 16/8 -> 8 ...).
; ** RE-TYPED 2026-09-25 (lane accomp): the names were .ascii already but the
; length bytes and "(4/2)" "(8/4)" "(8/8)" "(16/8)" names were spelled as
; push sr / max / reti / `pushw wa`.. (data-as-code).  The 10-byte stride and
; the 20-record count are read off the bytes: 20 records end exactly where
; the code at +0xC8 (call ...) begins.  READER NOT ESTABLISHED for this
; stride: the only direct readers found (`ld xbc, TimeSig_DisplayStrings /
; add xbc,7` after `sll hl,3`, in the code that follows DrumVoice_Handler7)
; index it with stride 8 at +7, which does not fit 10-byte records; the
; positional labels TimeSig_DisplayStrings_Code.. point far past this table
; into the code and data that follow.
	.ascii "(1/2)+0  "
	.byte 2
	.ascii "(2/2)+0  "
	.byte 4
	.ascii "(3/2)+0  "
	.byte 6
	.ascii "(4/2)+0  "
	.byte 8
	.ascii "(1/4)+0  "
	.byte 1
	.ascii "(2/4)+0  "
	.byte 2
	.ascii "(3/4)+0  "
	.byte 3
	.ascii "(4/4)+0  "
	.byte 4
	.ascii "(5/4)+0  "
	.byte 5
	.ascii "(6/4)+0  "
	.byte 6
	.ascii "(7/4)+0  "
	.byte 7
	.ascii "(8/4)+0  "
	.byte 8
	.ascii "(2/8)+0  "
	.byte 1
	.ascii "(4/8)+0  "
	.byte 2
	.ascii "(6/8)+0  "
	.byte 3
	.ascii "(8/8)+0  "
	.byte 4
	.ascii "(10/8)+0 "
	.byte 5
	.ascii "(12/8)+0 "
	.byte 6
	.ascii "(14/8)+0 "
	.byte 7
	.ascii "(16/8)+0 "
	.byte 8
DrumVoice_Handler7_Data_Code_Helper:
	call	16069349
TimeSig_DisplayStrings_Code_Sub2:
	ld	(0xfc5a:16), l
	and	h, 127
	and	(0xfc5b:16), 128
	or	(0xfc5b:16), h
	ld	(0x90f7:16), 72
	call	PartCtrl_WriteProgramChange
	ld	w, h
	extz	hl
	extz	xhl
	add	xhl, 0xff92
	jr	TimeSig_DisplayStrings_Code_Join10
TimeSig_DisplayStrings_Code_Join10:
	ld	(xhl), w
	ret
	push	w
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	ld	a, 72:opc
	ld	(0x90f7:16), a
	call	PartCtrl_WriteProgramChange
	pop	w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip2
	inc	1, l
	cp	l, 14
	jr	nz, TimeSig_DisplayStrings_Code_Skip
	ld	l, 15:opc
	jr	TimeSig_DisplayStrings_Code_Join
TimeSig_DisplayStrings_Code_Skip:
	cp	l, 16
	jr	c, TimeSig_DisplayStrings_Code_Join
	ld	l, 15:opc
	jr	TimeSig_DisplayStrings_Code_Join
TimeSig_DisplayStrings_Code_Skip2:
	dec	1, l
	cp	l, 14
	jr	nz, TimeSig_DisplayStrings_Code_Skip3
	ld	l, 13:opc
	jr	TimeSig_DisplayStrings_Code_Join
TimeSig_DisplayStrings_Code_Skip3:
	cp	l, 255
	jr	nz, TimeSig_DisplayStrings_Code_Join
	ld	l, 0:opc
TimeSig_DisplayStrings_Code_Join:
	ld	a, l
	ld	xix, 0xff92
	ld	h, (xix+l)
	ld l, a
	ld	a, 72:opc
	ld	(0x90f6:16), a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	ld	(0xfc5a:16), l
	and	h, 127
	ld	(0xfc5b:16), h
	cp	(0x34ef:16), 26
	jr	z, TimeSig_DisplayStrings_Code_Return12
	cp	(0xfc5a:16), 128
	jr	c, TimeSig_DisplayStrings_Code_Entry4
	cp	(0x34ef:16), 16
	jr	nc, TimeSig_DisplayStrings_Code_Return12
	ld	(0x34ef:16), 16
	jr	TimeSig_DisplayStrings_Code_Return12
TimeSig_DisplayStrings_Code_Entry4:
	cp	(0x34ef:16), 16
	jr	c, TimeSig_DisplayStrings_Code_Return12
	ld	(0x34ef:16), 0
TimeSig_DisplayStrings_Code_Return12:
	ret
	push	w
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	ld	a, 72:opc
	ld	(0x90f7:16), a
	call	PartCtrl_WriteProgramChange
	ld	a, h
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	ld	(0x342d:16), l
	popw	hl
	pop	w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip4
	cp	l, 15
	jr	nz, TimeSig_DisplayStrings_Code_Skip38
	push	xix
	ld	xix, TimeSig_StepUpTable15
	ld	a, (xix+a)
	pop	xix
	jr	TimeSig_DisplayStrings_Code_Join2
TimeSig_DisplayStrings_Code_Skip38:
	inc	1, a
	cp	a, (0x342d:16)
	jr	ule, TimeSig_DisplayStrings_Code_Join2
	ld	a, (0x342d:16)
	jr	TimeSig_DisplayStrings_Code_Join2
TimeSig_DisplayStrings_Code_Skip4:
	cp	l, 15
	jr	nz, TimeSig_DisplayStrings_Code_Skip5
	push	xix
	ld	xix, TimeSig_StepDownTable15
	ld	a, (xix+a)
	pop xix
	jr	TimeSig_DisplayStrings_Code_Join2
TimeSig_DisplayStrings_Code_Skip5:
	dec	1, a
	cp	a, 255
	jr	nz, TimeSig_DisplayStrings_Code_Join2
	ld	a, 0:opc
TimeSig_DisplayStrings_Code_Join2:
	ld	h, a
	ld	xwa, 0xff92
	ld	(xwa+l), h
	ld	a, 72:opc
	ld	(0x90f6:16), a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	ld	(0xfc5a:16), l
	and	h, 127
	ld	(0xfc5b:16), h
	ret
; Two 12-entry step tables for (0x342D) when AccVoice_GetChannelCount_Direct returns 15: the routine above
; takes A := TimeSig_StepUpTable15[A] on an up step and A := TimeSig_StepDownTable15[A] on a down step
; (bit 7 of W).  Were decoded as `max ... / ld (P2:8),8 ...` code; the second was the positional alias
; TimeSig_DisplayStrings + 0x227.
TimeSig_StepUpTable15:		.byte	4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8
TimeSig_StepDownTable15:	.byte	0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 4
TimeSig_DisplayStrings_Code_Sub:
	ld	a, (0xfc5a:16)
	and	a, 255
	ld	w, (0xfc5b:16)
	and	w, 127
	ld	(0x34ed:16), a
	ld	(0x34ee:16), w
	ret
DrumVoice_Handler7_Code_Helper2:
	ld	l, (0x34ed:16)
	and	l, 255
	cp	l, 240
	jr	c, DrumVoice_Handler7_Code_Helper2_Skip5
	ld	l, 128:opc
	ld	(0x34ed:16), l
	ld	(0x34ee:16), 0
DrumVoice_Handler7_Code_Helper2_Skip5:
	cp	l, 128
	jr	c, TimeSig_DisplayStrings_Code_Skip6
	ld	a, (0x34ee:16)
	and	a, 127
	cp	a, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Skip6
	ld	(0x34ee:16), 0
TimeSig_DisplayStrings_Code_Skip6:
	cp	l, 128
	jr	c, TimeSig_DisplayStrings_Code_Entry3
	cp	(0x34ef:16), 16
	jr	nc, TimeSig_DisplayStrings_Code_Entry
	ld	(0x34ef:16), 26
TimeSig_DisplayStrings_Code_Entry:
	cp	(0x34ef:16), 26
	jr	nz, TimeSig_DisplayStrings_Code_Entry2
	ld	a, (0x34cd:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Skip7
	cp	a, 32
	jr	z, TimeSig_DisplayStrings_Code_Skip8
	ld	(0x34d6:16), 32
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Skip7:
	ld	(0x34d6:16), 30
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Skip8:
	ld	(0x34d6:16), 31
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Entry2:
	cp	(0x34d6:16), 30
	jr	c, TimeSig_DisplayStrings_Code_Return
	ld	a, (0x34cd:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Skip10
	cp	a, 32
	jr	z, TimeSig_DisplayStrings_Code_Skip9
	ld	(0x34d6:16), 8
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Skip9:
	ld	(0x34d6:16), 4
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Skip10:
	ld	(0x34d6:16), 0
	jr	TimeSig_DisplayStrings_Code_Return
TimeSig_DisplayStrings_Code_Entry3:
	cp	(0x34ef:16), 16
	jr	c, TimeSig_DisplayStrings_Code_Skip11
	ld	(0x34ef:16), 26
TimeSig_DisplayStrings_Code_Skip11:
	jr	TimeSig_DisplayStrings_Code_Entry
TimeSig_DisplayStrings_Code_Return:
	ret
AccPatch_ComplexDataBlock_Helper2:
	ret
	.byte 0xc1, 0xed
	ldw	ix, 0x803f
	jr	c, TimeSig_DisplayStrings_Code_Return2
	cp	(0x34ef:16), 10
	jr	c, TimeSig_DisplayStrings_Code_Return2
	ld	(0x34ef:16), 0
TimeSig_DisplayStrings_Code_Return2:
	ret
	push	w
	ld	l, (0xfc5a:16)
	and	l, 255
	ld	h, (0xfc5b:16)
	and	h, 127
	ld	a, 72:opc
	ld	(0x90f7:16), a
	call	PartCtrl_WriteProgramChange
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	ld	(0x342d:16), h
	popw	hl
	ld	a, l
	cp	a, 15
	jr	lt, TimeSig_DisplayStrings_Code_Skip12
	ld	(0x342e:16), 25
	ld	(0x342f:16), 16
	jr	TimeSig_DisplayStrings_Code_Join3
TimeSig_DisplayStrings_Code_Skip12:
	ld	(0x342e:16), 15
	ld	(0x342f:16), 0
TimeSig_DisplayStrings_Code_Join3:
	ld	a, (0x34ef:16)
	pop	w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip14
	cp	a, 26
	jr	nz, TimeSig_DisplayStrings_Code_Skip13
	push	xix
	ld	a, (0x34d6:16)
	ld	xix, TimeSig_DisplayStrings_Code3
	ld	a, (xix+a)
	ld	(0x34d6:16), a
	pop	xix
	ld	a, (0x342f:16)
	jr	TimeSig_DisplayStrings_Code_Skip15
TimeSig_DisplayStrings_Code_Skip13:
	inc	1, a
	cp	a, (0x342e:16)
	jr	ule, TimeSig_DisplayStrings_Code_Skip15
	ld	a, (0x342e:16)
	jr	TimeSig_DisplayStrings_Code_Skip15
TimeSig_DisplayStrings_Code_Skip14:
	cp	a, 26
	jr	z, TimeSig_DisplayStrings_Code_Skip15
	dec	1, a
	cp a, (13359:16)
	jr ge, TimeSig_DisplayStrings_Code_Skip15
	push	xix
	ld	a, (0x34d6:16)
	ld	xix, TimeSig_DisplayStrings_Code2
	ld	a, (xix+a)
	ld (13526:16), a
	pop xix
	ld	a, 26:opc
	jr	0
TimeSig_DisplayStrings_Code_Skip15:
	ld	(0x34ef:16), a
	ret
TimeSig_DisplayStrings_Code2:
	calr	7710
	calr	7967
	.byte 0x1f, 0x1f
	ld	w, 32:opc
	ld	w, 32:opc
	calr	7710
	calr	7710
	.byte 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f
	ld	w, 32:opc
	.ascii "    "
	calr	8223
TimeSig_DisplayStrings_Code3:
	nop
	nop
	nop
	nop
	max
	max
	max
	max
	ld	(P2:8), 8:io
	ld	(P0:8), 0:io
	nop
	nop
	nop
	nop
	max
	max
	max
	max
	max
	max
	ld	(P2:8), 8:io
	ld	(P2:8), 8:io
	nop
	max
	ld	(TAMOD:8), 51:io
	reti
	jr	nz, 58
	bit	5, (0x34cd:16)
	jr	z, 22
	and	(0x34cd:16), 207
	or	(0x34cd:16), 16
	ld	(0x34d6:16), 32
	ld	(0x34ef:16), 26
	jr	81
	bit	4, (0x34cd:16)
	jr	z, 2
	jr	73
	and	(0x34cd:16), 207
	or	(0x34cd:16), 32
	ld	(0x34d6:16), 31
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return3
	bit	5, (0x34cd:16)
	jr	z, DrumVoice_Handler7_Code_Helper2_Entry
	and	(0x34cd:16), 207
	ld	(0x34d6:16), 30
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return3
DrumVoice_Handler7_Code_Helper2_Entry:
	bit	4, (0x34cd:16)
	jr	z, TimeSig_DisplayStrings_Code_Return3
	and	(0x34cd:16), 207
	or	(0x34cd:16), 32
	ld	(0x34d6:16), 31
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return3
TimeSig_DisplayStrings_Code_Return3:
	ret
	ld	a, (0x34d6:16)
	bit	4, (0x34cd:16)
	jr	z, DrumVoice_Handler7_Code_Helper2_Skip
	calr	DrumVoice_Handler7_Code_Helper2_Helper3
	jr	DrumVoice_Handler7_Code_Helper2_Join
DrumVoice_Handler7_Code_Helper2_Skip:
	bit	5, (0x34cd:16)
	jr	z, DrumVoice_Handler7_Code_Helper2_Skip2
	calr	DrumVoice_Handler7_Code_Helper2_Helper2
	jr	DrumVoice_Handler7_Code_Helper2_Join
DrumVoice_Handler7_Code_Helper2_Skip2:
	calr	DrumVoice_Handler7_Code_Helper2_Helper
DrumVoice_Handler7_Code_Helper2_Join:
	ld	(0x34d6:16), a
	ret
DrumVoice_Handler7_Code_Helper2_Helper:
	bit	7, w
	jr	nz, DrumVoice_Handler7_Code_Helper2_Skip4
	inc	1, a
	cp	a, 31
	jr	nz, DrumVoice_Handler7_Code_Helper2_Skip3
	calr	TimeSig_DisplayStrings_Code_Helper
	ld	a, 0:opc
	jr	TimeSig_DisplayStrings_Code_Join4
DrumVoice_Handler7_Code_Helper2_Skip3:
	cp	a, 4:i3
	jr	nz, TimeSig_DisplayStrings_Code_Skip16
	ld	a, 12:opc
	jr	TimeSig_DisplayStrings_Code_Join4
TimeSig_DisplayStrings_Code_Skip16:
	cp	a, 18
	jr	lt, TimeSig_DisplayStrings_Code_Join4
	ld	a, 17:opc
	jr	TimeSig_DisplayStrings_Code_Join4
TimeSig_DisplayStrings_Code_Join4:
	jr	TimeSig_DisplayStrings_Code_Return4
DrumVoice_Handler7_Code_Helper2_Skip4:
	dec	1, a
	cp	a, 29
	jr	nz, TimeSig_DisplayStrings_Code_Skip17
	ld	a, 30:opc
	jr	TimeSig_DisplayStrings_Code_Return4
TimeSig_DisplayStrings_Code_Skip17:
	cp	a, 255
	jr	nz, TimeSig_DisplayStrings_Code_Skip18
	ld	a, 30:opc
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return4
TimeSig_DisplayStrings_Code_Skip18:
	cp	a, 11
	jr	nz, TimeSig_DisplayStrings_Code_Skip19
	ld	a, 3:opc
	jr	TimeSig_DisplayStrings_Code_Return4
TimeSig_DisplayStrings_Code_Skip19:
	cp	a, 18
	jr	lt, TimeSig_DisplayStrings_Code_Return4
	ld	a, 17:opc
TimeSig_DisplayStrings_Code_Return4:
	ret
TimeSig_DisplayStrings_Code_Helper:
	ld	a, (0xfc5a:16)
	and	a, 255
	cp	a, 128
	jr	c, TimeSig_DisplayStrings_Code_Skip20
	ld	(0x34ef:16), 16
	jr	TimeSig_DisplayStrings_Code_Return5
TimeSig_DisplayStrings_Code_Skip20:
	ld	(0x34ef:16), 0
TimeSig_DisplayStrings_Code_Return5:
	ret
DrumVoice_Handler7_Code_Helper2_Helper2:
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip23
	inc	1, a
	cp	a, 32
	jr	nz, TimeSig_DisplayStrings_Code_Skip21
	calr	TimeSig_DisplayStrings_Code_Helper
	ld	a, 4:opc
	jr	TimeSig_DisplayStrings_Code_Loop
TimeSig_DisplayStrings_Code_Skip21:
	cp	a, 8
	jr	nz, TimeSig_DisplayStrings_Code_Skip22
	ld	a, 18:opc
	jr	TimeSig_DisplayStrings_Code_Loop
TimeSig_DisplayStrings_Code_Skip22:
	cp	a, 24
	jr	lt, TimeSig_DisplayStrings_Code_Loop
	ld	a, 23:opc
TimeSig_DisplayStrings_Code_Loop:
	jr	TimeSig_DisplayStrings_Code_Return6
TimeSig_DisplayStrings_Code_Skip23:
	dec	1, a
	cp	a, 30
	jr	nz, TimeSig_DisplayStrings_Code_Skip24
	ld	a, 31:opc
	jr	TimeSig_DisplayStrings_Code_Return6
TimeSig_DisplayStrings_Code_Skip24:
	cp	a, 3:i3
	jr	nz, TimeSig_DisplayStrings_Code_Skip25
	ld	a, 31:opc
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return6
TimeSig_DisplayStrings_Code_Skip25:
	cp	a, 17
	jr	nz, TimeSig_DisplayStrings_Code_Skip26
	ld	a, 7:opc
	jr	TimeSig_DisplayStrings_Code_Return6
TimeSig_DisplayStrings_Code_Skip26:
	cp	a, 24
	jr	lt, TimeSig_DisplayStrings_Code_Loop
	ld	a, 23:opc
TimeSig_DisplayStrings_Code_Return6:
	ret
DrumVoice_Handler7_Code_Helper2_Helper3:
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip29
	inc	1, a
	cp	a, 33
	jr	nz, TimeSig_DisplayStrings_Code_Skip27
	calr	TimeSig_DisplayStrings_Code_Helper
	ld	a, 8:opc
	jr	TimeSig_DisplayStrings_Code_Join5
TimeSig_DisplayStrings_Code_Skip27:
	cp	a, 12
	jr	nz, TimeSig_DisplayStrings_Code_Skip28
	ld	a, 24:opc
	jr	TimeSig_DisplayStrings_Code_Join5
TimeSig_DisplayStrings_Code_Skip28:
	cp	a, 30
	jr	lt, TimeSig_DisplayStrings_Code_Join5
	ld	a, 29:opc
	jr	TimeSig_DisplayStrings_Code_Join5
TimeSig_DisplayStrings_Code_Join5:
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Skip29:
	dec	1, a
	cp	a, 31
	jr	nz, TimeSig_DisplayStrings_Code_Skip30
	ld	a, 32:opc
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Skip30:
	cp	a, 7:i3
	jr	nz, TimeSig_DisplayStrings_Code_Skip31
	ld	a, 32:opc
	ld	(0x34ef:16), 26
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Skip31:
	cp	a, 23
	jr	nz, TimeSig_DisplayStrings_Code_Helper_Skip
	ld	a, 11:opc
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Helper_Skip:
	cp	a, 30
	jr	lt, TimeSig_DisplayStrings_Code_Join5
	ld	a, 29:opc
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Return7:
	ret
	call	AccWrap_PlayModeDispatch
	or	(0x28a7:16), 4
	ld	a, (0xfc5a:16)
	and	a, 15
	ld	(0x390a:16), a
	call	TimeSig_DisplayStrings_Helper
	ld	(0x391e:16), xiy
	add	xiy, 16
	ld	(0x3922:16), xiy
	bit	0, (0x3926:16)
	jr	nz, TimeSig_DisplayStrings_Code_Helper_Skip2
	ld	xbc, 4:i3
	ld	xiy, (0x391e:16)
	ld	xix, 0x390e
	ldir85
	ld	(0x390d:16), 0
TimeSig_DisplayStrings_Code_Helper_Skip2:
	and	(0x3926:16), 254
	ret
	ret
	ret
TimeSig_DisplayStrings_Helper:
	ld	xwa, 0:i3
	ld	xbc, 0:i3
	ld	a, 32:opc
	ld	c, (0x390a:16)
	mul	wa, c
	add	xwa, RHYTHM_PATTERN_BUF_A
	add	xwa, 2976
	ld	xiy, xwa
	ret
	ld	a, (0x390c:16)
	ld	xiy, 0x390e
	ld	c, (xiy+a)
	ld (14601:16), c
	ret
TimeSig_DisplayStrings_Code_Helper_Helper2:
	ld a, (14603:16)
	ld xiy, 14606
	ld	c, (xiy+a)
	ld (14600:16), c
	ret
	.byte 0xc1, 0xa7
	pushw	wa
	push	xix
	swi	3
	and	(0x3926:16), 254
	ret
	ld	a, (0x390a:16)
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Helper_Helper2_Skip2
	cp	a, 4:i3
	jr	nc, TimeSig_DisplayStrings_Code_Helper_Helper2_Skip
	inc	1, a
	jr	TimeSig_DisplayStrings_Code_Helper_Helper2_Join
TimeSig_DisplayStrings_Code_Helper_Helper2_Skip:
	ld	a, 4:opc
TimeSig_DisplayStrings_Code_Helper_Helper2_Join:
	jr	TimeSig_DisplayStrings_Code_Join6
TimeSig_DisplayStrings_Code_Helper_Helper2_Skip2:
	cp	a, 0:i3
	jr	ule, TimeSig_DisplayStrings_Code_Helper_Skip3
	dec	1, a
	jr	TimeSig_DisplayStrings_Code_Join6
TimeSig_DisplayStrings_Code_Helper_Skip3:
	ld	a, 0:opc
TimeSig_DisplayStrings_Code_Join6:
	ld	(0x390a:16), a
	or	a, 240
	ld	(0xfc5a:16), a
	ld	a, 0:opc
	ld	(0xfc5b:16), a
	calr	DrumKit_PostMidiEvents
	ld	(0x390d:16), 0
	ret
	push	w
	calr	TimeSig_DisplayStrings_Code_Helper_Helper2
	pop	w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Helper_Skip6
	cp	(0x3908:16), 11
	jr	nc, TimeSig_DisplayStrings_Code_Helper_Skip4
	inc	1, (0x3908:16)
	jr	TimeSig_DisplayStrings_Code_Helper_Join2
TimeSig_DisplayStrings_Code_Helper_Skip4:
	cp	(0x3908:16), 255
	jr	nz, TimeSig_DisplayStrings_Code_Helper_Skip5
	ld	(0x3908:16), 0
	jr	TimeSig_DisplayStrings_Code_Helper_Join2
TimeSig_DisplayStrings_Code_Helper_Skip5:
	ld	(0x3908:16), 11
TimeSig_DisplayStrings_Code_Helper_Join2:
	jr	TimeSig_DisplayStrings_Code_Helper_Join
TimeSig_DisplayStrings_Code_Helper_Skip6:
	cp	(0x3908:16), 0
	jr	le, TimeSig_DisplayStrings_Code_Helper_Skip7
	dec	1, (0x3908:16)
	jr	TimeSig_DisplayStrings_Code_Helper_Join
TimeSig_DisplayStrings_Code_Helper_Skip7:
	cp	(0x390b:16), 0
	jr	nz, TimeSig_DisplayStrings_Code_Skip32
	ld	(0x3908:16), 0
	jr	TimeSig_DisplayStrings_Code_Helper_Join
TimeSig_DisplayStrings_Code_Skip32:
	ld	(0x3908:16), 255
TimeSig_DisplayStrings_Code_Helper_Join:
	ld	a, (0x3908:16)
	ld	(0x3909:16), a
	ld	xix, 0x390e
	ld	c, (0x390b:16)
	ld	(xix+c), a
	ld xix, 14606
	calr	TimeSig_DisplayStrings_Code_Helper_Helper
	or	(0x3926:16), 1
	ret
TimeSig_DisplayStrings_Code_Helper_Helper:
	ld	(0x390d:16), 0
	ld	h, 0:opc
	calr	TimeSig_DisplayStrings_Code_Helper2
	ld	wa, bc
	pushw	wa
	ld	h, 1:opc
	calr	TimeSig_DisplayStrings_Code_Helper2
	popw	wa
	cp	bc, 0xffff
	jr	z, TimeSig_DisplayStrings_Code_Skip33
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Skip33
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Skip33:
	pushw	wa
	ld	h, 2:opc
	calr	TimeSig_DisplayStrings_Code_Helper2
	popw	wa
	cp	bc, 0xffff
	jr	z, TimeSig_DisplayStrings_Code_Skip34
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Skip34
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Skip34:
	pushw	wa
	ld	h, 3:opc
	calr	TimeSig_DisplayStrings_Code_Helper2
	popw	wa
	cp	bc, 0xffff
	jr	z, TimeSig_DisplayStrings_Code_Helper_Return
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Helper_Return
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Helper_Return:
	ret
TimeSig_DisplayStrings_Code_Helper2:
	ld	l, (xix+h)
	cp l, 255
	jr	z, TimeSig_DisplayStrings_Code_Helper2_Skip
	pushdi_b	(13526)
	ld	(0x34d6:16), l
	push	h
	push	xix
	call	AccPatch_CheckAndInitDemo_Helper2
	pop	xix
	pop	h
	pop	(0x34d6:16)
	ld	b, a
	jr	TimeSig_DisplayStrings_Code_Helper2_Return
TimeSig_DisplayStrings_Code_Helper2_Skip:
	ldw	bc, 0xffff
TimeSig_DisplayStrings_Code_Helper2_Return:
	ret
TimeSig_DisplayStrings_Code_Helper3:
	push	xwa
	ld	xwa, TimeSig_DisplayStrings_Code4
	ld	a, (xwa+h)
	or (14605:16), a
	pop	xwa
	ret
TimeSig_DisplayStrings_Code4:
	normal
	push	sr
	max
	ld	(P2:8), 8:io
	ld	(P2:8), 62:io
	call	TimeSig_DisplayStrings_Helper2
	pop	xiz
	ret
TimeSig_DisplayStrings_Helper2:
	ret
	.byte 0xc1
	ldw	(57:8), 0xc104:io
	pushw	1081
	ld	(0x390a:16), 0
TimeSig_DisplayStrings_Code_Helper3_Join:
	cp	(0x390a:16), 5
	jr	z, 19
	calr	65120
	ld	xix, xiy
	push	xix
	calr	TimeSig_DisplayStrings_Code_Helper_Helper
	pop	xix
	calr	TimeSig_DisplayStrings_Code_Helper3_Helper
	inc	1, (0x390a:16)
	jr	TimeSig_DisplayStrings_Code_Helper3_Join
	pop	(0x390b:16)
	pop	(0x390a:16)
	ld	(0x390d:16), 0
	ret
TimeSig_DisplayStrings_Code_Helper3_Helper:
	bit	1, (0x390d:16)
	jr	z, TimeSig_DisplayStrings_Code_Helper3_Skip
	ld	b, 255:opc
	ld	a, 1:opc
	ld	(xix+a), b
TimeSig_DisplayStrings_Code_Helper3_Skip:
	bit	2, (0x390d:16)
	jr	z, TimeSig_DisplayStrings_Code_Helper3_Skip2
	ld	b, 255:opc
	ld	a, 2:opc
	ld	(xix+a), b
TimeSig_DisplayStrings_Code_Helper3_Skip2:
	bit	3, (0x390d:16)
	jr	z, TimeSig_DisplayStrings_Code_Helper3_Return
	ld	b, 255:opc
	ld	a, 3:opc
	ld	(xix+a), b
TimeSig_DisplayStrings_Code_Helper3_Return:
	ret
	ld xbc, 4:i3
	ld xix, (14622:16)
	ld	xiy, 0x390e
	ldir85
	ret
CmEsyTtl_Dispatch2_Helper:
	push	xiz
	call	TimeSig_DisplayStrings_Helper3
	pop	xiz
	ret
TimeSig_DisplayStrings_Helper3:
	calr	TimeSig_DisplayStrings_Code_Helper4
	calr	DrumKit_UpdateStatusFlags
	call	AudioInit_SelectAndDispatch
	call	AudioMode_ResetVoiceState
	calr	RhythmPatInit_LoadParams
	ret
TimeSig_DisplayStrings_Code_Helper4:
	ld	(0x379b:16), 1
	bit	4, (0x37c9:16)
	jr	nz, TimeSig_DisplayStrings_Code_Helper4_Return
	ld	(0x379b:16), 2
	bit	5, (0x37c9:16)
	jr	nz, TimeSig_DisplayStrings_Code_Helper4_Return
	ld	(0x379b:16), 4
	bit	6, (0x37c9:16)
	jr	nz, TimeSig_DisplayStrings_Code_Helper4_Return
	ld	(0x379b:16), 8
	bit	3, (0x37c9:16)
	jr	nz, TimeSig_DisplayStrings_Code_Helper4_Return
	ld	(0x379b:16), 16
TimeSig_DisplayStrings_Code_Helper4_Return:
	ret
	ld	(0x37c9:16), 16
	bit	0, (0x379b:16)
	jr	nz, TimeSig_DisplayStrings_Code_Return8
	ld	(0x37c9:16), 32
	bit	1, (0x379b:16)
	jr	nz, TimeSig_DisplayStrings_Code_Return8
	ld	(0x37c9:16), 64
	bit	2, (0x379b:16)
	jr	nz, TimeSig_DisplayStrings_Code_Return8
	ld	(0x37c9:16), 8
	bit	3, (0x379b:16)
	jr	nz, TimeSig_DisplayStrings_Code_Return8
	ld	(0x37c9:16), 1
TimeSig_DisplayStrings_Code_Return8:
	ret
CmpSetTtl_Dispatch2_Helper:
	push	xiz
	call	TimeSig_DisplayStrings_Helper4
	pop	xiz
	ret
TimeSig_DisplayStrings_Helper4:
	ld	a, (0x39aa:16)
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip35
	cp	a, 3:i3
	jr	z, TimeSig_DisplayStrings_Code_Return9
	inc	1, a
	jr	TimeSig_DisplayStrings_Code_Join7
TimeSig_DisplayStrings_Code_Skip35:
	cp	a, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Return9
	dec	1, a
TimeSig_DisplayStrings_Code_Join7:
	ld	(0x39aa:16), a
TimeSig_DisplayStrings_Code_Return9:
	ret
	push	xiz
	call	TimeSig_DisplayStrings_Helper5
	pop	xiz
	ret
TimeSig_DisplayStrings_Helper5:
	pushw	wa
	call	AccPatch_GetCurrentSlotAddr
	popw	wa
	ld	xix, TimeSig_DisplayStrings_Code5
	ld	a, (0x39aa:16)
	ld	a, (xix+a)
	ld	l, (xiy+a)
	bit 7, w
	jr nz, TimeSig_DisplayStrings_Code_Skip36
	cp l, 127
	jr	z, TimeSig_DisplayStrings_Code_Return10
	inc	1, l
	jr	TimeSig_DisplayStrings_Code_Join8
TimeSig_DisplayStrings_Code_Skip36:
	cp	l, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Return10
	dec	1, l
TimeSig_DisplayStrings_Code_Join8:
	ld	(xiy+a), l
TimeSig_DisplayStrings_Code_Return10:
	ret
TimeSig_DisplayStrings_Code5:
	ld b, 42:opc
	ldw de, 15930
	call	TimeSig_DisplayStrings_Helper6
	pop	xiz
	ret
TimeSig_DisplayStrings_Helper6:
	pushw	wa
	call	AccPatch_GetCurrentSlotAddr
	popw	wa
	ld	xix, TimeSig_SlotFieldOffsets
	ld	a, (0x39aa:16)
	ld	a, (xix+a)
	ld	l, (xiy+a)
	bit 7, w
	jr nz, TimeSig_DisplayStrings_Code_Skip37
	cp l, 11
	jr z, TimeSig_DisplayStrings_Code_Return11
	inc 1, l
	jr	TimeSig_DisplayStrings_Code_Join9
TimeSig_DisplayStrings_Code_Skip37:
	cp	l, 0:i3
	jr	z, TimeSig_DisplayStrings_Code_Return11
	dec	1, l
TimeSig_DisplayStrings_Code_Join9:
	ld	(xiy+a), l
TimeSig_DisplayStrings_Code_Return11:
	ret
; TimeSig_SlotFieldOffsets -- offsets into the current slot record (AccPatch_GetCurrentSlotAddr), indexed by (0x39AA)
TimeSig_SlotFieldOffsets:	.byte	37, 45, 53, 61
; S2cTtl_InitOnTitleChange -- when CURRENT_TITLE differs from PREVIOUS_TITLE: (0x3989) := (0xFFE3) + 1, and if (0x398A)
;          is 0, seed 0x398A-0x3995.  Called from S2cTtl_Dispatch.  Was hidden: the table above was decoded as code
;          running into its first instruction, and the call used the positional alias TimeSig_DisplayStrings_0x8E2.
S2cTtl_InitOnTitleChange:
	ld	a, (CURRENT_TITLE:16)
	cp	a, (PREVIOUS_TITLE:16)
	ret	z
	ld	a, (0xffe3:24)
	inc	1, a
	ld	(0x3989:16), a
	ld	wa, (0x398a:16)
	cp	wa, 0:i3
	ret	nz
	ldw	(0x398a:16), 1
	ldw	(0x398c:16), 1
	ld	(0x398e:16), 25
	ld	(0x398f:16), 0
	ld	(0x3990:16), 0
	ld	(0x3991:16), 0
	ld	(0x3992:16), 0
	ld	(0x3993:16), 0
	ld	(0x3994:16), 0
	ld	(0x3995:16), 0
	ret
	ret
; TimeSig_CallProc -- WA = index 0..23 (`cp de, 23 / ret ugt`), BC bit 7 = a flag
; passed on in A; calls TimeSig_ProcTable[index] (`ld xde, TimeSig_ProcTable / add
; xde, xbc / ld xhl, (xde) / call (xhl)`).
TimeSig_CallProc:
	ld	de, wa
	cp	de, 23
	ret	ugt
	and	bc, 128
	cp	bc, 0:i3
	scc8	nz, a
	extz	wa
	ld	bc, de
	extz	xbc
	sll	xbc, 2
	ld	xde, TimeSig_ProcTable
	add	xde, xbc
	ld	xhl, (xde)
	call	(xhl)
	ret

Tempo_AdjustStartMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x80
	ld bc, 0:i3
	calr Tempo_DisplayParamCommon
	ld wa, (0x398a:16)
	cp (xsp), 0x0
	jr nz, Tempo_StartMeasureDec
	ld bc, wa
	cp wa, 0x3e7
	jr nc, Tempo_StartMeasureReturn
	inc 1, bc
	ld (0x398a:16), bc
	jr Tempo_StartMeasureSync

Tempo_StartMeasureDec:
	ld bc, wa
	cp wa, 1:i3
	jr ule, Tempo_StartMeasureReturn
	dec 1, bc
	ld (0x398a:16), bc

Tempo_StartMeasureSync:
	ld bc, (0x398c:16)
	ld wa, (0x398a:16)
	cp wa, bc
	jr ule, Tempo_StartMeasureSyncFar
	ld (0x398c:16), wa
	jr Tempo_StartMeasureSetDirty

Tempo_StartMeasureSyncFar:
	inc 7, wa
	cp wa, bc
	jr nc, Tempo_StartMeasureSetDirty
	ld (0x398c:16), wa

Tempo_StartMeasureSetDirty:
	set 4, (0xe3e0:16)

Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x81
	ld bc, 1:i3
	calr Tempo_DisplayParamCommon
	ld wa, (0x398c:16)
	cp (xsp), 0x0
	jr nz, Tempo_EndMeasureDec
	ld bc, wa
	cp wa, 0x3e7
	jr nc, Tempo_EndMeasureReturn
	inc 1, bc
	ld (0x398c:16), bc
	ld wa, bc
	jr Tempo_EndMeasureSyncStart

Tempo_EndMeasureDec:
	ld bc, wa
	cp wa, 1:i3
	jr ule, Tempo_EndMeasureReturn
	dec 1, bc
	ld (0x398c:16), bc
	ld wa, (0x398c:16)

Tempo_EndMeasureSyncStart:
	ld bc, (0x398a:16)
	cp bc, wa
	jr ule, Tempo_EndMeasureSyncFar
	ld (0x398a:16), wa
	jr Tempo_EndMeasureSetDirty

Tempo_EndMeasureSyncFar:
	inc 7, bc
	cp bc, wa
	jr nc, Tempo_EndMeasureSetDirty
	dec 7, wa
	ld (0x398a:16), wa

Tempo_EndMeasureSetDirty:
	set 4, (0xe3e0:16)

Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x82
	ld bc, 2:i3
	calr Tempo_DisplayParamCommon
	ld a, (0x398e:16)
	cp (xsp), 0x0
	jr nz, Tempo_QuantizeDec
	ld c, a
	cp a, 0x31
	jr nc, Tempo_QuantizeReturn
	inc 1, c
	ld (0x398e:16), c
	jr Tempo_QuantizeSetDirty

Tempo_QuantizeDec:
	ld c, a
	cp a, 1:i3
	jr ule, Tempo_QuantizeReturn
	dec 1, c
	ld (0x398e:16), c

Tempo_QuantizeSetDirty:
	set 4, (0xe3e0:16)

Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	dec 2, xsp
	ld (xsp), a
	ldw wa, 0x86
	ld bc, 6:i3
	calr Tempo_DisplayParamCommon
	ld a, (0x3990:16)
	extz wa
	sla wa, 2
	lda xbc, (Tempo_AdjustEffect_Table:24)
	ld	xbc, (xbc+wa)
	ld a, (xbc)
	cp (xsp), 0x0
	jr nz, Tempo_EffectDec
	cp a, 0x10
	jr nc, Tempo_EffectReturn
	inc 1, a
	jr Tempo_EffectStore

Tempo_EffectDec:
	cp a, 0:i3
	jr z, Tempo_EffectReturn
	dec 1, a

Tempo_EffectStore:
	ld (xbc), a
	set 4, (0xe3e0:16)

Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	cp a, 0:i3
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ld a, (0x398f:16)
	cp a, 0x1d
	ret nc
	inc 1, a
	ld (0x398f:16), a
	set 4, (0xe3e0:16)
	ret

Tempo_DecrementTimeSigNum:
	cp a, 0:i3
	ret nz
	ldw wa, 0x9
	ldw bc, 0x8
	calr Tempo_DisplayParamCommon
	ld a, (0x398f:16)
	cp a, 0:i3
	ret z
	dec 1, a
	ld (0x398f:16), a
	set 4, (0xe3e0:16)
	ret

Tempo_TimeSigCodeBlock:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 10
	ldw	bc, 11
	calr	Tempo_DisplayParamCommon
	ld	a, (0x3990:16)
	cp	a, 0:i3
	ret	z
	dec	1, a
	ld	(0x3990:16), a
	set	4, (0xe3e0:16)
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 132
	ld	bc, 4:i3
	calr	Tempo_DisplayParamCommon
	ld	a, (0x3990:16)
	cp	(xsp), 0
	jr	nz, Tempo_DecrementTimeSigNum_Skip
	ld	c, a
	cp	a, 4:i3
	jr	nc, Tempo_DecrementTimeSigNum_Epilogue
	inc	1, c
	ld	(0x3990:16), c
	jr	Tempo_DecrementTimeSigNum_Entry
Tempo_DecrementTimeSigNum_Skip:
	ld	c, a
	cp	a, 0:i3
	jr	z, Tempo_DecrementTimeSigNum_Epilogue
	dec	1, c
	ld	(0x3990:16), c
Tempo_DecrementTimeSigNum_Entry:
	set	4, (0xe3e0:16)
Tempo_DecrementTimeSigNum_Epilogue:
	inc	2, xsp
	ret

Tempo_EditBPM:
	cp a, 0:i3
	ret nz
	set 0, (0x8d88:16)
	calr Tempo_DisplayParamReturn
	ld (0x3988:16), l
	cp l, 1:i3
	jr z, Tempo_EditBPMDec
	cp l, 0:i3
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
	set 7, (0x34cd:16)
	set 7, (0x34cd:16)
	ret

Tempo_EditBPMApply:
	cp	a, 0:i3
	ret	nz
	ldw	wa, 176
	call	UI_PostModeChangeEvent
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 146
	ldw	bc, 18
	calr	Tempo_DisplayParamCommon
	ld	wa, (0x398a:16)
	cp	(xsp), 0
	jr	nz, Tempo_EditBPM_Skip2
	ld	bc, wa
	cp	wa, 999
	jr	nc, Tempo_EditBPM_Epilogue
	cp	bc, 989
	jr	c, Tempo_EditBPM_Skip
	ldw	(0x398a:16), 999
	jr	Tempo_EditBPM_Join
Tempo_EditBPM_Skip:
	add	bc, 10
	ld	(0x398a:16), bc
	jr	Tempo_EditBPM_Join
Tempo_EditBPM_Skip2:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_EditBPM_Epilogue
	cp	bc, 10
	jr	ugt, Tempo_EditBPM_Skip3
	ldw	(0x398a:16), 1
	jr	Tempo_EditBPM_Join
Tempo_EditBPM_Skip3:
	sub	bc, 10
	ld	(0x398a:16), bc
Tempo_EditBPM_Join:
	ld	bc, (0x398c:16)
	ld	wa, (0x398a:16)
	cp	wa, bc
	jr	ule, Tempo_EditBPM_Skip4
	ld	(0x398c:16), wa
	jr	Tempo_EditBPM_Entry
Tempo_EditBPM_Skip4:
	inc	7, wa
	cp	wa, bc
	jr	nc, Tempo_EditBPM_Entry
	ld	(0x398c:16), wa
Tempo_EditBPM_Entry:
	set	4, (0xe3e0:16)
Tempo_EditBPM_Epilogue:
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 147
	ldw	bc, 19
	calr	Tempo_DisplayParamCommon
	ld	wa, (0x398c:16)
	cp	(xsp), 0
	jr	nz, Tempo_EditBPM_Skip6
	ld	bc, wa
	cp	wa, 999
	jr	nc, Tempo_EditBPM_Epilogue2
	cp	bc, 989
	jr	c, Tempo_EditBPM_Skip5
	ldw	(0x398c:16), 999
	ldw	wa, 999
	jr	Tempo_EditBPM_Join2
Tempo_EditBPM_Skip5:
	add	bc, 10
	ld	(0x398c:16), bc
	ld	wa, bc
	jr	Tempo_EditBPM_Join2
Tempo_EditBPM_Skip6:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_EditBPM_Epilogue2
	cp	bc, 10
	jr	ugt, Tempo_EditBPM_Skip7
	ldw	(0x398c:16), 1
	ld	wa, 1:i3
	jr	Tempo_EditBPM_Join2
Tempo_EditBPM_Skip7:
	sub	bc, 10
	ld	(0x398c:16), bc
	ld	wa, (0x398c:16)
Tempo_EditBPM_Join2:
	ld	bc, (0x398a:16)
	cp	bc, wa
	jr	ule, Tempo_EditBPM_Skip8
	ld	(0x398a:16), wa
	jr	Tempo_EditBPM_Entry2
Tempo_EditBPM_Skip8:
	inc	7, bc
	cp	bc, wa
	jr	nc, Tempo_EditBPM_Entry2
	dec	7, wa
	ld	(0x398a:16), wa
Tempo_EditBPM_Entry2:
	set	4, (0xe3e0:16)
Tempo_EditBPM_Epilogue2:
	inc	2, xsp
	ret
	extz	wa
	jrl	Tempo_AdjustQuantize
	extz	wa
	jrl	Tempo_AdjustEffect

Tempo_DisplayParamCommon:
	or (0xe3e2:16), 9
	ld (0xe3e4:16), a
	ld (0xe3e6:16), c
	ret

Tempo_DisplayParamSkipClear:
	ld (GLOBAL_ERROR_CODE:16), a
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
	ld wa, 0:i3
	calr SeqRec_ValidateDone
	ld a, (0x3991:16)
	cp a, 0:i3
	jr z, Tempo_DisplayStartMeasure
	extz wa
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayStartMeasure
	ld c, (0x3991:16)
	extz bc
	ld wa, (0x398a:16)
	calr SetWall_StoreAndResolve
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, Tempo_DisplayStartMeasure
	ld wa, 0:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 0:i3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayStartMeasure:
	ld wa, 1:i3
	calr SeqRec_ValidateDone
	ld a, (0x3992:16)
	cp a, 0:i3
	jr z, Tempo_DisplayEndMeasure
	extz wa
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayEndMeasure
	ld c, (0x3992:16)
	extz bc
	ld wa, (0x398a:16)
	calr SetWall_StoreAndResolve
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, Tempo_DisplayEndMeasure
	ld wa, 1:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 1:i3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 1
	jrl z, Tempo_DisplayEffect

Tempo_DisplayEndMeasure:
	ld wa, 2:i3
	calr SeqRec_ValidateDone
	ld a, (0x3993:16)
	cp a, 0:i3
	jr z, Tempo_DisplayQuantize
	extz wa
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayQuantize
	ld c, (0x3993:16)
	extz bc
	ld wa, (0x398a:16)
	calr SetWall_StoreAndResolve
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, Tempo_DisplayQuantize
	ld wa, 2:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 2:i3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayQuantize:
	ld wa, 3:i3
	calr SeqRec_ValidateDone
	ld a, (0x3994:16)
	cp a, 0:i3
	jr z, Tempo_DisplayTimeSigNum
	extz wa
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayTimeSigNum
	ld c, (0x3994:16)
	extz bc
	ld wa, (0x398a:16)
	calr SetWall_StoreAndResolve
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, Tempo_DisplayTimeSigNum
	ld wa, 3:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 3:i3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 1
	jr z, Tempo_DisplayEffect

Tempo_DisplayTimeSigNum:
	ld wa, 4:i3
	calr SeqRec_ValidateDone
	ld a, (0x3995:16)
	cp a, 0:i3
	jr z, Tempo_DisplayEffectLookup
	extz wa
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayEffectLookup
	ld c, (0x3995:16)
	extz bc
	ld wa, (0x398a:16)
	calr SetWall_StoreAndResolve
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, Tempo_DisplayEffectLookup
	ld wa, 4:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 4:i3
	calr Tempo_FormatBPM
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 1
	jr nz, Tempo_DisplayEffectLookup

Tempo_DisplayEffect:
	calr Tempo_DisplayEffectRender

Tempo_DisplayEffectLookup:
	ldto_berp L, 0xfb
	popw_erp 0xfa
	ret

Tempo_DisplayEffectRender:
	ld wa, 0:i3
	calr SeqRec_ValidateDone
	ld wa, 1:i3
	calr SeqRec_ValidateDone
	ld wa, 2:i3
	calr SeqRec_ValidateDone
	ld wa, 3:i3
	calr SeqRec_ValidateDone
	ld wa, 4:i3
	jrl SeqRec_ValidateDone

Tempo_FormatBPM:
	pushw_erp 0xfa
	lda xde, (0x3998:16)
	ld xbc, xde
	lda xde, (xde + 10)

Tempo_FormatBPMDigit:
	ld (xbc+), 0x00
	cp xbc, xde
	jr c, Tempo_FormatBPMDigit
	cp a, 0:i3
	jr nz, Tempo_FormatBPMDone
	set 0, (0x3997:16)
	jr Tempo_FormatBPMOutput

Tempo_FormatBPMDone:
	res 0, (0x3997:16)

Tempo_FormatBPMOutput:
	cp a, 1:i3
	jr nz, Tempo_FormatBPMPad
	set 1, (0x3997:16)
	jr Tempo_DisplayBPMValue

Tempo_FormatBPMPad:
	res 1, (0x3997:16)

Tempo_DisplayBPMValue:
	ld wa, (0x398c:16)
	sub wa, (0x398a:16)
	inc 1, a
	ldfr_berp A, 0xfa
	mul wa, (0x3986:16)
	ldfr_berp A, 0xfa

Tempo_DisplayBPMFraction:
	cpib_erp 0xfa, 0
	jr z, Tempo_DisplayBPMWithDec
	calr Voice_ReadEventBytes
	calr RhythmParam_TypeCheck
	ld a, (0x3998:16)
	cp a, 0x81
	jr nz, Tempo_DisplayBPMNoFrac
	dec1b_erp 0xfa
	jr Tempo_DisplayBPMDecimal

Tempo_DisplayBPMNoFrac:
	cp a, 0x83
	jr z, Tempo_DisplayBPMWithDec

Tempo_DisplayBPMDecimal:
	calr Voice_ScanTableByType
	cp l, 1:i3
	jr nz, Tempo_DisplayBPMFraction
	jr Tempo_DisplayBPMExit

Tempo_DisplayBPMWithDec:
	cpib_erp 0xfa, 0
	jr z, Tempo_DisplayBPMClean
	ldib_erp 0xfb, 0

Tempo_DisplayBPMFinal:
	ld (0x3998:16), 129
	calr Voice_ScanTableByType
	cp l, 1:i3
	jr z, Tempo_DisplayBPMExit
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cpb_erp A, 0xfa
	jr nz, Tempo_DisplayBPMFinal

Tempo_DisplayBPMClean:
	ld (0x3998:16), 131
	calr Voice_ScanTableByType
	cp l, 1:i3
	jr z, Tempo_DisplayBPMExit
	ld l, 0x0:opc

Tempo_DisplayBPMExit:
	popw_erp 0xfa
	ret

Tempo_DisplayBPMReturn:
	lda xsp, (xsp - 18)
	push xiz
	ld xiy, Tempo_DisplayBPMReturn_LocalInit
	lda xix, (xsp + 6)
	ldw bc, 0x8
	ldirw
	ld e, (0x398f:16)
	ld xwa, 0:i3
	ld a, e
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	ld xiz, xbc
	add xiz, 0x94860
	lda xbc, (xiz + 12)
	ld a, (0x3986:16)
	inc 3, a
	cp a, (xbc)
	jr z, Tempo_DisplayMeasureRange
	ldmi16 (xsp + 4), 0x34d6
	ld (0x34d6:16), e
	ld a, (0x3986:16)
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
	ld wa, (0x398c:16)
	sub wa, (0x398a:16)
	ld (xiz + 13), a
	resm 7, (xiz + 15)
	lda xde, (xsp + 6)
	lda xwa, (xiz + 64)
	ld xbc, xwa
	lda xhl, (xwa + 16)

Tempo_DisplayMeasureStart:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, Tempo_DisplayMeasureStart
	cp (0x3991:16), 0
	jr z, Tempo_DisplayMeasureSep
	ld wa, 0:i3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureSep:
	cp (0x3992:16), 0
	jr z, Tempo_DisplayMeasureEnd
	ld wa, 1:i3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayMeasureEnd:
	cp (0x3993:16), 0
	jr z, Tempo_DisplayQuantizeVal
	ld wa, 2:i3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayQuantizeVal:
	cp (0x3994:16), 0
	jr z, Tempo_DisplayTimeSig
	ld wa, 3:i3
	calr Tempo_DisplayEffectValLookup

Tempo_DisplayTimeSig:
	cp (0x3995:16), 0
	jr z, Tempo_DisplayEffectVal
	ld wa, 4:i3
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
	ld a, (0x3991:16)
	ldfr_berp A, 0xfb
	ld (xsp + 8), 0x18
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay1:
	ld a, (0x3992:16)
	ldfr_berp A, 0xfb
	ld (xsp + 8), 0x20
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay2:
	ld a, (0x3993:16)
	ldfr_berp A, 0xfb
	ld (xsp + 8), 0x28
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay3:
	ld a, (0x3994:16)
	ldfr_berp A, 0xfb
	ld (xsp + 8), 0x30
	jr Tempo_RefreshDisplay5

Tempo_RefreshDisplay4:
	ld a, (0x3995:16)
	ldfr_berp A, 0xfb
	ld (xsp + 8), 0x38

Tempo_RefreshDisplay5:
	cpib_erp 0xfb, 0
	jrl z, SeqRec_UpdateFlags
	ld xwa, 0:i3
	ld a, (0x398f:16)
	ld xhl, xwa
	add xhl, xhl
	add xhl, xwa
	sll xhl, 5
	add xhl, 0x94860
	ld (xsp + 4), xhl
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	sla wa, 2
	lda xbc, (Tempo_RefreshDisplay5_Table:24)
	ld	xix, (xbc+wa)
	ld e, (xix + 1)
	extz de
	ld c, (xsp + 8)
	extz bc
	cp (xsp + 10), 0x0
	jr nz, SeqRec_InitState
	lda	xwa, (xhl+bc)
	ld c, (xix)
	extz bc
	calr SeqRec_CheckOverflow
	jr SeqRec_InitChannels

SeqRec_InitState:
	ld xwa, (xsp + 4)
	lda	xwa, (xwa+bc)
	ld c, (xix)
	extz bc
	calr SeqRec_OverflowCleanup

SeqRec_InitChannels:
	ldto_berp C, 0xfb
	extz bc
	ld wa, 1:i3
	calr SetWall_StoreAndResolve
	ld bc, (0x398a:16)
	dec 1, bc
	ld a, (0x3986:16)
	extz wa
	ldfr_werp WA, 0xfa
	mul xwa, bc
	ldfr_werp WA, 0xfa
	ld iz, 0:i3

SeqRec_StartRecord:
	cpw_erp IZ, 0xfa
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	calr Voice_ReadEventBytes
	lda xhl, (0x3998:16)
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
	lda	xwa, (xwa+de)
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
	cp e, 7:i3
	jr nz, SeqRec_CommitData
	ld c, 0x58:opc
	jr SeqRec_CommitFinalize

SeqRec_CommitData:
	cp c, 0xf0
	jr c, SeqRec_Validate
	ld c, 0x0:opc

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
	ld c, (0x34d6:16)
	ldfr_berp C, 0xfa
	ld c, (0x379b:16)
	ldfr_berp C, 0xfb
	cp a, 4:i3
	jr z, Part_SetVoiceType4
	cp a, 3:i3
	jr z, Part_SetVoiceType2
	cp a, 2:i3
	jr z, Part_SetVoiceType1
	cp a, 1:i3
	jr z, SeqRec_Cleanup
	cp a, 0:i3
	jr nz, Part_LoadAndIndexVoiceTable
	ld (0x379b:16), 16
	jr Part_LoadAndIndexVoiceTable

SeqRec_Cleanup:
	ld (0x379b:16), 8
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType1:
	ld (0x379b:16), 1
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType2:
	ld (0x379b:16), 2
	jr Part_LoadAndIndexVoiceTable

Part_SetVoiceType4:
	ld (0x379b:16), 4

Part_LoadAndIndexVoiceTable:
	ld a, (0x398f:16)
	ld (0x34d6:16), a
	ld xwa, 0:i3
	ld a, (0x398f:16)
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	sll xbc, 5
	add xbc, 0x94860
	ld a, (xbc + 12)
	dec 3, a
	ld (0x34d9:16), a
	ld a, (xbc + 13)
	ld (0x34d7:16), a
	push xde
	push xhl
	push xix
	push xiz
	call VoiceSlot_InitFromTable
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldto_berp A, 0xfa
	ld (0x34d6:16), a
	ldto_berp A, 0xfb
	ld (0x379b:16), a
	popw_erp 0xfa
	ret

Part_StoreVoiceTableIndex:
	ld c, a
	extz bc
	ld a, (0x398f:16)
	extz wa
	mul wa, 0x5
	add wa, bc
	ld (0x3980:16), wa
	ldw (0x3984:16), 6
	ret

SetWall_StoreAndResolve:
	ld (0x287f:16), wa
	extz bc
	ld wa, bc
	jp Voice_ResolveSlotAddr

MIDIChan_ScanForFree:
	ld xbc, 0xf1a0
	ld a, 0x1:opc

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
	ld (0x3996:16), 0
	ret

MIDIChan_StoreResult:
	ld (0x3996:16), a
	ret

VoiceSlot_UpdateState:
	ld a, (0x3996:16)
	ld (0x288d:16), a
	cp (0x3996:16), 0
	jr nz, VoiceSlot_SetBit2
	res 2, (0x287b:16)
	jr VoiceSlot_ValidateAndResolve

VoiceSlot_SetBit2:
	set 2, (0x287b:16)

VoiceSlot_ValidateAndResolve:
	call SeqVoice_ValidateAndProcessState
	ldmm16 0x287f, 0x398a
	ld a, (0x3993:16)
	cp a, 0:i3
	jr z, VoiceSlot_CheckSlot2
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot2:
	ld a, (0x3994:16)
	cp a, 0:i3
	jr z, VoiceSlot_CheckSlot3
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot3:
	ld a, (0x3995:16)
	cp a, 0:i3
	jr z, VoiceSlot_CheckSlot4
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot4:
	ld a, (0x3992:16)
	cp a, 0:i3
	jr z, VoiceSlot_CheckSlot5
	extz wa
	jr VoiceSlot_ResolveAddr

VoiceSlot_CheckSlot5:
	ld a, (0x3991:16)
	cp a, 0:i3
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
	ld l, 0x1:opc
	jr PartType_Return

PartType_NotPercussion:
	ld l, 0x0:opc

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
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr ule, VoiceBuf_CopyDone

VoiceBuf_CopyLoop:
	lda xbc, (0x3998:16)
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
	ld c, (0x3998:16)
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
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr ule, VoiceScan_NotFound

VoiceScan_WriteLoop:
	lda xbc, (0x3998:16)
	ld de, iz
	extz xde
	add xde, xbc
	ld c, (xde)
	ld (xwa), c
	calr VoiceTable_AdvanceWritePos
	ld xwa, xhl
	cp xwa, 0xffffffff
	jr nz, VoiceScan_NextEntry
	ld l, 0x1:opc
	jr VoiceScan_Return

VoiceScan_NextEntry:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr c, VoiceScan_WriteLoop

VoiceScan_NotFound:
	ld l, 0x0:opc

VoiceScan_Return:
	pop xiz
	ret

VoiceTable_AdvanceReadPos:
	ld xhl, xwa
	ld wa, (0x3982:16)
	inc 1, wa
	ld (0x3982:16), wa
	cp wa, 0x100
	jr c, VoiceTable_AdvRead_Done
	ld wa, (0x397e:16)
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
	ld (0x397e:16), wa
	ldw (0x3982:16), 5

VoiceTable_AdvRead_Done:
	jr VoiceTable_ResolveReadAddr

VoiceTable_ResolveReadAddr:
	ld bc, (0x3982:16)
	extz xbc
	ld wa, (0x397e:16)
	dec 1, wa
	extz xwa
	sll xwa, 8
	add xwa, 0xb0000
	add xwa, xbc
	ld xhl, xwa
	ret

VoiceTable_AdvanceWritePos:
	ld xhl, xwa
	ld wa, (0x3984:16)
	inc 1, wa
	ld (0x3984:16), wa
	cp wa, 0xff
	jr c, RhythmParam_Setup
	ld wa, (0x34d4:16)
	cp wa, 0:i3
	jr nz, VoiceTable_AdvWrite_AllocSlot
	ld xhl, 0xffffffff
	jr RhythmParam_Entry

VoiceTable_AdvWrite_AllocSlot:
	dec 1, wa
	ld (0x34d4:16), wa
	ldw bc, 0x96
	ld xde, 0x9f200

VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	lda xde, (xde+256)
	cp bc, 0x153
	jr ule, VoiceTable_AdvWrite_ScanLoop

VoiceTable_AdvWrite_LinkEntry:
	ld wa, (0x3980:16)
	extz xwa
	sll xwa, 8
	ld xhl, xwa
	add xhl, RHYTHM_PATTERN_BUF_B
	ld a, c
	ld (xhl + 3), a
	ld wa, bc
	srl wa, 8
	ld (xhl + 4), a
	ld wa, (0x3980:16)
	ld (xde + 1), a
	ld wa, (0x3980:16)
	srl wa, 8
	ld (xde + 2), a
	ld (0x3980:16), bc
	ldw (0x3984:16), 6
	setm 7, (xde)

; Rhythm parameter dispatch setup
RhythmParam_Setup:
	calr Voice_ResolveTableAddr

; Rhythm parameter entry
RhythmParam_Entry:
	ret

Voice_ResolveTableAddr:
	ld bc, (0x3984:16)
	extz xbc
	ld wa, (0x3980:16)
	extz xwa
	sll xwa, 8
	add xwa, RHYTHM_PATTERN_BUF_B
	add xwa, xbc
	ld xhl, xwa
	ret

; Rhythm parameter type check
RhythmParam_TypeCheck:
	lda xwa, (0x3998:16)
	bit 0, (0x3997:16)
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
	cp bc, 0:i3
	jr lt, RhythmParam_CheckExit
	cp bc, 6:i3
	jr gt, RhythmParam_CheckExit
	add bc, bc
	lda xix, (RhythmParam_Dispatch_CaseTable:24)
	ld	bc, (xix+bc)
	lda xix, (RhythmParam_CheckExit:24)
	jp	t, (xix+bc)

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
	ld e, (0x398e:16)
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
	ld a, 0x19:opc
	sub a, e
	ld e, a
	ld a, (xbc)
	sub a, e
	ld (xbc), a
	cp a, 0:i3
	jr ge, Voice_BoundaryCheck
	ld (xix), 0x0

Voice_BoundaryCheck:
	bit 1, (0x3997:16)
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
	cp e, 7:i3
	jr z, VoiceParam_D0_Skip
	cp e, 4:i3
	jr z, VoiceParam_D0_Process
	cp e, 3:i3
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
	cp a, 4:i3
	jr nz, VoiceParam_B0_Process_Join
	bitm 3, (xix)
	jr z, VoiceParam_B0_Process_Join
	ld (xhl), 0xd3
	bitm 3, (xbc)
	jr nz, VoiceParam_B0_Process
	ld (xde), 0x0
	ret

VoiceParam_B0_Process:
	ld (xde), 0x7f
	ret

VoiceParam_B0_Process_Join:
	cp a, 0x8
	jr nz, Voice_ClearSlotAndRet
	ld a, (xix)
	res 7, a
	cp a, 0:i3
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
	ld a, 0x40:opc
	sub a, e
	extz wa
	div a, 0x6
	ld e, a
	ld a, 0x40:opc
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
	cp de, 0:i3
	jr lt, Voice_ClearSlotAndRet
	cp de, 6:i3
	jr gt, Voice_ClearSlotAndRet
	add de, de
	lda xix, (VoiceSlot_Dispatch_CaseTable:24)
	ld	de, (xix+de)
	lda xix, (Voice_ClearSlotAndRet:24)
	jp	t, (xix+de)

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
	call	TimeSig_CallProc
	inc	4, xsp
	ret

Voice_ResolveSlotAddr:
	push xiz
	ld w, (0x3996:16)
	call SetWall_SlotResolve
	ld (0x3982:16), iy
	ld iy, (0x28af:16)
	ld (0x397e:16), iy
	pop xiz
	ret

VoiceSlot_Dispatch_Type81:
	ld a, 0x7f:opc
	ld (0x37c8:16), a
	ld a, 0xff:opc
	ld (0x37c7:16), a
	ld c, 0x0:opc

VoiceSlot_Dispatch_Type90:
	cp c, 7:i3
	jr z, VoiceSlot_Dispatch_D0Type
	ld xwa, 0x37ab
	ld e, 0x0:opc
	ld	(xwa+c), e
	ld xwa, 0x37b2
	ld e, 0x1:opc
	ld	(xwa+c), e
	ld xwa, 0x37b9
	ld e, 0xff:opc
	ld	(xwa+c), e
	ld xwa, 0x37c0
	ld e, 0xff:opc
	ld	(xwa+c), e
	inc 1, c
	jr VoiceSlot_Dispatch_Type90

VoiceSlot_Dispatch_D0Type:
	ld (0x37c9:16), 64
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 32
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 16
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 8
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 4
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 2
	calr RhythmDrum_LoadVoiceParams
	ld (0x37c9:16), 1
	calr RhythmDrum_LoadVoiceParams
	ret

VoiceSlot_Dispatch_Return:
	push	xiz
	call	VoiceSlot_Dispatch_D0Type_Helper
	pop	xiz
	ret
VoiceSlot_Dispatch_D0Type_Helper:
	bit	7, a
	jr	nz, VoiceSlot_Dispatch_Return_Entry
	cp	(0x34d6:16), 11
	jr	ge, VoiceSlot_Dispatch_Return_Skip
	inc	1, (0x34d6:16)
	jr	VoiceSlot_Dispatch_Return_Join
VoiceSlot_Dispatch_Return_Skip:
	ld	(0x34d6:16), 11
VoiceSlot_Dispatch_Return_Join:
	jr	VoiceSlot_Dispatch_Return_Join2
VoiceSlot_Dispatch_Return_Entry:
	cp	(0x34d6:16), 0
	jr	gt, VoiceSlot_Dispatch_Return_Skip2
	ld	(0x34d6:16), 0
	jr	VoiceSlot_Dispatch_Return_Join2
VoiceSlot_Dispatch_Return_Skip2:
	dec	1, (0x34d6:16)
VoiceSlot_Dispatch_Return_Join2:
	calr	VoiceSlot_Dispatch_Return_Helper
	calr	DrumParam_BuildActiveMask
	ret
VoiceSlot_Dispatch_Return_Helper:
	ld	xhl, 0:i3
	ld	l, (0x34d6:16)
	and	l, 31
	add	l, 128
	ld	xbc, 0xfc5a
	ld	a, 0:opc
	ld	(xbc+a), l
	ld	a, 1:opc
	ld	h, (xbc+a)
	and	h, 128
	ld	(xbc+a), h
	ld a, (64602:16)
	ld	w, 0:opc
	ld	e, 72:opc
	ld	d, 0:opc
	call	SwbtWr_QueuePostEvent
	ret

DrumParam_ProcessChannel:
	push xiz
	calr DrumParam_LookupChannelBit
	call DrumParam_ProcessChannel_Helper
	pop xiz
	ret

DrumParam_LookupChannelBit:
	push xwa
	push xix
	ld a, (0x39b8:16)
	ld xix, PatIdx_Lookup_Return
	ld	a, (xix+a)
	ld (0x37c9:16), a
	pop xix
	pop xwa
	ret

PatIdx_Lookup_Return:
	normal
	push	sr
	max
	ld	(P4:8), 32:io
	.byte 0x40

DrumParam_ProcessChannel_Helper:
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
	calr RhythmVoice_LoadParams_Helper
	calr DrumParam_BuildActiveMask
	ret

DrumParam_BuildActiveMask:
	ld w, 0x0:opc
	ld (0x37c8:16), w
	xor bc, bc
	ld w, 0x1:opc
	ld xix, 0x37ab
	ld xiy, 0x37b9

VoiceTable_InitEntry_Store:
	ld A, (xix+)
	cp A, (xiy+)
	jr z, VoiceTable_InitEntry_Return
	or (0x37c8:16), w

VoiceTable_InitEntry_Return:
	sll w, 1
	inc 1, bc
	cp bc, 7:i3
	jr lt, VoiceTable_InitEntry_Store
	xor bc, bc
	ld w, 0x1:opc
	ld xix, 0x37b2
	ld xiy, 0x37c0

MultiVoice_SetupChannel:
	ld A, (xix+)
	cp A, (xiy+)
	jr z, MultiVoice_Setup_Loop
	or (0x37c8:16), w

MultiVoice_Setup_Loop:
	sll w, 1
	inc 1, bc
	cp bc, 7:i3
	jr lt, MultiVoice_SetupChannel
	ld a, (0x34d6:16)
	cp a, (0x37c7:16)
	jr z, MultiVoice_Setup_WriteParam
	ld b, 0x7f:opc
	ld (0x37c8:16), b

MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	ld xbc, 0:i3
	ld c, (0x37c9:16)
	srl c, 1
	add xbc, MultiVoice_Setup_Done
	ld c, (xbc)
	cp c, 6:i3
	jr le, MultiVoice_Setup_NextChan
	ld c, 0x0:opc

MultiVoice_Setup_NextChan:
	push c
	ld xbc, 0:i3
	pop c
	ret

MultiVoice_Setup_Done:
; MultiVoice_Setup_Done -- NOT a code label: a 33-entry u8 table that turns a
; one-hot bit into its position.  ** RE-TYPED 2026-09-25 (lane accomp): was
; nop/normal/`push sr`/max/halt mnemonics (data-as-code).  Read by
; Rhythm_MapChannelToDrumIndex:
;     ld c,(0x37c9) / srl c,1 / add xbc, MultiVoice_Setup_Done / ld c,(xbc) /
;     cp c,6 / jr le,... / ld c,0
; so the index is (0x37c9) >> 1.  Only indices 1, 2, 4, 8, 16 and 32 are
; non-zero and they hold 1..6 (bit position + 1); every other byte is 0.
; 33 entries (0..32): the table ends where DrumParam_ReadVoiceCount begins.
; readers in v9/v10 (address from the linked ELF): Rhythm_MapChannelToDrumIndex 0xF670BF
	.byte 0x00, 0x01, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06

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
	ld xwa, 0:i3
	ld a, (xix)
	mul bc, 0xa
	add xbc, xwa
	ld xde, 0:i3
	ld xhl, 0:i3
	ld xwa, RhythmDrum_EntryCounts

VoiceAssign_ProcessRequest:
	cp hl, bc
	jr z, VoiceAssign_Process_Loop
	push xbc
	ld	c, (xwa+hl)
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
	ld xwa, 0:i3
	ld a, (xix)
	pop xde
	add xde, xwa
	sll xde, 2
	ld xwa, RhythmDrum_Entries
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
	ld xhl, 0:i3
	pop l
	calr VoiceAssign_ProcessRequest_Helper
	ret

VoiceAssign_Process_Return:
	ld (0x90f6:16), 72
	call SndParam_ApplyProgramChange_Safe
	call VoiceParam_ClampAndValidate_Tramp
	pushw hl
	calr Rhythm_MapChannelToDrumIndex
	popw hl
	ld xix, 0x38d2
	ld	(xix+c), l
	ld xix, 0x38d9
	ld	(xix+c), h
	sll l, 1
	sll hl, 1
	ld xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	add hl, 0x2
	ld xde, 0:i3
	ld	de, (xiy+hl)
	ld w, a
	and xwa, 0xff00
	sll xwa, 8
	ld xix, 0x400000
	add xix, (RHYTHM_ROM_BASE:16)
	add xix, xwa
	add xix, xde
	jr VoiceAssign_StoreFinal

VoiceAssign_StoreFinal:
	ret

VoiceAssign_ProcessRequest_Helper:
	pushw hl
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	popw hl
	ld xwa, VoiceAssign_PresetSelToCase
	ld	a, (xwa+hl)
	and xwa, 0x7
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, VoiceAssign_LoadLoopArgs
	ld xde, 0:i3
	ld de, (xbc)
	push xix
	calr RegPreset_Load_Loop
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, VoiceAssign_DispatchArgs
	ld xde, 0:i3
	ld de, (xbc)
	push xix
	calr MIDIChan_DispatchDone
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, VoiceAssign_ResolveArgs
	ld de, (xbc)
	push xix
	calr VoiceResolve_CheckAndStore
	pop xix
	pop xwa
	push xix
	calr VoiceAssign_StoreFinal_Helper
	pop xix
	ret

; VoiceAssign_ProcessRequest_Helper's tables (were one label, RegPreset_LoadVoiceData, decoded as code).  It maps
; the index in HL -- byte +2 of a RhythmDrum_Entries entry, kept across its Rhythm_MapChannelToDrumIndex call --
; through VoiceAssign_PresetSelToCase, keeps the low 3 bits as k, and passes
; word k of each table in DE: VoiceAssign_LoadLoopArgs to RegPreset_Load_Loop, VoiceAssign_DispatchArgs to
; MIDIChan_DispatchDone, VoiceAssign_ResolveArgs to VoiceResolve_CheckAndStore.
VoiceAssign_PresetSelToCase:		.byte	0, 3, 4, 7
VoiceAssign_LoadLoopArgs:	.short	0x0000, 0x040f, 0x040f, 0x000f, 0x0400, 0x040f, 0x040f, 0x040f
VoiceAssign_DispatchArgs:	.short	0x0000, 0x0431, 0x0431, 0x0031, 0x0400, 0x0431, 0x0431, 0x0431
VoiceAssign_ResolveArgs:	.short	0x0000, 0x0406, 0x0406, 0x0006, 0x0400, 0x0406, 0x0406, 0x0406
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
	ld hl, 1:i3
	cp wa, 0x400
	jr nc, RegPreset_Load_Return
	ld hl, 0:i3

RegPreset_Load_Return:
	ld xbc, 0:i3

ChanAssign_FourSlotLoop:
	cp c, 4:i3
	jr z, ChanAssign_StoreResult
	push xbc
	pushw wa
	push xbc
	calr ChanAssign_LookupEntry
	pop xbc
	calr ChanAssign_Lookup_Found
	popw wa
	pop xbc
	inc 1, wa
	inc 1, c
	jr ChanAssign_FourSlotLoop

ChanAssign_StoreResult:
	ret

ChanAssign_LookupEntry:
	ld xde, 0:i3
	ld	e, (xix+wa)
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
	cp hl, 0:i3
	jr nz, ChanAssign_Lookup
	add bc, 0x118
	jr ChanAssign_Lookup_Loop

ChanAssign_Lookup:
	add bc, 0x518

ChanAssign_Lookup_Loop:
	ld xwa, 0:i3
	ld	wa, (xix+bc)
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
	ld xwa, 0:i3
	ld	w, (xix+bc)
	and xwa, 0xff00
	sll xwa, 8
	ld xiy, 0x400000
	add xix, (RHYTHM_ROM_BASE:16)
	add xiy, xwa
	ret

DrumChannel_MapToIndexA:
	cp (0x37c9:16), 1
	jr nz, MIDIChan_Dispatch_Ch1
	ld xbc, 0:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch1:
	cp (0x37c9:16), 2
	jr nz, MIDIChan_Dispatch_Ch2
	ld xbc, 0:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch2:
	cp (0x37c9:16), 4
	jr nz, MIDIChan_Dispatch_Ch3
	ld xbc, 0:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch3:
	cp (0x37c9:16), 8
	jr nz, MIDIChan_Dispatch_Ch4
	ld xbc, 1:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch4:
	cp (0x37c9:16), 16
	jr nz, MIDIChan_Dispatch_Ch5
	ld xbc, 2:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch5:
	cp (0x37c9:16), 32
	jr nz, MIDIChan_Dispatch_Ch6
	ld xbc, 3:i3
	jr DrumChannel_MapA_NullRet

MIDIChan_Dispatch_Ch6:
	ld xbc, 4:i3

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	cp (0x37c9:16), 1
	jr nz, MIDIChan_Dispatch_Ch7
	ld xbc, 0:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch7:
	cp (0x37c9:16), 2
	jr nz, MIDIChan_Dispatch_Ch8
	ld xbc, 0:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch8:
	cp (0x37c9:16), 4
	jr nz, MIDIChan_Dispatch_Ch9
	ld xbc, 0:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch9:
	cp (0x37c9:16), 8
	jr nz, MIDIChan_Dispatch_Ch10
	ld xbc, 2:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch10:
	cp (0x37c9:16), 16
	jr nz, MIDIChan_Dispatch_Ch11
	ld xbc, 3:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch11:
	cp (0x37c9:16), 32
	jr nz, MIDIChan_Dispatch_Ch12
	ld xbc, 4:i3
	jr DrumChannel_MapB_NullRet

MIDIChan_Dispatch_Ch12:
	ld xbc, 5:i3

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
	ld xbc, 7:i3
	push xiy
	push xix
	pop xiy
	pop xix
	ldir85
	ret

VoiceResolve_CheckAndStore:
	bit 0, (0x37c9:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 1, (0x37c9:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 2, (0x37c9:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 3, (0x37c9:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	add de, 0x3d2
	ld	a, (xix+de)
	calr Rhythm_MapChannelToDrumIndex
	add xbc, VoiceResolve_SearchDone
	ld c, (xbc)
	and a, c
	cp a, c
	jr nz, VoiceResolve_Return
	ld a, 0x0:opc
	jr VoiceResolve_CheckAndStore_Join

VoiceResolve_Return:
	ld a, 0x1:opc

VoiceResolve_CheckAndStore_Join:
	jr VoiceResolve_InitSearch

Rhythm_ClearChannelDrumIndex:
	ld a, 0x0:opc

VoiceResolve_InitSearch:
	push_a
	calr Rhythm_MapChannelToDrumIndex
	pop_a
	add xbc, 0x387a
	ld (xbc), a
	ret

VoiceResolve_SearchDone:
	ld	(P2:8), 8:io
	ld	(P2:8), 16:io
	.byte 0x20

VoiceAssign_StoreFinal_Helper:
	ldw bc, 0x3d0
	ld	a, (xix+bc)
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
	ld xbc, AccTone_LookupByProgram_Table
	ld	a, (xbc+a)
	pop xbc
	ret

VoiceResolve_FindSlot_Return:
	add	a, 3
	ret

RhythmVoice_LoadParams_Helper:
	calr Rhythm_MapChannelToDrumIndex
	add xbc, 0x37ab
	ld xwa, 0:i3
	ld a, (xbc)
	sll xwa, 4
	ld xiy, AccRhythm_Ram3888_Records
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
	cp a, 0:i3
	jr nz, PartVoice_Update_Loop
	cp c, w
	jr ge, DrumParam_ClampVoiceCount
	inc 1, c
	jr DrumParam_ClampVoiceCount

PartVoice_Update_Loop:
	cp c, 0:i3
	jr z, DrumParam_ClampVoiceCount
	dec 1, c
	bit 0, (0x37c9:16)
	jr z, DrumParam_ClampVoiceCount
	cp c, 1:i3
	jr ge, DrumParam_ClampVoiceCount
	ld c, 0x1:opc

DrumParam_ClampVoiceCount:
	cp c, w
	jr gt, PartVoice_Update_Return
	cp c, 0:i3
	jr lt, PartVoice_Update_Done
	jr DrumParam_ClampVoiceCount_Join

PartVoice_Update_Return:
	ld c, w
	jr DrumParam_ClampVoiceCount_Join

PartVoice_Update_Done:
	ld c, 0x0:opc

DrumParam_ClampVoiceCount_Join:
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
	ld xwa, RhythmDrum_EntryCounts
	add xwa, xbc
	ld	w, (xwa+l)
	dec 1, w
	ret

ExtVoice_ProcessList:
	ret
CmEsyTtl_Dispatch2_Helper2:
	push	xiz
	call	ExtVoice_ProcessList_Data
	pop	xiz
	ret
ExtVoice_ProcessList_Data:
	.byte 0xf1
	calr	51716
	jr	nz, DrumParam_ReadMaxCount_Return
	or	(0x34cd:16), 128
	call	Seq_DispatcherEntry
	call	AccWrap_PlayModeStartAccPlay
DrumParam_ReadMaxCount_Return:
	ret
CmpEsy_DeliverEventAndCheck_Helper:
	push	xiz
	call	ExtVoice_ProcessList_Helper
	pop	xiz
	ret
ExtVoice_ProcessList_Helper:
	call	AccWrap_PlayModeDispatch
	calr	DrumParam_ReadMaxCount_Helper2
	call	Seq_DispatcherEntry
	pushdi_b	(14281)
	calr	DrumParam_ReadMaxCount_Helper3
	calr	DrumParam_ReadMaxCount_Helper4
	ld	(GLOBAL_ERROR_CODE:16), 0
	calr	DrumParam_ReadMaxCount_Helper5
	cp	(GLOBAL_ERROR_CODE:16), 0
	jr	z, DrumParam_ReadMaxCount_Skip
	call	AccPatch_InitCurrentSlot
	or	(0x37c8:16), 127
	jr DrumParam_ReadMaxCount_Entry
DrumParam_ReadMaxCount_Skip:
	ld	(0x37c8:16), 0
DrumParam_ReadMaxCount_Entry:
	pop	(0x37c9:16)
	or	(0x34cd:16), 128
	call	Seq_DispatcherEntry
	cp	(GLOBAL_ERROR_CODE:16), 0
	jr	nz, DrumParam_ReadMaxCount_Skip2
	call	AccWrap_PlayModeStartAccPlay
	jr	DrumParam_ReadMaxCount_Return2
DrumParam_ReadMaxCount_Skip2:
	calr	DrumParam_ReadMaxCount_Helper
DrumParam_ReadMaxCount_Return2:
	ret
DrumParam_ReadMaxCount_Helper:
	call	DrumVoice_NotifyEE
	ret
DrumParam_ReadMaxCount_Helper2:
	bit	2, (0x41e:16)
	jr	z, DrumParam_ReadMaxCount_Return3
	jr	DrumParam_ReadMaxCount_Helper2
DrumParam_ReadMaxCount_Return3:
	ret
DrumParam_ReadMaxCount_Helper3:
	ld	(0x37c9:16), 1
	calr	Rhythm_MapChannelToDrumIndex
	ld	xwa, 0x37ca
	add	xwa, xbc
	ld	a, (xwa)
	cp a, (13529:16)
	jr z, DrumParam_ReadMaxCount_Return4
	ld	(0x37c8:16), 127
	ld	(0x34d9:16), a
	calr	VoiceResolve_FindSlot_Return
	ld	(0x34d8:16), a
DrumParam_ReadMaxCount_Return4:
	ret
DrumParam_ReadMaxCount_Helper4:
	ld	(0x34d7:16), 3
	ret
DrumParam_ReadMaxCount_Helper5:
	bit	3, (0x37c8:16)
	jr	z, DrumParam_ReadMaxCount_Helper5_Skip
	ld	(0x37c9:16), 8
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 0x387a
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Helper5_Skip:
	bit	4, (0x37c8:16)
	jr	z, DrumParam_ReadMaxCount_Helper5_Skip2
	ld	(0x37c9:16), 16
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 0x387a
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip2
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Helper5_Skip2:
	bit	5, (0x37c8:16)
	jr	z, DrumParam_ReadMaxCount_Helper5_Skip3
	ld	(0x37c9:16), 32
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 0x387a
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip3
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Helper5_Skip3:
	bit	6, (0x37c8:16)
	jr	z, DrumParam_ReadMaxCount_Helper5_Skip4
	ld	(0x37c9:16), 64
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 0x387a
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip4
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Helper5_Skip4:
	bit	0, (0x37c8:16)
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip5
	bit	1, (0x37c8:16)
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip5
	bit	2, (0x37c8:16)
	jr	nz, DrumParam_ReadMaxCount_Helper5_Skip5
	jr	DrumParam_ReadMaxCount_Helper5_Return
DrumParam_ReadMaxCount_Helper5_Skip5:
	ld	(0x37c9:16), 1
	calr	AccVoice_SetupStyleSlots
	calr	828
DrumParam_ReadMaxCount_Helper5_Return:
	ret

AccVoice_SetupStyleSlots:
	calr AccVoice_SetupStyleSlots_Helper2
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
	calr AccVoice_SetupStyleSlots_Helper
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
	incw 1, (0x34d4:16)
	jr AccVoice_SetupSlots_Loop

AccVoice_SetupSlots_InitEntry:
	popw hl
	ret

Voice_ClearSlotBuffer:
	add xwa, 0x6
	ld xix, xwa
	ld xbc, 0xf9

AccVoice_SetupSlots_StoreEntry:
	cp bc, 0:i3
	jr z, AccVoice_SetupSlots_Return
	ld a, 0x0:opc
	ld (xix), a
	inc 1, xix
	dec 1, bc
	jr AccVoice_SetupSlots_StoreEntry

AccVoice_SetupSlots_Return:
	ret

AccVoice_SetupStyleSlots_Helper:
	add xwa, 0x6
	ld xbc, 0:i3
	ld c, (0x34d7:16)
	inc 1, c
	mul bc, (0x34d9:16)

AccVoice_SetupSlots_CheckType:
	cp bc, 0:i3
	jr z, AccVoice_SetupSlots_Done
	ld e, 0x81:opc
	ld (xwa), e
	inc 1, xwa
	dec 1, bc
	jr AccVoice_SetupSlots_CheckType

AccVoice_SetupSlots_Done:
	ld c, 0x83:opc
	ld (xwa), c
	ret

AccVoice_SetupStyleSlots_Helper2:
	ld xhl, 0:i3
	ld l, (0x34d6:16)
	cp l, 0x1e
	jr lt, AccVoice_SetupSlots_Write
	ld l, 0x0:opc

AccVoice_SetupSlots_Write:
	mul l, 0x60
	add hl, 0x60
	ld xix, RHYTHM_PATTERN_BUF_A
	add xix, xhl
	ret

AccVoice_SetupSlots_WriteDone:
	nop
	nop

AccPatch_ResolveEntryAddr:
	push xix
	pushw hl
	pushw hl
	ld xhl, 0:i3
	popw hl
	sll xhl, 8
	ld xwa, RHYTHM_PATTERN_BUF_B
	add xwa, xhl
	popw hl
	pop xix
	ret

AccVoice_SetupSlots_DataBlock:
	calr	Rhythm_MapChannelToDrumIndex
	add	xbc, 0x37b2
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Return
	calr	AccPatch_ResolveEntryAddr_Helper
	calr	AccPatch_ResolveEntryAddr_Helper2
	calr	AccPatch_ResolveEntryAddr_Helper3
AccPatch_ResolveEntryAddr_Return:
	ret
AccPatch_ResolveEntryAddr_Helper:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 3
	add	xbc, 0x37d1
	ld	xiy, xbc
	calr	AccVoice_SetupStyleSlots_Helper2
	push	xix
	calr	DrumChannel_MapToIndexA
	pop	xix
	sll	bc, 3
	add	bc, 24
	add	xix, xbc
	ld	xbc, 8
	ldir85
	ret
AccPatch_ResolveEntryAddr_Helper2:
	calr	AccVoice_SetupStyleSlots_Helper2
	calr	DrumChannel_MapToIndexB
	sll	bc, 1
	ld	hl, (xix+bc)
	ld (13842:16), hl
	ldw (13844:16), 6
	ret
AccPatch_ResolveEntryAddr_Helper3:
	ld	c, 0:opc
	ld	(0x38d1:16), c
	ld	c, (0x34d7:16)
	inc	1, c
AccPatch_ResolveEntryAddr_Join:
	cp c, (14545:16)
	jr le, AccPatch_ResolveEntryAddr_Skip
	push	c
	calr	AccPatch_ResolveEntryAddr_Helper4
	pop	c
	ld	a, (0x38d1:16)
	inc	1, a
	ld	(0x38d1:16), a
	jr	AccPatch_ResolveEntryAddr_Join
AccPatch_ResolveEntryAddr_Skip:
	calr	AccPatch_ResolveEntryAddr_Helper10
	ret
AccPatch_ResolveEntryAddr_Helper4:
	calr	AccPatch_ResolveEntryAddr_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ld	a, 0:opc
	ld	(0x38d0:16), a
	ld	c, (0x34d9:16)
AccPatch_ResolveEntryAddr_Join2:
	cp	(0x38d0:16), c
	jr	ge, AccPatch_ResolveEntryAddr_Return2
	push	c
	calr	AccPatch_ResolveEntryAddr_Helper6
	ld	a, (0x38d0:16)
	inc	1, a
	ld	(0x38d0:16), a
	pop	c
	jr	AccPatch_ResolveEntryAddr_Join2
AccPatch_ResolveEntryAddr_Return2:
	ret
AccPatch_ResolveEntryAddr_Helper5:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 4
	add	xbc, 0x380a
	ld	xwa, 0:i3
	ld	a, (0x38d1:16)
	sll	xwa, 2
	add	xbc, xwa
	ld	xwa, (xbc)
	ret
AccPatch_ResolveEntryAddr_Helper6:
	calr	AccPatch_ResolveEntryAddr_Sub
	cp	a, 131
	jr	nz, AccPatch_ResolveEntryAddr_Skip2
	calr	Rhythm_MapChannelToDrumIndex
	sll	bc, 2
	add	xbc, 0x3898
	ld	xwa, Rhythm_EmptyPattern
	ld	(xbc), xwa
	push	xbc
	ld	xbc, 1:i3
	calr	AccPatch_ResolveEntryAddr_Helper8
	pop	xbc
	ld	a, 129:opc
	jr	AccPatch_ResolveEntryAddr_Helper6_Join
AccPatch_ResolveEntryAddr_Skip2:
	push_a
	calr	AccPatch_ResolveEntryAddr_Helper8
	pop_a
AccPatch_ResolveEntryAddr_Helper6_Join:
	cp	a, 129
	jr	z, AccPatch_ResolveEntryAddr_Helper6_Return
	jr	AccPatch_ResolveEntryAddr_Helper6
AccPatch_ResolveEntryAddr_Helper6_Return:
	ret
; Rhythm_EmptyPattern -- an empty pattern stream (0x81, then 0xFF x4): the default every rhythm slot pointer
;          at 0x3898 + 4*drum is set to and compared with; a pointer one byte past it is put back on it.
;          Was Rhythm_EmptyPattern, decoded as `cp (xbc),l / swi 7 x3`.
Rhythm_EmptyPattern:
	.byte	0x81, 0xff, 0xff, 0xff, 0xff
AccPatch_ResolveEntryAddr_Sub:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, Rhythm_EmptyPattern
	jr	z, AccPatch_ResolveEntryAddr_Sub_Skip
	ld	a, (xwa)
	jr	AccPatch_ResolveEntryAddr_Sub_Return
AccPatch_ResolveEntryAddr_Sub_Skip:
	ld	a, 131:opc
AccPatch_ResolveEntryAddr_Sub_Return:
	ret
AccPatch_ResolveEntryAddr_Helper7:
	ld	c, 0:opc
	cp	a, 144
	jr	nz, AccPatch_ResolveEntryAddr_Skip3
	ld	c, 6:opc
	jr	AccPatch_ResolveEntryAddr_Return3
AccPatch_ResolveEntryAddr_Skip3:
	cp	a, 145
	jr	nz, AccPatch_ResolveEntryAddr_Skip4
	ld	c, 8:opc
	jr	AccPatch_ResolveEntryAddr_Return3
AccPatch_ResolveEntryAddr_Skip4:
	cp	a, 129
	jr	nz, AccPatch_ResolveEntryAddr_Skip5
	ld	c, 1:opc
	jr	AccPatch_ResolveEntryAddr_Return3
AccPatch_ResolveEntryAddr_Skip5:
	cp	a, 131
	jr	nz, AccPatch_ResolveEntryAddr_Skip6
	ld	c, 1:opc
	jr	AccPatch_ResolveEntryAddr_Return3
AccPatch_ResolveEntryAddr_Skip6:
	ld	w, a
	and	w, 208
	cp	w, 208
	jr	nz, AccPatch_ResolveEntryAddr_Skip7
	ld	c, 3:opc
	jr	AccPatch_ResolveEntryAddr_Return3
AccPatch_ResolveEntryAddr_Skip7:
	cp	c, 0:i3
	jr	nz, AccPatch_ResolveEntryAddr_Return3
	nop
AccPatch_ResolveEntryAddr_Return3:
	ret
AccPatch_ResolveEntryAddr_Helper8:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xiy, (xbc)
	ld	a, (xiy)
	ld	xbc, 0:i3
	calr	AccPatch_ResolveEntryAddr_Helper7
	ld	hl, (0x3612:16)
	pushw	bc
	calr	AccPatch_ResolveEntryAddr
	popw	bc
	ld	xix, xwa
	ld	xwa, 0:i3
	ld	wa, (0x3614:16)
	add	xix, xwa
	ldw	de, 255
	sub de, (13844:16)
	cp bc, de
	jr	gt, AccPatch_ResolveEntryAddr_Skip8
	add	(0x3614:16), bc
	cp	bc, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Helper8_Skip
	ldir85
AccPatch_ResolveEntryAddr_Helper8_Skip:
	jr	AccPatch_ResolveEntryAddr_Join3
AccPatch_ResolveEntryAddr_Skip8:
	pushw	bc
	ld	bc, de
	add	(0x3614:16), bc
	cp	bc, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Helper8_Skip2
	ldir85
AccPatch_ResolveEntryAddr_Helper8_Skip2:
	popw	bc
	push	xiy
	sub	bc, de
	ld	(0x343d:16), bc
	ld	(0x343f:16), de
	calr	AccPatch_ResolveEntryAddr_Helper9
	ld	hl, (0x3612:16)
	calr	AccPatch_ResolveEntryAddr
	ld	xix, xwa
	ld	xwa, 0:i3
	ld	wa, (0x3614:16)
	add	xix, xwa
	pop	xiy
	ld	bc, (0x343d:16)
	add	(0x3614:16), bc
	cp	bc, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Join3
	ldir85
AccPatch_ResolveEntryAddr_Join3:
	push	xiy
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	pop	xiy
	ld	(xbc), xiy
	cp	xiy, Rhythm_EmptyPattern + 1
	jr	nz, AccPatch_ResolveEntryAddr_Return4
	ld	xiy, Rhythm_EmptyPattern
	ld	(xbc), xiy
AccPatch_ResolveEntryAddr_Return4:
	ret
AccPatch_ResolveEntryAddr_Helper9:
	cpw	(0x34d4:16), 0
	jr	z, AccPatch_ResolveEntryAddr_Skip9
	ldw	hl, 150
AccPatch_ResolveEntryAddr_Join4:
	pushw	hl
	calr	AccPatch_ResolveEntryAddr
	popw	hl
	bit	7, (xwa)
	jr	z, AccPatch_ResolveEntryAddr_Helper9_Skip
	inc	1, hl
	jr	AccPatch_ResolveEntryAddr_Join4
AccPatch_ResolveEntryAddr_Helper9_Skip:
	ld	c, (xwa)
	or	c, 128
	ld	(xwa), c
	ld	de, 1:i3
	ld	bc, (0x3612:16)
	ld	(xwa+de), bc
	pushw	hl
	ld	hl, (0x3612:16)
	calr	AccPatch_ResolveEntryAddr
	ld	de, 3:i3
	popw	hl
	ld	(xwa+de), hl
	decw	1, (0x34d4:16)
	ld	(0x3612:16), hl
	ld	wa, 6:i3
	ld	(0x3614:16), wa
	jr	AccPatch_ResolveEntryAddr_Return5
AccPatch_ResolveEntryAddr_Skip9:
	ld	wa, 6:i3
	ld	(0x3614:16), wa
	ld	(GLOBAL_ERROR_CODE:16), 15
AccPatch_ResolveEntryAddr_Return5:
	ret
AccPatch_ResolveEntryAddr_Helper10:
	calr	Rhythm_MapChannelToDrumIndex
	sll	bc, 2
	add	xbc, 0x3898
	ld	xwa, AccVoice_SetupSlots_DataBlock_Code2
	ld	(xbc), xwa
	ld	c, 1:opc
	calr	AccPatch_ResolveEntryAddr_Helper8
	ret
AccVoice_SetupSlots_DataBlock_Code2:
	ld	a, (xhl)
	normal
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper
	calr	AccPatch_ResolveEntryAddr_Helper10_Helper
	calr	AccPatch_ResolveEntryAddr_Helper2
	calr	124
	ret
AccPatch_ResolveEntryAddr_Helper10_Helper:
	calr	AccVoice_SetupStyleSlots_Helper2
	ld	w, (0x34d8:16)
	ld	a, 12:opc
	ld	(xix+a), w
	ld w, (13527:16)
	ld	a, 13:opc
	ld	(xix+a), w
	ld	w, 32:opc
	ld	a, 14:opc
	ld	(xix+a), w
	ld	w, 0:opc
	ld	a, 15:opc
	ld	(xix+a), w
	ld	a, 1:opc
	ld	(0x37c9:16), a
	push	xix
	calr	Rhythm_MapChannelToDrumIndex
	pop	xix
	ld	xiy, 0x38d2
	ld	w, (xiy+c)
	ld a, 16:opc
	ld	(xix+a), w
	ld xiy, 14553
	ld	w, (xiy+c)
	ld a, 17:opc
	ld	(xix+a), w
	ld xiy, AccVoice_SetupSlots_DataBlock_Data
	add	xix, 64
	ld	xbc, 0:i3
	ldw	bc, 16
	.byte 0x85
	scf
	ret
AccVoice_SetupSlots_DataBlock_Data:
	aligned_string "Easy            #"
	ld	(0x38d1:16), c
	ld	c, (0x34d7:16)
	add	c, 1
AccPatch_ResolveEntryAddr_Join5:
	cp c, (14545:16)
	jr le, AccPatch_ResolveEntryAddr_Skip10
	push	c
	calr	AccPatch_ResolveEntryAddr_Helper11
	pop	c
	ld	a, (0x38d1:16)
	inc	1, a
	ld	(0x38d1:16), a
	jr	AccPatch_ResolveEntryAddr_Join5
AccPatch_ResolveEntryAddr_Skip10:
	calr	AccPatch_ResolveEntryAddr_Helper10
	ret
AccPatch_ResolveEntryAddr_Helper11:
	ld	a, 1:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ld	a, 2:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ld	a, 4:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 0x3898
	ld	(xbc), xwa
	ld	a, 0:opc
	ld	(0x38d0:16), a
	ld	c, (0x34d9:16)
AccPatch_ResolveEntryAddr_Join6:
	cp	(0x38d0:16), c
	jr	ge, AccPatch_ResolveEntryAddr_Return6
	push	c
	calr	AccPatch_ResolveEntryAddr_Helper12
	ld	a, (0x38d0:16)
	inc	1, a
	ld	(0x38d0:16), a
	pop	c
	jr	AccPatch_ResolveEntryAddr_Join6
AccPatch_ResolveEntryAddr_Return6:
	ret
AccPatch_ResolveEntryAddr_Helper12:
	ld	a, 1:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper13
	ld	a, 2:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper13
	ld	a, 4:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper13
	calr	AccPatch_ResolveEntryAddr_Helper17
	push	l
	calr	AccPatch_ResolveEntryAddr_Helper14
	pop	l
	cp	w, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Skip11
	calr	AccPatch_ResolveEntryAddr_Helper16
	ld	(0x37c9:16), l
	calr	AccPatch_ResolveEntryAddr_Helper8
	jrl	AccPatch_ResolveEntryAddr_Helper12
AccPatch_ResolveEntryAddr_Skip11:
	ld	a, 1:opc
	ld	(0x37c9:16), a
	ld	xbc, 0:i3
	ld	c, 1:opc
	calr	AccPatch_ResolveEntryAddr_Helper8
	ld	a, 2:opc
	ld	(0x37c9:16), a
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, Rhythm_EmptyPattern
	jr	z, AccPatch_ResolveEntryAddr_Skip12
	inc	1, xwa
	ld	(xbc), xwa
AccPatch_ResolveEntryAddr_Skip12:
	ld	a, 4:opc
	ld	(0x37c9:16), a
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	cp	xwa, Rhythm_EmptyPattern
	jr	z, AccPatch_ResolveEntryAddr_Return7
	inc	1, xwa
	ld	(xbc), xwa
AccPatch_ResolveEntryAddr_Return7:
	ret
AccPatch_ResolveEntryAddr_Helper13:
	calr	Rhythm_MapChannelToDrumIndex
	add	xbc, 0x37b2
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, AccPatch_ResolveEntryAddr_Skip14
	calr	AccPatch_ResolveEntryAddr_Helper18
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, (xbc)
	ld	l, (xwa)
	cp	l, 131
	jr	nz, AccPatch_ResolveEntryAddr_Skip13
	ld	xwa, Rhythm_EmptyPattern
	ld	(xbc), xwa
AccPatch_ResolveEntryAddr_Skip13:
	jr	AccPatch_ResolveEntryAddr_Join7
AccPatch_ResolveEntryAddr_Skip14:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xwa, Rhythm_EmptyPattern
	ld	(xbc), xwa
AccPatch_ResolveEntryAddr_Join7:
	calr	92
	ret
AccPatch_ResolveEntryAddr_Helper14:
	ld	a, 1:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper15
	cp	a, 129
	jr	nz, AccPatch_ResolveEntryAddr_Skip15
	ld	a, 2:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper15
	cp	a, 129
	jr	nz, AccPatch_ResolveEntryAddr_Skip15
	ld	a, 4:opc
	ld	(0x37c9:16), a
	calr	AccPatch_ResolveEntryAddr_Helper15
	cp	a, 129
	jr	nz, AccPatch_ResolveEntryAddr_Skip15
	ld	w, 0:opc
	jr	AccPatch_ResolveEntryAddr_Return8
AccPatch_ResolveEntryAddr_Skip15:
	ld	w, 1:opc
AccPatch_ResolveEntryAddr_Return8:
	ret
AccPatch_ResolveEntryAddr_Helper15:
	ld	xix, 0x342d
	push	xix
	calr	Rhythm_MapChannelToDrumIndex
	pop	xix
	ld	a, (xix+c)
	ret
AccPatch_ResolveEntryAddr_Helper16:
	push	l
	ld	xhl, 0:i3
	pop	l
	and	l, 7
	add	xhl, AccVoice_SetupSlots_DataBlock_Code3
	ld	l, (xhl)
	ret
AccVoice_SetupSlots_DataBlock_Code3:
	normal
	push	sr
	max
	ld	(P4:8), 32:io
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
	jr	z, AccPatch_ResolveEntryAddr_Skip17
	cp	a, 145
	jr	z, AccPatch_ResolveEntryAddr_Skip17
	ld	w, a
	and	w, 240
	cp	w, 208
	jr	z, AccPatch_ResolveEntryAddr_Skip17
	ld	(xix), a
	cp	a, 135
	jr	nz, AccPatch_ResolveEntryAddr_Skip16
	nop
AccPatch_ResolveEntryAddr_Skip16:
	jr	AccPatch_ResolveEntryAddr_Return9
AccPatch_ResolveEntryAddr_Skip17:
	ld	xwa, (xbc)
	inc	1, xwa
	ld	a, (xwa)
	ld	(xix), a
AccPatch_ResolveEntryAddr_Return9:
	ret
AccPatch_ResolveEntryAddr_Helper17:
	ld	l, 0:opc
	ld	a, 0:opc
	ld	xix, 0x342d
AccPatch_ResolveEntryAddr_Join8:
	cp	l, 2:i3
	jr	gt, AccPatch_ResolveEntryAddr_Skip19
	cp	a, 2:i3
	jr	gt, AccPatch_ResolveEntryAddr_Skip19
	ld	h, (xix+l)
	bit	7, h
	jr	z, AccPatch_ResolveEntryAddr_Helper17_Entry
	inc	1, l
	jr	AccPatch_ResolveEntryAddr_Join9
AccPatch_ResolveEntryAddr_Helper17_Entry:
	ld	w, (xix+a)
	bit	7, w
	jr	z, AccPatch_ResolveEntryAddr_Helper17_Skip
	inc	1, a
	jr	AccPatch_ResolveEntryAddr_Join9
AccPatch_ResolveEntryAddr_Helper17_Skip:
	cp	h, w
	jr	gt, AccPatch_ResolveEntryAddr_Skip18
	inc	1, a
	jr	AccPatch_ResolveEntryAddr_Join9
AccPatch_ResolveEntryAddr_Skip18:
	inc	1, l
	jr	AccPatch_ResolveEntryAddr_Join9
AccPatch_ResolveEntryAddr_Join9:
	jr	AccPatch_ResolveEntryAddr_Join8
AccPatch_ResolveEntryAddr_Skip19:
	cp	l, 2:i3
	jr	le, AccPatch_ResolveEntryAddr_Return10
	ld	l, 0:opc
AccPatch_ResolveEntryAddr_Return10:
	ret
AccPatch_ResolveEntryAddr_Helper18:
	calr	Rhythm_MapChannelToDrumIndex
	ld	ix, bc
	sll	xbc, 2
	add	xbc, 0x3898
AccPatch_ResolveEntryAddr_Helper18_Join:
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	jr	z, AccPatch_ResolveEntryAddr_Skip20
	cp	a, 145
	jr	z, AccPatch_ResolveEntryAddr_Skip20
	ld	e, a
	and	a, 240
	cp	a, 208
	jr	z, AccPatch_ResolveEntryAddr_Skip20
	jr	AccPatch_ResolveEntryAddr_Return11
AccPatch_ResolveEntryAddr_Skip20:
	ld	xwa, (xbc)
	inc	2, xwa
	ld	a, (xwa)
	calr	AccPatch_ResolveEntryAddr_Helper19
	cp	c, (14281:16)
	jr	z, AccPatch_ResolveEntryAddr_Return11
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 0x3898
	ld	xix, (xbc)
	push	xbc
	calr	AccPatch_ResolveEntryAddr_Helper18_Helper
	pop	xbc
	ld	(xbc), xix
	jr	AccPatch_ResolveEntryAddr_Helper18_Join
AccPatch_ResolveEntryAddr_Return11:
	ret
AccPatch_ResolveEntryAddr_Helper19:
	push_a
	calr	Rhythm_MapChannelToDrumIndex
	ld	xwa, 0x3881
	ld	e, (xwa+bc)
	push	e
	ld	xde, 0:i3
	pop	e
	sll	de, 7
	add	xde, AccVoice_SlotRows
	pop_a
	ld	c, (xde+a)
	ret
AccPatch_ResolveEntryAddr_Helper18_Helper:
	ld	a, (xix)
	calr	AccPatch_ResolveEntryAddr_Helper7
	push	c
	ld	xbc, 0:i3
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
	ld (0x37c9:16), 16
	bit 0, (0x379b:16)
	jr nz, CmpMode_NullRet
	ld (0x37c9:16), 32
	bit 1, (0x379b:16)
	jr nz, CmpMode_NullRet
	ld (0x37c9:16), 64
	bit 2, (0x379b:16)
	jr nz, CmpMode_NullRet
	ld (0x37c9:16), 8
	bit 3, (0x379b:16)
	jr nz, CmpMode_NullRet
	ld (0x37c9:16), 1

CmpMode_NullRet:
	ret

CmpMode_NullRet_Code:
	push	xiz
	call	CmpMode_NullRet_Helper
	pop	xiz
	ret
CmpMode_NullRet_Helper:
	ld	e, (0x37c9:16)
	and	e, 1
	cp	e, 1:i3
	jr	z, VoiceSlot_Init_Process_Skip
	ld	e, (0x37c9:16)
	and	e, 2
	cp	e, 2:i3
	jr	z, VoiceSlot_Init_Process_Skip2
	ld	e, (0x37c9:16)
	and	e, 4
	cp	e, 4:i3
	jr	z, VoiceSlot_Init_Process_Skip
	ld	e, (0x37c9:16)
	and	e, 8
	cp	e, 8
	jr	z, VoiceSlot_Init_Process_Skip3
	ld	e, (0x37c9:16)
	and	e, 16
	cp	e, 16
	jr	z, VoiceSlot_Init_Process_Skip4
	ld	e, (0x37c9:16)
	and	e, 32
	cp	e, 32
	jr	z, VoiceSlot_Init_Process_Skip5
	ld	e, (0x37c9:16)
	and	e, 64
	cp	e, 64
	jr	z, VoiceSlot_Init_Process_Skip6
VoiceSlot_Init_Process_Skip:
	ld	(0x39b8:16), 0
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip2:
	ld	(0x39b8:16), 1
	jr	VoiceSlot_Init_Process_Return
	ld	(0x39b8:16), 2
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip3:
	ld	(0x39b8:16), 3
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip4:
	ld	(0x39b8:16), 4
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip5:
	ld	(0x39b8:16), 5
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip6:
	ld	(0x39b8:16), 6
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Return:
	ret
; CmpMenuTtlFunc setup
CmpMenuTtl_Setup:
CmpModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
	ld xhl, 0:i3
	ret
; CmpMenuTtlFunc main handler
CmpMenuTtl_MainHandler:
CmpMenuTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, CmpMenuTtl_SpecialKeys
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, CmpMenuTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, CmpMenuTtl_ReturnZero
	cp xde, 0x6
	jr ugt, CmpMenuTtl_ReturnZero
	add xde, xde
	add xde, CmpMenuTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpMenuTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpMenuTtlFunc title dispatch
CmpMenuTtl_Dispatch:
	set	2, (0x28a7:16)
	call	AccWrap_PlayModeDispatch
	jr	t, CmpMenuTtl_ReturnZero

; CmpMenuTtl special key handler (0x88-0x8a)
CmpMenuTtl_SpecialKeys:
	ld a, (0x34cd:16)
	cp xde, 0x8a
	jr z, CmpMenuTtl_SetBit4
	cp xde, 0x89
	jr z, CmpMenuTtl_SetBit5
	cp xde, 0x88
	jr nz, CmpMenuTtl_ReturnZero
	and (0x34cd:16), 207
	ldw wa, 0xb1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 5
CmpMenuTtl_SetBit5:
	and a, 0xcf
	set 5, a
	ld (0x34cd:16), a
	ldw wa, 0xb1
	jr CmpMenuTtl_PostModeEvent

; CmpMenuTtl set mode bit 4
CmpMenuTtl_SetBit4:
	and a, 0xcf
	set 4, a
	ld (0x34cd:16), a
	ldw wa, 0xb1

; CmpMenuTtl post mode change event
CmpMenuTtl_PostModeEvent:
	call UI_PostModeChangeEvent

CmpMenuTtl_ReturnZero:
	ld xhl, 0:i3
	ret
; CmpSetTtlFunc main handler
CmpSetTtl_MainHandler:
CmpSetTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, CmpSetTtl_ModeSwitch
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CmpReal_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpReal_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpReal_ReturnZero
	add xde, xde
	add xde, CmpSetTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpSetTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpSetTtlFunc title dispatch
CmpSetTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 180
	jrl	z, CmpReal_ReturnZero
	call	CmpSetTtl_Dispatch_Helper
	ld	xwa, 0xb40007
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 0xffff0001
	call	ApDeliveryEvent
	jrl	CmpReal_ReturnZero
	cp	(CURRENT_TITLE:16), 180
	jrl	z, CmpReal_ReturnZero
	call	RhythmConfig_InlineCode2
	jrl	CmpReal_ReturnZero

; CmpSetTtl mode switch (5-way branch)
CmpSetTtl_ModeSwitch:
	cp (0x350c:16), 0
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
	ld w, 0x0:opc
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
	ld w, 0x80:opc
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
	ld w, 0x0:opc
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
	ld w, 0x80:opc
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
	add xde, CmpSetTtl_DynamicLookup_CaseTable
	ld de, (xde)
	lda xix, (CmpSetTtl_Dispatch2:24)
	jp	t, (xix+de)
; CmpSetTtlFunc title dispatch 2
CmpSetTtl_Dispatch2:
	.asciz ":;<> "
	call	CmpSetTtl_Dispatch2_Helper
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
	call 16146861
	.ascii "^\\[Zh"
	ret
	.ascii ":;<> "
	.byte 0x80, 0x1d, 0xad
	jr	lt, 0xf6
	.ascii "^\\[Z"

CmpReal_ReturnZero:
	ld xhl, 0:i3
	ret
; CmpRealTtlFunc entry
CmpRealTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, CmpRealTtl_MajorDispatch
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CmpBk_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBk_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBk_ReturnZero
	add xde, xde
	add xde, CmpRealTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpRealTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpRealTtlFunc title dispatch
CmpRealTtl_Dispatch:
	.ascii ":;<>"
	call	RhythmFillIn_PatternTable_Sub
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SoundCtrl_SendTempoScaled
	jrl	CmpBk_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmFillIn_PatternTable_Sub
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
	add xwa, CmpRealTtl_MajorDispatch_CaseTable
	ld wa, (xwa)
	lda xix, (CmpRealTtl_RhythmVar0:24)
	jp	t, (xix+wa)

; CmpRealTtl rhythm variation 0
CmpRealTtl_RhythmVar0:
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 0:i3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 1
CmpRealTtl_RhythmVar1:
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 1:i3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 2
CmpRealTtl_RhythmVar2:
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 2:i3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 3
CmpRealTtl_RhythmVar3:
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 3:i3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jrl CmpBk_DeliverEvent

; CmpRealTtl rhythm variation 4
CmpRealTtl_RhythmVar4:
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 4:i3
	call RhythmVariation_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0xb50019
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jr CmpBk_DeliverEvent
	set 1, (0x34cf:16)
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
	ld xbc, EVT_PAINT
	ld xde, 0:i3
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
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001b
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb50018
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb5001c
	ld xbc, EVT_PAINT
	ld xde, 0:i3

CmpBk_DeliverEvent:
	call ApDeliveryEvent

CmpBk_ReturnZero:
	ld xhl, 0:i3
	ret
; CmpOffsetFunc dispatch
CmpOffset_Dispatch:
CmpBkslTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, CmpBkslTtl_Mode1
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CmpBksl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmpBksl_ReturnZero
	cp xde, 0x6
	jrl ugt, CmpBksl_ReturnZero
	add xde, xde
	add xde, CmpBkslTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpBkslTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpBkslTtlFunc title dispatch
CmpBkslTtl_Dispatch:
	.ascii ":;<>"
	call	CmpBkslTtl_Dispatch_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	CmpBksl_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CmpBkslTtl_Dispatch_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	CmpBksl_ReturnZero
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
	ld hl, 1:i3
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
	ld hl, 0:i3
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
	ld hl, 3:i3
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
	ld hl, 2:i3
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
	ld hl, 5:i3
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
	ld hl, 4:i3
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
	ld hl, 7:i3
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
	ld hl, 6:i3
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
	ld xhl, 0:i3
	ret
; CmpBksl_STtlFunc main handler
CmpBkslSTtl_MainHandler:
CmpBksl_STtlFunc:
	cp xbc, EVT_SW_IN
	jr z, CmpBkslSTtl_DirectMode
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, DisplayFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DisplayFunc_ReturnZero
	cp xde, 0x6
	jrl ugt, DisplayFunc_ReturnZero
	add xde, xde
	add xde, CmpBksl_STtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpBkslSTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpBksl_STtlFunc title dispatch
CmpBkslSTtl_Dispatch:
	.ascii ":;<>"
	call	RhythmPatInit_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(GLOBAL_ERROR_CODE:16), 0
	jrl	DisplayFunc_ReturnZero
	ld	(0x350c:16), 0
	jrl	DisplayFunc_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmPatInit_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	t, DisplayFunc_ReturnZero

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
	add xwa, CmpBkslSTtl_DirectMode_CaseTable
	ld wa, (xwa)
	lda xix, (CmpBkslSTtl_FillIn4:24)
	jp	t, (xix+wa)

; CmpBkslSTtl fill-in level 4
CmpBkslSTtl_FillIn4:
	cp (0x350c:16), 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 4:i3
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 5
CmpBkslSTtl_FillIn5:
	cp (0x350c:16), 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 5:i3
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 6
CmpBkslSTtl_FillIn6:
	cp (0x350c:16), 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 6:i3
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb5
	jrl CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 7
CmpBkslSTtl_FillIn7:
	cp (0x350c:16), 0
	jrl nz, DisplayFunc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	ld hl, 7:i3
	call RhythmFillIn_Wrapper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0xb5
	jr CmpBk_PostModeChange

; CmpBkslSTtl fill-in level 8
CmpBkslSTtl_FillIn8:
	cp (0x350c:16), 0
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
	cp (0x350c:16), 0
	jr nz, DisplayFunc_ReturnZero
	cp (0x0340ea:24), 0x00
	jr nz, CmpBkslSTtl_EventPost
	set 2, (0x34cd:16)
	ld (GLOBAL_ERROR_CODE:16), 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr DisplayFunc_ReturnZero

; CmpBkslSTtl post accompaniment event
CmpBkslSTtl_EventPost:
	ld (0x350c:16), 1
	ld xwa, 0xb20012
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call ApPostEvent
	jr DisplayFunc_ReturnZero
	cp (0x350c:16), 0
	jr nz, DisplayFunc_ReturnZero
	cp (0x34d6:16), 12
	jr nc, DisplayFunc_ReturnZero
	ldw wa, 0xb3
	jr CmpBk_PostModeChange
	cp (0x350c:16), 0
	jr nz, DisplayFunc_ReturnZero
	ldw wa, 0xb4

CmpBk_PostModeChange:
	call UI_PostModeChangeEvent

DisplayFunc_ReturnZero:
	ld xhl, 0:i3
	ret
; CmpNcpTtlFunc main handler
CmpNcpTtl_MainHandler:
CmpNcpTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, CmpNcpTtl_SpecialMode7
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CmEsy_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CmEsy_ReturnZero
	cp xde, 0x6
	jrl ugt, CmEsy_ReturnZero
	add xde, xde
	add xde, CmpNcpTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmpNcpTtl_Dispatch:24)
	jp	t, (xix+de)
; CmpNcpTtlFunc title dispatch
CmpNcpTtl_Dispatch:
	.ascii ":;<>"
	call	CmpNcpTtl_Dispatch_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (0x3a80:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	jr	CmpNcpTtl_Dispatch_Code_Join
CmpNcpTtl_Dispatch_Code_Skip:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
	jr	CmpNcpTtl_Dispatch_Code_Join
	ld	wa, 0:i3
	call	UI_PostDialEnable
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumVoice_Handler7_Data_2_Sub
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	CmEsy_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CmpNcpTtl_Dispatch_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (0x3a80:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip12
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	jr	CmpNcpTtl_Dispatch_Code_Join
CmpNcpTtl_Dispatch_Code_Skip12:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
CmpNcpTtl_Dispatch_Code_Join:
	call	UI_PostDialRangeEvent
	jrl	CmEsy_ReturnZero

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
	add xde, CmpNcpTtl_TableDispatch_CaseTable
	ld de, (xde)
	lda xix, (CmpNcpTtl_Dispatch2:24)
	jp	t, (xix+de)
; CmpNcpTtlFunc title dispatch 2
CmpNcpTtl_Dispatch2:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	CmpNcpTtl_Dispatch2_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 0
	jr	z, CmpNcpTtl_Dispatch_Code_Skip2
	ld	(0x3a80:16), 0
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip2:
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	CmpNcpTtl_Dispatch2_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 0
	jr	z, CmpNcpTtl_Dispatch_Code_Skip3
	ld	(0x3a80:16), 0
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip3:
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	CmpNcpTtl_Dispatch2_Helper2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 0
	jr	z, CmpNcpTtl_Dispatch_Code_Skip4
	ld	(0x3a80:16), 0
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip4:
	ld	a, (0x39a7:16)
	cp	a, 2:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip6
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip5
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip5:
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip6:
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	CmpNcpTtl_Dispatch2_Helper2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 0
	jr	z, CmpNcpTtl_Dispatch_Code_Skip7
	ld	(0x3a80:16), 0
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip7:
	ld	a, (0x39a7:16)
	cp	a, 2:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip9
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip8
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip8:
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip9:
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	DrumVoice_Handler7_Data_3_Sub
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 1
	jr	z, CmpNcpTtl_Dispatch_Code_Skip13
	ld	(0x3a80:16), 1
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip13:
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	.ascii ":;<> €"
	call	DrumVoice_Handler7_Data_3_Sub
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 1
	jr	z, CmpNcpTtl_Dispatch_Code_Skip14
	ld	(0x3a80:16), 1
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip14:
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	CmpNcpTtl_Dispatch2_Helper3
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 1
	jr	z, CmpNcpTtl_Dispatch_Code_Skip15
	ld	(0x3a80:16), 1
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip15:
	ld	a, (0x39a8:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip10
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip10:
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	CmpNcpTtl_Dispatch2_Helper3
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(0x3a80:16), 1
	jr	z, CmpNcpTtl_Dispatch_Code_Skip16
	ld	(0x3a80:16), 1
	ld	xwa, 0xb8001e
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip16:
	ld	a, (0x39a8:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip11
	cp	a, 0:i3
	jr	nz, CmEsy_ReturnZero
	ld	xwa, 0xb8001a
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jr	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip11:
	ld	xwa, 0xb8001b
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb80012
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
CmpNcpTtl_Dispatch_Code_Join2:
	call	ApDeliveryEvent
	jr	CmEsy_ReturnZero
	.byte 0xf1, 0xd1, 0x34, 0xb8

CmEsy_ReturnZero:
	ld xhl, 0:i3
	ret
; CmEsyTtlFunc main handler
CmpEsyTtl_MainHandler:
CmEsyTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, CmpEsyTtl_Mode1
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, S2cTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, S2cTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, S2cTtl_ReturnZero
	add xde, xde
	add xde, CmEsyTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CmEsyTtl_Dispatch:24)
	jp	t, (xix+de)
; CmEsyTtlFunc title dispatch
CmEsyTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 186
	jrl	z, S2cTtl_ReturnZero
	ld	a, (0x34d6:16)
	cp	a, 29
	jr	ule, CmEsyTtlFunc_Skip
	sub	a, 30
	sll	a, 2
	ld	(0x34d6:16), a
CmEsyTtlFunc_Skip:
	or	(0x37c8:16), 127
	res	2, (0x28a7:16)
	res	6, (0x34cd:16)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumKit_InlineCode1_Sub
	call	CmEsyTtl_Dispatch_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(0x34f1:16), 0
	ld	xwa, 0xba000a
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 0xffff0002
	jrl	CmpEsy_DeliverEventAndCheck
	cp	(0x37b9:16), 255
	jrl	z, S2cTtl_ReturnZero
	lda	xiy, (0x37b9:16)
	lda	xix, (0x37ab:16)
	lda	xhl, (0x37c0:16)
	lda	xde, (0x37b2:16)
	ld	xbc, 0:i3
CmEsyTtlFunc_Loop:
	ld	a, (xiy+)
	ld	(xix+), a
	ld	a, (xhl+)
	ld	(xde+), a
	inc	1, xbc
	cp	xbc, 7
	jr	c, CmEsyTtlFunc_Loop
	ldmm8	13526, 14279
	jrl	S2cTtl_ReturnZero

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
	add xde, CmpEsyTtl_Mode2_Table
	ld de, (xde)
	extz de
	sll de, 1
	ld xix, CmpEsyTtl_Mode2_CaseTable
	ld	de, (xix+de)
	lda xix, (CmEsyTtl_Dispatch2:24)
	jp	t, (xix+de)
; CmEsyTtlFunc title dispatch 2
CmEsyTtl_Dispatch2:
	; --- Multi-branch dispatch subroutine (195 bytes) ---
	ld	wa, 0:i3
	jrl t, CmpEsyTtl_SubModeD_Cont
	push xde
	push xhl
	push xix
	push xiz
	call CmEsyTtl_Dispatch2_Helper2
	call CmEsyTtl_Dispatch2_Helper
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw wa, 0x00b5
	call UI_PostModeChangeEvent
	jrl t, S2cTtl_ReturnZero
	ld	wa, 1:i3
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x00:opc
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00ba0009
	ld xbc, EVT_PAINT
	ld	xde, 0:i3
	jr t, CmpEsy_DeliverEventAndCheck
	ld	wa, 1:i3
	call UI_PostEvent_0x6E
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x80:opc
	call VoiceSlot_Dispatch_Return
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld xwa, 0x00ba0009
	ld xbc, EVT_PAINT
	ld	xde, 0:i3
CmpEsy_DeliverEventAndCheck:
	call ApDeliveryEvent
	jr t, S2cTtl_ReturnZero
	cp	(0x37c8:16), 0
	jr z, CmpEsyTtl_SubModeC
	push xde
	push xhl
	push xix
	push xiz
	call CmpEsy_DeliverEventAndCheck_Helper
	pop xiz
	pop xix
	pop xhl
	pop xde
	cp	(GLOBAL_ERROR_CODE:16), 0
	jr nz, CmpEsyTtl_SubModeD
	lda	xiy, (0x37ab:16)
	lda	xix, (0x37b9:16)
	lda	xhl, (0x37b2:16)
	lda	xde, (0x37c0:16)
	ld	xbc, 0:i3
; CmpEsyTtl sub-mode B
CmpEsyTtl_SubModeB:
	ld	a, (xiy+)
	ld	(xix+), a
	ld	a, (xhl+)
	ld	(xde+), a
	inc 1, xbc
	cp xbc, 0x00000007
	jr c, CmpEsyTtl_SubModeB
	ldmm8	14279, 13526
	jr t, CmpEsyTtl_SubModeD
; CmpEsyTtl sub-mode C
CmpEsyTtl_SubModeC:
	push xde
	push xhl
	push xix
	push xiz
	call CmEsyTtl_Dispatch2_Helper2
	pop xiz
	pop xix
	pop xhl
	pop xde
; CmpEsyTtl sub-mode D entry
CmpEsyTtl_SubModeD:
	ld	wa, 0:i3
; CmpEsyTtl sub-mode D continuation
CmpEsyTtl_SubModeD_Cont:
	call UI_PostDialEnable


S2cTtl_ReturnZero:
	ld xhl, 0:i3
	ret
; CmpEsyTtl sub-mode E dispatch
CmpEsyTtl_SubModeE:
S2cTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, CmpEsyTtl_E_Var1
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CstmCp_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero
	add xde, xde
	add xde, S2cTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (S2cTtl_Dispatch:24)
	jp	t, (xix+de)
; S2cTtlFunc title dispatch
S2cTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 185
	jr	z, S2cTtlFunc_Skip
	ld	xwa, 0xb90021
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 0xffff0002
	call	ApDeliveryEvent
S2cTtlFunc_Skip:
	call	S2cTtl_InitOnTitleChange
	jrl	CstmCp_ReturnZero
	ld	a, (0x3a77:16)
	cp	a, 2:i3
	jr	z, S2cTtlFunc_Skip3
	cp	a, 1:i3
	jr	z, S2cTtlFunc_Skip2
	cp	a, 0:i3
	jrl	nz, CstmCp_ReturnZero
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 0:i3
	call	UI_PostDialValueEvent
	ldw	wa, 128
	jr	S2cTtlFunc_Join
S2cTtlFunc_Skip2:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 1:i3
	call	UI_PostDialValueEvent
	ldw	wa, 129
	jr	S2cTtlFunc_Join
S2cTtlFunc_Skip3:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
S2cTtlFunc_Join:
	call	UI_PostDialRangeEvent
	jrl	CstmCp_ReturnZero

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
	add xwa, CmpEsyTtl_E_Var1_CaseTable
	ld wa, (xwa)
	lda xix, (CmpEsy_E_DispatchDataBlock:24)
	jp	t, (xix+wa)

CmpEsy_E_DispatchDataBlock:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 0:i3
	call	UI_PostDialValueEvent
	ldw	wa, 128
	call	UI_PostDialRangeEvent
	ld	wa, 0:i3
	call	Tempo_AdjustStartMeasure
	cp	(0x3a77:16), 0
	jr	nz, S2cTtlFunc_Skip4
	ld	xwa, 0xb9001c
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb9001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn
S2cTtlFunc_Skip4:
	ld	(0x3a77:16), 0
	ld	xwa, 0xb9001c
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb9001f
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb90018
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xb90021
	ld	xbc, EVT_CLR_GRID_HANTEN
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn

; CmpEsyTtl E variant 2
CmpEsyTtl_E_Var2:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 0:i3
	call UI_PostDialValueEvent
	ldw wa, 0x80
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustStartMeasure
	cp (0x3a77:16), 0
	jr nz, CmpEsy_E_Var2_StoreMeasure
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_Var2_StoreMeasure:
	ld (0x3a77:16), 0
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 1:i3
	call UI_PostDialValueEvent
	ldw wa, 0x81
	call UI_PostDialRangeEvent
	ld wa, 0:i3
	call Tempo_AdjustEndMeasure
	cp (0x3a77:16), 1
	jr nz, CmpEsy_E_EndMeasure_Store
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

CmpEsy_E_EndMeasure_Store:
	ld (0x3a77:16), 1
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

; S2cTtlFunc main handler
S2cTtl_MainHandler:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 1:i3
	call UI_PostDialValueEvent
	ldw wa, 0x81
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustEndMeasure
	cp (0x3a77:16), 1
	jr nz, CmpEsy_Main_EndMeasure_Store
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Main_EndMeasure_Store:
	ld (0x3a77:16), 1
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 2:i3
	call UI_PostDialValueEvent
	ldw wa, 0x82
	call UI_PostDialRangeEvent
	ld wa, 0:i3
	call Tempo_AdjustQuantize
	cp (0x3a77:16), 2
	jr nz, CmpEsy_Quantize_Store
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

CmpEsy_Quantize_Store:
	ld (0x3a77:16), 2
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl TtlFunc_SendEventAndReturn

; S2cTtlFunc secondary handler
S2cTtl_SecondaryHandler:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 2:i3
	call UI_PostDialValueEvent
	ldw wa, 0x82
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustQuantize
	cp (0x3a77:16), 2
	jr nz, CmpEsy_SecQuantize_Store
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jr TtlFunc_SendEventAndReturn

CmpEsy_SecQuantize_Store:
	ld (0x3a77:16), 2
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90021
	ld xbc, EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jr TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 0:i3
	call Tempo_IncrementTimeSigNum
	ld xwa, 0xb9001e
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jr TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 0:i3
	call Tempo_DecrementTimeSigNum
	ld xwa, 0xb9001e
	ld xbc, EVT_REPAINT
	ld xde, 0:i3

TtlFunc_SendEventAndReturn:
	call ApDeliveryEvent
	jr CstmCp_ReturnZero
	ld wa, 0:i3
	call Tempo_EditBPM

CstmCp_ReturnZero:
	ld xhl, 0:i3
	ret
; CstmCpTtl record dispatch
CstmCpTtl_RecDispatch:
CstmCpTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, CstmCpTtl_RecMode1
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, CstmCp_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CstmCp_ReturnZero2
	cp xde, 0x6
	jrl ugt, CstmCp_ReturnZero2
	add xde, xde
	add xde, CstmCpTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (CstmCpTtl_Dispatch:24)
	jp	t, (xix+de)
; CstmCpTtlFunc title dispatch
CstmCpTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 190
	jr	z, CstmCpTtlFunc_Skip
	ld	(0x3a7e:16), 0
	jrl	CstmCp_ReturnZero2
CstmCpTtlFunc_Skip:
	cp	(ACTIVE_TITLE_PREVIOUS:16), 238
	jrl	nz, CstmCp_ReturnZero2
	ld	a, (0x3a7e:16)
	cp	a, 2:i3
	jr	z, CstmCpTtlFunc_Skip2
	cp	a, 1:i3
	jrl	nz, CstmCp_ReturnZero2
CstmCpTtlFunc_Skip2:
	cp	(0x39b6:16), 3
	jr	nc, CstmCpTtlFunc_Skip3
	ld	xwa, 0xbe0011
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	jrl	CstmCpTtlFunc_Join2
CstmCpTtlFunc_Skip3:
	ld	xwa, 0xbe0019
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	jrl	CstmCpTtlFunc_Join2
	ld	a, (0x3a7e:16)
	cp	a, 2:i3
	jr	z, CstmCpTtlFunc_Skip4
	cp	a, 1:i3
	jrl	nz, CstmCp_ReturnZero2
CstmCpTtlFunc_Skip4:
	cp	(0x39b6:16), 3
	jr	nc, CstmCpTtlFunc_Skip5
	ld	xwa, 0xbe0011
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	jrl	CstmCpTtlFunc_Join2
CstmCpTtlFunc_Skip5:
	ld	xwa, 0xbe0019
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	jrl	t, CstmCpTtlFunc_Join2

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
	add xde, CstmCpTtl_RecMode2_CaseTable
	ld de, (xde)
	lda xix, (CstmCpTtl_Dispatch2:24)
	jp	t, (xix+de)
; CstmCpTtlFunc title dispatch 2
CstmCpTtl_Dispatch2:
	cp	(0x3a7e:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 29:opc
	ld	a, (0x39b6:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip6
	ld	c, 2:opc
CstmCpTtlFunc_Skip6:
	cp	a, c
	jrl	nc, CstmCp_ReturnZero2
	inc	1, a
	ld	(0x39b6:16), a
	ld	xwa, 0xbe0003
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x3a7e:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 10:opc
	ld	a, (0x39b6:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip7
	ld	c, 0:opc
CstmCpTtlFunc_Skip7:
	cp	a, c
	jrl	ule, CstmCp_ReturnZero2
	dec	1, a
	ld	(0x39b6:16), a
	ld	xwa, 0xbe0003
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x3a7e:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	a, (0x39b6:16)
	ld	c, (0x39b7:16)
	ld	(0x39b6:16), c
	ld	(0x39b7:16), a
	ld	xwa, 0xbe0003
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000b
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000d
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000e
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe0004
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x3a7e:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 29:opc
	ld	a, (0x39b7:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip8
	ld	c, 2:opc
CstmCpTtlFunc_Skip8:
	cp	a, c
	jrl	nc, CstmCp_ReturnZero2
	inc	1, a
	ld	(0x39b7:16), a
	ld	xwa, 0xbe000b
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jr	CstmCpTtlFunc_Join
	cp	(0x3a7e:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 10:opc
	ld	a, (0x39b7:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip9
	ld	c, 0:opc
CstmCpTtlFunc_Skip9:
	cp	a, c
	jrl	ule, CstmCp_ReturnZero2
	dec	1, a
	ld	(0x39b7:16), a
	ld	xwa, 0xbe000b
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 0xbe000f
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
CstmCpTtlFunc_Join:
	call	ApDeliveryEvent
	jrl	CstmCp_ReturnZero2
	ld	a, (0x3a7e:16)
	cp	a, 2:i3
	jr	z, CstmCpTtlFunc_Skip10
	cp	a, 1:i3
	jrl	nz, CstmCp_ReturnZero2
CstmCpTtlFunc_Skip10:
	ld	wa, 0:i3
	call	CstmCpTtl_Dispatch2_Helper
	cp	l, 1:i3
	jrl	z, CstmCp_ReturnZero2
	cp	l, 0:i3
	jrl	nz, CstmCp_ReturnZero2
	ld	(0x3a7e:16), 0
	ld	xwa, 0xffffffff
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(GLOBAL_ERROR_CODE:16), 35
	ldw	wa, 238
	jrl	CstmCpTtlFunc_Join3
	ld	a, (0x3a7e:16)
	cp	a, 2:i3
	jrl	z, CstmCpTtlFunc_Skip15
	cp	a, 1:i3
	jr	z, CstmCpTtlFunc_Skip15
	cp	a, 0:i3
	jrl	nz, CstmCp_ReturnZero2
	cp	(0x39b6:16), 3
	jr	nc, CstmCpTtlFunc_Skip11
	ld	(GLOBAL_ERROR_CODE:16), 37
	ldw	wa, 238
	call	SoundCtrl_SendCommand
CstmCpTtlFunc_Skip11:
	ld	a, (0x39b6:16)
	extz	wa
	ld	c, (0x39b7:16)
	extz	bc
	call	Flash_InitBytecodeBlock
	cp	l, 2:i3
	jr	z, CstmCpTtlFunc_Skip13
	cp	l, 1:i3
	jr	z, CstmCpTtlFunc_Skip12
	cp	l, 0:i3
	jr	nz, CstmCp_ReturnZero2
	ld	(GLOBAL_ERROR_CODE:16), 35
	ldw	wa, 238
	jr	CstmCpTtlFunc_Join3
CstmCpTtlFunc_Skip12:
	ld	(GLOBAL_ERROR_CODE:16), 15
	ldw	wa, 238
	jr	CstmCpTtlFunc_Join3
CstmCpTtlFunc_Skip13:
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_EXIT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(0x39b6:16), 3
	jr	nc, CstmCpTtlFunc_Skip14
	ld	(0x3a7e:16), 1
	jr	CstmCp_ReturnZero2
CstmCpTtlFunc_Skip14:
	ld	(0x3a7e:16), 2
	ld	xwa, 0xbe0019
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
CstmCpTtlFunc_Join2:
	call	ApPostEvent
	jr	CstmCp_ReturnZero2
CstmCpTtlFunc_Skip15:
	ld	wa, 2:i3
	call	CstmCpTtl_Dispatch2_Helper
	cp	l, 1:i3
	jr	z, CstmCp_ReturnZero2
	cp	l, 0:i3
	jr	nz, CstmCp_ReturnZero2
	ld	(0x3a7e:16), 0
	ld	xwa, 0xffffffff
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(GLOBAL_ERROR_CODE:16), 35
	ldw	wa, 238
CstmCpTtlFunc_Join3:
	call	SoundCtrl_SendCommand

CstmCp_ReturnZero2:
	ld xhl, 0:i3
	ret

CstmCp_StyleDataBlock:
	cp	xbc, EVT_CSTM_CP_OK
	jr	nz, CstmCpTtlFunc_Skip16
	ld	a, (0x39b6:16)
	extz	wa
	ld	c, (0x39b7:16)
	extz	bc
	call	Flash_InitBytecodeBlock
	cp	l, 2:i3
	jr	z, CstmCpTtlFunc_Skip16
	cp	l, 1:i3
	jr	z, CstmCpTtlFunc_Skip16
	cp	l, 0:i3
	jr	nz, CstmCpTtlFunc_Skip16
	ld	(GLOBAL_ERROR_CODE:16), 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand
CstmCpTtlFunc_Skip16:
	ld	xhl, 0:i3
	ret

MainCstmNameFunc:
	lda xsp, (xsp - 120)
	push xiz
	ld xde, xbc
	ld xiy, MainCstmNameFunc_LocalInit
	lda xix, (xsp + 4)
	ldw bc, 0x3c
	ldirw
	cp xde, EVT_CSTM_T_NM_GET
	jr z, CstmName_HandleEvent2C
	cp xde, EVT_CSTM_F_NM_GET
	jrl nz, CstmName_ReturnZero
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ld a, (0x39b6:16)
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld	xwa, (xbc+wa)
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
	ld xbc, EVT_CSTM_F_NM_DISP
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz
	jr CstmName_PostEventAndReturn

CstmName_HandleEvent2C:
	pushw 0x11
	call Malloc
	ld xiz, xhl
	ld a, (0x39b7:16)
	extz wa
	sla wa, 2
	lda xbc, (xsp + 6)
	ld	xwa, (xbc+wa)
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
	ld xbc, EVT_CSTM_T_NM_DISP
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz

CstmName_PostEventAndReturn:
	call ApPostEvent

CstmName_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 120)
	ret

MainS2cFunc:
	dec 4, xsp
	ld (xsp), xde
	ld xwa, (xsp)
	dec 2, a
	cp xbc, EVT_S2C_TR_DN
	jr z, S2cFunc_HandleEvent11
	cp xbc, EVT_S2C_TR_UP
	jrl nz, EventDelivery_ReturnZero
	ld (0x3990:16), a
	ld wa, 0:i3
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xb90021
	ld xbc, EVT_REQUEST_GRID_DRAW
	call ApDeliveryEvent
	cp (0x3a77:16), 3
	jrl z, EventDelivery_ReturnZero
	ld (0x3a77:16), 3
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	jr S2cFunc_DeliverAndReturn

S2cFunc_HandleEvent11:
	ld (0x3990:16), a
	ld wa, 1:i3
	call Tempo_AdjustEffect
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xb90021
	ld xbc, EVT_REQUEST_GRID_DRAW
	call ApDeliveryEvent
	cp (0x3a77:16), 3
	jr z, EventDelivery_ReturnZero
	ld (0x3a77:16), 3
	ld xwa, 0xb9001c
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb9001f
	ld xbc, EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xb90018
	ld xbc, EVT_REPAINT
	ld xde, 0:i3

S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MiddleNameFunc:
	lda xwa, (0x34bc:16)
	cp xbc, EVT_MSP_NAME_SET
	jr z, MiddleName_HandleEvent01
	cp xbc, EVT_CMP_NAME_SET
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
	ld c, (0x7f3e:16)
	ld a, c
	sll a, 4
	cp c, 2:i3
	jr nc, MiddleName_CalcROMAddr_High
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x1e8a80
	jr MiddleName_CopyAndPost

MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ld w, 0x0:opc
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
	ld xhl, 0:i3
	ret

MiddleCmpClrFunc:
	cp xbc, EVT_CMP_CLR_NO
	jr z, MiddleCmpClr_HandleEvent07
	cp xbc, EVT_CMP_CLR_YES
	jr nz, MiddleCmpClr_ReturnZero
	set 2, (0x34cd:16)
	ld (0x350c:16), 0
	ld xwa, 0xb20012
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld (GLOBAL_ERROR_CODE:16), 35
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	jr MiddleCmpClr_ReturnZero

MiddleCmpClr_HandleEvent07:
	ld (0x350c:16), 0
	ld xwa, 0xb20012
	ld xbc, EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0xb20000
	ld xbc, EVT_ALL_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent

MiddleCmpClr_ReturnZero:
	ld xhl, 0:i3
	ret

MainCmpCpFunc:
	lda xsp, (xsp - 18)
	push xiz
	ld xde, xbc
	ld xiy, MainCmpCpFunc_LocalInit
	lda xix, (xsp + 10)
	ld bc, 6:i3
	ldirw
	cp xde, EVT_RHY_VARI_NM_GET
	jr z, MainCmpCp_HandleEvent03
	cp xde, EVT_RHY_GRP_NM_GET
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
	ld xbc, EVT_AP_RHY_GRP_NM
	ld xde, xiz
	call ApDeliveryEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
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
	cp (ACTIVE_TITLE:16), 184
	jr nz, MemCopy_SetupParams
	lda xbc, (xsp + 4)
	ld a, (xbc + 3)
	cp a, 0x80
	jr c, MemCopy_SetupParams
	cp (xbc + 4), 0x0
	jr nz, MemCopy_SetupParams
	res 7, a
	cp a, 4:i3
	jr nc, MainCmpCp_ClampRange4
	ld a, 0x0:opc
	jr MainCmpCp_StoreClampResult

MainCmpCp_ClampRange4:
	cp a, 0x8
	jr nc, MainCmpCp_ClampRange8
	ld a, 0x1:opc
	jr MainCmpCp_StoreClampResult

MainCmpCp_ClampRange8:
	ld a, 0x2:opc

MainCmpCp_StoreClampResult:
	pushw 0xd
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld	xwa, (xbc+wa)
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
	ld a, (ACTIVE_TITLE:16)
	cp a, 0xb8
	jr nz, MainCmpSet_Init
	ld xwa, 0xb8001f
	ld xbc, EVT_AP_RHY_VARI_NM
	ld xde, xiz
	jr MainCmpSet_Case1

; MainCmpSetFunc init
MainCmpSet_Init:
	cp a, 0xdc
	jr nz, MainCmpSet_Case2
	ld xwa, 0xdc0002
	ld xbc, EVT_AP_RHY_VARI_NM
	ld xde, xiz

; MainCmpSetFunc case 1
MainCmpSet_Case1:
	call ApDeliveryEvent

; MainCmpSetFunc case 2
MainCmpSet_Case2:
	ld xwa, 0xffffffff
	ld xbc, EVT_AUTO_FREE
	ld xde, xiz

; MainCmpSetFunc case 3
MainCmpSet_Case3:
	call ApPostEvent

; MainCmpSetFunc case 4
MainCmpSet_Case4:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 18)
	ret
; CmpSongTtlFunc main handler
CmpSong_MainHandler:
MainCmpSetFunc:
	dec 4, xsp
	ld (xsp), xde
	ld a, (0x34d6:16)
	extz wa
	sla wa, 2
	lda xde, (RhythmTiming_OffsetTable:24)
	ld xhl, 0x94860
	add	xhl, (xde+wa)
	ld xde, xhl
	ld xhl, xbc
	ld xwa, (xsp)
	ld c, a
	sub xhl, EVT_PAN_UP
	cp xhl, 0x0
	jrl lt, CmpSong_VariantA
	cp xhl, 0x7
	jrl gt, CmpSong_VariantA
	add xhl, xhl
	add xhl, MainCmpSetFunc_CaseTable
	ld hl, (xhl)
	lda xix, (MainCmpSet_Dispatch:24)
	jp	t, (xix+hl)
; MainCmpSetFunc dispatch
MainCmpSet_Dispatch:
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	2, xwa
	ld	c, (xwa)
	cp	c, 127
	jrl	nc, CmpSong_VariantA
	inc	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x010000
	ld	xwa, 0xb4000e
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Join
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	2, xwa
	ld	c, (xwa)
	cp	c, 0:i3
	jrl	z, CmpSong_VariantA
	dec	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x010000
	ld	xwa, 0xb4000e
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Join
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	5, xwa
	ld	c, (xwa)
	cp	c, 11
	jrl	nc, CmpSong_VariantA
	inc	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x020000
	ld	xwa, 0xb4000e
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Join
	ld	xwa, (xsp)
	sll	xwa, 3
	add	xwa, 16
	add	xwa, xde
	inc	5, xwa
	ld	c, (xwa)
	cp	c, 0:i3
	jrl	z, CmpSong_VariantA
	dec	1, c
	ld	(xwa), c
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 0x020000
	ld	xwa, 0xb4000e
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MainCmpSetFunc_Join
	ld	a, c
	ld	(0x3540:16), c
	cp	c, 2:i3
	jr	ule, MainCmpSetFunc_Skip
	dec	2, a
	ld	(0x3540:16), a
MainCmpSetFunc_Skip:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
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
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MainCmpSetFunc_Join
	ld	a, c
	ld	(0x3540:16), c
	cp	c, 2:i3
	jr	ule, MainCmpSetFunc_Skip2
	dec	2, a
	ld	(13632:16), a
MainCmpSetFunc_Skip2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
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
	ld	xbc, EVT_REQUEST_GRID_DRAW
MainCmpSetFunc_Join:
	call	ApDeliveryEvent

; CmpSong variant A
CmpSong_VariantA:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MainEsCmpFunc:
	dec 4, xsp
	ld (xsp), xde
	ld xde, (xsp)
	ld a, e
	dec 2, a
	cp xbc, EVT_ES_CMP_VARI_DN
	jrl z, EsCmp_HandleEvent2A
	cp xbc, EVT_ES_CMP_VARI_UP
	jrl z, EsCmp_HandleEvent29
	cp xbc, EVT_ES_CMP_STYL_DN
	jr z, EsCmp_HandleEvent28
	cp xbc, EVT_ES_CMP_STYL_UP
	jrl nz, EsCmp_ReturnZero
	ld (0x39b8:16), a
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x0:opc
	call DrumParam_ProcessChannel
	pop xiz
	pop xix
	pop xhl
	pop xde
	ld wa, de
	extz xde
	add xde, 0x10000
	ld xwa, 0xba000a
	ld xbc, EVT_REQUEST_GRID_DRAW
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xba000a
	ld xbc, EVT_REQUEST_GRID_DRAW
	jrl MspBksl_EventDeliver

EsCmp_HandleEvent28:
	ld (0x39b8:16), a
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x80:opc
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
	ld xbc, EVT_REQUEST_GRID_DRAW
	call ApDeliveryEvent
	ld xwa, (xsp)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xba000a
	ld xbc, EVT_REQUEST_GRID_DRAW
	jr MspBksl_EventDeliver

EsCmp_HandleEvent29:
	ld (0x39b8:16), a
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x0:opc
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
	ld xbc, EVT_REQUEST_GRID_DRAW
	jr MspBksl_EventDeliver

EsCmp_HandleEvent2A:
	ld (0x39b8:16), a
	push xde
	push xhl
	push xix
	push xiz
	ld a, 0x80:opc
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
	ld xbc, EVT_REQUEST_GRID_DRAW

MspBksl_EventDeliver:
	call ApDeliveryEvent

EsCmp_ReturnZero:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MspBkslTtlFunc:
	ld xhl, 0:i3
	ret

MainMspBnkNameFunc:
	ld xhl, 0:i3
	ret

SoundCtrl_SendAccTempo:
	cp (ACTIVE_TITLE:16), 181
	ret nz
	ld xwa, 0xb5001e
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ret

SoundCtrl_SendTempoScaled:
	cp (ACTIVE_TITLE:16), 181
	ret nz
	calr SoundCtrl_CalcScaledTempo
	ld xwa, 0xb50002
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ret

SoundCtrl_CalcScaledTempo:
	ld xhl, 0x64
	ld bc, (0x34d4:16)
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
	ld (0x39ab:16), l
	ret

AccGuard_ProgramChangeCheck:
	; --- Multi-condition guard with conditional calls (85 bytes) ---
	ld	c, (SWBTWR_PAYLOAD_2:16)
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 5:i3
	jr nz, AccGuard_CheckMode09
	cp	(SWBTWR_PAYLOAD_3:16), 0
	jr z, AccGuard_CheckMode09
	cp	c, 2:i3
	ret nz
	jr t, AccGuard_SendProgramChange
AccGuard_CheckMode09:
	cp a, 0x09
	ret nz
	cp	(SWBTWR_PAYLOAD_3:16), 0
	ret z
	cp c, 0x40
	ret nz
	ld	a, (CURRENT_TITLE:16)
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
	cp	hl, 0:i3
	ret z
	ldw wa, 0x00ed
	call SoundCtrl_SendCommand
	ret


AccSeq_DeliverC9_0009:
	cp (ACTIVE_TITLE:16), 201
	ret nz
	ld xwa, 0xc90009
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ret

AccSeq_DeliverC9_000A:
	cp (ACTIVE_TITLE:16), 201
	ret nz
	ld xwa, 0xc9000a
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ret

MainMspRgpSetFunc:
	ld a, (0x7f3d:16)
	sll a, 4
	ld w, 0x0:opc
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
	cp xbc, EVT_RGP_PAD_DN
	jr z, MspMenuTtl_Case1
	cp xbc, EVT_RGP_PAD_UP
	jr z, MspMenuTtl_Init
	cp xbc, EVT_RGP_BNK_DN
	jr z, MspRgpSet_HandleEvent13
	cp xbc, EVT_RGP_BNK_UP
	jrl nz, AccBass_ReturnZero
	cp (0x7f0b:16), 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cp a, 0xe
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, xhl
	jr AccBass_EventDeliver

MspRgpSet_HandleEvent13:
	cp (0x7f0b:16), 0
	jr nz, AccBass_ReturnZero
	ld xbc, xix
	ld a, (xix)
	cp a, 0:i3
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, EVT_REQUEST_GRID_DRAW
	ld xde, xhl
	jr AccBass_EventDeliver

; MspMenuTtlFunc init
MspMenuTtl_Init:
	cp (0x7f0b:16), 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cp a, 5:i3
	jr nc, AccBass_ReturnZero
	inc 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, EVT_REQUEST_GRID_DRAW
	jr AccBass_EventDeliver

; MspMenuTtlFunc case 1
MspMenuTtl_Case1:
	cp (0x7f0b:16), 0
	jr nz, AccBass_ReturnZero
	ld xbc, xwa
	ld a, (xwa)
	cp a, 0:i3
	jr z, AccBass_ReturnZero
	dec 1, a
	ld (xbc), a
	ld xwa, 0xcc0003
	ld xbc, EVT_REQUEST_GRID_DRAW

AccBass_EventDeliver:
	call ApDeliveryEvent

AccBass_ReturnZero:
	ld xhl, 0:i3
	ret
; MspMenuTtlFunc case 2
MspMenuTtl_Case2:
MspMenuTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, MspNameTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspNameTtl_ReturnZero
	cp xde, 0x6
	jr ugt, MspNameTtl_ReturnZero
	add xde, xde
	add xde, MspMenuTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (MspMenuTtl_Dispatch:24)
	jp	t, (xix+de)
; MspMenuTtlFunc title dispatch
MspMenuTtl_Dispatch:
	ld	xwa, 0x028800
	call	SndParam_LookupReadOnly
	cp	l, 13
	jr	c, MspMenuTtlFunc_Skip
	cp	l, 16
	jr	ule, MspMenuTtlFunc_Skip2
MspMenuTtlFunc_Skip:
	ld	l, 0:opc
	jr	MspMenuTtlFunc_Join
MspMenuTtlFunc_Skip2:
	sub	l, 13
MspMenuTtlFunc_Join:
	ld	(0x7f3e:16), l
	ld	a, l
	sll	a, 4
	cp	l, 2:i3
	jr	nc, MspMenuTtlFunc_Skip3
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x1e8a80
	jr	MspMenuTtlFunc_Join2
MspMenuTtlFunc_Skip3:
	sub	a, 32
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x1e8a40
MspMenuTtlFunc_Join2:
	pushw	16
	push	xwa
	pushw	0
	pushw	0x34bc
	call	Strncpy
	lda	xsp, (xsp+10)
	ld	(0x34cc:16), 0

MspNameTtl_ReturnZero:
	ld xhl, 0:i3
	ret
; MspNameTtlFunc mode 1
MspNameTtl_Mode1:
MspNameTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, MspRecMode_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, MspRecMode_ReturnZero
	cp xde, 0x6
	jr ugt, MspRecMode_ReturnZero
	add xde, xde
	add xde, MspNameTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (MspNameTtl_Dispatch:24)
	jp	t, (xix+de)
; MspNameTtlFunc title dispatch
MspNameTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 203
	jr	z, MspNameTtlFunc_Skip
	ld	c, (0x7f3e:16)
	add	c, 13
	extz	bc
	ld	xwa, 0x028800
	ld	de, 0:i3
	call	SoundParam_NotifyChange
MspNameTtlFunc_Skip:
	cp	(PREVIOUS_TITLE:16), 204
	jr	z, MspRecMode_ReturnZero
	ld	xwa, 0xcc0003
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 0xffff0002
	call	ApDeliveryEvent

MspRecMode_ReturnZero:
	ld xhl, 0:i3
	ret
; MspNameTtlFunc mode 2
MspNameTtl_Mode2:
MspRecModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, MspNameTtl_Mode4
	cp xde, 0x1
	jr z, MspNameTtl_Mode3
	or xde, xde
	jr nz, MspNameTtl_Mode4

; MspNameTtlFunc mode 3
MspNameTtl_Mode3:
	ld (0x7f0b:16), 0

; MspNameTtlFunc mode 4
MspNameTtl_Mode4:
	ld xhl, 0:i3
	ret
; MspNameTtlFunc mode 5
MspNameTtl_Mode5:
MspRecTtlFunc:
	cp xbc, EVT_MSP_PLY_MD_SET
	jrl z, MspRecTtl_SubA
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, MspRecTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, MspRecTtl_ReturnZero
	cp xde, 0x6
	jrl ugt, MspRecTtl_ReturnZero
	add xde, xde
	add xde, MspRecTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (MspRecTtl_Dispatch:24)
	jp	t, (xix+de)
; MspRecTtlFunc title dispatch
MspRecTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 201
	jr	z, MspRecTtlFunc_Skip2
	ld	xwa, 0x028103
	ld	bc, 0:i3
	ld	de, 3:i3
	call	SoundParam_NotifyChange
	ld	xwa, 0x028800
	call	SndParam_LookupReadOnly
	cp	l, 13
	jr	z, MspRecTtlFunc_Skip
	cp	l, 14
	jr	nz, MspRecTtlFunc_Skip2
MspRecTtlFunc_Skip:
	ld	a, (0x7f14:16)
	sll	a, 4
	ld	w, 0:opc
	extz	xwa
	add	xwa, 0x1e8820
	ld	a, (xwa)
	and	a, 16
	srl	a, 4
	ld	(0x7f3f:16), a
MspRecTtlFunc_Skip2:
	ld	wa, 0:i3
	call	UI_PostDialEnable
	jr	MspRecTtl_ReturnZero
	cp	(CURRENT_TITLE:16), 201
	jr	z, MspRecTtl_ReturnZero
	cp	(0x7f0b:16), 0
	jr	z, MspRecTtl_ReturnZero
	ld	(0x7f0b:16), 0
	jr	MspRecTtl_ReturnZero

; MspRecTtlFunc sub-handler A
MspRecTtl_SubA:
	ld xwa, 0x28800
	call SndParam_LookupReadOnly
	cp l, 0xd
	jr z, MspRecTtl_SubA_CheckRange
	cp l, 0xe
	jr nz, MspRecTtl_ReturnZero

MspRecTtl_SubA_CheckRange:
	ld a, (0x7f14:16)
	sll a, 4
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x1e8820
	ld c, (0x7f3f:16)
	and c, 0x1
	sll c, 4
	resm 4, (xwa)
	or (xwa), c

MspRecTtl_ReturnZero:
	ld xhl, 0:i3
	ret

AccSeq_PostEvent9E_Enable:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	jp ApPostEvent

AccSeq_PostEvent9E_Disable:
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	jp ApPostEvent
AccSeq_DcModeDataBlock:
	.byte 0xc1
	push	xwa
	xor	(xiy+63), d
	ret	nz
	ld	xwa, 0xdc0005
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ret
; SndArgTtlFunc sub-handler A
SndArgTtl_SubA:
SndArgModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
	ld xhl, 0:i3
	ret
; SndArgTtlFunc sub-handler C
SndArgTtl_SubC:
SndArgTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SndArgTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SndArgTtl_ReturnZero
	cp xde, 0x6
	jr ugt, SndArgTtl_ReturnZero
	add xde, xde
	add xde, SndArgTtlFunc_CaseTable
	ld de, (xde)
	lda xix, (SndArgTtl_Dispatch:24)
	jp	t, (xix+de)
; SndArgTtlFunc title dispatch
SndArgTtl_Dispatch:
	cp	(PREVIOUS_TITLE:16), 220
	jr	z, SndArgTtlFunc_Skip
	ld	xwa, 0xdc0005
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 0xffff0002
	call	ApDeliveryEvent
SndArgTtlFunc_Skip:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccStyle_InlinedBlock
	.ascii "^\\[Z"

SndArgTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SndArgNmGet:
	lda xsp, (xsp - 76)
	pushw_erp 0xfa
	ld (xsp + 70), xde
	ld (xsp + 74), xbc
	ld xiy, SndArgNmGet_PtrTable
	lda xix, (xsp + 66)
	ldiw
	ldiw
	ld xiy, SndArgNmGet_PtrTable_2
	lda xix, (xsp + 58)
	ld bc, 4:i3
	ldirw
	ld xiy, SndArgNmGet_Bytes5
	lda xix, (xsp + 52)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xiy, SndArgNmGet_RamPtrsA
	lda xix, (xsp + 32)
	ldw bc, 0xa
	ldirw
	ld xiy, SndArgNmGet_RamPtrsB
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
	ldfr_berp L, 0xfb
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
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
	cp xwa, EVT_SET_PT_SEL
	jrl z, SndArgNm_HandleEvent24
	add xhl, xix
	cp xwa, EVT_ARG_CHO_GET
	jrl z, SndArgNm_HandleEvent21
	cp xwa, EVT_ARG_TONE_NM_GET
	jrl nz, SndArgNm_ReturnZero
	ld xix, xhl
	ld a, (xhl)
	ldfr_berp A, 0xfb
	ld xiy, xde
	or xde, xde
	jr nz, SndArgNm_ProcessEntry
	or_erpb 0xfb, 0xf0

SndArgNm_ProcessEntry:
	lda xde, (xbc + 3)
	ldto_berp A, 0xfb
	ld (xde), a
	ld a, (xix + 1)
	res 7, a
	ldfr_berp A, 0xfb
	lda xhl, (xbc + 4)
	ldto_berp A, 0xfb
	ld (xhl), a
	ld xwa, (xsp + 2)
	add xwa, xiy
	ld a, (xwa)
	ldfr_berp A, 0xfb
	ld (xbc + 2), a
	ld xwa, (xsp + 70)
	dec 2, a
	ldfr_berp A, 0xfb
	ld a, (xde)
	extz wa
	ld c, (xhl)
	extz bc
	ldto_berp E, 0xfb
	extz de
	sla de, 2
	lda xhl, (xsp + 32)
	ld	xde, (xhl+de)
	call SndParam_ApplyProgramChangeAsync
	ldto_berp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 32)
	ld	xwa, (xbc+wa)
	ld (xwa + 16), 0x0
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x10000
	ld xwa, 0xdc0005
	ld xbc, EVT_ARG_TONE_NM_DISP
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
	ld (0x39e7:16), 0
	jr SndArgNm_DeliverEvent

SndArgNm_HandleEvent21_Copy:
	ld a, (xhl + 1)
	and a, 0x80
	srl a, 7
	ldfr_berp A, 0xfb
	ld xwa, (xsp + 70)
	ld e, a
	dec 2, e
	pushw 0x3
	ldto_berp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 60)
	ld	xwa, (xbc+wa)
	push xwa
	extz de
	sla de, 2
	lda xbc, (xsp + 18)
	ld	xwa, (xbc+de)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldto_berp A, 0xfb
	extz wa
	sla wa, 2
	lda xbc, (xsp + 12)
	ld	xwa, (xbc+wa)
	ld (xwa + 3), 0x0

SndArgNm_DeliverEvent:
	ld xwa, (xsp + 70)
	ld de, wa
	extz xde
	add xde, 0x20000
	ld xwa, 0xdc0005
	ld xbc, EVT_ARG_CHO_DISP

SndArgNm_DeliverAndReturn:
	call ApDeliveryEvent
	jr SndArgNm_ReturnZero

SndArgNm_HandleEvent24:
	ld xwa, (xsp + 2)
	add xwa, xde
	mrib4 0x80, 0x19, 0x3a, 0x8d
	ld e, (PART_SELECT:16)
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ldmm8 0x338f, 0x338e

SndArgNm_ReturnZero:
	ld xhl, 0:i3
	popw_erp 0xfa
	lda xsp, (xsp + 76)
	ret

CmpStepTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, CmpStepTitleFunc_ProcTable
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
	call	DirmdEmulator_Dispatch_Code_Helper
	call	DirmdEmulator_Dispatch_Code_Helper3
	ldw	wa, 255
	call	DirmdEmulator_Dispatch_Code_Helper2
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CmpStep_DataBlock_Helper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CmpStep_DataBlock_Helper2
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
	push	xde
	push	xhl
	push	xix
	push	xiz
	call CmpStep_DataBlock_Code_Helper
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
	call	SeGfx_BoundOp06_Helper
	pop	xwa
	ret
AccDraw_Secondary_Helper:
	push	xwa
	ld	xwa, xiy
	call	ColorBlit_Variant_ByteData
	pop	xwa
	ret
CmpStep_DataBlock_Helper:
	push	xiz
	calr	AccDraw_Secondary_Helper2
	pop	xiz
	ret
AccDraw_Secondary_Helper2:
	cp	(PREVIOUS_TITLE:16), 182
	jr	z, AccDraw_Secondary_Helper2_Skip
	call	AccPlayback_InitOrUpdate
	ld	(0x3525:16), 182
	and	(0xe3e0:16), 239
	and	(0xe3de:16), 239
AccDraw_Secondary_Helper2_Skip:
	call	AccScreen_DataBlock_Helper
	bit	4, (0xe3e0:16)
	jr	nz, AccDraw_Secondary_Helper2_Skip2
	ld	xwa, AccScreen_DataBlock_Code
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
AccDraw_Secondary_Helper2_Skip2:
	ld	xwa, AccScreen_DataBlock_Code2
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code:
	calr	AccScreen_DrawWall
	ld	(COLORBLIT_MODE:24), 2
	ld	xiy, AccScreen_DataBlock_Data_2
	ld	xix, AccScreen_DataBlock_Data_3
	calr	AccAudio_DataBlock1
	calr	AccDraw_Secondary_Helper6
	calr	AccDraw_Secondary_Helper7
	calr	AccDraw_Secondary_Helper11
	ret
AccScreen_DataBlock_Code2:
	calr	AccDraw_Secondary_Helper5
	ld	(COLORBLIT_MODE:24), 1
	ld	xiy, AccScreen_DataBlock_Data_6
	calr	AccDraw_Secondary_Helper
	calr	AccDraw_Secondary_Helper11
	ld	(COLORBLIT_MODE:24), 0
	calr	AccScreen_SelectorToWidgetIndex
	ldmm8	14779, 13526
	ldmm8	14780, 14146
	ldmm8	14781, 14147
	ldmm8	14782, 14148
	ldmm8	14783, 14149
	ldmm8	14784, 14106
	ld	xiy, AccScreen_DataBlock_Data_4
	ld	xix, AccScreen_DataBlock_Data_5
	calr	AccGraphics_RenderStart
	ld	(COLORBLIT_MODE:24), 0
	ldmm8	14779, 14098
	ld	xiy, AccScreen_DataBlock_Data_7
	calr	AccDraw_Secondary
	calr	AccDraw_Secondary_Helper9
	calr	AccDraw_Secondary_Helper12
	calr	AccDraw_Secondary_Helper10
	calr	AccScreen_RefreshScreen
	ret
CmpStep_DataBlock_Helper2:
	push	xiz
	calr	AccDraw_Secondary_Helper3
	pop	xiz
	ret
AccDraw_Secondary_Helper3:
	call	AccScreen_DataBlock_Helper2
	ret
CmpStep_DataBlock_Code_Helper:
	push	xiz
	calr	AccDraw_Secondary_Helper4
	pop	xiz
	ret
AccDraw_Secondary_Helper4:
	ld	xix, AccScreen_DataBlock_Data
	calr	AccDraw_Secondary_Sub
	ret
AccScreen_DataBlock_Data:
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
	ld	d, 166:opc
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
	and	c, (0xf6a6:24)
	.byte 0xa6, 0xf6
	nop
	.byte 0xd5, 0xa6, 0xf6	; data, not code (a table of 0x00f6a6xx
				; pointers misframed as code); was `cp_spiw iz, 166`, whose
				; register byte 0xa6 names no TLCS-900 register (unidasm: rA6L+)
	nop
	.byte 0xd6, 0xa6, 0xf6
	nop
	.byte 0xd7, 0xa6, 0xf6
	nop
	sub	iz, wa
	.byte 0xf6
	nop
AccDraw_Secondary_Sub:
	cp	hl, 15
	jr	ugt, AccDraw_Secondary_Sub_Return
	ld	e, l
	inc	1, e
	calr	AccDraw_Secondary_Sub_Helper
	and	(0xe3e2:16), 254
	ld	xbc, xhl
	and	l, 31
	sla	l, 2
	ld	xix, (xix+l)
	call	(xix)
AccDraw_Secondary_Sub_Return:
	ret
AccDraw_Secondary_Sub_Helper:
	push	xix
	cp	e, 32
	jr	ule, AccDraw_Secondary_Sub_Helper_Skip
	xor	e, e
AccDraw_Secondary_Sub_Helper_Skip:
	sla	e, 2
	ld	xix, AccScreen_DataBlock_Code3
	ld	xde, (xix+e)
	pop	xix
	ret
AccScreen_DataBlock_Code3:
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
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF6A51F-0xF6A537 (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near AccScreen_DataBlock_Code3+13
	.byte 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20
	.byte 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF6A540-0xF6A558 (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near AccScreen_DataBlock_Code3+46
	.byte 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20
	.byte 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00
	.byte 0x01
	nop
	nop
	nop
	push	sr
	nop
	nop
	nop
	.byte 0x04
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF6A561-0xF6A579 (24 B), unreached CODE-territory, was disassembled as 17 plausible-but-dead instruction lines; per=100% dist=6 near AccScreen_DataBlock_Code3+79
	.byte 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x20
	.byte 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00
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
	ld	(P0:8), 0:io
	nop
	rcf
	nop
	nop
	nop
	ld	w, 0:opc
	nop
	nop
	ld	xwa, 0x80000000
	bit	7, w
	jr	nz, 7
	or	(0x3713:16), 64
	jr	5
	or	(0x3713:16), 128
	ret
	.byte 0xc1
	ccf
	ldw	sp, 1087
	jr	nz, 22
	or	(0xe3e2:16), 8
	bit	7, w
	jr	nz, AccDraw_Secondary_Sub_Entry
	or	(0x372d:16), 4
	jr	AccDraw_Secondary_Sub_Return2
AccDraw_Secondary_Sub_Entry:
	or	(0x372d:16), 8
AccDraw_Secondary_Sub_Return2:
	ret
	cp	(0x3712:16), 4
	jr	nz, AccDraw_Secondary_Sub_Return3
	or	(0xe3e2:16), 8
	bit	7, w
	jr	nz, AccDraw_Secondary_Sub_Entry2
	or	(0x372d:16), 1
	jr	AccDraw_Secondary_Sub_Return3
AccDraw_Secondary_Sub_Entry2:
	or	(0x372d:16), 2
AccDraw_Secondary_Sub_Return3:
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(29:8), 82:io
	.byte 0x51, 0xf6
	ld	xwa, AccScreen_DataBlock_Code4
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code4:
	ld	(COLORBLIT_MODE:24), 0
	calr	AccScreen_BeatDataBlock
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(29:8), 139:io
	.byte 0x51, 0xf6
	ld	xwa, AccScreen_DataBlock_Code5
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code5:
	ld	(COLORBLIT_MODE:24), 0
	calr	AccScreen_BeatDataBlock
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(29:8), 194:io
	.byte 0x51, 0xf6, 0xc1
	ccf
	ldw	sp, 1087
	jr	nz, AccDraw_Secondary_Return
	ld	xwa, AccScreen_DataBlock_Code6
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
AccDraw_Secondary_Return:
	ret
AccScreen_DataBlock_Code6:
	ld	(COLORBLIT_MODE:24), 0
	ldmm8	14779, 14102
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_9
	calr	AccDraw_Secondary
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(TREGAH:8), 19:io
	ldw	sp, 574
	and	(0x3713:16), 254
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(TREGAH:8), 19:io
	ldw	sp, 318
	and	(0x3713:16), 253
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(TAMOD:8), 51:io
	reti
	jr	nz, 15
	bit	3, (0x379b:16)
	jr	nz, 9
	call	AccScreen_DataBlock_Helper3
	or	(0xe3e0:16), 16
	ret
	.byte 0xc1, 0xe2, 0xe3
	push	xiz
	ld	(TAMOD:8), 51:io
	reti
	jr	nz, 15
	bit	4, (0x379b:16)
	jr	nz, 9
	call	RhythmVariation_InlineCode_Sub
	or	(0xe3e0:16), 16
	ret
	bit	7, w
	jr	nz, 5
	or	(0x3713:16), 32
	ret
	bit	7, w
	jr	nz, AccDraw_Secondary_Return2
	or	(0x3713:16), 4
AccDraw_Secondary_Return2:
	ret
	ret
	ret
	ret
	bit	7, w
	jr	nz, AccDraw_Secondary_Return3
	ld	(0xe3dc:16), 181
	ld	(0xe3de:16), 128
	jr	AccDraw_Secondary_Return3
AccDraw_Secondary_Return3:
	ret
	ret
	ret
	ret
	ret
AccDraw_Secondary_Helper5:
	ld	(COLORBLIT_MODE:24), 2
	cp	(0x3712:16), 4
	jr	nz, AccDraw_Secondary_Skip
	ld	xiy, AccScreen_DataBlock_Data_3
	ld	xix, AccScreen_DataBlock_Data_4
	calr	AccAudio_DataBlock1
	jr	AccDraw_Secondary_Return4
AccDraw_Secondary_Skip:
	ld	xiy, AccScreen_DataBlock_Data_5
	calr	AccDraw_Secondary_Helper
AccDraw_Secondary_Return4:
	ret
AccDraw_Secondary_Helper6:
	xor	wa, wa
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_2
	ld	xix, xiy
	ld	a, 35:opc
	ld	c, (0x373e:16)
	mul	wa, c
	extz	xwa
	add	xix, xwa
	calr	AccAudio_DataBlock1
	ret
AccDraw_Secondary_Helper7:
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_3
	ld	c, (0x373e:16)
	calr	AccDraw_Secondary_Helper8
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_4
	ld	c, (0x373f:16)
	calr	AccDraw_Secondary_Helper8
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_5
	ld	c, (0x3740:16)
	calr	AccDraw_Secondary_Helper8
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_6
	ld	c, (0x3741:16)
	calr	AccDraw_Secondary_Helper8
	ret
AccDraw_Secondary_Helper8:
	xor	wa, wa
	ld	xix, xiy
	add	xix, 10
	ld	a, 20:opc
	mul	wa, c
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Return5
	extz	xwa
	add	xix, xwa
	calr	AccAudio_DataBlock1
AccDraw_Secondary_Return5:
	ret
AccDraw_Secondary_Helper9:
	ld	xiy, 0x372e
	ld	xix, 2601
	xor	de, de
AccDraw_Secondary_Join:
	xor	bc, bc
	ld	xiz, 0x373e
	xor	wa, wa
	ld	a, e
	extz	xwa
	add	xiz, xwa
	ld	d, (xiz)
	cp	d, 0:i3
	jr	z, AccDraw_Secondary_Helper9_Skip
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	AccAudio_LockAcquire
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
AccDraw_Secondary_Helper9_Loop:
	xor	hl, hl
	ld	l, c
	ld	l, (xiy+hl)
	and	l, 15
	calr	AccDraw_Secondary_Helper9_Helper
	add	xix, 4
	xor	hl, hl
	ld	l, c
	ld	l, (xiy+hl)
	and	l, 240
	srl	l, 4
	calr	AccDraw_Secondary_Helper9_Helper
	add	xix, 4
	inc	1, c
	cp	c, d
	jr	c, AccDraw_Secondary_Helper9_Loop
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	AccAudio_LockRelease
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
AccDraw_Secondary_Helper9_Skip:
	inc	1, e
	cp	e, 4:i3
	jr	ge, AccDraw_Secondary_Return6
	add	xiy, 4
	ld	a, 8:opc
	mul	wa, c
	extz	xwa
	sub	xix, xwa
	add	xix, 1200
	jrl	AccDraw_Secondary_Join
AccDraw_Secondary_Return6:
	ret
AccDraw_Secondary_Helper9_Helper:
	push	xiy
	push	xix
	pushw	de
	pushw	bc
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data
	ld	bc, 4:i3
	ld	a, 6:opc
	ld	xwa, 0x39cc
	ld	(xwa), 6
	ld	(xwa+1), 8
	ld	(xwa+2), ix
	extz	hl
	extz	xhl
	sll	xhl, 2
	add	xiy, xhl
	ld	l, (xiy+)
	ld	(xwa+4), l
	ld	l, (xiy+)
	ld	(xwa+5), l
	ld	l, (xiy+)
	ld	(xwa+6), l
	ld	l, (xiy)
	ld	(xwa+7), l
	call	DrawText_LayoutAndRender
	popw	bc
	popw	de
	pop	xix
	pop	xiy
	ret
AccDraw_Secondary_Helper10:
	xor	wa, wa
	ld	a, (0x370f:16)
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Helper10_Skip
	dec	1, a
AccDraw_Secondary_Helper10_Skip:
	and	a, 127
	ld	c, 32:opc
	div	wa, c
	ld	(0x39b9:16), a
	sla	wa, 1
	xor	xhl, xhl
	ld	l, w
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_7
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(0x39c4:16), bc
	add	bc, 6
	ld	(0x39c8:16), bc
	xor	xhl, xhl
	ld	l, a
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_8
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(0x39c6:16), bc
	add	bc, 8
	ld	(0x39ca:16), bc
	ld	a, 5:opc
	push	xwa
	ld	xwa, 0x39c2
	call	SeGfx_StaticOp05_FromBuf_Helper
	pop	xwa
	ret
AccDraw_Secondary_Helper11:
	xor	wa, wa
	ld	a, (0x370f:16)
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Skip2
	dec	1, a
AccDraw_Secondary_Skip2:
	and	a, 127
	ld	c, 32:opc
	div	wa, c
	ld	(0x39b9:16), a
	ret
AccDraw_Secondary_Helper12:
	ld	(COLORBLIT_MODE:24), 0
	cp	(0x3712:16), 4
	jr	z, AccDraw_Secondary_Skip3
	calr	AccScreen_DrawMeasureDetail
	jr	AccDraw_Secondary_Return7
AccDraw_Secondary_Skip3:
	ld	a, (0x3717:16)
	cp	a, 255
	jr	z, AccDraw_Secondary_Skip4
	calr	AccScreen_DrawTempoDisplay
	calr	AccScreen_UpdateBeatDisplay
AccDraw_Secondary_Skip4:
	calr	AccScreen_BeatDataBlock
	ldmm8	14779, 14102
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_9
	calr	AccDraw_Secondary
AccDraw_Secondary_Return7:
	ret

AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, AccScreen_DrawTempoDisplay_Data
	ld xix, AccScreen_DrawTempoDisplay_Data_2
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	xor wa, wa
	ld a, (0x3718:16)
	ld l, 0xc:opc
	divs wa, l
	ld (0x39b8:16), w
	ld (0x39ba:16), a
	ret

AccScreen_UpdateBeatDisplay:
	ldmm8 0x39bb, 0x3717
	ld xiy, AccScreen_DrawTempoDisplay_Data_2
	push xwa
	ld xwa, xiy
	call DrawText_LayoutAndRender
	pop xwa
	cp (0x3717:16), 99
	jr ugt, AccScreen_BeatDisplay_Large
	ld xiy, AccScreen_UpdateBeatDisplay_Data
	jr AccScreen_BeatDisplay_Draw

AccScreen_BeatDisplay_Large:
	ld xiy, AccScreen_BeatDisplay_Large_Data

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	cp	(0x3712:16), 4
	jr	nz, AccScreen_BeatDataBlock_Code_Return
	ldmm8	14779, 14100
	ldmm8	14780, 14101
	ld xiy, AccScreen_BeatDataBlock_DisplayList
	ld	xix, AccDraw_Secondary_Sub_Entry2_Data_9
	calr	AccGraphics_RenderStart
AccScreen_BeatDataBlock_Code_Return:
	ret

AccScreen_DrawInit_StackWrap:
	ld xwa, AccScreen_DrawInit_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawInit_Body:
	ld (COLORBLIT_MODE:24), 0x00
	calr AccScreen_DrawTempoDisplay
	ret

AccScreen_UpdateBeat_StackWrap:
	ld xwa, AccScreen_UpdateBeat_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_UpdateBeat_Body:
	ld (COLORBLIT_MODE:24), 0x00
	calr AccScreen_UpdateBeatDisplay
	ret

AccScreen_DrawMeasure_StackWrap:
	ld xwa, AccScreen_DrawMeasure_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawMeasure_Body:
	ld (COLORBLIT_MODE:24), 0x00
	calr AccScreen_DrawMeasureDetail
	ret

AccScreen_DrawMeasureDetail:
	ld a, (0x3720:16)
	dec 1, a
	ld (0x39ba:16), a
	ld xiy, AccScreen_DrawMeasureDetail_Data
	calr AccDraw_Secondary
	ld a, (0x3721:16)
	ld (0x39ba:16), a
	cp (0x3720:16), 3
	jr nz, AccScreen_DrawMeas_Other
	ld a, (0x3721:16)
	cp a, 0:i3
	jr z, AccScreen_DrawMeas_Variant3
	ld (0x39ba:16), 1

AccScreen_DrawMeas_Variant3:
	ld xiy, AccScreen_DrawMeas_Variant3_Data
	calr AccDraw_Secondary
	jr AccScreen_DrawMeas_Return

AccScreen_DrawMeas_Other:
	ld xiy, AccScreen_DrawMeas_Other_Data
	calr AccDraw_Init

AccScreen_DrawMeas_Return:
	ret

AccScreen_UIDataBlock:
; Accompaniment engine screen data block
; Total: 2096 bytes (698 + 15 + 120 + 15 + 6 + 287 + 955)
; Screen data blocks compiled from C source, included as .incbin

; Accompaniment step recording UI data: 698 bytes
; ** RE-FRAMED 2026-08-30 (lane B4). Was CODE territory. It is the first 698
; bytes of AccScreen_UIDataBlock, which the header above already documents as a
; 2096-byte screen data block; 23 positional labels point into it and EVERY one
; is used as `ld xiy/xix, <label>` -- an address taken, never a branch target.
; The records have a 2-byte head whose second byte is the record length, and
; several carry the descriptor shape (tag, LE32 pointer, LE16 cell width) that
; the three .incbin records below use.
; ** CORRECTED 2026-09-25 (lane accomp): bytes +0x00..+0x32 of this block are
; NOT data.  They are three routines (51 B) and AccDraw_Secondary CALLS the
; second and third (calr AccScreen_RefreshScreen / AccScreen_SelectorToWidgetIndex,
; which the symboliser had named AccDraw_Secondary_Helper13 / _Helper14), so the
; "never a branch target" reading above holds for the 23 positional labels
; only.  The records begin at +0x33 = AccScreen_DataBlock_Data_2, the first
; positional label.  Evidence: clean llvm-mc/unidasm decode ending on `ret` at
; +0x32; the calls land on Display_DeferOrDrawWall / Display_DeferOrUpdateScreen;
; and v7's copy of this block differs from v10's here in exactly those two call
; operands (by -0x40D, v7's code-relocation delta for that range) and in two
; RAM operands, (0x379b) and (0x39b8), each 0x9C lower in v7 --
; scripts/converters/lane_accomp_v7_uidatablock.py --diff.
; The four 16-byte .byte rows these 51 bytes were spelled as carried these
; ascii renderings:
; |......#.!.!..6..|
; |.#.!.._.......7!|
; |...f....g..ah...|
; |9@.#.4-.....STEP|
	ld	(COLORBLIT_MODE:24), 0
AccScreen_DrawWall:
	ld	c, 0:opc
	ld	a, 12:opc
	ld	a, 16:opc
	call	Display_DeferOrDrawWall
	ret
AccScreen_RefreshScreen:
	ld	c, 7:opc
	ld	a, 12:opc
	call	Display_DeferOrUpdateScreen
	ret
; W = index of the lowest set bit of ((0x379b) & 31), 0 when none is set;
; stored to (0x39b8).
AccScreen_SelectorToWidgetIndex:
	xor	wa, wa
	ld	a, (0x379b:16)
	and	a, 31
	jr	z, AccScreen_SelectorToWidgetIndex_Store
AccScreen_SelectorToWidgetIndex_Loop:
	srl	a, 1
	jr	c, AccScreen_SelectorToWidgetIndex_Store
	inc	1, w
	jr	AccScreen_SelectorToWidgetIndex_Loop
AccScreen_SelectorToWidgetIndex_Store:
	ld	(0x39b8:16), w
	ret
; +0x33: the records
AccScreen_DataBlock_Data_2:
	.byte 0x23, 0x05, 0x34, 0x2d, 0x00, 0x07, 0x12, 0x84, 0x00, 0x53, 0x54, 0x45, 0x50	; |#.4-.....STEP|
	.byte 0x20, 0x52, 0x45, 0x43, 0x4f, 0x52, 0x44, 0x49, 0x4e, 0x47, 0x20, 0x0c, 0x3a, 0x04, 0x50, 0x41	; | RECORDING .:.PA|
	.byte 0x54, 0x54, 0x45, 0x52, 0x4e, 0x3a, 0x20, 0x09, 0x23, 0x04, 0x50, 0x41, 0x52, 0x54, 0x3a, 0x06	; |TTERN: .#.PART:.|
	.byte 0x05, 0xc4, 0x05, 0x8d, 0x06, 0x08, 0xe3, 0x08, 0x50, 0x41, 0x52, 0x54, 0x06, 0x05, 0x8c, 0x0b	; |........PART....|
	.byte 0x8e, 0x06, 0x07, 0xcb, 0x11, 0x45, 0x52, 0x53, 0x06, 0x08, 0x0a, 0x18, 0x52, 0x45, 0x53, 0x54	; |.....ERS....REST|
	.byte 0x07, 0x05, 0xef, 0x05, 0x11, 0x07, 0x05, 0x8f, 0x0b, 0x11, 0x07, 0x05, 0xa7, 0x11, 0x11, 0x07	; |................|
	.byte 0x05, 0xe7, 0x17, 0x11, 0x06, 0x08, 0x19, 0x1f, 0x4d, 0x45, 0x41, 0x53, 0x06, 0x0a, 0x38, 0x1f	; |........MEAS..8.|
	.byte 0x43, 0x55, 0x52, 0x53, 0x4f, 0x52, 0x06, 0x05, 0x22, 0x21, 0x8d, 0x06, 0x05, 0x2a, 0x23, 0x8e	; |CURSOR.."!...*#.|
	.byte 0x06, 0x05, 0x3b, 0x21, 0x8d, 0x06, 0x05, 0x43, 0x23, 0x8e, 0x06, 0x05, 0x30, 0x22, 0x3c, 0x06	; |..;!...C#...0"<.|
	.byte 0x05, 0x35, 0x22, 0x3e, 0x09, 0x0a, 0x15, 0x01, 0x23, 0x00, 0x33, 0x01, 0x32, 0x00, 0x09, 0x0a	; |.5">....#.3.2...|
	.byte 0x13, 0x01, 0x21, 0x00, 0x35, 0x01, 0x34, 0x00, 0x09, 0x0a, 0x15, 0x01, 0x47, 0x00, 0x33, 0x01	; |..!.5.4.....G.3.|
	.byte 0x56, 0x00, 0x09, 0x0a, 0x13, 0x01, 0x45, 0x00, 0x35, 0x01, 0x58, 0x00, 0x09, 0x0a, 0x15, 0x01	; |V.....E.5.X.....|
	.byte 0x6e, 0x00, 0x33, 0x01, 0x7d, 0x00, 0x09, 0x0a, 0x13, 0x01, 0x6c, 0x00, 0x35, 0x01, 0x7f, 0x00	; |n.3.}.....l.5...|
	.byte 0x09, 0x0a, 0x0d, 0x01, 0x96, 0x00, 0x33, 0x01, 0xa5, 0x00, 0x09, 0x0a, 0x0b, 0x01, 0x94, 0x00	; |......3.........|
	.byte 0x35, 0x01, 0xa7, 0x00, 0x0a, 0x0a, 0x0c, 0x00, 0xaa, 0x00, 0xfa, 0x00, 0xc0, 0x00, 0x0a, 0x0a	; |5...............|
	.byte 0x05, 0x00, 0xd2, 0x00, 0x23, 0x00, 0xec, 0x00, 0x0a, 0x0a, 0xcd, 0x00, 0xd2, 0x00, 0xeb, 0x00	; |....#...........|
	.byte 0xec, 0x00, 0x0a, 0x0a, 0xf5, 0x00, 0xd2, 0x00, 0x13, 0x01, 0xec, 0x00, 0x0a, 0x0a, 0x1d, 0x01	; |................|
	.byte 0xd2, 0x00, 0x3b, 0x01, 0xec, 0x00, 0x01, 0x0a, 0x05, 0x00, 0xdf, 0x00, 0x23, 0x00, 0xdf, 0x00	; |..;.........#...|
	.byte	0x01, 0x0a, 0xcd, 0x00, 0xdf, 0x00, 0xeb, 0x00, 0xdf, 0x00	; |..............NO|
AccScreen_DataBlock_Data_3:	.byte	0x06, 0x15, 0x1e, 0x1f, 0x4e, 0x4f
	.byte 0x54, 0x45, 0x20, 0x56, 0x45, 0x4c, 0x20, 0x20, 0x20, 0x4c, 0x45, 0x4e, 0x47, 0x54, 0x48, 0x06	; |TE VEL   LENGTH.|
	.byte 0x14, 0x27, 0x21, 0x8d, 0x20, 0x20, 0x20, 0x20, 0x8d, 0x20, 0x20, 0x20, 0x20, 0x8d, 0x20, 0x20	; |.'!.    .    .  |
	.byte 0x20, 0x20, 0x8d, 0x06, 0x14, 0x2f, 0x23, 0x8e, 0x20, 0x20, 0x20, 0x20, 0x8e, 0x20, 0x20, 0x20	; |  .../#.    .   |
	.byte 0x20, 0x8e, 0x20, 0x20, 0x20, 0x20, 0x8e, 0x0a, 0x0a, 0x2d, 0x00, 0xd2, 0x00, 0x4b, 0x00, 0xec	; | .    ...-...K..|
	.byte 0x00, 0x0a, 0x0a, 0x55, 0x00, 0xd2, 0x00, 0x73, 0x00, 0xec, 0x00, 0x0a, 0x0a, 0x7d, 0x00, 0xd2	; |...U...s.....}..|
	.byte 0x00, 0x9b, 0x00, 0xec, 0x00, 0x0a, 0x0a, 0xa5, 0x00, 0xd2, 0x00, 0xc3, 0x00, 0xec, 0x00, 0x01	; |................|
	.byte 0x0a, 0x2d, 0x00, 0xdf, 0x00, 0x4b, 0x00, 0xdf, 0x00, 0x01, 0x0a, 0x55, 0x00, 0xdf, 0x00, 0x73	; |.-...K.....U...s|
	.byte 0x00, 0xdf, 0x00, 0x01, 0x0a, 0x7d, 0x00, 0xdf, 0x00, 0x9b, 0x00, 0xdf, 0x00, 0x01, 0x0a, 0xa5	; |.....}..........|
	.byte	0x00, 0xdf, 0x00, 0xc3, 0x00, 0xdf, 0x00	; |..........9.. ..|
AccScreen_DataBlock_Data_4:	.byte	0x02, 0x0f, 0xbb, 0x39, 0xff, 0x00, 0x20, 0x09, 0xb1
	.byte 0xf6, 0x00, 0x07, 0x00, 0x1a, 0x04, 0x02, 0x0f, 0xb8, 0x39, 0x07, 0x00, 0x20, 0x5c, 0xae, 0xf6	; |.........9.. \..|
	.byte 0x00, 0x08, 0x00, 0x28, 0x04, 0x02, 0x0f, 0xbc, 0x39, 0x0f, 0x00, 0x06, 0x84, 0xae, 0xf6, 0x00	; |...(....9.......|
	.byte 0x01, 0x00, 0x21, 0x08, 0x02, 0x0f, 0xbd, 0x39, 0x0f, 0x00, 0x06, 0x84, 0xae, 0xf6, 0x00, 0x01	; |..!....9........|
	.byte 0x00, 0xd1, 0x0c, 0x02, 0x0f, 0xbe, 0x39, 0x0f, 0x00, 0x06, 0x84, 0xae, 0xf6, 0x00, 0x01, 0x00	; |......9.........|
	.byte 0x81, 0x11, 0x02, 0x0f, 0xbf, 0x39, 0x0f, 0x00, 0x06, 0x84, 0xae, 0xf6, 0x00, 0x01, 0x00, 0x31	; |.....9.........1|
	.byte 0x16, 0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x8b, 0xac, 0xf6, 0x00, 0x00, 0x0a, 0xc0, 0x39	; |...............9|
	.byte	0x0f, 0x00, 0x06, 0x83, 0x1b, 0x01	; |.............8..|
AccScreen_DataBlock_Data_5:	.byte	0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x38, 0xac, 0xf6
	.byte	0x00, 0x1d, 0x1f, 0x14, 0x00, 0x28, 0x00	; |.....(....9...M.|
AccScreen_DataBlock_Data_7:	.byte	0x02, 0x0f, 0xbb, 0x39, 0x01, 0x00, 0x06, 0x4d, 0xac
	.byte 0xf6, 0x00, 0x05, 0x00, 0x31, 0x1f, 0x20, 0x50, 0x48, 0x52, 0x53, 0x56, 0x41, 0x4c, 0x55, 0x45	; |....1. PHRSVALUE|
	.byte 0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x62, 0xac, 0xf6, 0x00, 0xf0, 0x05, 0x22, 0x00, 0x88	; |.......b....."..|
	.byte	0x00	; |....9...s...Q.!.|
AccScreen_DataBlock_Data_6:	.byte	0x04, 0x0b, 0xb9, 0x39, 0x03, 0x00, 0x0e, 0x73, 0xac, 0xf6, 0x00, 0x51, 0x0a, 0x21, 0x00
	.byte 0x09, 0x00, 0x01, 0x0f, 0x21, 0x00, 0x09, 0x00, 0xb1, 0x13, 0x21, 0x00, 0x09, 0x00, 0x61, 0x18	; |....!.....!...a.|
	.byte 0x21, 0x00, 0x09, 0x00, 0xb9, 0x1a, 0x1f, 0x00, 0x16, 0x00	; |!.........|

; accomp_section_widget: 15 bytes (compiled from C)
AccScreen_DrawMeasureDetail_Data:
	.incbin "includes/generated/accomp_section_widget.bin"

; Accompaniment variation/section data: 120 bytes
; ** RE-FRAMED 2026-08-30 (lane B4). Was `ld xhl,0x52544e4f` and friends -- the
; immediate is the ASCII "ONTR". The descriptor above (already .incbin) carries
; ptr 0x00F6ACA0 and stride 0x0014 = 20, and the six 20-byte cells end exactly
; where the next descriptor begins at 0xF6AD18.
	.ascii "CONTROL PITCH BEND ="
	.ascii "CONTROL MODULATION ="
	.ascii "CONTROL SUSTAIN    ="
	.ascii "CONTROL PANPOT     ="
	.ascii "CONTROL EXPRESSION ="
	.ascii "CONTROL AFTER TOUCH="

; accomp_part_widget: 15 bytes (compiled from C)
AccScreen_DrawMeas_Variant3_Data:
	.incbin "includes/generated/accomp_part_widget.bin"

; Gap: 6 bytes
; ** RE-FRAMED 2026-08-30 (lane B4). The descriptor above (already .incbin)
; carries ptr 0x00F6AD27 and stride 3; these are its two 3-byte cells.
	.ascii "OFF"
	.ascii " ON"

; accomp_display_full: 287 bytes (compiled from C)
AccScreen_DrawMeas_Other_Data:
	.incbin "includes/generated/accomp_display_full.bin", 0x0, 0xA
AccScreen_DrawTempoDisplay_Data:	.incbin "includes/generated/accomp_display_full.bin", 0xA, 0x1E
AccScreen_DrawTempoDisplay_Data_2:	.incbin "includes/generated/accomp_display_full.bin", 0x28, 0x8
AccScreen_UpdateBeatDisplay_Data:	.incbin "includes/generated/accomp_display_full.bin", 0x30, 0xA
AccScreen_BeatDisplay_Large_Data:	.incbin "includes/generated/accomp_display_full.bin", 0x3A, 0xA
AccScreen_BeatDataBlock_DisplayList:	.incbin "includes/generated/accomp_display_full.bin", 0x44, 0x1E
AccDraw_Secondary_Sub_Entry2_Data_9:	.incbin "includes/generated/accomp_display_full.bin", 0x62, 0xBD

; Accompaniment part names and ordering: 955 bytes
; ** RE-FRAMED 2026-08-30 (lane B4) -- and the "955 bytes" above is NOT all
; data. 941 of them are; the other 14 are two real 7-byte subroutines, and the
; falsification test found them: positional_labels.s names offsets 0x804 and
; 0x829 of this block and accompaniment_engine.s reaches BOTH with `call`, not
; `ld`. The tail of the data is 30 seven-byte section-name cells at 0xF6B109
; (0xF6B109 + 30*7 = 0xF6B1DB, the first routine) named by the stride-7
; descriptor at 0xF6ABBE, and a matching 30-entry ordering table at 0xF6B1E2.
; The head is named by the stride-4 descriptor at 0xF6AD8F (ptr 0x00F6AE4C).
	.byte 0x54, 0x45, 0x4e, 0x55, 0x4e, 0x4f, 0x52, 0x4d, 0x53, 0x54, 0x41, 0x43, 0x43, 0x55, 0x54, 0x54	; |TENUNORMSTACCUTT|
	.byte 0x41, 0x43, 0x43, 0x4f, 0x4d, 0x50, 0x20, 0x31, 0x41, 0x43, 0x43, 0x4f, 0x4d, 0x50, 0x20, 0x32	; |ACCOMP 1ACCOMP 2|
	.byte 0x41, 0x43, 0x43, 0x4f, 0x4d, 0x50, 0x20, 0x33, 0x42, 0x41, 0x53, 0x53, 0x20, 0x20, 0x20, 0x20	; |ACCOMP 3BASS    |
	.byte 0x44, 0x52, 0x55, 0x4d, 0x20, 0x20, 0x20, 0x20, 0x20, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37	; |DRUM     1234567|
	.byte	0x38	; |8....*....*..**.|
AccDraw_Secondary_Sub_Entry2_Data:	.byte	0x91, 0x91, 0x91, 0x91, 0x2a, 0x91, 0x91, 0x91, 0x91, 0x2a, 0x91, 0x91, 0x2a, 0x2a, 0x91
	.byte 0x91, 0x91, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x91, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x2a	; |...*.*.*..**.***|
	.byte 0x91, 0x91, 0x91, 0x91, 0x2a, 0x2a, 0x91, 0x91, 0x2a, 0x91, 0x2a, 0x91, 0x2a, 0x2a, 0x2a, 0x91	; |....**..*.*.***.|
	.byte 0x2a, 0x91, 0x91, 0x2a, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x91, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a, 0x2a	; |*..***.**.******|
	.byte	0x2a	; |*....0.F.0.....0|
AccDraw_Secondary_Sub_Entry2_Data_2:	.byte	0x01, 0x0a, 0x07, 0x00, 0x30, 0x00, 0x46, 0x00, 0x30, 0x00, 0x02, 0x0a, 0x07, 0x00, 0x30
	.byte 0x00, 0x07, 0x00, 0x35, 0x00, 0x02, 0x0a, 0x46, 0x00, 0x30, 0x00, 0x46, 0x00, 0x35, 0x00, 0x06	; |...5...F.0.F.5..|
	.byte 0x05, 0xbd, 0x06, 0x15, 0x01, 0x0a, 0x4a, 0x00, 0x30, 0x00, 0x86, 0x00, 0x30, 0x00, 0x02, 0x0a	; |......J.0...0...|
	.byte 0x4a, 0x00, 0x30, 0x00, 0x4a, 0x00, 0x35, 0x00, 0x02, 0x0a, 0x86, 0x00, 0x30, 0x00, 0x86, 0x00	; |J.0.J.5.....0...|
	.byte 0x35, 0x00, 0x06, 0x05, 0xc5, 0x06, 0x15, 0x01, 0x0a, 0x8a, 0x00, 0x30, 0x00, 0xc6, 0x00, 0x30	; |5..........0...0|
	.byte 0x00, 0x02, 0x0a, 0x8a, 0x00, 0x30, 0x00, 0x8a, 0x00, 0x35, 0x00, 0x02, 0x0a, 0xc6, 0x00, 0x30	; |.....0...5.....0|
	.byte 0x00, 0xc6, 0x00, 0x35, 0x00, 0x06, 0x05, 0xcd, 0x06, 0x15, 0x01, 0x0a, 0xca, 0x00, 0x30, 0x00	; |...5..........0.|
	.byte 0x09, 0x01, 0x30, 0x00, 0x02, 0x0a, 0xca, 0x00, 0x30, 0x00, 0xca, 0x00, 0x35, 0x00, 0x02, 0x0a	; |..0.....0...5...|
	.byte	0x09, 0x01, 0x30, 0x00, 0x09, 0x01, 0x35, 0x00, 0x06, 0x05, 0xd5, 0x06, 0x15	; |..0...5.........|
AccDraw_Secondary_Sub_Entry2_Data_3:	.byte	0x02, 0x0a, 0x07
	.byte 0x00, 0x45, 0x00, 0x07, 0x00, 0x4c, 0x00, 0x01, 0x0a, 0x07, 0x00, 0x4c, 0x00, 0x48, 0x00, 0x4c	; |.E...L.....L.H.L|
	.byte 0x00, 0x02, 0x0a, 0x48, 0x00, 0x45, 0x00, 0x48, 0x00, 0x4c, 0x00, 0x01, 0x0a, 0x49, 0x00, 0x4c	; |...H.E.H.L...I.L|
	.byte 0x00, 0x88, 0x00, 0x4c, 0x00, 0x02, 0x0a, 0x88, 0x00, 0x45, 0x00, 0x88, 0x00, 0x4c, 0x00, 0x01	; |...L.....E...L..|
	.byte 0x0a, 0x89, 0x00, 0x4c, 0x00, 0xc8, 0x00, 0x4c, 0x00, 0x02, 0x0a, 0xc8, 0x00, 0x45, 0x00, 0xc8	; |...L...L.....E..|
	.byte 0x00, 0x4c, 0x00, 0x01, 0x0a, 0xc9, 0x00, 0x4c, 0x00, 0x09, 0x01, 0x4c, 0x00, 0x02, 0x0a, 0x09	; |.L.....L...L....|
	.byte	0x01, 0x45, 0x00, 0x09, 0x01, 0x4c, 0x00	; |.E...L.....c...j|
AccDraw_Secondary_Sub_Entry2_Data_4:	.byte	0x02, 0x0a, 0x07, 0x00, 0x63, 0x00, 0x07, 0x00, 0x6a
	.byte 0x00, 0x01, 0x0a, 0x07, 0x00, 0x6a, 0x00, 0x48, 0x00, 0x6a, 0x00, 0x02, 0x0a, 0x48, 0x00, 0x63	; |.....j.H.j...H.c|
	.byte 0x00, 0x48, 0x00, 0x6a, 0x00, 0x01, 0x0a, 0x49, 0x00, 0x6a, 0x00, 0x88, 0x00, 0x6a, 0x00, 0x02	; |.H.j...I.j...j..|
	.byte 0x0a, 0x88, 0x00, 0x63, 0x00, 0x88, 0x00, 0x6a, 0x00, 0x01, 0x0a, 0x89, 0x00, 0x6a, 0x00, 0xc8	; |...c...j.....j..|
	.byte 0x00, 0x6a, 0x00, 0x02, 0x0a, 0xc8, 0x00, 0x63, 0x00, 0xc8, 0x00, 0x6a, 0x00, 0x01, 0x0a, 0xc9	; |.j.....c...j....|
	.byte 0x00, 0x6a, 0x00, 0x09, 0x01, 0x6a, 0x00, 0x02, 0x0a, 0x09, 0x01, 0x63, 0x00, 0x09, 0x01, 0x6a	; |.j...j.....c...j|
	.byte	0x00	; |................|
AccDraw_Secondary_Sub_Entry2_Data_5:	.byte	0x02, 0x0a, 0x07, 0x00, 0x81, 0x00, 0x07, 0x00, 0x88, 0x00, 0x01, 0x0a, 0x07, 0x00, 0x88
	.byte 0x00, 0x48, 0x00, 0x88, 0x00, 0x02, 0x0a, 0x48, 0x00, 0x81, 0x00, 0x48, 0x00, 0x88, 0x00, 0x01	; |.H.....H...H....|
	.byte 0x0a, 0x49, 0x00, 0x88, 0x00, 0x88, 0x00, 0x88, 0x00, 0x02, 0x0a, 0x88, 0x00, 0x81, 0x00, 0x88	; |.I..............|
	.byte 0x00, 0x88, 0x00, 0x01, 0x0a, 0x89, 0x00, 0x88, 0x00, 0xc8, 0x00, 0x88, 0x00, 0x02, 0x0a, 0xc8	; |................|
	.byte 0x00, 0x81, 0x00, 0xc8, 0x00, 0x88, 0x00, 0x01, 0x0a, 0xc9, 0x00, 0x88, 0x00, 0x09, 0x01, 0x88	; |................|
	.byte	0x00, 0x02, 0x0a, 0x09, 0x01, 0x81, 0x00, 0x09, 0x01, 0x88, 0x00	; |................|
AccDraw_Secondary_Sub_Entry2_Data_6:	.byte	0x02, 0x0a, 0x07, 0x00, 0x9f
	.byte 0x00, 0x07, 0x00, 0xa6, 0x00, 0x01, 0x0a, 0x07, 0x00, 0xa6, 0x00, 0x48, 0x00, 0xa6, 0x00, 0x02	; |...........H....|
	.byte 0x0a, 0x48, 0x00, 0x9f, 0x00, 0x48, 0x00, 0xa6, 0x00, 0x01, 0x0a, 0x49, 0x00, 0xa6, 0x00, 0x88	; |.H...H.....I....|
	.byte 0x00, 0xa6, 0x00, 0x02, 0x0a, 0x88, 0x00, 0x9f, 0x00, 0x88, 0x00, 0xa6, 0x00, 0x01, 0x0a, 0x89	; |................|
	.byte 0x00, 0xa6, 0x00, 0xc8, 0x00, 0xa6, 0x00, 0x02, 0x0a, 0xc8, 0x00, 0x9f, 0x00, 0xc8, 0x00, 0xa6	; |................|
	.byte 0x00, 0x01, 0x0a, 0xc9, 0x00, 0xa6, 0x00, 0x09, 0x01, 0xa6, 0x00, 0x02, 0x0a, 0x09, 0x01, 0x9f	; |................|
	.byte	0x00, 0x09, 0x01, 0xa6, 0x00	; |...........!.).1|
AccDraw_Secondary_Sub_Entry2_Data_7:	.byte	0x09, 0x00, 0x11, 0x00, 0x19, 0x00, 0x21, 0x00, 0x29, 0x00, 0x31
	.byte 0x00, 0x39, 0x00, 0x41, 0x00, 0x49, 0x00, 0x51, 0x00, 0x59, 0x00, 0x61, 0x00, 0x69, 0x00, 0x71	; |.9.A.I.Q.Y.a.i.q|
	.byte 0x00, 0x79, 0x00, 0x81, 0x00, 0x89, 0x00, 0x91, 0x00, 0x99, 0x00, 0xa1, 0x00, 0xa9, 0x00, 0xb1	; |.y..............|
	.byte 0x00, 0xb9, 0x00, 0xc1, 0x00, 0xc9, 0x00, 0xd1, 0x00, 0xd9, 0x00, 0xe1, 0x00, 0xe9, 0x00, 0xf1	; |................|
	.byte	0x00, 0xf9, 0x00, 0x01, 0x01	; |.....B.`.~...A-v|
AccDraw_Secondary_Sub_Entry2_Data_8:	.byte	0x42, 0x00, 0x60, 0x00, 0x7e, 0x00, 0x9c, 0x00, 0x41, 0x2d, 0x76
	.byte 0x61, 0x72, 0x69, 0x31, 0x41, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x32, 0x41, 0x2d, 0x76, 0x61, 0x72	; |ari1A-vari2A-var|
	.byte 0x69, 0x33, 0x41, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x34, 0x42, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x31	; |i3A-vari4B-vari1|
	.byte 0x42, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x32, 0x42, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x33, 0x42, 0x2d	; |B-vari2B-vari3B-|
	.byte 0x76, 0x61, 0x72, 0x69, 0x34, 0x43, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x31, 0x43, 0x2d, 0x76, 0x61	; |vari4C-vari1C-va|
	.byte 0x72, 0x69, 0x32, 0x43, 0x2d, 0x76, 0x61, 0x72, 0x69, 0x33, 0x43, 0x2d, 0x76, 0x61, 0x72, 0x69	; |ri2C-vari3C-vari|
	.byte 0x34, 0x41, 0x2d, 0x49, 0x4e, 0x54, 0x20, 0x31, 0x41, 0x2d, 0x49, 0x4e, 0x54, 0x20, 0x32, 0x41	; |4A-INT 1A-INT 2A|
	.byte 0x2d, 0x46, 0x49, 0x4c, 0x4c, 0x31, 0x41, 0x2d, 0x46, 0x49, 0x4c, 0x4c, 0x32, 0x41, 0x2d, 0x45	; |-FILL1A-FILL2A-E|
	.byte 0x4e, 0x44, 0x20, 0x31, 0x41, 0x2d, 0x45, 0x4e, 0x44, 0x20, 0x32, 0x42, 0x2d, 0x49, 0x4e, 0x54	; |ND 1A-END 2B-INT|
	.byte 0x20, 0x31, 0x42, 0x2d, 0x49, 0x4e, 0x54, 0x20, 0x32, 0x42, 0x2d, 0x46, 0x49, 0x4c, 0x4c, 0x31	; | 1B-INT 2B-FILL1|
	.byte 0x42, 0x2d, 0x46, 0x49, 0x4c, 0x4c, 0x32, 0x42, 0x2d, 0x45, 0x4e, 0x44, 0x20, 0x31, 0x42, 0x2d	; |B-FILL2B-END 1B-|
	.byte 0x45, 0x4e, 0x44, 0x20, 0x32, 0x43, 0x2d, 0x49, 0x4e, 0x54, 0x20, 0x31, 0x43, 0x2d, 0x49, 0x4e	; |END 2C-INT 1C-IN|
	.byte 0x54, 0x20, 0x32, 0x43, 0x2d, 0x46, 0x49, 0x4c, 0x4c, 0x31, 0x43, 0x2d, 0x46, 0x49, 0x4c, 0x4c	; |T 2C-FILL1C-FILL|
	.byte 0x32, 0x43, 0x2d, 0x45, 0x4e, 0x44, 0x20, 0x31, 0x43, 0x2d, 0x45, 0x4e, 0x44, 0x20, 0x32	; |2C-END 1C-END 2|
; 0xF6B1DB = AccScreen_GetByte_0x353E: reads a byte variable into A and
; preserves XHL. Callers do `xor xwa,xwa` / `call` / `ld l,a` / `mul8rr a,l`.
AccScreen_GetByte_0x353E:
	push	xhl
	ld	a, (0x353e:16)
	pop	xhl
	ret
; 0xF6B1E2: 30 entries, one per section-name cell above -- a display ordering
; permutation of 0..29.
	.byte 0x00, 0x01, 0x02, 0x03, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11	; |..........|
	.byte 0x04, 0x05, 0x06, 0x07, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17	; |..........|
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d	; |..........|
; 0xF6B200 = AccScreen_GetByte_0x353C: the same shape for (0x353c). The tree
; had lost its entry point inside a phantom `jp 0x3b1d1c` at 0xF6B1FD.
AccScreen_GetByte_0x353C:
	push	xhl
	ld	a, (0x353c:16)
	pop	xhl
	ret

AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	push xiz
	ld xiz, RHYTHM_PATTERN_BUF_A
	ld (0x39ae:16), xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain:
	xor xwa, xwa
	xor xbc, xbc
	ld xhl, (0x39ae:16)
	add xhl, 0x1400
	ld (0x376e:16), xhl
	ld wa, (xhl + 3)
	ld (0x377e:16), wa
	ldw bc, 0x96
	ld (0x378e:16), bc
	ld xhl, (0x39ae:16)
	add xhl, 0xaa00
	ld (0x376a:16), xhl
	ldw bc, 0x96
	xor xhl, xhl

AccPatch_IterateSlotChain:
	cpw (0x377e:16), 0xffff
	jr z, AccPatch_IterateSlot_NextBlock
	ld hl, (0x377e:16)
	calr AccPatch_CalcSlotBufferAddr
	ld (0x375a:16), xiz
	cp hl, (0x378e:16)
	jr z, AccPatch_IterateSlot_Advance
	calr AccPatch_UpdateLinkPointers
	calr AccPatch_SwapSlotBuffers

AccPatch_IterateSlot_Advance:
	ld xiz, (0x376a:16)
	ld wa, (xiz + 3)
	ld (0x377e:16), wa
	incw 1, (0x378e:16)
	ld hl, (0x378e:16)
	calr AccPatch_CalcSlotBufferAddr
	ld (0x376a:16), xiz
	jr AccPatch_IterateSlotChain

AccPatch_IterateSlot_NextBlock:
	ld xiz, 0x100
	add (0x376e:16), xiz
	ld xiz, (0x376e:16)
	ld wa, (xiz + 3)
	ld (0x377e:16), wa
	djnz16 bc, AccPatch_IterateSlotChain
	xor xwa, xwa
	xor xhl, xhl
	ld wa, (0x378e:16)
	ldw hl, 0x100
	mul xwa, hl
	add xwa, 0x1400
	add xwa, 0x3ff
	and xwa, 0xfffffc00
	srl xwa, 4
	ld xiy, (0x39ae:16)
	ld (xiy + 46), wa
	ret

AccPatch_SwapSlotBuffers:
	push xbc
	ld xwa, 0x400
	push xwa
	call Malloc
	add xsp, 0x4
	ld (0x3564:16), xhl
	ldw bc, 0x100
	ld xix, (0x3564:16)
	ld xiy, (0x376a:16)
	ldir85
	ldw bc, 0x100
	ld xix, (0x376a:16)
	ld xiy, (0x375a:16)
	ldir85
	ldw bc, 0x100
	ld xiy, (0x3564:16)
	ld xix, (0x375a:16)
	ldir85
	ld xwa, (0x3564:16)
	push xwa
	call Free
	add xsp, 0x4
	pop xbc
	ret

AccPatch_UpdateLinkPointers:
	xor xwa, xwa
	xor xhl, xhl
	ld xiy, (0x375a:16)
	ld wa, (xiy + 3)
	ld (0x3927:16), wa
	ld wa, (xiy + 1)
	ld (0x3929:16), wa
	ld xix, (0x376a:16)
	ld wa, (xix + 3)
	ld (0x392b:16), wa
	ld wa, (xix + 1)
	ld (0x392d:16), wa
	ld hl, (0x3927:16)
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Back
	calr AccPatch_CalcSlotBufferAddr
	ld wa, (0x378e:16)
	ld (xiz + 1), wa

AccPatch_UpdateLink_Back:
	ld hl, (0x3929:16)
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Fwd1
	calr AccPatch_CalcSlotBufferAddr
	ld wa, (0x378e:16)
	ld (xiz + 3), wa

AccPatch_UpdateLink_Fwd1:
	ld hl, (0x392b:16)
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Fwd2
	calr AccPatch_CalcSlotBufferAddr
	ld wa, (0x377e:16)
	ld (xiz + 1), wa

AccPatch_UpdateLink_Fwd2:
	ld hl, (0x392d:16)
	cp hl, 0xffff
	jr z, AccPatch_UpdateLink_Return
	calr AccPatch_CalcSlotBufferAddr
	ld wa, (0x377e:16)
	ld (xiz + 3), wa

AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	xor xiz, xiz
	ld xiz, 0x100
	mul xiz, hl
	add xiz, (0x39ae:16)
	add xiz, 0x1400
	ret

AccPatch_VoiceAssignDataBlock:
	ret
	ret
	ld	xiy, (0x374e:16)
	ld a, (xiy+0:8)
	cp a, 109
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+2)
	cp	a, 97
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	(0x379a:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip:
	ld a, (xiy+0:8)
	cp a, 102
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+2)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	(0x379a:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip2:
	ld a, (xiy+0:8)
	cp a, 109
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	a, (xiy+2)
	cp	a, 98
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	(0x379a:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip3:
	ld	(0x379a:16), 255
	ld	(0x3950:16), 130
AccPatch_VoiceAssignDataBlock_Return:
	ret
	xor	xbc, xbc
	ldw	bc, 42
	add	xiy, 12
	add	xix, 12
	ldirw
	djnz8	e, -22
	ret
	cp	xix, xiy
	jr	ugt, AccPatch_VoiceAssignDataBlock_Skip4
AccPatch_VoiceAssignDataBlock_Loop:
	xor	xbc, xbc
	ldw	bc, 128
	ldirw
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop
	jr	AccPatch_VoiceAssignDataBlock_Return2
AccPatch_VoiceAssignDataBlock_Skip4:
	push	d
	ld	d, 0:opc
	ld	xbc, 0:i3
	ldw	bc, 256
	mul	xbc, de
	pop	d
	add	xix, xbc
	add	xiy, xbc
	push	xix
	push	xiy
	dec	1, xix
	dec	1, xiy
AccPatch_VoiceAssignDataBlock_Loop3:
	ld	xbc, 0:i3
	ldw	bc, 256
	lddr85
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop3
	pop	xiy
	pop	xix
AccPatch_VoiceAssignDataBlock_Return2:
	ret
	xor	xbc, xbc
AccPatch_VoiceAssignDataBlock_Loop4:
	ld	(xiy), 0
	ldw	(xiy+1), 65535
	ldw (xiy+3), 65535
	ld	c, 249:opc
	add	xiy, 6
AccPatch_VoiceAssignDataBlock_Loop5:
	ld (xiy+), 0
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop5
	inc	1, xiy
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop4
	ret
	xor	xbc, xbc
AccPatch_VoiceAssignDataBlock_Loop6:
	ld	xiy, 0x09f200
	ld	c, (0x393e:16)
AccPatch_VoiceAssignDataBlock_Loop7:
	cp	(xiy+1), wa
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip13
AccPatch_VoiceAssignDataBlock_Loop8:
	cpw	(xiy+3), 65535
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip12
	inc	1, (0x393d:16)
	jr	AccPatch_VoiceAssignDataBlock_Join4
AccPatch_VoiceAssignDataBlock_Skip12:
	inc	1, (0x393d:16)
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop8
	jr	AccPatch_VoiceAssignDataBlock_Join4
AccPatch_VoiceAssignDataBlock_Skip13:
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop7
AccPatch_VoiceAssignDataBlock_Join4:
	inc	1, wa
	cp	wa, qwa
	jr	ule, AccPatch_VoiceAssignDataBlock_Loop6
	ret
	ld	xiy, 0x09f200
	xor	xbc, xbc
	ld	c, 190:opc
	cp	(xiy), 128
	jr	nz, AccPatch_VoiceAssignDataBlock_Return6
	inc	1, (0x3942:16)
	add	xiy, 256
	djnz8	c, -18
AccPatch_VoiceAssignDataBlock_Return6:
	ret
	xor	xde, xde
AccPatch_VoiceAssignDataBlock_Loop2:
	ld	de, (xiy+3)
	cp	de, 0xffff
	jr	z, AccPatch_VoiceAssignDataBlock_Skip16
	ld	de, (0x3946:16)
	ld	(xiy+3), de
	ld	de, (0x3944:16)
	ld	(xix+1), de
	ldw	(0x394c:16), 0
AccPatch_VoiceAssignDataBlock_Entry:
	cpw	(xix+3), 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Skip15
	ld	de, (0x394c:16)
	cp	de, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip14
	incw	1, (0x3946:16)
	ld	de, (0x3946:16)
	ld	(xix+3), de
	add	xix, 256
	ldw	(0x394c:16), 255
	jr	AccPatch_VoiceAssignDataBlock_Entry
AccPatch_VoiceAssignDataBlock_Skip14:
	ld	de, (0x3946:16)
	dec	1, de
	ld	(xix+1), de
	incw	1, (0x3946:16)
	ld	de, (0x3946:16)
	ld	(xix+3), de
	add	xix, 256
	jr	AccPatch_VoiceAssignDataBlock_Entry
AccPatch_VoiceAssignDataBlock_Skip15:
	ld	de, (0x394c:16)
	cp	de, 0:i3
	jr	z, AccPatch_VoiceAssignDataBlock_Skip5
	ld	de, (0x3946:16)
	dec	1, de
	ld	(xix+1), de
AccPatch_VoiceAssignDataBlock_Skip5:
	incw	1, (0x3946:16)
	add	xix, 256
AccPatch_VoiceAssignDataBlock_Skip16:
	incw	1, (0x3944:16)
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jrl	ugt, AccPatch_VoiceAssignDataBlock_Loop2
	ret
AccPatch_VoiceAssignDataBlock_Helper:
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, hl
	add	xiz, RHYTHM_PATTERN_BUF_B
	ret
	push	xiz
	call	AccPatch_VoiceAssignDataBlock_Helper22
	pop	xiz
	ret
AccPatch_VoiceAssignDataBlock_Helper22:
	ld	(0x3950:16), 0
	ldw	(0x3970:16), 0
	ldw	(0x3972:16), 150
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	calr	AccPatch_VoiceAssignDataBlock_Helper18
	cp	(0x3950:16), 132
	jr	z, AccPatch_VoiceAssignDataBlock_Join
	calr	AccPatch_VoiceAssignDataBlock_Helper_Helper
	cp	w, 255
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip6
	ld	(0x3950:16), 130
	jr	AccPatch_VoiceAssignDataBlock_Join
AccPatch_VoiceAssignDataBlock_Skip6:
	calr	AccPatch_VoiceAssignDataBlock_Helper2
	call	AccScreen_GetByte_0x353E
	calr	AccPatch_VoiceAssignDataBlock_Helper3
	calr	AccPatch_VoiceAssignDataBlock_Sub
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join
	calr	AccPatch_VoiceAssignDataBlock_Helper5
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join
	calr	AccPatch_VoiceAssignDataBlock_Helper_Helper2
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join
	jr	AccPatch_VoiceAssignDataBlock_Join2
AccPatch_VoiceAssignDataBlock_Join:
	call	AccScreen_GetByte_0x353E
	calr	AccPatch_VoiceAssignDataBlock_Helper3
AccPatch_VoiceAssignDataBlock_Join2:
	calr	AccPatch_VoiceAssignDataBlock_Helper21
	call	AccPatch_ClearModeFlag
	ret
AccPatch_VoiceAssignDataBlock_Helper2:
	xor	xwa, xwa
	ld	xiy, 0x069800
	ld	wa, (xiy+14)
	ld	xiy, RHYTHM_PATTERN_BUF_A
	ld	(xiy+14), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper_Helper:
	ld	xhl, 0x069800
	cp	(xhl+1), 72
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip7
	cp	(xhl+2), 0
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip7
	cp	(xhl+2), 75
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip7
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return3
AccPatch_VoiceAssignDataBlock_Skip7:
	ld a, (xhl+0:8)
	cp a, 103
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip8
	ld	a, (xhl+1)
	cp	a, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip8
	ld	a, (xhl+2)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip8
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return3
AccPatch_VoiceAssignDataBlock_Skip8:
	ld a, (xhl+0:8)
	cp a, 76
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip9
	ld	a, (xhl+1)
	cp	a, 75
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip9
	ld	a, (xhl+2)
	cp	a, 69
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip9
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return3
AccPatch_VoiceAssignDataBlock_Skip9:
	ld	w, 255:opc
AccPatch_VoiceAssignDataBlock_Return3:
	ret
AccPatch_VoiceAssignDataBlock_Helper3:
	ld	w, (0x34d6:16)
	ld	(0x34d6:16), a
	pushw	wa
	call	AccPatch_InitCurrentSlot
	popw	wa
	ld	(0x34d6:16), w
	ret
AccPatch_VoiceAssignDataBlock_Sub:
	xor	xhl, xhl
	xor	xwa, xwa
	call	AccScreen_GetByte_0x353C
	ld	l, a
	ld	a, 96:opc
	mul	wa, l
	add	wa, 96
	ld	(0x397a:16), wa
	xor	xwa, xwa
	call	AccScreen_GetByte_0x353E
	ld	l, a
	ld	a, 96:opc
	mul	wa, l
	add	wa, 96
	ld	(0x397c:16), wa
	cpw	(0x397a:16), 960
	jr	c, AccPatch_VoiceAssignDataBlock_Sub_Skip
	cpw	(0x397a:16), 960
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Skip2
	cpw	(0x397a:16), 2016
	jr	c, AccPatch_VoiceAssignDataBlock_Sub_Skip3
	cpw	(0x397a:16), 2016
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Skip4
	jr	AccPatch_VoiceAssignDataBlock_Sub_Join
AccPatch_VoiceAssignDataBlock_Sub_Skip:
	calr	AccPatch_VoiceAssignDataBlock_Sub_Helper
	jr	AccPatch_VoiceAssignDataBlock_Sub_Return
AccPatch_VoiceAssignDataBlock_Sub_Skip2:
	calr	AccPatch_VoiceAssignDataBlock_Sub_Helper2
	jr	AccPatch_VoiceAssignDataBlock_Sub_Return
AccPatch_VoiceAssignDataBlock_Sub_Skip3:
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	cp	(0x3950:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Return
	subw	(0x397a:16), 1024
	calr	AccPatch_VoiceAssignDataBlock_Sub_Helper
	jr	AccPatch_VoiceAssignDataBlock_Sub_Return
AccPatch_VoiceAssignDataBlock_Sub_Skip4:
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	cp	(0x3950:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Return
	subw	(0x397a:16), 1024
	calr	AccPatch_VoiceAssignDataBlock_Sub_Helper2
	jr	AccPatch_VoiceAssignDataBlock_Sub_Return
AccPatch_VoiceAssignDataBlock_Sub_Join:
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	cp	(0x3950:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Return
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	cp	(0x3950:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Sub_Return
	subw	(0x397a:16), 2048
	calr	AccPatch_VoiceAssignDataBlock_Sub_Helper3
AccPatch_VoiceAssignDataBlock_Sub_Return:
	ret
AccPatch_VoiceAssignDataBlock_Sub_Helper:
	xor	xiz, xiz
	ld	xiy, 0x069800
	ld	iz, (0x397a:16)
	add	xiy, xiz
	add	xiy, 12
	ld	xix, RHYTHM_PATTERN_BUF_A
	ld	iz, (0x397c:16)
	add	xix, xiz
	add	xix, 12
	xor	xbc, xbc
	ldw	bc, 84
	ldir85
	calr	AccPatch_VoiceAssignDataBlock_Helper4
	ret
AccPatch_VoiceAssignDataBlock_Sub_Helper2:
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xiz, xiz
	ldw	wa, 1024
	sub wa, (14714:16)
	ld	bc, wa
	sub	bc, 12
	ld	xiy, 0x069800
	ld	xix, RHYTHM_PATTERN_BUF_A
	ld	iz, (0x397a:16)
	add	xiy, xiz
	add	xiy, 12
	ld	iz, (0x397c:16)
	add	xix, xiz
	add	xix, 12
	push	xbc
	ldir85
	push	xiy
	push	xix
	calr	AccPatch_VoiceAssignDataBlock_Helper4
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	pop	xix
	pop	xiy
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Sub_Return2
	pop	xbc
	ld	xiy, 0x069800
	ldw	wa, 96
	sub	wa, bc
	ld	bc, wa
	sub	bc, 12
	ldir85
AccPatch_VoiceAssignDataBlock_Sub_Return2:
	ret
AccPatch_VoiceAssignDataBlock_Sub_Helper3:
	xor	xiy, xiy
	xor	xix, xix
	ld	iy, (0x397a:16)
	add	xiy, 0x069800
	add	xiy, 12
	ld	ix, (0x397c:16)
	add	xix, RHYTHM_PATTERN_BUF_A
	add	xix, 12
	ldw	bc, 96
	sub	bc, 12
	ldir85
	calr	AccPatch_VoiceAssignDataBlock_Helper4
	ret
AccPatch_VoiceAssignDataBlock_Helper4:
	xor	xiy, xiy
	xor	xix, xix
	xor	xwa, xwa
	ld	iy, (0x397a:16)
	ld	xhl, 0x069800
	add	xhl, 0
	ld	wa, (xhl+iy)
	ld	(0x3952:16), wa
	ld	xhl, 432128
	add	xhl, 4
	ld	wa, (xhl+iy)
	ld (14676:16), wa
	ld	xhl, 0x069800
	add	xhl, 6
	ld	wa, (xhl+iy)
	ld	(0x3956:16), wa
	ld	xhl, 432128
	add	xhl, 8
	ld	wa, (xhl+iy)
	ld (14680:16), wa
	ld	xhl, 0x069800
	add	xhl, 10
	ld	wa, (xhl+iy)
	ld (14682:16), wa
	ld	ix, (0x397c:16)
	add	xix, RHYTHM_PATTERN_BUF_A
	ld wa, (xix+0:8)
	ld (14684:16), wa
	ld	wa, (xix+4)
	ld	(0x395e:16), wa
	ld	wa, (xix+6)
	ld	(0x3960:16), wa
	ld	wa, (xix+8)
	ld	(0x3962:16), wa
	ld	wa, (xix+10)
	ld	(0x3964:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper5:
	calr	AccPatch_VoiceAssignDataBlock_Helper19
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper5_Return
	ld	xwa, 5:i3
	push	xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	pop	xwa
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper5_Return
	djnz8	a, -14
	calr	AccPatch_VoiceAssignDataBlock_Helper6
	calr	AccPatch_VoiceAssignDataBlock_Helper7
	calr	AccPatch_VoiceAssignDataBlock_Helper8
	calr	AccPatch_VoiceAssignDataBlock_Helper9
	calr	AccPatch_VoiceAssignDataBlock_Helper10
AccPatch_VoiceAssignDataBlock_Helper5_Return:
	ret
AccPatch_VoiceAssignDataBlock_Helper6:
	ld	wa, (0x3952:16)
	ld	(0x3974:16), wa
	ld	wa, (0x395c:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	ld	wa, (0x3974:16)
	ld	(0x3952:16), wa
	ld	wa, (0x3978:16)
	ld	(0x3966:16), wa
	ld	wa, (0x3976:16)
	ld	(0x395c:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper7:
	ld	wa, (0x3954:16)
	ld	(0x3974:16), wa
	ld	wa, (0x395e:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	ld	wa, (0x3974:16)
	ld	(0x3954:16), wa
	ld	wa, (0x3978:16)
	ld	(0x3968:16), wa
	ld	wa, (0x3976:16)
	ld	(0x395e:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper8:
	ld	wa, (0x3956:16)
	ld	(0x3974:16), wa
	ld	wa, (0x3960:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	ld	wa, (0x3974:16)
	ld	(0x3956:16), wa
	ld	wa, (0x3978:16)
	ld	(0x396a:16), wa
	ld	wa, (0x3976:16)
	ld	(0x3960:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper9:
	ld	wa, (0x3958:16)
	ld	(0x3974:16), wa
	ld	wa, (0x3962:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	ld	wa, (0x3974:16)
	ld	(0x3958:16), wa
	ld	wa, (0x3978:16)
	ld	(0x396c:16), wa
	ld	wa, (0x3976:16)
	ld	(0x3962:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper10:
	ld	wa, (0x395a:16)
	ld	(0x3974:16), wa
	ld	wa, (0x3964:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	ld	wa, (0x3974:16)
	ld	(0x395a:16), wa
	ld	wa, (0x3978:16)
	ld	(0x396e:16), wa
	ld	wa, (0x3976:16)
	ld	(0x3964:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper11:
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper11_Return
	calr	AccPatch_VoiceAssignDataBlock_Helper11_Helper
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper11_Return
	calr	AccPatch_VoiceAssignDataBlock_Helper14
	calr	AccPatch_VoiceAssignDataBlock_Helper15
AccPatch_VoiceAssignDataBlock_Helper11_Return:
	ret
AccPatch_VoiceAssignDataBlock_Helper11_Helper:
	calr	AccPatch_VoiceAssignDataBlock_Helper12
	cp	de, 0:i3
	jr	z, AccPatch_VoiceAssignDataBlock_Return4
	ld	wa, (0x3974:16)
	cp wa, (14704:16)
	jr	c, AccPatch_VoiceAssignDataBlock_Skip10
	xor	xhl, xhl
	xor	xbc, xbc
	ld	bc, (0x3974:16)
	srl	bc, 2
	ld	hl, (0x3970:16)
	srl	hl, 2
	sub	bc, hl
AccPatch_VoiceAssignDataBlock_Helper11_Join:
	cp	bc, 0:i3
	jr	ule, AccPatch_VoiceAssignDataBlock_Helper11_Skip
	push	xbc
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	pop	xbc
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper11_Skip
	addw	(0x3970:16), 4
	dec	1, bc
	jr	AccPatch_VoiceAssignDataBlock_Helper11_Join
AccPatch_VoiceAssignDataBlock_Helper11_Skip:
	jr	AccPatch_VoiceAssignDataBlock_Return4
AccPatch_VoiceAssignDataBlock_Skip10:
	calr	AccPatch_VoiceAssignDataBlock_Helper11_Helper2
AccPatch_VoiceAssignDataBlock_Return4:
	ret
AccPatch_VoiceAssignDataBlock_Helper12:
	xor	xwa, xwa
	xor	xhl, xhl
	xor	xde, xde
	ld	wa, (0x3974:16)
	ld	hl, (0x3970:16)
	cp	wa, hl
	jr	c, AccPatch_VoiceAssignDataBlock_Helper12_Skip2
	add	hl, 3
	cp	wa, hl
	jr	ugt, AccPatch_VoiceAssignDataBlock_Helper12_Skip2
	ld	de, 0:i3
	jr	AccPatch_VoiceAssignDataBlock_Helper12_Return2
AccPatch_VoiceAssignDataBlock_Helper12_Skip2:
	ldw	de, 255
AccPatch_VoiceAssignDataBlock_Helper12_Return2:
	ret
AccPatch_VoiceAssignDataBlock_Helper11_Helper2:
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper12_Return
	cpw	(0x3974:16), 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper11_Helper2_Skip
	calr	AccPatch_VoiceAssignDataBlock_Helper19
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper12_Return
	ld	xwa, 4:i3
	push	xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	pop	xwa
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper12_Return
	djnz8	a, -14
	ldw	(0x3970:16), 0
	xor	xbc, xbc
	ld	bc, (0x3974:16)
	srl	bc, 2
	inc	1, bc
AccPatch_VoiceAssignDataBlock_Helper12_Join:
	cp	bc, 0:i3
	jr	ule, AccPatch_VoiceAssignDataBlock_Helper12_Skip
	push	xbc
	calr	AccPatch_VoiceAssignDataBlock_Helper20
	pop	xbc
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper12_Return
	addw	(0x3970:16), 4
	dec	1, bc
	jr	AccPatch_VoiceAssignDataBlock_Helper12_Join
AccPatch_VoiceAssignDataBlock_Helper12_Skip:
	jr	AccPatch_VoiceAssignDataBlock_Helper12_Return
AccPatch_VoiceAssignDataBlock_Helper11_Helper2_Skip:
	ld	(0x3950:16), 128
AccPatch_VoiceAssignDataBlock_Helper12_Return:
	ret
AccPatch_VoiceAssignDataBlock_Helper13:
	xor	xwa, xwa
	xor	xhl, xhl
	ld	wa, (0x3974:16)
	ld	hl, (0x3970:16)
	sub	wa, hl
	ldw	hl, 256
	mul	xwa, hl
	ld	(0x397a:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper14:
	calr	AccPatch_VoiceAssignDataBlock_Helper13
	xor	xiy, xiy
	ld	iy, (0x397a:16)
	add	xiy, 6
	add	xiy, 0x069800
	xor	xhl, xhl
	ld	hl, (0x3976:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	xix, xiz
	add	xix, 6
	xor	xbc, xbc
	ldw	bc, 249
	ldir85
	ret
AccPatch_VoiceAssignDataBlock_Helper15:
	xor	xiy, xiy
	xor	xwa, xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper13
	ld	iy, (0x397a:16)
	ld	xhl, 432128
	add	xhl, 3
	ld	wa, (xhl+iy)
	ld (14708:16), wa
	xor	xhl, xhl
	ld	hl, (0x3976:16)
	ld	(0x3978:16), hl
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	wa, (xiz+3)
	ld	(0x3976:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper_Helper2:
	ld	wa, (0x3952:16)
	ld	(0x3974:16), wa
	ld	wa, (0x3966:16)
	ld	(0x3978:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper16
	ld	wa, (0x3954:16)
	ld	(0x3974:16), wa
	ld	wa, (0x3968:16)
	ld	(0x3978:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper16
	ld	wa, (0x3956:16)
	ld	(0x3974:16), wa
	ld	wa, (0x396a:16)
	ld	(0x3978:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper16
	ld	wa, (0x3958:16)
	ld	(0x3974:16), wa
	ld	wa, (0x396c:16)
	ld	(0x3978:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper16
	ld	wa, (0x395a:16)
	ld	(0x3974:16), wa
	ld	wa, (0x396e:16)
	ld	(0x3978:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper16
	ret
AccPatch_VoiceAssignDataBlock_Helper16:
	xor	xwa, xwa
	bit	7, (0x3950:16)
	jrl	nz, AccPatch_VoiceAssignDataBlock_Helper16_Epilogue2
AccPatch_VoiceAssignDataBlock_Helper16_Join:
	cpw	(0x3974:16), 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Helper16_Epilogue
	calr	AccPatch_VoiceAssignDataBlock_Helper16_Helper
	cpw	(0x3972:16), 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper16_Skip
	ld	wa, (0x3972:16)
	ld	(0x3976:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper11_Helper
	bit	7, (0x3950:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Helper16_Skip
	calr	AccPatch_VoiceAssignDataBlock_Helper14
	xor	xhl, xhl
	ld	hl, (0x3978:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	wa, (0x3976:16)
	ld	(xiz+3), wa
	ld	hl, wa
	calr	AccPatch_VoiceAssignDataBlock_Helper
	or	(xiz), 128
	decw	1, (0x34d4:16)
	ld	wa, (0x3978:16)
	ld	(xiz+1), wa
	xor	xiy, xiy
	ld	iy, (0x397a:16)
	add	xiy, 0x069800
	ld	wa, (xiy+3)
	cp	wa, 0xffff
	jr	z, AccPatch_VoiceAssignDataBlock_Helper16_Skip2
	ld	(xiz+3), wa
	jr	AccPatch_VoiceAssignDataBlock_Helper16_Join2
AccPatch_VoiceAssignDataBlock_Helper16_Skip2:
	ldw (xiz+3), 65535
AccPatch_VoiceAssignDataBlock_Helper16_Join2:
	ld	(0x3974:16), wa
	ld	wa, (0x3976:16)
	ld	(0x3978:16), wa
	jr	AccPatch_VoiceAssignDataBlock_Helper16_Join
AccPatch_VoiceAssignDataBlock_Helper16_Skip:
	ld	hl, (0x3976:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ldw	(xiz+3), 65535
AccPatch_VoiceAssignDataBlock_Helper16_Epilogue:
	nop
AccPatch_VoiceAssignDataBlock_Helper16_Epilogue2:
	nop
	ret
AccPatch_VoiceAssignDataBlock_Helper16_Helper:
	xor	xhl, xhl
	ld	hl, (0x3972:16)
	cp	hl, 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper16_Helper_Skip2
AccPatch_VoiceAssignDataBlock_Join3:
	calr AccPatch_VoiceAssignDataBlock_Helper
	ld a, (xiz)
	bit 7, a
	jr z, AccPatch_VoiceAssignDataBlock_Helper16_Helper_Skip2
	inc 1, hl
	cp	hl, 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper16_Helper_Skip
	jr	AccPatch_VoiceAssignDataBlock_Join3
AccPatch_VoiceAssignDataBlock_Helper16_Helper_Skip:
	ld	(0x3950:16), 131
AccPatch_VoiceAssignDataBlock_Helper16_Helper_Skip2:
	ld	(0x3972:16), hl
	ret
AccPatch_VoiceAssignDataBlock_Helper17:
	ret
AccPatch_VoiceAssignDataBlock_Helper18:
	ret
AccPatch_VoiceAssignDataBlock_Helper19:
	ret
AccPatch_VoiceAssignDataBlock_Helper20:
	ret
AccPatch_VoiceAssignDataBlock_Helper21:
	cp	(0x3950:16), 0
	jr	z, AccPatch_VoiceAssignDataBlock_Skip11
	cp	(0x3950:16), 132
	jr	z, AccPatch_VoiceAssignDataBlock_Helper21_Skip
	cp	(0x3950:16), 130
	jr	z, AccPatch_VoiceAssignDataBlock_Helper21_Skip4
	cp	(0x3950:16), 131
	jr	z, AccPatch_VoiceAssignDataBlock_Helper21_Skip2
	cp	(0x3950:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Helper21_Skip3
	ld	(GLOBAL_ERROR_CODE:16), 1
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Helper21_Skip:
	ld	(GLOBAL_ERROR_CODE:16), 3
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Helper21_Skip2:
	ld	(GLOBAL_ERROR_CODE:16), 23
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Helper21_Skip3:
	ld	(GLOBAL_ERROR_CODE:16), 1
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Helper21_Skip4:
	ld	(GLOBAL_ERROR_CODE:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Skip11:
	ld	(GLOBAL_ERROR_CODE:16), 35
AccPatch_VoiceAssignDataBlock_Return5:
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
	cp wa, 0:i3
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
	and (0x8d88:16), 254
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
	cp wa, 0:i3
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
	set 2, (0x28a7:16)
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call Vga_SetupMultiPlaneDisplay
	jr AccDisplay_CopyToBackBuffer

Display_RestoreEntry:
	res 2, (0x28a7:16)
	call Vga_RestoreMultiPlaneDisplay
	jr AccDisplay_CopyToFrontBuffer

AccDisplay_CopyToBackBuffer:
	lda xbc, (RHYTHM_PATTERN_BUF_A:24)
	ld (0x55dc:16), xbc
	lda xwa, (0x069800:24)
	ld (0x55e0:16), xwa
	ld xiy, xbc
	ld xix, xwa
	ldw bc, 0xb400
	ldirw
	ret

AccDisplay_CopyToFrontBuffer:
	lda xde, (RHYTHM_PATTERN_BUF_A:24)
	ld (0x55dc:16), xde
	lda xwa, (0x069800:24)
	ld (0x55e0:16), xwa
	ld xiy, xwa
	ld xix, xde
	ldw bc, 0xb400
	ldirw
	ret

AccBankData_InitAllSlots:
	pushw_erp 0xfa
	ld xwa, (0x3d5c:16)
	ld (0x55dc:16), xwa
	ldib_erp 0xfb, 0
	ld wa, 0:i3

AccBankData_InitSlot_OuterLoop:
	ld xde, 0:i3

AccBankData_InitSlot_InnerLoop:
	lda	xbc, (xde+wa)
	add xbc, (0x55dc:16)
	lda xbc, (xbc+160:16)
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
	lda	xbc, (xde+wa)
	add xbc, (0x55dc:16)
	ld	(xbc+160), 0x20
	inc 1, xde
	cp xde, 0x10
	jr c, AccBankData_PadSpaces_Loop

AccBankData_PadSpaces_Done:
	inc1b_erp 0xfb
	add wa, 0x60
	cp_erpb 0xfb, 0x0c
	jr c, AccBankData_InitSlot_OuterLoop
	ld (0x48d6:16), 0
	res 0, (0x35b0:16)
	ldib_erp 0xfb, 0

AccBankData_ProcessSlot:
	lda xwa, (0x069800:24)
	ld (0x39ae:16), xwa
	ldto_berp A, 0xfb
	ld (0x39ac:16), a
	call AccPatch_InitFromSlotIndex
	ld xwa, (0x3d5c:16)
	ld (0x39ae:16), xwa
	lda xwa, (0x069800:24)
	ld (0x39b2:16), xwa
	ldto_berp A, 0xfb
	ld (0x39ad:16), a
	ldto_berp A, 0xfb
	ld (0x39ac:16), a
	call DualVoice_ParamLoadDone
	ld a, (0x35b0:16)
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotFound
	ld (0x48d6:16), 1
	jr AccBankData_ReInitAllSlots

AccBankData_SlotFound:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x1e
	jr c, AccBankData_ProcessSlot
	cp (0x48d6:16), 0
	jr z, AccBankData_FinalizeCheck

AccBankData_ReInitAllSlots:
	lda xwa, (0x069800:24)
	ld (0x39ae:16), xwa
	ldib_erp 0xfb, 0

AccBankData_ReInit_Loop:
	ldto_berp A, 0xfb
	ld (0x39ac:16), a
	call AccPatch_InitFromSlotIndex
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x1e
	jr c, AccBankData_ReInit_Loop

AccBankData_FinalizeCheck:
	cp (0x48d6:16), 0
	jr nz, AccBankData_Return
	ld xwa, (0x3d5c:16)
	add xwa, 0x16800
	ld bc, (xwa)
	ld xwa, 4:i3
	ld de, 3:i3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg
	ld xbc, (0x3d5c:16)
	add xbc, 0x16c00
	ld xix, xbc
	ldib_erp 0xfb, 0
	lda xde, (0xe3ba:16)

AccBankData_CompareLoop:
	ldto_berp A, 0xfb
	extz wa
	ld hl, wa
	extz xhl
	add xhl, xde
	ld A, (xix+)
	cp a, (xhl)
	jr nz, AccBankData_Return
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, AccBankData_CompareLoop
	ld xix, xbc
	lda xbc, (0x1e0000:24)
	ld xde, 0:i3

AccBankData_CopyToExtRAM:
	ld A, (xix+)
	ld (xbc+), a
	inc 1, xde
	cp xde, 0x72a6
	jr c, AccBankData_CopyToExtRAM
	ld wa, 0:i3
	call PostTmSave_Success

AccBankData_Return:
	popw_erp 0xfa
	ret

AccBankData_ProcessWithCopy:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ld xbc, (0x3d5c:16)
	ld (0x55dc:16), xbc
	pushw 0xd
	ld xwa, (0x3d5c:16)
	add xwa, 0x16802
	push xwa
	lda xwa, (xbc+160:16)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldib_erp 0xfb, 0
	ld bc, 0:i3

AccBankData_CopyLoop:
	ld de, bc
	add de, 0xa0
	ld xwa, (0x55dc:16)
	lda	xwa, (xwa+de)
	ld e, (xwa)
	cp e, 0:i3
	jr nz, AccBankData_CopyLoop_NonZero
	ld e, 0x20:opc

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
	ld xde, (0x3d5c:16)
	ld wa, 0:i3
	call DualVoice_LoadAndScan
	call Vga_RestorePlane3FromBuffer
	call AccPatch_CountSlotsAlt
	jrl AccBankData_PostModeChange

AccBankData_InitSlotScan:
	ld (0x48d6:16), 0
	res 0, (0x35b0:16)
	ldib_erp 0xfb, 0

AccBankData_SlotScan_Loop:
	lda xwa, (0x069800:24)
	ld (0x39ae:16), xwa
	ld c, (xsp + 2)
	extz bc
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda xwa, (AccBankData_SlotOrder:24)
	ld	(0x39ac:16), (xwa+de)
	call AccPatch_InitFromSlotIndex
	ld xwa, (0x3d5c:16)
	ld (0x39ae:16), xwa
	lda xwa, (0x069800:24)
	ld (0x39b2:16), xwa
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld bc, wa
	lda xde, (AccBankData_SlotOrder:24)
	ld	(0x39ac:16), (xde+bc)
	ld a, (xsp + 2)
	extz wa
	add bc, wa
	ld	(0x39ad:16), (xde+bc)
	call DualVoice_ParamLoadDone
	ld a, (0x35b0:16)
	extz wa
	bit 0, wa
	jr z, AccBankData_SlotScan_Next
	ld (0x48d6:16), 1
	jr AccBankData_SlotScan_ReInit

AccBankData_SlotScan_Next:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, AccBankData_SlotScan_Loop
	cp (0x48d6:16), 0
	jr z, AccBankData_NotifyAndUpdateTempo

AccBankData_SlotScan_ReInit:
	lda xwa, (0x069800:24)
	ld (0x39ae:16), xwa
	ldib_erp 0xfb, 0

AccBankData_ReInit_ScanLoop:
	ld c, (xsp + 2)
	extz bc
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x3
	ld de, wa
	add de, bc
	lda xwa, (AccBankData_SlotOrder:24)
	ld	(0x39ac:16), (xwa+de)
	call AccPatch_InitFromSlotIndex
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr c, AccBankData_ReInit_ScanLoop
	jr AccBankData_PostModeChange

AccBankData_NotifyAndUpdateTempo:
	ld xwa, (0x3d5c:16)
	add xwa, 0x16800
	ld bc, (xwa)
	ld xwa, 4:i3
	ld de, 3:i3
	call SoundParam_NotifyChange
	call SeqTimer_UpdateTempoReg

AccBankData_PostModeChange:
	ldw wa, 0x16
	call UI_PostModeChangeEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

AccBankData_CopyDataBlock:
	lda	xbc, (0x48b6:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
AccBankData_ProcessWithCopy_Loop:
	ld (xwa+), 0
	cp	xwa, xbc
	jr	c, AccBankData_ProcessWithCopy_Loop
	ret

StyleBuf_ClearAllEntries:
	lda xbc, (0x3f88:16)
	ld xwa, xbc
	lda xbc, (xbc+2048)

StyleBuf_ClearEntry_Outer:
	ld xde, xwa
	lda xhl, (xwa + 32)

StyleBuf_ClearEntry_Inner:
	ld (xde+), 0x00
	cp xde, xhl
	jr c, StyleBuf_ClearEntry_Inner
	lda xwa, (xwa + 32)
	cp xwa, xbc
	jr c, StyleBuf_ClearEntry_Outer
	ret

StyleConv_ClearWorkBuffer:
	lda xbc, (0x488c:16)
	ld xwa, xbc
	lda xbc, (xbc + 32)

StyleConv_ClearWorkBuf_Loop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	lda xwa, (0x4788:16)
	ld xbc, xwa
	lda xde, (0x3f88:16)
	lda xhl, (xwa+256)

StyleConv_ClearEntry_Outer:
	ld xwa, xde
	lda xix, (xde + 32)

StyleConv_ClearEntry_Inner:
	ld (xwa+), 0x00
	cp xwa, xix
	jr c, StyleConv_ClearEntry_Inner
	ld xwa, 0:i3
	ld (xbc+), XWA
	lda xde, (xde + 32)
	cp xbc, xhl
	jr c, StyleConv_ClearEntry_Outer
	ret

StyleConv_InitEntryTable:
	pushw iz
	ld ix, 0:i3

StyleConvInit_OuterLoop:
	ld hl, ix
	mul hl, 0x25
	lda xde, (0x55e4:16)
	ld bc, hl
	extz xbc
	add xbc, xde
	ld wa, ix
	extz xwa
	div wa, 0x14
	ldto_werp WA, 0xe2
	ld (xbc), a
	ld iz, 0:i3

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
	ldto_berp A, 0xe2
	ld (xiy + 1), a
	inc 1, iz
	cp iz, 0x20
	jr c, StyleConvInit_InnerLoop
	ld xwa, 0:i3
	ld (xbc + 33), xwa
	inc 1, ix
	cp ix, 0x100
	jr c, StyleConvInit_OuterLoop
	popw iz
	ret

SoundMem_ClearRegion:
	ld xwa, 0xffc00

SoundMem_ClearLoop:
	ld (xwa+), 0x00
	cp xwa, 0x100000
	jr c, SoundMem_ClearLoop
	ret

StyleFile_ClearAllTables:
	lda xwa, (0x555c:16)
	ld xbc, xwa
	lda xde, (0x48dc:16)
	lda xhl, (xwa+128:16)

StyleFile_ClearTable_Outer:
	ld xwa, xde
	lda xix, (xde + 100)

StyleFile_ClearTable_Inner:
	ld (xwa+), 0x00
	cp xwa, xix
	jr c, StyleFile_ClearTable_Inner
	ld xwa, 0:i3
	ld (xbc+), XWA
	lda xde, (xde + 100)
	cp xbc, xhl
	jr c, StyleFile_ClearTable_Outer
	ret

DialUI_PostInitEvents:
	ld wa, 1:i3
	call UI_PostDialEnable
	ldw wa, 0x82
	call UI_PostDialValueEvent
	ld wa, 2:i3
	jp UI_PostDialRangeEvent

DialUI_CalcProlog:
	dec 2, xsp
	push xiz
	ld iz, wa
	extz xde
	div xde, iz
	mul xde, iz
	ld (xsp + 4), de
	ldiw_erp 0xfa, 0
	cp iz, 0:i3
	jr ule, DialCalc_Return

DialCalc_EventLoop:
	ld xbc, 0x110002
	ld a, (CURRENT_TITLE:16)
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
	lda xhl, (0x55e4:16)
	ld de, bc
	extz xde
	add xde, xhl
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	inc1w_erp 0xfa
	ldto_werp WA, 0xfa
	cp wa, iz
	jr c, DialCalc_EventLoop

DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret

StylCnvWaitTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, AccChord_ReturnZero
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, AccChord_ReturnZero
	cp xde, 0x3
	jr z, StylCnvWait_HandleClose
	cp xde, 0x8
	jr z, AccChord_ReturnZero
	cp xde, 0x2
	jr nz, AccChord_ReturnZero
	cp (PREVIOUS_TITLE:16), 96
	jr nz, StylCnvWait_CheckPending
	calr StyleConv_InitEntryTable
	ld (0x3d06:16), 0
	calr AccDisplay_FullInit
	call FileIO_CheckMediaIsWritable
	cp hl, 0:i3
	jr nz, StylCnvWait_SetStatus
	ldw wa, 0x11
	call UI_PostModeChangeEvent

StylCnvWait_SetStatus:
	ld (0x48da:16), 0
	jr AccChord_ReturnZero

StylCnvWait_CheckPending:
	cp (0x48da:16), 0
	jr z, AccChord_ReturnZero
	ld (GLOBAL_ERROR_CODE:16), 74
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld (0x48da:16), 0
	jr AccChord_ReturnZero

StylCnvWait_HandleClose:
	cp (CURRENT_TITLE:16), 96
	jr z, StylCnvWait_RestoreDisplay
	cp (CURRENT_MODE:16), 6
	jr z, AccChord_ReturnZero

StylCnvWait_RestoreDisplay:
	calr Display_RestoreEntry

AccChord_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvTxtTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, StylCnvTxt_ReturnZero
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, StylCnvTxt_ReturnZero
	cp xde, 0x3
	jr z, StylCnvTxt_HandleClose
	cp xde, 0x8
	jr z, StylCnvTxt_ReturnZero
	cp xde, 0x2
	jr nz, StylCnvTxt_ReturnZero
	cp (0x0ffc00:24), 0x05
	jr nz, StylCnvTxt_ReturnZero
	ld (0x0ffc00:24), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvTxt_ReturnZero

StylCnvTxt_HandleClose:
	cp (CURRENT_MODE:16), 6
	call nz, (Display_RestoreEntry:24)

StylCnvTxt_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvModlTtlFunc:
	lda xsp, (xsp - 36)
	push xiz
	ld xhl, xde
	ld de, (0x3d04:16)
	ld iz, de
	ld wa, (0x3a82:16)
	cp xbc, EVT_SW_IN
	jrl z, StylCnvModl_HandleOK
	cp xbc, EVT_ACTIVATE_STATE
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
	ld (0x48da:16), 0
	ld xwa, StylCnvModl_CnvFilter
	call ControlState_ProcessCommand
	ldw (0x3a82:16), 0
	ld iz, 0:i3

StylCnvModl_ScanMatchingModels:
	ld bc, iz
	mul bc, 0x25
	lda xwa, (0x55e4:16)
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cp hl, 0:i3
	jr nz, StylCnvModl_ScanDone
	incw 1, (0x3a82:16)
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvModl_ScanMatchingModels

StylCnvModl_ScanDone:
	cpw (0x3a82:16), 0
	jr nz, StylCnvModl_PadModelNames
	ldw wa, 0x10
	jrl StylCnvModl_OK_Select_ShowError

StylCnvModl_PadModelNames:
	cp iz, 0x100
	jr nc, StylCnvModl_InitListDisplay
	lda xhl, (0x55e4:16)
	ld bc, iz
	mul bc, 0x25

StylCnvModl_PadOuterLoop:
	ld iy, 0:i3
	ld de, bc

StylCnvModl_PadInnerLoop:
	ld a, 0x0:opc
	cp iy, 0xc
	jr nc, StylCnvModl_PadStoreChar
	ld a, 0x20:opc

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
	ldw (0x3d04:16), 0
	ld xwa, 0x110002
	ld xbc, EVT_SET_SELECTED_LINE
	ld xde, 0:i3
	call ApPostEvent
	lda xbc, (0x3f68:16)
	ld xwa, xbc
	lda xbc, (xbc + 32)

StylCnvModl_ClearDisplayBuf:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StylCnvModl_ClearDisplayBuf
	ld xwa, StylCnvModl_VerFilter
	call ControlState_ProcessCommand
	lda xbc, (xsp + 36)
	ld xwa, 0x3f68
	call FileIO_SearchStringMatch
	lda xwa, (0x3f68:16)
	cp hl, 0:i3
	jr nz, StylCnvModl_CopyDefaultName
	pushw 0x2e
	push xwa
	call Sprintf_StringLength
	inc 6, xsp
	or xhl, xhl
	jr z, StylCnvModl_FormatFilename
	ld (xhl), 0x0

StylCnvModl_FormatFilename:
	ld iy, 0:i3
	lda xde, (0x3f68:16)

StylCnvModl_FormatLoop:
	ld bc, iy
	extz xbc
	add xbc, xde
	ld a, (xbc)
	cp a, 0:i3
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
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cp hl, 0:i3
	jrl nz, StylCnvModl_Return

StylCnvModl_WaitForAck:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 36)
	call FileIO_SearchStringMatch
	cp hl, 0:i3
	jr z, StylCnvModl_WaitForAck
	jrl StylCnvModl_Return

StylCnvModl_HandleScroll:
	ld bc, wa
	cp wa, 0:i3
	jrl z, StylCnvModl_Return
	ldw wa, 0x14
	jrl StylCnvModl_OK_CallRedraw

StylCnvModl_HandleRedraw:
	cp (CURRENT_TITLE:16), 96
	jr z, StylCnvModl_RedrawDone
	cp (CURRENT_MODE:16), 6
	jr z, StylCnvModl_RedrawReturnZero

StylCnvModl_RedrawDone:
	calr Display_RestoreEntry

StylCnvModl_RedrawReturnZero:
	ld wa, 0:i3
	jr StylCnvModl_CallReturnAction

StylCnvModl_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvModl_Return

StylCnvModl_HandleOpenItem:
	ld wa, 0:i3

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
	ld (0x3d04:16), de

StylCnvModl_OK_LoadSelection:
	ld bc, (0x3d04:16)

StylCnvModl_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvModl_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xe6
	extz xde
	ld xwa, 0x110002
	ld xbc, EVT_SET_SELECTED_LINE
	call ApPostEvent
	ld de, (0x3d04:16)
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvModl_OK_PageRedraw
	mul iz, 0x25
	lda xwa, (0x55e4:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld de, (0x3d04:16)
	mul de, 0x25
	lda xwa, (0x55e4:16)
	extz xde
	add xde, xwa
	ld xwa, 0x110002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_ScrollUp:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, (0x3d04:16)
	cp wa, 0:i3
	jrl z, StylCnvModl_OK_LoadSelection
	dec 1, wa
	ld (0x3d04:16), wa
	ld bc, wa
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_ScrollDown:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld bc, (0x3a82:16)
	dec 1, bc
	ld wa, (0x3d04:16)
	cp wa, bc
	jrl nc, StylCnvModl_OK_LoadSelection
	inc 1, wa
	ld (0x3d04:16), wa
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
	ldto_werp WA, 0xee
	cp wa, 0:i3
	jrl z, StylCnvModl_OK_LoadSelection
	ld (0x3d04:16), bc
	jrl StylCnvModl_OK_UpdateDisplay

StylCnvModl_OK_SelectItem:
	mul de, 0x25
	lda xwa, (0x55e5:16)
	extz xde
	add xde, xwa
	ld xwa, xde
	ld xbc, StylCnv_ModeRb_Select
	call FileIO_OpenWithBuiltPath
	cp hl, 0:i3
	jr ge, StylCnvModl_OK_Select_ClearMem
	ldw wa, 0x10
	jr StylCnvModl_OK_Select_ShowError

StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	ld xwa, 0:i3

StylCnvModl_OK_Select_FillLoop:
	ld (xbc+), 0x00
	inc 1, xwa
	cp xwa, 0x30000
	jr c, StylCnvModl_OK_Select_FillLoop
	ld bc, (0x3d04:16)
	mul bc, 0x25
	lda xwa, (0x5605:16)
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
	ld bc, (0x3d04:16)
	mul bc, 0x25
	lda xwa, (0x5605:16)
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
	ld (0x3d5c:16), xbc
	call FileIO_CloseHandle
	ld (0x0ffbfe:24), 0x00
	ld wa, (0x3d04:16)
	ld (0x48ac:16), wa
	ld iz, 0:i3
	lda xhl, (0xe3ca:16)
	ld wa, (0x3d04:16)
	mul wa, 0x25
	lda xbc, (0x55e4:16)

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
	ld (0x48ac:16), wa
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	pushw 0x4
	ld wa, (0x3d04:16)
	mul wa, 0x25
	extz xwa
	add xwa, xbc
	lda xwa, (xwa + 33)
	push xwa
	ld xwa, 0xffc02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld bc, (0x3d04:16)
	mul bc, 0x25
	lda xwa, (0x5605:16)
	extz xbc
	add xbc, xwa
	ld xwa, (xbc)
	ld (0x3d58:16), xwa
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvModl_Return

StylCnvModl_OK_PageRedraw:
	ld bc, (0x3a82:16)
	ldw wa, 0x14

StylCnvModl_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvModl_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 36)
	ret
StylCnvModl_End:

StylCnvCnvtTtlFunc:
	push xiz
	ld hl, (0x3d04:16)
	ld iz, hl
	ld ix, (0x3a82:16)
	cp xbc, EVT_SW_IN
	jrl z, StylCnvCnvt_HandleOK
	cp xbc, EVT_ACTIVATE_STATE
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
	ld (0x48da:16), 0
	calr DialUI_PostInitEvents
	ldw (0x3a82:16), 0
	ld iz, 0:i3

StylCnvCnvt_ScanMatchingStyles:
	ld bc, iz
	mul bc, 0x25
	lda xwa, (0x55e4:16)
	extz xbc
	add xbc, xwa
	lda xwa, (xbc + 1)
	lda xbc, (xbc + 33)
	call FileIO_SearchStringMatch
	cp hl, 0:i3
	jr nz, StylCnvCnvt_PadStyleNames
	incw 1, (0x3a82:16)
	inc 1, iz
	cp iz, 0x100
	jr c, StylCnvCnvt_ScanMatchingStyles

StylCnvCnvt_PadStyleNames:
	cp iz, 0x100
	jr nc, StylCnvCnvt_InitListDisplay
	lda xhl, (0x55e4:16)
	ld bc, iz
	mul bc, 0x25

StylCnvCnvt_PadOuterLoop:
	ld iy, 0:i3
	ld de, bc

StylCnvCnvt_PadInnerLoop:
	ld a, 0x0:opc
	cp iy, 0xc
	jr nc, StylCnvCnvt_PadStoreChar
	ld a, 0x20:opc

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
	ldw (0x3d04:16), 0
	ld xwa, 0x120002
	ld xbc, EVT_SET_SELECTED_LINE
	ld xde, 0:i3
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	cp (CURRENT_MODE:16), 6
	call nz, (Display_RestoreEntry:24)
	ld wa, 0:i3
	jr StylCnvCnvt_CallReturnAction

StylCnvCnvt_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvCnvt_Return

StylCnvCnvt_HandleOpenItem:
	ld wa, 0:i3

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
	ld (0x3d04:16), hl

StylCnvCnvt_OK_LoadSelection:
	ld bc, (0x3d04:16)

StylCnvCnvt_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvCnvt_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xe6
	extz xde
	ld xwa, 0x120002
	ld xbc, EVT_SET_SELECTED_LINE
	call ApPostEvent
	ld de, (0x3d04:16)
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvCnvt_OK_PageRedraw
	mul iz, 0x25
	lda xwa, (0x55e4:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld de, (0x3d04:16)
	mul de, 0x25
	lda xwa, (0x55e4:16)
	extz xde
	add xde, xwa
	ld xwa, 0x120002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	jrl StylCnvCnvt_Return

StylCnvCnvt_OK_ScrollUp:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, (0x3d04:16)
	cp wa, 0:i3
	jrl z, StylCnvCnvt_OK_LoadSelection
	dec 1, wa
	ld (0x3d04:16), wa
	ld bc, wa
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_ScrollDown:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld bc, (0x3a82:16)
	dec 1, bc
	ld wa, (0x3d04:16)
	cp wa, bc
	jrl nc, StylCnvCnvt_OK_LoadSelection
	inc 1, wa
	ld (0x3d04:16), wa
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
	ldto_werp WA, 0xea
	cp wa, 0:i3
	jrl z, StylCnvCnvt_OK_LoadSelection
	ld (0x3d04:16), bc
	jrl StylCnvCnvt_OK_UpdateDisplay

StylCnvCnvt_OK_SelectItem:
	ld a, (0x3d06:16)
	cp a, 2:i3
	jr z, StylCnvCnvt_OK_Select_WriteStyle
	cp a, 1:i3
	jr nz, StylCnvCnvt_Return
	ld wa, (0x48ac:16)
	cp wa, 1:i3
	jr z, StylCnvCnvt_OK_Select_Finalize
	cp wa, 0:i3
	jr z, StylCnvCnvt_OK_Select_Finalize
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_Select_WriteStyle:
	ld xwa, (0x3d5c:16)
	ld (0x3d60:16), xwa
	call FileIO_CheckMediaIsWritable
	ld bc, (0x3d04:16)
	mul bc, 0x25
	lda xwa, (0x55e5:16)
	extz xbc
	add xbc, xwa
	ld xwa, xbc
	call FileIO_NormalizePath

StylCnvCnvt_OK_Select_Finalize:
	ld (0x0ffc00:24), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_PageRedraw:
	ld bc, (0x3a82:16)
	ldw wa, 0x14

StylCnvCnvt_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvCnvt_Return:
	ld xhl, 0:i3
	pop xiz
	ret
StylCnvCnvt_End:

StylCnvSelTtlFunc:
	push xiz
	ld xhl, xbc
	ld ix, (0x3d04:16)
	ld iz, ix
	ld bc, (0x3a82:16)
	cp xhl, EVT_SW_IN
	jr z, StylCnvSel_HandleOK
	cp xhl, EVT_ACTIVATE_STATE
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
	ldw (0x3d04:16), 0
	ld xwa, 0x150002
	ld xbc, EVT_SET_SELECTED_LINE
	ld xde, 0:i3
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	cp (CURRENT_MODE:16), 6
	call nz, (Display_RestoreEntry:24)
	ld wa, 0:i3
	jr StylCnvSel_CallReturnAction

StylCnvSel_HandleClose:
	calr DialUI_PostInitEvents
	jrl StylCnvSel_Return

StylCnvSel_HandleOpenItem:
	ld wa, 0:i3

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
	ld (0x3d04:16), ix

StylCnvSel_OK_LoadSelection:
	ld bc, (0x3d04:16)

StylCnvSel_OK_UpdateDisplay:
	cp iz, bc
	jrl z, StylCnvSel_Return
	extz xbc
	div bc, 0x14
	ldto_werp DE, 0xe6
	extz xde
	ld xwa, 0x150002
	ld xbc, EVT_SET_SELECTED_LINE
	call ApPostEvent
	ld de, (0x3d04:16)
	ld bc, de
	extz xbc
	div bc, 0x14
	ld wa, iz
	extz xwa
	div wa, 0x14
	cp wa, bc
	jrl nz, StylCnvSel_OK_PageRedraw
	mul iz, 0x25
	lda xbc, (0x55e4:16)
	ld de, iz
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	ld wa, (0x3d04:16)
	mul wa, 0x25
	lda xbc, (0x55e4:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld xwa, 0x150002
	ld xbc, EVT_PARA_DRAW
	call ApPostEvent
	jrl StylCnvSel_Return

StylCnvSel_OK_ScrollUp:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, (0x3d04:16)
	cp wa, 0:i3
	jrl z, StylCnvSel_OK_LoadSelection
	dec 1, wa
	ld (0x3d04:16), wa
	ld bc, wa
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_ScrollDown:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld bc, (0x3a82:16)
	dec 1, bc
	ld wa, (0x3d04:16)
	cp wa, bc
	jrl nc, StylCnvSel_OK_LoadSelection
	inc 1, wa
	ld (0x3d04:16), wa
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
	ldto_werp WA, 0xea
	cp wa, 0:i3
	jrl z, StylCnvSel_OK_LoadSelection
	ld (0x3d04:16), bc
	jrl StylCnvSel_OK_UpdateDisplay

StylCnvSel_OK_SelectItem:
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld wa, (0x3d04:16)
	inc 1, a
	ld (0x0ffc01:24), a
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvSel_Return

StylCnvSel_OK_PageRedraw:
	ld bc, (0x3a82:16)
	ldw wa, 0x14

StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	ld xhl, 0:i3
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, StylCnvCont_HandleOK
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, AccRhythm_ReturnZero
	cp xde, 0x3
	jr z, StylCnvCont_HandleClose
	cp xde, 0x8
	jrl z, AccRhythm_ReturnZero
	cp xde, 0x2
	jrl nz, AccRhythm_ReturnZero
	cp (0x48d6:16), 0
	jr z, StylCnvCont_CheckPending
	ld (GLOBAL_ERROR_CODE:16), 15
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld (0x48d6:16), 0

StylCnvCont_CheckPending:
	cp (0x48da:16), 0
	jr z, AccRhythm_ReturnZero
	ld (GLOBAL_ERROR_CODE:16), 74
	ldw wa, 0xee
	call SoundCtrl_SendCommand
	ld (0x48da:16), 0
	jr AccRhythm_ReturnZero

StylCnvCont_HandleClose:
	cp (CURRENT_MODE:16), 6
	jr z, AccRhythm_ReturnZero
	calr Display_RestoreEntry
	jr AccRhythm_ReturnZero

StylCnvCont_HandleOK:
	cp xde, 0xb
	jr z, StylCnvCont_NotifyPart
	cp xde, 0xa
	jr nz, AccRhythm_ReturnZero
	ld (0x3d06:16), 0
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
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
	ld wa, 1:i3
	call UI_PostPartChangeEvent

AccRhythm_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvStorTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, StylCnvStor_ReturnZero
	cp xde, 0x3
	jr z, StylCnvStor_HandleClose
	ld xhl, 0:i3
	ret

StylCnvStor_HandleClose:
	cp (CURRENT_MODE:16), 6
	call nz, (Display_RestoreEntry:24)

StylCnvStor_ReturnZero:
	ld xhl, 0:i3
	ret

MainStylCnvFunc:
	extz de
	ld wa, de
	calr AccBankData_ProcessWithCopy
	ld xhl, 0:i3
	ret

StylCnv_ReportErrorAndReturn:
	ld (0x48da:16), 255
	ldw wa, 0x10
	jp UI_PostModeChangeEvent

FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	ld a, (0x0ffc00:24)
	cp a, 0:i3
	jr nz, StylCnvDisp_CheckFE
	cpw (0x48ac:16), 1
	jr nz, StylCnvDisp_PostMode13
	calr AccBankData_InitAllSlots
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	jrl StylCnv_Epilogue114

StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	cp a, 0xfe
	jr nz, StylCnvDisp_CheckType
	ld (0x48da:16), 255
	ldw wa, 0x16
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckType:
	cp a, 3:i3
	jrl z, StylCnv_Multi_InitAndClear
	cp a, 4:i3
	jrl z, StylCnv_DispatchByType
	cp a, 2:i3
	jr z, StylCnvDisp_Type2_CheckSubtype
	lda xbc, (0x3d68:16)
	cp a, 1:i3
	jr z, StylCnvDisp_Type1_CopyPath
	cp a, 5:i3
	jrl nz, StylCnv_AbortWithError
	ld xwa, 0xffc01
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld (0x3d06:16), 5
	ldw wa, 0x14
	jrl StylCnv_PostModeChange

StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xffc01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	ld a, (0x0ffc01:24)
	cp a, 0x40
	jrl z, StylCnv_Type4_Init
	cp a, 0x80
	jr z, StylCnvDisp_Subtype80_Process
	cp a, 0x10
	jr z, StylCnvDisp_Subtype10_Process
	cp a, 0:i3
	jrl nz, StyleConv_DispatchSoundMemState
	ld (0x3d06:16), 1
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	lda xbc, (0x3d08:16)
	ld (xbc), 0x2
	ld (xbc + 1), 0x0
	ld xwa, 0xffc02
	push xwa
	lda xwa, (xbc + 2)
	push xwa
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Subtype10_Process:
	ld (0x3d06:16), 2
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	ld xwa, 0xffc00
	push xwa
	lda xwa, (0x3d08:16)
	push xwa

StylCnvDisp_CopyAndFinalize:
	call Strcpy
	inc 8, xsp
	jrl StylCnv_ClearAndFinalize

StylCnvDisp_Subtype80_Process:
	cp (0x0ffc02:24), 0x2e
	jrl nz, ControlState_Type3
	ld (0x3d06:16), 6
	calr StyleBuf_ClearAllEntries
	calr StyleConv_ClearWorkBuffer
	ldw (xsp + 4), 0x0
	ldw (0x48d8:16), 0

StylCnvDisp_ScanFileLoop:
	pushw 0x3
	pushw StylCnv_Str_Stars@hi16
	pushw StylCnv_Str_Stars@lo16
	ld wa, (xsp + 10)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	call String_Compare
	add xsp, 0xa
	cp hl, 0:i3
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
	incw 1, (0x48d8:16)
	jr StylCnv_ParseEntry_NextField

StylCnv_ParseEntry_StoreChar:
	ld bc, (0x48d8:16)
	sll bc, 5
	ld de, (xsp + 6)
	add de, bc
	lda xbc, (0x3f88:16)
	extz xde
	add xde, xbc
	ld (xde), a
	incw 1, (xsp + 6)
	incw 1, (xsp + 4)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_ParseEntry_ScanChar

StylCnv_ParseEntry_NextField:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x80
	jrl lt, StylCnvDisp_ScanFileLoop

StylCnv_ParseEntry_Done:
	ldw (xsp + 4), 0x0
	ld ix, (0x3d04:16)
	mul ix, 0x25
	lda xhl, (0x55e4:16)

StylCnv_CopyNameLoop:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld c, (xwa + 1)
	cp c, 0x2e
	jr z, StylCnv_CopyName_Finalize
	lda xde, (0x488c:16)
	ld wa, (xsp + 4)
	ld	(xde+wa), c
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_CopyNameLoop

StylCnv_CopyName_Finalize:
	pushw 0x0
	pushw 0x3f88
	pushw 0x0
	pushw 0x488c
	jrl StylCnv_AppendAndClear

ControlState_Type3:
	ld (0x3d06:16), 3
	ld xwa, 0xffc00
	call ControlState_ProcessCommand
	jrl StylCnv_ClearAndFinalize

StylCnv_Type4_Init:
	ld (0x3d06:16), 4
	lda xde, (0x48b6:16)
	ld xwa, xde
	lda xbc, (xde + 32)

StylCnv_Type4_ClearLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StylCnv_Type4_ClearLoop
	ldw (xsp + 4), 0x0
	ld iz, 0:i3

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
	cp c, 0:i3
	jr z, LoopIndex_Reset
	ld wa, (xsp + 6)
	ld	(xde+wa), c
	incw 1, (xsp + 4)
	incw 1, (xsp + 6)
	cpw (xsp + 4), 0x28
	jr lt, StylCnv_Type4_CopyChars

LoopIndex_Reset:
	ldw (xsp + 6), 0x0

StylCnv_Type4_FindDot:
	ld wa, (xsp + 6)
	cp	(xde+wa), 0x2e
	jr z, StylCnv_Type4_CalcExtLen
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type4_FindDot

StylCnv_Type4_CalcExtLen:
	ldw (xsp + 16), 0x0

StylCnv_Type4_CountExt:
	ld wa, (xsp + 6)
	cp	(xde+wa), 0x00
	jr z, StylCnv_Type4_CalcCenter
	incw 1, (xsp + 16)
	incw 1, (xsp + 6)
	cpw (xsp + 16), 0x20
	jr lt, StylCnv_Type4_CountExt

StylCnv_Type4_CalcCenter:
	ld wa, (xsp + 16)
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xe2
	ldiw_erp 0xfa, 1
	cp wa, 0:i3
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
	incw 1, (xsp + 4)
	pushw 0x4
	ld wa, (xsp + 6)
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	pushw 0x0
	pushw 0x48ae
	call Mem_Copy
	incw 4, (xsp + 14)
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
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jrl lt, StylCnv_Type4_MainLoop

StylCnv_Type4_BuildOutput:
	calr StyleConv_ClearWorkBuffer
	ldw (xsp + 4), 0x0
	ld ix, (0x3d04:16)
	mul ix, 0x25
	lda xhl, (0x55e4:16)

StylCnv_Type4_CopyNameLoop2:
	ld wa, (xsp + 4)
	add wa, ix
	extz xwa
	add xwa, xhl
	ld e, (xwa + 1)
	lda xbc, (0x488c:16)
	cp e, 0x2e
	jr z, StylCnv_Type4_AppendExt
	ld wa, (xsp + 4)
	ld	(xbc+wa), e
	incw 1, (xsp + 4)
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
	ld (0x0ffc00:24), 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	ld a, (0x3d06:16)
	cp a, 6:i3
	jrl z, StylCnv_Type6_Dispatch
	cp a, 4:i3
	jrl z, StylCnv_Type4_OpenFile
	cp a, 3:i3
	jr z, StylCnv_Type3_ProcessFiles
	cp a, 2:i3
	jr z, StylCnv_Type2_CheckSoundMem
	cp a, 1:i3
	jrl nz, StyleConv_DispatchSoundMemState
	cp (CURRENT_TITLE:16), 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type2_CheckSoundMem:
	cp (CURRENT_TITLE:16), 22
	jrl nz, StylCnv_Epilogue114
	ldw wa, 0x12
	jrl StylCnv_PostModeChange

StylCnv_Type3_ProcessFiles:
	ld xwa, (0x3d5c:16)
	ld (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	calr StyleConv_ClearEntryTables
	calr StyleFile_ClearAllTables
	ld xwa, 0x488c
	ld xbc, 0x4888
	call FileIO_SearchStringMatch
	cp hl, 0:i3
	jr lt, StylCnv_Type3_CheckCount

StylCnv_Type3_SearchLoop:
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Type3_SearchNext
	ld xwa, (0x4888:16)
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
	lda xbc, (0x48dc:16)
	extz xwa
	add xwa, xbc
	push xwa
	call Strcpy
	lda xsp, (xsp + 24)
	ld de, (xsp + 4)
	sll de, 2
	lda xbc, (0x555c:16)
	extz xde
	add xde, xbc
	ld xwa, (0x4888:16)
	ld (xde), xwa
	incw 1, (xsp + 4)

StylCnv_Type3_SearchNext:
	ld xwa, 0x488c
	ld xbc, 0x4888
	call FileIO_SearchStringMatch
	cp hl, 0:i3
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
	lda xbc, (0x48dc:16)
	extz xwa
	add xwa, xbc
	push xwa
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 18)
	ld xbc, StylCnv_ModeRb_Type3
	call FileIO_OpenWithBuiltPath
	cp hl, 0:i3
	jrl lt, StylCnv_AbortWithError
	ld wa, (xsp + 8)
	sll wa, 2
	lda xbc, (0x555c:16)
	extz xwa
	add xwa, xbc
	ld xbc, (xwa)
	ld (0x4888:16), xbc
	ld xwa, (xsp + 10)
	call FileIO_ReadBlock
	cp xhl, 0x0
	jrl lt, FileIO_ErrorExit
	ld bc, (xsp + 8)
	sll bc, 2
	lda xwa, (0x4788:16)
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ld xwa, (0x4888:16)
	add (xsp + 10), xwa
	ld xwa, (xsp + 10)
	ld (0x3d60:16), xwa
	pushw 0x2e
	lda xwa, (xsp + 20)
	push xwa
	call Sprintf_StringLength
	inc 6, xsp
	ld wa, (xsp + 8)
	lda xbc, (0x3f88:16)
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
	incw 1, (xsp + 8)
	ld wa, (xsp + 8)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_LoadFileLoop

StylCnv_Type3_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	ldw (xsp + 16), 0x0
	ldiw_erp 0xfa, 0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Type3_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 18)
	sll bc, 2
	lda xwa, (0x4788:16)
	extz xbc
	add xbc, xwa
	push xbc
	ldto_werp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc4w_erp 0xfa
	ld iz, 0:i3
	ld bc, (xsp + 16)
	sll bc, 5
	lda xde, (0x3f88:16)

StylCnv_Type3_CopyNameChars:
	ld wa, iz
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0:i3
	jr z, StylCnv_Type3_TerminateName
	ldto_werp HL, 0xfa
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc1w_erp 0xfa
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type3_CopyNameChars

StylCnv_Type3_TerminateName:
	ldto_werp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa
	ld wa, iz
	exts xwa
	divs wa, 0x2
	ldto_werp WA, 0xe2
	cp wa, 0:i3
	jr nz, StylCnv_Type3_NextBlock
	ldto_werp WA, 0xfa
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc1w_erp 0xfa

StylCnv_Type3_NextBlock:
	incw 1, (xsp + 16)
	ld wa, (xsp + 16)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type4_OpenFile:
	ld xwa, 0x488c
	ld xbc, StylCnv_ModeRb_Type4
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jr lt, StylCnv_AbortWithError
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
	jr lt, FileIO_ErrorExit
	call FileIO_SeekWriteBlock_Impl
	ld (0x3d64:16), xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, (0x48ae:16)
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
	jr lt, FileIO_ErrorExit
	ld xwa, (0x3d5c:16)
	ld xbc, (0x48b2:16)
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
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	pushw 0x4
	pushw 0x0
	pushw 0x3d5c
	ld xwa, 0xffc02
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldw (xsp + 4), 0x0
	lda xde, (0x48b6:16)

StylCnv_Type4_CopyFieldLoop:
	ld bc, (xsp + 4)
	inc 6, bc
	extz xbc
	add xbc, 0xffc00
	ld wa, (xsp + 4)
	inc 1, wa
	ld	a, (xde+wa)
	ld (xbc), a
	cp a, 0:i3
	jrl z, StylCnv_FinalizeAndCheckStatus
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyFieldLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_Dispatch:
	ld wa, (0x48ac:16)
	cp wa, 1:i3
	jrl z, StylCnv_Type6_Case1_CopyName
	cp wa, 0:i3
	jrl nz, StyleConv_DispatchSoundMemState
	lda xwa, (0x4788:16)
	ld xbc, xwa
	lda xde, (xwa+256)

StylCnv_Type6_ClearRegion:
	ld xwa, 0:i3
	ld (xbc+), XWA
	cp xbc, xde
	jr c, StylCnv_Type6_ClearRegion
	ld xwa, (0x3d5c:16)
	ld (0x3d60:16), xwa
	ldw (xsp + 4), 0x0
	cpw (0x48d8:16), 0
	jrl ule, StylCnv_Type6_BuildFfcBuffer

StylCnv_Type6_MainLoop:
	ld iz, 0:i3
	lda xbc, (0x488c:16)

StylCnv_Type6_FindDot:
	cp	(xbc+iz), 0x2e
	jr z, StylCnv_Type6_ClearRemainder
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_FindDot

StylCnv_Type6_ClearRemainder:
	cp iz, 0x20
	jr ge, StylCnv_Type6_AppendName

StylCnv_Type6_ClearLoop:
	ld	(xbc+iz), 0x00
	inc 1, iz
	cp iz, 0x20
	jr lt, StylCnv_Type6_ClearLoop

StylCnv_Type6_AppendName:
	ld de, (xsp + 4)
	sll de, 5
	lda xwa, (0x3f88:16)
	extz xde
	add xde, xwa
	push xde
	push xbc
	call Strcat
	inc 8, xsp
	ld xwa, 0x488c
	ld xbc, StylCnv_ModeRb_Type6
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, StylCnv_Type6_FileOpenError
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
	jrl lt, StylCnv_Type6_FileReadError
	call FileIO_SeekWriteBlock_Impl
	ld (0x3d64:16), xhl
	call FileIO_SeekRead_ExtReturn
	ld xwa, (0x3d60:16)
	ld xbc, (0x3d64:16)
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp xhl, 0x0
	jrl lt, StylCnv_AbortWithError
	ld bc, (xsp + 4)
	sll bc, 2
	lda xwa, (0x4788:16)
	extz xbc
	add xbc, xwa
	ld xwa, (0x3d60:16)
	ld (xbc), xwa
	ld xwa, (0x3d64:16)
	add (0x3d60:16), xwa

StylCnv_Type6_AdvanceEntry:
	incw 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (0x48d8:16)
	jrl c, StylCnv_Type6_MainLoop

StylCnv_Type6_BuildFfcBuffer:
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	ldw (xsp + 4), 0x0
	ld iz, 0:i3
	cpw (0x48d8:16), 0
	jrl ule, StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_CopyBlockLoop:
	ld bc, (xsp + 4)
	sll bc, 2
	lda xde, (0x4788:16)
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
	lda xde, (0x3f88:16)

StylCnv_Type6_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0:i3
	jr z, StylCnv_Type6_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incw 1, (xsp + 6)
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
	ldto_werp WA, 0xe2
	cp wa, 0:i3
	jr nz, StylCnv_Type6_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Type6_NextBlock:
	incw 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (0x48d8:16)
	jrl c, StylCnv_Type6_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_FileReadError:
	ld bc, (xsp + 4)
	sll bc, 5
	lda xwa, (0x3f88:16)
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpw (0x48d8:16), 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_FileOpenError:
	ld bc, (xsp + 4)
	sll bc, 5
	lda xwa, (0x3f88:16)
	extz xbc
	add xbc, xwa
	ld (xbc), 0x0
	cpw (0x48d8:16), 2
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl StylCnv_AbortWithError

StylCnv_Type6_Case1_CopyName:
	ld bc, (0x3d04:16)
	mul bc, 0x25
	lda xwa, (0x55e5:16)
	extz xbc
	add xbc, xwa
	push xbc
	lda xwa, (xsp + 22)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (0x3d5c:16)
	ld (xsp + 10), xwa
	ldw (xsp + 8), 0x0
	lda xwa, (xsp + 18)
	ld xbc, StylCnv_ModeRb_Type6b
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, StylCnv_AbortWithError
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
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
	ld (0x4788:16), xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xwa, (xsp + 18)

StylCnv_Single_FindDot:
	ld bc, (xsp + 4)
	cp	(xwa+bc), 0x2e
	jr z, StylCnv_Single_CopyExtension
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot

StylCnv_Single_CopyExtension:
	ld iz, 0:i3
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Single_RenameTM

StylCnv_Single_CopyExt_Loop:
	ld de, iz
	lda xbc, (0x3f88:16)
	extz xde
	add xde, xbc
	ld bc, (xsp + 4)
	ld	c, (xwa+bc)
	ld (xde), c
	cp c, 0:i3
	jr z, StylCnv_Single_RenameTM
	incw 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_CopyExt_Loop

StylCnv_Single_RenameTM:
	ldw (xsp + 4), 0x0

StylCnv_Single_FindDot2:
	ld bc, (xsp + 4)
	exts xbc
	add xbc, xwa
	incw 1, (xsp + 4)
	cp (xbc), 0x2e
	jr z, StylCnv_Single_WriteTMExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot2

StylCnv_Single_WriteTMExtension:
	ld bc, (xsp + 4)
	ld	(xwa+bc), 0x54
	ld bc, (xsp + 4)
	inc 1, bc
	ld	(xwa+bc), 0x4d
	ld bc, (xsp + 4)
	inc 2, bc
	ld	(xwa+bc), 0x00
	ld xbc, StylCnv_ModeRb_Single
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, DRI_ParseFieldsAndOpenFile
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
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
	ld (0x478c:16), xwa
	ld xwa, (xsp + 14)
	add (xsp + 10), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot:
	ld wa, (xsp + 4)
	cp	(xbc+wa), 0x2e
	jr z, StylCnv_LSW_CopyExtension
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot

StylCnv_LSW_CopyExtension:
	ld iz, 0:i3
	cpw (xsp + 4), 0x20
	jr ge, DRI_ParseFieldsAndOpenFile

StylCnv_LSW_CopyExt_Loop:
	ld de, iz
	add de, 0x20
	lda xwa, (0x3f88:16)
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ld	a, (xbc+wa)
	ld (xde), a
	cp a, 0:i3
	jr z, DRI_ParseFieldsAndOpenFile
	incw 1, (xsp + 4)
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
	incw 1, (xsp + 4)
	cp (xbc), 0x2e
	jr z, StylCnv_LSW_WriteExtension
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot2

StylCnv_LSW_WriteExtension:
	ld bc, (xsp + 4)
	ld	(xwa+bc), 0x4c
	ld bc, (xsp + 4)
	inc 1, bc
	ld	(xwa+bc), 0x53
	ld bc, (xsp + 4)
	inc 2, bc
	ld	(xwa+bc), 0x57
	ld bc, (xsp + 4)
	inc 3, bc
	ld	(xwa+bc), 0x00
	ld xbc, StylCnv_ModeRb_LSW
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, FileLoad_ResetAndStartProcessing
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
	jrl lt, FileLoad_ResetAndStartProcessing
	incw 1, (xsp + 8)
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
	lda xwa, (0x4788:16)
	extz xbc
	add xbc, xwa
	ld xwa, (xsp + 10)
	ld (xbc), xwa
	ldw (xsp + 4), 0x0
	lda xbc, (xsp + 18)

StylCnv_LSW_FindDot3:
	ld wa, (xsp + 4)
	cp	(xbc+wa), 0x2e
	jr z, StylCnv_LSW_CopyExt3
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot3

StylCnv_LSW_CopyExt3:
	ld iz, 0:i3
	cpw (xsp + 4), 0x20
	jr ge, FileLoad_ResetAndStartProcessing

StylCnv_LSW_CopyExt3_Loop:
	ld wa, (xsp + 16)
	sll wa, 5
	ld de, iz
	add de, wa
	lda xwa, (0x3f88:16)
	extz xde
	add xde, xwa
	ld wa, (xsp + 4)
	ld	a, (xbc+wa)
	ld (xde), a
	cp a, 0:i3
	jr z, FileLoad_ResetAndStartProcessing
	incw 1, (xsp + 4)
	inc 1, iz
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_CopyExt3_Loop

FileLoad_ResetAndStartProcessing:
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	ldw (xsp + 4), 0x0
	ld iz, 0:i3
	ld wa, (xsp + 8)
	add wa, 0x1
	jrl le, StylCnv_FinalizeAndCheckStatus

StylCnv_Final_CopyBlockLoop:
	pushw 0x4
	ld bc, (xsp + 6)
	sll bc, 2
	lda xwa, (0x4788:16)
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
	lda xde, (0x3f88:16)

StylCnv_Final_CopyNameChars:
	ld wa, (xsp + 6)
	inc 1, wa
	add wa, bc
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0:i3
	jr z, StylCnv_Final_TerminateName
	ld hl, iz
	inc 2, hl
	extz xhl
	add xhl, 0xffc00
	ld (xhl), a
	inc 1, iz
	incw 1, (xsp + 6)
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
	ldto_werp WA, 0xe2
	cp wa, 0:i3
	jr nz, StylCnv_Final_NextBlock
	ld wa, iz
	inc 2, wa
	extz xwa
	add xwa, 0xffc00
	ld (xwa), 0x0
	inc 1, iz

StylCnv_Final_NextBlock:
	incw 1, (xsp + 4)
	ld wa, (xsp + 8)
	inc 1, wa
	cp (xsp + 4), wa
	jrl lt, StylCnv_Final_CopyBlockLoop

StylCnv_FinalizeAndCheckStatus:
	calr TableData_JumpToEntry
	jrl StyleConv_DispatchSoundMemState

StylCnv_Multi_InitAndClear:
	calr StyleConv_InitEntryTable
	ldw (0x3a82:16), 0
	lda xbc, (xsp + 18)
	ld xwa, xbc
	lda xbc, (xbc + 100)

StylCnv_Multi_ClearLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	ld iz, 0:i3

StylCnv_Multi_ParseLoop:
	lda xbc, (0x3d68:16)
	ld wa, (xsp + 4)
	lda	xhl, (xbc+wa)
	ld e, (xhl)
	lda xbc, (xsp + 18)
	lda xwa, (0x55e4:16)
	ld (xsp + 14), xwa
	cp e, 0:i3
	jr nz, StylCnv_Multi_HandleSeparator
	cp iz, 0:i3
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
	incw 1, (0x3a82:16)
	jr StylCnv_Multi_Finalize

StylCnv_Multi_HandleSeparator:
	cp e, 0x7c
	jr nz, StylCnv_Multi_CopyChar
	ld (xhl), 0x0
	ldw (xsp + 6), 0x0
	inc 1, iz
	cp iz, 1:i3
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
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearSubLoop
	incw 1, (0x3a82:16)
	jr LoopCounter_Increment

StylCnv_Multi_CopyChar:
	cp iz, 0:i3
	jr le, LoopCounter_Increment
	ld wa, (xsp + 6)
	ld	(xbc+wa), e
	ld (xhl), 0x0
	incw 1, (xsp + 6)

LoopCounter_Increment:
	incw 1, (xsp + 4)
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
	cp	hl, 0:i3
	ret	z
	cp	(SWBTWR_PAYLOAD_1:16), 65
	ret	nz
	bit	0, (SWBTWR_PAYLOAD_3:16)
	ret	z
	ld	c, (CURRENT_TITLE:16)
	bit	0, (SWBTWR_PAYLOAD_2:16)
	jr	z, AccStyle_TableDataEntry_Skip
	cp	c, 17
	ret	nz
	ldw	wa, 16
	jr	AccStyle_TableDataEntry_Join
AccStyle_TableDataEntry_Skip:
	ld	a, (0x3d06:16)
	cp	c, 18
	jr	z, AccStyle_TableDataEntry_Skip5
	cp	c, 20
	jr	z, AccStyle_TableDataEntry_Skip2
	cp	c, 16
	ret	nz
	call	FileIO_CheckMediaIsWritable
	cp	hl, 0:i3
	ret	nz
	ldw	wa, 17
	jr	AccStyle_TableDataEntry_Join
AccStyle_TableDataEntry_Skip2:
	cp	a, 2:i3
	jr	z, AccStyle_TableDataEntry_Skip4
	cp	a, 5:i3
	jr	z, AccStyle_TableDataEntry_Skip3
	cp	a, 1:i3
	ret	nz
AccStyle_TableDataEntry_Skip3:
	call	FileIO_CheckMediaIsWritable
	cp	hl, 0:i3
	ret	nz
	ldw	wa, 18
	jr	AccStyle_TableDataEntry_Join
AccStyle_TableDataEntry_Skip4:
	call	FileIO_CheckMediaIsWritable
	cp	hl, 0:i3
	ret	nz
	ldw	wa, 18
	jr	AccStyle_TableDataEntry_Join
AccStyle_TableDataEntry_Skip5:
	cp	a, 2:i3
	jr	z, AccStyle_TableDataEntry_Skip6
	cp	a, 1:i3
	ret	nz
AccStyle_TableDataEntry_Skip6:
	call	FileIO_CheckMediaIsWritable
	cp	hl, 0:i3
	ret	nz
	ld	xwa, 0x3d08
	call	ControlState_ProcessCommand
	ldw	wa, 18
AccStyle_TableDataEntry_Join:
	call	UI_PostModeChangeEvent
	ret
FileIO_ByteBlock_DemoProc1_Helper3:
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+34), c
	ld	(xsp+36), a
	ld	xiy, AccStyle_SlotOrderB
	lda	xix, (xsp+4)
	ldw	bc, 15
	ldirw
	lda	xde, (RHYTHM_PATTERN_BUF_A:24)
	lda	xbc, (SEQ_SONG_SLOTS:24)
	sub	xbc, xde
	ld	xwa, 0x069800
	call	FileIO_ReadBlock
	cp	xhl, 0
	jrl	lt, AccStyle_TableDataEntry_Epilogue
	lda	xbc, (0x069800:24)
	ld	(0x7ae4:16), xbc
	lda	xwa, (RHYTHM_PATTERN_BUF_A:24)
	ld	(0x7ae8:16), xwa
	ld	(0x3950:16), 0
	ld	a, (xbc)
	ldfr_berp	a, 249
	ld	a, (xbc+1)
	ldfr_berp	a, 250
	ld	a, (xbc+2)
	ldfr_berp	a, 251
	cp_erpb	249, 72
	jr	nz, AccStyle_TableDataEntry_Skip7
	cpib_erp	250, 0
	jr	nz, AccStyle_TableDataEntry_Skip7
	cp_erpb	251, 75
	jr	z, AccStyle_TableDataEntry_Skip9
AccStyle_TableDataEntry_Skip7:
	cp_erpb	249, 71
	jr	nz, AccStyle_TableDataEntry_Skip8
	cpib_erp	250, 0
	jr	nz, AccStyle_TableDataEntry_Skip8
	cp_erpb	251, 75
	jr	z, AccStyle_TableDataEntry_Skip9
AccStyle_TableDataEntry_Skip8:
	cp_erpb	249, 76
	jrl	nz, AccStyle_TableDataEntry_Skip15
	cp_erpb	250, 75
	jrl	nz, AccStyle_TableDataEntry_Skip15
	cp_erpb	251, 69
	jrl	nz, AccStyle_TableDataEntry_Skip15
AccStyle_TableDataEntry_Skip9:
	ld	xwa, (0x7ae4:16)
	ld	(xwa), 72
	ld	xwa, (0x7ae4:16)
	ld	(xwa+1), 0
	ld	xwa, (0x7ae4:16)
	ld	(xwa+2), 75
	ld	xbc, (0x7ae8:16)
	cp	(xsp+36), 29
	jrl	ule, AccStyle_TableDataEntry_Skip14
	cp	(xsp+34), 29
	jrl	ule, AccStyle_TableDataEntry_Skip14
	ld	xwa, (0x7ae4:16)
	ld	e, (xwa+14)
	cp	e, 0:i3
	jr	nz, AccStyle_TableDataEntry_Skip10
	cp	(xwa+15), 0
	jr	z, AccStyle_TableDataEntry_Skip11
AccStyle_TableDataEntry_Skip10:
	ld	(xbc+14), e
	ld	xwa, (0x7ae4:16)
	ld	a, (xwa+15)
	ld	(xbc+15), a
AccStyle_TableDataEntry_Skip11:
	cp_erpb	249, 72
	jr	nz, AccStyle_TableDataEntry_Skip12
	cpib_erp	250, 0
	jr	nz, AccStyle_TableDataEntry_Skip12
	cp_erpb	251, 75
	jrl	z, AccStyle_TableDataEntry_Skip13
AccStyle_TableDataEntry_Skip12:
	ld	a, (xsp+36)
	sub	a, 30
	extz	wa
	extz	xwa
	add	xwa, AccStyle_SlotOrderA
	ld	xbc, xwa
	ld	xde, xwa
	ld	xhl, xwa
	ld	xix, xwa
	lda	xiy, (xwa+30)
AccStyle_TableDataEntry_Loop:
	ld	a, (xix)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+34), 64
	ld	a, (xhl)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+42), 12
	ld	a, (xde)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+58), 64
	inc	3, xix
	inc	3, xhl
	inc	3, xde
	inc	3, xbc
	cp	xbc, xiy
	jr	c, AccStyle_TableDataEntry_Loop
AccStyle_TableDataEntry_Skip13:
	ld	a, (xsp+36)
	extz	wa
	ld	c, (xsp+34)
	extz	bc
	calr	AccStyle_TableDataEntry_Helper
AccStyle_TableDataEntry_Join2:
	ld	a, (0x3950:16)
	extz	wa
	bit	0, wa
	jrl	z, AccStyle_TableDataEntry_Join3
	ld	xwa, (0x7ae8:16)
	ld	(0x39ae:16), xwa
	cp	(xsp+34), 30
	jrl	nc, AccStyle_TableDataEntry_Skip21
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	ld	(14764), (xwa+bc)
	call	AccPatch_InitFromSlotIndex
	jrl	AccStyle_TableDataEntry_Join3
AccStyle_TableDataEntry_Skip14:
	cp	(xsp+36), 29
	jr	ule, AccStyle_TableDataEntry_Skip16
	cp	(xsp+34), 30
	jr	c, AccStyle_TableDataEntry_Skip15
AccStyle_TableDataEntry_Skip16:
	cp	(xsp+36), 30
	jr	nc, AccStyle_TableDataEntry_Skip17
	cp	(xsp+34), 29
	jr	ule, AccStyle_TableDataEntry_Skip17
AccStyle_TableDataEntry_Skip15:
	ld	(0x3950:16), 130
	jrl	AccStyle_TableDataEntry_Join4
AccStyle_TableDataEntry_Skip17:
	ld	(0x39ae:16), xbc
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	ld	(14764), (xwa+bc)
	call	AccPatch_InitFromSlotIndex
	cp_erpb	249, 72
	jr	nz, AccStyle_TableDataEntry_Skip18
	cpib_erp	250, 0
	jr	nz, AccStyle_TableDataEntry_Skip18
	cp_erpb	251, 75
	jr	z, AccStyle_TableDataEntry_Skip19
AccStyle_TableDataEntry_Skip18:
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	lda	xbc, (xbc+wa)
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+de)
	ld	(xwa+34), 64
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+de)
	ld	(xwa+42), 12
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+de)
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ld	xwa, (0x7ae4:16)
	lda	xwa, (xwa+bc)
	ld	(xwa+58), 64
AccStyle_TableDataEntry_Skip19:
	ld	xwa, (0x7ae4:16)
	ld	(0x39ae:16), xwa
	ld	xwa, (0x7ae8:16)
	ld	(0x39b2:16), xwa
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	ld	(14764), (xbc+wa)
	ld	a, (xsp+34)
	extz	wa
	ld	(14765), (xbc+wa)
	res	0, (0x35b0:16)
	call	DualVoice_ParamLoadDone
	ld	a, (0x35b0:16)
	extz	wa
	bit	0, wa
	jr	z, AccStyle_TableDataEntry_Skip20
	ld	(0x3950:16), 131
	jrl	AccStyle_TableDataEntry_Join2
AccStyle_TableDataEntry_Skip20:
	ld	(0x3950:16), 0
	jrl	AccStyle_TableDataEntry_Join2
AccStyle_TableDataEntry_Skip21:
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop3:
	ld	c, (xsp+34)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccStyle_SlotOrderA:24)
	ld	(14764), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop3
AccStyle_TableDataEntry_Join3:
	cp	(0x3950:16), 131
	jr	nz, AccStyle_TableDataEntry_Skip22
	ldw	hl, 0xff95
	jr	AccStyle_TableDataEntry_Epilogue
AccStyle_TableDataEntry_Skip22:
	call	AccStyle_TableDataEntry_Helper2
AccStyle_TableDataEntry_Join4:
	ld	hl, 0:i3
AccStyle_TableDataEntry_Epilogue:
	pop	xiz
	lda	xsp, (xsp+34)
	ret
AccStyle_TableDataEntry_Helper:
	dec	4, xsp
	push qiz
	ld	(xsp+2), c
	ld	(xsp+4), a
	ld	xwa, (0x7ae8:16)
	ld	(0x39ae:16), xwa
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop4:
	ld	c, (xsp+2)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccStyle_SlotOrderA:24)
	ld	(14764), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop4
	ld	xwa, (0x7ae4:16)
	ld	(0x39ae:16), xwa
	ld	xwa, (0x7ae8:16)
	ld	(0x39b2:16), xwa
	ld	(0x3950:16), 0
	res	0, (0x35b0:16)
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop2:
	ld	e, (xsp+4)
	sub	e, 30
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (AccStyle_SlotOrderA:24)
	ld	(14764), (xde+wa)
	ld	a, (xsp+2)
	sub	a, 30
	extz	wa
	add	bc, wa
	ld	(14765), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (0x35b0:16)
	extz	wa
	bit	0, wa
	jr	z, AccStyle_TableDataEntry_Skip23
	ld	(0x3950:16), 131
	jr	AccStyle_TableDataEntry_Epilogue2
AccStyle_TableDataEntry_Skip23:
	incb_erp	251, 1
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop2
AccStyle_TableDataEntry_Epilogue2:
	pop qiz
	inc	4, xsp
	ret

	.include "sequencer/accompseq_routines.s"
