; =============================================================================
; Sequencer Audio Mode & Accompaniment Processing (2K lines)
; =============================================================================
;
; Audio mode stereo flags, accompaniment pedal processing,
; sequencer timing setup, part activation, and audio flag
; dispatch between SMF event processing and rhythm routines.
; =============================================================================

	ei 0
	stb_d8 (0x31e3), a
	ret

AudioMode_CheckAndUpdateStereo:
	bitda 3, (0x31e8)
	jr z, AudioMode_CheckDone
	ldb_d8 a, (0x31e3)
	cp A,0x5d
	jr nc, .Lc_f5336e
	cp A,0x30
	jr ugt, AudioMode_CheckDone
AudioMode_ApplyStereoUpdate:
.Lc_f5336e:
	call 0xfdd7c0
	anddi8 (0x31e8), 0xf7



AudioMode_CheckDone:
	ret

AudioMode_MergeOutputBits:
	ldb_d8	a, (12916)
	and	a, 248
	ldb_d8	w, (12893)
	and	w, 7
	or	a, w
	stb_d8	(12916), a
	ret
AudioMode_CopyChannelMode:
	ldb_d8	a, (10418)
	and	a, 3
	stb_d8	(12953), a
	ret
AudioMode_CopyAccentFlags:
	ldb_d8	a, (13397)
	and	a, 61
	stb_d8	(12998), a
	ret
AccPedal_BytecodeBlock1:
	.incbin "includes/romslices/v7_transplant_AccPedal_BytecodeBlock1.bin"
AccPedal_SetFlag13155:
	pushw wa

	push xiy

	.byte 0xc1, 0xc7, 0x32, 0x3e, 0x01	; ordi8 0x3363, 1 (v7 patched)

	pop xiy

	popw wa

	ret



AccPedal_PartOffsetTable:
	.byte 0x00, 0x00, 0x30, 0x00, 0x00, 0x98, 0x31, 0x00
	.byte 0x00, 0x00, 0x33, 0x00, 0x00, 0x98, 0x34, 0x00
	.byte 0x00, 0x00, 0x36, 0x00, 0x00, 0x98, 0x37, 0x00
	.byte 0x00, 0x00, 0x39, 0x00

AccPedal_ProcessAllChanges:
	xor WA,WA
	ld XHL,Display_FontPalette_Table_0x1D58
	ldb_d8 a, (0x0433)
	.byte 0xf3, 0x07, 0xec, 0xe0, 0xc8, 0x76, 0x74, 0x00
	.byte 0xc9, 0xd1, 0xf1, 0x5f, 0x32, 0xc8, 0x66, 0x03
	.byte 0xc9, 0xce, 0x40
AccPedal_CheckBit1Left:
	.byte 0xf1, 0x5f, 0x32, 0xc9, 0x66, 0x03, 0xc9, 0xce
	.byte 0x80
AccPedal_CheckBit0Right:
	.byte 0xf1, 0x61, 0x32, 0xc8, 0x66, 0x03, 0xc9, 0xce
	.byte 0x10
AccPedal_CheckBit1Right:
	.byte 0xf1, 0x61, 0x32, 0xc9, 0x66, 0x03, 0xc9, 0xce
	.byte 0x20
AccPedal_CheckBit0Aux:
	.byte 0xf1, 0x63, 0x32, 0xc8, 0x66, 0x03, 0xc9, 0xce
	.byte 0x04
AccPedal_CheckBit1Aux:
	.byte 0xf1, 0x63, 0x32, 0xc9, 0x66, 0x03, 0xc9, 0xce
	.byte 0x08
AccPedal_ApplyChangeMask:
	cps a, 0
	jr z, AccPedal_CheckAuxBit2
	ld w, a
	xor w, 0xff
	anddm8 0xfc5f, w
	ldb e, 0x48
	ldb d, 0x5
	ldb w, 0x0
	ldb a, 0x0
	calr Rhythm_QueuePartChangeEvent

AccPedal_CheckAuxBit2:
	.byte 0xf1, 0x63, 0x32, 0xca, 0x66, 0x10, 0xc1, 0x60
	.byte 0xfc, 0x3c, 0xfb, 0x25, 0x48, 0x24, 0x05, 0x20
	.byte 0x00, 0x21, 0x00, 0x1e, 0x86, 0xfc
AccPedal_ClearAllPedalFlags:
	xor	a, a
	stb_d8	(12895), a
	stb_d8	(12897), a
	stb_d8	(12899), a
AccPedal_ReadBankAndReturn:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	xor WA,WA
	ld XHL,Display_FontPalette_Table_0x1D58
	ldb_d8 a, (0x0433)
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xf1, 0xe7, 0x31
	.byte 0xc8, 0x6e, 0x02, 0x21, 0x00
AccVoice_StoreBankAssign:
	stb_d8	(12774), a
	ret
AccChannel_CompareAndMarkDirty:
	ldb_d8 a, (0x3278)
	orda8 a, (0x3279)
	and A,0x3f
	jr nz, AccChannel_StoreCurrentState
	ldb_d8 a, (0x3259)
	cpda8 a, (0x325a)
	jr nz, .Lc_f534c3
	ldb_d8 a, (0x325b)
	and A,0x7f
	and A,0x07
	ldb_d8 w, (0x325c)
	and W,0x7f
	and W,0x07
	cp A,W
	jr z, AccChannel_StoreCurrentState
AccChannel_MarkDirtyAndSync:
.Lc_f534c3:
	calr AccChannel_SetDirtyIfActive
	calr AccChannel_CheckActivitySetDirty
	calr AccChannel_CheckPartIndexDirty
	ordi8 (0x3270), 0x01



AccChannel_StoreCurrentState:
	ldb_d8	a, (12889)
	stb_d8	(12875), a
	ldb_d8	a, (12891)
	and	a, 127
	and	w, 7
	stb_d8	(12876), a
	ret
AccChannel_BytecodeBlock2:
	.byte 0xc1, 0x59, 0x32, 0x21, 0xc1, 0x5a, 0x32, 0xf1
	.byte 0x6e, 0x1d, 0xc9, 0xcf, 0x80, 0x6f, 0x2e, 0xc1
	.byte 0x5b, 0x32, 0x21, 0xc9, 0xcc, 0x7f, 0xc9, 0xcc
	.byte 0x07, 0xc1, 0x5c, 0x32, 0x20, 0xc8, 0xcc, 0x7f
	.byte 0xc8, 0xcc, 0x07, 0xc8, 0xf1, 0x66, 0x16, 0xc1
	.byte 0x59, 0x32, 0x21, 0xf1, 0x4b, 0x32, 0x41, 0xc1
	.byte 0x5b, 0x32, 0x21, 0xc8, 0xcc, 0x7f, 0xc8, 0xcc
	.byte 0x07, 0xf1, 0x4c, 0x32, 0x41, 0x0e
AccChannel_SetDirtyIfActive:
	ldw_d16 wa, (0x3247)
	and W,0x07
	cps w, 0
	jr z, AccChannel_SetDirtyDone
	ordi8 (0x328a), 0x3f
AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	ldb_d8 a, (0x3276)
	orda8 a, (0x3277)
	orda8 a, (0x327a)
	orda8 a, (0x327b)
	orda8 a, (0x327c)
	and A,0x3f
	jr z, AccChannel_ActivityCheckDone
	cpdi8 (0x3259), 0x80
	jr c, AccChannel_ActivityCheckDone
	ordi8 (0x328a), 0x3f
AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	ldb_d8 a, (0x0433)
	cps a, 1
	jr nz, AccChannel_PartIndexDone
	ordi8 (0x328a), 0x3f
AccChannel_PartIndexDone:
	ret

AccVoice_ProcessPedalChanges:
	bitda 0, (0x3263)
	jr z, .Lc_f535a1
	bitda 0, (0x3264)
	jr nz, .Lc_f535a1
	xor A,A
	stb_d8 (0x326d), a
	stb_d8 (0x326f), a
	anddi8 (0x326e), 0xf3
	anddi8 (0x328b), 0xc0
	bitda 0, (0x3270)
	jr nz, .Lc_f53596
	anddi8 (0x328a), 0xc0
AccVoice_Pedal0_SetAndCheck:
.Lc_f53596:
	ordi8 (0x326e), 0x01
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_Pedal0_Done:
.Lc_f535a1:
	bitda 1, (0x3263)
	jr z, .Lc_f535d7
	bitda 1, (0x3264)
	jr nz, .Lc_f535d7
	xor A,A
	stb_d8 (0x326d), a
	stb_d8 (0x326f), a
	anddi8 (0x326e), 0xf6
	anddi8 (0x328b), 0xc0
	bitda 0, (0x3270)
	jr nz, .Lc_f535cc
	anddi8 (0x328a), 0xc0
AccVoice_Pedal1_SetAndCheck:
.Lc_f535cc:
	ordi8 (0x326e), 0x04
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_Pedal1_Done:
.Lc_f535d7:
	bitda 2, (0x3263)
	jr z, AccVoice_Pedal2_Done
	bitda 2, (0x3264)
	jr nz, AccVoice_Pedal2_Done
	xor A,A
	stb_d8 (0x326d), a
	stb_d8 (0x326f), a
	anddi8 (0x326e), 0xfa
	anddi8 (0x328b), 0xc0
	bitda 0, (0x3270)
	jr nz, .Lc_f53602
	anddi8 (0x328a), 0xc0
AccVoice_Pedal2_SetAndCheck:
.Lc_f53602:
	ordi8 (0x326e), 0x08
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive



AccVoice_Pedal2_Done:
	ret

AccVoice_ProcessLeftPedalChanges:
	bitda 0, (0x325f)
	jr z, .Lc_f53644
	bitda 0, (0x3260)
	jr nz, .Lc_f53644
	xor A,A
	stb_d8 (0x326e), a
	stb_d8 (0x326f), a
	anddi8 (0x326d), 0xfd
	anddi8 (0x328b), 0xc0
	bitda 0, (0x3270)
	jr nz, .Lc_f53639
	anddi8 (0x328a), 0xc0
AccVoice_LeftPedal0_SetAndCheck:
.Lc_f53639:
	ordi8 (0x326d), 0x01
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_LeftPedal0_Done:
.Lc_f53644:
	bitda 1, (0x325f)
	jr z, AccVoice_LeftPedal1_Done
	bitda 1, (0x3260)
	jr nz, AccVoice_LeftPedal1_Done
	xor A,A
	stb_d8 (0x326e), a
	stb_d8 (0x326f), a
	anddi8 (0x326d), 0xfe
	anddi8 (0x328b), 0xc0
	bitda 0, (0x3270)
	jr nz, .Lc_f5366f
	anddi8 (0x328a), 0xc0
AccVoice_LeftPedal1_SetAndCheck:
.Lc_f5366f:
	ordi8 (0x326d), 0x02
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive



AccVoice_LeftPedal1_Done:
	ret

AccVoice_CheckChannelSetActive:
	ldb_d8 a, (0x3278)
	orda8 a, (0x3279)
	and A,0x3f
	jr z, AccVoice_ChannelActiveDone
	ordi8 (0x3273), 0x01
AccVoice_ChannelActiveDone:
	ret

AccVoice_CheckBitsAndSetFlags:
	ldw_d16 de, (0x3247)
	and D,0x07
	inc 1,D
	cpda8 d, (0x0433)
	jr nz, AccVoice_BitsCheckDone
	ordi8 (0x328b), 0x3f
AccVoice_BitsCheckDone:
	ret

AccPitch_CheckTransposeFlags:
	bitda 6, (0x33d4)
	jr nz, .Lc_f536c0
	bitda 6, (0x31e5)
	jr z, .Lc_f536c0
	ldb_d8 a, (0x31e4)
	inc 1,A
	cpda8 a, (0x0433)
	jr nz, .Lc_f536c0
	ordi8 (0x328d), 0x3f
AccPitch_UpdateCheck:
.Lc_f536c0:
	bitda 7, (0x33d4)
	jr nz, AccPitch_FinalReturn
	bitda 7, (0x31e5)
	jr z, AccPitch_FinalReturn
	ldb_d8 a, (0x31e4)
	inc 1,A
	cpda8 a, (0x0433)
	jr nz, AccPitch_FinalReturn
	ordi8 (0x328d), 0x3f
AccPitch_FinalReturn:
	ret

AccChord_ProcessKeyChanges:
	bitda 0, (0x3261)
	jr z, .Lc_f5370b
	bitda 0, (0x3262)
	jr nz, .Lc_f5370b
	xor A,A
	stb_d8 (0x326e), a
	stb_d8 (0x326d), a
	anddi8 (0x328b), 0xc0
	anddi8 (0x326f), 0xfd
	anddi8 (0x328a), 0xc0
	ordi8 (0x326f), 0x01
	calr AccChannel_SetDirtyIfActive
AccChord_KeyChange0_Done:
.Lc_f5370b:
	bitda 1, (0x3261)
	jr z, AccChord_KeyChange1_Done
	bitda 1, (0x3262)
	jr nz, AccChord_KeyChange1_Done
	xor A,A
	stb_d8 (0x326e), a
	stb_d8 (0x326d), a
	anddi8 (0x328b), 0xc0
	anddi8 (0x326f), 0xfe
	anddi8 (0x328a), 0xc0
	ordi8 (0x326f), 0x02
	calr AccChannel_SetDirtyIfActive
AccChord_KeyChange1_Done:
	ret

AccChord_ResolveVoiceAndDispatch:
	ldb_d8	a, (12873)
	ldb_d8	w, (12939)
	and	w, 63
	jr	z, 4
	ldb_d8	a, (12875)
AccChord_CheckRange:
	cp	a, 128
	jrl	c, 335
	cp	a, 240
	jr	c, 6
	ldb_d8	a, (13141)
	jr	3
AccChord_MaskAndContinue:
	and a, 0x7f

AccChord_DispatchVoiceChange:
	.byte 0x1e, 0x8c, 0x02, 0xc9, 0x8b, 0xc9, 0xd1, 0xf1
	.byte 0x6e, 0x32, 0xc8, 0x66, 0x18, 0xc1, 0xc8, 0x32
	.byte 0xf3, 0x66, 0x12, 0xc1, 0x6e, 0x32, 0x3c, 0xfe
	.byte 0xc1, 0x8b, 0x32, 0x3c, 0xc0, 0xc1, 0x63, 0x32
	.byte 0x3c, 0xfe, 0xc9, 0xce, 0x04
AccChord_CheckVoiceBit2:
	.byte 0xf1, 0x6e, 0x32, 0xca, 0x66, 0x1e, 0x43, 0xb0
	.byte 0x6b, 0xe4, 0x00, 0xf3, 0x03, 0xec, 0xe4, 0xc8
	.byte 0x66, 0x12, 0xc1, 0x6e, 0x32, 0x3c, 0xfb, 0xc1
	.byte 0x8b, 0x32, 0x3c, 0xc0, 0xc1, 0x63, 0x32, 0x3c
	.byte 0xfd, 0xc9, 0xce, 0x08
AccChord_CheckLeftPedal0:
	.byte 0xf1, 0x6d, 0x32, 0xc8, 0x66, 0x18, 0xc1, 0xcc
	.byte 0x32, 0xf3, 0x66, 0x12, 0xc1, 0x6d, 0x32, 0x3c
	.byte 0xfe, 0xc1, 0x8b, 0x32, 0x3c, 0xc0, 0xc1, 0x5f
	.byte 0x32, 0x3c, 0xfe, 0xc9, 0xce, 0x40
AccChord_CheckLeftPedal1:
	.byte 0xf1, 0x6d, 0x32, 0xc9, 0x66, 0x18, 0xc1, 0xce
	.byte 0x32, 0xf3, 0x66, 0x12, 0xc1, 0x6d, 0x32, 0x3c
	.byte 0xfd, 0xc1, 0x8b, 0x32, 0x3c, 0xc0, 0xc1, 0x5f
	.byte 0x32, 0x3c, 0xfd, 0xc9, 0xce, 0x80
AccChord_CheckKeyChange0:
	.byte 0xf1, 0x6f, 0x32, 0xc8, 0x66, 0x1e, 0xc1, 0xd0
	.byte 0x32, 0xf3, 0x66, 0x18, 0xc1, 0x6f, 0x32, 0x3c
	.byte 0xfe, 0xc1, 0x61, 0x32, 0x3c, 0xfe, 0xc9, 0xce
	.byte 0x10, 0xf1, 0x70, 0x32, 0xc8, 0x6e, 0x05, 0xc1
	.byte 0x8b, 0x32, 0x3c, 0xc0
RhythmPart_ProcessBit0:
	.byte 0xf1, 0x6f, 0x32, 0xc9, 0x66, 0x1e, 0xc1, 0xd2
	.byte 0x32, 0xf3, 0x66, 0x18, 0xc1, 0x6f, 0x32, 0x3c
	.byte 0xfd, 0xc1, 0x61, 0x32, 0x3c, 0xfd, 0xc9, 0xce
	.byte 0x20, 0xf1, 0x70, 0x32, 0xc8, 0x6e, 0x05, 0xc1
	.byte 0x8b, 0x32, 0x3c, 0xc0
RhythmPart_ProcessBit1:
	cps a, 0
	jr z, AccChord_CheckExtraDirtyBit3
	ldb w, 0x0
	xor a, 0xff
	anddm8 0xfc5f, a
	ldb a, 0x0
	ldb e, 0x48
	ldb d, 0x5
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckExtraDirtyBit3:
	.byte 0xf1, 0x6e, 0x32, 0xcb, 0x66, 0x25, 0xc1, 0xca
	.byte 0x32, 0xf3, 0x66, 0x1f, 0xc1, 0x6e, 0x32, 0x3c
	.byte 0xf7, 0xc1, 0x8b, 0x32, 0x3c, 0xc0, 0xc1, 0x63
	.byte 0x32, 0x3c, 0xfb, 0xc1, 0x5f, 0xfc, 0x3c, 0xfb
	.byte 0x21, 0x00, 0x20, 0x00, 0x25, 0x48, 0x24, 0x05
	.byte 0x1e, 0x7f, 0xf8
AccChord_CheckPitchDirty:
	.byte 0xc1, 0x8d, 0x32, 0x21, 0xc9, 0xcc, 0x3f, 0x66
	.byte 0x2a, 0xf1, 0x5f, 0x32, 0xc8, 0x66, 0x0d, 0xc1
	.byte 0xcc, 0x32, 0xf3, 0x66, 0x1e, 0xc1, 0x8d, 0x32
	.byte 0x3c, 0xc0, 0x68, 0x17
AccChord_CheckPitchLeftPedal1:
	.byte 0xf1, 0x5f, 0x32, 0xc9, 0x66, 0x11, 0x43, 0xb0
	.byte 0x6b, 0xe4, 0x00, 0xf3, 0x03, 0xec, 0xe4, 0xc8
	.byte 0x66, 0x05, 0xc1, 0x8d, 0x32, 0x3c, 0xc0
AccChord_NullRet:
	ret

AccChord_CompareAndSetDirty:
	ldb_d8 a, (0x323c)
	cpda8 a, (0x3240)
	jr nz, .Lc_f538b4
	ldb_d8 a, (0x323e)
	cpda8 a, (0x3242)
	jr z, .Lc_f538b9
AccChord_SetDirtyBit5:
.Lc_f538b4:
	ordi8 (0x3257), 0x20
AccChord_CheckZeroChord:
.Lc_f538b9:
	cpdi8 (0x3240), 0x00
	jr nz, AccChord_CompareDone
	anddi8 (0x3257), 0xdf
AccChord_CompareDone:
	ret

AccentVoice_DetectAndMarkChange:
	ldb_d8 a, (0x3269)
	cpda8 a, (0x326a)
	jr z, AccentVoice_UpdateParamIndex
	ldb_d8 a, (0x3278)
	orda8 a, (0x3279)
	and A,0x3f
	jr nz, AccentVoice_UpdateParamIndex
	cpdi8 (0x3249), 0xf0
	jr nc, AccentVoice_UpdateParamIndex
	cpdi8 (0x3249), 0x80
	jr nc, AccentVoice_UpdateParamIndex
	bitda 0, (0x3265)
	jr z, .Lc_f538fe
	ldb_d8 a, (0x3276)
	orda8 a, (0x3277)
	and A,0x3f
	jr nz, AccentVoice_UpdateParamIndex
AccentVoice_CheckModeChange:
.Lc_f538fe:
	ldb_d8 a, (0x3269)
	and A,0x03
	cpda8 a, (0x329c)
	jr z, AccentVoice_UpdateParamIndex
	ordi8 (0x3271), 0x01
AccentVoice_UpdateParamIndex:
	ldb_d8	a, (12905)
	and	a, 3
	stb_d8	(12958), a
	ret
AccVoice_ResolveParamAddr:
	push xwa
	push xix
	ld xiy, RhythmTiming_OffsetTable
	cp a, 0x1d
	jr ule, AccVoice_ComputeParamOffset
	xor a, a

AccVoice_ComputeParamOffset:
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x02, 0xe8, 0x12, 0xe8
	.byte 0x85, 0xa5, 0x25, 0xc1, 0x4a, 0x32, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xec, 0x02, 0x44, 0x53, 0x39, 0xf5
	.byte 0x00, 0xe3, 0x07, 0xf0, 0xe0, 0x24, 0xec, 0x85
	.byte 0xed, 0xc8, 0x60, 0x00, 0x00, 0x00, 0x5c, 0x58
	.byte 0x0e
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
	ld xiy, Display_FontPalette_Table_0x2EA
	ldw_sri WA, 0x07, 0xf4, 0xec
	add hl, 0x2
	ldw_sri IY, 0x07, 0xf4, 0xec
	ret

AccVoice_LookupWithOffset:
	calr AccVoice_ComputeChannelIndex
	call AccVoice_TableLookup_Inner
	extz xiy
	add xhl, xiy
	ld xiy, xhl
	ret

AccVoice_SelectAndApplyPatch:
	cpdi8 (0x3249), 0x80
	jr nc, AccVoice_PatchFromDirect
	ldda32 xiy, (0x3232)
	calr AccStyle_ReadVoiceParam
	stb_d8 (0x3253), w
	jr t, AccVoice_StorePatchAndLookup
AccVoice_PatchFromDirect:
	ldb_d8	a, (12873)
	and	a, 127
	calr	43
AccVoice_StorePatchAndLookup:
	.byte 0xf1, 0x33, 0x04, 0x41, 0x43, 0x9e, 0x6b, 0xe4
	.byte 0x00, 0xc9, 0xec, 0x01, 0xd3, 0x03, 0xec, 0xe0
	.byte 0x20, 0xf1, 0xdf, 0x31, 0x50, 0x0e
AccStyle_ReadVoiceParam:
	ldb_sri0 W, (xiy + 0x03da)
	ldb_sri0 A, (xiy + 0x03d0)
	ld xhl, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

; ============================================================================
; AccPatch_SetVoiceParam - Set accompaniment voice parameter
; ============================================================================
; Clamps register A to <= 0x1d (29 voices), then indexes into table at
; 0xe46b8a to set a voice parameter. Called 148+ times, typically in
; rapid bursts during accompaniment patch configuration.
; ============================================================================
AccPatch_SetVoiceParam:
	cp a, 0x1d
	jr ule, AccPatch_ClampedSetParam
	xor a, a

AccPatch_ClampedSetParam:
	ld w, a
	calr AccVoice_ResolveParamAddr
	ld a, (xiy + 12)
	ld xhl, Display_FontPalette_Table_0x1D32
	ldb_sri A, 0x03, 0xec, 0xe0
	ret

AccVoice_LoadTuningBlock:
	push xiy

	add xhl, 0x248

	add xiy, xhl

	.byte 0x44, 0xaa, 0x31, 0x00, 0x00	; ld xix, 0x3246 (v7 patched)

	ldw bc, 0x31

	ldir85

	push xwa

	push xix

	.byte 0x44, 0xaa, 0x31, 0x00, 0x00	; ld xix, 0x3246 (v7 patched)

	ldw wa, 0x9

	stib_ind 0x07, 0xf0, 0xe0, 0x40

	ldw wa, 0x10

	stib_ind 0x07, 0xf0, 0xe0, 0x0c

	ldw wa, 0x17

	stib_ind 0x07, 0xf0, 0xe0, 0x74

	ldw wa, 0x1e

	stib_ind 0x07, 0xf0, 0xe0, 0x40

	pop xix

	pop xwa

	pop xiy

	call	16094128

	nop

	nop

	nop

	nop

	ret



AccTuning_CopyAllPartsFromStyle:
	push xiy

	ld xhl, xiy

	add xiy, 0x18

	.byte 0x44, 0xaa, 0x31, 0x00, 0x00	; ld xix, 0x3246 (v7 patched)

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x20

	.byte 0x44, 0xb1, 0x31, 0x00, 0x00	; ld xix, 0x324d (v7 patched)

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x28

	.byte 0x44, 0xb8, 0x31, 0x00, 0x00	; ld xix, 0x3254 (v7 patched)

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x30

	.byte 0x44, 0xbf, 0x31, 0x00, 0x00	; ld xix, 0x325b (v7 patched)

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x38

	.byte 0x44, 0xc6, 0x31, 0x00, 0x00	; ld xix, 0x3262 (v7 patched)

	lds bc, 7

	ldir85

	pop xiy

	ret



AccTuning_LoadAndApplyMaster:
	push xiy

	add xhl, 0x248

	add xiy, xhl

	.byte 0x44, 0xaa, 0x31, 0x00, 0x00	; ld xix, 0x3246 (v7 patched)

	lds bc, 7

	ldir85

	.byte 0x1d, 0x4a, 0x94, 0xf5	; call AccTuning_LoadMaster (v7 addr)

	pop xiy

	nop

	nop

	nop

	nop

	ret



AccTuning_LoadCoarseFromStyle:
	push xiy

	add xhl, 0x24f

	add xiy, xhl

	.byte 0x44, 0xb1, 0x31, 0x00, 0x00	; ld xix, 0x324d (v7 patched)

	lds bc, 7

	ldir85

	.byte 0x44, 0xb3, 0x31, 0x00, 0x00	; ld xix, 0x324f (v7 patched)

	ld (xix), 0x40

	.byte 0x1d, 0x6b, 0x94, 0xf5	; call AccTuning_LoadCoarse (v7 addr)

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

	.byte 0x44, 0xb8, 0x31, 0x00, 0x00	; ld xix, 0x3254 (v7 patched)

	lds bc, 7

	ldir85

	.byte 0x44, 0xba, 0x31, 0x00, 0x00	; ld xix, 0x3256 (v7 patched)

	ld (xix), 0xc

	.byte 0x1d, 0x98, 0x94, 0xf5	; call AccTuning_LoadFine (v7 addr)

	pop xiy

	nop

	nop

	nop

	nop

	ret



AccTuning_LoadOctaveFromStyle:
	push xiy

	add xhl, 0x25d

	add xiy, xhl

	.byte 0x44, 0xbf, 0x31, 0x00, 0x00	; ld xix, 0x325b (v7 patched)

	lds bc, 7

	ldir85

	.byte 0x44, 0xc1, 0x31, 0x00, 0x00	; ld xix, 0x325d (v7 patched)

	ld (xix), 0x74

	.byte 0x1d, 0xc5, 0x94, 0xf5	; call AccTuning_LoadOctave (v7 addr)

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

	.byte 0x44, 0xc6, 0x31, 0x00, 0x00	; ld xix, 0x3262 (v7 patched)

	lds bc, 7

	ldir85

	.byte 0x44, 0xc8, 0x31, 0x00, 0x00	; ld xix, 0x3264 (v7 patched)

	ld (xix), 0x40

	.byte 0x1d, 0xf2, 0x94, 0xf5	; call AccTuning_LoadTranspose (v7 addr)

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
	bitda 0, (0x31e7)
	jr nz, Rhythm_ProcessAllDone
	call AccVoice_LoadAllChannelParams
Rhythm_ProcessAllDone:
	ret

RhythmPart_CopyData:
	ldw bc, 0x19

	.byte 0x45, 0x78, 0x31, 0x00, 0x00	; ld xiy, 0x3214 (v7 patched)

	.byte 0x44, 0x91, 0x31, 0x00, 0x00	; ld xix, 0x322d (v7 patched)

	ldir85

	ret



RhythmPart1_ProcessAccentData:
	bitda 0, (0x31e7)
	jr z, .Lc_f53b8c
	call AccentData_ComparePart1
RhythmPart1_CheckAccentData:
.Lc_f53b8c:
	ldb_d8 a, (0x3290)
	and A,0x03
	jr z, RhythmPart1_WriteDone
	ldb_d8 e, (0x31aa)
	ldb_d8 d, (0x31ab)
	bitda 0, (0x31e7)
	jr nz, .Lc_f53baf
	ld XHL,0x00003178
	ld (XHL),E
	ld (XHL+0x01),D
	jr t, RhythmPart1_WriteDone
RhythmPart1_ProcessRingBuf:
.Lc_f53baf:
	ld XHL,0x000029f8

	ld iy, (xhl + 4)

	ld bc, (xhl + 2)

	stib_ind 0x07, 0xec, 0xf4, 0xc0

	.byte 0x1e, 0x92, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	.byte 0x1e, 0x41, 0x00	; calr RhythmAccent_CopyAndUpdateRingBuf (v7 displacement)

	stb_dri E, 0x07, 0xec, 0xf4

	.byte 0x1e, 0x87, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	stb_dri D, 0x07, 0xec, 0xf4

	ldb w, 0x0

	.byte 0x1e, 0x7d, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	stb_dri W, 0x07, 0xec, 0xf4

	.byte 0x1e, 0x75, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	stb_dri W, 0x07, 0xec, 0xf4

	.byte 0x1e, 0x6d, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	stb_dri W, 0x07, 0xec, 0xf4

	.byte 0x1e, 0x65, 0x00	; calr RingBuf_AdvanceIndex (v7 displacement)

	ld (xhl + 4), iy

	.byte 0x43, 0x78, 0x31, 0x00, 0x00	; ld xhl, 0x3214 (v7 patched)

	ld (xhl), e

	ld (xhl + 1), d



RhythmPart1_WriteDone:
	.byte 0xc1, 0x90, 0x32, 0x3c, 0xfc	; anddi8 (0x332c), 252 (v7 patched)

	.byte 0x1d, 0x00, 0xc6, 0xf5	; call AccVoiceReg_WritePart1 (v7 addr)

	ret



RhythmAccent_CopyAndUpdateRingBuf:
	pushw	de
	pushw	wa
	ldb_d8	a, (12880)
	stb_d8	(13202), a
	calr	3
	popw	wa
	popw	de
	ret
RhythmAccent_UpdateRingBufPosition:
	ldb_d8 a, (0x3392)
	ei 0x06
	subda8 a, (0x0464)
	jr ugt, RhythmAccent_StorePosition
	ldb A, 0x01
	stb_d8 (0x3392), a
	cpdi8 (0x0462), 0x00
	jr z, RhythmAccent_AddAndCompare
	xor A,A
	jr t, RhythmAccent_AddAndCompare
RhythmAccent_StorePosition:
	stb_d8	(13202), a
RhythmAccent_AddAndCompare:
	ldb_d8	w, 1122
	add	a, w
	st_rrb	a, xhl, iy
	calr	15
	ldb_d8	w, 13018
	cp	a, w
	jr	nc, 4
	stb_d8	13018, a
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
	bitda 0, (0x31e7)
	jr z, .Lc_f53c6b
	call AccentData_ComparePart2
RhythmPart2_LoadAndStore:
.Lc_f53c6b:
	bitda 2, (0x3290)
	ldb_d8 e, (0x31b1)
	ldb_d8 d, (0x31b2)
	ldb_d8 a, (0x31b3)
	stb_d8 (0x3393), a
	ldb_d8 a, (0x31b4)
	stb_d8 (0x3394), a
	ldb_d8 a, (0x31b5)
	stb_d8 (0x3395), a
	ldb_d8 a, (0x31b6)
	stb_d8 (0x3227), a
	ldb_d8 a, (0x31b7)
	stb_d8 (0x322b), a
	calr Rhythm_PackVelocityHighBit
	bitda 0, (0x31e7)
	jr nz, .Lc_f53cb2
	ld XHL,0x0000317d
	calr AccVoiceReg_StoreParamRecord
	jr t, .Lc_f53d08
RhythmPart2_ProcessRingBuf:
.Lc_f53cb2:
	ld XHL,0x00002bf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	stib_ind 0x07, 0xec, 0xf4, 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	stb_dri e, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	stb_dri d, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3393)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3394)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3395)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x0000317d
	calr AccVoiceReg_StoreParamRecord
RhythmPart2_WriteDone:
.Lc_f53d08:
	anddi8 (0x3290), 0xfb
	call AccVoiceReg_WritePart2

	ret



AccVoiceReg_StoreParamRecord:
	ld	(xhl), e
	ld	(xhl+1), d
	ldb_d8	a, (13203)
	ld	(xhl+2), a
	ldb_d8	a, (13204)
	ld	(xhl+3), a
	ldb_d8	a, (13205)
	ld	(xhl+4), a
	ret
Rhythm_PackVelocityHighBit:
	bit 7, e
	jr z, Rhythm_VelocityPackDone
	or d, 0x10
	and e, 0x7f

Rhythm_VelocityPackDone:
	ret

AccVoice_LoadRhythmParams_Part3:
	bitda 0, (0x31e7)
	jr z, .Lc_f53d43
	call AccentData_ComparePart3
RhythmPart3_LoadAndStore:
.Lc_f53d43:
	bitda 3, (0x3290)
	ldb_d8 e, (0x31b8)
	ldb_d8 d, (0x31b9)
	ldb_d8 a, (0x31ba)
	stb_d8 (0x3393), a
	ldb_d8 a, (0x31bb)
	stb_d8 (0x3394), a
	ldb_d8 a, (0x31bc)
	stb_d8 (0x3395), a
	ldb_d8 a, (0x31bd)
	stb_d8 (0x3228), a
	ldb_d8 a, (0x31be)
	stb_d8 (0x322c), a
	calr Rhythm_PackVelocityHighBit
	bitda 0, (0x31e7)
	jr nz, .Lc_f53d8a
	ld XHL,0x00003182
	calr AccVoiceReg_StoreParamRecord
	jr t, .Lc_f53de0
RhythmPart3_ProcessRingBuf:
.Lc_f53d8a:
	ld XHL,0x00002cf8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	stib_ind 0x07, 0xec, 0xf4, 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	stb_dri e, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	stb_dri d, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3393)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3394)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3395)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x00003182
	calr AccVoiceReg_StoreParamRecord
RhythmPart3_WriteDone:
.Lc_f53de0:
	anddi8 (0x3290), 0xf7
	call AccVoiceReg_WritePart3

	ret



AccVoice_LoadRhythmParams_Part4:
	bitda 0, (0x31e7)
	jr z, .Lc_f53df4
	call AccentData_ComparePart4
RhythmPart4_LoadAndStore:
.Lc_f53df4:
	bitda 4, (0x3290)
	ldb_d8 e, (0x31bf)
	ldb_d8 d, (0x31c0)
	ldb_d8 a, (0x31c1)
	stb_d8 (0x3393), a
	ldb_d8 a, (0x31c2)
	stb_d8 (0x3394), a
	ldb_d8 a, (0x31c3)
	stb_d8 (0x3395), a
	ldb_d8 a, (0x31c4)
	stb_d8 (0x3229), a
	ldb_d8 a, (0x31c5)
	stb_d8 (0x322d), a
	calr Rhythm_PackVelocityHighBit
	bitda 0, (0x31e7)
	jr nz, .Lc_f53e3b
	ld XHL,0x00003187
	calr AccVoiceReg_StoreParamRecord
	jr t, .Lc_f53e91
RhythmPart4_ProcessRingBuf:
.Lc_f53e3b:
	ld XHL,0x00002df8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	stib_ind 0x07, 0xec, 0xf4, 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	stb_dri e, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	stb_dri d, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3393)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3394)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3395)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x00003187
	calr AccVoiceReg_StoreParamRecord
RhythmPart4_WriteDone:
.Lc_f53e91:
	anddi8 (0x3290), 0xef
	call AccVoiceReg_WritePart4

	ret



AccVoice_LoadRhythmParams_Part5:
	bitda 0, (0x31e7)
	jr z, .Lc_f53ea5
	call AccentData_ComparePart5
RhythmPart5_LoadAndStore:
.Lc_f53ea5:
	bitda 5, (0x3290)
	ldb_d8 e, (0x31c6)
	ldb_d8 d, (0x31c7)
	ldb_d8 a, (0x31c8)
	stb_d8 (0x3393), a
	ldb_d8 a, (0x31c9)
	stb_d8 (0x3394), a
	ldb_d8 a, (0x31ca)
	stb_d8 (0x3395), a
	ldb_d8 a, (0x31cb)
	stb_d8 (0x322a), a
	ldb_d8 a, (0x31cc)
	stb_d8 (0x322e), a
	calr Rhythm_PackVelocityHighBit
	bitda 0, (0x31e7)
	jr nz, .Lc_f53eec
	ld XHL,0x0000318c
	calr AccVoiceReg_StoreParamRecord
	jr t, .Lc_f53f42
RhythmPart5_ProcessRingBuf:
.Lc_f53eec:
	ld XHL,0x00002ef8
	ld IY,(XHL+0x04)
	ld BC,(XHL+0x02)
	stib_ind 0x07, 0xec, 0xf4, 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	stb_dri e, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	stb_dri d, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3393)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3394)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ldb_d8 a, (0x3395)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x0000318c
	calr AccVoiceReg_StoreParamRecord
RhythmPart5_WriteDone:
.Lc_f53f42:
	anddi8 (0x3290), 0xdf
	call AccVoiceReg_WritePart5

	ret



AccompVoice_BulkReadRegisters:
	ldb	a, 0
	ld	xhl, 12280
	xor	iy, iy
BulkRead_Loop1_6Byte:
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x06
	.byte 0x00, 0xdd, 0xcf, 0x30, 0x00, 0x67, 0xf1, 0x43
	.byte 0x28, 0x30, 0x00, 0x00, 0xdd, 0xd5
BulkRead_Loop2_6Byte:
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x06
	.byte 0x00, 0xdd, 0xcf, 0x30, 0x00, 0x67, 0xf1, 0x43
	.byte 0x58, 0x30, 0x00, 0x00, 0xdd, 0xd5
BulkRead_Loop3_9Byte:
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0xa0, 0x30, 0x00, 0x00, 0xdd, 0xd5
BulkRead_Loop4_9Byte:
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0xe8, 0x30, 0x00, 0x00, 0xdd, 0xd5
BulkRead_Loop5_9Byte:
	.byte 0xf3, 0x07, 0xec, 0xf4, 0x41, 0xdd, 0xc8, 0x09
	.byte 0x00, 0xdd, 0xcf, 0x48, 0x00, 0x67, 0xf1, 0x43
	.byte 0x30, 0x31, 0x00, 0x00, 0xdd, 0xd5
BulkRead_Loop6_9Byte:
	stb_dri A, 0x07, 0xec, 0xf4
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop6_9Byte
	ret

Rhythm_SendNoteOnMax:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x7f
	calr Rhythm_Send3ByteMsg
	ret

Rhythm_Send3ByteMsg:
	stb_d8	(13126), a
	stb_d8	(13127), w
	stb_d8	(13128), e
	ldb_d8	a, (13126)
	call	16076951
	ldb_d8	a, (13127)
	call	16076951
	ldb_d8	a, (13128)
	call	16076951
	ret
Rhythm_SendChanPressure:
	ldb	a, 208
	ldb	w, 3
	ldb	e, 0
	calr	65490
	ldb	a, 0
	stb_d8	(12947), a
	stb_d8	(12948), a
	stb_d8	(12949), a
	stb_d8	(12950), a
	ret
AccBuf_ResetAndReload:
	call AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	call AccStyle_InitVRAM_Wrap
	ret

AccVoice_LoadAllChannelParams:
	ld	xix, 12664
	ldb	a, 152
	and	a, 15
	or	a, 192
	call	16076951
	call	16072853
	ld	xix, 12669
	ldb	a, 151
	and	a, 15
	or	a, 192
	call	16076951
	call	16072853
	ld	xix, 12674
	ldb	a, 148
	and	a, 15
	or	a, 192
	call	16076951
	call	16072853
	ld	xix, 12679
	ldb	a, 149
	and	a, 15
	or	a, 192
	call	16076951
	call	16072853
	ld	xix, 12684
	ldb	a, 150
	and	a, 15
	or	a, 192
	call	16076951
	call	16072853
	ret
VoiceParams_LoadFiveSequential:
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ldb_spi A, 0xf0
	call Rhythm_SendByte
	ret

AccVoice_BytecodeBlock3:
	.byte 0x1e, 0x0d, 0x00, 0x1e, 0x15, 0x00, 0x1e, 0x1d
	.byte 0x00, 0x1e, 0x25, 0x00, 0x1e, 0x2d, 0x00, 0x0e
	.byte 0xf1, 0xaa, 0x31, 0x00, 0x06, 0xf1, 0xab, 0x31
	.byte 0x00, 0x00, 0x0e, 0xf1, 0xb1, 0x31, 0x00, 0x00
	.byte 0xf1, 0xb2, 0x31, 0x00, 0x00, 0x0e, 0xf1, 0xb8
	.byte 0x31, 0x00, 0x00, 0xf1, 0xb9, 0x31, 0x00, 0x00
	.byte 0x0e, 0xf1, 0xbf, 0x31, 0x00, 0x00, 0xf1, 0xc0
	.byte 0x31, 0x00, 0x00, 0x0e, 0xf1, 0xc6, 0x31, 0x00
	.byte 0x00, 0xf1, 0xc7, 0x31, 0x00, 0x00, 0x0e, 0xf1
	.byte 0x59, 0x32, 0x00, 0x0f, 0xc1, 0x5b, 0x32, 0x3c
	.byte 0xf8, 0xc1, 0x5b, 0x32, 0x3e, 0x00, 0x0e, 0x0e
	.byte 0x1d, 0xe5, 0x57, 0xf5, 0xf1, 0x8f, 0x32, 0x45
	.byte 0x0e, 0xc1, 0x5a, 0xfc, 0x21, 0xc1, 0x5b, 0xfc
	.byte 0x24, 0x1d, 0xaf, 0x57, 0xf5, 0xf1, 0x8f, 0x32
	.byte 0x41, 0x0e
RhythmROM_CheckValid:
	ldb C, 0x00
	ld XWA,0xffffffff
	cpda32 xwa, (0x31db)
	jr z, RhythmROM_InvalidIncrement
	jr t, RhythmROM_CheckDone
RhythmROM_InvalidIncrement:
	ldb	c, 1
	ldw_d16	wa, (13240)
	add	wa, 1
	stda16	(13240), wa
	cps	wa, 0
	jr	nz, 11
	ldb	a, 238
	stb_d8	(58134), a
	stdi8	(58136), 64
RhythmROM_CheckDone:
	ret

RhythmROM_BytecodeBlock4:
	ld	xwa, 1024
	push	xwa
	call	16713379
	add	xsp, 4
	stda32	(13504), xhl
	ld	xwa, 4096
	push	xwa
	call	16713379
	add	xsp, 4
	ld	xwa, xhl
	ld	xwa, xwa
	push	xwa
	call	16712469
	add	xsp, 4
	ldda32	xwa, (13504)
	push	xwa
	call	16712469
	add	xsp, 4
	ret
AccentData_ComparePart1:
	ld XIX,0x00003178
	ld XIY,0x000031aa
	ld XWA,(XIX)
	ld XBC,(XIY)
	ld L,(XIX+0x01)
	ld H,(XIY+0x01)
	cp XWA,XBC
	jr nz, AccentData_Part1_Done
	cp L,H
	jr nz, AccentData_Part1_Done
	anddi8 (0x3290), 0xfc
AccentData_Part1_Done:
	ret

AccentData_ComparePart2:
	ld XIX,0x00003178
	ld XIY,0x000031aa
	ld XWA,(XIX+0x05)
	ld XBC,(XIY+0x07)
	ld L,(XIX+0x01)
	ld H,(XIY+0x01)
	cp XWA,XBC
	jr nz, AccentData_Part2_Done
	cp L,H
	jr nz, AccentData_Part2_Done
	anddi8 (0x3290), 0xfb
AccentData_Part2_Done:
	ret

AccentData_ComparePart3:
	ld XIX,0x00003178
	ld XIY,0x000031aa
	ld XWA,(XIX+0x0a)
	ld XBC,(XIY+0x0e)
	ld L,(XIX+0x01)
	ld H,(XIY+0x01)
	cp XWA,XBC
	jr nz, AccentData_Part3_Done
	cp L,H
	jr nz, AccentData_Part3_Done
	anddi8 (0x3290), 0xf7
AccentData_Part3_Done:
	ret

AccentData_ComparePart4:
	ld XIX,0x00003178
	ld XIY,0x000031aa
	ld XWA,(XIX+0x0f)
	ld XBC,(XIY+0x15)
	ld L,(XIX+0x01)
	ld H,(XIY+0x01)
	cp XWA,XBC
	jr nz, AccentData_Part4_Done
	cp L,H
	jr nz, AccentData_Part4_Done
	anddi8 (0x3290), 0xef
AccentData_Part4_Done:
	ret

AccentData_ComparePart5:
	ld XIX,0x00003178
	ld XIY,0x000031aa
	ld XWA,(XIX+0x14)
	ld XBC,(XIY+0x1c)
	ld L,(XIX+0x01)
	ld H,(XIY+0x01)
	cp XWA,XBC
	jr nz, AccentData_Part5_Done
	cp L,H
	jr nz, AccentData_Part5_Done
	anddi8 (0x3290), 0xdf
AccentData_Part5_Done:
	ret

RhythmROM_ValidateHeader:
	xor	xwa, xwa
	stda32	(12763), xwa
	ld	xix, 4194304
	ld	xwa, (xix)
	cp	xwa, 84148480
	jr	nz, 24
	ld	xwa, (xix+4)
	cp	xwa, 67174531
	jr	nz, 13
	ld	xwa, (xix+8)
	cp	xwa, 16810757
	jr	nz, 2
	jr	9
AccChord_CheckFailed:
	ld	xwa, 4294967295
	stda32	(12763), xwa
RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	xor XHL,XHL
	ld L,W
	and L,0x7f
	srl L, 0x02
	cpdi8 (0x324a), 0x00
	jrl nz, AccPatch_ChIdx1_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx0_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx0_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	63249
	stda16	(13000), wa
	ldb	a, 19
	calr	63240
	stda16	(13002), wa
	ldb	a, 20
	calr	63231
	stda16	(13004), wa
	ldb	a, 21
	calr	63222
	stda16	(13006), wa
	ldb	a, 22
	calr	63213
	stda16	(13008), wa
	ldb	a, 23
	calr	63204
	stda16	(13010), wa
	jrl	1293
AccPatch_ChIdx0_Bank2:
	ldb	a, 24
	calr	63192
	stda16	(13000), wa
	ldb	a, 25
	calr	63183
	stda16	(13002), wa
	ldb	a, 26
	calr	63174
	stda16	(13004), wa
	ldb	a, 27
	calr	63165
	stda16	(13006), wa
	ldb	a, 28
	calr	63156
	stda16	(13008), wa
	ldb	a, 29
	calr	63147
	stda16	(13010), wa
	jrl	1236
AccPatch_ChIdx1_Entry:
	cpdi8 (0x324a), 0x01
	jrl nz, AccPatch_ChIdx2_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx1_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx1_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	63062
	stda16	(13000), wa
	ldb	a, 19
	calr	63053
	stda16	(13002), wa
	ldb	a, 20
	calr	63044
	stda16	(13004), wa
	ldb	a, 21
	calr	63035
	stda16	(13006), wa
	ldb	a, 22
	calr	63026
	stda16	(13008), wa
	ldb	a, 23
	calr	63017
	stda16	(13010), wa
	jrl	1106
AccPatch_ChIdx1_Bank2:
	ldb	a, 24
	calr	63005
	stda16	(13000), wa
	ldb	a, 25
	calr	62996
	stda16	(13002), wa
	ldb	a, 26
	calr	62987
	stda16	(13004), wa
	ldb	a, 27
	calr	62978
	stda16	(13006), wa
	ldb	a, 28
	calr	62969
	stda16	(13008), wa
	ldb	a, 29
	calr	62960
	stda16	(13010), wa
	jrl	1049
AccPatch_ChIdx2_Entry:
	cpdi8 (0x324a), 0x02
	jrl nz, AccPatch_ChIdx3_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx2_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx2_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62875
	stda16	(13000), wa
	ldb	a, 19
	calr	62866
	stda16	(13002), wa
	ldb	a, 20
	calr	62857
	stda16	(13004), wa
	ldb	a, 21
	calr	62848
	stda16	(13006), wa
	ldb	a, 22
	calr	62839
	stda16	(13008), wa
	ldb	a, 23
	calr	62830
	stda16	(13010), wa
	jrl	919
AccPatch_ChIdx2_Bank2:
	ldb	a, 24
	calr	62818
	stda16	(13000), wa
	ldb	a, 25
	calr	62809
	stda16	(13002), wa
	ldb	a, 26
	calr	62800
	stda16	(13004), wa
	ldb	a, 27
	calr	62791
	stda16	(13006), wa
	ldb	a, 28
	calr	62782
	stda16	(13008), wa
	ldb	a, 29
	calr	62773
	stda16	(13010), wa
	jrl	862
AccPatch_ChIdx3_Entry:
	cpdi8 (0x324a), 0x03
	jrl nz, AccPatch_ChIdx4_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx3_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx3_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62688
	stda16	(13000), wa
	ldb	a, 19
	calr	62679
	stda16	(13002), wa
	ldb	a, 20
	calr	62670
	stda16	(13004), wa
	ldb	a, 21
	calr	62661
	stda16	(13006), wa
	ldb	a, 22
	calr	62652
	stda16	(13008), wa
	ldb	a, 23
	calr	62643
	stda16	(13010), wa
	jrl	732
AccPatch_ChIdx3_Bank2:
	ldb	a, 24
	calr	62631
	stda16	(13000), wa
	ldb	a, 25
	calr	62622
	stda16	(13002), wa
	ldb	a, 26
	calr	62613
	stda16	(13004), wa
	ldb	a, 27
	calr	62604
	stda16	(13006), wa
	ldb	a, 28
	calr	62595
	stda16	(13008), wa
	ldb	a, 29
	calr	62586
	stda16	(13010), wa
	jrl	675
AccPatch_ChIdx4_Entry:
	cpdi8 (0x324a), 0x04
	jrl nz, AccPatch_ChIdx5_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx4_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx4_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62501
	stda16	(13000), wa
	ldb	a, 19
	calr	62492
	stda16	(13002), wa
	ldb	a, 20
	calr	62483
	stda16	(13004), wa
	ldb	a, 21
	calr	62474
	stda16	(13006), wa
	ldb	a, 22
	calr	62465
	stda16	(13008), wa
	ldb	a, 23
	calr	62456
	stda16	(13010), wa
	jrl	545
AccPatch_ChIdx4_Bank2:
	ldb	a, 24
	calr	62444
	stda16	(13000), wa
	ldb	a, 25
	calr	62435
	stda16	(13002), wa
	ldb	a, 26
	calr	62426
	stda16	(13004), wa
	ldb	a, 27
	calr	62417
	stda16	(13006), wa
	ldb	a, 28
	calr	62408
	stda16	(13008), wa
	ldb	a, 29
	calr	62399
	stda16	(13010), wa
	jrl	488
AccPatch_ChIdx5_Entry:
	cpdi8 (0x324a), 0x05
	jrl nz, AccPatch_ChIdx6_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx5_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx5_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62314
	stda16	(13000), wa
	ldb	a, 19
	calr	62305
	stda16	(13002), wa
	ldb	a, 20
	calr	62296
	stda16	(13004), wa
	ldb	a, 21
	calr	62287
	stda16	(13006), wa
	ldb	a, 22
	calr	62278
	stda16	(13008), wa
	ldb	a, 23
	calr	62269
	stda16	(13010), wa
	jrl	358
AccPatch_ChIdx5_Bank2:
	ldb	a, 24
	calr	62257
	stda16	(13000), wa
	ldb	a, 25
	calr	62248
	stda16	(13002), wa
	ldb	a, 26
	calr	62239
	stda16	(13004), wa
	ldb	a, 27
	calr	62230
	stda16	(13006), wa
	ldb	a, 28
	calr	62221
	stda16	(13008), wa
	ldb	a, 29
	calr	62212
	stda16	(13010), wa
	jrl	301
AccPatch_ChIdx6_Entry:
	cpdi8 (0x324a), 0x06
	jrl nz, AccPatch_ChIdxDefault_Bank0
	cps l, 0
	jr nz, AccPatch_ChIdx6_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	stda16 (0x32c8), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	stda16 (0x32ca), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	stda16 (0x32cc), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	stda16 (0x32ce), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	stda16 (0x32d0), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	stda16 (0x32d2), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx6_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62127
	stda16	(13000), wa
	ldb	a, 19
	calr	62118
	stda16	(13002), wa
	ldb	a, 20
	calr	62109
	stda16	(13004), wa
	ldb	a, 21
	calr	62100
	stda16	(13006), wa
	ldb	a, 22
	calr	62091
	stda16	(13008), wa
	ldb	a, 23
	calr	62082
	stda16	(13010), wa
	jrl	171
AccPatch_ChIdx6_Bank2:
	ldb	a, 24
	calr	62070
	stda16	(13000), wa
	ldb	a, 25
	calr	62061
	stda16	(13002), wa
	ldb	a, 26
	calr	62052
	stda16	(13004), wa
	ldb	a, 27
	calr	62043
	stda16	(13006), wa
	ldb	a, 28
	calr	62034
	stda16	(13008), wa
	ldb	a, 29
	calr	62025
	stda16	(13010), wa
	jrl	114
AccPatch_ChIdxDefault_Bank0:
	cps	l, 0
	jr	nz, 56
	ldb	a, 12
	calr	62009
	stda16	(13000), wa
	ldb	a, 13
	calr	62000
	stda16	(13002), wa
	ldb	a, 14
	calr	61991
	stda16	(13004), wa
	ldb	a, 15
	calr	61982
	stda16	(13006), wa
	ldb	a, 16
	calr	61973
	stda16	(13008), wa
	ldb	a, 17
	calr	61964
	stda16	(13010), wa
	jr	54
AccPatch_ChIdxDefault_Bank1:
	ldb	a, 18
	calr	61953
	stda16	(13000), wa
	ldb	a, 19
	calr	61944
	stda16	(13002), wa
	ldb	a, 20
	calr	61935
	stda16	(13004), wa
	ldb	a, 21
	calr	61926
	stda16	(13006), wa
	ldb	a, 22
	calr	61917
	stda16	(13008), wa
	ldb	a, 23
	calr	61908
	stda16	(13010), wa
AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
