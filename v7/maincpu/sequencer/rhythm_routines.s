; =============================================================================
; Rhythm Pattern Routines
; =============================================================================
;
; Rhythm pattern comparison, trigger logic, and transposition.
; Evaluates accompaniment pattern matching and rhythm dispatch.
; =============================================================================

Rhythm_CompareAndTrigger:
	bit 0, (0x31e7:16)
	jrl z, Rhythm_SaveNoteState
	bit 6, (0x28ac:16)
	jr z, .Lc_f54842
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, .Lc_f54842
	ld a, (0x31e3:16)
	cp A,0x12
	jr ule, .Lc_f54842
	cp A,0x5c
	jr ugt, .Lc_f54842
	jrl t, Rhythm_SaveNoteState
Rhythm_CompareAndTriggerNotes:
.Lc_f54842:
	bit 1, (0x323b:16)
	jr nz, Rhythm_CompareNoteA_Only
	ld a, (0x323c:16)
	ld w, (0x323d:16)
	ld l, (0x3243:16)
	ld h, (0x3244:16)
	cp WA,HL
	jr z, Rhythm_SaveCurrentNoteState
	calr Rhythm_NoteOnAfterSetup_A
	jr t, Rhythm_SaveCurrentNoteState
Rhythm_CompareNoteA_Only:
	ld	a, (12860:16)
	ld	w, (12867:16)
	cp	a, w
	jr	z, Rhythm_CompareNoteB
	calr	Rhythm_NoteOnAfterSetup_A
	jr	Rhythm_SaveCurrentNoteState
Rhythm_CompareNoteB:
	ld	a, (12861:16)
	ld	w, (12868:16)
	cp	a, w
	jr	z, Rhythm_CompareNoteC
	calr	Rhythm_NoteOnAfterSetup_B
Rhythm_CompareNoteC:
	ld	a, (12862:16)
	ld	w, (12869:16)
	cp	a, w
	jr	z, Rhythm_SaveCurrentNoteState
	calr	Rhythm_NoteOnAfterSetup_C
Rhythm_SaveCurrentNoteState:
	ld	a, (12860:16)
	ld	(12867:16), a
	ld	a, (12861:16)
	ld	(12868:16), a
	ld	a, (12862:16)
	ld	(12869:16), a
Rhythm_SaveNoteState:
	ld	a, (12860:16)
	ld	(12864:16), a
	ld	a, (12861:16)
	ld	(12865:16), a
	ld	a, (12862:16)
	ld	(12866:16), a
	ld	a, (12859:16)
	ld	(12863:16), a
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
	ld XHL,0x00002bf8
	ld a, (0x3227:16)
	ld (0x322f:16), a
	ld a, (0x322b:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xfb
	or (0x3258:16), 0x08
	ld (0x3338:16), 0x04
	calr RhythmEvt_ProcessNote
	ret
Rhythm_SetupChannel_D4:
	ld XHL,0x00002cf8
	ld a, (0x3228:16)
	ld (0x322f:16), a
	ld a, (0x322c:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf7
	or (0x3258:16), 0x04
	ld (0x3338:16), 0x08
	calr RhythmEvt_ProcessNote
	ret
Rhythm_SetupChannel_D5:
	ld XHL,0x00002df8
	ld a, (0x3229:16)
	ld (0x322f:16), a
	ld a, (0x322d:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf3
	ld (0x3338:16), 0x10
	calr RhythmEvt_ProcessNote
	ret
Rhythm_SetupChannel_D6:
	ld XHL,0x00002ef8
	ld a, (0x322a:16)
	ld (0x322f:16), a
	ld a, (0x322e:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf3
	ld (0x3338:16), 0x20
	calr RhythmEvt_ProcessNote
	ret
RhythmEvt_ProcessNote:
	cp (0x3249:16), 0xf0
	jr c, RhythmEvt_AlternateProcess
	ld a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x327c:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, (0x3338:16)
	jr nz, RhythmEvt_AlternateProcess
	ld a, (0x3243:16)
	ld (0x3387:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3386:16)
	ld (0x3388:16), a
	ld a, (0x323c:16)
	ld (0x3387:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3386:16)
	cp (0x3388:16), a
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
	cp (XHL+0x04),IY
	jrl z, RhythmEvt_IterDone
	ld	a, (xhl+iy)
	ld (0x33c1:16), iy
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	cp A,0x90
	jr z, RhythmEvt_NoteOn90
	cp A,0x91
	jr z, RhythmEvt_NoteOn91
	jr t, RhythmEvt_SkipUnknown
RhythmEvt_NoteOn90:
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	jr RhythmEvt_ApplyTranspose

RhythmEvt_NoteOn91:
	calr Rhythm_AdvancePosition
	calr Rhythm_AdvancePosition

RhythmEvt_ApplyTranspose:
	ld	a, (xhl+iy)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x3258:16)
	jr nz, RhythmEvt_PostProcess
	bit 3, (0x3258:16)
	jr z, RhythmEvt_ApplyNoteRange
	calr Rhythm_CrossVoiceCorrect
RhythmEvt_ApplyNoteRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_PostProcess:
	calr Rhythm_VelocityCompute
	popw iy
	ld	(xhl+iy), a
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_NoteOnLoop

RhythmEvt_SkipUnknown:
	popw	iy
	ld	iy, (13249:16)
	call	RingBuf_AdvanceIndex
	jrl	RhythmEvt_NoteOnLoop
RhythmEvt_IterDone:
	ret

RhythmEvt_FullProcess:
	ld iy, (xhl + 6)
	ld bc, (xhl + 2)

RhythmEvt_FullLoop:
	cp (XHL+0x04),IY
	jrl z, RhythmEvt_FullDone
	ld	a, (xhl+iy)
	cp A,0x90
	jr nz, RhythmEvt_Full91
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	ld	a, (xhl+iy)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x3258:16)
	jr nz, RhythmEvt_Full90_PostTransp
	bit 3, (0x3258:16)
	jr z, RhythmEvt_Full90_PostRange
	calr Rhythm_CrossVoiceCorrect
RhythmEvt_Full90_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full90_PostTransp:
	calr Rhythm_VelocityLookup_A
	popw iy
	ld	(xhl+iy), a
	calr Rhythm_AdvancePosition
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	jr RhythmEvt_FullLoop

RhythmEvt_Full91:
	cp a, 145
	jr nz, RhythmEvt_FullSkip
	call RingBuf_AdvanceIndex
	call RingBuf_AdvanceIndex
	pushw iy
	call RingBuf_AdvanceIndex
	ld	a, (xhl+iy)
	ld (0x3394:16), a
	calr Rhythm_AdvancePosition
	ld	a, (xhl+iy)
	ld (0x3397:16), a
	call RingBuf_AdvanceIndex
	ld	a, (xhl+iy)
	ld (0x3398:16), a
	call RingBuf_AdvanceIndex
	ld	a, (xhl+iy)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x3258:16)
	jr nz, RhythmEvt_Full91_PostTransp
	bit 3, (0x3258:16)
	jr z, RhythmEvt_Full91_PostRange
	calr Rhythm_CrossVoiceCorrect
RhythmEvt_Full91_PostRange:
	calr Rhythm_NoteRangeCheck

RhythmEvt_Full91_PostTransp:
	calr Rhythm_VoiceMapLookup

	popw iy

	ld	(xhl+iy), a
	call RingBuf_AdvanceIndex	; call RingBuf_AdvanceIndex (v7 addr)
	ld a, (0x3394:16)	; ldb_d8 a, (0x3430) (v7 patched)



	ld	(xhl+iy), a
	calr Rhythm_AdvancePosition	; calr Rhythm_AdvancePosition (v7 displacement)
	calr Rhythm_AdvancePosition	; calr Rhythm_AdvancePosition (v7 displacement)
	jrl RhythmEvt_FullLoop	; jrl RhythmEvt_FullLoop (v7 displacement)






RhythmEvt_FullSkip:
	call RingBuf_AdvanceIndex
	jrl RhythmEvt_FullLoop

RhythmEvt_FullDone:
	ret

Rhythm_CheckVelocityThreshold:
	and (0x3258:16), 0xef
	cp A,0x78
	jr c, Rhythm_VelThreshReturn
	or (0x3258:16), 0x10
Rhythm_VelThreshReturn:
	ret

Rhythm_AdvancePosition:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvancePos_Step2
	ld iy, (xhl + 0:8)
	inc 2, iy
	jr Rhythm_AdvanceDone

Rhythm_AdvancePos_Step2:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvancePos_Step3
	ld iy, (xhl + 0:8)
	inc 1, iy
	jr Rhythm_AdvanceDone

Rhythm_AdvancePos_Step3:
	inc 1, iy
	cp iy, bc
	jr ule, Rhythm_AdvanceDone
	ld iy, (xhl + 0:8)

Rhythm_AdvanceDone:
	ret

Rhythm_CrossVoiceCorrect:
	bit 0, (0x323b:16)
	jr nz, .Lc_f54bfa
	bit 1, (0x323b:16)
	jr nz, .Lc_f54bfa
	ld w, (0x327a:16)
	or w, (0x327b:16)
	or w, (0x327c:16)
	and W,0x3f
	jr nz, .Lc_f54c26
	bit 5, (0x3257:16)
	jr z, .Lc_f54c26
Rhythm_CrossVoice_Apply:
.Lc_f54bfa:
	push XIY
	ld W,A
	add w, (0x322f:16)
	inc 1,W
	sub W,0x0c
	ld (0x3292:16), w
	or (0x3291:16), 0x01
	ld XIY,AccPatch_Transpose_LookupTable_Data
	ld	w, (xiy+a)
	sub A,W
	pop XIY
	ld (0x3397:16), 0x00
	ld (0x3398:16), 0x00
Rhythm_CrossVoice_ClearFlag:
.Lc_f54c26:
	and (0x3257:16), 0xdf

	ret



Rhythm_NoteRangeCheck:
	bit 0, (0x323b:16)
	jr z, Rhythm_NoteRangeReturn
	push XIY
	ld W,A
	ld XIY,AccPatch_Transpose_LookupTable_Data
	ld	w, (xiy+a)
	sub	a, w
	pop	xiy
	ld	(13207:16), 0
	ld	(13208:16), 0
Rhythm_NoteRangeReturn:
	ret

; Two zero bytes between Rhythm_NoteRangeCheck's `ret` and the called routine
; Rhythm_VelocityLookup_A.  No reference found (scripts/analysis/
; sequi_find_refs.py v7 0xF54C4D 0xF54C4E -> none); inter-routine padding by
; position, nothing established beyond that.  Was `nop / nop` until 2026-09-25.
Rhythm_NoteRangeData:
	.byte 0x00, 0x00

Rhythm_VelocityLookup_A:
	push XIY
	push XHL
	ld W,A
	calr Rhythm_InstrBaseLookup
	cp (0x323c:16), 0x00
	jr nz, .Lc_f54c61
	ld A, 0x00:opc
	jr t, Rhythm_VelLookA_Done
Rhythm_VelLookA_CheckEmpty:
.Lc_f54c61:
	bit 4, (0x3258:16)
	jr z, Rhythm_VelLookA_CheckRange
	and (0x3258:16), 0xef
	ld A,W
	jr t, Rhythm_VelLookA_Done
Rhythm_VelLookA_CheckRange:
	ld	l, (12860:16)
	cp	l, 48
	jr	c, Rhythm_VelLookA_SelectTable
	xor	l, l
Rhythm_VelLookA_SelectTable:
	ld xiy, Rhythm_InstrMapTable_Default
	bit 2, (0x3258:16)
	jr z, Rhythm_VelLookA_CheckBit3
	ld xiy, Rhythm_VelLookA_SelectTable_Data
Rhythm_VelLookA_CheckBit3:
	bit 3, (0x3258:16)
	jr z, Rhythm_VelLookA_TableLookup
	ld xiy, Rhythm_VelLookA_CheckBit3_Data
Rhythm_VelLookA_TableLookup:
	ld	l, (xiy+l)
	extz hl
	sla hl, 4
	ld xiy, Rhythm_VelLookA_TableLookup_Table
	lda	xiy, (xiy+hl)
	ld	a, (xiy+a)
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelLookA_Done:
	pop xhl
	pop xiy
	ret

Rhythm_InstrBaseLookup:
	push xiy
	ld xiy, AccPatch_Transpose_LookupTable_Data
	lda	xiy, (xiy+a)
	ld a, (xiy)
	pop xiy
	ret

; -----------------------------------------------------------------------------
; Rhythm_InstrMapTable_Default -- 3 variants x 49 bytes.  Each maps the RAM
; byte 0x323C (index clamped to 0..0x2F, anything larger reads entry 0) to a
; ROW NUMBER of the 16-byte-row table at Rhythm_VelLookA_TableLookup_Table.
; Readers (all the same pattern): Rhythm_VelocityLookup_A, Rhythm_VoiceMapLookup
; (second half) and Rhythm_TranspMod_BaseApply:
;     ld xiy, <variant> / ldb_sri L, ..., 0xf4, 0xec     ; L := variant[L]
;     sla hl, 4 / ld xiy, Rhythm_VelLookA_TableLookup_Table
;     lda_dri XIY, ...  ; xiy += row*16  /  ldb_sri A, ... ; A := row[A]
;     add w, a                                           ; note += row[col]
; where the column A came from Rhythm_InstrBaseLookup (a byte of
; AccPatch_Transpose_LookupTable_Data indexed by the note).
; Variant choice: bit 2 of RAM 0x3258 selects +0x31 (the positional alias
; Rhythm_VelLookA_SelectTable_Data), bit 3 selects +0x62 (..._0x62) and,
; being tested second, wins over bit 2;
; Rhythm_TranspMod_BaseApply always uses +0x31.  Stride 0x31 = 49 is pinned by
; those two aliases; the tables end exactly at Rhythm_TransposeNote (147 B).
; Values 0..20 = row numbers.  What each 16-byte row holds belongs to the
; documentation of Rhythm_VelLookA_TableLookup_Table (C data, another file).
; -----------------------------------------------------------------------------
Rhythm_InstrMapTable_Default:
	; +0x00: default (bits 2 and 3 of 0x3258 clear)
	.byte 0, 0, 0, 1, 5, 0, 3, 9, 10, 7, 4, 2, 5, 6, 6, 0
	.byte 0, 1, 2, 8, 10, 3, 8, 4, 0, 18, 19, 20, 0, 5, 0, 0
	.byte 5, 0, 0, 1, 1, 6, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read
	; +0x31: bit 2 of 0x3258 set; always used by Rhythm_TranspMod_BaseApply
Rhythm_VelLookA_SelectTable_Data:
	.byte 0, 0, 0, 1, 5, 0, 3, 9, 10, 7, 4, 2, 5, 6, 6, 11
	.byte 12, 14, 15, 8, 10, 16, 17, 4, 13, 18, 19, 20, 0, 5, 12, 13
	.byte 5, 12, 13, 1, 1, 6, 4, 5, 11, 16, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read
	; +0x62: bit 3 of 0x3258 set (tested after bit 2, so it wins)
Rhythm_VelLookA_CheckBit3_Data:
	.byte 0, 0, 0, 1, 5, 0, 3, 9, 10, 7, 4, 2, 5, 6, 6, 0
	.byte 0, 1, 2, 8, 10, 3, 8, 4, 0, 18, 19, 20, 0, 5, 0, 0
	.byte 5, 0, 0, 1, 1, 6, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read

Rhythm_TransposeNote:
	ld a, (0x323d:16)
	bit 3, (0x3258:16)
	jr z, Rhythm_Transp_CheckZero
	ld a, (0x323e:16)
Rhythm_Transp_CheckZero:
	cp a, 0:i3
	jr nz, Rhythm_Transp_Apply
	ld a, 0x0:opc
	jr Rhythm_Transp_Done

Rhythm_Transp_Apply:
	dec	1, a
	cp	a, (12847:16)
	jr	ugt, Rhythm_Transp_NegativeOctave	; -> 0xF54D83
	add	w, a
	bit	7, w
	jr	z, Rhythm_Transp_JumpToWrap	; -> 0xF54D81
	sub	w, 12
Rhythm_Transp_JumpToWrap:
	jr Rhythm_Transp_WrapCheck

Rhythm_Transp_NegativeOctave:
	sub a, 0xc
	add w, a
	bit 7, w
	jr z, Rhythm_Transp_WrapCheck
	add w, 0xc

Rhythm_Transp_WrapCheck:
	cp (0x3230:16), 12
	jr c, Rhythm_Transp_FinalCheck
Rhythm_Transp_WrapLoop:
	cp w, (0x3230:16)
	jr c, Rhythm_Transp_FinalCheck
	sub w, 12
	jr Rhythm_Transp_WrapLoop
Rhythm_Transp_FinalCheck:
	ld a, w
	bit 0, (0x3291:16)
	jr z, Rhythm_Transp_Done
	cp a, (0x3292:16)
	jr nc, Rhythm_Transp_Done
	add a, 12
Rhythm_Transp_Done:
	and (0x3291:16), 0xfe	; anddi8 (0x332d), 254 (v7 patched)

	ret



Rhythm_VoiceMapLookup:
	push XIY
	push XHL
	cp (0x323c:16), 0x00
	jr nz, .Lc_f54dc7
	ld A, 0x00:opc
	jrl t, Rhythm_VoiceMap_Done
Rhythm_VoiceMap_CheckInstr:
.Lc_f54dc7:
	bit 4, (0x3258:16)
	jr z, Rhythm_VoiceMap_CheckBit4
	and (0x3258:16), 0xef
	jrl t, Rhythm_VoiceMap_Done
Rhythm_VoiceMap_CheckBit4:
	ld	l, (12860:16)
	cp	l, 48
	jr	c, Rhythm_VoiceMap_ClampInstr
	xor	l, l
Rhythm_VoiceMap_ClampInstr:
	ld xiy, Rhythm_PitchShiftTable_Default
	bit 3, (0x3258:16)
	jr z, Rhythm_VoiceMap_SelectTable
	ld xiy, Rhythm_VoiceMap_ClampInstr_Data
Rhythm_VoiceMap_SelectTable:
	ld	l, (xiy+l)
	cp	l, 0:i3
	jr	z, Rhythm_VoiceMap_ApplyBase	; -> 0xF54E1F
	ld	h, (13207:16)
	cp	l, 1:i3
	jr	z, Rhythm_VoiceMap_CheckMute	; -> 0xF54E05
	ld	h, (13208:16)
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
	ld	w, a
	calr	Rhythm_InstrBaseLookup
	ld	l, (12860:16)
	cp	l, 48
	jr	c, Rhythm_VoiceMap_Inst2Clamp
	xor	l, l
Rhythm_VoiceMap_Inst2Clamp:
	ld xiy, Rhythm_InstrMapTable_Default
	bit 2, (0x3258:16)
	jr z, Rhythm_VoiceMap_Inst2Bit2
	ld xiy, Rhythm_VelLookA_SelectTable_Data
Rhythm_VoiceMap_Inst2Bit2:
	bit 3, (0x3258:16)
	jr z, Rhythm_VoiceMap_Inst2Bit3
	ld xiy, Rhythm_VelLookA_CheckBit3_Data
Rhythm_VoiceMap_Inst2Bit3:
	ld	l, (xiy+l)
	extz hl
	sla hl, 4
	ld xiy, Rhythm_VelLookA_TableLookup_Table
	lda	xiy, (xiy+hl)
	ld	a, (xiy+a)
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VoiceMap_Done:
	pop xhl
	pop xiy
	ret

; -----------------------------------------------------------------------------
; Rhythm_PitchShiftTable_Default -- 2 variants x 49 bytes of SHIFT SELECTORS,
; indexed like Rhythm_InstrMapTable_Default by RAM 0x323C (clamped 0..0x2F).
; Reader: Rhythm_VoiceMapLookup, first half: `ld xiy, <variant>`,
; `ld l, (xiy+hl)` (L := variant[L]); then
;     0 -> no shift;  1 -> shift byte RAM 0x3397;  2 -> shift byte RAM 0x3398,
; where a shift byte with bit 5 set returns 0 (muted), bit 4 set subtracts and
; clear adds its low nibble to A.  Rhythm_NoteRangeCheck clears both bytes.
; Variant: bit 3 of RAM 0x3258 selects +0x31 (alias
; Rhythm_VoiceMap_ClampInstr_Data).  98 bytes = 2 x 49, to
; Rhythm_VelocityCompute.  Was framed as `nop` / `normal` / `push sr`
; (0x00 / 0x01 / 0x02) until 2026-09-25.
; -----------------------------------------------------------------------------
Rhythm_PitchShiftTable_Default:
	; +0x00: default (bit 3 of 0x3258 clear)
	.byte 0, 0, 1, 1, 0, 2, 1, 1, 2, 1, 1, 1, 1, 0, 1, 1
	.byte 1, 1, 1, 1, 2, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 0, 2, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read
	; +0x31: bit 3 of 0x3258 set
Rhythm_VoiceMap_ClampInstr_Data:
	.byte 0, 0, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 0, 1, 1
	.byte 1, 1, 1, 1, 2, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1
	.byte 1, 1, 1, 1, 1, 1, 1, 1, 0, 2, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read

Rhythm_VelocityCompute:
	push XIY
	push XHL
	ld W,A
	calr Rhythm_InstrBaseLookup
	cp (0x323c:16), 0x00
	jr nz, .Lc_f54edf
	ld A, 0x00:opc
	jr t, Rhythm_VelComp_Done
Rhythm_VelComp_CheckBit4:
.Lc_f54edf:
	bit 4, (0x3258:16)
	jr z, Rhythm_VelComp_ClampInstr
	and (0x3258:16), 0xef
	ld A,W
	jr t, Rhythm_VelComp_Done
Rhythm_VelComp_ClampInstr:
	ld	l, (12860:16)
	cp	l, 48
	jr	c, Rhythm_VelComp_SelectTable
	xor	l, l
Rhythm_VelComp_SelectTable:
	ld xiy, Rhythm_VelocityTable_A
	bit 2, (0x3258:16)
	jr z, Rhythm_VelComp_Lookup
	ld xiy, Rhythm_VelComp_SelectTable_Data
Rhythm_VelComp_Lookup:
	ld	l, (xiy+l)
	extz hl
	sla hl, 4
	ld xiy, Rhythm_VelLookA_TableLookup_Table
	lda	xiy, (xiy+hl)
	ld	a, (xiy+a)
	add w, a
	calr Rhythm_TransposeNote

Rhythm_VelComp_Done:
	pop xhl
	pop xiy
	ret

; -----------------------------------------------------------------------------
; Rhythm_VelocityTable_A -- 2 variants x 49 bytes, the same kind of table as
; Rhythm_InstrMapTable_Default (row numbers into the 16-byte rows at
; Rhythm_VelLookA_TableLookup_Table), for a different reader.
; Reader: Rhythm_VelocityCompute -- `ld xiy, <variant>`, L := variant[L]
; (L = RAM 0x323C clamped 0..0x2F), `sla hl, 4`, row lookup, `add w, a`,
; `calr Rhythm_TransposeNote`: identical to Rhythm_VelocityLookup_A.
; Variant: bit 2 of RAM 0x3258 selects +0x31 (alias Rhythm_VelComp_SelectTable_Data).
; 98 bytes = 2 x 49, to Rhythm_FourChannelDispatch.  The two variants differ
; from Rhythm_InstrMapTable_Default's first two only at entry 7 (0 here, 9
; there).  The "Velocity" in the name is not supported by the reader, which
; adds the row value to the NOTE in W.
; -----------------------------------------------------------------------------
Rhythm_VelocityTable_A:
	; +0x00: default (bit 2 of 0x3258 clear)
	.byte 0, 0, 0, 1, 5, 0, 3, 0, 10, 7, 4, 2, 5, 6, 6, 0
	.byte 0, 1, 2, 8, 10, 3, 8, 4, 0, 18, 19, 20, 0, 5, 0, 0
	.byte 5, 0, 0, 1, 1, 6, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read
	; +0x31: bit 2 of 0x3258 set
Rhythm_VelComp_SelectTable_Data:
	.byte 0, 0, 0, 1, 5, 0, 3, 0, 10, 7, 4, 2, 5, 6, 6, 11
	.byte 12, 14, 15, 8, 10, 16, 17, 4, 13, 18, 19, 20, 0, 5, 12, 13
	.byte 5, 12, 13, 1, 1, 6, 4, 5, 11, 16, 0, 0, 0, 0, 0, 0
	.byte 0	; entry 48: past the 0..0x2F index clamp, never read

Rhythm_FourChannelDispatch:
	calr Rhythm_DispatchCh_D7
	calr Rhythm_DispatchCh_D4
	calr Rhythm_DispatchCh_D5
	calr Rhythm_DispatchCh_D6
	ret

Rhythm_DispatchCh_D7:
	ld a, (0x3227:16)
	ld (0x322f:16), a
	ld a, (0x322b:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xfb
	or (0x3258:16), 0x08
	ld W, 0x97:opc
	ld XIX,0x00003058
Rhythm_DispatchCh_D7_Loop:
	ld	(13112:16), 4
	calr	Rhythm_SingleNoteHandler
	add	xix, 9
	cp	xix, 12448
	jr	c, Rhythm_DispatchCh_D7_Loop
	ret
Rhythm_DispatchCh_D4:
	ld a, (0x3228:16)
	ld (0x322f:16), a
	ld a, (0x322c:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf7
	or (0x3258:16), 0x04
	ld W, 0x94:opc
	ld XIX,0x000030a0
Rhythm_DispatchCh_D4_Loop:
	ld	(13112:16), 8
	calr	Rhythm_SingleNoteHandler
	add	xix, 9
	cp	xix, 12520
	jr	c, Rhythm_DispatchCh_D4_Loop
	ret
Rhythm_DispatchCh_D5:
	ld a, (0x3229:16)
	ld (0x322f:16), a
	ld a, (0x322d:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf3
	ld W, 0x95:opc
	ld XIX,0x000030e8
Rhythm_DispatchCh_D5_Loop:
	ld	(13112:16), 16
	calr	Rhythm_SingleNoteHandler
	add	xix, 9
	cp	xix, 12592
	jr	c, Rhythm_DispatchCh_D5_Loop
	ret
Rhythm_DispatchCh_D6:
	ld a, (0x322a:16)
	ld (0x322f:16), a
	ld a, (0x322e:16)
	ld (0x3230:16), a
	and (0x3258:16), 0xf3
	ld W, 0x96:opc
	ld XIX,0x00003130
Rhythm_DispatchCh_D6_Loop:
	ld	(13112:16), 32
	calr	Rhythm_SingleNoteHandler
	add	xix, 9
	cp	xix, 12664
	jr	c, Rhythm_DispatchCh_D6_Loop
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
	cp (0x3249:16), 0xf0
	jr c, Rhythm_Validate_Mismatch
	ld a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x327c:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, (0x3338:16)
	jr nz, Rhythm_Validate_Mismatch
	ld a, (0x3243:16)
	ld (0x3387:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3386:16)
	ld (0x3388:16), a
	ld a, (0x323c:16)
	ld (0x3387:16), a
	call AccTuning_CallWithSaveRestore
	ld a, (0x3386:16)
	cp	(13192:16), a
	jr	nz, Rhythm_Validate_Mismatch
	calr	Rhythm_MatchedPhrase
	jr	Rhythm_Validate_Done
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
	bit 4, (0x3258:16)
	jr nz, Rhythm_MatchedPhrase_Output
	bit 3, (0x3258:16)
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
	ld A,(XIX)
	cp A,0x90
	jr nz, Rhythm_MismatchOther
	pushw wa
	ld A,(XIX+0x06)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x3258:16)
	jr nz, Rhythm_Mismatch90_Output
	bit 3, (0x3258:16)
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
	ld a, (xix+3)
	ld (0x3394:16), a
	ld a, (xix+6)
	ld (0x3397:16), a
	ld a, (xix+7)
	ld (0x3398:16), a
	ld a, (xix+8)
	calr Rhythm_CheckVelocityThreshold
	bit 4, (0x3258:16)
	jr nz, Rhythm_MismatchOther_Output
	bit 3, (0x3258:16)
	jr z, Rhythm_MismatchOther_PostRange
	calr Rhythm_CrossVoiceCorrect
Rhythm_MismatchOther_PostRange:
	calr Rhythm_NoteRangeCheck

Rhythm_MismatchOther_Output:
	calr	Rhythm_VoiceMapLookup
	ld	(xix+2), a
	ld	a, (13204:16)
	ld	(xix+3), a
	popw	wa
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
	cp (0x3293:16), 0x00
	jr z, Rhythm_AllNotesOff_D7_Skip
	ld A, 0xd7:opc
	ld W, 0x03:opc
	ld E, 0x00:opc
	call Rhythm_Send3ByteMsg
Rhythm_AllNotesOff_D7_Skip:
	ret

Rhythm_AllNotesOff_D4:
	cp (0x3294:16), 0x00
	jr z, Rhythm_AllNotesOff_D4_Skip
	ld A, 0xd4:opc
	ld W, 0x03:opc
	ld E, 0x00:opc
	call Rhythm_Send3ByteMsg
Rhythm_AllNotesOff_D4_Skip:
	ret

Rhythm_AllNotesOff_D5:
	cp (0x3295:16), 0x00
	jr z, Rhythm_AllNotesOff_D5_Skip
	ld A, 0xd5:opc
	ld W, 0x03:opc
	ld E, 0x00:opc
	call Rhythm_Send3ByteMsg
Rhythm_AllNotesOff_D5_Skip:
	ret

Rhythm_AllNotesOff_D6:
	cp (0x3296:16), 0x00
	jr z, Rhythm_AllNotesOff_D6_Done
	ld A, 0xd6:opc
	ld W, 0x03:opc
	ld E, 0x00:opc
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
	cp (0x3293:16), 0x00
	jr z, Rhythm_SendVolume_D7_Skip
	ld A, 0xd7:opc
	ld W, 0x03:opc
	ld e, (0x3293:16)
	call Rhythm_Send3ByteMsg
Rhythm_SendVolume_D7_Skip:
	ret

Rhythm_SendVolume_D4:
	cp (0x3294:16), 0x00
	jr z, Rhythm_SendVolume_D4_Skip
	ld A, 0xd4:opc
	ld W, 0x03:opc
	ld e, (0x3294:16)
	call Rhythm_Send3ByteMsg
Rhythm_SendVolume_D4_Skip:
	ret

Rhythm_SendVolume_D5:
	cp (0x3295:16), 0x00
	jr z, Rhythm_SendVolume_D5_Skip
	ld A, 0xd5:opc
	ld W, 0x03:opc
	ld e, (0x3295:16)
	call Rhythm_Send3ByteMsg
Rhythm_SendVolume_D5_Skip:
	ret

Rhythm_SendVolume_D6:
	cp (0x3296:16), 0x00
	jr z, Rhythm_SendVolume_D6_Done
	ld A, 0xd6:opc
	ld W, 0x03:opc
	ld e, (0x3296:16)
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
	cp (0x3293:16), 0x00
	jr z, Rhythm_NoteOffMax_D7_Skip
	ld A, 0x90:opc
	ld W, 0x7f:opc
	ld E, 0x77:opc
	call Rhythm_Send3ByteMsg
Rhythm_NoteOffMax_D7_Skip:
	ret

Rhythm_NoteOffMax_D4:
	cp (0x3294:16), 0x00
	jr z, Rhythm_NoteOffMax_D4_Skip
	ld A, 0x90:opc
	ld W, 0x7f:opc
	ld E, 0x74:opc
	call Rhythm_Send3ByteMsg
Rhythm_NoteOffMax_D4_Skip:
	ret

Rhythm_NoteOffMax_D5:
	cp (0x3295:16), 0x00
	jr z, Rhythm_NoteOffMax_D5_Skip
	ld A, 0x90:opc
	ld W, 0x7f:opc
	ld E, 0x75:opc
	call Rhythm_Send3ByteMsg
Rhythm_NoteOffMax_D5_Skip:
	ret

Rhythm_NoteOffMax_D6:
	cp (0x3296:16), 0x00
	jr z, Rhythm_NoteOffMax_D6_Done
	ld A, 0x90:opc
	ld W, 0x7f:opc
	ld E, 0x76:opc
	call Rhythm_Send3ByteMsg
Rhythm_NoteOffMax_D6_Done:
	ret

Rhythm_AdvanceTick:
	ld wa, (0x3247:16)
	ld (0x32ba:16), w
	ld a, (0x31e3:16)
	ld w, (0x31e4:16)
	ld (0x3389:16), w
	add A,0x18
	cp A,0x60
	jr c, Rhythm_AdvanceTick_Store
	sub A,0x60
	inc 1,W
	cp w, (0x0458:16)
	jr c, Rhythm_AdvanceTick_Store
	xor W,W
Rhythm_AdvanceTick_Store:
	ld	(12871:16), wa
	ret
Rhythm_SaveState:
	ld	a, (12889:16)
	ld	(12890:16), a
	ld	a, (12891:16)
	ld	(12892:16), a
	ld	a, (12893:16)
	ld	(12894:16), a
	ld	a, (12895:16)
	ld	(12896:16), a
	ld	a, (12899:16)
	ld	(12900:16), a
	ld	a, (12897:16)
	ld	(12898:16), a
	ld	a, (12901:16)
	ld	(12902:16), a
	ld	a, (12903:16)
	ld	(12904:16), a
	ld	a, (12905:16)
	ld	(12906:16), a
	ld	a, (12907:16)
	ld	(12908:16), a
	ld	a, (13268:16)
	ld	(12773:16), a
	ld	a, (CURRENT_MODE:16)
	ld	(12885:16), a
	ld	a, (12953:16)
	ld	(12886:16), a
	ld	a, (13132:16)
	ld	(13133:16), a
	ld	a, (12775:16)
	and	a, 253
	bit	0, a
	jr	z, Rhythm_SaveState_StoreBits
	or	a, 2
Rhythm_SaveState_StoreBits:
	ld (0x31e7:16), a
	or (0x3257:16), 0x01
	cp (0x31e4:16), 0
	jr nz, Rhythm_SaveState_CheckFx
	cp (0x31e3:16), 48
	jr c, Rhythm_SaveState_CheckFx
	and (0x328d:16), 0xc0
Rhythm_SaveState_CheckFx:
	ld a, (0x326f:16)
	and a, 3
	jr nz, Rhythm_SaveState_FxActive
	bit 0, (0x3270:16)
	jr z, Rhythm_SaveState_ClearFx
Rhythm_SaveState_FxActive:
	ld a, (0x328a:16)
	and a, 63
	jr nz, Rhythm_SaveState_CheckFx2
	and (0x326f:16), 0xfc
	and (0x3270:16), 0xfe
	jr Rhythm_SaveState_CheckFx2
Rhythm_SaveState_ClearFx:
	and (0x328a:16), 0xc0	; anddi8 (0x3326), 192 (v7 patched)



Rhythm_SaveState_CheckFx2:
	ld	a, (12909:16)
	and	a, 3
	jr	nz, Rhythm_SaveState_Fx2Active
	ld	a, (12910:16)
	and	a, 13
	jr	z, Rhythm_SaveState_ClearFx2
Rhythm_SaveState_Fx2Active:
	ld	a, (12939:16)
	and	a, 63
	jr	nz, Rhythm_VoiceAssignDetect
	and	a, 252
	and	a, 242
	jr	Rhythm_VoiceAssignDetect
Rhythm_SaveState_ClearFx2:
	and (0x328b:16), 0xc0	; anddi8 (0x3327), 192 (v7 patched)



Rhythm_VoiceAssignDetect:
	ld a, (0x3276:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_PartBDetect
	ld a, (0x327d:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_PartBDetect
	and (0xfc5f:16), 0xbf
	ld a, (0x3277:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_PartAOn
	or (0xfc5f:16), 0x80
	or (0x3260:16), 0x02
Rhythm_VoiceAssign_PartAOn:
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3260:16), 0xfe
	and (0x328f:16), 0xfd
	ld a, (0x3277:16)
	or a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x327c:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_PartBDetect
	or (0x31e8:16), 0x10
	or (0x31e8:16), 0x04
Rhythm_VoiceAssign_PartBDetect:
	ld a, (0x3277:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	ld a, (0x327e:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_Ext1Detect
	and (0xfc5f:16), 0x7f
	ld a, (0x3276:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_PartBOn
	or (0xfc5f:16), 0x40
	or (0x3260:16), 0x01
Rhythm_VoiceAssign_PartBOn:
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3260:16), 0xfd
	and (0x328f:16), 0xfb
	ld a, (0x3276:16)
	or a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x327c:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext1Detect
	or (0x31e8:16), 0x10
	or (0x31e8:16), 0x04
Rhythm_VoiceAssign_Ext1Detect:
	ld a, (0x327a:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	ld a, (0x3281:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_Ext2Detect
	and (0xfc5f:16), 0xfb
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3264:16), 0xfe
	ld a, (0x327b:16)
	or a, (0x327c:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext2Detect
	or (0x31e8:16), 0x08
Rhythm_VoiceAssign_Ext2Detect:
	ld a, (0x327b:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	ld a, (0x3282:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_Ext3Detect
	and (0xfc5f:16), 0xf7
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3264:16), 0xfd
	ld a, (0x327a:16)
	or a, (0x327c:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Ext3Detect
	or (0x31e8:16), 0x08
Rhythm_VoiceAssign_Ext3Detect:
	ld a, (0x327c:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	ld a, (0x3283:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_Perc1Detect
	and (0xfc60:16), 0xfb
	ld e, 72:opc
	ld d, 6:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3264:16), 0xfb
	ld a, (0x327a:16)
	or a, (0x327b:16)
	or a, (0x3276:16)
	or a, (0x3277:16)
	or a, (0x3278:16)
	or a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Perc1Detect
	or (0x31e8:16), 0x08
Rhythm_VoiceAssign_Perc1Detect:
	ld a, (0x3278:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_Perc2Detect
	ld a, (0x327f:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_Perc2Detect
	and (0xfc5f:16), 0xef
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3261:16), 0xfe
	or (0x31e8:16), 0x04
Rhythm_VoiceAssign_Perc2Detect:
	ld a, (0x3279:16)
	and a, 63
	jr nz, Rhythm_VoiceAssign_SaveShadow
	ld a, (0x3280:16)
	and a, 63
	jr z, Rhythm_VoiceAssign_SaveShadow
	and (0xfc5f:16), 0xdf
	ld e, 72:opc
	ld d, 5:opc
	ld a, 0:opc
	ld w, 0:opc
	calr Rhythm_QueuePartChangeEvent
	and (0x3261:16), 0xfd
	or (0x31e8:16), 0x04
Rhythm_VoiceAssign_SaveShadow:
	ld	a, (12918:16)
	ld	(12925:16), a
	ld	a, (12919:16)
	ld	(12926:16), a
	ld	a, (12922:16)
	ld	(12929:16), a
	ld	a, (12923:16)
	ld	(12930:16), a
	ld	a, (12924:16)
	ld	(12931:16), a
	ld	a, (12920:16)
	ld	(12927:16), a
	ld	a, (12921:16)
	ld	(12928:16), a
	ld	a, (12873:16)
	ld	(13012:16), a
	ld	a, (12960:16)
	ld	(12962:16), a
	call	AccTuning_SaveState
	calr	Rhythm_SeqResetCheck
	ret
Rhythm_SeqResetCheck:
	bit 2, (0x3433:16)
	jr z, Rhythm_SeqReset_UpdateFlags
	bit 4, (0x3433:16)
	jr nz, Rhythm_SeqReset_UpdateFlags
	ld l, (0x36ff:16)
	xor H,H
	sla L, 0x02
	ld XIY,Rhythm_SeqResetTable
	ld	xix, (xiy+hl)
	cp XIX,0x00000000
	jr z, Rhythm_SeqReset_UpdateFlags
	ei 0x06
	ld HL,(XIX+0x06)
	ld (XIX+0x04),HL
	ei 0x00
Rhythm_SeqReset_UpdateFlags:
	ld	a, (13363:16)
	and	a, 239
	bit	2, a
	jr	z, Rhythm_SeqReset_Store
	or	a, 16
Rhythm_SeqReset_Store:
	ld	(13363:16), a
	ret
; -----------------------------------------------------------------------------
; Rhythm_SeqResetTable -- 17 x 32-bit RAM pointers (or 0), indexed by RAM byte
; 0x36FF.
; Reader: Rhythm_SeqResetCheck -- when bit 2 of RAM 0x3433 is set and bit 4
; clear: L := (0x36FF), `sla l, 2`, `ld xiy, Rhythm_SeqResetTable`,
; `ld xix, (xiy+hl)` (xix := table[L]); if non-zero, with
; interrupts masked (`ei 6` .. `ei 0`) the word at (xix+6) is copied to
; (xix+4).  Stride 4 from `sla l, 2`; 17 entries = 68 bytes, to
; Rhythm_TransposeWithMod.  Non-zero entries: [1] 0x2CF8, [2] 0x2DF8,
; [4] 0x2EF8, [8] 0x2BF8, [16] 0x29F8 (v10: the same slots, 0x9C higher).
; This table only selects which structure Rhythm_SeqResetCheck updates; the
; structures themselves are not described here.  Was a verbatim ROM slice
; (includes/romslices/v7_transplant_Rhythm_SeqResetTable.bin, now
; unreferenced) until 2026-09-25.
; -----------------------------------------------------------------------------
Rhythm_SeqResetTable:
	.long 0x00000000	; [0]
	.long 0x00002cf8	; [1]
	.long 0x00002df8	; [2]
	.long 0x00000000	; [3]
	.long 0x00002ef8	; [4]
	.long 0x00000000	; [5]
	.long 0x00000000	; [6]
	.long 0x00000000	; [7]
	.long 0x00002bf8	; [8]
	.long 0x00000000	; [9]
	.long 0x00000000	; [10]
	.long 0x00000000	; [11]
	.long 0x00000000	; [12]
	.long 0x00000000	; [13]
	.long 0x00000000	; [14]
	.long 0x00000000	; [15]
	.long 0x000029f8	; [16]

Rhythm_TransposeWithMod:
	cp (0x323c:16), 0x00
	jr z, Rhythm_TranspMod_Return
	cp (0x323d:16), 0x00
	jr z, Rhythm_TranspMod_Return
	bit 2, (0x3349:16)
	jr nz, Rhythm_TranspMod_Return
	bit 1, (0x3349:16)
	jr z, Rhythm_TranspMod_ApplyBoth
	calr Rhythm_TranspMod_ModCheck
	bit 0, (0x3349:16)
	jr nz, Rhythm_TranspMod_Return
Rhythm_TranspMod_ApplyBoth:
	calr Rhythm_TranspMod_BaseApply
	calr Rhythm_TranspMod_OctaveWrap

Rhythm_TranspMod_Return:
	ret

Rhythm_TranspMod_ModCheck:
	and (0x3349:16), 0xfe
	ld l, (0x323c:16)
	cp L,0x30
	jr c, .Lc_f55706
	xor L,L
Rhythm_TranspMod_LookupTable:
.Lc_f55706:
	ld XIY,Rhythm_PitchShiftTable_Default
	ld	l, (xiy+l)
	cp l, 0:i3
	jr z, Rhythm_TranspMod_Done
	ld h, (0x334a:16)
	cp l, 1:i3
	jr z, Rhythm_TranspMod_Offset1
	ld h, (0x334b:16)
Rhythm_TranspMod_Offset1:
	bit 5, h
	jr z, Rhythm_TranspMod_MuteCheck
	ld a, 0:opc
	or (0x3349:16), 0x01
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
	ld W,A
	ld XIY,AccPatch_Transpose_LookupTable_Data
	ld	a, (xiy+a)
	ld l, (0x323c:16)
	cp L,0x30
	jr c, Rhythm_TranspMod_BaseLookup
	xor L,L
Rhythm_TranspMod_BaseLookup:
	extz hl
	ld xiy, Rhythm_VelLookA_SelectTable_Data
	ld	l, (xiy+hl)
	extz hl
	sla hl, 4
	ld xiy, Rhythm_VelLookA_TableLookup_Table
	lda	xiy, (xiy+hl)
	ld	a, (xiy+a)
	add w, a
	ret

Rhythm_TranspMod_OctaveWrap:
	ld	a, (12861:16)
	dec	1, a
	cp	a, 7:i3
	jr	nc, Rhythm_TranspMod_WrapNeg
	add	w, a
	bit	7, w
	jr	z, Rhythm_TranspMod_WrapJump
	sub	w, 12
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
	call VoiceParam_ClampAndValidate
	ret

