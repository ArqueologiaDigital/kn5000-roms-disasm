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
	push	xhl
	push	xwa
	xor	xhl, xhl
	ld	l, (36942:16)
	cp	l, 15
	jr	ule, AccStyle_LookupTempo_ClampL
	xor	l, l
AccStyle_LookupTempo_ClampL:
	sla	l, 1
	ld	xwa, AccStyle_TempoMultiplierTable
	ld	hl, (xwa+l)
	xor	xwa, xwa
	ld	a, (36943:16)
	cp	a, 79
	jr	ule, AccStyle_LookupTempo_AddAndStore
	xor	a, a
AccStyle_LookupTempo_AddAndStore:
	add	xhl, xwa
	sla	xhl, 1
	add	xhl, AccStyle_TempoWordTable
	ld	wa, (xhl)
	ld	(36946:16), a
	ld	(36947:16), w
	pop	xwa
	pop	xhl
	ret
AccStyle_TempoMultiplierTable:
	.byte 0x00, 0x00, 0x14, 0x00, 0x28, 0x00, 0x3c, 0x00
	.byte 0x50, 0x00, 0x64, 0x00, 0x78, 0x00, 0x8c, 0x00
	.byte 0xa0, 0x00, 0xb4, 0x00, 0xc8, 0x00, 0xdc, 0x00
	.byte 0xf0, 0x00, 0x04, 0x01, 0x18, 0x01, 0x68, 0x01

AccStyle_LookupVelocityTable:
	push XHL
	push XWA
	cp (0x904e:16), 0x80
	jr nc, .Lc_f55875
	xor XHL,XHL
	ld l, (0x904e:16)
	sla XHL, 0x03
	xor XWA,XWA
	ld a, (0x904f:16)
	and A,0x07
	add XHL,XWA
	sla XHL, 0x01
	add XHL,AccStyle_VelocityTableMain
	ld WA,(XHL)
	jr t, AccStyle_Velocity_StoreResult
AccStyle_Velocity_ExtendedRange:
.Lc_f55875:
	cp (0x904e:16), 0xf0
	jr nc, AccStyle_Velocity_HighRange
	xor XHL,XHL
	ld l, (0x904e:16)
	and L,0x7f
	cp L,0x0b
	jr ule, AccStyle_Velocity_ExtClamp
	xor L,L
AccStyle_Velocity_ExtClamp:
	sla	xhl, 3
	xor	xwa, xwa
	ld	a, (36943:16)
	and	a, 7
	add	xhl, xwa
	sla	xhl, 1
	add	xhl, AccStyle_VelocityTableExt
	ld	wa, (xhl)
	jr	AccStyle_Velocity_StoreResult
AccStyle_Velocity_HighRange:
	xor	xhl, xhl
	ld	l, (36942:16)
	and	l, 15
	cp	l, 4:i3
	jr	ule, AccStyle_Velocity_HighClamp
	xor	l, l
AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, AccStyle_VelocityTableHigh
	ld wa, (xhl)

AccStyle_Velocity_StoreResult:
	ld	(36946:16), a
	ld	(36947:16), w
	pop	xwa
	pop	xhl
	ret
AccStyle_CheckRecordMode:
	ld a, (0x3255:16)
	cp A,0x0e
	jr nz, AccStyle_CheckRecordReturn
	ld a, (0x8c98:16)
	cp A,0x0e
	jr z, AccStyle_CheckRecordReturn
	or (0x3431:16), 0x80
AccStyle_CheckRecordReturn:
	ret

AccStyle_DetectChanges:
	and (0x329f:16), 0xfe
	bit 0, (0x31e7:16)
	jrl nz, AccStyle_DetectChanges_CompareParams
	bit 1, (0x31e7:16)
	jrl z, AccStyle_DetectChanges_CompareParams
	bit 4, (0x0421:16)
	jr z, .Lc_f55901
	call NoteMap_SendAllNotesOff
AccStyle_DetectChanges_Init:
.Lc_f55901:
	ld (0x3246:16), 0x00
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	call Rhythm_SendChanPressure
	calr Rhythm_SendResetMsg
	and (0x3278:16), 0xc0
	and (0x3279:16), 0xc0
	and (0x3276:16), 0xc0
	and (0x3277:16), 0xc0
	and (0x327a:16), 0xc0
	and (0x327b:16), 0xc0
	and (0x327c:16), 0xc0
	and (0x32c1:16), 0xc0
	and (0x328a:16), 0xc0
	and (0x328b:16), 0xc0
	and (0x31e8:16), 0xe7
	xor A,A
	ld (0x326d:16), a
	ld (0x326e:16), a
	ld (0x326f:16), a
	ld (0x3270:16), a
	ld (0x3271:16), a
	ld (0x3272:16), a
	ld (0x3273:16), a
	ld (0x328f:16), 0x00
	and (0x33d4:16), 0x02
	and (0x328d:16), 0xc0
	ld a, (0xfc5f:16)
	and A,0xfc
	jr z, AccStyle_DetectChanges_QueueDone
	and (0xfc5f:16), 0x03
	ld A, 0x00:opc
	ld W, 0x00:opc
	ld D, 0x05:opc
	ld E, 0x48:opc
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
	; ordi8 0x333b, 1 (v7 patched)
	or	(0x329f:16), 1
AccStyle_DetectChanges_CompareParams:
	bit 0, (0x3257:16)
	jr nz, .Lc_f559c1
	call Rhythm_SendChanPressure
	or (0x329f:16), 0x01
	jrl t, AccStyle_DetectChanges_Epilogue
AccStyle_Compare_StyleNumber:
.Lc_f559c1:
	ld a, (0x3259:16)
	cp	a, (0x325a:16)
	jr	z, AccStyle_Compare_StyleNumDone
	or	(0x329f:16), 1
AccStyle_Compare_StyleNumDone:
	ld	a, (0x325b:16)
	cp	a, (0x325c:16)
	jr	z, AccStyle_Compare_Variation
	or	(0x329f:16), 1
AccStyle_Compare_Variation:
	ld	a, (0x325d:16)
	and	a, 7
	cp	a, (0x325e:16)
	jr	z, AccStyle_Compare_VariationDone
	or	(0x329f:16), 1
AccStyle_Compare_VariationDone:
	bit	7, (0x3431:16)
	jr	z, AccStyle_Compare_RegistrationFlag
	and	(0x3431:16), 127
	or	(0x329f:16), 1
AccStyle_Compare_RegistrationFlag:
	ld	a, (0x3299:16)
	xor	a, (0x3256:16)
	and	a, 2
	cp	a, 0:i3
	jr	z, AccStyle_Compare_SplitA
	or	(0x329f:16), 1
	jr	AccStyle_DetectChanges_Epilogue
AccStyle_Compare_SplitA:
	ld	a, (0x3263:16)
	cp	a, (0x3264:16)
	jr	z, AccStyle_Compare_SplitADone
	or	(0x329f:16), 1
AccStyle_Compare_SplitADone:
	ld	a, (0x3265:16)
	cp	a, (0x3266:16)
	jr	z, AccStyle_Compare_LayerA
	or	(0x329f:16), 1
AccStyle_Compare_LayerA:
	ld	a, (0x3269:16)
	cp	a, (0x326a:16)
	jr	z, AccStyle_Compare_LayerADone
	or	(0x329f:16), 1
AccStyle_Compare_LayerADone:
	ld	a, (0x326b:16)
	cp	a, (0x326c:16)
	jr	z, AccStyle_Compare_TuningState
	or	(0x329f:16), 1
AccStyle_Compare_TuningState:
	ld	a, (0x334c:16)
	xor	a, (0x334d:16)
	bit	0, a
	jr	z, AccStyle_Compare_TuningDone
	or	(0x329f:16), 1
AccStyle_Compare_TuningDone:
	call AccTuning_Toggle

AccStyle_DetectChanges_Epilogue:
	bit 0, (0x329f:16)
	jr z, .Lc_f55a72
	calr AccStyle_ApplyChanges
AccStyle_DetectChanges_ClearFlags:
.Lc_f55a72:
	ld (0x32b8:16), 0x00
	ld (0x32b9:16), 0x00
	ld (0x32c3:16), 0x00
	and (0x32bb:16), 0xfc
	and (0x32c5:16), 0x78

	ret



AccStyle_ApplyChanges:
	calr AccStyle_ResetAllVoiceState
	and (0x31e7:16), 0xfb
	ld (0x0462:16), 0x00
	calr AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	ld a, (0x325b:16)
	and A,0x7f
	and A,0x07
	ld (0x324a:16), a
	ld (0x324c:16), a
	ld a, (0x3259:16)
	ld (0x3249:16), a
	ld (0x324b:16), a
	ld (0x32d4:16), a
	call AccTuning_Init
	cp (0x3249:16), 0x80
	jr nc, AccStyle_ApplyChanges_Extended
	calr AccStyle_ApplyStandardStyle
	jr t, AccStyle_ApplyChanges_Finalize
AccStyle_ApplyChanges_Extended:
	calr AccStyle_ApplyExtendedStyle
	jr AccStyle_ApplyChanges_Finalize

AccStyle_ApplyChanges_Finalize:
	calr	AccBuf_InitKbd1WithMarkers
	ld	a, (1075:16)
	ld	(1112:16), a
	ld	(12880:16), 1
	call	Rhythm_ProcessAllPartsAndLoad
	ret
AccStyle_ResetAllVoiceState:
	xor	wa, wa
	ld	(1045:16), a
	ld	(1046:16), a
	ld	(12771:16), a
	ld	(12772:16), a
	ld	(12769:16), wa
	ld	(12940:16), a
	ld	(12815:16), a
	ld	(12816:16), a
	ld	(12821:16), a
	ld	(12817:16), a
	ld	(12818:16), a
	ld	(12819:16), a
	ld	(12820:16), a
	ld	(1076:16), a
	ld	(1077:16), a
	ld	(12824:16), a
	ld	(12825:16), a
	ld	(12826:16), a
	ld	(12831:16), a
	ld	(12827:16), a
	ld	(12828:16), a
	ld	(12829:16), a
	ld	(12830:16), a
	ld	(12977:16), a
	ld	(12833:16), a
	ld	(12834:16), a
	ld	(12835:16), a
	ld	(12836:16), a
	ld	(12837:16), a
	ld	(12838:16), a
	ld	(13033:16), a
	ld	(13034:16), a
	ld	(13035:16), a
	ld	(13036:16), a
	ld	(13037:16), a
	ld	(13038:16), a
	call	AccTone_CallWithSaveAll
	ret
AccStyle_ApplyStandardStyle:
	ld	a, (12905:16)
	and	a, 3
	ld	(12956:16), a
	ld	(12958:16), a
	ld	a, (12873:16)
	ld	h, (12874:16)
	call	AccVoice_LookupWithOffset
	ld	(12850:16), xiy
	call	AccVoice_SelectAndApplyPatch
	call	AccVoice_ReadBankAssign
	ld	xiy, (12850:16)
	call	Rhythm_UpdateTuningConfig
	ld	xiy, (12850:16)
	ld	a, (12899:16)
	and	a, 7
	jr	z, AccStyle_ApplyStd_LoadTuning
	calr	AccVoice_SelectPartOffset
	jr	AccStyle_ApplyStd_Return
AccStyle_ApplyStd_LoadTuning:
	calr AccStyle_SetupPartAddresses

	ld a, (12807:16)

	ld w, 0x0:opc

	; calr AccPart_GetVoiceParamOffsetTable (v7 displacement)
	calr	AccPart_GetVoiceParamOffsetTable
	; call AccVoice_LoadTuningBlock (v7 addr)
	call	AccVoice_LoadTuningBlock
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	ld	a, (xiy+977)
	ld	(0x31e9:16), a
	ld	(0x3338:16), 1
	ld	a, (0x3207:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31eb:16), wa
	ld	(0x3338:16), 2
	ld	a, (0x3208:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31ed:16), wa
	ld	(0x3338:16), 4
	ld	a, (0x3209:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31ef:16), wa
	ld	(0x3338:16), 8
	ld	a, (0x320a:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f1:16), wa
	ld	(0x3338:16), 16
	ld	a, (0x320b:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f3:16), wa
	ld	(0x3338:16), 32
	ld	a, (0x320c:16)
	calr	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f5:16), wa
	ld	xwa, AccStyle_DefaultStream
	add	xwa, 6
	ld	(0x31f7:16), xwa
	and	(0x327a:16), 192
	and	(0x327b:16), 192
	and	(0x327c:16), 192
	ret
AccStyle_ApplyExtendedStyle:
	ld	xiy, AccStyle_ExtStyleMap
	ld	a, (12873:16)
	and	a, 127
	cp	a, 29
	jr	ule, AccStyle_ApplyExt_ClampIndex
	xor	a, a
AccStyle_ApplyExt_ClampIndex:
	ld	a, (xiy+a)
	ld	(12956:16), a
	ld	a, (12873:16)
	and	a, 127
	call	AccVoice_ResolveParamAddr
	ld	(12850:16), xiy
	ld	l, (xiy+16)
	ld	h, (xiy+17)
	and	h, 15
	and	h, 7
	cp	hl, 520
	jr	z, AccStyle_ApplyExt_SkipClamp
	cp	hl, 792
	jr	z, AccStyle_ApplyExt_SkipClamp
	call	VoiceParam_ClampAndValidate
AccStyle_ApplyExt_SkipClamp:
	ld	a, l
	call	AccVoice_LookupWithOffset
	ld	(12855:16), xiy
	call	AccVoice_SelectAndApplyPatch
	ld	w, (12873:16)
	call	AccPatch_SetByChordIndex
	bit	0, (0x32c7:16)
	jr	nz, AccStyle_ApplyExt_CheckSplit
	call	AccPedal_ProcessAllChanges
AccStyle_ApplyExt_CheckSplit:
	ld	a, (12899:16)
	and	a, 7
	jrl	z, Seq_ProcessAndContinue
	bit	0, (0x32c7:16)
	jrl	z, AccStyle_ApplyExt_SelectPart
	bit	1, (0x3263:16)
	jr	z, AccStyle_ApplyExt_CheckBit0
	ld	a, (1075:16)
	ld	xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri	0, 0x03, 0xec, 0xe0
	jr	z, AccStyle_ApplyExt_SelectPart
	and	(0x3263:16), 253
	and	(0xfc5f:16), 247
	ld	e, 72:opc
	ld	d, 5:opc
	ld	a, 0:opc
	ld	w, 0:opc
	call	Rhythm_QueuePartChangeEvent
	jr	Seq_ProcessAndContinue
AccStyle_ApplyExt_CheckBit0:
	bit	0, (0x3263:16)
	jr	z, AccStyle_ApplyExt_CheckBit1
	ld	a, (13000:16)
	cp	a, (1075:16)
	jr	z, AccStyle_ApplyExt_UseSecondary
	and	(0x3263:16), 254
	and	(0xfc5f:16), 251
	ld	e, 72:opc
	ld	d, 5:opc
	ld	a, 0:opc
	ld	w, 0:opc
	call	Rhythm_QueuePartChangeEvent
	jr	Seq_ProcessAndContinue
AccStyle_ApplyExt_CheckBit1:
	ld	a, (13002:16)
	cp	a, (1075:16)
	jr	z, AccStyle_ApplyExt_UseSecondary
	and	(0x3263:16), 251
	and	(0xfc60:16), 251
	ld	e, 72:opc
	ld	d, 5:opc
	ld	a, 0:opc
	ld	w, 0:opc
	call	Rhythm_QueuePartChangeEvent
	jr	Seq_ProcessAndContinue
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
	ld	xiy, (12855:16)
	calr	AccVoice_SelectPartOffset
AccStyle_ApplyExt_UpdateTuning:
	ld	xiy, (12855:16)
	calr	Rhythm_UpdateTuningConfig
	ret
AccVoice_SelectPartOffset:
	ldw HL, 0x0020
	bit 0, (0x3263:16)
	jr nz, .Lc_f55d98
	ldw HL, 0x0022
	bit 1, (0x3263:16)
	jr nz, .Lc_f55d98
	ldw HL, 0x0420
AccVoice_SelectPartOffset_Resolved:
.Lc_f55d98:
	calr AccStyle_SetupPartAddressesByHL
	cp (0x3249:16), 0x80
	jr c, .Lc_f55dac
	ld xiy, (0x3232:16)
	call AccTuning_CopyAllPartsFromStyle
	jr t, AccVoice_SelectPartOffset_Apply63
AccVoice_SelectPartOffset_Bound:
.Lc_f55dac:
	ld a, (0x3207:16)
	ld W, 0x03:opc
	bit 2, (0x3263:16)
	jr z, AccVoice_SelectPartOffset_SetModeW
	ld W, 0x04:opc
AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	or	(0x3290:16), 63
	bit	0, (0x3263:16)
	jr	z, AccVoice_SelectPartOffset_Bit1
	or	(0x327a:16), 63
	and	(0x327b:16), 192
	and	(0x327c:16), 192
	jr	AccVoice_SelectPartOffset_Return
AccVoice_SelectPartOffset_Bit1:
	bit	1, (0x3263:16)
	jr	z, AccVoice_SelectPartOffset_Mode3
	and	(0x327a:16), 192
	or	(0x327b:16), 63
	and	(0x327c:16), 192
	jr	AccVoice_SelectPartOffset_Return
AccVoice_SelectPartOffset_Mode3:
	; anddi8 (0x3316), 192 (v7 patched)
	and	(0x327a:16), 192
	; anddi8 (0x3317), 192 (v7 patched)
	and	(0x327b:16), 192
	; ordi8 0x3318, 63 (v7 patched)
	or	(0x327c:16), 63
AccVoice_SelectPartOffset_Return:
	ret

AccStyle_SetupPartAddressesByHL:
	.byte 0xc3, 0xf5, 0xd1, 0x03, 0x21, 0xf1, 0xe9, 0x31
	.byte 0x41, 0xd7, 0x3c, 0x9b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x01, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xeb, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x02, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xed, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x04, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xef, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x08, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf1, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x10, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf3, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x20, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf5, 0x31
	.byte 0x50, 0x40, 0xb9, 0x6b, 0xe4, 0x00, 0xe8, 0xc8
	.byte 0x06, 0x00, 0x00, 0x00, 0xf1, 0xf7, 0x31, 0x60
	.byte 0x0e
AccStyle_UseSecondarySource:
	ld a, (0x32c9:16)
	bit 0, (0x3263:16)
	jr nz, .Lc_f55e8b
	ld a, (0x32cb:16)
AccStyle_UseSecondary_Resolve:
.Lc_f55e8b:
	call AccVoice_ResolveParamAddr
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	or (0x3290:16), 0x3f
	bit 0, (0x3263:16)
	jr z, .Lc_f55eb2
	or (0x327a:16), 0x3f
	and (0x327b:16), 0xc0
	and (0x327c:16), 0xc0
	jr t, AccStyle_UseSecondary_Return
AccStyle_UseSecondary_Mode3:
.Lc_f55eb2:
	and (0x327a:16), 0xc0
	and (0x327b:16), 0xc0
	or (0x327c:16), 0x3f



AccStyle_UseSecondary_Return:
	ret


; -----------------------------------------------------------------------------
; Section: Accompaniment Part Management
; -----------------------------------------------------------------------------
; Part position initialization, buffer reset, tuning
; configuration, and style index lookup.
; -----------------------------------------------------------------------------

AccPart_InitPositionsAndBase:
	call	AccInit_AllPartPositions
	ld	xwa, AccStyle_DefaultStream
	add	xwa, 6
	ld	(12791:16), xwa
	ret
AccPart_ResetAndCopyTuning:
	ld xiy, (0x3232:16)
	calr AccPart_InitPositionsAndBase
	call AccTuning_CopyAllPartsFromStyle
	or (0x3290:16), 0x3f
	and (0x327a:16), 0xc0
	and (0x327b:16), 0xc0
	and (0x327c:16), 0xc0
	ret
AccBuf_ResetAllPositions:
	ld	xhl, 10744
	call	AccBuf_ResetOnePosition
	ld	xhl, 11000
	call	AccBuf_ResetOnePosition
	ld	xhl, 11256
	call	AccBuf_ResetOnePosition
	ld	xhl, 11512
	call	AccBuf_ResetOnePosition
	ld	xhl, 11768
	call	AccBuf_ResetOnePosition
	ld	xhl, 12024
	call	AccBuf_ResetOnePosition
	ret
AccBuf_InitKbd1WithMarkers:
	ld XHL,0x000029f8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	ld	(xhl+iy), 0xd0
	call	RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x01
	call	RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x10
	call	RingBuf_AdvanceIndex
	ld	(xhl+iy), 0x01
	call	RingBuf_AdvanceIndex
	ld	(xhl+4), iy
	ret
Rhythm_SendResetMsg:
	ld a, 0xd8:opc
	ld w, 0x10:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	ld	w, (12860:16)
	ld	a, (12956:16)
	calr	Rhythm_LookupTuningByStyle
	ld	(12807:16), a
	ld	(12808:16), a
	ld	(12809:16), a
	ld	(12810:16), a
	ld	(12811:16), a
	ld	(12812:16), a
	ld	w, (12860:16)
	ld	a, (12956:16)
	calr	Rhythm_LookupTuningRange
	ret
Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, Rhythm_LookupTuningByStyle_Data
	ld	a, (xhl+a)
	ret

Rhythm_LookupTuningRange:
	cp (0x3249:16), 0x80
	jr nc, Rhythm_LookupTuning_DefaultRange
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld XHL,Rhythm_LookupTuningRange_Data
	sla A, 0x01
	ld	hl, (xhl+a)
	ld	wa, (xiy+hl)
	jr	Rhythm_StoreTuningRange
Rhythm_LookupTuning_DefaultRange:
	ld a, 0x39:opc
	ld w, 0x39:opc

Rhythm_StoreTuningRange:
	ld	(12963:16), a
	ld	(12964:16), w
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
; ** v7: typed as in v10 (the 115 bytes are identical in both ROMs) -- lane accomp
;    2026-09-25, scripts/converters/lane_accomp_port_typed_v10_to_v7.py.
; (this lane's third re-frame pass had read four bank-register instructions
;  into +0x04..+0x25 here; that reading is withdrawn with this typing.)
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
	ld	xhl, AccStyle_ReadParamOffset_Data
	sla	w, 1
	ld	hl, (xhl+w)
	extz	xhl
	add	xhl, xiy
	cp	(0x3338:16), 1
	jr	nz, AccStyle_ReadParamOff_Part2
	ld	w, (xhl+0:8)
	jr	AccStyle_ReadParamRet
AccStyle_ReadParamOff_Part2:
	cp	(0x3338:16), 2
	jr	nz, AccStyle_ReadParamOff_Part4
	ld	w, (xhl+0:8)
	jr	AccStyle_ReadParamRet
AccStyle_ReadParamOff_Part4:
	cp	(0x3338:16), 4
	jr	nz, AccStyle_ReadParamOff_Part8
	ld	w, (xhl+40)
	jr	AccStyle_ReadParamRet
AccStyle_ReadParamOff_Part8:
	cp	(0x3338:16), 8
	jr	nz, AccStyle_ReadParamOff_Part16
	ld	w, (xhl+80)
	jr	AccStyle_ReadParamRet
AccStyle_ReadParamOff_Part16:
	cp	(0x3338:16), 16
	jr	nz, AccStyle_ReadParamOff_Part32
	ld	w, (xhl+120)
	jr	AccStyle_ReadParamRet
AccStyle_ReadParamOff_Part32:
	ld	w, (xhl+160)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 114 of 138 slots byte-identical
	ld	xhl, AccStyle_ReadParamOffset_Data
	sla	a, 1
	ld	hl, (xhl+a)
	extz	xhl
	add	xhl, xiy
	; v10 does not spell this byte either
	cp	(0x3338:16), 1
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOff_Part16_Code_Entry
	ld	a, (xhl+20)
	jr	AccStyle_ReadParamOff_Part16_Code_Return
AccStyle_ReadParamOff_Part16_Code_Entry:
	; v10 does not spell this byte either
	cp	(0x3338:16), 2
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOff_Part16_Code_Entry2
	ld	a, (xhl+20)
	jr	AccStyle_ReadParamOff_Part16_Code_Return
AccStyle_ReadParamOff_Part16_Code_Entry2:
	; v10 does not spell this byte either
	cp	(0x3338:16), 4
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOffset_Skip
	; v10 does not spell this byte either
	ld	a, (xhl+60)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	jr	AccStyle_ReadParamOff_Part16_Code_Return
	; v10 does not spell this byte either
	; v10 does not spell this byte either
AccStyle_ReadParamOffset_Skip:
	cp	(0x3338:16), 8
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOffset_Skip2
	ld	a, (xhl+100)
	jr	AccStyle_ReadParamOff_Part16_Code_Return
	; v10 does not spell this byte either
AccStyle_ReadParamOffset_Skip2:
	cp	(0x3338:16), 16
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOffset_Skip3
	ld	a, (xhl+140)
	jr	AccStyle_ReadParamOff_Part16_Code_Return
	; v10 does not spell this byte either
AccStyle_ReadParamOffset_Skip3:
	cp	(0x3338:16), 32
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	jr	nz, AccStyle_ReadParamOff_Part16_Code_Return
	ld	a, (xhl+180)
AccStyle_ReadParamOff_Part16_Code_Return:
	ret
; (v7: the routine's final `ret` carries the label AccStyle_ReadParamOff_Part16_Code_Return.)
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
; readers in v7 (address from the linked ELF): AccStyle_ReadParamOffset 0xF56197,
;     AccPart_LookupBoundVoiceParam 0xF5617A
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
; -- comments that sat inside this range before the re-type, in order:
	; v10 does not spell this byte either
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
	cp A,0x0f
	jr nc, .Lc_f562c9
	ldw HL, 0x0018
	bit 0, (0x326d:16)
	jr nz, AccVoice_ReturnExtHL
	ldw HL, 0x001a
	jr t, AccVoice_ReturnExtHL
AccVoice_ParamAddr_Range0F_14:
.Lc_f562c9:
	cp A,0x14
	jr nc, .Lc_f562dc
	ldw HL, 0x001c
	bit 0, (0x326d:16)
	jr nz, AccVoice_ReturnExtHL
	ldw HL, 0x001e
	jr t, AccVoice_ReturnExtHL
AccVoice_ParamAddr_Range14_23:
.Lc_f562dc:
	cp A,0x23
	jr nc, .Lc_f562ef
	ldw HL, 0x0418
	bit 0, (0x326d:16)
	jr nz, AccVoice_ReturnExtHL
	ldw HL, 0x041a
	jr t, AccVoice_ReturnExtHL
AccVoice_ParamAddr_Range23Plus:
.Lc_f562ef:
	ldw HL, 0x041c
	bit 0, (0x326d:16)
	jr nz, AccVoice_ReturnExtHL
	ldw HL, 0x041e
AccVoice_ReturnExtHL:
	extz xhl
	ret

AccTuning_SetAllFromLookup:
	calr	AccTuning_FetchValue
	ld	(12807:16), a
	ld	(12808:16), a
	ld	(12809:16), a
	ld	(12810:16), a
	ld	(12811:16), a
	ld	(12812:16), a
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
; readers in v7 (address from the linked ELF): AccTuning_FetchValue 0xF5631A
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x01:opc
	ld (0x3338:16), a
	ld wa, (0x31fb:16)
	ld (0x333a:16), wa
	ld wa, (0x31eb:16)
	ld (0x333c:16), wa
	ld a, (0x3219:16)
	ld (0x333e:16), a
	ld a, (0x320f:16)
	ld (0x333f:16), a
	ld a, (0x3207:16)
	ld (0x3339:16), a
	ld a, (0x334f:16)
	ld (0x334e:16), a
	ret
AccVoice_RestorePartState1:
	ld	wa, (13114:16)
	ld	(12795:16), wa
	ld	wa, (13116:16)
	ld	(12779:16), wa
	ld	a, (13118:16)
	ld	(12825:16), a
	ld	a, (13119:16)
	ld	(12815:16), a
	ld	a, (13113:16)
	ld	(12807:16), a
	ld	a, (13134:16)
	ld	(13135:16), a
	ret
AccVoice_ProcessEventLoop:
	bit 0, (0x3258:16)
	jr z, .Lc_f563d1
	jr t, AccVoice_EventLoop_Idle
AccVoice_EventLoop_Active:
.Lc_f563d1:
	calr AccVoice_DispatchByChannel
	bit 0, (0x3258:16)
	jr z, .Lc_f563dc
	jr t, AccVoice_EventProcessingReturn
AccVoice_EventLoop_Dispatch:
.Lc_f563dc:
	ld w, (0x3338:16)
	ld iz, (0x333a:16)
	call AccVoice_SelectByMask
	ld iy, (0x333c:16)
	ld	a, (xhl+iy)
	cp	a, 131
	jr	nz, AccVoice_EventLoop_Check81
	calr	AccVoice_HandleMarker83
	jr	AccVoice_EventProcessingReturn
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
	cp (0x3338:16), 0x01
	jr nz, .Lc_f56445
	bit 0, (0x3290:16)
	jr z, SoundPatch_NullRet
	calr AccKbd1_ProcessNotes
	jr t, SoundPatch_NullRet
AccVoice_DispatchCh_Kbd2:
.Lc_f56445:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f56457
	bit 1, (0x3290:16)
	jr z, SoundPatch_NullRet
	calr AccKbd2_ProcessNotes
	jr t, SoundPatch_NullRet
AccVoice_DispatchCh_Acc1:
.Lc_f56457:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f5646a
	bit 2, (0x3290:16)
	jr z, SoundPatch_NullRet
	call AccCh1_ProcessNotes
	jr t, SoundPatch_NullRet
AccVoice_DispatchCh_Acc2:
.Lc_f5646a:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f5647d
	bit 3, (0x3290:16)
	jr z, SoundPatch_NullRet
	call AccCh2_ProcessNotes
	jr t, SoundPatch_NullRet
AccVoice_DispatchCh_Acc3:
.Lc_f5647d:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f56490
	bit 4, (0x3290:16)
	jr z, SoundPatch_NullRet
	call AccCh3_ProcessNotes
	jr t, SoundPatch_NullRet
AccVoice_DispatchCh_Acc4:
.Lc_f56490:
	cp (0x3338:16), 0x20
	jr nz, SoundPatch_NullRet
	bit 5, (0x3290:16)
	jr z, SoundPatch_NullRet
	call AccCh4_ProcessNotes
	jr t, SoundPatch_NullRet
SoundPatch_NullRet:
	ret

AccVoice_AdvanceAndCheckEnd:
	calr AccBuf_AdvanceNoPage
	inc 1, (0x3251:16)
	cp (0x3251:16), 0x20
	jr nz, AccVoice_AdvanceAndCheck_Return
	call AccWrap_PlayModeDispatch
	call AccDemo_InitDone
	ld (0x3259:16), 0xff
	or (0x3258:16), 0x21
AccVoice_AdvanceAndCheck_Return:
	ret

AccVoice_HandleNoteOnEvent:
	calr AccVoice_AdvanceWithSave
	ld w, (0x333f:16)
	calr AccVoice_LookupTableAddress
	ld bc, (0x31e1:16)
	ld w, (0x333e:16)
	calr AccTempo_PositionCompare
	cp A,0x18
	jr ule, AccVoice_NoteOn_InRange
	or (0x3258:16), 0x01
	jr t, AccVoice_NoteOn_Return
AccVoice_NoteOn_InRange:
	calr AccMidi_Dispatch

AccVoice_NoteOn_Return:
	ret

AccVoice_HandleBarEndEvent:
	bit 1, (0x3258:16)
	jr z, .Lc_f564f8
	or (0x3258:16), 0x01
	jrl t, AccVoice_NullRet
AccVoice_BarEnd_Process:
.Lc_f564f8:
	ld w, (0x333f:16)
	calr AccVoice_LookupExtParamAddr
	ld bc, (0x31e1:16)
	ld w, (0x333e:16)
	calr AccTempo_PositionCompare
	cp A,0x18
	jr ule, .Lc_f56517
	or (0x3258:16), 0x01
	jrl t, AccVoice_NullRet
AccVoice_BarEnd_InRange:
.Lc_f56517:
	or (0x3258:16), 0x02
	ld a, (0x333f:16)
	inc 1,A
	ld W,A
	and A,0x0f
	cp	a, (0x433:16)
	jr	z, AccVoice_BarEnd_NextPage
	ld	(0x333f:16), w
	calr	AccBuf_AdvanceNoPage
	jrl	AccVoice_NullRet
AccVoice_BarEnd_NextPage:
	and	w, 240
	add	w, 16
	ld	(0x333f:16), w
	inc	1, (0x333e:16)
	calr	AccBuf_AdvanceNoPage
	call	AccVoice_IncrementBarWithSave
	calr	AccPart_Reactivate
	and	(0x32c5:16), 251
	bit	0, (0x3270:16)
	jr	nz, AccVoice_BarEnd_CheckChord94
	ld	a, (0x326f:16)
	and	a, 3
	jr	z, AccVoice_BarEnd_CheckChord65
AccVoice_BarEnd_CheckChord94:
	ld	a, (13112:16)
	and	a, (12938:16)
	jr	nz, AccVoice_SetChordChangeFlags
AccVoice_BarEnd_CheckChord65:
	ld	a, (12909:16)
	and	a, 3
	jr	nz, AccVoice_BarEnd_CheckChord95
	ld	a, (12910:16)
	and	a, 13
	jr	z, AccVoice_BarEnd_CheckSync69
AccVoice_BarEnd_CheckChord95:
	ld	a, (13112:16)
	and	a, (12939:16)
	jr	nz, AccVoice_SetChordChangeFlags
AccVoice_BarEnd_CheckSync69:
	bit	0, (0x3271:16)
	jr	nz, AccVoice_SetChordChangeFlags
	ld	a, (0x32c0:16)
	and	a, 63
	jr	z, AccVoice_NullRet
	bit	7, (0x32c5:16)
	jr	nz, AccVoice_SetChordChangeFlags
	jr	AccVoice_NullRet
AccVoice_SetChordChangeFlags:
	or	(0x3257:16), 128
	or	(0x3258:16), 1
	ld	a, (0x3276:16)
	or	a, (0x3277:16)
	and	a, 63
	jr	z, AccVoice_NullRet
	bit	0, (0x3265:16)
	jr	z, AccVoice_NullRet
	and	(0x3272:16), 252
	or	(0x3272:16), 1
	ld	a, (0x3338:16)
	and	a, (0x3276:16)
	jr	z, AccVoice_NullRet
	or	(0x3272:16), 2
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
	ld	iy, (13116:16)
	ld	iz, (13114:16)
	call	AccBuf_AdvanceWithPageTurn
	ret
AccBuf_AdvanceNoPage:
	ld	iy, (13116:16)
	ld	iz, (13114:16)
	call	AccBuf_Advance
	ld	(13114:16), iz
	ld	(13116:16), iy
	ret
AccVoice_HandleMarker83:
	ld	w, (13112:16)
	ld	a, (12920:16)
	or	a, (12921:16)
	and	w, a
	jr	nz, AccVoice_Marker83_Activate
	ld	a, (13112:16)
	and	a, (12940:16)
	jr	z, AccVoice_Marker83_CheckDeact
AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	calr	AccPart_CheckAnyActive
	and	a, (13112:16)
	jr	z, AccVoice_Marker83_NextPart
	calr	AccPart_Deactivate
	jr	AccVoice_Marker83_Return
AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	ld a, (0x3338:16)
	or (0x328e:16), a
	or (0x328c:16), a
	or (0x3258:16), 0x01
	ld a, (0x328e:16)
	and A,0x3f
	cp A,0x3f
	jr nz, AccVoice_ActivatePart_Return
	or (0x31e7:16), 0x04
	and (0x328e:16), 0xc0
AccVoice_ActivatePart_Return:
	ret

AccVoice_ActivateByteData:
	ld	a, (0x33d4:16)
	and	a, 192
	jr	nz, AccVoice_ActivatePart_Skip
	ld	a, (0x3338:16)
	and	a, (0x328d:16)
	jr	z, AccVoice_ActivatePart_Skip2
AccVoice_ActivatePart_Skip:
	calr	AccPart_ResolveWithPedal
	ld	a, (0x3338:16)
	xor	a, 255
	and	(0x328d:16), a
	jr	AccVoice_ActivatePart_Return2
AccVoice_ActivatePart_Skip2:
	ld	a, (0x327a:16)
	or	a, (0x327b:16)
	or	a, (0x327c:16)
	and	a, (0x3338:16)
	jr	nz, AccVoice_ActivatePart_Skip4
	bit	0, (0x3265:16)
	jr	z, AccVoice_ActivatePart_Skip4
	and	(0x3272:16), 252
	or	(0x3272:16), 1
	ld	a, (0x3338:16)
	and	a, (0x3276:16)
	jr	z, AccVoice_ActivatePart_Skip3
	or	(0x3272:16), 2
AccVoice_ActivatePart_Skip3:
	or	(0x3257:16), 128
	or	(0x3258:16), 1
	jr	AccVoice_ActivatePart_Join
AccVoice_ActivatePart_Skip4:
	calr	AccPart_SelectSourceOrParam
	calr	AccPart_ResolveStyleAddr
AccVoice_ActivatePart_Join:
	ld	a, (0x3338:16)
	xor	a, 255
	and	(0x3276:16), a
	and	(0x3277:16), a
	and	(0x327a:16), a
	and	(0x327b:16), a
	and	(0x327c:16), a
	ld	(0x333f:16), 0
	ld	(0x334e:16), 0
AccVoice_ActivatePart_Return2:
	ret
	or	(0x3258:16), 1
AccPart_SelectSourceOrParam:
	cp (0x3249:16), 0x80
	jr c, AccPart_SelectSource_Param
	calr AccPart_SelectSource
	jr t, AccPart_SelectSource_Done
AccPart_SelectSource_Param:
	calr AccPart_LoadParamOffsetTable

AccPart_SelectSource_Done:
	ld	w, (13112:16)
	ret
AccPart_AdvanceAndResolve:
	calr	AccPart_IncrementIndex
	ld	a, (13112:16)
	and	a, (12993:16)
	jr	z, AccPart_AdvanceResolve_Done
	call	AccVoice_InitPerChannel
	calr	AccPart_LoadParamOffsetTable
	ld	a, (13112:16)
	xor	a, 255
	and	(12993:16), a
	call	AccVoice_AssignPerPart
AccPart_AdvanceResolve_Done:
	calr AccPart_ResolveStyleAddr
	ret

AccPart_ResolveStyleAddr:
	cp (0x3249:16), 0x80
	jr c, AccPart_ResolveStyle_Bound
	ld a, (0x3249:16)
	and A,0x7f
	call AccVoice_ResolveParamAddr
	calr AccPart_GetFreeVoiceAddr
	ld (0x333a:16), wa
	ldw (0x333c:16), 0x0006
	jr t, AccPart_ResolveStyle_Return
AccPart_ResolveStyle_Bound:
	ld	xiy, (12850:16)
	ld	a, (13113:16)
	call	AccPart_LookupBoundVoiceParam
	calr	AccPart_GetParamAddr
	ld	(13116:16), wa
AccPart_ResolveStyle_Return:
	ret

AccPart_IncrementIndex:
	cp (0x3249:16), 0x80
	jr nc, AccPart_IncrementIndex_Return
	ld xiy, (0x3232:16)
	inc	1, (13113:16)
	xor	xhl, xhl
	ld	w, (13113:16)
	call	AccStyle_ReadParamOffset
	cp	w, 131
	jr	nz, AccPart_IncrementIndex_Return
	ld	a, (13113:16)
	call	AccTuning_FetchValue
	ld	(13113:16), a
AccPart_IncrementIndex_Return:
	ret

AccPart_ResolveWithPedal:
	cp (0x3249:16), 0x80
	jr c, AccPart_ResolveWithPedal_Bound
	bit 0, (0x32c7:16)
	jr nz, AccPart_ResolveWithPedal_DirB
	calr AccPedal_DirectionA
	ld xiy, (0x3237:16)
	calr AccPart_GetParamAddr
	ld (0x333c:16), wa
	jr t, AccPart_ResolveWithPedal_Return
AccPart_ResolveWithPedal_DirB:
	ld	w, (13112:16)
	calr	AccPedal_DirectionB
	call	AccVoice_ResolveParamAddr
	calr	AccPart_GetFreeVoiceAddr
	ld	(13114:16), wa
	ldw	(13116:16), 6
	jr	AccPart_ResolveWithPedal_Return
AccPart_ResolveWithPedal_Bound:
	calr	AccPedal_DirectionA
	ld	xiy, (12850:16)
	calr	AccPart_GetParamAddr
	ld	(13116:16), wa
AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	ld	xiy, (12850:16)
	ld	a, (13113:16)
	ld	w, 0:opc
	call	AccPart_GetVoiceParamOffsetTable
	calr	AccPart_LoadTuningByChannel
	ret
AccPart_LoadTuningByChannel:
	cp (0x3338:16), 0x01
	jr nz, .Lc_f56810
	call AccTuning_LoadAndApplyMaster
	or (0x3290:16), 0x01
	jr t, AccPart_NullRet
AccPart_LoadTuning_Kbd2:
.Lc_f56810:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f56822
	call AccTuning_LoadAndApplyMaster
	or (0x3290:16), 0x02
	jr t, AccPart_NullRet
AccPart_LoadTuning_Acc1:
.Lc_f56822:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f56834
	call AccTuning_LoadCoarseFromStyle
	or (0x3290:16), 0x04
	jr t, AccPart_NullRet
AccPart_LoadTuning_Acc2:
.Lc_f56834:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f56846
	call AccTuning_LoadFineFromStyle
	or (0x3290:16), 0x08
	jr t, AccPart_NullRet
AccPart_LoadTuning_Acc3:
.Lc_f56846:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f56858
	call AccTuning_LoadOctaveFromStyle
	or (0x3290:16), 0x10
	jr t, AccPart_NullRet
AccPart_LoadTuning_Acc4:
.Lc_f56858:
	cp (0x3338:16), 0x20
	jr nz, AccPart_NullRet
	call AccTuning_LoadTransposeFromStyle
	or (0x3290:16), 0x20
AccPart_NullRet:
	ret

AccPart_GetFreeVoiceAddr:
	ld a, (0x3338:16)
	xor A,0xff
	and (0x3344:16), a
	cp (0x3338:16), 0x01
	jr nz, .Lc_f56880
	ld16_src_rid8 xiy, 0x00, wa
	jr t, AccPart_CheckEndOfDataMarker
AccPart_FreeAddr_Kbd2:
.Lc_f56880:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f5688c
	ldw WA, 0xfffe
	jr t, AccPart_CheckEndOfDataMarker
AccPart_FreeAddr_Acc1:
.Lc_f5688c:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f56898
	ld WA,(XIY+0x04)
	jr t, AccPart_CheckEndOfDataMarker
AccPart_FreeAddr_Acc2:
.Lc_f56898:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f568a4
	ld WA,(XIY+0x06)
	jr t, AccPart_CheckEndOfDataMarker
AccPart_FreeAddr_Acc3:
.Lc_f568a4:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f568b0
	ld WA,(XIY+0x08)
	jr t, AccPart_CheckEndOfDataMarker
AccPart_FreeAddr_Acc4:
.Lc_f568b0:
	cp (0x3338:16), 0x20
	jr nz, AccPart_CheckEndOfDataMarker
	ld WA,(XIY+0x0a)
AccPart_CheckEndOfDataMarker:
	cp	wa, 65534
	jr	nz, AccPart_FreeAddr_Return
	ld	a, (13112:16)
	or	(13124:16), a
	ldw	wa, 65534
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
	ld a, (0x3338:16)
	xor A,0xff
	and (0x3344:16), a
	cp (0x3338:16), 0x01
	jr nz, .Lc_f568e9
	add HL,0x0118
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Kbd2:
.Lc_f568e9:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f568fb
	add HL,0x013e
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc1:
.Lc_f568fb:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f5690d
	add HL,0x0164
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc2:
.Lc_f5690d:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f5691f
	add HL,0x018a
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc3:
.Lc_f5691f:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f56931
	add HL,0x01b0
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc4:
.Lc_f56931:
	cp (0x3338:16), 0x20
	jr nz, AccPart_SubtractBaseAddr
	add HL,0x01d6
	ld	wa, (xiy+hl)
	jr t, AccPart_SubtractBaseAddr
AccPart_SubtractBaseAddr:
	sub wa, 0x8000
	add wa, 0x6
	ret

AccPart_SelectSource:
	ld xiy, (0x3232:16)
	cp (0x3338:16), 0x01
	jr z, AccPart_SelectKbd
	cp (0x3338:16), 0x02
	jr nz, AccPart_CheckAcc1
AccPart_SelectKbd:
	add	xiy, 24
	ld	xix, 12714
	jr	AccPart_CopyData
AccPart_CheckAcc1:
	cp	(0x3338:16), 4
	jr	nz, AccPart_CheckAcc2
	add	xiy, 32
	ld	xix, 12721
	jr	AccPart_CopyData
AccPart_CheckAcc2:
	cp	(0x3338:16), 8
	jr	nz, AccPart_CheckAcc3
	add	xiy, 40
	ld	xix, 12728
	jr	AccPart_CopyData
AccPart_CheckAcc3:
	cp	(0x3338:16), 16
	jr	nz, AccPart_CheckAcc4
	add	xiy, 48
	ld	xix, 12735
	jr	AccPart_CopyData
AccPart_CheckAcc4:
	cp	(0x3338:16), 32
	jr	nz, AccPart_CheckAcc4
	add	xiy, 56
	ld	xix, 12742
AccPart_CopyData:
	ld bc, 7:i3

	ldir85

	ld a, (13112:16)

	or (12944:16), a

	ret



AccPart_CheckAnyActive:
	ld	a, (12922:16)
	or	a, (12923:16)
	or	a, (12924:16)
	or	a, (12918:16)
	or	a, (12919:16)
	ret
AccPedal_DirectionA:
	ld a, (0x33d4:16)
	and A,0xc0
	jr z, .Lc_f569f0
	bit 7, (0x33d4:16)
	jr z, .Lc_f569f6
	bit 6, (0x33d4:16)
	jr z, .Lc_f569fd
AccPedal_DirA_CheckBit1:
.Lc_f569f0:
	bit 1, (0x325f:16)
	jr nz, .Lc_f569fd
AccPedal_DirA_SetForward:
.Lc_f569f6:
	or (0x326d:16), 0x01
	jr t, .Lc_f56a02
AccPedal_DirA_SetReverse:
.Lc_f569fd:
	or (0x326d:16), 0x02
AccPedal_DirA_Apply:
.Lc_f56a02:
	ld a, (0x3339:16)
	call AccVoice_ComputeParamAddr
	and (0x326d:16), 0xfc

	ret



AccPedal_DirectionB:
	ld a, (0x33d4:16)
	and A,0xc0
	jr z, .Lc_f56a25
	bit 7, (0x33d4:16)
	jr z, .Lc_f56a48
	bit 6, (0x33d4:16)
	jr z, .Lc_f56a2b
AccPedal_DirB_CheckBit0:
.Lc_f56a25:
	bit 0, (0x325f:16)
	jr nz, .Lc_f56a48
AccPedal_DirB_InvertAndStore:
.Lc_f56a2b:
	ld A,W
	xor W,0xff
	and (0x3276:16), w
	ld w, (0x0433:16)
	cp w, (0x32ce:16)
	jr nz, AccPedal_DirB_DefaultStyle
	or (0x3277:16), a
	ld a, (0x32cf:16)
	jr t, AccPedal_DirB_Return
AccPedal_DirB_Alternate:
.Lc_f56a48:
	ld A,W
	xor W,0xff
	and (0x3277:16), w
	ld w, (0x0433:16)
	cp w, (0x32cc:16)
	jr nz, AccPedal_DirB_DefaultStyle
	or (0x3276:16), a
	ld a, (0x32cd:16)
	jr t, AccPedal_DirB_Return
AccPedal_DirB_DefaultStyle:
	ld	a, (12873:16)
	and	a, 127
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
	ld	e, a
	ld	(13110:16), a
	ld	a, (xhl+iy)
	ret
AccMidi_ParseNoteOn:
	calr AccMidi_ParseCommon
	cp (0x3391:16), 0x91
	jr nz, AccMidi_ParseNoteOn_StorePos
	ld	a, (xhl+iy)
	ld (0x3397:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3398:16), a
	call AccBuf_Advance
AccMidi_ParseNoteOn_StorePos:
	ld	(13116:16), iy
	ld	(13114:16), iz
	ret
AccMidi_ParseCommon:
	ld (0x3391:16), a
	call AccBuf_Advance
	ld (0x3392:16), e
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3393:16), a
	cp (0x3338:16), 0x01
	jr z, .Lc_f56b14
	cp (0x3338:16), 0x02
	jr z, .Lc_f56b14
	call Rhythm_CheckVelocityThreshold
AccMidi_ParseCommon_ExtraFields:
.Lc_f56b14:
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3394:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3395:16), a
	call AccBuf_Advance
	ld	a, (xhl+iy)
	ld (0x3396:16), a
	call AccBuf_Advance
	ret
AccMidi_SelectVelocitySource:
	ld	a, (13112:16)
	ld	w, (12963:16)
	and	a, (12922:16)
	jr	nz, AccMidi_VelSource_Active
	and	a, (12923:16)
	jr	nz, AccMidi_VelSource_Active
	and	a, (12924:16)
	jr	nz, AccMidi_VelSource_Active
	and	a, (12920:16)
	jr	nz, AccMidi_VelSource_Active
	and	a, (12921:16)
	jr	z, AccMidi_VelSource_Store
AccMidi_VelSource_Active:
	ld	w, (12964:16)
AccMidi_VelSource_Store:
	ld	(13122:16), w
	ret
AccMidi_DispatchPerPart:
	cp (0x3338:16), 0x01
	jr nz, .Lc_f56b7b
	calr AccKbd1_RingBufEntry
	jr t, AccMidi_DispatchAcc4Return
AccMidi_DispatchKbd2:
.Lc_f56b7b:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f56b87
	calr AccKbd2_RingBufEntry
	jr t, AccMidi_DispatchAcc4Return
AccMidi_DispatchAcc1:
.Lc_f56b87:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f56b94
	call AccCh1_NoteOnEntry
	jr t, AccMidi_DispatchAcc4Return
AccMidi_DispatchAcc2:
.Lc_f56b94:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f56ba1
	call AccCh2_NoteOnEntry
	jr t, AccMidi_DispatchAcc4Return
AccMidi_DispatchAcc3:
.Lc_f56ba1:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f56bae
	call AccCh3_NoteOnEntry
	jr t, AccMidi_DispatchAcc4Return
AccMidi_DispatchAcc4:
.Lc_f56bae:
	cp (0x3338:16), 0x20
	jr nz, AccMidi_DispatchAcc4Return
	call AccCh4_NoteOnEntry
AccMidi_DispatchAcc4Return:
	ret

AccKbd1_RingBufEntry:
	calr AccKbd1_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccKbd1_RingBufReturn
	ld XHL,0x000029f8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteNoteEvent
AccKbd1_RingBufReturn:
	ret

AccKbd1_CheckEligible:
	and (0x3345:16), 0xfe
	bit 0, (0x3342:16)
	jr z, AccKbd1_CheckReturn
	bit 0, (0x32c6:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x326b:16)
	jr z, AccKbd1_CheckReturn
	bit 4, (0x36ff:16)
	jr z, .Lc_f56c14
	bit 2, (0x3433:16)
	jr nz, AccKbd1_CheckReturn
	bit 7, (0x34bc:16)
	jr z, .Lc_f56c14
	ld a, (0x34bc:16)
	and A,0x7f
	cp a, (0x3393:16)
	jr z, AccKbd1_CheckReturn
	cp A,0x30
	jr nz, .Lc_f56c14
	cp (0x3393:16), 0x5d
	jr z, AccKbd1_CheckReturn
AccKbd1_CheckRecording:
.Lc_f56c14:
	bit 1, (0x3299:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccKbd1_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccKbd1_CheckReturn
	ld XHL,0x000029f8
	calr AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ule, AccKbd1_CheckReturn
	or (0x3345:16), 0x01
AccKbd1_CheckReturn:
	ret

AccBuf_WriteNoteEvent:
	ld a, (0x3391:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	cp a, 0:i3
	jr nz, AccBuf_WriteNote_VelNonZero
	ld A, 0x01:opc
AccBuf_WriteNote_VelNonZero:
	ld	(xhl+iy), a

	; call RingBuf_AdvanceIndex (v7 addr)
	call	RingBuf_AdvanceIndex
	; ldb_d8 a, (0x3432) (v7 patched)
	ld	a, (0x3396:16)
	ld	(xhl+iy), a

	; call RingBuf_AdvanceIndex (v7 addr)
	call	RingBuf_AdvanceIndex
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
	ld	(12936:16), wa
	ret
AccTempo_PositionCompare:
	cp w, (0x3218:16)
	jr nz, AccTempo_DiffBar
	cp BC,DE
	jr c, AccTempo_SameBar
	ld A, 0x00:opc
	jr t, AccTempo_Return
AccTempo_SameBar:
	sub de, bc
	ld a, e
	cp d, 0:i3
	jr z, AccTempo_Return
	ld a, 0x60:opc
	jr AccTempo_Return

AccTempo_DiffBar:
	cp	w, (0x3218:16)
	jr	c, AccTempo_BarZero
	cp	w, 255
	jr	nz, AccTempo_ComputeDelta
	cp	(0x3218:16), 0
	jr	z, AccTempo_TooFar
	jr	AccTempo_ComputeDelta
AccTempo_BarZero:
	cp	w, 0:i3
	jr	nz, AccTempo_TooFar
	cp	(0x3218:16), 255
	jr	z, AccTempo_ComputeDelta
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
	bit 0, (0x3258:16)
	jr nz, AccKbd1_ProcessReturn
	calr AccKbd1_ScanSlots
	calr AccKbd1_DrainRingBuf
	ld XIY,0x00003178
	ld XIX,0x00003191
	ld bc, 5:i3
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call RhythmPart1_ProcessAccentData
	and (0x3290:16), 0xfe
AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	ld A, 0x00:opc
	ld w, (0x333f:16)
	calr AccVoice_LookupTableAddress
	ld bc, (0x31e1:16)
	ld w, (0x333e:16)
	calr AccTempo_PositionCompare
	cp A,0x18
	jr ule, AccKbd1_TimingOK
	or (0x3258:16), 0x01
	jr t, AccKbd1_TimingReturn
AccKbd1_TimingOK:
	ld	(13216:16), a
	ld	a, 95:opc
	ld	w, (1112:16)
	dec	1, w
	calr	AccVoice_LookupTableAddress
	ld	bc, (12769:16)
	ld	w, (13118:16)
	dec	1, w
	calr	AccTempo_PositionCompare
	ld	(13215:16), a
AccKbd1_TimingReturn:
	ret

AccKbd1_ScanSlots:
	ld	xhl, 12280
AccKbd1_ScanSlots_Loop:
	calr	AccSlot_CheckAndUpdate
	add	xhl, 6
	cp	xhl, 12328
	jr	c, AccKbd1_ScanSlots_Loop
	ret
AccSlot_CheckAndUpdate:
	bit 7,(XHL)
	jr z, AccSlot_Return
	ld DE,(XHL+0x04)
	ld a, (0x339f:16)
	xor W,W
	ei 0x06
	add	wa, (0x460:16)
	sub	a, (0x464:16)
	jr	pl, AccSlot_CompareAndUpdate
	cp	w, 0:i3
	jr	z, AccSlot_TimingZero
	dec	1, w
	add	a, 96
	jr	AccSlot_CompareAndUpdate
AccSlot_TimingZero:
	xor wa, wa

AccSlot_CompareAndUpdate:
	cp	de, wa
	jr	ule, AccSlot_RestoreInterrupts	; -> 0xF56DCE
	ld	(xhl+4), wa
	cp	(13014:16), wa
	jr	ule, AccSlot_RestoreInterrupts	; -> 0xF56DCE
	ld	(13014:16), wa
AccSlot_RestoreInterrupts:
	ei 0

AccSlot_Return:
	ret

AccKbd1_DrainRingBuf:
	ld	xhl, 10744
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	popw	iy
	ld	a, (13215:16)
	ei	0x06
	add	a, (1122:16)
	add	w, (1124:16)
	sub	a, w
	jr	pl, AccBuf_NoteEvent_StoreTiming
	ld	a, 0:opc
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
	ld	a, (13112:16)
	and	a, (13124:16)
	jr	z, AccBuf_ProcessNoteEvent_Return
	ld	a, (13112:16)
	ld	w, (12920:16)
	or	w, (12921:16)
	and	w, a
	jr	z, AccBuf_ProcessNoteEvent_Skip
	or	(12942:16), a
	or	(12940:16), a
	jr	AccBuf_ProcessNoteEvent_Return
AccBuf_ProcessNoteEvent_Skip:
	ld	a, (13112:16)
	xor	a, 255
	and	(12918:16), a
	and	(12919:16), a
	and	(12922:16), a
	and	(12923:16), a
	and	(12924:16), a
	and	(12993:16), a
	and	(12941:16), a
	ld	(13134:16), 0
	ld	(13114:16), 254
	ld	(13116:16), 6
AccBuf_ProcessNoteEvent_Return:
	ret
AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x02:opc
	ld (0x3338:16), a
	ld wa, (0x31fd:16)
	ld (0x333a:16), wa
	ld wa, (0x31ed:16)
	ld (0x333c:16), wa
	ld a, (0x321a:16)
	ld (0x333e:16), a
	ld a, (0x3210:16)
	ld (0x333f:16), a
	ld a, (0x3208:16)
	ld (0x3339:16), a
	ld a, (0x3350:16)
	ld (0x334e:16), a
	ret
AccKbd2_RestoreState:
	ld	wa, (13114:16)
	ld	(12797:16), wa
	ld	wa, (13116:16)
	ld	(12781:16), wa
	ld	a, (13118:16)
	ld	(12826:16), a
	ld	a, (13119:16)
	ld	(12816:16), a
	ld	a, (13113:16)
	ld	(12808:16), a
	ld	a, (13134:16)
	ld	(13136:16), a
	ret
AccKbd2_RingBufEntry:
	calr AccKbd2_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccKbd2_RingBufReturn
	ld XHL,0x00002af8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteNoteEvent
AccKbd2_RingBufReturn:
	ret

AccKbd2_CheckEligible:
	and (0x3345:16), 0xfe
	cp (0x3249:16), 0x80
	jr nc, AccKbd2_CheckReturn
	bit 1, (0x3342:16)
	jr z, AccKbd2_CheckReturn
	bit 0, (0x326b:16)
	jr z, AccKbd2_CheckReturn
	bit 1, (0x3299:16)
	jr nz, AccKbd2_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccKbd2_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccKbd2_CheckReturn
	ld XHL,0x00002af8
	calr AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ule, AccKbd2_CheckReturn
	or (0x3345:16), 0x01
AccKbd2_CheckReturn:
	ret

AccKbd2_ProcessNotes:
	calr AccKbd1_TimingCheck
	bit 0, (0x3258:16)
	jr nz, AccKbd2_ProcessReturn
	calr AccKbd2_ScanSlots
	calr AccKbd2_DrainRingBuf
	and (0x3290:16), 0xfd
AccKbd2_ProcessReturn:
	ret

AccKbd2_ScanSlots:
	ld	xhl, 12328
AccKbd2_ScanSlots_Loop:
	calr	AccSlot_CheckAndUpdate
	add	xhl, 6
	cp	xhl, 12376
	jr	c, AccKbd2_ScanSlots_Loop
	ret
AccKbd2_DrainRingBuf:
	ld	xhl, 11000
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	; anddi8 (0x32f4), 252 (v7 patched)
	and	(0x3258:16), 252
AccSeq_ScanLoop:
	bit 0, (0x3258:16)
	jrl nz, AccSeq_ScanDone
	ld xhl, (0x31f7:16)
	ld A,(XHL)
	cp A,0x83
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
	calr	AccSeq_ReadNextByte
	ld	w, (12821:16)
	calr	AccVoice_LookupTableAddress
	ld	bc, (12769:16)
	ld	w, (12831:16)
	calr	AccTempo_PositionCompare
	cp	a, 24
	jr	ugt, AccSeq_NoteOn_TooFar
	calr	AccSeq_ParseNoteEvent
	jr	AccSeq_NoteOn_Continue
AccSeq_NoteOn_TooFar:
	; ordi8 0x32f4, 1 (v7 patched)
	or	(0x3258:16), 1
AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	bit	1, (0x3258:16)
	jr	z, AccSeq_EndOfBar_Process
	or	(0x3258:16), 1
	jr	AccSeq_ScanLoop
AccSeq_EndOfBar_Process:
	ld	w, (0x3215:16)
	calr	AccVoice_LookupExtParamAddr
	ld	bc, (0x31e1:16)
	ld	w, (0x321f:16)
	calr	AccTempo_PositionCompare
	cp	a, 24
	jr	ugt, AccSeq_EndOfBar_TooFar
	or	(0x3258:16), 2
	ld	a, (0x3215:16)
	inc	1, a
	ld	w, a
	and	a, 15
	cp	a, (0x433:16)
	jr	z, AccSeq_NextBarPage
	ld	(0x3215:16), w
	calr	AccSeq_AdvancePointer
	jrl	AccSeq_ScanLoop
AccSeq_NextBarPage:
	and	w, 240
	add	w, 16
	ld	(12821:16), w
	inc	1, (12831:16)
	ld	xhl, AccStyle_DefaultStream
	add	xhl, 6
	ld	(12791:16), xhl
	jrl	AccSeq_ScanLoop
AccSeq_EndOfBar_TooFar:
	; ordi8 0x32f4, 1 (v7 patched)
	or	(0x3258:16), 1
	; jrl AccSeq_ScanLoop (v7 displacement)
	jrl	AccSeq_ScanLoop
AccSeq_ScanDone:
	ret

AccSeq_ReadNextByte:
	ld	xhl, (12791:16)
	inc	1, xhl
	ld	a, (xhl)
	ret
AccSeq_AdvancePointer:
	ld	xhl, (12791:16)
	inc	1, xhl
	ld	(12791:16), xhl
	ret
AccSeq_ResetToStart:
	ld	xhl, AccStyle_DefaultStream
	add	xhl, 6
	ld	(12791:16), xhl
	ld	a, (xhl)
	ret
AccSeq_ParseNoteEvent:
	cp a, 0:i3
	jr nz, AccSeq_ParseNote_VelNonZero
	ld a, 0x1:opc

AccSeq_ParseNote_VelNonZero:
	ld	e, a
	ld	xhl, (0x31f7:16)
	ld	a, (xhl)
	ld	(0x3391:16), a
	calr	AccSeq_AdvancePointer
	ld	(0x3392:16), e
	calr	AccSeq_AdvancePointer
	ld	a, (xhl)
	ld	(0x3393:16), a
	calr	AccSeq_AdvancePointer
	ld	a, (xhl)
	ld	(0x3394:16), a
	calr	AccSeq_AdvancePointer
	ld	a, 1:opc
	ld	(0x3395:16), a
	calr	AccSeq_AdvancePointer
	ld	a, 0:opc
	ld	(0x3396:16), a
	calr	AccSeq_AdvancePointer
	ld	a, (0x36ff:16)
	and	a, 63
	jr	z, AccSeq_ParseNote_CheckMode
	cp	(0x8c9a:16), 181
	jr	z, AccSeq_ParseNote_WriteToKbd2
	jr	AccSeq_ParseNote_Return
AccSeq_ParseNote_CheckMode:
	ld	a, (0x3299:16)
	cp	a, 3:i3
	jr	nz, AccSeq_ParseNote_CheckRec
	bit	0, (0x33de:16)
	jr	z, AccSeq_ParseNote_WriteToKbd2
AccSeq_ParseNote_CheckRec:
	bit	0, (0x334c:16)
	jr	z, AccSeq_ParseNote_Return
AccSeq_ParseNote_WriteToKbd2:
	ld	xhl, 11000
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	AccBuf_WriteNoteEvent
AccSeq_ParseNote_Return:
	ret

AccCh1_ProcessEntry:
	calr AccCh1_SaveState
	call AccVoice_ProcessEventLoop
	calr AccCh1_RestoreState
	ret

AccCh1_SaveState:
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x04:opc
	ld (0x3338:16), a
	ld wa, (0x31ff:16)
	ld (0x333a:16), wa
	ld wa, (0x31ef:16)
	ld (0x333c:16), wa
	ld a, (0x321b:16)
	ld (0x333e:16), a
	ld a, (0x3211:16)
	ld (0x333f:16), a
	ld a, (0x3209:16)
	ld (0x3339:16), a
	ld a, (0x3351:16)
	ld (0x334e:16), a
	ret
AccCh1_RestoreState:
	ld	wa, (13114:16)
	ld	(12799:16), wa
	ld	wa, (13116:16)
	ld	(12783:16), wa
	ld	a, (13118:16)
	ld	(12827:16), a
	ld	a, (13119:16)
	ld	(12817:16), a
	ld	a, (13113:16)
	ld	(12809:16), a
	ld	a, (13134:16)
	ld	(13137:16), a
	ret
AccVoice_AssignPerPart:
	cp (0x3338:16), 0x01
	jr z, AccVoice_AssignReturn
	cp (0x3338:16), 0x02
	jr z, AccVoice_AssignReturn
	ld a, (0x3339:16)
	call AccTuning_FetchValue
	ld (0x32ad:16), a
	calr AccVoice_ScanInstruments
	calr AccVoice_SendProgChange
AccVoice_AssignReturn:
	ret

AccVoice_ScanInstruments:
	ld	e, (12973:16)
	ld	(12951:16), 0
AccVoice_ScanLoop:
	cp	e, (13113:16)
	jr	z, AccVoice_ScanDone	; -> 0xF571F2
	ld	xiy, (12850:16)
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (12777:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanLoop	; -> 0xF571CC
AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f5720c
	ld A, 0xd7:opc
	ld W, 0x03:opc
	ld e, (0x3297:16)
	ld (0x3293:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD4:
.Lc_f5720c:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f57225
	ld A, 0xd4:opc
	ld W, 0x03:opc
	ld e, (0x3297:16)
	ld (0x3294:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD5:
.Lc_f57225:
	cp (0x3338:16), 0x10
	jr nz, AccVoice_SendD6
	ld A, 0xd5:opc
	ld W, 0x03:opc
	ld e, (0x3297:16)
	ld (0x3295:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD6:
	ld	a, 214:opc
	ld	w, 3:opc
	ld	e, (12951:16)
	ld	(12950:16), e
	call	Rhythm_Send3ByteMsg
	jr	AccCh_ReturnStub
AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	ld a, (0x3391:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ret
AccCh1_Padding:
	nop
	nop

AccCh1_NoteOnEntry:
	calr AccCh1_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh1_NoteOnReturn
	ld a, (0x3227:16)
	ld (0x322f:16), a
	ld a, (0x322b:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xfb
	or (0x3258:16), 0x08
	ld XHL,0x00002bf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteExtendedEvent
AccCh1_NoteOnReturn:
	ret

AccCh1_CheckEligible:
	and (0x3345:16), 0xfe
	bit 2, (0x32c6:16)
	jr nz, AccCh1_CheckReturn
	bit 1, (0x326b:16)
	jr z, AccCh1_CheckReturn
	bit 3, (0xc504:16)
	jr z, AccCh1_CheckReturn
	calr AccCh_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh1_CheckReturn
	bit 1, (0x3299:16)
	jr nz, AccCh1_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccCh1_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccCh1_CheckReturn
	ld XHL,0x00002bf8
	call AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ugt, .Lc_f572fa
	calr AccBuf_InitWithDefaults
	jr t, AccCh1_CheckReturn
AccCh1_SetReady:
.Lc_f572fa:
	or (0x3345:16), 0x01



AccCh1_CheckReturn:
	ret

AccBuf_WriteExtendedEvent:
	ld a, (0x3397:16)
	ld (0x329a:16), a
	ld a, (0x3398:16)
	ld (0x329b:16), a
	ld a, (0x3391:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	ld (0x3399:16), a
	calr AccVoice_CheckStyle
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	cp a, 0:i3
	jr nz, .Lc_f5734c
	ld A, 0x01:opc
AccBuf_ExtEvt_VelNonZero:
.Lc_f5734c:
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x3396:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	calr AccBuf_ExtEvt_WriteExtra
	ld a, (0x3399:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ret
AccBuf_ExtEvt_WriteExtra:
	cp (0x3391:16), 0x90
	jr z, AccBuf_ExtEvt_ExtraReturn
	ld a, (0x329a:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld a, (0x329b:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	.byte 0xc1, 0x49, 0x32, 0x3f, 0xf0, 0x67, 0x00
AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	push	xhl
	pushw	iy
	ld	a, (0x3393:16)
	bit	4, (0x3258:16)
	jr	nz, AccVoice_CheckStyle_Code_Skip2
	bit	3, (0x3258:16)
	jr	z, AccVoice_CheckStyle_Code_Skip
	call	Rhythm_CrossVoiceCorrect
AccVoice_CheckStyle_Code_Skip:
	call	Rhythm_NoteRangeCheck
AccVoice_CheckStyle_Code_Skip2:
	call	Rhythm_VelocityCompute
	popw	iy
	pop	xhl
	ret
AccVoice_CorrectNote:
	push	xhl
	pushw	iy
	ld	a, (0x3393:16)
	bit	4, (0x3258:16)
	jr	nz, AccVoice_VelocityLookup
	bit	3, (0x3258:16)
	jr	z, AccVoice_NoteRangeCheck
	call	Rhythm_CrossVoiceCorrect
AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	cp	(13201:16), 145
	jr	z, AccVoice_UseVoiceMap
	call	Rhythm_VelocityLookup_A
	jr	AccVoice_CorrectReturn
AccVoice_UseVoiceMap:
	call Rhythm_VoiceMapLookup

AccVoice_CorrectReturn:
	popw iy
	pop xhl
	ret

AccMidi_ParseDType:
	ld D,A
	and A,0xf0
	ld (0x3391:16), a
	call AccBuf_Advance
	ld (0x3392:16), e
	call AccBuf_Advance
	ld A,D
	and A,0x0f
	ld (0x3393:16), a
	ld	a, (xhl+iy)
	ld	(13204:16), a
	call	AccBuf_Advance
	ld	(13116:16), iy
	ld	(13114:16), iz
	ret
AccMidi_DispatchDType:
	cp (0x3338:16), 0x01
	jr nz, .Lc_f57430
	jr t, AccMidi_DType_Return
AccMidi_DType_CheckKbd2:
.Lc_f57430:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f57439
	jr t, AccMidi_DType_Return
AccMidi_DType_CheckAcc1:
.Lc_f57439:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f57445
	calr AccCh1_DTypeEntry
	jr t, AccMidi_DType_Return
AccMidi_DType_CheckAcc2:
.Lc_f57445:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f57451
	calr AccCh2_DTypeEntry
	jr t, AccMidi_DType_Return
AccMidi_DType_CheckAcc3:
.Lc_f57451:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f5745d
	calr AccCh3_DTypeEntry
	jr t, AccMidi_DType_Return
AccMidi_DType_CheckAcc4:
.Lc_f5745d:
	cp (0x3338:16), 0x20
	jr nz, .Lc_f5745d
	calr AccCh4_DTypeEntry
AccMidi_DType_Return:
	ret

AccCh1_DTypeEntry:
	calr AccCh1_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh1_DTypeReturn
	ld XHL,0x00002bf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_Write3ByteEvent
AccCh1_DTypeReturn:
	ret

AccCh_CheckOverlap:
	ld A, 0x00:opc
	bit 2, (0x3433:16)
	jr z, AccCh_OverlapReturn
	bit 3, (0x36ff:16)
	jr z, AccCh_OverlapReturn
	ld A, 0x01:opc
AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	ldw (xhl+0:8), 0x000a
	ldw (XHL+0x02), 0x00ff
	ldw (XHL+0x04), 0x000a
	ldw (XHL+0x06), 0x000a
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	ld (0x3391:16), 0xd0
	ld a, (0x3336:16)
	ld (0x3392:16), a
	ld (0x3393:16), 0x02
	ld (0x3394:16), 0x40
	calr AccBuf_Write3ByteEvent
	ld a, (0x3336:16)
	ld (0x3392:16), a
	ld (0x3393:16), 0x01
	ld (0x3394:16), 0x00
	calr AccBuf_Write3ByteEvent
	ld a, (0x3336:16)
	ld (0x3392:16), a
	ld (0x3393:16), 0x03
	ld (0x3394:16), 0x00
	calr AccBuf_Write3ByteEvent
	ld a, (0x3336:16)
	ld (0x3392:16), a
	ld (0x3393:16), 0x05
	ld (0x3394:16), 0x7f
	calr AccBuf_Write3ByteEvent
	ret
AccCh1_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x3258:16)
	jr nz, AccCh1_ProcessReturn
	calr AccCh1_ScanSlots
	calr AccCh1_DrainRingBuf
	calr AccCh1_InitProgChange
	ld XIY,0x0000317d
	ld XIX,0x00003196
	ld bc, 5:i3
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call RhythmPart2_ProcessAccentData
	and (0x3290:16), 0xfb
AccCh1_ProcessReturn:
	ret

AccCh1_ScanSlots:
	ld	xhl, 12376
AccCh1_ScanSlots_Loop:
	call	AccSlot_CheckAndUpdate
	add	xhl, 9
	cp	xhl, 12448
	jr	c, AccCh1_ScanSlots_Loop
	ret
AccCh1_DrainRingBuf:
	ld	xhl, 11256
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x08:opc
	ld (0x3338:16), a
	ld wa, (0x3201:16)
	ld (0x333a:16), wa
	ld wa, (0x31f1:16)
	ld (0x333c:16), wa
	ld a, (0x321c:16)
	ld (0x333e:16), a
	ld a, (0x3212:16)
	ld (0x333f:16), a
	ld a, (0x320a:16)
	ld (0x3339:16), a
	ld a, (0x3352:16)
	ld (0x334e:16), a
	ret
AccCh2_RestoreState:
	ld	wa, (13114:16)
	ld	(12801:16), wa
	ld	wa, (13116:16)
	ld	(12785:16), wa
	ld	a, (13118:16)
	ld	(12828:16), a
	ld	a, (13119:16)
	ld	(12818:16), a
	ld	a, (13113:16)
	ld	(12810:16), a
	ld	a, (13134:16)
	ld	(13138:16), a
	ret
AccCh2_NoteOnEntry:
	calr AccCh2_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh2_NoteOnReturn
	ld a, (0x3228:16)
	ld (0x322f:16), a
	ld a, (0x322c:16)
	ld (0x3230:16), a
	or (0x3258:16), 0x04
	and (0x3258:16), 0xf7
	ld XHL,0x00002cf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteExtendedEvent
AccCh2_NoteOnReturn:
	ret

AccCh2_CheckEligible:
	and (0x3345:16), 0xfe
	bit 3, (0x3342:16)
	jr z, AccCh2_CheckReturn
	bit 3, (0x32c6:16)
	jr nz, AccCh2_CheckReturn
	bit 2, (0x326b:16)
	jr z, AccCh2_CheckReturn
	bit 0, (0x3274:16)
	jr z, AccCh2_CheckReturn
	bit 0, (0xc504:16)
	jr z, AccCh2_CheckReturn
	calr AccCh2_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh2_CheckReturn
	bit 1, (0x3299:16)
	jr nz, AccCh2_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccCh2_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccCh2_CheckReturn
	ld XHL,0x00002cf8
	call AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ugt, .Lc_f57693
	calr AccBuf_InitWithDefaults
	jr t, AccCh2_CheckReturn
AccCh2_SetReady:
.Lc_f57693:
	or (0x3345:16), 0x01



AccCh2_CheckReturn:
	ret

AccCh2_DTypeEntry:
	calr AccCh2_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh2_DTypeReturn
	ld XHL,0x00002cf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_Write3ByteEvent
AccCh2_DTypeReturn:
	ret

AccCh2_CheckOverlap:
	ld A, 0x00:opc
	bit 2, (0x3433:16)
	jr z, AccCh2_OverlapReturn
	bit 0, (0x36ff:16)
	jr z, AccCh2_OverlapReturn
	ld A, 0x01:opc
AccCh2_OverlapReturn:
	ret

AccCh2_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x3258:16)
	jr nz, AccCh2_ProcessReturn
	calr AccCh2_ScanSlots
	calr AccCh2_DrainRingBuf
	calr AccCh2_InitProgChange
	ld XIY,0x00003182
	ld XIX,0x0000319b
	ld bc, 5:i3
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call AccVoice_LoadRhythmParams_Part3
	and (0x3290:16), 0xf7
AccCh2_ProcessReturn:
	ret

AccCh2_ScanSlots:
	ld	xhl, 12448
AccCh2_ScanSlots_Loop:
	call	AccSlot_CheckAndUpdate
	add	xhl, 9
	cp	xhl, 12520
	jr	c, AccCh2_ScanSlots_Loop
	ret
AccCh2_DrainRingBuf:
	ld	xhl, 11512
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x10:opc
	ld (0x3338:16), a
	ld wa, (0x3203:16)
	ld (0x333a:16), wa
	ld wa, (0x31f3:16)
	ld (0x333c:16), wa
	ld a, (0x321d:16)
	ld (0x333e:16), a
	ld a, (0x3213:16)
	ld (0x333f:16), a
	ld a, (0x320b:16)
	ld (0x3339:16), a
	ld a, (0x3353:16)
	ld (0x334e:16), a
	ret
AccCh3_RestoreState:
	ld	wa, (13114:16)
	ld	(12803:16), wa
	ld	wa, (13116:16)
	ld	(12787:16), wa
	ld	a, (13118:16)
	ld	(12829:16), a
	ld	a, (13119:16)
	ld	(12819:16), a
	ld	a, (13113:16)
	ld	(12811:16), a
	ld	a, (13134:16)
	ld	(13139:16), a
	ret
AccCh3_NoteOnEntry:
	calr AccCh3_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh3_NoteOnReturn
	ld a, (0x3229:16)
	ld (0x322f:16), a
	ld a, (0x322d:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xfb
	and (0x3258:16), 0xf7
	ld XHL,0x00002df8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteExtendedEvent
AccCh3_NoteOnReturn:
	ret

AccCh3_CheckEligible:
	and (0x3345:16), 0xfe
	bit 4, (0x3342:16)
	jr z, AccCh3_CheckReturn
	bit 4, (0x32c6:16)
	jr nz, AccCh3_CheckReturn
	bit 3, (0x326b:16)
	jr z, AccCh3_CheckReturn
	bit 1, (0x3274:16)
	jr z, AccCh3_CheckReturn
	bit 1, (0xc504:16)
	jr z, AccCh3_CheckReturn
	calr AccCh3_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh3_CheckReturn
	bit 1, (0x3299:16)
	jr nz, AccCh3_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccCh3_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccCh3_CheckReturn
	ld XHL,0x00002df8
	call AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ugt, .Lc_f57850
	calr AccBuf_InitWithDefaults
	jr t, AccCh3_CheckReturn
AccCh3_SetReady:
.Lc_f57850:
	or (0x3345:16), 0x01



AccCh3_CheckReturn:
	ret

AccCh3_DTypeEntry:
	calr AccCh3_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh3_DTypeReturn
	ld XHL,0x00002df8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_Write3ByteEvent
AccCh3_DTypeReturn:
	ret

AccCh3_CheckOverlap:
	ld A, 0x00:opc
	bit 2, (0x3433:16)
	jr z, AccCh3_OverlapReturn
	bit 1, (0x36ff:16)
	jr z, AccCh3_OverlapReturn
	ld A, 0x01:opc
AccCh3_OverlapReturn:
	ret

AccCh3_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x3258:16)
	jr nz, AccCh3_ProcessReturn
	calr AccCh3_ScanSlots
	calr AccCh3_DrainRingBuf
	calr AccCh3_InitProgChange
	ld XIY,0x00003187
	ld XIX,0x000031a0
	ld bc, 5:i3
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call AccVoice_LoadRhythmParams_Part4
	and (0x3290:16), 0xef
AccCh3_ProcessReturn:
	ret

AccCh3_ScanSlots:
	ld	xhl, 12520
AccCh3_ScanSlots_Loop:
	call	AccSlot_CheckAndUpdate
	add	xhl, 9
	cp	xhl, 12592
	jr	c, AccCh3_ScanSlots_Loop
	ret
AccCh3_DrainRingBuf:
	ld	xhl, 11768
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ld A, 0x20:opc
	ld (0x3338:16), a
	ld wa, (0x3205:16)
	ld (0x333a:16), wa
	ld wa, (0x31f5:16)
	ld (0x333c:16), wa
	ld a, (0x321e:16)
	ld (0x333e:16), a
	ld a, (0x3214:16)
	ld (0x333f:16), a
	ld a, (0x320c:16)
	ld (0x3339:16), a
	ld a, (0x3354:16)
	ld (0x334e:16), a
	ret
AccCh4_RestoreState:
	ld	wa, (13114:16)
	ld	(12805:16), wa
	ld	wa, (13116:16)
	ld	(12789:16), wa
	ld	a, (13118:16)
	ld	(12830:16), a
	ld	a, (13119:16)
	ld	(12820:16), a
	ld	a, (13113:16)
	ld	(12812:16), a
	ld	a, (13134:16)
	ld	(13140:16), a
	ret
AccCh4_NoteOnEntry:
	calr AccCh4_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh4_NoteOnReturn
	ld a, (0x322a:16)
	ld (0x322f:16), a
	ld a, (0x322e:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xfb
	and (0x3258:16), 0xf7
	ld XHL,0x00002ef8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_WriteExtendedEvent
AccCh4_NoteOnReturn:
	ret

AccCh4_CheckEligible:
	and (0x3345:16), 0xfe
	bit 5, (0x3342:16)
	jr z, AccCh4_CheckReturn
	bit 5, (0x32c6:16)
	jr nz, AccCh4_CheckReturn
	bit 4, (0x326b:16)
	jr z, AccCh4_CheckReturn
	bit 2, (0x3274:16)
	jr z, AccCh4_CheckReturn
	bit 2, (0xc504:16)
	jr z, AccCh4_CheckReturn
	calr AccCh4_CheckOverlap
	cp a, 0:i3
	jr nz, AccCh4_CheckReturn
	bit 1, (0x3299:16)
	jr nz, AccCh4_CheckReturn
	bit 0, (0x33de:16)
	jr nz, AccCh4_CheckReturn
	bit 0, (0x334c:16)
	jr nz, AccCh4_CheckReturn
	ld XHL,0x00002ef8
	call AccBuf_ComputeFillLevel
	cpw (0x3288:16), 0x0010
	jr ugt, .Lc_f57a0d
	calr AccBuf_InitWithDefaults
	jr t, AccCh4_CheckReturn
AccCh4_SetReady:
.Lc_f57a0d:
	or (0x3345:16), 0x01



AccCh4_CheckReturn:
	ret

AccCh4_DTypeEntry:
	calr AccCh4_CheckEligible
	bit 0, (0x3345:16)
	jr z, AccCh4_DTypeReturn
	ld XHL,0x00002ef8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	calr AccBuf_Write3ByteEvent
AccCh4_DTypeReturn:
	ret

AccCh4_CheckOverlap:
	ld A, 0x00:opc
	bit 2, (0x3433:16)
	jr z, AccCh4_OverlapReturn
	bit 2, (0x36ff:16)
	jr z, AccCh4_OverlapReturn
	ld A, 0x01:opc
AccCh4_OverlapReturn:
	ret

AccCh4_ProcessNotes:
	call AccKbd1_TimingCheck
	bit 0, (0x3258:16)
	jr nz, AccCh4_ProcessReturn
	calr AccCh4_ScanSlots
	calr AccCh4_DrainRingBuf
	calr AccCh4_InitProgChange
	ld XIY,0x0000318c
	ld XIX,0x000031a5
	ld bc, 5:i3
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call AccVoice_LoadRhythmParams_Part5
	and (0x3290:16), 0xdf
AccCh4_ProcessReturn:
	ret

AccCh4_ScanSlots:
	ld	xhl, 12592
AccCh4_ScanSlots_Loop:
	call	AccSlot_CheckAndUpdate
	add	xhl, 9
	cp	xhl, 12664
	jr	c, AccCh4_ScanSlots_Loop
	ret
AccCh4_DrainRingBuf:
	ld	xhl, 12024
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	ld	xhl, 11256
	calr	AccBuf_WriteD0Defaults
	ret
AccCh2_InitProgChange:
	ld	xhl, 11512
	calr	AccBuf_WriteD0Defaults
	ret
AccCh3_InitProgChange:
	ld	xhl, 11768
	calr	AccBuf_WriteD0Defaults
	ret
AccCh4_InitProgChange:
	ld	xhl, 12024
	calr	AccBuf_WriteD0Defaults
	ret
AccBuf_WriteD0Defaults:
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	ld	(13201:16), 208
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 2
	ld	(13204:16), 64
	calr	AccBuf_Write3ByteEvent
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 1
	ld	(13204:16), 0
	calr	AccBuf_Write3ByteEvent
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 3
	ld	(13204:16), 0
	calr	AccBuf_Write3ByteEvent
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 5
	ld	(13204:16), 127
	calr	AccBuf_Write3ByteEvent
	ret
AccPart_Deactivate:
	ld	a, (13268:16)
	and	a, 192
	jr	nz, AccPart_Deactivate_WithPedal
	ld	a, (13112:16)
	and	a, (12941:16)
	jr	z, AccPart_Deactivate_NoPedal
AccPart_Deactivate_WithPedal:
	calr	AccPart_ResolveWithPedal
	ld	a, (13112:16)
	xor	a, 255
	and	(12941:16), a
	jrl	AccPart_DeactivateReturn
AccPart_Deactivate_NoPedal:
	ld	a, (0x327a:16)
	or	a, (0x327b:16)
	or	a, (0x327c:16)
	and	a, (0x3338:16)
	jr	nz, AccPart_Deactivate_ActiveNote
	bit	0, (0x3265:16)
	jr	nz, AccPart_Deactivate_WithSync
	bit	0, (0x3273:16)
	jr	nz, AccPart_Deactivate_SetDone
	jr	AccPart_Deactivate_SendOff
AccPart_Deactivate_WithSync:
	and	(0x3272:16), 252
	or	(0x3272:16), 1
	ld	a, (0x3338:16)
	and	a, (0x3276:16)
	jr	z, AccPart_Deactivate_SetDone
	or	(0x3272:16), 2
	jr	AccPart_Deactivate_SetDone
AccPart_Deactivate_ActiveNote:
	bit	0, (0x3273:16)
	jr	z, AccPart_Deactivate_SendOff
AccPart_Deactivate_SetDone:
	or	(0x3257:16), 128
	or	(0x3258:16), 1
	jr	AccPart_Deactivate_ClearMasks
AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	ld	a, (13112:16)
	xor	a, 255
	and	(12918:16), a
	and	(12919:16), a
	and	(12922:16), a
	and	(12923:16), a
	and	(12924:16), a
	ld	(13119:16), 0
	ld	(13134:16), 0
AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	ld	a, (13112:16)
	and	a, (13124:16)
	jr	z, AccPart_ReactivateReturn
	ld	a, (13112:16)
	ld	w, (12920:16)
	or	w, (12921:16)
	and	w, a
	jr	z, AccPart_Reactivate_Inactive
	or	(12942:16), a
	or	(12940:16), a
	ld	(13114:16), 254
	ld	(13116:16), 6
	jr	AccPart_ReactivateReturn
AccPart_Reactivate_Inactive:
	ld	a, (13112:16)
	xor	a, 255
	and	(12918:16), a
	and	(12919:16), a
	and	(12922:16), a
	and	(12923:16), a
	and	(12924:16), a
	and	(12993:16), a
	and	(12941:16), a
	ld	(13134:16), 0
	ld	(13114:16), 254
	ld	(13116:16), 6
AccPart_ReactivateReturn:
	ret

AccTick_Main:
	bit 2, (0x31e7:16)
	jrl nz, AccTick_CheckCollect
	calr AccTempo_BarCompare
	bit 6, (0x3258:16)
	jrl nz, AccTick_Return
	calr AccPedal_CheckCombined
	bit 6, (0x3258:16)
	jrl nz, AccTick_Return
	call AccTuning_ApplyChange
	bit 7, (0x3290:16)
	jr z, .Lc_f57c79
	call Rhythm_ProcessAllPartsAndLoad
	and (0x3290:16), 0x7f
AccTick_AfterSync:
.Lc_f57c79:
	call AccVoice_ProcessAllSixParts
	bit 5, (0x3258:16)
	jrl nz, AccTick_Return
	call AccKbd2_ProcessEntry
	call AccSeq_ScanPattern
	bit 0, (0x33de:16)
	jr nz, AccTick_ProcessAccChannels
	bit 0, (0x31e7:16)
	jr z, AccTick_CheckNoteOn
	ld wa, (0xc4fa:16)
	and WA,0x0200
	jr z, AccTick_CheckNoteOn
AccTick_ProcessAccChannels:
	call AccCh1_ProcessEntry
	call AccCh2_ProcessEntry
	call AccCh3_ProcessEntry
	call AccCh4_ProcessEntry

AccTick_CheckNoteOn:
	bit	7, (0x3257:16)
	jr	z, AccTick_CheckCollect
	and	(0x3257:16), 127
	call	AccTempo_CalcPosition
	bit	0, (0x3272:16)
	jr	nz, AccTick_DispatchNoteOn
	bit	0, (0x3273:16)
	jr	nz, AccTick_DispatchNoteOn
	bit	0, (0x3271:16)
	jr	nz, AccTick_DispatchNoteOn
	bit	0, (0x3270:16)
	jr	nz, AccTick_DispatchNoteOn
	ld	a, (0x326d:16)
	and	a, 3
	jr	nz, AccTick_DispatchNoteOn
	ld	a, (0x326e:16)
	and	a, 13
	jr	nz, AccTick_DispatchNoteOn
	ld	a, (0x326f:16)
	and	a, 3
	jr	z, AccTick_FlushAndRepeat
AccTick_DispatchNoteOn:
	call AccFlags_Aggregate

AccTick_FlushAndRepeat:
	call AccNote_FlushAll
	jrl AccTick_AfterSync

AccTick_CheckCollect:
	bit 2, (0x31e7:16)
	jr z, AccTick_Return
	call AccState_CollectAll
AccTick_Return:
	ret

AccVelocity_CurveTable:
	.byte 0x0d, 0x1a, 0x33, 0x4d, 0x66, 0x80, 0x9a, 0xb3
	.byte 0xcc, 0xe6, 0xff

AccVoice_InitPerChannel:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f57d21
	calr AccVoice_InitCh1_D7
	jr t, AccVoice_InitReturn
AccVoice_InitCh2:
.Lc_f57d21:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f57d2d
	calr AccVoice_InitCh2_D4
	jr t, AccVoice_InitReturn
AccVoice_InitCh3:
.Lc_f57d2d:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f57d39
	calr AccVoice_InitCh3_D5
	jr t, AccVoice_InitReturn
AccVoice_InitCh4:
.Lc_f57d39:
	cp (0x3338:16), 0x20
	jr nz, AccVoice_InitReturn
	calr AccVoice_InitCh4_D6
AccVoice_InitReturn:
	ret

AccVoice_InitCh1_D7:
	pushw	hl
	push	xiy
	ld	xhl, 11256
	calr	AccBuf_DrainAndReset
	ld	a, 215:opc
	ld	w, 2:opc
	ld	e, 64:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 215:opc
	ld	w, 1:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 215:opc
	ld	w, 3:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	(12947:16), 0
	ld	a, 215:opc
	ld	w, 5:opc
	ld	e, 127:opc
	call	Rhythm_Send3ByteMsg
	pop	xiy
	popw	hl
	ret
AccBuf_WriteD0WithVoice:
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	ld	(xhl+iy), 0xd0
	call RingBuf_AdvanceIndex
	ld a, (0x324e:16)
	ld (0x3392:16), a
	call RhythmAccent_UpdateRingBufPosition
	ld	(xhl+iy), 0x03
	call RingBuf_AdvanceIndex
	ld a, (0x3297:16)
	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ret
AccVoice_InitCh2_D4:
	pushw	hl
	push	xiy
	ld	xhl, 11512
	calr	AccBuf_DrainAndReset
	ld	a, 212:opc
	ld	w, 2:opc
	ld	e, 64:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 212:opc
	ld	w, 1:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 212:opc
	ld	w, 3:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	(12948:16), 0
	ld	a, 212:opc
	ld	w, 5:opc
	ld	e, 127:opc
	call	Rhythm_Send3ByteMsg
	pop	xiy
	popw	hl
	ret
AccVoice_InitCh3_D5:
	pushw	hl
	push	xiy
	ld	xhl, 11768
	calr	AccBuf_DrainAndReset
	ld	a, 213:opc
	ld	w, 2:opc
	ld	e, 64:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 213:opc
	ld	w, 1:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 213:opc
	ld	w, 3:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	(12949:16), 0
	ld	a, 213:opc
	ld	w, 5:opc
	ld	e, 127:opc
	call	Rhythm_Send3ByteMsg
	pop	xiy
	popw	hl
	ret
AccVoice_InitCh4_D6:
	pushw	hl
	push	xiy
	ld	xhl, 12024
	calr	AccBuf_DrainAndReset
	ld	a, 214:opc
	ld	w, 2:opc
	ld	e, 64:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 214:opc
	ld	w, 1:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	a, 214:opc
	ld	w, 3:opc
	ld	e, 0:opc
	call	Rhythm_Send3ByteMsg
	ld	(12950:16), 0
	ld	a, 214:opc
	ld	w, 5:opc
	ld	e, 127:opc
	call	Rhythm_Send3ByteMsg
	pop	xiy
	popw	hl
	ret
AccPedal_CheckCombined:
	bit 0, (0x3270:16)
	jr nz, AccPedal_CheckFlags
	ld a, (0x326f:16)
	and A,0x03
	jr z, AccPedal_CheckDirection
AccPedal_CheckFlags:
	ld	a, (12938:16)
	and	a, 63
	jr	z, AccPedal_TriggerReInit
AccPedal_CheckDirection:
	ld	a, (12910:16)
	and	a, 13
	jr	nz, AccPedal_CheckCounter
	ld	a, (12909:16)
	and	a, 3
	jr	z, AccPedal_CombinedReturn
AccPedal_CheckCounter:
	ld	a, (12939:16)
	and	a, 63
	jr	nz, AccPedal_CombinedReturn
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
	ld	a, (12918:16)
	or	a, (12919:16)
	and	a, 63
	jr	z, AccPedal_CheckCombined_Entry
	bit	0, (0x3265:16)
	jr	z, AccPedal_CheckCombined_Entry
	or	(0x3270:16), 1
	ld	a, (12918:16)
	and	a, 63
	jr	z, AccPedal_CheckCombined_Skip
	cp	(12958:16), 0
	jr	z, AccPedal_CheckCombined_Entry
	dec	1, (12958:16)
	jr	AccPedal_CheckCombined_Entry
AccPedal_CheckCombined_Skip:
	cp	(12958:16), 3
	jr	z, AccPedal_CheckCombined_Entry
	inc	1, (12958:16)
AccPedal_CheckCombined_Entry:
	bit	0, (0x3273:16)
	jr	nz, AccPedal_CheckCombined_Skip2
	bit	0, (0x3270:16)
	jr	z, AccPedal_CheckCombined_Skip3
	ld	a, (12938:16)
	and	a, 63
	jr	nz, AccPedal_CheckCombined_Skip3
AccPedal_CheckCombined_Skip2:
	calr	AccStyle_Init
	calr	AccVoice_SetupAllParts
	ld	a, (1075:16)
	ld	(1112:16), a
AccPedal_CheckCombined_Skip3:
	ld	a, (12910:16)
	and	a, 13
	jr	z, AccPedal_CheckCombined_Skip4
	calr	AccVoice_ResetAll
AccPedal_CheckCombined_Skip4:
	ld	a, (12909:16)
	and	a, 3
	jr	nz, AccPedal_CheckCombined_Join
	bit	6, (0x33d4:16)
	jr	z, AccPedal_CheckCombined_Entry2
	or	(0x326d:16), 1
	jr	AccPedal_CheckCombined_Join
AccPedal_CheckCombined_Entry2:
	bit	7, (0x33d4:16)
	jr	z, AccPedal_CheckCombined_Skip5
	or	(0x326d:16), 2
AccPedal_CheckCombined_Join:
	calr	AccVoice_SplitPointSetup
AccPedal_CheckCombined_Skip5:
	ld	a, (12911:16)
	and	a, 3
	jr	z, AccPedal_CheckCombined_Entry3
	calr	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	calr	AccVoice_ThirdLayer
AccPedal_CheckCombined_Entry3:
	and	(0x320f:16), 240
	and	(0x3210:16), 240
	and	(0x3211:16), 240
	and	(0x3212:16), 240
	and	(0x3213:16), 240
	and	(0x3214:16), 240
	calr	AccSeq_DualPartScan
	bit	6, (0x3258:16)
	jr	nz, AccPedal_CheckCombined_Entry4
	calr	AccSeq_FourChannelScan
AccPedal_CheckCombined_Entry4:
	or	(0x3290:16), 128
	ret
AccTempo_BarCompare:
	ld w, (0x3219:16)
	cp w, (0x3218:16)
	jr c, .Lc_f57f89
	jr z, AccTempo_BarEqual
	jr ugt, AccTempo_BarGreater
AccTempo_BarLess:
.Lc_f57f89:
	cp w, 0:i3
	jr nz, AccTempo_BarChanged
	cp (0x3218:16), 0xff
	jr nz, AccTempo_BarChanged
	jr t, AccTempo_ComputeSubDelta
AccTempo_BarEqual:
	ld	wa, (12871:16)
	cp	(12772:16), w
	jr	c, AccTempo_ComputeSubDelta
	jr	ugt, AccTempo_BarChanged
	cp	(12771:16), a
	jr	ule, AccTempo_ComputeSubDelta
	jr	AccTempo_BarChanged
AccTempo_BarGreater:
	cp	w, 255
	jr	nz, AccTempo_ComputeSubDelta
	cp	(12824:16), 0
	jr	nz, AccTempo_ComputeSubDelta
AccTempo_BarChanged:
	ld a, 0x1:opc
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	ld	wa, (12871:16)
	sub	a, (12771:16)
	jr	nc, AccTempo_StoreDelta
	add	a, 96
AccTempo_StoreDelta:
	ld	(12878:16), a
	ld	(12880:16), a
	ret
AccSeq_DualPartScan:
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31eb:16)
	ld (0x333c:16), wa
	ld a, (0x320f:16)
	ld (0x333f:16), a
	ld iz, (0x31fb:16)
	ld (0x333a:16), iz
	ld W, 0x01:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x31fb:16), wa
	ld a, (0x333f:16)
	ld (0x320f:16), a
	ld wa, (0x333c:16)
	ld (0x31eb:16), wa
	bit 6, (0x3258:16)
	jr nz, AccSeq_DualPartReturn
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31ed:16)
	ld (0x333c:16), wa
	ld a, (0x3210:16)
	ld (0x333f:16), a
	ld iz, (0x31fd:16)
	ld (0x333a:16), iz
	ld W, 0x02:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x31fd:16), wa
	ld a, (0x333f:16)
	ld (0x3210:16), a
	ld wa, (0x333c:16)
	ld (0x31ed:16), wa
AccSeq_DualPartReturn:
	ret

AccSeq_PatternScanner:
	ld iy, (0x333c:16)
	ld iz, (0x333a:16)
	and (0x3258:16), 0xfe

	xor bc, bc



AccSeq_ScannerLoop:
.Lc_f58072:
	bit 0, (0x3258:16)
	jrl nz, AccSeq_Scanner_Done
	ld	a, (xhl+iy)
	cp A,0x81
	jr nz, AccSeq_Scanner_EventType
	add B,0x01
	xor C,C
	cp DE,BC
	jr nc, .Lc_f58093
	or (0x3258:16), 0x01
	jr t, .Lc_f58072
AccSeq_Scanner_BarEnd:
.Lc_f58093:
	ld a, (0x333f:16)
	inc 1,A
	ld W,A
	and A,0x0f
	cp	a, (1075:16)
	jr	nz, AccSeq_Scanner_StorePos
	and	w, 240
	add	w, 16
AccSeq_Scanner_StorePos:
	ld	(13119:16), w
	calr	AccBuf_Advance
	jr	AccSeq_ScannerLoop
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
	calr	AccBuf_AdvanceWithPageTurn
	ld	c, a
	cp	de, bc
	jr	nc, AccSeq_Scanner_SkipFields
	or	(0x3258:16), 1
	jr	AccSeq_ScannerLoop
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
	calr	AccBuf_Advance
	calr	AccBuf_Advance
	ld	a, (xhl+iy)
	ld	(12951:16), a
	calr	AccBuf_Advance
	jrl	AccSeq_ScannerLoop	; -> 0xF58072
AccSeq_Scanner_Unknown:
	inc	1, (0x3252:16)
	cp	(0x3252:16), 32
	jr	c, AccSeq_Scanner_Skip1
	call	AccWrap_PlayModeDispatch
	call	AccDemo_InitDone
	ld	(0x3259:16), 255
	or	(0x3258:16), 65
AccSeq_Scanner_Skip1:
	calr AccBuf_Advance
	jrl AccSeq_ScannerLoop

AccSeq_Scanner_Done:
	ld	(13114:16), iz
	ld	(13116:16), iy
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
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31ef:16)
	ld (0x333c:16), wa
	ld a, (0x3211:16)
	ld (0x333f:16), a
	ld iz, (0x31ff:16)
	ld (0x333a:16), iz
	ld W, 0x04:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x31ff:16), wa
	ld a, (0x333f:16)
	ld (0x3211:16), a
	ld wa, (0x333c:16)
	ld (0x31ef:16), wa
	ld XHL,0x00002bf8
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x3258:16)
	jrl nz, AccSeq_FourChannelReturn
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31f1:16)
	ld (0x333c:16), wa
	ld a, (0x3212:16)
	ld (0x333f:16), a
	ld iz, (0x3201:16)
	ld (0x333a:16), iz
	ld W, 0x08:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x3201:16), wa
	ld a, (0x333f:16)
	ld (0x3212:16), a
	ld wa, (0x333c:16)
	ld (0x31f1:16), wa
	ld XHL,0x00002cf8
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x3258:16)
	jrl nz, AccSeq_FourChannelReturn
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31f3:16)
	ld (0x333c:16), wa
	ld a, (0x3213:16)
	ld (0x333f:16), a
	ld iz, (0x3203:16)
	ld (0x333a:16), iz
	ld W, 0x10:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x3203:16), wa
	ld a, (0x333f:16)
	ld (0x3213:16), a
	ld wa, (0x333c:16)
	ld (0x31f3:16), wa
	ld XHL,0x00002df8
	calr AccBuf_WriteD0WithVoice
	bit 6, (0x3258:16)
	jr nz, AccSeq_FourChannelReturn
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31f5:16)
	ld (0x333c:16), wa
	ld a, (0x3214:16)
	ld (0x333f:16), a
	ld iz, (0x3205:16)
	ld (0x333a:16), iz
	ld W, 0x20:opc
	calr AccVoice_SelectByMask
	calr AccSeq_PatternScanner
	ld wa, (0x333a:16)
	ld (0x3205:16), wa
	ld a, (0x333f:16)
	ld (0x3214:16), a
	ld wa, (0x333c:16)
	ld (0x31f5:16), wa
	ld XHL,0x00002ef8
	calr AccBuf_WriteD0WithVoice
AccSeq_FourChannelReturn:
	ret

AccStyle_Init:
	ld a, (0x324c:16)
	and A,0x7f
	and A,0x07
	ld (0x324a:16), a
	ld a, (0x324b:16)
	ld (0x3249:16), a
	call AccTuning_Init
	cp (0x3249:16), 0x80
	jr nc, AccStyle_ExtendedInit
	ld a, (0x329e:16)
	and A,0x03
	ld (0x329c:16), a
	ld a, (0x3249:16)
	ld h, (0x324a:16)
	call AccVoice_LookupWithOffset
	ld (0x3232:16), xiy
	call Rhythm_UpdateTuningConfig
	ld a, (0x3207:16)
	ld W, 0x00:opc
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	or (0x3290:16), 0x3f
	jr t, AccStyle_Finalize
AccStyle_ExtendedInit:
	ld	xiy, AccStyle_ExtStyleMap
	ld	a, (12873:16)
	and	a, 127
	cp	a, 29
	jr	ule, AccStyle_LookupTable
	xor	a, a
AccStyle_LookupTable:
	ld	a, (xiy+a)
	ld	(12956:16), a
	ld	a, (12873:16)
	and	a, 127
	call	AccVoice_ResolveParamAddr
	ld	(12850:16), xiy
	ld	l, (xiy+16)
	ld	h, (xiy+17)
	and	h, 15
	and	a, 7
	cp	hl, 520
	jr	z, AccStyle_LoadAndApply
	cp	hl, 792
	jr	z, AccStyle_LoadAndApply
	call	VoiceParam_ClampAndValidate
AccStyle_LoadAndApply:
	ld	a, l
	call	AccVoice_LookupWithOffset
	ld	(12855:16), xiy
	call	Rhythm_UpdateTuningConfig
	ld	xiy, (12850:16)
	call	AccTuning_CopyAllPartsFromStyle
	or	(0x3290:16), 63
	ld	w, (12873:16)
	call	AccPatch_SetByChordIndex
AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr AccInit_ClearAllFlags

AccInit_ClearAllFlags:
	and	(0x3270:16), 254
	and	(0x3271:16), 254
	and	(0x3272:16), 252
	xor	a, a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x32b1:16), a
	ld	(0x3221:16), a
	ld	(0x3222:16), a
	ld	(0x3223:16), a
	ld	(0x3224:16), a
	ld	(0x3225:16), a
	ld	(0x3226:16), a
	call	AccTone_CallWithSaveAll
	ret
AccVoice_SetupAllParts:
	cp (0x3249:16), 0x80
	jr c, AccVoice_SetupAll_Extended
	ld xiy, (0x3232:16)
	jr t, AccVoice_SetupAll_Dispatch
AccVoice_SetupAll_Extended:
	ld	xiy, (12850:16)
	ld	a, (xiy+977)
	ld	(12777:16), a
AccVoice_SetupAll_Dispatch:
	calr AccVoice_SetupKbd1
	calr AccVoice_SetupKbd2
	calr AccVoice_SetupAcc1
	calr AccVoice_SetupAcc2
	calr AccVoice_SetupAcc3
	calr AccVoice_SetupAcc4
	ret

AccVoice_SetupKbd1:
	and (0x320f:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupKbd1_Free
	ld (0x3338:16), 0x01
	ld a, (0x3207:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31eb:16), wa
	jr t, AccVoice_SetupKbd1_Return
AccVoice_SetupKbd1_Free:
	ld	(13112:16), 1
	call	AccPart_GetFreeVoiceAddr
	ld	(12795:16), wa
	ldw	(12779:16), 6
AccVoice_SetupKbd1_Return:
	ret

AccVoice_SetupKbd2:
	and (0x3210:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupKbd2_Free
	ld (0x3338:16), 0x02
	ld a, (0x3208:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31ed:16), wa
	jr t, AccVoice_SetupKbd2_Return
AccVoice_SetupKbd2_Free:
	ld	(13112:16), 2
	call	AccPart_GetFreeVoiceAddr
	ld	(12797:16), wa
	ldw	(12781:16), 6
AccVoice_SetupKbd2_Return:
	ret

AccVoice_SetupAcc1:
	and (0x3211:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupAcc1_Free
	ld (0x3338:16), 0x04
	ld a, (0x3209:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31ef:16), wa
	jr t, AccVoice_SetupAcc1_Return
AccVoice_SetupAcc1_Free:
	ld	(13112:16), 4
	call	AccPart_GetFreeVoiceAddr
	ld	(12799:16), wa
	ldw	(12783:16), 6
AccVoice_SetupAcc1_Return:
	ret

AccVoice_SetupAcc2:
	and (0x3212:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupAcc2_Free
	ld (0x3338:16), 0x08
	ld a, (0x320a:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31f1:16), wa
	jr t, AccVoice_SetupAcc2_Return
AccVoice_SetupAcc2_Free:
	ld	(13112:16), 8
	call	AccPart_GetFreeVoiceAddr
	ld	(12801:16), wa
	ldw	(12785:16), 6
AccVoice_SetupAcc2_Return:
	ret

AccVoice_SetupAcc3:
	and (0x3213:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupAcc3_Free
	ld (0x3338:16), 0x10
	ld a, (0x320b:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31f3:16), wa
	jr t, AccVoice_SetupAcc3_Return
AccVoice_SetupAcc3_Free:
	ld	(13112:16), 16
	call	AccPart_GetFreeVoiceAddr
	ld	(12803:16), wa
	ldw	(12787:16), 6
AccVoice_SetupAcc3_Return:
	ret

AccVoice_SetupAcc4:
	and (0x3214:16), 0x0f
	cp (0x3249:16), 0x80
	jr nc, AccVoice_SetupAcc4_Free
	ld (0x3338:16), 0x20
	ld a, (0x320c:16)
	call AccPart_LookupBoundVoiceParam
	call AccPart_GetParamAddr
	ld (0x31f5:16), wa
	jrl t, AccVoice_SetupAcc4_Return
AccVoice_SetupAcc4_Free:
	ld	(13112:16), 32
	call	AccPart_GetFreeVoiceAddr
	ld	(12805:16), wa
	ldw	(12789:16), 6
AccVoice_SetupAcc4_Return:
	ret

AccVoice_ResetAll:
	and (0x320f:16), 0x0f
	and (0x3210:16), 0x0f
	and (0x3211:16), 0x0f
	and (0x3212:16), 0x0f
	and (0x3213:16), 0x0f
	and (0x3214:16), 0x0f
	cp (0x3249:16), 0x80
	jr c, AccVoice_Reset_UseStyle
	bit 0, (0x32c7:16)
	jr z, AccVoice_Reset_UseSecondary
	calr AccVoice_Reassign
	jr t, AccVoice_Reset_SetMasks
AccVoice_Reset_UseSecondary:
	ld	xiy, (12855:16)
	jr	AccVoice_Reset_SelectMode
AccVoice_Reset_UseStyle:
	ld	xiy, (12850:16)
AccVoice_Reset_SelectMode:
	ldw	hl, 32
	bit	0, (0x326e:16)
	jr	nz, AccVoice_Reset_LoadParams
	ldw	hl, 34
	bit	2, (0x326e:16)
	jr	nz, AccVoice_Reset_LoadParams
	ldw	hl, 1056
AccVoice_Reset_LoadParams:
	calr	AccVoice_LoadAllParts
	cp	(0x3249:16), 128
	jr	c, AccVoice_Reset_Extended
	ld	xiy, (0x3232:16)
	call	AccTuning_CopyAllPartsFromStyle
	jr	AccVoice_Reset_ApplyAll
AccVoice_Reset_Extended:
	ld	a, (0x3207:16)
	ld	w, 3:opc
	bit	3, (0x326e:16)
	jr	z, AccVoice_Reset_SetMode
	ld	w, 4:opc
AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
AccVoice_Reset_SetMasks:
	bit	3, (0x326e:16)
	jrl	nz, AccVoice_Reset_Mode3
	bit	2, (0x326e:16)
	jr	nz, AccVoice_Reset_Mode2
	and	(0x326e:16), 254
	or	(0x327a:16), 63
	xor	a, a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x328c:16), a
	ld	(0x328e:16), a
	and	(0x31e7:16), 251
	jrl	AccVoice_Reset_Return
AccVoice_Reset_Mode2:
	and	(0x326e:16), 251
	or	(0x327b:16), 63
	xor	a, a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x327a:16), a
	ld	(0x327c:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x328c:16), a
	ld	(0x328e:16), a
	and	(0x31e7:16), 251
	jr	AccVoice_Reset_Return
AccVoice_Reset_Mode3:
	and	(0x326e:16), 247
	or	(0x327c:16), 63
	xor	a, a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x328c:16), a
	ld	(0x328e:16), a
	and	(0x31e7:16), 251
AccVoice_Reset_Return:
	ret

AccVoice_Reassign:
	bit 3, (0x326e:16)
	jrl nz, AccVoice_Reassign_Mode3
	bit 2, (0x326e:16)
	jr nz, AccVoice_Reassign_Mode2
	ld a, (0x3249:16)
	and A,0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x32c8:16)
	jr z, AccVoice_Reassign_MatchA
	and (0xfc5f:16), 0xfb
	ld E, 0x48:opc
	ld D, 0x05:opc
	ld W, 0x00:opc
	ld A, 0x00:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_Reassign_Apply
AccVoice_Reassign_MatchA:
	ld	a, (13001:16)
	call	AccVoice_ResolveParamAddr
	jr	AccVoice_Reassign_Apply
AccVoice_Reassign_Mode2:
	ld	a, (0x3249:16)
	and	a, 127
	call	AccPatch_SetVoiceParam
	ld	xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri	1, 0x03, 0xec, 0xe0
	jr	z, AccVoice_Reassign_Fallback
	and	(0xfc5f:16), 247
	ld	e, 72:opc
	ld	d, 5:opc
	ld	w, 0:opc
	ld	a, 0:opc
	call	Rhythm_QueuePartChangeEvent
	ld	xiy, (0x3232:16)
	jr	AccVoice_Reassign_Apply
AccVoice_Reassign_Mode3:
	ld a, (0x3249:16)
	and A,0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x32ca:16)
	jr z, AccVoice_Reassign_MatchB
	and (0xfc60:16), 0xfb
	ld E, 0x48:opc
	ld D, 0x06:opc
	ld W, 0x00:opc
	ld A, 0x00:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_Reassign_Apply
AccVoice_Reassign_MatchB:
	ld	a, (13003:16)
	call	AccVoice_ResolveParamAddr
AccVoice_Reassign_Apply:
	calr	AccInit_AllPartPositions
	call	AccTuning_CopyAllPartsFromStyle
	or	(0x3290:16), 63
	jr	AccVoice_Reassign_Return
AccVoice_Reassign_Fallback:
	ld xiy, (12855:16)

	ldw hl, 0x22

	; calr AccVoice_LoadAllParts (v7 displacement)
	calr	AccVoice_LoadAllParts
	xor xhl, xhl

	ldw hl, 0x126

	; call AccVoice_LoadTuningBlock (v7 addr)
	call	AccVoice_LoadTuningBlock
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
AccVoice_Reassign_Return:
	ret

AccVoice_SplitPointSetup:
	and (0x320f:16), 0x0f
	and (0x3210:16), 0x0f
	and (0x3211:16), 0x0f
	and (0x3212:16), 0x0f
	and (0x3213:16), 0x0f
	and (0x3214:16), 0x0f
	cp (0x3249:16), 0x80
	jr c, AccVoice_Split_UseStyle
	bit 0, (0x32c7:16)
	jr z, AccVoice_Split_UseSecondary
	calr AccVoice_SplitReassign
	jr t, AccVoice_Split_SetForward
AccVoice_Split_UseSecondary:
	ld	xiy, (12855:16)
	jr	AccVoice_Split_LoadAndApply
AccVoice_Split_UseStyle:
	ld	xiy, (12850:16)
AccVoice_Split_LoadAndApply:
	ld	a, (12807:16)
	call	AccVoice_ComputeParamAddr
	calr	AccVoice_LoadAllParts
	ld	a, (12807:16)
	call	AccTuning_SetAllFromLookup
	cp	(12873:16), 128
	jr	c, AccVoice_Split_StyleMode
	ld	xiy, (12850:16)
	call	AccTuning_CopyAllPartsFromStyle
	jr	AccVoice_Split_Apply63
AccVoice_Split_StyleMode:
	ld	a, (12807:16)
	ld	w, 2:opc
	call	AccPart_GetVoiceParamOffsetTable
	call	AccVoice_LoadTuningBlock
AccVoice_Split_Apply63:
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
AccVoice_Split_SetForward:
	bit	0, (0x326d:16)
	jr	z, AccVoice_Split_SetReverse
	and	(0x326d:16), 254
	or	(0x3276:16), 63
	xor	a, a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3277:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x328c:16), a
	ld	(0x328e:16), a
	and	(0x31e7:16), 251
	jr	AccVoice_Split_Return
AccVoice_Split_SetReverse:
	and	(0x326d:16), 253
	or	(0x3277:16), 63
	xor	a, a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3276:16), a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	ld	(0x328c:16), a
	ld	(0x328e:16), a
	and	(0x31e7:16), 251
AccVoice_Split_Return:
	ret

AccVoice_SplitReassign:
	bit 0, (0x326d:16)
	jr z, AccVoice_SplitReassign_Reverse
	ld a, (0x3249:16)
	and A,0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x32cc:16)
	jr z, AccVoice_SplitReassign_MatchFwd
	and (0xfc5f:16), 0xbf
	ld E, 0x48:opc
	ld D, 0x05:opc
	ld W, 0x00:opc
	ld A, 0x00:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_SplitReassign_Apply
AccVoice_SplitReassign_MatchFwd:
	ld	a, (13005:16)
	call	AccVoice_ResolveParamAddr
	jr	AccVoice_SplitReassign_Apply
AccVoice_SplitReassign_Reverse:
	ld	a, (0x3249:16)
	and	a, 127
	call	AccPatch_SetVoiceParam
	cp	a, (0x32ce:16)
	jr	z, AccVoice_SplitReassign_MatchRev
	and	(0xfc5f:16), 127
	ld	e, 72:opc
	ld	d, 5:opc
	ld	w, 0:opc
	ld	a, 0:opc
	call	Rhythm_QueuePartChangeEvent
	ld	xiy, (0x3232:16)
	jr	AccVoice_SplitReassign_Apply
AccVoice_SplitReassign_MatchRev:
	ld	a, (13007:16)
	call	AccVoice_ResolveParamAddr
AccVoice_SplitReassign_Apply:
	; calr AccInit_AllPartPositions (v7 displacement)
	calr	AccInit_AllPartPositions
	; call AccTuning_CopyAllPartsFromStyle (v7 addr)
	call	AccTuning_CopyAllPartsFromStyle
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
	ret



AccVoice_LoadAllParts:
	.byte 0xc3, 0xf5, 0xd1, 0x03, 0x21, 0xf1, 0xe9, 0x31
	.byte 0x41, 0xd7, 0x3c, 0x9b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x01, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xeb, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x02, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xed, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x04, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xef, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x08, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf1, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x10, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf3, 0x31
	.byte 0x50, 0xd7, 0x3c, 0x8b, 0xf1, 0x38, 0x33, 0x00
	.byte 0x20, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf5, 0x31
	.byte 0x50, 0x0e
AccInit_AllPartPositions:
	ld	(13112:16), 1
	call	AccPart_GetFreeVoiceAddr
	ld	(12795:16), wa
	ldw	(12779:16), 6
	ld	(13112:16), 4
	call	AccPart_GetFreeVoiceAddr
	ld	(12799:16), wa
	ldw	(12783:16), 6
	ld	(13112:16), 8
	call	AccPart_GetFreeVoiceAddr
	ld	(12801:16), wa
	ldw	(12785:16), 6
	ld	(13112:16), 16
	call	AccPart_GetFreeVoiceAddr
	ld	(12803:16), wa
	ldw	(12787:16), 6
	ld	(13112:16), 32
	call	AccPart_GetFreeVoiceAddr
	ld	(12805:16), wa
	ldw	(12789:16), 6
	ld	(13112:16), 2
	call	AccPart_GetFreeVoiceAddr
	ld	(12797:16), wa
	ldw	(12781:16), 6
	ret
AccVoice_ThirdLayer:
	and (0x320f:16), 0x0f
	and (0x3210:16), 0x0f
	and (0x3211:16), 0x0f
	and (0x3212:16), 0x0f
	and (0x3213:16), 0x0f
	and (0x3214:16), 0x0f
	cp (0x3249:16), 0x80
	jr c, AccVoice_ThirdLayer_Style
	bit 0, (0x32c7:16)
	jr z, AccVoice_ThirdLayer_Secondary
	calr AccVoice_ThirdLayerReassign
	jr t, AccVoice_ThirdLayer_SetMasks
AccVoice_ThirdLayer_Secondary:
	ld	xiy, (12855:16)
	jr	AccVoice_ThirdLayer_SelectMode
AccVoice_ThirdLayer_Style:
	ld	xiy, (12850:16)
AccVoice_ThirdLayer_SelectMode:
	ldw	hl, 36
	bit	0, (0x326f:16)
	jr	nz, AccVoice_ThirdLayer_LoadParams
	ldw	hl, 1060
AccVoice_ThirdLayer_LoadParams:
	calr	AccVoice_LoadAllParts
	ld	a, (0x3207:16)
	call	AccTuning_SetAllFromLookup
	cp	(0x3249:16), 128
	jr	c, AccVoice_ThirdLayer_StyleMode
	ld	xiy, (0x3232:16)
	call	AccTuning_CopyAllPartsFromStyle
	jr	AccVoice_ThirdLayer_Apply
AccVoice_ThirdLayer_StyleMode:
	ld	a, (0x3207:16)
	ld	w, 5:opc
	bit	1, (0x326f:16)
	jr	z, AccVoice_ThirdLayer_SetModeW
	ld	w, 6:opc
AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
AccVoice_ThirdLayer_SetMasks:
	bit	0, (0x326f:16)
	jr	z, AccVoice_ThirdLayer_Reverse
	and	(0x326f:16), 254
	or	(0x3278:16), 63
	xor	a, a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x3279:16), a
	ld	(0x32c1:16), a
	jr	AccVoice_ThirdLayer_Return
AccVoice_ThirdLayer_Reverse:
	and	(0x326f:16), 253
	or	(0x3279:16), 63
	xor	a, a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x3278:16), a
	ld	(0x32c1:16), a
AccVoice_ThirdLayer_Return:
	ret

AccVoice_ThirdLayerReassign:
	bit 0, (0x326f:16)
	jr z, AccVoice_ThirdReassign_Reverse
	ld a, (0x3249:16)
	and A,0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x32d0:16)
	jr z, AccVoice_ThirdReassign_MatchFwd
	and (0xfc5f:16), 0xef
	ld E, 0x48:opc
	ld D, 0x05:opc
	ld W, 0x00:opc
	ld A, 0x00:opc
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_ThirdReassign_Apply
AccVoice_ThirdReassign_MatchFwd:
	ld	a, (13009:16)
	call	AccVoice_ResolveParamAddr
	jr	AccVoice_ThirdReassign_Apply
AccVoice_ThirdReassign_Reverse:
	ld	a, (0x3249:16)
	and	a, 127
	call	AccPatch_SetVoiceParam
	cp	a, (0x32d2:16)
	jr	z, AccVoice_ThirdReassign_MatchRev
	and	(0xfc5f:16), 223
	ld	e, 72:opc
	ld	d, 5:opc
	ld	w, 0:opc
	ld	a, 0:opc
	call	Rhythm_QueuePartChangeEvent
	ld	xiy, (0x3232:16)
	jr	AccVoice_ThirdReassign_Apply
AccVoice_ThirdReassign_MatchRev:
	ld	a, (13011:16)
	call	AccVoice_ResolveParamAddr
AccVoice_ThirdReassign_Apply:
	; calr AccInit_AllPartPositions (v7 displacement)
	calr	AccInit_AllPartPositions
	; call AccTuning_CopyAllPartsFromStyle (v7 addr)
	call	AccTuning_CopyAllPartsFromStyle
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
	ret



AccBuf_WriteAllNotesOff:
	ld XHL,0x000029f8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	ld	(xhl+iy), 0x9f	; (unidasm; no llvm-mc spelling)
	call	16071765
	ld	a, (0x324e:16)
	ld	(0x3392:16), a
	call	16071703
	ld	a, 127:opc
	ld	(xhl+iy), a
	call	16071765
	ld	(xhl+iy), a
	call	16071765
	ld	(xhl+4), iy
	ret
AccBuf_AllNotesOffPadding:
	nop
	nop

AccBuf_ResetAll4:
	ld	xhl, 11256
	calr	AccBuf_DrainAndReset
	ld	xhl, 11512
	calr	AccBuf_DrainAndReset
	ld	xhl, 11768
	calr	AccBuf_DrainAndReset
	ld	xhl, 12024
	calr	AccBuf_DrainAndReset
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
	bit 1, (0x31e8:16)
	jr z, AccTiming_HelperReturn
	call SeqEvt_CallTimingHelper
	call Voice_UpdatePlayModeState
	call AccChord_ReadAndStoreKeys
	call AccChord_CompareAndSetDirty
	call Rhythm_CompareAndTrigger
AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	cp (0x3249:16), 0x80
	jr c, AccVoice_SelectByMask_Default
	ldfr_berp w, 0x31
	and w, (0x327b:16)
	jr nz, AccVoice_SelectByMask_Default
	bit 0, (0x32c7:16)
	jr nz, AccVoice_SelectByMask_Direct
	ld a, (0x327a:16)
	or a, (0x327c:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	or a, (0x328c:16)
	andb_erp	a, 49
	jr	nz, AccVoice_SelectByMask_Default
AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	ld	a, (12777:16)
	call	AccVoice_TableLookup
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
	add	xhl, 0x095c00
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
	xor	xhl, xhl
	xor	w, w
	ld	hl, wa
	sll	xhl, 2
	add	xhl, AccVoice_OffsetTable
	ld	xhl, (xhl)
	add	xhl, (12763:16)
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
	bit 3, (1054:16)

	jrl nz, AccState_CollectReturn

	bit 2, (1054:16)

	jrl z, AccState_CollectReturn

	ld xhl, 12280

	xor iy, iy

	ld	a, (xhl+iy)



AccState_CollectKbd1_Loop:
	or	a, (xhl+iy)
	add	iy, 6
	cp	iy, 48
	jr	c, AccState_CollectKbd1_Loop
	ld	xhl, 12328
	xor	iy, iy
AccState_CollectKbd2_Loop:
	or	a, (xhl+iy)
	add	iy, 6
	cp	iy, 48
	jr	c, AccState_CollectKbd2_Loop
	ld	xhl, 12376
	xor	iy, iy
AccState_CollectAcc1_Loop:
	or	a, (xhl+iy)
	add	iy, 9
	cp	iy, 72
	jr	c, AccState_CollectAcc1_Loop
	ld	xhl, 12448
	xor	iy, iy
AccState_CollectAcc2_Loop:
	or	a, (xhl+iy)
	add	iy, 9
	cp	iy, 72
	jr	c, AccState_CollectAcc2_Loop
	ld	xhl, 12520
	xor	iy, iy
AccState_CollectAcc3_Loop:
	or	a, (xhl+iy)
	add	iy, 9
	cp	iy, 72
	jr	c, AccState_CollectAcc3_Loop
	ld	xhl, 12592
	xor	iy, iy
AccState_CollectAcc4_Loop:
	or	a, (xhl+iy)
	add iy, 0x9
	cp iy, 0x48
	jr c, AccState_CollectAcc4_Loop
	bit 7, a
	jr nz, AccState_CollectReturn
	cpw (0x28b4:16), 0
	jr nz, AccState_CollectAcc4_Active
	cpw (0x28a8:16), 0
	jr nz, AccState_CollectAcc4_Active
	call AccWrap_PlayModeStopSync
	jr AccState_Apply

AccState_CollectAcc4_Active:
	call AccWrap_PlayModeStartPlay

AccState_Apply:
	call	AccInit_CallF435A9
	ld	a, (0xce43:16)
	ld	(0x8ca6:16), a
	ld	a, (0xce44:16)
	ld	(0x8ca4:16), a
	call	AccDisplay_RefreshIfDiskActive
	and	(0xfc5f:16), 207
	and	(0x31e7:16), 251
	xor	a, a
	ld	(0x3278:16), a
	ld	(0x3279:16), a
	ld	(0x3276:16), a
	ld	(0x3277:16), a
	ld	(0x327a:16), a
	ld	(0x327b:16), a
	ld	(0x327c:16), a
	or	(0x3403:16), 2
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
	cp	a, 131
	jr	z, AccVoice_ScanDone2	; -> 0xF58F11
	cp	a, 211
	jr	nz, AccVoice_ScanSkip	; -> 0xF58F0B
	call	AccBuf_Advance
	call	AccBuf_Advance
	ld	a, (xhl+iy)
	ld	(12951:16), a
AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	ld	(0x3338:16), 4
	ld	e, (0x32ad:16)
	ld	(0x3297:16), 0
AccVoice_ScanForD3_Join:
	ld	xiy, (0x3232:16)
	cp	e, (0x3209:16)
	jr	z, AccVoice_ScanForD3_Return
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x31e9:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join
AccVoice_ScanForD3_Return:
	ret
	ld	(0x3338:16), 8
	ld	e, (0x32ad:16)
	ld	(0x3297:16), 0
AccVoice_ScanForD3_Join2:
	ld	xiy, (0x3232:16)
	cp	e, (0x320a:16)
	jr	z, AccVoice_ScanForD3_Return2
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x31e9:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join2
AccVoice_ScanForD3_Return2:
	ret
	ld	(0x3338:16), 8
	ld	e, (0x32ad:16)
	ld	(0x3297:16), 0
AccVoice_ScanForD3_Join3:
	ld	xiy, (0x3232:16)
	cp	e, (0x320b:16)
	jr	z, AccVoice_ScanForD3_Return3
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x31e9:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join3
AccVoice_ScanForD3_Return3:
	ret
	ld	(0x3338:16), 8
	ld	e, (0x32ad:16)
	ld	(0x3297:16), 0
AccVoice_ScanForD3_Join4:
	ld	xiy, (0x3232:16)
	cp	e, (0x320c:16)
	jr	z, AccVoice_ScanForD3_Return4
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (0x31e9:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	AccVoice_ScanForD3_Join4
AccVoice_ScanForD3_Return4:
	ret
	ld	a, (xiy+977)
	ld	(0x31e9:16), a
	ld	(0x3338:16), 1
	ld	a, (0x3207:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31eb:16), wa
	ld	(0x3338:16), 2
	ld	a, (0x3208:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31ed:16), wa
	ld	(0x3338:16), 4
	ld	a, (0x3209:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31ef:16), wa
	ld	(0x3338:16), 8
	ld	a, (0x320a:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f1:16), wa
	ld	(0x3338:16), 16
	ld	a, (0x320b:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f3:16), wa
	ld	(0x3338:16), 32
	ld	l, (0x320c:16)
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	(0x31f5:16), wa
	ret
AccFlags_Aggregate:
	and (0x328a:16), 0xc0
	and (0x328b:16), 0xc0
	calr AccBuf_ResetAll4Positions
	bit 0, (0x3272:16)
	jr z, AccFlags_BuildIndex
	or (0x3271:16), 0x01
	bit 1, (0x3272:16)
	jr z, .Lc_f59099
	cp (0x329e:16), 0x00
	jr z, AccFlags_BuildIndex
	dec 1, (0x329e:16)
	jr t, AccFlags_BuildIndex
AccFlags_CheckDecay:
.Lc_f59099:
	cp (0x329e:16), 0x03
	jr z, AccFlags_BuildIndex
	inc 1, (0x329e:16)
AccFlags_BuildIndex:
	xor	w, w
	ld	a, (12910:16)
	and	a, 13
	jr	z, AccFlags_CheckDir65
	or	w, 1
AccFlags_CheckDir65:
	ld	a, (12909:16)
	and	a, 3
	jr	z, AccFlags_CheckDir67
	or	w, 2
AccFlags_CheckDir67:
	ld	a, (12911:16)
	and	a, 3
	jr	z, AccFlags_CheckNoteOn
	or	w, 4
AccFlags_CheckNoteOn:
	bit	0, (0x3270:16)
	jr	z, AccFlags_CheckSync69
	or	w, 8
	bit	6, (0x33d4:16)
	jr	z, AccFlags_PedalBit7
	or	w, 2
	or	(0x326d:16), 1
AccFlags_PedalBit7:
	bit	7, (0x33d4:16)
	jr	z, AccFlags_CheckSync69
	or	w, 2
	or	(0x326d:16), 2
AccFlags_CheckSync69:
	bit	0, (0x3271:16)
	jr	z, AccFlags_CheckSync71
	or	w, 8
AccFlags_CheckSync71:
	bit	0, (0x3273:16)
	jr	z, AccFlags_Dispatch
	or	w, 8
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
	call	16089851
	call	AccVoice_SetupAllParts
	and	(0x327a:16), 192
	and	(0x327b:16), 192
	and	(0x327c:16), 192
	and	(0x3276:16), 192
	and	(0x3277:16), 192
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
	ld	xhl, 11256
	calr	AccBuf_ResetOnePosition
	ld	xhl, 11512
	calr	AccBuf_ResetOnePosition
	ld	xhl, 11768
	calr	AccBuf_ResetOnePosition
	ld	xhl, 12024
	calr	AccBuf_ResetOnePosition
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
	ld A, 0x00:opc
	ld XHL,0x00003058
	xor IY,IY
AccBuf_ResetByteData_Loop:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop
	ld	xhl, 12448
	xor	iy, iy
AccBuf_ResetByteData_Loop2:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop2
	ld	xhl, 12520
	xor	iy, iy
AccBuf_ResetByteData_Loop3:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop3
	ld	xhl, 12592
	xor	iy, iy
AccBuf_ResetByteData_Loop4:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, AccBuf_ResetByteData_Loop4
	ret
AccNote_FlushAll:
	ld a, (0x3290:16)
	and A,0x3f
	jr z, AccNote_FlushReturn
	call RhythmPart_CopyData
	call RhythmPart1_ProcessAccentData
	ld A, 0x01:opc
	ld (0x3250:16), a
	call RhythmPart2_ProcessAccentData
	call AccVoice_LoadRhythmParams_Part3
	call AccVoice_LoadRhythmParams_Part4
	call AccVoice_LoadRhythmParams_Part5
	and (0x3290:16), 0xc0
AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	ld	a, 95:opc
	ld	w, (1112:16)
	dec	1, w
	call	AccVoice_LookupTableAddress
	ld	bc, (12769:16)
	ld	w, (12825:16)
	dec	1, w
	call	AccTempo_PositionCompare
	ld	(12880:16), a
	ld	(12878:16), a
	ret
AccInit_FullReInit:
	call Rhythm_SendNoteOnMax
	call AccompVoice_BulkReadRegisters
	calr AccBuf_WriteAllNotesOff
	call Rhythm_SendChanPressure
	calr AccBuf_ResetAll4
	ld a, (0x3276:16)
	or a, (0x3277:16)
	and A,0x3f
	jr z, .Lc_f592f0
	bit 0, (0x3265:16)
	jr z, .Lc_f592f0
	or (0x3270:16), 0x01
	ld a, (0x3276:16)
	and A,0x3f
	jr z, .Lc_f592e5
	cp (0x329e:16), 0x00
	jr z, .Lc_f592f0
	dec 1, (0x329e:16)
	jr t, .Lc_f592f0
AccInit_ReInit_AdjustDecay:
.Lc_f592e5:
	cp (0x329e:16), 0x03
	jr z, .Lc_f592f0
	inc 1, (0x329e:16)
AccInit_ReInit_CheckNoteOn:
.Lc_f592f0:
	bit 0, (0x3270:16)
	jr z, AccInit_ReInit_CheckModes
	ld a, (0x328a:16)
	and A,0x3f
	jr nz, AccInit_ReInit_CheckModes
	calr AccStyle_Init
	calr AccVoice_SetupAllParts
	ld a, (0x0433:16)
	ld (0x0458:16), a
AccInit_ReInit_CheckModes:
	ld	a, (12910:16)
	and	a, 13
	jr	z, AccInit_ReInit_CheckSplit
	calr	AccVoice_ResetAll
AccInit_ReInit_CheckSplit:
	ld	a, (0x326d:16)
	and	a, 3
	jr	nz, AccInit_ReInit_ApplySplit
	bit	6, (0x33d4:16)
	jr	z, AccInit_ReInit_CheckPedalBit7
	or	(0x326d:16), 1
	jr	AccInit_ReInit_ApplySplit
AccInit_ReInit_CheckPedalBit7:
	bit	7, (0x33d4:16)
	jr	z, AccInit_ReInit_CheckThird
	or	(0x326d:16), 2
AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	ld	a, (12911:16)
	and	a, 3
	jr	z, AccInit_ReInit_ClearHighBits
	calr	AccTiming_CallHelper
	call	AccInit_ResetSongCounter
	calr	AccVoice_ThirdLayer
AccInit_ReInit_ClearHighBits:
	and	(0x320f:16), 240
	and	(0x3210:16), 240
	and	(0x3211:16), 240
	and	(0x3212:16), 240
	and	(0x3213:16), 240
	and	(0x3214:16), 240
	calr	AccSeq_DualPartScan
	bit	6, (0x3258:16)
	jr	nz, AccInit_ReInit_SetDirty
	calr	AccSeq_FourChannelScan
AccInit_ReInit_SetDirty:
	; ordi8 0x332c, 128 (v7 patched)
	or	(0x3290:16), 128
	ret



AccInit_ResetSongCounter:
	cp (0x3246:16), 0x00
	jr nz, AccInit_ResetSong_Store
	call SeqVoice_SendNoteOffAndFlush
AccInit_ResetSong_Store:
	ld	(12870:16), 0
	ret
AccInit_CallF435A9:
	call SeqVoice_SendNoteOffAndFlush
	ret

AccTuning_CheckChange:
	cp (0x3249:16), 0x80
	jr nc, AccTuning_ChangeReturn
	ld a, (0x32f5:16)
	xor a, (0x32f6:16)
	bit 0x00,A
	jr z, AccTuning_ChangeReturn
	or (0x32f7:16), 0x01
AccTuning_ChangeReturn:
	ret

AccTuning_LoadFromROM:
	push	xwa
	push	xhl
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jrl	z, AccTuning_LoadReturn
	ld	a, (xhl+4)
	ld	(0x31b8:16), a
	ld	a, (xhl+5)
	ld	w, a
	and	w, 127
	ld	(0x31b9:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31bb:16), a
	ld	a, (xhl+6)
	ld	(0x31bf:16), a
	ld	a, (xhl+7)
	ld	w, a
	and	w, 127
	ld	(0x31c0:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31c2:16), a
	ld	a, (xhl+8)
	ld	(0x31c6:16), a
	ld	a, (xhl+9)
	ld	w, a
	and	w, 127
	ld	(0x31c7:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31c9:16), a
	ld	a, (xhl+2)
	ld	(0x31b1:16), a
	ld	a, (xhl+3)
	ld	w, a
	and	w, 127
	ld	(0x31b2:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31b4:16), a
	ld	a, (xhl+0:8)
	ld	(0x31aa:16), a
	ld	a, (xhl+1)
	and	a, 127
	ld	(0x31ab:16), a
AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jr	z, AccTuning_LoadMasterReturn
	ld	a, (xhl+0:8)
	ld	(0x31aa:16), a
	ld	a, (xhl+1)
	and	a, 127
	ld	(0x31ab:16), a
AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jr	z, AccTuning_LoadCoarseReturn
	ld	a, (xhl+2)
	ld	(0x31b1:16), a
	ld	a, (xhl+3)
	ld	w, a
	and	w, 127
	ld	(0x31b2:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31b4:16), a
AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jr	z, AccTuning_LoadFineReturn
	ld	a, (xhl+4)
	ld	(0x31b8:16), a
	ld	a, (xhl+5)
	ld	w, a
	and	w, 127
	ld	(0x31b9:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31bb:16), a
AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jr	z, AccTuning_LoadOctaveReturn
	ld	a, (xhl+6)
	ld	(0x31bf:16), a
	ld	a, (xhl+7)
	ld	w, a
	and	w, 127
	ld	(0x31c0:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31c2:16), a
AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	call	AccHelper_ComputeVoiceOffset
	add	xhl, 1996816
	bit	7, (xhl+1)
	jr	z, AccTuning_LoadTransposeReturn
	ld	a, (xhl+8)
	ld	(0x31c6:16), a
	ld	a, (xhl+9)
	ld	w, a
	and	w, 127
	ld	(0x31c7:16), w
	and	a, 128
	srl	a, 7
	ld	(0x31c9:16), a
AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	bit 0, (0x32f7:16)
	jrl z, AccTuning_ApplyReturn
	call AccHelper_ComputeVoiceOffset
	add XHL,0x001e7810
	bit 0, (0x32f5:16)
	jr z, AccTuning_ApplyChange_ClearBit
	or	(xhl+1), 128
	jr	AccTuning_ApplyChange_SelectMode
AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_ApplyChange_SelectMode:
	ld	a, (12922:16)
	or	a, (12923:16)
	and	a, 63
	jrl	nz, AccTuning_Mode_078
	ld	a, (12924:16)
	and	a, 63
	jr	nz, AccTuning_Mode_080
	ld	a, (12920:16)
	and	a, 63
	jr	nz, AccTuning_Mode_076
	or	a, (12921:16)
	and	a, 63
	jr	nz, AccTuning_Mode_077
	ld	a, (12918:16)
	or	a, (12919:16)
	and	a, 63
	jr	nz, AccTuning_Mode_074
	ld	a, (12993:16)
	and	a, 63
	jr	nz, AccTuning_Mode_149
	jr	AccTuning_Mode_None
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
	; ldb_d8 a, (0x32a3) (v7 patched)
	ld	a, (0x3207:16)
	; ldda32 xiy, (0x32ce) (v7 patched)
	ld	xiy, (0x3232:16)
	; call AccPart_GetVoiceParamOffsetTable (v7 addr)
	call	AccPart_GetVoiceParamOffsetTable
	; call AccVoice_LoadTuningBlock (v7 addr)
	call	AccVoice_LoadTuningBlock
	; ordi8 0x332c, 63 (v7 patched)
	or	(0x3290:16), 63
	; ordi8 0x332c, 128 (v7 patched)
	or	(0x3290:16), 128
AccTuning_ApplyReturn:
	; anddi8 (0x3393), 254 (v7 patched)
	and	(0x32f7:16), 254
	ret



AccTuning_Toggle:
	cp (0x3249:16), 0x80
	jr nc, AccTuning_Toggle_NoStyle
	ld a, (0x32f5:16)
	xor a, (0x32f6:16)
	bit 0x00,A
	jr z, AccTuning_Toggle_CheckDirty
	call AccHelper_ComputeVoiceOffset
	add XHL,0x001e7810
	bit 0, (0x32f5:16)
	jr z, AccTuning_Toggle_ClearBit
	or	(xhl+1), 128
	jr	AccTuning_Toggle_SetFlag
AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_Toggle_SetFlag:
	or	(0x329f:16), 1
	jr	AccTuning_Toggle_Return
AccTuning_Toggle_CheckDirty:
	bit	0, (0x32f7:16)
	jr	z, AccTuning_Toggle_Return
	and	(0x32f7:16), 254
	or	(0x329f:16), 1
	jr	AccTuning_Toggle_Return
AccTuning_Toggle_NoStyle:
	; anddi8 (0x3391), 254 (v7 patched)
	and	(0x32f5:16), 254
	; call AccTuning_LEDOff (v7 addr)
	call	AccTuning_LEDOff
AccTuning_Toggle_Return:
	ret

AccTuning_SaveState:
	ld	a, (13045:16)
	ld	(13046:16), a
	ret
AccTuning_Init:
	push XWA
	push XHL
	cp (0x3249:16), 0x80
	jr nc, .Lc_f59640
	call AccHelper_ComputeVoiceOffset
	add XHL,0x001e7810
	bit 7,(XHL+0x01)
	jr z, .Lc_f59640
	or (0x32f5:16), 0x01
	call AccTuning_LEDOn
	ld a, (0x32f5:16)
	ld (0x32f6:16), a
	jr t, AccTuning_Init_Epilogue
AccTuning_Init_NoTuning:
.Lc_f59640:
	and (0x32f5:16), 0xfe
	call AccTuning_LEDOff
	ld a, (0x32f5:16)
	ld (0x32f6:16), a
AccTuning_Init_Epilogue:
	pop xhl
	pop xwa
	ret

AccTuning_DisableIfNoStyle:
	cp (0x3249:16), 0x80
	jr c, AccTuning_DisableReturn
	and (0x32f5:16), 0xfe
	call AccTuning_LEDOff
AccTuning_DisableReturn:
	ret

AccTuning_LEDOn:
	ld	(13044:16), 1
	ld	a, 74:opc
	call	CtrlPanel_SetIndicatorBit
	ret
AccTuning_LEDOff:
	ld	(13044:16), 0
	ld	a, 74:opc
	call	CtrlPanel_SetIndicatorBit
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
	ld	a, (49121:16)
	ld	(13294:16), a
	cp	a, 5:i3
	jr	z, AccPedal_TypeSustainOrExpr
	cp	a, 6:i3
	jr	z, AccPedal_TypeSustainOrExpr
	jr	AccPedal_CheckType0
AccPedal_TypeSustainOrExpr:
	ld	a, (49122:16)
	ld	(13282:16), a
	ld	a, (49123:16)
	cp	a, 255
	jr	nz, AccPedal_ParseValue
	xor	a, a
AccPedal_ParseValue:
	ld	(13283:16), a
	calr	AccPedal_SustainHandler
	calr	AccPedal_ExprToggle
	calr	AccPedal_DistributeParams
AccPedal_CheckType0:
	ld	a, (49121:16)
	cp	a, 0:i3
	jr	z, AccPedal_SavePosition
	cp	a, 7:i3
	jr	nz, AccPedal_EventReturn
	ld	a, (49123:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, AccPedal_EventReturn
AccPedal_SavePosition:
	calr AccPos_SaveOnStop

AccPedal_EventReturn:
	ret

AccPedal_RawHandler:
	nop
	nop
AccPedal_RawHandler_Join:
	ld	a, (49121:16)
	cp	a, 3:i3
	jr	nz, 27
	ld	a, (49122:16)
	and	a, 7
	ld	(13282:16), a
	ld	a, (49123:16)
	ld	(13283:16), a
	ld	a, (49121:16)
	ld	(13294:16), a
	ret
	nop
	nop
AccPedal_SustainHandler:
	cp (0x33ee:16), 0x05
	jrl nz, AccPedal_SustainReturn
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x00,A
	jr nz, .Lc_f597aa
	jp AccPedal_SustainReturn
AccPedal_Sustain_CallReset:
.Lc_f597aa:
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call CompIface_ResetPedal
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	cp (0x7e6f:16), 0x00
	jr z, .Lc_f597ca
	call AccPlay_ToggleEntry
	jrl t, AccPedal_SustainReturn
AccPedal_Sustain_CheckStyle:
.Lc_f597ca:
	cp (0x8c9a:16), 0x6f
	jr z, AccPedal_Sustain_SpecialStyle
	cp (0x8c9a:16), 0x70
	jr z, AccPedal_Sustain_SpecialStyle
	cp (0x8c9a:16), 0x71
	jr z, AccPedal_Sustain_SpecialStyle
	cp (0x8c9a:16), 0x72
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
	cp	(0x8c9a:16), 120
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 122
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 115
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 116
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 117
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 118
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 119
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 121
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 108
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 109
	jr	z, AccPedal_Sustain_MultiMatch
	cp	(0x8c9a:16), 110
	jr	nz, AccPedal_Sustain_Normal
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
	ld (1057:16), a
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
	cp (0x8c9a:16), 0x6f
	jr z, AccPedal_StyleCheck_Ineligible
	cp (0x8c9a:16), 0x6c
	jr c, .Lc_f598bc
	cp (0x8c9a:16), 0x7a
	jr ugt, .Lc_f598bc
	jr t, AccPedal_StyleCheck_Ineligible
AccPedal_StyleCheck_Extended:
.Lc_f598bc:
	cp (0x8c98:16), 0x13
	jr z, AccPedal_StyleCheck_Ineligible
	cp (0x8c9a:16), 0x78
	jr z, AccPedal_StyleCheck_Match120
	jr t, AccPedal_StyleCheck_Eligible
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
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_ExprReturn
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x01,A
	jr z, AccPedal_ExprReturn
	ld A, 0x02:opc
	xor	(0xfc5f:16), a
	cp	(0x905c:16), 255
	jr	z, AccPedal_ExprReturn
	bit	3, (0xfd56:16)
	jr	z, AccPedal_ExprReturn
	ld	e, (0xfc5f:16)
	and	e, 2
	ld	xix, 14412
	ld	(xix+0:8), 72
	ld	(xix+1), 5
	ld	(xix+2), e
	ld	(xix+3), 2
	push	xix
	call	16621555
	inc	4, xsp
AccPedal_ExprReturn:
	ret

AccPedal_ExprPadding:
	nop
	nop

AccPedal_DistributeParams:
	cp (0x8c98:16), 0x0e
	jr z, AccPedal_Distribute_JumpMain
	bit 0, (0x28a6:16)
	jr z, AccPedal_Distribute_ClearAll
AccPedal_Distribute_JumpMain:
	jp AccPedal_DistributeReturn

AccPedal_Distribute_ClearAll:
	xor	wa, wa
	ld	(0x33e4:16), a
	ld	(0x33e5:16), a
	ld	(0x33e6:16), a
	ld	(0x33e7:16), a
	ld	(0x33e8:16), a
	ld	(0x33e9:16), a
	ld	(0x33ea:16), a
	ld	(0x33eb:16), a
	calr	AccPedal_ProcessAllBits
	bit	3, (0xd53:16)
	jr	z, AccPedal_Distribute_CheckRecord
	and	(0xfc5f:16), 15
	ld	(0x33e5:16), 0
	ld	(0x33e7:16), 0
	ld	(0x33e9:16), 0
	ld	(0x33eb:16), 0
AccPedal_Distribute_CheckRecord:
	calr	AccPedal_StateSync
	bit	3, (0xd53:16)
	jr	z, AccPedal_DistributeReturn
	cp	(0xd65:16), 0
	jr	z, AccPedal_DistributeReturn
	xor	wa, wa
	ld	(0x33e4:16), a
	ld	(0x33e5:16), a
	ld	(0x33e8:16), a
	ld	(0x33e9:16), a
	calr	AccPedal_MapToAcc
	calr	AccPedal_SendEvents
AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	nop
	nop

AccPedal_SendEvents:
	ld	a, (13284:16)
	xor	a, 255
	and	a, (13285:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendEvents_Group2
	ld	b, 5:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13284:16)
	call	16556753
AccPedal_SendEvents_Group2:
	ld	a, (13288:16)
	xor	a, 255
	and	a, (13289:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendEvents_OnSustain
	ld	b, 6:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13288:16)
	call	MIDI_TransmitTempoCC
AccPedal_SendEvents_OnSustain:
	ld	a, (13284:16)
	and	a, (13285:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendEvents_OnExpr
	ld	b, 5:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13284:16)
	call	MIDI_TransmitTempoCC
AccPedal_SendEvents_OnExpr:
	ld	a, (13288:16)
	and	a, (13289:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendEventsReturn
	ld	b, 6:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13288:16)
	call	16556753
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
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit2_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x02,A
	jr z, AccPedal_Bit2_Off
	orw (0x1108:16), 0x0004
	cp (0x905c:16), 0x7f
	jr z, AccPedal_Bit2_CheckPlay
	calr AccPedal_SustainOn
	jr t, AccPedal_Bit2_Off
AccPedal_Bit2_CheckPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Bit2_Sostenuto
	calr AccPedal_SustainOn
	jr AccPedal_Bit2_Off

AccPedal_Bit2_Sostenuto:
	calr AccPedal_SostenutoOn

AccPedal_Bit2_Off:
	bit	2, (0x33e3:16)
	jr	z, AccPedal_Bit2_Return
	bit	2, (0x33e2:16)
	jr	nz, AccPedal_Bit2_Return
	cp	(0x905c:16), 127
	jr	z, AccPedal_Bit2_OffPlay
	calr	AccPedal_SustainOff
	jr	AccPedal_Bit2_Return
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
	cp (0x33ee:16), 0x06
	jr nz, AccPedal_Expr_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x02,A
	jr z, AccPedal_Expr_Off
	ld de, 4:i3
	sla DE, 0x08
	or	(0x1108:16), de
	cp	(0x905c:16), 127
	jr	z, AccPedal_Expr_CheckPlay
	calr	AccPedal_ExprOn
	jr	AccPedal_Expr_Off
AccPedal_Expr_CheckPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Expr_Soft
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_Soft:
	calr AccPedal_SoftOn

AccPedal_Expr_Off:
	bit	2, (0x33e3:16)
	jr	z, AccPedal_Expr_Return
	bit	2, (0x33e2:16)
	jr	nz, AccPedal_Expr_Return
	cp	(0x905c:16), 127
	jr	z, AccPedal_Expr_OffPlay
	calr	AccPedal_ExprOff
	jr	AccPedal_Expr_Return
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
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit7_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x07,A
	jr z, AccPedal_Bit7_Off
	orw (0x1108:16), 0x0080
	bit 2, (0x041e:16)
	jr z, AccPedal_Bit7_Damper
	calr AccPedal_PortamentoOn
	jr t, AccPedal_Bit7_Off
AccPedal_Bit7_Damper:
	calr AccPedal_DamperOn

AccPedal_Bit7_Off:
	bit	7, (0x33e3:16)
	jr	z, AccPedal_Bit7_Return
	bit	7, (0x33e2:16)
	jr	nz, AccPedal_Bit7_Return
	bit	2, (0x41e:16)
	jr	z, AccPedal_Bit7_OffDamper
	calr	AccPedal_PortamentoOff
	jr	AccPedal_Bit7_Return
AccPedal_Bit7_OffDamper:
	calr AccPedal_DamperOff

AccPedal_Bit7_Return:
	ret

AccPedal_Bit6_Hold:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit6_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x06,A
	jr z, .Lc_f59b49
	orw (0x1108:16), 0x0040
	bit 2, (0x041e:16)
	jr z, .Lc_f59b49
	calr AccPedal_HoldOn
	jr t, .Lc_f59b49
AccPedal_Bit6_HoldOff:
.Lc_f59b49:
	bit 6, (0x33e3:16)
	jr z, AccPedal_Bit6_Return
	bit 6, (0x33e2:16)
	jr nz, AccPedal_Bit6_Return
	bit 2, (0x041e:16)
	jr z, AccPedal_Bit6_Return
	calr AccPedal_HoldOff
	jr t, AccPedal_Bit6_Return
AccPedal_Bit6_Return:
	ret

AccPedal_Bit4_Sostenuto:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit4_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x04,A
	jr z, .Lc_f59b7e
	bit 2, (0x041e:16)
	jr z, .Lc_f59b7e
	calr AccPedal_SostenutoOn
AccPedal_Bit4_Off:
.Lc_f59b7e:
	bit 4, (0x33e3:16)
	jr z, AccPedal_Bit4_Return
	bit 4, (0x33e2:16)
	jr nz, AccPedal_Bit4_Return
	bit 2, (0x041e:16)
	jr z, AccPedal_Bit4_Return
	calr AccPedal_SostenutoOff
AccPedal_Bit4_Return:
	ret

AccPedal_Bit5_Soft:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit5_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x05,A
	jr z, .Lc_f59bb1
	bit 2, (0x041e:16)
	jr z, .Lc_f59bb1
	calr AccPedal_SoftOn
AccPedal_Bit5_Off:
.Lc_f59bb1:
	bit 5, (0x33e3:16)
	jr z, AccPedal_Bit5_Return
	bit 5, (0x33e2:16)
	jr nz, AccPedal_Bit5_Return
	bit 2, (0x041e:16)
	jr z, AccPedal_Bit5_Return
	calr AccPedal_SoftOff
AccPedal_Bit5_Return:
	ret

AccPedal_Bit3_Damper:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit3_Return
	ld a, (0x33e2:16)
	and a, (0x33e3:16)
	bit 0x03,A
	jr z, .Lc_f59bde
	calr AccPedal_DamperOn
AccPedal_Bit3_Off:
.Lc_f59bde:
	bit 3, (0x33e3:16)
	jr z, AccPedal_Bit3_Return
	bit 3, (0x33e2:16)
	jr nz, AccPedal_Bit3_Return
	calr AccPedal_DamperOff
AccPedal_Bit3_Return:
	ret

AccPedal_StateSync:
	cp	(0x905c:16), 127
	jr	z, AccPedal_Sync_SendEvents
	cp	(0x905c:16), 255
	jr	nz, AccPedal_Sync_DispatchAll
AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	cp	(0x905c:16), 255
	jr	z, AccPedal_Sync_Return
	call	AccPedal_SendCtrl1
	call	AccPedal_SendCtrl2
	call	AccPedal_SendCtrl3
	call	AccPedal_SendCtrl4
AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	ld	a, (0x33e6:16)
	xor	a, 255
	and	a, (0x33e7:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendCtrl1_Return
	bit	3, (0xfd56:16)
	jr	z, AccPedal_SendCtrl1_CheckPort
	ld	b, 5:opc
	ld	d, a
	ld	e, (0x33e6:16)
	ld	xix, 14412
	ld	(xix+0:8), 72
	ld	(xix+1), b
	ld	(xix+2), e
	ld	(xix+3), d
	push	xix
	call	MidiPkt_DispatchViaTable_4DCE
	inc	4, xsp
AccPedal_SendCtrl1_CheckPort:
	bit	4, (0xfd50:16)
	jr	nz, AccPedal_SendCtrl1_Return
	ld	a, (0x9048:16)
	and	a, 143
	ld	(0x9049:16), a
	cp	(0x905c:16), 127
	jr	nz, AccPedal_SendCtrl1_UpdateMask
	and	(0x9049:16), 127
AccPedal_SendCtrl1_UpdateMask:
	ld	a, (13286:16)
	xor	a, 255
	and	a, (13287:16)
	ld	b, 5:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13286:16)
	call	MIDI_DispatchCC
AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	ld	a, (0x33ea:16)
	xor	a, 255
	and	a, (0x33eb:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendCtrl2_Return
	bit	3, (0xfd56:16)
	jr	z, AccPedal_SendCtrl2_CheckPort
	ld	b, 6:opc
	ld	d, a
	ld	e, (0x33ea:16)
	ld	xix, 14412
	ld	(xix+0:8), 72
	ld	(xix+1), b
	ld	(xix+2), e
	ld	(xix+3), d
	push	xix
	call	MidiPkt_DispatchViaTable_4DCE
	inc	4, xsp
AccPedal_SendCtrl2_CheckPort:
	bit	4, (0xfd50:16)
	jr	nz, AccPedal_SendCtrl2_Return
	ld	a, (0x9048:16)
	and	a, 143
	ld	(0x9049:16), a
	cp	(0x905c:16), 127
	jr	nz, AccPedal_SendCtrl2_UpdateMask
	and	(0x9049:16), 127
AccPedal_SendCtrl2_UpdateMask:
	ld	a, (13290:16)
	xor	a, 255
	and	a, (13291:16)
	ld	b, 6:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13290:16)
	call	MIDI_DispatchCC
AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	ld	a, (0x33e6:16)
	and	a, (0x33e7:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendCtrl3_Return
	bit	3, (0xfd56:16)
	jr	z, AccPedal_SendCtrl3_CheckPort
	ld	b, 5:opc
	ld	d, a
	ld	e, (0x33e6:16)
	ld	xix, 14412
	ld	(xix+0:8), 72
	ld	(xix+1), b
	ld	(xix+2), e
	ld	(xix+3), d
	push	xix
	call	MidiPkt_DispatchViaTable_4DCE
	inc	4, xsp
AccPedal_SendCtrl3_CheckPort:
	bit	4, (0xfd50:16)
	jr	nz, AccPedal_SendCtrl3_Return
	ld	a, (0x9048:16)
	and	a, 143
	ld	(0x9049:16), a
	cp	(0x905c:16), 127
	jr	nz, AccPedal_SendCtrl3_UpdateMask
	and	(0x9049:16), 127
AccPedal_SendCtrl3_UpdateMask:
	ld	a, (13286:16)
	and	a, (13287:16)
	ld	b, 5:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13286:16)
	call	MIDI_DispatchCC
AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	ld	a, (0x33ea:16)
	and	a, (0x33eb:16)
	cp	a, 0:i3
	jr	z, AccPedal_SendCtrl4_Return
	bit	3, (0xfd56:16)
	jr	z, AccPedal_SendCtrl4_CheckPort
	ld	b, 6:opc
	ld	d, a
	ld	e, (0x33ea:16)
	ld	xix, 14412
	ld	(xix+0:8), 72
	ld	(xix+1), b
	ld	(xix+2), e
	ld	(xix+3), d
	push	xix
	call	MidiPkt_DispatchViaTable_4DCE
	inc	4, xsp
AccPedal_SendCtrl4_CheckPort:
	bit	4, (0xfd50:16)
	jr	nz, AccPedal_SendCtrl4_Return
	ld	a, (0x9048:16)
	and	a, 143
	ld	(0x9049:16), a
	cp	(0x905c:16), 127
	jr	nz, AccPedal_SendCtrl4_UpdateMask
	and	(0x9049:16), 127
AccPedal_SendCtrl4_UpdateMask:
	ld	a, (13290:16)
	and	a, (13291:16)
	ld	b, 6:opc
	ld	c, 72:opc
	ld	d, a
	ld	e, (13290:16)
	call	MIDI_DispatchCC
AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	cp	(0x33ee:16), 5
	jr	nz, AccPedal_MapToAcc_Send
	ld	a, (0x33e2:16)
	and	a, (0x33e3:16)
	bit	6, a
	jr	z, AccPedal_MapToAcc_Send
	call	AccPedal_ScanVoiceSlots
	bit	1, (0xd53:16)
	jr	z, AccPedal_MapToAcc_Send
	or	(0x33e5:16), 64
	or	(0x33e4:16), 64
AccPedal_MapToAcc_Send:
	cp	(0x33ee:16), 5
	jr	nz, AccPedal_MapToAcc_UpdateMask
	ld	a, (0x33e2:16)
	and	a, (0x33e3:16)
	bit	7, a
	jr	z, AccPedal_MapToAcc_UpdateMask
	call	AccPedal_ScanVoiceSlots
	bit	1, (0xd53:16)
	jr	z, AccPedal_MapToAcc_CheckDir
	or	(0x33e5:16), 128
	or	(0x33e4:16), 128
	jr	AccPedal_MapToAcc_UpdateMask
AccPedal_MapToAcc_CheckDir:
	; ordi8 0x3481, 8 (v7 patched)
	or	(0x33e5:16), 8
	; ordi8 0x3480, 8 (v7 patched)
	or	(0x33e4:16), 8
AccPedal_MapToAcc_UpdateMask:
	cp	(0x33ee:16), 5
	jr	nz, AccPedal_MapToAcc_SetMask
	ld	a, (0x33e2:16)
	and	a, (0x33e3:16)
	bit	2, a
	jr	z, AccPedal_MapToAcc_SetMask
	call	AccPedal_ScanVoiceSlots
	bit	1, (0xd53:16)
	jr	z, AccPedal_MapToAcc_ClearMask
	or	(0x33e5:16), 16
	or	(0x33e4:16), 16
	jr	AccPedal_MapToAcc_SetMask
AccPedal_MapToAcc_ClearMask:
	; ordi8 0x3481, 4 (v7 patched)
	or	(0x33e5:16), 4
	; ordi8 0x3480, 4 (v7 patched)
	or	(0x33e4:16), 4
AccPedal_MapToAcc_SetMask:
	cp	(0x33ee:16), 6
	jr	nz, AccPedal_MapToAcc_Return
	ld	a, (0x33e2:16)
	and	a, (0x33e3:16)
	bit	2, a
	jr	z, AccPedal_MapToAcc_Return
	call	AccPedal_ScanVoiceSlots
	bit	1, (0xd53:16)
	jr	z, AccPedal_MapToAcc_Apply
	or	(0x33e5:16), 32
	or	(0x33e4:16), 32
	jr	AccPedal_MapToAcc_Return
AccPedal_MapToAcc_Apply:
	; ordi8 0x3485, 4 (v7 patched)
	or	(0x33e9:16), 4
	; ordi8 0x3484, 4 (v7 patched)
	or	(0x33e8:16), 4
AccPedal_MapToAcc_Return:
	cp	(0x33ee:16), 5
	jr	nz, AccPedal_MapPadding
	ld	a, (0x33e2:16)
	and	a, (0x33e3:16)
	bit	5, a
	jr	z, AccPedal_MapPadding
	call	15701500
	bit	1, (0xd53:16)
	jr	z, AccPedal_MapPadding
	or	(0x33e5:16), 32
	or	(0x33e4:16), 32
	jr	AccPedal_MapPadding
AccPedal_MapPadding:
	ret

AccPedal_MapPadding2:
	nop
	nop

AccPedal_SustainOn:
	bit 2, (0x33d4:16)
	jrl nz, AccPedal_SustainOn_AltRoute
	or (0x33d4:16), 0x04
	bit 2, (0xfc5f:16)
	jr nz, .Lc_f59ed3
	or (0xfc5f:16), 0x04
	or (0x33e6:16), 0x04
	or (0x33e4:16), 0x04
	jr t, .Lc_f59ee9
AccPedal_SustainOn_SetMask:
.Lc_f59ed3:
	cp (0x905c:16), 0x7f
	jr nz, .Lc_f59ee9
	and (0xfc5f:16), 0xfb
	and (0x33e6:16), 0xfb
	and (0x33e4:16), 0xfb
AccPedal_SustainOn_Update64607:
.Lc_f59ee9:
	or (0x33e5:16), 0x04
	or (0x33e7:16), 0x04
	bit 3, (0xfc5f:16)
	jr z, .Lc_f59f12
	and (0xfc5f:16), 0xf7
	and (0x33e4:16), 0xf7
	or (0x33e5:16), 0x08
	and (0x33e6:16), 0xf7
	or (0x33e7:16), 0x08
AccPedal_SustainOn_Post:
.Lc_f59f12:
	bit 2, (0xfc60:16)
	jr z, AccPedal_SustainOn_Finalize
	and (0xfc60:16), 0xfb
	and (0x33e8:16), 0xfb
	or (0x33e9:16), 0x04
	and (0x33ea:16), 0xfb
	or (0x33eb:16), 0x04
AccPedal_SustainOn_Finalize:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SustainOn_CheckAlt
	and (0xfc5f:16), 191

AccPedal_SustainOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SustainOn_AltRoute
	and (0xfc5f:16), 127

AccPedal_SustainOn_AltRoute:
	cp (0x905c:16), 0x7f
	jr z, AccPedal_SustainOn_Return
	and (0x33d4:16), 0xfb
AccPedal_SustainOn_Return:
	ret

AccPedal_SustainOff_Padding:
	nop
	nop

AccPedal_SustainOff:
	bit 2, (0x33d4:16)
	jr z, .Lc_f59f61
	and (0x33d4:16), 0xfb
AccPedal_SustainOff_Clear:
.Lc_f59f61:
	cp (0x905c:16), 0x7f
	jr z, AccPedal_SustainOff_Return
	and (0xfc5f:16), 0xfb
AccPedal_SustainOff_Return:
	ret

AccPedal_ExprOn_Padding:
	nop
	nop

AccPedal_ExprOn:
	bit 0, (0x33d4:16)
	jrl nz, AccPedal_ExprOn_AltRoute
	or (0x33d4:16), 0x01
	bit 2, (0xfc60:16)
	jr nz, .Lc_f59f93
	or (0xfc60:16), 0x04
	or (0x33ea:16), 0x04
	or (0x33e8:16), 0x04
	jr t, .Lc_f59fa9
AccPedal_ExprOn_SetMask:
.Lc_f59f93:
	cp (0x905c:16), 0x7f
	jr nz, .Lc_f59fa9
	and (0xfc60:16), 0xfb
	and (0x33ea:16), 0xfb
	and (0x33e8:16), 0xfb
AccPedal_ExprOn_Update64607:
.Lc_f59fa9:
	or (0x33e9:16), 0x04
	or (0x33eb:16), 0x04
	bit 3, (0xfc5f:16)
	jr z, .Lc_f59fd2
	and (0xfc5f:16), 0xf7
	and (0x33e4:16), 0xf7
	or (0x33e5:16), 0x08
	and (0x33e6:16), 0xf7
	or (0x33e7:16), 0x08
AccPedal_ExprOn_Post:
.Lc_f59fd2:
	bit 2, (0xfc5f:16)
	jr z, AccPedal_ExprOn_Finalize
	and (0xfc5f:16), 0xfb
	and (0x33e4:16), 0xfb
	or (0x33e5:16), 0x04
	and (0x33e6:16), 0xfb
	or (0x33e7:16), 0x04
AccPedal_ExprOn_Finalize:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_ExprOn_CheckAlt
	and (0xfc5f:16), 191

AccPedal_ExprOn_CheckAlt:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_ExprOn_AltRoute
	and (0xfc5f:16), 127

AccPedal_ExprOn_AltRoute:
	cp (0x905c:16), 0x7f
	jr z, AccPedal_ExprOn_Return
	and (0x33d4:16), 0xfe
AccPedal_ExprOn_Return:
	ret

AccPedal_ExprOff_Padding:
	nop
	nop

AccPedal_ExprOff:
	bit 0, (0x33d4:16)
	jr z, .Lc_f5a021
	and (0x33d4:16), 0xfe
AccPedal_ExprOff_Clear:
.Lc_f5a021:
	cp (0x905c:16), 0x7f
	jr z, AccPedal_ExprOff_Return
	and (0xfc60:16), 0xfb
AccPedal_ExprOff_Return:
	ret

AccPedal_SostenutoOn_Padding:
	nop
	nop

AccPedal_SostenutoOn:
	bit 4, (0x33d4:16)
	jrl nz, AccPedal_SostenutoOn_Return
	or (0x33d4:16), 0x10
	or (0xfc5f:16), 0x10
	or (0x33e5:16), 0x10
	or (0x33e4:16), 0x10
	or (0x33e7:16), 0x10
	or (0x33e6:16), 0x10
	bit 5, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_SetMask
	and (0xfc5f:16), 0xdf
AccPedal_SostenutoOn_SetMask:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_Update
	and (0xfc5f:16), 191

AccPedal_SostenutoOn_Update:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SostenutoOn_Post
	and (0xfc5f:16), 127

AccPedal_SostenutoOn_Post:
	bit	2, (0xfc5f:16)
	jr	z, AccPedal_SostenutoOn_Finalize
	and	(0xfc5f:16), 251
	or	(0x33e7:16), 4
	and	(0x33e6:16), 251
	or	(0x33e5:16), 4
	and	(0x33e4:16), 251
AccPedal_SostenutoOn_Finalize:
	bit	3, (0xfc5f:16)
	jr	z, AccPedal_SostenutoOn_CheckAlt
	and	(0xfc5f:16), 247
	or	(0x33e7:16), 8
	and	(0x33e6:16), 247
	or	(0x33e5:16), 8
	and	(0x33e4:16), 247
AccPedal_SostenutoOn_CheckAlt:
	bit	2, (0xfc60:16)
	jr	z, AccPedal_SostenutoOn_Return
	and	(0xfc60:16), 251
	or	(0x33eb:16), 4
	and	(0x33ea:16), 251
	or	(0x33e9:16), 4
	and	(0x33e8:16), 251
AccPedal_SostenutoOn_Return:
	ret

AccPedal_SostenutoOff_Padding:
	nop
	nop

AccPedal_SostenutoOff:
	bit 4, (0x33d4:16)
	jr z, AccPedal_SostenutoOff_Return
	and (0x33d4:16), 0xef
	or (0x33e5:16), 0x10
	and (0x33e4:16), 0xef
	or (0x33e7:16), 0x10
	and (0x33e6:16), 0xef
AccPedal_SostenutoOff_Return:
	ret

AccPedal_SostenutoOff_Padding2:
	nop
	nop

AccPedal_SoftOn:
	bit 5, (0x33d4:16)
	jrl nz, AccPedal_SoftOn_Return
	or (0x33d4:16), 0x20
	or (0xfc5f:16), 0x20
	or (0x33e5:16), 0x20
	or (0x33e4:16), 0x20
	or (0x33e7:16), 0x20
	or (0x33e6:16), 0x20
	bit 4, (0xfc5f:16)
	jr z, AccPedal_SoftOn_SetMask
	and (0xfc5f:16), 0xef
AccPedal_SoftOn_SetMask:
	bit 6, (0xfc5f:16)
	jr z, AccPedal_SoftOn_Update
	and (0xfc5f:16), 191

AccPedal_SoftOn_Update:
	bit 7, (0xfc5f:16)
	jr z, AccPedal_SoftOn_Post
	and (0xfc5f:16), 127

AccPedal_SoftOn_Post:
	bit	2, (0xfc5f:16)
	jr	z, AccPedal_SoftOn_Finalize
	and	(0xfc5f:16), 251
	or	(0x33e7:16), 4
	and	(0x33e6:16), 251
	or	(0x33e5:16), 4
	and	(0x33e4:16), 251
AccPedal_SoftOn_Finalize:
	bit	3, (0xfc5f:16)
	jr	z, AccPedal_SoftOn_CheckAlt
	and	(0xfc5f:16), 247
	or	(0x33e7:16), 8
	and	(0x33e6:16), 247
	or	(0x33e5:16), 8
	and	(0x33e4:16), 247
AccPedal_SoftOn_CheckAlt:
	bit	2, (0xfc60:16)
	jr	z, AccPedal_SoftOn_Return
	and	(0xfc60:16), 251
	or	(0x33eb:16), 4
	and	(0x33ea:16), 251
	or	(0x33e9:16), 4
	and	(0x33e8:16), 251
AccPedal_SoftOn_Return:
	ret

AccPedal_SoftOff_Padding:
	nop
	nop

AccPedal_SoftOff:
	bit 5, (0x33d4:16)
	jr z, AccPedal_SoftOff_Return
	and (0x33d4:16), 0xdf
	or (0x33e5:16), 0x20
	and (0x33e4:16), 0xdf
	or (0x33e7:16), 0x20
	and (0x33e6:16), 0xdf
AccPedal_SoftOff_Return:
	ret

AccPedal_HoldOn_Padding:
	nop
	nop

AccPedal_HoldOn:
	bit 6, (0x33d4:16)
	jrl nz, AccPedal_HoldOn_Return
	or (0x33d4:16), 0x40
	or (0xfc5f:16), 0x40
	or (0x33e5:16), 0x40
	or (0x33e4:16), 0x40
	or (0x33e7:16), 0x40
	or (0x33e6:16), 0x40
	bit 4, (0xfc5f:16)
	jr z, AccPedal_HoldOn_SetMask
	and (0xfc5f:16), 0xef
AccPedal_HoldOn_SetMask:
	bit 5, (0xfc5f:16)
	jr z, AccPedal_HoldOn_Update
	and (0xfc5f:16), 223

AccPedal_HoldOn_Update:
	bit	2, (0xfc5f:16)
	jr	z, AccPedal_HoldOn_Post
	and	(0xfc5f:16), 251
	or	(0x33e7:16), 4
	and	(0x33e6:16), 251
	or	(0x33e5:16), 4
	and	(0x33e4:16), 251
AccPedal_HoldOn_Post:
	bit	3, (0xfc5f:16)
	jr	z, AccPedal_HoldOn_Finalize
	and	(0xfc5f:16), 247
	or	(0x33e7:16), 8
	and	(0x33e6:16), 247
	or	(0x33e5:16), 8
	and	(0x33e4:16), 247
AccPedal_HoldOn_Finalize:
	bit	2, (0xfc60:16)
	jr	z, AccPedal_HoldOn_CheckAlt
	and	(0xfc60:16), 251
	or	(0x33eb:16), 4
	and	(0x33ea:16), 251
	or	(0x33e9:16), 4
	and	(0x33e8:16), 251
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
	bit 6, (0x33d4:16)
	jr z, AccPedal_HoldOff_Return
	and (0x33d4:16), 0xbf
	or (0x33e5:16), 0x40
	and (0x33e4:16), 0xbf
	or (0x33e7:16), 0x40
	and (0x33e6:16), 0xbf
AccPedal_HoldOff_Return:
	ret

AccPedal_HoldOff_Padding2:
	nop
	nop

AccPedal_DamperOn:
	bit 3, (0x33d4:16)
	jrl nz, AccPedal_DamperOn_FinalCheck
	or (0x33d4:16), 0x08
	bit 3, (0xfc5f:16)
	jr nz, .Lc_f5a2ab
	or (0xfc5f:16), 0x08
	or (0x33e6:16), 0x08
	or (0x33e4:16), 0x08
	jr t, .Lc_f5a2c1
AccPedal_DamperOn_SetMask:
.Lc_f5a2ab:
	cp (0x905c:16), 0x7f
	jr nz, .Lc_f5a2c1
	and (0xfc5f:16), 0xf7
	and (0x33e6:16), 0xf7
	and (0x33e4:16), 0xf7
AccPedal_DamperOn_Update:
.Lc_f5a2c1:
	or (0x33e5:16), 0x08
	or (0x33e7:16), 0x08
	bit 2, (0xfc5f:16)
	jr z, .Lc_f5a2ea
	and (0xfc5f:16), 0xfb
	and (0x33e4:16), 0xfb
	or (0x33e5:16), 0x04
	and (0x33e6:16), 0xfb
	or (0x33e7:16), 0x04
AccPedal_DamperOn_Post:
.Lc_f5a2ea:
	bit 2, (0xfc60:16)
	jr z, AccPedal_DamperOn_Finalize
	and (0xfc60:16), 0xfb
	and (0x33e8:16), 0xfb
	or (0x33e9:16), 0x04
	and (0x33ea:16), 0xfb
	or (0x33eb:16), 0x04
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
	cp (0x905c:16), 0x7f
	jr z, AccPedal_DamperOn_Return
	and (0x33d4:16), 0xf7
AccPedal_DamperOn_Return:
	ret

AccPedal_DamperOff_Padding:
	nop
	nop

AccPedal_DamperOff:
	bit 3, (0x33d4:16)
	jr z, .Lc_f5a34f
	and (0x33d4:16), 0xf7
AccPedal_DamperOff_Clear:
.Lc_f5a34f:
	cp (0x905c:16), 0x7f
	jr z, AccPedal_DamperOff_Return
	and (0xfc5f:16), 0xf7
AccPedal_DamperOff_Return:
	ret

AccPedal_DamperOff_Padding2:
	nop
	nop

AccPedal_PortamentoOn:
	bit 7, (0x33d4:16)
	jrl nz, AccPedal_PortamentoOn_Return
	or (0x33d4:16), 0x80
	or (0xfc5f:16), 0x80
	or (0x33e5:16), 0x80
	or (0x33e4:16), 0x80
	or (0x33e7:16), 0x80
	or (0x33e6:16), 0x80
	bit 4, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_SetMask
	and (0xfc5f:16), 0xef
AccPedal_PortamentoOn_SetMask:
	bit 5, (0xfc5f:16)
	jr z, AccPedal_PortamentoOn_Update
	and (0xfc5f:16), 223

AccPedal_PortamentoOn_Update:
	bit	2, (0xfc5f:16)
	jr	z, AccPedal_PortamentoOn_Post
	and	(0xfc5f:16), 251
	or	(0x33e7:16), 4
	and	(0x33e6:16), 251
	or	(0x33e5:16), 4
	and	(0x33e4:16), 251
AccPedal_PortamentoOn_Post:
	bit	3, (0xfc5f:16)
	jr	z, AccPedal_PortamentoOn_Finalize
	and	(0xfc5f:16), 247
	or	(0x33e7:16), 8
	and	(0x33e6:16), 247
	or	(0x33e5:16), 8
	and	(0x33e4:16), 247
AccPedal_PortamentoOn_Finalize:
	bit	2, (0xfc60:16)
	jr	z, AccPedal_PortamentoOn_CheckAlt
	and	(0xfc60:16), 251
	or	(0x33eb:16), 4
	and	(0x33ea:16), 251
	or	(0x33e9:16), 4
	and	(0x33e8:16), 251
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
	bit	7, (0x33d4:16)
	jr	z, AccPedal_PortamentoOff_Return
	and	(0x33d4:16), 127
	or	(0x33e5:16), 128
	and	(0x33e4:16), 127
	or	(0x33e7:16), 128
	and	(0x33e6:16), 127
AccPedal_PortamentoOff_Return:
	ret

AccPedal_PortamentoOff_Padding2:
	nop
	nop

AccAutoPlay_NoteDispatch:
	ld W,A
	ld A,C
	cp (0x7e6f:16), 0x00
	jr nz, .Lc_f5a463
	pushw wa
	calr AccPedal_StyleCheck
	cp a, 1:i3
	popw wa
	jr z, .Lc_f5a463
	bit 2, (0x28a7:16)
	jr nz, .Lc_f5a463
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call CompIface_ResetPedal
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	calr AccAutoPlay_SplitDetect
	cp c, 0:i3
	jr z, .Lc_f5a45e
	or (0x33fc:16), 0x01
AccAutoPlay_NoteDispatch_Check:
.Lc_f5a45e:
	or (0x33fc:16), 0x80
AccAutoPlay_NoteDispatch_Process:
.Lc_f5a463:
	cpw (0x28a8:16), 0x0000
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 2, (0x041e:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 3, (0x28b3:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	bit 0, (0x28b2:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 2, (0x28b1:16)
	jr nz, AccAutoPlay_NoteDispatch_Return
	bit 0, (0x33fc:16)
	jr z, AccAutoPlay_NoteDispatch_Return
	and (0x28b3:16), 0xf7
	call PerfMode_Handler_EvtB_Helper2_Helper11
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
	cp (0x7e6f:16), 0x00
	jr nz, AccAutoPlay_ZoneTrack_Update
	pushw wa
	calr AccPedal_StyleCheck
	cp a, 1:i3
	popw wa
	jr z, AccAutoPlay_ZoneTrack_Update
	bit 2, (0x28a7:16)
	jr nz, AccAutoPlay_ZoneTrack_Update
	calr AccAutoPlay_ZoneTrack_Apply
	ld hl, (0x3400:16)
	ld (0x33fe:16), hl
	ld (0x3400:16), wa
AccAutoPlay_ZoneTrack_Update:
	ret

AccAutoPlay_ZoneTrack_Apply:
	ld	xix, 52835
	ld	wa, (xix+2)
	cp	wa, 0:i3
	jr	nz, AccAutoPlay_ZoneTrack_Check
	ld	l, 128:opc
	jr	AccAutoPlay_ZoneTrack_Store
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

	ldw (14412:16), 0

	ld bc, (xix + 0:8)

	ld e, 0x5:opc



AccAutoPlay_ZoneTrack_Clear:
	cp	bc, 0:i3
	jr	z, AccAutoPlay_ZoneTrack_Default
	ld	a, (xix+e)
	cp	l, a
	jr	c, AccAutoPlay_ZoneTrack_Finalize
	incw	1, (14412:16)
AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	ld	wa, (14412:16)
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
	bit 6, (0x33d2:16)
	jr z, .Lc_f5a5da
	cpw (0xf19e:16), 0x0000
	jr z, .Lc_f5a5da
	cpw (0x28a8:16), 0x0000
	jr nz, .Lc_f5a5da
	calr AccAutoPlay_SetConfig
	bit 7, (0x33d1:16)
	jr nz, .Lc_f5a5da
	calr AccAutoPlay_Disable
AccAutoPlay_SM_CheckEligible:
.Lc_f5a5da:
	ld (0x33d8:16), 0x00
	calr AccAutoPlay_ActionDispatch
	bit 0, (0x33d8:16)
	jr z, AccAutoPlay_SM_Return
	ld (0x33d8:16), 0x00
	or (0x33d2:16), 0x04
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
	bit 0, (0x33fc:16)
	jrl z, AccAutoPlay_ModeAvail_Padding2
	bit 0, (0x33fd:16)
	jrl nz, AccAutoPlay_Trigger_Activate
	bit 7, (0x33d1:16)
	jr nz, AccAutoPlay_Trigger_Evaluate
	bit 2, (0x041e:16)
	jr nz, AccAutoPlay_Trigger_Process
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_Trigger_Process
AccAutoPlay_Trigger_Evaluate:
	calr AccAutoPlay_Configure

AccAutoPlay_Trigger_Process:
	or	(0x33fc:16), 1
	or	(0x33fd:16), 1
	jr	AccAutoPlay_ModeAvail_Padding
AccAutoPlay_Trigger_Activate:
	bit 7, (0x33fc:16)
	jr nz, AccAutoPlay_ModeAvail_Padding
	bit 7, (0x33d1:16)
	jr z, AccAutoPlay_Trigger_Return
	cpw (0x3400:16), 0x0000
	jr nz, .Lc_f5a662
	cpw (0x33fe:16), 0x0000
	jr z, .Lc_f5a662
	calr AccAutoPlay_SeqHandoff
	and (0x33fc:16), 0xfe
	and (0x33fd:16), 0xfe
	ldw (0x33fe:16), 0x0000
	jr t, AccAutoPlay_ModeAvail_Padding
AccAutoPlay_Trigger_Configure:
.Lc_f5a662:
	cpw (0x3400:16), 0x0000
	jr nz, AccAutoPlay_Trigger_Finalize
	cpw (0x33fe:16), 0x0000
	jr nz, AccAutoPlay_Trigger_Finalize
	ld (0x33fc:16), 0x00
	ld (0x33fd:16), 0x00
AccAutoPlay_Trigger_Finalize:
	jr AccAutoPlay_ModeAvail_Padding

AccAutoPlay_Trigger_Return:
	and	(0x33fc:16), 254
	and	(0x33fd:16), 254
	jr	AccAutoPlay_ModeAvail_Padding
AccAutoPlay_ModeAvail_Padding:
	; anddi8 (0x3498), 127 (v7 patched)
	and	(0x33fc:16), 127
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
	cp	(0x8c98:16), 14
	jr	nz, AccAutoPlay_ModeAvail_Return
	ld	l, 127:opc
AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	.byte	0x00, 0x00
AccAutoPlay_ModeAvail_Extended_Code:	.byte	0x3b, 0x36, 0x3b, 0x42, 0x47, 0xf1
	.byte 0x1e, 0x04, 0xca, 0x6e, 0x22, 0xf1, 0xd2, 0x33
	.byte 0xc9, 0x66, 0x1c, 0xf1, 0xfc, 0x33, 0xc8, 0x66
	.byte 0x16, 0xf1, 0xfd, 0x33, 0xc8, 0x6e, 0x10, 0x1e
	.byte 0x48, 0x00, 0xc1, 0xfc, 0x33, 0x21, 0xf1, 0xfd
	.byte 0x33, 0x41, 0xc1, 0xfc, 0x33, 0x3e, 0x01, 0x0e
AccAutoPlay_SetConfig:
	cpw (0x28a8:16), 0x0000
	jr nz, AccAutoPlay_SetConfig_Apply
	cpw (0xf19e:16), 0x0000
	jr nz, AccAutoPlay_SetConfig_Apply
	cp (0x36ff:16), 0x00
	jr nz, AccAutoPlay_SetConfig_Apply
	ld a, (0xfc5d:16)
	bit 0x03,A
	jr nz, AccAutoPlay_SetConfig_Apply
	and A,0x07
	cp a, 0:i3
	jr z, AccAutoPlay_SetConfig_Apply
	bit 1, (0xfc5f:16)
	jr z, AccAutoPlay_SetConfig_Apply
	or (0x33d1:16), 0x80
	jr t, AccAutoPlay_SetConfig_Return
AccAutoPlay_SetConfig_Apply:
	ld	(13265:16), 0
AccAutoPlay_SetConfig_Return:
	ret

AccAutoPlay_Configure:
	and (0x33d2:16), 0x1f
	cp (0x36ff:16), 0x00
	jr nz, .Lc_f5a74f
	cpw (0x28a8:16), 0x0000
	jr nz, .Lc_f5a759
	cpw (0xf19e:16), 0x0000
	jr z, .Lc_f5a74f
	jr t, AccAutoPlay_Configure_Store
AccAutoPlay_Configure_Mode1:
.Lc_f5a74f:
	or (0x33d2:16), 0xa0
	calr AccAutoPlay_SubModeA
	jr t, AccAutoPlay_Configure_Return
AccAutoPlay_Configure_Mode2:
.Lc_f5a759:
	cpw (0xf19e:16), 0x0000
	jr nz, AccAutoPlay_Configure_Store
	bit 2, (0x0420:16)
	jr z, .Lc_f5a76e
	or (0x33d2:16), 0x80
	jr t, AccAutoPlay_Configure_Check
AccAutoPlay_Configure_Apply:
.Lc_f5a76e:
	or (0x33d2:16), 0xe0



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
	.byte 0x00, 0x00, 0xf1, 0xd2, 0x33, 0xc9, 0x6e, 0x0c
	.byte 0xc1, 0xfd, 0x33, 0x3c, 0xfe, 0xc1, 0xfc, 0x33
	.byte 0x3c, 0xfe, 0x68, 0x1f
AccAutoPlay_Configure_Final:
	.byte 0xf1, 0xfc, 0x33, 0xc8, 0x6e, 0x19, 0xf1, 0xfd
	.byte 0x33, 0xc8, 0x66, 0x13, 0xf1, 0xd1, 0x33, 0xcf
	.byte 0x66, 0x03, 0x1e, 0x07, 0x01
AccAutoPlay_Configure_Done:
	.incbin "includes/romslices/v7_transplant_AccAutoPlay_Configure_Done.bin"
AccAutoPlay_Configure_Return2:
	ret
	nop
	nop


AccAutoPlay_PeriodicCheck:
	bit 1, (0xfc5f:16)
	jr nz, AccAutoPlay_Periodic_Evaluate
	jr AccAutoPlay_Periodic_Return

AccAutoPlay_Periodic_Evaluate:
	bit	2, (0x33d2:16)
	jr	z, AccAutoPlay_Periodic_Process
	calr	AccAutoPlay_SetConfig
	bit	7, (0x33d1:16)
	jr	nz, AccAutoPlay_Periodic_Padding
	calr	AccAutoPlay_Disable
	jr	AccAutoPlay_Periodic_Padding
AccAutoPlay_Periodic_Padding:
	and	(0x33d2:16), 251
	jr	AccAutoPlay_Periodic_Return
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

	call	16624672

	ret



AccAutoPlay_Disable_Return:
	nop
	nop

AccAutoPlay_SubModeA:
	bit 7, (0x33d1:16)
	jr z, AccAutoPlay_SubModeA_Return
	bit 2, (0x041e:16)
	jr nz, .Lc_f5a833
	bit 0, (0x31e7:16)
	jr z, .Lc_f5a827
	bit 1, (0x31e7:16)
	jr z, .Lc_f5a827
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x01
	jr t, AccAutoPlay_SubModeA_Return
AccAutoPlay_SubModeA_Check:
.Lc_f5a827:
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x04
	jr t, AccAutoPlay_SubModeA_Return
AccAutoPlay_SubModeA_Apply:
.Lc_f5a833:
	ld a, (0x0420:16)
	bit 0x02,A
	jr z, AccAutoPlay_SubModeA_Return
	bit 0x03,A
	jr z, AccAutoPlay_SubModeA_Return
	and (0x0420:16), 0xf7
	and (0x041e:16), 0xf7
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x08
AccAutoPlay_SubModeA_Return:
	ret

AccAutoPlay_SubModeA_Padding:
	nop
	nop

AccAutoPlay_SubModeB:
	bit 7, (0x33d1:16)
	jr z, AccAutoPlay_SubModeB_Return
	bit 2, (0x041e:16)
	jr nz, .Lc_f5a888
	bit 0, (0x31e7:16)
	jr z, .Lc_f5a87c
	bit 1, (0x31e7:16)
	jr z, .Lc_f5a87c
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x02
	jr t, AccAutoPlay_SubModeB_Return
AccAutoPlay_SubModeB_Check:
.Lc_f5a87c:
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x04
	jr t, AccAutoPlay_SubModeB_Return
AccAutoPlay_SubModeB_Apply:
.Lc_f5a888:
	ld a, (0x0420:16)
	bit 0x02,A
	jr z, AccAutoPlay_SubModeB_Return
	bit 0x03,A
	jr z, AccAutoPlay_SubModeB_Return
	and (0x0420:16), 0xf7
	and (0x041e:16), 0xf7
	and (0x0421:16), 0xf7
	and (0x33d1:16), 0xef
	or (0x33d1:16), 0x08
AccAutoPlay_SubModeB_Return:
	ret

AccAutoPlay_SubModeB_Padding:
	nop
	nop

AccAutoPlay_SeqHandoff:
	cp (0x36ff:16), 0x00
	jr nz, AccAutoPlay_SeqHandoff_Return
	cpw (0x28aa:16), 0x0000
	jr nz, AccAutoPlay_SeqHandoff_Return
	bit 2, (0x041e:16)
	jr z, AccAutoPlay_SeqHandoff_Return
	and (0x33d1:16), 0xf7
	or (0x33d1:16), 0x10
	cpw (0xf19e:16), 0x0000
	jr nz, AccAutoPlay_SeqHandoff_Process
	bit 2, (0x0420:16)
	jr z, AccAutoPlay_SeqHandoff_Return
	ei 0x06
	calr AccPlayMode_StopToSync2
	ei 0x00
	jr t, AccAutoPlay_SeqHandoff_Return
AccAutoPlay_SeqHandoff_Process:
	bit 2, (1057:16)
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
	and A,0x03
	cp a, 2:i3
	jr nz, .Lc_f5a919
	or (0x33d2:16), 0xa0
	jr t, AccAutoPlay_ModeDecode_Return
AccAutoPlay_ModeDecode_Process:
.Lc_f5a919:
	cp a, 1:i3
	jr nz, .Lc_f5a924
	or (0x33d2:16), 0x60
	jr t, AccAutoPlay_ModeDecode_Return
AccAutoPlay_ModeDecode_Apply:
.Lc_f5a924:
	cp a, 3:i3
	jr nz, AccAutoPlay_ModeDecode_Return
	or (0x33d2:16), 0xe0
AccAutoPlay_ModeDecode_Return:
	ret

AccAutoPlay_ModeDecode_Padding:
	nop
	nop

AccAutoPlay_ActionDispatch:
	ld a, (0x33d1:16)
	bit 0x07,A
	jr z, AccAutoPlay_Action_Check
	bit 2, (0x33d1:16)
	jr z, AccAutoPlay_Action_Finalize
	and A,0xfb
	or A,0x08
	ld (0x33d1:16), a
AccAutoPlay_Action_Check:
	ld	a, (13266:16)
	ld	b, a
	and	a, 224
	cp	a, 0:i3
	ld	a, b
	jr	z, AccAutoPlay_Action_Return
	bit	7, a
	jr	z, AccAutoPlay_Action_Activate
	bit	5, a
	jr	nz, AccAutoPlay_Action_Process
	calr	AccPlayMode_StartAccPlay
	jr	AccAutoPlay_Action_Apply
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
	.byte 0xf1, 0xd1, 0x33, 0xcb, 0x6e, 0x00
AccAutoPlay_Action_Finalize:
	.byte 0xc1, 0xd2, 0x33, 0x3c, 0x1f	; anddi8 (0x346e), 31 (v7 patched)



AccAutoPlay_Action_Return:
	ret

AccAutoPlay_Action_Padding:
	nop
	nop

AccAutoPlay_DeferredAction:
	bit 7, (0x33d1:16)
	jr z, AccAutoPlay_Deferred_Return
	bit 0, (0x33d1:16)
	jr z, .Lc_f5a9a9
	and (0x33d1:16), 0xee
	or (0x33d1:16), 0x08
	ei 0x06
	calr AccPlayMode_StartAccPlayFull
	ei 0x00
	calr AccReplay_FullRestart
	jr t, AccAutoPlay_Deferred_Return
AccAutoPlay_Deferred_Process:
.Lc_f5a9a9:
	bit 1, (0x33d1:16)
	jr z, AccAutoPlay_Deferred_Return
	and (0x33d1:16), 0xed
	or (0x33d1:16), 0x08
	ei 0x06
	calr AccPlayMode_StartPlay
	ei 0x00
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
	bit 2, (1057:16)
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
AccPlayMode_Dispatch_Execute_Data:	.byte	0x15, 0xaa, 0xf5, 0x00, 0x49, 0xab
	.byte 0xf5, 0x00, 0xcc, 0xab, 0xf5, 0x00, 0x00, 0xac
	.byte 0xf5, 0x00, 0xb3, 0xab, 0xf5, 0x00, 0x38, 0xab
	.byte 0xf5, 0x00, 0xae, 0xab, 0xf5, 0x00, 0x99, 0xab
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
	ld (1057:16), 1
	calr AccTempo_ClearSubPos

AccPlayMode_StartAccPlay:
	ld (1054:16), 1

	; ordi8 0x3474, 1 (v7 patched)
	or	(0x33d8:16), 1
	; calr AccTempo_ClearPositions (v7 displacement)
	calr	AccTempo_ClearPositions
	ld a, 0x85:opc

	; calr AccTempo_WriteStartMarker (v7 displacement)
	calr	AccTempo_WriteStartMarker
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
	ld	(1054:16), 12
	ld	(13268:16), 0
	ld	a, 134:opc
	calr	AccTempo_WriteStartMarker
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
	ld (1057:16), 1
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
	ld (0x041e:16), 0x0c
	bit 0, (0x28b2:16)
	jr nz, AccPlayMode_StopExprFull_Process
	or (0x33de:16), 0x04
AccPlayMode_StopExprFull_Process:
	ld a, 0x86:opc
	calr AccTempo_WriteStartMarker

AccPlayMode_StopExprC:
	ld (1057:16), 12
	bit 3, (1056:16)
	jr nz, AccPlayMode_StopExprC_Process
	bit 2, (1056:16)
	jr z, AccPlayMode_StopExprC_Process
	ld (1056:16), 12

AccPlayMode_StopExprC_Process:
	ld	(13268:16), 0
	ret
AccPlayMode_StopExprC_Return:
	nop
	nop

AccPlayMode_StopExprD:
	ld (1057:16), 12
	ret

AccPlayMode_StopExprD_Return:
	nop
	nop

AccPlayMode_StartAccPlayFull:
	ld (0x041e:16), 0x01
	or (0x33d8:16), 0x01
	calr AccTempo_ClearPositions
	ld A, 0x85:opc
	calr AccTempo_WriteStartMarker
	bit 0, (0x0420:16)
	jr nz, AccPlayMode_StartAccPlayFull_Return
	bit 2, (0x0420:16)
	jr nz, AccPlayMode_StartAccPlayFull_Return
	ld (0x0420:16), 0x01
	calr AccTempo_ClearCounters
	calr AccSync_MidiClock
AccPlayMode_StartAccPlayFull_Return:
	ret

AccPlayMode_StartAccPlayFull_Padding:
	.byte 0x00, 0x00, 0xf1, 0x21, 0x04, 0x00, 0x0c, 0xf1
	.byte 0x1e, 0x04, 0x00, 0x0c, 0xc1, 0xd4, 0x33, 0x3c
	.byte 0x0f, 0x21, 0x86, 0x1e, 0x6c, 0x00, 0x0e, 0x00
	.byte 0x00
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
	ld (1052:16), wa
	ld (1051:16), a

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
	call	16576929
	ei	0
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
	ld a, (1051:16)
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
	ld (0x33d8:16), 0x00
	or (0x33f5:16), 0x01
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
	; anddi8 (0x3491), 254 (v7 patched)
	and	(0x33f5:16), 254
	ret



AccReplay_Restart_Return:
	nop
	nop

AccTiming_AlignTo8Tick:
	pushw hl
	ldw bc, 0x8
	ld wa, (1033:16)
	add wa, bc

AccTiming_Align_Compute:
	ld hl, wa
	sub hl, (1033:16)
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
	cp (0x045b:16), 0x01
	jr nz, AccTempo_CheckSource_Process
	cp (0xce43:16), 0x00
	jr z, AccTempo_CheckSource_Process
	ld (0x045b:16), 0x00
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
	ld	a, (49121:16)
	pushw	wa
	ld	w, (49122:16)
	ld	a, (49123:16)
	pushw	wa
	ld	a, (13292:16)
	ld	(49121:16), a
	ld	a, (13273:16)
	ld	(49122:16), a
	ld	a, (13274:16)
	ld	(49123:16), a
	ld	a, (36956:16)
	pushw	wa
	ld	(36956:16), 0
	calr	AccPedal_EventDispatch
	popw	wa
	ld	(36956:16), a
	popw	wa
	ld	(49122:16), w
	ld	(49123:16), a
	popw	wa
	ld	(49121:16), a
	xor	a, a
	ld	(13273:16), a
	ld	(13274:16), a
	ld	(13292:16), a
	ld	wa, 0:i3
	ld	d, 5:opc
	ld	e, 72:opc
	call	16624672
	ld	wa, 0:i3
	ld	d, 6:opc
	ld	e, 72:opc
	call	16624672
	call	16635840
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
	ld	hl, wa
	ld	a, (49121:16)
	pushw	wa
	ld	w, (49122:16)
	ld	a, (49123:16)
	pushw	wa
	cp	l, 0:i3
	jr	nz, AccReplay_SendPedal_Process
	ld	(49121:16), 5
	ld	(49122:16), 4
	ld	(49123:16), 4
	jr	AccReplay_SendPedal_Dispatch
AccReplay_SendPedal_Process:
	ld	(49121:16), 6
	ld	(49122:16), 4
	ld	(49123:16), 4
AccReplay_SendPedal_Dispatch:
	ld	a, (36956:16)
	pushw	wa
	ld	(36956:16), 0
	calr	AccPedal_EventDispatch
	popw	wa
	ld	(36956:16), a
	popw	wa
	ld	(49122:16), w
	ld	(49123:16), a
	popw	wa
	ld	(49121:16), a
	ld	wa, 0:i3
	ld	d, 5:opc
	ld	e, 72:opc
	call	16624672
	ld	wa, 0:i3
	ld	d, 6:opc
	ld	e, 72:opc
	call	16624672
	call	16635840
	ret
AccReplay_SendPedal_Return:
	nop
	nop

AccReplay_SavedExpression:
	ld	a, (49121:16)
	pushw	wa
	ld	w, (49122:16)
	ld	a, (49123:16)
	pushw	wa
	ld	a, (13293:16)
	ld	(49121:16), a
	ld	a, (13280:16)
	ld	(49122:16), a
	ld	a, (13281:16)
	ld	(49123:16), a
	ld	a, (36956:16)
	pushw	wa
	ld	(36956:16), 255
	calr	AccPedal_EventDispatch
	popw	wa
	ld	(36956:16), a
	popw	wa
	ld	(49122:16), w
	ld	(49123:16), a
	popw	wa
	ld	(49121:16), a
	xor	a, a
	ld	(13280:16), a
	ld	(13281:16), a
	ld	(13293:16), a
	ld	wa, 0:i3
	ld	d, 5:opc
	ld	e, 72:opc
	call	16624672
	ld	wa, 0:i3
	ld	d, 6:opc
	ld	e, 72:opc
	call	16624672
	call	16635840
	ret
AccReplay_SavedExpr_Return:
	nop
	nop
	ld	xwa, 0x094800
	add	xwa, 14
	ld	wa, (xwa)
	cp	wa, 0:i3
	jr	z, 4
	call	AccDemo_InitDone
	ret
	nop
	nop

AccReplay_FullStop:
	ld a, (0xfc5f:16)
	and A,0x0c
	ld c, (0xfc60:16)
	and C,0x04
	or A,C
	cp a, 0:i3
	jr z, .Lc_f5aef4
	and (0xfc5f:16), 0xf3
	ld wa, 0:i3
	ld D, 0x05:opc
	ld E, 0x48:opc
	call SysEx_ApplyVoiceParam_49
	and (0xfc60:16), 0xfb
	ld wa, 0:i3
	ld D, 0x06:opc
	ld E, 0x48:opc
	call SysEx_ApplyVoiceParam_49
AccReplay_Stop_ClearPedals:
.Lc_f5aef4:
	call Seq_DispatcherEntry
	cp (0x33dd:16), 0x00
	jr z, .Lc_f5af0c
	ld a, (0x33dd:16)
	add (0x0437:16), a
	ld (0x33dd:16), 0x00
AccReplay_Stop_ResetPosition:
.Lc_f5af0c:
	and (0x0437:16), 0x07
	ld a, (0x0437:16)
	cp a, (0x0433:16)
	jr c, .Lc_f5af2b
	sub a, (0x0433:16)
	ld (0x0437:16), a
	ld a, (0x0433:16)
	ld (0x33dd:16), a
AccReplay_Stop_Rebuild:
.Lc_f5af2b:
	xor WA,WA
	ld (0x0415:16), a
	ld (0x0416:16), a
	or (0x3431:16), 0x80
	or (0x33de:16), 0x01
	ld e, (0x0436:16)
	ld d, (0x0437:16)
	cp de, 0:i3
	jr z, AccReplay_Stop_Finalize
	sub E,0x18
	jr nc, AccReplay_Stop_CheckMode
	add E,0x60
	dec 1,D
	cp D,0xff
	jr nz, AccReplay_Stop_CheckMode
	ld de, 0:i3
AccReplay_Stop_CheckMode:
	xor bc, bc

	; anddi8 (0x347a), 127 (v7 patched)
	and	(0x33de:16), 127
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
	bit	7, (0x33de:16)
	jr	nz, AccReplay_Stop_Finalize
	cp	bc, de
	jr	c, AccReplay_Stop_Process
	or	(0x33de:16), 128
	cp	bc, de
	jr	z, AccReplay_Stop_Process
	ld	bc, de
	jr	AccReplay_Stop_Process
AccReplay_Stop_Finalize:
	ld a, (1078:16)

	ld (1045:16), a

	ld a, (1079:16)

	ld (1046:16), a

	; anddi8 (0x347a), 254 (v7 patched)
	and	(0x33de:16), 254
	; call Seq_DispatcherEntry (v7 addr)
	call	16068317
	ret



AccReplay_Stop_Return:
	nop
	nop

AccPos_SaveOnStop:
	ld a, (0xbfe3:16)
	cp a, 0:i3
	jr z, AccPos_SaveOnStop_Return
	bit 0, (0x28a6:16)
	jr z, AccPos_SaveOnStop_Return
	ei 0x06
	ld a, (0x0415:16)
	ld (0x0436:16), a
	ld a, (0x0416:16)
	ld (0x0437:16), a
	xor WA,WA
	ld (0x0415:16), a
	ld (0x0416:16), a
	ei 0x00
	calr AccReplay_FullStop
AccPos_SaveOnStop_Return:
	ret

AccPos_SaveOnStop_Padding:
	nop
	nop

AccPos_ClearOnStart:
	bit 0, (0x31e7:16)
	jr nz, AccPos_ClearOnStart_Return
	xor WA,WA
	ei 0x06
	ld (0x0415:16), a
	ld (0x0416:16), a
	ei 0x00
	ld (0x0436:16), a
	ld (0x0437:16), a
	ld (0x33dd:16), a
	or (0x3431:16), 0x80
	call Seq_DispatcherEntry
AccPos_ClearOnStart_Return:
	ret

AccPos_ClearOnStart_Padding:
	nop
	nop
AccPos_ClearOnStart_Padding_Sub:
	cp (0x8c98:16), 0x13
	jr nz, .Lc_f5b023
	and (0x33de:16), 0xfd
	and (0x28a6:16), 0xfe
	jr t, .Lc_f5b041
.Lc_f5b023:
	bit 1, (0x33de:16)
	jr z, .Lc_f5b041
	ld a, (0x31e7:16)
	and A,0x03
	cp a, 0:i3
	jr nz, .Lc_f5b041
	ld (0x33dd:16), 0x00
	calr AccReplay_FullStop
	and (0x33de:16), 0xfd
.Lc_f5b041:
AccPos_ClearOnStart_Padding_Sub_Return:
	ret
	.byte 0x00, 0x00
AccFlags_SyncTo64607:
	ld e, (1056:16)
	and (0xfc5f:16), 254
	bit 2, e
	jr z, AccFlags_Sync_Process
	or (0xfc5f:16), 1

AccFlags_Sync_Process:
	ld	a, e
	xor	a, (13279:16)
	bit	2, a
	jr	z, AccFlags_Sync_UpdateLED
	ld	a, 34:opc
	call	16544114
AccFlags_Sync_UpdateLED:
	ld	(0x33df:16), e
	bit	0, (0x3402:16)
	jr	z, AccFlags_Sync_Return
	and	(0x3402:16), 254
AccFlags_Sync_Return:
	ret

AccFlags_Sync_Padding:
	nop
	nop

AccTiming_InitAllParts:
	ldw	(13016:16), 65375
	ldw	(13024:16), 6
	ldw	(13026:16), 48
	ld	xbc, 12280
	calr	AccKbdTiming_TableScan
	ld	xbc, 12328
	calr	AccKbdTiming_TableScan
	ldw	(13024:16), 9
	ldw	(13026:16), 72
	ld	(13040:16), 7
	ld	xbc, 12376
	calr	AccAccTiming_TableScan
	ld	(13040:16), 4
	ld	xbc, 12448
	calr	AccAccTiming_TableScan
	ld	(13040:16), 5
	ld	xbc, 12520
	calr	AccAccTiming_TableScan
	ld	(13040:16), 6
	ld	xbc, 12592
	calr	AccAccTiming_TableScan
	ld	wa, (13016:16)
	ld	(13014:16), wa
	jr	AccTiming_MasterTick_Return
AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	ld	(0x32db:16), 95
	ldw	(0x32e0:16), 6
	ldw	(0x32e2:16), 48
	ld	a, (0x32e9:16)
	ld	(0x32e8:16), a
	ld	xhl, 10744
	ld	xbc, 12280
	calr	AccKbdTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32e9:16), a
	ld	a, (0x32ea:16)
	ld	(0x32e8:16), a
	ld	xhl, 11000
	ld	xbc, 12328
	calr	AccKbdTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32ea:16), a
	ldw	(0x32e0:16), 9
	and	(0x32f1:16), 254
	ldw	(0x32e2:16), 72
	ld	(0x32f0:16), 7
	ld	a, (0x32eb:16)
	ld	(0x32e8:16), a
	ld	a, (0x3293:16)
	ld	(0x3297:16), a
	ld	xhl, 11256
	ld	xbc, 12376
	calr	AccAccTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32eb:16), a
	ld	a, (0x3297:16)
	ld	(0x3293:16), a
	ld	(0x32f0:16), 4
	ld	a, (0x32ec:16)
	ld	(0x32e8:16), a
	ld	a, (0x3294:16)
	ld	(0x3297:16), a
	ld	xhl, 11512
	ld	xbc, 12448
	calr	AccAccTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32ec:16), a
	ld	a, (0x3297:16)
	ld	(0x3294:16), a
	ld	(0x32f0:16), 5
	ld	a, (0x32ed:16)
	ld	(0x32e8:16), a
	ld	a, (0x3295:16)
	ld	(0x3297:16), a
	ld	xhl, 11768
	ld	xbc, 12520
	calr	AccAccTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32ed:16), a
	ld	a, (0x3297:16)
	ld	(0x3295:16), a
	ld	(0x32f0:16), 6
	ld	a, (0x32ee:16)
	ld	(0x32e8:16), a
	ld	a, (0x3296:16)
	ld	(0x3297:16), a
	ld	xhl, 12024
	ld	xbc, 12592
	calr	AccAccTiming_ScanRingBuf
	ld	a, (0x32e8:16)
	ld	(0x32ee:16), a
	ld	a, (0x3297:16)
	ld	(0x3296:16), a
	ld	a, (0x32db:16)
	ld	(0x32da:16), a
	jr	AccKbdTiming_Ret
AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	ld	(14812:16), 255
	ld	ix, (xhl+6)
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
	ld	(13028:16), 2
	jr	AccKbdTiming_StoreEventData
AccKbdTiming_CheckNoteOn:
	cp	a, 144
	jr	nz, AccKbdTiming_CheckProgramChg
	ld	(13028:16), 4
	jr	AccKbdTiming_StoreEventData
AccKbdTiming_CheckProgramChg:
	and	a, 240
	cp	a, 192
	jr	nz, AccKbdTiming_CheckControl
	ld	(13028:16), 5
	jr	AccKbdTiming_StoreEventData
AccKbdTiming_CheckControl:
	cp	a, 208
	jrl	nz, AccKbdTiming_SkipEvent
	ld	(13028:16), 2
AccKbdTiming_StoreEventData:
	ld	(0x39dd:16), a
	ld	a, (xhl+ix)
	ld	(0x32dc:16), ix
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccKbdTiming_CheckTimestamp
	ld	ix, (xhl+0:8)
AccKbdTiming_CheckTimestamp:
	cp	a, (0x45d:16)
	jrl	ugt, AccKbdTiming_TimestampOverflow
	ld	a, w
	and	a, 240
	cp	w, 159
	jrl	z, AccKbdTiming_WriteNonNote
	cp	w, 223
	jrl	z, AccKbdTiming_WriteNonNote
	cp	a, 144
	jrl	nz, AccKbdTiming_WriteNonNote_Prep
	cp	(0x39dc:16), 0
	jr	nz, AccKbdTiming_NoteSlotScan
	pushw	wa
	ld	a, 8:opc
	ld	(0x39e0:16), a
	popw	wa
	calr	AccKbdTiming_CatchupReplay
	ld	(0x39dc:16), 255
AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	cp	iz, (0x32e2:16)
	jr	nc, AccKbdTiming_SlotOverflow
	bit	7, (xbc+iz)
	jr	z, AccKbdTiming_WriteNoteEvent
	add	iz, (0x32e0:16)
	jr	AccKbdTiming_SlotLoop
AccKbdTiming_SlotOverflow:
	pushw	wa
	xor	xwa, xwa
	ld	a, (0x32e8:16)
	sla	xwa, 2
	add	xwa, AccTiming_SlotOffsetTables
	ld	iz, (xwa)
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	pushw	iz
	inc	2, iz
	ld	w, (xbc+iz)
	and	a, 240
	or	a, 8
	calr	AccSeq_WriteByte
	ld	a, w
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	popw	iz
	popw	wa
	inc	1, (0x32e8:16)
	cp	(0x32e8:16), 8
	jr	c, AccKbdTiming_SlotOverflow_Done
	ld	(0x32e8:16), 0
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
	cp	wa, (0x32d6:16)
	jr	nc, AccKbdTiming_WriteNote_UpdateReadPos
	ld	(0x32d6:16), wa
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
	calr	AccSeq_WriteByte
	cp	w, 223
	jr	nz, AccKbdTiming_WriteNonNote_CheckType
	ld	a, 0:opc
	ld	(12947:16), a
	ld	(12948:16), a
	ld	(12949:16), a
	ld	(12950:16), a
	jr	AccKbdTiming_WriteNonNote_Done
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
	cp	(0x39dd:16), 192
	jr	nz, AccKbdTiming_Overflow_SubBase
	ld	(0x39dc:16), 0
AccKbdTiming_Overflow_SubBase:
	sub	a, (0x45d:16)
	cp	a, (0x32db:16)
	jr	nc, AccKbdTiming_Overflow_CalcSkip
	ld	(0x32db:16), a
AccKbdTiming_Overflow_CalcSkip:
	ld	ix, (0x32dc:16)
	ld	(xhl+ix), a
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccKbdTiming_Overflow_AdvancePos
	ld	ix, (xhl+0:8)
AccKbdTiming_Overflow_AdvancePos:
	xor wa, wa

	ld a, (13028:16)

	add ix, wa

	cp ix, (xhl + 2)

	jrl ule, AccKbdTiming_EventLoop

	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 0:8)

	; jrl AccKbdTiming_EventLoop (v7 displacement)
	jrl	AccKbdTiming_EventLoop
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
	cp	ix, iy
	jr	z, AccKbdTiming_Catchup_Done	; -> 0xF5B4F4
	ld	a, (xhl+ix)
	ld	w, a
	and	w, 240
	cp	w, 192
	jr	nz, AccKbdTiming_Catchup_SkipNonC0	; -> 0xF5B4EF
	ld	a, w
	or	a, (14816:16)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	calr	AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	ld	a, (xhl+ix)
	calr	AccSeq_WriteByte
	calr	AccKbdTiming_AdvancePos
	jr	AccKbdTiming_Catchup_Loop	; -> 0xF5B494
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
	cp	iz, (0x32e2:16)
	jp	nc, (0xf5b589:24)
	bit	7, (xbc+iz)
	jr	z, AccKbdTiming_TableScan_NextSlot
	ld	ix, iz
	ld	a, (xbc+ix)
	ld	(0x32e5:16), a
	inc	2, ix
	ld	a, (xbc+ix)
	ld	(0x32e6:16), a
	inc	1, ix
	ld	a, (xbc+ix)
	ld	(0x32e7:16), a
	inc	1, ix
	ld	wa, (xbc+ix)
	cp	wa, (0x45e:16)
	jr	gt, AccKbdTiming_TableScan_Decrement
	ld	a, 240:opc
	and	a, (0x32e5:16)
	or	a, 8
	calr	AccSeq_WriteByte
	ld	a, (0x32e6:16)
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	and	(xbc+iz), 0x7f
	jr	AccKbdTiming_TableScan_NextSlot
AccKbdTiming_TableScan_Decrement:
	sub wa, (1118:16)
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	ld	(xbc+ix), wa
	cp	wa, (0x32d8:16)
	jr	nc, AccKbdTiming_TableScan_NextSlot
	ld	(0x32d8:16), wa
AccKbdTiming_TableScan_NextSlot:
	; addda16 xiz, 0x337c (v7 patched)
	add	iz, (0x32e0:16)
	; jrl AccKbdTiming_TableScan_Loop (v7 displacement)
	jrl	AccKbdTiming_TableScan_Loop
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
	ld	(14814:16), 255
	ld	ix, (xhl+6)
AccAccTiming_EventLoop:
	cp (xhl + 4), ix
	jrl z, AccAccTiming_ScanDone
	ld	a, (xhl+ix)
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 0:8)

AccAccTiming_ClassifyEvent:
	ld	w, a
	cp	a, 144
	jr	nz, AccAccTiming_Check0x91
	ld	(13028:16), 5
	jr	AccAccTiming_StoreEventData
AccAccTiming_Check0x91:
	cp	a, 145
	jr	nz, AccAccTiming_Check0x92
	ld	(13028:16), 7
	jr	AccAccTiming_StoreEventData
AccAccTiming_Check0x92:
	cp	a, 146
	jr	nz, AccAccTiming_CheckProgramChg
	ld	(13028:16), 6
	jr	AccAccTiming_StoreEventData
AccAccTiming_CheckProgramChg:
	and	a, 240
	cp	a, 192
	jr	nz, AccAccTiming_CheckControl
	ld	(13028:16), 5
	jr	AccAccTiming_StoreEventData
AccAccTiming_CheckControl:
	cp	a, 208
	jrl	nz, AccAccTiming_SkipEvent
	ld	(13028:16), 2
AccAccTiming_StoreEventData:
	ld	(0x39df:16), a
	ld	a, (xhl+ix)
	ld	(0x32de:16), ix
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccAccTiming_CheckTimestamp
	ld	ix, (xhl+0:8)
AccAccTiming_CheckTimestamp:
	cp	a, (0x45d:16)
	jrl	ugt, AccAccTiming_TimestampOverflow
	ld	a, w
	and	a, 240
	cp	a, 144
	jrl	nz, AccAccTiming_WriteNonNote
	cp	(0x39de:16), 0
	jr	nz, AccAccTiming_NoteSlotScan
	pushw	wa
	ld	a, (0x32f0:16)
	ld	(0x39e0:16), a
	popw	wa
	calr	AccKbdTiming_CatchupReplay
	ld	(0x39de:16), 255
AccAccTiming_NoteSlotScan:
	pushw wa
	ld	w, (xhl+ix)
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	cp	iz, (0x32e2:16)
	jr	nc, AccAccTiming_NoteSlot_FindFree
	bit	7, (xbc+iz)
	jr	z, AccAccTiming_NoteSlot_NextSlot
	ld	qiz, iz
	add	iz, 2
	cp	(xbc+iz), w
	ld	iz, qiz
	jr	z, AccAccTiming_NoteSlot_SendNoteOff
AccAccTiming_NoteSlot_NextSlot:
	add	iz, (0x32e0:16)
	jr	AccAccTiming_NoteSlot_Loop
AccAccTiming_NoteSlot_SendNoteOff:
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	and	a, 240
	or	a, (0x32f0:16)
	calr	AccSeq_WriteByte
	ld	a, w
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	bit	0, (0x32f1:16)
	jr	nz, AccAccTiming_NoteSlot_FindFree
	or	(0x32f1:16), 1
	ld	a, 144:opc
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	calr	AccSeq_WriteByte
AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	cp	iz, (0x32e2:16)
	jr	nc, AccAccTiming_SlotOverflow
	bit	7, (xbc+iz)
	jr	z, AccAccTiming_WriteNoteEvent
	add	iz, (0x32e0:16)
	jr	AccAccTiming_NoteSlot_FreeLoop
AccAccTiming_SlotOverflow:
	pushw	wa
	xor	xwa, xwa
	ld	a, (0x32e8:16)
	sla	xwa, 2
	add	xwa, AccAccTiming_SlotOverflow_Data
	ld	iz, (xwa)
	ld	a, (xbc+iz)
	and	(xbc+iz), 0x7f
	pushw	iz
	inc	2, iz
	ld	w, (xbc+iz)
	and	a, 240
	or	a, (0x32f0:16)
	calr	AccSeq_WriteByte
	ld	a, w
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	popw	iz
	popw	wa
	inc	1, (0x32e8:16)
	cp	(0x32e8:16), 8
	jr	c, AccAccTiming_SlotOverflow_Done
	ld	(0x32e8:16), 0
AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	or	a, (0x32f0:16)
	calr	AccSeq_WriteByte
	ld	a, w
	ld	(xbc+iz), a
	inc	1, iz
	ld	a, 0:opc
	ld	(xbc+iz), a
	inc	1, iz
	ld	a, (xhl+ix)
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccAccTiming_WriteNote_Byte2
	ld	ix, (xhl+0:8)
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
	inc	2, iz
	cp	wa, (13014:16)
	jr	nc, AccAccTiming_WriteNote_ExtraBytes	; -> 0xF5B795
	ld	(13014:16), wa
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
	ld	w, a
	or	a, (0x32f0:16)
	calr	AccSeq_WriteByte
	ld	a, (xhl+ix)
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccAccTiming_WriteNonNote_Byte2
	ld	ix, (xhl+0:8)
AccAccTiming_WriteNonNote_Byte2:
	calr	AccSeq_WriteByte
	ld	(0x3298:16), a
	ld	a, (xhl+ix)
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccAccTiming_WriteNonNote_Byte3
	ld	ix, (xhl+0:8)
AccAccTiming_WriteNonNote_Byte3:
	calr	AccSeq_WriteByte
	cp	w, 208
	jr	nz, AccAccTiming_WriteNonNote_ExtBytes
	cp	(0x3298:16), 3
	jr	nz, AccAccTiming_WriteNonNote_Done
	ld	(0x3297:16), a
	jr	AccAccTiming_WriteNonNote_Done
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
	cp	(0x39df:16), 192
	jr	nz, AccAccTiming_Overflow_SubBase
	ld	(0x39de:16), 0
AccAccTiming_Overflow_SubBase:
	sub	a, (0x45d:16)
	cp	a, (0x32db:16)
	jr	nc, AccAccTiming_Overflow_CalcSkip
	ld	(0x32db:16), a
AccAccTiming_Overflow_CalcSkip:
	ld	ix, (0x32de:16)
	ld	(xhl+ix), a
	inc	1, ix
	cp	ix, (xhl+2)
	jr	ule, AccAccTiming_Overflow_AdvancePos
	ld	ix, (xhl+0:8)
AccAccTiming_Overflow_AdvancePos:
	xor wa, wa

	ld a, (13028:16)

	add ix, wa

	cp ix, (xhl + 2)

	; jrl ule, AccAccTiming_EventLoop (v7 displacement)
	jrl	ule, AccAccTiming_EventLoop
	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 0:8)

	; jrl AccAccTiming_EventLoop (v7 displacement)
	jrl	AccAccTiming_EventLoop
AccAccTiming_ScanDone:
	ret

AccAccTiming_TableScan:
	xor iz, iz

AccAccTiming_TableScan_Loop:
	cp	iz, (0x32e2:16)
	jp	nc, (0xf5b931:24)
	bit	7, (xbc+iz)
	jr	z, AccAccTiming_TableScan_NextSlot
	ld	ix, iz
	ld	a, (xbc+ix)
	ld	(0x32e5:16), a
	inc	2, ix
	ld	a, (xbc+ix)
	ld	(0x32e6:16), a
	inc	1, ix
	ld	a, (xbc+ix)
	ld	(0x32e7:16), a
	inc	1, ix
	ld	wa, (xbc+ix)
	cp	wa, (0x45e:16)
	jr	gt, AccAccTiming_TableScan_Decrement
	ld	a, 240:opc
	and	a, (0x32e5:16)
	or	a, (0x32f0:16)
	calr	AccSeq_WriteByte
	ld	a, (0x32e6:16)
	calr	AccSeq_WriteByte
	ld	a, 0:opc
	calr	AccSeq_WriteByte
	and	(xbc+iz), 0x7f
	jr	AccAccTiming_TableScan_NextSlot
AccAccTiming_TableScan_Decrement:
	sub wa, (1118:16)
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	ld	(xbc+ix), wa
	cp	wa, (0x32d8:16)
	jr	nc, AccAccTiming_TableScan_NextSlot
	ld	(0x32d8:16), wa
AccAccTiming_TableScan_NextSlot:
	; addda16 xiz, 0x337c (v7 patched)
	add	iz, (0x32e0:16)
	; jrl AccAccTiming_TableScan_Loop (v7 displacement)
	jrl	AccAccTiming_TableScan_Loop
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
; readers in v7 (address from the linked ELF): AccKbdTiming_SlotOverflow 0xF5B2CD,
;     AccAccTiming_SlotOverflow 0xF5B6B6
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	cp (0x340b:16), 0x00
	jr nz, .Lc_f5b990
	cp (0x340c:16), 0x00
	jr z, .Lc_f5b990
	or (0x3403:16), 0x01
AccDir_CheckLeftNote:
.Lc_f5b990:
	cp (0x340d:16), 0x00
	jr nz, .Lc_f5b9a3
	cp (0x340e:16), 0x00
	jr z, .Lc_f5b9a3
	or (0x3403:16), 0x08
AccDir_CheckRightHandState:
.Lc_f5b9a3:
	ld a, (0x3409:16)
	bit 0x00,A
	jr nz, AccDir_Finalize
	bit 0x01,A
	jr z, AccDir_Finalize
	and (0x3403:16), 0xf6
	ld (0x340a:16), 0x00
AccDir_Finalize:
	calr AccDir_AdjustDirection
	calr AccDir_SavePrevState
	ret

AccDir_Padding1:
	nop
	nop

AccDir_ReadState:
	ld a, (0xfc5a:16)
	ld (0x3408:16), a
	ld a, (0x3276:16)
	and A,0x3f
	ld (0x340b:16), a
	ld a, (0x3277:16)
	and A,0x3f
	ld (0x340d:16), a
	ld a, (0x0415:16)
	ld (0x3404:16), a
	ld a, (0x3409:16)
	and A,0xfe
	bit 0, (0x31e7:16)
	jr z, .Lc_f5b9fa
	or A,0x01
AccDir_ReadState_StoreFlags:
.Lc_f5b9fa:
	ld (0x3409:16), a
	ld a, (0xfd99:16)
	bit 0x00,A
	jr nz, AccDir_ReadState_Ret
	and (0x3403:16), 0xf6
AccDir_ReadState_Ret:
	ret

AccDir_Padding2:
	nop
	nop

AccDir_SavePrevState:
	ld	a, (13323:16)
	ld	(13324:16), a
	ld	a, (13325:16)
	ld	(13326:16), a
	ld	a, (13321:16)
	and	a, 253
	bit	0, a
	jr	z, AccDir_SavePrevState_StoreFlags
	or	a, 2
AccDir_SavePrevState_StoreFlags:
	ld	(13321:16), a
	ret
AccDir_Padding3:
	nop
	nop

AccDir_AdjustDirection:
	ld a, (0x3403:16)
	and A,0x09
	cp a, 0:i3
	jp z, (AccDir_Adjust_Ret:24)
	bit 0, (0x3403:16)
	jr z, AccDir_Adjust_LeftHand
	and (0x3403:16), 0xfe
	cp (0x3408:16), 0x80
	jr nc, AccDir_Adjust_LeftHand
	ld w, (0xfd99:16)
	and W,0x01
	ld a, (0xfc61:16)
	and A,0x30
	srl A, 0x04
	cp w, 0:i3
	jr z, AccDir_Adjust_LeftHand
	dec 1,A
	cp A,0xff
	jr nz, AccDir_Adjust_RightDec
	ld A, 0x00:opc
AccDir_Adjust_RightDec:
	sll a, 4
	and (0xfc61:16), 207
	or (0xfc61:16), a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	bit	3, (0x3403:16)
	jr	z, AccDir_Adjust_SetChanged
	and	(0x3403:16), 247
	cp	(0x3408:16), 128
	jr	nc, AccDir_Adjust_SetChanged
	ld	w, (0xfd99:16)
	and	w, 1
	ld	a, (0xfc61:16)
	and	a, 48
	srl	a, 4
	cp	w, 0:i3
	jr	z, AccDir_Adjust_SetChanged
	inc	1, a
	cp	a, 4:i3
	jr	c, AccDir_Adjust_LeftInc
	ld	a, 3:opc
AccDir_Adjust_LeftInc:
	sll a, 4
	and (0xfc61:16), 207
	or (0xfc61:16), a
	calr AccDir_DispatchEvent

AccDir_Adjust_SetChanged:
	ld	(13322:16), 1
AccDir_Adjust_Ret:
	ret

AccDir_Padding4:
	nop
	nop

AccDir_DispatchEvent:
	ld w, (0xfd99:16)
	and W,0x01
	cp w, 0:i3
	jr z, AccDir_DispatchEvent_Ret
	cp (0x3408:16), 0x80
	jr nc, AccDir_DispatchEvent_Ret
	ld E, 0x48:opc
	ld D, 0x07:opc
	ld a, (0xfc61:16)
	ld W, 0x30:opc
	call SysEx_ApplyVoiceParam_49
	ld a, (0xfd99:16)
	and A,0x70
	cp A,0x10
	jr z, AccDir_DispatchEvent_Ret
	ld a, (0xfc61:16)
	and A,0x30
	srl A, 0x04
	ld (0x8cb8:16), a
	call EffectMode_ReinitWithFlag
AccDir_DispatchEvent_Ret:
	ret

AccDir_Padding5:
	nop
	nop

AccDir_PeriodicCheck:
	bit 4, (0x31e8:16)
	jr z, AccDir_Periodic_Ret
	cp (0x340a:16), 0x00
	jr z, .Lc_f5bb1a
	dec 1, (0x340a:16)
AccDir_Periodic_CheckCountdown:
.Lc_f5bb1a:
	cp (0x340a:16), 0x00
	jr nz, AccDir_Periodic_Ret
	ld a, (0x0415:16)
	cp A,0x5d
	jr nc, .Lc_f5bb2f
	cp A,0x30
	jr ugt, AccDir_Periodic_Ret
AccDir_Periodic_DisableAndReset:
.Lc_f5bb2f:
	and (0x31e8:16), 0xef
	and (0x31e8:16), 0xfb
	call 0xfdd7c0



AccDir_Periodic_Ret:
	ret

AccDir_JumpTable:
	nop
	nop
	call	16104266
	ret
AccProcess_Entry:
	call AccProcess_TimerCompare
	ret

AccProcess_InlinedCode:
	; framing ported from v10's source for the same label (same span length, statement for statement); 45 of 74 slots byte-identical
	ld	a, (49121:16)
	cp	a, 18
	; v10 does not spell this byte either
	jp	nz, (0xf5bbdd:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	a, (0xbfe2:16)
	; differs from v10 here and llvm-objdump cannot read it
	and	a, (49123:16)
	and	a, 1
	cp	a, 1:i3
	; v10 does not spell this byte either
	jp	nz, (0xf5bbdd:24)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	bit	0, (0x33f4:16)
	; v10 does not spell this byte either
	jr	nz, AccProcess_Entry_Skip5
	ld	wa, (0x409:16)
	ld	(0x33f2:16), wa
	; v10 does not spell this byte either
	or	(0x33f4:16), 1
	; v10 does not spell this byte either
	jr	AccProcess_Entry_Return
AccProcess_Entry_Skip5:
	ld	wa, (1033:16)
	ld	bc, (13298:16)
	cp	wa, bc
	jr	c, AccProcess_Entry_Skip6
	sub	wa, bc
	jr	AccProcess_Entry_Join2
AccProcess_Entry_Skip6:
	and	xwa, 65535
	and	xbc, 65535
	add	xwa, 65536
	sub	xwa, xbc
AccProcess_Entry_Join2:
	cp	wa, 750
	jr	c, AccProcess_Entry_Skip
	ldw	wa, 750
AccProcess_Entry_Skip:
	cp	wa, 100
	jr	ugt, AccProcess_Entry_Skip2
	ldw	wa, 100
AccProcess_Entry_Skip2:
	ld	bc, wa
	ld	xwa, 30000
	div	xwa, bc
	pushw	wa
	calr	AccProcess_Entry_Helper
	popw	wa
	ld	hl, (13304:16)
	ld	(13306:16), hl
	ld	hl, (13302:16)
	ld	(13304:16), hl
	ld	(13302:16), wa
	ld	wa, (1033:16)
	ld	(13298:16), wa
AccProcess_Entry_Return:
	ret
AccProcess_Entry_Helper:
	ld	de, (13302:16)
	ld	bc, (13304:16)
	cp	de, 0:i3
	jr	nz, AccProcess_Entry_Skip3
	jp	AccProcess_Entry_Join
AccProcess_Entry_Skip3:
	cp	bc, 0:i3
	jr	nz, AccProcess_Entry_Skip4
	add	wa, de
	srl	wa, 1
	jp	AccProcess_Entry_Join
AccProcess_Entry_Skip4:
	add	wa, de
	add	wa, bc
	and	xwa, 65535
	div	wa, 3
AccProcess_Entry_Join:
	ld	e, 72:opc
	ld	d, 8:opc
	call	SwbtWr_TrailingBytecode
	ret
AccProcess_TimerCompare:
	bit	0, (0x33f4:16)
	jr	z, AccProcess_Timer_Ret
	ld	wa, (0x409:16)
	ld	bc, (0x33f2:16)
	cp	wa, bc
	jr	c, AccProcess_Timer_WrapCase
	sub	wa, bc
	cp	wa, 1024
	jr	c, AccProcess_Timer_Skip
	and	(0x33f4:16), 254
	xor	wa, wa
	ld	(0x33f6:16), wa
	ld	(0x33f8:16), wa
	ld	(0x33fa:16), wa
AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	and	xwa, 65535
	and	xbc, 65535
	add	xwa, 65536
	sub	xwa, xbc
	cp	wa, 1024
	jr	c, AccProcess_Timer_Ret
	and	(0x33f4:16), 254
	xor	wa, wa
	ld	(0x33f6:16), wa
	ld	(0x33f8:16), wa
	ld	(0x33fa:16), wa
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
	pop	xiy
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ld	xiy, 13327
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

	; add xwa, AccVoice_RomRecords13 (v7 patched)
	add	xwa, AccVoice_RomRecords13
	ld xiy, xwa

	ld xix, 13327

	ldw bc, 0xd

	ldir85

	ret



AccVoice_ComputedCopy_Padding:
	nop
	nop

AccVoice_ROMLookup:
	ld L,H
	and HL,0x000f
	sla HL, 0x02
	ld XIX,AccVoice_ROMLookup_Data
	ld XIY,0x00094800
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x85, 0x44, 0x0f, 0x34
	.byte 0x00, 0x00, 0x31, 0x0d, 0x00, 0x85, 0x11, 0x0e
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
	ld L,H
	xor H,H
	sla HL, 0x02
	ld XIX,AccVoice_IndexedTableLookup_Data
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x25, 0x44, 0xd4, 0xbe
	.byte 0xf5, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x85, 0x44
	.byte 0x0f, 0x34, 0x00, 0x00, 0x31, 0x0d, 0x00, 0x85
	.byte 0x11, 0x0e
AccVoice_IndexedTableLookup_BaseOffsets:
	.byte	0x00, 0x00
AccVoice_IndexedTableLookup_Data:	.byte	0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
	.byte 0x30, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x98, 0x31, 0x00, 0x00, 0x98
	.byte 0x31, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x00, 0x33, 0x00, 0x00, 0x00
	.byte 0x33, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x98, 0x34, 0x00, 0x00, 0x98
	.byte 0x34, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x00, 0x36, 0x00, 0x00, 0x00
	.byte 0x36, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x98, 0x37, 0x00, 0x00, 0x98
	.byte 0x37, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0x00, 0x00, 0x39, 0x00, 0x00, 0x00
	.byte 0x39, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xa0, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x00, 0x00, 0x60, 0x01, 0x00, 0x00, 0xc0, 0x01
	.byte 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x80, 0x02
	.byte 0x00, 0x00, 0xe0, 0x02, 0x00, 0x00, 0x40, 0x03
	.byte 0x00, 0x00, 0xa0, 0x03, 0x00, 0x00, 0x00, 0x04
	.byte 0x00, 0x00, 0x60, 0x04, 0x00, 0x00, 0xc0, 0x04
	.byte 0x00, 0x00, 0xcf, 0xca, 0x8c, 0xdb, 0xcc, 0x07
	.byte 0x00, 0xdb, 0xec, 0x02, 0x44, 0x4a, 0xc0, 0xf5
	.byte 0x00, 0x45, 0x00, 0x48, 0x09, 0x00, 0xe3, 0x07
	.byte 0xf0, 0xec, 0x85, 0x44, 0x0f, 0x34, 0x00, 0x00
	.byte 0x31, 0x0d, 0x00, 0x85, 0x11, 0x0e, 0x00, 0x00
AccVoice_IndexedTableLookup_BaseOffsets_Data:
	.byte 0xb0, 0x0b, 0x00, 0x00, 0xd0, 0x0b, 0x00, 0x00
	.byte 0xf0, 0x0b, 0x00, 0x00, 0x10, 0x0c, 0x00, 0x00
	.byte 0x30, 0x0c, 0x00, 0x00, 0xb0, 0x0b, 0x00, 0x00
	.byte 0xb0, 0x0b, 0x00, 0x00, 0xb0, 0x0b, 0x00, 0x00
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

	; add xwa, AccVoice_RomRecords16 (v7 patched)
	add	xwa, AccVoice_RomRecords16
	ld xiy, xwa

	ld xix, 13327

	ldw bc, 0x10

	ldir85

	pop xiy

	pop xhl

	pop xbc

	pop xwa

	ld xiy, 13327

	ret



AccVoice_CopyFromROM_DataBlock:
	nop
	nop
	pushw	hl
	calr	64464
	popw	hl
	ld	xix, 0:i3
	ldw	bc, 8
	ldirw
	ld	xiy, AccVoice_CopyFromROM_DataBlock_Data
	jr	c, 5
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
	ld	(0:8), 0:io
	ld	(1:8), 1:io
	jr	AccVoice_CopyFromROM_Skip2
AccVoice_CopyFromROM_Skip3:
	ld	(11:8), 0:io
	ld	(12:8), 1:io
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
; readers in v7 (address from the linked ELF): AccVoice_CopyFromROM_DataBlock 0xF5C0C3
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	jp	AccStyle_JumpTable_Data

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
	ld	a, (13042:16)
	and	a, 31
	jr	z, AccStyle_Process_SaveState
	ld	a, (13043:16)
	and	a, 31
	jr	nz, AccStyle_Process_DoChain
	calr	AccVoiceState_Snapshot
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
	ld	a, (13042:16)
	ld	(13043:16), a
	ret
AccStyle_ToggleBit0:
	cp (0x8c98:16), 0x11
	jr nz, .Lc_f5c1dc
	jr t, AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CheckC07D:
.Lc_f5c1dc:
	cp (0xbfe1:16), 0x06
	jr nz, AccStyle_ToggleBit0_Ret
	ld a, (0xbfe2:16)
	and	a, (0xbfe3:16)
	bit	0, a
	jr	z, AccStyle_ToggleBit0_Ret
	xor	(0x32f5:16), 1
	bit	0, (0x32f5:16)
	jr	nz, AccStyle_ToggleBit0_CallOn
	call	AccTuning_LEDOff
	jr	AccStyle_ToggleBit0_Ret
AccStyle_ToggleBit0_CallOn:
	call AccTuning_LEDOn
AccStyle_ToggleBit0_Ret:
	ret
AccStyle_IndexedLookup:
	cp (0x8c98:16), 0x11
	jr nz, AccStyle_IndexedLookup_Ret
	cp (0xbfe1:16), 0x10
	jr nz, AccStyle_IndexedLookup_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr z, AccStyle_IndexedLookup_Ret
	ld l, (0x32f2:16)
	and L,0x1f
	extz HL
	ld XWA,AccStyle_IndexedLookup_Data
	ld	a, (xwa+hl)
	cp	(35998:16), a
	jr	z, AccStyle_IndexedLookup_Ret
	ld	(35998:16), a
	ld	e, 144:opc
	ld	d, 16:opc
	ld	w, 255:opc
	call	SysEx_ApplyVoiceParam_49
AccStyle_IndexedLookup_Ret:
	ret


AccStyle_ModeEnter_Wrap:
	push xiz
	calr AccStyle_ModeEnter
	pop xiz
	ret

AccStyle_ModeEnter:
	cp (0x8c99:16), 0x11
	jr z, AccStyle_ModeEnter_Ret
	ld (0x32f2:16), 0x00
	ld (0x32f3:16), 0x00
	ld (0x3303:16), 0x00
	and (0x3335:16), 0xfe
	cpw (0xf19e:16), 0x0000
	jr z, .Lc_f5c281
	call SeqAcc_SetIndicator_PB
	ldw (0xf19e:16), 0x0000
	call PerfMode_Handler_EvtB_Helper2_Helper11
	or (0x3335:16), 0x01
AccStyle_ModeEnter_SetFlags:
.Lc_f5c281:
	or (0x3431:16), 0x08
	or (0x3337:16), 0x01

	ld a, 0x4b:opc

	call	CtrlPanel_SetIndicatorBit



AccStyle_ModeEnter_Ret:
	ret

AccStyle_ModeExit_Wrap:
	push xiz
	calr AccStyle_ModeExit
	pop xiz
	ret

AccStyle_ModeExit:
	cp (0x8c98:16), 0x11
	jr z, AccStyle_ModeExit_Ret
	ld (0x32f2:16), 0x00
	ld (0x32f3:16), 0x00
	ld (0x3303:16), 0x00
	and (0x3431:16), 0xf7
	bit 0, (0x3335:16)
	jr z, .Lc_f5c2c6
	and (0x3335:16), 0xfe
	call AccWrap_PlayModeDispatch
	call SeqAcc_RestorePlaybackState
AccStyle_ModeExit_ClearFlags:
.Lc_f5c2c6:
	and (0x3337:16), 0xfc
	call PartSelect_UpdateDisplayState



AccStyle_ModeExit_Ret:
	ret

AccStyle_InlinedBlock:
	.byte	0x3e, 0x1e, 0x02, 0x00, 0x5e, 0x0e
AccStyle_JumpTable_Data:	.byte	0xc1, 0x9b
	.byte 0x8c, 0x3f, 0xdc, 0x76, 0x62, 0x01, 0xc1, 0x5a
	.byte 0xfc, 0x3f, 0x80, 0x67, 0x17, 0xf1, 0x03, 0x33
	.byte 0x00, 0x01, 0x21, 0x08, 0x1d, 0xd2, 0xb5, 0xfe
	.byte 0xf1, 0xa6, 0x7e, 0x00, 0x36, 0x1d, 0xee, 0x54
	.byte 0xf6, 0x78, 0x73, 0x01, 0xf1, 0xf2, 0x32, 0x00
	.byte 0x20, 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10
	.byte 0x78, 0x1e, 0x00, 0x8b, 0x01, 0x3e, 0x80, 0x1e
	.byte 0x1f, 0x03, 0x1d, 0xb0, 0x93, 0xf5, 0xc1, 0xaa
	.byte 0x31, 0x25, 0xc1, 0xab, 0x31, 0x24, 0x43, 0x78
	.byte 0x31, 0x00, 0x00, 0xb3, 0x45, 0xbb, 0x01, 0x44
	.byte 0xc1, 0xb1, 0x31, 0x25, 0xc1, 0xb2, 0x31, 0x24
	.byte 0xc1, 0xb3, 0x31, 0x21, 0xf1, 0x93, 0x33, 0x41
	.byte 0xc1, 0xb4, 0x31, 0x21, 0xf1, 0x94, 0x33, 0x41
	.byte 0xc1, 0xb5, 0x31, 0x21, 0xf1, 0x95, 0x33, 0x41
	.byte 0xc1, 0xb6, 0x31, 0x21, 0xf1, 0x27, 0x32, 0x41
	.byte 0xc1, 0xb7, 0x31, 0x21, 0xf1, 0x2b, 0x32, 0x41
	.byte 0x1d, 0x2d, 0x3d, 0xf5, 0x43, 0x7d, 0x31, 0x00
	.byte 0x00, 0x1d, 0x12, 0x3d, 0xf5, 0xc1, 0xb8, 0x31
	.byte 0x25, 0xc1, 0xb9, 0x31, 0x24, 0xc1, 0xba, 0x31
	.byte 0x21, 0xf1, 0x93, 0x33, 0x41, 0xc1, 0xbb, 0x31
	.byte 0x21, 0xf1, 0x94, 0x33, 0x41, 0xc1, 0xbc, 0x31
	.byte 0x21, 0xf1, 0x95, 0x33, 0x41, 0xc1, 0xbd, 0x31
	.byte 0x21, 0xf1, 0x27, 0x32, 0x41, 0xc1, 0xbe, 0x31
	.byte 0x21, 0xf1, 0x2b, 0x32, 0x41, 0x1d, 0x2d, 0x3d
	.byte 0xf5, 0x43, 0x82, 0x31, 0x00, 0x00, 0x1d, 0x12
	.byte 0x3d, 0xf5, 0xc1, 0xbf, 0x31, 0x25, 0xc1, 0xc0
	.byte 0x31, 0x24, 0xc1, 0xc1, 0x31, 0x21, 0xf1, 0x93
	.byte 0x33, 0x41, 0xc1, 0xc2, 0x31, 0x21, 0xf1, 0x94
	.byte 0x33, 0x41, 0xc1, 0xc3, 0x31, 0x21, 0xf1, 0x95
	.byte 0x33, 0x41, 0xc1, 0xc4, 0x31, 0x21, 0xf1, 0x27
	.byte 0x32, 0x41, 0xc1, 0xc5, 0x31, 0x21, 0xf1, 0x2b
	.byte 0x32, 0x41, 0x1d, 0x2d, 0x3d, 0xf5, 0x43, 0x87
	.byte 0x31, 0x00, 0x00, 0x1d, 0x12, 0x3d, 0xf5, 0xc1
	.byte 0xc6, 0x31, 0x25, 0xc1, 0xc7, 0x31, 0x24, 0xc1
	.byte 0xc8, 0x31, 0x21, 0xf1, 0x93, 0x33, 0x41, 0xc1
	.byte 0xc9, 0x31, 0x21, 0xf1, 0x94, 0x33, 0x41, 0xc1
	.byte 0xca, 0x31, 0x21, 0xf1, 0x95, 0x33, 0x41, 0xc1
	.byte 0xcb, 0x31, 0x21, 0xf1, 0x27, 0x32, 0x41, 0xc1
	.byte 0xcc, 0x31, 0x21, 0xf1, 0x2b, 0x32, 0x41, 0x1d
	.byte 0x2d, 0x3d, 0xf5, 0x43, 0x8c, 0x31, 0x00, 0x00
	.byte 0x1d, 0x12, 0x3d, 0xf5, 0x1e, 0xe1, 0x01, 0x1e
	.byte 0x92, 0x01, 0x1e, 0xab, 0x00, 0x1e, 0xf4, 0x00
	.byte 0x1e, 0x3d, 0x01, 0xf1, 0xf2, 0x32, 0x00, 0x01
	.byte 0x21, 0x14, 0xf1, 0x9e, 0x8c, 0x41, 0x25, 0x90
	.byte 0x24, 0x10, 0x20, 0xff, 0x1d, 0x20, 0xac, 0xfd
	.byte 0xc1, 0x03, 0x33, 0x3f, 0x01, 0x6e, 0x0a, 0xd8
	.byte 0xd0, 0x21, 0x01, 0x1d, 0x56, 0x90, 0xf9, 0x68
	.byte 0x1e, 0xc1, 0xf2, 0x32, 0x21, 0xc9, 0xcc, 0x1f
	.byte 0x66, 0x10, 0xc1, 0x37, 0x33, 0x3c, 0xfd, 0xc1
	.byte 0xf5, 0x32, 0x3e, 0x01, 0x1d, 0x65, 0x96, 0xf5
	.byte 0x68, 0x05, 0xc1, 0x37, 0x33, 0x3e, 0x02, 0x0e
; AccStyle_InlinedBlock +0x1A0..+0x1FF -- two u8 tables; the 0x1A0 bytes above
; them are the block's code, still spelled as .byte in v7 (they were one
; island with these tables, which the re-framer refuses as a whole).
; ** RE-TYPED 2026-09-25 (lane accomp), as in v9/v10, where the readers are
; cited: AccStyle_IndexedLookup and AccVoiceState_DispatchChange read the
; +0x1E0 table with the one-hot index (0x338e) & 0x1f.
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	cp (0x8c98:16), 0x11
	jr nz, AccVoiceReg_WritePart3_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, AccVoiceReg_WritePart3_Ret
	ld a, (0x3182:16)
	ld w, (0x3183:16)
	bit 0x04,W
	jr z, AccVoiceReg_WritePart3_StoreBit4
	or A,0x80
	and W,0xef
AccVoiceReg_WritePart3_StoreBit4:
	ld (0xfb56:16), a

	and w, 0x7f

	and (0xfb57:16), 128

	or (0xfb57:16), w

	ld a, (12677:16)

	sla a, 6

	and a, 0x40

	and (0xfb5a:16), 191

	or (0xfb5a:16), a

	ld l, 0x4:opc

	; calr AccVoiceState_DispatchChange (v7 displacement)
	calr	AccVoiceState_DispatchChange
AccVoiceReg_WritePart3_Ret:
	ret

AccVoiceReg_WritePart4:
	cp (0x8c98:16), 0x11
	jr nz, AccVoiceReg_WritePart4_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, AccVoiceReg_WritePart4_Ret
	ld a, (0x3187:16)
	ld w, (0x3188:16)
	bit 0x04,W
	jr z, AccVoiceReg_WritePart4_StoreBit4
	or A,0x80
	and W,0xef
AccVoiceReg_WritePart4_StoreBit4:
	ld (0xfb70:16), a

	and w, 0x7f

	and (0xfb71:16), 128

	or (0xfb71:16), w

	ld a, (12682:16)

	sla a, 6

	and a, 0x40

	and (0xfb74:16), 191

	or (0xfb74:16), a

	ld l, 0x8:opc

	; calr AccVoiceState_DispatchChange (v7 displacement)
	calr	AccVoiceState_DispatchChange
AccVoiceReg_WritePart4_Ret:
	ret

AccVoiceReg_WritePart5:
	cp (0x8c98:16), 0x11
	jr nz, AccVoiceReg_WritePart5_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, AccVoiceReg_WritePart5_Ret
	ld a, (0x318c:16)
	ld w, (0x318d:16)
	bit 0x04,W
	jr z, AccVoiceReg_WritePart5_StoreBit4
	or A,0x80
	and W,0xef
AccVoiceReg_WritePart5_StoreBit4:
	ld (0xfb8a:16), a

	and w, 0x7f

	and (0xfb8b:16), 128

	or (0xfb8b:16), w

	ld a, (12687:16)

	sla a, 6

	and a, 0x40

	and (0xfb8e:16), 191

	or (0xfb8e:16), a

	ld l, 0x10:opc

	; calr AccVoiceState_DispatchChange (v7 displacement)
	calr	AccVoiceState_DispatchChange
AccVoiceReg_WritePart5_Ret:
	ret

AccVoiceReg_WritePart2:
	cp (0x8c98:16), 0x11
	jr nz, AccVoiceReg_WritePart2_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, AccVoiceReg_WritePart2_Ret
	ld a, (0x317d:16)
	ld w, (0x317e:16)
	bit 0x04,W
	jr z, AccVoiceReg_WritePart2_StoreBit4
	or A,0x80
	and W,0xef
AccVoiceReg_WritePart2_StoreBit4:
	ld (0xfba4:16), a

	and w, 0x7f

	and (0xfba5:16), 128

	or (0xfba5:16), w

	ld a, (12672:16)

	sla a, 6

	and a, 0x40

	and (0xfba8:16), 191

	or (0xfba8:16), a

	ld l, 0x2:opc

	calr	AccVoiceState_DispatchChange



AccVoiceReg_WritePart2_Ret:
	ret

AccVoiceReg_WritePart1:
	cp (0x8c98:16), 0x11
	jr nz, AccVoiceReg_WritePart1_Ret
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, AccVoiceReg_WritePart1_Ret
	ld a, (0x3178:16)
	or A,0xf0
	ld w, (0x3179:16)
	and W,0x7f
	ld (0xfbbe:16), a
	and (0xfbbf:16), 0x80
	or (0xfbbf:16), w
	ld L, 0x01:opc
	calr AccVoiceState_DispatchChange
AccVoiceReg_WritePart1_Ret:
	ret

AccVoiceState_Snapshot:
	calr AccHelper_ComputeVoiceOffset
	ld XIY,XHL
	add XIY,0x001e7810
	ld a, (0xfbbe:16)
	ld w, (0xfbbf:16)
	and W,0x7f
	ld (0x32f9:16), wa
	and A,0x0f
	ld	(xiy+0:8), a
	and	(xiy+1), 128
	or	(xiy+1), w
	ld	a, (0xfba4:16)
	ld	w, (0xfba5:16)
	and	w, 127
	ld	l, (0xfba8:16)
	and	l, 64
	sla	l, 1
	or	w, l
	ld	(0x32fb:16), wa
	ld	(xiy+2), a
	and	(xiy+3), 0
	or	(xiy+3), w
	ld	a, (0xfb56:16)
	ld	w, (0xfb57:16)
	and	w, 127
	ld	l, (0xfb5a:16)
	and	l, 64
	sla	l, 1
	or	w, l
	ld	(0x32fd:16), wa
	ld	(xiy+4), a
	and	(xiy+5), 0
	or	(xiy+5), w
	ld	a, (0xfb70:16)
	ld	w, (0xfb71:16)
	and	w, 127
	ld	l, (0xfb74:16)
	and	l, 64
	sla	l, 1
	or	w, l
	ld	(0x32ff:16), wa
	ld	(xiy+6), a
	and	(xiy+7), 0
	or	(xiy+7), w
	ld	a, (0xfb8a:16)
	ld	w, (0xfb8b:16)
	and	w, 127
	ld	l, (0xfb8e:16)
	and	l, 64
	sla	l, 1
	or	w, l
	ld	(0x3301:16), wa
	ld	(xiy+8), a
	and	(xiy+9), 0
	or	(xiy+9), w
	or	(0x32f7:16), 1
	ret
AccVoiceState_DispatchChange:
	push XIY
	ld XWA,AccStyle_IndexedLookup_Data
	ld	e, (xwa+l)
	extz HL
	sla hl, 2
	ld XWA,AccVoiceState_DispatchChange_Data
	ld	xwa, (xwa+hl)
	ld XIY,AccVoiceState_PartLookupTable
	ld	xiy, (xiy+hl)
	ld (0x905b:16), e
	ld8_src_rid8 xiy, 0x00, l
	and L,0xff
	ld H,(XIY+0x01)
	and H,0x7f
	pushw de
	push XWA
	push XIY
	call PartCtrl_WriteProgramChange
	pop XIY
	pop XWA
	popw de
	.byte 0xf3, 0x03, 0xe0, 0xec, 0x46, 0x8d, 0x01, 0x21
	.byte 0xc9, 0xcc, 0x7f, 0x20, 0x7f, 0x24, 0x01, 0x28
	.byte 0x2a, 0x3b, 0x1d, 0x20, 0xac, 0xfd, 0x5b, 0x4a
	.byte 0x48, 0x8d, 0x00, 0x21, 0xc9, 0xcc, 0xff, 0x20
	.byte 0xff, 0x24, 0x00, 0x28, 0x2a, 0x3b, 0x1d, 0x20
	.byte 0xac, 0xfd, 0x5b, 0x4a, 0x48, 0x5d, 0x0e
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
	and W,0x7f
	cp	(0x32f9:16), wa
	jr	z, AccVoiceDelta_Part1_Store
	and	a, 15
	ld	(xiy+0:8), a
	and	(xiy+1), 128
	or	(xiy+1), w
	or	a, 240
	or	(0x32f7:16), 1
AccVoiceDelta_Part1_Store:
	ld	(13049:16), wa
	ret
AccVoiceDelta_Part2:
	ld a, (0xfba4:16)
	ld w, (0xfba5:16)
	and W,0x7f
	ld l, (0xfba8:16)
	and L,0x40
	sla L, 0x01
	or W,L
	cp	(0x32fb:16), wa
	jr	z, AccVoiceDelta_Part2_Store
	ld	(xiy+2), a
	and	(xiy+3), 0
	or	(xiy+3), w
	or	(0x32f7:16), 1
AccVoiceDelta_Part2_Store:
	ld	(13051:16), wa
	ret
AccVoiceDelta_Part3:
	ld a, (0xfb56:16)
	ld w, (0xfb57:16)
	and W,0x7f
	ld l, (0xfb5a:16)
	and L,0x40
	sla L, 0x01
	or W,L
	cp	(0x32fd:16), wa
	jr	z, AccVoiceDelta_Part3_Store
	ld	(xiy+4), a
	and	(xiy+5), 0
	or	(xiy+5), w
	or	(0x32f7:16), 1
AccVoiceDelta_Part3_Store:
	ld	(13053:16), wa
	ret
AccVoiceDelta_Part4:
	ld a, (0xfb70:16)
	ld w, (0xfb71:16)
	and W,0x7f
	ld l, (0xfb74:16)
	and L,0x40
	sla L, 0x01
	or W,L
	cp	(0x32ff:16), wa
	jr	z, AccVoiceDelta_Part4_Store
	ld	(xiy+6), a
	and	(xiy+7), 0
	or	(xiy+7), w
	or	(0x32f7:16), 1
AccVoiceDelta_Part4_Store:
	ld	(13055:16), wa
	ret
AccVoiceDelta_Part5:
	ld a, (0xfb8a:16)
	ld w, (0xfb8b:16)
	and W,0x7f
	ld l, (0xfb8e:16)
	and L,0x40
	sla L, 0x01
	or W,L
	cp	(0x3301:16), wa
	jr	z, AccVoiceDelta_Part5_Store
	ld	(xiy+8), a
	and	(xiy+9), 0
	or	(xiy+9), w
	or	(0x32f7:16), 1
AccVoiceDelta_Part5_Store:
	ld	(13057:16), wa
	ret
AccStyle_InitVRAM:
	xor a, a
	ld xiy, AccStyle_RamImage_1E7800
	ld xix, 0x1e7800
	ldw bc, 0x7e0
	ldir85
	ret

AccStyle_SC0ByteSelect:
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c973
	ld (0xe318:16), 0x10
.Lc_f5c973:
	ld (0x32f2:16), 0x01
	ret
AccStyle_SC0ByteSelect_Join:
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c98c
	ld (0xe318:16), 0x10
.Lc_f5c98c:
	ld (0x32f2:16), 0x10
	ret
AccStyle_SC0ByteSelect_Join2:
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c9a5
	ld (0xe318:16), 0x10
.Lc_f5c9a5:
	ld (0x32f2:16), 0x08
	ret
AccStyle_SC0ByteSelect_Join3:
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c9be
	ld (0xe318:16), 0x10
.Lc_f5c9be:
	ld (0x32f2:16), 0x04
	ret
AccStyle_SC0ByteSelect_Join4:
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c9d7
	ld (0xe318:16), 0x10
.Lc_f5c9d7:
	ld (0x32f2:16), 0x02
	ret
AccHelper_ComputeVoiceOffset:
	xor	xwa, xwa
	ld	l, (64602:16)
	ld	h, (64603:16)
	and	h, 7
	ld	(36955:16), 72
	call	PartCtrl_WriteProgramChange
	xor	xwa, xwa
	xor	xwa, xwa
	ld	a, h
	ld	h, l
	xor	l, l
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
	xor XBC,XBC
	calr AccDemo_LoadRhythm
	calr AccDemo_LoadVariation
	calr AccDemo_LoadFillIn
	calr AccDemo_LoadVariationData
	calr Demo_LoadVariationC_Data
	ldw (0x3438:16), 0x00be
	and (0x3257:16), 0xfe
	bit 7, (0x3435:16)
	jr nz, .Lc_f5ca46
	call AccWidget_DispatchTable
AccDemo_Init_ConfigTimers:
.Lc_f5ca46:
	and (0x3435:16), 0x7f
	ld (0x391a:16), 0x00
	ld (0x391b:16), 0x0a

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
	ld a, 0x0:opc
	ld xix, 0x94800
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
	ld xiy, Demo_StyleRhythmData_0x57C
	ldw bc, 0x10
	ldir85
	add a, 0x1
	cp a, 0x1e
	jr lt, AccDemo_LoadVariation_EntryLoop
	ret

AccDemo_LoadVariation_DataBlock:
	ld	xiy, AccDemo_LoadVariation_DataBlock_Data
	ld	xix, 0x094800
	add	xix, 2976
	ldw	bc, 160
	ldir85
	ret
	ld	xwa, 0:i3
	ld	xix, 0x094800
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
	ld xix, 0x94800
	add xix, 0x13c0
	ld xiy, AccDemo_LoadFillIn_Data
	ldir85
	ret

AccDemo_LoadVariationData:
	ld xix, 0x94800
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
	ld xix, 0x94800
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
; this is the style image the AccDemo_* loaders build in that RAM area.  The
; interior offsets are the Demo_StyleRhythmData_0x* symbols in
; shared/positional_labels.s.
; 30 section names: AccDemo_LoadVariation's loop bound is `cp a, 0x1e`, and the
; order (A/B/C variation 1-4, then intro/fill-in/ending 1-2 per variation) is the
; order of the 30 seven-byte section-name cells in AccScreen_UIDataBlock.
; readers in v7 (address from the linked ELF): AccDemo_LoadRhythm 0xF5CA76,
;     AccDemo_LoadVariation 0xF5CA8C, AccDemo_LoadVariation_DataBlock 0xF5CAEF,
;     AccDemo_LoadFillIn 0xF5CB64, Demo_LoadVariationData 0xF5CB87,
;     Demo_LoadVariationC_Data 0xF5CBAA
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
;                 at +0x57C (Demo_StyleRhythmData_0x57C) into every section record.
Demo_LoadVariationData_Inner_Data_2:
	.byte 0x00, 0xff, 0xff, 0xff, 0xff, 0x87
	.zero 249
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
	ld	a, (12899:16)
	cp	a, 1:i3
	jr	z, AccTone_DirectAddr_Mode1
	cp	a, 2:i3
	jr	z, AccTone_DirectAddr_Mode2
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
	res	0, (0x3383:16)
	cp	(0x327b:16), 0
	scc	z, bc
	cp	(0x327a:16), 0
	scc	z, de
	and	de, bc
	cp	(0x327c:16), 0
	scc	z, bc
	and	bc, de
	cp	(0x3276:16), 0
	scc	z, de
	and	de, bc
	cp	(0x3277:16), 0
	scc	z, bc
	and	bc, de
	cp	(0x3278:16), 0
	scc	z, de
	and	de, bc
	cp	(0x3279:16), 0
	scc	z, wa
	and	wa, de
	ret	z
	cp	(0x3249:16), 240
	ret	c
	ld	a, (0x31e4:16)
	cp	a, (0x3389:16)
	jr	z, AccTone_ExtendAndDispatch_Skip
	res	0, (0x3382:16)
AccTone_ExtendAndDispatch_Skip:
	bit	0, (0x3382:16)
	ret	nz
	calr	AccTone_ExtendAndDispatch_Helper
	ld	a, (0x3385:16)
	cp	a, (0x338e:16)
	jr	z, AccTone_ExtendAndDispatch_Skip2
	set	0, (0x3383:16)
	set	0, (0x3382:16)
AccTone_ExtendAndDispatch_Skip2:
	ldmm8	13189, 13198
	ldmm8	13188, 13199
	ret
AccTone_ExtendAndDispatch_Helper:
	ld	a, (0x323c:16)
	extz	wa
	lda	xbc, (AccTuning_ReadAndApplyOffset_Table:24)
	ld	a, (xbc+wa)
	ld	(0x338f:16), a
	ld	xbc, (0x3232:16)
	extz	wa
	ld	a, (xbc+wa)
	ld	(0x338e:16), a
	cp	a, 255
	ret	nz
	ld	(13198), (xbc)
	ld	(0x338f:16), 0
	ret
	bit	0, (0x3383:16)
	ret	z
	call	Rhythm_SendChanPressure_Wrap
	call	AccBuf_ResetAll4_Wrap
	ld	a, (0x3385:16)
	extz	wa
	sla	wa, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xbc, 608352
	add	xbc, (xde+wa)
	ld	(0x338a:16), xbc
	ld	xwa, xbc
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x3290:16), 63
	set	7, (0x3290:16)
	calr	AccTone_ExtendAndDispatch_Helper2
	ldmm8	12867, 12860
	ldmm8	12868, 12861
	ldmm8	12869, 12862
	res	0, (0x3383:16)
	ret
AccTone_ExtendAndDispatch_Helper2:
	calr	AccVoice_BarCounterBytecodeData
	and	(0x320f:16), 240
	and	(0x3210:16), 240
	and	(0x3211:16), 240
	and	(0x3212:16), 240
	and	(0x3213:16), 240
	and	(0x3214:16), 240
	call	AccSeq_DualPartScan_Wrap
	bit	6, (0x3258:16)
	ret	nz
	call	AccSeq_FourChannelScan_Wrap
	ret
AccVoice_BarCounterBytecodeData_Helper:
	extz DE
	sla de, 2
	extz BC
	sla bc, 5
	ld HL,BC
	add HL,DE
	ld W, 0x00:opc
	extz XWA
	ld XBC,XWA
	sll xbc, 2
	add XBC,XWA
	sll xbc, 5
	add XBC,0x00095440
	ld	hl, (xbc+hl)
	ret
AccVoice_BarCounterBytecodeData_Helper2:
	extz DE
	sla de, 2
	extz BC
	sla bc, 5
	ld HL,BC
	add HL,DE
	ld W, 0x00:opc
	extz XWA
	ld XBC,XWA
	sll xbc, 2
	add XBC,XWA
	sll xbc, 5
	add XBC,0x00095440
	lda	xwa, (xbc+hl)
	ld HL,(XWA+0x02)
	ret
	.incbin "includes/romslices/v7_transplant_AccTone_InlineBytecodeData_head_mid1.bin"
AccVoice_BarCounterBytecodeData_Helper3:
	res 1, (0x3263:16)
	res 3, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper4:
	res 0, (0x3263:16)
	res 2, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper5:
	res 2, (0x3263:16)
	res 2, (0xfc60:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 6:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper6:
	res 0, (0x3261:16)
	res 4, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper7:
	res 1, (0x3261:16)
	res 5, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper8:
	res 0, (0x325f:16)
	res 6, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccVoice_BarCounterBytecodeData_Helper9:
	res 1, (0x325f:16)
	res 7, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ret
AccTone_ValidateAndClamp_Helper:
	cp	a, 2:i3
	jr	nz, AccTone_ValidateAndClamp_Helper_Skip
	ldw	(0x333a:16), 65534
	jr	AccTone_ValidateAndClamp_Helper_Join
AccTone_ValidateAndClamp_Helper_Skip:
	extz	wa
	lda	xbc, (AccTone_InlineBytecodeData_Data:24)
	ld	a, (xbc+wa)
	ld	xbc, (0x338a:16)
	extz	wa
	add	wa, wa
	ldw	(13114), (xbc+wa)
AccTone_ValidateAndClamp_Helper_Join:
	ldw	(0x333c:16), 6
	ret
AccTone_ValidateAndClamp_Helper2:
	ld xix, (0x338a:16)
	ld C,A
	extz BC
	lda xde, (AccTone_InlineBytecodeData_Data_2:24)
	ld	e, (xde+bc)
	extz DE
	ld BC,DE
	muls BC,0x0007
	lda xhl, (0x31aa:16)
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
	or	(0x3290:16), a
	ret
AccVoice_ClearChannelStates:
	ld	(13135:16), 0
	ld	(13136:16), 0
	ld	(13137:16), 0
	ld	(13138:16), 0
	ld	(13139:16), 0
	ld	(13140:16), 0
	ret
AccVoice_IncrementBarCounter:
	ld a, (0x334e:16)
	inc 1,A
	ld (0x334e:16), a
	ld	xbc, (0x338a:16)
	cp	a, (xbc+13)
	ret	ule
	ld	(0x334e:16), 0
	ret
AccVoice_BarCounterBytecodeData:
	ld	(0x3344:16), 0
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x334f:16)
	extz	de
	ld	bc, 0:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(0x31fb:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip
	set	0, (0x3344:16)
AccVoice_BarCounterBytecodeData_Skip:
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x334f:16)
	extz	de
	ld	bc, 0:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(0x31eb:16), hl
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3351:16)
	extz	de
	ld	bc, 1:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(0x31ff:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip2
	set	2, (0x3344:16)
AccVoice_BarCounterBytecodeData_Skip2:
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3351:16)
	extz	de
	ld	bc, 1:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(0x31ef:16), hl
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3352:16)
	extz	de
	ld	bc, 2:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(0x3201:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip3
	set	3, (0x3344:16)
AccVoice_BarCounterBytecodeData_Skip3:
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3352:16)
	extz	de
	ld	bc, 2:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(0x31f1:16), hl
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3353:16)
	extz	de
	ld	bc, 3:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(0x3203:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip4
	set	4, (0x3344:16)
AccVoice_BarCounterBytecodeData_Skip4:
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3353:16)
	extz	de
	ld	bc, 3:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(0x31f3:16), hl
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3354:16)
	extz	de
	ld	bc, 4:i3
	calr	AccVoice_BarCounterBytecodeData_Helper
	ld	(0x3205:16), hl
	cp	hl, 65534
	jr	nz, AccVoice_BarCounterBytecodeData_Skip5
	set	5, (0x3344:16)
AccVoice_BarCounterBytecodeData_Skip5:
	ld	a, (0x3385:16)
	extz	wa
	ld	e, (0x3354:16)
	extz	de
	ld	bc, 4:i3
	calr	AccVoice_BarCounterBytecodeData_Helper2
	ld	(0x31f5:16), hl
	ldw	(0x31fd:16), 65534
	ldw	(0x31ed:16), 6
	set	1, (0x3344:16)
	ret
AccVoice_IncrementBarWithSave_Helper:
	dec	2, xsp
	push	xiz
	lda	xbc, (RhythmTiming_OffsetTable:24)
	bit	0, (0x32c7:16)
	jr	z, AccVoice_BarCounterBytecodeData_Skip9
	ld	a, (0x326f:16)
	cp	a, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip7
	cp	a, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Skip7
	ld	a, (0x433:16)
	cp	a, (0x32d2:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip6
	ld	a, (0x32d3:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip6:
	calr	AccVoice_BarCounterBytecodeData_Helper7
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
	jrl	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip7:
	ld	a, (0x433:16)
	cp	a, (0x32d0:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip8
	ld	a, (0x32d1:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip8:
	calr	AccVoice_BarCounterBytecodeData_Helper6
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
	jr	AccVoice_BarCounterBytecodeData_Join2
AccVoice_BarCounterBytecodeData_Skip9:
	ld	xde, (0x3356:16)
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
	call	nz, (0xf5e2e7:24)
AccVoice_BarCounterBytecodeData_Skip10:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xwa, xhl
	ld	c, (0x326f:16)
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
	ld	xwa, (0x3356:16)
AccVoice_BarCounterBytecodeData_Join2:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x3290:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccVoice_IncrementBarWithSave_Helper2:
	dec	2, xsp
	push	xiz
	lda	xbc, (RhythmTiming_OffsetTable:24)
	bit	0, (0x32c7:16)
	jr	z, AccVoice_BarCounterBytecodeData_Skip15
	ld	a, (0x326d:16)
	cp	a, 1:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip13
	cp	a, 2:i3
	jr	nz, AccVoice_BarCounterBytecodeData_Skip13
	ld	a, (0x433:16)
	cp	a, (0x32ce:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip12
	ld	a, (0x32cf:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip12:
	calr	AccVoice_BarCounterBytecodeData_Helper9
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
	jrl	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip13:
	ld	a, (0x433:16)
	cp	a, (0x32cc:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip14
	ld	a, (0x32cd:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xbc+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip14:
	calr	AccVoice_BarCounterBytecodeData_Helper8
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
	jr	AccVoice_BarCounterBytecodeData_Join3
AccVoice_BarCounterBytecodeData_Skip15:
	ld	xde, (0x3356:16)
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
	call	nz, (0xf5e2e7:24)
AccVoice_BarCounterBytecodeData_Skip16:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	ld	a, (0x3207:16)
	extz	wa
	call	AccVoice_ComputeParamAddr_Wrap
	ld	bc, hl
	ld	xwa, xiz
	call	AccVoice_LoadAllParts_Wrap
	ld	xwa, (0x3356:16)
AccVoice_BarCounterBytecodeData_Join3:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
	or	(0x3290:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccVoice_IncrementBarWithSave_Helper3:
	dec	2, xsp
	push	xiz
	ld	xwa, (0x3356:16)
	lda	xiy, (RhythmTiming_OffsetTable:24)
	lda	xix, (xwa+17)
	ld	e, (xwa+16)
	lda	xhl, (xsp+4)
	lda	xbc, (xhl+1)
	bit	0, (0x32c7:16)
	jrl	z, AccVoice_BarCounterBytecodeData_Skip23
	ld	a, (0x326e:16)
	cp	a, 1:i3
	jrl	z, AccVoice_BarCounterBytecodeData_Skip21
	cp	a, 4:i3
	jr	z, AccVoice_BarCounterBytecodeData_Skip18
	cp	a, 8
	jrl	nz, AccVoice_BarCounterBytecodeData_Skip21
	ld	a, (0x433:16)
	cp	a, (0x32ca:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip17
	ld	a, (0x32cb:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xiy+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jrl	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip17:
	calr	AccVoice_BarCounterBytecodeData_Helper5
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
	jrl	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip18:
	ld	a, (0x433:16)
	extz	wa
	lda	xiy, (AccStyle_ApplyExt_SkipClamp_Table:24)
	cp	(xiy+wa), 0x01
	jr	nz, AccVoice_BarCounterBytecodeData_Skip19
	calr	AccVoice_BarCounterBytecodeData_Helper3
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
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
	call	nz, (0xf5e2e7:24)
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
	jrl	AccVoice_BarCounterBytecodeData_Join6
AccVoice_BarCounterBytecodeData_Skip21:
	ld	a, (0x433:16)
	cp	a, (0x32c8:16)
	jr	nz, AccVoice_BarCounterBytecodeData_Skip22
	ld	a, (0x32c9:16)
	extz	wa
	sla	wa, 2
	ld	xiz, 608352
	add	xiz, (xiy+wa)
	ld	xwa, xiz
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, xiz
	jr	AccVoice_BarCounterBytecodeData_Join5
AccVoice_BarCounterBytecodeData_Skip22:
	calr	AccVoice_BarCounterBytecodeData_Helper4
	ld	xwa, (0x338a:16)
	call	AccInit_AllPartPositions_Wrap
	ld	xwa, (0x338a:16)
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
	call	nz, (0xf5e2e7:24)
AccVoice_BarCounterBytecodeData_Skip24:
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccTone_LookupByProgram_Dispatch
	ld	xiz, xhl
	ld	a, (0x326e:16)
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
	ld	xwa, (0x3356:16)
AccVoice_BarCounterBytecodeData_Join5:
	call	AccTuning_CopyAllPartsFromStyle_Wrap
AccVoice_BarCounterBytecodeData_Join6:
	or	(0x3290:16), 63
	pop	xiz
	inc	2, xsp
	ret
AccTuning_ReadAndApplyOffset:
	ld a, (0x3387:16)
	extz WA
	lda xbc, (AccTuning_ReadAndApplyOffset_Table:24)
	ld	(13190), (xbc+wa)
	ret
AccTuning_ComplexBytecodeData:
	dec	2, xsp
	push	xiz
	bit	0, (0x32c7:16)
	jrl	z, AccTuning_ComplexBytecodeData_Skip5
	ld	c, (0x33d4:16)
	ld	e, c
	and	e, 128
	ld	l, (0x3338:16)
	cpl	l
	cp	e, 128
	jr	z, AccTuning_ComplexBytecodeData_Skip
	ld	e, (0x325f:16)
	ld	a, e
	and	a, 2
	cp	a, 2:i3
	jr	nz, AccTuning_ComplexBytecodeData_Skip2
AccTuning_ComplexBytecodeData_Skip:
	and	(0x3276:16), l
	ld	a, (0x433:16)
	cp	a, (0x32ce:16)
	jr	nz, AccTuning_ComplexBytecodeData_Loop
	ld	a, (0x3338:16)
	or	(0x3277:16), a
	ld	e, (0x32cf:16)
	jr	AccTuning_ComplexBytecodeData_Loop2
AccTuning_ComplexBytecodeData_Loop:
	ld	e, (0x3385:16)
AccTuning_ComplexBytecodeData_Loop2:
	ld	a, (0x3338:16)
	cp	a, 2:i3
	jr	nz, AccTuning_ComplexBytecodeData_Skip4
	ldw	(0x333a:16), 65534
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
	and	(0x3277:16), l
	ld	a, (0x433:16)
	cp	a, (0x32cc:16)
	jr	nz, AccTuning_ComplexBytecodeData_Loop
	ld	a, (0x3338:16)
	or	(0x3276:16), a
	ld	e, (0x32cd:16)
	jr	AccTuning_ComplexBytecodeData_Loop2
AccTuning_ComplexBytecodeData_Skip4:
	extz	wa
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
	ldw	(13114), (xde+hl)
AccTuning_ComplexBytecodeData_Join:
	ldw	(0x333c:16), 6
	jr	AccTuning_ComplexBytecodeData_Epilogue
AccTuning_ComplexBytecodeData_Skip5:
	ld	xde, (0x3356:16)
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
	call	nz, (0xf5e2e7:24)
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
	call	AccTuning_ComplexBytecodeData_Helper3
	ld	(0x333c:16), hl
AccTuning_ComplexBytecodeData_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
	ld	(0x3344:16), 0
	ld	e, (0x334f:16)
	extz	de
	sla	de, 2
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12795), (xbc+de)
	cpw	(0x31fb:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Skip7
	set	0, (0x3344:16)
AccTuning_ComplexBytecodeData_Skip7:
	ld	e, (0x334f:16)
	extz	de
	sla	de, 2
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12779), (xwa+2)
	ld	a, (0x3351:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 32
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12799), (xbc+de)
	cpw	(0x31ff:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Skip8
	set	2, (0x3344:16)
AccTuning_ComplexBytecodeData_Skip8:
	ld	a, (0x3351:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 32
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12783), (xwa+2)
	ld	a, (0x3352:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 64
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12801), (xbc+de)
	cpw	(0x3201:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Skip9
	set	3, (0x3344:16)
AccTuning_ComplexBytecodeData_Skip9:
	ld	a, (0x3352:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 64
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12785), (xwa+2)
	ld	a, (0x3353:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 96
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12803), (xbc+de)
	cpw	(0x3203:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Skip10
	set	4, (0x3344:16)
AccTuning_ComplexBytecodeData_Skip10:
	ld	a, (0x3353:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 96
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12787), (xwa+2)
	ld	a, (0x3354:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 128
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	ldw	(12805), (xbc+de)
	cpw	(0x3205:16), 65534
	jr	nz, AccTuning_ComplexBytecodeData_Skip11
	set	5, (0x3344:16)
AccTuning_ComplexBytecodeData_Skip11:
	ld	a, (0x3354:16)
	extz	wa
	sla	wa, 2
	ld	de, wa
	add	de, 128
	ld	xwa, 0:i3
	ld	a, (0x3385:16)
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 611392
	lda	xwa, (xbc+de)
	ldw	(12789), (xwa+2)
	ldw	(0x31fd:16), 65534
	ldw	(0x31ed:16), 6
	set	1, (0x3344:16)
	ret
	calr	AccTuning_ComplexBytecodeData_Helper
	ret
AccTuning_ComplexBytecodeData_Helper:
	ret
AccTone_WriteProgramChange:
	push	xiz
	ld	xix, xwa
	ld	l, (xbc)
	ld	h, (xbc+1)
	ld	(36955:16), 72
	push	xix
	call	PartCtrl_WriteProgramChange
	pop	xix
	ld	xbc, xix
	ld	(xbc), l
	ld	(xbc+1), h
	pop	xiz
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
	and	xhl, 65535
	call	AccVoice_LoadTuningBlock
	pop	xiz
	ret
AccVoice_ComputeParamAddr_Wrap:
	push	xiz
	and	xwa, 255
	call	AccVoice_ComputeParamAddr
	and	xhl, 65535
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
	and	xhl, 65535
	call	AccStyle_SetupPartAddressesByHL
	pop	xiz
	ret
AccVoice_LoadAllParts_Wrap:
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
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
	and	xhl, 65535
	pop	xiz
	ret
AccTuning_ComplexBytecodeData_Helper3:
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	AccPart_GetParamAddr
	and	xwa, 65535
	ld	xhl, xwa
	pop	xiz
	ret
	push	xix
	push	xiy
	push	xiz
	push	xwa
	push	xbc
	push	xde
	push	xhl
	xor	xwa, xwa
	ld	a, (13112:16)
	call	AccTone_ValidateAndClamp_Helper
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
	xor	xwa, xwa
	ld	a, (13112:16)
	call	AccTone_ValidateAndClamp_Helper2
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	pop	xiz
	pop	xiy
	pop	xix
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
	.byte 0x1d, 0xc1, 0xd4, 0xf5, 0x0e, 0x1d, 0x65, 0xd7
	.byte 0xf5, 0x0e, 0x1d, 0x4c, 0xd7, 0xf5, 0x0e, 0x1d
	.byte 0x49, 0xd6, 0xf5, 0x0e, 0x1d, 0x73, 0xd5, 0xf5
	.byte 0x0e, 0x3e, 0x1d, 0x7d, 0x5e, 0xf5, 0x5e, 0x0e
	.byte 0x14, 0xe5, 0xf5, 0x00, 0x13, 0xe5, 0xf5, 0x00
	.byte 0x2d, 0xe5, 0xf5, 0x00, 0x1d, 0xe5, 0xf5, 0x00
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
	calr	AccPatch_CheckAndInitDemo
	calr	AccPatch_CountAvailableSlots
	call	VoiceSlot_Dispatch_Type81
	ld	(14619:16), 10
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
	or	(0x3431:16), 128
	pop	xiz
	ret
AccDemo_InitWithFlag:
	push xiz

	; ordi8 0x34d1, 128 (v7 patched)
	or	(0x3435:16), 128
	; call AccDemo_Init_Wrap (v7 addr)
	call	AccDemo_Init_Wrap
	pop xiz

	ret



AccPatch_MultiCallWrapper:
	push	xiz
	calr	AccDemo_InitWithFlag_Helper
	calr	AccPatch_ClearModeFlag
	pop	xiz
	ret
AccPatch_MultiCallWrapper_0x9:
	push	xiz
	calr	AccPatch_ClearModeFlag
	call	AccPatch_InitSlotChain_WithAddr
	pop	xiz
	ret
AccStyle_TableDataEntry_Helper:
	push	xiz
	calr	AccPatch_ClearModeFlag
	pop	xiz
	ret

AccPatch_ClearModeFlag:
	ld	(13625:16), 0
	ret
Not_sure_maybe_SOFT_VERSION_related:
	.incbin "includes/romslices/v7_transplant_Not_sure_maybe_SOFT_VERSION_related.bin"
AccPatch_CheckAndInitDemo:
	ld xiy, 0x94800
	add xiy, 0xe
	ld wa, (xiy)
	cp wa, 0:i3
	jr z, AccPatch_CheckAndInitDemo_Ret
	call AccDemo_Init_Wrap

AccPatch_CheckAndInitDemo_Ret:
	ret

AccPatch_SlotConfigByteData:
	; framing ported from v10's source for the same label (same span length, statement for statement); 36 of 58 slots byte-identical
	ret
	ret
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xff	; v10 does not spell this byte either
	.byte 0x36	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x3a	; v10 does not spell this byte either
	ldw	ix, 61700
	; v10 does not spell this byte either
	push	xde
	ldw	ix, 0
AccPatch_CheckAndInitDemo_Entry:
	; v10 does not spell this byte either
	cp	(0x343a:16), 12
	; v10 does not spell this byte either
	jr	z, AccPatch_CheckAndInitDemo_Entry2
	ld	(14079:16), 16
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(14079:16), 8
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(14079:16), 1
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(14079:16), 2
	calr	AccPatch_CheckAndInitDemo_Helper
	ld	(14079:16), 4
	calr	AccPatch_CheckAndInitDemo_Helper
	inc	1, (13370:16)
	jr	AccPatch_CheckAndInitDemo_Entry
AccPatch_CheckAndInitDemo_Entry2:
	; v10 does not spell this byte either
	pop	(0x343a:16)
	; v10 does not spell this byte either
	pop	(0x36ff:16)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ret
AccPatch_CheckAndInitDemo_Helper:
	; v10 does not spell this byte either
	cp	(0x343a:16), 12
	; v10 does not spell this byte either
	jr	nc, AccPatch_CheckAndInitDemo_Return
	calr	AccPatch_InitCurrentSlotPointer
	calr	AccPatch_SlotScanByteData
	calr	AccPatch_SlotScanByteData_0x38
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
	ld a, (0x36ff:16)
	calr MapBitFlagsToChannelOffset

	ld	hl, (xiy+w)

	ld (13686:16), hl

	ldw (13688:16), 6

	ret
AccPatch_SlotScanByteData:
	ld	c, 0:opc
AccPatch_SlotScanByteData_Join:
	cp	c, 8
	jr	z, AccPatch_SlotScanByteData_Return
	push	c
	calr	AccPatch_CheckAndInitDemo_Helper4
	pop c
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
	bit	0, (0x357a:16)
	jr	nz, AccPatch_SlotScanByteData_Skip
	jr	AccPatch_SlotScanByteData_Helper
AccPatch_SlotScanByteData_Skip:
	push_a
	call	AccPatch_AdvanceSeqIndex
	pop_a
	jr	AccPatch_SlotScanByteData_Return2
AccPatch_SlotScanByteData_Return2:
	ret
AccPatch_SlotScanByteData_0x38:
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
	pop c
	inc	1, c
	jr	AccPatch_SlotScanByteData_Join2
AccPatch_SlotScanByteData_Return3:
	ret
AccPatch_CheckAndInitDemo_Helper4:
	push	c
	ld	xwa, 0:i3
	ld	a, 160:opc
	ld	c, (13370:16)
	mul	wa, c
	ld	xbc, 0:i3
	ld	c, (14079:16)
	and	c, 31
	srl	c, 1
	add	xbc, AccPatch_SlotScanByteData_Code
	ld	xde, 0:i3
	ld	e, (xbc)
	mul	de, 32
	add	xwa, xde
	add	xwa, 3136
	add	xwa, 608256
	ld	xix, xwa
	pop c
	sll	c, 2
	ld	wa, (13686:16)
	ld	(xix+c), wa
	ld	wa, (13688:16)
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
	cp (0x8c9a:16), 0xb2
	jr z, .Lc_f5e896
	jr t, RhythmProc_StyleChange_Ret
RhythmProc_StyleChange_Init:
.Lc_f5e896:
	bit 2, (0x3431:16)
	jr z, RhythmProc_StyleChange_Ret
	and (0x3431:16), 0xfb
	calr AccPatch_InitCurrentSlot
	calr AccPatch_UpdateAllChains
	call RhythmPatInit_LoadParams
RhythmProc_StyleChange_Ret:
	ret

RhythmProc_CheckPlayMode:
	cp (0x8c9a:16), 0xb5
	jr z, .Lc_f5e8c0
	ld a, (0x3433:16)
	and A,0xf3
	ld (0x3433:16), a
	jr t, AccPatch_CopySlotsExit
RhythmProc_PlayMode_Compare:
.Lc_f5e8c0:
	cp (0x3489:16), 0xb5
	jr z, .Lc_f5e8d7
	ld (0x3562:16), 0x00
	ld a, (0x3217:16)
	and A,0x07
	ld (0x3440:16), a
RhythmProc_PlayMode_SendTempo:
.Lc_f5e8d7:
	bit 1, (0x3433:16)
	jr z, .Lc_f5e90d
	and (0x3433:16), 0xfd
	ld a, (0x3433:16)
	and A,0x0c
	cp a, 0:i3
	jr nz, .Lc_f5e90d
	ld a, (0x3560:16)
	and A,0x0c
	cp a, 0:i3
	jr nz, .Lc_f5e90d
	calr AccPatch_RebuildChannelSlot
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call SoundCtrl_SendTempoScaled
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
AccPatch_DetectModeChange:
.Lc_f5e90d:
	call AccPatch_SeqDispatch_Entry
	ld a, (0x3217:16)
	and A,0x07
	cp	a, (13376:16)
	jr	z, AccPatch_CopySlotsExit
	ld	(13376:16), a
	cp	(35996:16), 181
	jr	nz, AccPatch_CopySlotsExit
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	SoundCtrl_SendAccTempo
	call	SoundCtrl_SendTempoScaled
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
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
	calr	AccPatch_GetCurrentSlotAddr

	ld xbc, 0x40

	add xiy, xbc

	ld xix, 13344

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
	ld (8:8), 8:io
	ld (0:8), 0:io
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
	ld	xhl, 0:i3
	ld	l, (13370:16)
	cp	l, 30
	jr	c, AccPatch_GetSlotAddr_Valid
	ld	l, 0:opc
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
	ld	l, (13370:16)
	cp	l, 30
	jr	c, AccPatch_GetSlotAddr_Preserve_Skip
	xor	l, l
AccPatch_GetSlotAddr_Preserve_Skip:
	mul	hl, 96
	add	xhl, 96
	ld	xiy, 608256
	add	xiy, xhl
	pop	xix
	pop	xwa
	ret
AccPatch_GetEntryAddr:
	cp hl, 0xffff
	jr z, AccPatch_GetEntryAddr_Ret
	pushw hl
	pushw hl
	ld xhl, 0:i3
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
	or (0x3431:16), 0x80
	calr AccPatch_ScanToSequenceStart

	ret



AccPatch_InitFromSlotIndex:
	push xiz
	calr AccPatch_InitFromIndex
	pop xiz
	ret

AccPatch_InitFromIndex:
	xor	xhl, xhl
	ld	l, (14608:16)
	cp	l, 30
	jr	c, AccPatch_InitFromIndex_Valid
	xor	l, l
AccPatch_InitFromIndex_Valid:
	mul hl, 0x60

	add xhl, 0x60

	ld xiy, (14610:16)

	add xiy, xhl

	; calr AccPatch_FreeAllChains_Alt (v7 displacement)
	calr	AccPatch_FreeAllChains_Alt
	; calr AccPatch_CopyDefaultsToSlot (v7 displacement)
	calr	AccPatch_CopyDefaultsToSlot
	; calr AccPatch_FillAllSlots_Alt (v7 displacement)
	calr	AccPatch_FillAllSlots_Alt
	; ordi8 0x34cd, 128 (v7 patched)
	or	(0x3431:16), 128
	; calr AccPatch_ScanSequenceToEnd (v7 displacement)
	calr	AccPatch_ScanSequenceToEnd
	ret



AccPatch_InitByteStub:
	push	xiz
	calr	AccPat_InitWorkAreaFromSlot
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	push	xwa
	ld	a, (13370:16)
	ld	(14608:16), a
	ld	xwa, 608256
	ld	(14610:16), xwa
	pop	xwa
	calr	AccPatch_InitFromIndex
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
	push	xwa
	ld	a, 0:opc
	ld	w, (14608:16)
	cp	w, 14
	jr	nz, AccPatch_ClearSlot13_Check0F
	ld	(xiy+13), a
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
	or	(0x3431:16), 128
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
	ld	hl, wa
	ldw	(xix+3), 65535
	calr	AccPatch_GetEntryAddr
	ldw	(xix+1), 65535
	and	(xix), 127
	incw	1, (0x3438:16)
	ld	wa, (xix+3)
	cp	wa, 65535
	jr	z, AccPatch_FreeChain_Done
	jr	AccPatch_FreeChainLoop
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
	ld A, 0x00:opc
	cp (0x343a:16), 0x0e
	jr nz, .Lc_f5ec03
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_Idx0F:
.Lc_f5ec03:
	cp (0x343a:16), 0x0f
	jr nz, .Lc_f5ec0d
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_Idx14:
.Lc_f5ec0d:
	cp (0x343a:16), 0x14
	jr nz, .Lc_f5ec17
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_Idx15:
.Lc_f5ec17:
	cp (0x343a:16), 0x15
	jr nz, .Lc_f5ec21
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_Idx1A:
.Lc_f5ec21:
	cp (0x343a:16), 0x1a
	jr nz, .Lc_f5ec2b
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_Idx1B:
.Lc_f5ec2b:
	cp (0x343a:16), 0x1b
	jr nz, AccPatch_ClearSlot13_IdxDone
	ld (XIY+0x0d),A
AccPatch_ClearSlot13_IdxDone:
	ret

AccPatch_SetVoiceAndInit:
	calr AccPatch_GetCurrentSlotAddr

	ld a, (13372:16)

	ld (xiy + 12), a

	push xiy

	calr AccPatch_InitAllSentinels

	pop xiy

	ld xhl, 0:i3

	ld l, (13372:16)

	sll l, 1

	xor h, h

	; add xhl, AccPatch_VoiceStrideTable (v7 patched)
	add	xhl, AccPatch_VoiceStrideTable
	ld wa, (xhl)

	ld (xiy + 16), wa

	; calr AccPatch_CheckConfigType (v7 displacement)
	calr	AccPatch_CheckConfigType
	; ordi8 0x34cd, 128 (v7 patched)
	or	(0x3431:16), 128
	ret



AccPatch_VoiceStrideTable:
	.byte 0x00, 0x00, 0x58, 0x02, 0x08, 0x02, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03

AccPatch_CheckConfigType:
	cp	(13373:16), 6
	jr	z, RhythmConfig_CheckAndSkip
	cp	(13373:16), 8
	jr	z, RhythmConfig_CheckAndSkip
	cp	(13373:16), 4
	jr	z, RhythmConfig_CheckAndSkip
	cp	(13373:16), 3
	jr	z, RhythmConfig_CheckAndSkip
	jr	AccPatch_CheckConfig_Done
RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	calr	AccPatch_ReadVoiceStride

	ld xwa, 0:i3

	ld a, (13373:16)

	ld b, (13371:16)

	and b, 0x7

	inc 1, b

	mul wa, b

	ld c, a

	ld hl, (xiy + 0:8)

	calr	AccPatch_InitSlotSentinels

	ld hl, (xiy + 4)

	calr	AccPatch_InitSlotSentinels

	ld hl, (xiy + 6)

	calr	AccPatch_InitSlotSentinels

	ld hl, (xiy + 8)

	calr	AccPatch_InitSlotSentinels

	ld hl, (xiy + 10)

	calr	AccPatch_InitSlotSentinels

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
	ld	xhl, 0:i3
	ld	l, (13372:16)
	ld	xbc, AccTone_LookupByProgram_Table
	add	xbc, xhl
	ld	a, (xbc)
	ld	(13373:16), a
	ret
RhythmProc_CheckRhythmEdit:
	cp (0x8c9a:16), 0xb4
	jr nz, RhythmProc_RhythmEdit_Ret
	calr RhythmProc_CheckVoiceChange
	calr RhythmProc_CheckConfigBits
RhythmProc_RhythmEdit_Ret:
	ret

RhythmProc_CheckVoiceChange:
	bit 1, (0x3432:16)
	jr z, .Lc_f5ed34
	and (0x3432:16), 0xfd
	calr AccPatch_SetVoiceAndInit
RhythmProc_CheckVoiceUpdate:
.Lc_f5ed34:
	bit 0, (0x3432:16)
	jr z, RhythmProc_VoiceUpdate_Ret
	and (0x3432:16), 0xfe
	calr RhythmProc_UpdateVoiceSentinels
RhythmProc_VoiceUpdate_Ret:
	ret

RhythmProc_UpdateVoiceSentinels:
	calr	AccPatch_GetCurrentSlotAddr
	ld	a, (13371:16)
	and	a, 7
	ld	(xiy+13), a
	calr	AccPatch_InitAllSentinels
	ret
RhythmProc_CheckConfigBits:
	bit	0, (0x3436:16)
	jr	z, RhythmProc_ConfigBit1
	and	(0x3436:16), 254
	calr	AccPatch_GetCurrentSlotAddr
	and	(xiy+14), 240
	ld	a, (0x344d:16)
	and	a, 15
	or	(xiy+14), a
RhythmProc_ConfigBit1:
	bit	1, (0x3436:16)
	jr	z, RhythmProc_ConfigBit2
	and	(0x3436:16), 253
	calr	AccPatch_GetCurrentSlotAddr
	and	(xiy+14), 239
	bit	4, (0x344e:16)
	jr	z, RhythmProc_ConfigBit2
	or	(xiy+14), 16
RhythmProc_ConfigBit2:
	bit	2, (0x3436:16)
	jr	z, RhythmProc_ConfigBits_Done
	and	(0x3436:16), 251
	calr	AccPatch_GetCurrentSlotAddr
	and	(xiy+14), 159
	bit	5, (0x344e:16)
	jr	z, RhythmProc_ConfigBit2_SetBit6
	or	(xiy+14), 32
RhythmProc_ConfigBit2_SetBit6:
	bit	6, (0x344e:16)
	jr	z, RhythmProc_ConfigBits_Done
	or	(xiy+14), 64
RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	ld a, (0x36ff:16)
	and A,0x1f
	cp a, 0:i3
	jr z, AccPatch_RebuildChannel_Done
	calr MapBitFlagsToChannelOffset
	ld (0x3392:16), w
	ld C,W
	push C
	calr AccPatch_GetCurrentSlotAddr
	pop C
	ld	hl, (xiy+c)
	ld	(0x33a1:16), hl
	calr	AccPatch_FreeChainEntries
	ld	xhl, 0:i3
	ld	l, (0x343c:16)
	add	xhl, AccTone_LookupByProgram_Table
	ld	a, (xhl)
	ld	xhl, 0:i3
	ld	l, (0x343b:16)
	and	l, 7
	inc	1, l
	mul	hl, a
	and	hl, 127
	ld	c, l
	ld	hl, (0x33a1:16)
	calr	AccPatch_InitSlotSentinels
	calr	AccPatch_ComputeSeqPosition
	ld	(0x3562:16), 0
	calr	AccPatch_WriteRhythmInit
	bit	0, (0x31e7:16)
	jr	nz, AccPatch_RebuildChannel_Done
	or	(0x3431:16), 128
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
	ld	xwa, 0:i3
	ld	a, (12823:16)
	ld	c, (13373:16)
	mul	wa, c
	add	a, (12772:16)
	ld	l, a
	ld	a, (12771:16)
	add	a, 24
	cp	a, 96
	jr	lt, AccPatch_SeqPosition_Store
	inc	1, l
	ld	xwa, 0:i3
	ld	a, (13373:16)
	ld	c, (13371:16)
	inc	1, c
	mul	wa, c
	cp	a, l
	jr	nz, AccPatch_SeqPosition_Store
	ld	l, 0:opc
AccPatch_SeqPosition_Store:
	ld	xbc, 0:i3
	ld	c, l
	ld	hl, (13217:16)
	ld	wa, 6:i3
	add	wa, bc
	ld	xhl, 0:i3
	ld	l, (13202:16)
	sll	l, 1
	add	xhl, AccPatch_SeqBaseAddrTable
	ld	xhl, (xhl)
	ld	(xhl), wa
	ld	xhl, 0:i3
	ld	l, (13202:16)
	sll	l, 1
	add	xhl, AccPatch_SeqPosition_Store_Data
	ld	xhl, (xhl)
	ld	wa, (13217:16)
	ld	(xhl), wa
	ret
AccPatch_SeqBaseAddrTable:
	.byte 0xeb, 0x31, 0x00, 0x00, 0xed, 0x31, 0x00, 0x00
	.byte 0xef, 0x31, 0x00, 0x00, 0xf1, 0x31, 0x00, 0x00
	.byte 0xf3, 0x31, 0x00, 0x00, 0xf5, 0x31, 0x00, 0x00
AccPatch_SeqPosition_Store_Data:
	.byte 0xfb, 0x31, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0xff, 0x31, 0x00, 0x00, 0x01, 0x32, 0x00, 0x00
	.byte 0x03, 0x32, 0x00, 0x00, 0x05, 0x32, 0x00, 0x00
AccPatch_WriteRhythmInit:
	.byte 0xc1, 0x92, 0x33, 0x27, 0xcf, 0xd8, 0x66, 0x30
	.byte 0xeb, 0xa8, 0xc1, 0x92, 0x33, 0x27, 0xeb, 0xc8
	.byte 0x0c, 0xef, 0xf5, 0x00, 0x83, 0x21, 0xc1, 0x92
	.byte 0x33, 0x04, 0x1e, 0x44, 0x00, 0xf1, 0x92, 0x33
	.byte 0x04, 0xeb, 0xa8, 0xc1, 0x92, 0x33, 0x27, 0xdb
	.byte 0xee, 0x01, 0xeb, 0xc8, 0x1c, 0xef, 0xf5, 0x00
	.byte 0xa3, 0x23, 0x9b, 0x04, 0x25, 0xbb, 0x06, 0x55
AccPatch_WriteRhythm_Done:
	ret

AccPatch_ChannelToParamTable:
	.incbin "includes/romslices/v7_transplant_AccPatch_ChannelToParamTable.bin"
AccPatch_WriteRhythmParams:
	calr AccPatch_FetchVolumeForChannel
	push_a
	ld xwa, 0:i3
	pop_a
	ld c, 0x0:opc

AccPatch_WriteRhythmParam_Loop:
	cp	c, 6:i3
	jr	z, AccPatch_WriteRhythmParam_Done	; -> 0xF5EF89
	push	c
	push	xwa
	push	c
	pushw	wa
	call	RhythmBuf_WriteByte
	inc	2, xsp
	pop	c
	sll	c, 1
	ld	xwa, AccPatch_RhythmParamDefaults
	ld	a, (xwa+c)
	push	c
	pushw	wa
	call	RhythmBuf_WriteByte
	inc	2, xsp
	pop	c
	inc	1, c
	ld	xwa, AccPatch_RhythmParamDefaults
	ld	a, (xwa+c)
	cp	c, 7:i3
	jr	nz, AccPatch_WriteRhythmParam_Push	; -> 0xF5EF7B
	ld	a, (13233:16)
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
	ld	(13233:16), a
	pop	xiy
	pop	xix
	pop	xhl
	pop	xwa
	ret
RhythmProc_CheckStyleSwitch:
	cp (0x8c9a:16), 0xb8
	jr z, RhythmProc_StyleSwitch_Call
	jr t, RhythmProc_StyleSwitch_Ret
RhythmProc_StyleSwitch_Call:
	call AccPat_DispatchNoteChange

RhythmProc_StyleSwitch_Ret:
	ret

RhythmProc_CheckRepeatFlag:
	cp (0x8c9a:16), 0xbd
	jr nz, RhythmProc_RepeatFlag_Ret
	bit 1, (0x3437:16)
	jr z, RhythmProc_RepeatFlag_Ret
	and (0x3437:16), 0xfd
	ld XIY,0x00094800
	add XIY,0x00000000
	add XIY,0x00000010
	ld A,(XIY)
	and A,0xfe
	bit 0, (0x3437:16)
	jr z, RhythmProc_RepeatFlag_Store
	or A,0x01
RhythmProc_RepeatFlag_Store:
	ld (xiy), a

RhythmProc_RepeatFlag_Ret:
	ret

RhythmProc_SavePrevState:
	ld a, (0x8c9a:16)
	ld (0x3489:16), a
	ld a, (0x36ff:16)
	and A,0x7f
	ld (0x3474:16), a
	ld a, (0x31e7:16)
	ld (0x3565:16), a
	cp (0x8c98:16), 0x0e
	jr z, RhythmProc_SavePrevState_Done
	ld (0x36ff:16), 0x00
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
	ld	(13368:16), wa
	ret
AccPatch_CountSlotsAlt_Body:
	ld	xix, (14610:16)
	push	xix
	ld	xix, 432128
	ld	(14610:16), xix
	ldw	wa, 190
	ldw	de, 339
	xor	iy, iy
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
	ld	(13368:16), wa
	pop	xix
	ld	(14610:16), xix
	ret
AccPatch_MiscDataBlock:
	ld	xwa, 100
	mul	xwa, (0x3438:16)	; XWA, (0x3438) (unidasm; no llvm-mc spelling)
	ldw	hl, 190
	div	xwa, hl
	cp	a, 100
	jr	c, AccPatch_CountSlotsAlt_Body_Skip
	ld	a, 99:opc
AccPatch_CountSlotsAlt_Body_Skip:
	ld	(0x390f:16), a
	ret
AccPatch_ProcessPartChanges:
	ld	a, (14079:16)
	and	a, 31
	cp	a, 0:i3
	jr	nz, AccPatch_PartChanges_MapLookup
	ld	w, (13428:16)
	and	w, 31
	cp	w, 0:i3
	jr	z, AccPatch_PartChanges_NoNew
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	PartSelect_UpdateDisplayState
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
AccPatch_PartChanges_NoNew:
	jr AccPatch_PartChanges_CheckFlag

AccPatch_PartChanges_MapLookup:
	ld	a, (14079:16)
	and	a, 31
	ld	xhl, 0:i3
	ld	l, a
	add	xhl, AccPatch_PartNumberTable
	ld	a, (xhl)
	ld	(35998:16), a
	ld	e, a
	ld	a, (14079:16)
	ld	w, (13428:16)
	and	a, 31
	and	w, 31
	cp	w, a
	jr	z, AccPatch_PartChanges_Update
	ld	a, e
	ld	e, 144:opc
	ld	d, 16:opc
	ld	w, 255:opc
	call	SysEx_ApplyVoiceParam_49
AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	ld	a, (13428:16)
	bit	6, a
	jr	z, AccPatch_PartChanges_Done
	ld	w, (14079:16)
	bit	5, w
	jr	z, AccPatch_PartChanges_Done
	call	AccPatch_ReadRepeatBit
	calr	AccPatch_UpdateAllChains
AccPatch_PartChanges_Done:
	ret

AccPatch_ReadRepeatBit:
	ld XIX,0x00094800
	add XIX,0x00000000
	add XIX,0x00000010
	ld A,(XIX)
	bit 0x00,A
	jr nz, .Lc_f5f14e
	and (0x3437:16), 0xfe
	jr t, AccPatch_SetRepeatBit_Done
AccPatch_SetRepeatBitOn:
.Lc_f5f14e:
	or (0x3437:16), 0x01



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
; readers in v7 (address from the linked ELF): AccPatch_PartChanges_MapLookup 0xF5F0DB
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	push XIY
	add XIY,0x00000020
	ld XIX,0x0000fba4
	ld A,(XIY+0x03)
	and A,0x01
	sll A, 0x06
	and (XIX+0x04),0xbf
	and (XIX+0x04),0xf7
	or (XIX+0x04),A
	ld B,A
	ld A,(XIY+0x01)
	and A,0x7f
	and (XIX+0x01),0x80
	or (XIX+0x01),A
	ld D,A
	ld	a, (xiy+0:8)
	and	(xix+0:8), 0
	or	(xix+0:8), a
	ld	e, a
	sll	b, 1
	ld	(13381:16), e
	ld	(13382:16), d
	or	(0x3446:16), b
	push	d
	push	e
	ld	a, d
	ld	d, 1:opc
	ld	w, 127:opc
	ld	e, 19:opc
	call	SysEx_ApplyVoiceParam_49
	pop	e
	push	e
	ld	a, e
	ld	d, 0:opc
	ld	w, 255:opc
	ld	e, 19:opc
	call	SysEx_ApplyVoiceParam_49
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 19
	call	PartCtrl_WriteProgramChange
	ld	xbc, 65366
	ld	(xbc+l), h
	ld	a, (xiy+3)
	sla	a, 6
	ld	d, 4:opc
	ld	w, 64:opc
	ld	e, 19:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	ret
AccPatch_UpdateChain_Bass:
	push XIY
	add XIY,0x00000018
	ld XIX,0x0000fbbe
	ld A,(XIY+0x03)
	and A,0x01
	sll A, 0x06
	and (XIX+0x04),0xbf
	and (XIX+0x04),0xf7
	or (XIX+0x04),A
	ld B,A
	ld A,(XIY+0x01)
	and A,0x7f
	and (XIX+0x01),0x80
	or (XIX+0x01),A
	ld D,A
	ld	a, (xiy+0:8)
	or	a, 240
	and	(xix+0:8), 0
	or	(xix+0:8), a
	ld	e, a
	sll	b, 1
	ld	(13379:16), e
	ld	(13380:16), d
	or	(0x3444:16), b
	push	d
	push	e
	ld	a, d
	ld	d, 1:opc
	ld	w, 127:opc
	ld	e, 20:opc
	call	SysEx_ApplyVoiceParam_49
	pop	e
	push	e
	ld	a, e
	ld	d, 0:opc
	ld	w, 255:opc
	ld	e, 20:opc
	call	SysEx_ApplyVoiceParam_49
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 20
	call	PartCtrl_WriteProgramChange
	ld	xbc, 65386
	ld	(xbc+l), h
	ld	a, (xiy+3)
	sla	a, 6
	ld	d, 4:opc
	ld	w, 64:opc
	ld	e, 20:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	ret
AccPatch_UpdateChain_Acc1:
	push XIY
	add XIY,0x00000028
	ld XIX,0x0000fb56
	ld A,(XIY+0x03)
	and A,0x01
	sll A, 0x06
	and (XIX+0x04),0xbf
	and (XIX+0x04),0xf7
	or (XIX+0x04),A
	ld B,A
	ld A,(XIY+0x01)
	and A,0x7f
	and (XIX+0x01),0x80
	or (XIX+0x01),A
	ld D,A
	ld	a, (xiy+0:8)
	and	(xix+0:8), 0
	or	(xix+0:8), a
	ld	e, a
	sll	b, 1
	ld	(13383:16), e
	ld	(13384:16), d
	or	(0x3448:16), b
	push	d
	push	e
	ld	a, d
	ld	d, 1:opc
	ld	w, 127:opc
	ld	e, 16:opc
	call	SysEx_ApplyVoiceParam_49
	pop	e
	push	e
	ld	a, e
	ld	d, 0:opc
	ld	w, 255:opc
	ld	e, 16:opc
	call	SysEx_ApplyVoiceParam_49
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 16
	call	PartCtrl_WriteProgramChange
	ld	xbc, 65306
	ld	(xbc+l), h
	ld	a, (xiy+3)
	sla	a, 6
	ld	d, 4:opc
	ld	w, 64:opc
	ld	e, 16:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	ret
AccPatch_UpdateChain_Acc2:
	push XIY
	add XIY,0x00000030
	ld XIX,0x0000fb70
	ld A,(XIY+0x03)
	and A,0x01
	sll A, 0x06
	and (XIX+0x04),0xbf
	and (XIX+0x04),0xf7
	or (XIX+0x04),A
	ld B,A
	ld A,(XIY+0x01)
	and A,0x7f
	and (XIX+0x01),0x80
	or (XIX+0x01),A
	ld D,A
	ld	a, (xiy+0:8)
	and	(xix+0:8), 0
	or	(xix+0:8), a
	ld	e, a
	sll	b, 1
	ld	(13385:16), e
	ld	(13386:16), d
	or	(0x344a:16), b
	push	d
	push	e
	ld	a, d
	ld	d, 1:opc
	ld	w, 127:opc
	ld	e, 17:opc
	call	SysEx_ApplyVoiceParam_49
	pop	e
	push	e
	ld	a, e
	ld	d, 0:opc
	ld	w, 255:opc
	ld	e, 17:opc
	call	SysEx_ApplyVoiceParam_49
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 17
	call	PartCtrl_WriteProgramChange
	ld	xbc, 65326
	ld	(xbc+l), h
	ld	a, (xiy+3)
	sla	a, 6
	ld	d, 4:opc
	ld	w, 64:opc
	ld	e, 17:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	ret
AccPatch_UpdateChain_Acc3:
	push XIY
	add XIY,0x00000038
	ld XIX,0x0000fb8a
	ld A,(XIY+0x03)
	and A,0x01
	sll A, 0x06
	and (XIX+0x04),0xbf
	and (XIX+0x04),0xf7
	or (XIX+0x04),A
	ld B,A
	ld A,(XIY+0x01)
	and A,0x7f
	and (XIX+0x01),0x80
	or (XIX+0x01),A
	ld D,A
	ld	a, (xiy+0:8)
	and	(xix+0:8), 0
	or	(xix+0:8), a
	ld	e, a
	sll	b, 1
	ld	(13387:16), e
	ld	(13388:16), d
	or	(0x344c:16), b
	push	d
	push	e
	ld	a, d
	ld	d, 1:opc
	ld	w, 127:opc
	ld	e, 18:opc
	push	xiy
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	pop	e
	push	e
	ld	a, e
	ld	d, 0:opc
	ld	w, 255:opc
	ld	e, 18:opc
	push	xiy
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 18
	push	xiy
	call	PartCtrl_WriteProgramChange
	pop	xiy
	ld	xbc, 65346
	ld	(xbc+l), h
	ld	a, (xiy+3)
	sla	a, 6
	ld	d, 4:opc
	ld	w, 64:opc
	ld	e, 18:opc
	call	SysEx_ApplyVoiceParam_49
	pop	xiy
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
	ld	h, (13381:16)
	ld	l, (13382:16)
	cp	hl, wa
	jr	z, AccPatch_SyncRhythm_Done
	pushw	wa
	ld	(xiy+0:8), w
	ld	c, a
	and	c, 127
	ld	(xiy+1), c
	and	a, 128
	srl	a, 7
	ld	(xiy+3), a
	popw	wa
	ld	(13381:16), w
	ld	(13382:16), a
	ld	xix, 12669
	calr	AccPatch_LoadVoiceParams
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
	ld	h, (13379:16)
	ld	l, (13380:16)
	cp	hl, wa
	jr	z, AccPatch_SyncBass_Done
	pushw	wa
	ld	(xiy+0:8), w
	ld	c, a
	and	c, 127
	ld	(xiy+1), c
	and	a, 128
	srl	a, 7
	ld	(xiy+3), a
	popw	wa
	ld	(13379:16), w
	ld	(13380:16), a
	ld	xix, 12664
	calr	AccPatch_LoadVoiceParams
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
	ld	h, (13383:16)
	ld	l, (13384:16)
	cp	hl, wa
	jr	z, AccPatch_SyncAcc1_Done	; -> 0xF5F5A9
	pushw	wa
	ld	(xiy+0:8), w
	ld	c, a
	and	c, 127
	ld	(xiy+1), c
	and	a, 128
	srl	a, 7
	ld	(xiy+3), a
	popw	wa
	ld	(13383:16), w
	ld	(13384:16), a
	ld	xix, 12674
	calr	AccPatch_LoadVoiceParams
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
	ld	h, (13385:16)
	ld	l, (13386:16)
	cp	hl, wa
	jr	z, AccPatch_SyncAcc2_Done
	pushw	wa
	ld	(xiy+0:8), w
	ld	c, a
	and	c, 127
	ld	(xiy+1), c
	and	a, 128
	srl	a, 7
	ld	(xiy+3), a
	popw	wa
	ld	(13385:16), w
	ld	(13386:16), a
	ld	xix, 12679
	calr	AccPatch_LoadVoiceParams
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
	ld	h, (13387:16)
	ld	l, (13388:16)
	cp	hl, wa
	jr	z, AccPatch_SyncAcc3_Done
	pushw	wa
	ld	(xiy+0:8), w
	ld	c, a
	and	c, 127
	ld	(xiy+1), c
	and	a, 128
	srl	a, 7
	ld	(xiy+3), a
	popw	wa
	ld	(13387:16), w
	ld	(13388:16), a
	ld	xix, 12684
	calr	AccPatch_LoadVoiceParams
AccPatch_SyncAcc3_Done:
	pop xiy
	ret
AccPatch_LoadVoiceParams:
	ld	e, (xiy+0:8)
	ld	d, (xiy+1)
	ld	a, (xiy+2)
	ld	(13203:16), a
	ld	a, (xiy+3)
	ld	(13204:16), a
	ld	a, (xiy+4)
	ld	(13205:16), a
	calr	AccPatch_CallParamLookup
	ret
AccPatch_CallParamLookup:
	push	xix
	pushw	de
	pushdi_b	(13203)
	pushdi_b	(13204)
	pushdi_b	(13205)
	call	RhythmPart_CopyData_Tramp
	pop	(0x3395:16)
	pop	(0x3394:16)
	pop	(0x3393:16)
	popw	de
	pop	xix
	bit	7, e
	jr	z, AccPatch_StoreVoiceParams
	or	d, 16
	and	e, 127
AccPatch_StoreVoiceParams:
	ld	(xix), e
	ld	(xix+1), d
	ld	a, (13203:16)
	ld	(xix+2), a
	ld	a, (13204:16)
	ld	(xix+3), a
	ld	a, (13205:16)
	ld	(xix+4), a
	call	AccVoice_LoadAllChannelParams
	ret
AccPatch_ComplexDataBlock:
	ld	a, (35992:16)
	cp	a, 14
	jr	nz, AccPatch_CallParamLookup_Return
	calr	AccPatch_CallParamLookup_Helper
AccPatch_CallParamLookup_Return:
	ret
AccPatch_CallParamLookup_Helper:
	ld	a, (49121:16)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip
	cp	(49122:16), 128
	jr	nc, AccPatch_CallParamLookup_Skip
	cp	(49123:16), 0
	jr	z, AccPatch_CallParamLookup_Skip
	ld	a, (35994:16)
	cp	a, 180
	jr	nz, AccPatch_CallParamLookup_Skip
	ld	xiy, 608256
	add	xiy, 0
	ld	a, (xiy+16)
	bit	0, a
	jr	nz, AccPatch_CallParamLookup_Skip
	call	16143311
	ld	(13476:16), 7
AccPatch_CallParamLookup_Skip:
	ld	a, (49121:16)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Return2
	cp	(49123:16), 0
	jr	z, AccPatch_CallParamLookup_Return2
	ld	a, (35994:16)
	cp	a, 184
	jr	nz, AccPatch_CallParamLookup_Return2
	call	TimeSig_DisplayStrings_Code_Sub
	call	AccPatch_CallParamLookup_Helper7
	call	16143311
AccPatch_CallParamLookup_Return2:
	ret
AccDemo_InitDone_Helper:
	calr	AccPatch_CallParamLookup_Helper2
	ret
AccDemo_InitWithFlag_Helper:
	ld XIY,0x00094800
	add XIY,0x00000000
	add XIY,0x00000000
	ld	a, (xiy+0:8)
	cp	a, 72
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
	ld	a, (xiy+0:8)
	cp	a, 72
	jr	nz, AccPatch_CallParamLookup_Entry
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Entry
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Entry
	call	AccPatch_CallParamLookup_Helper3
	jrl	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Entry:
	cp	(xiy), 76
	jr	nz, AccPatch_CallParamLookup_Skip3
	cp	(xiy+1), 75
	jr	nz, AccPatch_CallParamLookup_Skip3
	cp	(xiy+2), 69
	jr	nz, AccPatch_CallParamLookup_Skip3
	call	AccPatch_CallParamLookup_Helper3
	call	AccPatch_CallParamLookup_Helper4
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Skip3:
	ld	a, (xiy+0:8)
	cp	a, 71
	jr	nz, AccPatch_CallParamLookup_Skip4
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip4
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip4
	call	AccPatch_CallParamLookup_Helper3
	call	AccPatch_CallParamLookup_Helper4
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Skip4:
	ld	a, (xiy+0:8)
	cp	a, 70
	jr	nz, AccPatch_CallParamLookup_Skip5
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_CallParamLookup_Skip5
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip5
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip5:
	ld	a, (xiy+0:8)
	cp	a, 77
	jr	nz, AccPatch_CallParamLookup_Skip7
	ld	a, (xiy+1)
	cp	a, 75
	jr	nz, AccPatch_CallParamLookup_Skip7
	ld	a, (xiy+2)
	cp	a, 66
	jr	nz, AccPatch_CallParamLookup_Skip6
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip6:
	cp	a, 65
	jr	nz, AccPatch_CallParamLookup_Skip7
	jr	AccPatch_CallParamLookup_Join
AccPatch_CallParamLookup_Skip7:
	call	AccDemo_Init_Wrap
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Join:
	call	AccPatch_VoiceAssignDataBlock
	jr	AccPatch_CallParamLookup_Return4
AccPatch_CallParamLookup_Return4:
	ret
AccPatch_CallParamLookup_Helper3:
	ret
AccPatch_CallParamLookup_Helper4:
	ld	xiy, 608256
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
	calr	AccPatch_CallParamLookup_Helper5
	ret
AccPatch_CallParamLookup_Helper5:
	ld	hl, (xiy+0:8)
	calr	AccPatch_CallParamLookup_Helper6
	ld	hl, (xiy+4)
	calr	AccPatch_CallParamLookup_Helper6
	ld	hl, (xiy+6)
	calr	AccPatch_CallParamLookup_Helper6
	ld	hl, (xiy+8)
	calr	AccPatch_CallParamLookup_Helper6
	ld	hl, (xiy+10)
	calr	AccPatch_CallParamLookup_Helper6
	ret
AccPatch_CallParamLookup_Helper6:
	push	xiy
	calr	AccPatch_GetEntryAddr
	ldw	(xix+3), 65535
	pushw	hl
	ld	l, (xiy+12)
	xor	h, h
	ld	xwa, 0:i3
	ld	xbc, AccTone_LookupByProgram_Table
	ld	a, (xbc+hl)
	ld	xbc, 0:i3
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
	ld	hl, wa
	ldw	(xix+3), 65535
	calr	AccPatch_ResolveSlotAddr
	ldw	(xix+1), 65535
	and	(xix), 127
	incw	1, (0x3438:16)
	ld	wa, (xix+3)
	cp	wa, 65535
	jr	z, AccPatch_FreeChain_Alt_Done
	jr	AccPatch_FreeChainLoop_Alt
AccPatch_FreeChain_Alt_Done:
	pop xiy
	ret

AccPatch_ResolveSlotAddr:
	cp	hl, 65535
	jr	z, AccPatch_ResolveSlotAddr_Ret
	pushw	hl
	pushw	hl
	ld	xhl, 0:i3
	popw	hl
	sll	xhl, 8
	ld	xix, (14610:16)
	add	xix, 5120
	add	xix, xhl
	popw	hl
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
	calr	AccPatch_SeqReadByte_Alt
	cp	a, 131
	jr	z, AccPatch_ScanSeq_StorePosAndRet
	calr	AccPatch_SeqAdvance_Alt
	bit	0, (0x357a:16)
	jr	nz, AccPatch_ScanSeq_StorePosAndRet
	jr	AccPatch_ScanSeq_Loop
AccPatch_ScanSeq_StorePosAndRet:
	ld	wa, (13686:16)
	ld	(13674:16), wa
	ld	wa, (13688:16)
	ld	(13676:16), wa
	ret
AccPatch_SeqReadByte_Alt:
	push xix

	ld hl, (13686:16)

	calr AccPatch_ResolveSlotAddr

	ld hl, (13688:16)

	ld	a, (xix+hl)

	pop xix

	ret



AccPatch_SeqAdvance_Alt:
	ld	wa, (0x3578:16)
	cp	wa, 254
	jr	nz, AccPatch_SeqAdvance_Inc
	ld	hl, (0x3576:16)
	calr	AccPatch_ResolveSlotAddr
	ld	wa, (xix+3)
	ld	(0x3576:16), wa
	cp	wa, 65535
	jr	nz, AccPatch_SeqAdvance_CheckLimit
	or	(0x357a:16), 1
AccPatch_SeqAdvance_CheckLimit:
	cp	wa, 340
	jr	lt, AccPatch_SeqAdvance_ResetBase
	or	(0x357a:16), 1
AccPatch_SeqAdvance_ResetBase:
	ld wa, 6:i3
	jr AccPatch_SeqAdvance_Store

AccPatch_SeqAdvance_Inc:
	inc 1, wa

AccPatch_SeqAdvance_Store:
	ld	(13688:16), wa
	ret
AccPatch_InitSlotPointer_Alt:
	xor	xhl, xhl
	ld	l, (14608:16)
	cp	l, 30
	jr	c, AccPatch_InitSlotAlt_Valid
	xor	l, l
AccPatch_InitSlotAlt_Valid:
	mul hl, 0x60

	add xhl, 0x60

	ld xiy, (14610:16)

	add xiy, xhl

	ld a, (14079:16)

	calr MapBitFlagsToChannelOffset

	ld	hl, (xiy+w)

	ld (13686:16), hl

	ldw (13688:16), 6

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

	ld hl, (13686:16)

	calr AccPatch_GetEntryAddr

	ld hl, (13688:16)

	ld	a, (xix+hl)

	pop xix

	ret



AccPatch_SeqDispatch_Padding:
	nop
	nop

AccPatch_AdvanceSeqIndex:
	ld wa, (0x3578:16)
	cp WA,0x00fe
	jr nz, AccPatch_AdvSeq_Inc
	ld hl, (0x3576:16)
	calr AccPatch_GetEntryAddr
	ld WA,(XIX+0x03)
	ld (0x3576:16), wa
	cp WA,0xffff
	jr nz, .Lc_f5fa4c
	or (0x357a:16), 0x01
AccPatch_AdvSeq_CheckLimit:
.Lc_f5fa4c:
	cp WA,0x0154
	jr lt, AccPatch_AdvSeq_ResetBase
	or (0x357a:16), 0x01
AccPatch_AdvSeq_ResetBase:
	ld wa, 6:i3
	jr AccPatch_AdvSeq_Store

AccPatch_AdvSeq_Inc:
	inc 1, wa

AccPatch_AdvSeq_Store:
	ld	(13688:16), wa
	ret
AccPatch_AdvSeq_Padding:
	nop
	nop

AccPatch_SeqDispatch_Main:
	ld	a, (14079:16)
	cp	a, (13666:16)
	jr	z, AccPatch_SeqDispatch_CheckEmpty
	calr	AccPatch_ScanToSequenceStart
	calr	AccPatch_InitAndLoadSequence
AccPatch_SeqDispatch_CheckEmpty:
	ld	a, (14079:16)
	and	a, 31
	cp	a, 0:i3
	jr	nz, AccPatch_SeqDispatch_CheckPlaying
	jrl	AccPatch_SyncStateAndReturn
AccPatch_SeqDispatch_CheckPlaying:
	bit	0, (0x31e7:16)
	jr	nz, AccPatch_SeqDispatch_CheckStarted
	call	TempoRingBuf_ReInitAndRet
	jrl	AccPatch_SyncStateAndReturn
AccPatch_SeqDispatch_CheckStarted:
	bit	0, (0x3565:16)
	jr	nz, AccPatch_SeqDispatch_ProcessFlags
	calr	AccPatch_ResetSeqCounters
	calr	AccPatch_InitCurrentSlotPointer
	ld	wa, (0x3576:16)
	ld	(0x3566:16), wa
	ld	wa, (0x3578:16)
	ld	(0x3568:16), wa
AccPatch_SeqDispatch_ProcessFlags:
	calr	AccPatch_ReadModeFlags
	ld	a, (13363:16)
	and	a, 12
	cp	a, 0:i3
	jr	nz, AccPatch_SeqDispatch_ModeChange
	ld	a, (13664:16)
	and	a, 12
	cp	a, 0:i3
	jr	z, AccPatch_SeqDispatch_RunNotes
AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn
AccPatch_SeqDispatch_RunNotes:
	call	AccPatch_CheckEmpty
	cp	wa, 0:i3
	jr	z, AccPatch_SyncStateAndReturn
	ldw	(13678:16), 0
	ldw	(13682:16), 0
	ld	(13667:16), 0
	calr	AccPatch_EventDispatch_Nop
	cpw	(13678:16), 0
	jr	z, AccPatch_SeqDispatch_CheckQueued
	ld	wa, (13670:16)
	ld	(13922:16), wa
	ld	wa, (13672:16)
	ld	(13924:16), wa
	calr	AccPatch_InitSlotAndCopyData
	calr	AccPatch_AdvancePlayPos
	calr	AccPatch_AdvanceAllSteps
	ldw	(13678:16), 0
AccPatch_SeqDispatch_CheckQueued:
	cpw	(13682:16), 0
	jr	z, AccPatch_SyncStateAndReturn
	calr	AccPatch_DispatchQueuedNotes
AccPatch_SyncStateAndReturn:
	ld	a, (14079:16)
	ld	(13666:16), a
	ret
AccPatch_SeqDispatch_MiscData:
	.byte 0x00, 0x00, 0xc1, 0x33, 0x34, 0x3e, 0x08, 0x0e
	.byte 0xc1, 0x33, 0x34, 0x3c, 0xf7, 0x1d, 0xe6, 0xfb
	.byte 0xf5, 0x0e
AccPatch_ReadModeFlags:
	ld a, (0x3433:16)
	and A,0xf3
	ld (0x3433:16), a
	cp (0x8c9c:16), 0xb5
	jr z, .Lc_f5fb46
	jr t, AccPatch_SetFlagExit
AccPatch_ReadModeFlags_Active:
.Lc_f5fb46:
	ld xwa, (0x02749a:24)
	or	xwa, (0x2749e:24)
	ld	(0x11d0:16), xwa
	ld	xwa, (0x2749e:24)
	ld	(0x3944:16), xwa
	ld	xwa, (0x11d0:16)
	and	xwa, 512
	cp	xwa, 0
	jr	z, AccPatch_ReadModeFlags_Check400
	ld	xwa, (0x3944:16)
	and	xwa, 512
	cp	xwa, 0
	jr	nz, AccPatch_ReadModeFlags_Check400
	ld	a, (0x3433:16)
	or	a, 4
	ld	(0x3433:16), a
AccPatch_ReadModeFlags_Check400:
	ld	xwa, (4560:16)
	and	xwa, 1024
	cp	xwa, 0
	jr	z, AccPatch_SetFlagExit
	ld	xwa, (14660:16)
	and	xwa, 1024
	cp	xwa, 0
	jr	nz, AccPatch_SetFlagExit
	ld	a, (13363:16)
	or	a, 8
	ld	(13363:16), a
AccPatch_SetFlagExit:
	ret

AccPatch_ScanSeq_PaddingByte:
	ret

AccPatch_ScanToSequenceStart:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ScanSeq_ReadLoop:
	calr	AccPatch_SeqReadByte
	cp	a, 131
	jr	z, AccPatch_ScanSeq_StorePosition
	calr	AccPatch_AdvanceSeqIndex
	bit	0, (0x357a:16)
	jr	nz, AccPatch_ScanSeq_StorePosition
	jr	AccPatch_ScanSeq_ReadLoop
AccPatch_ScanSeq_StorePosition:
	ld	wa, (13686:16)
	ld	(13674:16), wa
	ld	wa, (13688:16)
	ld	(13676:16), wa
	ret
AccPatch_ScanSeq_PaddingWord:
	nop
	nop

AccPatch_InitAndLoadSequence:
	ld	xhl, 13694
	ldw	bc, 8
AccPatch_InitSeq_ClearLoop:
	ldw	(xhl), 0
	add	hl, 6
	djnz16	bc, -11
	ei	6
	bit	0, (0x35ae:16)
	jr	nz, AccPatch_InitSeq_LoadTempo
	call	TempoRingBuf_ReInitAndRet
AccPatch_InitSeq_LoadTempo:
	ld	a, (0x435:16)
	ld	c, (0x416:16)
	ei	0
	and	(0x35ae:16), 254
	ld	b, (0x343d:16)
	mul	wa, b
	add	c, a
	xor	b, b
	pushw	bc
	calr	AccPatch_InitCurrentSlotPointer
	popw	bc
	cp	bc, 0:i3
	jr	z, AccPatch_InitSeq_AdvDone
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
	ld	xhl, 13694
	ldw	bc, 8
AccPatch_ResetSeqCounters_Loop:
	ldw	(xhl), 0
	add	hl, 6
	djnz16	bc, -11
	ei	6
	ld	a, (0x435:16)
	ld	c, (0x416:16)
	ei	0
	and	(0x35ae:16), 254
	ld	b, (0x343d:16)
	mul	wa, b
	add	c, a
	xor	b, b
	pushw	bc
	call	AccPatch_InitCurrentSlotPointer
	popw	bc
	cp	bc, 0:i3
	jr	z, AccPatch_ResetSeqCounters_Done
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
.Lc_f5fc75:
	calr AccPatch_SeqReadByte
	cp A,0x81
	jr z, .Lc_f5fc88
	calr AccPatch_AdvanceSeqIndex
	bit 0, (0x357a:16)
	jr nz, AccPatch_ScanDone
	jr t, .Lc_f5fc75
AccPatch_ScanSeqEnd_HandleMarker:
.Lc_f5fc88:
	calr AccPatch_AdvanceSeqIndex
	bit 0, (0x357a:16)
	jr nz, AccPatch_ScanDone
	calr AccPatch_SeqReadByte
	cp A,0x83
	jr nz, AccPatch_ScanDone
	calr AccPatch_MarkAllSlotsActive
AccPatch_ScanDone:
	ret

AccPatch_ScanDone_Pad:
	nop
	nop

AccPatch_MarkAllSlotsActive:
	ld	xhl, 13694
AccPatch_MarkSlots_Loop:
	bitm 7, (xhl)
	jr z, AccPatch_MarkSlots_Next
	ormi8 (xhl + 1), 0x80

AccPatch_MarkSlots_Next:
	add	xhl, 6
	cp	xhl, 13742
	jr	c, AccPatch_MarkSlots_Loop
	calr	AccPatch_InitCurrentSlotPointer
	ret
AccPatch_UpdateSequenceState:
	ld	wa, (13686:16)
	ld	(13630:16), wa
	ld	wa, (13688:16)
	ld	(13632:16), wa
	ei	6
	ld	a, (1077:16)
	ld	(13661:16), a
	ld	wa, (1045:16)
	ld	(13930:16), wa
	ei	0
	ld	a, (13363:16)
	ld	w, (13664:16)
	bit	2, a
	jr	nz, AccPatch_UpdateSeqState_CheckXor
	bit	2, w
	jr	nz, AccPatch_UpdateSeqState_CheckXor
	jr	AccPatch_UpdateSeqState_CheckBit4
AccPatch_UpdateSeqState_CheckXor:
	ld	c, a
	xor	c, w
	and	a, c
	cp	a, 0:i3
	jr	z, AccPatch_UpdateSeqState_AndCheck
	calr	AccPatch_SeekToPosition
	or	(0x3561:16), 1
	jr	AccPatch_LoadNextSequencePointers
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
	bit	4, (0x36ff:16)
	jr	z, AccPatch_LoadNextSequencePointers
	ld	a, (0x34bc:16)
	ld	(0x355f:16), a
	bit	3, (0x3433:16)
	jr	z, AccPatch_UpdateSeqState_ClearBit7
	bit	7, (0x34bc:16)
	jr	nz, AccPatch_UpdateSeqState_ScanNoteOff
	calr	AccPatch_ClearAndScanForNote
	jr	AccPatch_UpdateSeqState_AfterScan
AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	; anddi8 (0x3558), 127 (v7 patched)
	and	(0x34bc:16), 127
AccPatch_UpdateSeqState_CompareBits:
	ld	a, (13500:16)
	ld	c, (13663:16)
	bit	7, a
	jr	z, AccPatch_UpdateSeqState_CheckC7
	bit	7, c
	jr	nz, AccPatch_UpdateSeqState_BothSet
	calr	AccPatch_SeekToPosition
	jr	AccPatch_LoadNextSequencePointers
AccPatch_UpdateSeqState_CheckC7:
	bit 7, c
	jr z, AccPatch_LoadNextSequencePointers
	calr AccPatch_InitAndLoadSequence
	jr AccPatch_UpdateSeqState_CheckBit3

AccPatch_UpdateSeqState_BothSet:
	calr AccPatch_PrepareAndProcessEvents

AccPatch_LoadNextSequencePointers:
	ld	wa, (13630:16)
	ld	(13686:16), wa
	ld	wa, (13632:16)
	ld	(13688:16), wa
AccPatch_UpdateSeqState_CheckBit3:
	bit	3, (0x3433:16)
	jr	nz, AccPatch_UpdateSeqState_StoreFlags
	bit	3, (0x3560:16)
	jr	z, AccPatch_UpdateSeqState_StoreFlags
	calr	AccPatch_InitAndLoadSequence
AccPatch_UpdateSeqState_StoreFlags:
	ld	a, (0x3433:16)
	ld	(0x3560:16), a
	and	(0x355f:16), 253
	bit	0, (0x355f:16)
	jr	z, AccPatch_UpdateSeqState_Return
	or	(0x355f:16), 2
AccPatch_UpdateSeqState_Return:
	ret

AccPatch_UpdateSeqState_StoreFlags_Pad:
	nop
	nop

AccPatch_ClearAndScanForNote:
	; anddi8 (0x3558), 127 (v7 patched)
	and	(0x34bc:16), 127
AccPatch_ScanForActiveNote:
	call	AccPatch_CheckEmpty
	cp	wa, 0:i3
	jr	z, AccPatch_ScanNote_Done
	ld	bc, 1:i3
	calr	TempoRingBuf_SkipBytes
	ld	w, a
	and	w, 240
	cp	w, 144
	jr	nz, AccPatch_ScanNote_Continue
	ld	bc, 2:i3
	calr	TempoRingBuf_SkipBytes
	ld	l, a
	push	l
	ld	bc, 1:i3
	calr	TempoRingBuf_SkipBytes
	pop	l
	cp	a, 0:i3
	jr	z, AccPatch_ScanNote_Continue
	or	l, 128
	ld	(13500:16), l
	call	TempoRingBuf_ReInitAndRet
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
	call	AccPatch_CheckEmpty
	cp	wa, 0:i3
	jr	z, AccPatch_ScanForNoteOff_Done
	ld	bc, 1:i3
	calr	TempoRingBuf_SkipBytes
	ld	w, a
	and	w, 240
	cp	w, 144
	jr	nz, AccPatch_ErrorExit
	ld	bc, 2:i3
	calr	TempoRingBuf_SkipBytes
	ld	l, a
	ld	h, (0x34bc:16)
	and	h, 127
	cp	h, l
	jr	nz, AccPatch_ErrorExit
	ld	bc, 1:i3
	calr	TempoRingBuf_SkipBytes
	cp	a, 0:i3
	jr	nz, AccPatch_ErrorExit
	and	(0x34bc:16), 127
	call	TempoRingBuf_ReInitAndRet
AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	calr	AccPatch_SeekForwardSteps
	ld	a, (13930:16)
	ld	(13916:16), a
	calr	AccPatch_ParseSequenceHeader
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
	ret
AccPatch_SeekForwardSteps:
	ld	a, (13661:16)
	ld	c, (13931:16)
	ld	b, (13373:16)
	mul	wa, b
	add	c, a
	xor	b, b
	pushw	bc
	calr	AccPatch_InitCurrentSlotPointer
	popw	bc
	cp	bc, 0:i3
	jr	z, AccPatch_SeekFwd_Done
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
	ld wa, (0x3576:16)
	ld (0x365e:16), wa
	ld wa, (0x3578:16)
	ld (0x3660:16), wa
	calr AccPatch_SeqReadByte
	cp A,0x81
	jr z, AccPatch_ParseHdr_RestorePos
	cp A,0x83
	jr nz, .Lc_f5fe95
	or (0x357a:16), 0x02
	jr t, AccPatch_ParseHdr_Return
AccPatch_ParseHdr_AdvanceAndCompare:
.Lc_f5fe95:
	calr AccPatch_AdvanceSeqIndex
	calr AccPatch_SeqReadByte
	cp	a, (0x365c:16)
	jr	ugt, AccPatch_ParseHdr_RestorePos
AccPatch_ParseHdr_AdvanceAndRead:
	calr	AccPatch_AdvanceSeqIndex
	calr	AccPatch_SeqReadByte
	bit	0, (0x357a:16)
	jr	z, AccPatch_ParseHdr_CheckBit7
	jr	AccPatch_ParseHdr_Return
AccPatch_ParseHdr_CheckBit7:
	bit 7, a
	jr z, AccPatch_ParseHdr_AdvanceAndRead
	jr AccPatch_ParseSequenceHeader

AccPatch_ParseHdr_RestorePos:
	ld	wa, (13918:16)
	ld	(13686:16), wa
	ld	wa, (13920:16)
	ld	(13688:16), wa
AccPatch_ParseHdr_Return:
	ret

AccPatch_ParseHdr_RestorePos_Pad:
	nop
	nop

AccPatch_ResumeSequencePlayback:
	and (0x3561:16), 0xfe
	calr AccPatch_PrepareSequencePlayback
	ld wa, (0x3542:16)
	ld (0x3576:16), wa
	ld wa, (0x3544:16)
	ld (0x3578:16), wa
	ldw (0x356e:16), 0x0000
AccPatch_ResumeSeq_ComparePos:
	ld wa, (0x3576:16)
	cp	wa, (0x3546:16)
	jr	nz, AccPatch_ResumeSeq_ReadByte
	ld	wa, (0x3578:16)
	cp	wa, (0x3548:16)
	jr	nz, AccPatch_ResumeSeq_ReadByte
	calr	AccPatch_CheckSequenceChanged
	jrl	AccPatch_ResumeSeq_Return
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
	; adddm16 0x360a, xbc (v7 patched)
	add	(0x356e:16), bc
AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz16 bc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	calr	AccPatch_CheckSequenceChanged
	calr	AccPatch_AdvanceSeqIndex
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
	calr	AccPatch_SeqReadByte
	cp	a, 131
	jr	z, AccPatch_ResumeSeq_InitSlot
	cpw	(13678:16), 0
	jr	z, AccPatch_ResumeSeq_LoopBack
	calr	AccPatch_PrepareSequencePlayback
	ldw	(13678:16), 0
AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	calr	AccPatch_InitCurrentSlotPointer
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
AccPatch_ResumeSeq_Return:
	ret

AccPatch_ResumeSeq_InitSlot_Pad:
	nop
	nop

AccPatch_PrepareSequencePlayback:
	calr	AccPatch_SeekForwardSteps
	ld	a, (13930:16)
	ld	(13916:16), a
	calr	AccPatch_ParseSequenceHeader
	ld	wa, (13686:16)
	ld	(13638:16), wa
	ld	wa, (13688:16)
	ld	(13640:16), wa
	ret
AccPatch_CheckSequenceChanged:
	cpw (0x356e:16), 0x0000
	jr z, AccPatch_CheckChanged_Return
	ld wa, (0x3542:16)
	ld (0x35be:16), wa
	ld wa, (0x3544:16)
	ld (0x35c4:16), wa
	ld wa, (0x3576:16)
	ld (0x35bc:16), wa
	ld wa, (0x3578:16)
	ld (0x35c2:16), wa
	ld wa, (0x35be:16)
	cp	wa, (0x35bc:16)
	jr	nz, AccPatch_CheckChanged_DoCopy
	ld	wa, (0x35c4:16)
	cp	wa, (0x35c2:16)
	jr	nz, AccPatch_CheckChanged_DoCopy
	jr	AccPatch_CheckChanged_Return
AccPatch_CheckChanged_DoCopy:
	calr	AccPatch_CopySequenceEntry
	calr	AccPatch_UpdateEntryFromTable
	ld	wa, (13634:16)
	ld	(13686:16), wa
	ld	wa, (13636:16)
	ld	(13688:16), wa
AccPatch_CheckChanged_Return:
	ret

AccPatch_CheckChanged_DoCopy_Pad:
	nop
	nop

AccPatch_CopySequenceEntry:
	ld de, (0x356a:16)
	ld wa, (0x356c:16)
	ld (0x35c6:16), wa
	ld hl, (0x35bc:16)
	calr AccPatch_GetEntryAddr
	ld (0x35b4:16), xix
	ld hl, (0x35be:16)
	calr AccPatch_GetEntryAddr
	ld (0x35b0:16), xix
	calr AccPatch_SetupBlockCopyDispatch
	dec 1,IX
	ld (0x3668:16), ix
	ld wa, (0x35be:16)
	cp	wa, (0x356a:16)
	jr	z, AccPatch_CopyEntry_Store
	incw	1, (0x3438:16)
	ld	hl, (0x35be:16)
	calr	AccPatch_GetEntryAddr
	ld	wa, (xix+3)
	ldw	(xix+3), 65535
	ld	hl, wa
	calr	AccPatch_GetEntryAddr
	and	(xix), 127
	ldw	(xix+1), 65535
AccPatch_CopyEntry_Store:
	ld	wa, (13758:16)
	ld	(13674:16), wa
	ld	wa, (13928:16)
	ld	(13676:16), wa
	ret
AccPatch_CopyEntry_Store_Pad:
	nop
	nop

AccPatch_UpdateEntryFromTable:
	calr AccPatch_LoadTablePointers
	ld DE,(XIX)
	ld HL,(XIY)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cp	hl, (0x3542:16)
	jr	z, AccPatch_UpdateEntry_CheckDE
	cpw	(xix+1), 65535
	jr	z, AccPatch_NullRet
	calr	AccPatch_AdjustTableEntryPos
	jr	AccPatch_NullRet
AccPatch_UpdateEntry_CheckDE:
	cp	de, (0x3544:16)
	jr	nc, AccPatch_UpdateEntry_AdjustOffset
	jr	AccPatch_NullRet
AccPatch_UpdateEntry_AdjustOffset:
	sub	de, (13678:16)
	cp	de, 6:i3
	jr	z, AccPatch_UpdateEntry_StoreDirect	; -> 0xF600AF
	jr	ugt, AccPatch_UpdateEntry_StoreDirect	; -> 0xF600AF
	ld	hl, 6:i3
	sub	hl, de
	ld	de, hl
	pushw	de
	ld	wa, (xix+1)
	pushw	wa
	calr	AccPatch_LoadTablePointers
	popw	wa
	ld	(xiy), wa
	popw	de
	ldw	hl, 255
	sub	hl, de
	ld	(xix), hl
	jr	AccPatch_NullRet	; -> 0xF600B6
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
	push	xbc
	ld	xbc, 0:i3
	ld	c, (14079:16)
	sll	bc, 2
	push	xbc
	add	xbc, AccPatch_LoadTablePointers_Data_2
	ld	xix, xbc
	ld	xix, (xix)
	pop	xbc
	ld	xiy, AccPatch_LoadTablePointers_Data
	add	xiy, xbc
	ld	xiy, (xiy)
	pop	xbc
	ret
AccPatch_AdjustTableEntryPos:
	calr	AccPatch_LoadTablePointers
	ld	de, (xix)
	ld	wa, (xiy)
	sub	de, 6
	cp	de, (13678:16)
	jr	c, AccPatch_AdjustEntry_Overflow	; -> 0xF600F7
	sub	de, (13678:16)
	add	de, 6
	ld	(xix), de
	jr	AccPatch_AdjustEntry_Return	; -> 0xF60110
AccPatch_AdjustEntry_Overflow:
	ld	hl, (13678:16)
	sub	hl, de
	ldw	de, 255
	sub	de, hl
	ld	(xix), de
	ld	hl, wa
	push	xiy
	calr	AccPatch_GetEntryAddr
	pop	xiy
	ld	hl, (xix+1)
	ld	(xiy), hl
AccPatch_AdjustEntry_Return:
	ret

AccPatch_PrepareAndProcessEvents:
	calr	AccPatch_PrepareSequencePlayback
	ld	wa, (13634:16)
	ld	(13686:16), wa
	ld	wa, (13636:16)
	ld	(13688:16), wa
AccPatch_ProcessSequenceEvents:
	ld wa, (0x3576:16)
	cp wa, (0x3546:16)
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	ld wa, (0x3578:16)
	cp wa, (0x3548:16)
	jr nz, AccPatch_ProcessSeqEvt_SavePos
	jrl t, AccPatch_ProcessSeqEvt_StorePos
AccPatch_ProcessSeqEvt_SavePos:
	ld	wa, (13686:16)
	ld	(13918:16), wa
	ld	wa, (13688:16)
	ld	(13920:16), wa
	calr	AccPatch_SeqReadByte
	ld	(13917:16), a
	cp	a, 144
	jr	z, AccPatch_SkipNoteOff
	cp	a, 145
	jr	z, AccPatch_SkipNoteOff
	cp	a, 146
	jr	z, AccPatch_SkipNoteOff
	cp	a, 129
	jr	z, AccPatch_ProcessSeqEvt_HandleEnd
	and	a, 240
	cp	a, 208
	jr	z, AccPatch_ProcessSeqEvt_SkipD
	jrl	AccPatch_ProcessSeqEvt_RetNop
AccPatch_SkipNoteOff:
	calr	AccPatch_AdvanceSeqIndex
	calr	AccPatch_AdvanceSeqIndex
	calr	AccPatch_SeqReadByte
	ld	(13662:16), a
	ld	bc, 6:i3
	cp	(13917:16), 145
	jr	z, AccPatch_ProcessSeqEvt_AdvLoop
	ld	bc, 4:i3
AccPatch_ProcessSeqEvt_AdvLoop:
	calr	AccPatch_AdvanceSeqIndex
	djnz16	bc, -6
	ld	a, (13662:16)
	ld	b, (13500:16)
	and	b, 127
	cp	a, b
	jr	z, AccPatch_ProcessSeqEvt_SetSize
	cp	a, 93
	jr	nz, AccPatch_ProcessSeqEvt_LoopBack
	cp	b, 48
	jr	nz, AccPatch_ProcessSeqEvt_LoopBack
	jr	AccPatch_ProcessSeqEvt_SetSize
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
	ldw	(13678:16), 8
	cp	(13917:16), 145
	jr	z, AccPatch_ProcessSeqEvt_StoreAndPrep
	ldw	(13678:16), 6
AccPatch_ProcessSeqEvt_StoreAndPrep:
	ld	wa, (13918:16)
	ld	(13634:16), wa
	ld	wa, (13920:16)
	ld	(13636:16), wa
	calr	AccPatch_CheckSequenceChanged
	ldw	(13678:16), 0
	calr	AccPatch_PrepareSequencePlayback
	jrl	AccPatch_ProcessSequenceEvents
AccPatch_ProcessSeqEvt_InitSlot:
	calr AccPatch_InitCurrentSlotPointer

AccPatch_ProcessSeqEvt_StorePos:
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
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
	ld	bc, 5:i3
	calr	AccPatch_ReadRingBufBytes
	cp	(13905:16), 0
	jr	nz, AccPatch_EventDispatch_NoteResolve
	calr	AccPatch_TransposeAndCopyNote
	jr	AccPatch_ContinueProcessing
AccPatch_EventDispatch_NoteResolve:
	calr AccPatch_ParseAndResolve
	calr AccPatch_CopyNoteStepsToSlots
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_EndMarker:
	call	TempoRingBuf_ReadByteToA
	calr	AccPatch_UpdatePlayback
	bit	1, (0x35ae:16)
	jr	nz, AccPatch_EventDispatch_AdvSlots
	calr	AccPatch_ScanToSequenceEnd
AccPatch_EventDispatch_AdvSlots:
	calr	AccPatch_AdvanceSlotCounters
	and	(0x35ae:16), 253
	jr	AccPatch_ContinueProcessing
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
	cpw (0x356e:16), 0x0000
	jr z, .Lc_f602be
	ld wa, (0x3566:16)
	ld (0x3662:16), wa
	ld wa, (0x3568:16)
	ld (0x3664:16), wa
	calr AccPatch_InitSlotAndCopyData
	calr AccPatch_AdvancePlayPos
	calr AccPatch_AdvanceAllSteps
	ldw (0x356e:16), 0x0000
AccPatch_UpdatePlayback_CheckQueue:
.Lc_f602be:
	cpw (0x3572:16), 0x0000
	jr z, AccPatch_UpdatePlayback_ClearStep
	calr AccPatch_DispatchQueuedNotes
AccPatch_UpdatePlayback_ClearStep:
	ld	(13667:16), 0
	ret
AccPatch_UpdatePlayback_ClearStep_Pad:
	nop
	nop

AccPatch_AdvanceSlotCounters:
	ld	xhl, 13694
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
	add	xhl, 6
	cp	xhl, 13742
	jr	nz, AccPatch_AdvSlotCtr_Loop
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
	popw	hl
	popw	bc
	ld	xiz, 13902
	ld	(xiz+hl), a
	inc	1, hl
	jr	AccPatch_ReadBuf_Loop
AccPatch_ReadBuf_Done:
	ret

AccPatch_ReadBuf_StoreAndNext_Pad:
	nop
	nop

AccPatch_ParseAndResolve:
	ld a, (0x364f:16)
	ld (0x365b:16), a
	ld (0x365c:16), a
	calr AccPatch_LookupStepByDrumParam
	cp (0x3563:16), 0x00
	jr z, AccPatch_ParseResolve_ParseHdr
	ld a, (0x3564:16)
	cp a, (0x365c:16)
	jr z, AccPatch_ParseResolve_IncStep
	calr AccPatch_UpdatePlayback
AccPatch_ParseResolve_ParseHdr:
	calr	AccPatch_ParseSequenceHeader
	ld	wa, (13686:16)
	ld	(13670:16), wa
	ld	wa, (13688:16)
	ld	(13672:16), wa
AccPatch_ParseResolve_IncStep:
	inc	1, (13667:16)
	ld	a, (13916:16)
	ld	(13668:16), a
	ret
AccPatch_ParseResolve_IncStep_Pad:
	nop
	nop

AccPatch_LookupStepByDrumParam:
	xor W,W
	ld IY,WA
	ld a, (0x343f:16)
	cp a, 0:i3
	jr z, AccPatch_SetStepDone
	ld WA,IY
	ld w, (0x343f:16)
	and W,0x07
	call DrumParam_Wrapper
	cp A,0x7f
	jr nz, AccPatch_LookupStep_StoreResult
	ld A, 0x00:opc
	ld (0x365c:16), a
	ld (0x364f:16), a
	bit 1, (0x35ae:16)
	jr nz, AccPatch_SetStepDone
	or (0x35ae:16), 0x02
	calr AccPatch_UpdatePlayback
	calr AccPatch_ScanToSequenceEnd
	jr t, AccPatch_SetStepDone
AccPatch_LookupStep_StoreResult:
	ld	(13916:16), a
	ld	(13903:16), a
AccPatch_SetStepDone:
	ret

AccPatch_SetStepDone_Pad:
	nop
	nop

AccPatch_CopyNoteStepsToSlots:
	ld	xhl, 13694
	xor	iy, iy
AccPatch_CopySteps_FindFreeSlot:
	bit	7, (xhl+iy)
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	ld	de, iy
	cpw	(0x3438:16), 0
	jr	z, AccPatch_CopySteps_Overflow
	ld	(0x3395:16), 0
	ld	(0x364e:16), 144
	bit	4, (0x36ff:16)
	jr	nz, AccPatch_CopySteps_StartFetch
	calr	AccPatch_TransposeNote
AccPatch_CopySteps_StartFetch:
	ld	a, (0x364e:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, (0x364f:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, (0x3650:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_UpdateSlotVoiceData
	calr	AccPatch_SeqAdvanceStep
	ld	a, (0x3651:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, 16:opc
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, 0:opc
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	bit	0, (0x3395:16)
	jr	z, AccPatch_CopyStepsDone
	ld	a, (0x3654:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, (0x3655:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	ld	(32422:16), 15
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	jr	AccPatch_CopyStepsDone
AccPatch_TransposeNote:
	ld	a, (13389:16)
	and	a, 15
	cp	a, 0:i3
	jr	z, AccPatch_Transpose_LookupTable
	calr	AccPatch_ReadTransposeAmount
	cp	a, (14770:16)
	jr	ugt, AccPatch_Transpose_AddBack
	sub	(13904:16), a
	jr	nc, AccPatch_Transpose_Done
	ld	a, 12:opc
	add	(13904:16), a
AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	ld	w, 12:opc
	sub	w, a
	add	(13904:16), w
AccPatch_Transpose_LookupTable:
	ld	xhl, 0:i3
	ld	l, (0x3650:16)
	add	xhl, AccPatch_Transpose_LookupTable_Data
	ld	a, (xhl)
	bit	4, (0x344e:16)
	jr	z, AccPatch_Transpose_CheckBit6
	ld	w, a
	ld	xhl, 0:i3
	ld	l, a
	add	xhl, AccPatch_Transpose_LookupTable_Data_2
	ld	l, (xhl)
	bit	0, l
	jr	z, AccPatch_Transpose_CheckBit6
	inc	1, w
	ld	a, (0x3650:16)
	inc	1, a
	ld	(0x3650:16), a
	ld	a, w
AccPatch_Transpose_CheckBit6:
	bit	6, (0x344e:16)
	jr	z, AccPatch_Transpose_CheckBit5
	bit	3, (0x36ff:16)
	jr	z, AccPatch_Transpose_CheckBit5
	jr	AccPatch_Transpose_SetDrumSplit
AccPatch_Transpose_CheckBit5:
	bit	5, (0x344e:16)
	jr	z, AccPatch_StoreDrumParams
	bit	3, (0x36ff:16)
	jr	nz, AccPatch_StoreDrumParams
AccPatch_Transpose_SetDrumSplit:
	cp	a, 7:i3
	jr	nz, AccPatch_StoreDrumParams
	ld	(13205:16), 1
	ld	(13908:16), 3
	ld	(13909:16), 0
	jr	AccPatch_StoreDrumParams_CheckSplit
AccPatch_StoreDrumParams:
	ld	xhl, 0:i3
	ld	l, a
	sll	a, 1
	add	l, a
	add	xhl, AccPatch_StoreDrumParams_Data
	ld	a, (xhl)
	ld	(13205:16), a
	ld	a, (xhl+1)
	ld	(13908:16), a
	ld	a, (xhl+2)
	ld	(13909:16), a
AccPatch_StoreDrumParams_CheckSplit:
	bit	0, (0x3395:16)
	jr	z, AccPatch_StoreDrumParams_Return
	ld	(0x364e:16), 145
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
; readers in v7 (address from the linked ELF): AccPatch_Transpose_LookupTable 0xF60470,
;     AccPatch_StoreDrumParams 0xF604D4
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	AccPatch_GetCurrentSlotAddr
	ld	a, (14079:16)
	ld	xix, 37
	bit	3, a
	jr	nz, AccPatch_SelectTranspose
	ld	xix, 45
	bit	0, a
	jr	nz, AccPatch_SelectTranspose
	ld	xix, 53
	bit	1, a
	jr	nz, AccPatch_SelectTranspose
	ld	xix, 61
AccPatch_SelectTranspose:
	add	xix, xiy
	ld	a, (xix)
	ld	(14770:16), a
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
AccPatch_FetchStepEntry:
	ld xiy, 13774

	ld hl, (13678:16)

	ld	(xiy+hl), a

	inc 1, hl

	ld (13678:16), hl

	ret



AccPatch_FetchStepData:
	ld	xiy, 13838
	ld	hl, (0x3572:16)
	ld	(xiy+hl), a
	inc	1, hl
	ld	(0x3572:16), hl
	ret
AccPatch_SeqAdvanceStep:
	ld wa, (0x3578:16)
	cp WA,0x00fe
	jr nz, AccPatch_SeqAdvStep_Increment
	cpw (0x3438:16), 0x0000
	jr z, AccPatch_SeqAdvStep_Return
	calr AccPatch_SeqAdvStep_WrapToNext
	jr t, AccPatch_SeqAdvStep_Return
AccPatch_SeqAdvStep_Increment:
	inc	1, wa
	ld	(13688:16), wa
AccPatch_SeqAdvStep_Return:
	ret

AccPatch_SeqAdvStep_WrapToNext:
	ld	hl, (13686:16)
	calr	AccPatch_GetEntryAddr
	ld	hl, (xix+3)
	cp	hl, 65535
	jr	z, AccPatch_SeqAdvStep_ScanFromStart
	jr	AccPatch_SeqAdvStep_StorePos
AccPatch_SeqAdvStep_ScanFromStart:
	ldw hl, 0x95

AccPatch_SeqAdvStep_ScanLoop:
	inc 1, hl
	calr AccPatch_GetEntryAddr
	bitm 7, (xix)
	jr z, AccPatch_SeqAdvStep_StorePos
	jr AccPatch_SeqAdvStep_ScanLoop

AccPatch_SeqAdvStep_StorePos:
	ld	(13686:16), hl
	ldw	(13688:16), 6
	ret
AccPatch_SeqAdvStep_StorePos_Pad:
	nop
	nop

AccPatch_UpdateSlotVoiceData:
	ld xhl, 13694

	ld iy, de

	or a, 0x80

	ld	(xhl+iy), a

	pushw iy

	inc 1, iy

	ld	(xhl+iy), 0x00

	ld a, (13915:16)

	inc 1, iy

	ld	(xhl+iy), a

	ld wa, (13686:16)

	inc 1, iy

	ld	(xhl+iy), wa

	ld wa, (13688:16)

	inc 2, iy

	ld	(xhl+iy), a

	popw iy

	ret



AccPatch_TransposeAndCopyNote:
	bit	4, (0x36ff:16)
	jr	nz, AccPatch_TransposeCopy_DoCopy
	calr	AccPatch_TransposeNote
AccPatch_TransposeCopy_DoCopy:
	ld xiy, 13902

	ld xix, 13838

	ld xbc, 0:i3

	ld bc, (13682:16)

	add xix, xbc

	ld bc, 6:i3

	ldir85

	; adddi16 0x360e, 6 (v7 patched)
	addw	(0x3572:16), 6
	ret



AccPatch_TransposeCopy_DoCopy_Pad:
	nop
	nop

AccPatch_ProcessMarkerEvent:
	cpw (0x3438:16), 0x0000
	jr z, AccPatch_ProcessMarker_Return
	ld a, (0x364e:16)
	cp A,0xd4
	jr nz, AccPatch_ProcessMarker_CheckD3
	ld A, 0xd3:opc
	jr t, AccPatch_FetchSequence
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
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, (13903:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
	ld	a, (13904:16)
	calr	AccPatch_FetchStepEntry
	calr	AccPatch_SeqAdvanceStep
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
	pushw	bc
	call	TempoRingBuf_ReadByteToA
	popw	bc
	dec	1, bc
	cp	bc, 0:i3
	jr	nz, -12	; -> 0xF6069F
	ret
	ldw	(13684:16), 0
AccPatch_SkipToMarker_Loop:
	ld	xix, 13838
	add	ix, (13684:16)
	calr	664
	ld	wa, (13684:16)
	add	wa, 6
	ld	(13684:16), wa
	cp	wa, (13682:16)
	jr	c, AccPatch_SkipToMarker_Loop	; -> 0xF606B2
	ldw	(13682:16), 0
	ret
AccPatch_InitSlotAndCopyData:
	ld xhl, 0:i3
	ld l, (0x343a:16)
	call AccPatch_GetCurrentSlotAddr
	and (XIY+0x0f),0x7f
	ld de, (0x3566:16)
	ld hl, (0x356a:16)
	ld (0x35bc:16), hl
	calr AccPatch_GetEntryAddr
	ld (0x35b4:16), xix
	ld wa, (0x356c:16)
	ld (0x35c2:16), wa
	ldw BC, 0x00fe
	sub BC,WA
	ld (0x3666:16), bc
	cp	bc, (0x356e:16)
	jr	nc, AccPatch_InitSlot_SameBlock
	jr	AccPatch_InitSlot_CrossBlock
AccPatch_InitSlot_SameBlock:
	ld	hl, (13674:16)
	ld	(13758:16), hl
	calr	AccPatch_GetEntryAddr
	ld	(13744:16), xix
	ld	wa, (13676:16)
	add	wa, (13678:16)
	ld	(13764:16), wa
	jr	AccPatch_InitSlot_StoreAddrs	; -> 0xF6074E
AccPatch_InitSlot_CrossBlock:
	calr	AccPatch_FindFreeEntrySlot
	ld	(13758:16), wa
	ld	hl, wa
	calr	AccPatch_GetEntryAddr
	ld	(13744:16), xix
	ld	wa, (13678:16)
	sub	wa, (13926:16)
	add	wa, 5
	ld	(13764:16), wa
AccPatch_InitSlot_StoreAddrs:
	ld	wa, (0x35be:16)
	ld	(0x356a:16), wa
	ld	wa, (0x35c4:16)
	ld	(0x356c:16), wa
	calr	AccPatch_CalcBlockCopySetup
	inc	1, ix
	ld	(0x3668:16), ix
	ld	hl, (0x3566:16)
	calr	AccPatch_GetEntryAddr
	ld	xwa, 0:i3
	ld	wa, (0x3568:16)
	add	xix, xwa
	ld	xiy, 13774
	ld	xbc, 0:i3
	ldw	bc, 254
	sub	bc, (0x3568:16)
	inc	1, bc
	cp	bc, (0x356e:16)
	jr	c, AccPatch_InitSlot_SplitCopy
	ld	xbc, 0:i3
	ld	bc, (0x356e:16)
	ldir85
	jr	AccPatch_InitSlot_Finalize
AccPatch_InitSlot_SplitCopy:
	ld	wa, bc
	ldir85
	ld	xbc, 0:i3
	ld	bc, (0x356e:16)
	sub	bc, wa
	ld	hl, (0x3566:16)
	calr	AccPatch_GetEntryAddr
	ld	hl, (xix+3)
	calr	AccPatch_GetEntryAddr
	add	xix, 6
	cp	bc, 0:i3
	jr	z, AccPatch_InitSlot_Finalize
	ldir85
AccPatch_InitSlot_Finalize:
	ld	wa, (13758:16)
	ld	(13670:16), wa
	ld	wa, (13928:16)
	ld	(13672:16), wa
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

	ld hl, (13674:16)

	pushw wa

	calr AccPatch_GetEntryAddr

	popw wa

	ld (xix + 3), wa

	pop xix

	ormi8 (xix), 0x80

	ld bc, (13674:16)

	ld (xix + 1), bc

	ldw (xix + 3), 0xffff

	decw 1, (13368:16)

	ret



AccPatch_FindFreeSlot_Found_Pad:
	nop
	nop

AccPatch_AdvancePlayPos:
	calr AccPatch_LoadTablePointers
	ld DE,(XIX)
	ld HL,(XIY)
	pushw de
	pushw hl
	calr AccPatch_GetEntryAddr
	popw hl
	popw de
	cp	hl, (0x3662:16)
	jr	z, AccPatch_AdvPlayPos_CheckDE
	cpw	(xix+1), 65535
	jr	nz, AccPatch_AdvPlayPos_AddAndCheck
	jr	AccPatch_StoreEntryPtr
AccPatch_AdvPlayPos_CheckDE:
	cp	de, (0x3664:16)
	jr	nc, AccPatch_AdvPlayPos_AddAndCheck
	jr	AccPatch_StoreEntryPtr
AccPatch_AdvPlayPos_AddAndCheck:
	add	de, (13678:16)
	cp	de, 254
	jr	z, AccPatch_AdvPlayPos_StoreDirect	; -> 0xF6084E
	jr	c, AccPatch_AdvPlayPos_StoreDirect	; -> 0xF6084E
	sub	de, 254
	pushw	de
	calr	AccPatch_GetEntryAddr
	ld	wa, (xix+3)
	pushw	wa
	calr	AccPatch_LoadTablePointers
	popw	wa
	popw	de
	ld	(xiy), wa
	add	de, 5
	ld	(xix), de
	jr	AccPatch_StoreEntryPtr	; -> 0xF60855
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
; readers in v7 (address from the linked ELF): AccPatch_LoadTablePointers 0xF600B9
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
; +0x00  7 zero bytes, not addressed by the reader
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; +0x07  17 x LE32 -> XIY (RAM addresses)
AccPatch_LoadTablePointers_Data:
	.long 0x00000000, 0x00003201, 0x00003203, 0x00000000
	.long 0x00003205, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031ff, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031fb
; +0x4B  17 x LE32 -> XIX (RAM addresses)
AccPatch_LoadTablePointers_Data_2:
	.long 0x00000000, 0x000031f1, 0x000031f3, 0x00000000
	.long 0x000031f5, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031ef, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031eb
AccPatch_AdvanceAllSteps:
	ld	xix, 13694
AccPatch_AdvAllSteps_Loop:
	bit	7, (xix+1)
	jr	z, AccPatch_AdvAllSteps_Next
	ld	bc, (0x356e:16)
AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz16 bc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	add	xix, 6
	cp	xix, 13742
	jr	c, AccPatch_AdvAllSteps_Loop
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
	ld	xix, 13838
AccPatch_DispatchQueued_Loop:
	calr	AccPatch_DispatchNoteToVoice
	add	xix, 6
	ld	xwa, xix
	sub	xwa, 13838
	cp	wa, (13682:16)
	jr	c, AccPatch_DispatchQueued_Loop	; -> 0xF60936
	ldw	(13682:16), 0
	ret
AccPatch_DispatchQueuedNotes_Pad:
	nop
	nop

AccPatch_DispatchNoteToVoice:
	ld	xhl, 13694
	ldw	iy, 42
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
	pushw DE
	pushw WA
	ld wa, (0x3576:16)
	ld (0x365e:16), wa
	ld wa, (0x3578:16)
	ld (0x3660:16), wa
	inc 1,IY
	ld	wa, (xhl+iy)
	ld	(0x3576:16), wa
	pushw	iy
	inc	2, iy
	xor	wa, wa
	ld	a, (xhl+iy)
	popw	iy
	ld	(0x3578:16), wa
	calr	AccPatch_SeqReadByte
	cp	a, (xix+2)
	jr	z, AccPatch_WriteVel_MatchFound
	popw	wa
	popw	de
	jr	AccPatch_WriteVel_RestorePos
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
	ld	wa, (13918:16)
	ld	(13686:16), wa
	ld	wa, (13920:16)
	ld	(13688:16), wa
	ret
AccPatch_WriteVel_RestorePos_Pad:
	nop
	nop

AccPatch_WriteSeqByte:
	push	xix
	ld	hl, (13686:16)
	calr	AccPatch_GetEntryAddr
	push	xwa
	ld	xwa, 0:i3
	ld	wa, (13688:16)
	add	xix, xwa
	pop	xwa
	ld	(xix), a
	pop	xix
	ret
AccPatch_WriteSeqByte_Pad:
	nop
	nop

AccPatch_CalcBlockCopySetup:
	ld	(32422:16), 0
	cp	de, (13756:16)
	jr	nz, AccPatch_CalcBlockCopy_DiffEntry	; -> 0xF60A5C
	ld	iy, (13762:16)
	sub	iy, 6
	inc	1, iy
	ld	(13768:16), iy
	ld	iy, (13762:16)
	ld	ix, (13764:16)
	sub	ix, 6
	inc	1, ix
	ld	(13770:16), ix
	ld	ix, (13764:16)
	calr	AccPatch_CalcBlockCopyBounds
	jr	AccPatch_CalcBlockCopy_Done	; -> 0xF60A81
AccPatch_CalcBlockCopy_DiffEntry:
	ld	wa, (0x35c4:16)
	cp	wa, (0x35c2:16)
	jr	ugt, AccPatch_CalcBlockCopy_Clamp
	jr	z, AccPatch_CalcBlockCopy_StoreIY
	jr	AccPatch_CalcBlockCopy_CheckIX
AccPatch_CalcBlockCopy_Clamp:
	calr AccPatch_CalcBlockCopy_Clamp_Helper
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_StoreIY:
	calr BlockCopy_SameEntry_Reverse
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_CheckIX:
	calr BlockCopy_IXFirst_Reverse

AccPatch_CalcBlockCopy_StoreIX:
	cp	(32422:16), 0
	jr	nz, AccPatch_CalcBlockCopy_Done
	calr	AccPatch_CalcBlockCopyBounds
AccPatch_CalcBlockCopy_Done:
	ret

AccPatch_CalcBlockCopy_Clamp_Helper:
	ld wa, (0x35c4:16)
	sub wa, (0x35c2:16)
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	ld xix, 0:i3
	ld xiy, 0:i3
	ld iy, (0x35c2:16)
	ld ix, (0x35c4:16)
	ld bc, (0x35c2:16)
	sub BC,0x0006
	inc 1,BC
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ac0
	jr t, DSP_SetupDone
BlockCopy_Rev_CheckSameEntry:
.Lc_f60ac0:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60ac8
	jr t, BlockCopy_Rev_StoreBounds
BlockCopy_Rev_CopyDiffEntry:
.Lc_f60ac8:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60adb
	jr t, DSP_SetupDone
BlockCopy_Rev_CopyRemainder:
.Lc_f60adb:
	ld bc, (0x35ba:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ac0
	jr t, DSP_SetupDone
BlockCopy_Rev_StoreBounds:
	ld	wa, (13752:16)
	ld	(13770:16), wa
	ldw	bc, 255
	sub	bc, 6
	ld	(13768:16), bc
DSP_SetupDone:
	ret

DSP_BlockCopyReverse:
	push xwa

	push xhl

	and xiy, 0xff

	and xix, 0xff

	ld xwa, (13744:16)

	ld xhl, (13748:16)

	push xwa

	push xhl

	add xwa, xix

	ld xix, xwa

	add xhl, xiy

	ld xiy, xhl

	lddr85

	pop xhl

	pop xwa

	ld (13748:16), xhl

	ld (13744:16), xwa

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

	ld xwa, (13744:16)

	ld xhl, (13748:16)

	push xwa

	push xhl

	add xwa, xix

	ld xix, xwa

	add xhl, xiy

	ld xiy, xhl

	ldir85

	pop xhl

	pop xwa

	ld (13748:16), xhl

	ld (13744:16), xwa

	and xiy, 0xff

	and xix, 0xff

	pop xhl

	pop xwa

	ret



BlockCopy_SameEntry_Reverse:
	ld bc, (0x35c2:16)
	sub BC,0x0006
	inc 1,BC
	ld iy, (0x35c2:16)
	ld ix, (0x35c4:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60b99
	jr t, DSP_NullRet
BlockCopy_SameEntry_AdvIY:
.Lc_f60b99:
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ba5
	jr t, DSP_NullRet
BlockCopy_SameEntry_CheckDE:
.Lc_f60ba5:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60bad
	jr t, BlockCopy_SameEntry_StoreBounds
BlockCopy_SameEntry_FullCopy:
.Lc_f60bad:
	ldw BC, 0x00ff
	sub BC,0x0006
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60bc3
	jr t, DSP_NullRet
BlockCopy_SameEntry_AdvIYLoop:
.Lc_f60bc3:
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ba5
	jr t, DSP_NullRet
BlockCopy_SameEntry_StoreBounds:
	ldw	bc, 255
	sub	bc, 6
	ld	(13770:16), bc
	ld	(13768:16), bc
DSP_NullRet:
	ret

BlockCopy_IXFirst_Reverse:
	ld wa, (0x35c2:16)
	sub wa, (0x35c4:16)
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	ld xix, 0:i3
	ld xiy, 0:i3
	ld iy, (0x35c2:16)
	ld ix, (0x35c4:16)
	ld bc, (0x35c4:16)
	sub BC,0x0006
	inc 1,BC
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60c1d
	jr t, DSP_NullRet2
BlockCopy_IXFirst_CopyOffset:
.Lc_f60c1d:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60c30
	jr t, DSP_NullRet2
BlockCopy_IXFirst_CheckDE:
.Lc_f60c30:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60c38
	jr t, BlockCopy_IXFirst_StoreBounds
BlockCopy_IXFirst_CopyRemainder:
.Lc_f60c38:
	ld bc, (0x35ba:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60c4b
	jr t, DSP_NullRet2
BlockCopy_IXFirst_CopyOffset2:
.Lc_f60c4b:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyReverse
	calr AccPatch_AdvanceNextEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60c30
	jr t, DSP_NullRet2
BlockCopy_IXFirst_StoreBounds:
	ld	wa, (13754:16)
	ld	(13770:16), wa
	ldw	wa, 255
	sub	wa, 6
	ld	(13768:16), wa
DSP_NullRet2:
	ret

AccPatch_CalcBlockCopyBounds:
	ld	wa, (13672:16)
	sub	wa, 6
	ld	bc, (13768:16)
	sub	bc, wa
	ld	(13772:16), bc
	cp	(13770:16), bc
	jr	nc, BlockCopyBounds_UseBC	; -> 0xF60C8C
	jr	BlockCopyBounds_UseSmaller	; -> 0xF60C91
BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	ld	bc, (0x35ca:16)
	calr	DSP_BlockCopyReverse
	calr	AccPatch_AdvanceNextEntry_IX
	cp	(0x7ea6:16), 0
	jr	z, BlockCopyBounds_CopyRemainder
	jr	BlockCopyBounds_Return
BlockCopyBounds_CopyRemainder:
	; ldw_d16 xbc, (0x3668) (v7 patched)
	ld	bc, (0x35cc:16)
	; subda16 xbc, 0x3666 (v7 patched)
	sub	bc, (0x35ca:16)
	; calr DSP_BlockCopyReverse (v7 displacement)
	calr	DSP_BlockCopyReverse
BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	push XIX
	ld xiy, (0x35b4:16)
	ld HL,(XIY+0x01)
	ld (0x35bc:16), hl
	calr AccPatch_GetEntryAddr
	bit	7, (xix+0:8)
	jr	nz, AdvNextEntry_IY_StoreAndReset
	ld	(0x7ea6:16), 11
	jr	AdvNextEntry_IY_Return
AdvNextEntry_IY_StoreAndReset:
	ld	(13748:16), xix
	ld	xiy, 0:i3
	ldw	iy, 254
AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	ld xix, (0x35b0:16)
	ld HL,(XIX+0x01)
	ld (0x35be:16), hl
	calr AccPatch_GetEntryAddr
	bit	7, (xix+0:8)
	jr	nz, AdvNextEntry_IX_StoreAndReset
	ld	(0x7ea6:16), 11
	jr	AdvNextEntry_IX_Return
AdvNextEntry_IX_StoreAndReset:
	ld	(13744:16), xix
	ld	xix, 0:i3
	ldw	ix, 254
AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	ld (0x7ea6:16), 0x00
	ld hl, (0x35bc:16)
	calr AccPatch_GetEntryAddr
	ld (0x35b4:16), xix
	cp	de, (0x35bc:16)
	jr	nz, BlockCopyDisp_CompareOffsets
	ld	xiy, 0:i3
	ldw	iy, 255
	sub	iy, (0x35c2:16)
	ld	(0x35c8:16), iy
	ld	iy, (0x35c2:16)
	ld	xix, 0:i3
	ldw	ix, 255
	sub	ix, (0x35c4:16)
	ld	(0x35ca:16), ix
	ld	ix, (0x35c4:16)
	calr	AccPatch_ForwardBlockCopy
	jr	BlockCopyDisp_Return
BlockCopyDisp_CompareOffsets:
	ld	wa, (0x35c4:16)
	cp	wa, (0x35c2:16)
	jr	c, BlockCopyDisp_IXSmaller
	jr	z, BlockCopyDisp_Equal
	jr	ugt, BlockCopyDisp_IXLarger
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
	cp	(32422:16), 0
	jr	nz, BlockCopyDisp_Return
	calr	AccPatch_ForwardBlockCopy
BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	ldw WA, 0x00ff
	sub wa, (0x35c4:16)
	ldw BC, 0x00ff
	sub bc, (0x35c2:16)
	sub WA,BC
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	ld xiy, 0:i3
	ld iy, (0x35c2:16)
	ld xix, 0:i3
	ld ix, (0x35c4:16)
	ldw BC, 0x00ff
	sub bc, (0x35c2:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60da2
	jr t, DSP_CopyDone
BlockCopy_FwdIYSmall_CheckDE:
.Lc_f60da2:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60daa
	jr t, BlockCopy_FwdIYSmall_StoreBounds
BlockCopy_FwdIYSmall_CopyOffset:
.Lc_f60daa:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60dbd
	jr t, DSP_CopyDone
BlockCopy_FwdIYSmall_CopyRem:
.Lc_f60dbd:
	ld bc, (0x35ba:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60da2
	jr t, DSP_CopyDone
BlockCopy_FwdIYSmall_StoreBounds:
	ld	wa, (13752:16)
	ld	(13770:16), wa
	ldw	bc, 255
	sub	bc, 6
	ld	(13768:16), bc
DSP_CopyDone:
	ret

BlockCopy_FwdEqual:
	ldw BC, 0x00ff
	sub bc, (0x35c2:16)
	ld xiy, 0:i3
	ld iy, (0x35c2:16)
	ld xix, 0:i3
	ld ix, (0x35c4:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60e06
	jr t, AccPatch_NullRet2
BlockCopy_FwdEqual_AdvIX:
.Lc_f60e06:
	calr AccPatch_AdvancePrevEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60e12
	jr t, AccPatch_NullRet2
BlockCopy_FwdEqual_CheckDE:
.Lc_f60e12:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60e1a
	jr t, BlockCopy_FwdEqual_StoreBounds
BlockCopy_FwdEqual_FullCopy:
.Lc_f60e1a:
	ldw BC, 0x00ff
	sub BC,0x0006
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60e30
	jr t, AccPatch_NullRet2
BlockCopy_FwdEqual_AdvIXLoop:
.Lc_f60e30:
	calr AccPatch_AdvancePrevEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60e12
	jr t, AccPatch_NullRet2
BlockCopy_FwdEqual_StoreBounds:
	ldw	bc, 255
	sub	bc, 6
	ld	(13770:16), bc
	ld	(13768:16), bc
AccPatch_NullRet2:
	ret

BlockCopy_FwdIXSmaller:
	ldw WA, 0x00ff
	sub wa, (0x35c2:16)
	ldw BC, 0x00ff
	sub bc, (0x35c4:16)
	sub WA,BC
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	ld xiy, 0:i3
	ld iy, (0x35c2:16)
	ld xix, 0:i3
	ld ix, (0x35c4:16)
	ldw BC, 0x00ff
	sub bc, (0x35c4:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60e8f
	jr t, AccPatch_NullRet3
BlockCopy_FwdIXSmall_CopyOff:
.Lc_f60e8f:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ea2
	jr t, AccPatch_NullRet3
BlockCopy_FwdIXSmall_CheckDE:
.Lc_f60ea2:
	cp de, (0x35bc:16)
	jr nz, .Lc_f60eaa
	jr t, BlockCopy_FwdIXSmall_StoreBounds
BlockCopy_FwdIXSmall_CopyRem:
.Lc_f60eaa:
	ld bc, (0x35ba:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IX
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ebd
	jr t, AccPatch_NullRet3
BlockCopy_FwdIXSmall_CopyOff2:
.Lc_f60ebd:
	ld bc, (0x35b8:16)
	calr DSP_BlockCopyForward
	calr AccPatch_AdvancePrevEntry_IY
	cp (0x7ea6:16), 0x00
	jr z, .Lc_f60ea2
	jr t, AccPatch_NullRet3
BlockCopy_FwdIXSmall_StoreBounds:
	ld	wa, (13754:16)
	ld	(13770:16), wa
	ldw	wa, 255
	sub	wa, 6
	ld	(13768:16), wa
AccPatch_NullRet3:
	ret

AccPatch_ForwardBlockCopy:
	cp	(0x7ea6:16), 0
	jr	nz, AccPatch_DoneBlockCopy
	ldw	wa, 254
	sub	wa, (0x35c6:16)
	ld	bc, (0x35c8:16)
	sub	bc, wa
	ld	(0x35cc:16), bc
	cp	(0x35ca:16), bc
	jr	nc, FwdBlockCopy_UseFull
	jr	FwdBlockCopy_UseSmaller
FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	ld	bc, (0x35ca:16)
	calr	DSP_BlockCopyForward
	calr	AccPatch_AdvancePrevEntry_IX
	cp	(0x7ea6:16), 0
	jr	z, FwdBlockCopy_CopyRemainder
	jr	AccPatch_DoneBlockCopy
FwdBlockCopy_CopyRemainder:
	; ldw_d16 xbc, (0x3668) (v7 patched)
	ld	bc, (0x35cc:16)
	; subda16 xbc, 0x3666 (v7 patched)
	sub	bc, (0x35ca:16)
	; calr DSP_BlockCopyForward (v7 displacement)
	calr	DSP_BlockCopyForward
AccPatch_DoneBlockCopy:
	ret

AccPatch_AdvancePrevEntry_IX:
	ld xix, (0x35b0:16)
	ld HL,(XIX+0x03)
	ld (0x35be:16), hl
	calr AccPatch_GetEntryAddr
	bit 7,(XIX)
	jr nz, AdvPrevEntry_IX_StoreAndReset
	ld (0x7ea6:16), 0x0b
	jr t, AdvPrevEntry_IX_Return
AdvPrevEntry_IX_StoreAndReset:
	ld	(13744:16), xix
	ld	xix, 0:i3
	ld	ix, 6:i3
AdvPrevEntry_IX_Return:
	ret

AccPatch_AdvancePrevEntry_IY:
	push XIX
	ld xix, (0x35b4:16)
	ld HL,(XIX+0x03)
	ld (0x35bc:16), hl
	calr AccPatch_GetEntryAddr
	bit 7,(XIX)
	jr nz, AdvPrevEntry_IY_StoreAndReset
	ld (0x7ea6:16), 0x0b
	jr t, AdvPrevEntry_IY_Return
AdvPrevEntry_IY_StoreAndReset:
	ld	(13748:16), xix
	ld	xiy, 0:i3
	ld	iy, 6:i3
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
	and (0x3434:16), 0xef
	ld a, (0x36ff:16)
	and A,0x7f
	cp	a, (0x3474:16)
	jr	z, AccPlayback_CheckStyleMatch
	and	a, 31
	cp	a, 0:i3
	jr	z, AccPlayback_CheckStyleMatch
	or	(0x3434:16), 16
AccPlayback_CheckStyleMatch:
	ld	a, (35994:16)
	cp	a, 182
	jr	z, AccPlayback_CheckActiveStyle
	jrl	AccPlayback_Finalize
AccPlayback_CheckActiveStyle:
	cp	a, (0x3489:16)
	jr	z, AccPlayback_CheckBit4
	ld	(0x3461:16), 0
	call	TempoRingBuf_Init
	bit	0, (0x31e7:16)
	jr	nz, AccPlayback_GetSlotAddr
	or	(0x3431:16), 128
AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride
AccPlayback_CheckBit4:
	bit	4, (0x3434:16)
	jr	nz, AccPlayback_InitTimingVars
	ld	a, (13449:16)
	cp	a, 182
	jr	z, AccPlayback_InitOrUpdate_Skip
AccPlayback_InitTimingVars:
	ld	a, 0:opc
	ld	(13406:16), a
	ld	(13408:16), a
	ld	(13407:16), a
	ld	(13994:16), a
	ldw	(13995:16), 1
	calr	AccPlayback_CalcTimingPosition
	call	AccPatch_GetCurrentSlotAddr
	call	AccPatch_ScanToSequenceStart
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	(13446:16), 0
AccPlayback_CheckStateFlags:
	and	(0x3433:16), 127
AccPlayback_InitOrUpdate_Skip:
	and	(0x3434:16), 254
	ld	a, (13943:16)
	and	a, 192
	cp	a, 0:i3
	jr	z, AccPlayback_InitOrUpdate_Skip2
	or	(0x3434:16), 1
	calr	AccPlayback_AdjustBeatPosition
	calr	AccPlayback_CalcTimingPosition
	call	AccPatch_GetCurrentSlotAddr
	calr	AccVoice_InitPatternBuffer
AccPlayback_CheckSkipInit:
	or	(0xe31a:16), 16
AccPlayback_InitOrUpdate_Skip2:
	bit	4, (0x3434:16)
	jr	nz, AccPlayback_ApplyChanges
	bit	0, (0x3434:16)
	jr	nz, AccPlayback_ApplyChanges
	ld	a, (13449:16)
	cp	a, 182
	jr	z, AccPlayback_CheckBit0_3
AccPlayback_ApplyChanges:
	; anddi8 (0x34d0), 223 (v7 patched)
	and	(0x3434:16), 223
	; calr AccPlayback_ProcessStyleChanges (v7 displacement)
	calr	AccPlayback_ProcessStyleChanges
	; anddi8 (0x34d0), 254 (v7 patched)
	and	(0x3434:16), 254
	; anddi8 (0x3713), 63 (v7 patched)
	and	(0x3677:16), 63
AccPlayback_CheckBit0_3:
	ld	a, (0x3677:16)
	and	a, 3
	cp	a, 0:i3
	jr	z, AccPlayback_ProcessMiscFlags
	calr	AccPlayback_ProcessPartChanges
	and	(0x3677:16), 252
AccPlayback_ProcessMiscFlags:
	ld	a, (0x3691:16)
	and	a, 63
	cp	a, 0:i3
	jr	z, AccPlayback_RunPeriodicTasks
	calr	AccPlayback_ProcessVoiceType5
	and	(0x3691:16), 192
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
	add xhl, 0x95c00
	ret

ToneGen_CalcBufferAddr_Pad:
	nop
	nop

AccPlayback_CalcTimingPosition:
	ld a, (0x345e:16)
	inc 1,A
	xor W,W
	ld (0x367e:16), wa
	calr ToneGen_StepFwd_Alternate
	jr t, AccTiming_ComputeOffset
	ld A, 0x20:opc
	cp (0x345f:16), 0x04
	jr c, AccTiming_StorePartA
AccTiming_StorePartA:
	ld	(13952:16), a
AccTiming_ComputeOffset:
	ld	w, (13407:16)
	ld	a, 8:opc
	muls	wa, w
	ld	h, a
	ld	a, (13408:16)
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	add	h, a
	inc	1, h
	ld	a, (13406:16)
	sub	a, (13994:16)
	ld	w, 32:opc
	cp	(13373:16), 5
	jr	c, AccTiming_UseFullBar
	ld	w, 64:opc
AccTiming_UseFullBar:
	muls	wa, w
	add	h, a
	ld	(13939:16), h
	jr	AccTiming_CompareStyles
	cp	h, 32
	jr	ule, 3
	sub	h, 32
AccTiming_StoreResult:
	ld	(13939:16), h
AccTiming_CompareStyles:
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, AccTiming_Return
AccTiming_Return:
	ret

AccTiming_CompareStyles_Pad:
	nop
	nop

AccPlayback_AdjustBeatPosition:
	ld	wa, (0x367e:16)
	dec	1, a
	bit	7, (0x3677:16)
	jr	z, AccBeatAdj_CheckBit6
	inc	1, a
	cp	a, (0x343b:16)
	jr	ule, AccBeatAdj_CheckBit6
	ld	a, 0:opc
AccBeatAdj_CheckBit6:
	bit	6, (0x3677:16)
	jr	z, AccBeatAdj_StoreAndClear
	dec	1, a
	cp	a, 255
	jr	nz, AccBeatAdj_StoreAndClear
	ld	a, (0x343b:16)
AccBeatAdj_StoreAndClear:
	ld	(13406:16), a
	ld	(13408:16), 0
	ld	(13407:16), 0
	ret
AccBeatAdj_StoreAndClear_Pad:
	nop
	nop

AccVoice_InitPatternBuffer:
	ld XHL,0x00003692
	ld wa, 0:i3
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call AccAudio_LockAcquire
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	ld (XHL),WA
	ld (XHL+0x02),WA
	ld (XHL+0x04),WA
	ld (XHL+0x06),WA
	ld (XHL+0x08),WA
	ld (XHL+0x0a),WA
	ld (XHL+0x0c),WA
	ld (XHL+0x0e),WA
	calr AccPlayback_InitPartAssignment
	ld a, (0x36aa:16)
	ld w, (0x343d:16)
	muls	wa, w
	ld	c, a
	jr	ToneGen_SkipToNoteEntry
	ld	a, (13406:16)
	ld	w, (13373:16)
	muls	wa, w
	ld	c, a
	cp	(13373:16), 5
	jr	c, ToneGen_SkipToNoteEntry
	cp	(13407:16), 4
	jr	c, ToneGen_SkipToNoteEntry
	add	c, 4
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
	ld	(13426:16), 0
	ld	c, (13986:16)
	calr	ToneGen_ParseEventBuffer
	inc	1, (13426:16)
	ld	c, (13987:16)
	calr	ToneGen_ParseEventBuffer
	inc	1, (13426:16)
	ld	c, (13988:16)
	calr	ToneGen_ParseEventBuffer
	inc	1, (13426:16)
	ld	c, (13989:16)
	calr	ToneGen_ParseEventBuffer
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, ToneGen_SaveRegsAndCall
	ld	(58138:16), 16
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
	ld	(13427:16), 0
EventBuffer_ParseLoop:
	cp c, 0:i3
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	ld	a, (xix)
	cp	a, 129
	jr	nz, EventBuffer_CheckNoteType
	dec	1, c
	inc	1, (13427:16)
	calr	ToneGen_ReadBufferWithIndirection
	jr	EventBuffer_ParseLoop
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
	ld	(16:8), 32:io
	.byte 0x40, 0x80

ToneGen_MapNote_OrMask:
	ld l, (13427:16)

	xor h, h

	ld a, (13426:16)

	and a, 0x3

	sla a, 2

	add l, a

	ld xix, 13970

	ld	a, (xix+hl)

	or a, c

	ld	(xix+hl), a

	pop xix

	popw bc

	; calr ToneGen_ReadBufferWithIndirection (v7 displacement)
	calr	ToneGen_ReadBufferWithIndirection
	; jrl EventBuffer_ParseLoop (v7 displacement)
	jrl	EventBuffer_ParseLoop
ToneGen_ParseEvent_Done:
	ret

ToneGen_MapNote_OrMask_Pad:
	nop
	nop

AccPlayback_ProcessStyleChanges:
	ld	(13939:16), 1
	ld	(13942:16), 4
	ld	(13947:16), 255
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16355565
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ld	a, 0:opc
	ld	(13403:16), a
	ld	(13407:16), a
	ld	(13408:16), a
	ld	wa, (13950:16)
	dec	1, a
	ld	(13406:16), a
	call	AccPatch_GetCurrentSlotAddr
	calr	AccPlayback_CalcTimingPosition
	calr	AccVoice_InitPatternBuffer
	ret
AccStyleChange_CheckPartCount:
	nop
	nop

AccPlayback_ProcessPartChanges:
	and	(0x3486:16), 115
	cp	(0x3460:16), 0
	jr	nz, AccPartChange_Bit1
	or	(0x3486:16), 4
AccPartChange_Bit1:
	bit	0, (0x3677:16)
	jr	nz, AccPartChange_CheckBit2
	calr	ToneGen_ProcessWithRestore
	jrl	ToneGen_UpdateAndInitPattern
AccPartChange_CheckBit2:
	bit	5, (0x3434:16)
	jr	z, AccPartChange_Done
	calr	ToneGen_ScanRestoredVoiceEvents
	jr	AccPartChange_ProcessBit2
AccPartChange_Done:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots

AccPartChange_ProcessBit2:
	calr ToneGen_CalcNoteWithWrap
	cp bc, wa
	jr ugt, AccPartChange_StoreResult
	jr ToneGen_CalcAndRestart_Join

AccPartChange_StoreResult:
	; anddi8 (0x34d0), 223 (v7 patched)
	and	(0x3434:16), 223
ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

ToneGen_CalcAndRestart_Join:
	ld	wa, (0x33cf:16)
	ld	(0x3478:16), wa
	ld	wa, (0x33ad:16)
	ld	(0x3476:16), wa
	or	(0x3434:16), 32
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	a, 129
	jr	nz, ToneGen_PushAndReadType
	calr	ToneGen_StepToNextVoiceSlot
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	a, 144
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 145
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 209
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 210
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 211
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 212
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 213
	jr	z, ToneGen_ProcessVoiceEvent
	cp	a, 214
	jr	z, ToneGen_ProcessVoiceEvent
	jr	ToneGen_CalcAndRestart
ToneGen_ProcessVoiceEvent:
	calr	AccVoice_ReadCurrentToneType
	cp	a, 0:i3
	jr	nz, ToneGen_CalcAndRestart	; -> 0xF61356
	ld	wa, (13263:16)
	ld	(13432:16), wa
	ld	wa, (13229:16)
	ld	(13430:16), wa
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (13229:16)
	ld	a, (xhl+wa)
	pushw	wa
	push	xhl
	calr	ToneGen_AdvancePeriodWrap
	pop	xhl
	popw	wa
ToneGen_PushAndReadType:
	pushw	wa
	calr	AccVoice_ReadCurrentToneType
	ld	w, a
	ld	(13408:16), w
	popw	wa
	calr	ToneGen_ClassifyAndDispatch
ToneGen_UpdateAndInitPattern:
	; anddi8 (0x34cf), 127 (v7 patched)
	and	(0x3433:16), 127
	; calr AccPlayback_CalcTimingPosition (v7 displacement)
	calr	AccPlayback_CalcTimingPosition
	; call AccPatch_GetCurrentSlotAddr (v7 addr)
	call	AccPatch_GetCurrentSlotAddr
	; calr AccVoice_InitPatternBuffer (v7 displacement)
	calr	AccVoice_InitPatternBuffer
	; ordi8 0xe3e0, 16 (v7 patched)
	or	(0xe31a:16), 16
	ret



ToneGen_VoiceSlotLookupTable:
	.byte	0x00, 0x00
ToneGen_ClassifyMono_MapChannel_Data:	.byte	0x00, 0x94, 0x95, 0x00, 0x96, 0x00
	.byte 0x00, 0x00, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x98

ToneGen_ProcessWithRestore:
	bit	5, (13364:16)
	jr	z, ToneGen_ProcessRestore_Direct
	calr	ToneGen_RestoreFromSavedPos
	jr	ToneGen_ProcessRestore_CalcPos
ToneGen_ProcessRestore_Direct:
	.byte 0x1d, 0x86, 0xe9, 0xf5	; call AccPatch_GetCurrentSlotAddr (v7 addr)

	.byte 0x1e, 0x53, 0x08	; calr ToneGen_ProcessVoiceSlots (v7 displacement)

	.byte 0xc1, 0x86, 0x34, 0x3c, 0xfe	; anddi8 (0x3522), 254 (v7 patched)



ToneGen_ProcessRestore_CalcPos:
	calr	ToneGen_CalcNotePosition
	ld	bc, (13444:16)
	cp	bc, wa
	jr	c, ToneGen_ProcessRestore_CheckDelta
	sub	bc, wa
	cp	bc, 512
	jr	ugt, ToneGen_ProcessRestore_CheckDelta
	jr	ToneGen_ProcessRestore_UseSaved
ToneGen_ProcessRestore_CheckDelta:
	cp	bc, 0:i3
	jr	nz, ToneGen_ProcessRestore_ClearBit5
	bit	3, (0x3486:16)
	jr	z, ToneGen_ProcessRestore_ClearBit5
	jr	ToneGen_ProcessRestore_UseSaved
ToneGen_ProcessRestore_ClearBit5:
	; anddi8 (0x34d0), 223 (v7 patched)
	and	(0x3434:16), 223
ToneGen_ProcessRestore_CalcNote:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	cp	w, 0:i3
	jr	nz, ToneGen_ProcessRestore_AdjNote
	ld	w, 12:opc
ToneGen_ProcessRestore_AdjNote:
	calr	ToneGen_AdjustNoteWrap
	ld	a, 4:opc
	ld	(13942:16), a
	ld	w, 255:opc
	ld	(13947:16), 255
	jr	ToneGen_ProcessRestore_Return
ToneGen_ProcessRestore_UseSaved:
	bit	0, (0x3486:16)
	jr	nz, ToneGen_ProcessRestore_UseActive
	ld	wa, (0x347e:16)
	ld	(0x3478:16), wa
	ld	(0x33cf:16), wa
	ld	wa, (0x3482:16)
	ld	(0x3476:16), wa
	ld	(0x33ad:16), wa
	jr	ToneGen_ProcessRestore_SetBit5
ToneGen_ProcessRestore_UseActive:
	ld	wa, (13263:16)
	ld	(13432:16), wa
	ld	wa, (13229:16)
	ld	(13430:16), wa
ToneGen_ProcessRestore_SetBit5:
	or	(0x3434:16), 32
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+wa)
	cp	a, 129
	jr	nz, ToneGen_ProcessRestore_ReadType
	bit	7, (0x3433:16)
	jr	z, ToneGen_ProcessRestore_JumpCalc
	and	(0x3434:16), 223
	and	(0x3433:16), 127
ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	pushw	wa
	calr	AccVoice_ReadCurrentToneType
	ld	w, (13408:16)
	sub	w, a
	jr	nc, ToneGen_ProcessRestore_WrapOctave
	add	w, 96
ToneGen_ProcessRestore_WrapOctave:
	ld	e, (13408:16)
	calr	ToneGen_AdjustNoteWrap
	popw	wa
	calr	ToneGen_ClassifyAndDispatch
ToneGen_ProcessRestore_Return:
	ret

ToneGen_ProcessRestore_WrapOctave_Pad:
	nop
	nop

ToneGen_RestoreFromSavedPos:
	ld	iy, (0x3476:16)
	ld	(0x33ad:16), iy
	ld	wa, (0x3478:16)
	ld	(0x33cf:16), wa
	ld	a, 0:opc
	ld	(0x3399:16), a
	and	(0x3486:16), 253
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	a, 129
	jr	nz, ToneGen_EventDispatchLoop
	or	(0x3486:16), 2
	and	(0x3486:16), 251
ToneGen_EventDispatchLoop:
	calr	ToneGen_StepVoiceForward
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (13229:16)
	ld	a, (xhl+wa)
	bit	7, a
	jr	z, ToneGen_EventDispatchLoop	; -> 0xF61537
	cp	a, 129
	jrl	z, ToneGen_Velocity_HandleEnd	; -> 0xF615D6
	cp	a, 131
	jr	z, ToneGen_EventDisp_EndOfBlock	; -> 0xF61584
	cp	a, 144
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 145
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 209
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 210
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 211
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 212
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 213
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	cp	a, 214
	jr	z, ToneGen_CalcEventVelocity_WithFlags	; -> 0xF6159F
	jr	ToneGen_EventDispatchLoop	; -> 0xF61537
ToneGen_EventDisp_EndOfBlock:
	call	AccPatch_GetCurrentSlotAddr
	calr	ToneGen_GetSlotIndex
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	ix, 6:i3
	ld	(13229:16), ix
	ld	(13209:16), 6
	jr	ToneGen_EventDispatchLoop
ToneGen_CalcEventVelocity_WithFlags:
	calr	AccVoice_ReadCurrentToneType
	ld	c, a
	ld	b, (0x345f:16)
	bit	1, (0x3486:16)
	jr	z, ToneGen_Velocity_SkipDec
	dec	1, b
	cp	b, 255
	jr	nz, ToneGen_Velocity_SkipDec
	ld	b, (0x343d:16)
	dec	1, b
	ld	a, (0x343d:16)
	ld	w, (0x345e:16)
	dec	1, w
	cp	w, 255
	jr	nz, ToneGen_Velocity_Multiply
	ld	w, (0x343b:16)
ToneGen_Velocity_Multiply:
	muls wa, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	bit	7, (0x3486:16)
	jr	nz, VoiceVelocity_CalcDone
	bit	2, (0x3486:16)
	jr	z, ToneGen_Velocity_DefaultCalc
	or	(0x3486:16), 2
	or	(0x3486:16), 128
	jrl	ToneGen_EventDispatchLoop
ToneGen_Velocity_DefaultCalc:
	ld	c, 0:opc
	ld	b, (13407:16)
	dec	1, b
	cp	b, 255
	jr	nz, VoiceVelocity_CalcDone
	ld	b, (13373:16)
	dec	1, b
VoiceVelocity_CalcDone:
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls	wa, w
	add	b, a
ToneGen_Velocity_Store:
	; stda16 (0x3520), xbc (v7 patched)
	ld	(0x3484:16), bc
	; ordi8 0x3522, 1 (v7 patched)
	or	(0x3486:16), 1
	ret



ToneGen_Velocity_Store_Pad:
	nop
	nop

ToneGen_CalcNotePosition:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	ld	d, (13407:16)
	ld	bc, wa
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls	wa, w
	add	d, a
	ld	wa, bc
	cp	w, 0:i3
	jr	nz, ToneGen_CalcPos_SubOctave
	ld	w, 12:opc
ToneGen_CalcPos_SubOctave:
	ld	a, e
	sub	a, w
	jr	nc, ToneGen_CalcPos_Return
	add	a, 96
	dec	1, d
	cp	d, 255
	jr	nz, ToneGen_CalcPos_Return
	ld	d, (0x343d:16)
	dec	1, d
	or	(0x3486:16), 8
ToneGen_CalcPos_Return:
	ld w, d
	ret

ToneGen_CalcPos_SubOctave_Pad:
	nop
	nop

ToneGen_AdjustNoteWrap:
	ld	a, e
	sub	a, w
	jr	c, ToneGen_AdjWrap_AddOctave
	ld	(13408:16), a
	jr	SustainLevel_SetExit
ToneGen_AdjWrap_AddOctave:
	add	a, 96
	ld	(13408:16), a
	ld	a, (13407:16)
	dec	1, a
	cp	a, 255
	jr	z, ToneGen_AdjWrap_WrapBar
	ld	(13407:16), a
	jr	SustainLevel_SetExit
ToneGen_AdjWrap_WrapBar:
	ld	a, (13373:16)
	dec	1, a
	ld	(13407:16), a
	ld	a, (13406:16)
	dec	1, a
	cp	a, 255
	jr	z, ToneGen_AdjWrap_WrapMeasure
	ld	(13406:16), a
	jr	SustainLevel_SetExit
ToneGen_AdjWrap_WrapMeasure:
	ld	a, (13371:16)
	and	a, 7
	ld	(13406:16), a
SustainLevel_SetExit:
	ret

SustainLevel_SetExit_Pad:
	nop
	nop

ToneGen_ScanRestoredVoiceEvents:
	ld	iy, (13430:16)
	ld	(13229:16), iy
	ld	wa, (13432:16)
	ld	(13263:16), wa
	ld	a, 0:opc
	ld	(13209:16), a
ToneGen_ScanRestored_Loop:
	calr	ToneGen_StepToNextVoiceSlot
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (13229:16)
	ld	a, (xhl+wa)
	cp	a, 129
	jrl	z, ToneGen_ScanRestored_EndMarker	; -> 0xF6173D
	cp	a, 131
	jr	z, ToneGen_ScanRestored_EndBlock	; -> 0xF6170B
	cp	a, 144
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 145
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 209
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 210
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 211
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 212
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 213
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	cp	a, 214
	jr	z, ToneGen_CalcEventVelocity_Restored	; -> 0xF61726
	jr	ToneGen_ScanRestored_Loop	; -> 0xF616C3
ToneGen_ScanRestored_EndBlock:
	call	AccPatch_GetCurrentSlotAddr
	calr	ToneGen_GetSlotIndex
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	ix, 6:i3
	ld	(13229:16), ix
	ld	(13209:16), 6
	jr	ToneGen_ScanRestored_Loop
ToneGen_CalcEventVelocity_Restored:
	calr	AccVoice_ReadCurrentToneType
	ld	c, a
	ld	b, (13407:16)
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls	wa, w
	add	b, a
	jr	ToneGen_ScanRestored_Return
ToneGen_ScanRestored_EndMarker:
	ld	c, 0:opc
	ld	b, (13407:16)
	inc	1, b
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls	wa, w
	add	b, a
ToneGen_ScanRestored_Return:
	ret

ToneGen_ScanRestored_EndMarker_Pad:
	nop
	nop

ToneGen_GetSlotIndex:
	ld	a, (14079:16)
	and	a, 31
	cp	a, 0:i3
	jr	nz, ToneGen_GetSlot_Lookup
	or	a, 16
	ld	(14079:16), a
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
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	ld	a, e
	sub	a, w
	add	a, 12
	ld	w, (13407:16)
	cp	a, 96
	jr	nz, ToneGen_CalcWrap_Store
	ld	a, 0:opc
	inc	1, w
ToneGen_CalcWrap_Store:
	ld	hl, wa
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls	wa, w
	add	h, a
	ld	wa, hl
	ret
ToneGen_CalcWrap_Store_Pad:
	nop
	nop

ToneGen_RecalcAndRestart:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ld	l, 12:opc
	div	wa, l
	ld	a, e
	sub	a, w
	add	a, 12
	calr	ToneGen_StoreNoteOrWrap
	ld	(13942:16), 4
	ld	(13947:16), 255
	ret
ToneGen_RecalcAndRestart_Pad:
	nop
	nop

ToneGen_StoreNoteOrWrap:
	cp	a, 96
	jr	z, ToneGen_AdvancePeriodWrap
	ld	(13408:16), a
	jr	PitchValidate_Exit
ToneGen_AdvancePeriodWrap:
	ld	(13408:16), 0
	ld	a, (13407:16)
	inc	1, a
	cp	a, (13373:16)
	jr	z, ToneGen_PeriodWrap_NextBar
	ld	(13407:16), a
	jr	PitchValidate_Exit
ToneGen_PeriodWrap_NextBar:
	ld	(13407:16), 0
	ld	a, (13406:16)
	inc	1, a
	ld	w, (13371:16)
	and	w, 7
	inc	1, w
	cp	a, w
	jr	z, ToneGen_PeriodWrap_ResetBar
	ld	(13406:16), a
	jr	PitchValidate_Exit
ToneGen_PeriodWrap_ResetBar:
	ld	(13406:16), 0
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
	ld A, 0x05:opc
	ld (0x3676:16), a
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	a, (xhl+wa)
	ld E, 0x01:opc
	cp A,0xd2
	jr z, .Lc_f61878
	ld E, 0x02:opc
	cp A,0xd1
	jr z, .Lc_f61878
	ld E, 0x03:opc
	cp A,0xd3
	jr z, .Lc_f61878
	ld E, 0x04:opc
	cp A,0xd4
	jr z, .Lc_f61878
	ld E, 0x05:opc
	cp A,0xd5
	jr z, .Lc_f61878
	ld E, 0x06:opc
ToneGen_ClassifyStereoSlot_Common:
.Lc_f61878:
	ld (0x3684:16), e
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	a, (xhl+wa)
	ld (0x3685:16), a
	ret
ToneGen_ClassifyStereoSlot_Common_Pad:
	nop
	nop

ToneGen_ClassifyMonoEvent:
	ld A, 0x04:opc
	ld (0x3676:16), a
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	a, (xhl+wa)
	ld (0x367c:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	w, (xhl+wa)
	ld (0x367b:16), w
	ld a, (0x367c:16)
	ld DE,WA
	ld a, (0x36ff:16)
	and A,0x1f
	cp a, 0:i3
	jr nz, .Lc_f618e2
	or A,0x10
	ld (0x36ff:16), a
ToneGen_ClassifyMono_MapChannel:
.Lc_f618e2:
	ld L,A
	xor H,H
	ld XIY,ToneGen_ClassifyMono_MapChannel_Data
	ld	a, (xiy+hl)
	cp (0x347c:16), 0x00
	jr z, .Lc_f6191a
	pushw de
	pushw wa
	ld a, (0x347a:16)
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	ld a, (0x347b:16)
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	ld A, 0x00:opc
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	popw wa
	popw de
ToneGen_ClassifyMono_WriteNew:
.Lc_f6191a:
	pushw de
	pushw wa
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	ld A,E
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	ld A,D
	pushw wa
	call RhythmBuf_WriteByte
	inc 2,XSP
	popw wa
	popw de
	ld (0x347a:16), a
	ld (0x347b:16), e
	ld A, 0x10:opc
	ld (0x347c:16), a
	bit 4, (0x36ff:16)
	jr z, ToneGen_ClassifyMono_Return
	ld a, (0x367c:16)
	ld w, (0xfbbe:16)
	push XWA
	push XBC
	push XDE
	push XIX
	push XIY
	ld E,A
	xor D,D
	ld C,W
	xor B,B
	ld wa, 1:i3
	call 0xfee40d
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XWA
	ld A,L
	ld (0x367c:16), a
ToneGen_ClassifyMono_Return:
	ret

ToneGen_ClassifyMono_WriteNew_Pad:
	nop
	nop

AccPlayback_ReadEventLoop:
	and (0x3434:16), 0x7f
AccPlayback_ReadEvt_CheckEmpty:
	call AccPatch_CheckEmpty
	cp wa, 0:i3
	jr z, AccPlayback_ReadEvt_CheckBit7
	bit 7, (0x3434:16)
	jr nz, AccPlayback_ReadEvt_CheckBit7
	call TempoRingBuf_ReadByteToA
	cp A,0x90
	jr nz, AccPlayback_ReadEvt_Continue
	calr AccPlayback_ProcessNoteOnEvent
AccPlayback_ReadEvt_Continue:
	jr AccPlayback_ReadEvt_CheckEmpty

AccPlayback_ReadEvt_CheckBit7:
	bit	7, (0x3434:16)
	jr	z, ToneGenSetup_Done
	cpw	(0x3438:16), 0
	jr	nz, AccPlayback_ReadEvt_HasEntries
	ld	(0x7ea6:16), 15
	ld	(0xe316:16), 238
	ld	(0xe318:16), 64
	and	(0x3434:16), 127
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	jr	ToneGenSetup_Done
AccPlayback_ReadEvt_HasEntries:
	and	(0x3434:16), 223
	calr	ToneGen_CalcTempo
	bit	4, (0x36ff:16)
	jr	z, AccPlayback_ReadEvt_Overflow
	calr	AccPlayback_NoteOn_Check91
	jr	AccPlayback_ReadEvt_OverflowOK
AccPlayback_ReadEvt_Overflow:
	calr AccPlayback_AdvPattern_Loop

AccPlayback_ReadEvt_OverflowOK:
	call	AccPatch_GetCurrentSlotAddr
	calr	AccPlayback_ProcessOngoingEvents
	calr	ToneGen_AdvanceByTempo
	calr	AccPlayback_CalcTimingPosition
	call	AccPatch_GetCurrentSlotAddr
	calr	AccVoice_InitPatternBuffer
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, ToneGenSetup_Done
	ld	(58138:16), 16
ToneGenSetup_Done:
	ret

AccPlayback_ReadEvt_Return:
	nop
	nop

AccPlayback_ProcessNoteOnEvent:
	call TempoRingBuf_ReadByteToA
	call TempoRingBuf_ReadByteToA
	ld (0x3391:16), a
	call TempoRingBuf_ReadByteToA
	ld (0x3392:16), a
	call TempoRingBuf_ReadByteToA
	cp (0x3392:16), 0x00
	jr nz, .Lc_f61a26
	jr t, AccPlayback_NoteOn_WriteVoice
AccPlayback_NoteOn_ReadParams:
.Lc_f61a26:
	ld l, (0x3461:16)
	cp l, 5:i3
	jr ugt, AccPlayback_NoteOn_Store
	xor H,H
	ld XIY,0x00003464
	ld a, (0x3391:16)
	ld	(xiy+hl), a
	ld a, (0x3392:16)
	pushw hl
	add HL,0x0006
	ld	(xiy+hl), a
	popw hl
	inc 1,L
	ld (0x3461:16), l
	cp l, (0x3462:16)
	jr ule, AccPlayback_NoteOn_Store
	ld (0x3462:16), l
AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	ld	a, (0x3461:16)
	dec	1, a
	cp	a, 255
	jr	z, TimeoutCounter_CheckExit
	ld	(0x3461:16), a
	cp	a, 0:i3
	jr	nz, TimeoutCounter_CheckExit
	or	(0x3434:16), 128
TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	nop
	nop

AccPlayback_NoteOn_Check91:
	ld	wa, 0:i3
	ld	(13678:16), wa
	ld	e, (13410:16)
	xor	h, h
	ld	xix, 13412
	ld	xiy, 13774
AccPlayback_NoteOn_WritePan:
	cp	e, 0:i3
	jr	z, AccPlayback_NoteOn_Return
	ld	l, e
	dec	1, l
	addw	(0x356e:16), 6
	ld	(xiy), 144
	inc	1, xiy
	calr	ToneGen_WriteVoiceEventEntry
	dec	1, e
	jr	AccPlayback_NoteOn_WritePan
AccPlayback_NoteOn_Return:
	ret

AccPlayback_NoteOn_WritePan_Pad:
	nop
	nop

ToneGen_WriteVoiceEventEntry:
	ld a, (13408:16)

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

	ld a, (13201:16)

	ld (xiy), a

	inc 1, xiy

	ld a, (13202:16)

	ld (xiy), a

	inc 1, xiy

	ret



AccPlayback_AdvancePattern:
	nop
	nop

AccPlayback_AdvPattern_Loop:
	ld	wa, 0:i3
	ld	(13678:16), wa
	ld	e, (13410:16)
	xor	h, h
	ld	xix, 13412
	ld	xiy, 13774
AccPlayback_AdvPattern_Check81:
	cp	e, 0:i3
	jr	z, AccPlayback_AdvPattern_Nop
	ld	l, e
	dec	1, l
	calr	AccPlayback_AdvanceRingBuffer
	bit	0, (0x3395:16)
	jr	nz, AccPlayback_AdvPattern_Check90
	addw	(0x356e:16), 6
	ld	(xiy), 144
	inc	1, xiy
	calr	ToneGen_WriteVoiceEventEntry
	jr	AccPlayback_AdvPattern_Done
AccPlayback_AdvPattern_Check90:
	; adddi16 0x360a, 8 (v7 patched)
	addw	(0x356e:16), 8
	ld (xiy), 0x91

	inc 1, xiy

	; calr ToneGen_WriteVoiceEventEntry (v7 displacement)
	calr	ToneGen_WriteVoiceEventEntry
	; ldb_d8 a, (0x3432) (v7 patched)
	ld	a, (0x3396:16)
	ld (xiy), a

	inc 1, xiy

	ld a, (13207:16)

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
	ld	a, (0x344d:16)
	and	a, 15
	cp	a, 0:i3
	jr	z, AccPlayback_TrackPosition
	call	AccPatch_ReadTransposeAmount
	cp	a, (0x39b2:16)
	jr	ugt, AccPlayback_AdvanceRingBuffer_Join
	sub	(xix+hl), a
	jr	nc, AccPlayback_AdvRingBuf_Return
	ld	a, 12:opc
	add	(xix+hl), a
AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

AccPlayback_AdvanceRingBuffer_Join:
	ld w, 0xc:opc
	sub w, a
	add	(xix+hl), w

AccPlayback_TrackPosition:
	ld	a, (xix+hl)
	push	xix
	xor	w, w
	ld	xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+wa)
	pop	xix
	bit	4, (0x344e:16)
	jr	z, AccPlayback_TrackPosition_Join
	ld	c, a
	push	xix
	xor	w, w
	ld	xix, AccPlayback_TrackPosition_Data
	ld	a, (xix+wa)
	pop	xix
	bit	0, a
	jr	z, AccPlayback_TrackPos_Return
	inc	1, c
	ld	a, (xix+hl)
	inc	1, a
	ld	(xix+hl), a
AccPlayback_TrackPos_Return:
	ld a, c

AccPlayback_TrackPosition_Join:
	bit	6, (0x344e:16)
	jr	z, AccPlayback_TrackPos_WrapCheck
	bit	3, (0x36ff:16)
	jr	z, AccPlayback_TrackPos_WrapCheck
	jr	AccPlayback_TrackPos_WrapDone
AccPlayback_TrackPos_WrapCheck:
	bit	5, (0x344e:16)
	jr	z, ToneGen_LoadRhythmPatternParams
	bit	3, (0x36ff:16)
	jr	nz, ToneGen_LoadRhythmPatternParams
AccPlayback_TrackPos_WrapDone:
	cp	a, 7:i3
	jr	nz, ToneGen_LoadRhythmPatternParams
	ld	(13205:16), 1
	ld	(13206:16), 3
	ld	(13207:16), 0
	jr	AccPlayback_StyleRecalc_Return
ToneGen_LoadRhythmPatternParams:
	xor	xbc, xbc
	ld	c, a
	sla	a, 1
	add	c, a
	push	xix
	ld	xix, ToneGen_LoadRhythmPatternParams_Data
	add	xix, xbc
	ld	a, (xix)
	ld	(13205:16), a
	ld	a, (xix+1)
	ld	(13206:16), a
	ld	a, (xix+2)
	ld	(13207:16), a
	pop	xix
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
; readers in v7 (address from the linked ELF): AccPlayback_TrackPosition 0xF61B6A,
;     ToneGen_LoadRhythmPatternParams 0xF61BD7
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	and	(xiy+15), 127
	calr	ToneGen_ProcessVoiceSlots
	ld	wa, (13263:16)
	ld	(13670:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13672:16), wa
	ld	(13225:16), wa
	ld	wa, (13670:16)
	ld	(13227:16), wa
	ld	wa, (13678:16)
	ld	(13231:16), wa
	call	AccPatch_InitSlotAndCopyData
	calr	ToneGen_AdvanceSeqList
	ld	(13410:16), 0
	bit	0, (0x31e7:16)
	jr	nz, ToneGen_NullRet
	cp	(13406:16), 0
	jr	nz, ToneGen_NullRet
	cp	(13407:16), 0
	jr	nz, ToneGen_NullRet
	cp	(13408:16), 48
	jr	ugt, ToneGen_NullRet
	or	(0x3431:16), 128
ToneGen_NullRet:
	ret

AccPlayback_Ongoing_HandleType:
	nop
	nop

ToneGen_ProcessVoiceSlots:
	calr AccPlayback_Ongoing_AdvSlot
	calr ToneGen_GetSlotIndex
	ld (0x33cf:16), hl
	calr ToneGen_CalcBufferAddr
	ldw (0x33ad:16), 0x0006
	ld a, (0x345e:16)
	ld w, (0x343d:16)
	muls	wa, w
	ld	d, a
	ld	a, (0x345f:16)
	add	d, a
	ld	e, (0x3460:16)
	and	(0x3258:16), 254
	xor	bc, bc
	ld	(0x3399:16), 6
AccPlayback_Ongoing_NoteOff:
	bit 0, (0x3258:16)
	jr z, .Lc_f61cca
	jrl t, AccPlayback_Ongoing_Return
AccPlayback_Ongoing_NoteOffDone:
.Lc_f61cca:
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp A,0x81
	jr nz, AccPlayback_Ongoing_D2Type
	add B,0x01
	xor C,C
	cp DE,BC
	jr c, .Lc_f61ced
	calr ToneGen_StepToNextVoiceSlot
	jr t, AccPlayback_Ongoing_D1_Return
AccPlayback_Ongoing_D1Type:
.Lc_f61ced:
	or (0x3258:16), 0x01



AccPlayback_Ongoing_D1_Return:
	jr AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_D2Type:
	calr	AccVoice_ReadCurrentToneType
	ld	c, a
	cp	de, bc
	jr	ule, AccPlayback_Ongoing_StoreDone
	calr	AccPlayback_Ongoing_D2Type_Helper
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 144
	jr	nz, AccPlayback_Ongoing_D2_Return
	calr	ToneGen_StepToNextStereoSlot
	calr	ToneGen_StepToNextStereoSlot
	calr	ToneGen_StepToNextStereoSlot
	jr	ToneGen_StepVoiceReturn
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
	; ordi8 0x32f4, 1 (v7 patched)
	or	(0x3258:16), 1
ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

ToneGen_StepVoiceReturn_Pad:
	nop
	nop

AccPlayback_Ongoing_AdvSlot:
	ld	wa, (13676:16)
	dec	1, a
	ld	(13440:16), a
	ld	e, a
	ld	wa, (13674:16)
	ld	(13438:16), wa
	ld	hl, wa
	calr	ToneGen_CalcBufferAddr
	ld	a, (13440:16)
	xor	w, w
	ld	(13442:16), wa
	ld	a, (13371:16)
	inc	1, a
	ld	w, (13373:16)
	muls	wa, w
	dec	1, a
	ld	b, a
	xor	c, c
	ld	(13444:16), bc
	ret
AccPlayback_Ongoing_AdvDone:
	nop
	nop

AccPlayback_Ongoing_D2Type_Helper:
	ld	wa, (13263:16)
	ld	(13438:16), wa
	ld	a, (13209:16)
	ld	(13440:16), a
	ld	wa, (13229:16)
	ld	(13442:16), wa
	ld	(13444:16), bc
	ret
AccPlayback_UpdateVoiceState:
	nop
	nop

ToneGen_AdvanceSeqList:
	calr ToneGen_InitPlaybackState
	ld xhl, (0x34ac:16)
	ld WA,(XHL)
	cp	wa, (0x33ab:16)
	jr	z, AccPlayback_VoiceState_NoChange
	ld	de, (0x33a5:16)
	calr	ToneGen_SearchVoiceBuffer
	jr	AccPlayback_VoiceState_Changed
AccPlayback_VoiceState_NoChange:
	ld	de, (0x33a5:16)
	cp	de, (0x33a9:16)
	jr	c, AccPlayback_VoiceState_Changed
	or	(0x3434:16), 64
AccPlayback_VoiceState_Changed:
	bit	6, (0x3434:16)
	jr	z, AccPlayback_VoiceState_Return
	ld	wa, (0x33af:16)
	add	de, wa
	cp	de, 255
	jr	nc, AccPlayback_VoiceState_CalcOff
	ld	ix, (0x33a5:16)
	ld	wa, (0x33af:16)
	add	ix, wa
	ld	xhl, (0x34b0:16)
	ld	(xhl), ix
	jr	AccPlayback_VoiceState_Return
AccPlayback_VoiceState_CalcOff:
	ld	hl, (13464:16)
	calr	ToneGen_CalcBufferAddr
	ld	hl, (xhl+3)
	ld	xix, (13484:16)
	ld	(xix), hl
	ld	ix, 6:i3
	sub	de, 255
	add	ix, de
	ld	xhl, (13488:16)
	ld	(xhl), ix
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
; readers in v7 (address from the linked ELF): ToneGen_InitPlaybackState 0xF62096
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
; +0x00  2 B, not addressed by the reader
	.byte 0x00, 0x00
; +0x02  17 x LE32 -> (0x3548)
ToneGen_InitPlay_SetupTables_Data:
	.long 0x00000000, 0x00003201, 0x00003203, 0x00000000
	.long 0x00003205, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031ff, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031fb
; +0x46  17 x LE32 -> (0x354c)
ToneGen_InitPlay_SetupTables_Data_2:
	.long 0x00000000, 0x000031f1, 0x000031f3, 0x00000000
	.long 0x000031f5, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031ef, 0x00000000, 0x00000000, 0x00000000
	.long 0x00000000, 0x00000000, 0x00000000, 0x00000000
	.long 0x000031eb
ToneGen_SearchVoiceBuffer:
	call	AccPatch_GetCurrentSlotAddr
	ld	a, (14079:16)
	and	a, 31
	cp	a, 0:i3
	jr	nz, ToneGen_SearchBuf_MapChannel
	or	a, 16
	ld	(14079:16), a
ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ld	wa, (xiy+hl)

ToneGen_SearchBuf_CompareLoop:
	cp	wa, (0x33ab:16)
	jr	nz, ToneGen_SearchBuf_CheckEnd
	or	(0x3434:16), 64
	jr	ToneGen_SearchBuf_Return
ToneGen_SearchBuf_CheckEnd:
	cp	wa, (0x3498:16)
	jr	nz, ToneGen_SearchBuf_FollowChain
	jr	ToneGen_SearchBuf_Return
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
	bit 5, (0x3677:16)
	jr nz, .Lc_f61f04
	jrl t, AccBit5_Return
AccBit5_CheckBit5Active:
.Lc_f61f04:
	bit 5, (0x3434:16)
	jr nz, .Lc_f61f0d
	jrl t, FlagClear_Exit
AccBit5_InitAndScan:
.Lc_f61f0d:
	and (0x3434:16), 0xdf
	and (0x3433:16), 0x7f
	ld wa, (0x3478:16)
	ld (0x33cf:16), wa
	ld (0x35be:16), wa
	ld (0x3494:16), wa
	ld iy, (0x3476:16)
	ld (0x33af:16), iy
	ld (0x33ad:16), iy
	ld (0x35c4:16), iy
	ld WA,IY
	ld (0x3399:16), a
	ld iy, (0x3476:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 129
	jrl	z, FlagClear_Exit
	ld	(0x33b1:16), 6
	cp	a, 144
	jr	z, AccBit5_StepTwice
	ld	(0x33b1:16), 8
	cp	a, 145
	jr	z, AccBit5_StepOnce
	ld	(0x33b1:16), 3
	cp	a, 209
	jr	z, AccVoice_InitPlaybackState
	cp	a, 210
	jr	z, AccVoice_InitPlaybackState
	cp	a, 211
	jr	z, AccVoice_InitPlaybackState
	cp	a, 212
	jr	z, AccVoice_InitPlaybackState
	cp	a, 213
	jr	z, AccVoice_InitPlaybackState
	cp	a, 214
	jr	z, AccVoice_InitPlaybackState
	jr	FlagClear_Exit
AccBit5_StepOnce:
	calr ToneGen_StepToNextStereoSlot

AccBit5_StepTwice:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot

AccVoice_InitPlaybackState:
	calr	ToneGen_StepToNextStereoSlot
	calr	ToneGen_StepToNextVoiceSlot
	ld	wa, (13263:16)
	ld	(13756:16), wa
	ld	(13462:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13762:16), wa
	calr	ToneGen_ScanVoicePosition
	call	AccPatch_CopySequenceEntry
	call	AccPatch_GetCurrentSlotAddr
	calr	AccVoice_InitPatternBuffer
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	(58138:16), 16
FlagClear_Exit:
	; anddi8 (0x3713), 223 (v7 patched)
	and	(0x3677:16), 223
AccBit5_Return:
	ret

AccVoice_InitPlaybackState_Pad:
	nop
	nop

ToneGen_ScanVoicePosition:
	calr	ToneGen_InitPlaybackState
	call	AccPatch_GetCurrentSlotAddr
	calr	ToneGen_GetSlotIndex
	ld	de, hl
	calr	ToneGen_CalcBufferAddr
	ld	c, 3:opc
	ld	iy, 3:i3
	ld	(13447:16), 0
ToneGen_ScanPos_CompareLoop:
	cp	iy, (0x33af:16)
	jr	nz, ToneGen_ScanPos_CheckEnd
	cp	de, (0x3494:16)
	jr	nz, ToneGen_ScanPos_CheckEnd
	or	(0x3487:16), 1
	jr	VoiceState_CheckExit
ToneGen_ScanPos_CheckEnd:
	cp	iy, (0x33ad:16)
	jr	nz, VoiceState_CheckExit
	cp	de, (0x3496:16)
	jr	nz, VoiceState_CheckExit
	or	(0x3487:16), 2
VoiceState_CheckExit:
	cp	iy, (0x33a5:16)
	jr	nz, ToneGen_ScanPos_AdvanceStep
	cp	de, (0x3498:16)
	jr	nz, ToneGen_ScanPos_AdvanceStep
	jr	ToneGen_ScanPos_ProcessFlags
ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	ld	a, (0x3487:16)
	and	a, 3
	cp	a, 0:i3
	jr	z, PlaybackState_InitDone
	bit	1, (0x3487:16)
	jr	nz, ToneGen_ScanPos_AdjustBit1
	ld	iy, (0x33af:16)
	ld	xix, (0x34b0:16)
	ld	(xix), iy
	ld	xix, (0x34ac:16)
	ld	(xix), de
	ld	(0x3399:16), c
	jr	PlaybackState_InitDone
ToneGen_ScanPos_AdjustBit1:
	ld	iy, (13233:16)
	and	iy, 255
	ld	wa, iy
	sub	c, a
	jr	c, ToneGen_ScanPos_WrapBlock
	cp	c, 6:i3
	jr	c, ToneGen_ScanPos_WrapBlock
	ld	(13209:16), c
	ld	xix, (13488:16)
	ld	wa, (xix)
	sub	wa, iy
	ld	(xix), wa
	ld	xix, (13484:16)
	ld	(xix), de
	jr	PlaybackState_InitDone
ToneGen_ScanPos_WrapBlock:
	sub	c, 7
	ld	(13209:16), c
	ld	hl, de
	calr	ToneGen_CalcBufferAddr
	ld	wa, (xhl+1)
	ld	xix, (13484:16)
	ld	(xix), wa
	xor	w, w
	ld	a, c
	ld	xix, (13488:16)
	ld	(xix), iy
PlaybackState_InitDone:
	ret

PlaybackState_InitDone_Pad:
	nop
	nop

ToneGen_InitPlaybackState:
	and (0x3434:16), 0xbf
	ld a, (0x36ff:16)
	and A,0x1f
	cp a, 0:i3
	jr nz, .Lc_f620ad
	or A,0x10
	ld (0x36ff:16), a
ToneGen_InitPlay_SetupTables:
.Lc_f620ad:
	sla A, 0x02
	ld L,A
	xor H,H
	ld XIX,ToneGen_InitPlay_SetupTables_Data
	ld	xix, (xix+hl)
	ld	(13484:16), xix
	ld	xix, ToneGen_InitPlay_SetupTables_Data_2
	ld	xix, (xix+hl)
	ld	(13488:16), xix
	ld	hl, (xix)
	ld	(13221:16), hl
	ld	xix, (13484:16)
	ld	hl, (xix)
	ld	(13464:16), hl
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
	bit 2, (0x3677:16)
	jr z, AccPlayback_TempoAdv_Return
	and (0x3434:16), 0xdf
	calr ToneGen_CalcTempo
	calr ToneGen_AdvanceByTempo
	calr AccPlayback_CalcTimingPosition
	call AccPatch_GetCurrentSlotAddr
	calr AccVoice_InitPatternBuffer
	ld (0x3676:16), 0x04
	ld (0x367b:16), 0xff
	ld (0xe31a:16), 0x10
	and (0x3677:16), 0xfb
AccPlayback_TempoAdv_Return:
	ret

AccPlayback_ProcessTempoAdvance_Pad:
	nop
	nop

ToneGen_CalcTempo:
	ld	l, (13944:16)
	cp	l, 0:i3
	jr	nz, ToneGen_CalcTempo_Lookup
	ld	l, 6:opc
ToneGen_CalcTempo_Lookup:
	sla	l, 1
	xor	h, h
	push	xix
	ld	xix, ToneGen_CalcTempo_Lookup_Data
	ld	de, (xix+hl)
	ld	l, (13945:16)
	sla	l, 1
	ld	bc, (xix+hl)
	add	de, bc
	pop	xix
	ld	wa, de
	ld	l, 96:opc
	div	wa, l
	ld	(13203:16), w
	ld	(13204:16), a
	ld	a, (13946:16)
	cp	a, 1:i3
	jr	nz, ToneGen_CalcTempo_Mode0	; -> 0xF62181
	sla	de, 2
	ld	wa, de
	xor	de, de
	ld	hl, 5:i3
	ld	qwa, de
	div	xwa, hl
	jr	ToneGen_CalcTempoBeatsAndTicks	; -> 0xF621AC
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
	.byte 0x27, 0x60, 0xcf, 0x51, 0xf1, 0x91, 0x33, 0x40
	.byte 0xf1, 0x92, 0x33, 0x41, 0xc1, 0x33, 0x34, 0x3e
	.byte 0x80, 0x0e
ToneGen_CalcTempo_DataTable:
	.byte	0x00, 0x00
ToneGen_CalcTempo_Lookup_Data:	.byte	0x00, 0x00, 0x08, 0x00, 0x0c, 0x00
	.byte 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00
	.byte 0x40, 0x00, 0x60, 0x00, 0xc0, 0x00, 0x80, 0x01
	.byte 0x00, 0x03, 0x80, 0x04, 0x00, 0x06

ToneGen_AdvanceByTempo:
	ld	a, (13203:16)
	ld	w, (13204:16)
	add	a, (13408:16)
	cp	a, 96
	jr	c, ToneGen_AdvTempo_StoreNote
	sub	a, 96
	inc	1, w
ToneGen_AdvTempo_StoreNote:
	ld	(13408:16), a
	add	w, (13407:16)
	ld	l, (13373:16)
	ld	h, (13371:16)
	and	h, 7
	inc	1, h
ToneGen_AdvTempo_WrapLoop:
	cp	w, l
	jr	c, ToneGen_AdvTempo_StoreBeat	; -> 0xF6221E
	sub	w, l
	inc	1, (13406:16)
	cp	h, (13406:16)
	jr	nz, ToneGen_AdvTempo_Continue	; -> 0xF6221C
	ld	(13406:16), 0
ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	ld	(13407:16), w
	ret
ToneGen_AdvTempo_StoreBeat_Pad:
	nop
	nop

AccPlayback_UpdateRhythmSustain:
	ld	a, (13436:16)
	cp	a, 0:i3
	jr	z, AccPlayback_RhythmSust_Return
	dec	1, a
	ld	(13436:16), a
	cp	a, 0:i3
	jr	nz, AccPlayback_RhythmSust_Return
	ld	a, (13434:16)
	ld	e, (13435:16)
	ld	d, 0:opc
	pushw	wa
	call	15672633
	inc	2, xsp
	ld	a, e
	pushw	wa
	call	15672633
	inc	2, xsp
	ld	a, d
	pushw	wa
	call	15672633
	inc	2, xsp
AccPlayback_RhythmSust_Return:
	ret

AccPlayback_UpdateRhythmSustain_Pad:
	nop
	nop

AccPlayback_ProcessVoiceType5:
	bit	5, (0x3434:16)
	jr	z, AccVoice_DispatchType5Handler
	cp	(0x3676:16), 4
	jr	nz, AccVoice_DispatchType5Handler
	ld	a, (0x3691:16)
	and	a, 12
	cp	a, 0:i3
	jr	z, AccVoiceType5_CheckBit01
	calr	ToneGen_AdjustVoiceVelocity
AccVoiceType5_CheckBit01:
	ld	a, (13969:16)
	and	a, 3
	cp	a, 0:i3
	jr	z, AccVoice_DispatchType5Handler
	calr	ToneGen_AdjustVolumePan
AccVoice_DispatchType5Handler:
	bit	5, (0x3434:16)
	jr	z, TempoCheck_Exit
	cp	(0x3676:16), 5
	jr	nz, TempoCheck_Exit
	ld	a, (0x3691:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, TempoCheck_Exit
	calr	ToneGen_ProcessStereoType
TempoCheck_Exit:
	ret

AccVoice_DispatchType5Handler_Pad:
	nop
	nop

ToneGen_AdjustVoiceVelocity:
	ld	wa, (0x3476:16)
	ld	(0x33ad:16), wa
	ld	wa, (0x3478:16)
	ld	(0x33cf:16), wa
	ld	(0x3399:16), 0
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	a, 129
	jrl	z, ToneGen_AdjVel_Return
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	bit	4, (0x36ff:16)
	jr	z, ToneGen_AdjVel_CheckBit2
	ld	w, (0xfbbe:16)
	push	xwa
	push	xbc
	push	xde
	push	xix
	push	xiy
	xor	d, d
	ld	e, a
	ld	c, w
	xor	b, b
	ld	wa, 1:i3
	call	Param_SignExtendReturn
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xwa
	ld	a, l
ToneGen_AdjVel_CheckBit2:
	bit	2, (0x3691:16)
	jr	z, ToneGen_AdjVel_Decrement
	inc	1, a
	cp	a, 128
	jr	c, ToneGen_AdjVel_ClampHigh
	ld	a, 127:opc
ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_AdjVel_StoreAndParam
	ld a, 0x0:opc

ToneGen_AdjVel_StoreAndParam:
	ld	e, a
	bit	4, (0x36ff:16)
	jr	z, ToneGen_AdjVel_WriteToBuffer
	ld	w, (0xfbbe:16)
	push	xwa
	push	xbc
	push	xde
	push	xix
	push	xiy
	xor	bc, bc
	ld	c, w
	ld	wa, 2:i3
	xor	d, d
	call	Param_SignExtendReturn
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xwa
	ld	a, l
ToneGen_AdjVel_WriteToBuffer:
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	pushw	ix
	ld	ix, (13229:16)
	ld	(xhl+ix), a
	ld	(13948:16), e
	popw	ix
	push	xde
	call	AccScreen_DrawInit_StackWrap
	pop	xde
	ld	a, (14079:16)
	and	a, 15
	cp	a, 0:i3
	jr	z, ToneGen_AdjVel_Return	; -> 0xF62371
	calr	ToneGen_WriteMultiChanParam
ToneGen_AdjVel_Return:
	ret

ToneGen_AdjVel_WriteToBuffer_Pad:
	nop
	nop

ToneGen_AdjustVolumePan:
	ld wa, (0x3476:16)
	ld (0x33ad:16), wa
	ld wa, (0x3478:16)
	ld (0x33cf:16), wa
	ld (0x3399:16), 0x00
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp A,0x81
	jr z, ToneGen_AdjVol_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ld	a, (xhl+wa)
	bit 0, (0x3691:16)
	jr z, ToneGen_AdjVol_Decrement
	inc 1,A
	cp A,0x80
	jr c, ToneGen_AdjVol_ClampHigh
	ld A, 0x7f:opc
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
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	pushw	ix
	ld	ix, (13229:16)
	ld	(xhl+ix), a
	ld	(13947:16), a
	popw	ix
	call	AccScreen_UpdateBeat_StackWrap
ToneGen_AdjVol_Return:
	ret

ToneGen_AdjVol_WriteToBuffer_Pad:
	nop
	nop

ToneGen_ProcessStereoType:
	ld	wa, (0x3476:16)
	ld	(0x33ad:16), wa
	ld	wa, (0x3478:16)
	ld	(0x33cf:16), wa
	ld	(0x3399:16), 0
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	a, 129
	jr	z, ToneGen_Stereo_Return
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	c, (xhl+wa)
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	wa, (0x33ad:16)
	ld	a, (xhl+wa)
	cp	c, 211
	jr	z, ToneGen_Stereo_ClampLow
	bit	4, (0x3691:16)
	jr	z, ToneGen_Stereo_Increment
	inc	1, a
	cp	a, 128
	jr	c, ToneGen_Stereo_CheckInc
	ld	a, 127:opc
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
	bit	4, (0x3691:16)
	jr	z, ToneGen_Stereo_Store
	ld	a, 127:opc
	jr	ToneGen_Stereo_WriteParam
ToneGen_Stereo_Store:
	ld a, 0x0:opc

ToneGen_Stereo_WriteParam:
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	pushw	ix
	ld	ix, (13229:16)
	ld	(xhl+ix), a
	ld	(13957:16), a
	popw	ix
	call	AccScreen_DrawMeasure_StackWrap
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
	ld	(59:8), 60:io
	ld	xwa, 0x4906053f
	max
	.ascii "JHmnopqrstuvwxyz{|}~"
	jrl	nc, 14
	nop
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	jp	0x09121d
	ldw	(11:8), 3340:io
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
	ld	hl, (13263:16)
	calr	60196
	ld	iy, (13430:16)
	ld	d, (xhl+iy)
	xor	h, h
	ld	l, e
	push	xix
	ld	xix, AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+hl)
	pop	xix
	ld	e, 144:opc
	bit	6, (13390:16)
	jr	z, ToneGen_MultiChan_Compare
	bit	3, (14079:16)
	jr	z, ToneGen_MultiChan_Compare
	jr	ToneGen_MultiChan_AdjustVel
ToneGen_MultiChan_Compare:
	bit	5, (13390:16)
	jr	z, AccVoice_ResolveNoteOnOffType
	bit	3, (14079:16)
	jr	nz, AccVoice_ResolveNoteOnOffType
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
	ld wa, (0x3476:16)
	ld (0x33ad:16), wa
	ld wa, (0x3478:16)
	ld (0x33cf:16), wa
	ld (0x3399:16), 0x00
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339a:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339b:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339c:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339d:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339e:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	ld (0x339f:16), a
	ret
ToneGen_VoiceParamDisp_Return:
	nop
	nop

ToneGen_CompareVoiceBlocks_Helper2:
	ld wa, (0x3478:16)
	ld (0x33cf:16), wa
	ld (0x35be:16), wa
	ld (0x3494:16), wa
	ld iy, (0x3476:16)
	ld (0x33af:16), iy
	ld (0x33ad:16), iy
	ld (0x35c4:16), iy
	ld WA,IY
	ld (0x3399:16), a
	ld (0x33b1:16), 0x06
	ld iy, (0x3476:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp A,0x90
	jr z, ToneGen_CalcBeatSubdivision
	ld (0x33b1:16), 0x08
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
ToneGen_CalcBeatSubdivision:
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	calr	ToneGen_StepToNextVoiceSlot
	ld	wa, (13263:16)
	ld	(13756:16), wa
	ld	(13462:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13762:16), wa
	calr	ToneGen_ScanVoicePosition
	call	AccPatch_CopySequenceEntry
	ret
ToneGen_CalcBeat_Return:
	nop
	nop

ToneGen_CompareVoiceBlocks_Helper3:
	ld XIY,0x000035ce
	ld a, (0x339a:16)
	ld (XIY),A
	ld a, (0x339b:16)
	ld (XIY+0x01),A
	ld a, (0x339c:16)
	ld (XIY+0x02),A
	ld a, (0x339d:16)
	ld (XIY+0x03),A
	ld a, (0x339e:16)
	ld (XIY+0x04),A
	ld a, (0x339f:16)
	ld (XIY+0x05),A
	ld a, (0x339c:16)
	xor H,H
	ld L,A
	push XIX
	ld XIX,AccPatch_Transpose_LookupTable_Data
	ld	a, (xix+hl)
	pop	xix
	bit	6, (0x344e:16)
	jr	z, ToneGen_ReadBufferUtility
	bit	3, (0x36ff:16)
	jr	z, ToneGen_ReadBufferUtility
	jr	ToneGen_ReadBufUtil_Loop
ToneGen_ReadBufferUtility:
	bit	5, (0x344e:16)
	jr	z, AccVoice_WriteNoteEventToBuffer
	bit	3, (0x36ff:16)
	jr	nz, AccVoice_WriteNoteEventToBuffer
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
	cpw (0x3438:16), 0x0000
	jr z, ToneGen_SeqAdvanceMain
	ld XIY,0x000035ce
	ld A,(XIY)
	ldw (0x356e:16), 0x0006
	cp A,0x90
	jr z, ToneGen_StepBounds_Return
	ldw (0x356e:16), 0x0008
ToneGen_StepBounds_Return:
	ld	wa, (13432:16)
	ld	(13263:16), wa
	ld	iy, (13430:16)
	ld	wa, iy
	ld	(13209:16), a
	ld	wa, (13263:16)
	ld	(13670:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13672:16), wa
	ld	wa, (13672:16)
	ld	(13225:16), wa
	ld	wa, (13670:16)
	ld	(13227:16), wa
	ld	wa, (13678:16)
	ld	(13231:16), wa
	call	AccPatch_InitSlotAndCopyData
	calr	ToneGen_AdvanceSeqList
	jr	ToneGen_SeqAdv_Return
ToneGen_SeqAdvanceMain:
	ld	(32422:16), 15
	ld	(58134:16), 238
	ld	(58136:16), 64
	ld	a, 8:opc
	call	16692690
ToneGen_SeqAdv_Return:
	ret

ToneGen_SeqAdvanceMain_Pad:
	nop
	nop

AccVoice_ReadCurrentToneType:
	push	xiy
	push	xhl
	xor	xiy, xiy
	ld	iy, (13229:16)
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	add	xhl, xiy
	ld	a, (xhl+1)
	cp	a, 135
	jr	nz, ToneGen_InterpolateParam
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	hl, (xhl+3)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+6)
ToneGen_InterpolateParam:
	pop xhl
	pop xiy
	ret

ToneGen_Interp_Loop:
	nop
	nop

ToneGen_StepToNextVoiceSlot:
	push XIY
	push XHL
	ld iy, (0x33ad:16)
	inc 1,IY
	inc	1, (13209:16)
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 135
	jr	z, ToneGen_Interp_StoreResult
	cp	a, 131
	jr	nz, ToneGen_Interp_WrapPoint
	jr	ToneGen_Interp_CheckExit
ToneGen_Interp_StoreResult:
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	hl, (xhl+3)
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	iy, 6:i3
	ld	(13209:16), 6
	jr	ToneGen_Interp_WrapPoint
ToneGen_Interp_CheckExit:
	call	AccPatch_GetCurrentSlotAddr
	calr	ToneGen_GetSlotIndex
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	iy, 6:i3
	ld	(13209:16), 6
ToneGen_Interp_WrapPoint:
	ld	(13229:16), iy
	pop	xhl
	pop	xiy
	ret
ToneGen_Interp_Done:
	nop
	nop

ToneGen_StepToNextStereoSlot:
	push XIY
	push XHL
	ld iy, (0x33ad:16)
	inc 1,IY
	inc	1, (0x3399:16)
	ld	hl, (0x33cf:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 135
	jr	nz, ToneGen_Interp_Return
	calr	ToneGen_StepToNextBuffer
ToneGen_Interp_Return:
	inc	1, iy
	inc	1, (13209:16)
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 135
	jr	nz, ToneGen_Interp_OverflowCheck	; -> 0xF62900
	calr	ToneGen_StepToNextBuffer
ToneGen_Interp_OverflowCheck:
	ld	(13229:16), iy
	pop	xhl
	pop	xiy
	ret
ToneGen_Interp_OverflowDone:
	nop
	nop

ToneGen_StepToNextBuffer:
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	xor	iy, iy
	ld	hl, (xhl+3)
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	iy, 6:i3
	ld	(13209:16), 6
	ret
ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	ld iy, (xhl+0:8)
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
	push	xiy
	push	xhl
	ld	iy, (13229:16)
	dec	1, iy
	dec	1, (13209:16)
	ld	hl, (13263:16)
	calr	ToneGen_CalcBufferAddr
	ld	a, (xhl+iy)
	cp	a, 135
	jr	nz, ToneGen_StepFwd_WrapDone
	ld	hl, (xhl+1)
	cp	hl, 65535
	jr	z, ToneGen_StepFwd_CheckWrap
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ldw	iy, 254
	ld	(13209:16), 254
	jr	ToneGen_StepFwd_WrapDone
ToneGen_StepFwd_CheckWrap:
	ld	hl, (13674:16)
	ld	(13263:16), hl
	calr	ToneGen_CalcBufferAddr
	ld	hl, (13676:16)
	dec	1, hl
	ld	iy, hl
	ld	(13209:16), l
ToneGen_StepFwd_WrapDone:
	ld	(13229:16), iy
	pop	xhl
	pop	xiy
	ret
ToneGen_StepFwd_Exit:
	nop
	nop

ToneGen_StepFwd_Alternate:
	ld e, (0x367e:16)
	ld d, (0x36ab:16)
	ld c, (0x36aa:16)
	ld b, (0x343b:16)
	cp (0x343d:16), 0x04
	jr ugt, ToneGen_StepAlt_Overflow
	cp b, 3:i3
	jr ugt, ToneGen_StepAlt_CheckBeat
	ld C, 0x00:opc
	jr t, ToneGen_StepAlt_Return
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
	ld	(13994:16), c
	xor	d, d
	ld	(13995:16), de
	calr	AccPlayback_DetectMeasurePos
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
	ld A,C
	inc 1,A
	cp (0x343d:16), 0x04
	jr ugt, AccPlayback_MeasPos_SmallBeat
	cp E,A
	jr c, AccPlayback_MeasPos_SetLower
	add A,0x03
	cp E,A
	jr ugt, AccPlayback_MeasPos_SetUpper
	jr t, RhythmChannel_NullRet
AccPlayback_MeasPos_SetLower:
	ld	c, e
	dec	1, c
	ld	(13994:16), c
	jr	RhythmChannel_NullRet
AccPlayback_MeasPos_SetUpper:
	ld	c, e
	sub	c, 3
	dec	1, c
	ld	(13994:16), c
	jr	RhythmChannel_NullRet
AccPlayback_MeasPos_SmallBeat:
	cp e, a
	jr c, AccPlayback_MeasPos_SmallLower
	add a, 0x1
	cp e, a
	jr ugt, AccPlayback_MeasPos_SmallUpper
	jr RhythmChannel_NullRet

AccPlayback_MeasPos_SmallLower:
	ld	c, e
	dec	1, c
	ld	(13994:16), c
	jr	RhythmChannel_NullRet
AccPlayback_MeasPos_SmallUpper:
	ld	c, e
	sub	c, 1
	dec	1, c
	ld	(13994:16), c
RhythmChannel_NullRet:
	ret

RhythmChannel_NullRet_Pad:
	nop
	nop

AccPlayback_InitPartAssignment:
	xor WA,WA
	ld (0x36a2:16), wa
	ld (0x36a4:16), wa
	ld (0x36a6:16), wa
	ld (0x36a8:16), wa
	jr t, AccPlayback_PartAssign_Check4
	ld a, (0x343d:16)
	cp a, 4:i3
	jr ule, AccPlayback_PartAssign_Store
	cp (0x345f:16), 0x04
	jr nc, AccPlayback_PartAssign_Sub4
	ld A, 0x04:opc
	jr t, AccPlayback_PartAssign_Store
AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	ld	(13986:16), a
	jrl	RhythmFunc_NullRet
AccPlayback_PartAssign_Check4:
	cp	(0x343d:16), 4
	jrl	ugt, AccPlayback_PartAssign_LargeBeat
	cp	(0x343b:16), 2
	jr	ugt, AccPlayback_PartAssign_LargeMeasure
	cp	(0x36aa:16), 0
	jr	z, AccPlayback_PartAssign_SmallPart
	jrl	RhythmFunc_NullRet
AccPlayback_PartAssign_SmallPart:
	ld	a, (0x343d:16)
	ld	(0x36a2:16), a
	ld	(0x36a6:16), 1
	cp	(0x343b:16), 1
	jr	c, AccPlayback_PartAssign_Check2
	ld	(0x36a3:16), a
	ld	(0x36a7:16), 2
AccPlayback_PartAssign_Check2:
	cp	(0x343b:16), 2
	jr	c, AccPlayback_PartAssign_Check3
	ld	(0x36a4:16), a
	ld	(0x36a8:16), 3
AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	ld	a, (13371:16)
	sub	a, (13994:16)
	cp	a, 2:i3
	jr	gt, AccPlayback_PartAssign_FullSetup
	jrl	RhythmFunc_NullRet
AccPlayback_PartAssign_FullSetup:
	ld	a, (13373:16)
	ld	(13986:16), a
	ld	(13987:16), a
	ld	(13988:16), a
	ld	(13989:16), a
	ld	a, (13994:16)
	inc	1, a
	ld	(13990:16), a
	inc	1, a
	ld	(13991:16), a
	inc	1, a
	ld	(13992:16), a
	inc	1, a
	ld	(13993:16), a
	jr	RhythmFunc_NullRet
AccPlayback_PartAssign_LargeBeat:
	cp	(0x343b:16), 0
	jr	nz, AccPlayback_PartAssign_LargeBeat2
	cp	(0x36aa:16), 0
	jr	nz, RhythmFunc_NullRet
	ld	(0x36a2:16), 4
	ld	a, (0x343d:16)
	sub	a, 4
	ld	(0x36a3:16), a
	ld	(0x36a6:16), 1
	jr	RhythmFunc_NullRet
AccPlayback_PartAssign_LargeBeat2:
	ld	a, (13371:16)
	sub	a, (13994:16)
	cp	a, 0:i3
	jr	le, RhythmFunc_NullRet
	ld	(13986:16), 4
	ld	a, (13373:16)
	sub	a, 4
	ld	(13987:16), a
	ld	(13988:16), 4
	ld	(13989:16), a
	ld	a, (13994:16)
	inc	1, a
	ld	(13990:16), a
	inc	1, a
	ld	(13992:16), a
RhythmFunc_NullRet:
	ret

AccPlayback_PartAssign_DataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 45 of 68 slots byte-identical
	nop
	nop
	; differs from v10 here and llvm-objdump cannot read it
	cp	(0x8c9c:16), 182
	jr	z, 2
	jr	60
	ld	a, (13939:16)
	ldw	ix, 480
	calr	53
	ld	a, (13950:16)
	ldw	ix, 6962
	calr	43
	ld	a, (13948:16)
	ldw	ix, 6967
	calr	33
	ld	a, (13947:16)
	ldw	ix, 6972
	calr	23
	ld	a, (13944:16)
	ldw	ix, 6977
	calr	13
	ld	a, (13945:16)
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
	.byte 0x30	; v10 does not spell this byte either
	.byte 0x31	; v10 does not spell this byte either
	.byte 0x32	; v10 does not spell this byte either
	.byte 0x33	; v10 does not spell this byte either
	.byte 0x34	; v10 does not spell this byte either
	.byte 0x35	; v10 does not spell this byte either
	.byte 0x36	; v10 does not spell this byte either
	.byte 0x37	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	.byte 0x39	; v10 does not spell this byte either
	.byte 0x41	; v10 does not spell this byte either
	.byte 0x42	; v10 does not spell this byte either
	.byte 0x43	; v10 does not spell this byte either
	.byte 0x44	; v10 does not spell this byte either
	.byte 0x45	; v10 does not spell this byte either
	.byte 0x46	; v10 does not spell this byte either
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
	bit 0, (0x3435:16)
	jr nz, .Lc_f62d55
	jp AccPat_Dispatch_Return
AccPat_Dispatch_AllocAndProcess:
.Lc_f62d55:
	ld XWA,0x00000800
	push XWA
	call Malloc
	add XSP,0x00000004
	ld	(13512:16), xhl
	ld	a, (13393:16)
	ld	w, (13394:16)
	pushw	wa
	and	(0x3435:16), 254
	and	(0x3514:16), 254
	ld	a, (13393:16)
	cp	a, 128
	jr	c, AccPat_Dispatch_LowRange
	cp	a, 160
	jrl	nc, AccPat_CleanupAndFree
	cp	(13395:16), 26
	jr	nz, AccPat_Dispatch_CalcAccent
	calr	AccWidget_ProcessSpecialCmd
	jrl	AccPat_CleanupAndFree
AccPat_Dispatch_CalcAccent:
	calr	AccPat_CalcAccentVelocity
	ld	a, (13393:16)
	and	a, 127
	cp	a, (13370:16)
	jr	z, AccPat_CleanupAndFree
	cp	a, 30
	jr	nc, AccPat_CleanupAndFree
	or	(0x3431:16), 128
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	jr	AccPat_Dispatch_CheckBit0
AccPat_Dispatch_LowRange:
	or	(0x3431:16), 128
	cp	(13395:16), 26
	jr	nz, AccPat_Dispatch_InitWorkArea
	calr	RhythmROM_LoadDrumKit
	jr	AccPat_CleanupAndFree
AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	bit	0, (0x3514:16)
	jr	nz, AccPat_Dispatch_InitSlot
	cp	(0x8c9a:16), 184
	jr	nz, AccPat_CleanupAndFree
	ld	(0x7ea6:16), 20
	call	DrumVoice_NotifyEE
	jr	AccPat_CleanupAndFree
AccPat_Dispatch_InitSlot:
	call	AccPatch_InitCurrentSlot
	ld	(32422:16), 23
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	16692690
AccPat_CleanupAndFree:
	popw	wa
	ld	(13393:16), a
	ld	(13394:16), w
	ld	xwa, (13512:16)
	push	xwa
	call	16712469
	add	xsp, 4
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
	ld	l, (14608:16)
	cp	l, 30
	jr	c, AccPat_DualVoice_ClampIndex
	xor	l, l
AccPat_DualVoice_ClampIndex:
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add	xiy, (14610:16)
	add	xiy, 96
	ld	(13504:16), xiy
	ld	l, (14609:16)
	cp	l, 30
	jr	c, AccPat_DualVoice_ClampIndex2	; -> 0xF62E74
	xor	l, l
AccPat_DualVoice_ClampIndex2:
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add	xiy, (0x3916:16)
	add	xiy, 96
	ld	(0x34c4:16), xiy
	ld	xiy, (0x34c0:16)
	add	xiy, 12
	ld	xix, (0x34c4:16)
	add	xix, 12
	ldw	bc, 84
	ldir85
	calr	AccPat_DualVoice_ReadParamsA
	calr	AccPatch_LoadDualVoiceParamsB
	calr	AccPat_DualVoice_CopyAllBanks
	ret
AccPat_DualVoice_DataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 24 of 38 slots byte-identical
	nop
	nop
	ld	l, (13393:16)
	and	l, 127
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add	xiy, 608256
	add	xiy, 96
	ld	(13504:16), xiy
	ld	l, (13370:16)
	cp	l, 30
	jr	c, AccPatch_LoadDualVoiceParams_Skip
	xor	l, l
AccPatch_LoadDualVoiceParams_Skip:
	sla	l, 2
	xor	h, h
	; v10 does not spell this byte either
	ld	xix, RhythmTiming_OffsetTable
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	xiy, (xix+hl)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	add	xiy, 608256
	; v10 does not spell this byte either
	add	xiy, 96
	; v10 does not spell this byte either
	ld	(0x34c4:16), xiy
	; differs from v10 here and llvm-objdump cannot read it
	ret
AccPat_DualVoice_ReadParamsA:
	ld xiy, (13504:16)

	ld hl, (xiy + 0:8)

	ld (13576:16), hl

	ld hl, (xiy + 4)

	ld (13578:16), hl

	ld hl, (xiy + 6)

	ld (13580:16), hl

	ld hl, (xiy + 8)

	ld (13582:16), hl

	ld hl, (xiy + 10)

	ld (13584:16), hl

	ret



AccPat_DualVoice_ReadParamsA_Pad:
	nop
	nop

AccPatch_LoadDualVoiceParamsB:
	ld xiy, (13508:16)

	ld hl, (xiy + 0:8)

	ld (13564:16), hl

	ld hl, (xiy + 4)

	ld (13566:16), hl

	ld hl, (xiy + 6)

	ld (13568:16), hl

	ld hl, (xiy + 8)

	ld (13570:16), hl

	ld hl, (xiy + 10)

	; stda16 (0x35a0), xhl (v7 patched)
	ld	(0x3504:16), hl
	ret



AccPatch_LoadDualVoiceParamsB_Pad:
	nop
	nop

AccPat_DualVoice_CopyAllBanks:
	ld	iy, (13576:16)
	ld	ix, (13564:16)
	calr	ToneBank_CopyEntry
	ld	iy, (13578:16)
	ld	ix, (13566:16)
	calr	ToneBank_CopyEntry
	ld	iy, (13580:16)
	ld	ix, (13568:16)
	calr	ToneBank_CopyEntry
	ld	iy, (13582:16)
	ld	ix, (13570:16)
	calr	ToneBank_CopyEntry
	ld	iy, (13584:16)
	ld	ix, (13572:16)
	calr	ToneBank_CopyEntry
	ret
AccPat_DualVoice_CopyAllBanks_Pad:
	nop
	nop

ToneBank_CopyEntry:
	ld (0x34fa:16), ix
	ld (0x3506:16), iy
	ld HL,IY
	ld	xwa, (0x3912:16)
	calr	ToneBank_ComputeEntryAddress
	ld	wa, (xhl+3)
	ld	(0x3512:16), wa
	ld	hl, (0x34fa:16)
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	ld	xix, xhl
	ld	hl, (0x3506:16)
	ld	xwa, (0x3912:16)
	calr	ToneBank_ComputeEntryAddress
	ld	xiy, xhl
	add	xiy, 6
	add	xix, 6
	ldw	bc, 249
	ldir85
ToneBank_CopyEntry_Join:
	cpw	(0x3512:16), 65535
	jrl	z, ToneBank_CopyComplete_Return
	calr	ToneBank_CopyChunk_Return
	bit	0, (0x3514:16)
	jr	nz, ToneBank_CopyComplete_Return
	decw	1, (0x3438:16)
	ld	hl, de
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	or	(xhl), 128
	ld	hl, (0x34fa:16)
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	ld	(xhl+3), de
	ld	hl, de
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	ld	wa, (0x34fa:16)
	ld	(xhl+1), wa
	ld	(0x34fa:16), de
	ld	wa, (0x3512:16)
	ld	(0x3506:16), wa
	ld	hl, wa
	ld	xwa, (0x3912:16)
	calr	ToneBank_ComputeEntryAddress
	ld	wa, (xhl+3)
	ld	(0x3512:16), wa
	calr	AccPat_ShiftAndMask
	ld	hl, (0x34fa:16)
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	ld	xix, xhl
	ld	hl, (0x3506:16)
	ld	xwa, (0x3912:16)
	calr	ToneBank_ComputeEntryAddress
	ld	xiy, xhl
	add	xiy, 6
	add	xix, 6
	ldw	bc, 249
	ldir85
	jrl	ToneBank_CopyEntry_Join
ToneBank_CopyComplete_Return:
	ld	hl, (13562:16)
	ld	xwa, (14614:16)
	calr	ToneBank_ComputeEntryAddress
	ldw	wa, 65535
	ld	(xhl+3), wa
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
	cp	de, 340
	jr	nc, ToneBank_ComputeAddr_CheckRange
	ld	hl, de
	ld	xwa, (0x3916:16)
	calr	ToneBank_ComputeEntryAddress
	bit	7, (xhl)
	jr	z, ToneBank_ComputeAddr_Return
	inc	1, de
	jr	ToneBank_ComputeEntryAddress_Join
ToneBank_ComputeAddr_CheckRange:
	; ordi8 0x35b0, 1 (v7 patched)
	or	(0x3514:16), 1
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
	; ordi8 0x35b0, 1 (v7 patched)
	or	(0x3514:16), 1
ToneBank_SwapCopy_Pad:
	ret
ToneBank_SwapCopy_Pad_Code:
	nop
	nop
	ldw	de, 150
	cp	de, 340
	jr	nc, 13
	ld	hl, de
	calr	-1007
	bit	7, (xhl)
	jr	z, 9
	inc	1, de
	jr	-19
	or	(0x3514:16), 1
	or	de, 32768
	ret
RhythmROM_PatternDispatcher:
	and	(0x3514:16), 249
	ld	l, (13393:16)
	ld	h, (13394:16)
	call	VoiceParam_ClampAndValidate_Tramp
	ld	(13393:16), l
	ld	(13394:16), h
	sla	l, 1
	sla	hl, 1
	ld	xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	ld	(13502:16), wa
	add	hl, 2
	ld	wa, (xiy+hl)
	ld	(13504:16), wa
	ld	l, (13370:16)
	cp	l, 30
	jr	c, AccPat_CalcAccentVelocity_Body
	xor	l, l
AccPat_CalcAccentVelocity_Body:
	sla	l, 2
	xor	h, h
	ld	xix, RhythmTiming_OffsetTable
	ld	xiy, (xix+hl)
	add	xiy, 608256
	add	xiy, 96
	ld	(13508:16), xiy
	calr	RhythmROM_LoadPattern
	cp	(13395:16), 0
	jr	z, RhythmROM_LoadAndInit
	cp	(13395:16), 1
	jr	z, RhythmROM_LoadAndInit
	cp	(13395:16), 2
	jr	z, RhythmROM_LoadAndInit
	cp	(13395:16), 3
	jr	z, RhythmROM_LoadAndInit
	calr	ToneData_LookupEffectParam_Code
	calr	AccPatch_LoadDualVoiceParamsB
	calr	VoiceSlot_Resolve_Loop
	jr	AccPat_CalcAccent_Return
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
	ld	wa, (0x34be:16)
	ld	w, a
	calr	RhythmROM_CalcPatternAddr
	xor	xiy, xiy
	ld	iy, (0x34c0:16)
	add	xiy, xix
	ld	xix, (0x34c8:16)
	ldw	bc, 1024
	ldirw
	ld	l, (0x3453:16)
	and	l, 15
	xor	h, h
	sla	hl, 1
	ld	xix, RhythmROM_LoadPattern_Data
	xor	xwa, xwa
	ld	wa, (xix+hl)
	jr	RhythmROM_PatternDisp_ReadByte
; RhythmROM_LoadPattern +0x34 -- 16 x LE16 byte offsets into the rhythm pattern
; buffer, read by the routine above: ld l,(<var>) / and l,0xf / sla hl,1 /
; ld xix, RhythmROM_LoadPattern_Data / ld_rrw wa,(xix+hl), then
; RhythmROM_PatternDisp_ReadByte adds WA to the pattern pointer.  Typed as in
; v9/v10 (lane accomp 2026-09-25, scripts/converters/lane_accomp_v7_rhythmrom.py);
; before, the routine and this table were one .byte run with phantom
; instructions (neg wa / pop sr / reti) in the table.
RhythmROM_LoadPattern_Data:
	.short 0x03d2, 0x03d8, 0x07d2, 0x07d8, 0x03d3, 0x07d3, 0x03d3, 0x07d3
	.short 0x03d2, 0x03d2, 0x03d8, 0x03d8, 0x07d2, 0x07d2, 0x07d8, 0x07d8
RhythmROM_PatternDisp_ReadByte:
	ld	xiy, (13512:16)
	add	xiy, xwa
	ld	a, (xiy)
	ld	(13589:16), a
	ld	xiy, (13512:16)
	ld	xix, (13508:16)
	add	xix, 12
	ld	a, (xiy+976)
	ld	(xix), a
	inc	1, xix
	push	xix
	calr	RhythmROM_PatternDisp_ReadByte_Helper
	pop	xix
	ld	(xix), a
	inc	1, xix
	ld	a, 32:opc
	ld	(xix), a
	inc	1, xix
	ld	a, 0:opc
	ld	(xix), a
	inc	1, xix
	ld	a, (13393:16)
	ld	(xix), a
	inc	1, xix
	ld	a, (13394:16)
	ld	(xix), a
	inc	1, xix
	ld	l, (13395:16)
	and	l, 15
	xor	h, h
	sla	hl, 1
	ld	xix, RhythmROM_PatternDisp_CheckCmd
	xor	xwa, xwa
	ld	wa, (xix+hl)
	jr	RhythmROM_PatternDisp_Handle90	; -> 0xF6325F
RhythmROM_PatternDisp_CheckCmd:
	popw	wa
	push	sr
	jrl	ge, 18434
	.byte 0x06
	jrl	ge, 28166
	pop	sr
	jr	nz, 7
	adc	(xsp+3), sp
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
	ld	xiy, (13512:16)
	add	xiy, xwa
	ld	xix, (13508:16)
	add	xix, 24
	ld	a, 5:opc
RhythmROM_PatternDisp_Check91:
	ld	bc, 7:i3
	ldir85
	inc	1, xix
	dec	1, a
	cp	a, 0:i3
	jr	nz, RhythmROM_PatternDisp_Check91
	ld	xix, (0x34c4:16)
	ld	xiy, 34
	add	xiy, xix
	ld	(xiy), 64
	ld	xiy, 42
	add	xiy, xix
	ld	(xiy), 12
	ld	xiy, 50
	add	xiy, xix
	ld	(xiy), 116
	ld	xiy, 58
	add	xiy, xix
	ld	(xiy), 64
	ld	a, (0x3451:16)
	ld	(0x904e:16), a
	ld	a, (0x3452:16)
	ld	(0x904f:16), a
	call	16068357
	ld	h, (0x9053:16)
	ld	l, (0x9052:16)
	call	AccVoice_DispatchEntry
	ld	xiy, 13327
	ld	xix, (0x34c4:16)
	add	xix, 64
	ldw	bc, 16
	ldir85
	ret
RhythmROM_PatternDisp_Handle91:
	nop
	nop

RhythmROM_CalcPatternAddr:
	and	xwa, 65280
	sla	xwa, 8
	ld	xix, 4194304
	add	xix, (12763:16)
	add	xix, xwa
	ret
RhythmROM_PatternDisp_Return:
	nop
	nop

RhythmROM_PatternDisp_ReadByte_Helper:
	ld	xhl, (13512:16)
	add	xhl, 280
	calr	RhythmROM_CountEntries
	ld	(13591:16), e
	ld	a, (13395:16)
	cp	a, 0:i3
	jr	z, RhythmROM_InitPattern
	cp	a, 1:i3
	jr	z, RhythmROM_InitPattern
	cp	a, 2:i3
	jr	z, RhythmROM_InitPattern
	cp	a, 3:i3
	jr	z, RhythmROM_InitPattern
	jr	RhythmROM_InitPattern_Join
RhythmROM_InitPattern:
	ld	xhl, (0x34c4:16)
	xor	wa, wa
	ld	a, (xhl+12)
	ld	xhl, AccFill_AdvanceAndCheck_Code
	ld	l, (xhl+wa)
	ld	a, 7:opc
	cp	l, (0x3517:16)
	jr	nz, RhythmVoice_WriteParam_Return
	or	(0x3514:16), 2
	ld	a, 3:opc
RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

RhythmROM_InitPattern_Join:
	ld	xhl, (13512:16)
	add	xhl, 312
	cp	a, 4:i3
	jr	z, RhythmROM_ProcessPattern
	ld	xhl, (13512:16)
	add	xhl, 316
	cp	a, 6:i3
	jr	z, RhythmROM_ProcessPattern
	ld	xhl, (13512:16)
	add	xhl, 1336
	cp	a, 5:i3
	jr	z, RhythmROM_ProcessPattern
	ld	xhl, (13512:16)
	add	xhl, 1340
	cp	a, 7:i3
	jr	z, RhythmROM_ProcessPattern
	jr	RhythmVoice_SetupChannels
RhythmROM_ProcessPattern:
	calr	RhythmROM_CountEntries
	ld	xhl, (13508:16)
	xor	wa, wa
	ld	a, (xhl+12)
	ld	xhl, AccFill_AdvanceAndCheck_Code
	ld	a, (xhl+wa)
	ex8	a, e
	xor	w, w
	div	wa, e
	dec	1, a
	cp	w, 0:i3
	jr	z, RhythmROM_NullRet	; -> 0xF633D4
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	jr	RhythmROM_NullRet	; -> 0xF633D4
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
	push	xhl
	ld	xhl, (13512:16)
	add	xhl, 977
	ld	w, (xhl)
	pop	xhl
	calr	RhythmROM_CalcPatternAddr
	ld	hl, (xhl)
	and	xhl, 65535
	add	hl, 6
	add	xhl, xix
	xor	e, e
	ld	a, (xhl)
	inc	1, xhl
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
	ld xix, (0x34c8:16)
	ld xiy, (0x34c8:16)
	cp (0x3453:16), 0x00
	jr nz, .Lc_f63445
	add XIX,0x00000000
	add XIY,0x00000118
DrumKit_DataTable_Entry1:
.Lc_f63445:
	cp (0x3453:16), 0x01
	jr nz, .Lc_f63458
	add XIX,0x0000000f
	add XIY,0x00000118
DrumKit_DataTable_Entry2:
.Lc_f63458:
	cp (0x3453:16), 0x02
	jr nz, .Lc_f6346b
	add XIX,0x00000400
	add XIY,0x00000518
DrumKit_DataTable_Entry3:
.Lc_f6346b:
	cp (0x3453:16), 0x03
	jr nz, .Lc_f6347e
	add XIX,0x0000040f
	add XIY,0x00000518
DrumKit_DataTable_Entry4:
.Lc_f6347e:
	ld xhl, 0:i3
	bit 0, (0x3515:16)
	jr nz, .Lc_f6348b
	ld XHL,0x00000026
DrumKit_DataTable_Entry5:
.Lc_f6348b:
	add XHL,XIY
	ld	a, (xix+0:8)
	calr	ToneData_LookupEffectParam
	ld	(0x34f0:16), a
	ld	(0x34ce:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	a, (xix+40)
	calr	ToneData_LookupEffectParam
	ld	(0x34f1:16), a
	ld	(0x34d0:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	a, (xix+80)
	calr	ToneData_LookupEffectParam
	ld	(0x34f2:16), a
	ld	(0x34d2:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	a, (xix+120)
	calr	ToneData_LookupEffectParam
	ld	(0x34f3:16), a
	ld	(0x34d4:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	a, (xix+160)
	calr	ToneData_LookupEffectParam
	ld	(0x34f4:16), a
	ld	(0x34d6:16), hl
	ld	xhl, 0:i3
	bit	0, (0x3515:16)
	jr	nz, DrumKit_DataTable_Entry6
	ld	xhl, 38
DrumKit_DataTable_Entry6:
	add	xhl, xiy
	ld	a, (xix+1)
	calr	ToneData_LookupEffectParam
	ld	(0x34f5:16), a
	ld	(0x34d8:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	a, (xix+41)
	calr	ToneData_LookupEffectParam
	ld	(0x34f6:16), a
	ld	(0x34da:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	a, (xix+81)
	calr	ToneData_LookupEffectParam
	ld	(0x34f7:16), a
	ld	(0x34dc:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	a, (xix+121)
	calr	ToneData_LookupEffectParam
	ld	(0x34f8:16), a
	ld	(0x34de:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	a, (xix+161)
	calr	ToneData_LookupEffectParam
	ld	(0x34f9:16), a
	ld	(0x34e0:16), hl
	ld	xhl, 0:i3
	bit	0, (0x3515:16)
	jr	nz, DrumKit_DataTable_Entry7
	ld	xhl, 38
DrumKit_DataTable_Entry7:
	add	xhl, xiy
	ld	a, (xix+2)
	calr	ToneData_LookupEffectParam
	ld	(0x3524:16), a
	ld	(0x351a:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	a, (xix+42)
	calr	ToneData_LookupEffectParam
	ld	(0x3525:16), a
	ld	(0x351c:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	a, (xix+82)
	calr	ToneData_LookupEffectParam
	ld	(0x3526:16), a
	ld	(0x351e:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	a, (xix+122)
	calr	ToneData_LookupEffectParam
	ld	(0x3527:16), a
	ld	(0x3520:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	a, (xix+162)
	calr	ToneData_LookupEffectParam
	ld	(0x3528:16), a
	ld	(0x3522:16), hl
	ld	xhl, 0:i3
	bit	0, (0x3515:16)
	jr	nz, DrumKit_DataTable_Entry8
	ld	xhl, 38
DrumKit_DataTable_Entry8:
	add	xhl, xiy
	ld	a, (xix+3)
	calr	ToneData_LookupEffectParam
	ld	(13620:16), a
	ld	(13610:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	a, (xix+43)
	calr	ToneData_LookupEffectParam
	ld	(13621:16), a
	ld	(13612:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	a, (xix+83)
	calr	ToneData_LookupEffectParam
	ld	(13622:16), a
	ld	(13614:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	a, (xix+123)
	calr	ToneData_LookupEffectParam
	ld	(13623:16), a
	ld	(13616:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	a, (xix+163)
	calr	ToneData_LookupEffectParam
	ld	(13624:16), a
	ld	(13618:16), hl
	ret
RhythmROM_LoadKit_InitLDA:
	nop
	nop

ToneData_LookupEffectParam:
	sla a, 1

	xor w, w

	ld	hl, (xhl+wa)

	push xix

	ld xix, (13512:16)

	add xix, 0x3d1

	ld a, (xix)

	pop xix

	ret



RhythmROM_LoadKit_Return:
	nop
	nop

ToneData_LookupEffectParam_Code:
	ld	xix, (0x34c8:16)
	add	xix, 977
	ld	a, (xix)
	ld	(0x34f0:16), a
	ld	(0x34f1:16), a
	ld	(0x34f2:16), a
	ld	(0x34f3:16), a
	ld	(0x34f4:16), a
	calr	RhythmROM_LoadKit_CopyReturn_Code
	ld	xiy, (0x34c8:16)
	xor	xhl, xhl
	ld	hl, (0x3518:16)
	add	xiy, xhl
	ld	xhl, 0:i3
	bit	0, (0x3515:16)
	jr	nz, RhythmROM_LoadKit_CopyLoop
	ld	xhl, 38
RhythmROM_LoadKit_CopyLoop:
	add	xhl, xiy
	ld	hl, (xhl)
	ld	(13518:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	hl, (xhl)
	ld	(13520:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	hl, (xhl)
	ld	(13522:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	hl, (xhl)
	ld	(13524:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	hl, (xhl)
	ld	(13526:16), hl
	ret
RhythmROM_LoadKit_CopyReturn:
	nop
	nop

RhythmROM_LoadKit_CopyReturn_Code:
	ld l, (13395:16)

	and l, 0xf

	xor h, h

	sla hl, 1

	; ld xix, VoiceSlot_ResolveIndex_0x2 (v7 patched)
	ld	xix, VoiceSlot_ResolveIndex_0x2
	ld	wa, (xix+hl)

	ld (13592:16), wa

	ret



VoiceSlot_ResolveIndex:
	.zero 8
	nop
	nop
	push	xwa
	normal
	push	xwa
	halt
	push	xix
	normal
	push	xix
	halt
	ldw	wa, 0x3201
	normal
	ldw	ix, 0x3601
	normal
	ldw	wa, 0x3205
	halt
	ldw	ix, 0x3605
	halt
	ret
	nop
	nop

VoiceSlot_Resolve_Loop:
	ld	w, (0x34f0:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34ce:16)
	ld	de, (0x34fc:16)
	bit	0, (0x3515:16)
	jr	nz, VoiceSlot_Resolve_CheckA
	bit	1, (0x3515:16)
	jr	nz, VoiceSlot_Resolve_CheckA
	jr	VoiceSlot_Resolve_CheckB
VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	and	(0x3514:16), 251
	ld	w, (0x34f1:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d0:16)
	ld	de, (0x34fe:16)
	bit	2, (0x3515:16)
	jr	z, VoiceSlot_Resolve_CheckC
	calr	RhythmBuf_LoadPattern
	jr	VoiceSlot_Resolve_StoreB
VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	and	(0x3514:16), 251
	ld	w, (0x34f2:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d2:16)
	ld	de, (0x3500:16)
	bit	3, (0x3515:16)
	jr	z, VoiceSlot_Resolve_CheckD
	calr	RhythmBuf_LoadPattern
	jr	VoiceSlot_Resolve_StoreC
VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	and	(0x3514:16), 251
	ld	w, (0x34f3:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d4:16)
	ld	de, (0x3502:16)
	bit	4, (0x3515:16)
	jr	z, VoiceSlot_Resolve_CheckE
	calr	RhythmBuf_LoadPattern
	jr	VoiceSlot_Resolve_StoreD
VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	and	(0x3514:16), 251
	ld	w, (0x34f4:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d6:16)
	ld	de, (0x3504:16)
	bit	5, (0x3515:16)
	jr	z, VoiceSlot_Resolve_StoreE
	calr	RhythmBuf_LoadPattern
	jr	VoiceSlot_Resolve_Done
VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	; anddi8 (0x35b0), 251 (v7 patched)
	and	(0x3514:16), 251
	ret



VoiceSlot_Resolve_StoreE_Code:
	.byte 0x00, 0x00, 0xc1, 0xf0, 0x34, 0x20, 0x1e, 0x01
	.byte 0xfb, 0xd1, 0xce, 0x34, 0x25, 0xd1, 0xe4, 0x34
	.byte 0x24, 0xd1, 0xfc, 0x34, 0x22, 0x1e, 0x41, 0x02
	.byte 0xc1, 0xf5, 0x34, 0x20, 0x1e, 0xeb, 0xfa, 0xd1
	.byte 0xd8, 0x34, 0x25, 0x1e, 0x33, 0x02, 0xc1, 0x14
	.byte 0x35, 0x3c, 0xfb, 0xc1, 0xf1, 0x34, 0x20, 0x1e
	.byte 0xd8, 0xfa, 0xd1, 0xd0, 0x34, 0x25, 0xd1, 0xe6
	.byte 0x34, 0x24, 0xd1, 0xfe, 0x34, 0x22, 0x1e, 0x18
	.byte 0x02, 0xc1, 0xf6, 0x34, 0x20, 0x1e, 0xc2, 0xfa
	.byte 0xd1, 0xda, 0x34, 0x25, 0x1e, 0x0a, 0x02, 0xc1
	.byte 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf2, 0x34, 0x20
	.byte 0x1e, 0xaf, 0xfa, 0xd1, 0xd2, 0x34, 0x25, 0xd1
	.byte 0xe8, 0x34, 0x24, 0xd1, 0x00, 0x35, 0x22, 0x1e
	.byte 0xef, 0x01, 0xc1, 0xf7, 0x34, 0x20, 0x1e, 0x99
	.byte 0xfa, 0xd1, 0xdc, 0x34, 0x25, 0x1e, 0xe1, 0x01
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf3, 0x34
	.byte 0x20, 0x1e, 0x86, 0xfa, 0xd1, 0xd4, 0x34, 0x25
	.byte 0xd1, 0xea, 0x34, 0x24, 0xd1, 0x02, 0x35, 0x22
	.byte 0x1e, 0xc6, 0x01, 0xc1, 0xf8, 0x34, 0x20, 0x1e
	.byte 0x70, 0xfa, 0xd1, 0xde, 0x34, 0x25, 0x1e, 0xb8
	.byte 0x01, 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf4
	.byte 0x34, 0x20, 0x1e, 0x5d, 0xfa, 0xd1, 0xd6, 0x34
	.byte 0x25, 0xd1, 0xec, 0x34, 0x24, 0xd1, 0x04, 0x35
	.byte 0x22, 0x1e, 0x9d, 0x01, 0xc1, 0xf9, 0x34, 0x20
	.byte 0x1e, 0x47, 0xfa, 0xd1, 0xe0, 0x34, 0x25, 0x1e
	.byte 0x8f, 0x01, 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0x0e
	.byte 0x00, 0x00
AccSection_ProcessEntry:
	ld w, (0x34f0:16)
	calr RhythmROM_CalcPatternAddr
	ld iy, (0x34ce:16)
	ld de, (0x34fc:16)
	bit 0, (0x3515:16)
	jr nz, AccSection_Process_Loop
	bit 1, (0x3515:16)
	jr nz, AccSection_Process_Loop
	jr t, AccSection_Process_Return
AccSection_Process_Loop:
	calr	RhythmBuf_LoadPattern
	ld	w, (13557:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (13528:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (13604:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (13594:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (13620:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (13610:16)
	calr	RhythmBuf_LoadPattern
	jr	AccSection_ProcessEntry_Join
AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join:
	and	(0x3514:16), 251
	ld	w, (0x34f1:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d0:16)
	ld	de, (0x34fe:16)
	bit	2, (0x3515:16)
	jr	z, AccSection_Process2_Return
	calr	RhythmBuf_LoadPattern
	ld	w, (0x34f6:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34da:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3525:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x351c:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3535:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x352c:16)
	calr	RhythmBuf_LoadPattern
	jr	AccSection_ProcessEntry_Join2
AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join2:
	and	(0x3514:16), 251
	ld	w, (0x34f2:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d2:16)
	ld	de, (0x3500:16)
	bit	3, (0x3515:16)
	jr	z, AccSection_Process3_Return
	calr	RhythmBuf_LoadPattern
	ld	w, (0x34f7:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34dc:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3526:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x351e:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3536:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x352e:16)
	calr	RhythmBuf_LoadPattern
	jr	AccSection_ProcessEntry_Join3
AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join3:
	and	(0x3514:16), 251
	ld	w, (0x34f3:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d4:16)
	ld	de, (0x3502:16)
	bit	4, (0x3515:16)
	jr	z, AccSection_Process4_Return
	calr	RhythmBuf_LoadPattern
	ld	w, (0x34f8:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34de:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3527:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3520:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3537:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3530:16)
	calr	RhythmBuf_LoadPattern
	jr	AccSection_ProcessEntry_Join4
AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Join4:
	and	(0x3514:16), 251
	ld	w, (0x34f4:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34d6:16)
	ld	de, (0x3504:16)
	bit	5, (0x3515:16)
	jr	z, AccSection_Process5_Return
	calr	RhythmBuf_LoadPattern
	ld	w, (0x34f9:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x34e0:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3528:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3522:16)
	calr	RhythmBuf_LoadPattern
	ld	w, (0x3538:16)
	calr	RhythmROM_CalcPatternAddr
	ld	iy, (0x3532:16)
	calr	RhythmBuf_LoadPattern
	jr	AccSection_ProcessEntry_Code
AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

AccSection_ProcessEntry_Code:
	; anddi8 (0x35b0), 251 (v7 patched)
	and	(0x3514:16), 251
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
	bit 0, (0x3514:16)
	jr z, .Lc_f63a39
	jp AccFill_AdvCheck_Done
AccFill_CheckPattern:
.Lc_f63a39:
	add IY,0x0006
	and XIY,0x0000ffff
	add XIY,XIX
	bit 2, (0x3514:16)
	jr z, .Lc_f63a4d
	jr t, AccFill_ProcessDone
AccFill_ProcessEntry:
.Lc_f63a4d:
	or (0x3514:16), 0x04
	ld (0x34fa:16), de

	ld xiz, 6:i3



AccFill_ProcessDone:
	ld	a, (xiy)
	ld	hl, (13562:16)
	calr	AccPat_IndexToAddress
	add	xhl, xiz
	ld	(xhl), a
AccFill_ProcessDone_Join:
	cp	a, 131
	jr	z, AccFill_AdvCheck_Return
	inc	1, xiy
	inc	1, xiz
	cp	xiz, 254
	jr	ule, AccFill_AdvanceAndCheck
	calr	AccFill_ProcessDone_Helper
	bit	0, (0x3514:16)
	jr	nz, AccFill_AdvCheck_Return
	push	xiy
	ld	hl, (0x34fa:16)
	calr	AccPat_IndexToAddress
	ld	xiy, 3:i3
	add	xiy, xhl
	ld	(xiy), de
	ld	hl, de
	calr	AccPat_IndexToAddress
	ld	xiy, 1:i3
	add	xiy, xhl
	ld	wa, (0x34fa:16)
	ld	(xiy), wa
	ld	(0x34fa:16), de
	or	(xhl), 128
	decw	1, (0x3438:16)
	ld	xiz, 6:i3
	pop	xiy
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
	ld xiy, (0x34c4:16)
	ld L,(XIY+0x0c)
	xor H,H
	ld XIX,AccFill_AdvanceAndCheck_Code
	ld	w, (xix+hl)
	ld A,(XIY+0x0d)
	and A,0x07
	inc 1,A
	mul	wa, w
	push	xwa
	ld	hl, de
	calr	AccPat_IndexToAddress
	pop	xwa
	add	xhl, 6
	ld	e, a
	ld	a, 129:opc
StyleConvert_ReloadParams:
	ld (xhl), a
	inc 1, xhl
	dec 1, e
	cp e, 0:i3
	jr nz, StyleConvert_ReloadParams
	ld (xhl), 0x83
	ret

StyleConvert_Reload_Loop:
	.byte 0x00, 0x00, 0xc1, 0x53, 0x34, 0x3f, 0x10, 0x63
	.byte 0x1e, 0x21, 0x7b, 0xc1, 0x51, 0x34, 0x3f, 0x84
	.byte 0x67, 0x0d, 0xc9, 0xc8, 0x06, 0xc1, 0x51, 0x34
	.byte 0x3f, 0x88, 0x67, 0x03, 0xc9, 0xc8, 0x06, 0xc1
	.byte 0x53, 0x34, 0x81, 0xf1, 0x51, 0x34, 0x41, 0x0e
	.byte 0x00, 0x00
AccPat_CalcAccentVelocity:
	cp	(13395:16), 19
	jr	ule, StyleConvert_Reload_Return
	ld	a, 120:opc
	cp	(13393:16), 132
	jr	c, StyleConvert_Reload_CheckEnd
	add	a, 6
	cp	(13393:16), 136
	jr	c, StyleConvert_Reload_CheckEnd
	add	a, 6
StyleConvert_Reload_CheckEnd:
	add	a, (13395:16)
	ld	(13393:16), a
	jr	StyleConvert_Reload_Done
StyleConvert_Reload_Return:
	cp	(0x3453:16), 16
	jr	c, StyleConvert_Reload_Done
	ld	a, 112:opc
	cp	(0x3451:16), 132
	jr	c, StyleConvert_Reload_Fallback
	add	a, 4
	cp	(0x3451:16), 136
	jr	c, StyleConvert_Reload_Fallback
	add	a, 4
StyleConvert_Reload_Fallback:
	add	a, (13395:16)
	ld	(13393:16), a
StyleConvert_Reload_Done:
	ret

StyleConvert_Reload_Fallback_Code:
	.byte 0xc1, 0x51, 0x34, 0x27, 0xc1, 0x52, 0x34, 0x26
	.byte 0x1d, 0xe1, 0x2e, 0xf5, 0xdb, 0x8a, 0x45, 0xbe
	.byte 0x3b, 0xf6, 0x00, 0xdb, 0xd3, 0xd3, 0x07, 0xf4
	.byte 0xec, 0x20, 0xd8, 0xcf, 0xff, 0xff, 0x66, 0x0e
	.byte 0xda, 0xf0, 0x66, 0x06, 0xdb, 0xc8, 0x02, 0x00
	.byte 0x68, 0xeb, 0x21, 0x01, 0x68, 0x02, 0x21, 0x00
	.byte 0x0e, 0x00, 0x00, 0x06, 0x00, 0x06, 0x01, 0x06
	.byte 0x02, 0x06, 0x03, 0x07, 0x00, 0x07, 0x01, 0x07
	.byte 0x02, 0xff, 0xff, 0xff, 0xff, 0xc1, 0x51, 0x34
	.byte 0x27, 0xc1, 0x3a, 0x34, 0x26, 0xcf, 0xcf, 0x80
	.byte 0x6f, 0x2a, 0xce, 0xcf, 0x0c, 0x6f, 0x0c, 0x21
	.byte 0x00, 0xc1, 0x61, 0xfc, 0x20, 0x66, 0x02, 0x21
	.byte 0x01, 0x68, 0x30, 0xc1, 0x3a, 0x34, 0x21, 0xc9
	.byte 0xca, 0x0c, 0xc9, 0xcc, 0x03, 0xc1, 0x61, 0xfc
	.byte 0x20, 0x66, 0x03, 0xc9, 0xce, 0x04, 0xdb, 0xd3
	.byte 0xc9, 0x8f, 0x68, 0x17, 0xce, 0xcf, 0x0c, 0x6f
	.byte 0x04, 0x21, 0x00, 0x68, 0x0e, 0xc1, 0x3a, 0x34
	.byte 0x21, 0xc9, 0xca, 0x0c, 0xc9, 0xcc, 0x03, 0xdb
	.byte 0xd3, 0xc9, 0x8f, 0xf1, 0x53, 0x34, 0x41, 0x0e
	.byte 0x00, 0x00, 0x04, 0x08, 0x09, 0x06, 0x04, 0x08
	.byte 0x09, 0x06, 0x0e, 0xf1, 0x35, 0x34, 0xc8, 0x6e
	.byte 0x04, 0x1b, 0x33, 0x3d, 0xf6, 0xc1, 0x3a, 0x34
	.byte 0x27, 0xc1, 0x51, 0x34, 0x21, 0xc1, 0x52, 0x34
	.byte 0x20, 0x2b, 0x28, 0xc1, 0x51, 0x34, 0x3f, 0x80
	.byte 0x67, 0x04, 0x1b, 0x18, 0x3d, 0xf6, 0xc1, 0x3a
	.byte 0x34, 0x3f, 0x00, 0x66, 0x04, 0x1b, 0x18, 0x3d
	.byte 0xf6, 0xf1, 0x3a, 0x34, 0x00, 0x00, 0xf1, 0x3a
	.byte 0x34, 0x00, 0x06, 0xf1, 0x3a, 0x34, 0x00, 0x07
	.byte 0xf1, 0x3a, 0x34, 0x00, 0x08, 0xf1, 0x3a, 0x34
	.byte 0x00, 0x09, 0xc1, 0x14, 0x35, 0x3c, 0xf7, 0xf1
	.byte 0x53, 0x34, 0x00, 0x00, 0xf1, 0x3a, 0x34, 0x00
	.byte 0x00, 0xc1, 0x35, 0x34, 0x3e, 0x01, 0x1e, 0xbf
	.byte 0xf0, 0xf1, 0x14, 0x35, 0xc8, 0x66, 0x05, 0xc1
	.byte 0x14, 0x35, 0x3e, 0x08, 0xf1, 0x53, 0x34, 0x00
	.byte 0x04, 0xf1, 0x3a, 0x34, 0x00, 0x06, 0xc1, 0x35
	.byte 0x34, 0x3e, 0x01, 0x1e, 0xa2, 0xf0, 0xf1, 0x14
	.byte 0x35, 0xc8, 0x66, 0x05, 0xc1, 0x14, 0x35, 0x3e
	.byte 0x08, 0xf1, 0x53, 0x34, 0x00, 0x08, 0xf1, 0x3a
	.byte 0x34, 0x00, 0x07, 0xc1, 0x35, 0x34, 0x3e, 0x01
	.byte 0x1e, 0x85, 0xf0, 0xf1, 0x14, 0x35, 0xc8, 0x66
	.byte 0x05, 0xc1, 0x14, 0x35, 0x3e, 0x08, 0xf1, 0x53
	.byte 0x34, 0x00, 0x09, 0xf1, 0x3a, 0x34, 0x00, 0x08
	.byte 0xc1, 0x35, 0x34, 0x3e, 0x01, 0x1e, 0x68, 0xf0
	.byte 0xf1, 0x14, 0x35, 0xc8, 0x66, 0x05, 0xc1, 0x14
	.byte 0x35, 0x3e, 0x08, 0xf1, 0x53, 0x34, 0x00, 0x06
	.byte 0xf1, 0x3a, 0x34, 0x00, 0x09, 0xc1, 0x35, 0x34
	.byte 0x3e, 0x01, 0x1e, 0x4b, 0xf0, 0xf1, 0x14, 0x35
	.byte 0xc8, 0x66, 0x05, 0xc1, 0x14, 0x35, 0x3e, 0x08
	.byte 0xf1, 0x14, 0x35, 0xcb, 0x66, 0x05, 0xc1, 0x14
	.byte 0x35, 0x3e, 0x01, 0x68, 0x0d, 0xf1, 0x53, 0x34
	.byte 0x00, 0x00, 0xc1, 0x35, 0x34, 0x3e, 0x01, 0x1e
	.byte 0x26, 0xf0, 0x48, 0x4b, 0xf1, 0x52, 0x34, 0x40
	.byte 0xf1, 0x51, 0x34, 0x41, 0xf1, 0x3a, 0x34, 0x47
StyleConvert_Reload_Fallback_Code2:
	.byte 0x0e, 0x00, 0x00
AccWidget_DispatchTable:
	ld xiy, 0x9b4000
	ld xix, 0x94800
	ldw bc, 0x8000
	ldirw
	jp AccWidget_Dispatch_Return

AccWidget_Dispatch_Return:
	ret

AccWidget_DispatchTable_Pad:
	nop
	nop
AccWidget_ProcessSpecialCmd:
	cp	(13394:16), 0
	jr	nz, AccWidget_ProcessSpecialCmd_Code
	ld	a, (13393:16)
	and	a, 127
	ld	xix, DrumKit_GroupAssignTable
	ld	a, (xix+a)
	ld	w, (13370:16)
	sub	w, 30
	cp	a, w
	jrl	z, DrumKit_Return
AccWidget_ProcessSpecialCmd_Code:
	ld	a, (13393:16)
	ld	w, (13394:16)
	ld	l, (13395:16)
	ld	h, (13370:16)
	pushw	wa
	pushw	hl
	or	(0x3431:16), 128
	ld	(13395:16), 16
	ld	l, (13370:16)
	sub	l, 30
	ld	(14601:16), l
	ld	xix, AccWidget_ProcessSpecialCmd_Data
	ld	l, (xix+l)
	ld	(13370:16), l
	ld	(14602:16), l
	calr	AccPat_CalcAccentVelocity
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 17
	ld	l, (14602:16)
	inc	1, l
	ld	(13370:16), l
	calr	AccPat_CalcAccentVelocity
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 18
	ld	l, (14602:16)
	add	l, 2
	ld	(13370:16), l
	calr	AccPat_CalcAccentVelocity
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 19
	ld	l, (14602:16)
	add	l, 3
	ld	(13370:16), l
	calr	AccPat_CalcAccentVelocity
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 20
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_2
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 21
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_3
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 22
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_4
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 23
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_5
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 24
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_6
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_ErrorFallbackLoop
	ld	(13395:16), 25
	ld	a, (13393:16)
	pushw	wa
	calr	AccPat_CalcAccentVelocity
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_7
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	ld	a, (13393:16)
	and	a, 127
	ld	(14608:16), a
	ld	a, (13370:16)
	ld	(14609:16), a
	push	xix
	ld	xix, 608256
	ld	(14610:16), xix
	ld	(14614:16), xix
	pop	xix
	calr	AccPatch_LoadDualVoiceParams
	popw	wa
	ld	(13393:16), a
	bit	0, (0x3514:16)
	jr	z, DrumKit_SetErrorCode20
DrumKit_ErrorFallbackLoop:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_ErrorFallbackSlotIter:
	ld	a, (14601:16)
	ld	w, a
	sll	a, 3
	sll	w, 1
	add	a, w
	extz	wa
	extz	xwa
	add	xwa, xix
	ld	a, (xwa+c)
	ld	(13370:16), a
	push	xbc
	push	xix
	call	AccPat_InitWorkAreaFromSlot
	pop	xix
	pop	xbc
	inc	1, c
	cp	c, 10
	jr	c, DrumKit_ErrorFallbackSlotIter
	ld	(32422:16), 23
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	jr	DrumKit_RestoreRegisters
DrumKit_SetErrorCode20:
	ld	(32422:16), 20
	call	DrumVoice_NotifyEE
DrumKit_RestoreRegisters:
	popw	hl
	popw	wa
	ld	(13395:16), l
	ld	(13370:16), h
	ld	(13394:16), w
	ld	(13393:16), a
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
	ld	a, (13393:16)
	ld	w, (13394:16)
	ld	l, (13395:16)
	ld	h, (13370:16)
	pushw	wa
	pushw	hl
	ld	(13395:16), 0
	ld	l, (13370:16)
	sub	l, 30
	ld	(14601:16), l
	sll	l, 2
	ld	xix, RhythmROM_LoadDrumKit_Data
	ld	l, (xix+l)
	ld	(13370:16), l
	ld	(14602:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 1
	ld	l, (14602:16)
	inc	1, l
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 2
	ld	l, (14602:16)
	add	l, 2
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 3
	ld	l, (14602:16)
	add	l, 3
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 4
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_2
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 5
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_3
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 10
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_4
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 11
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_5
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jrl	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 6
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_6
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jr	nz, DrumKit_PatternLoadFailed
	ld	(13395:16), 7
	ld	l, (14601:16)
	ld	xix, AccWidget_ProcessSpecialCmd_Data_7
	ld	l, (xix+l)
	ld	(13370:16), l
	call	AccPat_InitWorkAreaFromSlot
	calr	RhythmROM_PatternDispatcher
	bit	0, (0x3514:16)
	jr	z, DrumKit_AllPatternsOK
DrumKit_PatternLoadFailed:
	xor c, c
	ld xix, DrumKit_FallbackSlotTable

DrumKit_FallbackSlotLoop:
	ld	a, (14601:16)
	ld	w, a
	sll	a, 3
	sll	w, 1
	add	a, w
	extz	wa
	extz	xwa
	add	xwa, xix
	ld	a, (xwa+c)
	ld	(13370:16), a
	push	xbc
	push	xix
	call	AccPat_InitWorkAreaFromSlot
	pop	xix
	pop	xbc
	inc	1, c
	cp	c, 10
	jr	c, DrumKit_FallbackSlotLoop
	ld	(32422:16), 23
	call	DrumVoice_NotifyEE
	ld	a, 8:opc
	call	MIDI_SendSysExCmd
	jr	DrumKit_Epilogue
DrumKit_AllPatternsOK:
	ld	(32422:16), 20
	call	DrumVoice_NotifyEE
DrumKit_Epilogue:
	popw	hl
	popw	wa
	ld	(13370:16), h
	ld	(13395:16), l
	ld	(13394:16), w
	ld	(13393:16), a
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
; readers in v7 (address from the linked ELF): DrumParam_Lookup 0xF64348
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	ld	a, 72:opc
	call	CtrlPanel_SetIndicatorBit
	cp	(35993:16), 14
	jr	nz, DrumKitInit_Setup
	jrl	DrumKitInit_Return
DrumKitInit_Setup:
	ld	(13397:16), 0
	ld	(13375:16), 0
	ld	(13944:16), 4
	ld	(13945:16), 0
	ld	(13946:16), 1
	call	AccWrap_PlayModeDispatch
	or	(0x28a7:16), 4
	ld	(14079:16), 64
	ld	a, (64602:16)
	ld	(13393:16), a
	ld	a, (64603:16)
	ld	(13394:16), a
	ld	a, (64602:16)
	ld	(13455:16), a
	ld	a, (64603:16)
	ld	(13456:16), a
	calr	DrumKit_SendProgramChange
	bit	2, (0xfc5f:16)
	jr	nz, DrumKitInit_ClearAssignFlags
	bit	3, (0xfc5f:16)
	jr	z, DrumKitInit_CheckExtAssign
DrumKitInit_ClearAssignFlags:
	and (0xfc5f:16), 243

	ld d, 0x5:opc

	ld e, 0x48:opc

	xor wa, wa

	; call SwbtWr_QueuePostEvent (v7 addr)
	call	SysEx_ApplyVoiceParam_49
DrumKitInit_CheckExtAssign:
	bit	2, (0xfc60:16)
	jr	z, DrumKitInit_FinalSetup
	and	(0xfc60:16), 251
	ld	d, 6:opc
	ld	e, 72:opc
	xor	wa, wa
	call	SysEx_ApplyVoiceParam_49
DrumKitInit_FinalSetup:
	call	AccPatch_CountSlots_Wrapper
	ld	(0x3470:16), 0
	call	SeqAcc_SetIndicator_PB
	ldw	(0xf19e:16), 0
	call	PerfMode_Handler_EvtB_Helper2_Helper11
	and	(0xe31c:16), 158
	or	(0x3431:16), 64
DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	ld	xhl, 0:i3
	ld	l, (13370:16)
	cp	l, 30
	jr	c, DrumKit_SendPC_MaskAndSend
	sub	l, 30
	sll	l, 2
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
	ld A, 0x48:opc
	call CtrlPanel_SetIndicatorBit
	cp (0x8c98:16), 0x0e
	jr nz, .Lc_f64737
	jrl t, DrumKitExit_Return
DrumKitExit_CheckState1:
.Lc_f64737:
	cp (0x8c98:16), 0x01
	jr z, .Lc_f64743
	and (0x8cec:16), 0xfe
DrumKitExit_ClearFlags:
.Lc_f64743:
	and (0x28a7:16), 0xfb
	and (0xe31c:16), 0xfe
	and (0xe31c:16), 0xf7
	and (0xe31c:16), 0xdf
	ld (0x3455:16), 0x00
	ld (0x36ff:16), 0x00
	push XWA
	push XHL
	push XBC
	push XDE
	push XIX
	push XIY
	push XIZ
	call PartSelect_UpdateDisplayState
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	bit 6, (0x3431:16)
	jr z, DrumKitExit_PostRestore
	and (0x3431:16), 0xbf
	ld a, (0x348f:16)
	ld (0xfc5a:16), a
	ld a, (0x3490:16)
	and A,0x7f
	and (0xfc5b:16), 0x80
	or	(0xfc5b:16), a
	calr	DrumKit_PostMidiEvents
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
	bit	0, (0x31e7:16)
	jr	nz, DrumKitExit_Return
	or	(0x3431:16), 128
DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
DrumKit_ValidateBank_Wrap:
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
	push	l
	calr	DrumKit_StoreAndSendBank
	pop	l
	and	l, 31
	ld	(13370:16), l
	calr	DrumKit_SendProgramChange
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
	ld	e, 72:opc
	ld	a, (64603:16)
	and	a, 127
	ld	d, 1:opc
	ld	w, 0:opc
	push_a
	call	SysEx_ApplyVoiceParam_49
	pop_a
	ld	h, a
	ld	e, 72:opc
	ld	a, (64602:16)
	and	a, 255
	ld	d, 0:opc
	ld	w, 0:opc
	push	h
	push_a
	call	SysEx_ApplyVoiceParam_49
	pop_a
	pop	h
	ld	l, a
	ld	(36955:16), 72
	call	PartCtrl_WriteProgramChange
	ld	c, 72:opc
	call	MIDI_SetupChannelParams
	ret
DrumKit_UpdateStatusFlags:
	ld	w, (13397:16)
	and	w, 194
	bit	7, w
	jr	z, DrumKit_StoreStatus
	ld	a, (14079:16)
	bit	4, a
	jr	z, DrumKit_StatusBit3
	or	w, 60
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
	ld	(13397:16), w
	ret
DrumKit_InlineCode1:
	push	xiz
	call	DrumKit_UpdateStatusFlags_Helper
	pop	xiz
	ret
DrumKit_UpdateStatusFlags_Helper:
	ret
CmpBkslTtl_Dispatch_Helper:
	push XIZ
	call DrumKit_InlineCode1_Helper
	pop XIZ
	ret
DrumKit_InlineCode1_Helper:
	cp	(35995:16), 177
	jr	z, DrumKit_UpdateStatusFlags_Entry
	calr	DrumKit_UpdateStatusFlags_Helper3
	ld	(14079:16), 64
	and	(0x3431:16), 191
	calr	DrumKit_UpdateStatusFlags_Helper2
DrumKit_UpdateStatusFlags_Entry:
	and	(0xe31c:16), 158
	ret
DrumKit_UpdateStatusFlags_Helper2:
	ld	e, (13361:16)
	and	e, 48
	ld	xhl, 0:i3
	ld	l, (13370:16)
	ld	xwa, DrumKit_InlineCode1_Code
	add	xwa, xhl
	ld	a, (xwa)
	cp	a, e
	jr	z, DrumKit_UpdateStatusFlags_Return
	cp	e, 0:i3
	jr	nz, DrumKit_UpdateStatusFlags_Helper2_Skip
	ld	l, 0:opc
	jr	DrumKit_UpdateStatusFlags_Helper2_Join
DrumKit_UpdateStatusFlags_Helper2_Skip:
	cp	e, 32
	jr	nz, DrumKit_UpdateStatusFlags_Helper2_Skip2
	ld	l, 4:opc
	jr	DrumKit_UpdateStatusFlags_Helper2_Join
DrumKit_UpdateStatusFlags_Helper2_Skip2:
	ld	l, 8:opc
DrumKit_UpdateStatusFlags_Helper2_Join:
	ld	(13370:16), l
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
	ld	w, 32:opc
	ld	w, 32:opc
	ld	w, 32:opc
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
DrumKit_UpdateStatusFlags_Sub:
	push	xiz
	call	DrumKit_UpdateStatusFlags_Helper3
	pop	xiz
	ret
DrumKit_UpdateStatusFlags_Helper3:
	xor	xwa, xwa
	xor	xde, xde
	ld	a, (64605:16)
	and	a, 7
	cp	a, 0:i3
	jr	nz, DrumKit_UpdateStatusFlags_Return2
	ld	a, 2:opc
	ld	w, 7:opc
	ld	e, 72:opc
	ld	d, 3:opc
	call	SwbtWr_TrailingBytecode
	ld	a, 8:opc
	or (64605:16), a
	ld	w, 8:opc
	ld	e, 72:opc
	ld	d, 3:opc
	call	SysEx_ApplyVoiceParam_49
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
	ld	e, (13361:16)
	and	e, 48
	cp	e, 0:i3
	jr	nz, DrumSlot_OffsetCalc_Check20
	jr	DrumSlot_OffsetCalc_StoreAndRet
DrumSlot_OffsetCalc_Check20:
	cp e, 0x20
	jr nz, DrumSlot_OffsetCalc_AddHigh
	add l, 0x04
	jr t, DrumSlot_OffsetCalc_StoreAndRet
DrumSlot_OffsetCalc_AddHigh:
	add l, 0x08
DrumSlot_OffsetCalc_StoreAndRet:
	ld	(13370:16), l
	ret
DrumSlot_OffsetCalc_Extended:
	ld	e, (13361:16)
	and	e, 48
	cp	e, 0:i3
	jr	nz, DrumSlot_ExtOffset_Check20
	add	l, 8
	jr	DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_Check20:
	cp e, 0x20
	jr nz, DrumSlot_ExtOffset_AddHigh
	add l, 0x0e
	jr t, DrumSlot_ExtOffset_StoreAndRet
DrumSlot_ExtOffset_AddHigh:
	add l, 0x14
DrumSlot_ExtOffset_StoreAndRet:
	ld	(13370:16), l
	ret
RhythmPatInit_Wrapper:
	; --- Push XIZ wrapper for inner routine (7 bytes) ---
	push xiz
	call RhythmPatInit_Entry
	pop xiz
	ret
RhythmPatInit_Entry:
	cp (0x8c9b:16), 0xb2
	jr z, .Lc_f64a0a
	calr RhythmPatInit_LoadParams
	ld (0x36ff:16), 0x20
	cp (0x8c9b:16), 0xb5
	jr nz, .Lc_f64a0a
	call AccWrap_PlayModeDispatch
	or (0x28a7:16), 0x04
	jr t, .Lc_f64a0a
RhythmPatInit_Cleanup:
.Lc_f64a0a:
	and (0xe31c:16), 0x9e

	ret





RhythmPatInit_LoadParams:
	call AccPatch_GetCurrentSlotAddr
	ld A,(XIY+0x0c)
	ld (0x343c:16), a
	ld L,A
	ld XWA,RhythmPatInit_KitIndexTable
	ld	a, (xwa+l)
	ld	(0x343d:16), a
	ld	a, (xiy+13)
	ld	(0x343b:16), a
	and	(0x3432:16), 127
	ld	a, (xiy+15)
	bit	7, a
	jr	z, RhythmPatInit_FlagBit7
	or	(0x3432:16), 128
RhythmPatInit_FlagBit7:
	ld	a, (xiy+14)
	ld	w, a
	and	a, 15
	ld	(0x344d:16), a
	and	(0x344e:16), 143
	bit	4, w
	jr	z, RhythmPatInit_Tempo4
	or	(0x344e:16), 16
RhythmPatInit_Tempo4:
	bit	5, w
	jr	z, RhythmPatInit_Tempo5
	or	(0x344e:16), 32
RhythmPatInit_Tempo5:
	bit	6, w
	jr	z, RhythmPatInit_CopyChannels
	or	(0x344e:16), 64
RhythmPatInit_CopyChannels:
	add xiy, 0x40

	ld xix, 13344

	ld xbc, 0xd

	ldir85

	ld (xix+), 0x00

	ld (xix+), 0x00

	ld (xix), 0x0

	ret



RhythmPatInit_KitIndexTable:
	.byte 0x02, 0x04, 0x06, 0x08, 0x01, 0x02, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x08, 0x01, 0x02, 0x03, 0x04
	.byte 0x05, 0x06, 0x07, 0x08, 0x3e, 0x1d, 0xac, 0x4a
	.byte 0xf6, 0x5e, 0x0e, 0x2b, 0xeb, 0xa8, 0x4b, 0x44
	.byte 0xc4, 0x4a, 0xf6, 0x00, 0xdb, 0xcc, 0x03, 0x00
	.byte 0xdb, 0xee, 0x02, 0xe3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xb3, 0xe8, 0x0e, 0xd5, 0x4a, 0xf6, 0x00, 0xfb
	.byte 0x4a, 0xf6, 0x00, 0x11, 0x4b, 0xf6, 0x00, 0xd4
	.byte 0x4a, 0xf6, 0x00, 0x0e, 0xc1, 0x70, 0x34, 0x3f
	.byte 0x01, 0x66, 0x07, 0xf1, 0x70, 0x34, 0x00, 0x01
	.byte 0x68, 0x17, 0xc1, 0x31, 0x34, 0x3e, 0x04, 0xf1
	.byte 0x70, 0x34, 0x00, 0x00, 0xf1, 0xa6, 0x7e, 0x00
	.byte 0x23, 0x1e, 0xf9, 0x09, 0xc1, 0xec, 0x8c, 0x3e
	.byte 0x01, 0x0e, 0xc1, 0x70, 0x34, 0x3f, 0x01, 0x66
	.byte 0x09, 0xc1, 0x3a, 0x34, 0x3f, 0x0b, 0x6b, 0x00
	.byte 0x68, 0x05, 0xf1, 0x70, 0x34, 0x00, 0x00, 0x0e
	.byte 0xc1, 0x70, 0x34, 0x3f, 0x01, 0x66, 0x02, 0x68
	.byte 0x00, 0x0e
RhythmFillIn_Wrapper:
	push xiz
	call RhythmFillIn_Select
	pop xiz
	ret

RhythmFillIn_Select:
	and	(0xe31c:16), 247
	ld	xwa, RhythmFillIn_PatternTable
	cp	hl, 4:i3
	jr	c, RhythmFillIn_LookupAndApply
	sub	hl, 4
RhythmFillIn_LookupAndApply:
	ld	a, (xwa+hl)
	ld	(14079:16), a
	calr	DrumKit_UpdateStatusFlags
	call	AudioInit_SelectAndDispatch
	call	DkMdlyPly_CheckState_Helper2
	ret
RhythmFillIn_PatternTable:
	.incbin "includes/romslices/v7_transplant_RhythmFillIn_PatternTable_head.bin"
RhythmFillIn_PatternTable_Sub:
	push XIZ
	call RhythmFillIn_PatternTable_Code_Helper
	pop XIZ
	ret
RhythmFillIn_PatternTable_Code_Helper:
	and	(0x28a7:16), 251
	and	(0xe31c:16), 254
	cp	(0x8c9b:16), 181
	jr	z, RhythmFillIn_PatternTable_Code_Helper_Return
	or	(0x8cec:16), 1
	bit	0, (0x31e7:16)
	jr	nz, RhythmFillIn_PatternTable_Code_Helper_Return
	or	(0x3431:16), 128
	call	Seq_DispatcherEntry
	cp	(0x8c9b:16), 178
	jr	nz, RhythmFillIn_PatternTable_Code_Helper_Return
	call	AccWrap_PlayModeStartAccPlay
RhythmFillIn_PatternTable_Code_Helper_Return:
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
	or (0xe31c:16), 0x08
	inc 1, (0x343f:16)
	cp (0x343f:16), 0x04
	jr nz, .Lc_f64bab
	ld (0x343f:16), 0x00
	jr t, RhythmMute_StateDone
RhythmMute_State1:
.Lc_f64bab:
	cp (0x343f:16), 0x01
	jr nz, .Lc_f64bb9
	ld (0x343f:16), 0x04
	jr t, RhythmMute_StateDone
RhythmMute_State8:
.Lc_f64bb9:
	cp (0x343f:16), 0x08
	jr nz, RhythmMute_StateDone
	ld (0x343f:16), 0x01
RhythmMute_StateDone:
	ret

RhythmMute_InlineCode:
	or	(0xe31c:16), 8
	bit	7, w
	jr	nz, RhythmMute_StateMachine_Skip3
	cp	(0x343f:16), 0
	jr	nz, RhythmMute_StateMachine_Skip
	ld	(0x343f:16), 4
	jr	RhythmMute_StateMachine_Join
RhythmMute_StateMachine_Skip:
	cp	(0x343f:16), 3
	jr	nz, RhythmMute_StateMachine_Skip2
	ld	(0x343f:16), 0
	jr	RhythmMute_StateMachine_Join
RhythmMute_StateMachine_Skip2:
	cp	(0x343f:16), 7
	jr	z, RhythmMute_StateMachine_Join
	inc	1, (0x343f:16)
RhythmMute_StateMachine_Join:
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip3:
	cp	(0x343f:16), 0
	jr	nz, RhythmMute_StateMachine_Skip4
	ld	(0x343f:16), 3
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip4:
	cp	(0x343f:16), 4
	jr	nz, RhythmMute_StateMachine_Skip5
	ld	(0x343f:16), 0
	jr	RhythmMute_StateMachine_Return
RhythmMute_StateMachine_Skip5:
	cp	(0x343f:16), 1
	jr	z, RhythmMute_StateMachine_Return
	dec	1, (0x343f:16)
RhythmMute_StateMachine_Return:
	ret
RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	bit	7, (0x3455:16)
	jr	nz, RhythmSolo_Disable
	ld	(0x3455:16), 128
	jr	RhythmSolo_UpdateStatus
RhythmSolo_Disable:
	ld	(13397:16), 0
RhythmSolo_UpdateStatus:
	calr	DrumKit_UpdateStatusFlags
	bit	0, (0x31e7:16)
	jr	nz, RhythmSolo_Return
	or	(0x3431:16), 128
RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	ld	a, (0x3433:16)
	and	a, 12
	cp	a, 0:i3
	jr	nz, RhythmVariation_Return
	ld	a, (0x3560:16)
	and	a, 12
	cp	a, 0:i3
	jr	nz, RhythmVariation_Return
	and	hl, 15
	ld	xwa, RhythmFillIn_PatternTable
	ld	a, (xwa+hl)
	ld	(0x36ff:16), a
	calr	DrumKit_UpdateStatusFlags
	bit	0, (0x31e7:16)
	jr	nz, RhythmVariation_PostDispatch
	or	(0x3431:16), 128
RhythmVariation_PostDispatch:
	call	AudioInit_SelectAndDispatch
	call	DkMdlyPly_CheckState_Helper2
RhythmVariation_Return:
	ret
RhythmVariation_InlineCode:
	calr	DrumKit_UpdateStatusFlags
	ret
AccDraw_Secondary_Helper:
	push	xiz
	calr	RhythmVariation_Select_Code_Helper
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper:
	cp	(35995:16), 182
	jr	z, RhythmVariation_Select_Code_Helper_Skip
	ld	(13942:16), 4
	or	(0x8cec:16), 1
RhythmVariation_Select_Code_Helper_Skip:
	and	(0xe31c:16), 254
	or	(0x3431:16), 8
	ret
AccDraw_Secondary_Helper8_Helper:
	push	xiz
	calr	RhythmVariation_Select_Code_Helper2
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper2:
	and	(0x3431:16), 247
	ret
AccDraw_Secondary_Helper2:
	push	xiz
	calr	RhythmVariation_Select_Code_Helper3
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper3:
	ld	xhl, 0:i3
	ld	l, (14079:16)
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_Code
	ld	a, (xhl)
	ld	(14079:16), a
	call	16635678
	call	16635862
	calr	DrumKit_UpdateStatusFlags
	ret
RhythmVariation_InlineCode_Code:
	nop
	ld	(1:8), 0:io
	push	sr
	nop
	nop
	nop
	ld	(0:8), 0:io
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
RhythmVariation_Select_Code_Sub:
	push	xiz
	calr	RhythmVariation_Select_Code_Sub_Helper
	pop	xiz
	ret
RhythmVariation_Select_Code_Sub_Helper:
	ld	xhl, 0:i3
	ld	l, (14079:16)
	and	l, 31
	add	xhl, RhythmVariation_InlineCode_Code2
	ld	a, (xhl)
	ld	(14079:16), a
	call	16635678
	call	16635862
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret
AccDraw_Secondary_Helper3:
	push	xiz
	calr	AccDraw_Secondary_Helper3_Helper
	pop	xiz
	ret
AccDraw_Secondary_Helper3_Helper:
	cp	(13942:16), 4
	jr	z, AccDraw_Secondary_Helper3_Skip
	jr	RhythmVariation_Select_Code_Return
AccDraw_Secondary_Helper3_Skip:
	bit	7, w
	jr	nz, AccDraw_Secondary_Helper3_Skip2
	inc	1, (13944:16)
	cp	(13944:16), 13
	jr	ule, RhythmVariation_Select_Code_Join
	ld	(13944:16), 13
	jr	RhythmVariation_Select_Code_Join
AccDraw_Secondary_Helper3_Skip2:
	dec	1, (13944:16)
	cp	(13944:16), 1
	jr	ge, RhythmVariation_Select_Code_Join
	ld	(13944:16), 1
RhythmVariation_Select_Code_Join:
	jr	RhythmVariation_Select_Code_Return
RhythmVariation_Select_Code_Return:
	ret
AccDraw_Secondary_Helper4:
	push	xiz
	calr	RhythmVariation_Select_Code_Helper4
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper4:
	cp	(13942:16), 4
	jr	nz, RhythmVariation_Select_Code_Return2
	bit	7, w
	jr	nz, RhythmVariation_Select_Code_Skip
	inc	1, (13945:16)
	cp	(13945:16), 13
	jr	ule, RhythmVariation_Select_Code_Join2
	ld	(13945:16), 13
	jr	RhythmVariation_Select_Code_Join2
RhythmVariation_Select_Code_Skip:
	dec	1, (13945:16)
	cp	(13945:16), 255
	jr	nz, RhythmVariation_Select_Code_Join2
	ld	(13945:16), 0
RhythmVariation_Select_Code_Join2:
	jr	RhythmVariation_Select_Code_Return2
RhythmVariation_Select_Code_Return2:
	ret
AccDraw_Secondary_Helper5:
	push	xiz
	calr	RhythmVariation_Select_Code_Helper5
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper5:
	cp	(13942:16), 4
	jr	z, RhythmVariation_Select_Code_Skip2
	jr	RhythmVariation_Select_Code_Join4
RhythmVariation_Select_Code_Skip2:
	bit	7, w
	jr	nz, RhythmVariation_Select_Code_Skip3
	inc	1, (13946:16)
	cp	(13946:16), 3
	jr	ule, RhythmVariation_Select_Code_Join3
	ld	(13946:16), 3
	jr	RhythmVariation_Select_Code_Join3
RhythmVariation_Select_Code_Skip3:
	dec	1, (13946:16)
	cp	(13946:16), 255
	jr	nz, RhythmVariation_Select_Code_Join3
	ld	(13946:16), 0
RhythmVariation_Select_Code_Join3:
	jr	RhythmVariation_Select_Code_Return3
RhythmVariation_Select_Code_Join4:
	bit	7, w
	jr	nz, RhythmVariation_Select_Code_Entry
	or	(0x3691:16), 16
	jr	RhythmVariation_Select_Code_Return3
RhythmVariation_Select_Code_Entry:
	or	(0x3691:16), 32
RhythmVariation_Select_Code_Return3:
	ret
CmpSetTtlFunc_Helper:
	push	xiz
	call	RhythmVariation_Select_Code_Helper6
	pop	xiz
	ret
RhythmVariation_Select_Code_Helper6:
	cp	(35995:16), 180
	jr	z, RhythmVariation_Select_Code_Skip4
	ld	(13476:16), 1
	call	AccPatch_GetCurrentSlotAddr
	ld	l, (xiy+16)
	and	l, 255
	ld	h, (xiy+17)
	and	h, 127
	calr	TimeSig_DisplayStrings_Code_Sub2
	calr	DrumKit_PostMidiEvents
RhythmVariation_Select_Code_Skip4:
	calr	1435
	ret
RhythmConfig_ReturnStub:
	ret

RhythmConfig_InlineCode2:
	push	xiz
	call	RhythmConfig_ReturnStub_Helper
	pop	xiz
	ret
RhythmConfig_ReturnStub_Helper:
	cp	(35994:16), 180
	jr	z, RhythmConfig_ReturnStub_Return
	calr	DrumKit_SendProgramChange
RhythmConfig_ReturnStub_Return:
	ret
DrumTempo_Adjust:
	push XIZ
	push XIX
	ld a, (0x34a4:16)
	bit 0x07,W
	jr nz, DrumTempo_Decrement
	ld L, 0x06:opc
	ld XIX,0x00094800
	add XIX,0x00000010
	bit 0,(XIX)
	jr nz, DrumTempo_CheckMax
	cp (0x343a:16), 0x0b
	jr ugt, DrumTempo_CheckMax
	ld L, 0x08:opc
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
	ld	(13476:16), a
DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	push	xiz
	xor	hl, hl
	ld	l, (13476:16)
	cp	l, 1:i3
	jr	nc, DrumVoice_ClampMin
	ld	l, 1:opc
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
	; ordi8 0x8d88, 1 (v7 patched)
	or	(0x8cec:16), 1
	pushw hl

	ld xhl, 0:i3

	popw hl

	and l, 0xf

	sll xhl, 2

	; add xhl, DrumVoice_DispatchTable (v7 patched)
	add	xhl, DrumVoice_DispatchTable
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
	bit	7, (0x3432:16)
	jr	z, DrumVoice_Handler0_Skip2
	bit	7, w
	jr	nz, DrumVoice_Handler0_Skip
	inc	1, (0x343b:16)
	cp	(0x343b:16), 7
	jr	ule, DrumVoice_Handler0_Join
	ld	(0x343b:16), 7
	jr	DrumVoice_Handler0_Join
DrumVoice_Handler0_Skip:
	dec	1, (0x343b:16)
	cp	(0x343b:16), 0
	jr	ge, DrumVoice_Handler0_Join
	ld	(0x343b:16), 0
DrumVoice_Handler0_Join:
	or	(0x3432:16), 1
	jr	DrumVoice_Handler0_Return
DrumVoice_Handler0_Skip2:
	ld	(0x7ea6:16), 19
	calr	DrumVoice_NotifyEE
DrumVoice_Handler0_Return:
	ret
DrumVoice_Handler1:
	bit	7, (0x3432:16)
	jr	z, DrumVoice_Handler1_Skip2
	bit	7, w
	jr	nz, DrumVoice_Handler1_Skip
	inc	1, (0x343c:16)
	cp	(0x343c:16), 11
	jr	ule, DrumVoice_Handler1_Join
	ld	(0x343c:16), 11
	jr	DrumVoice_Handler1_Join
DrumVoice_Handler1_Skip:
	dec	1, (0x343c:16)
	cp	(0x343c:16), 4
	jr	ge, DrumVoice_Handler1_Join
	ld	(0x343c:16), 4
DrumVoice_Handler1_Join:
	or	(0x3432:16), 2
	jr	DrumVoice_Handler1_Return
DrumVoice_Handler1_Skip2:
	ld	(0x7ea6:16), 19
	calr	DrumVoice_NotifyEE
DrumVoice_Handler1_Return:
	ret
DrumVoice_Handler2:
	or	(0xe31c:16), 8
	bit	7, w
	jr	nz, DrumVoice_Handler2_Skip
	inc	1, (0x344d:16)
	cp	(0x344d:16), 11
	jr	ule, DrumVoice_Handler2_Join
	ld	(0x344d:16), 11
	jr	DrumVoice_Handler2_Join
DrumVoice_Handler2_Skip:
	dec	1, (0x344d:16)
	cp	(0x344d:16), 0
	jr	ge, DrumVoice_Handler2_Join
	ld	(0x344d:16), 0
DrumVoice_Handler2_Join:
	or	(0x3436:16), 1
	ret
DrumVoice_Handler3:
	or	(0xe31c:16), 8
	bit	7, w
	jr	nz, DrumVoice_Handler3_Skip
	or	(0x344e:16), 16
	jr	DrumVoice_Handler3_Join
DrumVoice_Handler3_Skip:
	and	(0x344e:16), 239
DrumVoice_Handler3_Join:
	or	(0x3436:16), 2
	ret	
DrumVoice_Handler5:
	and	(0xe31c:16), 247
	bit	7, w
	jr	nz, DrumVoice_Handler5_Skip
	bit	5, (0x344e:16)
	jr	nz, DrumVoice_Handler5_Return
	or	(0x344e:16), 32
	or	(0x3436:16), 4
	jr	DrumVoice_Handler5_Return
DrumVoice_Handler5_Skip:
	bit	5, (0x344e:16)
	jr	z, DrumVoice_Handler5_Return
	and	(0x344e:16), 223
	or	(0x3436:16), 4
DrumVoice_Handler5_Return:
	ret
DrumVoice_Handler4:
	and	(0xe31c:16), 247
	bit	7, w
	jr	nz, DrumVoice_Handler4_Skip
	bit	6, (0x344e:16)
	jr	nz, DrumVoice_Handler4_Return
	or	(0x344e:16), 64
	or	(0x3436:16), 4
	jr	DrumVoice_Handler4_Return
DrumVoice_Handler4_Skip:
	bit	6, (0x344e:16)
	jr	z, DrumVoice_Handler4_Return
	and	(0x344e:16), 191
	or	(0x3436:16), 4
DrumVoice_Handler4_Return:
	ret
	or	(0xe31c:16), 8
	ld	a, (0x344e:16)
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
	jr	DrumVoice_Handler4_Join2
DrumVoice_Handler4_Code_Skip4:
	cp	a, 0:i3
	jr	nz, DrumVoice_Handler4_Code_Skip5
	ld	a, 0:opc
	jr	DrumVoice_Handler4_Join2
DrumVoice_Handler4_Code_Skip5:
	cp	a, 64
	jr	nz, DrumVoice_Handler4_Code_Skip6
	ld	a, 0:opc
	jr	DrumVoice_Handler4_Join2
DrumVoice_Handler4_Code_Skip6:
	cp	a, 32
	jr	nz, DrumVoice_Handler4_Skip8
	ld	a, 64:opc
	jr	DrumVoice_Handler4_Join2
DrumVoice_Handler4_Skip8:
	cp	a, 96
	jr	nz, DrumVoice_Handler4_Join2
	ld	a, 32:opc
DrumVoice_Handler4_Join2:
	and	(0x344e:16), 159
	or	(0x344e:16), a
	or	(0x3436:16), 4
	ret
DrumVoice_Handler6:
	or	(0xe31c:16), 8
	or	(0xe31c:16), 1
DrumVoice_Handler6_Code:
	ldw	(58142:16), 1927
	ldw	(58142:16), 1670
	ld	xiy, 608256
	add	xiy, 16
	ld	a, (xiy)
	bit	0, a
	jr	nz, 9
	calr	722
	calr	63352
	calr	804
DrumVoice_Handler6_Return:
	ret	
DrumVoice_Handler7:
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler7.bin"
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
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
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
	call	VoiceParam_ClampAndValidate_Tramp
TimeSig_DisplayStrings_Code_Sub2:
	ld	(64602:16), l
	and	h, 127
	and	(0xfc5b:16), 128
	or	(0xfc5b:16), h
	ld	(36955:16), 72
	call	PartCtrl_WriteProgramChange
	ld	w, h
	extz	hl
	extz	xhl
	add	xhl, 65426
	jr	TimeSig_DisplayStrings_Code_Join10
TimeSig_DisplayStrings_Code_Join10:
	ld	(xhl), w
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ld	a, 72:opc
	ld	(36955:16), a
	call	PartCtrl_WriteProgramChange
	pop w
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
	ld	xix, 65426
	ld	h, (xix+l)
	ld	l, a
	ld	a, 72:opc
	ld	(36954:16), a
	call	SndParam_ApplyProgramChange_Safe
	and	l, 255
	ld	(64602:16), l
	and	h, 127
	ld	(64603:16), h
	cp	(13395:16), 26
	jr	z, TimeSig_DisplayStrings_Code_Return12
	cp	(64602:16), 128
	jr	c, DrumVoice_NotifyEE_Skip4
	cp	(13395:16), 16
	jr	nc, TimeSig_DisplayStrings_Code_Return12
	ld	(13395:16), 16
	jr	TimeSig_DisplayStrings_Code_Return12
DrumVoice_NotifyEE_Skip4:
	cp	(13395:16), 16
	jr	c, TimeSig_DisplayStrings_Code_Return12
	ld	(13395:16), 0
TimeSig_DisplayStrings_Code_Return12:
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ld	a, 72:opc
	ld	(36955:16), a
	call	PartCtrl_WriteProgramChange
	ld	a, h
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	ld	(13201:16), l
	popw	hl
	pop w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip4
	cp	l, 15
	jr	nz, DrumVoice_NotifyEE_Skip5
	push	xix
	ld	xix, TimeSig_DisplayStrings_Code
	ld	a, (xix+a)
	pop	xix
	jr	TimeSig_DisplayStrings_Code_Join2
DrumVoice_NotifyEE_Skip5:
	inc	1, a
	cp	a, (13201:16)
	jr	ule, TimeSig_DisplayStrings_Code_Join2
	ld	a, (13201:16)
	jr	TimeSig_DisplayStrings_Code_Join2
TimeSig_DisplayStrings_Code_Skip4:
	cp	l, 15
	jr	nz, TimeSig_DisplayStrings_Code_Skip5
	push	xix
	ld	xix, TimeSig_DisplayStrings_0x227
	ld	a, (xix+a)
	pop	xix
	jr	TimeSig_DisplayStrings_Code_Join2
TimeSig_DisplayStrings_Code_Skip5:
	dec	1, a
	cp	a, 255
	jr	nz, TimeSig_DisplayStrings_Code_Join2
	ld	a, 0:opc
TimeSig_DisplayStrings_Code_Join2:
	ld	h, a
	ld	xwa, 65426
	ld	(xwa+l), h
	ld	a, 72:opc
	ld	(36954:16), a
	call	16554433
	and	l, 255
	ld	(64602:16), l
	and	h, 127
	ld	(64603:16), h
	ret
TimeSig_DisplayStrings_Code:
	max
	max
	max
	max
	ld	(8:8), 8:io
	ld	(8:8), 8:io
	ld	(8:8), 0:io
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	max
	max
	max
	max
TimeSig_DisplayStrings_Code_Sub:
	ld	a, (64602:16)
	and	a, 255
	ld	w, (64603:16)
	and	w, 127
	ld	(13393:16), a
	ld	(13394:16), w
	ret
	ld	l, (13393:16)
	and	l, 255
	cp	l, 240
	jr	c, 11
	ld	l, 128:opc
	ld	(13393:16), l
	ld	(13394:16), 0
	cp	l, 128
	jr	c, DrumVoice_NotifyEE_Skip8
	ld	a, (13394:16)
	and	a, 127
	cp	a, 0:i3
	jr	z, DrumVoice_NotifyEE_Skip8
	ld	(13394:16), 0
DrumVoice_NotifyEE_Skip8:
	cp	l, 128
	jr	c, DrumVoice_NotifyEE_Skip14
	cp	(13395:16), 16
	jr	nc, DrumVoice_NotifyEE_Join4
	ld	(13395:16), 26
DrumVoice_NotifyEE_Join4:
	cp	(13395:16), 26
	jr	nz, DrumVoice_NotifyEE_Skip11
	ld	a, (13361:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, DrumVoice_NotifyEE_Skip9
	cp	a, 32
	jr	z, DrumVoice_NotifyEE_Skip10
	ld	(13370:16), 32
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip9:
	ld	(13370:16), 30
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip10:
	ld	(13370:16), 31
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip11:
	cp	(13370:16), 30
	jr	c, DrumVoice_NotifyEE_Return2
	ld	a, (13361:16)
	and	a, 48
	cp	a, 0:i3
	jr	z, DrumVoice_NotifyEE_Skip13
	cp	a, 32
	jr	z, DrumVoice_NotifyEE_Skip12
	ld	(13370:16), 8
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip12:
	ld	(13370:16), 4
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip13:
	ld	(13370:16), 0
	jr	DrumVoice_NotifyEE_Return2
DrumVoice_NotifyEE_Skip14:
	cp	(13395:16), 16
	jr	c, DrumVoice_NotifyEE_Skip15
	ld	(13395:16), 26
DrumVoice_NotifyEE_Skip15:
	jr	DrumVoice_NotifyEE_Join4
DrumVoice_NotifyEE_Return2:
	ret
AccPatch_CallParamLookup_Helper7:
	ret
	cp	(13393:16), 128
	jr	c, TimeSig_DisplayStrings_Code_Return2
	cp	(13395:16), 10
	jr	c, TimeSig_DisplayStrings_Code_Return2
	ld	(13395:16), 0
TimeSig_DisplayStrings_Code_Return2:
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ld	a, 72:opc
	ld	(36955:16), a
	call	PartCtrl_WriteProgramChange
	pushw	hl
	call	AccVoice_GetChannelCount_Direct
	ld	(13201:16), h
	popw	hl
	ld	a, l
	cp	a, 15
	jr	lt, DrumVoice_NotifyEE_Skip16
	ld	(13202:16), 25
	ld	(13203:16), 16
	jr	DrumVoice_NotifyEE_Join5
DrumVoice_NotifyEE_Skip16:
	ld	(13202:16), 15
	ld	(13203:16), 0
DrumVoice_NotifyEE_Join5:
	ld	a, (13395:16)
	pop w
	bit	7, w
	jr	nz, TimeSig_DisplayStrings_Code_Skip14
	cp	a, 26
	jr	nz, DrumVoice_NotifyEE_Skip17
	push	xix
	ld	a, (13370:16)
	ld	xix, TimeSig_DisplayStrings_Code3
	ld	a, (xix+a)
	ld	(13370:16), a
	pop	xix
	ld	a, (13203:16)
	jr	DrumVoice_NotifyEE_Join6
DrumVoice_NotifyEE_Skip17:
	inc	1, a
	cp	a, (13202:16)
	jr	ule, DrumVoice_NotifyEE_Join6
	ld	a, (13202:16)
	jr	DrumVoice_NotifyEE_Join6
TimeSig_DisplayStrings_Code_Skip14:
	cp	a, 26
	jr	z, DrumVoice_NotifyEE_Join6
	dec	1, a
	cp	a, (13203:16)
	jr	ge, DrumVoice_NotifyEE_Join6
	push	xix
	ld	a, (13370:16)
	ld	xix, TimeSig_DisplayStrings_Code2
	ld	a, (xix+a)
	ld	(13370:16), a
	pop	xix
	ld	a, 26:opc
	jr	DrumVoice_NotifyEE_Join6
DrumVoice_NotifyEE_Join6:
	ld	(13395:16), a
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
	ld	w, 32:opc
	ld	w, 32:opc
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
	ld	(8:8), 8:io
	ld	(0:8), 0:io
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
	ld	(8:8), 8:io
	ld	(8:8), 8:io
	nop
	max
	ld	(200:8), 51:io
	reti
	jr	nz, 58
	bit	5, (0x3431:16)
	jr	z, 22
	and	(0x3431:16), 207
	or	(0x3431:16), 16
	ld	(13370:16), 32
	ld	(13395:16), 26
	jr	81
	bit	4, (0x3431:16)
	jr	z, 2
	jr	73
	and	(0x3431:16), 207
	or	(0x3431:16), 32
	ld	(13370:16), 31
	ld	(13395:16), 26
	jr	DrumVoice_NotifyEE_Return4
	bit	5, (0x3431:16)
	jr	z, AccPatch_CallParamLookup_Helper7_Entry
	and	(0x3431:16), 207
	ld	(13370:16), 30
	ld	(13395:16), 26
	jr	DrumVoice_NotifyEE_Return4
AccPatch_CallParamLookup_Helper7_Entry:
	bit	4, (0x3431:16)
	jr	z, DrumVoice_NotifyEE_Return4
	and	(0x3431:16), 207
	or	(0x3431:16), 32
	ld	(13370:16), 31
	ld	(13395:16), 26
	jr	DrumVoice_NotifyEE_Return4
DrumVoice_NotifyEE_Return4:
	ret
	ld	a, (13370:16)
	bit	4, (0x3431:16)
	jr	z, DrumVoice_NotifyEE_Entry
	calr	DrumVoice_NotifyEE_Helper4
	jr	DrumVoice_NotifyEE_Join7
DrumVoice_NotifyEE_Entry:
	bit	5, (0x3431:16)
	jr	z, DrumVoice_NotifyEE_Skip19
	calr	DrumVoice_NotifyEE_Helper3
	jr	DrumVoice_NotifyEE_Join7
DrumVoice_NotifyEE_Skip19:
	calr	DrumVoice_NotifyEE_Helper
DrumVoice_NotifyEE_Join7:
	ld	(13370:16), a
	ret
DrumVoice_NotifyEE_Helper:
	bit	7, w
	jr	nz, DrumVoice_NotifyEE_Skip22
	inc	1, a
	cp	a, 31
	jr	nz, DrumVoice_NotifyEE_Skip20
	calr	TimeSig_DisplayStrings_Code_Helper
	ld	a, 0:opc
	jr	TimeSig_DisplayStrings_Code_Join4
DrumVoice_NotifyEE_Skip20:
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
DrumVoice_NotifyEE_Skip22:
	dec	1, a
	cp	a, 29
	jr	nz, DrumVoice_NotifyEE_Skip23
	ld	a, 30:opc
	jr	TimeSig_DisplayStrings_Code_Return4
DrumVoice_NotifyEE_Skip23:
	cp	a, 255
	jr	nz, TimeSig_DisplayStrings_Code_Skip18
	ld	a, 30:opc
	ld	(13395:16), 26
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
	ld	a, (64602:16)
	and	a, 255
	cp	a, 128
	jr	c, DrumVoice_NotifyEE_Skip26
	ld	(13395:16), 16
	jr	TimeSig_DisplayStrings_Code_Return5
DrumVoice_NotifyEE_Skip26:
	ld	(13395:16), 0
TimeSig_DisplayStrings_Code_Return5:
	ret
DrumVoice_NotifyEE_Helper3:
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
	jr	nz, DrumVoice_NotifyEE_Skip30
	ld	a, 31:opc
	jr	TimeSig_DisplayStrings_Code_Return6
DrumVoice_NotifyEE_Skip30:
	cp	a, 3:i3
	jr	nz, TimeSig_DisplayStrings_Code_Skip25
	ld	a, 31:opc
	ld	(13395:16), 26
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
DrumVoice_NotifyEE_Helper4:
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
	jr	nz, DrumVoice_NotifyEE_Skip36
	ld	a, 32:opc
	jr	TimeSig_DisplayStrings_Code_Return7
DrumVoice_NotifyEE_Skip36:
	cp	a, 7:i3
	jr	nz, TimeSig_DisplayStrings_Code_Skip31
	ld	a, 32:opc
	ld	(13395:16), 26
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Skip31:
	cp	a, 23
	jr	nz, DrumVoice_NotifyEE_Skip38
	ld	a, 11:opc
	jr	TimeSig_DisplayStrings_Code_Return7
DrumVoice_NotifyEE_Skip38:
	cp	a, 30
	jr	lt, TimeSig_DisplayStrings_Code_Join5
	ld	a, 29:opc
	jr	TimeSig_DisplayStrings_Code_Return7
TimeSig_DisplayStrings_Code_Return7:
	ret
	call	AccWrap_PlayModeDispatch
	or	(0x28a7:16), 4
	ld	a, (64602:16)
	and	a, 15
	ld	(14446:16), a
	call	DrumVoice_NotifyEE_Helper5
	ld	(14466:16), xiy
	add	xiy, 16
	ld	(14470:16), xiy
	bit	0, (0x388a:16)
	jr	nz, DrumVoice_NotifyEE_Entry2
	ld	xbc, 4:i3
	ld	xiy, (14466:16)
	ld	xix, 14450
	ldir85
	ld	(14449:16), 0
DrumVoice_NotifyEE_Entry2:
	and	(0x388a:16), 254
	ret
	ret
	ret
DrumVoice_NotifyEE_Helper5:
	ld	xwa, 0:i3
	ld	xbc, 0:i3
	ld	a, 32:opc
	ld	c, (14446:16)
	mul	wa, c
	add	xwa, 608256
	add	xwa, 2976
	ld	xiy, xwa
	ret
	ld	a, (14448:16)
	ld	xiy, 14450
	ld	c, (xiy+a)
	ld	(14445:16), c
	ret
DrumVoice_NotifyEE_Helper6:
	ld	a, (14447:16)
	ld	xiy, 14450
	ld	c, (xiy+a)
	ld	(14444:16), c
	ret
	.byte 0xc1, 0xa7, 0x28, 0x3c, 0xfb, 0xc1, 0x8a, 0x38, 0x3c, 0xfe
	ret
	ld	a, (14446:16)
	bit	7, w
	jr	nz, DrumVoice_NotifyEE_Skip40
	cp	a, 4:i3
	jr	nc, DrumVoice_NotifyEE_Skip39
	inc	1, a
	jr	DrumVoice_NotifyEE_Join9
DrumVoice_NotifyEE_Skip39:
	ld	a, 4:opc
DrumVoice_NotifyEE_Join9:
	jr	DrumVoice_NotifyEE_Join10
DrumVoice_NotifyEE_Skip40:
	cp	a, 0:i3
	jr	ule, DrumVoice_NotifyEE_Skip41
	dec	1, a
	jr	DrumVoice_NotifyEE_Join10
DrumVoice_NotifyEE_Skip41:
	ld	a, 0:opc
DrumVoice_NotifyEE_Join10:
	ld	(14446:16), a
	or	a, 240
	ld	(64602:16), a
	ld	a, 0:opc
	ld	(64603:16), a
	calr	DrumKit_PostMidiEvents
	ld	(14449:16), 0
	ret
	.byte 0xc8, 0x04
	calr	DrumVoice_NotifyEE_Helper6
	pop w
	bit	7, w
	jr	nz, DrumVoice_NotifyEE_Skip44
	cp	(14444:16), 11
	jr	nc, DrumVoice_NotifyEE_Skip42
	inc	1, (14444:16)
	jr	DrumVoice_NotifyEE_Join11
DrumVoice_NotifyEE_Skip42:
	cp	(14444:16), 255
	jr	nz, DrumVoice_NotifyEE_Skip43
	ld	(14444:16), 0
	jr	DrumVoice_NotifyEE_Join11
DrumVoice_NotifyEE_Skip43:
	ld	(14444:16), 11
DrumVoice_NotifyEE_Join11:
	jr	DrumVoice_NotifyEE_Join12
DrumVoice_NotifyEE_Skip44:
	cp	(14444:16), 0
	jr	le, DrumVoice_NotifyEE_Skip45
	dec	1, (14444:16)
	jr	DrumVoice_NotifyEE_Join12
DrumVoice_NotifyEE_Skip45:
	cp	(14447:16), 0
	jr	nz, DrumVoice_NotifyEE_Skip46
	ld	(14444:16), 0
	jr	DrumVoice_NotifyEE_Join12
DrumVoice_NotifyEE_Skip46:
	ld	(14444:16), 255
DrumVoice_NotifyEE_Join12:
	ld	a, (14444:16)
	ld	(14445:16), a
	ld	xix, 14450
	ld	c, (14447:16)
	ld	(xix+c), a
	ld	xix, 14450
	calr	DrumVoice_NotifyEE_Helper7
	or	(0x388a:16), 1
	ret
DrumVoice_NotifyEE_Helper7:
	ld	(14449:16), 0
	ld	h, 0:opc
	calr	DrumVoice_NotifyEE_Helper8
	ld	wa, bc
	pushw	wa
	ld	h, 1:opc
	calr	DrumVoice_NotifyEE_Helper8
	popw	wa
	cp	bc, 65535
	jr	z, TimeSig_DisplayStrings_Code_Skip33
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Skip33
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Skip33:
	pushw	wa
	ld	h, 2:opc
	calr	DrumVoice_NotifyEE_Helper8
	popw	wa
	cp	bc, 65535
	jr	z, TimeSig_DisplayStrings_Code_Skip34
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Skip34
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Skip34:
	pushw	wa
	ld	h, 3:opc
	calr	DrumVoice_NotifyEE_Helper8
	popw	wa
	cp	bc, 65535
	jr	z, TimeSig_DisplayStrings_Code_Helper_Return
	cp	bc, wa
	jr	z, TimeSig_DisplayStrings_Code_Helper_Return
	calr	TimeSig_DisplayStrings_Code_Helper3
TimeSig_DisplayStrings_Code_Helper_Return:
	ret
DrumVoice_NotifyEE_Helper8:
	ld	l, (xix+h)
	cp	l, 255
	jr	z, TimeSig_DisplayStrings_Code_Helper2_Skip
	pushdi_b	(13370)
	ld	(13370:16), l
	push	h
	push	xix
	call	AccPatch_SlotScanByteData_0x38
	pop	xix
	pop	h
	pop	(0x343a:16)
	ld	b, a
	jr	TimeSig_DisplayStrings_Code_Helper2_Return
TimeSig_DisplayStrings_Code_Helper2_Skip:
	ldw	bc, 65535
TimeSig_DisplayStrings_Code_Helper2_Return:
	ret
TimeSig_DisplayStrings_Code_Helper3:
	push	xwa
	ld	xwa, TimeSig_DisplayStrings_Code4
	ld	a, (xwa+h)
	or (14449:16), a
	pop	xwa
	ret
TimeSig_DisplayStrings_Code4:
	normal
	push	sr
	max
	ld	(8:8), 8:io
	ld	(8:8), 62:io
	call	16145497
	pop	xiz
	ret
	ret
	.byte 0xc1, 0x6e, 0x38, 0x04, 0xc1, 0x6f, 0x38, 0x04
	ld	(14446:16), 0
DrumVoice_NotifyEE_Join13:
	cp	(14446:16), 5
	jr	z, 19
	calr	-416
	ld	xix, xiy
	push	xix
	calr	DrumVoice_NotifyEE_Helper7
	pop	xix
	calr	DrumVoice_NotifyEE_Helper10
	inc	1, (14446:16)
	jr	DrumVoice_NotifyEE_Join13
	pop	(0x386f:16)
	pop	(0x386e:16)
	ld	(14449:16), 0
	ret
DrumVoice_NotifyEE_Helper10:
	bit	1, (0x3871:16)
	jr	z, DrumVoice_NotifyEE_Entry3
	ld	b, 255:opc
	ld	a, 1:opc
	ld	(xix+a), b
DrumVoice_NotifyEE_Entry3:
	bit	2, (0x3871:16)
	jr	z, DrumVoice_NotifyEE_Entry4
	ld	b, 255:opc
	ld	a, 2:opc
	ld	(xix+a), b
DrumVoice_NotifyEE_Entry4:
	bit	3, (0x3871:16)
	jr	z, DrumVoice_NotifyEE_Return10
	ld	b, 255:opc
	ld	a, 3:opc
	ld	(xix+a), b
DrumVoice_NotifyEE_Return10:
	ret
	ld	xbc, 4:i3
	ld	xix, (14466:16)
	ld	xiy, 14450
	ldir85
	ret
CmEsyTtl_Dispatch2_Helper:
	push XIZ
	call DrumVoice_NotifyEE_Entry4_Data
	pop XIZ
	ret
DrumVoice_NotifyEE_Entry4_Data:
	.byte 0x1e, 0x0f, 0x00, 0x1e, 0x86, 0xeb, 0x1d, 0x1e
	.byte 0xd7, 0xfd, 0x1d, 0xd6, 0xd7, 0xfd, 0x1e, 0x2d
	.byte 0xed, 0x0e, 0xf1, 0xff, 0x36, 0x00, 0x01, 0xf1
	.byte 0x2d, 0x37, 0xcc, 0x6e, 0x26, 0xf1, 0xff, 0x36
	.byte 0x00, 0x02, 0xf1, 0x2d, 0x37, 0xcd, 0x6e, 0x1b
	.byte 0xf1, 0xff, 0x36, 0x00, 0x04, 0xf1, 0x2d, 0x37
	.byte 0xce, 0x6e, 0x10, 0xf1, 0xff, 0x36, 0x00, 0x08
	.byte 0xf1, 0x2d, 0x37, 0xcb, 0x6e, 0x05, 0xf1, 0xff
	.byte 0x36, 0x00, 0x10, 0x0e, 0xf1, 0x2d, 0x37, 0x00
	.byte 0x10, 0xf1, 0xff, 0x36, 0xc8, 0x6e, 0x26, 0xf1
	.byte 0x2d, 0x37, 0x00, 0x20, 0xf1, 0xff, 0x36, 0xc9
	.byte 0x6e, 0x1b, 0xf1, 0x2d, 0x37, 0x00, 0x40, 0xf1
	.byte 0xff, 0x36, 0xca, 0x6e, 0x10, 0xf1, 0x2d, 0x37
	.byte 0x00, 0x08, 0xf1, 0xff, 0x36, 0xcb, 0x6e, 0x05
	.byte 0xf1, 0x2d, 0x37, 0x00, 0x01, 0x0e, 0x3e, 0x1d
	.byte 0x4f, 0x5d, 0xf6, 0x5e, 0x0e, 0xc1, 0x0e, 0x39
	.byte 0x21, 0xc8, 0x33, 0x07, 0x6e, 0x08, 0xc9, 0xdb
	.byte 0x66, 0x0e, 0xc9, 0x61, 0x68, 0x06, 0xc9, 0xd8
	.byte 0x66, 0x06, 0xc9, 0x69, 0xf1, 0x0e, 0x39, 0x41
TimeSig_DisplayStrings_Code_Return9:
	.byte 0x0e, 0x3e, 0x1d, 0x72, 0x5d, 0xf6, 0x5e, 0x0e
TimeSig_DisplayStrings_Helper5:
	.byte 0x28, 0x1d, 0x86, 0xe9, 0xf5, 0x48, 0x44, 0xa5
	.byte 0x5d, 0xf6, 0x00, 0xc1, 0x0e, 0x39, 0x21, 0xc3
	.byte 0x03, 0xf0, 0xe0, 0x21, 0xc3, 0x03, 0xf4, 0xe0
	.byte 0x27, 0xc8, 0x33, 0x07, 0x6e, 0x09, 0xcf, 0xcf
	.byte 0x7f, 0x66, 0x0f, 0xcf, 0x61, 0x68, 0x06, 0xcf
	.byte 0xd8, 0x66, 0x07, 0xcf, 0x69, 0xf3, 0x03, 0xf4
	.byte 0xe0, 0x47, 0x0e, 0x22, 0x2a, 0x32, 0x3a, 0x3e
	.byte 0x1d, 0xb0, 0x5d, 0xf6, 0x5e, 0x0e, 0x28, 0x1d
	.byte 0x86, 0xe9, 0xf5, 0x48, 0x44, 0xe3, 0x5d, 0xf6
	.byte 0x00, 0xc1, 0x0e, 0x39, 0x21, 0xc3, 0x03, 0xf0
	.byte 0xe0, 0x21, 0xc3, 0x03, 0xf4, 0xe0, 0x27, 0xc8
	.byte 0x33, 0x07, 0x6e, 0x09, 0xcf, 0xcf, 0x0b, 0x66
	.byte 0x0f, 0xcf, 0x61, 0x68, 0x06, 0xcf, 0xd8, 0x66
	.byte 0x07, 0xcf, 0x69, 0xf3, 0x03, 0xf4, 0xe0, 0x47
	.byte 0x0e, 0x25, 0x2d, 0x35, 0x3d, 0xc1, 0x9a, 0x8c
	.byte 0x21, 0xc1, 0x9b, 0x8c, 0xf1, 0xb0, 0xf6, 0xc2
	.byte 0xe3, 0xff, 0x00, 0x21, 0xc9, 0x61, 0xf1, 0xed
	.byte 0x38, 0x41, 0xd1, 0xee, 0x38, 0x20, 0xd8, 0xd8
	.byte 0xb0, 0xfe, 0xf1, 0xee, 0x38, 0x02, 0x01, 0x00
	.byte 0xf1, 0xf0, 0x38, 0x02, 0x01, 0x00, 0xf1, 0xf2
	.byte 0x38, 0x00, 0x19, 0xf1, 0xf3, 0x38, 0x00, 0x00
	.byte 0xf1, 0xf4, 0x38, 0x00, 0x00, 0xf1, 0xf5, 0x38
	.byte 0x00, 0x00, 0xf1, 0xf6, 0x38, 0x00, 0x00, 0xf1
	.byte 0xf7, 0x38, 0x00, 0x00, 0xf1, 0xf8, 0x38, 0x00
	.byte 0x00, 0xf1, 0xf9, 0x38, 0x00, 0x00, 0x0e, 0x0e
; TimeSig_CallProc -- WA = index 0..23 (`cp de, 23 / ret ugt`), BC bit 7 = a flag
; passed on in A; calls TimeSig_ProcTable[index] (`ld xde, TimeSig_ProcTable / add
; xde, xbc / ld xhl, (xde) / call (xhl)`).
TimeSig_CallProc:
	ld DE,WA
	cp DE,0x0017
	ret UGT
	and	bc, 128
	cp	bc, 0:i3
	scc	nz, a
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
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0080
	ld bc, 0:i3
	calr Tempo_DisplayParamCommon
	ld wa, (0x38ee:16)
	cp (XSP),0x00
	jr nz, Tempo_StartMeasureDec
	ld BC,WA
	cp WA,0x03e7
	jr nc, Tempo_StartMeasureReturn
	inc 1,BC
	ld (0x38ee:16), bc
	jr t, Tempo_StartMeasureSync
Tempo_StartMeasureDec:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_StartMeasureReturn
	dec	1, bc
	ld	(14574:16), bc
Tempo_StartMeasureSync:
	ld	bc, (14576:16)
	ld	wa, (14574:16)
	cp	wa, bc
	jr	ule, Tempo_StartMeasureSyncFar
	ld	(14576:16), wa
	jr	Tempo_StartMeasureSetDirty
Tempo_StartMeasureSyncFar:
	inc	7, wa
	cp	wa, bc
	jr	nc, Tempo_StartMeasureSetDirty
	ld	(14576:16), wa
Tempo_StartMeasureSetDirty:
	; setda 4, 0xe3e0 (v7 patched)
	set	4, (0xe31a:16)
Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0081
	ld bc, 1:i3
	calr Tempo_DisplayParamCommon
	ld wa, (0x38f0:16)
	cp (XSP),0x00
	jr nz, Tempo_EndMeasureDec
	ld BC,WA
	cp WA,0x03e7
	jr nc, Tempo_EndMeasureReturn
	inc 1,BC
	ld (0x38f0:16), bc
	ld WA,BC
	jr t, Tempo_EndMeasureSyncStart
Tempo_EndMeasureDec:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_EndMeasureReturn
	dec	1, bc
	ld	(14576:16), bc
	ld	wa, (14576:16)
Tempo_EndMeasureSyncStart:
	ld	bc, (14574:16)
	cp	bc, wa
	jr	ule, Tempo_EndMeasureSyncFar
	ld	(14574:16), wa
	jr	Tempo_EndMeasureSetDirty
Tempo_EndMeasureSyncFar:
	inc	7, bc
	cp	bc, wa
	jr	nc, Tempo_EndMeasureSetDirty
	dec	7, wa
	ld	(14574:16), wa
Tempo_EndMeasureSetDirty:
	; setda 4, 0xe3e0 (v7 patched)
	set	4, (0xe31a:16)
Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0082
	ld bc, 2:i3
	calr Tempo_DisplayParamCommon
	ld a, (0x38f2:16)
	cp (XSP),0x00
	jr nz, Tempo_QuantizeDec
	ld C,A
	cp A,0x31
	jr nc, Tempo_QuantizeReturn
	inc 1,C
	ld (0x38f2:16), c
	jr t, Tempo_QuantizeSetDirty
Tempo_QuantizeDec:
	ld	c, a
	cp	a, 1:i3
	jr	ule, Tempo_QuantizeReturn
	dec	1, c
	ld	(14578:16), c
Tempo_QuantizeSetDirty:
	; setda 4, 0xe3e0 (v7 patched)
	set	4, (0xe31a:16)
Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 134
	ld	bc, 6:i3
	calr	Tempo_DisplayParamCommon
	ld	a, (0x38f4:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (Tempo_AdjustEffect_Table:24)
	ld	xbc, (xbc+wa)
	ld	a, (xbc)
	cp	(xsp), 0
	jr	nz, Tempo_EffectDec
	cp	a, 16
	jr	nc, Tempo_EffectReturn
	inc	1, a
	jr	Tempo_EffectStore
Tempo_EffectDec:
	cp a, 0:i3
	jr z, Tempo_EffectReturn
	dec 1, a

Tempo_EffectStore:
	ld (xbc), a

	; setda 4, 0xe3e0 (v7 patched)
	set	4, (0xe31a:16)
Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	cp a, 0:i3
	ret NZ
	ldw WA, 0x0009
	ldw BC, 0x0008
	calr Tempo_DisplayParamCommon
	ld a, (0x38f3:16)
	cp A,0x1d
	ret NC
	inc 1,A
	ld (0x38f3:16), a
	set 4, (0xe31a:16)
	ret
Tempo_DecrementTimeSigNum:
	cp a, 0:i3
	ret NZ
	ldw WA, 0x0009
	ldw BC, 0x0008
	calr Tempo_DisplayParamCommon
	ld a, (0x38f3:16)
	cp a, 0:i3
	ret Z
	dec 1,A
	ld (0x38f3:16), a
	set 4, (0xe31a:16)
	ret
Tempo_TimeSigCodeBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 28 of 41 slots byte-identical
	cp	a, 0:i3
	ret	nz
	ldw	wa, 10
	ldw	bc, 11
	calr	Tempo_DisplayParamCommon
	ld	a, (14580:16)
	cp	a, 0:i3
	ret	z
	dec	1, a
	ld	(14580:16), a
	; v10 does not spell this byte either
	set	4, (0xe31a:16)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 132
	ld	bc, 4:i3
	calr	Tempo_DisplayParamCommon
	ld	a, (14580:16)
	; v10 does not spell this byte either
	cp	(xsp), 0
	jr	nz, Tempo_DecrementTimeSigNum_Skip
	ld	c, a
	cp	a, 4:i3
	jr	nc, Tempo_DecrementTimeSigNum_Epilogue
	inc	1, c
	ld	(14580:16), c
	jr	Tempo_DecrementTimeSigNum_Entry
Tempo_DecrementTimeSigNum_Skip:
	ld	c, a
	cp	a, 0:i3
	jr	z, Tempo_DecrementTimeSigNum_Epilogue
	dec	1, c
	ld	(14580:16), c
Tempo_DecrementTimeSigNum_Entry:
	; v10 does not spell this byte either
	set	4, (0xe31a:16)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
Tempo_DecrementTimeSigNum_Epilogue:
	inc	2, xsp
	ret
Tempo_EditBPM:
	cp a, 0:i3
	ret NZ
	set 0, (0x8cec:16)
	calr Tempo_DisplayParamReturn
	ld (0x38ec:16), l
	cp l, 1:i3
	jr z, Tempo_EditBPMDec
	cp l, 0:i3
	jr nz, Tempo_EditBPMClamp
	ldw WA, 0x0023
	calr Tempo_DisplayParamSkipClear
	jr t, Tempo_EditBPMClamp
Tempo_EditBPMDec:
	ldw	wa, 15
	calr	Tempo_DisplayParamSkipClear
	ldw	wa, 8
	call	MIDI_SendSysExCmd
Tempo_EditBPMClamp:
	; setda 7, 0x34cd (v7 patched)
	set	7, (0x3431:16)
	; setda 7, 0x34cd (v7 patched)
	set	7, (0x3431:16)
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
	ld	wa, (14574:16)
	cp	(xsp), 0
	jr	nz, Tempo_EditBPMClamp_Code_Skip2
	ld	bc, wa
	cp	wa, 999
	jr	nc, Tempo_EditBPMClamp_Code_Epilogue
	cp	bc, 989
	jr	c, Tempo_EditBPMClamp_Code_Skip
	ldw	(14574:16), 999
	jr	Tempo_EditBPMClamp_Code_Join
Tempo_EditBPMClamp_Code_Skip:
	add	bc, 10
	ld	(14574:16), bc
	jr	Tempo_EditBPMClamp_Code_Join
Tempo_EditBPMClamp_Code_Skip2:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_EditBPMClamp_Code_Epilogue
	cp	bc, 10
	jr	ugt, Tempo_EditBPMClamp_Code_Skip3
	ldw	(14574:16), 1
	jr	Tempo_EditBPMClamp_Code_Join
Tempo_EditBPMClamp_Code_Skip3:
	sub	bc, 10
	ld	(14574:16), bc
Tempo_EditBPMClamp_Code_Join:
	ld	bc, (14576:16)
	ld	wa, (14574:16)
	cp	wa, bc
	jr	ule, Tempo_EditBPMClamp_Code_Skip4
	ld	(14576:16), wa
	jr	Tempo_EditBPMClamp_Code_Entry
Tempo_EditBPMClamp_Code_Skip4:
	inc	7, wa
	cp	wa, bc
	jr	nc, Tempo_EditBPMClamp_Code_Entry
	ld	(14576:16), wa
Tempo_EditBPMClamp_Code_Entry:
	set	4, (0xe31a:16)
Tempo_EditBPMClamp_Code_Epilogue:
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 147
	ldw	bc, 19
	calr	Tempo_DisplayParamCommon
	ld	wa, (14576:16)
	cp	(xsp), 0
	jr	nz, Tempo_EditBPMClamp_Code_Skip6
	ld	bc, wa
	cp	wa, 999
	jr	nc, Tempo_EditBPMClamp_Code_Epilogue2
	cp	bc, 989
	jr	c, Tempo_EditBPMClamp_Code_Skip5
	ldw	(14576:16), 999
	ldw	wa, 999
	jr	Tempo_EditBPMClamp_Code_Join2
Tempo_EditBPMClamp_Code_Skip5:
	add	bc, 10
	ld	(14576:16), bc
	ld	wa, bc
	jr	Tempo_EditBPMClamp_Code_Join2
Tempo_EditBPMClamp_Code_Skip6:
	ld	bc, wa
	cp	wa, 1:i3
	jr	ule, Tempo_EditBPMClamp_Code_Epilogue2
	cp	bc, 10
	jr	ugt, Tempo_EditBPMClamp_Code_Skip7
	ldw	(14576:16), 1
	ld	wa, 1:i3
	jr	Tempo_EditBPMClamp_Code_Join2
Tempo_EditBPMClamp_Code_Skip7:
	sub	bc, 10
	ld	(14576:16), bc
	ld	wa, (14576:16)
Tempo_EditBPMClamp_Code_Join2:
	ld	bc, (14574:16)
	cp	bc, wa
	jr	ule, Tempo_EditBPMClamp_Code_Skip8
	ld	(14574:16), wa
	jr	Tempo_EditBPMClamp_Code_Entry2
Tempo_EditBPMClamp_Code_Skip8:
	inc	7, bc
	cp	bc, wa
	jr	nc, Tempo_EditBPMClamp_Code_Entry2
	dec	7, wa
	ld	(14574:16), wa
Tempo_EditBPMClamp_Code_Entry2:
	set	4, (0xe31a:16)
Tempo_EditBPMClamp_Code_Epilogue2:
	inc	2, xsp
	ret
	extz	wa
	jrl	Tempo_AdjustQuantize
	extz	wa
	jrl	Tempo_AdjustEffect
Tempo_DisplayParamCommon:
	or (0xe31c:16), 0x09
	ld (0xe31e:16), a
	ld (0xe320:16), c
	ret
Tempo_DisplayParamSkipClear:
	ld	(32422:16), a
	ldw	wa, 238
	jp	SoundCtrl_SendCommand
Tempo_DisplayParamFormat:
	.incbin "includes/romslices/v7_transplant_Tempo_DisplayParamFormat.bin"
Tempo_DisplayParamReturn:
	push QIZ
	lds_erpb 0xfb, 0
	calr MIDIChan_ScanForFree
	calr VoiceSlot_UpdateState
	calr Tempo_DisplayBPMReturn
	ld wa, 0:i3
	calr SeqRec_ValidateDone
	ld a, (0x38f5:16)
	cp a, 0:i3
	jr z, .Lc_f661c5
	extz WA
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, .Lc_f661c5
	ld c, (0x38f5:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f661c5
	ld wa, 0:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 0:i3
	calr Tempo_FormatBPM
	ldfr_berp l, 0xfb
	cps_erpb 0xfb, 1
	jrl z, Tempo_DisplayEffect
Tempo_DisplayStartMeasure:
.Lc_f661c5:
	ld wa, 1:i3
	calr SeqRec_ValidateDone
	ld a, (0x38f6:16)
	cp a, 0:i3
	jr z, .Lc_f66202
	extz WA
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, .Lc_f66202
	ld c, (0x38f6:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f66202
	ld wa, 1:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 1:i3
	calr Tempo_FormatBPM
	ldfr_berp l, 0xfb
	cps_erpb 0xfb, 1
	jrl z, Tempo_DisplayEffect
Tempo_DisplayEndMeasure:
.Lc_f66202:
	ld wa, 2:i3
	calr SeqRec_ValidateDone
	ld a, (0x38f7:16)
	cp a, 0:i3
	jr z, .Lc_f6623e
	extz WA
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, .Lc_f6623e
	ld c, (0x38f7:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f6623e
	ld wa, 2:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 2:i3
	calr Tempo_FormatBPM
	ldfr_berp l, 0xfb
	cps_erpb 0xfb, 1
	jr z, Tempo_DisplayEffect
Tempo_DisplayQuantize:
.Lc_f6623e:
	ld wa, 3:i3
	calr SeqRec_ValidateDone
	ld a, (0x38f8:16)
	cp a, 0:i3
	jr z, .Lc_f6627a
	extz WA
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, .Lc_f6627a
	ld c, (0x38f8:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f6627a
	ld wa, 3:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 3:i3
	calr Tempo_FormatBPM
	ldfr_berp l, 0xfb
	cps_erpb 0xfb, 1
	jr z, Tempo_DisplayEffect
Tempo_DisplayTimeSigNum:
.Lc_f6627a:
	ld wa, 4:i3
	calr SeqRec_ValidateDone
	ld a, (0x38f9:16)
	cp a, 0:i3
	jr z, Tempo_DisplayEffectLookup
	extz WA
	calr Part_IsPercussionType
	cp l, 0:i3
	jr nz, Tempo_DisplayEffectLookup
	ld c, (0x38f9:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, Tempo_DisplayEffectLookup
	ld wa, 4:i3
	calr Part_StoreVoiceTableIndex
	ld wa, 4:i3
	calr Tempo_FormatBPM
	ldfr_berp l, 0xfb
	cps_erpb 0xfb, 1
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
	push	qiz
	lda	xde, (14588:16)
	ld	xbc, xde
	lda	xde, (xde+10)
Tempo_FormatBPMDigit:
	ld	(xbc+), 0
	cp	xbc, xde
	jr	c, Tempo_FormatBPMDigit
	cp	a, 0:i3
	jr	nz, Tempo_FormatBPMDone
	set	0, (0x38fb:16)
	jr	Tempo_FormatBPMOutput
Tempo_FormatBPMDone:
	; resda 0, 0x3997 (v7 patched)
	res	0, (0x38fb:16)
Tempo_FormatBPMOutput:
	cp	a, 1:i3
	jr	nz, Tempo_FormatBPMPad
	set	1, (0x38fb:16)
	jr	Tempo_DisplayBPMValue
Tempo_FormatBPMPad:
	; resda 1, 0x3997 (v7 patched)
	res	1, (0x38fb:16)
Tempo_DisplayBPMValue:
	ld wa, (14576:16)

	sub wa, (14574:16)

	inc 1, a

	ldfr_berp A, 0xfa

	; mul wa, (0x3986:16) (v7 patched)
	mul wa, (0x38ea:16)
	ldfr_berp A, 0xfa



Tempo_DisplayBPMFraction:
	cpib_erp	250, 0
	jr	z, Tempo_DisplayBPMWithDec
	calr	Voice_ReadEventBytes
	calr	RhythmParam_TypeCheck
	ld	a, (14588:16)
	cp	a, 129
	jr	nz, Tempo_DisplayBPMNoFrac
	dec1b_erp	250
	jr	Tempo_DisplayBPMDecimal
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
	ld	(14588:16), 129
	calr	Voice_ScanTableByType
	cp	l, 1:i3
	jr	z, Tempo_DisplayBPMExit
	inc1b_erp	251
	ldto_berp	a, 251
	cpb_erp	a, 250
	jr	nz, Tempo_DisplayBPMFinal
Tempo_DisplayBPMClean:
	ld	(14588:16), 131
	calr	Voice_ScanTableByType
	cp	l, 1:i3
	jr	z, Tempo_DisplayBPMExit
	ld	l, 0:opc
Tempo_DisplayBPMExit:
	popw_erp 0xfa
	ret
Tempo_DisplayBPMReturn:
	lda	xsp, (xsp-18)
	push	xiz
	ld	xiy, Tempo_DisplayBPMReturn_LocalInit
	lda	xix, (xsp+6)
	ldw	bc, 8
	ldirw
	ld	e, (14579:16)
	ld	xwa, 0:i3
	ld	a, e
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 5
	ld	xiz, xbc
	add	xiz, 608352
	lda	xbc, (xiz+12)
	ld	a, (14570:16)
	inc	3, a
	cp	a, (xbc)
	jr	z, Tempo_DisplayMeasureRange
	ld	(xsp+4), (13370)
	ld	(13370:16), e
	ld	a, (14570:16)
	inc	3, a
	ld	(xbc), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	AccPatch_RefreshSlotOffset_Wrap
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(13370), (xsp+4)
Tempo_DisplayMeasureRange:
	ld wa, (14576:16)

	sub wa, (14574:16)

	ld (xiz + 13), a

	resm 7, (xiz + 15)

	lda xde, (xsp + 6)

	lda xwa, (xiz + 64)

	ld xbc, xwa

	lda xhl, (xwa + 16)



Tempo_DisplayMeasureStart:
	ld	a, (xde+)
	ld	(xbc+), a
	cp	xbc, xhl
	jr	c, Tempo_DisplayMeasureStart
	cp	(0x38f5:16), 0
	jr	z, Tempo_DisplayMeasureSep
	ld	wa, 0:i3
	calr	Tempo_DisplayEffectValLookup
Tempo_DisplayMeasureSep:
	cp	(0x38f6:16), 0
	jr	z, Tempo_DisplayMeasureEnd
	ld	wa, 1:i3
	calr	Tempo_DisplayEffectValLookup
Tempo_DisplayMeasureEnd:
	cp	(0x38f7:16), 0
	jr	z, Tempo_DisplayQuantizeVal
	ld	wa, 2:i3
	calr	Tempo_DisplayEffectValLookup
Tempo_DisplayQuantizeVal:
	cp	(0x38f8:16), 0
	jr	z, Tempo_DisplayTimeSig
	ld	wa, 3:i3
	calr	Tempo_DisplayEffectValLookup
Tempo_DisplayTimeSig:
	cp	(0x38f9:16), 0
	jr	z, Tempo_DisplayEffectVal
	ld	wa, 4:i3
	calr	Tempo_DisplayEffectValLookup
Tempo_DisplayEffectVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

Tempo_DisplayEffectValLookup:
	dec	8, xsp
	push	xiz
	ld	(xsp+10), a
	cp	(xsp+10), 4
	jr	z, Tempo_RefreshDisplay4
	cp	(xsp+10), 3
	jr	z, Tempo_RefreshDisplay3
	cp	(xsp+10), 2
	jr	z, Tempo_RefreshDisplay2
	cp	(xsp+10), 1
	jr	z, Tempo_RefreshDisplay1
	cp	(xsp+10), 0
	jr	nz, Tempo_RefreshDisplay5
	ld	a, (0x38f5:16)
	ldfr_berp	a, 251
	ld	(xsp+8), 24
	jr	Tempo_RefreshDisplay5
Tempo_RefreshDisplay1:
	ld	a, (0x38f6:16)
	ldfr_berp	a, 251
	ld	(xsp+8), 32
	jr	Tempo_RefreshDisplay5
Tempo_RefreshDisplay2:
	ld	a, (0x38f7:16)
	ldfr_berp	a, 251
	ld	(xsp+8), 40
	jr	Tempo_RefreshDisplay5
Tempo_RefreshDisplay3:
	ld	a, (0x38f8:16)
	ldfr_berp	a, 251
	ld	(xsp+8), 48
	jr	Tempo_RefreshDisplay5
Tempo_RefreshDisplay4:
	ld a, (14585:16)

	ldfr_berp A, 0xfb

	ld (xsp + 8), 0x38



Tempo_RefreshDisplay5:
	cpib_erp	251, 0
	jrl	z, SeqRec_UpdateFlags
	ld	xwa, 0:i3
	ld	a, (0x38f3:16)
	ld	xhl, xwa
	add	xhl, xhl
	add	xhl, xwa
	sll	xhl, 5
	add	xhl, 608352
	ld	(xsp+4), xhl
	ldto_berp	a, 251
	dec	1, a
	extz	wa
	lda	xbc, (0xf1a0:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	extz	wa
	sla	wa, 2
	lda	xbc, (Tempo_RefreshDisplay5_Table:24)
	ld	xix, (xbc+wa)
	ld	e, (xix+1)
	extz	de
	ld	c, (xsp+8)
	extz	bc
	cp	(xsp+10), 0
	jr	nz, SeqRec_InitState
	lda	xwa, (xhl+bc)
	ld	c, (xix)
	extz	bc
	calr	SeqRec_CheckOverflow
	jr	SeqRec_InitChannels
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

	; calr SetWall_StoreAndResolve (v7 displacement)
	calr	SetWall_StoreAndResolve
	; ldw_d16 xbc, (0x398a) (v7 patched)
	ld	bc, (0x38ee:16)
	dec 1, bc

	ld a, (14570:16)

	extz wa

	ldfr_werp WA, 0xfa

	mul xwa, bc

	ldfr_werp WA, 0xfa

	ld iz, 0:i3



SeqRec_StartRecord:
	cpw_erp IZ, 0xfa
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	calr	Voice_ReadEventBytes
	lda	xhl, (14588:16)
	ld	c, (xhl)
	ld	a, c
	and	a, 240
	cp	a, 192
	jr	z, SeqRec_StopRecordImpl
	cp	a, 128
	jr	nz, SeqRec_StartRecord
	cp	c, 129
	jr	nz, SeqRec_StopRecord
	inc	1, iz
	jr	SeqRec_StartRecord
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
	push QIZ
	ld c, (0x343a:16)
	st_erpb_rr c, 0xfa
	ld c, (0x36ff:16)
	st_erpb_rr c, 0xfb
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
	ld (0x36ff:16), 0x10
	jr t, Part_LoadAndIndexVoiceTable
SeqRec_Cleanup:
	ld	(14079:16), 8
	jr	Part_LoadAndIndexVoiceTable
Part_SetVoiceType1:
	ld	(14079:16), 1
	jr	Part_LoadAndIndexVoiceTable
Part_SetVoiceType2:
	ld	(14079:16), 2
	jr	Part_LoadAndIndexVoiceTable
Part_SetVoiceType4:
	ld	(14079:16), 4
Part_LoadAndIndexVoiceTable:
	ld	a, (14579:16)
	ld	(13370:16), a
	ld	xwa, 0:i3
	ld	a, (14579:16)
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	sll	xbc, 5
	add	xbc, 608352
	ld	a, (xbc+12)
	dec	3, a
	ld	(13373:16), a
	ld	a, (xbc+13)
	ld	(13371:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	VoiceSlot_InitFromTable
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldto_berp	a, 250
	ld	(13370:16), a
	ldto_berp	a, 251
	ld	(14079:16), a
	pop qiz
	ret
Part_StoreVoiceTableIndex:
	ld	c, a
	extz	bc
	ld	a, (14579:16)
	extz	wa
	mul	wa, 5
	add	wa, bc
	ld	(14564:16), wa
	ldw	(14568:16), 6
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
	cp	a, 16
	jr	ule, MIDIChan_StoreResult
	ld	(14586:16), 0
	ret
MIDIChan_StoreResult:
	ld	(14586:16), a
	ret
VoiceSlot_UpdateState:
	ld a, (0x38fa:16)
	ld (0x288d:16), a
	cp (0x38fa:16), 0x00
	jr nz, VoiceSlot_SetBit2
	res 2, (0x287b:16)
	jr t, VoiceSlot_ValidateAndResolve
VoiceSlot_SetBit2:
	set 2, (0x287b:16)

VoiceSlot_ValidateAndResolve:
	call SeqVoice_ValidateAndProcessState
	ldmm16 0x287f, 0x38ee
	ld a, (0x38f7:16)
	cp a, 0:i3
	jr z, VoiceSlot_CheckSlot2
	extz WA
	jr t, VoiceSlot_ResolveAddr
VoiceSlot_CheckSlot2:
	ld	a, (14584:16)
	cp	a, 0:i3
	jr	z, VoiceSlot_CheckSlot3
	extz	wa
	jr	VoiceSlot_ResolveAddr
VoiceSlot_CheckSlot3:
	ld	a, (14585:16)
	cp	a, 0:i3
	jr	z, VoiceSlot_CheckSlot4
	extz	wa
	jr	VoiceSlot_ResolveAddr
VoiceSlot_CheckSlot4:
	ld	a, (14582:16)
	cp	a, 0:i3
	jr	z, VoiceSlot_CheckSlot5
	extz	wa
	jr	VoiceSlot_ResolveAddr
VoiceSlot_CheckSlot5:
	ld	a, (14581:16)
	cp	a, 0:i3
	jr	z, VoiceSlot_StoreAndReturn
	extz	wa
VoiceSlot_ResolveAddr:
	call Voice_ResolveSlotAddr

VoiceSlot_StoreAndReturn:
	; ldmm8 0x3986, 0x288e (v7 displacement)
	ldmm8	14570, 10382
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
	lda	xbc, (14588:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xwa)
	ld	(xde), c
	calr	VoiceTable_AdvanceReadPos
	ld	xwa, xhl
	inc	1, iz
	cp	iz, qiz
	jr	c, VoiceBuf_CopyLoop
VoiceBuf_CopyDone:
	pop xiz
	ret

Voice_ScanTableByType:
	push	xiz
	calr	Voice_ResolveTableAddr
	ld	xwa, xhl
	ld	c, (14588:16)
	cp	c, 131
	jr	z, VoiceScan_Size1
	cp	c, 129
	jr	z, VoiceScan_Size1
	cp	c, 213
	jr	z, Voice_SetScanType3
	cp	c, 212
	jr	z, Voice_SetScanType3
	cp	c, 211
	jr	z, Voice_SetScanType3
	cp	c, 210
	jr	z, Voice_SetScanType3
	cp	c, 209
	jr	z, Voice_SetScanType3
	cp	c, 145
	jr	z, VoiceScan_Size8
	cp	c, 144
	jr	nz, VoiceScan_Size0
	ld	qiz, 6
	jr	Voice_ScanTableEntries
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
	lda	xbc, (14588:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	ld	(xwa), c
	calr	VoiceTable_AdvanceWritePos
	ld	xwa, xhl
	cp	xwa, 4294967295
	jr	nz, VoiceScan_NextEntry
	ld	l, 1:opc
	jr	VoiceScan_Return
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
	ld	xhl, xwa
	ld	wa, (14566:16)
	inc	1, wa
	ld	(14566:16), wa
	cp	wa, 256
	jr	c, VoiceTable_AdvRead_Done
	ld	wa, (14562:16)
	dec	1, wa
	extz	xwa
	sll	xwa, 8
	ld	xde, xwa
	add	xde, 720896
	ld	c, (xde+4)
	extz	bc
	sll	bc, 8
	ld	a, (xde+3)
	extz	wa
	add	wa, bc
	ld	(14562:16), wa
	ldw	(14566:16), 5
VoiceTable_AdvRead_Done:
	jr VoiceTable_ResolveReadAddr

VoiceTable_ResolveReadAddr:
	ld	bc, (14566:16)
	extz	xbc
	ld	wa, (14562:16)
	dec	1, wa
	extz	xwa
	sll	xwa, 8
	add	xwa, 720896
	add	xwa, xbc
	ld	xhl, xwa
	ret
VoiceTable_AdvanceWritePos:
	ld	xhl, xwa
	ld	wa, (14568:16)
	inc	1, wa
	ld	(14568:16), wa
	cp	wa, 255
	jr	c, RhythmParam_Setup
	ld	wa, (13368:16)
	cp	wa, 0:i3
	jr	nz, VoiceTable_AdvWrite_AllocSlot
	ld	xhl, 4294967295
	jr	RhythmParam_Entry
VoiceTable_AdvWrite_AllocSlot:
	dec	1, wa
	ld	(13368:16), wa
	ldw	bc, 150
	ld	xde, 651776
VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	lda xde, (xde+256)
	cp bc, 0x153
	jr ule, VoiceTable_AdvWrite_ScanLoop

VoiceTable_AdvWrite_LinkEntry:
	ld wa, (14564:16)

	extz xwa

	sll xwa, 8

	ld xhl, xwa

	add xhl, 0x95c00

	ld a, c

	ld (xhl + 3), a

	ld wa, bc

	srl wa, 8

	ld (xhl + 4), a

	ld wa, (14564:16)

	ld (xde + 1), a

	ld wa, (14564:16)

	srl wa, 8

	ld (xde + 2), a

	ld (14564:16), bc

	ldw (14568:16), 6

	setm 7, (xde)



; Rhythm parameter dispatch setup

RhythmParam_Setup:
	calr Voice_ResolveTableAddr

; Rhythm parameter entry
RhythmParam_Entry:
	ret

Voice_ResolveTableAddr:
	ld	bc, (14568:16)
	extz	xbc
	ld	wa, (14564:16)
	extz	xwa
	sll	xwa, 8
	add	xwa, 613376
	add	xwa, xbc
	ld	xhl, xwa
	ret
RhythmParam_TypeCheck:
	lda	xwa, (0x38fc:16)
	bit	0, (0x38fb:16)
	jr	z, RhythmParam_Process
	ld	xde, xwa
	ld	c, (xwa)
	ld	a, c
	and	a, 240
	cp	a, 128
	jr	z, RhythmParam_Dispatch
	cp	a, 144
	jr	nz, RhythmParam_CheckExit
	ld	(xde), 144
	ret
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
	ld	xhl, xwa
	ld	e, (xwa)
	ld	d, e
	and	d, 240
	cp	d, 128
	jrl	z, VoiceSlot_Dispatch
	lda	xbc, (xhl+2)
	lda	xwa, (xhl+3)
	cp	d, 208
	jrl	z, VoiceParam_D0Handler
	cp	d, 176
	jrl	z, VoiceParam_B0_Handler
	cp	d, 144
	jrl	nz, Voice_ClearSlotAndRet
	ld	e, (14578:16)
	cp	e, 25
	jr	ule, VoiceNote_SubtractOffset
	ld	xix, xbc
	sub	e, 25
	ld	a, (xbc)
	add	a, e
	ld	(xbc), a
	cp	a, 127
	jr	ule, Voice_BoundaryCheck
	ld	(xix), 127
	jr	Voice_BoundaryCheck
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
	bit	1, (0x38fb:16)
	jr	z, VoiceBound_CalcOctave
	lda	xbc, (xhl+2)
	ld	a, (xbc)
	cp	a, 12
	jr	c, VoiceBound_CalcOctave
	sub	a, 12
	ld	(xbc), a
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
	push	xiz
	ld	w, (14586:16)
	call	15858243
	ld	(14566:16), iy
	ld	iy, (10415:16)
	ld	(14562:16), iy
	pop	xiz
	ret
VoiceSlot_Dispatch_Type81:
	ld	a, 127:opc
	ld	(14124:16), a
	ld	a, 255:opc
	ld	(14123:16), a
	ld	c, 0:opc
VoiceSlot_Dispatch_Type90:
	cp	c, 7:i3
	jr	z, VoiceSlot_Dispatch_D0Type	; -> 0xF66B3F
	ld	xwa, 14095
	ld	e, 0:opc
	ld	(xwa+c), e
	ld	xwa, 14102
	ld	e, 1:opc
	ld	(xwa+c), e
	ld	xwa, 14109
	ld	e, 255:opc
	ld	(xwa+c), e
	ld	xwa, 14116
	ld	e, 255:opc
	ld	(xwa+c), e
	inc	1, c
	jr	VoiceSlot_Dispatch_Type90	; -> 0xF66B07
VoiceSlot_Dispatch_D0Type:
	ld	(14125:16), 64
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 32
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 16
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 8
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 4
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 2
	calr	RhythmDrum_LoadVoiceParams
	ld	(14125:16), 1
	calr	RhythmDrum_LoadVoiceParams
	ret
VoiceSlot_Dispatch_Return:
	push XIZ
	call VoiceSlot_Dispatch_D0Type_Helper
	pop XIZ
	ret
VoiceSlot_Dispatch_D0Type_Helper:
	bit	7, a
	jr	nz, VoiceSlot_Dispatch_Return_Skip2
	cp	(13370:16), 11
	jr	ge, VoiceSlot_Dispatch_Return_Skip
	inc	1, (13370:16)
	jr	VoiceSlot_Dispatch_Return_Join
VoiceSlot_Dispatch_Return_Skip:
	ld	(13370:16), 11
VoiceSlot_Dispatch_Return_Join:
	jr	VoiceSlot_Dispatch_Return_Join2
VoiceSlot_Dispatch_Return_Skip2:
	cp	(13370:16), 0
	jr	gt, VoiceSlot_Dispatch_Return_Skip3
	ld	(13370:16), 0
	jr	VoiceSlot_Dispatch_Return_Join2
VoiceSlot_Dispatch_Return_Skip3:
	dec	1, (13370:16)
VoiceSlot_Dispatch_Return_Join2:
	calr	VoiceSlot_Dispatch_Return_Helper
	calr	DrumParam_BuildActiveMask
	ret
VoiceSlot_Dispatch_Return_Helper:
	ld	xhl, 0:i3
	ld	l, (13370:16)
	and	l, 31
	add	l, 128
	ld	xbc, 64602
	ld	a, 0:opc
	ld	(xbc+a), l
	ld	a, 1:opc
	ld	h, (xbc+a)
	and	h, 128
	ld	(xbc+a), h
	ld	a, (64602:16)
	ld	w, 0:opc
	ld	e, 72:opc
	ld	d, 0:opc
	call	SysEx_ApplyVoiceParam_49
	ret
DrumParam_ProcessChannel:
	push xiz
	calr DrumParam_LookupChannelBit
	call DrumParam_ProcessChannel_Helper
	pop xiz
	ret

DrumParam_LookupChannelBit:
	push XWA
	push XIX
	ld a, (0x391c:16)
	ld XIX,PatIdx_Lookup_Return
	ld	a, (xix+a)
	ld	(0x372d:16), a
	pop	xix
	pop	xwa
	ret
PatIdx_Lookup_Return:
	normal
	push	sr
	max
	ld	(16:8), 32:io
	.byte 0x40

DrumParam_ProcessChannel_Helper:
	push_a
	calr DrumParam_ReadVoiceCount
	ld L,A
	pop_a
	push	l
	push_a
	calr	Rhythm_MapChannelToDrumIndex
	pop_a
	ld	xiy, 14095
	add	xiy, xbc
	bit	7, a
	jr	nz, VoiceTable_InitEntry_Loop
	cp	(xiy), 9
	jr	ge, VoiceTable_InitEntry
	inc	1, (xiy)
	jr	RhythmVoice_LoadParams
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
	ld	w, 0:opc
	ld	(14124:16), w
	xor	bc, bc
	ld	w, 1:opc
	ld	xix, 14095
	ld	xiy, 14109
VoiceTable_InitEntry_Store:
	ld	a, (xix+)
	cp	a, (xiy+)
	jr	z, VoiceTable_InitEntry_Return
	or	(14124:16), w
VoiceTable_InitEntry_Return:
	sll	w, 1
	inc	1, bc
	cp	bc, 7:i3
	jr	lt, VoiceTable_InitEntry_Store
	xor	bc, bc
	ld	w, 1:opc
	ld	xix, 14102
	ld	xiy, 14116
MultiVoice_SetupChannel:
	ld	a, (xix+)
	cp	a, (xiy+)
	jr	z, MultiVoice_Setup_Loop
	or	(14124:16), w
MultiVoice_Setup_Loop:
	sll	w, 1
	inc	1, bc
	cp	bc, 7:i3
	jr	lt, MultiVoice_SetupChannel
	ld	a, (13370:16)
	cp	a, (14123:16)
	jr	z, MultiVoice_Setup_WriteParam
	ld	b, 127:opc
	ld	(14124:16), b
MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	ld	xbc, 0:i3
	ld	c, (14125:16)
	srl	c, 1
	add	xbc, MultiVoice_Setup_Done
	ld	c, (xbc)
	cp	c, 6:i3
	jr	le, MultiVoice_Setup_NextChan
	ld	c, 0:opc
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
; readers in v7 (address from the linked ELF): Rhythm_MapChannelToDrumIndex 0xF66CBB
; (v7 copy: the RAM addresses and ROM values quoted above are the v9/v10
; ones; v7's RAM layout differs -- read them off the reader named above.)
	.byte 0x00, 0x01, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06

DrumParam_ReadVoiceCount:
	calr	65470
	ld	xix, 14102
	add	xix, xbc
	ld	a, (xix)
	ret
RhythmDrum_LoadVoiceParams:
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14095
	add	xix, xbc
	ld	xwa, 0:i3
	ld	a, (xix)
	mul	bc, 10
	add	xbc, xwa
	ld	xde, 0:i3
	ld	xhl, 0:i3
	ld	xwa, RhythmDrum_EntryCounts
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
	push	xde
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14102
	add	xix, xbc
	ld	xwa, 0:i3
	ld	a, (xix)
	pop	xde
	add	xde, xwa
	sll	xde, 2
	ld	xwa, RhythmDrum_Entries
	add	xwa, xde
	ld	xhl, (xwa)
	push	xhl
	calr	Rhythm_MapChannelToDrumIndex
	pop	xhl
	ld	xde, xhl
	srl	xde, 8
	srl	xde, 8
	srl	xde, 8
	ld	xwa, 14309
	add	xwa, xbc
	ld	(xwa), e
	push	xhl
	calr	VoiceAssign_Process_Return
	pop	xhl
	srl	xhl, 8
	srl	xhl, 8
	push	l
	ld	xhl, 0:i3
	pop	l
	calr	VoiceAssign_ProcessRequest_Helper
	ret
VoiceAssign_Process_Return:
	ld (0x905a:16), 0x48
	call SndParam_ApplyProgramChange_Safe
	call VoiceParam_ClampAndValidate_Tramp
	pushw hl
	calr Rhythm_MapChannelToDrumIndex
	popw hl
	ld XIX,0x00003836
	ld	(xix+c), l
	ld	xix, 14397
	ld	(xix+c), h
	sll	l, 1
	sll	hl, 1
	ld	xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	add	hl, 2
	ld	xde, 0:i3
	ld	de, (xiy+hl)
	ld	w, a
	and	xwa, 65280
	sll	xwa, 8
	ld	xix, 4194304
	add	xix, (0x31db:16)
	add	xix, xwa
	add	xix, xde
	jr	VoiceAssign_StoreFinal
VoiceAssign_StoreFinal:
	ret

VoiceAssign_ProcessRequest_Helper:
	pushw hl
	push xix
	calr Rhythm_MapChannelToDrumIndex
	pop xix
	popw hl
	ld xwa, RegPreset_LoadVoiceData
	ld	a, (xwa+hl)
	and xwa, 0x7
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_Code
	ld xde, 0:i3
	ld de, (xbc)
	push xix
	calr RegPreset_Load_Loop
	pop xix
	pop xwa
	push xwa
	ld xbc, xwa
	sll xbc, 1
	add xbc, RegPreset_LoadVoiceData_0x14
	ld xde, 0:i3
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
	calr VoiceAssign_StoreFinal_Helper
	pop xix
	ret

RegPreset_LoadVoiceData:
	nop
	pop	sr
	max
	reti
RegPreset_LoadVoiceData_Code:
	nop
	nop
	retd	3844
	max
	retd	0
	max
	retd	3844
	max
	retd	4
	nop
	ldw	bc, 0x3104
	max
	ldw	bc, 0
	max
	ldw	bc, 0x3104
	max
	ldw	bc, 4
	nop
	ei	4
	ei	4
	ei	0
	nop
	max
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
	ld hl, 1:i3
	cp wa, 0x400
	jr nc, RegPreset_Load_Return
	ld hl, 0:i3

RegPreset_Load_Return:
	ld xbc, 0:i3

RegPreset_LoadVoiceData_Join:
	cp c, 4:i3
	jr z, ChanAssign_StoreResult
	push xbc
	pushw wa
	push xbc
	calr RegPreset_LoadVoiceData_Helper
	pop xbc
	calr ChanAssign_Lookup_Found
	popw wa
	pop xbc
	inc 1, wa
	inc 1, c
	jr RegPreset_LoadVoiceData_Join

ChanAssign_StoreResult:
	ret

RegPreset_LoadVoiceData_Helper:
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
	push	xde
	push	xbc
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 4
	ld	xwa, xbc
	pop	xbc
	sll	bc, 2
	add	xwa, xbc
	add	xwa, 14190
	pop	xde
	add	xde, 6
	ld	(xwa), xde
	ret
MIDIChan_DispatchTable:
	ldw bc, 0x3d1

	ld xwa, 0:i3

	ld	w, (xix+bc)

	and xwa, 0xff00

	sll xwa, 8

	ld xiy, 0x400000

	add xix, (12763:16)

	add xiy, xwa

	ret



DrumChannel_MapToIndexA:
	cp (0x372d:16), 0x01
	jr nz, .Lc_f66f2a
	ld xbc, 0:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch1:
.Lc_f66f2a:
	cp (0x372d:16), 0x02
	jr nz, .Lc_f66f35
	ld xbc, 0:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch2:
.Lc_f66f35:
	cp (0x372d:16), 0x04
	jr nz, .Lc_f66f40
	ld xbc, 0:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch3:
.Lc_f66f40:
	cp (0x372d:16), 0x08
	jr nz, .Lc_f66f4b
	ld xbc, 1:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch4:
.Lc_f66f4b:
	cp (0x372d:16), 0x10
	jr nz, .Lc_f66f56
	ld xbc, 2:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch5:
.Lc_f66f56:
	cp (0x372d:16), 0x20
	jr nz, MIDIChan_Dispatch_Ch6
	ld xbc, 3:i3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch6:
	ld xbc, 4:i3

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	cp (0x372d:16), 0x01
	jr nz, .Lc_f66f6f
	ld xbc, 0:i3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch7:
.Lc_f66f6f:
	cp (0x372d:16), 0x02
	jr nz, .Lc_f66f7a
	ld xbc, 0:i3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch8:
.Lc_f66f7a:
	cp (0x372d:16), 0x04
	jr nz, .Lc_f66f85
	ld xbc, 0:i3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch9:
.Lc_f66f85:
	cp (0x372d:16), 0x08
	jr nz, .Lc_f66f90
	ld xbc, 2:i3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch10:
.Lc_f66f90:
	cp (0x372d:16), 0x10
	jr nz, .Lc_f66f9b
	ld xbc, 3:i3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch11:
.Lc_f66f9b:
	cp (0x372d:16), 0x20
	jr nz, MIDIChan_Dispatch_Ch12
	ld xbc, 4:i3
	jr t, DrumChannel_MapB_NullRet
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

	add xbc, 14133

	ld xiy, xbc

	ld xbc, 7:i3

	push xiy

	push xix

	pop xiy

	pop xix

	ldir85

	ret



VoiceResolve_CheckAndStore:
	bit 0, (0x372d:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 1, (0x372d:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 2, (0x372d:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	bit 3, (0x372d:16)
	jr nz, Rhythm_ClearChannelDrumIndex
	add DE,0x03d2
	ld	a, (xix+de)
	calr Rhythm_MapChannelToDrumIndex
	add XBC,VoiceResolve_SearchDone
	ld C,(XBC)
	and A,C
	cp A,C
	jr nz, VoiceResolve_Return
	ld A, 0x00:opc
	jr t, VoiceResolve_CheckAndStore_Join
VoiceResolve_Return:
	ld a, 0x1:opc

VoiceResolve_CheckAndStore_Join:
	jr VoiceResolve_InitSearch

Rhythm_ClearChannelDrumIndex:
	ld a, 0x0:opc

VoiceResolve_InitSearch:
	push_a
	calr	Rhythm_MapChannelToDrumIndex
	pop_a
	add	xbc, 14302
	ld	(xbc), a
	ret
VoiceResolve_SearchDone:
	ld	(8:8), 8:io
	ld	(8:8), 16:io
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

	add xbc, 14126

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
	add XBC,0x0000370f
	ld xwa, 0:i3
	ld A,(XBC)
	sll XWA, 0x04
	ld XIY,AccRhythm_Ram3888_Records
	add XIY,XWA
	ld XIX,0x000037ec
	ld XBC,0x00000010
	push XIX
	ldir85
	pop XIX
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
	calr	DrumParam_ReadMaxCount
	pop_a
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14102
	add	xix, xbc
	ld	c, (xix)
	cp	a, 0:i3
	jr	nz, PartVoice_Update_Loop
	cp	c, w
	jr	ge, DrumParam_ClampVoiceCount
	inc	1, c
	jr	DrumParam_ClampVoiceCount
PartVoice_Update_Loop:
	cp	c, 0:i3
	jr	z, DrumParam_ClampVoiceCount
	dec	1, c
	bit	0, (0x372d:16)
	jr	z, DrumParam_ClampVoiceCount
	cp	c, 1:i3
	jr	ge, DrumParam_ClampVoiceCount
	ld	c, 1:opc
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
	ld XHL,XBC
	add XHL,0x0000370f
	ld L,(XHL)
	mul BC,0x000a
	ld XWA,RhythmDrum_EntryCounts
	add XWA,XBC
	ld	w, (xwa+l)
	dec	1, w
	ret
ExtVoice_ProcessList:
	ret
CmEsyTtl_Dispatch2_Helper2:
	push XIZ
	call ExtVoice_ProcessList_Data
	pop XIZ
	ret
ExtVoice_ProcessList_Data:
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	nz, DrumParam_ReadMaxCount_Return
	or	(0x3431:16), 128
	call	Seq_DispatcherEntry
	call	AccWrap_PlayModeStartAccPlay
DrumParam_ReadMaxCount_Return:
	ret
ExtVoice_ProcessList_0x1C:
	push	xiz
	call	ExtVoice_ProcessList_Helper
	pop	xiz
	ret
ExtVoice_ProcessList_Helper:
	call	AccWrap_PlayModeDispatch
	calr	DrumParam_ReadMaxCount_Helper3
	call	Seq_DispatcherEntry
	pushdi_b	(14125)
	calr	DrumParam_ReadMaxCount_Helper4
	calr	DrumParam_ReadMaxCount_Helper5
	ld	(32422:16), 0
	calr	DrumParam_ReadMaxCount_Helper6
	cp	(32422:16), 0
	jr	z, DrumParam_ReadMaxCount_Skip
	call	AccPatch_InitCurrentSlot
	or	(0x372c:16), 127
	jr	DrumParam_ReadMaxCount_Entry
DrumParam_ReadMaxCount_Skip:
	ld	(14124:16), 0
DrumParam_ReadMaxCount_Entry:
	pop	(0x372d:16)
	or	(0x3431:16), 128
	call	Seq_DispatcherEntry
	cp	(32422:16), 0
	jr	nz, DrumParam_ReadMaxCount_Skip2
	call	AccWrap_PlayModeStartAccPlay
	jr	DrumParam_ReadMaxCount_Return2
DrumParam_ReadMaxCount_Skip2:
	calr	DrumParam_ReadMaxCount_Helper2
DrumParam_ReadMaxCount_Return2:
	ret
DrumParam_ReadMaxCount_Helper2:
	call	DrumVoice_NotifyEE
	ret
DrumParam_ReadMaxCount_Helper3:
	bit	2, (0x41e:16)
	jr	z, DrumParam_ReadMaxCount_Return3
	jr	DrumParam_ReadMaxCount_Helper3
DrumParam_ReadMaxCount_Return3:
	ret
DrumParam_ReadMaxCount_Helper4:
	ld	(14125:16), 1
	calr	Rhythm_MapChannelToDrumIndex
	ld	xwa, 14126
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (13373:16)
	jr	z, DrumParam_ReadMaxCount_Return4
	ld	(14124:16), 127
	ld	(13373:16), a
	calr	VoiceResolve_FindSlot_Return
	ld	(13372:16), a
DrumParam_ReadMaxCount_Return4:
	ret
DrumParam_ReadMaxCount_Helper5:
	ld	(13371:16), 3
	ret
DrumParam_ReadMaxCount_Helper6:
	bit	3, (0x372c:16)
	jr	z, DrumParam_ReadMaxCount_Entry2
	ld	(14125:16), 8
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14302
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Entry2
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Entry2:
	bit	4, (0x372c:16)
	jr	z, DrumParam_ReadMaxCount_Entry3
	ld	(14125:16), 16
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14302
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Entry3
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Entry3:
	bit	5, (0x372c:16)
	jr	z, DrumParam_ReadMaxCount_Entry4
	ld	(14125:16), 32
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14302
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Entry4
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Entry4:
	bit	6, (0x372c:16)
	jr	z, DrumParam_ReadMaxCount_Entry5
	ld	(14125:16), 64
	calr	AccVoice_SetupStyleSlots
	calr	Rhythm_MapChannelToDrumIndex
	ld	xix, 14302
	cp	(xix+bc), 0x00
	jr	nz, DrumParam_ReadMaxCount_Entry5
	calr	AccVoice_SetupSlots_DataBlock
DrumParam_ReadMaxCount_Entry5:
	bit	0, (0x372c:16)
	jr	nz, DrumParam_ReadMaxCount_Skip3
	bit	1, (0x372c:16)
	jr	nz, DrumParam_ReadMaxCount_Skip3
	bit	2, (0x372c:16)
	jr	nz, DrumParam_ReadMaxCount_Skip3
	jr	DrumParam_ReadMaxCount_Return5
DrumParam_ReadMaxCount_Skip3:
	ld	(14125:16), 1
	calr	AccVoice_SetupStyleSlots
	calr	828
DrumParam_ReadMaxCount_Return5:
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
	cp	hl, 65535
	jr	z, AccVoice_SetupSlots_InitEntry
	calr	AccPatch_ResolveEntryAddr
	push	xwa
	add	xwa, 3
	ld	hl, (xwa)
	ldw	(xwa), 65535
	pop	xwa
	push	xwa
	add	xwa, 1
	ldw	(xwa), 65535
	pop	xwa
	push	xwa
	and	(xwa), 127
	pop	xwa
	pushw	hl
	calr	Voice_ClearSlotBuffer
	popw	hl
	incw	1, (0x3438:16)
	jr	AccVoice_SetupSlots_Loop
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

	ld c, (13371:16)

	inc 1, c

	; mul bc, (0x34d9:16) (v7 patched)
	mul bc, (0x343d:16)
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
	ld	xhl, 0:i3
	ld	l, (13370:16)
	cp	l, 30
	jr	lt, AccVoice_SetupSlots_Write
	ld	l, 0:opc
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
	ld xhl, 0:i3
	popw hl
	sll xhl, 8
	ld xwa, 0x95c00
	add xwa, xhl
	popw hl
	pop xix
	ret

AccVoice_SetupSlots_DataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 437 of 592 slots byte-identical
	calr	Rhythm_MapChannelToDrumIndex
	add	xbc, 14102
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Return
	calr	AccVoice_SetupSlots_DataBlock_Helper
	calr	AccVoice_SetupSlots_DataBlock_Helper2
	calr	AccVoice_SetupSlots_DataBlock_Helper3
AccVoice_SetupSlots_DataBlock_Return:
	ret
AccVoice_SetupSlots_DataBlock_Helper:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 3
	add	xbc, 14133
	ld	xiy, xbc
	calr	AccVoice_SetupStyleSlots_Helper2
	push	xix
	calr	DrumChannel_MapToIndexA
	pop	xix
	sll	bc, 3
	add	bc, 24
	add	xix, xbc
	ld	xbc, 8
	; v10 does not spell this byte either
	ldir85
	ret
AccVoice_SetupSlots_DataBlock_Helper2:
	calr	AccVoice_SetupStyleSlots_Helper2
	calr	DrumChannel_MapToIndexB
	sll	bc, 1
	ld	hl, (xix+bc)
	ld	(13686:16), hl
	ldw	(13688:16), 6
	ret
AccVoice_SetupSlots_DataBlock_Helper3:
	ld	c, 0:opc
	ld	(14389:16), c
	ld	c, (13371:16)
	inc	1, c
AccVoice_SetupSlots_DataBlock_Join:
	cp	c, (14389:16)
	jr	le, AccVoice_SetupSlots_DataBlock_Skip
	push	c
	calr	AccVoice_SetupSlots_DataBlock_Helper4
	pop	c
	ld	a, (14389:16)
	inc	1, a
	ld	(14389:16), a
	jr	AccVoice_SetupSlots_DataBlock_Join
AccVoice_SetupSlots_DataBlock_Skip:
	calr	AccVoice_SetupSlots_DataBlock_Helper10
	ret
AccVoice_SetupSlots_DataBlock_Helper4:
	calr	AccVoice_SetupSlots_DataBlock_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ld	a, 0:opc
	ld	(14388:16), a
	ld	c, (13373:16)
AccVoice_SetupSlots_DataBlock_Join2:
	cp	(14388:16), c
	jr	ge, AccVoice_SetupSlots_DataBlock_Return2
	push	c
	calr	AccVoice_SetupSlots_DataBlock_Helper6
	ld	a, (14388:16)
	inc	1, a
	ld	(14388:16), a
	pop	c
	jr	AccVoice_SetupSlots_DataBlock_Join2
AccVoice_SetupSlots_DataBlock_Return2:
	ret
AccVoice_SetupSlots_DataBlock_Helper5:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 4
	add	xbc, 14190
	ld	xwa, 0:i3
	ld	a, (14389:16)
	sll	xwa, 2
	add	xbc, xwa
	ld	xwa, (xbc)
	ret
AccVoice_SetupSlots_DataBlock_Helper6:
	calr	AccVoice_SetupSlots_DataBlock_Sub
	cp	a, 131
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip2
	calr	Rhythm_MapChannelToDrumIndex
	sll	bc, 2
	add	xbc, 14332
	ld	xwa, AccVoice_SetupSlots_DataBlock_Code
	ld	(xbc), xwa
	push	xbc
	ld	xbc, 1:i3
	calr	AccVoice_SetupSlots_DataBlock_Helper8
	pop	xbc
	ld	a, 129:opc
	jr	AccVoice_SetupSlots_DataBlock_Helper6_Join
AccVoice_SetupSlots_DataBlock_Skip2:
	push_a
	calr	AccVoice_SetupSlots_DataBlock_Helper8
	pop_a
AccVoice_SetupSlots_DataBlock_Helper6_Join:
	cp	a, 129
	jr	z, AccVoice_SetupSlots_DataBlock_Helper6_Return
	jr	AccVoice_SetupSlots_DataBlock_Helper6
AccVoice_SetupSlots_DataBlock_Helper6_Return:
	ret
AccVoice_SetupSlots_DataBlock_Code:
	cp	(xbc), l
	swi	7
	swi	7
	swi	7
AccVoice_SetupSlots_DataBlock_Sub:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_Code
	jr	z, AccVoice_SetupSlots_DataBlock_Sub_Skip
	ld	a, (xwa)
	jr	AccVoice_SetupSlots_DataBlock_Sub_Return
AccVoice_SetupSlots_DataBlock_Sub_Skip:
	ld	a, 131:opc
AccVoice_SetupSlots_DataBlock_Sub_Return:
	ret
AccVoice_SetupSlots_DataBlock_Helper7:
	ld	c, 0:opc
	cp	a, 144
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip3
	ld	c, 6:opc
	jr	AccVoice_SetupSlots_DataBlock_Return3
AccVoice_SetupSlots_DataBlock_Skip3:
	cp	a, 145
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip4
	ld	c, 8:opc
	jr	AccVoice_SetupSlots_DataBlock_Return3
AccVoice_SetupSlots_DataBlock_Skip4:
	cp	a, 129
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip5
	ld	c, 1:opc
	jr	AccVoice_SetupSlots_DataBlock_Return3
AccVoice_SetupSlots_DataBlock_Skip5:
	cp	a, 131
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip6
	ld	c, 1:opc
	jr	AccVoice_SetupSlots_DataBlock_Return3
AccVoice_SetupSlots_DataBlock_Skip6:
	ld	w, a
	and	w, 208
	cp	w, 208
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip7
	ld	c, 3:opc
	jr	AccVoice_SetupSlots_DataBlock_Return3
AccVoice_SetupSlots_DataBlock_Skip7:
	cp	c, 0:i3
	jr	nz, AccVoice_SetupSlots_DataBlock_Return3
	nop
AccVoice_SetupSlots_DataBlock_Return3:
	ret
AccVoice_SetupSlots_DataBlock_Helper8:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xiy, (xbc)
	ld	a, (xiy)
	ld	xbc, 0:i3
	calr	AccVoice_SetupSlots_DataBlock_Helper7
	ld	hl, (13686:16)
	pushw	bc
	calr	AccPatch_ResolveEntryAddr
	popw	bc
	ld	xix, xwa
	ld	xwa, 0:i3
	ld	wa, (13688:16)
	add	xix, xwa
	ldw	de, 255
	sub	de, (13688:16)
	cp	bc, de
	jr	gt, AccVoice_SetupSlots_DataBlock_Skip8
	; v10 does not spell this byte either
	add	(0x3578:16), bc
	; differs from v10 here and llvm-objdump cannot read it
	cp	bc, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Helper8_Skip
	; v10 does not spell this byte either
	ldir85
AccVoice_SetupSlots_DataBlock_Helper8_Skip:
	jr	AccVoice_SetupSlots_DataBlock_Join3
AccVoice_SetupSlots_DataBlock_Skip8:
	pushw	bc
	ld	bc, de
	; v10 does not spell this byte either
	add	(0x3578:16), bc
	; differs from v10 here and llvm-objdump cannot read it
	cp	bc, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Helper8_Skip2
	; v10 does not spell this byte either
	ldir85
AccVoice_SetupSlots_DataBlock_Helper8_Skip2:
	popw	bc
	push	xiy
	sub	bc, de
	ld	(13217:16), bc
	ld	(13219:16), de
	calr	AccVoice_SetupSlots_DataBlock_Helper9
	ld	hl, (13686:16)
	calr	AccPatch_ResolveEntryAddr
	ld	xix, xwa
	ld	xwa, 0:i3
	ld	wa, (13688:16)
	add	xix, xwa
	pop	xiy
	ld	bc, (13217:16)
	; v10 does not spell this byte either
	add	(0x3578:16), bc
	; differs from v10 here and llvm-objdump cannot read it
	cp	bc, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Join3
	; v10 does not spell this byte either
	ldir85
AccVoice_SetupSlots_DataBlock_Join3:
	push	xiy
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	pop	xiy
	ld	(xbc), xiy
	cp	xiy, AccVoice_SetupSlots_DataBlock_0x107
	jr	nz, AccVoice_SetupSlots_DataBlock_Return4
	ld	xiy, AccVoice_SetupSlots_DataBlock_Code
	ld	(xbc), xiy
AccVoice_SetupSlots_DataBlock_Return4:
	ret
AccVoice_SetupSlots_DataBlock_Helper9:
	; v10 does not spell this byte either
	cpw	(0x3438:16), 0
	; v10 does not spell this byte either
	jr	z, AccVoice_SetupSlots_DataBlock_Skip9
	ldw	hl, 150
AccVoice_SetupSlots_DataBlock_Join4:
	pushw	hl
	calr	AccPatch_ResolveEntryAddr
	popw	hl
	; v10 does not spell this byte either
	bit	7, (xwa)
	jr	z, AccVoice_SetupSlots_DataBlock_Helper9_Skip
	; v10 does not spell this byte either
	inc	1, hl
	jr	AccVoice_SetupSlots_DataBlock_Join4
AccVoice_SetupSlots_DataBlock_Helper9_Skip:
	ld	c, (xwa)
	or	c, 128
	ld	(xwa), c
	ld	de, 1:i3
	ld	bc, (13686:16)
	ld	(xwa+de), bc
	pushw	hl
	ld	hl, (13686:16)
	calr	AccPatch_ResolveEntryAddr
	ld	de, 3:i3
	popw	hl
	ld	(xwa+de), hl
	decw	1, (13368:16)
	ld	(13686:16), hl
	ld	wa, 6:i3
	ld	(13688:16), wa
	jr	AccVoice_SetupSlots_DataBlock_Return5
AccVoice_SetupSlots_DataBlock_Skip9:
	ld	wa, 6:i3
	ld	(13688:16), wa
	ld	(32422:16), 15
AccVoice_SetupSlots_DataBlock_Return5:
	ret
AccVoice_SetupSlots_DataBlock_Helper10:
	calr	Rhythm_MapChannelToDrumIndex
	sll	bc, 2
	add	xbc, 14332
	ld	xwa, AccVoice_SetupSlots_DataBlock_Code2
	ld	(xbc), xwa
	ld	c, 1:opc
	calr	AccVoice_SetupSlots_DataBlock_Helper8
	ret
AccVoice_SetupSlots_DataBlock_Code2:
	ld	a, (xhl)
	normal
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper
	calr	AccVoice_SetupSlots_DataBlock_Helper10_Helper
	calr	AccVoice_SetupSlots_DataBlock_Helper2
	calr	AccVoice_SetupSlots_DataBlock_Helper10_Helper2
	ret
AccVoice_SetupSlots_DataBlock_Helper10_Helper:
	calr	AccVoice_SetupStyleSlots_Helper2
	ld	w, (13372:16)
	ld	a, 12:opc
	ld	(xix+a), w
	ld	w, (13371:16)
	ld	a, 13:opc
	; v10 does not spell this byte either
	ld	(xix+a), w
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	w, 32:opc
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	a, 14:opc
	; v10 does not spell this byte either
	ld	(xix+a), w
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	w, 0:opc
	ld	a, 15:opc
	; v10 does not spell this byte either
	ld	(xix+a), w
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	a, 1:opc
	ld	(0x372d:16), a
	; v10 does not spell this byte either
	push	xix
	calr	Rhythm_MapChannelToDrumIndex
	pop	xix
	ld	xiy, 14390
	ld	w, (xiy+c)
	ld	a, 16:opc
	ld	(xix+a), w
	ld	xiy, 14397
	ld	w, (xiy+c)
	ld	a, 17:opc
	ld	(xix+a), w
	ld	xiy, AccVoice_SetupSlots_DataBlock_Data
	add	xix, 64
	ld	xbc, 0:i3
	ldw	bc, 16
	; v10 does not spell this byte either
	ldir85
	ret
AccVoice_SetupSlots_DataBlock_Data:
	.byte 0x45	; v10 does not spell this byte either
	.byte 0x61	; v10 does not spell this byte either
	.byte 0x73	; v10 does not spell this byte either
	.byte 0x79	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
AccVoice_SetupSlots_DataBlock_Helper10_Helper2:
	.byte 0x23	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	ld	(14389:16), c
	ld	c, (13371:16)
	add	c, 1
AccVoice_SetupSlots_DataBlock_Join5:
	cp	c, (14389:16)
	jr	le, AccVoice_SetupSlots_DataBlock_Skip10
	push	c
	calr	AccVoice_SetupSlots_DataBlock_Helper11
	pop	c
	ld	a, (14389:16)
	inc	1, a
	ld	(14389:16), a
	jr	AccVoice_SetupSlots_DataBlock_Join5
AccVoice_SetupSlots_DataBlock_Skip10:
	calr	AccVoice_SetupSlots_DataBlock_Helper10
	ret
AccVoice_SetupSlots_DataBlock_Helper11:
	ld	a, 1:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ld	a, 2:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ld	a, 4:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper5
	push	xwa
	calr	Rhythm_MapChannelToDrumIndex
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ld	a, 0:opc
	ld	(14388:16), a
	ld	c, (13373:16)
AccVoice_SetupSlots_DataBlock_Join6:
	cp	(14388:16), c
	jr	ge, AccVoice_SetupSlots_DataBlock_Return6
	push	c
	calr	AccVoice_SetupSlots_DataBlock_Helper12
	ld	a, (14388:16)
	inc	1, a
	ld	(14388:16), a
	pop	c
	jr	AccVoice_SetupSlots_DataBlock_Join6
AccVoice_SetupSlots_DataBlock_Return6:
	ret
AccVoice_SetupSlots_DataBlock_Helper12:
	ld	a, 1:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper13
	ld	a, 2:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper13
	ld	a, 4:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper13
	calr	AccVoice_SetupSlots_DataBlock_Helper17
	push	l
	calr	AccVoice_SetupSlots_DataBlock_Helper14
	pop	l
	cp	w, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Skip11
	calr	AccVoice_SetupSlots_DataBlock_Helper16
	ld	(14125:16), l
	calr	AccVoice_SetupSlots_DataBlock_Helper8
	jrl	AccVoice_SetupSlots_DataBlock_Helper12
AccVoice_SetupSlots_DataBlock_Skip11:
	ld	a, 1:opc
	ld	(14125:16), a
	ld	xbc, 0:i3
	ld	c, 1:opc
	calr	AccVoice_SetupSlots_DataBlock_Helper8
	ld	a, 2:opc
	ld	(14125:16), a
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_Code
	jr	z, AccVoice_SetupSlots_DataBlock_Skip12
	inc	1, xwa
	ld	(xbc), xwa
AccVoice_SetupSlots_DataBlock_Skip12:
	ld	a, 4:opc
	ld	(14125:16), a
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, AccVoice_SetupSlots_DataBlock_Code
	jr	z, AccVoice_SetupSlots_DataBlock_Return7
	inc	1, xwa
	ld	(xbc), xwa
AccVoice_SetupSlots_DataBlock_Return7:
	ret
AccVoice_SetupSlots_DataBlock_Helper13:
	calr	Rhythm_MapChannelToDrumIndex
	add	xbc, 14102
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, AccVoice_SetupSlots_DataBlock_Skip14
	calr	AccVoice_SetupSlots_DataBlock_Helper18
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	ld	l, (xwa)
	cp	l, 131
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip13
	ld	xwa, AccVoice_SetupSlots_DataBlock_Code
	ld	(xbc), xwa
AccVoice_SetupSlots_DataBlock_Skip13:
	jr	AccVoice_SetupSlots_DataBlock_Join7
AccVoice_SetupSlots_DataBlock_Skip14:
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, AccVoice_SetupSlots_DataBlock_Code
	ld	(xbc), xwa
AccVoice_SetupSlots_DataBlock_Join7:
	calr	92
	ret
AccVoice_SetupSlots_DataBlock_Helper14:
	ld	a, 1:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper15
	cp	a, 129
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip15
	ld	a, 2:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper15
	cp	a, 129
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip15
	ld	a, 4:opc
	ld	(14125:16), a
	calr	AccVoice_SetupSlots_DataBlock_Helper15
	cp	a, 129
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip15
	ld	w, 0:opc
	jr	AccVoice_SetupSlots_DataBlock_Return8
AccVoice_SetupSlots_DataBlock_Skip15:
	ld	w, 1:opc
AccVoice_SetupSlots_DataBlock_Return8:
	ret
AccVoice_SetupSlots_DataBlock_Helper15:
	ld	xix, 13201
	push	xix
	calr	Rhythm_MapChannelToDrumIndex
	pop	xix
	ld	a, (xix+c)
	ret
AccVoice_SetupSlots_DataBlock_Helper16:
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
	ld	(16:8), 32:io
	ld	xwa, 4109049408
	push	xbc
	add	xbc, 13201
	ld	xix, xbc
	pop	xbc
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	jr	z, AccVoice_SetupSlots_DataBlock_Skip17
	cp	a, 145
	jr	z, AccVoice_SetupSlots_DataBlock_Skip17
	ld	w, a
	and	w, 240
	cp	w, 208
	jr	z, AccVoice_SetupSlots_DataBlock_Skip17
	ld	(xix), a
	cp	a, 135
	jr	nz, AccVoice_SetupSlots_DataBlock_Skip16
	nop
AccVoice_SetupSlots_DataBlock_Skip16:
	jr	AccVoice_SetupSlots_DataBlock_Return9
AccVoice_SetupSlots_DataBlock_Skip17:
	ld	xwa, (xbc)
	inc	1, xwa
	ld	a, (xwa)
	ld	(xix), a
AccVoice_SetupSlots_DataBlock_Return9:
	ret
AccVoice_SetupSlots_DataBlock_Helper17:
	ld	l, 0:opc
	ld	a, 0:opc
	ld	xix, 13201
AccVoice_SetupSlots_DataBlock_Join8:
	cp	l, 2:i3
	jr	gt, AccVoice_SetupSlots_DataBlock_Skip19
	cp	a, 2:i3
	jr	gt, AccVoice_SetupSlots_DataBlock_Skip19
	; v10 does not spell this byte either
	ld	h, (xix+l)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	bit	7, h
	jr	z, AccVoice_SetupSlots_DataBlock_Helper17_Entry
	; v10 does not spell this byte either
	inc	1, l
	jr	AccVoice_SetupSlots_DataBlock_Join9
AccVoice_SetupSlots_DataBlock_Helper17_Entry:
	; v10 does not spell this byte either
	ld	w, (xix+a)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	bit	7, w
	jr	z, AccVoice_SetupSlots_DataBlock_Helper17_Skip
	; v10 does not spell this byte either
	inc	1, a
	jr	AccVoice_SetupSlots_DataBlock_Join9
AccVoice_SetupSlots_DataBlock_Helper17_Skip:
	cp	h, w
	jr	gt, AccVoice_SetupSlots_DataBlock_Skip18
	inc	1, a
	jr	AccVoice_SetupSlots_DataBlock_Join9
AccVoice_SetupSlots_DataBlock_Skip18:
	inc	1, l
	jr	AccVoice_SetupSlots_DataBlock_Join9
AccVoice_SetupSlots_DataBlock_Join9:
	jr	AccVoice_SetupSlots_DataBlock_Join8
AccVoice_SetupSlots_DataBlock_Skip19:
	cp	l, 2:i3
	jr	le, AccVoice_SetupSlots_DataBlock_Return10
	ld	l, 0:opc
AccVoice_SetupSlots_DataBlock_Return10:
	ret
AccVoice_SetupSlots_DataBlock_Helper18:
	calr	Rhythm_MapChannelToDrumIndex
	ld	ix, bc
	sll	xbc, 2
	add	xbc, 14332
AccVoice_SetupSlots_DataBlock_Helper18_Join:
	ld	xwa, (xbc)
	ld	a, (xwa)
	cp	a, 144
	jr	z, AccVoice_SetupSlots_DataBlock_Skip20
	cp	a, 145
	jr	z, AccVoice_SetupSlots_DataBlock_Skip20
	ld	e, a
	and	a, 240
	cp	a, 208
	jr	z, AccVoice_SetupSlots_DataBlock_Skip20
	jr	AccVoice_SetupSlots_DataBlock_Return11
AccVoice_SetupSlots_DataBlock_Skip20:
	ld	xwa, (xbc)
	inc	2, xwa
	ld	a, (xwa)
	calr	AccVoice_SetupSlots_DataBlock_Helper19
	cp	c, (14125:16)
	jr	z, AccVoice_SetupSlots_DataBlock_Return11
	calr	Rhythm_MapChannelToDrumIndex
	sll	xbc, 2
	add	xbc, 14332
	ld	xix, (xbc)
	push	xbc
	calr	AccVoice_SetupSlots_DataBlock_Helper18_Helper
	pop	xbc
	ld	(xbc), xix
	jr	AccVoice_SetupSlots_DataBlock_Helper18_Join
AccVoice_SetupSlots_DataBlock_Return11:
	ret
AccVoice_SetupSlots_DataBlock_Helper19:
	push_a
	calr	Rhythm_MapChannelToDrumIndex
	ld	xwa, 14309
	; v10 does not spell this byte either
	ld	e, (xwa+bc)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	push	e
	; v10 does not spell this byte either
	ld	xde, 0:i3
	pop	e
	sll	de, 7
	add	xde, AccVoice_SlotRows
	pop_a
	ld	c, (xde+a)
	ret
AccVoice_SetupSlots_DataBlock_Helper18_Helper:
	ld	a, (xix)
	calr	AccVoice_SetupSlots_DataBlock_Helper7
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
	ld (0x372d:16), 0x10
	bit 0, (0x36ff:16)
	jr nz, CmpMode_NullRet
	ld (0x372d:16), 0x20
	bit 1, (0x36ff:16)
	jr nz, CmpMode_NullRet
	ld (0x372d:16), 0x40
	bit 2, (0x36ff:16)
	jr nz, CmpMode_NullRet
	ld (0x372d:16), 0x08
	bit 3, (0x36ff:16)
	jr nz, CmpMode_NullRet
	ld (0x372d:16), 0x01
CmpMode_NullRet:
	ret

CmpMode_NullRet_Code:
	push	xiz
	call	VoiceSlot_Init_Process_Helper
	pop	xiz
	ret
VoiceSlot_Init_Process_Helper:
	ld	e, (14125:16)
	and	e, 1
	cp	e, 1:i3
	jr	z, VoiceSlot_Init_Process_Skip
	ld	e, (14125:16)
	and	e, 2
	cp	e, 2:i3
	jr	z, VoiceSlot_Init_Process_Skip2
	ld	e, (14125:16)
	and	e, 4
	cp	e, 4:i3
	jr	z, VoiceSlot_Init_Process_Skip
	ld	e, (14125:16)
	and	e, 8
	cp	e, 8
	jr	z, VoiceSlot_Init_Process_Skip3
	ld	e, (14125:16)
	and	e, 16
	cp	e, 16
	jr	z, VoiceSlot_Init_Process_Skip4
	ld	e, (14125:16)
	and	e, 32
	cp	e, 32
	jr	z, VoiceSlot_Init_Process_Skip5
	ld	e, (14125:16)
	and	e, 64
	cp	e, 64
	jr	z, VoiceSlot_Init_Process_Skip6
VoiceSlot_Init_Process_Skip:
	ld	(14620:16), 0
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip2:
	ld	(14620:16), 1
	jr	VoiceSlot_Init_Process_Return
	ld	(14620:16), 2
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip3:
	ld	(14620:16), 3
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip4:
	ld	(14620:16), 4
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip5:
	ld	(14620:16), 5
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Skip6:
	ld	(14620:16), 6
	jr	VoiceSlot_Init_Process_Return
VoiceSlot_Init_Process_Return:
	ret
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
	ld	a, (0x3431:16)
	cp	xde, 138
	jr	z, CmpMenuTtl_SetBit4
	cp	xde, 137
	jr	z, CmpMenuTtl_SetBit5
	cp	xde, 136
	jr	nz, CmpMenuTtl_ReturnZero
	and	(0x3431:16), 207
	ldw	wa, 177
	jr	CmpMenuTtl_PostModeEvent
CmpMenuTtl_SetBit5:
	and	a, 207
	set	5, a
	ld	(13361:16), a
	ldw	wa, 177
	jr	CmpMenuTtl_PostModeEvent
CmpMenuTtl_SetBit4:
	and	a, 207
	set	4, a
	ld	(13361:16), a
	ldw	wa, 177
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
	cp	(0x8c9b:16), 180
	jrl	z, CmpReal_ReturnZero
	call	CmpSetTtlFunc_Helper
	ld	xwa, 11796487
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 4294901761
	call	ApDeliveryEvent
	jrl	CmpReal_ReturnZero
	cp	(0x8c9a:16), 180
	jrl	z, CmpReal_ReturnZero
	call	RhythmConfig_InlineCode2
	jrl	CmpReal_ReturnZero
CmpSetTtl_ModeSwitch:
	cp	(0x3470:16), 0
	jrl	nz, CmpSetTtl_SecondaryDispatch
	cp	xde, 133
	jr	z, CmpSetTtl_DrumVoice1
	cp	xde, 132
	jr	z, CmpSetTtl_DrumVoice1
	cp	xde, 5
	jr	z, CmpSetTtl_DrumVoice0
	cp	xde, 4
	jr	z, CmpSetTtl_DrumVoice0
	cp	xde, 130
	jr	z, VoiceSlot_Resolve_StoreMap
	cp	xde, 129
	jr	z, VoiceSlot_Resolve_StoreMap
	cp	xde, 2
	jr	z, VoiceSlot_ResolveFromMap
	cp	xde, 1
	jrl	nz, CmpReal_ReturnZero
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
CmpSetTtl_Dispatch2_Code:
	call	16145736
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	CmpReal_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	16145736
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	62
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	16145771
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	46
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	16145771
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	CmpReal_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	16145833
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	CmpReal_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 128:opc
	call	16145833
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
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
	push XDE
	push XHL
	push XIX
	push XIZ
	ld hl, 4:i3
	call RhythmVariation_Wrapper
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	ld XWA,0x00b50019
	ld XBC,EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862043
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862042
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862040
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862044
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	CmpBk_DeliverEvent
	set	1, (0x3433:16)
	jr	CmpBk_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmMute_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 11862045
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	jr	CmpBk_DeliverEvent
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmSolo_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 11862041
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862043
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862042
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862040
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 11862044
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
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
CmpBkslSTtl_Dispatch_Code:
	call	RhythmPatInit_Wrapper
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(32422:16), 0
	jrl	DisplayFunc_ReturnZero
	ld	(13424:16), 0
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
	jrl	DisplayFunc_ReturnZero
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
	; cpdi8 (0x350c), 0 (v7 patched)
	cp	(0x3470:16), 0
	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)
	jrl	nz, DisplayFunc_ReturnZero
	push xde

	push xhl

	push xix

	push xiz

	ld hl, 4:i3

	call	RhythmFillIn_Wrapper

	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	; jrl CmpBk_PostModeChange (v7 displacement)
	jrl	CmpBk_PostModeChange
; CmpBkslSTtl fill-in level 5
CmpBkslSTtl_FillIn5:
	; cpdi8 (0x350c), 0 (v7 patched)
	cp	(0x3470:16), 0
	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)
	jrl	nz, DisplayFunc_ReturnZero
	push xde

	push xhl

	push xix

	push xiz

	ld hl, 5:i3

	; call RhythmFillIn_Wrapper (v7 addr)
	call	RhythmFillIn_Wrapper
	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	; jrl CmpBk_PostModeChange (v7 displacement)
	jrl	CmpBk_PostModeChange
; CmpBkslSTtl fill-in level 6
CmpBkslSTtl_FillIn6:
	; cpdi8 (0x350c), 0 (v7 patched)
	cp	(0x3470:16), 0
	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)
	jrl	nz, DisplayFunc_ReturnZero
	push xde

	push xhl

	push xix

	push xiz

	ld hl, 6:i3

	; call RhythmFillIn_Wrapper (v7 addr)
	call	RhythmFillIn_Wrapper
	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	; jrl CmpBk_PostModeChange (v7 displacement)
	jrl	CmpBk_PostModeChange
; CmpBkslSTtl fill-in level 7
CmpBkslSTtl_FillIn7:
	cp (0x3470:16), 0x00
	jrl nz, DisplayFunc_ReturnZero
	push XDE
	push XHL
	push XIX
	push XIZ
	ld hl, 7:i3
	call RhythmFillIn_Wrapper
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	ldw WA, 0x00b5
	jr t, CmpBk_PostModeChange
CmpBkslSTtl_FillIn8:
	cp (0x3470:16), 0x00
	jr nz, DisplayFunc_ReturnZero
	push XDE
	push XHL
	push XIX
	push XIZ
	ldw HL, 0x0008
	call RhythmFillIn_Wrapper
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	ldw WA, 0x00b5
	jr t, CmpBk_PostModeChange
	cp (0x3470:16), 0x00
	jr nz, DisplayFunc_ReturnZero
	cp	(0x340ea:24), 0
	jr	nz, CmpBkslSTtl_EventPost
	set	2, (0x3431:16)
	ld	(32422:16), 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	jr	DisplayFunc_ReturnZero
CmpBkslSTtl_EventPost:
	ld	(13424:16), 1
	ld	xwa, 11665426
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	ApPostEvent
	jr	DisplayFunc_ReturnZero
	cp	(13424:16), 0
	jr	nz, DisplayFunc_ReturnZero
	cp	(13370:16), 12
	jr	nc, DisplayFunc_ReturnZero
	ldw	wa, 179
	jr	CmpBk_PostModeChange
	cp	(13424:16), 0
	jr	nz, DisplayFunc_ReturnZero
	ldw	wa, 180
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
CmpNcpTtl_Dispatch_Code:
	call	16142625
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (14820:16)
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
	call	16142746
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	CmEsy_ReturnZero
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16142625
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (14820:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip2
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	jr	CmpNcpTtl_Dispatch_Code_Join
CmpNcpTtl_Dispatch_Code_Skip2:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 6:i3
	call	UI_PostDialValueEvent
	ldw	wa, 134
CmpNcpTtl_Dispatch_Code_Join:
	call	UI_PostDialRangeEvent
	jrl	CmEsy_ReturnZero
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 297 of 450 slots byte-identical
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	16142764
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 0
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip3
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058650
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
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	; v10 does not spell this byte either
	push	xde
	; v10 does not spell this byte either
	push	xhl
	; v10 does not spell this byte either
	push	xix
	; v10 does not spell this byte either
	push	xiz
	; v10 does not spell this byte either
	ld	w, 128:opc
	; v10 does not spell this byte either
	call	16142764
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 0
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip4
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058650
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
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	; v10 does not spell this byte either
	call	UI_PostEvent_0x6E
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	push	xde
	; v10 does not spell this byte either
	push	xhl
	; v10 does not spell this byte either
	push	xix
	; v10 does not spell this byte either
	push	xiz
	; v10 does not spell this byte either
	ld	w, 0:opc
	; v10 does not spell this byte either
	call	16142799
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 0
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip5
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip5:
	ld	a, (14603:16)
	cp	a, 2:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip7
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip6
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip6:
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip7:
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	; v10 does not spell this byte either
	push	xde
	; v10 does not spell this byte either
	push	xhl
	; v10 does not spell this byte either
	push	xix
	; v10 does not spell this byte either
	push	xiz
	; v10 does not spell this byte either
	ld	w, 128:opc
	; v10 does not spell this byte either
	call	16142799
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 0
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip8
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
CmpNcpTtl_Dispatch_Code_Skip8:
	ld	a, (14603:16)
	cp	a, 2:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip10
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip9
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip9:
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip10:
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	w, 0:opc
	call	16142834
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 1
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip13
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
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
	ld	xwa, 12058650
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	.byte 0x3a	; v10 does not spell this byte either
	.byte 0x3b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x3e	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x80	; v10 does not spell this byte either
	call	16142834
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 1
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip14
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
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
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058650
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
	call	16142869
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 1
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip15
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
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
	ld	a, (14604:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip11
	cp	a, 0:i3
	jrl	nz, CmEsy_ReturnZero
	ld	xwa, 12058650
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip11:
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	CmpNcpTtl_Dispatch_Code_Join2
	ld	wa, 1:i3
	; v10 does not spell this byte either
	call	UI_PostEvent_0x6E
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	push	xde
	; v10 does not spell this byte either
	push	xhl
	; v10 does not spell this byte either
	push	xix
	; v10 does not spell this byte either
	push	xiz
	; v10 does not spell this byte either
	ld	w, 128:opc
	; v10 does not spell this byte either
	call	16142869
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	; v10 does not spell this byte either
	cp	(0x39e4:16), 1
	; v10 does not spell this byte either
	jr	z, CmpNcpTtl_Dispatch_Code_Skip16
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
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
	ld	a, (14604:16)
	cp	a, 1:i3
	jr	z, CmpNcpTtl_Dispatch_Code_Skip12
	cp	a, 0:i3
	jr	nz, CmEsy_ReturnZero
	ld	xwa, 12058650
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jr	CmpNcpTtl_Dispatch_Code_Join2
CmpNcpTtl_Dispatch_Code_Skip12:
	ld	xwa, 12058651
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
CmpNcpTtl_Dispatch_Code_Join2:
	call	ApDeliveryEvent
	jr	CmEsy_ReturnZero
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0x35	; v10 does not spell this byte either
	.byte 0x34	; v10 does not spell this byte either
	.byte 0xb8	; v10 does not spell this byte either
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
CmEsyTtl_Dispatch:
	cp	(35995:16), 186
	jrl	z, S2cTtl_ReturnZero
	ld	a, (13370:16)
	cp	a, 29
	jr	ule, CmEsyTtlFunc_Entry
	sub	a, 30
	sll	a, 2
	ld	(13370:16), a
CmEsyTtlFunc_Entry:
	or	(0x372c:16), 127
	res	2, (0x28a7:16)
	res	6, (0x3431:16)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	DrumKit_UpdateStatusFlags_Sub
	call	DrumKit_ValidateBank_Wrap
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(13397:16), 0
	ld	xwa, 12189706
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 4294901762
	jrl	CmpEsy_DeliverEventAndCheck
	cp	(14109:16), 255
	jrl	z, S2cTtl_ReturnZero
	lda	xiy, (14109:16)
	lda	xix, (14095:16)
	lda	xhl, (14116:16)
	lda	xde, (14102:16)
	ld	xbc, 0:i3
CmEsyTtlFunc_Loop:
	ld	a, (xiy+)
	ld	(xix+), a
	ld	a, (xhl+)
	ld	(xde+), a
	inc	1, xbc
	cp	xbc, 7
	jr	c, CmEsyTtlFunc_Loop
	ldmm8	13370, 14123
	jrl	S2cTtl_ReturnZero
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
	call	ApDeliveryEvent
	jr	S2cTtl_ReturnZero
	cp	(14124:16), 0
	jr	z, CmpEsyTtl_SubModeC
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ExtVoice_ProcessList_0x1C
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(32422:16), 0
	jr	nz, CmpEsyTtl_SubModeD
	lda	xiy, (14095:16)
	lda	xix, (14109:16)
	lda	xhl, (14102:16)
	lda	xde, (14116:16)
	ld	xbc, 0:i3
CmpEsyTtl_SubModeB:
	ld	a, (xiy+)
	ld	(xix+), a
	ld	a, (xhl+)
	ld	(xde+), a
	inc	1, xbc
	cp	xbc, 7
	jr	c, CmpEsyTtl_SubModeB
	ldmm8	14123, 13370
	jr	CmpEsyTtl_SubModeD
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 23 of 34 slots byte-identical
	; differs from v10 here and llvm-objdump cannot read it
	cp	(0x8c9b:16), 185
	jr	z, S2cTtl_Dispatch_Code_Skip
	ld	xwa, 12124193
	ld	xbc, EVT_SET_SELECTED_CEL
	ld	xde, 4294901762
	call	ApDeliveryEvent
S2cTtl_Dispatch_Code_Skip:
	call	16145895
	jrl	CstmCp_ReturnZero
	ld	a, (14811:16)
	cp	a, 2:i3
	jr	z, S2cTtl_Dispatch_Code_Skip3
	cp	a, 1:i3
	jr	z, S2cTtl_Dispatch_Code_Skip2
	cp	a, 0:i3
	jrl	nz, CstmCp_ReturnZero
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 0:i3
	call	UI_PostDialValueEvent
	ldw	wa, 128
	jr	S2cTtl_Dispatch_Code_Join
S2cTtl_Dispatch_Code_Skip2:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 1:i3
	call	UI_PostDialValueEvent
	ldw	wa, 129
	jr	S2cTtl_Dispatch_Code_Join
S2cTtl_Dispatch_Code_Skip3:
	ld	wa, 1:i3
	call	UI_PostDialEnable
	ld	wa, 2:i3
	call	UI_PostDialValueEvent
	ldw	wa, 130
S2cTtl_Dispatch_Code_Join:
	call	UI_PostDialRangeEvent
	jrl	CstmCp_ReturnZero
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 26 of 37 slots byte-identical
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
	; differs from v10 here and llvm-objdump cannot read it
	cp	(0x39db:16), 0
	jr	nz, S2cTtl_Dispatch_Code_Skip4
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn
S2cTtl_Dispatch_Code_Skip4:
	ld	(14811:16), 0
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124193
	ld	xbc, EVT_CLR_GRID_HANTEN
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn
CmpEsyTtl_E_Var2:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 0:i3
	call UI_PostDialValueEvent
	ldw WA, 0x0080
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustStartMeasure
	cp (0x39db:16), 0x00
	jr nz, .Lc_f68b9c
	ld XWA,0x00b9001c
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b9001f
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_E_Var2_StoreMeasure:
.Lc_f68b9c:
	ld (0x39db:16), 0x00
	ld XWA,0x00b9001c
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b9001f
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b90018
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b90021
	ld XBC,EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 1:i3
	call UI_PostDialValueEvent
	ldw WA, 0x0081
	call UI_PostDialRangeEvent
	ld wa, 0:i3
	call Tempo_AdjustEndMeasure
	cp (0x39db:16), 0x01
	jr nz, CmpEsy_E_EndMeasure_Store
	ld XWA,0x00b9001f
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_E_EndMeasure_Store:
	ld	(14811:16), 1
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124193
	ld	xbc, EVT_CLR_GRID_HANTEN
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn
S2cTtl_MainHandler:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 1:i3
	call UI_PostDialValueEvent
	ldw WA, 0x0081
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustEndMeasure
	cp (0x39db:16), 0x01
	jr nz, .Lc_f68cae
	ld XWA,0x00b9001f
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_Main_EndMeasure_Store:
.Lc_f68cae:
	ld (0x39db:16), 0x01
	ld XWA,0x00b9001f
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b90018
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	call ApDeliveryEvent
	ld XWA,0x00b90021
	ld XBC,EVT_CLR_GRID_HANTEN
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 2:i3
	call UI_PostDialValueEvent
	ldw WA, 0x0082
	call UI_PostDialRangeEvent
	ld wa, 0:i3
	call Tempo_AdjustQuantize
	cp (0x39db:16), 0x02
	jr nz, CmpEsy_Quantize_Store
	ld XWA,0x00b90018
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_Quantize_Store:
	ld	(14811:16), 2
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124193
	ld	xbc, EVT_CLR_GRID_HANTEN
	ld	xde, 0:i3
	jrl	TtlFunc_SendEventAndReturn
S2cTtl_SecondaryHandler:
	ld wa, 1:i3
	call UI_PostEvent_0x6E
	ld wa, 1:i3
	call UI_PostDialEnable
	ld wa, 2:i3
	call UI_PostDialValueEvent
	ldw WA, 0x0082
	call UI_PostDialRangeEvent
	ld wa, 1:i3
	call Tempo_AdjustQuantize
	cp (0x39db:16), 0x02
	jr nz, CmpEsy_SecQuantize_Store
	ld XWA,0x00b90018
	ld XBC,EVT_REPAINT
	ld xde, 0:i3
	jr t, TtlFunc_SendEventAndReturn
CmpEsy_SecQuantize_Store:
	ld	(14811:16), 2
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124193
	ld	xbc, EVT_CLR_GRID_HANTEN
	ld	xde, 0:i3
	jr	TtlFunc_SendEventAndReturn
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, 0:i3
	call	Tempo_IncrementTimeSigNum
	ld	xwa, 12124190
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jr	TtlFunc_SendEventAndReturn
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, 0:i3
	call	Tempo_DecrementTimeSigNum
	ld	xwa, 12124190
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
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
	; cpdi8	(0x8d37), 190 (v7 patched)
	cp	(0x8c9b:16), 190
	jr	z, CstmCpTtl_Dispatch_Code_Entry

	; stdi8	(0x3a7e), 0 (v7 patched)
	ld	(0x39e2:16), 0
	jrl	CstmCp_ReturnZero2

CstmCpTtl_Dispatch_Code_Entry:
	; cpdi8	(0x8d39), 238 (v7 patched)
	cp	(0x8c9d:16), 238
	jrl	nz, CstmCp_ReturnZero2

	ld a, (14818:16)

	cp	a, 2:i3

	jr	z, CstmCpTtl_Dispatch_Code_Entry2

	cp	a, 1:i3

	jrl	nz, CstmCp_ReturnZero2

CstmCpTtl_Dispatch_Code_Entry2:
	; cpdi8	(0x39b6), 3 (v7 patched)
	cp	(0x391a:16), 3
	jr	nc, CstmCpTtl_Dispatch_Code_Skip

	ld	xwa, 0xbe0011

	ld	xbc, EVT_SHOW

	ld	xde, 5:i3

	jrl	CstmCpTtl_Dispatch2_Code_Join

CstmCpTtl_Dispatch_Code_Skip:
	ld	xwa, 0xbe0019

	ld	xbc, EVT_SHOW

	ld	xde, 5:i3

	jrl	CstmCpTtl_Dispatch2_Code_Join

	ld a, (14818:16)

	cp	a, 2:i3

	jr	z, CstmCpTtl_Dispatch_Code_Entry3

	cp	a, 1:i3

	jrl	nz, CstmCp_ReturnZero2

CstmCpTtl_Dispatch_Code_Entry3:
	; cpdi8	(0x39b6), 3 (v7 patched)
	cp	(0x391a:16), 3
	jr	nc, CstmCpTtl_Dispatch_Code_Skip2

	ld	xwa, 0xbe0011

	ld	xbc, EVT_SHOW

	ld	xde, 5:i3

	jrl	CstmCpTtl_Dispatch2_Code_Join

CstmCpTtl_Dispatch_Code_Skip2:
	ld	xwa, 0xbe0019

	ld	xbc, EVT_SHOW

	ld	xde, 5:i3

	jrl	t, CstmCpTtl_Dispatch2_Code_Join



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
	cp	(0x39e2:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 29:opc
	ld	a, (0x391a:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip
	ld	c, 2:opc
CstmCpTtlFunc_Skip:
	cp	a, c
	jrl	nc, CstmCp_ReturnZero2
	inc	1, a
	ld	(0x391a:16), a
	ld	xwa, 12451843
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451844
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x39e2:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 10:opc
	ld	a, (0x391a:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip2
	ld	c, 0:opc
CstmCpTtlFunc_Skip2:
	cp	a, c
	jrl	ule, CstmCp_ReturnZero2
	dec	1, a
	ld	(0x391a:16), a
	ld	xwa, 12451843
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451844
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x39e2:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	a, (0x391a:16)
	ld	c, (0x391b:16)
	ld	(0x391a:16), c
	ld	(0x391b:16), a
	ld	xwa, 12451843
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451851
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451853
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451854
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451844
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451855
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jrl	CstmCpTtlFunc_Join
	cp	(0x39e2:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 29:opc
	ld	a, (0x391b:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip3
	ld	c, 2:opc
CstmCpTtlFunc_Skip3:
	cp	a, c
	jrl	nc, CstmCp_ReturnZero2
	inc	1, a
	ld	(0x391b:16), a
	ld	xwa, 12451851
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451855
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
	jr	CstmCpTtlFunc_Join
	cp	(0x39e2:16), 0
	jrl	nz, CstmCp_ReturnZero2
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	c, 10:opc
	ld	a, (0x391b:16)
	cp	a, 10
	jr	nc, CstmCpTtlFunc_Skip4
	ld	c, 0:opc
CstmCpTtlFunc_Skip4:
	cp	a, c
	jrl	ule, CstmCp_ReturnZero2
	dec	1, a
	ld	(0x391b:16), a
	ld	xwa, 12451851
	ld	xbc, EVT_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12451855
	ld	xbc, EVT_DRAW
	ld	xde, 0:i3
CstmCpTtlFunc_Join:
	call	ApDeliveryEvent
	jrl	CstmCp_ReturnZero2
	ld	a, (0x39e2:16)
	cp	a, 2:i3
	jr	z, CstmCpTtlFunc_Skip5
	cp	a, 1:i3
	jrl	nz, CstmCp_ReturnZero2
CstmCpTtlFunc_Skip5:
	ld	wa, 0:i3
	call	CstmCpTtlFunc_Helper
	cp	l, 1:i3
	jrl	z, CstmCp_ReturnZero2
	cp	l, 0:i3
	jrl	nz, CstmCp_ReturnZero2
	ld	(0x39e2:16), 0
	ld	xwa, 4294967295
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(0x7ea6:16), 35
	ldw	wa, 238
	jrl	CstmCpTtlFunc_Join2
	ld	a, (0x39e2:16)
	cp	a, 2:i3
	jrl	z, CstmCpTtlFunc_Skip10
	cp	a, 1:i3
	jr	z, CstmCpTtlFunc_Skip10
	cp	a, 0:i3
	jrl	nz, CstmCp_ReturnZero2
	cp	(0x391a:16), 3
	jr	nc, CstmCpTtlFunc_Skip6
	ld	(0x7ea6:16), 37
	ldw	wa, 238
	call	SoundCtrl_SendCommand
CstmCpTtlFunc_Skip6:
	ld	a, (0x391a:16)
	extz	wa
	ld	c, (0x391b:16)
	extz	bc
	call	Flash_InitBytecodeBlock
	cp	l, 2:i3
	jr	z, CstmCpTtlFunc_Skip8
	cp	l, 1:i3
	jr	z, CstmCpTtlFunc_Skip7
	cp	l, 0:i3
	jr	nz, CstmCp_ReturnZero2
	ld	(0x7ea6:16), 35
	ldw	wa, 238
	jr	CstmCpTtlFunc_Join2
CstmCpTtlFunc_Skip7:
	ld	(0x7ea6:16), 15
	ldw	wa, 238
	jr	CstmCpTtlFunc_Join2
CstmCpTtlFunc_Skip8:
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_EXIT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(0x391a:16), 3
	jr	nc, CstmCpTtlFunc_Skip9
	ld	(0x39e2:16), 1
	jr	CstmCp_ReturnZero2
CstmCpTtlFunc_Skip9:
	ld	(0x39e2:16), 2
	ld	xwa, 12451865
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
CstmCpTtl_Dispatch2_Code_Join:
	call ApPostEvent
	jr t, CstmCp_ReturnZero2
CstmCpTtlFunc_Skip10:
	ld wa, 2:i3
	call CstmCpTtlFunc_Helper
	cp l, 1:i3
	jr z, CstmCp_ReturnZero2
	cp l, 0:i3
	jr nz, CstmCp_ReturnZero2
	ld (0x39e2:16), 0x00
	ld XWA,0xffffffff
	ld XBC,EVT_HIDE
	ld xde, 0:i3
	call ApPostEvent
	ld (0x7ea6:16), 0x23
	ldw WA, 0x00ee
CstmCpTtlFunc_Join2:
	call SoundCtrl_SendCommand
CstmCp_ReturnZero2:
	ld xhl, 0:i3
	ret

CstmCp_StyleDataBlock:
	cp	xbc, EVT_CSTM_CP_OK
	jr	nz, CstmCpTtl_Dispatch2_Code_Skip
	ld	a, (14618:16)
	extz	wa
	ld	c, (14619:16)
	extz	bc
	call	Flash_InitBytecodeBlock
	cp	l, 2:i3
	jr	z, CstmCpTtl_Dispatch2_Code_Skip
	cp	l, 1:i3
	jr	z, CstmCpTtl_Dispatch2_Code_Skip
	cp	l, 0:i3
	jr	nz, CstmCpTtl_Dispatch2_Code_Skip
	ld	(32422:16), 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand
CstmCpTtl_Dispatch2_Code_Skip:
	ld	xhl, 0:i3
	ret

MainCstmNameFunc:
	lda	xsp, (xsp-120)
	push	xiz
	ld	xde, xbc
	ld	xiy, MainCstmNameFunc_LocalInit
	lda	xix, (xsp+4)
	ldw	bc, 60
	ldirw
	cp	xde, EVT_CSTM_T_NM_GET
	jr	z, CstmName_HandleEvent2C
	cp	xde, EVT_CSTM_F_NM_GET
	jrl	nz, CstmName_ReturnZero
	pushw	17
	call	Malloc
	ld	xiz, xhl
	ld	a, (0x391a:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (xsp+6)
	ld	xwa, (xbc+wa)
	add	xwa, 64
	pushw	13
	push	xwa
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+12)
	ld	(xiz+13), 0
	ld	(xiz+14), 0
	ld	(xiz+15), 0
	ld	(xiz+16), 0
	ld	xwa, 12451844
	ld	xbc, EVT_CSTM_F_NM_DISP
	ld	xde, xiz
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	jr	CstmName_PostEventAndReturn
CstmName_HandleEvent2C:
	pushw 0x11

	call	Malloc

	ld xiz, xhl

	ld a, (14619:16)

	extz wa

	sla wa, 2

	lda xbc, (xsp + 6)

	ld	xwa, (xbc+wa)

	add xwa, 0x40

	pushw 0xd

	push xwa

	push xiz

	call	Mem_Copy

	lda xsp, (xsp + 12)

	ld (xiz + 13), 0x0

	ld (xiz + 14), 0x0

	ld (xiz + 15), 0x0

	ld (xiz + 16), 0x0

	ld xwa, 0xbe000f

	ld xbc, EVT_CSTM_T_NM_DISP

	ld xde, xiz

	; call ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
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
	dec	4, xsp
	ld	(xsp), xde
	ld	xwa, (xsp)
	dec	2, a
	cp	xbc, EVT_S2C_TR_DN
	jr	z, S2cFunc_HandleEvent11
	cp	xbc, EVT_S2C_TR_UP
	jrl	nz, EventDelivery_ReturnZero
	ld	(0x38f4:16), a
	ld	wa, 0:i3
	call	Tempo_AdjustEffect
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 12124193
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	ApDeliveryEvent
	cp	(0x39db:16), 3
	jrl	z, EventDelivery_ReturnZero
	ld	(0x39db:16), 3
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	jr	S2cFunc_DeliverAndReturn
S2cFunc_HandleEvent11:
	ld	(0x38f4:16), a
	ld	wa, 1:i3
	call	Tempo_AdjustEffect
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 12124193
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	ApDeliveryEvent
	cp	(0x39db:16), 3
	jr	z, EventDelivery_ReturnZero
	ld	(0x39db:16), 3
	ld	xwa, 12124188
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ld	xwa, 12124184
	ld	xbc, EVT_REPAINT
	ld	xde, 0:i3
S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MiddleNameFunc:
	lda	xwa, (13344:16)
	cp	xbc, EVT_MSP_NAME_SET
	jr	z, MiddleName_HandleEvent01
	cp	xbc, EVT_CMP_NAME_SET
	jr	nz, MiddleName_ReturnZero
	push	xde
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	RhythmProc_CopySlotData_Wrap
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldw	wa, 178
	jr	MiddleName_PostModeChange
MiddleName_HandleEvent01:
	push	xde
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	c, (32418:16)
	ld	a, c
	sll	a, 4
	cp	c, 2:i3
	jr	nc, MiddleName_CalcROMAddr_High
	ld	w, 0:opc
	extz	xwa
	add	xwa, 2001536
	jr	MiddleName_CopyAndPost
MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x1e8a40

MiddleName_CopyAndPost:
	pushw	16
	pushw	0
	pushw	13344
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ldw	wa, 202
MiddleName_PostModeChange:
	call UI_PostModeChangeEvent

MiddleName_ReturnZero:
	ld xhl, 0:i3
	ret

MiddleCmpClrFunc:
	cp	xbc, EVT_CMP_CLR_NO
	jr	z, MiddleCmpClr_HandleEvent07
	cp	xbc, EVT_CMP_CLR_YES
	jr	nz, MiddleCmpClr_ReturnZero
	set	2, (0x3431:16)
	ld	(0x3470:16), 0
	ld	xwa, 11665426
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(0x7ea6:16), 35
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	jr	MiddleCmpClr_ReturnZero
MiddleCmpClr_HandleEvent07:
	ld	(13424:16), 0
	ld	xwa, 11665426
	ld	xbc, EVT_HIDE
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 11665408
	ld	xbc, EVT_ALL_PAINT
	ld	xde, 0:i3
	call	ApDeliveryEvent
MiddleCmpClr_ReturnZero:
	ld xhl, 0:i3
	ret
MainCmpCpFunc:
	lda	xsp, (xsp-18)
	push	xiz
	ld	xde, xbc
	ld	xiy, MainCmpCpFunc_LocalInit
	lda	xix, (xsp+10)
	ld	bc, 6:i3
	ldirw
	cp	xde, EVT_RHY_VARI_NM_GET
	jr	z, MainCmpCp_HandleEvent03
	cp	xde, EVT_RHY_GRP_NM_GET
	jrl	nz, MainCmpSet_Case4
	pushw 17
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(xsp+7), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	ld	a, (xsp+4)
	extz	wa
	call	AccVoice_CopyFromROM_Wrap
	extz	xhl
	pushw 16
	push	xhl
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xiz+16), 0
	ld	xwa, 12058654
	ld	xbc, EVT_AP_RHY_GRP_NM
	ld	xde, xiz
	call	ApDeliveryEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	jrl	MainCmpSet_Case3
MainCmpCp_HandleEvent03:
	pushw 15
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(xsp+7), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	AccVoice_DispatchWithChannel
	extz	xhl
	cp	(35996:16), 184
	jr	nz, MemCopy_SetupParams
	lda	xbc, (xsp+4)
	ld	a, (xbc+3)
	cp	a, 128
	jr	c, MemCopy_SetupParams
	cp	(xbc+4), 0
	jr	nz, MemCopy_SetupParams
	res	7, a
	cp	a, 4:i3
	jr	nc, MainCmpCp_ClampRange4
	ld	a, 0:opc
	jr	MainCmpCp_StoreClampResult
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
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xiz+13), 0
	ld	a, (35996:16)
	cp	a, 184
	jr	nz, MainCmpSet_Init
	ld	xwa, 12058655
	ld	xbc, EVT_AP_RHY_VARI_NM
	ld	xde, xiz
	jr	MainCmpSet_Case1
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
	dec	4, xsp
	ld	(xsp), xde
	ld	a, (0x343a:16)
	extz	wa
	sla	wa, 2
	lda	xde, (RhythmTiming_OffsetTable:24)
	ld	xhl, 608352
	add	xhl, (xde+wa)
	ld	xde, xhl
	ld	xhl, xbc
	ld	xwa, (xsp)
	ld	c, a
	sub	xhl, EVT_PAN_UP
	cp	xhl, 0
	jrl	lt, CmpSong_VariantA
	cp	xhl, 7
	jrl	gt, CmpSong_VariantA
	add	xhl, xhl
	add	xhl, MainCmpSetFunc_CaseTable
	ld	hl, (xhl)
	lda	xix, (MainCmpSet_Dispatch:24)
	jp	t, (xix+hl)
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
	add	xde, 65536
	ld	xwa, 11796494
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Code_Join
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
	add	xde, 65536
	ld	xwa, 11796494
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Code_Join
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
	add	xde, 131072
	ld	xwa, 11796494
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MainCmpSetFunc_Code_Join
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
	add	xde, 131072
	ld	xwa, 11796494
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MainCmpSetFunc_Code_Join
	ld	a, c
	ld	(13476:16), c
	cp	c, 2:i3
	jr	ule, MainCmpSetFunc_Code_Skip
	dec	2, a
	ld	(13476:16), a
MainCmpSetFunc_Code_Skip:
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
	add	xde, 65536
	ld	xwa, 11796487
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MainCmpSetFunc_Code_Join
	ld	a, c
	ld	(13476:16), c
	cp	c, 2:i3
	jr	ule, MainCmpSetFunc_Code_Skip2
	dec	2, a
	ld	(13476:16), a
MainCmpSetFunc_Code_Skip2:
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
	add	xde, 65536
	ld	xwa, 11796487
	ld	xbc, EVT_REQUEST_GRID_DRAW
MainCmpSetFunc_Code_Join:
	call	ApDeliveryEvent
CmpSong_VariantA:
	ld xhl, 0:i3
	inc 4, xsp
	ret

MainEsCmpFunc:
	dec	4, xsp
	ld	(xsp), xde
	ld	xde, (xsp)
	ld	a, e
	dec	2, a
	cp	xbc, EVT_ES_CMP_VARI_DN
	jrl	z, EsCmp_HandleEvent2A
	cp	xbc, EVT_ES_CMP_VARI_UP
	jrl	z, EsCmp_HandleEvent29
	cp	xbc, EVT_ES_CMP_STYL_DN
	jr	z, EsCmp_HandleEvent28
	cp	xbc, EVT_ES_CMP_STYL_UP
	jrl	nz, EsCmp_ReturnZero
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	a, 0:opc
	call	DrumParam_ProcessChannel
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	wa, de
	extz	xde
	add	xde, 65536
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	ApDeliveryEvent
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jrl	MspBksl_EventDeliver
EsCmp_HandleEvent28:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	a, 128:opc
	call	DrumParam_ProcessChannel
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	ApDeliveryEvent
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MspBksl_EventDeliver
EsCmp_HandleEvent29:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	a, 0:opc
	call	DrumParam_ProcessChannelAlt
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	MspBksl_EventDeliver
EsCmp_HandleEvent2A:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	a, 128:opc
	call	DrumParam_ProcessChannelAlt
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, EVT_REQUEST_GRID_DRAW
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
	; cpdi8 (0x8d38), 181 (v7 patched)
	cp	(0x8c9c:16), 181
	ret nz

	ld xwa, 0xb5001e

	ld xbc, EVT_PAINT

	ld xde, 0:i3

	; call ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
	ret



SoundCtrl_SendTempoScaled:
	; cpdi8 (0x8d38), 181 (v7 patched)
	cp	(0x8c9c:16), 181
	ret nz

	calr SoundCtrl_CalcScaledTempo

	ld xwa, 0xb50002

	ld xbc, EVT_PAINT

	ld xde, 0:i3

	; call ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
	ret



SoundCtrl_CalcScaledTempo:
	ld	xhl, 100
	ld	bc, (13368:16)
	extz	xbc
	ld	xwa, xhl
	call	Math_MultiplyAccumulate
	ld	xwa, xhl
	ld	xbc, 190
	call	Math_DivideU32
	cp	xhl, 99
	jr	ule, SoundCtrl_CalcTempo_Clamp
	ld	xhl, 99
SoundCtrl_CalcTempo_Clamp:
	ld	(14607:16), l
	ret
AccGuard_ProgramChangeCheck:
	ld	c, (49122:16)
	ld	a, (49121:16)
	cp	a, 5:i3
	jr	nz, AccGuard_CheckMode09
	cp	(49123:16), 0
	jr	z, AccGuard_CheckMode09
	cp	c, 2:i3
	ret	nz
	jr	AccGuard_SendProgramChange
AccGuard_CheckMode09:
	cp a, 0x09

	ret nz

	.byte 0xc1, 0xe3, 0xbf, 0x3f, 0x00	; cpdi8	(0xc07f), 0 (v7 patched)

	ret z

	cp c, 0x40

	ret nz

	ld a, (35994:16)

	cp a, 0xcb

	ret z

	cp a, 0xcc

	ret z

	ldw wa, 0x00c8

	call	SoundCtrl_SendCommand

	ret

AccGuard_SendProgramChange:
	ld	xwa, 163968
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	ret	z
	ldw	wa, 237
	call	SoundCtrl_SendCommand
	ret
AccSeq_DeliverC9_0009:
	; cpdi8 (0x8d38), 201 (v7 patched)
	cp	(0x8c9c:16), 201
	ret nz

	ld xwa, 0xc90009

	ld xbc, EVT_PAINT

	ld xde, 0:i3

	; call ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
	ret



AccSeq_DeliverC9_000A:
	; cpdi8 (0x8d38), 201 (v7 patched)
	cp	(0x8c9c:16), 201
	ret nz

	ld xwa, 0xc9000a

	ld xbc, EVT_PAINT

	ld xde, 0:i3

	; call ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
	ret


MainMspRgpSetFunc:
	ld	a, (0x7ea1:16)
	sll	a, 4
	ld	w, 0:opc
	extz	xwa
	add	xwa, 2001408
	ld	xiy, xwa
	ld	ix, de
	extz	xix
	ld	xhl, xix
	add	xhl, 65536
	ld	xwa, xde
	add	xwa, xwa
	ld	xde, xix
	add	xde, 131072
	dec	4, xwa
	ld	xix, xwa
	add	xix, xiy
	lda	xwa, (xix+1)
	cp	xbc, EVT_RGP_PAD_DN
	jr	z, MspMenuTtl_Case1
	cp	xbc, EVT_RGP_PAD_UP
	jr	z, MspMenuTtl_Init
	cp	xbc, EVT_RGP_BNK_DN
	jr	z, MspRgpSet_HandleEvent13
	cp	xbc, EVT_RGP_BNK_UP
	jrl	nz, AccBass_ReturnZero
	cp	(0x7e6f:16), 0
	jr	nz, AccBass_ReturnZero
	ld	xbc, xix
	ld	a, (xix)
	cp	a, 14
	jr	nc, AccBass_ReturnZero
	inc	1, a
	ld	(xbc), a
	ld	xwa, 13369347
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xhl
	jr	AccBass_EventDeliver
MspRgpSet_HandleEvent13:
	cp	(0x7e6f:16), 0
	jr	nz, AccBass_ReturnZero
	ld	xbc, xix
	ld	a, (xix)
	cp	a, 0:i3
	jr	z, AccBass_ReturnZero
	dec	1, a
	ld	(xbc), a
	ld	xwa, 13369347
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xhl
	jr	AccBass_EventDeliver
MspMenuTtl_Init:
	cp	(0x7e6f:16), 0
	jr	nz, AccBass_ReturnZero
	ld	xbc, xwa
	ld	a, (xwa)
	cp	a, 5:i3
	jr	nc, AccBass_ReturnZero
	inc	1, a
	ld	(xbc), a
	ld	xwa, 13369347
	ld	xbc, EVT_REQUEST_GRID_DRAW
	jr	AccBass_EventDeliver
MspMenuTtl_Case1:
	cp	(0x7e6f:16), 0
	jr	nz, AccBass_ReturnZero
	ld	xbc, xwa
	ld	a, (xwa)
	cp	a, 0:i3
	jr	z, AccBass_ReturnZero
	dec	1, a
	ld	(xbc), a
	ld	xwa, 13369347
	ld	xbc, EVT_REQUEST_GRID_DRAW
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
	ld	xwa, 165888
	call	AcApcToggleProc_Helper
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
	ld	(32418:16), l
	ld	a, l
	sll	a, 4
	cp	l, 2:i3
	jr	nc, MspMenuTtlFunc_Skip3
	ld	w, 0:opc
	extz	xwa
	add	xwa, 2001536
	jr	MspMenuTtlFunc_Join2
MspMenuTtlFunc_Skip3:
	sub	a, 32
	ld	w, 0:opc
	extz	xwa
	add	xwa, 2001472
MspMenuTtlFunc_Join2:
	pushw	16
	push	xwa
	pushw	0
	pushw	13344
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	(13360:16), 0
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
	; cpdi8	(0x8d37), 203 (v7 patched)
	cp	(0x8c9b:16), 203
	jr	z, MspNameTtl_Dispatch_Code_Entry

	ld c, (32418:16)

	add	c, 13

	extz	bc

	ld	xwa, 0x028800

	ld	de, 0:i3

	; call	SoundParam_NotifyChange (v7 addr)
	call	Audio_ResetAfterPayloadError_Helper
MspNameTtl_Dispatch_Code_Entry:
	; cpdi8	(0x8d37), 204 (v7 patched)
	cp	(0x8c9b:16), 204
	jr	z, MspRecMode_ReturnZero

	ld	xwa, 0xcc0003

	ld	xbc, EVT_SET_SELECTED_CEL

	ld	xde, 0xffff0002

	; call	ApDeliveryEvent (v7 addr)
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
	ld	(32367:16), 0
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 21 of 30 slots byte-identical
	; differs from v10 here and llvm-objdump cannot read it
	cp	(0x8c9b:16), 201
	jr	z, MspRecTtl_Dispatch_Code_Skip2
	ld	xwa, 164099
	ld	bc, 0:i3
	ld	de, 3:i3
	call	Audio_ResetAfterPayloadError_Helper
	ld	xwa, 165888
	call	AcApcToggleProc_Helper
	cp	l, 13
	jr	z, MspRecTtl_Dispatch_Code_Skip
	cp	l, 14
	jr	nz, MspRecTtl_Dispatch_Code_Skip2
MspRecTtl_Dispatch_Code_Skip:
	ld	a, (32376:16)
	sll	a, 4
	ld	w, 0:opc
	extz	xwa
	add	xwa, 2000928
	ld	a, (xwa)
	and	a, 16
	srl	a, 4
	ld	(32419:16), a
MspRecTtl_Dispatch_Code_Skip2:
	ld	wa, 0:i3
	call	UI_PostDialEnable
	jr	MspRecTtl_ReturnZero
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0xc9	; differs from v10 here and llvm-objdump cannot read it
	jr	z, MspRecTtl_ReturnZero
	; differs from v10 here and llvm-objdump cannot read it
	cp	(0x7e6f:16), 0
	jr	z, MspRecTtl_ReturnZero
	ld	(32367:16), 0
	jr	MspRecTtl_ReturnZero
MspRecTtl_SubA:
	ld	xwa, 165888
	call	AcApcToggleProc_Helper
	cp	l, 13
	jr	z, MspRecTtl_SubA_CheckRange
	cp	l, 14
	jr	nz, MspRecTtl_ReturnZero
MspRecTtl_SubA_CheckRange:
	ld a, (32376:16)

	sll a, 4

	ld w, 0x0:opc

	extz xwa

	add xwa, 0x1e8820

	ld c, (32419:16)

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
	.byte 0xc1, 0x9c
AccSeq_DcModeDataBlock_Code:
	xor	(xix+63), d
	ret	nz
	ld	xwa, 14417925
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ret	
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
	; cpdi8	(0x8d37), 220 (v7 patched)
	cp	(0x8c9b:16), 220
	jr	z, SndArgTtl_Dispatch_Code_Skip

	ld	xwa, 0xdc0005

	ld	xbc, EVT_SET_SELECTED_CEL

	ld	xde, 0xffff0002

	; call	ApDeliveryEvent (v7 addr)
	call	ApDeliveryEvent
SndArgTtl_Dispatch_Code_Skip:
	push	xde

	push	xhl

	push	xix

	push	xiz

	; call	AccStyle_InlinedBlock (v7 addr)
	call	AccStyle_InlinedBlock
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
SndArgTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SndArgNmGet:
	lda	xsp, (xsp-76)
	push	qiz
	ld	(xsp+70), xde
	ld	(xsp+74), xbc
	ld	xiy, SndArgNmGet_PtrTable
	lda	xix, (xsp+66)
	ldiw
	ldiw
	ld	xiy, SndArgNmGet_PtrTable_2
	lda	xix, (xsp+58)
	ld	bc, 4:i3
	ldirw
	ld	xiy, SndArgNmGet_Bytes5
	lda	xix, (xsp+52)
	ld	bc, 2:i3
	ldirw
	ldi85
	ld	xiy, SndArgNmGet_RamPtrsA
	lda	xix, (xsp+32)
	ldw	bc, 10
	ldirw
	ld	xiy, SndArgNmGet_RamPtrsB
	lda	xix, (xsp+12)
	ldw	bc, 10
	ldirw
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(xsp+9), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (xsp+6)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	ldw	(xsp+2), 0
	ld	(xsp+4), 0
	jr	SndArgNm_CheckChannelDone
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

	call	SndParam_ApplyProgramChangeAsync

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

	; jrl SndArgNm_DeliverAndReturn (v7 displacement)
	jrl	SndArgNm_DeliverAndReturn
SndArgNm_HandleEvent21:
	or	xde, xde
	jr	nz, SndArgNm_HandleEvent21_Copy
	pushw	3
	ld	xwa, (xsp+68)
	push	xwa
	pushw	0
	pushw	14664
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(14667:16), 0
	jr	SndArgNm_DeliverEvent
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

	call	Mem_Copy

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
	ld	xwa, (xsp+2)
	add	xwa, xde
	ld	(35998), (xwa)
	ld	e, (0x8c9e:16)
	extz	de
	pushw	255
	ldw	wa, 144
	ldw	bc, 16
	call	AddswbWr
	ldmm8	13043, 13042
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
	.incbin "includes/romslices/v7_transplant_CmpStep_DataBlock.bin"
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
	call	AccDraw_Secondary_Helper20
	pop	xwa
	ret
AccDraw_Secondary_Helper6:
	push	xwa
	ld	xwa, xiy
	call	ColorBlit_Variant_ByteData
	pop	xwa
	ret
	push	xiz
	calr	AccDraw_Secondary_Helper7
	pop	xiz
	ret
AccDraw_Secondary_Helper7:
	cp	(35995:16), 182
	jr	z, AccDraw_Secondary_Skip
	call	AccPlayback_InitOrUpdate
	ld	(13449:16), 182
	and	(0xe31a:16), 239
	and	(0xe318:16), 239
AccDraw_Secondary_Skip:
	call	AccDraw_Secondary_Helper
	bit	4, (0xe31a:16)
	jr	nz, AccDraw_Secondary_Skip2
	ld	xwa, AccScreen_DataBlock_Code
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
AccDraw_Secondary_Skip2:
	ld	xwa, AccScreen_DataBlock_Code2
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code:
	calr	AccScreen_DrawWall
	ld	(257960:24), 2
	ld	xiy, AccScreen_DataBlock_Data_2
	ld	xix, AccScreen_DataBlock_Data_3
	calr	AccAudio_DataBlock1
	calr	AccDraw_Secondary_Helper11
	calr	AccDraw_Secondary_Helper12
	calr	AccDraw_Secondary_Helper17
	ret
AccScreen_DataBlock_Code2:
	calr	AccDraw_Secondary_Helper10
	ld	(257960:24), 1
	ld	xiy, AccScreen_DataBlock_Data_6
	calr	AccDraw_Secondary_Helper6
	calr	AccDraw_Secondary_Helper17
	ld	(257960:24), 0
	calr	AccScreen_SelectorToWidgetIndex
	ldmm8	14623, 13370
	ldmm8	14624, 13990
	ldmm8	14625, 13991
	ldmm8	14626, 13992
	ldmm8	14627, 13993
	ldmm8	14628, 13950
	ld	xiy, AccScreen_DataBlock_Data_4
	ld	xix, AccScreen_DataBlock_Data_5
	calr	AccGraphics_RenderStart
	ld	(257960:24), 0
	ldmm8	14623, 13942
	ld	xiy, AccScreen_DataBlock_Data_7
	calr	AccDraw_Secondary
	calr	AccDraw_Secondary_Helper14
	calr	AccDraw_Secondary_Helper18
	calr	AccDraw_Secondary_Helper16
	calr	AccScreen_RefreshScreen
	ret
	push	xiz
	calr	AccDraw_Secondary_Helper8
	pop	xiz
	ret
AccDraw_Secondary_Helper8:
	call	AccDraw_Secondary_Helper8_Helper
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	ld	xix, AccScreen_DataBlock_Data
	calr	81
	ret
AccScreen_DataBlock_Data:
	.byte 0x92, 0xa1, 0xf6
	nop
	.byte 0xa4, 0xa1, 0xf6
	nop
	.byte 0xc2, 0xa1, 0xf6, 0x00, 0xe0, 0xa1, 0xf6
	nop
	nop
	.byte 0xa2, 0xf6
	nop
	ld	w, 162:opc
	.byte 0xf6
	nop
	.byte 0x52, 0xa2, 0xf6
	nop
	jr	le, -94
	.byte 0xf6
	nop
	jrl	le, -2398
	nop
	.byte 0x8c, 0xa2, 0xf6
	nop
	.byte 0xa6, 0xa2, 0xf6
	nop
	.byte 0xb1, 0xa2, 0xf6
	nop
	.byte 0xbc, 0xa2, 0xf6
	nop
	.byte 0xbd, 0xa2, 0xf6
	nop
	.byte 0xbe, 0xa2, 0xf6
	nop
	.byte 0xbf, 0xa2, 0xf6
	nop
	.byte 0xd1, 0xa2, 0xf6, 0x00, 0xd2, 0xa2, 0xf6, 0x00, 0xd3, 0xa2, 0xf6
	nop
	.byte 0xd4, 0xa2, 0xf6	; data, not code (a table of 0x00f6a2xx
				; pointers misframed as code); was `cp_spdw iz, 162`, whose
				; register byte 0xa2 names no TLCS-900 register (unidasm: -rA2L)
	nop
	cp	hl, 15
	jr	ugt, AccDraw_Secondary_Return
	ld	e, l
	inc	1, e
	calr	AccDraw_Secondary_Helper9
	and	(0xe31c:16), 254
	ld	xbc, xhl
	and	l, 31
	sla	l, 2
	ld	xix, (xix+l)
	call	(xix)
AccDraw_Secondary_Return:
	ret
AccDraw_Secondary_Helper9:
	push	xix
	cp	e, 32
	jr	ule, AccDraw_Secondary_Helper9_Skip
	xor	e, e
AccDraw_Secondary_Helper9_Skip:
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
	nop
	nop
	nop
	ld	(0:8), 0:io
	nop
	rcf
	nop
	nop
	nop
	ld	w, 0:opc
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
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ld	(0:8), 0:io
	nop
	rcf
	nop
	nop
	nop
	ld	w, 0:opc
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
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ld	(0:8), 0:io
	nop
	rcf
	nop
	nop
	nop
	ld	w, 0:opc
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
	push	sr
	nop
	nop
	nop
	.byte 0x04
	nop
	nop
	nop
	ld	(0:8), 0:io
	nop
	rcf
	nop
	nop
	nop
	ld	w, 0:opc
	nop
	nop
	ld	xwa, 2147483648
	bit	7, w
	jr	nz, 7
	or	(0x3677:16), 64
	jr	5
	or	(0x3677:16), 128
	ret
	cp	(13942:16), 4
	jr	nz, 22
	or	(0xe31c:16), 8
	bit	7, w
	jr	nz, 7
	or	(0x3691:16), 4
	jr	AccDraw_Secondary_Helper9_Return
	or	(0x3691:16), 8
AccDraw_Secondary_Helper9_Return:
	ret
	cp	(13942:16), 4
	jr	nz, AccDraw_Secondary_Return2
	or	(0xe31c:16), 8
	bit	7, w
	jr	nz, AccDraw_Secondary_Entry
	or	(0x3691:16), 1
	jr	AccDraw_Secondary_Return2
AccDraw_Secondary_Entry:
	or	(0x3691:16), 2
AccDraw_Secondary_Return2:
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	AccDraw_Secondary_Helper3
	ld	xwa, AccScreen_DataBlock_Code4
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code4:
	ld	(257960:24), 0
	calr	AccScreen_BeatDataBlock
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	AccDraw_Secondary_Helper4
	ld	xwa, AccScreen_DataBlock_Code5
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
	ret
AccScreen_DataBlock_Code5:
	ld	(257960:24), 0
	calr	AccScreen_BeatDataBlock
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	AccDraw_Secondary_Helper5
	cp	(13942:16), 4
	jr	nz, AccDraw_Secondary_Return3
	ld	xwa, AccScreen_DataBlock_Code6
	push	xwa
	call	DrawFunc_StackEntry
	inc	4, xsp
AccDraw_Secondary_Return3:
	ret
AccScreen_DataBlock_Code6:
	ld	(257960:24), 0
	ldmm8	14623, 13946
	ld	xiy, AccDraw_Secondary_Entry_Data
	calr	AccDraw_Secondary
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x77, 0x36, 0x3e, 0x02, 0xc1, 0x77, 0x36, 0x3c, 0xfe
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x77, 0x36, 0x3e, 0x01, 0xc1, 0x77, 0x36, 0x3c, 0xfd
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, AccDraw_Secondary_Return4
	bit	3, (0x36ff:16)
	jr	nz, AccDraw_Secondary_Return4
	call	AccDraw_Secondary_Helper2
	or	(0xe31a:16), 16
AccDraw_Secondary_Return4:
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, AccDraw_Secondary_Return5
	bit	4, (0x36ff:16)
	jr	nz, AccDraw_Secondary_Return5
	call	RhythmVariation_Select_Code_Sub
	or	(0xe31a:16), 16
AccDraw_Secondary_Return5:
	ret
	bit	7, w
	jr	nz, AccDraw_Secondary_Return6
	or	(0x3677:16), 32
AccDraw_Secondary_Return6:
	ret
	bit	7, w
	jr	nz, AccDraw_Secondary_Return7
	or	(0x3677:16), 4
AccDraw_Secondary_Return7:
	ret
	ret
	ret
	ret
	bit	7, w
	jr	nz, AccDraw_Secondary_Return8
	ld	(58134:16), 181
	ld	(58136:16), 128
	jr	AccDraw_Secondary_Return8
AccDraw_Secondary_Return8:
	ret
	ret
	ret
	ret
	ret
AccDraw_Secondary_Helper10:
	ld	(257960:24), 2
	cp	(13942:16), 4
	jr	nz, AccDraw_Secondary_Skip3
	ld	xiy, AccScreen_DataBlock_Data_3
	ld	xix, AccScreen_DataBlock_Data_4
	calr	AccAudio_DataBlock1
	jr	AccDraw_Secondary_Return9
AccDraw_Secondary_Skip3:
	ld	xiy, AccScreen_DataBlock_Data_5
	calr	AccDraw_Secondary_Helper6
AccDraw_Secondary_Return9:
	ret
AccDraw_Secondary_Helper11:
	xor	wa, wa
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_2
	ld	xix, xiy
	ld	a, 35:opc
	ld	c, (13986:16)
	mul	wa, c
	extz	xwa
	add	xix, xwa
	calr	AccAudio_DataBlock1
	ret
AccDraw_Secondary_Helper12:
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_3
	ld	c, (13986:16)
	calr	AccDraw_Secondary_Helper13
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_4
	ld	c, (13987:16)
	calr	AccDraw_Secondary_Helper13
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_5
	ld	c, (13988:16)
	calr	AccDraw_Secondary_Helper13
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_6
	ld	c, (13989:16)
	calr	AccDraw_Secondary_Helper13
	ret
AccDraw_Secondary_Helper13:
	xor	wa, wa
	ld	xix, xiy
	add	xix, 10
	ld	a, 20:opc
	mul	wa, c
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Return10
	extz	xwa
	add	xix, xwa
	calr	AccAudio_DataBlock1
AccDraw_Secondary_Return10:
	ret
AccDraw_Secondary_Helper14:
	ld	xiy, 13970
	ld	xix, 2601
	xor	de, de
AccDraw_Secondary_Join:
	xor	bc, bc
	ld	xiz, 13986
	xor	wa, wa
	ld	a, e
	extz	xwa
	add	xiz, xwa
	ld	d, (xiz)
	cp	d, 0:i3
	jr	z, AccDraw_Secondary_Skip4
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
AccDraw_Secondary_Loop:
	xor	hl, hl
	ld	l, c
	ld	l, (xiy+hl)
	and	l, 15
	calr	AccDraw_Secondary_Helper15
	add	xix, 4
	xor	hl, hl
	ld	l, c
	ld	l, (xiy+hl)
	and	l, 240
	srl	l, 4
	calr	AccDraw_Secondary_Helper15
	add	xix, 4
	inc	1, c
	cp	c, d
	jr	c, AccDraw_Secondary_Loop
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
AccDraw_Secondary_Skip4:
	inc	1, e
	cp	e, 4:i3
	jr	ge, AccDraw_Secondary_Return11
	add	xiy, 4
	ld	a, 8:opc
	mul	wa, c
	extz	xwa
	sub	xix, xwa
	add	xix, 1200
	jrl	AccDraw_Secondary_Join
AccDraw_Secondary_Return11:
	ret
AccDraw_Secondary_Helper15:
	push	xiy
	push	xix
	pushw	de
	pushw	bc
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data
	ld	bc, 4:i3
	ld	a, 6:opc
	ld	xwa, 14640
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
AccDraw_Secondary_Helper16:
	xor	wa, wa
	ld	a, (13939:16)
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Skip5
	dec	1, a
AccDraw_Secondary_Skip5:
	and	a, 127
	ld	c, 32:opc
	div	wa, c
	ld	(14621:16), a
	sla	wa, 1
	xor	xhl, xhl
	ld	l, w
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_7
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(14632:16), bc
	add	bc, 6
	ld	(14636:16), bc
	xor	xhl, xhl
	ld	l, a
	ld	xiy, AccDraw_Secondary_Sub_Entry2_Data_8
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(14634:16), bc
	add	bc, 8
	ld	(14638:16), bc
	ld	a, 5:opc
	push	xwa
	ld	xwa, 14630
	call	AccDraw_Secondary_Helper19
	pop	xwa
	ret
AccDraw_Secondary_Helper17:
	xor	wa, wa
	ld	a, (13939:16)
	cp	a, 0:i3
	jr	z, AccDraw_Secondary_Skip6
	dec	1, a
AccDraw_Secondary_Skip6:
	and	a, 127
	ld	c, 32:opc
	div	wa, c
	ld	(14621:16), a
	ret
AccDraw_Secondary_Helper18:
	ld	(257960:24), 0
	cp	(13942:16), 4
	jr	z, AccDraw_Secondary_Skip7
	calr	AccScreen_DrawMeasureDetail
	jr	AccDraw_Secondary_Return12
AccDraw_Secondary_Skip7:
	ld	a, (13947:16)
	cp	a, 255
	jr	z, AccDraw_Secondary_Skip8
	calr	AccScreen_DrawTempoDisplay
	calr	AccScreen_UpdateBeatDisplay
AccDraw_Secondary_Skip8:
	calr	AccScreen_BeatDataBlock
	ldmm8	14623, 13946
	ld	xiy, AccDraw_Secondary_Entry_Data
	calr	AccDraw_Secondary
AccDraw_Secondary_Return12:
	ret
AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, AccScreen_DrawTempoDisplay_Data
	ld xix, AccScreen_DrawTempoDisplay_Data_2
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	xor	wa, wa
	ld	a, (13948:16)
	ld	l, 12:opc
	divs	wa, l
	ld	(14620:16), w
	ld	(14622:16), a
	ret
AccScreen_UpdateBeatDisplay:
	ldmm8 0x391f, 0x367b
	ld XIY,AccScreen_DrawTempoDisplay_Data_2
	push XWA
	ld XWA,XIY
	call DrawText_LayoutAndRender
	pop XWA
	cp (0x367b:16), 0x63
	jr ugt, AccScreen_BeatDisplay_Large
	ld XIY,AccScreen_UpdateBeatDisplay_Data
	jr t, AccScreen_BeatDisplay_Draw
AccScreen_BeatDisplay_Large:
	ld xiy, AccScreen_BeatDisplay_Large_Data

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	cp	(0x3676:16), 4
	jr	nz, AccScreen_BeatDataBlock_Code_Return
	ldmm8	14623, 13944
	ldmm8	14624, 13945
	ld	xiy, 16165229
	ld	xix, AccDraw_Secondary_Entry_Data
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
	ld (0x03efa8:24), 0x00
	calr AccScreen_DrawTempoDisplay
	ret

AccScreen_UpdateBeat_StackWrap:
	ld xwa, AccScreen_UpdateBeat_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_UpdateBeat_Body:
	ld (0x03efa8:24), 0x00
	calr AccScreen_UpdateBeatDisplay
	ret

AccScreen_DrawMeasure_StackWrap:
	ld xwa, AccScreen_DrawMeasure_Body
	push xwa
	call DrawFunc_StackEntry
	inc 4, xsp
	ret

AccScreen_DrawMeasure_Body:
	ld (0x03efa8:24), 0x00
	calr AccScreen_DrawMeasureDetail
	ret

AccScreen_DrawMeasureDetail:
	ld a, (0x3684:16)
	dec 1,A
	ld (0x391e:16), a
	ld XIY,AccScreen_DrawMeasureDetail_Data
	calr AccDraw_Secondary
	ld a, (0x3685:16)
	ld (0x391e:16), a
	cp (0x3684:16), 0x03
	jr nz, AccScreen_DrawMeas_Other
	ld a, (0x3685:16)
	cp a, 0:i3
	jr z, AccScreen_DrawMeas_Variant3
	ld (0x391e:16), 0x01
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
; ** v7 PORT 2026-09-25 (lane accomp) of the v10 typing below.  Was one verbatim
; ROM slice (includes/romslices/v7_block_accscreen_uidatablock.bin).  v7's block is
; the SAME 2,096-byte object as v10's: 66 bytes differ and every one is a RAM
; variable id (v7 = v10 - 0x9C), a ROM pointer (v7 = v10 - 0x404) or a call
; target (v7 = v10 - 0x40D) -- scripts/converters/lane_accomp_v7_uidatablock.py
; --diff lists them, and the same script generated this text by walking v10's
; statements over v7's bytes.  ADDRESSES QUOTED IN THE COMMENTS BELOW ARE v9/v10
; ADDRESSES (subtract 0x404 for v7); the byte values in the directives are v7's.
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
	ld	(0x3efa8:24), 0
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
	ld	a, (0x36ff:16)
	and	a, 31
	jr	z, AccScreen_SelectorToWidgetIndex_Store
AccScreen_SelectorToWidgetIndex_Loop:
	srl	a, 1
	jr	c, AccScreen_SelectorToWidgetIndex_Store
	inc	1, w
	jr	AccScreen_SelectorToWidgetIndex_Loop
AccScreen_SelectorToWidgetIndex_Store:
	ld	(0x391c:16), w
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
AccScreen_DataBlock_Data_4:	.byte	0x02, 0x0f, 0x1f, 0x39, 0xff, 0x00, 0x20, 0x05, 0xad
	.byte 0xf6, 0x00, 0x07, 0x00, 0x1a, 0x04, 0x02, 0x0f, 0x1c, 0x39, 0x07, 0x00, 0x20, 0x58, 0xaa, 0xf6	; |.........9.. X..|
	.byte 0x00, 0x08, 0x00, 0x28, 0x04, 0x02, 0x0f, 0x20, 0x39, 0x0f, 0x00, 0x06, 0x80, 0xaa, 0xf6, 0x00	; |...(... 9.......|
	.byte 0x01, 0x00, 0x21, 0x08, 0x02, 0x0f, 0x21, 0x39, 0x0f, 0x00, 0x06, 0x80, 0xaa, 0xf6, 0x00, 0x01	; |..!...!9........|
	.byte 0x00, 0xd1, 0x0c, 0x02, 0x0f, 0x22, 0x39, 0x0f, 0x00, 0x06, 0x80, 0xaa, 0xf6, 0x00, 0x01, 0x00	; |....."9.........|
	.byte 0x81, 0x11, 0x02, 0x0f, 0x23, 0x39, 0x0f, 0x00, 0x06, 0x80, 0xaa, 0xf6, 0x00, 0x01, 0x00, 0x31	; |....#9.........1|
	.byte 0x16, 0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x87, 0xa8, 0xf6, 0x00, 0x00, 0x0a, 0x24, 0x39	; |..............$9|
	.byte	0x0f, 0x00, 0x06, 0x83, 0x1b, 0x01	; |.............4..|
AccScreen_DataBlock_Data_5:	.byte	0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x34, 0xa8, 0xf6
	.byte	0x00, 0x1d, 0x1f, 0x14, 0x00, 0x28, 0x00	; |.....(....9...I.|
AccScreen_DataBlock_Data_7:	.byte	0x02, 0x0f, 0x1f, 0x39, 0x01, 0x00, 0x06, 0x49, 0xa8
	.byte 0xf6, 0x00, 0x05, 0x00, 0x31, 0x1f, 0x20, 0x50, 0x48, 0x52, 0x53, 0x56, 0x41, 0x4c, 0x55, 0x45	; |....1. PHRSVALUE|
	.byte 0x04, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x0e, 0x5e, 0xa8, 0xf6, 0x00, 0xf0, 0x05, 0x22, 0x00, 0x88	; |.......^....."..|
	.byte	0x00	; |....9...o...Q.!.|
AccScreen_DataBlock_Data_6:	.byte	0x04, 0x0b, 0x1d, 0x39, 0x03, 0x00, 0x0e, 0x6f, 0xa8, 0xf6, 0x00, 0x51, 0x0a, 0x21, 0x00
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
AccScreen_BeatDisplay_Large_Data:	.incbin "includes/generated/accomp_display_full.bin", 0x3A, 0x28
AccDraw_Secondary_Entry_Data:		.incbin "includes/generated/accomp_display_full.bin", 0x62, 0xBD

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
	ld	a, (0x34a2:16)
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
	ld	a, (0x34a0:16)
	pop	xhl
	ret
AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	push	xiz
	ld	xiz, 608256
	ld	(14610:16), xiz
	calr	AccPatch_InitSlotChain
	pop	xiz
	ret
AccPatch_InitSlotChain:
	xor	xwa, xwa
	xor	xbc, xbc
	ld	xhl, (14610:16)
	add	xhl, 5120
	ld	(14034:16), xhl
	ld	wa, (xhl+3)
	ld	(14050:16), wa
	ldw	bc, 150
	ld	(14066:16), bc
	ld	xhl, (14610:16)
	add	xhl, 43520
	ld	(14030:16), xhl
	ldw	bc, 150
	xor	xhl, xhl
AccPatch_IterateSlotChain:
	cpw	(0x36e2:16), 65535
	jr	z, AccPatch_IterateSlot_NextBlock
	ld	hl, (0x36e2:16)
	calr	AccPatch_CalcSlotBufferAddr
	ld	(0x36be:16), xiz
	cp	hl, (0x36f2:16)
	jr	z, AccPatch_IterateSlot_Advance
	calr	AccPatch_UpdateLinkPointers
	calr	AccPatch_SwapSlotBuffers
AccPatch_IterateSlot_Advance:
	ld	xiz, (14030:16)
	ld	wa, (xiz+3)
	ld	(14050:16), wa
	incw	1, (14066:16)
	ld	hl, (14066:16)
	calr	AccPatch_CalcSlotBufferAddr
	ld	(14030:16), xiz
	jr	AccPatch_IterateSlotChain
AccPatch_IterateSlot_NextBlock:
	ld	xiz, 256
	add	(14034:16), xiz
	ld	xiz, (14034:16)
	ld	wa, (xiz+3)
	ld	(14050:16), wa
	djnz16	bc, -82
	xor	xwa, xwa
	xor	xhl, xhl
	ld	wa, (14066:16)
	ldw	hl, 256
	mul	xwa, hl
	add	xwa, 5120
	add	xwa, 1023
	and	xwa, 4294966272
	srl	xwa, 4
	ld	xiy, (14610:16)
	ld	(xiy+46), wa
	ret
AccPatch_SwapSlotBuffers:
	push	xbc
	ld	xwa, 1024
	push	xwa
	call	Malloc
	add	xsp, 4
	ld	(0x34c8:16), xhl
	ldw	bc, 256
	ld	xix, (0x34c8:16)
	ld	xiy, (0x36ce:16)
	ldir85
	ldw	bc, 256
	ld	xix, (0x36ce:16)
	ld	xiy, (0x36be:16)
	ldir85
	ldw	bc, 256
	ld	xiy, (0x34c8:16)
	ld	xix, (0x36be:16)
	ldir85
	ld	xwa, (0x34c8:16)
	push	xwa
	call	Free
	add	xsp, 4
	pop	xbc
	ret
AccPatch_UpdateLinkPointers:
	xor	xwa, xwa
	xor	xhl, xhl
	ld	xiy, (14014:16)
	ld	wa, (xiy+3)
	ld	(14475:16), wa
	ld	wa, (xiy+1)
	ld	(14477:16), wa
	ld	xix, (14030:16)
	ld	wa, (xix+3)
	ld	(14479:16), wa
	ld	wa, (xix+1)
	ld	(14481:16), wa
	ld	hl, (14475:16)
	cp	hl, 65535
	jr	z, AccPatch_UpdateLink_Back
	calr	AccPatch_CalcSlotBufferAddr
	ld	wa, (14066:16)
	ld	(xiz+1), wa
AccPatch_UpdateLink_Back:
	ld	hl, (14477:16)
	cp	hl, 65535
	jr	z, AccPatch_UpdateLink_Fwd1
	calr	AccPatch_CalcSlotBufferAddr
	ld	wa, (14066:16)
	ld	(xiz+3), wa
AccPatch_UpdateLink_Fwd1:
	ld	hl, (14479:16)
	cp	hl, 65535
	jr	z, AccPatch_UpdateLink_Fwd2
	calr	AccPatch_CalcSlotBufferAddr
	ld	wa, (14050:16)
	ld	(xiz+1), wa
AccPatch_UpdateLink_Fwd2:
	ld	hl, (14481:16)
	cp	hl, 65535
	jr	z, AccPatch_UpdateLink_Return
	calr	AccPatch_CalcSlotBufferAddr
	ld	wa, (14050:16)
	ld	(xiz+3), wa
AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, hl
	add	xiz, (14610:16)
	add	xiz, 5120
	ret
AccPatch_VoiceAssignDataBlock:
	ret
	ret
	ld	xiy, (14002:16)
	ld	a, (xiy+0:8)
	cp	a, 109
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+2)
	cp	a, 97
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	(14078:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip:
	ld	a, (xiy+0:8)
	cp	a, 102
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+1)
	cp	a, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	a, (xiy+2)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip2
	ld	(14078:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip2:
	ld	a, (xiy+0:8)
	cp	a, 109
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	a, (xiy+2)
	cp	a, 98
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip3
	ld	(14078:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return
AccPatch_VoiceAssignDataBlock_Skip3:
	ld	(14078:16), 255
	ld	(14516:16), 130
AccPatch_VoiceAssignDataBlock_Return:
	ret
	xor	xbc, xbc
	ldw	bc, 42
	add	xiy, 12
	add	xix, 12
	ldirw
	djnz8	e, -22
	ret
	cp xix, xiy
	jr	ugt, AccPatch_VoiceAssignDataBlock_Entry
AccPatch_VoiceAssignDataBlock_Loop:
	xor	xbc, xbc
	ldw	bc, 128
	ldirw
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop
	jr	AccPatch_VoiceAssignDataBlock_Return2
AccPatch_VoiceAssignDataBlock_Entry:
	push	d
	ld	d, 0:opc
	ld	xbc, 0:i3
	ldw	bc, 256
	mul	xbc, de
	pop d
	add	xix, xbc
	add	xiy, xbc
	push	xix
	push	xiy
	dec	1, xix
	dec	1, xiy
AccPatch_VoiceAssignDataBlock_Loop2:
	ld	xbc, 0:i3
	ldw	bc, 256
	lddr85
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop2
	pop	xiy
	pop	xix
AccPatch_VoiceAssignDataBlock_Return2:
	ret
	xor	xbc, xbc
AccPatch_VoiceAssignDataBlock_Loop3:
	ld	(xiy), 0
	ldw	(xiy+1), 65535
	ldw	(xiy+3), 65535
	ld	c, 249:opc
	add	xiy, 6
AccPatch_VoiceAssignDataBlock_Loop4:
	ld	(xiy+), 0
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop4
	inc	1, xiy
	dec	1, e
	cp	e, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop3
	ret
	xor	xbc, xbc
AccPatch_VoiceAssignDataBlock_Loop5:
	ld	xiy, 651776
	ld	c, (14498:16)
AccPatch_VoiceAssignDataBlock_Loop6:
	cp	(xiy+1), wa
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip5
AccPatch_VoiceAssignDataBlock_Entry2:
	cpw	(xiy+3), 65535
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip4
	inc	1, (14497:16)
	jr	AccPatch_VoiceAssignDataBlock_Join
AccPatch_VoiceAssignDataBlock_Skip4:
	inc	1, (14497:16)
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Entry2
	jr	AccPatch_VoiceAssignDataBlock_Join
AccPatch_VoiceAssignDataBlock_Skip5:
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jr	ugt, AccPatch_VoiceAssignDataBlock_Loop6
AccPatch_VoiceAssignDataBlock_Join:
	inc	1, wa
	cp	wa, qwa
	jr	ule, AccPatch_VoiceAssignDataBlock_Loop5
	ret
	ld	xiy, 651776
	xor	xbc, xbc
	ld	c, 190:opc
	cp	(xiy), 128
	jr	nz, AccPatch_VoiceAssignDataBlock_Return3
	inc	1, (14502:16)
	add	xiy, 256
	djnz8	c, -18
AccPatch_VoiceAssignDataBlock_Return3:
	ret
	xor	xde, xde
AccPatch_VoiceAssignDataBlock_Loop7:
	ld	de, (xiy+3)
	cp	de, 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Skip9
	ld	de, (14506:16)
	ld	(xiy+3), de
	ld	de, (14504:16)
	ld	(xix+1), de
	ldw	(14512:16), 0
AccPatch_VoiceAssignDataBlock_Entry3:
	cpw	(xix+3), 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Skip7
	ld	de, (14512:16)
	cp	de, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip6
	incw	1, (14506:16)
	ld	de, (14506:16)
	ld	(xix+3), de
	add	xix, 256
	ldw	(14512:16), 255
	jr	AccPatch_VoiceAssignDataBlock_Entry3
AccPatch_VoiceAssignDataBlock_Skip6:
	ld	de, (14506:16)
	dec	1, de
	ld	(xix+1), de
	incw	1, (14506:16)
	ld	de, (14506:16)
	ld	(xix+3), de
	add	xix, 256
	jr	AccPatch_VoiceAssignDataBlock_Entry3
AccPatch_VoiceAssignDataBlock_Skip7:
	ld	de, (14512:16)
	cp	de, 0:i3
	jr	z, AccPatch_VoiceAssignDataBlock_Skip8
	ld	de, (14506:16)
	dec	1, de
	ld	(xix+1), de
AccPatch_VoiceAssignDataBlock_Skip8:
	incw	1, (14506:16)
	add	xix, 256
AccPatch_VoiceAssignDataBlock_Skip9:
	incw	1, (14504:16)
	add	xiy, 256
	dec	1, c
	cp	c, 0:i3
	jrl	ugt, AccPatch_VoiceAssignDataBlock_Loop7
	ret
AccPatch_VoiceAssignDataBlock_Helper:
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, hl
	add	xiz, 613376
	ret
	push	xiz
	call	AccPatch_VoiceAssignDataBlock_Helper2
	pop	xiz
	ret
AccPatch_VoiceAssignDataBlock_Helper2:
	ld	(14516:16), 0
	ldw	(14548:16), 0
	ldw	(14550:16), 150
	calr	AccPatch_VoiceAssignDataBlock_Helper27
	calr	AccPatch_VoiceAssignDataBlock_Helper28
	cp	(14516:16), 132
	jr	z, AccPatch_VoiceAssignDataBlock_Join2
	calr	AccPatch_VoiceAssignDataBlock_Helper4
	cp	w, 255
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip10
	ld	(14516:16), 130
	jr	AccPatch_VoiceAssignDataBlock_Join2
AccPatch_VoiceAssignDataBlock_Skip10:
	calr	AccPatch_VoiceAssignDataBlock_Helper3
	call	AccScreen_GetByte_0x353E
	calr	AccPatch_VoiceAssignDataBlock_Helper5
	calr	AccPatch_VoiceAssignDataBlock_Helper6
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join2
	calr	AccPatch_VoiceAssignDataBlock_Helper11
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join2
	calr	AccPatch_VoiceAssignDataBlock_Helper24
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Join2
	jr	AccPatch_VoiceAssignDataBlock_Join3
AccPatch_VoiceAssignDataBlock_Join2:
	call	AccScreen_GetByte_0x353E
	calr	AccPatch_VoiceAssignDataBlock_Helper5
AccPatch_VoiceAssignDataBlock_Join3:
	calr	AccPatch_VoiceAssignDataBlock_Helper31
	call	AccPatch_ClearModeFlag
	ret
AccPatch_VoiceAssignDataBlock_Helper3:
	xor	xwa, xwa
	ld	xiy, 432128
	ld	wa, (xiy+14)
	ld	xiy, 608256
	ld	(xiy+14), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper4:
	ld	xhl, 432128
	cp	(xhl+1), 72
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip11
	cp	(xhl+2), 0
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip11
	cp	(xhl+2), 75
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip11
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return4
AccPatch_VoiceAssignDataBlock_Skip11:
	ld	a, (xhl+0:8)
	cp	a, 103
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip12
	ld	a, (xhl+1)
	cp	a, 0:i3
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip12
	ld	a, (xhl+2)
	cp	a, 107
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip12
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return4
AccPatch_VoiceAssignDataBlock_Skip12:
	ld	a, (xhl+0:8)
	cp	a, 76
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip13
	ld	a, (xhl+1)
	cp	a, 75
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip13
	ld	a, (xhl+2)
	cp	a, 69
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip13
	ld	w, 5:opc
	jr	AccPatch_VoiceAssignDataBlock_Return4
AccPatch_VoiceAssignDataBlock_Skip13:
	ld	w, 255:opc
AccPatch_VoiceAssignDataBlock_Return4:
	ret
AccPatch_VoiceAssignDataBlock_Helper5:
	ld	w, (13370:16)
	ld	(13370:16), a
	pushw	wa
	call	AccPatch_InitCurrentSlot
	popw	wa
	ld	(13370:16), w
	ret
AccPatch_VoiceAssignDataBlock_Helper6:
	xor	xhl, xhl
	xor	xwa, xwa
	call	AccScreen_GetByte_0x353C
	ld	l, a
	ld	a, 96:opc
	mul	wa, l
	add	wa, 96
	ld	(14558:16), wa
	xor	xwa, xwa
	call	AccScreen_GetByte_0x353E
	ld	l, a
	ld	a, 96:opc
	mul	wa, l
	add	wa, 96
	ld	(14560:16), wa
	cpw	(14558:16), 960
	jr	c, AccPatch_VoiceAssignDataBlock_Skip14
	cpw	(14558:16), 960
	jr	z, AccPatch_VoiceAssignDataBlock_Skip15
	cpw	(14558:16), 2016
	jr	c, AccPatch_VoiceAssignDataBlock_Skip16
	cpw	(14558:16), 2016
	jr	z, AccPatch_VoiceAssignDataBlock_Skip17
	jr	AccPatch_VoiceAssignDataBlock_Join4
AccPatch_VoiceAssignDataBlock_Skip14:
	calr	AccPatch_VoiceAssignDataBlock_Helper7
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Skip15:
	calr	AccPatch_VoiceAssignDataBlock_Helper8
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Skip16:
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	cp	(14516:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Return5
	subw	(0x38de:16), 1024
	calr	AccPatch_VoiceAssignDataBlock_Helper7
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Skip17:
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	cp	(14516:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Return5
	subw	(0x38de:16), 1024
	calr	AccPatch_VoiceAssignDataBlock_Helper8
	jr	AccPatch_VoiceAssignDataBlock_Return5
AccPatch_VoiceAssignDataBlock_Join4:
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	cp	(14516:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Return5
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	cp	(14516:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Return5
	subw	(0x38de:16), 2048
	calr	AccPatch_VoiceAssignDataBlock_Helper9
AccPatch_VoiceAssignDataBlock_Return5:
	ret
AccPatch_VoiceAssignDataBlock_Helper7:
	xor	xiz, xiz
	ld	xiy, 432128
	ld	iz, (14558:16)
	add	xiy, xiz
	add	xiy, 12
	ld	xix, 608256
	ld	iz, (14560:16)
	add	xix, xiz
	add	xix, 12
	xor	xbc, xbc
	ldw	bc, 84
	ldir85
	calr	AccPatch_VoiceAssignDataBlock_Helper10
	ret
AccPatch_VoiceAssignDataBlock_Helper8:
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xiz, xiz
	ldw	wa, 1024
	sub wa, (14558:16)
	ld	bc, wa
	sub	bc, 12
	ld	xiy, 432128
	ld	xix, 608256
	ld	iz, (14558:16)
	add	xiy, xiz
	add	xiy, 12
	ld	iz, (14560:16)
	add	xix, xiz
	add	xix, 12
	push	xbc
	ldir85
	push	xiy
	push	xix
	calr	AccPatch_VoiceAssignDataBlock_Helper10
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	pop	xix
	pop	xiy
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return6
	pop	xbc
	ld	xiy, 432128
	ldw	wa, 96
	sub	wa, bc
	ld	bc, wa
	sub	bc, 12
	ldir85
AccPatch_VoiceAssignDataBlock_Return6:
	ret
AccPatch_VoiceAssignDataBlock_Helper9:
	xor	xiy, xiy
	xor	xix, xix
	ld	iy, (14558:16)
	add	xiy, 432128
	add	xiy, 12
	ld	ix, (14560:16)
	add	xix, 608256
	add	xix, 12
	ldw	bc, 96
	sub	bc, 12
	ldir85
	calr	AccPatch_VoiceAssignDataBlock_Helper10
	ret
AccPatch_VoiceAssignDataBlock_Helper10:
	xor	xiy, xiy
	xor	xix, xix
	xor	xwa, xwa
	ld	iy, (14558:16)
	ld	xhl, 432128
	add	xhl, 0
	ld	wa, (xhl+iy)
	ld	(14518:16), wa
	ld	xhl, 432128
	add	xhl, 4
	ld	wa, (xhl+iy)
	ld	(14520:16), wa
	ld	xhl, 432128
	add	xhl, 6
	ld	wa, (xhl+iy)
	ld	(14522:16), wa
	ld	xhl, 432128
	add	xhl, 8
	ld	wa, (xhl+iy)
	ld	(14524:16), wa
	ld	xhl, 432128
	add	xhl, 10
	ld	wa, (xhl+iy)
	ld	(14526:16), wa
	ld	ix, (14560:16)
	add	xix, 608256
	ld	wa, (xix+0:8)
	ld	(14528:16), wa
	ld	wa, (xix+4)
	ld	(14530:16), wa
	ld	wa, (xix+6)
	ld	(14532:16), wa
	ld	wa, (xix+8)
	ld	(14534:16), wa
	ld	wa, (xix+10)
	ld	(14536:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper11:
	calr	AccPatch_VoiceAssignDataBlock_Helper29
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return7
	ld	xwa, 5:i3
	push	xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	pop	xwa
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return7
	djnz8	a, -14
	calr	AccPatch_VoiceAssignDataBlock_Helper12
	calr	AccPatch_VoiceAssignDataBlock_Helper13
	calr	AccPatch_VoiceAssignDataBlock_Helper14
	calr	AccPatch_VoiceAssignDataBlock_Helper15
	calr	AccPatch_VoiceAssignDataBlock_Helper16
AccPatch_VoiceAssignDataBlock_Return7:
	ret
AccPatch_VoiceAssignDataBlock_Helper12:
	ld	wa, (14518:16)
	ld	(14552:16), wa
	ld	wa, (14528:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	ld	wa, (14552:16)
	ld	(14518:16), wa
	ld	wa, (14556:16)
	ld	(14538:16), wa
	ld	wa, (14554:16)
	ld	(14528:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper13:
	ld	wa, (14520:16)
	ld	(14552:16), wa
	ld	wa, (14530:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	ld	wa, (14552:16)
	ld	(14520:16), wa
	ld	wa, (14556:16)
	ld	(14540:16), wa
	ld	wa, (14554:16)
	ld	(14530:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper14:
	ld	wa, (14522:16)
	ld	(14552:16), wa
	ld	wa, (14532:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	ld	wa, (14552:16)
	ld	(14522:16), wa
	ld	wa, (14556:16)
	ld	(14542:16), wa
	ld	wa, (14554:16)
	ld	(14532:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper15:
	ld	wa, (14524:16)
	ld	(14552:16), wa
	ld	wa, (14534:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	ld	wa, (14552:16)
	ld	(14524:16), wa
	ld	wa, (14556:16)
	ld	(14544:16), wa
	ld	wa, (14554:16)
	ld	(14534:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper16:
	ld	wa, (14526:16)
	ld	(14552:16), wa
	ld	wa, (14536:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper17
	ld	wa, (14552:16)
	ld	(14526:16), wa
	ld	wa, (14556:16)
	ld	(14546:16), wa
	ld	wa, (14554:16)
	ld	(14536:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper17:
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return8
	calr	AccPatch_VoiceAssignDataBlock_Helper18
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return8
	calr	AccPatch_VoiceAssignDataBlock_Helper22
	calr	AccPatch_VoiceAssignDataBlock_Helper23
AccPatch_VoiceAssignDataBlock_Return8:
	ret
AccPatch_VoiceAssignDataBlock_Helper18:
	calr	AccPatch_VoiceAssignDataBlock_Helper19
	cp	de, 0:i3
	jr	z, AccPatch_VoiceAssignDataBlock_Return9
	ld	wa, (14552:16)
	cp wa, (14548:16)
	jr	c, AccPatch_VoiceAssignDataBlock_Skip19
	xor	xhl, xhl
	xor	xbc, xbc
	ld	bc, (14552:16)
	srl	bc, 2
	ld	hl, (14548:16)
	srl	hl, 2
	sub	bc, hl
AccPatch_VoiceAssignDataBlock_Join5:
	cp	bc, 0:i3
	jr	ule, AccPatch_VoiceAssignDataBlock_Skip18
	push	xbc
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	pop	xbc
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip18
	addw	(0x38d4:16), 4
	dec	1, bc
	jr	AccPatch_VoiceAssignDataBlock_Join5
AccPatch_VoiceAssignDataBlock_Skip18:
	jr	AccPatch_VoiceAssignDataBlock_Return9
AccPatch_VoiceAssignDataBlock_Skip19:
	calr	AccPatch_VoiceAssignDataBlock_Helper20
AccPatch_VoiceAssignDataBlock_Return9:
	ret
AccPatch_VoiceAssignDataBlock_Helper19:
	xor	xwa, xwa
	xor	xhl, xhl
	xor	xde, xde
	ld	wa, (14552:16)
	ld	hl, (14548:16)
	cp	wa, hl
	jr	c, AccPatch_VoiceAssignDataBlock_Skip20
	add	hl, 3
	cp	wa, hl
	jr	ugt, AccPatch_VoiceAssignDataBlock_Skip20
	ld	de, 0:i3
	jr	AccPatch_VoiceAssignDataBlock_Return10
AccPatch_VoiceAssignDataBlock_Skip20:
	ldw	de, 255
AccPatch_VoiceAssignDataBlock_Return10:
	ret
AccPatch_VoiceAssignDataBlock_Helper20:
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return11
	cpw	(14552:16), 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Skip22
	calr	AccPatch_VoiceAssignDataBlock_Helper29
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return11
	ld	xwa, 4:i3
	push	xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	pop	xwa
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return11
	djnz8	a, -14
	ldw	(14548:16), 0
	xor	xbc, xbc
	ld	bc, (14552:16)
	srl	bc, 2
	inc	1, bc
AccPatch_VoiceAssignDataBlock_Join6:
	cp	bc, 0:i3
	jr	ule, AccPatch_VoiceAssignDataBlock_Skip21
	push	xbc
	calr	AccPatch_VoiceAssignDataBlock_Helper30
	pop	xbc
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Return11
	addw	(0x38d4:16), 4
	dec	1, bc
	jr	AccPatch_VoiceAssignDataBlock_Join6
AccPatch_VoiceAssignDataBlock_Skip21:
	jr	AccPatch_VoiceAssignDataBlock_Return11
AccPatch_VoiceAssignDataBlock_Skip22:
	ld	(14516:16), 128
AccPatch_VoiceAssignDataBlock_Return11:
	ret
AccPatch_VoiceAssignDataBlock_Helper21:
	xor	xwa, xwa
	xor	xhl, xhl
	ld	wa, (14552:16)
	ld	hl, (14548:16)
	sub	wa, hl
	ldw	hl, 256
	mul	xwa, hl
	ld	(14558:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper22:
	calr	AccPatch_VoiceAssignDataBlock_Helper21
	xor	xiy, xiy
	ld	iy, (14558:16)
	add	xiy, 6
	add	xiy, 432128
	xor	xhl, xhl
	ld	hl, (14554:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	xix, xiz
	add	xix, 6
	xor	xbc, xbc
	ldw	bc, 249
	ldir85
	ret
AccPatch_VoiceAssignDataBlock_Helper23:
	xor	xiy, xiy
	xor	xwa, xwa
	calr	AccPatch_VoiceAssignDataBlock_Helper21
	ld	iy, (14558:16)
	ld	xhl, 432128
	add	xhl, 3
	ld	wa, (xhl+iy)
	ld	(14552:16), wa
	xor	xhl, xhl
	ld	hl, (14554:16)
	ld	(14556:16), hl
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	wa, (xiz+3)
	ld	(14554:16), wa
	ret
AccPatch_VoiceAssignDataBlock_Helper24:
	ld	wa, (14518:16)
	ld	(14552:16), wa
	ld	wa, (14538:16)
	ld	(14556:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper25
	ld	wa, (14520:16)
	ld	(14552:16), wa
	ld	wa, (14540:16)
	ld	(14556:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper25
	ld	wa, (14522:16)
	ld	(14552:16), wa
	ld	wa, (14542:16)
	ld	(14556:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper25
	ld	wa, (14524:16)
	ld	(14552:16), wa
	ld	wa, (14544:16)
	ld	(14556:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper25
	ld	wa, (14526:16)
	ld	(14552:16), wa
	ld	wa, (14546:16)
	ld	(14556:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper25
	ret
AccPatch_VoiceAssignDataBlock_Helper25:
	xor	xwa, xwa
	bit	7, (0x38b4:16)
	jrl	nz, AccPatch_VoiceAssignDataBlock_Epilogue2
AccPatch_VoiceAssignDataBlock_Helper25_Join:
	cpw	(14552:16), 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Epilogue
	calr	AccPatch_VoiceAssignDataBlock_Helper26
	cpw	(14550:16), 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Skip23
	ld	wa, (14550:16)
	ld	(14554:16), wa
	calr	AccPatch_VoiceAssignDataBlock_Helper18
	bit	7, (0x38b4:16)
	jr	nz, AccPatch_VoiceAssignDataBlock_Skip23
	calr	AccPatch_VoiceAssignDataBlock_Helper22
	xor	xhl, xhl
	ld	hl, (14556:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	wa, (14554:16)
	ld	(xiz+3), wa
	ld	hl, wa
	calr	AccPatch_VoiceAssignDataBlock_Helper
	or	(xiz), 128
	decw	1, (13368:16)
	ld	wa, (14556:16)
	ld	(xiz+1), wa
	xor	xiy, xiy
	ld	iy, (14558:16)
	add	xiy, 432128
	ld	wa, (xiy+3)
	cp	wa, 65535
	jr	z, AccPatch_VoiceAssignDataBlock_Helper25_Skip
	ld	(xiz+3), wa
	jr	AccPatch_VoiceAssignDataBlock_Helper25_Join2
AccPatch_VoiceAssignDataBlock_Helper25_Skip:
	ldw	(xiz+3), 65535
AccPatch_VoiceAssignDataBlock_Helper25_Join2:
	ld	(14552:16), wa
	ld	wa, (14554:16)
	ld	(14556:16), wa
	jr	AccPatch_VoiceAssignDataBlock_Helper25_Join
AccPatch_VoiceAssignDataBlock_Skip23:
	ld	hl, (14554:16)
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ldw	(xiz+3), 65535
AccPatch_VoiceAssignDataBlock_Epilogue:
	nop
AccPatch_VoiceAssignDataBlock_Epilogue2:
	nop
	ret
AccPatch_VoiceAssignDataBlock_Helper26:
	xor	xhl, xhl
	ld	hl, (14550:16)
	cp	hl, 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper26_Skip2
AccPatch_VoiceAssignDataBlock_Join7:
	calr	AccPatch_VoiceAssignDataBlock_Helper
	ld	a, (xiz)
	bit	7, a
	jr	z, AccPatch_VoiceAssignDataBlock_Helper26_Skip2
	inc	1, hl
	cp	hl, 340
	jr	nc, AccPatch_VoiceAssignDataBlock_Helper26_Skip
	jr	AccPatch_VoiceAssignDataBlock_Join7
AccPatch_VoiceAssignDataBlock_Helper26_Skip:
	ld	(14516:16), 131
AccPatch_VoiceAssignDataBlock_Helper26_Skip2:
	ld	(14550:16), hl
	ret
AccPatch_VoiceAssignDataBlock_Helper27:
	ret
AccPatch_VoiceAssignDataBlock_Helper28:
	ret
AccPatch_VoiceAssignDataBlock_Helper29:
	ret
AccPatch_VoiceAssignDataBlock_Helper30:
	ret
AccPatch_VoiceAssignDataBlock_Helper31:
	cp	(14516:16), 0
	jr	z, AccPatch_VoiceAssignDataBlock_Skip28
	cp	(14516:16), 132
	jr	z, AccPatch_VoiceAssignDataBlock_Skip24
	cp	(14516:16), 130
	jr	z, AccPatch_VoiceAssignDataBlock_Skip27
	cp	(14516:16), 131
	jr	z, AccPatch_VoiceAssignDataBlock_Skip25
	cp	(14516:16), 129
	jr	z, AccPatch_VoiceAssignDataBlock_Skip26
	ld	(32422:16), 1
	jr	AccPatch_VoiceAssignDataBlock_Return12
AccPatch_VoiceAssignDataBlock_Skip24:
	ld	(32422:16), 3
	jr	AccPatch_VoiceAssignDataBlock_Return12
AccPatch_VoiceAssignDataBlock_Skip25:
	ld	(32422:16), 23
	jr	AccPatch_VoiceAssignDataBlock_Return12
AccPatch_VoiceAssignDataBlock_Skip26:
	ld	(32422:16), 1
	jr	AccPatch_VoiceAssignDataBlock_Return12
AccPatch_VoiceAssignDataBlock_Skip27:
	ld	(32422:16), 0
	jr	AccPatch_VoiceAssignDataBlock_Return12
AccPatch_VoiceAssignDataBlock_Skip28:
	ld	(32422:16), 35
AccPatch_VoiceAssignDataBlock_Return12:
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
	; anddi8 (0x8d88), 254 (v7 patched)
	and	(0x8cec:16), 254
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
	call	SeqBuf_Init
	call	NoteMap_SendAllNotesOff
	call	Part_ReinitAllActive
	call	AccompSeq_StopSequence
	call	AccWrap_PlayModeDispatch
	set	2, (0x28a7:16)
	call	AudioInit_RefreshToneBank
	call	NoteMap_ProcessAndMerge
	call	Voice_InitializeAll
	call	Voice_InitTablePair
	call	Voice_InitTableGroup
	call	MIDI_SendAllSoundOff
	call	Vga_SetupMultiPlaneDisplay
	jr	AccDisplay_CopyToBackBuffer
Display_RestoreEntry:
	res 2, (0x28a7:16)
	call Vga_RestoreMultiPlaneDisplay
	jr AccDisplay_CopyToFrontBuffer

AccDisplay_CopyToBackBuffer:
	lda xbc, (0x094800:24)

	ld (21824:16), xbc

	lda xwa, (0x069800:24)

	ld (21828:16), xwa

	ld xiy, xbc

	ld xix, xwa

	ldw bc, 0xb400

	ldirw

	ret



AccDisplay_CopyToFrontBuffer:
	lda xde, (0x094800:24)

	ld (21824:16), xde

	lda xwa, (0x069800:24)

	ld (21828:16), xwa

	ld xiy, xwa

	ld xix, xde

	ldw bc, 0xb400

	ldirw

	ret



AccBankData_InitAllSlots:
	pushw_erp 0xfa

	ld xwa, (15552:16)

	ld (21824:16), xwa

	ldib_erp 0xfb, 0

	ld wa, 0:i3



AccBankData_InitSlot_OuterLoop:
	ld xde, 0:i3

AccBankData_InitSlot_InnerLoop:
	lda	xbc, (xde+wa)
	add	xbc, (0x5540:16)
	lda	xbc, (xbc+160)
	cp	(xbc), 0
	jr	nz, AccBankData_InitSlot_NonZero
	ld	(xbc), 32
	jr	AccBankData_InitSlot_PadSpaces
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
	add	xbc, (21824:16)
	ld	(xbc+160), 32
	inc	1, xde
	cp	xde, 16
	jr	c, AccBankData_PadSpaces_Loop
AccBankData_PadSpaces_Done:
	inc1b_erp	251
	add	wa, 96
	cp_erpb	251, 12
	jr	c, AccBankData_InitSlot_OuterLoop
	ld	(18490:16), 0
	res	0, (0x3514:16)
	ldib_erp	251, 0
AccBankData_ProcessSlot:
	lda	xwa, (432128:24)
	ld	(14610:16), xwa
	ldto_berp	a, 251
	ld	(14608:16), a
	call	AccPatch_InitFromSlotIndex
	ld	xwa, (15552:16)
	ld	(14610:16), xwa
	lda	xwa, (432128:24)
	ld	(14614:16), xwa
	ldto_berp	a, 251
	ld	(14609:16), a
	ldto_berp	a, 251
	ld	(14608:16), a
	call	DualVoice_ParamLoadDone
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, AccBankData_SlotFound
	ld	(18490:16), 1
	jr	AccBankData_ReInitAllSlots
AccBankData_SlotFound:
	inc1b_erp	251
	cp_erpb	251, 30
	jr	c, AccBankData_ProcessSlot
	cp	(18490:16), 0
	jr	z, AccBankData_FinalizeCheck
AccBankData_ReInitAllSlots:
	lda xwa, (0x069800:24)

	ld (14610:16), xwa

	ldib_erp 0xfb, 0



AccBankData_ReInit_Loop:
	ldto_berp	a, 251
	ld	(14608:16), a
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 30
	jr	c, AccBankData_ReInit_Loop	; -> 0xF6B9EF
AccBankData_FinalizeCheck:
	cp	(0x483a:16), 0
	jr	nz, AccBankData_Return
	ld	xwa, (0x3cc0:16)
	add	xwa, 92160
	ld	bc, (xwa)
	ld	xwa, 4:i3
	ld	de, 3:i3
	call	Audio_ResetAfterPayloadError_Helper
	call	SeqTimer_UpdateTempoReg
	ld	xbc, (0x3cc0:16)
	add	xbc, 93184
	ld	xix, xbc
	ldib_erp	251, 0
	lda	xde, (0xe2f4:16)
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
	ld	a, (xix+)
	ld	(xbc+), a
	inc	1, xde
	cp	xde, 29350
	jr	c, AccBankData_CopyToExtRAM
	ld	wa, 0:i3
	call	PostTmSave_Success
AccBankData_Return:
	popw_erp 0xfa
	ret

AccBankData_ProcessWithCopy:
	dec 2, xsp

	pushw_erp 0xfa

	ld (xsp + 2), a

	ld xbc, (15552:16)

	ld (21824:16), xbc

	pushw 0xd

	ld xwa, (15552:16)

	add xwa, 0x16802

	push xwa

	lda xwa, (xbc+160:16)

	push xwa

	call Mem_Copy

	lda xsp, (xsp + 10)

	ldib_erp 0xfb, 0

	ld bc, 0:i3
AccBankData_CopyLoop:
	ld	de, bc
	add	de, 160
	ld	xwa, (21824:16)
	lda	xwa, (xwa+de)
	ld	e, (xwa)
	cp	e, 0:i3
	jr	nz, AccBankData_CopyLoop_NonZero
	ld	e, 32:opc
AccBankData_CopyLoop_NonZero:
	ld	(xwa), e
	inc1b_erp	251
	inc	1, bc
	cp_erpb	251, 16
	jr	c, AccBankData_CopyLoop
	cp	(xsp+2), 2
	jr	ule, AccBankData_InitSlotScan
	call	Vga_BackupPlane3ToBuffer
	ld	c, (xsp+2)
	inc	7, c
	extz	bc
	ld	xde, (15552:16)
	ld	wa, 0:i3
	call	DualVoice_LoadAndScan
	call	Vga_RestorePlane3FromBuffer
	call	AccPatch_CountSlotsAlt
	jrl	AccBankData_PostModeChange
AccBankData_InitSlotScan:
	; stdi8 (0x48d6), 0 (v7 patched)
	ld	(0x483a:16), 0
	; resda 0, 0x35b0 (v7 patched)
	res	0, (0x3514:16)
	ldib_erp 0xfb, 0
AccBankData_SlotScan_Loop:
	lda	xwa, (432128:24)
	ld	(14610:16), xwa
	ld	c, (xsp+2)
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccBankData_SlotOrder:24)
	ld	(14608), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	ld	xwa, (15552:16)
	ld	(14610:16), xwa
	lda	xwa, (432128:24)
	ld	(14614:16), xwa
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	lda	xde, (AccBankData_SlotOrder:24)
	ld	(14608), (xde+bc)
	ld	a, (xsp+2)
	extz	wa
	add	bc, wa
	ld	(14609), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, AccBankData_SlotScan_Next
	ld	(18490:16), 1
	jr	AccBankData_SlotScan_ReInit
AccBankData_SlotScan_Next:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, AccBankData_SlotScan_Loop
	cp	(18490:16), 0
	jr	z, AccBankData_NotifyAndUpdateTempo
AccBankData_SlotScan_ReInit:
	lda xwa, (0x069800:24)

	ld (14610:16), xwa

	ldib_erp 0xfb, 0



AccBankData_ReInit_ScanLoop:
	ld	c, (xsp+2)
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccBankData_SlotOrder:24)
	ld	(14608), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, AccBankData_ReInit_ScanLoop
	jr	AccBankData_PostModeChange
AccBankData_NotifyAndUpdateTempo:
	ld	xwa, (15552:16)
	add	xwa, 92160
	ld	bc, (xwa)
	ld	xwa, 4:i3
	ld	de, 3:i3
	call	Audio_ResetAfterPayloadError_Helper
	call	SeqTimer_UpdateTempoReg
AccBankData_PostModeChange:
	ldw wa, 0x16
	call UI_PostModeChangeEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

AccBankData_CopyDataBlock:
	lda	xbc, (18458:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
AccBankData_ReInit_ScanLoop_Code_Loop:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, AccBankData_ReInit_ScanLoop_Code_Loop
	ret
StyleBuf_ClearAllEntries:
	lda	xbc, (16108:16)
	ld	xwa, xbc
	lda	xbc, (xbc+2048)
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
	lda	xbc, (18416:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
StyleConv_ClearWorkBuf_Loop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	lda	xwa, (18156:16)
	ld	xbc, xwa
	lda	xde, (16108:16)
	lda	xhl, (xwa+256)
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
	ld	hl, ix
	mul	hl, 37
	lda	xde, (21832:16)
	ld	bc, hl
	extz	xbc
	add	xbc, xde
	ld	wa, ix
	extz	xwa
	div	wa, 20
	ld	wa, qwa
	ld	(xbc), a
	ld	iz, 0:i3
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
	lda	xwa, (21696:16)
	ld	xbc, xwa
	lda	xde, (18496:16)
	lda	xhl, (xwa+128)
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
	ld	xbc, 1114114
	ld	a, (35994:16)
	cp	a, 21
	jr	z, DialCalc_SetMode15
	cp	a, 18
	jr	z, DialCalc_SetMode12
	cp	a, 17
	jr	nz, PostEventSetup_Send
	ld	xbc, 1114114
	jr	PostEventSetup_Send
DialCalc_SetMode12:
	ld xbc, 0x120002
	jr PostEventSetup_Send

DialCalc_SetMode15:
	ld xbc, 0x150002

PostEventSetup_Send:
	ld	xwa, xbc
	ld	bc, (xsp+4)
	add	bc, qiz
	mul	bc, 37
	lda	xhl, (21832:16)
	ld	de, bc
	extz	xde
	add	xde, xhl
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	inc	1, qiz
	ld	wa, qiz
	cp	wa, iz
	jr	c, DialCalc_EventLoop
DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret

StylCnvWaitTtlFunc:
	cp	xbc, EVT_SW_IN
	jr	z, AccChord_ReturnZero
	cp	xbc, EVT_ACTIVATE_STATE
	jr	nz, AccChord_ReturnZero
	cp	xde, 3
	jr	z, StylCnvWait_HandleClose
	cp	xde, 8
	jr	z, AccChord_ReturnZero
	cp	xde, 2
	jr	nz, AccChord_ReturnZero
	cp	(0x8c9b:16), 96
	jr	nz, StylCnvWait_CheckPending
	calr	StyleConv_InitEntryTable
	ld	(0x3c6a:16), 0
	calr	AccDisplay_FullInit
	call	FileIO_CheckMediaIsWritable
	cp	hl, 0:i3
	jr	nz, StylCnvWait_SetStatus
	ldw	wa, 17
	call	UI_PostModeChangeEvent
StylCnvWait_SetStatus:
	ld	(18494:16), 0
	jr	AccChord_ReturnZero
StylCnvWait_CheckPending:
	cp	(0x483e:16), 0
	jr	z, AccChord_ReturnZero
	ld	(0x7ea6:16), 74
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	ld	(0x483e:16), 0
	jr	AccChord_ReturnZero
StylCnvWait_HandleClose:
	cp	(0x8c9a:16), 96
	jr	z, StylCnvWait_RestoreDisplay
	cp	(0x8c98:16), 6
	jr	z, AccChord_ReturnZero
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
	cp	(0x8c98:16), 6
	call	nz, (0xf6b8d2:24)
StylCnvTxt_ReturnZero:
	ld xhl, 0:i3
	ret

StylCnvModlTtlFunc:
	lda	xsp, (xsp-36)
	push	xiz
	ld	xhl, xde
	ld	de, (15464:16)
	ld	iz, de
	ld	wa, (14822:16)
	cp	xbc, EVT_SW_IN
	jrl	z, StylCnvModl_HandleOK
	cp	xbc, EVT_ACTIVATE_STATE
	jrl	nz, StylCnvModl_Return
	cp	xhl, 4
	jrl	z, StylCnvModl_HandleOpenItem
	cp	xhl, 5
	jrl	z, StylCnvModl_HandleClose
	cp	xhl, 3
	jrl	z, StylCnvModl_HandleRedraw
	cp	xhl, 8
	jrl	z, StylCnvModl_HandleScroll
	cp	xhl, 2
	jrl	nz, StylCnvModl_Return
	calr	DialUI_PostInitEvents
	ld	(18494:16), 0
	ld	xwa, StylCnvModl_CnvFilter
	call	ControlState_ProcessCommand
	ldw	(14822:16), 0
	ld	iz, 0:i3
StylCnvModl_ScanMatchingModels:
	ld	bc, iz
	mul	bc, 37
	lda	xwa, (21832:16)
	extz	xbc
	add	xbc, xwa
	lda	xwa, (xbc+1)
	lda	xbc, (xbc+33)
	call	FileIO_SearchStringMatch
	cp	hl, 0:i3
	jr	nz, StylCnvModl_ScanDone
	incw	1, (14822:16)
	inc	1, iz
	cp	iz, 256
	jr	c, StylCnvModl_ScanMatchingModels
StylCnvModl_ScanDone:
	cpw	(0x39e6:16), 0
	jr	nz, StylCnvModl_PadModelNames
	ldw	wa, 16
	jrl	StylCnvModl_OK_Select_ShowError
StylCnvModl_PadModelNames:
	cp	iz, 256
	jr	nc, StylCnvModl_InitListDisplay
	lda	xhl, (21832:16)
	ld	bc, iz
	mul	bc, 37
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
	ldw	(15464:16), 0
	ld	xwa, 1114114
	ld	xbc, EVT_SET_SELECTED_LINE
	ld	xde, 0:i3
	call	ApPostEvent
	lda	xbc, (16076:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
StylCnvModl_ClearDisplayBuf:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, StylCnvModl_ClearDisplayBuf
	ld	xwa, StylCnvModl_VerFilter
	call	ControlState_ProcessCommand
	lda	xbc, (xsp+36)
	ld	xwa, 16076
	call	FileIO_SearchStringMatch
	lda	xwa, (16076:16)
	cp	hl, 0:i3
	jr	nz, StylCnvModl_CopyDefaultName
	pushw	46
	push	xwa
	call	Sprintf_StringLength
	inc	6, xsp
	or	xhl, xhl
	jr	z, StylCnvModl_FormatFilename
	ld	(xhl), 0
StylCnvModl_FormatFilename:
	ld	iy, 0:i3
	lda	xde, (16076:16)
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
	pushw	0
	pushw	58124
	push	xwa
	call	Free_Compare2
	inc	8, xsp
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
	cp (0x8c9a:16), 0x60
	jr z, StylCnvModl_RedrawDone
	cp (0x8c98:16), 0x06
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
	ld	(15464:16), de
StylCnvModl_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvModl_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, StylCnvModl_Return
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1114114
	ld	xbc, EVT_SET_SELECTED_LINE
	call	ApPostEvent
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, StylCnvModl_OK_PageRedraw
	mul	iz, 37
	lda	xwa, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xwa
	ld	xwa, 1114114
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	de, (15464:16)
	mul	de, 37
	lda	xwa, (21832:16)
	extz	xde
	add	xde, xwa
	ld	xwa, 1114114
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jrl	StylCnvModl_Return
StylCnvModl_OK_ScrollUp:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, (15464:16)
	cp	wa, 0:i3
	jrl	z, StylCnvModl_OK_LoadSelection
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvModl_OK_UpdateDisplay
StylCnvModl_OK_ScrollDown:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, StylCnvModl_OK_LoadSelection
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvModl_OK_UpdateDisplay
StylCnvModl_OK_PageDown:
	ld bc, de
	add bc, 0x14
	ld hl, wa
	cp bc, wa
	jr nc, StylCnvModl_OK_PageDown_Clamp
	add de, 0x14
	jrl StylCnvModl_OK_StoreSelection

StylCnvModl_OK_PageDown_Clamp:
	ld	bc, hl
	dec	1, bc
	ld	ix, bc
	extz	xix
	div	ix, 20
	extz	xde
	div	de, 20
	cp	de, ix
	jrl	nc, StylCnvModl_OK_LoadSelection
	extz	xhl
	div	hl, 20
	ld	wa, qhl
	cp	wa, 0:i3
	jrl	z, StylCnvModl_OK_LoadSelection
	ld	(15464:16), bc
	jrl	StylCnvModl_OK_UpdateDisplay
StylCnvModl_OK_SelectItem:
	mul	de, 37
	lda	xwa, (21833:16)
	extz	xde
	add	xde, xwa
	ld	xwa, xde
	ld	xbc, StylCnv_ModeRb_Select
	call	FileIO_OpenWithBuiltPath
	cp	hl, 0:i3
	jr	ge, StylCnvModl_OK_Select_ClearMem
	ldw	wa, 16
	jr	StylCnvModl_OK_Select_ShowError
StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	ld xwa, 0:i3

StylCnvModl_OK_Select_FillLoop:
	ld	(xbc+), 0
	inc	1, xwa
	cp	xwa, 196608
	jr	c, StylCnvModl_OK_Select_FillLoop
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21865:16)
	extz	xbc
	add	xbc, xwa
	ld	xbc, (xbc)
	ld	xwa, 524288
	call	FileIO_ReadBlock
	cp	xhl, 0
	jr	ge, StylCnvModl_OK_Select_LoadOK
	call	FileIO_CloseHandle
	ldw	wa, 16
StylCnvModl_OK_Select_ShowError:
	call UI_PostModeChangeEvent
	jrl StylCnvModl_Return

StylCnvModl_OK_Select_LoadOK:
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21865:16)
	extz	xbc
	add	xbc, xwa
	ld	xbc, (xbc)
	ld	xwa, xbc
	and	xwa, 255
	jr	z, StylCnvModl_OK_Select_AlignSize
	and	xbc, 4294967040
	add	xbc, 256
StylCnvModl_OK_Select_AlignSize:
	add	xbc, 524288
	ld	(15552:16), xbc
	call	FileIO_CloseHandle
	ld	(1047550:24), 0
	ld	wa, (15464:16)
	ld	(18448:16), wa
	ld	iz, 0:i3
	lda	xhl, (58116:16)
	ld	wa, (15464:16)
	mul	wa, 37
	lda	xbc, (21832:16)
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
	cp	iz, 8
	scc16	z, wa
	ld	(18448:16), wa
	ld	(1047552:24), 255
	ld	(1047553:24), 0
	pushw	4
	ld	wa, (15464:16)
	mul	wa, 37
	extz	xwa
	add	xwa, xbc
	lda	xwa, (xwa+33)
	push	xwa
	ld	xwa, 1047554
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21865:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	(15548:16), xwa
	calr	TableData_JumpToEntry
	calr	FloppyState_Dispatch
	jr	StylCnvModl_Return
StylCnvModl_OK_PageRedraw:
	ld	bc, (14822:16)
	ldw	wa, 20
StylCnvModl_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvModl_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 36)
	ret
StylCnvModl_End:

StylCnvCnvtTtlFunc:
	push	xiz
	ld	hl, (15464:16)
	ld	iz, hl
	ld	ix, (14822:16)
	cp	xbc, EVT_SW_IN
	jrl	z, StylCnvCnvt_HandleOK
	cp	xbc, EVT_ACTIVATE_STATE
	jrl	nz, StylCnvCnvt_Return
	cp	xde, 4
	jrl	z, StylCnvCnvt_HandleOpenItem
	cp	xde, 5
	jrl	z, StylCnvCnvt_HandleClose
	cp	xde, 3
	jrl	z, StylCnvCnvt_HandleRedraw
	cp	xde, 8
	jrl	z, StylCnvCnvt_HandleScroll
	cp	xde, 2
	jrl	nz, StylCnvCnvt_Return
	ld	(18494:16), 0
	calr	DialUI_PostInitEvents
	ldw	(14822:16), 0
	ld	iz, 0:i3
StylCnvCnvt_ScanMatchingStyles:
	ld	bc, iz
	mul	bc, 37
	lda	xwa, (21832:16)
	extz	xbc
	add	xbc, xwa
	lda	xwa, (xbc+1)
	lda	xbc, (xbc+33)
	call	FileIO_SearchStringMatch
	cp	hl, 0:i3
	jr	nz, StylCnvCnvt_PadStyleNames
	incw	1, (14822:16)
	inc	1, iz
	cp	iz, 256
	jr	c, StylCnvCnvt_ScanMatchingStyles
StylCnvCnvt_PadStyleNames:
	cp	iz, 256
	jr	nc, StylCnvCnvt_InitListDisplay
	lda	xhl, (21832:16)
	ld	bc, iz
	mul	bc, 37
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
	ldw	(15464:16), 0
	ld	xwa, 1179650
	ld	xbc, EVT_SET_SELECTED_LINE
	ld	xde, 0:i3
	call	ApPostEvent
	jrl	StylCnvCnvt_Return
StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	cp (0x8c98:16), 0x06
	call nz, (Display_RestoreEntry:24)
	ld wa, 0:i3
	jr t, StylCnvCnvt_CallReturnAction
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
	ld	(15464:16), hl
StylCnvCnvt_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvCnvt_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, StylCnvCnvt_Return
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1179650
	ld	xbc, EVT_SET_SELECTED_LINE
	call	ApPostEvent
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, StylCnvCnvt_OK_PageRedraw
	mul	iz, 37
	lda	xwa, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xwa
	ld	xwa, 1179650
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	de, (15464:16)
	mul	de, 37
	lda	xwa, (21832:16)
	extz	xde
	add	xde, xwa
	ld	xwa, 1179650
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jrl	StylCnvCnvt_Return
StylCnvCnvt_OK_ScrollUp:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, (15464:16)
	cp	wa, 0:i3
	jrl	z, StylCnvCnvt_OK_LoadSelection
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvCnvt_OK_UpdateDisplay
StylCnvCnvt_OK_ScrollDown:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, StylCnvCnvt_OK_LoadSelection
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvCnvt_OK_UpdateDisplay
StylCnvCnvt_OK_PageDown:
	ld wa, hl
	add wa, 0x14
	ld de, ix
	cp wa, ix
	jr nc, StylCnvCnvt_OK_PageDown_Clamp
	add hl, 0x14
	jrl StylCnvCnvt_OK_StoreSelection

StylCnvCnvt_OK_PageDown_Clamp:
	ld	bc, de
	dec	1, bc
	ld	ix, bc
	extz	xix
	div	ix, 20
	extz	xhl
	div	hl, 20
	cp	hl, ix
	jrl	nc, StylCnvCnvt_OK_LoadSelection
	extz	xde
	div	de, 20
	ld	wa, qde
	cp	wa, 0:i3
	jrl	z, StylCnvCnvt_OK_LoadSelection
	ld	(15464:16), bc
	jrl	StylCnvCnvt_OK_UpdateDisplay
StylCnvCnvt_OK_SelectItem:
	ld	a, (15466:16)
	cp	a, 2:i3
	jr	z, StylCnvCnvt_OK_Select_WriteStyle
	cp	a, 1:i3
	jr	nz, StylCnvCnvt_Return
	ld	wa, (18448:16)
	cp	wa, 1:i3
	jr	z, StylCnvCnvt_OK_Select_Finalize
	cp	wa, 0:i3
	jr	z, StylCnvCnvt_OK_Select_Finalize
	jr	StylCnvCnvt_Return
StylCnvCnvt_OK_Select_WriteStyle:
	ld	xwa, (15552:16)
	ld	(15556:16), xwa
	call	FileIO_CheckMediaIsWritable
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21833:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, xbc
	call	FileIO_NormalizePath
StylCnvCnvt_OK_Select_Finalize:
	ld (0x0ffc00:24), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvCnvt_Return

StylCnvCnvt_OK_PageRedraw:
	ld	bc, (14822:16)
	ldw	wa, 20
StylCnvCnvt_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvCnvt_Return:
	ld xhl, 0:i3
	pop xiz
	ret
StylCnvCnvt_End:

StylCnvSelTtlFunc:
	push	xiz
	ld	xhl, xbc
	ld	ix, (15464:16)
	ld	iz, ix
	ld	bc, (14822:16)
	cp	xhl, EVT_SW_IN
	jr	z, StylCnvSel_HandleOK
	cp	xhl, EVT_ACTIVATE_STATE
	jrl	nz, StylCnvSel_Return
	cp	xde, 4
	jr	z, StylCnvSel_HandleOpenItem
	cp	xde, 5
	jr	z, StylCnvSel_HandleClose
	cp	xde, 3
	jr	z, StylCnvSel_HandleRedraw
	cp	xde, 8
	jr	z, StylCnvSel_HandleScroll
	cp	xde, 2
	jrl	nz, StylCnvSel_Return
	calr	DialUI_PostInitEvents
	ldw	(15464:16), 0
	ld	xwa, 1376258
	ld	xbc, EVT_SET_SELECTED_LINE
	ld	xde, 0:i3
	call	ApPostEvent
	jrl	StylCnvSel_Return
StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	cp	(0x8c98:16), 6
	call	nz, (0xf6b8d2:24)
	ld	wa, 0:i3
	jr	StylCnvSel_CallReturnAction
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
	ld	(15464:16), ix
StylCnvSel_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvSel_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, StylCnvSel_Return
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1376258
	ld	xbc, EVT_SET_SELECTED_LINE
	call	ApPostEvent
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, StylCnvSel_OK_PageRedraw
	mul	iz, 37
	lda	xbc, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	xwa, 1376258
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	ld	wa, (15464:16)
	mul	wa, 37
	lda	xbc, (21832:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, 1376258
	ld	xbc, EVT_PARA_DRAW
	call	ApPostEvent
	jrl	StylCnvSel_Return
StylCnvSel_OK_ScrollUp:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	wa, (15464:16)
	cp	wa, 0:i3
	jrl	z, StylCnvSel_OK_LoadSelection
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvSel_OK_UpdateDisplay
StylCnvSel_OK_ScrollDown:
	ld	wa, 1:i3
	call	UI_PostEvent_0x6E
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, StylCnvSel_OK_LoadSelection
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	StylCnvSel_OK_UpdateDisplay
StylCnvSel_OK_PageDown:
	ld wa, ix
	add wa, 0x14
	ld de, bc
	cp wa, bc
	jr nc, StylCnvSel_OK_PageDown_Clamp
	add ix, 0x14
	jrl StylCnvSel_OK_StoreSelection

StylCnvSel_OK_PageDown_Clamp:
	ld	bc, de
	dec	1, bc
	ld	hl, bc
	extz	xhl
	div	hl, 20
	ld	wa, ix
	extz	xwa
	div	wa, 20
	cp	wa, hl
	jrl	nc, StylCnvSel_OK_LoadSelection
	extz	xde
	div	de, 20
	ld	wa, qde
	cp	wa, 0:i3
	jrl	z, StylCnvSel_OK_LoadSelection
	ld	(15464:16), bc
	jrl	StylCnvSel_OK_UpdateDisplay
StylCnvSel_OK_SelectItem:
	calr	SoundMem_ClearRegion
	ld	(1047552:24), 255
	ld	wa, (15464:16)
	inc	1, a
	ld	(1047553:24), a
	calr	TableData_JumpToEntry
	calr	FloppyState_Dispatch
	jr	StylCnvSel_Return
StylCnvSel_OK_PageRedraw:
	ld	bc, (14822:16)
	ldw	wa, 20
StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	ld xhl, 0:i3
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	cp	xbc, EVT_SW_IN
	jr	z, StylCnvCont_HandleOK
	cp	xbc, EVT_ACTIVATE_STATE
	jrl	nz, AccRhythm_ReturnZero
	cp	xde, 3
	jr	z, StylCnvCont_HandleClose
	cp	xde, 8
	jrl	z, AccRhythm_ReturnZero
	cp	xde, 2
	jrl	nz, AccRhythm_ReturnZero
	cp	(0x483a:16), 0
	jr	z, StylCnvCont_CheckPending
	ld	(0x7ea6:16), 15
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	ld	(0x483a:16), 0
StylCnvCont_CheckPending:
	cp	(0x483e:16), 0
	jr	z, AccRhythm_ReturnZero
	ld	(0x7ea6:16), 74
	ldw	wa, 238
	call	SoundCtrl_SendCommand
	ld	(0x483e:16), 0
	jr	AccRhythm_ReturnZero
StylCnvCont_HandleClose:
	cp	(0x8c98:16), 6
	jr	z, AccRhythm_ReturnZero
	calr	Display_RestoreEntry
	jr	AccRhythm_ReturnZero
StylCnvCont_HandleOK:
	cp	xde, 11
	jr	z, StylCnvCont_NotifyPart
	cp	xde, 10
	jr	nz, AccRhythm_ReturnZero
	ld	(15466:16), 0
	calr	SoundMem_ClearRegion
	ld	(1047552:24), 255
	ld	(1047553:24), 0
	pushw	4
	pushw	0
	pushw	15548
	ld	xwa, 1047554
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	calr	TableData_JumpToEntry
	calr	FloppyState_Dispatch
	jr	AccRhythm_ReturnZero
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
	cp	(0x8c98:16), 6
	call	nz, (0xf6b8d2:24)
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
	ld	(18494:16), 255
	ldw	wa, 16
	jp	UI_PostModeChangeEvent
FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	ld a, (0x0ffc00:24)
	cp a, 0:i3
	jr nz, StylCnvDisp_CheckFE
	cpw (0x4810:16), 0x0001
	jr nz, StylCnvDisp_PostMode13
	calr AccBankData_InitAllSlots
	ld wa, 1:i3
	call UI_PostPartChangeEvent
	jrl t, StylCnv_Epilogue114
StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	cp	a, 254
	jr	nz, StylCnvDisp_CheckType
	ld	(18494:16), 255
	ldw	wa, 22
	jrl	StylCnv_PostModeChange
StylCnvDisp_CheckType:
	cp	a, 3:i3
	jrl	z, StylCnv_Multi_InitAndClear
	cp	a, 4:i3
	jrl	z, StylCnv_DispatchByType
	cp	a, 2:i3
	jr	z, StylCnvDisp_Type2_CheckSubtype
	lda	xbc, (15564:16)
	cp	a, 1:i3
	jr	z, StylCnvDisp_Type1_CopyPath
	cp	a, 5:i3
	jrl	nz, StylCnv_AbortWithError
	ld	xwa, 1047553
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	(15466:16), 5
	ldw	wa, 20
	jrl	StylCnv_PostModeChange
StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xffc01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	ld	a, (1047553:24)
	cp	a, 64
	jrl	z, StylCnv_Type4_Init
	cp	a, 128
	jr	z, StylCnvDisp_Subtype80_Process
	cp	a, 16
	jr	z, StylCnvDisp_Subtype10_Process
	cp	a, 0:i3
	jrl	nz, StyleConv_DispatchSoundMemState
	ld	(15466:16), 1
	ld	xwa, 1047552
	call	ControlState_ProcessCommand
	lda	xbc, (15468:16)
	ld	(xbc), 2
	ld	(xbc+1), 0
	ld	xwa, 1047554
	push	xwa
	lda	xwa, (xbc+2)
	push	xwa
	jr	StylCnvDisp_CopyAndFinalize
StylCnvDisp_Subtype10_Process:
	ld	(15466:16), 2
	ld	xwa, 1047552
	call	ControlState_ProcessCommand
	ld	xwa, 1047552
	push	xwa
	lda	xwa, (15468:16)
	push	xwa
StylCnvDisp_CopyAndFinalize:
	call	Free_Compare2
	inc	8, xsp
	jrl	StylCnv_ClearAndFinalize
StylCnvDisp_Subtype80_Process:
	cp (0x0ffc02:24), 0x2e

	jrl nz, ControlState_Type3

	ld (15466:16), 6

	calr StyleBuf_ClearAllEntries

	calr StyleConv_ClearWorkBuffer

	ldw (xsp + 4), 0x0

	; stdi16 (0x48d8), 0 (v7 patched)
	ldw	(0x483c:16), 0
StylCnvDisp_ScanFileLoop:
	pushw 0x0003
	pushw StylCnv_Str_Stars@hi16
	pushw StylCnv_Str_Stars@lo16
	ld WA,(XSP+0x0a)
	inc 2,WA
	extz XWA
	add XWA,0x000ffc00
	push XWA
	call String_Compare
	add XSP,0x0000000a
	cp hl, 0:i3
	jr z, StylCnv_ParseEntry_Done
	ld WA,(XSP+0x04)
	inc 2,WA
	extz XWA
	add XWA,0x000ffc00
	ld A,(XWA)
	cp A,0x2a
	jrl z, ControlState_Type3
	cp A,0x3f
	jrl z, ControlState_Type3
	ldw (XSP+0x06), 0x0000
StylCnv_ParseEntry_ScanChar:
	ld	wa, (xsp+4)
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	ld	a, (xwa)
	cp	a, 44
	jr	nz, StylCnv_ParseEntry_StoreChar
	incw	1, (18492:16)
	jr	StylCnv_ParseEntry_NextField
StylCnv_ParseEntry_StoreChar:
	ld	bc, (0x483c:16)
	sll	bc, 5
	ld	de, (xsp+6)
	add	de, bc
	lda	xbc, (0x3eec:16)
	extz	xde
	add	xde, xbc
	ld	(xde), a
	incm	1, (xsp+6)
	incm	1, (xsp+4)
	cpw	(xsp+6), 32
	jr	lt, StylCnv_ParseEntry_ScanChar
StylCnv_ParseEntry_NextField:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x80
	jrl lt, StylCnvDisp_ScanFileLoop

StylCnv_ParseEntry_Done:
	ldw	(xsp+4), 0
	ld	ix, (15464:16)
	mul	ix, 37
	lda	xhl, (21832:16)
StylCnv_CopyNameLoop:
	ld	wa, (xsp+4)
	add	wa, ix
	extz	xwa
	add	xwa, xhl
	ld	c, (xwa+1)
	cp	c, 46
	jr	z, StylCnv_CopyName_Finalize
	lda	xde, (0x47f0:16)
	ld	wa, (xsp+4)
	ld	(xde+wa), c
	incm	1, (xsp+4)
	cpw	(xsp+4), 32
	jr	lt, StylCnv_CopyNameLoop
StylCnv_CopyName_Finalize:
	pushw	0
	pushw	16108
	pushw	0
	pushw	18416
	jrl	StylCnv_AppendAndClear
ControlState_Type3:
	ld	(15466:16), 3
	ld	xwa, 1047552
	call	ControlState_ProcessCommand
	jrl	StylCnv_ClearAndFinalize
StylCnv_Type4_Init:
	ld	(15466:16), 4
	lda	xde, (18458:16)
	ld	xwa, xde
	lda	xbc, (xde+32)
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
	ld	wa, (xsp+4)
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	cp	(xwa), 0
	jr	nz, StylCnv_Type4_Advance
	inc	1, iz
	cp	iz, qiz
	jr	nz, StylCnv_Type4_Advance
	incm	1, (xsp+4)
	pushw	4
	ld	wa, (xsp+6)
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	push	xwa
	pushw	0
	pushw	18450
	call	Mem_Copy
	incm	4, (xsp+14)
	pushw	4
	ld	wa, (xsp+16)
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	push	xwa
	pushw	0
	pushw	18454
	call	Mem_Copy
	lda	xsp, (xsp+20)
	jr	StylCnv_Type4_BuildOutput
StylCnv_Type4_Advance:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jrl lt, StylCnv_Type4_MainLoop

StylCnv_Type4_BuildOutput:
	calr	StyleConv_ClearWorkBuffer
	ldw	(xsp+4), 0
	ld	ix, (15464:16)
	mul	ix, 37
	lda	xhl, (21832:16)
StylCnv_Type4_CopyNameLoop2:
	ld	wa, (xsp+4)
	add	wa, ix
	extz	xwa
	add	xwa, xhl
	ld	e, (xwa+1)
	lda	xbc, (0x47f0:16)
	cp	e, 46
	jr	z, StylCnv_Type4_AppendExt
	ld	wa, (xsp+4)
	ld	(xbc+wa), e
	incm	1, (xsp+4)
	cpw	(xsp+4), 32
	jr	lt, StylCnv_Type4_CopyNameLoop2
StylCnv_Type4_AppendExt:
	pushw	0
	pushw	18458
	push	xbc
StylCnv_AppendAndClear:
	call	Strcat
	inc	8, xsp
StylCnv_ClearAndFinalize:
	ld (0x0ffc00:24), 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	ld a, (0x3c6a:16)
	cp a, 6:i3
	jrl z, StylCnv_Type6_Dispatch
	cp a, 4:i3
	jrl z, StylCnv_Type4_OpenFile
	cp a, 3:i3
	jr z, StylCnv_Type3_ProcessFiles
	cp a, 2:i3
	jr z, .Lc_f6cb6c
	cp a, 1:i3
	jrl nz, StyleConv_DispatchSoundMemState
	cp (0x8c9a:16), 0x16
	jrl nz, StylCnv_Epilogue114
	ldw WA, 0x0012
	jrl t, StylCnv_PostModeChange
StylCnv_Type2_CheckSoundMem:
.Lc_f6cb6c:
	cp (0x8c9a:16), 0x16
	jrl nz, StylCnv_Epilogue114

	ldw wa, 0x12

	; jrl StylCnv_PostModeChange (v7 displacement)
	jrl	StylCnv_PostModeChange
StylCnv_Type3_ProcessFiles:
	ld	xwa, (15552:16)
	ld	(xsp+10), xwa
	ldw	(xsp+4), 0
	calr	StyleConv_ClearEntryTables
	calr	StyleFile_ClearAllTables
	ld	xwa, 18416
	ld	xbc, 18412
	call	FileIO_SearchStringMatch
	cp	hl, 0:i3
	jr	lt, StylCnv_Type3_CheckCount	; -> 0xF6CC10
StylCnv_Type3_SearchLoop:
	cpw	(xsp+4), 32
	jr	ge, StylCnv_Type3_SearchNext
	ld	xwa, (0x47ec:16)
	cp	xwa, 0
	jr	lt, StylCnv_Type3_SearchNext
	call	FileIO_ExtractBasename
	push	xhl
	lda	xwa, (xsp+22)
	push	xwa
	call	Free_Compare2
	pushw	0
	pushw	18416
	lda	xwa, (xsp+30)
	push	xwa
	call	Strcat
	lda	xwa, (xsp+34)
	push	xwa
	ld	wa, (xsp+24)
	mul	wa, 100
	lda	xbc, (0x4840:16)
	extz	xwa
	add	xwa, xbc
	push	xwa
	call	Free_Compare2
	lda	xsp, (xsp+24)
	ld	de, (xsp+4)
	sll	de, 2
	lda	xbc, (0x54c0:16)
	extz	xde
	add	xde, xbc
	ld	xwa, (0x47ec:16)
	ld	(xde), xwa
	incm	1, (xsp+4)
StylCnv_Type3_SearchNext:
	ld	xwa, 18416
	ld	xbc, 18412
	call	FileIO_SearchStringMatch
	cp	hl, 0:i3
	jr	ge, StylCnv_Type3_SearchLoop
StylCnv_Type3_CheckCount:
	cpw (xsp + 4), 0x0
	jrl z, StylCnv_AbortWithError
	ldw (xsp + 8), 0x0
	cpw (xsp + 4), 0x0
	jrl le, StylCnv_Type3_BuildFfcBuffer

StylCnv_Type3_LoadFileLoop:
	ld	wa, (xsp+8)
	mul	wa, 100
	lda	xbc, (18496:16)
	extz	xwa
	add	xwa, xbc
	push	xwa
	lda	xwa, (xsp+22)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+18)
	ld	xbc, StylCnv_ModeRb_Type3
	call	FileIO_OpenWithBuiltPath
	cp	hl, 0:i3
	jrl	lt, StylCnv_AbortWithError
	ld	wa, (xsp+8)
	sll	wa, 2
	lda	xbc, (21696:16)
	extz	xwa
	add	xwa, xbc
	ld	xbc, (xwa)
	ld	(18412:16), xbc
	ld	xwa, (xsp+10)
	call	FileIO_ReadBlock
	cp	xhl, 0
	jrl	lt, FileIO_ErrorExit
	ld	bc, (xsp+8)
	sll	bc, 2
	lda	xwa, (18156:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (xsp+10)
	ld	(xbc), xwa
	ld	xwa, (18412:16)
	add	(xsp+10), xwa
	ld	xwa, (xsp+10)
	ld	(15556:16), xwa
	pushw	46
	lda	xwa, (xsp+20)
	push	xwa
	call	Sprintf_StringLength
	inc	6, xsp
	ld	wa, (xsp+8)
	lda	xbc, (16108:16)
	sll	wa, 5
	extz	xwa
	add	xwa, xbc
	or	xhl, xhl
	jr	z, StylCnv_Type3_EmptyName
	push	xhl
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	StylCnv_Type3_CloseFile
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
	pushw	4
	ld	bc, (xsp+18)
	sll	bc, 2
	lda	xwa, (18156:16)
	extz	xbc
	add	xbc, xwa
	push	xbc
	ld	wa, qiz
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc	4, qiz
	ld	iz, 0:i3
	ld	bc, (xsp+16)
	sll	bc, 5
	lda	xde, (16108:16)
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
	ld	xwa, 18416
	ld	xbc, StylCnv_ModeRb_Type4
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jr	lt, StylCnv_AbortWithError
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call	FileIO_SeekAndReadBlock
	cp	hl, 0:i3
	jr	lt, FileIO_ErrorExit
	call	FileIO_SeekWriteBlock_Impl
	ld	(15560:16), xhl
	call	FileIO_SeekRead_ExtReturn
	ld	xwa, (18450:16)
	ld	bc, 0:i3
	call	FileIO_SeekAndReadBlock
	cp	hl, 0:i3
	jr	lt, FileIO_ErrorExit
	ld	xwa, (15552:16)
	ld	xbc, (18454:16)
	call	FileIO_ReadBlock
	cp	xhl, 0
	jr	ge, StylCnv_Type4_ClearAndBuild
FileIO_ErrorExit:
	call FileIO_CloseHandle

StylCnv_AbortWithError:
	calr StylCnv_ReportErrorAndReturn
	jrl StylCnv_Epilogue114

StylCnv_Type4_ClearAndBuild:
	calr	SoundMem_ClearRegion
	ld	(1047552:24), 255
	ld	(1047553:24), 0
	pushw	4
	pushw	0
	pushw	15552
	ld	xwa, 1047554
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ldw	(xsp+4), 0
	lda	xde, (18458:16)
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
	ld wa, (0x4810:16)
	cp wa, 1:i3
	jrl z, StylCnv_Type6_Case1_CopyName
	cp wa, 0:i3
	jrl nz, StyleConv_DispatchSoundMemState
	lda xwa, (0x46ec:16)
	ld XBC,XWA
	lda xde, (xwa+256)
StylCnv_Type6_ClearRegion:
	ld	xwa, 0:i3
	ld	(xbc+), xwa
	cp	xbc, xde
	jr	c, StylCnv_Type6_ClearRegion
	ld	xwa, (15552:16)
	ld	(15556:16), xwa
	ldw	(xsp+4), 0
	cpw	(18492:16), 0
	jrl	ule, StylCnv_Type6_BuildFfcBuffer
StylCnv_Type6_MainLoop:
	ld	iz, 0:i3
	lda	xbc, (18416:16)
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
	ld	de, (xsp+4)
	sll	de, 5
	lda	xwa, (16108:16)
	extz	xde
	add	xde, xwa
	push	xde
	push	xbc
	call	Strcat
	inc	8, xsp
	ld	xwa, 18416
	ld	xbc, StylCnv_ModeRb_Type6
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jrl	lt, StylCnv_Type6_FileOpenError
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call	FileIO_SeekAndReadBlock
	cp	hl, 0:i3
	jrl	lt, StylCnv_Type6_FileReadError
	call	FileIO_SeekWriteBlock_Impl
	ld	(15560:16), xhl
	call	FileIO_SeekRead_ExtReturn
	ld	xwa, (15556:16)
	ld	xbc, (15560:16)
	call	FileIO_ReadBlock
	call	FileIO_CloseHandle
	cp	xhl, 0
	jrl	lt, StylCnv_AbortWithError
	ld	bc, (xsp+4)
	sll	bc, 2
	lda	xwa, (18156:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (15556:16)
	ld	(xbc), xwa
	ld	xwa, (15560:16)
	add	(15556:16), xwa
StylCnv_Type6_AdvanceEntry:
	incw 1, (xsp + 4)

	ld wa, (xsp + 4)

	; cpda16 xwa, 0x48d8 (v7 patched)
	cp	wa, (0x483c:16)
	; jrl c, StylCnv_Type6_MainLoop (v7 displacement)
	jrl	c, StylCnv_Type6_MainLoop
StylCnv_Type6_BuildFfcBuffer:
	calr SoundMem_ClearRegion

	ld (0x0ffc00:24), 0xff

	ld (0x0ffc01:24), 0x00

	ldw (xsp + 4), 0x0

	ld iz, 0:i3

	; cpdi16 0x48d8, 0 (v7 patched)
	cpw	(0x483c:16), 0
	; jrl ule, StylCnv_FinalizeAndCheckStatus (v7 displacement)
	jrl	ule, StylCnv_FinalizeAndCheckStatus
StylCnv_Type6_CopyBlockLoop:
	ld	bc, (xsp+4)
	sll	bc, 2
	lda	xde, (18156:16)
	extz	xbc
	add	xbc, xde
	ld	xwa, (xbc)
	or	xwa, xwa
	jrl	z, StylCnv_Type6_NextBlock	; -> 0xF6CFE3
	pushw	4
	push	xbc
	ld	wa, iz
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc	4, iz
	ldw	(xsp+6), 0
	ld	bc, (xsp+4)
	sll	bc, 5
	lda	xde, (16108:16)
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

	; cpda16 xwa, 0x48d8 (v7 patched)
	cp	wa, (0x483c:16)
	; jrl c, StylCnv_Type6_CopyBlockLoop (v7 displacement)
	jrl	c, StylCnv_Type6_CopyBlockLoop
	; jrl StylCnv_FinalizeAndCheckStatus (v7 displacement)
	jrl	StylCnv_FinalizeAndCheckStatus
StylCnv_Type6_FileReadError:
	ld BC,(XSP+0x04)
	sll BC, 0x05
	lda xwa, (0x3eec:16)
	extz XBC
	add XBC,XWA
	ld (XBC),0x00
	cpw (0x483c:16), 0x0002
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl t, StylCnv_AbortWithError
StylCnv_Type6_FileOpenError:
	ld BC,(XSP+0x04)
	sll BC, 0x05
	lda xwa, (0x3eec:16)
	extz XBC
	add XBC,XWA
	ld (XBC),0x00
	cpw (0x483c:16), 0x0002
	jrl nc, StylCnv_Type6_AdvanceEntry
	jrl t, StylCnv_AbortWithError
StylCnv_Type6_Case1_CopyName:
	ld bc, (0x3c68:16)
	mul BC,0x0025
	lda xwa, (0x5549:16)
	extz XBC
	add XBC,XWA
	push XBC
	lda xwa, (xsp + 0x16)
	push XWA
	call Free_Compare2
	inc 8,XSP
	ld xwa, (0x3cc0:16)
	ld (XSP+0x0a),XWA
	ldw (XSP+0x08), 0x0000
	lda xwa, (xsp + 0x12)
	ld XBC,StylCnv_ModeRb_Type6b
	call FileIO_OpenWithMode
	cp hl, 0:i3
	jrl lt, StylCnv_AbortWithError
	ld xwa, 0:i3
	ld bc, 2:i3
	call FileIO_SeekAndReadBlock
	cp hl, 0:i3
	jrl lt, StylCnv_Epilogue114
	call FileIO_SeekWriteBlock_Impl
	ld (XSP+0x0e),XHL
	call FileIO_SeekRead_ExtReturn
	ld XWA,(XSP+0x0a)
	ld XBC,(XSP+0x0e)
	call FileIO_ReadBlock
	call FileIO_CloseHandle
	cp XHL,0x00000000
	jrl lt, StylCnv_AbortWithError
	ld XWA,(XSP+0x0a)
	ld (0x46ec:16), xwa
	ld XWA,(XSP+0x0e)
	add (XSP+0x0a),XWA
	ldw (XSP+0x04), 0x0000
	lda xwa, (xsp + 0x12)
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
	ld	de, iz
	lda	xbc, (0x3eec:16)
	extz	xde
	add	xde, xbc
	ld	bc, (xsp+4)
	ld	c, (xwa+bc)
	ld	(xde), c
	cp	c, 0:i3
	jr	z, StylCnv_Single_RenameTM
	incm	1, (xsp+4)
	inc	1, iz
	cpw	(xsp+4), 32
	jr	lt, StylCnv_Single_CopyExt_Loop
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
	ld	bc, (xsp+4)
	ld	(xwa+bc), 0x54	; (unidasm; no llvm-mc spelling)
	ld	bc, (xsp+4)
	inc	1, bc
	ld	(xwa+bc), 0x4d	; (unidasm; no llvm-mc spelling)
	ld	bc, (xsp+4)
	inc	2, bc
	.byte	0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x00	; ld (XWA+BC), 0x00 (unidasm; no llvm-mc spelling)
	ld	xbc, StylCnv_ModeRb_Single
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jrl	lt, DRI_ParseFieldsAndOpenFile
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call	FileIO_SeekAndReadBlock
	cp	hl, 0:i3
	jrl	lt, DRI_ParseFieldsAndOpenFile
	ldw	(xsp+8), 1
	call	FileIO_SeekWriteBlock_Impl
	ld	(xsp+14), xhl
	call	FileIO_SeekRead_ExtReturn
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+14)
	call	FileIO_ReadBlock
	call	FileIO_CloseHandle
	cp	xhl, 0
	jrl	lt, StylCnv_AbortWithError
	ld	xwa, (xsp+10)
	ld	(18160:16), xwa
	ld	xwa, (xsp+14)
	add	(xsp+10), xwa
	ldw	(xsp+4), 0
	lda	xbc, (xsp+18)
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
	ld	de, iz
	add	de, 32
	lda	xwa, (0x3eec:16)
	extz	xde
	add	xde, xwa
	ld	wa, (xsp+4)
	ld	a, (xbc+wa)
	ld	(xde), a
	cp	a, 0:i3
	jr	z, DRI_ParseFieldsAndOpenFile
	incm	1, (xsp+4)
	inc	1, iz
	cpw	(xsp+4), 32
	jr	lt, StylCnv_LSW_CopyExt_Loop
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
	ld	bc, (xsp+4)
	ld	(xwa+bc), 0x4c	; (unidasm; no llvm-mc spelling)
	ld	bc, (xsp+4)
	inc	1, bc
	ld	(xwa+bc), 0x53	; (unidasm; no llvm-mc spelling)
	ld	bc, (xsp+4)
	inc	2, bc
	ld	(xwa+bc), 0x57	; (unidasm; no llvm-mc spelling)
	ld	bc, (xsp+4)
	inc	3, bc
	.byte	0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x00	; ld (XWA+BC), 0x00 (unidasm; no llvm-mc spelling)
	ld	xbc, StylCnv_ModeRb_LSW
	call	FileIO_OpenWithMode
	cp	hl, 0:i3
	jrl	lt, FileLoad_ResetAndStartProcessing
	ld	xwa, 0:i3
	ld	bc, 2:i3
	call	FileIO_SeekAndReadBlock
	cp	hl, 0:i3
	jrl	lt, FileLoad_ResetAndStartProcessing
	incw	1, (xsp+8)
	call	FileIO_SeekWriteBlock_Impl
	ld	(xsp+14), xhl
	call	FileIO_SeekRead_ExtReturn
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+14)
	call	FileIO_ReadBlock
	call	FileIO_CloseHandle
	cp	xhl, 0
	jrl	lt, StylCnv_AbortWithError
	ld	bc, (xsp+8)
	ld	(xsp+16), bc
	sla	bc, 2
	lda	xwa, (18156:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (xsp+10)
	ld	(xbc), xwa
	ldw	(xsp+4), 0
	lda	xbc, (xsp+18)
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
	ld	wa, (xsp+16)
	sll	wa, 5
	ld	de, iz
	add	de, wa
	lda	xwa, (0x3eec:16)
	extz	xde
	add	xde, xwa
	ld	wa, (xsp+4)
	ld	a, (xbc+wa)
	ld	(xde), a
	cp	a, 0:i3
	jr	z, FileLoad_ResetAndStartProcessing
	incm	1, (xsp+4)
	inc	1, iz
	cpw	(xsp+4), 32
	jr	lt, StylCnv_LSW_CopyExt3_Loop
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
	pushw 0x0004
	ld BC,(XSP+0x06)
	sll BC, 0x02
	lda xwa, (0x46ec:16)
	extz XBC
	add XBC,XWA
	push XBC
	ld WA,IZ
	inc 2,WA
	extz XWA
	add XWA,0x000ffc00
	push XWA
	call Mem_Copy
	lda xsp, (xsp + 0x0a)
	inc 4,IZ
	ldw (XSP+0x06), 0x0000
	ld BC,(XSP+0x04)
	sll BC, 0x05
	lda xde, (0x3eec:16)
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
	calr	StyleConv_InitEntryTable
	ldw	(14822:16), 0
	lda	xbc, (xsp+18)
	ld	xwa, xbc
	lda	xbc, (xbc+100)
StylCnv_Multi_ClearLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	ld iz, 0:i3

StylCnv_Multi_ParseLoop:
	lda xbc, (0x3ccc:16)
	ld WA,(XSP+0x04)
	lda	xhl, (xbc+wa)
	ld E,(XHL)
	lda xbc, (xsp + 0x12)
	lda xwa, (0x5548:16)
	ld (XSP+0x0e),XWA
	cp e, 0:i3
	jr nz, .Lc_f6d3d7
	cp iz, 0:i3
	jr le, StylCnv_Multi_Finalize
	push XBC
	ld WA,IZ
	dec 1,WA
	mul WA,0x0025
	extz XWA
	add XWA,(XSP+0x12)
	inc 1,XWA
	push XWA
	call Free_Compare2
	inc 8,XSP
	incw 1, (0x39e6:16)
	jr t, StylCnv_Multi_Finalize
StylCnv_Multi_HandleSeparator:
.Lc_f6d3d7:
	cp E,0x7c
	jr nz, StylCnv_Multi_CopyChar
	ld (XHL),0x00
	ldw (XSP+0x06), 0x0000
	inc 1,IZ
	cp iz, 1:i3
	jr le, LoopCounter_Increment
	push XBC
	ld WA,IZ
	dec 2,WA
	mul WA,0x0025
	extz XWA
	add XWA,(XSP+0x12)
	inc 1,XWA
	push XWA
	call Free_Compare2
	inc 8,XSP
	lda xbc, (xsp + 0x12)
	ld XWA,XBC
	lda xbc, (xbc + 0x64)
StylCnv_Multi_ClearSubLoop:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, StylCnv_Multi_ClearSubLoop
	incw	1, (14822:16)
	jr	LoopCounter_Increment
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
	cp	(0xbfe1:16), 65
	ret	nz
	bit	0, (0xbfe3:16)
	ret	z
	ld	c, (0x8c9a:16)
	bit	0, (0xbfe2:16)
	jr	z, AccStyle_TableDataEntry_Skip
	cp	c, 17
	ret	nz
	ldw	wa, 16
	jr	AccStyle_TableDataEntry_Join
AccStyle_TableDataEntry_Skip:
	ld	a, (0x3c6a:16)
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
	ld	xwa, 15468
	call	ControlState_ProcessCommand
	ldw	wa, 18
AccStyle_TableDataEntry_Join:
	call	UI_PostModeChangeEvent
	ret
AccStyle_TableDataEntry_0x90:
	lda	xsp, (xsp-34)
	push	xiz
	ld	(xsp+34), c
	ld	(xsp+36), a
	ld	xiy, AccStyle_SlotOrderB
	lda	xix, (xsp+4)
	ldw	bc, 15
	ldirw
	lda	xde, (0x94800:24)
	lda	xbc, (0xab000:24)
	sub	xbc, xde
	ld	xwa, 432128
	call	FileIO_ReadBlock
	cp	xhl, 0
	jrl	lt, AccStyle_TableDataEntry_Epilogue
	lda	xbc, (0x69800:24)
	ld	(0x7a48:16), xbc
	lda	xwa, (0x94800:24)
	ld	(0x7a4c:16), xwa
	ld	(0x38b4:16), 0
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
	jrl	nz, AccStyle_TableDataEntry_Skip16
	cp_erpb	250, 75
	jrl	nz, AccStyle_TableDataEntry_Skip16
	cp_erpb	251, 69
	jrl	nz, AccStyle_TableDataEntry_Skip16
AccStyle_TableDataEntry_Skip9:
	ld	xwa, (0x7a48:16)
	ld	(xwa), 72
	ld	xwa, (0x7a48:16)
	ld	(xwa+1), 0
	ld	xwa, (0x7a48:16)
	ld	(xwa+2), 75
	ld	xbc, (0x7a4c:16)
	cp	(xsp+36), 29
	jrl	ule, AccStyle_TableDataEntry_Skip14
	cp	(xsp+34), 29
	jrl	ule, AccStyle_TableDataEntry_Skip14
	ld	xwa, (0x7a48:16)
	ld	e, (xwa+14)
	cp	e, 0:i3
	jr	nz, AccStyle_TableDataEntry_Skip10
	cp	(xwa+15), 0
	jr	z, AccStyle_TableDataEntry_Skip11
AccStyle_TableDataEntry_Skip10:
	ld	(xbc+14), e
	ld	xwa, (0x7a48:16)
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
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+34), 64
	ld	a, (xhl)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+42), 12
	ld	a, (xde)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+iz)
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	iz, wa
	add	iz, 96
	ld	xwa, (0x7a48:16)
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
	calr	AccStyle_TableDataEntry_Helper2
AccStyle_TableDataEntry_Join2:
	ld	a, (0x38b4:16)
	extz	wa
	bit	0, wa
	jrl	z, AccStyle_TableDataEntry_Join3
	ld	xwa, (0x7a4c:16)
	ld	(0x3912:16), xwa
	cp	(xsp+34), 30
	jrl	nc, AccStyle_TableDataEntry_Skip21
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	ld	(14608), (xwa+bc)
	call	AccPatch_InitFromSlotIndex
	jrl	AccStyle_TableDataEntry_Join3
AccStyle_TableDataEntry_Skip14:
	cp	(xsp+36), 29
	jr	ule, AccStyle_TableDataEntry_Skip15
	cp	(xsp+34), 30
	jr	c, AccStyle_TableDataEntry_Skip16
AccStyle_TableDataEntry_Skip15:
	cp	(xsp+36), 30
	jr	nc, AccStyle_TableDataEntry_Skip17
	cp	(xsp+34), 29
	jr	ule, AccStyle_TableDataEntry_Skip17
AccStyle_TableDataEntry_Skip16:
	ld	(0x38b4:16), 130
	jrl	AccStyle_TableDataEntry_Join4
AccStyle_TableDataEntry_Skip17:
	ld	(0x3912:16), xbc
	ld	c, (xsp+34)
	extz	bc
	lda	xwa, (xsp+4)
	ld	(14608), (xwa+bc)
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
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+de)
	ld	(xwa+34), 64
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+de)
	ld	(xwa+42), 12
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	de, wa
	add	de, 96
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+de)
	ld	(xwa+50), 116
	ld	a, (xbc)
	extz	wa
	muls	wa, 96
	ld	bc, wa
	add	bc, 96
	ld	xwa, (0x7a48:16)
	lda	xwa, (xwa+bc)
	ld	(xwa+58), 64
AccStyle_TableDataEntry_Skip19:
	ld	xwa, (0x7a48:16)
	ld	(0x3912:16), xwa
	ld	xwa, (0x7a4c:16)
	ld	(0x3916:16), xwa
	ld	a, (xsp+36)
	extz	wa
	lda	xbc, (xsp+4)
	ld	(14608), (xbc+wa)
	ld	a, (xsp+34)
	extz	wa
	ld	(14609), (xbc+wa)
	res	0, (0x3514:16)
	call	DualVoice_ParamLoadDone
	ld	a, (0x3514:16)
	extz	wa
	bit	0, wa
	jr	z, AccStyle_TableDataEntry_Skip20
	ld	(0x38b4:16), 131
	jrl	AccStyle_TableDataEntry_Join2
AccStyle_TableDataEntry_Skip20:
	ld	(0x38b4:16), 0
	jrl	AccStyle_TableDataEntry_Join2
AccStyle_TableDataEntry_Skip21:
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop2:
	ld	c, (xsp+34)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccStyle_SlotOrderA:24)
	ld	(14608), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop2
AccStyle_TableDataEntry_Join3:
	cp	(0x38b4:16), 131
	jr	nz, AccStyle_TableDataEntry_Skip22
	ldw	hl, 65429
	jr	AccStyle_TableDataEntry_Epilogue
AccStyle_TableDataEntry_Skip22:
	call	AccStyle_TableDataEntry_Helper
AccStyle_TableDataEntry_Join4:
	ld	hl, 0:i3
AccStyle_TableDataEntry_Epilogue:
	pop	xiz
	lda	xsp, (xsp+34)
	ret
AccStyle_TableDataEntry_Helper2:
	dec	4, xsp
	push	qiz
	ld	(xsp+2), c
	ld	(xsp+4), a
	ld	xwa, (0x7a4c:16)
	ld	(0x3912:16), xwa
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop3:
	ld	c, (xsp+2)
	sub	c, 30
	extz	bc
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (AccStyle_SlotOrderA:24)
	ld	(14608), (xwa+de)
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop3
	ld	xwa, (0x7a48:16)
	ld	(0x3912:16), xwa
	ld	xwa, (0x7a4c:16)
	ld	(0x3916:16), xwa
	ld	(0x38b4:16), 0
	res	0, (0x3514:16)
	ldib_erp	251, 0
AccStyle_TableDataEntry_Loop4:
	ld	e, (xsp+4)
	sub	e, 30
	extz	de
	ldto_berp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	add	wa, de
	lda	xde, (AccStyle_SlotOrderA:24)
	ld	(14608), (xde+wa)
	ld	a, (xsp+2)
	sub	a, 30
	extz	wa
	add	bc, wa
	ld	(14609), (xde+bc)
	call	DualVoice_ParamLoadDone
	ld	a, (0x3514:16)
	extz	wa
	bit	0, wa
	jr	z, AccStyle_TableDataEntry_Skip23
	ld	(0x38b4:16), 131
	jr	AccStyle_TableDataEntry_Epilogue2
AccStyle_TableDataEntry_Skip23:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, AccStyle_TableDataEntry_Loop4
AccStyle_TableDataEntry_Epilogue2:
	pop	qiz
	inc	4, xsp
	ret
	.include "sequencer/accompseq_routines.s"
