; =============================================================================
; Sequencer Audio Mode & Accompaniment Processing (2K lines)
; =============================================================================
;
; Audio mode stereo flags, accompaniment pedal processing,
; sequencer timing setup, part activation, and audio flag
; dispatch between SMF event processing and rhythm routines.
; =============================================================================

	ei 0
	ld (0x327f:16), a
	ret

AudioMode_CheckAndUpdateStereo:
	bit 3, (0x3284:16)
	jr z, AudioMode_CheckDone
	ld a, (0x327f:16)
	cp a, 0x5d
	jr nc, AudioMode_ApplyStereoUpdate
	cp a, 0x30
	jr ugt, AudioMode_CheckDone

AudioMode_ApplyStereoUpdate:
	call AudioMode_SetStereoFlags
	and (0x3284:16), 247

AudioMode_CheckDone:
	ret

AudioMode_MergeOutputBits:
	ld a, (0x3310:16)
	and a, 0xf8
	ld w, (0x32f9:16)
	and w, 0x7
	or a, w
	ld (0x3310:16), a
	ret

AudioMode_CopyChannelMode:
	ld a, (0x28b2:16)
	and a, 0x3
	ld (0x3335:16), a
	ret

AudioMode_CopyAccentFlags:
	ld a, (0x34f1:16)
	and a, 0x3d
	ld (0x3362:16), a
	ret

; -----------------------------------------------------------------------------
; AccPedal_LoadFlagFromStyleMem -- bit 0 of RAM 0x3363 (13155) :=
; bit 0 of the byte at RAM 0x094810.  Preserves WA and XIY.
; 0x094800 is the RAM copy of the composer factory user-style memory
; (technics-docs memory-map.md: table data 0x9B4000-0x9C3FFF is copied to RAM
; 0x94800), so the byte read is offset 0x10 of that image.  Sibling of
; AccPedal_SetFlag13155 below, which sets the same bit unconditionally.
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v10 0xF537A9 finds no
; absolute 24-bit reference in any KN5000 image and no calr/jr/jrl landing
; here (computed word-offset jumps not searched).  Was `.byte` until
; 2026-09-25; decodes cleanly, both decoders agree
; (notes/sequi-2026-09-25/reframe-v10-seq_audio_mode.log).
; -----------------------------------------------------------------------------
AccPedal_LoadFlagFromStyleMem:
	pushw wa
	push xiy
	and (0x3363:16), 0xfe
	ld xiy, 0x00094800
	add xiy, 16
	ld a, (xiy)
	bit 0, a
	jr z, AccPedal_LoadFlagFromStyleMem_Done
	or (0x3363:16), 0x01
AccPedal_LoadFlagFromStyleMem_Done:
	pop xiy
	popw wa
	ret

AccPedal_SetFlag13155:
	pushw wa
	push xiy
	or (0x3363:16), 1
	pop xiy
	popw wa
	ret

; -----------------------------------------------------------------------------
; AccPedal_BankBaseTableCopy -- 7 x 32-bit addresses, value-for-value the same
; as AccVoice_BankBaseTable entries 1-7 (all in the Custom Data Flash window
; 0x300000-0x3FFFFF).  Extent: from here to AccPedal_ProcessAllChanges, a
; called routine (28 bytes = 7 longs).
; NO READER FOUND: scripts/analysis/sequi_find_refs.py v10 --window 64 0xF537D4
; -- the only hits are the call to AccPedal_ProcessAllChanges (+28), operand
; bytes of unrelated instructions and table-data bytes.  Kept as data: the bytes
; do not decode as code (0x98 at +5 is undecodable) and they follow a `ret`.
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
	xor wa, wa
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	ld a, (1075:16)
	bit	0, (xhl+wa)
	jrl z, AccPedal_ReadBankAndReturn
	xor a, a
	bit 0, (0x32fb:16)
	jr z, AccPedal_CheckBit1Left
	or a, 0x40

AccPedal_CheckBit1Left:
	bit 1, (0x32fb:16)
	jr z, AccPedal_CheckBit0Right
	or a, 0x80

AccPedal_CheckBit0Right:
	bit 0, (0x32fd:16)
	jr z, AccPedal_CheckBit1Right
	or a, 0x10

AccPedal_CheckBit1Right:
	bit 1, (0x32fd:16)
	jr z, AccPedal_CheckBit0Aux
	or a, 0x20

AccPedal_CheckBit0Aux:
	bit 0, (0x32ff:16)
	jr z, AccPedal_CheckBit1Aux
	or a, 0x4

AccPedal_CheckBit1Aux:
	bit 1, (0x32ff:16)
	jr z, AccPedal_ApplyChangeMask
	or a, 0x8

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
	bit 2, (0x32ff:16)
	jr z, AccPedal_ClearAllPedalFlags
	and (0xfc60:16), 251
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld w, 0x0:opc
	ld a, 0x0:opc
	calr Rhythm_QueuePartChangeEvent

AccPedal_ClearAllPedalFlags:
	xor a, a
	ld (0x32fb:16), a
	ld (0x32fd:16), a
	ld (0x32ff:16), a

AccPedal_ReadBankAndReturn:
	calr AccVoice_ReadBankAssign
	ret

AccVoice_ReadBankAssign:
	xor wa, wa
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	ld a, (1075:16)
	ld	a, (xhl+wa)
	bit 0, (0x3283:16)
	jr nz, AccVoice_StoreBankAssign
	ld a, 0x0:opc

AccVoice_StoreBankAssign:
	ld (0x3282:16), a
	ret

AccChannel_CompareAndMarkDirty:
	ld a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, AccChannel_StoreCurrentState
	ld a, (0x32f5:16)
	cp a, (0x32f6:16)
	jr nz, AccChannel_MarkDirtyAndSync
	ld a, (0x32f7:16)
	and a, 0x7f
	and a, 0x7
	ld w, (0x32f8:16)
	and w, 0x7f
	and w, 0x7
	cp a, w
	jr z, AccChannel_StoreCurrentState

AccChannel_MarkDirtyAndSync:
	calr AccChannel_SetDirtyIfActive
	calr AccChannel_CheckActivitySetDirty
	calr AccChannel_CheckPartIndexDirty
	or (0x330c:16), 1

AccChannel_StoreCurrentState:
	ld a, (0x32f5:16)
	ld (0x32e7:16), a
	ld a, (0x32f7:16)
	and a, 0x7f
	and w, 0x7
	ld (0x32e8:16), a
	ret

; -----------------------------------------------------------------------------
; AccChannel_StoreStateIfChanged -- the conditional form of
; AccChannel_StoreCurrentState (just above): when RAM 0x32F5 differs from
; 0x32F6, or it is below 0x80 and the low 3 bits of 0x32F7 and 0x32F8 differ,
; copy 0x32F5 -> 0x32E7 and 0x32F7 -> 0x32E8.  (Both `and` masks on the store
; path act on W, so 0x32F7 is stored unmasked; AccChannel_StoreCurrentState above
; masks A with 0x7F, and only its `and 7` hits W.)
; NO CALLER FOUND: scripts/analysis/sequi_find_refs.py v10 0xF538EC (forms as
; above).  Was `.byte` until 2026-09-25; decodes cleanly, both decoders agree.
; -----------------------------------------------------------------------------
AccChannel_StoreStateIfChanged:
	ld a, (0x32f5:16)
	cp a, (0x32f6:16)
	jr nz, AccChannel_StoreStateIfChanged_Store
	cp a, 128
	jr nc, AccChannel_StoreStateIfChanged_Return
	ld a, (0x32f7:16)
	and a, 127
	and a, 7
	ld w, (0x32f8:16)
	and w, 127
	and w, 7
	cp a, w
	jr z, AccChannel_StoreStateIfChanged_Return
AccChannel_StoreStateIfChanged_Store:
	ld a, (0x32f5:16)
	ld (0x32e7:16), a
	ld a, (0x32f7:16)
	and w, 127
	and w, 7
	ld (0x32e8:16), a
AccChannel_StoreStateIfChanged_Return:
	ret

AccChannel_SetDirtyIfActive:
	ld wa, (0x32e3:16)
	and w, 0x7
	cp w, 0:i3
	jr z, AccChannel_SetDirtyDone
	or (0x3326:16), 63

AccChannel_SetDirtyDone:
	ret

AccChannel_CheckActivitySetDirty:
	ld a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	and a, 0x3f
	jr z, AccChannel_ActivityCheckDone
	cp (0x32f5:16), 128
	jr c, AccChannel_ActivityCheckDone
	or (0x3326:16), 63

AccChannel_ActivityCheckDone:
	ret

AccChannel_CheckPartIndexDirty:
	ld a, (1075:16)
	cp a, 1:i3
	jr nz, AccChannel_PartIndexDone
	or (0x3326:16), 63

AccChannel_PartIndexDone:
	ret

AccVoice_ProcessPedalChanges:
	bit 0, (0x32ff:16)
	jr z, AccVoice_Pedal0_Done
	bit 0, (0x3300:16)
	jr nz, AccVoice_Pedal0_Done
	xor a, a
	ld (0x3309:16), a
	ld (0x330b:16), a
	and (0x330a:16), 243
	and (0x3327:16), 192
	bit 0, (0x330c:16)
	jr nz, AccVoice_Pedal0_SetAndCheck
	and (0x3326:16), 192

AccVoice_Pedal0_SetAndCheck:
	or (0x330a:16), 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal0_Done:
	bit 1, (0x32ff:16)
	jr z, AccVoice_Pedal1_Done
	bit 1, (0x3300:16)
	jr nz, AccVoice_Pedal1_Done
	xor a, a
	ld (0x3309:16), a
	ld (0x330b:16), a
	and (0x330a:16), 246
	and (0x3327:16), 192
	bit 0, (0x330c:16)
	jr nz, AccVoice_Pedal1_SetAndCheck
	and (0x3326:16), 192

AccVoice_Pedal1_SetAndCheck:
	or (0x330a:16), 4
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal1_Done:
	bit 2, (0x32ff:16)
	jr z, AccVoice_Pedal2_Done
	bit 2, (0x3300:16)
	jr nz, AccVoice_Pedal2_Done
	xor a, a
	ld (0x3309:16), a
	ld (0x330b:16), a
	and (0x330a:16), 250
	and (0x3327:16), 192
	bit 0, (0x330c:16)
	jr nz, AccVoice_Pedal2_SetAndCheck
	and (0x3326:16), 192

AccVoice_Pedal2_SetAndCheck:
	or (0x330a:16), 8
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_Pedal2_Done:
	ret

AccVoice_ProcessLeftPedalChanges:
	bit 0, (0x32fb:16)
	jr z, AccVoice_LeftPedal0_Done
	bit 0, (0x32fc:16)
	jr nz, AccVoice_LeftPedal0_Done
	xor a, a
	ld (0x330a:16), a
	ld (0x330b:16), a
	and (0x3309:16), 253
	and (0x3327:16), 192
	bit 0, (0x330c:16)
	jr nz, AccVoice_LeftPedal0_SetAndCheck
	and (0x3326:16), 192

AccVoice_LeftPedal0_SetAndCheck:
	or (0x3309:16), 1
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_LeftPedal0_Done:
	bit 1, (0x32fb:16)
	jr z, AccVoice_LeftPedal1_Done
	bit 1, (0x32fc:16)
	jr nz, AccVoice_LeftPedal1_Done
	xor a, a
	ld (0x330a:16), a
	ld (0x330b:16), a
	and (0x3309:16), 254
	and (0x3327:16), 192
	bit 0, (0x330c:16)
	jr nz, AccVoice_LeftPedal1_SetAndCheck
	and (0x3326:16), 192

AccVoice_LeftPedal1_SetAndCheck:
	or (0x3309:16), 2
	calr AccVoice_CheckBitsAndSetFlags
	calr AccVoice_CheckChannelSetActive

AccVoice_LeftPedal1_Done:
	ret

AccVoice_CheckChannelSetActive:
	ld a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr z, AccVoice_ChannelActiveDone
	or (0x330f:16), 1

AccVoice_ChannelActiveDone:
	ret

AccVoice_CheckBitsAndSetFlags:
	ld de, (0x32e3:16)
	and d, 0x7
	inc 1, d
	cp d, (1075:16)
	jr nz, AccVoice_BitsCheckDone
	or (0x3327:16), 63

AccVoice_BitsCheckDone:
	ret

AccPitch_CheckTransposeFlags:
	bit 6, (0x3470:16)
	jr nz, AccPitch_UpdateCheck
	bit 6, (0x3281:16)
	jr z, AccPitch_UpdateCheck
	ld a, (0x3280:16)
	inc 1, a
	cp a, (1075:16)
	jr nz, AccPitch_UpdateCheck
	or (0x3329:16), 63

AccPitch_UpdateCheck:
	bit 7, (0x3470:16)
	jr nz, AccPitch_FinalReturn
	bit 7, (0x3281:16)
	jr z, AccPitch_FinalReturn
	ld a, (0x3280:16)
	inc 1, a
	cp a, (1075:16)
	jr nz, AccPitch_FinalReturn
	or (0x3329:16), 63

AccPitch_FinalReturn:
	ret

AccChord_ProcessKeyChanges:
	bit 0, (0x32fd:16)
	jr z, AccChord_KeyChange0_Done
	bit 0, (0x32fe:16)
	jr nz, AccChord_KeyChange0_Done
	xor a, a
	ld (0x330a:16), a
	ld (0x3309:16), a
	and (0x3327:16), 192
	and (0x330b:16), 253
	and (0x3326:16), 192
	or (0x330b:16), 1
	calr AccChannel_SetDirtyIfActive

AccChord_KeyChange0_Done:
	bit 1, (0x32fd:16)
	jr z, AccChord_KeyChange1_Done
	bit 1, (0x32fe:16)
	jr nz, AccChord_KeyChange1_Done
	xor a, a
	ld (0x330a:16), a
	ld (0x3309:16), a
	and (0x3327:16), 192
	and (0x330b:16), 254
	and (0x3326:16), 192
	or (0x330b:16), 2
	calr AccChannel_SetDirtyIfActive

AccChord_KeyChange1_Done:
	ret

AccChord_ResolveVoiceAndDispatch:
	ld a, (0x32e5:16)
	ld w, (0x3327:16)
	and w, 0x3f
	jr z, AccChord_CheckRange
	ld a, (0x32e7:16)

AccChord_CheckRange:
	cp a, 0x80
	jrl c, AccChord_NullRet
	cp a, 0xf0
	jr c, AccChord_MaskAndContinue
	ld a, (0x33f1:16)
	jr AccChord_DispatchVoiceChange

AccChord_MaskAndContinue:
	and a, 0x7f

AccChord_DispatchVoiceChange:
	calr AccPatch_SetVoiceParam
	ld c, a
	xor a, a
	bit 0, (0x330a:16)
	jr z, AccChord_CheckVoiceBit2
	cp c, (0x3364:16)
	jr z, AccChord_CheckVoiceBit2
	and (0x330a:16), 254
	and (0x3327:16), 192
	and (0x32ff:16), 254
	or a, 0x4

AccChord_CheckVoiceBit2:
	bit 2, (0x330a:16)
	jr z, AccChord_CheckLeftPedal0
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 0, 0x03, 0xec, 0xe4
	jr z, AccChord_CheckLeftPedal0
	and (0x330a:16), 251
	and (0x3327:16), 192
	and (0x32ff:16), 253
	or a, 0x8

AccChord_CheckLeftPedal0:
	bit 0, (0x3309:16)
	jr z, AccChord_CheckLeftPedal1
	cp c, (0x3368:16)
	jr z, AccChord_CheckLeftPedal1
	and (0x3309:16), 254
	and (0x3327:16), 192
	and (0x32fb:16), 254
	or a, 0x40

AccChord_CheckLeftPedal1:
	bit 1, (0x3309:16)
	jr z, AccChord_CheckKeyChange0
	cp c, (0x336a:16)
	jr z, AccChord_CheckKeyChange0
	and (0x3309:16), 253
	and (0x3327:16), 192
	and (0x32fb:16), 253
	or a, 0x80

AccChord_CheckKeyChange0:
	bit 0, (0x330b:16)
	jr z, RhythmPart_ProcessBit0
	cp c, (0x336c:16)
	jr z, RhythmPart_ProcessBit0
	and (0x330b:16), 254
	and (0x32fd:16), 254
	or a, 0x10
	bit 0, (0x330c:16)
	jr nz, RhythmPart_ProcessBit0
	and (0x3327:16), 192

RhythmPart_ProcessBit0:
	bit 1, (0x330b:16)
	jr z, RhythmPart_ProcessBit1
	cp c, (0x336e:16)
	jr z, RhythmPart_ProcessBit1
	and (0x330b:16), 253
	and (0x32fd:16), 253
	or a, 0x20
	bit 0, (0x330c:16)
	jr nz, RhythmPart_ProcessBit1
	and (0x3327:16), 192

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
	bit 3, (0x330a:16)
	jr z, AccChord_CheckPitchDirty
	cp c, (0x3366:16)
	jr z, AccChord_CheckPitchDirty
	and (0x330a:16), 247
	and (0x3327:16), 192
	and (0x32ff:16), 251
	and (0xfc5f:16), 251
	ld a, 0x0:opc
	ld w, 0x0:opc
	ld e, 0x48:opc
	ld d, 0x5:opc
	calr Rhythm_QueuePartChangeEvent

AccChord_CheckPitchDirty:
	ld a, (0x3329:16)
	and a, 0x3f
	jr z, AccChord_NullRet
	bit 0, (0x32fb:16)
	jr z, AccChord_CheckPitchLeftPedal1
	cp c, (0x3368:16)
	jr z, AccChord_NullRet
	and (0x3329:16), 192
	jr AccChord_NullRet

AccChord_CheckPitchLeftPedal1:
	bit 1, (0x32fb:16)
	jr z, AccChord_NullRet
	ld xhl, AccStyle_ApplyExt_SkipClamp_Table
	bit_dri 0, 0x03, 0xec, 0xe4
	jr z, AccChord_NullRet
	and (0x3329:16), 192

AccChord_NullRet:
	ret

AccChord_CompareAndSetDirty:
	ld a, (0x32d8:16)
	cp a, (0x32dc:16)
	jr nz, AccChord_SetDirtyBit5
	ld a, (0x32da:16)
	cp a, (0x32de:16)
	jr z, AccChord_CheckZeroChord

AccChord_SetDirtyBit5:
	or (0x32f3:16), 32

AccChord_CheckZeroChord:
	cp (0x32dc:16), 0
	jr nz, AccChord_CompareDone
	and (0x32f3:16), 223

AccChord_CompareDone:
	ret

AccentVoice_DetectAndMarkChange:
	ld a, (0x3305:16)
	cp a, (0x3306:16)
	jr z, AccentVoice_UpdateParamIndex
	ld a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, AccentVoice_UpdateParamIndex
	cp (0x32e5:16), 240
	jr nc, AccentVoice_UpdateParamIndex
	cp (0x32e5:16), 128
	jr nc, AccentVoice_UpdateParamIndex
	bit 0, (0x3301:16)
	jr z, AccentVoice_CheckModeChange
	ld a, (0x3312:16)
	or a, (0x3313:16)
	and a, 0x3f
	jr nz, AccentVoice_UpdateParamIndex

AccentVoice_CheckModeChange:
	ld a, (0x3305:16)
	and a, 0x3
	cp a, (0x3338:16)
	jr z, AccentVoice_UpdateParamIndex
	or (0x330d:16), 1

AccentVoice_UpdateParamIndex:
	ld a, (0x3305:16)
	and a, 0x3
	ld (0x333a:16), a
	ret

AccVoice_ResolveParamAddr:
	push xwa
	push xix
	ld xiy, RhythmTiming_OffsetTable
	cp a, 0x1d
	jr ule, AccVoice_ComputeParamOffset
	xor a, a

AccVoice_ComputeParamOffset:
	extz wa
	sla wa, 2
	extz xwa
	add xiy, xwa
	ld xiy, (xiy)
	ld a, (0x32e6:16)
	extz wa
	sla wa, 2
	ld xix, AccVoice_BankBaseTable
	ld	xix, (xix+wa)
	add xiy, xix
	add xiy, 0x60
	pop xix
	pop xwa
	ret

; -----------------------------------------------------------------------------
; AccVoice_BankBaseTable -- 8 x 32-bit base addresses indexed by RAM byte
; 0x32E6.
; Reader: AccVoice_ComputeParamOffset (0xF53D2E, the tail of
; AccVoice_ResolveParamAddr 0xF53D20): `ld xix, AccVoice_BankBaseTable` then
; `ld xix, (xix+wa)` = ld xix, (xix + wa) with wa = (0x32E6)*4.
; The entry is added to the 32-bit offset the routine first loaded from
; RhythmTiming_OffsetTable[A] (A clamped to 0..0x1D), plus 0x60; the sum is
; returned in XIY.  So each entry is the base of a bank that those offsets
; index into.
; Stride 4 (the reader's `sla wa, 2`); 8 entries = 32 bytes, from here to
; AccVoice_ComputeChannelIndex (a called routine).
; Entry 0 is RAM 0x094800, the RAM copy of the composer factory user-style
; memory (technics-docs memory-map.md); entries 1-7 lie in the Custom Data
; Flash window 0x300000-0x3FFFFF, alternately 0x19800 and 0x16800 apart.
; Which style slot each bank index stands for is decided by the writers of the
; index byte, which were not examined for this header.
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
	cp (0x32e5:16), 128
	jr nc, AccVoice_PatchFromDirect
	ld xiy, (0x32ce:16)
	calr AccStyle_ReadVoiceParam
	ld (0x32ef:16), w
	jr AccVoice_StorePatchAndLookup

AccVoice_PatchFromDirect:
	ld a, (0x32e5:16)
	and a, 0x7f
	calr AccPatch_SetVoiceParam

AccVoice_StorePatchAndLookup:
	ld (1075:16), a
	ld xhl, AccVoice_LookupTableAddress_Table
	sla a, 1
	ld	wa, (xhl+a)
	ld (0x327b:16), wa
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
	ld xix, 0x3246
	ldw bc, 0x31
	ldir85
	push xwa
	push xix
	ld xix, 0x3246
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
	ld bc, 7:i3
	ldir85
	ld xiy, xhl
	add xiy, 0x20
	ld xix, 0x324d
	ld bc, 7:i3
	ldir85
	ld xiy, xhl
	add xiy, 0x28
	ld xix, 0x3254
	ld bc, 7:i3
	ldir85
	ld xiy, xhl
	add xiy, 0x30
	ld xix, 0x325b
	ld bc, 7:i3
	ldir85
	ld xiy, xhl
	add xiy, 0x38
	ld xix, 0x3262
	ld bc, 7:i3
	ldir85
	pop xiy
	ret

AccTuning_LoadAndApplyMaster:
	push xiy
	add xhl, 0x248
	add xiy, xhl
	ld xix, 0x3246
	ld bc, 7:i3
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
	add xhl, 0x24f
	add xiy, xhl
	ld xix, 0x324d
	ld bc, 7:i3
	ldir85
	ld xix, 0x324f
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
	ld bc, 7:i3
	ldir85
	ld xix, 0x3256
	ld (xix), 0xc
	call AccTuning_LoadFine
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
	ld xix, 0x325b
	ld bc, 7:i3
	ldir85
	ld xix, 0x325d
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
	ld bc, 7:i3
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
	bit 0, (0x3283:16)
	jr nz, Rhythm_ProcessAllDone
	call AccVoice_LoadAllChannelParams

Rhythm_ProcessAllDone:
	ret

RhythmPart_CopyData:
	ldw bc, 0x19
	ld xiy, 0x3214
	ld xix, 0x322d
	ldir85
	ret

RhythmPart1_ProcessAccentData:
	bit 0, (0x3283:16)
	jr z, RhythmPart1_CheckAccentData
	call AccentData_ComparePart1

RhythmPart1_CheckAccentData:
	ld a, (0x332c:16)
	and a, 0x3
	jr z, RhythmPart1_WriteDone
	ld e, (0x3246:16)
	ld d, (0x3247:16)
	bit 0, (0x3283:16)
	jr nz, RhythmPart1_ProcessRingBuf
	ld xhl, 0x3214
	ld (xhl), e
	ld (xhl + 1), d
	jr RhythmPart1_WriteDone

RhythmPart1_ProcessRingBuf:
	ld xhl, 0x2a94
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
	ld xhl, 0x3214
	ld (xhl), e
	ld (xhl + 1), d

RhythmPart1_WriteDone:
	and (0x332c:16), 252
	call AccVoiceReg_WritePart1
	ret

RhythmAccent_CopyAndUpdateRingBuf:
	pushw de
	pushw wa
	ld a, (0x32ec:16)
	ld (0x342e:16), a
	calr RhythmAccent_UpdateRingBufPosition
	popw wa
	popw de
	ret

RhythmAccent_UpdateRingBufPosition:
	ld a, (0x342e:16)
	ei 6
	sub a, (1124:16)
	jr ugt, RhythmAccent_StorePosition
	ld a, 0x1:opc
	ld (0x342e:16), a
	cp (1122:16), 0
	jr z, RhythmAccent_AddAndCompare
	xor a, a
	jr RhythmAccent_AddAndCompare

RhythmAccent_StorePosition:
	ld (0x342e:16), a

RhythmAccent_AddAndCompare:
	ld w, (1122:16)
	add a, w
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld w, (0x3376:16)
	cp a, w
	jr nc, RhythmAccent_UpdateDone
	ld (0x3376:16), a

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
	bit 0, (0x3283:16)
	jr z, RhythmPart2_LoadAndStore
	call AccentData_ComparePart2

RhythmPart2_LoadAndStore:
	bit 2, (0x332c:16)
	ld e, (0x324d:16)
	ld d, (0x324e:16)
	ld a, (0x324f:16)
	ld (0x342f:16), a
	ld a, (0x3250:16)
	ld (0x3430:16), a
	ld a, (0x3251:16)
	ld (0x3431:16), a
	ld a, (0x3252:16)
	ld (0x32c3:16), a
	ld a, (0x3253:16)
	ld (0x32c7:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x3283:16)
	jr nz, RhythmPart2_ProcessRingBuf
	ld xhl, 0x3219
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart2_WriteDone

RhythmPart2_ProcessRingBuf:
	ld xhl, 0x2c94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3219
	calr AccVoiceReg_StoreParamRecord

RhythmPart2_WriteDone:
	and (0x332c:16), 251
	call AccVoiceReg_WritePart2
	ret

AccVoiceReg_StoreParamRecord:
	ld (xhl), e
	ld (xhl + 1), d
	ld a, (0x342f:16)
	ld (xhl + 2), a
	ld a, (0x3430:16)
	ld (xhl + 3), a
	ld a, (0x3431:16)
	ld (xhl + 4), a
	ret

Rhythm_PackVelocityHighBit:
	bit 7, e
	jr z, Rhythm_VelocityPackDone
	or d, 0x10
	and e, 0x7f

Rhythm_VelocityPackDone:
	ret

AccVoice_LoadRhythmParams_Part3:
	bit 0, (0x3283:16)
	jr z, RhythmPart3_LoadAndStore
	call AccentData_ComparePart3

RhythmPart3_LoadAndStore:
	bit 3, (0x332c:16)
	ld e, (0x3254:16)
	ld d, (0x3255:16)
	ld a, (0x3256:16)
	ld (0x342f:16), a
	ld a, (0x3257:16)
	ld (0x3430:16), a
	ld a, (0x3258:16)
	ld (0x3431:16), a
	ld a, (0x3259:16)
	ld (0x32c4:16), a
	ld a, (0x325a:16)
	ld (0x32c8:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x3283:16)
	jr nz, RhythmPart3_ProcessRingBuf
	ld xhl, 0x321e
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart3_WriteDone

RhythmPart3_ProcessRingBuf:
	ld xhl, 0x2d94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x321e
	calr AccVoiceReg_StoreParamRecord

RhythmPart3_WriteDone:
	and (0x332c:16), 247
	call AccVoiceReg_WritePart3
	ret

AccVoice_LoadRhythmParams_Part4:
	bit 0, (0x3283:16)
	jr z, RhythmPart4_LoadAndStore
	call AccentData_ComparePart4

RhythmPart4_LoadAndStore:
	bit 4, (0x332c:16)
	ld e, (0x325b:16)
	ld d, (0x325c:16)
	ld a, (0x325d:16)
	ld (0x342f:16), a
	ld a, (0x325e:16)
	ld (0x3430:16), a
	ld a, (0x325f:16)
	ld (0x3431:16), a
	ld a, (0x3260:16)
	ld (0x32c5:16), a
	ld a, (0x3261:16)
	ld (0x32c9:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x3283:16)
	jr nz, RhythmPart4_ProcessRingBuf
	ld xhl, 0x3223
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart4_WriteDone

RhythmPart4_ProcessRingBuf:
	ld xhl, 0x2e94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3223
	calr AccVoiceReg_StoreParamRecord

RhythmPart4_WriteDone:
	and (0x332c:16), 239
	call AccVoiceReg_WritePart4
	ret

AccVoice_LoadRhythmParams_Part5:
	bit 0, (0x3283:16)
	jr z, RhythmPart5_LoadAndStore
	call AccentData_ComparePart5

RhythmPart5_LoadAndStore:
	bit 5, (0x332c:16)
	ld e, (0x3262:16)
	ld d, (0x3263:16)
	ld a, (0x3264:16)
	ld (0x342f:16), a
	ld a, (0x3265:16)
	ld (0x3430:16), a
	ld a, (0x3266:16)
	ld (0x3431:16), a
	ld a, (0x3267:16)
	ld (0x32c6:16), a
	ld a, (0x3268:16)
	ld (0x32ca:16), a
	calr Rhythm_PackVelocityHighBit
	bit 0, (0x3283:16)
	jr nz, RhythmPart5_ProcessRingBuf
	ld xhl, 0x3228
	calr AccVoiceReg_StoreParamRecord
	jr RhythmPart5_WriteDone

RhythmPart5_ProcessRingBuf:
	ld xhl, 0x2f94
	ld iy, (xhl + 4)
	ld bc, (xhl + 2)
	ld	(xhl+iy), 0xc0
	calr RingBuf_AdvanceIndex
	calr RhythmAccent_CopyAndUpdateRingBuf
	ld	(xhl+iy), e
	calr RingBuf_AdvanceIndex
	ld	(xhl+iy), d
	calr RingBuf_AdvanceIndex
	ld a, (0x342f:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld a, (0x3431:16)
	ld	(xhl+iy), a
	calr RingBuf_AdvanceIndex
	ld (xhl + 4), iy
	ld xhl, 0x3228
	calr AccVoiceReg_StoreParamRecord

RhythmPart5_WriteDone:
	and (0x332c:16), 223
	call AccVoiceReg_WritePart5
	ret

AccompVoice_BulkReadRegisters:
	ld a, 0x0:opc
	ld xhl, 0x3094
	xor iy, iy

BulkRead_Loop1_6Byte:
	ld	(xhl+iy), a
	add iy, 0x6
	cp iy, 0x30
	jr c, BulkRead_Loop1_6Byte
	ld xhl, 0x30c4
	xor iy, iy

BulkRead_Loop2_6Byte:
	ld	(xhl+iy), a
	add iy, 0x6
	cp iy, 0x30
	jr c, BulkRead_Loop2_6Byte
	ld xhl, 0x30f4
	xor iy, iy

BulkRead_Loop3_9Byte:
	ld	(xhl+iy), a
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop3_9Byte
	ld xhl, 0x313c
	xor iy, iy

BulkRead_Loop4_9Byte:
	ld	(xhl+iy), a
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop4_9Byte
	ld xhl, 0x3184
	xor iy, iy

BulkRead_Loop5_9Byte:
	ld	(xhl+iy), a
	add iy, 0x9
	cp iy, 0x48
	jr c, BulkRead_Loop5_9Byte
	ld xhl, 0x31cc
	xor iy, iy

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
	ld (0x33e2:16), a
	ld (0x33e3:16), w
	ld (0x33e4:16), e
	ld a, (0x33e2:16)
	call Rhythm_SendByte
	ld a, (0x33e3:16)
	call Rhythm_SendByte
	ld a, (0x33e4:16)
	call Rhythm_SendByte
	ret

Rhythm_SendChanPressure:
	ld a, 0xd0:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	calr Rhythm_Send3ByteMsg
	ld a, 0x0:opc
	ld (0x332f:16), a
	ld (0x3330:16), a
	ld (0x3331:16), a
	ld (0x3332:16), a
	ret

AccBuf_ResetAndReload:
	call AccBuf_ResetAllPositions
	call AccompVoice_BulkReadRegisters
	call AccStyle_InitVRAM_Wrap
	ret

AccVoice_LoadAllChannelParams:
	ld xix, 0x3214
	ld a, 0x98:opc
	and a, 0xf
	or a, 0xc0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3219
	ld a, 0x97:opc
	and a, 0xf
	or a, 0xc0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x321e
	ld a, 0x94:opc
	and a, 0xf
	or a, 0xc0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3223
	ld a, 0x95:opc
	and a, 0xf
	or a, 0xc0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
	ld xix, 0x3228
	ld a, 0x96:opc
	and a, 0xf
	or a, 0xc0
	call Rhythm_SendByte
	call VoiceParams_LoadFiveSequential
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
; instruction (notes/sequi-2026-09-25/reframe-v10-seq_audio_mode.log), every
; internal calr lands on an instruction boundary, and the calls reach the
; independently known Rhythm_DispatchNote / Rhythm_DispatchNote_Helper.
; NO CALLER FOUND for the five entry points that nothing here calls
; (AccTuning_ResetFiveParts, AccChannel_ResetCurrentState,
; AccVoice_EmptyStub, Rhythm_StoreDispatchHelperResult,
; Rhythm_DispatchNoteFromFC5A): scripts/analysis/sequi_find_refs.py v10
; 0xF544BD 0xF54504 0xF54514 0xF54515 0xF5451E -> none.
; -----------------------------------------------------------------------------

; Writes the first two bytes of the first five 7-byte records at RAM 0x3246,
; 0x324D, 0x3254, 0x325B, 0x3262 (record 0 byte 0 := 6, the other nine := 0).
; Those are the per-part tuning records: AccTuning_CopyAllPartsFromStyle
; copies 7 bytes per part from the style into 0x3246, 0x324D, ...;
; AccVoice_LoadTuningBlock copies all 0x31 bytes (7 records) at once.
AccTuning_ResetFiveParts:
	calr AccTuning_ResetFiveParts_Rec0
	calr AccTuning_ResetFiveParts_Rec1
	calr AccTuning_ResetFiveParts_Rec2
	calr AccTuning_ResetFiveParts_Rec3
	calr AccTuning_ResetFiveParts_Rec4
	ret
AccTuning_ResetFiveParts_Rec0:
	ld (0x3246:16), 6
	ld (0x3247:16), 0
	ret
AccTuning_ResetFiveParts_Rec1:
	ld (0x324d:16), 0
	ld (0x324e:16), 0
	ret
AccTuning_ResetFiveParts_Rec2:
	ld (0x3254:16), 0
	ld (0x3255:16), 0
	ret
AccTuning_ResetFiveParts_Rec3:
	ld (0x325b:16), 0
	ld (0x325c:16), 0
	ret
AccTuning_ResetFiveParts_Rec4:
	ld (0x3262:16), 0
	ld (0x3263:16), 0
	ret

; RAM 0x32F5 := 15 and the low 3 bits of 0x32F7 := 0 -- the two bytes
; AccChannel_StoreCurrentState copies out.
AccChannel_ResetCurrentState:
	ld (0x32f5:16), 15
	and (0x32f7:16), 0xf8
	or (0x32f7:16), 0x00
	ret

AccVoice_EmptyStub:
	ret

; Stores the E that Rhythm_DispatchNote_Helper returns into RAM 0x332B.
Rhythm_StoreDispatchHelperResult:
	call Rhythm_DispatchNote_Helper
	ld (0x332b:16), e
	ret

; Rhythm_DispatchNote with A = RAM 0xFC5A and D = RAM 0xFC5B; the A it
; returns is stored into RAM 0x332B.
Rhythm_DispatchNoteFromFC5A:
	ld a, (0xfc5a:16)
	ld d, (0xfc5b:16)
	call Rhythm_DispatchNote
	ld (0x332b:16), a
	ret

RhythmROM_CheckValid:
	ld c, 0x0:opc
	ld xwa, 0xffffffff
	cp xwa, (RHYTHM_ROM_BASE:16)
	jr z, RhythmROM_InvalidIncrement
	jr RhythmROM_CheckDone

RhythmROM_InvalidIncrement:
	ld c, 0x1:opc
	ld wa, (0x3454:16)
	add wa, 0x1
	ld (0x3454:16), wa
	cp wa, 0:i3
	jr nz, RhythmROM_CheckDone
	ld a, 0xee:opc
	ld (0xe3dc:16), a
	ld (0xe3de:16), 64

RhythmROM_CheckDone:
	ret

; -----------------------------------------------------------------------------
; Heap_AllocAndFreeTwoBlocks -- Malloc(0x400) (pointer kept in RAM 0x355C),
; Malloc(0x1000), Free(second), Free(first), return.  A heap round trip with
; no lasting effect except RAM 0x355C.  C-compiler shaped (`ld xwa,xhl;
; ld xwa,xwa; push xwa`).  NO CALLER FOUND: scripts/analysis/sequi_find_refs.py
; v10 0xF5455C -> none.  Was a mix of `.byte`, `.asciz "\\5c@"` and `addr24`
; until 2026-09-25 (the text was the operand bytes of `ld (0x355c:16), xhl`).
; -----------------------------------------------------------------------------
Heap_AllocAndFreeTwoBlocks:
	ld	xwa, 1024
	push	xwa
	call	Malloc
	add	xsp, 4
	ld (0x355c:16), xhl
	ld xwa, 4096
	push xwa
	call Malloc
	add xsp, 4
	ld xwa, xhl
	ld xwa, xwa
	push xwa
	call Free
	add xsp, 4
	ld xwa, (0x355c:16)
	push xwa
	call Free
	add xsp, 4
	ret

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
	and (0x332c:16), 252

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
	and (0x332c:16), 251

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
	and (0x332c:16), 247

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
	and (0x332c:16), 239

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
	and (0x332c:16), 223

AccentData_Part5_Done:
	ret

RhythmROM_ValidateHeader:
	xor xwa, xwa
	ld (RHYTHM_ROM_BASE:16), xwa
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
	ld xwa, 0xffffffff
	ld (RHYTHM_ROM_BASE:16), xwa

RhythmROM_HeaderValid:
	ret

AccPatch_SetByChordIndex:
	xor xhl, xhl
	ld l, w
	and l, 0x7f
	srl l, 2
	cp (0x32e6:16), 0
	jrl nz, AccPatch_ChIdx1_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx0_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx0_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx0_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx0_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Entry:
	cp (0x32e6:16), 1
	jrl nz, AccPatch_ChIdx2_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx1_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx1_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx1_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Entry:
	cp (0x32e6:16), 2
	jrl nz, AccPatch_ChIdx3_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx2_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx2_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx2_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Entry:
	cp (0x32e6:16), 3
	jrl nz, AccPatch_ChIdx4_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx3_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx3_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx3_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Entry:
	cp (0x32e6:16), 4
	jrl nz, AccPatch_ChIdx5_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx4_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx4_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx4_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Entry:
	cp (0x32e6:16), 5
	jrl nz, AccPatch_ChIdx6_Entry
	cp l, 0:i3
	jr nz, AccPatch_ChIdx5_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx5_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx5_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Entry:
	cp (0x32e6:16), 6
	jrl nz, AccPatch_ChIdxDefault_Bank0
	cp l, 0:i3
	jr nz, AccPatch_ChIdx6_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Bank1:
	cp l, 1:i3
	jr nz, AccPatch_ChIdx6_Bank2
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdx6_Bank2:
	ld a, 0x18:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x19:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x1a:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x1b:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x1c:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x1d:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jrl AccPatch_NullReturn

AccPatch_ChIdxDefault_Bank0:
	cp l, 0:i3
	jr nz, AccPatch_ChIdxDefault_Bank1
	ld a, 0xc:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0xd:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0xe:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0xf:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x10:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x11:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa
	jr AccPatch_NullReturn

AccPatch_ChIdxDefault_Bank1:
	ld a, 0x12:opc
	calr AccPatch_SetVoiceParam
	ld (0x3364:16), wa
	ld a, 0x13:opc
	calr AccPatch_SetVoiceParam
	ld (0x3366:16), wa
	ld a, 0x14:opc
	calr AccPatch_SetVoiceParam
	ld (0x3368:16), wa
	ld a, 0x15:opc
	calr AccPatch_SetVoiceParam
	ld (0x336a:16), wa
	ld a, 0x16:opc
	calr AccPatch_SetVoiceParam
	ld (0x336c:16), wa
	ld a, 0x17:opc
	calr AccPatch_SetVoiceParam
	ld (0x336e:16), wa

AccPatch_NullReturn:
	ret


; --- Rhythm, Accompaniment & Factory Defaults ---
