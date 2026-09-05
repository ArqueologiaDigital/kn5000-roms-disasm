; =============================================================================
; Rhythm Pattern Routines
; =============================================================================
;
; Rhythm pattern comparison, trigger logic, and transposition.
; Evaluates accompaniment pattern matching and rhythm dispatch.
; =============================================================================

Rhythm_CompareAndTrigger:
	bit 0, (0x3283:16)
	jrl z, Rhythm_SaveNoteState
	bit 6, (0x28ac:16)
	jr z, Rhythm_CompareAndTriggerNotes
	bit 2, (1057:16)
	jr z, Rhythm_CompareAndTriggerNotes
	ld a, (0x327f:16)
	cp a, 0x12
	jr ule, Rhythm_CompareAndTriggerNotes
	cp a, 0x5c
	jr ugt, Rhythm_CompareAndTriggerNotes
	jrl Rhythm_SaveNoteState

Rhythm_CompareAndTriggerNotes:
	bit 1, (0x32d7:16)
	jr nz, Rhythm_CompareNoteA_Only
	ld a, (0x32d8:16)
	ld w, (0x32d9:16)
	ld l, (0x32df:16)
	ld h, (0x32e0:16)
	cp wa, hl
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteA_Only:
	ld a, (0x32d8:16)
	ld w, (0x32df:16)
	cp a, w
	jr z, Rhythm_CompareNoteB
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteB:
	ld a, (0x32d9:16)
	ld w, (0x32e0:16)
	cp a, w
	jr z, Rhythm_CompareNoteC
	calr Rhythm_NoteOnAfterSetup_B

Rhythm_CompareNoteC:
	ld a, (0x32da:16)
	ld w, (0x32e1:16)
	cp a, w
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_C

Rhythm_SaveCurrentNoteState:
	ld a, (0x32d8:16)
	ld (0x32df:16), a
	ld a, (0x32d9:16)
	ld (0x32e0:16), a
	ld a, (0x32da:16)
	ld (0x32e1:16), a

Rhythm_SaveNoteState:
	ld a, (0x32d8:16)
	ld (0x32dc:16), a
	ld a, (0x32d9:16)
	ld (0x32dd:16), a
	ld a, (0x32da:16)
	ld (0x32de:16), a
	ld a, (0x32d7:16)
	ld (0x32db:16), a
	ret

Rhythm_NoteOnAfterSetup_A:
	calr Rhythm_SetupAllChannels
	calr Rhythm_AllNotesOff_Dispatch
	calr Rhythm_Send_Ch90_7F_7E
	calr Rhythm_NoteOffMax_Dispatch
	calr Rhythm_FourChannelDispatch
	calr Rhythm_SendVolume_Dispatch
	ld a, 0x90:opc
	call Rhythm_SendByte
	ld a, 0x7f:opc
	call Rhythm_SendByte
	ld a, 0x7d:opc
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
	ld a, 0x90:opc
	call Rhythm_SendByte
	ld a, 0x7f:opc
	call Rhythm_SendByte
	ld a, 0x7d:opc
	call Rhythm_SendByte
	ret

Rhythm_NoteOnAfterSetup_C:
	calr Rhythm_SetupChannel_D7
	calr Rhythm_AllNotesOff_D7
	calr Rhythm_Send_Ch90_7F_07
	calr Rhythm_NoteOffMax_D7
	calr Rhythm_DispatchCh_D7
	call Rhythm_SendVolume_D7
	ld a, 0x90:opc
	call Rhythm_SendByte
	ld a, 0x7f:opc
	call Rhythm_SendByte
	ld a, 0x7d:opc
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
	ld a, (0x32c3:16)
	ld (0x32cb:16), a
	ld a, (0x32c7:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 251
	or (0x32f4:16), 8
	ld (0x33d4:16), 4
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D4:
	ld xhl, 0x2d94
	ld a, (0x32c4:16)
	ld (0x32cb:16), a
	ld a, (0x32c8:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 247
	or (0x32f4:16), 4
	ld (0x33d4:16), 8
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D5:
	ld xhl, 0x2e94
	ld a, (0x32c5:16)
	ld (0x32cb:16), a
	ld a, (0x32c9:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 243
	ld (0x33d4:16), 16
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D6:
	ld xhl, 0x2f94
	ld a, (0x32c6:16)
	ld (0x32cb:16), a
	ld a, (0x32ca:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 243
	ld (0x33d4:16), 32
	calr RhythmEvt_ProcessNote
	ret

RhythmEvt_ProcessNote:
	cp (0x32e5:16), 240
	jr c, RhythmEvt_AlternateProcess
	ld a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, (0x33d4:16)
	jr nz, RhythmEvt_AlternateProcess
	ld a, (0x32df:16)
	ld (0x3423:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3422:16)
	ld (0x3424:16), a
	ld a, (0x32d8:16)
	ld (0x3423:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3422:16)
	cp (0x3424:16), a
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
	ld (0x345d:16), iy
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
	bit 4, (0x32f4:16)
	jr nz, RhythmEvt_PostProcess
	bit 3, (0x32f4:16)
	jr z, RhythmEvt_ApplyNoteRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_ApplyNoteRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_PostProcess:
	calr Rhythm_VelocityCompute
	popw iy
	stb_dri A, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_NoteOnLoop

RhythmEvt_SkipUnknown:
	popw iy
	ld iy, (0x345d:16)
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
	bit 4, (0x32f4:16)
	jr nz, RhythmEvt_Full90_PostTransp
	bit 3, (0x32f4:16)
	jr z, RhythmEvt_Full90_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full90_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full90_PostTransp:
	calr Rhythm_VelocityLookup_A
	popw iy
	stb_dri A, 0x07, 0xec, 0xf4
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
	ld (0x3430:16), a
	calr Rhythm_AdvancePosition
	ldb_sri A, 0x07, 0xec, 0xf4
	ld (0x3433:16), a
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	ld (0x3434:16), a
	call RingBuf_AdvanceIndex
	ldb_sri A, 0x07, 0xec, 0xf4
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x32f4:16)
	jr nz, RhythmEvt_Full91_PostTransp
	bit 3, (0x32f4:16)
	jr z, RhythmEvt_Full91_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	calr Rhythm_VoiceMapLookup
	popw iy
	stb_dri A, 0x07, 0xec, 0xf4
	call RingBuf_AdvanceIndex
	ld a, (0x3430:16)
	stb_dri A, 0x07, 0xec, 0xf4
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition
	jrl RhythmEvt_FullLoop

RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	and (0x32f4:16), 239
	cp a, 0x78
	jr c, Rhythm_VelThreshReturn
	or (0x32f4:16), 16

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
	bit 0, (0x32d7:16)
	jr nz, Rhythm_CrossVoice_Apply
	bit 1, (0x32d7:16)
	jr nz, Rhythm_CrossVoice_Apply
	ld w, (0x3316:16)
	or w, (0x3317:16)
	or w, (0x3318:16)
	and w, 0x3f
	jr nz, Rhythm_CrossVoice_ClearFlag
	bit 5, (0x32f3:16)
	jr z, Rhythm_CrossVoice_ClearFlag

Rhythm_CrossVoice_Apply:
	push xiy
	ld w, a
	add w, (0x32cb:16)
	inc 1, w
	sub w, 0xc
	ld (0x332e:16), w
	or (0x332d:16), 1
	ld xiy, Display_FontPalette_Table_0x12EA
	ldb_sri W, 0x03, 0xf4, 0xe0
	sub a, w
	pop xiy
	ld (0x3433:16), 0
	ld (0x3434:16), 0

Rhythm_CrossVoice_ClearFlag:
	and (0x32f3:16), 223
	ret

Rhythm_NoteRangeCheck:
	bit 0, (0x32d7:16)
	jr z, Rhythm_NoteRangeReturn
	push xiy
	ld w, a
	ld xiy, Display_FontPalette_Table_0x12EA
	ldb_sri W, 0x03, 0xf4, 0xe0
	sub a, w
	pop xiy
	ld (0x3433:16), 0
	ld (0x3434:16), 0

Rhythm_NoteRangeReturn:
	ret

Rhythm_NoteRangeData:
	nop
	nop

Rhythm_VelocityLookup_A:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cp (0x32d8:16), 0
	jr nz, Rhythm_VelLookA_CheckEmpty
	ld a, 0x0:opc
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckEmpty:
	bit 4, (0x32f4:16)
	jr z, Rhythm_VelLookA_CheckRange
	and (0x32f4:16), 239
	ld a, w
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckRange:
	ld l, (0x32d8:16)
	cp l, 0x30
	jr c, Rhythm_VelLookA_SelectTable
	xor l, l

Rhythm_VelLookA_SelectTable:
	ld xiy, Rhythm_InstrMapTable_Default
	bit 2, (0x32f4:16)
	jr z, Rhythm_VelLookA_CheckBit3
	ld xiy, Rhythm_InstrMapTable_Default_0x31

Rhythm_VelLookA_CheckBit3:
	bit 3, (0x32f4:16)
	jr z, Rhythm_VelLookA_TableLookup
	ld xiy, Rhythm_InstrMapTable_Default_0x62

Rhythm_VelLookA_TableLookup:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	lda_dri XIY, 0x03, 0xf4, 0xe0
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
	ld a, (0x32d9:16)
	bit 3, (0x32f4:16)
	jr z, Rhythm_Transp_CheckZero
	ld a, (0x32da:16)

Rhythm_Transp_CheckZero:
	cp a, 0:i3
	jr nz, Rhythm_Transp_Apply
	ld a, 0x0:opc
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	dec 1, a
	cp a, (0x32cb:16)
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
	cp (0x32cc:16), 12
	jr c, Rhythm_Transp_FinalCheck

Rhythm_Transp_WrapLoop:
	cp w, (0x32cc:16)
	jr c, Rhythm_Transp_FinalCheck
	sub w, 0xc
	jr Rhythm_Transp_WrapLoop

Rhythm_Transp_FinalCheck:
	ld a, w
	bit 0, (0x332d:16)
	jr z, Rhythm_Transp_Done
	cp a, (0x332e:16)
	jr nc, Rhythm_Transp_Done
	add a, 0xc

Rhythm_Transp_Done:
	and (0x332d:16), 254
	ret

Rhythm_VoiceMapLookup:
	push xiy
	push xhl
	cp (0x32d8:16), 0
	jr nz, Rhythm_VoiceMap_CheckInstr
	ld a, 0x0:opc
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckInstr:
	bit 4, (0x32f4:16)
	jr z, Rhythm_VoiceMap_CheckBit4
	and (0x32f4:16), 239
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckBit4:
	ld l, (0x32d8:16)
	cp l, 0x30
	jr c, Rhythm_VoiceMap_ClampInstr
	xor l, l

Rhythm_VoiceMap_ClampInstr:
	ld xiy, Rhythm_PitchShiftTable_Default
	bit 3, (0x32f4:16)
	jr z, Rhythm_VoiceMap_SelectTable
	ld xiy, Rhythm_PitchShiftTable_Default_0x31

Rhythm_VoiceMap_SelectTable:
	ldb_sri L, 0x03, 0xf4, 0xec
	cp l, 0:i3
	jr z, Rhythm_VoiceMap_ApplyBase
	ld h, (0x3433:16)
	cp l, 1:i3
	jr z, Rhythm_VoiceMap_CheckMute
	ld h, (0x3434:16)

Rhythm_VoiceMap_CheckMute:
	bit 5, h
	jr z, Rhythm_VoiceMap_CheckDir
	ld a, 0x0:opc
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
	ld l, (0x32d8:16)
	cp l, 0x30
	jr c, Rhythm_VoiceMap_Inst2Clamp
	xor l, l

Rhythm_VoiceMap_Inst2Clamp:
	ld xiy, Rhythm_InstrMapTable_Default
	bit 2, (0x32f4:16)
	jr z, Rhythm_VoiceMap_Inst2Bit2
	ld xiy, Rhythm_InstrMapTable_Default_0x31

Rhythm_VoiceMap_Inst2Bit2:
	bit 3, (0x32f4:16)
	jr z, Rhythm_VoiceMap_Inst2Bit3
	ld xiy, Rhythm_InstrMapTable_Default_0x62

Rhythm_VoiceMap_Inst2Bit3:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	lda_dri XIY, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VoiceMap_Done:
	pop xhl
	pop xiy
	ret

Rhythm_PitchShiftTable_Default:
	nop
	nop
	normal
	normal
	nop
	push sr
	normal
	normal
	push sr
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
	push sr
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
	.fill 8, 1, 0x01
	nop
	push sr
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	normal
	normal
	normal
	push sr
	normal
	normal
	push sr
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
	push sr
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
	.fill 8, 1, 0x01
	.byte 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x00, 0x00

Rhythm_VelocityCompute:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cp (0x32d8:16), 0
	jr nz, Rhythm_VelComp_CheckBit4
	ld a, 0x0:opc
	jr Rhythm_VelComp_Done

Rhythm_VelComp_CheckBit4:
	bit 4, (0x32f4:16)
	jr z, Rhythm_VelComp_ClampInstr
	and (0x32f4:16), 239
	ld a, w
	jr Rhythm_VelComp_Done

Rhythm_VelComp_ClampInstr:
	ld l, (0x32d8:16)
	cp l, 0x30
	jr c, Rhythm_VelComp_SelectTable
	xor l, l

Rhythm_VelComp_SelectTable:
	ld xiy, Rhythm_VelocityTable_A
	bit 2, (0x32f4:16)
	jr z, Rhythm_VelComp_Lookup
	ld xiy, Rhythm_VelocityTable_A_0x31

Rhythm_VelComp_Lookup:
	ldb_sri L, 0x03, 0xf4, 0xec
	extz hl
	sla hl, 4
	ld xiy, Display_FontPalette_Table_0x136A
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	ld a, (0x32c3:16)
	ld (0x32cb:16), a
	ld a, (0x32c7:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 251
	or (0x32f4:16), 8
	ld w, 0x97:opc
	ld xix, 0x30f4

Rhythm_DispatchCh_D7_Loop:
	ld (0x33d4:16), 4
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x313c
	jr c, Rhythm_DispatchCh_D7_Loop
	ret

Rhythm_DispatchCh_D4:
	ld a, (0x32c4:16)
	ld (0x32cb:16), a
	ld a, (0x32c8:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 247
	or (0x32f4:16), 4
	ld w, 0x94:opc
	ld xix, 0x313c

Rhythm_DispatchCh_D4_Loop:
	ld (0x33d4:16), 8
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x3184
	jr c, Rhythm_DispatchCh_D4_Loop
	ret

Rhythm_DispatchCh_D5:
	ld a, (0x32c5:16)
	ld (0x32cb:16), a
	ld a, (0x32c9:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 243
	ld w, 0x95:opc
	ld xix, 0x3184

Rhythm_DispatchCh_D5_Loop:
	ld (0x33d4:16), 16
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x31cc
	jr c, Rhythm_DispatchCh_D5_Loop
	ret

Rhythm_DispatchCh_D6:
	ld a, (0x32c6:16)
	ld (0x32cb:16), a
	ld a, (0x32ca:16)
	ld (0x32cc:16), a
	and (0x32f4:16), 243
	ld w, 0x96:opc
	ld xix, 0x31cc

Rhythm_DispatchCh_D6_Loop:
	ld (0x33d4:16), 32
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
	cp a, 0:i3
	jr gt, Rhythm_SingleNote_ClampVelocity
	ld a, 0x1:opc

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
	cp (0x32e5:16), 240
	jr c, Rhythm_Validate_Mismatch
	ld a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, (0x33d4:16)
	jr nz, Rhythm_Validate_Mismatch
	ld a, (0x32df:16)
	ld (0x3423:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3422:16)
	ld (0x3424:16), a
	ld a, (0x32d8:16)
	ld (0x3423:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3422:16)
	cp (0x3424:16), a
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
	bit 4, (0x32f4:16)
	jr nz, Rhythm_MatchedPhrase_Output
	bit 3, (0x32f4:16)
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
	bit 4, (0x32f4:16)
	jr nz, Rhythm_Mismatch90_Output
	bit 3, (0x32f4:16)
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
	ld (0x3430:16), a
	ld a, (xix + 6)
	ld (0x3433:16), a
	ld a, (xix + 7)
	ld (0x3434:16), a
	ld a, (xix + 8)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x32f4:16)
	jr nz, Rhythm_MismatchOther_Output
	bit 3, (0x32f4:16)
	jr z, Rhythm_MismatchOther_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	calr Rhythm_VoiceMapLookup
	ld (xix + 2), a
	ld a, (0x3430:16)
	ld (xix + 3), a
	popw wa

Rhythm_MismatchOther_Return:
	ret

Rhythm_Send_Ch90_7F_7E:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x7e:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_04:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x4:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_05:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x5:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_06:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x6:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_07:
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x7:opc
	call Rhythm_Send3ByteMsg
	ret

Rhythm_AllNotesOff_Dispatch:
	calr Rhythm_AllNotesOff_D7
	calr Rhythm_AllNotesOff_D4
	calr Rhythm_AllNotesOff_D5
	calr Rhythm_AllNotesOff_D6
	ret

Rhythm_AllNotesOff_D7:
	cp (0x332f:16), 0
	jr z, Rhythm_AllNotesOff_D7_Skip
	ld a, 0xd7:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D7_Skip:
	ret

Rhythm_AllNotesOff_D4:
	cp (0x3330:16), 0
	jr z, Rhythm_AllNotesOff_D4_Skip
	ld a, 0xd4:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D4_Skip:
	ret

Rhythm_AllNotesOff_D5:
	cp (0x3331:16), 0
	jr z, Rhythm_AllNotesOff_D5_Skip
	ld a, 0xd5:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D5_Skip:
	ret

Rhythm_AllNotesOff_D6:
	cp (0x3332:16), 0
	jr z, Rhythm_AllNotesOff_D6_Done
	ld a, 0xd6:opc
	ld w, 0x3:opc
	ld e, 0x0:opc
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
	cp (0x332f:16), 0
	jr z, Rhythm_SendVolume_D7_Skip
	ld a, 0xd7:opc
	ld w, 0x3:opc
	ld e, (0x332f:16)
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	cp (0x3330:16), 0
	jr z, Rhythm_SendVolume_D4_Skip
	ld a, 0xd4:opc
	ld w, 0x3:opc
	ld e, (0x3330:16)
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	cp (0x3331:16), 0
	jr z, Rhythm_SendVolume_D5_Skip
	ld a, 0xd5:opc
	ld w, 0x3:opc
	ld e, (0x3331:16)
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	cp (0x3332:16), 0
	jr z, Rhythm_SendVolume_D6_Done
	ld a, 0xd6:opc
	ld w, 0x3:opc
	ld e, (0x3332:16)
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
	cp (0x332f:16), 0
	jr z, Rhythm_NoteOffMax_D7_Skip
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x77:opc
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D7_Skip:
	ret

Rhythm_NoteOffMax_D4:
	cp (0x3330:16), 0
	jr z, Rhythm_NoteOffMax_D4_Skip
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x74:opc
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D4_Skip:
	ret

Rhythm_NoteOffMax_D5:
	cp (0x3331:16), 0
	jr z, Rhythm_NoteOffMax_D5_Skip
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x75:opc
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D5_Skip:
	ret

Rhythm_NoteOffMax_D6:
	cp (0x3332:16), 0
	jr z, Rhythm_NoteOffMax_D6_Done
	ld a, 0x90:opc
	ld w, 0x7f:opc
	ld e, 0x76:opc
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D6_Done:
	ret

Rhythm_AdvanceTick:
	ld wa, (0x32e3:16)
	ld (0x3356:16), w
	ld a, (0x327f:16)
	ld w, (0x3280:16)
	ld (0x3425:16), w
	add a, 0x18
	cp a, 0x60
	jr c, Rhythm_AdvanceTick_Store
	sub a, 0x60
	inc 1, w
	cp w, (1112:16)
	jr c, Rhythm_AdvanceTick_Store
	xor w, w

Rhythm_AdvanceTick_Store:
	ld (0x32e3:16), wa
	ret

Rhythm_SaveState:
	ld a, (0x32f5:16)
	ld (0x32f6:16), a
	ld a, (0x32f7:16)
	ld (0x32f8:16), a
	ld a, (0x32f9:16)
	ld (0x32fa:16), a
	ld a, (0x32fb:16)
	ld (0x32fc:16), a
	ld a, (0x32ff:16)
	ld (0x3300:16), a
	ld a, (0x32fd:16)
	ld (0x32fe:16), a
	ld a, (0x3301:16)
	ld (0x3302:16), a
	ld a, (0x3303:16)
	ld (0x3304:16), a
	ld a, (0x3305:16)
	ld (0x3306:16), a
	ld a, (0x3307:16)
	ld (0x3308:16), a
	ld a, (0x3470:16)
	ld (0x3281:16), a
	ld a, (0x8d34:16)
	ld (0x32f1:16), a
	ld a, (0x3335:16)
	ld (0x32f2:16), a
	ld a, (0x33e8:16)
	ld (0x33e9:16), a
	ld a, (0x3283:16)
	and a, 0xfd
	bit 0, a
	jr z, Rhythm_SaveState_StoreBits
	or a, 0x2

Rhythm_SaveState_StoreBits:
	ld (0x3283:16), a
	or (0x32f3:16), 1
	cp (0x3280:16), 0
	jr nz, Rhythm_SaveState_CheckFx
	cp (0x327f:16), 48
	jr c, Rhythm_SaveState_CheckFx
	and (0x3329:16), 192

Rhythm_SaveState_CheckFx:
	ld a, (0x330b:16)
	and a, 0x3
	jr nz, Rhythm_SaveState_FxActive
	bit 0, (0x330c:16)
	jr z, Rhythm_SaveState_ClearFx

Rhythm_SaveState_FxActive:
	ld a, (0x3326:16)
	and a, 0x3f
	jr nz, Rhythm_SaveState_CheckFx2
	and (0x330b:16), 252
	and (0x330c:16), 254
	jr Rhythm_SaveState_CheckFx2

Rhythm_SaveState_ClearFx:
	and (0x3326:16), 192

Rhythm_SaveState_CheckFx2:
	ld a, (0x3309:16)
	and a, 0x3
	jr nz, Rhythm_SaveState_Fx2Active
	ld a, (0x330a:16)
	and a, 0xd
	jr z, Rhythm_SaveState_ClearFx2

Rhythm_SaveState_Fx2Active:
	ld a, (0x3327:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssignDetect
	and a, 0xfc
	and a, 0xf2
	jr Rhythm_VoiceAssignDetect

Rhythm_SaveState_ClearFx2:
	and (0x3327:16), 192

Rhythm_VoiceAssignDetect:
	ld a, (0x3312:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ld a, (0x3319:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBDetect
	and (0xfc5f:16), 191
	ld a, (0x3313:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartAOn
	or (0xfc5f:16), 128
	or (0x32fc:16), 2

Rhythm_VoiceAssign_PartAOn:
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x32fc:16), 254
	and (0x332b:16), 253
	ld a, (0x3313:16)
	or a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_PartBDetect
	or (0x3284:16), 16
	or (0x3284:16), 4

Rhythm_VoiceAssign_PartBDetect:
	ld a, (0x3313:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ld a, (0x331a:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext1Detect
	and (0xfc5f:16), 127
	ld a, (0x3312:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_PartBOn
	or (0xfc5f:16), 64
	or (0x32fc:16), 1

Rhythm_VoiceAssign_PartBOn:
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x32fc:16), 253
	and (0x332b:16), 251
	ld a, (0x3312:16)
	or a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	or (0x3284:16), 16
	or (0x3284:16), 4

Rhythm_VoiceAssign_Ext1Detect:
	ld a, (0x3316:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ld a, (0x331d:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext2Detect
	and (0xfc5f:16), 251
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3300:16), 254
	ld a, (0x3317:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	or (0x3284:16), 8

Rhythm_VoiceAssign_Ext2Detect:
	ld a, (0x3317:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ld a, (0x331e:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Ext3Detect
	and (0xfc5f:16), 247
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3300:16), 253
	ld a, (0x3316:16)
	or a, (0x3318:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	or (0x3284:16), 8

Rhythm_VoiceAssign_Ext3Detect:
	ld a, (0x3318:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ld a, (0x331f:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc1Detect
	and (0xfc60:16), 251
	ld e, 0x48:opc
	ld d, 0x6:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3300:16), 251
	ld a, (0x3316:16)
	or a, (0x3317:16)
	or a, (0x3312:16)
	or a, (0x3313:16)
	or a, (0x3314:16)
	or a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	or (0x3284:16), 8

Rhythm_VoiceAssign_Perc1Detect:
	ld a, (0x3314:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_Perc2Detect
	ld a, (0x331b:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_Perc2Detect
	and (0xfc5f:16), 239
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x32fd:16), 254
	or (0x3284:16), 4

Rhythm_VoiceAssign_Perc2Detect:
	ld a, (0x3315:16)
	and a, 0x3f
	jr nz, Rhythm_VoiceAssign_SaveShadow
	ld a, (0x331c:16)
	and a, 0x3f
	jr z, Rhythm_VoiceAssign_SaveShadow
	and (0xfc5f:16), 223
	ld e, 0x48:opc
	ld d, 0x5:opc
	ld a, 0x0:opc
	ld w, 0x0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x32fd:16), 253
	or (0x3284:16), 4

Rhythm_VoiceAssign_SaveShadow:
	ld a, (0x3312:16)
	ld (0x3319:16), a
	ld a, (0x3313:16)
	ld (0x331a:16), a
	ld a, (0x3316:16)
	ld (0x331d:16), a
	ld a, (0x3317:16)
	ld (0x331e:16), a
	ld a, (0x3318:16)
	ld (0x331f:16), a
	ld a, (0x3314:16)
	ld (0x331b:16), a
	ld a, (0x3315:16)
	ld (0x331c:16), a
	ld a, (0x32e5:16)
	ld (0x3370:16), a
	ld a, (0x333c:16)
	ld (0x333e:16), a
	call AccTuning_SaveState
	calr Rhythm_SeqResetCheck
	ret

Rhythm_SeqResetCheck:
	bit 2, (0x34cf:16)
	jr z, Rhythm_SeqReset_UpdateFlags
	bit 4, (0x34cf:16)
	jr nz, Rhythm_SeqReset_UpdateFlags
	ld l, (0x379b:16)
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
	ld a, (0x34cf:16)
	and a, 0xef
	bit 2, a
	jr z, Rhythm_SeqReset_Store
	or a, 0x10

Rhythm_SeqReset_Store:
	ld (0x34cf:16), a
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
	cp (0x32d8:16), 0
	jr z, Rhythm_TranspMod_Return
	cp (0x32d9:16), 0
	jr z, Rhythm_TranspMod_Return
	bit 2, (0x33e5:16)
	jr nz, Rhythm_TranspMod_Return
	bit 1, (0x33e5:16)
	jr z, Rhythm_TranspMod_ApplyBoth
	calr Rhythm_TranspMod_ModCheck
	bit 0, (0x33e5:16)
	jr nz, Rhythm_TranspMod_Return

Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	and (0x33e5:16), 254
	ld l, (0x32d8:16)
	cp l, 0x30
	jr c, Rhythm_TranspMod_LookupTable
	xor l, l

Rhythm_TranspMod_LookupTable:
	ld xiy, Rhythm_PitchShiftTable_Default
	ldb_sri L, 0x03, 0xf4, 0xec
	cp l, 0:i3
	jr z, Rhythm_TranspMod_Done
	ld h, (0x33e6:16)
	cp l, 1:i3
	jr z, Rhythm_TranspMod_Offset1
	ld h, (0x33e7:16)

Rhythm_TranspMod_Offset1:
	bit 5, h
	jr z, Rhythm_TranspMod_MuteCheck
	ld a, 0x0:opc
	or (0x33e5:16), 1
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
	ld l, (0x32d8:16)
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
	lda_dri XIY, 0x07, 0xf4, 0xec
	ldb_sri A, 0x03, 0xf4, 0xe0
	add w, a
	ret

Rhythm_TranspMod_OctaveWrap:
	ld a, (0x32d9:16)
	dec 1, a
	cp a, 7:i3
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
	call	16069687
	ret

