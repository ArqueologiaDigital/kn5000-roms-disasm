; =============================================================================
; Sequencer Audio Mode & Accompaniment Processing (2K lines)
; =============================================================================
;
; Audio mode stereo flags, accompaniment pedal processing,
; sequencer timing setup, part activation, and audio flag
; dispatch between SMF event processing and rhythm routines.
; =============================================================================

	ei 0
	stda8 12927, a
	ret

AudioMode_CheckAndUpdateStereo:
	bitda 3, 12932
	jr z, AudioMode_CheckDone
	ldda8 a, 12927
	cp a, 0x5D
	jr nc, AudioMode_ApplyStereoUpdate
	cp a, 0x30
	jr ugt, AudioMode_CheckDone

AudioMode_ApplyStereoUpdate:
	call AudioMode_SetStereoFlags
	anddi8 12932, 247

AudioMode_CheckDone:
	ret

AudioMode_MergeOutputBits:
	ldda8 a, 13072
	and a, 0xF8
	ldda8 w, 13049
	and w, 0x7
	or a, w
	stda8 13072, a
	ret

AudioMode_CopyChannelMode:
	ldda8 a, 10418
	and a, 0x3
	stda8 13109, a
	ret

AudioMode_CopyAccentFlags:
	ldda8 a, 13553
	and a, 0x3D
	stda8 13154, a
	ret

AccPedal_BytecodeBlock1:
	.byte 0x28, 0x3d, 0xc1, 0x63, 0x33, 0x3c, 0xfe, 0x45
	.byte 0x00, 0x48, 0x09, 0x00, 0xed, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0x85, 0x21, 0xc9, 0x33, 0x00, 0x66
	.byte 0x05, 0xc1, 0x63, 0x33, 0x3e, 0x01, 0x5d, 0x48
	.byte 0x0e

AccPedal_SetFlag13155:
	pushw wa
	push xiy
	ordi8 13155, 1
	pop xiy
	popw wa
	ret

AccPedal_PartOffsetTable:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00

AccPedal_ProcessAllChanges:
	xor wa, wa
	ld xhl, 0xE46BB0
	ldda8 a, 1075
	bit_dri 0, 0x07, 0xEC, 0xE0
	jrl z, AccPedal_ReadBankAndReturn
	xor a, a
	bitda 0, 13051
	jr z, AccPedal_CheckBit1Left
	or a, 0x40

AccPedal_CheckBit1Left:
	bitda 1, 13051
	jr z, AccPedal_CheckBit0Right
	or a, 0x80

AccPedal_CheckBit0Right:
	bitda 0, 13053
	jr z, AccPedal_CheckBit1Right
	or a, 0x10

AccPedal_CheckBit1Right:
	bitda 1, 13053
	jr z, AccPedal_CheckBit0Aux
	or a, 0x20

AccPedal_CheckBit0Aux:
	bitda 0, 13055
	jr z, AccPedal_CheckBit1Aux
	or a, 0x4

AccPedal_CheckBit1Aux:
	bitda 1, 13055
	jr z, AccPedal_ApplyChangeMask
	or a, 0x8

AccPedal_ApplyChangeMask:
	cps a, 0
	jr z, AccPedal_CheckAuxBit2
	ld w, a
	xor w, 0xFF
	anddm8 64607, w
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

AccPedal_CheckAuxBit2:
	bitda 2, 13055
	jr z, AccPedal_ClearAllPedalFlags
	anddi8 64608, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

AccPedal_ClearAllPedalFlags:
	xor a, a
	stda8 13051, a
	stda8 13053, a
	stda8 13055, a

AccPedal_ReadBankAndReturn:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	xor wa, wa
	ld xhl, 0xE46BB0
	ldda8 a, 1075
	ld_srib3 A, 0x07, 0xEC, 0xE0
	bitda 0, 12931
	jr nz, AccVoice_StoreBankAssign
	ldb a, 0x0

AccVoice_StoreBankAssign:
	stda8 12930, a
	ret

AccChannel_CompareAndMarkDirty:
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, AccChannel_StoreCurrentState
	ldda8 a, 13045
	cpda8 a, 13046
	jr nz, AccChannel_MarkDirtyAndSync
	ldda8 a, 13047
	and a, 0x7F
	and a, 0x7
	ldda8 w, 13048
	and w, 0x7F
	and w, 0x7
	cp a, w
	jr z, AccChannel_StoreCurrentState

AccChannel_MarkDirtyAndSync:
	calr AccChannel_SetDirtyIfActive
	calr AccChannel_CheckActivitySetDirty
	calr AccChannel_CheckPartIndexDirty
	ordi8 13068, 1

AccChannel_StoreCurrentState:
	ldda8 a, 13045
	stda8 13031, a
	ldda8 a, 13047
	and a, 0x7F
	and w, 0x7
	stda8 13032, a
	ret

AccChannel_BytecodeBlock2:
	.byte 0xc1, 0xf5, 0x32, 0x21, 0xc1, 0xf6, 0x32, 0xf1
	.byte 0x6e, 0x1d, 0xc9, 0xcf, 0x80, 0x6f, 0x2e, 0xc1
	.byte 0xf7, 0x32, 0x21, 0xc9, 0xcc, 0x7f, 0xc9, 0xcc
	.byte 0x07, 0xc1, 0xf8, 0x32, 0x20, 0xc8, 0xcc, 0x7f
	.byte 0xc8, 0xcc, 0x07, 0xc8, 0xf1, 0x66, 0x16, 0xc1
	.byte 0xf5, 0x32, 0x21, 0xf1, 0xe7, 0x32, 0x41, 0xc1
	.byte 0xf7, 0x32, 0x21, 0xc8, 0xcc, 0x7f, 0xc8, 0xcc
	.byte 0x07, 0xf1, 0xe8, 0x32, 0x41, 0x0e

AccChannel_SetDirtyIfActive:
	ldda16 xwa, 13027
	and w, 0x7
	cps w, 0
	jr z, AccChannel_SetDirtyDone
	ordi8 13094, 63

AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	ldda8 a, 13074
	orda8 a, 13075
	orda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	and a, 0x3F
	jr z, AccChannel_ActivityCheckDone
	cpdi8 13045, 128
	jr c, AccChannel_ActivityCheckDone
	ordi8 13094, 63

AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	ldda8 a, 1075
	cps a, 1
	jr nz, AccChannel_PartIndexDone
	ordi8 13094, 63

AccChannel_PartIndexDone:
	ret

AccVoice_ProcessPedalChanges:
	bitda 0, 13055
	jr z, AccVoice_Pedal0_Done
	bitda 0, 13056
	jr nz, AccVoice_Pedal0_Done
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 243
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, AccVoice_Pedal0_SetAndCheck
	anddi8 13094, 192

AccVoice_Pedal0_SetAndCheck:
	ordi8 13066, 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal0_Done:
	bitda 1, 13055
	jr z, AccVoice_Pedal1_Done
	bitda 1, 13056
	jr nz, AccVoice_Pedal1_Done
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 246
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, AccVoice_Pedal1_SetAndCheck
	anddi8 13094, 192

AccVoice_Pedal1_SetAndCheck:
	ordi8 13066, 4
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal1_Done:
	bitda 2, 13055
	jr z, AccVoice_Pedal2_Done
	bitda 2, 13056
	jr nz, AccVoice_Pedal2_Done
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 250
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, AccVoice_Pedal2_SetAndCheck
	anddi8 13094, 192

AccVoice_Pedal2_SetAndCheck:
	ordi8 13066, 8
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal2_Done:
	ret

AccVoice_ProcessLeftPedalChanges:
	bitda 0, 13051
	jr z, AccVoice_LeftPedal0_Done
	bitda 0, 13052
	jr nz, AccVoice_LeftPedal0_Done
	xor a, a
	stda8 13066, a
	stda8 13067, a
	anddi8 13065, 253
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, AccVoice_LeftPedal0_SetAndCheck
	anddi8 13094, 192

AccVoice_LeftPedal0_SetAndCheck:
	ordi8 13065, 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_LeftPedal0_Done:
	bitda 1, 13051
	jr z, AccVoice_LeftPedal1_Done
	bitda 1, 13052
	jr nz, AccVoice_LeftPedal1_Done
	xor a, a
	stda8 13066, a
	stda8 13067, a
	anddi8 13065, 254
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, AccVoice_LeftPedal1_SetAndCheck
	anddi8 13094, 192

AccVoice_LeftPedal1_SetAndCheck:
	ordi8 13065, 2
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_LeftPedal1_Done:
	ret

AccVoice_CheckChannelSetActive:
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr z, AccVoice_ChannelActiveDone
	ordi8 13071, 1

AccVoice_ChannelActiveDone:
	ret

AccVoice_CheckBitsAndSetFlags:
	ldda16 xde, 13027
	and d, 0x7
	inc 1, d
	cpda8 d, 1075
	jr nz, AccVoice_BitsCheckDone
	ordi8 13095, 63

AccVoice_BitsCheckDone:
	ret

AccPitch_CheckTransposeFlags:
	bitda 6, 13424
	jr nz, AccPitch_UpdateCheck
	bitda 6, 12929
	jr z, AccPitch_UpdateCheck
	ldda8 a, 12928
	inc 1, a
	cpda8 a, 1075
	jr nz, AccPitch_UpdateCheck
	ordi8 13097, 63

AccPitch_UpdateCheck:
	bitda 7, 13424
	jr nz, AccPitch_FinalReturn
	bitda 7, 12929
	jr z, AccPitch_FinalReturn
	ldda8 a, 12928
	inc 1, a
	cpda8 a, 1075
	jr nz, AccPitch_FinalReturn
	ordi8 13097, 63

AccPitch_FinalReturn:
	ret

AccChord_ProcessKeyChanges:
	bitda 0, 13053
	jr z, AccChord_KeyChange0_Done
	bitda 0, 13054
	jr nz, AccChord_KeyChange0_Done
	xor a, a
	stda8 13066, a
	stda8 13065, a
	anddi8 13095, 192
	anddi8 13067, 253
	anddi8 13094, 192
	ordi8 13067, 1
	calr AccChannel_SetDirtyIfActive

AccChord_KeyChange0_Done:
	bitda 1, 13053
	jr z, AccChord_KeyChange1_Done
	bitda 1, 13054
	jr nz, AccChord_KeyChange1_Done
	xor a, a
	stda8 13066, a
	stda8 13065, a
	anddi8 13095, 192
	anddi8 13067, 254
	anddi8 13094, 192
	ordi8 13067, 2
	calr AccChannel_SetDirtyIfActive

AccChord_KeyChange1_Done:
	ret

AccChord_ResolveVoiceAndDispatch:
	ldda8 a, 13029
	ldda8 w, 13095
	and w, 0x3F
	jr z, AccChord_CheckRange
	ldda8 a, 13031

AccChord_CheckRange:
	cp a, 0x80
	jrl c, AccChord_NullRet
	cp a, 0xF0
	jr c, AccChord_MaskAndContinue
	ldda8 a, 13297
	jr AccChord_DispatchVoiceChange

AccChord_MaskAndContinue:
	and a, 0x7F

AccChord_DispatchVoiceChange:
	calr AccPatch_SetVoiceParam
	ld c, a
	xor a, a
	bitda 0, 13066
	jr z, AccChord_CheckVoiceBit2
	cpda8 c, 13156
	jr z, AccChord_CheckVoiceBit2
	anddi8 13066, 254
	anddi8 13095, 192
	anddi8 13055, 254
	or a, 0x4

AccChord_CheckVoiceBit2:
	bitda 2, 13066
	jr z, AccChord_CheckLeftPedal0
	ld xhl, 0xE46BB0
	bit_dri 0, 0x03, 0xEC, 0xE4
	jr z, AccChord_CheckLeftPedal0
	anddi8 13066, 251
	anddi8 13095, 192
	anddi8 13055, 253
	or a, 0x8

AccChord_CheckLeftPedal0:
	bitda 0, 13065
	jr z, AccChord_CheckLeftPedal1
	cpda8 c, 13160
	jr z, AccChord_CheckLeftPedal1
	anddi8 13065, 254
	anddi8 13095, 192
	anddi8 13051, 254
	or a, 0x40

AccChord_CheckLeftPedal1:
	bitda 1, 13065
	jr z, AccChord_CheckKeyChange0
	cpda8 c, 13162
	jr z, AccChord_CheckKeyChange0
	anddi8 13065, 253
	anddi8 13095, 192
	anddi8 13051, 253
	or a, 0x80

AccChord_CheckKeyChange0:
	bitda 0, 13067
	jr z, RhythmPart_ProcessBit0
	cpda8 c, 13164
	jr z, RhythmPart_ProcessBit0
	anddi8 13067, 254
	anddi8 13053, 254
	or a, 0x10
	bitda 0, 13068
	jr nz, RhythmPart_ProcessBit0
	anddi8 13095, 192

RhythmPart_ProcessBit0:
	bitda 1, 13067
	jr z, RhythmPart_ProcessBit1
	cpda8 c, 13166
	jr z, RhythmPart_ProcessBit1
	anddi8 13067, 253
	anddi8 13053, 253
	or a, 0x20
	bitda 0, 13068
	jr nz, RhythmPart_ProcessBit1
	anddi8 13095, 192

RhythmPart_ProcessBit1:
	cps a, 0
	jr z, AccChord_CheckExtraDirtyBit3
	ldb w, 0x0
	xor a, 0xFF
	anddm8 64607, a
	ldb a, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckExtraDirtyBit3:
	bitda 3, 13066
	jr z, AccChord_CheckPitchDirty
	cpda8 c, 13158
	jr z, AccChord_CheckPitchDirty
	anddi8 13066, 247
	anddi8 13095, 192
	anddi8 13055, 251
	anddi8 64607, 251
	ldb a, 0x0
	ldb w, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckPitchDirty:
	ldda8 a, 13097
	and a, 0x3F
	jr z, AccChord_NullRet
	bitda 0, 13051
	jr z, AccChord_CheckPitchLeftPedal1
	cpda8 c, 13160
	jr z, AccChord_NullRet
	anddi8 13097, 192
	jr AccChord_NullRet

AccChord_CheckPitchLeftPedal1:
	bitda 1, 13051
	jr z, AccChord_NullRet
	ld xhl, 0xE46BB0
	bit_dri 0, 0x03, 0xEC, 0xE4
	jr z, AccChord_NullRet
	anddi8 13097, 192

AccChord_NullRet:
	ret

AccChord_CompareAndSetDirty:
	ldda8 a, 13016
	cpda8 a, 13020
	jr nz, AccChord_SetDirtyBit5
	ldda8 a, 13018
	cpda8 a, 13022
	jr z, AccChord_CheckZeroChord

AccChord_SetDirtyBit5:
	ordi8 13043, 32

AccChord_CheckZeroChord:
	cpdi8 13020, 0
	jr nz, AccChord_CompareDone
	anddi8 13043, 223

AccChord_CompareDone:
	ret

AccentVoice_DetectAndMarkChange:
	ldda8 a, 13061
	cpda8 a, 13062
	jr z, AccentVoice_UpdateParamIndex
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, AccentVoice_UpdateParamIndex
	cpdi8 13029, 240
	jr nc, AccentVoice_UpdateParamIndex
	cpdi8 13029, 128
	jr nc, AccentVoice_UpdateParamIndex
	bitda 0, 13057
	jr z, AccentVoice_CheckModeChange
	ldda8 a, 13074
	orda8 a, 13075
	and a, 0x3F
	jr nz, AccentVoice_UpdateParamIndex

AccentVoice_CheckModeChange:
	ldda8 a, 13061
	and a, 0x3
	cpda8 a, 13112
	jr z, AccentVoice_UpdateParamIndex
	ordi8 13069, 1

AccentVoice_UpdateParamIndex:
	ldda8 a, 13061
	and a, 0x3
	stda8 13114, a
	ret

AccVoice_ResolveParamAddr:
	push xwa
	push xix
	ld xiy, 0xE46312
	cp a, 0x1D
	jr ule, AccVoice_ComputeParamOffset
	xor a, a

AccVoice_ComputeParamOffset:
	extz wa
	sla wa, 2
	extz xwa
	add xiy, xwa
	ld xiy, (xiy)
	ldda8 a, 13030
	extz wa
	sla wa, 2
	ld xix, 0xF53D57
	ld_sril3 XIX, 0x07, 0xF0, 0xE0
	add xiy, xix
	add xiy, 0x60
	pop xix
	pop xwa
	ret

AccVoice_PartOffsetTable2:
	.byte 0x00, 0x48, 0x09, 0x00, 0x00, 0x00, 0x30, 0x00
	.byte 0x00, 0x98, 0x31, 0x00, 0x00, 0x00, 0x33, 0x00
	.byte 0x00, 0x98, 0x34, 0x00, 0x00, 0x00, 0x36, 0x00
	.byte 0x00, 0x98, 0x37, 0x00, 0x00, 0x00, 0x39, 0x00

AccVoice_ComputeChannelIndex:
	and h, 0x7
	sla h, 1
	xor w, w
	sla wa, 2
	xor l, l
	add hl, wa
	ld xiy, 0xE45142
	ld_sriw3 WA, 0x07, 0xF4, 0xEC
	add hl, 0x2
	ld_sriw3 IY, 0x07, 0xF4, 0xEC
	ret

AccVoice_LookupWithOffset:
	calr AccVoice_ComputeChannelIndex
	call AccVoice_TableLookup_Inner
	extz xiy
	add xhl, xiy
	ld xiy, xhl
	ret

AccVoice_SelectAndApplyPatch:
	cpdi8 13029, 128
	jr nc, AccVoice_PatchFromDirect
	ldda32 xiy, 13006
	calr AccStyle_ReadVoiceParam
	stda8 13039, w
	jr AccVoice_StorePatchAndLookup

AccVoice_PatchFromDirect:
	ldda8 a, 13029
	and a, 0x7F
	calr AccPatch_SetVoiceParam

AccVoice_StorePatchAndLookup:
	stda8 1075, a
	ld xhl, 0xE46B9E
	sla a, 1
	ld_sriw3 WA, 0x03, 0xEC, 0xE0
	stda16 12923, xwa
	ret

AccStyle_ReadVoiceParam:
	ld_srib W, (xiy + 0x03da)
	ld_srib A, (xiy + 0x03d0)
	ld xhl, 0xE46B8A
	ld_srib3 A, 0x03, 0xEC, 0xE0
	ret

; ============================================================================
; AccPatch_SetVoiceParam - Set accompaniment voice parameter
; ============================================================================
; Clamps register A to <= 0x1D (29 voices), then indexes into table at
; 0xE46B8A to set a voice parameter. Called 148+ times, typically in
; rapid bursts during accompaniment patch configuration.
; ============================================================================
AccPatch_SetVoiceParam:
	cp a, 0x1D
	jr ule, AccPatch_ClampedSetParam
	xor a, a

AccPatch_ClampedSetParam:
	ld w, a
	calr AccVoice_ResolveParamAddr
	ld a, (xiy + 12)
	ld xhl, 0xE46B8A
	ld_srib3 A, 0x03, 0xEC, 0xE0
	ret

AccVoice_LoadTuningBlock:
	push xiy
	add xhl, 0x248
	add xiy, xhl
	ld xix, 0x3246
	ldw bc, 0x31
	ldir85
	push xwa
	push xix
	ld xix, 0x3246
	ldw wa, 0x9
	stib_dri 0x07, 0xF0, 0xE0, 0x40
	ldw wa, 0x10
	stib_dri 0x07, 0xF0, 0xE0, 0x0C
	ldw wa, 0x17
	stib_dri 0x07, 0xF0, 0xE0, 0x74
	ldw wa, 0x1E
	stib_dri 0x07, 0xF0, 0xE0, 0x40
	pop xix
	pop xwa
	pop xiy
	call AccTuning_LoadFromROM
	nop
	nop
	nop
	nop
	ret

AccTuning_CopyAllPartsFromStyle:
	push xiy
	ld xhl, xiy
	add xiy, 0x18
	ld xix, 0x3246
	lds bc, 7
	ldir85
	ld xiy, xhl
	add xiy, 0x20
	ld xix, 0x324D
	lds bc, 7
	ldir85
	ld xiy, xhl
	add xiy, 0x28
	ld xix, 0x3254
	lds bc, 7
	ldir85
	ld xiy, xhl
	add xiy, 0x30
	ld xix, 0x325B
	lds bc, 7
	ldir85
	ld xiy, xhl
	add xiy, 0x38
	ld xix, 0x3262
	lds bc, 7
	ldir85
	pop xiy
	ret

AccTuning_LoadAndApplyMaster:
	push xiy
	add xhl, 0x248
	add xiy, xhl
	ld xix, 0x3246
	lds bc, 7
	ldir85
	call AccTuning_LoadMaster
	pop xiy
	nop
	nop
	nop
	nop
	ret

AccTuning_LoadCoarseFromStyle:
	push xiy
	add xhl, 0x24F
	add xiy, xhl
	ld xix, 0x324D
	lds bc, 7
	ldir85
	ld xix, 0x324F
	ld (xix), 0x40
	call AccTuning_LoadCoarse
	pop xiy
	nop
	nop
	nop
	nop
	ret

AccTuning_LoadFineFromStyle:
	push xiy
	add xhl, 0x256
	add xiy, xhl
	ld xix, 0x3254
	lds bc, 7
	ldir85
	ld xix, 0x3256
	ld (xix), 0xC
	call AccTuning_LoadFine
	pop xiy
	nop
	nop
	nop
	nop
	ret

AccTuning_LoadOctaveFromStyle:
	push xiy
	add xhl, 0x25D
	add xiy, xhl
	ld xix, 0x325B
	lds bc, 7
	ldir85
	ld xix, 0x325D
	ld (xix), 0x74
	call AccTuning_LoadOctave
	pop xiy
	nop
	nop
	nop
	nop
	ret

AccTuning_LoadTransposeFromStyle:
	push xiy
	add xhl, 0x264
	add xiy, xhl
	ld xix, 0x3262
	lds bc, 7
	ldir85
	ld xix, 0x3264
	ld (xix), 0x40
	call AccTuning_LoadTranspose
	pop xiy
	nop
	nop
	nop
	nop
	ret

Rhythm_ProcessAllPartsAndLoad:
	calr RhythmPart_CopyData
	calr RhythmPart1_ProcessAccentData
	calr RhythmPart2_ProcessAccentData
	calr AccVoice_LoadRhythmParams_Part3
	calr AccVoice_LoadRhythmParams_Part4
	calr AccVoice_LoadRhythmParams_Part5
	bitda 0, 12931
	jr nz, Rhythm_ProcessAllDone
	call AccVoice_LoadAllChannelParams

Rhythm_ProcessAllDone:
	ret

RhythmPart_CopyData:
	ldw bc, 0x19
	ld xiy, 0x3214
	ld xix, 0x322D
	ldir85
	ret

RhythmPart1_ProcessAccentData:
	bitda 0, 12931
	jr z, RhythmPart1_CheckAccentData
	call AccentData_ComparePart1

RhythmPart1_CheckAccentData:
	ldda8 a, 13100
	and a, 0x3
	jr z, RhythmPart1_WriteDone
	ldda8 e, 12870
	ldda8 d, 12871
	bitda 0, 12931
	jr nz, RhythmPart1_ProcessRingBuf
	ld xhl, 0x3214
	ld (xhl), e
	ld (xhl + 1), d
	jr RhythmPart1_WriteDone

RhythmPart1_ProcessRingBuf:
	ld xhl, 0x2A94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xC0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XIX, 0x07, 0xEC, 0xF4
	ldb w, 0x0
	calr RingBuf_AdvanceIndex
	lda_dri3 XWA, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XWA, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XWA, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3214
	ld (xhl), e
	ld (xhl + 1), d

RhythmPart1_WriteDone:
	anddi8 13100, 252
	call AccVoiceReg_WritePart1
	ret

RhythmAccent_CopyAndUpdateRingBuf:
	pushw de
	pushw wa
	ldda8 a, 13036
	stda8 13358, a
	calr RhythmAccent_UpdateRingBufPosition
	popw wa
	popw de
	ret

RhythmAccent_UpdateRingBufPosition:
	ldda8 a, 13358
	ei 6
	subda8 a, 1124
	jr ugt, RhythmAccent_StorePosition
	ldb a, 0x1
	stda8 13358, a
	cpdi8 1122, 0
	jr z, RhythmAccent_AddAndCompare
	xor a, a
	jr RhythmAccent_AddAndCompare

RhythmAccent_StorePosition:
	stda8 13358, a

RhythmAccent_AddAndCompare:
	ldda8 w, 1122
	add a, w
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 w, 13174
	cp a, w
	jr nc, RhythmAccent_UpdateDone
	stda8 13174, a

RhythmAccent_UpdateDone:
	ei 0
	ret

; ============================================================================
; RingBuf_AdvanceIndex - Advance circular buffer index with wraparound
; ============================================================================
; Input:  IY = current index, BC = limit, XHL+256 = reset value
; Output: IY = incremented index (wrapped if >= limit)
; Called 110+ times, typically in bursts of 5-7 sequential calls while
; storing/loading data parameters through the ring buffer.
; ============================================================================
RingBuf_AdvanceIndex:
	add iy, 0x1
	cp iy, bc
	jr ule, RingBuf_IndexOK
	ld iy, (xhl + 256)

RingBuf_IndexOK:
	ret

RhythmPart2_ProcessAccentData:
	bitda 0, 12931
	jr z, RhythmPart2_LoadAndStore
	call AccentData_ComparePart2

RhythmPart2_LoadAndStore:
	bitda 2, 13100
	ldda8 e, 12877
	ldda8 d, 12878
	ldda8 a, 12879
	stda8 13359, a
	ldda8 a, 12880
	stda8 13360, a
	ldda8 a, 12881
	stda8 13361, a
	ldda8 a, 12882
	stda8 12995, a
	ldda8 a, 12883
	stda8 12999, a
	calr Rhythm_PackVelocityHighBit
	bitda 0, 12931
	jr nz, RhythmPart2_ProcessRingBuf
	ld xhl, 0x3219
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart2_WriteDone

RhythmPart2_ProcessRingBuf:
	ld xhl, 0x2C94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xC0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XIX, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13361
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3219
	calr AccVoiceReg_StoreParamRecord

RhythmPart2_WriteDone:
	anddi8 13100, 251
	call AccVoiceReg_WritePart2
	ret

AccVoiceReg_StoreParamRecord:
	ld (xhl), e
	ld (xhl + 1), d
	ldda8 a, 13359
	ld (xhl + 2), a
	ldda8 a, 13360
	ld (xhl + 3), a
	ldda8 a, 13361
	ld (xhl + 4), a
	ret

Rhythm_PackVelocityHighBit:
	bit 7, e
	jr z, Rhythm_VelocityPackDone
	or d, 0x10
	and e, 0x7F

Rhythm_VelocityPackDone:
	ret

AccVoice_LoadRhythmParams_Part3:
	bitda 0, 12931
	jr z, RhythmPart3_LoadAndStore
	call AccentData_ComparePart3

RhythmPart3_LoadAndStore:
	bitda 3, 13100
	ldda8 e, 12884
	ldda8 d, 12885
	ldda8 a, 12886
	stda8 13359, a
	ldda8 a, 12887
	stda8 13360, a
	ldda8 a, 12888
	stda8 13361, a
	ldda8 a, 12889
	stda8 12996, a
	ldda8 a, 12890
	stda8 13000, a
	calr Rhythm_PackVelocityHighBit
	bitda 0, 12931
	jr nz, RhythmPart3_ProcessRingBuf
	ld xhl, 0x321E
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart3_WriteDone

RhythmPart3_ProcessRingBuf:
	ld xhl, 0x2D94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xC0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XIX, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13361
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x321E
	calr AccVoiceReg_StoreParamRecord

RhythmPart3_WriteDone:
	anddi8 13100, 247
	call AccVoiceReg_WritePart3
	ret

AccVoice_LoadRhythmParams_Part4:
	bitda 0, 12931
	jr z, RhythmPart4_LoadAndStore
	call AccentData_ComparePart4

RhythmPart4_LoadAndStore:
	bitda 4, 13100
	ldda8 e, 12891
	ldda8 d, 12892
	ldda8 a, 12893
	stda8 13359, a
	ldda8 a, 12894
	stda8 13360, a
	ldda8 a, 12895
	stda8 13361, a
	ldda8 a, 12896
	stda8 12997, a
	ldda8 a, 12897
	stda8 13001, a
	calr Rhythm_PackVelocityHighBit
	bitda 0, 12931
	jr nz, RhythmPart4_ProcessRingBuf
	ld xhl, 0x3223
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart4_WriteDone

RhythmPart4_ProcessRingBuf:
	ld xhl, 0x2E94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xC0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XIX, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13361
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3223
	calr AccVoiceReg_StoreParamRecord

RhythmPart4_WriteDone:
	anddi8 13100, 239
	call AccVoiceReg_WritePart4
	ret

AccVoice_LoadRhythmParams_Part5:
	bitda 0, 12931
	jr z, RhythmPart5_LoadAndStore
	call AccentData_ComparePart5

RhythmPart5_LoadAndStore:
	bitda 5, 13100
	ldda8 e, 12898
	ldda8 d, 12899
	ldda8 a, 12900
	stda8 13359, a
	ldda8 a, 12901
	stda8 13360, a
	ldda8 a, 12902
	stda8 13361, a
	ldda8 a, 12903
	stda8 12998, a
	ldda8 a, 12904
	stda8 13002, a
	calr Rhythm_PackVelocityHighBit
	bitda 0, 12931
	jr nz, RhythmPart5_ProcessRingBuf
	ld xhl, 0x3228
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart5_WriteDone

RhythmPart5_ProcessRingBuf:
	ld xhl, 0x2F94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	stib_dri 0x07, 0xEC, 0xF4, 0xC0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	lda_dri3 XIY, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	lda_dri3 XIX, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13359
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 a, 13361
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3228
	calr AccVoiceReg_StoreParamRecord

RhythmPart5_WriteDone:
	anddi8 13100, 223
	call AccVoiceReg_WritePart5
	ret

AccompVoice_BulkReadRegisters:
	ldb a, 0x0
	ld xhl, 0x3094
	xor iy, iy

BulkRead_Loop1_6Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, BulkRead_Loop1_6Byte
	ld xhl, 0x30C4
	xor iy, iy

BulkRead_Loop2_6Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, BulkRead_Loop2_6Byte
	ld xhl, 0x30F4
	xor iy, iy

BulkRead_Loop3_9Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop3_9Byte
	ld xhl, 0x313C
	xor iy, iy

BulkRead_Loop4_9Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop4_9Byte
	ld xhl, 0x3184
	xor iy, iy

BulkRead_Loop5_9Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop5_9Byte
	ld xhl, 0x31CC
	xor iy, iy

BulkRead_Loop6_9Byte:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop6_9Byte
	ret

Rhythm_SendNoteOnMax:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x7F
	calr Rhythm_Send3ByteMsg
	ret

Rhythm_Send3ByteMsg:
	stda8 13282, a
	stda8 13283, w
	stda8 13284, e
	ldda8 a, 13282
	call Rhythm_SendByte
	ldda8 a, 13283
	call Rhythm_SendByte
	ldda8 a, 13284
	call Rhythm_SendByte
	ret

Rhythm_SendChanPressure:
	ldb a, 0xD0
	ldb w, 0x3
	ldb e, 0x0
	calr Rhythm_Send3ByteMsg
	ldb a, 0x0
	stda8 13103, a
	stda8 13104, a
	stda8 13105, a
	stda8 13106, a
	ret

AccBuf_ResetAndReload:
	call AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	call AccStyle_InitVRAM_Wrap
	ret

AccVoice_LoadAllChannelParams:
	ld xix, 0x3214
	ldb a, 0x98
	and a, 0xF
	or a, 0xC0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3219
	ldb a, 0x97
	and a, 0xF
	or a, 0xC0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x321E
	ldb a, 0x94
	and a, 0xF
	or a, 0xC0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3223
	ldb a, 0x95
	and a, 0xF
	or a, 0xC0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3228
	ldb a, 0x96
	and a, 0xF
	or a, 0xC0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ret

VoiceParams_LoadFiveSequential:
	ld_spib A, 0xF0
	call Rhythm_SendByte
	ld_spib A, 0xF0
	call Rhythm_SendByte
	ld_spib A, 0xF0
	call Rhythm_SendByte
	ld_spib A, 0xF0
	call Rhythm_SendByte
	ld_spib A, 0xF0
	call Rhythm_SendByte
	ret

AccVoice_BytecodeBlock3:
	.byte 0x1e, 0x0d, 0x00, 0x1e, 0x15, 0x00, 0x1e, 0x1d
	.byte 0x00, 0x1e, 0x25, 0x00, 0x1e, 0x2d, 0x00, 0x0e
	.byte 0xf1, 0x46, 0x32, 0x00, 0x06, 0xf1, 0x47, 0x32
	.byte 0x00, 0x00, 0x0e, 0xf1, 0x4d, 0x32, 0x00, 0x00
	.byte 0xf1, 0x4e, 0x32, 0x00, 0x00, 0x0e, 0xf1, 0x54
	.byte 0x32, 0x00, 0x00, 0xf1, 0x55, 0x32, 0x00, 0x00
	.byte 0x0e, 0xf1, 0x5b, 0x32, 0x00, 0x00, 0xf1, 0x5c
	.byte 0x32, 0x00, 0x00, 0x0e, 0xf1, 0x62, 0x32, 0x00
	.byte 0x00, 0xf1, 0x63, 0x32, 0x00, 0x00, 0x0e, 0xf1
	.byte 0xf5, 0x32, 0x00, 0x0f, 0xc1, 0xf7, 0x32, 0x3c
	.byte 0xf8, 0xc1, 0xf7, 0x32, 0x3e, 0x00, 0x0e, 0x0e
	.byte 0x1d, 0xe9, 0x5b, 0xf5, 0xf1, 0x2b, 0x33, 0x45
	.byte 0x0e, 0xc1, 0x5a, 0xfc, 0x21, 0xc1, 0x5b, 0xfc
	.byte 0x24, 0x1d, 0xb3, 0x5b, 0xf5, 0xf1, 0x2b, 0x33
	.byte 0x41, 0x0e

RhythmROM_CheckValid:
	ldb c, 0x0
	ld xwa, 0xFFFFFFFF
	cpda32 xwa, 12919
	jr z, RhythmROM_InvalidIncrement
	jr RhythmROM_CheckDone

RhythmROM_InvalidIncrement:
	ldb c, 0x1
	ldda16 xwa, 13396
	add wa, 0x1
	stda16 13396, xwa
	cps wa, 0
	jr nz, RhythmROM_CheckDone
	ldb a, 0xEE
	stda8 58332, a
	stdi8 58334, 64

RhythmROM_CheckDone:
	ret

RhythmROM_BytecodeBlock4:
	.byte 0x40, 0x00, 0x04, 0x00, 0x00, 0x38, 0x1d, 0x80
	.byte 0x0e, 0xff, 0xef, 0xc8, 0x04, 0x00, 0x00, 0x00
	.byte 0xf1
	.asciz "\\5c@"
	.byte 0x10, 0x00
	.byte 0x00, 0x38, 0x1d, 0x80, 0x0e, 0xff, 0xef, 0xc8
	.byte 0x04, 0x00, 0x00, 0x00, 0xeb, 0x88, 0xe8, 0x88
	.byte 0x38, 0x1d, 0xf2, 0x0a, 0xff, 0xef, 0xc8, 0x04
	.byte 0x00, 0x00, 0x00, 0xe1
	.ascii "\\5 8"
	.byte 0x1d, 0xf2, 0x0a, 0xff, 0xef, 0xc8, 0x04, 0x00
	.byte 0x00, 0x00, 0x0e

AccentData_ComparePart1:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix)
	ld xbc, (xiy)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, AccentData_Part1_Done
	cp l, h
	jr nz, AccentData_Part1_Done
	anddi8 13100, 252

AccentData_Part1_Done:
	ret

AccentData_ComparePart2:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 5)
	ld xbc, (xiy + 7)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, AccentData_Part2_Done
	cp l, h
	jr nz, AccentData_Part2_Done
	anddi8 13100, 251

AccentData_Part2_Done:
	ret

AccentData_ComparePart3:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 10)
	ld xbc, (xiy + 14)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, AccentData_Part3_Done
	cp l, h
	jr nz, AccentData_Part3_Done
	anddi8 13100, 247

AccentData_Part3_Done:
	ret

AccentData_ComparePart4:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 15)
	ld xbc, (xiy + 21)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, AccentData_Part4_Done
	cp l, h
	jr nz, AccentData_Part4_Done
	anddi8 13100, 239

AccentData_Part4_Done:
	ret

AccentData_ComparePart5:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 20)
	ld xbc, (xiy + 28)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, AccentData_Part5_Done
	cp l, h
	jr nz, AccentData_Part5_Done
	anddi8 13100, 223

AccentData_Part5_Done:
	ret

RhythmROM_ValidateHeader:
	xor xwa, xwa
	stda32 12919, xwa
	ld xix, 0x400000
	ld xwa, (xix)
	cp xwa, 0x5040100
	jr nz, AccChord_CheckFailed
	ld xwa, (xix + 4)
	cp xwa, 0x4010083
	jr nz, AccChord_CheckFailed
	ld xwa, (xix + 8)
	cp xwa, 0x1008305
	jr nz, AccChord_CheckFailed
	jr RhythmROM_HeaderValid

AccChord_CheckFailed:
	ld xwa, 0xFFFFFFFF
	stda32 12919, xwa

RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	xor xhl, xhl
	ld l, w
	and l, 0x7F
	srl l, 2
	cpdi8 13030, 0
	jrl nz, AccPatch_ChIdx1_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx0_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx0_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx0_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx0_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Entry:
	cpdi8 13030, 1
	jrl nz, AccPatch_ChIdx2_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx1_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx1_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Entry:
	cpdi8 13030, 2
	jrl nz, AccPatch_ChIdx3_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx2_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx2_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Entry:
	cpdi8 13030, 3
	jrl nz, AccPatch_ChIdx4_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx3_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx3_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Entry:
	cpdi8 13030, 4
	jrl nz, AccPatch_ChIdx5_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx4_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx4_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Entry:
	cpdi8 13030, 5
	jrl nz, AccPatch_ChIdx6_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx5_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx5_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Entry:
	cpdi8 13030, 6
	jrl nz, AccPatch_ChIdxDefault_Bank0
	cps l, 0
	jr nz, AccPatch_ChIdx6_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Bank1:
	cps l, 1
	jr nz, AccPatch_ChIdx6_Bank2
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Bank2:
	ldb a, 0x18
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x19
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x1A
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x1B
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x1C
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x1D
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jrl AccPatch_NullReturn

AccPatch_ChIdxDefault_Bank0:
	cps l, 0
	jr nz, AccPatch_ChIdxDefault_Bank1
	ldb a, 0xC
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0xD
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0xE
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0xF
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x10
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x11
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa
	jr AccPatch_NullReturn

AccPatch_ChIdxDefault_Bank1:
	ldb a, 0x12
	calr AccPatch_SetVoiceParam
	stda16 13156, xwa
	ldb a, 0x13
	calr AccPatch_SetVoiceParam
	stda16 13158, xwa
	ldb a, 0x14
	calr AccPatch_SetVoiceParam
	stda16 13160, xwa
	ldb a, 0x15
	calr AccPatch_SetVoiceParam
	stda16 13162, xwa
	ldb a, 0x16
	calr AccPatch_SetVoiceParam
	stda16 13164, xwa
	ldb a, 0x17
	calr AccPatch_SetVoiceParam
	stda16 13166, xwa

AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
