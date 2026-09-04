; =============================================================================
; Sequencer Audio Mode & Accompaniment Processing (2K lines)
; =============================================================================
;
; Audio mode stereo flags, accompaniment pedal processing,
; sequencer timing setup, part activation, and audio flag
; dispatch between SMF event processing and rhythm routines.
; =============================================================================

	ei 0
	ld (0x31e3:16), a
	ret

AudioMode_CheckAndUpdateStereo:
	bit 3, (0x31e8:16)
	jr z, AudioMode_CheckDone
	ld a, (0x31e3:16)
	cp A,0x5d
	jr nc, .Lc_f5336e
	cp A,0x30
	jr ugt, AudioMode_CheckDone
AudioMode_ApplyStereoUpdate:
.Lc_f5336e:
	call 0xfdd7c0
	and (0x31e8:16), 0xf7



AudioMode_CheckDone:
	ret

AudioMode_MergeOutputBits:
	ld	a, (12916:16)
	and	a, 248
	ld	w, (12893:16)
	and	w, 7
	or	a, w
	ld	(12916:16), a
	ret
AudioMode_CopyChannelMode:
	ld	a, (10418:16)
	and	a, 3
	ld	(12953:16), a
	ret
AudioMode_CopyAccentFlags:
	ld	a, (13397:16)
	and	a, 61
	ld	(12998:16), a
	ret
AccPedal_BytecodeBlock1:
	.byte 0x28, 0x3d, 0xc1, 0xc7, 0x32, 0x3c, 0xfe, 0x45
	.byte 0x00, 0x48, 0x09, 0x00, 0xed, 0xc8, 0x10, 0x00
	.byte 0x00, 0x00, 0x85, 0x21, 0xc9, 0x33, 0x00, 0x66
	.byte 0x05, 0xc1, 0xc7, 0x32, 0x3e, 0x01, 0x5d
AccPedal_BytecodeBlock1_Code:
	popw	wa
	ret	
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
	ld a, (0x0433:16)
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
	ld	(12895:16), a
	ld	(12897:16), a
	ld	(12899:16), a
AccPedal_ReadBankAndReturn:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	xor WA,WA
	ld XHL,Display_FontPalette_Table_0x1D58
	ld a, (0x0433:16)
	.byte 0xc3, 0x07, 0xec, 0xe0, 0x21, 0xf1, 0xe7, 0x31
	.byte 0xc8, 0x6e, 0x02, 0x21, 0x00
AccVoice_StoreBankAssign:
	ld	(12774:16), a
	ret
AccChannel_CompareAndMarkDirty:
	ld a, (0x3278:16)
	orda8 a, (0x3279)
	and A,0x3f
	jr nz, AccChannel_StoreCurrentState
	ld a, (0x3259:16)
	cp a, (0x325a:16)
	jr nz, .Lc_f534c3
	ld a, (0x325b:16)
	and A,0x7f
	and A,0x07
	ld w, (0x325c:16)
	and W,0x7f
	and W,0x07
	cp A,W
	jr z, AccChannel_StoreCurrentState
AccChannel_MarkDirtyAndSync:
.Lc_f534c3:
	calr AccChannel_SetDirtyIfActive
	calr AccChannel_CheckActivitySetDirty
	calr AccChannel_CheckPartIndexDirty
	or (0x3270:16), 0x01



AccChannel_StoreCurrentState:
	ld	a, (12889:16)
	ld	(12875:16), a
	ld	a, (12891:16)
	and	a, 127
	and	w, 7
	ld	(12876:16), a
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
	ld wa, (0x3247:16)
	and W,0x07
	cps w, 0
	jr z, AccChannel_SetDirtyDone
	or (0x328a:16), 0x3f
AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	ld a, (0x3276:16)
	orda8 a, (0x3277)
	orda8 a, (0x327a)
	orda8 a, (0x327b)
	orda8 a, (0x327c)
	and A,0x3f
	jr z, AccChannel_ActivityCheckDone
	cp (0x3259:16), 0x80
	jr c, AccChannel_ActivityCheckDone
	or (0x328a:16), 0x3f
AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	ld a, (0x0433:16)
	cps a, 1
	jr nz, AccChannel_PartIndexDone
	or (0x328a:16), 0x3f
AccChannel_PartIndexDone:
	ret

AccVoice_ProcessPedalChanges:
	bit 0, (0x3263:16)
	jr z, .Lc_f535a1
	bit 0, (0x3264:16)
	jr nz, .Lc_f535a1
	xor A,A
	ld (0x326d:16), a
	ld (0x326f:16), a
	and (0x326e:16), 0xf3
	and (0x328b:16), 0xc0
	bit 0, (0x3270:16)
	jr nz, .Lc_f53596
	and (0x328a:16), 0xc0
AccVoice_Pedal0_SetAndCheck:
.Lc_f53596:
	or (0x326e:16), 0x01
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_Pedal0_Done:
.Lc_f535a1:
	bit 1, (0x3263:16)
	jr z, .Lc_f535d7
	bit 1, (0x3264:16)
	jr nz, .Lc_f535d7
	xor A,A
	ld (0x326d:16), a
	ld (0x326f:16), a
	and (0x326e:16), 0xf6
	and (0x328b:16), 0xc0
	bit 0, (0x3270:16)
	jr nz, .Lc_f535cc
	and (0x328a:16), 0xc0
AccVoice_Pedal1_SetAndCheck:
.Lc_f535cc:
	or (0x326e:16), 0x04
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_Pedal1_Done:
.Lc_f535d7:
	bit 2, (0x3263:16)
	jr z, AccVoice_Pedal2_Done
	bit 2, (0x3264:16)
	jr nz, AccVoice_Pedal2_Done
	xor A,A
	ld (0x326d:16), a
	ld (0x326f:16), a
	and (0x326e:16), 0xfa
	and (0x328b:16), 0xc0
	bit 0, (0x3270:16)
	jr nz, .Lc_f53602
	and (0x328a:16), 0xc0
AccVoice_Pedal2_SetAndCheck:
.Lc_f53602:
	or (0x326e:16), 0x08
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive



AccVoice_Pedal2_Done:
	ret

AccVoice_ProcessLeftPedalChanges:
	bit 0, (0x325f:16)
	jr z, .Lc_f53644
	bit 0, (0x3260:16)
	jr nz, .Lc_f53644
	xor A,A
	ld (0x326e:16), a
	ld (0x326f:16), a
	and (0x326d:16), 0xfd
	and (0x328b:16), 0xc0
	bit 0, (0x3270:16)
	jr nz, .Lc_f53639
	and (0x328a:16), 0xc0
AccVoice_LeftPedal0_SetAndCheck:
.Lc_f53639:
	or (0x326d:16), 0x01
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive
AccVoice_LeftPedal0_Done:
.Lc_f53644:
	bit 1, (0x325f:16)
	jr z, AccVoice_LeftPedal1_Done
	bit 1, (0x3260:16)
	jr nz, AccVoice_LeftPedal1_Done
	xor A,A
	ld (0x326e:16), a
	ld (0x326f:16), a
	and (0x326d:16), 0xfe
	and (0x328b:16), 0xc0
	bit 0, (0x3270:16)
	jr nz, .Lc_f5366f
	and (0x328a:16), 0xc0
AccVoice_LeftPedal1_SetAndCheck:
.Lc_f5366f:
	or (0x326d:16), 0x02
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive



AccVoice_LeftPedal1_Done:
	ret

AccVoice_CheckChannelSetActive:
	ld a, (0x3278:16)
	orda8 a, (0x3279)
	and A,0x3f
	jr z, AccVoice_ChannelActiveDone
	or (0x3273:16), 0x01
AccVoice_ChannelActiveDone:
	ret

AccVoice_CheckBitsAndSetFlags:
	ld de, (0x3247:16)
	and D,0x07
	inc 1,D
	cp d, (0x0433:16)
	jr nz, AccVoice_BitsCheckDone
	or (0x328b:16), 0x3f
AccVoice_BitsCheckDone:
	ret

AccPitch_CheckTransposeFlags:
	bit 6, (0x33d4:16)
	jr nz, .Lc_f536c0
	bit 6, (0x31e5:16)
	jr z, .Lc_f536c0
	ld a, (0x31e4:16)
	inc 1,A
	cp a, (0x0433:16)
	jr nz, .Lc_f536c0
	or (0x328d:16), 0x3f
AccPitch_UpdateCheck:
.Lc_f536c0:
	bit 7, (0x33d4:16)
	jr nz, AccPitch_FinalReturn
	bit 7, (0x31e5:16)
	jr z, AccPitch_FinalReturn
	ld a, (0x31e4:16)
	inc 1,A
	cp a, (0x0433:16)
	jr nz, AccPitch_FinalReturn
	or (0x328d:16), 0x3f
AccPitch_FinalReturn:
	ret

AccChord_ProcessKeyChanges:
	bit 0, (0x3261:16)
	jr z, .Lc_f5370b
	bit 0, (0x3262:16)
	jr nz, .Lc_f5370b
	xor A,A
	ld (0x326e:16), a
	ld (0x326d:16), a
	and (0x328b:16), 0xc0
	and (0x326f:16), 0xfd
	and (0x328a:16), 0xc0
	or (0x326f:16), 0x01
	calr AccChannel_SetDirtyIfActive
AccChord_KeyChange0_Done:
.Lc_f5370b:
	bit 1, (0x3261:16)
	jr z, AccChord_KeyChange1_Done
	bit 1, (0x3262:16)
	jr nz, AccChord_KeyChange1_Done
	xor A,A
	ld (0x326e:16), a
	ld (0x326d:16), a
	and (0x328b:16), 0xc0
	and (0x326f:16), 0xfe
	and (0x328a:16), 0xc0
	or (0x326f:16), 0x02
	calr AccChannel_SetDirtyIfActive
AccChord_KeyChange1_Done:
	ret

AccChord_ResolveVoiceAndDispatch:
	ld	a, (12873:16)
	ld	w, (12939:16)
	and	w, 63
	jr	z, 4
	ld	a, (12875:16)
AccChord_CheckRange:
	cp	a, 128
	jrl	c, 335
	cp	a, 240
	jr	c, 6
	ld	a, (13141:16)
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
	ld a, (0x323c:16)
	cp a, (0x3240:16)
	jr nz, .Lc_f538b4
	ld a, (0x323e:16)
	cp a, (0x3242:16)
	jr z, .Lc_f538b9
AccChord_SetDirtyBit5:
.Lc_f538b4:
	or (0x3257:16), 0x20
AccChord_CheckZeroChord:
.Lc_f538b9:
	cp (0x3240:16), 0x00
	jr nz, AccChord_CompareDone
	and (0x3257:16), 0xdf
AccChord_CompareDone:
	ret

AccentVoice_DetectAndMarkChange:
	ld a, (0x3269:16)
	cp a, (0x326a:16)
	jr z, AccentVoice_UpdateParamIndex
	ld a, (0x3278:16)
	orda8 a, (0x3279)
	and A,0x3f
	jr nz, AccentVoice_UpdateParamIndex
	cp (0x3249:16), 0xf0
	jr nc, AccentVoice_UpdateParamIndex
	cp (0x3249:16), 0x80
	jr nc, AccentVoice_UpdateParamIndex
	bit 0, (0x3265:16)
	jr z, .Lc_f538fe
	ld a, (0x3276:16)
	orda8 a, (0x3277)
	and A,0x3f
	jr nz, AccentVoice_UpdateParamIndex
AccentVoice_CheckModeChange:
.Lc_f538fe:
	ld a, (0x3269:16)
	and A,0x03
	cp a, (0x329c:16)
	jr z, AccentVoice_UpdateParamIndex
	or (0x3271:16), 0x01
AccentVoice_UpdateParamIndex:
	ld	a, (12905:16)
	and	a, 3
	ld	(12958:16), a
	ret
AccVoice_ResolveParamAddr:
	push xwa
	push xix
	ld xiy, RhythmTiming_OffsetTable
	cp a, 0x1d
	jr ule, AccVoice_ComputeParamOffset
	xor a, a

AccVoice_ComputeParamOffset:
	extz	wa
	sla	wa, 2
	extz	xwa
	add	xiy, xwa
	ld	xiy, (xiy)
	ld	a, (12874:16)
	extz	wa
	sla	wa, 2
	ld	xix, 16070995
	ld_rrl	xix, xix, wa
	add	xiy, xix
	add	xiy, 96
	pop	xix
	pop	xwa
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
	cp (0x3249:16), 0x80
	jr nc, AccVoice_PatchFromDirect
	ld xiy, (0x3232:16)
	calr AccStyle_ReadVoiceParam
	ld (0x3253:16), w
	jr t, AccVoice_StorePatchAndLookup
AccVoice_PatchFromDirect:
	ld	a, (12873:16)
	and	a, 127
	calr	43
AccVoice_StorePatchAndLookup:
	ld	(1075:16), a
	ld	xhl, 14969758
	sla	a, 1
	ld_rr8w	wa, xhl, a
	ld	(12767:16), wa
	ret
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

	ld xix, 12714

	ldw bc, 0x31

	ldir85

	push xwa

	push xix

	ld xix, 12714

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

	ld xix, 12714

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x20

	ld xix, 12721

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x28

	ld xix, 12728

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x30

	ld xix, 12735

	lds bc, 7

	ldir85

	ld xiy, xhl

	add xiy, 0x38

	ld xix, 12742

	lds bc, 7

	ldir85

	pop xiy

	ret



AccTuning_LoadAndApplyMaster:
	push xiy

	add xhl, 0x248

	add xiy, xhl

	ld xix, 12714

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

	ld xix, 12721

	lds bc, 7

	ldir85

	ld xix, 12723

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

	ld xix, 12728

	lds bc, 7

	ldir85

	ld xix, 12730

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

	ld xix, 12735

	lds bc, 7

	ldir85

	ld xix, 12737

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

	ld xix, 12742

	lds bc, 7

	ldir85

	ld xix, 12744

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
	bit 0, (0x31e7:16)
	jr nz, Rhythm_ProcessAllDone
	call AccVoice_LoadAllChannelParams
Rhythm_ProcessAllDone:
	ret

RhythmPart_CopyData:
	ldw bc, 0x19

	ld xiy, 12664

	ld xix, 12689

	ldir85

	ret



RhythmPart1_ProcessAccentData:
	bit 0, (0x31e7:16)
	jr z, .Lc_f53b8c
	call AccentData_ComparePart1
RhythmPart1_CheckAccentData:
.Lc_f53b8c:
	ld a, (0x3290:16)
	and A,0x03
	jr z, RhythmPart1_WriteDone
	ld e, (0x31aa:16)
	ld d, (0x31ab:16)
	bit 0, (0x31e7:16)
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

	calr 146

	calr 65

	stb_dri E, 0x07, 0xec, 0xf4

	calr 135

	stb_dri D, 0x07, 0xec, 0xf4

	ldb w, 0x0

	calr 125

	stb_dri W, 0x07, 0xec, 0xf4

	calr 117

	stb_dri W, 0x07, 0xec, 0xf4

	calr 109

	stb_dri W, 0x07, 0xec, 0xf4

	calr 101

	ld (xhl + 4), iy

	ld xhl, 12664

	ld (xhl), e

	ld (xhl + 1), d



RhythmPart1_WriteDone:
	.byte 0xc1, 0x90, 0x32, 0x3c, 0xfc	; anddi8 (0x332c), 252 (v7 patched)

	.byte 0x1d, 0x00, 0xc6, 0xf5	; call AccVoiceReg_WritePart1 (v7 addr)

	ret



RhythmAccent_CopyAndUpdateRingBuf:
	pushw	de
	pushw	wa
	ld	a, (12880:16)
	ld	(13202:16), a
	calr	3
	popw	wa
	popw	de
	ret
RhythmAccent_UpdateRingBufPosition:
	ld a, (0x3392:16)
	ei 0x06
	sub a, (0x0464:16)
	jr ugt, RhythmAccent_StorePosition
	ldb A, 0x01
	ld (0x3392:16), a
	cp (0x0462:16), 0x00
	jr z, RhythmAccent_AddAndCompare
	xor A,A
	jr t, RhythmAccent_AddAndCompare
RhythmAccent_StorePosition:
	ld	(13202:16), a
RhythmAccent_AddAndCompare:
	ld	w, (1122:16)
	add	a, w
	st_rrb	a, xhl, iy
	calr	15
	ld	w, (13018:16)
	cp	a, w
	jr	nc, 4
	ld	(13018:16), a
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
	bit 0, (0x31e7:16)
	jr z, .Lc_f53c6b
	call AccentData_ComparePart2
RhythmPart2_LoadAndStore:
.Lc_f53c6b:
	bit 2, (0x3290:16)
	ld e, (0x31b1:16)
	ld d, (0x31b2:16)
	ld a, (0x31b3:16)
	ld (0x3393:16), a
	ld a, (0x31b4:16)
	ld (0x3394:16), a
	ld a, (0x31b5:16)
	ld (0x3395:16), a
	ld a, (0x31b6:16)
	ld (0x3227:16), a
	ld a, (0x31b7:16)
	ld (0x322b:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x31e7:16)
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
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x0000317d
	calr AccVoiceReg_StoreParamRecord
RhythmPart2_WriteDone:
.Lc_f53d08:
	and (0x3290:16), 0xfb
	call AccVoiceReg_WritePart2

	ret



AccVoiceReg_StoreParamRecord:
	ld	(xhl), e
	ld	(xhl+1), d
	ld	a, (13203:16)
	ld	(xhl+2), a
	ld	a, (13204:16)
	ld	(xhl+3), a
	ld	a, (13205:16)
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
	bit 0, (0x31e7:16)
	jr z, .Lc_f53d43
	call AccentData_ComparePart3
RhythmPart3_LoadAndStore:
.Lc_f53d43:
	bit 3, (0x3290:16)
	ld e, (0x31b8:16)
	ld d, (0x31b9:16)
	ld a, (0x31ba:16)
	ld (0x3393:16), a
	ld a, (0x31bb:16)
	ld (0x3394:16), a
	ld a, (0x31bc:16)
	ld (0x3395:16), a
	ld a, (0x31bd:16)
	ld (0x3228:16), a
	ld a, (0x31be:16)
	ld (0x322c:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x31e7:16)
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
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x00003182
	calr AccVoiceReg_StoreParamRecord
RhythmPart3_WriteDone:
.Lc_f53de0:
	and (0x3290:16), 0xf7
	call AccVoiceReg_WritePart3

	ret



AccVoice_LoadRhythmParams_Part4:
	bit 0, (0x31e7:16)
	jr z, .Lc_f53df4
	call AccentData_ComparePart4
RhythmPart4_LoadAndStore:
.Lc_f53df4:
	bit 4, (0x3290:16)
	ld e, (0x31bf:16)
	ld d, (0x31c0:16)
	ld a, (0x31c1:16)
	ld (0x3393:16), a
	ld a, (0x31c2:16)
	ld (0x3394:16), a
	ld a, (0x31c3:16)
	ld (0x3395:16), a
	ld a, (0x31c4:16)
	ld (0x3229:16), a
	ld a, (0x31c5:16)
	ld (0x322d:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x31e7:16)
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
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x00003187
	calr AccVoiceReg_StoreParamRecord
RhythmPart4_WriteDone:
.Lc_f53e91:
	and (0x3290:16), 0xef
	call AccVoiceReg_WritePart4

	ret



AccVoice_LoadRhythmParams_Part5:
	bit 0, (0x31e7:16)
	jr z, .Lc_f53ea5
	call AccentData_ComparePart5
RhythmPart5_LoadAndStore:
.Lc_f53ea5:
	bit 5, (0x3290:16)
	ld e, (0x31c6:16)
	ld d, (0x31c7:16)
	ld a, (0x31c8:16)
	ld (0x3393:16), a
	ld a, (0x31c9:16)
	ld (0x3394:16), a
	ld a, (0x31ca:16)
	ld (0x3395:16), a
	ld a, (0x31cb:16)
	ld (0x322a:16), a
	ld a, (0x31cc:16)
	ld (0x322e:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x31e7:16)
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
	ld a, (0x3393:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	stb_dri a, 0x07, 0xec, 0xf4
	calr RingBuf_AdvanceIndex
	ld (XHL+0x04),IY
	ld XHL,0x0000318c
	calr AccVoiceReg_StoreParamRecord
RhythmPart5_WriteDone:
.Lc_f53f42:
	and (0x3290:16), 0xdf
	call AccVoiceReg_WritePart5

	ret



AccompVoice_BulkReadRegisters:
	ldb	a, 0
	ld	xhl, 12280
	xor	iy, iy
BulkRead_Loop1_6Byte:
	st_rrb	a, xhl, iy
	add	iy, 6
	cp	iy, 48
	jr	c, -15	; -> 0xF53F55
	ld	xhl, 12328
	xor	iy, iy
BulkRead_Loop2_6Byte:
	st_rrb	a, xhl, iy
	add	iy, 6
	cp	iy, 48
	jr	c, -15	; -> 0xF53F6B
	ld	xhl, 12376
	xor	iy, iy
BulkRead_Loop3_9Byte:
	st_rrb	a, xhl, iy
	add	iy, 9
	cp	iy, 72
	jr	c, -15	; -> 0xF53F81
	ld	xhl, 12448
	xor	iy, iy
BulkRead_Loop4_9Byte:
	st_rrb	a, xhl, iy
	add	iy, 9
	cp	iy, 72
	jr	c, -15	; -> 0xF53F97
	ld	xhl, 12520
	xor	iy, iy
BulkRead_Loop5_9Byte:
	st_rrb	a, xhl, iy
	add	iy, 9
	cp	iy, 72
	jr	c, -15	; -> 0xF53FAD
	ld	xhl, 12592
	xor	iy, iy
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
	ld	(13126:16), a
	ld	(13127:16), w
	ld	(13128:16), e
	ld	a, (13126:16)
	call	16076951
	ld	a, (13127:16)
	call	16076951
	ld	a, (13128:16)
	call	16076951
	ret
Rhythm_SendChanPressure:
	ldb	a, 208
	ldb	w, 3
	ldb	e, 0
	calr	65490
	ldb	a, 0
	ld	(12947:16), a
	ld	(12948:16), a
	ld	(12949:16), a
	ld	(12950:16), a
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
	cp xwa, (0x31db:16)
	jr z, RhythmROM_InvalidIncrement
	jr t, RhythmROM_CheckDone
RhythmROM_InvalidIncrement:
	ldb	c, 1
	ld	wa, (13240:16)
	add	wa, 1
	ld	(13240:16), wa
	cps	wa, 0
	jr	nz, 11
	ldb	a, 238
	ld	(58134:16), a
	ld	(58136:16), 64
RhythmROM_CheckDone:
	ret

RhythmROM_BytecodeBlock4:
	ld	xwa, 1024
	push	xwa
	call	16713379
	add	xsp, 4
	ld	(13504:16), xhl
	ld	xwa, 4096
	push	xwa
	call	16713379
	add	xsp, 4
	ld	xwa, xhl
	ld	xwa, xwa
	push	xwa
	call	16712469
	add	xsp, 4
	ld	xwa, (13504:16)
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
	and (0x3290:16), 0xfc
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
	and (0x3290:16), 0xfb
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
	and (0x3290:16), 0xf7
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
	and (0x3290:16), 0xef
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
	and (0x3290:16), 0xdf
AccentData_Part5_Done:
	ret

RhythmROM_ValidateHeader:
	xor	xwa, xwa
	ld	(12763:16), xwa
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
	ld	(12763:16), xwa
RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	xor XHL,XHL
	ld L,W
	and L,0x7f
	srl L, 0x02
	cp (0x324a:16), 0x00
	jrl nz, AccPatch_ChIdx1_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx0_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx0_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	63249
	ld	(13000:16), wa
	ldb	a, 19
	calr	63240
	ld	(13002:16), wa
	ldb	a, 20
	calr	63231
	ld	(13004:16), wa
	ldb	a, 21
	calr	63222
	ld	(13006:16), wa
	ldb	a, 22
	calr	63213
	ld	(13008:16), wa
	ldb	a, 23
	calr	63204
	ld	(13010:16), wa
	jrl	1293
AccPatch_ChIdx0_Bank2:
	ldb	a, 24
	calr	63192
	ld	(13000:16), wa
	ldb	a, 25
	calr	63183
	ld	(13002:16), wa
	ldb	a, 26
	calr	63174
	ld	(13004:16), wa
	ldb	a, 27
	calr	63165
	ld	(13006:16), wa
	ldb	a, 28
	calr	63156
	ld	(13008:16), wa
	ldb	a, 29
	calr	63147
	ld	(13010:16), wa
	jrl	1236
AccPatch_ChIdx1_Entry:
	cp (0x324a:16), 0x01
	jrl nz, AccPatch_ChIdx2_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx1_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx1_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	63062
	ld	(13000:16), wa
	ldb	a, 19
	calr	63053
	ld	(13002:16), wa
	ldb	a, 20
	calr	63044
	ld	(13004:16), wa
	ldb	a, 21
	calr	63035
	ld	(13006:16), wa
	ldb	a, 22
	calr	63026
	ld	(13008:16), wa
	ldb	a, 23
	calr	63017
	ld	(13010:16), wa
	jrl	1106
AccPatch_ChIdx1_Bank2:
	ldb	a, 24
	calr	63005
	ld	(13000:16), wa
	ldb	a, 25
	calr	62996
	ld	(13002:16), wa
	ldb	a, 26
	calr	62987
	ld	(13004:16), wa
	ldb	a, 27
	calr	62978
	ld	(13006:16), wa
	ldb	a, 28
	calr	62969
	ld	(13008:16), wa
	ldb	a, 29
	calr	62960
	ld	(13010:16), wa
	jrl	1049
AccPatch_ChIdx2_Entry:
	cp (0x324a:16), 0x02
	jrl nz, AccPatch_ChIdx3_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx2_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx2_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62875
	ld	(13000:16), wa
	ldb	a, 19
	calr	62866
	ld	(13002:16), wa
	ldb	a, 20
	calr	62857
	ld	(13004:16), wa
	ldb	a, 21
	calr	62848
	ld	(13006:16), wa
	ldb	a, 22
	calr	62839
	ld	(13008:16), wa
	ldb	a, 23
	calr	62830
	ld	(13010:16), wa
	jrl	919
AccPatch_ChIdx2_Bank2:
	ldb	a, 24
	calr	62818
	ld	(13000:16), wa
	ldb	a, 25
	calr	62809
	ld	(13002:16), wa
	ldb	a, 26
	calr	62800
	ld	(13004:16), wa
	ldb	a, 27
	calr	62791
	ld	(13006:16), wa
	ldb	a, 28
	calr	62782
	ld	(13008:16), wa
	ldb	a, 29
	calr	62773
	ld	(13010:16), wa
	jrl	862
AccPatch_ChIdx3_Entry:
	cp (0x324a:16), 0x03
	jrl nz, AccPatch_ChIdx4_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx3_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx3_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62688
	ld	(13000:16), wa
	ldb	a, 19
	calr	62679
	ld	(13002:16), wa
	ldb	a, 20
	calr	62670
	ld	(13004:16), wa
	ldb	a, 21
	calr	62661
	ld	(13006:16), wa
	ldb	a, 22
	calr	62652
	ld	(13008:16), wa
	ldb	a, 23
	calr	62643
	ld	(13010:16), wa
	jrl	732
AccPatch_ChIdx3_Bank2:
	ldb	a, 24
	calr	62631
	ld	(13000:16), wa
	ldb	a, 25
	calr	62622
	ld	(13002:16), wa
	ldb	a, 26
	calr	62613
	ld	(13004:16), wa
	ldb	a, 27
	calr	62604
	ld	(13006:16), wa
	ldb	a, 28
	calr	62595
	ld	(13008:16), wa
	ldb	a, 29
	calr	62586
	ld	(13010:16), wa
	jrl	675
AccPatch_ChIdx4_Entry:
	cp (0x324a:16), 0x04
	jrl nz, AccPatch_ChIdx5_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx4_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx4_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62501
	ld	(13000:16), wa
	ldb	a, 19
	calr	62492
	ld	(13002:16), wa
	ldb	a, 20
	calr	62483
	ld	(13004:16), wa
	ldb	a, 21
	calr	62474
	ld	(13006:16), wa
	ldb	a, 22
	calr	62465
	ld	(13008:16), wa
	ldb	a, 23
	calr	62456
	ld	(13010:16), wa
	jrl	545
AccPatch_ChIdx4_Bank2:
	ldb	a, 24
	calr	62444
	ld	(13000:16), wa
	ldb	a, 25
	calr	62435
	ld	(13002:16), wa
	ldb	a, 26
	calr	62426
	ld	(13004:16), wa
	ldb	a, 27
	calr	62417
	ld	(13006:16), wa
	ldb	a, 28
	calr	62408
	ld	(13008:16), wa
	ldb	a, 29
	calr	62399
	ld	(13010:16), wa
	jrl	488
AccPatch_ChIdx5_Entry:
	cp (0x324a:16), 0x05
	jrl nz, AccPatch_ChIdx6_Entry
	cps l, 0
	jr nz, AccPatch_ChIdx5_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx5_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62314
	ld	(13000:16), wa
	ldb	a, 19
	calr	62305
	ld	(13002:16), wa
	ldb	a, 20
	calr	62296
	ld	(13004:16), wa
	ldb	a, 21
	calr	62287
	ld	(13006:16), wa
	ldb	a, 22
	calr	62278
	ld	(13008:16), wa
	ldb	a, 23
	calr	62269
	ld	(13010:16), wa
	jrl	358
AccPatch_ChIdx5_Bank2:
	ldb	a, 24
	calr	62257
	ld	(13000:16), wa
	ldb	a, 25
	calr	62248
	ld	(13002:16), wa
	ldb	a, 26
	calr	62239
	ld	(13004:16), wa
	ldb	a, 27
	calr	62230
	ld	(13006:16), wa
	ldb	a, 28
	calr	62221
	ld	(13008:16), wa
	ldb	a, 29
	calr	62212
	ld	(13010:16), wa
	jrl	301
AccPatch_ChIdx6_Entry:
	cp (0x324a:16), 0x06
	jrl nz, AccPatch_ChIdxDefault_Bank0
	cps l, 0
	jr nz, AccPatch_ChIdx6_Bank1
	ldb A, 0x0c
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ldb A, 0x0d
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ldb A, 0x0e
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ldb A, 0x0f
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ldb A, 0x10
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ldb A, 0x11
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx6_Bank1:
	cps	l, 1
	jr	nz, 57
	ldb	a, 18
	calr	62127
	ld	(13000:16), wa
	ldb	a, 19
	calr	62118
	ld	(13002:16), wa
	ldb	a, 20
	calr	62109
	ld	(13004:16), wa
	ldb	a, 21
	calr	62100
	ld	(13006:16), wa
	ldb	a, 22
	calr	62091
	ld	(13008:16), wa
	ldb	a, 23
	calr	62082
	ld	(13010:16), wa
	jrl	171
AccPatch_ChIdx6_Bank2:
	ldb	a, 24
	calr	62070
	ld	(13000:16), wa
	ldb	a, 25
	calr	62061
	ld	(13002:16), wa
	ldb	a, 26
	calr	62052
	ld	(13004:16), wa
	ldb	a, 27
	calr	62043
	ld	(13006:16), wa
	ldb	a, 28
	calr	62034
	ld	(13008:16), wa
	ldb	a, 29
	calr	62025
	ld	(13010:16), wa
	jrl	114
AccPatch_ChIdxDefault_Bank0:
	cps	l, 0
	jr	nz, 56
	ldb	a, 12
	calr	62009
	ld	(13000:16), wa
	ldb	a, 13
	calr	62000
	ld	(13002:16), wa
	ldb	a, 14
	calr	61991
	ld	(13004:16), wa
	ldb	a, 15
	calr	61982
	ld	(13006:16), wa
	ldb	a, 16
	calr	61973
	ld	(13008:16), wa
	ldb	a, 17
	calr	61964
	ld	(13010:16), wa
	jr	54
AccPatch_ChIdxDefault_Bank1:
	ldb	a, 18
	calr	61953
	ld	(13000:16), wa
	ldb	a, 19
	calr	61944
	ld	(13002:16), wa
	ldb	a, 20
	calr	61935
	ld	(13004:16), wa
	ldb	a, 21
	calr	61926
	ld	(13006:16), wa
	ldb	a, 22
	calr	61917
	ld	(13008:16), wa
	ldb	a, 23
	calr	61908
	ld	(13010:16), wa
AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
