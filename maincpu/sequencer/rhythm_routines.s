; =============================================================================
; Rhythm Pattern Routines
; =============================================================================
;
; Rhythm pattern comparison, trigger logic, and transposition.
; Evaluates accompaniment pattern matching and rhythm dispatch.
; =============================================================================

Rhythm_CompareAndTrigger:
	bitda 0, 12931
	jrl z, Rhythm_SaveNoteState
	bitda 6, 10412
	jr z, Rhythm_CompareAndTriggerNotes
	bitda 2, 1057
	jr z, Rhythm_CompareAndTriggerNotes
	ldda8 a, 12927
	cp a, 0x12
	jr ule, Rhythm_CompareAndTriggerNotes
	cp a, 0x5C
	jr ugt, Rhythm_CompareAndTriggerNotes
	jrl Rhythm_SaveNoteState

Rhythm_CompareAndTriggerNotes:
	bitda 1, 13015
	jr nz, Rhythm_CompareNoteA_Only
	ldda8 a, 13016
	ldda8 w, 13017
	ldda8 l, 13023
	ldda8 h, 13024
	cp wa, hl
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteA_Only:
	ldda8 a, 13016
	ldda8 w, 13023
	cp a, w
	jr z, Rhythm_CompareNoteB
	calr Rhythm_NoteOnAfterSetup_A
	jr Rhythm_SaveCurrentNoteState

Rhythm_CompareNoteB:
	ldda8 a, 13017
	ldda8 w, 13024
	cp a, w
	jr z, Rhythm_CompareNoteC
	calr Rhythm_NoteOnAfterSetup_B

Rhythm_CompareNoteC:
	ldda8 a, 13018
	ldda8 w, 13025
	cp a, w
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_C

Rhythm_SaveCurrentNoteState:
	ldda8 a, 13016
	stda8 13023, a
	ldda8 a, 13017
	stda8 13024, a
	ldda8 a, 13018
	stda8 13025, a

Rhythm_SaveNoteState:
	ldda8 a, 13016
	stda8 13020, a
	ldda8 a, 13017
	stda8 13021, a
	ldda8 a, 13018
	stda8 13022, a
	ldda8 a, 13015
	stda8 13019, a
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
	ldb a, 0x7F
	call Rhythm_SendByte
	ldb a, 0x7D
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
	ldb a, 0x7F
	call Rhythm_SendByte
	ldb a, 0x7D
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
	ldb a, 0x7F
	call Rhythm_SendByte
	ldb a, 0x7D
	call Rhythm_SendByte
	ret

Rhythm_SetupAllChannels:
	calr Rhythm_SetupChannel_D7
	calr Rhythm_SetupChannel_D4
	calr Rhythm_SetupChannel_D5
	calr Rhythm_SetupChannel_D6
	ret

Rhythm_SetupChannel_D7:
	ld xhl, 0x2C94
	ldda8 a, 12995
	stda8 13003, a
	ldda8 a, 12999
	stda8 13004, a
	anddi8 13044, 251
	ordi8 13044, 8
	stdi8 13268, 4
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D4:
	ld xhl, 0x2D94
	ldda8 a, 12996
	stda8 13003, a
	ldda8 a, 13000
	stda8 13004, a
	anddi8 13044, 247
	ordi8 13044, 4
	stdi8 13268, 8
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D5:
	ld xhl, 0x2E94
	ldda8 a, 12997
	stda8 13003, a
	ldda8 a, 13001
	stda8 13004, a
	anddi8 13044, 243
	stdi8 13268, 16
	calr RhythmEvt_ProcessNote
	ret

Rhythm_SetupChannel_D6:
	ld xhl, 0x2F94
	ldda8 a, 12998
	stda8 13003, a
	ldda8 a, 13002
	stda8 13004, a
	anddi8 13044, 243
	stdi8 13268, 32
	calr RhythmEvt_ProcessNote
	ret

RhythmEvt_ProcessNote:
	cpdi8 13029, 240
	jr c, RhythmEvt_AlternateProcess
	ldda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	andda8 a, 13268
	jr nz, RhythmEvt_AlternateProcess
	ldda8 a, 13023
	stda8 13347, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 13346
	stda8 13348, a
	ldda8 a, 13016
	stda8 13347, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 13346
	cpdm8 13348, a
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
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda16 13405, xiy
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
	ld_srib3 A, 0x07, 0xEC, 0xF4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 13044
	jr nz, RhythmEvt_PostProcess
	bitda 3, 13044
	jr z, RhythmEvt_ApplyNoteRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_ApplyNoteRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_PostProcess:
	calr Rhythm_VelocityCompute
	popw iy
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_NoteOnLoop

RhythmEvt_SkipUnknown:
	popw iy
	ldda16 xiy, 13405
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
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cp a, 0x90
	jr nz, RhythmEvt_Full91
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xEC, 0xF4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 13044
	jr nz, RhythmEvt_Full90_PostTransp
	bitda 3, 13044
	jr z, RhythmEvt_Full90_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full90_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full90_PostTransp:
	calr Rhythm_VelocityLookup_A
	popw iy
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
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
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13360, a
	calr Rhythm_AdvancePosition
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13363, a
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 13364, a
	call RingBuf_AdvanceIndex
	ld_srib3 A, 0x07, 0xEC, 0xF4
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 13044
	jr nz, RhythmEvt_Full91_PostTransp
	bitda 3, 13044
	jr z, RhythmEvt_Full91_PostRange
	calr Rhythm_CrossVoiceCorrect

RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	calr Rhythm_VoiceMapLookup
	popw iy
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call RingBuf_AdvanceIndex
	ldda8 a, 13360
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition
	jrl RhythmEvt_FullLoop

RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	anddi8 13044, 239
	cp a, 0x78
	jr c, Rhythm_VelThreshReturn
	ordi8 13044, 16

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
	bitda 0, 13015
	jr nz, Rhythm_CrossVoice_Apply
	bitda 1, 13015
	jr nz, Rhythm_CrossVoice_Apply
	ldda8 w, 13078
	orda8 w, 13079
	orda8 w, 13080
	and w, 0x3F
	jr nz, Rhythm_CrossVoice_ClearFlag
	bitda 5, 13043
	jr z, Rhythm_CrossVoice_ClearFlag

Rhythm_CrossVoice_Apply:
	push xiy
	ld w, a
	addda8 w, 13003
	inc 1, w
	sub w, 0xC
	stda8 13102, w
	ordi8 13101, 1
	ld xiy, 0xE46142
	ld_srib3 W, 0x03, 0xF4, 0xE0
	sub a, w
	pop xiy
	stdi8 13363, 0
	stdi8 13364, 0

Rhythm_CrossVoice_ClearFlag:
	anddi8 13043, 223
	ret

Rhythm_NoteRangeCheck:
	bitda 0, 13015
	jr z, Rhythm_NoteRangeReturn
	push xiy
	ld w, a
	ld xiy, 0xE46142
	ld_srib3 W, 0x03, 0xF4, 0xE0
	sub a, w
	pop xiy
	stdi8 13363, 0
	stdi8 13364, 0

Rhythm_NoteRangeReturn:
	ret

Rhythm_NoteRangeData:
	.byte 0x00, 0x00

Rhythm_VelocityLookup_A:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cpdi8 13016, 0
	jr nz, Rhythm_VelLookA_CheckEmpty
	ldb a, 0x0
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckEmpty:
	bitda 4, 13044
	jr z, Rhythm_VelLookA_CheckRange
	anddi8 13044, 239
	ld a, w
	jr Rhythm_VelLookA_Done

Rhythm_VelLookA_CheckRange:
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_VelLookA_SelectTable
	xor l, l

Rhythm_VelLookA_SelectTable:
	ld xiy, 0xF550CA
	bitda 2, 13044
	jr z, Rhythm_VelLookA_CheckBit3
	ld xiy, 0xF550FB

Rhythm_VelLookA_CheckBit3:
	bitda 3, 13044
	jr z, Rhythm_VelLookA_TableLookup
	ld xiy, 0xF5512C

Rhythm_VelLookA_TableLookup:
	ld_srib3 L, 0x03, 0xF4, 0xEC
	extz hl
	sla hl, 4
	ld xiy, 0xE461C2
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld_srib3 A, 0x03, 0xF4, 0xE0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelLookA_Done:
	pop xhl
	pop xiy
	ret

Rhythm_InstrBaseLookup:
	push xiy
	ld xiy, 0xE46142
	st_dri3b E, 0x03, 0xF4, 0xE0
	ld a, (xiy)
	pop xiy
	ret

Rhythm_InstrMapTable_Default:
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	.byte 0x03, 0x09, 0x0a
	reti
	.byte 0x04, 0x02
	halt
	ei	0x06
	nop
	nop
	.byte 0x01, 0x02
	ldio	10, 3
	ldio	4, 0
	ccf
	zcf
	.byte 0x14
	nop
	halt
	nop
	nop
	halt
	nop
	nop
	.byte 0x01, 0x01
	ei	0x04
	halt
	.zero 8
	nop
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	.byte 0x03, 0x09, 0x0a
	reti
	.byte 0x04, 0x02
	halt
	ei	0x06
	.byte 0x0b, 0x0c, 0x0e
	retd	0x0a08
	rcf
	scf
	.byte 0x04
	decf
	ccf
	zcf
	.byte 0x14
	nop
	halt
	incf
	decf
	halt
	incf
	decf
	.byte 0x01, 0x01
	ei	0x04
	halt
	.byte 0x0b, 0x10, 0x00
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	.byte 0x03, 0x09, 0x0a
	reti
	.byte 0x04, 0x02
	halt
	ei	0x06
	nop
	nop
	.byte 0x01, 0x02
	ldio	10, 3
	ldio	4, 0
	ccf
	zcf
	.byte 0x14
	nop
	halt
	nop
	nop
	halt
	nop
	nop
	.byte 0x01, 0x01
	ei	0x04
	halt
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

Rhythm_TransposeNote:
	ldda8 a, 13017
	bitda 3, 13044
	jr z, Rhythm_Transp_CheckZero
	ldda8 a, 13018

Rhythm_Transp_CheckZero:
	cps a, 0
	jr nz, Rhythm_Transp_Apply
	ldb a, 0x0
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	dec 1, a
	cpda8 a, 13003
	jr ugt, Rhythm_Transp_NegativeOctave
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_JumpToWrap
	sub w, 0xC

Rhythm_Transp_JumpToWrap:
	jr Rhythm_Transp_WrapCheck

Rhythm_Transp_NegativeOctave:
	sub a, 0xC
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_WrapCheck
	add w, 0xC

Rhythm_Transp_WrapCheck:
	cpdi8 13004, 12
	jr c, Rhythm_Transp_FinalCheck

Rhythm_Transp_WrapLoop:
	cpda8 w, 13004
	jr c, Rhythm_Transp_FinalCheck
	sub w, 0xC
	jr Rhythm_Transp_WrapLoop

Rhythm_Transp_FinalCheck:
	ld a, w
	bitda 0, 13101
	jr z, Rhythm_Transp_Done
	cpda8 a, 13102
	jr nc, Rhythm_Transp_Done
	add a, 0xC

Rhythm_Transp_Done:
	anddi8 13101, 254
	ret

Rhythm_VoiceMapLookup:
	push xiy
	push xhl
	cpdi8 13016, 0
	jr nz, Rhythm_VoiceMap_CheckInstr
	ldb a, 0x0
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckInstr:
	bitda 4, 13044
	jr z, Rhythm_VoiceMap_CheckBit4
	anddi8 13044, 239
	jrl Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckBit4:
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_VoiceMap_ClampInstr
	xor l, l

Rhythm_VoiceMap_ClampInstr:
	ld xiy, 0xF5526F
	bitda 3, 13044
	jr z, Rhythm_VoiceMap_SelectTable
	ld xiy, 0xF552A0

Rhythm_VoiceMap_SelectTable:
	ld_srib3 L, 0x03, 0xF4, 0xEC
	cps l, 0
	jr z, Rhythm_VoiceMap_ApplyBase
	ldda8 h, 13363
	cps l, 1
	jr z, Rhythm_VoiceMap_CheckMute
	ldda8 h, 13364

Rhythm_VoiceMap_CheckMute:
	bit 5, h
	jr z, Rhythm_VoiceMap_CheckDir
	ldb a, 0x0
	jr Rhythm_VoiceMap_Done

Rhythm_VoiceMap_CheckDir:
	bit 4, h
	jr nz, Rhythm_VoiceMap_SubShift
	and h, 0xF
	add a, h
	jr Rhythm_VoiceMap_ApplyBase

Rhythm_VoiceMap_SubShift:
	and h, 0xF
	sub a, h

Rhythm_VoiceMap_ApplyBase:
	ld w, a
	calr Rhythm_InstrBaseLookup
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_VoiceMap_Inst2Clamp
	xor l, l

Rhythm_VoiceMap_Inst2Clamp:
	ld xiy, 0xF550CA
	bitda 2, 13044
	jr z, Rhythm_VoiceMap_Inst2Bit2
	ld xiy, 0xF550FB

Rhythm_VoiceMap_Inst2Bit2:
	bitda 3, 13044
	jr z, Rhythm_VoiceMap_Inst2Bit3
	ld xiy, 0xF5512C

Rhythm_VoiceMap_Inst2Bit3:
	ld_srib3 L, 0x03, 0xF4, 0xEC
	extz hl
	sla hl, 4
	ld xiy, 0xE461C2
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld_srib3 A, 0x03, 0xF4, 0xE0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VoiceMap_Done:
	pop xhl
	pop xiy
	ret

Rhythm_PitchShiftTable_Default:
	nop
	nop
	.byte 0x01, 0x01
	nop
	.byte 0x02, 0x01, 0x01, 0x02, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01
	.fill 8, 1, 0x01
	nop
	.byte 0x02
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x01, 0x01, 0x01, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x01, 0x01
	nop
	.byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.fill 8, 1, 0x01
	.byte 0x01
	nop
	.byte 0x02
	nop
	nop
	nop
	nop
	nop
	nop
	nop

Rhythm_VelocityCompute:
	push xiy
	push xhl
	ld w, a
	calr Rhythm_InstrBaseLookup
	cpdi8 13016, 0
	jr nz, Rhythm_VelComp_CheckBit4
	ldb a, 0x0
	jr Rhythm_VelComp_Done

Rhythm_VelComp_CheckBit4:
	bitda 4, 13044
	jr z, Rhythm_VelComp_ClampInstr
	anddi8 13044, 239
	ld a, w
	jr Rhythm_VelComp_Done

Rhythm_VelComp_ClampInstr:
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_VelComp_SelectTable
	xor l, l

Rhythm_VelComp_SelectTable:
	ld xiy, 0xF5532E
	bitda 2, 13044
	jr z, Rhythm_VelComp_Lookup
	ld xiy, 0xF5535F

Rhythm_VelComp_Lookup:
	ld_srib3 L, 0x03, 0xF4, 0xEC
	extz hl
	sla hl, 4
	ld xiy, 0xE461C2
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld_srib3 A, 0x03, 0xF4, 0xE0
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelComp_Done:
	pop xhl
	pop xiy
	ret

Rhythm_VelocityTable_A:
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	.byte 0x03
	nop
	ldwio	7, 516
	halt
	ei	0x06
	nop
	nop
	.byte 0x01, 0x02
	ldio	10, 3
	ldio	4, 0
	ccf
	zcf
	.byte 0x14
	nop
	halt
	nop
	nop
	halt
	nop
	nop
	.byte 0x01, 0x01
	ei	0x04
	halt
	.zero 8
	nop
	nop
	nop
	nop
	.byte 0x01
	halt
	nop
	.byte 0x03
	nop
	ldwio	7, 516
	halt
	ei	0x06
	.byte 0x0b, 0x0c, 0x0e
	retd	0x0a08
	rcf
	scf
	.byte 0x04
	decf
	ccf
	zcf
	.byte 0x14
	nop
	halt
	incf
	decf
	halt
	incf
	decf
	.byte 0x01, 0x01
	ei	0x04
	halt
	.byte 0x0b, 0x10, 0x00
	nop
	nop
	nop
	nop
	nop
	nop

Rhythm_FourChannelDispatch:
	calr Rhythm_DispatchCh_D7
	calr Rhythm_DispatchCh_D4
	calr Rhythm_DispatchCh_D5
	calr Rhythm_DispatchCh_D6
	ret

Rhythm_DispatchCh_D7:
	ldda8 a, 12995
	stda8 13003, a
	ldda8 a, 12999
	stda8 13004, a
	anddi8 13044, 251
	ordi8 13044, 8
	ldb w, 0x97
	ld xix, 0x30F4

Rhythm_DispatchCh_D7_Loop:
	stdi8 13268, 4
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x313C
	jr c, Rhythm_DispatchCh_D7_Loop
	ret

Rhythm_DispatchCh_D4:
	ldda8 a, 12996
	stda8 13003, a
	ldda8 a, 13000
	stda8 13004, a
	anddi8 13044, 247
	ordi8 13044, 4
	ldb w, 0x94
	ld xix, 0x313C

Rhythm_DispatchCh_D4_Loop:
	stdi8 13268, 8
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x3184
	jr c, Rhythm_DispatchCh_D4_Loop
	ret

Rhythm_DispatchCh_D5:
	ldda8 a, 12997
	stda8 13003, a
	ldda8 a, 13001
	stda8 13004, a
	anddi8 13044, 243
	ldb w, 0x95
	ld xix, 0x3184

Rhythm_DispatchCh_D5_Loop:
	stdi8 13268, 16
	calr Rhythm_SingleNoteHandler
	add xix, 0x9
	cp xix, 0x31CC
	jr c, Rhythm_DispatchCh_D5_Loop
	ret

Rhythm_DispatchCh_D6:
	ldda8 a, 12998
	stda8 13003, a
	ldda8 a, 13002
	stda8 13004, a
	anddi8 13044, 243
	ldb w, 0x96
	ld xix, 0x31CC

Rhythm_DispatchCh_D6_Loop:
	stdi8 13268, 32
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
	cpdi8 13029, 240
	jr c, Rhythm_Validate_Mismatch
	ldda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	andda8 a, 13268
	jr nz, Rhythm_Validate_Mismatch
	ldda8 a, 13023
	stda8 13347, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 13346
	stda8 13348, a
	ldda8 a, 13016
	stda8 13347, a
	call AccTuning_CallWithSaveRestore
	ldda8 a, 13346
	cpdm8 13348, a
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
	bitda 4, 13044
	jr nz, Rhythm_MatchedPhrase_Output
	bitda 3, 13044
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
	bitda 4, 13044
	jr nz, Rhythm_Mismatch90_Output
	bitda 3, 13044
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
	stda8 13360, a
	ld a, (xix + 6)
	stda8 13363, a
	ld a, (xix + 7)
	stda8 13364, a
	ld a, (xix + 8)
	calr Rhythm_CheckVelocityThreshold
	bitda 4, 13044
	jr nz, Rhythm_MismatchOther_Output
	bitda 3, 13044
	jr z, Rhythm_MismatchOther_PostRange
	calr Rhythm_CrossVoiceCorrect

Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	calr Rhythm_VoiceMapLookup
	ld (xix + 2), a
	ldda8 a, 13360
	ld (xix + 3), a
	popw wa

Rhythm_MismatchOther_Return:
	ret

Rhythm_Send_Ch90_7F_7E:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x7E
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_04:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x4
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_05:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x5
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_06:
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x6
	call Rhythm_Send3ByteMsg
	ret

Rhythm_Send_Ch90_7F_07:
	ldb a, 0x90
	ldb w, 0x7F
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
	cpdi8 13103, 0
	jr z, Rhythm_AllNotesOff_D7_Skip
	ldb a, 0xD7
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D7_Skip:
	ret

Rhythm_AllNotesOff_D4:
	cpdi8 13104, 0
	jr z, Rhythm_AllNotesOff_D4_Skip
	ldb a, 0xD4
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D4_Skip:
	ret

Rhythm_AllNotesOff_D5:
	cpdi8 13105, 0
	jr z, Rhythm_AllNotesOff_D5_Skip
	ldb a, 0xD5
	ldb w, 0x3
	ldb e, 0x0
	call Rhythm_Send3ByteMsg

Rhythm_AllNotesOff_D5_Skip:
	ret

Rhythm_AllNotesOff_D6:
	cpdi8 13106, 0
	jr z, Rhythm_AllNotesOff_D6_Done
	ldb a, 0xD6
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
	cpdi8 13103, 0
	jr z, Rhythm_SendVolume_D7_Skip
	ldb a, 0xD7
	ldb w, 0x3
	ldda8 e, 13103
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	cpdi8 13104, 0
	jr z, Rhythm_SendVolume_D4_Skip
	ldb a, 0xD4
	ldb w, 0x3
	ldda8 e, 13104
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	cpdi8 13105, 0
	jr z, Rhythm_SendVolume_D5_Skip
	ldb a, 0xD5
	ldb w, 0x3
	ldda8 e, 13105
	call Rhythm_Send3ByteMsg

Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	cpdi8 13106, 0
	jr z, Rhythm_SendVolume_D6_Done
	ldb a, 0xD6
	ldb w, 0x3
	ldda8 e, 13106
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
	cpdi8 13103, 0
	jr z, Rhythm_NoteOffMax_D7_Skip
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x77
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D7_Skip:
	ret

Rhythm_NoteOffMax_D4:
	cpdi8 13104, 0
	jr z, Rhythm_NoteOffMax_D4_Skip
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x74
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D4_Skip:
	ret

Rhythm_NoteOffMax_D5:
	cpdi8 13105, 0
	jr z, Rhythm_NoteOffMax_D5_Skip
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x75
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D5_Skip:
	ret

Rhythm_NoteOffMax_D6:
	cpdi8 13106, 0
	jr z, Rhythm_NoteOffMax_D6_Done
	ldb a, 0x90
	ldb w, 0x7F
	ldb e, 0x76
	call Rhythm_Send3ByteMsg

Rhythm_NoteOffMax_D6_Done:
	ret

Rhythm_AdvanceTick:
	ldda16 xwa, 13027
	stda8 13142, w
	ldda8 a, 12927
	ldda8 w, 12928
	stda8 13349, w
	add a, 0x18
	cp a, 0x60
	jr c, Rhythm_AdvanceTick_Store
	sub a, 0x60
	inc 1, w
	cpda8 w, 1112
	jr c, Rhythm_AdvanceTick_Store
	xor w, w

Rhythm_AdvanceTick_Store:
	stda16 13027, xwa
	ret

Rhythm_SaveState:
	ldda8 a, 13045
	stda8 13046, a
	ldda8 a, 13047
	stda8 13048, a
	ldda8 a, 13049
	stda8 13050, a
	ldda8 a, 13051
	stda8 13052, a
	ldda8 a, 13055
	stda8 13056, a
	ldda8 a, 13053
	stda8 13054, a
	ldda8 a, 13057
	stda8 13058, a
	ldda8 a, 13059
	stda8 13060, a
	ldda8 a, 13061
	stda8 13062, a
	ldda8 a, 13063
	stda8 13064, a
	ldda8 a, 13424
	stda8 12929, a
	ldda8 a, 36148
	stda8 13041, a
	ldda8 a, 13109
	stda8 13042, a
	ldda8 a, 13288
	stda8 13289, a
	ldda8 a, 12931
	and a, 0xFD
	bit 0, a
	jr z, Rhythm_SaveState_StoreBits
	or a, 0x2

Rhythm_SaveState_StoreBits:
	stda8 12931, a
	ordi8 13043, 1
	cpdi8 12928, 0
	jr nz, Rhythm_SaveState_CheckFx
	cpdi8 12927, 48
	jr c, Rhythm_SaveState_CheckFx
	anddi8 13097, 192

Rhythm_SaveState_CheckFx:
	ldda8 a, 13067
	and a, 0x3
	jr nz, Rhythm_SaveState_FxActive
	bitda 0, 13068
	jr z, Rhythm_SaveState_ClearFx

Rhythm_SaveState_FxActive:
	ldda8 a, 13094
	and a, 0x3F
	jr nz, Rhythm_SaveState_CheckFx2
	anddi8 13067, 252
	anddi8 13068, 254
	jr Rhythm_SaveState_CheckFx2

Rhythm_SaveState_ClearFx:
	anddi8 13094, 192

Rhythm_SaveState_CheckFx2:
	ldda8 a, 13065
	and a, 0x3
	jr nz, Rhythm_SaveState_Fx2Active
	ldda8 a, 13066
	and a, 0xD
	jr z, Rhythm_SaveState_ClearFx2

Rhythm_SaveState_Fx2Active:
	ldda8 a, 13095
	and a, 0x3F
	jr nz, Rhythm_VoiceAssignDetect
	and a, 0xFC
	and a, 0xF2
	jr Rhythm_VoiceAssignDetect

Rhythm_SaveState_ClearFx2:
	anddi8 13095, 192

Rhythm_VoiceAssignDetect:
	ldda8 a, 13074
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ldda8 a, 13081
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_PartBDetect
	anddi8 64607, 191
	ldda8 a, 13075
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_PartAOn
	ordi8 64607, 128
	ordi8 13052, 2

Rhythm_VoiceAssign_PartAOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13052, 254
	anddi8 13099, 253
	ldda8 a, 13075
	orda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	orda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ordi8 12932, 16
	ordi8 12932, 4

Rhythm_VoiceAssign_PartBDetect:
	ldda8 a, 13075
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ldda8 a, 13082
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_Ext1Detect
	anddi8 64607, 127
	ldda8 a, 13074
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_PartBOn
	ordi8 64607, 64
	ordi8 13052, 1

Rhythm_VoiceAssign_PartBOn:
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13052, 253
	anddi8 13099, 251
	ldda8 a, 13074
	orda8 a, 13078
	orda8 a, 13079
	orda8 a, 13080
	orda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ordi8 12932, 16
	ordi8 12932, 4

Rhythm_VoiceAssign_Ext1Detect:
	ldda8 a, 13078
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ldda8 a, 13085
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_Ext2Detect
	anddi8 64607, 251
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13056, 254
	ldda8 a, 13079
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ordi8 12932, 8

Rhythm_VoiceAssign_Ext2Detect:
	ldda8 a, 13079
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ldda8 a, 13086
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_Ext3Detect
	anddi8 64607, 247
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13056, 253
	ldda8 a, 13078
	orda8 a, 13080
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ordi8 12932, 8

Rhythm_VoiceAssign_Ext3Detect:
	ldda8 a, 13080
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ldda8 a, 13087
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_Perc1Detect
	anddi8 64608, 251
	ldb e, 0x48
	ldb d, 0x6
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13056, 251
	ldda8 a, 13078
	orda8 a, 13079
	orda8 a, 13074
	orda8 a, 13075
	orda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ordi8 12932, 8

Rhythm_VoiceAssign_Perc1Detect:
	ldda8 a, 13076
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_Perc2Detect
	ldda8 a, 13083
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_Perc2Detect
	anddi8 64607, 239
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13053, 254
	ordi8 12932, 4

Rhythm_VoiceAssign_Perc2Detect:
	ldda8 a, 13077
	and a, 0x3F
	jr nz, Rhythm_VoiceAssign_SaveShadow
	ldda8 a, 13084
	and a, 0x3F
	jr z, Rhythm_VoiceAssign_SaveShadow
	anddi8 64607, 223
	ldb e, 0x48
	ldb d, 0x5
	ldb a, 0x0
	ldb w, 0x0
	calr Rhythm_QueuePartChangeEvent
	anddi8 13053, 253
	ordi8 12932, 4

Rhythm_VoiceAssign_SaveShadow:
	ldda8 a, 13074
	stda8 13081, a
	ldda8 a, 13075
	stda8 13082, a
	ldda8 a, 13078
	stda8 13085, a
	ldda8 a, 13079
	stda8 13086, a
	ldda8 a, 13080
	stda8 13087, a
	ldda8 a, 13076
	stda8 13083, a
	ldda8 a, 13077
	stda8 13084, a
	ldda8 a, 13029
	stda8 13168, a
	ldda8 a, 13116
	stda8 13118, a
	call AccTuning_SaveState
	calr Rhythm_SeqResetCheck
	ret

Rhythm_SeqResetCheck:
	bitda 2, 13519
	jr z, Rhythm_SeqReset_UpdateFlags
	bitda 4, 13519
	jr nz, Rhythm_SeqReset_UpdateFlags
	ldda8 l, 14235
	xor h, h
	sla l, 2
	ld xiy, 0xF55A8C
	ld_sril3 XIX, 0x07, 0xF4, 0xEC
	cp xix, 0x0
	jr z, Rhythm_SeqReset_UpdateFlags
	ei 6
	ld hl, (xix + 6)
	ld (xix + 4), hl
	ei 0

Rhythm_SeqReset_UpdateFlags:
	ldda8 a, 13519
	and a, 0xEF
	bit 2, a
	jr z, Rhythm_SeqReset_Store
	or a, 0x10

Rhythm_SeqReset_Store:
	stda8 13519, a
	ret

Rhythm_SeqResetTable:
	nop
	nop
	nop
	nop
	.byte 0x94, 0x2d
	nop
	nop
	.byte 0x94, 0x2e
	nop
	nop
	nop
	nop
	nop
	nop
	.byte 0x94, 0x2f
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 8
	.byte 0x94, 0x2c
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 24
	.byte 0x94, 0x2a
	nop
	nop

Rhythm_TransposeWithMod:
	cpdi8 13016, 0
	jr z, Rhythm_TranspMod_Return
	cpdi8 13017, 0
	jr z, Rhythm_TranspMod_Return
	bitda 2, 13285
	jr nz, Rhythm_TranspMod_Return
	bitda 1, 13285
	jr z, Rhythm_TranspMod_ApplyBoth
	calr Rhythm_TranspMod_ModCheck
	bitda 0, 13285
	jr nz, Rhythm_TranspMod_Return

Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	anddi8 13285, 254
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_TranspMod_LookupTable
	xor l, l

Rhythm_TranspMod_LookupTable:
	ld xiy, 0xF5526F
	ld_srib3 L, 0x03, 0xF4, 0xEC
	cps l, 0
	jr z, Rhythm_TranspMod_Done
	ldda8 h, 13286
	cps l, 1
	jr z, Rhythm_TranspMod_Offset1
	ldda8 h, 13287

Rhythm_TranspMod_Offset1:
	bit 5, h
	jr z, Rhythm_TranspMod_MuteCheck
	ldb a, 0x0
	ordi8 13285, 1
	jr Rhythm_TranspMod_Done

Rhythm_TranspMod_MuteCheck:
	bit 4, h
	jr nz, Rhythm_TranspMod_SubOffset
	and h, 0xF
	add a, h
	jr Rhythm_TranspMod_Done

Rhythm_TranspMod_SubOffset:
	and h, 0xF
	sub a, h

Rhythm_TranspMod_Done:
	ret

Rhythm_TranspMod_BaseApply:
	ld w, a
	ld xiy, 0xE46142
	ld_srib3 A, 0x03, 0xF4, 0xE0
	ldda8 l, 13016
	cp l, 0x30
	jr c, Rhythm_TranspMod_BaseLookup
	xor l, l

Rhythm_TranspMod_BaseLookup:
	extz hl
	ld xiy, 0xF550FB
	ld_srib3 L, 0x07, 0xF4, 0xEC
	extz hl
	sla hl, 4
	ld xiy, 0xE461C2
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld_srib3 A, 0x03, 0xF4, 0xE0
	add w, a
	ret

Rhythm_TranspMod_OctaveWrap:
	ldda8 a, 13017
	dec 1, a
	cps a, 7
	jr nc, Rhythm_TranspMod_WrapNeg
	add w, a
	bit 7, w
	jr z, Rhythm_TranspMod_WrapJump
	sub w, 0xC

Rhythm_TranspMod_WrapJump:
	jr Rhythm_TranspMod_WrapClamp

Rhythm_TranspMod_WrapNeg:
	sub a, 0xC
	add w, a
	bit 7, w
	jr z, Rhythm_TranspMod_WrapClamp
	add w, 0xC

Rhythm_TranspMod_WrapClamp:
	cp w, 0x7F
	jr ule, Rhythm_TranspMod_WrapDone
	sub w, 0xC
	jr Rhythm_TranspMod_WrapClamp

Rhythm_TranspMod_WrapDone:
	ld a, w
	ret

Rhythm_TailPadding:
	call	16069687
	ret

