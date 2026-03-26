; =============================================================================
; Rhythm Pattern Routines
; =============================================================================
;
; Rhythm pattern comparison, trigger logic, and transposition.
; Evaluates accompaniment pattern matching and rhythm dispatch.
; =============================================================================

Rhythm_CompareAndTrigger:
	.incbin "includes/generated/v7_transplant_Rhythm_CompareAndTrigger.bin"
Rhythm_CompareAndTriggerNotes:
	.incbin "includes/generated/v7_transplant_Rhythm_CompareAndTriggerNotes.bin"
Rhythm_CompareNoteA_Only:
	.incbin "includes/generated/v7_transplant_Rhythm_CompareNoteA_Only.bin"
Rhythm_CompareNoteB:
	.incbin "includes/generated/v7_transplant_Rhythm_CompareNoteB.bin"
Rhythm_CompareNoteC:
	.incbin "includes/generated/v7_transplant_Rhythm_CompareNoteC.bin"
Rhythm_SaveCurrentNoteState:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveCurrentNoteState.bin"
Rhythm_SaveNoteState:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveNoteState.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_SetupChannel_D7.bin"
Rhythm_SetupChannel_D4:
	.incbin "includes/generated/v7_transplant_Rhythm_SetupChannel_D4.bin"
Rhythm_SetupChannel_D5:
	.incbin "includes/generated/v7_transplant_Rhythm_SetupChannel_D5.bin"
Rhythm_SetupChannel_D6:
	.incbin "includes/generated/v7_transplant_Rhythm_SetupChannel_D6.bin"
RhythmEvt_ProcessNote:
	.incbin "includes/generated/v7_transplant_RhythmEvt_ProcessNote.bin"
RhythmEvt_AlternateProcess:
	call RhythmEvt_FullProcess

RhythmEvt_Return:
	ret

RhythmEvt_IterateNoteOn:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

RhythmEvt_NoteOnLoop:
	.incbin "includes/generated/v7_transplant_RhythmEvt_NoteOnLoop.bin"
RhythmEvt_NoteOn90:
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	jr RhythmEvt_ApplyTranspose

RhythmEvt_NoteOn91:
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition

RhythmEvt_ApplyTranspose:
	.incbin "includes/generated/v7_transplant_RhythmEvt_ApplyTranspose.bin"
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
	.incbin "includes/generated/v7_transplant_RhythmEvt_SkipUnknown.bin"
RhythmEvt_IterDone:
	ret

RhythmEvt_FullProcess:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

RhythmEvt_FullLoop:
	.incbin "includes/generated/v7_transplant_RhythmEvt_FullLoop.bin"
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
	.incbin "includes/generated/v7_transplant_RhythmEvt_Full91.bin"
RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	.incbin "includes/generated/v7_transplant_RhythmEvt_Full91_PostTransp.bin"
RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	.incbin "includes/generated/v7_transplant_Rhythm_CheckVelocityThreshold.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_CrossVoiceCorrect.bin"
Rhythm_CrossVoice_Apply:
	.incbin "includes/generated/v7_transplant_Rhythm_CrossVoice_Apply.bin"
Rhythm_CrossVoice_ClearFlag:
	.incbin "includes/generated/v7_transplant_Rhythm_CrossVoice_ClearFlag.bin"
Rhythm_NoteRangeCheck:
	.incbin "includes/generated/v7_transplant_Rhythm_NoteRangeCheck.bin"
Rhythm_NoteRangeReturn:
	ret

Rhythm_NoteRangeData:
	.byte 0x00, 0x00

Rhythm_VelocityLookup_A:
	.incbin "includes/generated/v7_transplant_Rhythm_VelocityLookup_A.bin"
Rhythm_VelLookA_CheckEmpty:
	.incbin "includes/generated/v7_transplant_Rhythm_VelLookA_CheckEmpty.bin"
Rhythm_VelLookA_CheckRange:
	.incbin "includes/generated/v7_transplant_Rhythm_VelLookA_CheckRange.bin"
Rhythm_VelLookA_SelectTable:
	.incbin "includes/generated/v7_transplant_Rhythm_VelLookA_SelectTable.bin"
Rhythm_VelLookA_CheckBit3:
	.incbin "includes/generated/v7_transplant_Rhythm_VelLookA_CheckBit3.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_TransposeNote.bin"
Rhythm_Transp_CheckZero:
	cps a, 0
	jr nz, Rhythm_Transp_Apply
	ldb a, 0x0
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	.incbin "includes/generated/v7_transplant_Rhythm_Transp_Apply.bin"
Rhythm_Transp_JumpToWrap:
	jr Rhythm_Transp_WrapCheck

Rhythm_Transp_NegativeOctave:
	sub a, 0xc
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_WrapCheck
	add w, 0xc

Rhythm_Transp_WrapCheck:
	.incbin "includes/generated/v7_transplant_Rhythm_Transp_WrapCheck.bin"
Rhythm_Transp_WrapLoop:
	.incbin "includes/generated/v7_transplant_Rhythm_Transp_WrapLoop.bin"
Rhythm_Transp_FinalCheck:
	.incbin "includes/generated/v7_transplant_Rhythm_Transp_FinalCheck.bin"
Rhythm_Transp_Done:
	.incbin "includes/generated/v7_transplant_Rhythm_Transp_Done.bin"
Rhythm_VoiceMapLookup:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMapLookup.bin"
Rhythm_VoiceMap_CheckInstr:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_CheckInstr.bin"
Rhythm_VoiceMap_CheckBit4:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_CheckBit4.bin"
Rhythm_VoiceMap_ClampInstr:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_ClampInstr.bin"
Rhythm_VoiceMap_SelectTable:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_SelectTable.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_ApplyBase.bin"
Rhythm_VoiceMap_Inst2Clamp:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_Inst2Clamp.bin"
Rhythm_VoiceMap_Inst2Bit2:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceMap_Inst2Bit2.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_VelocityCompute.bin"
Rhythm_VelComp_CheckBit4:
	.incbin "includes/generated/v7_transplant_Rhythm_VelComp_CheckBit4.bin"
Rhythm_VelComp_ClampInstr:
	.incbin "includes/generated/v7_transplant_Rhythm_VelComp_ClampInstr.bin"
Rhythm_VelComp_SelectTable:
	.incbin "includes/generated/v7_transplant_Rhythm_VelComp_SelectTable.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D7.bin"
Rhythm_DispatchCh_D7_Loop:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D7_Loop.bin"
Rhythm_DispatchCh_D4:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D4.bin"
Rhythm_DispatchCh_D4_Loop:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D4_Loop.bin"
Rhythm_DispatchCh_D5:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D5.bin"
Rhythm_DispatchCh_D5_Loop:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D5_Loop.bin"
Rhythm_DispatchCh_D6:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D6.bin"
Rhythm_DispatchCh_D6_Loop:
	.incbin "includes/generated/v7_transplant_Rhythm_DispatchCh_D6_Loop.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_ValidateAndSend.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_MatchedPhrase_Process.bin"
Rhythm_MatchedPhrase_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MatchedPhrase_Output:
	calr Rhythm_VelocityCompute
	ld (xix + 2), a
	popw wa
	ret

Rhythm_MismatchedPhrase:
	.incbin "includes/generated/v7_transplant_Rhythm_MismatchedPhrase.bin"
Rhythm_Mismatch90_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_Mismatch90_Output:
	calr Rhythm_VelocityLookup_A
	ld (xix + 2), a
	popw wa
	jr Rhythm_MismatchOther_Return

Rhythm_MismatchOther:
	.incbin "includes/generated/v7_transplant_Rhythm_MismatchOther.bin"
Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	.incbin "includes/generated/v7_transplant_Rhythm_MismatchOther_Output.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_AllNotesOff_D7.bin"
Rhythm_AllNotesOff_D7_Skip:
	ret

Rhythm_AllNotesOff_D4:
	.incbin "includes/generated/v7_transplant_Rhythm_AllNotesOff_D4.bin"
Rhythm_AllNotesOff_D4_Skip:
	ret

Rhythm_AllNotesOff_D5:
	.incbin "includes/generated/v7_transplant_Rhythm_AllNotesOff_D5.bin"
Rhythm_AllNotesOff_D5_Skip:
	ret

Rhythm_AllNotesOff_D6:
	.incbin "includes/generated/v7_transplant_Rhythm_AllNotesOff_D6.bin"
Rhythm_AllNotesOff_D6_Done:
	ret

Rhythm_SendVolume_Dispatch:
	calr Rhythm_SendVolume_D7
	calr Rhythm_SendVolume_D4
	calr Rhythm_SendVolume_D5
	calr Rhythm_SendVolume_D6
	ret

Rhythm_SendVolume_D7:
	.incbin "includes/generated/v7_transplant_Rhythm_SendVolume_D7.bin"
Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	.incbin "includes/generated/v7_transplant_Rhythm_SendVolume_D4.bin"
Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	.incbin "includes/generated/v7_transplant_Rhythm_SendVolume_D5.bin"
Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	.incbin "includes/generated/v7_transplant_Rhythm_SendVolume_D6.bin"
Rhythm_SendVolume_D6_Done:
	ret

Rhythm_NoteOffMax_Dispatch:
	calr Rhythm_NoteOffMax_D7
	calr Rhythm_NoteOffMax_D4
	calr Rhythm_NoteOffMax_D5
	calr Rhythm_NoteOffMax_D6
	ret

Rhythm_NoteOffMax_D7:
	.incbin "includes/generated/v7_transplant_Rhythm_NoteOffMax_D7.bin"
Rhythm_NoteOffMax_D7_Skip:
	ret

Rhythm_NoteOffMax_D4:
	.incbin "includes/generated/v7_transplant_Rhythm_NoteOffMax_D4.bin"
Rhythm_NoteOffMax_D4_Skip:
	ret

Rhythm_NoteOffMax_D5:
	.incbin "includes/generated/v7_transplant_Rhythm_NoteOffMax_D5.bin"
Rhythm_NoteOffMax_D5_Skip:
	ret

Rhythm_NoteOffMax_D6:
	.incbin "includes/generated/v7_transplant_Rhythm_NoteOffMax_D6.bin"
Rhythm_NoteOffMax_D6_Done:
	ret

Rhythm_AdvanceTick:
	.incbin "includes/generated/v7_transplant_Rhythm_AdvanceTick.bin"
Rhythm_AdvanceTick_Store:
	.incbin "includes/generated/v7_transplant_Rhythm_AdvanceTick_Store.bin"
Rhythm_SaveState:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState.bin"
Rhythm_SaveState_StoreBits:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_StoreBits.bin"
Rhythm_SaveState_CheckFx:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_CheckFx.bin"
Rhythm_SaveState_FxActive:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_FxActive.bin"
Rhythm_SaveState_ClearFx:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_ClearFx.bin"
Rhythm_SaveState_CheckFx2:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_CheckFx2.bin"
Rhythm_SaveState_Fx2Active:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_Fx2Active.bin"
Rhythm_SaveState_ClearFx2:
	.incbin "includes/generated/v7_transplant_Rhythm_SaveState_ClearFx2.bin"
Rhythm_VoiceAssignDetect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssignDetect.bin"
Rhythm_VoiceAssign_PartAOn:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_PartAOn.bin"
Rhythm_VoiceAssign_PartBDetect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_PartBDetect.bin"
Rhythm_VoiceAssign_PartBOn:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_PartBOn.bin"
Rhythm_VoiceAssign_Ext1Detect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_Ext1Detect.bin"
Rhythm_VoiceAssign_Ext2Detect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_Ext2Detect.bin"
Rhythm_VoiceAssign_Ext3Detect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_Ext3Detect.bin"
Rhythm_VoiceAssign_Perc1Detect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_Perc1Detect.bin"
Rhythm_VoiceAssign_Perc2Detect:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_Perc2Detect.bin"
Rhythm_VoiceAssign_SaveShadow:
	.incbin "includes/generated/v7_transplant_Rhythm_VoiceAssign_SaveShadow.bin"
Rhythm_SeqResetCheck:
	.incbin "includes/generated/v7_transplant_Rhythm_SeqResetCheck.bin"
Rhythm_SeqReset_UpdateFlags:
	.incbin "includes/generated/v7_transplant_Rhythm_SeqReset_UpdateFlags.bin"
Rhythm_SeqReset_Store:
	.incbin "includes/generated/v7_transplant_Rhythm_SeqReset_Store.bin"
Rhythm_SeqResetTable:
	.incbin "includes/generated/v7_transplant_Rhythm_SeqResetTable.bin"
Rhythm_TransposeWithMod:
	.incbin "includes/generated/v7_transplant_Rhythm_TransposeWithMod.bin"
Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	.incbin "includes/generated/v7_transplant_Rhythm_TranspMod_ModCheck.bin"
Rhythm_TranspMod_LookupTable:
	.incbin "includes/generated/v7_transplant_Rhythm_TranspMod_LookupTable.bin"
Rhythm_TranspMod_Offset1:
	.incbin "includes/generated/v7_transplant_Rhythm_TranspMod_Offset1.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_TranspMod_BaseApply.bin"
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
	.incbin "includes/generated/v7_transplant_Rhythm_TranspMod_OctaveWrap.bin"
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

