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
	bitda 6, 0x28ac
	jr z, Rhythm_CompareAndTriggerNotes
	bitda 2, 1057
	jr z, Rhythm_CompareAndTriggerNotes
	ldb_d8 a, 0x327f
	cp a, 0x12
	jr ule, Rhythm_CompareAndTriggerNotes
	cp a, 0x5c
	jr ugt, Rhythm_CompareAndTriggerNotes
	jrl Rhythm_SaveNoteState

Rhythm_CompareAndTriggerNotes:
	bitda 1, 0x32d7
	jr nz, Rhythm_CompareNoteA_Only
	ldb_d8 a, 0x32d8
	ldb_d8 w, 0x32d9
	ldb_d8 l, 0x32df
	ldb_d8 h, 0x32e0
	cp wa, hl
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteA_Only:
	ldb_d8 a, 0x32d8
	ldb_d8 w, 0x32df
	cp a, w
	jr z, Rhythm_CompareNoteB
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteB:
	ldb_d8 a, 0x32d9
	ldb_d8 w, 0x32e0
	cp a, w
	jr z, Rhythm_CompareNoteC
	calr Rhythm_NoteOnAfterSetup_B

Rhythm_CompareNoteC:
	ldb_d8 a, 0x32da
	ldb_d8 w, 0x32e1
	cp a, w
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_C

Rhythm_SaveCurrentNoteState:
	ldb_d8 a, 0x32d8
	stb_d8 0x32df, a
	ldb_d8 a, 0x32d9
	stb_d8 0x32e0, a
	ldb_d8 a, 0x32da
	stb_d8 0x32e1, a

Rhythm_SaveNoteState:
	ldb_d8 a, 0x32d8
	stb_d8 0x32dc, a
	ldb_d8 a, 0x32d9
	stb_d8 0x32dd, a
	ldb_d8 a, 0x32da
	stb_d8 0x32de, a
	ldb_d8 a, 0x32d7
	stb_d8 0x32db, a
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
	ldb_d8 a, 0x32c3
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c7
	stb_d8 0x32cc, a
	anddi8 0x32f4, 251
	ordi8 0x32f4, 8
	stdi8 0x33d4, 4
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D4:
	ld xhl, 0x2d94
	ldb_d8 a, 0x32c4
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c8
	stb_d8 0x32cc, a
	anddi8 0x32f4, 247
	ordi8 0x32f4, 4
	stdi8 0x33d4, 8
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D5:
	ld xhl, 0x2e94
	ldb_d8 a, 0x32c5
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c9
	stb_d8 0x32cc, a
	anddi8 0x32f4, 243
	stdi8 0x33d4, 16
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D6:
	ld xhl, 0x2f94
	ldb_d8 a, 0x32c6
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32ca
	stb_d8 0x32cc, a
	anddi8 0x32f4, 243
	stdi8 0x33d4, 32
	calr RhythmEvt_ProcessNote
	ret

RhythmEvt_ProcessNote:
	cpdi8 0x32e5, 240
	jr c, RhythmEvt_AlternateProcess
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	andda8 a, 0x33d4
	jr nz, RhythmEvt_AlternateProcess
	ldb_d8 a, 0x32df
	stb_d8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldb_d8 a, 0x3422
	stb_d8 0x3424, a
	ldb_d8 a, 0x32d8
	stb_d8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldb_d8 a, 0x3422
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
	ldb_sri A, 0x07, 0xec, 0xf4
	stda16 0x345d, xiy
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
	ldb_sri A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32f4
	jr nz, RhythmEvt_PostProcess
	bitda 3, 0x32f4
	jr z, RhythmEvt_ApplyNoteRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_ApplyNoteRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_PostProcess:
	calr Rhythm_VelocityCompute
	popw iy
	lda_dri XBC, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_NoteOnLoop

RhythmEvt_SkipUnknown:
	popw iy
	ldw_d16 xiy, 0x345d
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
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0x90
	jr nz, RhythmEvt_Full91
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32f4
	jr nz, RhythmEvt_Full90_PostTransp
	bitda 3, 0x32f4
	jr z, RhythmEvt_Full90_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full90_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full90_PostTransp:
	calr Rhythm_VelocityLookup_A
	popw iy
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3430, a
	calr Rhythm_AdvancePosition
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3433, a
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	stb_d8 0x3434, a
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32f4
	jr nz, RhythmEvt_Full91_PostTransp
	bitda 3, 0x32f4
	jr z, RhythmEvt_Full91_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	calr Rhythm_VoiceMapLookup
	popw iy
	lda_dri XBC, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ldb_d8 a, 0x3430
	lda_dri XBC, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition
	jrl RhythmEvt_FullLoop

RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	anddi8 0x32f4, 239
	cp a, 0x78
	jr c, Rhythm_VelThreshReturn
	ordi8 0x32f4, 16

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
	bitda 0, 0x32d7
	jr nz, Rhythm_CrossVoice_Apply
	bitda 1, 0x32d7
	jr nz, Rhythm_CrossVoice_Apply
	ldb_d8 w, 0x3316
	orda8 w, 0x3317
	orda8 w, 0x3318
	and w, 0x3f
	jr nz, Rhythm_CrossVoice_ClearFlag
	bitda 5, 0x32f3
	jr z, Rhythm_CrossVoice_ClearFlag

Rhythm_CrossVoice_Apply:
	push xiy
	ld w, a
	addda8 w, 0x32cb
	inc 1, w
	sub w, 0xc
	stb_d8 0x332e, w
	ordi8 0x332d, 1
	ld xiy, Display_FontPalette_Table_0x12EA
	ldb_sri W, 0x03, 0xf4, 0xe0
	sub a, w
	pop xiy
	stdi8 0x3433, 0
	stdi8 0x3434, 0

Rhythm_CrossVoice_ClearFlag:
	anddi8 0x32f3, 223
	ret

Rhythm_NoteRangeCheck:
	bitda 0, 0x32d7
	jr z, Rhythm_NoteRangeReturn
	push xiy
	ld w, a
	ld xiy, Display_FontPalette_Table_0x12EA
	ldb_sri W, 0x03, 0xf4, 0xe0
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
	cpdi8 0x32d8, 0
	jr nz, Rhythm_VelLookA_CheckEmpty
	ldb a, 0x0
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckEmpty:
	bitda 4, 0x32f4
	jr z, Rhythm_VelLookA_CheckRange
	anddi8 0x32f4, 239
	ld a, w
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckRange:
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_VelLookA_SelectTable
	xor l, l

Rhythm_VelLookA_SelectTable:
	ld xiy, Rhythm_InstrMapTable_Default
	bitda 2, 0x32f4
	jr z, Rhythm_VelLookA_CheckBit3
	ld xiy, Rhythm_InstrMapTable_Default_0x31

Rhythm_VelLookA_CheckBit3:
	bitda 3, 0x32f4
	jr z, Rhythm_VelLookA_TableLookup
	ld xiy, Rhythm_InstrMapTable_Default_0x62

Rhythm_VelLookA_TableLookup:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	stb_dri E, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelLookA_Done:
	pop xhl
	pop xiy
	ret

Rhythm_InstrBaseLookup:
	push xiy
	ld xiy, Display_FontPalette_Table_0x12EA
	stb_dri E, 0x03, 0xf4, 0xe0
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
	ldb_d8 a, 0x32d9
	bitda 3, 0x32f4
	jr z, Rhythm_Transp_CheckZero
	ldb_d8 a, 0x32da

Rhythm_Transp_CheckZero:
	cps a, 0
	jr nz, Rhythm_Transp_Apply
	ldb a, 0x0
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	dec 1, a
	cpda8 a, 0x32cb
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
	cpdi8 0x32cc, 12
	jr c, Rhythm_Transp_FinalCheck

Rhythm_Transp_WrapLoop:
	cpda8 w, 0x32cc
	jr c, Rhythm_Transp_FinalCheck
	sub w, 0xc
	jr Rhythm_Transp_WrapLoop

Rhythm_Transp_FinalCheck:
	ld a, w
	bitda 0, 0x332d
	jr z, Rhythm_Transp_Done
	cpda8 a, 0x332e
	jr nc, Rhythm_Transp_Done
	add a, 0xc

Rhythm_Transp_Done:
	anddi8 0x332d, 254
	ret

Rhythm_VoiceMapLookup:
	push xiy
	push xhl
	cpdi8 0x32d8, 0
	jr nz, Rhythm_VoiceMap_CheckInstr
	ldb a, 0x0
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckInstr:
	bitda 4, 0x32f4
	jr z, Rhythm_VoiceMap_CheckBit4
	anddi8 0x32f4, 239
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckBit4:
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_VoiceMap_ClampInstr
	xor l, l

Rhythm_VoiceMap_ClampInstr:
	ld xiy, Rhythm_PitchShiftTable_Default
	bitda 3, 0x32f4
	jr z, Rhythm_VoiceMap_SelectTable
	ld xiy, Rhythm_PitchShiftTable_Default_0x31

Rhythm_VoiceMap_SelectTable:
	ldb_sri L, 0x03, 0xf4, 0xec
	cps l, 0
	jr z, Rhythm_VoiceMap_ApplyBase
	ldb_d8 h, 0x3433
	cps l, 1
	jr z, Rhythm_VoiceMap_CheckMute
	ldb_d8 h, 0x3434

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
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_VoiceMap_Inst2Clamp
	xor l, l

Rhythm_VoiceMap_Inst2Clamp:
	ld xiy, Rhythm_InstrMapTable_Default
	bitda 2, 0x32f4
	jr z, Rhythm_VoiceMap_Inst2Bit2
	ld xiy, Rhythm_InstrMapTable_Default_0x31

Rhythm_VoiceMap_Inst2Bit2:
	bitda 3, 0x32f4
	jr z, Rhythm_VoiceMap_Inst2Bit3
	ld xiy, Rhythm_InstrMapTable_Default_0x62

Rhythm_VoiceMap_Inst2Bit3:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	stb_dri E, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
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
	cpdi8 0x32d8, 0
	jr nz, Rhythm_VelComp_CheckBit4
	ldb a, 0x0
	jr Rhythm_VelComp_Done

Rhythm_VelComp_CheckBit4:
	bitda 4, 0x32f4
	jr z, Rhythm_VelComp_ClampInstr
	anddi8 0x32f4, 239
	ld a, w
	jr Rhythm_VelComp_Done

Rhythm_VelComp_ClampInstr:
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_VelComp_SelectTable
	xor l, l

Rhythm_VelComp_SelectTable:
	ld xiy, Rhythm_VelocityTable_A
	bitda 2, 0x32f4
	jr z, Rhythm_VelComp_Lookup
	ld xiy, Rhythm_VelocityTable_A_0x31

Rhythm_VelComp_Lookup:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	stb_dri E, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
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
	ldb_d8 a, 0x32c3
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c7
	stb_d8 0x32cc, a
	anddi8 0x32f4, 251
	ordi8 0x32f4, 8
	ldb w, 0x97
	ld xix, 0x30f4

Rhythm_DispatchCh_D7_Loop:
	stdi8 0x33d4, 4
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x313c
	jr c, Rhythm_DispatchCh_D7_Loop
	ret

Rhythm_DispatchCh_D4:
	ldb_d8 a, 0x32c4
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c8
	stb_d8 0x32cc, a
	anddi8 0x32f4, 247
	ordi8 0x32f4, 4
	ldb w, 0x94
	ld xix, 0x313c

Rhythm_DispatchCh_D4_Loop:
	stdi8 0x33d4, 8
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x3184
	jr c, Rhythm_DispatchCh_D4_Loop
	ret

Rhythm_DispatchCh_D5:
	ldb_d8 a, 0x32c5
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32c9
	stb_d8 0x32cc, a
	anddi8 0x32f4, 243
	ldb w, 0x95
	ld xix, 0x3184

Rhythm_DispatchCh_D5_Loop:
	stdi8 0x33d4, 16
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x31cc
	jr c, Rhythm_DispatchCh_D5_Loop
	ret

Rhythm_DispatchCh_D6:
	ldb_d8 a, 0x32c6
	stb_d8 0x32cb, a
	ldb_d8 a, 0x32ca
	stb_d8 0x32cc, a
	anddi8 0x32f4, 243
	ldb w, 0x96
	ld xix, 0x31cc

Rhythm_DispatchCh_D6_Loop:
	stdi8 0x33d4, 32
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
	cpdi8 0x32e5, 240
	jr c, Rhythm_Validate_Mismatch
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	andda8 a, 0x33d4
	jr nz, Rhythm_Validate_Mismatch
	ldb_d8 a, 0x32df
	stb_d8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldb_d8 a, 0x3422
	stb_d8 0x3424, a
	ldb_d8 a, 0x32d8
	stb_d8 0x3423, a
	call AccTuning_CallWithSaveRestore
	ldb_d8 a, 0x3422
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
	bitda 4, 0x32f4
	jr nz, Rhythm_MatchedPhrase_Output
	bitda 3, 0x32f4
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
	bitda 4, 0x32f4
	jr nz, Rhythm_Mismatch90_Output
	bitda 3, 0x32f4
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
	stb_d8 0x3430, a
	ld a, (xix + 6)
	stb_d8 0x3433, a
	ld a, (xix + 7)
	stb_d8 0x3434, a
	ld a, (xix + 8)
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 0x32f4
	jr nz, Rhythm_MismatchOther_Output
	bitda 3, 0x32f4
	jr z, Rhythm_MismatchOther_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	calr Rhythm_VoiceMapLookup
	ld (xix + 2), a
	ldb_d8 a, 0x3430
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
	cpdi8 0x332f, 0
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
	cpdi8 0x332f, 0
	jr z, Rhythm_SendVolume_D7_Skip
	ldb a, 0xd7
	ldb w, 0x3
	ldb_d8 e, 0x332f
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	cpdi8 0x3330, 0
	jr z, Rhythm_SendVolume_D4_Skip
	ldb a, 0xd4
	ldb w, 0x3
	ldb_d8 e, 0x3330
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	cpdi8 0x3331, 0
	jr z, Rhythm_SendVolume_D5_Skip
	ldb a, 0xd5
	ldb w, 0x3
	ldb_d8 e, 0x3331
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	cpdi8 0x3332, 0
	jr z, Rhythm_SendVolume_D6_Done
	ldb a, 0xd6
	ldb w, 0x3
	ldb_d8 e, 0x3332
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
	cpdi8 0x332f, 0
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
	ldw_d16 xwa, 0x32e3
	stb_d8 0x3356, w
	ldb_d8 a, 0x327f
	ldb_d8 w, 0x3280
	stb_d8 0x3425, w
	add a, 0x18
	cp a, 0x60
	jr c, Rhythm_AdvanceTick_Store
	sub a, 0x60
	inc 1, w
	cpda8 w, 1112
	jr c, Rhythm_AdvanceTick_Store
	xor w, w

Rhythm_AdvanceTick_Store:
	stda16 0x32e3, xwa
	ret

Rhythm_SaveState:
	ldb_d8 a, 0x32f5
	stb_d8 0x32f6, a
	ldb_d8 a, 0x32f7
	stb_d8 0x32f8, a
	ldb_d8 a, 0x32f9
	stb_d8 0x32fa, a
	ldb_d8 a, 0x32fb
	stb_d8 0x32fc, a
	ldb_d8 a, 0x32ff
	stb_d8 0x3300, a
	ldb_d8 a, 0x32fd
	stb_d8 0x32fe, a
	ldb_d8 a, 0x3301
	stb_d8 0x3302, a
	ldb_d8 a, 0x3303
	stb_d8 0x3304, a
	ldb_d8 a, 0x3305
	stb_d8 0x3306, a
	ldb_d8 a, 0x3307
	stb_d8 0x3308, a
	ldb_d8 a, 0x3470
	stb_d8 0x3281, a
	ldb_d8 a, 0x8d34
	stb_d8 0x32f1, a
	ldb_d8 a, 0x3335
	stb_d8 0x32f2, a
	ldb_d8 a, 0x33e8
	stb_d8 0x33e9, a
	ldb_d8 a, 0x3283
	and a, 0xfd
	bit 0, a
	jr z, Rhythm_SaveState_StoreBits
	or a, 0x2

Rhythm_SaveState_StoreBits:
	stb_d8 0x3283, a
	ordi8 0x32f3, 1
	cpdi8 0x3280, 0
	jr nz, Rhythm_SaveState_CheckFx
	cpdi8 0x327f, 48
	jr c, Rhythm_SaveState_CheckFx
	anddi8 0x3329, 192

Rhythm_SaveState_CheckFx:
	ldb_d8 a, 0x330b
	and a, 0x3
	jr nz, Rhythm_SaveState_FxActive
	bitda 0, 0x330c
	jr z, Rhythm_SaveState_ClearFx

Rhythm_SaveState_FxActive:
	ldb_d8 a, 0x3326
	and a, 0x3f
	jr nz, Rhythm_SaveState_CheckFx2
	anddi8 0x330b, 252
	anddi8 0x330c, 254
	jr Rhythm_SaveState_CheckFx2

Rhythm_SaveState_ClearFx:
	anddi8 0x3326, 192

Rhythm_SaveState_CheckFx2:
	ldb_d8 a, 0x3309
	and a, 0x3
	jr nz, Rhythm_SaveState_Fx2Active
	ldb_d8 a, 0x330a
	and a, 0xd
	jr z, Rhythm_SaveState_ClearFx2

Rhythm_SaveState_Fx2Active:
	ldb_d8 a, 0x3327
	and a, 0x3f
	jr nz, Rhythm_VoiceAssignDetect
	and a, 0xfc
	and a, 0xf2
	jr Rhythm_VoiceAssignDetect

Rhythm_SaveState_ClearFx2:
	anddi8 0x3327, 192

Rhythm_VoiceAssignDetect:
	ldb_d8 a, 0x3312
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ldb_d8 a, 0x3319
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBDetect
	anddi8 0xfc5f, 191
	ldb_d8 a, 0x3313
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartAOn
	ordi8 0xfc5f, 128
	ordi8 0x32fc, 2

Rhythm_VoiceAssign_PartAOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32fc, 254
	anddi8 0x332b, 253
	ldb_d8 a, 0x3313
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
	ldb_d8 a, 0x3313
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ldb_d8 a, 0x331a
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext1Detect
	anddi8 0xfc5f, 127
	ldb_d8 a, 0x3312
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBOn
	ordi8 0xfc5f, 64
	ordi8 0x32fc, 1

Rhythm_VoiceAssign_PartBOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32fc, 253
	anddi8 0x332b, 251
	ldb_d8 a, 0x3312
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
	ldb_d8 a, 0x3316
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ldb_d8 a, 0x331d
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext2Detect
	anddi8 0xfc5f, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 254
	ldb_d8 a, 0x3317
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Ext2Detect:
	ldb_d8 a, 0x3317
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ldb_d8 a, 0x331e
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext3Detect
	anddi8 0xfc5f, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 253
	ldb_d8 a, 0x3316
	orda8 a, 0x3318
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Ext3Detect:
	ldb_d8 a, 0x3318
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ldb_d8 a, 0x331f
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc1Detect
	anddi8 0xfc60, 251
	ldb e, 0x48
	ldb d, 0x6
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x3300, 251
	ldb_d8 a, 0x3316
	orda8 a, 0x3317
	orda8 a, 0x3312
	orda8 a, 0x3313
	orda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ordi8 0x3284, 8

Rhythm_VoiceAssign_Perc1Detect:
	ldb_d8 a, 0x3314
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc2Detect
	ldb_d8 a, 0x331b
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc2Detect
	anddi8 0xfc5f, 239
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32fd, 254
	ordi8 0x3284, 4

Rhythm_VoiceAssign_Perc2Detect:
	ldb_d8 a, 0x3315
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_SaveShadow
	ldb_d8 a, 0x331c
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_SaveShadow
	anddi8 0xfc5f, 223
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 0x32fd, 253
	ordi8 0x3284, 4

Rhythm_VoiceAssign_SaveShadow:
	ldb_d8 a, 0x3312
	stb_d8 0x3319, a
	ldb_d8 a, 0x3313
	stb_d8 0x331a, a
	ldb_d8 a, 0x3316
	stb_d8 0x331d, a
	ldb_d8 a, 0x3317
	stb_d8 0x331e, a
	ldb_d8 a, 0x3318
	stb_d8 0x331f, a
	ldb_d8 a, 0x3314
	stb_d8 0x331b, a
	ldb_d8 a, 0x3315
	stb_d8 0x331c, a
	ldb_d8 a, 0x32e5
	stb_d8 0x3370, a
	ldb_d8 a, 0x333c
	stb_d8 0x333e, a
	call AccTuning_SaveState
	calr Rhythm_SeqResetCheck
	ret

Rhythm_SeqResetCheck:
	bitda 2, 0x34cf
	jr z, Rhythm_SeqReset_UpdateFlags
	bitda 4, 0x34cf
	jr nz, Rhythm_SeqReset_UpdateFlags
	ldb_d8 l, 0x379b
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
	ldb_d8 a, 0x34cf
	and a, 0xef
	bit 2, a
	jr z, Rhythm_SeqReset_Store
	or a, 0x10

Rhythm_SeqReset_Store:
	stb_d8 0x34cf, a
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
	cpdi8 0x32d8, 0
	jr z, Rhythm_TranspMod_Return
	cpdi8 0x32d9, 0
	jr z, Rhythm_TranspMod_Return
	bitda 2, 0x33e5
	jr nz, Rhythm_TranspMod_Return
	bitda 1, 0x33e5
	jr z, Rhythm_TranspMod_ApplyBoth
	calr Rhythm_TranspMod_ModCheck
	bitda 0, 0x33e5
	jr nz, Rhythm_TranspMod_Return

Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	anddi8 0x33e5, 254
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_TranspMod_LookupTable
	xor l, l

Rhythm_TranspMod_LookupTable:
	ld xiy, Rhythm_PitchShiftTable_Default
	ldb_sri L, 0x03, 0xf4, 0xec
	cps l, 0
	jr z, Rhythm_TranspMod_Done
	ldb_d8 h, 0x33e6
	cps l, 1
	jr z, Rhythm_TranspMod_Offset1
	ldb_d8 h, 0x33e7

Rhythm_TranspMod_Offset1:
	bit 5, h
	jr z, Rhythm_TranspMod_MuteCheck
	ldb a, 0x0
	ordi8 0x33e5, 1
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
	ld xiy, Display_FontPalette_Table_0x12EA
	ldb_sri A, 0x03, 0xf4, 0xe0
	ldb_d8 l, 0x32d8
	cp l, 0x30
	jr c, Rhythm_TranspMod_BaseLookup
	xor l, l

Rhythm_TranspMod_BaseLookup:
	extz hl
	ld xiy, Rhythm_InstrMapTable_Default_0x31
	ldb_sri L, 0x07, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	stb_dri E, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
	add w, a
	ret

Rhythm_TranspMod_OctaveWrap:
	ldb_d8 a, 0x32d9
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

