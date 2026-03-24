; =============================================================================
; Rhythm Pattern Routines
; =============================================================================
;
; Rhythm pattern comparison, trigger logic, and transposition.
; Evaluates accompaniment pattern matching and rhythm dispatch.
; =============================================================================

Rhythm_CompareAndTrigger:
	bitda 0, 0x3283
	jrl z, Rhythm_SaveNoteState
	bitda 6, 0x28AC
	jr z, Rhythm_CompareAndTriggerNotes
	bitda 2, 1057
	jr z, Rhythm_CompareAndTriggerNotes
	ldda8 a, 0x327F
	cp a, 0x12
	jr ule, Rhythm_CompareAndTriggerNotes
	cp a, 0x5c
	jr ugt, Rhythm_CompareAndTriggerNotes
	jrl Rhythm_SaveNoteState

Rhythm_CompareAndTriggerNotes:
	bitda 1, 0x32D7
	jr nz, Rhythm_CompareNoteA_Only
	ldda8 a, 0x32D8
	ldda8 w, 0x32D9
	ldda8 l, 0x32DF
	ldda8 h, 0x32E0
	cp wa, hl
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteA_Only:
	ldda8 a, 0x32D8
	ldda8 w, 0x32DF
	cp a, w
	jr z, Rhythm_CompareNoteB
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteB:
	ldda8 a, 0x32D9
	ldda8 w, 0x32E0
	cp a, w
	jr z, Rhythm_CompareNoteC
	calr Rhythm_NoteOnAfterSetup_B

Rhythm_CompareNoteC:
	ldda8 a, 0x32DA
	ldda8 w, 0x32E1
	cp a, w
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_C

Rhythm_SaveCurrentNoteState:
	ldda8 a, 0x32D8
	stda8 0x32DF, a
	ldda8 a, 0x32D9
	stda8 0x32E0, a
	ldda8 a, 0x32DA
	stda8 0x32E1, a

Rhythm_SaveNoteState:
	ldda8 a, 0x32D8
	stda8 0x32DC, a
	ldda8 a, 0x32D9
	stda8 0x32DD, a
	ldda8 a, 0x32DA
	stda8 0x32DE, a
	ldda8 a, 0x32D7
	stda8 0x32DB, a
	ret

Rhythm_NoteOnAfterSetup_A:
	calr Rhythm_SetupAllChannels
	calr Rhythm_AllNotesOff_Dispatch
	calr Rhythm_Send_Ch90_7F_7E
	calr Rhythm_NoteOffMax_Dispatch
	calr Rhythm_FourChannelDispatch
	calr Rhythm_SendVolume_Dispatch
	ldb a, 0x90
	call Rhythm_SendByte
	ldb a, 0x7f
	call Rhythm_SendByte
	ldb a, 0x7d
	call Rhythm_SendByte
	ret

Rhythm_NoteOnAfterSetup_B:
	calr Rhythm_SetupChannel_D4
	calr Rhythm_SetupChannel_D5
	calr Rhythm_SetupChannel_D6
	calr Rhythm_AllNotesOff_D4
	calr Rhythm_AllNotesOff_D5
	calr Rhythm_AllNotesOff_D6
	calr Rhythm_Send_Ch90_7F_04
	calr Rhythm_Send_Ch90_7F_05
	calr Rhythm_Send_Ch90_7F_06
	calr Rhythm_NoteOffMax_D4
	calr Rhythm_NoteOffMax_D5
	calr Rhythm_NoteOffMax_D6
	calr Rhythm_DispatchCh_D4
	calr Rhythm_DispatchCh_D5
	calr Rhythm_DispatchCh_D6
	calr Rhythm_SendVolume_D4
	calr Rhythm_SendVolume_D5
	calr Rhythm_SendVolume_D6
	ldb a, 0x90
	call Rhythm_SendByte
	ldb a, 0x7f
	call Rhythm_SendByte
	ldb a, 0x7d
	call Rhythm_SendByte
	ret

Rhythm_NoteOnAfterSetup_C:
	calr Rhythm_SetupChannel_D7
	calr Rhythm_AllNotesOff_D7
	calr Rhythm_Send_Ch90_7F_07
	calr Rhythm_NoteOffMax_D7
	calr Rhythm_DispatchCh_D7
	call Rhythm_SendVolume_D7
	ldb a, 0x90
	call Rhythm_SendByte
	ldb a, 0x7f
	call Rhythm_SendByte
	ldb a, 0x7d
	call Rhythm_SendByte
	ret

Rhythm_SetupAllChannels:
	calr Rhythm_SetupChannel_D7
	calr Rhythm_SetupChannel_D4
	calr Rhythm_SetupChannel_D5
	calr Rhythm_SetupChannel_D6
	ret

Rhythm_SetupChannel_D7:
	ld xhl, 0x2c94
	ldda8 a, 0x32C3
	stda8 0x32CB, a
	ldda8 a, 0x32C7
	stda8 0x32CC, a
	anddi8 0x32F4, 251
	ordi8 0x32F4, 8
	stdi8 0x33D4, 4
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D4:
	ld xhl, 0x2d94
	ldda8 a, 0x32C4
	stda8 0x32CB, a
	ldda8 a, 0x32C8
	stda8 0x32CC, a
	anddi8 0x32F4, 247
	ordi8 0x32F4, 4
	stdi8 0x33D4, 8
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D5:
	ld xhl, 0x2e94
	ldda8 a, 0x32C5
	stda8 0x32CB, a
	ldda8 a, 0x32C9
	stda8 0x32CC, a
	anddi8 0x32F4, 243
	stdi8 0x33D4, 16
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D6:
	ld xhl, 0x2f94
	ldda8 a, 0x32C6
	stda8 0x32CB, a
	ldda8 a, 0x32CA
	stda8 0x32CC, a
	anddi8 0x32F4, 243
	stdi8 0x33D4, 32
	calr RhythmEvt_ProcessNote
	ret

RhythmEvt_ProcessNote:
	cpdi8 0x32E5, 240
	jr c, RhythmEvt_AlternateProcess
	ldda8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	andda8 a, 0x33D4
	jr nz, RhythmEvt_AlternateProcess
	ldda8 a, 0x32DF
	stda8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 0x3422
	stda8 0x3424, a
	ldda8 a, 0x32D8
	stda8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 0x3422
	cpdm8 0x3424, a
	jr nz, RhythmEvt_AlternateProcess
	call RhythmEvt_IterateNoteOn
	jr RhythmEvt_Return

RhythmEvt_AlternateProcess:
	call RhythmEvt_FullProcess

RhythmEvt_Return:
	ret

RhythmEvt_IterateNoteOn:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

RhythmEvt_NoteOnLoop:
	cp (xhl + 4), iy
	jrl z, RhythmEvt_IterDone
	ld_srib3 A, 0x07, 0xec, 0xf4
	stda16 0x345D, xiy
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	cp a, 0x90
	jr z, RhythmEvt_NoteOn90
	cp a, 0x91
	jr z, RhythmEvt_NoteOn91
	jr RhythmEvt_SkipUnknown

RhythmEvt_NoteOn90:
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	jr RhythmEvt_ApplyTranspose

RhythmEvt_NoteOn91:
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition

RhythmEvt_ApplyTranspose:
	ld_srib3 A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, RhythmEvt_PostProcess
	bitda 3, 0x32F4
	jr z, RhythmEvt_ApplyNoteRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_ApplyNoteRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_PostProcess:
	calr Rhythm_VelocityCompute
	popw iy
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_NoteOnLoop

RhythmEvt_SkipUnknown:
	popw iy
	ldda16 xiy, 0x345D
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_NoteOnLoop

RhythmEvt_IterDone:
	ret

RhythmEvt_FullProcess:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

RhythmEvt_FullLoop:
	cp (xhl + 4), iy
	jrl z, RhythmEvt_FullDone
	ld_srib3 A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, RhythmEvt_Full91
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, RhythmEvt_Full90_PostTransp
	bitda 3, 0x32F4
	jr z, RhythmEvt_Full90_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full90_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full90_PostTransp:
	calr Rhythm_VelocityLookup_A
	popw iy
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_FullLoop

RhythmEvt_Full91:
	cp a, 0x91
	jr nz, RhythmEvt_FullSkip
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xec, 0xf4
	stda8 0x3430, a
	calr Rhythm_AdvancePosition
	ld_srib3 A, 0x07, 0xec, 0xf4
	stda8 0x3433, a
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xec, 0xf4
	stda8 0x3434, a
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, RhythmEvt_Full91_PostTransp
	bitda 3, 0x32F4
	jr z, RhythmEvt_Full91_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	calr Rhythm_VoiceMapLookup
	popw iy
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldda8 a, 0x3430
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition
	jrl RhythmEvt_FullLoop

RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	anddi8 0x32F4, 239
	cp a, 0x78
	jr c, Rhythm_VelThreshReturn
	ordi8 0x32F4, 16

Rhythm_VelThreshReturn:
	ret

Rhythm_AdvancePosition:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvancePos_Step2
	ld iy, (xhl + 256)
	inc 2, iy
	jr Rhythm_AdvanceDone

Rhythm_AdvancePos_Step2:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvancePos_Step3
	ld iy, (xhl + 256)
	inc 1, iy
	jr Rhythm_AdvanceDone

Rhythm_AdvancePos_Step3:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvanceDone
	ld iy, (xhl + 256)

Rhythm_AdvanceDone:
	ret

Rhythm_CrossVoiceCorrect:
	bitda 0, 0x32D7
	jr nz, Rhythm_CrossVoice_Apply
	bitda 1, 0x32D7
	jr nz, Rhythm_CrossVoice_Apply
	ldda8 w, 0x3316
	orda8 w, 0x3317
	orda8 w, 0x3318
	and w, 0x3f
	jr nz, Rhythm_CrossVoice_ClearFlag
	bitda 5, 0x32F3
	jr z, Rhythm_CrossVoice_ClearFlag

Rhythm_CrossVoice_Apply:
	push xiy
	ld w, a
	addda8 w, 0x32CB
	inc 1, w
	sub w, 0xc
	stda8 0x332E, w
	ordi8 0x332D, 1
	ld xiy, 0xe46142
	ld_srib3 W, 0x03, 0xf4, 0xe0
	sub a, w
	pop xiy
	stdi8 0x3433, 0
	stdi8 0x3434, 0

Rhythm_CrossVoice_ClearFlag:
	anddi8 0x32F3, 223
	ret

Rhythm_NoteRangeCheck:
	bitda 0, 0x32D7
	jr z, Rhythm_NoteRangeReturn
	push xiy
	ld w, a
	ld xiy, 0xe46142
	ld_srib3 W, 0x03, 0xf4, 0xe0
	sub a, w
	pop xiy
	stdi8 0x3433, 0
	stdi8 0x3434, 0

Rhythm_NoteRangeReturn:
	ret

Rhythm_NoteRangeData:
	.byte 0x00, 0x00

Rhythm_VelocityLookup_A:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cpdi8 0x32D8, 0
	jr nz, Rhythm_VelLookA_CheckEmpty
	ldb a, 0x0
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckEmpty:
	bitda 4, 0x32F4
	jr z, Rhythm_VelLookA_CheckRange
	anddi8 0x32F4, 239
	ld a, w
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckRange:
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_VelLookA_SelectTable
	xor l, l

Rhythm_VelLookA_SelectTable:
	ld xiy, Rhythm_InstrMapTable_Default
	bitda 2, 0x32F4
	jr z, Rhythm_VelLookA_CheckBit3
	ld xiy, 0xf550fb

Rhythm_VelLookA_CheckBit3:
	bitda 3, 0x32F4
	jr z, Rhythm_VelLookA_TableLookup
	ld xiy, 0xf5512c

Rhythm_VelLookA_TableLookup:
	ld_srib3 L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, 0xe461c2
	st_dri3b E, 0x07, 0xf4, 0xec
	ld_srib3 A, 0x03, 0xf4, 0xe0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelLookA_Done:
	pop xhl
	pop xiy
	ret

Rhythm_InstrBaseLookup:
	push xiy
	ld xiy, 0xe46142
	st_dri3b E, 0x03, 0xf4, 0xe0
	ld a, (xiy)
	pop xiy
	ret

Rhythm_InstrMapTable_Default:
	.byte 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x03, 0x09
	.byte 0x0a, 0x07, 0x04, 0x02, 0x05, 0x06, 0x06, 0x00
	.byte 0x00, 0x01, 0x02, 0x08, 0x0a, 0x03, 0x08, 0x04
	.byte 0x00, 0x12, 0x13, 0x14, 0x00, 0x05, 0x00, 0x00
	.byte 0x05, 0x00, 0x00, 0x01, 0x01, 0x06, 0x04, 0x05
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x03
	.byte 0x09, 0x0a, 0x07, 0x04, 0x02, 0x05, 0x06, 0x06
	.byte 0x0b, 0x0c, 0x0e, 0x0f, 0x08, 0x0a, 0x10, 0x11
	.byte 0x04, 0x0d, 0x12, 0x13, 0x14, 0x00, 0x05, 0x0c
	.byte 0x0d, 0x05, 0x0c, 0x0d, 0x01, 0x01, 0x06, 0x04
	.byte 0x05, 0x0b, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00
	.byte 0x03, 0x09, 0x0a, 0x07, 0x04, 0x02, 0x05, 0x06
	.byte 0x06, 0x00, 0x00, 0x01, 0x02, 0x08, 0x0a, 0x03
	.byte 0x08, 0x04, 0x00, 0x12, 0x13, 0x14, 0x00, 0x05
	.byte 0x00, 0x00, 0x05, 0x00, 0x00, 0x01, 0x01, 0x06
	.byte 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00

Rhythm_TransposeNote:
	ldda8 a, 0x32D9
	bitda 3, 0x32F4
	jr z, Rhythm_Transp_CheckZero
	ldda8 a, 0x32DA

Rhythm_Transp_CheckZero:
	cps a, 0
	jr nz, Rhythm_Transp_Apply
	ldb a, 0x0
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	dec 1, a
	cpda8 a, 0x32CB
	jr ugt, Rhythm_Transp_NegativeOctave
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_JumpToWrap
	sub w, 0xc

Rhythm_Transp_JumpToWrap:
	jr Rhythm_Transp_WrapCheck

Rhythm_Transp_NegativeOctave:
	sub a, 0xc
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_WrapCheck
	add w, 0xc

Rhythm_Transp_WrapCheck:
	cpdi8 0x32CC, 12
	jr c, Rhythm_Transp_FinalCheck

Rhythm_Transp_WrapLoop:
	cpda8 w, 0x32CC
	jr c, Rhythm_Transp_FinalCheck
	sub w, 0xc
	jr Rhythm_Transp_WrapLoop

Rhythm_Transp_FinalCheck:
	ld a, w
	bitda 0, 0x332D
	jr z, Rhythm_Transp_Done
	cpda8 a, 0x332E
	jr nc, Rhythm_Transp_Done
	add a, 0xc

Rhythm_Transp_Done:
	anddi8 0x332D, 254
	ret

Rhythm_VoiceMapLookup:
	push xiy
	push xhl
	cpdi8 0x32D8, 0
	jr nz, Rhythm_VoiceMap_CheckInstr
	ldb a, 0x0
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckInstr:
	bitda 4, 0x32F4
	jr z, Rhythm_VoiceMap_CheckBit4
	anddi8 0x32F4, 239
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckBit4:
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_VoiceMap_ClampInstr
	xor l, l

Rhythm_VoiceMap_ClampInstr:
	ld xiy, Rhythm_PitchShiftTable_Default
	bitda 3, 0x32F4
	jr z, Rhythm_VoiceMap_SelectTable
	ld xiy, 0xf552a0

Rhythm_VoiceMap_SelectTable:
	ld_srib3 L, 0x03, 0xf4, 0xec
	cps l, 0
	jr z, Rhythm_VoiceMap_ApplyBase
	ldda8 h, 0x3433
	cps l, 1
	jr z, Rhythm_VoiceMap_CheckMute
	ldda8 h, 0x3434

Rhythm_VoiceMap_CheckMute:
	bit 5, h
	jr z, Rhythm_VoiceMap_CheckDir
	ldb a, 0x0
	jr Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckDir:
	bit 4, h
	jr nz, Rhythm_VoiceMap_SubShift
	and h, 0xf
	add a, h
	jr Rhythm_VoiceMap_ApplyBase

Rhythm_VoiceMap_SubShift:
	and h, 0xf
	sub a, h

Rhythm_VoiceMap_ApplyBase:
	ld w, a
	calr Rhythm_InstrBaseLookup
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_VoiceMap_Inst2Clamp
	xor l, l

Rhythm_VoiceMap_Inst2Clamp:
	ld xiy, Rhythm_InstrMapTable_Default
	bitda 2, 0x32F4
	jr z, Rhythm_VoiceMap_Inst2Bit2
	ld xiy, 0xf550fb

Rhythm_VoiceMap_Inst2Bit2:
	bitda 3, 0x32F4
	jr z, Rhythm_VoiceMap_Inst2Bit3
	ld xiy, 0xf5512c

Rhythm_VoiceMap_Inst2Bit3:
	ld_srib3 L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, 0xe461c2
	st_dri3b E, 0x07, 0xf4, 0xec
	ld_srib3 A, 0x03, 0xf4, 0xe0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VoiceMap_Done:
	pop xhl
	pop xiy
	ret

Rhythm_PitchShiftTable_Default:
	.byte 0x00, 0x00, 0x01, 0x01, 0x00, 0x02, 0x01, 0x01
	.byte 0x02, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01
	.byte 0x01, 0x01, 0x01, 0x01, 0x02, 0x01, 0x01, 0x00
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01
	.fill 8, 1, 0x01
	.byte 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x02, 0x01
	.byte 0x01, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00, 0x01
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x01, 0x01
	.byte 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.fill 8, 1, 0x01
	.byte 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00

Rhythm_VelocityCompute:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cpdi8 0x32D8, 0
	jr nz, Rhythm_VelComp_CheckBit4
	ldb a, 0x0
	jr Rhythm_VelComp_Done

Rhythm_VelComp_CheckBit4:
	bitda 4, 0x32F4
	jr z, Rhythm_VelComp_ClampInstr
	anddi8 0x32F4, 239
	ld a, w
	jr Rhythm_VelComp_Done

Rhythm_VelComp_ClampInstr:
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_VelComp_SelectTable
	xor l, l

Rhythm_VelComp_SelectTable:
	ld xiy, Rhythm_VelocityTable_A
	bitda 2, 0x32F4
	jr z, Rhythm_VelComp_Lookup
	ld xiy, 0xf5535f

Rhythm_VelComp_Lookup:
	ld_srib3 L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, 0xe461c2
	st_dri3b E, 0x07, 0xf4, 0xec
	ld_srib3 A, 0x03, 0xf4, 0xe0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelComp_Done:
	pop xhl
	pop xiy
	ret

Rhythm_VelocityTable_A:
	.byte 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x03, 0x00
	.byte 0x0a, 0x07, 0x04, 0x02, 0x05, 0x06, 0x06, 0x00
	.byte 0x00, 0x01, 0x02, 0x08, 0x0a, 0x03, 0x08, 0x04
	.byte 0x00, 0x12, 0x13, 0x14, 0x00, 0x05, 0x00, 0x00
	.byte 0x05, 0x00, 0x00, 0x01, 0x01, 0x06, 0x04, 0x05
	.zero 8
	.byte 0x00, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x03
	.byte 0x00, 0x0a, 0x07, 0x04, 0x02, 0x05, 0x06, 0x06
	.byte 0x0b, 0x0c, 0x0e, 0x0f, 0x08, 0x0a, 0x10, 0x11
	.byte 0x04, 0x0d, 0x12, 0x13, 0x14, 0x00, 0x05, 0x0c
	.byte 0x0d, 0x05, 0x0c, 0x0d, 0x01, 0x01, 0x06, 0x04
	.byte 0x05, 0x0b, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00

Rhythm_FourChannelDispatch:
	calr Rhythm_DispatchCh_D7
	calr Rhythm_DispatchCh_D4
	calr Rhythm_DispatchCh_D5
	calr Rhythm_DispatchCh_D6
	ret

Rhythm_DispatchCh_D7:
	ldda8 a, 0x32C3
	stda8 0x32CB, a
	ldda8 a, 0x32C7
	stda8 0x32CC, a
	anddi8 0x32F4, 251
	ordi8 0x32F4, 8
	ldb w, 0x97
	ld xix, 0x30f4

Rhythm_DispatchCh_D7_Loop:
	stdi8 0x33D4, 4
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x313c
	jr c, Rhythm_DispatchCh_D7_Loop
	ret

Rhythm_DispatchCh_D4:
	ldda8 a, 0x32C4
	stda8 0x32CB, a
	ldda8 a, 0x32C8
	stda8 0x32CC, a
	anddi8 0x32F4, 247
	ordi8 0x32F4, 4
	ldb w, 0x94
	ld xix, 0x313c

Rhythm_DispatchCh_D4_Loop:
	stdi8 0x33D4, 8
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x3184
	jr c, Rhythm_DispatchCh_D4_Loop
	ret

Rhythm_DispatchCh_D5:
	ldda8 a, 0x32C5
	stda8 0x32CB, a
	ldda8 a, 0x32C9
	stda8 0x32CC, a
	anddi8 0x32F4, 243
	ldb w, 0x95
	ld xix, 0x3184

Rhythm_DispatchCh_D5_Loop:
	stdi8 0x33D4, 16
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x31cc
	jr c, Rhythm_DispatchCh_D5_Loop
	ret

Rhythm_DispatchCh_D6:
	ldda8 a, 0x32C6
	stda8 0x32CB, a
	ldda8 a, 0x32CA
	stda8 0x32CC, a
	anddi8 0x32F4, 243
	ldb w, 0x96
	ld xix, 0x31cc

Rhythm_DispatchCh_D6_Loop:
	stdi8 0x33D4, 32
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x3214
	jr c, Rhythm_DispatchCh_D6_Loop
	ret

Rhythm_SingleNoteHandler:
	ld a, (xix)
	bit 7, a
	jr z, Rhythm_SingleNote_Return
	ld a, w
	call Rhythm_SendByte
	calr Rhythm_ValidateAndSend
	ld a, (xix + 2)
	call Rhythm_SendByte
	ld a, (xix + 3)
	sub a, 0x10
	cps a, 0
	jr gt, Rhythm_SingleNote_ClampVelocity
	ldb a, 0x1

Rhythm_SingleNote_ClampVelocity:
	call Rhythm_SendByte

Rhythm_SingleNote_Return:
	ret

Rhythm_SendByte:
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	pushw wa
	pushw wa
	call RhythmBuf_WriteByte
	inc 2, xsp
	popw wa
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	ret

Rhythm_ValidateAndSend:
	cpdi8 0x32E5, 240
	jr c, Rhythm_Validate_Mismatch
	ldda8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	andda8 a, 0x33D4
	jr nz, Rhythm_Validate_Mismatch
	ldda8 a, 0x32DF
	stda8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 0x3422
	stda8 0x3424, a
	ldda8 a, 0x32D8
	stda8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 0x3422
	cpdm8 0x3424, a
	jr nz, Rhythm_Validate_Mismatch
	calr Rhythm_MatchedPhrase
	jr Rhythm_Validate_Done

Rhythm_Validate_Mismatch:
	calr Rhythm_MismatchedPhrase

Rhythm_Validate_Done:
	ret

Rhythm_MatchedPhrase:
	pushw wa
	ld a, (xix)
	cp a, 0x90
	jr nz, Rhythm_MatchedPhrase_NonNote
	ld a, (xix + 6)
	jr Rhythm_MatchedPhrase_Process

Rhythm_MatchedPhrase_NonNote:
	ld a, (xix + 8)

Rhythm_MatchedPhrase_Process:
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, Rhythm_MatchedPhrase_Output
	bitda 3, 0x32F4
	jr z, Rhythm_MatchedPhrase_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_MatchedPhrase_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MatchedPhrase_Output:
	calr Rhythm_VelocityCompute
	ld (xix + 2), a
	popw wa
	ret

Rhythm_MismatchedPhrase:
	ld a, (xix)
	cp a, 0x90
	jr nz, Rhythm_MismatchOther
	pushw wa
	ld a, (xix + 6)
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, Rhythm_Mismatch90_Output
	bitda 3, 0x32F4
	jr z, Rhythm_Mismatch90_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_Mismatch90_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_Mismatch90_Output:
	calr Rhythm_VelocityLookup_A
	ld (xix + 2), a
	popw wa
	jr Rhythm_MismatchOther_Return

Rhythm_MismatchOther:
	pushw wa
	ld a, (xix + 3)
	stda8 0x3430, a
	ld a, (xix + 6)
	stda8 0x3433, a
	ld a, (xix + 7)
	stda8 0x3434, a
	ld a, (xix + 8)
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32F4
	jr nz, Rhythm_MismatchOther_Output
	bitda 3, 0x32F4
	jr z, Rhythm_MismatchOther_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	calr Rhythm_VoiceMapLookup
	ld (xix + 2), a
	ldda8 a, 0x3430
	ld (xix + 3), a
	popw wa

Rhythm_MismatchOther_Return:
	ret

Rhythm_Send_Ch90_7F_7E:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x7e
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_04:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x4
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_05:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x5
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_06:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x6
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_07:
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x7
	call Rhythm_Send3ByteMsg
	ret

Rhythm_AllNotesOff_Dispatch:
	calr Rhythm_AllNotesOff_D7
	calr Rhythm_AllNotesOff_D4
	calr Rhythm_AllNotesOff_D5
	calr Rhythm_AllNotesOff_D6
	ret

Rhythm_AllNotesOff_D7:
	cpdi8 0x332F, 0
	jr z, Rhythm_AllNotesOff_D7_Skip
	ldb a, 0xd7
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D7_Skip:
	ret

Rhythm_AllNotesOff_D4:
	cpdi8 0x3330, 0
	jr z, Rhythm_AllNotesOff_D4_Skip
	ldb a, 0xd4
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D4_Skip:
	ret

Rhythm_AllNotesOff_D5:
	cpdi8 0x3331, 0
	jr z, Rhythm_AllNotesOff_D5_Skip
	ldb a, 0xd5
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D5_Skip:
	ret

Rhythm_AllNotesOff_D6:
	cpdi8 0x3332, 0
	jr z, Rhythm_AllNotesOff_D6_Done
	ldb a, 0xd6
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D6_Done:
	ret

Rhythm_SendVolume_Dispatch:
	calr Rhythm_SendVolume_D7
	calr Rhythm_SendVolume_D4
	calr Rhythm_SendVolume_D5
	calr Rhythm_SendVolume_D6
	ret

Rhythm_SendVolume_D7:
	cpdi8 0x332F, 0
	jr z, Rhythm_SendVolume_D7_Skip
	ldb a, 0xd7
	ldb w, 0x3
	ldda8 e, 0x332F
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	cpdi8 0x3330, 0
	jr z, Rhythm_SendVolume_D4_Skip
	ldb a, 0xd4
	ldb w, 0x3
	ldda8 e, 0x3330
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	cpdi8 0x3331, 0
	jr z, Rhythm_SendVolume_D5_Skip
	ldb a, 0xd5
	ldb w, 0x3
	ldda8 e, 0x3331
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	cpdi8 0x3332, 0
	jr z, Rhythm_SendVolume_D6_Done
	ldb a, 0xd6
	ldb w, 0x3
	ldda8 e, 0x3332
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D6_Done:
	ret

Rhythm_NoteOffMax_Dispatch:
	calr Rhythm_NoteOffMax_D7
	calr Rhythm_NoteOffMax_D4
	calr Rhythm_NoteOffMax_D5
	calr Rhythm_NoteOffMax_D6
	ret

Rhythm_NoteOffMax_D7:
	cpdi8 0x332F, 0
	jr z, Rhythm_NoteOffMax_D7_Skip
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x77
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D7_Skip:
	ret

Rhythm_NoteOffMax_D4:
	cpdi8 0x3330, 0
	jr z, Rhythm_NoteOffMax_D4_Skip
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x74
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D4_Skip:
	ret

Rhythm_NoteOffMax_D5:
	cpdi8 0x3331, 0
	jr z, Rhythm_NoteOffMax_D5_Skip
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x75
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D5_Skip:
	ret

Rhythm_NoteOffMax_D6:
	cpdi8 0x3332, 0
	jr z, Rhythm_NoteOffMax_D6_Done
	ldb a, 0x90
	ldb w, 0x7f
	ldb e, 0x76
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D6_Done:
	ret

Rhythm_AdvanceTick:
	ldda16 xwa, 0x32E3
	stda8 0x3356, w
	ldda8 a, 0x327F
	ldda8 w, 0x3280
	stda8 0x3425, w
	add a, 0x18
	cp a, 0x60
	jr c, Rhythm_AdvanceTick_Store
	sub a, 0x60
	inc 1, w
	cpda8 w, 1112
	jr c, Rhythm_AdvanceTick_Store
	xor w, w

Rhythm_AdvanceTick_Store:
	stda16 0x32E3, xwa
	ret

Rhythm_SaveState:
	ldda8 a, 0x32F5
	stda8 0x32F6, a
	ldda8 a, 0x32F7
	stda8 0x32F8, a
	ldda8 a, 0x32F9
	stda8 0x32FA, a
	ldda8 a, 0x32FB
	stda8 0x32FC, a
	ldda8 a, 0x32FF
	stda8 0x3300, a
	ldda8 a, 0x32FD
	stda8 0x32FE, a
	ldda8 a, 0x3301
	stda8 0x3302, a
	ldda8 a, 0x3303
	stda8 0x3304, a
	ldda8 a, 0x3305
	stda8 0x3306, a
	ldda8 a, 0x3307
	stda8 0x3308, a
	ldda8 a, 0x3470
	stda8 0x3281, a
	ldda8 a, 0x8D34
	stda8 0x32F1, a
	ldda8 a, 0x3335
	stda8 0x32F2, a
	ldda8 a, 0x33E8
	stda8 0x33E9, a
	ldda8 a, 0x3283
	and a, 0xfd
	bit 0, a
	jr z, Rhythm_SaveState_StoreBits
	or a, 0x2

Rhythm_SaveState_StoreBits:
	stda8 0x3283, a
	ordi8 0x32F3, 1
	cpdi8 0x3280, 0
	jr nz, Rhythm_SaveState_CheckFx
	cpdi8 0x327F, 48
	jr c, Rhythm_SaveState_CheckFx
	anddi8 0x3329, 192

Rhythm_SaveState_CheckFx:
	ldda8 a, 0x330B
	and a, 0x3
	jr nz, Rhythm_SaveState_FxActive
	bitda 0, 0x330C
	jr z, Rhythm_SaveState_ClearFx

Rhythm_SaveState_FxActive:
	ldda8 a, 0x3326
	and a, 0x3f
	jr nz, Rhythm_SaveState_CheckFx2
	anddi8 0x330B, 252
	anddi8 0x330C, 254
	jr Rhythm_SaveState_CheckFx2

Rhythm_SaveState_ClearFx:
	anddi8 0x3326, 192

Rhythm_SaveState_CheckFx2:
	ldda8 a, 0x3309
	and a, 0x3
	jr nz, Rhythm_SaveState_Fx2Active
	ldda8 a, 0x330A
	and a, 0xd
	jr z, Rhythm_SaveState_ClearFx2

Rhythm_SaveState_Fx2Active:
	ldda8 a, 0x3327
	and a, 0x3f
	jr nz, Rhythm_VoiceAssignDetect
	and a, 0xfc
	and a, 0xf2
	jr Rhythm_VoiceAssignDetect

Rhythm_SaveState_ClearFx2:
	anddi8 0x3327, 192

Rhythm_VoiceAssignDetect:
	ldda8 a, 0x3312
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ldda8 a, 0x3319
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBDetect
	anddi8 0xFC5F, 191
	ldda8 a, 0x3313
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartAOn
	ordi8 0xFC5F, 128
	ordi8 0x32FC, 2

Rhythm_VoiceAssign_PartAOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32FC, 254
	anddi8 0x332B, 253
	ldda8 a, 0x3313
	orda8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ordi8 0x3284, 16
	ordi8 0x3284, 4

Rhythm_VoiceAssign_PartBDetect:
	ldda8 a, 0x3313
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ldda8 a, 0x331A
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext1Detect
	anddi8 0xFC5F, 127
	ldda8 a, 0x3312
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBOn
	ordi8 0xFC5F, 64
	ordi8 0x32FC, 1

Rhythm_VoiceAssign_PartBOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32FC, 253
	anddi8 0x332B, 251
	ldda8 a, 0x3312
	orda8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ordi8 0x3284, 16
	ordi8 0x3284, 4

Rhythm_VoiceAssign_Ext1Detect:
	ldda8 a, 0x3316
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ldda8 a, 0x331D
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext2Detect
	anddi8 0xFC5F, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 254
	ldda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Ext2Detect:
	ldda8 a, 0x3317
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ldda8 a, 0x331E
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext3Detect
	anddi8 0xFC5F, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 253
	ldda8 a, 0x3316
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Ext3Detect:
	ldda8 a, 0x3318
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ldda8 a, 0x331F
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc1Detect
	anddi8 0xFC60, 251
	ldb e, 0x48
	ldb d, 0x6
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 251
	ldda8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Perc1Detect:
	ldda8 a, 0x3314
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc2Detect
	ldda8 a, 0x331B
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc2Detect
	anddi8 0xFC5F, 239
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32FD, 254
	ordi8 0x3284, 4

Rhythm_VoiceAssign_Perc2Detect:
	ldda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_SaveShadow
	ldda8 a, 0x331C
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_SaveShadow
	anddi8 0xFC5F, 223
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32FD, 253
	ordi8 0x3284, 4

Rhythm_VoiceAssign_SaveShadow:
	ldda8 a, 0x3312
	stda8 0x3319, a
	ldda8 a, 0x3313
	stda8 0x331A, a
	ldda8 a, 0x3316
	stda8 0x331D, a
	ldda8 a, 0x3317
	stda8 0x331E, a
	ldda8 a, 0x3318
	stda8 0x331F, a
	ldda8 a, 0x3314
	stda8 0x331B, a
	ldda8 a, 0x3315
	stda8 0x331C, a
	ldda8 a, 0x32E5
	stda8 0x3370, a
	ldda8 a, 0x333C
	stda8 0x333E, a
	call AccTuning_SaveState
	calr Rhythm_SeqResetCheck
	ret

Rhythm_SeqResetCheck:
	bitda 2, 0x34CF
	jr z, Rhythm_SeqReset_UpdateFlags
	bitda 4, 0x34CF
	jr nz, Rhythm_SeqReset_UpdateFlags
	ldda8 l, 0x379B
	xor h, h
	sla l, 2
	ld xiy, Rhythm_SeqResetTable
	ld_sril3 XIX, 0x07, 0xf4, 0xec
	cp xix, 0x0
	jr z, Rhythm_SeqReset_UpdateFlags
	ei 6
	ld hl, (xix + 6)
	ld (xix + 4), hl
	ei 0

Rhythm_SeqReset_UpdateFlags:
	ldda8 a, 0x34CF
	and a, 0xef
	bit 2, a
	jr z, Rhythm_SeqReset_Store
	or a, 0x10

Rhythm_SeqReset_Store:
	stda8 0x34CF, a
	ret

Rhythm_SeqResetTable:
	.byte 0x00, 0x00, 0x00, 0x00, 0x94, 0x2d, 0x00, 0x00
	.byte 0x94, 0x2e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x94, 0x2f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 8
	.byte 0x94, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.zero 24
	.byte 0x94, 0x2a, 0x00, 0x00

Rhythm_TransposeWithMod:
	cpdi8 0x32D8, 0
	jr z, Rhythm_TranspMod_Return
	cpdi8 0x32D9, 0
	jr z, Rhythm_TranspMod_Return
	bitda 2, 0x33E5
	jr nz, Rhythm_TranspMod_Return
	bitda 1, 0x33E5
	jr z, Rhythm_TranspMod_ApplyBoth
	calr Rhythm_TranspMod_ModCheck
	bitda 0, 0x33E5
	jr nz, Rhythm_TranspMod_Return

Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	anddi8 0x33E5, 254
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_TranspMod_LookupTable
	xor l, l

Rhythm_TranspMod_LookupTable:
	ld xiy, Rhythm_PitchShiftTable_Default
	ld_srib3 L, 0x03, 0xf4, 0xec
	cps l, 0
	jr z, Rhythm_TranspMod_Done
	ldda8 h, 0x33E6
	cps l, 1
	jr z, Rhythm_TranspMod_Offset1
	ldda8 h, 0x33E7

Rhythm_TranspMod_Offset1:
	bit 5, h
	jr z, Rhythm_TranspMod_MuteCheck
	ldb a, 0x0
	ordi8 0x33E5, 1
	jr Rhythm_TranspMod_Done

Rhythm_TranspMod_MuteCheck:
	bit 4, h
	jr nz, Rhythm_TranspMod_SubOffset
	and h, 0xf
	add a, h
	jr Rhythm_TranspMod_Done

Rhythm_TranspMod_SubOffset:
	and h, 0xf
	sub a, h

Rhythm_TranspMod_Done:
	ret

Rhythm_TranspMod_BaseApply:
	ld w, a
	ld xiy, 0xe46142
	ld_srib3 A, 0x03, 0xf4, 0xe0
	ldda8 l, 0x32D8
	cp l, 0x30
	jr c, Rhythm_TranspMod_BaseLookup
	xor l, l

Rhythm_TranspMod_BaseLookup:
	extz hl
	ld xiy, 0xf550fb
	ld_srib3 L, 0x07, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, 0xe461c2
	st_dri3b E, 0x07, 0xf4, 0xec
	ld_srib3 A, 0x03, 0xf4, 0xe0
	add w, a
	ret

Rhythm_TranspMod_OctaveWrap:
	ldda8 a, 0x32D9
	dec 1, a
	cps a, 7
	jr nc, Rhythm_TranspMod_WrapNeg
	add w, a
	bit 7, w
	jr z, Rhythm_TranspMod_WrapJump
	sub w, 0xc

Rhythm_TranspMod_WrapJump:
	jr Rhythm_TranspMod_WrapClamp

Rhythm_TranspMod_WrapNeg:
	sub a, 0xc
	add w, a
	bit 7, w
	jr z, Rhythm_TranspMod_WrapClamp
	add w, 0xc

Rhythm_TranspMod_WrapClamp:
	cp w, 0x7f
	jr ule, Rhythm_TranspMod_WrapDone
	sub w, 0xc
	jr Rhythm_TranspMod_WrapClamp

Rhythm_TranspMod_WrapDone:
	ld a, w
	ret

Rhythm_TailPadding:
	.byte 0x1d, 0x37, 0x34, 0xf5, 0x0e

