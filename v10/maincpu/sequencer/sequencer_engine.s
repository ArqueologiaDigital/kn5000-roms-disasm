; =============================================================================
; Sequencer Engine (32K lines)
; =============================================================================
;
; Core sequencer: note editor UI, playback control, voice
; allocation, application event framework, and part/voice data
; management. One of the largest files in the ROM.
;
; Internal codename: "YOKO" (Matsushita/Technics developer name).
; =============================================================================

NoteEditSy_SendCompoundWidgetUpdate:
	call NoteEditSy_SendWidgetCmd2
	jp NoteEditSy_SendModeWidgetCmd

NoteEditSy_UpdateAllWidgets:
	call NoteEditSy_SendWidgetCmd1
	call NoteEditSy_UpdateGridPosition
	call NoteEditSy_SendWidgetCmd3or4
	call NoteEditSy_UpdateNoteDisplay
	bit 0, (0x295f:16)
	call nz, (BmDrEdit_PrepareSecondaryNoteDisplay:24)
	jp NoteEditSy_UpdateEditModeGrid

NoteEditSy_ScanAndSortEntries:
	lda xsp, (xsp - 16)
	push xiz
	ld a, (7512:16)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0x0f
	jr nz, NoteEditSy_DirectCopy
	ld iz, 0:i3

NoteEditSy_ScanLoop:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xf8
	extz bc
	lda xde, (xsp + 4)
	call ApplyProgramChangeAs_Prologue2
	ld de, iz
	mul de, 0xd
	lda xhl, (xsp + 4)
	ld xbc, xhl
	ld xwa, (7504:16)
	add xde, xwa
	lda xhl, (xhl + 13)

NoteEditSy_CopyEntryLoop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, NoteEditSy_CopyEntryLoop
	inc 1, iz
	cp iz, 0x80
	jr c, NoteEditSy_ScanLoop
	jr NoteEditSy_ScanReturn

NoteEditSy_DirectCopy:
	ld xbc, (7504:16)
	ld xwa, xbc
	lda xbc, (xbc+1700)

NoteEditSy_DirectCopyLoop:
	ld (xwa+), 0x20
	cp xwa, xbc
	jr c, NoteEditSy_DirectCopyLoop

NoteEditSy_ScanReturn:
	pop xiz
	lda xsp, (xsp + 16)
	ret

SeqAcc_UpdateAndDispatch:
	call Accomp_UpdateModeFlag
	jr SeqAcc_InitAndDispatch

SeqAcc_InitAndDispatch:
	ldw (9832:16), 1
	set 1, (8970:16)
	res 3, (0x28a7:16)
	set 4, (0x28b3:16)
	call AccWrap_PlayModeDispatch
	jp SeqBuffer_ClearAndInitIteration


; -----------------------------------------------------------------------------
; Section: Sequencer Playback Control
; -----------------------------------------------------------------------------
; Playback state machine: tick handling, start/stop,
; repeat management, tempo, and part activation.
; -----------------------------------------------------------------------------

SeqAcc_HandlePlaybackTick:
	cp (CURRENT_TITLE:16), 136
	jr z, SeqAcc_HandlePlaybackTick_ClearBit2
	bit 1, (8970:16)
	jr z, SeqAcc_HandlePlaybackTick_ClearBit1
	call PartSelect_UpdateDisplayState
	calr SeqAcc_ProcessTempoEvents
	call AccWrap_PlayModeDispatch
	res 0, (9954:16)

SeqAcc_HandlePlaybackTick_ClearBit1:
	res 1, (8970:16)

SeqAcc_HandlePlaybackTick_ClearBit2:
	res 2, (0x28a7:16)
	ret

SeqAcc_HandlePlaybackTick_Data:
	set	3, (10437:16)
	ret

SeqAcc_StartPlaybackFromPosition:
	call Accomp_UpdateModeFlag
	ld bc, (9832:16)
	ld (9964:16), bc
	ld bc, (9832:16)
	ld wa, bc
	extz xwa
	bit 15, wa
	jr nz, SeqAcc_StartPlayback
	ld wa, (0xf238:16)
	cp bc, wa
	jr ule, SeqAcc_AdjustEndAndStart
	sub wa, (0xf23f:16)
	ld (9832:16), wa
	ld (9964:16), wa
	jr SeqAcc_StartPlayback

SeqAcc_AdjustEndAndStart:
	dec 1, wa
	ld (0x28c3:16), wa
	calr SeqAcc_UpdateEndPosition
	ld wa, (0xf238:16)
	sub wa, (0xf23f:16)
	ld (9832:16), wa
	ld (9964:16), wa

SeqAcc_StartPlayback:
	set 0, (0xf23c:16)
	calr SeqAcc_SetupRepeatCount
	call SeqPlay_InitStartState
	jp SeqBuf_Init

SeqAcc_StopPlayback:
	cp (CURRENT_TITLE:16), 136
	jr z, SeqAcc_StopPlayback_HandleTick
	res 0, (0xf23c:16)
	calr SeqAcc_SetupRepeatCount

SeqAcc_StopPlayback_HandleTick:
	calr SeqAcc_HandlePlaybackTick
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	jp SeqPlay_SaveStateAndCleanup

SeqAcc_UpdateEndPosition:
	ld wa, (0x28c3:16)
	cp (0xf23f:16), wa
	ret ule
	ld (0xf23f:16), wa
	ret

SeqAcc_SetupRepeatCount:
	ldw (0x28c6:16), 0
	bit 0, (0xf23c:16)
	jr z, SeqAcc_CheckRepeatEdgeCases
	ld wa, (0xf238:16)
	cp wa, (9832:16)
	jr nz, SeqAcc_CheckRepeatEdgeCases
	ldmm16 0x28c6, 0x28a8

SeqAcc_CheckRepeatEdgeCases:
	ld wa, (9832:16)
	extz xwa
	bit 15, wa
	jr z, SeqAcc_UpdatePlaybackFlags
	cpw (0xf238:16), 1
	jr nz, SeqAcc_UpdatePlaybackFlags
	ldmm16 0x28c6, 0x28a8

SeqAcc_UpdatePlaybackFlags:
	ld a, (0x28a7:16)
	res 3, a
	ld (0x28a7:16), a
	ld bc, (9832:16)
	cp bc, 1:i3
	jr z, SeqPlay_CheckFlagsAndInit
	extz xbc
	bit 15, bc
	jr nz, SeqPlay_CheckFlagsAndInit
	set 3, a
	ld (0x28a7:16), a

SeqPlay_CheckFlagsAndInit:
	jp SeqPlay_InitStartState

SeqPlay_CheckAndActivateParts:
	dec 4, xsp
	ld a, (0x28c5:16)
	bit 5, a
	jr nz, SeqPlay_CheckAndActivateParts_RetFFFF
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqPlay_CheckAndActivateParts_RetFFFF
	cpw (0x28a8:16), 0
	jr nz, SeqPlay_CheckAndActivateParts_Bit6

SeqPlay_CheckAndActivateParts_RetFFFF:
	ldw hl, 0xffff
	jr SeqPlay_CheckAndActivateParts_Return

SeqPlay_CheckAndActivateParts_Bit6:
	bit 6, a
	jr nz, SeqPlay_CheckAndActivateParts_Deactivate
	ei 6
	ldmm8 0x28c8, SEQ_BEAT_TICK
	ldmm16 0x28c9, SEQ_BEAT_COUNT
	ei 0
	ldmm16 8998, 0x28c9
	lda xwa, (xsp)
	ld (xwa), 0x0
	calr SeqPlay_ActivatePartsAndSendOff
	jr SeqPlay_CheckAndActivateParts_SetHL0

SeqPlay_CheckAndActivateParts_Deactivate:
	calr SeqPlay_DeactivateAndSendOff
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr nz, SeqPlay_CheckAndActivateParts_SetHL0
	ld (8956:16), 0

SeqPlay_CheckAndActivateParts_SetHL0:
	ld hl, 0:i3

SeqPlay_CheckAndActivateParts_Return:
	inc 4, xsp
	ret

SeqPlay_ActivatePartsAndSendOff:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	set 6, (0x28c5:16)
	ld wa, (0x28a8:16)
	and wa, (SEQ_ACTIVE_PARTS:16)
	ld (0x28aa:16), wa
	ld (0x28c6:16), wa
	cpl wa
	and (0xf19e:16), wa
	call Audio_CheckSubsystemReady
	ldib_erp 0xfb, 1

SeqPlay_ActivateParts_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_ActivateParts_ShiftDone
	slaa bc

SeqPlay_ActivateParts_ShiftDone:
	and bc, (0x28c6:16)
	jr z, SeqPlay_ActivateParts_LoopNext
	ldto_berp A, 0xfb
	extz wa
	call Part_SendVoiceOffAndCCEvents

SeqPlay_ActivateParts_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_ActivateParts_PartLoop
	ld xwa, (xsp + 2)
	calr SeqPlay_ProcessPartVoices
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqPlay_DeactivateAndSendOff:
	pushw_erp 0xfa
	res 6, (0x28c5:16)
	set 5, (0x28c5:16)
	ldib_erp 0xfb, 1

SeqPlay_DeactivateParts_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_DeactivateParts_ShiftDone
	slaa bc

SeqPlay_DeactivateParts_ShiftDone:
	and bc, (0x28c6:16)
	jr z, SeqPlay_DeactivateParts_LoopNext
	ldto_berp A, 0xfb
	extz wa
	call SeqBuf_WriteNoteOffEntry

SeqPlay_DeactivateParts_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqPlay_DeactivateParts_PartLoop
	ei 6
	ldmm8 0x28cb, SEQ_BEAT_TICK
	ldmm16 0x28cc, SEQ_BEAT_COUNT
	ldw (0x28aa:16), 0
	ei 0
	ldw (0x28a8:16), 0
	ld wa, (0x28c6:16)
	or (0xf19e:16), wa
	call Audio_CheckSubsystemReady
	popw_erp 0xfa
	ret

SeqPlay_ResetPlaybackState:
	ld (0x28c5:16), 0
	ldw (0x28c6:16), 0
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	res 7, a
	ld (0x28b2:16), a
	bit 0, (0xf23c:16)
	jr z, SeqPlay_InitTempoAndActivateParts
	ld wa, (0xf238:16)
	cp wa, (9832:16)
	jr nz, SeqPlay_InitTempoAndActivateParts
	ldmm16 0x28c6, 0x28a8

SeqPlay_InitTempoAndActivateParts:
	call TempoRingBuf_Init
	ld wa, (0x28a8:16)
	cp wa, 0:i3
	jr z, SeqPlay_InitAccAndSetMode
	or (0xf19e:16), wa
	set 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	set 0, (0x28c5:16)
	ld a, (0x28b2:16)
	bit 0, a
	jr z, SeqPlay_InitAccAndSetMode
	set 1, a
	ld (0x28b2:16), a
	ldmm16 9014, 9832

SeqPlay_InitAccAndSetMode:
	call SeqAcc_InitPlaybackState
	ld a, 0xc:opc
	bit 0, (0x28b2:16)
	jr nz, SeqPlay_InitAccAndSetMode_StoreState
	ld a, 0xb:opc

SeqPlay_InitAccAndSetMode_StoreState:
	ld (8956:16), a
	ld hl, 0:i3
	ret

SeqPlay_DataBlock_BBE:
	ld	wa, (0xf238:16)
	inc	1, wa
	ld	(0xf238:16), wa
	cp	wa, 998
	jr	ule, SeqPlay_DataBlock_BBE_Skip
	ldw	(0xf238:16), 998
SeqPlay_DataBlock_BBE_Skip:
	calr	SeqPlay_UpdateStartFromPunchIn
	ld	wa, (0xf238:16)
	cp wa, (62010:16)
	jr	c, SeqPlay_DataBlock_BBE_Skip2
	inc	1, wa
	ld	(0xf23a:16), wa
SeqPlay_DataBlock_BBE_Skip2:
	jrl	SeqAcc_SetupRepeatCount
SeqAccomp_SubHandlerB_Helper:
	ld	wa, (0xf238:16)
	cp	wa, 1:i3
	jr	ule, SeqPlay_DataBlock_BBE_Skip3
	dec	1, wa
	ld	(0xf238:16), wa
SeqPlay_DataBlock_BBE_Skip3:
	calr	SeqPlay_DataBlock_BBE_Helper2
	jrl	SeqAcc_SetupRepeatCount
; SeqPlay_UpdateStartFromPunchIn: After the punch-in measure (0xF238, the "P" in-measure of MT_GetPInMeasString) has
;   changed, recomputes the playback start measure (words 0x2668 and 0x26EC) as punch-in minus the count in 0xF23F,
;   first clamping 0xF23F to punch-in - 1 (0x28C3, SeqAcc_UpdateEndPosition); with bit 0 of 0x28B2 set, punch-in 2
;   instead gives start 0x8002 and 0xF23F = 3, punch-in 3 gives start 1 and 0xF23F = 2, and punch-in 1 leaves both
;   alone. Basis: callers + body -- SeqPlay_DataBlock_BBE (play-screen case 8) calls it after incrementing 0xF238,
;   SeqAccomp_SubHandlerA_Helper (case 9, punch-out up) after pulling 0xF238 below 0xF23A;
;   SeqAcc_StartPlaybackFromPosition does the same subtraction when playback starts.
SeqPlay_UpdateStartFromPunchIn:
	bit	0, (10418:16)
	jr	z, SeqPlay_DataBlock_BBE_Helper_Skip2
	ldw_d16	wa, (62008)
	cp	wa, 2:i3
	jr	nz, SeqPlay_DataBlock_BBE_Helper_Skip
	ldw	(9832:16), 0x8002
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 3
	ret
SeqPlay_DataBlock_BBE_Helper_Skip:
	cp	wa, 3:i3
	jr	nz, SeqPlay_DataBlock_BBE_Skip4
	ldw	(9832:16), 1
	ldw	(9964:16), 1
	ldw	(0xf23f:16), 2
	ret
SeqPlay_DataBlock_BBE_Skip4:
	cp	wa, 3:i3
	ret	c
SeqPlay_DataBlock_BBE_Helper_Skip2:
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	SeqAcc_UpdateEndPosition
	ld	wa, (0xf238:16)
	sub wa, (62015:16)
	ld	(9832:16), wa
	ld	(9964:16), wa
	ret
SeqPlay_DataBlock_BBE_Helper2:
	bit	0, (10418:16)
	jr	z, SeqPlay_DataBlock_BBE_Helper2_Skip2
	ldw_d16	wa, (62008)
	cp	wa, 1:i3
	jr	nz, SeqPlay_DataBlock_BBE_Helper2_Skip
	ldw	(9832:16), 0x8002
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 2
	ret
SeqPlay_DataBlock_BBE_Helper2_Skip:
	cp	wa, 2:i3
	jr	nz, SeqPlay_DataBlock_BBE_Skip5
	ldw	(9832:16), 2
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 3
	ret
SeqPlay_DataBlock_BBE_Skip5:
	cp	wa, 3:i3
	ret	c
SeqPlay_DataBlock_BBE_Helper2_Skip2:
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	SeqAcc_UpdateEndPosition
	ld	wa, (0xf238:16)
	sub wa, (62015:16)
	ld	(9832:16), wa
	ld	(9964:16), wa
	ret
SeqAccomp_SubHandlerA_Helper:
	ld	wa, (0xf23a:16)
	cp	wa, 999
	jr	c, SeqPlay_DataBlock_BBE_Skip6
	ldw	(0xf23a:16), 999
	ldw	wa, 999
	jr	SeqPlay_DataBlock_BBE_Join
SeqPlay_DataBlock_BBE_Skip6:
	inc	1, wa
	ld	(0xf23a:16), wa
	ld	wa, (0xf23a:16)
SeqPlay_DataBlock_BBE_Join:
	cp (62008:16), wa
	ret	c
	dec	1, wa
	ld	(0xf238:16), wa
	calr	SeqPlay_UpdateStartFromPunchIn
	calr	SeqAcc_SetupRepeatCount
	ret
SeqAccomp_SubHandlerB_Helper2:
	ld	wa, (0xf23a:16)
	cp	wa, 2:i3
	jr	ugt, SeqPlay_DataBlock_BBE_Skip7
	ldw	(0xf23a:16), 2
	ld	wa, 2:i3
	jr	SeqPlay_DataBlock_BBE_Join2
SeqPlay_DataBlock_BBE_Skip7:
	dec	1, wa
	ld	(0xf23a:16), wa
	ld	wa, (0xf23a:16)
SeqPlay_DataBlock_BBE_Join2:
	cp (62008:16), wa
	ret	c
	dec	1, wa
	ld	(0xf238:16), wa
	calr	SeqPlay_DataBlock_BBE_Helper2
	calr	SeqAcc_SetupRepeatCount
	ret
SeqAccomp_SubHandlerA_Helper2:
	bit	0, (10418:16)
	jr	z, SeqPlay_DataBlock_BBE_Helper2_Skip3
	cpw	(62008:16), 2
	ret	ule
SeqPlay_DataBlock_BBE_Helper2_Skip3:
	ld	wa, (0xf23f:16)
	cp	wa, 997
	jr	c, SeqPlay_DataBlock_BBE_Skip8
	ldw	(0xf23f:16), 997
	jr	SeqPlay_DataBlock_BBE_Join3
SeqPlay_DataBlock_BBE_Skip8:
	inc	1, wa
	ld	(0xf23f:16), wa
SeqPlay_DataBlock_BBE_Join3:
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	SeqAcc_UpdateEndPosition
	ld	wa, (0xf238:16)
	sub wa, (62015:16)
	ld	(9832:16), wa
	ld	(9964:16), wa
	jrl	SeqAcc_SetupRepeatCount
SeqAccomp_SubHandlerB_Helper3:
	bit	0, (10418:16)
	jr	z, SeqPlay_DataBlock_BBE_Helper2_Skip4
	cpw	(62008:16), 2
	ret	ule
SeqPlay_DataBlock_BBE_Helper2_Skip4:
	ld	wa, (0xf23f:16)
	cp	wa, 0:i3
	jr	z, SeqPlay_DataBlock_BBE_Skip9
	dec	1, wa
	ld	(0xf23f:16), wa
SeqPlay_DataBlock_BBE_Skip9:
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	SeqAcc_UpdateEndPosition
	ld	wa, (0xf238:16)
	sub wa, (62015:16)
	ld	(9832:16), wa
	ld	(9964:16), wa
	jrl	SeqAcc_SetupRepeatCount


; -----------------------------------------------------------------------------
; Section: Part & Voice Processing
; -----------------------------------------------------------------------------
; Per-part voice iteration, event processing, tempo
; events, and playback abort/cleanup.
; -----------------------------------------------------------------------------

SeqPlay_ProcessPartVoices:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldmm16 0x294e, 0x28a8
	ldib_erp 0xfb, 1

SeqPlay_ProcessParts_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_ProcessParts_ShiftDone
	slaa bc

SeqPlay_ProcessParts_ShiftDone:
	and bc, (0x294e:16)
	jr z, SeqPlay_ProcessParts_LoopNext
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqPlay_ProcessParts_HandleResult
	ldw (0x28a8:16), 0
	ldw (0xf19e:16), 0
	ldw (0x28aa:16), 0
	ldw (SEQ_ACTIVE_PARTS:16), 0
	call Audio_CheckSubsystemReady
	ld l, 0x2:opc
	jr SeqPlay_ProcessParts_Return

SeqPlay_ProcessParts_HandleResult:
	set 0, (9834:16)
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldto_berp C, 0xfb
	dec 1, c
	ld a, c
	extz wa
	add wa, wa
	lda xde, (0x28ce:16)
	ld	(xde+wa), iz
	lda xde, (0x291e:16)
	ld	(xde+wa), iz
	ld a, c
	extz wa
	lda xbc, (0x293e:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0x5

SeqPlay_ProcessParts_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jrl ule, SeqPlay_ProcessParts_PartLoop
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jr z, SeqPlay_ProcessParts_Dispatch
	ld xwa, (xsp + 4)
	call Seq_DispatchVoiceConfigEvent

SeqPlay_ProcessParts_Dispatch:
	ld l, 0x0:opc

SeqPlay_ProcessParts_Return:
	pop xiz
	inc 4, xsp
	ret

SeqAcc_ProcessTempoEvents:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld a, (0x28c5:16)
	and a, 0x60
	jrl z, SeqAcc_ProcessTempo_NoActiveParts
	lda xwa, (xsp + 2)
	call TempoRingBuf_ReadEventBytes
	cp l, 0:i3
	jr z, SeqAcc_ProcessTempo_ReadComplete

SeqAcc_ProcessTempo_DispatchLoop:
	lda xwa, (xsp + 2)
	call Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 2)
	call TempoRingBuf_ReadEventBytes
	cp l, 0:i3
	jr nz, SeqAcc_ProcessTempo_DispatchLoop

SeqAcc_ProcessTempo_ReadComplete:
	ld e, (0x28cb:16)
	extz de
	ld bc, (0x28cc:16)
	ldw wa, 0x32
	call SeqData_ValidateProcess
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call VoiceAlloc_ProcessAll
	lda xwa, (0x293e:16)
	ld xbc, xwa
	lda xde, (0x290e:16)
	lda xhl, (0x291e:16)
	lda xix, (0x28ee:16)
	lda xiy, (xwa + 16)

SeqAcc_ProcessTempo_CopyLoop:
	ld WA, (xhl+)
	ld (xix+), WA
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xiy
	jr c, SeqAcc_ProcessTempo_CopyLoop
	ld c, (0x28c5:16)
	ld a, c
	and a, 0x90
	jr nz, SeqPlay_AbortAndCleanup
	bit 5, c
	jr z, SeqPlay_AbortAndCleanup
	ld (9696:16), 0

SeqAcc_ProcessTempo_PartScanLoop:
	ldmm16 0x2950, 0x294e
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqAcc_ProcessTempo_ShiftDone
	slaa bc

SeqAcc_ProcessTempo_ShiftDone:
	and bc, (0x294e:16)
	jr z, SeqAcc_ProcessTempo_NextPart
	calr SeqPlay_ProcessCurrentPart
	bit 7, (0x28c5:16)
	jr z, SeqAcc_ProcessTempo_ClearPartBit

SeqPlay_AbortAndCleanup:
	calr SeqPlay_SelectStopCommand
	jrl SeqPlay_FinalizeAndReturn

SeqAcc_ProcessTempo_ClearPartBit:
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqAcc_ProcessTempo_ClearShiftDone
	slaa bc

SeqAcc_ProcessTempo_ClearShiftDone:
	cpl bc
	and (0x294e:16), bc
	ld a, (9696:16)
	inc 1, a
	extz wa
	call SeqPlay_SetupDualTrack
	ld a, (9696:16)
	extz wa
	add wa, wa
	lda xbc, (0x28ce:16)
	ld	wa, (xbc+wa)
	call Part_StealAndReallocVoices
	ld a, (9780:16)
	ldfr_berp A, 0xfb
	ld a, (9696:16)
	inc 1, a
	ld (9780:16), a
	call SeqPart_BufferSwap
	ldto_berp A, 0xfb
	ld (9780:16), a

SeqAcc_ProcessTempo_NextPart:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jrl c, SeqAcc_ProcessTempo_PartScanLoop
	ldw (0x28aa:16), 0
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw (0x28a8:16), 0
	ld wa, (0x2950:16)
	or (0xf19e:16), wa
	call Audio_CheckSubsystemReady
	set 4, (0x28b3:16)
	res 3, (0x28a7:16)
	ldw wa, 0x23
	call SoundCtrl_SaveAndSendCmd_EE
	jr SeqPlay_FinalizeAndReturn

SeqAcc_ProcessTempo_NoActiveParts:
	ldw (0x28aa:16), 0
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	set 4, (0x28b3:16)
	res 3, (0x28a7:16)
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call Part_ReinitAllActive

SeqPlay_FinalizeAndReturn:
	calr SeqPlay_FinalCleanupAndReset
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

SeqPlay_SelectStopCommand:
	bit 4, (0x28c5:16)
	jr z, SeqPlay_SelectStopCommand_Check88
	ldw wa, 0xf
	jr SeqPlay_SendStopAndClearParts

SeqPlay_SelectStopCommand_Check88:
	cp (ACTIVE_TITLE_PREVIOUS:16), 136
	jr nz, SeqPlay_SelectStopCommand_Default18
	ldw wa, 0x3b
	jr SeqPlay_SendStopAndClearParts

SeqPlay_SelectStopCommand_Default18:
	ldw wa, 0x18

SeqPlay_SendStopAndClearParts:
	call SoundCtrl_SaveAndSendCmd_EE
	res 0, (0x8d88:16)
	ldw (0x28a8:16), 0
	ldw (0x28aa:16), 0
	ldw (SEQ_ACTIVE_PARTS:16), 0
	call Audio_CheckSubsystemReady
	set 4, (0x28b3:16)
	res 3, (0x28a7:16)
	ret

SeqPlay_FinalCleanupAndReset:
	calr SeqPlay_CopyVoicePositionsToParts
	call SeqBuf_Init
	cpw (0xf19e:16), 0
	jr z, SeqPlay_FinalCleanup_ClearFlags
	ld (4596:16), 0
	ld wa, 0:i3
	call BitMapOut_PrepareAndRender

SeqPlay_FinalCleanup_ClearFlags:
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	ld (0x28c5:16), 0
	ld a, (0x28b2:16)
	res 7, a
	res 1, a
	res 2, a
	ld (0x28b2:16), a
	ret

SeqPlay_CopyVoicePositionsToParts:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1

SeqPlay_CopyVoicePos_PartLoop:
	ldto_berp C, 0xfb
	dec 1, c
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqPlay_CopyVoicePos_ShiftDone
	slaa de

SeqPlay_CopyVoicePos_ShiftDone:
	and de, (0x294e:16)
	jr z, SeqPlay_CopyVoicePos_LoopNext
	ld a, c
	extz wa
	add wa, wa
	lda xbc, (0x28ce:16)
	ld	wa, (xbc+wa)
	call Part_StealAndReallocVoices

SeqPlay_CopyVoicePos_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_CopyVoicePos_PartLoop
	popw_erp 0xfa
	ret

SeqPlay_ProcessCurrentPart:
	res 2, (0x287b:16)
	ldmm8 0x2958, 0x28c8
	ldmm16 3299, 0x28c9
	ld a, (9696:16)
	inc 1, a
	extz wa
	call SeqVoice_CountEventsInBar
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPlay_ProcessCurrentPart_Done
	calr SeqPlay_ProcessCurrentPart_Loop
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPlay_ProcessCurrentPart_Return

SeqPlay_ProcessCurrentPart_Done:
	set 7, (0x28c5:16)
	ret

SeqPlay_ProcessCurrentPart_Return:
	ldmm16 0x2952, 0x28af
	ld wa, (9830:16)
	ld (0x2954:16), a
	ldmm8 0x2958, 0x28cb
	ldmm16 3299, 0x28cc
	ld a, (9696:16)
	inc 1, a
	extz wa
	call SeqVoice_CountEventsInBar
	cp (SEQ_ERROR_CODE:16), 0
	call z, (SeqData_ScanForBarPosition:24)
	ldmm16 0x2955, 0x28af
	ld wa, (9830:16)
	ld (0x2957:16), a
	ret

SeqPlay_ProcessCurrentPart_Loop:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	call SeqData_ReadNextByte
	cp (0x2958:16), 0
	jr nz, SeqPlay_ProcessCurrentPart_NextTick
	cp l, 0x82
	jr nz, SeqData_HandleEndMark
	jr SeqData_HandleEndMark_SetError1

SeqPlay_ProcessCurrentPart_NextTick:
	cp l, 0x81
	jr z, SeqData_HandleEndMark

SeqData_SkipCommand_CheckType:
	cp l, 0x82
	jr z, SeqData_HandleEndMark_SetError1
	cp l, 0x84
	jr z, SeqData_HandleEndMark_SetError1
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, (0x2958:16)
	jr c, SeqData_SkipToNextCommand

SeqData_HandleEndMark_NotBarEnd:
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz

SeqData_HandleEndMark_NotEndMark:
	jr SeqData_HandleEndMark_Return

SeqData_SkipToNextCommand:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqData_SkipToNextCommand
	cp l, 0x81
	jr nz, SeqData_SkipCommand_CheckType

SeqData_HandleEndMark:
	cp l, 0x81
	jr nz, SeqData_HandleEndMark_NotEndMark
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqData_HandleEndMark_NotBarEnd

SeqData_HandleEndMark_SetError1:
	ld (SEQ_ERROR_CODE:16), 1

SeqData_HandleEndMark_Return:
	pop xiz
	ret

SeqData_ScanForBarPosition:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	cp (0x2958:16), 0
	jr z, Seq_HandleBarMarkEvent
	call SeqData_ReadNextByte
	cp l, 0x81
	jr z, Seq_HandleBarMarkEvent

SeqData_ScanForBar_CheckMarkers:
	cp l, 0x82
	jr z, Seq_HandleBarMarkEvent
	cp l, 0x84
	jr z, Seq_HandleBarMarkEvent
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, (0x2958:16)
	jr ule, SeqData_SkipToNextCommand_Fwd
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz
	jr Seq_HandleBarMark_Return

SeqData_SkipToNextCommand_Fwd:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqData_SkipToNextCommand_Fwd
	cp l, 0x81
	jr nz, SeqData_ScanForBar_CheckMarkers

Seq_HandleBarMarkEvent:
	cp l, 0x82
	jr nz, Seq_HandleBarMark_Return
	ld wa, (9830:16)
	cp wa, 5:i3
	jr z, Seq_HandleBarMark_AdvanceBlock
	dec 1, wa
	ld (9830:16), wa
	jr Seq_HandleBarMark_Return

Seq_HandleBarMark_AdvanceBlock:
	ld wa, (0x28af:16)
	call PartCtrl_ReadWord_Off1
	ld (0x28af:16), hl
	ldw (9830:16), 255

Seq_HandleBarMark_Return:
	pop xiz
	ret

SeqPlay_CheckAndReactivate:
	lda xsp, (xsp - 10)
	ld a, (0x28c5:16)
	bit 5, a
	jr nz, SeqPlay_CheckAndReactivate_Return
	bit 6, a
	jr nz, SeqPlay_CheckAndReactivate_Return
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqPlay_CheckAndReactivate_Return
	lda xwa, (xsp)
	call TempoRingBuf_ReadEventBytes
	bitm 7, (xsp + 0:8)
	jr nz, SeqPlay_CheckAndReactivate_CopyPos
	ldw wa, 0x68
	call SeqData_SetErrorCode

SeqPlay_CheckAndReactivate_CopyPos:
	lda xbc, (xsp + 1)
	ld a, (xbc)
	ld (0x28c8:16), a
	ldmm16 0x28c9, SEQ_BEAT_COUNT
	ld a, (xbc)
	cp a, (SEQ_BEAT_TICK:16)
	jr ule, SeqPlay_CheckAndReactivate_Activate
	pushw 0x81
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	decw 1, (0x28c9:16)

SeqPlay_CheckAndReactivate_Activate:
	ldmm16 8998, 0x28c9
	ld wa, 1:i3
	call AppEvent_SendModeToggle
	lda xwa, (xsp)
	calr SeqPlay_ActivatePartsAndSendOff

SeqPlay_CheckAndReactivate_Return:
	lda xsp, (xsp + 10)
	ret

SeqPlay_CheckRepeatAndReactivate:
	bit 0, (0x28c5:16)
	ret z
	bit 0, (0xf23c:16)
	ret z
	ld de, (SEQ_BEAT_COUNT:16)
	ld wa, (0xf238:16)
	ld bc, (9832:16)
	cp bc, wa
	jr nz, SeqPlay_CheckRepeat_AltPath
	ld (0x2959:16), de
	ld wa, (0x28a8:16)
	and wa, (SEQ_ACTIVE_PARTS:16)
	ld (0x28c6:16), wa
	jr SeqPlay_CheckRepeat_ApplyMask

SeqPlay_CheckRepeat_AltPath:
	cp wa, 1:i3
	ret nz
	extz xbc
	bit 15, bc
	ret z
	ld (0x2959:16), de
	ld wa, (0x28a8:16)
	and wa, (SEQ_ACTIVE_PARTS:16)
	ld (0x28c6:16), wa

SeqPlay_CheckRepeat_ApplyMask:
	cpl wa
	and (0xf19e:16), wa
	jrl SeqPlay_ReactivatePartsAndResume

SeqPlay_SyncPlaybackPosition:
	pushw iz
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jrl z, SeqPlay_PopIzRet
	ld a, (0x28c5:16)
	bit 0, a
	jrl z, SeqPlay_PopIzRet
	bit 0, (0xf23c:16)
	jrl z, SeqPlay_PopIzRet
	ld iy, (SEQ_BEAT_COUNT:16)
	ld (0x2959:16), iy
	ld a, (9010:16)
	ldfr_berp A, 0xf8
	extz iz
	ld ix, (9008:16)
	ldfr_werp IY, 0xe2
	ldto_werp WA, 0xe2
	sub wa, ix
	ldfr_werp WA, 0xe2
	ld wa, (0x28a8:16)
	ldfr_werp WA, 0xe6
	and wa, (SEQ_ACTIVE_PARTS:16)
	ldfr_werp WA, 0xe6
	ld l, (0x28c5:16)
	ld bc, (9832:16)
	ldto_werp DE, 0xe6
	cpl de
	bit 6, l
	jr nz, SeqPlay_SyncPosition_AltMode
	ld wa, (0xf238:16)
	ld hl, bc
	cp bc, wa
	jr nz, SeqPlay_SyncPosition_CheckPrev
	cp iy, ix
	jr z, SeqPlay_SyncPosition_ApplyParts
	jrl SeqPlay_PopIzRet

SeqPlay_SyncPosition_CheckPrev:
	cp iy, ix
	jrl c, SeqPlay_PopIzRet
	cpw_erp IZ, 0xe2
	jrl ugt, SeqPlay_PopIzRet
	dec 1, wa
	cp wa, hl
	jrl nz, SeqPlay_PopIzRet

SeqPlay_SyncPosition_ApplyParts:
	ldto_werp WA, 0xe6
	ld (0x28aa:16), wa
	ldto_werp WA, 0xe6
	ld (0x28c6:16), wa
	and (0xf19e:16), de
	call Audio_CheckSubsystemReady
	calr SeqPlay_ReactivatePartsAndResume
	jr SeqPlay_PopIzRet

SeqPlay_SyncPosition_AltMode:
	ld wa, (0xf23a:16)
	ld de, bc
	cp bc, wa
	jr z, SeqPlay_SyncPosition_MatchCheck
	cp iy, ix
	jr c, SeqPlay_PopIzRet
	cpw_erp IZ, 0xe2
	jr ugt, SeqPlay_PopIzRet
	inc 1, de
	cp de, wa
	jr z, SeqPlay_SyncPosition_StopAndReset
	jr SeqPlay_PopIzRet

SeqPlay_SyncPosition_MatchCheck:
	cp iy, ix
	jr nz, SeqPlay_PopIzRet

SeqPlay_SyncPosition_StopAndReset:
	res 6, l
	set 5, l
	ld (0x28c5:16), l
	ldw (0x28a8:16), 0
	ldw (0x28aa:16), 0
	ld wa, (0x28c6:16)
	or (0xf19e:16), wa
	ldw (0x28c6:16), 0
	call Audio_CheckSubsystemReady
	ld wa, (0x2959:16)
	dec 1, wa
	ld (0x28cc:16), wa
	ld (0x28cb:16), 95
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr nz, SeqPlay_PopIzRet
	ld (8956:16), 0
	ldmm16 9832, 0xf23a
	call NoteEditSy_SendModeScrollReset

SeqPlay_PopIzRet:
	popw iz
	ret

SeqPlay_ReactivatePartsAndResume:
	dec 4, xsp
	pushw_erp 0xfa
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	set 6, (0x28c5:16)
	ldib_erp 0xfb, 1

SeqPlay_Reactivate_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_Reactivate_ShiftDone
	slaa bc

SeqPlay_Reactivate_ShiftDone:
	and bc, (0x28c6:16)
	jr z, SeqPlay_Reactivate_LoopNext
	ldto_berp A, 0xfb
	extz wa
	call Part_SendVoiceOffAndCCEvents

SeqPlay_Reactivate_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_Reactivate_PartLoop
	ld wa, (0x28a8:16)
	and wa, (SEQ_ACTIVE_PARTS:16)
	ld (0x28aa:16), wa
	lda xwa, (xsp + 2)
	ld (xwa), 0x0
	calr SeqPlay_ProcessPartVoices
	ldmm16 0x28c9, 0x2959
	ld (0x28c8:16), 0
	ldmm16 8998, 0x28c9
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqAcc_InitPlaybackState:
	res 5, (0x28b3:16)
	ldw wa, 0x32
	call SeqNotePool_Init
	res 0, (1115:16)
	call SeqPlay_CheckRepeatActive
	ld (7570:16), l
	cpw (0xf19e:16), 0
	jr nz, SeqAcc_InitPlayback_HasActiveVoices
	cpw (0x28a8:16), 0
	jrl nz, SeqAcc_ClearStepCounter
	ld a, (0x28a7:16)
	res 0, a
	set 1, a
	ld (0x28a7:16), a
	jr SeqAcc_InitPlayback_SetState0

SeqAcc_InitPlayback_HasActiveVoices:
	bit 1, (0x3283:16)
	jr z, SeqAcc_InitPlayback_FindVoices
	set 4, (0x28b3:16)
	jrl SeqAcc_InitPlayback_ReturnZero

SeqAcc_InitPlayback_FindVoices:
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ld (8988:16), l
	ld wa, 0:i3
	ldw bc, 0x10
	call Part_FindVoiceByByte
	ld (8990:16), l
	ld wa, 0:i3
	ldw bc, 0xc
	call Part_FindVoiceByByte
	ld (8992:16), l
	ld wa, 0:i3
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ld (8994:16), l
	ld wa, 0:i3
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ld (8996:16), l
	call BitMapOut_PrepareAndDisplay
	call BitMapOut_PrepareAndDisplaySimple
	set 4, (0x28ac:16)
	bit 3, (0x28a7:16)
	jr nz, SeqAcc_InitPlayback_RestartPath
	calr SeqAcc_InitPlayback_FreshStart
	jr SeqAcc_InitPlayback_CheckDrum

SeqAcc_InitPlayback_RestartPath:
	calr SeqPlay_RestartWithVoiceConfig

SeqAcc_InitPlayback_CheckDrum:
	res 4, (0x28ac:16)
	cpw (8982:16), 0
	jr nz, SeqAcc_InitPlayback_DrumActive
	cpw (0x28a8:16), 0
	jr nz, SeqAcc_ClearStepCounter

SeqAcc_InitPlayback_SetState0:
	ld (8956:16), 0

SeqAcc_ClearStepCounter:
	ld (8968:16), 0
	jr SeqPlay_StateSetExit

SeqAcc_InitPlayback_DrumActive:
	calr SeqPlay_CheckDrumPartAndClearCounters
	cpw (0x28a8:16), 0
	jr nz, SeqPlay_StateSetExit
	cp (7570:16), 0
	jr nz, SeqAcc_InitPlayback_SetState4
	ld (8956:16), 1
	jr SeqPlay_StateSetExit

SeqAcc_InitPlayback_SetState4:
	ld (8956:16), 4

SeqPlay_StateSetExit:
	call SeqPlay_ResetStartState

SeqAcc_InitPlayback_ReturnZero:
	ld l, 0x0:opc
	ret

SeqAcc_InitPlayback_FreshStart:
	res 0, (0x28a6:16)
	call AccWrap_PositionClear
	res 1, (8974:16)
	ld (7560:16), 0
	ld (7562:16), 0
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	ldmm8 9010, 1075
	call SeqMode_SendStatusUpdate
	ldw (9008:16), 0
	ldw (9832:16), 1
	call NoteEditSy_SendModeScrollReset
	ldw (9004:16), 0
	call SeqBuf_Init
	ld (1073:16), 0
	ld a, (0x28a7:16)
	set 0, a
	res 1, a
	ld (0x28a7:16), a
	cp (7570:16), 1
	jr nz, SeqAcc_InitPlayback_ScanParts
	ld wa, (9000:16)
	ld bc, 0:i3
	call Voice_ScanAvailableChannel
	call SeqPart_InitVoiceChannelConfig

SeqAcc_InitPlayback_ScanParts:
	ld wa, 0:i3
	ld bc, 0:i3
	call Voice_ScanAvailableChannel
	ld wa, 0:i3
	call SeqScan_ProcessAllParts
	calr SeqPlay_IterateAllChannels
	ld wa, 0:i3
	ld bc, 0:i3
	calr SeqPlay_AssignAccompVoices
	ld wa, 0:i3
	ld bc, 0:i3
	calr SeqPlay_AssignBassVoices
	ld wa, 0:i3
	ld bc, 0:i3
	calr SeqPlay_AssignChordVoices
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPlay_MidiTimingJP
	ld a, l
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqAcc_InitPlayback_DrumShiftDone
	slaa bc

SeqAcc_InitPlayback_DrumShiftDone:
	and bc, (0xf19e:16)
	jr z, SeqPlay_MidiTimingJP
	extz hl
	ld wa, 0:i3
	ld bc, hl
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqPlay_MidiTimingJP
	set 1, (0x28a7:16)

SeqPlay_MidiTimingJP:
	jp Seq_SyncPositionAndOutputMIDITiming

SeqPlay_RestartWithVoiceConfig:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	ld (1073:16), 0
	ld (7560:16), 0
	ld (7562:16), 0
	ld a, (0x28a7:16)
	set 0, a
	res 1, a
	ld (0x28a7:16), a
	call SeqBuf_Init
	cp (7570:16), 1
	jr nz, SeqPlay_VoiceChannelCfg
	ld wa, (9000:16)
	ld bc, 0:i3
	call Voice_ScanAvailableChannel
	call SeqPart_InitVoiceChannelConfig
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9000:16)
	jr nz, SeqPlay_VoiceChannelCfg
	cp (SEQ_BEAT_TICK:16), 0
	jr nz, SeqPlay_VoiceChannelCfg
	ldib_erp 0xfb, 1
	jr SeqPlay_ConfigureVoiceChannels

SeqPlay_VoiceChannelCfg:
	cpib_erp 0xfb, 0
	jr nz, SeqPlay_ConfigureVoiceChannels
	ld c, (SEQ_BEAT_TICK:16)
	extz bc
	ld wa, (SEQ_BEAT_COUNT:16)
	call Voice_ScanAvailableChannel

SeqPlay_ConfigureVoiceChannels:
	ld wa, (SEQ_BEAT_COUNT:16)
	call SeqScan_ProcessAllParts
	ld c, (SEQ_BEAT_TICK:16)
	extz bc
	ld wa, (SEQ_BEAT_COUNT:16)
	calr SeqPlay_AssignAccompVoices
	ld c, (SEQ_BEAT_TICK:16)
	extz bc
	ld wa, (SEQ_BEAT_COUNT:16)
	calr SeqPlay_AssignBassVoices
	ld c, (SEQ_BEAT_TICK:16)
	extz bc
	ld wa, (SEQ_BEAT_COUNT:16)
	calr SeqPlay_AssignChordVoices
	call VoiceAlloc_TestBitRead
	bit 0, (0x28a6:16)
	jr z, SeqPlay_ConfigVoice_CheckActive
	set 1, (0x28a7:16)

SeqPlay_ConfigVoice_CheckActive:
	ldmm8 9010, 1075
	call SeqMode_SendStatusUpdate
	ldmm16 9008, SEQ_BEAT_COUNT
	cpw (8980:16), 0
	jr z, SeqPlay_ConfigVoice_FindDrum
	set 0, (0x28a7:16)

SeqPlay_ConfigVoice_FindDrum:
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPlay_MidiTimingSync
	ld a, l
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_ConfigVoice_DrumShiftDone
	slaa bc

SeqPlay_ConfigVoice_DrumShiftDone:
	and bc, (0xf19e:16)
	jr z, SeqPlay_MidiTimingSync
	extz hl
	ld wa, 0:i3
	ld bc, hl
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqPlay_MidiTimingSync
	set 1, (0x28a7:16)

SeqPlay_MidiTimingSync:
	call Seq_SyncPositionAndOutputMIDITiming
	popw_erp 0xfa
	ret

SeqPlay_ProcessChannelsAndDrum:
	dec 6, xsp
	push xiz
	res 0, (1115:16)
	bit 1, (0x28a7:16)
	jrl z, SeqPlay_PopIzSkip6Ret
	cpw (0x28a8:16), 0
	jr z, SeqPlay_ProcessCh_FindDrumVoice
	bit 0, (0x28b2:16)
	jrl nz, SeqPlay_PopIzSkip6Ret

SeqPlay_ProcessCh_FindDrumVoice:
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ldfr_berp L, 0xfa
	cp_erpb 0xfa, 0xff
	jr nz, SeqPlay_ProcessCh_FoundDrum
	ld wa, 0:i3
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ldfr_berp L, 0xfa
	cp_erpb 0xfa, 0xff
	jrl z, SeqPlay_PopIzSkip6Ret

SeqPlay_ProcessCh_FoundDrum:
	ldto_berp A, 0xfa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_ProcessCh_DrumShiftDone
	slaa bc

SeqPlay_ProcessCh_DrumShiftDone:
	and bc, (0xf19e:16)
	jrl z, SeqPlay_PopIzSkip6Ret
	cp (CURRENT_MODE:16), 19
	jr nz, SeqPlay_ProcessCh_ValidateChannel
	set 0, (1115:16)
	jrl SeqPlay_PopIzSkip6Ret

SeqPlay_ProcessCh_ValidateChannel:
	ldto_berp C, 0xfa
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jrl z, SeqPlay_PopIzSkip6Ret
	ldto_berp A, 0xfa
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	cp wa, (SEQ_BEAT_COUNT:16)
	jr nz, SeqPlay_PopIzSkip6Ret
	ld a, (xbc + 2)
	cp a, 0x82
	jr z, SeqPlay_PopIzSkip6Ret
	ldfr_berp A, 0xfb
	and_erpb 0xfb, 0xf0
	ldto_berp A, 0xfa
	extz wa
	cp_erpb 0xfb, 0x90
	jr nz, SeqPlay_ProcessCh_ReadData
	cp (xbc + 3), 0x0
	jr nz, SeqPlay_ProcessCh_SkipToReturn
	set 0, (1115:16)
	calr SeqPlay_ProcessTempoVoiceEvent

SeqPlay_ProcessCh_SkipToReturn:
	jr SeqPlay_PopIzSkip6Ret

SeqPlay_ProcessCh_ReadData:
	ldmw2 (xsp + 4), 0x28af
	ld iz, (9830:16)
	lda xhl, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	mriw4 0x93, 0x19, 0xaf, 0x28
	mriw4 0x92, 0x19, 0x66, 0x26

Seq_ScanForBarMarker:
	call SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x81
	jr z, SeqData_BarMarkerWrite
	cp_erpb 0xfb, 0x82
	jr nz, Seq_ScanForBar_AdvanceAndCheck

SeqData_BarMarkerWrite:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	ld (9830:16), iz

SeqPlay_PopIzSkip6Ret:
	pop xiz
	inc 6, xsp
	ret

Seq_ScanForBar_AdvanceAndCheck:
	call SeqData_AdvancePosition
	cp_erpb 0xfb, 0x85
	jr z, Seq_ScanForBarMarker
	bit_erpb 0xfb, 0x07
	jr z, Seq_ScanForBarMarker
	cp_erpb 0xfb, 0x90
	jr nz, Seq_ScanForBarMarker
	call SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr nz, SeqData_BarMarkerWrite
	set 0, (1115:16)
	ldto_berp A, 0xfa
	extz wa
	calr SeqPlay_ProcessTempoVoiceEvent
	jr SeqData_BarMarkerWrite

SeqPlay_ProcessTempoVoiceEvent:
	lda xsp, (xsp - 12)
	ld (xsp + 10), a
	ldw (xsp + 4), 0xffff
	ldw (xsp + 6), 0x0
	ld c, (xsp + 10)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceByte
	cp l, 0xe
	jrl nz, SeqPlay_TempoVoice_Return
	ldmw2 (xsp), 0x28af
	ldmw2 (xsp + 2), 0x2666
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqVoice_ValidateAndWriteDefault

SeqPlay_TempoVoice_ReadLoop:
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqVoice_EventAdvanceLoop
	cp l, 0x82
	jr z, SeqVoice_ChannelValidation_Check
	cp l, 0x84
	jr z, SeqVoice_ChannelValidation_Check
	cp l, 0x81
	jr z, SeqVoice_ChannelValidation_Check
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPlay_TempoVoice_CheckB0
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	call SeqData_ReadNextByte
	cp l, 0x10
	jr ugt, SeqVoice_ChannelValidation_Check
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	incw 1, (xsp + 6)
	jr SeqVoice_EventAdvanceLoop

SeqPlay_TempoVoice_CheckB0:
	cp l, 0xb0
	jr nz, SeqVoice_EventAdvanceLoop
	lda xwa, (xsp + 8)
	calr SeqPlay_TempoVoice_ParseCtrl48
	cp hl, 0:i3
	jr lt, SeqVoice_ValidateAndWriteDefault
	cpw (xsp + 8), 0x0
	jr lt, SeqVoice_EventAdvanceLoop
	cpw (xsp + 8), 0x3
	jr nz, SeqVoice_ValidateAndWriteDefault
	ld wa, (xsp + 8)
	ld (xsp + 4), wa

SeqVoice_EventAdvanceLoop:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	cpw (xsp + 6), 0x3
	jr c, SeqPlay_TempoVoice_ReadLoop

SeqVoice_ChannelValidation_Check:
	cpw (xsp + 4), 0x0
	jr ge, SeqPlay_TempoVoice_CheckNoteCount
	res 0, (1115:16)

SeqPlay_TempoVoice_CheckNoteCount:
	cpw (xsp + 6), 0x3
	jr nc, SeqVoice_ValidateAndWriteDefault
	res 0, (1115:16)

SeqVoice_ValidateAndWriteDefault:
	mriw4 0x97, 0x19, 0xaf, 0x28
	mrdw5 0x9f, 0x02, 0x19, 0x66, 0x26

SeqPlay_TempoVoice_Return:
	lda xsp, (xsp + 12)
	ret

SeqPlay_TempoVoice_ParseCtrl48:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ldw (xwa), 0xffff
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cp l, 0x48
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cp l, 3:i3
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPlay_TempoVoice_ParseCtrl48_Got3

SeqVoice_DataReadError_Return:
	ldw hl, 0xffff
	jr SeqPlay_TempoVoice_ParseCtrl48_Return

SeqPlay_TempoVoice_ParseCtrl48_Got3:
	call SeqData_ReadNextByte
	and l, 0x7
	cp l, 7:i3
	jr nz, SeqData_EventParseExit
	ldto_berp C, 0xfb
	and c, 0x7
	extz bc
	ld xwa, (xsp + 2)
	ld (xwa), bc

SeqData_EventParseExit:
	ld hl, 0:i3

SeqPlay_TempoVoice_ParseCtrl48_Return:
	popw_erp 0xfa
	inc 4, xsp
	ret


; -----------------------------------------------------------------------------
; Section: Drum Parts & Channel Dispatch
; -----------------------------------------------------------------------------
; Drum part handling, counter management, channel
; slot allocation, and MIDI event dispatch.
; -----------------------------------------------------------------------------

SeqPlay_CheckDrumPartAndClearCounters:
	ld a, (8988:16)
	cp a, 0xff
	jr z, SeqPlay_ClearCountersAndProcess
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_DrumPart_ShiftDone
	slaa bc

SeqPlay_DrumPart_ShiftDone:
	ld wa, bc
	and bc, (0xf19e:16)
	jr nz, SeqPlay_DrumPart_SetActiveFlag
	and wa, (8980:16)
	jr z, SeqPlay_ClearCountersAndProcess

SeqPlay_DrumPart_SetActiveFlag:
	set 6, (0x28ac:16)

SeqPlay_ClearCountersAndProcess:
	ld (7530:16), 0
	ld (0x2862:16), 0
	ld (0x2864:16), 0
	ld (0x2866:16), 0
	jrl SeqPlay_ProcessChannelsAndDrum

SeqPlay_IterateAllChannels:
	lda xsp, (xsp - 22)
	pushw_erp 0xfa
	ld (7556:16), 0
	ld (7558:16), 0
	call Part_SendVoiceOff_AllParts
	ld (xsp + 2), 0x1

SeqPlay_IterateCh_PartLoop:
	ld a, (xsp + 2)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_IterateCh_ShiftDone
	slaa bc

SeqPlay_IterateCh_ShiftDone:
	and bc, (0xf19e:16)
	jrl nz, SeqPlay_CheckChannelContinue
	jrl SeqPlay_IncrLoopCounter

SeqPlay_IterateCh_ProcessChannel:
	ld a, (xsp + 2)
	extz wa
	lda xix, (xsp + 12)
	ld l, a
	ld e, l
	dec 1, e
	ld (xsp + 10), e
	extz de
	sla de, 3
	lda xbc, (9016:16)
	ld (xsp + 6), xbc
	exts xde
	add xde, xbc
	ld bc, (xde)
	ld (xix), bc
	ld c, (xde + 3)
	ld (xix + 2), c
	cpw (xix), 0x0
	jrl nz, SeqPlay_IncrLoopCounter
	cp c, 0:i3
	jrl nz, SeqPlay_IncrLoopCounter
	lda xix, (xsp + 16)
	ld (xsp + 4), l
	ld xiy, xix
	ldib_erp 0xe2, 0

SeqPlay_IterateCh_CopyDataLoop:
	ldto_berp L, 0xe2
	extz hl
	inc 2, hl
	ld e, (xsp + 4)
	dec 1, e
	extz de
	sla de, 3
	ld xbc, (xsp + 6)
	lda	xbc, (xbc+de)
	extz xhl
	add xhl, xbc
	ldto_berp E, 0xe2
	extz de
	ld c, (xhl)
	ld	(xiy+de), c
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqPlay_IterateCh_CopyDataLoop
	ld e, (xix)
	ld c, e
	and c, 0xf0
	ldfr_berp C, 0xfb
	cp e, 0x82
	jr nz, SeqPlay_IterateCh_CheckEventType
	ld bc, 1:i3
	ld a, (xsp + 10)
	and a, 0xf
	jr z, SeqPlay_IterateCh_ClearPartBit
	slaa bc

SeqPlay_IterateCh_ClearPartBit:
	cpl bc
	and (8982:16), bc
	and (8980:16), bc
	jrl SeqPlay_IncrLoopCounter

SeqPlay_IterateCh_CheckEventType:
	cp e, 0x81
	jrl z, SeqPlay_IncrLoopCounter
	cp e, 0x84
	jrl z, SeqPlay_IncrLoopCounter
	cp_erpb 0xfb, 0x90
	jrl z, SeqPlay_IncrLoopCounter
	cp e, 0x85
	jr nz, SeqPlay_IterateCh_CheckEvent86
	set 1, (0x28a7:16)
	cp (7572:16), 0
	jrl z, SeqPlay_IterateCh_TempoFlag0
	jrl SeqPlay_IterateCh_TempoFlag1

SeqPlay_IterateCh_CheckEvent86:
	cp e, 0x86
	jr nz, SeqPlay_IterateCh_CheckControlChange
	res 1, (0x28a7:16)
	cp (7572:16), 0
	jrl z, SeqPlay_IterateCh_TempoFlag0
	jrl SeqPlay_IterateCh_TempoFlag1

SeqPlay_IterateCh_CheckControlChange:
	lda xhl, (xix + 4)
	lda xbc, (xix + 5)
	cp_erpb 0xfb, 0xb0
	jrl nz, SeqPlay_IterateCh_NotControlChange
	ld a, (xsp + 2)
	cp a, (8988:16)
	jrl nz, SeqCh_DispatchMidiEvent
	cp (xix + 2), 0x48
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xix + 3)
	cp a, 6:i3
	jr nz, SeqPlay_IterateCh_CtrlChange5
	bitm 2, (xbc)
	jr z, SeqCh_DispatchMidiEvent
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	set 1, (8974:16)
	ldw (4360:16), 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqCh_AllocSlotAndDispatch

SeqPlay_IterateCh_CtrlChange5:
	cp a, 5:i3
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xbc)
	bit 2, a
	jr z, SeqPlay_IterateCh_CtrlChangeBit3
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	set 1, (8974:16)
	ldw (4360:16), 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqCh_AllocSlotAndDispatch

SeqPlay_IterateCh_CtrlChangeBit3:
	bit 3, a
	jr z, SeqCh_DispatchMidiEvent
	bitm 3, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	set 1, (8974:16)
	ldw (4360:16), 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl

SeqCh_AllocSlotAndDispatch:
	call SeqBuf_AllocNextSlot
	ld (8972:16), l
	jr SeqCh_DispatchMidiEvent

SeqPlay_IterateCh_NotControlChange:
	cp e, 0xd3
	jr nz, SeqCh_DispatchMidiEvent
	set 6, (DEMO_CONTROL_FLAGS:16)

SeqCh_DispatchMidiEvent:
	ld a, (xsp + 2)
	extz wa
	cp (7572:16), 0
	jr nz, SeqCh_DispatchMidi_AltProcess
	calr SeqNote_ProcessForChannel
	jr SeqCh_DispatchMidi_CheckResult

SeqCh_DispatchMidi_AltProcess:
	calr SeqNote_ProcessForChannelAlt

SeqCh_DispatchMidi_CheckResult:
	cp l, 0:i3
	jr nz, SeqPlay_IncrLoopCounter
	cp_erpb 0xfb, 0xc0
	jr nz, SeqCh_DispatchChannelConfigLoad
	lda xwa, (xsp + 16)
	cp (xwa + 2), 0x48
	jr nz, SeqCh_DispatchChannelConfigLoad
	cp (xwa + 3), 0x0
	jr nz, SeqCh_DispatchChannelConfigLoad
	cp a, 0x10
	jr nz, SeqCh_DispatchChannelConfigLoad
	ld a, (7564:16)
	extz wa
	ld c, (7566:16)
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (9010:16), l
	call SeqMode_SendStatusUpdate

SeqCh_DispatchChannelConfigLoad:
	cp (7572:16), 0
	jr nz, SeqCh_DispatchMidi_ParseStream
	ld a, (xsp + 2)
	extz wa

SeqPlay_IterateCh_TempoFlag0:
	call SeqCh_LoadChannelConfig
	jr SeqPlay_CheckChannelContinue

SeqCh_DispatchMidi_ParseStream:
	ld a, (xsp + 2)
	extz wa

SeqPlay_IterateCh_TempoFlag1:
	call SeqData_ParseSequenceStream

SeqPlay_CheckChannelContinue:
	ld a, (xsp + 2)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_CheckChCont_ShiftDone
	slaa bc

SeqPlay_CheckChCont_ShiftDone:
	and bc, (8982:16)
	jrl nz, SeqPlay_IterateCh_ProcessChannel

SeqPlay_IncrLoopCounter:
	incm8 1, (xsp + 2)
	cp (xsp + 2), 0x10
	jrl ule, SeqPlay_IterateCh_PartLoop
	popw_erp 0xfa
	lda xsp, (xsp + 22)
	ret

SeqPlay_InitFromDemoRecord:
	res 5, (0x28b3:16)
	ldw (9004:16), 0
	res 0, (0x28a6:16)
	call AccWrap_PositionClear
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	ld l, (1075:16)
	ld (9010:16), l
	call SeqMode_SendStatusUpdate
	ld (1073:16), 0
	set 0, (0x28a7:16)
	call SeqBuf_Init
	res 1, (0x28a7:16)
	calr SeqPlay_InitDemo_LoadVoiceData
	calr SeqPlay_IterateAllChannels
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	call Demo_ProcessRecordEntry
	cp l, 0:i3
	jr z, SeqPlay_InitDemo_ClearRepeatBit
	set 1, (0x28a7:16)
	jr SeqPlay_InitDemo_SyncAndProcess

SeqPlay_InitDemo_ClearRepeatBit:
	res 1, (0x28a7:16)

SeqPlay_InitDemo_SyncAndProcess:
	call Seq_SyncPositionAndOutputMIDITiming
	calr SeqPlay_CheckDrumPartAndClearCounters
	ld (8956:16), 1
	ret

SeqPlay_InitDemo_LoadVoiceData:
	dec 4, xsp
	pushw_erp 0xfa
	ld a, (DEMO_ACTIVE_ENTRY:16)
	ldfr_berp A, 0xfb
	extz wa
	call Demo_GetPresetBaseForPart
	ld (0x283e:16), xhl
	ldto_berp A, 0xfb
	extz wa
	call Demo_GetPresetBaseForPartExt
	ld (xsp + 2), xhl
	ldib_erp 0xfb, 1

SeqPlay_InitDemo_PartLoop:
	ldto_berp E, 0xfb
	dec 1, e
	ld bc, 1:i3
	ld a, e
	and a, 0xf
	jr z, SeqPlay_InitDemo_PartShiftDone
	slaa bc

SeqPlay_InitDemo_PartShiftDone:
	and bc, (0xf19e:16)
	jr z, SeqPlay_InitDemo_PartLoopNext
	ldto_berp A, 0xfb
	mul a, 0x3
	dec 3, a
	ld c, a
	extz bc
	inc 1, bc
	ld xwa, (xsp + 2)
	ld	a, (xwa+bc)
	ldfr_berp A, 0xf0
	extz ix
	ldto_berp A, 0xfb
	extz wa
	ld c, a
	dec 1, c
	extz bc
	sla bc, 2
	lda xhl, (9184:16)
	exts xbc
	add xbc, xhl
	ld (xbc), ix
	ldw (xbc + 2), 0x5
	ld c, e
	extz bc
	sla bc, 3
	lda xde, (9016:16)
	ldw	(xde+bc), 0x0000
	call SeqData_ParseSequenceStream

SeqPlay_InitDemo_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_InitDemo_PartLoop
	ld (8968:16), 0
	ld wa, (0xf19e:16)
	ld (8982:16), wa
	ld (8980:16), wa
	popw_erp 0xfa
	inc 4, xsp
	ret


; -----------------------------------------------------------------------------
; Section: Playback Initialization & Voice Assignment
; -----------------------------------------------------------------------------
; Playback state setup, voice finding, channel
; configuration, and position/flag management.
; -----------------------------------------------------------------------------

SeqPlay_InitializePlayback:
	pushw_erp 0xfa
	res 5, (0x28b3:16)
	ld (7572:16), 0
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqPlay_Init_AccMode87_88
	cp a, 0x88
	jr nz, SeqPlay_Init_CheckRepeatMode

SeqPlay_Init_AccMode87_88:
	call SeqPlay_ResetPlaybackState
	ldfr_berp L, 0xfb
	jr SeqPlay_FindVoicesAndReturn

SeqPlay_Init_CheckRepeatMode:
	bit 1, (0x28b1:16)
	jr nz, SeqPlay_Init_RepeatMode
	calr SeqPlay_InitFreshPlayback
	ldfr_berp L, 0xfb
	jr SeqPlay_FindVoicesAndReturn

SeqPlay_Init_RepeatMode:
	calr SeqPlay_InitResumePlayback
	ldfr_berp L, 0xfb

SeqPlay_FindVoicesAndReturn:
	calr SeqPlay_FindSpecialVoices
	ldto_berp L, 0xfb
	popw_erp 0xfa
	ret

SeqPlay_InitFreshPlayback:
	calr SeqAcc_InitPlaybackState
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	res 7, a
	ld (0x28b2:16), a
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	res 3, (0x28a7:16)
	cpw (0x28a8:16), 0
	jrl z, SeqPlay_InitFresh_Return
	ldw (8998:16), 0
	ldw (8954:16), 0xffff
	ld l, 0x1:opc
	ld c, 0x0:opc

SeqPlay_InitFresh_PartClearLoop:
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqPlay_InitFresh_PartShiftDone
	slaa de

SeqPlay_InitFresh_PartShiftDone:
	and de, (0x28a8:16)
	jr z, SeqPlay_InitFresh_PartLoopNext
	ld a, l
	extz wa
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqPlay_InitFresh_ClearBit
	slaa de

SeqPlay_InitFresh_ClearBit:
	cpl de
	and (8980:16), de

SeqPlay_InitFresh_PartLoopNext:
	inc 1, l
	inc 1, c
	cp l, 0x10
	jr ule, SeqPlay_InitFresh_PartClearLoop
	ld a, (0x28b2:16)
	bit 0, a
	jr z, SeqPlay_InitFresh_SetPosition
	set 1, a
	ld (0x28b2:16), a
	ld wa, (9832:16)
	ld (9014:16), wa
	set 3, (0x28b3:16)
	call Audio_CheckSubsystemReady

SeqPlay_InitFresh_SetPosition:
	ldw (9008:16), 0
	call NoteEditSy_SendModeScrollReset
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	ld a, (1075:16)
	ld (9010:16), a
	call SeqMode_SendStatusUpdate
	cpw (0xf19e:16), 0
	jr z, SeqPlay_InitFresh_NoVoices
	set 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	jr SeqPlay_InitFresh_TempoInit

SeqPlay_InitFresh_NoVoices:
	ldw (8980:16), 0
	ld a, (0x28a7:16)
	set 0, a
	set 1, a
	ld (0x28a7:16), a
	call SeqBuf_Init

SeqPlay_InitFresh_TempoInit:
	call Audio_CheckSubsystemReady
	call TempoRingBuf_Init
	call BitMapOut_ComputeRegionDelta
	bit 0, (0x28b2:16)
	jr nz, SeqPlay_InitFresh_State8orC
	cpw (0xf19e:16), 0
	jr z, SeqPlay_InitFresh_StateB
	ld a, 0xb:opc
	jr SeqPlay_StoreChannelVal

SeqPlay_InitFresh_StateB:
	ld a, 0x7:opc
	jr SeqPlay_StoreChannelVal

SeqPlay_InitFresh_State8orC:
	ld a, 0x8:opc
	cpw (0xf19e:16), 0
	jr z, SeqPlay_StoreChannelVal
	ld a, 0xc:opc

SeqPlay_StoreChannelVal:
	ld (8956:16), a

SeqPlay_InitFresh_Return:
	ld l, 0x0:opc
	ret

SeqPlay_InitResumePlayback:
	push xiz
	calr SeqAcc_InitPlaybackState
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	res 7, a
	ld (0x28b2:16), a
	cpw (0x28a8:16), 0
	jrl z, SeqPlay_InitResume_Return
	ldmm16 8998, SEQ_BEAT_COUNT
	ldw (8954:16), 0xffff
	call SeqVoice_InitForRepeatMode
	ldib_erp 0xfb, 1

SeqPlay_InitResume_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_InitResume_ShiftDone
	slaa bc

SeqPlay_InitResume_ShiftDone:
	and bc, (0x28a8:16)
	jr z, SeqPlay_InitResume_LoopNext
	ldto_berp A, 0xfb
	ld (8986:16), a
	ldto_berp A, 0xfb
	extz wa
	ld bc, 1:i3
	call Chan_SetActiveBit

SeqPlay_InitResume_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_InitResume_PartLoop
	ld a, (0x28b2:16)
	ld c, a
	res 1, c
	ld a, c
	ld (0x28b2:16), c
	bit 0, c
	jr z, SeqPlay_InitResume_SetFlags
	set 1, a
	ld (0x28b2:16), a
	ld wa, (9832:16)
	ld (9014:16), wa

SeqPlay_InitResume_SetFlags:
	set 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	ldmm16 9008, SEQ_BEAT_COUNT
	call NoteEditSy_SendModeScrollReset
	ld a, (1075:16)
	ld (9010:16), a
	call SeqMode_SendStatusUpdate
	call Audio_CheckSubsystemReady
	call SeqBuf_Init
	call TempoRingBuf_Init
	call BitMapOut_ComputeRegionDelta
	ld a, (8986:16)
	ldfr_berp A, 0xfb
	extz wa
	ld bc, 0:i3
	call Chan_SetActiveBit
	ld iz, (0xf19e:16)
	ldto_berp A, 0xfb
	extz wa
	ld bc, 1:i3
	call Chan_SetActiveBit
	bit 0, (0x28b2:16)
	jr nz, SeqPlay_InitResume_State10or14
	cp iz, 0:i3
	jr z, SeqPlay_InitResume_State0F
	ld a, 0x13:opc
	jr SeqPlay_StoreCheckValue

SeqPlay_InitResume_State0F:
	ld a, 0xf:opc
	jr SeqPlay_StoreCheckValue

SeqPlay_InitResume_State10or14:
	ld a, 0x10:opc
	cp iz, 0:i3
	jr z, SeqPlay_StoreCheckValue
	ld a, 0x14:opc

SeqPlay_StoreCheckValue:
	ld (8956:16), a

SeqPlay_InitResume_Return:
	ld l, 0x0:opc
	pop xiz
	ret

SeqPlay_FindSpecialVoices:
	ld wa, 0:i3
	ldw bc, 0xc
	call Part_FindVoiceByByte
	ld (8992:16), l
	ld wa, 0:i3
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ld (8994:16), l
	ld wa, 0:i3
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ld (8996:16), l
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqPlay_ClearPositionAndFlags
	cp a, 0x88
	jr z, SeqPlay_ClearPositionAndFlags
	res 1, (8970:16)

SeqPlay_ClearPositionAndFlags:
	ld (7522:16), 0
	ldw (9006:16), 0
	res 1, (0x28b3:16)
	ret

SeqPlay_SaveAndPrepareState:
	pushw_erp 0xfa
	calr SeqPlay_PreparePlaybackState
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SeqPlay_SaveState_CheckActive
	res 1, (0x28b3:16)
	jr SeqPlay_ReassignVoicesAlt

SeqPlay_SaveState_CheckActive:
	bit 0, (0x28c5:16)
	jr z, SeqPlay_SaveState_NoActiveParts
	res 1, (0x28b3:16)
	ld a, (8956:16)
	extz wa
	lda xbc, (SeqPlay_SaveAndPrepareState_Table:24)
	ld	(0x22fc:16), (xbc+wa)
	bit 0, (0xf23c:16)
	jr nz, SeqPlay_ReassignVoicesAlt
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	jr SeqPlay_ReassignVoicesAlt

SeqPlay_SaveState_NoActiveParts:
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	bit 1, (0x28b3:16)
	jr nz, SeqPlay_SaveState_CheckBit1
	bit 0, (0x28b2:16)
	jr z, SeqPlay_SaveState_CheckBit1
	ldmm16 9832, 9014
	call NoteEditSy_SendModeScrollReset

SeqPlay_SaveState_CheckBit1:
	bit 1, (0x28b3:16)
	jr nz, SeqPlay_SaveState_SetPlayFlags
	calr SeqPlay_ReassignVoiceChannels
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SeqPlay_SaveState_NoActive

SeqPlay_ReassignVoicesAlt:
	ldto_berp L, 0xfb
	jrl SeqPlay_ReturnFalse_Return

SeqPlay_SaveState_NoActive:
	cpw (0x28aa:16), 0
	jrl z, SeqPlay_ReturnFalse

SeqPlay_SaveState_SetPlayFlags:
	set 0, (0x8d88:16)
	set 0, (9834:16)
	ld a, (8956:16)
	extz wa
	lda xbc, (SeqPlay_SaveAndPrepareState_Table:24)
	ld	(0x22fc:16), (xbc+wa)
	ld c, (8970:16)
	set 0, c
	ld (8970:16), c
	ld a, (0x28b3:16)
	bit 1, a
	jr z, SeqPlay_SaveState_CheckVoices
	res 1, a
	ld (0x28b3:16), a
	jrl SeqPlay_ReturnFalse

SeqPlay_SaveState_CheckVoices:
	res 1, c
	ld (8970:16), c
	cpw (0xf19e:16), 0
	jr z, SeqPlay_SaveState_CheckChordVoice
	bit 1, (0x28a7:16)
	jrl z, SeqPlay_ReturnFalse

SeqPlay_SaveState_CheckChordVoice:
	bit 0, (0x28b2:16)
	jrl nz, SeqPlay_ReturnFalse
	ld e, (8996:16)
	cp e, 0xff
	jr z, SeqPlay_AssignBassVoice
	ld a, e
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_SaveState_ChordShiftDone
	slaa bc

SeqPlay_SaveState_ChordShiftDone:
	and bc, (0x28aa:16)
	jr z, SeqPlay_AssignBassVoice
	lda xbc, (SeqPlay_SaveState_ChordShiftDone_Table:24)
	bit 1, (0x28b1:16)
	jr z, SeqPlay_SaveState_ChordAssignDirect
	ldw wa, 0x12
	ld de, 2:i3
	calr ToneVoice_AssignChannel
	jr SeqPlay_AssignBassVoice

SeqPlay_SaveState_ChordAssignDirect:
	extz de
	ld wa, de
	ld de, 2:i3
	calr ToneVoice_AssignChannel
	ld a, (8996:16)
	extz wa
	call SeqEvent_CreateWithChannelValidation

SeqPlay_AssignBassVoice:
	ld e, (8994:16)
	cp e, 0xff
	jr z, SeqPlay_ReturnFalse
	ld a, e
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_SaveState_BassShiftDone
	slaa bc

SeqPlay_SaveState_BassShiftDone:
	and bc, (0x28aa:16)
	jr z, SeqPlay_ReturnFalse
	lda xbc, (SeqPlay_SaveState_ChordShiftDone_Table:24)
	bit 1, (0x28b1:16)
	jr z, SeqPlay_SaveState_BassAssignDirect
	ldw wa, 0x12
	ld de, 2:i3
	calr ToneVoice_AssignChannel
	jr SeqPlay_ReturnFalse

SeqPlay_SaveState_BassAssignDirect:
	extz de
	ld wa, de
	ld de, 2:i3
	calr ToneVoice_AssignChannel
	ld a, (8994:16)
	extz wa
	call SeqEvent_CreateWithChannelValidation

SeqPlay_ReturnFalse:
	ld l, 0x0:opc

SeqPlay_ReturnFalse_Return:
	popw_erp 0xfa
	ret

SeqPlay_PreparePlaybackState:
	call KeyScan_Enable
	res 2, (0x347a:16)
	ld a, (7558:16)
	cp a, 1:i3
	call z, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	ld wa, 0:i3
	call UI_PostDialEnable
	ld wa, (8980:16)
	cp wa, 0:i3
	jr z, KeyScan_DisableComplete_Return
	ld (SEQ_ACTIVE_PARTS:16), wa
	bit 0, (0x28c5:16)
	jr z, SeqPlay_Prepare_CheckRepeat
	bit 0, (0x28b2:16)
	jr z, SeqPlay_Prepare_CheckRepeat
	ldmm16 9832, 9014
	call NoteEditSy_SendModeScrollReset

SeqPlay_Prepare_CheckRepeat:
	call SeqPlay_CheckRepeatAndReactivate
	call Seq_CheckChordVoiceAndSetFlag
	cp (CURRENT_MODE:16), 19
	jr z, SeqPlay_Prepare_LoadVoiceConfig
	set 3, (0x28a7:16)

SeqPlay_Prepare_LoadVoiceConfig:
	calr SeqNote_LoadVoicePositions
	ldmm16 7588, SEQ_BEAT_COUNT
	cpw (0x28a8:16), 0
	jr nz, KeyScan_DisableComplete_Return
	cp (7570:16), 0
	jr nz, SeqPlay_Prepare_SetState6
	ld (8956:16), 3
	jr SeqPlay_Prepare_CheckMode87

SeqPlay_Prepare_SetState6:
	ld (8956:16), 6

SeqPlay_Prepare_CheckMode87:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, KeyScan_DisableComplete_Return
	cp a, 0x88
	jr z, KeyScan_DisableComplete_Return
	res 1, (8970:16)

KeyScan_DisableComplete_Return:
	call KeyScan_Disable
	ld l, 0x0:opc
	ret

SeqPlay_HandlePlaybackEvent:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqPlay_HandleEvent_AccMode
	cp a, 0x88
	jr nz, SeqPlay_HandleEvent_CheckBit1

SeqPlay_HandleEvent_AccMode:
	call SeqAcc_ProcessTempoEvents
	jrl SeqPlay_ClearFlagsRet

SeqPlay_HandleEvent_CheckBit1:
	ld a, (8970:16)
	bit 1, a
	jr z, SeqPlay_HandleEvent_StopAndClean
	res 1, a
	ld (8970:16), a
	jrl SeqPlay_ClearFlagsRet

SeqPlay_HandleEvent_StopAndClean:
	res 7, (0x28ae:16)
	ld (7572:16), 0
	ld wa, (SEQ_ACTIVE_PARTS:16)
	ld (8980:16), wa
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplaySimple
	call AccompSeq_StopSequence
	cpw (0xf19e:16), 0
	jr z, SeqPlay_ClearFlagsRet
	cp (CURRENT_MODE:16), 19
	jr nz, SeqPlay_HandleEvent_SyncTiming
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	ldw (SEQ_ACTIVE_PARTS:16), 0

SeqPlay_HandleEvent_SyncTiming:
	set 2, (0x28a7:16)
	call Seq_SyncPositionAndOutputMIDITiming
	ld (1073:16), 0
	call Audio_CheckSubsystemReady
	ld a, (0x347a:16)
	bit 2, a
	jr z, SeqPlay_CheckSilentAndStop
	ld e, (0x3314:16)
	ld c, (0x3315:16)
	ld a, (0x3328:16)
	cp e, 0:i3
	jr nz, SeqPlay_HandleEvent_ClearAccFlag
	cp c, 0:i3
	jr nz, SeqPlay_HandleEvent_ClearAccFlag
	cp a, 0:i3
	jr z, SeqPlay_HandleEvent_SetAccFlag

SeqPlay_HandleEvent_ClearAccFlag:
	res 0, (0x28a6:16)
	jr SeqPlay_CheckSilentAndStop

SeqPlay_HandleEvent_SetAccFlag:
	set 0, (0x28a6:16)
	ld a, (0x347a:16)
	set 1, a
	ld (0x347a:16), a

SeqPlay_CheckSilentAndStop:
	bit 0, (0x28a6:16)
	jr z, SeqPlay_HandleEvent_ClearBit2
	call AccWrap_FullStop
	set 1, (0x28a7:16)

SeqPlay_HandleEvent_ClearBit2:
	res 2, (0x28a7:16)

SeqPlay_ClearFlagsRet:
	ld l, 0x0:opc
	ret


; -----------------------------------------------------------------------------
; Section: Voice Processing & Cleanup
; -----------------------------------------------------------------------------
; Voice and note processing, stop/cleanup routines,
; and playback finalization.
; -----------------------------------------------------------------------------

SeqPlay_ProcessVoiceAndNotes:
	lda xsp, (xsp - 12)
	push xiz
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqPlay_ProcessVoice_AccMode
	cp a, 0x88
	jr nz, SeqPlay_ProcessVoice_CheckActive

SeqPlay_ProcessVoice_AccMode:
	call SeqAcc_ProcessTempoEvents
	jrl SeqPlay_ProcessVoice_Return

SeqPlay_ProcessVoice_CheckActive:
	cpw (0x28aa:16), 0
	jr nz, SeqPlay_ProcessVoice_ReadTempo
	ld a, (0x28be:16)
	cp a, 0xff
	jr z, SeqPlay_StopAndCleanup
	bit 0, (8970:16)
	jr nz, SeqPlay_StopAndCleanup
	inc 1, a
	ld c, a
	extz bc
	ld wa, 0:i3
	ldw de, 0xd
	call Part_WriteSubBlock32

SeqPlay_StopAndCleanup:
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call AccompSeq_StopSequence
	call AccWrap_PlayModeDispatch
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	ld (0x28b2:16), a
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	ldw (SEQ_ACTIVE_PARTS:16), 0
	res 3, (0x28b3:16)
	call Audio_CheckSubsystemReady
	call SeqBuffer_ClearAndInitIteration
	call Audio_CheckSubsystemReady
	jrl SeqPlay_ProcessVoice_Return

SeqPlay_ProcessVoice_ReadTempo:
	ld wa, (9012:16)
	ld (9832:16), wa
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cp l, 0:i3
	jr z, SeqPlay_ProcessVoice_ValidateData

SeqPlay_ProcessVoice_TempoLoop:
	lda xwa, (xsp + 8)
	calr Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cp l, 0:i3
	jr nz, SeqPlay_ProcessVoice_TempoLoop

SeqPlay_ProcessVoice_ValidateData:
	lda xiz, (xsp + 4)
	ei 6
	ldmw2 (xiz), 0x41c
	ldmi16 (xiz + 2), 0x41b
	ei 0
	lda xwa, (xsp + 4)
	ld e, (xwa + 2)
	extz de
	ld bc, (xwa)
	ldw wa, 0x32
	calr SeqData_ValidateProcess
	bit 1, (0x28b1:16)
	jr z, SeqPlay_ProcessVoice_RepeatPath
	calr SeqPlay_ReallocateAndReconfig
	jr SeqPlay_ProcessVoice_Cleanup

SeqPlay_ProcessVoice_RepeatPath:
	call Part_CopyVoiceDataToAllChannels
	calr SeqPlay_ActivateAllChannels

SeqPlay_ProcessVoice_Cleanup:
	ld (7522:16), 0
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	ld (0x28b2:16), a
	call AccompSeq_StopSequence
	call AccWrap_PlayModeDispatch
	call AccWrap_DispatchAndWaitSync
	ld (7568:16), 1
	ld (7584:16), 1
	res 3, (0x28a7:16)
	set 1, (8970:16)
	call SeqBuffer_ClearAndInitIteration
	ld (0x28be:16), 255
	bit 1, (9834:16)
	jr nz, SeqPlay_ProcessVoice_PartChange
	cp (CURRENT_MODE:16), 10
	jr z, SeqPlay_ProcessVoice_ClearBit
	ldw wa, 0xa
	call UI_PostPartChangeEvent
	jr SeqPlay_ProcessVoice_ClearBit

SeqPlay_ProcessVoice_PartChange:
	call UI_PostRefreshEvent

SeqPlay_ProcessVoice_ClearBit:
	res 1, (9834:16)

SeqPlay_ProcessVoice_Return:
	ld l, 0x0:opc
	pop xiz
	lda xsp, (xsp + 12)
	ret

SeqPlay_ProcessNoteAndTempo:
	lda xsp, (xsp - 10)
	push xiz
	ldw (xsp + 4), 0x0
	calr SeqNote_ProcessNoteOn
	cp l, 0:i3
	jr nz, SeqPlay_ReadTempo_Return
	cpw (0x28a8:16), 0
	jr z, SeqPlay_ReadTempoEvents_ReturnZero
	ld a, (0x28c5:16)
	bit 0, a
	jr z, SeqPlay_ReadTempoEvents
	bit 6, a
	jr z, SeqPlay_ReadTempoEvents_ReturnZero

SeqPlay_ReadTempoEvents:
	lda xwa, (xsp + 6)
	calr TempoRingBuf_ReadEventBytes
	cp l, 0:i3
	jr nz, SeqPlay_ReadTempo_HasData
	cp (7570:16), 1
	jr nz, SeqPlay_ReadTempoEvents_ReturnZero
	bit 1, (0x28b1:16)
	jr z, SeqPlay_ReadTempoEvents_ReturnZero
	calr SeqNote_ReconfigureAfterRepeat
	jr SeqPlay_ReadTempoEvents_ReturnZero

SeqPlay_ReadTempo_HasData:
	cp (7570:16), 1
	jr nz, SeqPlay_DispatchVoiceEvt
	ei 6
	ld iz, (SEQ_BEAT_COUNT:16)
	ld a, (SEQ_BEAT_TICK:16)
	ldfr_berp A, 0xfb
	ei 0
	ld wa, (7542:16)
	cp wa, iz
	jr ugt, SeqPlay_DispatchVoiceEvt
	cp wa, iz
	jr nz, SeqPlay_ReadTempo_Reconfigure
	cp_erpb 0xfb, 0x5f
	jr nz, SeqPlay_DispatchVoiceEvt

SeqPlay_ReadTempo_Reconfigure:
	calr SeqPlay_ReconfigureVoices

SeqPlay_DispatchVoiceEvt:
	lda xwa, (xsp + 6)
	calr Seq_DispatchVoiceConfigEvent
	cp (7528:16), 0
	jr nz, SeqPlay_ReadTempo_CheckLoop
	ld l, 0x3:opc
	jr SeqPlay_ReadTempo_Return

SeqPlay_ReadTempo_CheckLoop:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0xa
	jr c, SeqPlay_ReadTempoEvents

SeqPlay_ReadTempoEvents_ReturnZero:
	ld l, 0x0:opc

SeqPlay_ReadTempo_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

TempoRingBuf_ReadEventBytes:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldib_erp 0xfb, 0
	jr TempoRingBuf_Read_NextByte

TempoRingBuf_Read_ProcessByte:
	ldto_berp C, 0xf8
	ld xwa, (xsp + 4)
	ld (xwa), c
	ld a, (xwa)
	extz wa
	call MIDI_GetEventSizeFromByte
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr nz, TempoRingBuf_Read_CheckCount
	ld wa, 1:i3
	call SeqData_SetErrorCode

TempoRingBuf_Read_NextByte:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cp iz, 0:i3
	jr ge, TempoRingBuf_Read_ProcessByte

TempoRingBuf_Read_CheckCount:
	ldib_erp 0xfa, 1
	cpib_erp 0xfb, 1
	jr ule, TempoRingBuf_Read_Return

TempoRingBuf_Read_ExtLoop:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cp iz, 0:i3
	jr ge, TempoRingBuf_Read_StoreByte
	ld wa, 2:i3
	call SeqData_SetErrorCode

TempoRingBuf_Read_StoreByte:
	ldto_berp C, 0xfa
	extz bc
	ldto_berp E, 0xf8
	ld xwa, (xsp + 4)
	ld	(xwa+bc), e
	inc1b_erp 0xfa
	ldto_berp A, 0xfa
	cpb_erp A, 0xfb
	jr c, TempoRingBuf_Read_ExtLoop

TempoRingBuf_Read_Return:
	ldto_berp L, 0xfb
	pop xiz
	inc 4, xsp
	ret

Seq_DispatchVoiceConfigEvent:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldmi16 (xsp + 6), 0x1d92
	ldmw2 (xsp + 8), 0x2326
	cp (xiz), 0x81
	jr nz, SeqVoice_Dispatch_CheckTiming
	ld a, (xsp + 6)
	extz wa
	ld xbc, xiz
	calr SeqVoice_HandleEndMark
	jrl SeqVoice_ReturnFalse

SeqVoice_Dispatch_CheckTiming:
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_DispatchByEventType
	ld wa, (9006:16)
	cp (xsp + 8), wa
	jr nc, SeqVoice_DispatchByEventType
	ldw wa, 0x1e
	call SeqData_SetErrorCode
	jrl SeqVoice_ReturnFalse

SeqVoice_DispatchByEventType:
	ld c, (xiz + 1)
	extz bc
	cp (xiz), 0x80
	jr z, SeqVoice_Dispatch_ProcessVoice
	cp (xiz), 0x85
	jr z, SeqVoice_Dispatch_ProcessVoice
	cp (xiz), 0x86
	jr nz, SeqVoice_Dispatch_CheckOtherTypes

SeqVoice_Dispatch_ProcessVoice:
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_Dispatch_CallBBE1
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch

SeqVoice_Dispatch_CallBBE1:
	ld xwa, xiz
	calr SeqVoice_ProcessAndAssign
	jrl SeqVoice_ReturnFalse

SeqVoice_Dispatch_CheckOtherTypes:
	ld a, (xiz)
	and a, 0xf0
	cp a, 0xb0
	jr nz, SeqVoice_Dispatch_Check83
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_Dispatch_Check80
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch

SeqVoice_Dispatch_Check80:
	ld xwa, xiz
	calr SeqPart_CheckAndSetVoiceConfig
	ld (xsp + 4), l
	cp (xsp + 4), 0x0
	jrl z, SeqVoice_ReturnFalse

SeqVoice_Dispatch_Check83:
	ld xwa, xiz
	call SeqData_GetEventByteCount
	cp l, 0:i3
	jr ge, SeqVoice_Dispatch_Check84
	ld l, 0xff:opc
	jrl SeqVoice_Dispatch_ScanNext

SeqVoice_Dispatch_Check84:
	inc 1, l
	ld a, l
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_Dispatch_Check82
	ld e, (8986:16)
	cp a, e
	jr z, SeqVoice_Dispatch_CheckD3
	jr SeqVoice_ReturnFalse

SeqVoice_Dispatch_Check82:
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqVoice_Dispatch_CheckD2
	slaa de

SeqVoice_Dispatch_CheckD2:
	and de, (0x28a8:16)
	jr z, SeqVoice_ReturnFalse

SeqVoice_Dispatch_CheckD3:
	ld a, (xiz)
	and a, 0xf0
	cp a, 0xc0
	jr z, SeqVoice_Dispatch_CheckD1
	cp a, 0x90
	jr nz, SeqVoice_Dispatch_CheckD0
	ld a, (xsp + 6)
	extz wa
	ld xbc, xiz
	calr SeqVoice_BufferSwapAndAssign
	jr SeqVoice_ReturnFalse

SeqVoice_Dispatch_CheckD1:
	ld (xsp + 4), 0x6
	jr SeqVoice_MatchAndAssignChannel

SeqVoice_Dispatch_CheckD0:
	ld a, (xiz)
	cp a, 0xd2
	jr z, SeqVoice_Dispatch_CheckC0
	cp a, 0xd3
	jr z, SeqVoice_Dispatch_CheckB0
	cp a, 0xd1
	jr z, SeqVoice_Dispatch_CheckB0
	cp a, 0xd0
	jr nz, SeqVoice_MatchAndAssignChannel

SeqVoice_Dispatch_CheckB0:
	ld (xsp + 4), 0x3
	jr SeqVoice_MatchAndAssignChannel

SeqVoice_Dispatch_CheckC0:
	ld (xsp + 4), 0x4

SeqVoice_MatchAndAssignChannel:
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_Dispatch_Check90
	ld c, (xiz + 1)
	extz bc
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch
	ld e, (xsp + 4)
	extz de
	ldw wa, 0x12
	ld xbc, xiz
	jr SeqVoice_Dispatch_ErrorUnknown

SeqVoice_Dispatch_Check90:
	extz hl
	ld e, (xsp + 4)
	extz de
	ld wa, hl
	ld xbc, xiz

SeqVoice_Dispatch_ErrorUnknown:
	calr ToneVoice_AssignChannel

SeqVoice_ReturnFalse:
	ld l, 0x0:opc

SeqVoice_Dispatch_ScanNext:
	pop xiz
	inc 6, xsp
	ret

SeqNote_ReconfigureAfterRepeat:
	dec 8, xsp
	jrl SeqNote_Reconfig_BassDone

SeqNote_Reconfig_CheckChannels:
	ld	a, (xhl+139)
	add a, 0x9
	cp bc, de
	jr nz, SeqNote_Reconfig_ProcessChannel
	cp (SEQ_BEAT_TICK:16), a
	jr nc, SeqVoice_CopyEventToSlot
	jrl SeqNote_Reconfig_ChordSetup

SeqNote_Reconfig_ProcessChannel:
	ld c, a
	cp a, 0x60
	jr c, SeqVoice_CopyEventToSlot
	sub c, 0x60
	cp (SEQ_BEAT_TICK:16), c
	jrl c, SeqNote_Reconfig_ChordSetup

SeqVoice_CopyEventToSlot:
	lda xix, (xsp)
	lda xwa, (xhl+136:16)
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqNote_Reconfig_DispatchLoop:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqNote_Reconfig_DispatchLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	ld e, l
	extz de
	cp hl, 0:i3
	jr lt, SeqNote_Reconfig_BassSetup
	lda xbc, (xsp)
	cp (7522:16), 1
	jr z, SeqNote_Reconfig_Complete
	ldw wa, 0x12
	jr SeqNote_Reconfig_Return

SeqNote_Reconfig_Done:
	cp wa, hl
	jr nz, SeqNote_Reconfig_MidiSync
	ld	a, (xix+139)
	extz wa
	cp (7526:16), wa
	jr nc, SeqVoice_ReadPartEvent

SeqNote_Reconfig_MidiSync:
	ldw wa, 0x12

SeqNote_Reconfig_Return:
	calr ToneVoice_AssignChannel
	jr SeqVoice_ReadPartEvent

SeqNote_Reconfig_Complete:
	lda xix, (9016:16)
	ld wa, (7524:16)
	ld	hl, (xix+136)
	cp wa, hl
	jr ule, SeqNote_Reconfig_Done
	jr SeqVoice_ReadPartEvent

SeqNote_Reconfig_BassSetup:
	ld wa, 3:i3
	call SeqData_SetErrorCode

SeqVoice_ReadPartEvent:
	ldw wa, 0x13
	ld bc, 1:i3
	calr SeqPart_ReadEventStream

SeqNote_Reconfig_BassDone:
	lda xhl, (9016:16)
	ld bc, (SEQ_BEAT_COUNT:16)
	ld	de, (xhl+136)
	cp bc, de
	jrl nc, SeqNote_Reconfig_CheckChannels

SeqNote_Reconfig_ChordSetup:
	inc 8, xsp
	ret

VoiceConfig_FindChannelMatch:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 10), c
	ld iz, wa
	jr SeqNote_TrackPos_CheckBass

SeqNote_Reconfig_ChordDone:
	cp wa, iz
	jr nz, SeqNote_Reconfig_SubSetup
	ld	a, (xde+139)
	cp a, (xsp + 10)
	jr nc, SeqNote_TrackPos_BassSetup

SeqNote_Reconfig_SubSetup:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqNote_Reconfig_SubDone:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xhl, (xde+136:16)
	ld ix, wa
	extz xix
	add xix, xhl
	ldto_berp L, 0xe2
	extz hl
	ld a, (xix)
	ld	(xiy+hl), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqNote_Reconfig_SubDone
	ld a, (xbc)
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr ge, SeqNote_TrackChannelPositions
	ld wa, 4:i3
	call SeqData_SetErrorCode
	jr SeqNote_TrackPos_BassSetup

SeqNote_TrackChannelPositions:
	ld e, l
	extz de
	lda xbc, (xsp + 2)
	cp (7522:16), 1
	jr z, SeqNote_TrackPos_ChordDone
	ldw wa, 0x12

SeqNote_TrackPos_Done:
	calr ToneVoice_AssignChannel

SeqNote_TrackPos_Return:
	ldw wa, 0x13
	ld bc, 1:i3
	calr SeqPart_ReadEventStream

SeqNote_TrackPos_CheckBass:
	lda xde, (9016:16)
	ld	wa, (xde+136)
	cp wa, iz
	jr ule, SeqNote_Reconfig_ChordDone

SeqNote_TrackPos_BassSetup:
	popw iz
	lda xsp, (xsp + 10)
	ret

SeqNote_TrackPos_BassDone:
	cp wa, hl
	jr nz, SeqNote_TrackPos_ChordSetup
	ld	a, (xix+139)
	extz wa
	cp (7526:16), wa
	jr nc, SeqNote_TrackPos_Return

SeqNote_TrackPos_ChordSetup:
	ldw wa, 0x12
	jr SeqNote_TrackPos_Done

SeqNote_TrackPos_ChordDone:
	lda xix, (9016:16)
	ld wa, (7524:16)
	ld	hl, (xix+136)
	cp wa, hl
	jr ule, SeqNote_TrackPos_BassDone
	jr SeqNote_TrackPos_Return

SeqNote_LoadVoicePositions:
	ldw (7586:16), 0
	ld wa, (8982:16)
	bit 0, wa
	jr z, SeqNote_LoadPos_Channel1
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9016:16)
	jr c, SeqNote_LoadPos_Channel1
	ldw (7586:16), 1

SeqNote_LoadPos_Channel1:
	ld wa, (8982:16)
	bit 1, wa
	jr z, SeqNote_LoadPos_Channel2
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9024:16)
	jr c, SeqNote_LoadPos_Channel2
	orw (7586:16), 2

SeqNote_LoadPos_Channel2:
	ld wa, (8982:16)
	bit 2, wa
	jr z, SeqNote_LoadPos_Channel3
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9032:16)
	jr c, SeqNote_LoadPos_Channel3
	orw (7586:16), 4

SeqNote_LoadPos_Channel3:
	ld wa, (8982:16)
	bit 3, wa
	jr z, SeqNote_LoadPos_Channel4
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9040:16)
	jr c, SeqNote_LoadPos_Channel4
	orw (7586:16), 8

SeqNote_LoadPos_Channel4:
	ld wa, (8982:16)
	bit 4, wa
	jr z, SeqNote_LoadPos_Channel5
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9048:16)
	jr c, SeqNote_LoadPos_Channel5
	orw (7586:16), 16

SeqNote_LoadPos_Channel5:
	ld wa, (8982:16)
	bit 5, wa
	jr z, SeqNote_LoadPos_Channel6
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9056:16)
	jr c, SeqNote_LoadPos_Channel6
	orw (7586:16), 32

SeqNote_LoadPos_Channel6:
	ld wa, (8982:16)
	bit 6, wa
	jr z, SeqNote_LoadPos_Channel7
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9064:16)
	jr c, SeqNote_LoadPos_Channel7
	orw (7586:16), 64

SeqNote_LoadPos_Channel7:
	ld wa, (8982:16)
	bit 7, wa
	jr z, SeqNote_LoadPos_Channel8
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9072:16)
	jr c, SeqNote_LoadPos_Channel8
	orw (7586:16), 128

SeqNote_LoadPos_Channel8:
	ld wa, (8982:16)
	bit 8, wa
	jr z, SeqNote_LoadPos_Channel9
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9080:16)
	jr c, SeqNote_LoadPos_Channel9
	orw (7586:16), 256

SeqNote_LoadPos_Channel9:
	ld wa, (8982:16)
	bit 9, wa
	jr z, SeqNote_LoadPos_Channel10
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9088:16)
	jr c, SeqNote_LoadPos_Channel10
	orw (7586:16), 512

SeqNote_LoadPos_Channel10:
	ld wa, (8982:16)
	bit 10, wa
	jr z, SeqNote_LoadPos_Channel11
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9096:16)
	jr c, SeqNote_LoadPos_Channel11
	orw (7586:16), 1024

SeqNote_LoadPos_Channel11:
	ld wa, (8982:16)
	bit 11, wa
	jr z, SeqNote_LoadPos_Channel12
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9104:16)
	jr c, SeqNote_LoadPos_Channel12
	orw (7586:16), 2048

SeqNote_LoadPos_Channel12:
	ld wa, (8982:16)
	bit 12, wa
	jr z, SeqNote_LoadPos_Channel13
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9112:16)
	jr c, SeqNote_LoadPos_Channel13
	orw (7586:16), 4096

SeqNote_LoadPos_Channel13:
	ld wa, (8982:16)
	bit 13, wa
	jr z, SeqNote_LoadPos_Channel14
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9120:16)
	jr c, SeqNote_LoadPos_Channel14
	orw (7586:16), 8192

SeqNote_LoadPos_Channel14:
	ld wa, (8982:16)
	bit 14, wa
	jr z, SeqNote_LoadPos_Channel15
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9128:16)
	jr c, SeqNote_LoadPos_Channel15
	orw (7586:16), 0x4000

SeqNote_LoadPos_Channel15:
	ld wa, (8982:16)
	extz xwa
	bit 15, wa
	ret z
	ld wa, (SEQ_BEAT_COUNT:16)
	cp wa, (9136:16)
	ret c
	orw (7586:16), 0x8000
	ret

SeqNote_ProcessNoteOn:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), 0x0
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr nz, SeqNote_NoteOn_HasParts
	ld l, 0x0:opc
	jrl SeqNote_ProcessNoteOn_Return

SeqNote_NoteOn_HasParts:
	bit 5, (0x28b3:16)
	jr z, SeqNote_NoteOn_CheckRepeat
	ei 6
	ld a, (SEQ_BEAT_TICK:16)
	inc 1, a
	ld (SEQ_BEAT_TICK:16), a
	cp a, 0x60
	jr c, SeqNote_NoteOn_TickDone
	ld (SEQ_BEAT_TICK:16), 0
	incw 1, (SEQ_BEAT_COUNT:16)

SeqNote_NoteOn_TickDone:
	ei 0

SeqNote_NoteOn_CheckRepeat:
	cp (7572:16), 1
	jr nz, SeqNote_NoteOn_ReadPosition
	calr SeqNote_ProcessRepeatNote
	ld (xsp + 6), l
	jrl SeqNote_LoadNoteParam_Return

SeqNote_NoteOn_ReadPosition:
	ei 6
	ldmw2 (xsp + 4), 0x41c
	ldmi16 (xsp + 8), 0x41b
	ei 0
	cp (7570:16), 1
	jrl nz, SeqNote_ProcessCurrentChannel
	ld wa, (7542:16)
	cp wa, (xsp + 4)
	jr ugt, SeqNote_FindExtraChannel
	cp wa, (xsp + 4)
	jr nz, SeqNote_NoteOn_Reconfigure
	cp (xsp + 8), 0x5f
	jr nz, SeqNote_FindExtraChannel

SeqNote_NoteOn_Reconfigure:
	calr SeqPlay_ReconfigureVoices
	ld (7530:16), 0
	ld (0x2862:16), 0
	ld (0x2864:16), 0
	ld (0x2866:16), 0

SeqNote_FindExtraChannel:
	cpw (0x28a8:16), 0
	jr z, SeqNote_AllocateMainChannel

SeqNote_FindExtra_CheckPosition:
	lda xbc, (9016:16)
	ld	wa, (xbc+128)
	cp (xsp + 4), wa
	jr c, SeqNote_AllocateMainChannel
	cp (xsp + 4), wa
	jr nz, SeqNote_FindExtra_ProcessChannel
	ld a, (xsp + 8)
	cp	a, (xbc+131)
	jr c, SeqNote_AllocateMainChannel

SeqNote_FindExtra_ProcessChannel:
	ldw wa, 0x11
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl nz, SeqNote_LoadNoteParam_Return
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	cpw (0x28a8:16), 0
	jr nz, SeqNote_FindExtra_CheckPosition

SeqNote_AllocateMainChannel:
	ld wa, (7542:16)
	cp (xsp + 4), wa
	jrl nz, SeqNote_ProcessCurrentChannel
	cp (7538:16), 1
	jr nz, SeqNote_AllocateBassChannel
	cp (xsp + 8), 0x46
	jr c, SeqNote_AllocateBassChannel
	cp (0x2862:16), 0
	jr nz, SeqNote_AllocateBassChannel
	ld a, (8988:16)
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (7542:16)
	inc 1, wa
	ld (9168:16), wa
	ld hl, (xhl)
	ld bc, (xde)
	lda xwa, (9260:16)
	ld (xwa), hl
	ld (xwa + 2), bc
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig
	ld (7530:16), 1
	ld (0x2862:16), 1

SeqNote_AllocateBassChannel:
	cp (7539:16), 1
	jrl nz, SeqNote_AllocateSubChannel
	cp (xsp + 8), 0x38
	jrl c, SeqNote_AllocateSubChannel
	cp (0x2864:16), 0
	jrl nz, SeqNote_AllocateSubChannel
	ld a, (8990:16)
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ld a, (8990:16)
	dec 1, a
	extz wa
	ld ix, wa
	sla ix, 3
	lda xbc, (9016:16)
	ld wa, (7542:16)
	inc 1, wa
	ld	(xbc+ix), wa
	ld a, (8990:16)
	extz wa
	ld hl, (xhl)
	ld de, (xde)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ld a, (8990:16)
	extz wa
	call SeqCh_LoadChannelConfig
	ld a, (8990:16)
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNote_AllocBass_SetBitAndFlags
	slaa bc

SeqNote_AllocBass_SetBitAndFlags:
	or (8982:16), bc
	ld (7530:16), 1
	ld (0x2864:16), 1

SeqNote_AllocateSubChannel:
	cp (7540:16), 1
	jr nz, SeqNote_ProcessCurrentChannel
	cp (xsp + 8), 0x38
	jr c, SeqNote_ProcessCurrentChannel
	cp (0x2866:16), 0
	jr nz, SeqNote_ProcessCurrentChannel
	ld a, (8996:16)
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (7542:16)
	inc 1, wa
	ld (9176:16), wa
	ld hl, (xhl)
	ld bc, (xde)
	lda xwa, (9264:16)
	ld (xwa), hl
	ld (xwa + 2), bc
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig
	ld a, (8996:16)
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNote_AllocSub_SetBitAndFlags
	slaa bc

SeqNote_AllocSub_SetBitAndFlags:
	or (8982:16), bc
	ld (7530:16), 1
	ld (0x2866:16), 1

SeqNote_ProcessCurrentChannel:
	cp (8988:16), 255
	jr nz, SeqNote_ProcessCurrent_DrumCheck
	jr VoiceConfig_SlotCheck

SeqNote_ProcessCurrent_ComparePos:
	lda xwa, (9016:16)
	ld	de, (xwa+152)
	ld	a, (xwa+155)
	cp a, 0x1a
	jr nc, SeqNote_ProcessCurrent_AdjustOfs
	dec 1, de
	add a, 0x60

SeqNote_ProcessCurrent_AdjustOfs:
	sub a, 0x1a
	cp (xsp + 4), de
	jr c, SeqNote_UpdateScoreDisplay
	cp (xsp + 4), de
	jr nz, SeqNote_ProcessCurrent_Dispatch
	cp (xsp + 8), a
	jr c, SeqNote_UpdateScoreDisplay

SeqNote_ProcessCurrent_Dispatch:
	ldw wa, 0x14
	calr SeqNote_ProcessForChannel
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig

SeqNote_ProcessCurrent_DrumCheck:
	ld a, (8988:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (SeqNote_ProcessCurrent_DrumCheck_Table:24)
	ld	wa, (xbc+wa)
	and wa, (8982:16)
	jr nz, SeqNote_ProcessCurrent_ComparePos

SeqNote_UpdateScoreDisplay:
	cpw (7578:16), 0xffff
	jr nz, SeqNote_ScoreDisplay_HasTarget
	jr VoiceConfig_SlotCheck

SeqNote_ScoreDisplay_Compare:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, SeqNote_ScoreDisplay_Mismatch
	ld a, (xsp + 8)
	cp a, (xbc + 2)
	jr c, VoiceConfig_SlotCheck

SeqNote_ScoreDisplay_Mismatch:
	call BitMapOut_PrepareAndDisplaySimple
	ldw (7578:16), 0xffff

SeqNote_ScoreDisplay_HasTarget:
	lda xbc, (7578:16)
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, SeqNote_ScoreDisplay_Compare

VoiceConfig_SlotCheck:
	cp (8996:16), 255
	jr nz, VoiceConfig_SlotCheck_GetChannel
	jr VoiceConfig_EventTypeChk

VoiceConfig_SlotCheck_ReadData:
	lda xwa, (9016:16)
	ld	de, (xwa+160)
	ld	a, (xwa+163)
	cp a, 0x28
	jr nc, VoiceConfig_SlotCheck_SubOffset
	dec 1, de
	add a, 0x60

VoiceConfig_SlotCheck_SubOffset:
	sub a, 0x28
	cp (xsp + 4), de
	jr c, VoiceConfig_EventTypeChk
	cp (xsp + 4), de
	jr nz, VoiceConfig_SlotCheck_ProcessAndLoad
	cp (xsp + 8), a
	jr c, VoiceConfig_EventTypeChk

VoiceConfig_SlotCheck_ProcessAndLoad:
	ldw wa, 0x15
	calr SeqNote_ProcessForChannel
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig

VoiceConfig_SlotCheck_GetChannel:
	ld a, (8996:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (SeqNote_ProcessCurrent_DrumCheck_Table:24)
	ld	wa, (xbc+wa)
	and wa, (8982:16)
	jr nz, VoiceConfig_SlotCheck_ReadData

VoiceConfig_EventTypeChk:
	cp (8990:16), 255
	jr nz, VoiceConfig_EventType_GetChannel
	jrl SeqNote_CheckActiveChannels

VoiceConfig_EventType_ReadData:
	sla wa, 3
	lda xde, (9016:16)
	exts xwa
	add xwa, xde
	ld de, (xwa)
	ld a, (xwa + 3)
	cp a, 0x28
	jr nc, VoiceConfig_EventType_SubOffset
	dec 1, de
	add a, 0x60

VoiceConfig_EventType_SubOffset:
	sub a, 0x28
	cp (xsp + 4), de
	jr c, SeqNote_CheckActiveChannels
	cp (xsp + 4), de
	jr nz, VoiceConfig_EventType_ProcessChan
	cp (xsp + 8), a
	jr c, SeqNote_CheckActiveChannels

VoiceConfig_EventType_ProcessChan:
	extz bc
	ld wa, bc
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl nz, SeqNote_LoadNoteParam_Return
	ld a, (8990:16)
	extz wa
	call SeqCh_LoadChannelConfig

VoiceConfig_EventType_GetChannel:
	ld c, (8990:16)
	ld a, c
	dec 1, a
	extz wa
	ld de, wa
	add de, de
	lda xhl, (SeqNote_ProcessCurrent_DrumCheck_Table:24)
	ld	de, (xhl+de)
	and de, (8982:16)
	jr nz, VoiceConfig_EventType_ReadData
	jr SeqNote_CheckActiveChannels

SeqNote_CheckActiveEntry:
	extz wa
	ld bc, wa
	muls bc, 0x9
	lda xde, (7606:16)
	lda	xde, (xde+bc)
	ld bc, (xde + 2)
	cp (xsp + 4), bc
	jr c, SeqNote_DispatchActiveChannels
	cp (xsp + 4), bc
	jr nz, SeqNote_CheckActive_FlushEvent
	ld c, (xsp + 8)
	cp c, (xde + 5)
	jr c, SeqNote_DispatchActiveChannels

SeqNote_CheckActive_FlushEvent:
	calr SeqNote_FlushPartEventToBuffer

SeqNote_CheckActiveChannels:
	ld a, (7602:16)
	cp a, 0xff
	jr nz, SeqNote_CheckActiveEntry

SeqNote_DispatchActiveChannels:
	ld wa, (7588:16)
	cp wa, (xsp + 4)
	jr z, SeqNote_DispatchActive_LoadParts
	calr SeqNote_LoadVoicePositions
	mrdw5 0x9f, 0x04, 0x19, 0xa4, 0x1d

SeqNote_DispatchActive_LoadParts:
	ld iz, (7586:16)
	ldib_erp 0xfb, 1
	cp iz, 0:i3
	jr z, SeqNote_DispatchActive_CheckSpecial

SeqNote_DispatchActive_TestBit:
	bit 0, iz
	jr z, SeqNote_ShiftAndIncrement

SeqNote_DispatchActive_ReadPart:
	ldto_berp E, 0xfb
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	lda	xbc, (xbc+wa)
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, SeqNote_DispatchActive_ComparePos
	ld a, (xsp + 8)
	cp a, (xbc + 3)
	jr c, SeqNote_ShiftAndIncrement

SeqNote_DispatchActive_ComparePos:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, SeqNote_DispatchActive_ProcessChan
	ld bc, 1:i3
	ld a, e
	and a, 0xf
	jr z, SeqNote_DispatchActive_ClearBit
	slaa bc

SeqNote_DispatchActive_ClearBit:
	cpl bc
	and (7586:16), bc
	jr SeqNote_ShiftAndIncrement

SeqNote_DispatchActive_ProcessChan:
	ldto_berp A, 0xfb
	extz wa
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jr z, SeqNote_DispatchActive_LoadConfig
	cp (xsp + 6), 0x5
	jr z, SeqNote_ShiftAndIncrement
	jr SeqNote_LoadNoteParam_Return

SeqNote_DispatchActive_LoadConfig:
	ldto_berp A, 0xfb
	extz wa
	call SeqCh_LoadChannelConfig
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jr nz, SeqNote_ShiftAndIncrement
	bit 0, iz
	jr nz, SeqNote_DispatchActive_ReadPart

SeqNote_ShiftAndIncrement:
	srl iz, 1
	inc1b_erp 0xfb
	cp iz, 0:i3
	jr nz, SeqNote_DispatchActive_TestBit

SeqNote_DispatchActive_CheckSpecial:
	cp (8988:16), 255
	jr z, SeqNote_ProcessSpecialChannels
	cpw (7574:16), 0xffff
	jr nz, SeqNote_SpecialChan_LoadAddr
	jr SeqNote_ProcessSpecialChannels

SeqNote_SpecialChan_ComparePos:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, SeqNote_SpecialChan_ClearAndStore
	ld a, (xsp + 8)
	cp a, (xbc + 2)
	jr c, SeqNote_ProcessSpecialChannels

SeqNote_SpecialChan_ClearAndStore:
	ld a, (0xfc5f:16)
	and a, 0x30
	call z, (BitMapOut_PrepareAndDisplay:24)
	ldw (7574:16), 0xffff

SeqNote_SpecialChan_LoadAddr:
	lda xbc, (7574:16)
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, SeqNote_SpecialChan_ComparePos

SeqNote_ProcessSpecialChannels:
	cp (7556:16), 0
	call nz, (SeqBuf_FlushAndReinit_NoteEvents:24)
	cp (7558:16), 0
	call nz, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)

SeqNote_LoadNoteParam_Return:
	ld l, (xsp + 6)

SeqNote_ProcessNoteOn_Return:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeqNote_ProcessRepeatNote:
	dec 6, xsp
	push xiz
	ld (xsp + 8), 0x0
	cpw (SEQ_ACTIVE_PARTS:16), 0
	jr nz, SeqRepeat_LoadTickAndPos
	ld l, 0x0:opc
	jrl SeqRepeat_Return

SeqRepeat_LoadTickAndPos:
	ei 6
	ldmw2 (xsp + 4), 0x41c
	ldmi16 (xsp + 6), 0x41b
	ei 0
	jr SeqRepeat_CheckNextSlot

SeqRepeat_CheckActiveEntry:
	extz wa
	ld bc, wa
	muls bc, 0x9
	lda xde, (7606:16)
	lda	xde, (xde+bc)
	ld bc, (xde + 2)
	cp (xsp + 4), bc
	jr c, SeqNote_DispatchActiveChannels_NoteOff
	cp (xsp + 4), bc
	jr nz, SeqRepeat_FlushEvent
	ld c, (xsp + 6)
	cp c, (xde + 5)
	jr c, SeqNote_DispatchActiveChannels_NoteOff

SeqRepeat_FlushEvent:
	calr SeqNote_FlushPartEventToBuffer

SeqRepeat_CheckNextSlot:
	ld a, (7602:16)
	cp a, 0xff
	jr nz, SeqRepeat_CheckActiveEntry

SeqNote_DispatchActiveChannels_NoteOff:
	ld wa, (7588:16)
	cp wa, (xsp + 4)
	jr z, SeqRepeat_LoadActiveParts
	ldmm16 7586, 8982
	mrdw5 0x9f, 0x04, 0x19, 0xa4, 0x1d

SeqRepeat_LoadActiveParts:
	ld iz, (7586:16)
	ldib_erp 0xfb, 1
	cp iz, 0:i3
	jr z, SeqRepeat_ProcessSpecialChan

SeqRepeat_TestPartBit:
	bit 0, iz
	jr z, SeqNote_StreamAdvanceJoin

SeqRepeat_ReadPartData:
	ldto_berp E, 0xfb
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	lda	xbc, (xbc+wa)
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, SeqRepeat_ComparePosition
	ld a, (xsp + 6)
	cp a, (xbc + 3)
	jr c, SeqNote_StreamAdvanceJoin

SeqRepeat_ComparePosition:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, SeqRepeat_ProcessChannel
	ld bc, 1:i3
	ld a, e
	and a, 0xf
	jr z, SeqRepeat_ClearPartBit
	slaa bc

SeqRepeat_ClearPartBit:
	cpl bc
	and (7586:16), bc
	jr SeqNote_StreamAdvanceJoin

SeqRepeat_ProcessChannel:
	ldto_berp A, 0xfb
	extz wa
	calr SeqNote_ProcessForChannelAlt
	ld (xsp + 8), l
	cp (xsp + 8), 0x0
	jr z, SeqRepeat_ParseStream
	cp (xsp + 8), 0x5
	jr z, SeqNote_StreamAdvanceJoin
	jr SeqRepeat_LoadResult

SeqRepeat_ParseStream:
	ldto_berp A, 0xfb
	extz wa
	call SeqData_ParseSequenceStream
	bit 0, iz
	jr nz, SeqRepeat_ReadPartData

SeqNote_StreamAdvanceJoin:
	srl iz, 1
	inc1b_erp 0xfb
	cp iz, 0:i3
	jr nz, SeqRepeat_TestPartBit

SeqRepeat_ProcessSpecialChan:
	cp (7556:16), 0
	call nz, (SeqBuf_FlushAndReinit_NoteEvents:24)
	cp (7558:16), 0
	call nz, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)

SeqRepeat_LoadResult:
	ld l, (xsp + 8)

SeqRepeat_Return:
	pop xiz
	inc 6, xsp
	ret

SeqNote_FlushPartEventToBuffer:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	call NoteMap_RemoveAndRelink
	cp (7558:16), 1
	call z, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call lt, (SeqBuf_FlushAndReinit_NoteEvents:24)
	ld a, (xsp)
	extz wa
	muls wa, 0x9
	lda xbc, (7610:16)
	exts xwa
	add xwa, xbc
	push xwa
	pushw 0x5
	call SeqBuf_WriteBytes
	inc 6, xsp
	ld (7556:16), 1
	inc 2, xsp
	ret

SeqPart_ScanNextEvent:
	lda xsp, (xsp - 18)
	pushw_erp 0xfa
	ld (xsp + 18), a
	ldib_erp 0xfb, 0
	call Get_Firmware_Version
	cp l, 0xff
	jr z, SeqPartScan_ReturnError
	ld a, (xsp + 18)
	extz wa
	lda xde, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

SeqPartScan_ReadAndCopy:
	lda xde, (xsp + 2)
	lda xwa, (xsp + 6)
	ld bc, (xwa)
	ld (xde), bc
	ld bc, (xwa + 2)
	ld (xde + 2), bc
	lda xbc, (xsp + 10)
	call SeqPart_ReadNextEventByte
	ld a, (xsp + 10)
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr lt, SeqPartScan_RetryLoop
	ld c, (xsp + 18)
	extz bc
	lda xwa, (xsp + 2)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ld l, 0x0:opc
	jr SeqPartScan_Return

SeqPartScan_RetryLoop:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x12
	jr ule, SeqPartScan_ReadAndCopy

SeqPartScan_ReturnError:
	ld l, 0x1:opc

SeqPartScan_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 18)
	ret

SeqNote_ProcessForChannel:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 20), a
	ld (xsp + 6), 0x0
	ld a, (8988:16)
	ldfr_berp A, 0xfb
	ld a, (xsp + 20)
	cpb_erp A, 0xfb
	jr nz, SeqNoteCh_CheckMasterChan
	ldto_berp A, 0xfb
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jr nz, SeqNoteCh_CheckStatusByte
	ld wa, 1:i3
	call Voice_AllocateFromSeqData
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl z, SeqNote_ReturnNotProcessed

SeqNoteCh_CheckStatusByte:
	ld c, (xsp + 20)
	dec 1, c
	extz bc
	sla bc, 3
	lda xwa, (9018:16)
	cp	(xwa+bc), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld (xsp + 6), 0x0

SeqNoteCh_CheckMasterChan:
	cp (xsp + 20), 0x14
	jr nz, SeqNoteCh_CheckZeroChannel
	ldto_berp A, 0xfb
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jrl nz, SeqNote_ReturnNotProcessed
	ld wa, 0:i3
	call Voice_AllocateFromSeqData
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl z, SeqNote_ReturnNotProcessed
	ld (xsp + 6), 0x0

SeqNoteCh_CheckZeroChannel:
	cp (xsp + 20), 0x0
	jr nz, SeqNoteCh_SetupEventBuffer
	ldw wa, 0xc
	call SeqData_SetErrorCode

SeqNoteCh_SetupEventBuffer:
	ld a, (xsp + 20)
	extz wa
	lda xbc, (xsp + 10)
	ld h, a
	ld xiy, xbc
	ld l, 0x0:opc

SeqNoteCh_CopyEventLoop:
	ld e, l
	extz de
	inc 2, de
	ld a, h
	dec 1, a
	extz wa
	sla wa, 3
	lda xix, (9016:16)
	exts xwa
	add xwa, xix
	ld iz, de
	extz xiz
	add xiz, xwa
	ld e, l
	extz de
	ld a, (xiz)
	ld	(xiy+de), a
	inc 1, l
	cp l, 6:i3
	jr c, SeqNoteCh_CopyEventLoop
	cp (xsp + 20), 0x11
	jr nz, SeqNoteCh_StoreChannel
	cpw (0x28a8:16), 0
	jr z, SeqNoteCh_StoreChannel
	ldmi16 (xsp + 20), 0x231a
	ld (xsp + 8), 0x11
	jr SeqNoteCh_WriteStatusByte

SeqNoteCh_StoreChannel:
	ld a, (xsp + 20)
	ld (xsp + 8), a

SeqNoteCh_WriteStatusByte:
	lda xhl, (xix+130:16)
	cp (7522:16), 1
	jr nz, SeqNote_HandleMasterChannel
	ld a, (xsp + 8)
	cp a, (8986:16)
	jr nz, SeqNoteCh_CheckChannel11
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNoteCh_DeactivateShiftDone
	slaa bc

SeqNoteCh_DeactivateShiftDone:
	jr SeqNote_DeactivateChannelBit

SeqNoteCh_CheckChannel11:
	cp (xsp + 8), 0x11
	jr z, SeqNoteCh_LoadVoiceAndCompare
	jr SeqNote_HandleMasterChannel

SeqNoteCh_CompareVoicePos:
	cp wa, de
	jr nz, SeqNoteCh_DeactivateCheck82
	ld	a, (xix+131)
	extz wa
	cp (7526:16), wa
	jr ule, SeqNote_HandleMasterChannel

SeqNoteCh_DeactivateCheck82:
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNote_DeactivateChannelBit
	slaa bc

SeqNote_DeactivateChannelBit:
	cpl bc
	and (8982:16), bc
	jrl SeqNote_ReturnNotProcessed

SeqNoteCh_LoadVoiceAndCompare:
	ld wa, (7524:16)
	ld	de, (xix+128)
	cp wa, de
	jr nc, SeqNoteCh_CompareVoicePos

SeqNote_HandleMasterChannel:
	cp (xsp + 20), 0x14
	jr nz, SeqNote_HandleAccompChannel
	cp (xbc), 0x82
	jr nz, SeqNoteCh_CheckMasterFallback
	ld a, (xsp + 20)
	dec 1, a
	extz wa
	sla wa, 3
	ldw	(xix+wa), 0xffff
	ld a, (0xfc5f:16)
	and a, 0x30
	jr nz, SeqNote_ReturnNotProcessed
	bit 2, (1054:16)
	jr z, SeqNote_ReturnNotProcessed
	call AccWrap_PlayModeStartPlay
	jr SeqNote_ReturnNotProcessed

SeqNoteCh_CheckMasterFallback:
	ld a, (8988:16)
	cp a, 0xff
	jr z, SeqNote_HandleAccompChannel
	ld (xsp + 20), a

SeqNote_HandleAccompChannel:
	ld a, (xsp + 20)
	cp a, (8996:16)
	jr z, SeqNoteCh_HandleAccompVoice
	cp (xsp + 20), 0x15
	jr nz, SeqNoteCh_DispatchEventType

SeqNoteCh_HandleAccompVoice:
	ld a, (xsp + 20)
	extz wa
	calr VoiceType_CheckDrumOrControl
	cp hl, 0:i3
	jr nz, SeqNote_ReturnNotProcessed
	cp (xsp + 20), 0x15
	jr nz, SeqNote_SetDrumChannelPair
	cp (xsp + 10), 0x82
	jr nz, SeqNote_SetDrumChannelPair
	ld c, (xsp + 20)
	dec 1, c
	extz bc
	sla bc, 3
	lda xwa, (9016:16)
	ldw	(xwa+bc), 0xfff0

SeqNote_ReturnNotProcessed:
	ld l, 0x0:opc
	jrl SeqNote_WriteEvent_Return

SeqNote_SetDrumChannelPair:
	ldmi16 (xsp + 20), 0x2324

SeqNoteCh_DispatchEventType:
	lda xbc, (xsp + 10)
	ld e, (xbc)
	ld a, e
	and a, 0xf0
	ldfr_berp A, 0xfb
	ld (xsp + 4), 0x0
	cp_erpb 0xfb, 0xc0
	jr z, SeqNoteCh_HandleProgramChange
	cp_erpb 0xfb, 0xb0
	jr z, SeqNoteCh_HandleControlChange
	cp_erpb 0xfb, 0x90
	jr nz, SeqNoteCh_HandleOtherEvents
	ld a, (xsp + 8)
	extz wa
	calr SeqNote_SetupVoice
	cp l, 0:i3
	jr nz, SeqNoteCh_ClearAndRetStatus
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jrl z, SeqNote_NoteOff_WritePart
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_ClearAndRetStatus:
	ld (xsp + 4), 0x0
	jrl SeqNote_WriteEvent_RetStatus

SeqNoteCh_HandleControlChange:
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jrl nz, SeqNote_ConditionalWriteToBuffer
	ld a, (xsp + 20)
	extz wa
	lda xbc, (xsp + 10)
	calr AccPedalConfig_ApplyChannel0
	ld (xsp + 4), l
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleProgramChange:
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jrl nz, SeqNote_ConditionalWriteToBuffer
	ld a, (xsp + 20)
	extz wa
	lda xbc, (xsp + 10)
	calr AccPedalConfig_ApplyChannelDirect
	ld (xsp + 4), l
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleOtherEvents:
	cp e, 0x86
	jrl z, SeqNote_UpdatePositionB_Entry
	cp e, 0x85
	jrl z, SeqNote_UpdatePositionA_Entry
	ld c, (xsp + 20)
	extz bc
	cp e, 0xd2
	jrl z, SeqNote_NoteOff_CheckActive2
	cp e, 0x80
	jrl z, SeqNote_NoteOff_CheckActive
	cp e, 0xd3
	jr z, SeqNoteCh_HandleEventD3
	cp e, 0xd1
	jr z, SeqNoteCh_HandleEventD1
	cp e, 0xd0
	jr z, SeqNoteCh_HandleEventD0
	cp e, 0x82
	jrl nz, SeqNote_ScanNextEvent_Entry
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqNoteCh_EndMark_ShiftDone
	slaa de

SeqNoteCh_EndMark_ShiftDone:
	cpl de
	and (8982:16), de
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	cpw (0x28a8:16), 0
	jr nz, SeqNoteCh_EndMark_SetStatus5
	cp (7570:16), 0
	jr nz, SeqNoteCh_EndMark_SetStatus5
	ld wa, (0xf19e:16)
	ld bc, (SEQ_ACTIVE_PARTS:16)
	and wa, bc
	jr nz, SeqNoteCh_EndMark_SetStatus5
	ld (xsp + 6), 0x1
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_EndMark_SetStatus5:
	ld (xsp + 6), 0x5
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleEventD0:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleEventD1:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleEventD3:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jrl nz, SeqNote_ConditionalWriteToBuffer

SeqNote_SendNoteOff:
	ld a, (xsp + 20)
	dec 1, a
	ld (xsp + 13), a
	ld (xsp + 4), 0x4
	jrl SeqNote_WriteEventToBuffer

SeqNote_NoteOff_CheckActive:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jrl nz, SeqNote_ConditionalWriteToBuffer
	ld a, (xsp + 20)
	extz wa
	lda xbc, (xsp + 10)
	calr AccPedalConfig_ApplyTempo
	ld (xsp + 4), l
	jr SeqNote_ConditionalWriteToBuffer

SeqNote_NoteOff_CheckActive2:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jr nz, SeqNote_ConditionalWriteToBuffer

SeqNote_NoteOff_WritePart:
	ld a, (xsp + 20)
	dec 1, a
	ld (xsp + 14), a
	ld (xsp + 4), 0x5
	jr SeqNote_WriteEventToBuffer

SeqNote_UpdatePositionA_Entry:
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jr nz, SeqNote_ConditionalWriteToBuffer
	lda xwa, (xsp + 10)
	ld c, (xsp + 20)
	extz bc
	calr SeqNote_UpdatePlayPosition_A
	jr SeqNote_ConditionalWriteToBuffer

SeqNote_UpdatePositionB_Entry:
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cp l, 1:i3
	jr nz, SeqNote_ConditionalWriteToBuffer
	lda xwa, (xsp + 10)
	ld c, (xsp + 20)
	extz bc
	calr SeqNote_UpdatePlayPosition_B
	jr SeqNote_ConditionalWriteToBuffer

SeqNote_ScanNextEvent_Entry:
	ld wa, bc
	calr Chan_IsActive
	cp l, 1:i3
	jr nz, SeqNote_ScanNextEvent_ClearBit
	ld a, (xsp + 20)
	extz wa
	calr SeqPart_ScanNextEvent
	cp l, 0:i3
	jr z, SeqNote_ConditionalWriteToBuffer
	ld l, 0x4:opc
	jr SeqNote_WriteEvent_Return

SeqNote_ScanNextEvent_ClearBit:
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNote_ScanNextEvent_ShiftDone
	slaa bc

SeqNote_ScanNextEvent_ShiftDone:
	cpl bc
	and (SEQ_ACTIVE_PARTS:16), bc

SeqNote_ConditionalWriteToBuffer:
	cp (xsp + 4), 0x0
	jr z, SeqNote_WriteEvent_RetStatus

SeqNote_WriteEventToBuffer:
	lda xwa, (xsp + 10)
	ld c, (xsp + 4)
	extz bc
	call SeqBuf_WriteMidiEvent

SeqNote_WriteEvent_RetStatus:
	ld l, (xsp + 6)

SeqNote_WriteEvent_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

VoiceType_CheckDrumOrControl:
	ldib_erp 0xe2, 0
	cp (xbc), 0x82
	jr z, VoiceType_ReturnZero
	ld w, (xbc)
	and w, 0xf0
	lda xde, (xbc + 2)
	lda xhl, (xbc + 3)
	cp w, 0xc0
	jr nz, VoiceType_CheckControlB0
	cp (xde), 0x48
	jr nz, VoiceType_ValidateCode
	cp (xhl), 0x0
	jr z, VoiceType_SetMatchFlag
	jr VoiceType_ValidateCode

VoiceType_CheckControlB0:
	ld c, (xbc)
	and c, 0xf0
	cp c, 0xb0
	jr nz, VoiceType_ValidateCode
	cp (xde), 0x48
	jr nz, VoiceType_ValidateCode
	cp (xhl), 0x7
	jr nz, VoiceType_ValidateCode

VoiceType_SetMatchFlag:
	ldib_erp 0xe2, 1

VoiceType_ValidateCode:
	cp a, 0x15
	jr nz, VoiceType_CheckMatchFlag
	cpib_erp 0xe2, 1
	jr nz, VoiceType_ReturnFFFF

VoiceType_ReturnZero:
	ld hl, 0:i3
	ret

VoiceType_CheckMatchFlag:
	cpib_erp 0xe2, 0
	jr z, VoiceType_ReturnZero

VoiceType_ReturnFFFF:
	ldw hl, 0xffff
	ret

SeqNote_ProcessForChannelAlt:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), a
	ld (xsp + 4), 0x0
	ld c, (xsp + 14)
	extz bc
	lda xde, (xsp + 6)
	ld w, c
	ldfr_berp W, 0xe6
	ld xiy, xde
	ldib_erp 0xe2, 0

SeqNote_ProcessAlt_CopyDataLoop:
	ldto_berp L, 0xe2
	extz hl
	ld iz, hl
	inc 2, iz
	ldto_berp L, 0xe6
	dec 1, l
	extz hl
	sla hl, 3
	lda xix, (9016:16)
	exts xhl
	add xhl, xix
	ld ix, iz
	extz xix
	add xix, xhl
	ldto_berp L, 0xe2
	extz hl
	ld a, (xix)
	ld	(xiy+hl), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqNote_ProcessAlt_CopyDataLoop
	ld l, (xde)
	ld h, l
	and h, 0xf0
	ldib_erp 0xfb, 0
	ld a, h
	cp h, 0xc0
	jr z, SeqNote_ProcessAlt_ProgramChange
	cp a, 0xb0
	jr z, SeqNote_ProcessAlt_ControlChange
	cp a, 0x90
	jr nz, SeqNote_ProcessAlt_CheckSpecial
	ld wa, bc
	ld xbc, xde
	calr SeqNote_SetupVoice
	cp l, 0:i3
	jr nz, SeqMidi_EmitEventToBuffer
	ld a, (xsp + 14)
	dec 1, a
	ld (xsp + 10), a

SeqNote_ProcessAlt_WriteBuffer5:
	ldib_erp 0xfb, 5
	jr SeqNote_WriteChannelToBuffer

SeqNote_ProcessAlt_ControlChange:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyChannel0
	ldfr_berp L, 0xfb

SeqMidi_EmitEventToBuffer:
	cpib_erp 0xfb, 0
	jr z, SeqNote_ProcessAlt_RetStatus

SeqNote_WriteChannelToBuffer:
	lda xwa, (xsp + 6)
	ldto_berp C, 0xfb
	extz bc
	call SeqBuf_WriteMidiEvent

SeqNote_ProcessAlt_RetStatus:
	ld l, (xsp + 4)
	jrl SeqNote_ProcessAlt_Return

SeqNote_ProcessAlt_ProgramChange:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyChannelDirect
	ldfr_berp L, 0xfb
	jr SeqMidi_EmitEventToBuffer

SeqNote_ProcessAlt_CheckSpecial:
	ld h, l
	cp l, 0x86
	jr z, SeqNote_ProcessAlt_86UpdateB
	cp h, 0x85
	jr z, SeqNote_ProcessAlt_85UpdateA
	ld a, (xsp + 14)
	dec 1, a
	cp h, 0xd2
	jr z, SeqNote_ProcessAlt_D2Store
	cp h, 0x80
	jr z, SeqNote_ProcessAlt_80Tempo
	inc 3, xde
	cp h, 0xd3
	jr z, SeqNote_WriteChannelEvt
	cp h, 0xd1
	jr z, SeqNote_WriteChannelEvt
	cp h, 0xd0
	jr z, SeqNote_WriteChannelEvt
	cp h, 0x82
	jr nz, SeqNote_ProcessAlt_ErrorUnknown
	dec 1, w
	ld de, 1:i3
	ld a, w
	and a, 0xf
	jr z, SeqNote_ProcessAlt_82ShiftDone
	slaa de

SeqNote_ProcessAlt_82ShiftDone:
	cpl de
	and (8982:16), de
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	ld wa, (0xf19e:16)
	ld bc, (SEQ_ACTIVE_PARTS:16)
	and wa, bc
	jr nz, SeqNote_ProcessAlt_82AllDone
	ld (xsp + 4), 0x1
	jr SeqMidi_EmitEventToBuffer

SeqNote_ProcessAlt_82AllDone:
	ld (xsp + 4), 0x5
	jrl SeqMidi_EmitEventToBuffer

SeqNote_WriteChannelEvt:
	ld (xde), a
	ldib_erp 0xfb, 4
	jrl SeqNote_WriteChannelToBuffer

SeqNote_ProcessAlt_80Tempo:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyTempo
	ldfr_berp L, 0xfb
	jrl SeqMidi_EmitEventToBuffer

SeqNote_ProcessAlt_D2Store:
	ld (xde + 4), a
	jrl SeqNote_ProcessAlt_WriteBuffer5

SeqNote_ProcessAlt_85UpdateA:
	ld xwa, xde
	calr SeqNote_UpdatePlayPosition_A
	jrl SeqMidi_EmitEventToBuffer

SeqNote_ProcessAlt_86UpdateB:
	ld xwa, xde
	calr SeqNote_UpdatePlayPosition_B
	jrl SeqMidi_EmitEventToBuffer

SeqNote_ProcessAlt_ErrorUnknown:
	ld wa, 5:i3
	call SeqData_SetErrorCode
	ld a, (xsp + 14)
	extz wa
	calr SeqPart_ScanNextEvent
	cp l, 0:i3
	jrl z, SeqMidi_EmitEventToBuffer
	ld l, 0x4:opc

SeqNote_ProcessAlt_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

Chan_IsActive:
	cp a, 1:i3
	jr c, Chan_IsActive_RetTrue
	cp a, 0x10
	jr ugt, Chan_IsActive_RetTrue
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, Chan_IsActive_ShiftDone
	slaa bc

Chan_IsActive_ShiftDone:
	ld wa, (0xf19e:16)
	and wa, bc
	jr nz, Chan_IsActive_RetTrue
	ld l, 0x0:opc
	ret

Chan_IsActive_RetTrue:
	ld l, 0x1:opc
	ret

AccPedalConfig_ApplyChannel0:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ld a, (xsp + 2)
	dec 1, a
	ld (xbc + 6), a
	cp (xbc + 2), 0x48
	jrl nz, AccPedalConfig_ReturnError7
	ld d, (xbc + 3)
	cp d, 5:i3
	jr z, AccPedalConfig_ValidCtrl5_6_7
	cp d, 6:i3
	jr z, AccPedalConfig_ValidCtrl5_6_7
	cp d, 7:i3
	jrl nz, AccPedalConfig_ReturnError7

AccPedalConfig_ValidCtrl5_6_7:
	ld a, (xbc + 4)
	ldfr_berp A, 0xfa
	ld a, (xbc + 5)
	ldfr_berp A, 0xfb
	bitm 0, (xbc)
	jr z, AccPedalConfig_CheckBit1
	set_erpb 0xfa, 0x07

AccPedalConfig_CheckBit1:
	bitm 1, (xbc)
	jr z, AccPedalConfig_CheckCtrl7
	set_erpb 0xfb, 0x07

AccPedalConfig_CheckCtrl7:
	cp d, 7:i3
	jr nz, AccPedalConfig_NotCtrl7
	ldto_berp E, 0xfa
	extz de
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	ldw wa, 0x48
	ld bc, 7:i3
	call AddswbWr
	ld (7546:16), 72
	ld (7548:16), 7
	ldto_berp A, 0xfa
	ld (7550:16), a
	ldto_berp A, 0xfb
	ld (7552:16), a
	ld a, (xsp + 2)
	dec 1, a
	ld (7554:16), a
	ld c, (7546:16)
	ld b, (7548:16)
	ld e, (7550:16)
	ld d, (7552:16)
	ld a, (7554:16)
	call SeqVoice_UpdateTempoParam

Chan_IsActive_RetFalse:
	ld l, 0x0:opc
	jrl AccPedalCfg_ReturnAndCleanup

AccPedalConfig_NotCtrl7:
	ldfr_berp D, 0xf0
	extz ix
	ld iy, ix
	ldto_berp L, 0xfa
	extz hl
	ld bc, hl
	bit 2, (1054:16)
	jrl z, AccPedalCfg_CheckBit6Replay
	ldto_berp E, 0xf4
	cp d, 6:i3
	jr nz, AccPedalConfig_Ctrl5Path
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_StoreCtrl6ValsAlt
	bit_erpb 0xfa, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cp a, (8990:16)
	jr nz, AccPedalConfig_StoreCtrl6Vals
	cp (7560:16), 0
	jrl nz, AccPedalConfig_ClearFlag7560

AccPedalConfig_StoreCtrl6Vals:
	ldto_berp A, 0xfb
	extz wa
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_StoreCtrl6ValsAlt:
	ldto_berp A, 0xfb
	extz wa
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_Ctrl5Path:
	ld a, (8988:16)
	bit_erpb 0xfb, 0x04
	jr z, AccPedalConfig_Ctrl5Bit5
	bit_erpb 0xfa, 0x04
	jrl z, AccPedalConfig_ReturnError7
	cp (xsp + 2), a
	jr nz, AccPedalConfig_Ctrl5Store
	ld (0x32e2:16), 1

AccPedalConfig_Ctrl5Store:
	ldto_berp C, 0xfb
	extz bc
	ldto_berp A, 0xf0
	ld (0x3488:16), a
	ld (0x3475:16), l
	ld (RHYTHM_VARIATION_INDEX:16), c
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_Ctrl5Bit5:
	bit_erpb 0xfb, 0x05
	jr z, AccPedalConfig_Ctrl5Bit2
	bit_erpb 0xfa, 0x05
	jrl z, AccPedalConfig_ReturnError7
	cp (xsp + 2), a
	jr nz, AccPedalConfig_Ctrl5Bit5Store
	ld (0x32e2:16), 1

AccPedalConfig_Ctrl5Bit5Store:
	ldto_berp C, 0xfb
	extz bc
	ldto_berp A, 0xf0
	ld (0x3488:16), a
	ld (0x3475:16), l
	ld (RHYTHM_VARIATION_INDEX:16), c
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_Ctrl5Bit2:
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_Ctrl5Bit3
	bit_erpb 0xfa, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cp a, (8990:16)
	jr nz, AccPedalConfig_Ctrl5Bit2Store
	cp (7560:16), 0
	jr nz, AccPedalConfig_ClearFlag7560

AccPedalConfig_Ctrl5Bit2Store:
	ldto_berp A, 0xfb
	extz wa
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_Ctrl5Bit3:
	bit_erpb 0xfb, 0x03
	jr z, AccPedalCfg_CheckBit6
	bit_erpb 0xfa, 0x03
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cp a, (8990:16)
	jr nz, AccPedalConfig_StorePedalValues
	cp (7560:16), 0
	jr z, AccPedalConfig_StorePedalValues

AccPedalConfig_ClearFlag7560:
	ld (7560:16), 0
	jrl Chan_IsActive_RetFalse

AccPedalConfig_StorePedalValues:
	ldto_berp A, 0xfb
	extz wa
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jrl AccPedalConfig_ReplayAndReturnOK

AccPedalCfg_CheckBit6:
	ldto_berp A, 0xfb
	extz wa
	bit_erpb 0xfb, 0x06
	jr z, AccPedalCfg_CheckBit7
	bit_erpb 0xfa, 0x06
	jrl z, AccPedalConfig_ReturnError7
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jr AccPedalConfig_ReplayAndReturnOK

AccPedalCfg_CheckBit7:
	bit_erpb 0xfb, 0x07
	jr z, AccPedalCfg_StoreValues
	bit_erpb 0xfa, 0x07
	jr z, AccPedalConfig_ReturnError7

AccPedalCfg_StoreValues:
	ld (0x3488:16), e
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jr AccPedalConfig_ReplayAndReturnOK

AccPedalCfg_CheckBit6Replay:
	bit_erpb 0xfb, 0x06
	jr z, AccPedalCfg_CheckBit7Alt
	cp (ACTIVE_TITLE:16), 129
	jr nz, AccPedalConfig_ApplyChannelSettings
	bit 5, (0x28b3:16)
	jr z, AccPedalConfig_ApplyChannelSettings
	res_erpb 0xfb, 0x06

AccPedalConfig_ApplyChannelSettings:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xf0
	ld e, a
	cp d, 6:i3
	jr nz, AccPedalConfig_CheckMaskBits
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_CheckMaskBits
	jr AccPedalCfg_StoreMaskValues

AccPedalCfg_CheckBit7Alt:
	bit_erpb 0xfb, 0x07
	jr nz, AccPedalConfig_ApplyChannelSettings
	ldto_berp E, 0xfb
	extz de
	ldto_berp A, 0xf4
	ld (0x3488:16), a
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), e
	jr AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_CheckMaskBits:
	ldto_berp A, 0xfb
	and a, 0xc
	jr z, AccPedalCfg_CheckZeroMask

AccPedalCfg_StoreMaskValues:
	ld (0x3488:16), c
	ld (0x3475:16), l
	ld (RHYTHM_VARIATION_INDEX:16), e

AccPedalConfig_ReplayAndReturnOK:
	call AccWrap_ReplaySavedPedal
	jrl Chan_IsActive_RetFalse

AccPedalCfg_CheckZeroMask:
	cpib_erp 0xfb, 0
	jrl z, Chan_IsActive_RetFalse

AccPedalConfig_ReturnError7:
	ld l, 0x7:opc

AccPedalCfg_ReturnAndCleanup:
	popw_erp 0xfa
	inc 2, xsp
	ret

AccPedalConfig_ApplyChannelDirect:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 6), a
	cp (xiz + 2), 0x48
	jr nz, AccPedalConfig_ChannelDirect_Error
	ld c, (xiz + 3)
	cp c, 0:i3
	jr nz, AccPedalConfig_ChannelDirect_Error
	ld a, (xiz + 4)
	ld (xsp + 4), a
	bitm 0, (xiz)
	jr z, AccPedalDirect_ClearBit7
	setm 7, (xsp + 4)

AccPedalDirect_ClearBit7:
	extz bc
	ld e, (xsp + 4)
	extz de
	ld a, (xiz + 5)
	extz wa
	pushw wa
	ldw wa, 0x48
	call AddswbWr
	ld (7546:16), 72
	mrdb5 0x8e, 0x03, 0x19, 0x7c, 0x1d
	mrdb5 0x8f, 0x04, 0x19, 0x7e, 0x1d
	mrdb5 0x8e, 0x05, 0x19, 0x80, 0x1d
	ld a, (xsp + 6)
	dec 1, a
	ld (7554:16), a
	ld c, (7546:16)
	ld b, (7548:16)
	ld e, (7550:16)
	ld d, (7552:16)
	ld a, (7554:16)
	call MidiNote_RhythmPartDispatch
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceByte
	cp l, 0x10
	jr nz, AccPedalDirect_ReturnOK
	mrdb5 0x8f, 0x04, 0x19, 0x8c, 0x1d
	mrdb5 0x8e, 0x05, 0x19, 0x8e, 0x1d

AccPedalDirect_ReturnOK:
	ld l, 0x0:opc
	jr AccPedalDirect_Return

AccPedalConfig_ChannelDirect_Error:
	ld a, (xsp + 6)
	dec 1, a
	ld (xiz + 6), a
	ld l, 0x7:opc

AccPedalDirect_Return:
	pop xiz
	inc 4, xsp
	ret

AccPedalConfig_ApplyTempo:
	pushw_erp 0xfa
	ld e, (xbc + 2)
	ld a, (xbc + 3)
	ldfr_berp A, 0xfb
	bit_erpb 0xfb, 0x00
	jr z, AccPedalTempo_ClearBit7
	set 7, e

AccPedalTempo_ClearBit7:
	srl_erpb 0xfb, 0x01
	lda xbc, (0xfc5a:16)
	ld (xbc + 8), e
	ldto_berp A, 0xfb
	ld (xbc + 9), a
	extz de
	pushw 0xff
	ldw wa, 0x48
	ldw bc, 0x8
	call AddswbWr
	ldto_berp E, 0xfb
	extz de
	pushw 0x1
	ldw wa, 0x48
	ldw bc, 0x9
	call AddswbWr
	call SeqTimer_UpdateTempoReg
	ld l, 0x0:opc
	popw_erp 0xfa
	ret

SeqNote_UpdatePlayPosition_A:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	bit 2, (1054:16)
	jr nz, SeqNotePos_Return
	bit 4, (0x28ac:16)
	jr z, SeqNotePos_CheckInterruptFlag
	set 1, (0x28a7:16)
	jr SeqNotePos_Return

SeqNotePos_CheckInterruptFlag:
	ei 6
	ld a, (xsp)
	cp a, (8988:16)
	jr z, SeqNotePos_CheckMainChannel
	cp a, (8990:16)
	jr nz, SeqNotePos_IncrementTick

SeqNotePos_CheckMainChannel:
	ld xwa, (xsp + 2)
	inc 1, xwa
	cp (xwa), 0x0
	jr nz, SeqNotePos_ClampAndWrite
	ld (xwa), 0x5f

SeqNotePos_ClampAndWrite:
	mrib4 0x80, 0x19, 0x2f, 0x04
	jr SeqNotePos_SetUpdateFlag

SeqNotePos_IncrementTick:
	ld a, (SEQ_BEAT_TICK:16)
	inc 1, a
	cp a, 0x5f
	jr ule, SeqNotePos_StoreTick
	ld a, 0x0:opc

SeqNotePos_StoreTick:
	ld (1071:16), a

SeqNotePos_SetUpdateFlag:
	set 0, (1073:16)
	ei 0

SeqNotePos_Return:
	inc 6, xsp
	ret

SeqNotePos_DataBlock_A:
	ei	6
	ld	a, (SEQ_BEAT_TICK:16)
	inc	1, a
	cp	a, 96
	jr	c, SeqNote_UpdatePlayPosition_A_Skip
	ld	a, 0:opc
SeqNote_UpdatePlayPosition_A_Skip:
	ld	(1071:16), a
	set	0, (1073:16)
	ei	0
	ret

SeqNote_UpdatePlayPosition_B:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	bit 2, (1054:16)
	jr z, SeqNote_StackCleanupRet
	bit 1, (0x28b2:16)
	jr nz, SeqNote_StackCleanupRet
	bit 4, (0x28ac:16)
	jr nz, SeqNote_StackCleanupRet
	ei 6
	ld a, (xsp)
	cp a, (8996:16)
	jr z, SeqNotePosB_CalcTick
	cp a, (8994:16)
	jr nz, SeqNotePosB_WriteFromStack

SeqNotePosB_CalcTick:
	ld a, (SEQ_BEAT_TICK:16)
	inc 1, a
	cp a, 0x5f
	jr ule, SeqNotePosB_StoreTick
	ld a, 0x0:opc

SeqNotePosB_StoreTick:
	ld (1072:16), a
	jr SeqNotePosB_SetUpdateFlag

SeqNotePosB_WriteFromStack:
	ld xwa, (xsp + 2)
	mrdb5 0x88, 0x01, 0x19, 0x30, 0x04

SeqNotePosB_SetUpdateFlag:
	set 3, (1073:16)
	ei 0

SeqNote_StackCleanupRet:
	inc 6, xsp
	ret

SeqNotePosB_DataBlock:
	ei	6
	ld	a, (SEQ_BEAT_TICK:16)
	inc	1, a
	cp	a, 96
	jr	c, SeqNote_UpdatePlayPosition_B_Skip
	ld	a, 0:opc
SeqNote_UpdatePlayPosition_B_Skip:
	ld	(1072:16), a
	set	3, (1073:16)
	ei	0
	ret

SeqVoice_HandleEndMark:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), a
	ldmw2 (xsp + 4), 0x2326
	ld hl, (8954:16)
	ld wa, (xsp + 4)
	sub wa, hl
	cp wa, 0x78
	jrl ule, VoiceConfig_CounterIncr
	call SeqBuffer_FindMinPosition
	ld wa, (xsp + 4)
	sub wa, hl
	cp wa, 0x78
	jrl ule, VoiceConfig_CounterIncr
	ld a, (8182:16)
	ldfr_berp A, 0xfa
	cp_erpb 0xfa, 0xff
	jrl z, VoiceConfig_CounterIncr

SeqVoice_EndMark_ProcessSlot:
	ldto_berp A, 0xfa
	extz wa
	ld bc, wa
	muls bc, 0xc
	lda xde, (8186:16)
	exts xbc
	add xbc, xde
	ld hl, (xbc + 4)
	ld de, (xsp + 4)
	sub de, hl
	cp de, 0x78
	jrl c, SeqVoice_ApplyChannels_NextSlot
	ld bc, (xsp + 4)
	ldw de, 0x5f
	calr Part_AssignVoiceConfig
	cp (xsp + 20), 0x1
	jr nz, SeqVoice_MatchAssign_ReadSlot
	lda xde, (xsp + 6)
	lda xbc, (9252:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr SeqVoice_ApplyToChannels

SeqVoice_MatchAssign_ReadSlot:
	ldto_berp A, 0xfa
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8195:16)
	ld	a, (xwa+bc)
	ldfr_berp A, 0xfb
	ld l, (0x28c5:16)
	and l, 0x41
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp l, 0x41
	jr nz, SeqVoice_LoadDefaultParams
	ld hl, 1:i3
	ldto_berp A, 0xfb
	and a, 0xf
	jr z, SeqVoice_MatchAssign_ShiftDone
	slaa hl

SeqVoice_MatchAssign_ShiftDone:
	and hl, (0x28a8:16)
	jr z, SeqVoice_LoadDefaultParams
	lda xhl, (xsp + 6)
	add bc, bc
	lda xwa, (0x291e:16)
	ld	wa, (xwa+bc)
	ld (xhl), wa
	extz de
	lda xbc, (0x293e:16)
	extz xde
	add xde, xbc
	ld a, (xde)
	extz wa
	ld (xhl + 2), wa
	jr SeqVoice_ApplyToChannels

SeqVoice_LoadDefaultParams:
	lda xde, (xsp + 6)
	sla bc, 2
	lda xwa, (9184:16)
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

SeqVoice_ApplyToChannels:
	ldto_berp A, 0xfa
	extz wa
	lda xbc, (xsp + 10)
	ldfr_berp A, 0xee
	ld xix, xbc
	ldib_erp 0xea, 0

SeqVoice_ApplyToChannels_Loop:
	ldto_berp L, 0xea
	extz hl
	ldto_berp A, 0xee
	extz wa
	muls wa, 0xc
	ld de, wa
	lda xwa, (8186:16)
	lda	xwa, (xwa+de)
	ld iy, hl
	extz xiy
	add xiy, xwa
	ldto_berp E, 0xea
	extz de
	ld a, (xiy)
	ld	(xix+de), a
	inc1b_erp 0xea
	cpib_erp 0xea, 4
	jr c, SeqVoice_ApplyToChannels_Loop
	ld (xbc + 1), 0x0
	lda xwa, (xsp + 6)
	ld de, 4:i3
	call Part_CopyBytesToVoiceBlock
	ldto_berp A, 0xfa
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda	xde, (xbc+wa)
	lda xwa, (xsp + 6)
	ld bc, (xwa)
	ld (xde + 6), bc
	ld bc, (xwa + 2)
	ld (xde + 8), c
	ld bc, (xsp + 4)
	inc 1, bc
	ld (xde + 4), bc
	lda xbc, (xsp + 10)
	ld (xbc), 0x0
	ld (xbc + 1), 0x0
	ld de, 2:i3
	call Part_CopyBytesToVoiceBlock
	lda xiy, (9184:16)
	cp (xsp + 20), 0x1
	jr nz, SeqVoice_ApplyChannels_CheckMode
	lda xwa, (xsp + 6)
	ld de, (xwa)
	ld bc, (xwa + 2)
	lda xwa, (xiy + 68)
	ld (xwa), de
	ld (xwa + 2), bc
	jr SeqVoice_ApplyChannels_UpdateSlot

SeqVoice_ApplyChannels_CheckMode:
	ld d, (0x28c5:16)
	and d, 0x41
	lda xix, (xsp + 6)
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	lda xhl, (xix + 2)
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp d, 0x41
	jr nz, SeqVoice_ApplyChannels_FromTable
	ld iz, 1:i3
	ldto_berp A, 0xfb
	and a, 0xf
	jr z, SeqVoice_ApplyChannels_ShiftDone
	slaa iz

SeqVoice_ApplyChannels_ShiftDone:
	and iz, (0x28a8:16)
	jr z, SeqVoice_ApplyChannels_FromTable
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	lda xwa, (0x291e:16)
	ld	(xwa+bc), ix
	extz de
	lda xbc, (0x293e:16)
	extz xde
	add xde, xbc
	ld (xde), l
	jr SeqVoice_ApplyChannels_UpdateSlot

SeqVoice_ApplyChannels_FromTable:
	ld ix, (xix)
	ld de, (xhl)
	sla bc, 2
	lda	xwa, (xiy+bc)
	ld (xwa), ix
	ld (xwa + 2), de

SeqVoice_ApplyChannels_UpdateSlot:
	ldto_berp A, 0xfa
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8186:16)
	exts xbc
	add xbc, xwa

SeqVoice_ApplyChannels_NextSlot:
	ld a, (xbc + 11)
	ldfr_berp A, 0xfa
	cp_erpb 0xfa, 0xff
	jrl nz, SeqVoice_EndMark_ProcessSlot

VoiceConfig_CounterIncr:
	ld wa, (8998:16)
	inc 1, wa
	ld (8998:16), wa
	cp (xsp + 20), 0x1
	jr nz, VoiceConfig_CounterIncr_Check
	ld bc, (9006:16)
	cp (xsp + 4), bc
	jr c, VoiceConfig_ReturnAndCleanup
	ld bc, 0:i3
	calr VoiceConfig_FindChannelMatch
	ldw wa, 0x12
	ld xbc, (xsp + 16)
	ld de, 1:i3
	calr ToneVoice_AssignChannel
	jr VoiceConfig_ReturnAndCleanup

VoiceConfig_CounterIncr_Check:
	ldib_erp 0xfb, 1

VoiceConfig_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, VoiceConfig_PartShiftDone
	slaa bc

VoiceConfig_PartShiftDone:
	and bc, (0x28a8:16)
	jr z, VoiceConfig_PartLoopNext
	ldto_berp A, 0xfb
	extz wa
	ld xbc, (xsp + 16)
	ld de, 1:i3
	calr ToneVoice_AssignChannel

VoiceConfig_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, VoiceConfig_PartLoop

VoiceConfig_ReturnAndCleanup:
	pop xiz
	lda xsp, (xsp + 18)
	ret

Part_AssignVoiceConfig:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), e
	ld (xsp + 20), bc
	ld c, a
	extz bc
	lda xde, (xsp + 12)
	ld a, c
	ldfr_berp A, 0xe7
	ld xiy, xde
	ldib_erp 0xe6, 0

PartAssign_CopySlotLoop:
	ldto_berp A, 0xe6
	ldfr_berp A, 0xf0
	extz ix
	ldto_berp A, 0xe7
	extz wa
	muls wa, 0xc
	lda xhl, (8186:16)
	exts xwa
	add xwa, xhl
	ld iz, ix
	extz xiz
	add xiz, xwa
	ldto_berp A, 0xe6
	ldfr_berp A, 0xf0
	extz ix
	ld a, (xiz)
	ld	(xiy+ix), a
	inc1b_erp 0xe6
	cpib_erp 0xe6, 4
	jr c, PartAssign_CopySlotLoop
	muls bc, 0xc
	lda	xix, (xhl+bc)
	ld iy, (xix + 4)
	ld l, (xde + 1)
	cp l, (xsp + 18)
	jr ule, PartAssign_CalcOffset
	decm 1, (xsp + 20)
	addmi8 (xsp + 18), 0x60

PartAssign_CalcOffset:
	lda xde, (xsp + 8)
	lda xbc, (xde + 1)
	cp (xsp + 20), iy
	jr c, PartAssign_SetMinValues
	ld a, (xsp + 18)
	sub a, l
	ld (xde), a
	ld wa, (xsp + 20)
	sub wa, iy
	ld (xbc), a
	jr PartAssign_ValidateMinimum

PartAssign_SetMinValues:
	ld (xde), 0x2
	ld (xbc), 0x0

PartAssign_ValidateMinimum:
	cp (xbc), 0x0
	jr nz, PartAssign_WritePositionData
	cp (xde), 0x2
	jr nc, PartAssign_WritePositionData
	ld (xde), 0x2

PartAssign_WritePositionData:
	lda xhl, (xsp + 4)
	ld wa, (xix + 6)
	ld (xhl), wa
	ld c, (xix + 8)
	extz bc
	ld (xhl + 2), bc
	ld wa, (xhl)
	call PartCtrl_WriteBytePair
	pop xiz
	lda xsp, (xsp + 18)
	ret

SeqVoice_ProcessAndAssign:
	push xiz
	ld xiz, xwa
	cp (xiz), 0x80
	jr nz, ToneVoice_VoiceTypeCheck
	ld c, (8996:16)
	cp c, 0xff
	jr z, ToneVoice_VoiceTypeCheck
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, ToneVoice_Type80_ShiftDone
	slaa de

ToneVoice_Type80_ShiftDone:
	and de, (0x28aa:16)
	jr z, ToneVoice_VoiceTypeCheck
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type80_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	ld de, 4:i3
	jr ToneVoice_Type80_Assign

ToneVoice_Type80_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	ld de, 4:i3

ToneVoice_Type80_Assign:
	calr ToneVoice_AssignChannel

ToneVoice_VoiceTypeCheck:
	cp (xiz), 0x85
	jr z, ToneVoice_Type85_86_Process
	cp (xiz), 0x86
	jr nz, ToneVoice_ChannelAssignRet

ToneVoice_Type85_86_Process:
	ld c, (8996:16)
	cp c, 0xff
	jr z, ToneVoice_Type86_CheckCh94
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, ToneVoice_Type85_ShiftDone
	slaa de

ToneVoice_Type85_ShiftDone:
	and de, (0x28aa:16)
	jr z, ToneVoice_Type86_CheckCh94
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type85_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	ld de, 2:i3
	jr ToneVoice_Type85_Assign

ToneVoice_Type85_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	ld de, 2:i3

ToneVoice_Type85_Assign:
	calr ToneVoice_AssignChannel

ToneVoice_Type86_CheckCh94:
	ld c, (8994:16)
	cp c, 0xff
	jr z, ToneVoice_ChannelAssignRet
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, ToneVoice_Type86_ShiftDone
	slaa de

ToneVoice_Type86_ShiftDone:
	and de, (0x28aa:16)
	jr z, ToneVoice_ChannelAssignRet
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type86_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	ld de, 2:i3
	jr ToneVoice_Type86_Assign

ToneVoice_Type86_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	ld de, 2:i3

ToneVoice_Type86_Assign:
	calr ToneVoice_AssignChannel

ToneVoice_ChannelAssignRet:
	pop xiz
	ret

SeqVoice_BufferSwapAndAssign:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xbc
	ld (xsp + 14), a
	cp (xiz + 3), 0x0
	jrl z, SeqVoiceBuf_ScanExistingSlots
	call SeqBuffer_RemoveLastEntry
	ld (xsp + 6), l
	cp (xsp + 6), 0xff
	jrl z, SeqNote_VoiceConfigExit
	ld a, (xiz + 4)
	ld (xsp + 4), a
	ld c, (xsp + 6)
	extz bc
	ld a, c
	ldfr_berp A, 0xee
	ld xix, xiz
	ldib_erp 0xe6, 0

SeqVoiceBuf_CopySlotLoop:
	ldto_berp L, 0xe6
	extz hl
	ldto_berp A, 0xee
	extz wa
	muls wa, 0xc
	lda xde, (8186:16)
	exts xwa
	add xwa, xde
	ld iy, hl
	extz xiy
	add xiy, xwa
	ldto_berp A, 0xe6
	extz wa
	ld	a, (xix+wa)
	ld (xiy), a
	inc1b_erp 0xe6
	cpib_erp 0xe6, 4
	jr c, SeqVoiceBuf_CopySlotLoop
	muls bc, 0xc
	exts xbc
	add xbc, xde
	ld a, (xsp + 4)
	ld (xbc + 9), a
	ldmw2 (xsp + 8), 0x2326
	cp (xsp + 14), 0x1
	jr nz, SeqVoiceBuf_CheckActiveMode
	ld c, (xiz + 1)
	extz bc
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch
	lda xde, (xsp + 10)
	lda xbc, (9252:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr SeqVoiceBuf_CopyToVoiceBlock

SeqVoiceBuf_CheckActiveMode:
	ld l, (0x28c5:16)
	and l, 0x41
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp l, 0x41
	jr nz, SeqVoiceBuf_LoadFromTable
	ld hl, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqVoiceBuf_ActiveShiftDone
	slaa hl

SeqVoiceBuf_ActiveShiftDone:
	and hl, (0x28a8:16)
	jr z, SeqVoiceBuf_LoadFromTable
	lda xhl, (xsp + 10)
	add bc, bc
	lda xwa, (0x291e:16)
	ld	wa, (xwa+bc)
	ld (xhl), wa
	extz de
	lda xbc, (0x293e:16)
	extz xde
	add xde, xbc
	ld a, (xde)
	extz wa
	ld (xhl + 2), wa
	jr SeqVoiceBuf_CopyToVoiceBlock

SeqVoiceBuf_LoadFromTable:
	lda xde, (xsp + 10)
	sla bc, 2
	lda xwa, (9184:16)
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

SeqVoiceBuf_CopyToVoiceBlock:
	lda xwa, (xsp + 10)
	ld xbc, xiz
	ld de, 4:i3
	call Part_CopyBytesToVoiceBlock
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda	xde, (xbc+wa)
	lda xwa, (xsp + 10)
	ld bc, (xwa)
	ld (xde + 6), bc
	ld bc, (xwa + 2)
	ld (xde + 8), c
	ld bc, (xsp + 8)
	ld (xde + 4), bc
	cpw (8954:16), 0xffff
	jr nz, SeqVoiceBuf_CheckMinPosition
	mrdw5 0x9f, 0x08, 0x19, 0xfa, 0x22

SeqVoiceBuf_CheckMinPosition:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld xbc, xiz
	ld de, 2:i3
	call Part_CopyBytesToVoiceBlock
	lda xix, (xsp + 10)
	lda xiy, (9184:16)
	lda xhl, (xix + 2)
	cp (xsp + 14), 0x1
	jr nz, SeqVoiceBuf_CheckActiveModeB
	ld de, (xix)
	ld bc, (xhl)
	lda xwa, (xiy + 68)
	ld (xwa), de
	ld (xwa + 2), bc
	jr SeqVoiceBuf_UpdateAndExit

SeqVoiceBuf_CheckActiveModeB:
	ld d, (0x28c5:16)
	and d, 0x41
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp d, 0x41
	jr nz, SeqVoiceBuf_LoadFromTableB
	ld iz, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqVoiceBuf_ActiveShiftDoneB
	slaa iz

SeqVoiceBuf_ActiveShiftDoneB:
	and iz, (0x28a8:16)
	jr z, SeqVoiceBuf_LoadFromTableB
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	lda xwa, (0x291e:16)
	ld	(xwa+bc), ix
	extz de
	lda xbc, (0x293e:16)
	extz xde
	add xde, xbc
	ld (xde), l
	jr SeqVoiceBuf_UpdateAndExit

SeqVoiceBuf_LoadFromTableB:
	ld ix, (xix)
	ld de, (xhl)
	sla bc, 2
	lda	xwa, (xiy+bc)
	ld (xwa), ix
	ld (xwa + 2), de

SeqVoiceBuf_UpdateAndExit:
	ld a, (xsp + 6)
	extz wa
	call SeqBuffer_InsertAtHead
	jr SeqNote_VoiceConfigExit

SeqVoiceBuf_ScanExistingSlots:
	ld a, (8182:16)
	ld (xsp + 6), a
	cp (xsp + 6), 0xff
	jr z, SeqVoiceBuf_ScanComplete
	lda xhl, (8186:16)
	ld c, (xiz + 2)

SeqVoiceBuf_ScanLoop:
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xc
	lda	xde, (xhl+wa)
	ld w, (xde + 2)
	ld a, (xde + 9)
	ld (xsp + 4), a
	cp w, c
	jr nz, SeqVoiceBuf_ScanNextSlot
	ld a, (xsp + 4)
	cp a, (xiz + 4)
	jr z, SeqVoiceBuf_ScanComplete

SeqVoiceBuf_ScanNextSlot:
	ld a, (xde + 11)
	ld (xsp + 6), a
	cp (xsp + 6), 0xff
	jr nz, SeqVoiceBuf_ScanLoop

SeqVoiceBuf_ScanComplete:
	cp (xsp + 6), 0xff
	jr z, SeqNote_VoiceConfigExit
	ld bc, (8998:16)
	ld a, (xsp + 6)
	extz wa
	ld e, (xiz + 1)
	extz de
	calr Part_AssignVoiceConfig
	ld a, (xsp + 6)
	extz wa
	call SeqBuffer_UnlinkEntry
	ld a, (xsp + 6)
	extz wa
	call SeqBuffer_MoveEntryToHead

SeqNote_VoiceConfigExit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

SeqPart_CheckAndSetVoiceConfig:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ld xbc, (xsp + 2)
	ld a, (xbc + 2)
	ldfr_berp A, 0xfb
	ld a, (xbc + 3)
	ldfr_berp A, 0xfa
	ld xwa, (xsp + 2)
	calr Part_CheckAndSetModifiedFlags
	cp_erpb 0xfb, 0x48
	jr nz, SeqPartCfg_ReturnError6
	cpib_erp 0xfa, 5
	jr z, SeqPartCfg_HandleTempo48
	cpib_erp 0xfa, 6
	jr nz, SeqPartCfg_ReturnError6

SeqPartCfg_HandleTempo48:
	ld c, (8996:16)
	cp c, 0xff
	jr z, SeqPartCfg_CheckCh94
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqPartCfg_Tempo48_ShiftDone
	slaa de

SeqPartCfg_Tempo48_ShiftDone:
	and de, (0x28aa:16)
	jr z, SeqPartCfg_CheckCh94
	bit 1, (0x28b1:16)
	jr z, SeqPartCfg_Tempo48_UsePartIdx
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	ld de, 6:i3
	jr SeqPartCfg_Tempo48_Assign

SeqPartCfg_Tempo48_UsePartIdx:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	ld de, 6:i3

SeqPartCfg_Tempo48_Assign:
	calr ToneVoice_AssignChannel

SeqPartCfg_CheckCh94:
	ld c, (8994:16)
	cp c, 0xff
	jr z, SeqPartCfg_ReturnOK
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqPartCfg_Ch94_ShiftDone
	slaa de

SeqPartCfg_Ch94_ShiftDone:
	and de, (0x28aa:16)
	jr z, SeqPartCfg_ReturnOK
	bit 1, (0x28b1:16)
	jr z, SeqPartCfg_Ch94_UsePartIdx
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	ld de, 6:i3
	jr SeqPartCfg_Ch94_Assign

SeqPartCfg_Ch94_UsePartIdx:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	ld de, 6:i3

SeqPartCfg_Ch94_Assign:
	calr ToneVoice_AssignChannel

SeqPartCfg_ReturnOK:
	ld l, 0x0:opc
	jr SeqPartCfg_Return

SeqPartCfg_ReturnError6:
	ld l, 0x6:opc

SeqPartCfg_Return:
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqNote_SetupVoice:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	ld a, (7604:16)
	ldfr_berp A, 0xfa
	cp_erpb 0xfa, 0xff
	jr nz, SeqSetupVoice_ValidateSlot
	ld l, 0x1:opc
	jrl SeqSetupVoice_Return

SeqSetupVoice_ValidateSlot:
	cp (xsp + 8), 0x0
	jr nz, SeqSetupVoice_CheckRange
	ldw wa, 0xd
	call SeqData_SetErrorCode

SeqSetupVoice_CheckRange:
	cp_erpb 0xfa, 0x40
	jr c, SeqSetupVoice_RemoveAndBuild
	ldw wa, 0xe
	call SeqData_SetErrorCode

SeqSetupVoice_RemoveAndBuild:
	ldto_berp A, 0xfa
	extz wa
	call NoteMap_RemoveHeadEntry
	ld a, (xsp + 8)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	exts xwa
	add xwa, xbc
	ld iz, (xwa)
	ld a, (xwa + 3)
	ldfr_berp A, 0xfb
	ld xwa, (xsp + 4)
	ldto_berp C, 0xfb
	add c, (xwa + 4)
	ldfr_berp C, 0xfb
	cp_erpb 0xfb, 0x60
	jr c, SeqSetupVoice_AdjustOctave
	sub_erpb 0xfb, 0x60
	inc 1, iz

SeqSetupVoice_AdjustOctave:
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	extz wa
	add iz, wa
	cp (xsp + 8), 0x11
	jr nz, SeqSetupVoice_CheckChannel11
	ldmi16 (xsp + 8), 0x231a

SeqSetupVoice_CheckChannel11:
	cp_erpb 0xfb, 0x60
	jr ule, SeqSetupVoice_ValidateRange
	ldw wa, 0xf
	call SeqData_SetErrorCode

SeqSetupVoice_ValidateRange:
	ldto_berp A, 0xfa
	extz wa
	ld bc, wa
	muls bc, 0x9
	lda xde, (7606:16)
	lda	xde, (xde+bc)
	ld xhl, (xsp + 4)
	ld c, (xhl)
	ld (xde + 4), c
	ldto_berp C, 0xfb
	ld (xde + 5), c
	ld c, (xhl + 2)
	ld (xde + 6), c
	ld (xde + 7), 0x0
	ld c, (xsp + 8)
	dec 1, c
	ld (xde + 8), c
	ld (xde + 2), iz
	calr NotePool_InsertEntry
	ld l, 0x0:opc

SeqSetupVoice_Return:
	pop xiz
	inc 6, xsp
	ret

; ============================================================================
; ToneVoice_AssignChannel - Assign a voice/patch to a tone channel
; ============================================================================
; Input:  WA = patch type (0x12=fixed, or patch index), DE = channel
;         (xsp) = destination struct pointer
; Output: Writes voice entry to dest[0] and value to dest[2]
; Checks voice source flag at 10437, applies via tone gen update (F41AF8).
; ============================================================================
ToneVoice_AssignChannel:
	dec 6, xsp
	ld (xsp + 4), a
	ld a, (0x28c5:16)
	and a, 0x41
	ldfr_berp A, 0xe2
	ld a, (xsp + 4)
	extz wa
	dec 1, a
	ld d, a
	ld l, d
	extz hl
	cp_erpb 0xe2, 0x41
	jr nz, ToneVoice_Assign_FromTable
	ld a, (xsp + 4)
	dec 1, a
	ld ix, 1:i3
	and a, 0xf
	jr z, ToneVoice_Assign_ShiftDone
	slaa ix

ToneVoice_Assign_ShiftDone:
	and ix, (0x28a8:16)
	jr z, ToneVoice_Assign_FromTable
	lda xix, (xsp)
	add hl, hl
	lda xwa, (0x291e:16)
	ld	wa, (xwa+hl)
	ld (xix), wa
	ld a, d
	extz wa
	lda xhl, (0x293e:16)
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	extz wa
	ld (xix + 2), wa
	jr ToneVoice_Assign_CopyToVoice

ToneVoice_Assign_FromTable:
	lda xix, (xsp)
	sla hl, 2
	lda xwa, (9184:16)
	exts xhl
	add xhl, xwa
	ld wa, (xhl)
	ld (xix), wa
	ld wa, (xhl + 2)
	ld (xix + 2), wa

ToneVoice_Assign_CopyToVoice:
	lda xwa, (xsp)
	extz de
	call Part_CopyBytesToVoiceBlock
	ld a, (0x28c5:16)
	and a, 0x41
	ldfr_berp A, 0xe2
	ld a, (xsp + 4)
	extz wa
	dec 1, a
	ldfr_berp A, 0xee
	ldto_berp L, 0xee
	extz hl
	lda xde, (xsp)
	lda xbc, (xde + 2)
	cp_erpb 0xe2, 0x41
	jr nz, ToneVoice_Assign_WriteFromTable
	ld a, (xsp + 4)
	dec 1, a
	ld ix, 1:i3
	and a, 0xf
	jr z, ToneVoice_Assign_WriteShiftDone
	slaa ix

ToneVoice_Assign_WriteShiftDone:
	and ix, (0x28a8:16)
	jr z, ToneVoice_Assign_WriteFromTable
	ld ix, (xde)
	ld de, (xbc)
	add hl, hl
	lda xwa, (0x291e:16)
	ld	(xwa+hl), ix
	ldto_berp A, 0xee
	extz wa
	lda xbc, (0x293e:16)
	extz xwa
	add xwa, xbc
	ld (xwa), e
	jr ToneVoice_Assign_Return

ToneVoice_Assign_WriteFromTable:
	ld de, (xde)
	ld bc, (xbc)
	sla hl, 2
	lda xwa, (9184:16)
	lda	xwa, (xwa+hl)
	ld (xwa), de
	ld (xwa + 2), bc

ToneVoice_Assign_Return:
	inc 6, xsp
	ret

SeqPart_ReadEventStream:
	lda xsp, (xsp - 16)
	ld (xsp + 12), c
	ld (xsp + 14), a
	ld a, (xsp + 14)
	extz wa
	lda xde, (xsp)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

SeqPart_ReadEvent_MainLoop:
	lda xwa, (xsp)
	lda xbc, (xsp + 4)
	call SeqPart_ReadNextEventByte
	lda xhl, (xsp + 4)
	lda xbc, (xhl + 1)
	ld a, (xhl)
	cp a, 0x81
	jr nz, SeqPart_ReadEvent_NotEndMark
	incw 1, (9152:16)
	ld (xbc), 0x0
	cp (xsp + 12), 0x0
	jr nz, SeqPart_ReadEvent_MainLoop

SeqPart_ReadEvent_SavePos:
	ld c, (xsp + 14)
	extz bc
	lda xwa, (xsp)
	ld ix, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), ix
	ld (xwa + 2), de
	lda xwa, (9152:16)
	ld xbc, xhl
	lda xde, (xwa + 2)
	inc 6, xhl

SeqPartRead_CopyLoop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, SeqPartRead_CopyLoop
	lda xsp, (xsp + 16)
	ret

SeqPart_ReadEvent_NotEndMark:
	cp a, 0x82
	jr nz, SeqPart_ReadEvent_SavePos
	ld (xbc), 0x0
	jr SeqPart_ReadEvent_SavePos

SeqPlay_ReassignVoiceChannels:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x2668
	mrdw5 0x9f, 0x04, 0x19, 0x34, 0x23
	bit 1, (0x28b1:16)
	jrl nz, SeqReassign_SinglePartMode
	ldib_erp 0xfb, 1

SeqReassign_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqReassign_PartShiftDone
	slaa bc

SeqReassign_PartShiftDone:
	and bc, (0x28a8:16)
	jrl z, SeqReassign_PartLoopNext
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqReassign_ProcessAndDecrement
	ldto_berp A, 0xfb
	extz wa
	call Part_ClearAndStealSingleVoice
	ldto_berp A, 0xfb
	extz wa
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqReassign_ClearBitShiftDone
	slaa bc

SeqReassign_ClearBitShiftDone:
	cpl bc
	and (8982:16), bc

SeqReassign_ProcessAndDecrement:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqReassign_ReturnError2
	cp (7528:16), 0
	jr z, SeqReassign_ReturnError2
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, 1:i3
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldto_berp A, 0xfb
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), iz
	ldw (xwa + 2), 0x5

SeqReassign_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jrl ule, SeqReassign_PartLoop
	jrl SeqReassign_UpdateAndNotify

SeqReassign_SinglePartMode:
	ld a, (8986:16)
	ldfr_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqReassign_SingleShiftDone
	slaa bc

SeqReassign_SingleShiftDone:
	and bc, (8980:16)
	jrl nz, SeqReassign_UpdateAndNotify
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqReassign_SetVoiceBitAndWrite

SeqReassign_ReturnError2:
	ld l, 0x2:opc
	jrl SeqReassign_Return

SeqReassign_SetVoiceBitAndWrite:
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, 1:i3
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ldto_berp C, 0xfb
	extz bc
	ld l, c
	dec 1, l
	ld a, l
	extz wa
	sla wa, 2
	lda xde, (9184:16)
	exts xwa
	add xwa, xde
	ld (xwa), iz
	ldw (xwa + 2), 0x5
	ld de, 1:i3
	ld a, l
	and a, 0xf
	jr z, SeqReassign_OrPartBits
	slaa de

SeqReassign_OrPartBits:
	or (8982:16), de
	or (SEQ_ACTIVE_PARTS:16), de
	or (8980:16), de
	ld wa, 0:i3
	ld de, iz
	call Part_WriteWord_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	call Part_WriteByte_Indexed
	ldto_berp A, 0xfb
	extz wa
	ld c, a
	dec 1, c
	extz bc
	sla bc, 3
	lda xde, (9332:16)
	exts xbc
	add xbc, xde
	ld (xbc), iz
	ldw (xbc + 2), 0x5
	call SeqCh_LoadChannelConfig

SeqReassign_UpdateAndNotify:
	ld wa, (0x28a8:16)
	ld (0x28aa:16), wa
	ld wa, (8982:16)
	ld (8984:16), wa
	call SeqPlay_CheckRepeatActive
	call SeqAccomp_SendStopNotify
	cpw (xsp + 4), 0x1
	jr nz, SeqReassign_ReturnOK
	bit 1, (0x28b1:16)
	call z, (SeqPlay_PrepareDrumVoice:24)

SeqReassign_ReturnOK:
	ld l, 0x0:opc

SeqReassign_Return:
	pop xiz
	inc 2, xsp
	ret

SeqPlay_AssignAccompVoices:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), c
	ld (xsp + 20), wa
	ldw (7574:16), 0xffff
	ldw (7578:16), 0xffff
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ld (xsp + 4), l
	cp (xsp + 4), 0xff
	jrl z, SeqPlay_RestoreReturn2
	ld a, (xsp + 4)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqAccVoice_ShiftDone
	slaa bc

SeqAccVoice_ShiftDone:
	and bc, (8982:16)
	jrl z, SeqPlay_RestoreReturn2
	addmi8 (xsp + 18), 0x1a
	cp (xsp + 18), 0x60
	jrl c, SeqPlay_WriteVoiceData
	submi8 (xsp + 18), 0x60
	incw 1, (xsp + 20)
	jrl SeqPlay_WriteVoiceData

SeqAccVoice_ComparePosition:
	cp wa, (xsp + 20)
	jr nz, SeqAccVoice_SetupCopyLoop
	ld	a, (xhl+155)
	cp a, (xsp + 18)
	jrl ugt, SeqAccVoice_JumpRestore

SeqAccVoice_SetupCopyLoop:
	lda xix, (xsp + 10)
	ld xiy, xix
	ldib_erp 0xe2, 0

SeqAccVoice_CopySlotLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xbc, (xhl+152:16)
	ld de, wa
	extz xde
	add xde, xbc
	ldto_berp C, 0xe2
	extz bc
	ld a, (xde)
	ld	(xiy+bc), a
	inc1b_erp 0xe2
	lda xbc, (xix + 4)
	lda xde, (xix + 5)
	cpib_erp 0xe2, 6
	jr c, SeqAccVoice_CopySlotLoop
	ld a, (xsp + 4)
	dec 1, a
	ld hl, 1:i3
	and a, 0xf
	jr z, SeqAccVoice_ShiftDoneCheck
	slaa hl

SeqAccVoice_ShiftDoneCheck:
	ld a, (xix)
	cp a, 0xb0
	jrl nz, SeqAccVoice_HandleNoteOn
	cp (xix + 2), 0x48
	jr nz, ToneVoice_AssignChannel_LoadConfig
	ld a, (xix + 3)
	cp a, 5:i3
	jrl nz, SeqAccVoice_CheckPedalType6
	ld xix, xde
	ld a, (xde)
	and a, 0xc
	jr z, ToneVoice_AssignChannel_LoadConfig
	ld xde, xbc
	ld a, (xbc)
	and a, 0xc
	jr z, ToneVoice_AssignChannel_LoadConfig
	set 1, (8974:16)
	and hl, (0xf19e:16)
	jr z, ToneVoice_AssignChannel_LoadConfig
	ld c, (xde)
	extz bc
	ld a, (xix)
	extz wa
	ld (0x3488:16), 5
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a

SeqAccVoice_ReplaySavedPedal:
	call AccWrap_ReplaySavedPedal

ToneVoice_AssignChannel_LoadConfig:
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig
	lda xix, (xsp + 10)
	ld xiz, xix
	ldib_erp 0xe2, 0

SeqAccVoice_CopyChannelLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xde, (9016:16)
	lda xbc, (xde+152:16)
	ld iy, wa
	extz xiy
	add xiy, xbc
	ldto_berp L, 0xe2
	extz hl
	ld a, (xiy)
	ld	(xiz+hl), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccVoice_CopyChannelLoop
	cp (xix), 0x82
	jr nz, SeqPlay_WriteVoiceData
	lda xhl, (xde+155:16)
	ld a, (xhl)
	cp a, 0x30
	jr ule, SeqAccVoice_AdjustOctave
	incw	1, (xde+152)
	ld a, (xhl)
	sub a, 0x30
	ld (xhl), a

SeqAccVoice_AdjustOctave:
	addmi8 (xhl), 0x30
	lda xde, (xde+152:16)
	ld wa, (xde)
	ld a, (xhl)
	ld (xix + 1), a
	ld l, 0x0:opc

SeqAccVoice_WriteChannelData:
	ld e, l
	extz de
	inc 2, de
	extz xde
	add xde, xbc
	ld a, l
	extz wa
	ld	a, (xix+wa)
	ld (xde), a
	inc 1, l
	cp l, 6:i3
	jr c, SeqAccVoice_WriteChannelData

SeqPlay_WriteVoiceData:
	lda xhl, (9016:16)
	lda xwa, (xhl+152:16)
	ld (xsp + 6), xwa
	ld wa, (xwa)
	cp wa, (xsp + 20)
	jrl ule, SeqAccVoice_ComparePosition

SeqAccVoice_JumpRestore:
	jr SeqPlay_RestoreReturn2

SeqAccVoice_CheckPedalType6:
	cp a, 6:i3
	jrl nz, ToneVoice_AssignChannel_LoadConfig
	ld xix, xde
	bitm 2, (xde)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	ld xwa, xbc
	bitm 2, (xbc)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	set 1, (8974:16)
	and hl, (0xf19e:16)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	ld c, (xwa)
	extz bc
	ld a, (xix)
	extz wa
	ld (0x3488:16), 6
	ld (0x3475:16), c
	ld (RHYTHM_VARIATION_INDEX:16), a
	jrl SeqAccVoice_ReplaySavedPedal

SeqAccVoice_HandleNoteOn:
	cp a, 0x90
	jr nz, SeqAccVoice_HandleEndMark82
	and hl, (0xf19e:16)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	ld wa, 0:i3
	call Voice_AllocateFromSeqData
	jrl ToneVoice_AssignChannel_LoadConfig

SeqAccVoice_HandleEndMark82:
	cp a, 0x82
	jrl nz, ToneVoice_AssignChannel_LoadConfig
	ld xwa, (xsp + 6)
	ldw (xwa), 0xffff

SeqPlay_RestoreReturn2:
	pop xiz
	lda xsp, (xsp + 18)
	ret

SeqPlay_AssignBassVoices:
	lda xsp, (xsp - 18)
	ld (xsp + 14), c
	ld (xsp + 16), wa
	ld wa, 0:i3
	ldw bc, 0x10
	call Part_FindVoiceByByte
	ld (xsp), l
	cp (xsp), 0xff
	jrl z, SeqPlay_BassEpilogue18
	ld a, (xsp)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqBass_ShiftDone
	slaa bc

SeqBass_ShiftDone:
	and bc, (8982:16)
	jrl z, SeqPlay_BassEpilogue18
	addmi8 (xsp + 14), 0x28
	cp (xsp + 14), 0x60
	jrl c, SeqPlay_BassCheck_ShiftDone
	submi8 (xsp + 14), 0x60
	incw 1, (xsp + 16)
	jrl SeqPlay_BassCheck_ShiftDone

SeqBass_ReadAndCompare:
	extz bc
	sla bc, 3
	lda xwa, (9016:16)
	ld (xsp + 2), xwa
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	cp wa, (xsp + 16)
	jrl ugt, SeqPlay_BassEpilogue18
	ld wa, (xbc)
	cp wa, (xsp + 16)
	jr nz, SeqBass_SetupCopyLoop
	ld a, (xbc + 3)
	cp a, (xsp + 14)
	jrl ugt, SeqPlay_BassEpilogue18

SeqBass_SetupCopyLoop:
	ld a, (xsp)
	extz wa
	lda xde, (xsp + 6)
	ld c, a
	ldfr_berp C, 0xee
	ld xiy, xde
	ldib_erp 0xe2, 0

SeqBass_CopySlotLoop:
	ldto_berp C, 0xe2
	extz bc
	ld ix, bc
	inc 2, ix
	ldto_berp L, 0xee
	dec 1, l
	extz hl
	sla hl, 3
	ld xbc, (xsp + 2)
	lda	xbc, (xbc+hl)
	extz xix
	add xix, xbc
	ldto_berp L, 0xe2
	extz hl
	ld c, (xix)
	ld	(xiy+hl), c
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqBass_CopySlotLoop
	cp (xde), 0x82
	jr z, SeqPlay_BassEpilogue18
	calr SeqNote_ProcessForChannel
	lda xwa, (xsp + 6)
	cp (xwa), 0xc0
	jr nz, SeqPlay_DispatchRhythm
	cp (xwa + 2), 0x48
	jr nz, SeqPlay_DispatchRhythm
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_DispatchRhythm
	ld a, (7564:16)
	extz wa
	ld c, (7566:16)
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (9010:16), l
	call SeqMode_SendStatusUpdate

SeqPlay_DispatchRhythm:
	ld a, (xsp)
	extz wa
	call SeqCh_LoadChannelConfig

SeqPlay_BassCheck_ShiftDone:
	ld c, (xsp)
	dec 1, c
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqPlay_BassCheck_TestBit
	slaa de

SeqPlay_BassCheck_TestBit:
	and de, (8982:16)
	jrl nz, SeqBass_ReadAndCompare

SeqPlay_BassEpilogue18:
	lda xsp, (xsp + 18)
	ret

SeqPlay_AssignChordVoices:
	lda xsp, (xsp - 14)
	ld (xsp + 10), c
	ld (xsp + 12), wa
	ld xiy, SeqPlay_AssignChordVoices_LocalInit
	lda xix, (xsp + 2)
	ld bc, 4:i3
	ldirw
	ld wa, 0:i3
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ld (xsp), l
	cp (xsp), 0xff
	jrl z, SeqPlay_ChordEpilogue14
	ld a, (xsp)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_Chord_ShiftDone
	slaa bc

SeqPlay_Chord_ShiftDone:
	and bc, (8982:16)
	jrl z, SeqPlay_ChordEpilogue14
	addmi8 (xsp + 10), 0x28
	cp (xsp + 10), 0x60
	jrl c, SeqPlay_Chord_NextPart
	submi8 (xsp + 10), 0x60
	incw 1, (xsp + 12)
	jrl SeqPlay_Chord_NextPart

SeqPlay_Chord_CompareLoop:
	lda xde, (9016:16)
	ld	wa, (xde+160)
	cp wa, (xsp + 12)
	jrl ugt, SeqPlay_ChordEpilogue14
	cp wa, (xsp + 12)
	jr nz, SeqPlay_Chord_CheckMatch
	ld	a, (xde+163)
	cp a, (xsp + 10)
	jrl ugt, SeqPlay_ChordEpilogue14

SeqPlay_Chord_CheckMatch:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqPlay_Chord_CopyDataLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xhl, (xde+160:16)
	ld ix, wa
	extz xix
	add xix, xhl
	ldto_berp L, 0xe2
	extz hl
	ld a, (xix)
	ld	(xiy+hl), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqPlay_Chord_CopyDataLoop
	cp (xbc), 0x82
	jr z, SeqPlay_ChordEpilogue14
	ldw wa, 0x15
	calr SeqNote_ProcessForChannel
	lda xwa, (xsp + 2)
	cp (xwa), 0xc0
	jr nz, SeqPlay_LoadChannelRet
	cp (xwa + 2), 0x48
	jr nz, SeqPlay_LoadChannelRet
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_LoadChannelRet
	ld a, (7564:16)
	extz wa
	ld c, (7566:16)
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (9010:16), l
	call SeqMode_SendStatusUpdate

SeqPlay_LoadChannelRet:
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig

SeqPlay_Chord_NextPart:
	ld a, (xsp)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_Chord_NextShiftDone
	slaa bc

SeqPlay_Chord_NextShiftDone:
	and bc, (8982:16)
	jrl nz, SeqPlay_Chord_CompareLoop

SeqPlay_ChordEpilogue14:
	lda xsp, (xsp + 14)
	ret

SeqCh_ClearActivePartBit:
	ld c, a
	ld a, c
	extz wa
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqCh_ClearActive_ShiftDone
	slaa de

SeqCh_ClearActive_ShiftDone:
	cpl de
	and (SEQ_ACTIVE_PARTS:16), de
	and (8980:16), de
	ld a, (0xfc5f:16)
	and a, 0x30
	ret nz
	ld a, (8988:16)
	cp c, a
	ret nz
	dec 1, c
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqCh_ClearActive_DrumShiftDone
	slaa de

SeqCh_ClearActive_DrumShiftDone:
	ld wa, (0xf19e:16)
	and wa, de
	ret z
	bit 2, (1054:16)
	ret z
	jp AccWrap_PlayModeStartPlay

NotePool_InsertEntry:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	cp (xsp + 10), 0x40
	jr c, NotePool_Insert_CheckMax
	ldw wa, 0x10
	call SeqData_SetErrorCode

NotePool_Insert_CheckMax:
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x9
	lda xhl, (7606:16)
	lda	xde, (xhl+wa)
	ld iy, (xde + 2)
	ld w, (xde + 5)
	ld (xsp + 8), w
	lda xix, (7602:16)
	lda xwa, (xix + 1)
	ld (xsp + 4), xwa
	ld a, (xwa)
	ldfr_berp A, 0xe2

NotePool_Insert_ScanLoop:
	lda xbc, (xde + 1)
	cp_erpb 0xe2, 0xff
	jr nz, NotePool_Insert_CompareAndLink
	ld (xde), 0xff
	ld a, (xix)
	ldfr_berp A, 0xe2
	ld (xbc), a
	cp_erpb 0xe2, 0xff
	jr z, NotePool_Insert_UpdateHead
	ldto_berp A, 0xe2
	extz wa
	muls wa, 0x9
	ld bc, wa
	ld a, (xsp + 10)
	ld	(xhl+bc), a

NotePool_Insert_UpdateHead:
	ld a, (xsp + 10)
	ld (xix), a
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xe2
	cp_erpb 0xe2, 0xff
	jr z, NotePool_Insert_SetHead
	jr NotePool_Insert_Return

NotePool_Insert_CompareAndLink:
	ldto_berp A, 0xe2
	ldfr_berp A, 0xf8
	extz iz
	muls iz, 0x9
	exts xiz
	add xiz, xhl
	ld wa, (xiz + 2)
	ldfr_werp WA, 0xf6
	ld a, (xiz + 5)
	ldfr_berp A, 0xe3
	ldto_werp WA, 0xf6
	cp wa, iy
	jr ugt, NotePool_Insert_AdvanceScan
	ldto_werp WA, 0xf6
	cp wa, iy
	jr nz, NotePool_Insert_LinkBefore
	ldto_berp A, 0xe3
	cp a, (xsp + 8)
	jr ule, NotePool_Insert_LinkBefore

NotePool_Insert_AdvanceScan:
	ld a, (xiz)
	ldfr_berp A, 0xe2
	jr NotePool_Insert_ScanLoop

NotePool_Insert_LinkBefore:
	ldto_berp A, 0xe2
	ld (xde), a
	lda xix, (xiz + 1)
	ld e, (xix)
	ld (xbc), e
	ld a, (xsp + 10)
	ld (xix), a
	cp e, 0xff
	jr nz, NotePool_Insert_RelinkPrev

NotePool_Insert_SetHead:
	ld xwa, (xsp + 4)
	ld c, (xsp + 10)
	ld (xwa), c
	jr NotePool_Insert_Return

NotePool_Insert_RelinkPrev:
	extz de
	muls de, 0x9
	ld a, (xsp + 10)
	ld	(xhl+de), a

NotePool_Insert_Return:
	pop xiz
	inc 8, xsp
	ret

NotePool_DataBlock_890:
	; data-as-code (v10_data_as_code_census.py, STRICT rule): 0xF3C890-0xF3C8A4 (20 B), unreached CODE-territory, was disassembled as 7 plausible-but-dead instruction lines; per=75% dist=11 near NotePool_DataBlock_890
	.byte 0xc1, 0x7f, 0xc0, 0x21, 0xc9, 0xd8, 0xb0, 0xf6, 0xc1, 0x7e, 0xc0, 0x21
	.byte 0xc9, 0xd8, 0xb0, 0xfe, 0xc1, 0x7d, 0xc0, 0x21
	bit	5, (10419:16)
	ret	z
	cp	a, 4:i3
	ret	nz
	calr	SeqPlay_HandlePlaybackEvent
	call	VoiceAlloc_TestBitRead
	res	5, (10419:16)
	ret
NotePool_DataBlock_8BA:
	bit	7, (8958:16)
	ret	nz
	cp	(CURRENT_MODE:16), 14
	ret	z
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 5:i3
	ret	nz
	ld	c, (SWBTWR_PAYLOAD_2:16)
	ld	a, (SWBTWR_PAYLOAD_3:16)
	and	c, a
	and	c, 64
	ret	z
	cp	(ACTIVE_TITLE:16), 138
	ret	z
	cpw	(0xf19e:16), 0
	ret	z
	bit	2, (SEQ_TRANSPORT_STATE:16)
	ret	nz
	cpw	(0x28a8:16), 0
	ret	nz
	bit	2, (1054:16)
	ret	nz
	jr	SeqPlay_CheckStartConditions

SeqPlay_CheckStartConditions:
	ld a, (8958:16)
	bit 7, a
	ret nz
	set 7, a
	ld (8958:16), a
	cpw (0xf19e:16), 0
	jr nz, SeqPlay_CheckStart_TestSysFlag
	ld a, (8958:16)
	res 7, a
	ld (8958:16), a
	ret

SeqPlay_CheckStart_TestSysFlag:
	ld a, (8958:16)
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqPlay_CheckStart_TestBit5
	res 7, a
	ld (8958:16), a
	ret

SeqPlay_CheckStart_TestBit5:
	bit 5, (0x28b3:16)
	jr z, SeqStart_CheckActiveParts
	res 7, a
	ld (8958:16), a
	ret

SeqStart_CheckActiveParts:
	ld a, (8958:16)
	cpw (0x28a8:16), 0
	jr z, SeqStart_CheckPlaybackBit
	res 7, a
	ld (8958:16), a
	ret

SeqStart_CheckPlaybackBit:
	bit 2, (1054:16)
	jr z, SeqStart_LoadPositionAndMode
	res 7, a
	ld (8958:16), a
	ret

SeqStart_LoadPositionAndMode:
	ld wa, (9832:16)
	ld c, (ACTIVE_TITLE:16)
	cp c, 0x85
	jr z, SeqStart_HandleMode85_86
	cp c, 0x86
	jr nz, SeqStart_HandleOtherModes

SeqStart_HandleMode85_86:
	bit 1, (0x28b1:16)
	jr nz, SeqStart_CheckSavedPosition
	ldw (9832:16), 1
	jr SeqStart_ClearTickAndInit

SeqStart_CheckSavedPosition:
	ld bc, (9504:16)
	cp wa, bc
	jr ugt, SeqStart_RestoreSavedPosition
	ldw (9832:16), 1
	ldw (SEQ_BEAT_COUNT:16), 0
	jr SeqStart_ClearTickAndInit

SeqStart_RestoreSavedPosition:
	ld (9832:16), bc
	ld wa, (9504:16)
	call SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0
	ld wa, (9506:16)
	call SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl

SeqStart_ClearTickAndInit:
	ld (SEQ_BEAT_TICK:16), 0
	jr SeqStart_SendResetAndInit

SeqStart_HandleOtherModes:
	bit 0, (0x28b1:16)
	jr nz, SeqStart_CheckSavedPosAlt
	ldw (9832:16), 1
	jr SeqStart_SendResetAndInit

SeqStart_CheckSavedPosAlt:
	ld bc, (9500:16)
	cp wa, bc
	jr ugt, SeqStart_RestoreSavedPosAlt
	ldw (9832:16), 1
	ldw (SEQ_BEAT_COUNT:16), 0
	jr SeqStart_SendResetAndInit

SeqStart_RestoreSavedPosAlt:
	ld (9832:16), bc
	ld wa, (9500:16)
	call SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0
	ld wa, (9502:16)
	call SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl

SeqStart_SendResetAndInit:
	call NoteEditSy_SendModeScrollReset
	cpw (9832:16), 1
	jr nz, SeqStart_SetBit3
	res 3, (0x28a7:16)
	ld (4596:16), 0
	ld wa, 0:i3
	call BitMapOut_PrepareAndRender
	jr SeqStart_FinalInit

SeqStart_SetBit3:
	set 3, (0x28a7:16)

SeqStart_FinalInit:
	calr SeqAcc_InitPlaybackState
	ld (1073:16), 0
	res 0, (0x28a6:16)
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure
	res 7, (8958:16)
	ret

SeqPlay_EmergencyStopAll:
	ld a, (8976:16)
	cp a, 0:i3
	ret nz
	ld (8976:16), 1
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	call AccWrap_PositionClear
	res 0, (0x28a6:16)
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	ld (8976:16), 0
	ret

Seq_ResetAndRestartAccompaniment:
	ldw (SEQ_ACTIVE_PARTS:16), 0
	call SeqTimer_BarReturn
	res 0, (0x28a6:16)
	res 1, (0x347a:16)
	res 3, (0x28a7:16)
	res 2, (0x28b3:16)
	cp (CURRENT_MODE:16), 19
	jr nz, Seq_ResetRestart_NormalPath
	ld (7572:16), 1
	calr SeqPlay_InitFromDemoRecord
	jr Seq_ResetRestart_CheckSubsystem

Seq_ResetRestart_NormalPath:
	ld (7572:16), 0
	calr SeqAcc_InitPlaybackState

Seq_ResetRestart_CheckSubsystem:
	jp Audio_CheckSubsystemReady

SeqPlay_StopAndResetAll:
	bit 0, (0x28c5:16)
	jr z, SeqPlay_StopReset_NotPlaying
	cpw (0x28a8:16), 0
	ret nz
	ld (8956:16), 0
	ret

SeqPlay_StopReset_NotPlaying:
	ld a, (1054:16)
	bit 3, a
	jr nz, SeqPlay_StopReset_DispatchAccomp
	bit 2, a
	jr z, SeqPlay_StopReset_DispatchAccomp
	bit 2, (SEQ_TRANSPORT_STATE:16)
	ret z
	call AccWrap_PlayModeStopExpr
	ld (8956:16), 0
	jr SeqPlay_StopReset_CleanupAll

SeqPlay_StopReset_DispatchAccomp:
	call AccWrap_PlayModeDispatch

SeqPlay_StopReset_CleanupAll:
	res 5, (0x28b3:16)
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call AccompSeq_StopSequence
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure
	res 3, (0x28a7:16)
	ldw (9832:16), 1
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ld a, (0x28b3:16)
	set 4, a
	set 2, a
	ld (0x28b3:16), a
	ld (8956:16), 0
	cp (CURRENT_MODE:16), 19
	ret nz
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	ldw (SEQ_ACTIVE_PARTS:16), 0
	call UI_PostTimerResetEvent
	call Demo_SelectEntry_AfterSongLoad
	ret

Part_ReadAndProcessVoiceData:
	lda xsp, (xsp - 24)
	ld (xsp + 16), xde
	ld (xsp + 20), bc
	ld (xsp + 22), a
	ldw (xsp), 0x0
	ld c, (xsp + 22)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, Part_ReadVoice_HasData
	ldw hl, 0xffff
	jr Part_ReadVoice_Return

Part_ReadVoice_HasData:
	ld c, (xsp + 22)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceWord
	ld xwa, (xsp + 16)
	ld (xwa), hl
	ldw (xwa + 2), 0x5
	cpw (xsp + 20), 0x0
	jr ule, Part_ReadVoice_StoreResult

Part_ReadVoice_ProcessLoop:
	ld xbc, (xsp + 16)
	ld wa, (xbc)
	ld (xsp + 2), wa
	ld wa, (xbc + 2)
	ld (xsp + 4), wa
	lda xbc, (xsp + 6)
	ld xwa, (xsp + 16)
	call SeqPart_ReadNextEventByte
	ld a, (xsp + 6)
	cp a, 0x81
	jr nz, Part_ReadVoice_CheckEndMarks
	incw 1, (xsp)

Part_ReadVoice_CheckCount:
	ld wa, (xsp)
	cp wa, (xsp + 20)
	jr c, Part_ReadVoice_ProcessLoop

Part_ReadVoice_StoreResult:
	ld hl, (xsp)

Part_ReadVoice_Return:
	lda xsp, (xsp + 24)
	ret

Part_ReadVoice_CheckEndMarks:
	cp a, 0x82
	jr z, Part_ReadVoice_RestorePos
	cp a, 0x84
	jr nz, Part_ReadVoice_CheckCount

Part_ReadVoice_RestorePos:
	ld xwa, (xsp + 16)
	ld bc, (xsp + 2)
	ld (xwa), bc
	ld bc, (xsp + 4)
	ld (xwa + 2), bc
	jr Part_ReadVoice_StoreResult

SeqPlay_ReconfigureVoices:
	lda xsp, (xsp - 24)
	push xiz
	cpw (0x28a8:16), 0
	scc8 nz, a
	ld (xsp + 18), a
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	cp (xsp + 18), 0x0
	call nz, (SeqChanAssign_InitLoop:24)
	cp (xsp + 18), 0x0
	jr z, SeqPlay_Reconfig_CheckActive
	ld bc, (8998:16)
	ldw wa, 0x32
	ldw de, 0x5f
	calr SeqData_ValidateProcess

SeqPlay_Reconfig_CheckActive:
	cp (xsp + 18), 0x0
	jr z, SeqPlay_Reconfig_CopyPartBits
	ld wa, (7542:16)
	inc 1, wa
	ld (9006:16), wa

SeqPlay_Reconfig_CopyPartBits:
	ldmm16 8982, 8984
	cp (xsp + 18), 0x0
	jrl z, SeqPlay_Reconfig_ScanParts
	lda xbc, (xsp + 24)
	lda xwa, (9332:16)
	ld (xsp + 4), xwa
	lda xwa, (xwa+136:16)
	ld (xsp + 12), xwa
	ld wa, (xwa)
	ld (xbc), wa
	lda xde, (xbc + 2)
	ld xwa, (xsp + 12)
	inc 2, xwa
	ld (xsp + 16), xwa
	ld wa, (xwa)
	ld (xde), wa
	lda xhl, (xsp + 20)
	ld xwa, (xsp + 4)
	lda xix, (xwa+128:16)
	ld wa, (xix)
	ld (xhl), wa
	lda xwa, (xhl + 2)
	ld (xsp + 8), xwa
	lda xiz, (xix + 2)
	ld iy, (xiz)
	ld xwa, (xsp + 8)
	ld (xwa), iy
	ld wa, (xbc)
	ld iy, (xde)
	ld (xix), wa
	ld (xiz), iy
	ld wa, (xbc)
	ld iz, (xde)
	lda xix, (9184:16)
	lda xiy, (xix + 64)
	ld (xiy), wa
	ld (xiy + 2), iz
	ld wa, (xbc)
	ldfr_werp WA, 0xfa
	ld iz, (xde)
	ld xwa, (xsp + 4)
	lda xiy, (xwa+144:16)
	ldto_werp WA, 0xfa
	ld (xiy), wa
	ld (xiy + 2), iz
	ld iy, (xbc)
	ld bc, (xde)
	lda xwa, (xix + 72)
	ld (xwa), iy
	ld (xwa + 2), bc
	ld de, (xhl)
	ld xiy, (xsp + 8)
	ld bc, (xiy)
	ld xwa, (xsp + 12)
	ld (xwa), de
	ld xwa, (xsp + 16)
	ld (xwa), bc
	ld de, (xhl)
	ld bc, (xiy)
	lda xwa, (xix + 68)
	ld (xwa), de
	ld (xwa + 2), bc
	lda xbc, (9016:16)
	ld wa, (7542:16)
	inc 1, wa
	ld	(xbc+128), wa
	ld wa, (7542:16)
	inc 1, wa
	ld	(xbc+136), wa
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x13
	ld bc, 1:i3
	calr SeqPart_ReadEventStream

SeqPlay_Reconfig_ScanParts:
	ld (xsp + 18), 0x1

SeqPlay_Reconfig_PartLoop:
	ld c, (xsp + 18)
	dec 1, c
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqPlay_Reconfig_PartShiftDone
	slaa de

SeqPlay_Reconfig_PartShiftDone:
	and de, (8982:16)
	jr z, SeqPlay_Reconfig_PartLoopNext
	ld l, (xsp + 18)
	cp l, (8990:16)
	jr z, SeqPlay_Reconfig_PartLoopNext
	ld e, c
	extz de
	sla de, 3
	lda xbc, (9016:16)
	ld wa, (7542:16)
	inc 1, wa
	ld	(xbc+de), wa
	ld a, l
	extz wa
	lda xix, (xsp + 24)
	ld e, a
	dec 1, e
	extz de
	ld bc, de
	sla bc, 3
	lda xhl, (9332:16)
	lda	xhl, (xhl+bc)
	ld bc, (xhl)
	ld (xix), bc
	ld bc, (xhl + 2)
	ld (xix + 2), bc
	ld ix, (xix)
	sla de, 2
	lda xhl, (9184:16)
	exts xde
	add xde, xhl
	ld (xde), ix
	ld (xde + 2), bc
	call SeqCh_LoadChannelConfig

SeqPlay_Reconfig_PartLoopNext:
	incm8 1, (xsp + 18)
	cp (xsp + 18), 0x10
	jr ule, SeqPlay_Reconfig_PartLoop
	ld wa, (7544:16)
	add (7542:16), wa
	pop xiz
	lda xsp, (xsp + 24)
	ret

SeqChanAssign_InitLoop:
	dec 8, xsp
	pushw iz
	ld wa, (8998:16)
	cp wa, (9152:16)
	jr nc, SeqChanAssign_CheckEndMark82
	ld (xsp + 2), 0x81
	ld iz, 0:i3
	jr SeqChanAssign_CheckCount

SeqChanAssign_AssignAndIncr:
	lda xbc, (xsp + 2)
	ldw wa, 0x12
	ld de, 1:i3
	calr ToneVoice_AssignChannel
	inc 1, iz

SeqChanAssign_CheckCount:
	ld wa, (9152:16)
	sub wa, (8998:16)
	cp iz, wa
	jr c, SeqChanAssign_AssignAndIncr
	jr SeqChanAssign_CheckEndMark82

SeqChanAssign_ReadEventData:
	lda xix, (xsp + 2)
	lda xwa, (xwa+136:16)
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssign_CopyDataLoop:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqChanAssign_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr ge, SeqChanAssign_ParseParamLen
	ld wa, 6:i3
	call SeqData_SetErrorCode
	jr SeqChanAssign_SetEndAndReturn

SeqChanAssign_ParseParamLen:
	lda xix, (9016:16)
	ld e, l
	extz de
	lda xbc, (xsp + 2)
	cp	(xix+138), 0x81
	jr nz, SeqChanAssign_CheckEndMark
	ldw wa, 0x12
	jr SeqChanAssign_DoAssign

SeqChanAssign_CheckEndMark:
	cp (7522:16), 1
	jr z, SeqChanAssign_CheckSavedPos
	ldw wa, 0x12

SeqChanAssign_DoAssign:
	calr ToneVoice_AssignChannel

SeqChanAssign_ReadEventStream:
	ldw wa, 0x13
	ld bc, 0:i3
	calr SeqPart_ReadEventStream

SeqChanAssign_CheckEndMark82:
	lda xwa, (9016:16)
	cp	(xwa+138), 0x82
	jr nz, SeqChanAssign_ReadEventData

SeqChanAssign_SetEndAndReturn:
	lda xbc, (xsp + 2)
	ld (xbc), 0x82
	ldw wa, 0x12
	ld de, 1:i3
	calr ToneVoice_AssignChannel
	popw iz
	inc 8, xsp
	ret

SeqChanAssign_CompareVoicePos:
	cp wa, hl
	jr nz, SeqChanAssign_AssignFixed12
	ld	a, (xix+139)
	extz wa
	cp (7526:16), wa
	jr nc, SeqChanAssign_ReadEventStream

SeqChanAssign_AssignFixed12:
	ldw wa, 0x12
	jr SeqChanAssign_DoAssign

SeqChanAssign_CheckSavedPos:
	ld wa, (7524:16)
	ld	hl, (xix+136)
	cp wa, hl
	jr ule, SeqChanAssign_CompareVoicePos
	jr SeqChanAssign_ReadEventStream

SeqChanAssignExt_InitLoop:
	lda xsp, (xsp - 32)
	pushw iz
	ld wa, (8998:16)
	cp wa, (9152:16)
	jrl nc, SeqChanAssignExt_CheckEndMark82
	ld (xsp + 26), 0x81
	ldw (xsp + 16), 0x0
	jr SeqChanAssignExt_CheckCount

SeqChanAssignExt_AssignAndIncr:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, 1:i3
	calr ToneVoice_AssignChannel
	incw 1, (xsp + 16)

SeqChanAssignExt_CheckCount:
	ld wa, (9152:16)
	sub wa, (8998:16)
	cp (xsp + 16), wa
	jr c, SeqChanAssignExt_AssignAndIncr
	jr SeqChanAssignExt_CheckEndMark82

SeqChanAssignExt_ReadEventData:
	lda xix, (xsp + 26)
	lda xwa, (xwa+136:16)
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssignExt_CopyDataLoop:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqChanAssignExt_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr ge, SeqChanAssignExt_ParseParamLen
	ldw wa, 0x1a
	call SeqData_SetErrorCode
	jr SeqChanAssignExt_SetEndAndReturn

SeqChanAssignExt_ParseParamLen:
	lda xix, (9016:16)
	cp	(xix+138), 0x81
	jr nz, SeqChanAssignExt_CheckEndMark
	lda xbc, (xsp + 26)
	extz hl
	ldw wa, 0x12
	ld de, hl
	jr SeqChanAssignExt_DoAssign

SeqChanAssignExt_CheckEndMark:
	extz hl
	cp (7522:16), 1
	jr z, SeqChanAssignExt_CheckSavedPos
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, hl

SeqChanAssignExt_DoAssign:
	calr ToneVoice_AssignChannel

SeqChanAssignExt_ReadEventStream:
	ldw wa, 0x13
	ld bc, 0:i3
	calr SeqPart_ReadEventStream

SeqChanAssignExt_CheckEndMark82:
	lda xwa, (9016:16)
	cp	(xwa+138), 0x82
	jr nz, SeqChanAssignExt_ReadEventData

SeqChanAssignExt_SetEndAndReturn:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	ld de, 1:i3
	calr ToneVoice_AssignChannel
	cp (7522:16), 0
	jr nz, SeqChanAssignExt_SwapAndReconfig
	jrl SeqPlay_RestoreReturn

SeqChanAssignExt_ComparePos:
	cp wa, bc
	jr nz, SeqChanAssignExt_AssignFixed12
	ld	a, (xix+139)
	extz wa
	cp (7526:16), wa
	jr nc, SeqChanAssignExt_ReadEventStream

SeqChanAssignExt_AssignFixed12:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, hl
	jr SeqChanAssignExt_DoAssign

SeqChanAssignExt_CheckSavedPos:
	ld wa, (7524:16)
	ld	bc, (xix+136)
	cp wa, bc
	jr ule, SeqChanAssignExt_ComparePos
	jr SeqChanAssignExt_ReadEventStream

SeqChanAssignExt_SwapAndReconfig:
	lda xde, (9016:16)
	ld wa, (7524:16)
	ld	bc, (xde+136)
	cp wa, bc
	jrl c, SeqPlay_RestoreReturn
	cp wa, bc
	jr nz, SeqChanAssignExt_BuildSwapData
	ld	a, (xde+139)
	extz wa
	cp (7526:16), wa
	jrl c, SeqPlay_RestoreReturn

SeqChanAssignExt_BuildSwapData:
	lda xwa, (xsp + 18)
	ld (xsp + 2), xwa
	lda xix, (9332:16)
	lda xde, (xix+128:16)
	ld xwa, (xsp + 2)
	ld bc, (xde)
	ld (xwa+), BC
	ld (xsp + 6), xwa
	lda xbc, (xde + 2)
	ld hl, (xbc)
	ld xwa, (xsp + 6)
	ld (xwa), hl
	lda xhl, (xsp + 22)
	lda xwa, (xix+136:16)
	ld (xsp + 10), xwa
	ld wa, (xwa)
	ld (xhl), wa
	lda xiy, (xhl + 2)
	ld xwa, (xsp + 10)
	inc 2, xwa
	ld (xsp + 14), xwa
	ld iz, (xwa)
	ld (xiy), iz
	ld wa, (xhl)
	ld (xde), wa
	ld (xbc), iz
	ld de, (xhl)
	ld bc, (xiy)
	lda xwa, (xix+144:16)
	ld (xwa), de
	ld (xwa + 2), bc
	ld ix, (xhl)
	ld de, (xiy)
	lda xbc, (9184:16)
	lda xwa, (xbc + 64)
	ld (xwa), ix
	ld (xwa + 2), de
	ld hl, (xhl)
	ld de, (xiy)
	lda xwa, (xbc + 72)
	ld (xwa), hl
	ld (xwa + 2), de
	ld xiy, (xsp + 2)
	ld hl, (xiy)
	ld xix, (xsp + 6)
	ld de, (xix)
	ld xwa, (xsp + 10)
	ld (xwa), hl
	ld xwa, (xsp + 14)
	ld (xwa), de
	ld hl, (xiy)
	ld de, (xix)
	lda xwa, (xbc + 68)
	ld (xwa), hl
	ld (xwa + 2), de
	ldw wa, 0x13
	ld bc, 0:i3
	jr SeqChanAssign3_ReadEventStream

SeqChanAssign3_ReadEventData:
	lda xix, (xsp + 26)
	lda xwa, (xwa+136:16)
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssign3_CopyDataLoop:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqChanAssign3_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr ge, SeqChanAssign3_ParseParamLen
	ldw wa, 0x1b
	call SeqData_SetErrorCode
	jr SeqChanAssign3_SetEndAndReturn

SeqChanAssign3_ParseParamLen:
	lda xix, (9016:16)
	ld e, l
	extz de
	cp	(xix+138), 0x81
	jr nz, SeqChanAssign3_CheckEndMark
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	jr SeqChanAssign3_DoAssign

SeqChanAssign3_CheckEndMark:
	lda xbc, (xsp + 26)
	cp (7522:16), 1
	jr z, SeqChanAssign3_CheckSavedPos
	ldw wa, 0x12

SeqChanAssign3_DoAssign:
	calr ToneVoice_AssignChannel

SeqChanAssign3_ReadAndProcess:
	ldw wa, 0x13
	ld bc, 0:i3

SeqChanAssign3_ReadEventStream:
	calr SeqPart_ReadEventStream
	lda xwa, (9016:16)
	cp	(xwa+138), 0x82
	jr nz, SeqChanAssign3_ReadEventData

SeqChanAssign3_SetEndAndReturn:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	ld de, 1:i3
	calr ToneVoice_AssignChannel

SeqPlay_RestoreReturn:
	popw iz
	lda xsp, (xsp + 32)
	ret

SeqChanAssign3_ComparePos:
	cp wa, hl
	jr nz, SeqChanAssign3_AssignFixed12
	ld	a, (xix+139)
	extz wa
	cp (7526:16), wa
	jr nc, SeqChanAssign3_ReadAndProcess

SeqChanAssign3_AssignFixed12:
	ldw wa, 0x12
	jr SeqChanAssign3_DoAssign

SeqChanAssign3_CheckSavedPos:
	ld wa, (7524:16)
	ld	hl, (xix+136)
	cp wa, hl
	jr ule, SeqChanAssign3_ComparePos
	jr SeqChanAssign3_ReadAndProcess

SeqCh_CountEventsAndCalcPos:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	ld iz, 0:i3
	lda xde, (xsp + 2)
	lda xbc, (9468:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld de, (xde)
	lda xbc, (9252:16)
	ld (xbc), de
	ld (xbc + 2), wa

SeqCh_LoadProcessEvent:
	ldw wa, 0x12
	call SeqCh_LoadChannelConfig
	ld a, (9154:16)
	cp a, 0x82
	jr z, SeqChCount_ReturnResult
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr ge, SeqChCount_AccumulateLength
	ld wa, 7:i3
	call SeqData_SetErrorCode
	jr SeqCh_LoadProcessEvent

SeqChCount_AccumulateLength:
	add iz, hl
	cp iz, 0xfb
	jr c, SeqCh_LoadProcessEvent
	sub iz, 0xfb
	ld xwa, (xsp + 6)
	incw 1, (xwa)
	jr SeqCh_LoadProcessEvent

SeqChCount_ReturnResult:
	ld wa, iz
	ld w, 0x0:opc
	ld c, a
	extz bc
	ld xwa, (xsp + 6)
	ld (xwa + 2), bc
	popw iz
	inc 8, xsp
	ret

PartCtrl_SwapIndexedEntries:
	lda xsp, (xsp - 20)
	pushw iz
	ld (xsp + 16), de
	ld (xsp + 18), bc
	ld (xsp + 20), a
	cpw (xsp + 18), 0x0
	jr nz, PartSwap_LoadSourceData
	cpw (xsp + 16), 0x0
	jrl z, PartSwap_ReturnZero

PartSwap_LoadSourceData:
	lda xbc, (xsp + 4)
	lda xde, (0x282c:16)
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 2)
	ld (xbc + 2), wa
	ld c, (xsp + 20)
	extz bc
	ld wa, 0:i3
	call Part_ReadWord_Indexed
	ld (xsp + 12), hl
	ld c, (xsp + 20)
	extz bc
	ld wa, 0:i3
	call Part_ReadByte_Indexed
	lda xwa, (xsp + 12)
	lda xbc, (xwa + 2)
	ld (xbc), hl
	lda xde, (xsp + 8)
	ld wa, (xwa)
	ld (xde), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	ld iz, 0:i3
	cpw (xsp + 18), 0x0
	jr ule, PartSwap_CalcRemaining

PartSwap_LinkVoiceLoop:
	ld wa, (xsp + 8)
	call Part_LinkVoiceToChain
	cp hl, 0xffff
	jr nz, PartSwap_StoreAndContinue
	ldw wa, 0x66
	call SeqData_SetErrorCode
	ld wa, (xsp + 12)
	jr PartSwap_HandleLinkError

PartSwap_StoreAndContinue:
	ld (xsp + 8), hl
	inc 1, iz
	cp iz, (xsp + 18)
	jr c, PartSwap_LinkVoiceLoop

PartSwap_CalcRemaining:
	ld iz, (xsp + 14)
	add iz, (xsp + 16)
	lda xbc, (xsp + 8)
	cp iz, 0x100
	jr c, PartSwap_SetCountDirect
	ld wa, (xbc)
	call Part_LinkVoiceToChain
	cp hl, 0xffff
	jr nz, PartSwap_StoreOverflow
	ldw wa, 0x67
	call SeqData_SetErrorCode
	ld wa, (xsp + 12)

PartSwap_HandleLinkError:
	calr PartCtrl_ReleaseVoiceChain
	ldw hl, 0xffff
	jrl PartSwap_Return

PartSwap_StoreOverflow:
	lda xbc, (xsp + 8)
	ld (xbc), hl
	ld wa, iz
	sub wa, 0xfb
	extz wa
	ld (xbc + 2), wa
	jr PartSwap_WriteIndexedData

PartSwap_SetCountDirect:
	ldto_berp A, 0xf8
	extz wa
	ld (xbc + 2), wa

PartSwap_WriteIndexedData:
	ld c, (xsp + 20)
	extz bc
	ld de, (xsp + 8)
	ld wa, 0:i3
	call Part_WriteWord_Indexed
	ld c, (xsp + 20)
	extz bc
	ld de, (xsp + 10)
	ld wa, 0:i3
	call Part_WriteByte_Indexed
	ld (xsp + 2), 0x0

PartSwap_CompareAndUpdate:
	lda xbc, (xsp + 12)
	lda xde, (xsp + 4)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, PartSwap_ReadAndWriteBytes
	ld wa, (xde + 2)
	cp wa, (xbc + 2)
	jr nz, PartSwap_ReadAndWriteBytes
	lda xhl, (0x282c:16)
	lda xde, (xsp + 8)
	ld wa, (xde)
	ld (xhl), wa
	ld wa, (xde + 2)
	ld (xhl + 2), wa
	ld (xsp + 2), 0x1

PartSwap_ReadAndWriteBytes:
	ld wa, (xbc)
	ld bc, (xbc + 2)
	call PartCtrl_ReadByteExtended
	lda xbc, (xsp + 8)
	extz hl
	ld wa, (xbc)
	ld bc, (xbc + 2)
	ld de, hl
	call PartCtrl_WriteByte_ZeroExtended
	lda xwa, (xsp + 12)
	lda xbc, (xwa + 2)
	call BmDrEdit_DecrementAndValidateCounter
	lda xwa, (xsp + 8)
	lda xbc, (xwa + 2)
	call BmDrEdit_DecrementAndValidateCounter
	cp (xsp + 2), 0x0
	jr z, PartSwap_CompareAndUpdate

PartSwap_ReturnZero:
	ld hl, 0:i3

PartSwap_Return:
	popw iz
	lda xsp, (xsp + 20)
	ret

PartCtrl_ReleaseVoiceChain:
	push xiz
	ld iz, wa
	ld wa, iz
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartRelease_Return
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartRelease_Return

PartRelease_FreeLoop:
	ldto_werp IZ, 0xfa
	ldto_werp WA, 0xfa
	ld bc, 0:i3
	call PartCtrl_SetClearBit7
	ldto_werp WA, 0xfa
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ld wa, iz
	call PartCtrl_AppendToFreeList
	cp_erpw 0xfa, 0xff, 0xff
	jr nz, PartRelease_FreeLoop

PartRelease_Return:
	pop xiz
	ret

SeqPlay_ReallocateAndReconfig:
	lda xsp, (xsp - 28)
	push xiz
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call Audio_CheckSubsystemReady
	cpw (0x28a8:16), 0
	jrl z, SeqPlay_PendingCh_Return
	calr SeqChanAssignExt_InitLoop
	call PartCtrl_DeallocAndWriteEnd
	cp (7522:16), 1
	call z, (SeqPlay_ScanAndStoreChannelPos:24)
	call SeqPart_ScanAndBuildVoiceData
	lda xwa, (xsp + 20)
	calr SeqCh_CountEventsAndCalcPos
	lda xde, (xsp + 20)
	cpw (xde), 0x0
	jr nz, SeqRealloc_SetupSwapData
	cpw (xde + 2), 0x0
	jrl z, SeqPlay_PendingCh_ClearAndDealloc

SeqRealloc_SetupSwapData:
	ldmi16 (xsp + 4), 0x231a
	ld a, (xsp + 4)
	extz wa
	ld (xsp + 6), wa
	lda xhl, (xsp + 16)
	ld wa, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 3
	lda xiz, (9332:16)
	lda	xbc, (xiz+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xix, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xix), wa
	lda xiy, (xsp + 12)
	lda xbc, (xiz+136:16)
	ld wa, (xbc)
	ld (xiy), wa
	ld wa, (xbc + 2)
	ld (xiy + 2), wa
	lda xiy, (xsp + 8)
	ld wa, (xhl)
	ld (xiy), wa
	lda xbc, (xiy + 2)
	ld wa, (xix)
	ld (xbc), wa
	lda xhl, (0x282c:16)
	ld wa, (xiy)
	ld (xhl), wa
	ld wa, (xbc)
	ld (xhl + 2), wa
	ld bc, (xde)
	ld de, (xde + 2)
	ld wa, (xsp + 6)
	calr PartCtrl_SwapIndexedEntries
	lda xbc, (xsp + 8)
	lda xde, (0x282c:16)
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 2)
	ld (xbc + 2), wa
	ld c, (xsp + 4)
	extz bc
	ld wa, 0:i3
	call Part_ReadWord_Indexed
	ld (xsp + 20), hl
	ld c, (xsp + 4)
	extz bc
	ld wa, 0:i3
	call Part_ReadByte_Indexed
	ld (xsp + 22), hl
	lda xwa, (xsp + 8)
	ld hl, (xwa)
	ld bc, (xwa + 2)
	lda xde, (9184:16)
	lda xwa, (xde + 64)
	ld (xwa), hl
	ld (xwa + 2), bc
	lda xwa, (xsp + 12)
	ld hl, (xwa)
	ld bc, (xwa + 2)
	lda xwa, (xde + 68)
	ld (xwa), hl
	ld (xwa + 2), bc
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 16)
	ld hl, (xbc)
	ld bc, (xbc + 2)
	dec 1, a
	extz wa
	sla wa, 2
	exts xwa
	add xwa, xde
	ld (xwa), hl
	ld (xwa + 2), bc
	lda xwa, (9016:16)
	ldw	(xwa+128), 0x0000
	ldw	(xwa+136), 0x0000
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x12
	ld bc, 0:i3

SeqPlay_ReadAndProcessEvents:
	calr SeqPart_ReadEventStream

SeqPlay_CheckEventTiming:
	lda xix, (9016:16)
	lda xhl, (xix+128:16)
	ld	wa, (xix+136)
	ld de, (xhl)
	lda xbc, (xsp + 24)
	cp de, wa
	jr c, SeqPlay_ReadEvents_TimingMatch
	cp wa, de
	jr nz, SeqPlay_ProcessPendingChannels
	ld	a, (xix+131)
	cp	a, (xix+139)
	jr nc, SeqPlay_ProcessPendingChannels

SeqPlay_ReadEvents_TimingMatch:
	ld xde, xbc
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqPlay_ReadEvents_CopyDataLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xbc, (xix+128:16)
	ld iz, wa
	extz xiz
	add xiz, xbc
	ldto_berp C, 0xe2
	extz bc
	ld a, (xiz)
	ld	(xiy+bc), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqPlay_ReadEvents_CopyDataLoop
	ld a, (xde)
	cp a, 0x82
	jr nz, SeqPlay_ReadEvents_NotEndMark
	ldw (xhl), 0xfff0
	jr SeqPlay_CheckEventTiming

SeqPlay_ReadEvents_NotEndMark:
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr le, SeqPlay_ReadEvents_ErrorBadParam
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 24)
	extz hl
	ld de, hl
	calr ToneVoice_AssignChannel
	jr SeqPlay_ReadEvents_ReloadCfg

SeqPlay_ReadEvents_ErrorBadParam:
	ldw wa, 0xa
	call SeqData_SetErrorCode

SeqPlay_ReadEvents_ReloadCfg:
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	jrl SeqPlay_CheckEventTiming

SeqPlay_ProcessPendingChannels:
	ld xde, xbc
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqPlay_PendingCh_CopyDataLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xbc, (xix+136:16)
	ld iz, wa
	extz xiz
	add xiz, xbc
	ldto_berp C, 0xe2
	extz bc
	ld a, (xiz)
	ld	(xiy+bc), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqPlay_PendingCh_CopyDataLoop
	ld a, (xde)
	cp a, 0x82
	jrl nz, SeqPlay_PendingCh_AssignVoice
	cpw (xhl), 0xfff0
	jr nz, SeqPlay_PendingCh_SetPart1
	ld c, (xsp + 4)
	extz bc
	lda xhl, (xsp + 20)
	ld a, c
	dec 1, a
	extz wa
	sla wa, 2
	lda xde, (9184:16)
	lda	xde, (xde+wa)
	ld wa, (xde)
	ld (xhl), wa
	ld wa, (xde + 2)
	ld (xhl + 2), wa
	ld de, (xhl)
	ld wa, 0:i3
	call Part_WriteWord_Indexed
	ld c, (xsp + 4)
	extz bc
	ld de, (xsp + 22)
	ld wa, 0:i3
	call Part_WriteByte_Indexed
	lda xbc, (xsp + 24)
	ld (xbc), 0x82
	ld a, (xsp + 4)
	extz wa
	ld de, 1:i3
	calr ToneVoice_AssignChannel

SeqPlay_PendingCh_SetPart1:
	ld (xsp + 4), 0x1

SeqPlay_PendingCh_ActivateLoop:
	ld a, (xsp + 4)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_PendingCh_ActivateShift
	slaa bc

SeqPlay_PendingCh_ActivateShift:
	and bc, (0x28a8:16)
	jr z, SeqPlay_PendingCh_ActivateNext
	ld a, (xsp + 4)
	extz wa
	ld bc, 1:i3
	call Chan_SetActiveBit

SeqPlay_PendingCh_ActivateNext:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr ule, SeqPlay_PendingCh_ActivateLoop

SeqPlay_PendingCh_ClearAndDealloc:
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	ldw (0x28aa:16), 0

SeqPlay_PendingCh_Return:
	call Part_DeallocVoices1And2
	pop xiz
	lda xsp, (xsp + 28)
	ret

SeqPlay_PendingCh_AssignVoice:
	extz wa
	call SeqEvent_GetParamLength
	cp hl, 0:i3
	jr le, SeqPlay_PendingCh_ErrorBadParam
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 24)
	extz hl
	ld de, hl
	calr ToneVoice_AssignChannel
	jr SeqPlay_PendingCh_ReadMore

SeqPlay_PendingCh_ErrorBadParam:
	ldw wa, 0xb
	call SeqData_SetErrorCode

SeqPlay_PendingCh_ReadMore:
	ldw wa, 0x12
	ld bc, 0:i3
	jrl SeqPlay_ReadAndProcessEvents

SeqData_ValidateProcess:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 6), e
	ld (xsp + 8), bc
	ld (xsp + 10), a
	ld a, (8182:16)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl z, SeqData_Validate_Return

SeqData_Validate_SlotLoop:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda	xhl, (xbc+wa)
	ld a, (xhl + 9)
	ld c, a
	extz bc
	cp (xsp + 10), 0x32
	jr z, SeqData_Validate_MatchFound
	inc 1, bc
	ld a, (xsp + 10)
	extz wa
	cp wa, bc
	jr nz, SeqData_Validate_ErrorCode9

SeqData_Validate_MatchFound:
	ld ix, (xsp + 8)
	ld a, (xsp + 6)
	ld c, (xhl + 1)
	cp c, a
	jr ule, SeqData_Validate_ComputeOffset
	dec 1, ix
	add a, 0x60

SeqData_Validate_ComputeOffset:
	sub a, c
	lda xde, (xsp + 2)
	ld (xde), a
	ld wa, ix
	sub wa, (xhl + 4)
	ld (xde + 1), a
	cp a, 0:i3
	jr nz, SeqPlay_DispatchNoteParams
	cp (xde), 0x2
	jr nc, SeqPlay_DispatchNoteParams
	ld (xde), 0x2

SeqPlay_DispatchNoteParams:
	ld c, (xhl + 8)
	extz bc
	ld wa, (xhl + 6)
	call PartCtrl_WriteBytePair
	jr SeqData_Validate_NextSlot

SeqData_Validate_ErrorCode9:
	ldw wa, 0x9
	call SeqData_SetErrorCode

SeqData_Validate_NextSlot:
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8197:16)
	ld	a, (xwa+bc)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl nz, SeqData_Validate_SlotLoop

SeqData_Validate_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

SeqPlay_PrepareDrumVoice:
	dec 8, xsp
	pushw_erp 0xfa
	ld wa, 0:i3
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, Part_FindAndAssignDrumVoice
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_PrepareDrum_ShiftDone
	slaa bc

SeqPlay_PrepareDrum_ShiftDone:
	and bc, (0x28aa:16)
	jr z, Part_FindAndAssignDrumVoice
	lda xwa, (xsp + 2)
	ld (xwa), 0xb0
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x48
	ld (xwa + 3), 0x3
	ld c, (0xfc5d:16)
	ld (xwa + 4), c
	ld (xwa + 5), 0x7
	calr Part_CheckAndSetModifiedFlags
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 2)
	ld de, 6:i3
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xfb
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_FindAndAssignDrumVoice:
	ld wa, 0:i3
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, Part_SendVoiceStatusLoop
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartVoiceStatus_ShiftDone
	slaa bc

PartVoiceStatus_ShiftDone:
	and bc, (0x28aa:16)
	jr z, Part_SendVoiceStatusLoop
	lda xbc, (xsp + 2)
	ld (xbc), 0xd3
	ld (xbc + 1), 0x0
	lda xde, (xbc + 2)
	ld a, (MIDI_CC_MODWHEEL_VALUE:16)
	ld (xde), a
	res 7, a
	ld (xde), a
	ldto_berp A, 0xfb
	extz wa
	ld de, 3:i3
	calr ToneVoice_AssignChannel
	lda xbc, (xsp + 2)
	ld (xbc), 0x80
	ld (xbc + 1), 0x0
	lda xwa, (0xfc5a:16)
	ld d, (xwa + 8)
	ld e, d
	res 7, e
	ld (xbc + 2), e
	lda xhl, (xbc + 3)
	ld e, (xwa + 9)
	ld a, e
	ld (xhl), a
	add e, e
	ld a, e
	ld (xhl), e
	bit 7, d
	jr z, PartVoiceStatus_AssignTempo
	inc 1, a
	ld (xhl), a

PartVoiceStatus_AssignTempo:
	ldto_berp A, 0xfb
	extz wa
	ld de, 4:i3
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xfb
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_SendVoiceStatusLoop:
	ldib_erp 0xfb, 1

PartVoiceStatus_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartVoiceStatus_PartShiftDone
	slaa bc

PartVoiceStatus_PartShiftDone:
	and bc, (0x28a8:16)
	jr z, PartVoiceStatus_PartLoopNext
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceByte
	cp l, 1:i3
	jr z, Part_BuildAndSendVoiceCCEvent
	cp l, 0:i3
	jr z, Part_BuildAndSendVoiceCCEvent
	cp l, 2:i3
	jr nz, PartVoiceStatus_PartLoopNext

Part_BuildAndSendVoiceCCEvent:
	lda xwa, (xsp + 2)
	ld (xwa), 0xb0
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x9a
	ldto_berp C, 0xfb
	inc 3, c
	ld (xwa + 3), c
	ldmi16 (xwa + 4), 0xc5a8
	ld (xwa + 5), 0x7f
	calr Part_CheckAndSetModifiedFlags
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 2)
	ld de, 6:i3
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xfb
	extz wa
	call SeqEvent_CreateWithChannelValidation

PartVoiceStatus_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartVoiceStatus_PartLoop
	popw_erp 0xfa
	inc 8, xsp
	ret

SeqPlay_ActivateAllChannels:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1

SeqActivate_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqActivate_PartShiftDone
	slaa bc

SeqActivate_PartShiftDone:
	and bc, (0x28a8:16)
	jr z, SeqActivate_PartLoopNext
	ldto_berp A, 0xfb
	extz wa
	ld bc, 1:i3
	call Chan_SetActiveBit

SeqActivate_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqActivate_PartLoop
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	ldw (0x28aa:16), 0
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call Audio_CheckSubsystemReady
	popw_erp 0xfa
	ret

SeqPlay_CheckDrumAndStart:
	cp (7570:16), 1
	jr nz, SeqPlayCheck_ReturnFFFF
	cpw (0x28a8:16), 0
	jr z, SeqPlayCheck_ReturnFFFF
	ld a, (8986:16)
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqPlay_StartPlayback
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlayCheck_DrumShiftDone
	slaa bc

SeqPlayCheck_DrumShiftDone:
	and bc, (8982:16)
	jr nz, SeqPlay_StartPlayback

SeqPlayCheck_ReturnFFFF:
	ldw hl, 0xffff
	ret

SeqPlay_StartPlayback:
	call SeqBuffer_ClearAndInitIteration
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqPlayCheck_SetSecondChannel
	calr SeqPlay_ScanAndStoreChannelPos
	ld (7522:16), 0
	calr SeqPlay_InitializePlayback

SeqPlayCheck_SetSecondChannel:
	ld (7522:16), 1
	ld wa, (SEQ_BEAT_COUNT:16)
	add wa, (7544:16)
	ld (7524:16), wa
	ld a, (SEQ_BEAT_TICK:16)
	extz wa
	ld (7526:16), wa
	ld hl, 0:i3
	ret

SeqPlay_ScanAndStoreChannelPos:
	lda xsp, (xsp - 20)
	push xiz
	ld iz, 0:i3
	ld a, (8986:16)
	ldfr_berp A, 0xfb
	extz wa
	lda xhl, (xsp + 12)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	lda xbc, (xsp + 8)
	ld wa, (xhl)
	ld (xbc), wa
	ld wa, (xde)
	ld (xbc + 2), wa
	lda xbc, (xsp + 4)
	ld wa, (xhl)
	ld (xbc), wa
	ld wa, (xde)
	ld (xbc + 2), wa
	cpw (7544:16), 0
	jr ule, SeqPlay_StoreChannelPosition

SeqScanPos_ReadNextEvent:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 16)
	call SeqPart_ReadNextEventByte
	lda xbc, (xsp + 16)
	ld a, (xbc)
	cp a, 0x81
	jr nz, SeqScanPos_CheckEndMark
	lda xwa, (xsp + 4)
	ld de, 1:i3
	call Part_CopyBytesToVoiceBlock
	inc 1, iz
	jr SeqScanPos_ComparePosition

SeqScanPos_CheckEndMark:
	cp a, 0x82
	jr z, SeqPlay_StoreChannelPosition

SeqScanPos_ComparePosition:
	cp iz, (7544:16)
	jr c, SeqScanPos_ReadNextEvent

SeqPlay_StoreChannelPosition:
	ldto_berp C, 0xfb
	extz bc
	lda xde, (xsp + 4)
	ld a, c
	ld iy, (xde)
	ld ix, (xde + 2)
	dec 1, a
	extz wa
	sla wa, 2
	lda xhl, (9184:16)
	exts xwa
	add xwa, xhl
	ld (xwa), iy
	ld (xwa + 2), ix
	ld a, (xsp + 16)
	cp a, 0x82
	jr z, SeqScanPos_WriteEndMarker
	cp a, 0x84
	jr nz, SeqScanPos_CheckEndOrContinue

SeqScanPos_WriteEndMarker:
	ld de, (xde)
	ld wa, 0:i3
	call Part_WriteWord_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 6)
	ld wa, 0:i3
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	ld de, 1:i3
	jr SeqScanPos_CopyAndSteal

SeqScanPos_ReadAndCopyEvent:
	lda xwa, (xsp + 8)
	call SeqPart_ReadNextEventByte
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	extz hl
	ld de, hl
	call Part_CopyBytesToVoiceBlock

SeqScanPos_CheckEndOrContinue:
	lda xbc, (xsp + 16)
	ld a, (xbc)
	cp a, 0x82
	jr z, SeqScanPos_WriteIndexedData
	cp a, 0x84
	jr nz, SeqScanPos_ReadAndCopyEvent

SeqScanPos_WriteIndexedData:
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 4)
	ld wa, 0:i3
	call Part_WriteWord_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 6)
	ld wa, 0:i3
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	ld de, 1:i3

SeqScanPos_CopyAndSteal:
	call Part_CopyBytesToVoiceBlock
	ld wa, (xsp + 4)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqScanPos_Return
	call Part_StealAndReallocVoices
	ld wa, (xsp + 4)
	ldw bc, 0xffff
	call PartCtrl_WriteWord

SeqScanPos_Return:
	pop xiz
	lda xsp, (xsp + 20)
	ret

Part_CheckAndSetModifiedFlags:
	lda xde, (xwa + 2)
	ld c, (xde)
	bit 7, c
	jr z, PartModFlags_CheckField4
	res 7, c
	ld (xde), c
	setm 2, (xwa)

PartModFlags_CheckField4:
	lda xde, (xwa + 4)
	ld c, (xde)
	bit 7, c
	jr z, PartModFlags_CheckField5
	res 7, c
	ld (xde), c
	setm 0, (xwa)

PartModFlags_CheckField5:
	lda xde, (xwa + 5)
	ld c, (xde)
	bit 7, c
	ret z
	res 7, c
	ld (xde), c
	setm 1, (xwa)
	ret

SeqBuf_WriteMidiEvent:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld xiz, xwa
	ld a, (xiz)
	and a, 0xf0
	cp a, 0x90
	jr nz, SeqBufMidi_HandleNonNoteOn
	cp (7558:16), 0
	call nz, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call lt, (SeqBuf_FlushAndReinit_NoteEvents:24)
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	ld (7556:16), 1
	jr SeqBufMidi_Return

SeqBufMidi_HandleNonNoteOn:
	cp (7556:16), 0
	call nz, (SeqBuf_FlushAndReinit_NoteEvents:24)
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call lt, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	ld (7558:16), 1

SeqBufMidi_Return:
	pop xiz
	inc 2, xsp
	ret

SeqBuf_WriteMidiEventDirect:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld xiz, xwa
	ld a, (xiz)
	and a, 0xf0
	cp a, 0x90
	jr nz, SeqBufDirect_HandleNonNoteOn
	cp (7558:16), 0
	call nz, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call lt, (SeqBuf_FlushAndReinit_NoteEvents:24)
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_NoteEvents
	jr SeqBufDirect_Return

SeqBufDirect_HandleNonNoteOn:
	cp (7556:16), 0
	call nz, (SeqBuf_FlushAndReinit_NoteEvents:24)
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call lt, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_VoiceCCEvents

SeqBufDirect_Return:
	pop xiz
	inc 2, xsp
	ret

SeqBuf_FlushAndReinit_NoteEvents:
	call SeqBuf_SaveWritePos
	call AccNoteOn_ChannelDispatch
	call SeqBuf_Init
	ld (7556:16), 0
	ret

SeqBuf_FlushAndReinit_VoiceCCEvents:
	call SeqBuf_SaveWritePos
	call Audio_ReinitAndProcessEvents
	call SeqBuf_Init
	call SwbtWr_ReinitBothBanks
	ld (7558:16), 0
	ret

SeqTimer_SetPlaybackFlags:
	ei 6
	set 1, (1056:16)
	set 2, (1056:16)
	ld a, (1054:16)
	bit 0, a
	jr z, SeqTimerFlags_CheckSysFlag
	set 1, a
	set 2, a
	ld (1054:16), a

SeqTimerFlags_CheckSysFlag:
	ld a, (SEQ_TRANSPORT_STATE:16)
	bit 0, a
	jr z, SeqTimerFlags_Done
	set 1, a
	set 2, a
	ld (SEQ_TRANSPORT_STATE:16), a

SeqTimerFlags_Done:
	ei 0
	ret

Part_SendVoiceOff_AllParts:
	dec 6, xsp
	pushw_erp 0xfa
	cpw (0xf19e:16), 0
	jr z, PartVoiceOff_Return
	ldib_erp 0xfb, 1

PartVoiceOff_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartVoiceOff_PartShiftDone
	slaa bc

PartVoiceOff_PartShiftDone:
	ld wa, (0xf19e:16)
	and wa, bc
	jr z, SeqBuf_IncrAndLoop16
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceByte
	cp l, 0xf
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0x10
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0xd
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0xe
	jr z, SeqBuf_IncrAndLoop16
	lda xwa, (xsp + 2)
	ld (xwa), 0xd3
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x7f
	ldto_berp C, 0xfb
	dec 1, c
	ld (xwa + 3), c
	ld bc, 4:i3
	calr SeqBuf_WriteMidiEvent

SeqBuf_IncrAndLoop16:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartVoiceOff_PartLoop

PartVoiceOff_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

VoiceAlloc_ScoopDisplayProcess:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 4), 0x0

VoiceAlloc_FindPartLoop:
	ld bc, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, VoiceAlloc_FindPartShiftDone
	slaa bc

VoiceAlloc_FindPartShiftDone:
	and bc, (3407:16)
	jr z, VoiceAlloc_FindPartNext
	ld a, (xsp + 4)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xd
	jr z, VoiceAlloc_StartProcessing
	ld a, (3431:16)
	cp a, 4:i3
	call nz, (SeqBuf_FlushAndReinit_NoteEvents:24)
	jrl VoiceAlloc_Return

VoiceAlloc_FindPartNext:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr c, VoiceAlloc_FindPartLoop

VoiceAlloc_StartProcessing:
	ld (xsp + 14), 0x0

VoiceAlloc_ReadNextByte:
	call SeqBuf_ReadByte
	cp hl, 0:i3
	jr ge, VoiceAlloc_StoreAndReadFields

VoiceAlloc_SortAndDisplay:
	lda xbc, (xsp + 14)
	cp (xbc), 0x0
	jrl z, VoiceAlloc_DisplayAndApply
	ld (xsp + 4), 0x0
	ld (xsp + 10), xbc
	ld (xsp + 6), xbc
	ld hl, 0:i3
	jrl VoiceAlloc_SortOuterLoop

VoiceAlloc_StoreAndReadFields:
	ld (xsp + 30), l
	ld (xsp + 4), 0x1

VoiceAlloc_ReadFieldLoop:
	call SeqBuf_ReadByte
	lda xbc, (xsp + 30)
	cp hl, 0:i3
	jr lt, VoiceAlloc_ProcessEntry
	ld a, (xsp + 4)
	extz wa
	ld	(xbc+wa), l
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x5
	jr c, VoiceAlloc_ReadFieldLoop

VoiceAlloc_ProcessEntry:
	ld (xsp + 10), xbc
	inc 1, xbc
	cp (xbc), 0x7f
	jr z, VoiceAlloc_CheckEndMarker
	lda xde, (xsp + 14)
	ld l, (xde)
	extz hl
	inc 1, hl
	ld xwa, (xsp + 10)
	ld a, (xwa + 2)
	ld	(xde+hl), a
	incm8 1, (xde)

VoiceAlloc_CheckEndMarker:
	ld c, (xbc)
	cp c, 0x7f
	jr z, SeqPlay_HandleEndOfData
	ld xwa, (xsp + 10)
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_HandleEndOfData
	ld (xsp + 14), 0x0
	call SeqBuf_Init
	jr VoiceAlloc_SortAndDisplay

SeqPlay_HandleEndOfData:
	cp c, 0x7f
	jrl nz, VoiceAlloc_ReadNextByte
	calr BitMapOut_PrepareAndDisplay
	call SeqBuf_Init
	jrl VoiceAlloc_Return

VoiceAlloc_SortInnerSetup:
	ld d, (xsp + 4)
	inc 1, d
	ld wa, hl
	inc 1, wa
	lda	xiy, (xbc+wa)
	ldfr_berp D, 0xf0
	extz ix
	jr VoiceAlloc_SortInnerLoop

VoiceAlloc_SortCompareSwap:
	ld wa, ix
	inc 1, wa
	lda	xiz, (xbc+wa)
	ld a, (xiz)
	ld e, (xiy)
	cp e, a
	jr nc, VoiceAlloc_SortInnerNext
	ld (xiy), a
	ld (xiz), e

VoiceAlloc_SortInnerNext:
	inc 1, d
	inc 1, ix

VoiceAlloc_SortInnerLoop:
	ld xwa, (xsp + 6)
	ld a, (xwa)
	dec 1, a
	cp d, a
	jr ule, VoiceAlloc_SortCompareSwap
	incm8 1, (xsp + 4)
	inc 1, hl

VoiceAlloc_SortOuterLoop:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	dec 1, a
	cp (xsp + 4), a
	jr c, VoiceAlloc_SortInnerSetup

VoiceAlloc_DisplayAndApply:
	lda xwa, (xsp + 26)
	ld de, 2:i3
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 26)
	mrib4 0x80, 0x19, 0xdf, 0xce
	mrdb5 0x88, 0x01, 0x19, 0xe0, 0xce
	mrdb5 0x88, 0x02, 0x19, 0xe1, 0xce
	mrdb5 0x88, 0x03, 0x19, 0xde, 0xce
	ld a, (3431:16)
	cp a, 4:i3
	jr z, VoiceAlloc_WriteIndexAndApply
	lda xix, (0xcee5:16)
	lda xhl, (xsp + 14)
	ld a, (xhl)
	ld (xix), a
	ld (xsp + 4), 0x0
	ld xiy, xhl
	ld de, 1:i3
	ld a, (xsp + 4)
	cp a, (xiy)
	jr nc, VoiceAlloc_InitAndFind

VoiceAlloc_CopyFieldLoop:
	ld wa, de
	ldw bc, 0xffff
	add wa, bc
	inc 1, wa
	ld bc, de
	extz xbc
	add xbc, xix
	ld	a, (xhl+wa)
	ld (xbc), a
	incm8 1, (xsp + 4)
	inc 1, de
	ld a, (xsp + 4)
	cp a, (xiy)
	jr c, VoiceAlloc_CopyFieldLoop

VoiceAlloc_InitAndFind:
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch

VoiceAlloc_WriteIndexAndApply:
	lda xwa, (xsp + 26)
	mrib4 0x80, 0x19, 0x42, 0x8d
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8d
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8d
	mrdb5 0x88, 0x03, 0x19, 0xde, 0xce
	call BitMapOut_CheckDiskAndApply

VoiceAlloc_Return:
	pop xiz
	lda xsp, (xsp + 34)
	ret

Voice_AllocateFromSeqData:
	lda xsp, (xsp - 42)
	push xiz
	ld (xsp + 44), a
	cp (xsp + 44), 0x1
	jr z, VoiceAlloc_SetupChannelLookup
	cp (xsp + 44), 0x0
	jr z, VoiceAlloc_SetupChannelLookup
	ldw wa, 0x11
	calr SeqData_SetErrorCode

VoiceAlloc_SetupChannelLookup:
	ldmi16 (xsp + 4), 0x231c
	cp (xsp + 4), 0xff
	jrl z, BitMapOut_CompletionJoin
	cp (xsp + 44), 0x0
	jr nz, VoiceAlloc_ComputeAddress
	ld (xsp + 4), 0x14

VoiceAlloc_ComputeAddress:
	ld a, (xsp + 4)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	exts xwa
	add xwa, xbc
	ld (xsp + 8), xwa
	cp (xwa + 2), 0x90
	jr z, VoiceAlloc_CheckNoteType
	ld l, 0xff:opc
	jrl VoiceAlloc_ReturnFF

VoiceAlloc_CheckNoteType:
	ld xix, (xsp + 8)
	lda xwa, (xix + 3)
	ld (xsp + 12), xwa
	ld a, (xwa)
	ld (xsp + 6), a
	lda xbc, (xsp + 28)
	ld (xbc), 0x0
	ld e, 0x0:opc
	extz de
	inc 1, de
	ld a, (xix + 4)
	ld	(xbc+de), a
	incm8 1, (xbc)
	ld a, (xsp + 4)
	extz wa
	lda xde, (xsp + 16)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	cp (xsp + 44), 0x0
	jr nz, VoiceAlloc_ReadNextNoteEvent
	lda xhl, (7574:16)
	ld wa, (xix)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld xwa, (xsp + 12)
	ld c, (xwa)
	ld (xde), c
	add c, (xix + 6)
	ld (xde), c
	cp c, 0x60
	jr c, VoiceAlloc_ComputePosition
	incw 1, (xhl)
	ld a, (xde)
	sub a, 0x60
	ld (xde), a

VoiceAlloc_ComputePosition:
	ld xwa, (xsp + 8)
	ld a, (xwa + 7)
	extz wa
	add (xhl), wa
	lda xix, (7578:16)
	ld wa, (xhl)
	ld (xix), wa
	lda xbc, (xix + 2)
	ld a, (xde)
	ld (xbc), a
	cp a, 0x1a
	jr nc, VoiceAlloc_AdjustSubtick
	decm 1, (xix)
	ld a, (xbc)
	add a, 0x60
	ld (xbc), a

VoiceAlloc_AdjustSubtick:
	submi8 (xbc), 0x1a

VoiceAlloc_ReadNextNoteEvent:
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 20)
	calr SeqPart_ReadNextEventByte
	lda xde, (xsp + 20)
	lda xbc, (xsp + 28)
	cp (xde), 0x90
	jr nz, VoiceAlloc_ValidateNoteCount
	ld a, (xde + 1)
	cp a, (xsp + 6)
	jr nz, VoiceAlloc_ValidateNoteCount
	ld l, (xbc)
	extz hl
	inc 1, hl
	ld a, (xde + 2)
	ld	(xbc+hl), a
	incm8 1, (xbc)
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 16)
	ld e, a
	ld wa, (xbc)
	ld (xsp + 12), wa
	ld wa, (xbc + 2)
	ld (xsp + 14), wa
	dec 1, e
	extz de
	sla de, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+de)
	ld wa, (xsp + 12)
	ld (xbc), wa
	ld wa, (xsp + 14)
	ld (xbc + 2), wa
	jr VoiceAlloc_ReadNextNoteEvent

VoiceAlloc_ValidateNoteCount:
	cp (xbc), 0xa
	jr ule, VoiceAlloc_ValidateCount_Done
	ldw wa, 0x12
	calr SeqData_SetErrorCode

VoiceAlloc_ValidateCount_Done:
	ld l, 0x0:opc
	lda xbc, (xsp + 28)
	ld (xsp + 10), xbc
	ld (xsp + 6), xbc
	ldw (xsp + 14), 0x0
	jr VoiceAlloc_SortLoop_OuterCheck

VoiceAlloc_SortLoop_Outer:
	ld d, l
	inc 1, d
	ld wa, (xsp + 14)
	inc 1, wa
	lda	xiy, (xbc+wa)
	ldfr_berp D, 0xf0
	extz ix
	jr VoiceAlloc_SortLoop_InnerCheck

VoiceAlloc_SortLoop_Inner:
	ld wa, ix
	inc 1, wa
	lda	xiz, (xbc+wa)
	ld a, (xiz)
	ld e, (xiy)
	cp e, a
	jr nc, VoiceAlloc_SortLoop_InnerNext
	ld (xiy), a
	ld (xiz), e

VoiceAlloc_SortLoop_InnerNext:
	inc 1, d
	inc 1, ix

VoiceAlloc_SortLoop_InnerCheck:
	ld xwa, (xsp + 6)
	ld a, (xwa)
	dec 1, a
	cp d, a
	jr ule, VoiceAlloc_SortLoop_Inner
	inc 1, l
	incw 1, (xsp + 14)

VoiceAlloc_SortLoop_OuterCheck:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	dec 1, a
	cp l, a
	jr c, VoiceAlloc_SortLoop_Outer
	lda xwa, (xsp + 40)
	ld de, 2:i3
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 40)
	cp (xsp + 44), 0x0
	jr z, VoiceAlloc_CompareLocalIdx
	ld xde, xwa
	ld c, (0xcedf:16)
	cp c, (xwa)
	jr nz, BitMapOut_WriteAltIdx
	ld a, (0xcee0:16)
	cp a, (xde + 1)
	jr nz, BitMapOut_WriteAltIdx
	ld a, (0xcee1:16)
	cp a, (xde + 2)
	jr nz, BitMapOut_WriteAltIdx
	ld a, (0xcede:16)
	cp a, (xde + 3)
	jrl z, BitMapOut_CompletionJoin

BitMapOut_WriteAltIdx:
	mrib4 0x82, 0x19, 0xdf, 0xce
	mrdb5 0x8a, 0x01, 0x19, 0xe0, 0xce
	mrdb5 0x8a, 0x02, 0x19, 0xe1, 0xce
	mrdb5 0x8a, 0x03, 0x19, 0xde, 0xce
	lda xiy, (0xcee5:16)
	lda xix, (xsp + 28)
	ld a, (xix)
	ld (xiy), a
	ld l, 0x0:opc
	ld xiz, xix
	ld de, 1:i3
	jr VoiceAlloc_CopyNoteData_Check

VoiceAlloc_CompareLocalIdx:
	ld xde, xwa
	ld c, (8960:16)
	cp c, (xwa)
	jr nz, BitMapOut_WriteMultiIdx
	ld a, (8962:16)
	cp a, (xde + 1)
	jr nz, BitMapOut_WriteMultiIdx
	ld a, (8964:16)
	cp a, (xde + 2)
	jr nz, BitMapOut_WriteMultiIdx
	ld a, (8966:16)
	cp a, (xde + 3)
	jr z, BitMapOut_CompletionJoin

BitMapOut_WriteMultiIdx:
	mrib4 0x82, 0x19, 0x00, 0x23
	mrdb5 0x8a, 0x01, 0x19, 0x02, 0x23
	mrdb5 0x8a, 0x02, 0x19, 0x04, 0x23
	mrdb5 0x8a, 0x03, 0x19, 0x06, 0x23
	jr BitMapOut_CompletionJoin

VoiceAlloc_CopyNoteData_Loop:
	ld wa, de
	ldw bc, 0xffff
	add wa, bc
	inc 1, wa
	ld bc, de
	extz xbc
	add xbc, xiy
	ld	a, (xix+wa)
	ld (xbc), a
	inc 1, l
	inc 1, de

VoiceAlloc_CopyNoteData_Check:
	cp l, (xiz)
	jr c, VoiceAlloc_CopyNoteData_Loop
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	lda xwa, (xsp + 40)
	mrib4 0x80, 0x19, 0x42, 0x8d
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8d
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8d
	mrdb5 0x88, 0x03, 0x19, 0xde, 0xce
	call BitMapOut_CheckDiskAndApply

BitMapOut_CompletionJoin:
	ld l, 0x0:opc

VoiceAlloc_ReturnFF:
	pop xiz
	lda xsp, (xsp + 42)
	ret

BitMapOut_PrepareAndDisplay:
	lda xsp, (xsp - 16)
	lda xbc, (xsp)
	ld (xbc), 0x0
	lda xwa, (xsp + 12)
	ld de, 2:i3
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 12)
	mrib4 0x80, 0x19, 0xdf, 0xce
	mrdb5 0x88, 0x01, 0x19, 0xe0, 0xce
	mrdb5 0x88, 0x02, 0x19, 0xe1, 0xce
	mrdb5 0x88, 0x03, 0x19, 0xde, 0xce
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	lda xwa, (xsp + 12)
	mrib4 0x80, 0x19, 0x42, 0x8d
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8d
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8d
	mrdb5 0x88, 0x03, 0x19, 0xde, 0xce
	call BitMapOut_CheckDiskAndApply
	lda xsp, (xsp + 16)
	ret

BitMapOut_PrepareAndDisplaySimple:
	lda xsp, (xsp - 16)
	lda xbc, (xsp)
	ld (xbc), 0x0
	lda xwa, (xsp + 12)
	ld de, 2:i3
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 12)
	mrib4 0x80, 0x19, 0x00, 0x23
	mrdb5 0x88, 0x01, 0x19, 0x02, 0x23
	mrdb5 0x88, 0x02, 0x19, 0x04, 0x23
	mrdb5 0x88, 0x03, 0x19, 0x06, 0x23
	lda xsp, (xsp + 16)
	ret

SeqBuf_AllocNextSlot:
	jrl Rhythm_ComputeNoteAllocation

SeqBuf_AllocNextSlotAdjusted:
	inc 1, wa
	calr Rhythm_ComputeNoteAllocation
	dec 1, hl
	ret

SeqBuf_WriteNoteOffEntry:
	lda xsp, (xsp - 10)
	ld (xsp + 8), a
	cp (7558:16), 0
	call nz, (SeqBuf_FlushAndReinit_VoiceCCEvents:24)
	lda xde, (xsp)
	ld (xde), 0x90
	ld (xde + 1), 0x7f
	ld (xde + 2), 0x0
	ld (xde + 3), 0x0
	lda xbc, (xde + 4)
	cp (xsp + 8), 0x32
	jr nz, SeqNoteOff_StoreChannelByte
	ld (xbc), 0x7f
	jr SeqNoteOff_WriteAndFlush

SeqNoteOff_StoreChannelByte:
	ld a, (xsp + 8)
	dec 1, a
	ld (xbc), a

SeqNoteOff_WriteAndFlush:
	push xde
	pushw 0x5
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_NoteEvents
	cp (xsp + 8), 0x32
	jr nz, SeqNoteOff_Return
	ldw wa, 0x32
	calr SeqNotePool_Init

SeqNoteOff_Return:
	lda xsp, (xsp + 10)
	ret

Part_DetectSingleVoiceType:
	res 0, (9954:16)
	ld l, 0x0:opc
	ld d, 0x1:opc

PartDetect_PartScanLoop:
	ld a, d
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartDetect_ShiftDone
	slaa bc

PartDetect_ShiftDone:
	and bc, (0x28a8:16)
	jr z, PartDetect_CheckCount
	inc 1, l
	ld e, d

PartDetect_CheckCount:
	cp l, 1:i3
	jr ugt, PartDetect_SingleVoiceFound
	inc 1, d
	cp d, 0x10
	jr ule, PartDetect_PartScanLoop

PartDetect_SingleVoiceFound:
	cp l, 1:i3
	jp nz, (PartSelect_UpdateDisplayState:24)
	extz de
	ld wa, 0:i3
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xf
	ret z
	cp l, 0x13
	jr ule, PartDetect_LookupAndApply
	ld l, 0x0:opc

PartDetect_LookupAndApply:
	extz hl
	lda xbc, (PartDetect_LookupAndApply_Table:24)
	ld	e, (xbc+hl)
	set 0, (9954:16)
	ld (PART_SELECT:16), e
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ret

Part_DeactivateVoiceChannel:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceByte
	cp l, 0xf
	jr nz, PartDeact_CheckSysFlags
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure

PartDeact_CheckSysFlags:
	ld a, (xsp)
	extz wa
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, PartDeact_ClearPartBit
	cpw (0xf19e:16), 0
	jr nz, PartDeact_SendVoiceOff
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw wa, 0x32
	calr SeqBuf_WriteNoteOffEntry
	ld a, (xsp)
	extz wa
	ld bc, 1:i3
	calr Chan_SetActiveBit
	calr VoiceAlloc_ProcessAll
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	call Audio_CheckSubsystemReady
	call SeqBuf_Init
	jr AccWrap_ClearPositionAndReset

PartDeact_SendVoiceOff:
	calr Part_SendVoiceOffAndCCEvents
	jr AccWrap_ClearPositionAndReset

PartDeact_ClearPartBit:
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartDeact_ClearShiftDone
	slaa bc

PartDeact_ClearShiftDone:
	cpl bc
	ld wa, (SEQ_ACTIVE_PARTS:16)
	and wa, bc
	ld (SEQ_ACTIVE_PARTS:16), wa
	cpw (0xf19e:16), 0
	jr nz, PartDeact_CheckSubsystem
	ldw (SEQ_ACTIVE_PARTS:16), 0
	res 7, (DEMO_CONTROL_FLAGS:16)
	call SeqBuf_Init

AccWrap_ClearPositionAndReset:
	res 0, (0x28a6:16)
	call AccWrap_PositionClear

PartDeact_CheckSubsystem:
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

Accomp_UpdateModeFlag:
	cp (CURRENT_TITLE:16), 129
	jr z, AccompMode_SetFlag
	cpw (0xf19e:16), 0
	jr z, AccompMode_ClearFlag

AccompMode_SetFlag:
	set 0, (0x28a5:16)
	jr AccompMode_ApplyAndNotify

AccompMode_ClearFlag:
	res 0, (0x28a5:16)

AccompMode_ApplyAndNotify:
	ld wa, (0x00ffec:24)
	ld (0xf19e:16), wa
	call Audio_CheckSubsystemReady
	ldw wa, 0x4c
	jp CtrlPanel_SetIndicatorBit

Accomp_ValidateAutoPlayChordVoice:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1
	ld wa, 0:i3
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr nz, AccompValidate_ShiftDone
	ldib_erp 0xfb, 0

AccompValidate_ShiftDone:
	ld a, l
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, AccompValidate_CheckPartActive
	slaa bc

AccompValidate_CheckPartActive:
	and bc, (0xf19e:16)
	jr nz, AccompValidate_CheckBit7
	ldib_erp 0xfb, 0

AccompValidate_CheckBit7:
	extz hl
	ld wa, 0:i3
	ld bc, hl
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, AccompValidate_StoreResult
	ldib_erp 0xfb, 0

AccompValidate_StoreResult:
	ldto_berp A, 0xfb
	ld (8968:16), a
	popw_erp 0xfa
	ret

Seq_SyncPositionAndOutputMIDITiming:
	dec 8, xsp
	push xiz
	ld xiy, Seq_SyncPositionAndOutputMIDITiming_LocalInit
	lda xix, (xsp + 4)
	ldi85
	ldiw
	cp (0xe388:16), 1
	jr nz, SeqSync_CheckDemoMode
	ld (0xe388:16), 0
	jr Seq_PopIzSkip8Ret

SeqSync_CheckDemoMode:
	cp (CURRENT_MODE:16), 19
	jr z, Seq_PopIzSkip8Ret
	bit 0, (0xb7e7:16)
	jr nz, Seq_PopIzSkip8Ret
	ld wa, 4:i3
	calr SeqStatus_CheckMaskedBit
	cp l, 0:i3
	jr z, Seq_PopIzSkip8Ret
	ld (1060:16), 242
	lda xiz, (xsp + 8)
	ei 6
	ldmw2 (xiz), 0x41c
	ldmi16 (xiz + 2), 0x41b
	ei 0
	lda xwa, (xsp + 8)
	ld bc, (xwa)
	sll bc, 2
	ld a, (xwa + 2)
	extz wa
	div a, 0x18
	extz wa
	add bc, wa
	ld de, bc
	and de, 0x7f
	srl bc, 7
	and bc, 0x7f
	lda xwa, (xsp + 4)
	ld (xwa + 1), e
	ld (xwa + 2), c
	ei 6
	lda xwa, (xsp + 4)
	push xwa
	pushw 0x3
	call SeqOut_WriteTimedBytes
	inc 6, xsp
	ei 0

Seq_PopIzSkip8Ret:
	pop xiz
	inc 8, xsp
	ret

Seq_CheckChordVoiceAndSetFlag:
	bit 6, (DEMO_CONTROL_FLAGS:16)
	ret z
	ld wa, 0:i3
	ldw bc, 0xf
	calr Part_FindVoiceByByte
	cp l, 0xff
	ret z
	dec 1, l
	ld bc, 1:i3
	ld a, l
	and a, 0xf
	jr z, SeqChordCheck_ShiftDone
	slaa bc

SeqChordCheck_ShiftDone:
	ld wa, bc
	and bc, (0xf19e:16)
	ret z
	and wa, (SEQ_ACTIVE_PARTS:16)
	ret z
	set 7, (0x28ae:16)
	ret

Part_CopyVoiceDataToAllChannels:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 8), 0x81
	ld (xsp + 6), 0x82
	ldib_erp 0xfb, 1

PartCopyVoice_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, PartCopyVoice_PartShiftDone
	slaa bc

PartCopyVoice_PartShiftDone:
	and bc, (0x28a8:16)
	jr z, PartCopyVoice_PartLoopNext
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (xsp + 2)
	dec 1, c
	extz bc
	sla bc, 2
	lda xde, (9184:16)
	lda	xde, (xde+bc)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 8)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 2)
	ld wa, 0:i3
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 4)
	ld wa, 0:i3
	calr Part_WriteByte_Indexed
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (xsp + 2)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de

PartCopyVoice_PartLoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jrl ule, PartCopyVoice_PartLoop
	popw_erp 0xfa
	inc 8, xsp
	ret

SeqEvent_CreateWithChannelValidation:
	dec 8, xsp
	ld c, a
	ld (xsp + 6), 0x81
	ld (xsp + 4), 0x82
	ld a, c
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqEventCreate_ShiftDone
	slaa de

SeqEventCreate_ShiftDone:
	and de, (0x28a8:16)
	jr z, SeqEventCreate_Return
	extz bc
	lda xwa, (xsp)
	dec 1, c
	extz bc
	sla bc, 2
	lda xde, (9184:16)
	lda	xde, (xde+bc)
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 6)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	lda xwa, (xsp)
	lda xbc, (xsp + 4)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock

SeqEventCreate_Return:
	inc 8, xsp
	ret

SeqEvent_GetParamLength:
	ld c, a
	and c, 0xf0
	cp c, 0xc0
	jr z, SeqEvent_ReturnError6
	cp c, 0xb0
	jr z, SeqEvent_ReturnError6
	cp c, 0x90
	jr z, SeqEvent_ReturnError6
	cp a, 0x82
	jr z, SeqEvent_ReturnLen1
	cp a, 0x81
	jr z, SeqEvent_ReturnLen1
	cp a, 0x86
	jr z, SeqEvent_ReturnLen2
	cp a, 0x85
	jr z, SeqEvent_ReturnLen2
	cp a, 0xa0
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xd3
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xd1
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xd0
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0x80
	jr z, SeqEvent_ReturnLen4
	cp a, 0xd2
	jr z, SeqEvent_ReturnLen4
	ldw hl, 0xffff

SeqEvent_NullRet:
	ret

SeqEvent_ReturnError6:
	ld hl, 6:i3
	jr SeqEvent_NullRet

SeqEvent_ReturnLen4:
	ld hl, 4:i3
	jr SeqEvent_NullRet

SeqEvent_ReturnStatusThree:
	ld hl, 3:i3
	jr SeqEvent_NullRet

SeqEvent_ReturnLen2:
	ld hl, 2:i3
	jr SeqEvent_NullRet

SeqEvent_ReturnLen1:
	ld hl, 1:i3
	jr SeqEvent_NullRet

SeqNotePool_Init:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 10), a
	lda xwa, (7602:16)
	cp (xsp + 10), 0x32
	jr nz, NotePool_ScanExistingEntries
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x3f
	lda xix, (7606:16)
	ld c, 0x1:opc
	lda xde, (xix + 1)
	ld xhl, xix

NotePool_InitLinkLoop:
	ld a, c
	add a, 0xfe
	ld (xhl), a
	ld (xde), c
	lda xhl, (xhl + 9)
	lda xde, (xde + 9)
	inc 1, c
	cp c, 0x40
	jr ule, NotePool_InitLinkLoop
	ld (xix), 0xff
	ld	(xix+568), 0xff
	jr NotePool_Return

NotePool_ScanExistingEntries:
	ld a, (xwa)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, NotePool_Return

NotePool_ScanEntryLoop:
	ldto_berp A, 0xfb
	extz wa
	lda xde, (xsp + 2)
	ld c, a
	ldfr_berp C, 0xee
	ld xix, xde
	ldib_erp 0xe2, 0

NotePool_CopySlotDataLoop:
	ldto_berp C, 0xe2
	extz bc
	ld iy, bc
	inc 4, iy
	ldto_berp C, 0xee
	extz bc
	muls bc, 0x9
	ld hl, bc
	lda xbc, (7606:16)
	lda	xbc, (xbc+hl)
	extz xiy
	add xiy, xbc
	ldto_berp L, 0xe2
	extz hl
	ld c, (xiy)
	ld	(xix+hl), c
	inc1b_erp 0xe2
	cpib_erp 0xe2, 5
	jr c, NotePool_CopySlotDataLoop
	ld c, (xde + 4)
	inc 1, c
	cp c, (xsp + 10)
	call z, (NoteMap_RemoveAndRelink:24)
	ldto_berp A, 0xfb
	extz wa
	muls wa, 0x9
	ld bc, wa
	lda xwa, (7607:16)
	ld	a, (xwa+bc)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0xff
	jr nz, NotePool_ScanEntryLoop

NotePool_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

NotePool_DataBlock:
	push	qiz
	ldib_erp	251, 0
SeqNotePool_Init_Loop:
	ldto_berp	c, 251
	inc	1, c
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadVoiceBit7
	ldto_berp c, 251
	inc 1, c
	extz	bc
	extz	hl
	dec	1, c
	ld	a, c
	ld	bc, 1:i3
	and	a, 15
	jr	z, SeqNotePool_Init_Skip
	.byte 0xd9, 0xfc	; sla a,bc
SeqNotePool_Init_Skip:
	cp	l, 0:i3
	jr	z, SeqNotePool_Init_Skip2
	or (8982:16), bc
	jr	SeqNotePool_Init_Join
SeqNotePool_Init_Skip2:
	cpl	bc
	and (8982:16), bc
SeqNotePool_Init_Join:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	c, SeqNotePool_Init_Loop
	pop qiz
	ret

SeqBuffer_MoveEntryToHead:
	push xiz
	cp a, 0xff
	jr nz, SeqBufMove_LoadSlotData
	ld (0xe38a:16), 255

SeqBufMove_LoadSlotData:
	lda xiz, (8184:16)
	lda xix, (xiz + 1)
	ld w, (xix)
	ld c, a
	extz bc
	muls bc, 0xc
	ld iy, bc
	lda xhl, (8186:16)
	lda	xbc, (xhl+iy)
	lda xde, (xbc + 10)
	cp w, 0xff
	jr nz, SeqBufMove_RelinkPrev
	ld (xiz), a
	ld (xde), 0xff
	jr SeqBufMove_UpdateHead

SeqBufMove_RelinkPrev:
	ld c, w
	extz bc
	muls bc, 0xc
	exts xbc
	add xbc, xhl
	ld (xbc + 11), a
	ld (xde), w

SeqBufMove_UpdateHead:
	ld (xix), a
	lda	xwa, (xhl+iy)
	ld (xwa + 11), 0xff
	pop xiz
	ret

SeqBuffer_UnlinkEntry:
	push xiz
	extz wa
	muls wa, 0xc
	lda xiz, (8186:16)
	lda	xbc, (xiz+wa)
	ld a, (xbc + 10)
	ldfr_berp A, 0xf4
	ld a, (xbc + 11)
	ldfr_berp A, 0xf0
	lda xde, (8182:16)
	lda xbc, (xde + 1)
	cp_erpb 0xf4, 0xff
	jr nz, VoiceAlloc_RelinkEntry
	cp_erpb 0xf0, 0xff
	jr nz, VoiceAlloc_RelinkEntry
	ld (xde), 0xff
	ld (xbc), 0xff
	jr Bitmap_RestoreReturn

VoiceAlloc_RelinkEntry:
	ldto_berp A, 0xf0
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xiz
	lda xhl, (xwa + 10)
	cp_erpb 0xf4, 0xff
	jr nz, SeqBufUnlink_HandlePrevOnly
	ldto_berp A, 0xf0
	ld (xde), a
	ld (xhl), 0xff
	jr Bitmap_RestoreReturn

SeqBufUnlink_HandlePrevOnly:
	ldto_berp A, 0xf4
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xiz
	lda xde, (xwa + 11)
	cp_erpb 0xf0, 0xff
	jr nz, SeqBufUnlink_HandleBothLinks
	ldto_berp A, 0xf4
	ld (xbc), a
	ld (xde), 0xff
	jr Bitmap_RestoreReturn

SeqBufUnlink_HandleBothLinks:
	ldto_berp A, 0xf4
	ld (xhl), a
	ldto_berp A, 0xf0
	ld (xde), a

Bitmap_RestoreReturn:
	pop xiz
	ret

SeqBuffer_InsertAtHead:
	push xiz
	lda xiz, (8182:16)
	lda xix, (xiz + 1)
	ld w, (xix)
	ld c, a
	extz bc
	muls bc, 0xc
	ld iy, bc
	lda xhl, (8186:16)
	lda	xbc, (xhl+iy)
	lda xde, (xbc + 10)
	cp w, 0xff
	jr nz, SeqBufInsert_RelinkPrev
	ld (xiz), a
	ld (xde), 0xff
	jr SeqBufInsert_UpdateHeadAndClear

SeqBufInsert_RelinkPrev:
	ld c, w
	extz bc
	muls bc, 0xc
	exts xbc
	add xbc, xhl
	ld (xbc + 11), a
	ld (xde), w

SeqBufInsert_UpdateHeadAndClear:
	ld (xix), a
	lda xwa, (8197:16)
	ld	(xwa+iy), 0xff
	pop xiz
	ret

SeqBuffer_ClearAndInitIteration:
	dec 6, xsp
	push xiz
	lda xde, (xsp + 4)
	ld xwa, xde
	lda xbc, (xde + 6)

SeqBuffer_ClearLoop:
	ld (xwa+), 0xff
	cp xwa, xbc
	jr c, SeqBuffer_ClearLoop
	lda xwa, (8182:16)
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	lda xwa, (8184:16)
	ld (xwa), 0x0
	ld (xwa + 1), 0x3f
	ld l, 0x0:opc

SeqBuffer_InitSlotLoop:
	ld c, l
	extz bc
	ld a, c
	ldfr_berp A, 0xe6
	ld xiy, xde
	ld h, 0x0:opc

SeqBuffer_InitSlot_CopyFields:
	ldfr_berp H, 0xf8
	extz iz
	ldto_berp A, 0xe6
	extz wa
	muls wa, 0xc
	lda xix, (8186:16)
	exts xwa
	add xwa, xix
	extz xiz
	add xiz, xwa
	ld a, h
	extz wa
	ld	a, (xiy+wa)
	ld (xiz), a
	inc 1, h
	cp h, 4:i3
	jr c, SeqBuffer_InitSlot_CopyFields
	muls bc, 0xc
	exts xbc
	add xbc, xix
	ld a, l
	dec 1, a
	ld (xbc + 10), a
	ld a, l
	inc 1, a
	ld (xbc + 11), a
	inc 1, l
	cp l, 0x3f
	jr ule, SeqBuffer_InitSlotLoop
	ld (xix + 10), 0xff
	ld	(xix+767), 0xff
	pop xiz
	inc 6, xsp
	ret

SeqBuffer_FindMinPosition:
	ld a, (8182:16)
	ldw hl, 0xffff
	cp a, 0xff
	jr z, SeqBuffer_FindMin_Store
	lda xbc, (8186:16)

SeqBuffer_FindMin_ScanLoop:
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xbc
	ld de, (xwa + 4)
	cp de, hl
	jr nc, SeqBuffer_FindMin_NextEntry
	ld hl, de

SeqBuffer_FindMin_NextEntry:
	ld a, (xwa + 11)
	cp a, 0xff
	jr nz, SeqBuffer_FindMin_ScanLoop

SeqBuffer_FindMin_Store:
	ld (8954:16), hl
	ret

NoteMap_RemoveHeadEntry:
	extz wa
	muls wa, 0x9
	lda xbc, (7606:16)
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	lda xwa, (7602:16)
	ld (xwa + 2), e
	cp e, 0xff
	jr z, NoteMap_RemoveHead_ClearTail
	extz de
	muls de, 0x9
	ld	(xbc+de), 0xff
	ret

NoteMap_RemoveHead_ClearTail:
	ld (xwa + 3), e
	ret

NoteMap_RemoveAndRelink:
	dec 4, xsp
	push xiz
	ld c, a
	extz bc
	muls bc, 0x9
	lda xhl, (7606:16)
	lda	xde, (xhl+bc)
	ld w, (xde)
	lda xbc, (xde + 1)
	ld (xsp + 4), xbc
	ld c, (xbc)
	ldfr_berp C, 0xe2
	cp w, 0xff
	jr nz, NoteMap_RelinkEntry
	cp_erpb 0xe2, 0xff
	jr nz, NoteMap_RelinkEntry
	lda xbc, (7602:16)
	ld (xbc), 0xff
	ld (xbc + 1), 0xff
	jr NoteMap_UpdateTailPointer

NoteMap_RelinkEntry:
	ldto_berp C, 0xe2
	extz bc
	muls bc, 0x9
	lda	xiz, (xhl+bc)
	lda xix, (7602:16)
	cp w, 0xff
	jr nz, NoteMap_Relink_HasPrev
	ldto_berp C, 0xe2
	ld (xix), c
	ld w, 0xff:opc
	jr NoteMap_Relink_SetPrev

NoteMap_Relink_HasPrev:
	ld c, w
	extz bc
	muls bc, 0x9
	exts xbc
	add xbc, xhl
	lda xiy, (xbc + 1)
	cp_erpb 0xe2, 0xff
	jr nz, NoteMap_Relink_ConnectPrevNext
	ld (xix + 1), w
	ld (xiy), 0xff
	jr NoteMap_UpdateTailPointer

NoteMap_Relink_ConnectPrevNext:
	ldto_berp C, 0xe2
	ld (xiy), c

NoteMap_Relink_SetPrev:
	ld (xiz), w

NoteMap_UpdateTailPointer:
	lda xbc, (7602:16)
	lda xix, (xbc + 3)
	ld w, (xix)
	cp w, 0xff
	jr nz, NoteMap_UpdateTail_HasPrev
	ld (xbc + 2), a
	ld w, 0xff:opc
	jr NoteMap_UpdateTail_LinkEntry

NoteMap_UpdateTail_HasPrev:
	ld c, w
	extz bc
	muls bc, 0x9
	exts xbc
	add xbc, xhl
	ld (xbc + 1), a

NoteMap_UpdateTail_LinkEntry:
	ld (xde), w
	ld (xix), a
	ld xwa, (xsp + 4)
	ld (xwa), 0xff
	pop xiz
	inc 4, xsp
	ret

SeqBuffer_RemoveLastEntry:
	lda xde, (8184:16)
	ld l, (xde)
	cp l, 0xff
	ret z
	ld a, l
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	exts xwa
	add xwa, xbc
	ld h, (xwa + 11)
	cp h, 0xff
	jr z, SeqBuffer_RemoveLast_Fixup
	ld a, h
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xbc
	ld (xwa + 10), 0xff

SeqBuffer_RemoveLast_Fixup:
	ld (xde), h
	cp h, 0xff
	ret nz
	ld (0x2868:16), l
	ret

SeqPlay_AllocBuffersAndInit:
	ld c, (CURRENT_TITLE:16)
	cp c, 0x85
	jr z, SeqPlay_AllocBuf_Mode85_86
	cp c, 0x86
	jr nz, SeqPlay_AllocBuf_Mode87_88

SeqPlay_AllocBuf_Mode85_86:
	bit 1, (0x28b1:16)
	jr nz, SeqPlay_AllocBuf_HasRepeat
	ldw (9000:16), 0
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	res 3, (0x28a7:16)
	jr SeqPlay_AllocBuf_InitPlayback

SeqPlay_AllocBuf_HasRepeat:
	ld wa, (9504:16)
	calr SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0
	cp hl, 0:i3
	jr nz, SeqPlay_AllocBuf_SetRepeatBit
	res 3, (0x28a7:16)
	jr SeqPlay_AllocBuf_AllocSecond

SeqPlay_AllocBuf_SetRepeatBit:
	set 3, (0x28a7:16)

SeqPlay_AllocBuf_AllocSecond:
	ld wa, (9506:16)
	calr SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl
	jr SeqPlay_AllocBuf_InitPlayback

SeqPlay_AllocBuf_Mode87_88:
	ld wa, (9832:16)
	cp c, 0x87
	jr z, SeqPlay_AllocBuf_Mode87_88_Alloc
	cp c, 0x88
	jr nz, SeqAllocBuf_CheckBit3

SeqPlay_AllocBuf_Mode87_88_Alloc:
	calr SeqBuf_AllocNextSlot
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0

SeqPlay_AllocBuf_InitPlayback:
	call SeqPlay_InitializePlayback
	jr SeqAllocBuf_ResetStartState

SeqAllocBuf_CheckBit3:
	bit 3, (0x28a7:16)
	jr z, SeqAllocBuf_CheckMode17
	calr SeqBuf_AllocNextSlot
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0

SeqAllocBuf_CheckMode17:
	bit 0, (0x28b1:16)
	jr z, SeqAllocBuf_InitPlayback
	ld wa, (9500:16)
	calr SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld wa, (9502:16)
	calr SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl

SeqAllocBuf_InitPlayback:
	call SeqAcc_InitPlaybackState

SeqAllocBuf_ResetStartState:
	jr SeqPlay_ResetStartState

SeqPlay_InitStartState:
	set 4, (0x28b3:16)
	set 2, (0x28a7:16)
	ld (9508:16), 1
	cpw (9832:16), 1
	jr z, SeqInitStart_CheckPlayMode
	ld (7518:16), 250
	set 3, (0x28a7:16)
	jr SeqInitStart_SetActiveFlag

SeqInitStart_CheckPlayMode:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x85
	jr z, SeqInitStart_Mode85_86
	cp a, 0x86
	jr nz, SeqInitStart_Mode87_88

SeqInitStart_Mode85_86:
	bit 1, (0x28b1:16)
	jr z, Display_ClearHWState
	jr SeqInitStart_SetPreroll

SeqInitStart_Mode87_88:
	cp a, 0x87
	jr z, Display_ClearHWState
	cp a, 0x88
	jr nz, SeqInitStart_CheckMode17Alt

Display_ClearHWState:
	ld (7518:16), 0

SeqInitStart_ClearBit3:
	res 3, (0x28a7:16)

SeqInitStart_SetActiveFlag:
	ld (0xe386:16), 1
	ret

SeqInitStart_CheckMode17Alt:
	bit 0, (0x28b1:16)
	jr z, Display_ClearHWState

SeqInitStart_SetPreroll:
	ld (7518:16), 250
	jr SeqInitStart_ClearBit3

SeqPlay_ResetStartState:
	res 4, (0x28b3:16)
	ld (7518:16), 0
	ld (9508:16), 0
	cp (CURRENT_TITLE:16), 142
	ret z
	cp (0xe386:16), 1
	jr nz, SeqResetStart_ClearActiveFlag
	res 2, (0x28a7:16)

SeqResetStart_ClearActiveFlag:
	ld (0xe386:16), 0
	ret

SeqPart_ScanAndBuildVoiceData:
	dec 8, xsp
	push xiz
	ld iz, 0:i3
	ld (xsp + 6), 0x81
	ld a, (8986:16)
	ldfr_berp A, 0xfb
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	ld (0x28af:16), hl
	ldw (9830:16), 5
	ldmw2 (xsp + 4), 0x232a
	cpw (xsp + 4), 0x0
	jrl c, SeqPartBuild_Return

SeqPartBuild_ReadLoop:
	calr SeqData_ReadNextByte
	cp l, 0x81
	jr nz, SeqPartBuild_CheckEndMark82
	inc 1, iz
	calr SeqData_AdvancePosition
	jrl SeqPartBuild_CheckCount

SeqPartBuild_CheckEndMark82:
	cp l, 0x82
	jrl nz, SeqPartBuild_GetEventSize
	lda xwa, (xsp + 8)
	ldmw2 (xwa), 0x28af
	ldmw2 (xwa + 2), 0x2666
	cp iz, (xsp + 4)
	jr ugt, SeqPartBuild_WriteAndProcess

SeqPartBuild_CopyBytesLoop:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	inc 1, iz
	cp iz, (xsp + 4)
	jr ule, SeqPartBuild_CopyBytesLoop

SeqPartBuild_WriteAndProcess:
	lda xwa, (xsp + 8)
	mriw4 0x90, 0x19, 0xaf, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x66, 0x26
	ldw wa, 0x82
	calr PartCtrl_WriteByte_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld de, (0x28af:16)
	ld wa, 0:i3
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xfb
	extz bc
	ld wa, (9830:16)
	ld e, a
	extz de
	ld wa, 0:i3
	calr Part_WriteByte_Indexed
	ld bc, (9000:16)
	ldto_berp A, 0xfb
	extz wa
	lda xde, (xsp + 8)
	call Part_ReadAndProcessVoiceData
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (xsp + 8)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	jr SeqPartBuild_CheckCount

SeqPartBuild_GetEventSize:
	extz hl
	ld wa, hl
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqPartBuild_CheckCount:
	cp iz, (xsp + 4)
	jrl ule, SeqPartBuild_ReadLoop

SeqPartBuild_Return:
	pop xiz
	inc 8, xsp
	ret

SeqPart_InitVoiceChannelConfig:
	dec 4, xsp
	push xiz
	ld wa, (9002:16)
	ld (7542:16), wa
	ld wa, (9002:16)
	sub wa, (9000:16)
	inc 1, wa
	ld (7544:16), wa
	ld wa, (8982:16)
	ld (8984:16), wa
	ld wa, 0:i3
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPartInit_CheckBassVoice
	dec 1, l
	ld bc, 1:i3
	ld a, l
	and a, 0xf
	jr z, SeqPartInit_AccompShiftDone
	slaa bc

SeqPartInit_AccompShiftDone:
	and bc, (8982:16)
	lda xwa, (7538:16)
	cp bc, 0:i3
	jr z, SeqPartInit_AccompNotActive
	ld (xwa), 0x1
	jr SeqPartInit_CheckBassVoice

SeqPartInit_AccompNotActive:
	ld (xwa), 0x0

SeqPartInit_CheckBassVoice:
	ld wa, 0:i3
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPartInit_MainLoop
	dec 1, l
	ld bc, 1:i3
	ld a, l
	and a, 0xf
	jr z, SeqPartInit_BassShiftDone
	slaa bc

SeqPartInit_BassShiftDone:
	and bc, (8982:16)
	lda xwa, (7539:16)
	cp bc, 0:i3
	jr z, SeqPartInit_BassNotActive
	ld (xwa), 0x1
	jr SeqPartInit_MainLoop

SeqPartInit_BassNotActive:
	ld (xwa), 0x0

SeqPartInit_MainLoop:
	ld b, 0x1:opc
	ld c, 0x0:opc

SeqPartInit_PartScanLoop:
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqPartInit_PartShiftDone
	slaa de

SeqPartInit_PartShiftDone:
	and de, (8982:16)
	jr z, SeqPartInit_PartLoopNext
	ld a, b
	extz wa
	lda xix, (xsp + 4)
	dec 1, a
	ld l, a
	extz hl
	ld wa, hl
	sla wa, 2
	lda xde, (9184:16)
	lda	xde, (xde+wa)
	ld wa, (xde)
	ld (xix), wa
	lda xiy, (xix + 2)
	ld de, (xde + 2)
	ld (xiy), de
	ld wa, (xix)
	sla hl, 3
	lda xiz, (9332:16)
	exts xhl
	add xhl, xiz
	ld (xhl), wa
	ld (xhl + 2), de
	cp b, (8988:16)
	jr nz, SeqPartInit_PartLoopNext
	ld hl, (xix)
	ld de, (xiy)
	lda xwa, (xiz+152:16)
	ld (xwa), hl
	ld (xwa + 2), de

SeqPartInit_PartLoopNext:
	inc 1, b
	inc 1, c
	cp b, 0x10
	jr ule, SeqPartInit_PartScanLoop
	pop xiz
	inc 4, xsp
	ret

MIDI_GetEventSizeFromByte:
	ld c, a
	and c, 0xf0
	cp c, 0xc0
	jr z, MidiEvtSize_Return7
	cp c, 0xb0
	jr z, MidiEvtSize_Return7
	cp c, 0x90
	jr nz, MidiEvtSize_CheckSpecial

MidiEvtSize_Return5:
	ld l, 0x5:opc
	jr SeqPart_NullRet

MidiEvtSize_Return7:
	ld l, 0x7:opc
	jr SeqPart_NullRet

MidiEvtSize_CheckSpecial:
	cp a, 0x81
	jr z, MidiEvtSize_Return1
	cp a, 0xd3
	jr z, SeqPart_ReturnStatusFour
	cp a, 0xd2
	jr z, MidiEvtSize_Return5
	cp a, 0xd1
	jr z, SeqPart_ReturnStatusFour
	cp a, 0xd0
	jr z, SeqPart_ReturnStatusFour
	cp a, 0x86
	jr z, MidiEvtSize_Return2
	cp a, 0x85
	jr z, MidiEvtSize_Return2
	cp a, 0x80
	jr z, SeqPart_ReturnStatusFour
	ld l, 0x0:opc

SeqPart_NullRet:
	ret

MidiEvtSize_Return2:
	ld l, 0x2:opc
	jr SeqPart_NullRet

SeqPart_ReturnStatusFour:
	ld l, 0x4:opc
	jr SeqPart_NullRet

MidiEvtSize_Return1:
	ld l, 0x1:opc
	jr SeqPart_NullRet

SeqPlay_CheckRepeatActive:
	ld l, 0x0:opc
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	ret z
	cp a, 0x88
	ret z
	ld bc, (9004:16)
	ld wa, (9002:16)
	ld e, (CURRENT_MODE:16)
	cp e, 0xb
	jr nz, SeqRepeatCheck_Mode13
	bit 1, (0x28b1:16)
	ret z
	cp bc, wa
	jr ule, SeqRepeatCheck_ReturnActive
	jr SeqRepeatCheck_Return

SeqRepeatCheck_Mode13:
	cp e, 0x13
	ret z
	bit 0, (0x28b1:16)
	ret z
	cp bc, wa
	ret ugt

SeqRepeatCheck_ReturnActive:
	ld l, 0x1:opc

SeqRepeatCheck_Return:
	ret

SeqData_GetEventByteCount:
	ld e, (xwa)
	and e, 0xf0
	lda xbc, (xwa + 4)
	cp e, 0xc0
	jr z, SeqDataEvtBC_Return6
	ld l, (xbc)
	cp e, 0xb0
	jr z, SeqDataEvtBC_Return6
	cp e, 0x90
	jr nz, SeqDataEvtBC_CheckSpecial

SeqDataEvtBC_JumpReturn:
	jr SeqDataEvtBC_Return

SeqDataEvtBC_Return6:
	ld bc, 6:i3
	jr SeqDataEvtBC_LoadAndReturn

SeqDataEvtBC_CheckSpecial:
	ld c, (xwa)
	cp c, 0xd2
	jr z, SeqDataEvtBC_JumpReturn
	cp c, 0xd3
	jr z, SeqDataEvtBC_Return3
	cp c, 0xd1
	jr z, SeqDataEvtBC_Return3
	cp c, 0xd0
	jr nz, SeqDataEvtBC_ReturnFF

SeqDataEvtBC_Return3:
	ld bc, 3:i3

SeqDataEvtBC_LoadAndReturn:
	ld	l, (xwa+bc)
	jr SeqDataEvtBC_Return

SeqDataEvtBC_ReturnFF:
	ld l, 0xff:opc

SeqDataEvtBC_Return:
	ret

Part_SendVoiceOffAndCCEvents:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceByte
	ldfr_berp L, 0xfb
	ld a, (xsp + 2)
	extz wa
	calr SeqBuf_WriteNoteOffEntry
	lda xwa, (0xe374:16)
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 3), c
	ld bc, 4:i3
	calr SeqBuf_WriteMidiEvent
	lda xwa, (0xe378:16)
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 4), c
	ld bc, 5:i3
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents
	cp_erpb 0xfb, 0x0c
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xfb, 0x0d
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xfb, 0x10
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xfb, 0x0f
	jr z, SeqBuf_MidiEventReturnPath
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (PartDetect_LookupAndApply_Table:24)
	ld	c, (xbc+wa)
	lda xwa, (0xe37e:16)
	ld (xwa + 2), c
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 6), c
	ld bc, 7:i3
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents

SeqBuf_MidiEventReturnPath:
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqVoice_FindSingleActive:
	res 0, (9954:16)
	ld l, 0x0:opc
	ld d, 0x1:opc

SeqVoiceSingle_ScanLoop:
	ld a, d
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqVoiceSingle_ShiftDone
	slaa bc

SeqVoiceSingle_ShiftDone:
	and bc, (3407:16)
	jr z, SeqVoiceSingle_CountCheck
	inc 1, l
	ld e, d

SeqVoiceSingle_CountCheck:
	cp l, 1:i3
	jr ugt, SeqVoiceSingle_FoundOrDone
	inc 1, d
	cp d, 0x10
	jr ule, SeqVoiceSingle_ScanLoop

SeqVoiceSingle_FoundOrDone:
	cp l, 1:i3
	jp nz, (PartSelect_UpdateDisplayState:24)
	extz de
	ld wa, 0:i3
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xf
	ret z
	cp l, 0x13
	jr ule, SeqVoiceSingle_LookupAndApply
	ld l, 0x0:opc

SeqVoiceSingle_LookupAndApply:
	extz hl
	lda xbc, (PartDetect_LookupAndApply_Table:24)
	ld	e, (xbc+hl)
	set 0, (9954:16)
	ld (PART_SELECT:16), e
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ret

SeqNotify_DataBlock:
	set	0, (10419:16)
	ret

SeqNotify_CheckAndClearStart:
	bit 0, (0x28b3:16)
	ret z
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqNotify_ClearStartFlag
	cp a, 0x88
	call nz, (BitMapOut_ComputeRegionDelta:24)

SeqNotify_ClearStartFlag:
	res 0, (0x28b3:16)
	ret

Seq_HandleModeTransition:
	cpw (0xf19e:16), 0
	jr nz, SeqModeTransit_ClearFlags
	ld (8968:16), 0
	res 3, (0x28a7:16)

SeqModeTransit_ClearFlags:
	res 4, (1056:16)
	res 1, (1056:16)
	ld a, (1054:16)
	res 4, a
	res 1, a
	ld (1054:16), a
	cp (CURRENT_MODE:16), 19
	jr nz, SeqModeTransit_CheckBit5
	calr SeqModeTransit_DemoPath
	jr Voice_LoadPresetReturn

SeqModeTransit_CheckBit5:
	bit 5, (0x28ac:16)
	jr nz, SeqModeTransit_LoadPreset
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, Voice_LoadPresetReturn
	bit 2, a
	jr nz, Voice_LoadPresetReturn

SeqModeTransit_LoadPreset:
	calr SeqModeTransit_UpdateParts

Voice_LoadPresetReturn:
	ldmm16 0x2838, 0xf19e
	ret

SeqModeTransit_DemoPath:
	calr SeqModeTransit_GetPresetWord
	ld (8980:16), hl
	ret

SeqModeTransit_GetPresetWord:
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	jp Voice_GetPresetFieldWord

SeqModeTransit_UpdateParts:
	ld wa, (0xf19e:16)
	cp wa, 0:i3
	jr z, SeqModeTransit_ClearPartState
	cp wa, (0x2838:16)
	call nz, (SeqAcc_InitPlaybackState:24)
	ld a, (1075:16)
	cp a, (0x286a:16)
	ret z
	ld (9010:16), a
	call SeqMode_SendStatusUpdate
	ldmm8 0x286a, 1075
	ret

SeqModeTransit_ClearPartState:
	ldw (8980:16), 0
	ld a, (0x28a7:16)
	res 0, a
	ld (0x28a7:16), a
	cpw (0x28a8:16), 0
	jr z, SeqModeTransit_SetRepeatBit
	set 0, a
	ld (0x28a7:16), a

SeqModeTransit_SetRepeatBit:
	set 1, (0x28a7:16)
	ld wa, (0xf19e:16)
	cp wa, (0x2838:16)
	jr z, SeqModeTransit_ClearSysFlag
	call AccWrap_PositionClear
	res 0, (0x28a6:16)

SeqModeTransit_ClearSysFlag:
	res 0, (1115:16)
	ret

SeqCh_LoadChannelConfig:
	lda xsp, (xsp - 18)
	ld (xsp + 16), a
	cp (xsp + 16), 0x14
	jr ule, SeqChLoad_SetupAndCopy
	ldw wa, 0x1d
	calr SeqData_SetErrorCode

SeqChLoad_SetupAndCopy:
	ld a, (xsp + 16)
	extz wa
	lda xde, (xsp + 4)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld (xsp + 2), 0x0

SeqChLoad_ReadEventLoop:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	cp hl, 0xffff
	jr nz, SeqChLoad_DispatchEvent
	ld (xsp + 9), 0x0

SeqChLoad_DispatchEvent:
	lda xhl, (xsp + 8)
	ld a, (xhl)
	ldfr_berp A, 0xe6
	ld e, (xsp + 16)
	dec 1, e
	extz de
	cp_erpb 0xe6, 0x81
	jr nz, SeqChLoad_CheckShiftAndBits
	sla de, 3
	lda xwa, (9016:16)
	incw	1, (xwa+de)
	jr SeqChLoad_ReadEventLoop

SeqChLoad_CheckShiftAndBits:
	ld a, (xsp + 16)
	extz wa
	lda xix, (9016:16)
	dec 1, a
	sla de, 3
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqChLoad_ShiftDone
	slaa bc

SeqChLoad_ShiftDone:
	exts xde
	add xde, xix
	cpl bc
	cp_erpb 0xe6, 0x84
	jrl nz, SeqCh_LoadData_CheckEndMark
	cp (xsp + 2), 0x1
	jr nz, SeqChLoad_FirstBarSetup
	cp (xsp + 16), 0x14
	jr z, SeqChLoad_SetEndMarkerFFF0
	and (8982:16), bc
	jrl SeqCh_WriteVoiceDataToTable

SeqChLoad_SetEndMarkerFFF0:
	ldw (xde), 0xfff0
	jrl SeqCh_WriteVoiceDataToTable

SeqChLoad_FirstBarSetup:
	ld (xsp + 2), 0x1
	cp (xsp + 16), 0x11
	jr nc, SeqCh_LoadData_CheckCh14
	ld a, (xsp + 16)
	ld (xsp), a
	jr SeqCh_LoadData_CheckBass

SeqCh_LoadData_CheckCh14:
	cp (xsp + 16), 0x14
	jr nz, SeqCh_LoadData_CheckBass
	ldmi16 (xsp), 0x231c

SeqCh_LoadData_CheckBass:
	ld a, (xsp + 16)
	cp a, (8990:16)
	jr nz, SeqCh_LoadData_CheckDrum
	lda xbc, (xsp + 4)
	lda xde, (7594:16)
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 2)
	ld (xbc + 2), wa
	ld (7560:16), 1
	jr Voice_WriteIndexedData

SeqCh_LoadData_CheckDrum:
	ld a, (xsp)
	cp a, (8988:16)
	jr nz, SeqCh_LoadData_ReadVoiceWord
	lda xde, (xsp + 4)
	bit 1, (8974:16)
	jr z, SeqCh_LoadData_DrumDefault
	extz wa
	ld c, (8972:16)
	extz bc
	call Part_ReadAndProcessVoiceData
	jr Voice_WriteIndexedData

SeqCh_LoadData_DrumDefault:
	lda xbc, (7590:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr Voice_WriteIndexedData

SeqCh_LoadData_ReadVoiceWord:
	ld c, (xsp + 16)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	lda xwa, (xsp + 4)
	ld (xwa), hl
	ldw (xwa + 2), 0x5

Voice_WriteIndexedData:
	ld a, (xsp + 16)
	extz wa
	lda xbc, (xsp + 4)
	ld hl, (xbc)
	ld de, (xbc + 2)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	jrl SeqChLoad_ReadEventLoop

SeqCh_LoadData_CheckEndMark:
	cp_erpb 0xe6, 0x82
	jrl nz, SeqCh_WriteVoiceDataToTable
	cp (7570:16), 1
	jr nz, SeqCh_LoadData_NotEndMark
	cp (xsp + 16), 0x10
	jr ugt, SeqCh_LoadData_EndMarkWord
	and (8982:16), bc
	jr SeqCh_LoadData_CopyToTable

SeqCh_LoadData_EndMarkWord:
	ldw (xde), 0xfff0

SeqCh_LoadData_CopyToTable:
	ld a, (xsp + 16)
	extz wa
	lda xbc, (xsp + 4)
	ld iy, (xbc)
	ld ix, (xbc + 2)
	dec 1, a
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (9184:16)
	exts xbc
	add xbc, xde
	ld (xbc), iy
	ld (xbc + 2), ix
	ld de, wa
	sla de, 3
	lda xwa, (9018:16)
	ld xbc, xhl
	exts xde
	add xde, xwa
	inc 6, xhl

SeqCh_LoadData_CopyLoop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, SeqCh_LoadData_CopyLoop
	ldw hl, 0xffff
	jr SeqCh_WriteData_Return

SeqCh_LoadData_NotEndMark:
	ld (xhl + 1), 0x0
	ld wa, 0:i3
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	ld (xsp), l
	ld a, (xsp + 16)
	cp a, (xsp)
	jr z, SeqCh_LoadData_DecrementPos
	cp (xsp + 16), 0x14
	jr nz, SeqCh_WriteVoiceDataToTable

SeqCh_LoadData_DecrementPos:
	ld a, (xsp + 16)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	exts xwa
	add xwa, xbc
	cpw (xwa), 0x0
	jr z, SeqCh_WriteVoiceDataToTable
	decm 1, (xwa)

SeqCh_WriteVoiceDataToTable:
	ld a, (xsp + 16)
	extz wa
	lda xbc, (xsp + 4)
	ld ix, (xbc)
	ld hl, (xbc + 2)
	dec 1, a
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (9184:16)
	exts xbc
	add xbc, xde
	ld (xbc), ix
	ld (xbc + 2), hl
	lda xhl, (xsp + 8)
	ld de, wa
	sla de, 3
	lda xwa, (9018:16)
	ld xbc, xhl
	exts xde
	add xde, xwa
	inc 6, xhl

SeqCh_WriteData_CopyLoop:
	ld A, (xbc+)
	ld (xde+), a
	cp xbc, xhl
	jr c, SeqCh_WriteData_CopyLoop
	ld hl, 0:i3

SeqCh_WriteData_Return:
	lda xsp, (xsp + 18)
	ret

SeqVoice_InitForRepeatMode:
	dec 8, xsp
	pushw iz
	ld (xsp + 8), 0x81
	ld (xsp + 6), 0x82
	calr SeqVoice_FindChannelSetup
	lda xbc, (9332:16)
	lda xwa, (xbc+128:16)
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda xwa, (xbc+144:16)
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda xwa, (xbc+136:16)
	ldw (xwa), 0x2
	ldw (xwa + 2), 0x5
	lda xbc, (9184:16)
	lda xwa, (xbc + 64)
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda xwa, (xbc + 72)
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda xwa, (xbc + 68)
	ldw (xwa), 0x2
	ldw (xwa + 2), 0x5
	lda xwa, (xsp + 2)
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	ld iz, 0:i3
	ld wa, (9002:16)
	sub wa, (9000:16)
	jr c, SeqVoice_InitRepeat_FinalCopy

SeqVoice_InitRepeat_CopyLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 8)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	inc 1, iz
	ld wa, (9002:16)
	sub wa, (9000:16)
	cp iz, wa
	jr ule, SeqVoice_InitRepeat_CopyLoop

SeqVoice_InitRepeat_FinalCopy:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	ld de, 1:i3
	calr Part_CopyBytesToVoiceBlock
	lda xwa, (9016:16)
	ldw	(xwa+128), (0x2328:16)
	ldw	(xwa+136), (0x2328:16)
	ldw wa, 0x11
	calr SeqCh_LoadChannelConfig
	ldw wa, 0x13
	ld bc, 1:i3
	call SeqPart_ReadEventStream
	popw iz
	inc 8, xsp
	ret

SeqVoice_ScanAndAssignParts:
	pushw_erp 0xfa
	ld bc, (0x28a8:16)
	cp bc, 0:i3
	jrl z, SeqVoice_ScanParts_Return
	ldib_erp 0xfb, 1

SeqVoice_ScanParts_PartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqVoice_ScanParts_ShiftDone
	slaa de

SeqVoice_ScanParts_ShiftDone:
	and de, bc
	jr nz, SeqVoice_ScanParts_CheckType
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqVoice_ScanParts_PartLoop

SeqVoice_ScanParts_CheckType:
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xe
	jr nz, SeqVoice_ScanParts_LoopNext
	cp (0x28be:16), 255
	jr z, SeqVoice_ScanParts_ReadGPIO
	ldto_berp A, 0xfb
	extz wa
	ld bc, 0:i3
	calr SeqVoice_SetOrClearBitMask
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xd
	ld (0x28be:16), 255
	jr SeqVoice_ScanParts_LoopNext

SeqVoice_ScanParts_ReadGPIO:
	lda xwa, (0xfc5a:16)
	ld e, (xwa + 3)
	and e, 0x7
	lda xbc, (xwa + 4)
	ld a, (xbc)
	and a, 0xf8
	or e, a
	ld (xbc), e
	extz de
	pushw 0x7
	ldw wa, 0x48
	ld bc, 4:i3
	call AddswbWr

SeqVoice_ScanParts_LoopNext:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	ldfr_berp A, 0xfa
	cp_erpb 0xfb, 0x10
	jr ugt, SeqVoice_ScanParts_Epilogue

SeqVoice_ScanParts_Continue:
	ldto_berp A, 0xfa
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xe
	jr nz, SeqPos_AdvanceToNextBar
	cp (0x28be:16), 255
	jr z, SeqPos_AdvanceToNextBar
	ldto_berp A, 0xfa
	extz wa
	ld bc, 0:i3
	calr SeqVoice_SetOrClearBitMask
	ldto_berp A, 0xfa
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xd
	ld (0x28be:16), 255

SeqPos_AdvanceToNextBar:
	ldto_berp A, 0xfa
	extz wa
	calr SeqVoice_DeactivateAndReinit
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqVoice_ScanParts_Continue

SeqVoice_ScanParts_Epilogue:
	calr Accomp_ValidateAutoPlayChordVoice

SeqVoice_ScanParts_Return:
	popw_erp 0xfa
	ret

VoiceAlloc_ProcessAll:
	push xiz
	call Part_ReinitAllActive
	pop xiz
	ret

SeqVoice_FindChannelSetup:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), 0x0
	ld (xsp + 8), 0x1

SeqPosAdv_CheckEndMark:
	ld a, (0x00ffe3:24)
	inc 1, a
	cp a, (xsp + 8)
	jr nz, SeqPosAdv_CheckBarEnd
	ld (xsp + 4), 0x0
	jr SeqPosAdv_AdvanceAndLoop

SeqPosAdv_CheckBarEnd:
	ld a, (xsp + 8)
	ld (xsp + 4), a

SeqPosAdv_AdvanceAndLoop:
	ld (xsp + 6), 0x1

SeqPosAdv_Return:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jrl z, PartCtrl_IncrAndLoop
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	calr Part_ReadVoiceWord
	ld (xsp + 10), hl
	cpw (xsp + 10), 0xffff
	jrl z, PartCtrl_IncrAndLoop
	cpw (xsp + 10), 0xffff
	jrl z, PartCtrl_IncrAndLoop

PartCtrl_CompareWordValues:
	cpw (xsp + 10), 0x1
	jr z, PartCtrl_SetupLinkedCopy
	cpw (xsp + 10), 0x2
	jrl nz, PartCtrl_ReadWordCheck

PartCtrl_SetupLinkedCopy:
	ld (xsp + 14), 0x1
	ldmw2 (xsp + 12), 0xf22f
	cpw (xsp + 12), 0x1
	jr nz, PartCtrl_CheckValue2

PartCtrl_SkipLinkedEntries:
	ld wa, (xsp + 12)
	calr PartCtrl_ReadWord
	ld (xsp + 12), hl
	cpw (xsp + 12), 0x1
	jr z, PartCtrl_SkipLinkedEntries

PartCtrl_CheckValue2:
	cpw (xsp + 12), 0x2
	jr z, PartCtrl_SkipLinkedEntries
	ld wa, (xsp + 12)
	calr PartCtrl_ReadWord
	ld iz, hl
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld xwa, (7514:16)
	ld xiy, xwa
	ld ix, (xsp + 10)
	extz xix
	dec 1, xix
	sll xix, 8
	ld xiz, xwa
	ld hl, (xsp + 12)
	extz xhl
	dec 1, xhl
	sll xhl, 8
	ld de, 0:i3

PartCtrl_CopyBlockLoop:
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xhl
	add xbc, xiz
	add xwa, xix
	add xwa, xiy
	ld a, (xwa)
	ld (xbc), a
	inc 1, de
	cp de, 0x100
	jr c, PartCtrl_CopyBlockLoop
	ld wa, (xsp + 10)
	calr PartCtrl_ReadWord_Off1
	ld wa, hl
	cp wa, 0:i3
	jr z, PartCtrl_UpdateVoiceWord
	ld bc, (xsp + 12)
	calr PartCtrl_WriteWord
	jr PartCtrl_ReadAndRelinkNext

PartCtrl_UpdateVoiceWord:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 12)
	calr Part_WriteVoiceWord
	ld a, (xsp + 8)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, PartCtrl_ReadAndRelinkNext
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	ld de, (xsp + 12)
	calr Part_WriteVoiceWord

PartCtrl_ReadAndRelinkNext:
	ld wa, (xsp + 10)
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, PartCtrl_WriteIndexedAndCheck
	ld bc, (xsp + 12)
	calr PartCtrl_WriteWord_Off1
	jr PartCtrl_ReadWordCheck

PartCtrl_WriteIndexedAndCheck:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 12)
	calr Part_WriteWord_Indexed
	ld a, (xsp + 8)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, PartCtrl_ReadWordCheck
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	ld de, (xsp + 12)
	calr Part_WriteWord_Indexed

PartCtrl_ReadWordCheck:
	ld wa, (xsp + 10)
	calr PartCtrl_ReadWord
	ld (xsp + 10), hl
	cpw (xsp + 10), 0xffff
	jrl nz, PartCtrl_CompareWordValues

PartCtrl_IncrAndLoop:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x10
	jrl ule, SeqPosAdv_Return
	incm8 1, (xsp + 8)
	cp (xsp + 8), 0xa
	jrl ule, SeqPosAdv_CheckEndMark
	cp (xsp + 14), 0x1
	jr nz, PartCtrl_CheckUnlinkFlag
	ld wa, 1:i3
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	ld wa, 1:i3
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, 1:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, 1:i3
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	ld wa, 2:i3
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	ld wa, 2:i3
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, 2:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, 2:i3
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	jr PartCtrl_DeallocReturn

PartCtrl_CheckUnlinkFlag:
	cpw (0xf22f:16), 1
	jr nz, PartCtrl_DeallocVoices
	calr Part_UnlinkVoiceFromChain
	jr PartCtrl_DeallocReturn

PartCtrl_DeallocVoices:
	calr Part_DeallocVoices1And2

PartCtrl_DeallocReturn:
	pop xiz
	lda xsp, (xsp + 12)
	ret

Part_ReleaseVoicesForRange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), c
	ld (xsp + 12), a
	cp (xsp + 12), 0xb
	jr nz, PartRelRange_SetCurrentMode
	ldib_erp 0xfb, 0
	ld (xsp + 4), 0xa
	jr PartRelRange_CheckAllParts

PartRelRange_SetCurrentMode:
	ld a, (xsp + 12)
	ldfr_berp A, 0xfb
	ld (xsp + 4), a

PartRelRange_CheckAllParts:
	cp (xsp + 10), 0x32
	jr nz, PartRelRange_SetSinglePart
	ld (xsp + 6), 0x1
	ld (xsp + 8), 0x10
	jr PartRelRange_CheckInitChain

PartRelRange_SetSinglePart:
	ld a, (xsp + 10)
	ld (xsp + 6), a
	ld (xsp + 8), a

PartRelRange_CheckInitChain:
	cp (xsp + 12), 0xb
	jr nz, PartRelRange_OuterLoop
	cp (xsp + 10), 0x32
	jr nz, PartRelRange_OuterLoop
	calr PartCtrl_InitChainLinkedList
	ldw (0x00ffec:24), 0x0000
	calr Part_UnlinkVoiceFromChain

PartRelRange_OuterLoop:
	ldto_berp A, 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl ugt, PartRelRange_OuterNext

PartRelRange_InnerLoop:
	ld a, (xsp + 6)
	ldfr_berp A, 0xfa
	cp a, (xsp + 8)
	jrl ugt, PartRelRange_InnerNext

PartRelRange_ClearAndWrite:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	calr Part_ReadVoiceWord
	ld iz, hl
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ld de, 5:i3
	calr Part_WriteByte_Indexed
	cp (xsp + 12), 0xb
	jr nz, PartRelRange_StealVoices
	cp (xsp + 10), 0x32
	jr z, PartRelRange_WriteDefaults

PartRelRange_StealVoices:
	ld wa, iz
	calr Part_StealAndReallocVoices

PartRelRange_WriteDefaults:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1c
	ld de, 0:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	calr Part_WriteByte
	inc1b_erp 0xfa
	ldto_berp A, 0xfa
	cp a, (xsp + 8)
	jrl ule, PartRelRange_ClearAndWrite

PartRelRange_InnerNext:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jrl ule, PartRelRange_InnerLoop

PartRelRange_OuterNext:
	pushw 0x1
	ldw wa, 0x91
	ld bc, 3:i3
	ld de, 0:i3
	call AddswbWr
	pop xiz
	lda xsp, (xsp + 10)
	ret

Part_ClearAndStealSingleVoice:
	dec 4, xsp
	ld (xsp + 2), a
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	ld (xsp), hl
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	calr Part_WriteByte_Indexed
	ld wa, (xsp)
	calr Part_StealAndReallocVoices
	inc 4, xsp
	ret

SeqParams_InitDefaults:
	ld (0xf1d2:16), 0
	ldw (9704:16), 0
	ld (0xf1d3:16), 1
	ld (0xf1d4:16), 2
	ld (0xf1d5:16), 3
	ld (0xf1d6:16), 1
	ldw (0xf1d7:16), 1
	ldw (0xf1d9:16), 1
	ldw (9772:16), 1
	ld (0xf1db:16), 1
	ldw (0xf1dc:16), 1
	ldw (0xf1de:16), 1
	ldw (9766:16), 1
	ld (0xf1e0:16), 0
	ld (0xf1e1:16), 1
	ldw (0xf1e2:16), 1
	ldw (0xf1e4:16), 1
	ld (0xf1e6:16), 1
	ldw (0xf1e7:16), 1
	ldw (9774:16), 1
	ld (9776:16), 0
	ld (0xf1e9:16), 1
	ldw (0xf1ea:16), 1
	ldw (0xf1ec:16), 1
	ld (0xf1ee:16), 1
	ldw (0xf1ef:16), 1
	ld (9770:16), 0
	ldw (9768:16), 1
	ld (0xf228:16), 1
	ldw (0xf229:16), 1
	ldw (0xf22b:16), 1
	ldw (9722:16), 1
	ld (0xf22d:16), 0
	ld (0xf22e:16), 0
	ld (0xf233:16), 0
	ld (0xf234:16), 0
	ld (0xf1f1:16), 1
	ldw (0xf1f2:16), 1
	ldw (0xf1f4:16), 1
	ldw (9724:16), 1
	ld (0xf1f6:16), 3
	ld (9702:16), 0
	ld (9728:16), 100
	ld (9730:16), 100
	ld (9742:16), 1
	ldw (9744:16), 1
	ldw (9746:16), 1
	ldw (9748:16), 1
	ld (9750:16), 60
	ld (9816:16), 60
	ldw (9754:16), 1
	ld (9756:16), 1
	ldw (9758:16), 1
	ldw (9760:16), 1
	ld (9762:16), 0
	ld (9764:16), 1
	ld (9732:16), 1
	ldw (9734:16), 1
	ldw (9736:16), 1
	ldw (9738:16), 1
	ld (9740:16), 0
	ret

Seq_ValidatePartNumber:
	cp a, 1:i3
	jr c, SeqValidate_PartFail
	cp a, (0x28a1:16)
	jr ule, SeqValidate_PartOK

SeqValidate_PartFail:
	ldw hl, 0xffff
	ret

SeqValidate_PartOK:
	ld hl, 0:i3
	ret

Seq_ValidateTempoValue:
	cp wa, 1:i3
	jr c, SeqValidate_TempoFail
	cp wa, 0x3e7
	jr ule, SeqValidate_TempoOK

SeqValidate_TempoFail:
	ldw hl, 0xffff
	ret

SeqValidate_TempoOK:
	ld hl, 0:i3
	ret

Seq_ValidateAllParams_DataBlock:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, Seq_ValidateAllParams_DataBlock_Skip
	extz	wa
	calr	Seq_ValidatePartNumber
	cp	hl, 0:i3
	jr	nz, Seq_ValidateAllParams_DataBlock_Skip2
	ld	a, (9858:16)
	extz	wa
	calr	Seq_ValidatePartNumber
	cp	hl, 0:i3
	jr	nz, Seq_ValidateAllParams_DataBlock_Skip2
Seq_ValidateAllParams_DataBlock_Skip:
	ld	wa, (9778:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	nz, Seq_ValidateAllParams_DataBlock_Skip2
	ld	wa, (9694:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	nz, Seq_ValidateAllParams_DataBlock_Skip2
	ld	wa, (9862:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	z, Seq_ValidateAllParams_DataBlock_Skip3
Seq_ValidateAllParams_DataBlock_Skip2:
	ldw	hl, 0xffff
	ret
Seq_ValidateAllParams_DataBlock_Skip3:
	ld	hl, 0:i3
	ret

Seq_ValidatePartAndTempo:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPT_CheckTempoValues
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, Seq_TempoValidationFailReturn
	ld a, (9858:16)
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, Seq_TempoValidationFailReturn

SeqValPT_CheckTempoValues:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, Seq_TempoValidationFailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, Seq_TempoValidationFailReturn
	ld wa, (9862:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr z, SeqValPT_ReturnOK

Seq_TempoValidationFailReturn:
	ldw hl, 0xffff
	ret

SeqValPT_ReturnOK:
	ld hl, 0:i3
	ret

Seq_ValidatePartTempoAndKey:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPTK_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	ret nz

SeqValPTK_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	ret nz
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	ret nz
	ld a, (9726:16)
	extz wa
	cp wa, 0:i3
	jr mi, SeqValPTK_ClampKeyValue
	cp wa, 0xc
	jr le, SeqValPTK_LookupAndReturn

SeqValPTK_ClampKeyValue:
	ldw wa, 0xd

SeqValPTK_LookupAndReturn:
	lda xix, (SeqValPTK_LookupAndReturn_Table:24)
	ld	l, (xix+wa)
	exts hl
	ret

Seq_ValidatePartTempoAndMode:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPTM_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqPart_ErrorReturnFFFF

SeqValPTM_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqPart_ErrorReturnFFFF
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqPart_ErrorReturnFFFF
	ld a, (9808:16)
	cp a, 0:i3
	jr z, SeqPart_SuccessReturn
	cp a, 1:i3
	jr z, SeqPart_SuccessReturn
	cp a, 2:i3
	jr z, SeqPart_SuccessReturn

SeqPart_ErrorReturnFFFF:
	ldw hl, 0xffff
	ret

SeqPart_SuccessReturn:
	ld hl, 0:i3
	ret

Seq_ValidatePartAndTempoAlt:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValPTA_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqValPTA_FailReturn

SeqValPTA_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqValPTA_FailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr z, SeqValPTA_OKReturn

SeqValPTA_FailReturn:
	ldw hl, 0xffff
	ret

SeqValPTA_OKReturn:
	ld hl, 0:i3
	ret

Seq_ValidateExtended_DataBlock:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, Seq_ValidateExtended_DataBlock_Skip
	extz	wa
	calr	Seq_ValidatePartNumber
	cp	hl, 0:i3
	jr	nz, Seq_ValidateExtended_DataBlock_Skip2
Seq_ValidateExtended_DataBlock_Skip:
	ld	wa, (9778:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	nz, Seq_ValidateExtended_DataBlock_Skip2
	ld	wa, (9694:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	z, Seq_ValidateExtended_DataBlock_Skip3
Seq_ValidateExtended_DataBlock_Skip2:
	ldw	hl, 0xffff
	ret
Seq_ValidateExtended_DataBlock_Skip3:
	ld	hl, 0:i3
	ret

SeqPos_DecrementAndCheck:
	dec 2, xsp
	push xiz
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld wa, (9830:16)
	ld (xsp + 4), wa
	dec 1, wa
	ld (9830:16), wa
	cp wa, 5:i3
	jr nc, SeqPosDec_Return
	ld wa, (0x28af:16)
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	cp iz, 0:i3
	jr z, SeqPosDec_HandleInvalid
	cp iz, 0x4d8
	jr ule, SeqPosDec_TestBit7

SeqPosDec_HandleInvalid:
	ld (SEQ_ERROR_CODE:16), 10
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	ldw wa, 0x50
	jr SeqPosDec_SetErrorCode

SeqPosDec_TestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, SeqPosDec_StorePosition
	ld (SEQ_ERROR_CODE:16), 11
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	ldw wa, 0x51

SeqPosDec_SetErrorCode:
	calr SeqData_SetErrorCode
	jr SeqPosDec_Return

SeqPosDec_StorePosition:
	ld (0x28af:16), iz
	ldw (9830:16), 255

SeqPosDec_Return:
	pop xiz
	inc 2, xsp
	ret

; SeqVoice_InitEntryForCurrentBank (named 2026-09-25, lane seqeng; it was
; labelled SeqPos_DataBlock and spelled partly as .byte, but it is a routine
; with two callers in this file).  Runs SeqVoice_InitEntry with the byte at
; 0x2878 temporarily replaced by the byte at 0xFFE3, then restores 0x2878
; (kept in QIZH meanwhile; QIZ is pushed and popped).  0xFFE3 is the index
; FloppyIO_ComputeSwitchboardAddr uses to pick one of the ten 0x800-byte
; records at DRAM 0xAB000, and SMF_SelectBankAndLoad is what stores it.
SeqVoice_InitEntryForCurrentBank:
	push	qiz
	ld	a, (0x2878:16)
	ldfr_berp	a, 251
	; ld (0x2878),(0x00ffe3)
	ld	(0x2878:16), (0xffe3:24)
	call	SeqVoice_InitEntry
	ldto_berp	a, 251
	ld	(0x2878:16), a
	pop qiz
	ret
	calr	SeqVoice_FindDrumPartIndex
	ldmm16	10367, 9832
	extz	hl
	ld	wa, hl
	ld	bc, hl
	calr	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jr	z, SeqPos_DataBlock_Code_Entry
	ldmm8	9818, 1075
	ret
SeqPos_DataBlock_Code_Entry:
	ldmm8	9818, 10382
	ret

Seq_ValidatePartTempoAndRange:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValPTR_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, Seq_ValidationFailReturn

SeqValPTR_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, Seq_ValidationFailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, Seq_ValidationFailReturn
	cp (9750:16), 127
	jr ugt, Seq_ValidationFailReturn
	cp (9816:16), 127
	jr ule, SeqValRange_CheckBounds

Seq_ValidationFailReturn:
	ldw hl, 0xffff
	ret

SeqValRange_CheckBounds:
	ld hl, 0:i3
	ret

SeqValRange_ReturnOK:
	push	qiz
	ld	a, (0x2878:16)
	ldfr_berp	a, 251
	ldmm8	10360, 10026
	calr	SeqVoice_InitAllChannelParams
	ldto_berp	a, 251
	ld	(0x2878:16), a
	pop qiz
	ret

SeqVoice_InitAllChannelParams:
	push xiz
	calr SeqVoice_SetDefaultParams
	ld a, (0x2877:16)
	ldfr_berp A, 0xfa
	ld (0x2877:16), 1
	ld a, (0x2878:16)
	cp a, (0xffe3:24)
	jr nz, SeqDispatch_ValidateParam
	ldib_erp 0xfb, 0
	jr SeqDispatch_ParamFail

SeqDispatch_ValidateParam:
	inc 1, a
	ldfr_berp A, 0xfb

SeqDispatch_ParamFail:
	ldib_erp 0xf9, 1

SeqDispatch_ParamOK:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xf9
	extz bc
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqTempo_CheckAndClamp
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xf9
	extz bc
	calr Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	call nz, (Part_StealAndReallocVoices:24)

SeqTempo_CheckAndClamp:
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqDispatch_ParamOK
	ldib_erp 0xf9, 1

SeqTempo_ClampedReturn:
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xf9
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xf9
	extz bc
	ld de, 5:i3
	calr Part_WriteByte_Indexed
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqTempo_ClampedReturn
	ldib_erp 0xf9, 1

SeqTempo_ApplyAndReturn:
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xf9
	extz bc
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xf9
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqTempo_ApplyAndReturn
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0x1e
	ld de, 0:i3
	calr Part_WriteWord
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0x1c
	ld de, 0:i3
	calr Part_WriteWord
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	calr Part_WriteByte
	ld a, (0x2878:16)
	cp a, (0xffe3:24)
	jr nz, SeqBufPos_HandleOverflow
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	ldw (0x00ffec:24), 0x0000
	ldw (0xf19c:16), 0
	ld (0xf24b:16), 0
	ldib_erp 0xf9, 1

SeqBufPos_UpdateAndSync:
	ldto_berp C, 0xf9
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xf9
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	calr Part_WriteByte_Indexed
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqBufPos_UpdateAndSync
	ldib_erp 0xf9, 1

SeqBufPos_CheckLimit:
	ldto_berp C, 0xf9
	extz bc
	ld wa, 0:i3
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ldto_berp C, 0xf9
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqBufPos_CheckLimit

SeqBufPos_HandleOverflow:
	ldto_berp A, 0xfa
	ld (0x2877:16), a
	pop xiz
	ret

SeqBufPos_WrapAround:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1

SeqBufPos_StoreResult:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1c
	ld de, 0:i3
	calr Part_WriteWord
	ldib_erp 0xfa, 1

SeqBufPos_Return:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	ld de, 5:i3
	calr Part_WriteByte_Indexed
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqBufPos_Return
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1e
	ld de, 0:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	calr Part_WriteByte
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqBufPos_StoreResult
	ldw (0xf19e:16), 0
	ldw (0x00ffec:24), 0x0000
	call Audio_CheckSubsystemReady
	ld (0xf24b:16), 0
	calr SeqStatus_ResetAndSendCmd
	ldw (0x2875:16), 0
	ldw (0x00ffec:24), 0x0000
	popw_erp 0xfa
	ret

SeqAccPlay_InitAndDispatch:
	ld a, (0x2877:16)
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqPart_ErrorReturn
	ld a, (9858:16)
	cp (0x2877:16), a
	jr z, SeqPart_ErrorReturn
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqPart_ErrorReturn
	ld a, (9860:16)
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr z, SeqAccPlay_Return

SeqPart_ErrorReturn:
	ldw hl, 0xffff
	ret

SeqAccPlay_Return:
	ld hl, 0:i3
	ret

; ============================================================================
; PartCtrl_AdvanceReadPos - Advance read cursor through part control data
; ============================================================================
; Reads 16-bit counter from DRAM[10377]. If not at max (0xff), increments.
; At max, advances to next data block via PartCtrl_ReadWord, validates
; bit 7 flag. Sets error code 2 on validation failure.
; ============================================================================
PartCtrl_AdvanceReadPos:
	pushw iz
	ld wa, (0x2889:16)
	cp wa, 0xff
	jr z, PartCtrl_AdvancePos_AtMax
	inc 1, wa
	ld (0x2889:16), wa
	jr PartCtrl_AdvancePos_Return

PartCtrl_AdvancePos_AtMax:
	ld wa, (0x288b:16)
	calr PartCtrl_ReadWord
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartCtrl_AdvancePos_SaveNew
	ld (SEQ_ERROR_CODE:16), 2
	jr PartCtrl_AdvancePos_Return

PartCtrl_AdvancePos_SaveNew:
	ld (0x288b:16), iz
	ldw (0x2889:16), 5

PartCtrl_AdvancePos_Return:
	popw iz
	ret

PartCtrl_NavigateBackward:
	pushw iz
	ld wa, (0x2889:16)
	cp wa, 5:i3
	jr z, PartCtrl_NavBack_AtMin
	dec 1, wa
	ld (0x2889:16), wa
	jr SeqPart_RestoreReturn3

PartCtrl_NavBack_AtMin:
	ld wa, (0x288b:16)
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartCtrl_NavBack_CheckZero
	ldw wa, 0x47
	calr SeqData_SetErrorCode
	ld (SEQ_ERROR_CODE:16), 2
	jr SeqPart_RestoreReturn3

PartCtrl_NavBack_CheckZero:
	cp iz, 0:i3
	jr z, PartCtrl_NavBack_ErrorEnd
	cp iz, 0xffff
	jr nz, PartCtrl_NavBack_SaveNew

PartCtrl_NavBack_ErrorEnd:
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqPart_RestoreReturn3

PartCtrl_NavBack_SaveNew:
	ld (0x288b:16), iz
	ldw (0x2889:16), 255

SeqPart_RestoreReturn3:
	popw iz
	ret

PartCtrl_AdvanceToNextEntry:
	pushw iz
	ld wa, (0x2885:16)
	cp wa, 0xff
	jr z, PartCtrl_AdvanceEntry_AtMax
	inc 1, wa
	ld (0x2885:16), wa
	jr PartCtrl_RestoreReturn

PartCtrl_AdvanceEntry_AtMax:
	ld wa, (0x2887:16)
	calr PartCtrl_ReadWord
	ld iz, hl
	ld wa, iz
	cp wa, 0xffff
	jr nz, PartCtrl_AdvanceEntry_TestBit7
	ld wa, (0x2887:16)
	calr Part_LinkVoiceToChain
	ld iz, hl
	cp iz, 0:i3
	jr ge, PartCtrl_SaveChainPosition
	ld (SEQ_ERROR_CODE:16), 5
	jr PartCtrl_RestoreReturn

PartCtrl_AdvanceEntry_TestBit7:
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartCtrl_SaveChainPosition
	ld (SEQ_ERROR_CODE:16), 2
	jr PartCtrl_RestoreReturn

PartCtrl_SaveChainPosition:
	ld (0x2887:16), iz
	ldw (0x2885:16), 5

PartCtrl_RestoreReturn:
	popw iz
	ret

PartCtrl_NavigateBackwardAlt:
	pushw iz
	ld wa, (0x2885:16)
	cp wa, 5:i3
	jr z, PartCtrl_NavBackAlt_AtMin
	dec 1, wa
	ld (0x2885:16), wa
	jr SeqPart_RestoreReturn2

PartCtrl_NavBackAlt_AtMin:
	ld wa, (0x2887:16)
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartCtrl_NavBackAlt_CheckZero
	ldw wa, 0x48
	calr SeqData_SetErrorCode
	ld (SEQ_ERROR_CODE:16), 2
	jr SeqPart_RestoreReturn2

PartCtrl_NavBackAlt_CheckZero:
	cp iz, 0:i3
	jr z, PartCtrl_NavBackAlt_ErrorEnd
	cp iz, 0xffff
	jr nz, PartCtrl_NavBackAlt_SaveNew

PartCtrl_NavBackAlt_ErrorEnd:
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqPart_RestoreReturn2

PartCtrl_NavBackAlt_SaveNew:
	ld (0x2887:16), iz
	ldw (0x2885:16), 255

SeqPart_RestoreReturn2:
	popw iz
	ret

; ============================================================================
; SeqPart_ReadByte_Secondary - Read byte from secondary sequencer part buffer
; ============================================================================
; Input:  Implicit (reads from secondary part state)
; Output: A = byte value from secondary buffer
; Reads a byte from the secondary (background) sequencer part data stream.
; ============================================================================
SeqPart_ReadByte_Secondary:
	ld wa, (0x2889:16)
	ld c, a
	extz bc
	ld wa, (0x288b:16)
	jrl PartCtrl_ReadByte

SeqPart_ReadByte_Primary:
	ld wa, (0x2885:16)
	ld c, a
	extz bc
	ld wa, (0x2887:16)
	jrl PartCtrl_ReadByte

SeqPart_WriteByte_Secondary:
	ld e, a
	ld bc, (0x2889:16)
	extz bc
	extz de
	ld wa, (0x288b:16)
	jrl PartCtrl_WriteByteToBuf

; ============================================================================
; SeqPart_WriteByte_Primary - Write byte to primary sequencer part buffer
; ============================================================================
; Input:  A = byte value to write
; Output: None
; Writes a byte to the primary (foreground) sequencer part data stream.
; ============================================================================
SeqPart_WriteByte_Primary:
	ld e, a
	ld bc, (0x2885:16)
	extz bc
	extz de
	ld wa, (0x2887:16)
	jrl PartCtrl_WriteByteToBuf

Part_ValidateVoiceChannel:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, Part_ValidateVoice_ReadWord
	ld (SEQ_ERROR_CODE:16), 1
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_ReadWord:
	ld c, (xsp + 2)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr nz, Part_ValidateVoice_CheckFFFF
	ld (SEQ_ERROR_CODE:16), 2
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_CheckFFFF:
	cp iz, 0x4d8
	jr ule, Part_ValidateVoice_CheckOverflow
	ld (SEQ_ERROR_CODE:16), 10
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_CheckOverflow:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, Part_ValidateVoice_SetPosition
	ld (SEQ_ERROR_CODE:16), 11
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_SetPosition:
	ld (0x28af:16), iz
	ldw (9830:16), 5
	ld (SEQ_ERROR_CODE:16), 0

PartCtrl_ConfigureAndReturn:
	popw iz
	inc 2, xsp
	ret

Part_ValidateVoiceAndSetupSeq:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	calr Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_DecisionReturn
	ld c, (xsp)
	dec 1, c
	extz bc
	lda xwa, (0xf218:16)
	ld de, bc
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	cp de, 5:i3
	jr c, Part_ValidateSetup_ErrorEnd
	cp de, 0xff
	jr ugt, Part_ValidateSetup_ErrorEnd
	add bc, bc
	lda xwa, (0xf1f8:16)
	extz xbc
	add xbc, xwa
	ld wa, (xbc)
	cp wa, 0x4d8
	jr ule, Part_ValidateSetup_StorePos
	ld (SEQ_ERROR_CODE:16), 10
	jr SeqPart_DecisionReturn

Part_ValidateSetup_StorePos:
	ld (0x28af:16), wa
	ld (9830:16), de
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr z, Part_ValidateSetup_CheckBarMark
	cp l, 0x84
	jr z, Part_ValidateSetup_CheckBarMark

Part_ValidateSetup_ErrorEnd:
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqPart_DecisionReturn

Part_ValidateSetup_CheckBarMark:
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_DecisionReturn:
	inc 2, xsp
	ret

SeqTrack_LookupChannelData:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, Part_ValidateVoiceAndSetupSeq_Skip
	extz	wa
	calr	Seq_ValidatePartNumber
	cp	hl, 0:i3
	jr	nz, Part_ValidateVoiceAndSetupSeq_Skip2
Part_ValidateVoiceAndSetupSeq_Skip:
	ld	wa, (9778:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	nz, Part_ValidateVoiceAndSetupSeq_Skip2
	ld	wa, (9694:16)
	calr	Seq_ValidateTempoValue
	cp	hl, 0:i3
	jr	nz, Part_ValidateVoiceAndSetupSeq_Skip2
	ld	a, (9812:16)
	cp	a, 128
	jr	nz, Part_ValidateVoiceAndSetupSeq_Skip3
Part_ValidateVoiceAndSetupSeq_Skip2:
	ldw	hl, 0xffff
	ret
Part_ValidateVoiceAndSetupSeq_Skip3:
	ld	hl, 0:i3
	ret

SeqPart_LoadAndValidateData:
	pushw_erp 0xfa
	ld a, (9770:16)
	cp a, 0:i3
	jr z, Part_PopRetFA2
	bit 3, (0x287b:16)
	jr nz, Part_PopRetFA2
	ld a, (0xf1ee:16)
	cp a, 0x11
	jr nz, SeqPart_StoreChannelParams
	ld a, 0x7f:opc

SeqPart_StoreChannelParams:
	ld (0x2877:16), a
	ld wa, (0xf1ef:16)
	ld (9778:16), wa
	ld wa, (0xf1ef:16)
	add wa, (9694:16)
	ld (9862:16), wa
	ldib_erp 0xfb, 0
	ld a, (9770:16)
	cp a, 0:i3
	jr ule, Part_PopRetFA2

SeqPart_LoadDualPartLoop:
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_DualPartLoad
	cp (GLOBAL_ERROR_CODE:16), 35
	jr nz, Part_PopRetFA2
	bit 3, (0x287b:16)
	jr nz, Part_PopRetFA2
	ld wa, (9862:16)
	add wa, (9694:16)
	ld (9862:16), wa
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (9770:16)
	jr c, SeqPart_LoadDualPartLoop

Part_PopRetFA2:
	popw_erp 0xfa
	ret

SeqPart_LoadDualPartData:
	push	qiz
	ld	a, (9776:16)
	cp	a, 0:i3
	jr	z, SeqPart_LoadDualPartData_Code_Epilogue
	bit	3, (10363:16)
	jr	nz, SeqPart_LoadDualPartData_Code_Epilogue
	ld	a, (0xf1e6:16)
	cp	a, 17
	jr	nz, SeqPart_LoadDualPartData_Skip
	ld	a, 127:opc
SeqPart_LoadDualPartData_Skip:
	ld	(0x2877:16), a
	ld	wa, (0xf1e7:16)
	ld	(9778:16), wa
	ld	wa, (0xf1e7:16)
	add wa, (9694:16)
	ld	(9862:16), wa
	ldib_erp 251, 0
	ld	a, (9776:16)
	cp	a, 0:i3
	jr	ule, SeqPart_LoadDualPartData_Code_Epilogue
SeqPart_LoadDualPartData_Code_Loop:
	ld	(GLOBAL_ERROR_CODE:16), 255
	ld	(SEQ_ERROR_CODE:16), 0
	call	SeqPart_ByteBlockA95A
	cp	(GLOBAL_ERROR_CODE:16), 35
	jr	nz, SeqPart_LoadDualPartData_Code_Epilogue
	bit	3, (10363:16)
	jr	nz, SeqPart_LoadDualPartData_Code_Epilogue
	ld	wa, (9862:16)
	add wa, (9694:16)
	ld	(9862:16), wa
	inc1b_erp 251
	ldto_berp a, 251
	cp a, (9776:16)
	jr	c, SeqPart_LoadDualPartData_Code_Loop
SeqPart_LoadDualPartData_Code_Epilogue:
	pop qiz
	ret

SeqVoice_SeekToBar:
	push xiz
	ld iz, 1:i3
	ldiw_erp 0xfa, 0
	ld (SEQ_ERROR_CODE:16), 0
	ld (0x288d:16), c
	extz wa
	calr Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_PopIzRet2
	calr SeqVoice_ValidateAndProcessState
	cpw (0x287f:16), 1
	jr z, SeqVoice_PopIzRet2

SeqVoice_SeekBarLoop:
	ld a, (0x288e:16)
	extz wa
	ldto_werp BC, 0xfa
	calr SeqData_SkipSections
	ldfr_werp HL, 0xfa
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_PopIzRet2
	inc 1, iz
	calr SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_PopIzRet2
	cp iz, (0x287f:16)
	jr nz, SeqVoice_SeekBarLoop

SeqVoice_PopIzRet2:
	pop xiz
	ret

SeqData_SkipSections:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), bc
	ld (xsp + 4), a
	ldib_erp 0xfb, 0
	cp (xsp + 4), 0x0
	jr z, SeqData_UpdatePositionAndReturn

SeqData_SkipReadLoop:
	calr SeqData_ReadNextByte
	cp l, 0x84
	jr z, SeqData_SkipEndMarkerError
	cp l, 0x82
	jr nz, SeqData_SkipCheckBarMarker

SeqData_SkipEndMarkerError:
	ld (SEQ_ERROR_CODE:16), 8
	jr SeqData_UpdatePositionAndReturn

SeqData_SkipCheckBarMarker:
	cp l, 0x81
	jr nz, SeqData_SkipReadParamBlock
	inc1b_erp 0xfb
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqData_SkipCountBarsLoop
	jr SeqData_UpdatePositionAndReturn

SeqData_SkipReadParamBlock:
	call SeqData_ReadParamBlock
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_UpdatePositionAndReturn

SeqData_SkipCountBarsLoop:
	ldto_berp A, 0xfb
	cp a, (xsp + 4)
	jr nz, SeqData_SkipReadLoop

SeqData_UpdatePositionAndReturn:
	ldto_berp A, 0xfb
	extz wa
	add wa, (xsp + 2)
	ld hl, wa
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqVoice_SetDefaultParams:
	ld (0x28a1:16), 16
	ld (0x289e:16), 15
	ldmm16 0x28a2, 0x286d
	ld xwa, (7514:16)
	ld (3304:16), xwa
	ldw (3376:16), 0
	ret

SeqVoice_InitReturnZero:
	ld wa, 0:i3
	jrl Part_InitVoiceDefaults

; AppEvent extended handler
AppEvent_ExtendedHandler:
	ld xwa, AppEvent_ExtendedHandler_Table
	jr Part_LoadAndApplyVoiceTable
SeqPart_ByteBlockA95A_Helper:
	ld xwa, AppEvent_ExtendedHandler_Table_2
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableB:
	ld xwa, Part_ApplyVoiceTableB_Table
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableA:
	ld xwa, Part_ApplyVoiceTableA_Table
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableC:
	ld xwa, Part_ApplyVoiceTableC_Table
	jr Part_LoadAndApplyVoiceTable

SeqVoice_ApplyTableEntry:
	ld xwa, SeqVoice_ApplyTableEntry_Table
	jr Part_LoadAndApplyVoiceTable

Part_LoadAndApplyVoiceTable:
	ld c, (SEQ_ERROR_CODE:16)
	extz bc
	ld	(GLOBAL_ERROR_CODE:16), (xwa+bc)
	ret

Part_ValidateAndSetupVoiceChannel:
	dec 4, xsp
	pushw iz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr Part_ValidateVoiceChannel
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, Part_ValidateSetup_ClearAndProcess
	cp a, 1:i3
	jr nz, Part_ValidateSetup_ErrorReturn
	ld (SEQ_ERROR_CODE:16), 0

Part_ValidateSetup_ErrorReturn:
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_ClearAndProcess:
	ld (SEQ_ERROR_CODE:16), 0
	ld c, (xsp + 4)
	dec 1, c
	extz bc
	lda xwa, (0xf218:16)
	ld de, bc
	extz xde
	add xde, xwa
	ld a, (xde)
	ld (xsp + 2), a
	cp (xsp + 2), 0x5
	jr c, Part_ValidateSetup_NoData
	add bc, bc
	lda xwa, (0xf1f8:16)
	extz xbc
	add xbc, xwa
	ld iz, (xbc)
	cp iz, 0x4d8
	jr ule, Part_ValidateSetup_TestBit7
	ld (SEQ_ERROR_CODE:16), 10
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_TestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, Part_ValidateSetup_StoreAndRead

Part_ValidateSetup_NoData:
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_StoreAndRead:
	ld (0x28af:16), iz
	ld a, (xsp + 2)
	extz wa
	ld (9830:16), wa
	calr SeqData_ReadNextByte
	cp l, 0x84
	jr nz, SeqData_TrackProcessComplete
	ld (SEQ_ERROR_CODE:16), 6

SeqData_TrackProcessComplete:
	popw iz
	inc 4, xsp
	ret

SeqData_ScanAllTracks:
	push xiz
	ld iz, 0:i3
	ld xwa, 1:i3
	ld (9690:16), xwa
	res 1, (0x287b:16)
	cpw (9694:16), 0
	jr z, SeqData_PopIzRet

SeqData_ScanTracks_OuterLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqData_ScanTracks_NextTrack

SeqData_ScanTracks_InnerLoop:
	bit 1, (0x287b:16)
	jr z, SeqData_ScanTracks_SetFlag
	ld xwa, 1:i3
	add (9690:16), xwa
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_PopIzRet

SeqData_ScanTracks_SetFlag:
	set 1, (0x287b:16)
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqData_ScanTracks_Check81
	ld (SEQ_ERROR_CODE:16), 7
	jr SeqData_PopIzRet

SeqData_ScanTracks_Check81:
	cp l, 0x81
	jr nz, SeqData_ScanTracks_CheckCount
	inc1w_erp 0xfa

SeqData_ScanTracks_CheckCount:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqData_ScanTracks_InnerLoop

SeqData_ScanTracks_NextTrack:
	inc 1, iz
	calr SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_PopIzRet
	cp iz, (9694:16)
	jr nz, SeqData_ScanTracks_OuterLoop

SeqData_PopIzRet:
	pop xiz
	ret

; ============================================================================
; SeqData_AdvancePosition - Advance read position in sequence data
; ============================================================================
; Increments position counter at address 9830. When it reaches 0xff,
; advances the data pointer (10415) to the next block, validating:
;   0xffff = end of data, > 0x4d8 = overflow error
; Sets error codes in 10362 (values 8, 10, 11, 0).
; ============================================================================
SeqData_AdvancePosition:
	pushw iz
	ld wa, (9830:16)
	inc 1, wa
	ld (9830:16), wa
	cp wa, 0xff
	jr ule, SeqData_PopIzRet2
	ld wa, (0x28af:16)
	calr PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqData_CheckPositionLimit
	ld (SEQ_ERROR_CODE:16), 8
	jr SeqData_PopIzRet2

SeqData_CheckPositionLimit:
	cp iz, 0x4d8
	jr ule, SeqData_ReadAndTestBit7
	ld (SEQ_ERROR_CODE:16), 10
	jr SeqData_PopIzRet2

SeqData_ReadAndTestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, SeqData_StoreNewPosition
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqData_PopIzRet2

SeqData_StoreNewPosition:
	ld (0x28af:16), iz
	ldw (9830:16), 5
	ld (SEQ_ERROR_CODE:16), 0

SeqData_PopIzRet2:
	popw iz
	ret

SeqVoice_FindDrumPartIndex:
	ld a, (0x287b:16)
	res 2, a
	ld (0x287b:16), a
	ld l, 0x0:opc
	lda xde, (0xf1a0:16)

SeqVoice_DrumSearchLoop:
	ld c, l
	extz bc
	extz xbc
	add xbc, xde
	cp (xbc), 0x10
	jr nz, SeqVoice_DrumSearchNext
	set 2, a
	ld (0x287b:16), a
	inc 1, l
	ret

SeqVoice_DrumSearchNext:
	inc 1, l
	cp l, 0x10
	jr c, SeqVoice_DrumSearchLoop
	ld l, 0x0:opc
	ret

SeqVoice_ValidateAndProcessState:
	push xiz
	ldmm8 0x288e, 1075
	bit 2, (0x287b:16)
	jrl z, SeqVoice_ValidateState_PopReturn
	ld a, (0x288d:16)
	dec 1, a
SeqVoice_ValidateState_StoreChannel:
	ld (9696:16), a
	ld iz, (0x28af:16)
	ld wa, (9830:16)
	ldfr_werp WA, 0xfa
	ld a, (0x288d:16)
	extz wa
	calr Part_ValidateVoiceChannel
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqVoice_ValidateState_SaveRefs
	res 2, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0
	jr SeqVoice_ValidateState_RestoreRegs

SeqVoice_ValidateState_SaveRefs:
	ldmm16 9698, 0x28af
	ldmm16 0x289b, 9830
	ldmm16 9700, 0x28af
	ldw (9830:16), 5

SeqData_RhythmDispatchLoop:
	calr SeqData_ReadNextByte
	ld a, l
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqData_RhythmCheckMarker
	calr SeqData_ReadParamBlockAlt
	lda xbc, (9606:16)
	cp (xbc + 2), 0x48
	jr nz, SeqData_RhythmDispatchLoop
	cp (xbc + 3), 0x0
	jr nz, SeqData_RhythmDispatchLoop
	bitm 0, (xbc)
	jr z, SeqData_RhythmNoteDispatch
	setm 7, (xbc + 4)

SeqData_RhythmNoteDispatch:
	ld a, (xbc + 4)
	extz wa
	ld c, (xbc + 5)
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (0x288e:16), l
	jr SeqData_RhythmDispatchLoop

SeqData_RhythmCheckMarker:
	ld a, (1075:16)
	cp l, 0x82
	jr nz, SeqData_RhythmOtherMarkers

SeqData_RhythmStoreAndSet:
	ld (0x288e:16), a
	set 5, (0x287b:16)

SeqData_RhythmRestoreRefs:
	ldmm16 9698, 0x28af
	ldmm16 0x289b, 9830

SeqVoice_ValidateState_RestoreRegs:
	ld (0x28af:16), iz
	ldto_werp WA, 0xfa
	ld (9830:16), wa

SeqVoice_ValidateState_PopReturn:
	pop xiz
	ret

SeqData_RhythmOtherMarkers:
	cp l, 0x84
	jr z, SeqData_RhythmStoreAndSet
	cp l, 0x81
	jr z, SeqData_RhythmRestoreRefs
	calr SeqData_ReadParamBlockAlt
	jr SeqData_RhythmDispatchLoop

SeqTrack_ProcessControlBytes:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (0x287b:16)
	bit 2, a
	jrl z, SeqTrack_PopIzReturn
	bit 5, a
	jrl nz, SeqTrack_PopIzReturn
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld iz, (9830:16)

SeqTrack_ReloadSecondaryRefs:
	ldmm16 0x28af, 9698
	ldmm16 9830, 0x289b

SeqTrack_ReadAndDispatch:
	calr SeqData_ReadNextByte
	ld a, l
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqTrack_CheckEndMarker
	calr SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_SaveIndexReturn
	lda xbc, (9606:16)
	bitm 0, (xbc)
	jr z, SeqTrack_SetNoteHighBit
	setm 7, (xbc + 4)

SeqTrack_SetNoteHighBit:
	ld a, (xbc + 4)
	extz wa
	ld c, (xbc + 5)
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (0x288e:16), l
	jr SeqTrack_ReadAndDispatch

SeqTrack_CheckEndMarker:
	cp l, 0x82
	jr nz, SeqTrack_CheckOtherMarkers
	set 5, (0x287b:16)
	jr SeqData_SaveIndexReturn

SeqTrack_CheckOtherMarkers:
	cp l, 0x84
	jr z, SeqTrack_ReloadSecondaryRefs
	cp l, 0x81
	jr nz, SeqTrack_ReadParamAndContinue
	calr SeqTrack_ScanBarPositions
	jr SeqData_SaveIndexReturn

SeqTrack_ReadParamAndContinue:
	calr SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqTrack_ReadAndDispatch

SeqData_SaveIndexReturn:
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz
	ld (SEQ_ERROR_CODE:16), 0

SeqTrack_PopIzReturn:
	pop xiz
	ret

SeqTrack_ScanBarPositions:
	push xiz
	ld iz, 0:i3
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqTrack_ScanReadFinal

SeqTrack_ScanReadLoop:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqTrack_ScanSetEndFlag
	cp_erpb 0xfb, 0x81
	jr nz, SeqTrack_ScanCheckResetMarker
	inc 1, iz
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqTrack_ScanSetEndAndClear

SeqTrack_ScanCheckResetMarker:
	cp_erpb 0xfb, 0x84
	jr nz, SeqTrack_ScanReadParam
	ldmm16 0x28af, 9700
	ldw (9830:16), 5

SeqTrack_ScanComparePosition:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jr nz, SeqTrack_ScanReadLoop

SeqTrack_ScanReadFinal:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr nz, SeqTrack_ScanCheckResetAlt

SeqTrack_ScanSetEndFlag:
	set 5, (0x287b:16)
	jr SeqTrack_ScanReturn

SeqTrack_ScanReadParam:
	calr SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqTrack_ScanComparePosition

SeqTrack_ScanSetEndAndClear:
	set 5, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0
	jr SeqTrack_ScanReturn

SeqTrack_ScanCheckResetAlt:
	cp_erpb 0xfb, 0x84
	jr nz, SeqTrack_ScanUpdateSecondary
	ldmm16 0x28af, 9700
	ldw (9830:16), 5

SeqTrack_ScanUpdateSecondary:
	ldmm16 0x289b, 9830
	ldmm16 9698, 0x28af

SeqTrack_ScanReturn:
	pop xiz
	ret

SeqData_ReadParamBlockAlt:
	pushw iz
	ld iz, 0:i3
	calr SeqData_ReadNextByte
	ld (9606:16), l
	cp l, 0x82
	jr z, SeqData_ReadParamError
	cp l, 0x84
	jr z, SeqData_ReadParamError

SeqData_ReadParamLoop:
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_ReadParamReturn
	calr SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqData_ReadParamReturn
	ld bc, iz
	lda xwa, (9607:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp iz, 7:i3
	jr ule, SeqData_ReadParamLoop

SeqData_ReadParamError:
	ld (SEQ_ERROR_CODE:16), 1

SeqData_ReadParamReturn:
	popw iz
	ret

SeqPart_SeekAllVoicesToBar:
	pushw_erp 0xfa
	ld (SEQ_ERROR_CODE:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_RestoreReturn

SeqPart_SeekVoiceLoop:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr nz, SeqPart_SeekCheckError
	calr SeqVoice_FindDrumPartIndex
	ldmm16 0x287f, 9778
	ld a, (9780:16)
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_SeekNextVoice
	cp a, 1:i3
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr z, SeqData_ClearAndLoop
	jr SeqPart_RestoreReturn

SeqPart_SeekCheckError:
	cp a, 1:i3
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr nz, SeqPart_RestoreReturn

SeqData_ClearAndLoop:
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_SeekNextVoice:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (0x28a1:16)
	jr ule, SeqPart_SeekVoiceLoop

SeqPart_RestoreReturn:
	popw_erp 0xfa
	ret

SeqPart_DefaultRangeData:
	ldw	(9722:16), 1
	ldw	(9724:16), 1
	ldw	(9766:16), 1
	ldw	(9768:16), 1
	ldw	(9772:16), 1
	ldw	(9774:16), 1
	ret

Part_WriteWordAndByte:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), c
	ld iz, wa
	ld wa, (0x287d:16)
	ld c, a
	extz bc
	ld wa, 0:i3
	ld de, iz
	calr Part_WriteWord_Indexed
	ld wa, (0x287d:16)
	ld c, a
	extz bc
	ld e, (xsp + 2)
	extz de
	ld wa, 0:i3
	calr Part_WriteByte_Indexed
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld bc, (0x287d:16)
	extz bc
	ld de, iz
	calr Part_WriteWord_Indexed
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld bc, (0x287d:16)
	extz bc
	ld e, (xsp + 2)
	extz de
	calr Part_WriteByte_Indexed
	popw iz
	inc 2, xsp
	ret

SeqPart_CalcPlaybackOffset:
	pushw iz
	ld a, (9780:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, SeqPart_CalcRemainingTicks
	ld xwa, 0xa
	add (9690:16), xwa

SeqPart_CalcRemainingTicks:
	ldw iz, 0xff
	ld c, (9780:16)
	extz bc
	ld wa, 0:i3
	calr Part_ReadWord_Indexed
	sub iz, hl
	ld wa, iz
	extz xwa
	ld xhl, (9690:16)
	cp xhl, xwa
	jr ugt, SeqPart_CalcDivideAndStore
	ld xwa, 0:i3
	ld (9914:16), xwa
	jr SeqPart_CalcStoreResult

SeqPart_CalcDivideAndStore:
	sub xhl, xwa
	add xhl, 0xfb
	dec 1, xhl
	ld xwa, xhl
	ld xbc, 0xfb
	call Math_DivideU32
	ld (9914:16), xhl

SeqPart_CalcStoreResult:
	ld xwa, (9914:16)
	ld (9930:16), wa
	popw iz
	ret

SeqPart_PositionUpdateBlock:
	push	qiz
	ldmm16	9932, 62001
	ld	(SEQ_ERROR_CODE:16), 0
	ldib_erp	251, 1
	cp	(10401:16), 1
	jrl	c, SeqPart_PositionUpdateBlock_Code_Epilogue
SeqPart_PositionUpdateBlock_Code_Loop:
	ldto_berp a, 251
	ld	(9780:16), a
	ldto_berp a, 251
	extz	wa
	calr	Part_ValidateVoiceAndSetupSeq
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_PositionUpdateBlock_Skip
	cp	a, 8
	jr	z, SeqPart_PositionUpdateBlock_Code_Loop2
	cp	a, 1:i3
	jr	z, SeqPart_PositionUpdateBlock_Code_Loop2
	jrl	SeqPart_PositionUpdateBlock_Code_Epilogue
SeqPart_PositionUpdateBlock_Skip:
	calr	SeqVoice_FindDrumPartIndex
	ldmm16	10367, 9862
	ldb_d8	a, (9780)
	ldfr_berp a, 251
	extz	wa
	extz	hl
	ld	bc, hl
	calr	SeqVoice_SeekToBar
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_PositionUpdateBlock_Code_Entry
	cp	a, 8
	jr	z, SeqPart_PositionUpdateBlock_Code_Loop2
	cp	a, 1:i3
	jr	nz, SeqPart_PositionUpdateBlock_Code_Epilogue
SeqPart_PositionUpdateBlock_Code_Loop2:
	ld	(SEQ_ERROR_CODE:16), 0
	jr	SeqPart_PositionUpdateBlock_Code_Join
SeqPart_PositionUpdateBlock_Code_Entry:
	ldmm16	10367, 9778
	ldb_d8	l, (10381)
	ld	a, (9780:16)
	ldfr_berp a, 251
	extz	wa
	extz	hl
	ld	bc, hl
	calr	SeqVoice_SeekToBar
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_PositionUpdateBlock_Code_Skip
	cp	a, 8
	jr	z, SeqPart_PositionUpdateBlock_Code_Loop2
	jr	SeqPart_PositionUpdateBlock_Code_Epilogue
SeqPart_PositionUpdateBlock_Code_Skip:
	calr	SeqData_ScanAllTracks
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_PositionUpdateBlock_Code_Skip2
	cp	a, 7:i3
	jr	nz, SeqPart_PositionUpdateBlock_Code_Skip3
	ld	(SEQ_ERROR_CODE:16), 0
SeqPart_PositionUpdateBlock_Code_Skip2:
	calr	SeqPart_CalcPlaybackOffset
	ld	wa, (9932:16)
	ld	bc, (9930:16)
	cp	wa, bc
	jr	nc, SeqPart_PositionUpdateBlock_Code_Skip4
	ld	(SEQ_ERROR_CODE:16), 5
SeqPart_PositionUpdateBlock_Code_Skip3:
	jr	SeqPart_PositionUpdateBlock_Code_Epilogue
SeqPart_PositionUpdateBlock_Code_Skip4:
	sub	wa, bc
	ld	(9932:16), wa
SeqPart_PositionUpdateBlock_Code_Join:
	inc1b_erp 251
	ldto_berp a, 251
	cp a, (10401:16)
	jrl	ule, SeqPart_PositionUpdateBlock_Code_Loop
SeqPart_PositionUpdateBlock_Code_Epilogue:
	pop qiz
	ret

SeqPart_CalcTickRate:
	ld c, (9780:16)
	extz bc
	ld wa, 0:i3
	calr Part_ReadByte_Indexed
	ld wa, hl
	dec 5, wa
	extz xwa
	ld xhl, (9690:16)
	cp xhl, xwa
	jr ugt, SeqPart_CalcTickDivide
	ld xhl, 0:i3
	jr SeqPart_CalcTickStore

SeqPart_CalcTickDivide:
	sub xhl, xwa
	ld xwa, xhl
	ld xbc, 0xfb
	call Math_DivideU32
	inc 1, xhl

SeqPart_CalcTickStore:
	ld (9930:16), hl
	ret

SeqPart_CopyDataPrimary:
	dec 4, xsp
	push xiz
	ld iz, (0x288b:16)
	ld wa, (0x2889:16)
	ldfr_werp WA, 0xfa
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	lda xwa, (0x282c:16)
	mriw4 0x90, 0x19, 0x8b, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	lda xwa, (0x2830:16)
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	ld (SEQ_ERROR_CODE:16), 0

SeqCopy_ComparePositionLoop:
	lda xbc, (0x2834:16)
	ld wa, (0x288b:16)
	cp wa, (xbc)
	jr nz, SeqCopy_MismatchAdvance
	ld wa, (0x2889:16)
	cp wa, (xbc + 2)
	jr nz, SeqCopy_MismatchAdvance
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqCopy_StoreEndPosition
	jr SeqPart_SaveIndexReturn

SeqCopy_MismatchAdvance:
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SaveIndexReturn
	calr PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqCopy_ComparePositionLoop
	jr SeqPart_SaveIndexReturn

SeqCopy_StoreEndPosition:
	lda xbc, (0x2834:16)
	ld wa, (0x2887:16)
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2885

SeqPart_SaveIndexReturn:
	ld (0x288b:16), iz
	ldto_werp WA, 0xfa
	ld (0x2889:16), wa
	mrdw5 0x9f, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9f, 0x04, 0x19, 0x85, 0x28
	pop xiz
	inc 4, xsp
	ret

SeqPart_CopyDataSecondary:
	dec 4, xsp
	push xiz
	ld iz, (0x288b:16)
	ld wa, (0x2889:16)
	ldfr_werp WA, 0xfa
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	lda xwa, (0x282c:16)
	mriw4 0x90, 0x19, 0x8b, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	lda xwa, (0x2830:16)
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	ld (SEQ_ERROR_CODE:16), 0

SeqCopy2_ComparePositionLoop:
	lda xbc, (0x2834:16)
	ld wa, (0x288b:16)
	cp wa, (xbc)
	jr nz, SeqCopy2_MismatchBackward
	ld wa, (0x2889:16)
	cp wa, (xbc + 2)
	jr nz, SeqCopy2_MismatchBackward
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	lda xbc, (0x2834:16)
	ld wa, (0x2887:16)
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2885
	jr SeqCopy2_SaveIndexReturn

SeqCopy2_MismatchBackward:
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_NavigateBackward
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqCopy2_SaveIndexReturn
	calr PartCtrl_NavigateBackwardAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqCopy2_ComparePositionLoop

SeqCopy2_SaveIndexReturn:
	ld (0x288b:16), iz
	ldto_werp WA, 0xfa
	ld (0x2889:16), wa
	mrdw5 0x9f, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9f, 0x04, 0x19, 0x85, 0x28
	pop xiz
	inc 4, xsp
	ret

SeqBuf_ComputePageLayout:
	dec 2, xsp
	push xiz
	ld xbc, 0xff
	ld wa, (9890:16)
	extz xwa
	sub xbc, xwa
	ld xwa, (9690:16)
	cp xwa, xbc
	jr ugt, SeqBuf_CalcPageDivision
	ldw (9882:16), 0
	ld wa, (9890:16)
	extz xwa
	add xwa, (9690:16)
	ld (9914:16), xwa
	ldmm16 9912, 9884
	jrl SeqBuf_PageLayoutReturn

SeqBuf_CalcPageDivision:
	sub xwa, xbc
	ld (9922:16), xwa
	add xwa, 0xfb
	dec 1, xwa
	ld xbc, 0xfb
	call Math_DivideU32
	ld iz, hl
	ld (9882:16), iz
	ld wa, iz
	extz xwa
	ld xbc, 0xfb
	call Math_MultiplyAccumulate
	sub xhl, (9922:16)
	ld a, 0xfb:opc
	sub a, l
	inc 4, a
	ld w, 0x0:opc
	extz xwa
	ld (9914:16), xwa
	cp iz, (0xf231:16)
	jr ugt, SeqBuf_PageOverflowError
	ld iz, (9884:16)
	ld (9912:16), iz
	ldw (xsp + 4), 0x0
	cpw (9882:16), 0
	jr ule, SeqBuf_StoreLastPage

SeqBuf_ReadAndCheckValid:
	calr PartCtrl_ReadWordRoutine
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr nz, SeqBuf_WritePageEntries

SeqBuf_PageOverflowError:
	ld (SEQ_ERROR_CODE:16), 5
	jr SeqBuf_PageLayoutReturn

SeqBuf_WritePageEntries:
	ld wa, iz
	ldto_werp BC, 0xfa
	calr PartCtrl_WriteWord
	ldto_werp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ldto_werp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord_Off1
	ldto_werp IZ, 0xfa
	incw 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (9882:16)
	jr c, SeqBuf_ReadAndCheckValid

SeqBuf_StoreLastPage:
	ld (9912:16), iz

SeqBuf_PageLayoutReturn:
	pop xiz
	inc 2, xsp
	ret

SeqPart_InitMultiVoicePages:
	pushw_erp 0xfa
	ld a, (0x287b:16)
	res 3, a
	res 4, a
	ld (0x287b:16), a
	ldmm16 9932, 0xf231
	ld (SEQ_ERROR_CODE:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jrl c, SeqPart_PopRetFA

SeqPart_MultiVoiceLoop:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_MultiVoiceSeekBar
	cp a, 1:i3
	jrl z, SeqData_ClearError
	cp a, 0x8
	jrl z, SeqData_ClearError
	jrl SeqPart_PopRetFA

SeqPart_MultiVoiceSeekBar:
	calr SeqVoice_FindDrumPartIndex
	ldmm16 0x287f, 9862
	ld a, (9780:16)
	ldfr_berp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_MultiVoiceScanTracks
	cp a, 1:i3
	jr z, SeqData_ClearError
	cp a, 0x8
	jr nz, SeqPart_PopReturn
	ld wa, (9778:16)
	cp wa, (9862:16)
	jrl ugt, SeqPart_PopRetFA
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_MultiVoiceScanTracks:
	calr SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_MultiVoiceCalcDelta
	cp a, 7:i3
	jr nz, SeqPart_PopReturn
	set 4, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_MultiVoiceCalcDelta:
	ld xwa, (9690:16)
	ld (9934:16), xwa
	ldmm16 0x287f, 9778
	ld l, (0x288d:16)
	ld a, (9780:16)
	ldfr_berp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_MultiVoiceScanAlt
	cp a, 0x8
	jr nz, SeqPart_PopReturn

SeqData_ClearError:
	ld (SEQ_ERROR_CODE:16), 0
	jrl SeqVoice_AdvanceReadLoop

SeqPart_PopReturn:
	jrl SeqPart_PopRetFA

SeqPart_MultiVoiceScanAlt:
	calr SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_MultiVoiceCompareDelta
	cp a, 7:i3
	jrl nz, SeqPart_PopRetFA
	set 3, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_MultiVoiceCompareDelta:
	ld xwa, (9934:16)
	ld xbc, (9690:16)
	cp xwa, xbc
	jr ule, SeqPart_MultiVoiceReverseCalc
	sub xwa, xbc
	ld (9934:16), xwa
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_MultiVoiceStoreDelta
	bit 3, a
	jr nz, SeqPart_MultiVoiceStoreDelta
	ld xwa, (9934:16)
	dec 1, xwa
	ld (9934:16), xwa

SeqPart_MultiVoiceStoreDelta:
	ld xwa, (9934:16)
	ld (9690:16), xwa
	calr SeqPart_CalcTickRate
	ld wa, (9930:16)
	add (9932:16), wa
	jr SeqVoice_AdvanceReadLoop

SeqPart_MultiVoiceReverseCalc:
	cp xwa, xbc
	jr nc, SeqVoice_AdvanceReadLoop
	sub xbc, xwa
	ld (9690:16), xbc
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_MultiVoiceCheckBounds
	bit 3, a
	jr nz, SeqPart_MultiVoiceCheckBounds
	ld xwa, (9690:16)
	inc 1, xwa
	ld (9690:16), xwa

SeqPart_MultiVoiceCheckBounds:
	calr SeqPart_CalcPlaybackOffset
	ld wa, (9932:16)
	ld bc, (9930:16)
	cp wa, bc
	jr ugt, SeqPart_MultiVoiceSubtractRate
	ld (SEQ_ERROR_CODE:16), 5
	jr SeqPart_PopRetFA

SeqPart_MultiVoiceSubtractRate:
	sub wa, bc
	ld (9932:16), wa

SeqVoice_AdvanceReadLoop:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (0x28a1:16)
	jrl ule, SeqPart_MultiVoiceLoop

SeqPart_PopRetFA:
	popw_erp 0xfa
	ret

SeqPart_CountActiveVoices:
	push xiz
	cp a, (0xffe3:24)
	jr nz, SeqCount_IncrementStart
	ldib_erp 0xfb, 0
	jr SeqCount_InitLoopRegs

SeqCount_IncrementStart:
	inc 1, a
	ldfr_berp A, 0xfb

SeqCount_InitLoopRegs:
	ld iz, 0:i3
	ldib_erp 0xfa, 1

SeqCount_VoiceLoop:
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqCount_SkipInactiveVoice
	ldto_berp A, 0xfb
	extz wa
	ldto_berp C, 0xfa
	extz bc
	calr SeqVoice_CountChainLength
	add iz, hl

SeqCount_SkipInactiveVoice:
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqCount_VoiceLoop
	cp iz, 0:i3
	jr nz, SeqCount_ClampTo4D8
	ld (0x286c:16), 0
	ldw (0x2728:16), 0
	jr SeqCount_Return

SeqCount_ClampTo4D8:
	ldw de, 0x4d8
	cp iz, 0x4d8
	jr ule, SeqCount_SetupDivision
	ldw iz, 0x4d8

SeqCount_SetupDivision:
	ld bc, iz

SeqCount_ShiftDivLoop:
	srl de, 1
	srl iz, 1
	cp de, 0x258
	jr ugt, SeqCount_ShiftDivLoop
	mul iz, 0x64
	extz xiz
	div xiz, de
	cp iz, 0x64
	jr nz, SeqCount_CheckZeroPercent
	dec 1, iz
	jr SeqCount_StorePercentResult

SeqCount_CheckZeroPercent:
	cp iz, 0:i3
	jr nz, SeqCount_StorePercentResult
	inc 1, iz

SeqCount_StorePercentResult:
	ldto_berp A, 0xf8
	ld (0x286c:16), a
	ld iz, bc
	srl iz, 2
	jr nz, SeqCount_ComputeTickQuarter
	inc 1, iz

SeqCount_ComputeTickQuarter:
	ld (0x2728:16), iz

SeqCount_Return:
	pop xiz
	ret

SeqVoice_CountChainLength:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), c
	ld (xsp + 6), a
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	calr Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqVoice_ChainNoData
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, SeqVoice_ChainStartCount

SeqVoice_ChainNoData:
	ld hl, 0:i3
	jr SeqVoice_ChainReturn

SeqVoice_ChainStartCount:
	ldw (xsp + 2), 0x1
	cp iz, 0xffff
	jr z, SeqVoice_ChainStoreCount

SeqVoice_ChainFollowLoop:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr z, SeqVoice_ChainStoreCount
	ld wa, iz
	calr PartCtrl_ReadWord
	ld iz, hl
	incw 1, (xsp + 2)
	cp iz, 0xffff
	jr nz, SeqVoice_ChainFollowLoop

SeqVoice_ChainStoreCount:
	ld hl, (xsp + 2)

SeqVoice_ChainReturn:
	popw iz
	inc 6, xsp
	ret

SeqData_CopyBlockWithLookup:
	lda xsp, (xsp - 34)
	ld xiy, SeqData_CopyBlockWithLookup_LocalInit
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	ld a, (0x2878:16)
	cp a, 0xa
	jr nz, SeqDataCopy_CheckChannel
	lda xde, (xsp)
	lda xwa, (9706:16)
	ld xbc, xwa
	lda xhl, (xwa + 16)

SeqDataCopy_TransferLoop:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqDataCopy_TransferLoop
	jr SeqDataCopy_RestoreStack

SeqDataCopy_CheckChannel:
	cp (0xffe3:24), a
	jr nz, SeqDataCopy_IncrementChannel
	ld a, 0x0:opc
	jr SeqDataCopy_ComputeAndCopy

SeqDataCopy_IncrementChannel:
	inc 1, a

SeqDataCopy_ComputeAndCopy:
	extz wa
	lda xbc, (xsp + 16)
	calr SeqData_CopyBlock2K
	lda xde, (xsp + 16)
	lda xwa, (9706:16)
	ld xbc, xwa
	lda xhl, (xwa + 16)

SeqDataCopy_TransferLoop2:
	ld A, (xde+)
	ld (xbc+), a
	cp xbc, xhl
	jr c, SeqDataCopy_TransferLoop2

SeqDataCopy_RestoreStack:
	lda xsp, (xsp + 34)
	ret

SeqData_VoiceSetupBlock:
	push	qiz
	calr	SeqBuf_ClearRange
	calr	SeqVoice_FindDrumPartIndex
	ldfr_berp l, 251
	cpib_erp 251, 0
	jr z, SeqData_VoiceSetupBlock_Code_Skip
	ldto_berp a, 251
	ld	(0x2740:16), a
	ldto_berp a, 251
	extz	wa
	ld	(0x287d:16), wa
	ldto_berp a, 251
	extz	wa
	calr	Part_ValidateVoiceAndSetupSeq
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqData_VoiceSetupBlock_Code_Skip
	ldmm16	9822, 9830
	ldmm16	9820, 10415
	ldmm16	10367, 9778
	ldto_berp	c, 251
	extz	bc
	ld	wa, bc
	calr	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqData_VoiceSetupBlock_Code_Skip
	ld	wa, (9778:16)
	add wa, (9694:16)
	ld	(0x287f:16), wa
	ldto_berp c, 251
	extz	bc
	ld	wa, bc
	calr	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqData_VoiceSetupBlock_Code_Skip
	calr	SeqData_ReadNextByte
	cp	l, 130
	jr	z, SeqData_VoiceSetupBlock_Code_Skip
	ldmm16	9946, 9778
	ldmm16	9948, 9694
	ld	xwa, 10028
	calr	SeqVoice_SeekAndScanTracks
SeqData_VoiceSetupBlock_Code_Skip:
	calr	SeqPlay_WriteErrorToVoiceTable
	pop qiz
	ret

SeqBuf_ClearRange:
	lda xde, (0x2732:16)
	ld xwa, xde
	lda xbc, (0x272c:16)
	inc 6, xde

SeqBuf_ClearLoop:
	ld (xbc+), 0x00
	ld (xwa+), 0x00
	cp xwa, xde
	jr c, SeqBuf_ClearLoop
	ret

SeqVoice_SeekAndScanTracks:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ld c, (0x2740:16)
	ldmm16 0x287f, 9946
	extz bc
	ld wa, bc
	calr SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqVoice_WriteErrorAndReturn
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	ldw (xsp + 4), 0x0
	cpw (9948:16), 0
	jrl z, SeqVoice_WriteErrorAndReturn

SeqScan_OuterBarLoop:
	ld iz, 0:i3
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqScan_IncrementBarCount

SeqScan_InnerReadLoop:
	calr SeqPart_ReadByte_Secondary
	cp l, 0x81
	jr nz, SeqScan_CheckEndOrNote
	inc 1, iz
	calr PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqScan_ContinueInnerLoop
	jr SeqVoice_WriteErrorAndReturn

SeqScan_CheckEndOrNote:
	cp l, 0x82
	jr z, SeqVoice_WriteErrorAndReturn
	ld a, l
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqTrack_ProcessLoop
	cp iz, 0:i3
	jr nz, SeqTrack_ProcessLoop
	ldib_erp 0xfb, 0

SeqScan_ProcessNoteParams:
	ldto_berp C, 0xfb
	extz bc
	ld xwa, (xsp + 6)
	ld	(xwa+bc), l
	calr PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqVoice_WriteErrorAndReturn
	calr SeqPart_ReadByte_Secondary
	bit 7, l
	jr z, SeqScan_NoteParamNext
	cpib_erp 0xfb, 5
	jr z, SeqScan_NoteParamNext
	ld xwa, (xsp + 6)
	calr SeqScan_ClearNoteRange
	jr SeqTrack_ProcessLoop

SeqScan_NoteParamNext:
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr ule, SeqScan_ProcessNoteParams

SeqTrack_ProcessLoop:
	calr PartCtrl_AdvanceReadPos

SeqScan_ContinueInnerLoop:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jr nz, SeqScan_InnerReadLoop

SeqScan_IncrementBarCount:
	incw 1, (xsp + 4)
	calr SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cp wa, (9948:16)
	jrl nz, SeqScan_OuterBarLoop

SeqVoice_WriteErrorAndReturn:
	calr SeqPlay_WriteErrorToVoiceTable
	pop xiz
	inc 6, xsp
	ret

SeqScan_ClearNoteRange:
	ld xbc, xwa
	inc 6, xwa

SeqScan_ClearNoteLoop:
	ld (xbc+), 0x00
	cp xbc, xwa
	jr c, SeqScan_ClearNoteLoop
	ret

SeqValidate_PartAndTempoCombined:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValidate_CheckTempoValues
	extz wa
	calr Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqValidate_CombinedFail

SeqValidate_CheckTempoValues:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqValidate_CombinedFail
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cp hl, 0:i3
	jr z, SeqValidate_CombinedOK

SeqValidate_CombinedFail:
	ldw hl, 0xffff
	ret

SeqValidate_CombinedOK:
	ld hl, 0:i3
	ret

SeqVoice_CountEventsInBar:
	dec 8, xsp
	ld (xsp + 6), a
	calr SeqVoice_SetDefaultParams
	ld (SEQ_ERROR_CODE:16), 0
	ld (0x288d:16), 0
	ld a, (xsp + 6)
	extz wa
	calr Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqCount_ValidateChannel
	ldw hl, 0xffff
	jr SeqCount_ReturnResult

SeqCount_ValidateChannel:
	calr SeqVoice_ValidateAndProcessState
	ldw (xsp + 2), 0x1
	ldw (xsp + 4), 0x0
	ldw (xsp), 0x0
	cpw (3299:16), 0
	jr z, SeqData_EOL_Cleanup

SeqCount_EventLoop:
	ld a, (0x288e:16)
	extz wa
	cp wa, (xsp)
	jr nz, SeqCount_ReadNextEvent
	incw 1, (xsp + 2)
	calr SeqTrack_ProcessControlBytes
	ldw (xsp), 0x0

SeqCount_ReadNextEvent:
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqCount_EndMarkerFound
	cp l, 0x84
	jr nz, SeqCount_CheckBarMarker

SeqCount_EndMarkerFound:
	ld (SEQ_ERROR_CODE:16), 8
	jr SeqData_EOL_Cleanup

SeqCount_CheckBarMarker:
	cp l, 0x81
	jr nz, SeqCount_AdvanceAndCheck
	incw 1, (xsp)
	incw 1, (xsp + 4)

SeqCount_AdvanceAndCheck:
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqData_EOL_Cleanup
	ld wa, (xsp + 4)
	cp wa, (3299:16)
	jr nz, SeqCount_EventLoop

SeqData_EOL_Cleanup:
	ld hl, (xsp + 2)

SeqCount_ReturnResult:
	inc 8, xsp
	ret

SeqPart_ComputePlaybackDelta:
	push xiz
	ld xiz, xwa
	lda xhl, (0x282c:16)
	lda xix, (0x2830:16)
	lda xbc, (xhl + 2)
	lda xde, (xiz + 2)
	ld wa, (xix)
	cp wa, (xhl)
	jr nz, SeqDelta_DifferentPage
	ld xhl, xbc
	inc 2, xix
	ld wa, (xix)
	ld bc, (xbc)
	cp bc, wa
	jr ugt, SeqDelta_ErrorTooLarge
	ldw (xiz), 0x0
	ld wa, (xix)
	sub wa, (xhl)
	ld (xde), wa
	inc 1, wa
	ld (xde), wa
	jr SeqDelta_ReturnOK

SeqDelta_ErrorTooLarge:
	ldw wa, 0x64
	jr SeqDelta_SetErrorAndReturn

SeqDelta_DifferentPage:
	ldw (xiz), 0x0
	ldw wa, 0x100
	sub wa, (xbc)
	ld (xde), wa
	ld wa, (xhl)
	calr PartCtrl_ReadWord
	ld (0x282c:16), hl

SeqDelta_SamePageLoop:
	lda xbc, (0x282c:16)
	lda xde, (0x2830:16)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, SeqDelta_AdvanceToNextPage
	lda xhl, (xiz + 2)
	ld wa, (xhl)
	ld bc, wa
	add bc, (xde + 2)
	ld wa, bc
	ld (xhl), wa
	dec 5, bc
	ld wa, bc
	ld (xhl), wa
	inc 1, bc
	ld (xhl), bc
	cp bc, 0xfb
	jr c, SeqDelta_ReturnOK
	incw 1, (xiz)
	ld wa, (xhl)
	sub wa, 0xfb
	ld (xhl), wa

SeqDelta_ReturnOK:
	ld hl, 0:i3
	jr SeqDelta_Return

SeqDelta_AdvanceToNextPage:
	incw 1, (xiz)
	ld wa, (xbc)
	calr PartCtrl_ReadWord
	lda xwa, (0x282c:16)
	ld (xwa), hl
	cpw (xwa), 0x4d8
	jr ule, SeqDelta_SamePageLoop
	ldw wa, 0x65

SeqDelta_SetErrorAndReturn:
	calr SeqData_SetErrorCode
	ldw hl, 0xffff

SeqDelta_Return:
	pop xiz
	ret

SeqPlay_SetupDualTrack:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 36), a
	lda xbc, (0x282c:16)
	ldmw2 (xbc), 0x2952
	ld a, (0x2954:16)
	extz wa
	ld (xbc + 2), wa
	lda xhl, (0x2830:16)
	ldmw2 (xhl), 0x2955
	lda xde, (xhl + 2)
	ld c, (0x2957:16)
	extz bc
	ld wa, bc
	ld (xde), bc
	cp bc, 5:i3
	jr nz, SeqPlay_DecrementPosition
	ld wa, (xhl)
	calr PartCtrl_ReadWord_Off1
	lda xwa, (0x2830:16)
	ld (xwa), hl
	ldw (xwa + 2), 0xff
	jr SeqPlay_ComputeDeltas

SeqPlay_DecrementPosition:
	dec 1, wa
	ld (xde), wa

SeqPlay_ComputeDeltas:
	lda xwa, (xsp + 32)
	calr SeqPart_ComputePlaybackDelta
	cp hl, 0:i3
	jrl nz, SeqPlay_ErrorReturn
	lda xbc, (0x282c:16)
	ld l, (xsp + 36)
	dec 1, l
	ld e, l
	extz de
	add de, de
	lda xwa, (0x28ce:16)
	ld	wa, (xwa+de)
	ld (xbc), wa
	ldw (xbc + 2), 0x5
	ld c, l
	extz bc
	lda xhl, (0x290e:16)
	extz xbc
	add xbc, xhl
	ld a, (xbc)
	cp a, 5:i3
	jr nz, SeqPlay_DecrementAltPos
	lda xwa, (0x28ee:16)
	ld	wa, (xwa+de)
	calr PartCtrl_ReadWord_Off1
	ld c, (xsp + 36)
	dec 1, c
	ld e, c
	extz de
	add de, de
	lda xwa, (0x28ee:16)
	ld	(xwa+de), hl
	extz bc
	lda xwa, (0x290e:16)
	extz xbc
	add xbc, xwa
	ld (xbc), 0xff
	jr SeqPlay_SetupSecondTrack

SeqPlay_DecrementAltPos:
	dec 1, a
	ld (xbc), a

SeqPlay_SetupSecondTrack:
	lda xbc, (0x2830:16)
	ld e, (xsp + 36)
	dec 1, e
	ld l, e
	extz hl
	add hl, hl
	lda xwa, (0x28ee:16)
	ld	wa, (xwa+hl)
	ld (xbc), wa
	extz de
	lda xwa, (0x290e:16)
	extz xde
	add xde, xwa
	ld a, (xde)
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 28)
	calr SeqPart_ComputePlaybackDelta
	cp hl, 0:i3
	jr z, SeqPlay_ComputeOffsets

SeqPlay_ErrorReturn:
	ldw hl, 0xffff
	jrl SeqPlay_RestoreAndReturn

SeqPlay_ComputeOffsets:
	lda xiz, (xsp + 32)
	ld wa, (xiz)
	extz xwa
	ld (xsp + 4), xwa
	ld xbc, 0xfb
	call Math_MultiplyAccumulate
	ld (xsp + 4), xhl
	ld wa, (xiz + 2)
	extz xwa
	add (xsp + 4), xwa
	lda xiz, (xsp + 28)
	ld wa, (xiz)
	extz xwa
	ld (xsp + 8), xwa
	ld xbc, 0xfb
	call Math_MultiplyAccumulate
	ld (xsp + 8), xhl
	ld wa, (xiz + 2)
	extz xwa
	add (xsp + 8), xwa
	lda xde, (0x28ce:16)
	lda xbc, (0x2834:16)
	lda xwa, (0x2830:16)
	ld (xsp + 16), xwa
	lda xiy, (0x28ee:16)
	ld l, (xsp + 36)
	dec 1, l
	ldfr_berp L, 0xf8
	extz iz
	ld xwa, (xsp + 16)
	inc 2, xwa
	ld (xsp + 20), xwa
	lda xix, (xbc + 2)
	ld wa, iz
	add wa, wa
	lda	xde, (xde+wa)
	lda	xiy, (xiy+wa)
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 8)
	jrl ule, SeqPlay_HandleSmallerDelta
	lda xiz, (0x282c:16)
	ld wa, (xde)
	ld (xiz), wa
	ldw (xiz + 2), 0x5
	ld wa, (xiy)
	ld (xbc), wa
	extz hl
	lda xwa, (0x290e:16)
	extz xhl
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xix), wa
	ld xwa, (xsp + 16)
	ldmw2 (xwa), 0x2952
	ld c, (0x2954:16)
	extz bc
	ld xwa, (xsp + 20)
	ld (xwa), bc
	calr SeqPart_CopyDataPrimary
	lda xde, (0x2830:16)
	lda xbc, (0x2834:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	lda xbc, (0x282c:16)
	ldmw2 (xbc), 0x2955
	ld a, (0x2957:16)
	extz wa
	ld (xbc + 2), wa
	ld c, (xsp + 36)
	extz bc
	ld wa, 0:i3
	calr Part_ReadWord_Indexed
	ld (0x2834:16), hl
	ld c, (xsp + 36)
	extz bc
	ld wa, 0:i3
	calr Part_ReadByte_Indexed
	ld (0x2836:16), hl
	calr SeqPart_CopyDataPrimary
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr nz, SeqPlay_DecrementBytePosAlt
	ld wa, (xde)
	calr PartCtrl_ReadWord_Off1
	ld (xsp + 22), hl
	ld wa, (0x2834:16)
	calr Part_StealAndReallocVoices
	lda xbc, (0x2834:16)
	ld wa, (xsp + 22)
	ld (xbc), wa
	ldw (xbc + 2), 0xff
	jr SeqPlay_WriteIndexedResults

SeqPlay_DecrementBytePosAlt:
	dec 1, wa
	ld (xbc), wa

SeqPlay_WriteIndexedResults:
	ld c, (xsp + 36)
	extz bc
	ld de, (0x2834:16)
	ld wa, 0:i3
	calr Part_WriteWord_Indexed
	ld c, (xsp + 36)
	extz bc
	ld de, (0x2836:16)
	ld wa, 0:i3
	calr Part_WriteByte_Indexed
	jrl SeqPlay_ReturnOK

SeqPlay_HandleSmallerDelta:
	lda xwa, (0x282c:16)
	ld (xsp + 12), xwa
	inc 2, xwa
	ld (xsp + 24), xwa
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 8)
	jrl nc, SeqPlay_HandleEqualDelta
	sub (xsp + 8), xwa
	ld xwa, (xsp + 8)
	ld xbc, 0xfb
	call Math_DivideU32
	ld (xsp + 22), hl
	ld xwa, (xsp + 8)
	ld xbc, 0xfb
	call DivMod32
	ld xwa, (xsp + 12)
	ldmw2 (xwa), 0x2955
	ld c, (0x2957:16)
	extz bc
	ld xwa, (xsp + 24)
	ld (xwa), bc
	ld a, (xsp + 36)
	extz wa
	extz hl
	ld bc, (xsp + 22)
	ld de, hl
	call PartCtrl_SwapIndexedEntries
	lda xde, (0x282c:16)
	ld l, (xsp + 36)
	dec 1, l
	ld c, l
	extz bc
	add bc, bc
	lda xwa, (0x28ce:16)
	ld	wa, (xwa+bc)
	ld (xde), wa
	ldw (xde + 2), 0x5
	lda xde, (0x2834:16)
	lda xwa, (0x28ee:16)
	ld	wa, (xwa+bc)
	ld (xde), wa
	extz hl
	lda xwa, (0x290e:16)
	extz xhl
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xde + 2), wa
	lda xbc, (0x2830:16)
	ldmw2 (xbc), 0x2952
	ld a, (0x2954:16)
	extz wa
	ld (xbc + 2), wa
	jr SeqPlay_CopyPrimaryData

SeqPlay_HandleEqualDelta:
	ld xhl, (xsp + 12)
	ld wa, (xde)
	ld (xhl), wa
	ld xwa, (xsp + 24)
	ldw (xwa), 0x5
	ld wa, (xiy)
	ld (xbc), wa
	ld wa, (xiy)
	ld (xix), wa
	ld xwa, (xsp + 16)
	ldmw2 (xwa), 0x2952
	ld c, (0x2954:16)
	extz bc
	ld xwa, (xsp + 20)
	ld (xwa), bc

SeqPlay_CopyPrimaryData:
	calr SeqPart_CopyDataPrimary

SeqPlay_ReturnOK:
	ld hl, 0:i3

SeqPlay_RestoreAndReturn:
	pop xiz
	lda xsp, (xsp + 34)
	ret

SeqPart_ConsumeTicksFromBuffer:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	ldw bc, 0x100
	ld xde, (xsp + 4)
	sub bc, (xde)
	extz xbc
	ld xwa, (9690:16)
	cp xbc, xwa
	jr ule, SeqTick_StartConsume
	ld bc, wa
	add (xde), bc
	jr SeqPart_StoredExit

SeqTick_StartConsume:
	ld xiz, xwa
	sub xiz, xbc

SeqTick_ReadNextEntry:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	calr PartCtrl_ReadWord
	cp hl, 0x4d8
	jr ule, SeqTick_StoreAndValidate
	ld (SEQ_ERROR_CODE:16), 10
	jr SeqPart_StoredExit

SeqTick_StoreAndValidate:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, SeqTick_CheckRemaining
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqPart_StoredExit

SeqTick_CheckRemaining:
	cp xiz, 0xfb
	jr ugt, SeqTick_SubtractAndLoop
	ld xbc, xiz
	inc 5, xbc
	ld xwa, (xsp + 4)
	ld (xwa), bc

SeqPart_StoredExit:
	pop xiz
	inc 8, xsp
	ret

SeqTick_SubtractAndLoop:
	sub xiz, 0xfb
	jr SeqTick_ReadNextEntry

SeqPart_ApplyControlChanges:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), xwa
	ldib_erp 0xfb, 0

SeqCtrl_ApplyLoop:
	ldto_berp C, 0xfb
	extz bc
	ld xwa, (xsp + 2)
	ld	a, (xwa+bc)
	extz wa
	calr SeqPart_WriteByte_Secondary
	calr PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqCtrl_WriteErrorReturn
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr ule, SeqCtrl_ApplyLoop

SeqCtrl_WriteErrorReturn:
	calr SeqPlay_WriteErrorToVoiceTable
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqBufInit_MainSetup:
	push xiz
	cp (0x2740:16), 0
	jrl z, SeqPart_AbortAndUpdateState
	lda xbc, (0x2732:16)
	ld wa, (9820:16)
	cp (0x272c:16), 0
	jrl nz, SeqBufInit_SecondaryPath
	cp (xbc), 0x0
	jrl z, SeqPart_AbortAndUpdateState
	ld (9884:16), wa
	ldmm16 9890, 9822
	ld xwa, 6:i3
	ld (9690:16), xwa
	calr SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	ld c, a
	extz bc
	ld wa, (9900:16)
	calr Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26d8
	ldmw2 (xwa + 2), 0x26d6
	calr SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 0x288b, 9944
	ldmm16 0x2889, 9942
	ld xwa, 0x2732
	jrl PartCtrl_ApplyChanges

SeqBufInit_SecondaryPath:
	ld (9884:16), wa
	ldmm16 9890, 9822
	cp (xbc), 0x0
	jr nz, SeqBufInit_DualTrackPath
	ld xwa, 6:i3
	ld (9690:16), xwa
	calr SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	ld c, a
	extz bc
	ld wa, (9900:16)
	calr Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26d4
	ldmw2 (xwa + 2), 0x26d2
	calr SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 0x288b, 9940
	ldmm16 0x2889, 9938
	ld xwa, 0x272c
	jrl PartCtrl_ApplyChanges

SeqBufInit_DualTrackPath:
	ld xwa, 0xc
	ld (9690:16), xwa
	calr SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ld wa, (9912:16)
	ldfr_werp WA, 0xfa
	ld xwa, (9914:16)
	ld iz, wa
	dec 6, iz
	cp iz, 5:i3
	jr nc, SeqBufInit_StorePageDirect
	ldto_werp WA, 0xfa
	calr PartCtrl_ReadWord_Off1
	ld (9900:16), hl
	ld wa, 5:i3
	sub wa, iz
	ldw iz, 0xff
	sub iz, wa
	jr SeqBufInit_StorePageOffset

SeqBufInit_StorePageDirect:
	ldto_werp WA, 0xfa
	ld (9900:16), wa

SeqBufInit_StorePageOffset:
	ld (9902:16), iz
	ldto_berp C, 0xf8
	extz bc
	ld wa, (9900:16)
	calr Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (9950:16)
	cp wa, (9952:16)
	jr ule, SeqBufInit_ChooseForwardDir
	ldmw2 (xde), 0x26d4
	ldmw2 (xbc), 0x26d2
	jr SeqBufInit_CopyAndProcess

SeqBufInit_ChooseForwardDir:
	ldmw2 (xde), 0x26d8
	ldmw2 (xbc), 0x26d6

SeqBufInit_CopyAndProcess:
	calr SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqBufInit_PopReturn
	ld wa, (9950:16)
	cp wa, (9952:16)
	jr ule, SeqBufInit_SetAltPointers
	lda xwa, (0x272c:16)
	ldmm16 0x288b, 9940
	ldmm16 0x2889, 9938
	jr SeqBufInit_ApplyCtrlChanges

SeqBufInit_SetAltPointers:
	lda xwa, (0x2732:16)
	ldmm16 0x288b, 9944
	ldmm16 0x2889, 9942

SeqBufInit_ApplyCtrlChanges:
	calr SeqPart_ApplyControlChanges
	ld c, (0x2740:16)
	extz bc
	ld wa, 0:i3
	calr Part_ReadByte_Indexed
	ld (0x282e:16), hl
	ld c, (0x2740:16)
	extz bc
	ld wa, 0:i3
	calr Part_ReadWord_Indexed
	ld (0x282c:16), hl
	lda xde, (0x2830:16)
	ldto_werp WA, 0xfa
	ld (xde), wa
	ld xwa, (9914:16)
	ld (xde + 2), wa
	ld c, a
	extz bc
	ld wa, (xde)
	calr Part_WriteWordAndByte
	ld wa, (9950:16)
	cp wa, (9952:16)
	jr ule, SeqBufInit_ChooseReverseDir
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26d8
	ldmw2 (xwa + 2), 0x26d6
	jr SeqBufInit_CopyAndCheckAlt

SeqBufInit_ChooseReverseDir:
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26d4
	ldmw2 (xwa + 2), 0x26d2

SeqBufInit_CopyAndCheckAlt:
	calr SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_AbortAndUpdateState
	ld wa, (9950:16)
	cp wa, (9952:16)
	jr ule, SeqBufInit_SetAltReverse
	lda xwa, (0x2732:16)
	ldmm16 0x288b, 9944
	ldmm16 0x2889, 9942
	jr PartCtrl_ApplyChanges

SeqBufInit_SetAltReverse:
	lda xwa, (0x272c:16)
	ldmm16 0x288b, 9940
	ldmm16 0x2889, 9938

PartCtrl_ApplyChanges:
	calr SeqPart_ApplyControlChanges

SeqPart_AbortAndUpdateState:
	calr SeqPlay_WriteErrorToVoiceTable

SeqBufInit_PopReturn:
	pop xiz
	ret

PartCtrl_FindActiveByLimit:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	ld bc, (xwa)
	extz xbc
	dec 4, xbc
	ld xwa, (9690:16)
	cp xbc, xwa
	jr ule, PartFind_SubtractAndLoop
	sub xbc, xwa
	inc 4, xbc
	jr PartFind_StoreResult

PartFind_SubtractAndLoop:
	ld xiz, xwa
	sub xiz, xbc

PartFind_ReadAndCheckLoop:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	calr PartCtrl_ReadWord_Off1
	cp hl, 0x4d8
	jr ule, PartFind_StoreAndValidate
	ld (SEQ_ERROR_CODE:16), 10
	jr PartFind_Return

PartFind_StoreAndValidate:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartFind_CheckRemaining
	ld (SEQ_ERROR_CODE:16), 11
	jr PartFind_Return

PartFind_CheckRemaining:
	cp xiz, 0xfb
	jr ule, PartFind_ComputeFinal
	sub xiz, 0xfb
	jr PartFind_ReadAndCheckLoop

PartFind_ComputeFinal:
	ld xbc, 0xff
	sub xbc, xiz

PartFind_StoreResult:
	ld xwa, (xsp + 4)
	ld (xwa), bc

PartFind_Return:
	pop xiz
	inc 8, xsp
	ret

SeqData_SkipToNextEvent:
	calr SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	jr nz, SeqSkip_AdvanceAndCheck
	ret

SeqSkip_AdvanceAndCheck:
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqData_SkipEventParams
	ldw wa, 0xd2
	jr SeqSkip_SetErrorCode

SeqData_SkipEventParams:
	calr SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	ret z
	bit 7, l
	ret nz
	calr SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqData_SkipEventParams
	ldw wa, 0xd3

SeqSkip_SetErrorCode:
	calr SeqData_SetErrorCode
	ret

SeqData_CopyBlockToBuffer:
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xde, (SEQ_SONG_SLOTS:24)
	add xde, xwa
	ld xiy, 0xf180
	ld xix, xde
	ldw bc, 0x400
	ldirw
	ret

VoicePreset_LoadAndInitPan:
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, xwa
	ld xiy, xbc
	ld xix, 0xf180
	ldw bc, 0x400
	ldirw
	jp VoiceChannels_InitPanFromPreset

Part_WriteWordBlock_OffsetAF:
	push xiz
	ld iz, wa
	ldib_erp 0xfb, 0

PartWrite_LoopAF:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xaf
	ld de, iz
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, PartWrite_LoopAF
	pop xiz
	ret

Chan_SetActiveBit:
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, Chan_ShiftComplete
	slaa de

Chan_ShiftComplete:
	cp c, 0:i3
	jr z, Chan_ClearBit
	or (0xf19e:16), de
	jr Chan_CheckSubsystem

Chan_ClearBit:
	cpl de
	and (0xf19e:16), de

Chan_CheckSubsystem:
	jp Audio_CheckSubsystemReady

SeqVoice_SetOrClearBitMask:
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, SeqVoiceBit_ShiftComplete
	slaa de

SeqVoiceBit_ShiftComplete:
	cp c, 0:i3
	jr z, SeqVoiceBit_ClearBit
	or (0x28a8:16), de
	jr SeqVoiceBit_CheckSubsystem

SeqVoiceBit_ClearBit:
	cpl de
	and (0x28a8:16), de

SeqVoiceBit_CheckSubsystem:
	jp Audio_CheckSubsystemReady

Part_CopyBlock16:
	cp a, 0:i3
	jr nz, PartCopy16_ComputeAddr
	lda xhl, (0xf280:16)
	jr PartCopy16_TransferLoop

PartCopy16_ComputeAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa+256)
	lda xhl, (SEQ_SONG_SLOTS:24)
	add xhl, xwa

PartCopy16_TransferLoop:
	ld xde, xbc
	lda xbc, (xbc + 16)

PartCopy16_CopyWord:
	ld A, (xde+)
	ld (xhl+), a
	cp xde, xbc
	jr c, PartCopy16_CopyWord
	ret

Part_CopyToBuffer:
	cp a, 0:i3
	jr nz, PartCopyBuf_ComputeSrcAddr
	lda xde, (0xf460:16)
	jr PartCopyBuf_SetupDst

PartCopyBuf_ComputeSrcAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa+736)
	lda xde, (SEQ_SONG_SLOTS:24)
	add xde, xwa

PartCopyBuf_SetupDst:
	cp c, 0:i3
	jr nz, PartCopyBuf_ComputeDstAddr
	lda xbc, (0xf460:16)
	jr PartCopyBuf_InitCounter

PartCopyBuf_ComputeDstAddr:
	dec 1, c
	ld b, 0x0:opc
	extz xbc
	sll xbc, 11
	lda xwa, (xbc+736)
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, xwa

PartCopyBuf_InitCounter:
	ld hl, 0:i3

PartCopyBuf_TransferLoop:
	ld A, (xde+)
	ld (xbc+), a
	inc 1, hl
	cp hl, 0x520
	jr c, PartCopyBuf_TransferLoop
	ret

; ============================================================================
; Part_WriteByte - Write byte to part/channel data structure
; ============================================================================
; Input:  A = part number (0 = direct base, 1+ = indexed)
;         BC = offset within part structure
;         E = byte value to write
; Address: 0xab000 + (A-1)*2048 + BC  (2KB per part)
; If A==0, uses direct base address from RAM[61824].
; See also: Part_WriteWord (16-bit write companion)
; ============================================================================
Part_WriteByte:
	cp a, 0:i3
	jr nz, Part_WriteByte_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_WriteByte_DoWrite

Part_WriteByte_ComputeAddr:
	extz xbc
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, xwa

Part_WriteByte_DoWrite:
	ld (xbc), e
	ret

; ============================================================================
; Part_WriteWord - Write 16-bit word to part/channel data structure
; ============================================================================
; Input:  A = part number (0 = direct base, 1+ = indexed)
;         BC = offset within part structure
;         DE = 16-bit value to write
; Address: 0xab000 + (A-1)*2048 + BC  (2KB per part)
; See also: Part_WriteByte (8-bit write companion)
; ============================================================================
Part_WriteWord:
	cp a, 0:i3
	jr nz, Part_WriteWord_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_WriteWord_DoWrite

Part_WriteWord_ComputeAddr:
	extz xbc
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, SEQ_SONG_SLOTS
	add xbc, xwa

Part_WriteWord_DoWrite:
	ld (xbc), de
	ret

Part_ReadByteDirect:
	cp a, 0:i3
	jr nz, Part_ReadByteDirect_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_ReadByteDirect_DoRead

Part_ReadByteDirect_ComputeAddr:
	extz xbc
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda xbc, (SEQ_SONG_SLOTS:24)
	add xbc, xwa

Part_ReadByteDirect_DoRead:
	ld l, (xbc)
	ret

Part_ReadWord:
	cp a, 0:i3
	jr nz, Part_ReadWord_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_ReadWord_DoRead

Part_ReadWord_ComputeAddr:
	extz xbc
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, SEQ_SONG_SLOTS
	add xbc, xwa

Part_ReadWord_DoRead:
	ld hl, (xbc)
	ret

Part_WriteWord_Indexed:
	ld l, c
	ldw bc, 0x78
	ld w, l
	add w, l
	dec 2, w
	ld l, w
	extz hl
	add bc, hl
	extz wa
	jrl Part_WriteWord

Part_ReadWord_Indexed:
	ldw de, 0x78
	ld l, c
	add l, c
	dec 2, l
	extz hl
	add de, hl
	extz wa
	ld bc, de
	jr Part_ReadWord

Part_WriteByte_Indexed:
	ldw hl, 0x98
	dec 1, c
	extz bc
	add hl, bc
	extz wa
	extz de
	ld bc, hl
	jrl Part_WriteByte

Part_ReadByte_Indexed:
	ld e, c
	ldw bc, 0x98
	dec 1, e
	extz de
	add bc, de
	extz wa
	calr Part_ReadByteDirect
	extz hl
	ret

Part_SetAllVoicePos:
	push xiz
	ld iz, wa
	ldib_erp 0xfb, 0

Part_SetAllVoicePos_Loop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb1
	ld de, iz
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, Part_SetAllVoicePos_Loop
	calr Seq_ComputePercentClamped99
	ld (7528:16), l
	call SeqAccomp_SendStopNotify
	pop xiz
	ret

Part_IncrementVoicePos:
	push xiz
	ld wa, 0:i3
	ldw bc, 0xb1
	calr Part_ReadWord
	ld iz, hl
	cp iz, 0x4d8
	jr c, Part_IncrVoicePos_ValidRange
	ldw hl, 0xffff
	jr PartIncrPos_Return

Part_IncrVoicePos_ValidRange:
	inc 1, iz
	ldib_erp 0xfb, 0

PartIncrPos_WriteLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb1
	ld de, iz
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, PartIncrPos_WriteLoop
	calr Seq_ComputePercentClamped99
	ld (7528:16), l
	call SeqAccomp_SendStopNotify
	ld hl, 0:i3

PartIncrPos_Return:
	pop xiz
	ret

Part_DecrementVoicePos:
	push xiz
	ld wa, 0:i3
	ldw bc, 0xb1
	calr Part_ReadWord
	ld iz, hl
	cp iz, 0:i3
	jr nz, PartDecrPos_StartDecrement
	ldw hl, 0xffff
	jr PartDecrPos_Return

PartDecrPos_StartDecrement:
	dec 1, iz
	ldib_erp 0xfb, 0

PartDecrPos_WriteLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb1
	ld de, iz
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, PartDecrPos_WriteLoop
	calr Seq_ComputePercentClamped99
	ld (7528:16), l
	call SeqAccomp_SendStopNotify
	ld hl, 0:i3

PartDecrPos_Return:
	pop xiz
	ret

Part_WriteSubBlock32:
	cp a, 0:i3
	jr nz, PartSubBlk_ComputeAddr
	lda xhl, (0xf1a0:16)
	jr PartSubBlk_WriteAndCheck

PartSubBlk_ComputeAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda xhl, (SEQ_SONG_SLOTS:24)
	add xhl, xwa

PartSubBlk_WriteAndCheck:
	extz bc
	lda	xwa, (xhl+bc)
	ld (xwa - 1), e
	jp Audio_CheckSubsystemReady

Part_ReadSubBlock32:
	cp a, 0:i3
	jr nz, PartSubBlkRd_ComputeAddr
	lda xde, (0xf1a0:16)
	jr PartSubBlkRd_ReadAndReturn

PartSubBlkRd_ComputeAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda xde, (SEQ_SONG_SLOTS:24)
	add xde, xwa

PartSubBlkRd_ReadAndReturn:
	extz bc
	lda	xwa, (xde+bc)
	ld l, (xwa - 1)
	ret

Part_WriteSubBlock48:
	cp a, 0:i3
	jr nz, PartSubBlk48_ComputeAddr
	lda xhl, (0xf1b0:16)
	jr PartSubBlk48_WriteAndCheck

PartSubBlk48_ComputeAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 48)
	lda xhl, (SEQ_SONG_SLOTS:24)
	add xhl, xwa

PartSubBlk48_WriteAndCheck:
	extz bc
	lda	xwa, (xhl+bc)
	ld (xwa - 1), e
	jp Audio_CheckSubsystemReady
Part_VoiceSearchBlock:
	cp	a, 0:i3
	jr	nz, Part_WriteSubBlock48_Skip
	lda	xde, (0xf1b0:16)
	jr	Part_WriteSubBlock48_Join
Part_WriteSubBlock48_Skip:
	dec	1, a
	ld	w, 0:opc
	extz	xwa
	sll	xwa, 11
	lda	xwa, (xwa+48)
	lda	xde, (SEQ_SONG_SLOTS:24)
	add	xde, xwa
Part_WriteSubBlock48_Join:
	extz	bc
	lda	xwa, (xde+bc)
	ld	l, (xwa-1)
	ret

Part_FindVoiceByByte:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), c
	ld (xsp + 4), a
	ldib_erp 0xfb, 1

PartFind_VoiceSearchLoop:
	ld a, (xsp + 4)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	calr Part_ReadSubBlock32
	cp l, (xsp + 2)
	jr nz, PartFind_VoiceSearchNext
	ldto_berp L, 0xfb
	jr PartFind_VoiceSearchReturn

PartFind_VoiceSearchNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartFind_VoiceSearchLoop
	ld l, 0xff:opc

PartFind_VoiceSearchReturn:
	popw_erp 0xfa
	inc 4, xsp
	ret

Part_ReadVoiceByte:
	extz wa
	extz bc
	jrl Part_ReadSubBlock32

Part_ReadVoiceBit7:
	extz wa
	mul c, 0x3
	dec 3, c
	add c, 0xd0
	extz bc
	calr Part_ReadByteDirect
	and l, 0x80
	ret

Part_SetClearVoiceBit7:
	dec 6, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 2)
	mul c, 0x3
	dec 3, c
	add c, 0xd0
	extz bc
	calr Part_ReadByteDirect
	cp (xsp), 0x0
	jr z, PartVoiceBit_ClearBit7
	set 7, l
	jr PartVoiceBit_WriteBit7

PartVoiceBit_ClearBit7:
	res 7, l

PartVoiceBit_WriteBit7:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 2)
	mul c, 0x3
	dec 3, c
	add c, 0xd0
	extz bc
	extz hl
	ld de, hl
	calr Part_WriteByte
	inc 6, xsp
	ret

Part_ReadVoiceWord:
	extz wa
	mul c, 0x3
	dec 3, c
	add c, 0xd1
	extz bc
	jrl Part_ReadWord

Part_WriteVoiceWord:
	extz wa
	mul c, 0x3
	dec 3, c
	add c, 0xd1
	extz bc
	jrl Part_WriteWord

Part_InitVoiceDefaults:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	ld bc, 0:i3
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 1:i3
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 2:i3
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 3:i3
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 4:i3
	ld de, 0:i3
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 5:i3
	ld de, 1:i3
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 6:i3
	ldw de, 0x8
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ld bc, 7:i3
	ld de, 0:i3
	calr Part_WriteByte
	call Boot_ReadFDCStatus
	ld a, (xsp + 2)
	extz wa
	extz hl
	ldw bc, 0x8
	ld de, hl
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x14
	ld de, 0:i3
	calr Part_WriteWord
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x16
	ldw de, 0x100
	calr Part_WriteWord
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x18
	ldw de, 0x2e
	calr Part_WriteWord
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x1a
	ldw de, 0x520
	calr Part_WriteWord
	ld iz, 0:i3

PartInit_WriteZeroLoop:
	ld a, (xsp + 2)
	extz wa
	ld bc, iz
	add bc, 0x42
	ld de, 0:i3
	calr Part_WriteByte
	inc 1, iz
	cp iz, 0xc
	jr c, PartInit_WriteZeroLoop
	calr SeqStatus_CheckBit2
	ld a, (xsp + 2)
	extz wa
	cp l, 0:i3
	jr nz, PartInit_SetBDFF
	ldw bc, 0xbd
	ld de, 0:i3
	jr PartInit_WriteAndReturn

PartInit_SetBDFF:
	ldw bc, 0xbd
	ldw de, 0xff

PartInit_WriteAndReturn:
	calr Part_WriteByte
	popw iz
	inc 2, xsp
	ret

Part_WriteAllVoiceSubBlocks_A:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ldib_erp 0xfb, 1

PartSubBlkA_WriteLoop32:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldto_berp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (PartSubBlkA_WriteLoop32_Table:24)
	ld	e, (xhl+de)
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkA_WriteLoop32
	ldib_erp 0xfb, 1

PartSubBlkA_WriteLoop48:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldto_berp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (PartSubBlkA_WriteLoop48_Table:24)
	ld	e, (xhl+de)
	calr Part_WriteSubBlock48
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkA_WriteLoop48
	popw_erp 0xfa
	inc 2, xsp
	ret

Part_WriteAllVoiceSubBlocks_B:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ldib_erp 0xfb, 1

PartSubBlkB_WriteLoop32:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldto_berp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (PartSubBlkB_WriteLoop32_Table:24)
	ld	e, (xhl+de)
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkB_WriteLoop32
	ldib_erp 0xfb, 1

PartSubBlkB_WriteLoop48:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldto_berp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (PartSubBlkA_WriteLoop48_Table:24)
	ld	e, (xhl+de)
	calr Part_WriteSubBlock48
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkB_WriteLoop48
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqPart_ResetVoicePositions:
	pushw_erp 0xfa
	cp (0x2878:16), 10
	jr nz, SeqPart_ResetPosSingle
	ldw (0x00ffec:24), 0x0000
	ldib_erp 0xfb, 1

SeqPart_ResetPosLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1e
	ld de, 0:i3
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqPart_ResetPosLoop
	jr SeqPart_ResetPosReturn

SeqPart_ResetPosSingle:
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	ldw bc, 0x1e
	ld de, 0:i3
	calr Part_WriteWord

SeqPart_ResetPosReturn:
	popw_erp 0xfa
	ret

SeqData_CopyBlock2K:
	cp a, 0:i3
	jr nz, SeqCopy2K_ComputeAddr
	lda xhl, (0xf280:16)
	jr SeqCopy2K_SetupTransfer

SeqCopy2K_ComputeAddr:
	dec 1, a
	ld w, 0x0:opc
	extz xwa
	sll xwa, 11
	lda xwa, (xwa+256)
	lda xhl, (SEQ_SONG_SLOTS:24)
	add xhl, xwa

SeqCopy2K_SetupTransfer:
	ld xde, xbc
	lda xbc, (xbc + 16)

SeqCopy2K_TransferLoop:
	ld A, (xhl+)
	ld (xde+), a
	cp xde, xbc
	jr c, SeqCopy2K_TransferLoop
	ret

SeqPart_ReadNextEventByte:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xbc
	ld xiz, xwa
	ld wa, (xiz)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xde, (0x0b0000:24)
	add xde, xwa
	lda xhl, (xiz + 2)
	ld bc, (xhl)
	extz xbc
	add xbc, xde
	ld xwa, (xsp + 6)
	ld c, (xbc)
	ld (xwa), c
	ld (xsp + 4), 0x1
	cp (xwa), 0x82
	jr z, SeqEvent_EndMarkerFound
	cp (xwa), 0x84
	jr nz, SeqEvent_CheckPageBoundary

SeqEvent_EndMarkerFound:
	ld hl, 1:i3
	jrl SeqEvent_Return

SeqEvent_CheckPageBoundary:
	ld wa, (xhl)
	cp wa, 0xff
	jr nz, SeqEvent_IncrementPos
	ldw (xhl), 0x5
	ld wa, (xiz)
	calr PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0xffff
	jr z, SeqEvent_ErrorReturn
	ld wa, (xiz)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xde, (0x0b0000:24)
	add xde, xwa
	jr SeqEvent_CheckHighBit

SeqEvent_IncrementPos:
	inc 1, wa
	ld (xhl), wa

SeqEvent_CheckHighBit:
	ld xwa, (xsp + 6)
	bitm 7, (xwa)
	jr z, SeqEvent_ErrorReturn

SeqEvent_ReadParamBytes:
	ld l, (xsp + 4)
	extz hl
	lda xix, (xiz + 2)
	ld wa, (xix)
	extz xwa
	add xwa, xde
	ld c, (xwa)
	ld xwa, (xsp + 6)
	ld	(xwa+hl), c
	bit 7, c
	jr nz, SeqEvent_StoreParamCount
	incm8 1, (xsp + 4)
	ld wa, (xix)
	cp wa, 0xff
	jr nz, SeqEvent_IncrementPosAlt
	ldw (xix), 0x5
	ld wa, (xiz)
	calr PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0xffff
	jr nz, SeqEvent_NewPageSetup

SeqEvent_ErrorReturn:
	ldw hl, 0xffff
	jr SeqEvent_Return

SeqEvent_NewPageSetup:
	ld wa, (xiz)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xde, (0x0b0000:24)
	add xde, xwa
	jr SeqEvent_CheckMaxParams

SeqEvent_IncrementPosAlt:
	inc 1, wa
	ld (xix), wa

SeqEvent_CheckMaxParams:
	cp (xsp + 4), 0x8
	jr c, SeqEvent_ReadParamBytes

SeqEvent_StoreParamCount:
	ld l, (xsp + 4)
	extz hl

SeqEvent_Return:
	pop xiz
	inc 6, xsp
	ret

Part_CopyBytesToVoiceBlock:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 6), e
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xde, (0x0b0000:24)
	add xde, xwa
	ldw (xsp + 4), 0x0
	ld a, (xsp + 6)
	extz wa
	cp wa, 0:i3
	jrl ule, PartCopyVoice_ReturnOK

PartCopyVoice_MainLoop:
	ld xwa, (xsp + 12)
	lda xbc, (xwa + 2)
	ld hl, (xbc)
	extz xhl
	add xhl, xde
	ld wa, (xsp + 4)
	extz xwa
	add xwa, (xsp + 8)
	ld a, (xwa)
	ld (xhl), a
	ld hl, (xbc)
	cp hl, 0xff
	jr z, PartCopyVoice_PageBoundary
	inc 1, hl
	ld (xbc), hl
	jrl PartCopyVoice_IncrementCount

PartCopyVoice_PageBoundary:
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr nz, PartCopyVoice_StoreNewPage
	ld iz, (0xf22f:16)
	cp iz, 0xffff
	jr nz, PartCopyVoice_ReadAndRelink
	ldw hl, 0xffff
	jr PartCopyVoice_Return

PartCopyVoice_ReadAndRelink:
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartCopyVoice_UpdateChain
	ldto_werp WA, 0xfa
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1

PartCopyVoice_UpdateChain:
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	ld bc, iz
	calr PartCtrl_WriteWord
	ld xwa, (xsp + 12)
	ld bc, (xwa)
	ld wa, iz
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	ld xwa, (xsp + 12)
	ld (xwa), iz
	calr Part_DecrementVoicePos
	jr PartCopyVoice_RecomputeAddr

PartCopyVoice_StoreNewPage:
	ld xwa, (xsp + 12)
	ldto_werp BC, 0xfa
	ld (xwa), bc

PartCopyVoice_RecomputeAddr:
	ld xbc, (xsp + 12)
	ld wa, (xbc)
	dec 1, wa
	extz xwa
	sll xwa, 8
	ld xde, 0xb0000
	add xde, xwa
	ldw (xbc + 2), 0x5

PartCopyVoice_IncrementCount:
	incw 1, (xsp + 4)
	ld a, (xsp + 6)
	extz wa
	cp (xsp + 4), wa
	jrl c, PartCopyVoice_MainLoop

PartCopyVoice_ReturnOK:
	ld hl, 0:i3

PartCopyVoice_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PartCtrl_InitChainLinkedList:
	pushw iz
	ld wa, 1:i3
	calr Part_WriteWordBlock_OffsetAF
	ldw wa, 0x4d8
	calr Part_SetAllVoicePos
	ld iz, 1:i3

PartChain_InitLoop:
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_SetClearBit7
	ld bc, iz
	dec 1, bc
	ld wa, iz
	calr PartCtrl_WriteWord_Off1
	ld bc, iz
	inc 1, bc
	ld wa, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	inc 1, iz
	cp iz, 0x4d8
	jr ule, PartChain_InitLoop
	ld wa, 1:i3
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ldw wa, 0x4d8
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	popw iz
	ret

PartCtrl_ReadWord_Off1:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 1, xwa
	ld xbc, 0xb0000
	add xbc, xwa
	ld hl, (xbc)
	ret

PartCtrl_WriteWord_Off1:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 1, xwa
	ld xde, 0xb0000
	add xde, xwa
	ld (xde), bc
	ret

PartCtrl_ReadWord:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 3, xwa
	ld xbc, 0xb0000
	add xbc, xwa
	ld hl, (xbc)
	ret

; ============================================================================
; PartCtrl_WriteWord - Write 16-bit word to part control register
; ============================================================================
; Input:  WA = part number (1-based)
;         BC = 16-bit value to write
; Address: 0xb0000 + (WA-1)*256 + 3  (256 bytes per part)
; Family: offset 1 (PartCtrl_WriteWord_Off1), offset 3 (this), read (PartCtrl_ReadWord),
;         bit 7 test (PartCtrl_TestBit7), bit 7 set/clear (PartCtrl_SetClearBit7)
; ============================================================================
PartCtrl_WriteWord:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 3, xwa
	ld xde, 0xb0000
	add xde, xwa
	ld (xde), bc
	ret

PartCtrl_TestBit7:
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xbc, (0x0b0000:24)
	add xbc, xwa
	ld l, (xbc)
	and l, 0x80
	ret

PartCtrl_SetClearBit7:
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda xde, (0x0b0000:24)
	add xde, xwa
	cp c, 0:i3
	jr z, PartCtrl_SetClearBit7_ClearPath
	setm 7, (xde)
	ret

PartCtrl_SetClearBit7_ClearPath:
	resm 7, (xde)
	ret

PartCtrl_ReadByte:
	extz bc
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda	xwa, (xwa+bc)
	lda xbc, (0x0b0000:24)
	add xbc, xwa
	ld l, (xbc)
	ret

PartCtrl_WriteByteToBuf:
	extz bc
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda	xwa, (xwa+bc)
	lda xbc, (0x0b0000:24)
	add xbc, xwa
	ld (xbc), e
	ret

PartCtrl_DataBlock_CE1:
	push	xiz
	ld	xiz, xwa
	lda	xde, (xiz+2)
	ld	hl, (xde)
	extz	xhl
	ld	wa, (xiz)
	dec	1, wa
	extz	xwa
	sll	xwa, 8
	add	xwa, xhl
	lda	xhl, (0x0b0000:24)
	add	xhl, xwa
	ld	(xhl), c
	ld	hl, (xde)
	cp	hl, 5:i3
	jr	z, PartCtrl_WriteByteToBuf_Skip
	dec	1, hl
	ld	(xde), hl
	jr	PartCtrl_WriteByteToBuf_Join
PartCtrl_WriteByteToBuf_Skip:
	ld	wa, (xiz)
	calr	PartCtrl_ReadWord_Off1
	cp	hl, 0:i3
	jr	nz, PartCtrl_WriteByteToBuf_Skip2
	ldw	hl, 0xffff
	jr	PartCtrl_WriteByteToBuf_Epilogue
PartCtrl_WriteByteToBuf_Skip2:
	ld	(xiz), hl
	ldw (xiz+2), 5
PartCtrl_WriteByteToBuf_Join:
	ld	hl, 0:i3
PartCtrl_WriteByteToBuf_Epilogue:
	pop	xiz
	ret
	push	xiz
	ld	xiz, xwa
	lda	xde, (xiz+2)
	ld	hl, (xde)
	extz	xhl
	ld	wa, (xiz)
	dec	1, wa
	extz	xwa
	sll	xwa, 8
	add	xwa, xhl
	lda	xhl, (0x0b0000:24)
	add	xhl, xwa
	ld	a, (xhl)
	ld	(xbc), a
	ld	hl, (xde)
	cp	hl, 5:i3
	jr	z, PartCtrl_WriteByteToBuf_Skip3
	dec	1, hl
	ld	(xde), hl
	jr	PartCtrl_WriteByteToBuf_Join2
PartCtrl_WriteByteToBuf_Skip3:
	ld	wa, (xiz)
	calr	PartCtrl_ReadWord_Off1
	cp	hl, 0:i3
	jr	nz, PartCtrl_WriteByteToBuf_Skip4
	ldw	hl, 0xffff
	jr	PartCtrl_WriteByteToBuf_Epilogue2
PartCtrl_WriteByteToBuf_Skip4:
	ld	(xiz), hl
	ldw (xiz+2), 5
PartCtrl_WriteByteToBuf_Join2:
	ld	hl, 0:i3
PartCtrl_WriteByteToBuf_Epilogue2:
	pop	xiz
	ret

PartCtrl_WriteBytePair:
	push xiz
	ld xiz, xde
	ld hl, bc
	extz xhl
	ld de, wa
	dec 1, de
	extz xde
	sll xde, 8
	add xde, xhl
	lda xhl, (0x0b0000:24)
	add xhl, xde
	ld e, (xiz)
	ld (xhl), e
	cp bc, 0xff
	jr nz, PartCtrl_WritePair_NotFF
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr nz, PartCtrl_WritePair_ReadNext
	ldw hl, 0xffff
	jr PartCtrl_WritePair_Return

PartCtrl_WritePair_ReadNext:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda xhl, (0x0b0000:24)
	add xhl, xwa
	jr PartCtrl_WritePair_WriteSecond

PartCtrl_WritePair_NotFF:
	inc 1, xhl

PartCtrl_WritePair_WriteSecond:
	ld a, (xiz + 1)
	ld (xhl), a
	ld hl, 0:i3

PartCtrl_WritePair_Return:
	pop xiz
	ret

PartCtrl_DeallocAndWriteEnd:
	dec 4, xsp
	lda xde, (xsp)
	lda xbc, (9460:16)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld wa, (xde)
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, PartCtrl_DeallocAndWrite_WriteByte
	calr Part_StealAndReallocVoices
	ld wa, (xsp + 0:8)
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

PartCtrl_DeallocAndWrite_WriteByte:
	ld wa, (xsp + 0:8)
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	inc 4, xsp
	ret

Part_DeallocVoices1And2:
	ld wa, 1:i3
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, Part_DeallocVoices_Voice2
	calr Part_StealAndReallocVoices
	ld wa, 1:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_DeallocVoices_Voice2:
	ld wa, 1:i3
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	ld wa, 2:i3
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, Part_DeallocVoices_Voice2Write
	calr Part_StealAndReallocVoices
	ld wa, 2:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_DeallocVoices_Voice2Write:
	ld wa, 2:i3
	ld bc, 5:i3
	ldw de, 0x82
	jrl PartCtrl_WriteByteToBuf

Part_UnlinkVoiceFromChain:
	push xiz
	ld wa, 1:i3
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, Part_UnlinkVoice_CheckVoice2
	ld wa, 1:i3
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	ld wa, 1:i3
	calr PartCtrl_ReadWord_Off1
	ldfr_werp HL, 0xfa
	ld wa, 1:i3
	calr PartCtrl_ReadWord
	ld iz, hl
	cpiw_erp 0xfa, 0
	jr nz, Part_UnlinkVoice1_HasNext
	cp iz, 0xffff
	jr z, Part_UnlinkVoice1_Clear
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	ld bc, 0:i3
	jr Part_UnlinkVoice1_WriteOff1

Part_UnlinkVoice1_HasNext:
	cp iz, 0xffff
	jr nz, Part_UnlinkVoice1_LinkPrevNext
	ldto_werp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	jr Part_UnlinkVoice1_Clear

Part_UnlinkVoice1_LinkPrevNext:
	ldto_werp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ldto_werp BC, 0xfa

Part_UnlinkVoice1_WriteOff1:
	calr PartCtrl_WriteWord_Off1

Part_UnlinkVoice1_Clear:
	ld wa, 1:i3
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, 1:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_UnlinkVoice_CheckVoice2:
	ld wa, 2:i3
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, SeqStatus_ClearBit2
	ld wa, 2:i3
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	ld wa, 2:i3
	calr PartCtrl_ReadWord_Off1
	ldfr_werp HL, 0xfa
	ld wa, 2:i3
	calr PartCtrl_ReadWord
	ld iz, hl
	cpiw_erp 0xfa, 0
	jr nz, Part_UnlinkVoice2_HasNext
	cp iz, 0xffff
	jr z, SeqStatus_WriteByte
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	ld bc, 0:i3
	jr SeqStatus_SetBit2

Part_UnlinkVoice2_HasNext:
	cp iz, 0xffff
	jr nz, SeqStatus_ClearBitAndSet
	ldto_werp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	jr SeqStatus_WriteByte

SeqStatus_ClearBitAndSet:
	ldto_werp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ldto_werp BC, 0xfa

SeqStatus_SetBit2:
	calr PartCtrl_WriteWord_Off1

SeqStatus_WriteByte:
	ld wa, 2:i3
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, 2:i3
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

SeqStatus_ClearBit2:
	pop xiz
	ret

Part_ClearAllVoiceChannels:
	pushw_erp 0xfa
	calr PartCtrl_InitChainLinkedList
	ldw (0x00ffec:24), 0x0000
	calr Part_UnlinkVoiceFromChain
	ldib_erp 0xfa, 0

SeqStatus_ReadBit2Check:
	ldib_erp 0xfb, 1

SeqStatus_ReadReturn:
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 0:i3
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	addb_erp C, 0xfb
	add c, 0x76
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	add c, 0x97
	extz bc
	ld de, 5:i3
	calr Part_WriteByte
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqStatus_ReadReturn
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x0a
	jr ule, SeqStatus_ReadBit2Check
	popw_erp 0xfa
	ret

Part_StealAndReallocVoices:
	push xiz
	ld iz, wa
	cp iz, 0xffff
	jr z, SeqMode_ReturnState

SeqMode_CheckAndSetState:
	ld wa, iz
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, SeqMode_SetActiveState
	ldw wa, 0x28
	calr SeqData_SetErrorCode
	jr SeqMode_ReturnState

SeqMode_SetActiveState:
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_SetClearBit7
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ld wa, iz
	calr PartCtrl_AppendToFreeList
	ldto_werp IZ, 0xfa
	cp iz, 0xffff
	jr nz, SeqMode_CheckAndSetState

SeqMode_ReturnState:
	pop xiz
	ret

PartCtrl_AppendToFreeList:
	pushw iz
	ld iz, wa
	ld bc, (0xf22f:16)
	ld wa, iz
	calr PartCtrl_WriteWord
	ld wa, (0xf22f:16)
	ld bc, iz
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_SetClearBit7
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	calr Part_IncrementVoicePos
	ld wa, iz
	ld bc, 5:i3
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	popw iz
	ret

Part_LinkVoiceToChain:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	ld wa, (xsp + 2)
	calr PartCtrl_ReadWord
	cp hl, 0xffff
	jr z, SeqPlay_CheckStartCondition
	ldw wa, 0x8
	calr SeqData_SetErrorCode
	jr SeqPlay_StartReturn

SeqPlay_CheckStartCondition:
	calr Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqPlay_InitPlayback

SeqPlay_StartReturn:
	ldw hl, 0xffff
	jr SeqPlay_ValidateAndBegin

SeqPlay_InitPlayback:
	ld wa, (xsp + 2)
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, (xsp + 2)
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	ld hl, iz

SeqPlay_ValidateAndBegin:
	popw iz
	inc 2, xsp
	ret

Part_ProcessAndDecrementVoice:
	push xiz
	ld iz, (0xf22f:16)
	cp iz, 0xffff
	jr z, SeqPlay_PlaybackReturn
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ldto_werp WA, 0xfa
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xfa, 0xff, 0xff
	jr z, SeqPlay_BeginPlayback
	ldto_werp WA, 0xfa
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1

SeqPlay_BeginPlayback:
	ld wa, iz
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos

SeqPlay_PlaybackReturn:
	ld hl, iz
	pop xiz
	ret

MIDI_GetEventSize:
	ld c, a
	and c, 0xf0
	cp c, 0xc0
	jr z, MIDI_Status_6
	cp c, 0xb0
	jr z, MIDI_Status_6
	cp c, 0x90
	jr z, MIDI_Status_6
	cp a, 0xd3
	jr z, MIDI_Status_3
	cp a, 0xd2
	jr z, SeqPlay_ResetState
	cp a, 0xd1
	jr z, MIDI_Status_3
	cp a, 0xd0
	jr z, MIDI_Status_3
	cp a, 0x86
	jr z, SeqPlay_StopAndReset
	cp a, 0x85
	jr z, SeqPlay_StopAndReset
	cp a, 0x80
	jr z, SeqPlay_ResetState
	ld l, 0x1:opc

MIDI_NullRet:
	ret

MIDI_Status_6:
	ld l, 0x6:opc
	jr MIDI_NullRet

SeqPlay_StopAndReset:
	ld l, 0x2:opc
	jr MIDI_NullRet

MIDI_Status_3:
	ld l, 0x3:opc
	jr MIDI_NullRet

SeqPlay_ResetState:
	ld l, 0x4:opc
	jr MIDI_NullRet

SeqPos_AdvanceWithWrap:
	ld c, a
	extz bc
	ld wa, (9830:16)
	add wa, bc
	ld (9830:16), wa
	cp wa, 0xff
	ret ule
	sub wa, 0x100
	inc 5, wa
	ld (9830:16), wa
	ld wa, (0x28af:16)
	calr PartCtrl_ReadWord
	ld (0x28af:16), hl
	ret

SeqPlay_StopReturn:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	iz, bc
	ld	c, a
	ldib_erp 251, 0
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadVoiceWord
	ld	(0x28af:16), hl
	cp	hl, 0xffff
	jr	nz, SeqPos_AdvanceWithWrap_Skip
	ldw	hl, 0xffff
	jr	SeqPos_AdvanceWithWrap_Epilogue
SeqPos_AdvanceWithWrap_Skip:
	ldw	(9830:16), 5
	cp	iz, 0:i3
	jr	ule, SeqPos_AdvanceWithWrap_Skip3
SeqPos_AdvanceWithWrap_Loop:
	calr	SeqData_ReadNextByte
	cp	l, 129
	jr	nz, SeqPos_AdvanceWithWrap_Skip2
	inc1b_erp 251
	calr PartCtrl_RefreshWordPeriodic
	jr	SeqPos_AdvanceWithWrap_Join
SeqPos_AdvanceWithWrap_Skip2:
	cp	l, 130
	jr	z, SeqPos_AdvanceWithWrap_Skip3
	extz	hl
	ld	wa, hl
	calr	MIDI_GetEventSize
	extz	hl
	ld	wa, hl
	calr	SeqPos_AdvanceWithWrap
SeqPos_AdvanceWithWrap_Join:
	ldto_berp a, 251
	extz	wa
	cp	wa, iz
	jr	c, SeqPos_AdvanceWithWrap_Loop
SeqPos_AdvanceWithWrap_Skip3:
	ld	xde, (xsp+4)
	ldw	(xde), (10415)
	ld	wa, (9830:16)
	ld	c, a
	extz	bc
	ld	(xde+2), bc
	ld	hl, 0:i3
SeqPos_AdvanceWithWrap_Epilogue:
	pop	xiz
	inc	4, xsp
	ret

SeqData_SkipToCurrentBar:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	cp (8972:16), 0
	jr ule, SeqMIDI_ProcessReturn

SeqMIDI_ProcessEventByte:
	calr SeqData_ReadNextByte
	cp l, 0x81
	jr nz, SeqMIDI_CheckRunningStatus
	inc1b_erp 0xfb
	calr PartCtrl_RefreshWordPeriodic
	jr SeqMIDI_StoreEventByte

SeqMIDI_CheckRunningStatus:
	extz hl
	ld wa, hl
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqMIDI_StoreEventByte:
	ldto_berp A, 0xfb
	cp a, (8972:16)
	jr c, SeqMIDI_ProcessEventByte

SeqMIDI_ProcessReturn:
	popw_erp 0xfa
	ret

SeqData_SeekToPartStart:
	ld c, (9696:16)
	inc 1, c
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	ld (0x28af:16), hl
	ldw (9830:16), 5
	ret

; ============================================================================
; SeqData_ReadNextByte - Read next byte from sequence data stream
; ============================================================================
; Reads from Table Data ROM at 0x0b0000 region using current position (9830)
; and data pointer (10415). Returns byte in L register.
; Called by sequencer routines that check for end marks (0x81, 0x82, 0x84).
; ============================================================================
SeqData_ReadNextByte:
	ld wa, (9830:16)
	ld c, a
	extz bc
	ld wa, (0x28af:16)
	jrl PartCtrl_ReadByte

PartCtrl_WriteByte_Indexed:
	ld e, a
	ld bc, (9830:16)
	extz bc
	extz de
	ld wa, (0x28af:16)
	jrl PartCtrl_WriteByteToBuf

PartCtrl_RefreshWordPeriodic:
	ld wa, (9830:16)
	cp wa, 0xff
	jr nz, SeqMIDI_WriteEventToBuffer
	ld wa, (0x28af:16)
	calr PartCtrl_ReadWord
	ld (0x28af:16), hl
	ldw (9830:16), 5
	ret

SeqMIDI_WriteEventToBuffer:
	inc 1, wa
	ld (9830:16), wa
	ret

SeqMIDI_BufferWriteSetup:
	ld wa, (0x28af:16)
	ld bc, (9830:16)
	cp bc, 0xff
	jr nz, SeqMIDI_BufferOverflow
	calr PartCtrl_ReadWord
	ld wa, hl
	ld bc, 5:i3
	jr SeqMIDI_BufferWriteReturn

SeqMIDI_BufferOverflow:
	inc 1, bc

SeqMIDI_BufferWriteReturn:
	extz bc
	jrl PartCtrl_ReadByte

Voice_ScanAvailableChannel:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 16), c
	ld iz, wa
	ld (9696:16), 0

SeqMIDI_BufferFull:
	ld c, (9696:16)
	inc 1, c
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, SeqMIDI_WriteDataByte
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_BufferFullReturn
	slaa bc

SeqMIDI_BufferFullReturn:
	jr SeqMIDI_FlushBuffer

SeqMIDI_WriteDataByte:
	ld a, (9696:16)
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqMIDI_DataWriteReturn
	slaa bc

SeqMIDI_DataWriteReturn:
	ld wa, bc
	and wa, (0x28a8:16)
	jr z, SeqScan_PartEntry
	bit 1, (0x28b1:16)
	jr nz, SeqScan_PartEntry
	bit 0, (0x28c5:16)
	jr nz, SeqScan_PartEntry

SeqMIDI_FlushBuffer:
	cpl bc
	and (8982:16), bc
	jrl SeqScan_AdvancePartIndex

SeqScan_PartEntry:
	or (8982:16), bc
	ldw (9614:16), 0
	calr SeqData_SeekToPartStart
	ld a, (9696:16)
	inc 1, a
	cp a, (8988:16)
	jrl nz, SeqMIDI_ReadBufferReturn
	lda xbc, (7590:16)
	ld wa, (0x28af:16)
	ld (xbc), wa
	ld wa, (9830:16)
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 4)
	ldmw2 (xwa), 0x28af
	ldmw2 (xwa + 2), 0x2666

SeqPart_ScanControlChanges:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	lda xhl, (xsp + 8)
	lda xde, (xhl + 4)
	lda xbc, (xhl + 5)
	cp (xhl + 1), 0x0
	jrl nz, SeqMIDI_ReadBufferEmpty
	ld a, (xhl)
	cp a, 0x81
	jrl z, SeqMIDI_ReadBufferEmpty
	cp a, 0x82
	jrl z, SeqMIDI_ReadBufferEmpty
	and a, 0xf0
	cp a, 0xb0
	jr nz, SeqPart_ScanControlChanges
	ld a, (xhl + 3)
	cp a, 6:i3
	jr nz, SeqMIDI_ReadFromBuffer
	bitm 2, (xbc)
	jr z, SeqPart_ScanControlChanges
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	set 1, (8974:16)
	ldw (4360:16), 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqMIDI_ReadBufferCheck

SeqMIDI_ReadFromBuffer:
	cp a, 5:i3
	jr nz, SeqPart_ScanControlChanges
	ld a, (xbc)
	bit 2, a
	jr z, SeqMIDI_ReadBufferLoop
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	set 1, (8974:16)
	ldw (4360:16), 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqMIDI_ReadBufferCheck

SeqMIDI_ReadBufferLoop:
	bit 3, a
	jr z, SeqPart_ScanControlChanges
	bitm 3, (xde)
	jrl z, SeqPart_ScanControlChanges
	set 1, (8974:16)
	ldw (4360:16), 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl

SeqMIDI_ReadBufferCheck:
	calr SeqBuf_AllocNextSlot
	ld (8972:16), l
	ldw (4360:16), 0
	jrl SeqPart_ScanControlChanges

SeqMIDI_ReadBufferEmpty:
	calr SeqData_SeekToPartStart

SeqMIDI_ReadBufferReturn:
	ld a, (9696:16)
	inc 1, a
	cp a, (8990:16)
	jr nz, SeqMIDI_DispatchEventType
	lda xwa, (7594:16)
	ldmw2 (xwa), 0x28af
	ldmw2 (xwa + 2), 0x2666

SeqMIDI_DispatchEventType:
	cp (9614:16), iz
	jrl nc, SeqScan_CheckPartActiveAndStore

SeqMIDI_DispatchProgramChange:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x81
	jr nz, SeqMIDI_DispatchReturn
	incw 1, (9614:16)
	calr PartCtrl_RefreshWordPeriodic
	jrl SeqData_ContinuePos

SeqMIDI_DispatchReturn:
	cp_erpb 0xfb, 0x82
	jr nz, SeqMIDI_NoteWithVelocity
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_ProcessControlChange
	slaa bc

SeqMIDI_ProcessControlChange:
	cpl bc
	ld wa, bc
	ld bc, (8982:16)
	and bc, wa
	ld (8982:16), bc
	cpw (0x28a8:16), 0
	jrl z, SeqScan_CheckPartActiveAndStore
	bit 1, (0x28b1:16)
	jrl z, SeqScan_CheckPartActiveAndStore
	cp (CURRENT_MODE:16), 11
	jrl nz, SeqScan_CheckPartActiveAndStore
	ld e, (9696:16)
	ld a, e
	inc 1, a
	cp a, (8986:16)
	jrl nz, SeqScan_CheckPartActiveAndStore
	ld hl, 1:i3
	ld a, e
	and a, 0xf
	jr z, SeqMIDI_HandleNoteEvent
	slaa hl

SeqMIDI_HandleNoteEvent:
	or bc, hl
	ld (8982:16), bc
	jrl SeqScan_CheckPartActiveAndStore

SeqMIDI_NoteWithVelocity:
	cp_erpb 0xfb, 0x84
	jr nz, SeqMIDI_NoteEventReturn
	calr SeqData_SeekToPartStart
	ld a, (9696:16)
	inc 1, a
	cp a, (8988:16)
	jr nz, SeqData_ContinuePos
	calr SeqData_SkipToCurrentBar
	jr SeqData_ContinuePos

SeqMIDI_NoteEventReturn:
	ldto_berp A, 0xfb
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqData_ContinuePos:
	cp (9614:16), iz
	jrl c, SeqMIDI_DispatchProgramChange
	jrl SeqScan_CheckPartActiveAndStore

SeqMIDI_HandlePitchBend:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x81
	jrl z, SeqScan_StoreTrackEndData
	cp_erpb 0xfb, 0x82
	jr nz, SeqMIDI_SysExReadLoop
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_PitchBendReturn
	slaa bc

SeqMIDI_PitchBendReturn:
	cpl bc
	ld wa, bc
	ld bc, (8982:16)
	and bc, wa
	ld (8982:16), bc
	cpw (0x28a8:16), 0
	jr z, SeqScan_StoreTrackEndData
	bit 1, (0x28b1:16)
	jr z, SeqScan_StoreTrackEndData
	cp (CURRENT_MODE:16), 11
	jr nz, SeqScan_StoreTrackEndData
	ld e, (9696:16)
	ld a, e
	inc 1, a
	cp a, (8986:16)
	jr nz, SeqScan_StoreTrackEndData
	ld hl, 1:i3
	ld a, e
	and a, 0xf
	jr z, SeqMIDI_HandleSysEx
	slaa hl

SeqMIDI_HandleSysEx:
	or bc, hl
	ld (8982:16), bc
	jr SeqScan_StoreTrackEndData

SeqMIDI_SysExReadLoop:
	cp_erpb 0xfb, 0x84
	jr nz, SeqMIDI_SysExReturn
	calr SeqData_SeekToPartStart
	ld a, (9696:16)
	inc 1, a
	cp a, (8988:16)
	jr nz, SeqScan_CheckPartActiveAndStore
	calr SeqData_SkipToCurrentBar
	jr SeqScan_CheckPartActiveAndStore

SeqMIDI_SysExReturn:
	calr SeqMIDI_BufferWriteSetup
	cp l, (xsp + 16)
	jr nc, SeqScan_StoreTrackEndData
	ldto_berp A, 0xfb
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqScan_CheckPartActiveAndStore:
	ld bc, 1:i3
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_HandleChannelPressure
	slaa bc

SeqMIDI_HandleChannelPressure:
	and bc, (8982:16)
	jrl nz, SeqMIDI_HandlePitchBend

SeqScan_StoreTrackEndData:
	ld c, (9696:16)
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqMIDI_ChannelPressureReturn
	slaa de

SeqMIDI_ChannelPressureReturn:
	and de, (8982:16)
	jr z, SeqScan_AdvancePartIndex
	inc 1, c
	extz bc
	ld hl, (0x28af:16)
	ld de, (9830:16)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de

SeqScan_AdvancePartIndex:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jrl c, SeqMIDI_BufferFull
	calr Accomp_ValidateAutoPlayChordVoice
	pop xiz
	lda xsp, (xsp + 14)
	ret

SeqScan_ProcessAllParts:
	dec 6, xsp
	push xiz
	ld (xsp + 8), wa
	ld wa, (8982:16)
	ld (8980:16), wa
	ld (9696:16), 0

SeqMIDI_GetEventSizeTable:
	ld a, (9696:16)
	ldfr_berp A, 0xf0
	ld bc, 1:i3
	ldto_berp A, 0xf0
	and a, 0xf
	jr z, SeqMIDI_GetEventSizeLookup
	slaa bc

SeqMIDI_GetEventSizeLookup:
	ld wa, bc
	and wa, (8982:16)
	lda xde, (xsp + 4)
	lda xhl, (9184:16)
	lda xbc, (xde + 2)
	cp wa, 0:i3
	jrl z, SeqMIDI_ChannelOutOfRange
	ldto_berp A, 0xf0
	extz wa
	ld iy, wa
	sla iy, 3
	lda xix, (9016:16)
	ld wa, (xsp + 8)
	ld	(xix+iy), wa
	ld a, (9696:16)
	inc 1, a
	ldfr_berp A, 0xe2
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	lda	xiz, (xhl+wa)
	lda xiy, (xiz + 2)
	ldto_berp A, 0xe2
	cp a, (8988:16)
	jr nz, SeqMIDI_ValidateChannel
	ld wa, (xiz)
	ld (xde), wa
	ld wa, (xiy)
	ld (xbc), wa
	ld c, a
	extz bc
	ld de, (xde)
	lda xwa, (xhl + 76)
	ld (xwa), de
	ld (xwa + 2), bc
	ld wa, (xsp + 8)
	ld	(xix+152), wa
	ldw wa, 0x14
	jr SeqMIDI_ChannelInRange

SeqMIDI_ValidateChannel:
	ldto_berp A, 0xe2
	cp a, (8996:16)
	jr nz, SeqMIDI_ChannelReturn
	ld wa, (xiz)
	ld (xde), wa
	ld wa, (xiy)
	ld (xbc), wa
	ld c, a
	extz bc
	ld de, (xde)
	lda xwa, (xhl + 80)
	ld (xwa), de
	ld (xwa + 2), bc
	ld wa, (xsp + 8)
	ld	(xix+160), wa
	ldw wa, 0x15

SeqMIDI_ChannelInRange:
	calr SeqCh_LoadChannelConfig

SeqMIDI_ChannelReturn:
	ld a, (9696:16)
	inc 1, a
	extz wa
	calr SeqCh_LoadChannelConfig

SeqMIDI_ChannelOutOfRange:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jrl c, SeqMIDI_GetEventSizeTable
	pop xiz
	inc 6, xsp
	ret

Part_CheckAndReallocVoices:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, PartRealloc_Return
	cp wa, 0x4d8
	jr ule, PartRealloc_StealAndClear
	ld (SEQ_ERROR_CODE:16), 10
	jr PartRealloc_Return

PartRealloc_StealAndClear:
	calr Part_StealAndReallocVoices
	ld wa, iz
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

PartRealloc_Return:
	popw iz
	ret

PartCtrl_SwapAndRelinkBlock:
	dec	8, xsp
	push	xiz
	ld	iz, wa
	ld	(xsp+8), bc
	ldw	(xsp+10), (61999)
	ld	(0xf22f:16), iz
	ldw	(xsp+4), 0
	ld	wa, iz
	calr	PartCtrl_ReadWord_Off1
	ld	(xsp+6), hl
	ld	wa, iz
	ld	bc, 0:i3
	calr	PartCtrl_WriteWord_Off1
Part_CheckAndReallocVoices_Join:
	ld	wa, iz
	calr	PartCtrl_ReadWord
	ld qiz, hl
	cpw qiz, 65535
	jr	nz, Part_CheckAndReallocVoices_Skip2
	ld	(xsp+8), iz
	incw	1, (xsp+4)
Part_CheckAndReallocVoices_Entry:
	cpw	(xsp+6), 0
	jr	z, Part_CheckAndReallocVoices_Skip
	ld	wa, (xsp+6)
	ld	bc, qiz
	calr	PartCtrl_WriteWord
Part_CheckAndReallocVoices_Skip:
	ld	wa, (xsp+8)
	ld	bc, 0:i3
	calr	PartCtrl_SetClearBit7
	ld	wa, (xsp+8)
	ld	bc, 5:i3
	ldw	de, 130
	calr	PartCtrl_WriteByteToBuf
	ld	wa, (xsp+8)
	ld	bc, (xsp+10)
	calr	PartCtrl_WriteWord
	ld	wa, (xsp+10)
	ld	bc, (xsp+8)
	calr	PartCtrl_WriteWord_Off1
	ld	wa, (xsp+4)
	add (62001:16), wa
	pop	xiz
	inc	8, xsp
	ret
Part_CheckAndReallocVoices_Skip2:
	ld	wa, iz
	ld	bc, 0:i3
	calr	PartCtrl_SetClearBit7
	ld	wa, iz
	ld	bc, 5:i3
	ldw	de, 130
	calr	PartCtrl_WriteByteToBuf
	incw	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, (xsp+8)
	jr	nz, Part_CheckAndReallocVoices_Skip3
	ld	(xsp+8), iz
	ld	wa, iz
	calr	PartCtrl_ReadWord
	ld qiz, hl
	ld wa, qiz
	ld	bc, (xsp+6)
	calr	PartCtrl_WriteWord_Off1
	jr	Part_CheckAndReallocVoices_Entry
Part_CheckAndReallocVoices_Skip3:
	ld iz, qiz
	jrl	Part_CheckAndReallocVoices_Join

PartCtrl_ReadWordRoutine:
	push xiz
	ld iz, (0xf22f:16)
	cp iz, 0xffff
	jr nz, PartCtrlRd_ProcessAndRelink
	ldw hl, 0xffff
	jr PartCtrlRd_Return

PartCtrlRd_ProcessAndRelink:
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ld wa, iz
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, 1:i3
	calr PartCtrl_SetClearBit7
	ldto_werp WA, 0xfa
	ld (0xf22f:16), wa
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartCtrlRd_DecrementCount
	ldto_werp WA, 0xfa
	ld bc, 0:i3
	calr PartCtrl_WriteWord_Off1

PartCtrlRd_DecrementCount:
	decw 1, (0xf231:16)
	ld hl, iz

PartCtrlRd_Return:
	pop xiz
	ret

Rhythm_ComputeNoteAllocation:
	dec 4, xsp
	ldw (xsp + 2), 0x0
	ld (xsp), 0x0
	lda xbc, (xsp + 2)
	lda xde, (xsp)
	calr Rhythm_DispatchNoteAlloc
	ld hl, (xsp + 2)
	inc 4, xsp
	ret

Rhythm_NoteAllocBlock:
	dec	8, xsp
	push	xiz
	ld	(xsp+6), xde
	ld	iz, bc
	ld	(xsp+10), a
	ldw	(xsp+4), 0
	ld	c, (xsp+10)
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadSubBlock32
	ldfr_berp	l, 251
	lda	xbc, (xsp+4)
	ld	wa, iz
	ld	xde, (xsp+6)
	calr	Rhythm_DispatchNoteAlloc
	ld	a, (xsp+10)
	extz	wa
	cp_erpb	251, 13
	jr	z, Rhythm_ComputeNoteAllocation_Skip
	cp_erpb	251, 16
	jr	nz, Rhythm_ComputeNoteAllocation_Join
	calr	SeqEvt_ProcessBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	nz, Rhythm_ComputeNoteAllocation_Skip2
	jr	Rhythm_ComputeNoteAllocation_Join
Rhythm_ComputeNoteAllocation_Skip:
	calr	SeqEvt_ProcessBlock
	ld	iz, hl
	cp	iz, 0:i3
	jr	z, Rhythm_ComputeNoteAllocation_Join
	cp	(xsp+4), iz
	jr	c, Rhythm_ComputeNoteAllocation_Join
	ld	a, (xsp+10)
	extz	wa
	calr	Rhythm_ComputeNoteAllocation_Helper
	cp	hl, 0:i3
	jr	z, Rhythm_ComputeNoteAllocation_Skip2
	ld	bc, iz
	sub	bc, hl
	ld	wa, (xsp+4)
	sub	wa, hl
	extz	xwa
	div	xwa, bc
	ld	wa, qwa
	add	wa, hl
	ld	(xsp+4), wa
	jr	Rhythm_ComputeNoteAllocation_Join
Rhythm_ComputeNoteAllocation_Skip2:
	ld	wa, (xsp+4)
	extz	xwa
	div	xwa, iz
	ld	wa, qwa
	ld	(xsp+4), wa
Rhythm_ComputeNoteAllocation_Join:
	ld	hl, (xsp+4)
	pop	xiz
	inc	8, xsp
	ret

Rhythm_SetupAndDispatch:
	dec 6, xsp
	push xiz
	ldw (xsp + 8), 0x0
	ld (xsp + 6), 0x0
	ld (xsp + 4), 0x0
	calr Rhythm_CheckHighBitFlag
	cp l, 0:i3
	jr z, Rhythm_SetupFail
	calr Rhythm_ClearHighBitFlag
	cpw (0xf19e:16), 0
	jr z, Rhythm_SetupFail
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, Rhythm_SetupComputeState

Rhythm_SetupFail:
	ld l, 0xff:opc
	jr Rhythm_SetupReturn

Rhythm_SetupComputeState:
	calr Rhythm_ComputeNoteIndex
	ld iz, hl
	srl iz, 2
	and hl, 0x3
	ldfr_berp L, 0xfb
	lda xbc, (xsp + 8)
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	ld wa, iz
	calr Rhythm_ExtendedNoteAlloc
	ld (SEQ_BEAT_COUNT:16), iz
	ldto_berp A, 0xfb
	mul a, 0x18
	ld (SEQ_BEAT_TICK:16), a
	mrdb5 0x8f, 0x04, 0x19, 0x32, 0x23
	call SeqMode_SendStatusUpdate
	mrdw5 0x9f, 0x08, 0x19, 0x68, 0x26
	call NoteEditSy_SendModeScrollReset
	ld c, (xsp + 6)
	extz bc
	ld wa, iz
	sub wa, bc
	ld (9008:16), wa
	ld l, 0x0:opc

Rhythm_SetupReturn:
	pop xiz
	inc 6, xsp
	ret

Rhythm_CheckHighBitFlag:
	ld a, (1070:16)
	and a, 0x80
	srl a, 7
	ld l, a
	ret

Rhythm_ClearHighBitFlag:
	res 7, (1070:16)
	ret

Rhythm_ComputeNoteIndex:
	ld l, (1069:16)
	res 7, l
	extz hl
	ld a, (1070:16)
	res 7, a
	extz wa
	sll wa, 7
	add hl, wa
	ret

Rhythm_DispatchNoteAlloc:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld (xsp + 22), wa
	ld xiy, Rhythm_DispatchNoteAlloc_LocalInit
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, Rhythm_DispatchNoteAlloc_LocalInit_2
	lda xix, (xsp + 6)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr nz, Rhythm_AllocMultiVoice
	calr SeqPart_DispatchRhythmNote
	ld xwa, (xsp + 14)
	ld (xwa), l
	ld bc, (xsp + 22)
	dec 1, bc
	ld a, (xwa)
	extz wa
	mul xwa, bc
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	jrl Rhythm_AllocReturn

Rhythm_AllocMultiVoice:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xfa
	ld iz, 1:i3
	ldw (xsp + 4), 0x0
	ld xwa, (xsp + 18)
	ldw (xwa), 0x0
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	lda xwa, (xsp + 6)
	ld (xwa), hl
	ldw (xwa + 2), 0x5
	lda xiy, (xsp + 6)
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ldib_erp 0xfb, 1
	cpw (xsp + 22), 0x1
	jr ule, Rhythm_AllocCheckDone

Rhythm_AllocProcessLoop:
	lda xwa, (xsp + 6)
	calr SeqEvent_ProcessRhythm4Ch
	ld e, l
	ldto_berp C, 0xfa
	extz bc
	cp l, 0xb1
	jr z, SeqPart_NoteProcessing_Loop
	cp e, 0xb0
	jr z, SeqPart_NoteProcessing_Loop
	cp e, 0x84
	jr z, Rhythm_AllocResetMarker
	cp e, 0x82
	jr z, Rhythm_AllocEndSection
	cp e, 0x81
	jr nz, Rhythm_AllocStoreAndCont
	ld xwa, (xsp + 18)
	incw 1, (xwa)
	incw 1, (xsp + 4)
	cp (xsp + 4), bc
	jr c, SeqPart_NoteProcessing_Loop
	inc 1, iz
	ldw (xsp + 4), 0x0
	jr SeqPart_NoteProcessing_Loop

Rhythm_AllocEndSection:
	ld de, bc
	sub de, (xsp + 4)
	ld xhl, (xsp + 18)
	add (xhl), de
	inc 1, iz
	ld wa, (xsp + 22)
	sub wa, iz
	mul xwa, bc
	ld bc, wa
	add (xhl), bc
	ld iz, (xsp + 22)
	ldib_erp 0xfb, 0
	jr SeqPart_NoteProcessing_Loop

Rhythm_AllocResetMarker:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xfa
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr SeqPart_NoteProcessing_Loop

Rhythm_AllocStoreAndCont:
	ldfr_berp L, 0xfa

SeqPart_NoteProcessing_Loop:
	cp iz, (xsp + 22)
	jr c, Rhythm_AllocProcessLoop

Rhythm_AllocCheckDone:
	cpib_erp 0xfb, 1
	jr nz, Rhythm_AllocStoreResult

Rhythm_AllocFinalizeLoop:
	lda xwa, (xsp + 6)
	calr SeqEvent_ProcessRhythm4Ch
	cp l, 0x82
	jr z, Rhythm_AllocClearFlag
	cp l, 0x81
	jr z, Rhythm_AllocClearFlag
	cp l, 0x84
	jr z, Rhythm_AllocResetAlt
	cp l, 0xb1
	jr z, Rhythm_AllocCheckFlag
	cp l, 0xb0
	jr nz, Rhythm_AllocStoreAlt

Rhythm_AllocCheckFlag:
	cpib_erp 0xfb, 1
	jr z, Rhythm_AllocFinalizeLoop

Rhythm_AllocStoreResult:
	ld xwa, (xsp + 14)
	ldto_berp C, 0xfa
	ld (xwa), c

Rhythm_AllocReturn:
	pop xiz
	lda xsp, (xsp + 20)
	ret

Rhythm_AllocResetAlt:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xfa
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr Rhythm_AllocCheckFlag

Rhythm_AllocStoreAlt:
	ldfr_berp L, 0xfa

Rhythm_AllocClearFlag:
	ldib_erp 0xfb, 0
	jr Rhythm_AllocStoreResult

Rhythm_ExtendedNoteAlloc:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld (xsp + 24), wa
	ld xiy, Rhythm_ExtendedNoteAlloc_LocalInit
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, Rhythm_ExtendedNoteAlloc_LocalInit_2
	lda xix, (xsp + 8)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldfr_berp L, 0xfa
	cpib_erp 0xfa, 0
	jr nz, Rhythm_ExtAllocMultiVoice
	calr SeqPart_DispatchRhythmNote
	ld xde, (xsp + 30)
	ld (xde), l
	ld c, (xde)
	extz bc
	ld wa, (xsp + 24)
	extz xwa
	div xwa, bc
	ld bc, wa
	inc 1, bc
	ld xwa, (xsp + 20)
	ld (xwa), bc
	ld bc, (xsp + 24)
	mrib2 0x82, 0x53
	ld c, b
	jrl Rhythm_ExtAllocReturn

Rhythm_ExtAllocMultiVoice:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xfb
	ldw (xsp + 4), 0x1
	ldw (xsp + 6), 0x0
	ldib_erp 0xf9, 0
	ld xwa, (xsp + 20)
	ldw (xwa), 0x1
	ldto_berp C, 0xfa
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	lda xwa, (xsp + 8)
	ld (xwa), hl
	ldw (xwa + 2), 0x5
	lda xiy, (xsp + 8)
	lda xix, (xsp + 12)
	ldiw
	ldiw
	cpw (xsp + 24), 0x0
	jrl ule, Rhythm_ExtAllocStoreResult

Rhythm_ExtAllocProcessLoop:
	lda xwa, (xsp + 8)
	calr SeqEvent_ProcessRhythm4Ch
	ld a, l
	cp l, 0xb1
	jr z, Rhythm_NoteAllocation_Finalize
	cp a, 0xb0
	jr z, Rhythm_NoteAllocation_Finalize
	cp a, 0x84
	jr z, Rhythm_ExtAllocResetMarker
	cp a, 0x82
	jr z, Rhythm_ExtAllocEndSection
	cp a, 0x81
	jr nz, Rhythm_ExtAllocStoreAndCont
	incw 1, (xsp + 6)
	inc1b_erp 0xf9
	ldto_berp A, 0xf9
	cpb_erp A, 0xfb
	jr c, Rhythm_NoteAllocation_Finalize
	incw 1, (xsp + 4)
	ldib_erp 0xf9, 0
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocEndSection:
	ldto_berp A, 0xfb
	subb_erp A, 0xf9
	extz wa
	add (xsp + 6), wa
	incw 1, (xsp + 4)
	ldto_berp C, 0xfb
	extz bc
	ld de, (xsp + 24)
	sub de, (xsp + 6)
	ld wa, de
	extz xwa
	div xwa, bc
	add (xsp + 4), wa
	extz xde
	div xde, bc
	ldto_werp WA, 0xea
	ldfr_berp A, 0xf9
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocResetMarker:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xfb
	lda xiy, (xsp + 12)
	lda xix, (xsp + 8)
	ldiw
	ldiw
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocStoreAndCont:
	ldfr_berp L, 0xfb

Rhythm_NoteAllocation_Finalize:
	ld wa, (xsp + 6)
	cp wa, (xsp + 24)
	jrl c, Rhythm_ExtAllocProcessLoop

Rhythm_ExtAllocStoreResult:
	ld xwa, (xsp + 20)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ld xwa, (xsp + 30)
	ldto_berp C, 0xfb
	ld (xwa), c
	ldto_berp C, 0xf9

Rhythm_ExtAllocReturn:
	ld xwa, (xsp + 16)
	ld (xwa), c
	pop xiz
	lda xsp, (xsp + 22)
	retd 0x4

SeqPart_FindActiveVoiceSlot:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1

SeqFind_VoiceSlotLoop:
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	calr Part_ReadSubBlock32
	cp l, 0x10
	jr nz, SeqFind_NextSlot
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqFind_ShiftBitMask
	slaa bc

SeqFind_ShiftBitMask:
	and bc, (0xf19e:16)
	jr z, SeqFind_SlotNotActive
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, SeqFind_CheckOverflow

SeqFind_SlotNotActive:
	ldi_erpb 0xfb, 0x11
	jr SeqFind_SetZeroResult

SeqFind_NextSlot:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqFind_VoiceSlotLoop

SeqFind_CheckOverflow:
	cp_erpb 0xfb, 0x11
	jr nz, SeqFind_ReturnResult

SeqFind_SetZeroResult:
	ldib_erp 0xfb, 0

SeqFind_ReturnResult:
	ldto_berp L, 0xfb
	popw_erp 0xfa
	ret

SeqPart_DispatchRhythmNote:
	push xiz
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf980
	ld iz, wa
	add iz, 0x2e0
	ld wa, 0:i3
	ld bc, iz
	calr Part_ReadByteDirect
	ldfr_berp L, 0xfb
	ld bc, iz
	inc 1, bc
	ld wa, 0:i3
	calr Part_ReadByteDirect
	ldto_berp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	call Rhythm_NoteDispatchWrapper
	pop xiz
	ret

SeqEvent_ProcessRhythm4Ch:
	lda xsp, (xsp - 12)
	pushw_erp 0xfa
	ld (xsp + 10), xwa
	ld xiy, SeqEvent_ProcessRhythm4Ch_LocalInit
	lda xix, (xsp + 2)
	ld bc, 4:i3
	ldirw
	ldib_erp 0xfb, 1

SeqEvt4Ch_ReadEventLoop:
	lda xbc, (xsp + 2)
	ld xwa, (xsp + 10)
	calr SeqPart_ReadNextEventByte
	lda xbc, (xsp + 2)
	ld a, (xbc)
	cp a, 0xc1
	jr z, SeqEvent_DispatchRhythmIfMatch
	cp a, 0xc0
	jr z, SeqEvent_DispatchRhythmIfMatch
	cp a, 0x84
	jr z, SeqEvent_ProcessRhythm3Ch
	cp a, 0x82
	jr z, SeqEvent_ProcessRhythm3Ch
	cp a, 0x81
	jr z, SeqEvent_ProcessRhythm3Ch

SeqEvt4Ch_CheckFlag:
	cpib_erp 0xfb, 1
	jr z, SeqEvt4Ch_ReadEventLoop

SeqEvt4Ch_Return:
	ld l, (xsp + 2)
	popw_erp 0xfa
	lda xsp, (xsp + 12)
	ret

SeqEvent_DispatchRhythmIfMatch:
	cp (xbc + 2), 0x48
	jr nz, SeqEvt4Ch_CheckFlag
	cp (xbc + 3), 0x0
	jr nz, SeqEvt4Ch_CheckFlag
	and a, 0x1
	sll a, 7
	add a, (xbc + 4)
	ld c, (xbc + 5)
	extz wa
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (xsp + 2), l

SeqEvent_ProcessRhythm3Ch:
	ldib_erp 0xfb, 0
	jr SeqEvt4Ch_Return
SeqEvt_ProcessBlock_Helper:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 8), xwa
	ld xiy, SeqEvent_ProcessRhythm3Ch_LocalInit
	lda xix, (xsp + 2)
	ld bc, 3:i3
	ldirw
	ldib_erp 0xfb, 1

SeqEvt3Ch_ReadEventLoop:
	lda xbc, (xsp + 2)
	ld xwa, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	lda xiy, (xsp + 2)
	ld a, (xiy)
	lda xbc, (xiy + 2)
	lda xde, (xiy + 3)
	lda xhl, (xiy + 4)
	lda xix, (xiy + 5)
	cp a, 0xc1
	jrl z, SeqEvt3Ch_DispatchNote
	cp a, 0xc0
	jrl z, SeqEvt3Ch_DispatchNote
	cp a, 0x84
	jrl z, Rhythm_ClearAndReturn
	cp a, 0x82
	jrl z, Rhythm_ClearAndReturn
	cp a, 0x81
	jrl z, Rhythm_ClearAndReturn
	cp a, 0xb7
	jrl ugt, AppEvent_CheckAndBranch
	cp a, 0xb0
	jrl c, AppEvent_CheckAndBranch
	cp (xbc), 0x48
	jrl nz, AppEvent_CheckAndBranch
	cp (xde), 0x5
	jr nz, SeqEvt3Ch_CheckCC6
	ld a, (xix)
	and a, (xhl)
	bit 2, a
	jr z, SeqEvt3Ch_CheckCC6
	ld (xiy), 0xb0
	ldw (4360:16), 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	ld (8972:16), l
	ldw (4360:16), 0
	ldib_erp 0xfb, 0

SeqEvt3Ch_CheckCC6:
	lda xbc, (xsp + 2)
	cp (xbc + 3), 0x6
	jr nz, SeqEvt3Ch_CheckCC5
	ld a, (xbc + 5)
	and a, (xbc + 4)
	bit 2, a
	jr z, SeqEvt3Ch_CheckCC5
	ld (xbc), 0xb0
	ldw (4360:16), 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	ld (8972:16), l
	ldw (4360:16), 0
	ldib_erp 0xfb, 0

SeqEvt3Ch_CheckCC5:
	lda xbc, (xsp + 2)
	cp (xbc + 3), 0x5
	jr nz, AppEvent_CheckAndBranch
	ld a, (xbc + 5)
	and a, (xbc + 4)
	bit 3, a
	jr z, AppEvent_CheckAndBranch
	ld (xbc), 0xb1
	ldw (4360:16), 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	ld (8972:16), l
	ldw (4360:16), 0
	jr Rhythm_ClearAndReturn

SeqEvt3Ch_DispatchNote:
	cp (xbc), 0x48
	jr nz, AppEvent_CheckAndBranch
	cp (xde), 0x0
	jr nz, AppEvent_CheckAndBranch
	and a, 0x1
	sll a, 7
	add a, (xhl)
	ld c, (xix)
	extz wa
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (xsp + 2), l

Rhythm_ClearAndReturn:
	ldib_erp 0xfb, 0
	jr SeqEvt3Ch_ReturnResult

AppEvent_CheckAndBranch:
	cpib_erp 0xfb, 1
	jrl z, SeqEvt3Ch_ReadEventLoop

SeqEvt3Ch_ReturnResult:
	ld l, (xsp + 2)
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

SeqEvt_ProcessBlock:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	ldw	(xsp), 0
	ld	(xsp+2), 1
	ld	xiy, SeqEvt_ProcessBlock_LocalInit
	lda	xix, (xsp+4)
	ldiw
	ldiw
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadSubBlock32
	cp	l, 16
	jr	z, SeqEvt_ProcessBlock_Skip
	cp	l, 13
	jr	z, SeqEvt_ProcessBlock_Skip
	ld	hl, 0:i3
	jr	SeqEvt_ProcessBlock_Epilogue
SeqEvt_ProcessBlock_Skip:
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadVoiceWord
	lda	xwa, (xsp+4)
	ld	(xwa), hl
	ldw (xwa+2), 5
SeqEvt_ProcessBlock_Loop:
	lda	xwa, (xsp+4)
	calr	SeqEvent_ProcessRhythm4Ch
	cp	l, 132
	jr	z, SeqEvt_ProcessBlock_Skip5
	cp	l, 130
	jr	z, SeqEvt_ProcessBlock_Skip4
	cp	l, 129
	jr	nz, SeqEvt_ProcessBlock_Skip3
	incw	1, (xsp)
SeqEvt_ProcessBlock_Skip3:
	cp	(xsp+2), 1
	jr	z, SeqEvt_ProcessBlock_Loop
SeqEvt_ProcessBlock_Join:
	ld	hl, (xsp)
SeqEvt_ProcessBlock_Epilogue:
	lda	xsp, (xsp+10)
	ret
SeqEvt_ProcessBlock_Skip4:
	ldw (xsp), 0
SeqEvt_ProcessBlock_Skip5:
	ld	(xsp+2), 0
	jr	SeqEvt_ProcessBlock_Join
Rhythm_ComputeNoteAllocation_Helper:
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	ldw (xsp), 0
	ld	(xsp+2), 1
	ld	xiy, SeqEvt_ProcessBlock_LocalInit_2
	lda	xix, (xsp+4)
	ldiw
	ldiw
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadSubBlock32
	cp	l, 13
	jr	z, SeqEvt_ProcessBlock_Skip2
	ld	hl, 0:i3
	jr	SeqEvt_ProcessBlock_Epilogue2
SeqEvt_ProcessBlock_Skip2:
	ld	c, (xsp+8)
	extz	bc
	ld	wa, 0:i3
	calr	Part_ReadVoiceWord
	lda	xwa, (xsp+4)
	ld	(xwa), hl
	ldw (xwa+2), 5
Rhythm_ComputeNoteAllocation_Helper_Loop:
	lda	xwa, (xsp+4)
	calr	SeqEvt_ProcessBlock_Helper
	cp	l, 177
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Skip
	cp	l, 176
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Skip
	cp	l, 132
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Skip2
	cp	l, 130
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Skip2
	cp	l, 129
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Skip2
	cp	(xsp+2), 1
	jr	z, Rhythm_ComputeNoteAllocation_Helper_Loop
Rhythm_ComputeNoteAllocation_Helper_Join:
	ld	hl, (xsp)
SeqEvt_ProcessBlock_Epilogue2:
	lda	xsp, (xsp+10)
	ret
Rhythm_ComputeNoteAllocation_Helper_Skip:
	ld	a, (8972:16)
	extz	wa
	ld	(xsp), wa
Rhythm_ComputeNoteAllocation_Helper_Skip2:
	ld	(xsp+2), 0
	jr	Rhythm_ComputeNoteAllocation_Helper_Join

SeqInit_ReturnStub:
	ret

SeqInit_SetBaseAddress:
	ldw (0x286d:16), 1240
	lda xwa, (0x0b0000:24)
	ld (7514:16), xwa
	ret

SeqInit_JumpToPartInit:
	jrl Part_InitFromPreset

SeqInit_FullReset:
	pushw_erp 0xfa
	ldw (9832:16), 1
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	calr SeqVoice_SetDefaultParams
	calr SeqInit_ClearPlaybackFlags
	calr SeqParams_InitDefaults
	call BmDrEdit_InitDisplayParams
	call Audio_CheckSubsystemReady
	ldib_erp 0xfb, 0

SeqInit_ClearCBLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	calr Part_WriteByte
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqInit_ClearCBLoop
	pushw 0x1
	ldw wa, 0x91
	ld bc, 3:i3
	ld de, 0:i3
	call AddswbWr
	ldib_erp 0xfb, 0

SeqInit_WriteDefaultsLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1c
	calr Part_ReadWord
	cp hl, 0:i3
	jr z, SeqInit_InitVoiceSubBlocks
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x32
	calr Part_ReleaseVoicesForRange

SeqInit_InitVoiceSubBlocks:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqInit_WriteDefaultsLoop
	ldw (9500:16), 1
	ldw (9502:16), 1
	ldw (9504:16), 1
	ldw (9506:16), 1
	ld (0x28b1:16), 0
	ld wa, 0:i3
	call VoiceParam_SetD6Group
	popw_erp 0xfa
	ret

Part_InitFromPreset:
	lda xsp, (xsp - 16)
	push xiz
	ld xiy, Part_InitFromPreset_LocalInit
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ldib_erp 0xfb, 0

SeqInit_SetMIDIDefaults:
	ldto_berp A, 0xfb
	extz wa
	call DataBuf_InitSlotFromPreset
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqInit_SetMIDIDefaults
	ldib_erp 0xfb, 0

SeqInit_FinalizeSetup:
	ldto_berp A, 0xfb
	extz wa
	calr Part_InitVoiceDefaults
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1c
	ld de, 0:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x1e
	ld de, 0:i3
	calr Part_WriteWord
	calr SeqStatus_CheckBit2
	ldto_berp A, 0xfb
	extz wa
	cp l, 0:i3
	jr nz, SeqInit_WriteMoreDefaults
	calr Part_WriteAllVoiceSubBlocks_A
	jr SeqInit_Return

SeqInit_WriteMoreDefaults:
	calr Part_WriteAllVoiceSubBlocks_B

SeqInit_Return:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x50
	ldw de, 0xffff
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x52
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x53
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x54
	ld de, 2:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x55
	ld de, 3:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x56
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x57
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x59
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x5b
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x5c
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x5e
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x60
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x61
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x62
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x64
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x66
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x67
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x69
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x6a
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x6c
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x6e
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x6f
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x71
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x72
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x74
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x76
	ld de, 3:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x77
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xa8
	ld de, 1:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xa9
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xab
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xad
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xae
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb3
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb4
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb5
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb6
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xb8
	ld de, 1:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xba
	ld de, 2:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xbc
	ld de, 0:i3
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xbf
	ld de, 0:i3
	calr Part_WriteWord
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xbe
	calr Part_ReadByteDirect
	set 0, l
	ldto_berp A, 0xfb
	extz wa
	extz hl
	ldw bc, 0xbe
	ld de, hl
	calr Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	calr Part_WriteByte
	ld iz, 0:i3

SeqInit_ClearPartDataLoop:
	ldto_berp A, 0xfb
	extz wa
	ld bc, iz
	add bc, 0x113
	ld de, 0:i3
	calr Part_WriteByte
	inc 1, iz
	cp iz, 0x1cd
	jr c, SeqInit_ClearPartDataLoop
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (xsp + 4)
	calr Part_CopyBlock16
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x110
	ldw de, 0xffff
	calr Part_WriteWord
	call VoiceChannels_InitPanFromPreset
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x112
	ld de, 1:i3
	calr Part_WriteByte
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jrl ule, SeqInit_FinalizeSetup
	call Audio_CheckSubsystemReady
	res 0, (0x28a5:16)
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	ldw wa, 0xb
	ldw bc, 0x32
	calr Part_ReleaseVoicesForRange
	calr Part_UnlinkVoiceFromChain
	ld (0x28b2:16), 0
	ldw (9832:16), 1
	ld (0x00ffe3:24), 0x00
	ldw (9500:16), 1
	ldw (9502:16), 1
	ldw (9504:16), 1
	ldw (9506:16), 1
	ld (0x28b1:16), 0
	ld (8956:16), 0
	res 0, (8970:16)
	ld (0x28be:16), 255
	ld (8976:16), 0
	res 0, (0x8d88:16)
	ld (7518:16), 0
	calr SeqParams_InitDefaults
	call BmDrEdit_InitDisplayParams
	pop xiz
	lda xsp, (xsp + 16)
	ret

SeqInit_ClearPlaybackFlags:
	ld a, (0x28a7:16)
	res 3, a
	res 1, a
	res 0, a
	ld (0x28a7:16), a
	jp SeqAcc_InitPlaybackState

SeqPlay_HandleChannelToggle:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_ToggleShiftDone
	slaa bc

SeqPlay_ToggleShiftDone:
	and bc, (0xf19e:16)
	ld a, (xsp)
	extz wa
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqPlay_ToggleNoSeqMode
	cp bc, 0:i3
	jr z, SeqPlay_ToggleInactive
	calr SeqPlay_DeactivateChannelFull
	jr SeqPlay_PostInitReturn

SeqPlay_ToggleInactive:
	calr Part_IsVoiceActive
	cp hl, 0:i3
	jr z, SeqPlay_PostInitReturn
	ld a, (xsp)
	extz wa
	calr SeqPlay_HandleChannelSolo
	jr SeqPlay_PostInitReturn

SeqPlay_ToggleNoSeqMode:
	cp bc, 0:i3
	jr z, SeqPlay_ToggleInactiveNoSeq
	calr Part_DeactivateChannel
	jr SeqPlay_ToggleInitStart

SeqPlay_ToggleInactiveNoSeq:
	calr Part_IsVoiceActive
	cp hl, 0:i3
	jr z, SeqPlay_PostInitReturn
	ld a, (xsp)
	extz wa
	calr SeqVoice_ActivateWithBarSync

SeqPlay_ToggleInitStart:
	calr SeqPlay_InitStartState

SeqPlay_PostInitReturn:
	calr Accomp_ValidateAutoPlayChordVoice
	ldmm16 0x2838, 0xf19e
	inc 2, xsp
	ret

SeqPlay_HandleChannelState:
	dec 2, xsp
	ld (xsp), a
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jrl nz, SeqPlay_StateReturn
	ld (9508:16), 1
	ld a, (xsp)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqPlay_StateShiftDone
	slaa bc

SeqPlay_StateShiftDone:
	ld de, bc
	and de, (0x28a8:16)
	ld a, (xsp)
	extz wa
	cp de, 0:i3
	jr nz, SeqPlay_StateReinitVoice
	and bc, (0xf19e:16)
	jr nz, SeqPlay_StateDeactivate
	calr SeqPlay_FindAndActivateVoice
	jr SeqPlay_ClearFlags_Exit

SeqPlay_StateDeactivate:
	calr Part_DeactivateChannel
	ld a, (xsp)
	extz wa
	calr SeqVoice_DeactivateAndReinit
	jr SeqPlay_ClearFlags_Exit

SeqPlay_StateReinitVoice:
	calr SeqVoice_DeactivateAndReinit
	ld a, (xsp)
	extz wa
	calr Part_IsVoiceActive
	ld a, (xsp)
	extz wa
	cp hl, 0:i3
	jr z, SeqPlay_StateDeactivateChannel
	calr SeqVoice_ActivateWithBarSync
	jr SeqPlay_ClearFlags_Exit

SeqPlay_StateDeactivateChannel:
	calr Part_DeactivateChannel

SeqPlay_ClearFlags_Exit:
	res 3, (0x28a7:16)
	ld a, (CURRENT_TITLE:16)
	cp a, 0x87
	jr z, SeqPlay_ResetModeAndDisplay
	cp a, 0x88
	jr z, SeqPlay_ResetModeAndDisplay
	bit 1, (0x28b1:16)
	jr nz, SeqPlay_StateSetBarPosition
	ldw (9832:16), 1
	jr SeqPlay_ResetModeAndDisplay

SeqPlay_StateSetBarPosition:
	ldmm16 9832, 9504
	cpw (9832:16), 1
	jr z, SeqPlay_ResetModeAndDisplay
	set 3, (0x28a7:16)

SeqPlay_ResetModeAndDisplay:
	call NoteEditSy_SendModeScrollReset
	calr SeqPlay_InitStartState
	calr Accomp_ValidateAutoPlayChordVoice
	ldmm16 0x2838, 0xf19e

SeqPlay_StateReturn:
	inc 2, xsp
	ret

SeqPlay_HandleChannelSolo:
	dec 2, xsp
	ld (xsp), a
	cpw (0xf19e:16), 0
	jr nz, SeqPlay_SoloCheckAutoChord
	bit 0, (0x28b1:16)
	jr z, SeqPlay_SoloSetBar1
	ld wa, (9500:16)
	cp (9832:16), wa
	jr ugt, SeqPlay_SoloSetBarFromSave

SeqPlay_SoloSetBar1:
	ldw (9832:16), 1
	jr SeqPlay_SoloResetMode

SeqPlay_SoloSetBarFromSave:
	ld (9832:16), wa

SeqPlay_SoloResetMode:
	call NoteEditSy_SendModeScrollReset
	cpw (9832:16), 1
	jr nz, SeqPlay_SoloSetBit3
	res 3, (0x28a7:16)
	jr SeqPlay_SoloInitState

SeqPlay_SoloSetBit3:
	set 3, (0x28a7:16)

SeqPlay_SoloInitState:
	calr SeqPlay_InitStartState

SeqPlay_SoloCheckAutoChord:
	ld a, (xsp)
	cp a, (8996:16)
	jr nz, Chan_ActivateAndNotify
	bit 6, (DEMO_CONTROL_FLAGS:16)
	jr z, Chan_ActivateAndNotify
	ld a, (9828:16)
	ld (0x28ae:16), a
	set 7, (0x28ae:16)

Chan_ActivateAndNotify:
	ld a, (xsp)
	extz wa
	ld bc, 1:i3
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

SeqPlay_DeactivateChannelFull:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	cp a, (8996:16)
	jr nz, SeqPlay_DeactClearBit
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure

SeqPlay_DeactClearBit:
	ld a, (xsp)
	extz wa
	ld bc, 0:i3
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	cpw (0xf19e:16), 0
	jr nz, Chan_DeactivateAfterAccomp
	bit 2, (1054:16)
	jr z, SeqPlay_DeactDispatchAccomp
	call AccWrap_PlayModeStopExpr
	jr Chan_DeactivateAfterAccomp

SeqPlay_DeactDispatchAccomp:
	call AccWrap_PlayModeDispatch

Chan_DeactivateAfterAccomp:
	ld a, (xsp)
	extz wa
	calr Part_DeactivateVoiceChannel
	inc 2, xsp
	ret

SeqVoice_ActivateWithBarSync:
	dec 2, xsp
	ld (xsp), a
	cpw (0xf19e:16), 0
	jr nz, SeqActivate_AssignAndEnable
	bit 0, (0x28b1:16)
	jr z, SeqActivate_SetBar1
	ld wa, (9500:16)
	cp (9832:16), wa
	jr ugt, SeqActivate_SetBarFromSave

SeqActivate_SetBar1:
	ldw (9832:16), 1
	jr SeqActivate_ResetMode

SeqActivate_SetBarFromSave:
	ld (9832:16), wa

SeqActivate_ResetMode:
	call NoteEditSy_SendModeScrollReset
	cpw (9832:16), 1
	jr nz, SeqActivate_SetBit3
	res 3, (0x28a7:16)
	jr SeqActivate_DispatchAccomp

SeqActivate_SetBit3:
	set 3, (0x28a7:16)

SeqActivate_DispatchAccomp:
	call AccWrap_PlayModeDispatch

SeqActivate_AssignAndEnable:
	ld a, (xsp)
	extz wa
	calr SeqVoice_UpdateSubBlockAssign
	ld a, (xsp)
	extz wa
	ld bc, 1:i3
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

Part_DeactivateChannel:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	ld bc, 0:i3
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	ld a, (xsp)
	extz wa
	calr Part_DeactivateVoiceChannel
	inc 2, xsp
	ret

SeqPlay_FindAndActivateVoice:
	dec 2, xsp
	ld (xsp), a
	ld wa, 0:i3
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, SeqPlay_FindCheckAlternate
	ld a, (xsp)
	extz wa
	calr Part_IsVoiceActive
	cp hl, 0:i3
	jr z, SeqPlay_FindJumpToEnd
	ld a, (xsp)
	extz wa
	ld bc, 1:i3
	calr Chan_SetActiveBit

SeqPlay_FindJumpToEnd:
	jrl SeqPlay_FindReturn

SeqPlay_FindCheckAlternate:
	ld wa, 0:i3
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, SeqPlay_FindCheckBitMask
	bit 1, (0x28b1:16)
	jr z, SeqPlay_FindCheckBitMask
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr nz, SeqPlay_FindReturn

SeqPlay_FindCheckBitMask:
	cpw (0x28a8:16), 0
	jr nz, SeqPlay_FindClearFlags
	res 2, (0x28a7:16)

SeqPlay_FindClearFlags:
	ld a, (xsp)
	extz wa
	calr SeqPlay_ReassignVoiceSlot
	bit 1, (0x28b1:16)
	jr z, SeqPlay_FindSetBitAndDeact
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady

SeqPlay_FindSetBitAndDeact:
	ld a, (xsp)
	extz wa
	ld bc, 1:i3
	calr SeqVoice_SetOrClearBitMask
	ld a, (xsp)
	extz wa
	ld bc, 0:i3
	calr Chan_SetActiveBit
	cp (CURRENT_MODE:16), 11
	jr z, SeqPlay_FindAfterReset
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw (9008:16), 0
	ldw (9832:16), 1
	ldmm8 9010, 1075
	res 3, (0x28a7:16)
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	call SeqBuf_Init

SeqPlay_FindAfterReset:
	call Audio_CheckSubsystemReady
	ld a, (1056:16)
	and a, 0x5
	call z, (AccWrap_PlayModeDispatch:24)
	calr Part_DetectSingleVoiceType

SeqPlay_FindReturn:
	inc 2, xsp
	ret

SeqVoice_DeactivateAndReinit:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	ld bc, 0:i3
	calr SeqVoice_SetOrClearBitMask
	call Audio_CheckSubsystemReady
	ld a, (xsp)
	extz wa
	calr SeqVoice_UpdateSubBlockAssign
	cp (CURRENT_MODE:16), 11
	jr z, SeqDeact_DetectTypeReturn
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw (9008:16), 0
	ldw (9832:16), 1
	ldmm8 9010, 1075
	res 3, (0x28a7:16)
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	call SeqBuf_Init

SeqDeact_DetectTypeReturn:
	calr Part_DetectSingleVoiceType
	inc 2, xsp
	ret

SeqVoice_UpdateSubBlockAssign:
	dec 2, xsp
	ld (xsp), a
	cp (CURRENT_MODE:16), 11
	jr z, SeqUpdate_FindVoiceAndWrite
	cp (CURRENT_TITLE:16), 135
	jr nz, Part_WriteSubBlock_Exit

SeqUpdate_FindVoiceAndWrite:
	ld wa, 0:i3
	ldw bc, 0xe
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, Part_WriteSubBlock_Exit
	ld l, (0x28be:16)
	cp l, 0xff
	jr z, Part_WriteSubBlock_Exit
	inc 1, l
	extz hl
	ld wa, 0:i3
	ld bc, hl
	ldw de, 0xd
	calr Part_WriteSubBlock32

Part_WriteSubBlock_Exit:
	inc 2, xsp
	ret

SeqPlay_ReassignVoiceSlot:
	dec 2, xsp
	ld (xsp), a
	ld wa, 0:i3
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, SeqPlay_ReassignReturn
	extz hl
	ld wa, 0:i3
	ld bc, hl
	ldw de, 0xe
	calr Part_WriteSubBlock32
	res 0, (8970:16)
	ld a, (xsp)
	dec 1, a
	ld (0x28be:16), a

SeqPlay_ReassignReturn:
	inc 2, xsp
	ret

SeqVoice_SendNoteOffAndFlush:
	pushw_erp 0xfa
	ld a, (8988:16)
	ldfr_berp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl z, SeqVoice_PopRetFA
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone1
	slaa bc

SeqNoteOff_ShiftDone1:
	and bc, (0xf19e:16)
	jrl z, SeqVoice_PopRetFA
	calr BitMapOut_PrepareAndDisplay
	ldto_berp A, 0xfb
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone2
	slaa bc

SeqNoteOff_ShiftDone2:
	ld de, (SEQ_ACTIVE_PARTS:16)
	and bc, de
	jr z, SeqVoice_PopRetFA
	ldto_berp C, 0xfb
	extz bc
	ld a, c
	dec 1, a
	ld hl, 1:i3
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone3
	slaa hl

SeqNoteOff_ShiftDone3:
	cpl hl
	and de, hl
	ld (SEQ_ACTIVE_PARTS:16), de
	ld wa, bc
	calr SeqBuf_WriteNoteOffEntry
	lda xwa, (0xe374:16)
	ldto_berp C, 0xfb
	dec 1, c
	ld (xwa + 3), c
	ld bc, 4:i3
	calr SeqBuf_WriteMidiEvent
	lda xwa, (0xe378:16)
	ldto_berp C, 0xfb
	dec 1, c
	ld (xwa + 4), c
	ld bc, 5:i3
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents
	pushw 0x30
	ldw wa, 0x48
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	cpw (0x28a8:16), 0
	jr nz, SeqVoice_PopRetFA
	cp (7570:16), 0
	jr nz, SeqVoice_PopRetFA
	ld wa, (0xf19e:16)
	ld bc, (SEQ_ACTIVE_PARTS:16)
	and wa, bc
	call z, (SeqPlay_StopAndResetAll:24)

SeqVoice_PopRetFA:
	popw_erp 0xfa
	ret

SeqPlay_SaveStateAndCleanup:
	ld wa, (0xf19e:16)
	ld (0x00ffec:24), wa
	bit 0, (0x28a5:16)
	jr nz, SeqSave_JumpCheckSubsys
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady

SeqSave_JumpCheckSubsys:
	jp Audio_CheckSubsystemReady

SeqPlay_CheckAndStartPlayback:
	cp (9508:16), 0
	jp nz, (TempoRingBuf_Init:24)
	bit 0, (0x28c5:16)
	jp nz, (SeqPlay_CheckAndReactivate:24)
	ld a, (SEQ_TRANSPORT_STATE:16)
	and a, 0x5
	ret nz
	call TempoRingBuf_CheckEmpty
	cp hl, 0:i3
	ret z
	cpw (0xf19e:16), 0
	ret nz
	cpw (0x28a8:16), 0
	ret z
	cpw (0x28aa:16), 0
	ret nz
	bit 1, (0x28b2:16)
	ret nz
	call SeqPlay_ReassignVoiceChannels
	cp l, 0:i3
	jrl nz, SeqPlay_StopAndClearChannels
	cpw (0x28aa:16), 0
	ret z
	set 1, (0x28b3:16)
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ei 0
	call AccWrap_PlayModeStart
	bit 2, (0xfd50:16)
	ret z
	calr SeqTimer_SetPlaybackFlags
	ret

SeqAcc_SetIndicator_PB:
	ld wa, (0xf19e:16)
	ld (0x2875:16), wa
	call Demo_PreSetup
	res 0, (0x28a5:16)
	ldw wa, 0x4c
	jp CtrlPanel_SetIndicatorBit

SeqAcc_RestorePlaybackState:
	pushw iz
	ld iz, (0x2875:16)
	ld (0xf19e:16), iz
	call Audio_CheckSubsystemReady
	cp iz, 0:i3
	jr z, SeqRestore_ClearIndicator
	res 3, (0x28a7:16)
	call SeqAcc_InitPlaybackState
	call Audio_CheckSubsystemReady
	set 0, (0x28a5:16)
	jr SeqRestore_SetIndicator

SeqRestore_ClearIndicator:
	res 0, (0x28a5:16)

SeqRestore_SetIndicator:
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	popw iz
	ret

SeqPlay_JumpCopyVoiceData:
	jrl Part_CopyVoiceDataToAllChannels

SeqPlay_SetBarAndResetScroll:
	ldw (9832:16), 0x8002
	jp NoteEditSy_SendModeScrollReset

SeqPlay_HandleVoiceReassign:
	bit 2, (0x28b3:16)
	jr z, SeqPlay_CheckNoteDisplayPending
	ld a, (0xfc5f:16)
	and a, 0x30
	jr nz, SeqPlay_CheckNoteDisplayPending
	call SeqRestart_CheckAndDispatch
	ld a, (0x28b3:16)
	res 2, a
	set 4, a
	ld (0x28b3:16), a

SeqPlay_CheckNoteDisplayPending:
	cp (7568:16), 0
	jr z, SeqPlay_InitBuffers
	bit 2, (1054:16)
	jr nz, SeqPlay_InitBuffers
	ld a, (SEQ_TRANSPORT_STATE:16)
	and a, 0x14
	jr nz, SeqPlay_InitBuffers
	ld (4596:16), 0
	ld wa, 0:i3
	call BitMapOut_PrepareAndRender
	ld (7568:16), 0

SeqPlay_InitBuffers:
	bit 4, (0x28b3:16)
	jr z, SeqPlay_CheckMidiPending
	bit 2, (1054:16)
	jr nz, SeqPlay_CheckMidiPending
	ld a, (SEQ_TRANSPORT_STATE:16)
	and a, 0x14
	jr nz, SeqPlay_CheckMidiPending
	cp (7518:16), 0
	jr nz, SeqPlay_CheckMidiPending
	bit 1, (0x3283:16)
	jr nz, SeqPlay_CheckMidiPending
	calr SeqPlay_AllocBuffersAndInit
	res 4, (0x28b3:16)

SeqPlay_CheckMidiPending:
	cp (7584:16), 0
	ret z
	ld a, (SEQ_TRANSPORT_STATE:16)
	and a, 0x1c
	ret nz
	call SeqPlay_CheckStartConditions
	ld (7584:16), 0
	ret

SeqPlay_SetupRhythmMode:
	calr Rhythm_SetupAndDispatch
	cp l, 0:i3
	ret nz
	cpw (SEQ_BEAT_COUNT:16), 0
	jr nz, SeqPlay_RhythmHasBar
	cp (SEQ_BEAT_TICK:16), 0
	jr z, SeqPlay_RhythmNoBar

SeqPlay_RhythmHasBar:
	set 3, (0x28a7:16)
	jr SeqAcc_ReInitWithGuard

SeqPlay_RhythmNoBar:
	res 3, (0x28a7:16)

SeqAcc_ReInitWithGuard:
	ld (0xe388:16), 1
	call SeqAcc_InitPlaybackState
	ld (0xe388:16), 0
	ret

SeqPlay_DispatchAndResetAll:
	call AccWrap_PlayModeDispatch
	calr Part_CopyVoiceDataToAllChannels
	call SeqPlay_ActivateAllChannels
	ld (4596:16), 0
	ld wa, 0:i3
	call BitMapOut_PrepareAndRender
	res 3, (0x28a7:16)
	call TempoRingBuf_Init
	set 4, (0x28b3:16)
	ldw wa, 0xf
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd

SeqPlay_StopAndClearChannels:
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	ldw (0x28aa:16), 0
	call TempoRingBuf_Init
	ldw wa, 0xf
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd

SeqPlay_StopAndClearSequence:
	call AccWrap_PlayModeDispatch
	ldw (SEQ_ACTIVE_PARTS:16), 0
	ldw wa, 0x32
	calr SeqBuf_WriteNoteOffEntry
	calr VoiceAlloc_ProcessAll
	ld (1073:16), 0
	res 5, (0x28b3:16)
	ldw wa, 0xe
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd
SeqPlay_BufferUpdateBlock:
	ld	wa, (9008:16)
	ld	bc, (SEQ_BEAT_COUNT:16)
	cp	bc, wa
	ret	c
	ld	e, (9010:16)
	sub	bc, wa
	cp	e, c
	ret	ugt
	ld	wa, (9832:16)
	cp	(CURRENT_TITLE:16), 133
	jr	z, SeqPlay_StopAndClearSequence_Skip4
	cp	(ACTIVE_TITLE:16), 134
	jr	nz, SeqPlay_StopAndClearSequence_Skip5
SeqPlay_StopAndClearSequence_Skip4:
	cp wa, (9506:16)
	jr	c, SeqPlay_StopAndClearSequence_Skip6
	ld	wa, (9504:16)
	jr	SeqPlay_StopAndClearSequence_Join2
SeqPlay_StopAndClearSequence_Skip5:
	cp wa, (9502:16)
	jr	nc, SeqPlay_StopAndClearSequence_Skip7
SeqPlay_StopAndClearSequence_Skip6:
	inc	1, wa
	jr	SeqPlay_StopAndClearSequence_Join2
SeqPlay_StopAndClearSequence_Skip7:
	ld	wa, (9500:16)
SeqPlay_StopAndClearSequence_Join2:
	ld	(9832:16), wa
	call	NoteEditSy_SendModeScrollReset
	ldmm16	9008, SEQ_BEAT_COUNT
	ldb_d8	e, (1075)
	ld	(9010:16), e
	jp	SeqMode_SendStatusUpdate
; SeqStep_TimerDispatch_ProcTables target: count-in measure -2 -> -1 (RAM 0x2668, sign-magnitude)
SeqPlay_CountInToLastBar:
	bit	2, (10418:16)
	ret	z
	ld	wa, (9832:16)
	cp	wa, 0x8002
	ret	nz
	ld	a, (1076:16)
	cp	a, 1:i3
	ret	c
	ldw	(9832:16), 0x8001
	call	NoteEditSy_SendModeScrollReset
	ret
; SeqStep_TimerDispatch_ProcTables target: measure counter + 1 per bar of beats, at most 999
SeqPlay_AdvanceMeasure:
	ld	wa, (9008:16)
	ld	bc, (SEQ_BEAT_COUNT:16)
	cp	bc, wa
	ret	c
	ld	e, (9010:16)
	sub	bc, wa
	cp	e, c
	ret	ugt
	ld	wa, (9832:16)
	cp	wa, 999
	ret	nc
	inc	1, wa
	ld	(9832:16), wa
	call	NoteEditSy_SendModeScrollReset
	ldmm16	9008, SEQ_BEAT_COUNT
	ldb_d8	e, (1075)
	ld	(9010:16), e
	jp	SeqMode_SendStatusUpdate
; SeqStep_TimerDispatch_ProcTables target: the count-in ends -- sequencer state 8/12/16/20 -> + 1
SeqPlay_CountInEnd:
	bit	1, (10418:16)
	ret	z
	ld	wa, (9832:16)
	cp	wa, 0x8001
	ret	nz
	ld	a, (1075:16)
	ld	c, (1046:16)
	dec	1, a
	cp	a, c
	ret	nz
	ld	a, (1045:16)
	cp	a, 72
	ret	c
	res	3, (10419:16)
	call	Audio_CheckSubsystemReady
	call	Audio_CheckSubsystemReady
	ld	a, (8956:16)
	cp	a, 20
	jr	z, SeqPlay_StopAndClearSequence_Skip3
	cp	a, 16
	jr	z, SeqPlay_StopAndClearSequence_Skip2
	cp	a, 12
	jr	z, SeqPlay_StopAndClearSequence_Skip
	cp	a, 8
	jr	nz, SeqPlay_StopAndClearSequence_Join
	ld	a, 9:opc
	jr	SeqPlay_StopAndClearSequence_Join
SeqPlay_StopAndClearSequence_Skip:
	ld	a, 13:opc
	jr	SeqPlay_StopAndClearSequence_Join
SeqPlay_StopAndClearSequence_Skip2:
	ld	a, 17:opc
	jr	SeqPlay_StopAndClearSequence_Join
SeqPlay_StopAndClearSequence_Skip3:
	ld	a, 21:opc
SeqPlay_StopAndClearSequence_Join:
	ld	(8956:16), a
	ret

AccWrap_DispatchAndWaitSync:
	call AccWrap_PlayModeDispatch
	ldw bc, 0xffff
	ld a, (1056:16)
	bit 2, a
	ret z

AccWrap_WaitSync_Loop:
	sub bc, 0x1
	ret z
	bit 2, a
	jr nz, AccWrap_WaitSync_Loop
	ret

; ============================================================================
; SeqData_SetErrorCode - Set sequence error code (first-error-wins)
; ============================================================================
; Input:  A = error code to set
; Only stores if DRAM[7520] is currently zero (no existing error).
; Called with error values 0xb8, 0xcf, 0xd0, 0xd1 from sequence processing.
; ============================================================================
SeqData_SetErrorCode:
	cp (7520:16), 0
	ret nz
	ld (7520:16), a
	ret

SeqStatus_CheckBit2:
	ld l, (0xfdad:16)
	and l, 0x4
	ret

SeqStatus_CheckMaskedBit:
	ld l, (0xfd52:16)
	and l, a
	ret

Seq_ComputePercentClamped99:
	ldw bc, 0x4d8
	ld wa, (0xf231:16)
	cp wa, 0x258
	jr ule, Seq_ComputePercent_Compute

Seq_ComputePercent_NormalizeLoop:
	srl bc, 1
	srl wa, 1
	cp wa, 0x258
	jr ugt, Seq_ComputePercent_NormalizeLoop

Seq_ComputePercent_Compute:
	mul wa, 0x64
	extz xwa
	div xwa, bc
	ld l, a
	cp l, 0x64
	ret nz
	ld l, 0x63:opc
	ret

SeqStatus_SetOrClearBit:
	lda xde, (0xfdad:16)
	cp c, 0:i3
	jr z, SeqStatus_SetOrClear_ClearPath
	or (xde), a
	ret

SeqStatus_SetOrClear_ClearPath:
	cpl a
	and (xde), a
	ret

Part_IsVoiceActive:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqStatus_Exit
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	calr Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqStatus_Exit
	calr PartCtrl_TestBit7
	cp l, 0:i3
	jr z, SeqStatus_Exit
	ld hl, 1:i3
	jr Part_IsVoiceActive_Return

SeqStatus_Exit:
	ld hl, 0:i3

Part_IsVoiceActive_Return:
	inc 2, xsp
	ret

SeqStatus_ResetAndSendCmd:
	res 0, (0xfdad:16)
	pushw 0x1
	ldw wa, 0x91
	ld bc, 3:i3
	ld de, 0:i3
	call AddswbWr
	ret

SeqPlay_WriteErrorToVoiceTable:
	ld a, (SEQ_ERROR_CODE:16)
	extz wa
	lda xbc, (SeqPlay_WriteErrorToVoiceTable_Data:24)
	ld	(SEQ_ERROR_CODE:16), (xbc+wa)
	ret

SeqData_SendVoiceTableBlock:
	dec 6, xsp
	ld xiy, SeqData_SendVoiceTableBlock_LocalInit
	ld xix, xsp
	ld bc, 2:i3
	ldirw
	ldi85
	lda xde, (xsp)
	ld wa, 0:i3
	ld bc, 4:i3
	call sendCOMM
	inc 6, xsp
	ret

SeqData_ParseSequenceStream:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 18), a
	ld a, (xsp + 18)
	extz wa
	lda xde, (xsp + 4)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda	xbc, (xbc+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld wa, (xde)
	sll wa, 8
	sub wa, 0x100
	extz xwa
	add xwa, (0x283e:16)
	ld xhl, xwa

SeqTimer_CheckFlags:
	lda xde, (xsp + 4)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	ld (xsp + 8), a
	ld wa, (xbc)
	cp wa, 0xff
	jr nz, SeqTimer_CheckReturn
	ld wa, (xde)
	calr SeqData_ResolveNextBlock
	lda xwa, (xsp + 4)
	ld (xwa), hl
	sll hl, 8
	sub hl, 0x100
	extz xhl
	add xhl, (0x283e:16)
	ldw (xwa + 2), 0x5
	jr SeqTimer_ProcessTick

SeqTimer_CheckReturn:
	inc 1, wa
	ld (xbc), wa

SeqTimer_ProcessTick:
	ld e, (xsp + 8)
	lda xbc, (9016:16)
	ld a, (xsp + 18)
	dec 1, a
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xbc
	cp e, 0x81
	jr nz, SeqTimer_TickReturn
	incw 1, (xwa)
	jr SeqTimer_CheckFlags

SeqTimer_TickReturn:
	ld xbc, xwa
	ld (xwa + 2), e
	cp e, 0x82
	jr nz, SeqTimer_UpdateCounters
	ld (xbc + 3), 0x0
	jr SeqData_SaveParsedState

SeqTimer_UpdateCounters:
	ldiw_erp 0xfa, 1

; Sequencer data field dispatch
SeqData_DispatchByField:
	lda xde, (xsp + 4)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	ldfr_berp A, 0xf8
	bit_erpb 0xf8, 0x07
	jr nz, SeqData_SaveParsedState
	ldto_werp IY, 0xfa
	inc 2, iy
	ld a, (xsp + 18)
	dec 1, a
	extz wa
	ld ix, wa
	sla ix, 3
	lda xwa, (9016:16)
	lda	xwa, (xwa+ix)
	ld ix, iy
	extz xix
	add xix, xwa
	ldto_berp A, 0xf8
	ld (xix), a
	ld wa, (xbc)
	cp wa, 0xff
	jr nz, SeqTimer_IncrementBar
	ld wa, (xde)
	calr SeqData_ResolveNextBlock
	lda xwa, (xsp + 4)
	ld (xwa), hl
	sll hl, 8
	sub hl, 0x100
	extz xhl
	add xhl, (0x283e:16)
	ldw (xwa + 2), 0x5
	jr SeqTimer_BarLoop

SeqTimer_IncrementBar:
	inc 1, wa
	ld (xbc), wa

SeqTimer_BarLoop:
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x08, 0x00
	jr c, SeqData_DispatchByField

SeqData_SaveParsedState:
	ld c, (xsp + 18)
	extz bc
	lda xwa, (xsp + 4)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	pop xiz
	lda xsp, (xsp + 16)
	ret

SeqData_ResolveNextBlock:
	pushw iz
	sll wa, 8
	sub wa, 0x100
	extz xwa
	add xwa, (0x283e:16)
	ld a, (xwa + 3)
	ldfr_berp A, 0xf8
	extz iz
	cp iz, 0xffff
	jr nz, SeqTimer_BarOverflow
	ldw wa, 0x32
	calr SeqData_SetErrorCode

SeqTimer_BarOverflow:
	ld hl, iz
	popw iz
	ret

SeqTimer_BarReturn:
	dec 4, xsp
	pushw_erp 0xfa
	cp (CURRENT_MODE:16), 19
	jr nz, SeqTimer_BarChangeProcess
	ld a, (DEMO_ACTIVE_ENTRY:16)
	ldfr_berp A, 0xfb
	extz wa
	call Voice_GetPresetFieldWord
	ld (0xf19e:16), hl
	call Audio_CheckSubsystemReady
	ldto_berp A, 0xfb
	extz wa
	call Voice_GetPresetFieldAddr
	ld (xsp + 2), xhl
	ldib_erp 0xfb, 1

SeqTimer_HandleBarChange:
	ldto_berp C, 0xfb
	extz bc
	ldto_berp E, 0xfb
	dec 1, e
	extz de
	ld xwa, (xsp + 2)
	ld	e, (xwa+de)
	extz de
	ld wa, 0:i3
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqTimer_HandleBarChange
	res 7, (0x28ae:16)
	call MidiChannel_ResetAndConfigure
	jr SeqTimer_BarChangeCleanup

SeqTimer_BarChangeProcess:
	res 3, (0x28a7:16)
	set 4, (0x28b3:16)
	ld wa, 0:i3
	ldw bc, 0xbd
	calr Part_ReadByteDirect
	lda xwa, (0xfdad:16)
	cp l, 0xff
	jr nz, SeqTimer_BarChangeLoop
	bitm 2, (xwa)
	jr nz, SeqTimer_BarChangeReturn
	ld wa, 4:i3
	ld bc, 1:i3
	calr SeqStatus_SetOrClearBit
	ld (4330:16), 1
	pushw 0x4
	ldw wa, 0x91
	ld bc, 3:i3
	ld de, 4:i3
	jr SeqTimer_BarChangeEnd

SeqTimer_BarChangeLoop:
	bitm 2, (xwa)
	jr z, SeqTimer_BarChangeReturn
	ld wa, 4:i3
	ld bc, 0:i3
	calr SeqStatus_SetOrClearBit
	ld (4330:16), 1
	pushw 0x4
	ldw wa, 0x91
	ld bc, 3:i3
	ld de, 0:i3

SeqTimer_BarChangeEnd:
	call AssswbWr

SeqTimer_BarChangeReturn:
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	cpw (0xf19e:16), 0
	jr z, SeqTimer_BarChangeCleanup
	ld (4596:16), 0
	ld wa, 0:i3
	call BitMapOut_PrepareAndRender

SeqTimer_BarChangeCleanup:
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqTimer_CheckPlaybackCountdown:
	cp (CURRENT_MODE:16), 19
	jr nz, SeqTimer_FlagsReturn
	ld a, (0x2966:16)
	bit 7, a
	ret z
	dec 1, a
	ld (0x2966:16), a
	cp a, 0x80
	ret nz
	ei 6
	ldw (SEQ_BEAT_COUNT:16), 0
	ld (SEQ_BEAT_TICK:16), 0
	ld a, (DEMO_ACTIVE_ENTRY:16)
	extz wa
	call Demo_ProcessRecordEntry
	cp l, 0:i3
	jr z, SeqTimer_FlagsLoop
	ld (1054:16), 1
	ld (1045:16), 0
	ld (1046:16), 0
	ld (1076:16), 0

SeqTimer_FlagsLoop:
	ld (SEQ_TRANSPORT_STATE:16), 1
	ld (1056:16), 1
	ei 0

SeqTimer_FlagsReturn:
	ld (0x2966:16), 0
	ret

; SeqEvent dispatch case A
SeqEvent_CaseA:
	cpw (0xf19e:16), 0
	jr z, SeqEvent_CaseB
	and (0x28a7:16), 247
	call SeqAcc_InitPlaybackState

; SeqEvent dispatch case B
SeqEvent_CaseB:
	and (0x28ac:16), 223
	ret

ApEditSyori:
	cp xbc, EVT_DEC_VAL
	jr z, ApEditSyori_OnDecVal
	cp xbc, EVT_INC_VAL
	jr z, ApEditSyori_OnIncVal
	cp xbc, EVT_PAINT
	jr nz, SeqEvent_CaseE
	ld (0x2972:16), xde
	calr SeqEvent_MainHandler
	jr SeqEvent_CaseE

; SeqEvent dispatch case C
ApEditSyori_OnIncVal:
	ld xwa, xde
	calr AppEvent_ChainDispatch1
	jr SeqEvent_CaseE

; SeqEvent dispatch case D
ApEditSyori_OnDecVal:
	ld xwa, xde
	calr AppEvent_InlineHandler

; SeqEvent dispatch case E
SeqEvent_CaseE:
	ld xhl, 0:i3
	ret

; SeqEvent main handler
SeqEvent_MainHandler:
	ld a, (CURRENT_TITLE:16)
	cp a, 0x91
	jrl z, AppEvent_SubHandler0
	cp a, 0x90
	jr z, SeqEvent_Dispatch
	extz wa
	sub wa, 0x9b
	cp wa, 0:i3
	jrl lt, AppEvent_PostDefaultEvents
	cp wa, 0xd
	jrl gt, AppEvent_PostDefaultEvents
	add wa, wa
	lda xix, (SeqEvent_MainHandler_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SeqEvent_Dispatch:24)
	jp	t, (xix+wa)

; Sequencer event handler dispatch
SeqEvent_Dispatch:
	call SeqData_CopyBlockWithLookup
	ld a, (0x2878:16)
	extz wa
	call SeqPart_CountActiveVoices
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1f
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x20
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x21
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqnotecng:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xa
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xb
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqvelocng:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 5:i3
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqtrns:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 4:i3
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqmdel:
	ld wa, (0xf1d7:16)
	add wa, (0xf1d9:16)
	dec 1, wa
	ld (9772:16), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqmers:
	ld wa, (0xf1dc:16)
	add wa, (0xf1de:16)
	dec 1, wa
	ld (9766:16), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 6:i3
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqqtz:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 7:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x9
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqtrkmrg:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xc
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xd
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xe
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqmcp:
	ld wa, (0xf1ea:16)
	add wa, (0xf1ec:16)
	dec 1, wa
	ld (9768:16), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jrl AppEvent_PostEvent_Stub
SeqEvent_MainHandler_OnTitleSqmins:
	ld wa, (0xf1e2:16)
	add wa, (0xf1e4:16)
	dec 1, wa
	ld (9774:16), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a
	jrl AppEvent_PostEvent_Stub

; AppEvent sub-handler 0
AppEvent_SubHandler0:
	ld a, (9992:16)
	extz wa
	ld xbc, 0x2842
	call SeqData_CopyBlock2K
	ld a, (9994:16)
	extz wa
	ld xbc, 0x2852
	call SeqData_CopyBlock2K
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e
	jr AppEvent_PostEvent_Stub

AppEvent_PostDefaultEvents:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3

AppEvent_PostEvent_Stub:
	jp ApDeliveryEvent

; AppEvent chain dispatch 1
AppEvent_ChainDispatch1:
	dec 4, xsp
	push xiz
	ld xbc, xwa
	cp xbc, 0x1f
	jrl ugt, AppEvent_Epilogue
	add xbc, xbc
	add xbc, AppEvent_ChainDispatch1_CaseTable
	ld bc, (xbc)
	lda xix, (APP_EVENT_HANDLER_TABLE:24)
	jp	t, (xix+bc)
; Application event handler dispatch table
; Handles up to 32 event types (XBC 0-0x1f), used by ApDeliveryEvent system
; Each handler increments counters, sends notifications via CALL 0FA9E07h
APP_EVENT_HANDLER_TABLE:
	ld a, (CURRENT_TITLE:16)
	extz wa
	sub wa, 0x9c
	cp wa, 0:i3
	jr lt, AppEvtHandler_Branch_001
	cp wa, 7:i3
	jr le, AppEvtHandler_Branch_002
AppEvtHandler_Branch_001:
	ldw wa, 0x8
AppEvtHandler_Branch_002:
	sll wa, 2
	lda xix, (AppEvtHandler_Branch_002_RamPtrs:24)
	ld	xwa, (xix+wa)
	cp (xwa), 0x11
	jrl nc, AppEvent_Epilogue
	incm8 1, (xwa)
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl AppEvtHandler_Branch_033
; AppEvent_ChainDispatch1_IncFromMeasure: EVT_INC_VAL on sequencer-edit parameter 1: from-measure of the current page
;   (the title's FM word; SqedtFunc_OnGetFmString picks it per title: 0x2610, 0x261e, 0xf1d7, 0xf1dc, 0xf1f2, 0xf229,
;   else 0x2606).
AppEvent_ChainDispatch1_IncFromMeasure:
	ld a, (CURRENT_TITLE:16)
	extz wa
	sub wa, 0x9c
	cp wa, 0:i3
	jr lt, AppEvtHandler_Branch_003
	cp wa, 7:i3
	jr gt, AppEvtHandler_Branch_003
	add wa, wa
	lda xix, (AppEvtHandler_Branch_002_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (AppEvtHandler_Branch_002_Code:24)
	jp	t, (xix+wa)
AppEvtHandler_Branch_002_Code:
	lda xiz, (9744:16)
	lda xwa, (9746:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_002_OnTitleSqvelocng:
	lda xiz, (0xf229:16)
	lda xwa, (9722:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_002_OnTitleSqtrns:
	lda xiz, (9758:16)
	lda xwa, (9760:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_002_OnTitleSqmdel:
	lda xiz, (0xf1d7:16)
	lda xwa, (9772:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_002_OnTitleSqmers:
	lda xiz, (0xf1dc:16)
	lda xwa, (9766:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_002_OnTitleSqqtz:
	lda xiz, (0xf1f2:16)
	lda xwa, (9724:16)
	jr AppEvtHandler_Branch_004
AppEvtHandler_Branch_003:
	lda xiz, (9734:16)
	lda xwa, (9736:16)
AppEvtHandler_Branch_004:
	ld (xsp + 4), xwa
	cpw (xiz), 0x3e7
	jr nc, AppEvtHandler_Branch_005
	incw 1, (xiz)
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
AppEvtHandler_Branch_005:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, AppEvtHandler_Branch_006
	ld bc, (xiz)
	ld (xwa), bc
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
AppEvtHandler_Branch_006:
	ld a, (CURRENT_TITLE:16)
	cp a, 0xa3
	jrl z, AppEvtHandler_Branch_011
	cp a, 0xa1
	jrl z, AppEvtHandler_Branch_013
	jrl AppEvent_Epilogue
AppEvent_ChainDispatch1_IncLastMeasure:
	ld a, (CURRENT_TITLE:16)
	extz wa
	sub wa, 0x9c
	cp wa, 0:i3
	jr lt, AppEvtHandler_Branch_007
	cp wa, 7:i3
	jr gt, AppEvtHandler_Branch_007
	add wa, wa
	lda xix, (AppEvtHandler_Branch_006_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (AppEvtHandler_Branch_006_Code:24)
	jp	t, (xix+wa)
AppEvtHandler_Branch_006_Code:
	lda xiz, (9744:16)
	lda xwa, (9746:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_006_OnTitleSqvelocng:
	lda xiz, (0xf229:16)
	lda xwa, (9722:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_006_OnTitleSqtrns:
	lda xiz, (9758:16)
	lda xwa, (9760:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_006_OnTitleSqmdel:
	lda xiz, (0xf1d7:16)
	lda xwa, (9772:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_006_OnTitleSqmers:
	lda xiz, (0xf1dc:16)
	lda xwa, (9766:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_006_OnTitleSqqtz:
	lda xiz, (0xf1f2:16)
	lda xwa, (9724:16)
	jr AppEvtHandler_Branch_008
AppEvtHandler_Branch_007:
	lda xiz, (9734:16)
	lda xwa, (9736:16)
AppEvtHandler_Branch_008:
	ld (xsp + 4), xwa
	cpw (xwa), 0x3e7
	jr nc, AppEvtHandler_Branch_009
	ld xwa, (xsp + 4)
	incw 1, (xwa)
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
AppEvtHandler_Branch_009:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, AppEvtHandler_Branch_010
	ld wa, (xwa)
	ld (xiz), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
AppEvtHandler_Branch_010:
	ld a, (CURRENT_TITLE:16)
	cp a, 0xa3
	jr nz, AppEvtHandler_Branch_012
AppEvtHandler_Branch_011:
	ld wa, (9772:16)
	sub wa, (0xf1d7:16)
	inc 1, wa
	ld (0xf1d9:16), wa
	jrl AppEvent_Epilogue
AppEvtHandler_Branch_012:
	cp a, 0xa1
	jrl nz, AppEvent_Epilogue
AppEvtHandler_Branch_013:
	ld wa, (9766:16)
	sub wa, (0xf1dc:16)
	inc 1, wa
	ld (0xf1de:16), wa
	jrl AppEvent_Epilogue
AppEvent_ChainDispatch1_IncAdly:
	ld a, (9740:16)
	cp a, 0x60
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9740:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncTranspose:
	ld a, (9762:16)
	cp a, 0x7f
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9762:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 4:i3
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncVelocity:
	ld a, (0xf22e:16)
	cp a, 0x7f
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (0xf22e:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 5:i3
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncMersEventType:
	ld a, (0xf1e0:16)
	cp a, 2:i3
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1e0:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 6:i3
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncQtzValue:
	ld a, (0xf1f6:16)
	cp a, 6:i3
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1f6:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 7:i3
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncQtzStrength:
	ld a, (9728:16)
	cp a, 0x64
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9728:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncQtzWindow:
	ld a, (9730:16)
	cp a, 0x64
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9730:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x9
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncTnNote:
	ld a, (9750:16)
	cp a, 0x7f
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9750:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xa
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncCnNote:
	ld a, (9816:16)
	cp a, 0x7f
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9816:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xb
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncMrgTrackA:
	ld a, (0xf1d3:16)
	cp a, 0x10
	jr nc, AppEvtHandler_Branch_014
	inc 1, a
	ld (0xf1d3:16), a
	jr AppEvtHandler_Branch_015
AppEvtHandler_Branch_014:
	ld (0xf1d3:16), 1
	ld a, (0xf1d3:16)
AppEvtHandler_Branch_015:
	cp a, (0xf1d4:16)
	jr nz, AppEvtHandler_Branch_017
	cp a, 0x10
	jr nc, AppEvtHandler_Branch_016
	inc 1, a
	ld (0xf1d3:16), a
	jr AppEvtHandler_Branch_017
AppEvtHandler_Branch_016:
	ld (0xf1d3:16), 1
AppEvtHandler_Branch_017:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xc
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncMrgTrackB:
	ld a, (0xf1d4:16)
	cp a, 0x10
	jr nc, AppEvtHandler_Branch_018
	inc 1, a
	ld (0xf1d4:16), a
	jr AppEvtHandler_Branch_019
AppEvtHandler_Branch_018:
	ld (0xf1d4:16), 1
	ld a, (0xf1d4:16)
AppEvtHandler_Branch_019:
	cp a, (0xf1d3:16)
	jr nz, AppEvtHandler_Branch_021
	cp a, 0x10
	jr nc, AppEvtHandler_Branch_020
	inc 1, a
	ld (0xf1d4:16), a
	jr AppEvtHandler_Branch_021
AppEvtHandler_Branch_020:
	ld (0xf1d4:16), 1
AppEvtHandler_Branch_021:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xd
	jrl AppEvtHandler_Branch_033
AppEvent_ChainDispatch1_IncMrgTrackC:
	ld a, (0xf1d5:16)
	cp a, 0x10
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1d5:16), a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xe
	jrl AppEvtHandler_Branch_033
; AppEvent_ChainDispatch1_IncMcpParam: EVT_INC_VAL on sequencer-edit parameter 15: the six TT_SQMCP measure-copy
;   fields 15..20 (track A 0xf1e9, from 0xf1ea, last 0x2628, track B 0xf1ee, start 0xf1ef, repeat 9770): an inner
;   switch on N - 15, then all six are redrawn.
AppEvent_ChainDispatch1_IncMcpParam:	; cases 15, 16, 17, 18, 19, 20
	sub xwa, 0xf
	cp xwa, 0x0
	jrl c, AppEvtHandler_Branch_024
	cp xwa, 0x5
	jrl ugt, AppEvtHandler_Branch_024
	add xwa, xwa
	add xwa, AppEvtHandler_Branch_021_CaseTable
	ld wa, (xwa)
	lda xix, (AppEvtHandler_Branch_021_Code:24)
	jp	t, (xix+wa)
AppEvtHandler_Branch_021_Code:
	ld a, (0xf1e9:16)
	cp a, 0x11
	jrl nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (0xf1e9:16), a
	cp a, 0x11
	jrl nz, AppEvtHandler_Branch_024
	ld (0xf1ee:16), 17
	jr AppEvtHandler_Branch_024
AppEvtHandler_Branch_021_Case16:
	ld wa, (0xf1ea:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_022
	inc 1, wa
	ld (0xf1ea:16), wa
AppEvtHandler_Branch_022:
	ld wa, (0xf1ea:16)
	cp wa, (9768:16)
	jr ule, AppEvtHandler_Branch_023
	ld (9768:16), wa
	jr AppEvtHandler_Branch_023
AppEvtHandler_Branch_021_Case17:
	ld wa, (9768:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_023
	inc 1, wa
	ld (9768:16), wa
AppEvtHandler_Branch_023:
	ld wa, (9768:16)
	sub wa, (0xf1ea:16)
	inc 1, wa
	ld (0xf1ec:16), wa
	jr AppEvtHandler_Branch_024
AppEvtHandler_Branch_021_Case18:
	ld a, (0xf1ee:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (0xf1ee:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_024
	ld (0xf1e9:16), 17
	jr AppEvtHandler_Branch_024
AppEvtHandler_Branch_021_Case19:
	ld wa, (0xf1ef:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_024
	inc 1, wa
	ld (0xf1ef:16), wa
	jr AppEvtHandler_Branch_024
AppEvtHandler_Branch_021_Case20:
	ld a, (9770:16)
	cp a, 0x7f
	jr nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (9770:16), a
AppEvtHandler_Branch_024:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jrl AppEvtHandler_Branch_033
; AppEvent_ChainDispatch1_IncMinsParam: EVT_INC_VAL on sequencer-edit parameter 21: the six TT_SQMINS measure-insert
;   fields 21..26 (track A 0xf1e1, from 0xf1e2, last 0x262e, track B 0xf1e6, start 0xf1e7, repeat 9776): an inner
;   switch on N - 21, then all six are redrawn.
AppEvent_ChainDispatch1_IncMinsParam:	; cases 21, 22, 23, 24, 25, 26
	sub xwa, 0x15
	cp xwa, 0x0
	jrl c, AppEvtHandler_Branch_027
	cp xwa, 0x5
	jrl ugt, AppEvtHandler_Branch_027
	add xwa, xwa
	add xwa, AppEvtHandler_Branch_024_CaseTable
	ld wa, (xwa)
	lda xix, (AppEvtHandler_Branch_024_Code:24)
	jp	t, (xix+wa)
AppEvtHandler_Branch_024_Code:
	ld a, (0xf1e1:16)
	cp a, 0x11
	jrl nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (0xf1e1:16), a
	cp a, 0x11
	jrl nz, AppEvtHandler_Branch_027
	ld (0xf1e6:16), 17
	jr AppEvtHandler_Branch_027
AppEvtHandler_Branch_024_Case22:
	ld wa, (0xf1e2:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_025
	inc 1, wa
	ld (0xf1e2:16), wa
AppEvtHandler_Branch_025:
	ld wa, (0xf1e2:16)
	cp wa, (9774:16)
	jr ule, AppEvtHandler_Branch_026
	ld (9774:16), wa
	jr AppEvtHandler_Branch_026
AppEvtHandler_Branch_024_Case23:
	ld wa, (9774:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_026
	inc 1, wa
	ld (9774:16), wa
AppEvtHandler_Branch_026:
	ld wa, (9774:16)
	sub wa, (0xf1e2:16)
	inc 1, wa
	ld (0xf1e4:16), wa
	jr AppEvtHandler_Branch_027
AppEvtHandler_Branch_024_Case24:
	ld a, (0xf1e6:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (0xf1e6:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_027
	ld (0xf1e1:16), 17
	jr AppEvtHandler_Branch_027
AppEvtHandler_Branch_024_Case25:
	ld wa, (0xf1e7:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_027
	inc 1, wa
	ld (0xf1e7:16), wa
	jr AppEvtHandler_Branch_027
AppEvtHandler_Branch_024_Case26:
	ld a, (9776:16)
	cp a, 0x7f
	jr nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (9776:16), a
AppEvtHandler_Branch_027:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a
	jrl AppEvtHandler_Branch_033
; AppEvent_ChainDispatch1_IncScpParam: EVT_INC_VAL on sequencer-edit parameter 27: the four song-copy fields 27..30
;   (from-song 9992, from-track 9996, to-song 9994, to-track 9998); a song change reloads its 16-char name (0x2842 /
;   0x2852) through SeqData_CopyBlock2K.
AppEvent_ChainDispatch1_IncScpParam:	; cases 27, 28, 29, 30
	cp xwa, 0x1e
	jr z, AppEvtHandler_Branch_031
	cp xwa, 0x1d
	jr z, AppEvtHandler_Branch_029
	cp xwa, 0x1c
	jr z, AppEvtHandler_Branch_028
	cp xwa, 0x1b
	jr nz, AppEvtHandler_Branch_032
	ld a, (9992:16)
	cp a, 0xa
	jr nc, AppEvtHandler_Branch_032
	inc 1, a
	ld (9992:16), a
	extz wa
	ld xbc, 0x2842
	jr AppEvtHandler_Branch_030
AppEvtHandler_Branch_028:
	ld a, (9996:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_032
	inc 1, a
	ld (9996:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_032
	ld (9998:16), 17
	jr AppEvtHandler_Branch_032
AppEvtHandler_Branch_029:
	ld a, (9994:16)
	cp a, 0xa
	jr nc, AppEvtHandler_Branch_032
	inc 1, a
	ld (9994:16), a
	extz wa
	ld xbc, 0x2852
AppEvtHandler_Branch_030:
	call SeqData_CopyBlock2K
	jr AppEvtHandler_Branch_032
AppEvtHandler_Branch_031:
	ld a, (9998:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_032
	inc 1, a
	ld (9998:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_032
	ld (9996:16), 17
AppEvtHandler_Branch_032:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e
	jr AppEvtHandler_Branch_033
; AppEvent_ChainDispatch1_IncSclrSongNo: EVT_INC_VAL on sequencer-edit parameter 31: the song-clear song number (byte
;   0x2878, 0..10); reloads the song's data (SeqData_CopyBlockWithLookup, SeqPart_CountActiveVoices) and redraws
;   parameters 31..34.
AppEvent_ChainDispatch1_IncSclrSongNo:
	ld a, (0x2878:16)
	cp a, 0xa
	jr nc, AppEvent_Epilogue
	inc 1, a
	ld (0x2878:16), a
	call SeqData_CopyBlockWithLookup
	ld a, (0x2878:16)
	extz wa
	call SeqPart_CountActiveVoices
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1f
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x20
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x21
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x22
AppEvtHandler_Branch_033:
	call ApDeliveryEvent
AppEvent_Epilogue:
	pop xiz
	inc 4, xsp
	ret

; AppEvent inline handler dispatch
AppEvent_InlineHandler:
	dec 4, xsp
	push xiz
	ld xbc, xwa
	cp xbc, 0x1f
	jrl ugt, SeqState_DispatchEntry
	add xbc, xbc
	add xbc, AppEvent_InlineHandler_CaseTable
	ld bc, (xbc)
	lda xix, (AppEvent_SubDispatch:24)
	jp	t, (xix+bc)
; Application event sub-dispatch
AppEvent_SubDispatch:
	ld	a, (CURRENT_TITLE:16)
	extz	wa
	sub	wa, 156
	cp	wa, 0:i3
	jr	lt, AppEvent_InlineHandler_Skip15
	cp	wa, 7:i3
	jr	le, AppEvent_InlineHandler_Skip16
AppEvent_InlineHandler_Skip15:
	ldw	wa, 8
AppEvent_InlineHandler_Skip16:
	sll	wa, 2
	lda	xix, (AppEvent_SubDispatch_RamPtrs:24)
	ld	xwa, (xix+wa)
	cp	(xwa), 1
	jrl	ule, SeqState_DispatchEntry
	decm8	1, (xwa)
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jrl	AppEvent_InlineHandler_Join8
; AppEvent_InlineHandler_DecFromMeasure: EVT_DEC_VAL on sequencer-edit parameter 1: from-measure of the current page
;   (the title's FM word; SqedtFunc_OnGetFmString picks it per title: 0x2610, 0x261e, 0xf1d7, 0xf1dc, 0xf1f2, 0xf229,
;   else 0x2606).
AppEvent_InlineHandler_DecFromMeasure:
	ld	a, (CURRENT_TITLE:16)
	extz	wa
	sub	wa, 156
	cp	wa, 0:i3
	jr	lt, AppEvent_InlineHandler_Skip17
	cp	wa, 7:i3
	jr	gt, AppEvent_InlineHandler_Skip17
	add	wa, wa
	lda	xix, (AppEvent_SubDispatch_Table_2:24)
	ld	wa, (xix+wa)
	lda	xix, (AppEvent_SubDispatch_Code:24)
	jp	t, (xix+wa)
AppEvent_SubDispatch_Code:
	lda_d16	xiz, (9744)
	lda	xwa, (9746:16)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Switch2_OnTitleSqvelocng:
	lda	xiz, (0xf229:16)
	lda_d16	xwa, (9722)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Switch2_OnTitleSqtrns:
	lda	xiz, (9758:16)
	lda_d16	xwa, (9760)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Switch2_OnTitleSqmdel:
	lda_d16	xiz, (61911)
	lda_d16	xwa, (9772)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Switch2_OnTitleSqmers:
	lda	xiz, (0xf1dc:16)
	lda	xwa, (9766:16)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Switch2_OnTitleSqqtz:
	lda	xiz, (0xf1f2:16)
	lda	xwa, (9724:16)
	jr	AppEvent_InlineHandler_Join9
AppEvent_InlineHandler_Skip17:
	lda	xiz, (9734:16)
	lda	xwa, (9736:16)
AppEvent_InlineHandler_Join9:
	ld	(xsp+4), xwa
	cpw	(xiz), 1
	jr	ule, AppEvent_InlineHandler_Skip18
	decm	1, (xiz)
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 1:i3
	call	ApDeliveryEvent
AppEvent_InlineHandler_Skip18:
	ld	bc, (xiz)
	ld	xwa, (xsp+4)
	cp	bc, (xwa)
	jr	ule, AppEvent_InlineHandler_Skip
	ld	bc, (xiz)
	ld	(xwa), bc
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 2:i3
	call	ApDeliveryEvent
AppEvent_InlineHandler_Skip:
	ld	a, (CURRENT_TITLE:16)
	cp	a, 163
	jrl	z, AppEvent_InlineHandler_Skip4
	cp	a, 161
	jrl	z, AppEvent_InlineHandler_Skip20
	jrl	SeqState_DispatchEntry
AppEvent_InlineHandler_DecLastMeasure:
	ld	a, (CURRENT_TITLE:16)
	extz	wa
	sub	wa, 156
	cp	wa, 0:i3
	jr	lt, AppEvent_InlineHandler_Skip19
	cp	wa, 7:i3
	jr	gt, AppEvent_InlineHandler_Skip19
	add	wa, wa
	lda	xix, (AppEvent_SubDispatch_Table:24)
	ld	wa, (xix+wa)
	lda	xix, (AppEvent_SubDispatch_Code_2:24)
	jp	t, (xix+wa)
AppEvent_SubDispatch_Code_2:
	lda_d16	xiz, (9744)
	lda_d16	xwa, (9746)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Switch3_OnTitleSqvelocng:
	lda_d16	xiz, (61993)
	lda_d16	xwa, (9722)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Switch3_OnTitleSqtrns:
	lda_d16	xiz, (9758)
	lda	xwa, (9760:16)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Switch3_OnTitleSqmdel:
	lda	xiz, (0xf1d7:16)
	lda_d16	xwa, (9772)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Switch3_OnTitleSqmers:
	lda	xiz, (0xf1dc:16)
	lda_d16	xwa, (9766)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Switch3_OnTitleSqqtz:
	lda	xiz, (0xf1f2:16)
	lda	xwa, (9724:16)
	jr	AppEvent_InlineHandler_Join
AppEvent_InlineHandler_Skip19:
	lda	xiz, (9734:16)
	lda	xwa, (9736:16)
AppEvent_InlineHandler_Join:
	ld	(xsp+4), xwa
	cpw	(xwa), 1
	jr	ule, AppEvent_InlineHandler_Skip2
	ld	xwa, (xsp+4)
	decm	1, (xwa)
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 2:i3
	call	ApDeliveryEvent
AppEvent_InlineHandler_Skip2:
	ld	bc, (xiz)
	ld	xwa, (xsp+4)
	cp	bc, (xwa)
	jr	ule, AppEvent_InlineHandler_Skip3
	ld	wa, (xwa)
	ld	(xiz), wa
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 1:i3
	call	ApDeliveryEvent
AppEvent_InlineHandler_Skip3:
	ld	a, (CURRENT_TITLE:16)
	cp	a, 163
	jr	nz, AppEvent_InlineHandler_Skip5
AppEvent_InlineHandler_Skip4:
	ld	wa, (9772:16)
	sub wa, (61911:16)
	inc 1, wa
	ld	(0xf1d9:16), wa
	jrl	SeqState_DispatchEntry
AppEvent_InlineHandler_Skip5:
	cp	a, 161
	jrl	nz, SeqState_DispatchEntry
AppEvent_InlineHandler_Skip20:
	ld	wa, (9766:16)
	sub wa, (61916:16)
	inc 1, wa
	ld (61918:16), wa
	jrl	SeqState_DispatchEntry
AppEvent_InlineHandler_DecAdly:
	ld	a, (9740:16)
	cp	a, 160
	jrl	le, SeqState_DispatchEntry
	dec	1, a
	ld	(9740:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 3:i3
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecTranspose:
	ld	a, (9762:16)
	cp	a, 129
	jrl	le, SeqState_DispatchEntry
	dec	1, a
	ld	(9762:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 4:i3
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecVelocity:
	ld	a, (0xf22e:16)
	cp	a, 129
	jrl	le, SeqState_DispatchEntry
	dec	1, a
	ld	(0xf22e:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 5:i3
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecMersEventType:
	ld	a, (0xf1e0:16)
	cp	a, 0:i3
	jrl	z, SeqState_DispatchEntry
	dec	1, a
	ld	(0xf1e0:16), a
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 6:i3
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecQtzValue:
	ld	a, (0xf1f6:16)
	cp	a, 0:i3
	jrl	z, SeqState_DispatchEntry
	dec	1, a
	ld	(0xf1f6:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 7:i3
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecQtzStrength:
	ld	a, (9728:16)
	cp	a, 0:i3
	jrl	z, SeqState_DispatchEntry
	dec	1, a
	ld	(9728:16), a
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 8
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecQtzWindow:
	ld	a, (9730:16)
	cp	a, 156
	jrl	le, SeqState_DispatchEntry
	dec	1, a
	ld	(9730:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 9
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecTnNote:
	ld	a, (9750:16)
	cp	a, 0:i3
	jrl	z, SeqState_DispatchEntry
	dec	1, a
	ld	(9750:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 10
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecCnNote:
	ld	a, (9816:16)
	cp	a, 0:i3
	jrl	z, SeqState_DispatchEntry
	dec	1, a
	ld	(9816:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 11
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecMrgTrackA:
	ld a, (61907:16)
	cp a, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip6
	dec	1, a
	ld	(0xf1d3:16), a
	jr	AppEvent_InlineHandler_Join2
AppEvent_InlineHandler_Skip6:
	ld (61907:16), 16
	ld a, (61907:16)
AppEvent_InlineHandler_Join2:
	cp a, (61908:16)
	jr	nz, AppEvent_InlineHandler_Entry
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip7
	dec	1, a
	ld	(0xf1d3:16), a
	jr	AppEvent_InlineHandler_Entry
AppEvent_InlineHandler_Skip7:
	ld	(0xf1d3:16), 16
AppEvent_InlineHandler_Entry:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 12
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecMrgTrackB:
	ld	a, (0xf1d4:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip8
	dec	1, a
	ld	(0xf1d4:16), a
	jr	AppEvent_InlineHandler_Join3
AppEvent_InlineHandler_Skip8:
	ld	(0xf1d4:16), 16
	ld	a, (0xf1d4:16)
AppEvent_InlineHandler_Join3:
	cp a, (61907:16)
	jr	nz, AppEvent_InlineHandler_Entry2
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip9
	dec	1, a
	ld	(0xf1d4:16), a
	jr	AppEvent_InlineHandler_Entry2
AppEvent_InlineHandler_Skip9:
	ld	(0xf1d4:16), 16
AppEvent_InlineHandler_Entry2:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 13
	jrl	AppEvent_InlineHandler_Join8
AppEvent_InlineHandler_DecMrgTrackC:
	ld	a, (0xf1d5:16)
	cp	a, 1:i3
	jrl	ule, SeqState_DispatchEntry
	dec	1, a
	ld	(0xf1d5:16), a
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 14
	jrl	AppEvent_InlineHandler_Join8
; AppEvent_InlineHandler_DecMcpParam: EVT_DEC_VAL on sequencer-edit parameter 15: the six TT_SQMCP measure-copy fields
;   15..20 (track A 0xf1e9, from 0xf1ea, last 0x2628, track B 0xf1ee, start 0xf1ef, repeat 9770): an inner switch on N
;   - 15, then all six are redrawn.
AppEvent_InlineHandler_DecMcpParam:	; cases 15, 16, 17, 18, 19, 20
	sub	xwa, 15
	cp	xwa, 0
	jrl	c, AppEvent_InlineHandler_Join5
	cp	xwa, 5
	jrl	ugt, AppEvent_InlineHandler_Join5
	add	xwa, xwa
	add	xwa, AppEvent_SubDispatch_CaseTable_2
	ld	wa, (xwa)
	lda	xix, (AppEvent_SubDispatch_Code_2_Code:24)
	jp	t, (xix+wa)
AppEvent_SubDispatch_Code_2_Code:
	ld a, (61929:16)
	cp a, 1:i3
	jrl ule, AppEvent_InlineHandler_Join5
	dec	1, a
	ld	(0xf1e9:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Join5
	ld	(0xf1ee:16), 16
	jr	AppEvent_InlineHandler_Join5
AppEvent_InlineHandler_DecMcpFromMeasure:
	ld	wa, (0xf1ea:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Join4
	dec	1, wa
	ld	(0xf1ea:16), wa
	jr	AppEvent_InlineHandler_Join4
AppEvent_InlineHandler_DecMcpLastMeasure:
	ld	wa, (9768:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip10
	dec	1, wa
	ld	(9768:16), wa
AppEvent_InlineHandler_Skip10:
	ld	wa, (9768:16)
	cp (61930:16), wa
	jr	ule, AppEvent_InlineHandler_Join4
	ld	(0xf1ea:16), wa
AppEvent_InlineHandler_Join4:
	ld	wa, (9768:16)
	sub wa, (61930:16)
	inc 1, wa
	ld (61932:16), wa
	jr	AppEvent_InlineHandler_Join5
AppEvent_InlineHandler_DecMcpTrackB:
	ld	a, (0xf1ee:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Join5
	dec	1, a
	ld	(0xf1ee:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Join5
	ld	(0xf1e9:16), 16
	jr	AppEvent_InlineHandler_Join5
AppEvent_InlineHandler_DecMcpStartMeasure:
	ld	wa, (0xf1ef:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Join5
	dec	1, wa
	ld	(0xf1ef:16), wa
	jr	AppEvent_InlineHandler_Join5
AppEvent_InlineHandler_DecMcpRepeat:
	ld	a, (9770:16)
	cp	a, 0:i3
	jr	z, AppEvent_InlineHandler_Join5
	dec	1, a
	ld	(9770:16), a
AppEvent_InlineHandler_Join5:
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 15
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 16
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 17
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 18
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 19
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 20
	jrl	AppEvent_InlineHandler_Join8
; AppEvent_InlineHandler_DecMinsParam: EVT_DEC_VAL on sequencer-edit parameter 21: the six TT_SQMINS measure-insert
;   fields 21..26 (track A 0xf1e1, from 0xf1e2, last 0x262e, track B 0xf1e6, start 0xf1e7, repeat 9776): an inner
;   switch on N - 21, then all six are redrawn.
AppEvent_InlineHandler_DecMinsParam:	; cases 21, 22, 23, 24, 25, 26
	sub	xwa, 21
	cp	xwa, 0
	jrl	c, AppEvent_InlineHandler_Entry3
	cp	xwa, 5
	jrl	ugt, AppEvent_InlineHandler_Entry3
	add	xwa, xwa
	add	xwa, AppEvent_SubDispatch_CaseTable
	ld	wa, (xwa)
	lda	xix, (AppEvent_SubDispatch_Code_2_Code2:24)
	jp	t, (xix+wa)
AppEvent_SubDispatch_Code_2_Code2:
	ld a, (61921:16)
	cp a, 1:i3
	jrl ule, AppEvent_InlineHandler_Entry3
	dec	1, a
	ld	(0xf1e1:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Entry3
	ld	(0xf1e6:16), 16
	jr	AppEvent_InlineHandler_Entry3
AppEvent_SubDispatch_Case22:
	ld	wa, (0xf1e2:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Join6
	dec	1, wa
	ld	(0xf1e2:16), wa
	jr	AppEvent_InlineHandler_Join6
AppEvent_SubDispatch_Case23:
	ld	wa, (9774:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Skip11
	dec	1, wa
	ld	(9774:16), wa
AppEvent_InlineHandler_Skip11:
	ld	wa, (9774:16)
	cp (61922:16), wa
	jr	ule, AppEvent_InlineHandler_Join6
	ld	(0xf1e2:16), wa
AppEvent_InlineHandler_Join6:
	ld	wa, (9774:16)
	sub wa, (61922:16)
	inc 1, wa
	ld	(0xf1e4:16), wa
	jr	AppEvent_InlineHandler_Entry3
AppEvent_SubDispatch_Case24:
	ld	a, (0xf1e6:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry3
	dec	1, a
	ld	(0xf1e6:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Entry3
	ld	(0xf1e1:16), 16
	jr	AppEvent_InlineHandler_Entry3
AppEvent_SubDispatch_Case25:
	ld	wa, (0xf1e7:16)
	cp	wa, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry3
	dec	1, wa
	ld	(0xf1e7:16), wa
	jr	AppEvent_InlineHandler_Entry3
AppEvent_SubDispatch_Case26:
	ld	a, (9776:16)
	cp	a, 0:i3
	jr	z, AppEvent_InlineHandler_Entry3
	dec	1, a
	ld	(9776:16), a
AppEvent_InlineHandler_Entry3:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 21
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 22
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 23
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 24
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 25
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 26
	jrl	AppEvent_InlineHandler_Join8
; AppEvent_InlineHandler_DecScpParam: EVT_DEC_VAL on sequencer-edit parameter 27: the four song-copy fields 27..30
;   (from-song 9992, from-track 9996, to-song 9994, to-track 9998); a song change reloads its 16-char name (0x2842 /
;   0x2852) through SeqData_CopyBlock2K.
AppEvent_InlineHandler_DecScpParam:	; cases 27, 28, 29, 30
	cp	xwa, 30
	jr	z, AppEvent_InlineHandler_Skip14
	cp	xwa, 29
	jr	z, AppEvent_InlineHandler_Skip13
	cp	xwa, 28
	jr	z, AppEvent_InlineHandler_Skip12
	cp	xwa, 27
	jr	nz, AppEvent_InlineHandler_Entry4
	ld	a, (9992:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry4
	dec	1, a
	ld	(9992:16), a
	extz	wa
	ld	xbc, 0x2842
	jr	AppEvent_InlineHandler_Join7
AppEvent_InlineHandler_Skip12:
	ld	a, (9996:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry4
	dec	1, a
	ld	(9996:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Entry4
	ld	(9998:16), 16
	jr	AppEvent_InlineHandler_Entry4
AppEvent_InlineHandler_Skip13:
	ld	a, (9994:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry4
	dec	1, a
	ld	(9994:16), a
	extz	wa
	ld	xbc, 0x2852
AppEvent_InlineHandler_Join7:
	call	SeqData_CopyBlock2K
	jr	AppEvent_InlineHandler_Entry4
AppEvent_InlineHandler_Skip14:
	ld	a, (9998:16)
	cp	a, 1:i3
	jr	ule, AppEvent_InlineHandler_Entry4
	dec	1, a
	ld	(9998:16), a
	cp	a, 16
	jr	nz, AppEvent_InlineHandler_Entry4
	ld	(9996:16), 16
AppEvent_InlineHandler_Entry4:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 27
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 28
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 29
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 30
	jr	AppEvent_InlineHandler_Join8
; AppEvent_InlineHandler_DecSclrSongNo: EVT_DEC_VAL on sequencer-edit parameter 31: the song-clear song number (byte
;   0x2878, 0..10); reloads the song's data (SeqData_CopyBlockWithLookup, SeqPart_CountActiveVoices) and redraws
;   parameters 31..34.
AppEvent_InlineHandler_DecSclrSongNo:
	ld	a, (0x2878:16)
	cp	a, 0:i3
	jr	z, SeqState_DispatchEntry
	dec	1, a
	ld	(0x2878:16), a
	call	SeqData_CopyBlockWithLookup
	ld	a, (0x2878:16)
	extz	wa
	call	SeqPart_CountActiveVoices
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 31
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 32
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 33
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 34
AppEvent_InlineHandler_Join8:
	call	ApDeliveryEvent

; Sequencer state dispatch entry
SeqState_DispatchEntry:
	pop xiz
	inc 4, xsp
	ret

SeqVoice_DispatchAllEvents:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

SeqVoice_DispatchLoop:
	ldto_berp A, 0xfb
	extz wa
	calr SeqVoice_DispatchEventToHandler
	ldto_berp A, 0xfb
	extz wa
	calr SeqVoice_ComputeStatusFlags
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqVoice_DispatchLoop
	popw_erp 0xfa
	ret

SeqVoice_DispatchEventToHandler:
	dec 2, xsp
	pushw_erp 0xfa
	ld (xsp + 2), a
	ld a, (xsp + 2)
	inc 1, a
	extz wa
	call Part_IsVoiceActive
	ldfr_berp L, 0xfb
	ld c, (xsp + 2)
	inc 1, c
	extz bc
	ld wa, 0:i3
	call Part_ReadSubBlock32
	ld xbc, 0:i3
	ldto_berp C, 0xfb
	sll xbc, 8
	ld xwa, 0:i3
	ld a, (xsp + 2)
	sll xwa, 16
	ld xix, xwa
	add xix, xbc
	ld h, 0x0:opc
	extz xhl
	add xhl, xix
	ld xwa, 0xffffffff
	ld xbc, EVT_TRSW_PART
	ld xde, xhl
	call ApPostEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqVoice_ComputeStatusFlags:
	dec 2, xsp
	ld (xsp), a
	ld e, (ACTIVE_TITLE:16)
	ld bc, 1:i3
	ld a, (xsp)
	and a, 0xf
	jr z, SeqStatus_CheckState9A
	slaa bc

SeqStatus_CheckState9A:
	cp e, 0x9a
	jr z, SeqStatus_Handle9AState
	ld a, (xsp)
	inc 1, a
	extz wa
	cp e, 0x87
	jr z, SeqStatus_CheckHighState
	cp e, 0x85
	jr z, SeqStatus_CheckHighState
	cp e, 0x7a
	jr z, SeqStatus_CheckActiveVoice
	cp e, 0x78
	jr z, SeqStatus_CheckActiveVoice
	cp e, 0x81
	jr nz, SeqVoice_PostStatusEvent_Inactive

SeqStatus_CheckActiveVoice:
	and bc, (0xf19e:16)
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cp hl, 0:i3
	jr nz, SeqStatus_SetActiveFlag

SeqVoice_PostStatusEvent_Inactive:
	ld c, 0x0:opc

SeqVoice_PostStatus_Loop:
	ld b, 0x0:opc
	extz xbc
	ld xwa, 0:i3
	ld a, (xsp)
	sll xwa, 16
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, EVT_TRSW_COMMAND
	call ApPostEvent
	inc 2, xsp
	ret

SeqStatus_CheckHighState:
	ld de, bc
	and bc, (0x28a8:16)
	jr z, SeqStatus_CheckHighFallback
	ld c, 0x1:opc
	jr SeqVoice_PostStatus_Loop

SeqStatus_CheckHighFallback:
	and de, (0xf19e:16)
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cp hl, 0:i3
	jr z, SeqVoice_PostStatusEvent_Inactive

SeqStatus_SetActiveFlag:
	ld c, 0x2:opc
	jr SeqVoice_PostStatus_Loop

SeqStatus_Handle9AState:
	and bc, (9704:16)
	jr z, SeqVoice_PostStatusEvent_Inactive
	ld c, 0x4:opc
	jr SeqVoice_PostStatus_Loop

AppEvent_HandleChannelEvent:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ld e, (CURRENT_TITLE:16)
	cp e, 0x9a
	jrl z, AppEvent_Handle9AToggle
	ld c, (xsp + 4)
	inc 1, c
	cp e, 0x97
	jrl z, AppEvent_HandleRecordState
	cp e, 0x94
	jrl z, AppEvent_HandleRecordState
	cp e, 0x89
	jrl z, SeqState_LabelDispatch
	ld wa, (0xf19e:16)
	ldfr_werp WA, 0xfa
	extz bc
	cp e, 0x87
	jr z, AppEvent_HandleStateChange
	cp e, 0x85
	jr z, AppEvent_HandleStateChange
	cp e, 0x7a
	jr z, AppEvent_ToggleChannel
	cp e, 0x78
	jr z, AppEvent_ToggleChannel
	cp e, 0x81
	jrl nz, AppEvent_PopIzSkip2Ret

AppEvent_ToggleChannel:
	ld wa, bc
	call SeqPlay_HandleChannelToggle
	ld bc, (0xf19e:16)
	cpw_erp BC, 0xfa
	jrl z, AppEvent_PopIzSkip2Ret
	ld de, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, AppEvent_ToggleShiftDone
	slaa de

AppEvent_ToggleShiftDone:
	and de, bc
	ld l, 0x0:opc
	cp de, 0:i3
	jr z, AppEvent_ToggleSetStatus
	ld l, 0x2:opc

AppEvent_ToggleSetStatus:
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0:i3
	ld a, (xsp + 4)
	sll xwa, 16
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_TRSW_COMMAND
	call ApPostEvent
	ld a, (xsp + 4)
	extz wa
	jr SeqState_Case4

AppEvent_HandleStateChange:
	ld iz, (0x28a8:16)
	ld wa, bc
	call SeqPlay_HandleChannelState
	ld bc, (0xf19e:16)
	cpw_erp BC, 0xfa
	jr nz, SeqState_Case0
	cp (0x28a8:16), iz
	jrl z, AppEvent_PopIzSkip2Ret

; Sequencer state case 0
SeqState_Case0:
	ld de, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqState_Case1
	slaa de

; Sequencer state case 1
SeqState_Case1:
	ld wa, de
	and de, (0x28a8:16)
	jr z, SeqState_Case2
	ld l, 0x1:opc
	jr SeqState_Case3

; Sequencer state case 2
SeqState_Case2:
	and wa, bc
	ld l, 0x0:opc
	cp wa, 0:i3
	jr z, SeqState_Case3
	ld l, 0x2:opc

; Sequencer state case 3
SeqState_Case3:
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0:i3
	ld a, (xsp + 4)
	sll xwa, 16
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_TRSW_COMMAND
	call ApPostEvent
	ld a, (xsp + 4)
	extz wa

; Sequencer state case 4
SeqState_Case4:
	calr SeqVoice_DispatchEventToHandler
	jrl AppEvent_PopIzSkip2Ret

; Sequencer state label dispatch
SeqState_LabelDispatch:
	extz bc
	dec 1, bc
	cp bc, 0:i3
	jrl lt, AppEvent_PopIzSkip2Ret
	cp bc, 0xf
	jrl gt, AppEvent_PopIzSkip2Ret
	add bc, bc
	lda xix, (SeqState_LabelDispatch_CaseTable:24)
	ld	bc, (xix+bc)
	lda xix, (SoundData_HandlerDispatch:24)
	jp	t, (xix+bc)
; Sound data handler dispatch
SoundData_HandlerDispatch:
	call	PartParam_Handler_00
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack2:
	call	PartParam_Handler_01
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack3:
	call	PartParam_Handler_02
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack4:
	call	PartParam_Handler_03
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack5:
	call	PartParam_Handler_04
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack6:
	call	PartParam_Handler_05
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack7:
	call	PartParam_Handler_06
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack8:
	call	PartParam_Handler_07
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack9:
	call	PartParam_Handler_08
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack10:
	call	PartParam_Handler_09
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack11:
	call	PartParam_Handler_0A
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack12:
	call	PartParam_Handler_0B
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack13:
	call	PartParam_Handler_0C
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack14:
	call	PartParam_Handler_0D
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack15:
	call	PartParam_Handler_0E
	jrl	AppEvent_PopIzSkip2Ret
SeqState_LabelDispatch_OnTrack16:
	call	PartParam_Handler_0F
	jrl	AppEvent_PopIzSkip2Ret

AppEvent_HandleRecordState:
	extz bc
	dec 2, bc
	cp bc, 0:i3
	jr lt, AppEvent_RecordClampLow
	cp bc, 0xe
	jr le, AppEvent_RecordDispatch

AppEvent_RecordClampLow:
	ldw bc, 0xf

AppEvent_RecordDispatch:
	lda xix, (AppEvent_RecordDispatch_Table:24)
	ld	a, (xix+bc)
	ld (xsp + 4), a
	inc 1, a
	extz wa
	call BmDrEdit_CheckNoteType
	cp hl, 0:i3
	jr nz, AppEvent_PopIzSkip2Ret
	mrdb5 0x8f, 0x04, 0x19, 0x65, 0x29
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda xbc, (AppEvent_RecordDispatch_BitMasks:24)
	ldw	(0x0d4f:16), (xbc+wa)
	call BmDrEdit_SaveSequencerState
	jr AppEvent_PopIzSkip2Ret

AppEvent_Handle9AToggle:
	ld de, 1:i3
	ld a, (xsp + 4)
	and a, 0xf
	jr z, AppEvent_9AShiftDone
	slaa de

AppEvent_9AShiftDone:
	ld wa, de
	ld bc, (9704:16)
	and wa, bc
	jr z, AppEvent_9ASetOff
	ld l, 0x0:opc
	cpl de
	and bc, de
	jr AppEvent_9AStoreAndPost

AppEvent_9ASetOff:
	ld l, 0x4:opc
	or bc, de

AppEvent_9AStoreAndPost:
	ld (9704:16), bc
	ld h, 0x0:opc
	extz xhl
	ld xwa, 0:i3
	ld a, (xsp + 4)
	sll xwa, 16
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_TRSW_COMMAND
	call ApPostEvent

AppEvent_PopIzSkip2Ret:
	pop xiz
	inc 2, xsp
	ret

EffEditMain:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	ld e, (ACTIVE_TITLE:16)
	cp xbc, EVT_CNG_EFF_PARA
	jrl z, EffEdit_HandleDirectWrite
	cp xbc, EVT_CNG_EFF_TYPE
	jrl z, EffEdit_HandleParamChange
	cp xbc, EVT_PAINT
	jrl nz, AppEvent_ReturnZeroEpilogue4
	ld xwa, (xsp + 2)
	ld (0x2972:16), xwa
	calr EffEdit_ValidateAndReadParams
	cp hl, 0:i3
	jrl nz, AppEvent_ReturnZeroEpilogue4
	ld xwa, (xsp + 2)
	ld xbc, EVT_RET_EFF_FIX
	ld xde, 0:i3
	call ApDeliveryEvent
	ld a, (ACTIVE_TITLE:16)
	cp a, 0xd6
	jr z, EffEdit_DispatchTypeD6
	cp a, 0xe
	jr z, EffEdit_DispatchTypeE
	cp a, 0xb
	jr z, EffEdit_DispatchTypeB
	cp a, 0xa
	jrl nz, AppEvent_ReturnZeroEpilogue4

EffEdit_DispatchTypeB:
	ld iz, 0:i3

EffEdit_TypeBLoop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, EVT_RET_EFF_PARA
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_TypeBLoop
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_DispatchTypeE:
	ld xwa, (xsp + 2)
	ld xbc, EVT_RET_EFF_PARA
	ld xde, 0:i3
	call ApDeliveryEvent
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_DispatchTypeD6:
	ld iz, 0:i3

EffEdit_TypeD6Loop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, EVT_RET_EFF_PARA
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 4:i3
	jr c, EffEdit_TypeD6Loop
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_HandleParamChange:
	ld xbc, (xsp + 2)
	cp e, 0xb
	jrl z, EffEdit_ParamChangeB
	cp e, 0xa
	jr z, EffEdit_ParamChangeA
	cp e, 0xd6
	jr z, EffEdit_ParamChangeD6
	cp e, 0xe
	jrl nz, AppEvent_ReturnZeroEpilogue4
	ld (0xe38c:16), 1
	ld xwa, 0x4d00
	jrl EffEdit_CallWriteParam

EffEdit_ParamChangeD6:
	ld (0xe38c:16), 1
	ld xwa, 0x4e00
	jrl EffEdit_CallWriteParam

EffEdit_ParamChangeA:
	ld (0xe38c:16), 1
	ld wa, (0x2976:16)
	extz wa
	lda xde, (EffEdit_ParamChangeA_Table_2:24)
	ld	e, (xde+wa)
	lda xwa, (EffEdit_ParamChangeA_Table:24)
	cp e, 0:i3
	jr ge, EffEdit_ParamAPositive
	ld c, (xwa)
	exts bc
	ld xwa, 0x4b00
	jrl EffEdit_WriteDSPAndReturn

EffEdit_ParamAPositive:
	cp bc, 0:i3
	jr le, EffEdit_ParamANegative
	inc 1, e
	ld	c, (xwa+e)
	cp c, 0:i3
	jr lt, AppEvent_DeliveryLoop
	exts bc
	ld xwa, 0x4b00
	jrl EffEdit_WriteDSPAndReturn

EffEdit_ParamANegative:
	cp bc, 0:i3
	jr ge, AppEvent_DeliveryLoop
	cp e, 0:i3
	jr z, AppEvent_DeliveryLoop
	dec 1, e
	ld	c, (xwa+e)
	exts bc
	ld xwa, 0x4b00
	jr EffEdit_WriteDSPAndReturn

AppEvent_DeliveryLoop:
	ld iz, 0:i3

EffEdit_DeliveryLoopBody:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, EVT_RET_EFF_PARA
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_DeliveryLoopBody
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_ParamChangeB:
	ld (0xe38c:16), 1
	ld wa, (0x2976:16)
	extz wa
	lda xde, (EffEdit_ParamChangeB_Table_2:24)
	ld	e, (xde+wa)
	lda xwa, (EffEdit_ParamChangeB_Table:24)
	cp e, 0:i3
	jr ge, EffEdit_ParamBPositive
	ld c, (xwa)
	exts bc
	ld xwa, 0x4900
	jr EffEdit_WriteDSPAndReturn

EffEdit_ParamBPositive:
	cp bc, 0:i3
	jr le, EffEdit_ParamBNegative
	inc 1, e
	ld	c, (xwa+e)
	cp c, 0:i3
	jr lt, AppEvent_DeliveryNoRet
	exts bc
	ld xwa, 0x4900
	jr EffEdit_WriteDSPAndReturn

EffEdit_ParamBNegative:
	cp bc, 0:i3
	jr ge, AppEvent_DeliveryNoRet
	cp e, 0:i3
	jr z, AppEvent_DeliveryNoRet
	dec 1, e
	ld	c, (xwa+e)
	exts bc
	ld xwa, 0x4900

EffEdit_WriteDSPAndReturn:
	call DSPCfg_WriteParamFull
	jr AppEvent_ReturnZeroEpilogue4

AppEvent_DeliveryNoRet:
	ld iz, 0:i3

EffEdit_DeliveryNoRetLoop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, EVT_RET_EFF_PARA
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_DeliveryNoRetLoop
	jr AppEvent_ReturnZeroEpilogue4

EffEdit_HandleDirectWrite:
	ld xwa, (xsp + 2)
	and xwa, 0xff
	ld w, 0x0:opc
	extz xwa
	cp e, 0xd6
	jr z, EffEdit_DirectWriteD6
	cp e, 0xe
	jr z, EffEdit_DirectWriteE
	cp e, 0xc
	jr z, EffEdit_DirectWriteC
	cp e, 0xb
	jr z, EffEdit_DirectWriteB
	cp e, 0xa
	jr nz, AppEvent_ReturnZeroEpilogue4
	add xwa, 0x4b10

Voice_OffsetAndDispatch:
	ld xbc, (xsp + 2)
	srl xbc, 8
	ldiw_erp 0xe6, 0
	cp e, 0xc
	jr nz, EffEdit_CallWriteParam
	calr EffEdit_ValidateRangeDelta
	jr AppEvent_ReturnZeroEpilogue4

EffEdit_DirectWriteB:
	add xwa, 0x4910
	jr Voice_OffsetAndDispatch

EffEdit_DirectWriteC:
	add xwa, 0x4c10
	jr Voice_OffsetAndDispatch

EffEdit_DirectWriteE:
	ld xwa, 0x4d10
	jr Voice_OffsetAndDispatch

EffEdit_DirectWriteD6:
	add xwa, 0x4e10
	jr Voice_OffsetAndDispatch

EffEdit_CallWriteParam:
	call DSPCfg_WriteParamDelta

AppEvent_ReturnZeroEpilogue4:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

EffEdit_DSPConfigBlock:
	dec	4, xsp
	pushw	iz
	ld	a, (SWBTWR_EVENT_TYPE:16)
	extz	wa
	ld	c, (SWBTWR_PAYLOAD_1:16)
	extz	bc
	ld	e, (SWBTWR_PAYLOAD_3:16)
	extz	de
	lda	xhl, (xsp+2)
	push	xhl
	call	DSPCfg_RecordFieldToParamId
	cp	hl, 0:i3
	jrl	lt, EffEdit_DSPConfigBlock_Epilogue
	ld	a, (ACTIVE_TITLE:16)
	cp	a, 214
	jrl	z, EffEdit_DSPConfigBlock_Skip4
	cp	a, 14
	jrl	z, EffEdit_DSPConfigBlock_Skip3
	cp	a, 12
	jrl	z, EffEdit_DSPConfigBlock_Skip2
	cp	a, 11
	jrl	z, EffEdit_DSPConfigBlock_Skip
	cp	a, 10
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4b00
	jrl	c, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4b47
	jrl	nc, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4b00
	jr	nz, EffEdit_DSPConfigBlock_Skip5
	calr	EffEdit_ValidateAndReadParams
	cp	hl, 0:i3
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (10610:16)
	ld	xbc, EVT_RET_EFF_FIX
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(58252:16), 1
	jrl	nz, EffEdit_DSPConfigBlock_Join
	ld	iz, 0:i3
	jr	EffEdit_DSPConfigBlock_Join3
EffEdit_DSPConfigBlock_Loop:
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4b10
	call	DSPCfg_ReadParam_Map1
	ld	bc, hl
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4b10
	call	DSPCfg_WriteParamFull
	inc	1, iz
EffEdit_DSPConfigBlock_Join3:
	cp iz, (10666:16)
	jrl	nc, EffEdit_DSPConfigBlock_Join
	cp	iz, 25
	jr	c, EffEdit_DSPConfigBlock_Loop
	jrl	EffEdit_DSPConfigBlock_Join
EffEdit_DSPConfigBlock_Skip5:
	ld	xwa, (xsp+2)
	sub	xwa, 0x4b10
	ld	iz, wa
	ld	xwa, (xsp+2)
	call	DSPCfg_ReadParam_Map0
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0x2978:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), hl
	ld	xwa, (0x2972:16)
	ld	de, iz
	extz	xde
	ld	xbc, EVT_RET_EFF_PARA
	jrl	EffEdit_DSPConfigBlock_Join2
EffEdit_DSPConfigBlock_Skip:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4900
	jrl	c, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4947
	jrl	nc, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4900
	jr	nz, EffEdit_DSPConfigBlock_Skip6
	calr	EffEdit_ValidateAndReadParams
	cp	hl, 0:i3
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_RET_EFF_FIX
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(58252:16), 1
	jrl	nz, EffEdit_DSPConfigBlock_Join
	ld	iz, 0:i3
	jr	EffEdit_DSPConfigBlock_Join4
EffEdit_DSPConfigBlock_Loop2:
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4910
	call	DSPCfg_ReadParam_Map1
	ld	bc, hl
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4910
	call	DSPCfg_WriteParamFull
	inc	1, iz
EffEdit_DSPConfigBlock_Join4:
	cp iz, (10666:16)
	jrl	nc, EffEdit_DSPConfigBlock_Join
	cp	iz, 25
	jr	c, EffEdit_DSPConfigBlock_Loop2
	jrl	EffEdit_DSPConfigBlock_Join
EffEdit_DSPConfigBlock_Skip6:
	ld	xwa, (xsp+2)
	sub	xwa, 0x4910
	ld	iz, wa
	ld	xwa, (xsp+2)
	call	DSPCfg_ReadParam_Map0
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0x2978:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), hl
	ld	xwa, (0x2972:16)
	ld	de, iz
	extz	xde
	ld	xbc, EVT_RET_EFF_PARA
	jrl	EffEdit_DSPConfigBlock_Join2
EffEdit_DSPConfigBlock_Skip2:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4c10
	jrl	c, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4c17
	jrl	ugt, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	sub	xwa, 0x4c10
	ld	iz, wa
	ld	xwa, (xsp+2)
	call	DSPCfg_ReadParam_Map0
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0x2978:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), hl
	ld	xwa, (0x2972:16)
	ld	de, iz
	extz	xde
	ld	xbc, EVT_RET_EFF_PARA
	jrl	EffEdit_DSPConfigBlock_Join2
EffEdit_DSPConfigBlock_Skip3:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4d00
	jr	nz, EffEdit_DSPConfigBlock_Skip7
	calr	EffEdit_ValidateAndReadParams
	cp	hl, 0:i3
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (10610:16)
	ld	xbc, EVT_RET_EFF_FIX
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(58252:16), 1
	jrl	nz, EffEdit_DSPConfigBlock_Join
	ld	xwa, 0x4d10
	call	DSPCfg_ReadParam_Map1
	ld	bc, hl
	ld	xwa, 0x4d10
	call	DSPCfg_WriteParamFull
	jr	EffEdit_DSPConfigBlock_Join
EffEdit_DSPConfigBlock_Skip7:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4d10
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	call	DSPCfg_ReadParam_Map0
	ld	(0x2978:16), hl
	ld	xwa, (10610:16)
	ld	xbc, EVT_RET_EFF_PARA
	ld	xde, 0:i3
	jrl	EffEdit_DSPConfigBlock_Join2
EffEdit_DSPConfigBlock_Skip4:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4e00
	jr	nz, EffEdit_DSPConfigBlock_Skip8
	calr	EffEdit_ValidateAndReadParams
	cp	hl, 0:i3
	jrl	nz, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (10610:16)
	ld	xbc, EVT_RET_EFF_FIX
	ld	xde, 0:i3
	call	ApDeliveryEvent
	cp	(58252:16), 1
	jr	nz, EffEdit_DSPConfigBlock_Join
	ld	iz, 0:i3
EffEdit_DSPConfigBlock_Loop3:
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4e10
	call	DSPCfg_ReadParam_Map1
	ld	bc, hl
	ld	wa, iz
	extz	xwa
	add	xwa, 0x4e10
	call	DSPCfg_WriteParamFull
	inc	1, iz
	cp	iz, 4:i3
	jr	c, EffEdit_DSPConfigBlock_Loop3
EffEdit_DSPConfigBlock_Join:
	ld	(0xe38c:16), 0
	jr	EffEdit_DSPConfigBlock_Epilogue
EffEdit_DSPConfigBlock_Skip8:
	ld	xwa, (xsp+2)
	cp	xwa, 0x4e10
	jr	c, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	cp	xwa, 0x4e13
	jr	ugt, EffEdit_DSPConfigBlock_Epilogue
	ld	xwa, (xsp+2)
	sub	xwa, 0x4e10
	ld	iz, wa
	ld	xwa, (xsp+2)
	call	DSPCfg_ReadParam_Map0
	ld	wa, iz
	add	wa, wa
	lda	xbc, (0x2978:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), hl
	ld	xwa, (0x2972:16)
	ld	de, iz
	extz	xde
	ld	xbc, EVT_RET_EFF_PARA
EffEdit_DSPConfigBlock_Join2:
	call	ApDeliveryEvent
EffEdit_DSPConfigBlock_Epilogue:
	popw	iz
	inc	4, xsp
	ret

EffEdit_ValidateAndReadParams:
	pushw_erp 0xfa
	lda xde, (0x29ac:16)
	ld xwa, xde
	lda xbc, (0x2978:16)
	lda xde, (xde + 25)

EffEdit_ValidateLoop:
	ldw (xbc+), 0x0000
	ld (xwa+), 0x00
	cp xwa, xde
	jr c, EffEdit_ValidateLoop
	ld a, (ACTIVE_TITLE:16)
	cp a, 0xd6
	jrl z, EffEdit_ReadParamD6
	cp a, 0xe
	jrl z, EffEdit_ReadParamE
	cp a, 0xc
	jrl z, EffEdit_ReadParamC
	cp a, 0xb
	jrl z, EffEdit_ReadParamB
	cp a, 0xa
	jrl nz, EffEdit_ReturnError
	ld xwa, 0x4b00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7f
	ld (0x2976:16), hl
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ld (0x29aa:16), hl
	ldib_erp 0xfb, 0
	jr EffEdit_ReadParamA_Check

EffEdit_ReadParamA_Body:
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	lda xbc, (0x2978:16)
	ld	(xbc+wa), hl
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4b10
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (0x29ac:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1b_erp 0xfb

EffEdit_ReadParamA_Check:
	ldto_berp C, 0xfb
	extz bc
	ld wa, (0x29aa:16)
	cp bc, wa
	jr nc, EffEdit_ReadParamA_Fixup
	cp_erpb 0xfb, 0x19
	jr c, EffEdit_ReadParamA_Body

EffEdit_ReadParamA_Fixup:
	ld bc, wa
	lda xwa, (0x0029ab:24)
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cp a, 3:i3
	jr nz, EffEdit_ReturnZeroJmp
	ld (xbc), 0x0
	ld wa, (0x29aa:16)
	dec 1, wa
	ld (0x29aa:16), wa

EffEdit_ReturnZeroJmp:
	ld hl, 0:i3
	jrl EffEdit_PopAndReturn

EffEdit_ReadParamB:
	ld xwa, 0x4900
	call DSPCfg_ReadParam_Map0
	and hl, 0x7f
	ld (0x2976:16), hl
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ld (0x29aa:16), hl
	ldib_erp 0xfb, 0
	jr EffEdit_ReadParamB_Check

EffEdit_ReadParamB_Body:
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	lda xbc, (0x2978:16)
	ld	(xbc+wa), hl
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4910
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (0x29ac:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1b_erp 0xfb

EffEdit_ReadParamB_Check:
	ldto_berp C, 0xfb
	extz bc
	ld wa, (0x29aa:16)
	cp bc, wa
	jr nc, EffEdit_ReadParamB_Fixup
	cp_erpb 0xfb, 0x19
	jr c, EffEdit_ReadParamB_Body

EffEdit_ReadParamB_Fixup:
	ld de, wa
	lda xbc, (0x0029ab:24)
	extz xde
	add xde, xbc
	cp (xde), 0x55
	jrl nz, EffEdit_ReturnZeroJmp
	dec 1, wa
	ld (0x29aa:16), wa
	jrl EffEdit_ReturnZeroJmp

EffEdit_ReadParamC:
	ldib_erp 0xfb, 0

EffEdit_ReadParamC_Loop:
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4c10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	lda xbc, (0x2978:16)
	ld	(xbc+wa), hl
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr c, EffEdit_ReadParamC_Loop
	jrl EffEdit_ReturnZeroJmp

EffEdit_ReadParamE:
	ld xwa, 0x4d00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7f
	ld (0x2976:16), hl
	ld xwa, 0x4d10
	call DSPCfg_ReadParam_Map0
	ld (0x2978:16), hl
	jrl EffEdit_ReturnZeroJmp

EffEdit_ReadParamD6:
	ld xwa, 0x4e00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7f
	ld (0x2976:16), hl
	ldib_erp 0xfb, 0

EffEdit_ReadParamD6_Loop:
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4e10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xfb
	extz wa
	add wa, wa
	lda xbc, (0x2978:16)
	ld	(xbc+wa), hl
	ld xwa, 0:i3
	ldto_berp A, 0xfb
	add xwa, 0x4e10
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (0x29ac:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1b_erp 0xfb
	cpib_erp 0xfb, 4
	jr c, EffEdit_ReadParamD6_Loop
	jrl EffEdit_ReturnZeroJmp

EffEdit_ReturnError:
	ldw hl, 0xffff

EffEdit_PopAndReturn:
	popw_erp 0xfa
	ret

EffEdit_ValidateRangeDelta:
	dec 8, xsp
	push xiz
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	ld xwa, 0x4c10
	call DSPCfg_ReadParam_Map0
	ld (xsp + 4), hl
	ld xwa, 0x4c12
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	ld xwa, 0x4c14
	call DSPCfg_ReadParam_Map0
	ld iz, hl
	ld xwa, 0x4c16
	call DSPCfg_ReadParam_Map0
	ldto_werp BC, 0xfa
	sub bc, (xsp + 4)
	ld xwa, (xsp + 8)
	cp xwa, 0x4c10
	jr nz, EffEdit_RangeCheck4C12
	cpw (xsp + 6), 0x0
	jr le, EffEdit_WriteValidDelta
	cp bc, 1:i3
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheck4C12:
	ld de, iz
	subw_erp DE, 0xfa
	ld xwa, (xsp + 8)
	cp xwa, 0x4c12
	jr nz, EffEdit_RangeCheck4C14
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_RangeCheckDE
	cp bc, 1:i3
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheckDE:
	cp de, 1:i3
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheck4C14:
	sub hl, iz
	ld xwa, (xsp + 8)
	cp xwa, 0x4c14
	jr nz, EffEdit_RangeCheck4C16
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_RangeCheckHL
	cp de, 1:i3
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheckHL:
	cp hl, 1:i3
	jr le, EffEdit_PopIzSkip8Ret

EffEdit_WriteValidDelta:
	ld xwa, (xsp + 8)
	ld bc, (xsp + 6)
	call DSPCfg_WriteParamDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheck4C16:
	ld xwa, (xsp + 8)
	cp xwa, 0x4c16
	jr nz, EffEdit_WriteValidDelta
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_WriteValidDelta
	cp hl, 1:i3
	jr gt, EffEdit_WriteValidDelta

EffEdit_PopIzSkip8Ret:
	pop xiz
	inc 8, xsp
	ret

MimeSyori:
	cp xbc, EVT_SET_PARAM
	jr nz, MimeSyori_ReturnZero
	or xde, xde
	scc8 nz, a
	extz wa
	call AudioMode_ConfigureExternal

MimeSyori_ReturnZero:
	ld xhl, 0:i3
	ret

ApPlaySyori:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, EVT_SET_PUNCH
	jrl z, NoteEditSy_ModeScrollReturn
	cp xbc, EVT_SET_METRO
	jrl z, NoteEditSy_ModeScroll
	cp xbc, EVT_SET_CYCLE
	jrl z, SeqAccomp_StartHelper
	ld de, (9832:16)
	ld hl, (9506:16)
	ld iy, (9504:16)
	ld iz, (9502:16)
	ld wa, (9500:16)
	ldfr_werp WA, 0xea
	ld a, (0x283a:16)
	ldfr_berp A, 0xee
	ld a, (CURRENT_TITLE:16)
	ldfr_berp A, 0xef
	cp xbc, EVT_DEC_VAL
	jrl z, SeqAccomp_SubChain
	cp xbc, EVT_INC_VAL
	jrl z, SeqAccomp_ParamDelivery
	cp xbc, EVT_PAINT
	jrl nz, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	ld (0x2972:16), xwa
	ld c, (CURRENT_TITLE:16)
	cp c, 0x99
	jrl z, SeqAccomp_DispatchRhythmEvents
	cp c, 0x96
	jrl z, SeqAccomp_DispatchRhythmEvents
	ld xwa, (xsp + 2)
	cp c, 0x7a
	jr z, SeqAccomp_StartAndPostEvents
	cp c, 0x78
	jr z, SeqAccomp_StartAndPostEvents
	extz bc
	sub bc, 0x81
	cp bc, 0:i3
	jrl lt, AppEvent_ReturnZero
	cp bc, 7:i3
	jrl gt, AppEvent_ReturnZero
	add bc, bc
	lda xix, (ApPlaySyori_CaseTable:24)
	ld	bc, (xix+bc)
	lda xix, (SeqAccomp_EventDispatch:24)
	jp	t, (xix+bc)
; Sequencer accompaniment event dispatch
SeqAccomp_EventDispatch:
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	call	ApDeliveryEvent
	ldmm8	9010, 1075
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 1:i3
	call	ApDeliveryEvent
	ld	a, (0x28b1:16)
	and	a, 1
	cp	a, 0:i3
	scc16	nz, iz
	ld	wa, iz
	exts	xwa
	jrl	SeqAccomp_SendVoiceAndReturn

SeqAccomp_StartAndPostEvents:
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jrl SeqAccomp_StartHandler
ApPlaySyori_Case133:
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	ld (7528:16), l
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	bit 1, (0x28b1:16)
	jr z, SeqPlay_AllocHideIndicator
	ld iz, 1:i3
	ld xwa, 0x850014
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0x850013
	ld xbc, EVT_SET_VISIBLE
	ld xde, 1:i3
	jr SeqPlay_AllocPostEvent

SeqPlay_AllocHideIndicator:
	ld iz, 0:i3
	ld xwa, 0x850014
	ld bc, 0:i3
	call SetVisible
	ld xwa, 0x850013
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3

SeqPlay_AllocPostEvent:
	call ApPostEvent
	ld wa, iz
	exts xwa
	calr AppEvent_SendPlayStatus
	ld a, (0x28b2:16)
	and a, 0x1
	cp a, 0:i3
	scc16 nz, iz
	ld wa, iz
	exts xwa
	jrl NoteEdit_ScrollCallReset
ApPlaySyori_Case135:
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	ld (7528:16), l
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ld a, (0x28b2:16)
	and a, 0x1
	cp a, 0:i3
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x87000d
	ld xbc, EVT_SET_PARAM
	call ApDeliveryEvent
	ld wa, 0:i3
	jrl NoteEdit_ReturnSendToggle
ApPlaySyori_Case136:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqAcc_SendParamsAndStart
	ld bc, (9832:16)
	ld (9964:16), bc
	ld bc, (9832:16)
	ld wa, bc
	extz xwa
	bit 15, wa
	jr nz, SeqAcc_SendParamsAndStart
	ld wa, (0xf238:16)
	cp bc, wa
	jr ule, SeqPlay_AllocAdjustBar
	sub wa, (0xf23f:16)
	ld (9832:16), wa
	ld (9964:16), wa
	jr SeqAcc_SendParamsAndStart

SeqPlay_AllocAdjustBar:
	dec 1, wa
	ld (0x28c3:16), wa
	call SeqAcc_UpdateEndPosition
	ld wa, (0xf238:16)
	sub wa, (0xf23f:16)
	ld (9832:16), wa
	ld (9964:16), wa

SeqAcc_SendParamsAndStart:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 7:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x9
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xa
	call ApDeliveryEvent
	ld a, (0x28b2:16)
	and a, 0x1
	cp a, 0:i3
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x880004
	ld xbc, EVT_SET_PARAM
	jrl SeqAccomp_StartHandler
ApPlaySyori_Case134:
	ld a, (0x28b2:16)
	and a, 0x1
	cp a, 0:i3
	scc16 nz, iz
	ld wa, iz
	exts xwa
	calr AppEvent_SendAccompStatus
ApPlaySyori_Case130:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 4:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 5:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 6:i3
	jrl SeqAccomp_StartHandler

SeqAccomp_DispatchRhythmEvents:
	call BmDrEdit_EnterPlayMode
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 5:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 6:i3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xb
	jrl SeqAccomp_StartHandler

; SeqAccomp parameter delivery
SeqAccomp_ParamDelivery:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, SeqAccomp_ParamDelivery_CaseTable
	ld wa, (xwa)
	lda xix, (SeqAccomp_SubHandlerA:24)
	jp	t, (xix+wa)

; Sequencer accompaniment sub-handler A
SeqAccomp_SubHandlerA:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	ld	wa, de
	cp	de, 999
	jrl	nc, AppEvent_ReturnZero
	inc	1, wa
	ld	(9832:16), wa
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jrl	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_ParamDelivery_Case4:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	ldto_berp	a, 239
	cp_erpb	239, 130
	jr	nz, ApPlaySyori_Skip13
	ld	a, (0x28b1:16)
	bit	0, a
	jrl	nz, AppEvent_ReturnZero
	set	0, a
	stb_d8	(10417), a
	jr	ApPlaySyori_Join9
ApPlaySyori_Skip13:
	cp	a, 134
	jr	nz, ApPlaySyori_Join9
	bit	2, (10418:16)
	jrl	nz, AppEvent_ReturnZero
	bit	1, (10417:16)
	jrl	nz, AppEvent_ReturnZero
	call	SeqVoice_ScanAndAssignParts
	set	1, (10417:16)
	ldmm16	9832, 9504
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 3:i3
	call	ApDeliveryEvent
ApPlaySyori_Join9:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 4:i3
	jrl	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_ParamDelivery_Case5:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	cp	(CURRENT_TITLE:16), 134
	jr	nz, ApPlaySyori_Skip2
	ld	wa, iy
	cp	iy, 999
	jrl	nc, AppEvent_ReturnZero
	inc	1, wa
	ld	(9504:16), wa
	ld	(9832:16), wa
	cp wa, (9506:16)
	jr	ule, ApPlaySyori_Skip
	ldmm16	9506, 9504
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 6:i3
	jr	ApPlaySyori_Join
ApPlaySyori_Skip2:
	ld wa, qde
	cpw	qde, 999
	jrl	nc, AppEvent_ReturnZero
	inc	1, wa
	ld	(9500:16), wa
	ld	(9832:16), wa
	cp wa, (9502:16)
	jr	ule, ApPlaySyori_Skip
	ldmm16	9502, 9500
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 6:i3
ApPlaySyori_Join:
	call	ApDeliveryEvent
ApPlaySyori_Skip:
	calr	NoteEditSy_SendModeScrollReset
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 5:i3
	jrl	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_ParamDelivery_Case6:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	cp	(CURRENT_TITLE:16), 134
	jr	nz, ApPlaySyori_Skip3
	ld	wa, hl
	cp	hl, 999
	jrl	nc, AppEvent_ReturnZero
	inc	1, wa
	ld	(9506:16), wa
	ldmm16	9832, 9504
	jr	ApPlaySyori_Join2
ApPlaySyori_Skip3:
	ld	wa, iz
	cp	iz, 999
	jrl	nc, AppEvent_ReturnZero
	inc	1, wa
	ld	(9502:16), wa
	ldmm16	9832, 9500
ApPlaySyori_Join2:
	calr	NoteEditSy_SendModeScrollReset
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 6:i3
	jrl	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_ParamDelivery_Case8:	; cases 8, 9, 10
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	ld	xwa, (xsp+2)
	cp	xwa, 10
	jr	z, ApPlaySyori_Skip5
	cp	xwa, 9
	jr	z, ApPlaySyori_Skip4
	cp	xwa, 8
	jr	nz, ApPlaySyori_Join3
	call	SeqPlay_DataBlock_BBE
	jr	ApPlaySyori_Join3
ApPlaySyori_Skip4:
	call	SeqAccomp_SubHandlerA_Helper
	jr	ApPlaySyori_Join3
ApPlaySyori_Skip5:
	call	SeqAccomp_SubHandlerA_Helper2
ApPlaySyori_Join3:
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 7:i3
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 8
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 9
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 10
	jrl	SeqAccomp_StartHandler
SeqAccomp_ParamDelivery_Case11:
	cpib_erp 238, 1
	jrl	z, AppEvent_ReturnZero
	ld	(0x283a:16), 1
	ldmm16	61854, 10595
	call	Audio_CheckSubsystemReady
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 11
	call	ApDeliveryEvent
	ldmm16	10296, 61854
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	z, ApPlaySyori_Skip12
	jrl	AppEvent_ReturnZero

; SeqAccomp sub-handler chain
SeqAccomp_SubChain:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, SeqAccomp_SubChain_CaseTable
	ld wa, (xwa)
	lda xix, (SeqAccomp_SubHandlerB:24)
	jp	t, (xix+wa)

; Sequencer accompaniment sub-handler B
SeqAccomp_SubHandlerB:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	ld	wa, de
	cp	de, 1:i3
	jrl	ule, SeqAccomp_InitAndReturn
	dec	1, wa
	ld	(9832:16), wa
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 0:i3
	jrl	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_SubChain_Case4:
	ldto_berp c, 239
	ld	a, (0x28b1:16)
	cp_erpb 239, 130
	jr nz, ApPlaySyori_Skip7
	ld c, a
	bit	0, a
	jrl	z, AppEvent_ReturnZero
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jr	z, ApPlaySyori_Skip6
	calr	SeqAccomp_ReassignVoiceState
	jr	ApPlaySyori_Join5
ApPlaySyori_Skip6:
	res	0, c
	ld	(0x28b1:16), c
	jr	ApPlaySyori_Join4
ApPlaySyori_Skip7:
	cp	c, 134
	jr	nz, ApPlaySyori_Join5
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	bit	2, (10418:16)
	jrl	nz, AppEvent_ReturnZero
	ld	c, a
	bit	1, a
	jrl	z, AppEvent_ReturnZero
	res	1, c
	ld	(0x28b1:16), c
	ldw	(9832:16), 1
	calr	NoteEditSy_SendModeScrollReset
	ld	wa, (0x28a8:16)
	ld	bc, (0xf19e:16)
	cpl	wa
	and	bc, wa
	ld	(0xf19e:16), bc
	call	Audio_CheckSubsystemReady
ApPlaySyori_Join4:
	call	SeqPlay_InitStartState
ApPlaySyori_Join5:
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 4:i3
	jrl	SeqAccomp_StartHandler
SeqAccomp_SubChain_Case5:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	cp	(CURRENT_TITLE:16), 134
	jr	nz, ApPlaySyori_Skip8
	ld	wa, iy
	cp	iy, 1:i3
	jrl	ule, AppEvent_ReturnZero
	dec	1, wa
	ld	(9504:16), wa
	ld	(9832:16), wa
	jr	ApPlaySyori_Join6
ApPlaySyori_Skip8:
	ld	wa, qde
	cp	qde, 1
	jrl	ule, AppEvent_ReturnZero
	dec	1, wa
	ld	(9500:16), wa
	ld	(9832:16), wa
ApPlaySyori_Join6:
	calr	NoteEditSy_SendModeScrollReset
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 5:i3
	jr	SeqAccomp_SubHandlerB_Code_Join
SeqAccomp_SubChain_Case6:
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	cp	(CURRENT_TITLE:16), 134
	jr	nz, ApPlaySyori_Skip9
	ld	wa, hl
	cp	hl, 1:i3
	jrl	ule, AppEvent_ReturnZero
	dec	1, wa
	ld	(9506:16), wa
	cp (9504:16), wa
	jr	ule, SeqAccomp_SubHandlerB_Code_Entry
	ldmm16	9504, 9506
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 5:i3
	call	ApDeliveryEvent
SeqAccomp_SubHandlerB_Code_Entry:
	ldmm16	9832, 9504
	jr	ApPlaySyori_Join7
ApPlaySyori_Skip9:
	ld	wa, iz
	cp	iz, 1:i3
	jrl	ule, AppEvent_ReturnZero
	dec	1, wa
	ld	(9502:16), wa
	cp (9500:16), wa
	jr	ule, SeqAccomp_SubHandlerB_Code_Entry2
	ldmm16	9500, 9502
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 5:i3
	call	ApDeliveryEvent
SeqAccomp_SubHandlerB_Code_Entry2:
	ldmm16	9832, 9500
ApPlaySyori_Join7:
	calr	NoteEditSy_SendModeScrollReset
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 6:i3
SeqAccomp_SubHandlerB_Code_Join:
	call	ApDeliveryEvent
	jrl	SeqAccomp_InitAndReturn
SeqAccomp_SubChain_Case8:	; cases 8, 9, 10
	bit	2, (SEQ_TRANSPORT_STATE:16)
	jrl	nz, AppEvent_ReturnZero
	ld	xwa, (xsp+2)
	cp	xwa, 10
	jr	z, ApPlaySyori_Skip11
	cp	xwa, 9
	jr	z, ApPlaySyori_Skip10
	cp	xwa, 8
	jr	nz, ApPlaySyori_Join8
	call	SeqAccomp_SubHandlerB_Helper
	jr	ApPlaySyori_Join8
ApPlaySyori_Skip10:
	call	SeqAccomp_SubHandlerB_Helper2
	jr	ApPlaySyori_Join8
ApPlaySyori_Skip11:
	call	SeqAccomp_SubHandlerB_Helper3
ApPlaySyori_Join8:
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 7:i3
	call	ApDeliveryEvent
	ld	xwa, (10610:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 8
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 9
	call	ApDeliveryEvent
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_PARA_DRAW
	ld	xde, 10

SeqAccomp_StartHandler:
	call ApDeliveryEvent
	jrl AppEvent_ReturnZero
SeqAccomp_SubChain_Case11:
	cpib_erp 0xee, 0
	jrl z, AppEvent_ReturnZero
	ld (0x283a:16), 0
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	call Audio_CheckSubsystemReady
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xb
	call ApDeliveryEvent
	ldmm16 0x2838, 0xf19e
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jrl nz, AppEvent_ReturnZero
ApPlaySyori_Skip12:
	call SeqPlay_AllocBuffersAndInit
	jrl AppEvent_ReturnZero

; SeqAccomp start helper
SeqAccomp_StartHelper:
	cp (CURRENT_TITLE:16), 133
	jrl nz, SeqAccomp_HandleOtherState
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqAccomp_TogglePlayback
	bit 2, (0x28b2:16)
	jr z, SeqAccomp_HandleStartStop

SeqAccomp_TogglePlayback:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, SeqAccomp_ToggleSetZero
	ld xwa, 1:i3
	ld (xsp + 2), xwa
	jr SeqAccomp_ToggleSendStatus

SeqAccomp_ToggleSetZero:
	ld xwa, 0:i3
	ld (xsp + 2), xwa

SeqAccomp_ToggleSendStatus:
	ld xwa, (xsp + 2)
	calr AppEvent_SendPlayStatus
	jrl AppEvent_ReturnZero

SeqAccomp_HandleStartStop:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, SeqAccomp_ActivateAndAssign
	res 1, (0x28b1:16)
	ldw (9832:16), 1
	ld wa, (0x28a8:16)
	ld bc, (0xf19e:16)
	cpl wa
	and bc, wa
	ld (0xf19e:16), bc
	call Audio_CheckSubsystemReady
	ld xwa, 0x850014
	ld bc, 0:i3
	call SetVisible
	ld xwa, 0x850013
	ld xbc, EVT_SET_VISIBLE
	ld xde, 0:i3
	call ApDeliveryEvent
	jrl SeqAccomp_InitAndReturn

SeqAccomp_ActivateAndAssign:
	call SeqVoice_ScanAndAssignParts
	set 1, (0x28b1:16)
	ld wa, (9504:16)
	ld (9832:16), wa
	ldw wa, 0x86
	jr SeqAccomp_PostModeAndInit

SeqAccomp_HandleOtherState:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, SeqAccomp_OtherActivate
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqAccomp_OtherClearBit
	calr SeqAccomp_ReassignVoiceState
	cp hl, 0:i3
	jrl z, AppEvent_ReturnZero
	ld xwa, 1:i3
	jr SeqAccomp_SendVoiceAndReturn

SeqAccomp_OtherClearBit:
	res 0, (0x28b1:16)
	jrl SeqAccomp_InitAndReturn

SeqAccomp_OtherActivate:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr z, SeqAccomp_OtherSetBit
	ld xwa, 0:i3

SeqAccomp_SendVoiceAndReturn:
	calr AppEvent_SendVoiceUpdate
	jrl AppEvent_ReturnZero

SeqAccomp_OtherSetBit:
	set 0, (0x28b1:16)
	ldw wa, 0x82

SeqAccomp_PostModeAndInit:
	call UI_PostModeChangeEvent
	jr SeqAccomp_InitAndReturn

; NoteEditSy mode scroll dispatch
NoteEditSy_ModeScroll:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, NoteEdit_ScrollToggle
	ld c, (0x28b2:16)
	bit 2, c
	jr z, NoteEdit_ScrollInactive

NoteEdit_ScrollToggle:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, NoteEdit_ScrollSetZero
	ld xwa, 1:i3
	ld (xsp + 2), xwa
	jr NoteEdit_ScrollDispatchMode

NoteEdit_ScrollSetZero:
	ld xwa, 0:i3
	ld (xsp + 2), xwa

NoteEdit_ScrollDispatchMode:
	ld a, (ACTIVE_TITLE:16)
	cp a, 0x85
	jr nz, NoteEdit_ScrollCheck86
	ld xwa, (xsp + 2)

NoteEdit_ScrollCallReset:
	calr NoteEditSy_ScrollReset
	jr AppEvent_ReturnZero

NoteEdit_ScrollCheck86:
	cp a, 0x86
	jr nz, NoteEdit_ScrollCheck87
	ld xwa, (xsp + 2)
	calr AppEvent_SendAccompStatus
	jr AppEvent_ReturnZero

NoteEdit_ScrollCheck87:
	cp a, 0x87
	jr nz, NoteEdit_ScrollCheck88
	ld xwa, (xsp + 2)
	calr NoteEditSy_ScrollCase1
	jr AppEvent_ReturnZero

NoteEdit_ScrollCheck88:
	cp a, 0x88
	jr nz, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	calr NoteEditSy_ScrollCase2
	jr AppEvent_ReturnZero

NoteEdit_ScrollInactive:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, NoteEdit_ScrollActivate
	res 0, c
	ld (0x28b2:16), c
	jr SeqAccomp_InitAndReturn

NoteEdit_ScrollActivate:
	set 0, c
	ld (0x28b2:16), c
	cp (ACTIVE_TITLE:16), 133
	jr nz, SeqAccomp_InitAndReturn
	ldw wa, 0xab
	call SoundCtrl_SendCommand

SeqAccomp_InitAndReturn:
	call SeqPlay_InitStartState
	jr AppEvent_ReturnZero

; NoteEditSy mode scroll return
NoteEditSy_ModeScrollReturn:
	call SeqPlay_CheckAndActivateParts
	cp hl, 0:i3
	jr z, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, NoteEdit_ReturnSetZero
	ld xwa, 1:i3
	ld (xsp + 2), xwa
	jr NoteEdit_ReturnGetParam

NoteEdit_ReturnSetZero:
	ld xwa, 0:i3
	ld (xsp + 2), xwa

NoteEdit_ReturnGetParam:
	ld xwa, (xsp + 2)
	extz wa

NoteEdit_ReturnSendToggle:
	calr AppEvent_SendModeToggle

AppEvent_ReturnZero:
	ld xhl, 0:i3
	popw iz
	inc 4, xsp
	ret

SeqAccomp_ReassignVoiceState:
	lda xsp, (xsp - 18)
	push xiz
	cp (7530:16), 0
	jr z, SeqAccomp_ReassignClearAndSetup
	ldw hl, 0xffff
	jrl SeqAccomp_ReassignEpilogue

SeqAccomp_ReassignClearAndSetup:
	res 0, (0x28b1:16)
	ld (8956:16), 3
	ld (7570:16), 0
	ld wa, (SEQ_ACTIVE_PARTS:16)
	ld (8982:16), wa
	ld a, (8988:16)
	cp a, 0xff
	jrl z, SeqAccomp_ReassignDone
	extz wa
	lda xhl, (xsp + 18)
	ld e, a
	dec 1, a
	extz wa
	ld (xsp + 4), wa
	sla wa, 2
	lda xix, (9184:16)
	lda	xbc, (xix+wa)
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xbc + 2)
	ld (xhl + 2), wa
	ld hl, (xhl)
	lda xbc, (xix + 76)
	ld (xbc), hl
	ld (xbc + 2), wa
	lda xbc, (xsp + 6)
	ldfr_berp E, 0xea
	ld xix, xbc
	ldib_erp 0xe2, 0

SeqAccomp_ReassignCopyLoop:
	ldto_berp E, 0xe2
	extz de
	inc 2, de
	ldto_berp A, 0xea
	dec 1, a
	extz wa
	sla wa, 3
	lda xhl, (9016:16)
	lda	xiy, (xhl+wa)
	ld iz, de
	extz xiz
	add xiz, xiy
	ldto_berp E, 0xe2
	extz de
	ld a, (xiz)
	ld	(xix+de), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccomp_ReassignCopyLoop
	ld xix, xbc
	ldib_erp 0xe2, 0

SeqAccomp_ReassignWriteLoop:
	ldto_berp A, 0xe2
	extz wa
	inc 2, wa
	lda xbc, (xhl+152:16)
	ld de, wa
	extz xde
	add xde, xbc
	ldto_berp A, 0xe2
	extz wa
	ld	a, (xix+wa)
	ld (xde), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccomp_ReassignWriteLoop
	lda xde, (xsp + 14)
	ld wa, (xsp + 4)
	sla wa, 3
	lda	xbc, (xhl+wa)
	ld wa, (xbc)
	ld (xde), wa
	ld a, (xbc + 3)
	ld (xde + 2), a
	ld wa, (xde)
	ld	(xhl+152), wa

SeqAccomp_ReassignDone:
	ld hl, 0:i3

SeqAccomp_ReassignEpilogue:
	pop xiz
	lda xsp, (xsp + 18)
	ret

AppEvent_SendModeToggle:
	cp a, 0:i3
	scc16 nz, de
	extz xde
	ld xwa, 0x87000e
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

AppEvent_SendVoiceUpdate:
	ld xde, xwa
	ld xwa, 0x810003
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

AppEvent_SendPlayStatus:
	ld xde, xwa
	ld xwa, 0x850004
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

; NoteEditSy scroll reset dispatch
NoteEditSy_ScrollReset:
	ld xde, xwa
	ld xwa, 0x850006
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

AppEvent_SendAccompStatus:
	ld xde, xwa
	ld xwa, 0x860007
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

; NoteEditSy scroll case 1
NoteEditSy_ScrollCase1:
	ld xde, xwa
	ld xwa, 0x87000d
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

; NoteEditSy scroll case 2
NoteEditSy_ScrollCase2:
	ld xde, xwa
	ld xwa, 0x880004
	ld xbc, EVT_SET_PARAM
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollReset:
	ld c, (ACTIVE_TITLE:16)
	ld xwa, (0x2972:16)
	cp c, 0x99
	jr z, NoteEditSy_ScrollCase4
	cp c, 0x96
	jr z, NoteEditSy_ScrollCase4
	cp c, 0x7a
	jr z, NoteEditSy_ScrollCase3
	cp c, 0x78
	jr z, NoteEditSy_ScrollCase3
	extz bc
	sub bc, 0x81
	cp bc, 0:i3
	ret lt
	cp bc, 7:i3
	ret gt
	add bc, bc
	lda xix, (NoteEditSy_SendModeScrollReset_CaseTable:24)
	ld	bc, (xix+bc)
	lda xix, (NoteEditSy_ModeDispatch:24)
	jp	t, (xix+bc)

; Note editor mode dispatch
NoteEditSy_ModeDispatch:
	ld xwa, 0x810005
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr NoteEditSy_DeliverEvent

NoteEditSy_Dispatch85:
	ld xwa, 0x850007
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr NoteEditSy_DeliverEvent

NoteEditSy_Dispatch87:
	ld xwa, 0x870003
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr NoteEditSy_DeliverEvent

; NoteEditSy scroll case 3
NoteEditSy_ScrollCase3:
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr NoteEditSy_DeliverEvent

; NoteEditSy scroll case 4
NoteEditSy_ScrollCase4:
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3
	jr NoteEditSy_DeliverEvent

NoteEditSy_DeliverParam7:
	ld xbc, EVT_PARA_DRAW
	ld xde, 7:i3

NoteEditSy_DeliverEvent:
	call ApDeliveryEvent

NoteEditSy_DeliverReturn:
	ret

SeqMode_SendStatusUpdate:
	ld a, (ACTIVE_TITLE:16)
	cp a, 0x87
	jr z, SeqMode_Status87
	cp a, 0x85
	jr z, SeqMode_Status85
	cp a, 0x81
	ret nz
	ld xwa, 0x810005
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jr SeqMode_StatusDeliver

SeqMode_Status85:
	ld xwa, 0x850007
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jr SeqMode_StatusDeliver

SeqMode_Status87:
	ld xwa, 0x870003
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3

SeqMode_StatusDeliver:
	call ApDeliveryEvent
	ret

SeqAccomp_SendStopNotify:
	ld a, (ACTIVE_TITLE:16)
	cp a, 0x85
	jr z, SeqAccomp_StopNotifyDeliver
	cp a, 0x87
	ret nz

SeqAccomp_StopNotifyDeliver:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	call ApDeliveryEvent
	ret

SngSelSyori:
	pushw_erp 0xfa
	ld a, (0x00ffe3:24)
	ldfr_berp A, 0xfb
	cp xbc, EVT_INDEXSW_DOWN
	jr z, SngSel_HandleNextSong
	cp xbc, EVT_INDEXSW_UP
	jr z, SngSel_HandlePrevSong
	cp xbc, EVT_PAINT
	jr nz, SeqAcc_CheckLoopAndSendEvent
	ld (0x29c6:16), xde
	ld xwa, xde
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	jr SeqAcc_CheckLoopAndSendEvent

SngSel_HandlePrevSong:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqAcc_CheckLoopAndSendEvent
	cp_erpb 0xfb, 0x09
	jr nc, SeqAcc_CheckLoopAndSendEvent
	ldto_berp A, 0xfb
	ld (7500:16), a
	ld a, (0x00ffe3:24)
	inc 1, a
	ld (7502:16), a
	call SetWall_LoadToneGenData
	cp (ACTIVE_TITLE:16), 129
	jr nz, SeqAcc_ResetAndReinit
	calr SeqVoice_DispatchAllEvents
	ld xwa, 0:i3
	jr SngSel_SendVoiceUpdate

SngSel_HandleNextSong:
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqAcc_CheckLoopAndSendEvent
	cpib_erp 0xfb, 0
	jr z, SeqAcc_CheckLoopAndSendEvent
	ldto_berp A, 0xfb
	ld (7500:16), a
	ld a, (0x00ffe3:24)
	dec 1, a
	ld (7502:16), a
	call SetWall_LoadToneGenData
	cp (ACTIVE_TITLE:16), 129
	jr nz, SeqAcc_ResetAndReinit
	calr SeqVoice_DispatchAllEvents
	ld xwa, 0:i3

SngSel_SendVoiceUpdate:
	calr AppEvent_SendVoiceUpdate

SeqAcc_ResetAndReinit:
	res 0, (0x28b1:16)
	res 3, (0x28a7:16)
	call SeqAcc_InitPlaybackState

SeqAcc_CheckLoopAndSendEvent:
	ld a, (0x00ffe3:24)
	cpb_erp A, 0xfb
	jr z, NoteEditSy_UpScrollTable
	ld xwa, (0x29c6:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent

; NoteEditSy up-scroll table
NoteEditSy_UpScrollTable:
	ld xhl, 0:i3
	popw_erp 0xfa
	ret

SoundCtrl_SaveAndSendCmd_EE:
	ld (GLOBAL_ERROR_CODE:16), a
	ldw wa, 0xee
	jp SoundCtrl_SendCommand

SoundCtrl_SendCmd_EE:
	ldw wa, 0xee
	jp SoundCtrl_SendCommand

NoteEditSyori:
	cp xbc, EVT_INDEXSW_DOWN
	jrl z, NoteEditSy_HandleDownScroll
	cp xbc, EVT_INDEXSW_UP
	jr z, NoteEditSy_HandleUpScroll
	cp xbc, EVT_PAINT
	jrl nz, NoteEditSy_ReturnZero
	ld (0x2972:16), xde
	bit 0, (0x2742:16)
	jr z, NoteEditSy_InitPlayMode
	call BmDrEdit_InitDrumMode
	jr NoteEditSy_InitCommon

NoteEditSy_InitPlayMode:
	call BmDrEdit_InitMelodicMode

NoteEditSy_InitCommon:
	call NoteEdit_SendScrollCmds
	calr NoteEditSy_UpdateGridPosition
	calr NoteEditSy_SendModeWidgetCmd
	calr NoteEditSy_UpdateChordDisplay
	bit 0, (0x2742:16)
	call z, (NoteEditSy_UpdateEditModeGrid:24)
	calr NoteEditSy_UpdateNoteDisplay
	bit 0, (0x295f:16)
	jrl z, NoteEditSy_ReturnZero
	call BmDrEdit_PrepareSecondaryNoteDisplay
	jrl NoteEditSy_ReturnZero

NoteEditSy_HandleUpScroll:
	cp xde, 0xe
	jrl ugt, NoteEditSy_ReturnZero
	add xde, xde
	add xde, NoteEditSy_HandleUpScroll_CaseTable
	ld de, (xde)
	lda xix, (NoteEditSy_UpScroll_Param0:24)
	jp	t, (xix+de)

NoteEditSy_UpScroll_Param0:
	call BmDrEdit_CheckScrollBusy
	jrl NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param1:
	call BmDrEdit_PitchScrollUp_Check
	jrl NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param2:
	call BmDrEdit_VelocityUp_Check
	jrl NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param3:
	call BmDrEdit_GateOrVelocityUp
	jrl NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param4:
	call BmDrEdit_DurationUp_Check
	jrl NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param5:
	call BmDrEdit_ModeScrollUp
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param6:
	call BmDrEdit_AdjustViewAndInsert
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param7:
	call BmDrEdit_ChordScrollUp_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param8:
	call BmDrEdit_DeleteNoteAtCursor
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param9:
	call BmDrEdit_DrumVoiceDown_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param10:
	call BmDrEdit_InsertNoteEvent
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param11:
	call BmDrEdit_PostModeChange96
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param12:
	call BmDrEdit_PostModeChange99
	jr NoteEditSy_ReturnZero

NoteEditSy_HandleDownScroll:
	cp xde, 0xb
	jr ugt, NoteEditSy_ReturnZero
	add xde, xde
	add xde, NoteEditSy_HandleDownScroll_CaseTable
	ld de, (xde)
	lda xix, (NoteEditSy_DownScroll_Param0:24)
	jp	t, (xix+de)

NoteEditSy_DownScroll_Param0:
	call BmDrEdit_CheckScrollBusyAlt
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param1:
	call BmDrEdit_PitchScrollDown_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param2:
	call BmDrEdit_VelocityDown_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param3:
	call BmDrEdit_GateOrVelocityDown
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param4:
	call BmDrEdit_DurationDown_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param5:
	call BmDrEdit_ModeScrollDown
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param6:
	call BmDrEdit_NavigateBackwardWithEdit
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param7:
	call BmDrEdit_ChordScrollDown_Check
	jr NoteEditSy_ReturnZero
NoteEditSy_HandleDownScroll_Case11:
	call BmDrEdit_DrumVoiceUp_Check

NoteEditSy_ReturnZero:
	ld xhl, 0:i3
	ret

NoteEditSy_SendScrollCmd0:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd1:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 1:i3
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd2:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 2:i3
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd0:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0:i3
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd1:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 1:i3
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd2:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 2:i3
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd3or4:
	ld xde, 3:i3
	bit 0, (0x2742:16)
	jr z, NoteEditSy_SendWidgetCmdDispatch
	ld xde, 4:i3

NoteEditSy_SendWidgetCmdDispatch:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	jp ApDeliveryEvent

NoteEditSy_UpdateGridPosition:
	dec 4, xsp
	push xiz
	ld bc, (0x279a:16)
	srl bc, 2
	ld wa, bc
	ld (0x27b6:16), bc
	bit 0, (0x2742:16)
	jr z, NoteEditSy_GridPosPlayOffset
	add wa, 0x53
	jr NoteEditSy_GridPosStore

NoteEditSy_GridPosPlayOffset:
	add wa, 0xf

NoteEditSy_GridPosStore:
	ld (0x27b6:16), wa
	ld wa, (0x28af:16)
	ldfr_werp WA, 0xfa
	ld iz, (9830:16)
	ldmw2 (xsp + 4), 0x275e
	ldmi16 (xsp + 6), 0x2760
	call BmDrEdit_LoadAlternateAndCountNotes
	ldto_werp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz
	mrdw5 0x9f, 0x04, 0x19, 0x5e, 0x27
	mrdb5 0x8f, 0x06, 0x19, 0x60, 0x27
	ld c, (0x2774:16)
	extz bc
	ld wa, (0x2772:16)
	cp wa, bc
	jr ugt, NoteEditSy_GridPosOutOfRange
	mul wa, 0x18
	bit 0, (0x2742:16)
	jr z, NoteEditSy_GridPosEdit
	add wa, 0x53
	ld (0x27b4:16), wa
	jr NoteEditSy_GridPosFinish

NoteEditSy_GridPosEdit:
	add wa, 0xf
	ld (0x27b4:16), wa
	jr NoteEditSy_GridPosFinish

NoteEditSy_GridPosOutOfRange:
	ldw (0x27b4:16), 0

NoteEditSy_GridPosFinish:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 5:i3
	call ApDeliveryEvent
	pop xiz
	inc 4, xsp
	ret

NoteEditSy_UpdateEditModeGrid:
	bit 0, (0x2742:16)
	ret nz
	ld wa, (0x279a:16)
	srl wa, 2
	add wa, 0x16
	ld (0x27b8:16), wa
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 7:i3
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollCmd:
	ld xwa, (0x2972:16)
	bit 0, (0x2742:16)
	jr z, NoteEditSy_SendScrollCmdEdit
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x9
	jr NoteEditSy_JumpFA9E07

NoteEditSy_SendScrollCmdEdit:
	ld xbc, EVT_PARA_DRAW
	ld xde, 6:i3

NoteEditSy_JumpFA9E07:
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd3:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 3:i3
	jp ApDeliveryEvent

NoteEditSy_SendVelocityCmd:
	ldmm8 0x296a, 0x278a
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xa
	jp ApDeliveryEvent

NoteEditSy_SendGateCmd:
	ldmm8 0x296a, 0x2788
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 4:i3
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd5:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 5:i3
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd8:
	ld xwa, (0x2972:16)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x8
	jp ApDeliveryEvent

NoteEditSy_SendModeWidgetCmd:
	ld xwa, (0x2972:16)
	bit 0, (0x2742:16)
	jr z, NoteEditSy_WidgetCmdEdit
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0xd
	jr NoteEditSy_JumpFA9E07_2

NoteEditSy_WidgetCmdEdit:
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0x8

NoteEditSy_JumpFA9E07_2:
	jp ApDeliveryEvent

NoteEditSy_UpdateNoteDisplay:
	dec 4, xsp
	ldmm16 0x27fe, 0x276a
	ld a, (0x276c:16)
	extz wa
	ld (0x2800:16), wa
	ldmm16 0x2802, 0x276e
	ld a, (0x2770:16)
	extz wa
	ld (0x2804:16), wa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call BmDrEdit_SetupScrollRegion
	mrdb5 0x8f, 0x02, 0x19, 0x22, 0x28
	mrib4 0x87, 0x19, 0x24, 0x28
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0x9
	call ApDeliveryEvent
	inc 4, xsp
	ret

NoteEditSy_SendWidgetCmdC:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0xc
	jp ApDeliveryEvent
NoteEditSy_DisplayUpdateData:
	dec	4, xsp
	ldmm16	10238, 10090
	ldb_d8	a, (10092)
	extz	wa
	ld	(0x2800:16), wa
	ldmm16	10242, 10094
	ld	a, (0x2770:16)
	extz	wa
	ld	(0x2804:16), wa
	lda	xwa, (xsp+2)
	lda	xbc, (xsp)
	call	BmDrEdit_SetupScrollRegion
	ld	(10274), (xsp+2)
	ld	(10276), (xsp)
	ld	xwa, (0x2972:16)
	ld	xbc, EVT_GRAPH_DRAW
	ld	xde, 10
	call	ApDeliveryEvent
	inc	4, xsp
	ret

NoteEditSy_UpdateChordDisplay:
	bit 0, (0x2742:16)
	jr z, NoteEditSy_ChordDisplayEdit
	call BmDrEdit_CalcTrackPosition
	jp BmDrEdit_SendWidgetCmd

NoteEditSy_ChordDisplayEdit:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0xb
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmdE:
	ld xwa, (0x2972:16)
	ld xbc, EVT_GRAPH_DRAW
	ld xde, 0xe
	jp ApDeliveryEvent

SeqModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SeqErecMode_ReturnZero
	cp xde, 0x1
	jr z, SeqErec_ClearPlayFlags
	or xde, xde
	jr nz, SeqErecMode_ReturnZero
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	res 5, (0x28b3:16)
	calr SeqIndicator_HideBoth
	jr SeqErecMode_ReturnZero

SeqErec_ClearPlayFlags:
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	res 2, (0x28a7:16)
	res 0, (9834:16)
	res 4, (DEMO_CONTROL_FLAGS:16)

SeqErecMode_ReturnZero:
	ld xhl, 0:i3
	ret

SeqErecModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SeqErecFunc_ReturnZero
	cp xde, 0x1
	jr z, SeqErecFunc_SetIndicator
	or xde, xde
	jr nz, SeqErecFunc_ReturnZero
	ldw wa, 0x4c
	jr SeqErecFunc_CallSetIndicator

SeqErecFunc_SetIndicator:
	ldw wa, 0x4c

SeqErecFunc_CallSetIndicator:
	call CtrlPanel_SetIndicatorBit

SeqErecFunc_ReturnZero:
	ld xhl, 0:i3
	ret

SeqPlayModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SeqPlayMode_ReturnZero
	cp xde, 0x1
	jr z, SeqPlayMode_SaveAndCleanup
	or xde, xde
	jr nz, SeqPlayMode_ReturnZero
	call Accomp_UpdateModeFlag
	ld (0xe38e:16), 0
	res 0, (9834:16)
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SeqPlayMode_ReturnZero
	call AccWrap_PlayModeDispatch
	jr SeqPlayMode_ReturnZero

SeqPlayMode_SaveAndCleanup:
	call SeqPlay_SaveStateAndCleanup
	ld (0xe38e:16), 0

SeqPlayMode_ReturnZero:
	ld xhl, 0:i3
	ret

SeqRealModeFunc:
	pushw iz
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, SeqAcc_ProcessedReturn
	cp xde, 0x1
	jr z, SeqReal_HandleActivation
	or xde, xde
	jrl nz, SeqAcc_ProcessedReturn
	call AccWrap_PlayModeDispatch
	call Accomp_UpdateModeFlag
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	call SeqBuffer_ClearAndInitIteration
	ld (0x28be:16), 255
	bit 1, (0x28b1:16)
	jr nz, SeqReal_CopyBarFromSaved
	ldw (9832:16), 1
	jr SeqReal_InitStartState

SeqReal_CopyBarFromSaved:
	ldmm16 9832, 9504

SeqReal_InitStartState:
	call SeqPlay_InitStartState
	jrl SeqAcc_ProcessedReturn

SeqReal_HandleActivation:
	call PartSelect_UpdateDisplayState
	call SeqPlay_ProcessVoiceAndNotes
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	call SeqPlay_SaveStateAndCleanup
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	ld (9980:16), 0
	res 0, (9954:16)
	ld a, (0x28b1:16)
	bit 0, a
	jr z, SeqReal_CheckAccompBit
	call AccWrap_DispatchAndWaitSync
	ld wa, (9500:16)
	ld (9832:16), wa
	ld wa, (9500:16)
	call SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (SEQ_BEAT_COUNT:16), hl
	ld (SEQ_BEAT_TICK:16), 0
	ld wa, (9502:16)
	call SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl
	cpw (9832:16), 1
	jr nz, SeqReal_SetBarFlag
	res 3, (0x28a7:16)
	jr SeqAcc_SaveChannelAndReinit

SeqReal_SetBarFlag:
	set 3, (0x28a7:16)
	jr SeqAcc_SaveChannelAndReinit

SeqReal_CheckAccompBit:
	bit 1, a
	jr z, SeqAcc_ProcessedReturn
	res 3, (0x28a7:16)

SeqAcc_SaveChannelAndReinit:
	ld iz, (0xf19e:16)
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	call SeqAcc_InitPlaybackState
	ld (0xf19e:16), iz

SeqAcc_ProcessedReturn:
	ld xhl, 0:i3
	popw iz
	ret

SeqEditModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SeqEdit_ReturnZero
	cp xde, 0x1
	jr z, SeqEdit_RestoreAndClear
	or xde, xde
	jr nz, SeqEdit_ReturnZero
	call SeqAcc_SetIndicator_PB
	set 2, (0x28a7:16)
	jr SeqEdit_ReturnZero

SeqEdit_RestoreAndClear:
	call SeqAcc_RestorePlaybackState
	res 2, (0x28a7:16)

SeqEdit_ReturnZero:
	ld xhl, 0:i3
	ret

SqRealRecTitleFunc:
	pushw_erp 0xfa
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, SqRealRec_ReturnZero
	cp xde, 0x3
	jr z, SqRealRec_HandleExitState
	cp xde, 0x2
	jr nz, SqRealRec_ReturnZero
	cp (ACTIVE_TITLE_PREVIOUS:16), 131
	jr nz, SqRealRec_ReturnZero
	cp (9980:16), 1
	jr nz, SqRealRec_ReturnZero
	ld (9508:16), 1
	ldw (0x28a8:16), 0
	call Audio_CheckSubsystemReady
	ldib_erp 0xfb, 1

SqRealRec_SetBitMaskLoop:
	ldto_berp A, 0xfb
	extz wa
	ld bc, 1:i3
	call SeqVoice_SetOrClearBitMask
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr ule, SqRealRec_SetBitMaskLoop
	ld wa, 0:i3
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 5
	jr ugt, SqRealRec_DetectAndInit
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ldw de, 0xe
	call Part_WriteSubBlock32
	ldto_berp A, 0xfb
	dec 1, a
	ld (0x28be:16), a

SqRealRec_DetectAndInit:
	call Part_DetectSingleVoiceType
	call Audio_CheckSubsystemReady
	call SeqPlay_InitializePlayback
	ld (9508:16), 0
	jr SqRealRec_ReturnZero

SqRealRec_HandleExitState:
	cp (CURRENT_MODE:16), 10
	jr z, SqRealRec_ReturnZero
	res 0, (0x8d88:16)

SqRealRec_ReturnZero:
	ld xhl, 0:i3
	popw_erp 0xfa
	ret

SqPlayTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqPlay_ReturnZero
	cp xde, 0x3
	jr z, SqPlay_HandleExitState
	cp xde, 0x2
	jr nz, SqPlay_ReturnZero
	bit 0, (0x28b1:16)
	jr z, SqPlay_ReturnZero
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, SqPlay_ReturnZero
	cp (ACTIVE_TITLE_PREVIOUS:16), 130
	jr z, SqPlay_ReturnZero
	ldmm16 9832, 9500
	call SeqPlay_InitStartState
	ldmm16 0x2838, 0xf19e
	jr SqPlay_ReturnZero

SqPlay_HandleExitState:
	cp (CURRENT_MODE:16), 1
	jr z, SqPlay_ReturnZero
	res 0, (0x8d88:16)

SqPlay_ReturnZero:
	ld xhl, 0:i3
	ret

SqQtzTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqQtzTtl_ReturnZero
	cp xde, 0x3
	jr z, SqQtzTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqQtzTtl_ReturnZero
	cp (0xf1f1:16), 17
	jr nz, SqQtz_ClearBit4
	set 4, (9702:16)
	jr SqQtzTtl_ReturnZero

SqQtz_ClearBit4:
	res 4, (9702:16)

SqQtzTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqMdelTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqMdelTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMdelTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMdelTtl_ReturnZero
	cp (0xf1d6:16), 17
	jr nz, SqMdel_ClearBit0
	set 0, (9702:16)
	jr SqMdelTtl_ReturnZero

SqMdel_ClearBit0:
	res 0, (9702:16)

SqMdelTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqMersTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqMersTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMersTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMersTtl_ReturnZero
	cp (0xf1db:16), 17
	jr nz, SqMers_ClearBit1
	set 1, (9702:16)
	jr SqMersTtl_ReturnZero

SqMers_ClearBit1:
	res 1, (9702:16)

SqMersTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqVcngTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqVcngTtl_ReturnZero
	cp xde, 0x3
	jr z, SqVcngTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqVcngTtl_ReturnZero
	cp (0xf228:16), 17
	jr nz, SqVcng_ClearBit5
	set 5, (9702:16)
	jr SqVcngTtl_ReturnZero

SqVcng_ClearBit5:
	res 5, (9702:16)

SqVcngTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqTrnsTitleFunc:
	ld xhl, 0:i3
	ret

SqNcngTitleFunc:
	ld xhl, 0:i3
	ret

SqSoclTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqMcpy_ReturnZero
	cp xde, 0x3
	jr z, SqMcpy_ReturnZero
	cp xde, 0x2
	jr nz, SqMcpy_ReturnZero
	ldmm_sd24b 0xe3, 0xff, 0x00, 0x78, 0x28

SqMcpy_ReturnZero:
	ld xhl, 0:i3
	ret

SqMcpyTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqMcpyTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMcpy_HandleExitState
	cp xde, 0x2
	jr nz, SqMcpyTtl_ReturnZero
	cp (0xf1e9:16), 17
	jr nz, SqMcpy_ClearBit3
	set 3, (9702:16)
	jr SqMcpyTtl_ReturnZero

SqMcpy_ClearBit3:
	res 3, (9702:16)
	jr SqMcpyTtl_ReturnZero

SqMcpy_HandleExitState:
	ld wa, (0x2875:16)
	or (0xffec:24), wa

SqMcpyTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqMinsTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqMinsTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMins_HandleExitState
	cp xde, 0x2
	jr nz, SqMinsTtl_ReturnZero
	cp (0xf1e1:16), 17
	jr nz, SqMins_ClearBit2
	set 2, (9702:16)
	jr SqMinsTtl_ReturnZero

SqMins_ClearBit2:
	res 2, (9702:16)
	jr SqMinsTtl_ReturnZero

SqMins_HandleExitState:
	ldmmw_dd24 0xec, 0xff, 0x00, 0x75, 0x28

SqMinsTtl_ReturnZero:
	ld xhl, 0:i3
	ret

SqTrclTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqSngcp_ReturnZero
	cp xde, 0x3
	jr z, SqTrcl_HandleExitState
	cp xde, 0x2
	jr nz, SqSngcp_ReturnZero
	ldw (9704:16), 0
	jr SqSngcp_ReturnZero

SqTrcl_HandleExitState:
	ld wa, (0x2738:16)
	cpl wa
	and (0xffec:24), wa

SqSngcp_ReturnZero:
	ld xhl, 0:i3
	ret

SqSngcpTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqRepeat_HandleReturn
	cp xde, 0x3
	jr z, SqRepeat_HandleReturn
	cp xde, 0x2
	jr nz, SqRepeat_HandleReturn
	ld (9992:16), 1
	ld (9994:16), 1
	ld (9996:16), 1
	ld (9998:16), 1

SqRepeat_HandleReturn:
	ld xhl, 0:i3
	ret

SqTrmgTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqTrmg_ReturnZero
	cp xde, 0x3
	jr nz, SqTrmg_ReturnZero
	ld wa, (0x2875:16)
	or (0xffec:24), wa

SqTrmg_ReturnZero:
	ld xhl, 0:i3
	ret

SqAdlyTitleFunc:
	ld xhl, 0:i3
	ret

SqPunchTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqPunch_HandleReturn
	cp xde, 0x3
	jr z, SqPunch_HandleTickOnExit
	cp xde, 0x2
	jr nz, SqPunch_HandleReturn
	call SeqAcc_UpdateAndDispatch
	jr SqPunch_HandleReturn

SqPunch_HandleTickOnExit:
	call SeqAcc_HandlePlaybackTick

SqPunch_HandleReturn:
	ld xhl, 0:i3
	ret

SqPunchmTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqPunchm_HandleReturn
	cp xde, 0x3
	jr z, SqPunchm_HandleStopOnExit
	cp xde, 0x2
	jr nz, SqPunchm_HandleReturn
	call SeqAcc_StartPlaybackFromPosition
	jr SqPunchm_HandleReturn

SqPunchm_HandleStopOnExit:
	call SeqAcc_StopPlayback

SqPunchm_HandleReturn:
	ld xhl, 0:i3
	ret

SqNoteSelTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqNoteSel_HandleReturn
	cp xde, 0x3
	jr z, SqNoteSel_HandleReturn
	cp xde, 0x2
	jr nz, SqNoteSel_HandleReturn
	res 0, (0x2742:16)

SqNoteSel_HandleReturn:
	ld xhl, 0:i3
	ret

SqNoteEdtTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqNoteEdt_ReturnZero
	cp xde, 0x3
	call z, (BmDrEdit_CleanupMelodicMode:24)

SqNoteEdt_ReturnZero:
	ld xhl, 0:i3
	ret

SqDrmSelTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqDrmSel_HandleReturn
	cp xde, 0x3
	jr z, SqDrmSel_HandleReturn
	cp xde, 0x2
	jr nz, SqDrmSel_HandleReturn
	res 0, (0x295b:16)
	set 0, (0x2742:16)

SqDrmSel_HandleReturn:
	ld xhl, 0:i3
	ret

SqDrmEdtTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqDrmEdt_ReturnZero
	cp xde, 0x3
	call z, (BmDrEdit_CleanupDrumMode:24)

SqDrmEdt_ReturnZero:
	ld xhl, 0:i3
	ret

SdRevsetTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SdRevset_ReturnZero
	cp xde, 0x3
	jr z, SdRevset_ClearFlag
	cp xde, 0x2
	jr nz, SdRevset_ReturnZero

SdRevset_ClearFlag:
	ld (0xe38c:16), 0

SdRevset_ReturnZero:
	ld xhl, 0:i3
	ret

SdDspeffTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SdDspeff_ReturnZero
	cp xde, 0x3
	jr z, SdDspeff_ClearFlag
	cp xde, 0x2
	jr nz, SdDspeff_ReturnZero

SdDspeff_ClearFlag:
	ld (0xe38c:16), 0

SdDspeff_ReturnZero:
	ld xhl, 0:i3
	ret

SdAccillTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SdAccill_ReturnZero
	cp xde, 0x3
	jr z, SdAccill_ClearFlag
	cp xde, 0x2
	jr nz, SdAccill_ReturnZero

SdAccill_ClearFlag:
	ld (0xe38c:16), 0

SdAccill_ReturnZero:
	ld xhl, 0:i3
	ret

SqNoteCycpTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqNoteCycp_ReturnZero
	cp xde, 0x3
	call z, (BmDrEdit_ExitPlayMode:24)

SqNoteCycp_ReturnZero:
	ld xhl, 0:i3
	ret

SqDrmCycpTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, SqDrmCycp_ReturnZero
	cp xde, 0x3
	call z, (BmDrEdit_ExitPlayMode:24)

SqDrmCycp_ReturnZero:
	ld xhl, 0:i3
	ret

HelpModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, HelpMode_ReturnZero
	cp xde, 0x1
	jr z, HelpMode_ReturnZero
	or xde, xde
	call z, (AccWrap_PlayModeDispatch:24)

HelpMode_ReturnZero:
	ld xhl, 0:i3
	ret

HelpTitleFunc:
	ld xhl, 0:i3
	ret

EtmenuTitleFunc:
	cp xbc, EVT_ACTIVATE_STATE
	jrl nz, EtmenuTtl_ReturnZero
	cp xde, 0x7
	jrl z, MainExe_DispatchReturn
	cp xde, 0x3
	jrl z, MainExe_DispatchEntry
	cp xde, 0x2
	jrl nz, EtmenuTtl_ReturnZero
	ld (0xe38c:16), 0
	cp (CURRENT_MODE:16), 7
	jr nz, EtmenuTtl_ReturnZero
	ld xwa, 0xd60003
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0xd60004
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0xd60005
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0xd60006
	ld bc, 1:i3
	call SetVisible
	ld xwa, 0xd60003
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xd60004
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xd60005
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	ld xwa, 0xd60006
	ld xbc, EVT_DRAW
	ld xde, 0:i3
	call ApDeliveryEvent
	jr EtmenuTtl_ReturnZero

; MainExeCall dispatch entry
MainExe_DispatchEntry:
	ld (0xe38c:16), 0

; MainExeCall dispatch return
MainExe_DispatchReturn:
	ld wa, 0:i3
	calr VoiceParam_SetD6Group

EtmenuTtl_ReturnZero:
	ld xhl, 0:i3
	ret

MainExeCall:
	ld a, (ACTIVE_TITLE:16)
	cp a, 0x91
	jrl z, MainExe_Handle91
	cp a, 0x8d
	jrl z, MainExe_Handle8D
	cp a, 0x90
	jrl z, MainExe_Handle90
	cp a, 0x86
	jrl z, MainExe_Handle86
	cp a, 0x85
	jr z, MainExe_Handle85
	cp a, 0x83
	jr z, MainExe_Handle83
	cp a, 0xd6
	jr z, MainExe_HandleD6
	extz wa
	sub wa, 0x9a
	cp wa, 0:i3
	jrl lt, MainExe_ReturnZero
	cp wa, 0x10
	jrl gt, MainExe_ReturnZero
	add wa, wa
	lda xix, (MainExeCall_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (MainExe_HandleD6:24)
	jp	t, (xix+wa)

MainExe_HandleD6:
	call NoteMap_ProcessAndMerge
	call MIDI_BroadcastControlChange
	call SeqData_SendVoiceTableBlock
	jrl MainExe_ReturnZero

MainExe_Handle83:
	calr MainExe_SequencerStop
	jrl MainExe_ReturnZero

MainExe_Handle85:
	and e, 0xf
	cp e, 0xa
	jr nz, MainExe_Handle85_SubE9
	ld a, (SEQ_TRANSPORT_STATE:16)
	and a, 0x14
	jrl z, MainExe_ReturnZero
	cpw (0x28a8:16), 0
	jrl z, MainExe_ReturnZero
	set 1, (9834:16)
	call SeqPlay_ProcessVoiceAndNotes
	jrl MainExe_ReturnZero

MainExe_Handle85_SubE9:
	cp e, 0x9
	jrl nz, MainExe_ReturnZero
	bit 1, (0x28b1:16)
	jrl z, MainExe_ReturnZero
	bit 2, (0x28b2:16)
	jr z, MainExe_StartSongPlay
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jr nz, MainExe_StartSongPlay
	jrl MainExe_ReturnZero

MainExe_Handle86:
	bit 1, (0x28b1:16)
	jrl z, MainExe_ReturnZero
	bit 2, (0x28b2:16)
	jr z, MainExe_StartSongPlay
	bit 2, (SEQ_TRANSPORT_STATE:16)
	jrl z, MainExe_ReturnZero

MainExe_StartSongPlay:
	call SeqPlay_CheckDrumAndStart
	jrl MainExe_ReturnZero

MainExe_Handle90:
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqVoice_InitEntry
	call SeqPart_ResetVoicePositions
	ld a, (0x00ffe3:24)
	cp a, (0x2878:16)
	jr nz, MainExe_Handle90_Finish
	ldw (0x2875:16), 0
	ldw (0x00ffec:24), 0x0000

MainExe_Handle90_Finish:
	ldw wa, 0x23
	calr SoundCtrl_SaveAndSendCmd_EE
	res 0, (0x8d88:16)
	jrl MainExe_ReturnZero

MainExe_Handle8D:
	call BitMapOut_ComputeRegionDelta
	ldw wa, 0x23
	jr MainExe_CallSongHandler

MainExe_Handle91:
	call SeqStep_TrackChange

MainExe_SongMemoryLoop:
	calr SoundCtrl_SendCmd_EE
	jrl MainExe_ReturnZero
; MainExeCall_OnTitleSqtrkclr: EXECUTE on TT_SQTRKCLR: calls SeqVoice_InitJmpNop for each track 1-16 whose bit is set
;   in mask word 9704, drops those bits from 0x2875 and zeroes 9704; with an empty mask it only re-posts the title.
MainExeCall_OnTitleSqtrkclr:
	cpw (9704:16), 0
	jr nz, MainExe_SongMemStart
	ldw wa, 0x9a
	jrl MainExe_CallModeSwitch

MainExe_SongMemStart:
	ld (0x2877:16), 1

MainExe_SongMemIterLoop:
	ld a, (0x2877:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_SongMemShiftMask
	slaa bc

MainExe_SongMemShiftMask:
	and bc, (9704:16)
	jr z, MainExe_SongMemNextPart
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqVoice_InitJmpNop

MainExe_SongMemNextPart:
	ld a, (0x2877:16)
	inc 1, a
	ld (0x2877:16), a
	cp a, 0x10
	jr ule, MainExe_SongMemIterLoop
	ld wa, (9704:16)
	ld bc, (0x2875:16)
	and wa, bc
	cpl wa
	and bc, wa
	ld (0x2875:16), bc
	ldmm16 0x2738, 9704
	ldw (9704:16), 0
	ldw wa, 0x23

MainExe_CallSongHandler:
	calr SoundCtrl_SaveAndSendCmd_EE
	jrl MainExe_ReturnZero
; MainExeCall_OnTitleSqtrkmrg: EXECUTE on TT_SQTRKMRG: merges MrgTrA (0xf1d3) and MrgTrB (0xf1d4) into MrgTrC (0xf1d5)
;   through SeqPart_Compare and moves the tracks' bits in 0x2875 / 0xffec from A and B to C.
MainExeCall_OnTitleSqtrkmrg:
	ldmm8 0x2877, 0xf1d3
	ldmm8 9858, 0xf1d4
	ldmm8 9860, 0xf1d5
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_Compare
	ld a, (0x2877:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_ClearPartMask1
	slaa bc

MainExe_ClearPartMask1:
	cpl bc
	and (0x2875:16), bc
	ld a, (0x2877:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_ClearPartMask2
	slaa bc

MainExe_ClearPartMask2:
	cpl bc
	and (0xffec:24), bc
	ld a, (9858:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_ClearPartMask3
	slaa bc

MainExe_ClearPartMask3:
	cpl bc
	and (0x2875:16), bc
	ld a, (9858:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_ClearPartMask4
	slaa bc

MainExe_ClearPartMask4:
	cpl bc
	and (0xffec:24), bc
	ld a, (9860:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_SetPartMask
	slaa bc

MainExe_SetPartMask:
	or (0x2875:16), bc
	ld a, (9860:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_SetPartMaskFFE0
	slaa bc

MainExe_SetPartMaskFFE0:
	or (0xffec:24), bc
	ld a, (GLOBAL_ERROR_CODE:16)
	cp a, 0xff
	jr nz, MainExe_CheckResultCode
	ldw wa, 0x9b
	jrl MainExe_CallModeSwitch

MainExe_CheckResultCode:
	cp a, 0x23
	jrl z, MainExe_SongMemoryLoop
	ld a, (0x2877:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_CalcRemainingMask
	slaa bc

MainExe_CalcRemainingMask:
	cpl bc
	ld wa, bc
	ld bc, (0x2875:16)
	and bc, wa
	ld a, (9858:16)
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, MainExe_MaskSecondary
	slaa de

MainExe_MaskSecondary:
	cpl de
	and bc, de
	ld a, (9860:16)
	dec 1, a
	ld de, 1:i3
	and a, 0xf
	jr z, MainExe_MaskTertiary
	slaa de

MainExe_MaskTertiary:
	cpl de
	and bc, de
	ld (0x2875:16), bc
	jrl MainExe_SongMemoryLoop
; MainExeCall_OnTitleSqqtz: EXECUTE on TT_SQQTZ: track 0xf1f1 (0x11 = all, passed as 127) from measure 0xf1f2, value
;   0xf1f6 doubled into 9726, then SeqPart_VelocityEditSetup.
MainExeCall_OnTitleSqqtz:
	ld a, (0xf1f1:16)
	cp a, 0x11
	jr nz, MainExe_StorePartDirect
	ld (0x2877:16), 127
	jr MainExe_PatternLoad

MainExe_StorePartDirect:
	ld (0x2877:16), a

MainExe_PatternLoad:
	ld wa, (0xf1f2:16)
	ld (9778:16), wa
	ld wa, (9724:16)
	sub wa, (0xf1f2:16)
	inc 1, wa
	ld (9694:16), wa
	ld a, (0xf1f6:16)
	sll a, 1
	ld (9726:16), a
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_VelocityEditSetup
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9c
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqtrns: EXECUTE on TT_SQTRNS: track 9756 from measure 9758 to 9760, then SeqPart_PartSelect.
MainExeCall_OnTitleSqtrns:
	ldmm8 0x2877, 9756
	ld wa, (9758:16)
	ld (9778:16), wa
	ld wa, (9760:16)
	sub wa, (9758:16)
	inc 1, wa
	ld (9694:16), wa
	call SeqPart_PartSelect
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9d
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqvelocng: EXECUTE on TT_SQVELOCNG: track 0xf228 from measure 0xf229, velocity amount 0xf22e into
;   9812, then SeqPart_TransposeSetup (name does not fit).
MainExeCall_OnTitleSqvelocng:
	ld a, (0xf228:16)
	cp a, 0x11
	jr nz, MainExe_RhythmStorePartDirect
	ld (0x2877:16), 127
	jr MainExe_RhythmLoad

MainExe_RhythmStorePartDirect:
	ld (0x2877:16), a

MainExe_RhythmLoad:
	ld wa, (0xf229:16)
	ld (9778:16), wa
	ld wa, (9722:16)
	sub wa, (0xf229:16)
	inc 1, wa
	ld (9694:16), wa
	ldmm8 9812, 0xf22e
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_TransposeSetup
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9e
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqnotecng: EXECUTE on TT_SQNOTECNG: track 9742 from measure 9744 to 9746, then
;   SeqPart_PartVoiceCheck.
MainExeCall_OnTitleSqnotecng:
	ldmm8 0x2877, 9742
	ld wa, (9744:16)
	ld (9778:16), wa
	ld wa, (9746:16)
	sub wa, (9744:16)
	inc 1, wa
	ld (9694:16), wa
	call SeqPart_PartVoiceCheck
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9f
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqadvdly: EXECUTE on TT_SQADVDLY: track 9732 from measure 9734 to 9736, then
;   SeqPart_VoiceCheckModeB.
MainExeCall_OnTitleSqadvdly:
	ldmm8 0x2877, 9732
	ld wa, (9734:16)
	ld (9778:16), wa
	ld wa, (9736:16)
	sub wa, (9734:16)
	inc 1, wa
	ld (9694:16), wa
	call SeqPart_VoiceCheckModeB
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0xa0
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqmers: EXECUTE on TT_SQMERS: track 0xf1db from measure 0xf1dc, MERS choice 0xf1e0 into 9808,
;   then SeqPart_SinglePartLoad.
MainExeCall_OnTitleSqmers:
	ld a, (0xf1db:16)
	cp a, 0x11
	jr nz, MainExe_AccompStorePartDirect
	ld (0x2877:16), 127
	jr MainExe_AccompLoad

MainExe_AccompStorePartDirect:
	ld (0x2877:16), a

MainExe_AccompLoad:
	ld wa, (0xf1dc:16)
	ld (9778:16), wa
	ld wa, (9766:16)
	sub wa, (0xf1dc:16)
	inc 1, wa
	ld (9694:16), wa
	ldmm8 9808, 0xf1e0
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_SinglePartLoad
	cp (GLOBAL_ERROR_CODE:16), 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0xa1
	jrl MainExe_CallModeSwitch
; MainExeCall_OnTitleSqmcp: EXECUTE on TT_SQMCP: source track 0xf1e9 from measure 0xf1ea, destination track 0xf1ee at
;   measure 0xf1ef, then SeqPart_DualPartLoad (SeqPart_LoadAndValidateData after error 0x23).
MainExeCall_OnTitleSqmcp:
	ld wa, (0xf1ea:16)
	ld (9778:16), wa
	ldmm16 9862, 0xf1ef
	ld wa, (9768:16)
	sub wa, (0xf1ea:16)
	inc 1, wa
	ld (9694:16), wa
	ldmm8 9858, 0xf1ee
	ld a, (0xf1e9:16)
	cp a, 0x11
	jr nz, MainExe_SongLoadStorePartDirect
	ld (0x2877:16), 127
	jr MainExe_SongLoad

MainExe_SongLoadStorePartDirect:
	ld (0x2877:16), a

MainExe_SongLoad:
	ld (GLOBAL_ERROR_CODE:16), 255
	ld (SEQ_ERROR_CODE:16), 0
	call SeqPart_DualPartLoad
	ld a, (GLOBAL_ERROR_CODE:16)
	cp a, 0xff
	jr nz, MainExe_SongLoadCheckRedirect
	ldw wa, 0xa2
	jrl MainExe_CallModeSwitch

MainExe_SongLoadCheckRedirect:
	cp a, 0x23
	jr nz, MainExe_SongLoadFinish
	call SeqPart_LoadAndValidateData
	cp (GLOBAL_ERROR_CODE:16), 255
	jr nz, MainExe_SongLoadFinish
	ldw wa, 0xa2
	jrl MainExe_CallModeSwitch

MainExe_SongLoadFinish:
	calr SoundCtrl_SendCmd_EE
	cp (GLOBAL_ERROR_CODE:16), 35
	jr z, MainExe_ReturnZero
	cp (0x2877:16), 127
	jrl z, MainExe_SetAllPartsMask

MainExe_SetPartBitMask:
	ld a, (9858:16)
	dec 1, a
	ld bc, 1:i3
	and a, 0xf
	jr z, MainExe_OrPartMask
	slaa bc

MainExe_OrPartMask:
	or (0x2875:16), bc

MainExe_ReturnZero:
	ld xhl, 0:i3
	ret

MainExe_InlineByteData:
	ld	a, (0xf1d6:16)
	cp	a, 17
	jr	nz, EtmenuTitleFunc_Skip
	ld	(0x2877:16), 127
	jr	EtmenuTitleFunc_Join
EtmenuTitleFunc_Skip:
	ld	(0x2877:16), a
EtmenuTitleFunc_Join:
	ld	wa, (0xf1d7:16)
	ld	(9778:16), wa
	ld	wa, (9772:16)
	sub	wa, (61911:16)
	inc	1, wa
	ld	(9694:16), wa
	ld	(GLOBAL_ERROR_CODE:16), 255
	ld	(SEQ_ERROR_CODE:16), 0
	call	SeqPart_ByteBlockA207
	cp	(GLOBAL_ERROR_CODE:16), 255
	jrl	nz, MainExe_SongMemoryLoop
	ldw	wa, 163
	jr	MainExe_CallModeSwitch
; MainExeCall_OnTitleSqmins: EXECUTE on TT_SQMINS: track 0xf1e1 from measure 0xf1e2, second track 0xf1e6 at measure
;   0xf1e7, then SeqPart_ByteBlockA95A (SeqPart_LoadDualPartData after error 0x23).
MainExeCall_OnTitleSqmins:
	ld	wa, (0xf1e2:16)
	ld	(9778:16), wa
	ldmm16	9862, 61927
	ld	wa, (9774:16)
	sub	wa, (61922:16)
	inc	1, wa
	ld	(9694:16), wa
	ldmm8	9858, 61926
	ld	a, (0xf1e1:16)
	cp	a, 17
	jr	nz, EtmenuTitleFunc_Skip2
	ld	(0x2877:16), 127
	jr	EtmenuTitleFunc_Join2
EtmenuTitleFunc_Skip2:
	ld	(0x2877:16), a
EtmenuTitleFunc_Join2:
	ld	(GLOBAL_ERROR_CODE:16), 255
	ld	(SEQ_ERROR_CODE:16), 0
	call	SeqPart_ByteBlockA95A
	ld	a, (GLOBAL_ERROR_CODE:16)
	cp	a, 255
	jr	nz, EtmenuTitleFunc_Skip3
	ldw	wa, 164
	jr	MainExe_CallModeSwitch
EtmenuTitleFunc_Skip3:
	cp	a, 35
	jr	nz, EtmenuTitleFunc_Skip4
	call	SeqPart_LoadDualPartData
	cp	(GLOBAL_ERROR_CODE:16), 255
	jr	nz, EtmenuTitleFunc_Skip4
	ldw	wa, 164

MainExe_CallModeSwitch:
	call UI_PostModeChangeEvent
	jrl MainExe_ReturnZero
EtmenuTitleFunc_Skip4:
	calr SoundCtrl_SendCmd_EE
	cp (GLOBAL_ERROR_CODE:16), 35
	jrl z, MainExe_ReturnZero
	cp (0x2877:16), 127
	jrl nz, MainExe_SetPartBitMask

MainExe_SetAllPartsMask:
	ldw (0x2875:16), 0xffff
	jrl MainExe_ReturnZero

MainExe_SequencerStop:
	ld (7572:16), 0
	call SeqPlay_SaveStateAndCleanup
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	res 1, (0x28b1:16)
	call SeqStatus_CheckBit2
	cp l, 0:i3
	jr nz, MainExe_SeqStopMode1
	ld wa, 0:i3
	call Part_WriteAllVoiceSubBlocks_A
	jr MainExe_SeqStopFinish

MainExe_SeqStopMode1:
	ld wa, 0:i3
	call Part_WriteAllVoiceSubBlocks_B

MainExe_SeqStopFinish:
	ld wa, 0:i3
	ldw bc, 0x50
	ldw de, 0xffff
	call Part_WriteWord
	ld wa, 0:i3
	ldw bc, 0x32
	call Part_ReleaseVoicesForRange
	ldw (0xf19e:16), 0
	call Audio_CheckSubsystemReady
	call AccWrap_PositionClear
	res 0, (0x28a6:16)
	ldw (0x00ffec:24), 0x0000
	ld (9980:16), 1
	call Part_DetectSingleVoiceType
	ldw wa, 0xb
	jp UI_PostPartChangeEvent

MainPanic:
	cp xbc, EVT_PANIC
	jr nz, MainPanic_ReturnZero
	call NoteMap_ProcessAndMerge
	call MIDI_BroadcastControlChange
	call SeqData_SendVoiceTableBlock

MainPanic_ReturnZero:
	ld xhl, 0:i3
	ret

HelpLang_DispatchDataBlock:
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 19
	ret	nz
	ld	a, (SWBTWR_PAYLOAD_2:16)
	ld	(0x296e:16), a
	cp a, (10608:16)
	ret	z
	cp	a, 49
	ret	ugt
	ld	(0x2970:16), a
	cp	(ACTIVE_TITLE:16), 231
	ret	nz
	ld	e, (0x0340e4:24)
	ld	c, (0x296e:16)
	extz	bc
	cp	e, 5:i3
	jr	z, HelpLang_DispatchDataBlock_Entry
	cp	e, 3:i3
	jr	z, HelpLang_DispatchDataBlock_Skip2
	cp	e, 2:i3
	jr	z, HelpLang_DispatchDataBlock_Skip
	cp	e, 1:i3
	jr	nz, HelpLang_DispatchDataBlock_Skip3
	ld	xwa, HelpLang_ByteTable1
	jr	HelpLang_DispatchDataBlock_Join
HelpLang_DispatchDataBlock_Skip:
	ld	xwa, HelpLang_ByteTable2
	jr	HelpLang_DispatchDataBlock_Join
HelpLang_DispatchDataBlock_Skip2:
	ld	xwa, HelpLang_ByteTable3
	jr	HelpLang_DispatchDataBlock_Join
HelpLang_DispatchDataBlock_Entry:
	ld	xwa, FontPalette_Gradient7
	jr	HelpLang_DispatchDataBlock_Join
HelpLang_DispatchDataBlock_Skip3:
	ld	xwa, HelpLang_ByteTable0
HelpLang_DispatchDataBlock_Join:
	ld	a, (xwa+bc)
	cp a, 1:i3
	jr nz, HelpLang_DispatchDataBlock_Skip4
	ld xwa, NAKA_VIEW_HelpSwTtl1Scr
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, NAKA_VIEW_HelpTtlStr1
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	jr	HelpLang_DispatchDataBlock_Join2
HelpLang_DispatchDataBlock_Skip4:
	cp	a, 2:i3
	jr	nz, HelpLang_DispatchDataBlock_Skip5
	ld	xwa, NAKA_VIEW_HelpSwTtl2Scr
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, NAKA_VIEW_HelpTtlStr2
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	jr	HelpLang_DispatchDataBlock_Join2
HelpLang_DispatchDataBlock_Skip5:
	cp	a, 3:i3
	jr	nz, HelpLang_DispatchDataBlock_Skip6
	ld	xwa, NAKA_VIEW_HelpSwTtl3Scr
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, NAKA_VIEW_HelpTtlStr3
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	jr	HelpLang_DispatchDataBlock_Join2
HelpLang_DispatchDataBlock_Skip6:
	ld	xwa, NAKA_VIEW_HelpSwTtl4Scr
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, NAKA_VIEW_HelpTtlStr4
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
HelpLang_DispatchDataBlock_Join2:
	call	ApPostEvent
	ret

HelpLangChkMain:
	cp xbc, EVT_SET_LANG
	jr z, HelpLang_LoadSlide
	cp xbc, EVT_SHOW
	jr nz, HelpLangChk_ReturnZero
	cp (ACTIVE_TITLE:16), 231
	jr nz, HelpLang_SetFlashAndLoadSlide
	cp (ACTIVE_TITLE_PREVIOUS:16), 238
	jr z, HelpLang_SetFlashAndLoadSlide
	call Get_Region_Code
	cp l, 3:i3
	jr nz, HelpLang_SetRegion5
	ld xwa, NAKA_VIEW_HelpXWin
	ld xbc, EVT_SHOW
	ld xde, 0:i3
	jr HelpLang_PostEvent

HelpLang_SetRegion5:
	ld xwa, NAKA_VIEW_HelpNotXWin
	ld xbc, EVT_SHOW
	ld xde, 0:i3

HelpLang_PostEvent:
	call ApPostEvent

HelpLang_SetFlashAndLoadSlide:
	ld (0x2970:16), 255
	ld a, (0x0340e4:24)
	sll a, 2
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800
	jr HelpLang_ParseSlideHeader

HelpLang_LoadSlide:
	ld a, (0x0340e4:24)
	sll a, 2
	ld w, 0x0:opc
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800

HelpLang_ParseSlideHeader:
	call SLIDE_Parse_Header

HelpLangChk_ReturnZero:
	ld xhl, 0:i3
	ret

HelpFlashFunc:
	cp xbc, EVT_KUBO_FLASH_LOAD
	jr z, HelpFlash_DispatchAudio
	cp xbc, EVT_KUBO_FLASH_WRITE
	jr nz, HelpFlash_ReturnZero
	ldw wa, 0x25
	calr SoundCtrl_SaveAndSendCmd_EE
	ld wa, 4:i3
	call CtrlPanel_IndicatorJumpTable
	ldw wa, 0x23
	calr SoundCtrl_SaveAndSendCmd_EE
	jr HelpFlash_ReturnZero

HelpFlash_DispatchAudio:
	ld wa, 4:i3
	call Audio_DispatchCommand

HelpFlash_ReturnZero:
	ld xhl, 0:i3
	ret

SeqIndicator_HideBoth:
	ld xwa, 0x850013
	ld bc, 0:i3
	call SetVisible
	ld xwa, 0x850014
	ld bc, 0:i3
	jp SetVisible

VoiceParam_SetD6Group:
	pushw iz
	cp a, 0:i3
	scc16 nz, iz
	ld xwa, 0xd60003
	ld bc, iz
	call SetVisible
	ld xwa, 0xd60004
	ld bc, iz
	call SetVisible
	ld xwa, 0xd60005
	ld bc, iz
	call SetVisible
	ld xwa, 0xd60006
	ld bc, iz
	call SetVisible
	popw iz
	ret

SeqLoadPre:
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoadPost:
	cp wa, 0:i3
	jr ge, SeqLoad_PostInitParts
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoad_PostInitParts:
	ld wa, 1:i3
	ld bc, 4:i3
	ld de, 0:i3
	call Part_WriteByte
	calr SeqLoad_RestorePartConfig
	call SeqStep_FindLastUsedPart
	ld a, (0x00ffe3:24)
	extz wa
	call VoicePreset_LoadAndInitPan
	cpw (0xf1ce:16), 0
	jr z, SeqLoad_PostSetPositions
	call SeqStep_FindAndCompactEntry
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	call Audio_CheckSubsystemReady
	jr SeqLoad_PostCheckAutoAccomp

SeqLoad_PostSetPositions:
	ldw (0xf22f:16), 3
	calr SeqBar_ComputeAndSetPositions

SeqLoad_PostCheckAutoAccomp:
	calr SeqLoad_CheckAutoAccompFlag
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	calr SeqLoad_InitPartPanPresets
	calr SeqLoad_ProcessAllVoiceData
	jp Seq_ResetAndRestartAccompaniment

SeqLoad_JumpInitFromPreset:
	jp Part_InitFromPreset

SeqLoad_PostAltEntry:
	cp wa, 0:i3
	jr ge, SeqLoad_AltInitParts
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoad_AltInitParts:
	ld wa, 1:i3
	ld bc, 4:i3
	ld de, 0:i3
	call Part_WriteByte
	ld (0x00ffe3:24), 0x00
	call SeqStep_FindLastUsedPart
	ld a, (0x00ffe3:24)
	extz wa
	call VoicePreset_LoadAndInitPan
	ldmmw_dd24 0xec, 0xff, 0x00, 0x9e, 0xf1
	cpw (0xf1ce:16), 0
	jr z, SeqLoad_AltSetPositions
	call SeqStep_FindAndCompactEntry
	call Audio_CheckSubsystemReady
	jr SeqLoad_AltCheckAutoAccomp

SeqLoad_AltSetPositions:
	ldw (0xf22f:16), 3
	calr SeqBar_ComputeAndSetPositions

SeqLoad_AltCheckAutoAccomp:
	calr SeqLoad_CheckAutoAccompFlag
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	calr SeqLoad_InitPartPanPresets
	calr SeqLoad_ProcessAllVoiceData
	jp Seq_ResetAndRestartAccompaniment

SeqSavePre:
	push xiz
	call SeqStep_ReinitPartTable
	ld xiz, xhl
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	ld wa, 1:i3
	ld bc, 4:i3
	ld de, 1:i3
	call Part_WriteByte
	ld xhl, xiz
	pop xiz
	ret

SeqSavePost:
	pushw iz
	ld iz, wa
	ld wa, 1:i3
	ld bc, 4:i3
	ld de, 0:i3
	call Part_WriteByte
	cp iz, 0:i3
	jr lt, SeqSave_PostReturn
	res 0, (0x8d88:16)

SeqSave_PostReturn:
	popw iz
	ret

SeqLoad_ProcessDataBlock:
	dec	6, xsp
	push	qiz
	ld	(xsp+6), a
	ld	xwa, 0:i3
	ld	(xsp+2), xwa
	ldib_erp 251, 1
SeqLoad_ProcessDataBlock_Loop:
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	ldto_berp c, 251
	extz	bc
	call	Part_ReadVoiceBit7
	cp	l, 0:i3
	jr	z, SeqLoad_ProcessDataBlock_Skip
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	ldto_berp c, 251
	extz	bc
	call	Part_ReadVoiceWord
	ld	wa, hl
	cp	wa, 0xffff
	jr	z, SeqLoad_ProcessDataBlock_Skip
SeqLoad_ProcessDataBlock_Loop2:
	ld	xbc, 1:i3
	add	(xsp+2), xbc
	call	PartCtrl_ReadWord
	ld	wa, hl
	cp	wa, 0xffff
	jr	nz, SeqLoad_ProcessDataBlock_Loop2
SeqLoad_ProcessDataBlock_Skip:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, SeqLoad_ProcessDataBlock_Loop
	ld	wa, (0xf22f:16)
	cp	wa, 0xffff
	jr	z, SeqLoad_ProcessDataBlock_Skip2
SeqLoad_ProcessDataBlock_Loop3:
	ld	xbc, 1:i3
	add	(xsp+2), xbc
	call	PartCtrl_ReadWord
	ld	wa, hl
	cp	wa, 0xffff
	jr	nz, SeqLoad_ProcessDataBlock_Loop3
SeqLoad_ProcessDataBlock_Skip2:
	ld	xhl, (xsp+2)
	sll	xhl, 8
	ld	(xsp+2), xhl
	pop qiz
	inc	6, xsp
	ret
FileIO_ByteBlock_DemoProc1_Helper:
	dec	2, xsp
	pushw	iz
	ld	(xsp+2), a
	; ldw (0xf19e),(0x00ffec)
	ldw	(0xf19e:16), (0xffec:24)
	call	Audio_CheckSubsystemReady
	ld	a, (0xffe3:24)
	extz	wa
	call	SeqData_CopyBlockToBuffer
	ld	a, (xsp+2)
	extz	wa
	call	VoicePreset_LoadAndInitPan
	ld	a, (xsp+2)
	ld	(0xffe3:24), a
	call	SeqVoice_InitEntryForCurrentBank
	ld	a, (0xffe3:24)
	extz	wa
	call	SeqData_CopyBlockToBuffer
	ld	iz, (0xf1ce:16)
	call	SeqStep_FindAndCompact
	ld	(0xf1ce:16), iz
	popw	iz
	inc	2, xsp
	ret
FileIO_ByteBlock_DemoProc1_Helper2:
	dec	8, xsp
	push	xiz
	ld	(xsp+10), a
	cp	bc, 0:i3
	jr	ge, SeqLoad_ProcessDataBlock_Skip3
	call	SeqVoice_InitEntryForCurrentBank
	jrl	SeqLoad_ProcessDataBlock_Join
SeqLoad_ProcessDataBlock_Skip3:
	calr	SeqBar_DataBlock
	ld	a, (xsp+10)
	extz	wa
	call	VoicePreset_LoadAndInitPan
	calr	SeqLoad_ProcessDataBlock_Helper
	calr	SeqLoad_ProcessDataBlock_Helper2
	ld	(xsp+6), hl
	ldib_erp 251, 1
SeqLoad_ProcessDataBlock_Loop4:
	ldto_berp c, 251
	extz	bc
	ld	wa, 0:i3
	call	Part_ReadVoiceWord
	ld	iz, hl
	cp	iz, 0:i3
	jr	z, SeqLoad_ProcessDataBlock_Skip5
	cp	iz, 0xffff
	jr	z, SeqLoad_ProcessDataBlock_Skip5
	add	iz, (xsp+6)
	ldto_berp	c, 251
	extz	bc
	ld	wa, 0:i3
	ld	de, iz
	call	Part_WriteVoiceWord
	ldto_berp c, 251
	extz	bc
	ld	wa, 0:i3
	call	Part_ReadWord_Indexed
	ld	iz, hl
	add	iz, (xsp+6)
	ldto_berp	c, 251
	extz	bc
	ld	wa, 0:i3
	ld	de, iz
	call	Part_WriteWord_Indexed
SeqLoad_ProcessDataBlock_Skip5:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, SeqLoad_ProcessDataBlock_Loop4
	ldw	(xsp+8), (61902)
	ld	wa, (xsp+8)
	srl	wa, 4
	ld	(xsp+8), wa
	ld	iz, (0xf22f:16)
	ldw	(xsp+4), 0
	cpw	(xsp+8), 0
	jr	ule, SeqLoad_ProcessDataBlock_Skip7
SeqLoad_ProcessDataBlock_Loop5:
	ld	wa, iz
	add	wa, (xsp+4)
	call	PartCtrl_ReadWord_Off1
	ld	bc, hl
	cp	bc, 0xffff
	jr	z, SeqLoad_ProcessDataBlock_Skip6
	cp	bc, 0:i3
	jr	z, SeqLoad_ProcessDataBlock_Skip6
	add	bc, (xsp+6)
	ld	wa, iz
	add	wa, (xsp+4)
	call	PartCtrl_WriteWord_Off1
SeqLoad_ProcessDataBlock_Skip6:
	ld	wa, iz
	add	wa, (xsp+4)
	call	PartCtrl_ReadWord
	ld	bc, hl
	cp	bc, 0xffff
	jr	z, SeqLoad_ProcessDataBlock_Skip4
	cp	bc, 0:i3
	jr	z, SeqLoad_ProcessDataBlock_Skip4
	add	bc, (xsp+6)
	ld	wa, iz
	add	wa, (xsp+4)
	call	PartCtrl_WriteWord
SeqLoad_ProcessDataBlock_Skip4:
	incw	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, (xsp+8)
	jr	c, SeqLoad_ProcessDataBlock_Loop5
SeqLoad_ProcessDataBlock_Skip7:
	calr	SeqBar_ComputeAndSetPositions
	ldw	(9832:16), 1
	calr	SeqLoad_ProcessDataBlock_Helper3
	calr	SeqLoad_CheckAutoAccompFlag
	ld	a, (xsp+10)
	extz	wa
	call	SeqData_CopyBlockToBuffer
	calr	SeqLoad_InitPartPanPresets
	calr	SeqLoad_ProcessAllVoiceData
	call	Seq_ResetAndRestartAccompaniment
	; ldw (0x00ffec),(0xf19e)
	ldw	(0xffec:24), (0xf19e:16)
SeqLoad_ProcessDataBlock_Join:
	pop	xiz
	inc	8, xsp
	ret

FileIO_WriteBlockToStream:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	ld xhl, 0:i3
	ld xiz, (7514:16)
	extz xwa
	dec 1, xwa
	sll xwa, 8
	add xiz, xwa
	ld xix, (0x29ee:16)
	ld wa, (0x29f6:16)
	extz xwa
	sll xwa, 8
	add xix, xwa
	ld xde, xix
	ld iy, 0:i3

FileIO_WriteBlockCopyLoop:
	ld wa, iy
	extz xwa
	ld xbc, xwa
	add xbc, xde
	add xwa, xiz
	ld a, (xwa)
	ld (xbc), a
	inc 1, iy
	cp iy, 0x100
	jr c, FileIO_WriteBlockCopyLoop
	ld wa, (0x29f4:16)
	ld bc, (0x29f2:16)
	add bc, wa
	ld wa, bc
	dec 1, wa
	ld (xix + 1), wa
	inc 1, bc
	ld (xix + 3), bc
	cpw (0x29f4:16), 0
	jr nz, FileIO_WriteCheckDefault
	ldw (xde + 1), 0x0

FileIO_WriteCheckDefault:
	cpw (xsp + 4), 0xffff
	jr nz, FileIO_WriteUpdateCounter
	ldw (xix + 3), 0xffff

FileIO_WriteUpdateCounter:
	ld wa, (0x29f6:16)
	inc 1, wa
	ld (0x29f6:16), wa
	cp wa, 0x20
	jr c, FileIO_WritePopReturn
	ld xwa, (0x29ee:16)
	ld xbc, 0x2000
	call FileIO_WriteByte_Impl
	ldw (0x29f6:16), 0

FileIO_WritePopReturn:
	pop xiz
	inc 2, xsp
	ret

FileIO_FlushPendingBlock:
	ld xhl, 0:i3
	ld bc, (0x29f6:16)
	cp bc, 0:i3
	ret z
	ld xwa, (0x29ee:16)
	sll bc, 8
	extz xbc
	call FileIO_WriteByte_Impl
	ret

FileIO_WriteAllPartVoices:
	dec 6, xsp
	push xiz
	ld (xsp + 8), a
	ldw (xsp + 6), 0x0
	ldw (0x29f2:16), 1
	ldw (0x29f6:16), 0
	ld (xsp + 4), 0x1

FileIO_WritePartLoop:
	ldw (0x29f4:16), 0
	ld a, (xsp + 8)
	inc 1, a
	extz wa
	ld c, (xsp + 4)
	extz bc
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, FileIO_WriteNextPart
	ld a, (xsp + 8)
	inc 1, a
	extz wa
	ld c, (xsp + 4)
	extz bc
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr z, FileIO_WritePartAccumulate

FileIO_WriteVoiceChainLoop:
	ld wa, iz
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xfa
	ld wa, iz
	ldto_werp BC, 0xfa
	calr FileIO_WriteBlockToStream
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jr lt, FileIO_WriteEpilogue
	ldto_werp IZ, 0xfa
	incw 1, (0x29f4:16)
	cp iz, 0xffff
	jr nz, FileIO_WriteVoiceChainLoop

FileIO_WritePartAccumulate:
	ld wa, (0x29f4:16)
	add (0x29f2:16), wa

FileIO_WriteNextPart:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr ule, FileIO_WritePartLoop
	calr FileIO_FlushPendingBlock

FileIO_WriteEpilogue:
	ld hl, (xsp + 6)
	pop xiz
	inc 6, xsp
	ret

SeqSave_PreparePartData:
	dec 6, xsp
	push xiz
	ld (xsp + 8), a
	ld a, (0x00ffe3:24)
	cp a, (xsp + 8)
	jr nz, SeqSave_CopyBlockAndInit
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	call Audio_CheckSubsystemReady

SeqSave_CopyBlockAndInit:
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ldw bc, 0xc7
	ld de, 0:i3
	call Part_WriteByte
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ldw bc, 0x1e
	call Part_ReadWord
	ld de, hl
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ldw bc, 0xc8
	call Part_WriteWord
	ld a, (xsp + 8)
	extz wa
	calr SeqSave_ComputeVoiceSize
	ld (xsp + 4), xhl
	ld xhl, (xsp + 4)
	cp xhl, 0x0
	jrl lt, AppEvent_PopIzSkip6Ret
	call GetEncodedFreeSpaceData
	cp xhl, 0x0
	jrl lt, AppEvent_PopIzSkip6Ret
	cp (xsp + 4), xhl
	jr le, SeqSave_AllocAndWrite
	ldw hl, 0xff9b
	jrl AppEvent_PopIzSkip6Ret

SeqSave_AllocAndWrite:
	ld a, (xsp + 8)
	extz wa
	calr SeqSave_WriteBlockToFile
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	pushw 0x2020
	call Malloc
	inc 2, xsp
	ld (0x29ee:16), xhl
	or xhl, xhl
	jr nz, SeqSave_WriteAndFree
	ldw hl, 0xfffd
	jrl AppEvent_PopIzSkip6Ret

SeqSave_WriteAndFree:
	ld a, (xsp + 8)
	extz wa
	calr FileIO_WriteAllPartVoices
	ld iz, hl
	exts xiz
	ld xwa, (0x29ee:16)
	push xwa
	call Free
	inc 4, xsp
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	ld bc, 0:i3
	lda xde, (0x29ce:16)
	ld xwa, xde
	lda xde, (xde + 32)

SeqSave_CountBlocksLoop:
	add BC, (xwa+)
	cp xwa, xde
	jr c, SeqSave_CountBlocksLoop
	sll bc, 4
	ld xwa, 0x4e
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	ld xwa, 4:i3
	ld bc, 0:i3
	calr FileIO_SeekReadAndCheck
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	ldw (xsp + 6), 0x0
	ld (xsp + 4), 0x0

SeqSave_WritePartDataLoop:
	ld c, (xsp + 4)
	extz bc
	add bc, bc
	lda xde, (0x29ce:16)
	ld a, (xsp + 4)
	mul a, 0x3
	add a, 0xd1
	ld w, 0x0:opc
	extz xwa
	cpw	(xde+bc), 0x0000
	jr nz, SeqSave_WritePartInner
	ldw bc, 0xffff
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	add a, (xsp + 4)
	add a, 0x78
	ld w, 0x0:opc
	extz xwa
	ldw bc, 0xffff
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr ge, SeqSave_NextPartLoop
	jr AppEvent_LoadIzToHL

SeqSave_WritePartInner:
	ld bc, (xsp + 6)
	inc 1, bc
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	add a, (xsp + 4)
	add a, 0x78
	ld w, 0x0:opc
	extz xwa
	ld e, (xsp + 4)
	extz de
	add de, de
	lda xhl, (0x29ce:16)
	ld bc, (xsp + 6)
	add	bc, (xhl+de)
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda xbc, (0x29ce:16)
	ld	wa, (xbc+wa)
	add (xsp + 6), wa

SeqSave_NextPartLoop:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jrl c, SeqSave_WritePartDataLoop
	res 0, (0x8d88:16)

AppEvent_LoadIzToHL:
	ld hl, iz

AppEvent_PopIzSkip6Ret:
	pop xiz
	inc 6, xsp
	ret

SeqLoad_ValidateFormat:
	cp (xwa + 5), 0x1
	jr nz, SeqLoad_FormatInvalid
	ld l, (xwa + 6)
	cp l, 3:i3
	jr z, SeqLoad_FetchPartLength
	cp l, 6:i3
	jr z, SeqLoad_FetchPartLength
	cp l, 7:i3
	jr z, SeqLoad_FetchPartLength
	cp l, 0x8
	jr z, SeqLoad_FetchPartLength

SeqLoad_FormatInvalid:
	ldw hl, 0xff9a
	ret

SeqLoad_FetchPartLength:
	ld l, (xwa + 4)
	extz hl
	ret

SeqLoad_JmpLoadPre:
	jrl SeqLoadPre

SeqLoad_JmpLoadPost:
	jrl SeqLoadPost

SeqLoad_JmpInitPreset:
	jrl SeqLoad_JumpInitFromPreset

SeqLoad_JmpAltEntry:
	jrl SeqLoad_PostAltEntry

SeqBar_ComputeAndSetPositions:
	pushw iz
	ld bc, (0xf22f:16)
	ld wa, (0xf1ce:16)
	srl wa, 4
	add bc, wa
	cp bc, 0x4d8
	jr c, SeqBar_ClampAndStore
	ldw bc, 0xffff

SeqBar_ClampAndStore:
	ld wa, bc
	call Part_WriteWordBlock_OffsetAF
	ld bc, (0xf22f:16)
	cp bc, 0xffff
	jr nz, SeqBar_ComputeRange
	ldw (0xf231:16), 0
	ld wa, 0:i3
	jr SeqBar_CheckZeroRange

SeqBar_ComputeRange:
	ldw wa, 0x4d8
	sub wa, bc
	inc 1, wa
	call Part_SetAllVoicePos
	ld wa, (0xf231:16)

SeqBar_CheckZeroRange:
	cp wa, 0:i3
	jr z, SeqBar_ReturnDone
	ld iz, (0xf22f:16)
	cp iz, wa
	jr ugt, SeqBar_WriteBoundary

SeqBar_SetPositionLoop:
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_SetClearBit7
	ld wa, iz
	ld bc, 5:i3
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	cp iz, 0:i3
	jr z, SeqBar_LinkNextPosition
	ld bc, iz
	dec 1, bc
	ld wa, iz
	call PartCtrl_WriteWord_Off1

SeqBar_LinkNextPosition:
	ld bc, iz
	inc 1, bc
	ld wa, iz
	call PartCtrl_WriteWord
	inc 1, iz
	cp iz, (0xf231:16)
	jr ule, SeqBar_SetPositionLoop

SeqBar_WriteBoundary:
	ld wa, (0xf22f:16)
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ldw wa, 0x4d8
	ldw bc, 0xffff
	call PartCtrl_WriteWord

SeqBar_ReturnDone:
	popw iz
	ret

SeqBar_DataBlock:
	ldmm16	10698, 61999
	ldmm16	10700, 62001
	ret
SeqLoad_ProcessDataBlock_Helper:
	ldmm16	61999, 10698
	ldmm16	62001, 10700
	ret
SeqLoad_ProcessDataBlock_Helper2:
	ld	hl, 0:i3
	ld	wa, (0xf22f:16)
	cp	wa, 0:i3
	ret	z
	ld	hl, wa
	dec	1, hl
	ret
	dec	4, xsp
	ld	(xsp), bc
	ld	(xsp+2), a
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	Part_ReadVoiceWord
	ld	de, hl
	cp	de, 0xffff
	jr	z, SeqBar_DataBlock_Code_Skip
	cp	de, 0:i3
	jr	nz, SeqBar_DataBlock_Code_Entry
SeqBar_DataBlock_Code_Skip:
	jr	SeqBar_DataBlock_Code_Epilogue
SeqBar_DataBlock_Code_Entry:
	add	de, (xsp)
	ld	c, (xsp+2)
	extz	bc
	ld	wa, 0:i3
	call	Part_WriteVoiceWord
SeqBar_DataBlock_Code_Epilogue:
	inc	4, xsp
	ret
SeqLoad_ProcessDataBlock_Helper3:
	ld	wa, 0:i3
	ld	bc, 5:i3
	call	Part_ReadByteDirect
	cp	l, 1:i3
	ret	nz
	ld	wa, 0:i3
	ld	bc, 6:i3
	call	Part_ReadByteDirect
	cp	l, 7:i3
	jr	z, SeqBar_DataBlock_Code_Skip2
	cp	l, 8
	ret	nz
SeqBar_DataBlock_Code_Skip2:
	lda	xde, (0xfc5a:16)
	lda	xbc, (xde+8)
	ld	xwa, xbc
	sub	xwa, 0xf980
	ld	ix, wa
	lda	xhl, (0xf460:16)
	ld	wa, ix
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	ld	(xbc), a
	ld	wa, ix
	inc	1, wa
	extz	xwa
	add	xwa, xhl
	ld	a, (xwa)
	ld	(xde+9), a
	ret

SeqLoad_RestorePartConfig:
	ld wa, 1:i3
	ldw bc, 0xc7
	call Part_ReadByteDirect
	ld (0x00ffe3:24), l
	ld wa, 1:i3
	ldw bc, 0xc7
	ld de, 0:i3
	call Part_WriteByte
	ld wa, 1:i3
	ldw bc, 0xc8
	call Part_ReadWord
	ld (0x00ffec:24), hl
	ld wa, 1:i3
	ldw bc, 0xc8
	ld de, 0:i3
	call Part_WriteWord
	ldw (9832:16), 1
	res 3, (0x28a7:16)
	ret

SeqSave_ComputeVoiceSize:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 4), a
	ldw (xsp + 2), 0x0
	cp (xsp + 4), 0x10
	jr c, SeqSave_VoiceSizeInitLoop
	ld xhl, 0xffffffff
	jr SeqSave_VoiceSizeReturn

SeqSave_VoiceSizeInitLoop:
	ldib_erp 0xfb, 1

SeqSave_VoiceSizePartLoop:
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (0x29ce:16)
	ldw	(xbc+wa), 0x0000
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqSave_VoiceSizeNextPart
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	call Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqSave_VoiceSizeNextPart

SeqSave_VoiceSizeChainLoop:
	ldto_berp C, 0xfb
	dec 1, c
	extz bc
	add bc, bc
	lda xde, (0x29ce:16)
	incw	1, (xde+bc)
	incw 1, (xsp + 2)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr nz, SeqSave_VoiceSizeChainLoop

SeqSave_VoiceSizeNextPart:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqSave_VoiceSizePartLoop
	ld hl, (xsp + 2)
	extz xhl
	sll xhl, 8
	add xhl, 0x800

SeqSave_VoiceSizeReturn:
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqSave_ReadBlockFromMem:
	ld	xbc, (7514:16)
	extz	xwa
	dec	1, xwa
	sll	xwa, 8
	add	xbc, xwa
	ld	xwa, xbc
	ld	xbc, 256
	jp	FileIO_WriteByte_Impl

SeqSave_WriteBlockToFile:
	ld c, a
	ld b, 0x0:opc
	extz xbc
	sll xbc, 11
	ld xwa, SEQ_SONG_SLOTS
	add xwa, xbc
	ld xbc, 0x800
	jp FileIO_WriteByte_Impl

FileIO_SeekReadAndCheck:
	dec 2, xsp
	ld (xsp), c
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	exts xhl
	or xhl, xhl
	jr nz, FileIO_SeekReadReturn
	ld a, (xsp)
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl

FileIO_SeekReadReturn:
	inc 2, xsp
	ret

FileIO_SeekAndRead16BitValue:
	pushw iz
	ld iz, bc
	ld bc, 0:i3
	call FileIO_SeekAndReadBlock
	exts xhl
	or xhl, xhl
	jr nz, FileIO_Read16Return
	ld wa, iz
	ld w, 0x0:opc
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl
	or xhl, xhl
	jr nz, FileIO_Read16Return
	ld wa, iz
	srl wa, 8
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl

FileIO_Read16Return:
	popw iz
	ret

SeqLoad_ReadPartDataBlock:
	lda	xsp, (xsp-10)
	push	xiz
	ld	(xsp+12), a
	ld	a, (xsp+12)
	extz	wa
	add	wa, wa
	lda	xde, (0x29ce:16)
	cpw	(xde+wa), 0x0000
	jr	nz, FileIO_SeekAndRead16BitValue_Skip2
	ld	xhl, 0:i3
	jrl	FileIO_SeekAndRead16BitValue_Epilogue
FileIO_SeekAndRead16BitValue_Skip2:
	ld	xwa, 2048
	ld	(xsp+4), xwa
	ldw (xsp+10), 0
	ldw (xsp+8), 0
	ld	c, (xsp+12)
	extz	bc
	cp	bc, 0:i3
	jr	ule, FileIO_SeekAndRead16BitValue_Skip3
FileIO_SeekAndRead16BitValue_Loop:
	ld	wa, (xsp+8)
	add	wa, wa
	extz	xwa
	add	xwa, xde
	ld	hl, (xwa)
	extz	xhl
	sll	xhl, 8
	add	(xsp+4), xhl
	ld	wa, (xwa)
	add	(xsp+10), wa
	incw	1, (xsp+8)
	cp	(xsp+8), bc
	jr	c, FileIO_SeekAndRead16BitValue_Loop
FileIO_SeekAndRead16BitValue_Skip3:
	ld	xwa, 1:i3
	add	(xsp+4), xwa
	ldw	(xsp+8), 1
	jr	FileIO_SeekAndRead16BitValue_Join
FileIO_SeekAndRead16BitValue_Loop2:
	ld	xwa, (xsp+4)
	calr	FileIO_SeekAndRead16BitValue
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, FileIO_SeekAndRead16BitValue_Skip4
	ldw	wa, 200
	jr	FileIO_SeekAndRead16BitValue_Join2
FileIO_SeekAndRead16BitValue_Skip4:
	ld	xwa, (xsp+4)
	inc	2, xwa
	ld	bc, (xsp+10)
	add	bc, (xsp+8)
	inc	1, bc
	calr	FileIO_SeekAndRead16BitValue
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, FileIO_SeekAndRead16BitValue_Skip5
	ldw	wa, 201
	jr	FileIO_SeekAndRead16BitValue_Join2
FileIO_SeekAndRead16BitValue_Skip5:
	ld	xwa, 256
	add	(xsp+4), xwa
	incw	1, (xsp+8)
FileIO_SeekAndRead16BitValue_Join:
	ld	l, (xsp+12)
	extz	hl
	add	hl, hl
	lda	xde, (0x29ce:16)
	ld	bc, (xsp+10)
	add	bc, (xsp+8)
	dec	1, bc
	ld	wa, (xsp+8)
	cp	wa, (xde+hl)
	jr	c, FileIO_SeekAndRead16BitValue_Loop2
	ld	xwa, (xsp+4)
	calr	FileIO_SeekAndRead16BitValue
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, FileIO_SeekAndRead16BitValue_Skip6
	ldw	wa, 202
	jr	FileIO_SeekAndRead16BitValue_Join2
FileIO_SeekAndRead16BitValue_Skip6:
	ld	xwa, (xsp+4)
	inc	2, xwa
	ldw	bc, 0xffff
	calr	FileIO_SeekAndRead16BitValue
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, FileIO_SeekAndRead16BitValue_Skip
	ldw	wa, 203
FileIO_SeekAndRead16BitValue_Join2:
	call	SeqData_SetErrorCode
FileIO_SeekAndRead16BitValue_Skip:
	ld	xhl, xiz
FileIO_SeekAndRead16BitValue_Epilogue:
	pop	xiz
	lda	xsp, (xsp+10)
	ret

SeqLoad_CheckAutoAccompFlag:
	ld wa, 0:i3
	ld bc, 6:i3
	call Part_ReadByteDirect
	cp l, 3:i3
	jr nc, SeqLoad_SkipBitCheck
	set 0, (0xf23e:16)
	ld wa, 0:i3
	ld bc, 5:i3
	call Part_ReadByteDirect
	cp l, 0:i3
	jr nz, SeqLoad_SkipBitCheck
	ld wa, 0:i3
	ld bc, 6:i3
	call Part_ReadByteDirect
	cp l, 3:i3
	jr nc, SeqLoad_SkipBitCheck
	res 0, (0xf23e:16)

SeqLoad_SkipBitCheck:
	jr SeqLoad_ClearAutoAccompBit1

SeqLoad_ClearAutoAccompBit1:
	res 1, (0xf23e:16)
	ret

SeqLoad_ProcessAllVoiceData:
	dec 8, xsp
	push xiz
	ld (xsp + 4), 0x1

SeqLoad_ProcessOuterLoop:
	ld (xsp + 6), 0x1

SeqLoad_ProcessInnerLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jrl z, VoiceData_LoopEnd
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	call Part_ReadVoiceWord
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xffff
	jrl z, VoiceData_LoopEnd
	cpw (xsp + 8), 0xffff
	jrl z, VoiceData_LoopEnd

SeqLoad_ProcessVoiceFound:
	cpw (xsp + 8), 0x1
	jr z, VoiceData_ProcessLoop
	cpw (xsp + 8), 0x2
	jrl nz, VoiceData_NextWord

VoiceData_ProcessLoop:
	call Part_ProcessAndDecrementVoice
	ld (xsp + 10), hl
	cpw (xsp + 10), 0x4d8
	jrl ugt, SeqLoad_ProcessEpilogue
	cpw (xsp + 10), 0x1
	jr z, VoiceData_ProcessLoop
	cpw (xsp + 10), 0x2
	jr z, VoiceData_ProcessLoop
	ld xwa, (7514:16)
	ld xiy, xwa
	ld ix, (xsp + 8)
	extz xix
	dec 1, xix
	sll xix, 8
	ld xiz, xwa
	ld hl, (xsp + 10)
	extz xhl
	dec 1, xhl
	sll xhl, 8
	ld de, 0:i3

SeqLoad_ProcessNextInner:
	ld wa, de
	extz xwa
	ld xbc, xwa
	add xbc, xhl
	add xbc, xiz
	add xwa, xix
	add xwa, xiy
	ld a, (xwa)
	ld (xbc), a
	inc 1, de
	cp de, 0x100
	jr c, SeqLoad_ProcessNextInner
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord_Off1
	ld wa, hl
	cp wa, 0:i3
	jr z, SeqLoad_ProcessNextOuter
	ld bc, (xsp + 10)
	call PartCtrl_WriteWord
	jr SeqLoad_ProcessReturn

SeqLoad_ProcessNextOuter:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 10)
	call Part_WriteVoiceWord
	ld a, (xsp + 4)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, SeqLoad_ProcessReturn
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	ld de, (xsp + 10)
	call Part_WriteVoiceWord

SeqLoad_ProcessReturn:
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqLoad_ProcessCopyLoop
	ld bc, (xsp + 10)
	call PartCtrl_WriteWord_Off1
	jr VoiceData_NextWord

SeqLoad_ProcessCopyLoop:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 10)
	call Part_WriteWord_Indexed
	ld a, (xsp + 4)
	dec 1, a
	cp a, (0xffe3:24)
	jr nz, VoiceData_NextWord
	ld c, (xsp + 6)
	extz bc
	ld wa, 0:i3
	ld de, (xsp + 10)
	call Part_WriteWord_Indexed

VoiceData_NextWord:
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord
	ld (xsp + 8), hl
	cpw (xsp + 8), 0xffff
	jrl nz, SeqLoad_ProcessVoiceFound

VoiceData_LoopEnd:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x10
	jrl ule, SeqLoad_ProcessInnerLoop
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0xa
	jrl ule, SeqLoad_ProcessOuterLoop
	ld wa, 1:i3
	ld bc, 1:i3
	call PartCtrl_SetClearBit7
	ld wa, 1:i3
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, 1:i3
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ld wa, 1:i3
	ld bc, 5:i3
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	ld wa, 2:i3
	ld bc, 1:i3
	call PartCtrl_SetClearBit7
	ld wa, 2:i3
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, 2:i3
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ld wa, 2:i3
	ld bc, 5:i3
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf

SeqLoad_ProcessEpilogue:
	pop xiz
	inc 8, xsp
	ret

SeqLoad_InitPartPanPresets:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

SeqLoad_PanPresetLoop:
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x112
	call Part_ReadByteDirect
	cp l, 1:i3
	jr z, SeqLoad_PanPresetNext
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x112
	ld de, 1:i3
	call Part_WriteByte
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x110
	call Part_ReadWord
	cp hl, 0:i3
	jr nz, SeqLoad_PanPresetNext
	ldto_berp A, 0xfb
	extz wa
	ldw bc, 0x110
	ldw de, 0xffff
	call Part_WriteWord
	call VoiceChannels_InitPanFromPreset

SeqLoad_PanPresetNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqLoad_PanPresetLoop
	popw_erp 0xfa
	ret

SeqScan_ValidateAndDispatch:
	cp bc, 0:i3
	ret lt
	cp a, 2:i3
	jr z, SeqScan_ValidateReturn2
	jr SeqScan_ProcessAllPartsAndVoices

SeqScan_ValidateReturn2:
	ret

SeqScan_ProcessAllPartsAndVoices:
	pushw_erp 0xfa
	calr VoiceAlloc_InitBitMap
	ldib_erp 0xfa, 1

SeqScan_OuterPartLoop:
	ldib_erp 0xfb, 1

SeqScan_InnerVoiceLoop:
	ldto_berp A, 0xfa
	extz wa
	ldto_berp C, 0xfb
	extz bc
	calr SeqScan_ProcessVoiceSlot
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqScan_InnerVoiceLoop
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x0a
	jr ule, SeqScan_OuterPartLoop
	calr VoiceMap_RebuildFromParts
	popw_erp 0xfa
	ret

SeqScan_ProcessVoiceSlot:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), c
	ld (xsp + 12), a
	ldw (xsp + 6), 0x0
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 10)
	extz bc
	call Part_ReadVoiceBit7
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 10)
	extz bc
	cp l, 0:i3
	jr nz, SeqScan_VoiceHasBit7
	calr Part_ClearVoiceSlot
	jrl SeqScan_ReturnZero

SeqScan_VoiceHasBit7:
	call Part_ReadVoiceWord
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	calr VoiceAlloc_CheckRangeAndBit7
	cp hl, 0:i3
	jr z, SeqScan_CheckChainOwner
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10
	jrl SeqScan_CallCompare

SeqScan_CheckChainOwner:
	ldiw_erp 0xfa, 0
	ld iz, (xsp + 4)
	ld wa, iz

SeqScan_ChainWalkLoop:
	call PartCtrl_ReadWord
	ld (xsp + 4), hl
	cpiw_erp 0xfa, 0
	jr nz, SeqScan_TestOwnerBit
	ld wa, iz
	calr VoiceAlloc_TestBitInMap
	cp l, 0:i3
	jr z, SeqScan_TestOwnerBit
	setm 4, (xsp + 6)
	jr SeqScan_CheckFlags

SeqScan_TestOwnerBit:
	ld wa, iz
	ldto_werp BC, 0xfa
	ld de, 1:i3
	calr PartCtrl_CheckOwnerAndToggle
	ld (xsp + 6), hl

SeqScan_CheckFlags:
	cpw (xsp + 6), 0x0
	jr z, SeqScan_ReadCounterAndCheck
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, SeqScan_AppendToQueue
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10
	jrl SeqScan_CallCompare

SeqScan_AppendToQueue:
	ld wa, (xsp + 6)
	ld bc, iz
	ld de, 0:i3
	calr PartCtrl_AppendToEventQueue

SeqScan_ReadCounterAndCheck:
	ld wa, iz
	calr VoiceAlloc_ReadCounterByte
	ld (xsp + 8), hl
	cpw (xsp + 8), 0x100
	jr nc, SeqScan_HandleOverflow
	cpw (xsp + 4), 0xffff
	jr z, SeqScan_WriteNewVoiceWord
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x40
	calr PartCtrl_AppendToEventQueue
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord

SeqScan_WriteNewVoiceWord:
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 10)
	extz bc
	ld de, iz
	call Part_WriteWord_Indexed
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 10)
	extz bc
	ld de, (xsp + 8)
	call Part_WriteByte_Indexed
	ld a, (xsp + 12)
	extz wa
	ld c, (xsp + 10)
	extz bc
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqScan_ReturnZero

SeqScan_ClearChainLoop:
	ld wa, iz
	calr VoiceAlloc_SetBitInMap
	ld wa, iz
	call PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqScan_ClearChainLoop

SeqScan_ReturnZero:
	ld hl, 0:i3
	jr SeqScan_PopEpilogue

SeqScan_HandleOverflow:
	cpw (xsp + 4), 0xffff
	jr nz, SeqScan_CheckEndCondition
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x80
	jr SeqScan_CallCompare

SeqScan_CheckEndCondition:
	cpw (xsp + 4), 0xffff
	jr z, SeqScan_CheckZeroDefault
	cpw (xsp + 4), 0x4d8
	jr ugt, SeqScan_CallCompareAndFail

SeqScan_CheckZeroDefault:
	cpw (xsp + 4), 0x0
	jr nz, SeqScan_ContinueChain

SeqScan_CallCompareAndFail:
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10

SeqScan_CallCompare:
	calr SeqScan_CompareAndAppend
	ldw hl, 0xffff

SeqScan_PopEpilogue:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeqScan_ContinueChain:
	ldfr_werp IZ, 0xfa
	ld iz, (xsp + 4)
	ld wa, iz
	jrl SeqScan_ChainWalkLoop

VoiceMap_RebuildFromParts:
	push xiz
	ldiw_erp 0xfa, 0
	ld wa, 0:i3
	call Part_WriteWordBlock_OffsetAF
	ldw iz, 0x4d8

VoiceMap_RebuildLoop:
	ld wa, iz
	calr VoiceAlloc_TestBitInMap
	cp l, 0:i3
	jr nz, VoiceMap_RebuildNext
	ld wa, iz
	calr VoiceChain_LinkAtEnd
	ld wa, iz
	ld bc, 0:i3
	ld de, 0:i3
	calr PartCtrl_CheckOwnerAndToggle
	inc1w_erp 0xfa

VoiceMap_RebuildNext:
	dec 1, iz
	cp iz, 2:i3
	jr ugt, VoiceMap_RebuildLoop
	ldto_werp WA, 0xfa
	call Part_SetAllVoicePos
	pop xiz
	ret

VoiceChain_LinkAtEnd:
	dec 2, xsp
	pushw iz
	ld iz, wa
	ld wa, (0xf22f:16)
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x0
	jr nz, VoiceChain_LinkWritePrev
	ld wa, iz
	ldw bc, 0xffff
	jr VoiceChain_LinkWriteNext

VoiceChain_LinkWritePrev:
	ld wa, (xsp + 2)
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ld bc, (xsp + 2)

VoiceChain_LinkWriteNext:
	call PartCtrl_WriteWord
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	call Part_WriteWordBlock_OffsetAF
	popw iz
	inc 2, xsp
	ret

PartCtrl_CheckOwnerAndToggle:
	dec 6, xsp
	pushw iz
	ld (xsp + 4), de
	ld (xsp + 6), bc
	ld iz, wa
	ldw (xsp + 2), 0x0
	ld wa, iz
	call PartCtrl_ReadWord_Off1
	cp hl, (xsp + 6)
	jr z, PartCtrl_ToggleCheckDE
	setm 4, (xsp + 2)
	jr PartCtrl_AdjustAndReturn

PartCtrl_ToggleCheckDE:
	cpw (xsp + 4), 0x0
	jr nz, PartCtrl_ToggleCheckSet
	ld wa, iz
	call PartCtrl_TestBit7
	cp l, 0:i3
	jr z, PartCtrl_ToggleCheckSet
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_SetClearBit7
	setm 1, (xsp + 2)
	jr PartCtrl_AdjustAndReturn

PartCtrl_ToggleCheckSet:
	cpw (xsp + 4), 0x1
	jr nz, PartCtrl_AdjustAndReturn
	ld wa, iz
	call PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, PartCtrl_AdjustAndReturn
	ld wa, iz
	ld bc, 1:i3
	call PartCtrl_SetClearBit7
	setm 2, (xsp + 2)

PartCtrl_AdjustAndReturn:
	ld hl, (xsp + 2)
	popw iz
	inc 6, xsp
	ret

VoiceAlloc_CheckRangeAndBit7:
	cp wa, 0x4d8
	jr ugt, VoiceAlloc_RangeInvalid
	cp wa, 0:i3
	jr z, VoiceAlloc_RangeInvalid
	call PartCtrl_TestBit7
	cp l, 0:i3
	jr nz, VoiceAlloc_RangeValid

VoiceAlloc_RangeInvalid:
	ldw hl, 0xffff
	ret

VoiceAlloc_RangeValid:
	ld hl, 0:i3
	ret

VoiceAlloc_ReadCounterByte:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	ld iz, 5:i3

VoiceAlloc_CounterLoop:
	ldto_berp C, 0xf8
	extz bc
	ld wa, (xsp + 2)
	call PartCtrl_ReadByte
	cp l, 0x82
	jr z, VoiceAlloc_CounterFound
	cp l, 0x84
	jr z, VoiceAlloc_CounterFound
	inc 1, iz
	cp iz, 0xff
	jr ule, VoiceAlloc_CounterLoop

VoiceAlloc_CounterFound:
	ld hl, iz
	popw iz
	inc 2, xsp
	ret

SeqScan_CompareAndAppend:
	dec 4, xsp
	ld (xsp), e
	ld (xsp + 2), c
	ld c, (xsp + 2)
	extz bc
	ld e, (xsp)
	extz de
	calr PartCtrl_AppendToEventQueue
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	calr Part_ClearVoiceSlot
	inc 4, xsp
	ret

Part_ClearVoiceSlot:
	dec 4, xsp
	ld (xsp), c
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	ld de, 5:i3
	call Part_WriteByte_Indexed
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	cp (xsp + 2), 0x0
	jr nz, VoiceScan_EventQueueBlock
	ld a, (xsp)
	extz wa
	ld bc, 0:i3
	call Chan_SetActiveBit

VoiceScan_EventQueueBlock:
	inc 4, xsp
	ret

PartCtrl_AppendToEventQueue:
	ld hl, (0xe3b8:16)
	cp hl, 0xa
	ret nc
	ld ix, hl
	sll ix, 2
	lda xhl, (0xe390:16)
	extz xix
	add xix, xhl
	extz wa
	ld (xix), wa
	ld wa, (0xe3b8:16)
	sll wa, 2
	extz xwa
	add xwa, xhl
	ld (xwa + 2), c
	ld wa, (0xe3b8:16)
	sll wa, 2
	extz xwa
	add xwa, xhl
	ld (xwa + 3), e
	ld wa, (0xe3b8:16)
	inc 1, wa
	ld (0xe3b8:16), wa
	ret

VoiceAlloc_InitBitMap:
	lda xbc, (0x29f8:16)
	ld xwa, xbc
	lda xbc, (xbc+155:16)

VoiceAlloc_InitBitMapLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, VoiceAlloc_InitBitMapLoop
	ret

VoiceAlloc_SetBitInMap:
	dec 1, wa
	ld hl, wa
	srl hl, 3
	and wa, 0x7
	ld de, 1:i3
	and a, 0xf
	jr z, VoiceAlloc_SetBitReturn
	slaa de

VoiceAlloc_SetBitReturn:
	lda xwa, (0x29f8:16)
	extz xhl
	add xhl, xwa
	or (xhl), e
	ret

VoiceAlloc_TestBitInMap:
	dec 1, wa
	ld hl, wa
	srl hl, 3
	and wa, 0x7
	ld de, 1:i3
	and a, 0xf
	jr z, VoiceAlloc_TestBitCalcAddr
	slaa de

VoiceAlloc_TestBitCalcAddr:
	lda xwa, (0x29f8:16)
	extz xhl
	add xhl, xwa
	ld l, (xhl)
	and l, e
	ret

VoiceAlloc_TestBitRead:
	calr SeqStep_PostEventAndUpdate
	calr SeqScan_CheckBarBitAndProcess
	calr Portamento_ScanInitAndLoop
	jrl SeqTick_InitAndScanParts

VoiceAlloc_TestBitHigh:
	ld l, 0x0:opc

VoiceAlloc_TestBitResult:
	ld bc, 1:i3
	ld a, l
	and a, 0xf
	jr z, VoiceAlloc_ComputeBitmaskAddr
	slaa bc

VoiceAlloc_ComputeBitmaskAddr:
	and bc, (0xf19e:16)
	jr z, VoiceChan_StatusCheckReturn
	ld a, l
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xf
	jr nz, VoiceChan_CheckStatusReady
	ld l, 0xf:opc
	ret

VoiceChan_CheckStatusReady:
	cp a, 0x10
	jr nz, VoiceChan_StatusCheckReturn
	ld l, 0x10:opc
	ret

VoiceChan_StatusCheckReturn:
	inc 1, l
	cp l, 0x10
	jr c, VoiceAlloc_TestBitResult
	ret

VoiceChan_PostStatusEvent:
	ld a, (9696:16)
	extz wa
	lda xbc, (9542:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (9607:16)
	ld (xde), a
	ld a, (9696:16)
	extz wa
	add wa, wa
	lda xbc, (9510:16)
	ldw	(xbc+wa), (0x258e:16)
	ret

SeqScan_StoreResultB:
	ld a, (9696:16)
	extz wa
	lda xbc, (9590:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (9607:16)
	ld (xde), a
	ld a, (9696:16)
	extz wa
	add wa, wa
	lda xbc, (9558:16)
	ldw	(xbc+wa), (0x258e:16)
	ret

SeqStep_PostEventAndUpdate:
	ldw (9616:16), 0
	ld (9618:16), 0
	res 0, (0x28a6:16)
	ld (9696:16), 0
	lda xix, (9510:16)
	lda xhl, (9558:16)
	lda xde, (9542:16)
	lda xbc, (9590:16)

SeqStep_PostEventReturn:
	ld a, (9696:16)
	extz wa
	add wa, wa
	ldw	(xix+wa), 0xffff
	ld a, (9696:16)
	extz wa
	add wa, wa
	ldw	(xhl+wa), 0xffff
	ld a, (9696:16)
	extz wa
	extz xwa
	add xwa, xde
	ld (xwa), 0xff
	ld a, (9696:16)
	extz wa
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jr c, SeqStep_PostEventReturn
	ld (9696:16), 0

SeqNote_FormatAndPost:
	ld c, (9696:16)
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqNote_FormatReturn
	slaa de

SeqNote_FormatReturn:
	and de, (0xf19e:16)
	jr z, SeqScan_AdvanceToNextPart
	inc 1, c
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqScan_AdvanceToNextPart
	ldw (9614:16), 0
	call SeqData_SeekToPartStart
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xd
	jr nz, SeqScan_ParsePartEvents
	ld (9607:16), 0
	ldw (9614:16), 0
	calr SeqScan_ComparePosition14vs1052
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart

SeqScan_ParsePartEvents:
	call SeqData_ReadNextByte
	ld a, l
	and a, 0xf0
	cp a, 0x90
	jr nz, SeqNote_QueueDispatch
	calr SeqNote_QueueReturn
	jr SeqScan_ParsePartEvents

SeqNote_QueueDispatch:
	cp l, 0x81
	jr nz, SeqNote_QueueCase1
	calr SeqEvent_AccumulateQueue
	cp l, 1:i3
	jr nz, SeqScan_ParsePartEvents

SeqScan_AdvanceToNextPart:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jr c, SeqNote_FormatAndPost
	ret

SeqNote_QueueCase1:
	cp a, 0xb0
	jr nz, SeqNote_QueueCase2
	calr SeqEvent_AccLoop
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase2:
	cp l, 0x85
	jr nz, SeqNote_QueueCase3
	calr SeqScan_RefreshReadAndCompare
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase3:
	cp l, 0x86
	jr nz, SeqNote_QueueCase4
	calr SeqScan_ReadAndCompareParam
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase4:
	cp l, 0x82
	jr z, SeqScan_AdvanceToNextPart
	cp l, 0x84
	jr nz, SeqNote_QueueDefault
	calr SeqScan_CheckSeekTerminator
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueDefault:
	bit 7, l
	jr nz, SeqNote_QueueFallthrough
	calr SeqData_ReadParamBlock
	jr SeqScan_ParsePartEvents

SeqNote_QueueFallthrough:
	calr SeqScan_ReadParamCompareRange
	cp l, 1:i3
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueReturn:
	ld wa, (9830:16)
	inc 6, wa
	ld (9830:16), wa
	cp wa, 0xff
	ret ule
	sub wa, 0x100
	inc 5, wa
	ld (9830:16), wa
	ld wa, (0x28af:16)
	call PartCtrl_ReadWord
	ld (0x28af:16), hl
	ret

SeqEvent_AccumulateQueue:
	call PartCtrl_RefreshWordPeriodic
	incw 1, (9614:16)
	ld wa, (9614:16)
	cp wa, (SEQ_BEAT_COUNT:16)
	scc8 ugt, l
	ret

SeqEvent_AccLoop:
	pushw iz
	calr SeqData_ReadParamBlock
	lda xhl, (9606:16)
	bitm 2, (xhl)
	jr z, SeqEvent_AccReturn
	setm 7, (xhl + 2)

SeqEvent_AccReturn:
	cp (xhl + 2), 0x48
	jrl nz, SeqScan_StoreAndReturn
	ld a, (xhl + 3)
	and a, 0x1f
	cp a, 5:i3
	jr nz, SeqScan_StoreAndReturn
	lda xbc, (xhl + 4)
	bitm 0, (xhl)
	jr z, SeqScan_PartVoiceInit
	setm 7, (xbc)

SeqScan_PartVoiceInit:
	bitm 1, (xhl)
	jr z, SeqScan_PartVoiceEntry
	setm 7, (xhl + 5)

SeqScan_PartVoiceEntry:
	ld a, (xhl + 5)
	and a, (xbc)
	and a, 0x30
	jr z, SeqScan_StoreAndReturn
	ld bc, (9614:16)
	ld iz, bc
	lda xwa, (xhl + 1)
	cp bc, 0:i3
	jr z, SeqScan_PartVoiceAccum
	ld xde, xwa
	ld a, (xwa)
	cp a, 0x28
	jr nc, SeqScan_PartVoiceCheck
	dec 1, bc
	ld (9614:16), bc
	ld a, (xde)
	add a, 0x5f
	ld (xde), a

SeqScan_PartVoiceCheck:
	submi8 (xde), 0x28
	jr SeqScan_PartVoiceNextPart

SeqScan_PartVoiceAccum:
	ld xbc, xwa
	ld a, (xwa)
	cp a, 0x28
	jr ule, SeqScan_PartVoiceReturn
	sub a, 0x28
	ld (xbc), a
	jr SeqScan_PartVoiceNextPart

SeqScan_PartVoiceReturn:
	ld (xbc), 0x0

SeqScan_PartVoiceNextPart:
	ld wa, (9614:16)
	ld bc, (SEQ_BEAT_COUNT:16)
	cp wa, bc
	jr c, SeqScan_StoreAndUpdateBest
	cp wa, bc
	jr ugt, SeqScan_StorePositionReturn1
	ld a, (xhl + 1)
	cp a, (SEQ_BEAT_TICK:16)
	jr ugt, SeqScan_StorePositionReturn1

SeqScan_StoreAndUpdateBest:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	ld (9614:16), iz

SeqScan_StoreAndReturn:
	ld l, 0x0:opc
	jr SeqScan_PopIzAndReturn

SeqScan_StorePositionReturn1:
	ld (9614:16), iz
	ld l, 0x1:opc

SeqScan_PopIzAndReturn:
	popw iz
	ret

SeqScan_RefreshReadAndCompare:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	ld (9607:16), l
	call PartCtrl_RefreshWordPeriodic
	jr SeqScan_ComparePosition14vs1052

SeqScan_ComparePosition14vs1052:
	ld wa, (9614:16)
	cp wa, (SEQ_BEAT_COUNT:16)
	jr nc, SeqScan_CompareByteAndPosition

SeqScan_PostAndUpdateTiming:
	calr VoiceChan_PostStatusEvent
	calr SeqScan_UpdateBestPositionA
	ld l, 0x0:opc
	ret

SeqScan_CompareByteAndPosition:
	ld c, (SEQ_BEAT_TICK:16)
	ld e, c
	extz de
	cp wa, de
	jr ugt, SeqScan_ReturnOneResult
	cp (9607:16), c
	jr ule, SeqScan_PostAndUpdateTiming

SeqScan_ReturnOneResult:
	ld l, 0x1:opc
	ret

SeqScan_ReadAndCompareParam:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	ld (9607:16), l
	call PartCtrl_RefreshWordPeriodic
	ld wa, (9614:16)
	ld bc, (SEQ_BEAT_COUNT:16)
	cp wa, bc
	jr nc, SeqScan_CompareEqual

SeqScan_StoreResultAndReturn:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	ld l, 0x0:opc
	ret

SeqScan_CompareEqual:
	cp wa, bc
	jr ugt, SeqScan_CompareReturnOne
	ld a, (9607:16)
	cp a, (SEQ_BEAT_TICK:16)
	jr ule, SeqScan_StoreResultAndReturn

SeqScan_CompareReturnOne:
	ld l, 0x1:opc
	ret

SeqScan_CheckSeekTerminator:
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xd
	jr nz, SeqScan_SeekAndReturnZero
	ld l, 0x1:opc
	ret

SeqScan_SeekAndReturnZero:
	call SeqData_SeekToPartStart
	ld l, 0x0:opc
	ret

SeqScan_ReadParamCompareRange:
	calr SeqData_ReadParamBlock
	ld wa, (9614:16)
	ld bc, (SEQ_BEAT_COUNT:16)
	cp wa, bc
	jr nc, SeqScan_ParamAboveOrEqual
	ld l, 0x0:opc
	ret

SeqScan_ParamAboveOrEqual:
	cp wa, bc
	jr ule, SeqScan_ParamExactCompare
	ld l, 0x1:opc
	ret

SeqScan_ParamExactCompare:
	ld a, (9607:16)
	cp a, (SEQ_BEAT_TICK:16)
	scc8 ugt, l
	ret

SeqScan_UpdateBestPositionA:
	ld bc, (9614:16)
	ld wa, (9616:16)
	cp wa, bc
	ret ugt
	cp wa, bc
	jr nz, SeqScan_WriteBestPositionA
	ld a, (9618:16)
	cp a, (9607:16)
	ret ugt

SeqScan_WriteBestPositionA:
	ld (9616:16), bc
	ldmm8 9618, 9607
	set 0, (0x28a6:16)
	ret

SeqScan_UpdateBestPositionB:
	ld bc, (9614:16)
	ld wa, (9616:16)
	cp wa, bc
	ret ugt
	cp wa, bc
	jr nz, SeqScan_WriteBestPositionB
	ld a, (9618:16)
	cp a, (9607:16)
	ret ugt

SeqScan_WriteBestPositionB:
	ld (9616:16), bc
	ldmm8 9618, 9607
	res 0, (0x28a6:16)
	ret

SeqScan_InitAllStateVars:
	ldw (9614:16), 0
	ldw (9620:16), 0
	ldw (9622:16), 0
	ld (9696:16), 0
	ldw (9624:16), 0
	ldw (9628:16), 0
	ldw (9626:16), 0
	ldw (9630:16), 0
	ld wa, (9616:16)
	ld (9632:16), wa
	ld (9636:16), wa
	ld (9640:16), wa
	ld (9648:16), wa
	ld (9644:16), wa
	ld a, (9618:16)
	ld (9634:16), a
	ld (9638:16), a
	ld (9642:16), a
	ld (9650:16), a
	ld (9646:16), a
	ld wa, (9652:16)
	ld (9654:16), wa
	ld (9656:16), wa
	ld (9660:16), wa
	ld (9662:16), wa
	ld (9658:16), wa
	ld (1079:16), 255
	ld (1078:16), 255
	ret

SeqTick_InitAndScanParts:
	calr SeqScan_InitAllStateVars
	ld (9696:16), 0

SeqTick_ScanPartLoop:
	ld c, (9696:16)
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, SeqTick_CheckPartMask
	slaa de

SeqTick_CheckPartMask:
	and de, (0xf19e:16)
	jr z, Seq_TickReturn
	inc 1, c
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, Seq_TickReturn
	call SeqData_SeekToPartStart
	ld a, (9696:16)
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld bc, (0x28af:16)
	cp (xwa), 0xf
	jr nz, SeqTick_CheckPartType10
	ld (9624:16), bc
	ldmm16 9628, 9830
	ldmm8 9664, 9696

SeqTick_CheckPartType10:
	ld a, (9696:16)
	extz wa
	extz xwa
	add xwa, xde
	cp (xwa), 0x10
	jr nz, Seq_TickReturn
	ld (9626:16), bc
	ldmm16 9630, 9830
	ldmm8 9666, 9696

Seq_TickReturn:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jr c, SeqTick_ScanPartLoop
	ld wa, (9624:16)
	ld bc, (9626:16)
	ld de, wa
	or de, bc
	ret z
	cp wa, 0:i3
	jr nz, SeqTick_StoreFirstCandidate
	ld (0x28af:16), bc
	ldmm16 9830, 9630
	jrl SeqStep_InitParseLoop

SeqTick_StoreFirstCandidate:
	ld (0x28af:16), wa
	ldmm16 9830, 9628
	ld wa, (9626:16)
	cp wa, 0:i3
	jrl nz, SeqEvt_InitDualTrackScan
	jr Seq_InitAdvancePosition

Seq_InitAdvancePosition:
	ldw (9614:16), 0

Seq_AdvanceNoteStep:
	calr SeqData_ReadParamBlock
	cp hl, 7:i3
	jr c, Seq_AdvanceCheckEventType
	ld a, (9664:16)
	extz wa
	jrl Portamento_NotifyParams

Seq_AdvanceCheckEventType:
	lda xix, (9606:16)
	ld a, (xix)
	ldfr_berp A, 0xe2
	cp_erpb 0xe2, 0x82
	jr nz, Seq_AdvanceCheckSeek
	ld a, (9664:16)
	extz wa
	jrl SeqStep_CallHandleNoteOverflow

Seq_AdvanceCheckSeek:
	cp_erpb 0xe2, 0x84
	jr nz, Seq_AdvanceCheckBoundary
	ldmm8 9696, 9664
	call SeqData_SeekToPartStart
	jr Seq_AdvanceNoteStep

Seq_AdvanceCheckBoundary:
	ld hl, (SEQ_BEAT_COUNT:16)
	ld bc, hl
	inc 1, bc
	ld de, (9614:16)
	cp bc, de
	jr ugt, Seq_AdvanceIncrement
	ld a, (9664:16)
	extz wa
	jrl SeqStep_CallHandleNoteOverflow

Seq_AdvanceIncrement:
	cp_erpb 0xe2, 0x81
	jr nz, Seq_AdvanceCheckNoteType
	inc 1, de
	ld (9614:16), de
	jr Seq_AdvanceNoteStep

Seq_AdvanceCheckNoteType:
	ldto_berp W, 0xe2
	and w, 0xf0
	lda xbc, (xix + 2)
	cp w, 0xc0
	jr nz, Seq_AdvanceCheckTypeB0
	cp (xbc), 0x48
	jr nz, Seq_AdvanceNoteStep
	cp (xix + 3), 0x0
	jr nz, Seq_AdvanceNoteStep
	ld wa, (9616:16)
	cp wa, de
	jrl ugt, Seq_AdvanceNoteStep
	lda xbc, (xix + 1)
	cp wa, de
	jr nz, Seq_AdvanceCompareOverflow
	ld a, (9618:16)
	cp a, (xbc)
	jrl ugt, Seq_AdvanceNoteStep

Seq_AdvanceCompareOverflow:
	ld a, (9664:16)
	extz wa
	cp de, hl
	jrl ugt, SeqStep_CallHandleNoteOverflow
	cp de, hl
	jr nz, Seq_AdvanceExtractNote
	ld c, (xbc)
	cp c, (SEQ_BEAT_TICK:16)
	jrl ugt, SeqStep_CallHandleNoteOverflow

Seq_AdvanceExtractNote:
	ld w, (xix + 4)
	bit_erpb 0xe2, 0x00
	jr z, Seq_AdvanceSetBit7
	set 7, w

Seq_AdvanceSetBit7:
	ld c, (xix + 5)
	extz bc
	sll bc, 8
	ld a, w
	extz wa
	add bc, wa
	ld (9652:16), bc
	ldmm16 9632, 9614
	mrdb5 0x8c, 0x01, 0x19, 0xa2, 0x25
	ldmm16 9658, 9656
	ld (9656:16), bc
	jrl Seq_NoteCompareAndContinue

Seq_AdvanceCheckTypeB0:
	ldto_berp W, 0xe2
	and w, 0xf0
	cp w, 0xb0
	jrl nz, Seq_AdvanceNoteStep
	bit_erpb 0xe2, 0x02
	jr z, Seq_AdvanceValidateB0Params
	setm 7, (xbc)

Seq_AdvanceValidateB0Params:
	cp (xbc), 0x98
	jrl nz, Seq_AdvanceNoteStep
	ld w, (xix + 3)
	and w, 0x1f
	cp w, 1:i3
	jrl nz, Seq_AdvanceNoteStep
	ld w, (xix + 4)
	res 7, w
	cp w, 0:i3
	jrl z, Seq_AdvanceNoteStep
	cp w, 0x50
	jrl ugt, Seq_AdvanceNoteStep
	bit 6, (0xfd97:16)
	jrl z, Seq_AdvanceNoteStep
	dec 1, w
	ld c, w
	extz bc
	mul bc, 0x3b0
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf9a0
	ld hl, wa
	add hl, bc
	ld bc, hl
	extz xbc
	lda xwa, (0x1ed400:24)
	ld xde, xwa
	add xde, xbc
	mrib4 0x82, 0x19, 0xca, 0x25
	inc 1, hl
	extz xhl
	add xwa, xhl
	ld l, (xwa)
	ld (9676:16), l
	ld bc, (9614:16)
	ld wa, (9616:16)
	cp wa, bc
	jrl ugt, Seq_AdvanceNoteStep
	inc 1, xix
	cp wa, bc
	jr nz, Seq_NoteCompareAndOverflow
	ld a, (9618:16)
	cp a, (xix)
	jrl ugt, Seq_AdvanceNoteStep

Seq_NoteCompareAndOverflow:
	ld a, (9664:16)
	extz wa
	ld de, (SEQ_BEAT_COUNT:16)
	cp bc, de
	jr ugt, SeqStep_CallHandleNoteOverflow
	cp bc, de
	jr nz, Seq_NoteExtractAndStore
	ld c, (xix)
	cp c, (SEQ_BEAT_TICK:16)
	jr ule, Seq_NoteExtractAndStore

SeqStep_CallHandleNoteOverflow:
	jrl SeqStep_HandleNoteOverflow

Seq_NoteExtractAndStore:
	extz hl
	sll hl, 8
	ld a, (9674:16)
	extz wa
	add hl, wa
	ld (9652:16), hl
	ldmm16 9632, 9614
	mrib4 0x84, 0x19, 0xa2, 0x25
	ldmm16 9658, 9656
	ld (9656:16), hl

Seq_NoteCompareAndContinue:
	calr SeqTiming_CompareAndUpdateState
	jrl Seq_AdvanceNoteStep

SeqStep_InitParseLoop:
	ldw (9614:16), 0

SeqStep_ParseEventLoop:
	calr SeqData_ReadParamBlock
	ld a, (9666:16)
	extz wa
	cp hl, 7:i3
	jrl nc, Portamento_NotifyParams
	lda xiy, (9606:16)
	ld c, (xiy)
	ldfr_berp C, 0xe2
	cp_erpb 0xe2, 0x82
	jr z, SeqStep_OverflowCheck
	cp_erpb 0xe2, 0x84
	jr nz, SeqStep_CheckBoundaryB
	ldmm8 9696, 9666
	call SeqData_SeekToPartStart
	jr SeqStep_ParseEventLoop

SeqStep_CheckBoundaryB:
	ld hl, (SEQ_BEAT_COUNT:16)
	ld bc, hl
	inc 1, bc
	ld de, (9614:16)
	cp bc, de
	jr ule, SeqStep_OverflowCheck
	cp_erpb 0xe2, 0x81
	jr nz, SeqStep_CheckTypeC0
	inc 1, de
	ld (9614:16), de
	jr SeqStep_ParseEventLoop

SeqStep_CheckTypeC0:
	ldto_berp C, 0xe2
	and c, 0xf0
	ldfr_berp C, 0xe6
	lda xix, (xiy + 1)
	cp_erpb 0xe6, 0xc0
	jr nz, SeqStep_ParseEventLoop
	cp (xiy + 2), 0x48
	jr nz, SeqStep_ParseEventLoop
	cp (xiy + 3), 0x0
	jr nz, SeqStep_ParseEventLoop
	ld bc, (9616:16)
	cp bc, de
	jr ugt, SeqStep_ParseEventLoop
	cp bc, de
	jr nz, SeqStep_NoteCompareB
	ld c, (9618:16)
	cp c, (xix)
	jr ugt, SeqStep_ParseEventLoop

SeqStep_NoteCompareB:
	cp de, hl
	jr ugt, SeqStep_OverflowCheck
	cp de, hl
	jr nz, SeqStep_ExtractNoteB
	ld c, (xix)
	cp c, (SEQ_BEAT_TICK:16)
	jr ule, SeqStep_ExtractNoteB

SeqStep_OverflowCheck:
	jr SeqStep_HandleNoteOverflow

SeqStep_ExtractNoteB:
	ld a, (xiy + 4)
	ldfr_berp A, 0xe6
	bit_erpb 0xe2, 0x00
	jr z, SeqStep_SetBit7B
	set_erpb 0xe6, 0x07

SeqStep_SetBit7B:
	ld c, (xiy + 5)
	extz bc
	sll bc, 8
	ldto_berp A, 0xe6
	extz wa
	add bc, wa
	ld (9652:16), bc
	ldmm16 9632, 9614
	mrib4 0x84, 0x19, 0xa2, 0x25
	ld wa, (9656:16)
	ld (9658:16), wa
	ld (9656:16), bc
	calr SeqTiming_CompareAndUpdateState
	jrl SeqStep_ParseEventLoop

SeqStep_HandleNoteOverflow:
	dec 2, xsp
	ld (xsp), a
	cp (1079:16), 255
	jr z, SeqStep_OverflowInitBest
	ld a, (xsp)
	extz wa
	jr SeqStep_OverflowNotifyReturn

SeqStep_OverflowInitBest:
	ldmm16 9632, 9616
	ldmm8 9634, 9618
	ldmm16 9656, 9652
	calr SeqTiming_CompareAndUpdateState
	ld a, (xsp)
	extz wa

SeqStep_OverflowNotifyReturn:
	calr Portamento_NotifyParams
	inc 2, xsp
	ret

SeqEvt_InitDualTrackScan:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

SeqEvt_ReadAndDispatchLoop:
	calr SeqData_ReadParamBlock
	cp hl, 7:i3
	jr c, SeqEvt_ProcessEventCode
	cpib_erp 0xfb, 0
	jr nz, SeqEvt_ReadPartB
	ld a, (9664:16)
	extz wa
	jr SeqEvt_NotifyAndReturn

SeqEvt_ReadPartB:
	ld a, (9666:16)
	extz wa

SeqEvt_NotifyAndReturn:
	calr Portamento_NotifyParams
	jrl SeqEvt_DispatchLoop_Return

SeqEvt_ProcessEventCode:
	lda xwa, (9606:16)
	cpib_erp 0xfb, 0
	jrl nz, SeqEvt_SecondTrackProcess
	cp (xwa), 0x82
	jr nz, SeqEvt_CheckSeekOp
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckSeekOp:
	cp (9606:16), 132
	jr nz, SeqEvt_CheckBoundaryAndInit
	ldmm8 9696, 9664
	jrl SeqEvt_SeekAndContinueLoop

SeqEvt_CheckBoundaryAndInit:
	ld wa, (SEQ_BEAT_COUNT:16)
	inc 1, wa
	cp wa, (9620:16)
	jr ugt, SeqEvt_CheckIncrementOp
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckIncrementOp:
	lda xde, (9606:16)
	ld a, (xde)
	cp a, 0x81
	jr nz, SeqEvt_ExtractEventType
	incw 1, (9620:16)
	jr SeqEvt_ReadAndDispatchLoop

SeqEvt_ExtractEventType:
	ld l, a
	and l, 0xf0
	lda xbc, (xde + 2)
	cp l, 0xc0
	jrl nz, SeqEvt_CheckTypeB0Event
	cp (xbc), 0x48
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 3), 0x0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld bc, (9620:16)
	ld wa, (9616:16)
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, SeqEvt_CheckOverflowA
	ld a, (9618:16)
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

SeqEvt_CheckOverflowA:
	cp bc, (SEQ_BEAT_COUNT:16)
	jr ule, SeqEvt_CheckExactMatchA
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckExactMatchA:
	ld wa, (9620:16)
	cp wa, (SEQ_BEAT_COUNT:16)
	jr nz, SeqEvt_SaveScanAndDispatch
	ld a, (9607:16)
	cp a, (SEQ_BEAT_TICK:16)
	jr ule, SeqEvt_SaveScanAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SaveScanAndDispatch:
	ldmm16 9624, 0x28af
	ldmm16 9628, 9830
	ldmm16 9636, 9620
	lda xwa, (9606:16)
	mrdb5 0x88, 0x01, 0x19, 0xa6, 0x25
	ld l, (xwa + 4)
	bitm 0, (xwa)
	jr z, SeqEvt_SetBit7NoteA
	set 7, l

SeqEvt_SetBit7NoteA:
	ld a, (xwa + 5)
	extz wa
	sll wa, 8
	extz hl
	add wa, hl
	ld (9660:16), wa
	jrl SeqEvt_ResolveNotePosition

SeqEvt_CheckTypeB0Event:
	ld l, a
	and l, 0xf0
	cp l, 0xb0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xbc)
	bit 2, a
	jr z, SeqEvt_SetBit7B0Event
	set 7, l

SeqEvt_SetBit7B0Event:
	cp l, 0x98
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xde + 3)
	and l, 0x1f
	cp l, 1:i3
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xde + 4)
	res 7, l
	cp l, 0:i3
	jrl z, SeqEvt_ReadAndDispatchLoop
	cp l, 0x50
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	bit 6, (0xfd97:16)
	jrl z, SeqEvt_ReadAndDispatchLoop
	extz hl
	dec 1, hl
	ld bc, hl
	mul bc, 0x3b0
	ld hl, bc
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf9a0
	ld ix, wa
	add ix, hl
	ld bc, ix
	extz xbc
	lda xwa, (0x1ed400:24)
	ld xhl, xwa
	add xhl, xbc
	mrib4 0x83, 0x19, 0xca, 0x25
	inc 1, ix
	ld bc, ix
	extz xbc
	add xwa, xbc
	mrib4 0x80, 0x19, 0xcc, 0x25
	ld bc, (9620:16)
	ld wa, (9616:16)
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, SeqEvt_CheckOverflowPortamento
	ld a, (9618:16)
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

SeqEvt_CheckOverflowPortamento:
	cp bc, (SEQ_BEAT_COUNT:16)
	jr ule, SeqEvt_CheckExactPortamento
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckExactPortamento:
	ld wa, (9620:16)
	cp wa, (SEQ_BEAT_COUNT:16)
	jr nz, SeqEvt_SavePortamentoAndDispatch
	ld a, (9607:16)
	cp a, (SEQ_BEAT_TICK:16)
	jr ule, SeqEvt_SavePortamentoAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SavePortamentoAndDispatch:
	ldmm16 9624, 0x28af
	ldmm16 9628, 9830
	ldmm16 9636, 9620
	ldmm8 9638, 9607
	ld a, (9674:16)
	extz wa
	ld (9660:16), wa
	jrl SeqEvt_ResolveNotePosition

SeqEvt_SecondTrackProcess:
	cp (xwa), 0x82
	jr nz, SeqEvt_SecondTrackCheckSeek
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SecondTrackCheckSeek:
	cp (9606:16), 132
	jr nz, SeqEvt_SecondTrackCheckBound
	ldmm8 9696, 9666

SeqEvt_SeekAndContinueLoop:
	call SeqData_SeekToPartStart
	jrl SeqEvt_ReadAndDispatchLoop

SeqEvt_SecondTrackCheckBound:
	ld wa, (SEQ_BEAT_COUNT:16)
	inc 1, wa
	cp wa, (9622:16)
	jr ugt, SeqEvt_SecondTrackExtract
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SecondTrackExtract:
	lda xde, (9606:16)
	ld l, (xde)
	cp l, 0x81
	jr nz, SeqEvt_SecondTrackCheckC0
	incw 1, (9622:16)
	jrl SeqEvt_ReadAndDispatchLoop

SeqEvt_SecondTrackCheckC0:
	and l, 0xf0
	cp l, 0xc0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 2), 0x48
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 3), 0x0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld bc, (9622:16)
	ld wa, (9616:16)
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, SeqEvt_AccompCheckOverflow
	ld a, (9618:16)
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

SeqEvt_AccompCheckOverflow:
	cp bc, (SEQ_BEAT_COUNT:16)
	jr ule, SeqEvt_AccompCheckExact
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr lt, SeqEvt_DispatchLoop_Return

SeqEvt_AccompCheckExact:
	ld wa, (9622:16)
	cp wa, (SEQ_BEAT_COUNT:16)
	jr nz, SeqEvt_SaveAccompAndDispatch
	ld a, (9607:16)
	cp a, (SEQ_BEAT_TICK:16)
	jr ule, SeqEvt_SaveAccompAndDispatch
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr lt, SeqEvt_DispatchLoop_Return

SeqEvt_SaveAccompAndDispatch:
	ldmm16 9626, 0x28af
	ldmm16 9630, 9830
	ldmm16 9640, 9622
	lda xwa, (9606:16)
	mrdb5 0x88, 0x01, 0x19, 0xaa, 0x25
	ld l, (xwa + 4)
	bitm 0, (xwa)
	jr z, SeqEvt_AccompSetBit7
	set 7, l

SeqEvt_AccompSetBit7:
	ld a, (xwa + 5)
	extz wa
	sll wa, 8
	ld (9662:16), wa
	extz hl
	add (9662:16), hl

SeqEvt_ResolveNotePosition:
	calr SeqEvt_SelectNearestTiming
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jrl ge, SeqEvt_ReadAndDispatchLoop

SeqEvt_DispatchLoop_Return:
	popw_erp 0xfa
	ret

SeqVoice_InitFirstSlotSearch:
	ldw (9636:16), 0xffff
	ld (9638:16), 255
	ldmm16 9660, 9652
	jr SeqEvt_SelectNearestTiming

SeqSearch_InitNotFound:
	ldw (9640:16), 0xffff
	ld (9642:16), 255
	ldmm16 9662, 9652
	jr SeqEvt_SelectNearestTiming

SeqEvt_SelectNearestTiming:
	ld bc, (9636:16)
	cp bc, 0xffff
	jr nz, SeqEvt_CompareBothTracks
	cpw (9640:16), 0xffff
	jr nz, SeqEvt_CompareBothTracks
	ld a, (9666:16)
	extz wa
	calr SeqStep_HandleNoteOverflow
	ld l, 0xff:opc
	ret

SeqEvt_CompareBothTracks:
	ld de, (9640:16)
	cp bc, de
	jr nz, SeqEvt_CompareTrackOrder
	ld a, (9638:16)
	cp a, (9642:16)
	jr z, SeqEvt_BothTracksEqual

SeqEvt_CompareTrackOrder:
	cp bc, de
	jr c, SeqEvt_SelectTrackA
	cp bc, de
	jr nz, SeqEvt_SelectTrackB
	ld a, (9638:16)
	cp a, (9642:16)
	jr nc, SeqEvt_SelectTrackB

SeqEvt_SelectTrackA:
	ld (9632:16), bc
	ldmm8 9634, 9638
	ldmm16 9658, 9656
	ldmm16 9656, 9660
	jr SeqEvt_ApplyTrackAAndReturn

SeqEvt_SelectTrackB:
	ld (9632:16), de
	ldmm8 9634, 9642
	ldmm16 9658, 9656
	ldmm16 9656, 9662
	jr SeqEvt_ApplyTrackBAndReturn

SeqEvt_BothTracksEqual:
	cp bc, 0:i3
	jr nz, SeqEvt_TestBitAndSelect
	cp a, 0:i3
	jr z, SeqEvt_SelectTrackBDefault

SeqEvt_TestBitAndSelect:
	calr VoiceAlloc_TestBitHigh
	cp l, 0xf
	jr nz, SeqEvt_ApplyTrackAFromBit

SeqEvt_SelectTrackBDefault:
	ldmm16 9632, 9640
	ldmm8 9634, 9642
	ldmm16 9658, 9656
	ldmm16 9656, 9662

SeqEvt_ApplyTrackAAndReturn:
	calr SeqTiming_CompareAndUpdateState
	ldmm16 0x28af, 9624
	ldmm16 9830, 9628
	ld l, 0x0:opc
	jr SeqEvt_SelectionReturn

SeqEvt_ApplyTrackAFromBit:
	ldmm16 9632, 9636
	ldmm8 9634, 9638
	ldmm16 9658, 9656
	ldmm16 9656, 9660

SeqEvt_ApplyTrackBAndReturn:
	calr SeqTiming_CompareAndUpdateState
	ldmm16 0x28af, 9626
	ldmm16 9830, 9630
	ld l, 0x1:opc

SeqEvt_SelectionReturn:
	ret

Portamento_NotifyParams:
	pushw_erp 0xfa
	ld bc, (9652:16)
	ld a, c
	and a, 0xff
	ldfr_berp A, 0xfb
	srl bc, 8
	extz bc
	ld xwa, 0x28001
	ld de, 3:i3
	call SoundParam_NotifyChange
	ldto_berp C, 0xfb
	extz bc
	ld xwa, 0x28000
	ld de, 3:i3
	call SoundParam_NotifyChange
	popw_erp 0xfa
	ret

SeqTiming_CompareAndUpdateState:
	push xiz
	ld bc, (9644:16)
	ld wa, (9632:16)
	cp bc, wa
	jr ugt, Portamento_CheckPos
	cp bc, wa
	jr nz, Portamento_CheckPos
	ld a, (9646:16)
	cp a, (9634:16)
	jr ugt, Portamento_CheckPos
	ld (9648:16), bc
	ldmm8 9650, 9646
	ldmm16 9654, 9658

Portamento_CheckPos:
	ld a, (9634:16)
	ld c, (9650:16)
	cp a, c
	jr nc, Portamento_SubtractDirect
	ld wa, (9632:16)
	dec 1, wa
	sub wa, (9648:16)
	ld (9632:16), wa
	ld a, (9634:16)
	add a, 0x5f
	sub a, (9650:16)
	ld (9634:16), a
	jr Portamento_CheckZeroPosition

Portamento_SubtractDirect:
	ld wa, (9648:16)
	sub (9632:16), wa
	ld a, (9634:16)
	sub a, (9650:16)
	ld (9634:16), a

Portamento_CheckZeroPosition:
	ld bc, (9632:16)
	cp bc, 0:i3
	jr z, Portamento_CheckSmallOffset
	ld a, (9634:16)
	cp a, 0x28
	jr ugt, Portamento_SubtractOffset
	dec 1, bc
	ld (9632:16), bc
	ld a, (9634:16)
	add a, 0x5f
	ld (9634:16), a

Portamento_SubtractOffset:
	sub (9634:16), 40
	jr Portamento_DispatchAndCompute

Portamento_CheckSmallOffset:
	ld a, (9634:16)
	cp a, 0x28
	jr ule, Portamento_ClearOffset
	sub a, 0x28
	ld (9634:16), a
	jr Portamento_DispatchAndCompute

Portamento_ClearOffset:
	ld (9634:16), 0

Portamento_DispatchAndCompute:
	ld bc, (9654:16)
	ld wa, bc
	ld w, 0x0:opc
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ldfr_berp L, 0xf0
	extz ix
	ld bc, (9632:16)
	ld iy, bc
	extz xiy
	div xiy, ix
	extz xbc
	div xbc, ix
	ldto_werp WA, 0xe6
	ld e, (9650:16)
	ld (9646:16), e
	cp l, 1:i3
	jr z, Portamento_IncrementAndWrap
	cp wa, 1:i3
	jr nc, Portamento_IncrementAndWrap
	mul xiy, ix
	ld wa, (9648:16)
	add wa, iy
	ld (9648:16), wa
	ld (9644:16), wa
	jr Portamento_ComputeStepSize

Portamento_IncrementAndWrap:
	inc 1, iy
	mul xix, iy
	ld bc, (9648:16)
	add bc, ix
	ld (9648:16), bc
	ld (9644:16), bc
	ld wa, (SEQ_BEAT_COUNT:16)
	cp bc, wa
	jr ugt, Portamento_WrapOverBoundary
	cp bc, wa
	jr nz, Portamento_ComputeStepSize
	cp e, (SEQ_BEAT_TICK:16)
	jr ule, Portamento_ComputeStepSize

Portamento_WrapOverBoundary:
	ld bc, (9656:16)
	ld wa, bc
	ld w, 0x0:opc
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld bc, (9644:16)
	ld iz, bc
	ld a, (9646:16)
	ldfr_berp A, 0xfb
	cp a, (SEQ_BEAT_TICK:16)
	jr nc, Portamento_DecrementPosition
	dec 1, iz

Portamento_DecrementPosition:
	sub iz, (SEQ_BEAT_COUNT:16)
	extz hl
	cp iz, hl
	jr ule, Portamento_SubtractDirect2
	ld iy, iz
	extz xiy
	div xiy, hl
	inc 1, iy
	mul xhl, iy
	sub bc, hl
	jr Portamento_StoreFinalPosition

Portamento_SubtractDirect2:
	sub bc, hl

Portamento_StoreFinalPosition:
	ld (9644:16), bc

Portamento_ComputeStepSize:
	ld iz, (SEQ_BEAT_COUNT:16)
	ld a, (SEQ_BEAT_TICK:16)
	ldfr_berp A, 0xfb
	ld c, (9646:16)
	ldto_berp A, 0xfb
	cp a, c
	jr nc, Portamento_SubtractPosition
	dec 1, iz
	sub iz, (9644:16)
	add_erpb 0xfb, 0x5f
	jr Portamento_ComputeAndStore

Portamento_SubtractPosition:
	sub iz, (9644:16)

Portamento_ComputeAndStore:
	ldto_berp A, 0xfb
	sub a, c
	ldfr_berp A, 0xfb
	ld bc, (9656:16)
	ld wa, bc
	ld w, 0x0:opc
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld wa, iz
	div wa, l
	ld (1079:16), w
	ldto_berp A, 0xfb
	ld (1078:16), a
	ldmm16 9652, 9656
	call AccWrap_FullStop
	pop xiz
	ret

Portamento_ScanInitAndLoop:
	push xiz
	ldw (9614:16), 0
	ld (9696:16), 0
	ldw (9668:16), 0
	ld (9670:16), 0
	ld (9672:16), 0
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf980
	ld iz, wa
	add iz, 0x2e0
	ld wa, 0:i3
	ld bc, iz
	call Part_ReadByteDirect
	ldfr_berp L, 0xfb
	ld bc, iz
	inc 1, bc
	ld wa, 0:i3
	call Part_ReadByteDirect
	ldto_berp A, 0xfb
	ld (9674:16), a
	ld (9676:16), l
	extz hl
	sll hl, 8
	ld (9652:16), hl
	ldto_berp A, 0xfb
	extz wa
	add (9652:16), wa
	ld (9696:16), 0

Portamento_ScanPartLoop:
	ld c, (9696:16)
	ld de, 1:i3
	ld a, c
	and a, 0xf
	jr z, Portamento_ScanCheckPartMask
	slaa de

Portamento_ScanCheckPartMask:
	and de, (0xf19e:16)
	jr z, Portamento_ScanNextPart
	inc 1, c
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, Portamento_ScanNextPart
	call SeqData_SeekToPartStart
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xf
	call z, (SeqSearch_InitAndAdvance:24)
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	call z, (Portamento_ScanInitPosition:24)

Portamento_ScanNextPart:
	ld a, (9696:16)
	inc 1, a
	ld (9696:16), a
	cp a, 0x10
	jr c, Portamento_ScanPartLoop
	pop xiz
	ret

Portamento_ScanInitPosition:
	ldw (9614:16), 0

Portamento_ScanSeqEvents:
	ld (9672:16), 1
	calr SeqData_ReadParamBlock
	cp hl, 7:i3
	jr c, Portamento_ScanCheckEventType
	ld a, (9696:16)
	extz wa
	jrl Portamento_NotifyParams

Portamento_ScanCheckEventType:
	lda xiy, (9606:16)
	ld l, (xiy)
	cp l, 0x82
	ret z
	cp l, 0x84
	jr nz, Portamento_ScanCheckBoundary
	call SeqData_SeekToPartStart
	jr Portamento_ScanSeqEvents

Portamento_ScanCheckBoundary:
	ld de, (9616:16)
	ld wa, de
	inc 1, wa
	ld bc, (9614:16)
	cp wa, bc
	ret ule
	cp l, 0x81
	jr nz, Portamento_ScanCheckC0Type
	inc 1, bc
	ld (9614:16), bc
	jr Portamento_ScanSeqEvents

Portamento_ScanCheckC0Type:
	ld h, l
	and h, 0xf0
	lda xix, (xiy + 1)
	cp h, 0xc0
	jr nz, Portamento_ScanSeqEvents
	cp (xiy + 2), 0x48
	jr nz, Portamento_ScanSeqEvents
	cp (xiy + 3), 0x0
	jr nz, Portamento_ScanSeqEvents
	ld wa, (9668:16)
	cp wa, bc
	jr ugt, Portamento_ScanSeqEvents
	cp wa, bc
	jr nz, Portamento_ScanComparePosition
	ld a, (9670:16)
	cp a, (xix)
	jr ugt, Portamento_ScanSeqEvents

Portamento_ScanComparePosition:
	cp bc, de
	ret ugt
	cp bc, de
	jr nz, Portamento_ScanExtractNote
	ld a, (xix)
	cp a, (9618:16)
	ret ugt

Portamento_ScanExtractNote:
	ld h, (xiy + 4)
	bit 0, l
	jr z, Portamento_ScanSetBit7Note
	set 7, h

Portamento_ScanSetBit7Note:
	ld a, (xiy + 5)
	extz wa
	sll wa, 8
	ld (9652:16), wa
	ld l, h
	extz hl
	add (9652:16), hl
	ldmm16 9668, 9614
	mrib4 0x84, 0x19, 0xc6, 0x25
	jrl Portamento_ScanSeqEvents

SeqSearch_InitAndAdvance:
	ldw (9614:16), 0

SeqSearch_AdvanceToPosition:
	calr SeqData_ReadParamBlock
	cp hl, 7:i3
	jr c, SeqSearch_CheckEventType
	ld a, (9696:16)
	extz wa
	jrl Portamento_NotifyParams

SeqSearch_CheckEventType:
	lda xiy, (9606:16)
	ld d, (xiy)
	cp d, 0x82
	ret z
	cp d, 0x84
	jr nz, SeqSearch_CheckBoundary
	call SeqData_SeekToPartStart
	jr SeqSearch_AdvanceToPosition

SeqSearch_CheckBoundary:
	ld ix, (9616:16)
	ld wa, ix
	inc 1, wa
	ld bc, (9614:16)
	cp wa, bc
	ret ule
	cp d, 0x81
	jr nz, SeqSearch_CheckTypeC0
	inc 1, bc
	ld (9614:16), bc
	jr SeqSearch_AdvanceToPosition

SeqSearch_CheckTypeC0:
	ld e, d
	and e, 0xf0
	lda xwa, (xiy + 2)
	cp e, 0xc0
	jr nz, SeqSearch_CheckTypeB0
	cp (xwa), 0x48
	jr nz, SeqSearch_AdvanceToPosition
	cp (xiy + 3), 0x0
	jr nz, SeqSearch_AdvanceToPosition
	ld hl, (9668:16)
	cp hl, bc
	jr ugt, SeqSearch_AdvanceToPosition
	cp hl, bc
	jr nz, SeqSearch_CheckExactMatch
	ld a, (9670:16)
	cp a, (xiy + 1)
	jr ugt, SeqSearch_AdvanceToPosition

SeqSearch_CheckExactMatch:
	lda xwa, (xiy + 1)
	cp hl, bc
	jr nz, SeqSearch_ComparePosition
	ld e, (9670:16)
	cp e, (xwa)
	jr nz, SeqSearch_ComparePosition
	cp (9672:16), 1
	jr nz, SeqSearch_ComparePosition
	cp hl, 0:i3
	jr nz, SeqSearch_ComparePosition
	cp e, 0:i3
	jrl z, SeqSearch_AdvanceToPosition

SeqSearch_ComparePosition:
	cp bc, ix
	ret ugt
	cp bc, ix
	jr nz, SeqSearch_ExtractNote
	ld a, (xwa)
	cp a, (9618:16)
	ret ugt

SeqSearch_ExtractNote:
	ld e, (xiy + 4)
	bit 0, d
	jr z, SeqSearch_SetBit7Note
	set 7, e

SeqSearch_SetBit7Note:
	ld a, (xiy + 5)
	extz wa
	sll wa, 8
	extz de
	add wa, de
	ld (9652:16), wa
	ldmm16 9668, 9614
	mrdb5 0x8d, 0x01, 0x19, 0xc6, 0x25
	jrl SeqSearch_AdvanceToPosition

SeqSearch_CheckTypeB0:
	ld e, d
	and e, 0xf0
	cp e, 0xb0
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xwa)
	bit 2, d
	jr z, SeqSearch_ValidateB0Params
	set 7, e

SeqSearch_ValidateB0Params:
	cp e, 0x98
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xiy + 3)
	and e, 0x1f
	cp e, 1:i3
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xiy + 4)
	res 7, e
	cp e, 0:i3
	jrl z, SeqSearch_AdvanceToPosition
	cp e, 0x50
	jrl ugt, SeqSearch_AdvanceToPosition
	bit 6, (0xfd97:16)
	jrl z, SeqSearch_AdvanceToPosition
	dec 1, e
	extz de
	ld bc, de
	mul bc, 0x3b0
	ld de, bc
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf9a0
	ld hl, wa
	add hl, de
	ld bc, hl
	extz xbc
	lda xwa, (0x1ed400:24)
	ld xde, xwa
	add xde, xbc
	mrib4 0x82, 0x19, 0xca, 0x25
	inc 1, hl
	extz xhl
	add xwa, xhl
	ld e, (xwa)
	ld (9676:16), e
	ld bc, (9614:16)
	ld wa, (9668:16)
	cp wa, bc
	jrl ugt, SeqSearch_AdvanceToPosition
	lda xhl, (xiy + 1)
	cp wa, bc
	jr nz, SeqSearch_CompareOverflow
	ld a, (9670:16)
	cp a, (xhl)
	jrl ugt, SeqSearch_AdvanceToPosition

SeqSearch_CompareOverflow:
	ld wa, (9616:16)
	cp bc, wa
	ret ugt
	cp bc, wa
	jr nz, SeqSearch_StorePortamento
	ld a, (xhl)
	cp a, (9618:16)
	ret ugt

SeqSearch_StorePortamento:
	extz de
	sll de, 8
	ld a, (9674:16)
	extz wa
	add de, wa
	ld (9652:16), de
	ldmm16 9668, 9614
	mrib4 0x83, 0x19, 0xc6, 0x25
	jrl SeqSearch_AdvanceToPosition

SeqData_ReadParamBlock:
	pushw iz
	ld iz, 0:i3
	call SeqData_ReadNextByte
	ld (9606:16), l
	cp l, 0x82
	jr z, SeqData_ReadParamTerminator
	cp l, 0x84
	jr nz, SeqVoice_ReadByteLoop

SeqData_ReadParamTerminator:
	ld hl, 0:i3
	jr SeqData_ReadParamReturn2

SeqVoice_ReadByteLoop:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqData_ReadParamDone
	cp iz, 5:i3
	jr nc, SeqVoice_ReadByteLoop
	ld bc, iz
	lda xwa, (9607:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cp iz, 7:i3
	jr c, SeqVoice_ReadByteLoop
	res 0, (0x28a6:16)
	ld (1079:16), 0
	ld (1078:16), 0

SeqData_ReadParamDone:
	ld hl, iz

SeqData_ReadParamReturn2:
	popw iz
	ret

SeqScan_CheckBarBitAndProcess:
	bit 0, (0x28a6:16)
	jr nz, SeqScan_CheckBarNonZero
	ret

SeqScan_CompareBarPositions:
	calr SeqScan_SortSecondBar
	ld de, (9678:16)
	ld wa, (9684:16)
	cp wa, de
	ret ugt
	cp wa, de
	jr nc, SeqScan_CompareBarBytes

SeqScan_SaveBarPosition:
	ld (9616:16), de

SeqScan_StoreBarTickByte:
	ldmm8 9618, 9680

SeqScan_CheckBarNonZero:
	cpw (9616:16), 0
	jr nz, SeqScan_ProcessBarSlots
	cp (9618:16), 0
	ret z

SeqScan_ProcessBarSlots:
	calr SeqScan_ClearMatchingBarSlots
	ld de, 0:i3
	lda xbc, (9510:16)

SeqScan_FindActiveBarSlot:
	ld wa, de
	add wa, wa
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr nz, SeqScan_CheckBarSlotValid
	inc 1, de
	cp de, 0x10
	jr c, SeqScan_FindActiveBarSlot

SeqScan_CheckBarSlotValid:
	cp de, 0x10
	ret nc
	calr SeqScan_SortBarSlots
	ldmm16 9678, 9684
	ldmm8 9680, 9686
	ldmm8 9682, 9688
	ld de, 0:i3
	lda xbc, (9558:16)

SeqScan_FindSecondBarSlot:
	ld wa, de
	add wa, wa
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xffff
	jr nz, SeqScan_CheckSecondBarValid
	inc 1, de
	cp de, 0x10
	jr c, SeqScan_FindSecondBarSlot

SeqScan_CheckSecondBarValid:
	cp de, 0x10
	jrl c, SeqScan_CompareBarPositions
	ldmm16 9616, 9678
	jr SeqScan_StoreBarTickByte

SeqScan_CompareBarBytes:
	ld a, (9680:16)
	ld c, (9686:16)
	cp c, a
	jrl c, SeqScan_SaveBarPosition
	cp c, a
	ret ugt
	ld a, (9682:16)
	cp a, (9688:16)
	jrl nc, SeqScan_SaveBarPosition
	ret

SeqScan_ClearMatchingBarSlots:
	ld hl, 0:i3
	lda xbc, (9542:16)

SeqScan_ClearBarLoop:
	ld a, (xbc)
	cp a, (9618:16)
	jr nz, SeqScan_ClearBarNext
	ld de, hl
	add de, de
	lda xwa, (9510:16)
	extz xde
	add xde, xwa
	ld wa, (xde)
	cp wa, (9616:16)
	jr nz, SeqScan_ClearBarNext
	ldw (xde), 0xffff
	ld (xbc), 0xff

SeqScan_ClearBarNext:
	inc 1, hl
	inc 1, xbc
	cp hl, 0x10
	jr c, SeqScan_ClearBarLoop
	ret

SeqScan_SortBarSlots:
	pushw iz
	lda xix, (9510:16)
	ld iy, (xix)
	lda xhl, (9542:16)
	ld a, (xhl)
	ldfr_berp A, 0xe6
	ld iz, 1:i3

SeqScan_SortBarLoop:
	ld de, iz
	extz xde
	add xde, xhl
	ld wa, iz
	add wa, wa
	extz xwa
	add xwa, xix
	cp iy, 0xffff
	jr nz, SeqScan_SortBarCompare
	ld iy, (xwa)
	jr SeqScan_SortBarUpdateBest

SeqScan_SortBarCompare:
	ld bc, (xwa)
	cp bc, iy
	jr ugt, SeqScan_SortBarCheckFFFF
	cp bc, iy
	jr c, SeqScan_PartLoopEnd
	ld a, (xde)
	cpb_erp A, 0xe6
	jr ule, SeqScan_PartLoopEnd

SeqScan_SortBarCheckFFFF:
	cp bc, 0xffff
	jr z, SeqScan_PartLoopEnd
	ld iy, bc

SeqScan_SortBarUpdateBest:
	ld a, (xde)
	ldfr_berp A, 0xe6

SeqScan_PartLoopEnd:
	inc 1, iz
	cp iz, 0x10
	jr c, SeqScan_SortBarLoop
	popw iz
	ret

SeqScan_SortSecondBar:
	pushw iz
	lda xix, (9558:16)
	ld iy, (xix)
	lda xhl, (9590:16)
	ld a, (xhl)
	ldfr_berp A, 0xe6
	ld iz, 1:i3

SeqScan_SortSecondBarLoop:
	ld de, iz
	extz xde
	add xde, xhl
	ld wa, iz
	add wa, wa
	extz xwa
	add xwa, xix
	cp iy, 0xffff
	jr nz, SeqScan_SortSecondBarCompare
	ld iy, (xwa)
	jr SeqScan_SortSecondBarUpdate

SeqScan_SortSecondBarCompare:
	ld bc, (xwa)
	cp bc, iy
	jr ugt, SeqScan_SortSecondBarCheckFFFF
	cp bc, iy
	jr c, SeqScan_PartSearchEnd
	ld a, (xde)
	cpb_erp A, 0xe6
	jr ule, SeqScan_PartSearchEnd

SeqScan_SortSecondBarCheckFFFF:
	cp bc, 0xffff
	jr z, SeqScan_PartSearchEnd
	ld iy, bc

SeqScan_SortSecondBarUpdate:
	ld a, (xde)
	ldfr_berp A, 0xe6

SeqScan_PartSearchEnd:
	inc 1, iz
	cp iz, 0x10
	jr c, SeqScan_SortSecondBarLoop
	popw iz
	ret

SeqVoice_InitEntry:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	cp (0x2878:16), 10
	jr nz, SeqVoice_InitChannelLoop
	call SeqBufPos_WrapAround
	ldw (0xf19c:16), 0
	call Part_ClearAllVoiceChannels
	jrl SeqVoice_InitDefaultsAndReturn

SeqVoice_InitChannelLoop:
	call SeqVoice_InitAllChannelParams
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0x1c
	ld de, 0:i3
	call Part_WriteWord
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0xcb
	ld de, 0:i3
	call Part_WriteByte
	ldib_erp 0xfb, 1

SeqVoice_InitPartVoiceLoop:
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldto_berp C, 0xfb
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqVoice_InitPartVoiceLoop
	ld a, (0x00ffe3:24)
	cp a, (0x2878:16)
	jr nz, SeqVoice_InitChannelAndParams
	ld (0xf24b:16), 0
	call SeqStatus_ResetAndSendCmd
	ldw (0xf19c:16), 0
	ldib_erp 0xfb, 1

SeqVoice_InitSecondPartLoop:
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xfb
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	call Part_WriteVoiceWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqVoice_InitSecondPartLoop

SeqVoice_InitChannelAndParams:
	call SeqVoice_InitAllChannelParams

SeqVoice_InitDefaultsAndReturn:
	call SeqParams_InitDefaults
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqVoice_InitJmpNop:
	jr SeqPart_InitClear

SeqPart_InitClear:
	pushw iz
	call SeqVoice_SetDefaultParams
	ld a, (0x2877:16)
	extz wa
	call Seq_ValidatePartNumber
	cp hl, 0:i3
	jr z, SeqPart_InitSlots
	ld (SEQ_ERROR_CODE:16), 3
	jr SeqPart_InitFinish

SeqPart_InitSlots:
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	call Part_WriteByte_Indexed
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jr z, SeqPart_InitFinish
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqPart_InitFinish
	ld c, (0x2877:16)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ld wa, iz
	call Part_StealAndReallocVoices

SeqPart_InitFinish:
	call SeqVoice_InitReturnZero
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld c, (0x2877:16)
	extz bc
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld c, (0x2877:16)
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld c, (0x2877:16)
	extz bc
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ld c, (0x2877:16)
	extz bc
	ld de, 5:i3
	call Part_WriteByte_Indexed
	popw iz
	ret

SeqPart_Compare:
	dec 6, xsp
	push xiz
	calr SeqPart_InitWithValidation
	cp hl, 0:i3
	jrl nz, SeqPart_CompareLongReturn
	ld a, (0x2877:16)
	extz wa
	calr SeqPart_CheckVoiceType
	cp l, 0:i3
	jrl lt, SeqPart_CompareLongReturn
	ldfr_berp L, 0xfb
	ld a, (9858:16)
	extz wa
	calr SeqPart_CheckVoiceType
	cp l, 0:i3
	jrl lt, SeqPart_CompareLongReturn
	ld (0x27d2:16), 0
	calr SeqPart_CheckBothCompatible
	cp hl, 0:i3
	jrl nz, SeqPart_CompareLongReturn
	calr SeqPart_SetupLeftPos
	cp hl, 0:i3
	jrl nz, SeqPart_CompareLongReturn
	ldmw2 (xsp + 4), 0x27d4
	calr SeqPart_SetupRightPos
	cp hl, 0:i3
	jrl nz, SeqPart_CompareLongReturn
	ld iz, (0x27d8:16)
	calr SeqPart_HandlePartChange
	ld a, (0x2877:16)
	extz wa
	calr SeqPart_ClearSingle
	ld a, (9858:16)
	extz wa
	calr SeqPart_ClearSingle
	ldto_berp A, 0xfb
	extz wa
	calr SeqPart_AllocNewEntry
	cp hl, 0:i3
	jrl nz, SeqPart_CompareLongReturn
	calr SeqPart_CompareLeft
	ld (xsp + 8), l
	calr SeqPart_CompareRight
	ld (xsp + 6), l
	cp (0x27d2:16), 255
	jr z, SeqPart_CompareLong

SeqPart_CompareFields:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld e, (0x27d2:16)
	cp e, 3:i3
	jr nz, SeqPart_CompareNoMatch
	ld e, (xsp + 8)
	cp e, (xsp + 6)
	jr c, SeqPart_CompareCheckD
	ld e, (xsp + 8)
	cp e, (xsp + 6)
	jr nz, SeqPart_CompareCheckA
	lda xbc, (xsp + 8)
	lda xde, (xsp + 6)
	calr SeqPart_DualSwap
	jr SeqPart_CompareReturn

SeqPart_CompareCheckA:
	ld wa, bc
	jr SeqPart_CompareCheckB

SeqPart_CompareNoMatch:
	bit 0, e
	jr z, SeqPart_CompareCheckC
	ld wa, bc

SeqPart_CompareCheckB:
	calr SeqPart_WaitRightMatch
	ld (xsp + 6), l
	jr SeqPart_CompareReturn

SeqPart_CompareCheckC:
	bit 1, e
	jr z, SeqPart_CompareCheckE

SeqPart_CompareCheckD:
	calr SeqPart_WaitLeftMatch
	ld (xsp + 8), l
	jr SeqPart_CompareReturn

SeqPart_CompareCheckE:
	ld e, (0x27dc:16)
	cp e, (0x27de:16)
	jr ugt, SeqPart_CompareSetFlag
	calr SeqPart_ValidateLeft
	ld (xsp + 8), l
	jr SeqPart_CompareReturn

SeqPart_CompareSetFlag:
	ld wa, bc
	calr SeqPart_ValidateRight
	ld (xsp + 6), l

SeqPart_CompareReturn:
	cp (0x27d2:16), 255
	jr nz, SeqPart_CompareFields

SeqPart_CompareLong:
	ld wa, (xsp + 4)
	call Part_StealAndReallocVoices
	ld wa, iz
	call Part_StealAndReallocVoices
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero

SeqPart_CompareLongReturn:
	pop xiz
	inc 6, xsp
	ret

SeqPart_SetupWithDispatch:
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (0x2879:16)
	res 0, a
	res 1, a
	ld (0x2879:16), a
	call SeqVoice_SetDefaultParams
	cp (3301:16), 15
	jp ugt, (SeqVoice_InitReturnZero:24)
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xc
	jr nz, SeqPart_DispatchReturn
	set 0, (0x2879:16)

SeqPart_DispatchReturn:
	ld a, (9858:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0xc
	jr nz, SeqPart_DispatchCheckEvent
	set 1, (0x2879:16)

SeqPart_DispatchCheckEvent:
	ld a, (3301:16)
	inc 1, a
	extz wa
	calr SeqPart_EventLoop
	call SeqVoice_InitReturnZero
	ld a, (0x2879:16)
	res 0, a
	res 1, a
	ld (0x2879:16), a
	ret

SeqPart_EventLoop:
	res 2, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0
	extz wa
	ld (0x287d:16), wa
	ldw (0x287f:16), 1
	ld wa, (0x287d:16)
	extz wa
	ld bc, 0:i3
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	ret nz
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af

SeqPart_EventLoopD0:
	call SeqPart_ReadByte_Secondary
	ld a, l
	extz wa
	cp l, 0xd1
	jr z, SeqPart_EventLoopNote
	cp l, 0xd2
	jr z, SeqPart_EventLoopNote
	cp l, 0xd3
	jr z, SeqPart_EventLoopD1D2D3
	cp l, 0x86
	jr z, SeqPart_EventLoopD1D2D3
	cp l, 0x85
	jr z, SeqPart_EventLoopD1D2D3
	cp l, 0x80
	jr z, SeqPart_EventLoopD1D2D3
	cp l, 0x81
	jr z, SeqPart_EventLoopD1D2D3
	cp l, 0x82
	jr nz, SeqPart_EventLoopB0
	jrl SeqStep_CommitEvent

SeqPart_EventLoopD1D2D3:
	calr SeqStep_SkipToMeasure
	cp hl, 0:i3
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopNote:
	calr SeqStep_SkipIfLeftFlag
	cp hl, 0:i3
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopB0:
	and l, 0xf0
	cp l, 0xb0
	jr z, SeqPart_EventLoop90
	cp l, 0xc0
	jr z, SeqPart_EventLoopC0
	cp l, 0x90
	jr nz, SeqPart_EventLoopSkip
	calr SeqStep_SkipToMeasure
	cp hl, 0:i3
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopC0:
	calr SeqStep_ProcessC0Ext
	cp hl, 0:i3
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoop90:
	calr SeqStep_ProcessB0Ext
	cp hl, 0:i3
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopSkip:
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopContinue:
	ldmm8 3378, 0x2873
	jrl SeqStep_ParseRhythm

SeqPart_ClearSingle:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	ld de, 0:i3
	call Part_SetClearVoiceBit7
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld c, (xsp)
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	call Part_WriteByte_Indexed
	ld a, (xsp)
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	exts xwa
	add xwa, xbc
	ldw (xwa), 0xffff
	ldw (xwa + 2), 0x5
	inc 2, xsp
	ret

SeqPart_ClearSingleReturn:
	ret

SeqPart_CompareLeft:
	pushw_erp 0xfa
	res 0, (0x27d2:16)
	ld wa, (0x27d4:16)
	ld bc, (0x27d6:16)
	call PartCtrl_ReadByteExtended
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqPart_CompareLeftCheck
	cp_erpb 0xfb, 0x81
	jr nz, SeqPart_CompareLeftLoop

SeqPart_CompareLeftCheck:
	set 0, (0x27d2:16)
	jr SeqPart_CompareLeftDone

SeqPart_CompareLeftLoop:
	ld xwa, 0x27d4
	ld xbc, 0x27d6
	call PartCtrl_ReadWordWithBoundsCheck
	ld wa, (0x27d4:16)
	ld bc, (0x27d6:16)
	call PartCtrl_ReadByteExtended
	ld (0x27dc:16), l

SeqPart_CompareLeftDone:
	ldto_berp L, 0xfb
	popw_erp 0xfa
	ret

SeqPart_CompareRight:
	pushw_erp 0xfa
	res 1, (0x27d2:16)
	ld wa, (0x27d8:16)
	ld bc, (0x27da:16)
	call PartCtrl_ReadByteExtended
	ldfr_berp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqPart_CompareRightCheck
	cp_erpb 0xfb, 0x81
	jr nz, SeqPart_CompareRightLoop

SeqPart_CompareRightCheck:
	set 1, (0x27d2:16)
	jr SeqPart_CompareRightDone

SeqPart_CompareRightLoop:
	ld xwa, 0x27d8
	ld xbc, 0x27da
	call PartCtrl_ReadWordWithBoundsCheck
	ld wa, (0x27d8:16)
	ld bc, (0x27da:16)
	call PartCtrl_ReadByteExtended
	ld (0x27de:16), l

SeqPart_CompareRightDone:
	ldto_berp L, 0xfb
	popw_erp 0xfa
	ret

SeqPart_WaitLeftMatch:
	ld l, a

SeqPart_WaitLeftLoop:
	extz hl
	ld wa, hl
	calr SeqPart_ValidateLeft
	bit 0, (0x27d2:16)
	jr z, SeqPart_WaitLeftLoop
	ret

SeqPart_WaitRightMatch:
	ld l, a

SeqPart_WaitRightLoop:
	extz hl
	ld wa, hl
	calr SeqPart_ValidateRight
	bit 1, (0x27d2:16)
	jr z, SeqPart_WaitRightLoop
	ret

SeqPart_DualSwap:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	cp a, 0x82
	jr nz, SeqPart_DualSwapFinish
	extz wa
	call SeqPart_WriteByte_Primary
	ld (0x27d2:16), 255
	ld a, (9860:16)
	extz wa
	ld (0x287d:16), wa
	ld wa, (0x2885:16)
	ld c, a
	extz bc
	ld wa, (0x2887:16)
	call Part_WriteWordAndByte
	jr SeqPart_DualSwapReturn

SeqPart_DualSwapFinish:
	ldw wa, 0x81
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	ld xwa, 0x27d4
	ld xbc, 0x27d6
	call PartCtrl_ReadWordWithBoundsCheck
	calr SeqPart_CompareLeft
	ld (xiz), l
	ld xwa, 0x27d8
	ld xbc, 0x27da
	call PartCtrl_ReadWordWithBoundsCheck
	calr SeqPart_CompareRight
	ld xwa, (xsp + 4)
	ld (xwa), l

SeqPart_DualSwapReturn:
	pop xiz
	inc 4, xsp
	ret

SeqPart_ValidateRight:
	ld l, a
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	bit 1, (0x27d2:16)
	jr nz, SeqPart_ValidateRightCore
	call PartCtrl_AdvanceToNextEntry
	ld a, (0x27de:16)
	extz wa

SeqPart_ValidateRightLoop:
	call SeqPart_WriteByte_Primary

SeqPart_ValidateRightCore:
	ld xwa, 0x27d8
	ld xbc, 0x27da
	call PartCtrl_ReadWordWithBoundsCheck
	call PartCtrl_AdvanceToNextEntry
	ld wa, (0x27d8:16)
	ld bc, (0x27da:16)
	call PartCtrl_ReadByteExtended
	bit 7, l
	jrl nz, SeqPart_CompareRight
	extz hl
	ld wa, hl
	jr SeqPart_ValidateRightLoop

SeqPart_ValidateLeft:
	ld l, a
	extz hl
	ld wa, hl
	call SeqPart_WriteByte_Primary
	bit 0, (0x27d2:16)
	jr nz, SeqPart_ValidateLeftCore
	call PartCtrl_AdvanceToNextEntry
	ld a, (0x27dc:16)
	extz wa

SeqPart_ValidateLeftLoop:
	call SeqPart_WriteByte_Primary

SeqPart_ValidateLeftCore:
	ld xwa, 0x27d4
	ld xbc, 0x27d6
	call PartCtrl_ReadWordWithBoundsCheck
	call PartCtrl_AdvanceToNextEntry
	ld wa, (0x27d4:16)
	ld bc, (0x27d6:16)
	call PartCtrl_ReadByteExtended
	bit 7, l
	jrl nz, SeqPart_CompareLeft
	extz hl
	ld wa, hl
	jr SeqPart_ValidateLeftLoop

SeqPart_InitWithValidation:
	call SeqVoice_SetDefaultParams
	call SeqAccPlay_InitAndDispatch
	cp hl, 0:i3
	jr z, SeqPart_InitValidOk
	ld (SEQ_ERROR_CODE:16), 3
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_InitValidOk:
	ld (SEQ_ERROR_CODE:16), 0
	res 6, (0x287b:16)
	ld hl, 0:i3
	ret

SeqPart_CheckVoiceType:
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	cp l, 0xf
	jr z, SeqPart_CheckVoiceIsDrum
	cp l, 0x10
	jr z, SeqPart_CheckVoiceIsDrum
	cp l, 0xd
	ret nz

SeqPart_CheckVoiceIsDrum:
	ld (SEQ_ERROR_CODE:16), 9
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ld l, 0xff:opc
	ret

SeqPart_CheckBothCompatible:
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	ld a, (9858:16)
	dec 1, a
	ld e, a
	extz de
	extz xde
	add xde, xbc
	cp l, (xde)
	jr z, SeqPart_CompatReturn
	ld (3301:16), a
	ld a, (9858:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x73, 0x28
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	lda xbc, (SeqStep_ParseRhythm_ByteMap:24)
	ld	(0x287c:16), (xbc+wa)
	calr SeqPart_SetupWithDispatch
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_CompatReturn
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_CompatReturn:
	ld hl, 0:i3
	ret

SeqPart_SetupLeftPos:
	ld a, (0x2877:16)
	extz wa
	call Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_SetupLeftDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_SetupLeftDone:
	ldmm16 0x27d4, 0x28af
	ldw (0x27d6:16), 5
	ld hl, 0:i3
	ret

SeqPart_SetupRightPos:
	ld a, (9858:16)
	extz wa
	call Part_ValidateVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_SetupRightDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_SetupRightDone:
	ldmm16 0x27d8, 0x28af
	ldw (0x27da:16), 5
	ld hl, 0:i3
	ret

SeqPart_HandlePartChange:
	pushw_erp 0xfa
	ld a, (0x2877:16)
	ldfr_berp A, 0xfb
	ld a, (9860:16)
	cpb_erp A, 0xfb
	jr z, SeqPart_PartChangeError
	cp a, (9858:16)
	jr z, SeqPart_PartChangeError
	ld (0x2877:16), a
	calr SeqPart_InitClear
	ldto_berp A, 0xfb
	ld (0x2877:16), a

SeqPart_PartChangeError:
	popw_erp 0xfa
	ret

SeqPart_AllocNewEntry:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqPart_AllocDone
	ldw hl, 0xffff
	jr SeqPart_AllocReturn

SeqPart_AllocDone:
	ld a, (9860:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 2)
	ld (xde), a
	ld c, (9860:16)
	extz bc
	ld wa, 0:i3
	ld de, 1:i3
	call Part_SetClearVoiceBit7
	ld c, (9860:16)
	extz bc
	ld wa, 0:i3
	ld de, iz
	call Part_WriteVoiceWord
	ld (0x2887:16), iz
	ldw (0x2885:16), 5
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	ld hl, 0:i3

SeqPart_AllocReturn:
	popw iz
	inc 2, xsp
	ret

SeqPart_ByteBlockA207:
	push	qiz
	call	SeqVoice_SetDefaultParams
	call	Seq_ValidateExtended_DataBlock
	cp	hl, 0:i3
	jr	z, SeqPart_ByteBlockA207_Skip
	ld	(SEQ_ERROR_CODE:16), 3
	jrl	SeqPart_ByteBlockA207_Join
SeqPart_ByteBlockA207_Skip:
	ld	(SEQ_ERROR_CODE:16), 0
	ld	c, (0x287b:16)
	res	6, c
	ld	(0x287b:16), c
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, SeqPart_ByteBlockA207_Code_Skip3
	dec	1, a
	extz	wa
	lda	xde, (0xf1a0:16)
	extz	xwa
	add	xwa, xde
	ld	a, (xwa)
	ldfr_berp a, 251
	cp_erpb 251, 13
	jr	z, SeqPart_ByteBlockA207_Code_Skip
	cp_erpb 251, 16
	jr	nz, SeqPart_ByteBlockA207_Code_Entry
SeqPart_ByteBlockA207_Code_Skip:
	cp_erpb 251, 16
	jr	nz, SeqPart_ByteBlockA207_Code_Skip2
	set	6, c
	ld	(0x287b:16), c
SeqPart_ByteBlockA207_Code_Skip2:
	ld	a, (0x2877:16)
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockA207_Join
SeqPart_ByteBlockA207_Code_Entry:
	ldmm8	9780, 10359
	bit	6, (10363:16)
	jr	z, SeqPart_ByteBlockA207_Skip2
	cp_erpb 251, 16
	call	z, (15993425:24)
SeqPart_ByteBlockA207_Skip2:
	calr	SeqPart_ByteBlockA207_Code_Helper
	jrl	SeqPart_ByteBlockA207_Code_Entry2
SeqPart_ByteBlockA207_Code_Skip3:
	ldib_erp 250, 1
SeqPart_ByteBlockA207_Loop:
	ldto_berp a, 250
	dec 1, a
	extz	wa
	lda	xbc, (0xf1a0:16)
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	ldfr_berp a, 251
	cp_erpb 251, 13
	jr	z, SeqPart_ByteBlockA207_Code_Skip4
	cp_erpb 251, 16
	jr	nz, SeqPart_ByteBlockA207_Code_Skip6
SeqPart_ByteBlockA207_Code_Skip4:
	cp_erpb 251, 16
	jr	nz, SeqPart_ByteBlockA207_Code_Skip5
	set	6, (10363:16)
SeqPart_ByteBlockA207_Code_Skip5:
	ldto_berp a, 250
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockA207_Join
SeqPart_ByteBlockA207_Code_Skip6:
	inc1b_erp 250
	cp_erpb 250, 16
	jr	ule, SeqPart_ByteBlockA207_Loop
	call	SeqPart_SeekAllVoicesToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockA207_Join
	ld	(9782:16), 0
	ldib_erp	250, 1
	cp	(10401:16), 1
	jr	c, SeqPart_ByteBlockA207_Code_Entry2
SeqPart_ByteBlockA207_Loop2:
	ldto_berp a, 250
	ld	(9780:16), a
	bit	6, (10363:16)
	jr	z, SeqPart_ByteBlockA207_Code_Skip7
	ldto_berp a, 250
	dec 1, a
	extz	wa
	lda	xbc, (0xf1a0:16)
	extz	xwa
	add	xwa, xbc
	cp	(xwa), 16
	jr	nz, SeqPart_ByteBlockA207_Code_Skip7
	ld	(SEQ_ERROR_CODE:16), 0
	call	SeqData_VoiceSetupBlock
SeqPart_ByteBlockA207_Code_Skip7:
	calr	SeqPart_ByteBlockA207_Code_Helper
	ld	c, (SEQ_ERROR_CODE:16)
	cp	c, 0:i3
	jr	nz, SeqPart_ByteBlockA207_Code_Skip8
	bit	6, (10363:16)
	jr	z, SeqPart_ByteBlockA207_Code_Skip9
	ldto_berp a, 250
	cp a, (10381:16)
	jr	nz, SeqPart_ByteBlockA207_Code_Skip9
	cp	c, 0:i3
	jr	z, SeqPart_ByteBlockA207_Code_Skip9
SeqPart_ByteBlockA207_Code_Skip8:
	cp	c, 1:i3
	jr	z, SeqPart_ByteBlockA207_Code_Skip9
	cp	c, 8
	jr	z, SeqPart_ByteBlockA207_Code_Skip9
	cp	(9782:16), 0
	jr	nz, SeqPart_ByteBlockA207_Code_Skip9
	ld	(9782:16), c
SeqPart_ByteBlockA207_Code_Skip9:
	inc1b_erp 250
	ldto_berp a, 250
	cp a, (10401:16)
	jr	ule, SeqPart_ByteBlockA207_Loop2
SeqPart_ByteBlockA207_Code_Entry2:
	ldmm8	SEQ_ERROR_CODE, 9782
SeqPart_ByteBlockA207_Join:
	call	SeqVoice_ApplyTableEntry
	call	SeqVoice_InitReturnZero
	pop	qiz
	ret
SeqPart_ByteBlockA207_Code_Helper:
	ld	(SEQ_ERROR_CODE:16), 0
	ld	a, (9780:16)
	extz	wa
	ld	(0x287d:16), wa
	ld	a, (9780:16)
	extz	wa
	call	Part_ValidateVoiceAndSetupSeq
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	9822, 9830
	ldmm16	9820, 10415
	call	SeqVoice_FindDrumPartIndex
	ldb_d8	a, (9780)
	ldmm16	10367, 9778
	extz	wa
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	10373, 9830
	ldmm16	10375, 10415
	ld	wa, (9778:16)
	cp	wa, 1:i3
	jr	nz, SeqPart_ByteBlockA207_Code_Skip11
	add wa, (9694:16)
	ld	(0x287f:16), wa
	ld	a, (9780:16)
	ld	l, (0x288d:16)
	extz	wa
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_ByteBlockA207_Code_Skip10
	cp	a, 8
	ret	nz
	ld	(SEQ_ERROR_CODE:16), 0
	jr	SeqPart_ByteBlockA207_Code_Entry3
SeqPart_ByteBlockA207_Code_Skip10:
	call	SeqData_ReadNextByte
	cp	l, 130
	jr	nz, SeqPart_ByteBlockA207_Code_Skip11
SeqPart_ByteBlockA207_Code_Entry3:
	ldmm8	10359, 9780
	calr	SeqPart_InitClear
	ld	a, (0x2877:16)
	dec	1, a
	ld	bc, 1:i3
	and	a, 15
	jr	z, SeqPart_ByteBlockA207_Code_Helper_Skip
	.byte 0xd9, 0xfc	; sla a,bc
SeqPart_ByteBlockA207_Code_Helper_Skip:
	cpl	bc
	and	(0xffec:24), bc
	ret
SeqPart_ByteBlockA207_Code_Skip11:
	ld	l, (0x288d:16)
	ld	a, (9780:16)
	ldmm16	10367, 9778
	extz	wa
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	10415, 10375
	ldmm16	9830, 10373
	call	SeqData_ScanAllTracks
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_ByteBlockA207_Code_Skip12
	cp	a, 7:i3
	jr	z, SeqPart_ByteBlockA207_Code_Skip13
	ret
SeqPart_ByteBlockA207_Code_Skip12:
	call	SeqData_AdvancePosition
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
SeqPart_ByteBlockA207_Code_Skip13:
	ld	(SEQ_ERROR_CODE:16), 0
	ldmm16	10377, 9830
	ldmm16	10379, 10415
	lda	xwa, (0x282c:16)
	ldw	(xwa), (10379)
	ldw	(xwa+2), (10377)
	lda	xwa, (0x2830:16)
	ldw	(xwa), (10375)
	ldw	(xwa+2), (10373)
	lda	xwa, (0x2834:16)
	ldw	(xwa), (9820)
	ldw	(xwa+2), (9822)
	call	SeqPart_CopyDataPrimary
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	lda	xde, (0x2834:16)
	lda	xbc, (xde+2)
	ld	wa, (xbc)
	cp	wa, 5:i3
	jr	nz, SeqPart_ByteBlockA207_Code_Skip14
	ld	wa, (xde)
	call	PartCtrl_ReadWord_Off1
	cp	hl, 0:i3
	ret	z
	lda	xwa, (0x2834:16)
	ld	(xwa), hl
	ldw (xwa+2), 255
	jr	SeqPart_ByteBlockA207_Code_Join
SeqPart_ByteBlockA207_Code_Skip14:
	dec	1, wa
	ld	(xbc), wa
SeqPart_ByteBlockA207_Code_Join:
	lda	xde, (0x2834:16)
	ld	wa, (xde+2)
	ld	c, a
	extz	bc
	ld	wa, (xde)
	call	Part_WriteWordAndByte
	ld	wa, (0x2834:16)
	jp	Part_CheckAndReallocVoices

SeqPart_SinglePartLoad:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndMode
	cp hl, 0:i3
	jr z, SeqPart_SingleLoadCheckType
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadCheckType:
	ld (SEQ_ERROR_CODE:16), 0
	ld c, (0x287b:16)
	res 6, c
	ld (0x287b:16), c
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_SingleLoadMode1
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_SingleLoadSetup
	cp a, 0x10
	jr nz, SeqPart_SingleLoadMode0

SeqPart_SingleLoadSetup:
	cp a, 0x10
	jr nz, SeqPart_SingleLoadMode
	set 6, c
	ld (0x287b:16), c

SeqPart_SingleLoadMode:
	ld a, (0x2877:16)
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode0:
	ldmm8 9780, 0x2877
	calr SeqPart_FullLoad
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode1:
	ldib_erp 0xfb, 1

SeqPart_SingleLoadMode2:
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_SingleLoadInit
	cp a, 0x10
	jr nz, SeqPart_SingleLoadVoiceSetup

SeqPart_SingleLoadInit:
	cp a, 0x10
	jr nz, SeqPart_SingleLoadSkipDrum
	set 6, (0x287b:16)

SeqPart_SingleLoadSkipDrum:
	ldto_berp A, 0xfb
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadVoiceSetup:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_SingleLoadMode2
	call SeqPart_SeekAllVoicesToBar
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SingleLoadCleanup
	ld (9782:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_SingleLoadReturn

SeqPart_SingleLoadFinish:
	ldto_berp A, 0xfb
	ld (9780:16), a
	calr SeqPart_FullLoad
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_SingleLoadError
	cp a, 1:i3
	jr z, SeqPart_SingleLoadError
	cp a, 0x8
	jr z, SeqPart_SingleLoadError
	cp (9782:16), 0
	jr nz, SeqPart_SingleLoadError
	ld (9782:16), a

SeqPart_SingleLoadError:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (0x28a1:16)
	jr ule, SeqPart_SingleLoadFinish

SeqPart_SingleLoadReturn:
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_SingleLoadCleanup:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_FullLoad:
	dec 2, xsp
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	ldmm16 9822, 9830
	ldmm16 9820, 0x28af
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	ld a, (9808:16)
	ldw (xsp + 4), 0x0
	cp a, 0:i3
	jrl nz, SeqPart_FullLoadMode1
	cpw (9694:16), 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadWalk:
	ld iz, 0:i3
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_FullLoadComplete

SeqPart_FullLoadReadEvent:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadCheck81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadCheck81:
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadSrcMatch
	ldto_berp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz

SeqPart_FullLoadCountCheck:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jr nz, SeqPart_FullLoadReadEvent

SeqPart_FullLoadComplete:
	cpib_erp 0xfb, 1
	jrl z, SeqPart_FullLoadExit
	incw 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cp wa, (9694:16)
	jr nz, SeqPart_FullLoadWalk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadSrcMatch:
	ld a, (9780:16)
	cp a, (0x288d:16)
	jr nz, SeqPart_FullLoadValidate
	ldto_berp A, 0xfa
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqPart_FullLoadValidate

SeqPart_FullLoadProcess:
	ldto_berp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	bit_erpb 0xfa, 0x07
	jr nz, SeqPart_FullLoadCountCheck
	ldto_berp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	jr SeqPart_FullLoadProcess

SeqPart_FullLoadValidate:
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_FullLoadCountCheck
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode1:
	cp a, 1:i3
	jrl nz, SeqPart_FullLoadMode2
	cpw (9694:16), 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode1Walk:
	ld iz, 0:i3
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_FullLoadMode1Done

SeqPart_FullLoadMode1Read:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadMode1Check81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Check81:
	ldto_berp A, 0xfa
	extz wa
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadMode1Src
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz

SeqPart_FullLoadMode1Count:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jr nz, SeqPart_FullLoadMode1Read

SeqPart_FullLoadMode1Done:
	cpib_erp 0xfb, 1
	jrl z, SeqPart_FullLoadExit
	incw 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cp wa, (9694:16)
	jr nz, SeqPart_FullLoadMode1Walk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Src:
	ldto_berp C, 0xfa
	and c, 0xf0
	cp c, 0x90
	jr nz, SeqPart_FullLoadMode1Validate

SeqPart_FullLoadMode1Process:
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	bit_erpb 0xfa, 0x07
	jr z, SeqPart_FullLoadMode1Process
	jr SeqPart_FullLoadMode1Count

SeqPart_FullLoadMode1Validate:
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_FullLoadMode1Count
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2:
	cpw (9694:16), 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode2Walk:
	ld iz, 0:i3
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jrl z, SeqPart_FullLoadMode2Validate

SeqPart_FullLoadMode2Read:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadMode2Check81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode2Check81:
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadMode2Count
	ldto_berp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz
	jr SeqPart_FullLoadMode2Done

SeqPart_FullLoadMode2Count:
	ldto_berp C, 0xfa
	and c, 0xf0
	cp c, 0x90
	jr z, SeqPart_FullLoadMode2Process
	ld a, (9780:16)
	cp a, (0x288d:16)
	jr z, SeqPart_FullLoadMode2Src
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Src:
	cp c, 0xc0
	jr z, SeqPart_FullLoadMode2Process
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Process:
	ldto_berp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xfa
	bit_erpb 0xfa, 0x07
	jr z, SeqPart_FullLoadMode2Process

SeqPart_FullLoadMode2Done:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jrl nz, SeqPart_FullLoadMode2Read

SeqPart_FullLoadMode2Validate:
	cpib_erp 0xfb, 1
	jr z, SeqPart_FullLoadExit
	incw 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cp wa, (9694:16)
	jrl nz, SeqPart_FullLoadMode2Walk

SeqPart_FullLoadExit:
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x288b
	ldmw2 (xwa + 2), 0x2889
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_FullLoadErrorExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr z, SeqPart_FullLoadWriteBack
	dec 1, wa
	ld (xbc), wa
	jr SeqPart_FullLoadWriteReturn

SeqPart_FullLoadWriteBack:
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	cp hl, 0:i3
	jr z, SeqPart_FullLoadErrorExit
	lda xwa, (0x2834:16)
	ld (xwa), hl
	ldw (xwa + 2), 0xff

SeqPart_FullLoadWriteReturn:
	lda xde, (0x2834:16)
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ld wa, (0x2834:16)
	call Part_CheckAndReallocVoices

SeqPart_FullLoadErrorExit:
	pop xiz
	inc 2, xsp
	ret

SeqPart_ByteBlockA95A:
	push	qiz
	ld	a, (0x2879:16)
	res	0, a
	res	1, a
	ld	(0x2879:16), a
	res	0, (10397:16)
	res	2, (10397:16)
	call	SeqVoice_SetDefaultParams
	call	Seq_ValidateAllParams_DataBlock
	cp	hl, 0:i3
	jr	z, SeqPart_ByteBlockA95A_Skip
	ld	(SEQ_ERROR_CODE:16), 3
	calr	SeqPart_ByteBlockA95A_Code_Helper
	ldw	wa, 61
	jrl	SeqPart_ByteBlockA95A_Code_Join2
SeqPart_ByteBlockA95A_Skip:
	ld	(SEQ_ERROR_CODE:16), 0
	ld	l, (0x287b:16)
	res	6, l
	ld	(0x287b:16), l
	ld	e, (0x2877:16)
	cp	e, 127
	jrl	z, SeqPart_ByteBlockA95A_Code_Skip8
	lda	xbc, (0xf1a0:16)
	ld	a, e
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	cp e, (9858:16)
	jrl	z, SeqPart_ByteBlockA95A_Code_Skip6
	ld	e, (xwa)
	cp	e, 16
	jr	z, SeqPart_ByteBlockA95A_Code_Skip
	cp	e, 13
	jr	z, SeqPart_ByteBlockA95A_Code_Skip
	cp	e, 15
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip2
SeqPart_ByteBlockA95A_Code_Skip:
	ld	(SEQ_ERROR_CODE:16), 9
	calr	SeqPart_ByteBlockA95A_Code_Helper
	ldw	wa, 62
	jr	SeqPart_ByteBlockA95A_Code_Join2
SeqPart_ByteBlockA95A_Code_Skip2:
	cp	e, 12
	jr	nz, SeqPart_ByteBlockA95A_Code_Entry
	set	1, (10361:16)
	jr	SeqPart_ByteBlockA95A_Code_Join
SeqPart_ByteBlockA95A_Code_Entry:
	res	1, (10361:16)
SeqPart_ByteBlockA95A_Code_Join:
	ld	a, (9858:16)
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	e, (xwa)
	cp	e, 16
	jr	z, SeqPart_ByteBlockA95A_Code_Skip3
	cp	e, 13
	jr	z, SeqPart_ByteBlockA95A_Code_Skip3
	cp	e, 15
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip4
SeqPart_ByteBlockA95A_Code_Skip3:
	ld	(SEQ_ERROR_CODE:16), 9
	calr	SeqPart_ByteBlockA95A_Code_Helper
	ldw	wa, 63
	jr	SeqPart_ByteBlockA95A_Code_Join2
SeqPart_ByteBlockA95A_Code_Skip4:
	cp	e, 12
	jr	nz, SeqPart_ByteBlockA95A_Code_Entry2
	set	0, (10361:16)
	jr	SeqPart_ByteBlockA95A_Code_Entry3
SeqPart_ByteBlockA95A_Code_Entry2:
	res	0, (10361:16)
SeqPart_ByteBlockA95A_Code_Entry3:
	ldmm8	9780, 10359
	ldmm8	9810, 9858
	calr	SeqPart_DualCopySetup_Loop
	cp	(SEQ_ERROR_CODE:16), 0
	jr	z, SeqPart_ByteBlockA95A_Code_Skip5
	calr	SeqPart_ByteBlockA95A_Code_Helper
	ldw	wa, 64
SeqPart_ByteBlockA95A_Code_Join2:
	call	SeqData_SetErrorCode
	jrl	SeqPart_ByteBlockA95A_Code_Epilogue
SeqPart_ByteBlockA95A_Code_Skip5:
	ld	a, (0x2877:16)
	dec	1, a
	extz	wa
	lda	xbc, (0xf1a0:16)
	extz	xwa
	add	xwa, xbc
	ld	e, (xwa)
	ld	a, (9858:16)
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	a, (xwa)
	cp	e, a
	jrl	z, SeqPart_ByteBlockA95A_Join
	ld	(3386:16), a
	extz	wa
	lda	xde, (SeqStep_ParseRhythm_ByteMap:24)
	ld	(10364), (xde+wa)
	ldb_d8	a, (10359)
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	(3378), (xwa)
	calr	SeqPart_DualCopySetup
	jrl	SeqPart_ByteBlockA95A_Join
SeqPart_ByteBlockA95A_Code_Skip6:
	ld	e, (xwa)
	cp	e, 13
	jr	z, SeqPart_ByteBlockA95A_Skip2
	cp	e, 16
	jr	nz, SeqPart_ByteBlockA95A_Skip4
SeqPart_ByteBlockA95A_Skip2:
	cp	e, 16
	jr	nz, SeqPart_ByteBlockA95A_Skip3
	set	6, l
	ld	(0x287b:16), l
SeqPart_ByteBlockA95A_Skip3:
	ld	a, (0x2877:16)
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockA95A_Join
SeqPart_ByteBlockA95A_Skip4:
	ldmm8	9780, 10359
	ldmm8	9810, 10359
	bit	6, (10363:16)
	jr	z, SeqPart_ByteBlockA95A_Code_Skip7
	ld	c, (0x2877:16)
	dec	1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	cp	(xbc), 16
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip7
	calr	SeqPart_ByteBlockB0DE
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockA95A_Join
SeqPart_ByteBlockA95A_Code_Skip7:
	calr	SeqPart_ByteBlockAD92
	jrl	SeqPart_ByteBlockA95A_Join
SeqPart_ByteBlockA95A_Code_Skip8:
	ldib_erp 251, 1
SeqPart_ByteBlockA95A_Code_Loop:
	ldto_berp c, 251
	dec 1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	ld	e, (xbc)
	cp	e, 13
	jr	z, SeqPart_ByteBlockA95A_Code_Skip9
	cp	e, 16
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip11
SeqPart_ByteBlockA95A_Code_Skip9:
	cp	e, 16
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip10
	set	6, (10363:16)
SeqPart_ByteBlockA95A_Code_Skip10:
	ldto_berp a, 251
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockA95A_Join
SeqPart_ByteBlockA95A_Code_Skip11:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, SeqPart_ByteBlockA95A_Code_Loop
	call	SeqPart_PositionUpdateBlock
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockA95A_Join
	ld	(9782:16), 0
	ldib_erp 251, 1
SeqPart_ByteBlockA95A_Loop:
	ldto_berp a, 251
	ld	(9780:16), a
	ldto_berp a, 251
	ld	(9810:16), a
	bit	6, (10363:16)
	jr	z, SeqPart_ByteBlockA95A_Code_Skip12
	ldto_berp c, 251
	dec 1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	cp	(xbc), 16
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip12
	ld	(SEQ_ERROR_CODE:16), 0
	calr	SeqPart_ByteBlockB0DE
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip13
SeqPart_ByteBlockA95A_Code_Skip12:
	calr	SeqPart_ByteBlockAD92
SeqPart_ByteBlockA95A_Code_Skip13:
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_ByteBlockA95A_Code_Skip14
	cp	a, 1:i3
	jr	z, SeqPart_ByteBlockA95A_Code_Skip14
	cp	a, 8
	jr	z, SeqPart_ByteBlockA95A_Code_Skip14
	cp	(9782:16), 0
	jr	nz, SeqPart_ByteBlockA95A_Code_Skip14
	ld	(9782:16), a
SeqPart_ByteBlockA95A_Code_Skip14:
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, SeqPart_ByteBlockA95A_Loop
	ldmm8	SEQ_ERROR_CODE, 9782
SeqPart_ByteBlockA95A_Join:
	calr	SeqPart_ByteBlockA95A_Code_Helper
SeqPart_ByteBlockA95A_Code_Epilogue:
	pop qiz
	ret
SeqPart_ByteBlockA95A_Code_Helper:
	call	SeqPart_ByteBlockA95A_Helper
	call	SeqVoice_InitReturnZero
	res	0, (10361:16)
	res	1, (10361:16)
	res	0, (10397:16)
	res	2, (10397:16)
	ret

SeqPart_DualCopySetup:
	jrl SeqPart_MultiPartWalker
SeqPart_DualCopySetup_Loop:
	res 3, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyCheck
	ldw wa, 0x41
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyCheck:
	ldmm16 9822, 9830
	ldmm16 9820, 0x28af
	call SeqVoice_FindDrumPartIndex
	ld a, (9810:16)
	ldmm16 0x287f, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyInit
	ldw wa, 0x42
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyInit:
	ldmm16 0x2885, 9830
	ldmm16 0x2887, 0x28af
	ld l, (0x288d:16)
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyProcess
	ldw wa, 0x42
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyProcess:
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_DualCopyAdvance
	cp a, 7:i3
	jr z, SeqPart_DualCopyValidate
	ldw wa, 0x43
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyValidate:
	set 3, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_DualCopyAdvance:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyFinish
	ldw wa, 0x44
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyFinish:
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	ld c, a
	extz bc
	ld wa, (9900:16)
	call Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	call SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyReturn
	ldw wa, 0x45
	jr SeqPart_DualCopyJumpExit

SeqPart_DualCopyReturn:
	ldmm16 0x28ba, 9896
	ldmm16 0x28bc, 9898
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr ugt, SeqPart_DualCopyErrorCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	ldw (xwa + 2), 0xff
	jr SeqPart_DualCopyErrorExit

SeqPart_DualCopyErrorCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_DualCopyErrorExit:
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x28ba
	ldmw2 (xwa + 2), 0x28bc
	lda xhl, (0x2830:16)
	lda xde, (0x2834:16)
	ld wa, (xde)
	ld (xhl), wa
	lda xbc, (xde + 2)
	ld wa, (xbc)
	ld (xhl + 2), wa
	mriw4 0x92, 0x19, 0xa4, 0x26
	mriw4 0x91, 0x19, 0xa6, 0x26
	ldmw2 (xde), 0x26b0
	ldmw2 (xbc), 0x26b2
	call SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DualCopyBit3Check
	ldw wa, 0x46

SeqPart_DualCopyJumpExit:
	jp SeqData_SetErrorCode

SeqPart_DualCopyBit3Check:
	bit 3, (0x287b:16)
	ret z
	ld wa, (9894:16)
	ld c, a
	extz bc
	ld wa, (9892:16)
	call Part_WriteWordAndByte
	ld wa, (9892:16)
	jp Part_CheckAndReallocVoices
SeqPart_ByteBlockAD92:
	ld	wa, (9778:16)
	cp wa, (9862:16)
	jrl	ule, SeqPart_DualCopySetup_Loop
	res	3, (0x287b:16)
	ld	(SEQ_ERROR_CODE:16), 0
	ld	a, (9810:16)
	extz	wa
	ld	(0x287d:16), wa
	ld	a, (9810:16)
	extz	wa
	call	Part_ValidateVoiceAndSetupSeq
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	9822, 9830
	ldmm16	9820, 10415
	call	SeqVoice_FindDrumPartIndex
	ld	a, (9810:16)
	ldmm16	10367, 9862
	extz	wa
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	10373, 9830
	ldmm16	10375, 10415
	ld	l, (0x288d:16)
	ld	a, (9780:16)
	ldmm16	10367, 9778
	extz	wa
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	9906, 9830
	ldmm16	9904, 10415
	call	SeqData_ScanAllTracks
	ld	a, (SEQ_ERROR_CODE:16)
	cp	a, 0:i3
	jr	z, SeqPart_ByteBlockAD92_Entry
	cp	a, 7:i3
	ret	nz
	set	3, (0x287b:16)
	ld	(SEQ_ERROR_CODE:16), 0
SeqPart_ByteBlockAD92_Entry:
	ldmm16	9898, 9830
	ldmm16	9896, 10415
	ldmm16	9884, 9820
	ldmm16	9890, 9822
	call	SeqBuf_ComputePageLayout
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ldmm16	9900, 9912
	ld	xwa, (9914:16)
	ld	(9902:16), wa
	ld	c, a
	extz	bc
	ld	wa, (9900:16)
	call	Part_WriteWordAndByte
	lda	xwa, (0x282c:16)
	ldw	(xwa), (9820)
	ldw	(xwa+2), (9822)
	lda_d16	xwa, (10288)
	ldw	(xwa), (9900)
	ldw	(xwa+2), (9902)
	lda	xwa, (0x2834:16)
	ldw	(xwa), (10375)
	ldw	(xwa+2), (10373)
	call	SeqPart_CopyDataSecondary
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ld	xwa, 9904
	ld	xbc, 9906
	call	SeqPart_ConsumeTicksFromBuffer
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	ld	xwa, 9896
	ld	xbc, 9898
	call	SeqPart_ConsumeTicksFromBuffer
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	lda	xwa, (0x282c:16)
	ldw	(xwa), (9904)
	ldw	(xwa+2), (9906)
	lda	xwa, (0x2830:16)
	ldw	(xwa), (10375)
	ldw	(xwa+2), (10373)
	lda	xwa, (0x2834:16)
	ldw	(xwa), (9896)
	ldw	(xwa+2), (9898)
	call	SeqPart_CopyDataPrimary
	cp	(SEQ_ERROR_CODE:16), 0
	ret	nz
	bit	3, (0x287b:16)
	ret	z
	lda	xde, (0x2834:16)
	lda	xbc, (xde+2)
	ld	wa, (xbc)
	cp	wa, 5:i3
	jr	z, SeqPart_ByteBlockAD92_Skip
	dec	1, wa
	ld	(xbc), wa
	jr	SeqPart_ByteBlockAD92_Join
SeqPart_ByteBlockAD92_Skip:
	ld	wa, (xde)
	call	PartCtrl_ReadWord_Off1
	cp	hl, 0:i3
	ret	z
	lda	xwa, (0x2834:16)
	ld	(xwa), hl
	ldw	(xwa+2), 255
SeqPart_ByteBlockAD92_Join:
	lda	xde, (0x2834:16)
	ld	wa, (xde+2)
	ld	c, a
	extz	bc
	ld	wa, (xde)
	call	Part_WriteWordAndByte
	ld	wa, (0x2834:16)
	jp	Part_CheckAndReallocVoices

SeqPart_MultiPartWalker:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	ld e, (0x288d:16)
	ld l, (9858:16)
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x73, 0x28
	ldmm16 0x287f, 9862
	extz hl
	extz de
	ld wa, hl
	ld bc, de
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_WalkerExit
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ldmm16 0x288b, 0x28af
	ldmm16 0x2889, 9830
	ld iz, 0:i3
	cpw (9694:16), 0
	jr z, SeqPart_WalkerNote

SeqPart_WalkerLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_WalkerD1D2D3

SeqPart_WalkerCheckType:
	call SeqPart_ReadByte_Secondary
	cp l, 0x82
	jr z, SeqPart_WalkerD1D2D3
	ld a, l
	extz wa
	cp l, 0x81
	jr nz, SeqPart_WalkerB0
	calr SeqStep_AdvanceOneEvent
	cp hl, 0:i3
	jrl nz, SeqPart_WalkerExit
	inc1w_erp 0xfa

SeqPart_WalkerD0:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqPart_WalkerCheckType

SeqPart_WalkerD1D2D3:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cp iz, (9694:16)
	jr nz, SeqPart_WalkerLoop

SeqPart_WalkerNote:
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x288b
	ldmw2 (xwa + 2), 0x2889
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	ld c, (9858:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadWord_Indexed
	ld (0x2834:16), hl
	ld c, (9858:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadByte_Indexed
	ld (0x2836:16), hl
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_WalkerNextSet
	jrl SeqPart_WalkerExit

SeqPart_WalkerB0:
	cp l, 0xd2
	jr z, SeqPart_WalkerC0
	cp l, 0xd1
	jr nz, SeqPart_Walker90

SeqPart_WalkerC0:
	calr SeqStep_SkipIfLeftFlag
	cp hl, 0:i3
	jr z, SeqPart_WalkerD0
	jrl SeqPart_WalkerExit

SeqPart_Walker90:
	cp l, 0x85
	jr z, SeqPart_WalkerSkip
	cp l, 0x86
	jr nz, SeqPart_WalkerContinue

SeqPart_WalkerSkip:
	calr SeqStep_SkipInvertedA
	cp hl, 0:i3
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerContinue:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_WalkerBoundary
	calr SeqStep_SkipInvertedB
	cp hl, 0:i3
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerBoundary:
	cp l, 0xb0
	jr nz, SeqPart_WalkerEndCheck
	calr SeqStep_ProcessB0
	cp hl, 0:i3
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerEndCheck:
	cp l, 0xc0
	jr nz, SeqPart_WalkerAdvance
	calr SeqStep_ProcessC0
	cp hl, 0:i3
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerAdvance:
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerNextSet:
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr ugt, SeqPart_WalkerComplete
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	ldw (xwa + 2), 0xff
	jr SeqPart_WalkerReturn

SeqPart_WalkerComplete:
	dec 1, wa
	ld (xbc), wa

SeqPart_WalkerReturn:
	lda xde, (0x2834:16)
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ld wa, (0x2834:16)
	call Part_CheckAndReallocVoices

SeqPart_WalkerExit:
	pop xiz
	ret

SeqPart_ByteBlockB0DE:
	call	SeqBuf_ClearRange
	call	SeqVoice_FindDrumPartIndex
	cp	l, 0:i3
	jrl	z, SeqPart_ByteBlockB0DE_Skip
	ld	(0x2740:16), l
	ld	a, l
	extz	wa
	ld	(0x287d:16), wa
	extz	hl
	ld	wa, hl
	call	Part_ValidateVoiceAndSetupSeq
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockB0DE_Skip
	ldmm16	9822, 9830
	ldmm16	9820, 10415
	ldb_d8	l, (10048)
	ldmm16	10367, 9778
	extz	hl
	ld	wa, hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jrl	nz, SeqPart_ByteBlockB0DE_Skip
	call	SeqData_ReadNextByte
	cp	l, 130
	jrl	z, SeqPart_ByteBlockB0DE_Skip
	ldmm16	9938, 9830
	ldmm16	9940, 10415
	ldw	(9946:16), 1
	ld	wa, (9778:16)
	dec	1, wa
	ld	(9948:16), wa
	ld	xwa, 0x272c
	call	SeqVoice_SeekAndScanTracks
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockB0DE_Skip
	ld	wa, (9862:16)
	cp (9778:16), wa
	jr	z, SeqPart_ByteBlockB0DE_Entry
	ld	l, (0x2740:16)
	ld	(0x287f:16), wa
	extz	hl
	ld	wa, hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockB0DE_Skip
	call	SeqData_ReadNextByte
	cp	l, 130
	jr	z, SeqPart_ByteBlockB0DE_Entry
	ldmm16	9942, 9830
	ldmm16	9944, 10415
	ldw	(9946:16), 1
	ld	wa, (9862:16)
	dec	1, wa
	ld	(9948:16), wa
	ld	xwa, 0x2732
	call	SeqVoice_SeekAndScanTracks
	cp	(SEQ_ERROR_CODE:16), 0
	jr	nz, SeqPart_ByteBlockB0DE_Skip
SeqPart_ByteBlockB0DE_Entry:
	ldmm16	9950, 9778
	ldmm16	9952, 9862
	call	SeqBufInit_MainSetup
SeqPart_ByteBlockB0DE_Skip:
	jp	SeqPlay_WriteErrorToVoiceTable

SeqPart_DualPartLoad:
	pushw_erp 0xfa
	ld a, (0x2879:16)
	res 0, a
	res 1, a
	ld (0x2879:16), a
	res 0, (0x289d:16)
	res 2, (0x289d:16)
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartAndTempo
	cp hl, 0:i3
	jr z, SeqPart_DualLoadSetup
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadSetup:
	ld (SEQ_ERROR_CODE:16), 0
	ld l, (0x287b:16)
	res 6, l
	ld (0x287b:16), l
	ld e, (0x2877:16)
	cp e, 0x7f
	jrl nz, SeqPart_DualLoadReturn
	ldib_erp 0xfb, 0

SeqPart_DualLoadCheck:
	ldto_berp C, 0xfb
	extz bc
	lda xwa, (0xf1a0:16)
	extz xbc
	add xbc, xwa
	ld e, (xbc)
	cp e, 0xd
	jr z, SeqPart_DualLoadInit
	cp e, 0x10
	jr nz, SeqPart_DualLoadEvent

SeqPart_DualLoadInit:
	cp e, 0x10
	jr nz, SeqPart_DualLoadLoop
	set 6, (0x287b:16)

SeqPart_DualLoadLoop:
	ldto_berp A, 0xfb
	inc 1, a
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DualLoadExit

SeqPart_DualLoadEvent:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqPart_DualLoadCheck
	call SeqPart_InitMultiVoicePages
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DualLoadExit
	ld (9782:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_DualLoadComplete

SeqPart_DualLoadValidate:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	ld (9810:16), a
	bit 6, (0x287b:16)
	jr z, SeqPart_DualLoadAdvance
	ldto_berp C, 0xfb
	dec 1, c
	extz bc
	lda xwa, (0xf1a0:16)
	extz xbc
	add xbc, xwa
	cp (xbc), 0x10
	jr nz, SeqPart_DualLoadAdvance
	ld (SEQ_ERROR_CODE:16), 0
	calr SeqPart_DrumPartHandler

SeqPart_DualLoadAdvance:
	calr SeqPart_MainNavigate
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_DualLoadFinish
	cp a, 1:i3
	jr z, SeqPart_DualLoadFinish
	cp a, 0x8
	jr z, SeqPart_DualLoadFinish
	cp (9782:16), 0
	jr nz, SeqPart_DualLoadFinish
	ld (9782:16), a

SeqPart_DualLoadFinish:
	inc1b_erp 0xfb
	ldto_berp A, 0xfb
	cp a, (0x28a1:16)
	jr ule, SeqPart_DualLoadValidate

SeqPart_DualLoadComplete:
	ldmm8 SEQ_ERROR_CODE, 9782
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadReturn:
	ld a, e
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp e, (9858:16)
	jrl z, SeqPart_DualLoadPartBCheck
	ld e, (xwa)
	cp e, 0x10
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xf
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xd
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xc
	jr nz, SeqPart_DualLoadCleanup
	set 1, (0x2879:16)
	jr SeqPart_DualLoadFinal

SeqPart_DualLoadCleanup:
	res 1, (0x2879:16)

SeqPart_DualLoadFinal:
	ld a, (9858:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld e, (xwa)
	cp e, 0x10
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xf
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xd
	jr nz, SeqPart_DualLoadPartA

SeqPart_DualLoadErrorCheck:
	ld (SEQ_ERROR_CODE:16), 9
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadPartA:
	cp e, 0xc
	jr nz, SeqPart_DualLoadPartADone
	set 0, (0x2879:16)
	jr SeqPart_DualLoadPartB

SeqPart_DualLoadPartADone:
	res 0, (0x2879:16)

SeqPart_DualLoadPartB:
	ldmm8 9780, 0x2877
	ldmm8 9810, 9858
	calr SeqPart_Exchange
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DualLoadExit
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld e, (xwa)
	ld a, (9858:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp e, a
	jr z, SeqPart_DualLoadExit
	ld (3386:16), a
	extz wa
	lda xbc, (SeqStep_ParseRhythm_ByteMap:24)
	ld	(0x287c:16), (xbc+wa)
	ld (3378:16), e
	calr SeqPart_DualCopySetup
	jr SeqPart_DualLoadExit

SeqPart_DualLoadPartBCheck:
	ld e, (xwa)
	cp e, 0xd
	jr z, SeqPart_DualLoadPartBInit
	cp e, 0x10
	jr nz, SeqPart_DualLoadPartBFinish

SeqPart_DualLoadPartBInit:
	cp e, 0x10
	jr nz, SeqPart_DualLoadPartBRun
	set 6, l
	ld (0x287b:16), l

SeqPart_DualLoadPartBRun:
	ld a, (0x2877:16)
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_DualLoadExit

SeqPart_DualLoadPartBFinish:
	ldmm8 9780, 0x2877
	ldmm8 9810, 0x2877
	bit 6, (0x287b:16)
	jr z, SeqPart_DualLoadNavigate
	ld c, (0x2877:16)
	dec 1, c
	extz bc
	lda xwa, (0xf1a0:16)
	extz xbc
	add xbc, xwa
	cp (xbc), 0x10
	jr nz, SeqPart_DualLoadNavigate
	calr SeqPart_DrumPartHandler
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_DualLoadExit

SeqPart_DualLoadNavigate:
	calr SeqPart_MainNavigate

SeqPart_DualLoadExit:
	call Part_ApplyVoiceTableB
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_DrumPartHandler:
	call SeqBuf_ClearRange
	call SeqVoice_FindDrumPartIndex
	cp l, 0:i3
	jrl z, SeqPart_DrumPartJumpExit
	ld (0x2740:16), l
	ld a, l
	extz wa
	ld (0x287d:16), wa
	extz hl
	ld wa, hl
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DrumPartJumpExit
	ldmm16 9822, 9830
	ldmm16 9820, 0x28af
	ld wa, (9778:16)
	cp wa, (9862:16)
	jrl z, SeqPart_DrumPartJumpExit
	ld l, (0x2740:16)
	ld (0x287f:16), wa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DrumPartJumpExit
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_DrumPartJumpExit
	ldmm16 9938, 9830
	ldmm16 9940, 0x28af
	ldw (9946:16), 1
	ld wa, (9778:16)
	dec 1, wa
	ld (9948:16), wa
	ld xwa, 0x272c
	call SeqVoice_SeekAndScanTracks
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_DrumPartJumpExit
	ld wa, (9862:16)
	ld de, wa
	ld bc, (9694:16)
	add de, bc
	cp de, (9778:16)
	jr z, SeqPart_DrumPartBoundary
	ld l, (0x2740:16)
	add wa, (9694:16)
	ld (0x287f:16), wa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_DrumPartExtended
	cp a, 0x8
	jr nz, SeqPart_DrumPartJumpExit
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_DrumPartBoundary:
	ldmm16 9950, 9778
	ldmm16 9952, 9862
	ld wa, (9694:16)
	add (9952:16), wa
	call SeqBufInit_MainSetup
	jr SeqPart_DrumPartJumpExit

SeqPart_DrumPartExtended:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqPart_DrumPartBoundary
	ldmm16 9942, 9830
	ldmm16 9944, 0x28af
	ldw (9946:16), 1
	ld wa, (9862:16)
	add wa, (9694:16)
	dec 1, wa
	ld (9948:16), wa
	ld xwa, 0x2732
	call SeqVoice_SeekAndScanTracks
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_DrumPartBoundary

SeqPart_DrumPartJumpExit:
	jp SeqPlay_WriteErrorToVoiceTable

SeqPart_Exchange:
	pushw iz
	ld a, (0x287b:16)
	res 3, a
	res 4, a
	res 7, a
	ld (0x287b:16), a
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (9810:16)
	cp a, (9780:16)
	jr z, SeqPart_ExchangeProcess
	extz wa
	call Part_ValidateVoiceChannel
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_ExchangeProcess
	cp a, 1:i3
	jrl nz, SeqPart_ExchangeCleanup
	ld (SEQ_ERROR_CODE:16), 0
	cp (7528:16), 1
	jr nc, SeqPart_ExchangeInit
	ld (SEQ_ERROR_CODE:16), 5
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeInit:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	ld de, iz
	call Part_WriteWord_Indexed
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	ld de, 5:i3
	call Part_WriteByte_Indexed
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	ld de, 1:i3
	call Part_SetClearVoiceBit7
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	ld bc, 0:i3
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	set 7, (0x287b:16)

SeqPart_ExchangeProcess:
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_ExchangeCleanup
	ld wa, (9830:16)
	ld (9822:16), wa
	ld wa, (0x28af:16)
	ld (9820:16), wa
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3343:16)
	ldw	(xbc+wa), (0x2666:16)
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3311:16)
	ldw	(xbc+wa), (0x28af:16)
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_ExchangeCleanup
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_ExchangeValidate
	cp a, 7:i3
	jrl nz, SeqPart_ExchangeCleanup
	set 3, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_ExchangeValidate:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ld xwa, (9690:16)
	ld (0x27e0:16), xwa
	res 0, (0x282a:16)
	ld l, (0x288d:16)
	ld a, (9810:16)
	ldmm16 0x287f, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_ExchangeCheckDone
	cp a, 0x8
	jrl nz, SeqPart_ExchangeCleanup
	calr SeqPart_Splice
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_ExchangeAdvance
	calr SeqPart_RestoreState
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeAdvance:
	ldmm16 0x28af, 0x288b
	ldmm16 9830, 0x2889
	set 0, (0x282a:16)
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadByte_Indexed
	ld (9822:16), hl
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadWord_Indexed
	ld (9820:16), hl

SeqPart_ExchangeCheckDone:
	ldmm16 0x2885, 9830
	ldmm16 0x2887, 0x28af
	call SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_ExchangeUpdate
	cp a, 7:i3
	jr nz, SeqPart_ExchangeCleanup
	set 4, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_ExchangeUpdate:
	ldmm16 0x27ea, 9830
	ldmm16 0x27e8, 0x28af
	ld xwa, (9690:16)
	ld (0x27e4:16), xwa
	ld xbc, (0x27e0:16)
	ld (9690:16), xbc
	cp xwa, xbc
	jr nc, SeqPart_ExchangeFinish
	calr SeqPart_PositionForward
	jr SeqPart_ExchangeError

SeqPart_ExchangeFinish:
	cp xwa, xbc
	jr ule, SeqPart_ExchangeReturn
	calr SeqPart_PositionBackward
	jr SeqPart_ExchangeError

SeqPart_ExchangeReturn:
	calr SeqPart_PositionEqual

SeqPart_ExchangeError:
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_ExchangeJump
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x26a8
	ldmw2 (xwa + 2), 0x26aa
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x27ec
	ldmw2 (xwa + 2), 0x27ee
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26b0
	ldmw2 (xwa + 2), 0x26b2
	call SeqPart_CopyDataSecondary

SeqPart_ExchangeCleanup:
	calr SeqPart_UndoAllocOnError

SeqPart_ExchangeJump:
	popw iz
	ret

SeqPart_PositionForward:
	ld xwa, (0x27e4:16)
	sub (9690:16), xwa
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_PosForwardLoop
	bit 3, a
	jr nz, SeqPart_PosForwardLoop
	ld xwa, 1:i3
	add (9690:16), xwa

SeqPart_PosForwardLoop:
	call SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_PosForwardStep
	bit 0, (0x282a:16)
	jrl z, SeqPart_PosForwardReturn
	calr SeqPart_RestoreState
	jrl SeqPart_PosForwardReturn

SeqPart_PosForwardStep:
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	ld c, a
	extz bc
	ld wa, (9900:16)
	call Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x27e8
	ldmw2 (xwa + 2), 0x27ea
	call SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_PosForwardReturn
	lda xwa, (0x2834:16)
	mriw4 0x90, 0x19, 0xec, 0x27
	ld bc, (xwa + 2)
	ld (0x27ee:16), bc
	ld e, (0x287b:16)
	bit 4, e
	ret z
	bit 3, e
	jr nz, SeqPart_PosForwardCheck
	dec 1, bc
	ld (0x27ee:16), bc
	cp bc, 4:i3
	ret ugt
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cp wa, 0:i3
	jr z, SeqPart_PosForwardValidate
	ldw (0x27ee:16), 255
	ret

SeqPart_PosForwardCheck:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_PosForwardDone
	cp a, (9858:16)
	ret nz

SeqPart_PosForwardDone:
	bit 0, (0x282a:16)
	ret z
	bit 3, e
	ret z
	dec 1, bc
	ld (0x27ee:16), bc
	cp bc, 4:i3
	jr ugt, SeqPart_PosForwardUpdate
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cp wa, 0:i3
	jr z, SeqPart_PosForwardValidate
	ldw (0x27ee:16), 255

SeqPart_PosForwardUpdate:
	ld wa, (9898:16)
	dec 1, wa
	ld (9898:16), wa
	cp wa, 4:i3
	ret ugt
	ld wa, (9896:16)
	call PartCtrl_ReadWord_Off1
	ld (9896:16), hl
	ld wa, (9896:16)
	cp wa, 0:i3
	jr nz, SeqPart_PosForwardError

SeqPart_PosForwardValidate:
	ld (SEQ_ERROR_CODE:16), 11

SeqPart_PosForwardReturn:
	jrl SeqPart_UndoAllocOnError

SeqPart_PosForwardError:
	ldw (9898:16), 255
	ret

SeqPart_PositionBackward:
	ld xwa, (9690:16)
	ld xbc, (0x27e4:16)
	sub xbc, xwa
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_PosBackwardLoop
	bit 3, a
	jr nz, SeqPart_PosBackwardLoop
	dec 1, xbc

SeqPart_PosBackwardLoop:
	ld (9690:16), xbc
	ldmm16 0x27ec, 0x27e8
	ldmm16 0x27ee, 0x27ea
	ld xwa, 0x27ec
	ld xbc, 0x27ee
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_PosBackwardReturn
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x27e8
	ldmw2 (xwa + 2), 0x27ea
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x27ec
	ldmw2 (xwa + 2), 0x27ee
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_PosBackwardReturn
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr nz, SeqPart_PosBackwardCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_PosBackwardReturn
	ldw (xwa + 2), 0xff
	jr SeqPart_PosBackwardDone

SeqPart_PosBackwardCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_PosBackwardDone:
	bit 3, (0x287b:16)
	jr z, SeqPart_PosBackwardUpdate
	ldmm16 9822, 0x27ee
	ldmm16 9820, 0x27ec

SeqPart_PosBackwardUpdate:
	ld wa, (9822:16)
	ld c, a
	extz bc
	ld wa, (9820:16)
	call Part_WriteWordAndByte
	ld wa, (9820:16)
	call Part_CheckAndReallocVoices
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_PosBackwardReturn
	ld a, (0x287b:16)
	bit 4, a
	ret z
	bit 3, a
	ret nz
	ld wa, (0x27ee:16)
	dec 1, wa
	ld (0x27ee:16), wa
	cp wa, 5:i3
	ret nc
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cp wa, 0:i3
	jr nz, SeqPart_PosBackwardValidate
	ld (SEQ_ERROR_CODE:16), 10
	jr SeqPart_PosBackwardReturn

SeqPart_PosBackwardValidate:
	call PartCtrl_TestBit7
	cp l, 0:i3
	ret nz
	ld (SEQ_ERROR_CODE:16), 11

SeqPart_PosBackwardReturn:
	calr SeqPart_UndoAllocOnError
	ret

SeqPart_PositionEqual:
	ld bc, (0x27ea:16)
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_PosEqualSpecial
	cp a, (9858:16)
	jr nz, SeqPart_PosEqualStore

SeqPart_PosEqualSpecial:
	bit 0, (0x282a:16)
	jr z, SeqPart_PosEqualStore
	bit 3, (0x287b:16)
	jr z, SeqPart_PosEqualStore
	dec 1, bc
	cp bc, 4:i3
	jr ugt, SeqPart_PosEqualStore
	ld wa, (0x27e8:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27e8:16), hl
	ld wa, (0x27e8:16)
	cp wa, 0:i3
	jr nz, SeqPart_PosEqualSetFF
	ld (SEQ_ERROR_CODE:16), 11
	jr SeqPart_UndoAllocOnError

SeqPart_PosEqualSetFF:
	ldw bc, 0xff

SeqPart_PosEqualStore:
	ld (0x27ee:16), bc
	ldmm16 0x27ec, 0x27e8
	ret

SeqPart_UndoAllocOnError:
	bit 7, (0x287b:16)
	ret z
	cp (SEQ_ERROR_CODE:16), 0
	ret z
	ldmm8 0x2877, 9810
	calr SeqPart_InitClear
	ret

SeqPart_MainNavigate:
	dec 4, xsp
	ld wa, (9862:16)
	ld bc, (9778:16)
	cp bc, wa
	jr nz, SeqPart_NavForward
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	jrl z, SeqPart_NavExit
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	jrl SeqPart_NavExit

SeqPart_NavForward:
	cp bc, wa
	jr nc, SeqPart_NavBackward
	calr SeqPart_Exchange
	jrl SeqPart_NavExit

SeqPart_NavBackward:
	ld a, (0x287b:16)
	res 3, a
	res 4, a
	res 7, a
	ld (0x287b:16), a
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 9822, 9830
	ldmm16 9820, 0x28af
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_NavBackwardProcess
	cp a, 7:i3
	jrl nz, SeqPart_NavExit
	set 3, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_NavBackwardProcess:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ld xwa, (9690:16)
	ld (0x27e0:16), xwa
	ld l, (0x288d:16)
	ld a, (9810:16)
	ldmm16 0x287f, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 0x2885, 9830
	ldmm16 0x2887, 0x28af
	call SeqData_ScanAllTracks
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_NavBackwardValidate
	set 4, (0x287b:16)
	ld (SEQ_ERROR_CODE:16), 0

SeqPart_NavBackwardValidate:
	ldmm16 0x27ea, 9830
	ldmm16 0x27e8, 0x28af
	ld xbc, (9690:16)
	ld (0x27e4:16), xbc
	ld xbc, (0x27e0:16)
	ld (9690:16), xbc
	bit 3, (0x287b:16)
	jr z, SeqPart_NavBackwardWrite
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x26b0
	ldmw2 (xwa + 2), 0x26b2
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr nz, SeqPart_NavBackwardCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_NavExit
	ldw (xwa + 2), 0xff
	jr SeqPart_NavBackwardDone

SeqPart_NavBackwardCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_NavBackwardDone:
	lda xde, (0x2834:16)
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ld wa, (0x2834:16)
	call Part_CheckAndReallocVoices
	jrl SeqPart_NavExit

SeqPart_NavBackwardWrite:
	ld xwa, (0x27e4:16)
	cp xwa, xbc
	jrl nc, SeqPart_NavProcessWalker
	sub xbc, xwa
	ld (9690:16), xbc
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	ld c, a
	extz bc
	ld wa, (9900:16)
	call Part_WriteWordAndByte
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x26ac
	ldmw2 (xwa + 2), 0x26ae
	ld de, (9862:16)
	add de, (9694:16)
	lda xbc, (0x2834:16)
	lda xwa, (xbc + 2)
	cp de, (9778:16)
	jr ule, SeqPart_NavBackwardReturn
	ldmw2 (xbc), 0x26b0
	ldmw2 (xwa), 0x26b2
	call SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	lda xwa, (0x2834:16)
	mrdw5 0x98, 0x02, 0x19, 0xb2, 0x26
	mriw4 0x90, 0x19, 0xb0, 0x26

SeqPart_NavBackwardCleanup:
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call SeqPart_ConsumeTicksFromBuffer
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavBackwardReturn:
	ldmw2 (xbc), 0x27e8
	ldmw2 (xwa), 0x27ea
	call SeqPart_CopyDataSecondary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26b0
	ld xbc, 0x26b2
	call SeqPart_ConsumeTicksFromBuffer
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_NavBackwardCleanup
	jrl SeqPart_NavExit

SeqPart_NavProcessWalker:
	cp xwa, xbc
	jrl ule, SeqPart_NavWalkerCleanup
	sub xwa, xbc
	ld (9690:16), xwa
	ld wa, (9862:16)
	add wa, (9694:16)
	cp wa, (9778:16)
	jrl ugt, SeqPart_NavWalkerFinish
	ld xwa, 0x26b0
	ld xbc, 0x26b2
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 0x27ec, 0x27e8
	ldmm16 0x27ee, 0x27ea
	ld xwa, 0x27ec
	ld xbc, 0x27ee
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x27e8
	ldmw2 (xwa + 2), 0x27ea
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x27ec
	ldmw2 (xwa + 2), 0x27ee
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	lda xwa, (0x2834:16)
	cpw (xwa + 2), 0x5
	jr nz, SeqPart_NavWalkerValidate
	ld wa, (xwa)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_NavExit
	ldw (xwa + 2), 0xff

SeqPart_NavWalkerValidate:
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ld wa, (0x2834:16)
	call Part_CheckAndReallocVoices
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavWalkerFinish:
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	ldmw2 (xsp + 2), 0x26b0
	ldmw2 (xsp), 0x26b2
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call PartCtrl_FindActiveByLimit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	mrdw5 0x9f, 0x02, 0x19, 0xf2, 0x27
	mriw4 0x97, 0x19, 0xf0, 0x27
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x26b0
	ldmw2 (xwa + 2), 0x26b2
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x27f0
	ldmw2 (xwa + 2), 0x27f2
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x265c
	ldmw2 (xwa + 2), 0x265e
	call SeqPart_CopyDataPrimary
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_NavExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 5:i3
	jr nz, SeqPart_NavWalkerReturn
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	lda xwa, (0x2834:16)
	ld (xwa), hl
	cpw (xwa), 0x0
	jr z, SeqPart_NavExit
	ldw (xwa + 2), 0xff
	jr SeqPart_NavWalkerError

SeqPart_NavWalkerReturn:
	dec 1, wa
	ld (xbc), wa

SeqPart_NavWalkerError:
	lda xde, (0x2834:16)
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ld wa, (0x2834:16)
	call Part_CheckAndReallocVoices
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_NavExit
	ldmm16 9904, 0x27f0
	ldmm16 9906, 0x27f2

SeqPart_NavWalkerCleanup:
	lda xwa, (0x282c:16)
	ldmw2 (xwa), 0x26b0
	ldmw2 (xwa + 2), 0x26b2
	lda xwa, (0x2830:16)
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	lda xwa, (0x2834:16)
	ldmw2 (xwa), 0x26a8
	ldmw2 (xwa + 2), 0x26aa
	call SeqPart_CopyDataPrimary

SeqPart_NavExit:
	inc 4, xsp
	ret

SeqPart_CountEventsInRange:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	ld (SEQ_ERROR_CODE:16), 0
	call SeqVoice_FindDrumPartIndex
	ld a, (9810:16)
	ldw (0x287f:16), 1
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_CountBoundary
	ldmm16 0x288b, 0x28af
	ldmm16 0x2889, 9830
	ldw (xiz), 0x0

SeqPart_CountLoop:
	ld xwa, (xsp + 4)
	ldw (xwa), 0x0

SeqPart_CountCheckEnd:
	ld c, (0x288e:16)
	extz bc
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr nz, SeqPart_CountAdvance
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_CountDone
	jr SeqPart_CountBoundary

SeqPart_CountAdvance:
	call SeqPart_ReadByte_Secondary
	cp l, 0x82
	jr nz, SeqPart_CountReturn
	incw 1, (xiz)
	jr SeqPart_CountBoundary

SeqPart_CountReturn:
	cp l, 0x81
	jr nz, SeqPart_CountError
	ld xwa, (xsp + 4)
	incw 1, (xwa)
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_CountCheckEnd
	jr SeqPart_CountBoundary

SeqPart_CountError:
	call PartCtrl_AdvanceReadPos
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_CountCheckEnd

SeqPart_CountBoundary:
	pop xiz
	inc 4, xsp
	ret

SeqPart_CountDone:
	incw 1, (xiz)
	jr SeqPart_CountLoop

SeqPart_ComputeStepCount:
	pushw iz
	ld (SEQ_ERROR_CODE:16), 0
	ld c, (0x288d:16)
	ld e, (9810:16)
	ld (0x287f:16), wa
	extz de
	extz bc
	ld wa, de
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_StepCountPopReturn
	ld iz, 0:i3
	ld xwa, 0:i3
	ld (9690:16), xwa

SeqPart_StepCountLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqPart_StepCountCheck
	ld bc, iz
	extz xbc
	ld xwa, 0:i3
	ld a, (0x288e:16)
	sub xwa, xbc
	ld (9690:16), xwa
	ld iz, 0:i3
	cpw (0x27f4:16), 0
	jr z, SeqPart_StepCountError

SeqPart_StepCountAdvance:
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_StepCountReturn
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountCheck:
	cp l, 0x81
	jr nz, SeqPart_StepCountDone
	inc 1, iz

SeqPart_StepCountDone:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_StepCountLoop
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountReturn:
	inc 1, iz
	ld xwa, 0:i3
	ld a, (0x288e:16)
	add (9690:16), xwa
	cp iz, (0x27f4:16)
	jr nz, SeqPart_StepCountAdvance

SeqPart_StepCountError:
	ld xwa, 1:i3
	add (9690:16), xwa

SeqPart_StepCountPopReturn:
	popw iz
	ret

SeqPart_ReplayForward:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	ldmm16 0x288b, 9820
	ldmm16 0x2889, 9822
	ld xwa, (9690:16)
	dec 1, xwa
	ld (9690:16), xwa
	ld xiz, 0:i3
	or xwa, xwa
	jr z, SeqPart_ReplayEnd

SeqPart_ReplayLoop:
	ld wa, (0x288b:16)
	ld bc, (0x2889:16)
	ldw de, 0x81
	call PartCtrl_WriteByte_ZeroExtended
	inc 1, xiz
	ld xwa, 0x288b
	ld xbc, 0x2889
	call PartCtrl_ReadWordWithBoundsCheck
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_ReplayReturn
	cp (9690:16), xiz
	jr nz, SeqPart_ReplayLoop

SeqPart_ReplayEnd:
	ld wa, (0x288b:16)
	ld bc, (0x2889:16)
	ldw de, 0x82
	call PartCtrl_WriteByte_ZeroExtended

SeqPart_ReplayReturn:
	pop xiz
	ret

SeqPart_Splice:
	dec 4, xsp
	ld (SEQ_ERROR_CODE:16), 0
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr SeqPart_CountEventsInRange
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SpliceReturn
	ld wa, (9862:16)
	sub wa, (xsp + 2)
	dec 1, wa
	ld (0x27f4:16), wa
	ld wa, (xsp + 2)
	calr SeqPart_ComputeStepCount
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	calr SeqPart_ReplayForward
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_SpliceReturn
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ldmm16 9822, 0x2889
	ld wa, (0x288b:16)
	ld (9820:16), wa
	ld bc, (9822:16)
	extz bc
	call Part_WriteWordAndByte

SeqPart_SpliceReturn:
	inc 4, xsp
	ret

SeqPart_RestoreState:
	ld c, (9810:16)
	extz bc
	ld wa, 0:i3
	call Part_ReadVoiceBit7
	cp l, 0:i3
	ret z
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3311:16)
	ldw	(0x28af:16), (xbc+wa)
	ldmm16 9820, 0x28af
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3343:16)
	ldw	(0x2666:16), (xbc+wa)
	ldmm16 9822, 9830
	ldw wa, 0x82
	call PartCtrl_WriteByte_Indexed
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld wa, (9822:16)
	ld c, a
	extz bc
	ld wa, (9820:16)
	call Part_WriteWordAndByte
	ld wa, (9820:16)
	jp Part_CheckAndReallocVoices

SeqPart_TransposeSetup:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_TransposeCheck
	extz wa
	call Seq_ValidatePartNumber
	cp hl, 0:i3
	jr nz, SeqPart_TransposeInit

SeqPart_TransposeCheck:
	ld wa, (9778:16)
	call Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqPart_TransposeInit
	ld wa, (9694:16)
	call Seq_ValidateTempoValue
	cp hl, 0:i3
	jr nz, SeqPart_TransposeInit
	ld a, (9812:16)
	cp a, 0x80
	jr nz, SeqPart_TransposeMode

SeqPart_TransposeInit:
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_TransposeExit

SeqPart_TransposeMode:
	ld (SEQ_ERROR_CODE:16), 0
	res 6, (0x287b:16)
	ld c, (0x2877:16)
	cp c, 0x7f
	jr z, SeqPart_TransposeBoundsOk
	ld a, c
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_TransposeSetBounds
	cp a, 0xf
	jr z, SeqPart_TransposeSetBounds
	cp a, 0x10
	jr nz, SeqPart_TransposeValidate

SeqPart_TransposeSetBounds:
	ld (SEQ_ERROR_CODE:16), 9
	jr SeqPart_TransposeExit

SeqPart_TransposeValidate:
	ld (9780:16), c
	calr SeqPart_TransposeWalker
	jr SeqPart_TransposeExit

SeqPart_TransposeBoundsOk:
	ldib_erp 0xfb, 0

SeqPart_TransposeStartWalk:
	ldto_berp A, 0xfb
	inc 1, a
	ld (9780:16), a
	ldto_berp A, 0xfb
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_TransposeFinish
	cp a, 0xf
	jr z, SeqPart_TransposeFinish
	cp a, 0x10
	call nz, (SeqPart_TransposeWalker:24)

SeqPart_TransposeFinish:
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_TransposeReturn
	cp a, 1:i3
	jr z, SeqPart_TransposeReturn
	cp (9782:16), 0
	jr nz, SeqPart_TransposeReturn
	ld (9782:16), a

SeqPart_TransposeReturn:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqPart_TransposeStartWalk
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_TransposeExit:
	call Part_ApplyVoiceTableC
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_TransposeWalker:
	push xiz
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_TransposePopReturn
	ld iz, 0:i3
	cpw (9694:16), 0
	jrl z, SeqPart_TransposePopReturn

SeqPart_TransposeWalkLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_TransposeClampHigh

SeqPart_TransposeCheckNote:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_TransposePopReturn
	cp l, 0x81
	jr nz, SeqPart_TransposeClampLow
	inc1w_erp 0xfa
	call SeqData_AdvancePosition

SeqPart_TransposeApply:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqPart_TransposeCheckNote

SeqPart_TransposeClampHigh:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_TransposeError
	jr SeqPart_TransposePopReturn

SeqPart_TransposeClampLow:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_TransposeDone
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_ReadNextByte
	extz hl
	ld a, (9812:16)
	exts wa
	add hl, wa
	jr ge, SeqPart_TransposeSkip
	ld hl, 0:i3
	jr SeqPart_TransposeAdvance

SeqPart_TransposeSkip:
	cp hl, 0x7f
	jr le, SeqPart_TransposeAdvance
	ldw hl, 0x7f

SeqPart_TransposeAdvance:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed

SeqPart_TransposeDone:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_TransposeApply
	jr SeqPart_TransposePopReturn

SeqPart_TransposeError:
	cp iz, (9694:16)
	jrl nz, SeqPart_TransposeWalkLoop

SeqPart_TransposePopReturn:
	pop xiz
	ret

SeqPart_VelocityEditSetup:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndKey
	cp hl, 0:i3
	jr z, SeqPart_VelEditCheck
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_VelEditReturn

SeqPart_VelEditCheck:
	ld (SEQ_ERROR_CODE:16), 0
	res 6, (0x287b:16)
	ld c, (0x2877:16)
	cp c, 0x7f
	jr z, SeqPart_VelEditMode
	ld a, c
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VelEditInit
	cp a, 0xf
	jr z, SeqPart_VelEditInit
	cp a, 0x10
	jr z, SeqPart_VelEditInit
	ld (9780:16), c
	calr SeqPart_VelExprEdit
	calr SeqPart_BufferSwap
	jr SeqPart_VelEditReturn

SeqPart_VelEditInit:
	ld (SEQ_ERROR_CODE:16), 9
	jr SeqPart_VelEditReturn

SeqPart_VelEditMode:
	ldib_erp 0xfb, 1

SeqPart_VelEditBounds:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VelEditValidate
	cp a, 0xf
	jr z, SeqPart_VelEditValidate
	cp a, 0x10
	jr z, SeqPart_VelEditValidate
	calr SeqPart_VelExprEdit
	calr SeqPart_BufferSwap

SeqPart_VelEditValidate:
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_VelEditStartWalk
	cp a, 1:i3
	jr z, SeqPart_VelEditStartWalk
	cp (9782:16), 0
	jr nz, SeqPart_VelEditStartWalk
	ld (9782:16), a

SeqPart_VelEditStartWalk:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VelEditBounds
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_VelEditReturn:
	call AppEvent_ExtendedHandler
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_VelocityCurveCalc:
	ld a, (9726:16)
	ld c, (9784:16)
	extz wa
	cp wa, 0:i3
	jrl mi, SeqPart_VelRangeToZone
	cp wa, 0xa
	jrl gt, SeqPart_VelRangeToZone
	add wa, wa
	lda xix, (SeqPart_VelocityCurveCalc_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SeqPart_VelCurveData:24)
	jp	t, (xix+wa)

SeqPart_VelCurveData:
	ld	(9792:16), 48
	ld	(9794:16), 48
	jrl	SeqPart_VelocityCurveCalc_Join5
SeqPart_VelocityCurveCalc_Case2:
	ld	a, c
	ld	e, 0:opc
	cp	c, 24
	jr	c, SeqPart_VelocityCurveCalc_Skip6
	cp	a, 72
	jr	nc, SeqPart_VelocityCurveCalc_Skip6
	ld	e, 1:opc
SeqPart_VelocityCurveCalc_Skip6:
	extz	de
	lda	xbc, (SeqPart_VelCurveData_Table:24)
	ld	(9792), (xbc+de)
	ld	xbc, SeqPart_VelCurveData_Table_6
	ld	(9794), (xbc+de)
	jrl	SeqPart_VelocityCurveCalc_Join5
SeqPart_VelocityCurveCalc_Case4:
	ld	a, c
	cp	c, 12
	jr	nc, SeqPart_VelocityCurveCalc_Skip7
	ld	e, 0:opc
	jr	SeqPart_VelocityCurveCalc_Join3
SeqPart_VelocityCurveCalc_Skip7:
	cp	a, 36
	jr	nc, SeqPart_VelocityCurveCalc_Skip8
	ld	e, 1:opc
	jr	SeqPart_VelocityCurveCalc_Join3
SeqPart_VelocityCurveCalc_Skip8:
	cp	a, 60
	jr	nc, SeqPart_VelocityCurveCalc_Skip9
	ld	e, 2:opc
	jr	SeqPart_VelocityCurveCalc_Join3
SeqPart_VelocityCurveCalc_Skip9:
	ld	e, 0:opc
	cp	a, 84
	jr	nc, SeqPart_VelocityCurveCalc_Join3
	ld	e, 3:opc
SeqPart_VelocityCurveCalc_Join3:
	extz	de
	lda	xbc, (SeqPart_VelCurveData_Table_2:24)
	ld	(9792), (xbc+de)
	ld	xbc, SeqPart_VelCurveData_Table_7
	ld	(9794), (xbc+de)
	jrl	SeqPart_VelocityCurveCalc_Join5
SeqPart_VelocityCurveCalc_Case6:
	ld	a, c
	cp	c, 6:i3
	jr	nc, SeqPart_VelocityCurveCalc_Skip10
	ld	e, 0:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip10:
	cp	a, 18
	jr	nc, SeqPart_VelocityCurveCalc_Skip11
	ld	e, 1:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip11:
	cp	a, 30
	jr	nc, SeqPart_VelocityCurveCalc_Skip12
	ld	e, 2:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip12:
	cp	a, 42
	jr	nc, SeqPart_VelocityCurveCalc_Skip
	ld	e, 3:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip:
	cp	a, 54
	jr	nc, SeqPart_VelocityCurveCalc_Skip2
	ld	e, 4:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip2:
	cp	a, 66
	jr	nc, SeqPart_VelocityCurveCalc_Skip3
	ld	e, 5:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip3:
	cp	a, 78
	jr	nc, SeqPart_VelocityCurveCalc_Skip13
	ld	e, 6:opc
	jr	SeqPart_VelocityCurveCalc_Join
SeqPart_VelocityCurveCalc_Skip13:
	ld	e, 0:opc
	cp	a, 90
	jr	nc, SeqPart_VelocityCurveCalc_Join
	ld	e, 7:opc
SeqPart_VelocityCurveCalc_Join:
	extz	de
	lda	xbc, (SeqPart_VelCurveData_Table_3:24)
	ld	(9792), (xbc+de)
	ld	xbc, SeqPart_VelCurveData_Data
	ld	(9794), (xbc+de)
	jrl	SeqPart_VelocityCurveCalc_Join5
SeqPart_VelocityCurveCalc_Case8:
	ld	a, c
	cp	c, 16
	jr	nc, SeqPart_VelocityCurveCalc_Skip14
	ld	e, 0:opc
	jr	SeqPart_VelocityCurveCalc_Join4
SeqPart_VelocityCurveCalc_Skip14:
	cp	a, 48
	jr	nc, SeqPart_VelocityCurveCalc_Skip15
	ld	e, 1:opc
	jr	SeqPart_VelocityCurveCalc_Join4
SeqPart_VelocityCurveCalc_Skip15:
	ld	e, 0:opc
	cp	a, 80
	jr	nc, SeqPart_VelocityCurveCalc_Join4
	ld	e, 2:opc
SeqPart_VelocityCurveCalc_Join4:
	extz	de
	lda	xbc, (SeqPart_VelCurveData_Table_4:24)
	ld	(9792), (xbc+de)
	ld	xbc, SeqPart_VelCurveData_Data_2
	ld	(9794), (xbc+de)
	jrl	SeqPart_VelocityCurveCalc_Join5
SeqPart_VelocityCurveCalc_Case10:
	ld	a, c
	cp	c, 8
	jr	nc, SeqPart_VelocityCurveCalc_Skip16
	ld	e, 0:opc
	jr	SeqPart_VelocityCurveCalc_Join2
SeqPart_VelocityCurveCalc_Skip16:
	cp	a, 24
	jr	nc, SeqPart_VelocityCurveCalc_Skip17
	ld	e, 1:opc
	jr	SeqPart_VelocityCurveCalc_Join2
SeqPart_VelocityCurveCalc_Skip17:
	cp	a, 40
	jr	nc, SeqPart_VelocityCurveCalc_Skip4
	ld	e, 2:opc
	jr	SeqPart_VelocityCurveCalc_Join2
SeqPart_VelocityCurveCalc_Skip4:
	cp	a, 56
	jr	nc, SeqPart_VelocityCurveCalc_Skip5
	ld	e, 3:opc
	jr	SeqPart_VelocityCurveCalc_Join2
SeqPart_VelocityCurveCalc_Skip5:
	cp	a, 72
	jr	nc, SeqPart_VelocityCurveCalc_Skip18
	ld	e, 4:opc
	jr	SeqPart_VelocityCurveCalc_Join2
SeqPart_VelocityCurveCalc_Skip18:
	ld	e, 0:opc
	cp	a, 88
	jr	nc, SeqPart_VelocityCurveCalc_Join2
	ld	e, 5:opc
SeqPart_VelocityCurveCalc_Join2:
	extz	de
	lda	xbc, (SeqPart_VelCurveData_Table_5:24)
	ld	(9792), (xbc+de)
	ld	xbc, SeqPart_VelCurveData_Data_3
	ld	(9794), (xbc+de)
	jrl	SeqPart_VelocityCurveCalc_Join5

SeqPart_VelRangeToZone:
	ld a, (9784:16)
	cp a, 4:i3
	jr nc, SeqPart_VelZone1
	ld e, 0x0:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone1:
	cp a, 0xc
	jr nc, SeqPart_VelZone2
	ld e, 0x1:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone2:
	cp a, 0x14
	jr nc, SeqPart_VelZone3
	ld e, 0x2:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone3:
	cp a, 0x1c
	jr nc, SeqPart_VelZone4
	ld e, 0x3:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone4:
	cp a, 0x24
	jr nc, SeqPart_VelZone5
	ld e, 0x4:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone5:
	cp a, 0x2c
	jr nc, SeqPart_VelZone6
	ld e, 0x5:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone6:
	cp a, 0x34
	jr nc, SeqPart_VelZone7
	ld e, 0x6:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone7:
	cp a, 0x3c
	jr nc, SeqPart_VelZone8
	ld e, 0x7:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone8:
	cp a, 0x44
	jr nc, SeqPart_VelZone9
	ld e, 0x8:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone9:
	cp a, 0x4c
	jr nc, SeqPart_VelZone10
	ld e, 0x9:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone10:
	cp a, 0x54
	jr nc, SeqPart_VelZone11
	ld e, 0xa:opc
	jr SeqPart_VelZoneLookup

SeqPart_VelZone11:
	ld e, 0x0:opc
	cp a, 0x5c
	jr nc, SeqPart_VelZoneLookup
	ld e, 0xb:opc

SeqPart_VelZoneLookup:
	extz de
	lda xbc, (SeqPart_VelZoneLookup_Table:24)
	ld	(0x2640:16), (xbc+de)
	ld xbc, SeqPart_VelZoneLookup_Table_2
	ld	(0x2642:16), (xbc+de)
SeqPart_VelocityCurveCalc_Join5:
	ld l, (9792:16)
	ld c, (9786:16)
	ld e, c
	cp c, 0x7f
	jr nz, SeqPart_VelCalcSubtract
	ld e, 0x0:opc

SeqPart_VelCalcSubtract:
	sub l, e
	ld a, (9730:16)
	ld e, a
	cp a, 0:i3
	jr ge, SeqPart_VelCalcMultiply
	ld e, a
	add e, 0x64

SeqPart_VelCalcMultiply:
	mul hl, e
	extz hl
	div l, 0x64
	ld e, c
	ld a, c
	cp c, 0x7f
	jr nz, SeqPart_VelCalcAdd
	ld e, 0x0:opc

SeqPart_VelCalcAdd:
	add e, l
	ld (9790:16), e
	cp a, 0:i3
	jr z, SeqPart_VelCalcClamp
	cp a, 0x7f
	jr nz, SeqPart_VelCalcStore

SeqPart_VelCalcClamp:
	ld a, 0x60:opc

SeqPart_VelCalcStore:
	sub a, l
	ld (9788:16), a
	ret

SeqPart_VelExprEdit:
	dec 4, xsp
	push xiz
	ld l, (9726:16)
	srl l, 1
	extz hl
	sla hl, 2
	lda xbc, (Display_FontPalette_Table:24)
	ld	xwa, (xbc+hl)
	ld (xsp + 4), xwa
	cp (9728:16), 0
	jrl z, SeqPart_VelExprFinalExit
	cp (9730:16), 0
	jrl z, SeqPart_VelExprFinalExit
	call SeqVoice_FindDrumPartIndex
	ldmm16 0x287f, 9778
	ld a, (9780:16)
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	ld iz, 0:i3
	cpw (9694:16), 0
	jr z, SeqPart_VelExprExit

SeqPart_VelExprLoop:
	ldiw_erp 0xfa, 0
	res 0, (0x287b:16)
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_VelExprCheckNote

SeqPart_VelExprReadEvent:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_VelExprFinalExit
	cp l, 0x81
	jr nz, SeqPart_VelExprDone
	calr SeqStep_MeasureRead
	calr SeqStep_EventAdvance
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	inc1w_erp 0xfa
	call SeqData_AdvancePosition
	res 0, (0x287b:16)
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af

SeqPart_VelExprCheckEnd:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqPart_VelExprReadEvent

SeqPart_VelExprCheckNote:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VelExprExit
	cp iz, (9694:16)
	jr nz, SeqPart_VelExprLoop

SeqPart_VelExprExit:
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprDone:
	bit 7, l
	jr nz, SeqPart_VelExprApply
	call SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprApply:
	and l, 0xf0
	cp l, 0x90
	jr z, SeqPart_VelExprClamp
	call SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprClamp:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	call SeqData_ReadNextByte
	ld (9784:16), l
	extz hl
	ld xwa, (xsp + 4)
	ld	(0x263a:16), (xwa+hl)
	ld a, (9730:16)
	cp a, 0x64
	jr z, SeqPart_VelExprContinue
	cp a, 0x9c
	jr z, SeqPart_VelExprContinue
	calr SeqPart_VelocityCurveCalc
	ld e, (9730:16)
	ld a, (9786:16)
	ld c, (9784:16)
	bit 7, e
	jrl nz, SeqPart_VelExprError
	ld e, a
	cp a, 0:i3
	jr nz, SeqPart_VelExprWrite
	ld a, (9784:16)
	cp a, (9790:16)
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprWrite:
	cp e, 0x7f
	jr nz, SeqPart_VelExprSkip
	ld a, (9784:16)
	cp a, (9788:16)
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprSkip:
	ld a, c
	cp c, (9788:16)
	jr c, SeqPart_VelExprAdvance
	cp a, (9790:16)
	jr ule, SeqPart_VelExprContinue

SeqPart_VelExprAdvance:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprContinue:
	ld e, (9786:16)
	ld b, e
	ld l, e
	ld c, (9728:16)
	cp c, 0x64
	jrl z, SeqPart_VelExprPopReturn
	cp e, 0x7f
	jr nz, SeqPart_VelExprBoundary
	ld b, 0x60:opc

SeqPart_VelExprBoundary:
	ld l, (9784:16)
	cp l, b
	jr nc, SeqPart_VelExprComplete
	sub b, l
	ld a, b
	jr SeqPart_VelExprUpdate

SeqPart_VelExprError:
	ld e, a
	cp a, 0:i3
	jr nz, SeqPart_VelExprReturn
	ld a, (9784:16)
	cp a, (9790:16)
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprReturn:
	cp e, 0x7f
	jr nz, SeqPart_VelExprFinish
	ld a, (9784:16)
	cp a, (9788:16)
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jr SeqPart_VelExprFinalExit

SeqPart_VelExprFinish:
	ld a, c
	cp c, (9788:16)
	jr ule, SeqPart_VelExprContinue
	cp a, (9790:16)
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jr SeqPart_VelExprFinalExit

SeqPart_VelExprComplete:
	ld w, l
	sub w, b
	ld a, w

SeqPart_VelExprUpdate:
	extz wa
	extz bc
	mul xwa, bc
	extz xwa
	div wa, 0x64
	ld b, e
	cp e, 0x7f
	jr nz, SeqPart_VelExprStore
	ld b, 0x60:opc

SeqPart_VelExprStore:
	cp l, b
	jr nc, SeqPart_VelExprPopIz
	add l, a
	cp l, 0x60
	jr c, SeqPart_VelExprPopReturn
	ld l, 0x7f:opc
	jr SeqPart_VelExprClampMax

SeqPart_VelExprPopIz:
	sub l, a

SeqPart_VelExprPopReturn:
	cp l, 0x7f
	jr nz, SeqPart_VelExprClampMin

SeqPart_VelExprClampMax:
	set 0, (0x287b:16)

SeqPart_VelExprClampMin:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jrl z, SeqPart_VelExprCheckEnd

SeqPart_VelExprFinalExit:
	pop xiz
	inc 4, xsp
	ret

SeqPart_BufferSwap:
	dec 6, xsp
	push xiz
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 8), 0x2885
	ld iz, (0x28af:16)
	ldmw2 (xsp + 4), 0x2666
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_BufferSwapReturn
	ldmm16 0x2887, 0x28af
	ldmm16 0x2885, 9830
	call PartCtrl_NavigateBackwardAlt
	call SeqPart_ReadByte_Primary
	cp l, 0x81
	jr z, SeqPart_BufferSwapReturn
	call PartCtrl_AdvanceToNextEntry
	call PartCtrl_AdvanceToNextEntry
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_BufferSwapReturn
	ldw wa, 0x82
	call SeqPart_WriteByte_Primary
	ld wa, (0x287d:16)
	ldfr_werp WA, 0xfa
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld wa, (0x2885:16)
	ld c, a
	extz bc
	ld wa, (0x2887:16)
	call Part_WriteWordAndByte
	ldto_werp WA, 0xfa
	ld (0x287d:16), wa
	call PartCtrl_NavigateBackwardAlt
	ldw wa, 0x81
	call SeqPart_WriteByte_Primary

SeqPart_BufferSwapReturn:
	mrdw5 0x9f, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9f, 0x08, 0x19, 0x85, 0x28
	ld (0x28af:16), iz
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	pop xiz
	inc 6, xsp
	ret

SeqPart_PartSelect:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call SeqValidate_PartAndTempoCombined
	cp hl, 0:i3
	jr z, SeqPart_PartSelectLoop
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_PartSelectExit

SeqPart_PartSelectLoop:
	ld c, (0x2877:16)
	cp c, 0x11
	jr z, SeqPart_PartSelectDone
	ld a, c
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_PartSelectCheck
	cp a, 0x10
	jr z, SeqPart_PartSelectCheck
	cp a, 0xf
	jr z, SeqPart_PartSelectCheck
	cp a, 0xe
	jr nz, SeqPart_PartSelectSkip

SeqPart_PartSelectCheck:
	ld (SEQ_ERROR_CODE:16), 9
	jr SeqPart_PartSelectExit

SeqPart_PartSelectSkip:
	ld (9780:16), c
	ld (SEQ_ERROR_CODE:16), 0
	calr SeqPart_InnerProcess
	jr SeqPart_PartSelectExit

SeqPart_PartSelectDone:
	ldib_erp 0xfb, 1

SeqPart_PartSelectProcess:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_PartSelectFinish
	cp a, 0xf
	jr z, SeqPart_PartSelectFinish
	cp a, 0x10
	call nz, (SeqPart_InnerProcess:24)

SeqPart_PartSelectFinish:
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_PartSelectReturn
	cp a, 1:i3
	jr z, SeqPart_PartSelectReturn
	cp a, 0x8
	jr z, SeqPart_PartSelectReturn
	cp (9782:16), 0
	jr nz, SeqPart_PartSelectReturn
	ld (9782:16), a

SeqPart_PartSelectReturn:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_PartSelectProcess
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_PartSelectExit:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_InnerProcess:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	cp (9762:16), 0
	jrl z, SeqPart_InnerReturn
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_InnerReturn
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_InnerReturn
	ld iz, 0:i3
	cpw (9694:16), 0
	jrl z, SeqPart_InnerReturn

SeqPart_InnerLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_InnerCheckNote

SeqPart_InnerReadEvent:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_InnerReturn
	cp l, 0x81
	jr nz, SeqPart_InnerCheck90
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_InnerReturn
	inc1w_erp 0xfa

SeqPart_InnerCheckType:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqPart_InnerReadEvent

SeqPart_InnerCheckNote:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_InnerBoundary
	jr SeqPart_InnerReturn

SeqPart_InnerCheck90:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_InnerAdvance
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_InnerReturn
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_InnerReturn
	call SeqData_ReadNextByte
	ld c, (9762:16)
	cp c, 0:i3
	jr le, SeqPart_InnerVelAddNeg
	ld e, 0x7f:opc
	sub e, l
	ld a, c
	cp e, a
	jr ugt, SeqPart_InnerVelAdd
	ld l, 0x7f:opc
	jr SeqPart_InnerVelStore

SeqPart_InnerVelAdd:
	add l, c
	jr SeqPart_InnerVelStore

SeqPart_InnerVelAddNeg:
	add l, c
	jr ge, SeqPart_InnerVelStore
	ld l, 0x0:opc

SeqPart_InnerVelStore:
	ld a, l
	call PartCtrl_WriteByte_Indexed

SeqPart_InnerAdvance:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_InnerCheckType
	jr SeqPart_InnerReturn

SeqPart_InnerBoundary:
	cp iz, (9694:16)
	jrl nz, SeqPart_InnerLoop

SeqPart_InnerReturn:
	pop xiz
	ret

SeqPart_PartVoiceCheck:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndRange
	cp hl, 0:i3
	jr z, SeqPart_VoiceCheckCompare
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckCompare:
	ld a, (9750:16)
	cp a, (9816:16)
	jrl z, SeqPart_VoiceCheckReturn
	ld c, (0x2877:16)
	cp c, 0x11
	jr z, SeqPart_VoiceCheckMulti
	ld a, c
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0x10
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0xf
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0xe
	jr nz, SeqPart_VoiceCheckOk

SeqPart_VoiceCheckDrum:
	ld (SEQ_ERROR_CODE:16), 9
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckOk:
	ld (9780:16), c
	ld (SEQ_ERROR_CODE:16), 0
	calr SeqPart_VoiceCheckSetup
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckMulti:
	ldib_erp 0xfb, 1

SeqPart_VoiceCheckMultiLoop:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VoiceCheckMultiNext
	cp a, 0xf
	jr z, SeqPart_VoiceCheckMultiNext
	cp a, 0x10
	call nz, (SeqPart_VoiceCheckSetup:24)

SeqPart_VoiceCheckMultiNext:
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_VoiceCheckMultiDone
	cp a, 1:i3
	jr z, SeqPart_VoiceCheckMultiDone
	cp a, 0x8
	jr z, SeqPart_VoiceCheckMultiDone
	ld a, (9782:16)
	cp a, 0:i3
	jr nz, SeqPart_VoiceCheckMultiDone
	ld (SEQ_ERROR_CODE:16), a

SeqPart_VoiceCheckMultiDone:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VoiceCheckMultiLoop
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_VoiceCheckReturn:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_VoiceCheckSetup:
	push xiz
	ld (SEQ_ERROR_CODE:16), 0
	ld a, (9750:16)
	cp a, (9816:16)
	jrl z, SeqPart_VoiceCheckModeA
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VoiceCheckModeA
	ldmm16 9820, 0x28af
	ldmm16 9822, 9830
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VoiceCheckModeA
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	ld iz, 0:i3
	cpw (9694:16), 0
	jr z, SeqPart_VoiceCheckComplete

SeqPart_VoiceCheckSetupDone:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_VoiceCheckValidate

SeqPart_VoiceCheckSetupReturn:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqPart_VoiceCheckModeA
	cp l, 0x81
	jr nz, SeqPart_VoiceCheckFinal
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckModeA
	inc1w_erp 0xfa

SeqPart_VoiceCheckProcess:
	ld a, (0x288e:16)
	extz wa
	cpw_erp WA, 0xfa
	jr nz, SeqPart_VoiceCheckSetupReturn

SeqPart_VoiceCheckValidate:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cp iz, (9694:16)
	jr nz, SeqPart_VoiceCheckSetupDone

SeqPart_VoiceCheckComplete:
	jr SeqPart_VoiceCheckModeA

SeqPart_VoiceCheckFinal:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_VoiceCheckDispatch
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_ReadNextByte
	cp l, (9750:16)
	jr nz, SeqPart_VoiceCheckDispatch
	ld a, (9816:16)
	extz wa
	call PartCtrl_WriteByte_Indexed

SeqPart_VoiceCheckDispatch:
	call SeqData_ReadParamBlockAlt
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_VoiceCheckProcess

SeqPart_VoiceCheckModeA:
	pop xiz
	ret

SeqPart_VoiceCheckModeB:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	ld (SEQ_ERROR_CODE:16), 0
	call Seq_ValidatePartAndTempoAlt
	cp hl, 0:i3
	jr z, SeqPart_VoiceCheckModeC
	ld (SEQ_ERROR_CODE:16), 3
	jrl SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckModeC:
	ld (SEQ_ERROR_CODE:16), 0
	res 6, (0x287b:16)
	ld c, (0x2877:16)
	cp c, 0x11
	jr z, SeqPart_VoiceCheckCleanup
	ld a, c
	dec 1, a
	extz wa
	lda xde, (0xf1a0:16)
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VoiceCheckUpdate
	cp a, 0xf
	jr z, SeqPart_VoiceCheckUpdate
	cp a, 0x10
	jr nz, SeqPart_VoiceCheckStore

SeqPart_VoiceCheckUpdate:
	ld (SEQ_ERROR_CODE:16), 9
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckStore:
	ld (9780:16), c
	calr SeqPart_VoiceCheckWalkReturn
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckCleanup:
	ldib_erp 0xfb, 1

SeqPart_VoiceCheckFinish:
	ldto_berp A, 0xfb
	ld (9780:16), a
	ldto_berp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xd
	jr z, SeqPart_VoiceCheckWalk
	cp a, 0xf
	jr z, SeqPart_VoiceCheckWalk
	cp a, 0x10
	call nz, (SeqPart_VoiceCheckWalkReturn:24)

SeqPart_VoiceCheckWalk:
	ld a, (SEQ_ERROR_CODE:16)
	cp a, 0:i3
	jr z, SeqPart_VoiceCheckWalkLoop
	cp a, 1:i3
	jr z, SeqPart_VoiceCheckWalkLoop
	cp (9782:16), 0
	jr nz, SeqPart_VoiceCheckWalkLoop
	ld (9782:16), a

SeqPart_VoiceCheckWalkLoop:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VoiceCheckFinish
	ldmm8 SEQ_ERROR_CODE, 9782

SeqPart_VoiceCheckWalkDone:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_VoiceCheckWalkReturn:
	dec 4, xsp
	push xiz
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VoiceCheckEndCleanup
	ldw (xsp + 4), 0x0
	cpw (9694:16), 0
	jrl z, SeqPart_VoiceCheckWalkFinish

SeqPart_VoiceCheckWalkAdvance:
	ld iz, 0:i3
	ld (9824:16), 0
	ld (9826:16), 0
	res 0, (0x287b:16)
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af
	ld (xsp + 6), 0x0
	ld a, (0x288e:16)
	extz wa
	cp wa, 0:i3
	jr z, SeqPart_VoiceCheckWalkCleanup

SeqPart_VoiceCheckWalkValidate:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqPart_VoiceCheckWalkSkip
	calr SeqStep_DeleteEvent
	jrl SeqPart_VoiceCheckEndAdvance

SeqPart_VoiceCheckWalkSkip:
	cp l, 0x81
	jr nz, SeqPart_VoiceCheckFinalReturn
	ld wa, (xsp + 4)
	ld bc, iz
	calr SeqPart_VoiceCheckEndExit
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SeqPart_VoiceCheckEndAdvance
	inc 1, iz
	call SeqData_AdvancePosition
	ld (9824:16), 0
	ld (9826:16), 0
	res 0, (0x287b:16)
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af

SeqPart_VoiceCheckWalkError:
	ld a, (0x288e:16)
	extz wa
	cp wa, iz
	jr nz, SeqPart_VoiceCheckWalkValidate

SeqPart_VoiceCheckWalkCleanup:
	cp (xsp + 6), 0x0
	jr nz, SeqPart_VoiceCheckWalkFinish
	incw 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckWalkFinish
	ld wa, (xsp + 4)
	cp wa, (9694:16)
	jrl nz, SeqPart_VoiceCheckWalkAdvance

SeqPart_VoiceCheckWalkFinish:
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_VoiceCheckEndReturn

SeqPart_VoiceCheckWalkExit:
	jr SeqPart_VoiceCheckEndCleanup

SeqPart_VoiceCheckFinalReturn:
	bit 7, l
	jr z, SeqPart_VoiceCheckEndStore
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckEndAdvance
	call SeqData_ReadNextByte
	ldfr_berp L, 0xfb
	ldto_berp A, 0xfb
	add a, (9740:16)
	ldfr_berp A, 0xfb
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xfb, 0x07
	jr nz, SeqPart_VoiceCheckEndCheck
	cp_erpb 0xfb, 0x60
	jr c, SeqPart_VoiceCheckEndStore

SeqPart_VoiceCheckEndCheck:
	set 0, (0x287b:16)

SeqPart_VoiceCheckEndStore:
	call SeqData_AdvancePosition
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SeqPart_VoiceCheckWalkError

SeqPart_VoiceCheckEndAdvance:
	ld (xsp + 6), 0x1
	cp (SEQ_ERROR_CODE:16), 0
	jr nz, SeqPart_VoiceCheckWalkExit

SeqPart_VoiceCheckEndReturn:
	ld a, (9740:16)
	bit 7, a
	jr z, SeqPart_VoiceCheckEndError
	calr SeqStep_VelNoteFwd
	jr SeqPart_VoiceCheckEndCleanup

SeqPart_VoiceCheckEndError:
	ld wa, (xsp + 4)
	calr SeqStep_VelNoteBwd

SeqPart_VoiceCheckEndCleanup:
	pop xiz
	inc 4, xsp
	ret

SeqPart_VoiceCheckEndExit:
	bit 0, (0x287b:16)
	ret z
	ld e, (9740:16)
	bit 7, e
	jrl nz, SeqStep_EventProcess
	jr SeqStep_NoteDispatch

	.include "sequencer/seq_step_routines.s"
