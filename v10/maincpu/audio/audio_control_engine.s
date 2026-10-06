; =============================================================================
; Audio Control Engine
; =============================================================================
;
; MIDI stream processing, control panel LED management, voice/tone
; parameter control, and sound preset dispatch. This is the main
; bridge between the UI layer and the SubCPU audio engine.
; =============================================================================

	ld a, e
	and a, 0xf
	jr z, PanelButton_DispatchChange_ShiftNewRight
	srla d

PanelButton_DispatchChange_ShiftNewRight:
	ld a, e
	and a, 0xf
	jr z, PanelButton_DispatchChange_Call
	srla l

; File I/O callback handler
PanelButton_DispatchChange_Call:
	cp l, 0:i3
	jr z, PanelButton_DispatchChange_Next
	ld a, (xiz + 1)
	ld (xbc + 1), a
	ld (xbc + 2), d
	ld (xbc + 3), l
	ld xhl, (xiz + 4)
	ld xwa, xbc
	call (xhl)

PanelButton_DispatchChange_Next:
	inc 8, xiz

PanelButton_DispatchChange_Loop:
	lda xbc, (0x8e7c:16)
	ld a, (xiz)
	ld (xbc), a
	cp a, 0xff
	jr nz, PanelButton_DispatchChange_Action
	pop xiz
	ret

; xwa -> a 4-byte panel event; an id of 0xFF is no event.  Append it to the event queue at (0xC039),
; count at RAM 0x8E8E, 16 deep; when full, mark the event 0xFF instead.
PanelEvent_Post:
	cp	(xwa), 0xff	; an id of 0xFF is no event
	ret	z
	ld	c, (36494:16)
	cp	c, 15
	jr	ugt, PanelEvent_Post_Skip
	ld	e, c
	inc	1, c
	ld	(36494:16), c
	ld	c, e
	extz	bc
	sll	bc, 2
	lda	xde, (49209:16)
	ld	ix, bc
	extz	xix
	add	xix, xde
	ld	xiy, xwa
	ldiw
	ldiw
PanelEvent_Post_Skip:
	ld	(xwa), 255
	ret
; unless MD_DEMO: PanelEvent_FillSelectedPart on the frame, then post both events
PanelAction_PostUnlessDemo:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_PostUnlessDemo_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelAction_PostUnlessDemo_Epilogue:
	pop	xiz
	ret
; unless MD_DEMO or panel parameter 0xC0 (tag 0x91 +3 bit 2) is 1: post both
PanelAction_PostUnlessDemoOrParamC0:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_PostUnlessDemoOrParamC0_Epilogue
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, PanelAction_PostUnlessDemoOrParamC0_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelAction_PostUnlessDemoOrParamC0_Epilogue:
	pop	xiz
	ret
PanelButton_PanelMemorySet:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 14
	jr	z, PanelButton_PanelMemorySet_Skip
	cp	a, 19
	jr	z, PanelButton_PanelMemorySet_Skip
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, PanelButton_PanelMemorySet_Skip2
PanelButton_PanelMemorySet_Skip:
	jr	PanelButton_PanelMemorySet_Epilogue
PanelButton_PanelMemorySet_Skip2:
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_PanelMemorySet_Epilogue:
	pop	xiz
	ret
PanelButton_AcousticIllusion:
	push	xiz
	ld	xiz, xwa
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
	pop	xiz
	ret
PanelButton_ModeKey:
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	nz, PanelButton_ModeKey_Skip
	ld	(xbc), 0
PanelButton_ModeKey_Join:
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	PanelButton_ModeKey_FilterTarget
	cp	(xiz), 255
	jr	nz, PanelButton_ModeKey_Skip7
	ld	xwa, xiz
	jr	PanelButton_ModeKey_Join3
PanelButton_ModeKey_Skip:
	ld	w, 0:opc
	extz	xwa
	call	Util_FindLowestSetBit
	lda	xde, (xiz+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 21
	jr	z, PanelButton_ModeKey_Skip6
	cp	a, 16
	jr	z, PanelButton_ModeKey_Skip5
	cp	a, 15
	jr	z, PanelButton_ModeKey_Skip4
	cp	a, 10
	jr	z, PanelButton_ModeKey_Skip3
	cp	a, 3:i3
	jr	z, PanelButton_ModeKey_Skip2
	cp	a, 1:i3
	jr	nz, PanelButton_ModeKey_Epilogue
	ld	xwa, PanelButton_ModeKeyCodes
	jr	PanelButton_ModeKey_Join2
PanelButton_ModeKey_Skip2:
	ld	xwa, FileIO_BytecodeData_Data
	jr	PanelButton_ModeKey_Join2
PanelButton_ModeKey_Skip3:
	ld	xwa, FileIO_BytecodeData_Data_2
	jr	PanelButton_ModeKey_Join2
PanelButton_ModeKey_Skip4:
	ld	xwa, FileIO_BytecodeData_Data_3
	jr	PanelButton_ModeKey_Join2
PanelButton_ModeKey_Skip5:
	ld	xwa, FileIO_BytecodeData_Data_4
	jr	PanelButton_ModeKey_Join2
PanelButton_ModeKey_Skip6:
	ld	xwa, FileIO_BytecodeData_Data_5
PanelButton_ModeKey_Join2:
	ld	a, (xwa+hl)
	ld	(xde), a
	jr	PanelButton_ModeKey_Join
PanelButton_ModeKey_Skip7:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
PanelButton_ModeKey_Join3:
	calr	PanelEvent_Post
PanelButton_ModeKey_Epilogue:
	pop	xiz
	ret
; PanelButton_ModeKey_FilterTarget: Vets the target mode in byte +2 of the mode-key event frame XWA; sets frame byte 0
;   to 0xFF (no event) in MD_DEMO unless the target is 0 or 19, when panel parameter 0xC0 is 1 and the target is
;   9/14/15/17/19, when SeqState_GetFlags & 7 and the target is 7, and for targets 19/20 while word 0x28A8 is nonzero;
;   remaps 9 -> 8 when byte 0x26FC is 1 and 8 -> 10 when bit 0 of 0x266A is set. Basis: callers + body --
;   PanelButton_ModeKey stores the mapped mode at +2, calls it, then posts nothing when byte 0 came back 0xFF.
PanelButton_ModeKey_FilterTarget:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	nz, FileIO_BytecodeData_Code_Skip11
	ld	a, (xiz+2)
	cp	a, 19
	jr	z, FileIO_BytecodeData_Code_Skip11
	cp	a, 0:i3
	jr	z, FileIO_BytecodeData_Code_Skip11
	ld	(xiz), 255
FileIO_BytecodeData_Code_Skip11:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, FileIO_BytecodeData_Code_Skip13
	ld	a, (xiz+2)
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip12
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip12
	cp	a, 19
	jr	z, FileIO_BytecodeData_Code_Skip12
	cp	a, 9
	jr	z, FileIO_BytecodeData_Code_Skip12
	cp	a, 14
	jr	nz, FileIO_BytecodeData_Code_Skip13
FileIO_BytecodeData_Code_Skip12:
	ld	(xiz), 255
FileIO_BytecodeData_Code_Skip13:
	call	SeqState_GetFlags
	and	hl, 7
	jr	z, FileIO_BytecodeData_Code_Skip14
	cp	(xiz+2), 7
	jr	nz, FileIO_BytecodeData_Code_Skip14
	ld	(xiz), 255
FileIO_BytecodeData_Code_Skip14:
	lda	xwa, (xiz+2)
	cp	(xwa), 9
	jr	nz, FileIO_BytecodeData_Code_Entry
	cp	(9980:16), 1
	jr	nz, FileIO_BytecodeData_Code_Entry
	ld	(xwa), 8
	jr	FileIO_BytecodeData_Code_Entry2
FileIO_BytecodeData_Code_Entry:
	cp	(xwa), 8
	jr	nz, FileIO_BytecodeData_Code_Skip15
FileIO_BytecodeData_Code_Entry2:
	bit	0, (0x266a:16)
	jr	z, FileIO_BytecodeData_Code_Skip15
	ld	(xwa), 10
FileIO_BytecodeData_Code_Skip15:
	cpw	(10408:16), 0
	jr	z, FileIO_BytecodeData_Code_Entry3
	ld	a, (xwa)
	cp	a, 19
	jr	z, FileIO_BytecodeData_Code_Skip16
	cp	a, 20
	jr	nz, FileIO_BytecodeData_Code_Entry3
FileIO_BytecodeData_Code_Skip16:
	ld	(xiz), 255
	jr	FileIO_BytecodeData_Code_Epilogue4
FileIO_BytecodeData_Code_Entry3:
	res	0, (0x266a:16)
FileIO_BytecodeData_Code_Epilogue4:
	pop	xiz
	ret
PanelButton_SequencerPlay:
	push	xiz
	ld	xiz, xwa
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, PanelButton_SequencerPlay_Epilogue
	ld	a, (CURRENT_MODE:16)
	cp	a, 19
	jr	z, PanelButton_SequencerPlay_Epilogue
	bit	2, (0x421:16)
	jr	nz, PanelButton_SequencerPlay_Skip2
	ld	a, (10405:16)
	xor	a, 1
	ld	(10405:16), a
	ld	c, (CURRENT_MODE:16)
	cp	c, 13
	jr	ugt, PanelButton_SequencerPlay_Skip
	cp	c, 8
	jr	c, PanelButton_SequencerPlay_Skip
PanelButton_SequencerPlay_Loop:
	ld	xwa, xiz
	calr PanelEvent_Post
	ld (xiz), 169
	ld	(xiz+1), 32
	ld	(xiz+2), 10
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	jr	PanelButton_SequencerPlay_Join
PanelButton_SequencerPlay_Skip:
	bit	0, a
	jr	nz, PanelButton_SequencerPlay_Loop
	cp	c, 14
	jr	z, PanelButton_SequencerPlay_Loop
	call	SeqPlay_SaveStateAndCleanup
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	jr	PanelButton_SequencerPlay_Join
PanelButton_SequencerPlay_Skip2:
	ld	(xiz), 169
	ld	(xiz+1), 32
	ld	(xbc), 10
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
PanelButton_SequencerPlay_Join:
	calr	PanelEvent_Post
PanelButton_SequencerPlay_Epilogue:
	pop	xiz
	ret
PanelButton_PairDown:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+1)
	cp	a, 14
	jr	nz, PanelButton_PairDown_Skip
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_PairDown_Epilogue
PanelButton_PairDown_Skip:
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	lda	xbc, (xiz+2)
	cp	(xbc), 0
	jr	z, PanelButton_PairDown_Skip2
	.byte 0xe1, 0x84, 0x8e, 0xeb
	jr	PanelButton_PairDown_Join
PanelButton_PairDown_Skip2:
	ld	xwa, xhl
	cpl	wa
	cpl	qwa
	.byte 0xe1, 0x84, 0x8e, 0xc8
PanelButton_PairDown_Join:
	ld	xwa, (36488:16)
	and	xwa, xhl
	jr	z, PanelButton_PairDown_Skip3
	set	1, (xbc)
PanelButton_PairDown_Skip3:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_PairDown_Epilogue:
	pop	xiz
	ret
PanelButton_PairUp:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+1)
	cp	a, 14
	jr	nz, PanelButton_PairUp_Skip
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_PairUp_Epilogue
PanelButton_PairUp_Skip:
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	lda	xbc, (xiz+2)
	cp	(xbc), 0
	jr	z, PanelButton_PairUp_Skip2
	.byte 0xe1, 0x88, 0x8e, 0xeb
	jr	PanelButton_PairUp_Join
PanelButton_PairUp_Skip2:
	ld	xwa, xhl
	cpl	wa
	cpl	qwa
	.byte 0xe1, 0x88, 0x8e, 0xc8
PanelButton_PairUp_Join:
	ld	xwa, (36484:16)
	and	xwa, xhl
	jr	z, PanelButton_PairUp_Skip3
	set	0, (xbc)
PanelButton_PairUp_Skip3:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_PairUp_Epilogue:
	pop	xiz
	ret
PanelButton_StartStop:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	nz, PanelButton_StartStop_Skip
	ld	(xiz), 168
	ld	(xiz+1), 1
PanelButton_StartStop_Skip:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
	pop	xiz
	ret
PanelButton_SynchroBreak:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, PanelButton_SynchroBreak_Epilogue
	cp	a, 19
	jr	z, PanelButton_SynchroBreak_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_SynchroBreak_Epilogue:
	pop	xiz
	ret
PanelButton_SoundGroup:
	dec	4, xsp
	push	qiz
	ld	(xsp+2), xwa
	ld	xwa, (xsp+2)
	ld	c, (xwa+2)
	cp	c, 0:i3
	jrl	z, FileIO_BytecodeData_Code_Epilogue9
	ld	a, (CURRENT_MODE:16)
	cp	a, 14
	jr	z, PanelButton_SoundGroup_Skip2
	cp	a, 3:i3
	jr	z, PanelButton_SoundGroup_Skip
	cp	a, 19
	jr	nz, PanelButton_SoundGroup_Skip3
PanelButton_SoundGroup_Skip:
	jrl	FileIO_BytecodeData_Code_Epilogue9
PanelButton_SoundGroup_Skip2:
	ld	a, (14235:24)
	and	a, 31
	jrl	z, FileIO_BytecodeData_Code_Epilogue9
PanelButton_SoundGroup_Skip3:
	ld	b, 0:opc
	extz	xbc
	ld	xwa, xbc
	call	Util_FindLowestSetBit
	ld	xwa, (xsp+2)
	lda	xde, (xwa+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 20
	jr	z, PanelButton_SoundGroup_Skip5
	cp	a, 13
	jr	z, PanelButton_SoundGroup_Skip4
	cp	a, 12
	jrl	nz, FileIO_BytecodeData_Code_Epilogue9
	ld	xwa, FileIO_BytecodeData_Data_6
PanelButton_SoundGroup_Join:
	ld	a, (xwa+hl)
	ld	(xde), a
	cp	a, 17
	jr	ule, PanelButton_SoundGroup_Skip6
	jrl	FileIO_BytecodeData_Code_Epilogue9
PanelButton_SoundGroup_Skip4:
	ld	xwa, FileIO_BytecodeData_Data_7
	jr	PanelButton_SoundGroup_Join
PanelButton_SoundGroup_Skip5:
	ld	xwa, FileIO_BytecodeData_Data_8
	jr	PanelButton_SoundGroup_Join
PanelButton_SoundGroup_Skip6:
	extz	wa
	call	CharMap_ActivePreamb_Prologue2
	cp	l, 255
	jrl	z, FileIO_BytecodeData_Code_Epilogue9
	call	GetCurrentPartSelect
	ldfr_berp	l, 251
	ld	xwa, (xsp+2)
	inc	2, xwa
	cpib_erp	251, 2
	jr	ule, PanelButton_SoundGroup_Skip7
	cp	(xwa), 12
	jr	z, FileIO_BytecodeData_Code_Epilogue9
PanelButton_SoundGroup_Skip7:
	cp_erpb	251, 15
	jr	z, FileIO_BytecodeData_Code_Entry4
	cp_erpb	251, 20
	jr	nz, FileIO_BytecodeData_Code_Skip33
FileIO_BytecodeData_Code_Entry4:
	cp	(xwa), 15
	jr	nz, FileIO_BytecodeData_Code_Epilogue9
FileIO_BytecodeData_Code_Skip33:
	cp_erpb	251, 16
	jr	c, FileIO_BytecodeData_Code_Skip34
	cp_erpb	251, 19
	jr	ugt, FileIO_BytecodeData_Code_Skip34
	ld	xwa, (xsp+2)
	cp	(xwa+2), 15
	jr	z, FileIO_BytecodeData_Code_Epilogue9
FileIO_BytecodeData_Code_Skip34:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, FileIO_BytecodeData_Code_Skip37
	ld	xwa, (xsp+2)
	ld	a, (xwa+2)
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip35
	cp	a, 16
	jr	nz, FileIO_BytecodeData_Code_Skip36
FileIO_BytecodeData_Code_Skip35:
	jr	FileIO_BytecodeData_Code_Epilogue9
FileIO_BytecodeData_Code_Skip36:
	cp_erpb	251, 14
	jr	ugt, FileIO_BytecodeData_Code_Skip37
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Epilogue9
FileIO_BytecodeData_Code_Skip37:
	ld	xwa, (xsp+2)
	calr	PanelEvent_FillSelectedPart
	ld	xbc, (xsp+2)
	ld	a, (xbc)
	extz	wa
	ld	c, (xbc+2)
	extz	bc
	call	VoiceData_DistributeToChannels
	ld	xwa, (xsp+2)
	ld	(xwa+3), l
	ld	xwa, (xsp+2)
	calr	PanelEvent_Post
	ld	xwa, 4:i3
	add	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue9:
	pop	qiz
	inc	4, xsp
	ret
PanelButton_RhythmGroup:
	push	xiz
	ld	xiz, xwa
	ld	c, (xiz+2)
	cp	c, 0:i3
	jrl	z, PanelButton_RhythmGroup_Epilogue
	ld	a, (CURRENT_MODE:16)
	cp	a, 19
	jrl	z, PanelButton_RhythmGroup_Epilogue
	bit	0, (0x33d3:16)
	jrl	nz, PanelButton_RhythmGroup_Epilogue
	cp	a, 14
	jr	nz, PanelButton_RhythmGroup_Skip
	ld	a, (CURRENT_TITLE:16)
	cp	a, 184
	jr	z, PanelButton_RhythmGroup_Skip
	cp	a, 180
	jr	nz, PanelButton_RhythmGroup_Epilogue
	bit	0, (0x34d3:16)
	jr	nz, PanelButton_RhythmGroup_Epilogue
	cp	(13526:16), 12
	jr	nc, PanelButton_RhythmGroup_Epilogue
PanelButton_RhythmGroup_Skip:
	ld	b, 0:opc
	extz	xbc
	ld	xwa, xbc
	call	Util_FindLowestSetBit
	lda	xde, (xiz+2)
	ld	(xde), l
	ld	a, (36496:16)
	extz	hl
	cp	a, 6:i3
	jr	z, PanelButton_RhythmGroup_Skip3
	cp	a, 1:i3
	jr	z, PanelButton_RhythmGroup_Skip2
	cp	a, 0:i3
	jr	nz, PanelButton_RhythmGroup_Epilogue
	ld	xwa, FileIO_BytecodeData_Data_9
PanelButton_RhythmGroup_Join:
	ld	a, (xwa+hl)
	ld	(xde), a
	ld	c, a
	cp	c, 15
	jr	ule, PanelButton_RhythmGroup_Skip4
	jr	PanelButton_RhythmGroup_Epilogue
PanelButton_RhythmGroup_Skip2:
	ld	xwa, FileIO_BytecodeData_Data_10
	jr	PanelButton_RhythmGroup_Join
PanelButton_RhythmGroup_Skip3:
	ld	xwa, FileIO_BytecodeData_Data_11
	jr	PanelButton_RhythmGroup_Join
PanelButton_RhythmGroup_Skip4:
	cp	(CURRENT_TITLE:16), 184
	jr	nz, PanelButton_RhythmGroup_Skip5
	cp	c, 14
	jr	z, PanelButton_RhythmGroup_Epilogue
PanelButton_RhythmGroup_Skip5:
	extz	bc
	ldw	wa, 72
	call	VoiceData_DistributeToChannels
	ld	(xiz+3), l
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_RhythmGroup_Epilogue:
	pop	xiz
	ret
PanelButton_PanelMemoryNumber:
	dec	2, xsp
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, PanelButton_PanelMemoryNumber_Skip
	cp	a, 15
	jr	z, PanelButton_PanelMemoryNumber_Skip
	cp	a, 14
	jr	z, PanelButton_PanelMemoryNumber_Skip
	cp	a, 17
	jr	z, PanelButton_PanelMemoryNumber_Skip
	cp	a, 3:i3
	jr	z, PanelButton_PanelMemoryNumber_Skip
	cp	a, 19
	jr	nz, PanelButton_PanelMemoryNumber_Skip2
PanelButton_PanelMemoryNumber_Skip:
	jr	FileIO_BytecodeData_Code_Epilogue11
PanelButton_PanelMemoryNumber_Skip2:
	ld	a, (ACTIVE_TITLE:16)
	cp	a, 211
	jr	z, PanelButton_PanelMemoryNumber_Skip3
	cp	a, 210
	jr	z, PanelButton_PanelMemoryNumber_Skip3
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, FileIO_BytecodeData_Code_Entry5
PanelButton_PanelMemoryNumber_Skip3:
	jr	FileIO_BytecodeData_Code_Epilogue11
FileIO_BytecodeData_Code_Entry5:
	cp	(xiz+2), 0
	jr	z, FileIO_BytecodeData_Code_Skip46
	call	BitMapOut_PrepareRender_CheckBit1
	sll	l, 3
	ld	(xsp+4), l
	ld	xwa, 0:i3
	ld	a, (xiz+2)
	call	Util_FindLowestSetBit
	inc	1, l
	add	l, (xsp+4)
	ld	(xiz+2), l
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Skip46:
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue11:
	pop	xiz
	inc	2, xsp
	ret
PanelButton_PanelMemoryNextBank:
	push	xiz
	ld	xiz, xwa
	cp	(xiz+2), 0
	jr	z, PanelButton_PanelMemoryNextBank_Epilogue
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, PanelButton_PanelMemoryNextBank_Skip
	cp	a, 15
	jr	z, PanelButton_PanelMemoryNextBank_Skip
	cp	a, 14
	jr	z, PanelButton_PanelMemoryNextBank_Skip
	cp	a, 17
	jr	z, PanelButton_PanelMemoryNextBank_Skip
	cp	a, 3:i3
	jr	z, PanelButton_PanelMemoryNextBank_Skip
	cp	a, 19
	jr	nz, PanelButton_PanelMemoryNextBank_Skip2
PanelButton_PanelMemoryNextBank_Skip:
	jr	PanelButton_PanelMemoryNextBank_Epilogue
PanelButton_PanelMemoryNextBank_Skip2:
	ld	a, (ACTIVE_TITLE:16)
	cp	a, 211
	jr	z, PanelButton_PanelMemoryNextBank_Skip3
	cp	a, 210
	jr	z, PanelButton_PanelMemoryNextBank_Skip3
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, PanelButton_PanelMemoryNextBank_Skip4
PanelButton_PanelMemoryNextBank_Skip3:
	jr	PanelButton_PanelMemoryNextBank_Epilogue
PanelButton_PanelMemoryNextBank_Skip4:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_PanelMemoryNextBank_Epilogue:
	pop	xiz
	ret
PanelButton_SplitPoint:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_SplitPoint_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_SplitPoint_Epilogue:
	pop	xiz
	ret
PanelButton_Octave:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_Octave_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	ld	(xiz), 168
	ld	(xiz+1), 5
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	and	a, (xbc)
	jr	z, PanelButton_Octave_Skip
	ld	(xbc), 64
	jr	PanelButton_Octave_Join
PanelButton_Octave_Skip:
	ld	(xbc), 0
PanelButton_Octave_Join:
	ld	(xde), 64
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_Octave_Epilogue:
	pop	xiz
	ret
PanelButton_AutoPlayChord:
	push	xiz
	ld	xiz, xwa
	cp	(xiz+2), 0
	jr	z, PanelButton_AutoPlayChord_Epilogue
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_AutoPlayChord_Epilogue
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, PanelButton_AutoPlayChord_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	bit	2, (0x41e:16)
	jr	z, PanelButton_AutoPlayChord_Skip
	ld	xwa, 163968
	call	SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr	nz, PanelButton_AutoPlayChord_Skip2
PanelButton_AutoPlayChord_Skip:
	ld	(xiz), 72
	ld	(xiz+1), 3
	ld	a, (65480:24)
	ld	(xiz+2), a
	ld	(xiz+3), 7
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_AutoPlayChord_Skip2:
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_AutoPlayChord_Epilogue:
	pop	xiz
	ret
PanelButton_PartSelect:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	cp	a, 0:i3
	jr	z, FileIO_BytecodeData_Code_Epilogue16
	ld	c, (CURRENT_MODE:16)
	cp	c, 16
	jr	z, PanelButton_PartSelect_Skip
	cp	c, 15
	jr	z, PanelButton_PartSelect_Skip
	cp	c, 14
	jr	z, PanelButton_PartSelect_Skip
	cp	c, 3:i3
	jr	z, PanelButton_PartSelect_Skip
	cp	c, 19
	jr	z, PanelButton_PartSelect_Skip
	cp	(CURRENT_TITLE:16), 81
	jr	nz, FileIO_BytecodeData_Code_Entry6
PanelButton_PartSelect_Skip:
	jr	FileIO_BytecodeData_Code_Epilogue16
FileIO_BytecodeData_Code_Entry6:
	bit	0, (0x26e2:16)
	jr	nz, FileIO_BytecodeData_Code_Epilogue16
	ld	w, 0:opc
	extz	xwa
	call	Util_FindLowestSetBit
	extz	hl
	lda	xbc, (FileIO_BytecodeData_Data_12:24)
	ld	a, (xbc+hl)
	ld	(xiz+2), a
	ld	(PART_SELECT:16), a
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue16:
	pop	xiz
	ret
PanelButton_Conductor:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, PanelButton_Conductor_Epilogue
	cp	a, 15
	jr	z, PanelButton_Conductor_Epilogue
	cp	a, 14
	jr	z, PanelButton_Conductor_Epilogue
	cp	a, 3:i3
	jr	z, PanelButton_Conductor_Epilogue
	cp	a, 19
	jr	z, PanelButton_Conductor_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_Conductor_Epilogue:
	pop	xiz
	ret
PanelButton_DigitalEffect:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_DigitalEffect_Epilogue
	calr	SndParam_ResolveSelectedPartVoice
	cp	(xhl), 15
	jr	z, PanelButton_DigitalEffect_Epilogue
	cp	(xhl), 12
	jr	z, PanelButton_DigitalEffect_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_DigitalEffect_Epilogue:
	pop	xiz
	ret
PanelButton_DspEffect:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 17
	jr	z, PanelButton_DspEffect_Skip
	cp	a, 14
	jr	z, PanelButton_DspEffect_Skip
	cp	a, 19
	jr	z, PanelButton_DspEffect_Skip
	ld	a, (PART_SELECT:16)
	cp	a, 15
	jr	ule, PanelButton_DspEffect_Skip2
PanelButton_DspEffect_Skip:
	jr	FileIO_BytecodeData_Code_Epilogue19
PanelButton_DspEffect_Skip2:
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	cp	a, 0:i3
	jr	z, FileIO_BytecodeData_Code_Entry7
	set	5, (0x8e92:16)
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 93
	call	SndParam_LookupViaEncode
	and	hl, 127
	lda	xde, (xiz+3)
	lda	xbc, (xiz+2)
	cp	hl, 0:i3
	jr	z, PanelButton_DspEffect_Skip3
	ld	(xbc), 0
	jr	PanelButton_DspEffect_Join
PanelButton_DspEffect_Skip3:
	ld	a, (PART_SELECT:16)
	extz	wa
	lda	xhl, (37261:16)
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	ld	(xbc), a
PanelButton_DspEffect_Join:
	ld	(xde), 127
	jr	FileIO_BytecodeData_Code_Join11
FileIO_BytecodeData_Code_Entry7:
	res	5, (0x8e92:16)
	ld	(xbc), 0
	ld	(xiz+3), 0
FileIO_BytecodeData_Code_Join11:
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue19:
	pop	xiz
	ret
PanelButton_DigitalReverb:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 17
	jr	z, PanelButton_DigitalReverb_Epilogue
	cp	a, 19
	jr	z, PanelButton_DigitalReverb_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_DigitalReverb_Epilogue:
	pop	xiz
	ret
PanelButton_Sustain:
	push	xiz
	ld	xiz, xwa
	bit	3, (0x34cd:16)
	jr	nz, FileIO_BytecodeData_Code_Epilogue21
	ld	a, (CURRENT_MODE:16)
	cp	a, 17
	jr	z, PanelButton_Sustain_Skip
	cp	a, 19
	jr	z, PanelButton_Sustain_Skip
	calr	SndParam_ResolveSelectedPartVoice
	cp	(xhl), 15
	jr	nz, FileIO_BytecodeData_Code_Entry8
PanelButton_Sustain_Skip:
	jr	FileIO_BytecodeData_Code_Epilogue21
FileIO_BytecodeData_Code_Entry8:
	res	1, (0x90f9:16)
	ld	xwa, xiz
	calr	PanelEvent_FillSelectedPart
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue21:
	pop	xiz
	ret
PanelButton_MusicStyleArranger:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelButton_MusicStyleArranger_Epilogue
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, PanelButton_MusicStyleArranger_Epilogue
	cp	(xiz+2), 0
	jr	z, PanelButton_MusicStyleArranger_Skip
	set	3, (0x8d52:16)
PanelButton_MusicStyleArranger_Skip:
	ld	xwa, xiz
	calr	PanelEvent_Post
	inc	4, xiz
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_MusicStyleArranger_Epilogue:
	pop	xiz
	ret
PanelButton_MspNumber:
	dec	4, xsp
	push	qiz
	ld	(xsp+2), xwa
	cp	(CURRENT_MODE:16), 19
	jrl	z, PanelButton_MspNumber_Epilogue
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, PanelButton_MspNumber_Epilogue
	ld	xwa, (xsp+2)
	ld	a, (xwa+3)
	extz	wa
	extz	xwa
	call	Util_FindLowestSetBit
	ldfr_berp	l, 251
	ld	xwa, 165888
	call	SndParam_LookupReadOnly
	ldto_berp	c, 251
	extz	bc
	ld	wa, bc
	sla	wa, 2
	cp	hl, 18
	jr	z, PanelButton_MspNumber_Skip
	cp	hl, 17
	jr	nz, PanelButton_MspNumber_Skip2
	lda	xde, (FileIO_BytecodeData_Data_13:24)
	ld	c, (xde+bc)
	lda	xde, (FileIO_BytecodeData_Code_Entry8_PtrTable:24)
	lda	xde, (xde+wa)
	ld	xwa, (xsp+2)
	ld	xhl, (xde)
	call	(xhl)
	jr	PanelButton_MspNumber_Join
PanelButton_MspNumber_Skip:
	lda	xde, (FileIO_BytecodeData_Data_14:24)
	ld	c, (xde+bc)
	lda	xde, (FileIO_BytecodeData_Code_Entry8_PtrTable_2:24)
	lda	xde, (xde+wa)
	ld	xwa, (xsp+2)
	ld	xhl, (xde)
	call	(xhl)
	jr	PanelButton_MspNumber_Join
PanelButton_MspNumber_Skip2:
	ld	xwa, (xsp+2)
	calr	PanelEvent_Post
PanelButton_MspNumber_Join:
	ld	xwa, 4:i3
	add	(xsp+2), xwa
	ld	xwa, (xsp+2)
	calr	PanelEvent_Post
PanelButton_MspNumber_Epilogue:
	pop	qiz
	inc	4, xsp
	ret
PanelButton_Variation:
	lda	xsp, (xsp-10)
	push	qiz
	ld	(xsp+8), xwa
	ld	xwa, (xsp+8)
	ld	a, (xwa+2)
	ldfr_berp	a, 251
	cpib_erp	251, 0
	jrl	z, PanelButton_Variation_Epilogue
	ld	a, (CURRENT_MODE:16)
	cp	a, 14
	jr	z, PanelButton_Variation_Skip
	cp	a, 19
	jr	z, PanelButton_Variation_Skip
	ld	xwa, 0:i3
	ldto_berp	a, 251
	call	Util_FindLowestSetBit
	ldfr_berp	l, 251
	ld	(xsp+4), 72
	ld	xwa, 163840
	call	SndParam_LookupReadOnly
	ld	(xsp+5), l
	ld	xwa, 163841
	call	SndParam_LookupReadOnly
	lda	xwa, (xsp+2)
	ld	(xwa+4), l
	call	SndParam_ResolveVoiceEntry
	lda	xhl, (xsp+2)
	ld	xwa, (xsp+8)
	lda	xbc, (xwa+2)
	lda	xde, (xwa+3)
	cp	(xhl), 14
	jr	nc, PanelButton_Variation_Skip2
	ldto_berp	a, 251
	extz	wa
	lda	xhl, (FileIO_BytecodeData_Data_15:24)
	ld	a, (xhl+wa)
	ld	(xbc), a
	ld	(xde), 48
	set	3, (0x8d52:16)
	jr	PanelButton_Variation_Join
PanelButton_Variation_Skip:
	jr	PanelButton_Variation_Epilogue
PanelButton_Variation_Skip2:
	ld	xwa, (xsp+8)
	ld	(xwa+1), 0
	ld	a, (xhl)
	ld	(xbc), a
	ld	a, (xhl+1)
	srl	a, 2
	sll	a, 2
	addb_erp	a, 251
	ld	l, a
	ld	(xde), l
	ld	a, (xbc)
	extz	wa
	lda	xbc, (65426:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), l
PanelButton_Variation_Join:
	ld	xwa, (xsp+8)
	calr	PanelEvent_Post
	ld	xwa, 4:i3
	add	(xsp+8), xwa
	ld	xwa, (xsp+8)
	calr	PanelEvent_Post
PanelButton_Variation_Epilogue:
	pop	qiz
	lda	xsp, (xsp+10)
	ret
; foot switch FS1 (PG.2; event 28 bit 0): acts per panel parameter 0x2886 (tag 0x99 payload byte 4)
PanelAction_FootSwitch1:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootSwitch1_Epilogue
	ld	xwa, 10374
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootSwitch1_Epilogue:
	pop	xiz
	ret
; foot switch FS2 (PG.3; event 28 bit 1): acts per panel parameter 0x2888 (tag 0x99 payload byte 5)
PanelAction_FootSwitch2:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootSwitch2_Epilogue
	ld	xwa, 10376
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootSwitch2_Epilogue:
	pop	xiz
	ret
; foot controller FC1 (PG.4; event 29 bit 0): acts per panel parameter 0x288A (tag 0x99 payload byte 6)
PanelAction_FootController1:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootController1_Epilogue
	ld	xwa, 10378
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootController1_Epilogue:
	pop	xiz
	ret
; foot controller FC2 (PG.5; event 29 bit 1): acts per panel parameter 0x288C (tag 0x99 payload byte 7)
PanelAction_FootController2:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootController2_Epilogue
	ld	xwa, 10380
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootController2_Epilogue:
	pop	xiz
	ret
; foot controller FC3 (PG.6; event 29 bit 2): acts per panel parameter 0x288E (tag 0x99 payload byte 8)
PanelAction_FootController3:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootController3_Epilogue
	ld	xwa, 10382
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootController3_Epilogue:
	pop	xiz
	ret
; foot controller FC4 (PG.7; event 29 bit 3): acts per panel parameter 0x2890 (tag 0x99 payload byte 9)
PanelAction_FootController4:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_FootController4_Epilogue
	ld	xwa, 10384
	call	SndParam_LookupReadOnly
	extz	hl
	ld	xwa, xiz
	ld	bc, hl
	calr	PanelAction_DispatchPedalFunction
PanelAction_FootController4_Epilogue:
	pop	xiz
	ret
; event 22 (left-panel header 0xD1): the byte as two 7-bit values ((b & 1) << 6, b >> 1)
PanelAction_Event22:
	cp	(CURRENT_MODE:16), 19
	ret	z
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	ld	e, (xhl)
	cp	e, 255
	jr	nz, PanelAction_Event22_Skip
	ld	(xhl), 127
	ld	(xix), 127
	jr	PanelAction_Event22_Join
PanelAction_Event22_Skip:
	ld	c, e
	and	c, 1
	sll	c, 6
	ld	(xhl), c
	srl	e, 1
	ld	(xix), e
PanelAction_Event22_Join:
	jrl	PanelEvent_Post
; modulation wheel (ENCODER_0_OUTPUT, event 26, queued by PanelInput_QueueWheelChanges): depends on panel parameter 0x2880 (tag 0x99 payload byte 2) being 182 or 183
PanelAction_ModWheel:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 10368
	call	SndParam_LookupReadOnly
	cp	hl, 183
	jr	z, PanelAction_ModWheel_Skip
	cp	hl, 182
	jr	nz, PanelAction_ModWheel_Epilogue
	ld	xwa, xiz
	jr	PanelAction_ModWheel_Join
PanelAction_ModWheel_Skip:
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_ModWheel_Epilogue
	ld	(xiz), 179
	ld	(xiz+1), 0
	ld	xwa, xiz
PanelAction_ModWheel_Join:
	calr	PanelEvent_Post
PanelAction_ModWheel_Epilogue:
	pop	xiz
	ret
; event 23 (left-panel header 0xD2): post unless MD_DEMO
PanelAction_Event23:
	cp	(CURRENT_MODE:16), 19
	ret	z
	jrl	PanelEvent_Post
; volume slider (ENCODER_1_OUTPUT, event 27, queued by PanelInput_QueueWheelChanges): post when panel parameter 0x104 (tag 0x93 payload byte 6 bit 7) is set
PanelAction_Volume:
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 19
	jr	z, PanelAction_Volume_Epilogue
	ld	xwa, 260
	call	SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr	z, PanelAction_Volume_Epilogue
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelAction_Volume_Epilogue:
	pop	xiz
	ret
; PanelEvent_FillSelectedPart: If byte 0 of the panel event at XWA is 0 and byte 1 is not 3, writes the selected part
;   (PART_SELECT, 0x8D3A) into byte 0. Basis: callers + body -- PanelAction_PostUnlessDemo and the other panel actions
;   call it on the event frame immediately before PanelEvent_Post.
PanelEvent_FillSelectedPart:
	cp	(xwa), 0
	ret	nz
	.byte 0x88, 0x01, 0x3f, 0x03
	ret	z
	.byte 0xb0, 0x14, 0x3a, 0x8d
	ret
; SndParam_ResolveSelectedPartVoice: Resolves the voice of the selected part (PART_SELECT): builds a 6-byte record {+2
;   part, +3 part param 0, +4 part param 32} on its stack frame, runs SndParam_ResolveVoiceEntry and returns XHL ->
;   that record (+0/+1 = resolved entry; the frame is already released, so read it at once). Basis: callers + body --
;   the DIGITAL EFFECT and SUSTAIN button handlers test byte +0 for 0x0F / 0x0C right after the call.
SndParam_ResolveSelectedPartVoice:
	dec	6, xsp
	ld	a, (PART_SELECT:16)
	extz	wa
	ld	bc, 0:i3
	call	SndParam_LookupViaEncode
	ld	(xsp+3), l
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	lda	xwa, (xsp)
	ld	(xwa+4), l
	ld	(xwa+2), (0x8d3a)
	call	SndParam_ResolveVoiceEntry
	lda	xhl, (xsp)
	inc	6, xsp
	ret
	dec	6, xsp
	ld	xwa, 163840
	call	SndParam_LookupReadOnly
	ld	(xsp+3), l
	ld	xwa, 163841
	call	SndParam_LookupReadOnly
	lda	xwa, (xsp)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	lda	xhl, (xsp)
	inc	6, xsp
	ret
; PanelAction_DispatchPedalFunction: Runs the foot-pedal function assigned by code BC: index =
;   PanelAction_PedalAssignHandlerIndex[BC]; if <= 22, calls PanelAction_PedalFunctionHandlers[index] with XWA = the
;   panel event. Basis: callers + body -- PanelAction_FootSwitch1/2 and FootController1-4 pass their assignment
;   parameter (0x2886..0x2890) in BC.
PanelAction_DispatchPedalFunction:
	extz	bc
	lda	xde, (PanelAction_PedalAssignHandlerIndex:24)
	ld	e, (xde+bc)
	cp	e, 22
	ret	ugt
	extz	de
	sla	de, 2
	lda	xhl, (PanelAction_PedalFunctionHandlers:24)
	exts	xde
	add	xde, xhl
	ld	xhl, (xde)
	call	(xhl)
	ret
; PanelAction_PedalFn_Code40: Foot-pedal function [0] of PanelAction_PedalFunctionHandlers, the only handler that
;   PanelAction_PedalAssignHandlerIndex gives to assignment code 0x40.  Unless the mode is 17 or (0x34CD) bit 3 is
;   set, it sets (0x90F9) bit 1 and, for each of the up-to-16 part tags in the 0xFF-terminated list at 0x90FB whose
;   SndParam_LookupViaEncode(tag, 0x601) is 1, posts the panel event {tag, 4, 8 if the pedal event's bytes +2 and
;   +3 share a bit else 0, 8}.  [INFERENCE] 0x40 is MIDI CC64, so this is probably the sustain function.  Basis:
;   table + body.
PanelAction_PedalFn_Code40:
	dec	4, xsp
	push	xiz
	ld	xiz, xwa
	cp	(CURRENT_MODE:16), 17
	jr	z, FileIO_BytecodeData_Code_Epilogue33
	bit	3, (0x34cd:16)
	jr	nz, FileIO_BytecodeData_Code_Epilogue33
	set	1, (0x90f9:16)
	ld	a, (xiz+3)
	and	a, (xiz+2)
	ld	(xsp+4), 0
	cp	a, 0:i3
	jr	z, FileIO_BytecodeData_Code_Skip66
	ld	(xsp+4), 8
FileIO_BytecodeData_Code_Skip66:
	ldw	(xsp+6), 0
FileIO_BytecodeData_Code_Loop2:
	lda	xbc, (37115:16)
	ld	wa, (xsp+6)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, FileIO_BytecodeData_Code_Epilogue33
	extz	wa
	ldw	bc, 1537
	call	SndParam_LookupViaEncode
	cp	hl, 1:i3
	jr	nz, FileIO_BytecodeData_Code_Skip67
	lda	xwa, (37115:16)
	ld	bc, (xsp+6)
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	ld	(xiz), a
	ld	(xiz+1), 4
	ld	a, (xsp+4)
	ld	(xiz+2), a
	ld	(xiz+3), 8
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Skip67:
	incw	1, (xsp+6)
	cpw	(xsp+6), 16
	jr	c, FileIO_BytecodeData_Code_Loop2
FileIO_BytecodeData_Code_Epilogue33:
	pop	xiz
	inc	4, xsp
	ret
NakaData_WidgetInit1:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip68
	ld	(xde), 1
	jr	FileIO_BytecodeData_Code_Join16
FileIO_BytecodeData_Code_Skip68:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join16:
	ld	(xhl), 1
	jrl	PanelEvent_Post
FileIO_BytecodeData_Code_Loop3:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, FileIO_BytecodeData_Code_Skip69
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip69
	cp	a, 14
	jr	z, FileIO_BytecodeData_Code_Skip69
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip69
	cp	a, 3:i3
	jr	z, FileIO_BytecodeData_Code_Skip69
	cp	a, 19
	jr	nz, FileIO_BytecodeData_Code_Skip70
FileIO_BytecodeData_Code_Skip69:
	jr	FileIO_BytecodeData_Code_Epilogue34
FileIO_BytecodeData_Code_Skip70:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, FileIO_BytecodeData_Code_Epilogue34
	ld	a, (xiz+3)
	and	a, (xiz+2)
	jr	z, FileIO_BytecodeData_Code_Epilogue34
	set	1, (0x90f9:16)
	ld	(xiz), 152
	ld	(xiz+1), 1
	ld	xwa, 768
	call	SndParam_LookupReadOnly
	lda	xwa, (xiz+2)
	cp	l, 80
	jr	c, FileIO_BytecodeData_Code_Skip71
	ld	(xwa), 1
	jr	FileIO_BytecodeData_Code_Join17
FileIO_BytecodeData_Code_Skip71:
	inc	1, l
	ld	(xwa), l
FileIO_BytecodeData_Code_Join17:
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue34:
	pop	xiz
	ret
FileIO_BytecodeData_Code_Join18:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, FileIO_BytecodeData_Code_Skip72
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip72
	cp	a, 14
	jr	z, FileIO_BytecodeData_Code_Skip72
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip72
	cp	a, 3:i3
	jr	z, FileIO_BytecodeData_Code_Skip72
	cp	a, 19
	jr	nz, FileIO_BytecodeData_Code_Skip73
FileIO_BytecodeData_Code_Skip72:
	jr	FileIO_BytecodeData_Code_Epilogue35
FileIO_BytecodeData_Code_Skip73:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, FileIO_BytecodeData_Code_Epilogue35
	ld	a, (xiz+3)
	and	a, (xiz+2)
	jr	z, FileIO_BytecodeData_Code_Epilogue35
	set	1, (0x90f9:16)
	ld	(xiz), 152
	ld	(xiz+1), 1
	ld	xwa, 768
	call	SndParam_LookupReadOnly
	lda	xwa, (xiz+2)
	cp	l, 1:i3
	jr	ugt, FileIO_BytecodeData_Code_Skip74
	ld	(xwa), 80
	jr	FileIO_BytecodeData_Code_Join19
FileIO_BytecodeData_Code_Skip74:
	dec	1, l
	ld	(xwa), l
FileIO_BytecodeData_Code_Join19:
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	PanelEvent_Post
FileIO_BytecodeData_Code_Epilogue35:
	pop	xiz
	ret
ExtDev_SndParam_Block48_Var40:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip75
	ld	(xde), 64
	jr	FileIO_BytecodeData_Code_Join20
FileIO_BytecodeData_Code_Skip75:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join20:
	ld	(xhl), 64
	jrl	PanelEvent_Post
ExtDev_SndParam_Block48_Var80:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip76
	ld	(xde), 128
	jr	FileIO_BytecodeData_Code_Join21
FileIO_BytecodeData_Code_Skip76:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join21:
	ld	(xhl), 128
	jrl	PanelEvent_Post
ExtDev_SndParam_Block48_Var04:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip77
	ld	(xde), 4
	jr	FileIO_BytecodeData_Code_Join22
FileIO_BytecodeData_Code_Skip77:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join22:
	ld	(xhl), 4
	jrl	PanelEvent_Post
ExtDev_SndParam_Block48_Var04_B:
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 6
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip78
	ld	(xde), 4
	jr	NakaData_WidgetInit1_Code_Join
FileIO_BytecodeData_Code_Skip78:
	ld	(xde), 0
NakaData_WidgetInit1_Code_Join:
	ld	(xhl), 4
	jrl	PanelEvent_Post
ExtDev_SndParam_Write98_Block:
	push	xiz
	ld	xiz, xwa
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 1539
	call	SndParam_LookupViaEncode
	cp	hl, 1:i3
	jr	nz, NakaData_WidgetInit1_Code_Epilogue
	set	1, (0x90f9:16)
	ld	(xiz), 152
	ld	(xiz+1), 2
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	and	a, (xbc)
	jr	z, NakaData_WidgetInit1_Code_Skip
	ld	(xbc), 128
	jr	NakaData_WidgetInit1_Code_Join2
NakaData_WidgetInit1_Code_Skip:
	ld	(xbc), 0
NakaData_WidgetInit1_Code_Join2:
	ld	(xde), 128
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue:
	pop	xiz
	ret
ExtDev_SndParam_Block98_Var40:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 2
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, NakaData_WidgetInit1_Code_Skip8
	ld	(xde), 64
	jr	NakaData_WidgetInit1_Code_Join5
NakaData_WidgetInit1_Code_Skip8:
	ld	(xde), 0
NakaData_WidgetInit1_Code_Join5:
	ld	(xhl), 64
	jrl	PanelEvent_Post
ExtDev_SndParam_BlockA9_Var02:
	cp	(CURRENT_TITLE:16), 135
	ret	nz
	set	1, (0x90f9:16)
	ld	(xwa), 0xa9
	ld	(xwa+1), 10
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, NakaData_WidgetInit1_Code_Skip9
	ld	(xde), 2
	jr	NakaData_WidgetInit1_Code_Join6
NakaData_WidgetInit1_Code_Skip9:
	ld	(xde), 0
NakaData_WidgetInit1_Code_Join6:
	ld	(xhl), 2
	calr	PanelEvent_Post
	ret
ExtDev_SndParam_Block98_Var80:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip79
	ld	(xde), 128
	jr	FileIO_BytecodeData_Code_Join23
FileIO_BytecodeData_Code_Skip79:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join23:
	ld	(xhl), 128
	jrl	PanelEvent_Post
ExtDev_SndParam_Block98_Var40_B:
	set	1, (0x90f9:16)
	ld	(xwa), 152
	ld	(xwa+1), 11
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, NakaData_WidgetInit1_Code_Skip5
	ld	(xde), 64
	jr	NakaData_WidgetInit1_Code_Join4
NakaData_WidgetInit1_Code_Skip5:
	ld	(xde), 0
NakaData_WidgetInit1_Code_Join4:
	ld	(xhl), 64
	jrl	PanelEvent_Post
ExtDev_SndParam_ConfigAndWrite:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+3)
	and	a, (xiz+2)
	jr	z, NakaData_WidgetInit1_Code_Epilogue5
	set	1, (0x90f9:16)
	ld	(xiz), (PART_SELECT)
	ld	(xiz+1), 5
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 93
	call	SndParam_LookupViaEncode
	lda	xbc, (xiz+2)
	cp	hl, 0:i3
	jr	nz, NakaData_WidgetInit1_Code_Skip6
	ld	a, (PART_SELECT:16)
	extz	wa
	lda	xde, (0x918d:16)
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ld	(xbc), a
	jr	FileIO_BytecodeData_Code_Join24
NakaData_WidgetInit1_Code_Skip6:
	ld	(xbc), 0
FileIO_BytecodeData_Code_Join24:
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue5:
	pop	xiz
	ret
ExtDev_SndParam_Block14_Dual:
	lda	xhl, (xwa+2)
	lda	xix, (xwa+3)
	ld	e, (xhl)
	ld	c, (xix)
	and	c, e
	ret	z
	set	1, (0x90f9:16)
	ld	(xwa), (0x8d3a)
	ld	(xwa+1), 4
	ld	(xhl), 64
	ld	(xix), 64
	calr	PanelEvent_Post
	ret
ExtDev_SndParam_Write48_Block:
	push	xiz
	ld	xiz, xwa
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr	nz, NakaData_WidgetInit1_Code_Epilogue2
	set	1, (0x90f9:16)
	ld	(xiz), 72
	ld	(xiz+1), 4
	lda	xbc, (xiz+2)
	lda	xde, (xiz+3)
	ld	a, (xde)
	and	a, (xbc)
	jr	z, NakaData_WidgetInit1_Code_Skip2
	ld	(xbc), 64
	jr	NakaData_WidgetInit1_Code_Join3
NakaData_WidgetInit1_Code_Skip2:
	ld	(xbc), 0
NakaData_WidgetInit1_Code_Join3:
	ld	(xde), 64
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue2:
	pop	xiz
	ret
ExtDev_SndParam_Block48_Var02:
	cp	(CURRENT_MODE:16), 16
	ret	z
	set	1, (0x90f9:16)
	ld	(xwa), 72
	ld	(xwa+1), 5
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip80
	ld	(xde), 2
	jr	FileIO_BytecodeData_Code_Join25
FileIO_BytecodeData_Code_Skip80:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join25:
	ld	(xhl), 2
	jrl	PanelEvent_Post
ExtDev_SndParam_Block70_Var04:
	set	1, (0x90f9:16)
	ld	(xwa), 112
	ld	(xwa+1), 0
	lda	xde, (xwa+2)
	lda	xhl, (xwa+3)
	ld	c, (xhl)
	and	c, (xde)
	jr	z, FileIO_BytecodeData_Code_Skip81
	ld	(xde), 4
	jr	FileIO_BytecodeData_Code_Join26
FileIO_BytecodeData_Code_Skip81:
	ld	(xde), 0
FileIO_BytecodeData_Code_Join26:
	ld	(xhl), 4
	jrl	PanelEvent_Post
ExtDev_SndParam_DispatchAndWriteA8:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, FileIO_BytecodeData_Code_Skip82
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip82
	cp	a, 14
	jr	z, FileIO_BytecodeData_Code_Skip82
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip82
	cp	a, 3:i3
	jr	z, FileIO_BytecodeData_Code_Skip82
	cp	a, 19
	jr	nz, NakaData_WidgetInit1_Code_Skip3
FileIO_BytecodeData_Code_Skip82:
	jr	NakaData_WidgetInit1_Code_Epilogue3
NakaData_WidgetInit1_Code_Skip3:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, NakaData_WidgetInit1_Code_Epilogue3
	set	1, (0x90f9:16)
	ld	(xiz), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, NakaData_WidgetInit1_Code_Epilogue3
	ld	(xde), 2
	ld	(xhl), 2
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue3:
	pop	xiz
	ret
ExtDev_SndParam_DispatchAndWriteA8_Alt:
	push	xiz
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, FileIO_BytecodeData_Code_Skip83
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip83
	cp	a, 14
	jr	z, FileIO_BytecodeData_Code_Skip83
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip83
	cp	a, 3:i3
	jr	z, FileIO_BytecodeData_Code_Skip83
	cp	a, 19
	jr	nz, NakaData_WidgetInit1_Code_Skip4
FileIO_BytecodeData_Code_Skip83:
	jr	NakaData_WidgetInit1_Code_Epilogue4
NakaData_WidgetInit1_Code_Skip4:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, NakaData_WidgetInit1_Code_Epilogue4
	set	1, (0x90f9:16)
	ld	(xiz), 168
	ld	(xiz+1), 4
	lda	xde, (xiz+2)
	lda	xhl, (xiz+3)
	ld	c, (xde)
	ld	a, (xhl)
	and	a, c
	jr	z, NakaData_WidgetInit1_Code_Epilogue4
	ld	(xde), 1
	ld	(xhl), 1
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue4:
	pop	xiz
	ret
ExtDev_SndParam_MultiReg_Iterate:
	set	1, (0x90f9:16)
	lda	xix, (xwa+2)
	ld	l, (xwa+3)
	ld	d, (xix)
	ld	e, l
	and	e, d
	extz	bc
	cp	e, 0:i3
	jrl	nz, FileIO_BytecodeData_Code_Loop3
	or	d, l
	ld	(xix), d
	jrl	FileIO_BytecodeData_Code_Join18
ExtDev_SndParam_DispatchComplex:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), c
	ld	xiz, xwa
	ld	a, (CURRENT_MODE:16)
	cp	a, 16
	jr	z, FileIO_BytecodeData_Code_Skip84
	cp	a, 15
	jr	z, FileIO_BytecodeData_Code_Skip84
	cp	a, 14
	jr	z, FileIO_BytecodeData_Code_Skip84
	cp	a, 17
	jr	z, FileIO_BytecodeData_Code_Skip84
	cp	a, 3:i3
	jr	z, FileIO_BytecodeData_Code_Skip84
	cp	a, 19
	jr	nz, NakaData_WidgetInit1_Code_Skip7
FileIO_BytecodeData_Code_Skip84:
	jr	NakaData_WidgetInit1_Code_Epilogue6
NakaData_WidgetInit1_Code_Skip7:
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	z, NakaData_WidgetInit1_Code_Epilogue6
	ld	a, (xiz+3)
	and	a, (xiz+2)
	jr	z, NakaData_WidgetInit1_Code_Epilogue6
	set	1, (0x90f9:16)
	ld	(xiz), 152
	ld	(xiz+1), 1
	call	BitMapOut_PrepareRender_CheckBit1
	sll	l, 3
	ld	w, (xsp+4)
	sub	w, 191
	add	w, l
	ld	(xiz+2), w
	ld	(xiz+3), 127
	ld	xwa, xiz
	calr	PanelEvent_Post
NakaData_WidgetInit1_Code_Epilogue6:
	pop	xiz
	inc	2, xsp
	ret
; every button but the LCD ones and HELP, in MD_HELP (PanelButton_HelpModeActionLists)
PanelButton_HelpMode:
	push	xiz
	ld	xiz, xwa
	ld	a, (xiz+2)
	cp	a, 0:i3
	jr	z, PanelButton_HelpMode_Epilogue
	ld	w, 0:opc
	extz	xwa
	call	Util_FindLowestSetBit
	lda	xbc, (xiz+2)
	ld	(xbc), l
	ld	a, (0x8e90:16)
	extz	wa
	sla	wa, 2
	lda	xde, (PanelButton_HelpCodeMaps:24)
	ld	xde, (xde+wa)
	or xde, xde
	jr	z, PanelButton_HelpMode_Epilogue
	extz	hl
	ld	a, (xde+hl)
	ld	(xbc), a
	cp	a, 255
	jr	z, PanelButton_HelpMode_Epilogue
	ld	(xiz+3), 255
	ld	xwa, xiz
	calr	PanelEvent_Post
PanelButton_HelpMode_Epilogue:
	pop	xiz
	ret

VoiceEntry_FindMasterVolume:
	lda xde, (0xc039:16)
	ld xbc, 0:i3
	ld wa, 0:i3
	jr VoiceEntry_CheckTerminator

VoiceEntry_CheckMatch:
	cp (xde), 0x98
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 1), 0x1
	jr nz, VoiceEntryLoop_Continue
	cp (xde + 3), 0x7f
	jr nz, VoiceEntryLoop_Continue
	or xbc, xbc
	jr z, VoiceEntry_SaveMatch
	ld (xbc + 3), 0x0

VoiceEntry_SaveMatch:
	ld xbc, xde

VoiceEntryLoop_Continue:
	inc 1, wa
	inc 4, xde
	cp wa, 0xf
	ret nc

VoiceEntry_CheckTerminator:
	cp (xde), 0xff
	jr nz, VoiceEntry_CheckMatch
	ret

PanelInput_InitPedalRecords:
	calr PanelInput_ClearChangeQueue
	lda xbc, (PanelInput_PedalRecordDefaults:24)
	ld xwa, xbc
	lda xde, (0x8eb6:16)
	lda xhl, (xbc + 12)

PanelInput_InitPedalRecords_Loop:
	ld xiy, xwa
	ld xix, xde
	ldiw
	ldiw
	inc 4, xwa
	inc 4, xde
	cp xwa, xhl
	jr c, PanelInput_InitPedalRecords_Loop
	ret

Audio_NullHandler_A:
	ret

Audio_NullHandler_B:
	ret

Audio_NullHandler_C:
	ret

Encoder_TimingAndOutput:
	inc 1, (0x8ec6:16)
	ld wa, (0x8ec8:16)
	cp wa, 0:i3
	jr z, Encoder_CheckTimerDelta
	dec 1, wa
	ld (0x8ec8:16), wa

Encoder_CheckTimerDelta:
	ld wa, (SYSTEM_TIMESTAMP:16)
	sub wa, (0x8ec2:16)
	cp wa, 0x10
	jr c, Encoder_CheckBitAndProcess
	ld (0x8ec6:16), 0
	jr Encoder_ProcessUpdate

Encoder_CheckBitAndProcess:
	bit 0, (0x8ec6:16)
	jr nz, Encoder_IncrementAndDispatch

Encoder_ProcessUpdate:
	calr PanelInput_Poll

Encoder_IncrementAndDispatch:
	call Audio_IncrementUpdateCounter
	push	sr
	ei 6
	call MidiOut_SerializeAndSend
	pop	sr
	jp CompIface_ProcessInput

; Each periodic tick (unless CURRENT_TITLE 247): drain the control-panel RX queue into change records, scan the
; pedal ports, queue the wheel encoders' changes.  The records go to PanelInput_ChangeQueue (RAM 0x8E94, 3 bytes
; each, count at 0x8EC4); PanelButton_ProcessChanges dispatches them later.
PanelInput_Poll:
	ldmm16 0x8ec2, SYSTEM_TIMESTAMP
	cp (CURRENT_TITLE:16), 247
	ret z
	calr PanelInput_DrainRxQueue
	calr PanelInput_ScanPedalPorts
	calr PanelInput_QueueWheelChanges
	ret

; While fewer than 7 records are queued, read one {header, state, changed} from CPANEL_RX_EVENT_QUEUE
; (PanelInput_ReadRxRecord) and queue it (PanelInput_QueueChange).
PanelInput_DrainRxQueue:
	push xiz
	lda xiz, (0x8eb2:16)
	cp (0x8ec4:16), 7
	jr nc, PanelInput_DrainRxQueue_Return

PanelInput_DrainRxQueue_Loop:
	ld xwa, xiz
	calr PanelInput_ReadRxRecord
	cp l, 0xff
	jr z, PanelInput_DrainRxQueue_Return
	ld xwa, xiz
	calr PanelInput_QueueChange
	cp (0x8ec4:16), 7
	jr c, PanelInput_DrainRxQueue_Loop

PanelInput_DrainRxQueue_Return:
	pop xiz
	ret

; xwa -> a 3-byte record: pop a header (-> event index, PanelInput_EventIndexOfHeader) and two data bytes from
; CPANEL_RX_EVENT_QUEUE; l = 0 when all three were there, 0xFF otherwise.
PanelInput_ReadRxRecord:
	dec 2, xsp
	push xiz
	ld xiz, xwa
	ld (xsp + 4), 0xff
	call CPanel_RxEventQueue_Pop
	cp hl, 0xffff
	jr z, PanelInput_ReadRxRecord_Return
	extz hl
	ld wa, hl
	calr PanelInput_EventIndexOfHeader
	ld (xiz), l
	call CPanel_RxEventQueue_Pop
	cp hl, 0xffff
	jr z, PanelInput_ReadRxRecord_Return
	ld (xiz + 1), l
	call CPanel_RxEventQueue_Pop
	cp hl, 0xffff
	jr z, PanelInput_ReadRxRecord_Return
	ld (xiz + 2), l
	ld (xsp + 4), 0x0

PanelInput_ReadRxRecord_Return:
	ld l, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

; Port G is the pedal port, active low (technics-docs cpu-subsystem.md): PG.3-2 -> the foot-switch record (event
; 28), PG.7-4 -> the foot-controller record (event 29; all four high = nothing engaged, which arms a 500-tick
; debounce at 0x8EC8), PD.6 -> the third record (event 30).  Records at 0x8EB6 / 0x8EBA / 0x8EBE.
PanelInput_ScanPedalPorts:
	ld	a, (PG:8)
	and a, 0xc
	srl a, 2
	ld c, a
	ld xwa, 0x8eb6
	calr PanelInput_UpdatePedalRecord
	ld	a, (PG:8)
	and a, 0xf0
	srl a, 4
	cp a, 0xf
	jr nz, PanelInput_ScanPedalPorts_Debounce
	ldw (0x8ec8:16), 500
	jr PanelInput_ScanPedalPorts_PD6

PanelInput_ScanPedalPorts_Debounce:
	cpw (0x8ec8:16), 0
	jr nz, PanelInput_ScanPedalPorts_PD6
	lda xwa, (0x8eba:16)
	ld	c, (PG:8)
	and c, 0xf0
	srl c, 4
	calr PanelInput_UpdatePedalRecord

PanelInput_ScanPedalPorts_PD6:
	lda xwa, (0x8ebe:16)
	ldcf	6, (PD:8)
	scc8 c, c
	jr PanelInput_UpdatePedalRecord

; xwa -> a pedal record {event index, raw, previous raw, state}, c = the new raw bits: a bit of the state follows
; the raw bit once two samples agree; when the state changes, queue {index, new state, new ^ old state} with
; PanelInput_QueueChange (unless 7 records are already queued).
PanelInput_UpdatePedalRecord:
	lda xsp, (xsp - 10)
	push xiz
	lda xhl, (xwa + 1)
	cp (xwa), 0x1d
	jr nz, PanelInput_UpdatePedalRecord_Store
	ld e, c
	and e, 0xf
	cp e, 0xf
	jr nz, PanelInput_UpdatePedalRecord_Store
	xor c, 0xf
	ld (xhl), c
	jr PanelInput_UpdatePedalRecord_Compare

PanelInput_UpdatePedalRecord_Store:
	ld (xhl), c

PanelInput_UpdatePedalRecord_Compare:
	cp (0x8ec4:16), 7
	jr nc, PanelInput_UpdatePedalRecord_Return
	lda xbc, (xwa + 1)
	ld (xsp + 8), xbc
	ld b, (xbc)
	cp b, 0:i3
	jr nz, PanelInput_UpdatePedalRecord_Queue
	cp (xwa + 3), 0x0
	jr z, PanelInput_UpdatePedalRecord_Return

PanelInput_UpdatePedalRecord_Queue:
	lda xiz, (0x8eb2:16)
	ld (xsp + 4), xiz
	lda xiy, (xwa + 3)
	ld e, (xiy)
	ld (xsp + 12), e
	lda xix, (xwa + 2)
	ld l, (xix)
	ld d, l
	xor d, b
	and d, e
	and l, b
	or l, d
	ld (xiy), l
	ld xbc, (xsp + 8)
	ld c, (xbc)
	ld (xix), c
	cp l, e
	jr z, PanelInput_UpdatePedalRecord_Return
	ld a, (xwa)
	ld (xiz), a
	ld (xiz + 1), l
	ld a, (xsp + 12)
	xor a, l
	ld (xiz + 2), a
	ld xwa, (xsp + 4)
	calr PanelInput_QueueChange

PanelInput_UpdatePedalRecord_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

; ENCODER_0_OUTPUT (modulation wheel) and ENCODER_1_OUTPUT (volume slider): when bit 7 of the output's flag byte
; is set, clear it and queue {26 / 27, value, 0x7F}.
PanelInput_QueueWheelChanges:
	push xiz
	lda xiz, (0x8eb2:16)
	cp (0x8ec4:16), 7
	jr nc, PanelInput_QueueWheelChanges_Volume
	lda xbc, (ENCODER_0_OUTPUT:16)
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, PanelInput_QueueWheelChanges_Volume
	resm 7, (xwa)
	ld (xiz), 0x1a
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr PanelInput_QueueChange

PanelInput_QueueWheelChanges_Volume:
	cp (0x8ec4:16), 7
	jr nc, PanelInput_QueueWheelChanges_Return
	lda xbc, (ENCODER_1_OUTPUT:16)
	lda xwa, (xbc + 1)
	bitm 7, (xwa)
	jr z, PanelInput_QueueWheelChanges_Return
	resm 7, (xwa)
	ld (xiz), 0x1b
	ld a, (xbc)
	ld (xiz + 1), a
	ld (xiz + 2), 0x7f
	ld xwa, xiz
	calr PanelInput_QueueChange

PanelInput_QueueWheelChanges_Return:
	pop xiz
	ret

; wa = a control-panel packet header -> l = its event index: PanelInput_EventIndexByHeader[(h & 0xC0) >> 1 |
; (h & 0x1F)] (0..10 left-panel segments, 11..21 right, 22..24 left headers 0xD1-0xD3, 25 = header 0xD7, the
; TEMPO/PROGRAM data wheel -- records {0x19, delta, 0xFF}, as the kn7000_mame data-wheel patch feeds them -- and
; 0x1F = none).
PanelInput_EventIndexOfHeader:
	ld c, a
	and c, 0x1f
	and a, 0xc0
	srl a, 1
	or a, c
	extz wa
	lda xbc, (PanelInput_EventIndexByHeader:24)
	ld	l, (xbc+wa)
	ret

; xwa -> {event index, state, changed}: append it to PanelInput_ChangeQueue and call SeqStep_TimerDispatchC.
; In CURRENT_TITLE 251 only indexes above 0x15 (but 0x19) are queued: index 3 sets RAM 0x8D80 bit 0 from the
; state; 0x19 and the panel segments (<= 0x15) send MIDI_SendSysExCmd 0x10 on a press, and the segments go to
; EffectMode_MidiSetLEDs.
PanelInput_QueueChange:
	push xiz
	ld xiz, xwa
	ld c, (0x8ec4:16)
	ld a, c
	extz wa
	muls wa, 0x3
	lda xde, (0x8e94:16)
	exts xwa
	add xwa, xde
	cp (CURRENT_TITLE:16), 251
	jrl nz, PanelInput_QueueChange_AppendAndNotify
	cp (xiz), 0x3
	jr nz, PanelInput_QueueChange_Index19
	cp (xiz + 2), 0x1
	jr nz, PanelInput_QueueChange_Index19
	ld c, (0x8d80:16)
	res 0, c
	ld (0x8d80:16), c
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, PanelInput_QueueChange_Return
	set 0, c
	ld (0x8d80:16), c
	jr PanelInput_QueueChange_Done

PanelInput_QueueChange_Index19:
	cp (xiz), 0x19
	jr nz, PanelInput_QueueChange_Segment
	ld a, (xiz + 2)
	and a, 0x1
	and a, (xiz + 1)
	bit 0, a
	jr z, PanelInput_QueueChange_Return
	ldw wa, 0x10
	call MIDI_SendSysExCmd
	jr PanelInput_QueueChange_Done

PanelInput_QueueChange_Segment:
	cp (xiz), 0x15
	jr ugt, PanelInput_QueueChange_Append
	ld a, (xiz + 2)
	and a, (xiz + 1)
	jr z, PanelInput_QueueChange_Leds
	ldw wa, 0x10
	call MIDI_SendSysExCmd

PanelInput_QueueChange_Leds:
	ld xwa, xiz
	call EffectMode_MidiSetLEDs
	jr PanelInput_QueueChange_Done

PanelInput_QueueChange_Append:
	inc 1, c
	ld (0x8ec4:16), c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ld a, (0x8ec4:16)
	extz wa
	muls wa, 0x3
	ld	(xde+wa), 0xff

PanelInput_QueueChange_Return:
	jr PanelInput_QueueChange_Done

PanelInput_QueueChange_AppendAndNotify:
	inc 1, c
	ld (0x8ec4:16), c
	ld xiy, xiz
	ld xix, xwa
	ldi85
	ldiw
	ld a, (0x8ec4:16)
	extz wa
	muls wa, 0x3
	ld	(xde+wa), 0xff
	call SeqStep_TimerDispatchC

PanelInput_QueueChange_Done:
	pop xiz
	ret

PanelInput_ChangeQueue:
	lda xhl, (0x8e94:16)
	ret

PanelInput_ClearChangeQueue:
	ld (0x8e94:16), 255
	ld (0x8ec4:16), 0
	ret

	.include "midi/midi_encoder_routines.s"

MidiParam_ForceResync:
	ld (297:16), 131
	ld (296:16), 7
	ld wa, 0:i3
	calr MidiChannel_GetParamByIndex
	ld a, l
	ld bc, 2:i3
	call CPanel_EncoderDispatch
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	cpl a
	ld (MIDI_CC_MODWHEEL_VALUE:16), a
	ld wa, 0:i3
	calr MidiChannel_GetParamByIndex
	ld a, l
	ld bc, 2:i3
	call CPanel_EncoderDispatch
	lda xwa, (ENCODER_0_OUTPUT:16)
	ld (xwa), l
	setm 7, (xwa + 1)
	ld wa, 1:i3
	calr MidiChannel_GetParamByIndex
	ld a, l
	ld bc, 5:i3
	call CPanel_EncoderDispatch
	ld a, (MIDI_CC_VOLUME_VALUE:16)
	cpl a
	ld (MIDI_CC_VOLUME_VALUE:16), a
	ld wa, 1:i3
	calr MidiChannel_GetParamByIndex
	ld a, l
	ld bc, 5:i3
	call CPanel_EncoderDispatch
	lda xwa, (ENCODER_1_OUTPUT:16)
	ld (xwa), l
	setm 7, (xwa + 1)
	ret

MidiChannel_GetParamByIndex:
	cp a, 3:i3
	jr z, MidiChannel_GetParam3
	cp a, 2:i3
	jr z, MidiChannel_GetParam2
	cp a, 1:i3
	jr z, MidiChannel_GetParam1
	cp a, 0:i3
	jr nz, MidiChannel_GetParamReturn
	lda xbc, (288:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam1:
	lda xbc, (290:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam2:
	lda xbc, (292:16)
	jr MidiChannel_GetParamReturn

MidiChannel_GetParam3:
	lda xbc, (294:16)

MidiChannel_GetParamReturn:
	ld l, (xbc + 1)
	ret

MidiParam_ProcessDeltas:
	ld xwa, 0x8f10
	calr MidiParam_ProcessChannel0
	ld xwa, 0x8f16
	jr MidiParam_ProcessChannel1

MidiParam_ProcessChannel0:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld wa, 0:i3
	calr MidiChannel_GetParamByIndex
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	extz wa
	ld c, (ENCODER_0_LAST_VALUE:16)
	extz bc
	ld xde, 0x8f04
	calr MIDI_ComputeParamDelta
	lda xwa, (ENCODER_0_STATUS:16)
	bitm 3, (xwa)
	jr z, MidiParam_Ch0_Done
	resm 3, (xwa)
	ldto_berp A, 0xfb
	ld (ENCODER_0_LAST_VALUE:16), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, 2:i3
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch0_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch0_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MidiParam_ProcessChannel1:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld wa, 1:i3
	calr MidiChannel_GetParamByIndex
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	extz wa
	ld c, (ENCODER_1_LAST_VALUE:16)
	extz bc
	ld xde, 0x8f06
	calr MIDI_ComputeParamDelta
	lda xwa, (ENCODER_1_STATUS:16)
	bitm 3, (xwa)
	jr z, MidiParam_Ch1_Done
	resm 3, (xwa)
	ldto_berp A, 0xfb
	ld (ENCODER_1_LAST_VALUE:16), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, 5:i3
	call CPanel_EncoderDispatch
	cp hl, 0xffff
	jr z, MidiParam_Ch1_Done
	ld xwa, (xsp + 2)
	ld (xwa), l
	setm 7, (xwa + 1)

MidiParam_Ch1_Done:
	popw_erp 0xfa
	inc 4, xsp
	ret

MIDI_ComputeParamDelta:
	dec 8, xsp
	ld (xsp), xde
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cp hl, 2:i3
	jr le, MidiParam_DeltaTooSmall
	ld c, (xsp + 4)
	extz bc
	ld a, (xsp + 6)
	extz wa
	sub wa, bc
	pushw wa
	call Math_AbsInt16
	inc 2, xsp
	cp hl, 6:i3
	jr le, MidiParam_DeltaMedium
	ld xwa, (xsp)
	ld a, (xwa)
	and a, 0x3
	xor a, 0x3
	jr z, MidiParam_DeltaConfirmed
	ld xbc, (xsp)
	ld a, (xbc)
	and a, 0x3
	inc 1, a
	and a, 0x3
	andmi8 (xbc), 0xfc
	or (xbc), a
	jr MidiParam_DeltaClearActive

MidiParam_DeltaMedium:
	ld xwa, (xsp)
	bitm 2, (xwa)
	jr z, MidiParam_DeltaStartDebounce

MidiParam_DeltaConfirmed:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc
	resm 2, (xwa)
	setm 3, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaStartDebounce:
	ld xwa, (xsp)
	setm 2, (xwa)
	jr MidiParam_DeltaDone

MidiParam_DeltaTooSmall:
	ld xwa, (xsp)
	andmi8 (xwa), 0xfc

MidiParam_DeltaClearActive:
	ld xwa, (xsp)
	resm 2, (xwa)

MidiParam_DeltaDone:
	inc 8, xsp
	ret

Audio_UpdateLEDsAndChannels:
	calr Audio_InitChannelTimers
	orw (0x8f42:16), 2
	ret

MIDI_ProcessChangedChannels:
	cp (CURRENT_TITLE:16), 251
	ret z
	calr Audio_CheckAndFlagChanges
	ld wa, (0x8f3c:16)
	cpl wa
	and wa, (0x8f3a:16)
	jr z, MidiChanged_ProcessGroup2
	ld xbc, MIDI_ProcessChangedChannels_Data
	calr DispatchBitmaskHandlers
	ldw (0x8f3a:16), 0

MidiChanged_ProcessGroup2:
	ld wa, (0x8f40:16)
	cpl wa
	and wa, (0x8f3e:16)
	jr z, MidiChanged_ProcessGroup3
	ld xbc, MidiChanged_ProcessGroup2_Data
	calr DispatchBitmaskHandlers
	ldw (0x8f3e:16), 0

MidiChanged_ProcessGroup3:
	ld wa, (0x8f44:16)
	cpl wa
	and wa, (0x8f42:16)
	jr z, MidiChanged_ProcessGroup4
	ld xbc, MidiChanged_ProcessGroup3_Data
	calr DispatchBitmaskHandlers
	ldw (0x8f42:16), 0

MidiChanged_ProcessGroup4:
	ld wa, (0x8f48:16)
	cpl wa
	and wa, (0x8f46:16)
	ret z
	ld xbc, MidiChanged_ProcessGroup4_Data
	calr DispatchBitmaskHandlers
	ldw (0x8f46:16), 0
	ret

MidiChannel_DispatchChanged:
	cp (CURRENT_TITLE:16), 251
	ret z
	ld wa, (0x8f3c:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup2
	ld xbc, MidiChannel_DispatchChanged_Data
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup2:
	ld wa, (0x8f40:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup3
	ld xbc, MidiDispatch_CheckGroup2_Data
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup3:
	ld wa, (0x8f44:16)
	cp wa, 0:i3
	jr z, MidiDispatch_CheckGroup4
	ld xbc, MidiDispatch_CheckGroup3_Data
	calr DispatchBitmaskHandlers

MidiDispatch_CheckGroup4:
	ld wa, (0x8f48:16)
	cp wa, 0:i3
	jr z, MidiDispatch_UpdateLEDs
	ld xbc, MidiDispatch_CheckGroup4_Data
	calr DispatchBitmaskHandlers

MidiDispatch_UpdateLEDs:
	jrl CtrlPanel_UpdateLEDState

Audio_InitChannelTimers:
	ld (0x8f4c:16), 5
	ld (0x8f4e:16), 5
	ld (0x8f50:16), 5
	ld (0x8f52:16), 5
	ld (0x8f54:16), 5
	ld (0x8f56:16), 5
	ret

Audio_IncrementUpdateCounter:
	inc 1, (0x8f4a:16)
	ret

Audio_CheckAndFlagChanges:
	call GetDialEnableState
	cp l, (0x8f5e:16)
	jr z, AudioChange_CheckSelectionState
	orw (0x8f42:16), 64
	ld (0x8f5e:16), l

AudioChange_CheckSelectionState:
	call CtrlPanel_GetSelectionState
	cp l, (0x8f60:16)
	ret z
	cp l, 2:i3
	jr nz, AudioChange_UpdatePreviousSelect
	orw (0x8f44:16), 4

AudioChange_UpdatePreviousSelect:
	cp (0x8f60:16), 2
	jr nz, AudioChange_SetChannelFlag
	andw (0x8f44:16), 0xfffb

AudioChange_SetChannelFlag:
	orw (0x8f42:16), 4
	ld (0x8f60:16), l
	ret

DispatchBitmaskHandlers:
	dec 2, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), wa
	cpw (xiz), 0xffff
	jr z, BitmaskDispatch_Return

; Bitmask dispatch loop handler
BitmaskDispatch_LoopHandler:
	ld wa, (xsp + 4)
	and wa, (xiz)
	jr z, BitmaskDispatch_NextEntry
	ld xhl, (xiz + 2)
	call (xhl)

BitmaskDispatch_NextEntry:
	inc 6, xiz
	cpw (xiz), 0xffff
	jr nz, BitmaskDispatch_LoopHandler

BitmaskDispatch_Return:
	pop xiz
	inc 2, xsp
	ret


; This routine seems to set the LEDs of the control panel
; I'm not sure yet if this is initialization, or if it
; also serves to update the LEDs later on.
CtrlPanel_UpdateLEDState:
	dec 8, xsp
	pushw_erp 0xfa
	lda xwa, (ENCODER_STATE_BASE:16)
	ld (xsp + 2), xwa
	lda xwa, (0x8f28:16)
	ld (xsp + 6), xwa
	cp (CURRENT_TITLE:16), 247
	jr z, LEDUpdate_Cleanup
	ldib_erp 0xfb, 0

LEDUpdate_ProcessChannel:
	ldto_berp A, 0xfb
	extz wa
	ld xbc, (xsp + 2)
	ld	c, (xbc+wa)
	ldfr_berp C, 0xfa
	ld xbc, (xsp + 6)
	ld	c, (xbc+wa)
	cpb_erp C, 0xfa
	jr z, LEDUpdate_NextChannel
	ldto_berp C, 0xfa
	extz bc
	calr Set_LEDs
	ldto_berp E, 0xfb
	extz de
	ld xwa, (xsp + 6)
	ldto_berp C, 0xfa
	ld	(xwa+de), c

LEDUpdate_NextChannel:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr c, LEDUpdate_ProcessChannel

LEDUpdate_Cleanup:
	popw_erp 0xfa
	inc 8, xsp
	ret


Set_LEDs:
	; Input: WA: row of LEDs
	;         C: LED pattern
	ld e, a
	cp e, 0xf
	ret ugt
	lda xwa, (CPANEL_LEDS__ROW_AND_PATTERN_BYTES:16)
	extz de
	lda xhl, (Protocol_values_for_LED_rows:24)
	ld	e, (xhl+de)
	ld (xwa), e
	ld (xwa + 1), c
	calr LED_WriteToPanel
	ret

	.include "ui/led_panel_write.s"


SndParam_SetResBit0_Via028100:
	; --- Routine 1: call FCD437(0x028100), set/res bit 0 at (xwa) (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+4)
	cp	hl, 1:i3
	jr nz, SndParam028100_ResBit0
	setm	0, (xwa)
	jr t, SndParam028100_Done
SndParam028100_ResBit0:
	res	0, (xwa)
SndParam028100_Done:
	pop xiz
	ret
SndParam_SetResBit1_ViaRegs0100_0101:
	; --- Routine 2: 2x FCD437, set/res bit 1 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028100
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr z, SndParam028101_SetBit1
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, SndParam028101_ResBit1
SndParam028101_SetBit1:
	setm	1, (xiz+4)
	jr t, SndParam028101_Done
SndParam028101_ResBit1:
	res	1, (xiz+4)
SndParam028101_Done:
	pop xiz
	ret
SndParam_SetResBit2_ViaRegs0101_0102:
	; --- Routine 3: 2x FCD437, set/res bit 2 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr z, SndParam028102_SetBit2
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, SndParam028102_ResBit2
SndParam028102_SetBit2:
	setm	2, (xiz+4)
	jr t, SndParam028102_Done
SndParam028102_ResBit2:
	res	2, (xiz+4)
SndParam028102_Done:
	pop xiz
	ret


SndParam_SetResBit3_ViaRegs0101_0102:
	; --- Routine 1: 2x FCD437, set/res bit 3 at (xiz+4) (41 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028101
	call SndParam_LookupReadOnly
	cp	hl, 3:i3
	jr z, SndParam028102_SetBit3
	ld xwa, 0x00028102
	call SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr nz, SndParam028102_ResBit3
SndParam028102_SetBit3:
	setm	3, (xiz+4)
	jr t, SndParam028102_Done2
SndParam028102_ResBit3:
	res	3, (xiz+4)
SndParam028102_Done2:
	pop xiz
	ret
SndParam_SetResBit3_Via4002:
	; --- Routine 2: FCD437(0x4002), set/res bit 3 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00004002
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cp	hl, 0:i3
	jr z, SndParam4002_ResBit3
	setm	3, (xwa)
	jr t, SndParam4002_Done
SndParam4002_ResBit3:
	res	3, (xwa)
SndParam4002_Done:
	pop xiz
	ret
SndParam_SetResBit4_Via4004:
	; --- Routine 3: FCD437(0x4004), set/res bit 4 at (xwa) via xiz+6 (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00004004
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+6)
	cp	hl, 0:i3
	jr z, SndParam4004_ResBit4
	setm	4, (xwa)
	jr t, SndParam4004_Done
SndParam4004_ResBit4:
	res	4, (xwa)
SndParam4004_Done:
	pop xiz
	ret


SndParam_TableLookup_Via4100:
	; --- Routine 1: FCD437(0x4100), table lookup at 0xeda626, nibble merge (39 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00004100
	call SndParam_LookupReadOnly
	lda xwa, (AudioCtl_SmallTables:24)
	ld	a, (xwa+hl)
	and a, 0x07
	sla	a, 4
	andmi8	(xiz+10), 143
	or	(xiz+10), a
	pop xiz
	ret
SndParam_SetResBit1_ViaPartCC5E:
	; --- Routine 2: F9945E+FCD4F7(0x5e), set/res bit 1 at (xwa) via xiz+6 (37 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005e
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC5E_ResBit1
	setm	1, (xwa)
	jr t, SndParamCC5E_Done
SndParamCC5E_ResBit1:
	res	1, (xwa)
SndParamCC5E_Done:
	pop xiz
	ret


SndParam_SetResBit2_ViaPartCC5D:
	; --- Routine 1: 2x F9945E+FCD4F7(0x5d), set/res bit 2 at (xiz+6) (55 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cp	hl, 0:i3
	jr z, SndParamCC5D_ResBit2
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x005d
	call SndParam_LookupViaEncode
	cp hl, 0xffff
	jr nz, SndParamCC5D_SetBit2
SndParamCC5D_ResBit2:
	resm	2, (xiz+6)
	jr t, SndParamCC5D_Done
SndParamCC5D_SetBit2:
	set	2, (xiz+6)
SndParamCC5D_Done:
	pop xiz
	ret
SndParam_SetResBit0_ViaPartCC40:
	; --- Routine 2: F9945E+FCD4F7(0x40), cp 0x7f, set/res bit 0 at (xwa) (37 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw bc, 0x0040
	call SndParam_LookupViaEncode
	lda	xwa, (xiz+6)
	cp hl, 0x007f
	jr nz, SndParamCC40_ResBit0
	setm	0, (xwa)
	jr t, SndParamCC40_Done
SndParamCC40_ResBit0:
	res	0, (xwa)
SndParamCC40_Done:
	pop xiz
	ret
SndParam_GuardedNibbleSet_ViaReg0103:
	; --- Routine 3: complex bit checks, and (xiz+0x0e), set 0 in A (59 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	bit	2, (1054:16)
	jr nz, MidiCtrl_PopIzRet
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr nz, MidiCtrl_PopIzRet
	andmi8	(xiz+14), 240
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jr z, MidiCtrl_PopIzRet
	ld	xwa, 1:i3
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, MidiCtrl_PopIzRet
	lda	xbc, (xiz+14)
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
MidiCtrl_PopIzRet:
	pop xiz
	ret
SndParam_SetResBit0_Via028103:
	; --- Routine 4: FCD437(0x028103), set/res bit 0 at (xwa) via xiz+0x0d (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+13)
	cp	hl, 1:i3
	jr nz, SndParam028103_ResBit0
	setm	0, (xwa)
	jr t, SndParam028103_Done
SndParam028103_ResBit0:
	res	0, (xwa)
SndParam028103_Done:
	pop xiz
	ret
SndParam_SetResBit5_Via028080:
	; --- Routine 5: FCD437(0x028080), set/res bit 5 at (xwa) via xiz+3 (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00028080
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cp	hl, 0:i3
	jr nz, SndParam028080_SetBit5
	resm	5, (xwa)
	jr t, SndParam028080_Done
SndParam028080_SetBit5:
	set	5, (xwa)
SndParam028080_Done:
	pop xiz
	ret


SndParam_VoiceEntryLookup_ViaReg8000:
	; --- Routine 1: stack frame, 3x FCD437 lookup, nibble merge (91 bytes) ---
	dec 6, xsp
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld (xsp+6), 0x48
	ld xwa, 0x00028000
	call SndParam_LookupReadOnly
	ld (xsp+7), l
	ld xwa, 0x00028001
	call SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld (xwa+4), l
	call SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	cp (xwa), 0x0e
	jr nc, SndParam028000_GetBankBit
	ld xwa, 0x00028002
	call SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	jr t, SndParam028000_LookupAndMerge
SndParam028000_GetBankBit:
	ld a, (xwa+1)
	and a, 0x03
	extz wa
SndParam028000_LookupAndMerge:
	call CtrlPanel_LookupIndicatorEntry
	and l, 0x0f
	andmi8	(xiz+3), 240
	or (xiz+3), l
	pop xiz
	inc 6, xsp
	ret
SndParam_SetResBit7_Via4200:
	; --- Routine 2: FCD437(0x4200), set/res bit 7 at (xwa) via xiz+0x0a (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00004200
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+10)
	cp	hl, 1:i3
	jr nz, SndParam4200_ResBit7
	setm	7, (xwa)
	jr t, SndParam4200_Done
SndParam4200_ResBit7:
	res	7, (xwa)
SndParam4200_Done:
	pop xiz
	ret
SndParam_MaskShiftMerge_8F58:
	; --- Routine 3: read (0x8f58), mask+shift, merge into (0x8f1c) (20 bytes) ---
	ld	a, (0x8f58:16)
	and a, 0x07
	sla	a, 4
	and	(0x8f1c:16), 143
	or	(0x8f1c:16), a
	ret
SndParam_DecrLookup_Via0300:
	; --- Routine 4: FCD437(0x300), decrement+mask+lookup via FC7C23 (40 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00000300
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr nz, SndParam0300_DecrAndMask
	ld l, 0x00:opc
	jr t, SndParam0300_StoreLookup
SndParam0300_DecrAndMask:
	dec 1, l
	and l, 0x07
	extz	hl
	ld	wa, hl
	call CtrlPanel_LookupIndicatorEntry
SndParam0300_StoreLookup:
	ld (xiz+9), l
	pop xiz
	ret


SndParam_SetResBit4_Via0400:
	; --- Routine 1: call FCD437, set/res bit 4 based on HL (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x00000400
	call SndParam_LookupReadOnly
	lda	xwa, (xiz+3)
	cp	hl, 1:i3
	jr nz, SndParam0400_ResBit4
	setm	4, (xwa)
	jr t, SndParam0400_Done
SndParam0400_ResBit4:
	res	4, (xwa)
SndParam0400_Done:
	pop xiz
	ret
SndParam_SetResBit7_ViaSelection:
	; --- Routine 2: call F99439, 3-way cp HL, set/res bit 7 (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call CtrlPanel_GetSelectionState
	cp	hl, 2:i3
	jr z, CtrlPanel_SetResBit7_Ret
	cp	hl, 1:i3
	jr z, SndParamSelect_SetBit7
	cp	hl, 0:i3
	jr nz, CtrlPanel_SetResBit7_Ret
	resm	7, (xiz)
	jr t, CtrlPanel_SetResBit7_Ret
SndParamSelect_SetBit7:
	set	7, (xiz)
CtrlPanel_SetResBit7_Ret:
	pop xiz
	ret
SndParam_SetResBit7_ViaF9A541:
	; --- Routine 3: call F9A541, set/res bit 7 based on HL (24 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call GetDialEnableState
	lda	xwa, (xiz+4)
	cp	hl, 0:i3
	jr z, SndParamF9A541_ResBit7
	setm	7, (xwa)
	jr t, SndParamF9A541_Done
SndParamF9A541_ResBit7:
	res	7, (xwa)
SndParamF9A541_Done:
	pop xiz
	ret
ExtData_VoiceParam_DispatchBytecode:
	push	xiz
	lda_d16	xiz, (ENCODER_STATE_BASE)
	lda	xbc, (xiz+0x2)
	resm	7, (xbc)
	resm	1, (xiz)
	resm	2, (xiz)
	resm	4, (xiz)
	lda	xhl, (xiz+0xa)
	resm	3, (xhl)
	lda	xde, (xiz+0x6)
	resm	6, (xde)
	resm	7, (xde)
	lda	xiy, (xiz+0xb)
	resm	0, (xiy)
	resm	1, (xiy)
	resm	2, (xiy)
	resm	3, (xiy)
	ldb_d8	a, (CURRENT_MODE)
	extz	wa
	dec	2, wa
	cp	wa, 0:i3
	jr	lt, ExtData_VoiceParam_DispatchBytecode_Epilogue2
	cp	wa, 16
	jr	gt, ExtData_VoiceParam_DispatchBytecode_Epilogue2
	add	wa, wa
	lda	xix, (ExtData_VoiceParam_DispatchBytecode_CaseTable:24)
	ld	wa, (xix+wa)
	lda	xix, (ExtData_VoiceParam_DispatchBytecode_Code:24)
	jp	t, (xix+wa)
ExtData_VoiceParam_DispatchBytecode_Code:
	setm	7, (xbc)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeCmp: MD_CMP: sets bit 1 of LED row 0 (0x8F18)
ExtData_VoiceParam_DispatchBytecode_ModeCmp:
	ld	a, 1:opc
	jr	ExtData_VoiceParam_DispatchBytecode_Join
; ExtData_VoiceParam_DispatchBytecode_ModeSndArg: MD_SND_ARG: sets bit 2 of LED row 0 (0x8F18)
ExtData_VoiceParam_DispatchBytecode_ModeSndArg:
	ld	a, 2:opc
	jr	ExtData_VoiceParam_DispatchBytecode_Join
; ExtData_VoiceParam_DispatchBytecode_ModeSeq: MD_SEQ / MD_SEQ_EDIT / MD_SEQ_STEP: sets bit 7 of LED row 6 (0x8F1E)
ExtData_VoiceParam_DispatchBytecode_ModeSeq:	; cases 8, 12, 13
	setm	7, (xde)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeSeqReal: MD_SEQ_REAL: sets bit 7 of LED row 6, and bit 6 too when (0x26FC) =
;   1
ExtData_VoiceParam_DispatchBytecode_ModeSeqReal:
	ld	xwa, xde
	setm	7, (xde)
	cp	(0x26fc:16), 1
	jr	nz, ExtData_VoiceParam_DispatchBytecode_Epilogue2
	setm	6, (xwa)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeSeqErec: MD_SEQ_EREC: sets bit 6 of LED row 6 (0x8F1E)
ExtData_VoiceParam_DispatchBytecode_ModeSeqErec:
	setm	6, (xde)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeSound: MD_SOUND / MD_SOUNDEDIT: sets bit 0 of LED row 11 (0x8F23)
ExtData_VoiceParam_DispatchBytecode_ModeSound:	; cases 2, 3
	setm	0, (xiy)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeMidi: MD_MIDI: sets bit 2 of LED row 11 (0x8F23)
ExtData_VoiceParam_DispatchBytecode_ModeMidi:
	setm	2, (xiy)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeControl: MD_CONTROL: sets bit 1 of LED row 11 (0x8F23)
ExtData_VoiceParam_DispatchBytecode_ModeControl:
	setm	1, (xiy)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeDisk: MD_DISK: sets bit 3 of LED row 11 (0x8F23)
ExtData_VoiceParam_DispatchBytecode_ModeDisk:
	setm	3, (xiy)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeEntertainer: MD_ENTERTAINER: sets bit 3 of LED row 10 (0x8F22)
ExtData_VoiceParam_DispatchBytecode_ModeEntertainer:
	setm	3, (xhl)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue2
; ExtData_VoiceParam_DispatchBytecode_ModeOtp: MD_OTP: sets bit 4 of LED row 0 (0x8F18)
ExtData_VoiceParam_DispatchBytecode_ModeOtp:
	ld	a, 4:opc
ExtData_VoiceParam_DispatchBytecode_Join:
	scf
	stcf	a, (xiz)
ExtData_VoiceParam_DispatchBytecode_Epilogue2:
	pop	xiz
	ret
MidiChanged_ProcessGroup3_Data_Target7:
	lda_d16	xwa, (ENCODER_STATE_BASE)
	cp	(0x3390:16), 0
	jr	z, ExtData_VoiceParam_DispatchBytecode_Entry
	setm	3, (xwa)
	ret
ExtData_VoiceParam_DispatchBytecode_Entry:
	res	3, (xwa)
	ret
MidiChanged_ProcessGroup3_Data_Target8:
	lda	xwa, (0x8f1e:16)
	res	5, (xwa)
	bit	0, (10405:16)
	ret	z
	ld	c, (CURRENT_MODE:16)
	cp	c, 13
	ret	z
	cp	c, 12
	ret	z
	cp	c, 11
	ret	z
	cp	c, 9
	ret	z
	cp	c, 8
	ret	z
	.byte 0xb0, 0xbd
	ret
MIDI_ProcessChangedChannels_Data_Target0:
	lda	xsp, (xsp-10)
	push	xiz
	lda	xwa, (ENCODER_STATE_BASE:16)
	ld	(xsp+4), xwa
	ld	(xwa+7), 0
	ld	xwa, (xsp+4)
	ld	(xwa+8), 0
	and	(xwa+12), 252
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ld	bc, 0:i3
	call	SndParam_LookupViaEncode
	ld	(xsp+11), l
	call	GetCurrentPartSelect
	extz	hl
	ld	wa, hl
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	ld	(xsp+12), l
	call	GetCurrentPartSelect
	lda	xwa, (xsp+8)
	ld	(xwa+2), l
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+8)
	cp	(xwa), 7
	jr	ugt, ExtData_VoiceParam_DispatchBytecode_Entry_Code_Entry
	ld	a, (xwa)
	extz	wa
	ld	xiz, 7:i3
	jr	ExtData_VoiceParam_DispatchBytecode_Entry_Code_Join
ExtData_VoiceParam_DispatchBytecode_Entry_Code_Entry:
	cp	(xwa), 15
	jr	ugt, MIDI_ProcessChangedChannels_Data_Target0_Entry
	ld	a, (xwa)
	dec	8, a
	extz	wa
	ld	xiz, 8
ExtData_VoiceParam_DispatchBytecode_Entry_Code_Join:
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	add	xwa, xiz
	ld	(xwa), l
	jr	ExtData_VoiceParam_DispatchBytecode_Entry_Code_Epilogue
MIDI_ProcessChangedChannels_Data_Target0_Entry:
	.byte 0x80
	push	xsp
	scf
	jr	ugt, ExtData_VoiceParam_DispatchBytecode_Entry_Code_Skip
	ld	a, (xwa)
	sub	a, 16
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	xwa, (xsp+4)
	and	l, 3
	and	(xwa+12), 252
	or	(xwa+12), l
	jr	ExtData_VoiceParam_DispatchBytecode_Entry_Code_Epilogue
ExtData_VoiceParam_DispatchBytecode_Entry_Code_Skip:
	ld	xwa, (xsp+4)
	ld	(xwa+7), 1
ExtData_VoiceParam_DispatchBytecode_Entry_Code_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret
MidiChanged_ProcessGroup2_Data_Target0:
	dec	6, xsp
	push	xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	res	0, (xiz)
	ld	(xiz+1), 0
	and	(xiz+2), 128
	ld	xwa, 0x028000
	call	SndParam_LookupReadOnly
	ld	(xsp+7), l
	ld	xwa, 0x028001
	call	SndParam_LookupReadOnly
	lda	xwa, (xsp+4)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	lda	xwa, (xsp+4)
	cp	(xwa), 6
	jr	ugt, ExtData_VoiceParam_DispatchBytecode_Entry2
	ld	a, (xwa)
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	res	7, l
	and	(xiz+2), 128
	or	(xiz+2), l
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue
ExtData_VoiceParam_DispatchBytecode_Entry2:
	cp	(xwa), 14
	jr	ugt, ExtData_VoiceParam_DispatchBytecode_Entry3
	ld	a, (xwa)
	dec	7, a
	extz	wa
	call	CtrlPanel_LookupIndicatorEntry
	ld	(xiz+1), l
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue
ExtData_VoiceParam_DispatchBytecode_Entry3:
	cp	(xwa), 15
	jr	nz, MidiChanged_ProcessGroup2_Data_Target0_Skip
	set	0, (xiz)
	jr	ExtData_VoiceParam_DispatchBytecode_Epilogue
MidiChanged_ProcessGroup2_Data_Target0_Skip:
	lda	xbc, (xiz+2)
	ld	a, (xbc)
	and	a, 128
	set	0, a
	ld	(xbc), a
ExtData_VoiceParam_DispatchBytecode_Epilogue:
	pop	xiz
	inc	6, xsp
	ret
MIDI_ProcessChangedChannels_Data_Target1:
	push	xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	call	GetCurrentPartSelect
	lda	xbc, (xiz+10)
	ld	a, (xbc)
	cp	l, 2:i3
	jr	z, ExtData_VoiceParam_DispatchBytecode_Skip2
	cp	l, 1:i3
	jr	z, ExtData_VoiceParam_DispatchBytecode_Skip
	cp	l, 0:i3
	jr	nz, ExtData_VoiceParam_DispatchBytecode_Entry4
	and	a, 248
	set	2, a
	ld	(xbc), a
	jr	ExtData_VoiceParam_DispatchBytecode_Entry4_Code_Epilogue
ExtData_VoiceParam_DispatchBytecode_Skip:
	and	a, 248
	set	1, a
	ld	(xbc), a
	jr	ExtData_VoiceParam_DispatchBytecode_Entry4_Code_Epilogue
ExtData_VoiceParam_DispatchBytecode_Skip2:
	and	a, 248
	set	0, a
	ld	(xbc), a
	jr	ExtData_VoiceParam_DispatchBytecode_Entry4_Code_Epilogue
ExtData_VoiceParam_DispatchBytecode_Entry4:
	.byte 0x81
	push	xix
	swi	0
ExtData_VoiceParam_DispatchBytecode_Entry4_Code_Epilogue:
	pop	xiz
	ret
MidiChanged_ProcessGroup3_Data_Target9:
	push	xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	xwa, 0x40c0
	call	SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr	nz, MidiChanged_ProcessGroup3_Data_Target9_Entry
	set	5, (xiz)
	jr	MidiChanged_ProcessGroup3_Data_Target9_Epilogue
MidiChanged_ProcessGroup3_Data_Target9_Entry:
	res	5, (xiz)
MidiChanged_ProcessGroup3_Data_Target9_Epilogue:
	pop	xiz
	ret
CtrlPanel_SetResBit6_ViaLookup:
	; --- Sub 1: set/res bit 6 of (XIZ) via FCD437 lookup (26 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x000040c1
	call SndParam_LookupReadOnly
	cp	hl, 1:i3
	jr nz, CtrlPanel_ResBit6
	setm	6, (xiz)
	jr t, CtrlPanel_Bit6Done
CtrlPanel_ResBit6:
	res	6, (xiz)
CtrlPanel_Bit6Done:
	pop xiz
	ret
CtrlPanel_MultiWayBitManip_ViaE0:
	; --- Sub 2: multi-way HL compare, and/set bits at (XBC+0x0d) (74 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld xwa, 0x000040e0
	call SndParam_LookupReadOnly
	lda	xbc, (xiz+13)
	ld a, (xbc)
	cp hl, 0x0058
	jr z, CtrlPanel_SetBit2
	cp hl, 0x004c
	jr z, CtrlPanel_SetBit2
	cp hl, 0x0040
	jr z, CtrlPanel_ClearBits1_2
	cp hl, 0x0034
	jr z, CtrlPanel_SetBit1
	cp hl, 0x0028
	jr nz, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit1:
	and a, 0xf9
	set 1, a
	ld (xbc), a
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_ClearBits1_2:
	andmi8	(xbc), 249
	jr t, CtrlPanel_BitManip_Ret
CtrlPanel_SetBit2:
	and a, 0xf9
	set 2, a
	ld (xbc), a
CtrlPanel_BitManip_Ret:
	pop xiz
	ret
CtrlPanel_SyncBit0_From8F5C:
	; --- Sub 3: set/res bit 0 at (0x8f1d) based on bit 0 of (0x8f5c) (16 bytes) ---
	lda	xwa, (0x8f1d:16)
	bit	0, (0x8f5c:16)
	jr z, CtrlPanel_ResBit0_8F5C
	setm	0, (xwa)
	ret
CtrlPanel_ResBit0_8F5C:
	resm	0, (xwa)
	ret
CtrlPanel_SetBit3_OnStyleD0D3:
	; --- Sub 4: conditionally set bit 3 at (0x8f25) based on (0x8d38) (33 bytes) ---
	lda	xwa, (0x8f25:16)
	resm	3, (xwa)
	ld	c, (ACTIVE_TITLE:16)
	cp c, 0xd3
	jr z, CtrlPanel_SetBit3
	cp c, 0xd2
	jr z, CtrlPanel_SetBit3
	cp c, 0xd1
	jr z, CtrlPanel_SetBit3
	cp c, 0xd0
	ret nz
CtrlPanel_SetBit3:
	setm	3, (xwa)
	ret
CtrlPanel_SetResBit0_ViaLookup4:
	; --- Sub 5: set/res bit 0 at (XIZ+4) via FC7C23 + (0x8f54) lookup (34 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f54:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup4_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4_Done
CtrlPanelLookup4_ResBit0:
	res	0, (xwa)
CtrlPanelLookup4_Done:
	pop xiz
	ret
CtrlPanel_SetResBit1_ViaLookup56:
	; --- Sub 6: set/res bit 1 at (XIZ+4) via FC7C23 + (0x8f56) lookup (34 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f56:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup56_ResBit1
	setm	1, (xwa)
	jr t, CtrlPanelLookup56_Done
CtrlPanelLookup56_ResBit1:
	res	1, (xwa)
CtrlPanelLookup56_Done:
	pop xiz
	ret
CtrlPanel_SetResBit2_ViaLookup50:
	; --- Sub 7: set/res bit 2 at (XIZ+4) via FC7C23 + (0x8f50) lookup (34 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f50:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup50_ResBit2
	setm	2, (xwa)
	jr t, CtrlPanelLookup50_Done
CtrlPanelLookup50_ResBit2:
	res	2, (xwa)
CtrlPanelLookup50_Done:
	pop xiz
	ret
CtrlPanel_SetResBit3_ViaLookup52:
	; --- Sub 8: set/res bit 3 at (XIZ+4) via FC7C23 + (0x8f52) lookup (34 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f52:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+4)
	cp	l, 0:i3
	jr z, CtrlPanelLookup52_ResBit3
	setm	3, (xwa)
	jr t, CtrlPanelLookup52_Done
CtrlPanelLookup52_ResBit3:
	res	3, (xwa)
CtrlPanelLookup52_Done:
	pop xiz
	ret
CtrlPanel_GuardedNibbleSet_8F4E:
	; --- Sub 9: guarded nibble set/res at (XIZ+0x0e) via (0x8f4e) lookup (76 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	bit	2, (1054:16)
	jr nz, CtrlPanel_BitOp_Cleanup
	ld xwa, 0x00028103
	call SndParam_LookupReadOnly
	cp	hl, 0:i3
	jr z, CtrlPanelGuard_PassedCheck
	cp	(CURRENT_MODE:16), 19
	jr z, CtrlPanelGuard_PassedCheck
	cp	(0x7f0b:16), 0
	jr z, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_PassedCheck:
	ld	a, (0x8f4e:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+14)
	cp	l, 0:i3
	jr z, CtrlPanelGuard_ClearNibble
	ld c, (xwa)
	and c, 0xf0
	set 0, c
	ld (xwa), c
	jr t, CtrlPanel_BitOp_Cleanup
CtrlPanelGuard_ClearNibble:
	.byte 0x80
	push	xix
	.byte 0xf0
CtrlPanel_BitOp_Cleanup:
	pop xiz
	ret
CtrlPanel_SetResBit0_ViaLookup4C:
	; --- Sub 10: set/res bit 0 at (XIZ+0x0d) via FC7C23 + (0x8f4c) lookup (34 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	lda	xwa, (xiz+13)
	cp	l, 0:i3
	jr z, CtrlPanelLookup4C_ResBit0
	setm	0, (xwa)
	jr t, CtrlPanelLookup4C_Done
CtrlPanelLookup4C_ResBit0:
	res	0, (xwa)
CtrlPanelLookup4C_Done:
	pop xiz
	ret
CtrlPanel_SetResBit7_ViaLookup4C:
	; --- Sub 11: set/res bit 7 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit7_Res
	setm	7, (xiz)
	jr t, CtrlPanelBit7_Done
CtrlPanelBit7_Res:
	res	7, (xiz)
CtrlPanelBit7_Done:
	pop xiz
	ret
CtrlPanel_SetResBit5_ViaLookup4C:
	; --- Sub 12: set/res bit 5 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit5_Res
	setm	5, (xiz)
	jr t, CtrlPanelBit5_Done
CtrlPanelBit5_Res:
	res	5, (xiz)
CtrlPanelBit5_Done:
	pop xiz
	ret
CtrlPanel_SetResBit6_ViaLookup4C:
	; --- Sub 13: set/res bit 6 of (XIZ) via FC7C23 + (0x8f4c) lookup (29 bytes) ---
	push xiz
	lda	xiz, (ENCODER_STATE_BASE:16)
	ld	a, (0x8f4c:16)
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	and	l, (0x8f4a:16)
	jr z, CtrlPanelBit6_Res
	setm	6, (xiz)
	jr t, CtrlPanelBit6_Done
CtrlPanelBit6_Res:
	res	6, (xiz)
CtrlPanelBit6_Done:
	pop xiz
	ret


; ============================================================================
; CtrlPanel_SetIndicatorBit - Set a control panel LED indicator bit
; ============================================================================
; Input:  A = key code (upper nibble=group, lower nibble=bit index)
; Output: ORs bitmask into panel LED register (36666/36670/36674/36678)
; Looks up bitmask from table at 0xeda66c.
; ============================================================================
CtrlPanel_SetIndicatorBit:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_SetIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetIndicator_Group2
	cpib_erp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA
	or (0x8f3a:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group2:
	or (0x8f3e:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group3:
	or (0x8f42:16), hl
	jr CtrlPanel_PopRetFA

CtrlPanel_SetIndicator_Group4:
	or (0x8f46:16), hl

CtrlPanel_PopRetFA:
	popw_erp 0xfa
	ret

CtrlPanel_IndicatorDispatch:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	cp_erpb 0xfb, 0x60
	jr z, CtrlPanel_DispIndicator_Group4
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_DispIndicator_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_DispIndicator_Group2
	cpib_erp 0xfb, 0
	jr nz, CtrlPanel_PopRetFA2
	or (0x8f3c:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group2:
	or (0x8f40:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group3:
	or (0x8f44:16), hl
	jr CtrlPanel_PopRetFA2

CtrlPanel_DispIndicator_Group4:
	or (0x8f48:16), hl

CtrlPanel_PopRetFA2:
	popw_erp 0xfa
	ret

CtrlPanel_SetIndicatorLED:
	pushw_erp 0xfa
	ld c, a
	and c, 0xf0
	ldfr_berp C, 0xfb
	and a, 0xf
	extz wa
	call CtrlPanel_LookupIndicatorEntry
	ld wa, hl
	cpl wa
	cp_erpb 0xfb, 0x40
	jr z, CtrlPanel_SetLED_Group3
	cp_erpb 0xfb, 0x20
	jr z, CtrlPanel_SetLED_Group2
	cpib_erp 0xfb, 0
	jr nz, MidiChOutState_Return
	and (0x8f3c:16), wa
	or (0x8f3a:16), hl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group2:
	and (0x8f40:16), wa
	or (0x8f3e:16), hl
	jr MidiChOutState_Return

CtrlPanel_SetLED_Group3:
	and (0x8f44:16), wa
	or (0x8f42:16), hl

MidiChOutState_Return:
	popw_erp 0xfa
	ret

MidiChannel_ProcessOutputState:
	push xiz
	lda xiz, (ENCODER_STATE_BASE:16)
	calr MidiChOut_DetectChanges
	lda xde, (xiz + 14)
	ld c, (0x8e76:16)
	bit 2, (1054:16)
	jr nz, MidiChOut_CheckHWState
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	ld (0x8e76:16), a
	jr MidiChOut_ClearLowNibble

MidiChOut_CheckHWState:
	ld l, (1046:16)
	ld a, (1045:16)
	and a, 0x60
	jr nz, MidiChOut_CheckBit1Clear
	set 1, (0x8e76:16)
	ld a, (1075:16)
	cp a, 6:i3
	jr z, MidiChOut_Mode6or3_Mask7
	cp a, 3:i3
	jr nz, MidiChOut_OtherMode_Mask3

MidiChOut_Mode6or3_Mask7:
	and l, 0x7
	ld xwa, MidiChOut_Mode6or3_Mask7_Data
	jr MidiChOut_TableLookup

MidiChOut_OtherMode_Mask3:
	and l, 0x3
	ld xwa, MidiChOut_OtherMode_Mask3_Data

MidiChOut_TableLookup:
	extz hl
	ld	a, (xwa+hl)
	and a, 0xf
	andmi8 (xde), 0xf0
	or (xde), a
	jr MidiChannel_CleanupRet

MidiChOut_CheckBit1Clear:
	ld a, c
	bit 1, c
	jr z, MidiChannel_CleanupRet
	res 1, a
	ld (0x8e76:16), a

MidiChOut_ClearLowNibble:
	andmi8 (xde), 0xf0

MidiChannel_CleanupRet:
	pop xiz
	ret

MidiChOut_DetectChanges:
	bit 2, (1054:16)
	ret nz
	ld a, (1056:16)
	xor a, (0x347b:16)
	bit 2, a
	ret z
	orw (0x8f3e:16), 4
	ldmm8 0x347b, 1056
	ret

MidiChannel_ScanPending:
	push xiz
	lda xiz, (ENCODER_STATE_BASE:16)
	ld wa, (0x8f40:16)
	bit 2, wa
	jr nz, MidiScan_PopIzRet
	ld a, (0x8f4a:16)
	and a, 0x3
	jr nz, MidiScan_PopIzRet
	bit 2, (1054:16)
	jr nz, MidiScan_PopIzRet
	bit 2, (0x28a7:16)
	jr nz, MidiScan_AltPathCheck
	ld xwa, 0x28103
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 14)
	cp hl, 1:i3
	jr nz, MidiScan_CheckBit2InAddr1057
	ld wa, (1039:16)
	bit 6, wa
	jr nz, MidiScan_ClearAndReturn
	ld a, (xbc)
	and a, 0xf0
	set 0, a
	ld (xbc), a
	jr MidiScan_PopIzRet

MidiScan_CheckBit2InAddr1057:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, MidiScan_PopIzRet

MidiScan_ClearAndReturn:
	andmi8 (xbc), 0xf0
	jr MidiScan_PopIzRet

MidiScan_AltPathCheck:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, MidiScan_PopIzRet
	andmi8 (xiz + 14), 0xf0

MidiScan_PopIzRet:
	pop xiz
	ret

; ============================================================================
; UIState_UpdateControlBits - Update UI state control bit flags
; ============================================================================
; Input:  Control parameters from caller
; Output: Updated control bit state
; Modifies the UI state control flags that govern which UI elements are
; active and which input modes are enabled.
; ============================================================================
UIState_UpdateControlBits:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 5:i3
	jr	z, UIState_UpdateControlBits_Entry2
	cp	a, 4:i3
	jr	z, UIState_UpdateControlBits_Entry
	cp	a, 0:i3
	ret	nz
	orw	(0x8f3a:16), 0x69
	ret
UIState_UpdateControlBits_Entry:
	orw	(0x8f3a:16), 0x28
	ret
UIState_UpdateControlBits_Entry2:
	orw	(0x8f3a:16), 0x40
	ret
UIState_SwitchOnDisplayMode:
	; --- Switch on A = (0xc07d): or bits into (0x8f3a)/(0x8f42) (53 bytes) ---
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 4:i3
	jr z, UIState_Mode4
	cp	a, 3:i3
	jr z, UIState_Mode3
	cp	a, 1:i3
	jr z, UIState_Mode0or1
	cp	a, 0:i3
	jr z, UIState_Mode0or1
	cp a, 0x10
	ret nz
	orw	(0x8f3a:16), 107
	ret
UIState_Mode0or1:
	orw	(0x8f3a:16), 111
	ret
UIState_Mode3:
	orw	(0x8f42:16), 512
	ret
UIState_Mode4:
	orw	(0x8f42:16), 0x8000
	ret


UIState_ProcessExtendedMode:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 7:i3
	ret	gt
	add	wa, wa
	lda	xix, (UIState_ProcessExtendedMode_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (UIState_ProcessExtendedMode_Cases:24)
	jp	t, (xix+wa)
UIState_ProcessExtendedMode_Cases:	; the switch's base: case k is at +UIState_ProcessExtendedMode_CaseTable[k]
	orw	(36670:16), 515
	ret
UIState_ProcessExtendedMode_Case5:	; cases 5, 6
	orw	(36670:16), 252
	ret
UIState_ProcessExtendedMode_Case3:
	ld	xwa, 0x028080
	call	SndParam_LookupReadOnly
	cp	l, 0:i3
	jr	z, UIState_ProcessExtendedMode_Skip
	ld	(0xffc8:24), l
UIState_ProcessExtendedMode_Skip:
	orw	(36670:16), 256
	ret
UIState_ProcessExtendedMode_Case4:
	orw	(36674:16), 16
	ret
UIState_ProcessExtendedMode_Case7:
	orw	(36670:16), 512
UIState_ProcessExtendedMode_Case1:	; cases 1, 2
	ret
UIStateEvt_NullHandler:
	ret
UIState_SwitchForMidiFlags:
	; --- Switch on A = (0xc07d): or bits into (0x8f42) (51 bytes) ---
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp a, 0x14
	jr z, UIState_MidiMode14
	cp	a, 4:i3
	jr z, UIState_MidiMode4
	cp a, 0x3f
	jr z, UIState_MidiMode3F
	cp	a, 6:i3
	ret nz
UIState_MidiMode6:
	orw	(0x8f42:16), 1024
	ret
UIState_MidiMode3F:
	orw	(0x8f42:16), 2048
	ret
UIState_MidiMode4:
	orw	(0x8f42:16), 2
	ret
UIState_MidiMode14:
	orw	(0x8f42:16), 4096
	ret
UIState_NullReturn:
	ret


UIState_ProcessAltMode:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 11
	jr	z, UIState_ProcessAltMode_Entry2
	cp	a, 3:i3
	jr	z, UIState_ProcessAltMode_Entry
	cp	a, 1:i3
	ret	nz
	orw	(0x8f42:16), 0x3
	ret
UIState_ProcessAltMode_Entry:
	orw	(0x8f42:16), 0x8
	ret
UIState_ProcessAltMode_Entry2:
	orw	(0x8f42:16), 0x6000
	ret
UIState_ProcessSimpleMode:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 1:i3
	ret	nz
	orw	(0x8f3a:16), 0x90
	ret

CtrlPanel_LookupIndicatorEntry:
	extz wa
	sla wa, 2
	lda xbc, (CtrlPanel_LookupIndicatorEntry_Data:24)
	ld	xhl, (xbc+wa)
	ret

Util_FindLowestSetBit:
	ld hl, 0:i3
	or xwa, xwa
	ret z
	bit 0, wa
	ret nz

FindBit_ShiftLoop:
	srl xwa, 1
	inc 1, hl
	bit 0, wa
	jr z, FindBit_ShiftLoop
	ret

Audio_InitAllDefaults:
	ld (0xc039:16), 255
	ld (SWBTWR_EVENT_QUEUE:16), 255
	ldw (0x90de:16), 0
	ldw (0x90e0:16), 0
	ld (0xbf39:16), 255
	ldw (0x90e2:16), 0
	ldw (0x9133:16), 0
	ld (0x90fb:16), 255
	ld (0x91ad:16), 255
	ld (0x91b5:16), 255
	ld (0x91d2:16), 255
	ld (0x90f8:16), 127
	ld (0x8f63:16), 255
	lda xwa, (PanelTlv_PayloadByTag:24)
	ld (0x90f2:16), xwa
	lda xwa, (PanelTlv_CompanionByPart:24)
	ld (0x9182:16), xwa
	lda xbc, (0x918d:16)
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioInit_FillLoop:
	ld (xwa+), 0x50
	cp xwa, xbc
	jr ule, AudioInit_FillLoop
	call SndParamBank_CheckFlash
	jp SndParamBank_LoadOptionBlock

Audio_ResetAfterPayloadError:
	call SubCPU_Payload_GetErrorFlag
	cp hl, 0xffff
	jr nz, Audio_ReinitToneGen
	cp (CURRENT_TITLE:16), 65
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cp hl, 1:i3
	jr nz, Audio_ReinitDisplay
	ld xwa, 0xc0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_ReinitDisplay:
	calr Display_SetupAndPrepareRender
	calr Display_CopyAndRenderBitmaps
	call MainTitle_SetBootFlag

Audio_ReinitToneGen:
	push xde
	push xhl
	push xix
	push xiz
	call PanelTlv_ApplyResetMasks
	call PanelTlv_ValidateAll
	call PanelTlv_ResolvePartCompanions_Entry
	call PanelTlv_WriteAllHeaders
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	calr Audio_InitAllChannelParams
	call SeqTimer_UpdateTempoReg
	calr Audio_FillParamBuffer
	jp CompIface_SetMax

Audio_FillParamBuffer:
	lda xbc, (0x918d:16)
	ld xwa, xbc
	lda xbc, (xbc + 31)

AudioFill_Loop:
	ld (xwa+), 0x50
	cp xwa, xbc
	jr ule, AudioFill_Loop
	ret

Audio_JumpTrampoline:
	jr	t, Audio_ResetAfterPayloadError

Audio_ReinitToneGenAndOutput:
	push xde
	push xhl
	push xix
	push xiz
	call PanelTlv_ApplyResetMasks
	call PanelTlv_ValidateAll
	call PanelTlv_ResolvePartCompanions_Entry
	call PanelTlv_WriteAllHeaders
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr MidiMsg_ParseChannelStream
	cp (0xfd32:16), 182
	jr z, Audio_UpdateTempoAndReturn
	pushw 0x7f
	ldw wa, 0xb0
	ld bc, 1:i3
	ldw de, 0x7f
	calr MIDI_WriteCommandToBuffer
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_UpdateTempoAndReturn:
	call SeqTimer_UpdateTempoReg
	jp CompIface_SetMax

Audio_FullReinitWithPreset:
	lda xwa, (PanelTlv_PayloadByTag:24)
	ld (0x90f2:16), xwa
	lda xwa, (PanelTlv_CompanionByPart:24)
	ld (0x9182:16), xwa
	call Sys_CheckPowerStableFlag
	cp hl, 0:i3
	jr nz, Audio_CheckAndReinitReverb
	ld xwa, 0xc0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde

Audio_CheckAndReinitReverb:
	ld xwa, 0x2880
	call SndParam_LookupReadOnly
	cp hl, 0xb7
	ret nz
	ld xwa, 0x4001
	ldw bc, 0x7f
	ld de, 2:i3
	call SoundParam_NotifyChange
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

VoiceData_InitAndCopyParams:
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	cpw (xsp + 4), 0x50
	jrl nc, VoiceData_InitDone
	pushw 0x3c0
	pushw 0x0
	ld wa, (xsp + 8)
	extz xwa
	ld xbc, xwa
	sll xbc, 4
	sub xbc, xwa
	sll xbc, 6
	ld xwa, 0x1ed400
	add xwa, xbc
	push xwa
	call Memset
	inc 8, xsp
	ld iz, (xsp + 4)
	extz xiz
	ld xwa, xiz
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	ld xwa, xiz
	sll xwa, 4
	sub xwa, xiz
	sll xwa, 6
	lda xiz, (0x1ed400:24)
	add xiz, xwa
	pushw 0x7c
	push xhl
	push xiz
	call Mem_Copy
	lda xwa, (SndParamRam_DefaultImage:24)
	add xwa, 0x7c
	lda xiz, (xiz + 124)
	pushw 0x11e
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, 0x2a2
	call Math_MultiplyAccumulate
	add xhl, 0x99eca0
	add xhl, 0x7c
	lda xwa, (xiz+286)
	pushw 0x226
	push xhl
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)

VoiceData_InitDone:
	pop xiz
	inc 2, xsp
	ret

VoiceData_ExtendedParamSetup:
	cp	wa, 10
	ret	nc
	sll	wa, 4
	extz	xwa
	ld	xde, xwa
	add	xde, 0x99ec00
	lda	xbc, (0x1ed360:24)
	add	xbc, xwa
	pushw	16
	push	xde
	push	xbc
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
MainSysCtrl_Entry5_VoiceInit_Helper:
	calr	Display_SetupAndPrepareRender
	call	PanelTlv_ValidateLivePanel
	call	PanelTlv_ResolvePartCompanions
	call	PanelTlv_WriteLivePanelHeaders
	calr	MidiMsg_ParseChannelStream
	call	MainTitle_SetBootFlag
	jrl	Audio_FillParamBuffer
MainSysCtrl_Entry5_VoiceInit_Helper2:
	dec	8, xsp
	pushw	iz
	lda	xwa, (SndParamRam_DefaultImage:24)
	ld	(xsp+2), xwa
	lda	xwa, (0xf9a0:16)
	ld	(xsp+6), xwa
	ld	iz, 0:i3
VoiceData_ExtendedParamSetup_Loop3:
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	ld	xbc, xhl
	add	xbc, (xsp+2)
	ld	a, (xbc+1)
	extz	wa
	pushw	wa
	lda	xwa, (xbc+2)
	push	xwa
	add	xhl, (xsp+12)
	lda	xwa, (xhl+2)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	wa, iz
	extz	xwa
	ld	xbc, 26
	call	Math_MultiplyAccumulate
	add	xhl, 20
	add	xhl, (xsp+6)
	ld	xwa, xhl
	calr	MIDI_WriteMultiByteWithHeader
	inc	1, iz
	cp	iz, 24
	jr	c, VoiceData_ExtendedParamSetup_Loop3
	call	PanelTlv_ResolvePartCompanions
	popw	iz
	inc	8, xsp
	ret
MainSysCtrl_Entry5_VoiceInit_Helper3:
	lda	xsp, (xsp-10)
	push	qiz
	lda	xwa, (SndParamRam_DefaultImage:24)
	ld	(xsp+4), xwa
	lda	xwa, (0xf9a0:16)
	ld	(xsp+8), xwa
	ld	(xsp+2), 0
MainSysCtrl_Entry5_VoiceInit_Helper3_Loop:
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	ix, wa
	add	ix, 20
	ld	xwa, (xsp+8)
	lda	xhl, (xwa+ix)
	lda xde, (xhl+14)
	ld c, (xde)
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	lda	xwa, (xwa+ix)
	ld a, (xwa+14)
	and a, 7
	or	c, a
	ld	(xde), c
	ld	a, (xhl)
	extz	wa
	ld	e, c
	extz	de
	pushw	7
	ldw	bc, 12
	calr	MIDI_WriteCommandToBuffer
	pushw	9
	ld	a, (xsp+4)
	extz	wa
	muls	wa, 26
	ld	bc, wa
	add	bc, 20
	ld	xwa, (xsp+6)
	lda	xwa, (xwa+bc)
	lda	xwa, (xwa+15)
	push	xwa
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+bc)
	lda	xwa, (xwa+15)
	; bytecode param 0x1d38
	push	xwa
	call	Mem_Copy
	; Mem_Copy
	lda	xsp, (xsp+10)
	ldi_erpb	251, 13
MainSysCtrl_Entry5_VoiceInit_Helper3_Loop2:
	ld	a, (xsp+2)
	extz	wa
	muls	wa, 26
	ld	hl, wa
	ld	bc, hl
	add	bc, 20
	ld	xde, (xsp+8)
	ld	a, (xde+bc)
	extz wa
	ldto_berp	c, 251
	extz	bc
	add	hl, bc
	lda	xde, (xde+hl)
	ld	e, (xde+22)
	extz	de
	pushw	255
	calr	MIDI_WriteCommandToBuffer
	inc1b_erp 251
	cp_erpb 251, 21
	jr	ule, MainSysCtrl_Entry5_VoiceInit_Helper3_Loop2
	incm8	1, (xsp+2)
	cp	(xsp+2), 24
	jrl	c, MainSysCtrl_Entry5_VoiceInit_Helper3_Loop
	set	1, (65472:24)
	pushw	14
	ld	xwa, (xsp+6)
	lda	xwa, (xwa+944)
	push	xwa
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+944)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xsp+2), 0
MainSysCtrl_Entry5_VoiceInit_Helper3_Loop3:
	ld	c, (xsp+2)
	extz	bc
	ld	de, bc
	add	de, 944
	ld	xwa, (xsp+8)
	ld	e, (xwa+de)
	extz de
	pushw	255
	ldw	wa, 128
	calr	MIDI_WriteCommandToBuffer
	incm8	1, (xsp+2)
	cp	(xsp+2), 14
	jr	c, MainSysCtrl_Entry5_VoiceInit_Helper3_Loop3
	ld	xwa, (xsp+8)
	lda	xbc, (xwa+1037)
	ld	a, (xbc)
	bit	2, a
	jr	z, MainSysCtrl_Entry5_VoiceInit_Helper3_Skip
	res	2, a
	ld	(xbc), a
	ld	e, a
	extz	de
	pushw	4
	ldw	wa, 145
	ld	bc, 3:i3
	calr	MIDI_WriteCommandToBuffer
MainSysCtrl_Entry5_VoiceInit_Helper3_Skip:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	(xsp+2), 0
VoiceData_ExtendedParamSetup_Loop:
	lda	xwa, (SndParamRam_DefaultImage:24)
	ld	(xsp+4), xwa
	ld	xwa, 0:i3
	ld	a, (xsp+2)
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	ld	xwa, 0x1ed400
	add	xwa, xbc
	ld	(xsp+8), xwa
	ldib_erp 251, 0
VoiceData_ExtendedParamSetup_Loop2:
	ldto_berp a, 251
	extz	wa
	muls	wa, 26
	ld	hl, wa
	add	hl, 20
	ld	xwa, (xsp+8)
	lda	xix, (xwa+hl)
	lda xde, (xix+14)
	ld c, (xde)
	and	c, 248
	ld	(xde), c
	ld	xwa, (xsp+4)
	exts	xhl
	add	xhl, xwa
	ld	a, (xhl+14)
	and	a, 7
	or	c, a
	ld	(xde), c
	pushw	9
	lda	xwa, (xhl+15)
	push	xwa
	lda	xwa, (xix+15)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	inc1b_erp 251
	cp_erpb 251, 24
	jr	c, VoiceData_ExtendedParamSetup_Loop2
	pushw	14
	ld	xwa, (xsp+6)
	lda	xwa, (xwa+944)
	push	xwa
	ld	xwa, (xsp+14)
	lda	xwa, (xwa+944)
	; bytecode param 0x1d38
	push	xwa
	call	Mem_Copy
	; Mem_Copy
	lda	xsp, (xsp+10)
	inc	1, (xsp+2)
	cp	(xsp+2), 80
	jrl	c, VoiceData_ExtendedParamSetup_Loop
	pop qiz
	lda	xsp, (xsp+10)
	ret
	calr	Display_SetupAndPrepareRender
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PanelTlv_ValidateAll
	call	PanelTlv_ResolvePartCompanions_Entry
	call	PanelTlv_WriteAllHeaders
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	MidiMsg_ParseChannelStream
	calr	Display_CopyAndRenderBitmaps
	jp	SeqTimer_UpdateTempoReg

MidiMsg_ParseChannelStream:
	push xiz
	lda xiz, (0xf9a0:16)
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckTerminator:
	cp (xiz), 0xff
	jr nz, MidiMsg_CheckMsgType
	inc 2, xiz
	jr MidiMsg_LoopAndFlush

MidiMsg_CheckMsgType:
	cp (xiz), 0x1f
	jr ule, MidiMsg_WriteMultiByte
	cp (xiz), 0x48
	jr nz, MidiMsg_CheckControlChange

MidiMsg_WriteMultiByte:
	ld xwa, xiz
	calr MIDI_WriteMultiByteWithHeader
	jr MidiChannelMsg_WriteOutput

MidiMsg_CheckControlChange:
	cp (xiz), 0xc0
	jr c, MidiMsg_WriteDefaultMsg
	cp (xiz), 0xdf
	jr ule, MidiChannelMsg_WriteOutput

MidiMsg_WriteDefaultMsg:
	cp (xiz), 0x49
	jr z, MidiChannelMsg_WriteOutput
	ld xwa, xiz
	calr MIDI_WriteMultiByteNoHeader

MidiChannelMsg_WriteOutput:
	ld a, (xiz + 1)
	inc 2, a
	extz wa
	lda	xiz, (xiz+wa)

MidiMsg_LoopAndFlush:
	cp xiz, 0xffbe
	jr c, MidiMsg_CheckTerminator
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop xiz
	ret

Display_SetupAndPrepareRender:
	pushw 0x20
	pushw DataSlot_HeaderTemplate@hi16
	pushw DataSlot_HeaderTemplate@lo16
	pushw 0x0
	pushw 0xf980
	call Mem_Copy
	pushw 0x620
	pushw SndParamRam_DefaultImage@hi16
	pushw SndParamRam_DefaultImage@lo16
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 20)
	res 0, (0xffc2:24)
	set 1, (0xffc0:24)
	call Get_Region_Code
	cp l, 2:i3
	jr nz, Display_SetRegionNon2
	ld (0x00ffc8:24), 0x01
	jr Display_RegionDone

Display_SetRegionNon2:
	ld (0x00ffc8:24), 0x02

Display_RegionDone:
	ld wa, 0:i3
	call BitMapOut_PrepareRender_CheckBit2
	jrl Audio_FillParamBuffer

Display_CopyAndRenderBitmaps:
	pushw iz
	pushw 0x10
	pushw Display_CopyAndRenderBitmaps_Str_HK@hi16
	pushw Display_CopyAndRenderBitmaps_Str_HK@lo16
	pushw 0x1e
	pushw 0xd350
	call Mem_Copy
	pushw 0xa0
	ld xwa, 0x99ec00
	push xwa
	pushw 0x1e
	pushw 0xd360
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld iz, 0:i3

DisplayRender_Loop:
	ld wa, iz
	calr VoiceData_InitAndCopyParams
	inc 1, iz
	cp iz, 0x50
	jr c, DisplayRender_Loop
	calr Display_ProcessBitmapTable
	popw iz
	ret

Display_ProcessBitmapTable:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0

BitmapTable_ProcessEntry:
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	lda xwa, (BitmapTable_ProcessEntry_Data_2:24)
	add xwa, xbc
	ld a, (xwa)
	calr PanelTlv_PayloadOfTag
	ld xiz, xhl
	sub xiz, 0xf9a0
	ld wa, (xsp + 4)
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, BitmapTable_ProcessEntry_Data
	add xwa, xbc
	lda xbc, (0x1ed400:24)
	lda xde, (xwa + 3)
	lda xhl, (xwa + 4)
	lda xix, (xwa + 5)
	cpw (xwa), 0x50
	jr nz, BitmapTable_CheckOffset
	ld iy, 0:i3
	ld e, (xde)
	ld d, (xix)
	ld l, (xhl)
	add xbc, xiz
	ld xix, xbc

BitmapTable_RenderLine:
	ld a, e
	extz wa
	lda	xbc, (xix+wa)
	ld a, d
	cpl a
	and (xbc), a
	or (xbc), l
	inc 1, iy
	add xix, 0x3c0
	cp iy, 0x50
	jr c, BitmapTable_RenderLine
	jr BitmapTable_NextEntry

BitmapTable_CheckOffset:
	cpw (xwa), 0x50
	jr ge, BitmapTable_NextEntry
	ld wa, (xwa)
	exts xwa
	ld xiy, xwa
	sll xiy, 4
	sub xiy, xwa
	sll xiy, 6
	add xbc, xiy
	ld xiy, xbc
	add xiy, xiz
	ld c, (xde)
	extz bc
	ld a, (xix)
	cpl a
	and	(xiy+bc), a
	ld c, (xde)
	extz bc
	ld a, (xhl)
	or	(xiy+bc), a

BitmapTable_NextEntry:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0x1
	jrl c, BitmapTable_ProcessEntry
	pop xiz
	inc 2, xsp
	ret

MIDI_WriteMultiByteWithHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld A, (xiz+)
	ld (xsp + 4), a
	ld A, (xiz+)
	ld (xsp + 6), a
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz + 1)
	extz de
	pushw 0xff
	ld bc, 1:i3
	calr MIDI_WriteCommandToBuffer
	ld a, (xsp + 4)
	extz wa
	ld e, (xiz)
	extz de
	pushw 0xff
	ld bc, 0:i3
	calr MIDI_WriteCommandToBuffer
	decm8 2, (xsp + 6)
	ld (xsp + 8), 0x2
	inc 2, xiz
	cp (xsp + 6), 0x0
	jr z, MidiMultiByte_Done

MidiMultiByte_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiMultiByte_WriteLoop

MidiMultiByte_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteMultiByteNoHeader:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ld A, (xiz+)
	ld (xsp + 4), a
	ld A, (xiz+)
	ld (xsp + 6), a
	ld (xsp + 8), 0x0
	cp (xsp + 6), 0x0
	jr z, MidiNoHeader_Done

MidiNoHeader_WriteLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 8)
	extz bc
	ld e, (xiz)
	extz de
	pushw 0xff
	calr MIDI_WriteCommandToBuffer
	decm8 1, (xsp + 6)
	incm8 1, (xsp + 8)
	inc 1, xiz
	cp (xsp + 6), 0x0
	jr nz, MidiNoHeader_WriteLoop

MidiNoHeader_Done:
	pop xiz
	inc 6, xsp
	ret

MIDI_WriteCommandToBuffer:
	ld hl, (0x90de:16)
	ld ix, hl
	inc 1, hl
	ld (0x90de:16), hl
	lda xhl, (SWBTWR_EVENT_QUEUE:16)
	extz xix
	add xix, xhl
	ld (xix), a
	ld wa, (0x90de:16)
	ld ix, wa
	inc 1, wa
	ld (0x90de:16), wa
	ld wa, ix
	extz xwa
	add xwa, xhl
	ld (xwa), c
	ld wa, (0x90de:16)
	ld bc, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xbc
	add xbc, xhl
	ld (xbc), e
	ld wa, (0x90de:16)
	ld bc, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xbc
	add xbc, xhl
	ld a, (xsp + 4)
	ld (xbc), a
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xhl
	ld (xwa), 0xff
	cpw (0x90de:16), 508
	jr c, MidiWrite_ReturnDiscard
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

MidiWrite_ReturnDiscard:
	retd 0x2

Audio_InitAllChannelParams:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

AudioParamInit_Loop:
	ldto_berp A, 0xfb
	extz wa
	calr Audio_InitSingleChannelParams
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, AudioParamInit_Loop
	popw_erp 0xfa
	ret

Audio_InitSingleChannelParams:
	dec 2, xsp
	ld (xsp), a
	ld (MIDI_MSG_STATUS:16), 177
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (MIDI_MSG_DATA2:16), 0
	ld (MIDI_MSG_DATA3:16), 64
	calr SwbtWr_WriteParamBlock
	ld (MIDI_MSG_STATUS:16), 178
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (MIDI_MSG_DATA2:16), 0
	ld (MIDI_MSG_DATA3:16), 127
	calr SwbtWr_WriteParamBlock
	ld (MIDI_MSG_STATUS:16), 179
	mrib4 0x87, 0x19, 0x28, 0x91
	ld (MIDI_MSG_DATA2:16), 127
	ld (MIDI_MSG_DATA3:16), 127
	calr SwbtWr_WriteParamBlock
	mrib4 0x87, 0x19, 0x7e, 0x91
	ld (0x917f:16), 4
	ld (0x9180:16), 0
	ld (0x9181:16), 8
	call MIDI_WriteVoiceParamFromBuffer
	mrib4 0x87, 0x19, 0x27, 0x91
	ld (MIDI_MSG_DATA1:16), 4
	ld (MIDI_MSG_DATA2:16), 0
	ld (MIDI_MSG_DATA3:16), 8
	calr SwbtWr_WriteParamBlock
	inc 2, xsp
	ret

Audio_MainPeriodicUpdate:
	cp (0xc039:16), 255
	ret z
	res 0, (0x9165:16)
	lda xwa, (PanelTlv_PayloadByTag:24)
	ld (0x90f2:16), xwa
	calr Audio_SyncBufferPositions
	push xde
	push xhl
	push xix
	push xiz
	call MidiStream_ProcessEventBuffer
	call MidiStream_ProcessSeqBuffer
	call MIDI_SelectTempoExpressionSource
	call MidiStream_ProcessTempoRingBuf
	call MidiStream_ProcessRxBuffer
	call MidiPkt_ProcessEventQueue
	pop xiz
	pop xix
	pop xhl
	pop xde
	res 1, (0x90f9:16)
	ret

Audio_SyncBufferPositions:
	ldw (0x9133:16), 0
	ldmm16 0x90e0, 0x90de
	jr FileIO_ProcessRemainingOps

; File I/O operation dispatch
FileIO_OperationDispatch:
	calr SndParam_FetchSequencerParams
	ld a, (MIDI_MSG_STATUS:16)
	extz wa
	sla wa, 2
	lda xbc, (SoundProgram_DispatchTable:24)
	ld	xhl, (xbc+wa)
	call (xhl)
	cpw (0x90de:16), 508
	jr c, FileIO_ProcessRemainingOps
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90e0:16), 0

FileIO_ProcessRemainingOps:
	lda xbc, (0xc039:16)
	ld wa, (0x9133:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xff
	jr nz, FileIO_OperationDispatch
	lda xbc, (SWBTWR_EVENT_QUEUE:16)
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	ld (0x90f8:16), 127
	ret

ExtData_ToneParam_DispatchHandler:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 22
	jr	z, ExtData_ToneParam_DispatchHandler_Skip
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 11
	ret	gt
	add	wa, wa
	lda	xix, (ExtData_ToneParam_DispatchHandler_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (ExtData_ToneParam_DispatchHandler_Code:24)
	jp	t, (xix+wa)
ExtData_ToneParam_DispatchHandler_Code:
	jr ExtData_ToneParam_DispatchHandler_Join
ExtData_ToneParam_DispatchHandler_Case3:
	jrl	ExtData_Voice_CheckMode3_Helper
ExtData_ToneParam_DispatchHandler_Case4:
	jrl	ExtData_ToneParam_DispatchHandler_Join2
ExtData_ToneParam_DispatchHandler_Case5:
	jrl	ExtData_ToneParam_DispatchHandler_Join5
ExtData_ToneParam_DispatchHandler_Case6:
	jrl	ExtData_Voice_CheckMode3_Helper_Join2
ExtData_ToneParam_DispatchHandler_Case7:
	jrl	ExtData_Voice_CheckMode3_Helper_Join3
ExtData_ToneParam_DispatchHandler_Case8:
	jrl	ExtData_Voice_CheckMode3_Helper_Join4
ExtData_ToneParam_DispatchHandler_Case9:
	jrl	ExtData_Voice_CheckMode3_Helper_Join5
ExtData_ToneParam_DispatchHandler_Case10:
	jrl	ExtData_Voice_CheckMode3_Helper_Join6
ExtData_ToneParam_DispatchHandler_Case11:
	jrl	ExtData_Voice_CheckMode3_Helper_Join7
ExtData_ToneParam_DispatchHandler_Skip:
	calr	ExtData_ToneParam_DispatchHandler_Helper4
ExtData_ToneParam_DispatchHandler_Case1:	; cases 1, 2
	ret
ExtData_ToneParam_DispatchHandler_Join:
	dec	6, xsp
	lda	xwa, (xsp)
	ld	(xwa), (0x9130)
	ld	(xwa+1), (0x9131)
	ld	(xwa+2), (MIDI_MSG_STATUS)
	call	SndParam_ApplyProgramChange
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jr	z, ExtData_ToneParam_DispatchHandler_Epilogue2
	lda	xde, (xsp)
	cp	(xde), 12
	jr	nz, ExtData_ToneParam_DispatchHandler_Skip4
	ld	a, (xhl)
	cp	a, (xde+3)
	jr	nz, ExtData_ToneParam_DispatchHandler_Skip4
	ld	a, (xhl+1)
	res	7, a
	cp	a, (xde+4)
	jr	nz, ExtData_ToneParam_DispatchHandler_Skip4
	cp	(CURRENT_MODE:16), 13
	jr	nz, ExtData_ToneParam_DispatchHandler_Epilogue2
ExtData_ToneParam_DispatchHandler_Skip4:
	ld	a, (xde+3)
	ld (xhl+), a
	ld c, (xhl)
	and c, 128
	ld	(xhl), c
	inc	4, xde
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	ld	(MIDI_MSG_DATA1:16), 1
	ld	(MIDI_MSG_DATA2), (xde)
	ld	(MIDI_MSG_DATA3:16), 127
	calr	SwbtWr_FlushAndAppendParams
	ld	(MIDI_MSG_DATA1:16), 0
	ld	(MIDI_MSG_DATA2), (xsp+3)
	ld	(MIDI_MSG_DATA3:16), 255
	calr	SwbtWr_FlushAndAppendParams
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	lda	xde, (xsp)
	ld	c, (xde+3)
	extz	bc
	ld	e, (xde+4)
	extz	de
	calr	SndParam_UpdateVoiceEntry
ExtData_ToneParam_DispatchHandler_Epilogue2:
	inc	6, xsp
	ret
ExtData_Voice_CheckMode3_Helper:
	ldw	wa, 128
	calr	ExtData_SetTlvField
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_DispatchHandler_Join2:
	dec	6, xsp
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jrl	z, ExtData_ToneParam_DispatchHandler_Epilogue
	lda	xwa, (xsp)
	.byte 0xb8
	push	sr
	push_a
	ld	l, 145:opc
	ld	c, (xhl)
	ld	(xwa+3), c
	ld	c, (xhl+1)
	res	7, c
	ld	(xwa+4), c
	call	SndParam_FetchOscTableEntry
	lda	xwa, (xsp)
	cp	(xwa), 15
	jr	nz, ExtData_Voice_CheckMode3_Helper_Skip
	and	(37168:16), 183
	and	(37169:16), 183
ExtData_Voice_CheckMode3_Helper_Skip:
	cp	(xwa), 12
	jr	nz, ExtData_Voice_CheckMode3_Helper_Skip2
	res	6, (37168:16)
	res	6, (37169:16)
ExtData_Voice_CheckMode3_Helper_Skip2:
	bit	1, (37113:16)
	jr	z, ExtData_Voice_CheckMode3_Helper_Skip3
	ldw	wa, 8
	calr	ExtData_ForceSetTlvField
	ldw	wa, 96
	jr	ExtData_Voice_CheckMode3_Helper_Join
ExtData_Voice_CheckMode3_Helper_Skip3:
	ldw	wa, 104
ExtData_Voice_CheckMode3_Helper_Join:
	calr	ExtData_ToggleTlvBits
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 7
	cp	a, 7:i3
	jr	nz, ExtData_ToneParam_DispatchHandler_Skip2
	ld	wa, 7:i3
	calr	ExtData_SetTlvField
	jr	ExtData_ToneParam_DispatchHandler_Join4
ExtData_ToneParam_DispatchHandler_Skip2:
	and	c, 3
	jr	z, ExtData_ToneParam_DispatchHandler_Join4
	ld	a, (0x9130:16)
	cp	a, 2:i3
	jr	nz, ExtData_ToneParam_DispatchHandler_Skip3
	ld	(0x9153:16), 1
	ld	(0x9154:16), 8
	ld	(0x9155:16), 7
	ld	wa, 2:i3
	ld	bc, 7:i3
	jr	ExtData_ToneParam_DispatchHandler_Join3
ExtData_ToneParam_DispatchHandler_Skip3:
	cp	a, 1:i3
	jr	nz, ExtData_ToneParam_DispatchHandler_Join4
	ld	(0x9153:16), 255
	ld	(0x9154:16), 255
	ld	(0x9155:16), 0
	ld	wa, 1:i3
	ld	bc, 7:i3
ExtData_ToneParam_DispatchHandler_Join3:
	calr	ExtData_StepTlvField
ExtData_ToneParam_DispatchHandler_Join4:
	calr	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_DispatchHandler_Epilogue:
	inc	6, xsp
	ret
ExtData_ToneParam_DispatchHandler_Join5:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join2:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	ldw	wa, 128
	calr	ExtData_ToggleTlvBits
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join3:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join4:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join5:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join6:
	ldw	wa, 255
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3_Helper_Join7:
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_DispatchHandler_Helper4:
	ld	wa, 1:i3
	calr	ExtData_ToggleTlvBits
	jrl	SwbtWr_FlushAndAppendParams
FileIO_AllocBuffer:
	ret
ExtData_ToneParam_CheckMode:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 1:i3
	jr	z, ExtData_ToneParam_CheckMode_Skip
	cp	a, 0:i3
	ret	nz
	jr	ExtData_ToneParam_CheckMode_Join
ExtData_ToneParam_CheckMode_Skip:
	calr	ExtData_Tag43_SetByte1Fields
	ret
ExtData_ToneParam_CheckMode_Join:
	ldw	wa, 128
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
; ExtData_Tag43_SetByte1Fields: Applies an incoming event to byte +1 of panel record 0x43 as two fields, bit 7 and
;   bits 0-6 (ExtData_SetTlvField 0x80, then 0x7F), and posts the change with SwbtWr_FlushAndAppendParams. Basis:
;   callers + body -- ExtData_ToneParam_CheckMode is entry 0x43 of SoundProgram_DispatchTable and calls it when the
;   event offset (0x912F) is 1; record 0x43 is identified in docs/kn-disk-file-formats.md:534 as the microphone record
;   (on/off, a 0..127 level, a second on/off; 'microphone' is that page's inference).
ExtData_Tag43_SetByte1Fields:
	ldw	wa, 128
	calr	ExtData_SetTlvField
	ldw	wa, 127
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltDispatch:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda	xix, (ExtData_ToneParam_AltDispatch_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (ExtData_ToneParam_AltDispatch_Code:24)
	jp	t, (xix+wa)
ExtData_ToneParam_AltDispatch_Code:
	jr ExtData_ToneParam_AltDispatch_Join
ExtData_ToneParam_AltDispatch_Case1:	; cases 1, 2
	jr ExtData_ToneParam_AltDispatch_Join2
ExtData_ToneParam_AltDispatch_Case3:	; cases 3, 4, 5, 6
	jr	ExtData_ToneParam_AltDispatch_Join3
ExtData_ToneParam_AltDispatch_Case7:
	calr	ExtData_ToneParam_AltDispatch_Helper
	ret
ExtData_ToneParam_AltDispatch_Join:
	ldw	wa, 255
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltDispatch_Join2:
	ldw	wa, 15
	calr	ExtData_SetTlvField
	ldw	wa, 240
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltDispatch_Join3:
	ldw	wa, 15
	calr	ExtData_SetTlvField
	ldw	wa, 240
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltDispatch_Helper:
	ldw	wa, 15
	calr	ExtData_SetTlvField
	ldw	wa, 48
	calr	ExtData_ToggleTlvBits
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltEntry:
	ret
ExtData_ToneParam_AltBody:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 8
	ret	gt
	add	wa, wa
	lda	xix, (ExtData_ToneParam_AltBody_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (ExtData_ToneParam_AltBody_Code:24)
	jp	t, (xix+wa)
ExtData_ToneParam_AltBody_Code:
	jr ExtData_ToneParam_AltBody_Join
ExtData_ToneParam_AltBody_Case3:
	jr ExtData_ToneParam_AltBody_Join2
ExtData_ToneParam_AltBody_Case4:
	jrl	ExtData_ToneParam_AltBody_Join3
ExtData_ToneParam_AltBody_Case5:	; cases 5, 6
	jrl	ExtData_ToneParam_AltBody_Entry
ExtData_ToneParam_AltBody_Case7:
	jrl	ExtData_ToneParam_AltBody_Join4
; ExtData_ToneParam_AltBody_OnTempo: Offset 8 of style/tempo record 0x48 (0xFC5A): stores a changed tempo into
;   0xFC62/0xFC63, posts it and calls SeqTimer_UpdateTempoReg.
ExtData_ToneParam_AltBody_OnTempo:
	calr	ExtData_ToneParam_AltBody_Helper2
ExtData_ToneParam_AltBody_Case1:	; cases 1, 2
	ret
ExtData_ToneParam_AltBody_Join:
	lda	xwa, (0x90ea:16)
	ld	(xwa), (0x9130)
	ld	(xwa+1), (0x9131)
	ld	(xwa+2), (MIDI_MSG_STATUS)
	call	Rhythm_LookupTempoVelocity_Wrap
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	ret	z
	lda	xde, (0x90ee:16)
	ld a, (xde+)
	ld (xhl+), a
	ld c, (xhl)
	and c, 128
	ld	(xhl), c
	ld	a, (xde)
	or	c, a
	ld	(xhl), c
	ld	(MIDI_MSG_DATA1:16), 1
	ld	(MIDI_MSG_DATA2), (xde)
	ld	(MIDI_MSG_DATA3:16), 127
	calr	SwbtWr_FlushAndAppendParams
	ld	(MIDI_MSG_DATA1:16), 0
	ld	(MIDI_MSG_DATA2), (37102:16)
	ld	(MIDI_MSG_DATA3:16), 255
	calr	SwbtWr_FlushAndAppendParams
	ret
ExtData_ToneParam_AltBody_Join2:
	ld	wa, 7:i3
	calr	ExtData_ToneParam_AltBody_Helper
	ldw	wa, 8
	calr	ExtData_ToggleTlvBits
	ld	a, (MIDI_MSG_DATA3:16)
	and	a, 7
	jr	z, ExtData_ToneParam_AltBody_Skip2
	call	ToneGen_DispatchByMode
	set	0, (0x90f9:16)
ExtData_ToneParam_AltBody_Skip2:
	calr	SwbtWr_FlushAndAppendParams
	jrl	MIDI_WriteResetSequence
ExtData_ToneParam_AltBody_Join3:
	ldw	wa, 80
	calr	ExtData_ToggleTlvBits
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltBody_Entry:
	ld	(MIDI_MSG_DATA2), (37168:16)
	ld	(MIDI_MSG_DATA3), (37169:16)
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltBody_Join4:
	ldw	wa, 48
	calr	ExtData_SetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_ToneParam_AltBody_Helper2:
	push	xiz
	lda	xiz, (0xfc5a:16)
	lda	xbc, (xiz+8)
	lda	xhl, (xiz+9)
	ld	e, (0x9130:16)
	cp	(xbc), e
	jr	nz, ExtData_ToneParam_AltBody_Skip
	ld	a, (xhl)
	cp	a, (37169:16)
	jr	z, ExtData_ToneParam_AltBody_Epilogue
ExtData_ToneParam_AltBody_Skip:
	ld	(xbc), e
	ld	(xhl), (0x9131)
	ld	(MIDI_MSG_DATA2), (xbc)
	ld	(MIDI_MSG_DATA3:16), 255
	calr	SwbtWr_FlushAndAppendParams
	ld	(MIDI_MSG_DATA1:16), 9
	ld	(MIDI_MSG_DATA2), (xiz+9)
	ld	(MIDI_MSG_DATA3:16), 1
	calr	SwbtWr_FlushAndAppendParams
	call	SeqTimer_UpdateTempoReg
ExtData_ToneParam_AltBody_Epilogue:
	pop	xiz
	ret
ExtData_ToneParam_MultiChannel:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 16
	jr	z, ExtData_ToneParam_MultiChannel_Skip2
	cp	a, 4:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip3
	cp	a, 3:i3
	jrl	z, ExtData_Voice_UpdateFlags
	cp	a, 1:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip
	cp	a, 0:i3
	ret	nz
ExtData_ToneParam_MultiChannel_Skip:
	jrl	ExtData_ToneParam_MultiChannel_Join3
ExtData_ToneParam_MultiChannel_Skip2:
	calr	ExtData_PostRawValueAndMask
	ret
ExtData_ToneParam_MultiChannel_Skip3:
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, ExtData_ToneParam_MultiChannel_Skip4
	ldw	wa, 255
	jrl	ExtData_SetTlvField
ExtData_ToneParam_MultiChannel_Skip4:
	and	c, 3
	ret	z
	ld	c, (0x9130:16)
	and	c, 3
	lda	xwa, (0xfc6a:16)
	cp	c, 3:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip7
	cp	c, 1:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip5
	cp	c, 2:i3
	jr	nz, ExtData_ToneParam_MultiChannel_Join2
	ld	(0x9153:16), 12
	ld	(0x9154:16), 89
	ld	(0x9155:16), 88
	ld	wa, 2:i3
	ldw	bc, 255
	calr	ExtData_StepTlvField
	jr	ExtData_ToneParam_MultiChannel_Join2
ExtData_ToneParam_MultiChannel_Skip5:
	ld	xbc, xwa
	ld	a, (xwa)
	ld	e, a
	cp	a, 40
	jr	ule, ExtData_ToneParam_MultiChannel_Skip6
	sub	e, 12
ExtData_ToneParam_MultiChannel_Skip6:
	cp	e, a
	ret	z
	ld	(xbc), e
	ld	(MIDI_MSG_DATA2:16), e
	jr	ExtData_ToneParam_MultiChannel_Join
ExtData_ToneParam_MultiChannel_Skip7:
	ld	xbc, xwa
	ld	a, (xwa)
	cp	a, 64
	ret	z
	ld	(xbc), 64
	ld	(MIDI_MSG_DATA2:16), 64
ExtData_ToneParam_MultiChannel_Join:
	ld	(MIDI_MSG_DATA3:16), 255
ExtData_ToneParam_MultiChannel_Join2:
	calr	SwbtWr_FlushAndAppendParams
	ret
ExtData_ToneParam_MultiChannel_Join3:
	lda	xbc, (0xfc66:16)
	ld	e, (xbc+1)
	extz	de
	sll	de, 8
	ld	a, (xbc)
	extz	wa
	add	wa, de
	ld	(0x9163:16), wa
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 2:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip11
	cp	a, 0:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip11
	cp	a, 3:i3
	jr	z, ExtData_ToneParam_MultiChannel_Skip10
	cp	a, 1:i3
	ret	nz
	bit	0, (xbc+3)
	jr	nz, ExtData_ToneParam_MultiChannel_Skip11
ExtData_ToneParam_MultiChannel_Skip10:
	cp	(37167:16), 1
	jr	nz, ExtData_ToneParam_MultiChannel_Skip11
	res	1, (0x9130:16)
	res	1, (0x9131:16)
ExtData_ToneParam_MultiChannel_Skip11:
	cp	(37167:16), 1
	jr	nz, ExtData_ToneParam_MultiChannel_Skip13
	ld	wa, 2:i3
	calr	ExtData_ToggleTlvBits
	bit	1, (MIDI_MSG_DATA3:16)
	jr	nz, ExtData_ToneParam_MultiChannel_Skip12
	ret
ExtData_ToneParam_MultiChannel_Skip12:
	set	0, (0x90f9:16)
	res	1, (0x9130:16)
	res	1, (0x9131:16)
	ld	(MIDI_MSG_DATA3:16), 0
ExtData_ToneParam_MultiChannel_Skip13:
	calr	ExtData_ToneParam_MultiChannel_Helper2
	call	ToneGen_DispatchByMode
	jrl	MIDI_WriteResetSequence
ExtData_ToneParam_MultiChannel_Helper2:
	ld	c, (0x9131:16)
	cp	c, 0:i3
	ret	z
	lda	xix, (0x915f:16)
	lda	xhl, (0x9161:16)
	ld	e, (0x912f:16)
	extz	de
	ld	a, (0x9130:16)
	and	a, c
	or	(xix+de), a
	ld	c, (37167:16)
	extz	bc
	ld	a, (0x9131:16)
	cpl	a
	and	(xhl+bc), a
	ld	c, (37167:16)
	extz	bc
	ld	a, (37168:16)
	and	a, (37169:16)
	or	(xhl+bc), a
	ld	c, (xhl)
	cp	c, 0:i3
	jr	nz, ExtData_ToneParam_MultiChannel_Skip8
	cp	(xhl+1), 0
	jr	nz, ExtData_ToneParam_MultiChannel_Skip8
	ld	(xix), 0
	ld	(xix+1), 0
	ret
ExtData_ToneParam_MultiChannel_Skip8:
	ld	a, (xix)
	and	a, 3
	jr	nz, ExtData_ToneParam_MultiChannel_Skip9
	bit	1, c
	ret	z
ExtData_ToneParam_MultiChannel_Skip9:
	lda	xde, (0xfc66:16)
	extz	wa
	lda	xbc, (ExtData_ToneParam_MultiChannel_Data:24)
	ld	c, (xbc+wa)
	ld	(xde), c
	ld	a, (xde+1)
	sll	a, 8
	extz	wa
	extz	bc
	add	bc, wa
	cp bc, (37219:16)
	ret	z
	set	0, (0x90f9:16)
	ret

MIDI_WriteResetSequence:
	ld a, (0x90f9:16)
	bit 0, a
	ret z
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	lda xbc, (SWBTWR_EVENT_QUEUE:16)
	extz xde
	add xde, xbc
	ld (xde), 0x90
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ld (xde), 0x0
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	lda xde, (0xfc66:16)
	ld a, (xde)
	ld (xhl), a
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1f
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x90
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld (xhl), 0x1
	ld wa, (0x90de:16)
	ld hl, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xhl
	add xhl, xbc
	ld a, (xde + 1)
	ld (xhl), a
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ld (xde), 0x1f
	ld a, (0x90f9:16)
	res 0, a
	ld (0x90f9:16), a
	ret

ExtData_Voice_UpdateFlags:
	ld	wa, 2:i3
	calr	ExtData_ToggleTlvBits
	ld	wa, 1:i3
	calr	ExtData_SetTlvField
	calr	SwbtWr_FlushAndAppendParams
	lda	xbc, (0xfc66:16)
	bit	0, (xbc+3)
	ret	nz
	ld	a, (0xfc5d:16)
	and	a, 7
	cp	a, 1:i3
	ret	nz
	inc	1, xbc
	ld	a, (xbc)
	bit	1, a
	ret	z
	set	0, (0x90f9:16)
	ld	a, (xbc)
	res	1, a
	ld	(xbc), a
	calr	MIDI_WriteResetSequence
	ret
; ExtData_PostRawValueAndMask: Posts the incoming event unchanged: MIDI_MSG_DATA2 := value (0x9130), MIDI_MSG_DATA3 :=
;   mask (0x9131), then SwbtWr_FlushAndAppendParams (which appends it when the mask is non-zero); no panel record byte
;   is touched. Basis: callers + body -- ExtData_ToneParam_MultiChannel (entry 0x90 of SoundProgram_DispatchTable)
;   calls it for offset 16, outside tag 0x90's 6-byte record; ExtData_Voice_CopyAndJump (entry 0xA8) is the same body.
ExtData_PostRawValueAndMask:
	ld	(MIDI_MSG_DATA2), (37168:16)
	ld	(MIDI_MSG_DATA3), (37169:16)
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 1:i3
	ret	nz
	calr	ExtData_ToggleReverbIllusionOnOff
	ret
; ExtData_ToggleReverbIllusionOnOff: Toggles bits 7 and 6 of panel record 0x60 byte +1 -- the DIGITAL REVERB and
;   ACOUSTIC ILLUSION on/off bits -- by the incoming event (ExtData_ToggleTlvBits with mask 0xC0) and posts the change
;   with SwbtWr_FlushAndAppendParams; bit 5 (EQUALIZER) is not handled here. Basis: callers + body --
;   ExtData_Voice_CheckMode (entry 0x60 of SoundProgram_DispatchTable) calls it for offset 1; the bit meanings are
;   docs/kn-disk-file-formats.md:469 (0x4002/0x4004/0x4006 = tag 0x60 +1 bits 7/6/5 for slots 1/2/4), confirmed by
;   BitMapOut_RestoreExtra.
ExtData_ToggleReverbIllusionOnOff:
	ldw	wa, 192
	calr	ExtData_ToggleTlvBits
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_RetEntry:
	ret
ExtData_Voice_MixedHandler:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 2:i3
	jr	z, ExtData_Voice_MixedHandler_Skip
	cp	a, 0:i3
	ret	nz
	jr	ExtData_Voice_MixedHandler_Join
ExtData_Voice_MixedHandler_Skip:
	calr	ExtData_ApplyTransposeEvent
	ret
ExtData_Voice_MixedHandler_Join:
	ld	wa, 4:i3
	calr	ExtData_ToggleTlvBits
	calr	SwbtWr_FlushAndAppendParams
	ld	(0x9153:16), 1
	ld	(0x9154:16), 4
	ld	(0x9155:16), 0
	ld	wa, 1:i3
	ld	bc, 3:i3
	calr	ExtData_StepTlvField
	calr	SwbtWr_FlushAndAppendParams
	cp	(50632:16), 255
	ret	nz
	ld	a, (0x9130:16)
	and	a, (0x9131:16)
	bit	0, a
	jr	z, ExtData_Voice_MixedHandler_Skip5
	ld	a, (0xfd02:16)
	and	a, 3
	extz	wa
	lda	xbc, (ExtData_Voice_MixedHandler_Data:24)
	ld	(0x8f58), (xbc+wa)
	jr	ExtData_Voice_MixedHandler_Join4
ExtData_Voice_MixedHandler_Skip5:
	ld	(0x8f58:16), 0
ExtData_Voice_MixedHandler_Join4:
	ldw	wa, 69
	call	CtrlPanel_SetIndicatorBit
	ret
; ExtData_ApplyTransposeEvent: Applies a panel event to the TRANSPOSE byte, panel record 0x70 byte +2 (0xFD04, 0..11 =
;   -5..+6 semitones, 5 = none): mask 0xFF sets it from the value; otherwise, unless 0xE3E2 bit 1 is set, value bits
;   0-1 = 1 step down (floor 0), 2 step up (cap 11), 0 or 3 reset to 5. When the posted value is 5 it sets the 0x8D3C
;   display countdown to 24; then SwbtWr_FlushAndAppendParams. Basis: callers + body -- ExtData_Voice_MixedHandler
;   (entry 0x70 of SoundProgram_DispatchTable) calls it for offset 2; the record rule (0..11, default 5),
;   EffectSelect_StepTable (-5..+6 applied per channel from 0xFD04) and AcTransposeBoxProc (labels G..F# with C at 5,
;   blank at 5 once 0x8D3C runs out) identify the byte.
ExtData_ApplyTransposeEvent:
	ld	c, (0x9131:16)
	ld	a, c
	and	a, 255
	cp	a, 255
	jr	nz, ExtData_Voice_MixedHandler_Helper_Entry
	ldw	wa, 255
	calr	ExtData_SetTlvField
	jr	ExtData_Voice_MixedHandler_Join3
ExtData_Voice_MixedHandler_Helper_Entry:
	bit	1, (58338:16)
	jr	nz, ExtData_Voice_MixedHandler_Join3
	and	c, 3
	jr	z, ExtData_Voice_MixedHandler_Join3
	ld	a, (0x9130:16)
	and	a, 3
	cp	a, 1:i3
	jr	z, ExtData_Voice_MixedHandler_Skip2
	cp	a, 2:i3
	jr	nz, ExtData_Voice_MixedHandler_Skip3
	ld	(0x9153:16), 1
	ld	(0x9154:16), 12
	ld	(0x9155:16), 11
	ld	wa, 2:i3
	ldw	bc, 255
	jr	ExtData_Voice_MixedHandler_Join2
ExtData_Voice_MixedHandler_Skip2:
	ld	(0x9153:16), 255
	ld	(0x9154:16), 255
	ld	(0x9155:16), 0
	ld	wa, 1:i3
	ldw	bc, 255
ExtData_Voice_MixedHandler_Join2:
	calr	ExtData_StepTlvField
	jr	ExtData_Voice_MixedHandler_Join3
ExtData_Voice_MixedHandler_Skip3:
	lda	xbc, (0xfd04:16)
	ld	a, (xbc)
	cp	a, 5:i3
	ret	z
	ld	(xbc), 5
	ld	(MIDI_MSG_DATA2:16), 5
	ld	(MIDI_MSG_DATA3:16), 255
ExtData_Voice_MixedHandler_Join3:
	cp	(MIDI_MSG_DATA2:16), 5
	jr	nz, ExtData_Voice_MixedHandler_Skip4
	ld	(0x8d3c:16), 24
ExtData_Voice_MixedHandler_Skip4:
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CheckMode3:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 3:i3
	ret	nz
	calr	ExtData_Voice_CheckMode3_Helper
	ret
ExtData_Voice_RetEntry2:
	ret
ExtData_Voice_FullHandler:
	calr	SndParam_WriteLookupAndStore
	ld	a, (0x912f:16)
	cp	a, 11
	jr	z, ExtData_Voice_FullHandler_Skip
	cp	a, 2:i3
	jr	z, ExtData_Voice_FullHandler_Entry
	cp	a, 4:i3
	jrl	z, ExtData_Voice_CheckMode3_Helper
	cp	a, 3:i3
	jr	z, ExtData_Voice_FullHandler_Skip2
	cp	a, 1:i3
	ret	nz
	jr	ExtData_Voice_FullHandler_Join
ExtData_Voice_FullHandler_Skip:
	calr	ExtData_Voice_FullHandler_Helper
	ret
ExtData_Voice_FullHandler_Join:
	ldw	wa, 128
	calr	ExtData_ForceSetTlvField
	and	(37170:16), 128
	ldw	wa, 127
	calr	VoiceParam_CompareAndUpdate
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_FullHandler_Skip2:
	ld	a, (0x9130:16)
	and	a, (0x9131:16)
	ret	z
	ld	wa, 1:i3
	calr	ExtData_ToggleTlvBits
	calr	SwbtWr_FlushAndAppendParams
	ret
ExtData_Voice_FullHandler_Entry:
	res	1, (37113:16)
	ldw	wa, 64
	calr	ExtData_ForceSetTlvField
	ldw	wa, 128
	calr	ExtData_ForceSetTlvField
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_FullHandler_Helper:
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	a, (0xfda1:16)
	and	a, 192
	ldfr_berp	a, 251
	ldw	wa, 128
	calr	ExtData_ToggleTlvBits
	ldw	wa, 64
	calr	ExtData_ToggleTlvBits
	lda	xde, (0xfda1:16)
	ld	c, (xde)
	ld	a, c
	and	a, 192
	cp	a, 192
	jr	nz, ExtData_Voice_FullHandler_Helper_Code_Entry
	bit	7, (MIDI_MSG_DATA3:16)
	jr	z, ExtData_Voice_FullHandler_Helper_Code_Skip
	res	6, c
	jr	ExtData_Voice_FullHandler_Helper_Code_Join
ExtData_Voice_FullHandler_Helper_Code_Skip:
	res	7, c
ExtData_Voice_FullHandler_Helper_Code_Join:
	ld	(xde), c
ExtData_Voice_FullHandler_Helper_Code_Entry:
	ld	(MIDI_MSG_DATA2), (xde)
	ld	c, 0:opc
	ld	(MIDI_MSG_DATA3:16), 0
	ld	l, (xde)
	and	l, 128
	ldto_berp a, 251
	and a, 128
	cp a, l
	jr	z, ExtData_Voice_FullHandler_Helper_Code_Skip2
	set	7, c
	ld	(MIDI_MSG_DATA3:16), c
ExtData_Voice_FullHandler_Helper_Code_Skip2:
	ld	c, (xde)
	and	c, 64
	ldto_berp	a, 251
	and	a, 64
	cp	a, c
	jr	z, ExtData_Voice_FullHandler_Helper_Code_Skip3
	set	6, (MIDI_MSG_DATA3:16)
ExtData_Voice_FullHandler_Helper_Code_Skip3:
	calr	SwbtWr_FlushAndAppendParams
	pop	qiz
	ret
ExtData_Voice_CopyAndJump:
	ld	(MIDI_MSG_DATA2), (37168:16)
	ld	(MIDI_MSG_DATA3), (37169:16)
	jrl	SwbtWr_FlushAndAppendParams
ExtData_Voice_CompareAndDispatch:
	ld	a, (0x912f:16)
	cp	a, 0:i3
	jr	z, ExtData_Voice_CompareAndDispatch_Skip
	cp	a, 1:i3
	ret	nz
	jrl	MidiCh_ConfigVoiceAndParts
ExtData_Voice_CompareAndDispatch_Skip:
	calr	ExtData_Voice_CompareAndDispatch_Helper
	ret
ExtData_Voice_CompareAndDispatch_Helper:
	ld	a, (MIDI_CC_EXPRESSION_VALUE:16)
	set	7, a
	ld	(MIDI_CC_EXPRESSION_PENDING:16), a
	calr	Audio_FlushPendingBankSelects
	ld	(0x917e:16), 176
	ld	(0x917f:16), 0
	ld	(0x9180), (37168:16)
	ld	(0x9181), (37169:16)
	jp	MIDI_LoadParamsAndDispatchCC

MidiChannel_ResetAndConfigure:
	res 7, (0x28ae:16)
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	set 7, a
	ld (MIDI_CC_MODWHEEL_PENDING:16), a
	bit 7, (MIDI_CC_MODWHEEL_VALUE:16)
	ret z
	calr Audio_FlushPendingBankSelects
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 1
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	res 7, a
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	ld e, (MIDI_MSG_DATA2:16)
	extz de
	pushw 0x7f
	ldw wa, 0xb0
	ld bc, 1:i3
	call AddswbWr
	ldmm8 0x917e, MIDI_MSG_STATUS
	ldmm8 0x917f, MIDI_MSG_DATA1
	ldmm8 0x9180, MIDI_MSG_DATA2
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	ret

MidiCh_ConfigVoiceAndParts:
	ld	a, (MIDI_CC_MODWHEEL_PENDING:16)
	res	7, a
	ld	(MIDI_CC_MODWHEEL_PENDING:16), a
	ld	c, (MIDI_CC_MODWHEEL_VALUE:16)
	cp	c, a
	ret	z
	ld	a, (0x28ae:16)
	bit	7, a
	jr	z, MidiChannel_ResetAndConfigure_Entry
	ld	(9828:16), c
	ld	e, (0x28ae:16)
	ld	l, e
	res	7, l
	cp	l, c
	jr	ule, MidiChannel_ResetAndConfigure_Skip
	sub	l, c
	ld	c, l
	jr	MidiChannel_ResetAndConfigure_Join
MidiChannel_ResetAndConfigure_Skip:
	sub	c, l
MidiChannel_ResetAndConfigure_Join:
	cp	c, 16
	jr	c, MidiChannel_ResetAndConfigure_Skip2
	res	7, e
	ld	(0x28ae:16), e
MidiChannel_ResetAndConfigure_Entry:
	ld	(MIDI_CC_MODWHEEL_PENDING), (MIDI_CC_MODWHEEL_VALUE:16)
	set	7, (MIDI_CC_MODWHEEL_VALUE:16)
MidiChannel_ResetAndConfigure_Skip2:
	bit	7, (MIDI_CC_MODWHEEL_VALUE:16)
	ret	z
	calr	Audio_FlushPendingBankSelects
	ld	(MIDI_MSG_STATUS:16), 176
	ld	(MIDI_MSG_DATA1:16), 1
	ld	a, (MIDI_CC_MODWHEEL_VALUE:16)
	res	7, a
	ld	(MIDI_MSG_DATA2:16), a
	ld	(MIDI_MSG_DATA3:16), 127
	calr	SwbtWr_FlushAndAppendParams
	ld	(0x917e), (MIDI_MSG_STATUS:16)
	ld	(0x917f), (MIDI_MSG_DATA1:16)
	ld	(0x9180), (37168:16)
	ld	(0x9181), (37169:16)
	call	MIDI_LoadParamsAndDispatchCC
	ret
MidiCh_IterateVolume_Forward:
	pushw	iz
	ldb_d8	a, (0x9131)
	res	7, a
	cp	a, 0:i3
	jr	z, MidiCh_IterateVolume_Forward_Epilogue
	ld	iz, 0:i3
MidiCh_IterateVolume_Forward_Loop:
	lda_d16	xde, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, MidiCh_IterateVolume_Forward_Epilogue
	cp	a, 2:i3
	jr	nz, MidiCh_IterateVolume_Forward_Skip
	cp	(xde+0x1), 255
	jr	nz, MidiCh_IterateVolume_Forward_Skip2
MidiCh_IterateVolume_Forward_Skip:
	ldmm8	0x917e, MIDI_MSG_STATUS
	ld	(0x917f), (xbc)
	ldmm8	0x9180, 0x9130
	ldmm8	0x9181, 0x9131
	call	MIDI_LoadParamsAndDispatchCC
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	bitm	5, (xhl+0xd)
	jr	nz, MidiCh_IterateVolume_Forward_Skip2
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(MIDI_MSG_DATA1), (xbc)
	ldmm8	MIDI_MSG_DATA2, 0x9130
	ldmm8	MIDI_MSG_DATA3, 0x9131
	calr	SwbtWr_FlushAndAppendParams
MidiCh_IterateVolume_Forward_Skip2:
	inc	1, iz
	cp	iz, 32
	jr	c, MidiCh_IterateVolume_Forward_Loop
MidiCh_IterateVolume_Forward_Epilogue:
	popw	iz
	ret
MidiCh_IterateVolume_Reverse:
	pushw	iz
	ld	iz, 0:i3
MidiCh_IterateVolume_Reverse_Loop:
	lda_d16	xde, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xde
	ld	a, (xbc)
	cp	a, 255
	jr	z, MidiCh_IterateVolume_Reverse_Epilogue
	cp	a, 2:i3
	jr	nz, MidiCh_IterateVolume_Reverse_Skip
	cp	(xde+0x1), 255
	jr	nz, MidiCh_IterateVolume_Reverse_Skip2
MidiCh_IterateVolume_Reverse_Skip:
	ldmm8	0x917e, MIDI_MSG_STATUS
	ld	(0x917f), (xbc)
	ldmm8	0x9180, 0x9130
	ldmm8	0x9181, 0x9131
	call	MIDI_LoadParamsAndDispatchCC
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	bitm	5, (xhl+0xd)
	jr	nz, MidiCh_IterateVolume_Reverse_Skip2
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(MIDI_MSG_DATA1), (xbc)
	ldmm8	MIDI_MSG_DATA2, 0x9130
	ldmm8	MIDI_MSG_DATA3, 0x9131
	calr	SwbtWr_CheckBufferOverflow
MidiCh_IterateVolume_Reverse_Skip2:
	inc	1, iz
	cp	iz, 32
	jr	c, MidiCh_IterateVolume_Reverse_Loop
MidiCh_IterateVolume_Reverse_Epilogue:
	popw	iz
	ret
MidiCh_IteratePan_Forward:
	pushw	iz
	ldb_d8	a, (0x9131)
	res	7, a
	cp	a, 0:i3
	jrl	z, MidiCh_IteratePan_Forward_Epilogue
	ld	iz, 0:i3
MidiCh_IteratePan_Forward_Loop:
	lda_d16	xbc, (0x90fb)
	ld	wa, iz
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, MidiCh_IteratePan_Forward_Epilogue
	cp	a, 2:i3
	jr	nz, MidiCh_IteratePan_Forward_Skip
	cp	(xbc+0x1), 255
	jr	nz, MidiCh_IteratePan_Forward_Skip2
MidiCh_IteratePan_Forward_Skip:
	extz	wa
	calr	PanelTlv_PayloadOfTag
	bitm	4, (xhl+0xc)
	jr	z, MidiCh_IteratePan_Forward_Skip2
	ldmm8	0x917e, MIDI_MSG_STATUS
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(0x917f), (xbc)
	ldmm8	0x9180, 0x9130
	ldmm8	0x9181, 0x9131
	call	MIDI_LoadParamsAndDispatchCC
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	bitm	5, (xhl+0xd)
	jr	nz, MidiCh_IteratePan_Forward_Skip2
	lda_d16	xwa, (0x90fb)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	(MIDI_MSG_DATA1), (xbc)
	ldmm8	MIDI_MSG_DATA2, 0x9130
	ldmm8	MIDI_MSG_DATA3, 0x9131
	calr	SwbtWr_FlushAndAppendParams
MidiCh_IteratePan_Forward_Skip2:
	inc	1, iz
	cp	iz, 32
	jrl	c, MidiCh_IteratePan_Forward_Loop
MidiCh_IteratePan_Forward_Epilogue:
	popw	iz
	ret
MidiCh_IterateExpression:
	dec	2, xsp
	push	xiz
	ldb_d8	a, (0x9131)
	res	7, a
	cp	a, 0:i3
	jr	z, MidiCh_IterateExpression_Epilogue
	ldw	(xsp+0x4), 0
MidiCh_IterateExpression_Loop:
	lda_d16	xbc, (0x90fb)
	ld	wa, (xsp+0x4)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	a, 255
	jr	z, MidiCh_IterateExpression_Epilogue
	extz	wa
	calr	PanelTlv_PayloadOfTag
	ld	xiz, xhl
	cp	xiz, 0xffffffff
	jr	z, MidiCh_IterateExpression_Skip
	bitm	5, (xiz+0x4)
	jr	z, MidiCh_IterateExpression_Skip
	ldmm8	0x917e, MIDI_MSG_STATUS
	lda_d16	xwa, (0x90fb)
	ld	bc, (xsp+0x4)
	extz	xbc
	add	xbc, xwa
	ld	(0x917f), (xbc)
	ldmm8	0x9180, 0x9130
	ldmm8	0x9181, 0x9131
	call	MIDI_LoadParamsAndDispatchCC
	bitm	5, (xiz+0xd)
	jr	nz, MidiCh_IterateExpression_Skip
	lda_d16	xwa, (0x90fb)
	ld	bc, (xsp+0x4)
	extz	xbc
	add	xbc, xwa
	ld	(MIDI_MSG_DATA1), (xbc)
	ldmm8	MIDI_MSG_DATA2, 0x9130
	ldmm8	MIDI_MSG_DATA3, 0x9131
	calr	SwbtWr_FlushAndAppendParams
MidiCh_IterateExpression_Skip:
	incm	1, (xsp+0x4)
	cpw	(xsp+0x4), 32
	jr	c, MidiCh_IterateExpression_Loop
MidiCh_IterateExpression_Epilogue:
	pop	xiz
	inc	2, xsp
	ret

CtrlPanel_RefreshIndicatorState:
	push xiz
	ld xiz, xwa
	ld xwa, xiz
	ld xbc, 0x8f62
	calr CtrlPanel_CompareAndUpdateIndicators
	ld xwa, xiz
	calr CtrlPanel_BuildIndicatorBitmask
	ld xwa, xhl
	calr Part_BitmaskToIndexList
	ld xiy, xiz
	ld xix, 0x8f62
	ldw bc, 0xb3
	ldirw
	pop xiz
	ret

CtrlPanel_CompareAndUpdateIndicators:
	lda xsp, (xsp-370)
	push xiz
	ld	(xsp+366), xbc
	ld	(xsp+370), xwa
	ld XWA, (xsp + 0x0172)
	calr CtrlPanel_BuildIndicatorBitmask
	ld (xsp + 4), xhl
	ld XWA, (xsp + 0x016e)
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x80
	calr Audio_IteratePartsWithExpression
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ld wa, 0:i3
	calr Audio_IteratePartsWithVolume
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	extz bc
	ld wa, 0:i3
	calr Audio_IteratePartsWithPan
	ld XWA, (xsp + 0x016e)
	ld c, (xwa + 1)
	cp c, 0xff
	jr z, CtrlPanelRefresh_ProcessRemoved
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_ProcessRemoved:
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ld a, (MIDI_CC_BREATH_VALUE:16)
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithExpression
	ld a, (MIDI_CC_FOOT_VALUE:16)
	res 7, a
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithVolume
	ld a, (MIDI_CC_VOLUME_VALUE:16)
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr Audio_IteratePartsWithPan
	ld XWA, (xsp + 0x0172)
	lda xbc, (xwa + 1)
	ld XWA, (xsp + 0x016e)
	cp (xwa + 1), 0xff
	jr nz, CtrlPanelRefresh_DispatchVoiceCC
	cp (xbc), 0xff
	jr nz, CtrlPanelRefresh_CheckMigration

CtrlPanelRefresh_DispatchVoiceCC:
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	res 7, a
	extz wa
	ld c, (xbc)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_CheckMigration:
	ld XBC, (xsp + 0x016e)
	cp (xbc + 1), 0xff
	jr nz, CtrlPanelRefresh_Done
	ld XWA, (xsp + 0x0172)
	cp (xwa + 1), 0xff
	jr z, CtrlPanelRefresh_Done
	ld xiy, xbc
	lda xix, (xsp + 8)
	ldw bc, 0xb3
	ldirw
	lda xwa, (xsp + 8)
	ormi8 (xwa), 0x7
	calr CtrlPanel_BuildIndicatorBitmask
	ld xiz, xhl
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, xiz
	calr Part_BitmaskToIndexList
	ld XWA, (xsp + 0x0172)
	ld c, (xwa + 1)
	extz bc
	ldw wa, 0x7f
	calr MIDI_DispatchVoiceParamCC
	ld xwa, (xsp + 4)
	xor xwa, xiz
	and xwa, (xsp + 4)
	calr Part_BitmaskToIndexList
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	res 7, a
	extz wa
	ld XBC, (xsp + 0x0172)
	ld c, (xbc + 1)
	extz bc
	calr MIDI_DispatchVoiceParamCC

CtrlPanelRefresh_Done:
	pop xiz
	lda xsp, (xsp+370)
	ret

CtrlPanel_BuildIndicatorBitmask:
	push xiz
	ld xiz, 0:i3
	lda xde, (CtrlPanel_BuildIndicatorBitmask_Data:24)
	ld c, (xwa + 1)
	cp c, 0xff
	jr nz, IndBitmask_LookupByChannel
	ld c, (xwa)
	ld xiz, 0:i3
	ldfr_berp C, 0xf8
	and xiz, 0x7
	ld	a, (xwa+190)
	cp a, 0xff
	jr z, IndBitmask_ReturnResult
	extz wa
	ld	a, (xde+wa)
	jr IndBitmask_ApplyResult

IndBitmask_LookupByChannel:
	extz bc
	ld	a, (xde+bc)

IndBitmask_ApplyResult:
	call CtrlPanel_LookupIndicatorEntry
	or xiz, xhl

IndBitmask_ReturnResult:
	ld xhl, xiz
	pop xiz
	ret

Part_BitmaskToIndexList:
	ld iy, 0:i3
	lda xde, (0x90fb:16)
	ld (xde), 0xff
	ld hl, 0:i3

BitmaskToIndex_ScanLoop:
	or xwa, xwa
	jr z, BitmaskToIndex_Terminate
	bit 0, wa
	jr z, BitmaskToIndex_ShiftAndAdvance
	ld bc, iy
	inc 1, iy
	ld ix, bc
	extz xix
	add xix, xde
	ld c, l
	ld (xix), c

BitmaskToIndex_ShiftAndAdvance:
	srl xwa, 1
	inc 1, hl
	cp hl, 0x20
	jr c, BitmaskToIndex_ScanLoop

BitmaskToIndex_Terminate:
	ld wa, iy
	extz xwa
	add xwa, xde
	ld (xwa), 0xff
	ret

Audio_IteratePartsWithVolume:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	ld iz, 0:i3

VolumeIter_NextPart:
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, VolumeIter_Done
	cp a, 2:i3
	jr nz, VolumeIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, VolumeIter_AdvancePart

VolumeIter_ApplyParam:
	ld (0x917e:16), 178
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 5, (xhl + 13)
	jr nz, VolumeIter_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

VolumeIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VolumeIter_NextPart

VolumeIter_Done:
	popw iz
	inc 4, xsp
	ret

Audio_IteratePartsWithExpression:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld c, a
	sll c, 6
	and c, 0x40
	ldfr_berp C, 0xfa
	srl a, 1
	ldfr_berp A, 0xfb
	res_erpb 0xfb, 0x07
	ldto_berp C, 0xfb
	extz bc
	sll bc, 8
	ldto_berp A, 0xfa
	extz wa
	add wa, bc
	cp wa, 0x7f40
	jr c, ExprIter_Start
	ldi_erpb 0xfb, 0x7f
	ldi_erpb 0xfa, 0x7f

ExprIter_Start:
	ld iz, 0:i3

ExprIter_NextPart:
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 0xff
	jr z, ExprIter_Done
	cp a, 2:i3
	jr nz, ExprIter_ApplyParam
	cp (xsp + 4), 0x2
	jr nz, ExprIter_AdvancePart

ExprIter_ApplyParam:
	ld (0x917e:16), 177
	mrib4 0x81, 0x19, 0x7f, 0x91
	ldto_berp A, 0xfa
	ld (0x9180:16), a
	ldto_berp A, 0xfb
	ld (0x9181:16), a
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 5, (xhl + 13)
	jr nz, ExprIter_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

ExprIter_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, ExprIter_NextPart

ExprIter_Done:
	pop xiz
	inc 2, xsp
	ret

Audio_IteratePartsWithPan:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), c
	ld (xsp + 4), a
	ld iz, 0:i3

PanIter_NextPart:
	lda xbc, (0x90fb:16)
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, PanIter_Done
	cp a, 2:i3
	jr nz, PanIter_ApplyParam
	cp (xsp + 2), 0x2
	jr nz, MidiLoadParams_ContinueLoop

PanIter_ApplyParam:
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 4, (xhl + 12)
	jr z, MidiLoadParams_ContinueLoop
	ld (0x917e:16), 180
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x04, 0x19, 0x80, 0x91
	ld (0x9181:16), 255
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 5, (xhl + 13)
	jr nz, MidiLoadParams_ContinueLoop
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

MidiLoadParams_ContinueLoop:
	inc 1, iz
	cp iz, 0x20
	jrl c, PanIter_NextPart

PanIter_Done:
	popw iz
	inc 4, xsp
	ret

MIDI_DispatchVoiceParamCC:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	cp (0xfd32:16), 183
	jr nz, VoiceParamCC_Done
	ld iz, 0:i3

VoiceParamCC_NextPart:
	lda xbc, (0x90fb:16)
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xff
	jr z, VoiceParamCC_Done
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 5, (xhl + 4)
	jr z, VoiceParamCC_AdvancePart
	ld (0x917e:16), 179
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x7f, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x80, 0x91
	ld (0x9181:16), 127
	call MIDI_LoadParamsAndDispatchCC
	lda xwa, (0x90fb:16)
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr PanelTlv_PayloadOfTag
	bitm 5, (xhl + 13)
	jr nz, VoiceParamCC_AdvancePart
	ld a, (0x917e:16)
	extz wa
	ld c, (0x917f:16)
	extz bc
	ld e, (0x9180:16)
	extz de
	ld l, (0x9181:16)
	extz hl
	pushw hl
	call AddswbWr

VoiceParamCC_AdvancePart:
	inc 1, iz
	cp iz, 0x20
	jr c, VoiceParamCC_NextPart

VoiceParamCC_Done:
	popw iz
	inc 2, xsp
	ret

UIState_CheckAndRenderBitmap:
	pushw	iz
	cp	(SWBTWR_PAYLOAD_1:16), 2
	jr	nz, UIState_CheckAndRenderBitmap_Epilogue
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 255
	jr	z, UIState_CheckAndRenderBitmap_Epilogue
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, 255
	cp	a, 183
	jr	z, UIState_CheckAndRenderBitmap_Skip
	cp	a, 182
	jr	nz, UIState_CheckAndRenderBitmap_Epilogue
	ld	iz, 0:i3
UIState_CheckAndRenderBitmap_Loop:
	pushw	3
	ld	wa, iz
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	inc	1, iz
	cp	iz, 15
	jr	ule, UIState_CheckAndRenderBitmap_Loop
	jr	UIState_CheckAndRenderBitmap_Epilogue
UIState_CheckAndRenderBitmap_Skip:
	ld	xwa, 0x4001
	ldw	bc, 127
	ld	de, 3:i3
	call	SoundParam_NotifyChange
UIState_CheckAndRenderBitmap_Epilogue:
	popw	iz
	ret
UIState_RenderBitmapData:
	cp	(SWBTWR_PAYLOAD_1:16), 5
	jr	nz, UIState_RenderBitmapData_Skip
	ld	a, (SWBTWR_PAYLOAD_3:16)
	res	7, a
	cp	a, 0:i3
	jr	z, UIState_RenderBitmapData_Skip
	ld	c, (SWBTWR_PAYLOAD_2:16)
	res	7, c
	cp	c, 0:i3
	jr	z, UIState_RenderBitmapData_Skip
	ld	a, (SWBTWR_EVENT_TYPE:16)
	extz	wa
	lda	xde, (0x918d:16)
	extz	xwa
	add	xwa, xde
	ld	(xwa), c
UIState_RenderBitmapData_Skip:
	cp	(SWBTWR_PAYLOAD_1:16), 12
	jr	nz, UIState_RenderBitmapData_Skip2
	bit	4, (SWBTWR_PAYLOAD_3:16)
	jr	z, UIState_RenderBitmapData_Skip2
	bit	4, (SWBTWR_PAYLOAD_2:16)
	jr	nz, UIState_RenderBitmapData_Skip2
	ldb_d8	a, (SWBTWR_EVENT_TYPE)
	extz	wa
	pushw	3
	ldw	bc, 0x1b2
	ld	de, 0:i3
	call	SndParam_NotifyAndReturn
UIState_RenderBitmapData_Skip2:
	cp	(SWBTWR_PAYLOAD_1:16), 4
	ret	nz
	bit	5, (SWBTWR_PAYLOAD_3:16)
	ret	z
	bit	5, (SWBTWR_PAYLOAD_2:16)
	ret	nz
	ldb_d8	a, (SWBTWR_EVENT_TYPE)
	extz	wa
	pushw	3
	ldw	bc, 11
	ldw	de, 127
	call	SndParam_NotifyAndReturn
	ret
ToshiCmd_DefaultHandler_Ret:
	ret

SndParam_FetchSequencerParams:
	ld wa, (0x9133:16)
	ld bc, wa
	inc 1, wa
	ld (0x9133:16), wa
	lda xwa, (0xc039:16)
	extz xbc
	add xbc, xwa
	mrib4 0x81, 0x19, 0x27, 0x91
	ld a, (MIDI_MSG_STATUS:16)
	extz wa
	calr PanelTlv_PayloadOfTag
	ld (0x912b:16), xhl
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	lda xbc, (0xc039:16)
	extz xde
	add xde, xbc
	ld a, (xde)
	ld (MIDI_MSG_DATA1:16), a
	ld (0x912f:16), a
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x30, 0x91
	ld (MIDI_MSG_DATA2:16), 0
	ld wa, (0x9133:16)
	ld de, wa
	inc 1, wa
	ld (0x9133:16), wa
	extz xde
	add xde, xbc
	mrib4 0x82, 0x19, 0x31, 0x91
	ld (MIDI_MSG_DATA3:16), 0
	ret

SndParam_WriteLookupAndStore:
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	ret	z
	ld	a, (0x912f:16)
	extz	wa
	ld	(0x9132), (xhl+wa)
	ret

SwbtWr_FlushAndAppendParams:
	cp (MIDI_MSG_DATA3:16), 0
	ret z
	cpw (0x90de:16), 508
	jr c, SwbtWr_FlushDone
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

SwbtWr_FlushDone:
	calr SwbtWr_AppendFixedParamBlock
	ret

SwbtWr_CheckBufferOverflow:
	cpw	(0x90de:16), 508
	jr	c, SwbtWr_FlushAndAppendParams_Skip
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitBothBanks
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldw	(0x90de:16), 0
SwbtWr_FlushAndAppendParams_Skip:
	jrl	SwbtWr_AppendFixedParamBlock

SwbtWr_WriteParamBlock:
	cpw (0x90de:16), 508
	jr c, SwbtWr_WriteParamBlock_Body
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldw (0x90de:16), 0

SwbtWr_WriteParamBlock_Body:
	jrl SwbtWr_AppendFixedParamBlock
; ExtData_ToggleTlvBits: XORs the panel TLV byte (tag MIDI_MSG_STATUS, offset (0x912F)) with the incoming bits
;   (0x9130) & (0x9131) when mask A is enabled; if the byte changed, ORs the changed bits (within A) into
;   MIDI_MSG_DATA3 and copies the byte to (0x9132) and MIDI_MSG_DATA2. Basis: callers + body -- ExtData_* handlers
;   call it per field mask and then flush with SwbtWr_FlushAndAppendParams.
ExtData_ToggleTlvBits:
	dec 2, xsp
	ld (xsp), a
	ld c, (0x9131:16)
	ld a, c
	and a, (xsp)
	jr z, Voice_Update_Return
	ld a, (0x9130:16)
	and a, c
	jr z, Voice_Update_Return
	ld a, (MIDI_MSG_STATUS:16)
	extz wa
	calr PanelTlv_PayloadOfTag
	cp xhl, 0xffffffff
	jr z, Voice_Update_Return
	ld a, (0x912f:16)
	extz wa
	lda	xhl, (xhl+wa)
	ld a, (0x9130:16)
	and a, (0x9131:16)
	xor (xhl), a
	ld c, (0x9132:16)
	cp (xhl), c
	jr z, Voice_Update_Return
	ld a, (xhl)
	xor a, c
	and a, (xsp)
	or (MIDI_MSG_DATA3:16), a
	mrib4 0x83, 0x19, 0x32, 0x91
	mrib4 0x83, 0x19, 0x29, 0x91

Voice_Update_Return:
	inc 2, xsp
	ret

VoiceParam_CompareAndUpdate:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	and	a, (xsp)
	jr	z, VoiceParam_CompareAndUpdate_Epilogue
	ld	a, (37168:16)
	and	a, (xsp)
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFC972C-0xFC9746 (26 B), unreached CODE-territory, was disassembled as 9 plausible-but-dead instruction lines; per=67% dist=15 near VoiceParam_CompareAndUpdate+17
	jr	z, VoiceParam_CompareAndUpdate_Epilogue
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 4294967295
	jr	z, VoiceParam_CompareAndUpdate_Epilogue
	ld	a, (37167:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld	a, (xsp)
	cpl	a
	and	a, (xhl)
	or	a, (0x9130:16)
	ld	c, a
	ld	a, (0x9132:16)
	cp	c, a
	jr	z, VoiceParam_CompareAndUpdate_Epilogue
	ld	(xhl), c
	ld	(0x9132:16), c
	ld	(MIDI_MSG_DATA2:16), c
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
VoiceParam_CompareAndUpdate_Epilogue:
	inc	2, xsp
	ret
; ExtData_SetTlvField: If mask A is enabled in (0x9131), replaces the field A of the panel TLV byte (tag
;   MIDI_MSG_STATUS, offset (0x912F)) with (0x9130); if the byte changed, stores it in (0x9132) and MIDI_MSG_DATA2 and
;   ORs A into MIDI_MSG_DATA3. Basis: callers + body -- ExtData_* handlers call it per field mask and then flush.
ExtData_SetTlvField:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	and	a, (xsp)
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xFC977B-0xFC9795 (26 B), unreached CODE-territory, was disassembled as 9 plausible-but-dead instruction lines; per=67% dist=15 near VoiceParam_CompareAndUpdate+96
	jr	z, ExtData_SetTlvField_Epilogue
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 4294967295
	jr	z, ExtData_SetTlvField_Epilogue
	ld	a, (37167:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld	a, (xsp)
	cpl	a
	and	a, (xhl)
	or	a, (0x9130:16)
	ld	c, a
	ld	a, (0x9132:16)
	cp	c, a
	jr	z, ExtData_SetTlvField_Epilogue
	ld	(xhl), c
	ld	(0x9132:16), c
	ld	(MIDI_MSG_DATA2:16), c
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
ExtData_SetTlvField_Epilogue:
	inc	2, xsp
	ret
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	and	a, (xsp)
	jr	z, SwbtWr_WriteParamBlock_Epilogue
	ld	a, (37168:16)
	and	a, (xsp)
	jr	z, SwbtWr_WriteParamBlock_Epilogue
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jr	z, SwbtWr_WriteParamBlock_Epilogue
	ld	a, (0x912f:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld c, (xsp)
	cpl	c
	ld	e, c
	and	e, (xhl)
	or	e, (0x9130:16)
	ld	a, (0x9132:16)
	cp	e, a
	jr	nz, SwbtWr_WriteParamBlock_Skip
	and	e, c
SwbtWr_WriteParamBlock_Skip:
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(MIDI_MSG_DATA2:16), e
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
SwbtWr_WriteParamBlock_Epilogue:
	inc	2, xsp
	ret
ExtData_ToneParam_AltBody_Helper:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	and	a, (xsp)
	jr	z, SwbtWr_WriteParamBlock_Epilogue2
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jr	z, SwbtWr_WriteParamBlock_Epilogue2
	ld	a, (0x912f:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld c, (xsp)
	cpl	c
	ld	e, c
	and	e, (xhl)
	or	e, (0x9130:16)
	ld	a, (0x9132:16)
	cp	e, a
	jr	nz, SwbtWr_WriteParamBlock_Skip2
	and	e, c
SwbtWr_WriteParamBlock_Skip2:
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(MIDI_MSG_DATA2:16), e
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
SwbtWr_WriteParamBlock_Epilogue2:
	inc	2, xsp
	ret
; ExtData_StepTlvField: Adds the step (0x9153) to field C of the panel TLV byte (tag MIDI_MSG_STATUS, offset
;   (0x912F)); a sum >= the limit (0x9154) becomes the fallback (0x9155). Gated by A in (0x9131) and (0x9130); if the
;   byte changed it goes to (0x9132) and MIDI_MSG_DATA2 and C is ORed into MIDI_MSG_DATA3. Basis: callers + body --
;   the ExtData_* handlers load step/limit/fallback, call it, then flush.
ExtData_StepTlvField:
	dec	2, xsp
	ld	(xsp), c
	ld	c, (0x9131:16)
	and	c, a
	jr	z, SwbtWr_WriteParamBlock_Epilogue3
	ld	c, (0x9130:16)
	and	c, a
	jr	z, SwbtWr_WriteParamBlock_Epilogue3
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jr	z, SwbtWr_WriteParamBlock_Epilogue3
	ld	a, (0x912f:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld e, (xhl)
	and	e, (xsp)
	ld	c, (0x9153:16)
	ld	a, e
	add	a, c
	cp	a, (37204:16)
	jr	nc, SwbtWr_WriteParamBlock_Skip3
	add	e, c
	jr	SwbtWr_WriteParamBlock_Join
SwbtWr_WriteParamBlock_Skip3:
	ld	e, (0x9155:16)
SwbtWr_WriteParamBlock_Join:
	ld	a, (xsp)
	cpl	a
	and	a, (xhl)
	or	e, a
	ld	a, (37170:16)
	cp	e, a
	jr	z, SwbtWr_WriteParamBlock_Epilogue3
	ld	(xhl), e
	ld	(0x9132:16), e
	ld	(MIDI_MSG_DATA2:16), e
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
SwbtWr_WriteParamBlock_Epilogue3:
	inc	2, xsp
	ret
; ExtData_ForceSetTlvField: If mask A is enabled in (0x9131), sets field A of the panel TLV byte (tag MIDI_MSG_STATUS,
;   offset (0x912F)) to (0x9130) & A and, unlike ExtData_SetTlvField, always records it -- byte to (0x9132) and
;   MIDI_MSG_DATA2, A ORed into MIDI_MSG_DATA3 -- even when the byte did not change. Basis: callers + body --
;   ExtData_Voice_FullHandler (tag 0x98 offsets 1 and 2, masks 0x80 / 0x40, 0x80) and ExtData_Voice_CheckMode3_Helper
;   (mask 8) call it per field before flushing, exactly as the ExtData_SetTlvField callers do.
ExtData_ForceSetTlvField:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (0x9131:16)
	and	a, (xsp)
	jr	z, SwbtWr_WriteParamBlock_Epilogue4
	ld	a, (MIDI_MSG_STATUS:16)
	extz	wa
	calr	PanelTlv_PayloadOfTag
	cp	xhl, 0xffffffff
	jr	z, SwbtWr_WriteParamBlock_Epilogue4
	ld	a, (0x912f:16)
	extz	wa
	lda	xhl, (xhl+wa)
	ld a, (xsp)
	cpl	a
	and	a, (xhl)
	ld	c, a
	ld	a, (37168:16)
	and	a, (xsp)
	or	a, c
	ld	(xhl), a
	ld	(0x9132:16), a
	ld	(MIDI_MSG_DATA2:16), a
	ld	a, (xsp)
	or	(MIDI_MSG_DATA3:16), a
SwbtWr_WriteParamBlock_Epilogue4:
	inc	2, xsp
	ret

ToneGen_ApplyVoiceParams:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	cp (xsp + 10), 0x0
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 4)
	extz wa
	calr PanelTlv_PayloadOfTag
	cp xhl, 0xffffffff
	jr z, ToneGen_DispatchStartVoice
	ld a, (xsp + 2)
	extz wa
	lda	xhl, (xhl+wa)
	ld c, (xhl)
	ld (0x9132:16), c
	ld e, (xsp)
	and e, (xsp + 10)
	ld a, (xsp + 10)
	cpl a
	and a, c
	or a, e
	ld e, a
	xor a, c
	and a, (xsp + 10)
	jr z, ToneGen_DispatchStartVoice
	ld (xhl), e
	mrdb5 0x8f, 0x04, 0x19, 0x27, 0x91
	mrdb5 0x8f, 0x02, 0x19, 0x28, 0x91
	ld (MIDI_MSG_DATA2:16), e
	ld (MIDI_MSG_DATA3:16), a

ToneGen_DispatchStartVoice:
	inc 6, xsp
	retd 0x2
	dec 6, xsp
	pushw_erp 0xfa
	cp (SWBTWR_PAYLOAD_1:16), 3
	jr nz, ToneGen_Dispatch_Return
	bit 0, (SWBTWR_PAYLOAD_3:16)
	jr z, ToneGen_Dispatch_Return
	ldw wa, 0x90
	calr PanelTlv_PayloadOfTag
	ld (xsp + 2), xhl
	ld xbc, (xsp + 2)
	ld a, (xbc)
	ldfr_berp A, 0xfb
	ld a, (xbc + 1)
	ld (xsp + 6), a
	call ToneGen_DispatchByMode
	ldto_berp C, 0xfb
	ld xwa, (xsp + 2)
	xor c, (xwa)
	and c, 0x3
	jr z, ToneGen_Dispatch_Return
	ld c, (xsp + 6)
	xor c, (xwa + 1)
	bit 1, c
	jr z, ToneGen_Dispatch_Return
	ld e, (xwa)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	ld bc, 0:i3
	call AddswbWr
	ld xwa, (xsp + 2)
	ld e, (xwa + 1)
	extz de
	pushw 0x1f
	ldw wa, 0x90
	ld bc, 1:i3
	call AddswbWr

ToneGen_Dispatch_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

SwbtWr_NullRet:
	ret

Audio_FlushPendingBankSelects:
	ld a, (MIDI_CC_EXPRESSION_PENDING:16)
	bit 7, a
	jr z, BankFlush_CheckChannel1
	res 7, a
	ld (MIDI_CC_EXPRESSION_PENDING:16), a
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 0
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	calr SwbtWr_FlushAndAppendParams

BankFlush_CheckChannel1:
	ld a, (MIDI_CC_MODWHEEL_PENDING:16)
	bit 7, a
	ret z
	res 7, a
	ld (MIDI_CC_MODWHEEL_PENDING:16), a
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 1
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	calr SwbtWr_FlushAndAppendParams
	ret
UIWidget_MidiStreamControl:
	cp	(SWBTWR_PAYLOAD_1:16), 0
	ret	nz
	ldb_d8	a, (SWBTWR_PAYLOAD_3)
	and	a, 3
	call	nz, (MidiCC_ClearReceivedBankSelects:24)
	bit	2, (SWBTWR_PAYLOAD_3:16)
	ret	z
	bit	2, (SWBTWR_PAYLOAD_2:16)
	ret	nz
	set	4, (0x90f9:16)
	call	SeqTimer_UpdateTempoReg
	res	4, (0x90f9:16)
	ret
; MidiCC_ClearReceivedBankSelects: Clears the received bank selects: the 32 two-byte CC32/CC0 cells and the 32
;   part banks that MidiCC_ApplyBankSelect fills (v10/v9 0x93D2 and 0x9412, v7 0x9336 and 0x9376). Basis: caller +
;   body -- UIWidget_MidiStreamControl calls it when bits 0-1 of SWBTWR_PAYLOAD_3 are non-zero.
MidiCC_ClearReceivedBankSelects:
	ld	wa, 0:i3
	lda_d16	xbc, (0x93d2)
MidiCC_ClearReceivedBankSelects_Loop:
	ld	(xbc+), 0
	ld	(xbc+), 0
	inc	1, wa
	cp	wa, 32
	jr	c, MidiCC_ClearReceivedBankSelects_Loop
	ld	wa, 0:i3
	lda_d16	xbc, (0x9412)
MidiCC_ClearReceivedBankSelects_Loop2:
	ld	(xbc+), 0
	inc	1, wa
	cp	wa, 32
	jr	c, MidiCC_ClearReceivedBankSelects_Loop2
	ret

SndParam_ApplyAndFetch:
	dec 6, xsp
	lda xwa, (xsp)
	lda xde, (0x90ea:16)
	ld c, (xde)
	ld (xwa), c
	ld c, (xde + 1)
	ld (xwa + 1), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_CheckRhythm
	call SndParam_ApplyProgramChange
	lda xde, (0x90ee:16)
	lda xbc, (xsp)
	ld a, (xbc + 3)
	ld (xde), a
	ld a, (xbc + 4)
	ld (xde + 1), a
	jr SndParam_ApplyDone

SndParam_CheckRhythm:
	cp c, 0x48
	call z, (Rhythm_LookupTempoVelocity_Wrap:24)

SndParam_ApplyDone:
	inc 6, xsp
	ret

SndParam_ApplyFromPointer:
	push	xiz
	ld	xiz, xwa
	lda	xde, (xiz+2)
	ld	a, (xde)
	cp	a, 31
	jr	ugt, SndParam_ApplyAndFetch_Skip
	ld	xwa, xiz
	call	SndParam_ApplyProgramChange
	jr	SndParam_ApplyAndFetch_Epilogue
SndParam_ApplyAndFetch_Skip:
	cp	a, 72
	jr	nz, SndParam_ApplyAndFetch_Epilogue
	lda	xbc, (0x90ea:16)
	ld	a, (xiz)
	ld	(xbc), a
	ld	a, (xiz+1)
	ld	(xbc+1), a
	ld	a, (xde)
	ld	(xbc+2), a
	call	Rhythm_LookupTempoVelocity_Wrap
	lda	xbc, (0x90ee:16)
	ld	a, (xbc)
	ld	(xiz+3), a
	ld	a, (xbc+1)
	ld	(xiz+4), a
SndParam_ApplyAndFetch_Epilogue:
	pop xiz
	ret

SndParam_FetchAndStore:
	dec 6, xsp
	lda xwa, (xsp)
	lda xde, (0x90ea:16)
	ld c, (xde)
	ld (xwa + 3), c
	ld c, (xde + 1)
	ld (xwa + 4), c
	ld c, (xde + 2)
	ld (xwa + 2), c
	cp c, 0x1f
	jr ugt, SndParam_FetchCheckRhythm
	call SndParam_FetchOscTableEntry
	lda xde, (0x90ee:16)
	lda xbc, (xsp)
	ld a, (xbc)
	ld (xde), a
	ld a, (xbc + 1)
	ld (xde + 1), a
	jr SndParam_FetchDone

SndParam_FetchCheckRhythm:
	cp c, 0x48
	call z, (Rhythm_DispatchNote_Finalize:24)

SndParam_FetchDone:
	inc 6, xsp
	ret

SndParam_ResolveVoiceEntry:
	push xiz
	ld xiz, xwa
	lda xde, (xiz + 2)
	ld a, (xde)
	cp a, 0x1f
	jr ugt, SndParamResolve_CheckRhythm
	ld xwa, xiz
	call SndParam_FetchOscTableEntry
	jr SndParamResolve_Done

SndParamResolve_CheckRhythm:
	cp a, 0x48
	jr nz, SndParamResolve_Done
	lda xbc, (0x90ea:16)
	ld a, (xiz + 3)
	ld (xbc), a
	ld a, (xiz + 4)
	ld (xbc + 1), a
	ld a, (xde)
	ld (xbc + 2), a
	call Rhythm_DispatchNote_Finalize
	lda xbc, (0x90ee:16)
	ld a, (xbc)
	ld (xiz), a
	ld a, (xbc + 1)
	ld (xiz + 1), a

SndParamResolve_Done:
	pop xiz
	ret

SndBuf_WriteParamEntries:
	dec	6, xsp
	lda	xwa, (xsp)
	lda	xde, (0x90ea:16)
	ld	c, (xde)
	ld	(xwa), c
	ld	c, (xde+1)
	ld	(xwa+1), c
	ld	c, (xde+2)
	ld	(xwa+2), c
	ld	c, (xde+3)
	ld	(xwa+5), c
	call	SndParam_CheckAndApplyMode
	lda	xde, (0x90ee:16)
	lda	xbc, (xsp)
	ld	a, (xbc+3)
	ld	(xde), a
	ld	a, (xbc+4)
	ld	(xde+1), a
	inc	6, xsp
	ret
RegBitManip_Handler_4_Helper:
	dec	6, xsp
	lda	xwa, (xsp)
	lda	xde, (0x90ea:16)
	ld	c, (xde)
	ld	(xwa+3), c
	ld	c, (xde+1)
	ld	(xwa+4), c
	ld	c, (xde+2)
	ld	(xwa+5), c
	call	SndParam_ComputeVoiceIndex
	lda	xde, (0x90ee:16)
	lda	xbc, (xsp)
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+2)
	ld	(xde+2), a
	inc	6, xsp
	ret
MidiStream_ExtendedDispatch_Helper3_Helper:
	dec	6, xsp
	ld	a, (0x90f7:16)
	lda	xbc, (0x916f:16)
	lda	xde, (xbc+1)
	cp	a, 31
	jr	ugt, SndBuf_WriteParamEntries_Skip
	lda	xwa, (xsp)
	ld	c, (xbc)
	ld	(xwa+3), c
	ld	c, (xde)
	ld	(xwa+4), c
	ld	(xwa+2), (0x90f7)
	call	SndBuf_WriteParamEntries_Helper
	lda	xbc, (0x90ee:16)
	lda	xwa, (xsp)
	ld	l, (xwa)
	ld	(xbc), l
	lda	xde, (0x916b:16)
	ld	(xde), l
	ld	a, (xwa+1)
	ld	(xbc+1), a
	ld	(xde+1), a
	jr	SndBuf_WriteParamEntries_Join
SndBuf_WriteParamEntries_Skip:
	cp	a, 72
	jr	nz, SndBuf_WriteParamEntries_Join
	lda	xhl, (0x90ea:16)
	ld	a, (xbc)
	ld	(xhl), a
	ld	a, (xde)
	ld	(xhl+1), a
	ld	(xhl+2), (0x90f7)
	nop
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Rhythm_DispatchNote_Finalize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
SndBuf_WriteParamEntries_Join:
	lda	xde, (0x9173:16)
	lda	xbc, (0x90ee:16)
	ld	a, (xbc)
	ld	(xde), a
	ld	a, (xbc+1)
	ld	(xde+1), a
	ld	a, (xbc+3)
	ld	(xde+2), a
	inc	6, xsp
	ret

SndParam_UpdateVoiceEntry:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 4), e
	ld (xsp + 6), c
	ld (xsp + 8), a
	cp (xsp + 8), 0x1f
	jr ugt, SndParamUpdate_Done
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	call ApplyProgramChangeAs_Prologue
	ldib_erp 0xfb, 0
	cp l, 0:i3
	jr z, SndParamUpdate_SetResBit6
	ldi_erpb 0xfb, 0x40

SndParamUpdate_SetResBit6:
	ld (xsp + 2), 0x40
	ld c, (xsp + 4)
	extz bc
	sll bc, 8
	ld a, (xsp + 6)
	extz wa
	add wa, bc
	call MIDI_ParamValidate_CheckBit2
	cp hl, 0:i3
	jr z, SndParamUpdate_DispatchWrite
	ldib_erp 0xfb, 0
	setm 3, (xsp + 2)

SndParamUpdate_DispatchWrite:
	ld a, (xsp + 8)
	extz wa
	ldto_berp E, 0xfb
	extz de
	ld c, (xsp + 2)
	extz bc
	pushw bc
	ld bc, 4:i3
	calr ToneGen_ApplyVoiceParams
	ld a, (MIDI_MSG_DATA3:16)
	and a, 0x48
	call nz, (SwbtWr_FlushAndAppendParams:24)

SndParamUpdate_Done:
	popw_erp 0xfa
	inc 8, xsp
	ret

MIDI_DistributeParamToChannels:
	dec 8, xsp
	ld (xsp + 2), e
	ld (xsp + 4), c
	ld (xsp + 6), a
	cp (xsp + 6), 0x1f
	jr ugt, MidiDistribute_CheckRhythm
	call ApplyProgramChangeAs_DoLookupRe
	ld (xsp), l

MidiDistribute_LookupAndWrite:
	ld a, (xsp + 6)
	extz wa
	calr PanelTlv_CompanionOfPart
	cp xhl, 0xffffffff
	jr z, MidiDistribute_Fallthrough
	ld c, (xsp + 4)
	cp c, (xsp)
	jr ugt, MidiDistribute_Fallthrough
	extz bc
	ld a, (xsp + 2)
	ld	(xhl+bc), a

MidiDistribute_Fallthrough:
	jr MidiDistribute_Done

MidiDistribute_CheckRhythm:
	cp (xsp + 6), 0x48
	jr nz, MidiDistribute_Done
	ld (xsp), 0xf
	jr MidiDistribute_LookupAndWrite

MidiDistribute_Done:
	inc 8, xsp
	ret

VoiceData_DistributeToChannels:
	dec	8, xsp
	ld	(xsp+4), c
	ld	(xsp+6), a
	ld	(xsp+2), 0
	cp	(xsp+6), 31
	jr	ugt, VoiceData_DistributeToChannels_Entry
	call	ApplyProgramChangeAs_DoLookupRe
	ld	(xsp), l
VoiceData_DistributeToChannels_Join:
	ld	a, (xsp+6)
	extz	wa
	calr	PanelTlv_CompanionOfPart
	cp	xhl, 0xffffffff
	jr	z, VoiceData_DistributeToChannels_Skip
	ld	a, (xsp+4)
	cp	a, (xsp)
	jr	ugt, VoiceData_DistributeToChannels_Skip
	extz	wa
	ld	a, (xhl+wa)
	ld (xsp+2), a
VoiceData_DistributeToChannels_Skip:
	ld l, (xsp+2)
	jr VoiceData_DistributeToChannels_Epilogue
VoiceData_DistributeToChannels_Entry:
	.byte 0x8f, 0x06
	push	xsp
	popw	wa
	jr	nz, VoiceData_DistributeToChannels_Skip2
	ld	(xsp), 15
	jr	VoiceData_DistributeToChannels_Join
VoiceData_DistributeToChannels_Skip2:
	ld	l, 0:opc
VoiceData_DistributeToChannels_Epilogue:
	inc	8, xsp
	ret

SwbtWr_AppendFixedParamBlock:
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	lda xbc, (SWBTWR_EVENT_QUEUE:16)
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9127
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9128
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x9129
	ld wa, (0x90de:16)
	ld de, wa
	inc 1, wa
	ld (0x90de:16), wa
	extz xde
	add xde, xbc
	ldmi16 (xde), 0x912a
	ld wa, (0x90de:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	ld (MIDI_MSG_DATA3:16), 0
	ret

; a = tag -> xhl = the RAM address of that record's payload (PanelTlv_PayloadByTag[tag]; 0xFFFFFFFF = none)
PanelTlv_PayloadOfTag:
	extz wa
	sla wa, 2
	lda xbc, (PanelTlv_PayloadByTag:24)
	ld	xhl, (xbc+wa)
	ret

; a = part tag -> xhl = its companion record's payload: PanelTlv_CompanionByPart[a] for a <= 0x1F, tag 0x49's
; payload (RAM 0xFF92) for the style record 0x48, else 0xFFFFFFFF
PanelTlv_CompanionOfPart:
	cp a, 0x1f
	jr ugt, PanelTlv_CompanionOfPart_Style
	extz wa
	sla wa, 2
	lda xbc, (PanelTlv_CompanionByPart:24)
	ld	xhl, (xbc+wa)
	ret

PanelTlv_CompanionOfPart_Style:
	cp a, 0x48
	jr nz, PanelTlv_CompanionOfPart_None
	lda xhl, (0xff92:16)
	ret

PanelTlv_CompanionOfPart_None:
	ld xhl, 0xffffffff
	ret

VoiceChannels_InitPanFromPreset:
	push xiz
	ld iz, (0xf290:16)
	ldiw_erp 0xfa, 0

VoicePanInit_Loop:
	lda xwa, (0x90ce:16)
	ldto_werp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld (xbc), 0x10
	bit 0, iz
	jr z, ToneGen_IncrementAndExit
	lda xwa, (0xf1a0:16)
	ldto_werp BC, 0xfa
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	lda xbc, (VoiceChannels_InitPanFromPreset_Data:24)
	ld	a, (xbc+wa)
	calr PanelTlv_PayloadOfTag
	cp xhl, 0xffffffff
	jr z, ToneGen_IncrementAndExit
	ld c, (xhl + 13)
	ld a, c
	and a, 0xc0
	jr nz, ToneGen_IncrementAndExit
	lda xwa, (0x90ce:16)
	ldto_werp DE, 0xfa
	extz xde
	add xde, xwa
	and c, 0xf
	ld (xde), c

ToneGen_IncrementAndExit:
	srl iz, 1
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x10, 0x00
	jr c, VoicePanInit_Loop
	pop xiz
	ret

; =============================================================================
; SoundPreset_FindMatch -- Find matching preset in ROM tables
; =============================================================================
; Compares current params against all presets to find active one.
; Args: a = type (0/1/2), bc = search params
; Returns: hl = matched index, or 0xffff if no match
SoundPreset_FindMatch:
	cp a, 2:i3
	jrl z, SoundPreset_FindMatch_Combined
	cp a, 1:i3
	jr z, EQPreset_FindMatch
	cp a, 0:i3
	jr z, SoundPreset_FindMatch_Reverb
	ldw hl, 0xffff
	ret

SoundPreset_FindMatch_Reverb:
	pushw iz
	ld iz, 0:i3

ReverbPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, ReverbPreset_Table
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, ReverbPreset_NextEntry
	ld hl, iz
	jr ReverbPreset_SearchDone

ReverbPreset_NextEntry:
	inc 1, iz
	cp iz, 0xa
	jr c, ReverbPreset_SearchLoop
	ldw hl, 0xffff

ReverbPreset_SearchDone:
	popw iz
	ret

EQPreset_FindMatch:
	pushw iz
	ld iz, 0:i3

EQPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, EQPreset_Table
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, EQPreset_NextEntry
	ld hl, iz
	jr EQPreset_SearchDone

EQPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, EQPreset_SearchLoop
	ldw hl, 0xffff

EQPreset_SearchDone:
	popw iz
	ret

SoundPreset_FindMatch_Combined:
	pushw iz
	ld iz, 0:i3

CombinedPreset_SearchLoop:
	pushw 0x18
	pushw 0x0
	pushw 0xfc8e
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, CombinedPreset_Table
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, CombinedPreset_NextEntry
	pushw 0x18
	pushw 0x0
	pushw 0xfca8
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, CombinedPreset_Table
	add xbc, xwa
	ld xwa, (xbc)
	lda xwa, (xwa + 24)
	push xwa
	call Mem_Compare
	add xsp, 0xa
	cp hl, 0:i3
	jr nz, CombinedPreset_NextEntry
	ld hl, iz
	jr SoundPreset_ReturnResult

CombinedPreset_NextEntry:
	inc 1, iz
	cp iz, 0x9
	jr c, CombinedPreset_SearchLoop
	ldw hl, 0xffff

SoundPreset_ReturnResult:
	popw iz
	ret

; =============================================================================
; SoundPreset_Dispatch -- Route preset load by type (reverb/EQ/combined)
; =============================================================================
; Dispatches to the appropriate preset loader based on the type parameter:
;   type 0 -> ReverbPreset_Load (reverb-only, 24 bytes via cmd 0x63)
;   type 1 -> EQPreset_Load (EQ-only, 24 bytes via cmd 0x64)
;   type 2 -> CombinedPreset_Load (reverb+EQ, 48 bytes)
; Args: a = preset type (0/1/2), bc = preset index
; Called from: MainRevEqPresetLoad
SoundPreset_Dispatch:
	ld e, a
	extz bc
	cp e, 2:i3
	jr z, SoundPreset_Dispatch_Combined
	cp e, 1:i3
	jr z, SoundPreset_Dispatch_EQ
	cp e, 0:i3
	ret nz
	ld wa, bc
	jr ReverbPreset_Load

SoundPreset_Dispatch_EQ:
	ld wa, bc
	jr EQPreset_Load

SoundPreset_Dispatch_Combined:
	ld wa, bc
	calr CombinedPreset_Load
	ret

; =============================================================================
; ReverbPreset_Load -- Load and send a reverb preset to the Sub CPU
; =============================================================================
; Reads 24-byte reverb preset from ROM table at 0xedb36c, copies to 0xfc8e,
; then sends all 24 bytes via cmd 0x63 to the Sub CPU DSP ring buffer.
; Preset: B0=algo_id, B1=REV_TIME, B3=PRE_DLY, B4=HI_DAMP, B5=ER_LVL, B22=99
; Args: wa = preset index (0-9)
ReverbPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (ReverbPreset_Table:24)
	ld	xwa, (xbc+wa)
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld iz, 0:i3

ReverbPreset_SendLoop:
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (0xfc8e:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, ReverbPreset_SendLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	ld de, 1:i3
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; EQPreset_Load -- Load and send an EQ preset to the Sub CPU
; =============================================================================
; Reads 24-byte EQ preset from ROM table at 0xedb394, copies to 0xfca8,
; sends via cmd 0x64. EQ uses algo 0x4f with 4 big-endian 16-bit frequencies.
; Args: wa = preset index (0-8)
EQPreset_Load:
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (EQPreset_Table:24)
	ld	xwa, (xbc+wa)
	pushw 0x18
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld iz, 0:i3

EQPreset_SendLoop:
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (0xfca8:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, EQPreset_SendLoop
	ld xwa, 0x4006
	ld bc, 1:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	popw iz
	ret

; =============================================================================
; CombinedPreset_Load -- Load combined reverb+EQ preset (48 bytes)
; =============================================================================
; Reads 48 bytes (24 reverb + 24 EQ) from ROM table at 0xedb3b8.
; Sends reverb with cmd 0x63, EQ (at offset +24) with cmd 0x64.
; Args: wa = preset index (0-8)
CombinedPreset_Load:
	dec 4, xsp
	pushw iz
	extz wa
	sla wa, 2
	lda xbc, (CombinedPreset_Table:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 2), xwa
	pushw 0x18
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xfc8e
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld iz, 0:i3

CombinedPreset_SendReverbLoop:
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (0xfc8e:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x63
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendReverbLoop
	pushw 0x18
	ld xwa, (xsp + 4)
	lda xwa, (xwa + 24)
	push xwa
	pushw 0x0
	pushw 0xfca8
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld iz, 0:i3

CombinedPreset_SendEQLoop:
	ldto_berp C, 0xf8
	extz bc
	lda xwa, (0xfca8:16)
	ld de, iz
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	pushw 0xff
	ldw wa, 0x64
	call AssswbWr
	inc 1, iz
	cp iz, 0x18
	jr c, CombinedPreset_SendEQLoop
	ld xwa, 0x4002
	ldw bc, 0x7f
	ld de, 1:i3
	call SoundParam_NotifyChange
	ld xwa, 0x4006
	ld bc, 1:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	popw iz
	inc 4, xsp
	ret

MIDI_MapCCToIndex:
	cp	a, 102
	jr	z, CombinedPreset_Load_Skip5
	cp	a, 101
	jr	z, CombinedPreset_Load_Skip4
	cp	a, 100
	jr	z, CombinedPreset_Load_Skip3
	cp	a, 99
	jr	z, CombinedPreset_Load_Skip2
	cp	a, 97
	jr	z, CombinedPreset_Load_Skip
	ldw	hl, 0xffff
	ret
CombinedPreset_Load_Skip:
	ld	hl, 0:i3
	ret
CombinedPreset_Load_Skip2:
	ld	hl, 1:i3
	ret
CombinedPreset_Load_Skip3:
	ld	hl, 4:i3
	ret
CombinedPreset_Load_Skip4:
	ld	hl, 2:i3
	ret
CombinedPreset_Load_Skip5:
	ld	hl, 3:i3
	ret
	cp	a, 4:i3
	jr	z, CombinedPreset_Load_Skip10
	cp	a, 3:i3
	jr	z, CombinedPreset_Load_Skip9
	cp	a, 2:i3
	jr	z, CombinedPreset_Load_Skip8
	cp	a, 1:i3
	jr	z, CombinedPreset_Load_Skip7
	cp	a, 0:i3
	jr	z, CombinedPreset_Load_Skip6
	ldw	hl, 0xffff
	ret
CombinedPreset_Load_Skip6:
	ldw	hl, 97
	ret
CombinedPreset_Load_Skip7:
	ldw	hl, 99
	ret
CombinedPreset_Load_Skip8:
	ldw	hl, 101
	ret
CombinedPreset_Load_Skip9:
	ldw	hl, 102
	ret
CombinedPreset_Load_Skip10:
	ldw	hl, 100
	ret

SwbtWr_WriteVoiceParam_PreserveRegs:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_FlushAndAppendParams
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

AudioCtrl_PreserveRegs_PopEpilogue:	.ascii "89:;<=>"
	.byte 0x1d
	cp	(xwa-106), d
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret

SwbtWr_WriteParamBlockSafe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call SwbtWr_WriteParamBlock
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

SndParam_ApplyProgramChange_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x90ea:16), hl
	ld a, (0x90f6:16)
	ld (0x90ec:16), a
	call SndParam_ApplyAndFetch
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ld hl, (0x90ee:16)
	ret

PartCtrl_WriteProgramChange:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld (0x90ea:16), hl
	ld a, (0x90f7:16)
	ld (0x90ec:16), a
	call SndParam_FetchAndStore
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ld hl, (0x90ee:16)
	ret

SndParam_UpdateVoiceEntry_Safe:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, e
	extz bc
	ld e, d
	extz de
	call SndParam_UpdateVoiceEntry
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

MIDI_LoadParamsAndDispatchCC:
	ld bc, (0x917e:16)
	ld de, (0x9180:16)
	call MIDI_ClearGuardAndDispatchCC
	ret

MIDI_ClearGuardAndDispatchCC:
	ld (0x90e5:16), 0

MIDI_DispatchCC_Guarded:
	bit 0, (0xb7e7:16)
	jr nz, MidiGuarded_Return
	bit 4, (0xfd50:16)
	jr nz, MidiGuarded_Return
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	call MIDI_DispatchCC
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa

MidiGuarded_Return:
	ret

MIDI_WriteVoiceParamCC:
	push xix
	pushw wa
	push xhl
	cp d, 0:i3
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, c
	sla hl, 2
	ld xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp xix, 0x9166
	jr z, MidiWriteVoice_Done
	xor h, h
	ld l, b
	ld	a, (xix+hl)
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	ld	(xix+hl), e
	ld (MIDI_MSG_STATUS:16), bc
	ld (MIDI_MSG_DATA2:16), de

MidiWriteVoice_Done:
	pop xhl
	popw wa
	pop xix
	ret

MIDI_WriteVoiceParamFromBuffer:
	ld c, (0x917e:16)
	ld b, (0x917f:16)
	ld e, (0x9180:16)
	ld d, (0x9181:16)

MIDI_WriteVoiceParamDirect:
	push xix
	pushw wa
	pushw hl
	cp d, 0:i3
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, c
	sla hl, 2
	ld xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp xix, 0x9166
	jr z, MidiWriteDirect_Done
	xor h, h
	ld l, b
	ld	a, (xix+hl)
	ld w, d
	xor w, 0xff
	and a, w
	and e, d
	or e, a
	ld	(xix+hl), e
	ld (MIDI_MSG_STATUS:16), bc
	ld (MIDI_MSG_DATA2:16), de

MidiWriteDirect_Done:
	popw hl
	popw wa
	pop xix
	ret

MIDI_SetupChannelParams:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	push xiz
	ld a, c
	extz wa
	ld c, l
	extz bc
	ld e, h
	extz de
	call MIDI_DistributeParamToChannels
	pop xiz
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

Audio_WriteBankSelectParams:
	pushw de
	bit 7, (MIDI_CC_EXPRESSION_PENDING:16)
	jr z, BankSelect_CheckChannel1
	and (MIDI_CC_EXPRESSION_PENDING:16), 127
	ldw (MIDI_MSG_STATUS:16), 176
	ld e, (MIDI_CC_EXPRESSION_PENDING:16)
	ld d, 0x7f:opc
	ld (MIDI_MSG_DATA2:16), de
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_CheckChannel1:
	bit 7, (MIDI_CC_MODWHEEL_PENDING:16)
	jr z, BankSelect_Done
	and (MIDI_CC_MODWHEEL_PENDING:16), 127
	ldw (MIDI_MSG_STATUS:16), 432
	ld e, (MIDI_CC_MODWHEEL_PENDING:16)
	ld d, 0x7f:opc
	ld (MIDI_MSG_DATA2:16), de
	calr SwbtWr_WriteVoiceParam_PreserveRegs

BankSelect_Done:
	popw de
	ret

SeqTimer_UpdateTempoReg:
	bit 2, (0xfd50:16)
	jr nz, SeqTimer_Return
	push xiz
	push xwa
	push xbc
	push xde
	push xhl
	ld xde, 0xfc5a
	ld wa, (xde + 8)
	and wa, 0x1ff
	cp wa, 0x28
	jr c, SeqTimer_ClampToDefault
	cp wa, 0x12c
	jr ule, SeqTimer_ComputeRegValue

SeqTimer_ClampToDefault:
	andmi16 (xde + 8), 0xfe00
	ldw wa, 0x78
	ld (xde + 8), a

SeqTimer_ComputeRegValue:
	ld (0xbd3a:16), wa
	ldw de, 0x40
	mul xwa, de
	ld xde, 0x4c4b400
	call Boot_ReadFDCStatus
	cp l, 4:i3
	jr nz, SeqTimer_AdjustForMode4
	ld xde, 0x3938700

SeqTimer_AdjustForMode4:
	div xde, wa
	ld xbc, xde
	srl xbc, 16
	srl wa, 1
	cp bc, wa
	jr c, SeqTimer_RoundUp
	inc 1, de

SeqTimer_RoundUp:
	ld (146:16), de; LD (TREG5L), DE
	bit 4, (0xfd50:16)
	jr nz, SeqTimer_ClearFlag
	bit 4, (0x90f9:16)
	jr nz, SeqTimer_ClearFlag
	call SeqData_DispatchLoop_Done

SeqTimer_ClearFlag:
	and (0x90f9:16), 239
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xiz

SeqTimer_Return:
	ret

ToneGen_DispatchByMode:
	pushw wa
	pushw hl
	push xix
	ld wa, (0xfc66:16)
	and wa, 0x203
	cp a, 0:i3
	jr nz, RegBitManip_Dispatch
	ld a, 0x1:opc

; Register bit manipulation dispatch
; Index: DRAM[64605] & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
RegBitManip_Dispatch:
	extz xhl
	xor h, h
	ld l, (0xfc5d:16)
	and l, 0x7
	sla hl, 2
	ld xix, RegisterBit_Manipulate_Table
	ld	xix, (xix+hl)
	jp (xix)
; Jump table: 8 x .long code pointer.  Reader RegBitManip_Dispatch:
;   extz xhl / xor h, h / ld l, (0xfc5d:16) / and l, 0x7 / sla hl, 2
;   ld xix, RegisterBit_Manipulate_Table / ld_sril3 XIX, 0x07, 0xf0, 0xec
;   jp (xix)
; Index: bits 0-2 of the byte it loads; 8 entries.
RegisterBit_Manipulate_Table:
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_1
	.long RegBitManip_Handler_0
	.long RegBitManip_Handler_3
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
	.long RegBitManip_Handler_4
RegBitManip_Handler_1:
	bit	0, (0xfc69:16)
	jr	nz, RegBitManip_Handler_0
RegBitManip_Handler_3:
	and	w, 0xfd
RegBitManip_Handler_0:
	pushw	wa
	and	wa, 515
	popw	wa
	jr	nz, RegBitManip_Handler_4
	ld	wa, 1:i3
RegBitManip_Handler_4:
	ld	(0xfc66:16), wa
	pop	xix
	popw	hl
	popw	wa
	ret
VoiceMode_ParamHandler_4_Helper:
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	RegBitManip_Handler_4_Helper
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
; MidiStream_GetCategoryLastSlot: Register-preserving call of CharMap_ActivePreamb_Prologue2: returns in A the last
;   slot index of sound category A (the per-category tables at descriptor +0x3C/+0x40/+0x44/+0x48/+0x4C, chosen by
;   part and mode), all other registers kept. The part comes from PART_SELECT (GetCurrentPartSelect), not from the B
;   the caller loads. Basis: callers + body -- the only caller MidiStream_ExtDispatch_Mode0 takes the received program
;   E (<= 17, the category count - 1) as a category and drops the change when the part's bank byte 0x9412[part] (the
;   slot) is above this value.
MidiStream_GetCategoryLastSlot:
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	push	xwa
	call	CharMap_ActivePreamb_Prologue2
	pop	xwa
	ld	a, l
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	ret
; MidiStream_ResolveVoiceIndex: Register-preserving call of SndBuf_WriteParamEntries: builds a sound-selection record
;   from the received bank-select pair at (0x90EA) (+0 = CC32 byte, +1 = CC0 byte) and the program and part at
;   (0x90EC) (+2 = program, +5 = part). SndParam_CheckAndApplyMode resolves the record's (program, bank): the +2 voice
;   index goes through the +0x1C / +0x30 tables (SndParam_LookupOscEnvelope, +1 selecting the variation), or
;   SndParam_ApplyVoiceValue in mode 1. The result is left at (0x90EE). Basis: callers + body -- the only caller
;   MidiStream_ExtDispatch_Mode3 (MIDI mode 3) fills 0x90EA/0x90EC from 0x93D2[2p] and DE, then passes (0x90EE) to
;   MidiStream_SetPartProgram as program E and bank B.
MidiStream_ResolveVoiceIndex:
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	SndBuf_WriteParamEntries
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ret
RegBitManip_Handler_4_Code:
	ld	(0x916f:16), hl
;
	push	xwa
	push	xbc
	push	xde
	push	xhl
	push	xix
	push	xiy
	push	xiz
	call	MidiStream_ExtendedDispatch_Helper3_Helper
	pop	xiz
	pop	xiy
	pop	xix
	pop	xhl
	pop	xde
	pop	xbc
	pop	xwa
	ldw_d16	hl, (0x9173)
	ldb_d8	w, (0x9175)
	ret

MIDI_ParamValidate_CheckBit2:
	xor hl, hl
	bit 2, (0xfdad:16)
	jr nz, MidiParamValid_CheckW78
	cp a, 0xf0
	jr nc, MidiParamValid_SetInvalid
	jr MidiParamValid_Return

MidiParamValid_CheckW78:
	cp w, 0x78
	jr nz, MidiParamValid_Return

MidiParamValid_SetInvalid:
	inc 1, hl

MidiParamValid_Return:
	ret

MidiStream_ProcessEventBuffer:
	push xiz
	ld a, (0x379b:16)
	and a, 0xf
	jrl z, MidiStream_Return
	calr MidiStream_InitFromLookup
	ei 6
	or (1113:16), 1
	ld a, (1045:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, SWBTWR_EVENT_QUEUE
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

MidiStream_NextEvent:
	ld xix, (0x91c1:16)
	ld WA, (xix+)
	cp a, 0xff
	jr z, MidiStream_BufferDone
	ld (0x91bd:16), wa
	ld WA, (xix+)
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	ld bc, (0x91bd:16)
	ld de, (0x91bf:16)
	ld xix, 0x91d2

MidiStream_ScanForMatch:
	ld WA, (xix+)
	cp a, 0xff
	jr z, MidiStream_NextEvent
	cp wa, bc
	jr z, MidiStream_FoundMatch
	inc 2, xix
	jr MidiStream_ScanForMatch

MidiStream_FoundMatch:
	ld WA, (xix+)
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatch
	and d, a
	jr z, MidiStream_ScanForMatch

; MIDI stream processor dispatch A
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatch:
	and w, 0x7
	sll w, 2
	ld xix, MidiStream_Processor_Table
	ld	xix, (xix+w)
	call (xix)
	jr MidiStream_NextEvent

MidiStream_BufferDone:
	call TempoRingBuf_Consume
	res 0, (1113:16)

MidiStream_Return:
	pop xiz
	ret


; Jump table: 8 x .long code pointer.  Reader MidiStream_ProcessorDispatch:
;   and w, 0x7 / sll w, 2 / ld xix, MidiStream_Processor_Table
;   ld_sril3 XIX, 0x03, 0xf0, 0xe1 / call (xix)
; Index: w & 7; 8 entries.
MidiStream_Processor_Table:
	.long MidiStream_ProcessHandler_0
	.long MidiStream_ProcessHandler_1
	.long MidiStream_ProcessHandler_2
	.long MidiStream_ProcessHandler_3
	.long MidiStream_ProcessHandler_4
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
	.long MidiStream_ProcessHandler_5
MidiStream_ProcessHandler_5:
	ret

MidiStream_InitFromLookup:
	ld (0x91d2:16), 255
	extz hl
	ld l, (0x379b:16)
	and l, 0xf
	sll hl, 2
	ld xiy, MidiStream_InitFromLookup_Data
	ld	xiy, (xiy+hl)
	cp xiy, 0xffffffff
	jr z, MidiStreamInit_Done
	ld xix, 0x91d2

MidiStreamInit_CopyLoop:
	ld WA, (xiy+)
	ld (xix+), WA
	ld WA, (xiy+)
	ld (xix+), WA
	cp a, 0xff
	jr nz, MidiStreamInit_CopyLoop

MidiStreamInit_Done:
	ret

MidiStream_ProcessHandler_0:
	ld	xix, 0x91ad
	ld	a, 209:opc
	ld	w, (0x91c9:16)
	ld	(xix+), wa
	ld	a, (0x91bf:16)
	ld	w, 255:opc
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	TempoRingBuf_ProcessEntry
	ret
MidiStream_ProcessHandler_1:
	ld	xix, 0x91ad
	ld	a, 210:opc
	ld	w, (0x91c9:16)
	ld	(xix+), wa
	ld	a, (0x91c0:16)
	ld	w, 255:opc
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	TempoRingBuf_ProcessEntry
	ret
MidiStream_ProcessHandler_2:
	ld	xix, 0x91ad
	ld	a, 211:opc
	ld	w, (0x91c9:16)
	ld	(xix+), wa
	ld	a, (0x91bf:16)
	ld	w, 255:opc
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	TempoRingBuf_ProcessEntry
	ret
MidiStream_ProcessHandler_3:
	ld	xix, 0x91ad
	ld	a, 212:opc
	ld	w, (0x91c9:16)
	ld	(xix+), wa
	ld	a, 0:opc
	bit	3, (37311:16)
	jr	z, MidiStream_ProcessHandler_3_Skip
	ld	a, 127:opc
MidiStream_ProcessHandler_3_Skip:
	ld	w, 255:opc
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	TempoRingBuf_ProcessEntry
	ret
MidiStream_ProcessHandler_4:
	ld	xix, 0x91ad
	ld	a, 213:opc
	ld	w, (0x91c9:16)
	ld	(xix+), wa
	ld	a, (0x91bf:16)
	ld	w, 255:opc
	ld	(xix), wa
	ld	(0x91ca:16), 3
	calr	TempoRingBuf_ProcessEntry
	ret

MidiStream_ProcessSeqBuffer:
	push xiz
	cp (CURRENT_TITLE:16), 201
	jrl nz, MidiSeqBuf_Return
	cp (0x7f0b:16), 0
	jrl z, MidiSeqBuf_Return
	ei 6
	set 0, (1113:16)
	ld a, (1130:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, SWBTWR_EVENT_QUEUE
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

MidiSeqBuf_NextEvent:
	ld xix, (0x91c1:16)
	ld WA, (xix+)
	cp a, 0xff
	jr z, MidiSeqBuf_Done
	ld (0x91bd:16), wa
	ld WA, (xix+)
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	calr MidiSeqBuf_InitFromTable
	ld bc, (0x91bd:16)
	ld d, (0x91c0:16)
	ld xix, 0x91d2

MidiSeqBuf_ScanForMatch:
	ld WA, (xix+)
	cp a, 0xff
	jr z, MidiSeqBuf_NextEvent
	cp wa, bc
	jr z, MidiSeqBuf_FoundMatch
	inc 2, xix
	jr MidiSeqBuf_ScanForMatch

MidiSeqBuf_FoundMatch:
	ld WA, (xix+)
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchB
	and d, a
	jr z, MidiSeqBuf_ScanForMatch

; MIDI stream processor dispatch B
; Index: w & 0x7 (0-7), entries: 8
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchB:
	ld (0x91c7:16), 0
	and w, 0x7
	sll w, 2
	ld xix, MidiStream_ProcessorDispatchB_Data
	ld	xix, (xix+w)
	call (xix)
	ld (0x91d2:16), 255
	jr MidiSeqBuf_NextEvent

MidiSeqBuf_Done:
	call TempoRingBuf_Consume
	res 0, (1113:16)

MidiSeqBuf_Return:
	pop xiz
	ret

; MidiSeqBuf event-type handler table: 8 x .long code pointer, starting one
; byte in (after the 0xff pad byte; the reader uses MidiStream_ProcessorDispatchB_Data,
; a .set in shared/positional_labels.s).  Reader MidiStream_ProcessorDispatchB:
;   and w, 7 / sll w, 2 / ld xix, <table> / ld_sril3 xix, (xix + w) / call (xix)
; so 8 entries, index = w & 7.  Each handler builds one record at RAM 0x91AD
; whose first byte is the status named in the handler's label (C0 is
; TempoCC_TransmitBytecodeBlock) and hands it to TempoRingBuf_ProcessEntry;
; entries 5-7 are the `ret` right after the table (no record).
MidiSeqBuf_ProcessorTable:
	.byte	0xff	; pad: the table proper starts one byte in
MidiStream_ProcessorDispatchB_Data:
	.long TempoCC_TransmitBytecodeBlock
	.long	MIDI_EmitRecord_B0
	.long	MIDI_EmitRecord_D2
	.long	MIDI_EmitRecord_D1
	.long	MIDI_EmitRecord_D3
	.long	MidiSeqBuf_ProcessorNop
	.long	MidiSeqBuf_ProcessorNop
	.long	MidiSeqBuf_ProcessorNop
MidiSeqBuf_ProcessorNop:
	ret

MidiSeqBuf_InitFromTable:
	ld (0x91d2:16), 255
	ld xiy, VoiceMode_ParamConfigTables
	ld xix, 0x91d2

MidiSeqBufInit_CopyLoop:
	ld WA, (xiy+)
	ld (xix+), WA
	cp a, 0xff
	jr z, MidiSeqBufInit_Done
	ld WA, (xiy+)
	ld (xix+), WA
	jr MidiSeqBufInit_CopyLoop

MidiSeqBufInit_Done:
	ret

Tempo_ProcessExpressionChange:
	pushw wa
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jr z, TempoExpr_Done
	xor l, l
	ld xix, 0xf1a0

TempoExpr_FindActivePart:
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, TempoExpr_StorePartIndex
	inc 1, l
	cp l, 0x10
	jr c, TempoExpr_FindActivePart

TempoExpr_StorePartIndex:
	ld (0x91c7:16), l
	ei 6
	set 0, (1113:16)
	ld a, (SEQ_BEAT_TICK:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0x91ad
	ld a, 0xc0:opc
	ld w, (0x91c9:16)
	ld (xix+), WA
	ldw (xix+), 0x0017
	ld wa, (xsp)
	bit 7, a
	jr z, TempoExpr_CheckHighBitW
	res 7, a
	set 0, (0x91ad:16)

TempoExpr_CheckHighBitW:
	bit 7, w
	jr z, TempoExpr_WriteAndProcess
	res 7, w
	set 1, (0x91ad:16)

TempoExpr_WriteAndProcess:
	ld (xix+), WA
	ld a, (0x91c7:16)
	ld w, 0xff:opc
	ld (xix+), WA
	ld (0x91ca:16), 7
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoExpr_Done:
	inc 2, xsp
	ret

Audio_ProcessAllMidiStreams:
	ldw (0x90e0:16), 0
	calr MidiStream_ProcessEventBuffer
	calr MidiStream_ProcessSeqBuffer
	calr Mod_SelectExpressionSource
	calr MidiStream_ProcessTempoRingBuf
	ret

MIDI_SelectTempoExpressionSource:
	push xiz
	xor wa, wa
	ld e, (CURRENT_MODE:16)
	cp e, 0xb
	jr z, TempoSrc_CheckAutoPlay
	cp e, 0xd
	jr z, TempoSrc_DirectTempoMode
	ld d, (CURRENT_TITLE:16)
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	and (0x90f9:16), 243
	jr Tempo_ExpressionStore

TempoSrc_CheckAutoPlay:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, Tempo_ExpressionStore
	ld wa, (0x28a8:16)
	set 2, (0x90f9:16)
	jr Tempo_ExpressionStore

Tempo_Expression_Bypass:
	bit 0, (0x28c5:16)
	jr z, Tempo_ExpressionStore
	ld wa, (0x28aa:16)
	jr Tempo_ExpressionStore

TempoSrc_DirectTempoMode:
	ld wa, (3407:16)
	set 3, (0x90f9:16)

Tempo_ExpressionStore:
	ld (0x91c5:16), wa
	pop xiz
	ret

Mod_SelectExpressionSource:
	xor wa, wa
	ld e, (CURRENT_MODE:16)
	cp e, 0xb
	jr z, ModExpr_CheckAutoPlay
	cp e, 0xd
	jr z, ModExpr_DirectMode
	ld d, (CURRENT_TITLE:16)
	cp d, 0x87
	jr z, Tempo_Expression_Bypass
	cp d, 0x88
	jr z, Tempo_Expression_Bypass
	and (0x90f9:16), 243
	jr Mod_ExpressionStore

ModExpr_CheckAutoPlay:
	cpw (0x28a8:16), 0
	jr z, Mod_ExpressionStore
	ld wa, (0x28a8:16)
	set 2, (0x90f9:16)
	jr Mod_ExpressionStore
	bit 0, (0x28c5:16)
	jr z, Mod_ExpressionStore
	ld wa, (0x28aa:16)
	jr Mod_ExpressionStore

ModExpr_DirectMode:
	ld wa, (3407:16)
	set 3, (0x90f9:16)

Mod_ExpressionStore:
	ld (0x91c5:16), wa
	ret

MidiStream_ProcessTempoRingBuf:
	push xiz
	cpw (0x91c5:16), 0
	jrl z, TempoRing_Return
	ei 6
	set 0, (1113:16)
	ld a, (SEQ_BEAT_TICK:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, SWBTWR_EVENT_QUEUE
	extz xwa
	ld wa, (0x90e0:16)
	add xix, xwa
	ld (0x91c1:16), xix

TempoRing_NextEvent:
	ld xix, (0x91c1:16)
	ld WA, (xix+)
	cp a, 0xff
	jr z, TempoRing_Done
	ld (0x91bd:16), wa
	ld WA, (xix+)
	ld (0x91c1:16), xix
	ld (0x91bf:16), wa
	calr TempoRing_ValidateState
	ld (0x91c7:16), 0

TempoRing_InitAndScan:
	calr TempoRing_InitPartStream
	ld bc, (0x91bd:16)
	ld d, (0x91c0:16)
	ld xix, 0x91d2

TempoRing_ScanForMatch:
	ld WA, (xix+)
	cp a, 0xff
	jr z, TempoRing_UpdateAndContinue
	cp wa, bc
	jr z, TempoRing_FoundMatch
	inc 2, xix
	jr TempoRing_ScanForMatch

TempoRing_FoundMatch:
	ld WA, (xix+)
	cp c, 0xb1
	jr z, MidiStream_ProcessorDispatchC
	and d, a
	jr z, TempoRing_ScanForMatch

; MIDI stream processor dispatch C
; Index: w & 0xf (0-15), entries: 16
; 32-bit function pointers, call (xhl)
MidiStream_ProcessorDispatchC:
	and w, 0xf
	sll w, 2
	ld xix, MidiStream_ProcessorDispatchC_Data
	ld	xix, (xix+w)
	call (xix)

TempoRing_UpdateAndContinue:
	ld (0x91d2:16), 255
	inc 1, (0x91c7:16)
	cp (0x91c7:16), 15
	jr ule, TempoRing_InitAndScan
	jr TempoRing_NextEvent

TempoRing_Done:
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoRing_Return:
	pop xiz
	ret

; TempoRing event-type handler table: 16 x .long code pointer, starting one
; byte in (after the 0xff pad byte; the reader uses MidiStream_ProcessorDispatchC_Data,
; a .set in shared/positional_labels.s).  Reader MidiStream_ProcessorDispatchC
;   and w, 0xf / sll w, 2 / ld xix, <table> / ld_sril3 xix, (xix + w) / call (xix)
; so 16 entries, index = w & 15; entries 7-15 point at the `ret` right after
; the table (no record).  Same
; handlers as MidiSeqBuf_ProcessorTable plus MIDI_EmitRecord_80 (index 2) and
; MIDI_EmitRecord_D0 (index 6, which emits only when bit 0 of 0xFFC2 is set).
TempoRing_ProcessorTable:
	.byte	0xff	; pad: the table proper starts one byte in
MidiStream_ProcessorDispatchC_Data:
	.long TempoCC_TransmitBytecodeBlock
	.long	MIDI_EmitRecord_B0
	.long	MIDI_EmitRecord_80
	.long	MIDI_EmitRecord_D2
	.long	MIDI_EmitRecord_D1
	.long	MIDI_EmitRecord_D3
	.long	MIDI_EmitRecord_D0
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
	.long	TempoRing_ProcessorNop
TempoRing_ProcessorNop:
	ret

TempoRing_ValidateState:
	ld xix, (0x91c1:16)
	cp xix, 0xbd40
	jr z, MIDI_ParamValidation_ReturnNoOp
	ld bc, (0x91bd:16)
	cp c, 0x1f
	jr ugt, MIDI_ParamValidation_ReturnNoOp
	cp b, 4:i3
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp c, (xix - 8)
	jr nz, MIDI_ParamValidation_ReturnNoOp
	cp (xix - 7), 0x0
	jr nz, MIDI_ParamValidation_ReturnNoOp
	and (0x91c0:16), 183

MIDI_ParamValidation_ReturnNoOp:
	ret
TempoCC_TransmitBytecodeBlock:
	ld	xix, 0x91ad
	ld	a, 192:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldw_d16	wa, (0x91bd)
	ld	(xix+), wa
	ld	xiy, (0x90f2:16)
	extz	wa
	sll	wa, 2
	ld	xiy, (xiy+wa)
	ld	wa, (xiy)
	bit	7, a
	jr	z, TempoCC_TransmitBytecodeBlock_Skip
	res	7, a
	set	0, (0x91ad:16)
TempoCC_TransmitBytecodeBlock_Skip:
	bit	7, w
	jr	z, TempoCC_TransmitBytecodeBlock_Skip2
	res	7, w
	set	1, (0x91ad:16)
TempoCC_TransmitBytecodeBlock_Skip2:
	ld	(xix+), wa
	ldb_d8	a, (0x91c7)
	ld	w, 255:opc
	ld	(xix+), wa
	ld	(0x91ca:16), 7
	calr	TempoRingBuf_ProcessEntry
	ret
MIDI_EmitRecord_B0:
	ld	xix, 0x91ad
	ld	a, 176:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldw_d16	wa, (0x91bd)
	bit	7, a
	jr	z, MIDI_EmitRecord_B0_Skip
	res	7, a
	set	2, (0x91ad:16)
MIDI_EmitRecord_B0_Skip:
	ld	(xix+), wa
	ldw_d16	wa, (0x91bf)
	bit	7, a
	jr	z, MIDI_EmitRecord_B0_Skip2
	res	7, a
	set	0, (0x91ad:16)
MIDI_EmitRecord_B0_Skip2:
	bit	7, w
	jr	z, MIDI_EmitRecord_B0_Skip3
	res	7, w
	set	1, (0x91ad:16)
MIDI_EmitRecord_B0_Skip3:
	ld	(xix+), wa
	ldb_d8	a, (0x91c7)
	ld	w, 255:opc
	ld	(xix+), wa
	ld	(0x91ca:16), 7
	calr	TempoRingBuf_ProcessEntry
	ret
MIDI_EmitRecord_D2:
	ld	xix, 0x91ad
	ld	a, 210:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldw_d16	wa, (0x91bf)
	and	wa, 0x7f7f
	ld	(xix+), wa
	ldb_d8	a, (0x91c7)
	ld	w, 255:opc
	ld	(xix+), wa
	ld	(0x91ca:16), 37
	calr	TempoRingBuf_ProcessEntry
	ret
MIDI_EmitRecord_D1:
	ld	xix, 0x91ad
	ld	a, 209:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldb_d8	a, (0x91bf)
	ldb_d8	w, (0x91c7)
	ld	(xix+), wa
	ld	(xix), 255
	ld	(0x91ca:16), 20
	calr	TempoRingBuf_ProcessEntry
	ret
MIDI_EmitRecord_D3:
	ld	xix, 0x91ad
	ld	a, 211:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldb_d8	a, (0x91bf)
	ldb_d8	w, (0x91c7)
	ld	(xix+), wa
	ld	(xix), 255
	ld	(0x91ca:16), 4
	calr	TempoRingBuf_ProcessEntry
	ret
MIDI_EmitRecord_D0:
	bit	0, (0xffc2:24)
	jr	z, MIDI_EmitRecord_D0_Return
	ld	xix, 0x91ad
	ld	a, 208:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldb_d8	a, (0x91bf)
	ldb_d8	w, (0x91c7)
	ld	(xix+), wa
	ld	(xix), 255
	ld	(0x91ca:16), 4
	calr	TempoRingBuf_ProcessEntry
MIDI_EmitRecord_D0_Return:
	ret
MIDI_EmitRecord_80:
	ld	xix, 0x91ad
	ld	a, 128:opc
	ldb_d8	w, (0x91c9)
	ld	(xix+), wa
	ldw_d16	wa, (0xfc62)
	and	wa, 0x1ff
	sll	w, 1
	bit	7, a
	jr	z, MIDI_EmitRecord_80_Skip
	set	0, w
MIDI_EmitRecord_80_Skip:
	res	7, a
	ld	(xix+), wa
	ld	(xix), 255
	ld	(0x91ca:16), 4
	calr	TempoRingBuf_ProcessEntry
	ret

MIDI_TransmitTempoCC:
	ld (0x91bd:16), bc
	ld (0x91bf:16), de
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jr z, TempoCC_Return
	ei 6
	set 0, (1113:16)
	ld a, (SEQ_BEAT_TICK:16)
	ld (0x91c9:16), a
	ei 0
	ld xix, 0x91ad
	ld a, 0xb0:opc
	ld w, (0x91c9:16)
	ld (xix+), WA
	ld wa, (0x91bd:16)
	ld (xix+), WA
	ld wa, (0x91bf:16)
	bit 7, a
	jr z, TempoCC_CheckHighBitW
	res 7, a
	set 0, (0x91ad:16)

TempoCC_CheckHighBitW:
	bit 7, w
	jr z, TempoCC_WriteAndProcess
	res 7, w
	set 1, (0x91ad:16)

TempoCC_WriteAndProcess:
	ld (xix+), WA
	ldw wa, 0xff7f
	ld (xix), wa
	ld (0x91ca:16), 135
	calr TempoRingBuf_ProcessEntry
	call TempoRingBuf_Consume
	res 0, (1113:16)

TempoCC_Return:
	ret

TempoRing_InitPartStream:
	ld (0x91d2:16), 255
	ld c, (0x91c7:16)
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x91c5:16)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, TempoPartStream_Done
	extz hl
	ld l, (0x91c7:16)
	ld xix, 0xf1a0
	ld	l, (xix+hl)
	sll hl, 2
	ld xix, TempoRing_InitPartStream_Data
	ld	xiy, (xix+hl)
	ld xix, 0x91d2

TempoPartStream_CopyLoop:
	ld WA, (xiy+)
	ld (xix+), WA
	cp a, 0xff
	jr z, TempoPartStream_Done
	ld WA, (xiy+)
	ld (xix+), WA
	jr TempoPartStream_CopyLoop

TempoPartStream_Done:
	ret

TempoRingBuf_ProcessEntry:
	cp (0x91ad:16), 255
	jr z, TempoRingBuf_EntryDone
	ld xix, 0x91ad
	push xix
	extz wa
	ld a, (0x91ca:16)
	and a, 0x7
	pushw wa
	ei 6
	call TempoRingBuf_WriteBytes
	inc 6, xsp
	ei 0
	cp (0x90f8:16), 255
	jr nz, TempoRingBuf_ClearEntryType
	call AudioCtrl_SaveAllRegs
	call SeqPlay_CheckAndStartPlayback
	call AudioCtrl_RestoreAllRegs
	jr TempoRingBuf_ClearEntryType

TempoRingBuf_ClearEntryType:
	ld (0x91ca:16), 0

TempoRingBuf_EntryDone:
	ret

Audio_ProcessPartExpressions:
	push xiz
	calr MIDI_SelectTempoExpressionSource
	cpw (0x91c5:16), 0
	jrl z, PartExpr_Done
	ei 6
	set 0, (1113:16)
	ld a, (SEQ_BEAT_TICK:16)
	ld (0x91c9:16), a
	ei 0
	xor c, c

PartExpr_ProcessNextBit:
	ld wa, (0x91c5:16)
	srl wa, 1
	ld (0x91c5:16), wa
	jr nc, PartExpr_AdvanceBit
	ld l, c
	ld xix, 0xf1a0
	ld	a, (xix+l)
	cp a, 0:i3
	jr z, PartExpr_WriteToBuffer
	cp a, 2:i3
	jr z, PartExpr_WriteToBuffer
	cp a, 1:i3
	jr nz, PartExpr_AdvanceBit

PartExpr_WriteToBuffer:
	ld xix, 0x91ad
	ld a, 0xb2:opc
	ld w, (0x91c9:16)
	ld (xix+), WA
	ld a, 0x9a:opc
	bit 7, a
	jr z, PartExpr_AddPartIndex
	set 2, (0x91ad:16)
	res 7, a

PartExpr_AddPartIndex:
	ld w, c
	add w, 0x4
	ld (xix+), WA
	ld a, (0xc5a8:16)
	bit 7, a
	jr z, PartExpr_ReadCurrentValue
	set 0, (0x91ad:16)
	res 7, a

PartExpr_ReadCurrentValue:
	ld w, 0x7f:opc
	ld (xix+), WA
	ld a, c
	ld w, 0xff:opc
	ld (xix+), WA
	ld (0x91ca:16), 7
	pushw bc
	calr TempoRingBuf_ProcessEntry
	popw bc

PartExpr_AdvanceBit:
	inc 1, c
	cp c, 0x10
	jr c, PartExpr_ProcessNextBit
	call TempoRingBuf_Consume
	res 0, (1113:16)

PartExpr_Done:
	pop xiz
	ret

Part_ReinitAllActive:
	push xiz
	ld (0x91c8:16), 0

PartReinit_ProcessNextPart:
	ld c, (0x91c8:16)
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0xf19e:16)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, PartReinit_AdvancePart
	extz hl
	ld l, c
	ld xix, 0xf1a0
	ld	a, (xix+hl)
	ld (0x91cd:16), a
	calr PartReinit_SendD0Command
	calr PartReinit_SendB0Command
	calr PartReinit_SendD2Command
	calr PartReinit_SendD1Command
	calr PartReinit_SendD0Command
	calr PartReinit_CheckSpecialPart15

PartReinit_AdvancePart:
	inc 1, (0x91c8:16)
	cp (0x91c8:16), 16
	jr c, PartReinit_ProcessNextPart
	calr PendingParam_ScanAllTables
	call SwbtWr_ReinitOutputBank
	pop xiz
	ret

PartReinit_SendD2Command:
	ld xix, 0x91b5
	ldw wa, 0xd2
	ld (xix+), WA
	xor a, a
	ld w, 0x40:opc
	ld (xix+), WA
	ld a, (0x91c8:16)
	ld w, 0xff:opc
	ld (xix), wa
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD1Command:
	ld xix, 0x91b5
	ldw wa, 0xd1
	ld (xix+), WA
	ld a, 0x0:opc
	ld w, (0x91c8:16)
	ld (xix+), WA
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendD0Command:
	ld xix, 0x91b5
	ldw wa, 0xd0
	ld (xix+), WA
	ld a, 0x0:opc
	ld w, (0x91c8:16)
	ld (xix+), WA
	ld (xix), 0xff
	calr VoiceParam_DispatchByMode
	ret

PartReinit_SendB0Command:
	ld xix, 0x91b5
	ldw wa, 0xb0
	ld (xix+), WA
	extz hl
	ld l, (0x91c8:16)
	ld xiy, 0xf1a0
	ld	l, (xiy+hl)
	ld xiy, PartReinit_SendB0Command_Data
	ld	a, (xiy+hl)
	ld w, 0x4:opc
	ld (xix+), WA
	ldw wa, 0x800
	ld (xix+), WA
	ld a, (0x91c8:16)
	ld w, 0xff:opc
	ld (xix), wa
	calr VoiceMode_ParamHandler_3
	ret

PartReinit_CheckSpecialPart15:
	cp (0x91cd:16), 15
	jr nz, PartReinit_SpecialDone
	ldw bc, 0x298
	ldw de, 0x8000
	call MIDI_WriteVoiceParamDirect
	call SwbtWr_WriteVoiceParam_PreserveRegs

PartReinit_SpecialDone:
	ret

Audio_ReinitAndProcessEvents:
	calr Audio_SyncAndProcessSequencer
	calr PendingParam_ScanAllTables
	call MidiPkt_ProcessEventQueue
	ret

Audio_SyncAndProcessSequencer:
	ld wa, (0x90de:16)
	ld (0x90e0:16), wa
	call SeqBuf_SaveReadPos

AudioSeq_CheckEventPending:
	ld xix, 0x1e549
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, AudioSeq_FlushAndTerminate
	ld xiy, 0x91b5

AudioSeq_ReadNextEvent:
	pushw hl
	call SeqBuf_ReadAlternate
	ld (xiy+), l
	popw hl
	ld hl, (xix - 10)
	cp hl, (xix - 6)
	jr z, VoiceMode_ParamDispatch
	ld	a, (xix+hl)
	bit 7, a
	jr z, AudioSeq_ReadNextEvent

; Voice mode parameter dispatch
; Index: DRAM[37301] bits [6:4] (0-7), entries: 8
; 32-bit function pointers, call (xhl)
VoiceMode_ParamDispatch:
	ld (xiy), 0xff
	ld a, (0x91b6:16)
	ld (0x90f8:16), a
	extz hl
	ld l, (0x91b5:16)
	and l, 0x70
	srl hl, 2
	ld xiy, VoiceMode_ParamDispatch_Table
	ld	xiy, (xiy+hl)
	call (xiy)
	jr AudioSeq_CheckEventPending

VoiceMode_ParamDispatch_Sentinel:
	swi	7


; Jump table: 8 x .long code pointer.  Reader VoiceMode_ParamDispatch:
;   ld (xiy), 0xff / ld a, (0x91b6:16) / ld (0x90f8:16), a / extz hl
;   ld l, (0x91b5:16) / and l, 0x70 / srl hl, 2
;   ld xiy, VoiceMode_ParamDispatch_Table / ld_sril3 XIY, 0x07, 0xf4, 0xec
;   call (xiy)
; Index: bits 4-6 of the byte it loads; 8 entries.
VoiceMode_ParamDispatch_Table:
	.long VoiceMode_ParamHandler_0
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_3
	.long VoiceMode_ParamHandler_4
	.long VoiceParam_DispatchByMode
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1

VoiceMode_ParamHandler_1:
	ret

AudioSeq_FlushAndTerminate:
	ld xix, SWBTWR_EVENT_QUEUE
	ld hl, (0x90de:16)
	ld	(xix+hl), 0xff
	ret

VoiceMode_ParamHandler_4:
	calr VoiceMode_CheckPendingFlags
	cp (0x91b5:16), 255
	jrl z, MidiCtrl_NullRet
	ld xix, 0x91b7
	ld BC, (xix+)
	ld DE, (xix+)
	ld a, (xix)
	ld (0x91c8:16), a
	extz hl
	ld l, c
	sll hl, 2
	ld xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp xix, 0xffffffff
	jrl z, MidiCtrl_NullRet
	ld (0x915b:16), bc
	ld (0x915d:16), de
	ld (0x90f7:16), c
	ld hl, de
	call PartCtrl_WriteProgramChange
	ld (0x91cf:16), hl
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode4_CheckPart0
	cp (0x915b:16), 23
	jr nz, VoiceMode4_SetupChannelAndWrite
	ld hl, de
	call AccompSeq_ManualMidiEntry2
	ret

VoiceMode4_SetupChannelAndWrite:
	call MIDI_SetupChannelParams
	andmi8 (xix + 1), 0x80
	ld a, (0x915e:16)
	or (xix + 1), a
	ld a, (0x915d:16)
	ld (xix), a
	ld a, (0x915b:16)
	ld w, 0x1:opc
	ld (MIDI_MSG_STATUS:16), wa
	ld a, (0x915e:16)
	ld w, 0x7f:opc
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ld a, (0x915b:16)
	ld w, 0x0:opc
	ld (MIDI_MSG_STATUS:16), wa
	ld a, (0x915d:16)
	ld w, 0xff:opc
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call SndParam_UpdateVoiceEntry_Safe

VoiceMode4_CheckPart0:
	cp (0x915b:16), 0
	jr nz, MidiCtrl_DispatchHandler
	bit 3, (0xfd50:16)
	jrl nz, MidiCtrl_NullRet

; MIDI controller dispatch handler
MidiCtrl_DispatchHandler:
	xor h, h
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ld	a, (xix+hl)
	cp a, 0xd
	jrl z, MidiCtrl_NullRet
	cp a, 0xe
	jrl z, MidiCtrl_NullRet
	cp a, 0xf
	jrl z, MidiCtrl_NullRet
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	ld xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 0x10
	jrl z, MidiCtrl_NullRet
	set 7, a
	ld (0x90e5:16), a
	extz hl
	ld l, (0xfd50:16)
	and l, 0x3
	sll hl, 2
	ld xix, MidiCtrl_ModeDispatch_Table
	ld	xix, (xix+hl)
	jp (xix)
MidiCtrl_ModeDispatch_Table:
	; (0xFD50) & 3 -> handler; mode 2 does nothing.  Was decoded as `swi 1 / .byte ... / jrl -849`.
	.long	MidiCtrl_Mode0_Handler
	.long	MidiCtrl_Mode1_Handler
	.long	MidiCtrl_NullRet
	.long	MidiCtrl_Mode3_Handler
MidiCtrl_Mode0_Handler:
	ld	c, 129:opc
	ld	b, (37211:16)
	ld	e, (37328:16)
	xor	d, d
	call	MIDI_DispatchCC_Guarded
	xor	h, h
	ld	l, (37320:16)
	ld	xix, 37070
	ld	a, (xix+hl)
	set	7, a
	ld	(37093:16), a
	ld	bc, (37211:16)
	ld	e, (37327:16)
	ld	d, 255:opc
	call	MIDI_DispatchCC_Guarded
	jrl	MidiCtrl_NullRet
MidiCtrl_Mode1_Handler:
	ld	b, (37211:16)
	ld	c, 129:opc
	xor	d, d
	bit	7, (0x915d:16)
	jr	z, VoiceMode_ParamHandler_4_Skip
	ld	d, 1:opc
VoiceMode_ParamHandler_4_Skip:
	ld	e, (37214:16)
	sll	e, 4
	call	MIDI_DispatchCC_Guarded
	extz	hl
	ld	l, (37320:16)
	ld	xix, 37070
	ld	a, (xix+hl)
	set	7, a
	ld	(37093:16), a
	ld	c, (37211:16)
	ld	b, 0:opc
	ld	e, (37213:16)
	res	7, e
	ld	d, 255:opc
	call	MIDI_DispatchCC_Guarded
	jr	MidiCtrl_NullRet
MidiCtrl_Mode3_Handler:
	ld	wa, (37213:16)
	ld	(37098:16), wa
	ld	a, (37211:16)
	ld	(37100:16), a
	call	VoiceMode_ParamHandler_4_Helper
	pushw	wa
	pushw	hl
	ld	wa, (37213:16)
	call	MIDI_ParamValidate_CheckBit2
	or	hl, hl
	popw	hl
	popw	wa
	jr	nz, VoiceMode_ParamHandler_4_Skip2
	ld	b, (37211:16)
	ld	c, 129:opc
	ld	de, (37102:16)
	call	MIDI_DispatchCC_Guarded
VoiceMode_ParamHandler_4_Skip2:
	extz	hl
	ld	l, (37320:16)
	ld	xix, 37070
	ld	a, (xix+hl)
	set	7, a
	ld	(37093:16), a
	ld	c, (37211:16)
	xor	b, b
	ld	e, (37104:16)
	ld	d, 255:opc
	call	MIDI_DispatchCC_Guarded

MidiCtrl_NullRet:
	ret

VoiceMode_CheckPendingFlags:
	ld xix, 0x91b5
	bitm 0, (xix)
	jr z, VoiceMode_CheckFlag1
	setm 7, (xix + 4)

VoiceMode_CheckFlag1:
	bitm 1, (xix)
	jr z, VoiceMode_CheckPart15Validate
	setm 7, (xix + 5)

VoiceMode_CheckPart15Validate:
	cp (xix + 2), 0xf
	jr nz, VoiceMode_FlagCheckDone
	pushw wa
	pushw hl
	ld a, (xix + 4)
	ld w, (xix + 5)
	call MIDI_ParamValidate_CheckBit2
	or hl, hl
	popw hl
	popw wa
	jr nz, VoiceMode_FlagCheckDone
	ld (xix), 0xff

VoiceMode_FlagCheckDone:
	ret

VoiceMode_ParamHandler_3:
	calr VoiceMode3_InitChannelMatch
	cp (0x91b5:16), 255
	jr z, VoiceMode3_Done
	extz hl
	ld l, (0x91d1:16)
	and l, 0xf
	sll hl, 2
	ld xix, VoiceMode_ParamHandler_3_Data
	ld	xix, (xix+hl)
	call (xix)

VoiceMode3_Done:
	ret

; VoiceMode3 record-type handler table: 16 x .long code pointer, starting one
; byte in (after the 0xff pad byte; the reader uses VoiceMode_ParamHandler_3_Data,
; a .set in shared/positional_labels.s).  Reader VoiceMode_ParamHandler_3:
;   ld l, (0x91d1) / and l, 0xf / sll hl, 2 / ld xix, <table> /
;   ld_sril3 xix, (xix + hl) / call (xix)
; so 16 entries, index = low nibble of the byte at 0x91D1.  Entries 7-15 all
; go to VoiceMode_ParamHandler_1.  Entries 0 and 2-6 are named by index only:
; the event each index stands for is not pinned here (the processor tables
; above map indices 0-6 to records C0, B0, 80, D2, D1, D3, D0, but no reader
; ties this table's index to that numbering).
VoiceMode3_DispatchTable:
	.byte	0xff	; pad: the table proper starts one byte in
VoiceMode_ParamHandler_3_Data:
	.long	VoiceMode3_EvType0
	.long MidiVoice_DataBlockHandler
	.long	VoiceMode3_EvType2
	.long	VoiceMode3_EvType3
	.long	VoiceMode3_EvType4
	.long	VoiceMode3_EvType5
	.long	VoiceMode3_EvType6
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
	.long VoiceMode_ParamHandler_1
VoiceMode3_EvType0:
	call	PartCtrl_CheckBitmaskBit
	jr	nc, VoiceMode3_DispatchTable_Code_Skip3
	ld	a, (37306:16)
	and	a, 7
	jr	z, VoiceMode3_DispatchTable_Code_Skip2
	ld	bc, (37303:16)
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	ld	a, (xix+hl)
	cp	a, 14
	jr	nz, VoiceMode3_DispatchTable_Code_Skip
	ld	b, 4:opc
VoiceMode3_DispatchTable_Code_Skip:
	ld	e, (37305:16)
	ld	d, 7:opc
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
VoiceMode3_DispatchTable_Code_Skip2:
	ld	bc, (37303:16)
	ld	de, (37305:16)
	and	d, 248
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
VoiceMode3_DispatchTable_Code_Skip3:
	ld	a, (37306:16)
	and	a, 7
	jr	z, VoiceMode3_DispatchTable_Code_Return
	extz	hl
	ld	l, (37307:16)
	ld	xix, 61856
	cp	(xix+hl), 0x0f
	jr	nz, VoiceMode3_DispatchTable_Code_Return
	ld	xix, 37070
	ld	a, (xix+hl)
	cp	a, 16
	jr	z, VoiceMode3_DispatchTable_Code_Return
	set	7, a
	ld	(37093:16), a
	ld	bc, (37303:16)
	ld	de, (37305:16)
	and	d, 7
	call	MIDI_DispatchCC_Guarded
VoiceMode3_DispatchTable_Code_Return:
	ret
VoiceMode3_EvType6:
	call	PartCtrl_CheckBitmaskBit
	jr	nc, VoiceMode3_DispatchTable_Code_Skip4
	ld	bc, (37303:16)
	ld	de, (37305:16)
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (37106:16)
	ld	xix, (xix+hl)
	cp	xix, 4294967295
	jr	z, VoiceMode3_DispatchTable_Code_Return2
	extz	hl
	ld	l, b
	ld	a, (xix+hl)
	ld	w, d
	xor	w, 255
	and	a, w
	and	e, d
	or	e, a
	ld	(xix+hl), e
	ld	(MIDI_MSG_STATUS:16), bc
	ld	(MIDI_MSG_DATA2:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	cpw	(37303:16), 920
	jr	nz, VoiceMode3_DispatchTable_Code_Skip4
	set	3, (0x8d52:16)
VoiceMode3_DispatchTable_Code_Skip4:
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	ld	a, (xix+hl)
	cp	a, 15
	jr	z, VoiceMode3_DispatchTable_Code_Return2
	cp	a, 14
	jr	z, VoiceMode3_DispatchTable_Code_Return2
	cp	a, 13
	jr	z, VoiceMode3_DispatchTable_Code_Return2
	ld	xix, 37070
	ld	a, (xix+hl)
	cp	a, 16
	jr	z, VoiceMode3_DispatchTable_Code_Return2
	set	7, a
	ld	(37093:16), a
	ld	bc, (37303:16)
	ld	de, (37305:16)
	call	MIDI_DispatchCC_Guarded
VoiceMode3_DispatchTable_Code_Return2:
	ret
VoiceMode3_EvType5:
	ld	bc, (37303:16)
	ld	de, (37305:16)
	bit	7, d
	jr	nz, MidiPartCC_WriteAndDispatch_Skip
	extz	hl
	ld	l, (37320:16)
	ld	xix, 61856
	cp	(xix+hl), 0x0f
	jr	z, MidiPartCC_WriteAndDispatch_Skip
	set	7, e
	ld	xix, 38066
	ld	(xix+hl), e
	ret

MidiPartCC_WriteAndDispatch:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ld	l, (xix+hl)
	ld xix, PartReinit_SendB0Command_Data
	ld	c, (xix+hl)
	ld b, 0x3:opc
	ld (0x915b:16), bc
	ld d, 0x7f:opc
	ld (0x915d:16), de
MidiPartCC_WriteAndDispatch_Skip:
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPartCC_CheckAndGuard
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiPartCC_CheckAndGuard:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ld	a, (xix+hl)
	cp a, 0xe
	jr z, MIDI_PartCC_DispatchExit
	cp a, 0xd
	jr z, MIDI_PartCC_DispatchExit
	ld xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 0x10
	jr z, MIDI_PartCC_DispatchExit
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

MIDI_PartCC_DispatchExit:
	ret

MidiVoice_DataBlockHandler:
	ld	xiy, 0x91b7
	ld	(0x90e4:16), 0
	call	PartCtrl_CheckBitmaskBit
	jr	nc, MidiVoice_DataBlockHandler_Skip
	or	(37092:16), 32
	ld	wa, (xiy)
	ld	(MIDI_MSG_STATUS:16), wa
	ld	wa, (xiy+2)
	ld	(MIDI_MSG_DATA2:16), wa
MidiVoice_DataBlockHandler_Skip:
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 16
	jr	z, MidiVoice_DataBlockHandler_Skip4
	bit	4, (64848:16)
	jr	nz, MidiVoice_DataBlockHandler_Skip4
	or	(37092:16), a
	or	(37092:16), 192
	ld	wa, (xiy)
	ld	(MIDI_MSG_STATUS:16), wa
	ld	wa, (xiy+2)
	ld	(MIDI_MSG_DATA2:16), wa
MidiVoice_DataBlockHandler_Skip4:
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
VoiceMode3_EvType2:
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0xf1a0
	cp	(xix+hl), 0x0f
	jr	nz, MidiVoice_DataBlockHandler_Return
	call	PartCtrl_CheckBitmaskBit
	jr	nc, VoiceMode3_EvType2_Skip
	ldw	bc, 664
	ld	e, (0x91b9:16)
	ld	d, 128:opc
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
VoiceMode3_EvType2_Skip:
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 16
	jr	z, MidiVoice_DataBlockHandler_Return
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 664
	ld	e, (0x91b9:16)
	ld	d, 128:opc
	call	MIDI_DispatchCC_Guarded
MidiVoice_DataBlockHandler_Return:
	ret
VoiceMode3_EvType3:
	call	PartCtrl_CheckBitmaskBit
	jr	nc, MidiVoice_DataBlockHandler_Skip2
	ld	a, 0:opc
	ld	(0x9644:16), a
	ld	wa, (0x91b7:16)
	ld	(0x9644:16), wa
	ldw	wa, 0x7f00
	ld	(0x9646:16), wa
	call	MidiCC_ResetAllControllers
	ld	a, (0x91b6:16)
	ld	(0x90f8:16), a
MidiVoice_DataBlockHandler_Skip2:
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 16
	jr	z, MidiVoice_DataBlockHandler_Return2
	set	7, a
	ld	(0x90e5:16), a
	ld	bc, (0x91b7:16)
	ld	de, (0x91b9:16)
	call	MIDI_DispatchCC_Guarded
MidiVoice_DataBlockHandler_Return2:
	ret
VoiceMode3_EvType4:
	call	PartCtrl_CheckBitmaskBit
	jr	nc, MidiVoice_DataBlockHandler_Skip3
	ld	wa, (0x91b7:16)
	ld	(MIDI_MSG_STATUS:16), wa
	ld	wa, (0x91b9:16)
	ld	(MIDI_MSG_DATA2:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
MidiVoice_DataBlockHandler_Skip3:
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 16
	jr	z, MidiVoice_DataBlockHandler_Return3
	set	7, a
	ld	(0x90e5:16), a
	ld	bc, (0x91b7:16)
	ld	de, (0x91b9:16)
	call	MIDI_DispatchCC_Guarded
MidiVoice_DataBlockHandler_Return3:
	ret

VoiceMode3_InitChannelMatch:
	ld a, (0x91bb:16)
	ld (0x91c8:16), a
	calr VoiceMode3_BuildChannelTable
	cp (0x91d2:16), 255
	jr z, VoiceMode3_NoMatch
	ld xix, 0x91b7
	ld bc, (xix)
	ld de, (xix + 2)
	ld a, (xix - 2)
	bit 2, a
	jr z, VoiceMode3_CheckBit0
	set 7, c

VoiceMode3_CheckBit0:
	bit 0, a
	jr z, VoiceMode3_CheckBit1
	set 7, e

VoiceMode3_CheckBit1:
	bit 1, a
	jr z, VoiceMode3_StoreAndScan
	set 7, d

VoiceMode3_StoreAndScan:
	ld (xix), bc
	ld (xix + 2), de
	ld xiy, 0x91d2

VoiceMode3_ScanLoop:
	ld WA, (xiy+)
	cp a, 0xff
	jr z, VoiceMode3_NoMatch
	cp wa, bc
	jr z, VoiceMode3_FoundMatch
	inc 2, xiy
	jr VoiceMode3_ScanLoop

VoiceMode3_FoundMatch:
	ld WA, (xiy+)
	and d, a
	ld (xix + 2), de
	jr nz, VoiceMode3_StoreSubMode

VoiceMode3_NoMatch:
	ld (0x91b5:16), 255
	jr VoiceMode3_ScanDone

VoiceMode3_StoreSubMode:
	ld (0x91d1:16), w

VoiceMode3_ScanDone:
	ret

VoiceMode3_BuildChannelTable:
	ld (0x91d2:16), 255
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ld	l, (xix+hl)
	sll hl, 2
	ld xix, VoiceMode3_BuildChannelTable_Data
	ld	xiy, (xix+hl)
	ld xix, 0x91d2

VoiceMode3_CopyTableEntry:
	ld WA, (xiy+)
	ld (xix+), WA
	cp a, 0xff
	jr z, VoiceMode3_TableCopyDone
	ld WA, (xiy+)
	ld (xix+), WA
	jr VoiceMode3_CopyTableEntry

VoiceMode3_TableCopyDone:
	ret

VoiceMode_ParamHandler_0:
	cp (0x91b5:16), 128
	jr nz, VoiceMode0_Done
	ld a, (0x91b9:16)
	ld (0x91c8:16), a
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceMode0_Done
	ld wa, (0x91b7:16)
	srl w, 1
	jr nc, VoiceMode0_UpdateTempoAndWrite
	set 7, a

VoiceMode0_UpdateTempoAndWrite:
	ld xix, (0xfc62:16)
	and w, 0x1
	andmi16 (xix), 0xfe00
	or (xix), wa
	ld w, 0xff:opc
	call SeqTimer_UpdateTempoReg
	ld (MIDI_MSG_DATA2:16), wa
	ldw (MIDI_MSG_STATUS:16), 2120
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceMode0_Done:
	ret

VoiceParam_DispatchByMode:
	calr MidiVoiceNote_Dispatch
	cp (0x91b5:16), 255
	jr z, VoiceParam_DispatchDone
	ld a, (0x91b5:16)
	and a, 0x3
	sll a, 2
	ld xix, VoiceParam_ModeDispatch_Table
	ld	xix, (xix+a)
	call (xix)

VoiceParam_DispatchDone:
	ret

VoiceParam_ModeDispatch_Table:
	.long VoiceParam_StorePendingB4
	.long VoiceParam_StorePendingModulation
	.long VoiceParam_StorePendingPitchBend
	.long VoiceNote_StoreBankSelect

VoiceParam_StorePendingB4:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x94d2
	ld a, (0x91b7:16)
	set 7, a
	ld	(xix+hl), a
	ret

VoiceParam_SendPendingB4:
	ld c, 0xb4:opc
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ld	l, (xix+l)
	ld xix, PartReinit_SendB0Command_Data
	ld	b, (xix+l)
	ld (0x915b:16), bc
	ld d, 0x7f:opc
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_SendPendingB4_Guard
	ld wa, (0x915b:16)
	ld (MIDI_MSG_STATUS:16), wa
	ld wa, (0x915d:16)
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_SendPendingB4_Guard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_SendPendingB4_Done
	ld xix, 0x90ce
	ld	a, (xix+l)
	cp a, 0x10
	jr z, VoiceParam_SendPendingB4_Done
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_SendPendingB4_Done:
	ret

VoiceParam_StorePendingModulation:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x9452
	ld a, (0x91b7:16)
	set 7, a
	ld	(xix+hl), a
	ret

VoiceParam_SendPendingModulation:
	ld c, 0xb2:opc
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ld	l, (xix+l)
	ld xix, PartReinit_SendB0Command_Data
	ld	b, (xix+l)
	ld (0x915b:16), bc
	ld d, 0x7f:opc
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_SendPendingModulation_Guard
	ld wa, (0x915b:16)
	ld (MIDI_MSG_STATUS:16), wa
	ld wa, (0x915d:16)
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs

VoiceParam_SendPendingModulation_Guard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_SendPendingModulation_Done
	ld xix, 0x90ce
	ld	a, (xix+l)
	cp a, 0x10
	jr z, VoiceParam_SendPendingModulation_Done
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_SendPendingModulation_Done:
	ret

VoiceParam_StorePendingPitchBend:
	extz hl
	ld l, (0x91c8:16)
	sll l, 1
	ld xix, 0x9472
	ld wa, (0x91b7:16)
	and wa, 0x7f7f
	set 7, a
	ld	(xix+hl), wa
	ret

VoiceParam_SendPendingPitchBend:
	ld c, 0xb1:opc
	ld xix, 0xf1a0
	ld l, (0x91c8:16)
	ld	l, (xix+l)
	ld xix, PartReinit_SendB0Command_Data
	ld	b, (xix+l)
	ld (0x915b:16), bc
	and de, 0x7f7f
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, VoiceParam_SendPendingPitchBend_Guard
	ld wa, (0x915b:16)
	ld (MIDI_MSG_STATUS:16), wa
	ld wa, (0x915d:16)
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteParamBlockSafe

VoiceParam_SendPendingPitchBend_Guard:
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cpib_sri 0x03, 0xf0, 0xec, 0x0f
	jr z, VoiceParam_SendPendingPitchBend_Done
	ld xix, 0x90ce
	ld	a, (xix+l)
	cp a, 0x10
	jr z, VoiceParam_SendPendingPitchBend_Done
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceParam_SendPendingPitchBend_Done:
	ret

VoiceNote_StoreBankSelect:

	ld e, (0x91b7:16)
	extz hl
	ld l, (0x91c8:16)
	bit 7, (DEMO_CONTROL_FLAGS:16)

	; LD SP, (XBC)
	; BIT 7, (28ADh)

	jr nz, VoiceNote_WriteBankAndCC
	set 7, e
	ld xix, 0x9432
	ld	(xix+hl), e
	ret

VoiceNote_WriteBankAndCC:
	ldw bc, 0x1b0
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	ld	a, (xix+hl)
	cp a, 0xf
	jr z, VoiceNote_SetupCCParams
	ld c, 0xb3:opc
	ld xix, PartReinit_SendB0Command_Data
	ld	b, (xix+a)

VoiceNote_SetupCCParams:
	ld (0x915b:16), bc
	ld d, 0x7f:opc
	ld (0x915d:16), de
	call PartCtrl_CheckBitmaskBit
	jr nc, MIDI_VoiceNote_CtrlExit
	cp (0x915b:16), 176
	jr z, VoiceNote_CheckBankSelect
	ld wa, (0x915b:16)
	ld (MIDI_MSG_STATUS:16), wa
	ld wa, (0x915d:16)
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteVoiceParam_PreserveRegs
	jr MIDI_VoiceNote_CtrlExit

VoiceNote_CheckBankSelect:
	bit 7, (DEMO_CONTROL_FLAGS:16)
	jr nz, VoiceNote_ApplyBankSelect
	bit 7, (0x28ae:16)
	jr z, VoiceNote_CtrlDone

VoiceNote_ApplyBankSelect:
	ld a, (0x915d:16)
	set 7, a
	ld (MIDI_CC_MODWHEEL_PENDING:16), a
	call Audio_WriteBankSelectParams
	bit 7, (DEMO_CONTROL_FLAGS:16)
	jr z, MIDI_VoiceNote_CtrlExit
	res 7, (DEMO_CONTROL_FLAGS:16)

MIDI_VoiceNote_CtrlExit:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 0x10
	jr z, VoiceNote_CtrlDone
	set 7, a
	ld (0x90e5:16), a
	ld bc, (0x915b:16)
	ld de, (0x915d:16)
	call MIDI_DispatchCC_Guarded

VoiceNote_CtrlDone:
	ret

; MIDI voice note dispatch
MidiVoiceNote_Dispatch:
	ld l, (0x91b5:16)
	and l, 0x3
	sll l, 2
	ld xix, MidiVoiceNote_Dispatch_Table
	ld	xix, (xix+l)
	jp (xix)
MidiVoiceNote_Dispatch_Table:
	.long MidiVoiceNote_LookupMode0
	.long MidiVoiceNote_LookupMode1
	.long MidiVoiceNote_LookupMode2
	.long MidiVoiceNote_LookupMode3

MidiVoiceNote_LookupMode0:
	ld xiy, MidiVoiceNote_LookupMode0_Data
	ld xbc, 0xf
	ld l, (0x91b8:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode1:
	ld xiy, MidiVoiceNote_LookupMode1_Data
	ld xbc, 0xf
	ld l, (0x91b8:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode2:
	ld xiy, MidiVoiceNote_LookupMode1_Data
	ld xbc, 0xf
	ld l, (0x91b9:16)
	jr MidiPart_FindChannelInTable

MidiVoiceNote_LookupMode3:
	ld xiy, MidiVoiceNote_LookupMode3_Data
	ld xbc, 0x11
	ld l, (0x91b8:16)

MidiPart_FindChannelInTable:
	cp xbc, 0x0
	jr z, MidiPart_NoChannelFound
	ld (0x91c8:16), l
	ld xix, 0xf1a0
	ld	w, (xix+hl)
	ld (0x91cd:16), w

MidiPart_ScanNextEntry:
	ld A, (xiy+)
	cp a, w
	jr z, MidiPart_ScanDone
	djnz16 bc, MidiPart_ScanNextEntry

MidiPart_NoChannelFound:
	ld (0x91b5:16), 255

MidiPart_ScanDone:
	ret

MidiNote_RhythmPartDispatch:
	cp bc, 0x48
	jrl nz, MidiNoteVel_Handler_2
	ld (0x915b:16), bc
	ld (0x915d:16), de
	ld (0x91c8:16), a
	ld (0x90f7:16), c
	ld hl, de
	call PartCtrl_WriteProgramChange
	ld (0x91cf:16), hl
	call PartCtrl_CheckBitmaskBit
	jr nc, MidiPart_ChannelDispatch
	ld xix, 0xfc5a
	call MIDI_SetupChannelParams
	ld wa, (0x915d:16)
	ld (xix), a
	andmi8 (xix + 1), 0x80
	or (xix + 1), w
	pushw hl
	ld a, (0x915e:16)
	ld w, 0x7f:opc
	ldw de, 0x148
	call SwbtWr_QueuePostEvent
	ld a, (0x915d:16)
	ld w, 0xff:opc
	ldw de, 0x48
	call SwbtWr_QueuePostEvent
	popw hl

; MIDI part channel dispatch
MidiPart_ChannelDispatch:
	extz hl
	ld l, (0x91c8:16)
	ld xix, 0xf1a0
	cp	(xix+hl), 0x10
	jrl nz, MidiNoteVel_Handler_2
	ld xix, 0x90ce
	ld	a, (xix+hl)
	cp a, 0x10
	jrl nz, MidiNoteVel_Handler_2
	set 7, a
	ld (0x90e5:16), a
	xor h, h
	ld l, (0xfd50:16)
	and l, 0x3
	sll hl, 2
	ld xix, MidiNote_VelocityHandler_Table
	ld	xix, (xix+hl)
	jp (xix)


MidiNote_VelocityHandler_Table:
	.long MidiNoteVel_Handler_0
	.long MidiNoteVel_Handler_1
	.long MidiNoteVel_Handler_2
	.long MidiNoteVel_Handler_2

MidiNoteVel_Handler_0:
	ldw	bc, 5249
	xor	de, de
	bit	7, (0x91cf:16)
	jr	z, MidiNoteVel_Handler_0_Skip
	inc	1, e
MidiNoteVel_Handler_0_Skip:
	call	MIDI_DispatchCC_Guarded
	xor	h, h
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 20
	ld	e, (0x91cf:16)
	res	7, e
	ld	d, 255:opc
	call	MIDI_DispatchCC_Guarded
	jr	t, MidiNoteVel_Handler_2

MidiNoteVel_Handler_1:
	ldw	bc, 5249
	xor	d, d
	bit	7, (0x915d:16)
	jr	z, MidiNoteVel_Handler_1_Skip
	ld	d, 1:opc
MidiNoteVel_Handler_1_Skip:
	ld	e, (0x915e:16)
	sll	e, 4
	call	MIDI_DispatchCC_Guarded
	extz	hl
	ld	l, (0x91c8:16)
	ld	xix, 0x90ce
	ld	a, (xix+hl)
	set	7, a
	ld	(0x90e5:16), a
	ldw	bc, 20
	ld	e, (0x915d:16)
	res	7, e
	ld	d, 255:opc
	call	MIDI_DispatchCC_Guarded

MidiNoteVel_Handler_2:
	ret

SeqVoice_UpdateTempoParam:
	cp bc, 0x748
	jr nz, SeqVoice_TempoDone
	ld (0x91c8:16), a
	call PartCtrl_CheckBitmaskBit
	jr nc, SeqVoice_TempoDone
	and d, 0x30
	call MIDI_WriteVoiceParamCC
	ld de, (MIDI_MSG_STATUS:16)
	ld wa, (MIDI_MSG_DATA2:16)
	ld (MIDI_MSG_DATA3:16), 0
	call SwbtWr_QueuePostEvent
	set 3, (0x8d52:16)

SeqVoice_TempoDone:
	ret

; PendingParam_ScanAllTables: sends every part's deferred controller value whose bit 7 (pending) is set, and clears
;   the flag.  Five 16-part arrays, named by what fills them (helper-naming batch h evidence): B4 (record 0xB4,
;   filled only through VoiceParam_ModeDispatch_Table; meaning not established), modulation (MidiCC_SetPending-
;   PartModulation, record 0xB2), pitch bend (MidiRx_SetPendingPartPitchBend, 2 bytes per part, record 0xB1),
;   expression (MidiCC_SetPendingPartExpression, record 0xB3; sent by VoiceNote_WriteBankAndCC) and volume
;   (MidiCC_SetPendingPartVolume, CC7).  These scanners were labelled PendingExpr / Vol / Pan / Bank / PartCC
;   until 2026-10-06 (scripts/renaming/rename_kn5000_pending_param_arrays.sed).
PendingParam_ScanAllTables:
	ld xiy, 0x94d2
	ldw bc, 0x10

PendingB4_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingB4_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x94d2
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_SendPendingB4
	pop xiy
	popw bc

PendingB4_NextEntry:
	inc 1, xiy
	djnz16 bc, PendingB4_ScanEntry
	ld xiy, 0x9452
	ldw bc, 0x10

PendingModulation_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingModulation_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9452
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_SendPendingModulation
	pop xiy
	popw bc

PendingModulation_NextEntry:
	inc 1, xiy
	djnz16 bc, PendingModulation_ScanEntry
	ld xiy, 0x9472
	ldw bc, 0x10

PendingPitchBend_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingPitchBend_NextEntry
	resm 7, (xiy)
	ld de, (xiy)
	ld xhl, xiy
	sub xhl, 0x9472
	srl l, 1
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceParam_SendPendingPitchBend
	pop xiy
	popw bc

PendingPitchBend_NextEntry:
	inc 2, xiy
	djnz16 bc, PendingPitchBend_ScanEntry
	ld xiy, 0x9432
	ldw bc, 0x10

PendingExpression_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingExpression_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld xhl, xiy
	sub xhl, 0x9432
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr VoiceNote_WriteBankAndCC
	pop xiy
	popw bc

PendingExpression_NextEntry:
	inc 1, xiy
	djnz16 bc, PendingExpression_ScanEntry
	ld xiy, 0x94b2
	ldw bc, 0x10

PendingVolume_ScanEntry:
	bitm 7, (xiy)
	jr z, PendingVolume_NextEntry
	resm 7, (xiy)
	ld e, (xiy)
	ld hl, iy
	sub xhl, 0x94b2
	ld (0x91c8:16), l
	pushw bc
	push xiy
	calr MidiPartCC_WriteAndDispatch
	pop xiy
	popw bc

PendingVolume_NextEntry:
	inc 1, xiy
	djnz16 bc, PendingVolume_ScanEntry
	ret

PartCtrl_CheckBitmaskBit:
	pushw wa
	pushw bc
	ld wa, (0xf1d0:16)
	ld c, (0x91c8:16)
	inc 1, c

PartCtrl_ShiftBitmask:
	srl wa, 1
	djnz8 c, PartCtrl_ShiftBitmask
	popw bc
	popw wa
	ret

AudioCtrl_SaveAllRegs:
	ld (0x9137:16), xwa
	ld (0x913b:16), xbc
	ld (0x913f:16), xde
	ld (0x9143:16), xhl
	ld (0x9147:16), xix
	ld (0x914b:16), xiy
	ld (0x914f:16), xiz
	ret

AudioCtrl_RestoreAllRegs:
	ld xwa, (0x9137:16)
	ld xbc, (0x913b:16)
	ld xde, (0x913f:16)
	ld xhl, (0x9143:16)
	ld xix, (0x9147:16)
	ld xiy, (0x914b:16)
	ld xiz, (0x914f:16)
	ret

VoiceMode_ParamConfigTables:
	.byte 0xb1, 0x17, 0x7f, 0x02, 0xb2, 0x17, 0x7f, 0x03
	.byte 0xb3, 0x17, 0x7f, 0x04, 0xb0, 0x01, 0x7f, 0x04
	.byte 0x17, 0x00, 0xff, 0x00, 0x17, 0x04, 0x48, 0x01
	.byte 0x17, 0x08, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte	0xff, 0xff, 0xff, 0xff
PartReinit_SendB0Command_Data:	.byte	0x00, 0x02, 0x01, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03
	.byte 0x0f, 0x15, 0x15, 0x00, 0x00, 0x0c, 0x0d, 0x0e
MidiVoiceNote_LookupMode1_Data:
	.byte 0x00, 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03
	.byte	0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13
MidiVoiceNote_LookupMode0_Data:	.byte	0x00
	.byte 0x02, 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04
	.byte	0x05, 0x06, 0x07, 0x11, 0x12, 0x13
MidiVoiceNote_LookupMode3_Data:	.byte	0x00, 0x02
	.byte 0x01, 0x08, 0x09, 0x0a, 0x0b, 0x03, 0x04, 0x05
	.byte 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c, 0x0f, 0xff
TempoRing_InitPartStream_Data:
	.long VoiceMode_ParamConfigTables + 0xb8
	.long VoiceMode_ParamConfigTables + 0x168
	.long VoiceMode_ParamConfigTables + 0x110
	.long VoiceMode_ParamConfigTables + 0x2d0
	.long VoiceMode_ParamConfigTables + 0x314
	.long VoiceMode_ParamConfigTables + 0x358
	.long VoiceMode_ParamConfigTables + 0x39c
	.long VoiceMode_ParamConfigTables + 0x3e0
	.long VoiceMode_ParamConfigTables + 0x204
	.long VoiceMode_ParamConfigTables + 0x248
	.long VoiceMode_ParamConfigTables + 0x28c
	.long VoiceMode_ParamConfigTables + 0x1c0
	.long VoiceMode_ParamConfigTables + 0x4f0
	.long VoiceMode_ParamConfigTables + 0x518
	.long VoiceMode_ParamConfigTables + 0x520
	.long VoiceMode_ParamConfigTables + 0x558
	.long VoiceMode_ParamConfigTables + 0x544
	.long VoiceMode_ParamConfigTables + 0x424
	.long VoiceMode_ParamConfigTables + 0x468
	.long VoiceMode_ParamConfigTables + 0x4ac
	.byte 0xb4, 0x00, 0x7f, 0x06, 0xb1, 0x00, 0x7f, 0x03
	.byte 0xb2, 0x00, 0x7f, 0x04, 0xb3, 0x00, 0x7f, 0x05
	.byte 0x00, 0x00, 0xff, 0x00, 0x00, 0x03, 0xff, 0x01
	.byte 0x00, 0x04, 0x48, 0x01, 0x00, 0x05, 0x7f, 0x01
	.byte 0x00, 0x07, 0x7f, 0x01, 0x00, 0x08, 0x7f, 0x01
	.byte 0x00, 0x0b, 0x7f, 0x01, 0x00, 0x0a, 0xff, 0x01
	.byte 0x00, 0x09, 0x7f, 0x01, 0x44, 0x03, 0xff, 0x01
	.byte 0x44, 0x04, 0xff, 0x01, 0x44, 0x05, 0xff, 0x01
	.byte 0x44, 0x06, 0xff, 0x01, 0x44, 0x07, 0x3f, 0x01
	.byte 0xad, 0x00, 0x7f, 0x01, 0xae, 0x00, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x01, 0x7f, 0x06, 0xb1, 0x01, 0x7f, 0x03
	.byte 0xb2, 0x01, 0x7f, 0x04, 0xb3, 0x01, 0x7f, 0x05
	.byte 0x01, 0x00, 0xff, 0x00, 0x01, 0x03, 0xff, 0x01
	.byte 0x01, 0x04, 0x48, 0x01, 0x01, 0x05, 0x7f, 0x01
	.byte 0x01, 0x07, 0x7f, 0x01, 0x01, 0x08, 0x7f, 0x01
	.byte 0x01, 0x0b, 0x7f, 0x01, 0x01, 0x0a, 0xff, 0x01
	.byte 0x01, 0x09, 0x7f, 0x01, 0x45, 0x03, 0xff, 0x01
	.byte 0x45, 0x04, 0xff, 0x01, 0x45, 0x05, 0xff, 0x01
	.byte 0x45, 0x06, 0xff, 0x01, 0x45, 0x07, 0x3f, 0x01
	.byte 0xad, 0x01, 0x7f, 0x01, 0xae, 0x01, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x02, 0x7f, 0x06, 0xb1, 0x02, 0x7f, 0x03
	.byte 0xb2, 0x02, 0x7f, 0x04, 0xb3, 0x02, 0x7f, 0x05
	.byte 0x02, 0x00, 0xff, 0x00, 0x02, 0x03, 0xff, 0x01
	.byte 0x02, 0x04, 0x48, 0x01, 0x02, 0x05, 0x7f, 0x01
	.byte 0x02, 0x07, 0x7f, 0x01, 0x02, 0x08, 0x7f, 0x01
	.byte 0x02, 0x0b, 0x7f, 0x01, 0x02, 0x0a, 0xff, 0x01
	.byte 0x02, 0x09, 0x7f, 0x01, 0x46, 0x03, 0xff, 0x01
	.byte 0x46, 0x04, 0xff, 0x01, 0x46, 0x05, 0xff, 0x01
	.byte 0x46, 0x06, 0xff, 0x01, 0x46, 0x07, 0x3f, 0x01
	.byte 0xad, 0x02, 0x7f, 0x01, 0xae, 0x02, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x03, 0x7f, 0x06, 0xb1, 0x03, 0x7f, 0x03
	.byte 0xb2, 0x03, 0x7f, 0x04, 0xb3, 0x03, 0x7f, 0x05
	.byte 0x03, 0x00, 0xff, 0x00, 0x03, 0x03, 0xff, 0x01
	.byte 0x03, 0x04, 0x48, 0x01, 0x03, 0x05, 0x7f, 0x01
	.byte 0x03, 0x07, 0x7f, 0x01, 0x03, 0x08, 0x7f, 0x01
	.byte 0x03, 0x0b, 0x7f, 0x01, 0x03, 0x0a, 0xff, 0x01
	.byte 0x03, 0x09, 0x7f, 0x01, 0xad, 0x03, 0x7f, 0x01
	.byte 0xae, 0x03, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x04, 0x7f, 0x06
	.byte 0xb1, 0x04, 0x7f, 0x03, 0xb2, 0x04, 0x7f, 0x04
	.byte 0xb3, 0x04, 0x7f, 0x05, 0x04, 0x00, 0xff, 0x00
	.byte 0x04, 0x03, 0xff, 0x01, 0x04, 0x04, 0x48, 0x01
	.byte 0x04, 0x05, 0x7f, 0x01, 0x04, 0x07, 0x7f, 0x01
	.byte 0x04, 0x08, 0x7f, 0x01, 0x04, 0x0b, 0x7f, 0x01
	.byte 0x04, 0x0a, 0xff, 0x01, 0x04, 0x09, 0x7f, 0x01
	.byte 0xad, 0x04, 0x7f, 0x01, 0xae, 0x04, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x05, 0x7f, 0x06, 0xb1, 0x05, 0x7f, 0x03
	.byte 0xb2, 0x05, 0x7f, 0x04, 0xb3, 0x05, 0x7f, 0x05
	.byte 0x05, 0x00, 0xff, 0x00, 0x05, 0x03, 0xff, 0x01
	.byte 0x05, 0x04, 0x48, 0x01, 0x05, 0x05, 0x7f, 0x01
	.byte 0x05, 0x07, 0x7f, 0x01, 0x05, 0x08, 0x7f, 0x01
	.byte 0x05, 0x0b, 0x7f, 0x01, 0x05, 0x0a, 0xff, 0x01
	.byte 0x05, 0x09, 0x7f, 0x01, 0xad, 0x05, 0x7f, 0x01
	.byte 0xae, 0x05, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x06, 0x7f, 0x06
	.byte 0xb1, 0x06, 0x7f, 0x03, 0xb2, 0x06, 0x7f, 0x04
	.byte 0xb3, 0x06, 0x7f, 0x05, 0x06, 0x00, 0xff, 0x00
	.byte 0x06, 0x03, 0xff, 0x01, 0x06, 0x04, 0x48, 0x01
	.byte 0x06, 0x05, 0x7f, 0x01, 0x06, 0x07, 0x7f, 0x01
	.byte 0x06, 0x08, 0x7f, 0x01, 0x06, 0x0b, 0x7f, 0x01
	.byte 0x06, 0x0a, 0xff, 0x01, 0x06, 0x09, 0x7f, 0x01
	.byte 0xad, 0x06, 0x7f, 0x01, 0xae, 0x06, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x07, 0x7f, 0x06, 0xb1, 0x07, 0x7f, 0x03
	.byte 0xb2, 0x07, 0x7f, 0x04, 0xb3, 0x07, 0x7f, 0x05
	.byte 0x07, 0x00, 0xff, 0x00, 0x07, 0x03, 0xff, 0x01
	.byte 0x07, 0x04, 0x48, 0x01, 0x07, 0x05, 0x7f, 0x01
	.byte 0x07, 0x07, 0x7f, 0x01, 0x07, 0x08, 0x7f, 0x01
	.byte 0x07, 0x0b, 0x7f, 0x01, 0x07, 0x0a, 0xff, 0x01
	.byte 0x07, 0x09, 0x7f, 0x01, 0xad, 0x07, 0x7f, 0x01
	.byte 0xae, 0x07, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x08, 0x7f, 0x06
	.byte 0xb1, 0x08, 0x7f, 0x03, 0xb2, 0x08, 0x7f, 0x04
	.byte 0xb3, 0x08, 0x7f, 0x05, 0x08, 0x00, 0xff, 0x00
	.byte 0x08, 0x03, 0xff, 0x01, 0x08, 0x04, 0x48, 0x01
	.byte 0x08, 0x05, 0x7f, 0x01, 0x08, 0x07, 0x7f, 0x01
	.byte 0x08, 0x08, 0x7f, 0x01, 0x08, 0x0b, 0x7f, 0x01
	.byte 0x08, 0x0a, 0xff, 0x01, 0x08, 0x09, 0x7f, 0x01
	.byte 0xad, 0x08, 0x7f, 0x01, 0xae, 0x08, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x09, 0x7f, 0x06, 0xb1, 0x09, 0x7f, 0x03
	.byte 0xb2, 0x09, 0x7f, 0x04, 0xb3, 0x09, 0x7f, 0x05
	.byte 0x09, 0x00, 0xff, 0x00, 0x09, 0x03, 0xff, 0x01
	.byte 0x09, 0x04, 0x48, 0x01, 0x09, 0x05, 0x7f, 0x01
	.byte 0x09, 0x07, 0x7f, 0x01, 0x09, 0x08, 0x7f, 0x01
	.byte 0x09, 0x0b, 0x7f, 0x01, 0x09, 0x0a, 0xff, 0x01
	.byte 0x09, 0x09, 0x7f, 0x01, 0xad, 0x09, 0x7f, 0x01
	.byte 0xae, 0x09, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0a, 0x7f, 0x06
	.byte 0xb1, 0x0a, 0x7f, 0x03, 0xb2, 0x0a, 0x7f, 0x04
	.byte 0xb3, 0x0a, 0x7f, 0x05, 0x0a, 0x00, 0xff, 0x00
	.byte 0x0a, 0x03, 0xff, 0x01, 0x0a, 0x04, 0x48, 0x01
	.byte 0x0a, 0x05, 0x7f, 0x01, 0x0a, 0x07, 0x7f, 0x01
	.byte 0x0a, 0x08, 0x7f, 0x01, 0x0a, 0x0b, 0x7f, 0x01
	.byte 0x0a, 0x0a, 0xff, 0x01, 0x0a, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0a, 0x7f, 0x01, 0xae, 0x0a, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0b, 0x7f, 0x06, 0xb1, 0x0b, 0x7f, 0x03
	.byte 0xb2, 0x0b, 0x7f, 0x04, 0xb3, 0x0b, 0x7f, 0x05
	.byte 0x0b, 0x00, 0xff, 0x00, 0x0b, 0x03, 0xff, 0x01
	.byte 0x0b, 0x04, 0x48, 0x01, 0x0b, 0x05, 0x7f, 0x01
	.byte 0x0b, 0x07, 0x7f, 0x01, 0x0b, 0x08, 0x7f, 0x01
	.byte 0x0b, 0x0b, 0x7f, 0x01, 0x0b, 0x0a, 0xff, 0x01
	.byte 0x0b, 0x09, 0x7f, 0x01, 0xad, 0x0b, 0x7f, 0x01
	.byte 0xae, 0x0b, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0c, 0x7f, 0x06
	.byte 0xb1, 0x0c, 0x7f, 0x03, 0xb2, 0x0c, 0x7f, 0x04
	.byte 0xb3, 0x0c, 0x7f, 0x05, 0x0c, 0x00, 0xff, 0x00
	.byte 0x0c, 0x03, 0xff, 0x01, 0x0c, 0x04, 0x48, 0x01
	.byte 0x0c, 0x05, 0x7f, 0x01, 0x0c, 0x07, 0x7f, 0x01
	.byte 0x0c, 0x08, 0x7f, 0x01, 0x0c, 0x0b, 0x7f, 0x01
	.byte 0x0c, 0x0a, 0xff, 0x01, 0x0c, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0c, 0x7f, 0x01, 0xae, 0x0c, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb4, 0x0d, 0x7f, 0x06, 0xb1, 0x0d, 0x7f, 0x03
	.byte 0xb2, 0x0d, 0x7f, 0x04, 0xb3, 0x0d, 0x7f, 0x05
	.byte 0x0d, 0x00, 0xff, 0x00, 0x0d, 0x03, 0xff, 0x01
	.byte 0x0d, 0x04, 0x48, 0x01, 0x0d, 0x05, 0x7f, 0x01
	.byte 0x0d, 0x07, 0x7f, 0x01, 0x0d, 0x08, 0x7f, 0x01
	.byte 0x0d, 0x0b, 0x7f, 0x01, 0x0d, 0x0a, 0xff, 0x01
	.byte 0x0d, 0x09, 0x7f, 0x01, 0xad, 0x0d, 0x7f, 0x01
	.byte 0xae, 0x0d, 0x7f, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x0e, 0x7f, 0x06
	.byte 0xb1, 0x0e, 0x7f, 0x03, 0xb2, 0x0e, 0x7f, 0x04
	.byte 0xb3, 0x0e, 0x7f, 0x05, 0x0e, 0x00, 0xff, 0x00
	.byte 0x0e, 0x03, 0xff, 0x01, 0x0e, 0x04, 0x48, 0x01
	.byte 0x0e, 0x05, 0x7f, 0x01, 0x0e, 0x07, 0x7f, 0x01
	.byte 0x0e, 0x08, 0x7f, 0x01, 0x0e, 0x0b, 0x7f, 0x01
	.byte 0x0e, 0x0a, 0xff, 0x01, 0x0e, 0x09, 0x7f, 0x01
	.byte 0xad, 0x0e, 0x7f, 0x01, 0xae, 0x0e, 0x7f, 0x01
	.fill 8, 1, 0xff
	.byte 0xb3, 0x0f, 0x7f, 0x05, 0x0f, 0x00, 0xff, 0x00
	.byte 0x0f, 0x03, 0xff, 0x01, 0x0f, 0x04, 0x48, 0x01
	.byte 0x0f, 0x05, 0x7f, 0x01, 0x0f, 0x07, 0x7f, 0x01
	.byte 0xad, 0x0f, 0x7f, 0x01, 0xae, 0x0f, 0x7f, 0x01
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x00, 0xff, 0x00
	.byte 0x48, 0x08, 0xff, 0x02, 0x48, 0x07, 0x30, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x03, 0x0f, 0x01, 0x48, 0x04, 0x50, 0x01
	.byte 0x48, 0x00, 0xff, 0x00, 0x48, 0x07, 0x30, 0x01
	.byte 0x48, 0x08, 0xff, 0x02, 0x90, 0x00, 0x1f, 0x01
	.byte 0x90, 0x01, 0x1f, 0x01, 0x90, 0x03, 0x02, 0x01
	.byte 0x60, 0x01, 0xc0, 0x01, 0x70, 0x00, 0x07, 0x01
	.byte 0x70, 0x02, 0xff, 0x01, 0x98, 0x0b, 0xc0, 0x01
	.byte 0x98, 0x01, 0x7f, 0x01, 0x98, 0x02, 0x80, 0x01
	.byte 0x98, 0x03, 0x01, 0x01, 0xb0, 0x01, 0x7f, 0x05
	.byte 0x10, 0x03, 0xff, 0x01, 0x11, 0x03, 0xff, 0x01
	.byte 0x12, 0x03, 0xff, 0x01, 0x13, 0x03, 0xff, 0x01
	.byte 0x14, 0x03, 0xff, 0x01, 0x72, 0x03, 0xff, 0x01
	.byte 0x72, 0x07, 0x7f, 0x06, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0xff, 0xff, 0xff, 0xff
VoiceMode3_BuildChannelTable_Data:
	.long VoiceMode_ParamConfigTables + 0x614
	.long VoiceMode_ParamConfigTables + 0x71c
	.long VoiceMode_ParamConfigTables + 0x698
	.long VoiceMode_ParamConfigTables + 0x860
	.long VoiceMode_ParamConfigTables + 0x890
	.long VoiceMode_ParamConfigTables + 0x8c0
	.long VoiceMode_ParamConfigTables + 0x8f0
	.long VoiceMode_ParamConfigTables + 0x920
	.long VoiceMode_ParamConfigTables + 0x7d0
	.long VoiceMode_ParamConfigTables + 0x800
	.long VoiceMode_ParamConfigTables + 0x830
	.long VoiceMode_ParamConfigTables + 0x7a0
	.long VoiceMode_ParamConfigTables + 0x9e0
	.long VoiceMode_ParamConfigTables + 0xa00
	.long VoiceMode_ParamConfigTables + 0xa10
	.long VoiceMode_ParamConfigTables + 0xa50
	.long VoiceMode_ParamConfigTables + 0xa3c
	.long VoiceMode_ParamConfigTables + 0x950
	.long VoiceMode_ParamConfigTables + 0x980
	.long VoiceMode_ParamConfigTables + 0x9b0
	.byte 0x00, 0x03, 0xff, 0x05
	.byte 0x00, 0x04, 0x48, 0x06, 0x00, 0x05, 0x7f, 0x06
	.byte 0x00, 0x07, 0x7f, 0x06, 0x00, 0x08, 0x7f, 0x06
	.byte 0x00, 0x0b, 0x7f, 0x06, 0x00, 0x0a, 0xff, 0x06
	.byte 0x00, 0x09, 0x7f, 0x06, 0x44, 0x03, 0xff, 0x06
	.byte 0x44, 0x04, 0xff, 0x06, 0x44, 0x05, 0xff, 0x06
	.byte 0x44, 0x06, 0xff, 0x06, 0x44, 0x07, 0x3f, 0x06
	.byte 0xad, 0x00, 0x7f, 0x03, 0xae, 0x00, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x01, 0x03, 0xff, 0x05, 0x01, 0x04, 0x48, 0x06
	.byte 0x01, 0x05, 0x7f, 0x06, 0x01, 0x07, 0x7f, 0x06
	.byte 0x01, 0x08, 0x7f, 0x06, 0x01, 0x0b, 0x7f, 0x06
	.byte 0x01, 0x0a, 0xff, 0x06, 0x01, 0x09, 0x7f, 0x06
	.byte 0x45, 0x03, 0xff, 0x06, 0x45, 0x04, 0xff, 0x06
	.byte 0x45, 0x05, 0xff, 0x06, 0x45, 0x06, 0xff, 0x06
	.byte 0x45, 0x07, 0x3f, 0x06, 0xad, 0x01, 0x7f, 0x03
	.byte 0xae, 0x01, 0x7f, 0x04, 0x9a, 0x04, 0xff, 0x06
	.byte 0x9a, 0x05, 0xff, 0x06, 0x9a, 0x06, 0xff, 0x06
	.byte 0x9a, 0x07, 0xff, 0x06, 0x9a, 0x08, 0xff, 0x06
	.byte 0x9a, 0x09, 0xff, 0x06, 0x9a, 0x0a, 0xff, 0x06
	.byte 0x9a, 0x0b, 0xff, 0x06, 0x9a, 0x0c, 0xff, 0x06
	.byte 0x9a, 0x0d, 0xff, 0x06, 0x9a, 0x0e, 0xff, 0x06
	.byte 0x9a, 0x0f, 0xff, 0x06, 0x9a, 0x10, 0xff, 0x06
	.byte 0x9a, 0x11, 0xff, 0x06, 0x9a, 0x12, 0xff, 0x06
	.byte 0x9a, 0x13, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x02, 0x03, 0xff, 0x05
	.byte 0x02, 0x04, 0x48, 0x06, 0x02, 0x05, 0x7f, 0x06
	.byte 0x02, 0x07, 0x7f, 0x06, 0x02, 0x08, 0x7f, 0x06
	.byte 0x02, 0x0b, 0x7f, 0x06, 0x02, 0x0a, 0xff, 0x06
	.byte 0x02, 0x09, 0x7f, 0x06, 0x46, 0x03, 0xff, 0x06
	.byte 0x46, 0x04, 0xff, 0x06, 0x46, 0x05, 0xff, 0x06
	.byte 0x46, 0x06, 0xff, 0x06, 0x46, 0x07, 0x3f, 0x06
	.byte 0xad, 0x02, 0x7f, 0x03, 0xae, 0x02, 0x7f, 0x04
	.byte 0x9a, 0x04, 0xff, 0x06, 0x9a, 0x05, 0xff, 0x06
	.byte 0x9a, 0x06, 0xff, 0x06, 0x9a, 0x07, 0xff, 0x06
	.byte 0x9a, 0x08, 0xff, 0x06, 0x9a, 0x09, 0xff, 0x06
	.byte 0x9a, 0x0a, 0xff, 0x06, 0x9a, 0x0b, 0xff, 0x06
	.byte 0x9a, 0x0c, 0xff, 0x06, 0x9a, 0x0d, 0xff, 0x06
	.byte 0x9a, 0x0e, 0xff, 0x06, 0x9a, 0x0f, 0xff, 0x06
	.byte 0x9a, 0x10, 0xff, 0x06, 0x9a, 0x11, 0xff, 0x06
	.byte 0x9a, 0x12, 0xff, 0x06, 0x9a, 0x13, 0xff, 0x06
	.fill 8, 1, 0xff
	.byte 0x03, 0x03, 0xff, 0x05, 0x03, 0x04, 0x48, 0x06
	.byte 0x03, 0x05, 0x7f, 0x06, 0x03, 0x07, 0x7f, 0x06
	.byte 0x03, 0x08, 0x7f, 0x06, 0x03, 0x0b, 0x7f, 0x06
	.byte 0x03, 0x0a, 0xff, 0x06, 0x03, 0x09, 0x7f, 0x06
	.byte 0xad, 0x03, 0x7f, 0x03, 0xae, 0x03, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x04, 0x03, 0xff, 0x05, 0x04, 0x04, 0x48, 0x06
	.byte 0x04, 0x05, 0x7f, 0x06, 0x04, 0x07, 0x7f, 0x06
	.byte 0x04, 0x08, 0x7f, 0x06, 0x04, 0x0b, 0x7f, 0x06
	.byte 0x04, 0x0a, 0xff, 0x06, 0x04, 0x09, 0x7f, 0x06
	.byte 0xad, 0x04, 0x7f, 0x03, 0xae, 0x04, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x05, 0x03, 0xff, 0x05, 0x05, 0x04, 0x48, 0x06
	.byte 0x05, 0x05, 0x7f, 0x06, 0x05, 0x07, 0x7f, 0x06
	.byte 0x05, 0x08, 0x7f, 0x06, 0x05, 0x0b, 0x7f, 0x06
	.byte 0x05, 0x0a, 0xff, 0x06, 0x05, 0x09, 0x7f, 0x06
	.byte 0xad, 0x05, 0x7f, 0x03, 0xae, 0x05, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x06, 0x03, 0xff, 0x05, 0x06, 0x04, 0x48, 0x06
	.byte 0x06, 0x05, 0x7f, 0x06, 0x06, 0x07, 0x7f, 0x06
	.byte 0x06, 0x08, 0x7f, 0x06, 0x06, 0x0b, 0x7f, 0x06
	.byte 0x06, 0x0a, 0xff, 0x06, 0x06, 0x09, 0x7f, 0x06
	.byte 0xad, 0x06, 0x7f, 0x03, 0xae, 0x06, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x07, 0x03, 0xff, 0x05, 0x07, 0x04, 0x48, 0x06
	.byte 0x07, 0x05, 0x7f, 0x06, 0x07, 0x07, 0x7f, 0x06
	.byte 0x07, 0x08, 0x7f, 0x06, 0x07, 0x0b, 0x7f, 0x06
	.byte 0x07, 0x0a, 0xff, 0x06, 0x07, 0x09, 0x7f, 0x06
	.byte 0xad, 0x07, 0x7f, 0x03, 0xae, 0x07, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x08, 0x03, 0xff, 0x05, 0x08, 0x04, 0x48, 0x06
	.byte 0x08, 0x05, 0x7f, 0x06, 0x08, 0x07, 0x7f, 0x06
	.byte 0x08, 0x08, 0x7f, 0x06, 0x08, 0x0b, 0x7f, 0x06
	.byte 0x08, 0x0a, 0xff, 0x06, 0x08, 0x09, 0x7f, 0x06
	.byte 0xad, 0x08, 0x7f, 0x03, 0xae, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x09, 0x03, 0xff, 0x05, 0x09, 0x04, 0x48, 0x06
	.byte 0x09, 0x05, 0x7f, 0x06, 0x09, 0x07, 0x7f, 0x06
	.byte 0x09, 0x08, 0x7f, 0x06, 0x09, 0x0b, 0x7f, 0x06
	.byte 0x09, 0x0a, 0xff, 0x06, 0x09, 0x09, 0x7f, 0x06
	.byte 0xad, 0x09, 0x7f, 0x03, 0xae, 0x09, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0a, 0x03, 0xff, 0x05, 0x0a, 0x04, 0x48, 0x06
	.byte 0x0a, 0x05, 0x7f, 0x06, 0x0a, 0x07, 0x7f, 0x06
	.byte 0x0a, 0x08, 0x7f, 0x06, 0x0a, 0x0b, 0x7f, 0x06
	.byte 0x0a, 0x0a, 0xff, 0x06, 0x0a, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0a, 0x7f, 0x03, 0xae, 0x0a, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0b, 0x03, 0xff, 0x05, 0x0b, 0x04, 0x48, 0x06
	.byte 0x0b, 0x05, 0x7f, 0x06, 0x0b, 0x07, 0x7f, 0x06
	.byte 0x0b, 0x08, 0x7f, 0x06, 0x0b, 0x0b, 0x7f, 0x06
	.byte 0x0b, 0x0a, 0xff, 0x06, 0x0b, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0b, 0x7f, 0x03, 0xae, 0x0b, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0c, 0x03, 0xff, 0x05, 0x0c, 0x04, 0x48, 0x06
	.byte 0x0c, 0x05, 0x7f, 0x06, 0x0c, 0x07, 0x7f, 0x06
	.byte 0x0c, 0x08, 0x7f, 0x06, 0x0c, 0x0b, 0x7f, 0x06
	.byte 0x0c, 0x0a, 0xff, 0x06, 0x0c, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0c, 0x7f, 0x03, 0xae, 0x0c, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0d, 0x03, 0xff, 0x05, 0x0d, 0x04, 0x48, 0x06
	.byte 0x0d, 0x05, 0x7f, 0x06, 0x0d, 0x07, 0x7f, 0x06
	.byte 0x0d, 0x08, 0x7f, 0x06, 0x0d, 0x0b, 0x7f, 0x06
	.byte 0x0d, 0x0a, 0xff, 0x06, 0x0d, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0d, 0x7f, 0x03, 0xae, 0x0d, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0e, 0x03, 0xff, 0x05, 0x0e, 0x04, 0x48, 0x06
	.byte 0x0e, 0x05, 0x7f, 0x06, 0x0e, 0x07, 0x7f, 0x06
	.byte 0x0e, 0x08, 0x7f, 0x06, 0x0e, 0x0b, 0x7f, 0x06
	.byte 0x0e, 0x0a, 0xff, 0x06, 0x0e, 0x09, 0x7f, 0x06
	.byte 0xad, 0x0e, 0x7f, 0x03, 0xae, 0x0e, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x0f, 0x03, 0xff, 0x05, 0x0f, 0x04, 0x48, 0x06
	.byte 0x0f, 0x05, 0x7f, 0x06, 0x0f, 0x07, 0x7f, 0x06
	.byte 0xad, 0x0f, 0x7f, 0x03, 0xae, 0x0f, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x90, 0x03, 0x02, 0x06
	.byte 0x10, 0x03, 0xff, 0x06, 0x11, 0x03, 0xff, 0x06
	.byte 0x12, 0x03, 0xff, 0x06, 0x13, 0x03, 0xff, 0x06
	.byte 0x14, 0x03, 0xff, 0x06, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x48, 0x05, 0xfc, 0x01
	.byte 0x48, 0x06, 0xfc, 0x01, 0x48, 0x07, 0x30, 0x06
	.fill 8, 1, 0xff
	.byte 0x48, 0x05, 0xfc, 0x01, 0x48, 0x06, 0xfc, 0x01
	.byte 0x48, 0x03, 0x0f, 0x00, 0x48, 0x04, 0x50, 0x06
	.byte 0x48, 0x07, 0x30, 0x06, 0x90, 0x00, 0x1f, 0x06
	.byte 0x90, 0x01, 0x1f, 0x06, 0x90, 0x03, 0x02, 0x06
	.byte 0x60, 0x01, 0xc0, 0x06, 0x70, 0x00, 0x07, 0x06
	.byte 0x70, 0x02, 0xff, 0x06, 0x98, 0x0b, 0xc0, 0x06
	.byte 0x98, 0x01, 0x7f, 0x06, 0x98, 0x02, 0x80, 0x06
	.byte 0x98, 0x03, 0x01, 0x06, 0x10, 0x03, 0xff, 0x06
	.byte 0x11, 0x03, 0xff, 0x06, 0x12, 0x03, 0xff, 0x06
	.byte 0x13, 0x03, 0xff, 0x06, 0x14, 0x03, 0xff, 0x06
	.byte 0x72, 0x03, 0xff, 0x06, 0x72, 0x07, 0x7f, 0x06
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
MidiStream_InitFromLookup_Data:
	.byte 0xff, 0xff, 0xff, 0xff, 0xd7, 0xc4, 0xfc, 0x00
	.byte 0xf3, 0xc4, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.byte 0x0f, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.byte 0x2b, 0xc5, 0xfc, 0x00, 0xff, 0xff, 0xff, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.fill 8, 1, 0xff
	.byte 0xb1, 0x10, 0x7f, 0x01, 0xb2, 0x10, 0x7f, 0x00
	.byte 0xb3, 0x10, 0x7f, 0x02, 0x10, 0x04, 0x08, 0x03
	.byte 0x10, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x11, 0x7f, 0x01
	.byte 0xb2, 0x11, 0x7f, 0x00, 0xb3, 0x11, 0x7f, 0x02
	.byte 0x11, 0x04, 0x08, 0x03, 0x11, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
	.byte 0xb1, 0x12, 0x7f, 0x01, 0xb2, 0x12, 0x7f, 0x00
	.byte 0xb3, 0x12, 0x7f, 0x02, 0x12, 0x04, 0x08, 0x03
	.byte 0x12, 0x08, 0x7f, 0x04, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0xb1, 0x13, 0x7f, 0x01
	.byte 0xb2, 0x13, 0x7f, 0x00, 0xb3, 0x13, 0x7f, 0x02
	.byte 0x13, 0x04, 0x08, 0x03, 0x13, 0x08, 0x7f, 0x04
	.fill 8, 1, 0xff
; MidiCC_RxCC83_SetParamBitsAndQueue: CC83 on part 25: merges bits 6-7 of E into the byte at 0xFDA1 (bits 0-5 kept),
;   puts the result in E and queues the event BC/DE (BC = 0x0B98: param 0x0B of target 0x98, D = 0xC0 mask) on the
;   SwbtWr queue; marks (0x90F8) = 0xFF. What bits 6-7 of that byte control is not established. Basis: callers + body
;   -- the only caller MidiCC_Handler_BitManipulation is CC function 18 <- CC83, taken only for part 25 with bit 2 of
;   (0xFD51) set, E from MidiCC_CC83_ValueMap (value 0/1/2 -> 0x00/0x80/0x40).
MidiCC_RxCC83_SetParamBitsAndQueue:
	ld	(0x90f8:16), 255
	ld	a, (0xfda1:16)
	and	a, 63
	ld	w, e
	and	w, 192
	or	a, w
	ld	(0xfda1:16), a
	ld	e, a
	ld	(MIDI_MSG_STATUS:16), bc
	ld	(MIDI_MSG_DATA2:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	ld	(0x90f8:16), 255
	ld	(MIDI_MSG_STATUS:16), bc
	ld	(MIDI_MSG_DATA2:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret

MidiStream_ApplyPendingParams:
	cp (CURRENT_MODE:16), 14
	jr z, MidiStream_ApplyDone
	ld (0x90f8:16), 255
	and d, 0x7
	jr z, MidiStream_ApplyDone
	call MIDI_WriteVoiceParamCC
	ld a, (MIDI_MSG_DATA3:16)
	and a, 0x7
	jr z, MidiStream_CallFilterAndAudio
	call ToneGen_DispatchByMode
	or (0x90f9:16), 1

MidiStream_CallFilterAndAudio:
	call SwbtWr_WriteVoiceParam_PreserveRegs
	call MIDI_WriteResetSequence

MidiStream_ApplyDone:
	ret

MidiStream_DispatchData:
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_Switch_WritePartParamAndQueue: Switch-controller copy of MidiCC_WritePartParamAndQueue: writes E under mask D
;   into parameter byte B of part C's block (MIDI_WriteVoiceParamDirect, the same body as MIDI_WriteVoiceParamCC) and
;   queues the event on the SwbtWr queue; marks (0x90F8) = 0xFF. The caller has already set E to D (on) or 0 (off).
;   Basis: callers + body -- reached only from MidiCC_Helper_ConditionalESetup, the on/off tail (value >= 0x40) shared
;   by CC64 Sustain, CC94 and CC91's target 0x60.
MidiCC_Switch_WritePartParamAndQueue:
	ld	(0x90f8:16), 255
	call	MIDI_WriteVoiceParamDirect
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_SetPendingPartVolume: Queues a part volume: for target BC with part C <= 31 it stores E | 0x80 in the
;   pending-volume byte 0x94B2[C]; target BC = 0x00B0 instead marks 0x90F8, stores E in MIDI_CC_EXPRESSION_PENDING and
;   calls Audio_WriteBankSelectParams at once. Basis: callers + body -- MidiCC_RxCC7_Volume passes its CC7 target
;   (function 3, the part) and PerfMode_Evt04_VolumeHandler passes C = PART_SELECT, B = 3; the scanners send each
;   flagged byte as function 3.
MidiCC_SetPendingPartVolume:
	cp	bc, 176
	jr	z, MidiStream_ApplyPendingParams_Skip
	cp	c, 31
	jr	ugt, MidiStream_ApplyPendingParams_Return
	set	7, e
	ld	xix, 0x94b2
	ld	(xix+c), e
	jr MidiStream_ApplyPendingParams_Return
MidiStream_ApplyPendingParams_Skip:
	ld (37112:16), 255
	ld	(MIDI_CC_EXPRESSION_PENDING:16), e
	call	Audio_WriteBankSelectParams
MidiStream_ApplyPendingParams_Return:
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_SetPendingPartExpression: Defers a received CC11 (Expression): for target C = 0xB3 and part B <= 31 it stores
;   E | 0x80 in the pending byte 0x9432[B]; the one target C = 0xB0 (part 25's record {0xB0, 0x01}) stores E | 0x80 in
;   0x94F2 instead. MidiStream_LoadAllPresets later sends each flagged 0x9432 byte as event 0xB3 and 0x94F2 as status
;   0xB0, data 1. Basis: callers + body -- the only caller is MidiCC_RxCC11_Expression
;   (MidiCC_PartTargets_CC11_Expression); sibling of MidiCC_SetPendingPartVolume.
MidiCC_SetPendingPartExpression:
	cp	c, 176
	jr	nz, MidiStream_ApplyPendingParams_Skip2
	set	7, e
	ld	(0x94f2:16), e
	jr	MidiStream_ApplyPendingParams_Return2
MidiStream_ApplyPendingParams_Skip2:
	cp	b, 31
	jr	ugt, MidiStream_ApplyPendingParams_Return2
	set	7, e
	ld	xix, 0x9432
	ld	(xix+b), e
MidiStream_ApplyPendingParams_Return2:
	ret
	calr MidiStream_ExtendedDispatch
	ret
; MidiRx_SetPendingPartPitchBend: Defers a received pitch bend: for part B <= 31 stores the word DE (E = LSB | 0x80 as
;   the pending flag, D = MSB) in 0x9472[2 * B]; MidiStream_LoadMultiPartPreset later sends each flagged word as event
;   0xB1 and clears the flag. Basis: callers + body -- the only caller is MidiRx_PitchBend (status Ex,
;   MidiPB_PartTargets {0xB1, part}, E = LSB 0x9635, D = MSB 0x9636); sibling of MidiCC_SetPendingPartVolume.
MidiRx_SetPendingPartPitchBend:
	cp	b, 31
	jr	ugt, MidiStream_ApplyPendingParams_Return2
	set	7, e
	ld	xix, 0x9472
	sll	b, 1
	ld	(xix+b), de
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_SetPendingPartModulation: Defers a received CC1 (Modulation): for part B <= 31 stores E | 0x80 in the pending
;   byte 0x9452[B]; MidiStream_LoadAllPresets later sends each flagged byte as event 0xB2 and clears the flag. Basis:
;   callers + body -- the only caller is MidiCC_RxCC1_Modulation (MidiCC_PartTargets_CC1_Modulation, records {0xB2,
;   part, 0x7F}); sibling of MidiCC_SetPendingPartVolume.
MidiCC_SetPendingPartModulation:
	cp	b, 31
	jr	ugt, MidiStream_ApplyPendingParams_Return2
	set	7, e
	ld	xix, 0x9452
	ld	(xix+b), e
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_DataEntry_WritePartParamAndQueue: Data-entry (CC6/CC38) copy of MidiCC_WritePartParamAndQueue, byte for byte:
;   writes the value into the target part's parameter byte under mask D (MIDI_WriteVoiceParamCC on (0x9644)/(0x9646)),
;   queues the event on the SwbtWr queue and marks (0x90F8) = 0xFF. Basis: callers + body -- the only callers are the
;   CC6 and CC38 data-entry handlers.
MidiCC_DataEntry_WritePartParamAndQueue:
	ld	(0x90f8:16), 255
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_RxFunc08_QueuePartParam: Copy of MidiCC_QueuePartParam for CC functions 8 and 9, byte for byte: queues the
;   saved part-parameter event ((0x9644)/(0x9646) -> MIDI_MSG_STATUS/DATA2) on the SwbtWr queue without writing it
;   into the part block; marks (0x90F8) = 0xFF. Basis: callers + body -- only MidiCC_RxFunc08/09 call it (no
;   controller maps to those functions).
MidiCC_RxFunc08_QueuePartParam:
	ld	(0x90f8:16), 255
	ld	wa, (0x9644:16)
	ld	(MIDI_MSG_STATUS:16), wa
	ld	wa, (0x9646:16)
	ld	(MIDI_MSG_DATA2:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_QueuePartParam: Queues the part-parameter event saved by a MIDI receive handler ((0x9644) part/param,
;   (0x9646) value/mask) on the SwbtWr event queue WITHOUT writing it into the part's parameter block; marks (0x90F8)
;   = 0xFF. Basis: callers + body -- CC functions 12-15 and Channel Pressure.
MidiCC_QueuePartParam:
	ld	(0x90f8:16), 255
	ld	wa, (0x9644:16)
	ld	(MIDI_MSG_STATUS:16), wa
	ld	wa, (0x9646:16)
	ld	(MIDI_MSG_DATA2:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_ResetAllControllers: MIDI Reset All Controllers for part (0x9645): posts the control event (0x9644)/(0x9646),
;   then pitch bend 0x4000 (event 0xB1), channel pressure 0 (0xB4), modulation 0 (0xB2), expression 127 (0xB3), voice
;   param 4 = 0x800, re-posts the original event and sets the part's RPN word (0x9674 + 2*part) to the null 0x7F7F.
;   Basis: callers + body -- MidiCC_Handler_ParamDispatch reaches it through MidiCC_PartTargets_CC121_ResetAll
;   (CC121); the event codes are those of the pitch-bend, channel-pressure, CC1 and CC11 part-target tables.
MidiCC_ResetAllControllers:
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f8:16), 255
	ld	(MIDI_MSG_STATUS:16), bc
	ld	(MIDI_MSG_DATA2:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ld	e, 177:opc
	ld	d, (0x9645:16)
	ldw	wa, 0x4000
	call	SwbtWr_QueuePostEvent
	ld	e, 180:opc
	ld	d, (0x9645:16)
	ldw	wa, 0x7f00
	call	SwbtWr_QueuePostEvent
	ld	e, 178:opc
	ld	d, (0x9645:16)
	ldw	wa, 0x7f00
	call	SwbtWr_QueuePostEvent
	ld	e, 179:opc
	ld	d, (0x9645:16)
	ldw	wa, 0x7f7f
	call	SwbtWr_QueuePostEvent
	ld	c, (0x9645:16)
	ld	b, 4:opc
	ldw	de, 2048
	call	MIDI_WriteVoiceParamDirect
	ld	de, (MIDI_MSG_STATUS:16)
	ld	wa, (MIDI_MSG_DATA2:16)
	call	SwbtWr_QueuePostEvent
	ld	(MIDI_MSG_DATA3:16), 0
	xor	h, h
	ld	l, (0x9645:16)
	sla	hl, 1
	ld	xix, 0x9674
	ldw	(xix+hl), 0x7f7f
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_AllSoundOff_QueuePartParam: CC120 (All Sound Off) copy of MidiCC_QueuePartParam: queues the saved part event
;   ((0x9644) = 0xAE / part, (0x9646) = value / 0x7F -> MIDI_MSG_STATUS / DATA2) on the SwbtWr queue without writing a
;   part parameter; marks (0x90F8) = 0xFF. Same as the first six instructions of MidiCC_ResetAllControllers. Basis:
;   callers + body -- the only caller MidiCC_Handler_TableDispatch reads MidiCC_PartTargets_CC120_AllSoundOff
;   (function 41 <- CC120).
MidiCC_AllSoundOff_QueuePartParam:
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	ld	(0x90f8:16), 255
	ld	(MIDI_MSG_STATUS:16), bc
	ld	(MIDI_MSG_DATA2:16), de
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MidiCC_WritePartParamAndQueue: Writes the received controller value into the target part's parameter byte under mask
;   D (MIDI_WriteVoiceParamCC on (0x9644)/(0x9646)) and queues the same 4-byte event on the SwbtWr queue; marks
;   (0x90F8) = 0xFF. Basis: callers + body -- Pan, Chorus and Reverb receive handlers.
MidiCC_WritePartParamAndQueue:
	ld	(0x90f8:16), 255
	ld	bc, (0x9644:16)
	ld	de, (0x9646:16)
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ret
	calr	MidiStream_ExtendedDispatch
	ret

MidiStream_LoadAllPresets:
	ld xiy, 0x9432
	ld w, 0xb3:opc
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadBankSelect
	ld xiy, 0x9452
	ld w, 0xb2:opc
	calr MidiStream_LoadVoicePreset
	calr MidiStream_LoadMultiPartPreset
	calr MidiStream_LoadPedalPreset
	ret

MidiStream_LoadVoicePreset:
	xor hl, hl

MidiStream_LoadVoiceLoop:
	ld	a, (xiy+hl)
	bit 7, a
	jr z, MidiStream_LoadVoiceNext
	res 7, a
	ld	(xiy+hl), a
	ld (0x90f8:16), 255
	ld (MIDI_MSG_STATUS:16), w
	ld (MIDI_MSG_DATA1:16), l
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadVoiceNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadVoiceLoop
	ret

MidiStream_LoadBankSelect:
	ld xiy, 0x94f2
	ld a, (xiy)
	bit 7, a
	jr z, MidiStream_LoadBankDone
	res 7, a
	ld (xiy), a
	ld (MIDI_CC_MODWHEEL_PENDING:16), a
	call Audio_WriteBankSelectParams
	ld (0x90f8:16), 255
	ld (MIDI_MSG_STATUS:16), 176
	ld (MIDI_MSG_DATA1:16), 1
	ld (MIDI_MSG_DATA2:16), a
	ld (MIDI_MSG_DATA3:16), 127
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadBankDone:
	ret

MidiStream_LoadMultiPartPreset:
	ld xiy, 0x9472
	xor hl, hl
	xor bc, bc

MidiStream_LoadMultiLoop:
	ld	wa, (xiy+hl)
	bit 7, a
	jr z, MidiStream_LoadMultiNext
	res 7, a
	ld	(xiy+hl), wa
	ld (0x90f8:16), 255
	ld c, 0xb1:opc
	ld (MIDI_MSG_STATUS:16), bc
	ld (MIDI_MSG_DATA2:16), wa
	call SwbtWr_WriteParamBlockSafe

MidiStream_LoadMultiNext:
	inc 1, b
	inc 2, hl
	cp b, 0x1f
	jr ule, MidiStream_LoadMultiLoop
	ret

MidiStream_LoadPedalPreset:
	ld xiy, 0x94b2
	xor hl, hl

MidiStream_LoadPedalLoop:
	ld	a, (xiy+hl)
	bit 7, a
	jr z, MidiStream_LoadPedalNext
	res 7, a
	ld	(xiy+hl), a
	ld (0x90f8:16), 255
	ld c, l
	ld b, 0x3:opc
	ld e, a
	ld d, 0x7f:opc
	call MIDI_WriteVoiceParamCC
	call SwbtWr_WriteVoiceParam_PreserveRegs

MidiStream_LoadPedalNext:
	inc 1, hl
	cp l, 0x1f
	jr ule, MidiStream_LoadPedalLoop
	ret

MidiStream_ProcessRxBuffer:
	bit 0, (0xb7e7:16)
	jr nz, MidiStream_ProcessDone
	bit 4, (0xfd50:16)
	jr nz, MidiStream_ProcessDone
	ldw (0x9133:16), 0

MidiStream_DispatchLoop:
	ld xix, 0xc039
	ld hl, (0x9133:16)
	ld	a, (xix+hl)
	cp a, 0xff
	jr z, MidiStream_ProcessDone
	cp a, 0xbf
	jr ugt, MidiStream_AdvanceRxPtr
	extz wa
	sll wa, 2
	ld xiy, MidiStream_DispatchLoop_Data
	ld	xiy, (xiy+wa)
	cp xiy, 0xffffffff
	jr z, MidiStream_AdvanceRxPtr
	ld	bc, (xix+hl)
	inc 2, hl
	ld (0x915b:16), bc
	ld	de, (xix+hl)
	ld (0x915d:16), de
	call (xiy)

MidiStream_AdvanceRxPtr:
	inc 4, (0x9133:16)
	jr MidiStream_DispatchLoop

MidiStream_ProcessDone:
	ret

MidiStream_StatusPrecheck:
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, MidiStream_HandleNoteCC
	sll	hl, 2
	ld	xix, MidiStream_StatusJumpTable
	ld	xix, (xix+hl)
	jp	(xix)


; Jump table: 12 x .long code pointer.  Reader MidiStream_StatusPrecheck:
;   extz hl / ld l, b / cp l, 11 / jr ugt, MidiStream_HandleNoteCC
;   sll hl, 2 / ld xix, MidiStream_StatusJumpTable / ld_rrl xix, xix, hl
;   jp (xix)
; Index: the record's second byte (B), 0-11; above 11 goes to the ret stub MidiStream_HandleNoteCC; 12 entries.
MidiStream_StatusJumpTable:
	.long MidiStream_HandleRunningStatus
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandleNoteCC
	.long MidiStream_HandlePgmChange
	.long MidiStream_HandleChanPressure
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
	.long MidiStream_HandleSysMsg
MidiStream_HandleNoteCC:
	ret
	; --- Indexed dispatch: table lookup, conditional call paths (76 bytes) ---
MidiStream_HandleNoteCC_Body:
	cp c, 0x48
	jr z, MidiStream_HandleNoteCC_Ret
	extz	hl
	ld l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	ld wa, (xix)
	ld	(0x90ea:16), wa
	pushw wa
	ld	(0x90ec:16), c
	call VoiceMode_ParamHandler_4_Helper
	popw wa
	pushw hl
	call MIDI_ParamValidate_CheckBit2
	or	hl, hl
	popw hl
	jr nz, MidiStream_PostNoteCC
	ld b, c
	ld c, 0x81:opc
	ld	de, (0x90ee:16)
	call MIDI_ClearGuardAndDispatchCC
MidiStream_PostNoteCC:
	ld	c, (0x915b:16)
	xor b, b
	ld	e, (0x90f0:16)
	ld d, 0xff:opc
	call MIDI_ClearGuardAndDispatchCC
MidiStream_HandleNoteCC_Ret:
	ret


MidiStream_HandlePgmChange:
	ld	a, d
	and	a, 127
	jr	z, MidiStream_HandlePgmChange_Return
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	ld l, b
	ld	e, (xix+l)
	and e, 127
	ld	d, 127:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_HandlePgmChange_Return:
	ret
MidiStream_HandleChanPressure:
	and	de, 0x4848
	and	e, d
	bit	3, d
	jr	z, MidiStream_HandleChanPressure_Skip
	bit	1, (0x90f9:16)
	jr	z, MidiStream_HandleChanPressure_Skip
	or	e, 8
MidiStream_HandleChanPressure_Skip:
	ld	a, e
	and	e, 72
	jr	z, MidiStream_HandleChanPressure_Return
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	ld	l, b
	ld	e, (xix+l)
	and	d, 72
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_HandleChanPressure_Return:
	ret
MidiStream_HandleSysMsg:
	cp	d, 0:i3
	jr	z, MidiStream_HandleSysMsg_Return
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	ld	l, b
	ld	e, (xix+l)
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_HandleSysMsg_Return:
	ret
; MIDI RX record type 0x48 handler: entry 72 of the record-type table
; read by MidiStream_DispatchLoop (the table rows are .long pointers to this
; address).  With BC = record word +0 and DE = word +2 it dispatches on B
; through MidiStream_SysExJumpTable (4 entries, bounded by the `cp l, 3` below).
MidiStream_RecType48_SysExDispatch:
	extz	hl
	ld	l, b
	cp	l, 3:i3
	jr	ugt, MidiStream_SysExNop
	sll	hl, 2
	ld	xix, MidiStream_SysExJumpTable
	ld	xix, (xix+hl)
	jp	(xix)
; Jump table: 4 x .long code pointer.  Reader MidiStream_RecType48_SysExDispatch:
;   extz hl / ld l, b / cp l, 3:i3 / jr ugt, MidiStream_SysExNop / sll hl, 2
;   ld xix, MidiStream_SysExJumpTable / ld_rrl xix, xix, hl / jp (xix)
; Index: the record's second byte (B), 0-3; 4 entries.
MidiStream_SysExJumpTable:
	.long	MidiStream_HandleRunningStatus
	.long	MidiStream_SysExNop
	.long	MidiStream_SysExNop
	.long	MidiStream_SysExData
MidiStream_SysExNop:
	ret
MidiStream_SysExData:
	cp	(CURRENT_MODE:16), 14
	jr	z, MidiStream_SysExData_Return
	and	d, 7
	jr	z, MidiStream_SysExData_Return
	ldb_d8	e, (0xfc5d)
	and	e, 7
	ld	d, 7:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_SysExData_Return:
	ret
; MIDI RX record type 0x60 handler: entry 96 of the record-type table
; read by MidiStream_DispatchLoop (the table rows are .long pointers to this
; address).  With BC = record word +0 and DE = word +2 it dispatches on B
; through MidiStream_CtrlJumpTable (2 entries, bounded by the `cp l, 1` below).
MidiStream_RecType60_CtrlDispatch:
	extz	hl
	ld	l, b
	cp	l, 1:i3
	jr	ugt, MidiStream_CtrlNop
	sll	hl, 2
	ld	xix, MidiStream_CtrlJumpTable
	ld	xix, (xix+hl)
	jp	(xix)
; Jump table: 2 x .long code pointer.  Reader MidiStream_RecType60_CtrlDispatch:
;   extz hl / ld l, b / cp l, 1:i3 / jr ugt, MidiStream_CtrlNop / sll hl, 2
;   ld xix, MidiStream_CtrlJumpTable / ld_rrl xix, xix, hl / jp (xix)
; Index: the record's second byte (B), 0-1; 2 entries.
MidiStream_CtrlJumpTable:
	.long	MidiStream_CtrlNop
	.long	MidiStream_CtrlData
MidiStream_CtrlNop:
	ret
MidiStream_CtrlData:
	bit	7, d
	jr	z, MidiStream_CtrlData_Return
	bit	7, e
	jr	z, MidiStream_CtrlData_Return
	ldb_d8	e, (0xfc6f)
	and	e, 128
	ld	d, 128:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_CtrlData_Return:
	ret
; MIDI RX record type 0x98 handler: entry 152 of the record-type table
; read by MidiStream_DispatchLoop (the table rows are .long pointers to this
; address).  With BC = record word +0 and DE = word +2 it dispatches on B
; through MidiStream_CmdJumpTable (12 entries, bounded by the `cp l, 11` below).
MidiStream_RecType98_CmdDispatch:
	extz	hl
	ld	l, b
	cp	l, 11
	jr	ugt, MidiStream_CmdNop
	sll	hl, 2
	ld	xix, MidiStream_CmdJumpTable
	ld	xix, (xix+hl)
	jp	(xix)
; Jump table: 12 x .long code pointer.  Reader MidiStream_RecType98_CmdDispatch:
;   extz hl / ld l, b / cp l, 11 / jr ugt, MidiStream_CmdNop / sll hl, 2
;   ld xix, MidiStream_CmdJumpTable / ld_rrl xix, xix, hl / jp (xix)
; Index: the record's second byte (B), 0-11; 12 entries.
MidiStream_CmdJumpTable:
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdPedalNotify
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdNop
	.long	MidiStream_CmdMaskedNotify
MidiStream_CmdNop:
	ret
; --- Routine 1: D/E bit masking, call FCA1FE (23 bytes) ---
MidiStream_CmdMaskedNotify:
	and	d, 192
	jr	z, MidiStream_CmdMaskedDone
	and	e, d
	jr	z, MidiStream_CmdMaskedDone
	ldb_d8	e, (0xfda1)
	and	e, 192
	ld	d, 192:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_CmdMaskedDone:
	ret
; --- Routine 2: conditional E/D setup, dec E, call FCA1FE (36 bytes) ---
MidiStream_CmdPedalNotify:
	cp	(CURRENT_MODE:16), 14
	jr	z, MidiStream_CmdPedalDone
	bit	3, (0xfd50:16)
	jr	z, MidiStream_CmdPedalDone
	and	e, 127
	jr	z, MidiStream_CmdPedalDone
	ld	bc, 0:i3
	ldb_d8	e, (0xfd97)
	and	e, 127
	dec	1, e
	ld	d, 127:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_CmdPedalDone:
	ret
MidiStream_HandlePartSelect:
	cp	a, 72
	jr	z, MidiStream_PartSelectDone
	and	w, 15
	or	w, 128
	pushw	wa
	ld	wa, (xsp)
	stb_d8	(0x90e5), w
	ld	c, a
	ld	b, 4:opc
	ldw	de, 0x800
	call	MIDI_DispatchCC_Guarded
	ld	wa, (xsp)
	stb_d8	(0x90e5), w
	ld	c, 177:opc
	ld	b, a
	ldw	de, 0x4000
	call	MIDI_DispatchCC_Guarded
	ld	wa, (xsp)
	stb_d8	(0x90e5), w
	ld	c, 178:opc
	ld	b, a
	ldw	de, 0x7f00
	call	MIDI_DispatchCC_Guarded
	ld	wa, (xsp)
	stb_d8	(0x90e5), w
	ld	c, 180:opc
	ld	b, a
	ldw	de, 0x7f00
	call	MIDI_DispatchCC_Guarded
	inc	2, xsp
MidiStream_PartSelectDone:
	ret

MidiStream_ExtendedDispatch:
	ret
; MidiRx_ApplyProgramChange: Applies a received program change for the part in (0x9644) (E = program): part 20 is
;   taken as part 72; in modes 14 (MD_CMP) and 17 (MD_SND_ARG) part 72 is ignored; marks (0x90F8) = 0xFF. Part 0 with
;   bit 3 of (0xFD50) set and program < 80 writes program + 1 into param 1 of target 0x98 and queues it. Otherwise it
;   calls the MIDI-mode handler for (0xFD50) bits 0-1 (MidiStream_ExtendedDispatch_Data: Mode0 / Mode1 / nothing /
;   Mode3), which ends in MidiStream_SetPartProgram. Basis: callers + body -- the only caller is MidiRx_ProgramChange
;   (status Cx, MidiPC_PartTargets, gated by bit 4 of 0xFD57).
MidiRx_ApplyProgramChange:
	cp	(0x9644:16), 20
	jr	nz, MidiStream_ExtendedDispatch_Skip8
	ld	(0x9644:16), 72
	ld	c, 72:opc
MidiStream_ExtendedDispatch_Skip8:
	cp	(CURRENT_MODE:16), 14
	jr	z, MidiStream_ExtendedDispatch_Skip9
	cp	(CURRENT_MODE:16), 17
	jr	nz, MidiStream_ExtendedDispatch_Skip10
MidiStream_ExtendedDispatch_Skip9:
	cp	c, 72
	jr	z, MidiStream_ExtendedDispatch_Return4
MidiStream_ExtendedDispatch_Skip10:
	ld	(0x90f8:16), 255
	cp	c, 0:i3
	jr	nz, MidiStream_ExtendedDispatch_Skip11
	bit	3, (0xfd50:16)
	jr	z, MidiStream_ExtendedDispatch_Skip11
	cp	(CURRENT_MODE:16), 14
	jr	z, MidiStream_ExtendedDispatch_Return4
	cp	(CURRENT_MODE:16), 17
	jr	z, MidiStream_ExtendedDispatch_Return4
	cp	e, 80
	jr	nc, MidiStream_ExtendedDispatch_Return4
	inc	1, e
	ldw	bc, 0x198
	ld	d, 127:opc
	call	MIDI_WriteVoiceParamCC
	call	SwbtWr_WriteVoiceParam_PreserveRegs
MidiStream_ExtendedDispatch_Return4:
	ret
	calr	MidiStream_ExtendedDispatch
	ret
MidiStream_ExtendedDispatch_Skip11:
	ldb_d8	l, (0xfd50)
	and	l, 3
	sla	l, 2
	ld	xix, MidiStream_ExtendedDispatch_Data
	ld	xix, (xix+l)
	call	(xix)
MidiStream_ExtDispatch_Mode2Ret:
	ret
	calr	MidiStream_ExtendedDispatch
	ret
; MIDI-mode handler table of the MidiStream_ExtendedDispatch body: 4 x .long
; code pointer.  Reader: the code just above (v10 0xFCCB74) --
;   ldb_d8 l, (0xfd50) / and l, 3 / sla l, 2 / ld xix, <this table> /
;   ld_rr8l xix, xix, l / call (xix)
; so the index is bits 0-1 of RAM 0xFD50 and the count, 4, is that mask.
; Entry 2 is the `ret` in front of the table: that value does nothing.
; Also named MidiStream_ExtendedDispatch_Data (a .set in
; shared/positional_labels.s).  Open: what the four values of 0xFD50 bits 0-1
; select (0xFD50-0xFD5D is the block BitMapOut_RestoreVoiceChannels restores).
MidiStream_ExtendedDispatch_Data:
	.long	MidiStream_ExtDispatch_Mode0
	.long	MidiStream_ExtDispatch_Mode1
	.long	MidiStream_ExtDispatch_Mode2Ret
	.long	MidiStream_ExtDispatch_Mode3
MidiStream_ExtDispatch_Mode0:
	ldw_d16	bc, (0x9644)
	ldw_d16	de, (0x9646)
	stb_d8	(0x90f6), c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiStream_ExtendedDispatch_Return
	ld	a, 17:opc
	cp	c, 72
	jr	nz, MidiStream_ExtendedDispatch_Skip
	ld	a, 15:opc
MidiStream_ExtendedDispatch_Skip:
	cp	e, a
	jr	ugt, MidiStream_ExtendedDispatch_Return
	cp	c, 72
	jr	nz, MidiStream_ExtendedDispatch_Skip2
	ld	l, e
	call	AccVoice_GetChannelCount_Direct
	ld	a, l
	jr	MidiStream_ExtendedDispatch_Join
MidiStream_ExtendedDispatch_Skip2:
	ld	a, e
	pushw	bc
	ld	b, c
	call	MidiStream_GetCategoryLastSlot
	popw	bc
MidiStream_ExtendedDispatch_Join:
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, MidiStream_ExtendedDispatch_Skip3
	ld	l, 20:opc
MidiStream_ExtendedDispatch_Skip3:
	ld	xiy, 0x9412
	ld	h, (xiy+hl)
	cp	h, a
	jr	ugt, MidiStream_ExtendedDispatch_Return
	ld	l, e
	call	SndParam_ApplyProgramChange_Safe
	ld	b, h
	ld	e, l
	ld	d, 255:opc
	calr	MidiStream_SetPartProgram
MidiStream_ExtendedDispatch_Return:
	ret
MidiStream_ExtDispatch_Mode1:
	ldw_d16	bc, (0x9644)
	ldw_d16	de, (0x9646)
	stb_d8	(0x90f7), c
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiStream_ExtendedDispatch_Return2
	extz	hl
	ld	l, c
	cp	c, 72
	jr	nz, MidiStream_ExtendedDispatch_Skip4
	ld	l, 20:opc
MidiStream_ExtendedDispatch_Skip4:
	ld	xiy, 0x9412
	ld	d, (xiy+hl)
	bit	7, d
	jr	z, MidiStream_ExtendedDispatch_Skip5
	res	7, d
	set	7, e
MidiStream_ExtendedDispatch_Skip5:
	ld	b, d
	ld	d, 255:opc
	calr	MidiStream_SetPartProgram
MidiStream_ExtendedDispatch_Return2:
	ret
MidiStream_ExtDispatch_Mode3:
	ldw_d16	bc, (0x9644)
	cp	c, 72
	jr	z, MidiStream_ExtendedDispatch_Return3
	ldw_d16	de, (0x9646)
	extz	hl
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiStream_ExtendedDispatch_Return3
	extz	hl
	ld	l, c
	ld	d, c
	sll	hl, 1
	ld	xiy, 0x93d2
	ld	wa, (xiy+hl)
	ld	(0x90ea:16), wa
	ld	(0x90ec:16), de
	call	MidiStream_ResolveVoiceIndex
	ldw_d16	de, (0x90ee)
	ldb_d8	c, (0x9644)
	ld	b, d
	ld	d, 255:opc
	call	MidiStream_SetPartProgram
MidiStream_ExtendedDispatch_Return3:
	ret
; MidiStream_SetPartProgram: Sets part C's program to E and bank to B: writes them into the part record ((0x90F2)[C]),
;   PartCtrl_WriteProgramChange, MIDI_SetupChannelParams, two SwbtWr voice-param writes and, unless C = 72,
;   SndParam_UpdateVoiceEntry_Safe; skipped when its pre-check sets bit 1 of 0x90FA. Basis: callers + body -- the
;   three MIDI-mode handlers (MidiStream_ExtDispatch_Mode0/1/3, chosen by 0xFD50 bits 0-1) call it with the program
;   and the part's bank from 0x9412.
MidiStream_SetPartProgram:
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	set	0, (0x90fa:16)
	calr	MidiStream_CheckPartProgramAllowed
	bit	1, (0x90fa:16)
	jr	nz, MidiStream_ExtendedDispatch_Epilogue
	stb_d8	(0x90f7), c
	xor	h, h
	ld	l, c
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	ld	(xix), e
	andmi8	(xix+0x1), 128
	or	(xix+0x1), b
	ld	h, b
	ld	l, e
	call	PartCtrl_WriteProgramChange
	call	MIDI_SetupChannelParams
	ld	a, c
	ld	w, 1:opc
	ld	(MIDI_MSG_STATUS:16), wa
	ld	a, b
	ld	w, 127:opc
	ld	(MIDI_MSG_DATA2:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	ld	a, c
	ld	w, 0:opc
	ld	(MIDI_MSG_STATUS:16), wa
	ld	a, e
	ld	w, 255:opc
	ld	(MIDI_MSG_DATA2:16), wa
	call	SwbtWr_WriteVoiceParam_PreserveRegs
	cp	c, 72
	jr	z, MidiStream_ExtendedDispatch_Epilogue
	ld	d, b
	ld	b, 0:opc
	call	SndParam_UpdateVoiceEntry_Safe
MidiStream_ExtendedDispatch_Epilogue:
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
; MidiStream_CheckPartProgramAllowed: Pre-check of MidiStream_SetPartProgram (part C, program E, bank B): clears bit 1
;   of 0x90FA. If bit 0 is set, it clears it and replaces E with the category of (E, B) (PartCtrl_WriteProgramChange,
;   or RegBitManip_Handler_4_Code in MIDI mode 1). It then sets bit 1 (refuse) when part 15 or 20 gets a category
;   other than 15 (drum kits), when parts 16-19, 21 or 22 get category 15, or when part 20 or 16-22 is used while
;   (0x379B) & 0x1F = 0. Registers are preserved. Basis: callers + body -- the only caller MidiStream_SetPartProgram
;   sets bit 0 of 0x90FA, calls it, and skips the program write when bit 1 comes back set.
MidiStream_CheckPartProgramAllowed:
	push	xix
	pushw	hl
	pushw	bc
	pushw	de
	and	(0x90fa:16), 253
	bit	0, (0x90fa:16)
	jr	z, MidiStream_CheckPartProgramAllowed_Skip2
	and	(0x90fa:16), 254
	stb_d8	(0x90f7), c
	ld	l, e
	ld	h, b
	ld	xix, RegBitManip_Handler_4_Code
	ldb_d8	e, (0xfd50)
	and	e, 3
	cp	e, 1:i3
	jr	z, MidiStream_CheckPartProgramAllowed_Skip
	ld	xix, PartCtrl_WriteProgramChange
MidiStream_CheckPartProgramAllowed_Skip:
	call	(xix)
	ld	e, l
MidiStream_CheckPartProgramAllowed_Skip2:
	cp	c, 15
	jr	z, MidiStream_ExtendedDispatch_Skip7
	cp	c, 20
	jr	z, MidiStream_ExtendedDispatch_Skip7
	cp	c, 16
	jr	z, MidiStream_ExtendedDispatch_Skip6
	cp	c, 17
	jr	z, MidiStream_ExtendedDispatch_Skip6
	cp	c, 18
	jr	z, MidiStream_ExtendedDispatch_Skip6
	cp	c, 19
	jr	z, MidiStream_ExtendedDispatch_Skip6
	cp	c, 21
	jr	z, MidiStream_ExtendedDispatch_Skip6
	cp	c, 22
	jr	nz, MidiStream_ExtendedDispatch_Epilogue2
MidiStream_ExtendedDispatch_Skip6:
	call	MidiStream_IsDrumKitCategory
	jr	c, MidiStream_CheckPartProgramAllowed_Skip3
	jr	MidiStream_CheckPartProgramAllowed_Join
MidiStream_ExtendedDispatch_Skip7:
	call	MidiStream_IsDrumKitCategory
	jr	nc, MidiStream_CheckPartProgramAllowed_Skip3
	cp	c, 15
	jr	z, MidiStream_ExtendedDispatch_Epilogue2
MidiStream_CheckPartProgramAllowed_Join:
	push_a
	ldb_d8	a, (0x379b)
	and	a, 31
	pop_a
	jr	nz, MidiStream_ExtendedDispatch_Epilogue2
MidiStream_CheckPartProgramAllowed_Skip3:
	set	1, (0x90fa:16)
MidiStream_ExtendedDispatch_Epilogue2:
	popw	de
	popw	bc
	popw	hl
	pop	xix
	ret
; MidiStream_IsDrumKitCategory: Sets the carry flag when the sound category in E is 15 (drum kits), clears it
;   otherwise. Basis: callers + body -- MidiStream_CheckPartProgramAllowed calls it for parts 15/20 (refuse when no
;   carry: a non-drum category) and for parts 16-19, 21, 22 (refuse on carry); its header names category 15 the drum
;   kits.
MidiStream_IsDrumKitCategory:
	cp	e, 15
	jr	nz, MidiStream_ExtendedDispatch_Helper_Helper2_Skip4
	scf
	ret
MidiStream_ExtendedDispatch_Helper_Helper2_Skip4:
	rcf
	ret
; MidiCC_ApplyBankSelect: Records a received bank select for part (0x9644): E (CC32) into 0x93D2[2p] or, when E =
;   0xFF, D (CC0) into 0x93D3[2p]; then derives the part's bank at 0x9412[p] by the MIDI mode in 0xFD50 bits 0-1
;   (modes 0/2 LSB, 3 MSB, 1 mixed). Part 72 is mapped to 20. Basis: callers + body -- MidiCC_Handler_PairedParamA/B
;   are the CC32/CC0 (bank select) handlers; MidiPkt_SysExBulkTransfer_Data_Helper feeds the same 4-byte block.
MidiCC_ApplyBankSelect:
	cp	(0x9644:16), 72
	jr	nz, MidiCC_ApplyBankSelect_Skip5
	ld	(0x9644:16), 20
	cp	(CURRENT_MODE:16), 14
	jrl	z, MidiStream_ExtDispatch_ModeJump3_Return
MidiCC_ApplyBankSelect_Skip5:
	ldw_d16	bc, (0x9644)
	ldw_d16	de, (0x9646)
	ld	xix, 0x93d2
	ld	xiz, 0x9412
	extz	hl
	ld	l, c
	sll	hl, 1
	cp	e, 255
	jr	z, MidiCC_ApplyBankSelect_Skip6
	res	7, e
	ld	(xix+hl), e
	jr	MidiStream_ExtendedDispatch_Join2
MidiCC_ApplyBankSelect_Skip6:
	res	7, d
	inc	1, xix
	ld	(xix+hl), d
	dec	1, xix
MidiStream_ExtendedDispatch_Join2:
	ld	wa, (xix+hl)
	and	wa, 0x7f7f
	ld	(xix+hl), wa
	srl	hl, 1
	ldb_d8	b, (0xfd50)
	and	b, 3
	sll	b, 2
	ld	xiy, MidiStream_ExtDispatch_Mode3_Data
	ld	xiy, (xiy+b)
	jp	(xiy)
; MIDI-mode jump table: 4 x .long code pointer, indexed by bits 0-1 of RAM
; 0xFD50.  Reader: the code just above (v10 0xFCCE0D) --
;   ldb_d8 b, (0xfd50) / and b, 3 / sll b, 2 / ld xiy, <this table> /
;   ld_rr8l xiy, xiy, b / jp (xiy)
; Modes 0 and 2 share one target.  Also named MidiStream_ExtDispatch_Mode3_Data
; (a .set in shared/positional_labels.s).
MidiStream_ExtDispatch_Mode3_Data:
	.long	MidiStream_ExtDispatch_ModeJump02
	.long	MidiStream_ExtDispatch_ModeJump1
	.long	MidiStream_ExtDispatch_ModeJump02
	.long	MidiStream_ExtDispatch_ModeJump3
MidiStream_ExtDispatch_ModeJump02:
	jr	MidiStream_ExtDispatch_ModeJump3_Join2
MidiStream_ExtDispatch_ModeJump1:
	bit	0, w
	jr	z, MidiStream_ExtDispatch_ModeJump1_Skip8
	srl	a, 4
	and	a, 15
	cp	c, 20
	jr	z, MidiStream_ExtDispatch_ModeJump1_Skip7
	cp	a, 2:i3
	jr	c, MidiStream_ExtDispatch_ModeJump1_Skip7
	cp	a, 6:i3
	jr	nc, MidiStream_ExtDispatch_ModeJump1_Skip7
	xor	a, a
MidiStream_ExtDispatch_ModeJump1_Skip7:
	set	7, a
	jr	MidiStream_ExtDispatch_ModeJump3_Join2
MidiStream_ExtDispatch_ModeJump1_Skip8:
	srl	a, 4
	and	a, 15
	jr	MidiStream_ExtDispatch_ModeJump3_Join2
MidiStream_ExtDispatch_ModeJump3:
	srl	wa, 8
MidiStream_ExtDispatch_ModeJump3_Join2:
	ld	(xiz+hl), a
MidiStream_ExtDispatch_ModeJump3_Return:
	ret
	calr	MidiStream_ExtendedDispatch
	ret
MidiStream_HandleRunningStatus:
	bit	3, (0xfd50:16)
	jr	z, MidiStream_HandleRunningStatus_Skip
	cp	c, 0:i3
	jr	z, MidiStream_HandleRunningStatus_Return
MidiStream_HandleRunningStatus_Skip:
	ldb_d8	l, (0xfd50)
	and	l, 3
	sll	hl, 2
	ld	xix, MidiStream_HandleRunningStatus_Data
	ld	xix, (xix+l)
	jp	(xix)
MidiStream_HandleRunningStatus_Return:
	ret
; MIDI-mode jump table of MidiStream_HandleRunningStatus: 4 x .long code
; pointer, indexed by bits 0-1 of RAM 0xFD50.  Reader: MidiStream_HandleRunningStatus
; (v10 0xFCCE69) -- ldb_d8 l, (0xfd50) / and l, 3 / sll hl, 2 /
; ld xix, <this table> / ld_rr8l xix, xix, l / jp (xix).  Entry 2 is the `ret`
; just above (no action); entry 3 is the routine that follows the 1-byte `ret`
; stub MidiStream_HandleNoteCC.  Also named MidiStream_HandleRunningStatus_Data
; (a .set in shared/positional_labels.s).
MidiStream_HandleRunningStatus_Data:
	.long	MidiStream_RunStatus_Mode0
	.long	MidiStream_RunStatus_Mode1
	.long	MidiStream_HandleRunningStatus_Return
	.long	MidiStream_HandleNoteCC_Body
MidiStream_RunStatus_Mode0:
	cp	c, 72
	jr	nz, MidiStream_HandleRunningStatus_Skip2
	ld	c, 20:opc
MidiStream_HandleRunningStatus_Skip2:
	pushw	bc
	pushw	de
	ld	e, d
	xor	d, d
	ld	b, c
	ld	c, 129:opc
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	ld	d, 255:opc
	call	MIDI_ClearGuardAndDispatchCC
	ret
MidiStream_RunStatus_Mode1:
	cp	c, 72
	jr	nz, MidiStream_HandleRunningStatus_Skip3
	ld	c, 20:opc
MidiStream_HandleRunningStatus_Skip3:
	extz	hl
	ldb_d8	l, (0x915b)
	sll	hl, 2
	ld	xix, (0x90f2:16)
	ld	xix, (xix+hl)
	cp	xix, 0xffffffff
	jr	z, MidiStream_HandleRunningStatus_Return2
	ld	e, (xix)
	pushw	bc
	pushw	de
	xor	d, d
	bit	7, e
	jr	z, MidiStream_HandleRunningStatus_Skip4
	ld	d, 1:opc
MidiStream_HandleRunningStatus_Skip4:
	ld	e, (xix+0x1)
	sll	e, 4
	ld	b, c
	ld	c, 129:opc
	call	MIDI_ClearGuardAndDispatchCC
	popw	de
	popw	bc
	res	7, e
	ld	d, 255:opc
	call	MIDI_ClearGuardAndDispatchCC
MidiStream_HandleRunningStatus_Return2:
	ret
	.byte	0xff	; pad byte; the table below starts at an odd address
; MIDI RX RECORD-TYPE HANDLER TABLE: 192 x .long, one per record type 0x00-0xBF;
; 0xFFFFFFFF = ignore the record.  Reader MidiStream_DispatchLoop (v10 0xFCC868):
; the RX buffer at 0xC039 holds 4-byte records read at offset (0x9133); a type
; byte of 0xFF ends the scan, a type above 0xBF is skipped, otherwise
;   ld xiy, <this table> / ld_sril3 xiy, (xiy + 4*type) / cp xiy, 0xffffffff
; and a real handler is called with the record's first word in BC (also stored
; at 0x915B) and its second in DE (0x915D).  Types 0x00-0x1F all go to
; MidiStream_StatusPrecheck; 0x48, 0x60 and 0x98 go into the
; MidiStream_HandleSysMsg area (0xFCC9CB, 0xFCCA0D, 0xFCCA45); the other 157
; are 0xFFFFFFFF.  Count 192 is the reader's `cp a, 0xbf` bound, and the table
; ends exactly where SoundParam_NotifyChange (0xFCD201) begins.
; ⚠ Only the first 60 entries and 3 bytes of the 61st are in this file: the
; rest (0xFCCFF4-0xFCD200) is the start of boot/interrupt_vector_trampolines.s,
; which spells it as instructions.  Also named MidiStream_DispatchLoop_Data
; (a .set in shared/positional_labels.s).
MidiStream_DispatchLoop_Data:
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	MidiStream_StatusPrecheck
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.long	0xffffffff
	.byte	0xff, 0xff, 0xff
