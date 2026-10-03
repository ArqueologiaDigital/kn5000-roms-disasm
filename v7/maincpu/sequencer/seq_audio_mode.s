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
	call AudioMode_CheckAndUpdateStereo_Helper
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
; -----------------------------------------------------------------------------
; AccPedal_LoadFlagFromStyleMem -- bit 0 of RAM 0x32C7 := bit 0 of the byte at
; RAM 0x094810.  Preserves WA and XIY.  (v10: the same routine on 0x3363.)
; 0x094800 is the RAM copy of the composer factory user-style memory
; (technics-docs memory-map.md), so the byte read is offset 0x10 of it.
; Sibling of AccPedal_SetFlag13155 below, which sets the same bit.
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v7 0xF533A5 -- one
; absolute hit, at 0xF62013, is the operand bytes of `cp iy,(0x33a5)`; no
; calr/jr/jrl lands here.  Was `.byte` until 2026-09-25
; (notes/sequi-2026-09-25/reframe-v7-seq_audio_mode.log).
; -----------------------------------------------------------------------------
AccPedal_LoadFlagFromStyleMem:
	pushw wa
	push xiy
	and (0x32c7:16), 0xfe
	ld xiy, RHYTHM_PATTERN_BUF_A
	add xiy, 16
	ld a, (xiy)
	bit 0, a
	jr z, AccPedal_LoadFlagFromStyleMem_Done
	or (0x32c7:16), 0x01
AccPedal_LoadFlagFromStyleMem_Done:
	pop xiy
	popw	wa
	ret	
AccPedal_SetFlag13155:
	pushw wa

	push xiy
	or (0x32c7:16), 0x01


	pop xiy

	popw wa

	ret



; -----------------------------------------------------------------------------
; AccPedal_BankBaseTableCopy -- 7 x 32-bit addresses, value-for-value the same
; as AccVoice_BankBaseTable entries 1-7 (Custom Data Flash window).  Extent:
; to AccPedal_ProcessAllChanges, a called routine (28 bytes = 7 longs).
; NO READER FOUND: scripts/analysis/sequi_find_refs.py v7 --window 64 0xF533D0
; -- the hits are the call to AccPedal_ProcessAllChanges (+28) and operand
; bytes of unrelated instructions.  Kept as data: 0x98 at +5 does not decode.
; -----------------------------------------------------------------------------
AccPedal_BankBaseTableCopy:
	.long 0x00300000
	.long 0x00319800
	.long 0x00330000
	.long 0x00349800
	.long 0x00360000
	.long 0x00379800
	.long 0x00390000

AccPedal_ProcessAllChanges:
	xor WA,WA
	ld XHL,AccStyle_ApplyExt_SkipClamp_Table
	ld a, (0x0433:16)
	bit	0, (xhl+wa)
	jrl z, AccPedal_ReadBankAndReturn
	xor a, a
	bit 0, (0x325f:16)
	jr z, AccPedal_CheckBit1Left
	or a, 64
AccPedal_CheckBit1Left:
	bit 1, (0x325f:16)
	jr z, AccPedal_CheckBit0Right
	or a, 128
AccPedal_CheckBit0Right:
	bit 0, (0x3261:16)
	jr z, AccPedal_CheckBit1Right
	or a, 16
AccPedal_CheckBit1Right:
	bit 1, (0x3261:16)
	jr z, AccPedal_CheckBit0Aux
	or a, 32
AccPedal_CheckBit0Aux:
	bit 0, (0x3263:16)
	jr z, AccPedal_CheckBit1Aux
	or a, 4
AccPedal_CheckBit1Aux:
	bit 1, (0x3263:16)
	jr z, AccPedal_ApplyChangeMask
	or a, 8
AccPedal_ApplyChangeMask:
	cp a, 0:i3
	jr z, AccPedal_CheckAuxBit2
	ld w, a
	xor w, 0xff
	and (0xfc5f:16), w
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	calr Rhythm_QueuePartChangeEvent

AccPedal_CheckAuxBit2:
	bit 2, (0x3263:16)
	jr z, AccPedal_ClearAllPedalFlags
	and (0xfc60:16), 0xfb
	ld e, 72:opc
	ld d, 5:opc
	ld w, 0:opc
	ld a, 0:opc
	calr Rhythm_QueuePartChangeEvent
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
	ld XHL,AccStyle_ApplyExt_SkipClamp_Table
	ld a, (0x0433:16)
	ld	a, (xhl+wa)
	bit 0, (0x31e7:16)
	jr nz, AccVoice_StoreBankAssign
	ld a, 0:opc
AccVoice_StoreBankAssign:
	ld	(12774:16), a
	ret
AccChannel_CompareAndMarkDirty:
	ld a, (0x3278:16)
	or a, (0x3279:16)
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
; -----------------------------------------------------------------------------
; AccChannel_StoreStateIfChanged -- the conditional form of
; AccChannel_StoreCurrentState (just above): when RAM 0x3259 differs from
; 0x325A, or it is below 0x80 and the low 3 bits of 0x325B and 0x325C differ,
; copy 0x3259 -> 0x324B and 0x325B -> 0x324C.  (v10: 0x32F5.. / 0x32E7..;
; the `and w` masks apply to W, not to the A that is stored.)
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v7 0xF534E8 -> none.
; Was `.byte` until 2026-09-25; decodes cleanly, both decoders agree.
; -----------------------------------------------------------------------------
AccChannel_StoreStateIfChanged:
	ld a, (0x3259:16)
	cp a, (0x325a:16)
	jr nz, AccChannel_StoreStateIfChanged_Store
	cp a, 128
	jr nc, AccChannel_StoreStateIfChanged_Return
	ld a, (0x325b:16)
	and a, 127
	and a, 7
	ld w, (0x325c:16)
	and w, 127
	and w, 7
	cp a, w
	jr z, AccChannel_StoreStateIfChanged_Return
AccChannel_StoreStateIfChanged_Store:
	ld a, (0x3259:16)
	ld (0x324b:16), a
	ld a, (0x325b:16)
	and w, 127
	and w, 7
	ld (0x324c:16), a
AccChannel_StoreStateIfChanged_Return:
	ret
AccChannel_SetDirtyIfActive:
	ld wa, (0x3247:16)
	and W,0x07
	cp w, 0:i3
	jr z, AccChannel_SetDirtyDone
	or (0x328a:16), 0x3f
AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	ld a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x327c:16)
	and A,0x3f
	jr z, AccChannel_ActivityCheckDone
	cp (0x3259:16), 0x80
	jr c, AccChannel_ActivityCheckDone
	or (0x328a:16), 0x3f
AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	ld a, (0x0433:16)
	cp a, 1:i3
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
	or a, (0x3279:16)
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
	jr	z, AccChord_CheckRange
	ld	a, (12875:16)
AccChord_CheckRange:
	cp	a, 128
	jrl	c, AccChord_NullRet
	cp	a, 240
	jr	c, AccChord_MaskAndContinue
	ld	a, (13141:16)
	jr	AccChord_DispatchVoiceChange
AccChord_MaskAndContinue:
	and a, 0x7f

AccChord_DispatchVoiceChange:
	calr AccPatch_SetVoiceParam
	ld c, a
	xor a, a
	bit 0, (0x326e:16)
	jr z, AccChord_CheckVoiceBit2
	cp c, (0x32c8:16)
	jr z, AccChord_CheckVoiceBit2
	and (0x326e:16), 0xfe
	and (0x328b:16), 0xc0
	and (0x3263:16), 0xfe
	or a, 4
AccChord_CheckVoiceBit2:
	bit 2, (0x326e:16)
	jr z, AccChord_CheckLeftPedal0
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 0, 0x03, 0xec, 0xe4
	jr z, AccChord_CheckLeftPedal0
	and (0x326e:16), 0xfb
	and (0x328b:16), 0xc0
	and (0x3263:16), 0xfd
	or a, 8
AccChord_CheckLeftPedal0:
	bit 0, (0x326d:16)
	jr z, AccChord_CheckLeftPedal1
	cp c, (0x32cc:16)
	jr z, AccChord_CheckLeftPedal1
	and (0x326d:16), 0xfe
	and (0x328b:16), 0xc0
	and (0x325f:16), 0xfe
	or a, 64
AccChord_CheckLeftPedal1:
	bit 1, (0x326d:16)
	jr z, AccChord_CheckKeyChange0
	cp c, (0x32ce:16)
	jr z, AccChord_CheckKeyChange0
	and (0x326d:16), 0xfd
	and (0x328b:16), 0xc0
	and (0x325f:16), 0xfd
	or a, 128
AccChord_CheckKeyChange0:
	bit 0, (0x326f:16)
	jr z, RhythmPart_ProcessBit0
	cp c, (0x32d0:16)
	jr z, RhythmPart_ProcessBit0
	and (0x326f:16), 0xfe
	and (0x3261:16), 0xfe
	or a, 16
	bit 0, (0x3270:16)
	jr nz, RhythmPart_ProcessBit0
	and (0x328b:16), 0xc0
RhythmPart_ProcessBit0:
	bit 1, (0x326f:16)
	jr z, RhythmPart_ProcessBit1
	cp c, (0x32d2:16)
	jr z, RhythmPart_ProcessBit1
	and (0x326f:16), 0xfd
	and (0x3261:16), 0xfd
	or a, 32
	bit 0, (0x3270:16)
	jr nz, RhythmPart_ProcessBit1
	and (0x328b:16), 0xc0
RhythmPart_ProcessBit1:
	cp a, 0:i3
	jr z, AccChord_CheckExtraDirtyBit3
	ld w, 0x0:opc
	xor a, 0xff
	and (0xfc5f:16), a
	ld a, 0x0:opc
	ld e, 0x48:opc
	ld d, 0x5:opc
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckExtraDirtyBit3:
	bit 3, (0x326e:16)
	jr z, AccChord_CheckPitchDirty
	cp c, (0x32ca:16)
	jr z, AccChord_CheckPitchDirty
	and (0x326e:16), 0xf7
	and (0x328b:16), 0xc0
	and (0x3263:16), 0xfb
	and (0xfc5f:16), 0xfb
	ld a, 0:opc
	ld w, 0:opc
	ld e, 72:opc
	ld d, 5:opc
	calr Rhythm_QueuePartChangeEvent
AccChord_CheckPitchDirty:
	ld a, (0x328d:16)
	and a, 63
	jr z, AccChord_NullRet
	bit 0, (0x325f:16)
	jr z, AccChord_CheckPitchLeftPedal1
	cp c, (0x32cc:16)
	jr z, AccChord_NullRet
	and (0x328d:16), 0xc0
	jr AccChord_NullRet
AccChord_CheckPitchLeftPedal1:
	bit 1, (0x325f:16)
	jr z, AccChord_NullRet
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 0, 0x03, 0xec, 0xe4
	jr z, AccChord_NullRet
	and (0x328d:16), 0xc0
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
	or a, (0x3279:16)
	and A,0x3f
	jr nz, AccentVoice_UpdateParamIndex
	cp (0x3249:16), 0xf0
	jr nc, AccentVoice_UpdateParamIndex
	cp (0x3249:16), 0x80
	jr nc, AccentVoice_UpdateParamIndex
	bit 0, (0x3265:16)
	jr z, .Lc_f538fe
	ld a, (0x3276:16)
	or a, (0x3277:16)
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
	ld	xix, AccVoice_BankBaseTable
	ld	xix, (xix+wa)
	add	xiy, xix
	add	xiy, 96
	pop	xix
	pop	xwa
	ret
; -----------------------------------------------------------------------------
; AccVoice_BankBaseTable -- 8 x 32-bit base addresses indexed by RAM byte
; 0x324A (v10: 0x32E6).
; Reader: AccVoice_ComputeParamOffset (0xF5392A, the tail of
; AccVoice_ResolveParamAddr 0xF5391C): `ld xix, AccVoice_BankBaseTable`,
; `ld xix, (xix+wa)` with wa = (0x324A)*4; the entry is added to the
; 32-bit offset loaded from the RhythmTiming_OffsetTable entry (A clamped to
; 0..0x1D) plus 0x60, and the sum returned in XIY -- each entry is the base
; of a bank those offsets index into.
; Stride 4 (`sla wa, 2`); 8 entries = 32 bytes, to AccVoice_ComputeChannelIndex.
; Entry 0 is RAM 0x094800, the RAM copy of the composer factory user-style
; memory (technics-docs memory-map.md); entries 1-7 lie in the Custom Data
; Flash window 0x300000-0x3FFFFF.  Which style slot each bank index stands
; for is decided by the writers of the index byte, not examined here.
; -----------------------------------------------------------------------------
AccVoice_BankBaseTable:
	.long 0x00094800
	.long 0x00300000
	.long 0x00319800
	.long 0x00330000
	.long 0x00349800
	.long 0x00360000
	.long 0x00379800
	.long 0x00390000

AccVoice_ComputeChannelIndex:
	and h, 0x7
	sla h, 1
	xor w, w
	sla wa, 2
	xor l, l
	add hl, wa
	ld xiy, RhythmROM_BankProgramLocators
	ld	wa, (xiy+hl)
	add hl, 0x2
	ld	iy, (xiy+hl)
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
	calr	AccPatch_SetVoiceParam
AccVoice_StorePatchAndLookup:
	ld	(1075:16), a
	ld	xhl, AccVoice_LookupTableAddress_Table
	sla	a, 1
	ld	wa, (xhl+a)
	ld	(12767:16), wa
	ret
AccStyle_ReadVoiceParam:
	ld	w, (xiy+986)
	ld	a, (xiy+976)
	ld xhl, AccTone_LookupByProgram_Table
	ld	a, (xhl+a)
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
	ld xhl, AccTone_LookupByProgram_Table
	ld	a, (xhl+a)
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

	ld	(xix+wa), 0x40

	ldw wa, 0x10

	ld	(xix+wa), 0x0c

	ldw wa, 0x17

	ld	(xix+wa), 0x74

	ldw wa, 0x1e

	ld	(xix+wa), 0x40

	pop xix

	pop xwa

	pop xiy

	call	AccTuning_LoadFromROM

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

	ld bc, 7:i3

	ldir85

	ld xiy, xhl

	add xiy, 0x20

	ld xix, 12721

	ld bc, 7:i3

	ldir85

	ld xiy, xhl

	add xiy, 0x28

	ld xix, 12728

	ld bc, 7:i3

	ldir85

	ld xiy, xhl

	add xiy, 0x30

	ld xix, 12735

	ld bc, 7:i3

	ldir85

	ld xiy, xhl

	add xiy, 0x38

	ld xix, 12742

	ld bc, 7:i3

	ldir85

	pop xiy

	ret



AccTuning_LoadAndApplyMaster:
	push xiy

	add xhl, 0x248

	add xiy, xhl

	ld xix, 12714

	ld bc, 7:i3

	ldir85
	call AccTuning_LoadMaster	; call AccTuning_LoadMaster (v7 addr)


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

	ld bc, 7:i3

	ldir85

	ld xix, 12723

	ld (xix), 0x40
	call AccTuning_LoadCoarse	; call AccTuning_LoadCoarse (v7 addr)


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

	ld bc, 7:i3

	ldir85

	ld xix, 12730

	ld (xix), 0xc
	call AccTuning_LoadFine	; call AccTuning_LoadFine (v7 addr)


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

	ld bc, 7:i3

	ldir85

	ld xix, 12737

	ld (xix), 0x74
	call AccTuning_LoadOctave	; call AccTuning_LoadOctave (v7 addr)


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

	ld bc, 7:i3

	ldir85

	ld xix, 12744

	ld (xix), 0x40
	call AccTuning_LoadTranspose	; call AccTuning_LoadTranspose (v7 addr)


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

	ld	(xhl+iy), 0xc0

	calr RingBuf_AdvanceIndex

	calr RhythmAccent_CopyAndUpdateRingBuf

	ld	(xhl+iy), e

	calr RingBuf_AdvanceIndex

	ld	(xhl+iy), d

	ld w, 0x0:opc

	calr RingBuf_AdvanceIndex

	ld	(xhl+iy), w

	calr RingBuf_AdvanceIndex

	ld	(xhl+iy), w

	calr RingBuf_AdvanceIndex

	ld	(xhl+iy), w

	calr RingBuf_AdvanceIndex

	ld (xhl + 4), iy

	ld xhl, 12664

	ld (xhl), e

	ld (xhl + 1), d



RhythmPart1_WriteDone:
	and (0x3290:16), 0xfc	; anddi8 (0x332c), 252 (v7 patched)
	call AccVoiceReg_WritePart1	; call AccVoiceReg_WritePart1 (v7 addr)


	ret



RhythmAccent_CopyAndUpdateRingBuf:
	pushw	de
	pushw	wa
	ld	a, (12880:16)
	ld	(13202:16), a
	calr	RhythmAccent_UpdateRingBufPosition
	popw	wa
	popw	de
	ret
RhythmAccent_UpdateRingBufPosition:
	ld a, (0x3392:16)
	ei 0x06
	sub a, (0x0464:16)
	jr ugt, RhythmAccent_StorePosition
	ld A, 0x01:opc
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
	ld	(xhl+iy), a
	calr	RingBuf_AdvanceIndex
	ld	w, (13018:16)
	cp	a, w
	jr	nc, RhythmAccent_UpdateDone
	ld	(13018:16), a
RhythmAccent_UpdateDone:
	ei 0
	ret

; ============================================================================
; RingBuf_AdvanceIndex - Advance circular buffer index with wraparound
; ============================================================================
; Input:  IY = current index, BC = limit, word at (XHL) = reset value
; Output: IY = incremented index (wrapped if >= limit)
; Called 110+ times, typically in bursts of 5-7 sequential calls while
; storing/loading data parameters through the ring buffer.
; ============================================================================
RingBuf_AdvanceIndex:
	add iy, 0x1
	cp iy, bc
	jr ule, RingBuf_IndexOK
	ld iy, (xhl + 0:8)

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
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	ld	(xhl+iy), a
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
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	ld	(xhl+iy), a
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
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	ld	(xhl+iy), a
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
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x3393:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3394:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3395:16)
	ld	(xhl+iy), a
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
	ld	a, 0:opc
	ld	xhl, 12280
	xor	iy, iy
BulkRead_Loop1_6Byte:
	ld	(xhl+iy), a
	add	iy, 6
	cp	iy, 48
	jr	c, BulkRead_Loop1_6Byte	; -> 0xF53F55
	ld	xhl, 12328
	xor	iy, iy
BulkRead_Loop2_6Byte:
	ld	(xhl+iy), a
	add	iy, 6
	cp	iy, 48
	jr	c, BulkRead_Loop2_6Byte	; -> 0xF53F6B
	ld	xhl, 12376
	xor	iy, iy
BulkRead_Loop3_9Byte:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, BulkRead_Loop3_9Byte	; -> 0xF53F81
	ld	xhl, 12448
	xor	iy, iy
BulkRead_Loop4_9Byte:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, BulkRead_Loop4_9Byte	; -> 0xF53F97
	ld	xhl, 12520
	xor	iy, iy
BulkRead_Loop5_9Byte:
	ld	(xhl+iy), a
	add	iy, 9
	cp	iy, 72
	jr	c, BulkRead_Loop5_9Byte	; -> 0xF53FAD
	ld	xhl, 12592
	xor	iy, iy
BulkRead_Loop6_9Byte:
	ld	(xhl+iy), a
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop6_9Byte
	ret

Rhythm_SendNoteOnMax:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x7f:opc
	calr Rhythm_Send3ByteMsg
	ret

Rhythm_Send3ByteMsg:
	ld	(13126:16), a
	ld	(13127:16), w
	ld	(13128:16), e
	ld	a, (13126:16)
	call	Rhythm_SendByte
	ld	a, (13127:16)
	call	Rhythm_SendByte
	ld	a, (13128:16)
	call	Rhythm_SendByte
	ret
Rhythm_SendChanPressure:
	ld	a, 208:opc
	ld	w, 3:opc
	ld	e, 0:opc
	calr	Rhythm_Send3ByteMsg
	ld	a, 0:opc
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
	ld	a, 152:opc
	and	a, 15
	or	a, 192
	call	Rhythm_SendByte
	call	VoiceParams_LoadFiveSequential
	ld	xix, 12669
	ld	a, 151:opc
	and	a, 15
	or	a, 192
	call	Rhythm_SendByte
	call	VoiceParams_LoadFiveSequential
	ld	xix, 12674
	ld	a, 148:opc
	and	a, 15
	or	a, 192
	call	Rhythm_SendByte
	call	VoiceParams_LoadFiveSequential
	ld	xix, 12679
	ld	a, 149:opc
	and	a, 15
	or	a, 192
	call	Rhythm_SendByte
	call	VoiceParams_LoadFiveSequential
	ld	xix, 12684
	ld	a, 150:opc
	and	a, 15
	or	a, 192
	call	Rhythm_SendByte
	call	VoiceParams_LoadFiveSequential
	ret
VoiceParams_LoadFiveSequential:
	ld A, (xix+)
	call Rhythm_SendByte
	ld A, (xix+)
	call Rhythm_SendByte
	ld A, (xix+)
	call Rhythm_SendByte
	ld A, (xix+)
	call Rhythm_SendByte
	ld A, (xix+)
	call Rhythm_SendByte
	ret

; -----------------------------------------------------------------------------
; Nine small routines between VoiceParams_LoadFiveSequential and
; RhythmROM_CheckValid, `.byte` until 2026-09-25.  Both decoders agree on every
; instruction (notes/sequi-2026-09-25/reframe-v7-seq_audio_mode.log), every
; internal calr lands on an instruction boundary, and the calls reach the
; independently known Rhythm_DispatchNote / Rhythm_DispatchNote_Helper.
; NO CALLER FOUND for the five entry points nothing here calls:
; scripts/analysis/sequi_find_refs.py v7 0xF540B9 0xF54100 0xF54110 0xF54111
; 0xF5411A -> none (one table-data byte match).  v10 carries the same nine.
; -----------------------------------------------------------------------------

; Writes the first two bytes of the first five 7-byte records at RAM 0x31AA,
; 0x31B1, 0x31B8, 0x31BF, 0x31C6 (record 0 byte 0 := 6, the other nine := 0).
; v10 does the same at 0x3246.., where AccTuning_CopyAllPartsFromStyle and
; AccVoice_LoadTuningBlock show these are the 7-byte per-part tuning records.
AccTuning_ResetFiveParts:
	calr AccTuning_ResetFiveParts_Rec0
	calr AccTuning_ResetFiveParts_Rec1
	calr AccTuning_ResetFiveParts_Rec2
	calr AccTuning_ResetFiveParts_Rec3
	calr AccTuning_ResetFiveParts_Rec4
	ret
AccTuning_ResetFiveParts_Rec0:
	ld (0x31aa:16), 6
	ld (0x31ab:16), 0
	ret
AccTuning_ResetFiveParts_Rec1:
	ld (0x31b1:16), 0
	ld (0x31b2:16), 0
	ret
AccTuning_ResetFiveParts_Rec2:
	ld (0x31b8:16), 0
	ld (0x31b9:16), 0
	ret
AccTuning_ResetFiveParts_Rec3:
	ld (0x31bf:16), 0
	ld (0x31c0:16), 0
	ret
AccTuning_ResetFiveParts_Rec4:
	ld (0x31c6:16), 0
	ld (0x31c7:16), 0
	ret

; RAM 0x3259 := 15 and the low 3 bits of 0x325B := 0 -- the two bytes
; AccChannel_StoreCurrentState copies out.
AccChannel_ResetCurrentState:
	ld (0x3259:16), 15
	and (0x325b:16), 0xf8
	or (0x325b:16), 0x00
	ret

AccVoice_EmptyStub:
	ret

; Stores the E that Rhythm_DispatchNote_Helper returns into RAM 0x328F.
Rhythm_StoreDispatchHelperResult:
	call Rhythm_DispatchNote_Helper
	ld (0x328f:16), e
	ret

; Rhythm_DispatchNote with A = RAM 0xFC5A and D = RAM 0xFC5B; the A it
; returns is stored into RAM 0x328F.
Rhythm_DispatchNoteFromFC5A:
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x328f:16), a
	ret
RhythmROM_CheckValid:
	ld C, 0x00:opc
	ld XWA,0xffffffff
	cp xwa, (RHYTHM_ROM_BASE:16)
	jr z, RhythmROM_InvalidIncrement
	jr t, RhythmROM_CheckDone
RhythmROM_InvalidIncrement:
	ld	c, 1:opc
	ld	wa, (13240:16)
	add	wa, 1
	ld	(13240:16), wa
	cp	wa, 0:i3
	jr	nz, RhythmROM_CheckDone
	ld	a, 238:opc
	ld	(58134:16), a
	ld	(58136:16), 64
RhythmROM_CheckDone:
	ret

; -----------------------------------------------------------------------------
; Heap_AllocAndFreeTwoBlocks -- Malloc(0x400) (pointer kept in RAM 0x34C0),
; Malloc(0x1000), Free(second), Free(first), return.  NO CALLER FOUND:
; scripts/analysis/sequi_find_refs.py v7 0xF54158 -> none.
; The two callees carry misleading v7 names: 0xFF06A3
; (`Malloc`) is v10's Malloc (0xFF0E80) -- 63 of
; their first 64 bytes equal, the odd one a relocated call operand -- and
; 0xFF0315 (`Free`) is v10's Free (0xFF0AF2), 62/64
; equal.  v10's copy of this routine calls Malloc / Free by name.
; -----------------------------------------------------------------------------
Heap_AllocAndFreeTwoBlocks:
	ld	xwa, 1024
	push	xwa
	call	Malloc
	add	xsp, 4
	ld	(13504:16), xhl
	ld	xwa, 4096
	push	xwa
	call	Malloc
	add	xsp, 4
	ld	xwa, xhl
	ld	xwa, xwa
	push	xwa
	call	Free
	add	xsp, 4
	ld	xwa, (13504:16)
	push	xwa
	call	Free
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

; The 12 bytes RhythmROM_ValidateHeader requires at the start of the Rhythm Data ROM
; (RHYTHM_DATA_ROM__BASE_ADDR, 0x400000), as the three little-endian words it compares:
; 00 01 04 05 83 00 01 04 05 83 00 01.  A match leaves RHYTHM_ROM_BASE = 0, any difference -1.
.equ RHYTHMROM_SIG_0, 0x05040100
.equ RHYTHMROM_SIG_1, 0x04010083
.equ RHYTHMROM_SIG_2, 0x01008305
RhythmROM_ValidateHeader:
	xor	xwa, xwa
	ld	(RHYTHM_ROM_BASE:16), xwa
	ld	xix, RHYTHM_DATA_ROM__BASE_ADDR
	ld	xwa, (xix)
	cp	xwa, RHYTHMROM_SIG_0
	jr	nz, AccChord_CheckFailed
	ld	xwa, (xix+4)
	cp	xwa, RHYTHMROM_SIG_1
	jr	nz, AccChord_CheckFailed
	ld	xwa, (xix+8)
	cp	xwa, RHYTHMROM_SIG_2
	jr	nz, AccChord_CheckFailed
	jr	RhythmROM_HeaderValid
AccChord_CheckFailed:
	ld	xwa, 4294967295
	ld	(RHYTHM_ROM_BASE:16), xwa
RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	xor XHL,XHL
	ld L,W
	and L,0x7f
	srl L, 0x02
	cp (0x324a:16), 0x00
	jrl nz, AccPatch_ChIdx1_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx0_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx0_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx0_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx0_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx1_Entry:
	cp (0x324a:16), 0x01
	jrl nz, AccPatch_ChIdx2_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx1_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx1_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx1_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx1_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx2_Entry:
	cp (0x324a:16), 0x02
	jrl nz, AccPatch_ChIdx3_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx2_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx2_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx2_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx2_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx3_Entry:
	cp (0x324a:16), 0x03
	jrl nz, AccPatch_ChIdx4_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx3_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx3_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx3_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx3_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx4_Entry:
	cp (0x324a:16), 0x04
	jrl nz, AccPatch_ChIdx5_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx4_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx4_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx4_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx4_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx5_Entry:
	cp (0x324a:16), 0x05
	jrl nz, AccPatch_ChIdx6_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx5_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx5_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx5_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx5_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx6_Entry:
	cp (0x324a:16), 0x06
	jrl nz, AccPatch_ChIdxDefault_Bank0
	cp l, 0:i3
	jr nz, AccPatch_ChIdx6_Bank1
	ld A, 0x0c:opc
	calr AccPatch_SetVoiceParam
	ld (0x32c8:16), wa
	ld A, 0x0d:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ca:16), wa
	ld A, 0x0e:opc
	calr AccPatch_SetVoiceParam
	ld (0x32cc:16), wa
	ld A, 0x0f:opc
	calr AccPatch_SetVoiceParam
	ld (0x32ce:16), wa
	ld A, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d0:16), wa
	ld A, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x32d2:16), wa
	jrl t, AccPatch_NullReturn
AccPatch_ChIdx6_Bank1:
	cp	l, 1:i3
	jr	nz, AccPatch_ChIdx6_Bank2
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdx6_Bank2:
	ld	a, 24:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 25:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 26:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 27:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 28:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 29:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jrl	AccPatch_NullReturn
AccPatch_ChIdxDefault_Bank0:
	cp	l, 0:i3
	jr	nz, AccPatch_ChIdxDefault_Bank1
	ld	a, 12:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 13:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 14:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 15:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 16:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 17:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
	jr	AccPatch_NullReturn
AccPatch_ChIdxDefault_Bank1:
	ld	a, 18:opc
	calr	AccPatch_SetVoiceParam
	ld	(13000:16), wa
	ld	a, 19:opc
	calr	AccPatch_SetVoiceParam
	ld	(13002:16), wa
	ld	a, 20:opc
	calr	AccPatch_SetVoiceParam
	ld	(13004:16), wa
	ld	a, 21:opc
	calr	AccPatch_SetVoiceParam
	ld	(13006:16), wa
	ld	a, 22:opc
	calr	AccPatch_SetVoiceParam
	ld	(13008:16), wa
	ld	a, 23:opc
	calr	AccPatch_SetVoiceParam
	ld	(13010:16), wa
AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
