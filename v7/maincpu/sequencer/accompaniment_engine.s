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
	push	xhl
	push	xwa
	xor	xhl, xhl
	ld	l, (36942:16)
	cp	l, 15
	jr	ule, 2
	xor	l, l
AccStyle_LookupTempo_ClampL:
	sla	l, 1
	ld	xwa, 16078891
	ld_rr8w	hl, xwa, l
	xor	xwa, xwa
	ld	a, (36943:16)
	cp	a, 79
	jr	ule, 2
	xor	a, a
AccStyle_LookupTempo_AddAndStore:
	add	xhl, xwa
	sla	xhl, 1
	add	xhl, 14981983
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
	add XHL,Display_FontPalette_Table_0x4507
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
	add	xhl, 14982739
	ld	wa, (xhl)
	jr	26
AccStyle_Velocity_HighRange:
	xor	xhl, xhl
	ld	l, (36942:16)
	and	l, 15
	cps	l, 4
	jr	ule, 2
	xor	l, l
AccStyle_Velocity_HighClamp:
	sla xhl, 1
	add xhl, Display_FontPalette_Table_0x50FB
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
	call 0xfe09be
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
	ldb A, 0x00
	ldb W, 0x00
	ldb D, 0x05
	ldb E, 0x48
	call Rhythm_QueuePartChangeEvent
AccStyle_DetectChanges_QueueDone:
	bit 2, (0xfc60:16)
	jr z, AccStyle_DetectChanges_MarkDirty
	and (0xfc60:16), 251
	ldb a, 0x0
	ldb w, 0x0
	ldb d, 0x6
	ldb e, 0x48
	call Rhythm_QueuePartChangeEvent

AccStyle_DetectChanges_MarkDirty:
	.byte 0xc1, 0x9f, 0x32, 0x3e, 0x01	; ordi8 0x333b, 1 (v7 patched)



AccStyle_DetectChanges_CompareParams:
	bit 0, (0x3257:16)
	jr nz, .Lc_f559c1
	call Rhythm_SendChanPressure
	or (0x329f:16), 0x01
	jrl t, AccStyle_DetectChanges_Epilogue
AccStyle_Compare_StyleNumber:
.Lc_f559c1:
	ld a, (0x3259:16)
	.byte 0xc1, 0x5a, 0x32, 0xf1, 0x66, 0x05, 0xc1, 0x9f
	.byte 0x32, 0x3e, 0x01
AccStyle_Compare_StyleNumDone:
	.byte 0xc1, 0x5b, 0x32, 0x21, 0xc1, 0x5c, 0x32, 0xf1
	.byte 0x66, 0x05, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_Variation:
	.byte 0xc1, 0x5d, 0x32, 0x21, 0xc9, 0xcc, 0x07, 0xc1
	.byte 0x5e, 0x32, 0xf1, 0x66, 0x05, 0xc1, 0x9f, 0x32
	.byte 0x3e, 0x01
AccStyle_Compare_VariationDone:
	.byte 0xf1, 0x31, 0x34, 0xcf, 0x66, 0x0a, 0xc1, 0x31
	.byte 0x34, 0x3c, 0x7f, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_RegistrationFlag:
	.byte 0xc1, 0x99, 0x32, 0x21, 0xc1, 0x56, 0x32, 0xd1
	.byte 0xc9, 0xcc, 0x02, 0xc9, 0xd8, 0x66, 0x07, 0xc1
	.byte 0x9f, 0x32, 0x3e, 0x01, 0x68, 0x52
AccStyle_Compare_SplitA:
	.byte 0xc1, 0x63, 0x32, 0x21, 0xc1, 0x64, 0x32, 0xf1
	.byte 0x66, 0x05, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_SplitADone:
	.byte 0xc1, 0x65, 0x32, 0x21, 0xc1, 0x66, 0x32, 0xf1
	.byte 0x66, 0x05, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_LayerA:
	.byte 0xc1, 0x69, 0x32, 0x21, 0xc1, 0x6a, 0x32, 0xf1
	.byte 0x66, 0x05, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_LayerADone:
	.byte 0xc1, 0x6b, 0x32, 0x21, 0xc1, 0x6c, 0x32, 0xf1
	.byte 0x66, 0x05, 0xc1, 0x9f, 0x32, 0x3e, 0x01
AccStyle_Compare_TuningState:
	.byte 0xc1, 0x4c, 0x33, 0x21, 0xc1, 0x4d, 0x33, 0xd1
	.byte 0xc9, 0x33, 0x00, 0x66, 0x05, 0xc1, 0x9f, 0x32
	.byte 0x3e, 0x01
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
	calr	1107
	ld	a, (1075:16)
	ld	(1112:16), a
	ld	(12880:16), 1
	call	16071509
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
	call	16114717
	ret
AccStyle_ApplyStandardStyle:
	ld	a, (12905:16)
	and	a, 3
	ld	(12956:16), a
	ld	(12958:16), a
	ld	a, (12873:16)
	ld	h, (12874:16)
	call	16071062
	ld	(12850:16), xiy
	call	16071076
	call	16069751
	ld	xiy, (12850:16)
	call	16080751
	ld	xiy, (12850:16)
	ld	a, (12899:16)
	and	a, 7
	jr	z, 5
	calr	449
	jr	21
AccStyle_ApplyStd_LoadTuning:
	calr 19

	ld a, (12807:16)

	ldb w, 0x0

	.byte 0x1e, 0xb2, 0x04	; calr AccPart_GetVoiceParamOffsetTable (v7 displacement)

	.byte 0x1d, 0x07, 0x3a, 0xf5	; call AccVoice_LoadTuningBlock (v7 addr)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)



AccStyle_ApplyStd_Return:
	ret

AccStyle_SetupPartAddresses:
	.byte 0xc3, 0xf5, 0xd1, 0x03, 0x21, 0xf1, 0xe9, 0x31
	.byte 0x41, 0xf1, 0x38, 0x33, 0x00, 0x01, 0xc1, 0x07
	.byte 0x32, 0x21, 0x1e, 0x8b, 0x05, 0x1d, 0xcc, 0x68
	.byte 0xf5, 0xf1, 0xeb, 0x31, 0x50, 0xf1, 0x38, 0x33
	.byte 0x00, 0x02, 0xc1, 0x08, 0x32, 0x21, 0x1e, 0x77
	.byte 0x05, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xed, 0x31
	.byte 0x50, 0xf1, 0x38, 0x33, 0x00, 0x04, 0xc1, 0x09
	.byte 0x32, 0x21, 0x1e, 0x63, 0x05, 0x1d, 0xcc, 0x68
	.byte 0xf5, 0xf1, 0xef, 0x31, 0x50, 0xf1, 0x38, 0x33
	.byte 0x00, 0x08, 0xc1, 0x0a, 0x32, 0x21, 0x1e, 0x4f
	.byte 0x05, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf1, 0x31
	.byte 0x50, 0xf1, 0x38, 0x33, 0x00, 0x10, 0xc1, 0x0b
	.byte 0x32, 0x21, 0x1e, 0x3b, 0x05, 0x1d, 0xcc, 0x68
	.byte 0xf5, 0xf1, 0xf3, 0x31, 0x50, 0xf1, 0x38, 0x33
	.byte 0x00, 0x20, 0xc1, 0x0c, 0x32, 0x21, 0x1e, 0x27
	.byte 0x05, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf5, 0x31
	.byte 0x50, 0x40, 0xb9, 0x6b, 0xe4, 0x00, 0xe8, 0xc8
	.byte 0x06, 0x00, 0x00, 0x00, 0xf1, 0xf7, 0x31, 0x60
	.byte 0xc1, 0x7a, 0x32, 0x3c, 0xc0, 0xc1, 0x7b, 0x32
	.byte 0x3c, 0xc0, 0xc1, 0x7c, 0x32, 0x3c, 0xc0, 0x0e
AccStyle_ApplyExtendedStyle:
	ld	xiy, 14969849
	ld	a, (12873:16)
	and	a, 127
	cp	a, 29
	jr	ule, 2
	xor	a, a
AccStyle_ApplyExt_ClampIndex:
	ld_rr8b	a, xiy, a
	ld	(12956:16), a
	ld	a, (12873:16)
	and	a, 127
	call	16070940
	ld	(12850:16), xiy
	ld	l, (xiy+16)
	ld	h, (xiy+17)
	and	h, 15
	and	h, 7
	cp	hl, 520
	jr	z, 10
	cp	hl, 792
	jr	z, 4
	call	16068659
AccStyle_ApplyExt_SkipClamp:
	ld	a, l
	call	16071062
	ld	(12855:16), xiy
	call	16071076
	ld	w, (12873:16)
	call	16073348
	.byte 0xf1, 0xc7, 0x32, 0xc8
	jr	nz, 4
	call	16069612
AccStyle_ApplyExt_CheckSplit:
	ld	a, (12899:16)
	and	a, 7
	jrl	z, 132
	.byte 0xf1, 0xc7, 0x32, 0xc8
	jrl	z, 130
	.byte 0xf1, 0x63, 0x32, 0xc9
	jr	z, 40
	ld	a, (1075:16)
	ld	xhl, 14969776
	.byte 0xf3, 0x03, 0xec, 0xe0, 0xc8
	jr	z, 108
	.byte 0xc1, 0x63, 0x32, 0x3c, 0xfd, 0xc1, 0x5f, 0xfc, 0x3c, 0xf7
	ldb	e, 72
	ldb	d, 5
	ldb	a, 0
	ldb	w, 0
	call	16068843
	jr	79
AccStyle_ApplyExt_CheckBit0:
	.byte 0xf1, 0x63, 0x32, 0xc8
	jr	z, 34
	ld	a, (13000:16)
	cp	a, (1075:16)
	jr	z, 58
	.byte 0xc1, 0x63, 0x32, 0x3c, 0xfe, 0xc1, 0x5f, 0xfc, 0x3c, 0xfb
	ldb	e, 72
	ldb	d, 5
	ldb	a, 0
	ldb	w, 0
	call	16068843
	jr	39
AccStyle_ApplyExt_CheckBit1:
	ld	a, (13002:16)
	cp	a, (1075:16)
	jr	z, 24
	.byte 0xc1, 0x63, 0x32, 0x3c, 0xfb, 0xc1, 0x60, 0xfc, 0x3c, 0xfb
	ldb	e, 72
	ldb	d, 5
	ldb	a, 0
	ldb	w, 0
	call	16068843
	jr	5
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
	calr	8
AccStyle_ApplyExt_UpdateTuning:
	ld	xiy, (12855:16)
	calr	493
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
	ldb W, 0x03
	bit 2, (0x3263:16)
	jr z, AccVoice_SelectPartOffset_SetModeW
	ldb W, 0x04
AccVoice_SelectPartOffset_SetModeW:
	calr AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_SelectPartOffset_Apply63:
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f, 0xf1, 0x63, 0x32
	.byte 0xc8, 0x66, 0x11, 0xc1, 0x7a, 0x32, 0x3e, 0x3f
	.byte 0xc1, 0x7b, 0x32, 0x3c, 0xc0, 0xc1, 0x7c, 0x32
	.byte 0x3c, 0xc0, 0x68, 0x26
AccVoice_SelectPartOffset_Bit1:
	.byte 0xf1, 0x63, 0x32, 0xc9, 0x66, 0x11, 0xc1, 0x7a
	.byte 0x32, 0x3c, 0xc0, 0xc1, 0x7b, 0x32, 0x3e, 0x3f
	.byte 0xc1, 0x7c, 0x32, 0x3c, 0xc0, 0x68, 0x0f
AccVoice_SelectPartOffset_Mode3:
	.byte 0xc1, 0x7a, 0x32, 0x3c, 0xc0	; anddi8 (0x3316), 192 (v7 patched)

	.byte 0xc1, 0x7b, 0x32, 0x3c, 0xc0	; anddi8 (0x3317), 192 (v7 patched)

	.byte 0xc1, 0x7c, 0x32, 0x3e, 0x3f	; ordi8 0x3318, 63 (v7 patched)



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
	call	16091457
	ld	xwa, 14969785
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
	call	16093665
	ld	xhl, 11000
	call	16093665
	ld	xhl, 11256
	call	16093665
	ld	xhl, 11512
	call	16093665
	ld	xhl, 11768
	call	16093665
	ld	xhl, 12024
	call	16093665
	ret
AccBuf_InitKbd1WithMarkers:
	ld XHL,0x000029f8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x00, 0xd0, 0x1d, 0x55
	.byte 0x3c, 0xf5, 0xf3, 0x07, 0xec, 0xf4, 0x00, 0x01
	.byte 0x1d, 0x55, 0x3c, 0xf5, 0xf3, 0x07, 0xec, 0xf4
	.byte 0x00, 0x10, 0x1d, 0x55, 0x3c, 0xf5, 0xf3, 0x07
	.byte 0xec, 0xf4, 0x00, 0x01, 0x1d, 0x55, 0x3c, 0xf5
	.byte 0xbb, 0x04, 0x55, 0x0e
Rhythm_SendResetMsg:
	ldb a, 0xd8
	ldb w, 0x10
	ldb e, 0x0
	call Rhythm_Send3ByteMsg
	ret

Rhythm_UpdateTuningConfig:
	ld	w, (12860:16)
	ld	a, (12956:16)
	calr	36
	ld	(12807:16), a
	ld	(12808:16), a
	ld	(12809:16), a
	ld	(12810:16), a
	ld	(12811:16), a
	ld	(12812:16), a
	ld	w, (12860:16)
	ld	a, (12956:16)
	calr	18
	ret
Rhythm_LookupTuningByStyle:
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld xhl, AccVoice_ParamIndexData_0x5B
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

Rhythm_LookupTuningRange:
	cp (0x3249:16), 0x80
	jr nc, Rhythm_LookupTuning_DefaultRange
	calr Rhythm_LookupStyleIndex
	calr AccVoice_LookupParamIndex
	ld XHL,AccVoice_ParamIndexData_0x63
	sla A, 0x01
	.byte 0xd3, 0x03, 0xec, 0xe0, 0x23, 0xd3, 0x07, 0xf4
	.byte 0xec, 0x20, 0x68, 0x04
Rhythm_LookupTuning_DefaultRange:
	ldb a, 0x39
	ldb w, 0x39

Rhythm_StoreTuningRange:
	ld	(12963:16), a
	ld	(12964:16), w
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
	max
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
	ld_rrb a, xiy, wa
	ret
	nop
	nop
	normal
	normal
	nop
	push	sr
	normal
	normal
	push	sr
	normal
	normal
	normal
	normal
	nop
	normal
	normal
	normal
	normal
	normal
	normal
	push	sr
	normal
	normal
	nop
	normal
	normal
	normal
	normal
	normal
	nop
	normal
	normal
	normal
	normal
	normal
	normal
	normal
	normal
	normal
	normal
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
	ld_spdb h, 0
	normal
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
	max
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
	.byte 0x43, 0x46, 0x62, 0xf5, 0x00, 0xc8, 0xec, 0x01
	.byte 0xd3, 0x03, 0xec, 0xe1, 0x23, 0xeb, 0x12, 0xed
	.byte 0x83, 0xc1, 0x38, 0x33, 0x3f, 0x01, 0x6e, 0x05
	.byte 0x8b, 0x00, 0x20, 0x68, 0x35
AccStyle_ReadParamOff_Part2:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x02, 0x6e, 0x05, 0x8b
	.byte 0x00, 0x20, 0x68, 0x29
AccStyle_ReadParamOff_Part4:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x04, 0x6e, 0x05, 0x8b
	.byte 0x28, 0x20, 0x68, 0x1d
AccStyle_ReadParamOff_Part8:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x08, 0x6e, 0x05, 0x8b
	.byte 0x50, 0x20, 0x68, 0x11
AccStyle_ReadParamOff_Part16:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x10, 0x6e, 0x05, 0x8b
	.byte 0x78, 0x20, 0x68, 0x05
AccStyle_ReadParamOff_Part32:
	ldb_sri0 W, (xhl + 0x00a0)

AccStyle_ReadParamRet:
	ret

AccStyle_ByteDataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 114 of 138 slots byte-identical
	ld	xhl, 16081478
	sla	a, 1
	ld_rr8w	hl, xhl, a
	extz	xhl
	add	xhl, xiy
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	ldw	hl, 319
	jr	nz, 5
	ld	a, (xhl+20)
	jr	62
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	ldw	hl, 575
	jr	nz, 5
	ld	a, (xhl+20)
	jr	50
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	ldw	hl, 1087
	jr	nz, 5
	.byte 0x8b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x21	; v10 does not spell this byte either
	.byte 0x68	; v10 does not spell this byte either
	.byte 0x26	; v10 does not spell this byte either
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	.byte 0x33	; v10 does not spell this byte either
	push	xsp
	ldio	110, 5
	ld	a, (xhl+100)
	jr	26
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	ldw	hl, 4159
	jr	nz, 7
	ld	a, (xhl+140)
	jr	12
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	.byte 0x33	; v10 does not spell this byte either
	.byte 0x3f	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x6e	; v10 does not spell this byte either
	halt
	ld	a, (xhl+180)
	ret
	nop
	nop
	normal
	nop
	push	sr
	nop
	pop	sr
	nop
	max
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
	max
	normal
	max
	push	sr
	max
	pop	sr
	max
	max
	max
	halt
	max
	ei	4
	reti
	max
	ldio	4, 9
	max
	ldwio	4, 1035
	incf
	max
	decf
	max
	ret
	max
	retd	4100
	max
	scf
	max
	ccf
	max
	zcf
	max
	nop
	nop
	push	sr
	nop
	max
	nop
	di
	ldio	0, 10
	nop
	incf
	nop
	ret
	nop
	nop
	max
	push	sr
	max
	max
	max
	ei	4
	ldio	4, 10
	max
	incf
	max
	ret
	.byte 0x04	; v10 does not spell this byte either
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
	calr	25
	ld	(12807:16), a
	ld	(12808:16), a
	ld	(12809:16), a
	ld	(12810:16), a
	ld	(12811:16), a
	ld	(12812:16), a
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ldb A, 0x01
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
	.byte 0xc3, 0x07, 0xec, 0xf4, 0x21, 0xc9, 0xcf, 0x83
	.byte 0x6e, 0x05, 0x1e, 0x28, 0x02, 0x68, 0x35
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
	.byte 0xc1, 0x33, 0x04, 0xf1, 0x66, 0x0a, 0xf1, 0x3f
	.byte 0x33, 0x40, 0x1e, 0xd8, 0x00, 0x78, 0x9f, 0x00
AccVoice_BarEnd_NextPage:
	.byte 0xc8, 0xcc, 0xf0, 0xc8, 0xc8, 0x10, 0xf1, 0x3f
	.byte 0x33, 0x40, 0xc1, 0x3e, 0x33, 0x61, 0x1e, 0xc4
	.byte 0x00, 0x1d, 0x30, 0xe4, 0xf5, 0x1e, 0x9b, 0x16
	.byte 0xc1, 0xc5, 0x32, 0x3c, 0xfb, 0xf1, 0x70, 0x32
	.byte 0xc8, 0x6e, 0x09, 0xc1, 0x6f, 0x32, 0x21, 0xc9
	.byte 0xcc, 0x03, 0x66, 0x0a
AccVoice_BarEnd_CheckChord94:
	ld	a, (13112:16)
	andda8	a, (12938)
	jr	nz, 51
AccVoice_BarEnd_CheckChord65:
	ld	a, (12909:16)
	and	a, 3
	jr	nz, 9
	ld	a, (12910:16)
	and	a, 13
	jr	z, 10
AccVoice_BarEnd_CheckChord95:
	ld	a, (13112:16)
	andda8	a, (12939)
	jr	nz, 23
AccVoice_BarEnd_CheckSync69:
	.byte 0xf1, 0x71, 0x32, 0xc8, 0x6e, 0x11, 0xc1, 0xc0
	.byte 0x32, 0x21, 0xc9, 0xcc, 0x3f, 0x66, 0x3e, 0xf1
	.byte 0xc5, 0x32, 0xcf, 0x6e, 0x02, 0x68, 0x36
AccVoice_SetChordChangeFlags:
	.byte 0xc1, 0x57, 0x32, 0x3e, 0x80, 0xc1, 0x58, 0x32
	.byte 0x3e, 0x01, 0xc1, 0x76, 0x32, 0x21, 0xc1, 0x77
	.byte 0x32, 0xe1, 0xc9, 0xcc, 0x3f, 0x66, 0x1f, 0xf1
	.byte 0x65, 0x32, 0xc8, 0x66, 0x19, 0xc1, 0x72, 0x32
	.byte 0x3c, 0xfc, 0xc1, 0x72, 0x32, 0x3e, 0x01, 0xc1
	.byte 0x38, 0x33, 0x21, 0xc1, 0x76, 0x32, 0xc1, 0x66
	.byte 0x05, 0xc1, 0x72, 0x32, 0x3e, 0x02
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
	ld	iy, (13116:16)
	ld	iz, (13114:16)
	call	16089467
	ret
AccBuf_AdvanceNoPage:
	ld	iy, (13116:16)
	ld	iz, (13114:16)
	call	16089495
	ld	(13114:16), iz
	ld	(13116:16), iy
	ret
AccVoice_HandleMarker83:
	ld	w, (13112:16)
	ld	a, (12920:16)
	orda8	a, (12921)
	and	w, a
	jr	nz, 10
	ld	a, (13112:16)
	andda8	a, (12940)
	jr	z, 5
AccVoice_Marker83_Activate:
	calr AccVoice_ActivatePart
	jr AccVoice_Marker83_Return

AccVoice_Marker83_CheckDeact:
	calr	899
	andda8	a, (13112)
	jr	z, 5
	calr	5377
	jr	3
AccVoice_Marker83_NextPart:
	calr AccPart_AdvanceAndResolve

AccVoice_Marker83_Return:
	ret

AccVoice_ActivatePart:
	ld a, (0x3338:16)
	orddm8 0x328e, a
	orddm8 0x328c, a
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
	.byte 0xc1, 0xd4, 0x33, 0x21, 0xc9, 0xcc, 0xc0, 0x6e
	.byte 0x0a, 0xc1, 0x38, 0x33, 0x21, 0xc1, 0x8d, 0x32
	.byte 0xc1, 0x66, 0x10, 0x1e, 0x16, 0x01, 0xc1, 0x38
	.byte 0x33, 0x21, 0xc9, 0xcd, 0xff, 0xc1, 0x8d, 0x32
	.byte 0xc9, 0x68, 0x68, 0xc1, 0x7a, 0x32, 0x21, 0xc1
	.byte 0x7b, 0x32, 0xe1, 0xc1, 0x7c, 0x32, 0xe1, 0xc1
	.byte 0x38, 0x33, 0xc1, 0x6e, 0x2b, 0xf1, 0x65, 0x32
	.byte 0xc8, 0x66, 0x25, 0xc1, 0x72, 0x32, 0x3c, 0xfc
	.byte 0xc1, 0x72, 0x32, 0x3e, 0x01, 0xc1, 0x38, 0x33
	.byte 0x21, 0xc1, 0x76, 0x32, 0xc1, 0x66, 0x05, 0xc1
	.byte 0x72, 0x32, 0x3e, 0x02, 0xc1, 0x57, 0x32, 0x3e
	.byte 0x80, 0xc1, 0x58, 0x32, 0x3e, 0x01, 0x68, 0x06
	.byte 0x1e, 0x2e, 0x00, 0x1e, 0x66, 0x00, 0xc1, 0x38
	.byte 0x33, 0x21, 0xc9, 0xcd, 0xff, 0xc1, 0x76, 0x32
	.byte 0xc9, 0xc1, 0x77, 0x32, 0xc9, 0xc1, 0x7a, 0x32
	.byte 0xc9, 0xc1, 0x7b, 0x32, 0xc9, 0xc1, 0x7c, 0x32
	.byte 0xc9, 0xf1, 0x3f, 0x33, 0x00, 0x00, 0xf1, 0x4e
	.byte 0x33, 0x00, 0x00, 0x0e, 0xc1, 0x58, 0x32, 0x3e
	.byte 0x01
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
	calr	89
	ld	a, (13112:16)
	andda8	a, (12993)
	jr	z, 22
	call	16088341
	calr	185
	ld	a, (13112:16)
	xor	a, 255
	anddm8	(12993), a
	call	16085410
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
	call	16081274
	calr	342
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
	call	16081303
	cp	w, 131
	jr	nz, 12
	ld	a, (13113:16)
	call	16081690
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
	calr	582
	call	16070940
	calr	152
	ld	(13114:16), wa
	ldw	(13116:16), 6
	jr	14
AccPart_ResolveWithPedal_Bound:
	calr	507
	ld	xiy, (12850:16)
	calr	229
	ld	(13116:16), wa
AccPart_ResolveWithPedal_Return:
	ret

AccPart_LoadParamOffsetTable:
	ld	xiy, (12850:16)
	ld	a, (13113:16)
	ldb	w, 0
	call	16081026
	calr	1
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
	anddm8 0x3344, a
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
	jr	nz, 11
	ld	a, (13112:16)
	orddm8	(13124), a
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
	anddm8 0x3344, a
	cp (0x3338:16), 0x01
	jr nz, .Lc_f568e9
	add HL,0x0118
	ldw_dri wa, 0x07, 0xf4, 0xec
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Kbd2:
.Lc_f568e9:
	cp (0x3338:16), 0x02
	jr nz, .Lc_f568fb
	add HL,0x013e
	ldw_dri wa, 0x07, 0xf4, 0xec
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc1:
.Lc_f568fb:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f5690d
	add HL,0x0164
	ldw_dri wa, 0x07, 0xf4, 0xec
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc2:
.Lc_f5690d:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f5691f
	add HL,0x018a
	ldw_dri wa, 0x07, 0xf4, 0xec
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc3:
.Lc_f5691f:
	cp (0x3338:16), 0x10
	jr nz, .Lc_f56931
	add HL,0x01b0
	ldw_dri wa, 0x07, 0xf4, 0xec
	jr t, AccPart_SubtractBaseAddr
AccPart_ParamAddr_Acc4:
.Lc_f56931:
	cp (0x3338:16), 0x20
	jr nz, AccPart_SubtractBaseAddr
	add HL,0x01d6
	ldw_dri wa, 0x07, 0xf4, 0xec
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
	jr	78
AccPart_CheckAcc1:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x04, 0x6e, 0x0d, 0xed
	.byte 0xc8, 0x20, 0x00, 0x00, 0x00, 0x44, 0xb1, 0x31
	.byte 0x00, 0x00, 0x68, 0x3a
AccPart_CheckAcc2:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x08, 0x6e, 0x0d, 0xed
	.byte 0xc8, 0x28, 0x00, 0x00, 0x00, 0x44, 0xb8, 0x31
	.byte 0x00, 0x00, 0x68, 0x26
AccPart_CheckAcc3:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x10, 0x6e, 0x0d, 0xed
	.byte 0xc8, 0x30, 0x00, 0x00, 0x00, 0x44, 0xbf, 0x31
	.byte 0x00, 0x00, 0x68, 0x12
AccPart_CheckAcc4:
	.byte 0xc1, 0x38, 0x33, 0x3f, 0x20, 0x6e, 0xf9, 0xed
	.byte 0xc8, 0x38, 0x00, 0x00, 0x00, 0x44, 0xc6, 0x31
	.byte 0x00, 0x00
AccPart_CopyData:
	lds bc, 7

	ldir85

	ld a, (13112:16)

	orddm8 (12944), xbc

	ret



AccPart_CheckAnyActive:
	ld	a, (12922:16)
	orda8	a, (12923)
	orda8	a, (12924)
	orda8	a, (12918)
	orda8	a, (12919)
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
	anddm8 0x3276, w
	ld w, (0x0433:16)
	cp w, (0x32ce:16)
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 0x3277, a
	ld a, (0x32cf:16)
	jr t, AccPedal_DirB_Return
AccPedal_DirB_Alternate:
.Lc_f56a48:
	ld A,W
	xor W,0xff
	anddm8 0x3277, w
	ld w, (0x0433:16)
	cp w, (0x32cc:16)
	jr nz, AccPedal_DirB_DefaultStyle
	orddm8 0x3276, a
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
	cps a, 0
	jr nz, AccMidi_VelNonZero
	ldb a, 0x1

AccMidi_VelNonZero:
	ld	e, a
	ld	(13110:16), a
	ld_rrb	a, xhl, iy
	ret
AccMidi_ParseNoteOn:
	calr AccMidi_ParseCommon
	cp (0x3391:16), 0x91
	jr nz, AccMidi_ParseNoteOn_StorePos
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x3397:16), a
	call AccBuf_Advance
	ldb_dri a, 0x07, 0xec, 0xf4
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
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x3393:16), a
	cp (0x3338:16), 0x01
	jr z, .Lc_f56b14
	cp (0x3338:16), 0x02
	jr z, .Lc_f56b14
	call Rhythm_CheckVelocityThreshold
AccMidi_ParseCommon_ExtraFields:
.Lc_f56b14:
	call AccBuf_Advance
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x3394:16), a
	call AccBuf_Advance
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x3395:16), a
	call AccBuf_Advance
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x3396:16), a
	call AccBuf_Advance
	ret
AccMidi_SelectVelocitySource:
	ld	a, (13112:16)
	ld	w, (12963:16)
	andda8	a, (12922)
	jr	nz, 24
	andda8	a, (12923)
	jr	nz, 18
	andda8	a, (12924)
	jr	nz, 12
	andda8	a, (12920)
	jr	nz, 6
	andda8	a, (12921)
	jr	z, 4
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
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	cps a, 0
	jr nz, AccBuf_WriteNote_VelNonZero
	ldb A, 0x01
AccBuf_WriteNote_VelNonZero:
	stb_dri A, 0x07, 0xec, 0xf4

	.byte 0x1d, 0x55, 0x3c, 0xf5	; call RingBuf_AdvanceIndex (v7 addr)

	.byte 0xc1, 0x96, 0x33, 0x21	; ldb_d8 a, (0x3432) (v7 patched)

	stb_dri A, 0x07, 0xec, 0xf4

	.byte 0x1d, 0x55, 0x3c, 0xf5	; call RingBuf_AdvanceIndex (v7 addr)

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
	ld	(12936:16), wa
	ret
AccTempo_PositionCompare:
	cp w, (0x3218:16)
	jr nz, AccTempo_DiffBar
	cp BC,DE
	jr c, AccTempo_SameBar
	ldb A, 0x00
	jr t, AccTempo_Return
AccTempo_SameBar:
	sub de, bc
	ld a, e
	cps d, 0
	jr z, AccTempo_Return
	ldb a, 0x60
	jr AccTempo_Return

AccTempo_DiffBar:
	.byte 0xc1, 0x18, 0x32, 0xf0, 0x67, 0x0e, 0xc8, 0xcf
	.byte 0xff, 0x6e, 0x18, 0xc1, 0x18, 0x32, 0x3f, 0x00
	.byte 0x66, 0x0d, 0x68, 0x0f
AccTempo_BarZero:
	.byte 0xc8, 0xd8, 0x6e, 0x07, 0xc1, 0x18, 0x32, 0x3f
	.byte 0xff, 0x66, 0x04
AccTempo_TooFar:
	ldb a, 0x0
	jr AccTempo_Return

AccTempo_ComputeDelta:
	xor xwa, xwa
	ld a, (1112:16)
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
	bit 0, (0x3258:16)
	jr nz, AccKbd1_ProcessReturn
	calr AccKbd1_ScanSlots
	calr AccKbd1_DrainRingBuf
	ld XIY,0x00003178
	ld XIX,0x00003191
	lds bc, 5
	ldir85
	ld a, (0x33a0:16)
	ld (0x3250:16), a
	call RhythmPart1_ProcessAccentData
	and (0x3290:16), 0xfe
AccKbd1_ProcessReturn:
	ret

AccKbd1_TimingCheck:
	ldb A, 0x00
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
	ldb	a, 95
	ld	w, (1112:16)
	dec	1, w
	calr	63593
	ld	bc, (12769:16)
	ld	w, (13118:16)
	dec	1, w
	calr	65340
	ld	(13215:16), a
AccKbd1_TimingReturn:
	ret

AccKbd1_ScanSlots:
	ld	xhl, 12280
AccKbd1_ScanSlots_Loop:
	calr	15
	add	xhl, 6
	cp	xhl, 12328
	jr	c, -17
	ret
AccSlot_CheckAndUpdate:
	bit 7,(XHL)
	jr z, AccSlot_Return
	ld DE,(XHL+0x04)
	ld a, (0x339f:16)
	xor W,W
	ei 0x06
	.byte 0xd1, 0x60, 0x04, 0x80, 0xc1, 0x64, 0x04, 0xa1
	.byte 0x6d, 0x0d, 0xc8, 0xd8, 0x66, 0x07, 0xc8, 0x69
	.byte 0xc9, 0xc8, 0x60, 0x68, 0x02
AccSlot_TimingZero:
	xor wa, wa

AccSlot_CompareAndUpdate:
	cp	de, wa
	jr	ule, 13	; -> 0xF56DCE
	ld	(xhl+4), wa
	cp	(13014:16), wa
	jr	ule, 4	; -> 0xF56DCE
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
	ld_rrb	d, xhl, iy
	popw	iy
	ld	a, (13215:16)
	ei	0x06
	addda8	a, 1122
	addda8	w, 1124
	sub	a, w
	jr	pl, 2
	ldb	a, 0
AccBuf_NoteEvent_StoreTiming:
	xor w, w
	cp de, wa
	jr ule, AccBuf_NoteEvent_SkipTiming
	stb_dri A, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	stb_dri W, 0x07, 0xec, 0xf4
	jr AccBuf_NoteEvent_Return

AccBuf_NoteEvent_SkipTiming:
	call RingBuf_AdvanceIndex

AccBuf_NoteEvent_Return:
	ei 0
	ret

AccKbd2_CheckActive:
	ld	a, (13112:16)
	andda8	a, (13124)
	jr	z, 76
	ld	a, (13112:16)
	ld	w, (12920:16)
	orda8	w, (12921)
	and	w, a
	jr	z, 10
	orddm8	(12942), a
	orddm8	(12940), a
	jr	50
	ld	a, (13112:16)
	xor	a, 255
	anddm8	(12918), a
	anddm8	(12919), a
	anddm8	(12922), a
	anddm8	(12923), a
	anddm8	(12924), a
	anddm8	(12993), a
	anddm8	(12941), a
	ld	(13134:16), 0
	ld	(13114:16), 254
	ld	(13116:16), 6
	ret
AccKbd2_ProcessEntry:
	calr AccKbd2_SaveState
	calr AccVoice_ProcessEventLoop
	calr AccKbd2_RestoreState

AccKbd2_SaveState:
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ldb A, 0x02
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
	calr	65026
	add	xhl, 6
	cp	xhl, 12376
	jr	c, -17
	ret
AccKbd2_DrainRingBuf:
	ld	xhl, 11000
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	.byte 0xc1, 0x58, 0x32, 0x3c, 0xfc	; anddi8 (0x32f4), 252 (v7 patched)



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
	calr	144
	ld	w, (12821:16)
	calr	62934
	ld	bc, (12769:16)
	ld	w, (12831:16)
	calr	64683
	cp	a, 24
	jr	ugt, 5
	calr	156
	jr	5
AccSeq_NoteOn_TooFar:
	.byte 0xc1, 0x58, 0x32, 0x3e, 0x01	; ordi8 0x32f4, 1 (v7 patched)



AccSeq_NoteOn_Continue:
	jr AccSeq_ScanLoop

AccSeq_EndOfBar:
	.byte 0xf1, 0x58, 0x32, 0xc9, 0x66, 0x07, 0xc1, 0x58
	.byte 0x32, 0x3e, 0x01, 0x68, 0xa9
AccSeq_EndOfBar_Process:
	.byte 0xc1, 0x15, 0x32, 0x20, 0x1e, 0xbb, 0xf5, 0xd1
	.byte 0xe1, 0x31, 0x21, 0xc1, 0x1f, 0x32, 0x20, 0x1e
	.byte 0x7b, 0xfc, 0xc9, 0xcf, 0x18, 0x6b, 0x40, 0xc1
	.byte 0x58, 0x32, 0x3e, 0x02, 0xc1, 0x15, 0x32, 0x21
	.byte 0xc9, 0x61, 0xc9, 0x88, 0xc9, 0xcc, 0x0f, 0xc1
	.byte 0x33, 0x04, 0xf1, 0x66, 0x0a, 0xf1, 0x15, 0x32
	.byte 0x40, 0x1e, 0x35, 0x00, 0x78, 0x72, 0xff
AccSeq_NextBarPage:
	and	w, 240
	add	w, 16
	ld	(12821:16), w
	inc	1, (12831:16)
	ld	xhl, 14969785
	add	xhl, 6
	ld	(12791:16), xhl
	jrl	-174
AccSeq_EndOfBar_TooFar:
	.byte 0xc1, 0x58, 0x32, 0x3e, 0x01	; ordi8 0x32f4, 1 (v7 patched)

	.byte 0x78, 0x4a, 0xff	; jrl AccSeq_ScanLoop (v7 displacement)



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
	ld	xhl, 14969785
	add	xhl, 6
	ld	(12791:16), xhl
	ld	a, (xhl)
	ret
AccSeq_ParseNoteEvent:
	cps a, 0
	jr nz, AccSeq_ParseNote_VelNonZero
	ldb a, 0x1

AccSeq_ParseNote_VelNonZero:
	.byte 0xc9, 0x8d, 0xe1, 0xf7, 0x31, 0x23, 0x83, 0x21
	.byte 0xf1, 0x91, 0x33, 0x41, 0x1e, 0xce, 0xff, 0xf1
	.byte 0x92, 0x33, 0x45, 0x1e, 0xc7, 0xff, 0x83, 0x21
	.byte 0xf1, 0x93, 0x33, 0x41, 0x1e, 0xbe, 0xff, 0x83
	.byte 0x21, 0xf1, 0x94, 0x33, 0x41, 0x1e, 0xb5, 0xff
	.byte 0x21, 0x01, 0xf1, 0x95, 0x33, 0x41, 0x1e, 0xac
	.byte 0xff, 0x21, 0x00, 0xf1, 0x96, 0x33, 0x41, 0x1e
	.byte 0xa3, 0xff, 0xc1, 0xff, 0x36, 0x21, 0xc9, 0xcc
	.byte 0x3f, 0x66, 0x09, 0xc1, 0x9a, 0x8c, 0x3f, 0xb5
	.byte 0x66, 0x16, 0x68, 0x22
AccSeq_ParseNote_CheckMode:
	.byte 0xc1, 0x99, 0x32, 0x21, 0xc9, 0xdb, 0x6e, 0x06
	.byte 0xf1, 0xde, 0x33, 0xc8, 0x66, 0x06
AccSeq_ParseNote_CheckRec:
	.byte 0xf1, 0x4c, 0x33, 0xc8, 0x66, 0x0e
AccSeq_ParseNote_WriteToKbd2:
	ld	xhl, 11000
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	calr	64280
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
	ldb A, 0x04
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
	jr	z, 32	; -> 0xF571F2
	ld	xiy, (12850:16)
	ld	a, e
	call	AccPart_LookupBoundVoiceParam
	call	AccPart_GetParamAddr
	ld	iy, wa
	ld	a, (12777:16)
	call	AccVoice_TableLookup
	call	AccVoice_ScanForD3
	inc	1, e
	jr	-38	; -> 0xF571CC
AccVoice_ScanDone:
	ret

AccVoice_SendProgChange:
	cp (0x3338:16), 0x04
	jr nz, .Lc_f5720c
	ldb A, 0xd7
	ldb W, 0x03
	ld e, (0x3297:16)
	ld (0x3293:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD4:
.Lc_f5720c:
	cp (0x3338:16), 0x08
	jr nz, .Lc_f57225
	ldb A, 0xd4
	ldb W, 0x03
	ld e, (0x3297:16)
	ld (0x3294:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD5:
.Lc_f57225:
	cp (0x3338:16), 0x10
	jr nz, AccVoice_SendD6
	ldb A, 0xd5
	ldb W, 0x03
	ld e, (0x3297:16)
	ld (0x3295:16), e
	call Rhythm_Send3ByteMsg
	jr t, AccCh_ReturnStub
AccVoice_SendD6:
	ldb	a, 214
	ldb	w, 3
	ld	e, (12951:16)
	ld	(12950:16), e
	call	16072669
	jr	0
AccCh_ReturnStub:
	ret

AccBuf_Write3ByteEvent:
	ld a, (0x3391:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
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
	cps a, 0
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
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	call RhythmAccent_UpdateRingBufPosition
	ld a, (0x3393:16)
	ld (0x3399:16), a
	calr AccVoice_CheckStyle
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	cps a, 0
	jr nz, .Lc_f5734c
	ldb A, 0x01
AccBuf_ExtEvt_VelNonZero:
.Lc_f5734c:
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3396:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	calr AccBuf_ExtEvt_WriteExtra
	ld a, (0x3399:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ret
AccBuf_ExtEvt_WriteExtra:
	cp (0x3391:16), 0x90
	jr z, AccBuf_ExtEvt_ExtraReturn
	ld a, (0x329a:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x329b:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
AccBuf_ExtEvt_ExtraReturn:
	ret

AccVoice_CheckStyle:
	.byte 0xc1, 0x49, 0x32, 0x3f, 0xf0, 0x67, 0x00
AccVoice_CallCorrection:
	call AccVoice_CorrectNote
	ret

AccVoice_CorrectionData:
	.byte 0x3b, 0x2d, 0xc1, 0x93, 0x33, 0x21, 0xf1, 0x58
	.byte 0x32, 0xcc, 0x6e, 0x0e, 0xf1, 0x58, 0x32, 0xcb
	.byte 0x66, 0x04, 0x1d, 0xd7, 0x4b, 0xf5, 0x1d, 0x2c
	.byte 0x4c, 0xf5, 0x1d, 0xcd, 0x4e, 0xf5, 0x4d, 0x5b
	.byte 0x0e
AccVoice_CorrectNote:
	.byte 0x3b, 0x2d, 0xc1, 0x93, 0x33, 0x21, 0xf1, 0x58
	.byte 0x32, 0xcc, 0x6e, 0x0e, 0xf1, 0x58, 0x32, 0xcb
	.byte 0x66, 0x04, 0x1d, 0xd7, 0x4b, 0xf5
AccVoice_NoteRangeCheck:
	call Rhythm_NoteRangeCheck

AccVoice_VelocityLookup:
	cp	(13201:16), 145
	jr	z, 6
	call	16075855
	jr	4
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
	ld_rrb	a, xhl, iy
	ld	(13204:16), a
	call	16089495
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
	ldb A, 0x00
	bit 2, (0x3433:16)
	jr z, AccCh_OverlapReturn
	bit 3, (0x36ff:16)
	jr z, AccCh_OverlapReturn
	ldb A, 0x01
AccCh_OverlapReturn:
	ret

AccBuf_InitWithDefaults:
	ldw (xhl+0x100), 0x000a
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
	lds bc, 5
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
	call	16084375
	add	xhl, 9
	cp	xhl, 12448
	jr	c, -18
	ret
AccCh1_DrainRingBuf:
	ld	xhl, 11256
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ldb A, 0x08
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
	cps a, 0
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
	ldb A, 0x00
	bit 2, (0x3433:16)
	jr z, AccCh2_OverlapReturn
	bit 0, (0x36ff:16)
	jr z, AccCh2_OverlapReturn
	ldb A, 0x01
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
	lds bc, 5
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
	call	16084375
	add	xhl, 9
	cp	xhl, 12520
	jr	c, -18
	ret
AccCh2_DrainRingBuf:
	ld	xhl, 11512
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ldb A, 0x10
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
	cps a, 0
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
	ldb A, 0x00
	bit 2, (0x3433:16)
	jr z, AccCh3_OverlapReturn
	bit 1, (0x36ff:16)
	jr z, AccCh3_OverlapReturn
	ldb A, 0x01
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
	lds bc, 5
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
	call	16084375
	add	xhl, 9
	cp	xhl, 12592
	jr	c, -18
	ret
AccCh3_DrainRingBuf:
	ld	xhl, 11768
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	and (0x3258:16), 0xfc
	ld (0x3251:16), 0x00
	ldb A, 0x20
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
	cps a, 0
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
	ldb A, 0x00
	bit 2, (0x3433:16)
	jr z, AccCh4_OverlapReturn
	bit 2, (0x36ff:16)
	jr z, AccCh4_OverlapReturn
	ldb A, 0x01
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
	lds bc, 5
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
	call	16084375
	add	xhl, 9
	cp	xhl, 12664
	jr	c, -18
	ret
AccCh4_DrainRingBuf:
	ld	xhl, 12024
	ld	iy, (xhl+6)
	ld	bc, (xhl+2)
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
	ld	xhl, 11256
	calr	28
	ret
AccCh2_InitProgChange:
	ld	xhl, 11512
	calr	19
	ret
AccCh3_InitProgChange:
	ld	xhl, 11768
	calr	10
	ret
AccCh4_InitProgChange:
	ld	xhl, 12024
	calr	1
	ret
AccBuf_WriteD0Defaults:
	ld	iy, (xhl+4)
	ld	bc, (xhl+2)
	ld	(13201:16), 208
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 2
	ld	(13204:16), 64
	calr	63300
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 1
	ld	(13204:16), 0
	calr	63279
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 3
	ld	(13204:16), 0
	calr	63258
	ld	a, (13216:16)
	ld	(13202:16), a
	ld	(13203:16), 5
	ld	(13204:16), 127
	calr	63237
	ret
AccPart_Deactivate:
	ld	a, (13268:16)
	and	a, 192
	jr	nz, 10
	ld	a, (13112:16)
	andda8	a, (12941)
	jr	z, 17
AccPart_Deactivate_WithPedal:
	calr	60483
	ld	a, (13112:16)
	xor	a, 255
	anddm8	(12941), a
	jrl	120
AccPart_Deactivate_NoPedal:
	.byte 0xc1, 0x7a, 0x32, 0x21, 0xc1, 0x7b, 0x32, 0xe1
	.byte 0xc1, 0x7c, 0x32, 0xe1, 0xc1, 0x38, 0x33, 0xc1
	.byte 0x6e, 0x29, 0xf1, 0x65, 0x32, 0xc8, 0x6e, 0x08
	.byte 0xf1, 0x73, 0x32, 0xc8, 0x6e, 0x23, 0x68, 0x2d
AccPart_Deactivate_WithSync:
	.byte 0xc1, 0x72, 0x32, 0x3c, 0xfc, 0xc1, 0x72, 0x32
	.byte 0x3e, 0x01, 0xc1, 0x38, 0x33, 0x21, 0xc1, 0x76
	.byte 0x32, 0xc1, 0x66, 0x0d, 0xc1, 0x72, 0x32, 0x3e
	.byte 0x02, 0x68, 0x06
AccPart_Deactivate_ActiveNote:
	.byte 0xf1, 0x73, 0x32, 0xc8, 0x66, 0x0c
AccPart_Deactivate_SetDone:
	.byte 0xc1, 0x57, 0x32, 0x3e, 0x80, 0xc1, 0x58, 0x32
	.byte 0x3e, 0x01, 0x68, 0x06
AccPart_Deactivate_SendOff:
	calr AccPart_SelectSourceOrParam
	calr AccPart_ResolveStyleAddr

AccPart_Deactivate_ClearMasks:
	ld	a, (13112:16)
	xor	a, 255
	anddm8	(12918), a
	anddm8	(12919), a
	anddm8	(12922), a
	anddm8	(12923), a
	anddm8	(12924), a
	ld	(13119:16), 0
	ld	(13134:16), 0
AccPart_DeactivateReturn:
	ret

AccPart_Reactivate:
	ld	a, (13112:16)
	andda8	a, (13124)
	jr	z, 86
	ld	a, (13112:16)
	ld	w, (12920:16)
	orda8	w, (12921)
	and	w, a
	jr	z, 20
	orddm8	(12942), a
	orddm8	(12940), a
	ld	(13114:16), 254
	ld	(13116:16), 6
	jr	50
AccPart_Reactivate_Inactive:
	ld	a, (13112:16)
	xor	a, 255
	anddm8	(12918), a
	anddm8	(12919), a
	anddm8	(12922), a
	anddm8	(12923), a
	anddm8	(12924), a
	anddm8	(12993), a
	anddm8	(12941), a
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
	.byte 0xf1, 0x57, 0x32, 0xcf, 0x66, 0x47, 0xc1, 0x57
	.byte 0x32, 0x3c, 0x7f, 0x1d, 0x82, 0x92, 0xf5, 0xf1
	.byte 0x72, 0x32, 0xc8, 0x6e, 0x2d, 0xf1, 0x73, 0x32
	.byte 0xc8, 0x6e, 0x27, 0xf1, 0x71, 0x32, 0xc8, 0x6e
	.byte 0x21, 0xf1, 0x70, 0x32, 0xc8, 0x6e, 0x1b, 0xc1
	.byte 0x6d, 0x32, 0x21, 0xc9, 0xcc, 0x03, 0x6e, 0x12
	.byte 0xc1, 0x6e, 0x32, 0x21, 0xc9, 0xcc, 0x0d, 0x6e
	.byte 0x09, 0xc1, 0x6f, 0x32, 0x21, 0xc9, 0xcc, 0x03
	.byte 0x66, 0x04
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
	calr	3597
	ldb	a, 215
	ldb	w, 2
	ldb	e, 64
	call	16072669
	ldb	a, 215
	ldb	w, 1
	ldb	e, 0
	call	16072669
	ldb	a, 215
	ldb	w, 3
	ldb	e, 0
	call	16072669
	ld	(12947:16), 0
	ldb	a, 215
	ldb	w, 5
	ldb	e, 127
	call	16072669
	pop	xiy
	popw	hl
	ret
AccBuf_WriteD0WithVoice:
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	stib_ind 0x07, 0xec, 0xf4, 0xd0
	call RingBuf_AdvanceIndex
	ld a, (0x324e:16)
	ld (0x3392:16), a
	call RhythmAccent_UpdateRingBufPosition
	stib_ind 0x07, 0xec, 0xf4, 0x03
	call RingBuf_AdvanceIndex
	ld a, (0x3297:16)
	stb_dri a, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ret
AccVoice_InitCh2_D4:
	pushw	hl
	push	xiy
	ld	xhl, 11512
	calr	3484
	ldb	a, 212
	ldb	w, 2
	ldb	e, 64
	call	16072669
	ldb	a, 212
	ldb	w, 1
	ldb	e, 0
	call	16072669
	ldb	a, 212
	ldb	w, 3
	ldb	e, 0
	call	16072669
	ld	(12948:16), 0
	ldb	a, 212
	ldb	w, 5
	ldb	e, 127
	call	16072669
	pop	xiy
	popw	hl
	ret
AccVoice_InitCh3_D5:
	pushw	hl
	push	xiy
	ld	xhl, 11768
	calr	3426
	ldb	a, 213
	ldb	w, 2
	ldb	e, 64
	call	16072669
	ldb	a, 213
	ldb	w, 1
	ldb	e, 0
	call	16072669
	ldb	a, 213
	ldb	w, 3
	ldb	e, 0
	call	16072669
	ld	(12949:16), 0
	ldb	a, 213
	ldb	w, 5
	ldb	e, 127
	call	16072669
	pop	xiy
	popw	hl
	ret
AccVoice_InitCh4_D6:
	pushw	hl
	push	xiy
	ld	xhl, 12024
	calr	3368
	ldb	a, 214
	ldb	w, 2
	ldb	e, 64
	call	16072669
	ldb	a, 214
	ldb	w, 1
	ldb	e, 0
	call	16072669
	ldb	a, 214
	ldb	w, 3
	ldb	e, 0
	call	16072669
	ld	(12950:16), 0
	ldb	a, 214
	ldb	w, 5
	ldb	e, 127
	call	16072669
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
	jr	z, 27
AccPedal_CheckDirection:
	ld	a, (12910:16)
	and	a, 13
	jr	nz, 9
	ld	a, (12909:16)
	and	a, 3
	jr	z, 12
AccPedal_CheckCounter:
	ld	a, (12939:16)
	and	a, 63
	jr	nz, 3
AccPedal_TriggerReInit:
	calr AccInit_FullReInit

AccPedal_CombinedReturn:
	ret
AccTick_ByteData:
	call	16072659
	call	16072524
	calr	3162
	call	16072706
	calr	3214
	ld	a, (12918:16)
	orda8	a, 12919
	and	a, 63
	jr	z, 44
	.byte 0xf1, 0x65, 0x32, 0xc8
	jr	z, 38
	.byte 0xc1, 0x70, 0x32, 0x3e, 0x01
	ld	a, (12918:16)
	and	a, 63
	jr	z, 13
	cp	(12958:16), 0
	jr	z, 17
	dec	1, (12958:16)
	jr	11
	cp	(12958:16), 3
	jr	z, 4
	inc	1, (12958:16)
	.byte 0xf1, 0x73, 0x32, 0xc8
	jr	nz, 15
	.byte 0xf1, 0x70, 0x32, 0xc8
	jr	z, 23
	ld	a, (12938:16)
	and	a, 63
	jr	nz, 14
	calr	1022
	calr	1298
	ld	a, (1075:16)
	ld	(1112:16), a
	ld	a, (12910:16)
	and	a, 13
	jr	z, 3
	calr	1654
	ld	a, (12909:16)
	and	a, 3
	jr	nz, 24
	.byte 0xf1, 0xd4, 0x33, 0xce
	jr	z, 7
	.byte 0xc1, 0x6d, 0x32, 0x3e, 0x01
	jr	11
	.byte 0xf1, 0xd4, 0x33, 0xcf
	jr	z, 8
	.byte 0xc1, 0x6d, 0x32, 0x3e, 0x02
	calr	2118
	ld	a, (12911:16)
	and	a, 3
	jr	z, 10
	calr	3222
	call	16094080
	calr	2665
	.byte 0xc1, 0x0f, 0x32, 0x3c, 0xf0, 0xc1, 0x10, 0x32, 0x3c, 0xf0, 0xc1, 0x11, 0x32, 0x3c, 0xf0, 0xc1, 0x12, 0x32, 0x3c, 0xf0, 0xc1, 0x13, 0x32, 0x3c, 0xf0, 0xc1, 0x14, 0x32, 0x3c, 0xf0
	calr	100
	.byte 0xf1, 0x58, 0x32, 0xce
	jr	nz, 3
	calr	569
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x80
	ret
AccTempo_BarCompare:
	ld w, (0x3219:16)
	cp w, (0x3218:16)
	jr c, .Lc_f57f89
	jr z, AccTempo_BarEqual
	jr ugt, AccTempo_BarGreater
AccTempo_BarLess:
.Lc_f57f89:
	cps w, 0
	jr nz, AccTempo_BarChanged
	cp (0x3218:16), 0xff
	jr nz, AccTempo_BarChanged
	jr t, AccTempo_ComputeSubDelta
AccTempo_BarEqual:
	ld	wa, (12871:16)
	cp	(12772:16), w
	jr	c, 26
	jr	ugt, 20
	cp	(12771:16), a
	jr	ule, 18
	jr	12
AccTempo_BarGreater:
	cp	w, 255
	jr	nz, 11
	cp	(12824:16), 0
	jr	nz, 4
AccTempo_BarChanged:
	ldb a, 0x1
	jr AccTempo_StoreDelta

AccTempo_ComputeSubDelta:
	ld	wa, (12871:16)
	subda8	a, (12771)
	jr	nc, 3
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
	ldb W, 0x01
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
	ldb W, 0x02
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
	ldb_dri a, 0x07, 0xec, 0xf4
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
	jr	nz, 6
	and	w, 240
	add	w, 16
AccSeq_Scanner_StorePos:
	ld	(13119:16), w
	calr	230
	jr	-65
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
	.byte 0x1e, 0xa0, 0x00, 0xc9, 0x8b, 0xd9, 0xf2, 0x6f
	.byte 0x07, 0xc1, 0x58, 0x32, 0x3e, 0x01, 0x68, 0x8a
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
	calr	92
	calr	89
	ld_rrb	a, xhl, iy
	ld	(12951:16), a
	calr	77
	jrl	-219	; -> 0xF58072
AccSeq_Scanner_Unknown:
	.byte 0xc1, 0x52, 0x32, 0x61, 0xc1, 0x52, 0x32, 0x3f
	.byte 0x20, 0x67, 0x12, 0x1d, 0xb5, 0x96, 0xf5, 0x1d
	.byte 0x2d, 0xe5, 0xf5, 0xf1, 0x59, 0x32, 0x00, 0xff
	.byte 0xc1, 0x58, 0x32, 0x3e, 0x41
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
	ld de, (0x3247:16)
	ld (0x3252:16), 0x00
	ld (0x3297:16), 0x00
	ld wa, (0x31ef:16)
	ld (0x333c:16), wa
	ld a, (0x3211:16)
	ld (0x333f:16), a
	ld iz, (0x31ff:16)
	ld (0x333a:16), iz
	ldb W, 0x04
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
	ldb W, 0x08
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
	ldb W, 0x10
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
	ldb W, 0x20
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
	ldb W, 0x00
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock
	or (0x3290:16), 0x3f
	jr t, AccStyle_Finalize
AccStyle_ExtendedInit:
	ld	xiy, 14969849
	ld	a, (12873:16)
	and	a, 127
	cp	a, 29
	jr	ule, 2
	xor	a, a
AccStyle_LookupTable:
	ld_rr8b	a, xiy, a
	ld	(12956:16), a
	ld	a, (12873:16)
	and	a, 127
	call	16070940
	ld	(12850:16), xiy
	ld	l, (xiy+16)
	ld	h, (xiy+17)
	and	h, 15
	and	a, 7
	cp	hl, 520
	jr	z, 10
	cp	hl, 792
	jr	z, 4
	call	16068659
AccStyle_LoadAndApply:
	ld	a, l
	call	16071062
	ld	(12855:16), xiy
	call	16080751
	ld	xiy, (12850:16)
	call	16071249
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f
	ld	w, (12873:16)
	call	16073348
AccStyle_Finalize:
	call AccVoice_SelectAndApplyPatch
	jr AccInit_ClearAllFlags

AccInit_ClearAllFlags:
	.byte 0xc1, 0x70, 0x32, 0x3c, 0xfe, 0xc1, 0x71, 0x32
	.byte 0x3c, 0xfe, 0xc1, 0x72, 0x32, 0x3c, 0xfc, 0xc9
	.byte 0xd1, 0xf1, 0x7a, 0x32, 0x41, 0xf1, 0x7b, 0x32
	.byte 0x41, 0xf1, 0x7c, 0x32, 0x41, 0xf1, 0x76, 0x32
	.byte 0x41, 0xf1, 0x77, 0x32, 0x41, 0xf1, 0x78, 0x32
	.byte 0x41, 0xf1, 0x79, 0x32, 0x41, 0xf1, 0xc1, 0x32
	.byte 0x41, 0xf1, 0xb1, 0x32, 0x41, 0xf1, 0x21, 0x32
	.byte 0x41, 0xf1, 0x22, 0x32, 0x41, 0xf1, 0x23, 0x32
	.byte 0x41, 0xf1, 0x24, 0x32, 0x41, 0xf1, 0x25, 0x32
	.byte 0x41, 0xf1, 0x26, 0x32, 0x41, 0x1d, 0x1d, 0xe4
	.byte 0xf5, 0x0e
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
	call	16083049
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
	call	16083049
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
	call	16083049
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
	call	16083049
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
	call	16083049
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
	call	16083049
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
	jr	4
AccVoice_Reset_UseStyle:
	ld	xiy, (12850:16)
AccVoice_Reset_SelectMode:
	.byte 0x33, 0x20, 0x00, 0xf1, 0x6e, 0x32, 0xc8, 0x6e
	.byte 0x0c, 0x33, 0x22, 0x00, 0xf1, 0x6e, 0x32, 0xca
	.byte 0x6e, 0x03, 0x33, 0x20, 0x04
AccVoice_Reset_LoadParams:
	.byte 0x1e, 0xfb, 0x02, 0xc1, 0x49, 0x32, 0x3f, 0x80
	.byte 0x67, 0x0a, 0xe1, 0x32, 0x32, 0x25, 0x1d, 0x51
	.byte 0x3a, 0xf5, 0x68, 0x16
AccVoice_Reset_Extended:
	.byte 0xc1, 0x07, 0x32, 0x21, 0x20, 0x03, 0xf1, 0x6e
	.byte 0x32, 0xcb, 0x66, 0x02, 0x20, 0x04
AccVoice_Reset_SetMode:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_Reset_ApplyAll:
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)



AccVoice_Reset_SetMasks:
	.byte 0xf1, 0x6e, 0x32, 0xcb, 0x7e, 0x75, 0x00, 0xf1
	.byte 0x6e, 0x32, 0xca, 0x6e, 0x38, 0xc1, 0x6e, 0x32
	.byte 0x3c, 0xfe, 0xc1, 0x7a, 0x32, 0x3e, 0x3f, 0xc9
	.byte 0xd1, 0xf1, 0x76, 0x32, 0x41, 0xf1, 0x77, 0x32
	.byte 0x41, 0xf1, 0x7b, 0x32, 0x41, 0xf1, 0x7c, 0x32
	.byte 0x41, 0xf1, 0x78, 0x32, 0x41, 0xf1, 0x79, 0x32
	.byte 0x41, 0xf1, 0xc1, 0x32, 0x41, 0xf1, 0x8c, 0x32
	.byte 0x41, 0xf1, 0x8e, 0x32, 0x41, 0xc1, 0xe7, 0x31
	.byte 0x3c, 0xfb, 0x78, 0x6c, 0x00
AccVoice_Reset_Mode2:
	.byte 0xc1, 0x6e, 0x32, 0x3c, 0xfb, 0xc1, 0x7b, 0x32
	.byte 0x3e, 0x3f, 0xc9, 0xd1, 0xf1, 0x76, 0x32, 0x41
	.byte 0xf1, 0x77, 0x32, 0x41, 0xf1, 0x7a, 0x32, 0x41
	.byte 0xf1, 0x7c, 0x32, 0x41, 0xf1, 0x78, 0x32, 0x41
	.byte 0xf1, 0x79, 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41
	.byte 0xf1, 0x8c, 0x32, 0x41, 0xf1, 0x8e, 0x32, 0x41
	.byte 0xc1, 0xe7, 0x31, 0x3c, 0xfb, 0x68, 0x35
AccVoice_Reset_Mode3:
	.byte 0xc1, 0x6e, 0x32, 0x3c, 0xf7, 0xc1, 0x7c, 0x32
	.byte 0x3e, 0x3f, 0xc9, 0xd1, 0xf1, 0x76, 0x32, 0x41
	.byte 0xf1, 0x77, 0x32, 0x41, 0xf1, 0x7a, 0x32, 0x41
	.byte 0xf1, 0x7b, 0x32, 0x41, 0xf1, 0x78, 0x32, 0x41
	.byte 0xf1, 0x79, 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41
	.byte 0xf1, 0x8c, 0x32, 0x41, 0xf1, 0x8e, 0x32, 0x41
	.byte 0xc1, 0xe7, 0x31, 0x3c, 0xfb
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
	ldb E, 0x48
	ldb D, 0x05
	ldb W, 0x00
	ldb A, 0x00
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_Reassign_Apply
AccVoice_Reassign_MatchA:
	ld	a, (13001:16)
	call	16070940
	jr	94
AccVoice_Reassign_Mode2:
	.byte 0xc1, 0x49, 0x32, 0x21, 0xc9, 0xcc, 0x7f, 0x1d
	.byte 0xed, 0x39, 0xf5, 0x43, 0xb0, 0x6b, 0xe4, 0x00
	.byte 0xf3, 0x03, 0xec, 0xe0, 0xc9, 0x66, 0x55, 0xc1
	.byte 0x5f, 0xfc, 0x3c, 0xf7, 0x25, 0x48, 0x24, 0x05
	.byte 0x20, 0x00, 0x21, 0x00, 0x1d, 0xeb, 0x30, 0xf5
	.byte 0xe1, 0x32, 0x32, 0x25, 0x68, 0x30
AccVoice_Reassign_Mode3:
	ld a, (0x3249:16)
	and A,0x7f
	call AccPatch_SetVoiceParam
	cp a, (0x32ca:16)
	jr z, AccVoice_Reassign_MatchB
	and (0xfc60:16), 0xfb
	ldb E, 0x48
	ldb D, 0x06
	ldb W, 0x00
	ldb A, 0x00
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_Reassign_Apply
AccVoice_Reassign_MatchB:
	ld	a, (13003:16)
	call	16070940
AccVoice_Reassign_Apply:
	.byte 0x1e, 0xe7, 0x01, 0x1d, 0x51, 0x3a, 0xf5, 0xc1
	.byte 0x90, 0x32, 0x3e, 0x3f, 0x68, 0x18
AccVoice_Reassign_Fallback:
	ld xiy, (12855:16)

	ldw hl, 0x22

	.byte 0x1e, 0x68, 0x01	; calr AccVoice_LoadAllParts (v7 displacement)

	xor xhl, xhl

	ldw hl, 0x126

	.byte 0x1d, 0x07, 0x3a, 0xf5	; call AccVoice_LoadTuningBlock (v7 addr)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)



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
	jr	4
AccVoice_Split_UseStyle:
	ld	xiy, (12850:16)
AccVoice_Split_LoadAndApply:
	ld	a, (12807:16)
	call	16081590
	calr	276
	ld	a, (12807:16)
	call	16081662
	cp	(12873:16), 128
	jr	c, 10
	ld	xiy, (12850:16)
	call	16071249
	jr	14
AccVoice_Split_StyleMode:
	ld	a, (12807:16)
	ldb	w, 2
	call	16081026
	call	16071175
AccVoice_Split_Apply63:
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)



AccVoice_Split_SetForward:
	.byte 0xf1, 0x6d, 0x32, 0xc8, 0x66, 0x37, 0xc1, 0x6d
	.byte 0x32, 0x3c, 0xfe, 0xc1, 0x76, 0x32, 0x3e, 0x3f
	.byte 0xc9, 0xd1, 0xf1, 0x7a, 0x32, 0x41, 0xf1, 0x7b
	.byte 0x32, 0x41, 0xf1, 0x7c, 0x32, 0x41, 0xf1, 0x77
	.byte 0x32, 0x41, 0xf1, 0x78, 0x32, 0x41, 0xf1, 0x79
	.byte 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41, 0xf1, 0x8c
	.byte 0x32, 0x41, 0xf1, 0x8e, 0x32, 0x41, 0xc1, 0xe7
	.byte 0x31, 0x3c, 0xfb, 0x68, 0x35
AccVoice_Split_SetReverse:
	.byte 0xc1, 0x6d, 0x32, 0x3c, 0xfd, 0xc1, 0x77, 0x32
	.byte 0x3e, 0x3f, 0xc9, 0xd1, 0xf1, 0x7a, 0x32, 0x41
	.byte 0xf1, 0x7b, 0x32, 0x41, 0xf1, 0x7c, 0x32, 0x41
	.byte 0xf1, 0x76, 0x32, 0x41, 0xf1, 0x78, 0x32, 0x41
	.byte 0xf1, 0x79, 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41
	.byte 0xf1, 0x8c, 0x32, 0x41, 0xf1, 0x8e, 0x32, 0x41
	.byte 0xc1, 0xe7, 0x31, 0x3c, 0xfb
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
	ldb E, 0x48
	ldb D, 0x05
	ldb W, 0x00
	ldb A, 0x00
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_SplitReassign_Apply
AccVoice_SplitReassign_MatchFwd:
	ld	a, (13005:16)
	call	16070940
	jr	48
AccVoice_SplitReassign_Reverse:
	.byte 0xc1, 0x49, 0x32, 0x21, 0xc9, 0xcc, 0x7f, 0x1d
	.byte 0xed, 0x39, 0xf5, 0xc1, 0xce, 0x32, 0xf1, 0x66
	.byte 0x17, 0xc1, 0x5f, 0xfc, 0x3c, 0x7f, 0x25, 0x48
	.byte 0x24, 0x05, 0x20, 0x00, 0x21, 0x00, 0x1d, 0xeb
	.byte 0x30, 0xf5, 0xe1, 0x32, 0x32, 0x25, 0x68, 0x08
AccVoice_SplitReassign_MatchRev:
	ld	a, (13007:16)
	call	16070940
AccVoice_SplitReassign_Apply:
	.byte 0x1e, 0x74, 0x00	; calr AccInit_AllPartPositions (v7 displacement)

	.byte 0x1d, 0x51, 0x3a, 0xf5	; call AccTuning_CopyAllPartsFromStyle (v7 addr)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)

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
	call	16083049
	ld	(12795:16), wa
	ldw	(12779:16), 6
	ld	(13112:16), 4
	call	16083049
	ld	(12799:16), wa
	ldw	(12783:16), 6
	ld	(13112:16), 8
	call	16083049
	ld	(12801:16), wa
	ldw	(12785:16), 6
	ld	(13112:16), 16
	call	16083049
	ld	(12803:16), wa
	ldw	(12787:16), 6
	ld	(13112:16), 32
	call	16083049
	ld	(12805:16), wa
	ldw	(12789:16), 6
	ld	(13112:16), 2
	call	16083049
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
	jr	4
AccVoice_ThirdLayer_Style:
	ld	xiy, (12850:16)
AccVoice_ThirdLayer_SelectMode:
	.byte 0x33, 0x24, 0x00, 0xf1, 0x6f, 0x32, 0xc8, 0x6e
	.byte 0x03, 0x33, 0x24, 0x04
AccVoice_ThirdLayer_LoadParams:
	.byte 0x1e, 0xda, 0xfe, 0xc1, 0x07, 0x32, 0x21, 0x1d
	.byte 0xfe, 0x62, 0xf5, 0xc1, 0x49, 0x32, 0x3f, 0x80
	.byte 0x67, 0x0a, 0xe1, 0x32, 0x32, 0x25, 0x1d, 0x51
	.byte 0x3a, 0xf5, 0x68, 0x16
AccVoice_ThirdLayer_StyleMode:
	.byte 0xc1, 0x07, 0x32, 0x21, 0x20, 0x05, 0xf1, 0x6f
	.byte 0x32, 0xc9, 0x66, 0x02, 0x20, 0x06
AccVoice_ThirdLayer_SetModeW:
	call AccPart_GetVoiceParamOffsetTable
	call AccVoice_LoadTuningBlock

AccVoice_ThirdLayer_Apply:
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)



AccVoice_ThirdLayer_SetMasks:
	.byte 0xf1, 0x6f, 0x32, 0xc8, 0x66, 0x2a, 0xc1, 0x6f
	.byte 0x32, 0x3c, 0xfe, 0xc1, 0x78, 0x32, 0x3e, 0x3f
	.byte 0xc9, 0xd1, 0xf1, 0x7a, 0x32, 0x41, 0xf1, 0x7b
	.byte 0x32, 0x41, 0xf1, 0x7c, 0x32, 0x41, 0xf1, 0x76
	.byte 0x32, 0x41, 0xf1, 0x77, 0x32, 0x41, 0xf1, 0x79
	.byte 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41, 0x68, 0x28
AccVoice_ThirdLayer_Reverse:
	.byte 0xc1, 0x6f, 0x32, 0x3c, 0xfd, 0xc1, 0x79, 0x32
	.byte 0x3e, 0x3f, 0xc9, 0xd1, 0xf1, 0x7a, 0x32, 0x41
	.byte 0xf1, 0x7b, 0x32, 0x41, 0xf1, 0x7c, 0x32, 0x41
	.byte 0xf1, 0x76, 0x32, 0x41, 0xf1, 0x77, 0x32, 0x41
	.byte 0xf1, 0x78, 0x32, 0x41, 0xf1, 0xc1, 0x32, 0x41
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
	ldb E, 0x48
	ldb D, 0x05
	ldb W, 0x00
	ldb A, 0x00
	call Rhythm_QueuePartChangeEvent
	ld xiy, (0x3232:16)
	jr t, AccVoice_ThirdReassign_Apply
AccVoice_ThirdReassign_MatchFwd:
	ld	a, (13009:16)
	call	16070940
	jr	48
AccVoice_ThirdReassign_Reverse:
	.byte 0xc1, 0x49, 0x32, 0x21, 0xc9, 0xcc, 0x7f, 0x1d
	.byte 0xed, 0x39, 0xf5, 0xc1, 0xd2, 0x32, 0xf1, 0x66
	.byte 0x17, 0xc1, 0x5f, 0xfc, 0x3c, 0xdf, 0x25, 0x48
	.byte 0x24, 0x05, 0x20, 0x00, 0x21, 0x00, 0x1d, 0xeb
	.byte 0x30, 0xf5, 0xe1, 0x32, 0x32, 0x25, 0x68, 0x08
AccVoice_ThirdReassign_MatchRev:
	ld	a, (13011:16)
	call	16070940
AccVoice_ThirdReassign_Apply:
	.byte 0x1e, 0x4c, 0xfe	; calr AccInit_AllPartPositions (v7 displacement)

	.byte 0x1d, 0x51, 0x3a, 0xf5	; call AccTuning_CopyAllPartsFromStyle (v7 addr)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)

	ret



AccBuf_WriteAllNotesOff:
	ld XHL,0x000029f8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x00, 0x9f, 0x1d, 0x55
	.byte 0x3c, 0xf5, 0xc1, 0x4e, 0x32, 0x21, 0xf1, 0x92
	.byte 0x33, 0x41, 0x1d, 0x17, 0x3c, 0xf5, 0x21, 0x7f
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0x1d, 0x55, 0x3c
	.byte 0xf5, 0xf3, 0x07, 0xec, 0xf4, 0x41, 0x1d, 0x55
	.byte 0x3c, 0xf5, 0xbb, 0x04, 0x55, 0x0e
AccBuf_AllNotesOffPadding:
	nop
	nop

AccBuf_ResetAll4:
	ld	xhl, 11256
	calr	25
	ld	xhl, 11512
	calr	17
	ld	xhl, 11768
	calr	9
	ld	xhl, 12024
	calr	1
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
	bit 1, (0x31e8:16)
	jr z, AccTiming_HelperReturn
	call SeqEvt_CallTimingHelper
	call 0xfe8d01
	call AccChord_ReadAndStoreKeys
	call AccChord_CompareAndSetDirty
	call Rhythm_CompareAndTrigger
AccTiming_HelperReturn:
	ret

AccVoice_SelectByMask:
	cp (0x3249:16), 0x80
	jr c, AccVoice_SelectByMask_Default
	ldb_erp w, 0x31
	andda8 w, (0x327b)
	jr nz, AccVoice_SelectByMask_Default
	bit 0, (0x32c7:16)
	jr nz, AccVoice_SelectByMask_Direct
	ld a, (0x327a:16)
	orda8 a, (0x327c)
	orda8 a, (0x3276)
	orda8 a, (0x3277)
	orda8 a, (0x3278)
	orda8 a, (0x3279)
	orda8 a, (0x328c)
	.byte 0xc7, 0x31, 0xc1, 0x6e, 0x05
AccVoice_SelectByMask_Direct:
	calr AccWave_BankResolve
	jr AccVoice_SelectReturn

AccVoice_SelectByMask_Default:
	ld	a, (12777:16)
	call	16092325
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
	xor	xhl, xhl
	xor	w, w
	ld	hl, wa
	sll	xhl, 2
	add	xhl, 16092365
	ld	xhl, (xhl)
	addda32	xhl, (12763)
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

	jrl nz, 244

	bit 2, (1054:16)

	jrl z, 237

	ld xhl, 12280

	xor iy, iy

	ldb_sri A, 0x07, 0xec, 0xf4



AccState_CollectKbd1_Loop:
	.byte 0xc3, 0x07, 0xec, 0xf4, 0xe1, 0xdd, 0xc8, 0x06
	.byte 0x00, 0xdd, 0xcf, 0x30, 0x00, 0x67, 0xf1, 0x43
	.byte 0x28, 0x30, 0x00, 0x00, 0xdd, 0xd5
AccState_CollectKbd2_Loop:
	.byte 0xc3, 0x07, 0xec, 0xf4, 0xe1, 0xdd, 0xc8, 0x06
	.byte 0x00, 0xdd, 0xcf, 0x30, 0x00, 0x67, 0xf1, 0x43
	.byte 0x58, 0x30, 0x00, 0x00, 0xdd, 0xd5
AccState_CollectAcc1_Loop:
	.byte 0xc3, 0x07, 0xec, 0xf4, 0xe1, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0xa0, 0x30, 0x00, 0x00, 0xdd, 0xd5
AccState_CollectAcc2_Loop:
	.byte 0xc3, 0x07, 0xec, 0xf4, 0xe1, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0xe8, 0x30, 0x00, 0x00, 0xdd, 0xd5
AccState_CollectAcc3_Loop:
	.byte 0xc3, 0x07, 0xec, 0xf4, 0xe1, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0x30, 0x31, 0x00, 0x00, 0xdd, 0xd5
AccState_CollectAcc4_Loop:
	or_srib_rm A, 0x07, 0xec, 0xf4
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
	.byte 0x1d, 0x91, 0x93, 0xf5, 0xc1, 0x43, 0xce, 0x21
	.byte 0xf1, 0xa6, 0x8c, 0x41, 0xc1, 0x44, 0xce, 0x21
	.byte 0xf1, 0xa4, 0x8c, 0x41, 0x1d, 0x1d, 0x33, 0xf5
	.byte 0xc1, 0x5f, 0xfc, 0x3c, 0xcf, 0xc1, 0xe7, 0x31
	.byte 0x3c, 0xfb, 0xc9, 0xd1, 0xf1, 0x78, 0x32, 0x41
	.byte 0xf1, 0x79, 0x32, 0x41, 0xf1, 0x76, 0x32, 0x41
	.byte 0xf1, 0x77, 0x32, 0x41, 0xf1, 0x7a, 0x32, 0x41
	.byte 0xf1, 0x7b, 0x32, 0x41, 0xf1, 0x7c, 0x32, 0x41
	.byte 0xc1, 0x03, 0x34, 0x3e, 0x02
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
	ld_rrb	a, xhl, iy
	cp	a, 131
	jr	z, 28	; -> 0xF58F11
	cp	a, 211
	jr	nz, 17	; -> 0xF58F0B
	call	AccBuf_Advance
	call	AccBuf_Advance
	ld_rrb	a, xhl, iy
	ld	(12951:16), a
AccVoice_ScanSkip:
	call AccBuf_Advance
	jr AccVoice_ScanForD3

AccVoice_ScanDone2:
	ret

AccVoice_SetupByteData:
	.byte 0xf1, 0x38, 0x33, 0x00, 0x04, 0xc1, 0xad, 0x32
	.byte 0x25, 0xf1, 0x97, 0x32, 0x00, 0x00, 0xe1, 0x32
	.byte 0x32, 0x25, 0xc1, 0x09, 0x32, 0xf5, 0x66, 0x1c
	.byte 0xcd, 0x89, 0x1d, 0x7a, 0x61, 0xf5, 0x1d, 0xcc
	.byte 0x68, 0xf5, 0xd8, 0x8d, 0xc1, 0xe9, 0x31, 0x21
	.byte 0x1d, 0xa5, 0x8c, 0xf5, 0x1d, 0xeb, 0x8e, 0xf5
	.byte 0xcd, 0x61, 0x68, 0xda, 0x0e, 0xf1, 0x38, 0x33
	.byte 0x00, 0x08, 0xc1, 0xad, 0x32, 0x25, 0xf1, 0x97
	.byte 0x32, 0x00, 0x00, 0xe1, 0x32, 0x32, 0x25, 0xc1
	.byte 0x0a, 0x32, 0xf5, 0x66, 0x1c, 0xcd, 0x89, 0x1d
	.byte 0x7a, 0x61, 0xf5, 0x1d, 0xcc, 0x68, 0xf5, 0xd8
	.byte 0x8d, 0xc1, 0xe9, 0x31, 0x21, 0x1d, 0xa5, 0x8c
	.byte 0xf5, 0x1d, 0xeb, 0x8e, 0xf5, 0xcd, 0x61, 0x68
	.byte 0xda, 0x0e, 0xf1, 0x38, 0x33, 0x00, 0x08, 0xc1
	.byte 0xad, 0x32, 0x25, 0xf1, 0x97, 0x32, 0x00, 0x00
	.byte 0xe1, 0x32, 0x32, 0x25, 0xc1, 0x0b, 0x32, 0xf5
	.byte 0x66, 0x1c, 0xcd, 0x89, 0x1d, 0x7a, 0x61, 0xf5
	.byte 0x1d, 0xcc, 0x68, 0xf5, 0xd8, 0x8d, 0xc1, 0xe9
	.byte 0x31, 0x21, 0x1d, 0xa5, 0x8c, 0xf5, 0x1d, 0xeb
	.byte 0x8e, 0xf5, 0xcd, 0x61, 0x68, 0xda, 0x0e, 0xf1
	.byte 0x38, 0x33, 0x00, 0x08, 0xc1, 0xad, 0x32, 0x25
	.byte 0xf1, 0x97, 0x32, 0x00, 0x00, 0xe1, 0x32, 0x32
	.byte 0x25, 0xc1, 0x0c, 0x32, 0xf5, 0x66, 0x1c, 0xcd
	.byte 0x89, 0x1d, 0x7a, 0x61, 0xf5, 0x1d, 0xcc, 0x68
	.byte 0xf5, 0xd8, 0x8d, 0xc1, 0xe9, 0x31, 0x21, 0x1d
	.byte 0xa5, 0x8c, 0xf5, 0x1d, 0xeb, 0x8e, 0xf5, 0xcd
	.byte 0x61, 0x68, 0xda, 0x0e, 0xc3, 0xf5, 0xd1, 0x03
	.byte 0x21, 0xf1, 0xe9, 0x31, 0x41, 0xf1, 0x38, 0x33
	.byte 0x00, 0x01, 0xc1, 0x07, 0x32, 0x21, 0x1d, 0x7a
	.byte 0x61, 0xf5, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xeb
	.byte 0x31, 0x50, 0xf1, 0x38, 0x33, 0x00, 0x02, 0xc1
	.byte 0x08, 0x32, 0x21, 0x1d, 0x7a, 0x61, 0xf5, 0x1d
	.byte 0xcc, 0x68, 0xf5, 0xf1, 0xed, 0x31, 0x50, 0xf1
	.byte 0x38, 0x33, 0x00, 0x04, 0xc1, 0x09, 0x32, 0x21
	.byte 0x1d, 0x7a, 0x61, 0xf5, 0x1d, 0xcc, 0x68, 0xf5
	.byte 0xf1, 0xef, 0x31, 0x50, 0xf1, 0x38, 0x33, 0x00
	.byte 0x08, 0xc1, 0x0a, 0x32, 0x21, 0x1d, 0x7a, 0x61
	.byte 0xf5, 0x1d, 0xcc, 0x68, 0xf5, 0xf1, 0xf1, 0x31
	.byte 0x50, 0xf1, 0x38, 0x33, 0x00, 0x10, 0xc1, 0x0b
	.byte 0x32, 0x21, 0x1d, 0x7a, 0x61, 0xf5, 0x1d, 0xcc
	.byte 0x68, 0xf5, 0xf1, 0xf3, 0x31, 0x50, 0xf1, 0x38
	.byte 0x33, 0x00, 0x20, 0xc1, 0x0c, 0x32, 0x27, 0x1d
	.byte 0x7a, 0x61, 0xf5, 0x1d, 0xcc, 0x68, 0xf5, 0xf1
	.byte 0xf5, 0x31, 0x50, 0x0e
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
	jr	z, 3
	or	w, 1
AccFlags_CheckDir65:
	ld	a, (12909:16)
	and	a, 3
	jr	z, 3
	or	w, 2
AccFlags_CheckDir67:
	ld	a, (12911:16)
	and	a, 3
	jr	z, 3
	or	w, 4
AccFlags_CheckNoteOn:
	.byte 0xf1, 0x70, 0x32, 0xc8, 0x66, 0x1f, 0xc8, 0xce
	.byte 0x08, 0xf1, 0xd4, 0x33, 0xce, 0x66, 0x08, 0xc8
	.byte 0xce, 0x02, 0xc1, 0x6d, 0x32, 0x3e, 0x01
AccFlags_PedalBit7:
	.byte 0xf1, 0xd4, 0x33, 0xcf, 0x66, 0x08, 0xc8, 0xce
	.byte 0x02, 0xc1, 0x6d, 0x32, 0x3e, 0x02
AccFlags_CheckSync69:
	.byte 0xf1, 0x71, 0x32, 0xc8, 0x66, 0x03, 0xc8, 0xce
	.byte 0x08
AccFlags_CheckSync71:
	.byte 0xf1, 0x73, 0x32, 0xc8, 0x66, 0x03, 0xc8, 0xce
	.byte 0x08
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
	.byte 0x1d, 0xfb, 0x82, 0xf5, 0x1d, 0x12, 0x84, 0xf5
	.byte 0xc1, 0x7a, 0x32, 0x3c, 0xc0, 0xc1, 0x7b, 0x32
	.byte 0x3c, 0xc0, 0xc1, 0x7c, 0x32, 0x3c, 0xc0, 0xc1
	.byte 0x76, 0x32, 0x3c, 0xc0, 0xc1, 0x77, 0x32, 0x3c
	.byte 0xc0, 0x68, 0x3e
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
	ld	xhl, 11256
	calr	25
	ld	xhl, 11512
	calr	17
	ld	xhl, 11768
	calr	9
	ld	xhl, 12024
	calr	1
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
	ldb A, 0x00
	ld XHL,0x00003058
	xor IY,IY
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0xa0, 0x30, 0x00, 0x00, 0xdd, 0xd5, 0xf3, 0x07
	.byte 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x09, 0x00, 0xdd
	.byte 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43, 0xe8, 0x30
	.byte 0x00, 0x00, 0xdd, 0xd5, 0xf3, 0x07, 0xec, 0xf4
	.byte 0x41, 0xdd, 0xc8, 0x09, 0x00, 0xdd, 0xcf, 0x48
	.byte 0x00, 0x67, 0xf1, 0x43, 0x30, 0x31, 0x00, 0x00
	.byte 0xdd, 0xd5, 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd
	.byte 0xc8, 0x09, 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67
	.byte 0xf1, 0x0e
AccNote_FlushAll:
	ld a, (0x3290:16)
	and A,0x3f
	jr z, AccNote_FlushReturn
	call RhythmPart_CopyData
	call RhythmPart1_ProcessAccentData
	ldb A, 0x01
	ld (0x3250:16), a
	call RhythmPart2_ProcessAccentData
	call AccVoice_LoadRhythmParams_Part3
	call AccVoice_LoadRhythmParams_Part4
	call AccVoice_LoadRhythmParams_Part5
	and (0x3290:16), 0xc0
AccNote_FlushReturn:
	ret

AccTempo_CalcPosition:
	ldb	a, 95
	ld	w, (1112:16)
	dec	1, w
	call	16082391
	ld	bc, (12769:16)
	ld	w, (12825:16)
	dec	1, w
	call	16084151
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
	orda8 a, (0x3277)
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
	jr	z, 3
	calr	62065
AccInit_ReInit_CheckSplit:
	.byte 0xc1, 0x6d, 0x32, 0x21, 0xc9, 0xcc, 0x03, 0x6e
	.byte 0x18, 0xf1, 0xd4, 0x33, 0xce, 0x66, 0x07, 0xc1
	.byte 0x6d, 0x32, 0x3e, 0x01, 0x68, 0x0b
AccInit_ReInit_CheckPedalBit7:
	.byte 0xf1, 0xd4, 0x33, 0xcf, 0x66, 0x08, 0xc1, 0x6d
	.byte 0x32, 0x3e, 0x02
AccInit_ReInit_ApplySplit:
	calr AccVoice_SplitPointSetup

AccInit_ReInit_CheckThird:
	ld	a, (12911:16)
	and	a, 3
	jr	z, 10
	calr	63633
	call	16094080
	calr	63076
AccInit_ReInit_ClearHighBits:
	.byte 0xc1, 0x0f, 0x32, 0x3c, 0xf0, 0xc1, 0x10, 0x32
	.byte 0x3c, 0xf0, 0xc1, 0x11, 0x32, 0x3c, 0xf0, 0xc1
	.byte 0x12, 0x32, 0x3c, 0xf0, 0xc1, 0x13, 0x32, 0x3c
	.byte 0xf0, 0xc1, 0x14, 0x32, 0x3c, 0xf0, 0x1e, 0x5f
	.byte 0xec, 0xf1, 0x58, 0x32, 0xce, 0x6e, 0x03, 0x1e
	.byte 0x34, 0xee
AccInit_ReInit_SetDirty:
	.byte 0xc1, 0x90, 0x32, 0x3e, 0x80	; ordi8 0x332c, 128 (v7 patched)

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
	xorda8 a, (0x32f6)
	bit 0x00,A
	jr z, AccTuning_ChangeReturn
	or (0x32f7:16), 0x01
AccTuning_ChangeReturn:
	ret

AccTuning_LoadFromROM:
	.byte 0x38, 0x3b, 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8
	.byte 0x10, 0x78, 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x76
	.byte 0x85, 0x00, 0x8b, 0x04, 0x21, 0xf1, 0xb8, 0x31
	.byte 0x41, 0x8b, 0x05, 0x21, 0xc9, 0x88, 0xc8, 0xcc
	.byte 0x7f, 0xf1, 0xb9, 0x31, 0x40, 0xc9, 0xcc, 0x80
	.byte 0xc9, 0xef, 0x07, 0xf1, 0xbb, 0x31, 0x41, 0x8b
	.byte 0x06, 0x21, 0xf1, 0xbf, 0x31, 0x41, 0x8b, 0x07
	.byte 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f, 0xf1, 0xc0
	.byte 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9, 0xef, 0x07
	.byte 0xf1, 0xc2, 0x31, 0x41, 0x8b, 0x08, 0x21, 0xf1
	.byte 0xc6, 0x31, 0x41, 0x8b, 0x09, 0x21, 0xc9, 0x88
	.byte 0xc8, 0xcc, 0x7f, 0xf1, 0xc7, 0x31, 0x40, 0xc9
	.byte 0xcc, 0x80, 0xc9, 0xef, 0x07, 0xf1, 0xc9, 0x31
	.byte 0x41, 0x8b, 0x02, 0x21, 0xf1, 0xb1, 0x31, 0x41
	.byte 0x8b, 0x03, 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f
	.byte 0xf1, 0xb2, 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9
	.byte 0xef, 0x07, 0xf1, 0xb4, 0x31, 0x41, 0x8b, 0x00
	.byte 0x21, 0xf1, 0xaa, 0x31, 0x41, 0x8b, 0x01, 0x21
	.byte 0xc9, 0xcc, 0x7f, 0xf1, 0xab, 0x31, 0x41
AccTuning_LoadReturn:
	pop xhl
	pop xwa
	ret

AccTuning_LoadMaster:
	.byte 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10, 0x78
	.byte 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x66, 0x11, 0x8b
	.byte 0x00, 0x21, 0xf1, 0xaa, 0x31, 0x41, 0x8b, 0x01
	.byte 0x21, 0xc9, 0xcc, 0x7f, 0xf1, 0xab, 0x31, 0x41
AccTuning_LoadMasterReturn:
	ret

AccTuning_LoadCoarse:
	.byte 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10, 0x78
	.byte 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x66, 0x1d, 0x8b
	.byte 0x02, 0x21, 0xf1, 0xb1, 0x31, 0x41, 0x8b, 0x03
	.byte 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f, 0xf1, 0xb2
	.byte 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9, 0xef, 0x07
	.byte 0xf1, 0xb4, 0x31, 0x41
AccTuning_LoadCoarseReturn:
	ret

AccTuning_LoadFine:
	.byte 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10, 0x78
	.byte 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x66, 0x1d, 0x8b
	.byte 0x04, 0x21, 0xf1, 0xb8, 0x31, 0x41, 0x8b, 0x05
	.byte 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f, 0xf1, 0xb9
	.byte 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9, 0xef, 0x07
	.byte 0xf1, 0xbb, 0x31, 0x41
AccTuning_LoadFineReturn:
	ret

AccTuning_LoadOctave:
	.byte 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10, 0x78
	.byte 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x66, 0x1d, 0x8b
	.byte 0x06, 0x21, 0xf1, 0xbf, 0x31, 0x41, 0x8b, 0x07
	.byte 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f, 0xf1, 0xc0
	.byte 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9, 0xef, 0x07
	.byte 0xf1, 0xc2, 0x31, 0x41
AccTuning_LoadOctaveReturn:
	ret

AccTuning_LoadTranspose:
	.byte 0x1d, 0xdd, 0xc9, 0xf5, 0xeb, 0xc8, 0x10, 0x78
	.byte 0x1e, 0x00, 0xbb, 0x01, 0xcf, 0x66, 0x1d, 0x8b
	.byte 0x08, 0x21, 0xf1, 0xc6, 0x31, 0x41, 0x8b, 0x09
	.byte 0x21, 0xc9, 0x88, 0xc8, 0xcc, 0x7f, 0xf1, 0xc7
	.byte 0x31, 0x40, 0xc9, 0xcc, 0x80, 0xc9, 0xef, 0x07
	.byte 0xf1, 0xc9, 0x31, 0x41
AccTuning_LoadTransposeReturn:
	ret

AccTuning_ApplyChange:
	bit 0, (0x32f7:16)
	jrl z, AccTuning_ApplyReturn
	call AccHelper_ComputeVoiceOffset
	add XHL,0x001e7810
	bit 0, (0x32f5:16)
	jr z, AccTuning_ApplyChange_ClearBit
	.byte 0x8b, 0x01, 0x3e, 0x80, 0x68, 0x04
AccTuning_ApplyChange_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_ApplyChange_SelectMode:
	ld	a, (12922:16)
	orda8	a, (12923)
	and	a, 63
	jrl	nz, 51
	ld	a, (12924:16)
	and	a, 63
	jr	nz, 46
	ld	a, (12920:16)
	and	a, 63
	jr	nz, 41
	orda8	a, (12921)
	and	a, 63
	jr	nz, 36
	ld	a, (12918:16)
	orda8	a, (12919)
	and	a, 63
	jr	nz, 27
	ld	a, (12993:16)
	and	a, 63
	jr	nz, 22
	jr	24
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
	.byte 0xc1, 0x07, 0x32, 0x21	; ldb_d8 a, (0x32a3) (v7 patched)

	.byte 0xe1, 0x32, 0x32, 0x25	; ldda32 xiy, (0x32ce) (v7 patched)

	.byte 0x1d, 0x82, 0x60, 0xf5	; call AccPart_GetVoiceParamOffsetTable (v7 addr)

	.byte 0x1d, 0x07, 0x3a, 0xf5	; call AccVoice_LoadTuningBlock (v7 addr)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x3f	; ordi8 0x332c, 63 (v7 patched)

	.byte 0xc1, 0x90, 0x32, 0x3e, 0x80	; ordi8 0x332c, 128 (v7 patched)



AccTuning_ApplyReturn:
	.byte 0xc1, 0xf7, 0x32, 0x3c, 0xfe	; anddi8 (0x3393), 254 (v7 patched)

	ret



AccTuning_Toggle:
	cp (0x3249:16), 0x80
	jr nc, AccTuning_Toggle_NoStyle
	ld a, (0x32f5:16)
	xorda8 a, (0x32f6)
	bit 0x00,A
	jr z, AccTuning_Toggle_CheckDirty
	call AccHelper_ComputeVoiceOffset
	add XHL,0x001e7810
	bit 0, (0x32f5:16)
	jr z, AccTuning_Toggle_ClearBit
	.byte 0x8b, 0x01, 0x3e, 0x80, 0x68, 0x04
AccTuning_Toggle_ClearBit:
	andmi8 (xhl + 1), 0x7f

AccTuning_Toggle_SetFlag:
	.byte 0xc1, 0x9f, 0x32, 0x3e, 0x01, 0x68, 0x1b
AccTuning_Toggle_CheckDirty:
	.byte 0xf1, 0xf7, 0x32, 0xc8, 0x66, 0x15, 0xc1, 0xf7
	.byte 0x32, 0x3c, 0xfe, 0xc1, 0x9f, 0x32, 0x3e, 0x01
	.byte 0x68, 0x09
AccTuning_Toggle_NoStyle:
	.byte 0xc1, 0xf5, 0x32, 0x3c, 0xfe	; anddi8 (0x3391), 254 (v7 patched)

	.byte 0x1d, 0x71, 0x96, 0xf5	; call AccTuning_LEDOff (v7 addr)



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
	ldb	a, 74
	call	16544114
	ret
AccTuning_LEDOff:
	ld	(13044:16), 0
	ldb	a, 74
	call	16544114
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
	ld	a, (49121:16)
	ld	(13294:16), a
	cps	a, 5
	jr	z, 6
	cps	a, 6
	jr	z, 2
	jr	32
AccPedal_TypeSustainOrExpr:
	ld	a, (49122:16)
	ld	(13282:16), a
	ld	a, (49123:16)
	cp	a, 255
	jr	nz, 2
	xor	a, a
AccPedal_ParseValue:
	ld	(13283:16), a
	calr	73
	calr	394
	calr	467
AccPedal_CheckType0:
	ld	a, (49121:16)
	cps	a, 0
	jr	z, 15
	cps	a, 7
	jr	nz, 14
	ld	a, (49123:16)
	and	a, 48
	cps	a, 0
	jr	z, 3
AccPedal_SavePosition:
	calr AccPos_SaveOnStop

AccPedal_EventReturn:
	ret

AccPedal_RawHandler:
	nop
	nop
	ld	a, (49121:16)
	cps	a, 3
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
	andda8 a, (0x33e3)
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
	call 0xfdb4ea
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
	ldb a, 0x86
	bit 1, (3411:16)
	jr nz, AccPedal_Sustain_WriteTempo
	ldb a, 0x85

AccPedal_Sustain_WriteTempo:
	calr AccTempo_WriteStopMarker

AccPedal_Sustain_PlayJump:
	jrl AccPedal_SustainReturn

AccPedal_Sustain_CheckMultiStyle:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x78, 0x66, 0x46, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x7a, 0x66, 0x3f, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x73, 0x66, 0x38, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x74, 0x66, 0x31, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x75, 0x66, 0x2a, 0xc1, 0x9a, 0x8c, 0x3f, 0x76
	.byte 0x66, 0x23, 0xc1, 0x9a, 0x8c, 0x3f, 0x77, 0x66
	.byte 0x1c, 0xc1, 0x9a, 0x8c, 0x3f, 0x79, 0x66, 0x15
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x6c, 0x66, 0x0e, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x6d, 0x66, 0x07, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x6e, 0x6e, 0x07
AccPedal_Sustain_MultiMatch:
	or (3381:16), 1
	jr AccPedal_SustainReturn

AccPedal_Sustain_Normal:
	bit 2, (0x28b2:16)
	jr nz, AccPedal_SustainReturn
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
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
	ldb a, 0x0
	jr AccPedal_StyleCheckReturn

AccPedal_StyleCheck_Ineligible:
	ldb a, 0x1

AccPedal_StyleCheckReturn:
	ret

AccPedal_ExprToggle:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_ExprReturn
	ld a, (0x33e2:16)
	andda8 a, (0x33e3)
	bit 0x01,A
	jr z, AccPedal_ExprReturn
	ldb A, 0x02
	.byte 0xc1, 0x5f, 0xfc, 0xd9, 0xc1, 0x5c, 0x90, 0x3f
	.byte 0xff, 0x66, 0x28, 0xf1, 0x56, 0xfd, 0xcb, 0x66
	.byte 0x22, 0xc1, 0x5f, 0xfc, 0x25, 0xcd, 0xcc, 0x02
	.byte 0x44, 0x4c, 0x38, 0x00, 0x00, 0xbc, 0x00, 0x00
	.byte 0x48, 0xbc, 0x01, 0x00, 0x05, 0xbc, 0x02, 0x45
	.byte 0xbc, 0x03, 0x00, 0x02, 0x3c, 0x1d, 0xf3, 0x9f
	.byte 0xfd, 0xef, 0x64
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
	.byte 0xd8, 0xd0, 0xf1, 0xe4, 0x33, 0x41, 0xf1, 0xe5
	.byte 0x33, 0x41, 0xf1, 0xe6, 0x33, 0x41, 0xf1, 0xe7
	.byte 0x33, 0x41, 0xf1, 0xe8, 0x33, 0x41, 0xf1, 0xe9
	.byte 0x33, 0x41, 0xf1, 0xea, 0x33, 0x41, 0xf1, 0xeb
	.byte 0x33, 0x41, 0x1e, 0xb9, 0x00, 0xf1, 0x53, 0x0d
	.byte 0xcb, 0x66, 0x19, 0xc1, 0x5f, 0xfc, 0x3c, 0x0f
	.byte 0xf1, 0xe5, 0x33, 0x00, 0x00, 0xf1, 0xe7, 0x33
	.byte 0x00, 0x00, 0xf1, 0xe9, 0x33, 0x00, 0x00, 0xf1
	.byte 0xeb, 0x33, 0x00, 0x00
AccPedal_Distribute_CheckRecord:
	.byte 0x1e, 0x75, 0x02, 0xf1, 0x53, 0x0d, 0xcb, 0x66
	.byte 0x1f, 0xc1, 0x65, 0x0d, 0x3f, 0x00, 0x66, 0x18
	.byte 0xd8, 0xd0, 0xf1, 0xe4, 0x33, 0x41, 0xf1, 0xe5
	.byte 0x33, 0x41, 0xf1, 0xe8, 0x33, 0x41, 0xf1, 0xe9
	.byte 0x33, 0x41, 0x1e, 0x24, 0x04, 0x1e, 0x03, 0x00
AccPedal_DistributeReturn:
	ret

AccPedal_DistributePadding:
	nop
	nop

AccPedal_SendEvents:
	ld	a, (13284:16)
	xor	a, 255
	andda8	a, (13285)
	cps	a, 0
	jr	z, 14
	ldb	b, 5
	ldb	c, 72
	ld	d, a
	ld	e, (13284:16)
	call	16556753
AccPedal_SendEvents_Group2:
	ld	a, (13288:16)
	xor	a, 255
	andda8	a, (13289)
	cps	a, 0
	jr	z, 14
	ldb	b, 6
	ldb	c, 72
	ld	d, a
	ld	e, (13288:16)
	call	16556753
AccPedal_SendEvents_OnSustain:
	ld	a, (13284:16)
	andda8	a, (13285)
	cps	a, 0
	jr	z, 14
	ldb	b, 5
	ldb	c, 72
	ld	d, a
	ld	e, (13284:16)
	call	16556753
AccPedal_SendEvents_OnExpr:
	ld	a, (13288:16)
	andda8	a, (13289)
	cps	a, 0
	jr	z, 14
	ldb	b, 6
	ldb	c, 72
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
	andda8 a, (0x33e3)
	bit 0x02,A
	jr z, AccPedal_Bit2_Off
	ordi16 (0x1108), 0x0004
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
	.byte 0xf1, 0xe3, 0x33, 0xca, 0x66, 0x20, 0xf1, 0xe2
	.byte 0x33, 0xca, 0x6e, 0x1a, 0xc1, 0x5c, 0x90, 0x3f
	.byte 0x7f, 0x66, 0x05, 0x1e, 0xe4, 0x04, 0x68, 0x0e
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
	andda8 a, (0x33e3)
	bit 0x02,A
	jr z, AccPedal_Expr_Off
	lds de, 4
	sla DE, 0x08
	.byte 0xd1, 0x08, 0x11, 0xea, 0xc1, 0x5c, 0x90, 0x3f
	.byte 0x7f, 0x66, 0x05, 0x1e, 0xc6, 0x04, 0x68, 0x0e
AccPedal_Expr_CheckPlay:
	bit 2, (1054:16)
	jr nz, AccPedal_Expr_Soft
	calr AccPedal_ExprOn
	jr AccPedal_Expr_Off

AccPedal_Expr_Soft:
	calr AccPedal_SoftOn

AccPedal_Expr_Off:
	.byte 0xf1, 0xe3, 0x33, 0xca, 0x66, 0x20, 0xf1, 0xe2
	.byte 0x33, 0xca, 0x6e, 0x1a, 0xc1, 0x5c, 0x90, 0x3f
	.byte 0x7f, 0x66, 0x05, 0x1e, 0x46, 0x05, 0x68, 0x0e
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
	andda8 a, (0x33e3)
	bit 0x07,A
	jr z, AccPedal_Bit7_Off
	ordi16 (0x1108), 0x0080
	bit 2, (0x041e:16)
	jr z, AccPedal_Bit7_Damper
	calr AccPedal_PortamentoOn
	jr t, AccPedal_Bit7_Off
AccPedal_Bit7_Damper:
	calr AccPedal_DamperOn

AccPedal_Bit7_Off:
	.byte 0xf1, 0xe3, 0x33, 0xcf, 0x66, 0x14, 0xf1, 0xe2
	.byte 0x33, 0xcf, 0x6e, 0x0e, 0xf1, 0x1e, 0x04, 0xca
	.byte 0x66, 0x05, 0x1e, 0xe6, 0x08, 0x68, 0x03
AccPedal_Bit7_OffDamper:
	calr AccPedal_DamperOff

AccPedal_Bit7_Return:
	ret

AccPedal_Bit6_Hold:
	cp (0x33ee:16), 0x05
	jr nz, AccPedal_Bit6_Return
	ld a, (0x33e2:16)
	andda8 a, (0x33e3)
	bit 0x06,A
	jr z, .Lc_f59b49
	ordi16 (0x1108), 0x0040
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
	andda8 a, (0x33e3)
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
	andda8 a, (0x33e3)
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
	andda8 a, (0x33e3)
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
	.byte 0xc1, 0x5c, 0x90, 0x3f, 0x7f, 0x66, 0x07, 0xc1
	.byte 0x5c, 0x90, 0x3f, 0xff, 0x6e, 0x03
AccPedal_Sync_SendEvents:
	calr AccPedal_SendEvents

AccPedal_Sync_DispatchAll:
	.byte 0xc1, 0x5c, 0x90, 0x3f, 0xff, 0x66, 0x10, 0x1d
	.byte 0x17, 0x9c, 0xf5, 0x1d, 0x84, 0x9c, 0xf5, 0x1d
	.byte 0xf1, 0x9c, 0xf5, 0x1d, 0x58, 0x9d, 0xf5
AccPedal_Sync_Return:
	ret

AccPedal_SendCtrl1:
	.byte 0xc1, 0xe6, 0x33, 0x21, 0xc9, 0xcd, 0xff, 0xc1
	.byte 0xe7, 0x33, 0xc1, 0xc9, 0xd8, 0x66, 0x5d, 0xf1
	.byte 0x56, 0xfd, 0xcb, 0x66, 0x21, 0x22, 0x05, 0xc9
	.byte 0x8c, 0xc1, 0xe6, 0x33, 0x25, 0x44, 0x4c, 0x38
	.byte 0x00, 0x00, 0xbc, 0x00, 0x00, 0x48, 0xbc, 0x01
	.byte 0x42, 0xbc, 0x02, 0x45, 0xbc, 0x03, 0x44, 0x3c
	.byte 0x1d, 0xf3, 0x9f, 0xfd, 0xef, 0x64
AccPedal_SendCtrl1_CheckPort:
	.byte 0xf1, 0x50, 0xfd, 0xcc, 0x6e, 0x30, 0xc1, 0x48
	.byte 0x90, 0x21, 0xc9, 0xcc, 0x8f, 0xf1, 0x49, 0x90
	.byte 0x41, 0xc1, 0x5c, 0x90, 0x3f, 0x7f, 0x6e, 0x05
	.byte 0xc1, 0x49, 0x90, 0x3c, 0x7f
AccPedal_SendCtrl1_UpdateMask:
	ld	a, (13286:16)
	xor	a, 255
	andda8	a, (13287)
	ldb	b, 5
	ldb	c, 72
	ld	d, a
	ld	e, (13286:16)
	call	16579981
AccPedal_SendCtrl1_Return:
	ret

AccPedal_SendCtrl2:
	.byte 0xc1, 0xea, 0x33, 0x21, 0xc9, 0xcd, 0xff, 0xc1
	.byte 0xeb, 0x33, 0xc1, 0xc9, 0xd8, 0x66, 0x5d, 0xf1
	.byte 0x56, 0xfd, 0xcb, 0x66, 0x21, 0x22, 0x06, 0xc9
	.byte 0x8c, 0xc1, 0xea, 0x33, 0x25, 0x44, 0x4c, 0x38
	.byte 0x00, 0x00, 0xbc, 0x00, 0x00, 0x48, 0xbc, 0x01
	.byte 0x42, 0xbc, 0x02, 0x45, 0xbc, 0x03, 0x44, 0x3c
	.byte 0x1d, 0xf3, 0x9f, 0xfd, 0xef, 0x64
AccPedal_SendCtrl2_CheckPort:
	.byte 0xf1, 0x50, 0xfd, 0xcc, 0x6e, 0x30, 0xc1, 0x48
	.byte 0x90, 0x21, 0xc9, 0xcc, 0x8f, 0xf1, 0x49, 0x90
	.byte 0x41, 0xc1, 0x5c, 0x90, 0x3f, 0x7f, 0x6e, 0x05
	.byte 0xc1, 0x49, 0x90, 0x3c, 0x7f
AccPedal_SendCtrl2_UpdateMask:
	ld	a, (13290:16)
	xor	a, 255
	andda8	a, (13291)
	ldb	b, 6
	ldb	c, 72
	ld	d, a
	ld	e, (13290:16)
	call	16579981
AccPedal_SendCtrl2_Return:
	ret

AccPedal_SendCtrl3:
	.byte 0xc1, 0xe6, 0x33, 0x21, 0xc1, 0xe7, 0x33, 0xc1
	.byte 0xc9, 0xd8, 0x66, 0x5a, 0xf1, 0x56, 0xfd, 0xcb
	.byte 0x66, 0x21, 0x22, 0x05, 0xc9, 0x8c, 0xc1, 0xe6
	.byte 0x33, 0x25, 0x44, 0x4c, 0x38, 0x00, 0x00, 0xbc
	.byte 0x00, 0x00, 0x48, 0xbc, 0x01, 0x42, 0xbc, 0x02
	.byte 0x45, 0xbc, 0x03, 0x44, 0x3c, 0x1d, 0xf3, 0x9f
	.byte 0xfd, 0xef, 0x64
AccPedal_SendCtrl3_CheckPort:
	.byte 0xf1, 0x50, 0xfd, 0xcc, 0x6e, 0x2d, 0xc1, 0x48
	.byte 0x90, 0x21, 0xc9, 0xcc, 0x8f, 0xf1, 0x49, 0x90
	.byte 0x41, 0xc1, 0x5c, 0x90, 0x3f, 0x7f, 0x6e, 0x05
	.byte 0xc1, 0x49, 0x90, 0x3c, 0x7f
AccPedal_SendCtrl3_UpdateMask:
	ld	a, (13286:16)
	andda8	a, (13287)
	ldb	b, 5
	ldb	c, 72
	ld	d, a
	ld	e, (13286:16)
	call	16579981
AccPedal_SendCtrl3_Return:
	ret

AccPedal_SendCtrl4:
	.byte 0xc1, 0xea, 0x33, 0x21, 0xc1, 0xeb, 0x33, 0xc1
	.byte 0xc9, 0xd8, 0x66, 0x5a, 0xf1, 0x56, 0xfd, 0xcb
	.byte 0x66, 0x21, 0x22, 0x06, 0xc9, 0x8c, 0xc1, 0xea
	.byte 0x33, 0x25, 0x44, 0x4c, 0x38, 0x00, 0x00, 0xbc
	.byte 0x00, 0x00, 0x48, 0xbc, 0x01, 0x42, 0xbc, 0x02
	.byte 0x45, 0xbc, 0x03, 0x44, 0x3c, 0x1d, 0xf3, 0x9f
	.byte 0xfd, 0xef, 0x64
AccPedal_SendCtrl4_CheckPort:
	.byte 0xf1, 0x50, 0xfd, 0xcc, 0x6e, 0x2d, 0xc1, 0x48
	.byte 0x90, 0x21, 0xc9, 0xcc, 0x8f, 0xf1, 0x49, 0x90
	.byte 0x41, 0xc1, 0x5c, 0x90, 0x3f, 0x7f, 0x6e, 0x05
	.byte 0xc1, 0x49, 0x90, 0x3c, 0x7f
AccPedal_SendCtrl4_UpdateMask:
	ld	a, (13290:16)
	andda8	a, (13291)
	ldb	b, 6
	ldb	c, 72
	ld	d, a
	ld	e, (13290:16)
	call	16579981
AccPedal_SendCtrl4_Return:
	ret

AccPedal_MapToAcc:
	.byte 0xc1, 0xee, 0x33, 0x3f, 0x05, 0x6e, 0x21, 0xc1
	.byte 0xe2, 0x33, 0x21, 0xc1, 0xe3, 0x33, 0xc1, 0xc9
	.byte 0x33, 0x06, 0x66, 0x14, 0x1d, 0xfc, 0x95, 0xef
	.byte 0xf1, 0x53, 0x0d, 0xc9, 0x66, 0x0a, 0xc1, 0xe5
	.byte 0x33, 0x3e, 0x40, 0xc1, 0xe4, 0x33, 0x3e, 0x40
AccPedal_MapToAcc_Send:
	.byte 0xc1, 0xee, 0x33, 0x3f, 0x05, 0x6e, 0x2d, 0xc1
	.byte 0xe2, 0x33, 0x21, 0xc1, 0xe3, 0x33, 0xc1, 0xc9
	.byte 0x33, 0x07, 0x66, 0x20, 0x1d, 0xfc, 0x95, 0xef
	.byte 0xf1, 0x53, 0x0d, 0xc9, 0x66, 0x0c, 0xc1, 0xe5
	.byte 0x33, 0x3e, 0x80, 0xc1, 0xe4, 0x33, 0x3e, 0x80
	.byte 0x68, 0x0a
AccPedal_MapToAcc_CheckDir:
	.byte 0xc1, 0xe5, 0x33, 0x3e, 0x08	; ordi8 0x3481, 8 (v7 patched)

	.byte 0xc1, 0xe4, 0x33, 0x3e, 0x08	; ordi8 0x3480, 8 (v7 patched)



AccPedal_MapToAcc_UpdateMask:
	.byte 0xc1, 0xee, 0x33, 0x3f, 0x05, 0x6e, 0x2d, 0xc1
	.byte 0xe2, 0x33, 0x21, 0xc1, 0xe3, 0x33, 0xc1, 0xc9
	.byte 0x33, 0x02, 0x66, 0x20, 0x1d, 0xfc, 0x95, 0xef
	.byte 0xf1, 0x53, 0x0d, 0xc9, 0x66, 0x0c, 0xc1, 0xe5
	.byte 0x33, 0x3e, 0x10, 0xc1, 0xe4, 0x33, 0x3e, 0x10
	.byte 0x68, 0x0a
AccPedal_MapToAcc_ClearMask:
	.byte 0xc1, 0xe5, 0x33, 0x3e, 0x04	; ordi8 0x3481, 4 (v7 patched)

	.byte 0xc1, 0xe4, 0x33, 0x3e, 0x04	; ordi8 0x3480, 4 (v7 patched)



AccPedal_MapToAcc_SetMask:
	.byte 0xc1, 0xee, 0x33, 0x3f, 0x06, 0x6e, 0x2d, 0xc1
	.byte 0xe2, 0x33, 0x21, 0xc1, 0xe3, 0x33, 0xc1, 0xc9
	.byte 0x33, 0x02, 0x66, 0x20, 0x1d, 0xfc, 0x95, 0xef
	.byte 0xf1, 0x53, 0x0d, 0xc9, 0x66, 0x0c, 0xc1, 0xe5
	.byte 0x33, 0x3e, 0x20, 0xc1, 0xe4, 0x33, 0x3e, 0x20
	.byte 0x68, 0x0a
AccPedal_MapToAcc_Apply:
	.byte 0xc1, 0xe9, 0x33, 0x3e, 0x04	; ordi8 0x3485, 4 (v7 patched)

	.byte 0xc1, 0xe8, 0x33, 0x3e, 0x04	; ordi8 0x3484, 4 (v7 patched)



AccPedal_MapToAcc_Return:
	.byte 0xc1, 0xee, 0x33, 0x3f, 0x05, 0x6e, 0x23, 0xc1
	.byte 0xe2, 0x33, 0x21, 0xc1, 0xe3, 0x33, 0xc1, 0xc9
	.byte 0x33, 0x05, 0x66, 0x16, 0x1d, 0xfc, 0x95, 0xef
	.byte 0xf1, 0x53, 0x0d, 0xc9, 0x66, 0x0c, 0xc1, 0xe5
	.byte 0x33, 0x3e, 0x20, 0xc1, 0xe4, 0x33, 0x3e, 0x20
	.byte 0x68, 0x00
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
	.byte 0xf1, 0x5f, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xe7, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xfb, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe4, 0x33, 0x3c, 0xfb
AccPedal_SostenutoOn_Finalize:
	.byte 0xf1, 0x5f, 0xfc, 0xcb, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xf7, 0xc1, 0xe7, 0x33, 0x3e, 0x08
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xf7, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x08, 0xc1, 0xe4, 0x33, 0x3c, 0xf7
AccPedal_SostenutoOn_CheckAlt:
	.byte 0xf1, 0x60, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xeb, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xea, 0x33, 0x3c, 0xfb, 0xc1, 0xe9, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe8, 0x33, 0x3c, 0xfb
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
	.byte 0xf1, 0x5f, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xe7, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xfb, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe4, 0x33, 0x3c, 0xfb
AccPedal_SoftOn_Finalize:
	.byte 0xf1, 0x5f, 0xfc, 0xcb, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xf7, 0xc1, 0xe7, 0x33, 0x3e, 0x08
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xf7, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x08, 0xc1, 0xe4, 0x33, 0x3c, 0xf7
AccPedal_SoftOn_CheckAlt:
	.byte 0xf1, 0x60, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xeb, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xea, 0x33, 0x3c, 0xfb, 0xc1, 0xe9, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe8, 0x33, 0x3c, 0xfb
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
	.byte 0xf1, 0x5f, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xe7, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xfb, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe4, 0x33, 0x3c, 0xfb
AccPedal_HoldOn_Post:
	.byte 0xf1, 0x5f, 0xfc, 0xcb, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xf7, 0xc1, 0xe7, 0x33, 0x3e, 0x08
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xf7, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x08, 0xc1, 0xe4, 0x33, 0x3c, 0xf7
AccPedal_HoldOn_Finalize:
	.byte 0xf1, 0x60, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xeb, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xea, 0x33, 0x3c, 0xfb, 0xc1, 0xe9, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe8, 0x33, 0x3c, 0xfb
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
	.byte 0xf1, 0x5f, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xe7, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xfb, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe4, 0x33, 0x3c, 0xfb
AccPedal_PortamentoOn_Post:
	.byte 0xf1, 0x5f, 0xfc, 0xcb, 0x66, 0x19, 0xc1, 0x5f
	.byte 0xfc, 0x3c, 0xf7, 0xc1, 0xe7, 0x33, 0x3e, 0x08
	.byte 0xc1, 0xe6, 0x33, 0x3c, 0xf7, 0xc1, 0xe5, 0x33
	.byte 0x3e, 0x08, 0xc1, 0xe4, 0x33, 0x3c, 0xf7
AccPedal_PortamentoOn_Finalize:
	.byte 0xf1, 0x60, 0xfc, 0xca, 0x66, 0x19, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0xc1, 0xeb, 0x33, 0x3e, 0x04
	.byte 0xc1, 0xea, 0x33, 0x3c, 0xfb, 0xc1, 0xe9, 0x33
	.byte 0x3e, 0x04, 0xc1, 0xe8, 0x33, 0x3c, 0xfb
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
	.byte 0xf1, 0xd4, 0x33, 0xcf, 0x66, 0x19, 0xc1, 0xd4
	.byte 0x33, 0x3c, 0x7f, 0xc1, 0xe5, 0x33, 0x3e, 0x80
	.byte 0xc1, 0xe4, 0x33, 0x3c, 0x7f, 0xc1, 0xe7, 0x33
	.byte 0x3e, 0x80, 0xc1, 0xe6, 0x33, 0x3c, 0x7f
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
	cps a, 1
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
	call 0xfdb4ea
	pop XIZ
	pop XIY
	pop XIX
	pop XDE
	pop XBC
	pop XHL
	pop XWA
	calr AccAutoPlay_SplitDetect
	cps c, 0
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
	call 0xfdd69e
AccAutoPlay_NoteDispatch_Return:
	ret

AccAutoPlay_SplitDetect:
	ldb c, 0x0
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
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Upper:
	ldb c, 0x0
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
	ld l, (0xf9f7:16)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Store
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Store
	ldb c, 0x1
	jr AccAutoPlay_SplitDetect_Return

AccAutoPlay_SplitDetect_Store:
	ld l, (0xfbe5:16)
	bit 7, l
	jr nz, AccAutoPlay_SplitDetect_Return
	and l, 0xf
	cp l, w
	jr nz, AccAutoPlay_SplitDetect_Return
	ldb c, 0x1

AccAutoPlay_SplitDetect_Return:
	ret

AccAutoPlay_ZoneTrack:
	cp (0x7e6f:16), 0x00
	jr nz, AccAutoPlay_ZoneTrack_Update
	pushw wa
	calr AccPedal_StyleCheck
	cps a, 1
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
	cps	wa, 0
	jr	nz, 4
	ldb	l, 128
	jr	10
AccAutoPlay_ZoneTrack_Check:
	cps wa, 1
	jr nz, AccAutoPlay_ZoneTrack_Upper
	ldb l, 0x0
	jr AccAutoPlay_ZoneTrack_Store

AccAutoPlay_ZoneTrack_Upper:
	ldb l, 0xf0

AccAutoPlay_ZoneTrack_Store:
	ld w, l

	calr 39

	ldw (14412:16), 0

	ld bc, (xix + 256)

	ldb e, 0x5



AccAutoPlay_ZoneTrack_Clear:
	cps	bc, 0
	jr	z, 19
	ld_rr8b	a, xix, e
	cp	l, a
	jr	c, 4
	incw	1, (14412:16)
AccAutoPlay_ZoneTrack_Finalize:
	inc 2, e
	dec 1, bc
	jr AccAutoPlay_ZoneTrack_Clear

AccAutoPlay_ZoneTrack_Default:
	ld	wa, (14412:16)
	ret
AccAutoPlay_ZoneTrack_SetFlag:
	ldb c, 0x0
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
	ldb l, 0x7f

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
	.byte 0xc1, 0xfc, 0x33, 0x3e, 0x01, 0xc1, 0xfd, 0x33
	.byte 0x3e, 0x01, 0x68, 0x59
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
	.byte 0xc1, 0xfc, 0x33, 0x3c, 0xfe, 0xc1, 0xfd, 0x33
	.byte 0x3c, 0xfe, 0x68, 0x00
AccAutoPlay_ModeAvail_Padding:
	.byte 0xc1, 0xfc, 0x33, 0x3c, 0x7f	; anddi8 (0x3498), 127 (v7 patched)



AccAutoPlay_ModeAvail_Padding2:
	ret

AccAutoPlay_ModeAvail_Padding3:
	nop
	nop

AccAutoPlay_ModeAvail:
	ld l, (0xfd02:16)
	and l, 0x3
	cps l, 0
	jr nz, AccAutoPlay_ModeAvail_Process
	ld l, (0xfd03:16)
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
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x0e, 0x6e, 0x02, 0x27
	.byte 0x7f
AccAutoPlay_ModeAvail_Return:
	ret

AccAutoPlay_ModeAvail_Extended:
	.byte 0x00, 0x00, 0x3b, 0x36, 0x3b, 0x42, 0x47, 0xf1
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
	cps a, 0
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
	.byte 0xf1, 0xd2, 0x33, 0xca, 0x66, 0x15, 0x1e, 0x2e
	.byte 0xff, 0xf1, 0xd1, 0x33, 0xcf, 0x6e, 0x05, 0x1e
	.byte 0x1d, 0x00, 0x68, 0x00
AccAutoPlay_Periodic_Padding:
	.byte 0xc1, 0xd2, 0x33, 0x3c, 0xfb, 0x68, 0x13
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

	ldb w, 0x2

	ldb a, 0x0

	ldb d, 0x5

	ldb e, 0x48

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
	cps a, 2
	jr nz, .Lc_f5a919
	or (0x33d2:16), 0xa0
	jr t, AccAutoPlay_ModeDecode_Return
AccAutoPlay_ModeDecode_Process:
.Lc_f5a919:
	cps a, 1
	jr nz, .Lc_f5a924
	or (0x33d2:16), 0x60
	jr t, AccAutoPlay_ModeDecode_Return
AccAutoPlay_ModeDecode_Apply:
.Lc_f5a924:
	cps a, 3
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
	cps	a, 0
	ld	a, b
	jr	z, 44
	bit	7, a
	jr	z, 20
	bit	5, a
	jr	nz, 5
	calr	446
	jr	18
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
	ld xwa, AccPlayMode_Dispatch_Table_0x2
	add xhl, xwa
	ld xwa, (xhl)
	call (xwa)
	ei 0
	ret

AccPlayMode_Dispatch_Table:
	.byte 0x00, 0x00, 0x15, 0xaa, 0xf5, 0x00, 0x49, 0xab
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

	.byte 0xc1, 0xd8, 0x33, 0x3e, 0x01	; ordi8 0x3474, 1 (v7 patched)

	.byte 0x1e, 0xf6, 0x00	; calr AccTempo_ClearPositions (v7 displacement)

	ldb a, 0x85

	.byte 0x1e, 0x4b, 0x01	; calr AccTempo_WriteStartMarker (v7 displacement)



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
	ldb	a, 134
	calr	296
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
	ldb a, 0x86
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
	ldb A, 0x85
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
	di
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
	.byte 0xc1, 0xf5, 0x33, 0x3c, 0xfe	; anddi8 (0x3491), 254 (v7 patched)

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
	calr	59794
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
	lds	wa, 0
	ldb	d, 5
	ldb	e, 72
	call	16624672
	lds	wa, 0
	ldb	d, 6
	ldb	e, 72
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
	cps	l, 0
	jr	nz, 17
	ld	(49121:16), 5
	ld	(49122:16), 4
	ld	(49123:16), 4
	jr	15
AccReplay_SendPedal_Process:
	ld	(49121:16), 6
	ld	(49122:16), 4
	ld	(49123:16), 4
AccReplay_SendPedal_Dispatch:
	ld	a, (36956:16)
	pushw	wa
	ld	(36956:16), 0
	calr	59663
	popw	wa
	ld	(36956:16), a
	popw	wa
	ld	(49122:16), w
	ld	(49123:16), a
	popw	wa
	ld	(49121:16), a
	lds	wa, 0
	ldb	d, 5
	ldb	e, 72
	call	16624672
	lds	wa, 0
	ldb	d, 6
	ldb	e, 72
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
	calr	59566
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
	lds	wa, 0
	ldb	d, 5
	ldb	e, 72
	call	16624672
	lds	wa, 0
	ldb	d, 6
	ldb	e, 72
	call	16624672
	call	16635840
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
	ld a, (0xfc5f:16)
	and A,0x0c
	ld c, (0xfc60:16)
	and C,0x04
	or A,C
	cps a, 0
	jr z, .Lc_f5aef4
	and (0xfc5f:16), 0xf3
	lds wa, 0
	ldb D, 0x05
	ldb E, 0x48
	call SysEx_ApplyVoiceParam_49
	and (0xfc60:16), 0xfb
	lds wa, 0
	ldb D, 0x06
	ldb E, 0x48
	call SysEx_ApplyVoiceParam_49
AccReplay_Stop_ClearPedals:
.Lc_f5aef4:
	call Seq_DispatcherEntry
	cp (0x33dd:16), 0x00
	jr z, .Lc_f5af0c
	ld a, (0x33dd:16)
	adddm8 0x0437, a
	ld (0x33dd:16), 0x00
AccReplay_Stop_ResetPosition:
.Lc_f5af0c:
	and (0x0437:16), 0x07
	ld a, (0x0437:16)
	cp a, (0x0433:16)
	jr c, .Lc_f5af2b
	subda8 a, (0x0433)
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
	cps de, 0
	jr z, AccReplay_Stop_Finalize
	sub E,0x18
	jr nc, AccReplay_Stop_CheckMode
	add E,0x60
	dec 1,D
	cp D,0xff
	jr nz, AccReplay_Stop_CheckMode
	lds de, 0
AccReplay_Stop_CheckMode:
	xor bc, bc

	.byte 0xc1, 0xde, 0x33, 0x3c, 0x7f	; anddi8 (0x347a), 127 (v7 patched)



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
	.byte 0xf1, 0xde, 0x33, 0xcf, 0x6e, 0x11, 0xda, 0xf1
	.byte 0x67, 0xda, 0xc1, 0xde, 0x33, 0x3e, 0x80, 0xda
	.byte 0xf1, 0x66, 0xd1, 0xda, 0x89, 0x68, 0xcd
AccReplay_Stop_Finalize:
	ld a, (1078:16)

	ld (1045:16), a

	ld a, (1079:16)

	ld (1046:16), a

	.byte 0xc1, 0xde, 0x33, 0x3c, 0xfe	; anddi8 (0x347a), 254 (v7 patched)

	.byte 0x1d, 0xdd, 0x2e, 0xf5	; call Seq_DispatcherEntry (v7 addr)

	ret



AccReplay_Stop_Return:
	nop
	nop

AccPos_SaveOnStop:
	ld a, (0xbfe3:16)
	cps a, 0
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
	cps a, 0
	jr nz, .Lc_f5b041
	ld (0x33dd:16), 0x00
	calr AccReplay_FullStop
	and (0x33de:16), 0xfd
.Lc_f5b041:
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
	xorda8	a, (13279)
	bit	2, a
	jr	z, 6
	ldb	a, 34
	call	16544114
AccFlags_Sync_UpdateLED:
	.byte 0xf1, 0xdf, 0x33, 0x45, 0xf1, 0x02, 0x34, 0xc8
	.byte 0x66, 0x05, 0xc1, 0x02, 0x34, 0x3c, 0xfe
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
	calr	1139
	ld	xbc, 12328
	calr	1131
	ldw	(13024:16), 9
	ldw	(13026:16), 72
	ld	(13040:16), 7
	ld	xbc, 12376
	calr	2041
	ld	(13040:16), 4
	ld	xbc, 12448
	calr	2028
	ld	(13040:16), 5
	ld	xbc, 12520
	calr	2015
	ld	(13040:16), 6
	ld	xbc, 12592
	calr	2002
	ld	wa, (13016:16)
	ld	(13014:16), wa
	jr	0
AccTiming_MasterTick_Return:
	ret

AccTiming_MasterTick:
	.byte 0xf1, 0xdb, 0x32, 0x00, 0x5f, 0xf1, 0xe0, 0x32
	.byte 0x02, 0x06, 0x00, 0xf1, 0xe2, 0x32, 0x02, 0x30
	.byte 0x00, 0xc1, 0xe9, 0x32, 0x21, 0xf1, 0xe8, 0x32
	.byte 0x41, 0x43, 0xf8, 0x29, 0x00, 0x00, 0x41, 0xf8
	.byte 0x2f, 0x00, 0x00, 0x1e, 0x09, 0x01, 0xc1, 0xe8
	.byte 0x32, 0x21, 0xf1, 0xe9, 0x32, 0x41, 0xc1, 0xea
	.byte 0x32, 0x21, 0xf1, 0xe8, 0x32, 0x41, 0x43, 0xf8
	.byte 0x2a, 0x00, 0x00, 0x41, 0x28, 0x30, 0x00, 0x00
	.byte 0x1e, 0xec, 0x00, 0xc1, 0xe8, 0x32, 0x21, 0xf1
	.byte 0xea, 0x32, 0x41, 0xf1, 0xe0, 0x32, 0x02, 0x09
	.byte 0x00, 0xc1, 0xf1, 0x32, 0x3c, 0xfe, 0xf1, 0xe2
	.byte 0x32, 0x02, 0x48, 0x00, 0xf1, 0xf0, 0x32, 0x00
	.byte 0x07, 0xc1, 0xeb, 0x32, 0x21, 0xf1, 0xe8, 0x32
	.byte 0x41, 0xc1, 0x93, 0x32, 0x21, 0xf1, 0x97, 0x32
	.byte 0x41, 0x43, 0xf8, 0x2b, 0x00, 0x00, 0x41, 0x58
	.byte 0x30, 0x00, 0x00, 0x1e, 0x39, 0x04, 0xc1, 0xe8
	.byte 0x32, 0x21, 0xf1, 0xeb, 0x32, 0x41, 0xc1, 0x97
	.byte 0x32, 0x21, 0xf1, 0x93, 0x32, 0x41, 0xf1, 0xf0
	.byte 0x32, 0x00, 0x04, 0xc1, 0xec, 0x32, 0x21, 0xf1
	.byte 0xe8, 0x32, 0x41, 0xc1, 0x94, 0x32, 0x21, 0xf1
	.byte 0x97, 0x32, 0x41, 0x43, 0xf8, 0x2c, 0x00, 0x00
	.byte 0x41, 0xa0, 0x30, 0x00, 0x00, 0x1e, 0x07, 0x04
	.byte 0xc1, 0xe8, 0x32, 0x21, 0xf1, 0xec, 0x32, 0x41
	.byte 0xc1, 0x97, 0x32, 0x21, 0xf1, 0x94, 0x32, 0x41
	.byte 0xf1, 0xf0, 0x32, 0x00, 0x05, 0xc1, 0xed, 0x32
	.byte 0x21, 0xf1, 0xe8, 0x32, 0x41, 0xc1, 0x95, 0x32
	.byte 0x21, 0xf1, 0x97, 0x32, 0x41, 0x43, 0xf8, 0x2d
	.byte 0x00, 0x00, 0x41, 0xe8, 0x30, 0x00, 0x00, 0x1e
	.byte 0xd5, 0x03, 0xc1, 0xe8, 0x32, 0x21, 0xf1, 0xed
	.byte 0x32, 0x41, 0xc1, 0x97, 0x32, 0x21, 0xf1, 0x95
	.byte 0x32, 0x41, 0xf1, 0xf0, 0x32, 0x00, 0x06, 0xc1
	.byte 0xee, 0x32, 0x21, 0xf1, 0xe8, 0x32, 0x41, 0xc1
	.byte 0x96, 0x32, 0x21, 0xf1, 0x97, 0x32, 0x41, 0x43
	.byte 0xf8, 0x2e, 0x00, 0x00, 0x41, 0x30, 0x31, 0x00
	.byte 0x00, 0x1e, 0xa3, 0x03, 0xc1, 0xe8, 0x32, 0x21
	.byte 0xf1, 0xee, 0x32, 0x41, 0xc1, 0x97, 0x32, 0x21
	.byte 0xf1, 0x96, 0x32, 0x41, 0xc1, 0xdb, 0x32, 0x21
	.byte 0xf1, 0xda, 0x32, 0x41, 0x68, 0x00
AccKbdTiming_Ret:
	ret

AccKbdTiming_ScanRingBuf:
	ld	(14812:16), 255
	ld	ix, (xhl+6)
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
	ld	(13028:16), 2
	jr	38
AccKbdTiming_CheckNoteOn:
	cp	a, 144
	jr	nz, 7
	ld	(13028:16), 4
	jr	26
AccKbdTiming_CheckProgramChg:
	and	a, 240
	cp	a, 192
	jr	nz, 7
	ld	(13028:16), 5
	jr	11
AccKbdTiming_CheckControl:
	cp	a, 208
	jrl	nz, 178
	ld	(13028:16), 2
AccKbdTiming_StoreEventData:
	.byte 0xf1, 0xdd, 0x39, 0x41, 0xc3, 0x07, 0xec, 0xf0
	.byte 0x21, 0xf1, 0xdc, 0x32, 0x54, 0xdc, 0x61, 0x9b
	.byte 0x02, 0xf4, 0x63, 0x03, 0x9b, 0x00, 0x24
AccKbdTiming_CheckTimestamp:
	.byte 0xc1, 0x5d, 0x04, 0xf1, 0x7b, 0xb7, 0x01, 0xc8
	.byte 0x89, 0xc9, 0xcc, 0xf0, 0xc8, 0xcf, 0x9f, 0x76
	.byte 0x26, 0x01, 0xc8, 0xcf, 0xdf, 0x76, 0x20, 0x01
	.byte 0xc9, 0xcf, 0x90, 0x7e, 0x15, 0x01, 0xc1, 0xdc
	.byte 0x39, 0x3f, 0x00, 0x6e, 0x10, 0x28, 0x21, 0x08
	.byte 0xf1, 0xe0, 0x39, 0x41, 0x48, 0x1e, 0xd5, 0x01
	.byte 0xf1, 0xdc, 0x39, 0x00, 0xff
AccKbdTiming_NoteSlotScan:
	xor iz, iz

AccKbdTiming_SlotLoop:
	.byte 0xd1, 0xe2, 0x32, 0xf6, 0x6f, 0x0d, 0xf3, 0x07
	.byte 0xe4, 0xf8, 0xcf, 0x66, 0x5b, 0xd1, 0xe0, 0x32
	.byte 0x86, 0x68, 0xed
AccKbdTiming_SlotOverflow:
	.byte 0x28, 0xe8, 0xd0, 0xc1, 0xe8, 0x32, 0x21, 0xe8
	.byte 0xec, 0x02, 0xe8, 0xc8, 0x32, 0xb9, 0xf5, 0x00
	.byte 0x90, 0x26, 0xc3, 0x07, 0xe4, 0xf8, 0x21, 0xc3
	.byte 0x07, 0xe4, 0xf8, 0x3c, 0x7f, 0x2e, 0xde, 0x62
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x20, 0xc9, 0xcc, 0xf0
	.byte 0xc9, 0xce, 0x08, 0x1e, 0x8f, 0x02, 0xc8, 0x89
	.byte 0x1e, 0x8a, 0x02, 0x21, 0x00, 0x1e, 0x85, 0x02
	.byte 0x4e, 0x48, 0xc1, 0xe8, 0x32, 0x61, 0xc1, 0xe8
	.byte 0x32, 0x3f, 0x08, 0x67, 0x05, 0xf1, 0xe8, 0x32
	.byte 0x00, 0x00
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
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb a, 0x0
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte2
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccKbdTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccKbdTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	stb_dri A, 0x07, 0xe4, 0xf8
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
	.byte 0xf3, 0x07, 0xe4, 0xf8, 0x50, 0xd1, 0xd6, 0x32
	.byte 0xf0, 0x6f, 0x04, 0xf1, 0xd6, 0x32, 0x50
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
	calr	424
	cp	w, 223
	jr	nz, 20
	ldb	a, 0
	ld	(12947:16), a
	ld	(12948:16), a
	ld	(12949:16), a
	ld	(12950:16), a
	jr	64
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
	.byte 0xc1, 0xdd, 0x39, 0x3f, 0xc0, 0x6e, 0x05, 0xf1
	.byte 0xdc, 0x39, 0x00, 0x00
AccKbdTiming_Overflow_SubBase:
	.byte 0xc1, 0x5d, 0x04, 0xa1, 0xc1, 0xdb, 0x32, 0xf1
	.byte 0x6f, 0x04, 0xf1, 0xdb, 0x32, 0x41
AccKbdTiming_Overflow_CalcSkip:
	.byte 0xd1, 0xdc, 0x32, 0x24, 0xf3, 0x07, 0xec, 0xf0
	.byte 0x41, 0xdc, 0x61, 0x9b, 0x02, 0xf4, 0x63, 0x03
	.byte 0x9b, 0x00, 0x24
AccKbdTiming_Overflow_AdvancePos:
	xor wa, wa

	ld a, (13028:16)

	add ix, wa

	cp ix, (xhl + 2)

	jrl ule, -606

	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 256)

	.byte 0x78, 0x97, 0xfd	; jrl AccKbdTiming_EventLoop (v7 displacement)



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
	jr	z, 92	; -> 0xF5B4F4
	ld_rrb	a, xhl, ix
	ld	w, a
	and	w, 240
	cp	w, 192
	jr	nz, 72	; -> 0xF5B4EF
	ld	a, w
	orda8	xbc, (14816)
	calr	218
	calr	73
	calr	70
	ld_rrb	a, xhl, ix
	calr	204
	calr	59
	ld_rrb	a, xhl, ix
	calr	193
	calr	48
	ld_rrb	a, xhl, ix
	calr	182
	calr	37
	ld_rrb	a, xhl, ix
	calr	171
	calr	26
	ld_rrb	a, xhl, ix
	calr	160
	calr	15
	jr	-91	; -> 0xF5B494
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
	.byte 0xd1, 0xe2, 0x32, 0xf6, 0xf2, 0x89, 0xb5, 0xf5
	.byte 0xdf, 0xf3, 0x07, 0xe4, 0xf8, 0xcf, 0x66, 0x69
	.byte 0xde, 0x8c, 0xc3, 0x07, 0xe4, 0xf0, 0x21, 0xf1
	.byte 0xe5, 0x32, 0x41, 0xdc, 0x62, 0xc3, 0x07, 0xe4
	.byte 0xf0, 0x21, 0xf1, 0xe6, 0x32, 0x41, 0xdc, 0x61
	.byte 0xc3, 0x07, 0xe4, 0xf0, 0x21, 0xf1, 0xe7, 0x32
	.byte 0x41, 0xdc, 0x61, 0xd3, 0x07, 0xe4, 0xf0, 0x20
	.byte 0xd1, 0x5e, 0x04, 0xf0, 0x6a, 0x20, 0x21, 0xf0
	.byte 0xc1, 0xe5, 0x32, 0xc1, 0xc9, 0xce, 0x08, 0x1e
	.byte 0x37, 0x00, 0xc1, 0xe6, 0x32, 0x21, 0x1e, 0x30
	.byte 0x00, 0x21, 0x00, 0x1e, 0x2b, 0x00, 0xc3, 0x07
	.byte 0xe4, 0xf8, 0x3c, 0x7f, 0x68, 0x1b
AccKbdTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccKbdTiming_TableScan_StoreTiming
	add a, 0x60

AccKbdTiming_TableScan_StoreTiming:
	.byte 0xf3, 0x07, 0xe4, 0xf0, 0x50, 0xd1, 0xd8, 0x32
	.byte 0xf0, 0x6f, 0x04, 0xf1, 0xd8, 0x32, 0x50
AccKbdTiming_TableScan_NextSlot:
	.byte 0xd1, 0xe0, 0x32, 0x86	; addda16 xiz, 0x337c (v7 patched)

	.byte 0x78, 0x80, 0xff	; jrl AccKbdTiming_TableScan_Loop (v7 displacement)



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
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_ClassifyEvent
	ld ix, (xhl + 256)

AccAccTiming_ClassifyEvent:
	ld	w, a
	cp	a, 144
	jr	nz, 7
	ld	(13028:16), 5
	jr	50
AccAccTiming_Check0x91:
	cp	a, 145
	jr	nz, 7
	ld	(13028:16), 7
	jr	38
AccAccTiming_Check0x92:
	cp	a, 146
	jr	nz, 7
	ld	(13028:16), 6
	jr	26
AccAccTiming_CheckProgramChg:
	and	a, 240
	cp	a, 192
	jr	nz, 7
	ld	(13028:16), 5
	jr	11
AccAccTiming_CheckControl:
	cp	a, 208
	jrl	nz, 269
	ld	(13028:16), 2
AccAccTiming_StoreEventData:
	.byte 0xf1, 0xdf, 0x39, 0x41, 0xc3, 0x07, 0xec, 0xf0
	.byte 0x21, 0xf1, 0xde, 0x32, 0x54, 0xdc, 0x61, 0x9b
	.byte 0x02, 0xf4, 0x63, 0x03, 0x9b, 0x00, 0x24
AccAccTiming_CheckTimestamp:
	.byte 0xc1, 0x5d, 0x04, 0xf1, 0x7b, 0x4e, 0x02, 0xc8
	.byte 0x89, 0xc9, 0xcc, 0xf0, 0xc9, 0xcf, 0x90, 0x7e
	.byte 0xc4, 0x01, 0xc1, 0xde, 0x39, 0x3f, 0x00, 0x6e
	.byte 0x12, 0x28, 0xc1, 0xf0, 0x32, 0x21, 0xf1, 0xe0
	.byte 0x39, 0x41, 0x48, 0x1e, 0x50, 0xfe, 0xf1, 0xde
	.byte 0x39, 0x00, 0xff
AccAccTiming_NoteSlotScan:
	pushw wa
	ldb_sri W, 0x07, 0xec, 0xf0
	xor iz, iz

AccAccTiming_NoteSlot_Loop:
	.byte 0xd1, 0xe2, 0x32, 0xf6, 0x6f, 0x55, 0xf3, 0x07
	.byte 0xe4, 0xf8, 0xcf, 0x66, 0x11, 0xd7, 0xfa, 0x9e
	.byte 0xde, 0xc8, 0x02, 0x00, 0xc3, 0x07, 0xe4, 0xf8
	.byte 0xf8, 0xd7, 0xfa, 0x8e, 0x66, 0x06
AccAccTiming_NoteSlot_NextSlot:
	.byte 0xd1, 0xe0, 0x32, 0x86, 0x68, 0xdc
AccAccTiming_NoteSlot_SendNoteOff:
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x21, 0xc3, 0x07, 0xe4
	.byte 0xf8, 0x3c, 0x7f, 0xc9, 0xcc, 0xf0, 0xc1, 0xf0
	.byte 0x32, 0xe1, 0x1e, 0x0c, 0xff, 0xc8, 0x89, 0x1e
	.byte 0x07, 0xff, 0x21, 0x00, 0x1e, 0x02, 0xff, 0xf1
	.byte 0xf1, 0x32, 0xc8, 0x6e, 0x12, 0xc1, 0xf1, 0x32
	.byte 0x3e, 0x01, 0x21, 0x90, 0x1e, 0xf2, 0xfe, 0x21
	.byte 0x00, 0x1e, 0xed, 0xfe, 0x1e, 0xea, 0xfe
AccAccTiming_NoteSlot_FindFree:
	popw wa
	xor iz, iz

AccAccTiming_NoteSlot_FreeLoop:
	.byte 0xd1, 0xe2, 0x32, 0xf6, 0x6f, 0x0d, 0xf3, 0x07
	.byte 0xe4, 0xf8, 0xcf, 0x66, 0x5c, 0xd1, 0xe0, 0x32
	.byte 0x86, 0x68, 0xed
AccAccTiming_SlotOverflow:
	.byte 0x28, 0xe8, 0xd0, 0xc1, 0xe8, 0x32, 0x21, 0xe8
	.byte 0xec, 0x02, 0xe8, 0xc8, 0x52, 0xb9, 0xf5, 0x00
	.byte 0x90, 0x26, 0xc3, 0x07, 0xe4, 0xf8, 0x21, 0xc3
	.byte 0x07, 0xe4, 0xf8, 0x3c, 0x7f, 0x2e, 0xde, 0x62
	.byte 0xc3, 0x07, 0xe4, 0xf8, 0x20, 0xc9, 0xcc, 0xf0
	.byte 0xc1, 0xf0, 0x32, 0xe1, 0x1e, 0xa5, 0xfe, 0xc8
	.byte 0x89, 0x1e, 0xa0, 0xfe, 0x21, 0x00, 0x1e, 0x9b
	.byte 0xfe, 0x4e, 0x48, 0xc1, 0xe8, 0x32, 0x61, 0xc1
	.byte 0xe8, 0x32, 0x3f, 0x08, 0x67, 0x05, 0xf1, 0xe8
	.byte 0x32, 0x00, 0x00
AccAccTiming_SlotOverflow_Done:
	jr AccAccTiming_WriteNoteEvent

AccAccTiming_SkipEvent:
	ld ix, (xhl + 4)
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNoteEvent:
	.byte 0xc1, 0xf0, 0x32, 0xe1, 0x1e, 0x77, 0xfe, 0xc8
	.byte 0x89, 0xf3, 0x07, 0xe4, 0xf8, 0x41, 0xde, 0x61
	.byte 0x21, 0x00, 0xf3, 0x07, 0xe4, 0xf8, 0x41, 0xde
	.byte 0x61, 0xc3, 0x07, 0xec, 0xf0, 0x21, 0xdc, 0x61
	.byte 0x9b, 0x02, 0xf4, 0x63, 0x03, 0x9b, 0x00, 0x24
AccAccTiming_WriteNote_Byte2:
	calr AccSeq_WriteByte
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_Byte3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_Byte3:
	calr AccSeq_WriteByte
	stb_dri A, 0x07, 0xe4, 0xf8
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
	st_rrw	wa, xbc, iz
	inc	2, iz
	cp	wa, (13014:16)
	jr	nc, 4	; -> 0xF5B795
	ld	(13014:16), wa
AccAccTiming_WriteNote_ExtraBytes:
	popw wa
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra1
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra1:
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x90
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra2
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra2:
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz
	cp w, 0x92
	jr z, AccAccTiming_WriteNote_Done
	ldb_sri A, 0x07, 0xec, 0xf0
	inc 1, ix
	cp ix, (xhl + 2)
	jr ule, AccAccTiming_WriteNote_StoreExtra3
	ld ix, (xhl + 256)

AccAccTiming_WriteNote_StoreExtra3:
	stb_dri A, 0x07, 0xe4, 0xf8
	inc 1, iz

AccAccTiming_WriteNote_Done:
	ld (xhl + 6), ix
	jrl AccAccTiming_EventLoop

AccAccTiming_WriteNonNote:
	.byte 0xc9, 0x88, 0xc1, 0xf0, 0x32, 0xe1, 0x1e, 0x99
	.byte 0xfd, 0xc3, 0x07, 0xec, 0xf0, 0x21, 0xdc, 0x61
	.byte 0x9b, 0x02, 0xf4, 0x63, 0x03, 0x9b, 0x00, 0x24
AccAccTiming_WriteNonNote_Byte2:
	.byte 0x1e, 0x87, 0xfd, 0xf1, 0x98, 0x32, 0x41, 0xc3
	.byte 0x07, 0xec, 0xf0, 0x21, 0xdc, 0x61, 0x9b, 0x02
	.byte 0xf4, 0x63, 0x03, 0x9b, 0x00, 0x24
AccAccTiming_WriteNonNote_Byte3:
	.byte 0x1e, 0x71, 0xfd, 0xc8, 0xcf, 0xd0, 0x6e, 0x0d
	.byte 0xc1, 0x98, 0x32, 0x3f, 0x03, 0x6e, 0x3c, 0xf1
	.byte 0x97, 0x32, 0x41, 0x68, 0x36
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
	.byte 0xc1, 0xdf, 0x39, 0x3f, 0xc0, 0x6e, 0x05, 0xf1
	.byte 0xde, 0x39, 0x00, 0x00
AccAccTiming_Overflow_SubBase:
	.byte 0xc1, 0x5d, 0x04, 0xa1, 0xc1, 0xdb, 0x32, 0xf1
	.byte 0x6f, 0x04, 0xf1, 0xdb, 0x32, 0x41
AccAccTiming_Overflow_CalcSkip:
	.byte 0xd1, 0xde, 0x32, 0x24, 0xf3, 0x07, 0xec, 0xf0
	.byte 0x41, 0xdc, 0x61, 0x9b, 0x02, 0xf4, 0x63, 0x03
	.byte 0x9b, 0x00, 0x24
AccAccTiming_Overflow_AdvancePos:
	xor wa, wa

	ld a, (13028:16)

	add ix, wa

	cp ix, (xhl + 2)

	.byte 0x73, 0x04, 0xfd	; jrl ule, AccAccTiming_EventLoop (v7 displacement)

	sub ix, (xhl + 2)

	dec 1, ix

	add ix, (xhl + 256)

	.byte 0x78, 0xf9, 0xfc	; jrl AccAccTiming_EventLoop (v7 displacement)



AccAccTiming_ScanDone:
	ret

AccAccTiming_TableScan:
	xor iz, iz

AccAccTiming_TableScan_Loop:
	.byte 0xd1, 0xe2, 0x32, 0xf6, 0xf2, 0x31, 0xb9, 0xf5
	.byte 0xdf, 0xf3, 0x07, 0xe4, 0xf8, 0xcf, 0x66, 0x6a
	.byte 0xde, 0x8c, 0xc3, 0x07, 0xe4, 0xf0, 0x21, 0xf1
	.byte 0xe5, 0x32, 0x41, 0xdc, 0x62, 0xc3, 0x07, 0xe4
	.byte 0xf0, 0x21, 0xf1, 0xe6, 0x32, 0x41, 0xdc, 0x61
	.byte 0xc3, 0x07, 0xe4, 0xf0, 0x21, 0xf1, 0xe7, 0x32
	.byte 0x41, 0xdc, 0x61, 0xd3, 0x07, 0xe4, 0xf0, 0x20
	.byte 0xd1, 0x5e, 0x04, 0xf0, 0x6a, 0x21, 0x21, 0xf0
	.byte 0xc1, 0xe5, 0x32, 0xc1, 0xc1, 0xf0, 0x32, 0xe1
	.byte 0x1e, 0x8f, 0xfc, 0xc1, 0xe6, 0x32, 0x21, 0x1e
	.byte 0x88, 0xfc, 0x21, 0x00, 0x1e, 0x83, 0xfc, 0xc3
	.byte 0x07, 0xe4, 0xf8, 0x3c, 0x7f, 0x68, 0x1b
AccAccTiming_TableScan_Decrement:
	subda16 xwa, 1118
	bit 7, a
	jr z, AccAccTiming_TableScan_StoreTiming
	add a, 0x60

AccAccTiming_TableScan_StoreTiming:
	.byte 0xf3, 0x07, 0xe4, 0xf0, 0x50, 0xd1, 0xd8, 0x32
	.byte 0xf0, 0x6f, 0x04, 0xf1, 0xd8, 0x32, 0x50
AccAccTiming_TableScan_NextSlot:
	.byte 0xd1, 0xe0, 0x32, 0x86	; addda16 xiz, 0x337c (v7 patched)

	.byte 0x78, 0x7f, 0xff	; jrl AccAccTiming_TableScan_Loop (v7 displacement)



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
	jr	z, 3
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
	cps a, 0
	jp_24 z, (AccDir_Adjust_Ret)
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
	cps w, 0
	jr z, AccDir_Adjust_LeftHand
	dec 1,A
	cp A,0xff
	jr nz, AccDir_Adjust_RightDec
	ldb A, 0x00
AccDir_Adjust_RightDec:
	sll a, 4
	and (0xfc61:16), 207
	orddm8 0xfc61, a
	calr AccDir_DispatchEvent

AccDir_Adjust_LeftHand:
	.byte 0xf1, 0x03, 0x34, 0xcb, 0x66, 0x38, 0xc1, 0x03
	.byte 0x34, 0x3c, 0xf7, 0xc1, 0x08, 0x34, 0x3f, 0x80
	.byte 0x6f, 0x2c, 0xc1, 0x99, 0xfd, 0x20, 0xc8, 0xcc
	.byte 0x01, 0xc1, 0x61, 0xfc, 0x21, 0xc9, 0xcc, 0x30
	.byte 0xc9, 0xef, 0x04, 0xc8, 0xd8, 0x66, 0x17, 0xc9
	.byte 0x61, 0xc9, 0xdc, 0x67, 0x02, 0x21, 0x03
AccDir_Adjust_LeftInc:
	sll a, 4
	and (0xfc61:16), 207
	orddm8 0xfc61, a
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
	cps w, 0
	jr z, AccDir_DispatchEvent_Ret
	cp (0x3408:16), 0x80
	jr nc, AccDir_DispatchEvent_Ret
	ldb E, 0x48
	ldb D, 0x07
	ld a, (0xfc61:16)
	ldb W, 0x30
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
	.byte 0xf2	; v10 does not spell this byte either
	.byte 0xdd	; v10 does not spell this byte either
	.byte 0xbb	; v10 does not spell this byte either
	.byte 0xf5	; v10 does not spell this byte either
	and	bc, iz
	.byte 0xe2, 0xbf, 0x21	; differs from v10 here and llvm-objdump cannot read it
	andda8	xbc, (49123)
	and	a, 1
	cps	a, 1
	.byte 0xf2	; v10 does not spell this byte either
	.byte 0xdd	; v10 does not spell this byte either
	.byte 0xbb	; v10 does not spell this byte either
	.byte 0xf5	; v10 does not spell this byte either
	cp	bc, iz
	.byte 0xf4	; v10 does not spell this byte either
	ldw	hl, 28360
	retd	2513
	max
	ldb	w, 241
	.byte 0xf2	; v10 does not spell this byte either
	ldw	hl, 49488
	.byte 0xf4	; v10 does not spell this byte either
	ldw	hl, 318
	jr	96
	ld	wa, (1033:16)
	ld	bc, (13298:16)
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
	ld	hl, (13304:16)
	ld	(13306:16), hl
	ld	hl, (13302:16)
	ld	(13304:16), hl
	ld	(13302:16), wa
	ld	wa, (1033:16)
	ld	(13298:16), wa
	ret
	ld	de, (13302:16)
	ld	bc, (13304:16)
	cps	de, 0
	jr	nz, 4
	jp	16104457
	cps	bc, 0
	jr	nz, 9
	add	wa, de
	srl	wa, 1
	jp	16104457
	add	wa, de
	add	wa, bc
	and	xwa, 65535
	div	wa, 3
	ldb	e, 72
	ldb	d, 8
	call	16624705
	ret
AccProcess_TimerCompare:
	.byte 0xf1, 0xf4, 0x33, 0xc8, 0x66, 0x56, 0xd1, 0x09
	.byte 0x04, 0x20, 0xd1, 0xf2, 0x33, 0x21, 0xd9, 0xf0
	.byte 0x67, 0x1d, 0xd9, 0xa0, 0xd8, 0xcf, 0x00, 0x04
	.byte 0x67, 0x13, 0xc1, 0xf4, 0x33, 0x3c, 0xfe, 0xd8
	.byte 0xd0, 0xf1, 0xf6, 0x33, 0x50, 0xf1, 0xf8, 0x33
	.byte 0x50, 0xf1, 0xfa, 0x33, 0x50
AccProcess_Timer_Skip:
	jr AccProcess_Timer_Ret

AccProcess_Timer_WrapCase:
	.byte 0xe8, 0xcc, 0xff, 0xff, 0x00, 0x00, 0xe9, 0xcc
	.byte 0xff, 0xff, 0x00, 0x00, 0xe8, 0xc8, 0x00, 0x00
	.byte 0x01, 0x00, 0xe9, 0xa0, 0xd8, 0xcf, 0x00, 0x04
	.byte 0x67, 0x13, 0xc1, 0xf4, 0x33, 0x3c, 0xfe, 0xd8
	.byte 0xd0, 0xf1, 0xf6, 0x33, 0x50, 0xf1, 0xf8, 0x33
	.byte 0x50, 0xf1, 0xfa, 0x33, 0x50
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

	.byte 0xe8, 0xc8, 0x47, 0x71, 0xe4, 0x00	; add xwa, Display_FontPalette_Table_0x22EF (v7 patched)

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
	ld XIX,AccVoice_ROMLookup_OffsetTable_0x2
	ld XIY,0x00094800
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x85, 0x44, 0x0f, 0x34
	.byte 0x00, 0x00, 0x31, 0x0d, 0x00, 0x85, 0x11, 0x0e
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
	ld L,H
	xor H,H
	sla HL, 0x02
	ld XIX,AccVoice_IndexedTableLookup_BaseOffsets_0x2
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x25, 0x44, 0xd4, 0xbe
	.byte 0xf5, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x85, 0x44
	.byte 0x0f, 0x34, 0x00, 0x00, 0x31, 0x0d, 0x00, 0x85
	.byte 0x11, 0x0e
AccVoice_IndexedTableLookup_BaseOffsets:
	.byte 0x00, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x00
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

	.byte 0xe8, 0xc8, 0x47, 0x70, 0xe4, 0x00	; add xwa, Display_FontPalette_Table_0x21EF (v7 patched)

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
	max
	pop	sr
	nop
	max
	max
	nop
	halt
	push	sr
	nop
	ei	4
	nop
	ei	6
	normal
	pushw	3
	pushw	4
	decf
	push	sr
	nop
	decf
	reti
	normal
	ret
	normal
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
	max
	push	sr
	nop
	max
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
	ld	a, (13042:16)
	and	a, 31
	jr	z, 38
	ld	a, (13043:16)
	and	a, 31
	jr	nz, 3
	calr	1153
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
	.byte 0xc1, 0xe3, 0xbf, 0xc1, 0xc9, 0x33, 0x00, 0x66
	.byte 0x15, 0xc1, 0xf5, 0x32, 0x3d, 0x01, 0xf1, 0xf5
	.byte 0x32, 0xc8, 0x6e, 0x06, 0x1d, 0x71, 0x96, 0xf5
	.byte 0x68, 0x04
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
	ld XWA,AccStyle_InlinedBlock_0x1E0
	ldb_dri a, 0x07, 0xe0, 0xec
	cp	(35998:16), a
	jr	z, 14
	ld	(35998:16), a
	ldb	e, 144
	ldb	d, 16
	ldb	w, 255
	call	16624672
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
	call 0xfdd69e
	or (0x3335:16), 0x01
AccStyle_ModeEnter_SetFlags:
.Lc_f5c281:
	or (0x3431:16), 0x08
	or (0x3337:16), 0x01

	ldb a, 0x4b

	call	16544114



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
	.byte 0x3e, 0x1e, 0x02, 0x00, 0x5e, 0x0e, 0xc1, 0x9b
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
	.byte 0x00, 0x00, 0x01, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x14, 0x13, 0x00, 0x10, 0x00, 0x00, 0x00
	.byte 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
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

	orddm8 0xfb57, w

	ld a, (12677:16)

	sla a, 6

	and a, 0x40

	and (0xfb5a:16), 191

	orddm8 0xfb5a, a

	ldb l, 0x4

	.byte 0x1e, 0xd7, 0x01	; calr AccVoiceState_DispatchChange (v7 displacement)



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

	orddm8 0xfb71, w

	ld a, (12682:16)

	sla a, 6

	and a, 0x40

	and (0xfb74:16), 191

	orddm8 0xfb74, a

	ldb l, 0x8

	.byte 0x1e, 0x8b, 0x01	; calr AccVoiceState_DispatchChange (v7 displacement)



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

	orddm8 0xfb8b, w

	ld a, (12687:16)

	sla a, 6

	and a, 0x40

	and (0xfb8e:16), 191

	orddm8 0xfb8e, a

	ldb l, 0x10

	.byte 0x1e, 0x3f, 0x01	; calr AccVoiceState_DispatchChange (v7 displacement)



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

	orddm8 0xfba5, w

	ld a, (12672:16)

	sla a, 6

	and a, 0x40

	and (0xfba8:16), 191

	orddm8 0xfba8, a

	ldb l, 0x2

	calr	243



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
	orddm8 0xfbbf, w
	ldb L, 0x01
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
	.byte 0xbd, 0x00, 0x41, 0x8d, 0x01, 0x3c, 0x80, 0x8d
	.byte 0x01, 0xe8, 0xc1, 0xa4, 0xfb, 0x21, 0xc1, 0xa5
	.byte 0xfb, 0x20, 0xc8, 0xcc, 0x7f, 0xc1, 0xa8, 0xfb
	.byte 0x27, 0xcf, 0xcc, 0x40, 0xcf, 0xec, 0x01, 0xcf
	.byte 0xe0, 0xf1, 0xfb, 0x32, 0x50, 0xbd, 0x02, 0x41
	.byte 0x8d, 0x03, 0x3c, 0x00, 0x8d, 0x03, 0xe8, 0xc1
	.byte 0x56, 0xfb, 0x21, 0xc1, 0x57, 0xfb, 0x20, 0xc8
	.byte 0xcc, 0x7f, 0xc1, 0x5a, 0xfb, 0x27, 0xcf, 0xcc
	.byte 0x40, 0xcf, 0xec, 0x01, 0xcf, 0xe0, 0xf1, 0xfd
	.byte 0x32, 0x50, 0xbd, 0x04, 0x41, 0x8d, 0x05, 0x3c
	.byte 0x00, 0x8d, 0x05, 0xe8, 0xc1, 0x70, 0xfb, 0x21
	.byte 0xc1, 0x71, 0xfb, 0x20, 0xc8, 0xcc, 0x7f, 0xc1
	.byte 0x74, 0xfb, 0x27, 0xcf, 0xcc, 0x40, 0xcf, 0xec
	.byte 0x01, 0xcf, 0xe0, 0xf1, 0xff, 0x32, 0x50, 0xbd
	.byte 0x06, 0x41, 0x8d, 0x07, 0x3c, 0x00, 0x8d, 0x07
	.byte 0xe8, 0xc1, 0x8a, 0xfb, 0x21, 0xc1, 0x8b, 0xfb
	.byte 0x20, 0xc8, 0xcc, 0x7f, 0xc1, 0x8e, 0xfb, 0x27
	.byte 0xcf, 0xcc, 0x40, 0xcf, 0xec, 0x01, 0xcf, 0xe0
	.byte 0xf1, 0x01, 0x33, 0x50, 0xbd, 0x08, 0x41, 0x8d
	.byte 0x09, 0x3c, 0x00, 0x8d, 0x09, 0xe8, 0xc1, 0xf7
	.byte 0x32, 0x3e, 0x01, 0x0e
AccVoiceState_DispatchChange:
	push XIY
	ld XWA,AccStyle_InlinedBlock_0x1E0
	ldb_dri e, 0x03, 0xe0, 0xec
	extz HL
	sla hl, 2
	ld XWA,AccVoiceState_PartLookupTable_0x80
	ldl_dri xwa, 0x07, 0xe0, 0xec
	ld XIY,AccVoiceState_PartLookupTable
	ldl_dri xiy, 0x07, 0xf4, 0xec
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
	.byte 0xd1, 0xf9, 0x32, 0xf8, 0x66, 0x15, 0xc9, 0xcc
	.byte 0x0f, 0xbd, 0x00, 0x41, 0x8d, 0x01, 0x3c, 0x80
	.byte 0x8d, 0x01, 0xe8, 0xc9, 0xce, 0xf0, 0xc1, 0xf7
	.byte 0x32, 0x3e, 0x01
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
	.byte 0xd1, 0xfb, 0x32, 0xf8, 0x66, 0x0f, 0xbd, 0x02
	.byte 0x41, 0x8d, 0x03, 0x3c, 0x00, 0x8d, 0x03, 0xe8
	.byte 0xc1, 0xf7, 0x32, 0x3e, 0x01
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
	.byte 0xd1, 0xfd, 0x32, 0xf8, 0x66, 0x0f, 0xbd, 0x04
	.byte 0x41, 0x8d, 0x05, 0x3c, 0x00, 0x8d, 0x05, 0xe8
	.byte 0xc1, 0xf7, 0x32, 0x3e, 0x01
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
	.byte 0xd1, 0xff, 0x32, 0xf8, 0x66, 0x0f, 0xbd, 0x06
	.byte 0x41, 0x8d, 0x07, 0x3c, 0x00, 0x8d, 0x07, 0xe8
	.byte 0xc1, 0xf7, 0x32, 0x3e, 0x01
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
	.byte 0xd1, 0x01, 0x33, 0xf8, 0x66, 0x0f, 0xbd, 0x08
	.byte 0x41, 0x8d, 0x09, 0x3c, 0x00, 0x8d, 0x09, 0xe8
	.byte 0xc1, 0xf7, 0x32, 0x3e, 0x01
AccVoiceDelta_Part5_Store:
	ld	(13057:16), wa
	ret
AccStyle_InitVRAM:
	xor a, a
	ld xiy, Display_FontPalette_Table_0x3127
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
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c98c
	ld (0xe318:16), 0x10
.Lc_f5c98c:
	ld (0x32f2:16), 0x10
	ret
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c9a5
	ld (0xe318:16), 0x10
.Lc_f5c9a5:
	ld (0x32f2:16), 0x08
	ret
	ld (0xe31a:16), 0x10
	ld a, (0x32f2:16)
	and A,0x1f
	jr nz, .Lc_f5c9be
	ld (0xe318:16), 0x10
.Lc_f5c9be:
	ld (0x32f2:16), 0x04
	ret
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
	call	16554468
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
	lda xbc, (Display_FontPalette_Table_0x515C:24)
	ld_sril3 XDE, 0x07, 0xe4, 0xe0
	ld a, (xde)
	extz wa
	sla wa, 2
	lda xbc, (RhythmTiming_OffsetTable:24)
	ld xde, 0x94860
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda xbc, (Display_FontPalette_Table_0x1D32:24)
	ldb_sri L, 0x07, 0xe4, 0xe0
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
	lda xbc, (Display_FontPalette_Table_0x515C:24)
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
	ld de, (4360:16)
	ld ix, de
	and ix, 0x4
	lda xhl, (Display_FontPalette_Table_0x1EBF:24)
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
	lda xde, (Display_FontPalette_Table_0x513C:24)
	ld_sril3 XIY, 0x07, 0xe8, 0xe4
	ld e, a
	extz de
	ld wa, de
	sla wa, 2
	lda xix, (RhythmTiming_OffsetTable:24)
	ld xiz, xiy
	add_sril_rm XIZ, 0x07, 0xf0, 0xe0
	ld a, (xiz + 12)
	extz wa
	lda xhl, (Display_FontPalette_Table_0x1D32:24)
	ldb_sri A, 0x07, 0xec, 0xe0
	ldb_erp A, 0xe2
	lda xiz, (Display_FontPalette_Table_0x511C:24)
	ld_sril3 XBC, 0x07, 0xf8, 0xe4
	add de, 0x11
	ldb_sri C, 0x07, 0xe4, 0xe8
	ld wa, (4360:16)
	ld de, wa
	and de, 0x4
	extz bc
	cps de, 4
	jr nz, AccTone_CheckBit10Flag
	lda xde, (Display_FontPalette_Table_0x51E4:24)
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
	lda xde, (Display_FontPalette_Table_0x51E8:24)
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
	lda xbc, (Display_FontPalette_Table_0x1D58:24)
	bit_dri 0, 0x07, 0xe4, 0xe0
	jr nz, AccTone_SetupExit
	ldb l, 0x1
	jr AccTone_ExtendAndDispatch_PopRet
	dec 4, xsp
	ld de, (4360:16)
	and de, 0x40c
	jrl z, AccTone_LookupFailed
	extz bc
	sla bc, 2
	lda xde, (Display_FontPalette_Table_0x513C:24)
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	extz wa
	sla wa, 2
	lda xbc, (RhythmTiming_OffsetTable:24)
	add_sril_rm XDE, 0x07, 0xe4, 0xe0
	ld a, (xde + 12)
	extz wa
	lda xbc, (Display_FontPalette_Table_0x1D32:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (Display_FontPalette_Table_0x1D58:24)
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
	ld	a, (12899:16)
	cps	a, 1
	jr	z, 4
	cps	a, 2
	jr	z, 4
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
	.incbin "includes/romslices/v7_transplant_AccTone_InlineBytecodeData_head_head.bin"
	extz DE
	sla de, 2
	extz BC
	sla bc, 5
	ld HL,BC
	add HL,DE
	ldb W, 0x00
	extz XWA
	ld XBC,XWA
	sll xbc, 2
	add XBC,XWA
	sll xbc, 5
	add XBC,0x00095440
	ldw_dri hl, 0x07, 0xe4, 0xec
	ret
	extz DE
	sla de, 2
	extz BC
	sla bc, 5
	ld HL,BC
	add HL,DE
	ldb W, 0x00
	extz XWA
	ld XBC,XWA
	sll xbc, 2
	add XBC,XWA
	sll xbc, 5
	add XBC,0x00095440
	lda_dri xwa, 0x07, 0xe4, 0xec
	ld HL,(XWA+0x02)
	ret
	.incbin "includes/romslices/v7_transplant_AccTone_InlineBytecodeData_head_mid1.bin"
	res 1, (0x3263:16)
	res 3, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	res 0, (0x3263:16)
	res 2, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	res 2, (0x3263:16)
	res 2, (0xfc60:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 6
	lds de, 0
	call 0xfdaa53
	ret
	res 0, (0x3261:16)
	res 4, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	res 1, (0x3261:16)
	res 5, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	res 0, (0x325f:16)
	res 6, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	res 1, (0x325f:16)
	res 7, (0xfc5f:16)
	pushw 0x0000
	ldw WA, 0x0048
	lds bc, 5
	lds de, 0
	call 0xfdaa53
	ret
	.incbin "includes/romslices/v7_transplant_AccTone_InlineBytecodeData_head_tail.bin"
	ld xix, (0x338a:16)
	ld C,A
	extz BC
	lda xde, (0xe4a01a:24)
	ldb_dri e, 0x07, 0xe8, 0xe4
	extz DE
	ld BC,DE
	muls BC,0x0007
	lda xhl, (0x31aa:16)
	.incbin "includes/romslices/v7_transplant_AccTone_InlineBytecodeData_tail.bin"
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
	.byte 0xe1, 0x8a, 0x33, 0x21, 0x89, 0x0d, 0xf1, 0xb0
	.byte 0xf3, 0xf1, 0x4e, 0x33, 0x00, 0x00, 0x0e
AccVoice_BarCounterBytecodeData:
	.incbin "includes/romslices/v7_transplant_AccVoice_BarCounterBytecodeData.bin"
AccTuning_ReadAndApplyOffset:
	ld a, (0x3387:16)
	extz WA
	lda xbc, (Display_FontPalette_Table_0x5170:24)
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x19, 0x86, 0x33, 0x0e
AccTuning_ComplexBytecodeData:
	.incbin "includes/romslices/v7_transplant_AccTuning_ComplexBytecodeData.bin"
AccTone_WriteProgramChange:
	push	xiz
	ld	xix, xwa
	ld	l, (xbc)
	ld	h, (xbc+1)
	ld	(36955:16), 72
	push	xix
	call	16554468
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
	call	16071062
	ld	xhl, xiy
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16080751
	pop	xiz
	ret
	push	xiz
	ld	w, a
	call	16073348
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16071249
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16071175
	pop	xiz
	ret
	push	xiz
	and	xwa, 255
	call	16081590
	and	xhl, 65535
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16080578
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	call	16091457
	pop	xiz
	ret
	push	xiz
	call	16069612
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16080388
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16091351
	pop	xiz
	ret
	push	xiz
	call	16079500
	pop	xiz
	ret
	push	xiz
	call	16072659
	pop	xiz
	ret
	push	xiz
	call	16072524
	pop	xiz
	ret
	push	xiz
	call	16091903
	pop	xiz
	ret
	push	xiz
	call	16072706
	pop	xiz
	ret
	push	xiz
	call	16091962
	pop	xiz
	ret
	push	xiz
	call	16089040
	pop	xiz
	ret
	push	xiz
	call	16089518
	pop	xiz
	ret
	push	xiz
	call	16083419
	and	xhl, 65535
	pop	xiz
	ret
	push	xiz
	ld	xiy, xwa
	ld	xhl, xbc
	and	xhl, 65535
	call	16083148
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
	call	16112183
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
	call	16112229
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
	calr	458
	calr	2845
	call	16149241
	ld	(14619:16), 10
	ret
AccDemo_InitDone:
	push xiz
	call AccDemo_Init_Wrap
	calr AccPatch_CountAvailableSlots
	pop xiz
	ret

AccPatch_InitByteData:
	.byte 0x3e, 0x1d, 0x09, 0xae, 0xf6, 0x5e, 0x0e, 0x1d
	.byte 0xa1, 0xaf, 0xf6, 0x0e, 0x1d, 0x1c, 0xca, 0xf5
	.byte 0x0e, 0x3e, 0x1e, 0xe5, 0x11, 0x1e, 0xf1, 0x0a
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80, 0x5e, 0x0e
AccDemo_InitWithFlag:
	push xiz

	.byte 0xc1, 0x35, 0x34, 0x3e, 0x80	; ordi8 0x34d1, 128 (v7 patched)

	.byte 0x1d, 0x1c, 0xca, 0xf5	; call AccDemo_Init_Wrap (v7 addr)

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
	ld	(13625:16), 0
	ret
Not_sure_maybe_SOFT_VERSION_related:
	.incbin "includes/romslices/v7_transplant_Not_sure_maybe_SOFT_VERSION_related.bin"
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
	.byte 0x3a	; v10 does not spell this byte either
	ldw	ix, 0
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x3a	; v10 does not spell this byte either
	ldw	ix, 3135
	jr	z, 46
	ld	(14079:16), 16
	calr	47
	ld	(14079:16), 8
	calr	39
	ld	(14079:16), 1
	calr	31
	ld	(14079:16), 2
	calr	23
	ld	(14079:16), 4
	calr	15
	inc	1, (13370:16)
	jr	-53
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0x3a	; v10 does not spell this byte either
	ldw	ix, 61700
	.byte 0xff	; v10 does not spell this byte either
	.byte 0x36	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	ret
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0x3a	; v10 does not spell this byte either
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
	ld a, (0x36ff:16)
	calr MapBitFlagsToChannelOffset

	ldw_sri HL, 0x03, 0xf4, 0xe1

	ld (13686:16), hl

	ldw (13688:16), 6

	ret
AccPatch_SlotScanByteData:
	ldb	c, 0
	cp	c, 8
	jr	z, 11
	.byte 0xcb, 0x04
	calr	86
	pop c
	inc	1, c
	jr	-16
	ret
	call	16120340
	cp	a, 129
	jr	z, 19
	cp	a, 131
	jr	z, 22
	push_a
	call	16120361
	.byte 0x15, 0xf1, 0x7a, 0x35, 0xc8
	jr	nz, 2
	jr	-28
	push_a
	call	16120361
	pop_a
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
	.byte 0xcb, 0x04, 0x14
	calr	-71
	pop_a
	pop c
	inc	1, c
	jr	-17
	ret
	.byte 0xcb, 0x04
	lds32	xwa, 0
	ldb	a, 160
	ld	c, (13370:16)
	mul8rr	a, c
	lds32	xbc, 0
	ld	c, (14079:16)
	and	c, 31
	srl	c, 1
	add	xbc, 16115786
	lds32	xde, 0
	ld	e, (xbc)
	mul	de, 32
	add	xwa, xde
	add	xwa, 3136
	add	xwa, 608256
	ld	xix, xwa
	pop c
	sll	c, 2
	ld	wa, (13686:16)
	st_rr8w	wa, xix, c
	ld	wa, (13688:16)
	inc	2, c
	st_rr8w	wa, xix, c
	ret
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
	cps a, 0
	jr nz, .Lc_f5e90d
	ld a, (0x3560:16)
	and A,0x0c
	cps a, 0
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
	jr	z, 33
	ld	(13376:16), a
	cp	(35996:16), 181
	jr	nz, 22
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16160861
	call	16160885
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
	calr	54

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
	ldio 8, 8
	ldio 0, 0
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
	lds32	xhl, 0
	ld	l, (13370:16)
	cp	l, 30
	jr	c, 2
	ldb	l, 0
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
	jr	c, 2
	xor	l, l
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
	jr	c, 2
	xor	l, l
AccPatch_InitFromIndex_Valid:
	mul hl, 0x60

	add xhl, 0x60

	ld xiy, (14610:16)

	add xiy, xhl

	.byte 0x1e, 0x81, 0x0e	; calr AccPatch_FreeAllChains_Alt (v7 displacement)

	.byte 0x1e, 0x29, 0x00	; calr AccPatch_CopyDefaultsToSlot (v7 displacement)

	.byte 0x1e, 0xe6, 0x0e	; calr AccPatch_FillAllSlots_Alt (v7 displacement)

	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80	; ordi8 0x34cd, 128 (v7 patched)

	.byte 0x1e, 0x34, 0x0f	; calr AccPatch_ScanSequenceToEnd (v7 displacement)

	ret



AccPatch_InitByteStub:
	push	xiz
	calr	2
	pop	xiz
	ret

AccPat_InitWorkAreaFromSlot:
	push	xwa
	ld	a, (13370:16)
	ld	(14608:16), a
	ld	xwa, 608256
	ld	(14610:16), xwa
	pop	xwa
	calr	65461
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
	push	xwa
	ldb	a, 0
	ld	w, (14608:16)
	cp	w, 14
	jr	nz, 3
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
	.byte 0x1e, 0xee, 0xfe, 0x1e, 0x0f, 0x00, 0x1e, 0xb1
	.byte 0x00, 0x1e, 0x58, 0x00, 0xc1, 0x31, 0x34, 0x3e
	.byte 0x80, 0x1e, 0xf5, 0x10, 0x0e
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
	.byte 0xd8, 0x8b, 0xbc, 0x03, 0x02, 0xff, 0xff, 0x1e
	.byte 0xc9, 0xfe, 0xbc, 0x01, 0x02, 0xff, 0xff, 0x84
	.byte 0x3c, 0x7f, 0xd1, 0x38, 0x34, 0x61, 0x9c, 0x03
	.byte 0x20, 0xd8, 0xcf, 0xff, 0xff, 0x66, 0x02, 0x68
	.byte 0xdf
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
	normal
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
	ldb A, 0x00
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
	calr 64845

	ld a, (13372:16)

	ld (xiy + 12), a

	push xiy

	calr 107

	pop xiy

	lds32 xhl, 0

	ld l, (13372:16)

	sll l, 1

	xor h, h

	.byte 0xeb, 0xc8, 0x64, 0xec, 0xf5, 0x00	; add xhl, AccPatch_VoiceStrideTable (v7 patched)

	ld wa, (xhl)

	ld (xiy + 16), wa

	.byte 0x1e, 0x2e, 0x00	; calr AccPatch_CheckConfigType (v7 displacement)

	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80	; ordi8 0x34cd, 128 (v7 patched)

	ret



AccPatch_VoiceStrideTable:
	.byte 0x00, 0x00, 0x58, 0x02, 0x08, 0x02, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03
	.byte 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x58, 0x02
	.byte 0x00, 0x00, 0x08, 0x02, 0x00, 0x00, 0x18, 0x03

AccPatch_CheckConfigType:
	.byte 0xc1, 0x3d, 0x34, 0x3f, 0x06, 0x66, 0x17, 0xc1
	.byte 0x3d, 0x34, 0x3f, 0x08, 0x66, 0x10, 0xc1, 0x3d
	.byte 0x34, 0x3f, 0x04, 0x66, 0x09, 0xc1, 0x3d, 0x34
	.byte 0x3f, 0x03, 0x66, 0x02, 0x68, 0x04
RhythmConfig_CheckAndSkip:
	call RhythmConfig_ReturnStub

AccPatch_CheckConfig_Done:
	ret

AccPatch_InitAllSentinels:
	calr	82

	lds32 xwa, 0

	ld a, (13373:16)

	ld b, (13371:16)

	and b, 0x7

	inc 1, b

	mul8rr a, b

	ld c, a

	ld hl, (xiy + 256)

	calr	25

	ld hl, (xiy + 4)

	calr	19

	ld hl, (xiy + 6)

	calr	13

	ld hl, (xiy + 8)

	calr	7

	ld hl, (xiy + 10)

	calr	1

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
	lds32	xhl, 0
	ld	l, (13372:16)
	ld	xbc, 14969738
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
	calr	64576
	ld	a, (13371:16)
	and	a, 7
	ld	(xiy+13), a
	calr	65372
	ret
RhythmProc_CheckConfigBits:
	.byte 0xf1, 0x36, 0x34, 0xc8, 0x66, 0x16, 0xc1, 0x36
	.byte 0x34, 0x3c, 0xfe, 0x1e, 0x24, 0xfc, 0x8d, 0x0e
	.byte 0x3c, 0xf0, 0xc1, 0x4d, 0x34, 0x21, 0xc9, 0xcc
	.byte 0x0f, 0x8d, 0x0e, 0xe9
RhythmProc_ConfigBit1:
	.byte 0xf1, 0x36, 0x34, 0xc9, 0x66, 0x16, 0xc1, 0x36
	.byte 0x34, 0x3c, 0xfd, 0x1e, 0x08, 0xfc, 0x8d, 0x0e
	.byte 0x3c, 0xef, 0xf1, 0x4e, 0x34, 0xcc, 0x66, 0x04
	.byte 0x8d, 0x0e, 0x3e, 0x10
RhythmProc_ConfigBit2:
	.byte 0xf1, 0x36, 0x34, 0xca, 0x66, 0x20, 0xc1, 0x36
	.byte 0x34, 0x3c, 0xfb, 0x1e, 0xec, 0xfb, 0x8d, 0x0e
	.byte 0x3c, 0x9f, 0xf1, 0x4e, 0x34, 0xcd, 0x66, 0x04
	.byte 0x8d, 0x0e, 0x3e, 0x20
RhythmProc_ConfigBit2_SetBit6:
	.byte 0xf1, 0x4e, 0x34, 0xce, 0x66, 0x04, 0x8d, 0x0e
	.byte 0x3e, 0x40
RhythmProc_ConfigBits_Done:
	ret

AccPatch_RebuildChannelSlot:
	ld a, (0x36ff:16)
	and A,0x1f
	cps a, 0
	jr z, AccPatch_RebuildChannel_Done
	calr MapBitFlagsToChannelOffset
	ld (0x3392:16), w
	ld C,W
	push C
	calr AccPatch_GetCurrentSlotAddr
	pop C
	.byte 0xd3, 0x03, 0xf4, 0xe4, 0x23, 0xf1, 0xa1, 0x33
	.byte 0x53, 0x1e, 0x0e, 0xfd, 0xeb, 0xa8, 0xc1, 0x3c
	.byte 0x34, 0x27, 0xeb, 0xc8, 0x8a, 0x6b, 0xe4, 0x00
	.byte 0x83, 0x21, 0xeb, 0xa8, 0xc1, 0x3b, 0x34, 0x27
	.byte 0xcf, 0xcc, 0x07, 0xcf, 0x61, 0xc9, 0x47, 0xdb
	.byte 0xcc, 0x7f, 0x00, 0xcf, 0x8b, 0xd1, 0xa1, 0x33
	.byte 0x23, 0x1e, 0xe2, 0xfe, 0x1e, 0x33, 0x00, 0xf1
	.byte 0x62, 0x35, 0x00, 0x00, 0x1e, 0xc6, 0x00, 0xf1
	.byte 0xe7, 0x31, 0xc8, 0x6e, 0x05, 0xc1, 0x31, 0x34
	.byte 0x3e, 0x80
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
	lds32	xwa, 0
	ld	a, (12823:16)
	ld	c, (13373:16)
	mul8rr	a, c
	addda8	a, (12772)
	ld	l, a
	ld	a, (12771:16)
	add	a, 24
	cp	a, 96
	jr	lt, 22
	inc	1, l
	lds32	xwa, 0
	ld	a, (13373:16)
	ld	c, (13371:16)
	inc	1, c
	mul8rr	a, c
	cp	a, l
	jr	nz, 2
	ldb	l, 0
AccPatch_SeqPosition_Store:
	lds32	xbc, 0
	ld	c, l
	ld	hl, (13217:16)
	lds	wa, 6
	add	wa, bc
	lds32	xhl, 0
	ld	l, (13202:16)
	sll	l, 1
	add	xhl, 16117411
	ld	xhl, (xhl)
	ld	(xhl), wa
	lds32	xhl, 0
	ld	l, (13202:16)
	sll	l, 1
	add	xhl, 16117435
	ld	xhl, (xhl)
	ld	wa, (13217:16)
	ld	(xhl), wa
	ret
AccPatch_SeqBaseAddrTable:
	.byte 0xeb, 0x31, 0x00, 0x00, 0xed, 0x31, 0x00, 0x00
	.byte 0xef, 0x31, 0x00, 0x00, 0xf1, 0x31, 0x00, 0x00
	.byte 0xf3, 0x31, 0x00, 0x00, 0xf5, 0x31, 0x00, 0x00
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
	lds32 xwa, 0
	pop_a
	ldb c, 0x0

AccPatch_WriteRhythmParam_Loop:
	cps	c, 6
	jr	z, 72	; -> 0xF5EF89
	push	c
	push	xwa
	push	c
	pushw	wa
	call	RhythmBuf_WriteByte
	inc	2, xsp
	pop	c
	sll	c, 1
	ld	xwa, 16117642
	ld_rr8b	a, xwa, c
	push	c
	pushw	wa
	call	RhythmBuf_WriteByte
	inc	2, xsp
	pop	c
	inc	1, c
	ld	xwa, 16117642
	ld_rr8b	a, xwa, c
	cps	c, 7
	jr	nz, 4	; -> 0xF5EF7B
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
	ldb a, 0x40
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
	.byte 0x40, 0x64, 0x00, 0x00, 0x00, 0xd1, 0x38, 0x34
	.byte 0x40, 0x33, 0xbe, 0x00, 0xdb, 0x50, 0xc9, 0xcf
	.byte 0x64, 0x67, 0x02, 0x21, 0x63, 0xf1, 0x0f, 0x39
	.byte 0x41, 0x0e
AccPatch_ProcessPartChanges:
	ld	a, (14079:16)
	and	a, 31
	cps	a, 0
	jr	nz, 31
	ld	w, (13428:16)
	and	w, 31
	cps	w, 0
	jr	z, 18
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16352117
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
	lds32	xhl, 0
	ld	l, a
	add	xhl, 16118100
	ld	a, (xhl)
	ld	(35998:16), a
	ld	e, a
	ld	a, (14079:16)
	ld	w, (13428:16)
	and	a, 31
	and	w, 31
	cp	w, a
	jr	z, 12
	ld	a, e
	ldb	e, 144
	ldb	d, 16
	ldb	w, 255
	call	16624672
AccPatch_PartChanges_Update:
	calr AccPatch_SyncAllVoiceParams

AccPatch_PartChanges_CheckFlag:
	ld	a, (13428:16)
	bit	6, a
	jr	z, 16
	ld	w, (14079:16)
	bit	5, w
	jr	z, 7
	call	16118063
	calr	70
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
	push_a
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
	ld	a, (xiy+256)
	.byte 0x8c, 0x00, 0x3c, 0x00
	or	(xix+256), a
	ld	e, a
	sll	b, 1
	ld	(13381:16), e
	ld	(13382:16), d
	.byte 0xc1, 0x46, 0x34, 0xea, 0xcc, 0x04, 0xcd, 0x04
	ld	a, d
	ldb	d, 1
	ldb	w, 127
	ldb	e, 19
	call	16624672
	.byte 0xcd, 0x05, 0xcd, 0x04
	ld	a, e
	ldb	d, 0
	ldb	w, 255
	ldb	e, 19
	call	16624672
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 19
	call	16554468
	ld	xbc, 65366
	st_rr8b	h, xbc, l
	ld	a, (xiy+3)
	sla	a, 6
	ldb	d, 4
	ldb	w, 64
	ldb	e, 19
	call	16624672
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
	ld	a, (xiy+256)
	or	a, 240
	.byte 0x8c, 0x00, 0x3c, 0x00
	or	(xix+256), a
	ld	e, a
	sll	b, 1
	ld	(13379:16), e
	ld	(13380:16), d
	.byte 0xc1, 0x44, 0x34, 0xea, 0xcc, 0x04, 0xcd, 0x04
	ld	a, d
	ldb	d, 1
	ldb	w, 127
	ldb	e, 20
	call	16624672
	.byte 0xcd, 0x05, 0xcd, 0x04
	ld	a, e
	ldb	d, 0
	ldb	w, 255
	ldb	e, 20
	call	16624672
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 20
	call	16554468
	ld	xbc, 65386
	st_rr8b	h, xbc, l
	ld	a, (xiy+3)
	sla	a, 6
	ldb	d, 4
	ldb	w, 64
	ldb	e, 20
	call	16624672
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
	ld	a, (xiy+256)
	.byte 0x8c, 0x00, 0x3c, 0x00
	or	(xix+256), a
	ld	e, a
	sll	b, 1
	ld	(13383:16), e
	ld	(13384:16), d
	.byte 0xc1, 0x48, 0x34, 0xea, 0xcc, 0x04, 0xcd, 0x04
	ld	a, d
	ldb	d, 1
	ldb	w, 127
	ldb	e, 16
	call	16624672
	.byte 0xcd, 0x05, 0xcd, 0x04
	ld	a, e
	ldb	d, 0
	ldb	w, 255
	ldb	e, 16
	call	16624672
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 16
	call	16554468
	ld	xbc, 65306
	st_rr8b	h, xbc, l
	ld	a, (xiy+3)
	sla	a, 6
	ldb	d, 4
	ldb	w, 64
	ldb	e, 16
	call	16624672
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
	ld	a, (xiy+256)
	.byte 0x8c, 0x00, 0x3c, 0x00
	or	(xix+256), a
	ld	e, a
	sll	b, 1
	ld	(13385:16), e
	ld	(13386:16), d
	.byte 0xc1, 0x4a, 0x34, 0xea, 0xcc, 0x04, 0xcd, 0x04
	ld	a, d
	ldb	d, 1
	ldb	w, 127
	ldb	e, 17
	call	16624672
	.byte 0xcd, 0x05, 0xcd, 0x04
	ld	a, e
	ldb	d, 0
	ldb	w, 255
	ldb	e, 17
	call	16624672
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 17
	call	16554468
	ld	xbc, 65326
	st_rr8b	h, xbc, l
	ld	a, (xiy+3)
	sla	a, 6
	ldb	d, 4
	ldb	w, 64
	ldb	e, 17
	call	16624672
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
	ld	a, (xiy+256)
	.byte 0x8c, 0x00, 0x3c, 0x00
	or	(xix+256), a
	ld	e, a
	sll	b, 1
	ld	(13387:16), e
	ld	(13388:16), d
	.byte 0xc1, 0x4c, 0x34, 0xea, 0xcc, 0x04, 0xcd, 0x04
	ld	a, d
	ldb	d, 1
	ldb	w, 127
	ldb	e, 18
	push	xiy
	call	16624672
	pop	xiy
	.byte 0xcd, 0x05, 0xcd, 0x04
	ld	a, e
	ldb	d, 0
	ldb	w, 255
	ldb	e, 18
	push	xiy
	call	16624672
	pop	xiy
	pop e
	pop d
	ld	h, d
	ld	l, e
	ld	(36955:16), 18
	push	xiy
	call	16554468
	pop	xiy
	ld	xbc, 65346
	st_rr8b	h, xbc, l
	ld	a, (xiy+3)
	sla	a, 6
	ldb	d, 4
	ldb	w, 64
	ldb	e, 18
	call	16624672
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
	ld	h, (13381:16)
	ld	l, (13382:16)
	cp	hl, wa
	jr	z, 38
	pushw	wa
	ld	(xiy+256), w
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
	calr	357
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
	ld	h, (13379:16)
	ld	l, (13380:16)
	cp	hl, wa
	jr	z, 38
	pushw	wa
	ld	(xiy+256), w
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
	calr	266
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
	ld	h, (13383:16)
	ld	l, (13384:16)
	cp	hl, wa
	jr	z, 38	; -> 0xF5F5A9
	pushw	wa
	ld	(xiy+256), w
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
	calr	178
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
	ld	h, (13385:16)
	ld	l, (13386:16)
	cp	hl, wa
	jr	z, 38
	pushw	wa
	ld	(xiy+256), w
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
	calr	90
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
	ld	h, (13387:16)
	ld	l, (13388:16)
	cp	hl, wa
	jr	z, 38
	pushw	wa
	ld	(xiy+256), w
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
	calr	2
AccPatch_SyncAcc3_Done:
	pop xiy
	ret
AccPatch_LoadVoiceParams:
	ld	e, (xiy+256)
	ld	d, (xiy+1)
	ld	a, (xiy+2)
	ld	(13203:16), a
	ld	a, (xiy+3)
	ld	(13204:16), a
	ld	a, (xiy+4)
	ld	(13205:16), a
	calr	1
	ret
AccPatch_CallParamLookup:
	push	xix
	pushw	de
	.byte 0xc1, 0x93, 0x33, 0x04, 0xc1, 0x94, 0x33, 0x04, 0xc1, 0x95, 0x33, 0x04
	call	16068346
	.byte 0xf1, 0x95, 0x33, 0x04, 0xf1, 0x94, 0x33, 0x04, 0xf1, 0x93, 0x33, 0x04
	popw	de
	pop	xix
	bit	7, e
	jr	z, 6
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
	call	16072747
	ret
AccPatch_ComplexDataBlock:
	ld	a, (35992:16)
	cp	a, 14
	jr	nz, 3
	calr	1
	ret
	ld	a, (49121:16)
	cps	a, 0
	jr	nz, 51
	cp	(49122:16), 128
	jr	nc, 44
	cp	(49123:16), 0
	jr	z, 37
	ld	a, (35994:16)
	cp	a, 180
	jr	nz, 28
	ld	xiy, 608256
	add	xiy, 0
	ld	a, (xiy+16)
	bit	0, a
	jr	nz, 9
	call	16143311
	ld	(13476:16), 7
	ld	a, (49121:16)
	cps	a, 0
	jr	nz, 28
	cp	(49123:16), 0
	jr	z, 21
	ld	a, (35994:16)
	cp	a, 184
	jr	nz, 12
	call	16144184
	call	16144371
	call	16143311
	ret
	calr	48
	ret
	ld XIY,0x00094800
	add XIY,0x00000000
	add XIY,0x00000000
	ld	a, (xiy+256)
	cp	a, 72
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	4
	call	16108060
	ret
	add	xiy, 0
	add	xiy, 0
	ld	a, (xiy+256)
	cp	a, 72
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 7
	call	16119825
	jrl	130
	.byte 0x85, 0x3f, 0x4c
	jr	nz, 22
	.byte 0x8d, 0x01, 0x3f, 0x4b
	jr	nz, 16
	.byte 0x8d, 0x02, 0x3f, 0x45
	jr	nz, 10
	call	16119825
	call	16119826
	jr	103
	ld	a, (xiy+256)
	cp	a, 71
	jr	nz, 25
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 18
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 10
	call	16119825
	call	16119826
	jr	70
	ld	a, (xiy+256)
	cp	a, 70
	jr	nz, 17
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 10
	ld	a, (xiy+2)
	cp	a, 75
	jr	nz, 2
	jr	39
	ld	a, (xiy+256)
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
	call	16108060
	jr	6
	call	16166817
	jr	0
	ret
	ret
	ld	xiy, 608256
	add	xiy, 0
	add	xiy, 0
	ldb	a, 72
	ld	(xiy+256), a
	ldb	a, 0
	ld	(xiy+1), a
	ldb	a, 75
	ld	(xiy+2), a
	ret
	calr	-3760
	calr	-3275
	calr	1
	ret
	ld	hl, (xiy+256)
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
	ldw	(xix+3), 65535
	pushw	hl
	ld	l, (xiy+12)
	xor	h, h
	lds32	xwa, 0
	ld	xbc, 14969738
	ld_rrb	a, xbc, hl
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
	cp wa, 0xffff
	jr z, AccPatch_FreeChain_Alt_Done

AccPatch_FreeChainLoop_Alt:
	.byte 0xd8, 0x8b, 0xbc, 0x03, 0x02, 0xff, 0xff, 0x1e
	.byte 0x19, 0x00, 0xbc, 0x01, 0x02, 0xff, 0xff, 0x84
	.byte 0x3c, 0x7f, 0xd1, 0x38, 0x34, 0x61, 0x9c, 0x03
	.byte 0x20, 0xd8, 0xcf, 0xff, 0xff, 0x66, 0x02, 0x68
	.byte 0xdf
AccPatch_FreeChain_Alt_Done:
	pop xiy
	ret

AccPatch_ResolveSlotAddr:
	cp	hl, 65535
	jr	z, 21
	pushw	hl
	pushw	hl
	lds32	xhl, 0
	popw	hl
	sll	xhl, 8
	ld	xix, (14610:16)
	add	xix, 5120
	add	xix, xhl
	popw	hl
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
	.byte 0x1e, 0x21, 0x00, 0xc9, 0xcf, 0x83, 0x66, 0x0b
	.byte 0x1e, 0x2c, 0x00, 0xf1, 0x7a, 0x35, 0xc8, 0x6e
	.byte 0x02, 0x68, 0xed
AccPatch_ScanSeq_StorePosAndRet:
	ld	wa, (13686:16)
	ld	(13674:16), wa
	ld	wa, (13688:16)
	ld	(13676:16), wa
	ret
AccPatch_SeqReadByte_Alt:
	push xix

	ld hl, (13686:16)

	calr 65375

	ld hl, (13688:16)

	ldb_sri A, 0x07, 0xf0, 0xec

	pop xix

	ret



AccPatch_SeqAdvance_Alt:
	.byte 0xd1, 0x78, 0x35, 0x20, 0xd8, 0xcf, 0xfe, 0x00
	.byte 0x6e, 0x28, 0xd1, 0x76, 0x35, 0x23, 0x1e, 0x43
	.byte 0xff, 0x9c, 0x03, 0x20, 0xf1, 0x76, 0x35, 0x50
	.byte 0xd8, 0xcf, 0xff, 0xff, 0x6e, 0x05, 0xc1, 0x7a
	.byte 0x35, 0x3e, 0x01
AccPatch_SeqAdvance_CheckLimit:
	.byte 0xd8, 0xcf, 0x54, 0x01, 0x61, 0x05, 0xc1, 0x7a
	.byte 0x35, 0x3e, 0x01
AccPatch_SeqAdvance_ResetBase:
	lds wa, 6
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
	jr	c, 2
	xor	l, l
AccPatch_InitSlotAlt_Valid:
	mul hl, 0x60

	add xhl, 0x60

	ld xiy, (14610:16)

	add xiy, xhl

	ld a, (14079:16)

	calr 62502

	ldw_sri HL, 0x03, 0xf4, 0xe1

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

	calr 61356

	ld hl, (13688:16)

	ldb_sri A, 0x07, 0xf0, 0xec

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
	lds wa, 6
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
	jr	z, 6
	calr	332
	calr	370
AccPatch_SeqDispatch_CheckEmpty:
	ld	a, (14079:16)
	and	a, 31
	cps	a, 0
	jr	nz, 3
	jrl	149
AccPatch_SeqDispatch_CheckPlaying:
	.byte 0xf1, 0xe7, 0x31, 0xc8, 0x6e, 0x07, 0x1d, 0x7c
	.byte 0x0f, 0xf6, 0x78, 0x88, 0x00
AccPatch_SeqDispatch_CheckStarted:
	.byte 0xf1, 0x65, 0x35, 0xc8, 0x6e, 0x16, 0x1e, 0x9a
	.byte 0x01, 0x1e, 0xe3, 0xec, 0xd1, 0x76, 0x35, 0x20
	.byte 0xf1, 0x66, 0x35, 0x50, 0xd1, 0x78, 0x35, 0x20
	.byte 0xf1, 0x68, 0x35, 0x50
AccPatch_SeqDispatch_ProcessFlags:
	calr	132
	ld	a, (13363:16)
	and	a, 12
	cps	a, 0
	jr	nz, 11
	ld	a, (13664:16)
	and	a, 12
	cps	a, 0
	jr	z, 5
AccPatch_SeqDispatch_ModeChange:
	calr AccPatch_UpdateSequenceState
	jr AccPatch_SyncStateAndReturn
AccPatch_SeqDispatch_RunNotes:
	call	16125806
	cps	wa, 0
	jr	z, 70
	ldw	(13678:16), 0
	ldw	(13682:16), 0
	ld	(13667:16), 0
	calr	1832
	cpw	(13678:16), 0
	jr	z, 31
	ld	wa, (13670:16)
	ld	(13922:16), wa
	ld	wa, (13672:16)
	ld	(13924:16), wa
	calr	3031
	calr	3327
	calr	3551
	ldw	(13678:16), 0
AccPatch_SeqDispatch_CheckQueued:
	cpw	(13682:16), 0
	jr	z, 3
	calr	3610
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
	.byte 0xe2, 0x9e, 0x74, 0x02, 0xe0, 0xf1, 0xd0, 0x11
	.byte 0x60, 0xe2, 0x9e, 0x74, 0x02, 0x20, 0xf1, 0x44
	.byte 0x39, 0x60, 0xe1, 0xd0, 0x11, 0x20, 0xe8, 0xcc
	.byte 0x00, 0x02, 0x00, 0x00, 0xe8, 0xcf, 0x00, 0x00
	.byte 0x00, 0x00, 0x66, 0x1d, 0xe1, 0x44, 0x39, 0x20
	.byte 0xe8, 0xcc, 0x00, 0x02, 0x00, 0x00, 0xe8, 0xcf
	.byte 0x00, 0x00, 0x00, 0x00, 0x6e, 0x0b, 0xc1, 0x33
	.byte 0x34, 0x21, 0xc9, 0xce, 0x04, 0xf1, 0x33, 0x34
	.byte 0x41
AccPatch_ReadModeFlags_Check400:
	ld	xwa, (4560:16)
	and	xwa, 1024
	cp	xwa, 0
	jr	z, 29
	ld	xwa, (14660:16)
	and	xwa, 1024
	cp	xwa, 0
	jr	nz, 11
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
	.byte 0x1e, 0x51, 0xfe, 0xc9, 0xcf, 0x83, 0x66, 0x0b
	.byte 0x1e, 0x5e, 0xfe, 0xf1, 0x7a, 0x35, 0xc8, 0x6e
	.byte 0x02, 0x68, 0xed
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
	.byte 0xb3, 0x02, 0x00, 0x00, 0xdb, 0xc8, 0x06, 0x00
	.byte 0xd9, 0x1c, 0xf5, 0x06, 0x06, 0xf1, 0xae, 0x35
	.byte 0xc8, 0x6e, 0x04, 0x1d, 0x7c, 0x0f, 0xf6
AccPatch_InitSeq_LoadTempo:
	.byte 0xc1, 0x35, 0x04, 0x21, 0xc1, 0x16, 0x04, 0x23
	.byte 0x06, 0x00, 0xc1, 0xae, 0x35, 0x3c, 0xfe, 0xc1
	.byte 0x3d, 0x34, 0x22, 0xca, 0x41, 0xc9, 0x83, 0xca
	.byte 0xd2, 0x29, 0x1e, 0x5c, 0xeb, 0x49, 0xd9, 0xd8
	.byte 0x66, 0x08
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
	ld	xhl, 13694
	ldw	bc, 8
AccPatch_ResetSeqCounters_Loop:
	.byte 0xb3, 0x02, 0x00, 0x00, 0xdb, 0xc8, 0x06, 0x00
	.byte 0xd9, 0x1c, 0xf5, 0x06, 0x06, 0xc1, 0x35, 0x04
	.byte 0x21, 0xc1, 0x16, 0x04, 0x23, 0x06, 0x00, 0xc1
	.byte 0xae, 0x35, 0x3c, 0xfe, 0xc1, 0x3d, 0x34, 0x22
	.byte 0xca, 0x41, 0xc9, 0x83, 0xca, 0xd2, 0x29, 0x1d
	.byte 0x7e, 0xe7, 0xf5, 0x49, 0xd9, 0xd8, 0x66, 0x08
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

__pad_F600A1:
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
	jr	c, -22
	calr	60097
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
	di
	ld	a, (13363:16)
	ld	w, (13664:16)
	bit	2, a
	jr	nz, 7
	bit	2, w
	jr	nz, 2
	jr	36
AccPatch_UpdateSeqState_CheckXor:
	.byte 0xc9, 0x8b, 0xc8, 0xd3, 0xcb, 0xc1, 0xc9, 0xd8
	.byte 0x66, 0x0a, 0x1e, 0x29, 0x01, 0xc1, 0x61, 0x35
	.byte 0x3e, 0x01, 0x68, 0x5d
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
	.byte 0xf1, 0xff, 0x36, 0xcc, 0x66, 0x47, 0xc1, 0xbc
	.byte 0x34, 0x21, 0xf1, 0x5f, 0x35, 0x41, 0xf1, 0x33
	.byte 0x34, 0xcb, 0x66, 0x10, 0xf1, 0xbc, 0x34, 0xcf
	.byte 0x6e, 0x05, 0x1e, 0x6a, 0x00, 0x68, 0x03
AccPatch_UpdateSeqState_ScanNoteOff:
	calr AccPatch_ScanForNoteOff

AccPatch_UpdateSeqState_AfterScan:
	jr AccPatch_UpdateSeqState_CompareBits

AccPatch_UpdateSeqState_ClearBit7:
	.byte 0xc1, 0xbc, 0x34, 0x3c, 0x7f	; anddi8 (0x3558), 127 (v7 patched)



AccPatch_UpdateSeqState_CompareBits:
	ld	a, (13500:16)
	ld	c, (13663:16)
	bit	7, a
	jr	z, 10
	bit	7, c
	jr	nz, 15
	calr	212
	jr	13
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
	.byte 0xf1, 0x33, 0x34, 0xcb, 0x6e, 0x09, 0xf1, 0x60
	.byte 0x35, 0xcb, 0x66, 0x03, 0x1e, 0x60, 0xfe
AccPatch_UpdateSeqState_StoreFlags:
	.byte 0xc1, 0x33, 0x34, 0x21, 0xf1, 0x60, 0x35, 0x41
	.byte 0xc1, 0x5f, 0x35, 0x3c, 0xfd, 0xf1, 0x5f, 0x35
	.byte 0xc8, 0x66, 0x05, 0xc1, 0x5f, 0x35, 0x3e, 0x02
AccPatch_UpdateSeqState_Return:
	ret

__pad_F601A3:
	nop
	nop

AccPatch_ClearAndScanForNote:
	.byte 0xc1, 0xbc, 0x34, 0x3c, 0x7f	; anddi8 (0x3558), 127 (v7 patched)



AccPatch_ScanForActiveNote:
	call	16125806
	cps	wa, 0
	jr	z, 48
	lds	bc, 1
	calr	44
	ld	w, a
	and	w, 240
	cp	w, 144
	jr	nz, 31
	lds	bc, 2
	calr	29
	ld	l, a
	push	l
	lds	bc, 1
	calr	20
	pop	l
	cps	a, 0
	jr	z, 11
	or	l, 128
	ld	(13500:16), l
	call	16125820
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
	.byte 0x1d, 0x6e, 0x0f, 0xf6, 0xd8, 0xd8, 0x66, 0x35
	.byte 0xd9, 0xa9, 0x1e, 0xe4, 0xff, 0xc9, 0x88, 0xc8
	.byte 0xcc, 0xf0, 0xc8, 0xcf, 0x90, 0x6e, 0x24, 0xd9
	.byte 0xaa, 0x1e, 0xd5, 0xff, 0xc9, 0x8f, 0xc1, 0xbc
	.byte 0x34, 0x26, 0xce, 0xcc, 0x7f, 0xcf, 0xf6, 0x6e
	.byte 0x12, 0xd9, 0xa9, 0x1e, 0xc3, 0xff, 0xc9, 0xd8
	.byte 0x6e, 0x09, 0xc1, 0xbc, 0x34, 0x3c, 0x7f, 0x1d
	.byte 0x7c, 0x0f, 0xf6
AccPatch_ErrorExit:
	jr AccPatch_ScanForNoteOff

AccPatch_ScanForNoteOff_Done:
	ret

AccPatch_SeekToPosition:
	calr	28
	ld	a, (13930:16)
	ld	(13916:16), a
	calr	55
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
	ret
AccPatch_SeekForwardSteps:
	ld	a, (13661:16)
	ld	c, (13931:16)
	ld	b, (13373:16)
	mul8rr	a, b
	add	c, a
	xor	b, b
	pushw	bc
	calr	59677
	popw	bc
	cps	bc, 0
	jr	z, 8
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
	.byte 0xc1, 0x5c, 0x36, 0xf1, 0x6b, 0x15
AccPatch_ParseHdr_AdvanceAndRead:
	.byte 0x1e, 0x85, 0xfb, 0x1e, 0x6d, 0xfb, 0xf1, 0x7a
	.byte 0x35, 0xc8, 0x66, 0x02, 0x68, 0x17
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

__pad_F602CB:
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
	.byte 0xd1, 0x46, 0x35, 0xf0, 0x6e, 0x10, 0xd1, 0x78
	.byte 0x35, 0x20, 0xd1, 0x48, 0x35, 0xf0, 0x6e, 0x06
	.byte 0x1e, 0xa5, 0x00, 0x78, 0x80, 0x00
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
	.byte 0xd1, 0x6e, 0x35, 0x89	; adddm16 0x360a, xbc (v7 patched)



AccPatch_ResumeSeq_AdvLoop:
	calr AccPatch_AdvanceSeqIndex
	djnz xbc, AccPatch_ResumeSeq_AdvLoop
	jr AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_HandleMarker:
	calr	100
	calr	-1305
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
	calr	-1345
	cp	a, 131
	jr	z, 20
	cpw	(13678:16), 0
	jr	z, 9
	calr	31
	ldw	(13678:16), 0
AccPatch_ResumeSeq_LoopBack:
	jrl AccPatch_ResumeSeq_ComparePos

AccPatch_ResumeSeq_InitSlot:
	calr	59405
	ld	wa, (13686:16)
	ld	(13634:16), wa
	ld	wa, (13688:16)
	ld	(13636:16), wa
AccPatch_ResumeSeq_Return:
	ret

__pad_F60386:
	nop
	nop

AccPatch_PrepareSequencePlayback:
	calr	65220
	ld	a, (13930:16)
	ld	(13916:16), a
	calr	65247
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
	.byte 0xd1, 0xbc, 0x35, 0xf0, 0x6e, 0x0c, 0xd1, 0xc4
	.byte 0x35, 0x20, 0xd1, 0xc2, 0x35, 0xf0, 0x6e, 0x02
	.byte 0x68, 0x16
AccPatch_CheckChanged_DoCopy:
	calr	22
	calr	123
	ld	wa, (13634:16)
	ld	(13686:16), wa
	ld	wa, (13636:16)
	ld	(13688:16), wa
AccPatch_CheckChanged_Return:
	ret

__pad_F603FC:
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
	.byte 0xd1, 0x6a, 0x35, 0xf0, 0x66, 0x20, 0xd1, 0x38
	.byte 0x34, 0x61, 0xd1, 0xbe, 0x35, 0x23, 0x1e, 0x8e
	.byte 0xe9, 0x9c, 0x03, 0x20, 0xbc, 0x03, 0x02, 0xff
	.byte 0xff, 0xd8, 0x8b, 0x1e, 0x81, 0xe9, 0x84, 0x3c
	.byte 0x7f, 0xbc, 0x01, 0x02, 0xff, 0xff
AccPatch_CopyEntry_Store:
	ld	wa, (13758:16)
	ld	(13674:16), wa
	ld	wa, (13928:16)
	ld	(13676:16), wa
	ret
__pad_F60464:
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
	.byte 0xd1, 0x42, 0x35, 0xf3, 0x66, 0x0c, 0x9c, 0x01
	.byte 0x3f, 0xff, 0xff, 0x66, 0x39, 0x1e, 0x5a, 0x00
	.byte 0x68, 0x34
AccPatch_UpdateEntry_CheckDE:
	.byte 0xd1, 0x44, 0x35, 0xf2, 0x6f, 0x02, 0x68, 0x2c
AccPatch_UpdateEntry_AdjustOffset:
	subda16	xde, (13678)
	cps	de, 6
	jr	z, 29	; -> 0xF600AF
	jr	ugt, 27	; -> 0xF600AF
	lds	hl, 6
	sub	hl, de
	ld	de, hl
	pushw	de
	ld	wa, (xix+1)
	pushw	wa
	calr	23
	popw	wa
	ld	(xiy), wa
	popw	de
	ldw	hl, 255
	sub	hl, de
	ld	(xix), hl
	jr	7	; -> 0xF600B6
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
	push	xbc
	lds32	xbc, 0
	ld	c, (14079:16)
	sll	bc, 2
	push	xbc
	add	xbc, 16124065
	ld	xix, xbc
	ld	xix, (xix)
	pop	xbc
	ld	xiy, 16123997
	add	xiy, xbc
	ld	xiy, (xiy)
	pop	xbc
	ret
AccPatch_AdjustTableEntryPos:
	calr	65500
	ld	de, (xix)
	ld	wa, (xiy)
	sub	de, 6
	cp	de, (13678:16)
	jr	c, 12	; -> 0xF600F7
	subda16	xde, (13678)
	add	de, 6
	ld	(xix), de
	jr	25	; -> 0xF60110
AccPatch_AdjustEntry_Overflow:
	ld	hl, (13678:16)
	sub	hl, de
	ldw	de, 255
	sub	de, hl
	ld	(xix), de
	ld	hl, wa
	push	xiy
	calr	59582
	pop	xiy
	ld	hl, (xix+1)
	ld	(xiy), hl
AccPatch_AdjustEntry_Return:
	ret

AccPatch_PrepareAndProcessEvents:
	calr	65136
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
	calr	63686
	ld	(13917:16), a
	cp	a, 144
	jr	z, 26
	cp	a, 145
	jr	z, 21
	cp	a, 146
	jr	z, 16
	cp	a, 129
	jr	z, 71
	and	a, 240
	cp	a, 208
	jr	z, 77
	jrl	155
AccPatch_SkipNoteOff:
	calr	-1867
	calr	-1870
	calr	-1894
	ld	(13662:16), a
	lds	bc, 6
	cp	(13917:16), 145
	jr	z, 2
	lds	bc, 4
AccPatch_ProcessSeqEvt_AdvLoop:
	calr	63645
	djnz16	bc, -6
	ld	a, (13662:16)
	ld	b, (13500:16)
	and	b, 127
	cp	a, b
	jr	z, 40
	cp	a, 93
	jr	nz, 7
	cp	b, 48
	jr	nz, 2
	jr	28
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
	ldw	(13678:16), 8
	cp	(13917:16), 145
	jr	z, 6
	ldw	(13678:16), 6
AccPatch_ProcessSeqEvt_StoreAndPrep:
	ld	wa, (13918:16)
	ld	(13634:16), wa
	ld	wa, (13920:16)
	ld	(13636:16), wa
	calr	64951
	ldw	(13678:16), 0
	calr	64911
	jrl	-212
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
	lds	bc, 5
	calr	162
	cp	(13905:16), 0
	jr	nz, 5
	calr	967
	jr	47
AccPatch_EventDispatch_NoteResolve:
	calr AccPatch_ParseAndResolve
	calr AccPatch_CopyNoteStepsToSlots
	jr AccPatch_ContinueProcessing

AccPatch_EventDispatch_EndMarker:
	.byte 0x1d, 0x75, 0x0f, 0xf6, 0x1e, 0x26, 0x00, 0xf1
	.byte 0xae, 0x35, 0xc9, 0x6e, 0x03, 0x1e, 0xfb, 0xf9
AccPatch_EventDispatch_AdvSlots:
	.byte 0x1e, 0x54, 0x00, 0xc1, 0xae, 0x35, 0x3c, 0xfd
	.byte 0x68, 0x0d
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
__pad_F606D3:
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
	jr	nz, -31
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
	popw	hl
	popw	bc
	ld	xiz, 13902
	st_rrb	a, xiz, hl
	inc	1, hl
	jr	-32
AccPatch_ReadBuf_Done:
	ret

__pad_F6071F:
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
	calr	64302
	ld	wa, (13686:16)
	ld	(13670:16), wa
	ld	wa, (13688:16)
	ld	(13672:16), wa
AccPatch_ParseResolve_IncStep:
	inc	1, (13667:16)
	ld	a, (13916:16)
	ld	(13668:16), a
	ret
__pad_F60764:
	nop
	nop

AccPatch_LookupStepByDrumParam:
	xor W,W
	ld IY,WA
	ld a, (0x343f:16)
	cps a, 0
	jr z, AccPatch_SetStepDone
	ld WA,IY
	ld w, (0x343f:16)
	and W,0x07
	call DrumParam_Wrapper
	cp A,0x7f
	jr nz, AccPatch_LookupStep_StoreResult
	ldb A, 0x00
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

__pad_F607AA:
	nop
	nop

AccPatch_CopyNoteStepsToSlots:
	ld	xhl, 13694
	xor	iy, iy
AccPatch_CopySteps_FindFreeSlot:
	bit_dri 7, 0x07, 0xec, 0xf4
	jr z, AccPatch_CopySteps_ProcessEntry
	add iy, 0x6
	cp iy, 0x30
	jr z, AccPatch_CopyStepsDone
	jr AccPatch_CopySteps_FindFreeSlot

AccPatch_CopySteps_ProcessEntry:
	.byte 0xdd, 0x8a, 0xd1, 0x38, 0x34, 0x3f, 0x00, 0x00
	.byte 0x66, 0x69, 0xf1, 0x95, 0x33, 0x00, 0x00, 0xf1
	.byte 0x4e, 0x36, 0x00, 0x90, 0xf1, 0xff, 0x36, 0xcc
	.byte 0x6e, 0x03, 0x1e, 0x67, 0x00
AccPatch_CopySteps_StartFetch:
	.byte 0xc1, 0x4e, 0x36, 0x21, 0x1e, 0x91, 0x01, 0x1e
	.byte 0xb8, 0x01, 0xc1, 0x4f, 0x36, 0x21, 0x1e, 0x87
	.byte 0x01, 0x1e, 0xae, 0x01, 0xc1, 0x50, 0x36, 0x21
	.byte 0x1e, 0x7d, 0x01, 0x1e, 0xef, 0x01, 0x1e, 0xa1
	.byte 0x01, 0xc1, 0x51, 0x36, 0x21, 0x1e, 0x70, 0x01
	.byte 0x1e, 0x97, 0x01, 0x21, 0x10, 0x1e, 0x68, 0x01
	.byte 0x1e, 0x8f, 0x01, 0x21, 0x00, 0x1e, 0x60, 0x01
	.byte 0x1e, 0x87, 0x01, 0xf1, 0x95, 0x33, 0xc8, 0x66
	.byte 0x14, 0xc1, 0x54, 0x36, 0x21, 0x1e, 0x50, 0x01
	.byte 0x1e, 0x77, 0x01, 0xc1, 0x55, 0x36, 0x21, 0x1e
	.byte 0x46, 0x01, 0x1e, 0x6d, 0x01
AccPatch_CopyStepsDone:
	ret

AccPatch_CopySteps_Overflow:
	ld	(32422:16), 15
	call	16143598
	ldb	a, 8
	call	16692690
	jr	-18
AccPatch_TransposeNote:
	ld	a, (13389:16)
	and	a, 15
	cps	a, 0
	jr	z, 31
	calr	225
	cp	a, (14770:16)
	jr	ugt, 14
	subdm8	13904, a
	jr	nc, 6
	ldb	a, 12
	adddm8	13904, a
AccPatch_Transpose_Done:
	jr AccPatch_Transpose_LookupTable

AccPatch_Transpose_AddBack:
	ldb	w, 12
	sub	w, a
	adddm8	(13904), w
AccPatch_Transpose_LookupTable:
	.byte 0xeb, 0xa8, 0xc1, 0x50, 0x36, 0x27, 0xeb, 0xc8
	.byte 0x42, 0x61, 0xe4, 0x00, 0x83, 0x21, 0xf1, 0x4e
	.byte 0x34, 0xcc, 0x66, 0x21, 0xc9, 0x88, 0xeb, 0xa8
	.byte 0xc9, 0x8f, 0xeb, 0xc8, 0x05, 0x05, 0xf6, 0x00
	.byte 0x83, 0x27, 0xcf, 0x33, 0x00, 0x66, 0x0e, 0xc8
	.byte 0x61, 0xc1, 0x50, 0x36, 0x21, 0xc9, 0x61, 0xf1
	.byte 0x50, 0x36, 0x41, 0xc8, 0x89
AccPatch_Transpose_CheckBit6:
	.byte 0xf1, 0x4e, 0x34, 0xce, 0x66, 0x08, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x66, 0x02, 0x68, 0x0c
AccPatch_Transpose_CheckBit5:
	.byte 0xf1, 0x4e, 0x34, 0xcd, 0x66, 0x1b, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x6e, 0x15
AccPatch_Transpose_SetDrumSplit:
	cps	a, 7
	jr	nz, 17
	ld	(13205:16), 1
	ld	(13908:16), 3
	ld	(13909:16), 0
	jr	35
AccPatch_StoreDrumParams:
	lds32	xhl, 0
	ld	l, a
	sll	a, 1
	add	l, a
	add	xhl, 16123153
	ld	a, (xhl)
	ld	(13205:16), a
	ld	a, (xhl+1)
	ld	(13908:16), a
	ld	a, (xhl+2)
	ld	(13909:16), a
AccPatch_StoreDrumParams_CheckSplit:
	.byte 0xf1, 0x95, 0x33, 0xc8, 0x66, 0x05, 0xf1, 0x4e
	.byte 0x36, 0x00, 0x91
AccPatch_StoreDrumParams_Return:
	ret

AccPatch_TransposeNoteTable:
	nop
	nop
	nop
	nop
	nop
	normal
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
	normal
	nop
	scf
	normal
	nop
	scf
	nop
	nop
	nop
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01
	.byte 0x11, 0x11

AccPatch_ReadTransposeAmount:
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16116102
	ld	a, (14079:16)
	ld	xix, 37
	bit	3, a
	jr	nz, 25
	ld	xix, 45
	bit	0, a
	jr	nz, 15
	ld	xix, 53
	bit	1, a
	jr	nz, 5
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

	stb_dri A, 0x07, 0xf4, 0xec

	inc 1, hl

	ld (13678:16), hl

	ret



AccPatch_FetchStepData:
	.byte 0x45, 0x0e, 0x36, 0x00, 0x00, 0xd1, 0x72, 0x35
	.byte 0x23, 0xf3, 0x07, 0xf4, 0xec, 0x41, 0xdb, 0x61
	.byte 0xf1, 0x72, 0x35, 0x53, 0x0e
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
	calr	58370
	ld	hl, (xix+3)
	cp	hl, 65535
	jr	z, 2
	jr	14
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
__pad_F609EE:
	nop
	nop

AccPatch_UpdateSlotVoiceData:
	ld xhl, 13694

	ld iy, de

	or a, 0x80

	stb_dri A, 0x07, 0xec, 0xf4

	pushw iy

	inc 1, iy

	stib_ind 0x07, 0xec, 0xf4, 0x00

	ld a, (13915:16)

	inc 1, iy

	stb_dri A, 0x07, 0xec, 0xf4

	ld wa, (13686:16)

	inc 1, iy

	stw_dri WA, 0x07, 0xec, 0xf4

	ld wa, (13688:16)

	inc 2, iy

	stb_dri A, 0x07, 0xec, 0xf4

	popw iy

	ret



AccPatch_TransposeAndCopyNote:
	.byte 0xf1, 0xff, 0x36, 0xcc, 0x6e, 0x03, 0x1e, 0x16
	.byte 0xfe
AccPatch_TransposeCopy_DoCopy:
	ld xiy, 13902

	ld xix, 13838

	lds32 xbc, 0

	ld bc, (13682:16)

	add xix, xbc

	lds bc, 6

	ldir85

	.byte 0xd1, 0x72, 0x35, 0x38, 0x06, 0x00	; adddi16 0x360e, 6 (v7 patched)

	ret



__pad_F60A51:
	nop
	nop

AccPatch_ProcessMarkerEvent:
	cpw (0x3438:16), 0x0000
	jr z, AccPatch_ProcessMarker_Return
	ld a, (0x364e:16)
	cp A,0xd4
	jr nz, AccPatch_ProcessMarker_CheckD3
	ldb A, 0xd3
	jr t, AccPatch_FetchSequence
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
	calr	65278
	calr	65317
	ld	a, (13903:16)
	calr	65268
	calr	65307
	ld	a, (13904:16)
	calr	65258
	calr	65297
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
	jr	nz, -12	; -> 0xF6069F
	ret
	ldw	(13684:16), 0
	ld	xix, 13838
	addda16	xix, (13684)
	calr	664
	ld	wa, (13684:16)
	add	wa, 6
	ld	(13684:16), wa
	cp	wa, (13682:16)
	jr	c, -30	; -> 0xF606B2
	ldw	(13682:16), 0
	ret
AccPatch_InitSlotAndCopyData:
	lds32 xhl, 0
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
	.byte 0xd1, 0x6e, 0x35, 0xf1, 0x6f, 0x02, 0x68, 0x1d
AccPatch_InitSlot_SameBlock:
	ld	hl, (13674:16)
	ld	(13758:16), hl
	calr	58028
	ld	(13744:16), xix
	ld	wa, (13676:16)
	addda16	xwa, (13678)
	ld	(13764:16), wa
	jr	32	; -> 0xF6074E
AccPatch_InitSlot_CrossBlock:
	calr	157
	ld	(13758:16), wa
	ld	hl, wa
	calr	57998
	ld	(13744:16), xix
	ld	wa, (13678:16)
	subda16	xwa, (13926)
	add	wa, 5
	ld	(13764:16), wa
AccPatch_InitSlot_StoreAddrs:
	.byte 0xd1, 0xbe, 0x35, 0x20, 0xf1, 0x6a, 0x35, 0x50
	.byte 0xd1, 0xc4, 0x35, 0x20, 0xf1, 0x6c, 0x35, 0x50
	.byte 0x1e, 0xc7, 0x02, 0xdc, 0x61, 0xf1, 0x68, 0x36
	.byte 0x54, 0xd1, 0x66, 0x35, 0x23, 0x1e, 0x5a, 0xe2
	.byte 0xe8, 0xa8, 0xd1, 0x68, 0x35, 0x20, 0xe8, 0x84
	.byte 0x45, 0xce, 0x35, 0x00, 0x00, 0xe9, 0xa8, 0x31
	.byte 0xfe, 0x00, 0xd1, 0x68, 0x35, 0xa1, 0xd9, 0x61
	.byte 0xd1, 0x6e, 0x35, 0xf1, 0x67, 0x0a, 0xe9, 0xa8
	.byte 0xd1, 0x6e, 0x35, 0x21, 0x85, 0x11, 0x68, 0x25
AccPatch_InitSlot_SplitCopy:
	.byte 0xd9, 0x88, 0x85, 0x11, 0xe9, 0xa8, 0xd1, 0x6e
	.byte 0x35, 0x21, 0xd8, 0xa1, 0xd1, 0x66, 0x35, 0x23
	.byte 0x1e, 0x1f, 0xe2, 0x9c, 0x03, 0x23, 0x1e, 0x19
	.byte 0xe2, 0xec, 0xc8, 0x06, 0x00, 0x00, 0x00, 0xd9
	.byte 0xd8, 0x66, 0x02, 0x85, 0x11
AccPatch_InitSlot_Finalize:
	ld	wa, (13758:16)
	ld	(13670:16), wa
	ld	wa, (13928:16)
	ld	(13672:16), wa
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

	ld hl, (13674:16)

	pushw wa

	calr 57825

	popw wa

	ld (xix + 3), wa

	pop xix

	ormi8 (xix), 0x80

	ld bc, (13674:16)

	ld (xix + 1), bc

	ldw (xix + 3), 0xffff

	decw 1, (13368:16)

	ret



__pad_F60C04:
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
	.byte 0xd1, 0x62, 0x36, 0xf3, 0x66, 0x09, 0x9c, 0x01
	.byte 0x3f, 0xff, 0xff, 0x6e, 0x0a, 0x68, 0x36
AccPatch_AdvPlayPos_CheckDE:
	.byte 0xd1, 0x64, 0x36, 0xf2, 0x6f, 0x02, 0x68, 0x2e
AccPatch_AdvPlayPos_AddAndCheck:
	addda16	xde, (13678)
	cp	de, 254
	jr	z, 29	; -> 0xF6084E
	jr	c, 27	; -> 0xF6084E
	sub	de, 254
	pushw	de
	calr	57741
	ld	wa, (xix+3)
	pushw	wa
	calr	63607
	popw	wa
	popw	de
	ld	(xiy), wa
	add	de, 5
	ld	(xix), de
	jr	7	; -> 0xF60855
AccPatch_AdvPlayPos_StoreDirect:
	pushw de
	calr AccPatch_LoadTablePointers
	popw de
	ld (xix), de

AccPatch_StoreEntryPtr:
	ret

AccPatch_AdvPlayPos_DataBlock:
	.incbin "includes/romslices/v7_transplant_AccPatch_AdvPlayPos_DataBlock.bin"
AccPatch_AdvanceAllSteps:
	ld	xix, 13694
AccPatch_AdvAllSteps_Loop:
	.byte 0xbc, 0x01, 0xcf, 0x66, 0x0a, 0xd1, 0x6e, 0x35
	.byte 0x21
AccPatch_AdvAllSteps_InnerLoop:
	calr AccPatch_AdvanceSingleStep
	djnz xbc, AccPatch_AdvAllSteps_InnerLoop

AccPatch_AdvAllSteps_Next:
	add	xix, 6
	cp	xix, 13742
	jr	c, -29
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
	ld	xix, 13838
AccPatch_DispatchQueued_Loop:
	calr	29
	add	xix, 6
	ld	xwa, xix
	sub	xwa, 13838
	cp	wa, (13682:16)
	jr	c, -23	; -> 0xF60936
	ldw	(13682:16), 0
	ret
__pad_F60D58:
	nop
	nop

AccPatch_DispatchNoteToVoice:
	ld	xhl, 13694
	ldw	iy, 42
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
	pushw DE
	pushw WA
	ld wa, (0x3576:16)
	ld (0x365e:16), wa
	ld wa, (0x3578:16)
	ld (0x3660:16), wa
	inc 1,IY
	.byte 0xd3, 0x07, 0xec, 0xf4, 0x20, 0xf1, 0x76, 0x35
	.byte 0x50, 0x2d, 0xdd, 0x62, 0xd8, 0xd0, 0xc3, 0x07
	.byte 0xec, 0xf4, 0x21, 0x4d, 0xf1, 0x78, 0x35, 0x50
	.byte 0x1e, 0x33, 0xf0, 0x8c, 0x02, 0xf1, 0x66, 0x04
	.byte 0x48, 0x4a, 0x68, 0x13
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
__pad_F60E12:
	nop
	nop

AccPatch_WriteSeqByte:
	push	xix
	ld	hl, (13686:16)
	calr	57264
	push	xwa
	lds32	xwa, 0
	ld	wa, (13688:16)
	add	xix, xwa
	pop	xwa
	ld	(xix), a
	pop	xix
	ret
__pad_F60E2A:
	nop
	nop

AccPatch_CalcBlockCopySetup:
	ld	(32422:16), 0
	cp	de, (13756:16)
	jr	nz, 41	; -> 0xF60A5C
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
	calr	536
	jr	37	; -> 0xF60A81
AccPatch_CalcBlockCopy_DiffEntry:
	.byte 0xd1, 0xc4, 0x35, 0x20, 0xd1, 0xc2, 0x35, 0xf0
	.byte 0x6b, 0x04, 0x66, 0x07, 0x68, 0x0a
AccPatch_CalcBlockCopy_Clamp:
	calr __pad_F60E86
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_StoreIY:
	calr BlockCopy_SameEntry_Reverse
	jr AccPatch_CalcBlockCopy_StoreIX

AccPatch_CalcBlockCopy_CheckIX:
	calr BlockCopy_IXFirst_Reverse

AccPatch_CalcBlockCopy_StoreIX:
	cp	(32422:16), 0
	jr	nz, 3
	calr	497
AccPatch_CalcBlockCopy_Done:
	ret

__pad_F60E86:
	ld wa, (0x35c4:16)
	subda16 xwa, 0x35c2
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	lds32 xix, 0
	lds32 xiy, 0
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
	subda16 xwa, 0x35c4
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	lds32 xix, 0
	lds32 xiy, 0
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
	jr	nc, 2	; -> 0xF60C8C
	jr	5	; -> 0xF60C91
BlockCopyBounds_UseBC:
	calr DSP_BlockCopyReverse
	jr BlockCopyBounds_Return

BlockCopyBounds_UseSmaller:
	.byte 0xd1, 0xca, 0x35, 0x21, 0x1e, 0x6a, 0xfe, 0x1e
	.byte 0x3b, 0x00, 0xc1, 0xa6, 0x7e, 0x3f, 0x00, 0x66
	.byte 0x02, 0x68, 0x0b
BlockCopyBounds_CopyRemainder:
	.byte 0xd1, 0xcc, 0x35, 0x21	; ldw_d16 xbc, (0x3668) (v7 patched)

	.byte 0xd1, 0xca, 0x35, 0xa1	; subda16 xbc, 0x3666 (v7 patched)

	.byte 0x1e, 0x53, 0xfe	; calr DSP_BlockCopyReverse (v7 displacement)



BlockCopyBounds_Return:
	ret

AccPatch_AdvanceNextEntry_IY:
	push XIX
	ld xiy, (0x35b4:16)
	ld HL,(XIY+0x01)
	ld (0x35bc:16), hl
	calr AccPatch_GetEntryAddr
	.byte 0xbc, 0x00, 0xcf, 0x6e, 0x07, 0xf1, 0xa6, 0x7e
	.byte 0x00, 0x0b, 0x68, 0x09
AdvNextEntry_IY_StoreAndReset:
	ld	(13748:16), xix
	lds32	xiy, 0
	ldw	iy, 254
AdvNextEntry_IY_Return:
	pop xix
	ret

AccPatch_AdvanceNextEntry_IX:
	ld xix, (0x35b0:16)
	ld HL,(XIX+0x01)
	ld (0x35be:16), hl
	calr AccPatch_GetEntryAddr
	.byte 0xbc, 0x00, 0xcf, 0x6e, 0x07, 0xf1, 0xa6, 0x7e
	.byte 0x00, 0x0b, 0x68, 0x09
AdvNextEntry_IX_StoreAndReset:
	ld	(13744:16), xix
	lds32	xix, 0
	ldw	ix, 254
AdvNextEntry_IX_Return:
	ret

AccPatch_SetupBlockCopyDispatch:
	ld (0x7ea6:16), 0x00
	ld hl, (0x35bc:16)
	calr AccPatch_GetEntryAddr
	ld (0x35b4:16), xix
	.byte 0xd1, 0xbc, 0x35, 0xf2, 0x6e, 0x27, 0xed, 0xa8
	.byte 0x35, 0xff, 0x00, 0xd1, 0xc2, 0x35, 0xa5, 0xf1
	.byte 0xc8, 0x35, 0x55, 0xd1, 0xc2, 0x35, 0x25, 0xec
	.byte 0xa8, 0x34, 0xff, 0x00, 0xd1, 0xc4, 0x35, 0xa4
	.byte 0xf1, 0xca, 0x35, 0x54, 0xd1, 0xc4, 0x35, 0x24
	.byte 0x1e, 0xaf, 0x01, 0x68, 0x27
BlockCopyDisp_CompareOffsets:
	.byte 0xd1, 0xc4, 0x35, 0x20, 0xd1, 0xc2, 0x35, 0xf0
	.byte 0x67, 0x04, 0x66, 0x07, 0x6b, 0x0a
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
	jr	nz, 3
	calr	390
BlockCopyDisp_Return:
	ret

BlockCopy_FwdIYSmaller:
	ldw WA, 0x00ff
	subda16 xwa, 0x35c4
	ldw BC, 0x00ff
	subda16 xbc, 0x35c2
	sub WA,BC
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	lds32 xiy, 0
	ld iy, (0x35c2:16)
	lds32 xix, 0
	ld ix, (0x35c4:16)
	ldw BC, 0x00ff
	subda16 xbc, 0x35c2
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
	subda16 xbc, 0x35c2
	lds32 xiy, 0
	ld iy, (0x35c2:16)
	lds32 xix, 0
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
	subda16 xwa, 0x35c2
	ldw BC, 0x00ff
	subda16 xbc, 0x35c4
	sub WA,BC
	ld (0x35b8:16), wa
	ldw BC, 0x00ff
	sub BC,0x0006
	sub BC,WA
	ld (0x35ba:16), bc
	lds32 xiy, 0
	ld iy, (0x35c2:16)
	lds32 xix, 0
	ld ix, (0x35c4:16)
	ldw BC, 0x00ff
	subda16 xbc, 0x35c4
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
	.byte 0xc1, 0xa6, 0x7e, 0x3f, 0x00, 0x6e, 0x3c, 0x30
	.byte 0xfe, 0x00, 0xd1, 0xc6, 0x35, 0xa0, 0xd1, 0xc8
	.byte 0x35, 0x21, 0xd8, 0xa1, 0xf1, 0xcc, 0x35, 0x51
	.byte 0xd1, 0xca, 0x35, 0xf9, 0x6f, 0x02, 0x68, 0x05
FwdBlockCopy_UseFull:
	calr DSP_BlockCopyForward
	jr AccPatch_DoneBlockCopy

FwdBlockCopy_UseSmaller:
	.byte 0xd1, 0xca, 0x35, 0x21, 0x1e, 0x2d, 0xfc, 0x1e
	.byte 0x15, 0x00, 0xc1, 0xa6, 0x7e, 0x3f, 0x00, 0x66
	.byte 0x02, 0x68, 0x0b
FwdBlockCopy_CopyRemainder:
	.byte 0xd1, 0xcc, 0x35, 0x21	; ldw_d16 xbc, (0x3668) (v7 patched)

	.byte 0xd1, 0xca, 0x35, 0xa1	; subda16 xbc, 0x3666 (v7 patched)

	.byte 0x1e, 0x16, 0xfc	; calr DSP_BlockCopyForward (v7 displacement)



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
	lds32	xix, 0
	lds	ix, 6
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
	lds32	xiy, 0
	lds	iy, 6
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
	.byte 0xc1, 0x74, 0x34, 0xf1, 0x66, 0x0c, 0xc9, 0xcc
	.byte 0x1f, 0xc9, 0xd8, 0x66, 0x05, 0xc1, 0x34, 0x34
	.byte 0x3e, 0x10
AccPlayback_CheckStyleMatch:
	ld	a, (35994:16)
	cp	a, 182
	jr	z, 3
	jrl	229
AccPlayback_CheckActiveStyle:
	.byte 0xc1, 0x89, 0x34, 0xf1, 0x66, 0x1c, 0xf1, 0x61
	.byte 0x34, 0x00, 0x00, 0x1d, 0xdb, 0x24, 0xef, 0xf1
	.byte 0xe7, 0x31, 0xc8, 0x6e, 0x05, 0xc1, 0x31, 0x34
	.byte 0x3e, 0x80
AccPlayback_GetSlotAddr:
	call AccPatch_GetCurrentSlotAddr
	call AccPatch_ReadVoiceStride
AccPlayback_CheckBit4:
	.byte 0xf1, 0x34, 0x34, 0xcc
	jr	nz, 9
	ld	a, (13449:16)
	cp	a, 182
	jr	z, 55
AccPlayback_InitTimingVars:
	ldb	a, 0
	ld	(13406:16), a
	ld	(13408:16), a
	ld	(13407:16), a
	ld	(13994:16), a
	ldw	(13995:16), 1
	calr	189
	call	16116102
	call	16120765
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	(13446:16), 0
AccPlayback_CheckStateFlags:
	.byte 0xc1, 0x33, 0x34, 0x3c, 0x7f, 0xc1, 0x34, 0x34, 0x3c, 0xfe
	ld	a, (13943:16)
	and	a, 192
	cps	a, 0
	jr	z, 23
	.byte 0xc1, 0x34, 0x34, 0x3e, 0x01
	calr	245
	calr	134
	call	16116102
	calr	291
AccPlayback_CheckSkipInit:
	.byte 0xc1, 0x1a, 0xe3, 0x3e, 0x10, 0xf1, 0x34, 0x34, 0xcc
	jr	nz, 15
	.byte 0xf1, 0x34, 0x34, 0xc8
	jr	nz, 9
	ld	a, (13449:16)
	cp	a, 182
	jr	z, 18
AccPlayback_ApplyChanges:
	.byte 0xc1, 0x34, 0x34, 0x3c, 0xdf	; anddi8 (0x34d0), 223 (v7 patched)

	.byte 0x1e, 0x71, 0x02	; calr AccPlayback_ProcessStyleChanges (v7 displacement)

	.byte 0xc1, 0x34, 0x34, 0x3c, 0xfe	; anddi8 (0x34d0), 254 (v7 patched)

	.byte 0xc1, 0x77, 0x36, 0x3c, 0x3f	; anddi8 (0x3713), 63 (v7 patched)



AccPlayback_CheckBit0_3:
	.byte 0xc1, 0x77, 0x36, 0x21, 0xc9, 0xcc, 0x03, 0xc9
	.byte 0xd8, 0x66, 0x08, 0x1e, 0x9f, 0x02, 0xc1, 0x77
	.byte 0x36, 0x3c, 0xfc
AccPlayback_ProcessMiscFlags:
	.byte 0xc1, 0x91, 0x36, 0x21, 0xc9, 0xcc, 0x3f, 0xc9
	.byte 0xd8, 0x66, 0x08, 0x1e, 0xd0, 0x11, 0xc1, 0x91
	.byte 0x36, 0x3c, 0xc0
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
	ld a, (0x345e:16)
	inc 1,A
	xor W,W
	ld (0x367e:16), wa
	calr ToneGen_StepFwd_Alternate
	jr t, AccTiming_ComputeOffset
	ldb A, 0x20
	cp (0x345f:16), 0x04
	jr c, AccTiming_StorePartA
AccTiming_StorePartA:
	ld	(13952:16), a
AccTiming_ComputeOffset:
	ld	w, (13407:16)
	ldb	a, 8
	muls8rr	a, w
	ld	h, a
	ld	a, (13408:16)
	xor	w, w
	ldb	l, 12
	div8rr	a, l
	add	h, a
	inc	1, h
	ld	a, (13406:16)
	subda8	a, 13994
	ldb	w, 32
	cp	(13373:16), 5
	jr	c, 2
	ldb	w, 64
AccTiming_UseFullBar:
	muls8rr	a, w
	add	h, a
	ld	(13939:16), h
	jr	12
	cp	h, 32
	jr	ule, 3
	sub	h, 32
AccTiming_StoreResult:
	ld	(13939:16), h
AccTiming_CompareStyles:
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, 0
AccTiming_Return:
	ret

__pad_F6152D:
	nop
	nop

AccPlayback_AdjustBeatPosition:
	.byte 0xd1, 0x7e, 0x36, 0x20, 0xc9, 0x69, 0xf1, 0x77
	.byte 0x36, 0xcf, 0x66, 0x0a, 0xc9, 0x61, 0xc1, 0x3b
	.byte 0x34, 0xf1, 0x63, 0x02, 0x21, 0x00
AccBeatAdj_CheckBit6:
	.byte 0xf1, 0x77, 0x36, 0xce, 0x66, 0x0b, 0xc9, 0x69
	.byte 0xc9, 0xcf, 0xff, 0x6e, 0x04, 0xc1, 0x3b, 0x34
	.byte 0x21
AccBeatAdj_StoreAndClear:
	ld	(13406:16), a
	ld	(13408:16), 0
	ld	(13407:16), 0
	ret
__pad_F61565:
	nop
	nop

AccVoice_InitPatternBuffer:
	ld XHL,0x00003692
	lds wa, 0
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
	muls8rr	a, w
	ld	c, a
	jr	29
	ld	a, (13406:16)
	ld	w, (13373:16)
	muls8rr	a, w
	ld	c, a
	cp	(13373:16), 5
	jr	c, 10
	cp	(13407:16), 4
	jr	c, 3
	add	c, 4
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
	ld	(13426:16), 0
	ld	c, (13986:16)
	calr	69
	inc	1, (13426:16)
	ld	c, (13987:16)
	calr	58
	inc	1, (13426:16)
	ld	c, (13988:16)
	calr	47
	inc	1, (13426:16)
	ld	c, (13989:16)
	calr	36
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, 5
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

__pad_F61634:
	nop
	nop

ToneGen_ParseEventBuffer:
	ld	(13427:16), 0
EventBuffer_ParseLoop:
	cps c, 0
	jr nz, EventBuffer_ReadByte
	jrl ToneGen_ParseEvent_Done

EventBuffer_ReadByte:
	ld	a, (xix)
	cp	a, 129
	jr	nz, 11
	dec	1, c
	inc	1, (13427:16)
	calr	5860
	jr	-25
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
	ld l, (13427:16)

	xor h, h

	ld a, (13426:16)

	and a, 0x3

	sla a, 2

	add l, a

	ld xix, 13970

	ldb_sri A, 0x07, 0xf0, 0xec

	or a, c

	stb_dri A, 0x07, 0xf0, 0xec

	pop xix

	popw bc

	.byte 0x1e, 0x65, 0x16	; calr ToneGen_ReadBufferWithIndirection (v7 displacement)

	.byte 0x78, 0x67, 0xff	; jrl EventBuffer_ParseLoop (v7 displacement)



ToneGen_ParseEvent_Done:
	ret

__pad_F616D5:
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
	ldb	a, 0
	ld	(13403:16), a
	ld	(13407:16), a
	ld	(13408:16), a
	ld	wa, (13950:16)
	dec	1, a
	ld	(13406:16), a
	call	16116102
	calr	64940
	calr	65101
	ret
AccStyleChange_CheckPartCount:
	nop
	nop

AccPlayback_ProcessPartChanges:
	.byte 0xc1, 0x86, 0x34, 0x3c, 0x73, 0xc1, 0x60, 0x34
	.byte 0x3f, 0x00, 0x6e, 0x05, 0xc1, 0x86, 0x34, 0x3e
	.byte 0x04
AccPartChange_Bit1:
	.byte 0xf1, 0x77, 0x36, 0xc8, 0x6e, 0x06, 0x1e, 0xf4
	.byte 0x00, 0x78, 0xc9, 0x00
AccPartChange_CheckBit2:
	.byte 0xf1, 0x34, 0x34, 0xcd, 0x66, 0x05, 0x1e, 0x6e
	.byte 0x03, 0x68, 0x07
AccPartChange_Done:
	call AccPatch_GetCurrentSlotAddr
	calr ToneGen_ProcessVoiceSlots

AccPartChange_ProcessBit2:
	calr ToneGen_CalcNoteWithWrap
	cp bc, wa
	jr ugt, AccPartChange_StoreResult
	jr __pad_F61760

AccPartChange_StoreResult:
	.byte 0xc1, 0x34, 0x34, 0x3c, 0xdf	; anddi8 (0x34d0), 223 (v7 patched)



ToneGen_CalcAndRestart:
	calr ToneGen_RecalcAndRestart
	jrl ToneGen_UpdateAndInitPattern

__pad_F61760:
	.byte 0xd1, 0xcf, 0x33, 0x20, 0xf1, 0x78, 0x34, 0x50
	.byte 0xd1, 0xad, 0x33, 0x20, 0xf1, 0x76, 0x34, 0x50
	.byte 0xc1, 0x34, 0x34, 0x3e, 0x20, 0xd1, 0xcf, 0x33
	.byte 0x23, 0x1e, 0x35, 0xfd, 0xd1, 0xad, 0x33, 0x20
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xc9, 0xcf, 0x81
	.byte 0x6e, 0x6b, 0x1e, 0xe1, 0x14, 0xd1, 0xcf, 0x33
	.byte 0x23, 0x1e, 0x1d, 0xfd, 0xd1, 0xad, 0x33, 0x20
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xc9, 0xcf, 0x90
	.byte 0x66, 0x25, 0xc9, 0xcf, 0x91, 0x66, 0x20, 0xc9
	.byte 0xcf, 0xd1, 0x66, 0x1b, 0xc9, 0xcf, 0xd2, 0x66
	.byte 0x16, 0xc9, 0xcf, 0xd3, 0x66, 0x11, 0xc9, 0xcf
	.byte 0xd4, 0x66, 0x0c, 0xc9, 0xcf, 0xd5, 0x66, 0x07
	.byte 0xc9, 0xcf, 0xd6, 0x66, 0x02, 0x68, 0x93
ToneGen_ProcessVoiceEvent:
	calr	5238
	cps	a, 0
	jr	nz, -116	; -> 0xF61356
	ld	wa, (13263:16)
	ld	(13432:16), wa
	ld	wa, (13229:16)
	ld	(13430:16), wa
	ld	hl, (13263:16)
	calr	64716
	ld	wa, (13229:16)
	ld_rrb	a, xhl, wa
	pushw	wa
	push	xhl
	calr	1000
	pop	xhl
	popw	wa
ToneGen_PushAndReadType:
	pushw	wa
	calr	5191
	ld	w, a
	ld	(13408:16), w
	popw	wa
	calr	1045
ToneGen_UpdateAndInitPattern:
	.byte 0xc1, 0x33, 0x34, 0x3c, 0x7f	; anddi8 (0x34cf), 127 (v7 patched)

	.byte 0x1e, 0xb8, 0xfc	; calr AccPlayback_CalcTimingPosition (v7 displacement)

	.byte 0x1d, 0x86, 0xe9, 0xf5	; call AccPatch_GetCurrentSlotAddr (v7 addr)

	.byte 0x1e, 0x55, 0xfd	; calr AccVoice_InitPatternBuffer (v7 displacement)

	.byte 0xc1, 0x1a, 0xe3, 0x3e, 0x10	; ordi8 0xe3e0, 16 (v7 patched)

	ret



ToneGen_VoiceSlotLookupTable:
	.byte 0x00, 0x00, 0x00, 0x94, 0x95, 0x00, 0x96, 0x00
	.byte 0x00, 0x00, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x98

ToneGen_ProcessWithRestore:
	.byte 0xf1, 0x34, 0x34, 0xcd, 0x66, 0x05, 0x1e, 0xcd
	.byte 0x00, 0x68, 0x0c
ToneGen_ProcessRestore_Direct:
	.byte 0x1d, 0x86, 0xe9, 0xf5	; call AccPatch_GetCurrentSlotAddr (v7 addr)

	.byte 0x1e, 0x53, 0x08	; calr ToneGen_ProcessVoiceSlots (v7 displacement)

	.byte 0xc1, 0x86, 0x34, 0x3c, 0xfe	; anddi8 (0x3522), 254 (v7 patched)



ToneGen_ProcessRestore_CalcPos:
	calr	473
	ld	bc, (13444:16)
	cp	bc, wa
	jr	c, 10
	sub	bc, wa
	cp	bc, 512
	jr	ugt, 2
	jr	53
ToneGen_ProcessRestore_CheckDelta:
	.byte 0xd9, 0xd8, 0x6e, 0x08, 0xf1, 0x86, 0x34, 0xcb
	.byte 0x66, 0x02, 0x68, 0x29
ToneGen_ProcessRestore_ClearBit5:
	.byte 0xc1, 0x34, 0x34, 0x3c, 0xdf	; anddi8 (0x34d0), 223 (v7 patched)



ToneGen_ProcessRestore_CalcNote:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ldb	l, 12
	div8rr	a, l
	cps	w, 0
	jr	nz, 2
	ldb	w, 12
ToneGen_ProcessRestore_AdjNote:
	calr	487
	ldb	a, 4
	ld	(13942:16), a
	ldb	w, 255
	ld	(13947:16), 255
	jr	114
ToneGen_ProcessRestore_UseSaved:
	.byte 0xf1, 0x86, 0x34, 0xc8, 0x6e, 0x1a, 0xd1, 0x7e
	.byte 0x34, 0x20, 0xf1, 0x78, 0x34, 0x50, 0xf1, 0xcf
	.byte 0x33, 0x50, 0xd1, 0x82, 0x34, 0x20, 0xf1, 0x76
	.byte 0x34, 0x50, 0xf1, 0xad, 0x33, 0x50, 0x68, 0x10
ToneGen_ProcessRestore_UseActive:
	ld	wa, (13263:16)
	ld	(13432:16), wa
	ld	wa, (13229:16)
	ld	(13430:16), wa
ToneGen_ProcessRestore_SetBit5:
	.byte 0xc1, 0x34, 0x34, 0x3e, 0x20, 0xd1, 0xcf, 0x33
	.byte 0x23, 0x1e, 0xe9, 0xfb, 0xc3, 0x07, 0xec, 0xe0
	.byte 0x21, 0xc9, 0xcf, 0x81, 0x6e, 0x12, 0xf1, 0x33
	.byte 0x34, 0xcf, 0x66, 0x0a, 0xc1, 0x34, 0x34, 0x3c
	.byte 0xdf, 0xc1, 0x33, 0x34, 0x3c, 0x7f
ToneGen_ProcessRestore_JumpCalc:
	jr ToneGen_ProcessRestore_CalcNote

ToneGen_ProcessRestore_ReadType:
	pushw	wa
	calr	4952
	ld	w, (13408:16)
	sub	w, a
	jr	nc, 3
	add	w, 96
ToneGen_ProcessRestore_WrapOctave:
	ld	e, (13408:16)
	calr	362
	popw	wa
	calr	794
ToneGen_ProcessRestore_Return:
	ret

__pad_F618FF:
	nop
	nop

ToneGen_RestoreFromSavedPos:
	.byte 0xd1, 0x76, 0x34, 0x25, 0xf1, 0xad, 0x33, 0x55
	.byte 0xd1, 0x78, 0x34, 0x20, 0xf1, 0xcf, 0x33, 0x50
	.byte 0x21, 0x00, 0xf1, 0x99, 0x33, 0x41, 0xc1, 0x86
	.byte 0x34, 0x3c, 0xfd, 0xd1, 0xcf, 0x33, 0x23, 0x1e
	.byte 0x8e, 0xfb, 0xd1, 0xad, 0x33, 0x20, 0xc3, 0x07
	.byte 0xec, 0xe0, 0x21, 0xc9, 0xcf, 0x81, 0x6e, 0x0a
	.byte 0xc1, 0x86, 0x34, 0x3e, 0x02, 0xc1, 0x86, 0x34
	.byte 0x3c, 0xfb
ToneGen_EventDispatchLoop:
	calr	5147
	ld	hl, (13263:16)
	calr	64364
	ld	wa, (13229:16)
	ld_rrb	a, xhl, wa
	bit	7, a
	jr	z, -24	; -> 0xF61537
	cp	a, 129
	jrl	z, 129	; -> 0xF615D6
	cp	a, 131
	jr	z, 42	; -> 0xF61584
	cp	a, 144
	jr	z, 64	; -> 0xF6159F
	cp	a, 145
	jr	z, 59	; -> 0xF6159F
	cp	a, 209
	jr	z, 54	; -> 0xF6159F
	cp	a, 210
	jr	z, 49	; -> 0xF6159F
	cp	a, 211
	jr	z, 44	; -> 0xF6159F
	cp	a, 212
	jr	z, 39	; -> 0xF6159F
	cp	a, 213
	jr	z, 34	; -> 0xF6159F
	cp	a, 214
	jr	z, 29	; -> 0xF6159F
	jr	-77	; -> 0xF61537
ToneGen_EventDisp_EndOfBlock:
	call	16116102
	calr	457
	ld	(13263:16), hl
	calr	64283
	lds	ix, 6
	ld	(13229:16), ix
	ld	(13209:16), 6
	jr	-104
ToneGen_CalcEventVelocity_WithFlags:
	.byte 0x1e, 0x9a, 0x12, 0xc9, 0x8b, 0xc1, 0x5f, 0x34
	.byte 0x22, 0xf1, 0x86, 0x34, 0xc9, 0x66, 0x26, 0xca
	.byte 0x69, 0xca, 0xcf, 0xff, 0x6e, 0x1f, 0xc1, 0x3d
	.byte 0x34, 0x22, 0xca, 0x69, 0xc1, 0x3d, 0x34, 0x21
	.byte 0xc1, 0x5e, 0x34, 0x20, 0xc8, 0x69, 0xc8, 0xcf
	.byte 0xff, 0x6e, 0x04, 0xc1, 0x3b, 0x34, 0x20
ToneGen_Velocity_Multiply:
	muls8rr a, w
	add b, a
	jr ToneGen_Velocity_Store

ToneGen_Velocity_SkipDec:
	jr VoiceVelocity_CalcDone

ToneGen_Velocity_HandleEnd:
	.byte 0xf1, 0x86, 0x34, 0xcf, 0x6e, 0x26, 0xf1, 0x86
	.byte 0x34, 0xca, 0x66, 0x0d, 0xc1, 0x86, 0x34, 0x3e
	.byte 0x02, 0xc1, 0x86, 0x34, 0x3e, 0x80, 0x78, 0x48
	.byte 0xff
ToneGen_Velocity_DefaultCalc:
	ldb	c, 0
	ld	b, (13407:16)
	dec	1, b
	cp	b, 255
	jr	nz, 6
	ld	b, (13373:16)
	dec	1, b
VoiceVelocity_CalcDone:
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls8rr	a, w
	add	b, a
ToneGen_Velocity_Store:
	.byte 0xf1, 0x84, 0x34, 0x51	; stda16 (0x3520), xbc (v7 patched)

	.byte 0xc1, 0x86, 0x34, 0x3e, 0x01	; ordi8 0x3522, 1 (v7 patched)

	ret



__pad_F61A1C:
	nop
	nop

ToneGen_CalcNotePosition:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ldb	l, 12
	div8rr	a, l
	ld	d, (13407:16)
	ld	bc, wa
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls8rr	a, w
	add	d, a
	ld	wa, bc
	cps	w, 0
	jr	nz, 2
	ldb	w, 12
ToneGen_CalcPos_SubOctave:
	.byte 0xcd, 0x89, 0xc8, 0xa1, 0x6f, 0x15, 0xc9, 0xc8
	.byte 0x60, 0xcc, 0x69, 0xcc, 0xcf, 0xff, 0x6e, 0x0b
	.byte 0xc1, 0x3d, 0x34, 0x24, 0xcc, 0x69, 0xc1, 0x86
	.byte 0x34, 0x3e, 0x08
ToneGen_CalcPos_Return:
	ld w, d
	ret

__pad_F61A62:
	nop
	nop

ToneGen_AdjustNoteWrap:
	ld	a, e
	sub	a, w
	jr	c, 6
	ld	(13408:16), a
	jr	62
ToneGen_AdjWrap_AddOctave:
	add	a, 96
	ld	(13408:16), a
	ld	a, (13407:16)
	dec	1, a
	cp	a, 255
	jr	z, 6
	ld	(13407:16), a
	jr	38
ToneGen_AdjWrap_WrapBar:
	ld	a, (13373:16)
	dec	1, a
	ld	(13407:16), a
	ld	a, (13406:16)
	dec	1, a
	cp	a, 255
	jr	z, 6
	ld	(13406:16), a
	jr	11
ToneGen_AdjWrap_WrapMeasure:
	ld	a, (13371:16)
	and	a, 7
	ld	(13406:16), a
SustainLevel_SetExit:
	ret

__pad_F61AAF:
	nop
	nop

ToneGen_ScanRestoredVoiceEvents:
	ld	iy, (13430:16)
	ld	(13229:16), iy
	ld	wa, (13432:16)
	ld	(13263:16), wa
	ldb	a, 0
	ld	(13209:16), a
ToneGen_ScanRestored_Loop:
	calr	4516
	ld	hl, (13263:16)
	calr	63968
	ld	wa, (13229:16)
	ld_rrb	a, xhl, wa
	cp	a, 129
	jrl	z, 97	; -> 0xF6173D
	cp	a, 131
	jr	z, 42	; -> 0xF6170B
	cp	a, 144
	jr	z, 64	; -> 0xF61726
	cp	a, 145
	jr	z, 59	; -> 0xF61726
	cp	a, 209
	jr	z, 54	; -> 0xF61726
	cp	a, 210
	jr	z, 49	; -> 0xF61726
	cp	a, 211
	jr	z, 44	; -> 0xF61726
	cp	a, 212
	jr	z, 39	; -> 0xF61726
	cp	a, 213
	jr	z, 34	; -> 0xF61726
	cp	a, 214
	jr	z, 29	; -> 0xF61726
	jr	-72	; -> 0xF616C3
ToneGen_ScanRestored_EndBlock:
	call	16116102
	calr	66
	ld	(13263:16), hl
	calr	63892
	lds	ix, 6
	ld	(13229:16), ix
	ld	(13209:16), 6
	jr	-99
ToneGen_CalcEventVelocity_Restored:
	calr	4371
	ld	c, a
	ld	b, (13407:16)
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls8rr	a, w
	add	b, a
	jr	20
ToneGen_ScanRestored_EndMarker:
	ldb	c, 0
	ld	b, (13407:16)
	inc	1, b
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls8rr	a, w
	add	b, a
ToneGen_ScanRestored_Return:
	ret

__pad_F61B56:
	nop
	nop

ToneGen_GetSlotIndex:
	ld	a, (14079:16)
	and	a, 31
	cps	a, 0
	jr	nz, 7
	or	a, 16
	ld	(14079:16), a
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
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ldb	l, 12
	div8rr	a, l
	ld	a, e
	sub	a, w
	add	a, 12
	ld	w, (13407:16)
	cp	a, 96
	jr	nz, 4
	ldb	a, 0
	inc	1, w
ToneGen_CalcWrap_Store:
	ld	hl, wa
	ld	a, (13373:16)
	ld	w, (13406:16)
	muls8rr	a, w
	add	h, a
	ld	wa, hl
	ret
__pad_F61BAB:
	nop
	nop

ToneGen_RecalcAndRestart:
	ld	a, (13408:16)
	ld	e, a
	xor	w, w
	ldb	l, 12
	div8rr	a, l
	ld	a, e
	sub	a, w
	add	a, 12
	calr	13
	ld	(13942:16), 4
	ld	(13947:16), 255
	ret
__pad_F61BCE:
	nop
	nop

ToneGen_StoreNoteOrWrap:
	cp	a, 96
	jr	z, 6
	ld	(13408:16), a
	jr	58
ToneGen_AdvancePeriodWrap:
	ld	(13408:16), 0
	ld	a, (13407:16)
	inc	1, a
	cp	a, (13373:16)
	jr	z, 6
	ld	(13407:16), a
	jr	35
ToneGen_PeriodWrap_NextBar:
	ld	(13407:16), 0
	ld	a, (13406:16)
	inc	1, a
	ld	w, (13371:16)
	and	w, 7
	inc	1, w
	cp	a, w
	jr	z, 6
	ld	(13406:16), a
	jr	5
ToneGen_PeriodWrap_ResetBar:
	ld	(13406:16), 0
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
	ldb A, 0x05
	ld (0x3676:16), a
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ldb_dri a, 0x07, 0xec, 0xe0
	ldb E, 0x01
	cp A,0xd2
	jr z, .Lc_f61878
	ldb E, 0x02
	cp A,0xd1
	jr z, .Lc_f61878
	ldb E, 0x03
	cp A,0xd3
	jr z, .Lc_f61878
	ldb E, 0x04
	cp A,0xd4
	jr z, .Lc_f61878
	ldb E, 0x05
	cp A,0xd5
	jr z, .Lc_f61878
	ldb E, 0x06
ToneGen_ClassifyStereoSlot_Common:
.Lc_f61878:
	ld (0x3684:16), e
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ldb_dri a, 0x07, 0xec, 0xe0
	ld (0x3685:16), a
	ret
__pad_F61C98:
	nop
	nop

ToneGen_ClassifyMonoEvent:
	ldb A, 0x04
	ld (0x3676:16), a
	calr ToneGen_StepToNextStereoSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ldb_dri a, 0x07, 0xec, 0xe0
	ld (0x367c:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ldb_dri w, 0x07, 0xec, 0xe0
	ld (0x367b:16), w
	ld a, (0x367c:16)
	ld DE,WA
	ld a, (0x36ff:16)
	and A,0x1f
	cps a, 0
	jr nz, .Lc_f618e2
	or A,0x10
	ld (0x36ff:16), a
ToneGen_ClassifyMono_MapChannel:
.Lc_f618e2:
	ld L,A
	xor H,H
	ld XIY,ToneGen_VoiceSlotLookupTable_0x2
	ldb_dri a, 0x07, 0xf4, 0xec
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
	ldb A, 0x00
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
	ldb A, 0x10
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
	lds wa, 1
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

__pad_F61D76:
	nop
	nop

AccPlayback_ReadEventLoop:
	and (0x3434:16), 0x7f
AccPlayback_ReadEvt_CheckEmpty:
	call AccPatch_CheckEmpty
	cps wa, 0
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
	.byte 0xf1, 0x34, 0x34, 0xcf, 0x66, 0x67, 0xd1, 0x38
	.byte 0x34, 0x3f, 0x00, 0x00, 0x6e, 0x1c, 0xf1, 0xa6
	.byte 0x7e, 0x00, 0x0f, 0xf1, 0x16, 0xe3, 0x00, 0xee
	.byte 0xf1, 0x18, 0xe3, 0x00, 0x40, 0xc1, 0x34, 0x34
	.byte 0x3c, 0x7f, 0x21, 0x08, 0x1d, 0xd2, 0xb5, 0xfe
	.byte 0x68, 0x43
AccPlayback_ReadEvt_HasEntries:
	.byte 0xc1, 0x34, 0x34, 0x3c, 0xdf, 0x1e, 0x6b, 0x07
	.byte 0xf1, 0xff, 0x36, 0xcc, 0x66, 0x05, 0x1e, 0xaa
	.byte 0x00, 0x68, 0x03
AccPlayback_ReadEvt_Overflow:
	calr AccPlayback_AdvPattern_Loop

AccPlayback_ReadEvt_OverflowOK:
	call	16116102
	calr	596
	calr	2045
	calr	-2339
	call	16116102
	calr	-2182
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	a, (35994:16)
	cp	a, (35996:16)
	jr	nz, 5
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
	cps l, 5
	jr ugt, AccPlayback_NoteOn_Store
	xor H,H
	ld XIY,0x00003464
	ld a, (0x3391:16)
	stb_dri a, 0x07, 0xf4, 0xec
	ld a, (0x3392:16)
	pushw hl
	add HL,0x0006
	stb_dri a, 0x07, 0xf4, 0xec
	popw hl
	inc 1,L
	ld (0x3461:16), l
	cp l, (0x3462:16)
	jr ule, AccPlayback_NoteOn_Store
	ld (0x3462:16), l
AccPlayback_NoteOn_Store:
	jr TimeoutCounter_CheckExit

AccPlayback_NoteOn_WriteVoice:
	.byte 0xc1, 0x61, 0x34, 0x21, 0xc9, 0x69, 0xc9, 0xcf
	.byte 0xff, 0x66, 0x0d, 0xf1, 0x61, 0x34, 0x41, 0xc9
	.byte 0xd8, 0x6e, 0x05, 0xc1, 0x34, 0x34, 0x3e, 0x80
TimeoutCounter_CheckExit:
	ret

AccPlayback_NoteOn_SetBit:
	nop
	nop

AccPlayback_NoteOn_Check91:
	lds	wa, 0
	ld	(13678:16), wa
	ld	e, (13410:16)
	xor	h, h
	ld	xix, 13412
	ld	xiy, 13774
AccPlayback_NoteOn_WritePan:
	.byte 0xcd, 0xd8, 0x66, 0x16, 0xcd, 0x8f, 0xcf, 0x69
	.byte 0xd1, 0x6e, 0x35, 0x38, 0x06, 0x00, 0xb5, 0x00
	.byte 0x90, 0xed, 0x61, 0x1e, 0x07, 0x00, 0xcd, 0x69
	.byte 0x68, 0xe6
AccPlayback_NoteOn_Return:
	ret

__pad_F61EAF:
	nop
	nop

ToneGen_WriteVoiceEventEntry:
	ld a, (13408:16)

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
	lds	wa, 0
	ld	(13678:16), wa
	ld	e, (13410:16)
	xor	h, h
	ld	xix, 13412
	ld	xiy, 13774
AccPlayback_AdvPattern_Check81:
	.byte 0xcd, 0xd8, 0x66, 0x3f, 0xcd, 0x8f, 0xcf, 0x69
	.byte 0x1e, 0x3b, 0x00, 0xf1, 0x95, 0x33, 0xc8, 0x6e
	.byte 0x10, 0xd1, 0x6e, 0x35, 0x38, 0x06, 0x00, 0xb5
	.byte 0x00, 0x90, 0xed, 0x61, 0x1e, 0x98, 0xff, 0x68
	.byte 0x1e
AccPlayback_AdvPattern_Check90:
	.byte 0xd1, 0x6e, 0x35, 0x38, 0x08, 0x00	; adddi16 0x360a, 8 (v7 patched)

	ld (xiy), 0x91

	inc 1, xiy

	.byte 0x1e, 0x88, 0xff	; calr ToneGen_WriteVoiceEventEntry (v7 displacement)

	.byte 0xc1, 0x96, 0x33, 0x21	; ldb_d8 a, (0x3432) (v7 patched)

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

__pad_F61F3E:
	nop
	nop

AccPlayback_AdvanceRingBuffer:
	.byte 0xc1, 0x4d, 0x34, 0x21, 0xc9, 0xcc, 0x0f, 0xc9
	.byte 0xd8, 0x66, 0x23, 0x1d, 0x35, 0x05, 0xf6, 0xc1
	.byte 0xb2, 0x39, 0xf1, 0x6b, 0x10, 0xc3, 0x07, 0xf0
	.byte 0xec, 0xa9, 0x6f, 0x07, 0x21, 0x0c, 0xc3, 0x07
	.byte 0xf0, 0xec, 0x89
AccPlayback_AdvRingBuf_Return:
	jr AccPlayback_TrackPosition

__pad_F61F65:
	ldb w, 0xc
	sub w, a
	add_srib_mr W, 0x07, 0xf0, 0xec

AccPlayback_TrackPosition:
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21, 0x3c, 0xc8, 0xd0
	.byte 0x44, 0x42, 0x61, 0xe4, 0x00, 0xc3, 0x07, 0xf0
	.byte 0xe0, 0x21, 0x5c, 0xf1, 0x4e, 0x34, 0xcc, 0x66
	.byte 0x25, 0xc9, 0x8b, 0x3c, 0xc8, 0xd0, 0x44, 0x00
	.byte 0x1c, 0xf6, 0x00, 0xc3, 0x07, 0xf0, 0xe0, 0x21
	.byte 0x5c, 0xc9, 0x33, 0x00, 0x66, 0x0e, 0xcb, 0x61
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xc9, 0x61, 0xf3
	.byte 0x07, 0xf0, 0xec, 0x41
AccPlayback_TrackPos_Return:
	ld a, c

__pad_F61FAC:
	.byte 0xf1, 0x4e, 0x34, 0xce, 0x66, 0x08, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x66, 0x02, 0x68, 0x0c
AccPlayback_TrackPos_WrapCheck:
	.byte 0xf1, 0x4e, 0x34, 0xcd, 0x66, 0x1b, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x6e, 0x15
AccPlayback_TrackPos_WrapDone:
	cps	a, 7
	jr	nz, 17
	ld	(13205:16), 1
	ld	(13206:16), 3
	ld	(13207:16), 0
	jr	38
ToneGen_LoadRhythmPatternParams:
	xor	xbc, xbc
	ld	c, a
	sla	a, 1
	add	c, a
	push	xix
	ld	xix, 16129036
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

__pad_F62002:
	nop
	nop
	nop
	nop
	nop
	normal
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
	normal
	nop
	scf
	normal
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
	normal
	scf
	scf
AccPlayback_ProcessOngoingEvents:
	.byte 0x8d, 0x0f, 0x3c, 0x7f
	calr	85
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
	call	16123607
	calr	350
	ld	(13410:16), 0
	.byte 0xf1, 0xe7, 0x31, 0xc8
	jr	nz, 26
	cp	(13406:16), 0
	jr	nz, 19
	cp	(13407:16), 0
	jr	nz, 12
	cp	(13408:16), 48
	jr	ugt, 5
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80
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
	.byte 0xc8, 0x49, 0xc9, 0x8c, 0xc1, 0x5f, 0x34, 0x21
	.byte 0xc9, 0x84, 0xc1, 0x60, 0x34, 0x25, 0xc1, 0x58
	.byte 0x32, 0x3c, 0xfe, 0xd9, 0xd1, 0xf1, 0x99, 0x33
	.byte 0x00, 0x06
AccPlayback_Ongoing_NoteOff:
	bit 0, (0x3258:16)
	jr z, .Lc_f61cca
	jrl t, AccPlayback_Ongoing_Return
AccPlayback_Ongoing_NoteOffDone:
.Lc_f61cca:
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
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
	calr	2885
	ld	c, a
	cp	de, bc
	jr	ule, 95
	calr	163
	ld	hl, (13263:16)
	calr	-3162
	ld_rrb	a, xhl, iy
	cp	a, 144
	jr	nz, 11
	calr	2994
	calr	2991
	calr	2988
	jr	69
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
	.byte 0xc1, 0x58, 0x32, 0x3e, 0x01	; ordi8 0x32f4, 1 (v7 patched)



ToneGen_StepVoiceReturn:
	jrl AccPlayback_Ongoing_NoteOff

AccPlayback_Ongoing_Return:
	ret

__pad_F62169:
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
	calr	62253
	ld	a, (13440:16)
	xor	w, w
	ld	(13442:16), wa
	ld	a, (13371:16)
	inc	1, a
	ld	w, (13373:16)
	muls8rr	a, w
	dec	1, a
	ld	b, a
	xor	c, c
	ld	(13444:16), bc
	ret
AccPlayback_Ongoing_AdvDone:
	nop
	nop

__pad_F621A7:
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
	.byte 0xd1, 0xab, 0x33, 0xf0, 0x66, 0x09, 0xd1, 0xa5
	.byte 0x33, 0x22, 0x1e, 0xde, 0x00, 0x68, 0x0f
AccPlayback_VoiceState_NoChange:
	.byte 0xd1, 0xa5, 0x33, 0x22, 0xd1, 0xa9, 0x33, 0xf2
	.byte 0x67, 0x05, 0xc1, 0x34, 0x34, 0x3e, 0x40
AccPlayback_VoiceState_Changed:
	.byte 0xf1, 0x34, 0x34, 0xce, 0x66, 0x3c, 0xd1, 0xaf
	.byte 0x33, 0x20, 0xd8, 0x82, 0xda, 0xcf, 0xff, 0x00
	.byte 0x6f, 0x12, 0xd1, 0xa5, 0x33, 0x24, 0xd1, 0xaf
	.byte 0x33, 0x20, 0xd8, 0x84, 0xe1, 0xb0, 0x34, 0x23
	.byte 0xb3, 0x54, 0x68, 0x1e
AccPlayback_VoiceState_CalcOff:
	ld	hl, (13464:16)
	calr	62105
	ld	hl, (xhl+3)
	ld	xix, (13484:16)
	ld	(xix), hl
	lds	ix, 6
	sub	de, 255
	add	ix, de
	ld	xhl, (13488:16)
	ld	(xhl), ix
AccPlayback_VoiceState_Return:
	ret

__pad_F62230:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x32
	.byte 0x00, 0x00, 0x03, 0x32, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x05, 0x32, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xff, 0x31, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xfb, 0x31, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0xf1, 0x31, 0x00, 0x00, 0xf3, 0x31
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf5, 0x31
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xef, 0x31
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xeb, 0x31
	.byte 0x00, 0x00
ToneGen_SearchVoiceBuffer:
	call	16116102
	ld	a, (14079:16)
	and	a, 31
	cps	a, 0
	jr	nz, 7
	or	a, 16
	ld	(14079:16), a
ToneGen_SearchBuf_MapChannel:
	call MapBitFlagsToChannelOffset
	ld l, w
	xor h, h
	ldw_sri WA, 0x07, 0xf4, 0xec

ToneGen_SearchBuf_CompareLoop:
	.byte 0xd1, 0xab, 0x33, 0xf0, 0x6e, 0x07, 0xc1, 0x34
	.byte 0x34, 0x3e, 0x40, 0x68, 0x12
ToneGen_SearchBuf_CheckEnd:
	.byte 0xd1, 0x98, 0x34, 0xf0, 0x6e, 0x02, 0x68, 0x0a
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
	.byte 0xc3, 0x07, 0xec, 0xf4, 0x21, 0xc9, 0xcf, 0x81
	.byte 0x76, 0x7b, 0x00, 0xf1, 0xb1, 0x33, 0x00, 0x06
	.byte 0xc9, 0xcf, 0x90, 0x66, 0x32, 0xf1, 0xb1, 0x33
	.byte 0x00, 0x08, 0xc9, 0xcf, 0x91, 0x66, 0x25, 0xf1
	.byte 0xb1, 0x33, 0x00, 0x03, 0xc9, 0xcf, 0xd1, 0x66
	.byte 0x24, 0xc9, 0xcf, 0xd2, 0x66, 0x1f, 0xc9, 0xcf
	.byte 0xd3, 0x66, 0x1a, 0xc9, 0xcf, 0xd4, 0x66, 0x15
	.byte 0xc9, 0xcf, 0xd5, 0x66, 0x10, 0xc9, 0xcf, 0xd6
	.byte 0x66, 0x0b, 0x68, 0x42
AccBit5_StepOnce:
	calr ToneGen_StepToNextStereoSlot

AccBit5_StepTwice:
	calr ToneGen_StepToNextStereoSlot
	calr ToneGen_StepToNextVoiceSlot

AccVoice_InitPlaybackState:
	calr	2350
	calr	2255
	ld	wa, (13263:16)
	ld	(13756:16), wa
	ld	(13462:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13762:16), wa
	calr	34
	call	16121850
	call	16116102
	calr	61860
	ld	(13942:16), 4
	ld	(13947:16), 255
	ld	(58138:16), 16
FlagClear_Exit:
	.byte 0xc1, 0x77, 0x36, 0x3c, 0xdf	; anddi8 (0x3713), 223 (v7 patched)



AccBit5_Return:
	ret

__pad_F623D8:
	nop
	nop

ToneGen_ScanVoicePosition:
	calr	189
	call	16116102
	calr	63348
	ld	de, hl
	calr	61640
	ldb	c, 3
	lds	iy, 3
	ld	(13447:16), 0
ToneGen_ScanPos_CompareLoop:
	.byte 0xd1, 0xaf, 0x33, 0xf5, 0x6e, 0x0d, 0xd1, 0x94
	.byte 0x34, 0xf2, 0x6e, 0x07, 0xc1, 0x87, 0x34, 0x3e
	.byte 0x01, 0x68, 0x11
ToneGen_ScanPos_CheckEnd:
	.byte 0xd1, 0xad, 0x33, 0xf5, 0x6e, 0x0b, 0xd1, 0x96
	.byte 0x34, 0xf2, 0x6e, 0x05, 0xc1, 0x87, 0x34, 0x3e
	.byte 0x02
VoiceState_CheckExit:
	.byte 0xd1, 0xa5, 0x33, 0xf5, 0x6e, 0x08, 0xd1, 0x98
	.byte 0x34, 0xf2, 0x6e, 0x02, 0x68, 0x05
ToneGen_ScanPos_AdvanceStep:
	calr ToneGen_AdvanceVoiceStep
	jr ToneGen_ScanPos_CompareLoop

ToneGen_ScanPos_ProcessFlags:
	.byte 0xc1, 0x87, 0x34, 0x21, 0xc9, 0xcc, 0x03, 0xc9
	.byte 0xd8, 0x66, 0x63, 0xf1, 0x87, 0x34, 0xc9, 0x6e
	.byte 0x16, 0xd1, 0xaf, 0x33, 0x25, 0xe1, 0xb0, 0x34
	.byte 0x24, 0xb4, 0x55, 0xe1, 0xac, 0x34, 0x24, 0xb4
	.byte 0x52, 0xf1, 0x99, 0x33, 0x43, 0x68, 0x47
ToneGen_ScanPos_AdjustBit1:
	ld	iy, (13233:16)
	and	iy, 255
	ld	wa, iy
	sub	c, a
	jr	c, 26
	cps	c, 6
	jr	c, 22
	ld	(13209:16), c
	ld	xix, (13488:16)
	ld	wa, (xix)
	sub	wa, iy
	ld	(xix), wa
	ld	xix, (13484:16)
	ld	(xix), de
	jr	31
ToneGen_ScanPos_WrapBlock:
	sub	c, 7
	ld	(13209:16), c
	ld	hl, de
	calr	61485
	ld	wa, (xhl+1)
	ld	xix, (13484:16)
	ld	(xix), wa
	xor	w, w
	ld	a, c
	ld	xix, (13488:16)
	ld	(xix), iy
PlaybackState_InitDone:
	ret

__pad_F62498:
	nop
	nop

ToneGen_InitPlaybackState:
	and (0x3434:16), 0xbf
	ld a, (0x36ff:16)
	and A,0x1f
	cps a, 0
	jr nz, .Lc_f620ad
	or A,0x10
	ld (0x36ff:16), a
ToneGen_InitPlay_SetupTables:
.Lc_f620ad:
	sla A, 0x02
	ld L,A
	xor H,H
	ld XIX,__pad_F62230_0x2
	ld_rrl	xix, xix, hl
	ld	(13484:16), xix
	ld	xix, 16129650
	ld_rrl	xix, xix, hl
	ld	(13488:16), xix
	ld	hl, (xix)
	ld	(13221:16), hl
	ld	xix, (13484:16)
	ld	hl, (xix)
	ld	(13464:16), hl
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

__pad_F62534:
	nop
	nop

ToneGen_CalcTempo:
	ld	l, (13944:16)
	cps	l, 0
	jr	nz, 2
	ldb	l, 6
ToneGen_CalcTempo_Lookup:
	sla	l, 1
	xor	h, h
	push	xix
	ld	xix, 16130496
	ld_rrw	de, xix, hl
	ld	l, (13945:16)
	sla	l, 1
	ld_rrw	bc, xix, hl
	add	de, bc
	pop	xix
	ld	wa, de
	ldb	l, 96
	div8rr	a, l
	ld	(13203:16), w
	ld	(13204:16), a
	ld	a, (13946:16)
	cps	a, 1
	jr	nz, 16	; -> 0xF62181
	sla	de, 2
	ld	wa, de
	xor	de, de
	lds	hl, 5
	ld	qwa, de
	div	xwa, xhl
	jr	43	; -> 0xF621AC
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
	.byte 0x27, 0x60, 0xcf, 0x51, 0xf1, 0x91, 0x33, 0x40
	.byte 0xf1, 0x92, 0x33, 0x41, 0xc1, 0x33, 0x34, 0x3e
	.byte 0x80, 0x0e
ToneGen_CalcTempo_DataTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x0c, 0x00
	.byte 0x10, 0x00, 0x18, 0x00, 0x20, 0x00, 0x30, 0x00
	.byte 0x40, 0x00, 0x60, 0x00, 0xc0, 0x00, 0x80, 0x01
	.byte 0x00, 0x03, 0x80, 0x04, 0x00, 0x06

ToneGen_AdvanceByTempo:
	ld	a, (13203:16)
	ld	w, (13204:16)
	addda8	a, (13408)
	cp	a, 96
	jr	c, 5
	sub	a, 96
	inc	1, w
ToneGen_AdvTempo_StoreNote:
	ld	(13408:16), a
	addda8	w, (13407)
	ld	l, (13373:16)
	ld	h, (13371:16)
	and	h, 7
	inc	1, h
ToneGen_AdvTempo_WrapLoop:
	cp	w, l
	jr	c, 19	; -> 0xF6221E
	sub	w, l
	inc	1, (13406:16)
	cp	h, (13406:16)
	jr	nz, 5	; -> 0xF6221C
	ld	(13406:16), 0
ToneGen_AdvTempo_Continue:
	jr ToneGen_AdvTempo_WrapLoop

ToneGen_AdvTempo_StoreBeat:
	ld	(13407:16), w
	ret
__pad_F62627:
	nop
	nop

AccPlayback_UpdateRhythmSustain:
	ld	a, (13436:16)
	cps	a, 0
	jr	z, 45
	dec	1, a
	ld	(13436:16), a
	cps	a, 0
	jr	nz, 35
	ld	a, (13434:16)
	ld	e, (13435:16)
	ldb	d, 0
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

__pad_F6265F:
	nop
	nop

AccPlayback_ProcessVoiceType5:
	.byte 0xf1, 0x34, 0x34, 0xcd, 0x66, 0x23, 0xc1, 0x76
	.byte 0x36, 0x3f, 0x04, 0x6e, 0x1c, 0xc1, 0x91, 0x36
	.byte 0x21, 0xc9, 0xcc, 0x0c, 0xc9, 0xd8, 0x66, 0x03
	.byte 0x1e, 0x2c, 0x00
AccVoiceType5_CheckBit01:
	ld	a, (13969:16)
	and	a, 3
	cps	a, 0
	jr	z, 3
	calr	238
AccVoice_DispatchType5Handler:
	.byte 0xf1, 0x34, 0x34, 0xcd, 0x66, 0x15, 0xc1, 0x76
	.byte 0x36, 0x3f, 0x05, 0x6e, 0x0e, 0xc1, 0x91, 0x36
	.byte 0x21, 0xc9, 0xcc, 0x30, 0xc9, 0xd8, 0x66, 0x03
	.byte 0x1e, 0x51, 0x01
TempoCheck_Exit:
	ret

__pad_F626A6:
	nop
	nop

ToneGen_AdjustVoiceVelocity:
	.byte 0xd1, 0x76, 0x34, 0x20, 0xf1, 0xad, 0x33, 0x50
	.byte 0xd1, 0x78, 0x34, 0x20, 0xf1, 0xcf, 0x33, 0x50
	.byte 0xf1, 0x99, 0x33, 0x00, 0x00, 0xd1, 0xcf, 0x33
	.byte 0x23, 0x1e, 0xed, 0xed, 0xd1, 0xad, 0x33, 0x20
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xc9, 0xcf, 0x81
	.byte 0x76, 0xa2, 0x00, 0x1e, 0x98, 0x05, 0x1e, 0x95
	.byte 0x05, 0xd1, 0xcf, 0x33, 0x23, 0x1e, 0xd1, 0xed
	.byte 0xd1, 0xad, 0x33, 0x20, 0xc3, 0x07, 0xec, 0xe0
	.byte 0x21, 0xf1, 0xff, 0x36, 0xcc, 0x66, 0x1e, 0xc1
	.byte 0xbe, 0xfb, 0x20, 0x38, 0x39, 0x3a, 0x3c, 0x3d
	.byte 0xcc, 0xd4, 0xc9, 0x8d, 0xc8, 0x8b, 0xca, 0xd2
	.byte 0xd8, 0xa9, 0x1d, 0x0d, 0xe4, 0xfe, 0x5d, 0x5c
	.byte 0x5a, 0x59, 0x58, 0xcf, 0x89
ToneGen_AdjVel_CheckBit2:
	.byte 0xf1, 0x91, 0x36, 0xca, 0x66, 0x0b, 0xc9, 0x61
	.byte 0xc9, 0xcf, 0x80, 0x67, 0x02, 0x21, 0x7f
ToneGen_AdjVel_ClampHigh:
	jr ToneGen_AdjVel_StoreAndParam

ToneGen_AdjVel_Decrement:
	dec 1, a
	cp a, 0xff
	jr nz, ToneGen_AdjVel_StoreAndParam
	ldb a, 0x0

ToneGen_AdjVel_StoreAndParam:
	.byte 0xc9, 0x8d, 0xf1, 0xff, 0x36, 0xcc, 0x66, 0x1c
	.byte 0xc1, 0xbe, 0xfb, 0x20, 0x38, 0x39, 0x3a, 0x3c
	.byte 0x3d, 0xd9, 0xd1, 0xc8, 0x8b, 0xd8, 0xaa, 0xcc
	.byte 0xd4, 0x1d, 0x0d, 0xe4, 0xfe, 0x5d, 0x5c, 0x5a
	.byte 0x59, 0x58, 0xcf, 0x89
ToneGen_AdjVel_WriteToBuffer:
	ld	hl, (13263:16)
	calr	60767
	pushw	ix
	ld	ix, (13229:16)
	st_rrb	a, xhl, ix
	ld	(13948:16), e
	popw	ix
	push	xde
	call	AccScreen_DrawInit_StackWrap
	pop	xde
	ld	a, (14079:16)
	and	a, 15
	cps	a, 0
	jr	z, 3	; -> 0xF62371
	calr	529
ToneGen_AdjVel_Return:
	ret

__pad_F62776:
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
	ldb_dri a, 0x07, 0xec, 0xe0
	cp A,0x81
	jr z, ToneGen_AdjVol_Return
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ld wa, (0x33ad:16)
	ldb_dri a, 0x07, 0xec, 0xe0
	bit 0, (0x3691:16)
	jr z, ToneGen_AdjVol_Decrement
	inc 1,A
	cp A,0x80
	jr c, ToneGen_AdjVol_ClampHigh
	ldb A, 0x7f
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
	ld	hl, (13263:16)
	calr	-4911
	pushw	ix
	ld	ix, (13229:16)
	st_rrb	a, xhl, ix
	ld	(13947:16), a
	popw	ix
	call	16164196
ToneGen_AdjVol_Return:
	ret

__pad_F627F4:
	nop
	nop

ToneGen_ProcessStereoType:
	.byte 0xd1, 0x76, 0x34, 0x20, 0xf1, 0xad, 0x33, 0x50
	.byte 0xd1, 0x78, 0x34, 0x20, 0xf1, 0xcf, 0x33, 0x50
	.byte 0xf1, 0x99, 0x33, 0x00, 0x00, 0xd1, 0xcf, 0x33
	.byte 0x23, 0x1e, 0x9f, 0xec, 0xd1, 0xad, 0x33, 0x20
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xc9, 0xcf, 0x81
	.byte 0x66, 0x6d, 0xd1, 0xcf, 0x33, 0x23, 0x1e, 0x8a
	.byte 0xec, 0xd1, 0xad, 0x33, 0x20, 0xc3, 0x07, 0xec
	.byte 0xe0, 0x23, 0x1e, 0x3b, 0x04, 0x1e, 0x38, 0x04
	.byte 0xd1, 0xcf, 0x33, 0x23, 0x1e, 0x74, 0xec, 0xd1
	.byte 0xad, 0x33, 0x20, 0xc3, 0x07, 0xec, 0xe0, 0x21
	.byte 0xcb, 0xcf, 0xd3, 0x66, 0x1c, 0xf1, 0x91, 0x36
	.byte 0xcc, 0x66, 0x0b, 0xc9, 0x61, 0xc9, 0xcf, 0x80
	.byte 0x67, 0x02, 0x21, 0x7f
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
	.byte 0xf1, 0x91, 0x36, 0xcc, 0x66, 0x04, 0x21, 0x7f
	.byte 0x68, 0x02
ToneGen_Stereo_Store:
	ldb a, 0x0

ToneGen_Stereo_WriteParam:
	ld	hl, (13263:16)
	calr	-5065
	pushw	ix
	ld	ix, (13229:16)
	st_rrb	a, xhl, ix
	ld	(13957:16), a
	popw	ix
	call	16164219
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
	ldio	59, 60
	ld	xwa, 0x4906053f
	max
	.ascii "JHmnopqrstuvwxyz{|}~"
	jrl	nc, 14
	nop
	.ascii "b_]^XYZ[\\NOPQRSTKHI=>?@('*,.$%&"
	.byte 0x1f
	.ascii " )!+\"-#/0123456789:cd;<feABCDEJ`likMLUVW"
	jp	0x09121d
	ldwio	11, 3340
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
	.byte 0xd1, 0xcf, 0x33, 0x23, 0x1e, 0x24, 0xeb, 0xd1
	.byte 0x76, 0x34, 0x25, 0xc3, 0x07, 0xec, 0xf4, 0x24
	.byte 0xce, 0xd6, 0xcd, 0x8f, 0x3c, 0x44, 0x42, 0x61
	.byte 0xe4, 0x00, 0xc3, 0x07, 0xf0, 0xec, 0x21, 0x5c
	.byte 0x25, 0x90, 0xf1, 0x4e, 0x34, 0xce, 0x66, 0x08
	.byte 0xf1, 0xff, 0x36, 0xcb, 0x66, 0x02, 0x68, 0x0c
ToneGen_MultiChan_Compare:
	.byte 0xf1, 0x4e, 0x34, 0xcd, 0x66, 0x0e, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x6e, 0x08
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
	ld wa, (0x3476:16)
	ld (0x33ad:16), wa
	ld wa, (0x3478:16)
	ld (0x33cf:16), wa
	ld (0x3399:16), 0x00
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339a:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339b:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339c:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339d:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339e:16), a
	calr ToneGen_StepToNextVoiceSlot
	ld iy, (0x33ad:16)
	ld hl, (0x33cf:16)
	calr ToneGen_CalcBufferAddr
	ldb_dri a, 0x07, 0xec, 0xf4
	ld (0x339f:16), a
	ret
ToneGen_VoiceParamDisp_Return:
	nop
	nop

__pad_F62AAC:
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
	ldb_dri a, 0x07, 0xec, 0xf4
	cp A,0x90
	jr z, ToneGen_CalcBeatSubdivision
	ld (0x33b1:16), 0x08
	calr ToneGen_StepToNextVoiceSlot
	calr ToneGen_StepToNextVoiceSlot
ToneGen_CalcBeatSubdivision:
	calr	372
	calr	369
	calr	366
	calr	363
	calr	360
	calr	357
	ld	wa, (13263:16)
	ld	(13756:16), wa
	ld	(13462:16), wa
	xor	w, w
	ld	a, (13209:16)
	ld	(13762:16), wa
	calr	63672
	call	16121850
	ret
ToneGen_CalcBeat_Return:
	nop
	nop

__pad_F62B29:
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
	ld XIX,Display_FontPalette_Table_0x12EA
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21, 0x5c, 0xf1, 0x4e
	.byte 0x34, 0xce, 0x66, 0x08, 0xf1, 0xff, 0x36, 0xcb
	.byte 0x66, 0x02, 0x68, 0x0c
ToneGen_ReadBufferUtility:
	.byte 0xf1, 0x4e, 0x34, 0xcd, 0x66, 0x17, 0xf1, 0xff
	.byte 0x36, 0xcb, 0x6e, 0x11
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
	call	16123607
	calr	62880
	jr	21
ToneGen_SeqAdvanceMain:
	ld	(32422:16), 15
	ld	(58134:16), 238
	ld	(58136:16), 64
	ldb	a, 8
	call	16692690
ToneGen_SeqAdv_Return:
	ret

__pad_F62C3E:
	nop
	nop

AccVoice_ReadCurrentToneType:
	push	xiy
	push	xhl
	xor	xiy, xiy
	ld	iy, (13229:16)
	ld	hl, (13263:16)
	calr	59490
	add	xhl, xiy
	ld	a, (xhl+1)
	cp	a, 135
	jr	nz, 16
	ld	hl, (13263:16)
	calr	59473
	ld	hl, (xhl+3)
	calr	59467
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
	calr	-6096
	ld_rrb	a, xhl, iy
	cp	a, 135
	jr	z, 7
	cp	a, 131
	jr	nz, 49
	jr	26
ToneGen_Interp_StoreResult:
	ld	hl, (13263:16)
	calr	59416
	ld	hl, (xhl+3)
	ld	(13263:16), hl
	calr	59406
	lds	iy, 6
	ld	(13209:16), 6
	jr	21
ToneGen_Interp_CheckExit:
	call	16116102
	calr	61093
	ld	(13263:16), hl
	calr	59383
	lds	iy, 6
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
	.byte 0xc1, 0x99, 0x33, 0x61, 0xd1, 0xcf, 0x33, 0x23
	.byte 0x1e, 0xd4, 0xe7, 0xc3, 0x07, 0xec, 0xf4, 0x21
	.byte 0xc9, 0xcf, 0x87, 0x6e, 0x03, 0x1e, 0x23, 0x00
ToneGen_Interp_Return:
	inc	1, iy
	inc	1, (13209:16)
	ld	hl, (13263:16)
	calr	59322
	ld_rrb	a, xhl, iy
	cp	a, 135
	jr	nz, 3	; -> 0xF62900
	calr	9
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
	calr	59293
	xor	iy, iy
	ld	hl, (xhl+3)
	ld	(13263:16), hl
	calr	59281
	lds	iy, 6
	ld	(13209:16), 6
	ret
ToneGen_AdvanceBeatCounter:
	nop
	nop
	inc	1, iy
	cp	iy, bc
	jr	ule, 3
	ld iy, (xhl+256)
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
	nop
	nop

ToneGen_StepVoiceForward:
	push	xiy
	push	xhl
	ld	iy, (13229:16)
	dec	1, iy
	dec	1, (13209:16)
	ld	hl, (13263:16)
	calr	-6331
	ld_rrb	a, xhl, iy
	cp	a, 135
	jr	nz, 49
	ld	hl, (xhl+1)
	cp	hl, 65535
	jr	z, 17
	ld	(13263:16), hl
	calr	-6357
	ldw	iy, 254
	ld	(13209:16), 254
	jr	23
ToneGen_StepFwd_CheckWrap:
	ld	hl, (13674:16)
	ld	(13263:16), hl
	calr	59158
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
	cps b, 3
	jr ugt, ToneGen_StepAlt_CheckBeat
	ldb C, 0x00
	jr t, ToneGen_StepAlt_Return
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
	ld	(13994:16), c
	xor	d, d
	ld	(13995:16), de
	calr	226
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
	jr	47
AccPlayback_MeasPos_SetUpper:
	ld	c, e
	sub	c, 3
	dec	1, c
	ld	(13994:16), c
	jr	34
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
	jr	11
AccPlayback_MeasPos_SmallUpper:
	ld	c, e
	sub	c, 1
	dec	1, c
	ld	(13994:16), c
RhythmChannel_NullRet:
	ret

__pad_F62F32:
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
	cps a, 4
	jr ule, AccPlayback_PartAssign_Store
	cp (0x345f:16), 0x04
	jr nc, AccPlayback_PartAssign_Sub4
	ldb A, 0x04
	jr t, AccPlayback_PartAssign_Store
AccPlayback_PartAssign_Sub4:
	sub a, 0x4

AccPlayback_PartAssign_Store:
	ld	(13986:16), a
	jrl	228
AccPlayback_PartAssign_Check4:
	.byte 0xc1, 0x3d, 0x34, 0x3f, 0x04, 0x7b, 0x82, 0x00
	.byte 0xc1, 0x3b, 0x34, 0x3f, 0x02, 0x6b, 0x3a, 0xc1
	.byte 0xaa, 0x36, 0x3f, 0x00, 0x66, 0x03, 0x78, 0xcb
	.byte 0x00
AccPlayback_PartAssign_SmallPart:
	.byte 0xc1, 0x3d, 0x34, 0x21, 0xf1, 0xa2, 0x36, 0x41
	.byte 0xf1, 0xa6, 0x36, 0x00, 0x01, 0xc1, 0x3b, 0x34
	.byte 0x3f, 0x01, 0x67, 0x09, 0xf1, 0xa3, 0x36, 0x41
	.byte 0xf1, 0xa7, 0x36, 0x00, 0x02
AccPlayback_PartAssign_Check2:
	.byte 0xc1, 0x3b, 0x34, 0x3f, 0x02, 0x67, 0x09, 0xf1
	.byte 0xa4, 0x36, 0x41, 0xf1, 0xa8, 0x36, 0x00, 0x03
AccPlayback_PartAssign_Check3:
	jrl RhythmFunc_NullRet

AccPlayback_PartAssign_LargeMeasure:
	ld	a, (13371:16)
	subda8	a, (13994)
	cps	a, 2
	jr	gt, 3
	jrl	140
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
	jr	90
AccPlayback_PartAssign_LargeBeat:
	.byte 0xc1, 0x3b, 0x34, 0x3f, 0x00, 0x6e, 0x1e, 0xc1
	.byte 0xaa, 0x36, 0x3f, 0x00, 0x6e, 0x4c, 0xf1, 0xa2
	.byte 0x36, 0x00, 0x04, 0xc1, 0x3d, 0x34, 0x21, 0xc9
	.byte 0xca, 0x04, 0xf1, 0xa3, 0x36, 0x41, 0xf1, 0xa6
	.byte 0x36, 0x00, 0x01, 0x68, 0x35
AccPlayback_PartAssign_LargeBeat2:
	ld	a, (13371:16)
	subda8	a, (13994)
	cps	a, 0
	jr	le, 41
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
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xb6	; differs from v10 here and llvm-objdump cannot read it
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
	bit 0, (0x3435:16)
	jr nz, .Lc_f62d55
	jp AccPat_Dispatch_Return
AccPat_Dispatch_AllocAndProcess:
.Lc_f62d55:
	ld XWA,0x00000800
	push XWA
	call 0xff06a3
	add XSP,0x00000004
	ld	(13512:16), xhl
	ld	a, (13393:16)
	ld	w, (13394:16)
	pushw	wa
	.byte 0xc1, 0x35, 0x34, 0x3c, 0xfe, 0xc1, 0x14, 0x35, 0x3c, 0xfe
	ld	a, (13393:16)
	cp	a, 128
	jr	c, 88
	cp	a, 160
	jrl	nc, 149
	cp	(13395:16), 26
	jr	nz, 6
	calr	4023
	jrl	136
AccPat_Dispatch_CalcAccent:
	calr	3491
	ld	a, (13393:16)
	and	a, 127
	cp	a, (13370:16)
	jr	z, 120
	cp	a, 30
	jr	nc, 115
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80
	call	16116271
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
	calr	102
	jr	24
AccPat_Dispatch_LowRange:
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80
	cp	(13395:16), 26
	jr	nz, 5
	calr	4960
	jr	50
AccPat_Dispatch_InitWorkArea:
	call AccPat_InitWorkAreaFromSlot
	calr RhythmROM_PatternDispatcher

AccPat_Dispatch_CheckBit0:
	.byte 0xf1, 0x14, 0x35, 0xc8, 0x6e, 0x12, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0xb8, 0x6e, 0x1e, 0xf1, 0xa6, 0x7e
	.byte 0x00, 0x14, 0x1d, 0xee, 0x54, 0xf6, 0x68, 0x13
AccPat_Dispatch_InitSlot:
	call	16116191
	ld	(32422:16), 23
	call	16143598
	ldb	a, 8
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

__pad_F6323D:
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
	jr	c, 2
	xor	l, l
AccPat_DualVoice_ClampIndex:
	sla	l, 2
	xor	h, h
	ld	xix, 14967570
	ld_rrl	xiy, xix, hl
	addda32	xiy, (14610)
	add	xiy, 96
	ld	(13504:16), xiy
	ld	l, (14609:16)
	cp	l, 30
	jr	c, 2	; -> 0xF62E74
	xor	l, l
AccPat_DualVoice_ClampIndex2:
	.byte 0xcf, 0xec, 0x02, 0xce, 0xd6, 0x44, 0x12, 0x63
	.byte 0xe4, 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x25, 0xe1
	.byte 0x16, 0x39, 0x85, 0xed, 0xc8, 0x60, 0x00, 0x00
	.byte 0x00, 0xf1, 0xc4, 0x34, 0x65, 0xe1, 0xc0, 0x34
	.byte 0x25, 0xed, 0xc8, 0x0c, 0x00, 0x00, 0x00, 0xe1
	.byte 0xc4, 0x34, 0x24, 0xec, 0xc8, 0x0c, 0x00, 0x00
	.byte 0x00, 0x31, 0x54, 0x00, 0x85, 0x11, 0x1e, 0x61
	.byte 0x00, 0x1e, 0x88, 0x00, 0x1e, 0xaf, 0x00, 0x0e
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
	ld_rrl	xiy, xix, hl
	add	xiy, 608256
	add	xiy, 96
	ld	(13504:16), xiy
	ld	l, (13370:16)
	cp	l, 30
	jr	c, 2
	xor	l, l
	sla	l, 2
	xor	h, h
	.byte 0x44	; v10 does not spell this byte either
	.byte 0x12	; v10 does not spell this byte either
	.byte 0x63	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	.byte 0xe3	; v10 does not spell this byte either
	reti
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xec	; v10 does not spell this byte either
	ldb	e, 237
	.byte 0xc8	; v10 does not spell this byte either
	nop
	popw	wa
	push	0
	add	xiy, 96
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0xc4, 0x34	; differs from v10 here and llvm-objdump cannot read it
	jr	mi, 14
AccPat_DualVoice_ReadParamsA:
	ld xiy, (13504:16)

	ld hl, (xiy + 256)

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



__pad_F6333A:
	nop
	nop

AccPatch_LoadDualVoiceParamsB:
	ld xiy, (13508:16)

	ld hl, (xiy + 256)

	ld (13564:16), hl

	ld hl, (xiy + 4)

	ld (13566:16), hl

	ld hl, (xiy + 6)

	ld (13568:16), hl

	ld hl, (xiy + 8)

	ld (13570:16), hl

	ld hl, (xiy + 10)

	.byte 0xf1, 0x04, 0x35, 0x53	; stda16 (0x35a0), xhl (v7 patched)

	ret



__pad_F63364:
	nop
	nop

AccPat_DualVoice_CopyAllBanks:
	ld	iy, (13576:16)
	ld	ix, (13564:16)
	calr	47
	ld	iy, (13578:16)
	ld	ix, (13566:16)
	calr	36
	ld	iy, (13580:16)
	ld	ix, (13568:16)
	calr	25
	ld	iy, (13582:16)
	ld	ix, (13570:16)
	calr	14
	ld	iy, (13584:16)
	ld	ix, (13572:16)
	calr	3
	ret
__pad_F6339E:
	nop
	nop

ToneBank_CopyEntry:
	ld (0x34fa:16), ix
	ld (0x3506:16), iy
	ld HL,IY
	.byte 0xe1, 0x12, 0x39, 0x20, 0x1e, 0xd2, 0x00, 0x9b
	.byte 0x03, 0x20, 0xf1, 0x12, 0x35, 0x50, 0xd1, 0xfa
	.byte 0x34, 0x23, 0xe1, 0x16, 0x39, 0x20, 0x1e, 0xc0
	.byte 0x00, 0xeb, 0x8c, 0xd1, 0x06, 0x35, 0x23, 0xe1
	.byte 0x12, 0x39, 0x20, 0x1e, 0xb3, 0x00, 0xeb, 0x8d
	.byte 0xed, 0xc8, 0x06, 0x00, 0x00, 0x00, 0xec, 0xc8
	.byte 0x06, 0x00, 0x00, 0x00, 0x31, 0xf9, 0x00, 0x85
	.byte 0x11
__pad_F633E3:
	.byte 0xd1, 0x12, 0x35, 0x3f, 0xff, 0xff, 0x76, 0x84
	.byte 0x00, 0x1e, 0xa6, 0x00, 0xf1, 0x14, 0x35, 0xc8
	.byte 0x6e, 0x7b, 0xd1, 0x38, 0x34, 0x69, 0xda, 0x8b
	.byte 0xe1, 0x16, 0x39, 0x20, 0x1e, 0x81, 0x00, 0x83
	.byte 0x3e, 0x80, 0xd1, 0xfa, 0x34, 0x23, 0xe1, 0x16
	.byte 0x39, 0x20, 0x1e, 0x73, 0x00, 0xbb, 0x03, 0x52
	.byte 0xda, 0x8b, 0xe1, 0x16, 0x39, 0x20, 0x1e, 0x67
	.byte 0x00, 0xd1, 0xfa, 0x34, 0x20, 0xbb, 0x01, 0x50
	.byte 0xf1, 0xfa, 0x34, 0x52, 0xd1, 0x12, 0x35, 0x20
	.byte 0xf1, 0x06, 0x35, 0x50, 0xd8, 0x8b, 0xe1, 0x12
	.byte 0x39, 0x20, 0x1e, 0x4b, 0x00, 0x9b, 0x03, 0x20
	.byte 0xf1, 0x12, 0x35, 0x50, 0x1e, 0x92, 0xfc, 0xd1
	.byte 0xfa, 0x34, 0x23, 0xe1, 0x16, 0x39, 0x20, 0x1e
	.byte 0x36, 0x00, 0xeb, 0x8c, 0xd1, 0x06, 0x35, 0x23
	.byte 0xe1, 0x12, 0x39, 0x20, 0x1e, 0x29, 0x00, 0xeb
	.byte 0x8d, 0xed, 0xc8, 0x06, 0x00, 0x00, 0x00, 0xec
	.byte 0xc8, 0x06, 0x00, 0x00, 0x00, 0x31, 0xf9, 0x00
	.byte 0x85, 0x11, 0x78, 0x73, 0xff
ToneBank_CopyComplete_Return:
	ld	hl, (13562:16)
	ld	xwa, (14614:16)
	calr	8
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

__pad_F63498:
	.byte 0xda, 0xcf, 0x54, 0x01, 0x6f, 0x11, 0xda, 0x8b
	.byte 0xe1, 0x16, 0x39, 0x20, 0x1e, 0xdc, 0xff, 0xb3
	.byte 0xcf, 0x66, 0x09, 0xda, 0x61, 0x68, 0xe9
ToneBank_ComputeAddr_CheckRange:
	.byte 0xc1, 0x14, 0x35, 0x3e, 0x01	; ordi8 0x35b0, 1 (v7 patched)



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
	.byte 0xc1, 0x14, 0x35, 0x3e, 0x01	; ordi8 0x35b0, 1 (v7 patched)



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
	.byte 0xc1, 0x14, 0x35, 0x3e, 0x01
	or	de, 32768
	ret
RhythmROM_PatternDispatcher:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xf9
	ld	l, (13393:16)
	ld	h, (13394:16)
	call	16068321
	ld	(13393:16), l
	ld	(13394:16), h
	sla	l, 1
	sla	hl, 1
	ld	xiy, 14963010
	ld_rrw	wa, xiy, hl
	ld	(13502:16), wa
	add	hl, 2
	ld_rrw	wa, xiy, hl
	ld	(13504:16), wa
	ld	l, (13370:16)
	cp	l, 30
	jr	c, 2
	xor	l, l
AccPat_CalcAccentVelocity_Body:
	sla	l, 2
	xor	h, h
	ld	xix, 14967570
	ld_rrl	xiy, xix, hl
	add	xiy, 608256
	add	xiy, 96
	ld	(13508:16), xiy
	calr	51
	cp	(13395:16), 0
	jr	z, 32
	cp	(13395:16), 1
	jr	z, 25
	cp	(13395:16), 2
	jr	z, 18
	cp	(13395:16), 3
	jr	z, 11
	calr	1267
	calr	-576
	calr	1448
	jr	9
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
	.byte 0xd1, 0xbe, 0x34, 0x20, 0xc9, 0x88, 0x1e, 0x4e
	.byte 0x01, 0xed, 0xd5, 0xd1, 0xc0, 0x34, 0x25, 0xec
	.byte 0x85, 0xe1, 0xc8, 0x34, 0x24, 0x31, 0x00, 0x04
	.byte 0x95, 0x11, 0xc1, 0x53, 0x34, 0x27, 0xcf, 0xcc
	.byte 0x0f, 0xce, 0xd6, 0xdb, 0xec, 0x01, 0x44, 0xbd
	.byte 0x31, 0xf6, 0x00, 0xe8, 0xd0, 0xd3, 0x07, 0xf0
	.byte 0xec, 0x20, 0x68, 0x20, 0xd2, 0x03, 0xd8, 0x03
	.byte 0xd2, 0x07
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
	xordm16_24	(0x07d207), wa
	reti
	neg	wa

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
	calr	243
	pop	xix
	ld	(xix), a
	inc	1, xix
	ldb	a, 32
	ld	(xix), a
	inc	1, xix
	ldb	a, 0
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
	ld	xix, 16134719
	xor	xwa, xwa
	ld_rrw	wa, xix, hl
	jr	32	; -> 0xF6325F
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
	ld	xiy, (13512:16)
	add	xiy, xwa
	ld	xix, (13508:16)
	add	xix, 24
	ldb	a, 5
RhythmROM_PatternDisp_Check91:
	.byte 0xd9, 0xaf, 0x85, 0x11, 0xec, 0x61, 0xc9, 0x69
	.byte 0xc9, 0xd8, 0x6e, 0xf4, 0xe1, 0xc4, 0x34, 0x24
	.byte 0x45, 0x22, 0x00, 0x00, 0x00, 0xec, 0x85, 0xb5
	.byte 0x00, 0x40, 0x45, 0x2a, 0x00, 0x00, 0x00, 0xec
	.byte 0x85, 0xb5, 0x00, 0x0c, 0x45, 0x32, 0x00, 0x00
	.byte 0x00, 0xec, 0x85, 0xb5, 0x00, 0x74, 0x45, 0x3a
	.byte 0x00, 0x00, 0x00, 0xec, 0x85, 0xb5, 0x00, 0x40
	.byte 0xc1, 0x51, 0x34, 0x21, 0xf1, 0x4e, 0x90, 0x41
	.byte 0xc1, 0x52, 0x34, 0x21, 0xf1, 0x4f, 0x90, 0x41
	.byte 0x1d, 0x05, 0x2f, 0xf5, 0xc1, 0x53, 0x90, 0x26
	.byte 0xc1, 0x52, 0x90, 0x27, 0x1d, 0x6f, 0xbc, 0xf5
	.byte 0x45, 0x0f, 0x34, 0x00, 0x00, 0xe1, 0xc4, 0x34
	.byte 0x24, 0xec, 0xc8, 0x40, 0x00, 0x00, 0x00, 0x31
	.byte 0x10, 0x00, 0x85, 0x11, 0x0e
RhythmROM_PatternDisp_Handle91:
	nop
	nop

RhythmROM_CalcPatternAddr:
	and	xwa, 65280
	sla	xwa, 8
	ld	xix, 4194304
	addda32	xix, (12763)
	add	xix, xwa
	ret
RhythmROM_PatternDisp_Return:
	nop
	nop

__pad_F636FB:
	ld	xhl, (13512:16)
	add	xhl, 280
	calr	211
	ld	(13591:16), e
	ld	a, (13395:16)
	cps	a, 0
	jr	z, 14
	cps	a, 1
	jr	z, 10
	cps	a, 2
	jr	z, 6
	cps	a, 3
	jr	z, 2
	jr	38
RhythmROM_InitPattern:
	.byte 0xe1, 0xc4, 0x34, 0x23, 0xd8, 0xd0, 0x8b, 0x0c
	.byte 0x21, 0x43, 0xc4, 0x3a, 0xf6, 0x00, 0xc3, 0x07
	.byte 0xec, 0xe0, 0x27, 0x21, 0x07, 0xc1, 0x17, 0x35
	.byte 0xf7, 0x6e, 0x07, 0xc1, 0x14, 0x35, 0x3e, 0x02
	.byte 0x21, 0x03
RhythmVoice_WriteParam_Return:
	jp RhythmROM_NullRet

__pad_F63748:
	ld	xhl, (13512:16)
	add	xhl, 312
	cps	a, 4
	jr	z, 44
	ld	xhl, (13512:16)
	add	xhl, 316
	cps	a, 6
	jr	z, 30
	ld	xhl, (13512:16)
	add	xhl, 1336
	cps	a, 5
	jr	z, 16
	ld	xhl, (13512:16)
	add	xhl, 1340
	cps	a, 7
	jr	z, 2
	jr	42
RhythmROM_ProcessPattern:
	calr	86
	ld	xhl, (13508:16)
	xor	wa, wa
	ld	a, (xhl+12)
	ld	xhl, 16136900
	ld_rrb	a, xhl, wa
	ex8	a, e
	xor	w, w
	div8rr	a, e
	dec	1, a
	cps	w, 0
	jr	z, 52	; -> 0xF633D4
	ldb	a, 8
	call	16692690
	jr	44	; -> 0xF633D4
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
	calr	65272
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
	lds32 xhl, 0
	bit 0, (0x3515:16)
	jr nz, .Lc_f6348b
	ld XHL,0x00000026
DrumKit_DataTable_Entry5:
.Lc_f6348b:
	add XHL,XIY
	.byte 0x8c, 0x00, 0x21, 0x1e, 0xba, 0x01, 0xf1, 0xf0
	.byte 0x34, 0x41, 0xf1, 0xce, 0x34, 0x53, 0x43, 0x4c
	.byte 0x00, 0x00, 0x00, 0xed, 0x83, 0x8c, 0x28, 0x21
	.byte 0x1e, 0xa5, 0x01, 0xf1, 0xf1, 0x34, 0x41, 0xf1
	.byte 0xd0, 0x34, 0x53, 0x43, 0x72, 0x00, 0x00, 0x00
	.byte 0xed, 0x83, 0x8c, 0x50, 0x21, 0x1e, 0x90, 0x01
	.byte 0xf1, 0xf2, 0x34, 0x41, 0xf1, 0xd2, 0x34, 0x53
	.byte 0x43, 0x98, 0x00, 0x00, 0x00, 0xed, 0x83, 0x8c
	.byte 0x78, 0x21, 0x1e, 0x7b, 0x01, 0xf1, 0xf3, 0x34
	.byte 0x41, 0xf1, 0xd4, 0x34, 0x53, 0x43, 0xbe, 0x00
	.byte 0x00, 0x00, 0xed, 0x83, 0xc3, 0xf1, 0xa0, 0x00
	.byte 0x21, 0x1e, 0x64, 0x01, 0xf1, 0xf4, 0x34, 0x41
	.byte 0xf1, 0xd6, 0x34, 0x53, 0xeb, 0xa8, 0xf1, 0x15
	.byte 0x35, 0xc8, 0x6e, 0x05, 0x43, 0x26, 0x00, 0x00
	.byte 0x00
DrumKit_DataTable_Entry6:
	.byte 0xed, 0x83, 0x8c, 0x01, 0x21, 0x1e, 0x47, 0x01
	.byte 0xf1, 0xf5, 0x34, 0x41, 0xf1, 0xd8, 0x34, 0x53
	.byte 0x43, 0x4c, 0x00, 0x00, 0x00, 0xed, 0x83, 0x8c
	.byte 0x29, 0x21, 0x1e, 0x32, 0x01, 0xf1, 0xf6, 0x34
	.byte 0x41, 0xf1, 0xda, 0x34, 0x53, 0x43, 0x72, 0x00
	.byte 0x00, 0x00, 0xed, 0x83, 0x8c, 0x51, 0x21, 0x1e
	.byte 0x1d, 0x01, 0xf1, 0xf7, 0x34, 0x41, 0xf1, 0xdc
	.byte 0x34, 0x53, 0x43, 0x98, 0x00, 0x00, 0x00, 0xed
	.byte 0x83, 0x8c, 0x79, 0x21, 0x1e, 0x08, 0x01, 0xf1
	.byte 0xf8, 0x34, 0x41, 0xf1, 0xde, 0x34, 0x53, 0x43
	.byte 0xbe, 0x00, 0x00, 0x00, 0xed, 0x83, 0xc3, 0xf1
	.byte 0xa1, 0x00, 0x21, 0x1e, 0xf1, 0x00, 0xf1, 0xf9
	.byte 0x34, 0x41, 0xf1, 0xe0, 0x34, 0x53, 0xeb, 0xa8
	.byte 0xf1, 0x15, 0x35, 0xc8, 0x6e, 0x05, 0x43, 0x26
	.byte 0x00, 0x00, 0x00
DrumKit_DataTable_Entry7:
	.byte 0xed, 0x83, 0x8c, 0x02, 0x21, 0x1e, 0xd4, 0x00
	.byte 0xf1, 0x24, 0x35, 0x41, 0xf1, 0x1a, 0x35, 0x53
	.byte 0x43, 0x4c, 0x00, 0x00, 0x00, 0xed, 0x83, 0x8c
	.byte 0x2a, 0x21, 0x1e, 0xbf, 0x00, 0xf1, 0x25, 0x35
	.byte 0x41, 0xf1, 0x1c, 0x35, 0x53, 0x43, 0x72, 0x00
	.byte 0x00, 0x00, 0xed, 0x83, 0x8c, 0x52, 0x21, 0x1e
	.byte 0xaa, 0x00, 0xf1, 0x26, 0x35, 0x41, 0xf1, 0x1e
	.byte 0x35, 0x53, 0x43, 0x98, 0x00, 0x00, 0x00, 0xed
	.byte 0x83, 0x8c, 0x7a, 0x21, 0x1e, 0x95, 0x00, 0xf1
	.byte 0x27, 0x35, 0x41, 0xf1, 0x20, 0x35, 0x53, 0x43
	.byte 0xbe, 0x00, 0x00, 0x00, 0xed, 0x83, 0xc3, 0xf1
	.byte 0xa2, 0x00, 0x21, 0x1e, 0x7e, 0x00, 0xf1, 0x28
	.byte 0x35, 0x41, 0xf1, 0x22, 0x35, 0x53, 0xeb, 0xa8
	.byte 0xf1, 0x15, 0x35, 0xc8, 0x6e, 0x05, 0x43, 0x26
	.byte 0x00, 0x00, 0x00
DrumKit_DataTable_Entry8:
	add	xhl, xiy
	ld	a, (xix+3)
	calr	97
	ld	(13620:16), a
	ld	(13610:16), hl
	ld	xhl, 76
	add	xhl, xiy
	ld	a, (xix+43)
	calr	76
	ld	(13621:16), a
	ld	(13612:16), hl
	ld	xhl, 114
	add	xhl, xiy
	ld	a, (xix+83)
	calr	55
	ld	(13622:16), a
	ld	(13614:16), hl
	ld	xhl, 152
	add	xhl, xiy
	ld	a, (xix+123)
	calr	34
	ld	(13623:16), a
	ld	(13616:16), hl
	ld	xhl, 190
	add	xhl, xiy
	ld	a, (xix+163)
	calr	11
	ld	(13624:16), a
	ld	(13618:16), hl
	ret
RhythmROM_LoadKit_InitLDA:
	nop
	nop

ToneData_LookupEffectParam:
	sla a, 1

	xor w, w

	ldw_sri HL, 0x07, 0xec, 0xe0

	push xix

	ld xix, (13512:16)

	add xix, 0x3d1

	ld a, (xix)

	pop xix

	ret



RhythmROM_LoadKit_Return:
	nop
	nop

__pad_F63A6C:
	.byte 0xe1, 0xc8, 0x34, 0x24, 0xec, 0xc8, 0xd1, 0x03
	.byte 0x00, 0x00, 0x84, 0x21, 0xf1, 0xf0, 0x34, 0x41
	.byte 0xf1, 0xf1, 0x34, 0x41, 0xf1, 0xf2, 0x34, 0x41
	.byte 0xf1, 0xf3, 0x34, 0x41, 0xf1, 0xf4, 0x34, 0x41
	.byte 0x1e, 0x58, 0x00, 0xe1, 0xc8, 0x34, 0x25, 0xeb
	.byte 0xd3, 0xd1, 0x18, 0x35, 0x23, 0xeb, 0x85, 0xeb
	.byte 0xa8, 0xf1, 0x15, 0x35, 0xc8, 0x6e, 0x05, 0x43
	.byte 0x26, 0x00, 0x00, 0x00
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

__pad_F63AE7:
	ld l, (13395:16)

	and l, 0xf

	xor h, h

	sla hl, 1

	.byte 0x44, 0x00, 0x37, 0xf6, 0x00	; ld xix, VoiceSlot_ResolveIndex_0x2 (v7 patched)

	ldw_sri WA, 0x07, 0xf0, 0xec

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
	.byte 0xc1, 0xf0, 0x34, 0x20, 0x1e, 0xb6, 0xfb, 0xd1
	.byte 0xce, 0x34, 0x25, 0xd1, 0xfc, 0x34, 0x22, 0xf1
	.byte 0x15, 0x35, 0xc8, 0x6e, 0x08, 0xf1, 0x15, 0x35
	.byte 0xc9, 0x6e, 0x02, 0x68, 0x05
VoiceSlot_Resolve_CheckA:
	calr RhythmBuf_LoadPattern
	jr VoiceSlot_Resolve_StoreA

VoiceSlot_Resolve_CheckB:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreA:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf1, 0x34
	.byte 0x20, 0x1e, 0x8c, 0xfb, 0xd1, 0xd0, 0x34, 0x25
	.byte 0xd1, 0xfe, 0x34, 0x22, 0xf1, 0x15, 0x35, 0xca
	.byte 0x66, 0x05, 0x1e, 0xca, 0x02, 0x68, 0x03
VoiceSlot_Resolve_CheckC:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreB:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf2, 0x34
	.byte 0x20, 0x1e, 0x6a, 0xfb, 0xd1, 0xd2, 0x34, 0x25
	.byte 0xd1, 0x00, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcb
	.byte 0x66, 0x05, 0x1e, 0xa8, 0x02, 0x68, 0x03
VoiceSlot_Resolve_CheckD:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreC:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf3, 0x34
	.byte 0x20, 0x1e, 0x48, 0xfb, 0xd1, 0xd4, 0x34, 0x25
	.byte 0xd1, 0x02, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcc
	.byte 0x66, 0x05, 0x1e, 0x86, 0x02, 0x68, 0x03
VoiceSlot_Resolve_CheckE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_StoreD:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf4, 0x34
	.byte 0x20, 0x1e, 0x26, 0xfb, 0xd1, 0xd6, 0x34, 0x25
	.byte 0xd1, 0x04, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcd
	.byte 0x66, 0x05, 0x1e, 0x64, 0x02, 0x68, 0x03
VoiceSlot_Resolve_StoreE:
	calr RhythmBuf_FillEmptyPattern

VoiceSlot_Resolve_Done:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb	; anddi8 (0x35b0), 251 (v7 patched)

	ret



__pad_F63BDA:
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
	calr	359
	ld	w, (13557:16)
	calr	64017
	ld	iy, (13528:16)
	calr	345
	ld	w, (13604:16)
	calr	64003
	ld	iy, (13594:16)
	calr	331
	ld	w, (13620:16)
	calr	63989
	ld	iy, (13610:16)
	calr	317
	jr	3
AccSection_Process_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63CFB:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf1, 0x34
	.byte 0x20, 0x1e, 0xdd, 0xf9, 0xd1, 0xd0, 0x34, 0x25
	.byte 0xd1, 0xfe, 0x34, 0x22, 0xf1, 0x15, 0x35, 0xca
	.byte 0x66, 0x2f, 0x1e, 0x1b, 0x01, 0xc1, 0xf6, 0x34
	.byte 0x20, 0x1e, 0xc5, 0xf9, 0xd1, 0xda, 0x34, 0x25
	.byte 0x1e, 0x0d, 0x01, 0xc1, 0x25, 0x35, 0x20, 0x1e
	.byte 0xb7, 0xf9, 0xd1, 0x1c, 0x35, 0x25, 0x1e, 0xff
	.byte 0x00, 0xc1, 0x35, 0x35, 0x20, 0x1e, 0xa9, 0xf9
	.byte 0xd1, 0x2c, 0x35, 0x25, 0x1e, 0xf1, 0x00, 0x68
	.byte 0x03
AccSection_Process2_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D47:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf2, 0x34
	.byte 0x20, 0x1e, 0x91, 0xf9, 0xd1, 0xd2, 0x34, 0x25
	.byte 0xd1, 0x00, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcb
	.byte 0x66, 0x2f, 0x1e, 0xcf, 0x00, 0xc1, 0xf7, 0x34
	.byte 0x20, 0x1e, 0x79, 0xf9, 0xd1, 0xdc, 0x34, 0x25
	.byte 0x1e, 0xc1, 0x00, 0xc1, 0x26, 0x35, 0x20, 0x1e
	.byte 0x6b, 0xf9, 0xd1, 0x1e, 0x35, 0x25, 0x1e, 0xb3
	.byte 0x00, 0xc1, 0x36, 0x35, 0x20, 0x1e, 0x5d, 0xf9
	.byte 0xd1, 0x2e, 0x35, 0x25, 0x1e, 0xa5, 0x00, 0x68
	.byte 0x03
AccSection_Process3_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63D93:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf3, 0x34
	.byte 0x20, 0x1e, 0x45, 0xf9, 0xd1, 0xd4, 0x34, 0x25
	.byte 0xd1, 0x02, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcc
	.byte 0x66, 0x2f, 0x1e, 0x83, 0x00, 0xc1, 0xf8, 0x34
	.byte 0x20, 0x1e, 0x2d, 0xf9, 0xd1, 0xde, 0x34, 0x25
	.byte 0x1e, 0x75, 0x00, 0xc1, 0x27, 0x35, 0x20, 0x1e
	.byte 0x1f, 0xf9, 0xd1, 0x20, 0x35, 0x25, 0x1e, 0x67
	.byte 0x00, 0xc1, 0x37, 0x35, 0x20, 0x1e, 0x11, 0xf9
	.byte 0xd1, 0x30, 0x35, 0x25, 0x1e, 0x59, 0x00, 0x68
	.byte 0x03
AccSection_Process4_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63DDF:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb, 0xc1, 0xf4, 0x34
	.byte 0x20, 0x1e, 0xf9, 0xf8, 0xd1, 0xd6, 0x34, 0x25
	.byte 0xd1, 0x04, 0x35, 0x22, 0xf1, 0x15, 0x35, 0xcd
	.byte 0x66, 0x2f, 0x1e, 0x37, 0x00, 0xc1, 0xf9, 0x34
	.byte 0x20, 0x1e, 0xe1, 0xf8, 0xd1, 0xe0, 0x34, 0x25
	.byte 0x1e, 0x29, 0x00, 0xc1, 0x28, 0x35, 0x20, 0x1e
	.byte 0xd3, 0xf8, 0xd1, 0x22, 0x35, 0x25, 0x1e, 0x1b
	.byte 0x00, 0xc1, 0x38, 0x35, 0x20, 0x1e, 0xc5, 0xf8
	.byte 0xd1, 0x32, 0x35, 0x25, 0x1e, 0x0d, 0x00, 0x68
	.byte 0x03
AccSection_Process5_Return:
	calr RhythmBuf_FillEmptyPattern

__pad_F63E2B:
	.byte 0xc1, 0x14, 0x35, 0x3c, 0xfb	; anddi8 (0x35b0), 251 (v7 patched)

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

	lds32 xiz, 6



AccFill_ProcessDone:
	ld	a, (xiy)
	ld	hl, (13562:16)
	calr	62075
	add	xhl, xiz
	ld	(xhl), a
__pad_F63E69:
	.byte 0xc9, 0xcf, 0x83, 0x66, 0x4d, 0xed, 0x61, 0xee
	.byte 0x61, 0xee, 0xcf, 0xfe, 0x00, 0x00, 0x00, 0x63
	.byte 0x34, 0x1e, 0x38, 0xf6, 0xf1, 0x14, 0x35, 0xc8
	.byte 0x6e, 0x38, 0x3d, 0xd1, 0xfa, 0x34, 0x23, 0x1e
	.byte 0x55, 0xf2, 0xed, 0xab, 0xeb, 0x85, 0xb5, 0x52
	.byte 0xda, 0x8b, 0x1e, 0x4a, 0xf2, 0xed, 0xa9, 0xeb
	.byte 0x85, 0xd1, 0xfa, 0x34, 0x20, 0xb5, 0x50, 0xf1
	.byte 0xfa, 0x34, 0x52, 0x83, 0x3e, 0x80, 0xd1, 0x38
	.byte 0x34, 0x69, 0xee, 0xae, 0x5d
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
	max
	halt
	ei	7
	ldio	1, 2
	pop	sr
	max
	halt
	ei	7
	.byte 0x08

RhythmBuf_FillEmptyPattern:
	ld xiy, (0x34c4:16)
	ld L,(XIY+0x0c)
	xor H,H
	ld XIX,__pad_F63EC6_0x2
	ldb_dri w, 0x07, 0xf0, 0xec
	ld A,(XIY+0x0d)
	and A,0x07
	inc 1,A
	mul8rr	a, w
	push	xwa
	ld	hl, de
	calr	-3615
	pop	xwa
	add	xhl, 6
	ld	e, a
	ldb	a, 129
StyleConvert_ReloadParams:
	ld (xhl), a
	inc 1, xhl
	dec 1, e
	cps e, 0
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
	.byte 0xc1, 0x53, 0x34, 0x3f, 0x13, 0x63, 0x20, 0x21
	.byte 0x78, 0xc1, 0x51, 0x34, 0x3f, 0x84, 0x67, 0x0d
	.byte 0xc9, 0xc8, 0x06, 0xc1, 0x51, 0x34, 0x3f, 0x88
	.byte 0x67, 0x03, 0xc9, 0xc8, 0x06
StyleConvert_Reload_CheckEnd:
	addda8	a, (13395)
	ld	(13393:16), a
	jr	37
StyleConvert_Reload_Return:
	.byte 0xc1, 0x53, 0x34, 0x3f, 0x10, 0x67, 0x1e, 0x21
	.byte 0x70, 0xc1, 0x51, 0x34, 0x3f, 0x84, 0x67, 0x0d
	.byte 0xc9, 0xc8, 0x04, 0xc1, 0x51, 0x34, 0x3f, 0x88
	.byte 0x67, 0x03, 0xc9, 0xc8, 0x04
StyleConvert_Reload_Fallback:
	addda8	a, (13395)
	ld	(13393:16), a
StyleConvert_Reload_Done:
	ret

__pad_F63F8F:
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
	.byte 0x0e, 0x00, 0x00
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
	cp	(13394:16), 0
	jr	nz, 29
	ld	a, (13393:16)
	and	a, 127
	ld	xix, 16138491
	ld_rr8b	a, xix, a
	ld	w, (13370:16)
	sub	w, 30
	cp	a, w
	jrl	z, 906
__pad_F64174:
	ld	a, (13393:16)
	ld	w, (13394:16)
	ld	l, (13395:16)
	ld	h, (13370:16)
	pushw	wa
	pushw	hl
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80
	ld	(13395:16), 16
	ld	l, (13370:16)
	sub	l, 30
	ld	(14601:16), l
	ld	xix, 16138551
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	ld	(14602:16), l
	calr	-622
	call	16116271
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
	calr	-3988
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 703
	ld	(13395:16), 17
	ld	l, (14602:16)
	inc	1, l
	ld	(13370:16), l
	calr	-688
	call	16116271
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
	calr	-4054
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 637
	ld	(13395:16), 18
	ld	l, (14602:16)
	add	l, 2
	ld	(13370:16), l
	calr	-755
	call	16116271
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
	calr	-4121
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 570
	ld	(13395:16), 19
	ld	l, (14602:16)
	add	l, 3
	ld	(13370:16), l
	calr	-822
	call	16116271
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
	calr	-4188
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 503
	ld	(13395:16), 20
	ld	a, (13393:16)
	pushw	wa
	calr	-883
	ld	l, (14601:16)
	ld	xix, 16138554
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4267
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 419
	ld	(13395:16), 21
	ld	a, (13393:16)
	pushw	wa
	calr	-967
	ld	l, (14601:16)
	ld	xix, 16138557
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4351
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 335
	ld	(13395:16), 22
	ld	a, (13393:16)
	pushw	wa
	calr	-1051
	ld	l, (14601:16)
	ld	xix, 16138560
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4435
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 251
	ld	(13395:16), 23
	ld	a, (13393:16)
	pushw	wa
	calr	-1135
	ld	l, (14601:16)
	ld	xix, 16138563
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4519
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 167
	ld	(13395:16), 24
	ld	a, (13393:16)
	pushw	wa
	calr	-1219
	ld	l, (14601:16)
	ld	xix, 16138566
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4603
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 83
	ld	(13395:16), 25
	ld	a, (13393:16)
	pushw	wa
	calr	-1303
	ld	l, (14601:16)
	ld	xix, 16138569
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
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
	calr	-4687
	popw	wa
	ld	(13393:16), a
	.byte 0xf1, 0x14, 0x35, 0xc8
	jr	z, 68
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
	ld_rr8b	a, xwa, c
	ld	(13370:16), a
	push	xbc
	push	xix
	call	16116271
	pop	xix
	pop	xbc
	inc	1, c
	cp	c, 10
	jr	c, -44
	ld	(32422:16), 23
	call	16143598
	ldb	a, 8
	call	16692690
	jr	9
DrumKit_SetErrorCode20:
	ld	(32422:16), 20
	call	16143598
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
	.byte 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x00, 0x00
	.byte 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x08, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x00, 0x04, 0x08, 0x0c
	.byte 0x12, 0x18, 0x0d, 0x13, 0x19, 0x0e, 0x14, 0x1a
	.byte 0x0f, 0x15, 0x1b, 0x10, 0x16, 0x1c, 0x11, 0x17
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
	ld	xix, 16138521
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	ld	(14602:16), l
	call	16116271
	calr	-4251
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 309
	ld	(13395:16), 1
	ld	l, (14602:16)
	inc	1, l
	ld	(13370:16), l
	call	16116271
	calr	-4280
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 280
	ld	(13395:16), 2
	ld	l, (14602:16)
	add	l, 2
	ld	(13370:16), l
	call	16116271
	calr	-4310
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 250
	ld	(13395:16), 3
	ld	l, (14602:16)
	add	l, 3
	ld	(13370:16), l
	call	16116271
	calr	-4340
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 220
	ld	(13395:16), 4
	ld	l, (14601:16)
	ld	xix, 16138554
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4377
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 183
	ld	(13395:16), 5
	ld	l, (14601:16)
	ld	xix, 16138557
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4414
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 146
	ld	(13395:16), 10
	ld	l, (14601:16)
	ld	xix, 16138560
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4451
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 109
	ld	(13395:16), 11
	ld	l, (14601:16)
	ld	xix, 16138563
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4488
	.byte 0xf1, 0x14, 0x35, 0xc8
	jrl	nz, 72
	ld	(13395:16), 6
	ld	l, (14601:16)
	ld	xix, 16138566
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4525
	.byte 0xf1, 0x14, 0x35, 0xc8
	jr	nz, 36
	ld	(13395:16), 7
	ld	l, (14601:16)
	ld	xix, 16138569
	ld_rr8b	l, xix, l
	ld	(13370:16), l
	call	16116271
	calr	-4561
	.byte 0xf1, 0x14, 0x35, 0xc8
	jr	z, 68
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
	ld_rr8b	a, xwa, c
	ld	(13370:16), a
	push	xbc
	push	xix
	call	16116271
	pop	xix
	pop	xbc
	inc	1, c
	cp	c, 10
	jr	c, -44
	ld	(32422:16), 23
	call	16143598
	ldb	a, 8
	call	16692690
	jr	9
DrumKit_AllPatternsOK:
	ld	(32422:16), 20
	call	16143598
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
	.byte 0x00, 0x00, 0x97, 0x43, 0xf6, 0x00, 0xd7, 0x45
	.byte 0xf6, 0x00, 0xb7, 0x44, 0xf6, 0x00, 0x77, 0x45
	.byte 0xf6, 0x00, 0x57, 0x44, 0xf6, 0x00, 0x17, 0x45
	.byte 0xf6, 0x00, 0xf7, 0x43, 0xf6, 0x00, 0x97, 0x43
	.byte 0xf6, 0x00, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4
	.byte 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4, 0xf4
	.byte 0xf4, 0xf4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x48, 0x48
	.byte 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48
	.byte 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x48
	.byte 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0x0c
	.byte 0x0c, 0x0c, 0x0c, 0x0c, 0x18, 0x18, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18
	.byte 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24, 0x24
	.byte 0x24, 0x24, 0x24, 0x24, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c, 0x3c
	.byte 0x3c, 0x3c, 0x3c, 0x3c, 0x49, 0x49, 0x49, 0x49
	.byte 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49, 0x49
	.byte 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54, 0x54
	.byte 0x54, 0x54, 0x54, 0x54, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10
	.byte 0x10, 0x10, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20
	.byte 0x20, 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x30, 0x30, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40
	.byte 0x40, 0x40, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50
	.byte 0x50, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50
	.byte 0x50, 0x50, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f
	.byte 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00, 0x08, 0x08
	.byte 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x10, 0x10
	.byte 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x18, 0x18
	.byte 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x20, 0x20
	.byte 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x28, 0x28
	.byte 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x30, 0x30
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x38, 0x38
	.byte 0x38, 0x38, 0x38, 0x38, 0x38, 0x38, 0x40, 0x40
	.byte 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x48, 0x48
	.byte 0x48, 0x48, 0x48, 0x48, 0x48, 0x48, 0x50, 0x50
	.byte 0x50, 0x50, 0x50, 0x50, 0x50, 0x50, 0x58, 0x58
	.byte 0x58, 0x58, 0x58, 0x58, 0x58, 0x58, 0x7f, 0x7f
	.byte 0x7f, 0x7f
DrumKitInit_Wrapper:
	push xiz
	call DrumKitInit_Entry
	pop xiz
	ret
DrumKitInit_Entry:
	ldb	a, 72
	call	16544114
	cp	(35993:16), 14
	jr	nz, 3
	jrl	155
DrumKitInit_Setup:
	ld	(13397:16), 0
	ld	(13375:16), 0
	ld	(13944:16), 4
	ld	(13945:16), 0
	ld	(13946:16), 1
	call	16094901
	.byte 0xc1, 0xa7, 0x28, 0x3e, 0x04
	ld	(14079:16), 64
	ld	a, (64602:16)
	ld	(13393:16), a
	ld	a, (64603:16)
	ld	(13394:16), a
	ld	a, (64602:16)
	ld	(13455:16), a
	ld	a, (64603:16)
	ld	(13456:16), a
	calr	82
	.byte 0xf1, 0x5f, 0xfc, 0xca
	jr	nz, 6
	.byte 0xf1, 0x5f, 0xfc, 0xcb
	jr	z, 15
DrumKitInit_ClearAssignFlags:
	and (0xfc5f:16), 243

	ldb d, 0x5

	ldb e, 0x48

	xor wa, wa

	.byte 0x1d, 0x20, 0xac, 0xfd	; call SwbtWr_QueuePostEvent (v7 addr)



DrumKitInit_CheckExtAssign:
	.byte 0xf1, 0x60, 0xfc, 0xca, 0x66, 0x0f, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0x24, 0x06, 0x25, 0x48, 0xd8
	.byte 0xd0, 0x1d, 0x20, 0xac, 0xfd
DrumKitInit_FinalSetup:
	.byte 0x1d, 0x15, 0xe5, 0xf5, 0xf1, 0x70, 0x34, 0x00
	.byte 0x00, 0x1d, 0xdf, 0x36, 0xf4, 0xf1, 0x9e, 0xf1
	.byte 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6, 0xfd, 0xc1
	.byte 0x1c, 0xe3, 0x3c, 0x9e, 0xc1, 0x31, 0x34, 0x3e
	.byte 0x40
DrumKitInit_Return:
	ret

DrumKit_SendProgramChange:
	lds32	xhl, 0
	ld	l, (13370:16)
	cp	l, 30
	jr	c, 6
	sub	l, 30
	sll	l, 2
DrumKit_SendPC_MaskAndSend:
	and l, 0x1f
	add l, 0x80
	ld xbc, 0xfc5a
	ldb a, 0x0
	stb_dri L, 0x03, 0xe4, 0xe0
	ldb a, 0x1
	ldb_sri H, 0x03, 0xe4, 0xe0
	and h, 0x80
	stb_dri H, 0x03, 0xe4, 0xe0
	calr DrumKit_PostMidiEvents
	ret

DrumKitExit_Wrapper:
	push xiz
	call DrumKitExit_Entry
	pop xiz
	ret

DrumKitExit_Entry:
	ldb A, 0x48
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
	.byte 0xc1, 0x5b, 0xfc, 0xe9, 0x1e, 0x87, 0x00
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
	.byte 0xf1, 0xe7, 0x31, 0xc8, 0x6e, 0x05, 0xc1, 0x31
	.byte 0x34, 0x3e, 0x80
DrumKitExit_Return:
	ret

DrumKitExit_DataPad:
	ret
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
	push	l
	calr	13
	pop	l
	and	l, 31
	ld	(13370:16), l
	calr	65257
DrumKit_ValidateBank_Return:
	ret

DrumKit_StoreAndSendBank:
	ld (0xfc5a:16), l
	and (0xfc5b:16), 128
	ldb h, 0x0
	call PartCtrl_WriteProgramChange
	ld xix, 0xff92
	stb_dri H, 0x03, 0xf0, 0xec
	call DrumKit_PostMidiEvents
	ret

DrumKit_PostMidiEvents:
	ldb	e, 72
	ld	a, (64603:16)
	and	a, 127
	ldb	d, 1
	ldb	w, 0
	push_a
	call	16624672
	pop_a
	ld	h, a
	ldb	e, 72
	ld	a, (64602:16)
	and	a, 255
	ldb	d, 0
	ldb	w, 0
	push	h
	push_a
	call	16624672
	pop_a
	pop	h
	ld	l, a
	ld	(36955:16), 72
	call	16554468
	ldb	c, 72
	call	16554735
	ret
DrumKit_UpdateStatusFlags:
	ld	w, (13397:16)
	and	w, 194
	bit	7, w
	jr	z, 44
	ld	a, (14079:16)
	bit	4, a
	jr	z, 3
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
	call	16140450
	pop	xiz
	ret
	ret
	push XIZ
	call DrumKit_InlineCode1_0xF
	pop XIZ
	ret
	cp	(35995:16), 177
	jr	z, 16
	calr	109
	ld	(14079:16), 64
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xbf
	calr	6
	.byte 0xc1, 0x1c, 0xe3, 0x3c, 0x9e
	ret
	ld	e, (13361:16)
	and	e, 48
	lds32	xhl, 0
	ld	l, (13370:16)
	ld	xwa, 16140540
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
	ld	(13370:16), l
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
	ldb	w, 32
	ldb	w, 32
	ldb	w, 32
	rcf
	rcf
	rcf
	rcf
	rcf
	rcf
	push	xiz
	call	16140577
	pop	xiz
	ret
	xor	xwa, xwa
	xor	xde, xde
	ld	a, (64605:16)
	and	a, 7
	cps	a, 0
	jr	nz, 28
	ldb	a, 2
	ldb	w, 7
	ldb	e, 72
	ldb	d, 3
	call	16624705
	ldb	a, 8
	orddm8 (64605), xbc
	ldb	w, 8
	ldb	e, 72
	ldb	d, 3
	call	16624672
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
	ld	e, (13361:16)
	and	e, 48
	cps	e, 0
	jr	nz, 2
	jr	13
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
	cps	e, 0
	jr	nz, 5
	add	l, 8
	jr	13
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
	.byte 0xc3, 0x03, 0xe0, 0xec, 0x21, 0xf1, 0x3d, 0x34
	.byte 0x41, 0x8d, 0x0d, 0x21, 0xf1, 0x3b, 0x34, 0x41
	.byte 0xc1, 0x32, 0x34, 0x3c, 0x7f, 0x8d, 0x0f, 0x21
	.byte 0xc9, 0x33, 0x07, 0x66, 0x05, 0xc1, 0x32, 0x34
	.byte 0x3e, 0x80
RhythmPatInit_FlagBit7:
	.byte 0x8d, 0x0e, 0x21, 0xc9, 0x88, 0xc9, 0xcc, 0x0f
	.byte 0xf1, 0x4d, 0x34, 0x41, 0xc1, 0x4e, 0x34, 0x3c
	.byte 0x8f, 0xc8, 0x33, 0x04, 0x66, 0x05, 0xc1, 0x4e
	.byte 0x34, 0x3e, 0x10
RhythmPatInit_Tempo4:
	.byte 0xc8, 0x33, 0x05, 0x66, 0x05, 0xc1, 0x4e, 0x34
	.byte 0x3e, 0x20
RhythmPatInit_Tempo5:
	.byte 0xc8, 0x33, 0x06, 0x66, 0x05, 0xc1, 0x4e, 0x34
	.byte 0x3e, 0x40
RhythmPatInit_CopyChannels:
	add xiy, 0x40

	ld xix, 13344

	ld xbc, 0xd

	ldir85

	stib_dsp 0xf0, 0x00

	stib_dsp 0xf0, 0x00

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
	.byte 0xc1, 0x1c, 0xe3, 0x3c, 0xf7, 0x40, 0x49, 0x4b
	.byte 0xf6, 0x00, 0xdb, 0xdc, 0x67, 0x04, 0xdb, 0xca
	.byte 0x04, 0x00
RhythmFillIn_LookupAndApply:
	ld_rrb	a, xwa, hl
	ld	(14079:16), a
	calr	64798
	call	16635678
	call	16635862
	ret
RhythmFillIn_PatternTable:
	.incbin "includes/romslices/v7_transplant_RhythmFillIn_PatternTable_head.bin"
	push XIZ
	call 0xf64b58
	pop XIZ
	ret
	.incbin "includes/romslices/v7_transplant_RhythmFillIn_PatternTable_tail.bin"
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
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc8, 0x33, 0x07
	.byte 0x6e, 0x29, 0xc1, 0x3f, 0x34, 0x3f, 0x00, 0x6e
	.byte 0x07, 0xf1, 0x3f, 0x34, 0x00, 0x04, 0x68, 0x19
	.byte 0xc1, 0x3f, 0x34, 0x3f, 0x03, 0x6e, 0x07, 0xf1
	.byte 0x3f, 0x34, 0x00, 0x00, 0x68, 0x0b, 0xc1, 0x3f
	.byte 0x34, 0x3f, 0x07, 0x66, 0x04, 0xc1, 0x3f, 0x34
	.byte 0x61, 0x68, 0x27, 0xc1, 0x3f, 0x34, 0x3f, 0x00
	.byte 0x6e, 0x07, 0xf1, 0x3f, 0x34, 0x00, 0x03, 0x68
	.byte 0x19, 0xc1, 0x3f, 0x34, 0x3f, 0x04, 0x6e, 0x07
	.byte 0xf1, 0x3f, 0x34, 0x00, 0x00, 0x68, 0x0b, 0xc1
	.byte 0x3f, 0x34, 0x3f, 0x01, 0x66, 0x04, 0xc1, 0x3f
	.byte 0x34, 0x69, 0x0e
RhythmSolo_Wrapper:
	push xiz
	calr RhythmSolo_Toggle
	pop xiz
	ret

RhythmSolo_Toggle:
	.byte 0xf1, 0x55, 0x34, 0xcf, 0x6e, 0x07, 0xf1, 0x55
	.byte 0x34, 0x00, 0x80, 0x68, 0x05
RhythmSolo_Disable:
	ld	(13397:16), 0
RhythmSolo_UpdateStatus:
	.byte 0x1e, 0x22, 0xfc, 0xf1, 0xe7, 0x31, 0xc8, 0x6e
	.byte 0x05, 0xc1, 0x31, 0x34, 0x3e, 0x80
RhythmSolo_Return:
	ret

RhythmVariation_Wrapper:
	push xiz
	calr RhythmVariation_Select
	pop xiz
	ret

RhythmVariation_Select:
	.byte 0xc1, 0x33, 0x34, 0x21, 0xc9, 0xcc, 0x0c, 0xc9
	.byte 0xd8, 0x6e, 0x33, 0xc1, 0x60, 0x35, 0x21, 0xc9
	.byte 0xcc, 0x0c, 0xc9, 0xd8, 0x6e, 0x28, 0xdb, 0xcc
	.byte 0x0f, 0x00, 0x40, 0x49, 0x4b, 0xf6, 0x00, 0xc3
	.byte 0x07, 0xe0, 0xec, 0x21, 0xf1, 0xff, 0x36, 0x41
	.byte 0x1e, 0xe5, 0xfb, 0xf1, 0xe7, 0x31, 0xc8, 0x6e
	.byte 0x05, 0xc1, 0x31, 0x34, 0x3e, 0x80
RhythmVariation_PostDispatch:
	call	16635678
	call	16635862
RhythmVariation_Return:
	ret
RhythmVariation_InlineCode:
	calr	-1074
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cp	(35995:16), 182
	jr	z, 10
	ld	(13942:16), 4
	.byte 0xc1, 0xec, 0x8c, 0x3e, 0x01, 0xc1, 0x1c, 0xe3, 0x3c, 0xfe, 0xc1, 0x31, 0x34, 0x3e, 0x08
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xf7
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	lds32	xhl, 0
	ld	l, (14079:16)
	and	l, 31
	add	xhl, 16141542
	ld	a, (xhl)
	ld	(14079:16), a
	call	16635678
	call	16635862
	calr	-1159
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	push	xiz
	calr	2
	pop	xiz
	ret
	lds32	xhl, 0
	ld	l, (14079:16)
	and	l, 31
	add	xhl, 16141613
	ld	a, (xhl)
	ld	(14079:16), a
	call	16635678
	call	16635862
	calr	-1230
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
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cp	(13942:16), 4
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	inc	1, (13944:16)
	cp	(13944:16), 13
	jr	ule, 23
	ld	(13944:16), 13
	jr	16
	dec	1, (13944:16)
	cp	(13944:16), 1
	jr	ge, 5
	ld	(13944:16), 1
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cp	(13942:16), 4
	jr	nz, 41
	bit	7, w
	jr	nz, 18
	inc	1, (13945:16)
	cp	(13945:16), 13
	jr	ule, 23
	ld	(13945:16), 13
	jr	16
	dec	1, (13945:16)
	cp	(13945:16), 255
	jr	nz, 5
	ld	(13945:16), 0
	jr	0
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cp	(13942:16), 4
	jr	z, 2
	jr	41
	bit	7, w
	jr	nz, 18
	inc	1, (13946:16)
	cp	(13946:16), 3
	jr	ule, 23
	ld	(13946:16), 3
	jr	16
	dec	1, (13946:16)
	cp	(13946:16), 255
	jr	nz, 5
	ld	(13946:16), 0
	jr	17
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x10
	jr	5
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x20
	ret
	push	xiz
	call	16141839
	pop	xiz
	ret
	cp	(35995:16), 180
	jr	z, 27
	ld	(13476:16), 1
	call	16116102
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
	call	16141885
	pop	xiz
	ret
	cp	(35994:16), 180
	jr	z, 3
	calr	-1885
	ret
DrumTempo_Adjust:
	push XIZ
	push XIX
	ld a, (0x34a4:16)
	bit 0x07,W
	jr nz, DrumTempo_Decrement
	ldb L, 0x06
	ld XIX,0x00094800
	add XIX,0x00000010
	bit 0,(XIX)
	jr nz, DrumTempo_CheckMax
	cp (0x343a:16), 0x0b
	jr ugt, DrumTempo_CheckMax
	ldb L, 0x08
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
	ld	(13476:16), a
DrumTempo_Done:
	pop xix
	pop xiz
	ret

DrumVoice_Select:
	push	xiz
	xor	hl, hl
	ld	l, (13476:16)
	cps	l, 1
	jr	nc, 2
	ldb	l, 1
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
	.byte 0xc1, 0xec, 0x8c, 0x3e, 0x01	; ordi8 0x8d88, 1 (v7 patched)

	pushw hl

	lds32 xhl, 0

	popw hl

	and l, 0xf

	sll xhl, 2

	.byte 0xeb, 0xc8, 0xb7, 0x4e, 0xf6, 0x00	; add xhl, DrumVoice_DispatchTable (v7 patched)

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
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler0.bin"
DrumVoice_Handler1:
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler1.bin"
DrumVoice_Handler2:
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler2.bin"
DrumVoice_Handler3:
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc8, 0x33, 0x07
	.byte 0x6e, 0x07, 0xc1, 0x4e, 0x34, 0x3e, 0x10, 0x68
	.byte 0x05, 0xc1, 0x4e, 0x34
DrumVoice_Handler3_Code:
	push	xix
	and	xbc, xsp
	ldw	iz, 15924
	push	sr	
	ret	
DrumVoice_Handler5:
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler5.bin"
DrumVoice_Handler4:
	.incbin "includes/romslices/v7_transplant_DrumVoice_Handler4.bin"
DrumVoice_Handler6:
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x1c, 0xe3
	.byte 0x3e, 0x01
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
TimeSig_DisplayStrings:
	pushw	wa
	ldw	bc, 12847
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	push	sr
	pushw	wa
	ldw	de, 12847
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	max
	pushw	wa
	ldw	hl, 12847
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	ei	0x28
	ldw	ix, 12847
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	ldio	40, 49
	pushw sp
	ldw	ix, 11049
	ldw	wa, 8224
	normal
	pushw	wa
	ldw	de, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	push	sr
	pushw	wa
	ldw	hl, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	pop	sr
	pushw	wa
	ldw	ix, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	max
	pushw	wa
	ldw	iy, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	halt
	pushw	wa
	ldw	iz, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	ei	0x28
	ldw sp, 13359
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	reti
	pushw	wa
	push	xwa
	pushw sp
	ldw	ix, 11049
	ldw	wa, 8224
	ldio	40, 50
	pushw sp
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	normal
	pushw	wa
	ldw	ix, 14383
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	push	sr
	pushw	wa
	ldw	iz, 14383
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	pop	sr
	pushw	wa
	push	xwa
	pushw sp
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 8224
	max
	pushw	wa
	ldw	bc, 12080
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 1312
	pushw	wa
	ldw	bc, 12082
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 1568
	pushw	wa
	ldw	bc, 12084
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 1824
	pushw	wa
	ldw	bc, 12086
	push	xwa
	pushw	bc
	pushw	hl
	ldw	wa, 2080
	call	16068321
	ld	(64602:16), l
	and	h, 127
	.byte 0xc1, 0x5b, 0xfc, 0x3c, 0x80, 0xc1, 0x5b, 0xfc, 0xee
	ld	(36955:16), 72
	call	16554468
	ld	w, h
	extz	hl
	extz	xhl
	add	xhl, 65426
	jr	0
	ld	(xhl), w
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ldb	a, 72
	ld	(36955:16), a
	call	16554468
	pop w
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
	ld	xix, 65426
	ld_rr8b	h, xix, l
	ld	l, a
	ldb	a, 72
	ld	(36954:16), a
	call	16554433
	and	l, 255
	ld	(64602:16), l
	and	h, 127
	ld	(64603:16), h
	cp	(13395:16), 26
	jr	z, 33
	cp	(64602:16), 128
	jr	c, 14
	cp	(13395:16), 16
	jr	nc, 19
	ld	(13395:16), 16
	jr	12
	cp	(13395:16), 16
	jr	c, 5
	ld	(13395:16), 0
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ldb	a, 72
	ld	(36955:16), a
	call	16554468
	ld	a, h
	pushw	hl
	call	16104585
	ld	(13201:16), l
	popw	hl
	pop w
	bit	7, w
	jr	nz, 33
	cp	l, 15
	jr	nz, 14
	push	xix
	ld	xix, 16144160
	ld_rr8b	a, xix, a
	pop	xix
	jr	42
	inc	1, a
	cp	a, (13201:16)
	jr	ule, 34
	ld	a, (13201:16)
	jr	28
	cp	l, 15
	jr	nz, 14
	push	xix
	ld	xix, 16144172
	ld_rr8b	a, xix, a
	pop	xix
	jr	9
	dec	1, a
	cp	a, 255
	jr	nz, 2
	ldb	a, 0
	ld	h, a
	ld	xwa, 65426
	st_rr8b	h, xwa, l
	ldb	a, 72
	ld	(36954:16), a
	call	16554433
	and	l, 255
	ld	(64602:16), l
	and	h, 127
	ld	(64603:16), h
	ret
	max
	max
	max
	max
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
	max
	max
	max
	max
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
	ldb	l, 128
	ld	(13393:16), l
	ld	(13394:16), 0
	cp	l, 128
	jr	c, 16
	ld	a, (13394:16)
	and	a, 127
	cps	a, 0
	jr	z, 5
	ld	(13394:16), 0
	cp	l, 128
	jr	c, 100
	cp	(13395:16), 16
	jr	nc, 5
	ld	(13395:16), 26
	cp	(13395:16), 26
	jr	nz, 37
	ld	a, (13361:16)
	and	a, 48
	cps	a, 0
	jr	z, 12
	cp	a, 32
	jr	z, 14
	ld	(13370:16), 32
	jr	72
	ld	(13370:16), 30
	jr	65
	ld	(13370:16), 31
	jr	58
	cp	(13370:16), 30
	jr	c, 51
	ld	a, (13361:16)
	and	a, 48
	cps	a, 0
	jr	z, 19
	cp	a, 32
	jr	z, 7
	ld	(13370:16), 8
	jr	28
	ld	(13370:16), 4
	jr	21
	ld	(13370:16), 0
	jr	14
	cp	(13395:16), 16
	jr	c, 5
	ld	(13395:16), 26
	jr	-102
	ret
	ret
	cp	(13393:16), 128
	jr	c, 12
	cp	(13395:16), 10
	jr	c, 5
	ld	(13395:16), 0
	ret
	.byte 0xc8, 0x04
	ld	l, (64602:16)
	and	l, 255
	ld	h, (64603:16)
	and	h, 127
	ldb	a, 72
	ld	(36955:16), a
	call	16554468
	pushw	hl
	call	16104585
	ld	(13201:16), h
	popw	hl
	ld	a, l
	cp	a, 15
	jr	lt, 12
	ld	(13202:16), 25
	ld	(13203:16), 16
	jr	10
	ld	(13202:16), 15
	ld	(13203:16), 0
	ld	a, (13395:16)
	pop w
	bit	7, w
	jr	nz, 45
	cp	a, 26
	jr	nz, 26
	push	xix
	ld	a, (13370:16)
	ld	xix, 16144588
	ld_rr8b	a, xix, a
	ld	(13370:16), a
	pop	xix
	ld	a, (13203:16)
	jr	51
	inc	1, a
	cp	a, (13202:16)
	jr	ule, 43
	ld	a, (13202:16)
	jr	37
	cp	a, 26
	jr	z, 32
	dec	1, a
	cp	a, (13203:16)
	jr	ge, 24
	push	xix
	ld	a, (13370:16)
	ld	xix, 16144555
	ld_rr8b	a, xix, a
	ld	(13370:16), a
	pop	xix
	ldb	a, 26
	jr	0
	ld	(13395:16), a
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
	ldb	w, 32
	ldb	w, 32
	calr	8223
	nop
	nop
	nop
	nop
	max
	max
	max
	max
	ldio	8, 8
	ldio	0, 0
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
	ldio	8, 8
	ldio	8, 8
	nop
	max
	ldio	200, 51
	reti
	jr	nz, 58
	.byte 0xf1, 0x31, 0x34, 0xcd
	jr	z, 22
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xcf, 0xc1, 0x31, 0x34, 0x3e, 0x10
	ld	(13370:16), 32
	ld	(13395:16), 26
	jr	81
	.byte 0xf1, 0x31, 0x34, 0xcc
	jr	z, 2
	jr	73
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xcf, 0xc1, 0x31, 0x34, 0x3e, 0x20
	ld	(13370:16), 31
	ld	(13395:16), 26
	jr	51
	.byte 0xf1, 0x31, 0x34, 0xcd
	jr	z, 17
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xcf
	ld	(13370:16), 30
	ld	(13395:16), 26
	jr	28
	.byte 0xf1, 0x31, 0x34, 0xcc
	jr	z, 22
	.byte 0xc1, 0x31, 0x34, 0x3c, 0xcf, 0xc1, 0x31, 0x34, 0x3e, 0x20
	ld	(13370:16), 31
	ld	(13395:16), 26
	jr	0
	ret
	ld	a, (13370:16)
	.byte 0xf1, 0x31, 0x34, 0xcc
	jr	z, 5
	calr	204
	jr	14
	.byte 0xf1, 0x31, 0x34, 0xcd
	jr	z, 5
	calr	115
	jr	3
	calr	5
	ld	(13370:16), a
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
	ld	(13395:16), 26
	jr	16
	cp	a, 11
	jr	nz, 4
	ldb	a, 3
	jr	7
	cp	a, 18
	jr	lt, 2
	ldb	a, 17
	ret
	ld	a, (64602:16)
	and	a, 255
	cp	a, 128
	jr	c, 7
	ld	(13395:16), 16
	jr	5
	ld	(13395:16), 0
	ret
	bit	7, w
	jr	nz, 32
	inc	1, a
	cp	a, 32
	jr	nz, 7
	calr	-40
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
	ld	(13395:16), 26
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
	calr	-118
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
	ld	(13395:16), 26
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
	call	16094901
	.byte 0xc1, 0xa7, 0x28, 0x3e, 0x04
	ld	a, (64602:16)
	and	a, 15
	ld	(14446:16), a
	call	16145105
	ld	(14466:16), xiy
	add	xiy, 16
	ld	(14470:16), xiy
	.byte 0xf1, 0x8a, 0x38, 0xc8
	jr	nz, 18
	lds32	xbc, 4
	ld	xiy, (14466:16)
	ld	xix, 14450
	.byte 0x85, 0x11
	ld	(14449:16), 0
	.byte 0xc1, 0x8a, 0x38, 0x3c, 0xfe
	ret
	ret
	ret
	lds32	xwa, 0
	lds32	xbc, 0
	ldb	a, 32
	ld	c, (14446:16)
	mul8rr	a, c
	add	xwa, 608256
	add	xwa, 2976
	ld	xiy, xwa
	ret
	ld	a, (14448:16)
	ld	xiy, 14450
	ld_rr8b	c, xiy, a
	ld	(14445:16), c
	ret
	ld	a, (14447:16)
	ld	xiy, 14450
	ld_rr8b	c, xiy, a
	ld	(14444:16), c
	ret
	.byte 0xc1, 0xa7, 0x28, 0x3c, 0xfb, 0xc1, 0x8a, 0x38, 0x3c, 0xfe
	ret
	ld	a, (14446:16)
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
	ld	(14446:16), a
	or	a, 240
	ld	(64602:16), a
	ldb	a, 0
	ld	(64603:16), a
	calr	-4912
	ld	(14449:16), 0
	ret
	.byte 0xc8, 0x04
	calr	-92
	pop w
	bit	7, w
	jr	nz, 34
	cp	(14444:16), 11
	jr	nc, 6
	inc	1, (14444:16)
	jr	19
	cp	(14444:16), 255
	jr	nz, 7
	ld	(14444:16), 0
	jr	5
	ld	(14444:16), 11
	jr	32
	cp	(14444:16), 0
	jr	le, 6
	dec	1, (14444:16)
	jr	19
	cp	(14447:16), 0
	jr	nz, 7
	ld	(14444:16), 0
	jr	5
	ld	(14444:16), 255
	ld	a, (14444:16)
	ld	(14445:16), a
	ld	xix, 14450
	ld	c, (14447:16)
	st_rr8b	a, xix, c
	ld	xix, 14450
	calr	6
	.byte 0xc1, 0x8a, 0x38, 0x3e, 0x01
	ret
	ld	(14449:16), 0
	ldb	h, 0
	calr	63
	ld	wa, bc
	pushw	wa
	ldb	h, 1
	calr	55
	popw	wa
	cp	bc, 65535
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	81
	pushw	wa
	ldb	h, 2
	calr	35
	popw	wa
	cp	bc, 65535
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	61
	pushw	wa
	ldb	h, 3
	calr	15
	popw	wa
	cp	bc, 65535
	jr	z, 7
	cp	bc, wa
	jr	z, 3
	calr	41
	ret
	ld_rr8b	l, xix, h
	cp	l, 255
	jr	z, 26
	.byte 0xc1, 0x3a, 0x34, 0x04
	ld	(13370:16), l
	.byte 0xce, 0x04
	push	xix
	call	16115664
	pop	xix
	.byte 0xce, 0x05, 0xf1, 0x3a, 0x34, 0x04
	ld	b, a
	jr	3
	ldw	bc, 65535
	ret
	push	xwa
	ld	xwa, 16145482
	ld_rr8b	a, xwa, h
	orddm8 (14449), xbc
	pop	xwa
	ret
	normal
	push	sr
	max
	ldio	8, 8
	ldio	8, 62
	call	16145497
	pop	xiz
	ret
	ret
	.byte 0xc1, 0x6e, 0x38, 0x04, 0xc1, 0x6f, 0x38, 0x04
	ld	(14446:16), 0
	cp	(14446:16), 5
	jr	z, 19
	calr	-416
	ld	xix, xiy
	push	xix
	calr	-175
	pop	xix
	calr	20
	inc	1, (14446:16)
	jr	-26
	.byte 0xf1, 0x6f, 0x38, 0x04, 0xf1, 0x6e, 0x38, 0x04
	ld	(14449:16), 0
	ret
	.byte 0xf1, 0x71, 0x38, 0xc9
	jr	z, 9
	ldb	b, 255
	ldb	a, 1
	st_rr8b	b, xix, a
	.byte 0xf1, 0x71, 0x38, 0xca
	jr	z, 9
	ldb	b, 255
	ldb	a, 2
	st_rr8b	b, xix, a
	.byte 0xf1, 0x71, 0x38, 0xcb
	jr	z, 9
	ldb	b, 255
	ldb	a, 3
	st_rr8b	b, xix, a
	ret
	lds32	xbc, 4
	ld	xix, (14466:16)
	ld	xiy, 14450
	.byte 0x85, 0x11
	ret
	push XIZ
	call TimeSig_DisplayStrings_0x7CD
	pop XIZ
	ret
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
	.byte 0x0e, 0x3e, 0x1d, 0x72, 0x5d, 0xf6, 0x5e, 0x0e
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
	ld DE,WA
	cp DE,0x0017
	ret UGT
	.byte 0xd9, 0xcc, 0x80, 0x00, 0xd9, 0xd8, 0xc9, 0x7e
	.byte 0xd8, 0x12, 0xda, 0x89, 0xe9, 0x12, 0xe9, 0xee
	.byte 0x02, 0x42, 0x44, 0xa0, 0xe4, 0x00, 0xe9, 0x82
	.byte 0xa2, 0x23, 0xb3, 0xe8, 0x0e
Tempo_AdjustStartMeasure:
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0080
	lds bc, 0
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
	cps	wa, 1
	jr	ule, 38
	dec	1, bc
	ld	(14574:16), bc
Tempo_StartMeasureSync:
	ld	bc, (14576:16)
	ld	wa, (14574:16)
	cp	wa, bc
	jr	ule, 6
	ld	(14576:16), wa
	jr	10
Tempo_StartMeasureSyncFar:
	inc	7, wa
	cp	wa, bc
	jr	nc, 4
	ld	(14576:16), wa
Tempo_StartMeasureSetDirty:
	.byte 0xf1, 0x1a, 0xe3, 0xbc	; setda 4, 0xe3e0 (v7 patched)



Tempo_StartMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustEndMeasure:
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0081
	lds bc, 1
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
	cps	wa, 1
	jr	ule, 40
	dec	1, bc
	ld	(14576:16), bc
	ld	wa, (14576:16)
Tempo_EndMeasureSyncStart:
	ld	bc, (14574:16)
	cp	bc, wa
	jr	ule, 6
	ld	(14574:16), wa
	jr	12
Tempo_EndMeasureSyncFar:
	inc	7, bc
	cp	bc, wa
	jr	nc, 6
	dec	7, wa
	ld	(14574:16), wa
Tempo_EndMeasureSetDirty:
	.byte 0xf1, 0x1a, 0xe3, 0xbc	; setda 4, 0xe3e0 (v7 patched)



Tempo_EndMeasureReturn:
	inc 2, xsp
	ret

Tempo_AdjustQuantize:
	dec 2,XSP
	ld (XSP),A
	ldw WA, 0x0082
	lds bc, 2
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
	cps	a, 1
	jr	ule, 10
	dec	1, c
	ld	(14578:16), c
Tempo_QuantizeSetDirty:
	.byte 0xf1, 0x1a, 0xe3, 0xbc	; setda 4, 0xe3e0 (v7 patched)



Tempo_QuantizeReturn:
	inc 2, xsp
	ret

Tempo_AdjustEffect:
	.byte 0xef, 0x6a, 0xb7, 0x41, 0x30, 0x86, 0x00, 0xd9
	.byte 0xae, 0x1e, 0x07, 0x02, 0xc1, 0xf4, 0x38, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xf2, 0xa4, 0xa0
	.byte 0xe4, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x21, 0x81
	.byte 0x21, 0x87, 0x3f, 0x00, 0x6e, 0x09, 0xc9, 0xcf
	.byte 0x10, 0x6f, 0x10, 0xc9, 0x61, 0x68, 0x06
Tempo_EffectDec:
	cps a, 0
	jr z, Tempo_EffectReturn
	dec 1, a

Tempo_EffectStore:
	ld (xbc), a

	.byte 0xf1, 0x1a, 0xe3, 0xbc	; setda 4, 0xe3e0 (v7 patched)



Tempo_EffectReturn:
	inc 2, xsp
	ret

Tempo_IncrementTimeSigNum:
	cps a, 0
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
	cps a, 0
	ret NZ
	ldw WA, 0x0009
	ldw BC, 0x0008
	calr Tempo_DisplayParamCommon
	ld a, (0x38f3:16)
	cps a, 0
	ret Z
	dec 1,A
	ld (0x38f3:16), a
	set 4, (0xe31a:16)
	ret
Tempo_TimeSigCodeBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 28 of 41 slots byte-identical
	cps	a, 0
	ret	nz
	ldw	wa, 10
	ldw	bc, 11
	calr	391
	ld	a, (14580:16)
	cps	a, 0
	ret	z
	dec	1, a
	ld	(14580:16), a
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0x1a	; v10 does not spell this byte either
	.byte 0xe3	; v10 does not spell this byte either
	.byte 0xbc	; v10 does not spell this byte either
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 132
	lds	bc, 4
	calr	360
	ld	a, (14580:16)
	.byte 0x87	; v10 does not spell this byte either
	push	xsp
	nop
	jr	nz, 14
	ld	c, a
	cps	a, 4
	jr	nc, 24
	inc	1, c
	ld	(14580:16), c
	jr	12
	ld	c, a
	cps	a, 0
	jr	z, 10
	dec	1, c
	ld	(14580:16), c
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0x1a	; v10 does not spell this byte either
	.byte 0xe3	; v10 does not spell this byte either
	ld	(xix-17), xde
	ret
Tempo_EditBPM:
	cps a, 0
	ret NZ
	set 0, (0x8cec:16)
	calr Tempo_DisplayParamReturn
	ld (0x38ec:16), l
	cps l, 1
	jr z, Tempo_EditBPMDec
	cps l, 0
	jr nz, Tempo_EditBPMClamp
	ldw WA, 0x0023
	calr Tempo_DisplayParamSkipClear
	jr t, Tempo_EditBPMClamp
Tempo_EditBPMDec:
	ldw	wa, 15
	calr	295
	ldw	wa, 8
	call	16692690
Tempo_EditBPMClamp:
	.byte 0xf1, 0x31, 0x34, 0xbf	; setda 7, 0x34cd (v7 patched)

	.byte 0xf1, 0x31, 0x34, 0xbf	; setda 7, 0x34cd (v7 patched)

	ret
Tempo_EditBPMApply:
	cps	a, 0
	ret	nz
	ldw	wa, 176
	call	16355459
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 146
	ldw	bc, 18
	calr	240
	ld	wa, (14574:16)
	.byte 0x87, 0x3f, 0x00
	jr	nz, 32
	ld	bc, wa
	cp	wa, 999
	jr	nc, 84
	cp	bc, 989
	jr	c, 8
	ldw	(14574:16), 999
	jr	38
	add	bc, 10
	ld	(14574:16), bc
	jr	28
	ld	bc, wa
	cps	wa, 1
	jr	ule, 54
	cp	bc, 10
	jr	ugt, 8
	ldw	(14574:16), 1
	jr	8
	sub	bc, 10
	ld	(14574:16), bc
	ld	bc, (14576:16)
	ld	wa, (14574:16)
	cp	wa, bc
	jr	ule, 6
	ld	(14576:16), wa
	jr	10
	inc	7, wa
	cp	wa, bc
	jr	nc, 4
	ld	(14576:16), wa
	.byte 0xf1, 0x1a, 0xe3, 0xbc
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ldw	wa, 147
	ldw	bc, 19
	calr	123
	ld	wa, (14576:16)
	.byte 0x87, 0x3f, 0x00
	jr	nz, 37
	ld	bc, wa
	cp	wa, 999
	jr	nc, 93
	cp	bc, 989
	jr	c, 11
	ldw	(14576:16), 999
	ldw	wa, 999
	jr	46
	add	bc, 10
	ld	(14576:16), bc
	ld	wa, bc
	jr	34
	ld	bc, wa
	cps	wa, 1
	jr	ule, 58
	cp	bc, 10
	jr	ugt, 10
	ldw	(14576:16), 1
	lds	wa, 1
	jr	12
	sub	bc, 10
	ld	(14576:16), bc
	ld	wa, (14576:16)
	ld	bc, (14574:16)
	cp	bc, wa
	jr	ule, 6
	ld	(14574:16), wa
	jr	12
	inc	7, bc
	cp	bc, wa
	jr	nc, 6
	dec	7, wa
	ld	(14574:16), wa
	.byte 0xf1, 0x1a, 0xe3, 0xbc
	inc	2, xsp
	ret
	extz	wa
	jrl	-581
	extz	wa
	jrl	-531
Tempo_DisplayParamCommon:
	or (0xe31c:16), 0x09
	ld (0xe31e:16), a
	ld (0xe320:16), c
	ret
Tempo_DisplayParamSkipClear:
	ld	(32422:16), a
	ldw	wa, 238
	jp	16355504
Tempo_DisplayParamFormat:
	.incbin "includes/romslices/v7_transplant_Tempo_DisplayParamFormat.bin"
Tempo_DisplayParamReturn:
	push QIZ
	lds_erpb 0xfb, 0
	calr MIDIChan_ScanForFree
	calr VoiceSlot_UpdateState
	calr Tempo_DisplayBPMReturn
	lds wa, 0
	calr SeqRec_ValidateDone
	ld a, (0x38f5:16)
	cps a, 0
	jr z, .Lc_f661c5
	extz WA
	calr Part_IsPercussionType
	cps l, 0
	jr nz, .Lc_f661c5
	ld c, (0x38f5:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f661c5
	lds wa, 0
	calr Part_StoreVoiceTableIndex
	lds wa, 0
	calr Tempo_FormatBPM
	ldb_erp l, 0xfb
	cps_erpb 0xfb, 1
	jrl z, Tempo_DisplayEffect
Tempo_DisplayStartMeasure:
.Lc_f661c5:
	lds wa, 1
	calr SeqRec_ValidateDone
	ld a, (0x38f6:16)
	cps a, 0
	jr z, .Lc_f66202
	extz WA
	calr Part_IsPercussionType
	cps l, 0
	jr nz, .Lc_f66202
	ld c, (0x38f6:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f66202
	lds wa, 1
	calr Part_StoreVoiceTableIndex
	lds wa, 1
	calr Tempo_FormatBPM
	ldb_erp l, 0xfb
	cps_erpb 0xfb, 1
	jrl z, Tempo_DisplayEffect
Tempo_DisplayEndMeasure:
.Lc_f66202:
	lds wa, 2
	calr SeqRec_ValidateDone
	ld a, (0x38f7:16)
	cps a, 0
	jr z, .Lc_f6623e
	extz WA
	calr Part_IsPercussionType
	cps l, 0
	jr nz, .Lc_f6623e
	ld c, (0x38f7:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f6623e
	lds wa, 2
	calr Part_StoreVoiceTableIndex
	lds wa, 2
	calr Tempo_FormatBPM
	ldb_erp l, 0xfb
	cps_erpb 0xfb, 1
	jr z, Tempo_DisplayEffect
Tempo_DisplayQuantize:
.Lc_f6623e:
	lds wa, 3
	calr SeqRec_ValidateDone
	ld a, (0x38f8:16)
	cps a, 0
	jr z, .Lc_f6627a
	extz WA
	calr Part_IsPercussionType
	cps l, 0
	jr nz, .Lc_f6627a
	ld c, (0x38f8:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, .Lc_f6627a
	lds wa, 3
	calr Part_StoreVoiceTableIndex
	lds wa, 3
	calr Tempo_FormatBPM
	ldb_erp l, 0xfb
	cps_erpb 0xfb, 1
	jr z, Tempo_DisplayEffect
Tempo_DisplayTimeSigNum:
.Lc_f6627a:
	lds wa, 4
	calr SeqRec_ValidateDone
	ld a, (0x38f9:16)
	cps a, 0
	jr z, Tempo_DisplayEffectLookup
	extz WA
	calr Part_IsPercussionType
	cps l, 0
	jr nz, Tempo_DisplayEffectLookup
	ld c, (0x38f9:16)
	extz BC
	ld wa, (0x38ee:16)
	calr SetWall_StoreAndResolve
	cp (0x287a:16), 0x00
	jr nz, Tempo_DisplayEffectLookup
	lds wa, 4
	calr Part_StoreVoiceTableIndex
	lds wa, 4
	calr Tempo_FormatBPM
	ldb_erp l, 0xfb
	cps_erpb 0xfb, 1
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
	push	qiz
	lda	xde, (14588:16)
	ld	xbc, xde
	lda	xde, (xde+10)
Tempo_FormatBPMDigit:
	.byte 0xf5, 0xe4, 0x00, 0x00, 0xea, 0xf1, 0x67, 0xf8
	.byte 0xc9, 0xd8, 0x6e, 0x06, 0xf1, 0xfb, 0x38, 0xb8
	.byte 0x68, 0x04
Tempo_FormatBPMDone:
	.byte 0xf1, 0xfb, 0x38, 0xb0	; resda 0, 0x3997 (v7 patched)



Tempo_FormatBPMOutput:
	.byte 0xc9, 0xd9, 0x6e, 0x06, 0xf1, 0xfb, 0x38, 0xb9
	.byte 0x68, 0x04
Tempo_FormatBPMPad:
	.byte 0xf1, 0xfb, 0x38, 0xb1	; resda 1, 0x3997 (v7 patched)



Tempo_DisplayBPMValue:
	ld wa, (14576:16)

	subda16 xwa, (14574)

	inc 1, a

	ldb_erp A, 0xfa

	.byte 0xc1, 0xea, 0x38, 0x41	; mul_sd16b 1, 0x86, 0x39 (v7 patched)

	ldb_erp A, 0xfa



Tempo_DisplayBPMFraction:
	cpib_erp	250, 0
	jr	z, 34
	calr	1048
	calr	1513
	ld	a, (14588:16)
	cp	a, 129
	jr	nz, 5
	dec1b_erp	250
	jr	5
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
	ld	(14588:16), 129
	calr	1095
	cps	l, 1
	jr	z, 25
	inc1b_erp	251
	stb_erp	a, 251
	cpb_erp	a, 250
	jr	nz, -23
Tempo_DisplayBPMClean:
	ld	(14588:16), 131
	calr	1072
	cps	l, 1
	jr	z, 2
	ldb	l, 0
Tempo_DisplayBPMExit:
	popw_erp 0xfa
	ret
Tempo_DisplayBPMReturn:
	lda	xsp, (xsp-18)
	push	xiz
	ld	xiy, 14983352
	lda	xix, (xsp+6)
	ldw	bc, 8
	.byte 0x95, 0x11
	ld	e, (14579:16)
	lds32	xwa, 0
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
	.byte 0x81, 0xf1
	jr	z, 34
	.byte 0xbf, 0x04, 0x14, 0x3a, 0x34
	ld	(13370:16), e
	ld	a, (14570:16)
	inc	3, a
	ld	(xbc), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16115795
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0x8f, 0x04, 0x19, 0x3a, 0x34
Tempo_DisplayMeasureRange:
	ld wa, (14576:16)

	subda16 xwa, (14574)

	ld (xiz + 13), a

	resm 7, (xiz + 15)

	lda xde, (xsp + 6)

	lda xwa, (xiz + 64)

	ld xbc, xwa

	lda xhl, (xwa + 16)



Tempo_DisplayMeasureStart:
	.byte 0xc5, 0xe8, 0x21, 0xf5, 0xe4, 0x41, 0xeb, 0xf1
	.byte 0x67, 0xf6, 0xc1, 0xf5, 0x38, 0x3f, 0x00, 0x66
	.byte 0x05, 0xd8, 0xa8, 0x1e, 0x35, 0x00
Tempo_DisplayMeasureSep:
	.byte 0xc1, 0xf6, 0x38, 0x3f, 0x00, 0x66, 0x05, 0xd8
	.byte 0xa9, 0x1e, 0x29, 0x00
Tempo_DisplayMeasureEnd:
	.byte 0xc1, 0xf7, 0x38, 0x3f, 0x00, 0x66, 0x05, 0xd8
	.byte 0xaa, 0x1e, 0x1d, 0x00
Tempo_DisplayQuantizeVal:
	.byte 0xc1, 0xf8, 0x38, 0x3f, 0x00, 0x66, 0x05, 0xd8
	.byte 0xab, 0x1e, 0x11, 0x00
Tempo_DisplayTimeSig:
	.byte 0xc1, 0xf9, 0x38, 0x3f, 0x00, 0x66, 0x05, 0xd8
	.byte 0xac, 0x1e, 0x05, 0x00
Tempo_DisplayEffectVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

Tempo_DisplayEffectValLookup:
	.byte 0xef, 0x68, 0x3e, 0xbf, 0x0a, 0x41, 0x8f, 0x0a
	.byte 0x3f, 0x04, 0x66, 0x4c, 0x8f, 0x0a, 0x3f, 0x03
	.byte 0x66, 0x39, 0x8f, 0x0a, 0x3f, 0x02, 0x66, 0x26
	.byte 0x8f, 0x0a, 0x3f, 0x01, 0x66, 0x13, 0x8f, 0x0a
	.byte 0x3f, 0x00, 0x6e, 0x3f, 0xc1, 0xf5, 0x38, 0x21
	.byte 0xc7, 0xfb, 0x99, 0xbf, 0x08, 0x00, 0x18, 0x68
	.byte 0x32
Tempo_RefreshDisplay1:
	.byte 0xc1, 0xf6, 0x38, 0x21, 0xc7, 0xfb, 0x99, 0xbf
	.byte 0x08, 0x00, 0x20, 0x68, 0x25
Tempo_RefreshDisplay2:
	.byte 0xc1, 0xf7, 0x38, 0x21, 0xc7, 0xfb, 0x99, 0xbf
	.byte 0x08, 0x00, 0x28, 0x68, 0x18
Tempo_RefreshDisplay3:
	.byte 0xc1, 0xf8, 0x38, 0x21, 0xc7, 0xfb, 0x99, 0xbf
	.byte 0x08, 0x00, 0x30, 0x68, 0x0b
Tempo_RefreshDisplay4:
	ld a, (14585:16)

	ldb_erp A, 0xfb

	ld (xsp + 8), 0x38



Tempo_RefreshDisplay5:
	.byte 0xc7, 0xfb, 0xd8, 0x76, 0xef, 0x00, 0xe8, 0xa8
	.byte 0xc1, 0xf3, 0x38, 0x21, 0xe8, 0x8b, 0xeb, 0x83
	.byte 0xe8, 0x83, 0xeb, 0xee, 0x05, 0xeb, 0xc8, 0x60
	.byte 0x48, 0x09, 0x00, 0xbf, 0x04, 0x63, 0xc7, 0xfb
	.byte 0x89, 0xc9, 0x69, 0xd8, 0x12, 0xf1, 0xa0, 0xf1
	.byte 0x31, 0xe8, 0x12, 0xe9, 0x80, 0x80, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xec, 0x02, 0xf2, 0xc8, 0xa0, 0xe4
	.byte 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x24, 0x8c, 0x01
	.byte 0x25, 0xda, 0x12, 0x8f, 0x08, 0x23, 0xd9, 0x12
	.byte 0x8f, 0x0a, 0x3f, 0x00, 0x6e, 0x0e, 0xf3, 0x07
	.byte 0xec, 0xe4, 0x30, 0x84, 0x23, 0xd9, 0x12, 0x1e
	.byte 0x9f, 0x00, 0x68, 0x0f
SeqRec_InitState:
	ld xwa, (xsp + 4)
	lda_dri XWA, 0x07, 0xe0, 0xe4
	ld c, (xix)
	extz bc
	calr SeqRec_OverflowCleanup

SeqRec_InitChannels:
	stb_erp C, 0xfb

	extz bc

	lds wa, 1

	.byte 0x1e, 0x71, 0x01	; calr SetWall_StoreAndResolve (v7 displacement)

	.byte 0xd1, 0xee, 0x38, 0x21	; ldw_d16 xbc, (0x398a) (v7 patched)

	dec 1, bc

	ld a, (14570:16)

	extz wa

	ldw_erp WA, 0xfa

	mul xwa, xbc

	ldw_erp WA, 0xfa

	lds iz, 0



SeqRec_StartRecord:
	cpw_erp IZ, 0xfa
	jr nc, SeqRec_UpdateFlags

SeqRec_StartRecordImpl:
	calr	533
	lda	xhl, (14588:16)
	ld	c, (xhl)
	ld	a, c
	and	a, 240
	cp	a, 192
	jr	z, 26
	cp	a, 128
	jr	nz, -29
	cp	c, 129
	jr	nz, 4
	inc	1, iz
	jr	-38
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
	lda_dri XWA, 0x07, 0xe0, 0xe8
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
	push QIZ
	ld c, (0x343a:16)
	st_erpb_rr c, 0xfa
	ld c, (0x36ff:16)
	st_erpb_rr c, 0xfb
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
	ld (0x36ff:16), 0x10
	jr t, Part_LoadAndIndexVoiceTable
SeqRec_Cleanup:
	ld	(14079:16), 8
	jr	19
Part_SetVoiceType1:
	ld	(14079:16), 1
	jr	12
Part_SetVoiceType2:
	ld	(14079:16), 2
	jr	5
Part_SetVoiceType4:
	ld	(14079:16), 4
Part_LoadAndIndexVoiceTable:
	ld	a, (14579:16)
	ld	(13370:16), a
	lds32	xwa, 0
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
	call	16152785
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	stb_erp	a, 250
	ld	(13370:16), a
	stb_erp	a, 251
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
	ldb a, 0x1

MIDIChan_ScanLoop:
	cp (xbc), 0x10
	jr z, MIDIChan_Found
	inc 1, xbc
	inc 1, a
	cp a, 0x11
	jr ule, MIDIChan_ScanLoop

MIDIChan_Found:
	cp	a, 16
	jr	ule, 6
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
	cps a, 0
	jr z, VoiceSlot_CheckSlot2
	extz WA
	jr t, VoiceSlot_ResolveAddr
VoiceSlot_CheckSlot2:
	ld	a, (14584:16)
	cps	a, 0
	jr	z, 4
	extz	wa
	jr	34
VoiceSlot_CheckSlot3:
	ld	a, (14585:16)
	cps	a, 0
	jr	z, 4
	extz	wa
	jr	22
VoiceSlot_CheckSlot4:
	ld	a, (14582:16)
	cps	a, 0
	jr	z, 4
	extz	wa
	jr	10
VoiceSlot_CheckSlot5:
	ld	a, (14581:16)
	cps	a, 0
	jr	z, 6
	extz	wa
VoiceSlot_ResolveAddr:
	call Voice_ResolveSlotAddr

VoiceSlot_StoreAndReturn:
	.byte 0xc1, 0x8e, 0x28, 0x19, 0xea, 0x38	; ldmm8 0x3986, 0x288e (v7 displacement)

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
	lda	xbc, (14588:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xwa)
	ld	(xde), c
	calr	140
	ld	xwa, xhl
	inc	1, iz
	cp	iz, qiz
	jr	c, -26
VoiceBuf_CopyDone:
	pop xiz
	ret

Voice_ScanTableByType:
	push	xiz
	calr	344
	ld	xwa, xhl
	ld	c, (14588:16)
	cp	c, 131
	jr	z, 57
	cp	c, 129
	jr	z, 52
	cp	c, 213
	jr	z, 42
	cp	c, 212
	jr	z, 37
	cp	c, 211
	jr	z, 32
	cp	c, 210
	jr	z, 27
	cp	c, 209
	jr	z, 22
	cp	c, 145
	jr	z, 10
	cp	c, 144
	jr	nz, 22
	ld	qiz, 6
	jr	20
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
	lda	xbc, (14588:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	c, (xde)
	ld	(xwa), c
	calr	117
	ld	xwa, xhl
	cp	xwa, 4294967295
	jr	nz, 4
	ldb	l, 1
	jr	9
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
	ld	xhl, xwa
	ld	wa, (14566:16)
	inc	1, wa
	ld	(14566:16), wa
	cp	wa, 256
	jr	c, 44
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
	jr	c, 105
	ld	wa, (13368:16)
	cps	wa, 0
	jr	nz, 7
	ld	xhl, 4294967295
	jr	93
VoiceTable_AdvWrite_AllocSlot:
	dec	1, wa
	ld	(13368:16), wa
	ldw	bc, 150
	ld	xde, 651776
VoiceTable_AdvWrite_ScanLoop:
	bitm 7, (xde)
	jr z, VoiceTable_AdvWrite_LinkEntry
	inc 1, bc
	lda_dri XDE, 0xe9, 0x00, 0x01
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
	.byte 0xf1, 0xfc, 0x38, 0x30, 0xf1, 0xfb, 0x38, 0xc8
	.byte 0x66, 0x43, 0xe8, 0x8a, 0x80, 0x23, 0xcb, 0x89
	.byte 0xc9, 0xcc, 0xf0, 0xc9, 0xcf, 0x80, 0x66, 0x09
	.byte 0xc9, 0xcf, 0x90, 0x6e, 0x28, 0xb2, 0x00, 0x90
	.byte 0x0e
RhythmParam_Dispatch:
	extz bc
	sub bc, 0x80
	cps bc, 0
	jr lt, RhythmParam_CheckExit
	cps bc, 6
	jr gt, RhythmParam_CheckExit
	add bc, bc
	lda xix, (Display_FontPalette_Table_0x52CE:24)
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda xix, (RhythmParam_CheckExit:24)
	jp_ind 8, 0x07, 0xf0, 0xe4

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
	jrl	z, 296
	lda	xbc, (xhl+2)
	lda	xwa, (xhl+3)
	cp	d, 208
	jrl	z, 231
	cp	d, 176
	jrl	z, 148
	cp	d, 144
	jrl	nz, 308
	ld	e, (14578:16)
	cp	e, 25
	jr	ule, 21
	ld	xix, xbc
	sub	e, 25
	ld	a, (xbc)
	add	a, e
	ld	(xbc), a
	cp	a, 127
	jr	ule, 31
	ld	(xix), 127
	jr	26
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
	.byte 0xf1, 0xfb, 0x38, 0xc9, 0x66, 0x0f, 0xbb, 0x02
	.byte 0x31, 0x81, 0x21, 0xc9, 0xcf, 0x0c, 0x67, 0x05
	.byte 0xc9, 0xca, 0x0c, 0xb1, 0x41
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
	lda xix, (Display_FontPalette_Table_0x52C0:24)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda xix, (Voice_ClearSlotAndRet:24)
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
	push	xiz
	ld	w, (14586:16)
	call	15858243
	ld	(14566:16), iy
	ld	iy, (10415:16)
	ld	(14562:16), iy
	pop	xiz
	ret
VoiceSlot_Dispatch_Type81:
	ldb	a, 127
	ld	(14124:16), a
	ldb	a, 255
	ld	(14123:16), a
	ldb	c, 0
VoiceSlot_Dispatch_Type90:
	cps	c, 7
	jr	z, 52	; -> 0xF66B3F
	ld	xwa, 14095
	ldb	e, 0
	st_rr8b	e, xwa, c
	ld	xwa, 14102
	ldb	e, 1
	st_rr8b	e, xwa, c
	ld	xwa, 14109
	ldb	e, 255
	st_rr8b	e, xwa, c
	ld	xwa, 14116
	ldb	e, 255
	st_rr8b	e, xwa, c
	inc	1, c
	jr	-56	; -> 0xF66B07
VoiceSlot_Dispatch_D0Type:
	ld	(14125:16), 64
	calr	448
	ld	(14125:16), 32
	calr	440
	ld	(14125:16), 16
	calr	432
	ld	(14125:16), 8
	calr	424
	ld	(14125:16), 4
	calr	416
	ld	(14125:16), 2
	calr	408
	ld	(14125:16), 1
	calr	400
	ret
VoiceSlot_Dispatch_Return:
	push XIZ
	call VoiceSlot_Dispatch_Return_0x7
	pop XIZ
	ret
	bit	7, a
	jr	nz, 20
	cp	(13370:16), 11
	jr	ge, 6
	inc	1, (13370:16)
	jr	5
	ld	(13370:16), 11
	jr	18
	cp	(13370:16), 0
	jr	gt, 7
	ld	(13370:16), 0
	jr	4
	dec	1, (13370:16)
	calr	4
	calr	174
	ret
	lds32	xhl, 0
	ld	l, (13370:16)
	and	l, 31
	add	l, 128
	ld	xbc, 64602
	ldb	a, 0
	st_rr8b	l, xbc, a
	ldb	a, 1
	ld_rr8b	h, xbc, a
	and	h, 128
	st_rr8b	h, xbc, a
	ld	a, (64602:16)
	ldb	w, 0
	ldb	e, 72
	ldb	d, 0
	call	16624672
	ret
DrumParam_ProcessChannel:
	push xiz
	calr DrumParam_LookupChannelBit
	call __pad_F67013
	pop xiz
	ret

DrumParam_LookupChannelBit:
	push XWA
	push XIX
	ld a, (0x391c:16)
	ld XIX,PatIdx_Lookup_Return
	.byte 0xc3, 0x03, 0xf0, 0xe0, 0x21, 0xf1, 0x2d, 0x37
	.byte 0x41, 0x5c, 0x58, 0x0e
PatIdx_Lookup_Return:
	normal
	push	sr
	max
	ldio	16, 32
	.byte 0x40

__pad_F67013:
	push_a
	calr DrumParam_ReadVoiceCount
	ld L,A
	.byte 0x15, 0xcf, 0x04, 0x14, 0x1e, 0x9f, 0x00, 0x15
	.byte 0x45, 0x0f, 0x37, 0x00, 0x00, 0xe9, 0x85, 0xc9
	.byte 0x33, 0x07, 0x6e, 0x0e, 0x85, 0x3f, 0x09, 0x69
	.byte 0x04, 0x85, 0x61, 0x68, 0x0c
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
	ldb	w, 0
	ld	(14124:16), w
	xor	bc, bc
	ldb	w, 1
	ld	xix, 14095
	ld	xiy, 14109
VoiceTable_InitEntry_Store:
	ldb_spi	a, 240
	cp_spib	a, 244
	jr	z, 4
	orddm8	(14124), w
VoiceTable_InitEntry_Return:
	sll	w, 1
	inc	1, bc
	cps	bc, 7
	jr	lt, -21
	xor	bc, bc
	ldb	w, 1
	ld	xix, 14102
	ld	xiy, 14116
MultiVoice_SetupChannel:
	ldb_spi	a, 240
	cp_spib	a, 244
	jr	z, 4
	orddm8	(14124), w
MultiVoice_Setup_Loop:
	sll	w, 1
	inc	1, bc
	cps	bc, 7
	jr	lt, -21
	ld	a, (13370:16)
	cp	a, (14123:16)
	jr	z, 6
	ldb	b, 127
	ld	(14124:16), b
MultiVoice_Setup_WriteParam:
	ret

Rhythm_MapChannelToDrumIndex:
	lds32	xbc, 0
	ld	c, (14125:16)
	srl	c, 1
	add	xbc, 16149721
	ld	c, (xbc)
	cps	c, 6
	jr	le, 2
	ldb	c, 0
MultiVoice_Setup_NextChan:
	push c
	lds32 xbc, 0
	pop c
	ret

MultiVoice_Setup_Done:
	nop
	normal
	push	sr
	nop
	pop	sr
	nop
	nop
	nop
	max
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
	calr	65470
	ld	xix, 14102
	add	xix, xbc
	ld	a, (xix)
	ret
RhythmDrum_LoadVoiceParams:
	calr	65457
	ld	xix, 14095
	add	xix, xbc
	lds32	xwa, 0
	ld	a, (xix)
	mul	bc, 10
	add	xbc, xwa
	lds32	xde, 0
	lds32	xhl, 0
	ld	xwa, 14983636
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
	push	xde
	calr	65404
	ld	xix, 14102
	add	xix, xbc
	lds32	xwa, 0
	ld	a, (xix)
	pop	xde
	add	xde, xwa
	sll	xde, 2
	ld	xwa, 14983706
	add	xwa, xde
	ld	xhl, (xwa)
	push	xhl
	calr	65374
	pop	xhl
	ld	xde, xhl
	srl	xde, 8
	srl	xde, 8
	srl	xde, 8
	ld	xwa, 14309
	add	xwa, xbc
	ld	(xwa), e
	push	xhl
	calr	17
	pop	xhl
	srl	xhl, 8
	srl	xhl, 8
	push	l
	lds32	xhl, 0
	pop	l
	calr	93
	ret
VoiceAssign_Process_Return:
	ld (0x905a:16), 0x48
	call SndParam_ApplyProgramChange_Safe
	call VoiceParam_ClampAndValidate_Tramp
	pushw hl
	calr Rhythm_MapChannelToDrumIndex
	popw hl
	ld XIX,0x00003836
	.byte 0xf3, 0x03, 0xf0, 0xe4, 0x47, 0x44, 0x3d, 0x38
	.byte 0x00, 0x00, 0xf3, 0x03, 0xf0, 0xe4, 0x46, 0xcf
	.byte 0xee, 0x01, 0xdb, 0xee, 0x01, 0x45, 0x42, 0x51
	.byte 0xe4, 0x00, 0xd3, 0x07, 0xf4, 0xec, 0x20, 0xdb
	.byte 0xc8, 0x02, 0x00, 0xea, 0xa8, 0xd3, 0x07, 0xf4
	.byte 0xec, 0x22, 0xc9, 0x88, 0xe8, 0xcc, 0x00, 0xff
	.byte 0x00, 0x00, 0xe8, 0xee, 0x08, 0x44, 0x00, 0x00
	.byte 0x40, 0x00, 0xe1, 0xdb, 0x31, 0x84, 0xe8, 0x84
	.byte 0xea, 0x84, 0x68, 0x00
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
	max
	reti
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
	di
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
	push	xde
	push	xbc
	calr	64982
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

	lds32 xwa, 0

	ldb_sri W, 0x07, 0xf0, 0xe4

	and xwa, 0xff00

	sll xwa, 8

	ld xiy, 0x400000

	addda32 xix, (12763)

	add xiy, xwa

	ret



DrumChannel_MapToIndexA:
	cp (0x372d:16), 0x01
	jr nz, .Lc_f66f2a
	lds32 xbc, 0
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch1:
.Lc_f66f2a:
	cp (0x372d:16), 0x02
	jr nz, .Lc_f66f35
	lds32 xbc, 0
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch2:
.Lc_f66f35:
	cp (0x372d:16), 0x04
	jr nz, .Lc_f66f40
	lds32 xbc, 0
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch3:
.Lc_f66f40:
	cp (0x372d:16), 0x08
	jr nz, .Lc_f66f4b
	lds32 xbc, 1
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch4:
.Lc_f66f4b:
	cp (0x372d:16), 0x10
	jr nz, .Lc_f66f56
	lds32 xbc, 2
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch5:
.Lc_f66f56:
	cp (0x372d:16), 0x20
	jr nz, MIDIChan_Dispatch_Ch6
	lds32 xbc, 3
	jr t, DrumChannel_MapA_NullRet
MIDIChan_Dispatch_Ch6:
	lds32 xbc, 4

DrumChannel_MapA_NullRet:
	ret

DrumChannel_MapToIndexB:
	cp (0x372d:16), 0x01
	jr nz, .Lc_f66f6f
	lds32 xbc, 0
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch7:
.Lc_f66f6f:
	cp (0x372d:16), 0x02
	jr nz, .Lc_f66f7a
	lds32 xbc, 0
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch8:
.Lc_f66f7a:
	cp (0x372d:16), 0x04
	jr nz, .Lc_f66f85
	lds32 xbc, 0
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch9:
.Lc_f66f85:
	cp (0x372d:16), 0x08
	jr nz, .Lc_f66f90
	lds32 xbc, 2
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch10:
.Lc_f66f90:
	cp (0x372d:16), 0x10
	jr nz, .Lc_f66f9b
	lds32 xbc, 3
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch11:
.Lc_f66f9b:
	cp (0x372d:16), 0x20
	jr nz, MIDIChan_Dispatch_Ch12
	lds32 xbc, 4
	jr t, DrumChannel_MapB_NullRet
MIDIChan_Dispatch_Ch12:
	lds32 xbc, 5

DrumChannel_MapB_NullRet:
	ret

MIDIChan_DispatchDone:
	push xix

	push xde

	calr 65393

	pop xde

	pop xix

	mul bc, 0x7

	add xbc, xde

	add xbc, 0x248

	add xix, xbc

	calr 64762

	mul bc, 0x8

	add xbc, 14133

	ld xiy, xbc

	lds32 xbc, 7

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
	ldb_dri a, 0x07, 0xf0, 0xe8
	calr Rhythm_MapChannelToDrumIndex
	add XBC,VoiceResolve_SearchDone
	ld C,(XBC)
	and A,C
	cp A,C
	jr nz, VoiceResolve_Return
	ldb A, 0x00
	jr t, __pad_F67412
VoiceResolve_Return:
	ldb a, 0x1

__pad_F67412:
	jr VoiceResolve_InitSearch

Rhythm_ClearChannelDrumIndex:
	ldb a, 0x0

VoiceResolve_InitSearch:
	push_a
	calr	64677
	pop_a
	add	xbc, 14302
	ld	(xbc), a
	ret
VoiceResolve_SearchDone:
	ldio	8, 8
	ldio	8, 16
	.byte 0x20

__pad_F6742B:
	ldw bc, 0x3d0

	ldb_sri A, 0x07, 0xf0, 0xe4

	push xix

	calr 17

	pop xix

	push_a

	push xix

	calr 64642

	pop xix

	pop_a

	add xbc, 14126

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
	add XBC,0x0000370f
	lds32 xwa, 0
	ld A,(XBC)
	sll XWA, 0x04
	ld XIY,Display_FontPalette_Table_0x52DC
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
	calr	68
	pop_a
	calr	64555
	ld	xix, 14102
	add	xix, xbc
	ld	c, (xix)
	cps	a, 0
	jr	nz, 8
	cp	c, w
	jr	ge, 22
	inc	1, c
	jr	18
PartVoice_Update_Loop:
	.byte 0xcb, 0xd8, 0x66, 0x0e, 0xcb, 0x69, 0xf1, 0x2d
	.byte 0x37, 0xc8, 0x66, 0x06, 0xcb, 0xd9, 0x69, 0x02
	.byte 0x23, 0x01
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
	ld XHL,XBC
	add XHL,0x0000370f
	ld L,(XHL)
	mul BC,0x000a
	ld XWA,Display_FontPalette_Table_0x537C
	add XWA,XBC
	.byte 0xc3, 0x03, 0xe0, 0xec, 0x20, 0xc8, 0x69, 0x0e
ExtVoice_ProcessList:
	ret
	push XIZ
	call ExtVoice_ProcessList_0x8
	pop XIZ
	ret
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	nz, 13
	.byte 0xc1, 0x31, 0x34, 0x3e, 0x80
	call	16068317
	call	16094919
	ret
	push	xiz
	call	16150803
	pop	xiz
	ret
	call	16094901
	calr	80
	call	16068317
	.byte 0xc1, 0x2d, 0x37, 0x04
	calr	78
	calr	115
	ld	(32422:16), 0
	calr	113
	cp	(32422:16), 0
	jr	z, 11
	call	16116191
	.byte 0xc1, 0x2c, 0x37, 0x3e, 0x7f
	jr	5
	ld	(14124:16), 0
	.byte 0xf1, 0x2d, 0x37, 0x04, 0xc1, 0x31, 0x34, 0x3e, 0x80
	call	16068317
	cp	(32422:16), 0
	jr	nz, 6
	call	16094919
	jr	3
	calr	1
	ret
	call	16143598
	ret
	.byte 0xf1, 0x1e, 0x04, 0xca
	jr	z, 2
	jr	-8
	ret
	ld	(14125:16), 1
	calr	-1216
	ld	xwa, 14126
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, (13373:16)
	jr	z, 16
	ld	(14124:16), 127
	ld	(13373:16), a
	calr	-325
	ld	(13372:16), a
	ret
	ld	(13371:16), 3
	ret
	.byte 0xf1, 0x2c, 0x37, 0xcb
	jr	z, 27
	ld	(14125:16), 8
	calr	150
	calr	-1271
	ld	xix, 14302
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	337
	.byte 0xf1, 0x2c, 0x37, 0xcc
	jr	z, 27
	ld	(14125:16), 16
	calr	117
	calr	-1304
	ld	xix, 14302
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	304
	.byte 0xf1, 0x2c, 0x37, 0xcd
	jr	z, 27
	ld	(14125:16), 32
	calr	84
	calr	-1337
	ld	xix, 14302
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	271
	.byte 0xf1, 0x2c, 0x37, 0xce
	jr	z, 27
	ld	(14125:16), 64
	calr	51
	calr	-1370
	ld	xix, 14302
	.byte 0xc3, 0x07, 0xf0, 0xe4, 0x3f, 0x00
	jr	nz, 3
	calr	238
	.byte 0xf1, 0x2c, 0x37, 0xc8
	jr	nz, 14
	.byte 0xf1, 0x2c, 0x37, 0xc9
	jr	nz, 8
	.byte 0xf1, 0x2c, 0x37, 0xca
	jr	nz, 2
	jr	11
	ld	(14125:16), 1
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
	.byte 0xdb, 0xcf, 0xff, 0xff, 0x66, 0x2d, 0x1e, 0x8b
	.byte 0x00, 0x38, 0xe8, 0xc8, 0x03, 0x00, 0x00, 0x00
	.byte 0x90, 0x23, 0xb0, 0x02, 0xff, 0xff, 0x58, 0x38
	.byte 0xe8, 0xc8, 0x01, 0x00, 0x00, 0x00, 0xb0, 0x02
	.byte 0xff, 0xff, 0x58, 0x38, 0x80, 0x3c, 0x7f, 0x58
	.byte 0x2b, 0x1e, 0x09, 0x00, 0x4b, 0xd1, 0x38, 0x34
	.byte 0x61, 0x68, 0xcd
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

	ld c, (13371:16)

	inc 1, c

	.byte 0xc1, 0x3d, 0x34, 0x43	; mul_sd16b 3, 0xd9, 0x34 (v7 patched)



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
	lds32	xhl, 0
	ld	l, (13370:16)
	cp	l, 30
	jr	lt, 2
	ldb	l, 0
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 437 of 592 slots byte-identical
	calr	63909
	add	xbc, 14102
	ld	a, (xbc)
	cps	a, 0
	jr	z, 9
	calr	7
	calr	43
	calr	65
	ret
	calr	63884
	sll	xbc, 3
	add	xbc, 14133
	ld	xiy, xbc
	calr	65445
	push	xix
	calr	64478
	pop	xix
	sll	bc, 3
	add	bc, 24
	add	xix, xbc
	ld	xbc, 8
	.byte 0x85	; v10 does not spell this byte either
	scf
	ret
	calr	65420
	calr	64523
	sll	bc, 1
	ld_rrw	hl, xix, bc
	ld	(13686:16), hl
	ldw	(13688:16), 6
	ret
	ldb	c, 0
	ld	(14389:16), c
	ld	c, (13371:16)
	inc	1, c
	cp	c, (14389:16)
	jr	le, 19
	push	c
	calr	18
	pop	c
	ld	a, (14389:16)
	inc	1, a
	ld	(14389:16), a
	jr	-25
	calr	466
	ret
	calr	52
	push	xwa
	calr	63775
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ldb	a, 0
	ld	(14388:16), a
	ld	c, (13373:16)
	cp	(14388:16), c
	jr	ge, 19
	push	c
	calr	41
	ld	a, (14388:16)
	inc	1, a
	ld	(14388:16), a
	pop	c
	jr	-25
	ret
	calr	63724
	sll	xbc, 4
	add	xbc, 14190
	lds32	xwa, 0
	ld	a, (14389:16)
	sll	xwa, 2
	add	xbc, xwa
	ld	xwa, (xbc)
	ret
	calr	53
	cp	a, 131
	jr	nz, 30
	calr	63690
	sll	bc, 2
	add	xbc, 14332
	ld	xwa, 16151577
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
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, 16151577
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
	add	xbc, 14332
	ld	xiy, (xbc)
	ld	a, (xiy)
	lds32	xbc, 0
	calr	65457
	ld	hl, (13686:16)
	pushw	bc
	calr	65134
	popw	bc
	ld	xix, xwa
	lds32	xwa, 0
	ld	wa, (13688:16)
	add	xix, xwa
	ldw	de, 255
	subda16	xde, (13688)
	cp	bc, de
	jr	gt, 12
	.byte 0xd1	; v10 does not spell this byte either
	.byte 0x78	; differs from v10 here and llvm-objdump cannot read it
	ldw	iy, 55689
	inc	6, wa
	push	sr
	.byte 0x85	; v10 does not spell this byte either
	scf
	jr	60
	pushw	bc
	ld	bc, de
	.byte 0xd1	; v10 does not spell this byte either
	.byte 0x78	; differs from v10 here and llvm-objdump cannot read it
	ldw	iy, 55689
	inc	6, wa
	push	sr
	.byte 0x85	; v10 does not spell this byte either
	scf
	popw	bc
	push	xiy
	sub	bc, de
	ld	(13217:16), bc
	ld	(13219:16), de
	calr	64
	ld	hl, (13686:16)
	calr	65065
	ld	xix, xwa
	lds32	xwa, 0
	ld	wa, (13688:16)
	add	xix, xwa
	pop	xiy
	ld	bc, (13217:16)
	.byte 0xd1	; v10 does not spell this byte either
	.byte 0x78	; differs from v10 here and llvm-objdump cannot read it
	ldw	iy, 55689
	inc	6, wa
	push	sr
	.byte 0x85	; v10 does not spell this byte either
	scf
	push	xiy
	calr	63431
	sll	xbc, 2
	add	xbc, 14332
	pop	xiy
	ld	(xbc), xiy
	cp	xiy, 16151578
	jr	nz, 7
	ld	xiy, 16151577
	ld	(xbc), xiy
	ret
	.byte 0xd1	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	ldw	ix, 63
	nop
	jr	z, 66
	ldw	hl, 150
	pushw	hl
	calr	64993
	popw	hl
	.byte 0xb0	; v10 does not spell this byte either
	inc	6, l
	.byte 0x04	; v10 does not spell this byte either
	inc	1, hl
	jr	-13
	ld	c, (xwa)
	or	c, 128
	ld	(xwa), c
	lds	de, 1
	ld	bc, (13686:16)
	st_rrw	bc, xwa, de
	pushw	hl
	ld	hl, (13686:16)
	calr	64958
	lds	de, 3
	popw	hl
	st_rrw	hl, xwa, de
	decw	1, (13368:16)
	ld	(13686:16), hl
	lds	wa, 6
	ld	(13688:16), wa
	jr	11
	lds	wa, 6
	ld	(13688:16), wa
	ld	(32422:16), 15
	ret
	calr	63314
	sll	bc, 2
	add	xbc, 14332
	ld	xwa, 16151935
	ld	(xbc), xwa
	ldb	c, 1
	calr	65271
	ret
	ld	a, (xhl)
	normal
	ld	(14125:16), a
	calr	64931
	calr	7
	calr	64964
	calr	124
	ret
	calr	64844
	ld	w, (13372:16)
	ldb	a, 12
	st_rr8b	w, xix, a
	ld	w, (13371:16)
	ldb	a, 13
	.byte 0xf3	; v10 does not spell this byte either
	pop	sr
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0x40	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x21	; v10 does not spell this byte either
	ret
	.byte 0xf3	; v10 does not spell this byte either
	pop	sr
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xe0	; v10 does not spell this byte either
	ld	xwa, 253820960
	.byte 0xf3	; v10 does not spell this byte either
	pop	sr
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xe0	; v10 does not spell this byte either
	ld	xwa, 770769185
	.byte 0x37	; v10 does not spell this byte either
	ld	xbc, 4143128124
	pop	xix
	ld	xiy, 14390
	ld_rr8b	w, xiy, c
	ldb	a, 16
	st_rr8b	w, xix, a
	ld	xiy, 14397
	ld_rr8b	w, xiy, c
	ldb	a, 17
	st_rr8b	w, xix, a
	ld	xiy, 16152062
	add	xix, 64
	lds32	xbc, 0
	ldw	bc, 16
	.byte 0x85	; v10 does not spell this byte either
	scf
	ret
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
	.byte 0x23	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	ld	(14389:16), c
	ld	c, (13371:16)
	add	c, 1
	cp	c, (14389:16)
	jr	le, 19
	push	c
	calr	18
	pop	c
	ld	a, (14389:16)
	inc	1, a
	ld	(14389:16), a
	jr	-25
	calr	65327
	ret
	ldb	a, 1
	ld	(14125:16), a
	calr	64907
	push	xwa
	calr	63094
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ldb	a, 2
	ld	(14125:16), a
	calr	64882
	push	xwa
	calr	63069
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ldb	a, 4
	ld	(14125:16), a
	calr	64857
	push	xwa
	calr	63044
	pop	xwa
	sll	xbc, 2
	add	xbc, 14332
	ld	(xbc), xwa
	ldb	a, 0
	ld	(14388:16), a
	ld	c, (13373:16)
	cp	(14388:16), c
	jr	ge, 19
	push	c
	calr	15
	ld	a, (14388:16)
	inc	1, a
	ld	(14388:16), a
	pop	c
	jr	-25
	ret
	ldb	a, 1
	ld	(14125:16), a
	calr	123
	ldb	a, 2
	ld	(14125:16), a
	calr	114
	ldb	a, 4
	ld	(14125:16), a
	calr	105
	calr	329
	push	l
	calr	168
	pop	l
	cps	w, 0
	jr	z, 13
	calr	224
	ld	(14125:16), l
	calr	64923
	jrl	-54
	ldb	a, 1
	ld	(14125:16), a
	lds32	xbc, 0
	ldb	c, 1
	calr	64907
	ldb	a, 2
	ld	(14125:16), a
	calr	62920
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, 16151577
	jr	z, 4
	inc	1, xwa
	ld	(xbc), xwa
	ldb	a, 4
	ld	(14125:16), a
	calr	62888
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	cp	xwa, 16151577
	jr	z, 4
	inc	1, xwa
	ld	(xbc), xwa
	ret
	calr	62861
	add	xbc, 14102
	ld	a, (xbc)
	cps	a, 0
	jr	z, 33
	calr	275
	calr	62843
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, (xbc)
	ld	l, (xwa)
	cp	l, 131
	jr	nz, 7
	ld	xwa, 16151577
	ld	(xbc), xwa
	jr	19
	calr	62813
	sll	xbc, 2
	add	xbc, 14332
	ld	xwa, 16151577
	ld	(xbc), xwa
	calr	92
	ret
	ldb	a, 1
	ld	(14125:16), a
	calr	40
	cp	a, 129
	jr	nz, 32
	ldb	a, 2
	ld	(14125:16), a
	calr	26
	cp	a, 129
	jr	nz, 18
	ldb	a, 4
	ld	(14125:16), a
	calr	12
	cp	a, 129
	jr	nz, 4
	ldb	w, 0
	jr	2
	ldb	w, 1
	ret
	ld	xix, 13201
	push	xix
	calr	62735
	pop	xix
	ld_rr8b	a, xix, c
	ret
	push	l
	lds32	xhl, 0
	pop	l
	and	l, 7
	add	xhl, 16152517
	ld	l, (xhl)
	ret
	normal
	push	sr
	max
	ldio	16, 32
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
	ld	xix, 13201
	cps	l, 2
	jr	gt, 46
	cps	a, 2
	jr	gt, 42
	.byte 0xc3	; v10 does not spell this byte either
	pop	sr
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xec	; v10 does not spell this byte either
	ldb	h, 206
	ldw	hl, 26119
	.byte 0x04	; v10 does not spell this byte either
	inc	1, l
	jr	26
	.byte 0xc3	; v10 does not spell this byte either
	pop	sr
	.byte 0xf0	; v10 does not spell this byte either
	.byte 0xe0	; v10 does not spell this byte either
	ldb	w, 200
	ldw	hl, 26119
	.byte 0x04	; v10 does not spell this byte either
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
	add	xbc, 14332
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
	cp	c, (14125:16)
	jr	z, 23
	calr	62513
	sll	xbc, 2
	add	xbc, 14332
	ld	xix, (xbc)
	push	xbc
	calr	42
	pop	xbc
	ld	(xbc), xix
	jr	-64
	ret
	push_a
	calr	62488
	ld	xwa, 14309
	.byte 0xc3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	ldb	e, 205
	.byte 0x04	; v10 does not spell this byte either
	lds32	xde, 0
	pop	e
	sll	de, 7
	add	xde, Display_FontPalette_Table_0x6E9A
	pop_a
	ld_rr8b	c, xde, a
	ret
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

__pad_F67D15:
	push	xiz
	call	16152856
	pop	xiz
	ret
	ld	e, (14125:16)
	and	e, 1
	cps	e, 1
	jr	z, 70
	ld	e, (14125:16)
	and	e, 2
	cps	e, 2
	jr	z, 66
	ld	e, (14125:16)
	and	e, 4
	cps	e, 4
	jr	z, 48
	ld	e, (14125:16)
	and	e, 8
	cp	e, 8
	jr	z, 57
	ld	e, (14125:16)
	and	e, 16
	cp	e, 16
	jr	z, 52
	ld	e, (14125:16)
	and	e, 32
	cp	e, 32
	jr	z, 47
	ld	e, (14125:16)
	and	e, 64
	cp	e, 64
	jr	z, 42
	ld	(14620:16), 0
	jr	42
	ld	(14620:16), 1
	jr	35
	ld	(14620:16), 2
	jr	28
	ld	(14620:16), 3
	jr	21
	ld	(14620:16), 4
	jr	14
	ld	(14620:16), 5
	jr	7
	ld	(14620:16), 6
	jr	0
	ret
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
	lda xix, (CmpMenuTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpMenuTtlFunc title dispatch
CmpMenuTtl_Dispatch:
	set	2, (0x28a7:16)
	call	AccWrap_PlayModeDispatch
	jr	t, 0x46

; CmpMenuTtl special key handler (0x88-0x8a)
CmpMenuTtl_SpecialKeys:
	.byte 0xc1, 0x31, 0x34, 0x21, 0xea, 0xcf, 0x8a, 0x00
	.byte 0x00, 0x00, 0x66, 0x29, 0xea, 0xcf, 0x89, 0x00
	.byte 0x00, 0x00, 0x66, 0x12, 0xea, 0xcf, 0x88, 0x00
	.byte 0x00, 0x00, 0x6e, 0x2a, 0xc1, 0x31, 0x34, 0x3c
	.byte 0xcf, 0x30, 0xb1, 0x00, 0x68, 0x1c
CmpMenuTtl_SetBit5:
	and	a, 207
	set	5, a
	ld	(13361:16), a
	ldw	wa, 177
	jr	13
CmpMenuTtl_SetBit4:
	and	a, 207
	set	4, a
	ld	(13361:16), a
	ldw	wa, 177
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
	lda xix, (CmpSetTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch
CmpSetTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xb4, 0x76, 0x51, 0x01
	.byte 0x1d, 0x08, 0x4e, 0xf6, 0x40, 0x07, 0x00, 0xb4
	.byte 0x00, 0x41, 0x8e, 0x00, 0xe0, 0x01, 0x42, 0x01
	.byte 0x00, 0xff, 0xff, 0x1d, 0xfa, 0x99, 0xfa, 0x78
	.byte 0x37, 0x01, 0xc1, 0x9a, 0x8c, 0x3f, 0xb4, 0x76
	.byte 0x2f, 0x01, 0x1d, 0x36, 0x4e, 0xf6, 0x78, 0x28
	.byte 0x01
CmpSetTtl_ModeSwitch:
	.byte 0xc1, 0x70, 0x34, 0x3f, 0x00, 0x7e, 0x85, 0x00
	.byte 0xea, 0xcf, 0x85, 0x00, 0x00, 0x00, 0x66, 0x6c
	.byte 0xea, 0xcf, 0x84, 0x00, 0x00, 0x00, 0x66, 0x64
	.byte 0xea, 0xcf, 0x05, 0x00, 0x00, 0x00, 0x66, 0x4b
	.byte 0xea, 0xcf, 0x04, 0x00, 0x00, 0x00, 0x66, 0x43
	.byte 0xea, 0xcf, 0x82, 0x00, 0x00, 0x00, 0x66, 0x2a
	.byte 0xea, 0xcf, 0x81, 0x00, 0x00, 0x00, 0x66, 0x22
	.byte 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x66, 0x09
	.byte 0xea, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x7e, 0xdf
	.byte 0x00
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
	lda xix, (CmpSetTtl_Dispatch2:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpSetTtlFunc title dispatch 2
CmpSetTtl_Dispatch2:
	.asciz ":;<> "
CmpSetTtl_Dispatch2_Code:
	call	16145736
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	78
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 128
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
	ldb	w, 0
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
	ldb	w, 128
	call	16145771
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	30
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16145833
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	14
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 128
	call	16145833
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
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
	lda xix, (CmpRealTtl_Dispatch:24)
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
	lda xix, (CmpRealTtl_RhythmVar0:24)
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
	push XDE
	push XHL
	push XIX
	push XIZ
	lds hl, 4
	call RhythmVariation_Wrapper
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	ld XWA,0x00b50019
	ld XBC,0x01c0000b
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x1b
	.byte 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x1a
	.byte 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x18
	.byte 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x1c
	.byte 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x68, 0x78, 0xf1, 0x33, 0x34, 0xb9
	.byte 0x68, 0x76, 0x3a, 0x3b, 0x3c, 0x3e, 0x1d, 0x89
	.byte 0x4b, 0xf6, 0x5e, 0x5c, 0x5b, 0x5a, 0x40, 0x1d
	.byte 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x68, 0x58, 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0x21, 0x4c, 0xf6, 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0x40, 0x19, 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x1b, 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x1a, 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x18, 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x1c, 0x00, 0xb5, 0x00, 0x41, 0x0b, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8
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
	lda xix, (CmpBkslTtl_Dispatch:24)
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
	lda xix, (CmpBkslSTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpBksl_STtlFunc title dispatch
CmpBkslSTtl_Dispatch:
	.ascii ":;<>"
CmpBkslSTtl_Dispatch_Code:
	call	16140770
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(32422:16), 0
	jrl	334
	ld	(13424:16), 0
	jrl	326
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16140770
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	311
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
	lda xix, (CmpBkslSTtl_FillIn4:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; CmpBkslSTtl fill-in level 4
CmpBkslSTtl_FillIn4:
	.byte 0xc1, 0x70, 0x34, 0x3f, 0x00	; cpdi8 (0x350c), 0 (v7 patched)

	.byte 0x7e, 0xdb, 0x00	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)

	push xde

	push xhl

	push xix

	push xiz

	lds hl, 4

	call	16141083

	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	.byte 0x78, 0xc3, 0x00	; jrl CmpBk_PostModeChange (v7 displacement)



; CmpBkslSTtl fill-in level 5

CmpBkslSTtl_FillIn5:
	.byte 0xc1, 0x70, 0x34, 0x3f, 0x00	; cpdi8 (0x350c), 0 (v7 patched)

	.byte 0x7e, 0xbf, 0x00	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)

	push xde

	push xhl

	push xix

	push xiz

	lds hl, 5

	.byte 0x1d, 0x1b, 0x4b, 0xf6	; call RhythmFillIn_Wrapper (v7 addr)

	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	.byte 0x78, 0xa7, 0x00	; jrl CmpBk_PostModeChange (v7 displacement)



; CmpBkslSTtl fill-in level 6

CmpBkslSTtl_FillIn6:
	.byte 0xc1, 0x70, 0x34, 0x3f, 0x00	; cpdi8 (0x350c), 0 (v7 patched)

	.byte 0x7e, 0xa3, 0x00	; jrl nz, DisplayFunc_ReturnZero (v7 displacement)

	push xde

	push xhl

	push xix

	push xiz

	lds hl, 6

	.byte 0x1d, 0x1b, 0x4b, 0xf6	; call RhythmFillIn_Wrapper (v7 addr)

	pop xiz

	pop xix

	pop xhl

	pop xde

	ldw wa, 0xb5

	.byte 0x78, 0x8b, 0x00	; jrl CmpBk_PostModeChange (v7 displacement)



; CmpBkslSTtl fill-in level 7

CmpBkslSTtl_FillIn7:
	cp (0x3470:16), 0x00
	jrl nz, DisplayFunc_ReturnZero
	push XDE
	push XHL
	push XIX
	push XIZ
	lds hl, 7
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
	.byte 0xc2, 0xea, 0x40, 0x03, 0x3f, 0x00
	jr	nz, 18
	.byte 0xf1, 0x31, 0x34, 0xba
	ld	(32422:16), 35
	ldw	wa, 238
	call	16355504
	jr	56
CmpBkslSTtl_EventPost:
	ld	(13424:16), 1
	ld	xwa, 11665426
	ld	xbc, 29360129
	lds32	xde, 5
	call	16423243
	jr	33
	cp	(13424:16), 0
	jr	nz, 26
	cp	(13370:16), 12
	jr	nc, 19
	ldw	wa, 179
	jr	10
	cp	(13424:16), 0
	jr	nz, 7
	ldw	wa, 180
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
	lda xix, (CmpNcpTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 1482
	lds	wa, 1
	call	16355608
	lds	wa, 2
	call	16355680
	ldw	wa, 130
	jr	95
	lds	wa, 1
	call	16355608
	lds	wa, 6
	call	16355680
	ldw	wa, 134
	jr	78
	lds	wa, 0
	call	16355608
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16142746
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jrl	1427
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
	cps	a, 1
	jr	z, 22
	cps	a, 0
	jrl	nz, 1402
	lds	wa, 1
	call	16355608
	lds	wa, 2
	call	16355680
	ldw	wa, 130
	jr	15
	lds	wa, 1
	call	16355608
	lds	wa, 6
	call	16355680
	ldw	wa, 134
	call	16355660
	jrl	1363
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
	lda xix, (CmpNcpTtl_Dispatch2:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CmpNcpTtlFunc title dispatch 2
CmpNcpTtl_Dispatch2:
	; framing ported from v10's source for the same label (same span length, statement for statement); 297 of 450 slots byte-identical
	lds	wa, 1
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16142764
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	nop
	jr	z, 56
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1171
	lds	wa, 1
	call	UI_PostEvent_0x6E
	.byte 0x3a	; v10 does not spell this byte either
	.byte 0x3b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x3e	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x80	; v10 does not spell this byte either
	call	16142764
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	nop
	jr	z, 56
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	1041
	lds	wa, 1
	.byte 0x1d	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	cp	(xbc), bc
	.byte 0x3a	; v10 does not spell this byte either
	.byte 0x3b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x3e	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x00	; v10 does not spell this byte either
	call	16142799
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	nop
	jr	z, 56
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	a, (14603:16)
	cps	a, 2
	jr	z, 87
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 951
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	894
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	863
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	832
	lds	wa, 1
	call	UI_PostEvent_0x6E
	.byte 0x3a	; v10 does not spell this byte either
	.byte 0x3b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x3e	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x80	; v10 does not spell this byte either
	call	16142799
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	nop
	jr	z, 56
	ld	(14820:16), 0
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 2
	call	UI_PostDialValueEvent
	ldw	wa, 130
	call	UI_PostDialRangeEvent
	ld	a, (14603:16)
	cps	a, 2
	jr	z, 87
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 742
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	685
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	654
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	623
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16142834
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	normal
	jr	z, 72
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	499
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
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	normal
	jr	z, 72
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	375
	lds	wa, 1
	call	UI_PostEvent_0x6E
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16142869
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	normal
	jr	z, 72
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	a, (14604:16)
	cps	a, 1
	jr	z, 52
	cps	a, 0
	jrl	nz, 273
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	216
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	185
	lds	wa, 1
	.byte 0x1d	; v10 does not spell this byte either
	.byte 0x38	; v10 does not spell this byte either
	cp	(xbc), bc
	.byte 0x3a	; v10 does not spell this byte either
	.byte 0x3b	; v10 does not spell this byte either
	.byte 0x3c	; v10 does not spell this byte either
	.byte 0x3e	; v10 does not spell this byte either
	.byte 0x20	; v10 does not spell this byte either
	.byte 0x80	; v10 does not spell this byte either
	call	16142869
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	.byte 0xc1	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	push	xbc
	push	xsp
	normal
	jr	z, 72
	ld	(14820:16), 1
	ld	xwa, 12058654
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058655
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	lds	wa, 1
	call	UI_PostDialEnable
	lds	wa, 6
	call	UI_PostDialValueEvent
	ldw	wa, 134
	call	UI_PostDialRangeEvent
	ld	a, (14604:16)
	cps	a, 1
	jr	z, 50
	cps	a, 0
	jr	nz, 84
	ld	xwa, 12058650
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	jr	28
	ld	xwa, 12058651
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12058642
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	jr	4
	.byte 0xf1	; v10 does not spell this byte either
	.byte 0x35	; v10 does not spell this byte either
	.byte 0x34	; v10 does not spell this byte either
	.byte 0xb8	; v10 does not spell this byte either
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
	lda xix, (CmEsyTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
CmEsyTtl_Dispatch:
	cp	(35995:16), 186
	jrl	z, 388
	ld	a, (13370:16)
	cp	a, 29
	jr	ule, 10
	sub	a, 30
	sll	a, 2
	ld	(13370:16), a
	.byte 0xc1, 0x2c, 0x37, 0x3e, 0x7f, 0xf1, 0xa7, 0x28, 0xb2, 0xf1, 0x31, 0x34, 0xb6
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16140570
	call	16140231
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(13397:16), 0
	ld	xwa, 12189706
	ld	xbc, 31457422
	ld	xde, 4294901762
	jrl	219
	cp	(14109:16), 255
	jrl	z, 309
	lda	xiy, (14109:16)
	lda	xix, (14095:16)
	lda	xhl, (14116:16)
	lda	xde, (14102:16)
	lds32	xbc, 0
	ldb_spi	a, 244
	lda_dpi	xbc, 240
	ldb_spi	a, 236
	lda_dpi	xbc, 232
	inc	1, xbc
	cp	xbc, 7
	jr	c, -22
	.byte 0xc1, 0x2b, 0x37, 0x19, 0x3a, 0x34
	jrl	260
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
	lda xix, (CmEsyTtl_Dispatch2:24)
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
	call	16423418
	jr	92
	cp	(14124:16), 0
	jr	z, 67
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16150796
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	cp	(32422:16), 0
	jr	nz, 60
	lda	xiy, (14095:16)
	lda	xix, (14109:16)
	lda	xhl, (14102:16)
	lda	xde, (14116:16)
	lds32	xbc, 0
CmpEsyTtl_SubModeB:
	ldb_spi	a, 244
	lda_dpi	xbc, 240
	ldb_spi	a, 236
	lda_dpi	xbc, 232
	inc	1, xbc
	cp	xbc, 7
	jr	c, -22
	.byte 0xc1, 0x3a, 0x34, 0x19, 0x2b, 0x37
	jr	12
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
	lda xix, (S2cTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; S2cTtlFunc title dispatch
S2cTtl_Dispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 23 of 34 slots byte-identical
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xb9	; differs from v10 here and llvm-objdump cannot read it
	jr	z, 19
	ld	xwa, 12124193
	ld	xbc, 31457422
	ld	xde, 4294901762
	call	ApDeliveryEvent
	call	16145895
	jrl	999
	ld	a, (14811:16)
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
	lda xix, (CmpEsy_E_DispatchDataBlock:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

CmpEsy_E_DispatchDataBlock:
	; framing ported from v10's source for the same label (same span length, statement for statement); 26 of 37 slots byte-identical
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
	.byte 0xc1, 0xdb, 0x39, 0x3f, 0x00	; differs from v10 here and llvm-objdump cannot read it
	jr	nz, 31
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	jrl	769
	ld	(14811:16), 0
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12124184
	ld	xbc, 29360140
	lds32	xde, 0
	call	ApDeliveryEvent
	ld	xwa, 12124193
	ld	xbc, 31719473
	lds32	xde, 0
	jrl	701
CmpEsyTtl_E_Var2:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 0
	call UI_PostDialValueEvent
	ldw WA, 0x0080
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustStartMeasure
	cp (0x39db:16), 0x00
	jr nz, .Lc_f68b9c
	ld XWA,0x00b9001c
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b9001f
	ld XBC,0x01c0000c
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_E_Var2_StoreMeasure:
.Lc_f68b9c:
	ld (0x39db:16), 0x00
	ld XWA,0x00b9001c
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b9001f
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b90018
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b90021
	ld XBC,0x01e40031
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 1
	call UI_PostDialValueEvent
	ldw WA, 0x0081
	call UI_PostDialRangeEvent
	lds wa, 0
	call Tempo_AdjustEndMeasure
	cp (0x39db:16), 0x01
	jr nz, CmpEsy_E_EndMeasure_Store
	ld XWA,0x00b9001f
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,0x01c0000c
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_E_EndMeasure_Store:
	ld	(14811:16), 1
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124184
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124193
	ld	xbc, 31719473
	lds32	xde, 0
	jrl	427
S2cTtl_MainHandler:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 1
	call UI_PostDialValueEvent
	ldw WA, 0x0081
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustEndMeasure
	cp (0x39db:16), 0x01
	jr nz, .Lc_f68cae
	ld XWA,0x00b9001f
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,0x01c0000c
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_Main_EndMeasure_Store:
.Lc_f68cae:
	ld (0x39db:16), 0x01
	ld XWA,0x00b9001f
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b9001c
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b90018
	ld XBC,0x01c0000c
	lds32 xde, 0
	call ApDeliveryEvent
	ld XWA,0x00b90021
	ld XBC,0x01e40031
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 2
	call UI_PostDialValueEvent
	ldw WA, 0x0082
	call UI_PostDialRangeEvent
	lds wa, 0
	call Tempo_AdjustQuantize
	cp (0x39db:16), 0x02
	jr nz, CmpEsy_Quantize_Store
	ld XWA,0x00b90018
	ld XBC,0x01c0000c
	lds32 xde, 0
	jrl t, TtlFunc_SendEventAndReturn
CmpEsy_Quantize_Store:
	ld	(14811:16), 2
	ld	xwa, 12124184
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124193
	ld	xbc, 31719473
	lds32	xde, 0
	jrl	169
S2cTtl_SecondaryHandler:
	lds wa, 1
	call UI_PostEvent_0x6E
	lds wa, 1
	call UI_PostDialEnable
	lds wa, 2
	call UI_PostDialValueEvent
	ldw WA, 0x0082
	call UI_PostDialRangeEvent
	lds wa, 1
	call Tempo_AdjustQuantize
	cp (0x39db:16), 0x02
	jr nz, CmpEsy_SecQuantize_Store
	ld XWA,0x00b90018
	ld XBC,0x01c0000c
	lds32 xde, 0
	jr t, TtlFunc_SendEventAndReturn
CmpEsy_SecQuantize_Store:
	ld	(14811:16), 2
	ld	xwa, 12124184
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124191
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124188
	ld	xbc, 29360140
	lds32	xde, 0
	call	16423418
	ld	xwa, 12124193
	ld	xbc, 31719473
	lds32	xde, 0
	jr	50
	lds	wa, 1
	call	16355640
	lds	wa, 0
	call	16146304
	ld	xwa, 12124190
	ld	xbc, 29360140
	lds32	xde, 0
	jr	24
	lds	wa, 1
	call	16355640
	lds	wa, 0
	call	16146337
	ld	xwa, 12124190
	ld	xbc, 29360140
	lds32	xde, 0
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
	lda xix, (CstmCpTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch
CstmCpTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xbe	; cpdi8	(0x8d37), 190 (v7 patched)

	jr	z, 8

	.byte 0xf1, 0xe2, 0x39, 0x00, 0x00	; stdi8	(0x3a7e), 0 (v7 patched)

	jrl	804

	.byte 0xc1, 0x9d, 0x8c, 0x3f, 0xee	; cpdi8	(0x8d39), 238 (v7 patched)

	jrl	nz, 796

	ld a, (14818:16)

	cps	a, 2

	jr	z, 5

	cps	a, 1

	jrl	nz, 783

	.byte 0xc1, 0x1a, 0x39, 0x3f, 0x03	; cpdi8	(0x39b6), 3 (v7 patched)

	jr	nc, 15

	ld	xwa, 0xbe0011

	ld	xbc, 0x01c00001

	lds32	xde, 5

	jrl	708

	ld	xwa, 0xbe0019

	ld	xbc, 0x01c00001

	lds32	xde, 5

	jrl	693

	ld a, (14818:16)

	cps	a, 2

	jr	z, 5

	cps	a, 1

	jrl	nz, 733

	.byte 0xc1, 0x1a, 0x39, 0x3f, 0x03	; cpdi8	(0x39b6), 3 (v7 patched)

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
	lda xix, (CstmCpTtl_Dispatch2:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; CstmCpTtlFunc title dispatch 2
CstmCpTtl_Dispatch2:
	.byte 0xc1, 0xe2, 0x39, 0x3f, 0x00, 0x7e, 0x7c, 0x02
	.byte 0xd8, 0xa9, 0x1d, 0x38, 0x91, 0xf9, 0x23, 0x1d
	.byte 0xc1, 0x1a, 0x39, 0x21, 0xc9, 0xcf, 0x0a, 0x6f
	.byte 0x02, 0x23, 0x02, 0xcb, 0xf1, 0x7f, 0x64, 0x02
	.byte 0xc9, 0x61, 0xf1, 0x1a, 0x39, 0x41, 0x40, 0x03
	.byte 0x00, 0xbe, 0x00, 0x41, 0x0b, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x04
	.byte 0x00, 0xbe, 0x00, 0x41, 0x0d, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x78, 0x42, 0x01, 0xc1, 0xe2, 0x39
	.byte 0x3f, 0x00, 0x7e, 0x37, 0x02, 0xd8, 0xa9, 0x1d
	.byte 0x38, 0x91, 0xf9, 0x23, 0x0a, 0xc1, 0x1a, 0x39
	.byte 0x21, 0xc9, 0xcf, 0x0a, 0x6f, 0x02, 0x23, 0x00
	.byte 0xcb, 0xf1, 0x73, 0x1f, 0x02, 0xc9, 0x69, 0xf1
	.byte 0x1a, 0x39, 0x41, 0x40, 0x03, 0x00, 0xbe, 0x00
	.byte 0x41, 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0xfa, 0x99, 0xfa, 0x40, 0x04, 0x00, 0xbe, 0x00
	.byte 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78
	.byte 0xfd, 0x00, 0xc1, 0xe2, 0x39, 0x3f, 0x00, 0x7e
	.byte 0xf2, 0x01, 0xc1, 0x1a, 0x39, 0x21, 0xc1, 0x1b
	.byte 0x39, 0x23, 0xf1, 0x1a, 0x39, 0x43, 0xf1, 0x1b
	.byte 0x39, 0x41, 0x40, 0x03, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x0b, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x0d, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x0e, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x04, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x0f, 0x00, 0xbe, 0x00, 0x41
	.byte 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78, 0x86
	.byte 0x00, 0xc1, 0xe2, 0x39, 0x3f, 0x00, 0x7e, 0x7b
	.byte 0x01, 0xd8, 0xa9, 0x1d, 0x38, 0x91, 0xf9, 0x23
	.byte 0x1d, 0xc1, 0x1b, 0x39, 0x21, 0xc9, 0xcf, 0x0a
	.byte 0x6f, 0x02, 0x23, 0x02, 0xcb, 0xf1, 0x7f, 0x63
	.byte 0x01, 0xc9, 0x61, 0xf1, 0x1b, 0x39, 0x41, 0x40
	.byte 0x0b, 0x00, 0xbe, 0x00, 0x41, 0x0b, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0x40
	.byte 0x0f, 0x00, 0xbe, 0x00, 0x41, 0x0d, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x68, 0x42, 0xc1, 0xe2, 0x39
	.byte 0x3f, 0x00, 0x7e, 0x37, 0x01, 0xd8, 0xa9, 0x1d
	.byte 0x38, 0x91, 0xf9, 0x23, 0x0a, 0xc1, 0x1b, 0x39
	.byte 0x21, 0xc9, 0xcf, 0x0a, 0x6f, 0x02, 0x23, 0x00
	.byte 0xcb, 0xf1, 0x73, 0x1f, 0x01, 0xc9, 0x69, 0xf1
	.byte 0x1b, 0x39, 0x41, 0x40, 0x0b, 0x00, 0xbe, 0x00
	.byte 0x41, 0x0b, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0xfa, 0x99, 0xfa, 0x40, 0x0f, 0x00, 0xbe, 0x00
	.byte 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0xfa, 0x99, 0xfa, 0x78, 0xf6, 0x00, 0xc1, 0xe2
	.byte 0x39, 0x21, 0xc9, 0xda, 0x66, 0x05, 0xc9, 0xd9
	.byte 0x7e, 0xe9, 0x00, 0xd8, 0xa8, 0x1d, 0x60, 0x6d
	.byte 0xf1, 0xcf, 0xd9, 0x76, 0xde, 0x00, 0xcf, 0xd8
	.byte 0x7e, 0xd9, 0x00, 0xf1, 0xe2, 0x39, 0x00, 0x00
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x02, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99, 0xfa
	.byte 0xf1, 0xa6, 0x7e, 0x00, 0x23, 0x30, 0xee, 0x00
	.byte 0x78, 0xb5, 0x00, 0xc1, 0xe2, 0x39, 0x21, 0xc9
	.byte 0xda, 0x76, 0x81, 0x00, 0xc9, 0xd9, 0x66, 0x7d
	.byte 0xc9, 0xd8, 0x7e, 0xa7, 0x00, 0xc1, 0x1a, 0x39
	.byte 0x3f, 0x03, 0x6f, 0x0c, 0xf1, 0xa6, 0x7e, 0x00
	.byte 0x25, 0x30, 0xee, 0x00, 0x1d, 0xb0, 0x90, 0xf9
	.byte 0xc1, 0x1a, 0x39, 0x21, 0xd8, 0x12, 0xc1, 0x1b
	.byte 0x39, 0x23, 0xd9, 0x12, 0x1d, 0xa1, 0x6a, 0xf1
	.byte 0xcf, 0xda, 0x66, 0x1c, 0xcf, 0xd9, 0x66, 0x0e
	.byte 0xcf, 0xd8, 0x6e, 0x78, 0xf1, 0xa6, 0x7e, 0x00
	.byte 0x23, 0x30, 0xee, 0x00, 0x68, 0x6a, 0xf1, 0xa6
	.byte 0x7e, 0x00, 0x0f, 0x30, 0xee, 0x00, 0x68, 0x60
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x79, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0xc1, 0x1a, 0x39, 0x3f, 0x03, 0x6f, 0x07, 0xf1
	.byte 0xe2, 0x39, 0x00, 0x01, 0x68, 0x46, 0xf1, 0xe2
	.byte 0x39, 0x00, 0x02, 0x40, 0x19, 0x00, 0xbe, 0x00
	.byte 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xad
	call ApPostEvent
	jr t, CstmCp_ReturnZero2
	lds wa, 2
	call Flash_InitBytecodeBlock_0x2BF
	cps l, 1
	jr z, CstmCp_ReturnZero2
	cps l, 0
	jr nz, CstmCp_ReturnZero2
	ld (0x39e2:16), 0x00
	ld XWA,0xffffffff
	ld XBC,0x01c00002
	lds32 xde, 0
	call ApPostEvent
	ld (0x7ea6:16), 0x23
	ldw WA, 0x00ee
	call SoundCtrl_SendCommand
CstmCp_ReturnZero2:
	lds32 xhl, 0
	ret

CstmCp_StyleDataBlock:
	cp	xbc, 31719446
	jr	nz, 40
	ld	a, (14618:16)
	extz	wa
	ld	c, (14619:16)
	extz	bc
	call	15821473
	cps	l, 2
	jr	z, 20
	cps	l, 1
	jr	z, 16
	cps	l, 0
	jr	nz, 12
	ld	(32422:16), 35
	ldw	wa, 238
	call	16355504
	lds32	xhl, 0
	ret
__pad_F695CA:

MainCstmNameFunc:
	.byte 0xbf, 0x88, 0x37, 0x3e, 0xe9, 0x8a, 0x45, 0xc0
	.byte 0xbf, 0xe4, 0x00, 0xbf, 0x04, 0x34, 0x31, 0x3c
	.byte 0x00, 0x95, 0x11, 0xea, 0xcf, 0x2c, 0x00, 0xe4
	.byte 0x01, 0x66, 0x63, 0xea, 0xcf, 0x2b, 0x00, 0xe4
	.byte 0x01, 0x7e, 0xb6, 0x00, 0x0b, 0x11, 0x00, 0x1d
	.byte 0xa3, 0x06, 0xff, 0xeb, 0x8e, 0xc1, 0x1a, 0x39
	.byte 0x21, 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xbf, 0x06
	.byte 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0xe8, 0xc8
	.byte 0x40, 0x00, 0x00, 0x00, 0x0b, 0x0d, 0x00, 0x38
	.byte 0x3e, 0x1d, 0xbc, 0x05, 0xff, 0xbf, 0x0c, 0x37
	.byte 0xbe, 0x0d, 0x00, 0x00, 0xbe, 0x0e, 0x00, 0x00
	.byte 0xbe, 0x0f, 0x00, 0x00, 0xbe, 0x10, 0x00, 0x00
	.byte 0x40, 0x04, 0x00, 0xbe, 0x00, 0x41, 0x2d, 0x00
	.byte 0xe4, 0x01, 0xee, 0x8a, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x23, 0x00
	.byte 0xe0, 0x01, 0xee, 0x8a, 0x68, 0x58
CstmName_HandleEvent2C:
	pushw 0x11

	call	16713379

	ld xiz, xhl

	ld a, (14619:16)

	extz wa

	sla wa, 2

	lda xbc, (xsp + 6)

	ld_sril3 XWA, 0x07, 0xe4, 0xe0

	add xwa, 0x40

	pushw 0xd

	push xwa

	push xiz

	call	16713148

	lda xsp, (xsp + 12)

	ld (xiz + 13), 0x0

	ld (xiz + 14), 0x0

	ld (xiz + 15), 0x0

	ld (xiz + 16), 0x0

	ld xwa, 0xbe000f

	ld xbc, 0x1e4002e

	ld xde, xiz

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call ApDeliveryEvent (v7 addr)

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
	.byte 0xef, 0x6c, 0xb7, 0x62, 0xa7, 0x20, 0xc9, 0x6a
	.byte 0xe9, 0xcf, 0x11, 0x00, 0xe4, 0x01, 0x66, 0x68
	.byte 0xe9, 0xcf, 0x10, 0x00, 0xe4, 0x01, 0x7e, 0xbf
	.byte 0x00, 0xf1, 0xf4, 0x38, 0x41, 0xd8, 0xa8, 0x1d
	.byte 0x42, 0x5f, 0xf6, 0xa7, 0x20, 0xd8, 0x8a, 0xea
	.byte 0x12, 0xea, 0xc8, 0x00, 0x00, 0x01, 0x00, 0x40
	.byte 0x21, 0x00, 0xb9, 0x00, 0x41, 0x8d, 0x00, 0xe0
	.byte 0x01, 0x1d, 0xfa, 0x99, 0xfa, 0xc1, 0xdb, 0x39
	.byte 0x3f, 0x03, 0x76, 0x93, 0x00, 0xf1, 0xdb, 0x39
	.byte 0x00, 0x03, 0x40, 0x1c, 0x00, 0xb9, 0x00, 0x41
	.byte 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x1f, 0x00, 0xb9, 0x00, 0x41
	.byte 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0x40, 0x18, 0x00, 0xb9, 0x00, 0x41
	.byte 0x0c, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x68, 0x5c
S2cFunc_HandleEvent11:
	.byte 0xf1, 0xf4, 0x38, 0x41, 0xd8, 0xa9, 0x1d, 0x42
	.byte 0x5f, 0xf6, 0xa7, 0x20, 0xd8, 0x8a, 0xea, 0x12
	.byte 0xea, 0xc8, 0x00, 0x00, 0x01, 0x00, 0x40, 0x21
	.byte 0x00, 0xb9, 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0xc1, 0xdb, 0x39, 0x3f
	.byte 0x03, 0x66, 0x35, 0xf1, 0xdb, 0x39, 0x00, 0x03
	.byte 0x40, 0x1c, 0x00, 0xb9, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x1f, 0x00, 0xb9, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0x40, 0x18, 0x00, 0xb9, 0x00, 0x41, 0x0c, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8
S2cFunc_DeliverAndReturn:
	call ApDeliveryEvent

EventDelivery_ReturnZero:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69788:

MiddleNameFunc:
	lda	xwa, (13344:16)
	cp	xbc, 31719425
	jr	z, 33
	cp	xbc, 31719424
	jr	nz, 95
	push	xde
	push	xwa
	call	16713584
	inc	8, xsp
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16116038
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldw	wa, 178
	jr	66
MiddleName_HandleEvent01:
	push	xde
	push	xwa
	call	16713584
	inc	8, xsp
	ld	c, (32418:16)
	ld	a, c
	sll	a, 4
	cps	c, 2
	jr	nc, 12
	ldb	w, 0
	extz	xwa
	add	xwa, 2001536
	jr	13
MiddleName_CalcROMAddr_High:
	sub a, 0x20
	ldb w, 0x0
	extz xwa
	add xwa, 0x1e8a40

MiddleName_CopyAndPost:
	pushw	16
	pushw	0
	pushw	13344
	push	xwa
	call	16712982
	lda	xsp, (xsp+10)
	ldw	wa, 202
MiddleName_PostModeChange:
	call UI_PostModeChangeEvent

MiddleName_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F697FE:

MiddleCmpClrFunc:
	.byte 0xe9, 0xcf, 0x07, 0x00, 0xe4, 0x01, 0x66, 0x2f
	.byte 0xe9, 0xcf, 0x06, 0x00, 0xe4, 0x01, 0x6e, 0x4c
	.byte 0xf1, 0x31, 0x34, 0xba, 0xf1, 0x70, 0x34, 0x00
	.byte 0x00, 0x40, 0x12, 0x00, 0xb2, 0x00, 0x41, 0x02
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99
	.byte 0xfa, 0xf1, 0xa6, 0x7e, 0x00, 0x23, 0x30, 0xee
	.byte 0x00, 0x1d, 0xb0, 0x90, 0xf9, 0x68, 0x25
MiddleCmpClr_HandleEvent07:
	ld	(13424:16), 0
	ld	xwa, 11665426
	ld	xbc, 29360130
	lds32	xde, 0
	call	16423243
	ld	xwa, 11665408
	ld	xbc, 29360138
	lds32	xde, 0
	call	16423418
MiddleCmpClr_ReturnZero:
	lds32 xhl, 0
	ret
MainCmpCpFunc:
__pad_F6985D:
	lda	xsp, (xsp-18)
	push	xiz
	ld	xde, xbc
	ld	xiy, 14991416
	lda	xix, (xsp+10)
	lds	bc, 6
	.byte 0x95, 0x11
	cp	xde, 31719427
	jr	z, 113
	cp	xde, 31719426
	jrl	nz, 309
	pushw 17
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, 163840
	call	16567398
	ld	(xsp+7), l
	ld	xwa, 163841
	call	16567398
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	16552842
	ld	a, (xsp+4)
	extz	wa
	call	16104590
	extz	xhl
	pushw 16
	push	xhl
	push	xiz
	call	16713148
	lda	xsp, (xsp+10)
	ld	(xiz+16), 0
	ld	xwa, 12058654
	ld	xbc, 31719428
	ld	xde, xiz
	call	16423418
	ld	xwa, 4294967295
	ld	xbc, 31457315
	ld	xde, xiz
	jrl	201
MainCmpCp_HandleEvent03:
	pushw 15
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	ld	xwa, 163840
	call	16567398
	ld	(xsp+7), l
	ld	xwa, 163841
	call	16567398
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	16552842
	lda	xbc, (xsp+4)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+1)
	extz	bc
	call	16104563
	extz	xhl
	cp	(35996:16), 184
	jr	nz, 58
	lda	xbc, (xsp+4)
	ld	a, (xbc+3)
	cp	a, 128
	jr	c, 47
	.byte 0x89, 0x04, 0x3f, 0x00
	jr	nz, 41
	res	7, a
	cps	a, 4
	jr	nc, 4
	ldb	a, 0
	jr	11
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
	push	xiz
	call	16713148
	lda	xsp, (xsp+10)
	ld	(xiz+13), 0
	ld	a, (35996:16)
	cp	a, 184
	jr	nz, 14
	ld	xwa, 12058655
	ld	xbc, 31719429
	ld	xde, xiz
	jr	17
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
	.byte 0xef, 0x6c, 0xb7, 0x62, 0xc1, 0x3a, 0x34, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xf2, 0x12, 0x63
	.byte 0xe4, 0x32, 0x43, 0x60, 0x48, 0x09, 0x00, 0xe3
	.byte 0x07, 0xe8, 0xe0, 0x83, 0xeb, 0x8a, 0xe9, 0x8b
	.byte 0xa7, 0x20, 0xc9, 0x8b, 0xeb, 0xca, 0x08, 0x00
	.byte 0xe4, 0x01, 0xeb, 0xcf, 0x00, 0x00, 0x00, 0x00
	.byte 0x71, 0x58, 0x01, 0xeb, 0xcf, 0x07, 0x00, 0x00
	.byte 0x00, 0x7a, 0x4f, 0x01, 0xeb, 0x83, 0xeb, 0xc8
	.byte 0x6e, 0xc0, 0xe4, 0x00, 0x93, 0x23, 0xf2, 0x08
	.byte 0x96, 0xf6, 0x34, 0xf3, 0x07, 0xf0, 0xec, 0xd8
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
	ld	(13476:16), c
	cps	c, 2
	jr	ule, 6
	dec	2, a
	ld	(13476:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 0
	call	16141954
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 11796487
	ld	xbc, 31457421
	jr	52
	ld	a, c
	ld	(13476:16), c
	cps	c, 2
	jr	ule, 6
	dec	2, a
	ld	(13476:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	w, 128
	call	16141954
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 11796487
	ld	xbc, 31457421
	call	16423418
CmpSong_VariantA:
	lds32 xhl, 0
	inc 4, xsp
	ret
__pad_F69B4C:

MainEsCmpFunc:
	dec	4, xsp
	ld	(xsp), xde
	ld	xde, (xsp)
	ld	a, e
	dec	2, a
	cp	xbc, 31719466
	jrl	z, 203
	cp	xbc, 31719465
	jrl	z, 152
	cp	xbc, 31719464
	jr	z, 76
	cp	xbc, 31719463
	jrl	nz, 221
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	a, 0
	call	16149479
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	wa, de
	extz	xde
	add	xde, 65536
	ld	xwa, 12189706
	ld	xbc, 31457421
	call	16423418
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, 31457421
	jrl	150
EsCmp_HandleEvent28:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	a, 128
	call	16149479
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 65536
	ld	xwa, 12189706
	ld	xbc, 31457421
	call	16423418
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, 31457421
	jr	82
EsCmp_HandleEvent29:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	a, 0
	call	16150654
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, 31457421
	jr	40
EsCmp_HandleEvent2A:
	ld	(14620:16), a
	push	xde
	push	xhl
	push	xix
	push	xiz
	ldb	a, 128
	call	16150654
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, (xsp)
	ld	de, wa
	extz	xde
	add	xde, 131072
	ld	xwa, 12189706
	ld	xbc, 31457421
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
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xb5	; cpdi8 (0x8d38), 181 (v7 patched)

	ret nz

	ld xwa, 0xb5001e

	ld xbc, 0x1c0000b

	lds32 xde, 0

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call ApDeliveryEvent (v7 addr)

	ret



SoundCtrl_SendTempoScaled:
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xb5	; cpdi8 (0x8d38), 181 (v7 patched)

	ret nz

	calr 17

	ld xwa, 0xb50002

	ld xbc, 0x1c0000b

	lds32 xde, 0

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call ApDeliveryEvent (v7 addr)

	ret



SoundCtrl_CalcScaledTempo:
	ld	xhl, 100
	ld	bc, (13368:16)
	extz	xbc
	ld	xwa, xhl
	call	16712319
	ld	xwa, xhl
	ld	xbc, 190
	call	16712763
	cp	xhl, 99
	jr	ule, 5
	ld	xhl, 99
SoundCtrl_CalcTempo_Clamp:
	ld	(14607:16), l
	ret
AccGuard_ProgramChangeCheck:
	ld	c, (49122:16)
	ld	a, (49121:16)
	cps	a, 5
	jr	nz, 13
	cp	(49123:16), 0
	jr	z, 6
	cps	c, 2
	ret	nz
	jr	39
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

	call	16355504

	ret

AccGuard_SendProgramChange:
	ld	xwa, 163968
	call	16567398
	cps	hl, 0
	ret	z
	ldw	wa, 237
	call	16355504
	ret
AccSeq_DeliverC9_0009:
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xc9	; cpdi8 (0x8d38), 201 (v7 patched)

	ret nz

	ld xwa, 0xc90009

	ld xbc, 0x1c0000b

	lds32 xde, 0

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call ApDeliveryEvent (v7 addr)

	ret



AccSeq_DeliverC9_000A:
	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0xc9	; cpdi8 (0x8d38), 201 (v7 patched)

	ret nz

	ld xwa, 0xc9000a

	ld xbc, 0x1c0000b

	lds32 xde, 0

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call ApDeliveryEvent (v7 addr)

	ret

__pad_F69D47:

MainMspRgpSetFunc:
	.byte 0xc1, 0xa1, 0x7e, 0x21, 0xc9, 0xee, 0x04, 0x20
	.byte 0x00, 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0x8a, 0x1e
	.byte 0x00, 0xe8, 0x8d, 0xda, 0x8c, 0xec, 0x12, 0xec
	.byte 0x8b, 0xeb, 0xc8, 0x00, 0x00, 0x01, 0x00, 0xea
	.byte 0x88, 0xe8, 0x80, 0xec, 0x8a, 0xea, 0xc8, 0x00
	.byte 0x00, 0x02, 0x00, 0xe8, 0x6c, 0xe8, 0x8c, 0xed
	.byte 0x84, 0xbc, 0x01, 0x30, 0xe9, 0xcf, 0x15, 0x00
	.byte 0xe4, 0x01, 0x66, 0x7b, 0xe9, 0xcf, 0x14, 0x00
	.byte 0xe4, 0x01, 0x66, 0x54, 0xe9, 0xcf, 0x13, 0x00
	.byte 0xe4, 0x01, 0x66, 0x2b, 0xe9, 0xcf, 0x12, 0x00
	.byte 0xe4, 0x01, 0x7e, 0x83, 0x00, 0xc1, 0x6f, 0x7e
	.byte 0x3f, 0x00, 0x6e, 0x7c, 0xec, 0x89, 0x84, 0x21
	.byte 0xc9, 0xcf, 0x0e, 0x6f, 0x73, 0xc9, 0x61, 0xb1
	.byte 0x41, 0x40, 0x03, 0x00, 0xcc, 0x00, 0x41, 0x8d
	.byte 0x00, 0xe0, 0x01, 0xeb, 0x8a, 0x68, 0x5d
MspRgpSet_HandleEvent13:
	.byte 0xc1, 0x6f, 0x7e, 0x3f, 0x00, 0x6e, 0x5a, 0xec
	.byte 0x89, 0x84, 0x21, 0xc9, 0xd8, 0x66, 0x52, 0xc9
	.byte 0x69, 0xb1, 0x41, 0x40, 0x03, 0x00, 0xcc, 0x00
	.byte 0x41, 0x8d, 0x00, 0xe0, 0x01, 0xeb, 0x8a, 0x68
	.byte 0x3c
MspMenuTtl_Init:
	.byte 0xc1, 0x6f, 0x7e, 0x3f, 0x00, 0x6e, 0x39, 0xe8
	.byte 0x89, 0x80, 0x21, 0xc9, 0xdd, 0x6f, 0x31, 0xc9
	.byte 0x61, 0xb1, 0x41, 0x40, 0x03, 0x00, 0xcc, 0x00
	.byte 0x41, 0x8d, 0x00, 0xe0, 0x01, 0x68, 0x1d
MspMenuTtl_Case1:
	.byte 0xc1, 0x6f, 0x7e, 0x3f, 0x00, 0x6e, 0x1a, 0xe8
	.byte 0x89, 0x80, 0x21, 0xc9, 0xd8, 0x66, 0x12, 0xc9
	.byte 0x69, 0xb1, 0x41, 0x40, 0x03, 0x00, 0xcc, 0x00
	.byte 0x41, 0x8d, 0x00, 0xe0, 0x01
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
	lda xix, (MspMenuTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspMenuTtlFunc title dispatch
MspMenuTtl_Dispatch:
	ld	xwa, 165888
	call	16567398
	cp	l, 13
	jr	c, 5
	cp	l, 16
	jr	ule, 4
	ldb	l, 0
	jr	3
	sub	l, 13
	ld	(32418:16), l
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
	pushw	13344
	call	16712982
	lda	xsp, (xsp+10)
	ld	(13360:16), 0
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
	lda xix, (MspNameTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspNameTtlFunc title dispatch
MspNameTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xcb	; cpdi8	(0x8d37), 203 (v7 patched)

	jr	z, 20

	ld c, (32418:16)

	add	c, 13

	extz	bc

	ld	xwa, 0x028800

	lds	de, 0

	.byte 0x1d, 0x30, 0xca, 0xfc	; call	SoundParam_NotifyChange (v7 addr)

	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xcc	; cpdi8	(0x8d37), 204 (v7 patched)

	jr	z, 19

	ld	xwa, 0xcc0003

	ld	xbc, 0x01e0008e

	ld	xde, 0xffff0002

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call	ApDeliveryEvent (v7 addr)



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
	ld	(32367:16), 0
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
	lda xix, (MspRecTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; MspRecTtlFunc title dispatch
MspRecTtl_Dispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 21 of 30 slots byte-identical
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xc9	; differs from v10 here and llvm-objdump cannot read it
	jr	z, 61
	ld	xwa, 164099
	lds	bc, 0
	lds	de, 3
	call	16566832
	ld	xwa, 165888
	call	16567398
	cp	l, 13
	jr	z, 5
	cp	l, 14
	jr	nz, 29
	ld	a, (32376:16)
	sll	a, 4
	ldb	w, 0
	extz	xwa
	add	xwa, 2000928
	ld	a, (xwa)
	and	a, 16
	srl	a, 4
	ld	(32419:16), a
	lds	wa, 0
	call	UI_PostDialEnable
	jr	71
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0xc9	; differs from v10 here and llvm-objdump cannot read it
	jr	z, 64
	.byte 0xc1, 0x6f, 0x7e, 0x3f, 0x00	; differs from v10 here and llvm-objdump cannot read it
	jr	z, 57
	ld	(32367:16), 0
	jr	50
MspRecTtl_SubA:
	ld	xwa, 165888
	call	16567398
	cp	l, 13
	jr	z, 5
	cp	l, 14
	jr	nz, 31
MspRecTtl_SubA_CheckRange:
	ld a, (32376:16)

	sll a, 4

	ldb w, 0x0

	extz xwa

	add xwa, 0x1e8820

	ld c, (32419:16)

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
	.byte 0xc1, 0x9c
AccSeq_DcModeDataBlock_Code:
	xor	(xix+63), d
	ret	nz
	ld	xwa, 14417925
	ld	xbc, 29360143
	lds32	xde, 0
	call	16423418
	ret	
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
	lda xix, (SndArgTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; SndArgTtlFunc title dispatch
SndArgTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0xdc	; cpdi8	(0x8d37), 220 (v7 patched)

	jr	z, 19

	ld	xwa, 0xdc0005

	ld	xbc, 0x01e0008e

	ld	xde, 0xffff0002

	.byte 0x1d, 0xfa, 0x99, 0xfa	; call	ApDeliveryEvent (v7 addr)

	push	xde

	push	xhl

	push	xix

	push	xiz

	.byte 0x1d, 0xd0, 0xc2, 0xf5	; call	AccStyle_InlinedBlock (v7 addr)

	.ascii "^\\[Z"



SndArgTtl_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6A0BB:

SndArgNmGet:
	.byte 0xbf, 0xb4, 0x37, 0xd7, 0xfa, 0x04, 0xbf, 0x46
	.byte 0x62, 0xbf, 0x4a, 0x61, 0x45, 0xbe, 0xc0, 0xe4
	.byte 0x00, 0xbf, 0x42, 0x34, 0x95, 0x10, 0x95, 0x10
	.byte 0x45, 0xc6, 0xc0, 0xe4, 0x00, 0xbf, 0x3a, 0x34
	.byte 0xd9, 0xac, 0x95, 0x11, 0x45, 0xd6, 0xc0, 0xe4
	.byte 0x00, 0xbf, 0x34, 0x34, 0xd9, 0xaa, 0x95, 0x11
	.byte 0x85, 0x10, 0x45, 0xdc, 0xc0, 0xe4, 0x00, 0xbf
	.byte 0x20, 0x34, 0x31, 0x0a, 0x00, 0x95, 0x11, 0x45
	.byte 0xf0, 0xc0, 0xe4, 0x00, 0xbf, 0x0c, 0x34, 0x31
	.byte 0x0a, 0x00, 0x95, 0x11, 0x40, 0x00, 0x80, 0x02
	.byte 0x00, 0x1d, 0x66, 0xcc, 0xfc, 0xbf, 0x09, 0x47
	.byte 0x40, 0x01, 0x80, 0x02, 0x00, 0x1d, 0x66, 0xcc
	.byte 0xfc, 0xbf, 0x06, 0x30, 0xb8, 0x04, 0x47, 0xb8
	.byte 0x02, 0x00, 0x48, 0x1d, 0x8a, 0x93, 0xfc, 0xbf
	.byte 0x02, 0x02, 0x00, 0x00, 0xbf, 0x04, 0x00, 0x00
	.byte 0x68, 0x18
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

	call	16703099

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

	.byte 0x78, 0x86, 0x00	; jrl SndArgNm_DeliverAndReturn (v7 displacement)



SndArgNm_HandleEvent21:
	or	xde, xde
	jr	nz, 27
	pushw	3
	ld	xwa, (xsp+68)
	push	xwa
	pushw	0
	pushw	14664
	call	16713148
	lda	xsp, (xsp+10)
	ld	(14667:16), 0
	jr	80
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

	call	16713148

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
	.byte 0xaf, 0x02, 0x20, 0xea, 0x80, 0x80, 0x19, 0x9e
	.byte 0x8c, 0xc1, 0x9e, 0x8c, 0x25, 0xda, 0x12, 0x0b
	.byte 0xff, 0x00, 0x30, 0x90, 0x00, 0x31, 0x10, 0x00
	.byte 0x1d, 0x53, 0xaa, 0xfd, 0xc1, 0xf2, 0x32, 0x19
	.byte 0xf3, 0x32
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
	call	16457204
	pop	xwa
	ret
	push	xwa
	ld	xwa, xiy
	call	16458027
	pop	xwa
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	cp	(35995:16), 182
	jr	z, 19
	call	16125836
	ld	(13449:16), 182
	.byte 0xc1, 0x1a, 0xe3, 0x3c, 0xef, 0xc1, 0x18, 0xe3, 0x3c, 0xef
	call	16141457
	.byte 0xf1, 0x1a, 0xe3, 0xcc
	jr	nz, 12
	ld	xwa, 16162780
	push	xwa
	call	16425183
	inc	4, xsp
	ld	xwa, 16162812
	push	xwa
	call	16425183
	inc	4, xsp
	ret
	calr	1530
	ld	(257960:24), 2
	ld	xiy, 16164358
	ld	xix, 16164653
	calr	-161
	calr	773
	calr	795
	calr	1176
	ret
	calr	726
	ld	(257960:24), 1
	ld	xiy, 16164964
	calr	-125
	calr	1155
	ld	(257960:24), 0
	calr	1492
	.byte 0xc1, 0x3a, 0x34, 0x19, 0x1f, 0x39, 0xc1, 0xa6, 0x36, 0x19, 0x20, 0x39, 0xc1, 0xa7, 0x36, 0x19, 0x21, 0x39, 0xc1, 0xa8, 0x36, 0x19, 0x22, 0x39, 0xc1, 0xa9, 0x36, 0x19, 0x23, 0x39, 0xc1, 0x7e, 0x36, 0x19, 0x24, 0x39
	ld	xiy, 16164794
	ld	xix, 16164905
	calr	-240
	ld	(257960:24), 0
	.byte 0xc1, 0x76, 0x36, 0x19, 0x1f, 0x39
	ld	xiy, 16164922
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
	call	16141491
	ret
	push	xiz
	calr	2
	pop	xiz
	ret
	ld	xix, 16162949
	calr	81
	ret
	.byte 0x92, 0xa1, 0xf6
	nop
	.byte 0xa4, 0xa1, 0xf6
	nop
	.byte 0xc2, 0xa1, 0xf6, 0x00, 0xe0, 0xa1, 0xf6
	nop
	nop
	.byte 0xa2, 0xf6
	nop
	ldb	w, 162
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
	cp_spdw	iz, 162
	nop
	cp	hl, 15
	jr	ugt, 27
	ld	e, l
	inc	1, e
	calr	21
	.byte 0xc1, 0x1c, 0xe3, 0x3c, 0xfe
	ld	xbc, xhl
	and	l, 31
	sla	l, 2
	ld_rr8l	xix, xix, l
	.byte 0xb4, 0xe8
	ret
	push	xix
	cp	e, 32
	jr	ule, 2
	xor	e, e
	sla	e, 2
	ld	xix, 16163086
	ld_rr8l	xde, xix, e
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
	.byte 0xc1, 0x77, 0x36, 0x3e, 0x40
	jr	5
	.byte 0xc1, 0x77, 0x36, 0x3e, 0x80
	ret
	cp	(13942:16), 4
	jr	nz, 22
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x04
	jr	5
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x08
	ret
	cp	(13942:16), 4
	jr	nz, 22
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 7
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x01
	jr	5
	.byte 0xc1, 0x91, 0x36, 0x3e, 0x02
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	16141646
	ld	xwa, 16163318
	push	xwa
	call	16425183
	inc	4, xsp
	ret
	ld	(257960:24), 0
	calr	813
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	16141703
	ld	xwa, 16163350
	push	xwa
	call	16425183
	inc	4, xsp
	ret
	ld	(257960:24), 0
	calr	781
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	call	16141758
	cp	(13942:16), 4
	jr	nz, 12
	ld	xwa, 16163389
	push	xwa
	call	16425183
	inc	4, xsp
	ret
	ld	(257960:24), 0
	.byte 0xc1, 0x7a, 0x36, 0x19, 0x1f, 0x39
	ld	xiy, 16165259
	calr	-728
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x77, 0x36, 0x3e, 0x02, 0xc1, 0x77, 0x36, 0x3c, 0xfe
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08, 0xc1, 0x77, 0x36, 0x3e, 0x01, 0xc1, 0x77, 0x36, 0x3c, 0xfd
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 15
	.byte 0xf1, 0xff, 0x36, 0xcb
	jr	nz, 9
	call	16141503
	.byte 0xc1, 0x1a, 0xe3, 0x3e, 0x10
	ret
	.byte 0xc1, 0x1c, 0xe3, 0x3e, 0x08
	bit	7, w
	jr	nz, 15
	.byte 0xf1, 0xff, 0x36, 0xcc
	jr	nz, 9
	call	16141574
	.byte 0xc1, 0x1a, 0xe3, 0x3e, 0x10
	ret
	bit	7, w
	jr	nz, 5
	.byte 0xc1, 0x77, 0x36, 0x3e, 0x20
	ret
	bit	7, w
	jr	nz, 5
	.byte 0xc1, 0x77, 0x36, 0x3e, 0x04
	ret
	ret
	ret
	ret
	bit	7, w
	jr	nz, 12
	ld	(58134:16), 181
	ld	(58136:16), 128
	jr	0
	ret
	ret
	ret
	ret
	ret
	ld	(257960:24), 2
	cp	(13942:16), 4
	jr	nz, 15
	ld	xiy, 16164653
	ld	xix, 16164794
	calr	-926
	jr	8
	ld	xiy, 16164905
	calr	-873
	ret
	xor	wa, wa
	ld	xiy, 16165577
	ld	xix, xiy
	ldb	a, 35
	ld	c, (13986:16)
	mul8rr	a, c
	extz	xwa
	add	xix, xwa
	calr	-961
	ret
	ld	xiy, 16165717
	ld	c, (13986:16)
	calr	37
	ld	xiy, 16165807
	ld	c, (13987:16)
	calr	25
	ld	xiy, 16165897
	ld	c, (13988:16)
	calr	13
	ld	xiy, 16165987
	ld	c, (13989:16)
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
	ld	xiy, 13970
	ld	xix, 2601
	xor	de, de
	xor	bc, bc
	ld	xiz, 13986
	xor	wa, wa
	ld	a, e
	extz	xwa
	add	xiz, xwa
	ld	d, (xiz)
	cps	d, 0
	jr	z, 87
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16162627
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	xor	hl, hl
	ld	l, c
	ld_rrb	l, xiy, hl
	and	l, 15
	calr	84
	add	xix, 4
	xor	hl, hl
	ld	l, c
	ld_rrb	l, xiy, hl
	and	l, 240
	srl	l, 4
	calr	60
	add	xix, 4
	inc	1, c
	cp	c, d
	jr	c, -51
	push	xwa
	push	xhl
	push	xbc
	push	xde
	push	xix
	push	xiy
	push	xiz
	call	16162634
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
	ld	xiy, 16165513
	lds	bc, 4
	ldb	a, 6
	ld	xwa, 14640
	ld	(xwa), 6
	ld	(xwa+1), 8
	ld	(xwa+2), ix
	extz	hl
	extz	xhl
	sll	xhl, 2
	add	xiy, xhl
	ldb_spi	l, 244
	ld	(xwa+4), l
	ldb_spi	l, 244
	ld	(xwa+5), l
	ldb_spi	l, 244
	ld	(xwa+6), l
	ld	l, (xiy)
	ld	(xwa+7), l
	call	16454209
	popw	bc
	popw	de
	pop	xix
	pop	xiy
	ret
	xor	wa, wa
	ld	a, (13939:16)
	cps	a, 0
	jr	z, 2
	dec	1, a
	and	a, 127
	ldb	c, 32
	div8rr	a, c
	ld	(14621:16), a
	sla	wa, 1
	xor	xhl, xhl
	ld	l, w
	ld	xiy, 16166077
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(14632:16), bc
	add	bc, 6
	ld	(14636:16), bc
	xor	xhl, xhl
	ld	l, a
	ld	xiy, 16166141
	add	xiy, xhl
	ld	bc, (xiy)
	ld	(14634:16), bc
	add	bc, 8
	ld	(14638:16), bc
	ldb	a, 5
	push	xwa
	ld	xwa, 14630
	call	16456102
	pop	xwa
	ret
	xor	wa, wa
	ld	a, (13939:16)
	cps	a, 0
	jr	z, 2
	dec	1, a
	and	a, 127
	ldb	c, 32
	div8rr	a, c
	ld	(14621:16), a
	ret
	ld	(257960:24), 0
	cp	(13942:16), 4
	jr	z, 5
	calr	215
	jr	32
	ld	a, (13947:16)
	cp	a, 255
	jr	z, 6
	calr	21
	calr	54
	calr	93
	.byte 0xc1, 0x7a, 0x36, 0x19, 0x1f, 0x39
	ld	xiy, 16165259
	calr	-1380
	ret
AccScreen_DrawTempoDisplay:
	calr AccScreen_CalcTempoParams
	ld xiy, AccScreen_UIDataBlock_0x360
	ld xix, AccScreen_UIDataBlock_0x37E
	calr AccGraphics_RenderStart
	ret

AccScreen_CalcTempoParams:
	xor	wa, wa
	ld	a, (13948:16)
	ldb	l, 12
	divs8rr	a, l
	ld	(14620:16), w
	ld	(14622:16), a
	ret
AccScreen_UpdateBeatDisplay:
	ldmm8 0x391f, 0x367b
	ld XIY,AccScreen_UIDataBlock_0x37E
	push XWA
	ld XWA,XIY
	call DrawText_LayoutAndRender
	pop XWA
	cp (0x367b:16), 0x63
	jr ugt, AccScreen_BeatDisplay_Large
	ld XIY,AccScreen_UIDataBlock_0x386
	jr t, AccScreen_BeatDisplay_Draw
AccScreen_BeatDisplay_Large:
	ld xiy, AccScreen_UIDataBlock_0x390

AccScreen_BeatDisplay_Draw:
	calr AccDraw_Init
	ret

AccScreen_BeatDataBlock:
	.byte 0xc1, 0x76, 0x36, 0x3f, 0x04, 0x6e, 0x19, 0xc1
	.byte 0x78, 0x36, 0x19, 0x1f, 0x39, 0xc1
AccScreen_BeatDataBlock_Code:
	jrl	ge, 6454
	ldb	w, 57
	ld	xiy, 16165229
	ld	xix, 16165259
	calr	64014
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
	ld XIY,AccScreen_UIDataBlock_0x2BA
	calr AccDraw_Secondary
	ld a, (0x3685:16)
	ld (0x391e:16), a
	cp (0x3684:16), 0x03
	jr nz, AccScreen_DrawMeas_Other
	ld a, (0x3685:16)
	cps a, 0
	jr z, AccScreen_DrawMeas_Variant3
	ld (0x391e:16), 0x01
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
	.incbin "includes/romslices/v7_block_accscreen_uidatablock.bin"
AccPatch_InitSlotChain_Wrap:
	push xiz
	calr AccPatch_InitSlotChain
	pop xiz
	ret

AccPatch_InitSlotChain_WithAddr:
	push	xiz
	ld	xiz, 608256
	ld	(14610:16), xiz
	calr	2
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
	.byte 0xd1, 0xe2, 0x36, 0x3f, 0xff, 0xff, 0x66, 0x33
	.byte 0xd1, 0xe2, 0x36, 0x23, 0x1e, 0x33, 0x01, 0xf1
	.byte 0xbe, 0x36, 0x66, 0xd1, 0xf2, 0x36, 0xf3, 0x66
	.byte 0x06, 0x1e, 0xad, 0x00, 0x1e, 0x5d, 0x00
AccPatch_IterateSlot_Advance:
	ld	xiz, (14030:16)
	ld	wa, (xiz+3)
	ld	(14050:16), wa
	incw	1, (14066:16)
	ld	hl, (14066:16)
	calr	269
	ld	(14030:16), xiz
	jr	-59
AccPatch_IterateSlot_NextBlock:
	ld	xiz, 256
	adddm32	(14034), xiz
	ld	xiz, (14034:16)
	ld	wa, (xiz+3)
	ld	(14050:16), wa
	djnz16	bc, -82
	xor	xwa, xwa
	xor	xhl, xhl
	ld	wa, (14066:16)
	ldw	hl, 256
	mul	xwa, xhl
	add	xwa, 5120
	add	xwa, 1023
	and	xwa, 4294966272
	srl	xwa, 4
	ld	xiy, (14610:16)
	ld	(xiy+46), wa
	ret
AccPatch_SwapSlotBuffers:
	.byte 0x39, 0x40, 0x00, 0x04, 0x00, 0x00, 0x38, 0x1d
	.byte 0xa3, 0x06, 0xff, 0xef, 0xc8, 0x04, 0x00, 0x00
	.byte 0x00, 0xf1, 0xc8, 0x34, 0x63, 0x31, 0x00, 0x01
	.byte 0xe1, 0xc8, 0x34, 0x24, 0xe1, 0xce, 0x36, 0x25
	.byte 0x85, 0x11, 0x31, 0x00, 0x01, 0xe1, 0xce, 0x36
	.byte 0x24, 0xe1, 0xbe, 0x36, 0x25, 0x85, 0x11, 0x31
	.byte 0x00, 0x01, 0xe1, 0xc8, 0x34, 0x25, 0xe1, 0xbe
	.byte 0x36, 0x24, 0x85, 0x11, 0xe1, 0xc8, 0x34, 0x20
	.byte 0x38, 0x1d, 0x15, 0x03, 0xff, 0xef, 0xc8, 0x04
	.byte 0x00, 0x00, 0x00, 0x59, 0x0e
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
	jr	z, 10
	calr	68
	ld	wa, (14066:16)
	ld	(xiz+1), wa
AccPatch_UpdateLink_Back:
	ld	hl, (14477:16)
	cp	hl, 65535
	jr	z, 10
	calr	48
	ld	wa, (14066:16)
	ld	(xiz+3), wa
AccPatch_UpdateLink_Fwd1:
	ld	hl, (14479:16)
	cp	hl, 65535
	jr	z, 10
	calr	28
	ld	wa, (14050:16)
	ld	(xiz+1), wa
AccPatch_UpdateLink_Fwd2:
	ld	hl, (14481:16)
	cp	hl, 65535
	jr	z, 10
	calr	8
	ld	wa, (14050:16)
	ld	(xiz+3), wa
AccPatch_UpdateLink_Return:
	ret

AccPatch_CalcSlotBufferAddr:
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, xhl
	addda32	xiz, (14610)
	add	xiz, 5120
	ret
AccPatch_VoiceAssignDataBlock:
	ret
	ret
	ld	xiy, (14002:16)
	ld	a, (xiy+256)
	cp	a, 109
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 45
	ld	a, (xiy+2)
	cp	a, 97
	jr	nz, 37
	ld	(14078:16), 0
	jr	71
	ld	a, (xiy+256)
	cp	a, 102
	jr	nz, 22
	ld	a, (xiy+1)
	cps	a, 0
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 107
	jr	nz, 7
	ld	(14078:16), 0
	jr	41
	ld	a, (xiy+256)
	cp	a, 109
	jr	nz, 23
	ld	a, (xiy+1)
	cp	a, 107
	jr	nz, 15
	ld	a, (xiy+2)
	cp	a, 98
	jr	nz, 7
	ld	(14078:16), 0
	jr	10
	ld	(14078:16), 255
	ld	(14516:16), 130
	ret
	xor	xbc, xbc
	ldw	bc, 42
	add	xiy, 12
	add	xix, 12
	.byte 0x95, 0x11
	djnz8	e, -22
	ret
	cp xix, xiy
	jr	ugt, 15
	xor	xbc, xbc
	ldw	bc, 128
	.byte 0x95, 0x11
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	jr	38
	.byte 0xcc, 0x04
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
	.byte 0x85, 0x13
	dec	1, e
	cps	e, 0
	jr	ugt, -13
	pop	xiy
	pop	xix
	ret
	xor	xbc, xbc
	ld	(xiy), 0
	ldw	(xiy+1), 65535
	ldw	(xiy+3), 65535
	ldb	c, 249
	add	xiy, 6
	stib_dsp	244, 0
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
	ld	c, (14498:16)
	cp	(xiy+1), wa
	jr	nz, 31
	.byte 0x9d, 0x03, 0x3f, 0xff, 0xff
	jr	nz, 6
	inc	1, (14497:16)
	jr	30
	inc	1, (14497:16)
	add	xiy, 256
	dec	1, c
	cps	c, 0
	jr	ugt, -29
	jr	12
	add	xiy, 256
	dec	1, c
	cps	c, 0
	jr	ugt, -48
	inc	1, wa
	cp	wa, qwa
	jr	ule, -64
	ret
	ld	xiy, 651776
	xor	xbc, xbc
	ldb	c, 190
	.byte 0x85, 0x3f, 0x80
	jr	nz, 13
	inc	1, (14502:16)
	add	xiy, 256
	djnz8	c, -18
	ret
	xor	xde, xde
	ld	de, (xiy+3)
	cp	de, 65535
	jr	z, 115
	ld	de, (14506:16)
	ld	(xiy+3), de
	ld	de, (14504:16)
	ld	(xix+1), de
	ldw	(14512:16), 0
	.byte 0x9c, 0x03, 0x3f, 0xff, 0xff
	jr	z, 61
	ld	de, (14512:16)
	cps	de, 0
	jr	nz, 25
	incw	1, (14506:16)
	ld	de, (14506:16)
	ld	(xix+3), de
	add	xix, 256
	ldw	(14512:16), 255
	jr	-40
	ld	de, (14506:16)
	dec	1, de
	ld	(xix+1), de
	incw	1, (14506:16)
	ld	de, (14506:16)
	ld	(xix+3), de
	add	xix, 256
	jr	-68
	ld	de, (14512:16)
	cps	de, 0
	jr	z, 9
	ld	de, (14506:16)
	dec	1, de
	ld	(xix+1), de
	incw	1, (14506:16)
	add	xix, 256
	incw	1, (14504:16)
	add	xiy, 256
	dec	1, c
	cps	c, 0
	jrl	ugt, -141
	ret
	xor	xiz, xiz
	ld	xiz, 256
	mul	xiz, xhl
	add	xiz, 613376
	ret
	push	xiz
	call	16167311
	pop	xiz
	ret
	ld	(14516:16), 0
	ldw	(14548:16), 0
	ldw	(14550:16), 150
	calr	1581
	calr	1579
	cp	(14516:16), 132
	jr	z, 54
	calr	85
	cp	w, 255
	jr	nz, 7
	ld	(14516:16), 130
	jr	39
	calr	51
	call	16166359
	calr	148
	calr	164
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 20
	calr	657
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 11
	calr	1244
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 2
	jr	7
	call	16166359
	calr	112
	calr	1511
	call	16115067
	ret
	xor	xwa, xwa
	ld	xiy, 432128
	ld	wa, (xiy+14)
	ld	xiy, 608256
	ld	(xiy+14), wa
	ret
	ld	xhl, 432128
	.byte 0x8b, 0x01, 0x3f, 0x48
	jr	nz, 16
	.byte 0x8b, 0x02, 0x3f, 0x00
	jr	nz, 10
	.byte 0x8b, 0x02, 0x3f, 0x4b
	jr	nz, 4
	ldb	w, 5
	jr	57
	ld	a, (xhl+256)
	cp	a, 103
	jr	nz, 19
	ld	a, (xhl+1)
	cps	a, 0
	jr	nz, 12
	ld	a, (xhl+2)
	cp	a, 107
	jr	nz, 4
	ldb	w, 5
	jr	30
	ld	a, (xhl+256)
	cp	a, 76
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
	ld	w, (13370:16)
	ld	(13370:16), a
	pushw	wa
	call	16116191
	popw	wa
	ld	(13370:16), w
	ret
	xor	xhl, xhl
	xor	xwa, xwa
	call	16166396
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	ld	(14558:16), wa
	xor	xwa, xwa
	call	16166359
	ld	l, a
	ldb	a, 96
	mul8rr	a, l
	add	wa, 96
	ld	(14560:16), wa
	cpw	(14558:16), 960
	jr	c, 26
	cpw	(14558:16), 960
	jr	z, 23
	cpw	(14558:16), 2016
	jr	c, 20
	cpw	(14558:16), 2016
	jr	z, 33
	jr	52
	calr	79
	jr	76
	calr	121
	jr	71
	calr	1293
	cp	(14516:16), 129
	jr	z, 61
	.byte 0xd1, 0xde, 0x38, 0x3a, 0x00, 0x04
	calr	53
	jr	50
	calr	1272
	cp	(14516:16), 129
	jr	z, 40
	.byte 0xd1, 0xde, 0x38, 0x3a, 0x00, 0x04
	calr	79
	jr	29
	calr	1251
	cp	(14516:16), 129
	jr	z, 19
	calr	1241
	cp	(14516:16), 129
	jr	z, 9
	.byte 0xd1, 0xde, 0x38, 0x3a, 0x00, 0x08
	calr	140
	ret
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
	.byte 0x85, 0x11
	calr	142
	ret
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xiz, xiz
	ldw	wa, 1024
	subda16 xwa, (14558)
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
	.byte 0x85, 0x11
	push	xiy
	push	xix
	calr	80
	calr	1113
	pop	xix
	pop	xiy
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 19
	pop	xbc
	ld	xiy, 432128
	ldw	wa, 96
	sub	wa, bc
	ld	bc, wa
	sub	bc, 12
	.byte 0x85, 0x11
	ret
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
	.byte 0x85, 0x11
	calr	1
	ret
	xor	xiy, xiy
	xor	xix, xix
	xor	xwa, xwa
	ld	iy, (14558:16)
	ld	xhl, 432128
	add	xhl, 0
	ld_rrw	wa, xhl, iy
	ld	(14518:16), wa
	ld	xhl, 432128
	add	xhl, 4
	ld_rrw	wa, xhl, iy
	ld	(14520:16), wa
	ld	xhl, 432128
	add	xhl, 6
	ld_rrw	wa, xhl, iy
	ld	(14522:16), wa
	ld	xhl, 432128
	add	xhl, 8
	ld_rrw	wa, xhl, iy
	ld	(14524:16), wa
	ld	xhl, 432128
	add	xhl, 10
	ld_rrw	wa, xhl, iy
	ld	(14526:16), wa
	ld	ix, (14560:16)
	add	xix, 608256
	ld	wa, (xix+256)
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
	calr	876
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 31
	lds32	xwa, 5
	push	xwa
	calr	865
	pop	xwa
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 18
	djnz8	a, -14
	calr	13
	calr	54
	calr	95
	calr	136
	calr	177
	ret
	ld	wa, (14518:16)
	ld	(14552:16), wa
	ld	wa, (14528:16)
	ld	(14554:16), wa
	calr	201
	ld	wa, (14552:16)
	ld	(14518:16), wa
	ld	wa, (14556:16)
	ld	(14538:16), wa
	ld	wa, (14554:16)
	ld	(14528:16), wa
	ret
	ld	wa, (14520:16)
	ld	(14552:16), wa
	ld	wa, (14530:16)
	ld	(14554:16), wa
	calr	157
	ld	wa, (14552:16)
	ld	(14520:16), wa
	ld	wa, (14556:16)
	ld	(14540:16), wa
	ld	wa, (14554:16)
	ld	(14530:16), wa
	ret
	ld	wa, (14522:16)
	ld	(14552:16), wa
	ld	wa, (14532:16)
	ld	(14554:16), wa
	calr	113
	ld	wa, (14552:16)
	ld	(14522:16), wa
	ld	wa, (14556:16)
	ld	(14542:16), wa
	ld	wa, (14554:16)
	ld	(14532:16), wa
	ret
	ld	wa, (14524:16)
	ld	(14552:16), wa
	ld	wa, (14534:16)
	ld	(14554:16), wa
	calr	69
	ld	wa, (14552:16)
	ld	(14524:16), wa
	ld	wa, (14556:16)
	ld	(14544:16), wa
	ld	wa, (14554:16)
	ld	(14534:16), wa
	ret
	ld	wa, (14526:16)
	ld	(14552:16), wa
	ld	wa, (14536:16)
	ld	(14554:16), wa
	calr	25
	ld	wa, (14552:16)
	ld	(14526:16), wa
	ld	wa, (14556:16)
	ld	(14546:16), wa
	ld	wa, (14554:16)
	ld	(14536:16), wa
	ret
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 15
	calr	13
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 6
	calr	219
	calr	262
	ret
	calr	65
	cps	de, 0
	jr	z, 60
	ld	wa, (14552:16)
	cp wa, (14548:16)
	jr	c, 47
	xor	xhl, xhl
	xor	xbc, xbc
	ld	bc, (14552:16)
	srl	bc, 2
	ld	hl, (14548:16)
	srl	hl, 2
	sub	bc, hl
	cps	bc, 0
	jr	ule, 21
	push	xbc
	calr	552
	pop	xbc
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 10
	.byte 0xd1, 0xd4, 0x38, 0x38, 0x04, 0x00
	dec	1, bc
	jr	-25
	jr	3
	calr	35
	ret
	xor	xwa, xwa
	xor	xhl, xhl
	xor	xde, xde
	ld	wa, (14552:16)
	ld	hl, (14548:16)
	cp	wa, hl
	jr	c, 12
	add	hl, 3
	cp	wa, hl
	jr	ugt, 4
	lds	de, 0
	jr	3
	ldw	de, 255
	ret
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 82
	cpw	(14552:16), 340
	jr	nc, 69
	calr	477
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 65
	lds32	xwa, 4
	push	xwa
	calr	466
	pop	xwa
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 52
	djnz8	a, -14
	ldw	(14548:16), 0
	xor	xbc, xbc
	ld	bc, (14552:16)
	srl	bc, 2
	inc	1, bc
	cps	bc, 0
	jr	ule, 21
	push	xbc
	calr	431
	pop	xbc
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 17
	.byte 0xd1, 0xd4, 0x38, 0x38, 0x04, 0x00
	dec	1, bc
	jr	-25
	jr	5
	ld	(14516:16), 128
	ret
	xor	xwa, xwa
	xor	xhl, xhl
	ld	wa, (14552:16)
	ld	hl, (14548:16)
	sub	wa, hl
	ldw	hl, 256
	mul	xwa, xhl
	ld	(14558:16), wa
	ret
	calr	-27
	xor	xiy, xiy
	ld	iy, (14558:16)
	add	xiy, 6
	add	xiy, 432128
	xor	xhl, xhl
	ld	hl, (14554:16)
	calr	-1275
	ld	xix, xiz
	add	xix, 6
	xor	xbc, xbc
	ldw	bc, 249
	.byte 0x85, 0x11
	ret
	xor	xiy, xiy
	xor	xwa, xwa
	calr	-77
	ld	iy, (14558:16)
	ld	xhl, 432128
	add	xhl, 3
	ld_rrw	wa, xhl, iy
	ld	(14552:16), wa
	xor	xhl, xhl
	ld	hl, (14554:16)
	ld	(14556:16), hl
	calr	-1335
	ld	wa, (xiz+3)
	ld	(14554:16), wa
	ret
	ld	wa, (14518:16)
	ld	(14552:16), wa
	ld	wa, (14538:16)
	ld	(14556:16), wa
	calr	77
	ld	wa, (14520:16)
	ld	(14552:16), wa
	ld	wa, (14540:16)
	ld	(14556:16), wa
	calr	58
	ld	wa, (14522:16)
	ld	(14552:16), wa
	ld	wa, (14542:16)
	ld	(14556:16), wa
	calr	39
	ld	wa, (14524:16)
	ld	(14552:16), wa
	ld	wa, (14544:16)
	ld	(14556:16), wa
	calr	20
	ld	wa, (14526:16)
	ld	(14552:16), wa
	ld	wa, (14546:16)
	ld	(14556:16), wa
	calr	1
	ret
	xor	xwa, xwa
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jrl	nz, 132
	cpw	(14552:16), 65535
	jr	z, 123
	calr	123
	cpw	(14550:16), 340
	jr	nc, 100
	ld	wa, (14550:16)
	ld	(14554:16), wa
	calr	-448
	.byte 0xf1, 0xb4, 0x38, 0xcf
	jr	nz, 83
	calr	-242
	xor	xhl, xhl
	ld	hl, (14556:16)
	calr	-1496
	ld	wa, (14554:16)
	ld	(xiz+3), wa
	ld	hl, wa
	calr	-1508
	.byte 0x86, 0x3e, 0x80
	decw	1, (13368:16)
	ld	wa, (14556:16)
	ld	(xiz+1), wa
	xor	xiy, xiy
	ld	iy, (14558:16)
	add	xiy, 432128
	ld	wa, (xiy+3)
	cp	wa, 65535
	jr	z, 5
	ld	(xiz+3), wa
	jr	5
	ldw	(xiz+3), 65535
	ld	(14552:16), wa
	ld	wa, (14554:16)
	ld	(14556:16), wa
	jr	-119
	ld	hl, (14554:16)
	calr	-1574
	ldw	(xiz+3), 65535
	nop
	nop
	ret
	xor	xhl, xhl
	ld	hl, (14550:16)
	cp	hl, 340
	jr	nc, 25
	calr	-1597
	ld	a, (xiz)
	bit	7, a
	jr	z, 15
	inc	1, hl
	cp	hl, 340
	jr	nc, 2
	jr	-20
	ld	(14516:16), 131
	ld	(14550:16), hl
	ret
	ret
	ret
	ret
	ret
	cp	(14516:16), 0
	jr	z, 63
	cp	(14516:16), 132
	jr	z, 28
	cp	(14516:16), 130
	jr	z, 42
	cp	(14516:16), 131
	jr	z, 21
	cp	(14516:16), 129
	jr	z, 21
	ld	(32422:16), 1
	jr	33
	ld	(32422:16), 3
	jr	26
	ld	(32422:16), 23
	jr	19
	ld	(32422:16), 1
	jr	12
	ld	(32422:16), 0
	jr	5
	ld	(32422:16), 35
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
	.byte 0xc1, 0xec, 0x8c, 0x3c, 0xfe	; anddi8 (0x8d88), 254 (v7 patched)

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
	.byte 0x1d, 0x2d, 0x24, 0xef, 0x1d, 0xbe, 0x09, 0xfe
	.byte 0x1d, 0x6f, 0xa4, 0xfc, 0x1d, 0x36, 0xe2, 0xf6
	.byte 0x1d, 0xb5, 0x96, 0xf5, 0xf1, 0xa7, 0x28, 0xba
	.byte 0x1d, 0x26, 0xee, 0xfd, 0x1d, 0x9b, 0x08, 0xfe
	.byte 0x1d, 0xa6, 0x06, 0xfe, 0x1d, 0x97, 0x0a, 0xfe
	.byte 0x1d, 0x46, 0x0a, 0xfe, 0x1d, 0x2d, 0xb7, 0xfe
	.byte 0x1d, 0xc0, 0x09, 0xef, 0x68, 0x0a
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

	lds wa, 0



AccBankData_InitSlot_OuterLoop:
	lds32 xde, 0

AccBankData_InitSlot_InnerLoop:
	.byte 0xf3, 0x07, 0xe8, 0xe0, 0x31, 0xe1, 0x40, 0x55
	.byte 0x81, 0xf3, 0xe5, 0xa0, 0x00, 0x31, 0x81, 0x3f
	.byte 0x00, 0x6e, 0x05, 0xb1, 0x00, 0x20, 0x68, 0x0a
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
	lda_rr	xbc, xde, wa
	addda32	xbc, 21824
	ld	(xbc+160), 32
	inc	1, xde
	cp	xde, 16
	jr	c, -25
AccBankData_PadSpaces_Done:
	inc1b_erp	251
	add	wa, 96
	cp_erpb	251, 12
	jr	c, -90
	ld	(18490:16), 0
	.byte 0xf1, 0x14, 0x35, 0xb0
	ldib_erp	251, 0
AccBankData_ProcessSlot:
	lda	xwa, (432128:24)
	ld	(14610:16), xwa
	stb_erp	a, 251
	ld	(14608:16), a
	call	16116212
	ld	xwa, (15552:16)
	ld	(14610:16), xwa
	lda	xwa, (432128:24)
	ld	(14614:16), xwa
	stb_erp	a, 251
	ld	(14609:16), a
	stb_erp	a, 251
	ld	(14608:16), a
	call	16133691
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, 7
	ld	(18490:16), 1
	jr	16
AccBankData_SlotFound:
	inc1b_erp	251
	cp_erpb	251, 30
	jr	c, -82
	cp	(18490:16), 0
	jr	z, 32
AccBankData_ReInitAllSlots:
	lda xwa, (0x069800:24)

	ld (14610:16), xwa

	ldib_erp 0xfb, 0



AccBankData_ReInit_Loop:
	stb_erp	a, 251
	ld	(14608:16), a
	call	AccPatch_InitFromSlotIndex
	inc1b_erp	251
	cp_erpb	251, 30
	jr	c, -20	; -> 0xF6B9EF
AccBankData_FinalizeCheck:
	.byte 0xc1, 0x3a, 0x48, 0x3f, 0x00, 0x6e, 0x65, 0xe1
	.byte 0xc0, 0x3c, 0x20, 0xe8, 0xc8, 0x00, 0x68, 0x01
	.byte 0x00, 0x90, 0x21, 0xe8, 0xac, 0xda, 0xab, 0x1d
	.byte 0x30, 0xca, 0xfc, 0x1d, 0x4d, 0x9b, 0xfc, 0xe1
	.byte 0xc0, 0x3c, 0x21, 0xe9, 0xc8, 0x00, 0x6c, 0x01
	.byte 0x00, 0xe9, 0x8c, 0xc7, 0xfb, 0xa8, 0xf1, 0xf4
	.byte 0xe2, 0x32
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
	lda xbc, (0x1e0000:24)
	lds32 xde, 0

AccBankData_CopyToExtRAM:
	ldb_spi	a, 240
	lda_dpi	xbc, 228
	inc	1, xde
	cp	xde, 29350
	jr	c, -16
	lds	wa, 0
	call	16710953
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

	lda_dri XWA, 0xe5, 0xa0, 0x00

	push xwa

	call 16713148

	lda xsp, (xsp + 10)

	ldib_erp 0xfb, 0

	lds bc, 0
AccBankData_CopyLoop:
	ld	de, bc
	add	de, 160
	ld	xwa, (21824:16)
	lda_rr	xwa, xwa, de
	ld	e, (xwa)
	cps	e, 0
	jr	nz, 2
	ldb	e, 32
AccBankData_CopyLoop_NonZero:
	ld	(xwa), e
	inc1b_erp	251
	inc	1, bc
	cp_erpb	251, 16
	jr	c, -36
	.byte 0x8f, 0x02, 0x3f, 0x02
	jr	ule, 32
	call	15665874
	ld	c, (xsp+2)
	inc	7, c
	extz	bc
	ld	xde, (15552:16)
	lds	wa, 0
	call	15831932
	call	15665911
	call	16114969
	jrl	228
AccBankData_InitSlotScan:
	.byte 0xf1, 0x3a, 0x48, 0x00, 0x00	; stdi8 (0x48d6), 0 (v7 patched)

	.byte 0xf1, 0x14, 0x35, 0xb0	; resda 0, 0x35b0 (v7 patched)

	ldib_erp 0xfb, 0
AccBankData_SlotScan_Loop:
	lda	xwa, (432128:24)
	ld	(14610:16), xwa
	ld	c, (xsp+2)
	extz	bc
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	de, wa
	add	de, bc
	lda	xwa, (14991636:24)
	.byte 0xc3, 0x07, 0xe0, 0xe8, 0x19, 0x10, 0x39
	call	16116212
	ld	xwa, (15552:16)
	ld	(14610:16), xwa
	lda	xwa, (432128:24)
	ld	(14614:16), xwa
	stb_erp	a, 251
	extz	wa
	muls	wa, 3
	ld	bc, wa
	lda	xde, (14991636:24)
	.byte 0xc3, 0x07, 0xe8, 0xe4, 0x19, 0x10, 0x39
	ld	a, (xsp+2)
	extz	wa
	add	bc, wa
	.byte 0xc3, 0x07, 0xe8, 0xe4, 0x19, 0x11, 0x39
	call	16133691
	ld	a, (13588:16)
	extz	wa
	bit	0, wa
	jr	z, 7
	ld	(18490:16), 1
	jr	16
AccBankData_SlotScan_Next:
	inc1b_erp	251
	cp_erpb	251, 10
	jr	c, -128
	cp	(18490:16), 0
	jr	z, 57
AccBankData_SlotScan_ReInit:
	lda xwa, (0x069800:24)

	ld (14610:16), xwa

	ldib_erp 0xfb, 0



AccBankData_ReInit_ScanLoop:
	.byte 0x8f, 0x02, 0x23, 0xd9, 0x12, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x03, 0x00, 0xd8, 0x8a
	.byte 0xd9, 0x82, 0xf2, 0x14, 0xc1, 0xe4, 0x30, 0xc3
	.byte 0x07, 0xe0, 0xe8, 0x19, 0x10, 0x39, 0x1d, 0xf4
	.byte 0xe9, 0xf5, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf
	.byte 0x0a, 0x67, 0xd5, 0x68, 0x18
AccBankData_NotifyAndUpdateTempo:
	ld	xwa, (15552:16)
	add	xwa, 92160
	ld	bc, (xwa)
	lds32	xwa, 4
	lds	de, 3
	call	16566832
	call	16554829
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
	stib_dsp	224, 0
	cp	xwa, xbc
	jr	c, -8
	ret
StyleBuf_ClearAllEntries:
	lda	xbc, (16108:16)
	ld	xwa, xbc
	lda	xbc, (xbc+2048)
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
	lda	xbc, (18416:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
StyleConv_ClearWorkBuf_Loop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StyleConv_ClearWorkBuf_Loop
	ret

StyleConv_ClearEntryTables:
	.byte 0xf1, 0xec, 0x46, 0x30, 0xe8, 0x89, 0xf1, 0xec
	.byte 0x3e, 0x32, 0xf3, 0xe1, 0x00, 0x01, 0x33
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
	lds	iz, 0
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
	lda	xwa, (21696:16)
	ld	xbc, xwa
	lda	xde, (18496:16)
	lda	xhl, (xwa+128)
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
	ld	xbc, 1114114
	ld	a, (35994:16)
	cp	a, 21
	jr	z, 24
	cp	a, 18
	jr	z, 12
	cp	a, 17
	jr	nz, 19
	ld	xbc, 1114114
	jr	12
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
	ld	xbc, 29360143
	call	16423243
	inc	1, qiz
	ld	wa, qiz
	cp	wa, iz
	jr	c, -84
DialCalc_Return:
	pop xiz
	inc 2, xsp
	ret
__pad_F6C160:

StylCnvWaitTtlFunc:
	.byte 0xe9, 0xcf, 0x07, 0x00, 0xc0, 0x01, 0x66, 0x73
	.byte 0xe9, 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x6e, 0x6b
	.byte 0xea, 0xcf, 0x03, 0x00, 0x00, 0x00, 0x66, 0x52
	.byte 0xea, 0xcf, 0x08, 0x00, 0x00, 0x00, 0x66, 0x5b
	.byte 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00, 0x6e, 0x53
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0x60, 0x6e, 0x21, 0x1e
	.byte 0xbd, 0xfe, 0xf1, 0x6a, 0x3c, 0x00, 0x00, 0x1e
	.byte 0x06, 0xfb, 0x1d, 0x07, 0xa8, 0xf8, 0xdb, 0xd8
	.byte 0x6e, 0x07, 0x30, 0x11, 0x00, 0x1d, 0x83, 0x90
	.byte 0xf9
StylCnvWait_SetStatus:
	ld	(18494:16), 0
	jr	43
StylCnvWait_CheckPending:
	.byte 0xc1, 0x3e, 0x48, 0x3f, 0x00, 0x66, 0x24, 0xf1
	.byte 0xa6, 0x7e, 0x00, 0x4a, 0x30, 0xee, 0x00, 0x1d
	.byte 0xb0, 0x90, 0xf9, 0xf1, 0x3e, 0x48, 0x00, 0x00
	.byte 0x68, 0x11
StylCnvWait_HandleClose:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x60, 0x66, 0x07, 0xc1
	.byte 0x98, 0x8c, 0x3f, 0x06, 0x66, 0x03
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
	cp (0x0ffc00:24), 0x05
	jr nz, StylCnvTxt_ReturnZero
	ld (0x0ffc00:24), 0xff
	calr TableData_JumpToEntry
	calr FloppyState_Dispatch
	jr StylCnvTxt_ReturnZero

StylCnvTxt_HandleClose:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x06, 0xf2, 0xd2, 0xb8
	.byte 0xf6, 0xee
StylCnvTxt_ReturnZero:
	lds32 xhl, 0
	ret
__pad_F6C229:

StylCnvModlTtlFunc:
	lda	xsp, (xsp-36)
	push	xiz
	ld	xhl, xde
	ld	de, (15464:16)
	ld	iz, de
	ld	wa, (14822:16)
	cp	xbc, 29360135
	jrl	z, 435
	cp	xbc, 29360147
	jrl	nz, 1071
	cp	xhl, 4
	jrl	z, 408
	cp	xhl, 5
	jrl	z, 393
	cp	xhl, 3
	jrl	z, 363
	cp	xhl, 8
	jrl	z, 341
	cp	xhl, 2
	jrl	nz, 1026
	calr	65125
	ld	(18494:16), 0
	ld	xwa, 14991666
	call	16296216
	ldw	(14822:16), 0
	lds	iz, 0
StylCnvModl_ScanMatchingModels:
	ld	bc, iz
	mul	bc, 37
	lda	xwa, (21832:16)
	extz	xbc
	add	xbc, xwa
	lda	xwa, (xbc+1)
	lda	xbc, (xbc+33)
	call	16296648
	cps	hl, 0
	jr	nz, 12
	incw	1, (14822:16)
	inc	1, iz
	cp	iz, 256
	jr	c, -40
StylCnvModl_ScanDone:
	.byte 0xd1, 0xe6, 0x39, 0x3f, 0x00, 0x00, 0x6e, 0x06
	.byte 0x30, 0x10, 0x00, 0x78, 0xdb, 0x02
StylCnvModl_PadModelNames:
	cp	iz, 256
	jr	nc, 55
	lda	xhl, (21832:16)
	ld	bc, iz
	mul	bc, 37
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
	ldw	(15464:16), 0
	ld	xwa, 1114114
	ld	xbc, 31719471
	lds32	xde, 0
	call	16423243
	lda	xbc, (16076:16)
	ld	xwa, xbc
	lda	xbc, (xbc+32)
StylCnvModl_ClearDisplayBuf:
	stib_dsp	224, 0
	cp	xwa, xbc
	jr	c, -8
	ld	xwa, 14991678
	call	16296216
	lda	xbc, (xsp+36)
	ld	xwa, 16076
	call	16296648
	lda	xwa, (16076:16)
	cps	hl, 0
	jr	nz, 63
	pushw	46
	push	xwa
	call	16720173
	inc	6, xsp
	or	xhl, xhl
	jr	z, 3
	ld	(xhl), 0
StylCnvModl_FormatFilename:
	lds	iy, 0
	lda	xde, (16076:16)
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
	pushw	0
	pushw	58124
	push	xwa
	call	16713584
	inc	8, xsp
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
	cp (0x8c9a:16), 0x60
	jr z, StylCnvModl_RedrawDone
	cp (0x8c98:16), 0x06
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
	ld	(15464:16), de
StylCnvModl_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvModl_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, 543
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1114114
	ld	xbc, 31719471
	call	16423243
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, 483
	mul	iz, 37
	lda	xwa, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xwa
	ld	xwa, 1114114
	ld	xbc, 29360143
	call	16423243
	ld	de, (15464:16)
	mul	de, 37
	lda	xwa, (21832:16)
	extz	xde
	add	xde, xwa
	ld	xwa, 1114114
	ld	xbc, 29360143
	call	16423243
	jrl	432
StylCnvModl_OK_ScrollUp:
	lds	wa, 1
	call	16355640
	ld	wa, (15464:16)
	cps	wa, 0
	jrl	z, -135
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-142
StylCnvModl_OK_ScrollDown:
	lds	wa, 1
	call	16355640
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, -167
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-174
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
	jrl	nc, -220
	extz	xhl
	div	hl, 20
	ld	wa, qhl
	cps	wa, 0
	jrl	z, -234
	ld	(15464:16), bc
	jrl	-237
StylCnvModl_OK_SelectItem:
	mul	de, 37
	lda	xwa, (21833:16)
	extz	xde
	add	xde, xwa
	ld	xwa, xde
	ld	xbc, 14991690
	call	16295962
	cps	hl, 0
	jr	ge, 5
	ldw	wa, 16
	jr	63
StylCnvModl_OK_Select_ClearMem:
	ld xbc, 0x80000
	lds32 xwa, 0

StylCnvModl_OK_Select_FillLoop:
	stib_dsp	228, 0
	inc	1, xwa
	cp	xwa, 196608
	jr	c, -14
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21865:16)
	extz	xbc
	add	xbc, xwa
	ld	xbc, (xbc)
	ld	xwa, 524288
	call	16288103
	cp	xhl, 0
	jr	ge, 14
	call	16287803
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
	jr	z, 12
	and	xbc, 4294967040
	add	xbc, 256
StylCnvModl_OK_Select_AlignSize:
	add	xbc, 524288
	ld	(15552:16), xbc
	call	16287803
	ld	(1047550:24), 0
	ld	wa, (15464:16)
	ld	(18448:16), wa
	lds	iz, 0
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
	call	16713148
	lda	xsp, (xsp+10)
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21865:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (xbc)
	ld	(15548:16), xwa
	calr	4571
	calr	1446
	jr	10
StylCnvModl_OK_PageRedraw:
	ld	bc, (14822:16)
	ldw	wa, 20
StylCnvModl_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvModl_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 36)
	ret
StylCnvModl_End:

StylCnvCnvtTtlFunc:
	push	xiz
	ld	hl, (15464:16)
	ld	iz, hl
	ld	ix, (14822:16)
	cp	xbc, 29360135
	jrl	z, 235
	cp	xbc, 29360147
	jrl	nz, 644
	cp	xde, 4
	jrl	z, 208
	cp	xde, 5
	jrl	z, 193
	cp	xde, 3
	jrl	z, 170
	cp	xde, 8
	jrl	z, 151
	cp	xde, 2
	jrl	nz, 599
	ld	(18494:16), 0
	calr	64013
	ldw	(14822:16), 0
	lds	iz, 0
StylCnvCnvt_ScanMatchingStyles:
	ld	bc, iz
	mul	bc, 37
	lda	xwa, (21832:16)
	extz	xbc
	add	xbc, xwa
	lda	xwa, (xbc+1)
	lda	xbc, (xbc+33)
	call	16296648
	cps	hl, 0
	jr	nz, 12
	incw	1, (14822:16)
	inc	1, iz
	cp	iz, 256
	jr	c, -40
StylCnvCnvt_PadStyleNames:
	cp	iz, 256
	jr	nc, 55
	lda	xhl, (21832:16)
	ld	bc, iz
	mul	bc, 37
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
	ldw	(15464:16), 0
	ld	xwa, 1179650
	ld	xbc, 31719471
	lds32	xde, 0
	call	16423243
	jrl	457
StylCnvCnvt_HandleScroll:
	ldw wa, 0x14
	ld bc, ix
	ld de, hl
	jrl StylCnvCnvt_OK_CallRedraw

StylCnvCnvt_HandleRedraw:
	cp (0x8c98:16), 0x06
	call_24 nz, (Display_RestoreEntry)
	lds wa, 0
	jr t, StylCnvCnvt_CallReturnAction
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
	ld	(15464:16), hl
StylCnvCnvt_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvCnvt_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, 316
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1179650
	ld	xbc, 31719471
	call	16423243
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, 256
	mul	iz, 37
	lda	xwa, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xwa
	ld	xwa, 1179650
	ld	xbc, 29360143
	call	16423243
	ld	de, (15464:16)
	mul	de, 37
	lda	xwa, (21832:16)
	extz	xde
	add	xde, xwa
	ld	xwa, 1179650
	ld	xbc, 29360143
	call	16423243
	jrl	205
StylCnvCnvt_OK_ScrollUp:
	lds	wa, 1
	call	16355640
	ld	wa, (15464:16)
	cps	wa, 0
	jrl	z, -135
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-142
StylCnvCnvt_OK_ScrollDown:
	lds	wa, 1
	call	16355640
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, -167
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-174
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
	jrl	nc, -220
	extz	xde
	div	de, 20
	ld	wa, qde
	cps	wa, 0
	jrl	z, -234
	ld	(15464:16), bc
	jrl	-237
StylCnvCnvt_OK_SelectItem:
	ld	a, (15466:16)
	cps	a, 2
	jr	z, 18
	cps	a, 1
	jr	nz, 72
	ld	wa, (18448:16)
	cps	wa, 1
	jr	z, 40
	cps	wa, 0
	jr	z, 36
	jr	58
StylCnvCnvt_OK_Select_WriteStyle:
	ld	xwa, (15552:16)
	ld	(15556:16), xwa
	call	16295943
	ld	bc, (15464:16)
	mul	bc, 37
	lda	xwa, (21833:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, xbc
	call	16296829
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
	lds32 xhl, 0
	pop xiz
	ret
StylCnvCnvt_End:

StylCnvSelTtlFunc:
	push	xiz
	ld	xhl, xbc
	ld	ix, (15464:16)
	ld	iz, ix
	ld	bc, (14822:16)
	cp	xhl, 29360135
	jr	z, 115
	cp	xhl, 29360147
	jrl	nz, 482
	cp	xde, 4
	jr	z, 89
	cp	xde, 5
	jr	z, 75
	cp	xde, 3
	jr	z, 53
	cp	xde, 8
	jr	z, 37
	cp	xde, 2
	jrl	nz, 441
	calr	63344
	ldw	(15464:16), 0
	ld	xwa, 1376258
	ld	xbc, 31719471
	lds32	xde, 0
	call	16423243
	jrl	413
StylCnvSel_HandleScroll:
	ldw wa, 0x14
	ld de, ix
	jrl StylCnvSel_OK_CallRedraw

StylCnvSel_HandleRedraw:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x06, 0xf2, 0xd2, 0xb8
	.byte 0xf6, 0xee, 0xd8, 0xa8, 0x68, 0x08
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
	ld	(15464:16), ix
StylCnvSel_OK_LoadSelection:
	ld	bc, (15464:16)
StylCnvSel_OK_UpdateDisplay:
	cp	iz, bc
	jrl	z, 274
	extz	xbc
	div	bc, 20
	ld	de, qbc
	extz	xde
	ld	xwa, 1376258
	ld	xbc, 31719471
	call	16423243
	ld	de, (15464:16)
	ld	bc, de
	extz	xbc
	div	bc, 20
	ld	wa, iz
	extz	xwa
	div	wa, 20
	cp	wa, bc
	jrl	nz, 214
	mul	iz, 37
	lda	xbc, (21832:16)
	ld	de, iz
	extz	xde
	add	xde, xbc
	ld	xwa, 1376258
	ld	xbc, 29360143
	call	16423243
	ld	wa, (15464:16)
	mul	wa, 37
	lda	xbc, (21832:16)
	ld	de, wa
	extz	xde
	add	xde, xbc
	ld	xwa, 1376258
	ld	xbc, 29360143
	call	16423243
	jrl	161
StylCnvSel_OK_ScrollUp:
	lds	wa, 1
	call	16355640
	ld	wa, (15464:16)
	cps	wa, 0
	jrl	z, -137
	dec	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-144
StylCnvSel_OK_ScrollDown:
	lds	wa, 1
	call	16355640
	ld	bc, (14822:16)
	dec	1, bc
	ld	wa, (15464:16)
	cp	wa, bc
	jrl	nc, -169
	inc	1, wa
	ld	(15464:16), wa
	ld	bc, wa
	jrl	-176
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
	jrl	nc, -224
	extz	xde
	div	de, 20
	ld	wa, qde
	cps	wa, 0
	jrl	z, -238
	ld	(15464:16), bc
	jrl	-241
StylCnvSel_OK_SelectItem:
	calr	62882
	ld	(1047552:24), 255
	ld	wa, (15464:16)
	inc	1, a
	ld	(1047553:24), a
	calr	3375
	calr	250
	jr	10
StylCnvSel_OK_PageRedraw:
	ld	bc, (14822:16)
	ldw	wa, 20
StylCnvSel_OK_CallRedraw:
	calr DialUI_CalcProlog

StylCnvSel_Return:
	lds32 xhl, 0
	pop xiz
	ret
StylCnvSel_End:

StylCnvContTtlFunc:
	.byte 0xe9, 0xcf, 0x07, 0x00, 0xc0, 0x01, 0x66, 0x61
	.byte 0xe9, 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x7e, 0xa0
	.byte 0x00, 0xea, 0xcf, 0x03, 0x00, 0x00, 0x00, 0x66
	.byte 0x44, 0xea, 0xcf, 0x08, 0x00, 0x00, 0x00, 0x76
	.byte 0x8f, 0x00, 0xea, 0xcf, 0x02, 0x00, 0x00, 0x00
	.byte 0x7e, 0x86, 0x00, 0xc1, 0x3a, 0x48, 0x3f, 0x00
	.byte 0x66, 0x11, 0xf1, 0xa6, 0x7e, 0x00, 0x0f, 0x30
	.byte 0xee, 0x00, 0x1d, 0xb0, 0x90, 0xf9, 0xf1, 0x3a
	.byte 0x48, 0x00, 0x00
StylCnvCont_CheckPending:
	.byte 0xc1, 0x3e, 0x48, 0x3f, 0x00, 0x66, 0x67, 0xf1
	.byte 0xa6, 0x7e, 0x00, 0x4a, 0x30, 0xee, 0x00, 0x1d
	.byte 0xb0, 0x90, 0xf9, 0xf1, 0x3e, 0x48, 0x00, 0x00
	.byte 0x68, 0x54
StylCnvCont_HandleClose:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x06, 0x66, 0x4d, 0x1e
	.byte 0x45, 0xf1, 0x68, 0x48
StylCnvCont_HandleOK:
	cp	xde, 11
	jr	z, 58
	cp	xde, 10
	jr	nz, 56
	ld	(15466:16), 0
	calr	62714
	ld	(1047552:24), 255
	ld	(1047553:24), 0
	pushw	4
	pushw	0
	pushw	15548
	ld	xwa, 1047554
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	calr	3190
	calr	65
	jr	6
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
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x06, 0xf2, 0xd2, 0xb8
	.byte 0xf6, 0xee
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
	ld	(18494:16), 255
	ldw	wa, 16
	jp	16355459
FloppyState_Dispatch:
	lda xsp, (xsp - 114)
	push xiz

StyleConv_DispatchSoundMemState:
	ld a, (0x0ffc00:24)
	cps a, 0
	jr nz, StylCnvDisp_CheckFE
	cpw (0x4810:16), 0x0001
	jr nz, StylCnvDisp_PostMode13
	calr AccBankData_InitAllSlots
	lds wa, 1
	call UI_PostPartChangeEvent
	jrl t, StylCnv_Epilogue114
StylCnvDisp_PostMode13:
	ldw wa, 0x13
	jrl StylCnv_PostModeChange

StylCnvDisp_CheckFE:
	cp	a, 254
	jr	nz, 11
	ld	(18494:16), 255
	ldw	wa, 22
	jrl	3058
StylCnvDisp_CheckType:
	cps	a, 3
	jrl	z, 2862
	cps	a, 4
	jrl	z, 754
	cps	a, 2
	jr	z, 46
	lda	xbc, (15564:16)
	cps	a, 1
	jr	z, 29
	cps	a, 5
	jrl	nz, 1410
	ld	xwa, 1047553
	push	xwa
	push	xbc
	call	16713584
	inc	8, xsp
	ld	(15466:16), 5
	ldw	wa, 20
	jrl	3007
StylCnvDisp_Type1_CopyPath:
	ld xwa, 0xffc01
	push xwa
	push xbc
	jr StylCnvDisp_CopyAndFinalize

StylCnvDisp_Type2_CheckSubtype:
	ld	a, (1047553:24)
	cp	a, 64
	jrl	z, 346
	cp	a, 128
	jr	z, 81
	cp	a, 16
	jr	z, 42
	cps	a, 0
	jrl	nz, -137
	ld	(15466:16), 1
	ld	xwa, 1047552
	call	16296216
	lda	xbc, (15468:16)
	ld	(xbc), 2
	ld	(xbc+1), 0
	ld	xwa, 1047554
	push	xwa
	lda	xwa, (xbc+2)
	push	xwa
	jr	25
StylCnvDisp_Subtype10_Process:
	ld	(15466:16), 2
	ld	xwa, 1047552
	call	16296216
	ld	xwa, 1047552
	push	xwa
	lda	xwa, (15468:16)
	push	xwa
StylCnvDisp_CopyAndFinalize:
	call	16713584
	inc	8, xsp
	jrl	598
StylCnvDisp_Subtype80_Process:
	cp (0x0ffc02:24), 0x2e

	jrl nz, 234

	ld (15466:16), 6

	calr 62203

	calr 62232

	ldw (xsp + 4), 0x0

	.byte 0xf1, 0x3c, 0x48, 0x02, 0x00, 0x00	; stdi16 (0x48d8), 0 (v7 patched)



StylCnvDisp_ScanFileLoop:
	pushw 0x0003
	pushw 0x00e4
	pushw 0xc14e
	ld WA,(XSP+0x0a)
	inc 2,WA
	extz XWA
	add XWA,0x000ffc00
	push XWA
	call 0xff04e4
	add XSP,0x0000000a
	cps hl, 0
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
	jr	nz, 6
	incw	1, (18492:16)
	jr	35
StylCnv_ParseEntry_StoreChar:
	.byte 0xd1, 0x3c, 0x48, 0x21, 0xd9, 0xee, 0x05, 0x9f
	.byte 0x06, 0x22, 0xd9, 0x82, 0xf1, 0xec, 0x3e, 0x31
	.byte 0xea, 0x12, 0xe9, 0x82, 0xb2, 0x41, 0x9f, 0x06
	.byte 0x61, 0x9f, 0x04, 0x61, 0x9f, 0x06, 0x3f, 0x20
	.byte 0x00, 0x61, 0xc3
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
	.byte 0x9f, 0x04, 0x20, 0xdc, 0x80, 0xe8, 0x12, 0xeb
	.byte 0x80, 0x88, 0x01, 0x23, 0xcb, 0xcf, 0x2e, 0x66
	.byte 0x16, 0xf1, 0xf0, 0x47, 0x32, 0x9f, 0x04, 0x20
	.byte 0xf3, 0x07, 0xe8, 0xe0, 0x43, 0x9f, 0x04, 0x61
	.byte 0x9f, 0x04, 0x3f, 0x20, 0x00, 0x61, 0xd9
StylCnv_CopyName_Finalize:
	pushw	0
	pushw	16108
	pushw	0
	pushw	18416
	jrl	349
ControlState_Type3:
	ld	(15466:16), 3
	ld	xwa, 1047552
	call	16296216
	jrl	338
StylCnv_Type4_Init:
	ld	(15466:16), 4
	lda	xde, (18458:16)
	ld	xwa, xde
	lda	xbc, (xde+32)
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
	stb_dri C, 0x07, 0xe8, 0xe0
	incw 1, (xsp + 4)
	incw 1, (xsp + 6)
	cpw (xsp + 4), 0x28
	jr lt, StylCnv_Type4_CopyChars

LoopIndex_Reset:
	ldw (xsp + 6), 0x0

StylCnv_Type4_FindDot:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x2e
	jr z, StylCnv_Type4_CalcExtLen
	incw 1, (xsp + 6)
	cpw (xsp + 6), 0x20
	jr lt, StylCnv_Type4_FindDot

StylCnv_Type4_CalcExtLen:
	ldw (xsp + 16), 0x0

StylCnv_Type4_CountExt:
	ld wa, (xsp + 6)
	cpib_sri 0x07, 0xe8, 0xe0, 0x00
	jr z, StylCnv_Type4_CalcCenter
	incw 1, (xsp + 16)
	incw 1, (xsp + 6)
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
	.byte 0x9f, 0x04, 0x20, 0xd8, 0x62, 0xe8, 0x12, 0xe8
	.byte 0xc8, 0x00, 0xfc, 0x0f, 0x00, 0x80, 0x3f, 0x00
	.byte 0x6e, 0x48, 0xde, 0x61, 0xd7, 0xfa, 0xf6, 0x6e
	.byte 0x41, 0x9f, 0x04, 0x61, 0x0b, 0x04, 0x00, 0x9f
	.byte 0x06, 0x20, 0xd8, 0x62, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x00, 0xfc, 0x0f, 0x00, 0x38, 0x0b, 0x00, 0x00
	.byte 0x0b, 0x12, 0x48, 0x1d, 0xbc, 0x05, 0xff, 0x9f
	.byte 0x0e, 0x64, 0x0b, 0x04, 0x00, 0x9f, 0x10, 0x20
	.byte 0xd8, 0x62, 0xe8, 0x12, 0xe8, 0xc8, 0x00, 0xfc
	.byte 0x0f, 0x00, 0x38, 0x0b, 0x00, 0x00, 0x0b, 0x16
	.byte 0x48, 0x1d, 0xbc, 0x05, 0xff, 0xbf, 0x14, 0x37
	.byte 0x68, 0x0b
StylCnv_Type4_Advance:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jrl lt, StylCnv_Type4_MainLoop

StylCnv_Type4_BuildOutput:
	calr	61723
	ldw	(xsp+4), 0
	ld	ix, (15464:16)
	mul	ix, 37
	lda	xhl, (21832:16)
StylCnv_Type4_CopyNameLoop2:
	.byte 0x9f, 0x04, 0x20, 0xdc, 0x80, 0xe8, 0x12, 0xeb
	.byte 0x80, 0x88, 0x01, 0x25, 0xf1, 0xf0, 0x47, 0x31
	.byte 0xcd, 0xcf, 0x2e, 0x66, 0x12, 0x9f, 0x04, 0x20
	.byte 0xf3, 0x07, 0xe4, 0xe0, 0x45, 0x9f, 0x04, 0x61
	.byte 0x9f, 0x04, 0x3f, 0x20, 0x00, 0x61, 0xd9
StylCnv_Type4_AppendExt:
	pushw	0
	pushw	18458
	push	xbc
StylCnv_AppendAndClear:
	call	16713188
	inc	8, xsp
StylCnv_ClearAndFinalize:
	ld (0x0ffc00:24), 0xff
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_DispatchByType:
	ld a, (0x3c6a:16)
	cps a, 6
	jrl z, StylCnv_Type6_Dispatch
	cps a, 4
	jrl z, StylCnv_Type4_OpenFile
	cps a, 3
	jr z, StylCnv_Type3_ProcessFiles
	cps a, 2
	jr z, .Lc_f6cb6c
	cps a, 1
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

	.byte 0x78, 0xbf, 0x08	; jrl StylCnv_PostModeChange (v7 displacement)



StylCnv_Type3_ProcessFiles:
	ld	xwa, (15552:16)
	ld	(xsp+10), xwa
	ldw	(xsp+4), 0
	calr	61593
	calr	61735
	ld	xwa, 18416
	ld	xbc, 18412
	call	FileIO_SearchStringMatch
	cps	hl, 0
	jr	lt, 114	; -> 0xF6CC10
StylCnv_Type3_SearchLoop:
	.byte 0x9f, 0x04, 0x3f, 0x20, 0x00, 0x69, 0x59, 0xe1
	.byte 0xec, 0x47, 0x20, 0xe8, 0xcf, 0x00, 0x00, 0x00
	.byte 0x00, 0x61, 0x4d, 0x1d, 0x10, 0xab, 0xf8, 0x3b
	.byte 0xbf, 0x16, 0x30, 0x38, 0x1d, 0x70, 0x07, 0xff
	.byte 0x0b, 0x00, 0x00, 0x0b, 0xf0, 0x47, 0xbf, 0x1e
	.byte 0x30, 0x38, 0x1d, 0xe4, 0x05, 0xff, 0xbf, 0x22
	.byte 0x30, 0x38, 0x9f, 0x18, 0x20, 0xd8, 0x08, 0x64
	.byte 0x00, 0xf1, 0x40, 0x48, 0x31, 0xe8, 0x12, 0xe9
	.byte 0x80, 0x38, 0x1d, 0x70, 0x07, 0xff, 0xbf, 0x18
	.byte 0x37, 0x9f, 0x04, 0x22, 0xda, 0xee, 0x02, 0xf1
	.byte 0xc0, 0x54, 0x31, 0xea, 0x12, 0xe9, 0x82, 0xe1
	.byte 0xec, 0x47, 0x20, 0xb2, 0x60, 0x9f, 0x04, 0x61
StylCnv_Type3_SearchNext:
	ld	xwa, 18416
	ld	xbc, 18412
	call	16296648
	cps	hl, 0
	jr	ge, -114
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
	call	16713584
	inc	8, xsp
	lda	xwa, (xsp+18)
	ld	xbc, 14991698
	call	16295962
	cps	hl, 0
	jrl	lt, 404
	ld	wa, (xsp+8)
	sll	wa, 2
	lda	xbc, (21696:16)
	extz	xwa
	add	xwa, xbc
	ld	xbc, (xwa)
	ld	(18412:16), xbc
	ld	xwa, (xsp+10)
	call	16288103
	cp	xhl, 0
	jrl	lt, 364
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
	call	16720173
	inc	6, xsp
	ld	wa, (xsp+8)
	lda	xbc, (16108:16)
	sll	wa, 5
	extz	xwa
	add	xwa, xbc
	or	xhl, xhl
	jr	z, 10
	push	xhl
	push	xwa
	call	16713584
	inc	8, xsp
	jr	3
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
	call	16713148
	lda	xsp, (xsp+10)
	inc	4, qiz
	lds	iz, 0
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
	incw 1, (xsp + 16)
	ld wa, (xsp + 16)
	cp wa, (xsp + 4)
	jrl lt, StylCnv_Type3_CopyBlockLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type4_OpenFile:
	ld	xwa, 18416
	ld	xbc, 14991702
	call	16287674
	cps	hl, 0
	jr	lt, 62
	lds32	xwa, 0
	lds	bc, 2
	call	16288467
	cps	hl, 0
	jr	lt, 46
	call	16288556
	ld	(15560:16), xhl
	call	16288515
	ld	xwa, (18450:16)
	lds	bc, 0
	call	16288467
	cps	hl, 0
	jr	lt, 20
	ld	xwa, (15552:16)
	ld	xbc, (18454:16)
	call	16288103
	cp	xhl, 0
	jr	ge, 10
FileIO_ErrorExit:
	call FileIO_CloseHandle

StylCnv_AbortWithError:
	calr StylCnv_ReportErrorAndReturn
	jrl StylCnv_Epilogue114

StylCnv_Type4_ClearAndBuild:
	calr	61108
	ld	(1047552:24), 255
	ld	(1047553:24), 0
	pushw	4
	pushw	0
	pushw	15552
	ld	xwa, 1047554
	push	xwa
	call	16713148
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
	ldb_sri A, 0x07, 0xe8, 0xe0
	ld (xbc), a
	cps a, 0
	jrl z, StylCnv_FinalizeAndCheckStatus
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Type4_CopyFieldLoop
	jrl StylCnv_FinalizeAndCheckStatus

StylCnv_Type6_Dispatch:
	ld wa, (0x4810:16)
	cps wa, 1
	jrl z, StylCnv_Type6_Case1_CopyName
	cps wa, 0
	jrl nz, StyleConv_DispatchSoundMemState
	lda xwa, (0x46ec:16)
	ld XBC,XWA
	.byte 0xf3, 0xe1, 0x00, 0x01, 0x32
StylCnv_Type6_ClearRegion:
	.byte 0xe8, 0xa8, 0xf5, 0xe6, 0x60, 0xea, 0xf1, 0x67
	.byte 0xf7, 0xe1, 0xc0, 0x3c, 0x20, 0xf1, 0xc4, 0x3c
	.byte 0x60, 0xbf, 0x04, 0x02, 0x00, 0x00, 0xd1, 0x3c
	.byte 0x48, 0x3f, 0x00, 0x00, 0x73, 0xae, 0x00
StylCnv_Type6_MainLoop:
	lds	iz, 0
	lda	xbc, (18416:16)
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
	ld	de, (xsp+4)
	sll	de, 5
	lda	xwa, (16108:16)
	extz	xde
	add	xde, xwa
	push	xde
	push	xbc
	call	16713188
	inc	8, xsp
	ld	xwa, 18416
	ld	xbc, 14991706
	call	16287674
	cps	hl, 0
	jrl	lt, 322
	lds32	xwa, 0
	lds	bc, 2
	call	16288467
	cps	hl, 0
	jrl	lt, 280
	call	16288556
	ld	(15560:16), xhl
	call	16288515
	ld	xwa, (15556:16)
	ld	xbc, (15560:16)
	call	16288103
	call	16287803
	cp	xhl, 0
	jrl	lt, -284
	ld	bc, (xsp+4)
	sll	bc, 2
	lda	xwa, (18156:16)
	extz	xbc
	add	xbc, xwa
	ld	xwa, (15556:16)
	ld	(xbc), xwa
	ld	xwa, (15560:16)
	adddm32	(15556), xwa
StylCnv_Type6_AdvanceEntry:
	incw 1, (xsp + 4)

	ld wa, (xsp + 4)

	.byte 0xd1, 0x3c, 0x48, 0xf0	; cpda16 xwa, 0x48d8 (v7 patched)

	.byte 0x77, 0x52, 0xff	; jrl c, StylCnv_Type6_MainLoop (v7 displacement)



StylCnv_Type6_BuildFfcBuffer:
	calr 60789

	ld (0x0ffc00:24), 0xff

	ld (0x0ffc01:24), 0x00

	ldw (xsp + 4), 0x0

	lds iz, 0

	.byte 0xd1, 0x3c, 0x48, 0x3f, 0x00, 0x00	; cpdi16 0x48d8, 0 (v7 patched)

	.byte 0x73, 0x2c, 0x04	; jrl ule, StylCnv_FinalizeAndCheckStatus (v7 displacement)



StylCnv_Type6_CopyBlockLoop:
	ld	bc, (xsp+4)
	sll	bc, 2
	lda	xde, (18156:16)
	extz	xbc
	add	xbc, xde
	ld	xwa, (xbc)
	or	xwa, xwa
	jrl	z, 134	; -> 0xF6CFE3
	pushw	4
	push	xbc
	ld	wa, iz
	inc	2, wa
	extz	xwa
	add	xwa, 1047552
	push	xwa
	call	16713148
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
	cps a, 0
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
	incw 1, (xsp + 4)

	ld wa, (xsp + 4)

	.byte 0xd1, 0x3c, 0x48, 0xf0	; cpda16 xwa, 0x48d8 (v7 patched)

	.byte 0x77, 0x58, 0xff	; jrl c, StylCnv_Type6_CopyBlockLoop (v7 displacement)

	.byte 0x78, 0x81, 0x03	; jrl StylCnv_FinalizeAndCheckStatus (v7 displacement)



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
	inc 0,XSP
	ld xwa, (0x3cc0:16)
	ld (XSP+0x0a),XWA
	ldw (XSP+0x08), 0x0000
	lda xwa, (xsp + 0x12)
	ld XBC,NakaInst_OFF_Str_0x8C
	call FileIO_OpenWithMode
	cps hl, 0
	jrl lt, StylCnv_AbortWithError
	lds32 xwa, 0
	lds bc, 2
	call FileIO_SeekAndReadBlock
	cps hl, 0
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
	cpib_sri 0x07, 0xe0, 0xe4, 0x2e
	jr z, StylCnv_Single_CopyExtension
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_Single_FindDot

StylCnv_Single_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, StylCnv_Single_RenameTM

StylCnv_Single_CopyExt_Loop:
	.byte 0xde, 0x8a, 0xf1, 0xec, 0x3e, 0x31, 0xea, 0x12
	.byte 0xe9, 0x82, 0x9f, 0x04, 0x21, 0xc3, 0x07, 0xe0
	.byte 0xe4, 0x23, 0xb2, 0x43, 0xcb, 0xd8, 0x66, 0x0c
	.byte 0x9f, 0x04, 0x61, 0xde, 0x61, 0x9f, 0x04, 0x3f
	.byte 0x20, 0x00, 0x61, 0xdc
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
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x54
	ld	bc, (xsp+4)
	inc	1, bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x4d
	ld	bc, (xsp+4)
	inc	2, bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x00
	ld	xbc, 14991714
	call	16287674
	cps	hl, 0
	jrl	lt, 143
	lds32	xwa, 0
	lds	bc, 2
	call	16288467
	cps	hl, 0
	jrl	lt, 130
	ldw	(xsp+8), 1
	call	16288556
	ld	(xsp+14), xhl
	call	16288515
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+14)
	call	16288103
	call	16287803
	cp	xhl, 0
	jrl	lt, -899
	ld	xwa, (xsp+10)
	ld	(18160:16), xwa
	ld	xwa, (xsp+14)
	add	(xsp+10), xwa
	ldw	(xsp+4), 0
	lda	xbc, (xsp+18)
StylCnv_LSW_FindDot:
	ld wa, (xsp + 4)
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
	jr z, StylCnv_LSW_CopyExtension
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot

StylCnv_LSW_CopyExtension:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, DRI_ParseFieldsAndOpenFile

StylCnv_LSW_CopyExt_Loop:
	.byte 0xde, 0x8a, 0xda, 0xc8, 0x20, 0x00, 0xf1, 0xec
	.byte 0x3e, 0x30, 0xea, 0x12, 0xe8, 0x82, 0x9f, 0x04
	.byte 0x20, 0xc3, 0x07, 0xe4, 0xe0, 0x21, 0xb2, 0x41
	.byte 0xc9, 0xd8, 0x66, 0x0c, 0x9f, 0x04, 0x61, 0xde
	.byte 0x61, 0x9f, 0x04, 0x3f, 0x20, 0x00, 0x61, 0xd8
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
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x4c
	ld	bc, (xsp+4)
	inc	1, bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x53
	ld	bc, (xsp+4)
	inc	2, bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x57
	ld	bc, (xsp+4)
	inc	3, bc
	.byte 0xf3, 0x07, 0xe0, 0xe4, 0x00, 0x00
	ld	xbc, 14991718
	call	16287674
	cps	hl, 0
	jrl	lt, 154
	lds32	xwa, 0
	lds	bc, 2
	call	16288467
	cps	hl, 0
	jrl	lt, 141
	incw	1, (xsp+8)
	call	16288556
	ld	(xsp+14), xhl
	call	16288515
	ld	xwa, (xsp+10)
	ld	xbc, (xsp+14)
	call	16288103
	call	16287803
	cp	xhl, 0
	jrl	lt, -1126
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
	cpib_sri 0x07, 0xe4, 0xe0, 0x2e
	jr z, StylCnv_LSW_CopyExt3
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x20
	jr lt, StylCnv_LSW_FindDot3

StylCnv_LSW_CopyExt3:
	lds iz, 0
	cpw (xsp + 4), 0x20
	jr ge, FileLoad_ResetAndStartProcessing

StylCnv_LSW_CopyExt3_Loop:
	.byte 0x9f, 0x10, 0x20, 0xd8, 0xee, 0x05, 0xde, 0x8a
	.byte 0xd8, 0x82, 0xf1, 0xec, 0x3e, 0x30, 0xea, 0x12
	.byte 0xe8, 0x82, 0x9f, 0x04, 0x20, 0xc3, 0x07, 0xe4
	.byte 0xe0, 0x21, 0xb2, 0x41, 0xc9, 0xd8, 0x66, 0x0c
	.byte 0x9f, 0x04, 0x61, 0xde, 0x61, 0x9f, 0x04, 0x3f
	.byte 0x20, 0x00, 0x61, 0xd4
FileLoad_ResetAndStartProcessing:
	calr SoundMem_ClearRegion
	ld (0x0ffc00:24), 0xff
	ld (0x0ffc01:24), 0x00
	ldw (xsp + 4), 0x0
	lds iz, 0
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
	call 0xff05bc
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
	cps a, 0
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
	incw 1, (xsp + 4)
	ld wa, (xsp + 8)
	inc 1, wa
	cp (xsp + 4), wa
	jrl lt, StylCnv_Final_CopyBlockLoop

StylCnv_FinalizeAndCheckStatus:
	calr TableData_JumpToEntry
	jrl StyleConv_DispatchSoundMemState

StylCnv_Multi_InitAndClear:
	calr	59598
	ldw	(14822:16), 0
	lda	xbc, (xsp+18)
	ld	xwa, xbc
	lda	xbc, (xbc+100)
StylCnv_Multi_ClearLoop:
	stib_dsp 0xe0, 0x00
	cp xwa, xbc
	jr c, StylCnv_Multi_ClearLoop
	ldw (xsp + 4), 0x0
	lds iz, 0

StylCnv_Multi_ParseLoop:
	lda xbc, (0x3ccc:16)
	ld WA,(XSP+0x04)
	lda_dri xhl, 0x07, 0xe4, 0xe0
	ld E,(XHL)
	lda xbc, (xsp + 0x12)
	lda xwa, (0x5548:16)
	ld (XSP+0x0e),XWA
	cps e, 0
	jr nz, .Lc_f6d3d7
	cps iz, 0
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
	inc 0,XSP
	incw 1, (0x39e6:16)
	jr t, StylCnv_Multi_Finalize
StylCnv_Multi_HandleSeparator:
.Lc_f6d3d7:
	cp E,0x7c
	jr nz, StylCnv_Multi_CopyChar
	ld (XHL),0x00
	ldw (XSP+0x06), 0x0000
	inc 1,IZ
	cps iz, 1
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
	inc 0,XSP
	lda xbc, (xsp + 0x12)
	ld XWA,XBC
	lda xbc, (xbc + 0x64)
StylCnv_Multi_ClearSubLoop:
	stib_dsp	224, 0
	cp	xwa, xbc
	jr	c, -8
	incw	1, (14822:16)
	jr	18
StylCnv_Multi_CopyChar:
	cps iz, 0
	jr le, LoopCounter_Increment
	ld wa, (xsp + 6)
	stb_dri E, 0x07, 0xe4, 0xe0
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
	.incbin "includes/romslices/v7_fix_accstyle_tabledataentry.bin"
	.include "sequencer/accompseq_routines.s"
