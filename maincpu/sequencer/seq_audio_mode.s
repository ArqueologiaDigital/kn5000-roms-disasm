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

LABEL_F5375E:
	bitda 3, 12932
	jr z, LABEL_F5377B
	ldda8 a, 12927
	cp a, 0x5D
	jr nc, LABEL_F53772
	cp a, 0x30
	jr ugt, LABEL_F5377B

LABEL_F53772:
	call AudioMode_SetStereoFlags
	anddi8 12932, 247

LABEL_F5377B:
	ret

LABEL_F5377C:
	ldda8 a, 13072
	and a, 0xF8
	ldda8 w, 13049
	and w, 0x7
	or a, w
	stda8 13072, a
	ret

LABEL_F53791:
	ldda8 a, 10418
	and a, 0x3
	stda8 13109, a
	ret

LABEL_F5379D:
	ldda8 a, 13553
	and a, 0x3D
	stda8 13154, a
	ret

LABEL_F537A9:
	.byte 0x28, 0x3d, 0xc1, 0x63, 0x33, 0x3c, 0xfe, 0x45
	.byte 0x00, 0x48, 0x09, 0x00, 0xed, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0x85, 0x21, 0xc9, 0x33, 0x00, 0x66
	.byte 0x05, 0xc1, 0x63, 0x33, 0x3e, 0x01, 0x5d, 0x48
	.byte 0x0e

LABEL_F537CA:
	pushw wa
	push xiy
	ordi8 13155, 1
	pop xiy
	popw wa
	ret

LABEL_F537D4:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00

AccPedal_ProcessAllChanges:
	xor wa, wa
	ld xhl, 0xE46BB0
	ldda8 a, 1075
	bit_dri 0, 0x07, 0xEC, 0xE0
	jrl z, LABEL_F53877
	xor a, a
	bitda 0, 13051
	jr z, LABEL_F5380E
	or a, 0x40

LABEL_F5380E:
	bitda 1, 13051
	jr z, LABEL_F53817
	or a, 0x80

LABEL_F53817:
	bitda 0, 13053
	jr z, LABEL_F53820
	or a, 0x10

LABEL_F53820:
	bitda 1, 13053
	jr z, LABEL_F53829
	or a, 0x20

LABEL_F53829:
	bitda 0, 13055
	jr z, LABEL_F53832
	or a, 0x4

LABEL_F53832:
	bitda 1, 13055
	jr z, LABEL_F5383B
	or a, 0x8

LABEL_F5383B:
	cps a, 0
	jr z, LABEL_F53853
	ld w, a
	xor w, 0xFF
	anddm8 64607, w
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

LABEL_F53853:
	bitda 2, 13055
	jr z, LABEL_F53869
	anddi8 64608, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

LABEL_F53869:
	xor a, a
	stda8 13051, a
	stda8 13053, a
	stda8 13055, a

LABEL_F53877:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	xor wa, wa
	ld xhl, 0xE46BB0
	ldda8 a, 1075
	ld_srib3 A, 0x07, 0xEC, 0xE0
	bitda 0, 12931
	jr nz, LABEL_F53893
	ldb a, 0x0

LABEL_F53893:
	stda8 12930, a
	ret

LABEL_F53898:
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, LABEL_F538D5
	ldda8 a, 13045
	cpda8 a, 13046
	jr nz, LABEL_F538C7
	ldda8 a, 13047
	and a, 0x7F
	and a, 0x7
	ldda8 w, 13048
	and w, 0x7F
	and w, 0x7
	cp a, w
	jr z, LABEL_F538D5

LABEL_F538C7:
	calr AccChannel_SetDirtyIfActive
	calr LABEL_F5393B
	calr LABEL_F53961
	ordi8 13068, 1

LABEL_F538D5:
	ldda8 a, 13045
	stda8 13031, a
	ldda8 a, 13047
	and a, 0x7F
	and w, 0x7
	stda8 13032, a
	ret

LABEL_F538EC:
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
	jr z, LABEL_F5393A
	ordi8 13094, 63

LABEL_F5393A:
	ret

LABEL_F5393B:
	ldda8 a, 13074
	orda8 a, 13075
	orda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	and a, 0x3F
	jr z, LABEL_F53960
	cpdi8 13045, 128
	jr c, LABEL_F53960
	ordi8 13094, 63

LABEL_F53960:
	ret

LABEL_F53961:
	ldda8 a, 1075
	cps a, 1
	jr nz, LABEL_F5396E
	ordi8 13094, 63

LABEL_F5396E:
	ret

LABEL_F5396F:
	bitda 0, 13055
	jr z, LABEL_F539A5
	bitda 0, 13056
	jr nz, LABEL_F539A5
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 243
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, LABEL_F5399A
	anddi8 13094, 192

LABEL_F5399A:
	ordi8 13066, 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

LABEL_F539A5:
	bitda 1, 13055
	jr z, LABEL_F539DB
	bitda 1, 13056
	jr nz, LABEL_F539DB
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 246
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, LABEL_F539D0
	anddi8 13094, 192

LABEL_F539D0:
	ordi8 13066, 4
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

LABEL_F539DB:
	bitda 2, 13055
	jr z, LABEL_F53A11
	bitda 2, 13056
	jr nz, LABEL_F53A11
	xor a, a
	stda8 13065, a
	stda8 13067, a
	anddi8 13066, 250
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, LABEL_F53A06
	anddi8 13094, 192

LABEL_F53A06:
	ordi8 13066, 8
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

LABEL_F53A11:
	ret

LABEL_F53A12:
	bitda 0, 13051
	jr z, LABEL_F53A48
	bitda 0, 13052
	jr nz, LABEL_F53A48
	xor a, a
	stda8 13066, a
	stda8 13067, a
	anddi8 13065, 253
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, LABEL_F53A3D
	anddi8 13094, 192

LABEL_F53A3D:
	ordi8 13065, 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

LABEL_F53A48:
	bitda 1, 13051
	jr z, LABEL_F53A7E
	bitda 1, 13052
	jr nz, LABEL_F53A7E
	xor a, a
	stda8 13066, a
	stda8 13067, a
	anddi8 13065, 254
	anddi8 13095, 192
	bitda 0, 13068
	jr nz, LABEL_F53A73
	anddi8 13094, 192

LABEL_F53A73:
	ordi8 13065, 2
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

LABEL_F53A7E:
	ret

AccVoice_CheckChannelSetActive:
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr z, LABEL_F53A91
	ordi8 13071, 1

LABEL_F53A91:
	ret

AccVoice_CheckBitsAndSetFlags:
	ldda16 xde, 13027
	and d, 0x7
	inc 1, d
	cpda8 d, 1075
	jr nz, LABEL_F53AA6
	ordi8 13095, 63

LABEL_F53AA6:
	ret

LABEL_F53AA7:
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

LABEL_F53AE2:
	bitda 0, 13053
	jr z, LABEL_F53B0F
	bitda 0, 13054
	jr nz, LABEL_F53B0F
	xor a, a
	stda8 13066, a
	stda8 13065, a
	anddi8 13095, 192
	anddi8 13067, 253
	anddi8 13094, 192
	ordi8 13067, 1
	calr AccChannel_SetDirtyIfActive

LABEL_F53B0F:
	bitda 1, 13053
	jr z, LABEL_F53B3C
	bitda 1, 13054
	jr nz, LABEL_F53B3C
	xor a, a
	stda8 13066, a
	stda8 13065, a
	anddi8 13095, 192
	anddi8 13067, 254
	anddi8 13094, 192
	ordi8 13067, 2
	calr AccChannel_SetDirtyIfActive

LABEL_F53B3C:
	ret

LABEL_F53B3D:
	ldda8 a, 13029
	ldda8 w, 13095
	and w, 0x3F
	jr z, LABEL_F53B4E
	ldda8 a, 13031

LABEL_F53B4E:
	cp a, 0x80
	jrl c, AccChord_NullRet
	cp a, 0xF0
	jr c, LABEL_F53B5F
	ldda8 a, 13297
	jr LABEL_F53B62

LABEL_F53B5F:
	and a, 0x7F

LABEL_F53B62:
	calr AccPatch_SetVoiceParam
	ld c, a
	xor a, a
	bitda 0, 13066
	jr z, LABEL_F53B87
	cpda8 c, 13156
	jr z, LABEL_F53B87
	anddi8 13066, 254
	anddi8 13095, 192
	anddi8 13055, 254
	or a, 0x4

LABEL_F53B87:
	bitda 2, 13066
	jr z, LABEL_F53BAB
	ld xhl, 0xE46BB0
	bit_dri 0, 0x03, 0xEC, 0xE4
	jr z, LABEL_F53BAB
	anddi8 13066, 251
	anddi8 13095, 192
	anddi8 13055, 253
	or a, 0x8

LABEL_F53BAB:
	bitda 0, 13065
	jr z, LABEL_F53BC9
	cpda8 c, 13160
	jr z, LABEL_F53BC9
	anddi8 13065, 254
	anddi8 13095, 192
	anddi8 13051, 254
	or a, 0x40

LABEL_F53BC9:
	bitda 1, 13065
	jr z, LABEL_F53BE7
	cpda8 c, 13162
	jr z, LABEL_F53BE7
	anddi8 13065, 253
	anddi8 13095, 192
	anddi8 13051, 253
	or a, 0x80

LABEL_F53BE7:
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
	jr z, LABEL_F53C45
	ldb w, 0x0
	xor a, 0xFF
	anddm8 64607, a
	ldb a, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

LABEL_F53C45:
	bitda 3, 13066
	jr z, LABEL_F53C70
	cpda8 c, 13158
	jr z, LABEL_F53C70
	anddi8 13066, 247
	anddi8 13095, 192
	anddi8 13055, 251
	anddi8 64607, 251
	ldb a, 0x0
	ldb w, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

LABEL_F53C70:
	ldda8 a, 13097
	and a, 0x3F
	jr z, AccChord_NullRet
	bitda 0, 13051
	jr z, LABEL_F53C8C
	cpda8 c, 13160
	jr z, AccChord_NullRet
	anddi8 13097, 192
	jr AccChord_NullRet

LABEL_F53C8C:
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
	jr nz, LABEL_F53CB8
	ldda8 a, 13018
	cpda8 a, 13022
	jr z, LABEL_F53CBD

LABEL_F53CB8:
	ordi8 13043, 32

LABEL_F53CBD:
	cpdi8 13020, 0
	jr nz, LABEL_F53CC9
	anddi8 13043, 223

LABEL_F53CC9:
	ret

LABEL_F53CCA:
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
	jr z, LABEL_F53D02
	ldda8 a, 13074
	orda8 a, 13075
	and a, 0x3F
	jr nz, AccentVoice_UpdateParamIndex

LABEL_F53D02:
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
	jr ule, LABEL_F53D2E
	xor a, a

LABEL_F53D2E:
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

LABEL_F53D57:
	.byte 0x00, 0x48, 0x09, 0x00, 0x00, 0x00, 0x30, 0x00
	.byte 0x00, 0x98, 0x31, 0x00, 0x00, 0x00, 0x33, 0x00
	.byte 0x00, 0x98, 0x34, 0x00, 0x00, 0x00, 0x36, 0x00
	.byte 0x00, 0x98, 0x37, 0x00, 0x00, 0x00, 0x39, 0x00

LABEL_F53D77:
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
	calr LABEL_F53D77
	call AccVoice_TableLookup_Inner
	extz xiy
	add xhl, xiy
	ld xiy, xhl
	ret

AccVoice_SelectAndApplyPatch:
	cpdi8 13029, 128
	jr nc, LABEL_F53DBC
	ldda32 xiy, 13006
	calr AccStyle_ReadVoiceParam
	stda8 13039, w
	jr LABEL_F53DC6

LABEL_F53DBC:
	ldda8 a, 13029
	and a, 0x7F
	calr AccPatch_SetVoiceParam

LABEL_F53DC6:
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
	jr ule, LABEL_F53DF8
	xor a, a

LABEL_F53DF8:
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

LABEL_F53EC9:
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

LABEL_F53EED:
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

LABEL_F53F11:
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

LABEL_F53F35:
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
	jr nz, LABEL_F53F75
	call AccVoice_LoadAllChannelParams

LABEL_F53F75:
	ret

RhythmPart_CopyData:
	ldw bc, 0x19
	ld xiy, 0x3214
	ld xix, 0x322D
	ldir85
	ret

RhythmPart1_ProcessAccentData:
	bitda 0, 12931
	jr z, LABEL_F53F90
	call LABEL_F5459F

LABEL_F53F90:
	ldda8 a, 13100
	and a, 0x3
	jr z, LABEL_F54001
	ldda8 e, 12870
	ldda8 d, 12871
	bitda 0, 12931
	jr nz, LABEL_F53FB3
	ld xhl, 0x3214
	ld (xhl), e
	ld (xhl + 1), d
	jr LABEL_F54001

LABEL_F53FB3:
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

LABEL_F54001:
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
	jr ugt, LABEL_F54038
	ldb a, 0x1
	stda8 13358, a
	cpdi8 1122, 0
	jr z, LABEL_F5403C
	xor a, a
	jr LABEL_F5403C

LABEL_F54038:
	stda8 13358, a

LABEL_F5403C:
	ldda8 w, 1122
	add a, w
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr RingBuf_AdvanceIndex
	ldda8 w, 13174
	cp a, w
	jr nc, LABEL_F54056
	stda8 13174, a

LABEL_F54056:
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
	jr ule, LABEL_F54064
	ld iy, (xhl + 256)

LABEL_F54064:
	ret

RhythmPart2_ProcessAccentData:
	bitda 0, 12931
	jr z, LABEL_F5406F
	call LABEL_F545C1

LABEL_F5406F:
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
	jr nz, LABEL_F540B6
	ld xhl, 0x3219
	calr AccVoiceReg_StoreParamRecord
	jr LABEL_F5410C

LABEL_F540B6:
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

LABEL_F5410C:
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
	jr z, LABEL_F5413C
	or d, 0x10
	and e, 0x7F

LABEL_F5413C:
	ret

AccVoice_LoadRhythmParams_Part3:
	bitda 0, 12931
	jr z, LABEL_F54147
	call LABEL_F545E5

LABEL_F54147:
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
	jr nz, LABEL_F5418E
	ld xhl, 0x321E
	calr AccVoiceReg_StoreParamRecord
	jr LABEL_F541E4

LABEL_F5418E:
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

LABEL_F541E4:
	anddi8 13100, 247
	call AccVoiceReg_WritePart3
	ret

AccVoice_LoadRhythmParams_Part4:
	bitda 0, 12931
	jr z, LABEL_F541F8
	call LABEL_F54609

LABEL_F541F8:
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
	jr nz, LABEL_F5423F
	ld xhl, 0x3223
	calr AccVoiceReg_StoreParamRecord
	jr LABEL_F54295

LABEL_F5423F:
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

LABEL_F54295:
	anddi8 13100, 239
	call AccVoiceReg_WritePart4
	ret

AccVoice_LoadRhythmParams_Part5:
	bitda 0, 12931
	jr z, LABEL_F542A9
	call LABEL_F5462D

LABEL_F542A9:
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
	jr nz, LABEL_F542F0
	ld xhl, 0x3228
	calr AccVoiceReg_StoreParamRecord
	jr LABEL_F54346

LABEL_F542F0:
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

LABEL_F54346:
	anddi8 13100, 223
	call AccVoiceReg_WritePart5
	ret

AccompVoice_BulkReadRegisters:
	ldb a, 0x0
	ld xhl, 0x3094
	xor iy, iy

LABEL_F54359:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, LABEL_F54359
	ld xhl, 0x30C4
	xor iy, iy

LABEL_F5436F:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x6
	cp iy, 0x30
	jr c, LABEL_F5436F
	ld xhl, 0x30F4
	xor iy, iy

LABEL_F54385:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, LABEL_F54385
	ld xhl, 0x313C
	xor iy, iy

LABEL_F5439B:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, LABEL_F5439B
	ld xhl, 0x3184
	xor iy, iy

LABEL_F543B1:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, LABEL_F543B1
	ld xhl, 0x31CC
	xor iy, iy

LABEL_F543C7:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x9
	cp iy, 0x48
	jr c, LABEL_F543C7
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

LABEL_F54422:
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

LABEL_F544BD:
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
	jr z, LABEL_F5453E
	jr LABEL_F5455B

LABEL_F5453E:
	ldb c, 0x1
	ldda16 xwa, 13396
	add wa, 0x1
	stda16 13396, xwa
	cps wa, 0
	jr nz, LABEL_F5455B
	ldb a, 0xEE
	stda8 58332, a
	stdi8 58334, 64

LABEL_F5455B:
	ret

LABEL_F5455C:
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

LABEL_F5459F:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix)
	ld xbc, (xiy)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, LABEL_F545C0
	cp l, h
	jr nz, LABEL_F545C0
	anddi8 13100, 252

LABEL_F545C0:
	ret

LABEL_F545C1:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 5)
	ld xbc, (xiy + 7)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, LABEL_F545E4
	cp l, h
	jr nz, LABEL_F545E4
	anddi8 13100, 251

LABEL_F545E4:
	ret

LABEL_F545E5:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 10)
	ld xbc, (xiy + 14)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, LABEL_F54608
	cp l, h
	jr nz, LABEL_F54608
	anddi8 13100, 247

LABEL_F54608:
	ret

LABEL_F54609:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 15)
	ld xbc, (xiy + 21)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, LABEL_F5462C
	cp l, h
	jr nz, LABEL_F5462C
	anddi8 13100, 239

LABEL_F5462C:
	ret

LABEL_F5462D:
	ld xix, 0x3214
	ld xiy, 0x3246
	ld xwa, (xix + 20)
	ld xbc, (xiy + 28)
	ld l, (xix + 1)
	ld h, (xiy + 1)
	cp xwa, xbc
	jr nz, LABEL_F54650
	cp l, h
	jr nz, LABEL_F54650
	anddi8 13100, 223

LABEL_F54650:
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
	jr LABEL_F54687

AccChord_CheckFailed:
	ld xwa, 0xFFFFFFFF
	stda32 12919, xwa

LABEL_F54687:
	ret

AccPatch_SetByChordIndex:
	xor xhl, xhl
	ld l, w
	and l, 0x7F
	srl l, 2
	cpdi8 13030, 0
	jrl nz, LABEL_F5474D
	cps l, 0
	jr nz, LABEL_F546D7
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

LABEL_F546D7:
	cps l, 1
	jr nz, LABEL_F54714
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

LABEL_F54714:
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

LABEL_F5474D:
	cpdi8 13030, 1
	jrl nz, LABEL_F54808
	cps l, 0
	jr nz, LABEL_F54792
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

LABEL_F54792:
	cps l, 1
	jr nz, LABEL_F547CF
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

LABEL_F547CF:
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

LABEL_F54808:
	cpdi8 13030, 2
	jrl nz, LABEL_F548C3
	cps l, 0
	jr nz, LABEL_F5484D
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

LABEL_F5484D:
	cps l, 1
	jr nz, LABEL_F5488A
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

LABEL_F5488A:
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

LABEL_F548C3:
	cpdi8 13030, 3
	jrl nz, LABEL_F5497E
	cps l, 0
	jr nz, LABEL_F54908
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

LABEL_F54908:
	cps l, 1
	jr nz, LABEL_F54945
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

LABEL_F54945:
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

LABEL_F5497E:
	cpdi8 13030, 4
	jrl nz, LABEL_F54A39
	cps l, 0
	jr nz, LABEL_F549C3
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

LABEL_F549C3:
	cps l, 1
	jr nz, LABEL_F54A00
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

LABEL_F54A00:
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

LABEL_F54A39:
	cpdi8 13030, 5
	jrl nz, LABEL_F54AF4
	cps l, 0
	jr nz, LABEL_F54A7E
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

LABEL_F54A7E:
	cps l, 1
	jr nz, LABEL_F54ABB
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

LABEL_F54ABB:
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

LABEL_F54AF4:
	cpdi8 13030, 6
	jrl nz, LABEL_F54BAF
	cps l, 0
	jr nz, LABEL_F54B39
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

LABEL_F54B39:
	cps l, 1
	jr nz, LABEL_F54B76
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

LABEL_F54B76:
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

LABEL_F54BAF:
	cps l, 0
	jr nz, LABEL_F54BEB
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

LABEL_F54BEB:
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
