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
	call_24 nz, BmDrEdit_PrepareSecondaryNoteDisplay
	jp NoteEditSy_UpdateEditModeGrid

NoteEditSy_ScanAndSortEntries:
	lda xsp, (xsp - 16)
	push xiz
	ld a, (7512:16)
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0x0f
	jr nz, NoteEditSy_DirectCopy
	lds iz, 0

NoteEditSy_ScanLoop:
	stb_erp A, 0xfb

	extz wa

	stb_erp C, 0xf8

	extz bc

	lda xde, (xsp + 4)

	call	16703299

	ld de, iz

	mul de, 0xd

	lda xhl, (xsp + 4)

	ld xbc, xhl

	ld xwa, (7504:16)

	add xde, xwa

	lda xhl, (xhl + 13)



NoteEditSy_CopyEntryLoop:
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, NoteEditSy_CopyEntryLoop
	inc 1, iz
	cp iz, 0x80
	jr c, NoteEditSy_ScanLoop
	jr NoteEditSy_ScanReturn

NoteEditSy_DirectCopy:
	ld xbc, (7504:16)
	ld xwa, xbc
	lda_dri XBC, 0xe5, 0xa4, 0x06

NoteEditSy_DirectCopyLoop:
	stib_dsp 0xe0, 0x20
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
	setda 1, 8970
	resda 3, 0x28a7
	setda 4, 0x28b3
	call AccWrap_PlayModeDispatch
	jp SeqBuffer_ClearAndInitIteration


; -----------------------------------------------------------------------------
; Section: Sequencer Playback Control
; -----------------------------------------------------------------------------
; Playback state machine: tick handling, start/stop,
; repeat management, tempo, and part activation.
; -----------------------------------------------------------------------------

SeqAcc_HandlePlaybackTick:
	cp (0x8c9a:16), 0x88
	jr z, SeqAcc_HandlePlaybackTick_ClearBit2
	bit 1, (0x230a:16)
	jr z, SeqAcc_HandlePlaybackTick_ClearBit1
	call PartSelect_UpdateDisplayState
	calr SeqAcc_ProcessTempoEvents
	call AccWrap_PlayModeDispatch
	resda 0, (0x26e2)
SeqAcc_HandlePlaybackTick_ClearBit1:
	resda 1, 8970

SeqAcc_HandlePlaybackTick_ClearBit2:
	resda 2, 0x28a7
	ret

SeqAcc_HandlePlaybackTick_Data:
	.byte 0xf1, 0xc5
	pushw	wa
	.byte 0xbb
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
	subda16 xwa, 0xf23f
	ld (9832:16), wa
	ld (9964:16), wa
	jr SeqAcc_StartPlayback

SeqAcc_AdjustEndAndStart:
	dec 1, wa
	ld (0x28c3:16), wa
	calr SeqAcc_UpdateEndPosition
	ld wa, (0xf238:16)
	subda16 xwa, 0xf23f
	ld (9832:16), wa
	ld (9964:16), wa

SeqAcc_StartPlayback:
	setda 0, 0xf23c
	calr SeqAcc_SetupRepeatCount
	call SeqPlay_InitStartState
	jp SeqBuf_Init

SeqAcc_StopPlayback:
	cp (0x8c9a:16), 0x88
	jr z, SeqAcc_StopPlayback_HandleTick
	resda 0, (0xf23c)
	calr SeqAcc_SetupRepeatCount
SeqAcc_StopPlayback_HandleTick:
	calr SeqAcc_HandlePlaybackTick
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	jp SeqPlay_SaveStateAndCleanup

SeqAcc_UpdateEndPosition:
	ld wa, (0x28c3:16)
	cpdm16 0xf23f, xwa
	ret ule
	ld (0xf23f:16), wa
	ret

SeqAcc_SetupRepeatCount:
	ldw (0x28c6:16), 0
	bit 0, (0xf23c:16)
	jr z, SeqAcc_CheckRepeatEdgeCases
	ld wa, (0xf238:16)
	cpda16 xwa, 9832
	jr nz, SeqAcc_CheckRepeatEdgeCases
	ldmm16 0x28c6, 0x28a8

SeqAcc_CheckRepeatEdgeCases:
	ld wa, (9832:16)
	extz xwa
	bit 15, wa
	jr z, SeqAcc_UpdatePlaybackFlags
	cpdi16 0xf238, 1
	jr nz, SeqAcc_UpdatePlaybackFlags
	ldmm16 0x28c6, 0x28a8

SeqAcc_UpdatePlaybackFlags:
	ld a, (0x28a7:16)
	res 3, a
	ld (0x28a7:16), a
	ld bc, (9832:16)
	cps bc, 1
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
	bit 2, (1057:16)
	jr z, SeqPlay_CheckAndActivateParts_RetFFFF
	cpdi16 0x28a8, 0
	jr nz, SeqPlay_CheckAndActivateParts_Bit6

SeqPlay_CheckAndActivateParts_RetFFFF:
	ldw hl, 0xffff
	jr SeqPlay_CheckAndActivateParts_Return

SeqPlay_CheckAndActivateParts_Bit6:
	bit 6, a
	jr nz, SeqPlay_CheckAndActivateParts_Deactivate
	ei 6
	ldmm8 0x28c8, 1051
	ldmm16 0x28c9, 1052
	ei 0
	ldmm16 8998, 0x28c9
	lda xwa, (xsp)
	ld (xwa), 0x0
	calr SeqPlay_ActivatePartsAndSendOff
	jr SeqPlay_CheckAndActivateParts_SetHL0

SeqPlay_CheckAndActivateParts_Deactivate:
	calr SeqPlay_DeactivateAndSendOff
	cpdi16 0x28b4, 0
	jr nz, SeqPlay_CheckAndActivateParts_SetHL0
	ld (8956:16), 0

SeqPlay_CheckAndActivateParts_SetHL0:
	lds hl, 0

SeqPlay_CheckAndActivateParts_Return:
	inc 4, xsp
	ret

SeqPlay_ActivatePartsAndSendOff:
	dec 4, xsp

	pushw_erp 0xfa

	ld (xsp + 2), xwa

	setda 6, 0x28c5

	ld wa, (0x28a8:16)

	andda16 xwa, 0x28b4

	ld (0x28aa:16), wa

	ld (0x28c6:16), wa

	cpl wa

	anddm16 0xf19e, xwa

	call	16635550

	ldib_erp 0xfb, 1



SeqPlay_ActivateParts_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_ActivateParts_ShiftDone
	slaa bc

SeqPlay_ActivateParts_ShiftDone:
	andda16 xbc, 0x28c6
	jr z, SeqPlay_ActivateParts_LoopNext
	stb_erp A, 0xfb
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
	resda 6, 0x28c5
	setda 5, 0x28c5
	ldib_erp 0xfb, 1

SeqPlay_DeactivateParts_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_DeactivateParts_ShiftDone
	slaa bc

SeqPlay_DeactivateParts_ShiftDone:
	andda16 xbc, 0x28c6
	jr z, SeqPlay_DeactivateParts_LoopNext
	stb_erp A, 0xfb
	extz wa
	call SeqBuf_WriteNoteOffEntry

SeqPlay_DeactivateParts_LoopNext:
	.byte 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x10, 0x67
	.byte 0xda, 0x06, 0x06, 0xc1, 0x1b, 0x04, 0x19, 0xcb
	.byte 0x28, 0xd1, 0x1c, 0x04, 0x19, 0xcc, 0x28, 0xf1
	.byte 0xaa, 0x28, 0x02, 0x00, 0x00, 0x06, 0x00, 0xf1
	.byte 0xa8, 0x28, 0x02, 0x00, 0x00, 0xd1, 0xc6, 0x28
	.byte 0x20, 0xd1, 0x9e, 0xf1, 0xe8, 0x1d, 0x9e, 0xd6
	.byte 0xfd, 0xd7, 0xfa, 0x05, 0x0e
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
	cpda16 xwa, 9832
	jr nz, SeqPlay_InitTempoAndActivateParts
	ldmm16 0x28c6, 0x28a8

SeqPlay_InitTempoAndActivateParts:
	.byte 0x1d, 0xdb, 0x24, 0xef, 0xd1, 0xa8, 0x28, 0x20
	.byte 0xd8, 0xd8, 0x66, 0x26, 0xd1, 0x9e, 0xf1, 0xe8
	.byte 0xf1, 0xb3, 0x28, 0xbb, 0x1d, 0x9e, 0xd6, 0xfd
	.byte 0xf1, 0xc5, 0x28, 0xb8, 0xc1, 0xb2, 0x28, 0x21
	.byte 0xc9, 0x33, 0x00, 0x66, 0x0d, 0xc9, 0x31, 0x01
	.byte 0xf1, 0xb2, 0x28, 0x41, 0xd1, 0x68, 0x26, 0x19
	.byte 0x36, 0x23
SeqPlay_InitAccAndSetMode:
	call SeqAcc_InitPlaybackState
	ldb a, 0xc
	bit 0, (0x28b2:16)
	jr nz, SeqPlay_InitAccAndSetMode_StoreState
	ldb a, 0xb

SeqPlay_InitAccAndSetMode_StoreState:
	ld (8956:16), a
	lds hl, 0
	ret

SeqPlay_DataBlock_BBE:
	ld	wa, (0xf238:16)
	inc	1, wa
	ld	(0xf238:16), wa
	cp	wa, 998
	jr	ule, 6
	ldw	(0xf238:16), 998
	calr	39
	ld	wa, (0xf238:16)
	cpda16 xwa, (62010)
	jr	c, 6
	inc	1, wa
	ld	(0xf23a:16), wa
	jrl	-530
	ld	wa, (0xf238:16)
	cps	wa, 1
	jr	ule, 6
	dec	1, wa
	ld	(0xf238:16), wa
	calr	93
	jrl	-550
	.byte 0xf1, 0xb2
	pushw	wa
	inc	6, w
	ldw	iz, 0x38d1
	.byte 0xf2
	ldb	w, 216
	dec	6, de
	zcf
	ldw	(9832:16), 0x8002
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 3
	ret
	cps	wa, 3
	jr	nz, 19
	ldw	(9832:16), 1
	ldw	(9964:16), 1
	ldw	(0xf23f:16), 2
	ret
	cps	wa, 3
	ret	c
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	64898
	ld	wa, (0xf238:16)
	subda16 xwa, (62015)
	ld	(9832:16), wa
	ld	(9964:16), wa
	ret
	.byte 0xf1, 0xb2
	pushw	wa
	inc	6, w
	ldw	iz, 0x38d1
	.byte 0xf2
	ldb	w, 216
	dec	6, bc
	zcf
	ldw	(9832:16), 0x8002
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 2
	ret
	cps	wa, 2
	jr	nz, 19
	ldw	(9832:16), 2
	ldw	(9964:16), 0x8002
	ldw	(0xf23f:16), 3
	ret
	cps	wa, 3
	ret	c
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	64808
	ld	wa, (0xf238:16)
	subda16 xwa, (62015)
	ld	(9832:16), wa
	ld	(9964:16), wa
	ret
	ld	wa, (0xf23a:16)
	cp	wa, 999
	jr	c, 11
	ldw	(0xf23a:16), 999
	ldw	wa, 999
	jr	10
	inc	1, wa
	ld	(0xf23a:16), wa
	ld	wa, (0xf23a:16)
	cpdm16 (62008), xwa
	ret	c
	dec	1, wa
	ld	(0xf238:16), wa
	calr	65310
	calr	64757
	ret
	ld	wa, (0xf23a:16)
	cps	wa, 2
	jr	ugt, 10
	ldw	(0xf23a:16), 2
	lds	wa, 2
	jr	10
	dec	1, wa
	ld	(0xf23a:16), wa
	ld	wa, (0xf23a:16)
	cpdm16 (62008), xwa
	ret	c
	dec	1, wa
	ld	(0xf238:16), wa
	calr	65353
	calr	64710
	ret
	.byte 0xf1, 0xb2
	pushw	wa
	inc	6, w
	ldio	209, 56
	.byte 0xf2
	push	xsp
	push	sr
	nop
	ret	ule
	ld	wa, (0xf23f:16)
	cp	wa, 997
	jr	c, 8
	ldw	(0xf23f:16), 997
	jr	6
	inc	1, wa
	ld	(0xf23f:16), wa
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	64643
	ld	wa, (0xf238:16)
	subda16 xwa, (62015)
	ld	(9832:16), wa
	ld	(9964:16), wa
	jrl	-897
	.byte 0xf1, 0xb2
	pushw	wa
	inc	6, w
	ldio	209, 56
	.byte 0xf2
	push	xsp
	push	sr
	nop
	ret	ule
	ld	wa, (0xf23f:16)
	cps	wa, 0
	jr	z, 6
	dec	1, wa
	ld	(0xf23f:16), wa
	ld	wa, (0xf238:16)
	dec	1, wa
	ld	(0x28c3:16), wa
	calr	64583
	ld	wa, (0xf238:16)
	subda16 xwa, (62015)
	ld	(9832:16), wa
	.byte 0xf1, 0xec
	.ascii "&PxCü"


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
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_ProcessParts_ShiftDone
	slaa bc

SeqPlay_ProcessParts_ShiftDone:
	andda16	xbc, (10574)
	jr	z, 109	; -> 0xF38DFB
	call	Part_ProcessAndDecrementVoice
	ld	iz, hl
	cp	iz, 65535
	jr	nz, 32	; -> 0xF38DBA
	ldw	(10408:16), 0
	ldw	(61854:16), 0
	ldw	(10410:16), 0
	ldw	(10420:16), 0
	call	16635550
	ldb	l, 2
	jr	92	; -> 0xF38E16
SeqPlay_ProcessParts_HandleResult:
	setda 0, 9834
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	stb_erp C, 0xfb
	dec 1, c
	ld a, c
	extz wa
	add wa, wa
	lda xde, (0x28ce:16)
	stw_dri IZ, 0x07, 0xe8, 0xe0
	lda xde, (0x291e:16)
	stw_dri IZ, 0x07, 0xe8, 0xe0
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
	ldb l, 0x0

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
	cps l, 0
	jr z, SeqAcc_ProcessTempo_ReadComplete

SeqAcc_ProcessTempo_DispatchLoop:
	lda xwa, (xsp + 2)
	call Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 2)
	call TempoRingBuf_ReadEventBytes
	cps l, 0
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
	ld_spiw WA, 0xed
	stw_dpi WA, 0xf1
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
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
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqAcc_ProcessTempo_ShiftDone
	slaa bc

SeqAcc_ProcessTempo_ShiftDone:
	andda16 xbc, 0x294e
	jr z, SeqAcc_ProcessTempo_NextPart
	calr SeqPlay_ProcessCurrentPart
	bit 7, (0x28c5:16)
	jr z, SeqAcc_ProcessTempo_ClearPartBit

SeqPlay_AbortAndCleanup:
	calr SeqPlay_SelectStopCommand
	jrl SeqPlay_FinalizeAndReturn

SeqAcc_ProcessTempo_ClearPartBit:
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqAcc_ProcessTempo_ClearShiftDone
	slaa bc

SeqAcc_ProcessTempo_ClearShiftDone:
	cpl bc
	anddm16 0x294e, xbc
	ld a, (9696:16)
	inc 1, a
	extz wa
	call SeqPlay_SetupDualTrack
	ld a, (9696:16)
	extz wa
	add wa, wa
	lda xbc, (0x28ce:16)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	call Part_StealAndReallocVoices
	ld a, (9780:16)
	ldb_erp A, 0xfb
	ld a, (9696:16)
	inc 1, a
	ld (9780:16), a
	call SeqPart_BufferSwap
	stb_erp A, 0xfb
	ld (9780:16), a

SeqAcc_ProcessTempo_NextPart:
	.byte 0xc1, 0xe0, 0x25, 0x21, 0xc9, 0x61, 0xf1, 0xe0
	.byte 0x25, 0x41, 0xc9, 0xcf, 0x10, 0x77, 0x78, 0xff
	.byte 0xf1, 0xaa, 0x28, 0x02, 0x00, 0x00, 0xf1, 0xb4
	.byte 0x28, 0x02, 0x00, 0x00, 0xf1, 0xa8, 0x28, 0x02
	.byte 0x00, 0x00, 0xd1, 0x50, 0x29, 0x20, 0xd1, 0x9e
	.byte 0xf1, 0xe8, 0x1d, 0x9e, 0xd6, 0xfd, 0xf1, 0xb3
	.byte 0x28, 0xbc, 0xf1, 0xa7, 0x28, 0xb3, 0x30, 0x23
	.byte 0x00, 0x1d, 0x7d, 0x66, 0xf4, 0x68, 0x29
SeqAcc_ProcessTempo_NoActiveParts:
	ldw (0x28aa:16), 0

	ldw (0x28b4:16), 0

	ldw (0x28a8:16), 0

	call	16635550

	setda 4, 0x28b3

	resda 3, 0x28a7

	ldw wa, 0x32

	.byte 0x1d, 0xe3, 0xdf, 0xf3	; call SeqBuf_WriteNoteOffEntry (v7 addr)

	.byte 0x1d, 0x6f, 0xa4, 0xfc	; call Part_ReinitAllActive (v7 addr)



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
	cp	(35997:16), 136
	jr	nz, 5
	ldw	wa, 59
	jr	3
SeqPlay_SelectStopCommand_Default18:
	ldw wa, 0x18

SeqPlay_SendStopAndClearParts:
	.byte 0x1d, 0x7d, 0x66, 0xf4	; call SoundCtrl_SaveAndSendCmd_EE (v7 addr)

	.byte 0xf1, 0xec, 0x8c, 0xb0	; resda 0, 0x8d88 (v7 patched)

	ldw (0x28a8:16), 0

	ldw (0x28aa:16), 0

	ldw (0x28b4:16), 0

	call 16635550

	setda 4, 0x28b3

	resda 3, 0x28a7

	ret



SeqPlay_FinalCleanupAndReset:
	calr SeqPlay_CopyVoicePositionsToParts
	call SeqBuf_Init
	cpdi16 (0xf19e), 0x0000
	jr z, SeqPlay_FinalCleanup_ClearFlags
	ld (0x11f4:16), 0x00
	lds wa, 0
	call 0xfdada0
SeqPlay_FinalCleanup_ClearFlags:
	resda 3, 0x28b3

	call	16635550

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
	stb_erp C, 0xfb
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqPlay_CopyVoicePos_ShiftDone
	slaa de

SeqPlay_CopyVoicePos_ShiftDone:
	andda16 xde, 0x294e
	jr z, SeqPlay_CopyVoicePos_LoopNext
	ld a, c
	extz wa
	add wa, wa
	lda xbc, (0x28ce:16)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	call Part_StealAndReallocVoices

SeqPlay_CopyVoicePos_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_CopyVoicePos_PartLoop
	popw_erp 0xfa
	ret

SeqPlay_ProcessCurrentPart:
	resda 2, 0x287b
	ldmm8 0x2958, 0x28c8
	ldmm16 3299, 0x28c9
	ld a, (9696:16)
	inc 1, a
	extz wa
	call SeqVoice_CountEventsInBar
	cp (0x287a:16), 0
	jr nz, SeqPlay_ProcessCurrentPart_Done
	calr SeqPlay_ProcessCurrentPart_Loop
	cp (0x287a:16), 0
	jr z, SeqPlay_ProcessCurrentPart_Return

SeqPlay_ProcessCurrentPart_Done:
	setda 7, 0x28c5
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
	cp (0x287a:16), 0
	call_24 z, SeqData_ScanForBarPosition
	ldmm16 0x2955, 0x28af
	ld wa, (9830:16)
	ld (0x2957:16), a
	ret

SeqPlay_ProcessCurrentPart_Loop:
	push xiz
	ld (0x287a:16), 0
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
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 0x2958
	jr c, SeqData_SkipToNextCommand

SeqData_HandleEndMark_NotBarEnd:
	stw_erp WA, 0xfa
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
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqData_HandleEndMark_NotBarEnd

SeqData_HandleEndMark_SetError1:
	ld (0x287a:16), 1

SeqData_HandleEndMark_Return:
	pop xiz
	ret

SeqData_ScanForBarPosition:
	push xiz
	ld (0x287a:16), 0
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
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 0x2958
	jr ule, SeqData_SkipToNextCommand_Fwd
	stw_erp WA, 0xfa
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
	cps wa, 5
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
	bit 2, (1057:16)
	jr z, SeqPlay_CheckAndReactivate_Return
	lda xwa, (xsp)
	call TempoRingBuf_ReadEventBytes
	bitm 7, (xsp + 256)
	jr nz, SeqPlay_CheckAndReactivate_CopyPos
	ldw wa, 0x68
	call SeqData_SetErrorCode

SeqPlay_CheckAndReactivate_CopyPos:
	lda xbc, (xsp + 1)
	ld a, (xbc)
	ld (0x28c8:16), a
	ldmm16 0x28c9, 1052
	ld a, (xbc)
	cpda8 a, 1051
	jr ule, SeqPlay_CheckAndReactivate_Activate
	pushw 0x81
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	decdi16 1, 0x28c9

SeqPlay_CheckAndReactivate_Activate:
	ldmm16 8998, 0x28c9
	lds wa, 1
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
	ld de, (1052:16)
	ld wa, (0xf238:16)
	ld bc, (9832:16)
	cp bc, wa
	jr nz, SeqPlay_CheckRepeat_AltPath
	ld (0x2959:16), de
	ld wa, (0x28a8:16)
	andda16 xwa, 0x28b4
	ld (0x28c6:16), wa
	jr SeqPlay_CheckRepeat_ApplyMask

SeqPlay_CheckRepeat_AltPath:
	cps wa, 1
	ret nz
	extz xbc
	bit 15, bc
	ret z
	ld (0x2959:16), de
	ld wa, (0x28a8:16)
	andda16 xwa, 0x28b4
	ld (0x28c6:16), wa

SeqPlay_CheckRepeat_ApplyMask:
	cpl wa
	anddm16 0xf19e, xwa
	jrl SeqPlay_ReactivatePartsAndResume

SeqPlay_SyncPlaybackPosition:
	pushw iz
	bit 2, (1057:16)
	jrl z, SeqPlay_PopIzRet
	ld a, (0x28c5:16)
	bit 0, a
	jrl z, SeqPlay_PopIzRet
	bit 0, (0xf23c:16)
	jrl z, SeqPlay_PopIzRet
	ld iy, (1052:16)
	ld (0x2959:16), iy
	ld a, (9010:16)
	ldb_erp A, 0xf8
	extz iz
	ld ix, (9008:16)
	ldw_erp IY, 0xe2
	stw_erp WA, 0xe2
	sub wa, ix
	ldw_erp WA, 0xe2
	ld wa, (0x28a8:16)
	ldw_erp WA, 0xe6
	andda16 xwa, 0x28b4
	ldw_erp WA, 0xe6
	ld l, (0x28c5:16)
	ld bc, (9832:16)
	stw_erp DE, 0xe6
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
	ld	wa, qbc
	ld	(10410:16), wa
	ld	wa, qbc
	ld	(10438:16), wa
	anddm16	(61854), xde
	call	16635550
	calr	113
	jr	109	; -> 0xF3936A
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
	.byte 0xcf, 0x30, 0x06, 0xcf, 0x31, 0x05, 0xf1, 0xc5
	.byte 0x28, 0x47, 0xf1, 0xa8, 0x28, 0x02, 0x00, 0x00
	.byte 0xf1, 0xaa, 0x28, 0x02, 0x00, 0x00, 0xd1, 0xc6
	.byte 0x28, 0x20, 0xd1, 0x9e, 0xf1, 0xe8, 0xf1, 0xc6
	.byte 0x28, 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6, 0xfd
	.byte 0xd1, 0x59, 0x29, 0x20, 0xd8, 0x69, 0xf1, 0xcc
	.byte 0x28, 0x50, 0xf1, 0xcb, 0x28, 0x00, 0x5f, 0xd1
	.byte 0xb4, 0x28, 0x3f, 0x00, 0x00, 0x6e, 0x0f, 0xf1
	.byte 0xfc, 0x22, 0x00, 0x00, 0xd1, 0x3a, 0xf2, 0x19
	.byte 0x68, 0x26, 0x1d, 0xd6, 0x64, 0xf4
SeqPlay_PopIzRet:
	popw iz
	ret

SeqPlay_ReactivatePartsAndResume:
	dec 4, xsp

	pushw_erp 0xfa

	resda 3, 0x28b3

	call	16635550

	setda 6, 0x28c5

	ldib_erp 0xfb, 1



SeqPlay_Reactivate_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_Reactivate_ShiftDone
	slaa bc

SeqPlay_Reactivate_ShiftDone:
	andda16 xbc, 0x28c6
	jr z, SeqPlay_Reactivate_LoopNext
	stb_erp A, 0xfb
	extz wa
	call Part_SendVoiceOffAndCCEvents

SeqPlay_Reactivate_LoopNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPlay_Reactivate_PartLoop
	ld wa, (0x28a8:16)
	andda16 xwa, 0x28b4
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
	resda 5, 0x28b3
	ldw wa, 0x32
	call SeqNotePool_Init
	resda 0, 1115
	call SeqPlay_CheckRepeatActive
	ld (7570:16), l
	cpdi16 0xf19e, 0
	jr nz, SeqAcc_InitPlayback_HasActiveVoices
	cpdi16 0x28a8, 0
	jrl nz, SeqAcc_ClearStepCounter
	ld a, (0x28a7:16)
	res 0, a
	set 1, a
	ld (0x28a7:16), a
	jr SeqAcc_InitPlayback_SetState0

SeqAcc_InitPlayback_HasActiveVoices:
	.byte 0xf1, 0xe7, 0x31, 0xc9, 0x66, 0x07, 0xf1, 0xb3
	.byte 0x28, 0xbc, 0x78, 0x9d, 0x00
SeqAcc_InitPlayback_FindVoices:
	lds wa, 0
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ld (8988:16), l
	lds wa, 0
	ldw bc, 0x10
	call Part_FindVoiceByByte
	ld (8990:16), l
	lds wa, 0
	ldw bc, 0xc
	call Part_FindVoiceByByte
	ld (8992:16), l
	lds wa, 0
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ld (8994:16), l
	lds wa, 0
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ld (8996:16), l
	call BitMapOut_PrepareAndDisplay
	call BitMapOut_PrepareAndDisplaySimple
	setda 4, 0x28ac
	bit 3, (0x28a7:16)
	jr nz, SeqAcc_InitPlayback_RestartPath
	calr SeqAcc_InitPlayback_FreshStart
	jr SeqAcc_InitPlayback_CheckDrum

SeqAcc_InitPlayback_RestartPath:
	calr SeqPlay_RestartWithVoiceConfig

SeqAcc_InitPlayback_CheckDrum:
	resda 4, 0x28ac
	cpdi16 8982, 0
	jr nz, SeqAcc_InitPlayback_DrumActive
	cpdi16 0x28a8, 0
	jr nz, SeqAcc_ClearStepCounter

SeqAcc_InitPlayback_SetState0:
	ld (8956:16), 0

SeqAcc_ClearStepCounter:
	ld (8968:16), 0
	jr SeqPlay_StateSetExit

SeqAcc_InitPlayback_DrumActive:
	calr SeqPlay_CheckDrumPartAndClearCounters
	cpdi16 0x28a8, 0
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
	ldb l, 0x0
	ret

SeqAcc_InitPlayback_FreshStart:
	resda 0, 0x28a6
	call AccWrap_PositionClear
	resda 1, 8974
	ld (7560:16), 0
	ld (7562:16), 0
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
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
	lds bc, 0
	call Voice_ScanAvailableChannel
	call SeqPart_InitVoiceChannelConfig

SeqAcc_InitPlayback_ScanParts:
	lds wa, 0
	lds bc, 0
	call Voice_ScanAvailableChannel
	lds wa, 0
	call SeqScan_ProcessAllParts
	calr SeqPlay_IterateAllChannels
	lds wa, 0
	lds bc, 0
	calr SeqPlay_AssignAccompVoices
	lds wa, 0
	lds bc, 0
	calr SeqPlay_AssignBassVoices
	lds wa, 0
	lds bc, 0
	calr SeqPlay_AssignChordVoices
	lds wa, 0
	ldw bc, 0xd
	call Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPlay_MidiTimingJP
	ld a, l
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqAcc_InitPlayback_DrumShiftDone
	slaa bc

SeqAcc_InitPlayback_DrumShiftDone:
	andda16 xbc, 0xf19e
	jr z, SeqPlay_MidiTimingJP
	extz hl
	lds wa, 0
	ld bc, hl
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqPlay_MidiTimingJP
	setda 1, 0x28a7

SeqPlay_MidiTimingJP:
	jp Seq_SyncPositionAndOutputMIDITiming
SeqPlay_RestartWithVoiceConfig:
	.byte 0xd7, 0xfa, 0x04
	ldib_erp	251, 0
	ld	(1073:16), 0
	ld	(7560:16), 0
	ld	(7562:16), 0
	ld	a, (10407:16)
	set	0, a
	res	1, a
	ld	(10407:16), a
	call	15672365
	cp	(7570:16), 1
	jr	nz, 36
	ld	wa, (9000:16)
	lds	bc, 0
	call	15999481
	call	15985128
	ld	wa, (1052:16)
	cpda16 xwa, (9000)
	jr	nz, 12
	cp	(1051:16), 0
	jr	nz, 5
	ldib_erp	251, 1
	jr	19
SeqPlay_VoiceChannelCfg:
	.incbin "includes/romslices/v7_block_seqplay_voicechannelcfg.bin"
; === end v7 block ===
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	mriw4 0x93, 0x19, 0xaf, 0x28
	mriw4 0x92, 0x19, 0x66, 0x26

Seq_ScanForBarMarker:
	call	15999384
	ldb_erp	l, 250
	cp_erpb	250, 129
	jr	z, 6
	cp_erpb	250, 130
	jr	nz, 13
SeqData_BarMarkerWrite:
	mrdw5 0x9f, 0x04, 0x19, 0xaf, 0x28
	ld (9830:16), iz

SeqPlay_PopIzSkip6Ret:
	pop xiz
	inc 6, xsp
	ret

Seq_ScanForBar_AdvanceAndCheck:
	.byte 0x1d, 0x44, 0x00, 0xf4, 0xc7, 0xfa, 0xcf, 0x85
	.byte 0x66, 0xd6, 0xc7, 0xfa, 0x33, 0x07, 0x66, 0xd0
	.byte 0xc7, 0xfa, 0xcf, 0x90, 0x6e, 0xca, 0x1d, 0x98
	.byte 0x21, 0xf4, 0xc7, 0xfa, 0x9f, 0xc7, 0xfa, 0xd8
	.byte 0x6e, 0xd1, 0xf1, 0x5b, 0x04, 0xb8, 0xc7, 0xfb
	.byte 0x89, 0xd8, 0x12, 0x1e, 0x02, 0x00, 0x68, 0xc3
SeqPlay_ProcessTempoVoiceEvent:
	lda xsp, (xsp - 12)
	ld (xsp + 10), a
	ldw (xsp + 4), 0xffff
	ldw (xsp + 6), 0x0
	ld c, (xsp + 10)
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cp l, 0xe
	jrl nz, SeqPlay_TempoVoice_Return
	ldmw2 (xsp), 0x28af
	ldmw2 (xsp + 2), 0x2666
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	call SeqData_ReadNextByte
	cp l, 0x10
	jr ugt, SeqVoice_ChannelValidation_Check
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	incw 1, (xsp + 6)
	jr SeqVoice_EventAdvanceLoop

SeqPlay_TempoVoice_CheckB0:
	cp l, 0xb0
	jr nz, SeqVoice_EventAdvanceLoop
	lda xwa, (xsp + 8)
	calr SeqPlay_TempoVoice_ParseCtrl48
	cps hl, 0
	jr lt, SeqVoice_ValidateAndWriteDefault
	cpw (xsp + 8), 0x0
	jr lt, SeqVoice_EventAdvanceLoop
	cpw (xsp + 8), 0x3
	jr nz, SeqVoice_ValidateAndWriteDefault
	ld wa, (xsp + 8)
	ld (xsp + 4), wa

SeqVoice_EventAdvanceLoop:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	cpw (xsp + 6), 0x3
	jr c, SeqPlay_TempoVoice_ReadLoop

SeqVoice_ChannelValidation_Check:
	cpw (xsp + 4), 0x0
	jr ge, SeqPlay_TempoVoice_CheckNoteCount
	resda 0, 1115

SeqPlay_TempoVoice_CheckNoteCount:
	cpw (xsp + 6), 0x3
	jr nc, SeqVoice_ValidateAndWriteDefault
	resda 0, 1115

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
	cp (0x287a:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cp l, 0x48
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cps l, 3
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	ldb_erp L, 0xfb
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqPlay_TempoVoice_ParseCtrl48_Got3

SeqVoice_DataReadError_Return:
	ldw hl, 0xffff
	jr SeqPlay_TempoVoice_ParseCtrl48_Return

SeqPlay_TempoVoice_ParseCtrl48_Got3:
	call SeqData_ReadNextByte
	and l, 0x7
	cps l, 7
	jr nz, SeqData_EventParseExit
	stb_erp C, 0xfb
	and c, 0x7
	extz bc
	ld xwa, (xsp + 2)
	ld (xwa), bc

SeqData_EventParseExit:
	lds hl, 0

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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_DrumPart_ShiftDone
	slaa bc

SeqPlay_DrumPart_ShiftDone:
	ld wa, bc
	andda16 xbc, 0xf19e
	jr nz, SeqPlay_DrumPart_SetActiveFlag
	andda16 xwa, 8980
	jr z, SeqPlay_ClearCountersAndProcess

SeqPlay_DrumPart_SetActiveFlag:
	setda 6, 0x28ac

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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_IterateCh_ShiftDone
	slaa bc

SeqPlay_IterateCh_ShiftDone:
	andda16 xbc, 0xf19e
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
	cps c, 0
	jrl nz, SeqPlay_IncrLoopCounter
	lda xix, (xsp + 16)
	ld (xsp + 4), l
	ld xiy, xix
	ldib_erp 0xe2, 0

SeqPlay_IterateCh_CopyDataLoop:
	stb_erp L, 0xe2
	extz hl
	inc 2, hl
	ld e, (xsp + 4)
	dec 1, e
	extz de
	sla de, 3
	ld xbc, (xsp + 6)
	lda_dri XBC, 0x07, 0xe4, 0xe8
	extz xhl
	add xhl, xbc
	stb_erp E, 0xe2
	extz de
	ld c, (xhl)
	stb_dri C, 0x07, 0xf4, 0xe8
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqPlay_IterateCh_CopyDataLoop
	ld e, (xix)
	ld c, e
	and c, 0xf0
	ldb_erp C, 0xfb
	cp e, 0x82
	jr nz, SeqPlay_IterateCh_CheckEventType
	lds bc, 1
	ld a, (xsp + 10)
	and a, 0xf
	jr z, SeqPlay_IterateCh_ClearPartBit
	slaa bc

SeqPlay_IterateCh_ClearPartBit:
	cpl bc
	anddm16 8982, xbc
	anddm16 8980, xbc
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
	setda 1, 0x28a7
	cp (7572:16), 0
	jrl z, SeqPlay_IterateCh_TempoFlag0
	jrl SeqPlay_IterateCh_TempoFlag1

SeqPlay_IterateCh_CheckEvent86:
	cp e, 0x86
	jr nz, SeqPlay_IterateCh_CheckControlChange
	resda 1, 0x28a7
	cp (7572:16), 0
	jrl z, SeqPlay_IterateCh_TempoFlag0
	jrl SeqPlay_IterateCh_TempoFlag1

SeqPlay_IterateCh_CheckControlChange:
	lda xhl, (xix + 4)
	lda xbc, (xix + 5)
	cp_erpb 0xfb, 0xb0
	jrl nz, SeqPlay_IterateCh_NotControlChange
	ld a, (xsp + 2)
	cpda8 a, 8988
	jrl nz, SeqCh_DispatchMidiEvent
	cp (xix + 2), 0x48
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xix + 3)
	cps a, 6
	jr nz, SeqPlay_IterateCh_CtrlChange5
	bitm 2, (xbc)
	jr z, SeqCh_DispatchMidiEvent
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	setda 1, 8974
	ldw (4360:16), 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqCh_AllocSlotAndDispatch

SeqPlay_IterateCh_CtrlChange5:
	cps a, 5
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xbc)
	bit 2, a
	jr z, SeqPlay_IterateCh_CtrlChangeBit3
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	setda 1, 8974
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
	setda 1, 8974
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
	setda 6, 0x28ad

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
	cps l, 0
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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_CheckChCont_ShiftDone
	slaa bc

SeqPlay_CheckChCont_ShiftDone:
	andda16 xbc, 8982
	jrl nz, SeqPlay_IterateCh_ProcessChannel

SeqPlay_IncrLoopCounter:
	incm8 1, (xsp + 2)
	cp (xsp + 2), 0x10
	jrl ule, SeqPlay_IterateCh_PartLoop
	popw_erp 0xfa
	lda xsp, (xsp + 22)
	ret

SeqPlay_InitFromDemoRecord:
	resda 5, 0x28b3
	ldw (9004:16), 0
	resda 0, 0x28a6
	call AccWrap_PositionClear
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
	ei 0
	ld l, (1075:16)
	ld (9010:16), l
	call SeqMode_SendStatusUpdate
	ld (1073:16), 0
	setda 0, 0x28a7
	call SeqBuf_Init
	resda 1, 0x28a7
	calr SeqPlay_InitDemo_LoadVoiceData
	calr SeqPlay_IterateAllChannels
	ld a, (0x28a4:16)
	extz wa
	call Demo_ProcessRecordEntry
	cps l, 0
	jr z, SeqPlay_InitDemo_ClearRepeatBit
	setda 1, 0x28a7
	jr SeqPlay_InitDemo_SyncAndProcess

SeqPlay_InitDemo_ClearRepeatBit:
	resda 1, 0x28a7

SeqPlay_InitDemo_SyncAndProcess:
	call Seq_SyncPositionAndOutputMIDITiming
	calr SeqPlay_CheckDrumPartAndClearCounters
	ld (8956:16), 1
	ret

SeqPlay_InitDemo_LoadVoiceData:
	dec 4, xsp
	pushw_erp 0xfa
	ld a, (0x28a4:16)
	ldb_erp A, 0xfb
	extz wa
	call Demo_GetPresetBaseForPart
	stda32 0x283e, xhl
	stb_erp A, 0xfb
	extz wa
	call Demo_GetPresetBaseForPartExt
	ld (xsp + 2), xhl
	ldib_erp 0xfb, 1

SeqPlay_InitDemo_PartLoop:
	stb_erp E, 0xfb
	dec 1, e
	lds bc, 1
	ld a, e
	and a, 0xf
	jr z, SeqPlay_InitDemo_PartShiftDone
	slaa bc

SeqPlay_InitDemo_PartShiftDone:
	andda16 xbc, 0xf19e
	jr z, SeqPlay_InitDemo_PartLoopNext
	stb_erp A, 0xfb
	mul a, 0x3
	dec 3, a
	ld c, a
	extz bc
	inc 1, bc
	ld xwa, (xsp + 2)
	ldb_sri A, 0x07, 0xe0, 0xe4
	ldb_erp A, 0xf0
	extz ix
	stb_erp A, 0xfb
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
	stiw_ind 0x07, 0xe8, 0xe4, 0x00, 0x00
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
	push QIZ
	resda 5, (0x28b3)
	ld (0x1d94:16), 0x00
	ld a, (0x8c9a:16)
	cp A,0x87
	jr z, SeqPlay_Init_AccMode87_88
	cp A,0x88
	jr nz, SeqPlay_Init_CheckRepeatMode
SeqPlay_Init_AccMode87_88:
	call SeqPlay_ResetPlaybackState
	ldb_erp L, 0xfb
	jr SeqPlay_FindVoicesAndReturn

SeqPlay_Init_CheckRepeatMode:
	bit 1, (0x28b1:16)
	jr nz, SeqPlay_Init_RepeatMode
	calr SeqPlay_InitFreshPlayback
	ldb_erp L, 0xfb
	jr SeqPlay_FindVoicesAndReturn

SeqPlay_Init_RepeatMode:
	calr SeqPlay_InitResumePlayback
	ldb_erp L, 0xfb

SeqPlay_FindVoicesAndReturn:
	calr SeqPlay_FindSpecialVoices
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

SeqPlay_InitFreshPlayback:
	calr 63255

	ld a, (0x28b2:16)

	res 2, a

	res 1, a

	res 7, a

	ld (0x28b2:16), a

	resda 3, 0x28b3

	call	16635550

	resda 3, 0x28a7

	cpdi16 0x28a8, 0

	jrl z, 224

	ldw (8998:16), 0

	ldw (8954:16), 0xffff

	ldb l, 0x1

	ldb c, 0x0



SeqPlay_InitFresh_PartClearLoop:
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqPlay_InitFresh_PartShiftDone
	slaa de

SeqPlay_InitFresh_PartShiftDone:
	andda16 xde, 0x28a8
	jr z, SeqPlay_InitFresh_PartLoopNext
	ld a, l
	extz wa
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, SeqPlay_InitFresh_ClearBit
	slaa de

SeqPlay_InitFresh_ClearBit:
	cpl de
	anddm16 8980, xde
SeqPlay_InitFresh_PartLoopNext:
	inc	1, l
	inc	1, c
	cp	l, 16
	jr	ule, -47
	ld	a, (10418:16)
	bit	0, a
	jr	z, 23
	set	1, a
	ld	(10418:16), a
	ld	wa, (9832:16)
	ld	(9014:16), wa
	.byte 0xf1, 0xb3, 0x28, 0xbb
	call	16635550
SeqPlay_InitFresh_SetPosition:
	ldw	(9008:16), 0
	call	16016598
	ei	0x06
	ldw	(1052:16), 0
	ld	(1051:16), 0
	ei	0x00
	ld	a, (1075:16)
	ld	(9010:16), a
	call	16016734
	cpdi16	61854, 0
	jr	z, 10
	.byte 0xf1, 0xb3, 0x28, 0xbb
	call	16635550
	jr	24
SeqPlay_InitFresh_NoVoices:
	ldw (8980:16), 0
	ld a, (0x28a7:16)
	set 0, a
	set 1, a
	ld (0x28a7:16), a
	call SeqBuf_Init

SeqPlay_InitFresh_TempoInit:
	.byte 0x1d, 0x9e, 0xd6, 0xfd, 0x1d, 0xdb, 0x24, 0xef
	.byte 0x1d, 0x86, 0xad, 0xfd, 0xf1, 0xb2, 0x28, 0xc8
	.byte 0x6e, 0x10, 0xd1, 0x9e, 0xf1, 0x3f, 0x00, 0x00
	.byte 0x66, 0x04, 0x21, 0x0b, 0x68, 0x10
SeqPlay_InitFresh_StateB:
	ldb a, 0x7
	jr SeqPlay_StoreChannelVal

SeqPlay_InitFresh_State8orC:
	ldb a, 0x8
	cpdi16 0xf19e, 0
	jr z, SeqPlay_StoreChannelVal
	ldb a, 0xc

SeqPlay_StoreChannelVal:
	ld (8956:16), a

SeqPlay_InitFresh_Return:
	ldb l, 0x0
	ret

SeqPlay_InitResumePlayback:
	push xiz
	calr SeqAcc_InitPlaybackState
	ld a, (0x28b2:16)
	res 2, a
	res 1, a
	res 7, a
	ld (0x28b2:16), a
	cpdi16 0x28a8, 0
	jrl z, SeqPlay_InitResume_Return
	ldmm16 8998, 1052
	ldw (8954:16), 0xffff
	call SeqVoice_InitForRepeatMode
	ldib_erp 0xfb, 1

SeqPlay_InitResume_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_InitResume_ShiftDone
	slaa bc

SeqPlay_InitResume_ShiftDone:
	andda16 xbc, 0x28a8
	jr z, SeqPlay_InitResume_LoopNext
	stb_erp A, 0xfb
	ld (8986:16), a
	stb_erp A, 0xfb
	extz wa
	lds bc, 1
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
	.byte 0xf1, 0xb3, 0x28, 0xbb
	call	16635550
	.byte 0xd1, 0x1c, 0x04, 0x19, 0x30, 0x23
	call	16016598
	ld	a, (1075:16)
	ld	(9010:16), a
	call	16016734
	call	16635550
	call	15672365
	call	15672539
	call	16625030
	ld	a, (8986:16)
	ldb_erp	a, 251
	extz	wa
	lds	bc, 0
	call	15995988
	ld	iz, (61854:16)
	stb_erp	a, 251
	extz	wa
	lds	bc, 1
	call	15995988
	.byte 0xf1, 0xb2, 0x28, 0xc8
	jr	nz, 12
	cps	iz, 0
	jr	z, 4
	ldb	a, 19
	jr	12
SeqPlay_InitResume_State0F:
	ldb a, 0xf
	jr SeqPlay_StoreCheckValue

SeqPlay_InitResume_State10or14:
	ldb a, 0x10
	cps iz, 0
	jr z, SeqPlay_StoreCheckValue
	ldb a, 0x14

SeqPlay_StoreCheckValue:
	ld (8956:16), a

SeqPlay_InitResume_Return:
	ldb l, 0x0
	pop xiz
	ret

SeqPlay_FindSpecialVoices:
	lds wa, 0
	ldw BC, 0x000c
	call Part_FindVoiceByByte
	ld (0x2320:16), l
	lds wa, 0
	ldw BC, 0x000e
	call Part_FindVoiceByByte
	ld (0x2322:16), l
	lds wa, 0
	ldw BC, 0x000f
	call Part_FindVoiceByByte
	ld (0x2324:16), l
	ld a, (0x8c9a:16)
	cp A,0x87
	jr z, SeqPlay_ClearPositionAndFlags
	cp A,0x88
	jr z, SeqPlay_ClearPositionAndFlags
	resda 1, (0x230a)
SeqPlay_ClearPositionAndFlags:
	ld (7522:16), 0
	ldw (9006:16), 0
	resda 1, 0x28b3
	ret

SeqPlay_SaveAndPrepareState:
	pushw_erp 0xfa
	calr SeqPlay_PreparePlaybackState
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SeqPlay_SaveState_CheckActive
	resda 1, 0x28b3
	jr SeqPlay_ReassignVoicesAlt

SeqPlay_SaveState_CheckActive:
	.byte 0xf1, 0xc5, 0x28, 0xc8, 0x66, 0x26, 0xf1, 0xb3
	.byte 0x28, 0xb1, 0xc1, 0xfc, 0x22, 0x21, 0xd8, 0x12
	.byte 0xf2, 0xe2, 0x44, 0xe4, 0x31, 0xc3, 0x07, 0xe4
	.byte 0xe0, 0x19, 0xfc, 0x22, 0xf1, 0x3c, 0xf2, 0xc8
	.byte 0x6e, 0x39, 0xf1, 0xb3, 0x28, 0xb3, 0x1d, 0x9e
	.byte 0xd6, 0xfd, 0x68, 0x2f
SeqPlay_SaveState_NoActiveParts:
	.byte 0xf1, 0xb3, 0x28, 0xb3, 0x1d, 0x9e, 0xd6, 0xfd
	.byte 0xf1, 0xb3, 0x28, 0xc9, 0x6e, 0x10, 0xf1, 0xb2
	.byte 0x28, 0xc8, 0x66, 0x0a, 0xd1, 0x36, 0x23, 0x19
	.byte 0x68, 0x26, 0x1d, 0xd6, 0x64, 0xf4
SeqPlay_SaveState_CheckBit1:
	bit 1, (0x28b3:16)
	jr nz, SeqPlay_SaveState_SetPlayFlags
	calr SeqPlay_ReassignVoiceChannels
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SeqPlay_SaveState_NoActive

SeqPlay_ReassignVoicesAlt:
	stb_erp L, 0xfb
	jrl SeqPlay_ReturnFalse_Return

SeqPlay_SaveState_NoActive:
	cpdi16 0x28aa, 0
	jrl z, SeqPlay_ReturnFalse

SeqPlay_SaveState_SetPlayFlags:
	.byte 0xf1, 0xec, 0x8c, 0xb8, 0xf1, 0x6a, 0x26, 0xb8
	.byte 0xc1, 0xfc, 0x22, 0x21, 0xd8, 0x12, 0xf2, 0xe2
	.byte 0x44, 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe0, 0x19
	.byte 0xfc, 0x22, 0xc1, 0x0a, 0x23, 0x23, 0xcb, 0x31
	.byte 0x00, 0xf1, 0x0a, 0x23, 0x43, 0xc1, 0xb3, 0x28
	.byte 0x21, 0xc9, 0x33, 0x01, 0x66, 0x0a, 0xc9, 0x30
	.byte 0x01, 0xf1, 0xb3, 0x28, 0x41, 0x78, 0xa5, 0x00
SeqPlay_SaveState_CheckVoices:
	res 1, c
	ld (8970:16), c
	cpdi16 0xf19e, 0
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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_SaveState_ChordShiftDone
	slaa bc

SeqPlay_SaveState_ChordShiftDone:
	andda16 xbc, 0x28aa
	jr z, SeqPlay_AssignBassVoice
	lda xbc, (WidgetData_DrawbarPositionTable_0x82:24)
	bit 1, (0x28b1:16)
	jr z, SeqPlay_SaveState_ChordAssignDirect
	ldw wa, 0x12
	lds de, 2
	calr ToneVoice_AssignChannel
	jr SeqPlay_AssignBassVoice

SeqPlay_SaveState_ChordAssignDirect:
	extz de
	ld wa, de
	lds de, 2
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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_SaveState_BassShiftDone
	slaa bc

SeqPlay_SaveState_BassShiftDone:
	andda16 xbc, 0x28aa
	jr z, SeqPlay_ReturnFalse
	lda xbc, (WidgetData_DrawbarPositionTable_0x82:24)
	bit 1, (0x28b1:16)
	jr z, SeqPlay_SaveState_BassAssignDirect
	ldw wa, 0x12
	lds de, 2
	calr ToneVoice_AssignChannel
	jr SeqPlay_ReturnFalse

SeqPlay_SaveState_BassAssignDirect:
	extz de
	ld wa, de
	lds de, 2
	calr ToneVoice_AssignChannel
	ld a, (8994:16)
	extz wa
	call SeqEvent_CreateWithChannelValidation

SeqPlay_ReturnFalse:
	ldb l, 0x0

SeqPlay_ReturnFalse_Return:
	popw_erp 0xfa
	ret

SeqPlay_PreparePlaybackState:
	call KeyScan_Enable
	resda 2, (0x33de)
	ld a, (0x1d86:16)
	cps a, 1
	call_24 z, (SeqBuf_FlushAndReinit_VoiceCCEvents)
	lds wa, 0
	call UI_PostDialEnable
	ld wa, (0x2314:16)
	cps wa, 0
	jr z, KeyScan_DisableComplete_Return
	ld (0x28b4:16), wa
	bit 0, (0x28c5:16)
	jr z, .Lc_f3a09a
	bit 0, (0x28b2:16)
	jr z, .Lc_f3a09a
	ldmm16 0x2668, 0x2336
	call NoteEditSy_SendModeScrollReset
SeqPlay_Prepare_CheckRepeat:
.Lc_f3a09a:
	call SeqPlay_CheckRepeatAndReactivate
	call Seq_CheckChordVoiceAndSetFlag
	cp (0x8c98:16), 0x13
	jr z, SeqPlay_Prepare_LoadVoiceConfig
	setda 3, (0x28a7)
SeqPlay_Prepare_LoadVoiceConfig:
	calr SeqNote_LoadVoicePositions
	ldmm16 7588, 1052
	cpdi16 0x28a8, 0
	jr nz, KeyScan_DisableComplete_Return
	cp (7570:16), 0
	jr nz, SeqPlay_Prepare_SetState6
	ld (8956:16), 3
	jr SeqPlay_Prepare_CheckMode87

SeqPlay_Prepare_SetState6:
	ld (8956:16), 6

SeqPlay_Prepare_CheckMode87:
	.byte 0xc1, 0x9a, 0x8c, 0x21, 0xc9, 0xcf, 0x87, 0x66
	.byte 0x09, 0xc9, 0xcf, 0x88, 0x66, 0x04, 0xf1, 0x0a
	.byte 0x23, 0xb1
KeyScan_DisableComplete_Return:
	call KeyScan_Disable
	ldb l, 0x0
	ret

SeqPlay_HandlePlaybackEvent:
	ld	a, (35994:16)
	cp	a, 135
	jr	z, 5
	cp	a, 136
	jr	nz, 7
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
	.byte 0xf1, 0xae, 0x28, 0xb7, 0xf1, 0x94, 0x1d, 0x00
	.byte 0x00, 0xd1, 0xb4, 0x28, 0x20, 0xf1, 0x14, 0x23
	.byte 0x50, 0xf1, 0xb4, 0x28, 0x02, 0x00, 0x00, 0x30
	.byte 0x32, 0x00, 0x1d, 0xe3, 0xdf, 0xf3, 0x1d, 0xbe
	.byte 0x09, 0xfe, 0x1d, 0x26, 0xee, 0xfd, 0x1d, 0x6b
	.byte 0xf1, 0xf3, 0x1d, 0xad, 0xdf, 0xf3, 0x1d, 0x36
	.byte 0xe2, 0xf6, 0xd1, 0x9e, 0xf1, 0x3f, 0x00, 0x00
	.byte 0x66, 0x70, 0xc1, 0x98, 0x8c, 0x3f, 0x13, 0x6e
	.byte 0x10, 0xf1, 0x9e, 0xf1, 0x02, 0x00, 0x00, 0x1d
	.byte 0x9e, 0xd6, 0xfd, 0xf1, 0xb4, 0x28, 0x02, 0x00
	.byte 0x00
SeqPlay_HandleEvent_SyncTiming:
	.byte 0xf1, 0xa7, 0x28, 0xba, 0x1d, 0xad, 0xe1, 0xf3
	.byte 0xf1, 0x31, 0x04, 0x00, 0x00, 0x1d, 0x9e, 0xd6
	.byte 0xfd, 0xc1, 0xde, 0x33, 0x21, 0xc9, 0x33, 0x02
	.byte 0x66, 0x2d, 0xc1, 0x78, 0x32, 0x25, 0xc1, 0x79
	.byte 0x32, 0x23, 0xc1, 0x8c, 0x32, 0x21, 0xcd, 0xd8
	.byte 0x6e, 0x08, 0xcb, 0xd8, 0x6e, 0x04, 0xc9, 0xd8
	.byte 0x66, 0x06
SeqPlay_HandleEvent_ClearAccFlag:
	resda 0, 0x28a6
	jr SeqPlay_CheckSilentAndStop

SeqPlay_HandleEvent_SetAccFlag:
	.byte 0xf1, 0xa6, 0x28, 0xb8, 0xc1, 0xde, 0x33, 0x21
	.byte 0xc9, 0x31, 0x01, 0xf1, 0xde, 0x33, 0x41
SeqPlay_CheckSilentAndStop:
	bit 0, (0x28a6:16)
	jr z, SeqPlay_HandleEvent_ClearBit2
	call AccWrap_FullStop
	setda 1, 0x28a7

SeqPlay_HandleEvent_ClearBit2:
	resda 2, 0x28a7

SeqPlay_ClearFlagsRet:
	ldb l, 0x0
	ret


; -----------------------------------------------------------------------------
; Section: Voice Processing & Cleanup
; -----------------------------------------------------------------------------
; Voice and note processing, stop/cleanup routines,
; and playback finalization.
; -----------------------------------------------------------------------------

SeqPlay_ProcessVoiceAndNotes:
	lda	xsp, (xsp-12)
	push	xiz
	ld	a, (35994:16)
	cp	a, 135
	jr	z, 5
	cp	a, 136
	jr	nz, 7
SeqPlay_ProcessVoice_AccMode:
	call SeqAcc_ProcessTempoEvents
	jrl SeqPlay_ProcessVoice_Return

SeqPlay_ProcessVoice_CheckActive:
	cpdi16 0x28aa, 0
	jr nz, SeqPlay_ProcessVoice_ReadTempo
	ld a, (0x28be:16)
	cp a, 0xff
	jr z, SeqPlay_StopAndCleanup
	bit 0, (8970:16)
	jr nz, SeqPlay_StopAndCleanup
	inc 1, a
	ld c, a
	extz bc
	lds wa, 0
	ldw de, 0xd
	call Part_WriteSubBlock32
SeqPlay_StopAndCleanup:
	ldw	wa, 50
	call	15982563
	call	16648638
	call	16641574
	call	15987051
	call	15982432
	call	16179766
	call	16094901
	ld	a, (10418:16)
	res	2, a
	res	1, a
	ld	(10418:16), a
	ldw	(10408:16), 0
	call	16635550
	ldw	(10420:16), 0
	.byte 0xf1, 0xb3, 0x28, 0xb3
	call	16635550
	call	15984117
	call	16635550
	jrl	178
SeqPlay_ProcessVoice_ReadTempo:
	ld wa, (9012:16)
	ld (9832:16), wa
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
	jr z, SeqPlay_ProcessVoice_ValidateData

SeqPlay_ProcessVoice_TempoLoop:
	lda xwa, (xsp + 8)
	calr Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
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
	ld	(7522:16), 0
	ldw	(10420:16), 0
	ld	a, (10418:16)
	res	2, a
	res	1, a
	ld	(10418:16), a
	call	16179766
	call	16094901
	call	16005505
	ld	(7568:16), 1
	ld	(7584:16), 1
	.byte 0xf1, 0xa7, 0x28, 0xb3, 0xf1, 0x0a, 0x23, 0xb9
	call	15984117
	ld	(10430:16), 255
	.byte 0xf1, 0x6a, 0x26, 0xc9
	jr	nz, 16
	cp	(35992:16), 10
	jr	z, 13
	ldw	wa, 10
	call	16355414
	jr	4
SeqPlay_ProcessVoice_PartChange:
	call UI_PostRefreshEvent

SeqPlay_ProcessVoice_ClearBit:
	resda 1, 9834

SeqPlay_ProcessVoice_Return:
	ldb l, 0x0
	pop xiz
	lda xsp, (xsp + 12)
	ret

SeqPlay_ProcessNoteAndTempo:
	lda xsp, (xsp - 10)
	push xiz
	ldw (xsp + 4), 0x0
	calr SeqNote_ProcessNoteOn
	cps l, 0
	jr nz, SeqPlay_ReadTempo_Return
	cpdi16 0x28a8, 0
	jr z, SeqPlay_ReadTempoEvents_ReturnZero
	ld a, (0x28c5:16)
	bit 0, a
	jr z, SeqPlay_ReadTempoEvents
	bit 6, a
	jr z, SeqPlay_ReadTempoEvents_ReturnZero

SeqPlay_ReadTempoEvents:
	lda xwa, (xsp + 6)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
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
	ld iz, (1052:16)
	ld a, (1051:16)
	ldb_erp A, 0xfb
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
	ldb l, 0x3
	jr SeqPlay_ReadTempo_Return

SeqPlay_ReadTempo_CheckLoop:
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0xa
	jr c, SeqPlay_ReadTempoEvents

SeqPlay_ReadTempoEvents_ReturnZero:
	ldb l, 0x0

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
	stb_erp C, 0xf8
	ld xwa, (xsp + 4)
	ld (xwa), c
	ld a, (xwa)
	extz wa
	call MIDI_GetEventSizeFromByte
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr nz, TempoRingBuf_Read_CheckCount
	lds wa, 1
	call SeqData_SetErrorCode

TempoRingBuf_Read_NextByte:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cps iz, 0
	jr ge, TempoRingBuf_Read_ProcessByte

TempoRingBuf_Read_CheckCount:
	ldib_erp 0xfa, 1
	cpib_erp 0xfb, 1
	jr ule, TempoRingBuf_Read_Return

TempoRingBuf_Read_ExtLoop:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cps iz, 0
	jr ge, TempoRingBuf_Read_StoreByte
	lds wa, 2
	call SeqData_SetErrorCode

TempoRingBuf_Read_StoreByte:
	stb_erp C, 0xfa
	extz bc
	stb_erp E, 0xf8
	ld xwa, (xsp + 4)
	stb_dri E, 0x07, 0xe0, 0xe4
	inc1b_erp 0xfa
	stb_erp A, 0xfa
	cpb_erp A, 0xfb
	jr c, TempoRingBuf_Read_ExtLoop

TempoRingBuf_Read_Return:
	stb_erp L, 0xfb
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
	cps l, 0
	jr ge, SeqVoice_Dispatch_Check84
	ldb l, 0xff
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
	lds de, 1
	and a, 0xf
	jr z, SeqVoice_Dispatch_CheckD2
	slaa de

SeqVoice_Dispatch_CheckD2:
	andda16 xde, 0x28a8
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
	ldb l, 0x0

SeqVoice_Dispatch_ScanNext:
	pop xiz
	inc 6, xsp
	ret

SeqNote_ReconfigureAfterRepeat:
	dec 8, xsp
	jrl SeqNote_Reconfig_BassDone

SeqNote_Reconfig_CheckChannels:
	ldb_sri0 A, (xhl + 0x008b)
	add a, 0x9
	cp bc, de
	jr nz, SeqNote_Reconfig_ProcessChannel
	cpdm8 1051, a
	jr nc, SeqVoice_CopyEventToSlot
	jrl SeqNote_Reconfig_ChordSetup

SeqNote_Reconfig_ProcessChannel:
	ld c, a
	cp a, 0x60
	jr c, SeqVoice_CopyEventToSlot
	sub c, 0x60
	cpdm8 1051, c
	jrl c, SeqNote_Reconfig_ChordSetup

SeqVoice_CopyEventToSlot:
	lda xix, (xsp)
	lda_dri XWA, 0xed, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqNote_Reconfig_DispatchLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqNote_Reconfig_DispatchLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	ld e, l
	extz de
	cps hl, 0
	jr lt, SeqNote_Reconfig_BassSetup
	lda xbc, (xsp)
	cp (7522:16), 1
	jr z, SeqNote_Reconfig_Complete
	ldw wa, 0x12
	jr SeqNote_Reconfig_Return

SeqNote_Reconfig_Done:
	cp wa, hl
	jr nz, SeqNote_Reconfig_MidiSync
	ldb_sri0 A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqVoice_ReadPartEvent

SeqNote_Reconfig_MidiSync:
	ldw wa, 0x12

SeqNote_Reconfig_Return:
	calr ToneVoice_AssignChannel
	jr SeqVoice_ReadPartEvent

SeqNote_Reconfig_Complete:
	lda xix, (9016:16)
	ld wa, (7524:16)
	ldw_sri0 HL, (xix + 0x0088)
	cp wa, hl
	jr ule, SeqNote_Reconfig_Done
	jr SeqVoice_ReadPartEvent

SeqNote_Reconfig_BassSetup:
	lds wa, 3
	call SeqData_SetErrorCode

SeqVoice_ReadPartEvent:
	ldw wa, 0x13
	lds bc, 1
	calr SeqPart_ReadEventStream

SeqNote_Reconfig_BassDone:
	lda xhl, (9016:16)
	ld bc, (1052:16)
	ldw_sri0 DE, (xhl + 0x0088)
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
	ldb_sri0 A, (xde + 0x008b)
	cp a, (xsp + 10)
	jr nc, SeqNote_TrackPos_BassSetup

SeqNote_Reconfig_SubSetup:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqNote_Reconfig_SubDone:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XHL, 0xe9, 0x88, 0x00
	ld ix, wa
	extz xix
	add xix, xhl
	stb_erp L, 0xe2
	extz hl
	ld a, (xix)
	stb_dri A, 0x07, 0xf4, 0xec
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqNote_Reconfig_SubDone
	ld a, (xbc)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, SeqNote_TrackChannelPositions
	lds wa, 4
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
	lds bc, 1
	calr SeqPart_ReadEventStream

SeqNote_TrackPos_CheckBass:
	lda xde, (9016:16)
	ldw_sri0 WA, (xde + 0x0088)
	cp wa, iz
	jr ule, SeqNote_Reconfig_ChordDone

SeqNote_TrackPos_BassSetup:
	popw iz
	lda xsp, (xsp + 10)
	ret

SeqNote_TrackPos_BassDone:
	cp wa, hl
	jr nz, SeqNote_TrackPos_ChordSetup
	ldb_sri0 A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqNote_TrackPos_Return

SeqNote_TrackPos_ChordSetup:
	ldw wa, 0x12
	jr SeqNote_TrackPos_Done

SeqNote_TrackPos_ChordDone:
	lda xix, (9016:16)
	ld wa, (7524:16)
	ldw_sri0 HL, (xix + 0x0088)
	cp wa, hl
	jr ule, SeqNote_TrackPos_BassDone
	jr SeqNote_TrackPos_Return

SeqNote_LoadVoicePositions:
	ldw (7586:16), 0
	ld wa, (8982:16)
	bit 0, wa
	jr z, SeqNote_LoadPos_Channel1
	ld wa, (1052:16)
	cpda16 xwa, 9016
	jr c, SeqNote_LoadPos_Channel1
	ldw (7586:16), 1

SeqNote_LoadPos_Channel1:
	ld wa, (8982:16)
	bit 1, wa
	jr z, SeqNote_LoadPos_Channel2
	ld wa, (1052:16)
	cpda16 xwa, 9024
	jr c, SeqNote_LoadPos_Channel2
	ordi16 7586, 2

SeqNote_LoadPos_Channel2:
	ld wa, (8982:16)
	bit 2, wa
	jr z, SeqNote_LoadPos_Channel3
	ld wa, (1052:16)
	cpda16 xwa, 9032
	jr c, SeqNote_LoadPos_Channel3
	ordi16 7586, 4

SeqNote_LoadPos_Channel3:
	ld wa, (8982:16)
	bit 3, wa
	jr z, SeqNote_LoadPos_Channel4
	ld wa, (1052:16)
	cpda16 xwa, 9040
	jr c, SeqNote_LoadPos_Channel4
	ordi16 7586, 8

SeqNote_LoadPos_Channel4:
	ld wa, (8982:16)
	bit 4, wa
	jr z, SeqNote_LoadPos_Channel5
	ld wa, (1052:16)
	cpda16 xwa, 9048
	jr c, SeqNote_LoadPos_Channel5
	ordi16 7586, 16

SeqNote_LoadPos_Channel5:
	ld wa, (8982:16)
	bit 5, wa
	jr z, SeqNote_LoadPos_Channel6
	ld wa, (1052:16)
	cpda16 xwa, 9056
	jr c, SeqNote_LoadPos_Channel6
	ordi16 7586, 32

SeqNote_LoadPos_Channel6:
	ld wa, (8982:16)
	bit 6, wa
	jr z, SeqNote_LoadPos_Channel7
	ld wa, (1052:16)
	cpda16 xwa, 9064
	jr c, SeqNote_LoadPos_Channel7
	ordi16 7586, 64

SeqNote_LoadPos_Channel7:
	ld wa, (8982:16)
	bit 7, wa
	jr z, SeqNote_LoadPos_Channel8
	ld wa, (1052:16)
	cpda16 xwa, 9072
	jr c, SeqNote_LoadPos_Channel8
	ordi16 7586, 128

SeqNote_LoadPos_Channel8:
	ld wa, (8982:16)
	bit 8, wa
	jr z, SeqNote_LoadPos_Channel9
	ld wa, (1052:16)
	cpda16 xwa, 9080
	jr c, SeqNote_LoadPos_Channel9
	ordi16 7586, 256

SeqNote_LoadPos_Channel9:
	ld wa, (8982:16)
	bit 9, wa
	jr z, SeqNote_LoadPos_Channel10
	ld wa, (1052:16)
	cpda16 xwa, 9088
	jr c, SeqNote_LoadPos_Channel10
	ordi16 7586, 512

SeqNote_LoadPos_Channel10:
	ld wa, (8982:16)
	bit 10, wa
	jr z, SeqNote_LoadPos_Channel11
	ld wa, (1052:16)
	cpda16 xwa, 9096
	jr c, SeqNote_LoadPos_Channel11
	ordi16 7586, 1024

SeqNote_LoadPos_Channel11:
	ld wa, (8982:16)
	bit 11, wa
	jr z, SeqNote_LoadPos_Channel12
	ld wa, (1052:16)
	cpda16 xwa, 9104
	jr c, SeqNote_LoadPos_Channel12
	ordi16 7586, 2048

SeqNote_LoadPos_Channel12:
	ld wa, (8982:16)
	bit 12, wa
	jr z, SeqNote_LoadPos_Channel13
	ld wa, (1052:16)
	cpda16 xwa, 9112
	jr c, SeqNote_LoadPos_Channel13
	ordi16 7586, 4096

SeqNote_LoadPos_Channel13:
	ld wa, (8982:16)
	bit 13, wa
	jr z, SeqNote_LoadPos_Channel14
	ld wa, (1052:16)
	cpda16 xwa, 9120
	jr c, SeqNote_LoadPos_Channel14
	ordi16 7586, 8192

SeqNote_LoadPos_Channel14:
	ld wa, (8982:16)
	bit 14, wa
	jr z, SeqNote_LoadPos_Channel15
	ld wa, (1052:16)
	cpda16 xwa, 9128
	jr c, SeqNote_LoadPos_Channel15
	ordi16 7586, 0x4000

SeqNote_LoadPos_Channel15:
	ld wa, (8982:16)
	extz xwa
	bit 15, wa
	ret z
	ld wa, (1052:16)
	cpda16 xwa, 9136
	ret c
	ordi16 7586, 0x8000
	ret

SeqNote_ProcessNoteOn:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), 0x0
	cpdi16 0x28b4, 0
	jr nz, SeqNote_NoteOn_HasParts
	ldb l, 0x0
	jrl SeqNote_ProcessNoteOn_Return

SeqNote_NoteOn_HasParts:
	bit 5, (0x28b3:16)
	jr z, SeqNote_NoteOn_CheckRepeat
	ei 6
	ld a, (1051:16)
	inc 1, a
	ld (1051:16), a
	cp a, 0x60
	jr c, SeqNote_NoteOn_TickDone
	ld (1051:16), 0
	incdi16 1, (1052)

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
	cpdi16 0x28a8, 0
	jr z, SeqNote_AllocateMainChannel

SeqNote_FindExtra_CheckPosition:
	lda xbc, (9016:16)
	ldw_sri0 WA, (xbc + 0x0080)
	cp (xsp + 4), wa
	jr c, SeqNote_AllocateMainChannel
	cp (xsp + 4), wa
	jr nz, SeqNote_FindExtra_ProcessChannel
	ld a, (xsp + 8)
	cpb_sri_rm A, 0xe5, 0x83, 0x00
	jr c, SeqNote_AllocateMainChannel

SeqNote_FindExtra_ProcessChannel:
	ldw wa, 0x11
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl nz, SeqNote_LoadNoteParam_Return
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	cpdi16 0x28a8, 0
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	stw_dri WA, 0x07, 0xe4, 0xf0
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
	lds bc, 1
	and a, 0xf
	jr z, SeqNote_AllocBass_SetBitAndFlags
	slaa bc

SeqNote_AllocBass_SetBitAndFlags:
	orddm16 8982, xbc
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	lds bc, 1
	and a, 0xf
	jr z, SeqNote_AllocSub_SetBitAndFlags
	slaa bc

SeqNote_AllocSub_SetBitAndFlags:
	orddm16 8982, xbc
	ld (7530:16), 1
	ld (0x2866:16), 1

SeqNote_ProcessCurrentChannel:
	cp (8988:16), 255
	jr nz, SeqNote_ProcessCurrent_DrumCheck
	jr VoiceConfig_SlotCheck

SeqNote_ProcessCurrent_ComparePos:
	lda xwa, (9016:16)
	ldw_sri0 DE, (xwa + 0x0098)
	ldb_sri0 A, (xwa + 0x009b)
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
	lda xbc, (WidgetData_DrawbarPositionTable_0x86:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	andda16 xwa, 8982
	jr nz, SeqNote_ProcessCurrent_ComparePos

SeqNote_UpdateScoreDisplay:
	cpdi16 7578, 0xffff
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
	ldw_sri0 DE, (xwa + 0x00a0)
	ldb_sri0 A, (xwa + 0x00a3)
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
	lda xbc, (WidgetData_DrawbarPositionTable_0x86:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	andda16 xwa, 8982
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
	lda xhl, (WidgetData_DrawbarPositionTable_0x86:24)
	ldw_sri DE, 0x07, 0xec, 0xe8
	andda16 xde, 8982
	jr nz, VoiceConfig_EventType_ReadData
	jr SeqNote_CheckActiveChannels

SeqNote_CheckActiveEntry:
	extz wa
	ld bc, wa
	muls bc, 0x9
	lda xde, (7606:16)
	lda_dri XDE, 0x07, 0xe8, 0xe4
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
	cps iz, 0
	jr z, SeqNote_DispatchActive_CheckSpecial

SeqNote_DispatchActive_TestBit:
	bit 0, iz
	jr z, SeqNote_ShiftAndIncrement

SeqNote_DispatchActive_ReadPart:
	stb_erp E, 0xfb
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	lds bc, 1
	ld a, e
	and a, 0xf
	jr z, SeqNote_DispatchActive_ClearBit
	slaa bc

SeqNote_DispatchActive_ClearBit:
	cpl bc
	anddm16 7586, xbc
	jr SeqNote_ShiftAndIncrement

SeqNote_DispatchActive_ProcessChan:
	stb_erp A, 0xfb
	extz wa
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jr z, SeqNote_DispatchActive_LoadConfig
	cp (xsp + 6), 0x5
	jr z, SeqNote_ShiftAndIncrement
	jr SeqNote_LoadNoteParam_Return

SeqNote_DispatchActive_LoadConfig:
	stb_erp A, 0xfb
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
	cps iz, 0
	jr nz, SeqNote_DispatchActive_TestBit

SeqNote_DispatchActive_CheckSpecial:
	cp (8988:16), 255
	jr z, SeqNote_ProcessSpecialChannels
	cpdi16 7574, 0xffff
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
	call_24 z, BitMapOut_PrepareAndDisplay
	ldw (7574:16), 0xffff

SeqNote_SpecialChan_LoadAddr:
	lda xbc, (7574:16)
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, SeqNote_SpecialChan_ComparePos

SeqNote_ProcessSpecialChannels:
	cp (7556:16), 0
	call_24 nz, SeqBuf_FlushAndReinit_NoteEvents
	cp (7558:16), 0
	call_24 nz, SeqBuf_FlushAndReinit_VoiceCCEvents

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
	cpdi16 0x28b4, 0
	jr nz, SeqRepeat_LoadTickAndPos
	ldb l, 0x0
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
	lda_dri XDE, 0x07, 0xe8, 0xe4
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
	cps iz, 0
	jr z, SeqRepeat_ProcessSpecialChan

SeqRepeat_TestPartBit:
	bit 0, iz
	jr z, SeqNote_StreamAdvanceJoin

SeqRepeat_ReadPartData:
	stb_erp E, 0xfb
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	lda xbc, (9016:16)
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	lds bc, 1
	ld a, e
	and a, 0xf
	jr z, SeqRepeat_ClearPartBit
	slaa bc

SeqRepeat_ClearPartBit:
	cpl bc
	anddm16 7586, xbc
	jr SeqNote_StreamAdvanceJoin

SeqRepeat_ProcessChannel:
	stb_erp A, 0xfb
	extz wa
	calr SeqNote_ProcessForChannelAlt
	ld (xsp + 8), l
	cp (xsp + 8), 0x0
	jr z, SeqRepeat_ParseStream
	cp (xsp + 8), 0x5
	jr z, SeqNote_StreamAdvanceJoin
	jr SeqRepeat_LoadResult

SeqRepeat_ParseStream:
	stb_erp A, 0xfb
	extz wa
	call SeqData_ParseSequenceStream
	bit 0, iz
	jr nz, SeqRepeat_ReadPartData

SeqNote_StreamAdvanceJoin:
	srl iz, 1
	inc1b_erp 0xfb
	cps iz, 0
	jr nz, SeqRepeat_TestPartBit

SeqRepeat_ProcessSpecialChan:
	cp (7556:16), 0
	call_24 nz, SeqBuf_FlushAndReinit_NoteEvents
	cp (7558:16), 0
	call_24 nz, SeqBuf_FlushAndReinit_VoiceCCEvents

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
	call_24 z, SeqBuf_FlushAndReinit_VoiceCCEvents
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call_24 lt, SeqBuf_FlushAndReinit_NoteEvents
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	cps hl, 0
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
	ldb l, 0x0
	jr SeqPartScan_Return

SeqPartScan_RetryLoop:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x12
	jr ule, SeqPartScan_ReadAndCopy

SeqPartScan_ReturnError:
	ldb l, 0x1

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
	ldb_erp A, 0xfb
	ld a, (xsp + 20)
	cpb_erp A, 0xfb
	jr nz, SeqNoteCh_CheckMasterChan
	stb_erp A, 0xfb
	extz wa
	calr Chan_IsActive
	cps l, 1
	jr nz, SeqNoteCh_CheckStatusByte
	lds wa, 1
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
	cpib_sri 0x07, 0xe0, 0xe4, 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld (xsp + 6), 0x0

SeqNoteCh_CheckMasterChan:
	cp (xsp + 20), 0x14
	jr nz, SeqNoteCh_CheckZeroChannel
	stb_erp A, 0xfb
	extz wa
	calr Chan_IsActive
	cps l, 1
	jrl nz, SeqNote_ReturnNotProcessed
	lds wa, 0
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
	ldb l, 0x0

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
	stb_dri A, 0x07, 0xf4, 0xe8
	inc 1, l
	cps l, 6
	jr c, SeqNoteCh_CopyEventLoop
	cp (xsp + 20), 0x11
	jr nz, SeqNoteCh_StoreChannel
	cpdi16 0x28a8, 0
	jr z, SeqNoteCh_StoreChannel
	ldmi16 (xsp + 20), 0x231a
	ld (xsp + 8), 0x11
	jr SeqNoteCh_WriteStatusByte

SeqNoteCh_StoreChannel:
	ld a, (xsp + 20)
	ld (xsp + 8), a

SeqNoteCh_WriteStatusByte:
	lda_dri XHL, 0xf1, 0x82, 0x00
	cp (7522:16), 1
	jr nz, SeqNote_HandleMasterChannel
	ld a, (xsp + 8)
	cpda8 a, 8986
	jr nz, SeqNoteCh_CheckChannel11
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
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
	ldb_sri0 A, (xix + 0x0083)
	extz wa
	cpdm16 7526, xwa
	jr ule, SeqNote_HandleMasterChannel

SeqNoteCh_DeactivateCheck82:
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqNote_DeactivateChannelBit
	slaa bc

SeqNote_DeactivateChannelBit:
	cpl bc
	anddm16 8982, xbc
	jrl SeqNote_ReturnNotProcessed

SeqNoteCh_LoadVoiceAndCompare:
	ld wa, (7524:16)
	ldw_sri0 DE, (xix + 0x0080)
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
	stiw_ind 0x07, 0xf0, 0xe0, 0xff, 0xff
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
	cpda8 a, 8996
	jr z, SeqNoteCh_HandleAccompVoice
	cp (xsp + 20), 0x15
	jr nz, SeqNoteCh_DispatchEventType

SeqNoteCh_HandleAccompVoice:
	ld a, (xsp + 20)
	extz wa
	calr VoiceType_CheckDrumOrControl
	cps hl, 0
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
	stiw_ind 0x07, 0xe0, 0xe4, 0xf0, 0xff

SeqNote_ReturnNotProcessed:
	ldb l, 0x0
	jrl SeqNote_WriteEvent_Return

SeqNote_SetDrumChannelPair:
	ldmi16 (xsp + 20), 0x2324

SeqNoteCh_DispatchEventType:
	lda xbc, (xsp + 10)
	ld e, (xbc)
	ld a, e
	and a, 0xf0
	ldb_erp A, 0xfb
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
	cps l, 0
	jr nz, SeqNoteCh_ClearAndRetStatus
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cps l, 1
	jrl z, SeqNote_NoteOff_WritePart
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_ClearAndRetStatus:
	ld (xsp + 4), 0x0
	jrl SeqNote_WriteEvent_RetStatus

SeqNoteCh_HandleControlChange:
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cps l, 1
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
	cps l, 1
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
	lds de, 1
	and a, 0xf
	jr z, SeqNoteCh_EndMark_ShiftDone
	slaa de

SeqNoteCh_EndMark_ShiftDone:
	cpl de
	anddm16 8982, xde
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	cpdi16 0x28a8, 0
	jr nz, SeqNoteCh_EndMark_SetStatus5
	cp (7570:16), 0
	jr nz, SeqNoteCh_EndMark_SetStatus5
	ld wa, (0xf19e:16)
	ld bc, (0x28b4:16)
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
	cps l, 1
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleEventD1:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

SeqNoteCh_HandleEventD3:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
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
	cps l, 1
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
	cps l, 1
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
	cps l, 1
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
	cps l, 1
	jr nz, SeqNote_ConditionalWriteToBuffer
	lda xwa, (xsp + 10)
	ld c, (xsp + 20)
	extz bc
	calr SeqNote_UpdatePlayPosition_B
	jr SeqNote_ConditionalWriteToBuffer

SeqNote_ScanNextEvent_Entry:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr nz, SeqNote_ScanNextEvent_ClearBit
	ld a, (xsp + 20)
	extz wa
	calr SeqPart_ScanNextEvent
	cps l, 0
	jr z, SeqNote_ConditionalWriteToBuffer
	ldb l, 0x4
	jr SeqNote_WriteEvent_Return

SeqNote_ScanNextEvent_ClearBit:
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqNote_ScanNextEvent_ShiftDone
	slaa bc

SeqNote_ScanNextEvent_ShiftDone:
	cpl bc
	anddm16 0x28b4, xbc

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
	lds hl, 0
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
	ldb_erp W, 0xe6
	ld xiy, xde
	ldib_erp 0xe2, 0

SeqNote_ProcessAlt_CopyDataLoop:
	stb_erp L, 0xe2
	extz hl
	ld iz, hl
	inc 2, iz
	stb_erp L, 0xe6
	dec 1, l
	extz hl
	sla hl, 3
	lda xix, (9016:16)
	exts xhl
	add xhl, xix
	ld ix, iz
	extz xix
	add xix, xhl
	stb_erp L, 0xe2
	extz hl
	ld a, (xix)
	stb_dri A, 0x07, 0xf4, 0xec
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
	cps l, 0
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
	ldb_erp L, 0xfb

SeqMidi_EmitEventToBuffer:
	cpib_erp 0xfb, 0
	jr z, SeqNote_ProcessAlt_RetStatus

SeqNote_WriteChannelToBuffer:
	lda xwa, (xsp + 6)
	stb_erp C, 0xfb
	extz bc
	call SeqBuf_WriteMidiEvent

SeqNote_ProcessAlt_RetStatus:
	ld l, (xsp + 4)
	jrl SeqNote_ProcessAlt_Return

SeqNote_ProcessAlt_ProgramChange:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyChannelDirect
	ldb_erp L, 0xfb
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
	lds de, 1
	ld a, w
	and a, 0xf
	jr z, SeqNote_ProcessAlt_82ShiftDone
	slaa de

SeqNote_ProcessAlt_82ShiftDone:
	cpl de
	anddm16 8982, xde
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	ld wa, (0xf19e:16)
	ld bc, (0x28b4:16)
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
	ldb_erp L, 0xfb
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
	lds wa, 5
	call SeqData_SetErrorCode
	ld a, (xsp + 14)
	extz wa
	calr SeqPart_ScanNextEvent
	cps l, 0
	jrl z, SeqMidi_EmitEventToBuffer
	ldb l, 0x4

SeqNote_ProcessAlt_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

Chan_IsActive:
	cps a, 1
	jr c, Chan_IsActive_RetTrue
	cp a, 0x10
	jr ugt, Chan_IsActive_RetTrue
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, Chan_IsActive_ShiftDone
	slaa bc

Chan_IsActive_ShiftDone:
	ld wa, (0xf19e:16)
	and wa, bc
	jr nz, Chan_IsActive_RetTrue
	ldb l, 0x0
	ret

Chan_IsActive_RetTrue:
	ldb l, 0x1
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
	cps d, 5
	jr z, AccPedalConfig_ValidCtrl5_6_7
	cps d, 6
	jr z, AccPedalConfig_ValidCtrl5_6_7
	cps d, 7
	jrl nz, AccPedalConfig_ReturnError7

AccPedalConfig_ValidCtrl5_6_7:
	ld a, (xbc + 4)
	ldb_erp A, 0xfa
	ld a, (xbc + 5)
	ldb_erp A, 0xfb
	bitm 0, (xbc)
	jr z, AccPedalConfig_CheckBit1
	set_erpb 0xfa, 0x07

AccPedalConfig_CheckBit1:
	bitm 1, (xbc)
	jr z, AccPedalConfig_CheckCtrl7
	set_erpb 0xfb, 0x07

AccPedalConfig_CheckCtrl7:
	cps	d, 7
	jr	nz, 82	; -> 0xF3B4D8
	stb_erp	e, 250
	extz	de
	stb_erp	a, 251
	extz	wa
	pushw	wa
	ldw	wa, 72
	lds	bc, 7
	call	16624211
	ld	(7546:16), 72
	ld	(7548:16), 7
	stb_erp	a, 250
	ld	(7550:16), a
	stb_erp	a, 251
	ld	(7552:16), a
	ld	a, (xsp+2)
	dec	1, a
	ld	(7554:16), a
	ld	c, (7546:16)
	ld	b, (7548:16)
	ld	e, (7550:16)
	ld	d, (7552:16)
	ld	a, (7554:16)
	call	SeqVoice_UpdateTempoParam
Chan_IsActive_RetFalse:
	ldb l, 0x0
	jrl AccPedalCfg_ReturnAndCleanup

AccPedalConfig_NotCtrl7:
	ldb_erp D, 0xf0
	extz ix
	ld iy, ix
	stb_erp L, 0xfa
	extz hl
	ld bc, hl
	bit 2, (1054:16)
	jrl z, AccPedalCfg_CheckBit6Replay
	stb_erp E, 0xf4
	cps d, 6
	jr nz, AccPedalConfig_Ctrl5Path
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_StoreCtrl6ValsAlt
	bit_erpb 0xfa, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, AccPedalConfig_StoreCtrl6Vals
	cp (7560:16), 0
	jrl nz, AccPedalConfig_ClearFlag7560

AccPedalConfig_StoreCtrl6Vals:
	stb_erp	a, 251
	extz	wa
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jrl	373	; -> 0xF3B69B
AccPedalConfig_StoreCtrl6ValsAlt:
	stb_erp	a, 251
	extz	wa
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jrl	353	; -> 0xF3B69B
AccPedalConfig_Ctrl5Path:
	ld	a, (8988:16)
	bit_erpb	251, 4
	jr	z, 40	; -> 0xF3B56C
	bit_erpb	250, 4
	jrl	z, 349	; -> 0xF3B6A8
	cp	(xsp+2), a
	jr	nz, 5	; -> 0xF3B555
	ld	(12870:16), 1
AccPedalConfig_Ctrl5Store:
	stb_erp	c, 251
	extz	bc
	stb_erp	a, 240
	ld	(13292:16), a
	ld	(13273:16), l
	ld	(13274:16), c
	jrl	303	; -> 0xF3B69B
AccPedalConfig_Ctrl5Bit5:
	bit_erpb	251, 5
	jr	z, 40	; -> 0xF3B59A
	bit_erpb	250, 5
	jrl	z, 303	; -> 0xF3B6A8
	cp	(xsp+2), a
	jr	nz, 5	; -> 0xF3B583
	ld	(12870:16), 1
AccPedalConfig_Ctrl5Bit5Store:
	stb_erp	c, 251
	extz	bc
	stb_erp	a, 240
	ld	(13292:16), a
	ld	(13273:16), l
	ld	(13274:16), c
	jrl	257	; -> 0xF3B69B
AccPedalConfig_Ctrl5Bit2:
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_Ctrl5Bit3
	bit_erpb 0xfa, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, AccPedalConfig_Ctrl5Bit2Store
	cp (7560:16), 0
	jr nz, AccPedalConfig_ClearFlag7560

AccPedalConfig_Ctrl5Bit2Store:
	stb_erp	a, 251
	extz	wa
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jrl	208	; -> 0xF3B69B
AccPedalConfig_Ctrl5Bit3:
	bit_erpb 0xfb, 0x03
	jr z, AccPedalCfg_CheckBit6
	bit_erpb 0xfa, 0x03
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, AccPedalConfig_StorePedalValues
	cp (7560:16), 0
	jr z, AccPedalConfig_StorePedalValues

AccPedalConfig_ClearFlag7560:
	ld (7560:16), 0
	jrl Chan_IsActive_RetFalse

AccPedalConfig_StorePedalValues:
	stb_erp	a, 251
	extz	wa
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jrl	151	; -> 0xF3B69B
AccPedalCfg_CheckBit6:
	stb_erp	a, 251
	extz	wa
	bit_erpb	251, 6
	jr	z, 21	; -> 0xF3B624
	bit_erpb	250, 6
	jrl	z, 146	; -> 0xF3B6A8
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jr	119	; -> 0xF3B69B
AccPedalCfg_CheckBit7:
	bit_erpb 0xfb, 0x07
	jr z, AccPedalCfg_StoreValues
	bit_erpb 0xfa, 0x07
	jr z, AccPedalConfig_ReturnError7

AccPedalCfg_StoreValues:
	ld	(13292:16), e
	ld	(13273:16), c
	ld	(13274:16), a
	jr	93
AccPedalCfg_CheckBit6Replay:
	.byte 0xc7, 0xfb, 0x33, 0x06, 0x66, 0x27, 0xc1, 0x9c
	.byte 0x8c, 0x3f, 0x81, 0x6e, 0x0a, 0xf1, 0xb3, 0x28
	.byte 0xcd, 0x66, 0x04, 0xc7, 0xfb, 0x30, 0x06
AccPedalConfig_ApplyChannelSettings:
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xf0
	ld e, a
	cps d, 6
	jr nz, AccPedalConfig_CheckMaskBits
	bit_erpb 0xfb, 0x02
	jr z, AccPedalConfig_CheckMaskBits
	jr AccPedalCfg_StoreMaskValues

AccPedalCfg_CheckBit7Alt:
	bit_erpb	251, 7
	jr	nz, -28	; -> 0xF3B655
	stb_erp	e, 251
	extz	de
	stb_erp	a, 244
	ld	(13292:16), a
	ld	(13273:16), c
	ld	(13274:16), e
	jr	20	; -> 0xF3B69B
AccPedalConfig_CheckMaskBits:
	stb_erp A, 0xfb
	and a, 0xc
	jr z, AccPedalCfg_CheckZeroMask

AccPedalCfg_StoreMaskValues:
	ld	(13292:16), c
	ld	(13273:16), l
	ld	(13274:16), e
AccPedalConfig_ReplayAndReturnOK:
	call AccWrap_ReplaySavedPedal
	jrl Chan_IsActive_RetFalse

AccPedalCfg_CheckZeroMask:
	cpib_erp 0xfb, 0
	jrl z, Chan_IsActive_RetFalse

AccPedalConfig_ReturnError7:
	ldb l, 0x7

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
	cps c, 0
	jr nz, AccPedalConfig_ChannelDirect_Error
	ld a, (xiz + 4)
	ld (xsp + 4), a
	bitm 0, (xiz)
	jr z, AccPedalDirect_ClearBit7
	setm 7, (xsp + 4)

AccPedalDirect_ClearBit7:
	.byte 0xd9, 0x12, 0x8f, 0x04, 0x25, 0xda, 0x12, 0x8e
	.byte 0x05, 0x21, 0xd8, 0x12, 0x28, 0x30, 0x48, 0x00
	.byte 0x1d, 0x53, 0xaa, 0xfd, 0xf1, 0x7a, 0x1d, 0x00
	.byte 0x48, 0x8e, 0x03, 0x19, 0x7c, 0x1d, 0x8f, 0x04
	.byte 0x19, 0x7e, 0x1d, 0x8e, 0x05, 0x19, 0x80, 0x1d
	.byte 0x8f, 0x06, 0x21, 0xc9, 0x69, 0xf1, 0x82, 0x1d
	.byte 0x41, 0xc1, 0x7a, 0x1d, 0x23, 0xc1, 0x7c, 0x1d
	.byte 0x22, 0xc1, 0x7e, 0x1d, 0x25, 0xc1, 0x80, 0x1d
	.byte 0x24, 0xc1, 0x82, 0x1d, 0x21, 0x1d, 0xa6, 0xaf
	.byte 0xfc, 0x8f, 0x06, 0x23, 0xd9, 0x12, 0xd8, 0xa8
	.byte 0x1d, 0x75, 0x17, 0xf4, 0xcf, 0xcf, 0x10, 0x6e
	.byte 0x0a, 0x8f, 0x04, 0x19, 0x8c, 0x1d, 0x8e, 0x05
	.byte 0x19, 0x8e, 0x1d
AccPedalDirect_ReturnOK:
	ldb l, 0x0
	jr AccPedalDirect_Return

AccPedalConfig_ChannelDirect_Error:
	ld a, (xsp + 6)
	dec 1, a
	ld (xiz + 6), a
	ldb l, 0x7

AccPedalDirect_Return:
	pop xiz
	inc 4, xsp
	ret

AccPedalConfig_ApplyTempo:
	pushw_erp 0xfa
	ld e, (xbc + 2)
	ld a, (xbc + 3)
	ldb_erp A, 0xfb
	bit_erpb 0xfb, 0x00
	jr z, AccPedalTempo_ClearBit7
	set 7, e

AccPedalTempo_ClearBit7:
	srl_erpb 0xfb, 0x01

	lda xbc, (0xfc5a:16)

	ld (xbc + 8), e

	stb_erp A, 0xfb

	ld (xbc + 9), a

	extz de

	pushw 0xff

	ldw wa, 0x48

	ldw bc, 0x8

	call	16624211

	stb_erp E, 0xfb

	extz de

	pushw 0x1

	ldw wa, 0x48

	ldw bc, 0x9

	.byte 0x1d, 0x53, 0xaa, 0xfd	; call AddswbWr (v7 addr)

	.byte 0x1d, 0x4d, 0x9b, 0xfc	; call SeqTimer_UpdateTempoReg (v7 addr)

	ldb l, 0x0

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
	setda 1, 0x28a7
	jr SeqNotePos_Return

SeqNotePos_CheckInterruptFlag:
	ei 6
	ld a, (xsp)
	cpda8 a, 8988
	jr z, SeqNotePos_CheckMainChannel
	cpda8 a, 8990
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
	ld a, (1051:16)
	inc 1, a
	cp a, 0x5f
	jr ule, SeqNotePos_StoreTick
	ldb a, 0x0

SeqNotePos_StoreTick:
	ld (1071:16), a

SeqNotePos_SetUpdateFlag:
	setda 0, 1073
	ei 0

SeqNotePos_Return:
	inc 6, xsp
	ret

SeqNotePos_DataBlock_A:
	ei	6
	ld	a, (1051:16)
	inc	1, a
	cp	a, 96
	jr	c, 2
	ldb	a, 0
	ld	(1071:16), a
	.byte 0xf1
	ldw	bc, 0xb804
	di
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
	cpda8 a, 8996
	jr z, SeqNotePosB_CalcTick
	cpda8 a, 8994
	jr nz, SeqNotePosB_WriteFromStack

SeqNotePosB_CalcTick:
	ld a, (1051:16)
	inc 1, a
	cp a, 0x5f
	jr ule, SeqNotePosB_StoreTick
	ldb a, 0x0

SeqNotePosB_StoreTick:
	ld (1072:16), a
	jr SeqNotePosB_SetUpdateFlag

SeqNotePosB_WriteFromStack:
	ld xwa, (xsp + 2)
	mrdb5 0x88, 0x01, 0x19, 0x30, 0x04

SeqNotePosB_SetUpdateFlag:
	setda 3, 1073
	ei 0

SeqNote_StackCleanupRet:
	inc 6, xsp
	ret

SeqNotePosB_DataBlock:
	ei	6
	ld	a, (1051:16)
	inc	1, a
	cp	a, 96
	jr	c, 2
	ldb	a, 0
	ld	(1072:16), a
	.byte 0xf1
	ldw	bc, 0xbb04
	di
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
	ldb_erp A, 0xfa
	cp_erpb 0xfa, 0xff
	jrl z, VoiceConfig_CounterIncr

SeqVoice_EndMark_ProcessSlot:
	stb_erp A, 0xfa
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
	stb_erp A, 0xfa
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8195:16)
	ldb_sri A, 0x07, 0xe0, 0xe4
	ldb_erp A, 0xfb
	ld l, (0x28c5:16)
	and l, 0x41
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp l, 0x41
	jr nz, SeqVoice_LoadDefaultParams
	lds hl, 1
	stb_erp A, 0xfb
	and a, 0xf
	jr z, SeqVoice_MatchAssign_ShiftDone
	slaa hl

SeqVoice_MatchAssign_ShiftDone:
	andda16 xhl, 0x28a8
	jr z, SeqVoice_LoadDefaultParams
	lda xhl, (xsp + 6)
	add bc, bc
	lda xwa, (0x291e:16)
	ldw_sri WA, 0x07, 0xe0, 0xe4
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
	stb_erp A, 0xfa
	extz wa
	lda xbc, (xsp + 10)
	ldb_erp A, 0xee
	ld xix, xbc
	ldib_erp 0xea, 0

SeqVoice_ApplyToChannels_Loop:
	stb_erp L, 0xea
	extz hl
	stb_erp A, 0xee
	extz wa
	muls wa, 0xc
	ld de, wa
	lda xwa, (8186:16)
	lda_dri XWA, 0x07, 0xe0, 0xe8
	ld iy, hl
	extz xiy
	add xiy, xwa
	stb_erp E, 0xea
	extz de
	ld a, (xiy)
	stb_dri A, 0x07, 0xf0, 0xe8
	inc1b_erp 0xea
	cpib_erp 0xea, 4
	jr c, SeqVoice_ApplyToChannels_Loop
	ld (xbc + 1), 0x0
	lda xwa, (xsp + 6)
	lds de, 4
	call Part_CopyBytesToVoiceBlock
	stb_erp A, 0xfa
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
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
	lds de, 2
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
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	lda xhl, (xix + 2)
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp d, 0x41
	jr nz, SeqVoice_ApplyChannels_FromTable
	lds iz, 1
	stb_erp A, 0xfb
	and a, 0xf
	jr z, SeqVoice_ApplyChannels_ShiftDone
	slaa iz

SeqVoice_ApplyChannels_ShiftDone:
	andda16 xiz, 0x28a8
	jr z, SeqVoice_ApplyChannels_FromTable
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	lda xwa, (0x291e:16)
	stw_dri IX, 0x07, 0xe0, 0xe4
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
	lda_dri XWA, 0x07, 0xf4, 0xe4
	ld (xwa), ix
	ld (xwa + 2), de

SeqVoice_ApplyChannels_UpdateSlot:
	stb_erp A, 0xfa
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8186:16)
	exts xbc
	add xbc, xwa

SeqVoice_ApplyChannels_NextSlot:
	ld a, (xbc + 11)
	ldb_erp A, 0xfa
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
	lds bc, 0
	calr VoiceConfig_FindChannelMatch
	ldw wa, 0x12
	ld xbc, (xsp + 16)
	lds de, 1
	calr ToneVoice_AssignChannel
	jr VoiceConfig_ReturnAndCleanup

VoiceConfig_CounterIncr_Check:
	ldib_erp 0xfb, 1

VoiceConfig_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, VoiceConfig_PartShiftDone
	slaa bc

VoiceConfig_PartShiftDone:
	andda16 xbc, 0x28a8
	jr z, VoiceConfig_PartLoopNext
	stb_erp A, 0xfb
	extz wa
	ld xbc, (xsp + 16)
	lds de, 1
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
	ldb_erp A, 0xe7
	ld xiy, xde
	ldib_erp 0xe6, 0

PartAssign_CopySlotLoop:
	stb_erp A, 0xe6
	ldb_erp A, 0xf0
	extz ix
	stb_erp A, 0xe7
	extz wa
	muls wa, 0xc
	lda xhl, (8186:16)
	exts xwa
	add xwa, xhl
	ld iz, ix
	extz xiz
	add xiz, xwa
	stb_erp A, 0xe6
	ldb_erp A, 0xf0
	extz ix
	ld a, (xiz)
	stb_dri A, 0x07, 0xf4, 0xf0
	inc1b_erp 0xe6
	cpib_erp 0xe6, 4
	jr c, PartAssign_CopySlotLoop
	muls bc, 0xc
	lda_dri XIX, 0x07, 0xec, 0xe4
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
	lds de, 1
	and a, 0xf
	jr z, ToneVoice_Type80_ShiftDone
	slaa de

ToneVoice_Type80_ShiftDone:
	andda16 xde, 0x28aa
	jr z, ToneVoice_VoiceTypeCheck
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type80_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 4
	jr ToneVoice_Type80_Assign

ToneVoice_Type80_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 4

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
	lds de, 1
	and a, 0xf
	jr z, ToneVoice_Type85_ShiftDone
	slaa de

ToneVoice_Type85_ShiftDone:
	andda16 xde, 0x28aa
	jr z, ToneVoice_Type86_CheckCh94
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type85_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 2
	jr ToneVoice_Type85_Assign

ToneVoice_Type85_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 2

ToneVoice_Type85_Assign:
	calr ToneVoice_AssignChannel

ToneVoice_Type86_CheckCh94:
	ld c, (8994:16)
	cp c, 0xff
	jr z, ToneVoice_ChannelAssignRet
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, ToneVoice_Type86_ShiftDone
	slaa de

ToneVoice_Type86_ShiftDone:
	andda16 xde, 0x28aa
	jr z, ToneVoice_ChannelAssignRet
	bit 1, (0x28b1:16)
	jr z, ToneVoice_Type86_UsePartIndex
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 2
	jr ToneVoice_Type86_Assign

ToneVoice_Type86_UsePartIndex:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 2

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
	ldb_erp A, 0xee
	ld xix, xiz
	ldib_erp 0xe6, 0

SeqVoiceBuf_CopySlotLoop:
	stb_erp L, 0xe6
	extz hl
	stb_erp A, 0xee
	extz wa
	muls wa, 0xc
	lda xde, (8186:16)
	exts xwa
	add xwa, xde
	ld iy, hl
	extz xiy
	add xiy, xwa
	stb_erp A, 0xe6
	extz wa
	ldb_sri A, 0x07, 0xf0, 0xe0
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
	lds hl, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqVoiceBuf_ActiveShiftDone
	slaa hl

SeqVoiceBuf_ActiveShiftDone:
	andda16 xhl, 0x28a8
	jr z, SeqVoiceBuf_LoadFromTable
	lda xhl, (xsp + 10)
	add bc, bc
	lda xwa, (0x291e:16)
	ldw_sri WA, 0x07, 0xe0, 0xe4
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
	lds de, 4
	call Part_CopyBytesToVoiceBlock
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda_dri XDE, 0x07, 0xe4, 0xe0
	lda xwa, (xsp + 10)
	ld bc, (xwa)
	ld (xde + 6), bc
	ld bc, (xwa + 2)
	ld (xde + 8), c
	ld bc, (xsp + 8)
	ld (xde + 4), bc
	cpdi16 8954, 0xffff
	jr nz, SeqVoiceBuf_CheckMinPosition
	mrdw5 0x9f, 0x08, 0x19, 0xfa, 0x22

SeqVoiceBuf_CheckMinPosition:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld xbc, xiz
	lds de, 2
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
	lds iz, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqVoiceBuf_ActiveShiftDoneB
	slaa iz

SeqVoiceBuf_ActiveShiftDoneB:
	andda16 xiz, 0x28a8
	jr z, SeqVoiceBuf_LoadFromTableB
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	lda xwa, (0x291e:16)
	stw_dri IX, 0x07, 0xe0, 0xe4
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
	lda_dri XWA, 0x07, 0xf4, 0xe4
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
	lda_dri XDE, 0x07, 0xec, 0xe0
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
	ldb_erp A, 0xfb
	ld a, (xbc + 3)
	ldb_erp A, 0xfa
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
	lds de, 1
	and a, 0xf
	jr z, SeqPartCfg_Tempo48_ShiftDone
	slaa de

SeqPartCfg_Tempo48_ShiftDone:
	andda16 xde, 0x28aa
	jr z, SeqPartCfg_CheckCh94
	bit 1, (0x28b1:16)
	jr z, SeqPartCfg_Tempo48_UsePartIdx
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	lds de, 6
	jr SeqPartCfg_Tempo48_Assign

SeqPartCfg_Tempo48_UsePartIdx:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	lds de, 6

SeqPartCfg_Tempo48_Assign:
	calr ToneVoice_AssignChannel

SeqPartCfg_CheckCh94:
	ld c, (8994:16)
	cp c, 0xff
	jr z, SeqPartCfg_ReturnOK
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, SeqPartCfg_Ch94_ShiftDone
	slaa de

SeqPartCfg_Ch94_ShiftDone:
	andda16 xde, 0x28aa
	jr z, SeqPartCfg_ReturnOK
	bit 1, (0x28b1:16)
	jr z, SeqPartCfg_Ch94_UsePartIdx
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	lds de, 6
	jr SeqPartCfg_Ch94_Assign

SeqPartCfg_Ch94_UsePartIdx:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	lds de, 6

SeqPartCfg_Ch94_Assign:
	calr ToneVoice_AssignChannel

SeqPartCfg_ReturnOK:
	ldb l, 0x0
	jr SeqPartCfg_Return

SeqPartCfg_ReturnError6:
	ldb l, 0x6

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
	ldb_erp A, 0xfa
	cp_erpb 0xfa, 0xff
	jr nz, SeqSetupVoice_ValidateSlot
	ldb l, 0x1
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
	stb_erp A, 0xfa
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
	ldb_erp A, 0xfb
	ld xwa, (xsp + 4)
	stb_erp C, 0xfb
	add c, (xwa + 4)
	ldb_erp C, 0xfb
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
	stb_erp A, 0xfa
	extz wa
	ld bc, wa
	muls bc, 0x9
	lda xde, (7606:16)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	ld xhl, (xsp + 4)
	ld c, (xhl)
	ld (xde + 4), c
	stb_erp C, 0xfb
	ld (xde + 5), c
	ld c, (xhl + 2)
	ld (xde + 6), c
	ld (xde + 7), 0x0
	ld c, (xsp + 8)
	dec 1, c
	ld (xde + 8), c
	ld (xde + 2), iz
	calr NotePool_InsertEntry
	ldb l, 0x0

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
	ldb_erp A, 0xe2
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
	lds ix, 1
	and a, 0xf
	jr z, ToneVoice_Assign_ShiftDone
	slaa ix

ToneVoice_Assign_ShiftDone:
	andda16 xix, 0x28a8
	jr z, ToneVoice_Assign_FromTable
	lda xix, (xsp)
	add hl, hl
	lda xwa, (0x291e:16)
	ldw_sri WA, 0x07, 0xe0, 0xec
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
	ldb_erp A, 0xe2
	ld a, (xsp + 4)
	extz wa
	dec 1, a
	ldb_erp A, 0xee
	stb_erp L, 0xee
	extz hl
	lda xde, (xsp)
	lda xbc, (xde + 2)
	cp_erpb 0xe2, 0x41
	jr nz, ToneVoice_Assign_WriteFromTable
	ld a, (xsp + 4)
	dec 1, a
	lds ix, 1
	and a, 0xf
	jr z, ToneVoice_Assign_WriteShiftDone
	slaa ix

ToneVoice_Assign_WriteShiftDone:
	andda16 xix, 0x28a8
	jr z, ToneVoice_Assign_WriteFromTable
	ld ix, (xde)
	ld de, (xbc)
	add hl, hl
	lda xwa, (0x291e:16)
	stw_dri IX, 0x07, 0xe0, 0xec
	stb_erp A, 0xee
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
	lda_dri XWA, 0x07, 0xe0, 0xec
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	incdi16 1, (9152)
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
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
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
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqReassign_PartShiftDone
	slaa bc

SeqReassign_PartShiftDone:
	andda16 xbc, 0x28a8
	jrl z, SeqReassign_PartLoopNext
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqReassign_ProcessAndDecrement
	stb_erp A, 0xfb
	extz wa
	call Part_ClearAndStealSingleVoice
	stb_erp A, 0xfb
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqReassign_ClearBitShiftDone
	slaa bc

SeqReassign_ClearBitShiftDone:
	cpl bc
	anddm16 8982, xbc

SeqReassign_ProcessAndDecrement:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqReassign_ReturnError2
	cp (7528:16), 0
	jr z, SeqReassign_ReturnError2
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	stb_erp A, 0xfb
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
	ldb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqReassign_SingleShiftDone
	slaa bc

SeqReassign_SingleShiftDone:
	andda16 xbc, 8980
	jrl nz, SeqReassign_UpdateAndNotify
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xffff
	jr nz, SeqReassign_SetVoiceBitAndWrite

SeqReassign_ReturnError2:
	ldb l, 0x2
	jrl SeqReassign_Return

SeqReassign_SetVoiceBitAndWrite:
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	stb_erp C, 0xfb
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
	lds de, 1
	ld a, l
	and a, 0xf
	jr z, SeqReassign_OrPartBits
	slaa de

SeqReassign_OrPartBits:
	orddm16 8982, xde
	orddm16 0x28b4, xde
	orddm16 8980, xde
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	stb_erp A, 0xfb
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
	call_24 z, SeqPlay_PrepareDrumVoice

SeqReassign_ReturnOK:
	ldb l, 0x0

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
	lds wa, 0
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ld (xsp + 4), l
	cp (xsp + 4), 0xff
	jrl z, SeqPlay_RestoreReturn2
	ld a, (xsp + 4)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqAccVoice_ShiftDone
	slaa bc

SeqAccVoice_ShiftDone:
	andda16 xbc, 8982
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
	ldb_sri0 A, (xhl + 0x009b)
	cp a, (xsp + 18)
	jrl ugt, SeqAccVoice_JumpRestore

SeqAccVoice_SetupCopyLoop:
	lda xix, (xsp + 10)
	ld xiy, xix
	ldib_erp 0xe2, 0

SeqAccVoice_CopySlotLoop:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XBC, 0xed, 0x98, 0x00
	ld de, wa
	extz xde
	add xde, xbc
	stb_erp C, 0xe2
	extz bc
	ld a, (xde)
	stb_dri A, 0x07, 0xf4, 0xe4
	inc1b_erp 0xe2
	lda xbc, (xix + 4)
	lda xde, (xix + 5)
	cpib_erp 0xe2, 6
	jr c, SeqAccVoice_CopySlotLoop
	ld a, (xsp + 4)
	dec 1, a
	lds hl, 1
	and a, 0xf
	jr z, SeqAccVoice_ShiftDoneCheck
	slaa hl

SeqAccVoice_ShiftDoneCheck:
	.byte 0x84, 0x21, 0xc9, 0xcf, 0xb0, 0x7e, 0x11, 0x01
	.byte 0x8c, 0x02, 0x3f, 0x48, 0x6e, 0x3d, 0x8c, 0x03
	.byte 0x21, 0xc9, 0xdd, 0x7e, 0xcd, 0x00, 0xea, 0x8c
	.byte 0x82, 0x21, 0xc9, 0xcc, 0x0c, 0x66, 0x2c, 0xe9
	.byte 0x8a, 0x81, 0x21, 0xc9, 0xcc, 0x0c, 0x66, 0x23
	.byte 0xf1, 0x0e, 0x23, 0xb9, 0xd1, 0x9e, 0xf1, 0xc3
	.byte 0x66, 0x19, 0x82, 0x23, 0xd9, 0x12, 0x84, 0x21
	.byte 0xd8, 0x12, 0xf1, 0xec, 0x33, 0x00, 0x05, 0xf1
	.byte 0xd9, 0x33, 0x43, 0xf1, 0xda, 0x33, 0x41
SeqAccVoice_ReplaySavedPedal:
	call AccWrap_ReplaySavedPedal

ToneVoice_AssignChannel_LoadConfig:
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig
	lda xix, (xsp + 10)
	ld xiz, xix
	ldib_erp 0xe2, 0

SeqAccVoice_CopyChannelLoop:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda xde, (9016:16)
	lda_dri XBC, 0xe9, 0x98, 0x00
	ld iy, wa
	extz xiy
	add xiy, xbc
	stb_erp L, 0xe2
	extz hl
	ld a, (xiy)
	stb_dri A, 0x07, 0xf8, 0xec
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccVoice_CopyChannelLoop
	cp (xix), 0x82
	jr nz, SeqPlay_WriteVoiceData
	lda_dri XHL, 0xe9, 0x9b, 0x00
	ld a, (xhl)
	cp a, 0x30
	jr ule, SeqAccVoice_AdjustOctave
	inc_sriw 1, 0xe9, 0x98, 0x00
	ld a, (xhl)
	sub a, 0x30
	ld (xhl), a

SeqAccVoice_AdjustOctave:
	addmi8 (xhl), 0x30
	lda_dri XDE, 0xe9, 0x98, 0x00
	ld wa, (xde)
	ld a, (xhl)
	ld (xix + 1), a
	ldb l, 0x0

SeqAccVoice_WriteChannelData:
	ld e, l
	extz de
	inc 2, de
	extz xde
	add xde, xbc
	ld a, l
	extz wa
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xde), a
	inc 1, l
	cps l, 6
	jr c, SeqAccVoice_WriteChannelData

SeqPlay_WriteVoiceData:
	lda xhl, (9016:16)
	lda_dri XWA, 0xed, 0x98, 0x00
	ld (xsp + 6), xwa
	ld wa, (xwa)
	cp wa, (xsp + 20)
	jrl ule, SeqAccVoice_ComparePosition

SeqAccVoice_JumpRestore:
	jr SeqPlay_RestoreReturn2

SeqAccVoice_CheckPedalType6:
	.byte 0xc9, 0xde, 0x7e, 0x63, 0xff, 0xea, 0x8c, 0xb2
	.byte 0xca, 0x76, 0x5c, 0xff, 0xe9, 0x88, 0xb1, 0xca
	.byte 0x76, 0x55, 0xff, 0xf1, 0x0e, 0x23, 0xb9, 0xd1
	.byte 0x9e, 0xf1, 0xc3, 0x76, 0x4a, 0xff, 0x80, 0x23
	.byte 0xd9, 0x12, 0x84, 0x21, 0xd8, 0x12, 0xf1, 0xec
	.byte 0x33, 0x00, 0x06, 0xf1, 0xd9, 0x33, 0x43, 0xf1
	.byte 0xda, 0x33, 0x41, 0x78, 0x2e, 0xff
SeqAccVoice_HandleNoteOn:
	cp a, 0x90
	jr nz, SeqAccVoice_HandleEndMark82
	andda16 xhl, 0xf19e
	jrl z, ToneVoice_AssignChannel_LoadConfig
	lds wa, 0
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
	lds wa, 0
	ldw bc, 0x10
	call Part_FindVoiceByByte
	ld (xsp), l
	cp (xsp), 0xff
	jrl z, SeqPlay_BassEpilogue18
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqBass_ShiftDone
	slaa bc

SeqBass_ShiftDone:
	andda16 xbc, 8982
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
	ldb_erp C, 0xee
	ld xiy, xde
	ldib_erp 0xe2, 0

SeqBass_CopySlotLoop:
	stb_erp C, 0xe2
	extz bc
	ld ix, bc
	inc 2, ix
	stb_erp L, 0xee
	dec 1, l
	extz hl
	sla hl, 3
	ld xbc, (xsp + 2)
	lda_dri XBC, 0x07, 0xe4, 0xec
	extz xix
	add xix, xbc
	stb_erp L, 0xe2
	extz hl
	ld c, (xix)
	stb_dri C, 0x07, 0xf4, 0xec
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
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqPlay_BassCheck_TestBit
	slaa de

SeqPlay_BassCheck_TestBit:
	andda16 xde, 8982
	jrl nz, SeqBass_ReadAndCompare

SeqPlay_BassEpilogue18:
	lda xsp, (xsp + 18)
	ret

SeqPlay_AssignChordVoices:
	lda xsp, (xsp - 14)
	ld (xsp + 10), c
	ld (xsp + 12), wa
	ld xiy, WidgetData_DrawbarPositionTable_0xA6
	lda xix, (xsp + 2)
	lds bc, 4
	ldirw
	lds wa, 0
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ld (xsp), l
	cp (xsp), 0xff
	jrl z, SeqPlay_ChordEpilogue14
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_Chord_ShiftDone
	slaa bc

SeqPlay_Chord_ShiftDone:
	andda16 xbc, 8982
	jrl z, SeqPlay_ChordEpilogue14
	addmi8 (xsp + 10), 0x28
	cp (xsp + 10), 0x60
	jrl c, SeqPlay_Chord_NextPart
	submi8 (xsp + 10), 0x60
	incw 1, (xsp + 12)
	jrl SeqPlay_Chord_NextPart

SeqPlay_Chord_CompareLoop:
	lda xde, (9016:16)
	ldw_sri0 WA, (xde + 0x00a0)
	cp wa, (xsp + 12)
	jrl ugt, SeqPlay_ChordEpilogue14
	cp wa, (xsp + 12)
	jr nz, SeqPlay_Chord_CheckMatch
	ldb_sri0 A, (xde + 0x00a3)
	cp a, (xsp + 10)
	jrl ugt, SeqPlay_ChordEpilogue14

SeqPlay_Chord_CheckMatch:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqPlay_Chord_CopyDataLoop:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XHL, 0xe9, 0xa0, 0x00
	ld ix, wa
	extz xix
	add xix, xhl
	stb_erp L, 0xe2
	extz hl
	ld a, (xix)
	stb_dri A, 0x07, 0xf4, 0xec
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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_Chord_NextShiftDone
	slaa bc

SeqPlay_Chord_NextShiftDone:
	andda16 xbc, 8982
	jrl nz, SeqPlay_Chord_CompareLoop

SeqPlay_ChordEpilogue14:
	lda xsp, (xsp + 14)
	ret

SeqCh_ClearActivePartBit:
	ld c, a
	ld a, c
	extz wa
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, SeqCh_ClearActive_ShiftDone
	slaa de

SeqCh_ClearActive_ShiftDone:
	cpl de
	anddm16 0x28b4, xde
	anddm16 8980, xde
	ld a, (0xfc5f:16)
	and a, 0x30
	ret nz
	ld a, (8988:16)
	cp c, a
	ret nz
	dec 1, c
	lds de, 1
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
	lda_dri XDE, 0x07, 0xec, 0xe0
	ld iy, (xde + 2)
	ld w, (xde + 5)
	ld (xsp + 8), w
	lda xix, (7602:16)
	lda xwa, (xix + 1)
	ld (xsp + 4), xwa
	ld a, (xwa)
	ldb_erp A, 0xe2

NotePool_Insert_ScanLoop:
	lda xbc, (xde + 1)
	cp_erpb 0xe2, 0xff
	jr nz, NotePool_Insert_CompareAndLink
	ld (xde), 0xff
	ld a, (xix)
	ldb_erp A, 0xe2
	ld (xbc), a
	cp_erpb 0xe2, 0xff
	jr z, NotePool_Insert_UpdateHead
	stb_erp A, 0xe2
	extz wa
	muls wa, 0x9
	ld bc, wa
	ld a, (xsp + 10)
	stb_dri A, 0x07, 0xec, 0xe4

NotePool_Insert_UpdateHead:
	ld a, (xsp + 10)
	ld (xix), a
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ldb_erp A, 0xe2
	cp_erpb 0xe2, 0xff
	jr z, NotePool_Insert_SetHead
	jr NotePool_Insert_Return

NotePool_Insert_CompareAndLink:
	stb_erp A, 0xe2
	ldb_erp A, 0xf8
	extz iz
	muls iz, 0x9
	exts xiz
	add xiz, xhl
	ld wa, (xiz + 2)
	ldw_erp WA, 0xf6
	ld a, (xiz + 5)
	ldb_erp A, 0xe3
	stw_erp WA, 0xf6
	cp wa, iy
	jr ugt, NotePool_Insert_AdvanceScan
	stw_erp WA, 0xf6
	cp wa, iy
	jr nz, NotePool_Insert_LinkBefore
	stb_erp A, 0xe3
	cp a, (xsp + 8)
	jr ule, NotePool_Insert_LinkBefore

NotePool_Insert_AdvanceScan:
	ld a, (xiz)
	ldb_erp A, 0xe2
	jr NotePool_Insert_ScanLoop

NotePool_Insert_LinkBefore:
	stb_erp A, 0xe2
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
	stb_dri A, 0x07, 0xec, 0xe8

NotePool_Insert_Return:
	pop xiz
	inc 8, xsp
	ret

NotePool_DataBlock_890:
	.byte 0xc1, 0xe3, 0xbf, 0x21, 0xc9, 0xd8, 0xb0, 0xf6
	.byte 0xc1, 0xe2, 0xbf, 0x21, 0xc9, 0xd8, 0xb0, 0xfe
	.byte 0xc1, 0xe1, 0xbf, 0x21, 0xf1, 0xb3, 0x28, 0xcd
	.byte 0xb0, 0xf6, 0xc9, 0xdc, 0xb0, 0xfe, 0x1e, 0x74
	.byte 0xd8, 0x1d, 0xf5, 0x83, 0xf4, 0xf1, 0xb3, 0x28
	.byte 0xb5, 0x0e
NotePool_DataBlock_8BA:
	bit	7, (8958:16)

	ret	nz

	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x0e	; cpdi8	(0x8d34), 14 (v7 patched)

	ret	z

	ld a, (49121:16)

	cps	a, 5

	ret	nz

	ld c, (49122:16)

	ld a, (49123:16)

	and	c, a

	and	c, 64

	ret	z

	.byte 0xc1, 0x9c, 0x8c, 0x3f, 0x8a	; cpdi8	(0x8d38), 138 (v7 patched)

	ret	z

	cpdi16	0xf19e, 0

	ret	z

	bit	2, (1057:16)

	ret	nz

	cpdi16	0x28a8, 0

	ret	nz

	bit	2, (1054:16)

	ret	nz

	jr	0



SeqPlay_CheckStartConditions:
	ld a, (8958:16)
	bit 7, a
	ret nz
	set 7, a
	ld (8958:16), a
	cpdi16 0xf19e, 0
	jr nz, SeqPlay_CheckStart_TestSysFlag
	ld a, (8958:16)
	res 7, a
	ld (8958:16), a
	ret

SeqPlay_CheckStart_TestSysFlag:
	ld a, (8958:16)
	bit 2, (1057:16)
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
	cpdi16 0x28a8, 0
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
	ld	wa, (9832:16)
	ld	c, (35996:16)
	cp	c, 133
	jr	z, 5
	cp	c, 134
	jr	nz, 80
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
	ldw (1052:16), 0
	jr SeqStart_ClearTickAndInit

SeqStart_RestoreSavedPosition:
	ld (9832:16), bc
	ld wa, (9504:16)
	call SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (1052:16), hl
	ld (1051:16), 0
	ld wa, (9506:16)
	call SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl

SeqStart_ClearTickAndInit:
	ld (1051:16), 0
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
	ldw (1052:16), 0
	jr SeqStart_SendResetAndInit

SeqStart_RestoreSavedPosAlt:
	ld (9832:16), bc
	ld wa, (9500:16)
	call SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (1052:16), hl
	ld (1051:16), 0
	ld wa, (9502:16)
	call SeqBuf_AllocNextSlotAdjusted
	ld (9002:16), hl

SeqStart_SendResetAndInit:
	.byte 0x1d, 0xd6, 0x64, 0xf4, 0xd1, 0x68, 0x26, 0x3f
	.byte 0x01, 0x00, 0x6e, 0x11, 0xf1, 0xa7, 0x28, 0xb3
	.byte 0xf1, 0xf4, 0x11, 0x00, 0x00, 0xd8, 0xa8, 0x1d
	.byte 0xa0, 0xad, 0xfd, 0x68, 0x04
SeqStart_SetBit3:
	setda 3, 0x28a7

SeqStart_FinalInit:
	calr SeqAcc_InitPlaybackState
	ld (1073:16), 0
	resda 0, 0x28a6
	resda 7, 0x28ae
	call MidiChannel_ResetAndConfigure
	resda 7, 8958
	ret

SeqPlay_EmergencyStopAll:
	ld a, (0x2310:16)
	cps a, 0
	ret NZ
	.byte 0xf1, 0x10, 0x23, 0x00, 0x01, 0xf1, 0x9e, 0xf1
	.byte 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6, 0xfd, 0x1d
	.byte 0xef, 0x96, 0xf5, 0xf1, 0xa6, 0x28, 0xb0, 0x30
	.byte 0x32, 0x00, 0x1d, 0xe3, 0xdf, 0xf3, 0x1d, 0xbe
	.byte 0x09, 0xfe, 0x1d, 0x26, 0xee, 0xfd, 0x1d, 0x6b
	.byte 0xf1, 0xf3, 0x1d, 0x60, 0xdf, 0xf3, 0xf1, 0x10
	.byte 0x23, 0x00, 0x00, 0x0e
Seq_ResetAndRestartAccompaniment:
	ldw (0x28b4:16), 0x0000
	call SeqTimer_BarReturn
	resda 0, (0x28a6)
	resda 1, (0x33de)
	resda 3, (0x28a7)
	resda 2, (0x28b3)
	cp (0x8c98:16), 0x13
	jr nz, Seq_ResetRestart_NormalPath
	ld (0x1d94:16), 0x01
	calr SeqPlay_InitFromDemoRecord
	jr t, Seq_ResetRestart_CheckSubsystem
Seq_ResetRestart_NormalPath:
	ld (7572:16), 0
	calr SeqAcc_InitPlaybackState

Seq_ResetRestart_CheckSubsystem:
	jp	16635550
SeqPlay_StopAndResetAll:
	bit 0, (0x28c5:16)
	jr z, SeqPlay_StopReset_NotPlaying
	cpdi16 0x28a8, 0
	ret nz
	ld (8956:16), 0
	ret

SeqPlay_StopReset_NotPlaying:
	ld a, (1054:16)
	bit 3, a
	jr nz, SeqPlay_StopReset_DispatchAccomp
	bit 2, a
	jr z, SeqPlay_StopReset_DispatchAccomp
	bit 2, (1057:16)
	ret z
	call AccWrap_PlayModeStopExpr
	ld (8956:16), 0
	jr SeqPlay_StopReset_CleanupAll

SeqPlay_StopReset_DispatchAccomp:
	call AccWrap_PlayModeDispatch
SeqPlay_StopReset_CleanupAll:
	.byte 0xf1, 0xb3, 0x28, 0xb5
	ldw	wa, 50
	call	15982563
	call	16648638
	call	16641574
	call	15987051
	call	16179766
	.byte 0xf1, 0xae, 0x28, 0xb7
	call	16549379
	.byte 0xf1, 0xa7, 0x28, 0xb3
	ldw	(9832:16), 1
	ldw	(10420:16), 0
	ld	a, (10419:16)
	set	4, a
	set	2, a
	ld	(10419:16), a
	ld	(8956:16), 0
	cp	(35992:16), 19
	ret	nz
	ldw	(61854:16), 0
	call	16635550
	ldw	(10420:16), 0
	call	16355565
	call	16279643
	ret
Part_ReadAndProcessVoiceData:
	lda xsp, (xsp - 24)
	ld (xsp + 16), xde
	ld (xsp + 20), bc
	ld (xsp + 22), a
	ldw (xsp), 0x0
	ld c, (xsp + 22)
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr nz, Part_ReadVoice_HasData
	ldw hl, 0xffff
	jr Part_ReadVoice_Return

Part_ReadVoice_HasData:
	ld c, (xsp + 22)
	extz bc
	lds wa, 0
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
	cpdi16 0x28a8, 0
	scc8 nz, a
	ld (xsp + 18), a
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	cp (xsp + 18), 0x0
	call_24 nz, SeqChanAssign_InitLoop
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
	lda_dri XWA, 0xe1, 0x88, 0x00
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
	lda_dri XIX, 0xe1, 0x80, 0x00
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
	ldw_erp WA, 0xfa
	ld iz, (xde)
	ld xwa, (xsp + 4)
	lda_dri XIY, 0xe1, 0x90, 0x00
	stw_erp WA, 0xfa
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
	stw_dri WA, 0xe5, 0x80, 0x00
	ld wa, (7542:16)
	inc 1, wa
	stw_dri WA, 0xe5, 0x88, 0x00
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x13
	lds bc, 1
	calr SeqPart_ReadEventStream

SeqPlay_Reconfig_ScanParts:
	ld (xsp + 18), 0x1

SeqPlay_Reconfig_PartLoop:
	ld c, (xsp + 18)
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqPlay_Reconfig_PartShiftDone
	slaa de

SeqPlay_Reconfig_PartShiftDone:
	andda16 xde, 8982
	jr z, SeqPlay_Reconfig_PartLoopNext
	ld l, (xsp + 18)
	cpda8 l, 8990
	jr z, SeqPlay_Reconfig_PartLoopNext
	ld e, c
	extz de
	sla de, 3
	lda xbc, (9016:16)
	ld wa, (7542:16)
	inc 1, wa
	stw_dri WA, 0x07, 0xe4, 0xe8
	ld a, l
	extz wa
	lda xix, (xsp + 24)
	ld e, a
	dec 1, e
	extz de
	ld bc, de
	sla bc, 3
	lda xhl, (9332:16)
	lda_dri XHL, 0x07, 0xec, 0xe4
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
	adddm16 7542, xwa
	pop xiz
	lda xsp, (xsp + 24)
	ret

SeqChanAssign_InitLoop:
	dec 8, xsp
	pushw iz
	ld wa, (8998:16)
	cpda16 xwa, 9152
	jr nc, SeqChanAssign_CheckEndMark82
	ld (xsp + 2), 0x81
	lds iz, 0
	jr SeqChanAssign_CheckCount

SeqChanAssign_AssignAndIncr:
	lda xbc, (xsp + 2)
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	inc 1, iz

SeqChanAssign_CheckCount:
	ld wa, (9152:16)
	subda16 xwa, 8998
	cp iz, wa
	jr c, SeqChanAssign_AssignAndIncr
	jr SeqChanAssign_CheckEndMark82

SeqChanAssign_ReadEventData:
	lda xix, (xsp + 2)
	lda_dri XWA, 0xe1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssign_CopyDataLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqChanAssign_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, SeqChanAssign_ParseParamLen
	lds wa, 6
	call SeqData_SetErrorCode
	jr SeqChanAssign_SetEndAndReturn

SeqChanAssign_ParseParamLen:
	lda xix, (9016:16)
	ld e, l
	extz de
	lda xbc, (xsp + 2)
	cpib_sri 0xf1, 0x8a, 0x00, 0x81
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
	lds bc, 0
	calr SeqPart_ReadEventStream

SeqChanAssign_CheckEndMark82:
	lda xwa, (9016:16)
	cpib_sri 0xe1, 0x8a, 0x00, 0x82
	jr nz, SeqChanAssign_ReadEventData

SeqChanAssign_SetEndAndReturn:
	lda xbc, (xsp + 2)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	popw iz
	inc 8, xsp
	ret

SeqChanAssign_CompareVoicePos:
	cp wa, hl
	jr nz, SeqChanAssign_AssignFixed12
	ldb_sri0 A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqChanAssign_ReadEventStream

SeqChanAssign_AssignFixed12:
	ldw wa, 0x12
	jr SeqChanAssign_DoAssign

SeqChanAssign_CheckSavedPos:
	ld wa, (7524:16)
	ldw_sri0 HL, (xix + 0x0088)
	cp wa, hl
	jr ule, SeqChanAssign_CompareVoicePos
	jr SeqChanAssign_ReadEventStream

SeqChanAssignExt_InitLoop:
	lda xsp, (xsp - 32)
	pushw iz
	ld wa, (8998:16)
	cpda16 xwa, 9152
	jrl nc, SeqChanAssignExt_CheckEndMark82
	ld (xsp + 26), 0x81
	ldw (xsp + 16), 0x0
	jr SeqChanAssignExt_CheckCount

SeqChanAssignExt_AssignAndIncr:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	incw 1, (xsp + 16)

SeqChanAssignExt_CheckCount:
	ld wa, (9152:16)
	subda16 xwa, 8998
	cp (xsp + 16), wa
	jr c, SeqChanAssignExt_AssignAndIncr
	jr SeqChanAssignExt_CheckEndMark82

SeqChanAssignExt_ReadEventData:
	lda xix, (xsp + 26)
	lda_dri XWA, 0xe1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssignExt_CopyDataLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqChanAssignExt_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, SeqChanAssignExt_ParseParamLen
	ldw wa, 0x1a
	call SeqData_SetErrorCode
	jr SeqChanAssignExt_SetEndAndReturn

SeqChanAssignExt_ParseParamLen:
	lda xix, (9016:16)
	cpib_sri 0xf1, 0x8a, 0x00, 0x81
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
	lds bc, 0
	calr SeqPart_ReadEventStream

SeqChanAssignExt_CheckEndMark82:
	lda xwa, (9016:16)
	cpib_sri 0xe1, 0x8a, 0x00, 0x82
	jr nz, SeqChanAssignExt_ReadEventData

SeqChanAssignExt_SetEndAndReturn:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	cp (7522:16), 0
	jr nz, SeqChanAssignExt_SwapAndReconfig
	jrl SeqPlay_RestoreReturn

SeqChanAssignExt_ComparePos:
	cp wa, bc
	jr nz, SeqChanAssignExt_AssignFixed12
	ldb_sri0 A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqChanAssignExt_ReadEventStream

SeqChanAssignExt_AssignFixed12:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, hl
	jr SeqChanAssignExt_DoAssign

SeqChanAssignExt_CheckSavedPos:
	ld wa, (7524:16)
	ldw_sri0 BC, (xix + 0x0088)
	cp wa, bc
	jr ule, SeqChanAssignExt_ComparePos
	jr SeqChanAssignExt_ReadEventStream

SeqChanAssignExt_SwapAndReconfig:
	lda xde, (9016:16)
	ld wa, (7524:16)
	ldw_sri0 BC, (xde + 0x0088)
	cp wa, bc
	jrl c, SeqPlay_RestoreReturn
	cp wa, bc
	jr nz, SeqChanAssignExt_BuildSwapData
	ldb_sri0 A, (xde + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jrl c, SeqPlay_RestoreReturn

SeqChanAssignExt_BuildSwapData:
	lda xwa, (xsp + 18)
	ld (xsp + 2), xwa
	lda xix, (9332:16)
	lda_dri XDE, 0xf1, 0x80, 0x00
	ld xwa, (xsp + 2)
	ld bc, (xde)
	stw_dpi BC, 0xe1
	ld (xsp + 6), xwa
	lda xbc, (xde + 2)
	ld hl, (xbc)
	ld xwa, (xsp + 6)
	ld (xwa), hl
	lda xhl, (xsp + 22)
	lda_dri XWA, 0xf1, 0x88, 0x00
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
	lda_dri XWA, 0xf1, 0x90, 0x00
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
	lds bc, 0
	jr SeqChanAssign3_ReadEventStream

SeqChanAssign3_ReadEventData:
	lda xix, (xsp + 26)
	lda_dri XWA, 0xe1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

SeqChanAssign3_CopyDataLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqChanAssign3_CopyDataLoop
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, SeqChanAssign3_ParseParamLen
	ldw wa, 0x1b
	call SeqData_SetErrorCode
	jr SeqChanAssign3_SetEndAndReturn

SeqChanAssign3_ParseParamLen:
	lda xix, (9016:16)
	ld e, l
	extz de
	cpib_sri 0xf1, 0x8a, 0x00, 0x81
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
	lds bc, 0

SeqChanAssign3_ReadEventStream:
	calr SeqPart_ReadEventStream
	lda xwa, (9016:16)
	cpib_sri 0xe1, 0x8a, 0x00, 0x82
	jr nz, SeqChanAssign3_ReadEventData

SeqChanAssign3_SetEndAndReturn:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel

SeqPlay_RestoreReturn:
	popw iz
	lda xsp, (xsp + 32)
	ret

SeqChanAssign3_ComparePos:
	cp wa, hl
	jr nz, SeqChanAssign3_AssignFixed12
	ldb_sri0 A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqChanAssign3_ReadAndProcess

SeqChanAssign3_AssignFixed12:
	ldw wa, 0x12
	jr SeqChanAssign3_DoAssign

SeqChanAssign3_CheckSavedPos:
	ld wa, (7524:16)
	ldw_sri0 HL, (xix + 0x0088)
	cp wa, hl
	jr ule, SeqChanAssign3_ComparePos
	jr SeqChanAssign3_ReadAndProcess

SeqCh_CountEventsAndCalcPos:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	lds iz, 0
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
	cps hl, 0
	jr ge, SeqChCount_AccumulateLength
	lds wa, 7
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
	ldb w, 0x0
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
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (xsp + 12), hl
	ld c, (xsp + 20)
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	lda xwa, (xsp + 12)
	lda xbc, (xwa + 2)
	ld (xbc), hl
	lda xde, (xsp + 8)
	ld wa, (xwa)
	ld (xde), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	lds iz, 0
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
	stb_erp A, 0xf8
	extz wa
	ld (xbc + 2), wa

PartSwap_WriteIndexedData:
	ld c, (xsp + 20)
	extz bc
	ld de, (xsp + 8)
	lds wa, 0
	call Part_WriteWord_Indexed
	ld c, (xsp + 20)
	extz bc
	ld de, (xsp + 10)
	lds wa, 0
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
	lds hl, 0

PartSwap_Return:
	popw iz
	lda xsp, (xsp + 20)
	ret

PartCtrl_ReleaseVoiceChain:
	push xiz
	ld iz, wa
	ld wa, iz
	call PartCtrl_ReadWord
	ldw_erp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartRelease_Return
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartRelease_Return

PartRelease_FreeLoop:
	stw_erp IZ, 0xfa
	stw_erp WA, 0xfa
	lds bc, 0
	call PartCtrl_SetClearBit7
	stw_erp WA, 0xfa
	call PartCtrl_ReadWord
	ldw_erp HL, 0xfa
	ld wa, iz
	call PartCtrl_AppendToFreeList
	cp_erpw 0xfa, 0xff, 0xff
	jr nz, PartRelease_FreeLoop

PartRelease_Return:
	pop xiz
	ret

SeqPlay_ReallocateAndReconfig:
	lda xsp, (xsp - 0x1c)
	push XIZ
	ldw WA, 0x0032
	call SeqBuf_WriteNoteOffEntry
	call 0xfe09be
	call 0xfdee26
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call 0xfdd69e
	cpdi16 (0x28a8), 0x0000
	jrl z, SeqPlay_PendingCh_Return
	calr SeqChanAssignExt_InitLoop
	call PartCtrl_DeallocAndWriteEnd
	cp (0x1d62:16), 0x01
	call_24 z, (SeqPlay_ScanAndStoreChannelPos)
	call SeqPart_ScanAndBuildVoiceData
	lda xwa, (xsp + 0x14)
	calr SeqCh_CountEventsAndCalcPos
	lda xde, (xsp + 0x14)
	cpw (XDE), 0x0000
	jr nz, SeqRealloc_SetupSwapData
	cpw (XDE+0x02), 0x0000
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
	lda_dri XBC, 0x07, 0xf8, 0xe0
	ld wa, (xbc)
	ld (xhl), wa
	lda xix, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xix), wa
	lda xiy, (xsp + 12)
	lda_dri XBC, 0xf9, 0x88, 0x00
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
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (xsp + 20), hl
	ld c, (xsp + 4)
	extz bc
	lds wa, 0
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
	stiw_ind 0xe1, 0x80, 0x00, 0x00, 0x00
	stiw_ind 0xe1, 0x88, 0x00, 0x00, 0x00
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x12
	lds bc, 0

SeqPlay_ReadAndProcessEvents:
	calr SeqPart_ReadEventStream

SeqPlay_CheckEventTiming:
	lda xix, (9016:16)
	lda_dri XHL, 0xf1, 0x80, 0x00
	ldw_sri0 WA, (xix + 0x0088)
	ld de, (xhl)
	lda xbc, (xsp + 24)
	cp de, wa
	jr c, SeqPlay_ReadEvents_TimingMatch
	cp wa, de
	jr nz, SeqPlay_ProcessPendingChannels
	ldb_sri0 A, (xix + 0x0083)
	cpb_sri_rm A, 0xf1, 0x8b, 0x00
	jr nc, SeqPlay_ProcessPendingChannels

SeqPlay_ReadEvents_TimingMatch:
	ld xde, xbc
	ld xiy, xbc
	ldib_erp 0xe2, 0

SeqPlay_ReadEvents_CopyDataLoop:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XBC, 0xf1, 0x80, 0x00
	ld iz, wa
	extz xiz
	add xiz, xbc
	stb_erp C, 0xe2
	extz bc
	ld a, (xiz)
	stb_dri A, 0x07, 0xf4, 0xe4
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
	cps hl, 0
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
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XBC, 0xf1, 0x88, 0x00
	ld iz, wa
	extz xiz
	add xiz, xbc
	stb_erp C, 0xe2
	extz bc
	ld a, (xiz)
	stb_dri A, 0x07, 0xf4, 0xe4
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
	lda_dri XDE, 0x07, 0xe8, 0xe0
	ld wa, (xde)
	ld (xhl), wa
	ld wa, (xde + 2)
	ld (xhl + 2), wa
	ld de, (xhl)
	lds wa, 0
	call Part_WriteWord_Indexed
	ld c, (xsp + 4)
	extz bc
	ld de, (xsp + 22)
	lds wa, 0
	call Part_WriteByte_Indexed
	lda xbc, (xsp + 24)
	ld (xbc), 0x82
	ld a, (xsp + 4)
	extz wa
	lds de, 1
	calr ToneVoice_AssignChannel

SeqPlay_PendingCh_SetPart1:
	ld (xsp + 4), 0x1

SeqPlay_PendingCh_ActivateLoop:
	ld a, (xsp + 4)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_PendingCh_ActivateShift
	slaa bc

SeqPlay_PendingCh_ActivateShift:
	andda16 xbc, 0x28a8
	jr z, SeqPlay_PendingCh_ActivateNext
	ld a, (xsp + 4)
	extz wa
	lds bc, 1
	call Chan_SetActiveBit

SeqPlay_PendingCh_ActivateNext:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr ule, SeqPlay_PendingCh_ActivateLoop

SeqPlay_PendingCh_ClearAndDealloc:
	ldw	(10408:16), 0
	call	16635550
	ldw	(10410:16), 0
SeqPlay_PendingCh_Return:
	call Part_DeallocVoices1And2
	pop xiz
	lda xsp, (xsp + 28)
	ret

SeqPlay_PendingCh_AssignVoice:
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
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
	lds bc, 0
	jrl SeqPlay_ReadAndProcessEvents

SeqData_ValidateProcess:
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 6), e
	ld (xsp + 8), bc
	ld (xsp + 10), a
	ld a, (8182:16)
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl z, SeqData_Validate_Return

SeqData_Validate_SlotLoop:
	stb_erp A, 0xfb
	extz wa
	muls wa, 0xc
	lda xbc, (8186:16)
	lda_dri XHL, 0x07, 0xe4, 0xe0
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
	cps a, 0
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
	stb_erp A, 0xfb
	extz wa
	muls wa, 0xc
	ld bc, wa
	lda xwa, (8197:16)
	ldb_sri A, 0x07, 0xe0, 0xe4
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl nz, SeqData_Validate_SlotLoop

SeqData_Validate_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

SeqPlay_PrepareDrumVoice:
	dec 8, xsp
	pushw_erp 0xfa
	lds wa, 0
	ldw bc, 0xe
	call Part_FindVoiceByByte
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, Part_FindAndAssignDrumVoice
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_PrepareDrum_ShiftDone
	slaa bc

SeqPlay_PrepareDrum_ShiftDone:
	andda16 xbc, 0x28aa
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
	stb_erp A, 0xfb
	extz wa
	lda xbc, (xsp + 2)
	lds de, 6
	calr ToneVoice_AssignChannel
	stb_erp A, 0xfb
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_FindAndAssignDrumVoice:
	lds wa, 0
	ldw bc, 0xf
	call Part_FindVoiceByByte
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, Part_SendVoiceStatusLoop
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, PartVoiceStatus_ShiftDone
	slaa bc

PartVoiceStatus_ShiftDone:
	andda16	xbc, (10410)
	jr	z, 103	; -> 0xF3D6D2
	lda	xbc, (xsp+2)
	ld	(xbc), 211
	ld	(xbc+1), 0
	lda	xde, (xbc+2)
	ld	a, (36424:16)
	ld	(xde), a
	res	7, a
	ld	(xde), a
	stb_erp	a, 251
	extz	wa
	lds	de, 3
	calr	59790
	lda	xbc, (xsp+2)
	ld	(xbc), 128
	ld	(xbc+1), 0
	lda	xwa, (64602:16)
	ld	d, (xwa+8)
	ld	e, d
	res	7, e
	ld	(xbc+2), e
	lda	xhl, (xbc+3)
	ld	e, (xwa+9)
	ld	a, e
	ld	(xhl), a
	add	e, e
	ld	a, e
	ld	(xhl), e
	bit	7, d
	jr	z, 4	; -> 0xF3D6BF
	inc	1, a
	ld	(xhl), a
PartVoiceStatus_AssignTempo:
	stb_erp A, 0xfb
	extz wa
	lds de, 4
	calr ToneVoice_AssignChannel
	stb_erp A, 0xfb
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_SendVoiceStatusLoop:
	ldib_erp 0xfb, 1

PartVoiceStatus_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, PartVoiceStatus_PartShiftDone
	slaa bc

PartVoiceStatus_PartShiftDone:
	andda16 xbc, 0x28a8
	jr z, PartVoiceStatus_PartLoopNext
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cps l, 1
	jr z, Part_BuildAndSendVoiceCCEvent
	cps l, 0
	jr z, Part_BuildAndSendVoiceCCEvent
	cps l, 2
	jr nz, PartVoiceStatus_PartLoopNext

Part_BuildAndSendVoiceCCEvent:
	lda xwa, (xsp + 2)

	ld (xwa), 0xb0

	ld (xwa + 1), 0x0

	ld (xwa + 2), 0x9a

	stb_erp C, 0xfb

	inc 3, c

	ld (xwa + 3), c

	.byte 0xb8, 0x04, 0x14, 0x0c, 0xc5	; ldmi16 (xwa + 4), 0xc5a8 (v7 displacement)

	ld (xwa + 5), 0x7f

	calr 539

	stb_erp A, 0xfb

	extz wa

	lda xbc, (xsp + 2)

	lds de, 6

	calr 59628

	stb_erp A, 0xfb

	extz wa

	call	15983373



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
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqActivate_PartShiftDone
	slaa bc

SeqActivate_PartShiftDone:
	andda16 xbc, 0x28a8
	jr z, SeqActivate_PartLoopNext
	stb_erp A, 0xfb
	extz wa
	lds bc, 1
	call Chan_SetActiveBit

SeqActivate_PartLoopNext:
	inc1b_erp	251
	cp_erpb	251, 16
	jr	ule, -40	; -> 0xF3D74D
	ldw	(10408:16), 0
	call	16635550
	ldw	(10410:16), 0
	ldw	wa, 50
	call	SeqBuf_WriteNoteOffEntry
	call	16648638
	call	16641574
	call	VoiceAlloc_ProcessAll
	call	BitMapOut_PrepareAndDisplay
	call	16635550
	pop	qiz
	ret
SeqPlay_CheckDrumAndStart:
	cp (7570:16), 1
	jr nz, SeqPlayCheck_ReturnFFFF
	cpdi16 0x28a8, 0
	jr z, SeqPlayCheck_ReturnFFFF
	ld a, (8986:16)
	bit 2, (1057:16)
	jr nz, SeqPlay_StartPlayback
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlayCheck_DrumShiftDone
	slaa bc

SeqPlayCheck_DrumShiftDone:
	andda16 xbc, 8982
	jr nz, SeqPlay_StartPlayback

SeqPlayCheck_ReturnFFFF:
	ldw hl, 0xffff
	ret

SeqPlay_StartPlayback:
	call SeqBuffer_ClearAndInitIteration
	bit 2, (1057:16)
	jr nz, SeqPlayCheck_SetSecondChannel
	calr SeqPlay_ScanAndStoreChannelPos
	ld (7522:16), 0
	calr SeqPlay_InitializePlayback

SeqPlayCheck_SetSecondChannel:
	ld (7522:16), 1
	ld wa, (1052:16)
	addda16 xwa, 7544
	ld (7524:16), wa
	ld a, (1051:16)
	extz wa
	ld (7526:16), wa
	lds hl, 0
	ret

SeqPlay_ScanAndStoreChannelPos:
	lda xsp, (xsp - 20)
	push xiz
	lds iz, 0
	ld a, (8986:16)
	ldb_erp A, 0xfb
	extz wa
	lda xhl, (xsp + 12)
	dec 1, a
	extz wa
	sla wa, 3
	lda xbc, (9332:16)
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	cpdi16 7544, 0
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
	lds de, 1
	call Part_CopyBytesToVoiceBlock
	inc 1, iz
	jr SeqScanPos_ComparePosition

SeqScanPos_CheckEndMark:
	cp a, 0x82
	jr z, SeqPlay_StoreChannelPosition

SeqScanPos_ComparePosition:
	cpda16 xiz, 7544
	jr c, SeqScanPos_ReadNextEvent

SeqPlay_StoreChannelPosition:
	stb_erp C, 0xfb
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
	lds wa, 0
	call Part_WriteWord_Indexed
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 6)
	lds wa, 0
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	lds de, 1
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
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 4)
	lds wa, 0
	call Part_WriteWord_Indexed
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 6)
	lds wa, 0
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	lds de, 1

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
	call_24 nz, SeqBuf_FlushAndReinit_VoiceCCEvents
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call_24 lt, SeqBuf_FlushAndReinit_NoteEvents
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
	call_24 nz, SeqBuf_FlushAndReinit_NoteEvents
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call_24 lt, SeqBuf_FlushAndReinit_VoiceCCEvents
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
	call_24 nz, SeqBuf_FlushAndReinit_VoiceCCEvents
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call_24 lt, SeqBuf_FlushAndReinit_NoteEvents
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
	call_24 nz, SeqBuf_FlushAndReinit_NoteEvents
	call SeqBuf_GetWritePos
	cp hl, 0xf
	call_24 lt, SeqBuf_FlushAndReinit_VoiceCCEvents
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
	call	15672433
	call	16646645
	call	15672365
	ld	(7556:16), 0
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
	setda 1, 1056
	setda 2, 1056
	ld a, (1054:16)
	bit 0, a
	jr z, SeqTimerFlags_CheckSysFlag
	set 1, a
	set 2, a
	ld (1054:16), a

; === v7-specific block: SeqTimerFlags_CheckSysFlag (157 bytes) ===
SeqTimerFlags_CheckSysFlag:
	.incbin "includes/romslices/v7_block_seqtimerflags_checksysflag.bin"
; === end v7 block ===
PartVoiceOff_Return:
	popw_erp 0xfa
	inc 6, xsp
	ret

VoiceAlloc_ScoopDisplayProcess:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 4), 0x0

VoiceAlloc_FindPartLoop:
	lds bc, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, VoiceAlloc_FindPartShiftDone
	slaa bc

VoiceAlloc_FindPartShiftDone:
	andda16 xbc, 3407
	jr z, VoiceAlloc_FindPartNext
	ld a, (xsp + 4)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xd
	jr z, VoiceAlloc_StartProcessing
	ld a, (3431:16)
	cps a, 4
	call_24 nz, SeqBuf_FlushAndReinit_NoteEvents
	jrl VoiceAlloc_Return

VoiceAlloc_FindPartNext:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr c, VoiceAlloc_FindPartLoop

VoiceAlloc_StartProcessing:
	ld (xsp + 14), 0x0

VoiceAlloc_ReadNextByte:
	call SeqBuf_ReadByte
	cps hl, 0
	jr ge, VoiceAlloc_StoreAndReadFields

VoiceAlloc_SortAndDisplay:
	lda xbc, (xsp + 14)
	cp (xbc), 0x0
	jrl z, VoiceAlloc_DisplayAndApply
	ld (xsp + 4), 0x0
	ld (xsp + 10), xbc
	ld (xsp + 6), xbc
	lds hl, 0
	jrl VoiceAlloc_SortOuterLoop

VoiceAlloc_StoreAndReadFields:
	ld (xsp + 30), l
	ld (xsp + 4), 0x1

VoiceAlloc_ReadFieldLoop:
	call SeqBuf_ReadByte
	lda xbc, (xsp + 30)
	cps hl, 0
	jr lt, VoiceAlloc_ProcessEntry
	ld a, (xsp + 4)
	extz wa
	stb_dri L, 0x07, 0xe4, 0xe0
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
	stb_dri A, 0x07, 0xe8, 0xec
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
	lda_dri XIY, 0x07, 0xe4, 0xe0
	ldb_erp D, 0xf0
	extz ix
	jr VoiceAlloc_SortInnerLoop

VoiceAlloc_SortCompareSwap:
	ld wa, ix
	inc 1, wa
	lda_dri XIZ, 0x07, 0xe4, 0xe0
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
	lda xwa, (xsp + 0x1a)
	lds de, 2
	call 0xfe9f09
	lda xwa, (xsp + 0x1a)
	.byte 0x80, 0x19, 0x43, 0xce, 0x88, 0x01, 0x19, 0x44
	.byte 0xce, 0x88, 0x02, 0x19, 0x45, 0xce, 0x88, 0x03
	.byte 0x19, 0x42, 0xce, 0xc1, 0x67, 0x0d, 0x21, 0xc9
	.byte 0xdc, 0x66, 0x44, 0xf1, 0x49, 0xce, 0x34, 0xbf
	.byte 0x0e, 0x33, 0x83, 0x21, 0xb4, 0x41, 0xbf, 0x04
	.byte 0x00, 0x00, 0xeb, 0x8d, 0xda, 0xa9, 0x8f, 0x04
	.byte 0x21, 0x85, 0xf1, 0x6f, 0x22
VoiceAlloc_CopyFieldLoop:
	ld wa, de
	ldw bc, 0xffff
	add wa, bc
	inc 1, wa
	ld bc, de
	extz xbc
	add xbc, xix
	ldb_sri A, 0x07, 0xec, 0xe0
	ld (xbc), a
	incm8 1, (xsp + 4)
	inc 1, de
	ld a, (xsp + 4)
	cp a, (xiy)
	jr c, VoiceAlloc_CopyFieldLoop

VoiceAlloc_InitAndFind:
	call	16651526
	call	16651498
VoiceAlloc_WriteIndexAndApply:
	lda xwa, (xsp + 26)

	.byte 0x80, 0x19, 0xa6, 0x8c	; mrib4 0x80, 0x19, 0x42, 0x8d (v7 displacement)

	.byte 0x88, 0x01, 0x19, 0xa4, 0x8c	; mrdb5 0x88, 0x01, 0x19, 0x40, 0x8d (v7 displacement)

	.byte 0x88, 0x02, 0x19, 0xa8, 0x8c	; mrdb5 0x88, 0x02, 0x19, 0x44, 0x8d (v7 displacement)

	.byte 0x88, 0x03, 0x19, 0x42, 0xce	; mrdb5 0x88, 0x03, 0x19, 0xde, 0xce (v7 displacement)

	.byte 0x1d, 0x6a, 0x3e, 0xfb	; call BitMapOut_CheckDiskAndApply (v7 addr)



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
	ldb l, 0xff
	jrl VoiceAlloc_ReturnFF

VoiceAlloc_CheckNoteType:
	ld xix, (xsp + 8)
	lda xwa, (xix + 3)
	ld (xsp + 12), xwa
	ld a, (xwa)
	ld (xsp + 6), a
	lda xbc, (xsp + 28)
	ld (xbc), 0x0
	ldb e, 0x0
	extz de
	inc 1, de
	ld a, (xix + 4)
	stb_dri A, 0x07, 0xe4, 0xe8
	incm8 1, (xbc)
	ld a, (xsp + 4)
	extz wa
	lda xde, (xsp + 16)
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (9184:16)
	lda_dri XBC, 0x07, 0xe4, 0xe0
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
	stb_dri A, 0x07, 0xe4, 0xec
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
	lda_dri XBC, 0x07, 0xe4, 0xe8
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
	ldb l, 0x0
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
	lda_dri XIY, 0x07, 0xe4, 0xe0
	ldb_erp D, 0xf0
	extz ix
	jr VoiceAlloc_SortLoop_InnerCheck

VoiceAlloc_SortLoop_Inner:
	ld wa, ix
	inc 1, wa
	lda_dri XIZ, 0x07, 0xe4, 0xe0
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
	.byte 0xaf, 0x0a, 0x20, 0x80, 0x21, 0xc9, 0x69, 0xc9
	.byte 0xf7, 0x67, 0xb7, 0xbf, 0x28, 0x30, 0xda, 0xaa
	.byte 0x1d, 0x09, 0x9f, 0xfe, 0xbf, 0x28, 0x30, 0x8f
	.byte 0x2c, 0x3f, 0x00, 0x66, 0x4c, 0xe8, 0x8a, 0xc1
	.byte 0x43, 0xce, 0x23, 0x80, 0xf3, 0x6e, 0x1c, 0xc1
	.byte 0x44, 0xce, 0x21, 0x8a, 0x01, 0xf1, 0x6e, 0x13
	.byte 0xc1, 0x45, 0xce, 0x21, 0x8a, 0x02, 0xf1, 0x6e
	.byte 0x0a, 0xc1, 0x42, 0xce, 0x21, 0x8a, 0x03, 0xf1
	.byte 0x76, 0xa0, 0x00
BitMapOut_WriteAltIdx:
	.byte 0x82, 0x19, 0x43, 0xce, 0x8a, 0x01, 0x19, 0x44
	.byte 0xce, 0x8a, 0x02, 0x19, 0x45, 0xce, 0x8a, 0x03
	.byte 0x19, 0x42, 0xce, 0xf1, 0x49, 0xce, 0x35, 0xbf
	.byte 0x1c, 0x34, 0x84, 0x21, 0xb5, 0x41, 0x27, 0x00
	.byte 0xec, 0x8e, 0xda, 0xa9, 0x68, 0x54
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
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xbc), a
	inc 1, l
	inc 1, de

VoiceAlloc_CopyNoteData_Check:
	.byte 0x86, 0xf7, 0x67, 0xe2, 0x1d, 0x06, 0x15, 0xfe
	.byte 0x1d, 0xea, 0x14, 0xfe, 0xbf, 0x28, 0x30, 0x80
	.byte 0x19, 0xa6, 0x8c, 0x88, 0x01, 0x19, 0xa4, 0x8c
	.byte 0x88, 0x02, 0x19, 0xa8, 0x8c, 0x88, 0x03, 0x19
	.byte 0x42, 0xce, 0x1d, 0x6a, 0x3e, 0xfb
BitMapOut_CompletionJoin:
	ldb l, 0x0

VoiceAlloc_ReturnFF:
	pop xiz
	lda xsp, (xsp + 42)
	ret

BitMapOut_PrepareAndDisplay:
	lda xsp, (xsp - 0x10)
	lda XBC, (XSP)
	ld (XBC),0x00
	lda xwa, (xsp + 0x0c)
	lds de, 2
	call 0xfe9f09
	lda xwa, (xsp + 0x0c)
	.byte 0x80, 0x19, 0x43, 0xce, 0x88, 0x01, 0x19, 0x44
	.byte 0xce, 0x88, 0x02, 0x19, 0x45, 0xce, 0x88, 0x03
	.byte 0x19, 0x42, 0xce, 0x1d, 0x06, 0x15, 0xfe, 0x1d
	.byte 0xea, 0x14, 0xfe, 0xbf, 0x0c, 0x30, 0x80, 0x19
	.byte 0xa6, 0x8c, 0x88, 0x01, 0x19, 0xa4, 0x8c, 0x88
	.byte 0x02, 0x19, 0xa8, 0x8c, 0x88, 0x03, 0x19, 0x42
	.byte 0xce, 0x1d, 0x6a, 0x3e, 0xfb, 0xbf, 0x10, 0x37
	.byte 0x0e
BitMapOut_PrepareAndDisplaySimple:
	lda xsp, (xsp - 16)

	lda xbc, (xsp)

	ld (xbc), 0x0

	lda xwa, (xsp + 12)

	lds de, 2

	call	16686857

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
	call_24 nz, SeqBuf_FlushAndReinit_VoiceCCEvents
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
	resda 0, 9954
	ldb l, 0x0
	ldb d, 0x1

PartDetect_PartScanLoop:
	ld a, d
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, PartDetect_ShiftDone
	slaa bc

PartDetect_ShiftDone:
	andda16 xbc, 0x28a8
	jr z, PartDetect_CheckCount
	inc 1, l
	ld e, d

PartDetect_CheckCount:
	cps l, 1
	jr ugt, PartDetect_SingleVoiceFound
	inc 1, d
	cp d, 0x10
	jr ule, PartDetect_PartScanLoop

PartDetect_SingleVoiceFound:
	cps l, 1
	jp_24 nz, PartSelect_UpdateDisplayState
	extz de
	lds wa, 0
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xf
	ret z
	cp l, 0x13
	jr ule, PartDetect_LookupAndApply
	ldb l, 0x0

PartDetect_LookupAndApply:
	.byte 0xdb, 0x12, 0xf2, 0x36, 0x45, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xec, 0x25, 0xf1, 0xe2, 0x26, 0xb8
	.byte 0xf1, 0x9e, 0x8c, 0x45, 0xda, 0x12, 0x0b, 0xff
	.byte 0x00, 0x30, 0x90, 0x00, 0x31, 0x10, 0x00, 0x1d
	.byte 0x53, 0xaa, 0xfd, 0x0e
Part_DeactivateVoiceChannel:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceByte
	cp l, 0xf
	jr nz, PartDeact_CheckSysFlags
	resda 7, 0x28ae
	call MidiChannel_ResetAndConfigure

PartDeact_CheckSysFlags:
	.byte 0x87, 0x21, 0xd8, 0x12, 0xf1, 0x21, 0x04, 0xca
	.byte 0x66, 0x39, 0xd1, 0x9e, 0xf1, 0x3f, 0x00, 0x00
	.byte 0x6e, 0x2c, 0xf1, 0xb4, 0x28, 0x02, 0x00, 0x00
	.byte 0x30, 0x32, 0x00, 0x1e, 0x0b, 0xff, 0x87, 0x21
	.byte 0xd8, 0x12, 0xd9, 0xa9, 0x1e, 0x73, 0x33, 0x1e
	.byte 0x87, 0x10, 0xf1, 0x9e, 0xf1, 0x02, 0x00, 0x00
	.byte 0x1d, 0x9e, 0xd6, 0xfd, 0x1d, 0x9e, 0xd6, 0xfd
	.byte 0x1d, 0x2d, 0x24, 0xef, 0x68, 0x32
PartDeact_SendVoiceOff:
	calr Part_SendVoiceOffAndCCEvents
	jr AccWrap_ClearPositionAndReset

PartDeact_ClearPartBit:
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, PartDeact_ClearShiftDone
	slaa bc

PartDeact_ClearShiftDone:
	cpl bc
	ld wa, (0x28b4:16)
	and wa, bc
	ld (0x28b4:16), wa
	cpdi16 0xf19e, 0
	jr nz, PartDeact_CheckSubsystem
	ldw (0x28b4:16), 0
	resda 7, 0x28ad
	call SeqBuf_Init

AccWrap_ClearPositionAndReset:
	resda 0, 0x28a6
	call AccWrap_PositionClear

PartDeact_CheckSubsystem:
	call	16635550
	inc	2, xsp
	ret
Accomp_UpdateModeFlag:
	cp (0x8c9a:16), 0x81
	jr z, AccompMode_SetFlag
	cpdi16 (0xf19e), 0x0000
	jr z, AccompMode_ClearFlag
AccompMode_SetFlag:
	setda 0, 0x28a5
	jr AccompMode_ApplyAndNotify

AccompMode_ClearFlag:
	resda 0, 0x28a5

AccompMode_ApplyAndNotify:
	ld	wa, (65516:24)
	ld	(61854:16), wa
	call	16635550
	ldw	wa, 76
	jp	16544114
Accomp_ValidateAutoPlayChordVoice:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1
	lds wa, 0
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr nz, AccompValidate_ShiftDone
	ldib_erp 0xfb, 0

AccompValidate_ShiftDone:
	ld a, l
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, AccompValidate_CheckPartActive
	slaa bc

AccompValidate_CheckPartActive:
	andda16 xbc, 0xf19e
	jr nz, AccompValidate_CheckBit7
	ldib_erp 0xfb, 0

AccompValidate_CheckBit7:
	extz hl
	lds wa, 0
	ld bc, hl
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, AccompValidate_StoreResult
	ldib_erp 0xfb, 0

AccompValidate_StoreResult:
	stb_erp A, 0xfb
	ld (8968:16), a
	popw_erp 0xfa
	ret

Seq_SyncPositionAndOutputMIDITiming:
	dec 0,XSP
	push XIZ
	ld XIY,WidgetData_DrawbarPositionTable_0x176
	lda xix, (xsp + 0x04)
	.byte 0x85, 0x10, 0x95, 0x10, 0xc1, 0xec, 0xe2, 0x3f
	.byte 0x01, 0x6e, 0x07, 0xf1, 0xec, 0xe2, 0x00, 0x00
	.byte 0x68, 0x66
SeqSync_CheckDemoMode:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x13, 0x66, 0x5f, 0xf1
	.byte 0x4b, 0xb7, 0xc8, 0x6e, 0x59, 0xd8, 0xac, 0x1e
	.byte 0xd5, 0x57, 0xcf, 0xd8, 0x66, 0x50, 0xf1, 0x24
	.byte 0x04, 0x00, 0xf2, 0xbf, 0x08, 0x36, 0x06, 0x06
	.byte 0xb6, 0x16, 0x1c, 0x04, 0xbe, 0x02, 0x14, 0x1b
	.byte 0x04, 0x06, 0x00, 0xbf, 0x08, 0x30, 0x90, 0x21
	.byte 0xd9, 0xee, 0x02, 0x88, 0x02, 0x21, 0xd8, 0x12
	.byte 0xc9, 0x0a, 0x18, 0xd8, 0x12, 0xd8, 0x81, 0xd9
	.byte 0x8a, 0xda, 0xcc, 0x7f, 0x00, 0xd9, 0xef, 0x07
	.byte 0xd9, 0xcc, 0x7f, 0x00, 0xbf, 0x04, 0x30, 0xb8
	.byte 0x01, 0x45, 0xb8, 0x02, 0x43, 0x06, 0x06, 0xbf
	.byte 0x04, 0x30, 0x38, 0x0b, 0x03, 0x00, 0x1d, 0xa2
	.byte 0xaf, 0xfd, 0xef, 0x66, 0x06, 0x00
Seq_PopIzSkip8Ret:
	pop xiz
	inc 8, xsp
	ret

Seq_CheckChordVoiceAndSetFlag:
	bit 6, (0x28ad:16)
	ret z
	lds wa, 0
	ldw bc, 0xf
	calr Part_FindVoiceByByte
	cp l, 0xff
	ret z
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xf
	jr z, SeqChordCheck_ShiftDone
	slaa bc

SeqChordCheck_ShiftDone:
	ld wa, bc
	andda16 xbc, 0xf19e
	ret z
	andda16 xwa, 0x28b4
	ret z
	setda 7, 0x28ae
	ret

Part_CopyVoiceDataToAllChannels:
	dec 8, xsp
	pushw_erp 0xfa
	ld (xsp + 8), 0x81
	ld (xsp + 6), 0x82
	ldib_erp 0xfb, 1

PartCopyVoice_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, PartCopyVoice_PartShiftDone
	slaa bc

PartCopyVoice_PartShiftDone:
	andda16 xbc, 0x28a8
	jr z, PartCopyVoice_PartLoopNext
	stb_erp C, 0xfb
	extz bc
	lda xwa, (xsp + 2)
	dec 1, c
	extz bc
	sla bc, 2
	lda xde, (9184:16)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 8)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 2)
	lds wa, 0
	calr Part_WriteWord_Indexed
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 4)
	lds wa, 0
	calr Part_WriteByte_Indexed
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	stb_erp C, 0xfb
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
	lds de, 1
	and a, 0xf
	jr z, SeqEventCreate_ShiftDone
	slaa de

SeqEventCreate_ShiftDone:
	andda16 xde, 0x28a8
	jr z, SeqEventCreate_Return
	extz bc
	lda xwa, (xsp)
	dec 1, c
	extz bc
	sla bc, 2
	lda xde, (9184:16)
	lda_dri XDE, 0x07, 0xe8, 0xe4
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	lda xwa, (xsp)
	lda xbc, (xsp + 4)
	lds de, 1
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
	lds hl, 6
	jr SeqEvent_NullRet

SeqEvent_ReturnLen4:
	lds hl, 4
	jr SeqEvent_NullRet

SeqEvent_ReturnStatusThree:
	lds hl, 3
	jr SeqEvent_NullRet

SeqEvent_ReturnLen2:
	lds hl, 2
	jr SeqEvent_NullRet

SeqEvent_ReturnLen1:
	lds hl, 1
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
	ldb c, 0x1
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
	stib_ind 0xf1, 0x38, 0x02, 0xff
	jr NotePool_Return

NotePool_ScanExistingEntries:
	ld a, (xwa)
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0xff
	jr z, NotePool_Return

NotePool_ScanEntryLoop:
	stb_erp A, 0xfb
	extz wa
	lda xde, (xsp + 2)
	ld c, a
	ldb_erp C, 0xee
	ld xix, xde
	ldib_erp 0xe2, 0

NotePool_CopySlotDataLoop:
	stb_erp C, 0xe2
	extz bc
	ld iy, bc
	inc 4, iy
	stb_erp C, 0xee
	extz bc
	muls bc, 0x9
	ld hl, bc
	lda xbc, (7606:16)
	lda_dri XBC, 0x07, 0xe4, 0xec
	extz xiy
	add xiy, xbc
	stb_erp L, 0xe2
	extz hl
	ld c, (xiy)
	stb_dri C, 0x07, 0xf0, 0xec
	inc1b_erp 0xe2
	cpib_erp 0xe2, 5
	jr c, NotePool_CopySlotDataLoop
	ld c, (xde + 4)
	inc 1, c
	cp c, (xsp + 10)
	call_24 z, NoteMap_RemoveAndRelink
	stb_erp A, 0xfb
	extz wa
	muls wa, 0x9
	ld bc, wa
	lda xwa, (7607:16)
	ldb_sri A, 0x07, 0xe0, 0xe4
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0xff
	jr nz, NotePool_ScanEntryLoop

NotePool_Return:
	popw_erp 0xfa
	lda xsp, (xsp + 10)
	ret

NotePool_DataBlock:
	.incbin "includes/romslices/v7_transplant_NotePool_DataBlock.bin"
SeqBuffer_MoveEntryToHead:
	push	xiz
	cp	a, 255
	jr	nz, 5
	ld	(58094:16), 255
SeqBufMove_LoadSlotData:
	lda xiz, (8184:16)
	lda xix, (xiz + 1)
	ld w, (xix)
	ld c, a
	extz bc
	muls bc, 0xc
	ld iy, bc
	lda xhl, (8186:16)
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	lda_dri XWA, 0x07, 0xec, 0xf4
	ld (xwa + 11), 0xff
	pop xiz
	ret

SeqBuffer_UnlinkEntry:
	push xiz
	extz wa
	muls wa, 0xc
	lda xiz, (8186:16)
	lda_dri XBC, 0x07, 0xf8, 0xe0
	ld a, (xbc + 10)
	ldb_erp A, 0xf4
	ld a, (xbc + 11)
	ldb_erp A, 0xf0
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
	stb_erp A, 0xf0
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xiz
	lda xhl, (xwa + 10)
	cp_erpb 0xf4, 0xff
	jr nz, SeqBufUnlink_HandlePrevOnly
	stb_erp A, 0xf0
	ld (xde), a
	ld (xhl), 0xff
	jr Bitmap_RestoreReturn

SeqBufUnlink_HandlePrevOnly:
	stb_erp A, 0xf4
	extz wa
	muls wa, 0xc
	exts xwa
	add xwa, xiz
	lda xde, (xwa + 11)
	cp_erpb 0xf0, 0xff
	jr nz, SeqBufUnlink_HandleBothLinks
	stb_erp A, 0xf4
	ld (xbc), a
	ld (xde), 0xff
	jr Bitmap_RestoreReturn

SeqBufUnlink_HandleBothLinks:
	stb_erp A, 0xf4
	ld (xhl), a
	stb_erp A, 0xf0
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
	lda_dri XBC, 0x07, 0xec, 0xf4
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
	stib_ind 0x07, 0xe0, 0xf4, 0xff
	pop xiz
	ret

SeqBuffer_ClearAndInitIteration:
	dec 6, xsp
	push xiz
	lda xde, (xsp + 4)
	ld xwa, xde
	lda xbc, (xde + 6)

SeqBuffer_ClearLoop:
	stib_dsp 0xe0, 0xff
	cp xwa, xbc
	jr c, SeqBuffer_ClearLoop
	lda xwa, (8182:16)
	ld (xwa), 0xff
	ld (xwa + 1), 0xff
	lda xwa, (8184:16)
	ld (xwa), 0x0
	ld (xwa + 1), 0x3f
	ldb l, 0x0

SeqBuffer_InitSlotLoop:
	ld c, l
	extz bc
	ld a, c
	ldb_erp A, 0xe6
	ld xiy, xde
	ldb h, 0x0

SeqBuffer_InitSlot_CopyFields:
	ldb_erp H, 0xf8
	extz iz
	stb_erp A, 0xe6
	extz wa
	muls wa, 0xc
	lda xix, (8186:16)
	exts xwa
	add xwa, xix
	extz xiz
	add xiz, xwa
	ld a, h
	extz wa
	ldb_sri A, 0x07, 0xf4, 0xe0
	ld (xiz), a
	inc 1, h
	cps h, 4
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
	stib_ind 0xf1, 0xff, 0x02, 0xff
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
	stib_ind 0x07, 0xe4, 0xe8, 0xff
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
	lda_dri XDE, 0x07, 0xec, 0xe4
	ld w, (xde)
	lda xbc, (xde + 1)
	ld (xsp + 4), xbc
	ld c, (xbc)
	ldb_erp C, 0xe2
	cp w, 0xff
	jr nz, NoteMap_RelinkEntry
	cp_erpb 0xe2, 0xff
	jr nz, NoteMap_RelinkEntry
	lda xbc, (7602:16)
	ld (xbc), 0xff
	ld (xbc + 1), 0xff
	jr NoteMap_UpdateTailPointer

NoteMap_RelinkEntry:
	stb_erp C, 0xe2
	extz bc
	muls bc, 0x9
	lda_dri XIZ, 0x07, 0xec, 0xe4
	lda xix, (7602:16)
	cp w, 0xff
	jr nz, NoteMap_Relink_HasPrev
	stb_erp C, 0xe2
	ld (xix), c
	ldb w, 0xff
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
	stb_erp C, 0xe2
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
	ldb w, 0xff
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
	ld	c, (35994:16)
	cp	c, 133
	jr	z, 5
	cp	c, 134
	jr	nz, 76
SeqPlay_AllocBuf_Mode85_86:
	bit 1, (0x28b1:16)
	jr nz, SeqPlay_AllocBuf_HasRepeat
	ldw (9000:16), 0
	ldw (1052:16), 0
	ld (1051:16), 0
	resda 3, 0x28a7
	jr SeqPlay_AllocBuf_InitPlayback

SeqPlay_AllocBuf_HasRepeat:
	ld wa, (9504:16)
	calr SeqBuf_AllocNextSlot
	ld (9000:16), hl
	ld (1052:16), hl
	ld (1051:16), 0
	cps hl, 0
	jr nz, SeqPlay_AllocBuf_SetRepeatBit
	resda 3, 0x28a7
	jr SeqPlay_AllocBuf_AllocSecond

SeqPlay_AllocBuf_SetRepeatBit:
	setda 3, 0x28a7

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
	ld (1052:16), hl
	ld (1051:16), 0

SeqPlay_AllocBuf_InitPlayback:
	call SeqPlay_InitializePlayback
	jr SeqAllocBuf_ResetStartState

SeqAllocBuf_CheckBit3:
	bit 3, (0x28a7:16)
	jr z, SeqAllocBuf_CheckMode17
	calr SeqBuf_AllocNextSlot
	ld (1052:16), hl
	ld (1051:16), 0

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
	setda 4, 0x28b3
	setda 2, 0x28a7
	ld (9508:16), 1
	cpdi16 9832, 1
	jr z, SeqInitStart_CheckPlayMode
	ld (7518:16), 250
	setda 3, 0x28a7
	jr SeqInitStart_SetActiveFlag

SeqInitStart_CheckPlayMode:
	ld	a, (35994:16)
	cp	a, 133
	jr	z, 5
	cp	a, 134
	jr	nz, 8
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
	resda 3, 0x28a7

SeqInitStart_SetActiveFlag:
	ld	(58090:16), 1
	ret
SeqInitStart_CheckMode17Alt:
	bit 0, (0x28b1:16)
	jr z, Display_ClearHWState

SeqInitStart_SetPreroll:
	ld (7518:16), 250
	jr SeqInitStart_ClearBit3

SeqPlay_ResetStartState:
	resda 4, (0x28b3)
	ld (0x1d5e:16), 0x00
	ld (0x2524:16), 0x00
	cp (0x8c9a:16), 0x8e
	ret Z
	.byte 0xc1, 0xea, 0xe2, 0x3f, 0x01, 0x6e, 0x04, 0xf1
	.byte 0xa7, 0x28, 0xb2
SeqResetStart_ClearActiveFlag:
	ld	(58090:16), 0
	ret
SeqPart_ScanAndBuildVoiceData:
	dec 8, xsp
	push xiz
	lds iz, 0
	ld (xsp + 6), 0x81
	ld a, (8986:16)
	ldb_erp A, 0xfb
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
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
	lds de, 1
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
	stb_erp C, 0xfb
	extz bc
	ld de, (0x28af:16)
	lds wa, 0
	calr Part_WriteWord_Indexed
	stb_erp C, 0xfb
	extz bc
	ld wa, (9830:16)
	ld e, a
	extz de
	lds wa, 0
	calr Part_WriteByte_Indexed
	ld bc, (9000:16)
	stb_erp A, 0xfb
	extz wa
	lda xde, (xsp + 8)
	call Part_ReadAndProcessVoiceData
	stb_erp C, 0xfb
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
	subda16 xwa, 9000
	inc 1, wa
	ld (7544:16), wa
	ld wa, (8982:16)
	ld (8984:16), wa
	lds wa, 0
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPartInit_CheckBassVoice
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xf
	jr z, SeqPartInit_AccompShiftDone
	slaa bc

SeqPartInit_AccompShiftDone:
	andda16 xbc, 8982
	lda xwa, (7538:16)
	cps bc, 0
	jr z, SeqPartInit_AccompNotActive
	ld (xwa), 0x1
	jr SeqPartInit_CheckBassVoice

SeqPartInit_AccompNotActive:
	ld (xwa), 0x0

SeqPartInit_CheckBassVoice:
	lds wa, 0
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp l, 0xff
	jr z, SeqPartInit_MainLoop
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xf
	jr z, SeqPartInit_BassShiftDone
	slaa bc

SeqPartInit_BassShiftDone:
	andda16 xbc, 8982
	lda xwa, (7539:16)
	cps bc, 0
	jr z, SeqPartInit_BassNotActive
	ld (xwa), 0x1
	jr SeqPartInit_MainLoop

SeqPartInit_BassNotActive:
	ld (xwa), 0x0

SeqPartInit_MainLoop:
	ldb b, 0x1
	ldb c, 0x0

SeqPartInit_PartScanLoop:
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqPartInit_PartShiftDone
	slaa de

SeqPartInit_PartShiftDone:
	andda16 xde, 8982
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
	lda_dri XDE, 0x07, 0xe8, 0xe0
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
	cpda8 b, 8988
	jr nz, SeqPartInit_PartLoopNext
	ld hl, (xix)
	ld de, (xiy)
	lda_dri XWA, 0xf9, 0x98, 0x00
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
	ldb l, 0x5
	jr SeqPart_NullRet

MidiEvtSize_Return7:
	ldb l, 0x7
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
	ldb l, 0x0

SeqPart_NullRet:
	ret

MidiEvtSize_Return2:
	ldb l, 0x2
	jr SeqPart_NullRet

SeqPart_ReturnStatusFour:
	ldb l, 0x4
	jr SeqPart_NullRet

MidiEvtSize_Return1:
	ldb l, 0x1
	jr SeqPart_NullRet

SeqPlay_CheckRepeatActive:
	ldb L, 0x00
	ld a, (0x8c9a:16)
	cp A,0x87
	ret Z
	.byte 0xc9, 0xcf, 0x88, 0xb0, 0xf6, 0xd1, 0x2c, 0x23
	.byte 0x21, 0xd1, 0x2a, 0x23, 0x20, 0xc1, 0x98, 0x8c
	.byte 0x25, 0xcd, 0xcf, 0x0b, 0x6e, 0x0c, 0xf1, 0xb1
	.byte 0x28, 0xc9, 0xb0, 0xf6, 0xd8, 0xf1, 0x63, 0x11
	.byte 0x68, 0x11
SeqRepeatCheck_Mode13:
	cp e, 0x13
	ret z
	bit 0, (0x28b1:16)
	ret z
	cp bc, wa
	ret ugt

SeqRepeatCheck_ReturnActive:
	ldb l, 0x1

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
	lds bc, 6
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
	lds bc, 3

SeqDataEvtBC_LoadAndReturn:
	ldb_sri L, 0x07, 0xe0, 0xe4
	jr SeqDataEvtBC_Return

SeqDataEvtBC_ReturnFF:
	ldb l, 0xff

SeqDataEvtBC_Return:
	ret

Part_SendVoiceOffAndCCEvents:
	dec 2,XSP
	push QIZ
	ld (XSP+0x02),A
	ld C,(XSP+0x02)
	extz BC
	lds wa, 0
	calr Part_ReadVoiceByte
	st_erpb_rr l, 0xfb
	ld A,(XSP+0x02)
	extz WA
	calr SeqBuf_WriteNoteOffEntry
	lda xwa, (0xe2d8:16)
	ld C,(XSP+0x02)
	dec 1,C
	ld (XWA+0x03),C
	lds bc, 4
	calr SeqBuf_WriteMidiEvent
	lda xwa, (0xe2dc:16)
	ld C,(XSP+0x02)
	dec 1,C
	ld (XWA+0x04),C
	lds bc, 5
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
	ld_erpb_rr a, 0xfb
	extz WA
	lda xbc, (WidgetData_DrawbarPositionTable_0xBE:24)
	ldb_dri c, 0x07, 0xe4, 0xe0
	lda xwa, (0xe2e2:16)
	ld (XWA+0x02),C
	ld C,(XSP+0x02)
	dec 1,C
	ld (XWA+0x06),C
	lds bc, 7
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents
SeqBuf_MidiEventReturnPath:
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqVoice_FindSingleActive:
	resda 0, 9954
	ldb l, 0x0
	ldb d, 0x1

SeqVoiceSingle_ScanLoop:
	ld a, d
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqVoiceSingle_ShiftDone
	slaa bc

SeqVoiceSingle_ShiftDone:
	andda16 xbc, 3407
	jr z, SeqVoiceSingle_CountCheck
	inc 1, l
	ld e, d

SeqVoiceSingle_CountCheck:
	cps l, 1
	jr ugt, SeqVoiceSingle_FoundOrDone
	inc 1, d
	cp d, 0x10
	jr ule, SeqVoiceSingle_ScanLoop

SeqVoiceSingle_FoundOrDone:
	cps l, 1
	jp_24 nz, PartSelect_UpdateDisplayState
	extz de
	lds wa, 0
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xf
	ret z
	cp l, 0x13
	jr ule, SeqVoiceSingle_LookupAndApply
	ldb l, 0x0

SeqVoiceSingle_LookupAndApply:
	.byte 0xdb, 0x12, 0xf2, 0x36, 0x45, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xec, 0x25, 0xf1, 0xe2, 0x26, 0xb8
	.byte 0xf1, 0x9e, 0x8c, 0x45, 0xda, 0x12, 0x0b, 0xff
	.byte 0x00, 0x30, 0x90, 0x00, 0x31, 0x10, 0x00, 0x1d
	.byte 0x53, 0xaa, 0xfd, 0x0e
SeqNotify_DataBlock:
	.byte 0xf1, 0xb3
	pushw	wa
	.byte 0xb8
	ret

SeqNotify_CheckAndClearStart:
	bit 0, (0x28b3:16)
	ret Z
	ld a, (0x8c9a:16)
	cp A,0x87
	jr z, SeqNotify_ClearStartFlag
	cp A,0x88
	call_24 nz, (0xfdad86)
SeqNotify_ClearStartFlag:
	resda 0, 0x28b3
	ret

Seq_HandleModeTransition:
	cpdi16 0xf19e, 0
	jr nz, SeqModeTransit_ClearFlags
	ld (8968:16), 0
	resda 3, 0x28a7

SeqModeTransit_ClearFlags:
	.byte 0xf1, 0x20, 0x04, 0xb4, 0xf1, 0x20, 0x04, 0xb1
	.byte 0xc1, 0x1e, 0x04, 0x21, 0xc9, 0x30, 0x04, 0xc9
	.byte 0x30, 0x01, 0xf1, 0x1e, 0x04, 0x41, 0xc1, 0x98
	.byte 0x8c, 0x3f, 0x13, 0x6e, 0x05, 0x1e, 0x1d, 0x00
	.byte 0x68, 0x14
SeqModeTransit_CheckBit5:
	bit 5, (0x28ac:16)
	jr nz, SeqModeTransit_LoadPreset
	bit 2, (1057:16)
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
	ld a, (0x28a4:16)
	extz wa
	jp Voice_GetPresetFieldWord

SeqModeTransit_UpdateParts:
	ld wa, (0xf19e:16)
	cps wa, 0
	jr z, SeqModeTransit_ClearPartState
	cpda16 xwa, 0x2838
	call_24 nz, SeqAcc_InitPlaybackState
	ld a, (1075:16)
	cpda8 a, 0x286a
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
	cpdi16 0x28a8, 0
	jr z, SeqModeTransit_SetRepeatBit
	set 0, a
	ld (0x28a7:16), a

SeqModeTransit_SetRepeatBit:
	setda 1, 0x28a7
	ld wa, (0xf19e:16)
	cpda16 xwa, 0x2838
	jr z, SeqModeTransit_ClearSysFlag
	call AccWrap_PositionClear
	resda 0, 0x28a6

SeqModeTransit_ClearSysFlag:
	resda 0, 1115
	ret

SeqCh_LoadChannelConfig:
	lda xsp, (xsp - 18)
	ld (xsp + 16), a
	cp (xsp + 16), 0x14
	jr ule, SeqChLoad_SetupAndCopy
	ldw wa, 0x1d
	calr SeqData_SetErrorCode

; === v7-specific block: SeqChLoad_SetupAndCopy (161 bytes) ===
SeqChLoad_SetupAndCopy:
	.incbin "includes/romslices/v7_block_seqchload_setupandcopy.bin"
; === end v7 block ===
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

; === v7-specific block: SeqCh_LoadData_CheckBass (107 bytes) ===
SeqCh_LoadData_CheckBass:
	.incbin "includes/romslices/v7_block_seqch_loaddata_checkbass.bin"
; === end v7 block ===
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
	anddm16 8982, xbc
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
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, SeqCh_LoadData_CopyLoop
	ldw hl, 0xffff
	jr SeqCh_WriteData_Return

SeqCh_LoadData_NotEndMark:
	ld (xhl + 1), 0x0
	lds wa, 0
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
	ldb_spi A, 0xe4
	lda_dpi XBC, 0xe8
	cp xbc, xhl
	jr c, SeqCh_WriteData_CopyLoop
	lds hl, 0

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
	lda_dri XWA, 0xe5, 0x80, 0x00
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda_dri XWA, 0xe5, 0x90, 0x00
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	lda_dri XWA, 0xe5, 0x88, 0x00
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
	lds iz, 0
	ld wa, (9002:16)
	subda16 xwa, 9000
	jr c, SeqVoice_InitRepeat_FinalCopy

SeqVoice_InitRepeat_CopyLoop:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 8)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	inc 1, iz
	ld wa, (9002:16)
	subda16 xwa, 9000
	cp iz, wa
	jr ule, SeqVoice_InitRepeat_CopyLoop

SeqVoice_InitRepeat_FinalCopy:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	lda xwa, (9016:16)
	ldmmw_dri 0xe1, 0x80, 0x00, 0x28, 0x23
	ldmmw_dri 0xe1, 0x88, 0x00, 0x28, 0x23
	ldw wa, 0x11
	calr SeqCh_LoadChannelConfig
	ldw wa, 0x13
	lds bc, 1
	call SeqPart_ReadEventStream
	popw iz
	inc 8, xsp
	ret

SeqVoice_ScanAndAssignParts:
	pushw_erp 0xfa
	ld bc, (0x28a8:16)
	cps bc, 0
	jrl z, SeqVoice_ScanParts_Return
	ldib_erp 0xfb, 1

SeqVoice_ScanParts_PartLoop:
	stb_erp A, 0xfb
	dec 1, a
	lds de, 1
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
	stb_erp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xe
	jr nz, SeqVoice_ScanParts_LoopNext
	cp (0x28be:16), 255
	jr z, SeqVoice_ScanParts_ReadGPIO
	stb_erp A, 0xfb
	extz wa
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	stb_erp A, 0xfb
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xd
	ld (0x28be:16), 255
	jr SeqVoice_ScanParts_LoopNext

SeqVoice_ScanParts_ReadGPIO:
	lda	xwa, (64602:16)
	ld	e, (xwa+3)
	and	e, 7
	lda	xbc, (xwa+4)
	ld	a, (xbc)
	and	a, 248
	or	e, a
	ld	(xbc), e
	extz	de
	pushw	7
	ldw	wa, 72
	lds	bc, 4
	call	16624211
SeqVoice_ScanParts_LoopNext:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	ldb_erp A, 0xfa
	cp_erpb 0xfb, 0x10
	jr ugt, SeqVoice_ScanParts_Epilogue

SeqVoice_ScanParts_Continue:
	stb_erp A, 0xfa
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xe
	jr nz, SeqPos_AdvanceToNextBar
	cp (0x28be:16), 255
	jr z, SeqPos_AdvanceToNextBar
	stb_erp A, 0xfa
	extz wa
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	stb_erp A, 0xfa
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xd
	ld (0x28be:16), 255

SeqPos_AdvanceToNextBar:
	stb_erp A, 0xfa
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
	cps l, 0
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
	lds bc, 0
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
	lds de, 0

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
	cps wa, 0
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
	cpda8_24 a, (0xffe3)
	jr nz, PartCtrl_ReadAndRelinkNext
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
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
	cpda8_24 a, (0xffe3)
	jr nz, PartCtrl_ReadWordCheck
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
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
	lds wa, 1
	lds bc, 1
	calr PartCtrl_SetClearBit7
	lds wa, 1
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	lds wa, 1
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	lds wa, 2
	lds bc, 1
	calr PartCtrl_SetClearBit7
	lds wa, 2
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 2
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	jr PartCtrl_DeallocReturn

PartCtrl_CheckUnlinkFlag:
	cpdi16 0xf22f, 1
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
	ldb_erp A, 0xfb
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
	stiw_da (0x00ffec), 0x0000
	calr Part_UnlinkVoiceFromChain

PartRelRange_OuterLoop:
	stb_erp A, 0xfb
	stb_erp A, 0xfb
	cp a, (xsp + 4)
	jrl ugt, PartRelRange_OuterNext

PartRelRange_InnerLoop:
	ld a, (xsp + 6)
	ldb_erp A, 0xfa
	cp a, (xsp + 8)
	jrl ugt, PartRelRange_InnerNext

PartRelRange_ClearAndWrite:
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	calr Part_ReadVoiceWord
	ld iz, hl
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	lds de, 5
	calr Part_WriteByte_Indexed
	cp (xsp + 12), 0xb
	jr nz, PartRelRange_StealVoices
	cp (xsp + 10), 0x32
	jr z, PartRelRange_WriteDefaults

PartRelRange_StealVoices:
	ld wa, iz
	calr Part_StealAndReallocVoices

PartRelRange_WriteDefaults:
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1c
	lds de, 0
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xcb
	lds de, 0
	calr Part_WriteByte
	inc1b_erp 0xfa
	stb_erp A, 0xfa
	cp a, (xsp + 8)
	jrl ule, PartRelRange_ClearAndWrite

PartRelRange_InnerNext:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cp a, (xsp + 4)
	jrl ule, PartRelRange_InnerLoop

PartRelRange_OuterNext:
	pushw	1
	ldw	wa, 145
	lds	bc, 3
	lds	de, 0
	call	16624211
	pop	xiz
	lda	xsp, (xsp+10)
	ret
Part_ClearAndStealSingleVoice:
	dec 4, xsp
	ld (xsp + 2), a
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	lds de, 0
	calr Part_SetClearVoiceBit7
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	ld (xsp), hl
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	lds de, 5
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
	cps a, 1
	jr c, SeqValidate_PartFail
	cpda8 a, 0x28a1
	jr ule, SeqValidate_PartOK

SeqValidate_PartFail:
	ldw hl, 0xffff
	ret

SeqValidate_PartOK:
	lds hl, 0
	ret

Seq_ValidateTempoValue:
	cps wa, 1
	jr c, SeqValidate_TempoFail
	cp wa, 0x3e7
	jr ule, SeqValidate_TempoOK

SeqValidate_TempoFail:
	ldw hl, 0xffff
	ret

SeqValidate_TempoOK:
	lds hl, 0
	ret

Seq_ValidateAllParams_DataBlock:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, 22
	extz	wa
	calr	65488
	cps	hl, 0
	jr	nz, 46
	ld	a, (9858:16)
	extz	wa
	calr	65475
	cps	hl, 0
	jr	nz, 33
	ld	wa, (9778:16)
	calr	65481
	cps	hl, 0
	jr	nz, 22
	ld	wa, (9694:16)
	calr	65470
	cps	hl, 0
	jr	nz, 11
	ld	wa, (9862:16)
	calr	65459
	cps	hl, 0
	jr	z, 4
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ret

Seq_ValidatePartAndTempo:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPT_CheckTempoValues
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ld a, (9858:16)
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn

SeqValPT_CheckTempoValues:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ld wa, (9862:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, SeqValPT_ReturnOK

Seq_TempoValidationFailReturn:
	ldw hl, 0xffff
	ret

SeqValPT_ReturnOK:
	lds hl, 0
	ret

Seq_ValidatePartTempoAndKey:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPTK_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	ret nz

SeqValPTK_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	ret nz
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	ret nz
	ld a, (9726:16)
	extz wa
	cps wa, 0
	jr mi, SeqValPTK_ClampKeyValue
	cp wa, 0xc
	jr le, SeqValPTK_LookupAndReturn

SeqValPTK_ClampKeyValue:
	ldw wa, 0xd

SeqValPTK_LookupAndReturn:
	lda xix, (WidgetData_DrawbarPositionTable_0x17A:24)
	ldb_sri L, 0x07, 0xf0, 0xe0
	exts hl
	ret

Seq_ValidatePartTempoAndMode:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqValPTM_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF

SeqValPTM_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF
	ld a, (9808:16)
	cps a, 0
	jr z, SeqPart_SuccessReturn
	cps a, 1
	jr z, SeqPart_SuccessReturn
	cps a, 2
	jr z, SeqPart_SuccessReturn

SeqPart_ErrorReturnFFFF:
	ldw hl, 0xffff
	ret

SeqPart_SuccessReturn:
	lds hl, 0
	ret

Seq_ValidatePartAndTempoAlt:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValPTA_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqValPTA_FailReturn

SeqValPTA_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqValPTA_FailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, SeqValPTA_OKReturn

SeqValPTA_FailReturn:
	ldw hl, 0xffff
	ret

SeqValPTA_OKReturn:
	lds hl, 0
	ret

Seq_ValidateExtended_DataBlock:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, 9
	extz	wa
	calr	65164
	cps	hl, 0
	jr	nz, 22
	ld	wa, (9778:16)
	calr	65170
	cps	hl, 0
	jr	nz, 11
	ld	wa, (9694:16)
	calr	65159
	cps	hl, 0
	jr	z, 4
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ret

SeqPos_DecrementAndCheck:
	dec 2, xsp
	push xiz
	ld wa, (0x28af:16)
	ldw_erp WA, 0xfa
	ld wa, (9830:16)
	ld (xsp + 4), wa
	dec 1, wa
	ld (9830:16), wa
	cps wa, 5
	jr nc, SeqPosDec_Return
	ld wa, (0x28af:16)
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	cps iz, 0
	jr z, SeqPosDec_HandleInvalid
	cp iz, 0x4d8
	jr ule, SeqPosDec_TestBit7

SeqPosDec_HandleInvalid:
	ld (0x287a:16), 10
	stw_erp WA, 0xfa
	ld (0x28af:16), wa
	mrdw5 0x9f, 0x04, 0x19, 0x66, 0x26
	ldw wa, 0x50
	jr SeqPosDec_SetErrorCode

SeqPosDec_TestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, SeqPosDec_StorePosition
	ld (0x287a:16), 11
	stw_erp WA, 0xfa
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

SeqPos_DataBlock:
	.incbin "includes/romslices/v7_transplant_SeqPos_DataBlock.bin"
Seq_ValidatePartTempoAndRange:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValPTR_CheckTempo
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_ValidationFailReturn

SeqValPTR_CheckTempo:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_ValidationFailReturn
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_ValidationFailReturn
	cp (9750:16), 127
	jr ugt, Seq_ValidationFailReturn
	cp (9816:16), 127
	jr ule, SeqValRange_CheckBounds

Seq_ValidationFailReturn:
	ldw hl, 0xffff
	ret

SeqValRange_CheckBounds:
	lds hl, 0
	ret

SeqValRange_ReturnOK:
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	a, (0x2878:16)
	.byte 0xc7
	swi	3
	.byte 0x99, 0xc1
	pushw	de
	ldb	l, 25
	jrl	7720
	pushw	0xc700
	swi	3
	.byte 0x89
	ld	(0x2878:16), a
	pop qiz
	ret

SeqVoice_InitAllChannelParams:
	push xiz
	calr SeqVoice_SetDefaultParams
	ld a, (0x2877:16)
	ldb_erp A, 0xfa
	ld (0x2877:16), 1
	ld a, (0x2878:16)
	cpda8_24 a, (0xffe3)
	jr nz, SeqDispatch_ValidateParam
	ldib_erp 0xfb, 0
	jr SeqDispatch_ParamFail

SeqDispatch_ValidateParam:
	inc 1, a
	ldb_erp A, 0xfb

SeqDispatch_ParamFail:
	ldib_erp 0xf9, 1

SeqDispatch_ParamOK:
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xf9
	extz bc
	calr Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqTempo_CheckAndClamp
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xf9
	extz bc
	calr Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	call_24 nz, Part_StealAndReallocVoices

SeqTempo_CheckAndClamp:
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqDispatch_ParamOK
	ldib_erp 0xf9, 1

SeqTempo_ClampedReturn:
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	stb_erp C, 0xf9
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	stb_erp C, 0xf9
	extz bc
	lds de, 5
	calr Part_WriteByte_Indexed
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqTempo_ClampedReturn
	ldib_erp 0xf9, 1

SeqTempo_ApplyAndReturn:
	ld	a, (10360:16)
	inc	1, a
	extz	wa
	stb_erp	c, 249
	extz	bc
	lds	de, 0
	calr	7758
	ld	a, (10360:16)
	inc	1, a
	extz	wa
	stb_erp	c, 249
	extz	bc
	ldw	de, 65535
	calr	7826
	inc1b_erp	249
	cp_erpb	249, 16
	jr	ule, -46	; -> 0xF3F92F
	ld	a, (10360:16)
	inc	1, a
	extz	wa
	ldw	bc, 30
	lds	de, 0
	calr	7112
	ld	a, (10360:16)
	inc	1, a
	extz	wa
	ldw	bc, 28
	lds	de, 0
	calr	7096
	ld	a, (10360:16)
	inc	1, a
	extz	wa
	ldw	bc, 203
	lds	de, 0
	calr	7043
	ld	a, (10360:16)
	cpda8_24	xbc, (65507)
	jr	nz, 102	; -> 0xF3F9FE
	ldw	(61854:16), 0
	call	16635550
	stiw_da	(65516), 0
	ldw	(61852:16), 0
	ld	(62027:16), 0
	ldib_erp	249, 1
SeqBufPos_UpdateAndSync:
	stb_erp C, 0xf9
	extz bc
	lds wa, 0
	ldw de, 0xffff
	calr Part_WriteWord_Indexed
	stb_erp C, 0xf9
	extz bc
	lds wa, 0
	lds de, 5
	calr Part_WriteByte_Indexed
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqBufPos_UpdateAndSync
	ldib_erp 0xf9, 1

SeqBufPos_CheckLimit:
	stb_erp C, 0xf9
	extz bc
	lds wa, 0
	lds de, 0
	calr Part_SetClearVoiceBit7
	stb_erp C, 0xf9
	extz bc
	lds wa, 0
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	inc1b_erp 0xf9
	cp_erpb 0xf9, 0x10
	jr ule, SeqBufPos_CheckLimit

SeqBufPos_HandleOverflow:
	stb_erp A, 0xfa
	ld (0x2877:16), a
	pop xiz
	ret

SeqBufPos_WrapAround:
	pushw_erp 0xfa
	ldib_erp 0xfb, 1

SeqBufPos_StoreResult:
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1c
	lds de, 0
	calr Part_WriteWord
	ldib_erp 0xfa, 1

SeqBufPos_Return:
	stb_erp	a, 251
	extz	wa
	stb_erp	c, 250
	extz	bc
	lds	de, 0
	calr	7523
	stb_erp	a, 251
	extz	wa
	stb_erp	c, 250
	extz	bc
	ldw	de, 65535
	calr	7594
	stb_erp	a, 251
	extz	wa
	stb_erp	c, 250
	extz	bc
	ldw	de, 65535
	calr	7000
	stb_erp	a, 251
	extz	wa
	stb_erp	c, 250
	extz	bc
	lds	de, 5
	calr	7026
	inc1b_erp	250
	cp_erpb	250, 16
	jr	ule, -71	; -> 0xF3FA1D
	stb_erp	a, 251
	extz	wa
	ldw	bc, 30
	lds	de, 0
	calr	6852
	stb_erp	a, 251
	extz	wa
	ldw	bc, 203
	lds	de, 0
	calr	6802
	inc1b_erp	251
	cp_erpb	251, 10
	jr	ule, -122	; -> 0xF3FA0D
	ldw	(61854:16), 0
	stiw_da	(65516), 0
	call	16635550
	ld	(62027:16), 0
	calr	16261
	ldw	(10357:16), 0
	stiw_da	(65516), 0
	pop	qiz
	ret
SeqAccPlay_InitAndDispatch:
	ld a, (0x2877:16)
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturn
	ld a, (9858:16)
	cpdm8 0x2877, a
	jr z, SeqPart_ErrorReturn
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturn
	ld a, (9860:16)
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr z, SeqAccPlay_Return

SeqPart_ErrorReturn:
	ldw hl, 0xffff
	ret

SeqAccPlay_Return:
	lds hl, 0
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
	cps l, 0
	jr nz, PartCtrl_AdvancePos_SaveNew
	ld (0x287a:16), 2
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
	cps wa, 5
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
	cps l, 0
	jr nz, PartCtrl_NavBack_CheckZero
	ldw wa, 0x47
	calr SeqData_SetErrorCode
	ld (0x287a:16), 2
	jr SeqPart_RestoreReturn3

PartCtrl_NavBack_CheckZero:
	cps iz, 0
	jr z, PartCtrl_NavBack_ErrorEnd
	cp iz, 0xffff
	jr nz, PartCtrl_NavBack_SaveNew

PartCtrl_NavBack_ErrorEnd:
	ld (0x287a:16), 11
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
	cps iz, 0
	jr ge, PartCtrl_SaveChainPosition
	ld (0x287a:16), 5
	jr PartCtrl_RestoreReturn

PartCtrl_AdvanceEntry_TestBit7:
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, PartCtrl_SaveChainPosition
	ld (0x287a:16), 2
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
	cps wa, 5
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
	cps l, 0
	jr nz, PartCtrl_NavBackAlt_CheckZero
	ldw wa, 0x48
	calr SeqData_SetErrorCode
	ld (0x287a:16), 2
	jr SeqPart_RestoreReturn2

PartCtrl_NavBackAlt_CheckZero:
	cps iz, 0
	jr z, PartCtrl_NavBackAlt_ErrorEnd
	cp iz, 0xffff
	jr nz, PartCtrl_NavBackAlt_SaveNew

PartCtrl_NavBackAlt_ErrorEnd:
	ld (0x287a:16), 11
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
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, Part_ValidateVoice_ReadWord
	ld (0x287a:16), 1
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_ReadWord:
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr nz, Part_ValidateVoice_CheckFFFF
	ld (0x287a:16), 2
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_CheckFFFF:
	cp iz, 0x4d8
	jr ule, Part_ValidateVoice_CheckOverflow
	ld (0x287a:16), 10
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_CheckOverflow:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, Part_ValidateVoice_SetPosition
	ld (0x287a:16), 11
	jr PartCtrl_ConfigureAndReturn

Part_ValidateVoice_SetPosition:
	ld (0x28af:16), iz
	ldw (9830:16), 5
	ld (0x287a:16), 0

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
	cp (0x287a:16), 0
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
	cps de, 5
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
	ld (0x287a:16), 10
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
	ld (0x287a:16), 11
	jr SeqPart_DecisionReturn

Part_ValidateSetup_CheckBarMark:
	ld (0x287a:16), 0

SeqPart_DecisionReturn:
	inc 2, xsp
	ret

SeqTrack_LookupChannelData:
	ld	a, (0x2877:16)
	cp	a, 127
	jr	z, 9
	extz	wa
	calr	63694
	cps	hl, 0
	jr	nz, 31
	ld	wa, (9778:16)
	calr	63700
	cps	hl, 0
	jr	nz, 20
	ld	wa, (9694:16)
	calr	63689
	cps	hl, 0
	jr	nz, 9
	ld	a, (9812:16)
	cp	a, 128
	jr	nz, 4
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ret

SeqPart_LoadAndValidateData:
	pushw_erp 0xfa
	ld a, (9770:16)
	cps a, 0
	jr z, Part_PopRetFA2
	bit 3, (0x287b:16)
	jr nz, Part_PopRetFA2
	ld a, (0xf1ee:16)
	cp a, 0x11
	jr nz, SeqPart_StoreChannelParams
	ldb a, 0x7f

SeqPart_StoreChannelParams:
	ld (0x2877:16), a
	ld wa, (0xf1ef:16)
	ld (9778:16), wa
	ld wa, (0xf1ef:16)
	addda16 xwa, 9694
	ld (9862:16), wa
	ldib_erp 0xfb, 0
	ld a, (9770:16)
	cps a, 0
	jr ule, Part_PopRetFA2

SeqPart_LoadDualPartLoop:
	.byte 0xf1, 0xa6, 0x7e, 0x00, 0xff, 0xf1, 0x7a, 0x28
	.byte 0x00, 0x00, 0x1d, 0xe7, 0xad, 0xf4, 0xc1, 0xa6
	.byte 0x7e, 0x3f, 0x23, 0x6e, 0x1e, 0xf1, 0x7b, 0x28
	.byte 0xcb, 0x6e, 0x18, 0xd1, 0x86, 0x26, 0x20, 0xd1
	.byte 0xde, 0x25, 0x80, 0xf1, 0x86, 0x26, 0x50, 0xc7
	.byte 0xfb, 0x61, 0xc7, 0xfb, 0x89, 0xc1, 0x2a, 0x26
	.byte 0xf1, 0x67, 0xcd
Part_PopRetFA2:
	popw_erp 0xfa
	ret

SeqPart_LoadDualPartData:
	.incbin "includes/romslices/v7_transplant_SeqPart_LoadDualPartData.bin"
SeqVoice_SeekToBar:
	push xiz
	lds iz, 1
	ldiw_erp 0xfa, 0
	ld (0x287a:16), 0
	ld (0x288d:16), c
	extz wa
	calr Part_ValidateVoiceChannel
	cp (0x287a:16), 0
	jr nz, SeqVoice_PopIzRet2
	calr SeqVoice_ValidateAndProcessState
	cpdi16 0x287f, 1
	jr z, SeqVoice_PopIzRet2

SeqVoice_SeekBarLoop:
	ld a, (0x288e:16)
	extz wa
	stw_erp BC, 0xfa
	calr SeqData_SkipSections
	ldw_erp HL, 0xfa
	cp (0x287a:16), 0
	jr nz, SeqVoice_PopIzRet2
	inc 1, iz
	calr SeqTrack_ProcessControlBytes
	cp (0x287a:16), 0
	jr nz, SeqVoice_PopIzRet2
	cpda16 xiz, 0x287f
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
	ld (0x287a:16), 8
	jr SeqData_UpdatePositionAndReturn

SeqData_SkipCheckBarMarker:
	cp l, 0x81
	jr nz, SeqData_SkipReadParamBlock
	inc1b_erp 0xfb
	calr SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqData_SkipCountBarsLoop
	jr SeqData_UpdatePositionAndReturn

SeqData_SkipReadParamBlock:
	call SeqData_ReadParamBlock
	cp (0x287a:16), 0
	jr nz, SeqData_UpdatePositionAndReturn

SeqData_SkipCountBarsLoop:
	stb_erp A, 0xfb
	cp a, (xsp + 4)
	jr nz, SeqData_SkipReadLoop

SeqData_UpdatePositionAndReturn:
	stb_erp A, 0xfb
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
	stda32 3304, xwa
	ldw (3376:16), 0
	ret

SeqVoice_InitReturnZero:
	lds wa, 0
	jrl Part_InitVoiceDefaults

; AppEvent extended handler
AppEvent_ExtendedHandler:
	ld xwa, WidgetData_DrawbarPositionTable_0x12E
	jr Part_LoadAndApplyVoiceTable
	ld xwa, WidgetData_DrawbarPositionTable_0x13A
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableB:
	ld xwa, WidgetData_DrawbarPositionTable_0x146
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableA:
	ld xwa, WidgetData_DrawbarPositionTable_0x152
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableC:
	ld xwa, WidgetData_DrawbarPositionTable_0x15E
	jr Part_LoadAndApplyVoiceTable

SeqVoice_ApplyTableEntry:
	ld xwa, WidgetData_DrawbarPositionTable_0x122
	jr Part_LoadAndApplyVoiceTable

Part_LoadAndApplyVoiceTable:
	ld c, (0x287a:16)

	extz bc

	.byte 0xc3, 0x07, 0xe0, 0xe4, 0x19, 0xa6, 0x7e	; ldmm_srib 0x07, 0xe0, 0xe4, 0x42, 0x7f (v7 displacement)

	ret



Part_ValidateAndSetupVoiceChannel:
	dec 4, xsp
	pushw iz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr Part_ValidateVoiceChannel
	ld a, (0x287a:16)
	cps a, 0
	jr z, Part_ValidateSetup_ClearAndProcess
	cps a, 1
	jr nz, Part_ValidateSetup_ErrorReturn
	ld (0x287a:16), 0

Part_ValidateSetup_ErrorReturn:
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_ClearAndProcess:
	ld (0x287a:16), 0
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
	ld (0x287a:16), 10
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_TestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, Part_ValidateSetup_StoreAndRead

Part_ValidateSetup_NoData:
	ld (0x287a:16), 11
	jr SeqData_TrackProcessComplete

Part_ValidateSetup_StoreAndRead:
	ld (0x28af:16), iz
	ld a, (xsp + 2)
	extz wa
	ld (9830:16), wa
	calr SeqData_ReadNextByte
	cp l, 0x84
	jr nz, SeqData_TrackProcessComplete
	ld (0x287a:16), 6

SeqData_TrackProcessComplete:
	popw iz
	inc 4, xsp
	ret

SeqData_ScanAllTracks:
	push xiz
	lds iz, 0
	lds32 xwa, 1
	stda32 9690, xwa
	resda 1, 0x287b
	cpdi16 9694, 0
	jr z, SeqData_PopIzRet

SeqData_ScanTracks_OuterLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqData_ScanTracks_NextTrack

SeqData_ScanTracks_InnerLoop:
	bit 1, (0x287b:16)
	jr z, SeqData_ScanTracks_SetFlag
	lds32 xwa, 1
	adddm32 9690, xwa
	calr SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqData_PopIzRet

SeqData_ScanTracks_SetFlag:
	setda 1, 0x287b
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqData_ScanTracks_Check81
	ld (0x287a:16), 7
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
	cp (0x287a:16), 0
	jr nz, SeqData_PopIzRet
	cpda16 xiz, 9694
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
	ld (0x287a:16), 8
	jr SeqData_PopIzRet2

SeqData_CheckPositionLimit:
	cp iz, 0x4d8
	jr ule, SeqData_ReadAndTestBit7
	ld (0x287a:16), 10
	jr SeqData_PopIzRet2

SeqData_ReadAndTestBit7:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, SeqData_StoreNewPosition
	ld (0x287a:16), 11
	jr SeqData_PopIzRet2

SeqData_StoreNewPosition:
	ld (0x28af:16), iz
	ldw (9830:16), 5
	ld (0x287a:16), 0

SeqData_PopIzRet2:
	popw iz
	ret

SeqVoice_FindDrumPartIndex:
	ld a, (0x287b:16)
	res 2, a
	ld (0x287b:16), a
	ldb l, 0x0
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
	ldb l, 0x0
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
	ldw_erp WA, 0xfa
	ld a, (0x288d:16)
	extz wa
	calr Part_ValidateVoiceChannel
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqVoice_ValidateState_SaveRefs
	resda 2, 0x287b
	ld (0x287a:16), 0
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
	setda 5, 0x287b

SeqData_RhythmRestoreRefs:
	ldmm16 9698, 0x28af
	ldmm16 0x289b, 9830

SeqVoice_ValidateState_RestoreRegs:
	ld (0x28af:16), iz
	stw_erp WA, 0xfa
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
	ld (0x287a:16), 0
	ld a, (0x287b:16)
	bit 2, a
	jrl z, SeqTrack_PopIzReturn
	bit 5, a
	jrl nz, SeqTrack_PopIzReturn
	ld wa, (0x28af:16)
	ldw_erp WA, 0xfa
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
	cp (0x287a:16), 0
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
	setda 5, 0x287b
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
	cp (0x287a:16), 0
	jr z, SeqTrack_ReadAndDispatch

SeqData_SaveIndexReturn:
	stw_erp WA, 0xfa
	ld (0x28af:16), wa
	ld (9830:16), iz
	ld (0x287a:16), 0

SeqTrack_PopIzReturn:
	pop xiz
	ret

SeqTrack_ScanBarPositions:
	push xiz
	lds iz, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqTrack_ScanReadFinal

SeqTrack_ScanReadLoop:
	calr SeqData_ReadNextByte
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqTrack_ScanSetEndFlag
	cp_erpb 0xfb, 0x81
	jr nz, SeqTrack_ScanCheckResetMarker
	inc 1, iz
	calr SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr nz, SeqTrack_ScanCheckResetAlt

SeqTrack_ScanSetEndFlag:
	setda 5, 0x287b
	jr SeqTrack_ScanReturn

SeqTrack_ScanReadParam:
	calr SeqData_ReadParamBlockAlt
	cp (0x287a:16), 0
	jr z, SeqTrack_ScanComparePosition

SeqTrack_ScanSetEndAndClear:
	setda 5, 0x287b
	ld (0x287a:16), 0
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
	lds iz, 0
	calr SeqData_ReadNextByte
	ld (9606:16), l
	cp l, 0x82
	jr z, SeqData_ReadParamError
	cp l, 0x84
	jr z, SeqData_ReadParamError

SeqData_ReadParamLoop:
	calr SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	cps iz, 7
	jr ule, SeqData_ReadParamLoop

SeqData_ReadParamError:
	ld (0x287a:16), 1

SeqData_ReadParamReturn:
	popw iz
	ret

SeqPart_SeekAllVoicesToBar:
	pushw_erp 0xfa
	ld (0x287a:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_RestoreReturn

SeqPart_SeekVoiceLoop:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ld a, (0x287a:16)
	cps a, 0
	jr nz, SeqPart_SeekCheckError
	calr SeqVoice_FindDrumPartIndex
	ldmm16 0x287f, 9778
	ld a, (9780:16)
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_SeekNextVoice
	cps a, 1
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr z, SeqData_ClearAndLoop
	jr SeqPart_RestoreReturn

SeqPart_SeekCheckError:
	cps a, 1
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr nz, SeqPart_RestoreReturn

SeqData_ClearAndLoop:
	ld (0x287a:16), 0

SeqPart_SeekNextVoice:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpda8 a, 0x28a1
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
	lds wa, 0
	ld de, iz
	calr Part_WriteWord_Indexed
	ld wa, (0x287d:16)
	ld c, a
	extz bc
	ld e, (xsp + 2)
	extz de
	lds wa, 0
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
	adddm32 9690, xwa

SeqPart_CalcRemainingTicks:
	ldw iz, 0xff
	ld c, (9780:16)
	extz bc
	lds wa, 0
	calr Part_ReadWord_Indexed
	sub iz, hl
	ld wa, iz
	extz xwa
	ld xhl, (9690:16)
	cp xhl, xwa
	jr ugt, SeqPart_CalcDivideAndStore
	lds32 xwa, 0
	stda32 9914, xwa
	jr SeqPart_CalcStoreResult

SeqPart_CalcDivideAndStore:
	sub	xhl, xwa
	add	xhl, 251
	dec	1, xhl
	ld	xwa, xhl
	ld	xbc, 251
	call	16712763
	stda32	(9914), xhl
SeqPart_CalcStoreResult:
	ld xwa, (9914:16)
	ld (9930:16), wa
	popw iz
	ret

SeqPart_PositionUpdateBlock:
	.byte 0xd7
	swi	2
	.byte 0x04, 0xd1
	ldw	bc, 6642
	.byte 0xcc
	ldb	h, 241
	jrl	gt, 40
	nop
	.byte 0xc7
	swi	3
	.byte 0xa9, 0xc1, 0xa1
	pushw	wa
	push	xsp
	normal
	jrl	c, 186
	stb_erp a, 251
	ld	(9780:16), a
	stb_erp a, 251
	extz	wa
	calr	63542
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 12
	cp	a, 8
	jr	z, 49
	cps	a, 1
	jr	z, 45
	jrl	151
	calr	64523
	.byte 0xd1
	ld	h, (xiz)
	pop_f
	jrl	nc, -16088
	ldw	ix, 8486
	ldb_erp a, 251
	extz	wa
	extz	hl
	ld	bc, hl
	calr	63898
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 16
	cp	a, 8
	jr	z, 4
	cps	a, 1
	jr	nz, 109
	ld	(0x287a:16), 0
	jr	89
	.byte 0xd1
	ldw	de, 6438
	jrl	nc, -16088
	ld	l, (xiy+40)
	ld	a, (9780:16)
	ldb_erp a, 251
	extz	wa
	extz	hl
	ld	bc, hl
	calr	63848
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 7
	cp	a, 8
	jr	z, -46
	jr	61
	calr	64234
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 9
	cps	a, 7
	jr	nz, 25
	ld	(0x287a:16), 0
	calr	65261
	ld	wa, (9932:16)
	ld	bc, (9930:16)
	cp	wa, bc
	jr	nc, 7
	ld	(0x287a:16), 5
	jr	19
	sub	wa, bc
	ld	(9932:16), wa
	inc1b_erp 251
	stb_erp a, 251
	cpda8 xbc, (10401)
	jrl	ule, -186
	pop qiz
	ret

SeqPart_CalcTickRate:
	ld c, (9780:16)
	extz bc
	lds wa, 0
	calr Part_ReadByte_Indexed
	ld wa, hl
	dec 5, wa
	extz xwa
	ld xhl, (9690:16)
	cp xhl, xwa
	jr ugt, SeqPart_CalcTickDivide
	lds32 xhl, 0
	jr SeqPart_CalcTickStore

SeqPart_CalcTickDivide:
	sub	xhl, xwa
	ld	xwa, xhl
	ld	xbc, 251
	call	16712763
	inc	1, xhl
SeqPart_CalcTickStore:
	ld (9930:16), hl
	ret

SeqPart_CopyDataPrimary:
	dec 4, xsp
	push xiz
	ld iz, (0x288b:16)
	ld wa, (0x2889:16)
	ldw_erp WA, 0xfa
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	lda xwa, (0x282c:16)
	mriw4 0x90, 0x19, 0x8b, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	lda xwa, (0x2830:16)
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	ld (0x287a:16), 0

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
	cp (0x287a:16), 0
	jr z, SeqCopy_StoreEndPosition
	jr SeqPart_SaveIndexReturn

SeqCopy_MismatchAdvance:
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr nz, SeqPart_SaveIndexReturn
	calr PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr z, SeqCopy_ComparePositionLoop
	jr SeqPart_SaveIndexReturn

SeqCopy_StoreEndPosition:
	lda xbc, (0x2834:16)
	ld wa, (0x2887:16)
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2885

SeqPart_SaveIndexReturn:
	ld (0x288b:16), iz
	stw_erp WA, 0xfa
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
	ldw_erp WA, 0xfa
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	lda xwa, (0x282c:16)
	mriw4 0x90, 0x19, 0x8b, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	lda xwa, (0x2830:16)
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	ld (0x287a:16), 0

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
	cp (0x287a:16), 0
	jr nz, SeqCopy2_SaveIndexReturn
	calr PartCtrl_NavigateBackwardAlt
	cp (0x287a:16), 0
	jr z, SeqCopy2_ComparePositionLoop

SeqCopy2_SaveIndexReturn:
	ld (0x288b:16), iz
	stw_erp WA, 0xfa
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
	addda32 xwa, 9690
	stda32 9914, xwa
	ldmm16 9912, 9884
	jrl SeqBuf_PageLayoutReturn

SeqBuf_CalcPageDivision:
	.byte 0xe9, 0xa0, 0xf1, 0xc2, 0x26, 0x60, 0xe8, 0xc8
	.byte 0xfb, 0x00, 0x00, 0x00, 0xe8, 0x69, 0x41, 0xfb
	.byte 0x00, 0x00, 0x00, 0x1d, 0x3b, 0x04, 0xff, 0xdb
	.byte 0x8e, 0xf1, 0x9a, 0x26, 0x56, 0xde, 0x88, 0xe8
	.byte 0x12, 0x41, 0xfb, 0x00, 0x00, 0x00, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xe1, 0xc2, 0x26, 0xa3, 0x21, 0xfb
	.byte 0xcf, 0xa1, 0xc9, 0x64, 0x20, 0x00, 0xe8, 0x12
	.byte 0xf1, 0xba, 0x26, 0x60, 0xd1, 0x31, 0xf2, 0xf6
	.byte 0x6b, 0x22, 0xd1, 0x9c, 0x26, 0x26, 0xf1, 0xb8
	.byte 0x26, 0x56, 0xbf, 0x04, 0x02, 0x00, 0x00, 0xd1
	.byte 0x9a, 0x26, 0x3f, 0x00, 0x00, 0x63, 0x3c
SeqBuf_ReadAndCheckValid:
	calr PartCtrl_ReadWordRoutine
	ldw_erp HL, 0xfa
	cp_erpw 0xfa, 0xff, 0xff
	jr nz, SeqBuf_WritePageEntries

SeqBuf_PageOverflowError:
	ld (0x287a:16), 5
	jr SeqBuf_PageLayoutReturn

SeqBuf_WritePageEntries:
	ld wa, iz
	stw_erp BC, 0xfa
	calr PartCtrl_WriteWord
	stw_erp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	stw_erp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord_Off1
	stw_erp IZ, 0xfa
	incw 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 9882
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
	ld (0x287a:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jrl c, SeqPart_PopRetFA

SeqPart_MultiVoiceLoop:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_MultiVoiceSeekBar
	cps a, 1
	jrl z, SeqData_ClearError
	cp a, 0x8
	jrl z, SeqData_ClearError
	jrl SeqPart_PopRetFA

SeqPart_MultiVoiceSeekBar:
	calr SeqVoice_FindDrumPartIndex
	ldmm16 0x287f, 9862
	ld a, (9780:16)
	ldb_erp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_MultiVoiceScanTracks
	cps a, 1
	jr z, SeqData_ClearError
	cp a, 0x8
	jr nz, SeqPart_PopReturn
	ld wa, (9778:16)
	cpda16 xwa, 9862
	jrl ugt, SeqPart_PopRetFA
	ld (0x287a:16), 0

SeqPart_MultiVoiceScanTracks:
	calr SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_MultiVoiceCalcDelta
	cps a, 7
	jr nz, SeqPart_PopReturn
	setda 4, 0x287b
	ld (0x287a:16), 0

SeqPart_MultiVoiceCalcDelta:
	ld xwa, (9690:16)
	stda32 9934, xwa
	ldmm16 0x287f, 9778
	ld l, (0x288d:16)
	ld a, (9780:16)
	ldb_erp A, 0xfb
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_MultiVoiceScanAlt
	cp a, 0x8
	jr nz, SeqPart_PopReturn

SeqData_ClearError:
	ld (0x287a:16), 0
	jrl SeqVoice_AdvanceReadLoop

SeqPart_PopReturn:
	jrl SeqPart_PopRetFA

SeqPart_MultiVoiceScanAlt:
	calr SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_MultiVoiceCompareDelta
	cps a, 7
	jrl nz, SeqPart_PopRetFA
	setda 3, 0x287b
	ld (0x287a:16), 0

SeqPart_MultiVoiceCompareDelta:
	ld xwa, (9934:16)
	ld xbc, (9690:16)
	cp xwa, xbc
	jr ule, SeqPart_MultiVoiceReverseCalc
	sub xwa, xbc
	stda32 9934, xwa
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_MultiVoiceStoreDelta
	bit 3, a
	jr nz, SeqPart_MultiVoiceStoreDelta
	ld xwa, (9934:16)
	dec 1, xwa
	stda32 9934, xwa

SeqPart_MultiVoiceStoreDelta:
	ld xwa, (9934:16)
	stda32 9690, xwa
	calr SeqPart_CalcTickRate
	ld wa, (9930:16)
	adddm16 9932, xwa
	jr SeqVoice_AdvanceReadLoop

SeqPart_MultiVoiceReverseCalc:
	cp xwa, xbc
	jr nc, SeqVoice_AdvanceReadLoop
	sub xbc, xwa
	stda32 9690, xbc
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_MultiVoiceCheckBounds
	bit 3, a
	jr nz, SeqPart_MultiVoiceCheckBounds
	ld xwa, (9690:16)
	inc 1, xwa
	stda32 9690, xwa

SeqPart_MultiVoiceCheckBounds:
	calr SeqPart_CalcPlaybackOffset
	ld wa, (9932:16)
	ld bc, (9930:16)
	cp wa, bc
	jr ugt, SeqPart_MultiVoiceSubtractRate
	ld (0x287a:16), 5
	jr SeqPart_PopRetFA

SeqPart_MultiVoiceSubtractRate:
	sub wa, bc
	ld (9932:16), wa

SeqVoice_AdvanceReadLoop:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpda8 a, 0x28a1
	jrl ule, SeqPart_MultiVoiceLoop

SeqPart_PopRetFA:
	popw_erp 0xfa
	ret

SeqPart_CountActiveVoices:
	push xiz
	cpda8_24 a, (0xffe3)
	jr nz, SeqCount_IncrementStart
	ldib_erp 0xfb, 0
	jr SeqCount_InitLoopRegs

SeqCount_IncrementStart:
	inc 1, a
	ldb_erp A, 0xfb

SeqCount_InitLoopRegs:
	lds iz, 0
	ldib_erp 0xfa, 1

SeqCount_VoiceLoop:
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	calr Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqCount_SkipInactiveVoice
	stb_erp A, 0xfb
	extz wa
	stb_erp C, 0xfa
	extz bc
	calr SeqVoice_CountChainLength
	add iz, hl

SeqCount_SkipInactiveVoice:
	inc1b_erp 0xfa
	cp_erpb 0xfa, 0x10
	jr ule, SeqCount_VoiceLoop
	cps iz, 0
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
	div xiz, xde
	cp iz, 0x64
	jr nz, SeqCount_CheckZeroPercent
	dec 1, iz
	jr SeqCount_StorePercentResult

SeqCount_CheckZeroPercent:
	cps iz, 0
	jr nz, SeqCount_StorePercentResult
	inc 1, iz

SeqCount_StorePercentResult:
	stb_erp A, 0xf8
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
	cps l, 0
	jr nz, SeqVoice_ChainStartCount

SeqVoice_ChainNoData:
	lds hl, 0
	jr SeqVoice_ChainReturn

SeqVoice_ChainStartCount:
	ldw (xsp + 2), 0x1
	cp iz, 0xffff
	jr z, SeqVoice_ChainStoreCount

SeqVoice_ChainFollowLoop:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
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
	ld xiy, WidgetData_DrawbarPositionTable_0x188
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
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqDataCopy_TransferLoop
	jr SeqDataCopy_RestoreStack

SeqDataCopy_CheckChannel:
	cpdm8_24 (0xffe3), a
	jr nz, SeqDataCopy_IncrementChannel
	ldb a, 0x0
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
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
	cp xbc, xhl
	jr c, SeqDataCopy_TransferLoop2

SeqDataCopy_RestoreStack:
	lda xsp, (xsp + 34)
	ret

SeqData_VoiceSetupBlock:
	.byte 0xd7
	swi	2
	.byte 0x04
	calr	141
	calr	63053
	ldb_erp l, 251
	cpib_erp 251, 0
	jr z, 123
	stb_erp a, 251
	ld	(0x2740:16), a
	stb_erp a, 251
	extz	wa
	ld	(0x287d:16), wa
	stb_erp a, 251
	extz	wa
	calr	62017
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	nz, 92
	.byte 0xd1
	jr	z, 38
	pop_f
	pop	xiz
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	pop	xix
	ldb	h, 209
	ldw	de, 6438
	jrl	nc, -14552
	swi	3
	.byte 0x8b
	extz	bc
	ld	wa, bc
	calr	62383
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	nz, 57
	ld	wa, (9778:16)
	addda16 xwa, (9694)
	ld	(0x287f:16), wa
	stb_erp c, 251
	extz	bc
	ld	wa, bc
	calr	62354
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	nz, 28
	calr	5858
	cp	l, 130
	jr	z, 20
	.byte 0xd1
	ldw	de, 6438
	.byte 0xda
	ldb	h, 209
	.byte 0xde
	ldb	e, 25
	.byte 0xdc
	.asciz "&@,'"
	nop
	calr	32
	calr	12134
	pop qiz
	ret

SeqBuf_ClearRange:
	lda xde, (0x2732:16)
	ld xwa, xde
	lda xbc, (0x272c:16)
	inc 6, xde

SeqBuf_ClearLoop:
	stib_dsp 0xe4, 0x00
	stib_dsp 0xe0, 0x00
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
	cp (0x287a:16), 0
	jrl nz, SeqVoice_WriteErrorAndReturn
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	ldw (xsp + 4), 0x0
	cpdi16 9948, 0
	jrl z, SeqVoice_WriteErrorAndReturn

SeqScan_OuterBarLoop:
	lds iz, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqScan_IncrementBarCount

SeqScan_InnerReadLoop:
	calr SeqPart_ReadByte_Secondary
	cp l, 0x81
	jr nz, SeqScan_CheckEndOrNote
	inc 1, iz
	calr PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqScan_ContinueInnerLoop
	jr SeqVoice_WriteErrorAndReturn

SeqScan_CheckEndOrNote:
	cp l, 0x82
	jr z, SeqVoice_WriteErrorAndReturn
	ld a, l
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqTrack_ProcessLoop
	cps iz, 0
	jr nz, SeqTrack_ProcessLoop
	ldib_erp 0xfb, 0

SeqScan_ProcessNoteParams:
	stb_erp C, 0xfb
	extz bc
	ld xwa, (xsp + 6)
	stb_dri L, 0x07, 0xe0, 0xe4
	calr PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
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
	cpda16 xwa, 9948
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
	stib_dsp 0xe4, 0x00
	cp xbc, xwa
	jr c, SeqScan_ClearNoteLoop
	ret

SeqValidate_PartAndTempoCombined:
	ld a, (0x2877:16)
	cp a, 0x11
	jr z, SeqValidate_CheckTempoValues
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqValidate_CombinedFail

SeqValidate_CheckTempoValues:
	ld wa, (9778:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqValidate_CombinedFail
	ld wa, (9694:16)
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, SeqValidate_CombinedOK

SeqValidate_CombinedFail:
	ldw hl, 0xffff
	ret

SeqValidate_CombinedOK:
	lds hl, 0
	ret

SeqVoice_CountEventsInBar:
	dec 8, xsp
	ld (xsp + 6), a
	calr SeqVoice_SetDefaultParams
	ld (0x287a:16), 0
	ld (0x288d:16), 0
	ld a, (xsp + 6)
	extz wa
	calr Part_ValidateVoiceChannel
	cp (0x287a:16), 0
	jr z, SeqCount_ValidateChannel
	ldw hl, 0xffff
	jr SeqCount_ReturnResult

SeqCount_ValidateChannel:
	calr SeqVoice_ValidateAndProcessState
	ldw (xsp + 2), 0x1
	ldw (xsp + 4), 0x0
	ldw (xsp), 0x0
	cpdi16 3299, 0
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
	ld (0x287a:16), 8
	jr SeqData_EOL_Cleanup

SeqCount_CheckBarMarker:
	cp l, 0x81
	jr nz, SeqCount_AdvanceAndCheck
	incw 1, (xsp)
	incw 1, (xsp + 4)

SeqCount_AdvanceAndCheck:
	calr SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqData_EOL_Cleanup
	ld wa, (xsp + 4)
	cpda16 xwa, 3299
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
	lds hl, 0
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
	cps bc, 5
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
	cps hl, 0
	jrl nz, SeqPlay_ErrorReturn
	lda xbc, (0x282c:16)
	ld l, (xsp + 36)
	dec 1, l
	ld e, l
	extz de
	add de, de
	lda xwa, (0x28ce:16)
	ldw_sri WA, 0x07, 0xe0, 0xe8
	ld (xbc), wa
	ldw (xbc + 2), 0x5
	ld c, l
	extz bc
	lda xhl, (0x290e:16)
	extz xbc
	add xbc, xhl
	ld a, (xbc)
	cps a, 5
	jr nz, SeqPlay_DecrementAltPos
	lda xwa, (0x28ee:16)
	ldw_sri WA, 0x07, 0xe0, 0xe8
	calr PartCtrl_ReadWord_Off1
	ld c, (xsp + 36)
	dec 1, c
	ld e, c
	extz de
	add de, de
	lda xwa, (0x28ee:16)
	stw_dri HL, 0x07, 0xe0, 0xe8
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
	ldw_sri WA, 0x07, 0xe0, 0xec
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
	cps hl, 0
	jr z, SeqPlay_ComputeOffsets

SeqPlay_ErrorReturn:
	ldw hl, 0xffff
	jrl SeqPlay_RestoreAndReturn

SeqPlay_ComputeOffsets:
	.byte 0xbf, 0x20, 0x36, 0x96, 0x20, 0xe8, 0x12, 0xbf
	.byte 0x04, 0x60, 0x41, 0xfb, 0x00, 0x00, 0x00, 0x1d
	.byte 0x7f, 0x02, 0xff, 0xbf, 0x04, 0x63, 0x9e, 0x02
	.byte 0x20, 0xe8, 0x12, 0xaf, 0x04, 0x88, 0xbf, 0x1c
	.byte 0x36, 0x96, 0x20, 0xe8, 0x12, 0xbf, 0x08, 0x60
	.byte 0x41, 0xfb, 0x00, 0x00, 0x00, 0x1d, 0x7f, 0x02
	.byte 0xff, 0xbf, 0x08, 0x63, 0x9e, 0x02, 0x20, 0xe8
	.byte 0x12, 0xaf, 0x08, 0x88, 0xf1, 0xce, 0x28, 0x32
	.byte 0xf1, 0x34, 0x28, 0x31, 0xf1, 0x30, 0x28, 0x30
	.byte 0xbf, 0x10, 0x60, 0xf1, 0xee, 0x28, 0x35, 0x8f
	.byte 0x24, 0x27, 0xcf, 0x69, 0xc7, 0xf8, 0x9f, 0xde
	.byte 0x12, 0xaf, 0x10, 0x20, 0xe8, 0x62, 0xbf, 0x14
	.byte 0x60, 0xb9, 0x02, 0x34, 0xde, 0x88, 0xd8, 0x80
	.byte 0xf3, 0x07, 0xe8, 0xe0, 0x32, 0xf3, 0x07, 0xf4
	.byte 0xe0, 0x35, 0xaf, 0x04, 0x20, 0xaf, 0x08, 0xf0
	.byte 0x73, 0xc7, 0x00, 0xf1, 0x2c, 0x28, 0x36, 0x92
	.byte 0x20, 0xb6, 0x50, 0xbe, 0x02, 0x02, 0x05, 0x00
	.byte 0x95, 0x20, 0xb1, 0x50, 0xdb, 0x12, 0xf1, 0x0e
	.byte 0x29, 0x30, 0xeb, 0x12, 0xe8, 0x83, 0x83, 0x21
	.byte 0xd8, 0x12, 0xb4, 0x50, 0xaf, 0x10, 0x20, 0xb0
	.byte 0x16, 0x52, 0x29, 0xc1, 0x54, 0x29, 0x23, 0xd9
	.byte 0x12, 0xaf, 0x14, 0x20, 0xb0, 0x51, 0x1e, 0x93
	.byte 0xf6, 0xf1, 0x30, 0x28, 0x32, 0xf1, 0x34, 0x28
	.byte 0x31, 0x91, 0x20, 0xb2, 0x50, 0x99, 0x02, 0x20
	.byte 0xba, 0x02, 0x50, 0xf1, 0x2c, 0x28, 0x31, 0xb1
	.byte 0x16, 0x55, 0x29, 0xc1, 0x57, 0x29, 0x21, 0xd8
	.byte 0x12, 0xb9, 0x02, 0x50, 0x8f, 0x24, 0x23, 0xd9
	.byte 0x12, 0xd8, 0xa8, 0x1e, 0xc9, 0x06, 0xf1, 0x34
	.byte 0x28, 0x53, 0x8f, 0x24, 0x23, 0xd9, 0x12, 0xd8
	.byte 0xa8, 0x1e, 0xe0, 0x06, 0xf1, 0x36, 0x28, 0x53
	.byte 0x1e, 0x51, 0xf6, 0xf1, 0x34, 0x28, 0x32, 0xba
	.byte 0x02, 0x31, 0x91, 0x20, 0xd8, 0xdd, 0x6e, 0x1f
	.byte 0x92, 0x20, 0x1e, 0x13, 0x0d, 0xbf, 0x16, 0x53
	.byte 0xd1, 0x34, 0x28, 0x20, 0x1e, 0x4c, 0x10, 0xf1
	.byte 0x34, 0x28, 0x31, 0x9f, 0x16, 0x20, 0xb1, 0x50
	.byte 0xb9, 0x02, 0x02, 0xff, 0x00, 0x68, 0x04
SeqPlay_DecrementBytePosAlt:
	dec 1, wa
	ld (xbc), wa

SeqPlay_WriteIndexedResults:
	ld c, (xsp + 36)
	extz bc
	ld de, (0x2834:16)
	lds wa, 0
	calr Part_WriteWord_Indexed
	ld c, (xsp + 36)
	extz bc
	ld de, (0x2836:16)
	lds wa, 0
	calr Part_WriteByte_Indexed
	jrl SeqPlay_ReturnOK

SeqPlay_HandleSmallerDelta:
	.byte 0xf1, 0x2c, 0x28, 0x30, 0xbf, 0x0c, 0x60, 0xe8
	.byte 0x62, 0xbf, 0x18, 0x60, 0xaf, 0x04, 0x20, 0xaf
	.byte 0x08, 0xf0, 0x7f, 0x92, 0x00, 0xaf, 0x08, 0xa8
	.byte 0xaf, 0x08, 0x20, 0x41, 0xfb, 0x00, 0x00, 0x00
	.byte 0x1d, 0x3b, 0x04, 0xff, 0xbf, 0x16, 0x53, 0xaf
	.byte 0x08, 0x20, 0x41, 0xfb, 0x00, 0x00, 0x00, 0x1d
	.byte 0x35, 0x04, 0xff, 0xaf, 0x0c, 0x20, 0xb0, 0x16
	.byte 0x55, 0x29, 0xc1, 0x57, 0x29, 0x23, 0xd9, 0x12
	.byte 0xaf, 0x18, 0x20, 0xb0, 0x51, 0x8f, 0x24, 0x21
	.byte 0xd8, 0x12, 0xdb, 0x12, 0x9f, 0x16, 0x21, 0xdb
	.byte 0x8a, 0x1d, 0xd2, 0xd0, 0xf3, 0xf1, 0x2c, 0x28
	.byte 0x32, 0x8f, 0x24, 0x27, 0xcf, 0x69, 0xcf, 0x8b
	.byte 0xd9, 0x12, 0xd9, 0x81, 0xf1, 0xce, 0x28, 0x30
	.byte 0xd3, 0x07, 0xe0, 0xe4, 0x20, 0xb2, 0x50, 0xba
	.byte 0x02, 0x02, 0x05, 0x00, 0xf1, 0x34, 0x28, 0x32
	.byte 0xf1, 0xee, 0x28, 0x30, 0xd3, 0x07, 0xe0, 0xe4
	.byte 0x20, 0xb2, 0x50, 0xdb, 0x12, 0xf1, 0x0e, 0x29
	.byte 0x30, 0xeb, 0x12, 0xe8, 0x83, 0x83, 0x21, 0xd8
	.byte 0x12, 0xba, 0x02, 0x50, 0xf1, 0x30, 0x28, 0x31
	.byte 0xb1, 0x16, 0x52, 0x29, 0xc1, 0x54, 0x29, 0x21
	.byte 0xd8, 0x12, 0xb9, 0x02, 0x50, 0x68, 0x28
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
	lds hl, 0

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
	ld (0x287a:16), 10
	jr SeqPart_StoredExit

SeqTick_StoreAndValidate:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, SeqTick_CheckRemaining
	ld (0x287a:16), 11
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
	stb_erp C, 0xfb
	extz bc
	ld xwa, (xsp + 2)
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	calr SeqPart_WriteByte_Secondary
	calr PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
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
	lds32 xwa, 6
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	lds32 xwa, 6
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 0x288b, 9940
	ldmm16 0x2889, 9938
	ld xwa, 0x272c
	jrl PartCtrl_ApplyChanges

SeqBufInit_DualTrackPath:
	ld xwa, 0xc
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
	jrl nz, SeqPart_AbortAndUpdateState
	ld wa, (9912:16)
	ldw_erp WA, 0xfa
	ld xwa, (9914:16)
	ld iz, wa
	dec 6, iz
	cps iz, 5
	jr nc, SeqBufInit_StorePageDirect
	stw_erp WA, 0xfa
	calr PartCtrl_ReadWord_Off1
	ld (9900:16), hl
	lds wa, 5
	sub wa, iz
	ldw iz, 0xff
	sub iz, wa
	jr SeqBufInit_StorePageOffset

SeqBufInit_StorePageDirect:
	stw_erp WA, 0xfa
	ld (9900:16), wa

SeqBufInit_StorePageOffset:
	ld (9902:16), iz
	stb_erp C, 0xf8
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
	cpda16 xwa, 9952
	jr ule, SeqBufInit_ChooseForwardDir
	ldmw2 (xde), 0x26d4
	ldmw2 (xbc), 0x26d2
	jr SeqBufInit_CopyAndProcess

SeqBufInit_ChooseForwardDir:
	ldmw2 (xde), 0x26d8
	ldmw2 (xbc), 0x26d6

SeqBufInit_CopyAndProcess:
	calr SeqPart_CopyDataSecondary
	cp (0x287a:16), 0
	jrl nz, SeqBufInit_PopReturn
	ld wa, (9950:16)
	cpda16 xwa, 9952
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
	lds wa, 0
	calr Part_ReadByte_Indexed
	ld (0x282e:16), hl
	ld c, (0x2740:16)
	extz bc
	lds wa, 0
	calr Part_ReadWord_Indexed
	ld (0x282c:16), hl
	lda xde, (0x2830:16)
	stw_erp WA, 0xfa
	ld (xde), wa
	ld xwa, (9914:16)
	ld (xde + 2), wa
	ld c, a
	extz bc
	ld wa, (xde)
	calr Part_WriteWordAndByte
	ld wa, (9950:16)
	cpda16 xwa, 9952
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
	cp (0x287a:16), 0
	jr nz, SeqPart_AbortAndUpdateState
	ld wa, (9950:16)
	cpda16 xwa, 9952
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
	ld (0x287a:16), 10
	jr PartFind_Return

PartFind_StoreAndValidate:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, PartFind_CheckRemaining
	ld (0x287a:16), 11
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, SeqData_SkipEventParams
	ldw wa, 0xd3

SeqSkip_SetErrorCode:
	calr SeqData_SetErrorCode
	ret

SeqData_CopyBlockToBuffer:
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xde, (0x0ab000:24)
	add xde, xwa
	ld xiy, 0xf180
	ld xix, xde
	ldw bc, 0x400
	ldirw
	ret

VoicePreset_LoadAndInitPan:
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xbc, (0x0ab000:24)
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
	stb_erp A, 0xfb
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
	lds de, 1
	and a, 0xf
	jr z, Chan_ShiftComplete
	slaa de

Chan_ShiftComplete:
	cps c, 0
	jr z, Chan_ClearBit
	orddm16 0xf19e, xde
	jr Chan_CheckSubsystem

Chan_ClearBit:
	cpl de
	anddm16 0xf19e, xde

Chan_CheckSubsystem:
	jp	16635550
SeqVoice_SetOrClearBitMask:
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, SeqVoiceBit_ShiftComplete
	slaa de

SeqVoiceBit_ShiftComplete:
	cps c, 0
	jr z, SeqVoiceBit_ClearBit
	orddm16 0x28a8, xde
	jr SeqVoiceBit_CheckSubsystem

SeqVoiceBit_ClearBit:
	cpl de
	anddm16 0x28a8, xde

SeqVoiceBit_CheckSubsystem:
	jp	16635550
Part_CopyBlock16:
	cps a, 0
	jr nz, PartCopy16_ComputeAddr
	lda xhl, (0xf280:16)
	jr PartCopy16_TransferLoop

PartCopy16_ComputeAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda_dri XWA, 0xe1, 0x00, 0x01
	lda xhl, (0x0ab000:24)
	add xhl, xwa

PartCopy16_TransferLoop:
	ld xde, xbc
	lda xbc, (xbc + 16)

PartCopy16_CopyWord:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xec
	cp xde, xbc
	jr c, PartCopy16_CopyWord
	ret

Part_CopyToBuffer:
	cps a, 0
	jr nz, PartCopyBuf_ComputeSrcAddr
	lda xde, (0xf460:16)
	jr PartCopyBuf_SetupDst

PartCopyBuf_ComputeSrcAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda_dri XWA, 0xe1, 0xe0, 0x02
	lda xde, (0x0ab000:24)
	add xde, xwa

PartCopyBuf_SetupDst:
	cps c, 0
	jr nz, PartCopyBuf_ComputeDstAddr
	lda xbc, (0xf460:16)
	jr PartCopyBuf_InitCounter

PartCopyBuf_ComputeDstAddr:
	dec 1, c
	ldb b, 0x0
	extz xbc
	sll xbc, 11
	lda_dri XWA, 0xe5, 0xe0, 0x02
	lda xbc, (0x0ab000:24)
	add xbc, xwa

PartCopyBuf_InitCounter:
	lds hl, 0

PartCopyBuf_TransferLoop:
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xe4
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
	cps a, 0
	jr nz, Part_WriteByte_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_WriteByte_DoWrite

Part_WriteByte_ComputeAddr:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda xbc, (0x0ab000:24)
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
	cps a, 0
	jr nz, Part_WriteWord_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_WriteWord_DoWrite

Part_WriteWord_ComputeAddr:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, 0xab000
	add xbc, xwa

Part_WriteWord_DoWrite:
	ld (xbc), de
	ret

Part_ReadByteDirect:
	cps a, 0
	jr nz, Part_ReadByteDirect_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_ReadByteDirect_DoRead

Part_ReadByteDirect_ComputeAddr:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda xbc, (0x0ab000:24)
	add xbc, xwa

Part_ReadByteDirect_DoRead:
	ld l, (xbc)
	ret

Part_ReadWord:
	cps a, 0
	jr nz, Part_ReadWord_ComputeAddr
	lda xwa, (0xf180:16)
	extz xbc
	add xbc, xwa
	jr Part_ReadWord_DoRead

Part_ReadWord_ComputeAddr:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, 0xab000
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
	stb_erp A, 0xfb
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
	lds wa, 0
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
	stb_erp A, 0xfb
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
	lds hl, 0

PartIncrPos_Return:
	pop xiz
	ret

Part_DecrementVoicePos:
	push xiz
	lds wa, 0
	ldw bc, 0xb1
	calr Part_ReadWord
	ld iz, hl
	cps iz, 0
	jr nz, PartDecrPos_StartDecrement
	ldw hl, 0xffff
	jr PartDecrPos_Return

PartDecrPos_StartDecrement:
	dec 1, iz
	ldib_erp 0xfb, 0

PartDecrPos_WriteLoop:
	stb_erp A, 0xfb
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
	lds hl, 0

PartDecrPos_Return:
	pop xiz
	ret

Part_WriteSubBlock32:
	cps a, 0
	jr nz, PartSubBlk_ComputeAddr
	lda xhl, (0xf1a0:16)
	jr PartSubBlk_WriteAndCheck

PartSubBlk_ComputeAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda xhl, (0x0ab000:24)
	add xhl, xwa

PartSubBlk_WriteAndCheck:
	extz	bc
	lda_rr	xwa, xhl, bc
	ld	(xwa-1), e
	jp	16635550
Part_ReadSubBlock32:
	cps a, 0
	jr nz, PartSubBlkRd_ComputeAddr
	lda xde, (0xf1a0:16)
	jr PartSubBlkRd_ReadAndReturn

PartSubBlkRd_ComputeAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda xde, (0x0ab000:24)
	add xde, xwa

PartSubBlkRd_ReadAndReturn:
	extz bc
	lda_dri XWA, 0x07, 0xe8, 0xe4
	ld l, (xwa - 1)
	ret

Part_WriteSubBlock48:
	cps a, 0
	jr nz, PartSubBlk48_ComputeAddr
	lda xhl, (0xf1b0:16)
	jr PartSubBlk48_WriteAndCheck

PartSubBlk48_ComputeAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 48)
	lda xhl, (0x0ab000:24)
	add xhl, xwa

PartSubBlk48_WriteAndCheck:
	extz	bc
	lda_rr	xwa, xhl, bc
	ld	(xwa-1), e
	jp	16635550
Part_VoiceSearchBlock:
	cps	a, 0
	jr	nz, 6
	lda	xde, (0xf1b0:16)
	jr	19
	dec	1, a
	ldb	w, 0
	extz	xwa
	sll	xwa, 11
	lda	xwa, (xwa+48)
	lda	xde, (0x0ab000:24)
	add	xde, xwa
	extz	bc
	.byte 0xf3
	reti
	or	xix, xwa
	ldw	wa, 0xff88
	ldb	l, 14

Part_FindVoiceByByte:
	dec 4, xsp
	pushw_erp 0xfa
	ld (xsp + 2), c
	ld (xsp + 4), a
	ldib_erp 0xfb, 1

PartFind_VoiceSearchLoop:
	ld a, (xsp + 4)
	extz wa
	stb_erp C, 0xfb
	extz bc
	calr Part_ReadSubBlock32
	cp l, (xsp + 2)
	jr nz, PartFind_VoiceSearchNext
	stb_erp L, 0xfb
	jr PartFind_VoiceSearchReturn

PartFind_VoiceSearchNext:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartFind_VoiceSearchLoop
	ldb l, 0xff

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
	lds bc, 0
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 2
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 3
	ldw de, 0x5a
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 4
	lds de, 0
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 5
	lds de, 1
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 6
	ldw de, 0x8
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 7
	lds de, 0
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
	lds de, 0
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
	lds iz, 0

PartInit_WriteZeroLoop:
	ld a, (xsp + 2)
	extz wa
	ld bc, iz
	add bc, 0x42
	lds de, 0
	calr Part_WriteByte
	inc 1, iz
	cp iz, 0xc
	jr c, PartInit_WriteZeroLoop
	calr SeqStatus_CheckBit2
	ld a, (xsp + 2)
	extz wa
	cps l, 0
	jr nz, PartInit_SetBDFF
	ldw bc, 0xbd
	lds de, 0
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
	stb_erp C, 0xfb
	extz bc
	stb_erp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (WidgetData_DrawbarPositionTable_0xD2:24)
	ldb_sri E, 0x07, 0xec, 0xe8
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkA_WriteLoop32
	ldib_erp 0xfb, 1

PartSubBlkA_WriteLoop48:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	stb_erp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (WidgetData_DrawbarPositionTable_0xF2:24)
	ldb_sri E, 0x07, 0xec, 0xe8
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
	stb_erp C, 0xfb
	extz bc
	stb_erp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (WidgetData_DrawbarPositionTable_0xE2:24)
	ldb_sri E, 0x07, 0xec, 0xe8
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, PartSubBlkB_WriteLoop32
	ldib_erp 0xfb, 1

PartSubBlkB_WriteLoop48:
	ld a, (xsp + 2)
	extz wa
	stb_erp C, 0xfb
	extz bc
	stb_erp E, 0xfb
	dec 1, e
	extz de
	lda xhl, (WidgetData_DrawbarPositionTable_0xF2:24)
	ldb_sri E, 0x07, 0xec, 0xe8
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
	stiw_da (0x00ffec), 0x0000
	ldib_erp 0xfb, 1

SeqPart_ResetPosLoop:
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1e
	lds de, 0
	calr Part_WriteWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0a
	jr ule, SeqPart_ResetPosLoop
	jr SeqPart_ResetPosReturn

SeqPart_ResetPosSingle:
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	ldw bc, 0x1e
	lds de, 0
	calr Part_WriteWord

SeqPart_ResetPosReturn:
	popw_erp 0xfa
	ret

SeqData_CopyBlock2K:
	cps a, 0
	jr nz, SeqCopy2K_ComputeAddr
	lda xhl, (0xf280:16)
	jr SeqCopy2K_SetupTransfer

SeqCopy2K_ComputeAddr:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda_dri XWA, 0xe1, 0x00, 0x01
	lda xhl, (0x0ab000:24)
	add xhl, xwa

SeqCopy2K_SetupTransfer:
	ld xde, xbc
	lda xbc, (xbc + 16)

SeqCopy2K_TransferLoop:
	ldb_spi A, 0xec
	lda_dpi XBC, 0xe8
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
	lds hl, 1
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
	stb_dri C, 0x07, 0xe0, 0xec
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
	cps wa, 0
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
	ldw_erp HL, 0xfa
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
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartCopyVoice_UpdateChain
	stw_erp WA, 0xfa
	lds bc, 0
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
	lds bc, 1
	calr PartCtrl_SetClearBit7
	ld xwa, (xsp + 12)
	ld (xwa), iz
	calr Part_DecrementVoicePos
	jr PartCopyVoice_RecomputeAddr

PartCopyVoice_StoreNewPage:
	ld xwa, (xsp + 12)
	stw_erp BC, 0xfa
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
	lds hl, 0

PartCopyVoice_Return:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PartCtrl_InitChainLinkedList:
	pushw iz
	lds wa, 1
	calr Part_WriteWordBlock_OffsetAF
	ldw wa, 0x4d8
	calr Part_SetAllVoicePos
	lds iz, 1

PartChain_InitLoop:
	ld wa, iz
	lds bc, 0
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
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	inc 1, iz
	cp iz, 0x4d8
	jr ule, PartChain_InitLoop
	lds wa, 1
	lds bc, 0
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
	cps c, 0
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
	lda_dri XWA, 0x07, 0xe0, 0xe4
	lda xbc, (0x0b0000:24)
	add xbc, xwa
	ld l, (xbc)
	ret

PartCtrl_WriteByteToBuf:
	extz bc
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda_dri XWA, 0x07, 0xe0, 0xe4
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
	cps	hl, 5
	jr	z, 6
	dec	1, hl
	ld	(xde), hl
	jr	21
	ld	wa, (xiz)
	calr	65321
	cps	hl, 0
	jr	nz, 5
	ldw	hl, 0xffff
	jr	9
	ld	(xiz), hl
	ldw (xiz+2), 5
	lds	hl, 0
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
	cps	hl, 5
	jr	z, 6
	dec	1, hl
	ld	(xde), hl
	jr	21
	ld	wa, (xiz)
	calr	65252
	cps	hl, 0
	jr	nz, 5
	ldw	hl, 0xffff
	jr	9
	ld	(xiz), hl
	ldw (xiz+2), 5
	lds	hl, 0
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
	lds hl, 0

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
	ld wa, (xsp + 256)
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

PartCtrl_DeallocAndWrite_WriteByte:
	ld wa, (xsp + 256)
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	inc 4, xsp
	ret

Part_DeallocVoices1And2:
	lds wa, 1
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, Part_DeallocVoices_Voice2
	calr Part_StealAndReallocVoices
	lds wa, 1
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_DeallocVoices_Voice2:
	lds wa, 1
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	lds wa, 2
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xffff
	jr z, Part_DeallocVoices_Voice2Write
	calr Part_StealAndReallocVoices
	lds wa, 2
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_DeallocVoices_Voice2Write:
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	jrl PartCtrl_WriteByteToBuf

Part_UnlinkVoiceFromChain:
	push xiz
	lds wa, 1
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, Part_UnlinkVoice_CheckVoice2
	lds wa, 1
	lds bc, 1
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	lds wa, 1
	calr PartCtrl_ReadWord_Off1
	ldw_erp HL, 0xfa
	lds wa, 1
	calr PartCtrl_ReadWord
	ld iz, hl
	cpiw_erp 0xfa, 0
	jr nz, Part_UnlinkVoice1_HasNext
	cp iz, 0xffff
	jr z, Part_UnlinkVoice1_Clear
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	lds bc, 0
	jr Part_UnlinkVoice1_WriteOff1

Part_UnlinkVoice1_HasNext:
	cp iz, 0xffff
	jr nz, Part_UnlinkVoice1_LinkPrevNext
	stw_erp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	jr Part_UnlinkVoice1_Clear

Part_UnlinkVoice1_LinkPrevNext:
	stw_erp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	stw_erp BC, 0xfa

Part_UnlinkVoice1_WriteOff1:
	calr PartCtrl_WriteWord_Off1

Part_UnlinkVoice1_Clear:
	lds wa, 1
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

Part_UnlinkVoice_CheckVoice2:
	lds wa, 2
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, SeqStatus_ClearBit2
	lds wa, 2
	lds bc, 1
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	lds wa, 2
	calr PartCtrl_ReadWord_Off1
	ldw_erp HL, 0xfa
	lds wa, 2
	calr PartCtrl_ReadWord
	ld iz, hl
	cpiw_erp 0xfa, 0
	jr nz, Part_UnlinkVoice2_HasNext
	cp iz, 0xffff
	jr z, SeqStatus_WriteByte
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	lds bc, 0
	jr SeqStatus_SetBit2

Part_UnlinkVoice2_HasNext:
	cp iz, 0xffff
	jr nz, SeqStatus_ClearBitAndSet
	stw_erp WA, 0xfa
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	jr SeqStatus_WriteByte

SeqStatus_ClearBitAndSet:
	stw_erp WA, 0xfa
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	stw_erp BC, 0xfa

SeqStatus_SetBit2:
	calr PartCtrl_WriteWord_Off1

SeqStatus_WriteByte:
	lds wa, 2
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 2
	ldw bc, 0xffff
	calr PartCtrl_WriteWord

SeqStatus_ClearBit2:
	pop xiz
	ret

Part_ClearAllVoiceChannels:
	pushw_erp 0xfa
	calr PartCtrl_InitChainLinkedList
	stiw_da (0x00ffec), 0x0000
	calr Part_UnlinkVoiceFromChain
	ldib_erp 0xfa, 0

SeqStatus_ReadBit2Check:
	ldib_erp 0xfb, 1

SeqStatus_ReadReturn:
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	extz bc
	ldw de, 0xffff
	calr Part_WriteVoiceWord
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	addb_erp C, 0xfb
	add c, 0x76
	extz bc
	ldw de, 0xffff
	calr Part_WriteWord
	stb_erp A, 0xfa
	extz wa
	stb_erp C, 0xfb
	add c, 0x97
	extz bc
	lds de, 5
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
	cps l, 0
	jr nz, SeqMode_SetActiveState
	ldw wa, 0x28
	calr SeqData_SetErrorCode
	jr SeqMode_ReturnState

SeqMode_SetActiveState:
	ld wa, iz
	lds bc, 0
	calr PartCtrl_SetClearBit7
	ld wa, iz
	calr PartCtrl_ReadWord
	ldw_erp HL, 0xfa
	ld wa, iz
	calr PartCtrl_AppendToFreeList
	stw_erp IZ, 0xfa
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
	lds bc, 0
	calr PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	calr Part_IncrementVoicePos
	ld wa, iz
	lds bc, 5
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
	lds bc, 1
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
	ldw_erp HL, 0xfa
	stw_erp WA, 0xfa
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xfa, 0xff, 0xff
	jr z, SeqPlay_BeginPlayback
	stw_erp WA, 0xfa
	lds bc, 0
	calr PartCtrl_WriteWord_Off1

SeqPlay_BeginPlayback:
	ld wa, iz
	lds bc, 1
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
	ldb l, 0x1

MIDI_NullRet:
	ret

MIDI_Status_6:
	ldb l, 0x6
	jr MIDI_NullRet

SeqPlay_StopAndReset:
	ldb l, 0x2
	jr MIDI_NullRet

MIDI_Status_3:
	ldb l, 0x3
	jr MIDI_NullRet

SeqPlay_ResetState:
	ldb l, 0x4
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
	lds	wa, 0
	calr	63212
	ld	(0x28af:16), hl
	cp	hl, 0xffff
	jr	nz, 5
	ldw	hl, 0xffff
	jr	74
	ldw	(9830:16), 5
	cps	iz, 0
	jr	ule, 44
	calr	145
	cp	l, 129
	jr	nz, 8
	inc1b_erp 251
	calr 166
	jr	19
	cp	l, 130
	jr	z, 23
	extz	hl
	ld	wa, hl
	calr	65347
	extz	hl
	ld	wa, hl
	calr	65414
	stb_erp a, 251
	extz	wa
	cp	wa, iz
	jr	c, -44
	ld	xde, (xsp+4)
	.byte 0xb2
	ex_ff
	.byte 0xaf
	pushw	wa
	ld	wa, (9830:16)
	ld	c, a
	extz	bc
	ld	(xde+2), bc
	lds	hl, 0
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
	stb_erp A, 0xfb
	cpda8 a, 8972
	jr c, SeqMIDI_ProcessEventByte

SeqMIDI_ProcessReturn:
	popw_erp 0xfa
	ret

SeqData_SeekToPartStart:
	ld c, (9696:16)
	inc 1, c
	extz bc
	lds wa, 0
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
	lds bc, 5
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
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, SeqMIDI_WriteDataByte
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_BufferFullReturn
	slaa bc

SeqMIDI_BufferFullReturn:
	jr SeqMIDI_FlushBuffer

SeqMIDI_WriteDataByte:
	ld a, (9696:16)
	lds bc, 1
	and a, 0xf
	jr z, SeqMIDI_DataWriteReturn
	slaa bc

SeqMIDI_DataWriteReturn:
	ld wa, bc
	andda16 xwa, 0x28a8
	jr z, SeqScan_PartEntry
	bit 1, (0x28b1:16)
	jr nz, SeqScan_PartEntry
	bit 0, (0x28c5:16)
	jr nz, SeqScan_PartEntry

SeqMIDI_FlushBuffer:
	cpl bc
	anddm16 8982, xbc
	jrl SeqScan_AdvancePartIndex

SeqScan_PartEntry:
	orddm16 8982, xbc
	ldw (9614:16), 0
	calr SeqData_SeekToPartStart
	ld a, (9696:16)
	inc 1, a
	cpda8 a, 8988
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
	cps a, 6
	jr nz, SeqMIDI_ReadFromBuffer
	bitm 2, (xbc)
	jr z, SeqPart_ScanControlChanges
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	setda 1, 8974
	ldw (4360:16), 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqMIDI_ReadBufferCheck

SeqMIDI_ReadFromBuffer:
	cps a, 5
	jr nz, SeqPart_ScanControlChanges
	ld a, (xbc)
	bit 2, a
	jr z, SeqMIDI_ReadBufferLoop
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	setda 1, 8974
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
	setda 1, 8974
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
	cpda8 a, 8990
	jr nz, SeqMIDI_DispatchEventType
	lda xwa, (7594:16)
	ldmw2 (xwa), 0x28af
	ldmw2 (xwa + 2), 0x2666

SeqMIDI_DispatchEventType:
	cpdm16 9614, xiz
	jrl nc, SeqScan_CheckPartActiveAndStore

SeqMIDI_DispatchProgramChange:
	calr SeqData_ReadNextByte
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x81
	jr nz, SeqMIDI_DispatchReturn
	incdi16 1, (9614)
	calr PartCtrl_RefreshWordPeriodic
	jrl SeqData_ContinuePos

SeqMIDI_DispatchReturn:
	cp_erpb 0xfb, 0x82
	jr nz, SeqMIDI_NoteWithVelocity
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_ProcessControlChange
	slaa bc

SeqMIDI_ProcessControlChange:
	.byte 0xd9, 0x06, 0xd9, 0x88, 0xd1, 0x16, 0x23, 0x21
	.byte 0xd8, 0xc1, 0xf1, 0x16, 0x23, 0x51, 0xd1, 0xa8
	.byte 0x28, 0x3f, 0x00, 0x00, 0x76, 0xfa, 0x00, 0xf1
	.byte 0xb1, 0x28, 0xc9, 0x76, 0xf3, 0x00, 0xc1, 0x98
	.byte 0x8c, 0x3f, 0x0b, 0x7e, 0xeb, 0x00, 0xc1, 0xe0
	.byte 0x25, 0x25, 0xcd, 0x89, 0xc9, 0x61, 0xc1, 0x1a
	.byte 0x23, 0xf1, 0x7e, 0xdc, 0x00, 0xdb, 0xa9, 0xcd
	.byte 0x89, 0xc9, 0xcc, 0x0f, 0x66, 0x02, 0xdb, 0xfc
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
	cpda8 a, 8988
	jr nz, SeqData_ContinuePos
	calr SeqData_SkipToCurrentBar
	jr SeqData_ContinuePos

SeqMIDI_NoteEventReturn:
	stb_erp A, 0xfb
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqData_ContinuePos:
	cpdm16 9614, xiz
	jrl c, SeqMIDI_DispatchProgramChange
	jrl SeqScan_CheckPartActiveAndStore

SeqMIDI_HandlePitchBend:
	calr SeqData_ReadNextByte
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x81
	jrl z, SeqScan_StoreTrackEndData
	cp_erpb 0xfb, 0x82
	jr nz, SeqMIDI_SysExReadLoop
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_PitchBendReturn
	slaa bc

SeqMIDI_PitchBendReturn:
	.byte 0xd9, 0x06, 0xd9, 0x88, 0xd1, 0x16, 0x23, 0x21
	.byte 0xd8, 0xc1, 0xf1, 0x16, 0x23, 0x51, 0xd1, 0xa8
	.byte 0x28, 0x3f, 0x00, 0x00, 0x66, 0x73, 0xf1, 0xb1
	.byte 0x28, 0xc9, 0x66, 0x6d, 0xc1, 0x98, 0x8c, 0x3f
	.byte 0x0b, 0x6e, 0x66, 0xc1, 0xe0, 0x25, 0x25, 0xcd
	.byte 0x89, 0xc9, 0x61, 0xc1, 0x1a, 0x23, 0xf1, 0x6e
	.byte 0x58, 0xdb, 0xa9, 0xcd, 0x89, 0xc9, 0xcc, 0x0f
	.byte 0x66, 0x02, 0xdb, 0xfc
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
	cpda8 a, 8988
	jr nz, SeqScan_CheckPartActiveAndStore
	calr SeqData_SkipToCurrentBar
	jr SeqScan_CheckPartActiveAndStore

SeqMIDI_SysExReturn:
	calr SeqMIDI_BufferWriteSetup
	cp l, (xsp + 16)
	jr nc, SeqScan_StoreTrackEndData
	stb_erp A, 0xfb
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqScan_CheckPartActiveAndStore:
	lds bc, 1
	ld a, (9696:16)
	and a, 0xf
	jr z, SeqMIDI_HandleChannelPressure
	slaa bc

SeqMIDI_HandleChannelPressure:
	andda16 xbc, 8982
	jrl nz, SeqMIDI_HandlePitchBend

SeqScan_StoreTrackEndData:
	ld c, (9696:16)
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqMIDI_ChannelPressureReturn
	slaa de

SeqMIDI_ChannelPressureReturn:
	andda16 xde, 8982
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
	ldb_erp A, 0xf0
	lds bc, 1
	stb_erp A, 0xf0
	and a, 0xf
	jr z, SeqMIDI_GetEventSizeLookup
	slaa bc

SeqMIDI_GetEventSizeLookup:
	ld wa, bc
	andda16 xwa, 8982
	lda xde, (xsp + 4)
	lda xhl, (9184:16)
	lda xbc, (xde + 2)
	cps wa, 0
	jrl z, SeqMIDI_ChannelOutOfRange
	stb_erp A, 0xf0
	extz wa
	ld iy, wa
	sla iy, 3
	lda xix, (9016:16)
	ld wa, (xsp + 8)
	stw_dri WA, 0x07, 0xf0, 0xf4
	ld a, (9696:16)
	inc 1, a
	ldb_erp A, 0xe2
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	lda_dri XIZ, 0x07, 0xec, 0xe0
	lda xiy, (xiz + 2)
	stb_erp A, 0xe2
	cpda8 a, 8988
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
	stw_dri WA, 0xf1, 0x98, 0x00
	ldw wa, 0x14
	jr SeqMIDI_ChannelInRange

SeqMIDI_ValidateChannel:
	stb_erp A, 0xe2
	cpda8 a, 8996
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
	stw_dri WA, 0xf1, 0xa0, 0x00
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
	ld (0x287a:16), 10
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
	.byte 0xbf
	ldwio	22, 0xf22f
	ld	(0xf22f:16), iz
	.byte 0xbf, 0x04
	push	sr
	nop
	nop
	ld	wa, iz
	calr	62994
	ld	(xsp+6), hl
	ld	wa, iz
	lds	bc, 0
	calr	63003
	ld	wa, iz
	calr	63017
	ld qiz, hl
	cpw qiz, 65535
	jr	nz, 70
	ld	(xsp+8), iz
	incw	1, (xsp+4)
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 9
	ld	wa, (xsp+6)
	ld	bc, qiz
	calr	63004
	ld	wa, (xsp+8)
	lds	bc, 0
	calr	63035
	ld	wa, (xsp+8)
	lds	bc, 5
	ldw	de, 130
	calr	63072
	ld	wa, (xsp+8)
	ld	bc, (xsp+10)
	calr	62976
	ld	wa, (xsp+10)
	ld	bc, (xsp+8)
	calr	62929
	ld	wa, (xsp+4)
	adddm16 (62001), xwa
	pop	xiz
	inc	8, xsp
	ret
	ld	wa, iz
	lds	bc, 0
	calr	62988
	ld	wa, iz
	lds	bc, 5
	ldw	de, 130
	calr	63026
	incw	1, (xsp+4)
	ld	wa, (xsp+4)
	.byte 0x9f
	ldio	240, 110
	ex_ff
	ld	(xsp+8), iz
	ld	wa, iz
	calr	62901
	ld qiz, hl
	ld wa, qiz
	ld	bc, (xsp+6)
	calr	62870
	jr	-114
	ld iz, qiz
	jrl	-141

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
	ldw_erp HL, 0xfa
	ld wa, iz
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	calr PartCtrl_WriteWord
	ld wa, iz
	lds bc, 1
	calr PartCtrl_SetClearBit7
	stw_erp WA, 0xfa
	ld (0xf22f:16), wa
	cp_erpw 0xfa, 0xff, 0xff
	jr z, PartCtrlRd_DecrementCount
	stw_erp WA, 0xfa
	lds bc, 0
	calr PartCtrl_WriteWord_Off1

PartCtrlRd_DecrementCount:
	decdi16 1, 0xf231
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
	lds	wa, 0
	calr	61334
	ldb_erp	l, 251
	lda	xbc, (xsp+4)
	ld	wa, iz
	ld	xde, (xsp+6)
	calr	264
	ld	a, (xsp+10)
	extz	wa
	cp_erpb	251, 13
	jr	z, 17
	cp_erpb	251, 16
	jr	nz, 73
	calr	1453
	ld	iz, hl
	cps	iz, 0
	.ascii "n3h>"
	calr	1442
	ld	iz, hl
	cps	iz, 0
	jr	z, 53
	cp	(xsp+4), iz
	jr	c, 48
	ld	a, (xsp+10)
	extz	wa
	calr	1538
	cps	hl, 0
	jr	z, 23
	ld	bc, iz
	sub	bc, hl
	ld	wa, (xsp+4)
	sub	wa, hl
	extz	xwa
	div	xwa, xbc
	ld	wa, qwa
	add	wa, hl
	ld	(xsp+4), wa
	jr	13
	ld	wa, (xsp+4)
	extz	xwa
	div	xwa, xiz
	ld	wa, qwa
	ld	(xsp+4), wa
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
	cps l, 0
	jr z, Rhythm_SetupFail
	calr Rhythm_ClearHighBitFlag
	cpdi16 0xf19e, 0
	jr z, Rhythm_SetupFail
	bit 2, (1057:16)
	jr z, Rhythm_SetupComputeState

Rhythm_SetupFail:
	ldb l, 0xff
	jr Rhythm_SetupReturn

Rhythm_SetupComputeState:
	calr Rhythm_ComputeNoteIndex
	ld iz, hl
	srl iz, 2
	and hl, 0x3
	ldb_erp L, 0xfb
	lda xbc, (xsp + 8)
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	ld wa, iz
	calr Rhythm_ExtendedNoteAlloc
	ld (1052:16), iz
	stb_erp A, 0xfb
	mul a, 0x18
	ld (1051:16), a
	mrdb5 0x8f, 0x04, 0x19, 0x32, 0x23
	call SeqMode_SendStatusUpdate
	mrdw5 0x9f, 0x08, 0x19, 0x68, 0x26
	call NoteEditSy_SendModeScrollReset
	ld c, (xsp + 6)
	extz bc
	ld wa, iz
	sub wa, bc
	ld (9008:16), wa
	ldb l, 0x0

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
	resda 7, 1070
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
	ld xiy, WidgetData_DrawbarPositionTable_0x198
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, WidgetData_DrawbarPositionTable_0x19C
	lda xix, (xsp + 6)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr nz, Rhythm_AllocMultiVoice
	calr SeqPart_DispatchRhythmNote
	ld xwa, (xsp + 14)
	ld (xwa), l
	ld bc, (xsp + 22)
	dec 1, bc
	ld a, (xwa)
	extz wa
	mul xwa, xbc
	ld bc, wa
	ld xwa, (xsp + 18)
	ld (xwa), bc
	jrl Rhythm_AllocReturn

Rhythm_AllocMultiVoice:
	calr SeqPart_DispatchRhythmNote
	ldb_erp L, 0xfa
	lds iz, 1
	ldw (xsp + 4), 0x0
	ld xwa, (xsp + 18)
	ldw (xwa), 0x0
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
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
	stb_erp C, 0xfa
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
	mul xwa, xbc
	ld bc, wa
	add (xhl), bc
	ld iz, (xsp + 22)
	ldib_erp 0xfb, 0
	jr SeqPart_NoteProcessing_Loop

Rhythm_AllocResetMarker:
	calr SeqPart_DispatchRhythmNote
	ldb_erp L, 0xfa
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr SeqPart_NoteProcessing_Loop

Rhythm_AllocStoreAndCont:
	ldb_erp L, 0xfa

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
	stb_erp C, 0xfa
	ld (xwa), c

Rhythm_AllocReturn:
	pop xiz
	lda xsp, (xsp + 20)
	ret

Rhythm_AllocResetAlt:
	calr SeqPart_DispatchRhythmNote
	ldb_erp L, 0xfa
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr Rhythm_AllocCheckFlag

Rhythm_AllocStoreAlt:
	ldb_erp L, 0xfa

Rhythm_AllocClearFlag:
	ldib_erp 0xfb, 0
	jr Rhythm_AllocStoreResult

Rhythm_ExtendedNoteAlloc:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld (xsp + 24), wa
	ld xiy, WidgetData_DrawbarPositionTable_0x1A0
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, WidgetData_DrawbarPositionTable_0x1A4
	lda xix, (xsp + 8)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldb_erp L, 0xfa
	cpib_erp 0xfa, 0
	jr nz, Rhythm_ExtAllocMultiVoice
	calr SeqPart_DispatchRhythmNote
	ld xde, (xsp + 30)
	ld (xde), l
	ld c, (xde)
	extz bc
	ld wa, (xsp + 24)
	extz xwa
	div xwa, xbc
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
	ldb_erp L, 0xfb
	ldw (xsp + 4), 0x1
	ldw (xsp + 6), 0x0
	ldib_erp 0xf9, 0
	ld xwa, (xsp + 20)
	ldw (xwa), 0x1
	stb_erp C, 0xfa
	extz bc
	lds wa, 0
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
	stb_erp A, 0xf9
	cpb_erp A, 0xfb
	jr c, Rhythm_NoteAllocation_Finalize
	incw 1, (xsp + 4)
	ldib_erp 0xf9, 0
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocEndSection:
	stb_erp A, 0xfb
	subb_erp A, 0xf9
	extz wa
	add (xsp + 6), wa
	incw 1, (xsp + 4)
	stb_erp C, 0xfb
	extz bc
	ld de, (xsp + 24)
	sub de, (xsp + 6)
	ld wa, de
	extz xwa
	div xwa, xbc
	add (xsp + 4), wa
	extz xde
	div xde, xbc
	stw_erp WA, 0xea
	ldb_erp A, 0xf9
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocResetMarker:
	calr SeqPart_DispatchRhythmNote
	ldb_erp L, 0xfb
	lda xiy, (xsp + 12)
	lda xix, (xsp + 8)
	ldiw
	ldiw
	jr Rhythm_NoteAllocation_Finalize

Rhythm_ExtAllocStoreAndCont:
	ldb_erp L, 0xfb

Rhythm_NoteAllocation_Finalize:
	ld wa, (xsp + 6)
	cp wa, (xsp + 24)
	jrl c, Rhythm_ExtAllocProcessLoop

Rhythm_ExtAllocStoreResult:
	ld xwa, (xsp + 20)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ld xwa, (xsp + 30)
	stb_erp C, 0xfb
	ld (xwa), c
	stb_erp C, 0xf9

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
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	calr Part_ReadSubBlock32
	cp l, 0x10
	jr nz, SeqFind_NextSlot
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqFind_ShiftBitMask
	slaa bc

SeqFind_ShiftBitMask:
	andda16 xbc, 0xf19e
	jr z, SeqFind_SlotNotActive
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
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
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

SeqPart_DispatchRhythmNote:
	push xiz
	lda xwa, (0xfc5a:16)
	sub xwa, 0xf980
	ld iz, wa
	add iz, 0x2e0
	lds wa, 0
	ld bc, iz
	calr Part_ReadByteDirect
	ldb_erp L, 0xfb
	ld bc, iz
	inc 1, bc
	lds wa, 0
	calr Part_ReadByteDirect
	stb_erp A, 0xfb
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
	ld xiy, WidgetData_DrawbarPositionTable_0x1A8
	lda xix, (xsp + 2)
	lds bc, 4
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
	lda xsp, (xsp - 10)
	pushw_erp 0xfa
	ld (xsp + 8), xwa
	ld xiy, WidgetData_DrawbarPositionTable_0x1B0
	lda xix, (xsp + 2)
	lds bc, 3
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
	ld	xiy, WidgetData_DrawbarPositionTable_0x1B6
	lda	xix, (xsp+4)
	ldiw
	ldiw
	ld	c, (xsp+8)
	extz	bc
	lds	wa, 0
	calr	59811
	cp	l, 16
	jr	z, 9
	cp	l, 13
	jr	z, 4
	lds	hl, 0
	jr	51
	ld	c, (xsp+8)
	extz	bc
	lds	wa, 0
	calr	60062
	lda	xwa, (xsp+4)
	ld	(xwa), hl
	ldw (xwa+2), 5
	lda	xwa, (xsp+4)
	calr	65034
	cp	l, 132
	jr	z, 28
	cp	l, 130
	jr	z, 19
	cp	l, 129
	jr	nz, 2
	incw	1, (xsp)
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, -29
	ld	hl, (xsp)
	lda	xsp, (xsp+10)
	ret
	ldw (xsp), 0
	ld	(xsp+2), 0
	jr	-16
	lda	xsp, (xsp-10)
	ld	(xsp+8), a
	ldw (xsp), 0
	ld	(xsp+2), 1
	ld	xiy, WidgetData_DrawbarPositionTable_0x1BA
	lda	xix, (xsp+4)
	.byte 0x95
	rcf
	.byte 0x95
	rcf
	ld	c, (xsp+8)
	extz	bc
	lds	wa, 0
	calr	59696
	cp	l, 13
	jr	z, 4
	lds	hl, 0
	jr	59
	ld	c, (xsp+8)
	extz	bc
	lds	wa, 0
	calr	59952
	lda	xwa, (xsp+4)
	ld	(xwa), hl
	ldw (xwa+2), 5
	lda	xwa, (xsp+4)
	calr	65042
	cp	l, 177
	jr	z, 32
	cp	l, 176
	jr	z, 27
	cp	l, 132
	jr	z, 30
	cp	l, 130
	jr	z, 25
	cp	l, 129
	jr	z, 20
	.byte 0x8f
	push	sr
	push	xsp
	normal
	jr	z, -37
	ld	hl, (xsp)
	lda	xsp, (xsp+10)
	ret
	ld	a, (8972:16)
	extz	wa
	ld	(xsp), wa
	ld	(xsp+2), 0
	jr	-20

SeqInit_ReturnStub:
	ret

SeqInit_SetBaseAddress:
	ldw (0x286d:16), 1240
	lda xwa, (0x0b0000:24)
	stda32 7514, xwa
	ret

SeqInit_JumpToPartInit:
	jrl Part_InitFromPreset

SeqInit_FullReset:
	push	qiz
	ldw	(9832:16), 1
	ldw	(61854:16), 0
	call	16635550
	calr	53465
	calr	976
	calr	50828
	call	BmDrEdit_InitDisplayParams
	call	16635550
	ldib_erp	251, 0
SeqInit_ClearCBLoop:
	stb_erp	a, 251
	extz	wa
	ldw	bc, 203
	lds	de, 0
	calr	59102
	inc1b_erp	251
	cp_erpb	251, 10
	jr	ule, -22	; -> 0xF42E25
	pushw	1
	ldw	wa, 145
	lds	bc, 3
	lds	de, 0
	call	16624211
	ldib_erp	251, 0
SeqInit_WriteDefaultsLoop:
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1c
	calr Part_ReadWord
	cps hl, 0
	jr z, SeqInit_InitVoiceSubBlocks
	stb_erp A, 0xfb
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
	lds wa, 0
	call VoiceParam_SetD6Group
	popw_erp 0xfa
	ret

Part_InitFromPreset:
	lda xsp, (xsp - 16)
	push xiz
	ld xiy, WidgetData_CharsetMappingTable_0x10
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ldib_erp 0xfb, 0

SeqInit_SetMIDIDefaults:
	stb_erp	a, 251
	extz	wa
	call	16600025
	inc1b_erp	251
	cp_erpb	251, 10
	jr	ule, -18
	ldib_erp	251, 0
SeqInit_FinalizeSetup:
	stb_erp A, 0xfb
	extz wa
	calr Part_InitVoiceDefaults
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1c
	lds de, 0
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x1e
	lds de, 0
	calr Part_WriteWord
	calr SeqStatus_CheckBit2
	stb_erp A, 0xfb
	extz wa
	cps l, 0
	jr nz, SeqInit_WriteMoreDefaults
	calr Part_WriteAllVoiceSubBlocks_A
	jr SeqInit_Return

SeqInit_WriteMoreDefaults:
	calr Part_WriteAllVoiceSubBlocks_B

SeqInit_Return:
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x50
	ldw de, 0xffff
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x52
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x53
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x54
	lds de, 2
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x55
	lds de, 3
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x56
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x57
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x59
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x5b
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x5c
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x5e
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x60
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x61
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x62
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x64
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x66
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x67
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x69
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x6a
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x6c
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x6e
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x6f
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x71
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x72
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x74
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x76
	lds de, 3
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0x77
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xa8
	lds de, 1
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xa9
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xab
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xad
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xae
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xb3
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xb4
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xb5
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xb6
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xb8
	lds de, 1
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xba
	lds de, 2
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xbc
	lds de, 0
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xbf
	lds de, 0
	calr Part_WriteWord
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xbe
	calr Part_ReadByteDirect
	set 0, l
	stb_erp A, 0xfb
	extz wa
	extz hl
	ldw bc, 0xbe
	ld de, hl
	calr Part_WriteByte
	stb_erp A, 0xfb
	extz wa
	ldw bc, 0xcb
	lds de, 0
	calr Part_WriteByte
	lds iz, 0
SeqInit_ClearPartDataLoop:
	stb_erp	a, 251
	extz	wa
	ld	bc, iz
	add	bc, 275
	lds	de, 0
	calr	-7210
	inc	1, iz
	cp	iz, 461
	jr	c, -24
	stb_erp	a, 251
	extz	wa
	lda	xbc, (xsp+4)
	calr	-7355
	stb_erp	a, 251
	extz	wa
	ldw	bc, 272
	ldw	de, 65535
	calr	-7206
	call	16553566
	stb_erp	a, 251
	extz	wa
	ldw	bc, 274
	lds	de, 1
	calr	-7260
	inc1b_erp	251
	cp_erpb	251, 10
	jrl	ule, -695
	call	16635550
	.byte 0xf1, 0xa5, 0x28, 0xb0
	ldw	wa, 76
	call	16544114
	ldw	wa, 11
	ldw	bc, 50
	calr	-15938
	calr	-4969
	ld	(10418:16), 0
	ldw	(9832:16), 1
	stib_da	65507, 0
	ldw	(9500:16), 1
	ldw	(9502:16), 1
	ldw	(9504:16), 1
	ldw	(9506:16), 1
	ld	(10417:16), 0
	ld	(8956:16), 0
	.byte 0xf1, 0x0a, 0x23, 0xb0
	ld	(10430:16), 255
	ld	(8976:16), 0
	.byte 0xf1, 0xec, 0x8c, 0xb0
	ld	(7518:16), 0
	calr	-15672
	call	15950665
	pop	xiz
	lda	xsp, (xsp+16)
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
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_ToggleShiftDone
	slaa bc

SeqPlay_ToggleShiftDone:
	andda16 xbc, 0xf19e
	ld a, (xsp)
	extz wa
	bit 2, (1057:16)
	jr z, SeqPlay_ToggleNoSeqMode
	cps bc, 0
	jr z, SeqPlay_ToggleInactive
	calr SeqPlay_DeactivateChannelFull
	jr SeqPlay_PostInitReturn

SeqPlay_ToggleInactive:
	calr Part_IsVoiceActive
	cps hl, 0
	jr z, SeqPlay_PostInitReturn
	ld a, (xsp)
	extz wa
	calr SeqPlay_HandleChannelSolo
	jr SeqPlay_PostInitReturn

SeqPlay_ToggleNoSeqMode:
	cps bc, 0
	jr z, SeqPlay_ToggleInactiveNoSeq
	calr Part_DeactivateChannel
	jr SeqPlay_ToggleInitStart

SeqPlay_ToggleInactiveNoSeq:
	calr Part_IsVoiceActive
	cps hl, 0
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
	bit 2, (1057:16)
	jrl nz, SeqPlay_StateReturn
	ld (9508:16), 1
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqPlay_StateShiftDone
	slaa bc

SeqPlay_StateShiftDone:
	ld de, bc
	andda16 xde, 0x28a8
	ld a, (xsp)
	extz wa
	cps de, 0
	jr nz, SeqPlay_StateReinitVoice
	andda16 xbc, 0xf19e
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
	cps hl, 0
	jr z, SeqPlay_StateDeactivateChannel
	calr SeqVoice_ActivateWithBarSync
	jr SeqPlay_ClearFlags_Exit

SeqPlay_StateDeactivateChannel:
	calr Part_DeactivateChannel

SeqPlay_ClearFlags_Exit:
	.byte 0xf1, 0xa7, 0x28, 0xb3, 0xc1, 0x9a, 0x8c, 0x21
	.byte 0xc9, 0xcf, 0x87, 0x66, 0x25, 0xc9, 0xcf, 0x88
	.byte 0x66, 0x20, 0xf1, 0xb1, 0x28, 0xc9, 0x6e, 0x08
	.byte 0xf1, 0x68, 0x26, 0x02, 0x01, 0x00, 0x68, 0x12
SeqPlay_StateSetBarPosition:
	ldmm16 9832, 9504
	cpdi16 9832, 1
	jr z, SeqPlay_ResetModeAndDisplay
	setda 3, 0x28a7

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
	cpdi16 0xf19e, 0
	jr nz, SeqPlay_SoloCheckAutoChord
	bit 0, (0x28b1:16)
	jr z, SeqPlay_SoloSetBar1
	ld wa, (9500:16)
	cpdm16 9832, xwa
	jr ugt, SeqPlay_SoloSetBarFromSave

SeqPlay_SoloSetBar1:
	ldw (9832:16), 1
	jr SeqPlay_SoloResetMode

SeqPlay_SoloSetBarFromSave:
	ld (9832:16), wa

SeqPlay_SoloResetMode:
	call NoteEditSy_SendModeScrollReset
	cpdi16 9832, 1
	jr nz, SeqPlay_SoloSetBit3
	resda 3, 0x28a7
	jr SeqPlay_SoloInitState

SeqPlay_SoloSetBit3:
	setda 3, 0x28a7

SeqPlay_SoloInitState:
	calr SeqPlay_InitStartState

SeqPlay_SoloCheckAutoChord:
	ld a, (xsp)
	cpda8 a, 8996
	jr nz, Chan_ActivateAndNotify
	bit 6, (0x28ad:16)
	jr z, Chan_ActivateAndNotify
	ld a, (9828:16)
	ld (0x28ae:16), a
	setda 7, 0x28ae

Chan_ActivateAndNotify:
	ld	a, (xsp)
	extz	wa
	lds	bc, 1
	calr	57589
	call	16635550
	inc	2, xsp
	ret
SeqPlay_DeactivateChannelFull:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	cpda8 a, 8996
	jr nz, SeqPlay_DeactClearBit
	resda 7, 0x28ae
	call MidiChannel_ResetAndConfigure

SeqPlay_DeactClearBit:
	.byte 0x87, 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0x1e, 0xd1
	.byte 0xe0, 0x1d, 0x9e, 0xd6, 0xfd, 0xd1, 0x9e, 0xf1
	.byte 0x3f, 0x00, 0x00, 0x6e, 0x10, 0xf1, 0x1e, 0x04
	.byte 0xca, 0x66, 0x06, 0x1d, 0xcf, 0x96, 0xf5, 0x68
	.byte 0x04
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
	cpdi16 0xf19e, 0
	jr nz, SeqActivate_AssignAndEnable
	bit 0, (0x28b1:16)
	jr z, SeqActivate_SetBar1
	ld wa, (9500:16)
	cpdm16 9832, xwa
	jr ugt, SeqActivate_SetBarFromSave

SeqActivate_SetBar1:
	ldw (9832:16), 1
	jr SeqActivate_ResetMode

SeqActivate_SetBarFromSave:
	ld (9832:16), wa

SeqActivate_ResetMode:
	call NoteEditSy_SendModeScrollReset
	cpdi16 9832, 1
	jr nz, SeqActivate_SetBit3
	resda 3, 0x28a7
	jr SeqActivate_DispatchAccomp

SeqActivate_SetBit3:
	setda 3, 0x28a7

SeqActivate_DispatchAccomp:
	call AccWrap_PlayModeDispatch

SeqActivate_AssignAndEnable:
	ld	a, (xsp)
	extz	wa
	calr	326
	ld	a, (xsp)
	extz	wa
	lds	bc, 1
	calr	57433
	call	16635550
	inc	2, xsp
	ret
Part_DeactivateChannel:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	lds	bc, 0
	calr	57413
	call	16635550
	ld	a, (xsp)
	extz	wa
	calr	44166
	inc	2, xsp
	ret
SeqPlay_FindAndActivateVoice:
	dec 2, xsp
	ld (xsp), a
	lds wa, 0
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, SeqPlay_FindCheckAlternate
	ld a, (xsp)
	extz wa
	calr Part_IsVoiceActive
	cps hl, 0
	jr z, SeqPlay_FindJumpToEnd
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr Chan_SetActiveBit

SeqPlay_FindJumpToEnd:
	jrl SeqPlay_FindReturn

SeqPlay_FindCheckAlternate:
	lds wa, 0
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, SeqPlay_FindCheckBitMask
	bit 1, (0x28b1:16)
	jr z, SeqPlay_FindCheckBitMask
	ld c, (xsp)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, SeqPlay_FindReturn

SeqPlay_FindCheckBitMask:
	cpdi16 0x28a8, 0
	jr nz, SeqPlay_FindClearFlags
	resda 2, 0x28a7

SeqPlay_FindClearFlags:
	.byte 0x87, 0x21, 0xd8, 0x12, 0x1e, 0xfa, 0x00, 0xf1
	.byte 0xb1, 0x28, 0xc9, 0x66, 0x0a, 0xf1, 0xa8, 0x28
	.byte 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6, 0xfd
SeqPlay_FindSetBitAndDeact:
	.byte 0x87, 0x21, 0xd8, 0x12, 0xd9, 0xa9, 0x1e, 0xe4
	.byte 0xdf, 0x87, 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0x1e
	.byte 0xbc, 0xdf, 0xc1, 0x98, 0x8c, 0x3f, 0x0b, 0x66
	.byte 0x2f, 0xf1, 0xb4, 0x28, 0x02, 0x00, 0x00, 0xf1
	.byte 0x30, 0x23, 0x02, 0x00, 0x00, 0xf1, 0x68, 0x26
	.byte 0x02, 0x01, 0x00, 0xc1, 0x33, 0x04, 0x19, 0x32
	.byte 0x23, 0xf1, 0xa7, 0x28, 0xb3, 0x06, 0x06, 0xf1
	.byte 0x1c, 0x04, 0x02, 0x00, 0x00, 0xf1, 0x1b, 0x04
	.byte 0x00, 0x00, 0x06, 0x00, 0x1d, 0x2d, 0x24, 0xef
SeqPlay_FindAfterReset:
	.byte 0x1d, 0x9e, 0xd6, 0xfd, 0xc1, 0x20, 0x04, 0x21
	.byte 0xc9, 0xcc, 0x05, 0xf2, 0xb5, 0x96, 0xf5, 0xe6
	.byte 0x1e, 0x55, 0xab
SeqPlay_FindReturn:
	inc 2, xsp
	ret

SeqVoice_DeactivateAndReinit:
	dec 2,XSP
	ld (XSP),A
	ld A,(XSP)
	extz WA
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	call 0xfdd69e
	ld A,(XSP)
	extz WA
	calr SeqVoice_UpdateSubBlockAssign
	cp (0x8c98:16), 0x0b
	jr z, SeqDeact_DetectTypeReturn
	ldw (0x28b4:16), 0x0000
	ldw (0x2330:16), 0x0000
	ldw (0x2668:16), 0x0001
	.byte 0xc1, 0x33, 0x04, 0x19, 0x32, 0x23, 0xf1, 0xa7
	.byte 0x28, 0xb3, 0x06, 0x06, 0xf1, 0x1c, 0x04, 0x02
	.byte 0x00, 0x00, 0xf1, 0x1b, 0x04, 0x00, 0x00, 0x06
	.byte 0x00, 0x1d, 0x2d, 0x24, 0xef
SeqDeact_DetectTypeReturn:
	calr Part_DetectSingleVoiceType
	inc 2, xsp
	ret

SeqVoice_UpdateSubBlockAssign:
	dec 2,XSP
	ld (XSP),A
	cp (0x8c98:16), 0x0b
	jr z, SeqUpdate_FindVoiceAndWrite
	cp (0x8c9a:16), 0x87
	jr nz, Part_WriteSubBlock_Exit
SeqUpdate_FindVoiceAndWrite:
	lds wa, 0
	ldw bc, 0xe
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, Part_WriteSubBlock_Exit
	ld l, (0x28be:16)
	cp l, 0xff
	jr z, Part_WriteSubBlock_Exit
	inc 1, l
	extz hl
	lds wa, 0
	ld bc, hl
	ldw de, 0xd
	calr Part_WriteSubBlock32

Part_WriteSubBlock_Exit:
	inc 2, xsp
	ret

SeqPlay_ReassignVoiceSlot:
	dec 2, xsp
	ld (xsp), a
	lds wa, 0
	ldw bc, 0xd
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, SeqPlay_ReassignReturn
	extz hl
	lds wa, 0
	ld bc, hl
	ldw de, 0xe
	calr Part_WriteSubBlock32
	resda 0, 8970
	ld a, (xsp)
	dec 1, a
	ld (0x28be:16), a

SeqPlay_ReassignReturn:
	inc 2, xsp
	ret

SeqVoice_SendNoteOffAndFlush:
	pushw_erp 0xfa
	ld a, (8988:16)
	ldb_erp A, 0xfb
	cp_erpb 0xfb, 0xff
	jrl z, SeqVoice_PopRetFA
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone1
	slaa bc

SeqNoteOff_ShiftDone1:
	andda16 xbc, 0xf19e
	jrl z, SeqVoice_PopRetFA
	calr BitMapOut_PrepareAndDisplay
	stb_erp A, 0xfb
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone2
	slaa bc

SeqNoteOff_ShiftDone2:
	ld de, (0x28b4:16)
	and bc, de
	jr z, SeqVoice_PopRetFA
	stb_erp C, 0xfb
	extz bc
	ld a, c
	dec 1, a
	lds hl, 1
	and a, 0xf
	jr z, SeqNoteOff_ShiftDone3
	slaa hl

SeqNoteOff_ShiftDone3:
	.byte 0xdb, 0x06, 0xdb, 0xc2, 0xf1, 0xb4, 0x28, 0x52
	.byte 0xd9, 0x88, 0x1e, 0xea, 0xa9, 0xf1, 0xd8, 0xe2
	.byte 0x30, 0xc7, 0xfb, 0x8b, 0xcb, 0x69, 0xb8, 0x03
	.byte 0x43, 0xd9, 0xac, 0x1e, 0x67, 0xa3, 0xf1, 0xdc
	.byte 0xe2, 0x30, 0xc7, 0xfb, 0x8b, 0xcb, 0x69, 0xb8
	.byte 0x04, 0x43, 0xd9, 0xad, 0x1e, 0x56, 0xa3, 0x1e
	.byte 0x35, 0xa4, 0x0b, 0x30, 0x00, 0x30, 0x48, 0x00
	.byte 0xd9, 0xad, 0xda, 0xa8, 0x1d, 0x53, 0xaa, 0xfd
	.byte 0xd1, 0xa8, 0x28, 0x3f, 0x00, 0x00, 0x6e, 0x16
	.byte 0xc1, 0x92, 0x1d, 0x3f, 0x00, 0x6e, 0x0f, 0xd1
	.byte 0x9e, 0xf1, 0x20, 0xd1, 0xb4, 0x28, 0x21, 0xd9
	.byte 0xc0, 0xf2, 0x86, 0xca, 0xf3, 0xe6
SeqVoice_PopRetFA:
	popw_erp 0xfa
	ret

SeqPlay_SaveStateAndCleanup:
	ld wa, (0xf19e:16)
	stw_da (0x00ffec), wa
	bit 0, (0x28a5:16)
	jr nz, SeqSave_JumpCheckSubsys
	ldw (0xf19e:16), 0x0000
	call 0xfdd69e
SeqSave_JumpCheckSubsys:
	jp	16635550
SeqPlay_CheckAndStartPlayback:
	cp (9508:16), 0
	jp_24 nz, TempoRingBuf_Init
	bit 0, (0x28c5:16)
	jp_24 nz, SeqPlay_CheckAndReactivate
	ld a, (1057:16)
	and a, 0x5
	ret nz
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	ret z
	cpdi16 0xf19e, 0
	ret nz
	cpdi16 0x28a8, 0
	ret z
	cpdi16 0x28aa, 0
	ret nz
	bit 1, (0x28b2:16)
	ret nz
	call SeqPlay_ReassignVoiceChannels
	cps l, 0
	jrl nz, SeqPlay_StopAndClearChannels
	cpdi16 0x28aa, 0
	ret z
	setda 1, 0x28b3
	ei 6
	ldw (1052:16), 0
	ld (1051:16), 0
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
	resda 0, 0x28a5
	ldw wa, 0x4c
	jp CtrlPanel_SetIndicatorBit

SeqAcc_RestorePlaybackState:
	pushw iz
	ld iz, (0x2875:16)
	ld (0xf19e:16), iz
	call 0xfdd69e
	cps iz, 0
	jr z, SeqRestore_ClearIndicator
	resda 3, (0x28a7)
	call SeqAcc_InitPlaybackState
	call 0xfdd69e
	setda 0, (0x28a5)
	jr t, SeqRestore_SetIndicator
SeqRestore_ClearIndicator:
	resda 0, 0x28a5

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
	.byte 0xc1, 0x90, 0x1d, 0x3f, 0x00, 0x66, 0x1f, 0xf1
	.byte 0x1e, 0x04, 0xca, 0x6e, 0x19, 0xc1, 0x21, 0x04
	.byte 0x21, 0xc9, 0xcc, 0x14, 0x6e, 0x10, 0xf1, 0xf4
	.byte 0x11, 0x00, 0x00, 0xd8, 0xa8, 0x1d, 0xa0, 0xad
	.byte 0xfd, 0xf1, 0x90, 0x1d, 0x00, 0x00
SeqPlay_InitBuffers:
	.byte 0xf1, 0xb3, 0x28, 0xcc, 0x66, 0x23, 0xf1, 0x1e
	.byte 0x04, 0xca, 0x6e, 0x1d, 0xc1, 0x21, 0x04, 0x21
	.byte 0xc9, 0xcc, 0x14, 0x6e, 0x14, 0xc1, 0x5e, 0x1d
	.byte 0x3f, 0x00, 0x6e, 0x0d, 0xf1, 0xe7, 0x31, 0xc9
	.byte 0x6e, 0x07, 0x1e, 0x30, 0xb0, 0xf1, 0xb3, 0x28
	.byte 0xb4
SeqPlay_CheckMidiPending:
	cp (7584:16), 0
	ret z
	ld a, (1057:16)
	and a, 0x1c
	ret nz
	call SeqPlay_CheckStartConditions
	ld (7584:16), 0
	ret

SeqPlay_SetupRhythmMode:
	calr Rhythm_SetupAndDispatch
	cps l, 0
	ret nz
	cpdi16 1052, 0
	jr nz, SeqPlay_RhythmHasBar
	cp (1051:16), 0
	jr z, SeqPlay_RhythmNoBar

SeqPlay_RhythmHasBar:
	setda 3, 0x28a7
	jr SeqAcc_ReInitWithGuard

SeqPlay_RhythmNoBar:
	resda 3, 0x28a7

SeqAcc_ReInitWithGuard:
	ld	(58092:16), 1
	call	15963090
	ld	(58092:16), 0
	ret
SeqPlay_DispatchAndResetAll:
	call AccWrap_PlayModeDispatch
	calr Part_CopyVoiceDataToAllChannels
	call SeqPlay_ActivateAllChannels
	ld (0x11f4:16), 0x00
	lds wa, 0
	call 0xfdada0
	resda 3, (0x28a7)
	call TempoRingBuf_Init
	setda 4, (0x28b3)
	ldw WA, 0x000f
	call SoundCtrl_SaveAndSendCmd_EE
	ldw WA, 0x0008
	jp 0xfeb5d2
SeqPlay_StopAndClearChannels:
	ldw	(10408:16), 0
	call	16635550
	ldw	(10410:16), 0
	call	15672539
	ldw	wa, 15
	call	16017021
	ldw	wa, 8
	jp	16692690
SeqPlay_StopAndClearSequence:
	call AccWrap_PlayModeDispatch
	ldw (0x28b4:16), 0x0000
	ldw WA, 0x0032
	calr SeqBuf_WriteNoteOffEntry
	calr VoiceAlloc_ProcessAll
	ld (0x0431:16), 0x00
	resda 5, (0x28b3)
	ldw WA, 0x000e
	call SoundCtrl_SaveAndSendCmd_EE
	ldw WA, 0x0008
	jp 0xfeb5d2
SeqPlay_BufferUpdateBlock:
	ld wa, (0x2330:16)
	ld bc, (0x041c:16)
	cp BC,WA
	ret C
	ld	e, (9010:16)
	sub	bc, wa
	cp	e, c
	ret	ugt
	ld	wa, (9832:16)
	cp	(35994:16), 133
	jr	z, 7
	cp	(35996:16), 134
	jr	nz, 12
	cpda16 xwa, (9506)
	jr	c, 12
	ld	wa, (9504:16)
	jr	14
	cpda16 xwa, (9502)
	jr	nc, 4
	inc	1, wa
	jr	4
	ld	wa, (9500:16)
	ld	(9832:16), wa
	call	16016598
	.byte 0xd1, 0x1c, 0x04, 0x19, 0x30, 0x23
	ld	e, (1075:16)
	ld	(9010:16), e
	jp	16016734
	.byte 0xf1, 0xb2, 0x28, 0xca
	ret	z
	ld	wa, (9832:16)
	cp	wa, 32770
	ret	nz
	ld	a, (1076:16)
	cps	a, 1
	ret	c
	ldw	(9832:16), 32769
	call	16016598
	ret
	ld	wa, (9008:16)
	ld	bc, (1052:16)
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
	call	16016598
	.byte 0xd1, 0x1c, 0x04, 0x19, 0x30, 0x23
	ld	e, (1075:16)
	ld	(9010:16), e
	jp	16016734
	.byte 0xf1, 0xb2, 0x28, 0xc9
	ret	z
	ld	wa, (9832:16)
	cp	wa, 32769
	ret	nz
	ld	a, (1075:16)
	ld	c, (1046:16)
	dec	1, a
	cp	a, c
	ret	nz
	ld	a, (1045:16)
	cp	a, 72
	ret	c
	.byte 0xf1, 0xb3, 0x28, 0xb3
	call	16635550
	call	16635550
	ld	a, (8956:16)
	cp	a, 20
	jr	z, 27
	cp	a, 16
	jr	z, 18
	cp	a, 12
	jr	z, 9
	cp	a, 8
	jr	nz, 14
	ldb	a, 9
	jr	10
	ldb	a, 13
	jr	6
	ldb	a, 17
	jr	2
	ldb	a, 21
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
	div xwa, xbc
	ld l, a
	cp l, 0x64
	ret nz
	ldb l, 0x63
	ret

SeqStatus_SetOrClearBit:
	lda xde, (0xfdad:16)
	cps c, 0
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
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqStatus_Exit
	ld c, (xsp)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqStatus_Exit
	calr PartCtrl_TestBit7
	cps l, 0
	jr z, SeqStatus_Exit
	lds hl, 1
	jr Part_IsVoiceActive_Return

SeqStatus_Exit:
	lds hl, 0

Part_IsVoiceActive_Return:
	inc 2, xsp
	ret

SeqStatus_ResetAndSendCmd:
	resda 0, 0xfdad

	pushw 0x1

	ldw wa, 0x91

	lds bc, 3

	lds de, 0

	call	16624211

	ret



SeqPlay_WriteErrorToVoiceTable:
	ld a, (0x287a:16)
	extz wa
	lda xbc, (WidgetData_DrawbarPositionTable_0x16A:24)
	ldmm_srib 0x07, 0xe4, 0xe0, 0x7a, 0x28
	ret

SeqData_SendVoiceTableBlock:
	dec 6, xsp
	ld xiy, WidgetData_CharsetMappingTable_0x20
	ld xix, xsp
	lds bc, 2
	ldirw
	ldi85
	lda xde, (xsp)
	lds wa, 0
	lds bc, 4
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
	lda_dri XBC, 0x07, 0xe4, 0xe0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld wa, (xde)
	sll wa, 8
	sub wa, 0x100
	extz xwa
	addda32 xwa, 0x283e
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
	addda32 xhl, 0x283e
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
	ldb_erp A, 0xf8
	bit_erpb 0xf8, 0x07
	jr nz, SeqData_SaveParsedState
	stw_erp IY, 0xfa
	inc 2, iy
	ld a, (xsp + 18)
	dec 1, a
	extz wa
	ld ix, wa
	sla ix, 3
	lda xwa, (9016:16)
	lda_dri XWA, 0x07, 0xe0, 0xf0
	ld ix, iy
	extz xix
	add xix, xwa
	stb_erp A, 0xf8
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
	addda32 xhl, 0x283e
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
	addda32 xwa, 0x283e
	ld a, (xwa + 3)
	ldb_erp A, 0xf8
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
	dec 4,XSP
	push QIZ
	cp (0x8c98:16), 0x13
	jr nz, SeqTimer_BarChangeProcess
	ld a, (0x28a4:16)
	st_erpb_rr a, 0xfb
	extz WA
	call Voice_GetPresetFieldWord
	ld (0xf19e:16), hl
	call 0xfdd69e
	ld_erpb_rr a, 0xfb
	extz WA
	call Voice_GetPresetFieldAddr
	ld (XSP+0x02),XHL
	lds_erpb 0xfb, 1
SeqTimer_HandleBarChange:
	stb_erp C, 0xfb
	extz bc
	stb_erp E, 0xfb
	dec 1, e
	extz de
	ld xwa, (xsp + 2)
	ldb_sri E, 0x07, 0xe0, 0xe8
	extz de
	lds wa, 0
	calr Part_WriteSubBlock32
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqTimer_HandleBarChange
	resda 7, 0x28ae
	call MidiChannel_ResetAndConfigure
	jr SeqTimer_BarChangeCleanup

SeqTimer_BarChangeProcess:
	resda 3, 0x28a7
	setda 4, 0x28b3
	lds wa, 0
	ldw bc, 0xbd
	calr Part_ReadByteDirect
	lda xwa, (0xfdad:16)
	cp l, 0xff
	jr nz, SeqTimer_BarChangeLoop
	bitm 2, (xwa)
	jr nz, SeqTimer_BarChangeReturn
	lds wa, 4
	lds bc, 1
	calr SeqStatus_SetOrClearBit
	ld (4330:16), 1
	pushw 0x4
	ldw wa, 0x91
	lds bc, 3
	lds de, 4
	jr SeqTimer_BarChangeEnd

SeqTimer_BarChangeLoop:
	bitm 2, (xwa)
	jr z, SeqTimer_BarChangeReturn
	lds wa, 4
	lds bc, 0
	calr SeqStatus_SetOrClearBit
	ld (4330:16), 1
	pushw 0x4
	ldw wa, 0x91
	lds bc, 3
	lds de, 0

SeqTimer_BarChangeEnd:
	call	16624162
SeqTimer_BarChangeReturn:
	push	xiz
	call	15668425
	pop	xiz
	cpdi16	61854, 0
	jr	z, 11
	ld	(4596:16), 0
	lds	wa, 0
	call	16625056
SeqTimer_BarChangeCleanup:
	popw_erp 0xfa
	inc 4, xsp
	ret

SeqTimer_CheckPlaybackCountdown:
	cp (0x8c98:16), 0x13
	jr nz, SeqTimer_FlagsReturn
	ld a, (0x2966:16)
	bit 0x07,A
	ret Z
	dec	1, a
	ld	(10598:16), a
	cp	a, 128
	ret	nz
	ei	0x06
	ldw	(1052:16), 0
	ld	(1051:16), 0
	ld	a, (10404:16)
	extz	wa
	call	16280571
	cps	l, 0
	jr	z, 20
	ld	(1054:16), 1
	ld	(1045:16), 0
	ld	(1046:16), 0
	ld	(1076:16), 0
SeqTimer_FlagsLoop:
	ld (1057:16), 1
	ld (1056:16), 1
	ei 0

SeqTimer_FlagsReturn:
	ld (0x2966:16), 0
	ret

; SeqEvent dispatch case A
SeqEvent_CaseA:
	cpdi16 0xf19e, 0
	jr z, SeqEvent_CaseB
	anddi8 (0x28a7), 247
	call SeqAcc_InitPlaybackState

; SeqEvent dispatch case B
SeqEvent_CaseB:
	anddi8 (0x28ac), 223
	ret

ApEditSyori:
	cp xbc, 0x1e80015
	jr z, SeqEvent_CaseD
	cp xbc, 0x1e80014
	jr z, SeqEvent_CaseC
	cp xbc, 0x1c0000b
	jr nz, SeqEvent_CaseE
	stda32 0x2972, xde
	calr SeqEvent_MainHandler
	jr SeqEvent_CaseE

; SeqEvent dispatch case C
SeqEvent_CaseC:
	ld xwa, xde
	calr AppEvent_ChainDispatch1
	jr SeqEvent_CaseE

; SeqEvent dispatch case D
SeqEvent_CaseD:
	ld xwa, xde
	calr AppEvent_InlineHandler

; SeqEvent dispatch case E
SeqEvent_CaseE:
	lds32 xhl, 0
	ret

; SeqEvent main handler
SeqEvent_MainHandler:
	ld a, (0x8c9a:16)
	cp A,0x91
	jrl z, AppEvent_SubHandler0
	cp A,0x90
	jr z, SeqEvent_Dispatch
	extz WA
	sub WA,0x009b
	cps wa, 0
	jrl lt, AppEvent_PostDefaultEvents
	cp WA,0x000d
	jrl gt, AppEvent_PostDefaultEvents
	add WA,WA
	lda xix, (WidgetData_CharsetMappingTable_0x248:24)
	ldw_dri wa, 0x07, 0xf0, 0xe0
	lda xix, (SeqEvent_Dispatch:24)
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8
SeqEvent_Dispatch:
	call SeqData_CopyBlockWithLookup
	ld a, (0x2878:16)
	extz wa
	call SeqPart_CountActiveVoices
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1e
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1f
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x20
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x21
	jrl AppEvent_PostEvent_Stub
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xa
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xb
	jrl AppEvent_PostEvent_Stub
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 5
	jrl AppEvent_PostEvent_Stub
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 4
	jrl AppEvent_PostEvent_Stub
	ld wa, (0xf1d7:16)
	addda16 xwa, 0xf1d9
	dec 1, wa
	ld (9772:16), wa
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	jrl AppEvent_PostEvent_Stub
	ld wa, (0xf1dc:16)
	addda16 xwa, 0xf1de
	dec 1, wa
	ld (9766:16), wa
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 6
	jrl AppEvent_PostEvent_Stub
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 7
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x8
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x9
	jrl AppEvent_PostEvent_Stub
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xc
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xd
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xe
	jrl AppEvent_PostEvent_Stub
	ld wa, (0xf1ea:16)
	addda16 xwa, 0xf1ec
	dec 1, wa
	ld (9768:16), wa
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xf
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x10
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x11
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x12
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x13
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x14
	jrl AppEvent_PostEvent_Stub
	ld wa, (0xf1e2:16)
	addda16 xwa, 0xf1e4
	dec 1, wa
	ld (9774:16), wa
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x15
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x16
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x17
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x18
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x19
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1c0000f
	ld xde, 0x1b
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1c
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1d
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1e
	jr AppEvent_PostEvent_Stub

AppEvent_PostDefaultEvents:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 3

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
	add xbc, WidgetData_CharsetMappingTable_0x2C0
	ld bc, (xbc)
	lda xix, (APP_EVENT_HANDLER_TABLE:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
; Application event handler dispatch table
; Handles up to 32 event types (XBC 0-0x1f), used by ApDeliveryEvent system
; Each handler increments counters, sends notifications via CALL 0FA9E07h
APP_EVENT_HANDLER_TABLE:
	ld	a, (35994:16)
	extz	wa
	sub	wa, 156
	cps	wa, 0
	jr	lt, 4
	cps	wa, 7
	jr	le, 3
AppEvtHandler_Branch_001:
	ldw wa, 0x8
AppEvtHandler_Branch_002:
	.byte 0xd8, 0xee, 0x02, 0xf2, 0xd2, 0x48, 0xe4, 0x34
	.byte 0xe3, 0x07, 0xf0, 0xe0, 0x20, 0x80, 0x3f, 0x11
	.byte 0x7f, 0xed, 0x06, 0x80, 0x61, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x78, 0xd9, 0x06, 0xc1, 0x9a, 0x8c, 0x21, 0xd8
	.byte 0x12, 0xd8, 0xca, 0x9c, 0x00, 0xd8, 0xd8, 0x61
	.byte 0x56, 0xd8, 0xdf, 0x6a, 0x52, 0xd8, 0x80, 0xf2
	.byte 0xc2, 0x48, 0xe4, 0x34, 0xd3, 0x07, 0xf0, 0xe0
	.byte 0x20, 0xf2, 0xbb, 0x41, 0xf4, 0x34, 0xf3, 0x07
	.byte 0xf0, 0xe0, 0xd8, 0xf1, 0x10, 0x26, 0x36, 0xf1
	.byte 0x12, 0x26, 0x30, 0x68, 0x3a, 0xf1, 0x29, 0xf2
	.byte 0x36, 0xf1, 0xfa, 0x25, 0x30, 0x68, 0x30, 0xf1
	.byte 0x1e, 0x26, 0x36, 0xf1, 0x20, 0x26, 0x30, 0x68
	.byte 0x26, 0xf1, 0xd7, 0xf1, 0x36, 0xf1, 0x2c, 0x26
	.byte 0x30, 0x68, 0x1c, 0xf1, 0xdc, 0xf1, 0x36, 0xf1
	.byte 0x26, 0x26, 0x30, 0x68, 0x12, 0xf1, 0xf2, 0xf1
	.byte 0x36, 0xf1, 0xfc, 0x25, 0x30, 0x68, 0x08
AppEvtHandler_Branch_003:
	lda xiz, (9734:16)
	lda xwa, (9736:16)
AppEvtHandler_Branch_004:
	ld (xsp + 4), xwa
	cpw (xiz), 0x3e7
	jr nc, AppEvtHandler_Branch_005
	incw 1, (xiz)
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
AppEvtHandler_Branch_005:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, AppEvtHandler_Branch_006
	ld bc, (xiz)
	ld (xwa), bc
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
AppEvtHandler_Branch_006:
	ld	a, (35994:16)
	cp	a, 163
	jrl	z, 183	; -> 0xF442F6
	cp	a, 161
	jrl	z, 200	; -> 0xF4430D
	jrl	1576	; -> 0xF44870
	ld	a, (35994:16)
	extz	wa
	sub	wa, 156
	cps	wa, 0
	jr	lt, 86	; -> 0xF442AC
	cps	wa, 7
	jr	gt, 82	; -> 0xF442AC
	add	wa, wa
	lda	xix, (14960818:24)
	ld_rrw	wa, xix, wa
	lda	xix, (16007792:24)
	jp_rr	8, xix, wa
	lda	xiz, (9744:16)
	lda	xwa, (9746:16)
	jr	58	; -> 0xF442B4
	lda	xiz, (61993:16)
	lda	xwa, (9722:16)
	jr	48	; -> 0xF442B4
	lda	xiz, (9758:16)
	lda	xwa, (9760:16)
	jr	38	; -> 0xF442B4
	lda	xiz, (61911:16)
	lda	xwa, (9772:16)
	jr	28	; -> 0xF442B4
	lda	xiz, (61916:16)
	lda	xwa, (9766:16)
	jr	18	; -> 0xF442B4
	lda	xiz, (61938:16)
	lda	xwa, (9724:16)
	jr	8	; -> 0xF442B4
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
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
AppEvtHandler_Branch_009:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, AppEvtHandler_Branch_010
	ld wa, (xwa)
	ld (xiz), wa
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
AppEvtHandler_Branch_010:
	ld	a, (35994:16)
	cp	a, 163
	jr	nz, 17
AppEvtHandler_Branch_011:
	ld wa, (9772:16)
	subda16 xwa, 0xf1d7
	inc 1, wa
	ld (0xf1d9:16), wa
	jrl AppEvent_Epilogue
AppEvtHandler_Branch_012:
	cp a, 0xa1
	jrl nz, AppEvent_Epilogue
AppEvtHandler_Branch_013:
	ld wa, (9766:16)
	subda16 xwa, 0xf1dc
	inc 1, wa
	ld (0xf1de:16), wa
	jrl AppEvent_Epilogue
	ld a, (9740:16)
	cp a, 0x60
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9740:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 3
	jrl AppEvtHandler_Branch_033
	ld a, (9762:16)
	cp a, 0x7f
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9762:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 4
	jrl AppEvtHandler_Branch_033
	ld a, (0xf22e:16)
	cp a, 0x7f
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (0xf22e:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 5
	jrl AppEvtHandler_Branch_033
	ld a, (0xf1e0:16)
	cps a, 2
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1e0:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 6
	jrl AppEvtHandler_Branch_033
	ld a, (0xf1f6:16)
	cps a, 6
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1f6:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 7
	jrl AppEvtHandler_Branch_033
	ld a, (9728:16)
	cp a, 0x64
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9728:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x8
	jrl AppEvtHandler_Branch_033
	ld a, (9730:16)
	cp a, 0x64
	jrl ge, AppEvent_Epilogue
	inc 1, a
	ld (9730:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x9
	jrl AppEvtHandler_Branch_033
	ld a, (9750:16)
	cp a, 0x7f
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9750:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xa
	jrl AppEvtHandler_Branch_033
	ld a, (9816:16)
	cp a, 0x7f
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (9816:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xb
	jrl AppEvtHandler_Branch_033
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
	cpda8 a, 0xf1d4
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
	ld xbc, 0x1c0000f
	ld xde, 0xc
	jrl AppEvtHandler_Branch_033
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
	cpda8 a, 0xf1d3
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
	ld xbc, 0x1c0000f
	ld xde, 0xd
	jrl AppEvtHandler_Branch_033
	ld a, (0xf1d5:16)
	cp a, 0x10
	jrl nc, AppEvent_Epilogue
	inc 1, a
	ld (0xf1d5:16), a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xe
	jrl AppEvtHandler_Branch_033
	sub xwa, 0xf
	cp xwa, 0x0
	jrl c, AppEvtHandler_Branch_024
	cp xwa, 0x5
	jrl ugt, AppEvtHandler_Branch_024
	add xwa, xwa
	add xwa, WidgetData_CharsetMappingTable_0x270
	ld wa, (xwa)
	lda xix, (AppEvtHandler_Branch_021_0x5E:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
	ld a, (0xf1e9:16)
	cp a, 0x11
	jrl nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (0xf1e9:16), a
	cp a, 0x11
	jrl nz, AppEvtHandler_Branch_024
	ld (0xf1ee:16), 17
	jr AppEvtHandler_Branch_024
	ld wa, (0xf1ea:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_022
	inc 1, wa
	ld (0xf1ea:16), wa
AppEvtHandler_Branch_022:
	ld wa, (0xf1ea:16)
	cpda16 xwa, 9768
	jr ule, AppEvtHandler_Branch_023
	ld (9768:16), wa
	jr AppEvtHandler_Branch_023
	ld wa, (9768:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_023
	inc 1, wa
	ld (9768:16), wa
AppEvtHandler_Branch_023:
	ld wa, (9768:16)
	subda16 xwa, 0xf1ea
	inc 1, wa
	ld (0xf1ec:16), wa
	jr AppEvtHandler_Branch_024
	ld a, (0xf1ee:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (0xf1ee:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_024
	ld (0xf1e9:16), 17
	jr AppEvtHandler_Branch_024
	ld wa, (0xf1ef:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_024
	inc 1, wa
	ld (0xf1ef:16), wa
	jr AppEvtHandler_Branch_024
	ld a, (9770:16)
	cp a, 0x7f
	jr nc, AppEvtHandler_Branch_024
	inc 1, a
	ld (9770:16), a
AppEvtHandler_Branch_024:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xf
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x10
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x11
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x12
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x13
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x14
	jrl AppEvtHandler_Branch_033
	sub xwa, 0x15
	cp xwa, 0x0
	jrl c, AppEvtHandler_Branch_027
	cp xwa, 0x5
	jrl ugt, AppEvtHandler_Branch_027
	add xwa, xwa
	add xwa, WidgetData_CharsetMappingTable_0x264
	ld wa, (xwa)
	lda xix, (AppEvtHandler_Branch_024_0x97:24)
	jp_ind 8, 0x07, 0xf0, 0xe0
	ld a, (0xf1e1:16)
	cp a, 0x11
	jrl nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (0xf1e1:16), a
	cp a, 0x11
	jrl nz, AppEvtHandler_Branch_027
	ld (0xf1e6:16), 17
	jr AppEvtHandler_Branch_027
	ld wa, (0xf1e2:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_025
	inc 1, wa
	ld (0xf1e2:16), wa
AppEvtHandler_Branch_025:
	ld wa, (0xf1e2:16)
	cpda16 xwa, 9774
	jr ule, AppEvtHandler_Branch_026
	ld (9774:16), wa
	jr AppEvtHandler_Branch_026
	ld wa, (9774:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_026
	inc 1, wa
	ld (9774:16), wa
AppEvtHandler_Branch_026:
	ld wa, (9774:16)
	subda16 xwa, 0xf1e2
	inc 1, wa
	ld (0xf1e4:16), wa
	jr AppEvtHandler_Branch_027
	ld a, (0xf1e6:16)
	cp a, 0x11
	jr nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (0xf1e6:16), a
	cp a, 0x11
	jr nz, AppEvtHandler_Branch_027
	ld (0xf1e1:16), 17
	jr AppEvtHandler_Branch_027
	ld wa, (0xf1e7:16)
	cp wa, 0x3e7
	jr nc, AppEvtHandler_Branch_027
	inc 1, wa
	ld (0xf1e7:16), wa
	jr AppEvtHandler_Branch_027
	ld a, (9776:16)
	cp a, 0x7f
	jr nc, AppEvtHandler_Branch_027
	inc 1, a
	ld (9776:16), a
AppEvtHandler_Branch_027:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x15
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x16
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x17
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x18
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x19
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1a
	jrl AppEvtHandler_Branch_033
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
	ld xbc, 0x1c0000f
	ld xde, 0x1b
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1c
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1d
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x1e
	jr AppEvtHandler_Branch_033
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
	ld xbc, 0x1c0000f
	ld xde, 0x1f
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x20
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x21
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
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
	add xbc, WidgetData_CharsetMappingTable_0x35C
	ld bc, (xbc)
	lda xix, (AppEvent_SubDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
AppEvent_SubDispatch:
	ld	a, (35994:16)
	extz	wa
	sub	wa, 156
	cps	wa, 0
	jr	lt, 4
	cps	wa, 7
	jr	le, 3
	ldw	wa, 8
	sll	wa, 2
	lda	xix, (14961006:24)
	ld_rrl	xwa, xix, wa
	.byte 0x80, 0x3f, 0x01
	jrl	ule, 1740
	decm8	1, (xwa)
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 0
	jrl	1720
	ld	a, (35994:16)
	extz	wa
	sub	wa, 156
	cps	wa, 0
	jr	lt, 86
	cps	wa, 7
	jr	gt, 82
	add	wa, wa
	lda	xix, (14960990:24)
	ld_rrw	wa, xix, wa
	lda	xix, (16009462:24)
	jp_rr 8, xix, wa
	lda	xiz, (9744:16)
	lda	xwa, (9746:16)
	jr	58
	lda	xiz, (61993:16)
	lda	xwa, (9722:16)
	jr	48
	lda	xiz, (9758:16)
	lda	xwa, (9760:16)
	jr	38
	lda	xiz, (61911:16)
	lda	xwa, (9772:16)
	jr	28
	lda	xiz, (61916:16)
	lda	xwa, (9766:16)
	jr	18
	lda	xiz, (61938:16)
	lda	xwa, (9724:16)
	jr	8
	lda	xiz, (9734:16)
	lda	xwa, (9736:16)
	ld	(xsp+4), xwa
	.byte 0x96, 0x3f, 0x01, 0x00
	jr	ule, 17
	decm	1, (xiz)
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 1
	call	16423418
	ld	bc, (xiz)
	ld	xwa, (xsp+4)
	.byte 0x90, 0xf1
	jr	ule, 19
	ld	bc, (xiz)
	ld	(xwa), bc
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 2
	call	16423418
	ld	a, (35994:16)
	cp	a, 163
	jrl	z, 183
	cp	a, 161
	jrl	z, 200
	jrl	1543
	ld	a, (35994:16)
	extz	wa
	sub	wa, 156
	cps	wa, 0
	jr	lt, 86
	cps	wa, 7
	jr	gt, 82
	add	wa, wa
	lda	xix, (14960974:24)
	ld_rrw	wa, xix, wa
	lda	xix, (16009643:24)
	jp_rr 8, xix, wa
	lda	xiz, (9744:16)
	lda	xwa, (9746:16)
	jr	58
	lda	xiz, (61993:16)
	lda	xwa, (9722:16)
	jr	48
	lda	xiz, (9758:16)
	lda	xwa, (9760:16)
	jr	38
	lda	xiz, (61911:16)
	lda	xwa, (9772:16)
	jr	28
	lda	xiz, (61916:16)
	lda	xwa, (9766:16)
	jr	18
	lda	xiz, (61938:16)
	lda	xwa, (9724:16)
	jr	8
	lda	xiz, (9734:16)
	lda	xwa, (9736:16)
	ld	(xsp+4), xwa
	.byte 0x90, 0x3f, 0x01, 0x00
	jr	ule, 20
	ld	xwa, (xsp+4)
	decm	1, (xwa)
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 2
	call	16423418
	ld	bc, (xiz)
	ld	xwa, (xsp+4)
	.byte 0x90, 0xf1
	jr	ule, 19
	ld	wa, (xwa)
	ld	(xiz), wa
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 1
	call	16423418
	ld	a, (35994:16)
	cp	a, 163
	jr	nz, 17
	ld	wa, (9772:16)
	subda16 xwa, (61911)
	inc	1, wa
	ld	(61913:16), wa
	jrl	1352
	cp	a, 161
	jrl	nz, 1346
	ld	wa, (9766:16)
	subda16 xwa, (61916)
	inc	1, wa
	ld	(61918:16), wa
	jrl	1329
	ld	a, (9740:16)
	cp	a, 160
	jrl	le, 1319
	dec	1, a
	ld	(9740:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 3
	jrl	1295
	ld	a, (9762:16)
	cp	a, 129
	jrl	le, 1289
	dec	1, a
	ld	(9762:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 4
	jrl	1265
	ld	a, (61998:16)
	cp	a, 129
	jrl	le, 1259
	dec	1, a
	ld	(61998:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 5
	jrl	1235
	ld	a, (61920:16)
	cps	a, 0
	jrl	z, 1230
	dec	1, a
	ld	(61920:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 6
	jrl	1206
	ld	a, (61942:16)
	cps	a, 0
	jrl	z, 1201
	dec	1, a
	ld	(61942:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	lds32	xde, 7
	jrl	1177
	ld	a, (9728:16)
	cps	a, 0
	jrl	z, 1172
	dec	1, a
	ld	(9728:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 8
	jrl	1145
	ld	a, (9730:16)
	cp	a, 156
	jrl	le, 1139
	dec	1, a
	ld	(9730:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 9
	jrl	1112
	ld	a, (9750:16)
	cps	a, 0
	jrl	z, 1107
	dec	1, a
	ld	(9750:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 10
	jrl	1080
	ld	a, (9816:16)
	cps	a, 0
	jrl	z, 1075
	dec	1, a
	ld	(9816:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 11
	jrl	1048
	ld	a, (61907:16)
	cps	a, 1
	jr	ule, 8
	dec	1, a
	ld	(61907:16), a
	jr	9
	ld	(61907:16), 16
	ld	a, (61907:16)
	cpda8	a, 61908
	jr	nz, 17
	cps	a, 1
	jr	ule, 8
	dec	1, a
	ld	(61907:16), a
	jr	5
	ld	(61907:16), 16
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 12
	jrl	983
	ld	a, (61908:16)
	cps	a, 1
	jr	ule, 8
	dec	1, a
	ld	(61908:16), a
	jr	9
	ld	(61908:16), 16
	ld	a, (61908:16)
	cpda8	a, 61907
	jr	nz, 17
	cps	a, 1
	jr	ule, 8
	dec	1, a
	ld	(61908:16), a
	jr	5
	ld	(61908:16), 16
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 13
	jrl	918
	ld	a, (61909:16)
	cps	a, 1
	jrl	ule, 913
	dec	1, a
	ld	(61909:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 14
	jrl	886
	sub	xwa, 15
	cp	xwa, 0
	jrl	c, 172
	cp	xwa, 5
	jrl	ugt, 163
	add	xwa, xwa
	add	xwa, 14960962
	ld	wa, (xwa)
	lda	xix, (16010300:24)
	jp_rr 8, xix, wa
	ld	a, (61929:16)
	cps	a, 1
	jrl	ule, 134
	dec	1, a
	ld	(61929:16), a
	cp	a, 16
	jr	nz, 123
	ld	(61934:16), 16
	jr	116
	ld	wa, (61930:16)
	cps	wa, 1
	jr	ule, 36
	dec	1, wa
	ld	(61930:16), wa
	jr	28
	ld	wa, (9768:16)
	cps	wa, 1
	jr	ule, 6
	dec	1, wa
	ld	(9768:16), wa
	ld	wa, (9768:16)
	cpdm16 (61930), xwa
	jr	ule, 4
	ld	(61930:16), wa
	ld	wa, (9768:16)
	subda16 xwa, (61930)
	inc	1, wa
	ld	(61932:16), wa
	jr	56
	ld	a, (61934:16)
	cps	a, 1
	jr	ule, 48
	dec	1, a
	ld	(61934:16), a
	cp	a, 16
	jr	nz, 37
	ld	(61929:16), 16
	jr	30
	ld	wa, (61935:16)
	cps	wa, 1
	jr	ule, 22
	dec	1, wa
	ld	(61935:16), wa
	jr	14
	ld	a, (9770:16)
	cps	a, 0
	jr	z, 6
	dec	1, a
	ld	(9770:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 15
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 16
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 17
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 18
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 19
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 20
	jrl	592
	sub	xwa, 21
	cp	xwa, 0
	jrl	c, 172
	cp	xwa, 5
	jrl	ugt, 163
	add	xwa, xwa
	add	xwa, 14960950
	ld	wa, (xwa)
	lda	xix, (16010594:24)
	jp_rr 8, xix, wa
	ld	a, (61921:16)
	cps	a, 1
	jrl	ule, 134
	dec	1, a
	ld	(61921:16), a
	cp	a, 16
	jr	nz, 123
	ld	(61926:16), 16
	jr	116
	ld	wa, (61922:16)
	cps	wa, 1
	jr	ule, 36
	dec	1, wa
	ld	(61922:16), wa
	jr	28
	ld	wa, (9774:16)
	cps	wa, 1
	jr	ule, 6
	dec	1, wa
	ld	(9774:16), wa
	ld	wa, (9774:16)
	cpdm16 (61922), xwa
	jr	ule, 4
	ld	(61922:16), wa
	ld	wa, (9774:16)
	subda16 xwa, (61922)
	inc	1, wa
	ld	(61924:16), wa
	jr	56
	ld	a, (61926:16)
	cps	a, 1
	jr	ule, 48
	dec	1, a
	ld	(61926:16), a
	cp	a, 16
	jr	nz, 37
	ld	(61921:16), 16
	jr	30
	ld	wa, (61927:16)
	cps	wa, 1
	jr	ule, 22
	dec	1, wa
	ld	(61927:16), wa
	jr	14
	ld	a, (9776:16)
	cps	a, 0
	jr	z, 6
	dec	1, a
	ld	(9776:16), a
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 21
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 22
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 23
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 24
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 25
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 26
	jrl	298
	cp	xwa, 30
	jr	z, 100
	cp	xwa, 29
	jr	z, 65
	cp	xwa, 28
	jr	z, 31
	cp	xwa, 27
	jr	nz, 100
	ld	a, (9992:16)
	cps	a, 1
	jr	ule, 92
	dec	1, a
	ld	(9992:16), a
	extz	wa
	ld	xbc, 10306
	jr	47
	ld	a, (9996:16)
	cps	a, 1
	jr	ule, 69
	dec	1, a
	ld	(9996:16), a
	cp	a, 16
	jr	nz, 58
	ld	(9998:16), 16
	jr	51
	ld	a, (9994:16)
	cps	a, 1
	jr	ule, 43
	dec	1, a
	ld	(9994:16), a
	extz	wa
	ld	xbc, 10322
	call	15997415
	jr	24
	ld	a, (9998:16)
	cps	a, 1
	jr	ule, 16
	dec	1, a
	ld	(9998:16), a
	cp	a, 16
	jr	nz, 5
	ld	(9996:16), 16
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 27
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 28
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 29
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 30
	jr	96
	ld	a, (10360:16)
	cps	a, 0
	jr	z, 92
	dec	1, a
	ld	(10360:16), a
	call	15993317
	ld	a, (10360:16)
	extz	wa
	call	15993070
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 31
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 32
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 33
	call	16423418
	ld	xwa, (10610:16)
	ld	xbc, 29360143
	ld	xde, 34
	call	16423418
SeqState_DispatchEntry:
	pop xiz
	inc 4, xsp
	ret

SeqVoice_DispatchAllEvents:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0

SeqVoice_DispatchLoop:
	stb_erp A, 0xfb
	extz wa
	calr SeqVoice_DispatchEventToHandler
	stb_erp A, 0xfb
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
	ldb_erp L, 0xfb
	ld c, (xsp + 2)
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadSubBlock32
	lds32 xbc, 0
	stb_erp C, 0xfb
	sll xbc, 8
	lds32 xwa, 0
	ld a, (xsp + 2)
	sll xwa, 0
	ld xix, xwa
	add xix, xbc
	ldb h, 0x0
	extz xhl
	add xhl, xix
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002d
	ld xde, xhl
	call ApPostEvent
	popw_erp 0xfa
	inc 2, xsp
	ret

SeqVoice_ComputeStatusFlags:
	dec 2,XSP
	ld (XSP),A
	ld e, (0x8c9c:16)
	lds bc, 1
	ld A,(XSP)
	and A,0x0f
	jr z, SeqStatus_CheckState9A
	.byte 0xd9, 0xfc
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
	andda16 xbc, 0xf19e
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cps hl, 0
	jr nz, SeqStatus_SetActiveFlag

SeqVoice_PostStatusEvent_Inactive:
	ldb c, 0x0

SeqVoice_PostStatus_Loop:
	ldb b, 0x0
	extz xbc
	lds32 xwa, 0
	ld a, (xsp)
	sll xwa, 0
	ld xde, xwa
	add xde, xbc
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002e
	call ApPostEvent
	inc 2, xsp
	ret

SeqStatus_CheckHighState:
	ld de, bc
	andda16 xbc, 0x28a8
	jr z, SeqStatus_CheckHighFallback
	ldb c, 0x1
	jr SeqVoice_PostStatus_Loop

SeqStatus_CheckHighFallback:
	andda16 xde, 0xf19e
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cps hl, 0
	jr z, SeqVoice_PostStatusEvent_Inactive

SeqStatus_SetActiveFlag:
	ldb c, 0x2
	jr SeqVoice_PostStatus_Loop

SeqStatus_Handle9AState:
	andda16 xbc, 9704
	jr z, SeqVoice_PostStatusEvent_Inactive
	ldb c, 0x4
	jr SeqVoice_PostStatus_Loop

AppEvent_HandleChannelEvent:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), a
	ld	e, (35994:16)
	cp	e, 154
	jrl	z, 456
	ld	c, (xsp+4)
	inc	1, c
	cp	e, 151
	jrl	z, 373
	cp	e, 148
	jrl	z, 367
	cp	e, 137
	jrl	z, 211
	ld	wa, (61854:16)
	ld	qiz, wa
	extz	bc
	cp	e, 135
	jr	z, 96
	cp	e, 133
	jr	z, 91
	cp	e, 122
	jr	z, 11
	cp	e, 120
	jr	z, 6
	cp	e, 129
	jrl	nz, 466
AppEvent_ToggleChannel:
	ld wa, bc
	call SeqPlay_HandleChannelToggle
	ld bc, (0xf19e:16)
	cpw_erp BC, 0xfa
	jrl z, AppEvent_PopIzSkip2Ret
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, AppEvent_ToggleShiftDone
	slaa de

AppEvent_ToggleShiftDone:
	and de, bc
	ldb l, 0x0
	cps de, 0
	jr z, AppEvent_ToggleSetStatus
	ldb l, 0x2

AppEvent_ToggleSetStatus:
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002e
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
	cpdm16 0x28a8, xiz
	jrl z, AppEvent_PopIzSkip2Ret

; Sequencer state case 0
SeqState_Case0:
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, SeqState_Case1
	slaa de

; Sequencer state case 1
SeqState_Case1:
	ld wa, de
	andda16 xde, 0x28a8
	jr z, SeqState_Case2
	ldb l, 0x1
	jr SeqState_Case3

; Sequencer state case 2
SeqState_Case2:
	and wa, bc
	ldb l, 0x0
	cps wa, 0
	jr z, SeqState_Case3
	ldb l, 0x2

; Sequencer state case 3
SeqState_Case3:
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002e
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
	cps bc, 0
	jrl lt, AppEvent_PopIzSkip2Ret
	cp bc, 0xf
	jrl gt, AppEvent_PopIzSkip2Ret
	add bc, bc
	lda xix, (WidgetData_CharsetMappingTable_0x3AC:24)
	ldw_sri BC, 0x07, 0xf0, 0xe4
	lda xix, (SoundData_HandlerDispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
; Sound data handler dispatch
SoundData_HandlerDispatch:
	call	15860830
	jrl	245
	call	15860841
	jrl	238
	call	15860852
	jrl	231
	call	15860863
	jrl	224
	call	15860874
	jrl	217
	call	15860885
	jrl	210
	call	15860896
	jrl	203
	call	15860907
	jrl	196
	call	15860918
	jrl	189
	call	15860929
	jrl	182
	call	15860940
	jrl	175
	call	15860951
	jrl	168
	call	15860962
	jrl	161
	call	15860973
	jrl	154
	call	15860984
	jrl	147
	call	15860995
	jrl	140
AppEvent_HandleRecordState:
	extz bc
	dec 2, bc
	cps bc, 0
	jr lt, AppEvent_RecordClampLow
	cp bc, 0xe
	jr le, AppEvent_RecordDispatch

AppEvent_RecordClampLow:
	ldw bc, 0xf

AppEvent_RecordDispatch:
	lda xix, (WidgetData_CharsetMappingTable_0x39C:24)
	ldb_sri A, 0x07, 0xf0, 0xe4
	ld (xsp + 4), a
	inc 1, a
	extz wa
	call BmDrEdit_CheckNoteType
	cps hl, 0
	jr nz, AppEvent_PopIzSkip2Ret
	mrdb5 0x8f, 0x04, 0x19, 0x65, 0x29
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda xbc, (WidgetData_CharsetMappingTable_0x226:24)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0x4f, 0x0d
	call BmDrEdit_SaveSequencerState
	jr AppEvent_PopIzSkip2Ret

AppEvent_Handle9AToggle:
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xf
	jr z, AppEvent_9AShiftDone
	slaa de

AppEvent_9AShiftDone:
	ld wa, de
	ld bc, (9704:16)
	and wa, bc
	jr z, AppEvent_9ASetOff
	ldb l, 0x0
	cpl de
	and bc, de
	jr AppEvent_9AStoreAndPost

AppEvent_9ASetOff:
	ldb l, 0x4
	or bc, de

AppEvent_9AStoreAndPost:
	ld (9704:16), bc
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, 0x1c0002e
	call ApPostEvent

AppEvent_PopIzSkip2Ret:
	pop xiz
	inc 2, xsp
	ret

EffEditMain:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xde
	ld	e, (35996:16)
	cp	xbc, 31981586
	jrl	z, 437
	cp	xbc, 31981585
	jrl	z, 136
	cp	xbc, 29360139
	jrl	nz, 517
	ld	xwa, (xsp+2)
	stda32	(10610), xwa
	calr	1247
	cps	hl, 0
	jrl	nz, 502
	ld	xwa, (xsp+2)
	ld	xbc, 31981582
	lds32	xde, 0
	call	16423418
	ld	a, (35996:16)
	cp	a, 214
	jr	z, 62
	cp	a, 14
	jr	z, 40
	cp	a, 11
	jr	z, 6
	cp	a, 10
	jrl	nz, 463
EffEdit_DispatchTypeB:
	lds iz, 0

EffEdit_TypeBLoop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1e8000f
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_TypeBLoop
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_DispatchTypeE:
	ld xwa, (xsp + 2)
	ld xbc, 0x1e8000f
	lds32 xde, 0
	call ApDeliveryEvent
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_DispatchTypeD6:
	lds iz, 0

EffEdit_TypeD6Loop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1e8000f
	call ApDeliveryEvent
	inc 1, iz
	cps iz, 4
	jr c, EffEdit_TypeD6Loop
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_HandleParamChange:
	ld	xbc, (xsp+2)
	cp	e, 11
	jrl	z, 162
	cp	e, 10
	jr	z, 37
	cp	e, 214
	jr	z, 19
	cp	e, 14
	jrl	nz, 365
	ld	(58096:16), 1
	ld	xwa, 19712
	jrl	348
EffEdit_ParamChangeD6:
	ld	(58096:16), 1
	ld	xwa, 19968
	jrl	335
EffEdit_ParamChangeA:
	ld	(58096:16), 1
	ld	wa, (10614:16)
	extz	wa
	lda	xde, (14960604:24)
	ld_rrb	e, xde, wa
	lda	xwa, (14960476:24)
	cps	e, 0
	jr	ge, 12
	ld	c, (xwa)
	exts	bc
	ld	xwa, 19200
	jrl	165
EffEdit_ParamAPositive:
	cps bc, 0
	jr le, EffEdit_ParamANegative
	inc 1, e
	ldb_sri C, 0x03, 0xe0, 0xe8
	cps c, 0
	jr lt, AppEvent_DeliveryLoop
	exts bc
	ld xwa, 0x4b00
	jrl EffEdit_WriteDSPAndReturn

EffEdit_ParamANegative:
	cps bc, 0
	jr ge, AppEvent_DeliveryLoop
	cps e, 0
	jr z, AppEvent_DeliveryLoop
	dec 1, e
	ldb_sri C, 0x03, 0xe0, 0xe8
	exts bc
	ld xwa, 0x4b00
	jr EffEdit_WriteDSPAndReturn

AppEvent_DeliveryLoop:
	lds iz, 0

EffEdit_DeliveryLoopBody:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1e8000f
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_DeliveryLoopBody
	jrl AppEvent_ReturnZeroEpilogue4

EffEdit_ParamChangeB:
	ld (0xe2f0:16), 0x01
	ld wa, (0x2976:16)
	extz WA
	lda xde, (WidgetData_CharsetMappingTable_0xA6:24)
	ldb_dri e, 0x07, 0xe8, 0xe0
	lda xwa, (WidgetData_CharsetMappingTable_0x26:24)
	cps e, 0
	jr ge, EffEdit_ParamBPositive
	ld C,(XWA)
	exts BC
	ld XWA,0x00004900
	jr t, EffEdit_WriteDSPAndReturn
EffEdit_ParamBPositive:
	cps bc, 0
	jr le, EffEdit_ParamBNegative
	inc 1, e
	ldb_sri C, 0x03, 0xe0, 0xe8
	cps c, 0
	jr lt, AppEvent_DeliveryNoRet
	exts bc
	ld xwa, 0x4900
	jr EffEdit_WriteDSPAndReturn

EffEdit_ParamBNegative:
	cps bc, 0
	jr ge, AppEvent_DeliveryNoRet
	cps e, 0
	jr z, AppEvent_DeliveryNoRet
	dec 1, e
	ldb_sri C, 0x03, 0xe0, 0xe8
	exts bc
	ld xwa, 0x4900

EffEdit_WriteDSPAndReturn:
	call	16630064
	jr	126
AppEvent_DeliveryNoRet:
	lds iz, 0

EffEdit_DeliveryNoRetLoop:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1e8000f
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffEdit_DeliveryNoRetLoop
	jr AppEvent_ReturnZeroEpilogue4

EffEdit_HandleDirectWrite:
	ld xwa, (xsp + 2)
	and xwa, 0xff
	ldb w, 0x0
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
	call	16630547
AppEvent_ReturnZeroEpilogue4:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

EffEdit_DSPConfigBlock:
	.byte 0xef, 0x6c, 0x2e, 0xc1, 0xe4, 0xbf, 0x21, 0xd8
	.byte 0x12, 0xc1, 0xe1, 0xbf, 0x23, 0xd9, 0x12, 0xc1
	.byte 0xe3, 0xbf, 0x25, 0xda, 0x12, 0xbf, 0x02, 0x33
	.byte 0x3b, 0x1d, 0xcf, 0xc6, 0xfd, 0xdb, 0xd8, 0x71
	.byte 0xb8, 0x02, 0xc1, 0x9c, 0x8c, 0x21, 0xc9, 0xcf
	.byte 0xd6, 0x76, 0x11, 0x02, 0xc9, 0xcf, 0x0e, 0x76
	.byte 0xa6, 0x01, 0xc9, 0xcf, 0x0c, 0x76, 0x58, 0x01
	.byte 0xc9, 0xcf, 0x0b, 0x76, 0xac, 0x00, 0xc9, 0xcf
	.byte 0x0a, 0x7e, 0x96, 0x02, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x00, 0x4b, 0x00, 0x00, 0x77, 0x8a, 0x02
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x47, 0x4b, 0x00
	.byte 0x00, 0x7f, 0x7e, 0x02, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x00, 0x4b, 0x00, 0x00, 0x6e, 0x53, 0x1e
	.byte 0x74, 0x02, 0xdb, 0xd8, 0x7e, 0x6b, 0x02, 0xe1
	.byte 0x72, 0x29, 0x20, 0x41, 0x0e, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xfa, 0x99, 0xfa, 0xc1, 0xf0
	.byte 0xe2, 0x3f, 0x01, 0x7e, 0x06, 0x02, 0xde, 0xa8
	.byte 0x68, 0x20, 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x10, 0x4b, 0x00, 0x00, 0x1d, 0x2d, 0xc0, 0xfd
	.byte 0xdb, 0x89, 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x10, 0x4b, 0x00, 0x00, 0x1d, 0x30, 0xc1, 0xfd
	.byte 0xde, 0x61, 0xd1, 0xaa, 0x29, 0xf6, 0x7f, 0xdb
	.byte 0x01, 0xde, 0xcf, 0x19, 0x00, 0x67, 0xd3, 0x78
	.byte 0xd2, 0x01, 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10
	.byte 0x4b, 0x00, 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20
	.byte 0x1d, 0x28, 0xc0, 0xfd, 0xde, 0x88, 0xd8, 0x80
	.byte 0xf1, 0x78, 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80
	.byte 0xb0, 0x53, 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a
	.byte 0xea, 0x12, 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x78
	.byte 0xec, 0x01, 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x00
	.byte 0x49, 0x00, 0x00, 0x77, 0xe4, 0x01, 0xaf, 0x02
	.byte 0x20, 0xe8, 0xcf, 0x47, 0x49, 0x00, 0x00, 0x7f
	.byte 0xd8, 0x01, 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x00
	.byte 0x49, 0x00, 0x00, 0x6e, 0x53, 0x1e, 0xce, 0x01
	.byte 0xdb, 0xd8, 0x7e, 0xc5, 0x01, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0e, 0x00, 0xe8, 0x01, 0xea, 0xa8
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0xc1, 0xf0, 0xe2, 0x3f
	.byte 0x01, 0x7e, 0x60, 0x01, 0xde, 0xa8, 0x68, 0x20
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x49
	.byte 0x00, 0x00, 0x1d, 0x2d, 0xc0, 0xfd, 0xdb, 0x89
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x49
	.byte 0x00, 0x00, 0x1d, 0x30, 0xc1, 0xfd, 0xde, 0x61
	.byte 0xd1, 0xaa, 0x29, 0xf6, 0x7f, 0x35, 0x01, 0xde
	.byte 0xcf, 0x19, 0x00, 0x67, 0xd3, 0x78, 0x2c, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10, 0x49, 0x00
	.byte 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x1d, 0x28
	.byte 0xc0, 0xfd, 0xde, 0x88, 0xd8, 0x80, 0xf1, 0x78
	.byte 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0x53
	.byte 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a, 0xea, 0x12
	.byte 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x78, 0x46, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x10, 0x4c, 0x00
	.byte 0x00, 0x77, 0x3e, 0x01, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x17, 0x4c, 0x00, 0x00, 0x7b, 0x32, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10, 0x4c, 0x00
	.byte 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x1d, 0x28
	.byte 0xc0, 0xfd, 0xde, 0x88, 0xd8, 0x80, 0xf1, 0x78
	.byte 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0x53
	.byte 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a, 0xea, 0x12
	.byte 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x78, 0xfe, 0x00
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x00, 0x4d, 0x00
	.byte 0x00, 0x6e, 0x35, 0x1e, 0xf8, 0x00, 0xdb, 0xd8
	.byte 0x7e, 0xef, 0x00, 0xe1, 0x72, 0x29, 0x20, 0x41
	.byte 0x0e, 0x00, 0xe8, 0x01, 0xea, 0xa8, 0x1d, 0xfa
	.byte 0x99, 0xfa, 0xc1, 0xf0, 0xe2, 0x3f, 0x01, 0x7e
	.byte 0x8a, 0x00, 0x40, 0x10, 0x4d, 0x00, 0x00, 0x1d
	.byte 0x2d, 0xc0, 0xfd, 0xdb, 0x89, 0x40, 0x10, 0x4d
	.byte 0x00, 0x00, 0x1d, 0x30, 0xc1, 0xfd, 0x68, 0x74
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x10, 0x4d, 0x00
	.byte 0x00, 0x7e, 0xb6, 0x00, 0xaf, 0x02, 0x20, 0x1d
	.byte 0x28, 0xc0, 0xfd, 0xf1, 0x78, 0x29, 0x53, 0xe1
	.byte 0x72, 0x29, 0x20, 0x41, 0x0f, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x78, 0x99, 0x00, 0xaf, 0x02, 0x20
	.byte 0xe8, 0xcf, 0x00, 0x4e
	nop
	nop
	jr nz, .Lc_f45776
	calr EffEdit_ValidateAndReadParams
	cps hl, 0
	jrl nz, .Lc_f457bd
	ld xwa, (0x2972:16)
	ld XBC,0x01e8000e
	lds32 xde, 0
	call ApDeliveryEvent
	cp (0xe2f0:16), 0x01
	jr nz, .Lc_f4576f
	lds iz, 0
.Lc_f4574b:
	ld WA,IZ
	extz XWA
	add XWA,0x00004e10
	call 0xfdc02d
	ld BC,HL
	ld WA,IZ
	extz XWA
	add XWA,0x00004e10
	call 0xfdc130
	inc 1,IZ
	cps iz, 4
	jr c, .Lc_f4574b
.Lc_f4576f:
	ld (0xe2f0:16), 0x00
	jr t, .Lc_f457bd
.Lc_f45776:
	ld XWA,(XSP+0x02)
	cp XWA,0x00004e10
	jr c, .Lc_f457bd
	ld XWA,(XSP+0x02)
	cp XWA,0x00004e13
	jr ugt, .Lc_f457bd
	ld XWA,(XSP+0x02)
	sub XWA,0x00004e10
	ld IZ,WA
	ld XWA,(XSP+0x02)
	call 0xfdc028
	ld WA,IZ
	add WA,WA
	lda xbc, (0x2978:16)
	extz XWA
	add XWA,XBC
	ld (XWA),HL
	ld xwa, (0x2972:16)
	ld DE,IZ
	extz XDE
	ld XBC,0x01e8000f
	call ApDeliveryEvent
.Lc_f457bd:
	popw iz
	inc 4,XSP
	ret
EffEdit_ValidateAndReadParams:
	pushw_erp 0xfa
	lda xde, (0x29ac:16)
	ld xwa, xde
	lda xbc, (0x2978:16)
	lda xde, (xde + 25)

EffEdit_ValidateLoop:
	stiw_dsp	229, 0, 0
	stib_dsp	224, 0
	cp	xwa, xde
	jr	c, -13	; -> 0xF457D1
	ld	a, (35996:16)
	cp	a, 214
	jrl	z, 400	; -> 0xF45978
	cp	a, 14
	jrl	z, 361	; -> 0xF45957
	cp	a, 12
	jrl	z, 309	; -> 0xF45929
	cp	a, 11
	jrl	z, 159	; -> 0xF45899
	cp	a, 10
	jrl	nz, 468	; -> 0xF459D4
	ld	xwa, 19200
	call	16629800
	and	hl, 127
	ld	(10614:16), hl
	ld	xwa, 19204
	call	16629800
	ld	(10666:16), hl
	ldib_erp	251, 0
	jr	64	; -> 0xF45863
EffEdit_ReadParamA_Body:
	lds32 xwa, 0

	stb_erp A, 0xfb

	add xwa, 0x4b10

	call	16629800

	stb_erp A, 0xfb

	extz wa

	add wa, wa

	lda xbc, (0x2978:16)

	stw_dri HL, 0x07, 0xe4, 0xe0

	lds32 xwa, 0

	stb_erp A, 0xfb

	add xwa, 0x4b10

	call	16629526

	stb_erp C, 0xfb

	extz bc

	lda xwa, (0x29ac:16)

	extz xbc

	add xbc, xwa

	ld (xbc), l

	inc1b_erp 0xfb



EffEdit_ReadParamA_Check:
	stb_erp C, 0xfb
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
	cps a, 3
	jr nz, EffEdit_ReturnZeroJmp
	ld (xbc), 0x0
	ld wa, (0x29aa:16)
	dec 1, wa
	ld (0x29aa:16), wa

EffEdit_ReturnZeroJmp:
	lds hl, 0
	jrl EffEdit_PopAndReturn

EffEdit_ReadParamB:
	ld	xwa, 18688
	call	16629800
	and	hl, 127
	ld	(10614:16), hl
	ld	xwa, 18692
	call	16629800
	ld	(10666:16), hl
	ldib_erp	251, 0
	jr	64
EffEdit_ReadParamB_Body:
	lds32 xwa, 0

	stb_erp A, 0xfb

	add xwa, 0x4910

	call	16629800

	stb_erp A, 0xfb

	extz wa

	add wa, wa

	lda xbc, (0x2978:16)

	stw_dri HL, 0x07, 0xe4, 0xe0

	lds32 xwa, 0

	stb_erp A, 0xfb

	add xwa, 0x4910

	call	16629526

	stb_erp C, 0xfb

	extz bc

	lda xwa, (0x29ac:16)

	extz xbc

	add xbc, xwa

	ld (xbc), l

	inc1b_erp 0xfb



EffEdit_ReadParamB_Check:
	stb_erp C, 0xfb
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
	lds32	xwa, 0
	stb_erp	a, 251
	add	xwa, 19472
	call	16629800
	stb_erp	a, 251
	extz	wa
	add	wa, wa
	lda	xbc, (10616:16)
	st_rrw	hl, xbc, wa
	inc1b_erp	251
	cp_erpb	251, 8
	jr	c, -40
	jrl	-195
EffEdit_ReadParamE:
	ld	xwa, 19712
	call	16629800
	and	hl, 127
	ld	(10614:16), hl
	ld	xwa, 19728
	call	16629800
	ld	(10616:16), hl
	jrl	-228
EffEdit_ReadParamD6:
	ld xwa, 0x4e00

	call	16629800

	and hl, 0x7f

	ld (0x2976:16), hl

	ldib_erp 0xfb, 0



EffEdit_ReadParamD6_Loop:
	lds32	xwa, 0
	stb_erp	a, 251
	add	xwa, 19984
	call	16629800
	stb_erp	a, 251
	extz	wa
	add	wa, wa
	lda	xbc, (10616:16)
	st_rrw	hl, xbc, wa
	lds32	xwa, 0
	stb_erp	a, 251
	add	xwa, 19984
	call	16629526
	stb_erp	c, 251
	extz	bc
	lda	xwa, (10668:16)
	extz	xbc
	add	xbc, xwa
	ld	(xbc), l
	inc1b_erp	251
	cpib_erp	251, 4
	jr	c, -69	; -> 0xF4598C
	jrl	-320	; -> 0xF45894
EffEdit_ReturnError:
	ldw hl, 0xffff

EffEdit_PopAndReturn:
	popw_erp 0xfa
	ret

EffEdit_ValidateRangeDelta:
	dec 0,XSP
	push XIZ
	ld (XSP+0x06),BC
	ld (XSP+0x08),XWA
	ld XWA,0x00004c10
	call 0xfdc028
	ld (XSP+0x04),HL
	ld XWA,0x00004c12
	call 0xfdc028
	ld QIZ,HL
	ld XWA,0x00004c14
	call 0xfdc028
	ld IZ,HL
	ld XWA,0x00004c16
	call 0xfdc028
	ld BC,QIZ
	sub BC,(XSP+0x04)
	ld XWA,(XSP+0x08)
	cp XWA,0x00004c10
	jr nz, EffEdit_RangeCheck4C12
	cpw (XSP+0x06), 0x0000
	jr le, EffEdit_WriteValidDelta
	cps bc, 1
	jr gt, EffEdit_WriteValidDelta
	jr t, EffEdit_PopIzSkip8Ret
EffEdit_RangeCheck4C12:
	ld de, iz
	subw_erp DE, 0xfa
	ld xwa, (xsp + 8)
	cp xwa, 0x4c12
	jr nz, EffEdit_RangeCheck4C14
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_RangeCheckDE
	cps bc, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheckDE:
	cps de, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheck4C14:
	sub hl, iz
	ld xwa, (xsp + 8)
	cp xwa, 0x4c14
	jr nz, EffEdit_RangeCheck4C16
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_RangeCheckHL
	cps de, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

EffEdit_RangeCheckHL:
	cps hl, 1
	jr le, EffEdit_PopIzSkip8Ret

EffEdit_WriteValidDelta:
	ld	xwa, (xsp+8)
	ld	bc, (xsp+6)
	call	16630547
	jr	22
EffEdit_RangeCheck4C16:
	ld xwa, (xsp + 8)
	cp xwa, 0x4c16
	jr nz, EffEdit_WriteValidDelta
	cpw (xsp + 6), 0x0
	jr ge, EffEdit_WriteValidDelta
	cps hl, 1
	jr gt, EffEdit_WriteValidDelta

EffEdit_PopIzSkip8Ret:
	pop xiz
	inc 8, xsp
	ret

MimeSyori:
	cp	xbc, 31457339
	jr	nz, 10
	or	xde, xde
	scc8	nz, a
	extz	wa
	call	16635979
MimeSyori_ReturnZero:
	lds32 xhl, 0
	ret

ApPlaySyori:
	dec	4, xsp
	pushw	iz
	ld	(xsp+2), xde
	cp	xbc, 31981638
	jrl	z, 2193	; -> 0xF4634A
	cp	xbc, 31981637
	jrl	z, 2051	; -> 0xF462C5
	cp	xbc, 31981636
	jrl	z, 1847	; -> 0xF46202
	ld	de, (9832:16)
	ld	hl, (9506:16)
	ld	iy, (9504:16)
	ld	iz, (9502:16)
	ld	wa, (9500:16)
	ld	qde, wa
	ld	a, (10298:16)
	ldb_erp	a, 238
	ld	a, (35994:16)
	ldb_erp	a, 239
	cp	xbc, 31981589
	jrl	z, 1234	; -> 0xF45FCB
	cp	xbc, 31981588
	jrl	z, 689	; -> 0xF45DB3
	cp	xbc, 29360139
	jrl	nz, 2146	; -> 0xF4636D
	ld	xwa, (xsp+2)
	stda32	(10610), xwa
	ld	c, (35994:16)
	cp	c, 153
	jrl	z, 597	; -> 0xF45D71
	cp	c, 150
	jrl	z, 591	; -> 0xF45D71
	ld	xwa, (xsp+2)
	cp	c, 122
	jr	z, 93	; -> 0xF45B87
	cp	c, 120
	jr	z, 88	; -> 0xF45B87
	extz	bc
	sub	bc, 129
	cps	bc, 0
	jrl	lt, 2099	; -> 0xF4636D
	cps	bc, 7
	jrl	gt, 2094	; -> 0xF4636D
	add	bc, bc
	lda	xix, (14961202:24)
	ld_rrw	bc, xix, bc
	lda	xix, (16014165:24)
	jp_rr	8, xix, bc
SeqAccomp_EventDispatch:
	ld	xbc, 0x01c0000f
	lds32	xde, 0
	call	ApDeliveryEvent
	.byte 0xc1
	ldw	hl, 6404
	ldw de, 57635
	.ascii "r) A"
	retd	0xc000
	.byte 0x01
	lds32	xde, 1
	call	ApDeliveryEvent
	ld	a, (0x28b1:16)
	and	a, 1
	cps	a, 0
	scc16	nz, iz
	ld	wa, iz
	exts	xwa
	jrl	1835

SeqAccomp_StartAndPostEvents:
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl SeqAccomp_StartHandler
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	ld (7528:16), l
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	bit 1, (0x28b1:16)
	jr z, SeqPlay_AllocHideIndicator
	lds iz, 1
	ld xwa, 0x850014
	lds bc, 1
	call SetVisible
	ld xwa, 0x850013
	ld xbc, 0x1e0009c
	lds32 xde, 1
	jr SeqPlay_AllocPostEvent

SeqPlay_AllocHideIndicator:
	lds iz, 0
	ld xwa, 0x850014
	lds bc, 0
	call SetVisible
	ld xwa, 0x850013
	ld xbc, 0x1e0009c
	lds32 xde, 0

SeqPlay_AllocPostEvent:
	call ApPostEvent
	ld wa, iz
	exts xwa
	calr AppEvent_SendPlayStatus
	ld a, (0x28b2:16)
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld wa, iz
	exts xwa
	jrl NoteEdit_ScrollCallReset
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	ld (7528:16), l
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ld a, (0x28b2:16)
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x87000d
	ld xbc, 0x1e0003b
	call ApDeliveryEvent
	lds wa, 0
	jrl NoteEdit_ReturnSendToggle
	bit 2, (1057:16)
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
	subda16 xwa, 0xf23f
	ld (9832:16), wa
	ld (9964:16), wa
	jr SeqAcc_SendParamsAndStart

SeqPlay_AllocAdjustBar:
	dec 1, wa
	ld (0x28c3:16), wa
	call SeqAcc_UpdateEndPosition
	ld wa, (0xf238:16)
	subda16 xwa, 0xf23f
	ld (9832:16), wa
	ld (9964:16), wa

SeqAcc_SendParamsAndStart:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 7
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x8
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x9
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xa
	call ApDeliveryEvent
	ld a, (0x28b2:16)
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x880004
	ld xbc, 0x1e0003b
	jrl SeqAccomp_StartHandler
	ld a, (0x28b2:16)
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld wa, iz
	exts xwa
	calr AppEvent_SendAccompStatus
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 4
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 5
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 6
	jrl SeqAccomp_StartHandler

SeqAccomp_DispatchRhythmEvents:
	call BmDrEdit_EnterPlayMode
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 3
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 5
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 6
	call ApDeliveryEvent
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xb
	jrl SeqAccomp_StartHandler

; SeqAccomp parameter delivery
SeqAccomp_ParamDelivery:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, WidgetData_CharsetMappingTable_0x3E4
	ld wa, (xwa)
	lda xix, (SeqAccomp_SubHandlerA:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; Sequencer accompaniment sub-handler A
SeqAccomp_SubHandlerA:
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x93, 0x05, 0xda
	.byte 0x88, 0xda, 0xcf, 0xe7, 0x03, 0x7f, 0x8a, 0x05
	.byte 0xd8, 0x61, 0xf1, 0x68, 0x26, 0x50, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa8, 0x78, 0x4e, 0x03, 0xf1, 0x21, 0x04, 0xca
	.byte 0x7e, 0x6f, 0x05, 0xc7, 0xef, 0x89, 0xc7, 0xef
	.byte 0xcf, 0x82, 0x6e, 0x13, 0xc1, 0xb1, 0x28, 0x21
	.byte 0xc9, 0x33, 0x00, 0x7e, 0x5c, 0x05, 0xc9, 0x31
	.byte 0x00, 0xf1, 0xb1, 0x28, 0x41, 0x68, 0x30, 0xc9
	.byte 0xcf, 0x86, 0x6e, 0x2b, 0xf1, 0xb2, 0x28, 0xca
	.byte 0x7e, 0x47, 0x05, 0xf1, 0xb1, 0x28, 0xc9, 0x7e
	.byte 0x40, 0x05, 0x1d, 0x7c, 0xf0, 0xf3, 0xf1, 0xb1
	.byte 0x28, 0xb9, 0xd1, 0x20, 0x25, 0x19, 0x68, 0x26
	.byte 0xe1, 0x72, 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0
	.byte 0x01, 0xea, 0xab, 0x1d, 0xfa, 0x99, 0xfa, 0xe1
	.byte 0x72, 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xac, 0x78, 0xed, 0x02, 0xf1, 0x21, 0x04
	.byte 0xca, 0x7e, 0x0e, 0x05, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x86, 0x6e, 0x2c, 0xdd, 0x88, 0xdd, 0xcf, 0xe7
	.byte 0x03, 0x7f, 0xfe, 0x04, 0xd8, 0x61, 0xf1, 0x20
	.byte 0x25, 0x50, 0xf1, 0x68, 0x26, 0x50, 0xd1, 0x22
	.byte 0x25, 0xf0, 0x63, 0x43, 0xd1, 0x20, 0x25, 0x19
	.byte 0x22, 0x25, 0xe1, 0x72, 0x29, 0x20, 0x41, 0x0f
	.byte 0x00, 0xc0, 0x01, 0xea, 0xae, 0x68, 0x2c, 0xd7
	.byte 0xea, 0x88, 0xd7, 0xea, 0xcf, 0xe7, 0x03, 0x7f
	.byte 0xd0, 0x04, 0xd8, 0x61, 0xf1, 0x1c, 0x25, 0x50
	.byte 0xf1, 0x68, 0x26, 0x50, 0xd1, 0x1e, 0x25, 0xf0
	.byte 0x63, 0x15, 0xd1, 0x1c, 0x25, 0x19, 0x1e, 0x25
	.byte 0xe1, 0x72, 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0
	.byte 0x01, 0xea, 0xae, 0x1d, 0xfa, 0x99, 0xfa, 0x1e
	.byte 0x11, 0x06, 0xe1, 0x72, 0x29, 0x20, 0x41, 0x0f
	.byte 0x00, 0xc0, 0x01, 0xea, 0xad, 0x78, 0x72, 0x02
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x93, 0x04, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x86, 0x6e, 0x17, 0xdb, 0x88
	.byte 0xdb, 0xcf, 0xe7, 0x03, 0x7f, 0x83, 0x04, 0xd8
	.byte 0x61, 0xf1, 0x22, 0x25, 0x50, 0xd1, 0x20, 0x25
	.byte 0x19, 0x68, 0x26, 0x68, 0x15, 0xde, 0x88, 0xde
	.byte 0xcf, 0xe7, 0x03, 0x7f, 0x6c, 0x04, 0xd8, 0x61
	.byte 0xf1, 0x1e, 0x25, 0x50, 0xd1, 0x1c, 0x25, 0x19
	.byte 0x68, 0x26, 0x1e, 0xc6, 0x05, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xae
	.byte 0x78, 0x27, 0x02, 0xf1, 0x21, 0x04, 0xca, 0x7e
	.byte 0x48, 0x04, 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x0a
	.byte 0x00, 0x00, 0x00, 0x66, 0x1c, 0xe8, 0xcf, 0x09
	.byte 0x00, 0x00, 0x00, 0x66, 0x0e, 0xe8, 0xcf, 0x08
	.byte 0x00, 0x00, 0x00, 0x6e, 0x10, 0x1d, 0x94, 0x8b
	.byte 0xf3, 0x68, 0x0a, 0x1d, 0x88, 0x8c, 0xf3, 0x68
	.byte 0x04, 0x1d, 0xe9, 0x8c, 0xf3, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xaf
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x08, 0x00
	.byte 0x00, 0x00, 0x1d, 0xfa, 0x99, 0xfa, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x09, 0x00, 0x00, 0x00, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0xe1, 0x72, 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0x0a, 0x00, 0x00, 0x00, 0x78, 0x2b
	.byte 0x02, 0xc7, 0xee, 0xd9, 0x76, 0xd3, 0x03, 0xf1
	.byte 0x3a, 0x28, 0x00, 0x01, 0xd1, 0x63, 0x29, 0x19
	.byte 0x9e, 0xf1, 0x1d, 0x9e, 0xd6, 0xfd, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x0b, 0x00, 0x00, 0x00, 0x1d, 0xfa, 0x99, 0xfa
	.byte 0xd1, 0x9e, 0xf1, 0x19, 0x38, 0x28, 0xf1, 0x21
	.byte 0x04, 0xca, 0x76, 0x33, 0x02, 0x78, 0xa2, 0x03
SeqAccomp_SubChain:
	ld xwa, (xsp + 2)
	cp xwa, 0xb
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, WidgetData_CharsetMappingTable_0x3CC
	ld wa, (xwa)
	lda xix, (SeqAccomp_SubHandlerB:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; Sequencer accompaniment sub-handler B
SeqAccomp_SubHandlerB:
	.incbin "includes/romslices/v7_transplant_SeqAccomp_SubHandlerB.bin"
SeqAccomp_StartHandler:
	call ApDeliveryEvent
	jrl t, AppEvent_ReturnZero
	cps_erpb 0xee, 0
	jrl z, AppEvent_ReturnZero
	ld (0x283a:16), 0x00
	.byte 0xd2, 0xec, 0xff, 0x00, 0x19, 0x9e, 0xf1, 0x1d
	.byte 0x9e, 0xd6, 0xfd, 0xe1, 0x72, 0x29, 0x20, 0x41
	.byte 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x0b, 0x00, 0x00
	.byte 0x00, 0x1d, 0xfa, 0x99, 0xfa, 0xd1, 0x9e, 0xf1
	.byte 0x19, 0x38, 0x28, 0xf1, 0x21, 0x04, 0xca, 0x7e
	.byte 0x72, 0x01, 0x1d, 0xcf, 0xe7, 0xf3, 0x78, 0x6b
	.byte 0x01
SeqAccomp_StartHelper:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x85, 0x7e, 0x80, 0x00
	.byte 0xf1, 0x21, 0x04, 0xca, 0x6e, 0x06, 0xf1, 0xb2
	.byte 0x28, 0xca, 0x66, 0x1c
SeqAccomp_TogglePlayback:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, SeqAccomp_ToggleSetZero
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr SeqAccomp_ToggleSendStatus

SeqAccomp_ToggleSetZero:
	lds32 xwa, 0
	ld (xsp + 2), xwa

SeqAccomp_ToggleSendStatus:
	ld xwa, (xsp + 2)
	calr AppEvent_SendPlayStatus
	jrl AppEvent_ReturnZero
SeqAccomp_HandleStartStop:
	ld	xwa, (xsp+2)
	or	xwa, xwa
	jr	nz, 60
	.byte 0xf1, 0xb1, 0x28, 0xb1
	ldw	(9832:16), 1
	ld	wa, (10408:16)
	ld	bc, (61854:16)
	cpl	wa
	and	bc, wa
	ld	(61854:16), bc
	call	16635550
	ld	xwa, 8716308
	lds	bc, 0
	call	16407167
	ld	xwa, 8716307
	ld	xbc, 31457436
	lds32	xde, 0
	call	16423418
	jrl	207
SeqAccomp_ActivateAndAssign:
	call SeqVoice_ScanAndAssignParts
	setda 1, 0x28b1
	ld wa, (9504:16)
	ld (9832:16), wa
	ldw wa, 0x86
	jr SeqAccomp_PostModeAndInit

SeqAccomp_HandleOtherState:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, SeqAccomp_OtherActivate
	bit 2, (1057:16)
	jr z, SeqAccomp_OtherClearBit
	calr SeqAccomp_ReassignVoiceState
	cps hl, 0
	jrl z, AppEvent_ReturnZero
	lds32 xwa, 1
	jr SeqAccomp_SendVoiceAndReturn

SeqAccomp_OtherClearBit:
	resda 0, 0x28b1
	jrl SeqAccomp_InitAndReturn

SeqAccomp_OtherActivate:
	bit 2, (1057:16)
	jr z, SeqAccomp_OtherSetBit
	lds32 xwa, 0

SeqAccomp_SendVoiceAndReturn:
	calr AppEvent_SendVoiceUpdate
	jrl AppEvent_ReturnZero

SeqAccomp_OtherSetBit:
	setda 0, 0x28b1
	ldw wa, 0x82

SeqAccomp_PostModeAndInit:
	call UI_PostModeChangeEvent
	jr SeqAccomp_InitAndReturn

; NoteEditSy mode scroll dispatch
NoteEditSy_ModeScroll:
	bit 2, (1057:16)
	jr nz, NoteEdit_ScrollToggle
	ld c, (0x28b2:16)
	bit 2, c
	jr z, NoteEdit_ScrollInactive

NoteEdit_ScrollToggle:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, NoteEdit_ScrollSetZero
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr NoteEdit_ScrollDispatchMode

NoteEdit_ScrollSetZero:
	lds32 xwa, 0
	ld (xsp + 2), xwa

NoteEdit_ScrollDispatchMode:
	ld	a, (35996:16)
	cp	a, 133
	jr	nz, 8
	ld	xwa, (xsp+2)
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
	.byte 0xcb, 0x31, 0x00, 0xf1, 0xb2, 0x28, 0x43, 0xc1
	.byte 0x9c, 0x8c, 0x3f, 0x85, 0x6e, 0x07, 0x30, 0xab
	.byte 0x00, 0x1d, 0xb0, 0x90, 0xf9
SeqAccomp_InitAndReturn:
	call SeqPlay_InitStartState
	jr AppEvent_ReturnZero

; NoteEditSy mode scroll return
NoteEditSy_ModeScrollReturn:
	call SeqPlay_CheckAndActivateParts
	cps hl, 0
	jr z, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, NoteEdit_ReturnSetZero
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr NoteEdit_ReturnGetParam

NoteEdit_ReturnSetZero:
	lds32 xwa, 0
	ld (xsp + 2), xwa

NoteEdit_ReturnGetParam:
	ld xwa, (xsp + 2)
	extz wa

NoteEdit_ReturnSendToggle:
	calr AppEvent_SendModeToggle

AppEvent_ReturnZero:
	lds32 xhl, 0
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
	resda 0, 0x28b1
	ld (8956:16), 3
	ld (7570:16), 0
	ld wa, (0x28b4:16)
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
	lda_dri XBC, 0x07, 0xf0, 0xe0
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xbc + 2)
	ld (xhl + 2), wa
	ld hl, (xhl)
	lda xbc, (xix + 76)
	ld (xbc), hl
	ld (xbc + 2), wa
	lda xbc, (xsp + 6)
	ldb_erp E, 0xea
	ld xix, xbc
	ldib_erp 0xe2, 0

SeqAccomp_ReassignCopyLoop:
	stb_erp E, 0xe2
	extz de
	inc 2, de
	stb_erp A, 0xea
	dec 1, a
	extz wa
	sla wa, 3
	lda xhl, (9016:16)
	lda_dri XIY, 0x07, 0xec, 0xe0
	ld iz, de
	extz xiz
	add xiz, xiy
	stb_erp E, 0xe2
	extz de
	ld a, (xiz)
	stb_dri A, 0x07, 0xf0, 0xe8
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccomp_ReassignCopyLoop
	ld xix, xbc
	ldib_erp 0xe2, 0

SeqAccomp_ReassignWriteLoop:
	stb_erp A, 0xe2
	extz wa
	inc 2, wa
	lda_dri XBC, 0xed, 0x98, 0x00
	ld de, wa
	extz xde
	add xde, xbc
	stb_erp A, 0xe2
	extz wa
	ldb_sri A, 0x07, 0xf0, 0xe0
	ld (xde), a
	inc1b_erp 0xe2
	cpib_erp 0xe2, 6
	jr c, SeqAccomp_ReassignWriteLoop
	lda xde, (xsp + 14)
	ld wa, (xsp + 4)
	sla wa, 3
	lda_dri XBC, 0x07, 0xec, 0xe0
	ld wa, (xbc)
	ld (xde), wa
	ld a, (xbc + 3)
	ld (xde + 2), a
	ld wa, (xde)
	stw_dri WA, 0xed, 0x98, 0x00

SeqAccomp_ReassignDone:
	lds hl, 0

SeqAccomp_ReassignEpilogue:
	pop xiz
	lda xsp, (xsp + 18)
	ret

AppEvent_SendModeToggle:
	cps a, 0
	scc16 nz, de
	extz xde
	ld xwa, 0x87000e
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

AppEvent_SendVoiceUpdate:
	ld xde, xwa
	ld xwa, 0x810003
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

AppEvent_SendPlayStatus:
	ld xde, xwa
	ld xwa, 0x850004
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

; NoteEditSy scroll reset dispatch
NoteEditSy_ScrollReset:
	ld xde, xwa
	ld xwa, 0x850006
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

AppEvent_SendAccompStatus:
	ld xde, xwa
	ld xwa, 0x860007
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

; NoteEditSy scroll case 1
NoteEditSy_ScrollCase1:
	ld xde, xwa
	ld xwa, 0x87000d
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

; NoteEditSy scroll case 2
NoteEditSy_ScrollCase2:
	ld xde, xwa
	ld xwa, 0x880004
	ld xbc, 0x1e0003b
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollReset:
	ld c, (0x8c9c:16)
	ld xwa, (0x2972:16)
	cp C,0x99
	jr z, NoteEditSy_ScrollCase4
	cp C,0x96
	jr z, NoteEditSy_ScrollCase4
	cp C,0x7a
	jr z, NoteEditSy_ScrollCase3
	cp C,0x78
	jr z, NoteEditSy_ScrollCase3
	extz BC
	sub BC,0x0081
	cps bc, 0
	ret LT
	.byte 0xd9, 0xdf, 0xb0, 0xfa, 0xd9, 0x81, 0xf2, 0x42
	.byte 0x4a, 0xe4, 0x34, 0xd3, 0x07, 0xf0, 0xe4, 0x21
	.byte 0xf2, 0x16, 0x65, 0xf4, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe4, 0xd8
NoteEditSy_ModeDispatch:
	ld xwa, 0x810005
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

NoteEditSy_Dispatch85:
	ld xwa, 0x850007
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

NoteEditSy_Dispatch87:
	ld xwa, 0x870003
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

; NoteEditSy scroll case 3
NoteEditSy_ScrollCase3:
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

; NoteEditSy scroll case 4
NoteEditSy_ScrollCase4:
	ld xbc, 0x1c0000f
	lds32 xde, 3
	jr NoteEditSy_DeliverEvent

NoteEditSy_DeliverParam7:
	ld xbc, 0x1c0000f
	lds32 xde, 7

NoteEditSy_DeliverEvent:
	call ApDeliveryEvent

NoteEditSy_DeliverReturn:
	ret

SeqMode_SendStatusUpdate:
	ld	a, (35996:16)
	cp	a, 135
	jr	z, 38
	cp	a, 133
	jr	z, 19
	cp	a, 129
	ret	nz
	ld	xwa, 8454149
	ld	xbc, 29360143
	lds32	xde, 1
	jr	26
SeqMode_Status85:
	ld xwa, 0x850007
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jr SeqMode_StatusDeliver

SeqMode_Status87:
	ld xwa, 0x870003
	ld xbc, 0x1c0000f
	lds32 xde, 1

SeqMode_StatusDeliver:
	call ApDeliveryEvent
	ret

SeqAccomp_SendStopNotify:
	ld	a, (35996:16)
	cp	a, 133
	jr	z, 5
	cp	a, 135
	ret	nz
SeqAccomp_StopNotifyDeliver:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	call ApDeliveryEvent
	ret

SngSelSyori:
	pushw_erp 0xfa
	ld a, (0x00ffe3:24)
	ldb_erp A, 0xfb
	cp xbc, 0x1c00018
	jr z, SngSel_HandleNextSong
	cp xbc, 0x1c00017
	jr z, SngSel_HandlePrevSong
	cp xbc, 0x1c0000b
	jr nz, SeqAcc_CheckLoopAndSendEvent
	stda32 0x29c6, xde
	ld xwa, xde
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent
	jr SeqAcc_CheckLoopAndSendEvent
SngSel_HandlePrevSong:
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	nz, 102
	cp_erpb	251, 9
	jr	nc, 96
	stb_erp	a, 251
	ld	(7500:16), a
	ld	a, (65507:24)
	inc	1, a
	ld	(7502:16), a
	call	15859883
	cp	(35996:16), 129
	jr	nz, 55
	calr	-5776
	lds32	xwa, 0
	jr	45
SngSel_HandleNextSong:
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	nz, 54
	cpib_erp	251, 0
	jr	z, 49
	stb_erp	a, 251
	ld	(7500:16), a
	ld	a, (65507:24)
	dec	1, a
	ld	(7502:16), a
	call	15859883
	cp	(35996:16), 129
	jr	nz, 8
	calr	-5823
	lds32	xwa, 0
SngSel_SendVoiceUpdate:
	calr AppEvent_SendVoiceUpdate

SeqAcc_ResetAndReinit:
	resda 0, 0x28b1
	resda 3, 0x28a7
	call SeqAcc_InitPlaybackState

SeqAcc_CheckLoopAndSendEvent:
	ld a, (0x00ffe3:24)
	cpb_erp A, 0xfb
	jr z, NoteEditSy_UpScrollTable
	ld xwa, (0x29c6:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call ApDeliveryEvent

; NoteEditSy up-scroll table
NoteEditSy_UpScrollTable:
	lds32 xhl, 0
	popw_erp 0xfa
	ret

SoundCtrl_SaveAndSendCmd_EE:
	ld	(32422:16), a
	ldw	wa, 238
	jp	16355504
SoundCtrl_SendCmd_EE:
	ldw wa, 0xee
	jp SoundCtrl_SendCommand

NoteEditSyori:
	cp xbc, 0x1c00018
	jrl z, NoteEditSy_HandleDownScroll
	cp xbc, 0x1c00017
	jr z, NoteEditSy_HandleUpScroll
	cp xbc, 0x1c0000b
	jrl nz, NoteEditSy_ReturnZero
	stda32 0x2972, xde
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
	call_24 z, NoteEditSy_UpdateEditModeGrid
	calr NoteEditSy_UpdateNoteDisplay
	bit 0, (0x295f:16)
	jrl z, NoteEditSy_ReturnZero
	call BmDrEdit_PrepareSecondaryNoteDisplay
	jrl NoteEditSy_ReturnZero

NoteEditSy_HandleUpScroll:
	cp xde, 0xe
	jrl ugt, NoteEditSy_ReturnZero
	add xde, xde
	add xde, WidgetData_CharsetMappingTable_0x434
	ld de, (xde)
	lda xix, (NoteEditSy_UpScroll_Param0:24)
	jp_ind 8, 0x07, 0xf0, 0xe8

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
	add xde, WidgetData_CharsetMappingTable_0x41C
	ld de, (xde)
	lda xix, (NoteEditSy_DownScroll_Param0:24)
	jp_ind 8, 0x07, 0xf0, 0xe8

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
	call BmDrEdit_DrumVoiceUp_Check

NoteEditSy_ReturnZero:
	lds32 xhl, 0
	ret

NoteEditSy_SendScrollCmd0:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd1:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 1
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd2:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 2
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd0:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
	lds32 xde, 0
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd1:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
	lds32 xde, 1
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd2:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
	lds32 xde, 2
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd3or4:
	lds32 xde, 3
	bit 0, (0x2742:16)
	jr z, NoteEditSy_SendWidgetCmdDispatch
	lds32 xde, 4

NoteEditSy_SendWidgetCmdDispatch:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
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
	ldw_erp WA, 0xfa
	ld iz, (9830:16)
	ldmw2 (xsp + 4), 0x275e
	ldmi16 (xsp + 6), 0x2760
	call BmDrEdit_LoadAlternateAndCountNotes
	stw_erp WA, 0xfa
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
	ld xbc, 0x1c80004
	lds32 xde, 5
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
	ld xbc, 0x1c80004
	lds32 xde, 7
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollCmd:
	ld xwa, (0x2972:16)
	bit 0, (0x2742:16)
	jr z, NoteEditSy_SendScrollCmdEdit
	ld xbc, 0x1c0000f
	ld xde, 0x9
	jr NoteEditSy_JumpFA9E07

NoteEditSy_SendScrollCmdEdit:
	ld xbc, 0x1c0000f
	lds32 xde, 6

NoteEditSy_JumpFA9E07:
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd3:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 3
	jp ApDeliveryEvent

NoteEditSy_SendVelocityCmd:
	ldmm8 0x296a, 0x278a
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0xa
	jp ApDeliveryEvent

NoteEditSy_SendGateCmd:
	ldmm8 0x296a, 0x2788
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 4
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd5:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	lds32 xde, 5
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd8:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c0000f
	ld xde, 0x8
	jp ApDeliveryEvent

NoteEditSy_SendModeWidgetCmd:
	ld xwa, (0x2972:16)
	bit 0, (0x2742:16)
	jr z, NoteEditSy_WidgetCmdEdit
	ld xbc, 0x1c80004
	ld xde, 0xd
	jr NoteEditSy_JumpFA9E07_2

NoteEditSy_WidgetCmdEdit:
	ld xbc, 0x1c80004
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
	ld xbc, 0x1c80004
	ld xde, 0x9
	call ApDeliveryEvent
	inc 4, xsp
	ret

NoteEditSy_SendWidgetCmdC:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
	ld xde, 0xc
	jp ApDeliveryEvent
NoteEditSy_DisplayUpdateData:
	dec	4, xsp
	.byte 0xd1
	jr	gt, 39
	pop_f
	swi	6
	ldb	l, 193
	jr	nov, 39
	ldb	a, 216
	ccf
	ld	(0x2800:16), wa
	.byte 0xd1
	jr	nz, 39
	pop_f
	push	sr
	pushw	wa
	ld	a, (0x2770:16)
	extz	wa
	ld	(0x2804:16), wa
	lda	xwa, (xsp+2)
	lda	xbc, (xsp)
	call	BmDrEdit_SetupScrollRegion
	.byte 0x8f
	push	sr
	pop_f
	ldb	b, 40
	.byte 0x87
	pop_f
	ldb	d, 40
	ld	xwa, (0x2972:16)
	ld	xbc, 0x01c80004
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
	ld xbc, 0x1c80004
	ld xde, 0xb
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmdE:
	ld xwa, (0x2972:16)
	ld xbc, 0x1c80004
	ld xde, 0xe
	jp ApDeliveryEvent

SeqModeFunc:
	cp xbc, 0x1c00013
	jr nz, SeqErecMode_ReturnZero
	cp xde, 0x1
	jr z, SeqErec_ClearPlayFlags
	or xde, xde
	jr nz, SeqErecMode_ReturnZero
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	resda 5, 0x28b3
	calr SeqIndicator_HideBoth
	jr SeqErecMode_ReturnZero

SeqErec_ClearPlayFlags:
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	resda 2, 0x28a7
	resda 0, 9834
	resda 4, 0x28ad

SeqErecMode_ReturnZero:
	lds32 xhl, 0
	ret

SeqErecModeFunc:
	cp xbc, 0x1c00013
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
	lds32 xhl, 0
	ret

SeqPlayModeFunc:
	.byte 0xe9, 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x6e, 0x2e
	.byte 0xea, 0xcf, 0x01, 0x00, 0x00, 0x00, 0x66, 0x1d
	.byte 0xea, 0xe2, 0x6e, 0x22, 0x1d, 0x39, 0xe1, 0xf3
	.byte 0xf1, 0xf2, 0xe2, 0x00, 0x00, 0xf1, 0x6a, 0x26
	.byte 0xb0, 0xf1, 0x21, 0x04, 0xca, 0x6e, 0x0f, 0x1d
	.byte 0xb5, 0x96, 0xf5, 0x68, 0x09
SeqPlayMode_SaveAndCleanup:
	call	16004686
	ld	(58098:16), 0
SeqPlayMode_ReturnZero:
	lds32 xhl, 0
	ret

SeqRealModeFunc:
	pushw iz
	cp xbc, 0x1c00013
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
	call	16352117
	call	15966655
	ldw	(10408:16), 0
	call	16635550
	call	16004686
	ldw	wa, 76
	call	16544114
	ld	(9980:16), 0
	.byte 0xf1, 0xe2, 0x26, 0xb0
	ld	a, (10417:16)
	bit	0, a
	jr	z, 65
	call	16005505
	ld	wa, (9500:16)
	ld	(9832:16), wa
	ld	wa, (9500:16)
	call	15982552
	ld	(9000:16), hl
	ld	(1052:16), hl
	ld	(1051:16), 0
	ld	wa, (9502:16)
	call	15982555
	ld	(9002:16), hl
	cpdi16	9832, 1
	jr	nz, 6
	.byte 0xf1, 0xa7, 0x28, 0xb3
	jr	15
SeqReal_SetBarFlag:
	setda 3, 0x28a7
	jr SeqAcc_SaveChannelAndReinit

SeqReal_CheckAccompBit:
	bit 1, a
	jr z, SeqAcc_ProcessedReturn
	resda 3, 0x28a7

SeqAcc_SaveChannelAndReinit:
	ld iz, (0xf19e:16)
	ldmm_sd24w 0xec, 0xff, 0x00, 0x9e, 0xf1
	call SeqAcc_InitPlaybackState
	ld (0xf19e:16), iz

SeqAcc_ProcessedReturn:
	lds32 xhl, 0
	popw iz
	ret

SeqEditModeFunc:
	cp xbc, 0x1c00013
	jr nz, SeqEdit_ReturnZero
	cp xde, 0x1
	jr z, SeqEdit_RestoreAndClear
	or xde, xde
	jr nz, SeqEdit_ReturnZero
	call SeqAcc_SetIndicator_PB
	setda 2, 0x28a7
	jr SeqEdit_ReturnZero

SeqEdit_RestoreAndClear:
	call SeqAcc_RestorePlaybackState
	resda 2, 0x28a7

SeqEdit_ReturnZero:
	lds32 xhl, 0
	ret

SqRealRecTitleFunc:
	.byte 0xd7, 0xfa, 0x04, 0xe9, 0xcf, 0x13, 0x00, 0xc0
	.byte 0x01, 0x7e, 0x89, 0x00, 0xea, 0xcf, 0x03, 0x00
	.byte 0x00, 0x00, 0x66, 0x76, 0xea, 0xcf, 0x02, 0x00
	.byte 0x00, 0x00, 0x6e, 0x79, 0xc1, 0x9d, 0x8c, 0x3f
	.byte 0x83, 0x6e, 0x72, 0xc1, 0xfc, 0x26, 0x3f, 0x01
	.byte 0x6e, 0x6b, 0xf1, 0x24, 0x25, 0x00, 0x01, 0xf1
	.byte 0xa8, 0x28, 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6
	.byte 0xfd, 0xc7, 0xfb, 0xa9
SqRealRec_SetBitMaskLoop:
	stb_erp A, 0xfb
	extz wa
	lds bc, 1
	call SeqVoice_SetOrClearBitMask
	inc1b_erp 0xfb
	cpib_erp 0xfb, 5
	jr ule, SqRealRec_SetBitMaskLoop
	lds wa, 0
	ldw bc, 0xd
	call Part_FindVoiceByByte
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 5
	jr ugt, SqRealRec_DetectAndInit
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	ldw de, 0xe
	call Part_WriteSubBlock32
	stb_erp A, 0xfb
	dec 1, a
	ld (0x28be:16), a

SqRealRec_DetectAndInit:
	call	15982646
	call	16635550
	call	15965303
	ld	(9508:16), 0
	jr	11
SqRealRec_HandleExitState:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x0a, 0x66, 0x04, 0xf1
	.byte 0xec, 0x8c, 0xb0
SqRealRec_ReturnZero:
	lds32 xhl, 0
	popw_erp 0xfa
	ret
SqPlayTitleFunc:
	cp	xbc, 29360147
	jr	nz, 64
	cp	xde, 3
	jr	z, 45
	cp	xde, 2
	jr	nz, 48
	.byte 0xf1, 0xb1, 0x28, 0xc8
	jr	z, 42
	.byte 0xf1, 0x21, 0x04, 0xca
	jr	nz, 36
	cp	(35997:16), 130
	jr	z, 29
	.byte 0xd1, 0x1c, 0x25, 0x19, 0x68, 0x26
	call	15984765
	.byte 0xd1, 0x9e, 0xf1, 0x19, 0x38, 0x28
	jr	11
SqPlay_HandleExitState:
	cp	(35992:16), 1
	jr	z, 4
	.byte 0xf1, 0xec, 0x8c, 0xb0
SqPlay_ReturnZero:
	lds32 xhl, 0
	ret

SqQtzTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqQtzTtl_ReturnZero
	cp xde, 0x3
	jr z, SqQtzTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqQtzTtl_ReturnZero
	cp (0xf1f1:16), 17
	jr nz, SqQtz_ClearBit4
	setda 4, 9702
	jr SqQtzTtl_ReturnZero

SqQtz_ClearBit4:
	resda 4, 9702

SqQtzTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMdelTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqMdelTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMdelTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMdelTtl_ReturnZero
	cp (0xf1d6:16), 17
	jr nz, SqMdel_ClearBit0
	setda 0, 9702
	jr SqMdelTtl_ReturnZero

SqMdel_ClearBit0:
	resda 0, 9702

SqMdelTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMersTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqMersTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMersTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMersTtl_ReturnZero
	cp (0xf1db:16), 17
	jr nz, SqMers_ClearBit1
	setda 1, 9702
	jr SqMersTtl_ReturnZero

SqMers_ClearBit1:
	resda 1, 9702

SqMersTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqVcngTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqVcngTtl_ReturnZero
	cp xde, 0x3
	jr z, SqVcngTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqVcngTtl_ReturnZero
	cp (0xf228:16), 17
	jr nz, SqVcng_ClearBit5
	setda 5, 9702
	jr SqVcngTtl_ReturnZero

SqVcng_ClearBit5:
	resda 5, 9702

SqVcngTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqTrnsTitleFunc:
	lds32 xhl, 0
	ret

SqNcngTitleFunc:
	lds32 xhl, 0
	ret

SqSoclTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqMcpy_ReturnZero
	cp xde, 0x3
	jr z, SqMcpy_ReturnZero
	cp xde, 0x2
	jr nz, SqMcpy_ReturnZero
	ldmm_sd24b 0xe3, 0xff, 0x00, 0x78, 0x28

SqMcpy_ReturnZero:
	lds32 xhl, 0
	ret

SqMcpyTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqMcpyTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMcpy_HandleExitState
	cp xde, 0x2
	jr nz, SqMcpyTtl_ReturnZero
	cp (0xf1e9:16), 17
	jr nz, SqMcpy_ClearBit3
	setda 3, 9702
	jr SqMcpyTtl_ReturnZero

SqMcpy_ClearBit3:
	resda 3, 9702
	jr SqMcpyTtl_ReturnZero

SqMcpy_HandleExitState:
	ld wa, (0x2875:16)
	ordm16_24 (0xffec), xwa

SqMcpyTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMinsTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqMinsTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMins_HandleExitState
	cp xde, 0x2
	jr nz, SqMinsTtl_ReturnZero
	cp (0xf1e1:16), 17
	jr nz, SqMins_ClearBit2
	setda 2, 9702
	jr SqMinsTtl_ReturnZero

SqMins_ClearBit2:
	resda 2, 9702
	jr SqMinsTtl_ReturnZero

SqMins_HandleExitState:
	ldmmw_dd24 0xec, 0xff, 0x00, 0x75, 0x28

SqMinsTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqTrclTitleFunc:
	cp xbc, 0x1c00013
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
	anddm16_24 (0xffec), xwa

SqSngcp_ReturnZero:
	lds32 xhl, 0
	ret

SqSngcpTitleFunc:
	cp xbc, 0x1c00013
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
	lds32 xhl, 0
	ret

SqTrmgTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqTrmg_ReturnZero
	cp xde, 0x3
	jr nz, SqTrmg_ReturnZero
	ld wa, (0x2875:16)
	ordm16_24 (0xffec), xwa

SqTrmg_ReturnZero:
	lds32 xhl, 0
	ret

SqAdlyTitleFunc:
	lds32 xhl, 0
	ret

SqPunchTitleFunc:
	cp xbc, 0x1c00013
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
	lds32 xhl, 0
	ret

SqPunchmTitleFunc:
	cp xbc, 0x1c00013
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
	lds32 xhl, 0
	ret

SqNoteSelTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqNoteSel_HandleReturn
	cp xde, 0x3
	jr z, SqNoteSel_HandleReturn
	cp xde, 0x2
	jr nz, SqNoteSel_HandleReturn
	resda 0, 0x2742

SqNoteSel_HandleReturn:
	lds32 xhl, 0
	ret

SqNoteEdtTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqNoteEdt_ReturnZero
	cp xde, 0x3
	call_24 z, BmDrEdit_CleanupMelodicMode

SqNoteEdt_ReturnZero:
	lds32 xhl, 0
	ret

SqDrmSelTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqDrmSel_HandleReturn
	cp xde, 0x3
	jr z, SqDrmSel_HandleReturn
	cp xde, 0x2
	jr nz, SqDrmSel_HandleReturn
	resda 0, 0x295b
	setda 0, 0x2742

SqDrmSel_HandleReturn:
	lds32 xhl, 0
	ret

SqDrmEdtTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqDrmEdt_ReturnZero
	cp xde, 0x3
	call_24 z, BmDrEdit_CleanupDrumMode

SqDrmEdt_ReturnZero:
	lds32 xhl, 0
	ret

SdRevsetTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SdRevset_ReturnZero
	cp xde, 0x3
	jr z, SdRevset_ClearFlag
	cp xde, 0x2
	jr nz, SdRevset_ReturnZero

SdRevset_ClearFlag:
	ld	(58096:16), 0
SdRevset_ReturnZero:
	lds32 xhl, 0
	ret

SdDspeffTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SdDspeff_ReturnZero
	cp xde, 0x3
	jr z, SdDspeff_ClearFlag
	cp xde, 0x2
	jr nz, SdDspeff_ReturnZero

SdDspeff_ClearFlag:
	ld	(58096:16), 0
SdDspeff_ReturnZero:
	lds32 xhl, 0
	ret

SdAccillTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SdAccill_ReturnZero
	cp xde, 0x3
	jr z, SdAccill_ClearFlag
	cp xde, 0x2
	jr nz, SdAccill_ReturnZero

SdAccill_ClearFlag:
	ld	(58096:16), 0
SdAccill_ReturnZero:
	lds32 xhl, 0
	ret

SqNoteCycpTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqNoteCycp_ReturnZero
	cp xde, 0x3
	call_24 z, BmDrEdit_ExitPlayMode

SqNoteCycp_ReturnZero:
	lds32 xhl, 0
	ret

SqDrmCycpTitleFunc:
	cp xbc, 0x1c00013
	jr nz, SqDrmCycp_ReturnZero
	cp xde, 0x3
	call_24 z, BmDrEdit_ExitPlayMode

SqDrmCycp_ReturnZero:
	lds32 xhl, 0
	ret

HelpModeFunc:
	cp xbc, 0x1c00013
	jr nz, HelpMode_ReturnZero
	cp xde, 0x1
	jr z, HelpMode_ReturnZero
	or xde, xde
	call_24 z, AccWrap_PlayModeDispatch

HelpMode_ReturnZero:
	lds32 xhl, 0
	ret

HelpTitleFunc:
	lds32 xhl, 0
	ret

EtmenuTitleFunc:
	.byte 0xe9, 0xcf, 0x13, 0x00, 0xc0, 0x01, 0x7e, 0x9f
	.byte 0x00, 0xea, 0xcf, 0x07, 0x00, 0x00, 0x00, 0x76
	.byte 0x91, 0x00, 0xea, 0xcf, 0x03, 0x00, 0x00, 0x00
	.byte 0x76, 0x83, 0x00, 0xea, 0xcf, 0x02, 0x00, 0x00
	.byte 0x00, 0x7e, 0x84, 0x00, 0xf1, 0xf0, 0xe2, 0x00
	.byte 0x00, 0xc1, 0x98, 0x8c, 0x3f, 0x07, 0x6e, 0x78
	.byte 0x40, 0x03, 0x00, 0xd6, 0x00, 0xd9, 0xa9, 0x1d
	.byte 0x7f, 0x5a, 0xfa, 0x40, 0x04, 0x00, 0xd6, 0x00
	.byte 0xd9, 0xa9, 0x1d, 0x7f, 0x5a, 0xfa, 0x40, 0x05
	.byte 0x00, 0xd6, 0x00, 0xd9, 0xa9, 0x1d, 0x7f, 0x5a
	.byte 0xfa, 0x40, 0x06, 0x00, 0xd6, 0x00, 0xd9, 0xa9
	.byte 0x1d, 0x7f, 0x5a, 0xfa, 0x40, 0x03, 0x00, 0xd6
	.byte 0x00, 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x04, 0x00, 0xd6
	.byte 0x00, 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x05, 0x00, 0xd6
	.byte 0x00, 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0x40, 0x06, 0x00, 0xd6
	.byte 0x00, 0x41, 0x0d, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0xfa, 0x99, 0xfa, 0x68, 0x0a
MainExe_DispatchEntry:
	ld	(58096:16), 0
MainExe_DispatchReturn:
	lds wa, 0
	calr VoiceParam_SetD6Group

EtmenuTtl_ReturnZero:
	lds32 xhl, 0
	ret

MainExeCall:
	ld	a, (35996:16)
	cp	a, 145
	jrl	z, 251	; -> 0xF4719B
	cp	a, 141
	jrl	z, 236	; -> 0xF47192
	cp	a, 144
	jrl	z, 175	; -> 0xF4715B
	cp	a, 134
	jrl	z, 142	; -> 0xF47140
	cp	a, 133
	jr	z, 71	; -> 0xF470FE
	cp	a, 131
	jr	z, 60	; -> 0xF470F8
	cp	a, 214
	jr	z, 40	; -> 0xF470E9
	extz	wa
	sub	wa, 154
	cps	wa, 0
	jrl	lt, 1086	; -> 0xF4750A
	cp	wa, 16
	jrl	gt, 1079	; -> 0xF4750A
	add	wa, wa
	lda	xix, (14961288:24)
	ld_rrw	wa, xix, wa
	lda	xix, (16019689:24)
	jp_rr	8, xix, wa
MainExe_HandleD6:
	call	16648347
	call	16626122
	call	16005707
	jrl	1042
MainExe_Handle83:
	calr MainExe_SequencerStop
	jrl MainExe_ReturnZero

MainExe_Handle85:
	and e, 0xf
	cp e, 0xa
	jr nz, MainExe_Handle85_SubE9
	ld a, (1057:16)
	and a, 0x14
	jrl z, MainExe_ReturnZero
	cpdi16 0x28a8, 0
	jrl z, MainExe_ReturnZero
	setda 1, 9834
	call SeqPlay_ProcessVoiceAndNotes
	jrl MainExe_ReturnZero

MainExe_Handle85_SubE9:
	cp e, 0x9
	jrl nz, MainExe_ReturnZero
	bit 1, (0x28b1:16)
	jrl z, MainExe_ReturnZero
	bit 2, (0x28b2:16)
	jr z, MainExe_StartSongPlay
	bit 2, (1057:16)
	jr nz, MainExe_StartSongPlay
	jrl MainExe_ReturnZero

MainExe_Handle86:
	bit 1, (0x28b1:16)
	jrl z, MainExe_ReturnZero
	bit 2, (0x28b2:16)
	jr z, MainExe_StartSongPlay
	bit 2, (1057:16)
	jrl z, MainExe_ReturnZero

MainExe_StartSongPlay:
	call SeqPlay_CheckDrumAndStart
	jrl MainExe_ReturnZero

MainExe_Handle90:
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16029308
	call	15997352
	ld	a, (65507:24)
	cpda8	a, 10360
	jr	nz, 13
	ldw	(10357:16), 0
	stiw_da	65516, 0
MainExe_Handle90_Finish:
	ldw wa, 0x23

	.byte 0x1e, 0xf2, 0xf4	; calr SoundCtrl_SaveAndSendCmd_EE (v7 displacement)

	.byte 0xf1, 0xec, 0x8c, 0xb0	; resda 0, 0x8d88 (v7 patched)

	.byte 0x78, 0x78, 0x03	; jrl MainExe_ReturnZero (v7 displacement)



MainExe_Handle8D:
	call	16625030
	ldw	wa, 35
	jr	112
MainExe_Handle91:
	call SeqStep_TrackChange

MainExe_SongMemoryLoop:
	calr SoundCtrl_SendCmd_EE
	jrl MainExe_ReturnZero
	cpdi16 9704, 0
	jr nz, MainExe_SongMemStart
	ldw wa, 0x9a
	jrl MainExe_CallModeSwitch

MainExe_SongMemStart:
	ld (0x2877:16), 1

MainExe_SongMemIterLoop:
	ld a, (0x2877:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_SongMemShiftMask
	slaa bc

MainExe_SongMemShiftMask:
	andda16	xbc, (9704)
	jr	z, 14	; -> 0xF471DB
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	SeqVoice_InitJmpNop
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
	.byte 0x1e, 0x6f, 0xf4, 0x78, 0xf9, 0x02, 0xc1, 0xd3
	.byte 0xf1, 0x19, 0x77, 0x28, 0xc1, 0xd4, 0xf1, 0x19
	.byte 0x82, 0x26, 0xc1, 0xd5, 0xf1, 0x19, 0x84, 0x26
	.byte 0xf1, 0xa6, 0x7e, 0x00, 0xff, 0xf1, 0x7a, 0x28
	.byte 0x00, 0x00, 0x1d, 0x21, 0x98, 0xf4, 0xc1, 0x77
	.byte 0x28, 0x21, 0xc9, 0x69, 0xd9, 0xa9, 0xc9, 0xcc
	.byte 0x0f, 0x66, 0x02, 0xd9, 0xfc
MainExe_ClearPartMask1:
	cpl bc
	anddm16 0x2875, xbc
	ld a, (0x2877:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_ClearPartMask2
	slaa bc

MainExe_ClearPartMask2:
	cpl bc
	anddm16_24 (0xffec), xbc
	ld a, (9858:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_ClearPartMask3
	slaa bc

MainExe_ClearPartMask3:
	cpl bc
	anddm16 0x2875, xbc
	ld a, (9858:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_ClearPartMask4
	slaa bc

MainExe_ClearPartMask4:
	cpl bc
	anddm16_24 (0xffec), xbc
	ld a, (9860:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_SetPartMask
	slaa bc

MainExe_SetPartMask:
	orddm16 0x2875, xbc
	ld a, (9860:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_SetPartMaskFFE0
	slaa bc

MainExe_SetPartMaskFFE0:
	ordm16_24	(65516), bc
	ld	a, (32422:16)
	cp	a, 255
	jr	nz, 6
	ldw	wa, 155
	jrl	762
MainExe_CheckResultCode:
	cp a, 0x23
	jrl z, MainExe_SongMemoryLoop
	ld a, (0x2877:16)
	dec 1, a
	lds bc, 1
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
	lds de, 1
	and a, 0xf
	jr z, MainExe_MaskSecondary
	slaa de

MainExe_MaskSecondary:
	cpl de
	and bc, de
	ld a, (9860:16)
	dec 1, a
	lds de, 1
	and a, 0xf
	jr z, MainExe_MaskTertiary
	slaa de

MainExe_MaskTertiary:
	cpl de
	and bc, de
	ld (0x2875:16), bc
	jrl MainExe_SongMemoryLoop
	ld a, (0xf1f1:16)
	cp a, 0x11
	jr nz, MainExe_StorePartDirect
	ld (0x2877:16), 127
	jr MainExe_PatternLoad

MainExe_StorePartDirect:
	ld (0x2877:16), a
MainExe_PatternLoad:
	ld	wa, (61938:16)
	ld	(9778:16), wa
	ld	wa, (9724:16)
	subda16 xwa, (61938)
	inc	1, wa
	ld	(9694:16), wa
	ld	a, (61942:16)
	sll	a, 1
	ld	(9726:16), a
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16039609
	cp	(32422:16), 255
	jrl	nz, -437
	ldw	wa, 156
	jrl	605
	.byte 0xc1, 0x1c, 0x26, 0x19, 0x77, 0x28
	ld	wa, (9758:16)
	ld	(9778:16), wa
	ld	wa, (9760:16)
	subda16 xwa, (9758)
	inc	1, wa
	ld	(9694:16), wa
	call	16041187
	cp	(32422:16), 255
	jrl	nz, -483
	ldw	wa, 157
	jrl	559
	ld	a, (61992:16)
	cp	a, 17
	jr	nz, 7
	ld	(10359:16), 127
	jr	4
MainExe_RhythmStorePartDirect:
	ld (0x2877:16), a
MainExe_RhythmLoad:
	ld	wa, (61993:16)
	ld	(9778:16), wa
	ld	wa, (9722:16)
	subda16 xwa, (61993)
	inc	1, wa
	ld	(9694:16), wa
	.byte 0xc1, 0x2e, 0xf2, 0x19, 0x54, 0x26
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16039177
	cp	(32422:16), 255
	jrl	nz, -559
	ldw	wa, 158
	jrl	483
	.byte 0xc1, 0x0e, 0x26, 0x19, 0x77, 0x28
	ld	wa, (9744:16)
	ld	(9778:16), wa
	ld	wa, (9746:16)
	subda16 xwa, (9744)
	inc	1, wa
	ld	(9694:16), wa
	call	16041623
	cp	(32422:16), 255
	jrl	nz, -605
	ldw	wa, 159
	jrl	437
	.byte 0xc1, 0x04, 0x26, 0x19, 0x77, 0x28
	ld	wa, (9734:16)
	ld	(9778:16), wa
	ld	wa, (9736:16)
	subda16 xwa, (9734)
	inc	1, wa
	ld	(9694:16), wa
	call	16042080
	cp	(32422:16), 255
	jrl	nz, -651
	ldw	wa, 160
	jrl	391
	ld	a, (61915:16)
	cp	a, 17
	jr	nz, 7
	ld	(10359:16), 127
	jr	4
MainExe_AccompStorePartDirect:
	ld (0x2877:16), a
MainExe_AccompLoad:
	ld	wa, (61916:16)
	ld	(9778:16), wa
	ld	wa, (9766:16)
	subda16 xwa, (61916)
	inc	1, wa
	ld	(9694:16), wa
	.byte 0xc1, 0xe0, 0xf1, 0x19, 0x50, 0x26
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16032000
	cp	(32422:16), 255
	jrl	nz, -727
	ldw	wa, 161
	jrl	315
	ld	wa, (61930:16)
	ld	(9778:16), wa
	.byte 0xd1, 0xef, 0xf1, 0x19, 0x86, 0x26
	ld	wa, (9768:16)
	subda16 xwa, (61930)
	inc	1, wa
	ld	(9694:16), wa
	.byte 0xc1, 0xee, 0xf1, 0x19, 0x82, 0x26
	ld	a, (61929:16)
	cp	a, 17
	jr	nz, 7
	ld	(10359:16), 127
	jr	4
MainExe_SongLoadStorePartDirect:
	ld (0x2877:16), a

MainExe_SongLoad:
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16035303
	ld	a, (32422:16)
	cp	a, 255
	jr	nz, 6
	ldw	wa, 162
	jrl	232
MainExe_SongLoadCheckRedirect:
	.byte 0xc9, 0xcf, 0x23, 0x6e, 0x11, 0x1d, 0x52, 0xfd
	.byte 0xf3, 0xc1, 0xa6, 0x7e, 0x3f, 0xff, 0x6e, 0x06
	.byte 0x30, 0xa2, 0x00, 0x78, 0xd2, 0x00
MainExe_SongLoadFinish:
	.byte 0x1e, 0xa0, 0xf1, 0xc1, 0xa6, 0x7e, 0x3f, 0x23
	.byte 0x66, 0x1b, 0xc1, 0x77, 0x28, 0x3f, 0x7f, 0x76
	.byte 0xda, 0x00
MainExe_SetPartBitMask:
	ld a, (9858:16)
	dec 1, a
	lds bc, 1
	and a, 0xf
	jr z, MainExe_OrPartMask
	slaa bc

MainExe_OrPartMask:
	orddm16 0x2875, xbc

MainExe_ReturnZero:
	lds32 xhl, 0
	ret
MainExe_InlineByteData:
	ld	a, (61910:16)
	cp	a, 17
	jr	nz, 7
	ld	(10359:16), 127
	jr	4
	ld	(10359:16), a
	ld	wa, (61911:16)
	ld	(9778:16), wa
	ld	wa, (9772:16)
	subda16 xwa, (61911)
	inc	1, wa
	ld	(9694:16), wa
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16031261
	cp	(32422:16), 255
	jrl	nz, -942
	ldw	wa, 163
	jr	101
	ld	wa, (61922:16)
	ld	(9778:16), wa
	.byte 0xd1, 0xe7, 0xf1, 0x19, 0x86, 0x26
	ld	wa, (9774:16)
	subda16 xwa, (61922)
	inc	1, wa
	ld	(9694:16), wa
	.byte 0xc1, 0xe6, 0xf1, 0x19, 0x82, 0x26
	ld	a, (61921:16)
	cp	a, 17
	jr	nz, 7
	ld	(10359:16), 127
	jr	4
	ld	(10359:16), a
	ld	(32422:16), 255
	ld	(10362:16), 0
	call	16033136
	ld	a, (32422:16)
	cp	a, 255
	jr	nz, 5
	ldw	wa, 164
	jr	19
	cp	a, 35
	jr	nz, 21
	call	15990216
	cp	(32422:16), 255
	jr	nz, 10
	ldw	wa, 164
MainExe_CallModeSwitch:
	call UI_PostModeChangeEvent
	jrl t, MainExe_ReturnZero
	calr SoundCtrl_SendCmd_EE
	cp (0x7ea6:16), 0x23
	jrl z, MainExe_ReturnZero
	cp (0x2877:16), 0x7f
	jrl nz, MainExe_SetPartBitMask
MainExe_SetAllPartsMask:
	ldw (0x2875:16), 0xffff
	jrl MainExe_ReturnZero

MainExe_SequencerStop:
	ld (7572:16), 0
	call SeqPlay_SaveStateAndCleanup
	ldw wa, 0x4c
	call CtrlPanel_SetIndicatorBit
	resda 1, 0x28b1
	call SeqStatus_CheckBit2
	cps l, 0
	jr nz, MainExe_SeqStopMode1
	lds wa, 0
	call Part_WriteAllVoiceSubBlocks_A
	jr MainExe_SeqStopFinish

MainExe_SeqStopMode1:
	lds wa, 0
	call Part_WriteAllVoiceSubBlocks_B

MainExe_SeqStopFinish:
	.byte 0xd8, 0xa8, 0x31, 0x50, 0x00, 0x32, 0xff, 0xff
	.byte 0x1d, 0x35, 0x15, 0xf4, 0xd8, 0xa8, 0x31, 0x32
	.byte 0x00, 0x1d, 0x4c, 0xf3, 0xf3, 0xf1, 0x9e, 0xf1
	.byte 0x02, 0x00, 0x00, 0x1d, 0x9e, 0xd6, 0xfd, 0x1d
	.byte 0xef, 0x96, 0xf5, 0xf1, 0xa6, 0x28, 0xb0, 0xf2
	.byte 0xec, 0xff, 0x00, 0x02, 0x00, 0x00, 0xf1, 0xfc
	.byte 0x26, 0x00, 0x01, 0x1d, 0x36, 0xe0, 0xf3, 0x30
	.byte 0x0b, 0x00, 0x1b, 0x56, 0x90, 0xf9
MainPanic:
	cp	xbc, 31981686
	jr	nz, 12
	call	16648347
	call	16626122
	call	16005707
MainPanic_ReturnZero:
	lds32 xhl, 0
	ret
HelpLang_DispatchDataBlock:
	ld	a, (49121:16)
	cp	a, 19
	ret	nz
	ld	a, (49122:16)
	ld	(10606:16), a
	cpda8	a, 10608
	ret	z
	cp	a, 49
	ret	ugt
	ld	(10608:16), a
	cp	(35996:16), 231
	ret	nz
	ld	e, (213220:24)
	ld	c, (10606:16)
	extz	bc
	cps	e, 5
	jr	z, 33
	cps	e, 3
	jr	z, 22
	cps	e, 2
	jr	z, 11
	cps	e, 1
	jr	nz, 28
	ld	xwa, 14961372
	jr	26
	ld	xwa, 14961422
	jr	19
	ld	xwa, 14961472
	jr	12
	ld	xwa, 14961522
	jr	5
	ld	xwa, 14961322
	ld_rrb	a, xwa, bc
	cps	a, 1
	jr	nz, 30
	ld	xwa, 15138830
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	ld	xwa, 15138832
	ld	xbc, 29360129
	lds32	xde, 0
	jr	96
	cps	a, 2
	jr	nz, 30
	ld	xwa, 15138839
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	ld	xwa, 15138841
	ld	xbc, 29360129
	lds32	xde, 0
	jr	62
	cps	a, 3
	jr	nz, 30
	ld	xwa, 15138852
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	ld	xwa, 15138854
	ld	xbc, 29360129
	lds32	xde, 0
	jr	28
	ld	xwa, 15138860
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	ld	xwa, 15138863
	ld	xbc, 29360129
	lds32	xde, 0
	call	16423243
	ret
HelpLangChkMain:
	cp	xbc, 31981680
	jr	z, 92
	cp	xbc, 29360129
	jr	nz, 113
	cp	(35996:16), 231
	jr	nz, 45
	cp	(35997:16), 238
	jr	z, 38
	call	15665211
	cps	l, 3
	jr	nz, 14
	ld	xwa, 15138826
	ld	xbc, 29360129
	lds32	xde, 0
	jr	12
HelpLang_SetRegion5:
	ld xwa, Bitmap_MIDIConnections_2_0x3BB3
	ld xbc, 0x1c00001
	lds32 xde, 0

HelpLang_PostEvent:
	call ApPostEvent

HelpLang_SetFlashAndLoadSlide:
	ld (0x2970:16), 255
	ld a, (0x0340e4:24)
	sll a, 2
	ldb w, 0x0
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800
	jr HelpLang_ParseSlideHeader

HelpLang_LoadSlide:
	ld a, (0x0340e4:24)
	sll a, 2
	ldb w, 0x0
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800

HelpLang_ParseSlideHeader:
	call SLIDE_Parse_Header

HelpLangChk_ReturnZero:
	lds32 xhl, 0
	ret

HelpFlashFunc:
	cp xbc, 0x1e80075
	jr z, HelpFlash_DispatchAudio
	cp xbc, 0x1e80074
	jr nz, HelpFlash_ReturnZero
	ldw wa, 0x25
	calr SoundCtrl_SaveAndSendCmd_EE
	lds wa, 4
	call CtrlPanel_IndicatorJumpTable
	ldw wa, 0x23
	calr SoundCtrl_SaveAndSendCmd_EE
	jr HelpFlash_ReturnZero

HelpFlash_DispatchAudio:
	lds wa, 4
	call Audio_DispatchCommand

HelpFlash_ReturnZero:
	lds32 xhl, 0
	ret

SeqIndicator_HideBoth:
	ld xwa, 0x850013
	lds bc, 0
	call SetVisible
	ld xwa, 0x850014
	lds bc, 0
	jp SetVisible

VoiceParam_SetD6Group:
	pushw iz
	cps a, 0
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
	cps wa, 0
	jr ge, SeqLoad_PostInitParts
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoad_PostInitParts:
	.byte 0xd8, 0xa9, 0xd9, 0xac, 0xda, 0xa8, 0x1d, 0x10
	.byte 0x15, 0xf4, 0x1e, 0x33, 0x07, 0x1d, 0x75, 0xe3
	.byte 0xf4, 0xc2, 0xe3, 0xff, 0x00, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x18, 0x14, 0xf4, 0xd1, 0xce, 0xf1, 0x3f
	.byte 0x00, 0x00, 0x66, 0x11, 0x1d, 0xa6, 0xe3, 0xf4
	.byte 0xd2, 0xec, 0xff, 0x00, 0x19, 0x9e, 0xf1, 0x1d
	.byte 0x9e, 0xd6, 0xfd, 0x68, 0x09
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
	cps wa, 0
	jr ge, SeqLoad_AltInitParts
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoad_AltInitParts:
	.byte 0xd8, 0xa9, 0xd9, 0xac, 0xda, 0xa8, 0x1d, 0x10
	.byte 0x15, 0xf4, 0xf2, 0xe3, 0xff, 0x00, 0x00, 0x00
	.byte 0x1d, 0x75, 0xe3, 0xf4, 0xc2, 0xe3, 0xff, 0x00
	.byte 0x21, 0xd8, 0x12, 0x1d, 0x18, 0x14, 0xf4, 0xf2
	.byte 0xec, 0xff, 0x00, 0x16, 0x9e, 0xf1, 0xd1, 0xce
	.byte 0xf1, 0x3f, 0x00, 0x00, 0x66, 0x0a, 0x1d, 0xa6
	.byte 0xe3, 0xf4, 0x1d, 0x9e, 0xd6, 0xfd, 0x68, 0x09
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
	lds wa, 1
	lds bc, 4
	lds de, 1
	call Part_WriteByte
	ld xhl, xiz
	pop xiz
	ret

SeqSavePost:
	pushw iz
	ld IZ,WA
	lds wa, 1
	lds bc, 4
	lds de, 0
	call Part_WriteByte
	cps iz, 0
	jr lt, SeqSave_PostReturn
	resda 0, (0x8cec)
SeqSave_PostReturn:
	popw iz
	ret
SeqLoad_ProcessDataBlock:
	dec	6, xsp
	.byte 0xd7, 0xfa, 0x04
	ld	(xsp+6), a
	lds32	xwa, 0
	ld	(xsp+2), xwa
	ldib_erp	251, 1
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	stb_erp	c, 251
	extz	bc
	call	15996796
	cps	l, 0
	jr	z, 41
	ld	a, (xsp+6)
	inc	1, a
	extz	wa
	stb_erp	c, 251
	extz	bc
	call	15996887
	ld	wa, hl
	cp	wa, 65535
	jr	z, 17
	lds32	xbc, 1
	add	(xsp+2), xbc
	call	15998033
	ld	wa, hl
	cp	wa, 65535
	jr	nz, -17
	inc1b_erp	251
	cp_erpb	251, 16
	jr	ule, -70
	ld	wa, (61999:16)
	cp	wa, 65535
	jr	z, 17
	lds32	xbc, 1
	add	(xsp+2), xbc
	call	15998033
	ld	wa, hl
	cp	wa, 65535
	jr	nz, -17
	ld	xhl, (xsp+2)
	sll	xhl, 8
	ld	(xsp+2), xhl
	pop qiz
	inc	6, xsp
	ret
	dec	2, xsp
	pushw	iz
	ld	(xsp+2), a
	.byte 0xd2, 0xec, 0xff, 0x00, 0x19, 0x9e, 0xf1
	call	16635550
	ld	a, (65507:24)
	extz	wa
	call	15995901
	ld	a, (xsp+2)
	extz	wa
	call	15995928
	ld	a, (xsp+2)
	stb_da	65507, a
	call	15988735
	ld	a, (65507:24)
	extz	wa
	call	15995901
	ld	iz, (61902:16)
	call	16049072
	ld	(61902:16), iz
	popw	iz
	inc	2, xsp
	ret
	dec	8, xsp
	push	xiz
	ld	(xsp+10), a
	cps	bc, 0
	jr	ge, 7
	call	15988735
	jrl	249
	calr	1223
	ld	a, (xsp+10)
	extz	wa
	call	15995928
	calr	1224
	calr	1234
	ld	(xsp+6), hl
	ldib_erp	251, 1
	stb_erp	c, 251
	extz	bc
	lds	wa, 0
	call	15996887
	ld	iz, hl
	cps	iz, 0
	jr	z, 51
	cp	iz, 65535
	jr	z, 45
	.byte 0x9f, 0x06, 0x86
	stb_erp	c, 251
	extz	bc
	lds	wa, 0
	ld	de, iz
	call	15996902
	stb_erp	c, 251
	extz	bc
	lds	wa, 0
	call	15996346
	ld	iz, hl
	.byte 0x9f, 0x06, 0x86
	stb_erp	c, 251
	extz	bc
	lds	wa, 0
	ld	de, iz
	call	15996324
	inc1b_erp	251
	cp_erpb	251, 16
	jr	ule, -77
	.byte 0xbf, 0x08, 0x16, 0xce, 0xf1
	ld	wa, (xsp+8)
	srl	wa, 4
	ld	(xsp+8), wa
	ld	iz, (61999:16)
	ldw	(xsp+4), 0
	.byte 0x9f, 0x08, 0x3f, 0x00, 0x00
	jr	ule, 77
	ld	wa, iz
	.byte 0x9f, 0x04, 0x80
	call	15997995
	ld	bc, hl
	cp	bc, 65535
	jr	z, 16
	cps	bc, 0
	jr	z, 12
	.byte 0x9f, 0x06, 0x81
	ld	wa, iz
	.byte 0x9f, 0x04, 0x80
	call	15998014
	ld	wa, iz
	.byte 0x9f, 0x04, 0x80
	call	15998033
	ld	bc, hl
	cp	bc, 65535
	jr	z, 16
	cps	bc, 0
	jr	z, 12
	.byte 0x9f, 0x06, 0x81
	ld	wa, iz
	.byte 0x9f, 0x04, 0x80
	call	15998052
	incw	1, (xsp+4)
	ld	wa, (xsp+4)
	.byte 0x9f, 0x08, 0xf0
	jr	c, -77
	calr	866
	ldw	(9832:16), 1
	calr	1095
	calr	1741
	ld	a, (xsp+10)
	extz	wa
	call	15995901
	calr	2189
	calr	1777
	call	15977039
	.byte 0xf2, 0xec, 0xff, 0x00, 0x16, 0x9e, 0xf1
	pop	xiz
	inc	8, xsp
	ret
FileIO_WriteBlockToStream:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	lds32 xhl, 0
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
	lds iy, 0

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
	cpdi16 0x29f4, 0
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
	lds32 xhl, 0
	ld bc, (0x29f6:16)
	cps bc, 0
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
	cps l, 0
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
	ldw_erp HL, 0xfa
	ld wa, iz
	stw_erp BC, 0xfa
	calr FileIO_WriteBlockToStream
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jr lt, FileIO_WriteEpilogue
	stw_erp IZ, 0xfa
	incdi16 1, (0x29f4)
	cp iz, 0xffff
	jr nz, FileIO_WriteVoiceChainLoop

FileIO_WritePartAccumulate:
	ld wa, (0x29f4:16)
	adddm16 0x29f2, xwa

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
	dec 6,XSP
	push XIZ
	ld (XSP+0x08),A
	ld a, (0x00ffe3:24)
	cp A,(XSP+0x08)
	jr nz, SeqSave_CopyBlockAndInit
	.byte 0xd2, 0xec, 0xff, 0x00, 0x19, 0x9e, 0xf1, 0x1d
	.byte 0x9e, 0xd6, 0xfd
SeqSave_CopyBlockAndInit:
	ld a, (0x00ffe3:24)
	extz wa
	call SeqData_CopyBlockToBuffer
	ld a, (0x00ffe3:24)
	inc 1, a
	extz wa
	ldw bc, 0xc7
	lds de, 0
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
	ld	a, (xsp+8)
	extz	wa
	calr	915
	ld	xiz, xhl
	cp	xiz, 0
	jrl	lt, 298
	pushw	8224
	call	16713379
	inc	2, xsp
	stda32	(10734), xhl
	or	xhl, xhl
	jr	nz, 6
	ldw	hl, 65533
	jrl	277
SeqSave_WriteAndFree:
	ld	a, (xsp+8)
	extz	wa
	calr	65205
	ld	iz, hl
	exts	xiz
	ld	xwa, (10734:16)
	push	xwa
	call	16712469
	inc	4, xsp
	cp	xiz, 0
	jrl	lt, 243
	lds	bc, 0
	lda	xde, (10702:16)
	ld	xwa, xde
	lda	xde, (xde+32)
SeqSave_CountBlocksLoop:
	add_spiw BC, 0xe1
	cp xwa, xde
	jr c, SeqSave_CountBlocksLoop
	sll bc, 4
	ld xwa, 0x4e
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	lds32 xwa, 4
	lds bc, 0
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
	ldb w, 0x0
	extz xwa
	cpiw_sri 0x07, 0xe8, 0xe4, 0x00, 0x00
	jr nz, SeqSave_WritePartInner
	ldw bc, 0xffff
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	add a, (xsp + 4)
	add a, 0x78
	ldb w, 0x0
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
	ldb w, 0x0
	extz xwa
	ld e, (xsp + 4)
	extz de
	add de, de
	lda xhl, (0x29ce:16)
	ld bc, (xsp + 6)
	add_sriw_rm BC, 0x07, 0xec, 0xe8
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda xbc, (0x29ce:16)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	add (xsp + 6), wa

SeqSave_NextPartLoop:
	incm8 1, (xsp + 4)

	cp (xsp + 4), 0x10

	.byte 0x77, 0x54, 0xff	; jrl c, SeqSave_WritePartDataLoop (v7 displacement)

	.byte 0xf1, 0xec, 0x8c, 0xb0	; resda 0, 0x8d88 (v7 patched)



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
	cps l, 3
	jr z, SeqLoad_FetchPartLength
	cps l, 6
	jr z, SeqLoad_FetchPartLength
	cps l, 7
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
	lds wa, 0
	jr SeqBar_CheckZeroRange

SeqBar_ComputeRange:
	ldw wa, 0x4d8
	sub wa, bc
	inc 1, wa
	call Part_SetAllVoicePos
	ld wa, (0xf231:16)

SeqBar_CheckZeroRange:
	cps wa, 0
	jr z, SeqBar_ReturnDone
	ld iz, (0xf22f:16)
	cp iz, wa
	jr ugt, SeqBar_WriteBoundary

SeqBar_SetPositionLoop:
	ld wa, iz
	lds bc, 0
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	cps iz, 0
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
	cpda16 xiz, 0xf231
	jr ule, SeqBar_SetPositionLoop

SeqBar_WriteBoundary:
	ld wa, (0xf22f:16)
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ldw wa, 0x4d8
	ldw bc, 0xffff
	call PartCtrl_WriteWord

SeqBar_ReturnDone:
	popw iz
	ret

SeqBar_DataBlock:
	.byte 0xd1
	pushw	sp
	.byte 0xf2
	pop_f
	.byte 0xca
	pushw	bc
	.byte 0xd1
	ldw	bc, 6642
	.byte 0xcc
	pushw	bc
	ret
	.byte 0xd1, 0xca
	pushw	bc
	pop_f
	pushw	sp
	.byte 0xf2, 0xd1, 0xcc
	pushw	bc
	pop_f
	ldw	bc, 3826
	lds	hl, 0
	ld	wa, (0xf22f:16)
	cps	wa, 0
	ret	z
	ld	hl, wa
	dec	1, hl
	ret
	dec	4, xsp
	ld	(xsp), bc
	ld	(xsp+2), a
	ld	c, (xsp+2)
	extz	bc
	lds	wa, 0
	call	Part_ReadVoiceWord
	ld	de, hl
	cp	de, 0xffff
	jr	z, 4
	cps	de, 0
	jr	nz, 2
	jr	13
	.byte 0x97
	add	(xde), l
	push	sr
	ldb	c, 217
	ccf
	lds	wa, 0
	call	Part_WriteVoiceWord
	inc	4, xsp
	ret
	lds	wa, 0
	lds	bc, 5
	call	Part_ReadByteDirect
	cps	l, 1
	ret	nz
	lds	wa, 0
	lds	bc, 6
	call	Part_ReadByteDirect
	cps	l, 7
	jr	z, 5
	cp	l, 8
	ret	nz
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
	lds wa, 1
	ldw bc, 0xc7
	call Part_ReadByteDirect
	stb_da (0x00ffe3), l
	lds wa, 1
	ldw bc, 0xc7
	lds de, 0
	call Part_WriteByte
	lds wa, 1
	ldw bc, 0xc8
	call Part_ReadWord
	stw_da (0x00ffec), xhl
	lds wa, 1
	ldw bc, 0xc8
	lds de, 0
	call Part_WriteWord
	ldw (9832:16), 1
	resda 3, 0x28a7
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
	stb_erp A, 0xfb
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (0x29ce:16)
	stiw_ind 0x07, 0xe4, 0xe0, 0x00, 0x00
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqSave_VoiceSizeNextPart
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	call Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xffff
	jr z, SeqSave_VoiceSizeNextPart

SeqSave_VoiceSizeChainLoop:
	stb_erp C, 0xfb
	dec 1, c
	extz bc
	add bc, bc
	lda xde, (0x29ce:16)
	inc_sriw 1, 0x07, 0xe8, 0xe4
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
	ldb b, 0x0
	extz xbc
	sll xbc, 11
	ld xwa, 0xab000
	add xwa, xbc
	ld xbc, 0x800
	jp FileIO_WriteByte_Impl

FileIO_SeekReadAndCheck:
	dec 2, xsp
	ld (xsp), c
	lds bc, 0
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
	lds bc, 0
	call FileIO_SeekAndReadBlock
	exts xhl
	or xhl, xhl
	jr nz, FileIO_Read16Return
	ld wa, iz
	ldb w, 0x0
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
	.byte 0xd3
	reti
	or	xwa, xwa
	push	xsp
	nop
	nop
	jr	nz, 5
	lds32	xhl, 0
	jrl	198
	ld	xwa, 2048
	ld	(xsp+4), xwa
	ldw (xsp+10), 0
	ldw (xsp+8), 0
	ld	c, (xsp+12)
	extz	bc
	cps	bc, 0
	jr	ule, 32
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
	jr	c, -32
	lds32	xwa, 1
	add	(xsp+4), xwa
	.byte 0xbf
	ldio	2, 1
	nop
	jr	55
	ld	xwa, (xsp+4)
	calr	65381
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 5
	ldw	wa, 200
	jr	104
	ld	xwa, (xsp+4)
	inc	2, xwa
	ld	bc, (xsp+10)
	.byte 0x9f
	ldio	129, 217
	jr	lt, 30
	popw	de
	swi	7
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 5
	ldw	wa, 201
	jr	77
	ld	xwa, 256
	add	(xsp+4), xwa
	incw	1, (xsp+8)
	ld	l, (xsp+12)
	extz	hl
	add	hl, hl
	lda	xde, (0x29ce:16)
	ld	bc, (xsp+10)
	.byte 0x9f
	ldio	129, 217
	jr	ge, -97
	ldio	32, 211
	reti
	sla	xwa, 240
	jr	c, -84
	ld	xwa, (xsp+4)
	calr	65297
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 5
	ldw	wa, 202
	jr	20
	ld	xwa, (xsp+4)
	inc	2, xwa
	ldw	bc, 0xffff
	calr	65275
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 7
	ldw	wa, 203
	call	SeqData_SetErrorCode
	ld	xhl, xiz
	pop	xiz
	lda	xsp, (xsp+10)
	ret

SeqLoad_CheckAutoAccompFlag:
	lds wa, 0
	lds bc, 6
	call Part_ReadByteDirect
	cps l, 3
	jr nc, SeqLoad_SkipBitCheck
	setda 0, 0xf23e
	lds wa, 0
	lds bc, 5
	call Part_ReadByteDirect
	cps l, 0
	jr nz, SeqLoad_SkipBitCheck
	lds wa, 0
	lds bc, 6
	call Part_ReadByteDirect
	cps l, 3
	jr nc, SeqLoad_SkipBitCheck
	resda 0, 0xf23e

SeqLoad_SkipBitCheck:
	jr SeqLoad_ClearAutoAccompBit1

SeqLoad_ClearAutoAccompBit1:
	resda 1, 0xf23e
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
	cps l, 0
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
	lds de, 0

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
	cps wa, 0
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
	cpda8_24 a, (0xffe3)
	jr nz, SeqLoad_ProcessReturn
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
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
	cpda8_24 a, (0xffe3)
	jr nz, VoiceData_NextWord
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
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
	lds wa, 1
	lds bc, 1
	call PartCtrl_SetClearBit7
	lds wa, 1
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	lds wa, 1
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	lds wa, 2
	lds bc, 1
	call PartCtrl_SetClearBit7
	lds wa, 2
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	lds wa, 2
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf

; === v7-specific block: SeqLoad_ProcessEpilogue (88 bytes) ===
SeqLoad_ProcessEpilogue:
	pop XIZ
	inc 0,XSP
	ret
	push QIZ
	lds_erpb 0xfb, 0
.Lc_f483a7:
	ld_erpb_rr a, 0xfb
	extz WA
	ldw BC, 0x0112
	call Part_ReadByteDirect
	cps l, 1
	jr z, .Lc_f483e8
	ld_erpb_rr a, 0xfb
	extz WA
	ldw BC, 0x0112
	lds de, 1
	call Part_WriteByte
	ld_erpb_rr a, 0xfb
	extz WA
	ldw BC, 0x0110
	call Part_ReadWord
	cps hl, 0
	jr nz, .Lc_f483e8
	ld_erpb_rr a, 0xfb
	extz WA
	ldw BC, 0x0110
	ldw DE, 0xffff
	call Part_WriteWord
	call VoiceChannels_InitPanFromPreset
.Lc_f483e8:
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x0a
	jr ule, .Lc_f483a7
	pop QIZ
	ret
; === end v7 block ===
VoiceAlloc_TestBitRead:
	calr SeqStep_PostEventAndUpdate
	calr SeqScan_CheckBarBitAndProcess
	calr Portamento_ScanInitAndLoop
	jrl SeqTick_InitAndScanParts

VoiceAlloc_TestBitHigh:
	ldb l, 0x0

VoiceAlloc_TestBitResult:
	lds bc, 1
	ld a, l
	and a, 0xf
	jr z, VoiceAlloc_ComputeBitmaskAddr
	slaa bc

VoiceAlloc_ComputeBitmaskAddr:
	andda16 xbc, 0xf19e
	jr z, VoiceChan_StatusCheckReturn
	ld a, l
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xf
	jr nz, VoiceChan_CheckStatusReady
	ldb l, 0xf
	ret

VoiceChan_CheckStatusReady:
	cp a, 0x10
	jr nz, VoiceChan_StatusCheckReturn
	ldb l, 0x10
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
	ldmmw_dri 0x07, 0xe4, 0xe0, 0x8e, 0x25
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
	ldmmw_dri 0x07, 0xe4, 0xe0, 0x8e, 0x25
	ret

SeqStep_PostEventAndUpdate:
	ldw (9616:16), 0
	ld (9618:16), 0
	resda 0, 0x28a6
	ld (9696:16), 0
	lda xix, (9510:16)
	lda xhl, (9558:16)
	lda xde, (9542:16)
	lda xbc, (9590:16)

SeqStep_PostEventReturn:
	ld a, (9696:16)
	extz wa
	add wa, wa
	stiw_ind 0x07, 0xf0, 0xe0, 0xff, 0xff
	ld a, (9696:16)
	extz wa
	add wa, wa
	stiw_ind 0x07, 0xec, 0xe0, 0xff, 0xff
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
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqNote_FormatReturn
	slaa de

SeqNote_FormatReturn:
	andda16 xde, 0xf19e
	jr z, SeqScan_AdvanceToNextPart
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
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
	cps l, 1
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
	cps l, 1
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
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase2:
	cp l, 0x85
	jr nz, SeqNote_QueueCase3
	calr SeqScan_RefreshReadAndCompare
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase3:
	cp l, 0x86
	jr nz, SeqNote_QueueCase4
	calr SeqScan_ReadAndCompareParam
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueCase4:
	cp l, 0x82
	jr z, SeqScan_AdvanceToNextPart
	cp l, 0x84
	jr nz, SeqNote_QueueDefault
	calr SeqScan_CheckSeekTerminator
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

SeqNote_QueueDefault:
	bit 7, l
	jr nz, SeqNote_QueueFallthrough
	calr SeqData_ReadParamBlock
	jr SeqScan_ParsePartEvents

SeqNote_QueueFallthrough:
	calr SeqScan_ReadParamCompareRange
	cps l, 1
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
	incdi16 1, (9614)
	ld wa, (9614:16)
	cpda16 xwa, 1052
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
	cps a, 5
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
	cps bc, 0
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
	ld bc, (1052:16)
	cp wa, bc
	jr c, SeqScan_StoreAndUpdateBest
	cp wa, bc
	jr ugt, SeqScan_StorePositionReturn1
	ld a, (xhl + 1)
	cpda8 a, 1051
	jr ugt, SeqScan_StorePositionReturn1

SeqScan_StoreAndUpdateBest:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	ld (9614:16), iz

SeqScan_StoreAndReturn:
	ldb l, 0x0
	jr SeqScan_PopIzAndReturn

SeqScan_StorePositionReturn1:
	ld (9614:16), iz
	ldb l, 0x1

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
	cpda16 xwa, 1052
	jr nc, SeqScan_CompareByteAndPosition

SeqScan_PostAndUpdateTiming:
	calr VoiceChan_PostStatusEvent
	calr SeqScan_UpdateBestPositionA
	ldb l, 0x0
	ret

SeqScan_CompareByteAndPosition:
	ld c, (1051:16)
	ld e, c
	extz de
	cp wa, de
	jr ugt, SeqScan_ReturnOneResult
	cpdm8 9607, c
	jr ule, SeqScan_PostAndUpdateTiming

SeqScan_ReturnOneResult:
	ldb l, 0x1
	ret

SeqScan_ReadAndCompareParam:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	ld (9607:16), l
	call PartCtrl_RefreshWordPeriodic
	ld wa, (9614:16)
	ld bc, (1052:16)
	cp wa, bc
	jr nc, SeqScan_CompareEqual

SeqScan_StoreResultAndReturn:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	ldb l, 0x0
	ret

SeqScan_CompareEqual:
	cp wa, bc
	jr ugt, SeqScan_CompareReturnOne
	ld a, (9607:16)
	cpda8 a, 1051
	jr ule, SeqScan_StoreResultAndReturn

SeqScan_CompareReturnOne:
	ldb l, 0x1
	ret

SeqScan_CheckSeekTerminator:
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xd
	jr nz, SeqScan_SeekAndReturnZero
	ldb l, 0x1
	ret

SeqScan_SeekAndReturnZero:
	call SeqData_SeekToPartStart
	ldb l, 0x0
	ret

SeqScan_ReadParamCompareRange:
	calr SeqData_ReadParamBlock
	ld wa, (9614:16)
	ld bc, (1052:16)
	cp wa, bc
	jr nc, SeqScan_ParamAboveOrEqual
	ldb l, 0x0
	ret

SeqScan_ParamAboveOrEqual:
	cp wa, bc
	jr ule, SeqScan_ParamExactCompare
	ldb l, 0x1
	ret

SeqScan_ParamExactCompare:
	ld a, (9607:16)
	cpda8 a, 1051
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
	cpda8 a, 9607
	ret ugt

SeqScan_WriteBestPositionA:
	ld (9616:16), bc
	ldmm8 9618, 9607
	setda 0, 0x28a6
	ret

SeqScan_UpdateBestPositionB:
	ld bc, (9614:16)
	ld wa, (9616:16)
	cp wa, bc
	ret ugt
	cp wa, bc
	jr nz, SeqScan_WriteBestPositionB
	ld a, (9618:16)
	cpda8 a, 9607
	ret ugt

SeqScan_WriteBestPositionB:
	ld (9616:16), bc
	ldmm8 9618, 9607
	resda 0, 0x28a6
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
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, SeqTick_CheckPartMask
	slaa de

SeqTick_CheckPartMask:
	andda16 xde, 0xf19e
	jr z, Seq_TickReturn
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
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
	cps wa, 0
	jr nz, SeqTick_StoreFirstCandidate
	ld (0x28af:16), bc
	ldmm16 9830, 9630
	jrl SeqStep_InitParseLoop

SeqTick_StoreFirstCandidate:
	ld (0x28af:16), wa
	ldmm16 9830, 9628
	ld wa, (9626:16)
	cps wa, 0
	jrl nz, SeqEvt_InitDualTrackScan
	jr Seq_InitAdvancePosition

Seq_InitAdvancePosition:
	ldw (9614:16), 0

Seq_AdvanceNoteStep:
	calr SeqData_ReadParamBlock
	cps hl, 7
	jr c, Seq_AdvanceCheckEventType
	ld a, (9664:16)
	extz wa
	jrl Portamento_NotifyParams

Seq_AdvanceCheckEventType:
	lda xix, (9606:16)
	ld a, (xix)
	ldb_erp A, 0xe2
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
	ld hl, (1052:16)
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
	stb_erp W, 0xe2
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
	cpda8 c, 1051
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
	stb_erp W, 0xe2
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
	cps w, 1
	jrl nz, Seq_AdvanceNoteStep
	ld w, (xix + 4)
	res 7, w
	cps w, 0
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
	ld de, (1052:16)
	cp bc, de
	jr ugt, SeqStep_CallHandleNoteOverflow
	cp bc, de
	jr nz, Seq_NoteExtractAndStore
	ld c, (xix)
	cpda8 c, 1051
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
	cps hl, 7
	jrl nc, Portamento_NotifyParams
	lda xiy, (9606:16)
	ld c, (xiy)
	ldb_erp C, 0xe2
	cp_erpb 0xe2, 0x82
	jr z, SeqStep_OverflowCheck
	cp_erpb 0xe2, 0x84
	jr nz, SeqStep_CheckBoundaryB
	ldmm8 9696, 9666
	call SeqData_SeekToPartStart
	jr SeqStep_ParseEventLoop

SeqStep_CheckBoundaryB:
	ld hl, (1052:16)
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
	stb_erp C, 0xe2
	and c, 0xf0
	ldb_erp C, 0xe6
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
	cpda8 c, 1051
	jr ule, SeqStep_ExtractNoteB

SeqStep_OverflowCheck:
	jr SeqStep_HandleNoteOverflow

SeqStep_ExtractNoteB:
	ld a, (xiy + 4)
	ldb_erp A, 0xe6
	bit_erpb 0xe2, 0x00
	jr z, SeqStep_SetBit7B
	set_erpb 0xe6, 0x07

SeqStep_SetBit7B:
	ld c, (xiy + 5)
	extz bc
	sll bc, 8
	stb_erp A, 0xe6
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
	cps hl, 7
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
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckSeekOp:
	cp (9606:16), 132
	jr nz, SeqEvt_CheckBoundaryAndInit
	ldmm8 9696, 9664
	jrl SeqEvt_SeekAndContinueLoop

SeqEvt_CheckBoundaryAndInit:
	ld wa, (1052:16)
	inc 1, wa
	cpda16 xwa, 9620
	jr ugt, SeqEvt_CheckIncrementOp
	calr SeqVoice_InitFirstSlotSearch
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckIncrementOp:
	lda xde, (9606:16)
	ld a, (xde)
	cp a, 0x81
	jr nz, SeqEvt_ExtractEventType
	incdi16 1, (9620)
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
	cpda16 xbc, 1052
	jr ule, SeqEvt_CheckExactMatchA
	calr SeqVoice_InitFirstSlotSearch
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckExactMatchA:
	ld wa, (9620:16)
	cpda16 xwa, 1052
	jr nz, SeqEvt_SaveScanAndDispatch
	ld a, (9607:16)
	cpda8 a, 1051
	jr ule, SeqEvt_SaveScanAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldb_erp L, 0xfb
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
	cps l, 1
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xde + 4)
	res 7, l
	cps l, 0
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
	cpda16 xbc, 1052
	jr ule, SeqEvt_CheckExactPortamento
	calr SeqVoice_InitFirstSlotSearch
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_CheckExactPortamento:
	ld wa, (9620:16)
	cpda16 xwa, 1052
	jr nz, SeqEvt_SavePortamentoAndDispatch
	ld a, (9607:16)
	cpda8 a, 1051
	jr ule, SeqEvt_SavePortamentoAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldb_erp L, 0xfb
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
	ldb_erp L, 0xfb
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
	ld wa, (1052:16)
	inc 1, wa
	cpda16 xwa, 9622
	jr ugt, SeqEvt_SecondTrackExtract
	calr SeqSearch_InitNotFound
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SecondTrackExtract:
	lda xde, (9606:16)
	ld l, (xde)
	cp l, 0x81
	jr nz, SeqEvt_SecondTrackCheckC0
	incdi16 1, (9622)
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
	cpda16 xbc, 1052
	jr ule, SeqEvt_AccompCheckExact
	calr SeqSearch_InitNotFound
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr lt, SeqEvt_DispatchLoop_Return

SeqEvt_AccompCheckExact:
	ld wa, (9622:16)
	cpda16 xwa, 1052
	jr nz, SeqEvt_SaveAccompAndDispatch
	ld a, (9607:16)
	cpda8 a, 1051
	jr ule, SeqEvt_SaveAccompAndDispatch
	calr SeqSearch_InitNotFound
	ldb_erp L, 0xfb
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
	adddm16 9662, xhl

SeqEvt_ResolveNotePosition:
	calr SeqEvt_SelectNearestTiming
	ldb_erp L, 0xfb
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
	cpdi16 9640, 0xffff
	jr nz, SeqEvt_CompareBothTracks
	ld a, (9666:16)
	extz wa
	calr SeqStep_HandleNoteOverflow
	ldb l, 0xff
	ret

SeqEvt_CompareBothTracks:
	ld de, (9640:16)
	cp bc, de
	jr nz, SeqEvt_CompareTrackOrder
	ld a, (9638:16)
	cpda8 a, 9642
	jr z, SeqEvt_BothTracksEqual

SeqEvt_CompareTrackOrder:
	cp bc, de
	jr c, SeqEvt_SelectTrackA
	cp bc, de
	jr nz, SeqEvt_SelectTrackB
	ld a, (9638:16)
	cpda8 a, 9642
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
	cps bc, 0
	jr nz, SeqEvt_TestBitAndSelect
	cps a, 0
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
	ldb l, 0x0
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
	ldb l, 0x1

SeqEvt_SelectionReturn:
	ret

Portamento_NotifyParams:
	pushw_erp 0xfa

	ld bc, (9652:16)

	ld a, c

	and a, 0xff

	ldb_erp A, 0xfb

	srl bc, 8

	extz bc

	ld xwa, 0x28001

	lds de, 3

	call 16566832

	stb_erp C, 0xfb

	extz bc

	ld xwa, 0x28000

	lds de, 3

	call	16566832

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
	cpda8 a, 9634
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
	subda16 xwa, 9648
	ld (9632:16), wa
	ld a, (9634:16)
	add a, 0x5f
	subda8 a, 9650
	ld (9634:16), a
	jr Portamento_CheckZeroPosition

Portamento_SubtractDirect:
	ld wa, (9648:16)
	subdm16 9632, xwa
	ld a, (9634:16)
	subda8 a, 9650
	ld (9634:16), a

Portamento_CheckZeroPosition:
	ld bc, (9632:16)
	cps bc, 0
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
	subdi8 9634, 40
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
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ldb_erp L, 0xf0
	extz ix
	ld bc, (9632:16)
	ld iy, bc
	extz xiy
	div xiy, xix
	extz xbc
	div xbc, xix
	stw_erp WA, 0xe6
	ld e, (9650:16)
	ld (9646:16), e
	cps l, 1
	jr z, Portamento_IncrementAndWrap
	cps wa, 1
	jr nc, Portamento_IncrementAndWrap
	mul xiy, xix
	ld wa, (9648:16)
	add wa, iy
	ld (9648:16), wa
	ld (9644:16), wa
	jr Portamento_ComputeStepSize

Portamento_IncrementAndWrap:
	inc 1, iy
	mul xix, xiy
	ld bc, (9648:16)
	add bc, ix
	ld (9648:16), bc
	ld (9644:16), bc
	ld wa, (1052:16)
	cp bc, wa
	jr ugt, Portamento_WrapOverBoundary
	cp bc, wa
	jr nz, Portamento_ComputeStepSize
	cpda8 e, 1051
	jr ule, Portamento_ComputeStepSize

Portamento_WrapOverBoundary:
	ld bc, (9656:16)
	ld wa, bc
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld bc, (9644:16)
	ld iz, bc
	ld a, (9646:16)
	ldb_erp A, 0xfb
	cpda8 a, 1051
	jr nc, Portamento_DecrementPosition
	dec 1, iz

Portamento_DecrementPosition:
	subda16 xiz, 1052
	extz hl
	cp iz, hl
	jr ule, Portamento_SubtractDirect2
	ld iy, iz
	extz xiy
	div xiy, xhl
	inc 1, iy
	mul xhl, xiy
	sub bc, hl
	jr Portamento_StoreFinalPosition

Portamento_SubtractDirect2:
	sub bc, hl

Portamento_StoreFinalPosition:
	ld (9644:16), bc

Portamento_ComputeStepSize:
	ld iz, (1052:16)
	ld a, (1051:16)
	ldb_erp A, 0xfb
	ld c, (9646:16)
	stb_erp A, 0xfb
	cp a, c
	jr nc, Portamento_SubtractPosition
	dec 1, iz
	subda16 xiz, 9644
	add_erpb 0xfb, 0x5f
	jr Portamento_ComputeAndStore

Portamento_SubtractPosition:
	subda16 xiz, 9644

Portamento_ComputeAndStore:
	stb_erp A, 0xfb
	sub a, c
	ldb_erp A, 0xfb
	ld bc, (9656:16)
	ld wa, bc
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld wa, iz
	div8rr a, l
	ld (1079:16), w
	stb_erp A, 0xfb
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
	lds wa, 0
	ld bc, iz
	call Part_ReadByteDirect
	ldb_erp L, 0xfb
	ld bc, iz
	inc 1, bc
	lds wa, 0
	call Part_ReadByteDirect
	stb_erp A, 0xfb
	ld (9674:16), a
	ld (9676:16), l
	extz hl
	sll hl, 8
	ld (9652:16), hl
	stb_erp A, 0xfb
	extz wa
	adddm16 9652, xwa
	ld (9696:16), 0

Portamento_ScanPartLoop:
	ld c, (9696:16)
	lds de, 1
	ld a, c
	and a, 0xf
	jr z, Portamento_ScanCheckPartMask
	slaa de

Portamento_ScanCheckPartMask:
	andda16 xde, 0xf19e
	jr z, Portamento_ScanNextPart
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, Portamento_ScanNextPart
	call SeqData_SeekToPartStart
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xf
	call_24 z, SeqSearch_InitAndAdvance
	ld a, (9696:16)
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	call_24 z, Portamento_ScanInitPosition

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
	cps hl, 7
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
	cpda8 a, 9618
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
	adddm16 9652, xhl
	ldmm16 9668, 9614
	mrib4 0x84, 0x19, 0xc6, 0x25
	jrl Portamento_ScanSeqEvents

SeqSearch_InitAndAdvance:
	ldw (9614:16), 0

SeqSearch_AdvanceToPosition:
	calr SeqData_ReadParamBlock
	cps hl, 7
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
	cps hl, 0
	jr nz, SeqSearch_ComparePosition
	cps e, 0
	jrl z, SeqSearch_AdvanceToPosition

SeqSearch_ComparePosition:
	cp bc, ix
	ret ugt
	cp bc, ix
	jr nz, SeqSearch_ExtractNote
	ld a, (xwa)
	cpda8 a, 9618
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
	cps e, 1
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xiy + 4)
	res 7, e
	cps e, 0
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
	cpda8 a, 9618
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
	lds iz, 0
	call SeqData_ReadNextByte
	ld (9606:16), l
	cp l, 0x82
	jr z, SeqData_ReadParamTerminator
	cp l, 0x84
	jr nz, SeqVoice_ReadByteLoop

SeqData_ReadParamTerminator:
	lds hl, 0
	jr SeqData_ReadParamReturn2

SeqVoice_ReadByteLoop:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, SeqData_ReadParamDone
	cps iz, 5
	jr nc, SeqVoice_ReadByteLoop
	ld bc, iz
	lda xwa, (9607:16)
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cps iz, 7
	jr c, SeqVoice_ReadByteLoop
	resda 0, 0x28a6
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
	cpdi16 9616, 0
	jr nz, SeqScan_ProcessBarSlots
	cp (9618:16), 0
	ret z

SeqScan_ProcessBarSlots:
	calr SeqScan_ClearMatchingBarSlots
	lds de, 0
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
	lds de, 0
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
	cpda8 a, 9688
	jrl nc, SeqScan_SaveBarPosition
	ret

SeqScan_ClearMatchingBarSlots:
	lds hl, 0
	lda xbc, (9542:16)

SeqScan_ClearBarLoop:
	ld a, (xbc)
	cpda8 a, 9618
	jr nz, SeqScan_ClearBarNext
	ld de, hl
	add de, de
	lda xwa, (9510:16)
	extz xde
	add xde, xwa
	ld wa, (xde)
	cpda16 xwa, 9616
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
	ldb_erp A, 0xe6
	lds iz, 1

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
	ldb_erp A, 0xe6

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
	ldb_erp A, 0xe6
	lds iz, 1

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
	ldb_erp A, 0xe6

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
	lds de, 0
	call Part_WriteWord
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	ldw bc, 0xcb
	lds de, 0
	call Part_WriteByte
	ldib_erp 0xfb, 1

SeqVoice_InitPartVoiceLoop:
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ld a, (0x2878:16)
	inc 1, a
	extz wa
	stb_erp C, 0xfb
	extz bc
	ldw de, 0xffff
	call Part_WriteVoiceWord
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqVoice_InitPartVoiceLoop
	ld a, (0x00ffe3:24)
	cpda8 a, 0x2878
	jr nz, SeqVoice_InitChannelAndParams
	ld (0xf24b:16), 0
	call SeqStatus_ResetAndSendCmd
	ldw (0xf19c:16), 0
	ldib_erp 0xfb, 1

SeqVoice_InitSecondPartLoop:
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	stb_erp C, 0xfb
	extz bc
	lds wa, 0
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
	cps hl, 0
	jr z, SeqPart_InitSlots
	ld (0x287a:16), 3
	jr SeqPart_InitFinish

SeqPart_InitSlots:
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqPart_InitFinish
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xffff
	jr z, SeqPart_InitFinish
	ld c, (0x2877:16)
	extz bc
	lds wa, 0
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
	lds de, 0
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
	lds de, 5
	call Part_WriteByte_Indexed
	popw iz
	ret

SeqPart_Compare:
	dec 6, xsp
	push xiz
	calr SeqPart_InitWithValidation
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	ld a, (0x2877:16)
	extz wa
	calr SeqPart_CheckVoiceType
	cps l, 0
	jrl lt, SeqPart_CompareLongReturn
	ldb_erp L, 0xfb
	ld a, (9858:16)
	extz wa
	calr SeqPart_CheckVoiceType
	cps l, 0
	jrl lt, SeqPart_CompareLongReturn
	ld (0x27d2:16), 0
	calr SeqPart_CheckBothCompatible
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	calr SeqPart_SetupLeftPos
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	ldmw2 (xsp + 4), 0x27d4
	calr SeqPart_SetupRightPos
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	ld iz, (0x27d8:16)
	calr SeqPart_HandlePartChange
	ld a, (0x2877:16)
	extz wa
	calr SeqPart_ClearSingle
	ld a, (9858:16)
	extz wa
	calr SeqPart_ClearSingle
	stb_erp A, 0xfb
	extz wa
	calr SeqPart_AllocNewEntry
	cps hl, 0
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
	cps e, 3
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
	cpda8 e, 0x27de
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
	ld (0x287a:16), 0
	ld a, (0x2879:16)
	res 0, a
	res 1, a
	ld (0x2879:16), a
	call SeqVoice_SetDefaultParams
	cp (3301:16), 15
	jp_24 ugt, SeqVoice_InitReturnZero
	ld a, (0x2877:16)
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cp (xwa), 0xc
	jr nz, SeqPart_DispatchReturn
	setda 0, 0x2879

SeqPart_DispatchReturn:
	ld a, (9858:16)
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0xc
	jr nz, SeqPart_DispatchCheckEvent
	setda 1, 0x2879

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
	resda 2, 0x287b
	ld (0x287a:16), 0
	extz wa
	ld (0x287d:16), wa
	ldw (0x287f:16), 1
	ld wa, (0x287d:16)
	extz wa
	lds bc, 0
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
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
	cps hl, 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopNote:
	calr SeqStep_SkipIfLeftFlag
	cps hl, 0
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
	cps hl, 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopC0:
	calr SeqStep_ProcessC0Ext
	cps hl, 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoop90:
	calr SeqStep_ProcessB0Ext
	cps hl, 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopSkip:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
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
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ld c, (xsp)
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteVoiceWord
	ld c, (xsp)
	extz bc
	lds wa, 0
	ldw de, 0xffff
	call Part_WriteWord_Indexed
	ld c, (xsp)
	extz bc
	lds wa, 0
	lds de, 5
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
	resda 0, 0x27d2
	ld wa, (0x27d4:16)
	ld bc, (0x27d6:16)
	call PartCtrl_ReadByteExtended
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqPart_CompareLeftCheck
	cp_erpb 0xfb, 0x81
	jr nz, SeqPart_CompareLeftLoop

SeqPart_CompareLeftCheck:
	setda 0, 0x27d2
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
	stb_erp L, 0xfb
	popw_erp 0xfa
	ret

SeqPart_CompareRight:
	pushw_erp 0xfa
	resda 1, 0x27d2
	ld wa, (0x27d8:16)
	ld bc, (0x27da:16)
	call PartCtrl_ReadByteExtended
	ldb_erp L, 0xfb
	cp_erpb 0xfb, 0x82
	jr z, SeqPart_CompareRightCheck
	cp_erpb 0xfb, 0x81
	jr nz, SeqPart_CompareRightLoop

SeqPart_CompareRightCheck:
	setda 1, 0x27d2
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
	stb_erp L, 0xfb
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
	cps hl, 0
	jr z, SeqPart_InitValidOk
	ld (0x287a:16), 3
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_InitValidOk:
	ld (0x287a:16), 0
	resda 6, 0x287b
	lds hl, 0
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
	ld (0x287a:16), 9
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldb l, 0xff
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
	lda xbc, (FontPalette_Gradient7_0x32:24)
	ldmm_srib 0x07, 0xe4, 0xe0, 0x7c, 0x28
	calr SeqPart_SetupWithDispatch
	cp (0x287a:16), 0
	jr z, SeqPart_CompatReturn
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_CompatReturn:
	lds hl, 0
	ret

SeqPart_SetupLeftPos:
	ld a, (0x2877:16)
	extz wa
	call Part_ValidateVoiceChannel
	cp (0x287a:16), 0
	jr z, SeqPart_SetupLeftDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_SetupLeftDone:
	ldmm16 0x27d4, 0x28af
	ldw (0x27d6:16), 5
	lds hl, 0
	ret

SeqPart_SetupRightPos:
	ld a, (9858:16)
	extz wa
	call Part_ValidateVoiceChannel
	cp (0x287a:16), 0
	jr z, SeqPart_SetupRightDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xffff
	ret

SeqPart_SetupRightDone:
	ldmm16 0x27d8, 0x28af
	ldw (0x27da:16), 5
	lds hl, 0
	ret

SeqPart_HandlePartChange:
	pushw_erp 0xfa
	ld a, (0x2877:16)
	ldb_erp A, 0xfb
	ld a, (9860:16)
	cpb_erp A, 0xfb
	jr z, SeqPart_PartChangeError
	cpda8 a, 9858
	jr z, SeqPart_PartChangeError
	ld (0x2877:16), a
	calr SeqPart_InitClear
	stb_erp A, 0xfb
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
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ld c, (9860:16)
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld (0x2887:16), iz
	ldw (0x2885:16), 5
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	lds hl, 0

SeqPart_AllocReturn:
	popw iz
	inc 2, xsp
	ret

SeqPart_ByteBlockA207:
	.incbin "includes/romslices/v7_transplant_SeqPart_ByteBlockA207.bin"
SeqPart_SinglePartLoad:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndMode
	cps hl, 0
	jr z, SeqPart_SingleLoadCheckType
	ld (0x287a:16), 3
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadCheckType:
	ld (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode0:
	ldmm8 9780, 0x2877
	calr SeqPart_FullLoad
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode1:
	ldib_erp 0xfb, 1

SeqPart_SingleLoadMode2:
	stb_erp A, 0xfb
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
	setda 6, 0x287b

SeqPart_SingleLoadSkipDrum:
	stb_erp A, 0xfb
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (0x287a:16), 0
	jr nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadVoiceSetup:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_SingleLoadMode2
	call SeqPart_SeekAllVoicesToBar
	cp (0x287a:16), 0
	jr nz, SeqPart_SingleLoadCleanup
	ld (9782:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_SingleLoadReturn

SeqPart_SingleLoadFinish:
	stb_erp A, 0xfb
	ld (9780:16), a
	calr SeqPart_FullLoad
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_SingleLoadError
	cps a, 1
	jr z, SeqPart_SingleLoadError
	cp a, 0x8
	jr z, SeqPart_SingleLoadError
	cp (9782:16), 0
	jr nz, SeqPart_SingleLoadError
	ld (9782:16), a

SeqPart_SingleLoadError:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpda8 a, 0x28a1
	jr ule, SeqPart_SingleLoadFinish

SeqPart_SingleLoadReturn:
	ldmm8 0x287a, 9782

SeqPart_SingleLoadCleanup:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_FullLoad:
	dec 2, xsp
	push xiz
	ld (0x287a:16), 0
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	ld a, (9808:16)
	ldw (xsp + 4), 0x0
	cps a, 0
	jrl nz, SeqPart_FullLoadMode1
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadWalk:
	lds iz, 0
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqPart_FullLoadComplete

SeqPart_FullLoadReadEvent:
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadCheck81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadCheck81:
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadSrcMatch
	stb_erp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
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
	cpda16 xwa, 9694
	jr nz, SeqPart_FullLoadWalk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadSrcMatch:
	ld a, (9780:16)
	cpda8 a, 0x288d
	jr nz, SeqPart_FullLoadValidate
	stb_erp A, 0xfa
	and a, 0xf0
	cp a, 0xc0
	jr nz, SeqPart_FullLoadValidate

SeqPart_FullLoadProcess:
	stb_erp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
	bit_erpb 0xfa, 0x07
	jr nz, SeqPart_FullLoadCountCheck
	stb_erp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	jr SeqPart_FullLoadProcess

SeqPart_FullLoadValidate:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqPart_FullLoadCountCheck
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode1:
	cps a, 1
	jrl nz, SeqPart_FullLoadMode2
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode1Walk:
	lds iz, 0
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqPart_FullLoadMode1Done

SeqPart_FullLoadMode1Read:
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadMode1Check81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Check81:
	stb_erp A, 0xfa
	extz wa
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadMode1Src
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
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
	cpda16 xwa, 9694
	jr nz, SeqPart_FullLoadMode1Walk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Src:
	stb_erp C, 0xfa
	and c, 0xf0
	cp c, 0x90
	jr nz, SeqPart_FullLoadMode1Validate

SeqPart_FullLoadMode1Process:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
	bit_erpb 0xfa, 0x07
	jr z, SeqPart_FullLoadMode1Process
	jr SeqPart_FullLoadMode1Count

SeqPart_FullLoadMode1Validate:
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr z, SeqPart_FullLoadMode1Count
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2:
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode2Walk:
	lds iz, 0
	ldib_erp 0xfb, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jrl z, SeqPart_FullLoadMode2Validate

SeqPart_FullLoadMode2Read:
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
	cp_erpb 0xfa, 0x82
	jr nz, SeqPart_FullLoadMode2Check81
	ldib_erp 0xfb, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode2Check81:
	cp_erpb 0xfa, 0x81
	jr nz, SeqPart_FullLoadMode2Count
	stb_erp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz
	jr SeqPart_FullLoadMode2Done

SeqPart_FullLoadMode2Count:
	stb_erp C, 0xfa
	and c, 0xf0
	cp c, 0x90
	jr z, SeqPart_FullLoadMode2Process
	ld a, (9780:16)
	cpda8 a, 0x288d
	jr z, SeqPart_FullLoadMode2Src
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Src:
	cp c, 0xc0
	jr z, SeqPart_FullLoadMode2Process
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Process:
	stb_erp A, 0xfa
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldb_erp L, 0xfa
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
	cpda16 xwa, 9694
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
	cp (0x287a:16), 0
	jr nz, SeqPart_FullLoadErrorExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr z, SeqPart_FullLoadWriteBack
	dec 1, wa
	ld (xbc), wa
	jr SeqPart_FullLoadWriteReturn

SeqPart_FullLoadWriteBack:
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	cps hl, 0
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
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	a, (0x2879:16)
	res	0, a
	res	1, a
	ld	(0x2879:16), a
	.byte 0xf1, 0x9d
	pushw	wa
	ret	lt
	sbc	de, (xiy+40)
	call	SeqVoice_SetDefaultParams
	call	Seq_ValidateAllParams_DataBlock
	cps	hl, 0
	jr	z, 14
	ld	(0x287a:16), 3
	calr	557
	ldw	wa, 61
	jrl	177
	ld	(0x287a:16), 0
	ld	l, (0x287b:16)
	res	6, l
	ld	(0x287b:16), l
	ld	e, (0x2877:16)
	cp	e, 127
	jrl	z, 333
	lda	xbc, (0xf1a0:16)
	ld	a, e
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	cpda8 xiy, (9858)
	jrl	z, 214
	ld	e, (xwa)
	cp	e, 16
	jr	z, 10
	cp	e, 13
	jr	z, 5
	cp	e, 15
	jr	nz, 13
	ld	(0x287a:16), 9
	calr	479
	ldw	wa, 62
	jr	100
	cp	e, 12
	jr	nz, 6
	.byte 0xf1
	jrl	ge, -18136
	jr	4
	.byte 0xf1
	jrl	ge, -20184
	ld	a, (9858:16)
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	ld	e, (xwa)
	cp	e, 16
	jr	z, 10
	cp	e, 13
	jr	z, 5
	cp	e, 15
	jr	nz, 13
	ld	(0x287a:16), 9
	calr	422
	ldw	wa, 63
	jr	43
	cp	e, 12
	jr	nz, 6
	.byte 0xf1
	jrl	ge, -18392
	jr	4
	.byte 0xf1
	jrl	ge, -20440
	.byte 0xc1
	jrl	c, 6440
	ldw	ix, 0xc126
	ld	h, (xde)
	pop_f
	.byte 0x52
	ldb	h, 30
	.byte 0x9f, 0x01, 0xc1
	jrl	gt, 16168
	nop
	jr	z, 13
	calr	377
	ldw	wa, 64
	call	SeqData_SetErrorCode
	jrl	363
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
	jrl	z, 323
	ld	(3386:16), a
	extz	wa
	lda	xde, (FontPalette_Gradient7_0x32:24)
	.byte 0xc3
	reti
	or	xwa, xwa
	pop_f
	jrl	nov, -16088
	jrl	c, 8488
	dec	1, a
	extz	wa
	extz	xwa
	add	xwa, xbc
	.byte 0x80
	pop_f
	ldw	de, 7693
	push	xiz
	normal
	jrl	283
	ld	e, (xwa)
	cp	e, 13
	jr	z, 5
	cp	e, 16
	jr	nz, 30
	cp	e, 16
	jr	nz, 7
	set	6, l
	ld	(0x287b:16), l
	ld	a, (0x2877:16)
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	.byte 0xc1
	jrl	gt, 16168
	nop
	jrl	nz, 241
	.byte 0xc1
	jrl	c, 6440
	ldw	ix, 0xc126
	jrl	c, 6440
	.byte 0x52
	ldb	h, 241
	jrl	ugt, -12760
	jr	z, 32
	ld	c, (0x2877:16)
	dec	1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	push	xsp
	rcf
	jr	nz, 11
	calr	1528
	.byte 0xc1
	jrl	gt, 16168
	nop
	jrl	nz, 191
	calr	673
	jrl	185
	ldib_erp 251, 1
	stb_erp c, 251
	dec 1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	ld	e, (xbc)
	cp	e, 13
	jr	z, 5
	cp	e, 16
	jr	nz, 26
	cp	e, 16
	jr	nz, 4
	.byte 0xf1
	jrl	ugt, -16856
	stb_erp a, 251
	extz	wa
	call	Part_ValidateAndSetupVoiceChannel
	.byte 0xc1
	jrl	gt, 16168
	nop
	jrl	nz, 129
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, -62
	call	SeqPart_PositionUpdateBlock
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	nz, 109
	ld	(9782:16), 0
	ldib_erp 251, 1
	stb_erp a, 251
	ld	(9780:16), a
	stb_erp a, 251
	ld	(9810:16), a
	.byte 0xf1
	jrl	ugt, -12760
	jr	z, 35
	stb_erp c, 251
	dec 1, c
	extz	bc
	lda	xwa, (0xf1a0:16)
	extz	xbc
	add	xbc, xwa
	.byte 0x81
	push	xsp
	rcf
	jr	nz, 15
	ld	(0x287a:16), 0
	calr	1382
	.byte 0xc1
	jrl	gt, 16168
	nop
	jr	nz, 3
	calr	528
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 20
	cps	a, 1
	jr	z, 16
	cp	a, 8
	jr	z, 11
	.byte 0xc1
	ldw	iz, 0x3f26
	nop
	jr	nz, 4
	ld	(9782:16), a
	inc1b_erp 251
	cp_erpb 251, 16
	jr	ule, -95
	.byte 0xc1
	ldw	iz, 6438
	jrl	gt, 7720
	max
	nop
	pop qiz
	ret
	call	AppEvent_ExtendedHandler_0x7
	call	SeqVoice_InitReturnZero
	.byte 0xf1
	jrl	ge, -20440
	.byte 0xf1
	jrl	ge, -20184
	.byte 0xf1, 0x9d
	pushw	wa
	ret	lt
	.byte 0x9d
	pushw	wa
	.byte 0xb2
	ret

SeqPart_DualCopySetup:
	jrl SeqPart_MultiPartWalker
	resda 3, 0x287b
	ld (0x287a:16), 0
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_DualCopyProcess
	ldw wa, 0x42
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyProcess:
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_DualCopyAdvance
	cps a, 7
	jr z, SeqPart_DualCopyValidate
	ldw wa, 0x43
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyValidate:
	setda 3, 0x287b
	ld (0x287a:16), 0

SeqPart_DualCopyAdvance:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_DualCopyReturn
	ldw wa, 0x45
	jr SeqPart_DualCopyJumpExit

SeqPart_DualCopyReturn:
	ldmm16 0x28ba, 9896
	ldmm16 0x28bc, 9898
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
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
	cp (0x287a:16), 0
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
	cpda16 xwa, (9862)
	jrl	ule, -461
	resda	3, 0x287b
	ld	(0x287a:16), 0
	ld	a, (9810:16)
	extz	wa
	ld	(0x287d:16), wa
	ld	a, (9810:16)
	extz	wa
	call	Part_ValidateVoiceAndSetupSeq
	cp	(0x287a:16), 0
	ret	nz
	.byte 0xd1
	jr	z, 38
	pop_f
	pop	xiz
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	pop	xix
	.byte 0x26
	call	SeqVoice_FindDrumPartIndex
	ld	a, (9810:16)
	.byte 0xd1
	ld	h, (xiz)
	pop_f
	jrl nc, -10200
	ccf
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(0x287a:16), 0
	ret	nz
	.byte 0xd1
	jr	z, 38
	pop_f
	.byte 0x85
	pushw	wa
	.byte 0xd1, 0xaf
	pushw	wa
	pop_f
	.byte 0x87
	pushw	wa
	ld	l, (0x288d:16)
	ld	a, (9780:16)
	.byte 0xd1
	ldw	de, 6438
	jrl nc, -10200
	ccf
	extz	hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(0x287a:16), 0
	ret	nz
	.byte 0xd1
	jr	z, 38
	pop_f
	.byte 0xb2
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	.byte 0xb0, 0x26
	call	SeqData_ScanAllTracks
	ld	a, (0x287a:16)
	cps	a, 0
	jr	z, 13
	cps	a, 7
	ret	nz
	setda	3, 0x287b
	ld	(0x287a:16), 0
	.byte 0xd1
	jr	z, 38
	pop_f
	.byte 0xaa
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	.byte 0xa8
	ldb	h, 209
	pop	xix
	ldb	h, 25
	.byte 0x9c
	ldb	h, 209
	pop	xiz
	ldb	h, 25
	ld	xiz, (xde)
	call	SeqBuf_ComputePageLayout
	cp	(0x287a:16), 0
	ret	nz
	.byte 0xd1, 0xb8
	ldb	h, 25
	.byte 0xac, 0x26
	ld	xwa, (9914:16)
	ld	(9902:16), wa
	ld	c, a
	extz	bc
	ld	wa, (9900:16)
	call	Part_WriteWordAndByte
	lda	xwa, (0x282c:16)
	.byte 0xb0
	ex_ff
	pop	xix
	ldb	h, 184
	push	sr
	ex_ff
	pop	xiz
	ldb h, 241
	ldw wa, 12328
	.byte 0xb0
	ex_ff
	.byte 0xac
	ldb	h, 184
	push	sr
	ex_ff
	.byte 0xae, 0x26
	lda	xwa, (0x2834:16)
	.byte 0xb0
	ex_ff
	.byte 0x87
	pushw	wa
	.byte 0xb8
	push	sr
	ex_ff
	.byte 0x85
	pushw	wa
	call	SeqPart_CopyDataSecondary
	cp	(0x287a:16), 0
	ret	nz
	ld	xwa, 9904
	ld	xbc, 9906
	call	SeqPart_ConsumeTicksFromBuffer
	cp	(0x287a:16), 0
	ret	nz
	ld	xwa, 9896
	ld	xbc, 9898
	call	SeqPart_ConsumeTicksFromBuffer
	cp	(0x287a:16), 0
	ret	nz
	lda	xwa, (0x282c:16)
	.byte 0xb0
	ex_ff
	.byte 0xb0
	ldb	h, 184
	push	sr
	ex_ff
	.byte 0xb2, 0x26
	lda	xwa, (0x2830:16)
	.byte 0xb0
	ex_ff
	.byte 0x87
	pushw	wa
	.byte 0xb8
	push	sr
	ex_ff
	.byte 0x85
	pushw	wa
	lda	xwa, (0x2834:16)
	.byte 0xb0
	ex_ff
	.byte 0xa8
	ldb	h, 184
	push	sr
	ex_ff
	.byte 0xaa, 0x26
	call	SeqPart_CopyDataPrimary
	cp	(0x287a:16), 0
	ret	nz
	bit	3, (0x287b:16)
	ret	z
	lda	xde, (0x2834:16)
	lda	xbc, (xde+2)
	ld	wa, (xbc)
	cps	wa, 5
	jr	z, 6
	dec	1, wa
	ld	(xbc), wa
	jr	21
	ld	wa, (xde)
	call	PartCtrl_ReadWord_Off1
	cps	hl, 0
	ret	z
	lda	xwa, (0x2834:16)
	ld	(xwa), hl
	ldw	(xwa+2), 255
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
	ld (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_WalkerExit
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ldmm16 0x288b, 0x28af
	ldmm16 0x2889, 9830
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_WalkerNote

SeqPart_WalkerLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
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
	cps hl, 0
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
	cpda16 xiz, 9694
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
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (0x2834:16), hl
	ld c, (9858:16)
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	ld (0x2836:16), hl
	call SeqPart_CopyDataPrimary
	cp (0x287a:16), 0
	jr z, SeqPart_WalkerNextSet
	jrl SeqPart_WalkerExit

SeqPart_WalkerB0:
	cp l, 0xd2
	jr z, SeqPart_WalkerC0
	cp l, 0xd1
	jr nz, SeqPart_Walker90

SeqPart_WalkerC0:
	calr SeqStep_SkipIfLeftFlag
	cps hl, 0
	jr z, SeqPart_WalkerD0
	jrl SeqPart_WalkerExit

SeqPart_Walker90:
	cp l, 0x85
	jr z, SeqPart_WalkerSkip
	cp l, 0x86
	jr nz, SeqPart_WalkerContinue

SeqPart_WalkerSkip:
	calr SeqStep_SkipInvertedA
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerContinue:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_WalkerBoundary
	calr SeqStep_SkipInvertedB
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerBoundary:
	cp l, 0xb0
	jr nz, SeqPart_WalkerEndCheck
	calr SeqStep_ProcessB0
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerEndCheck:
	cp l, 0xc0
	jr nz, SeqPart_WalkerAdvance
	calr SeqStep_ProcessC0
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerAdvance:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerNextSet:
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
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
	cps	l, 0
	jrl	z, 226
	ld	(0x2740:16), l
	ld	a, l
	extz	wa
	ld	(0x287d:16), wa
	extz	hl
	ld	wa, hl
	call	Part_ValidateVoiceAndSetupSeq
	cp	(0x287a:16), 0
	jrl	nz, 198
	.byte 0xd1
	jr	z, 38
	pop_f
	pop	xiz
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	pop	xix
	ldb h, 193
	ld xwa, 852567847
	ldb h, 25
	jrl nc, -9432
	ccf
	ld	wa, hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(0x287a:16), 0
	jrl	nz, 158
	call	SeqData_ReadNextByte
	cp	l, 130
	jrl	z, 148
	.byte 0xd1
	jr	z, 38
	pop_f
	.byte 0xd2
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	.byte 0xd4, 0x26
	ldw	(9946:16), 1
	ld	wa, (9778:16)
	dec	1, wa
	ld	(9948:16), wa
	ld	xwa, 0x272c
	call	SeqVoice_SeekAndScanTracks
	cp	(0x287a:16), 0
	jr	nz, 104
	ld	wa, (9862:16)
	cpdm16 (9778), xwa
	jr	z, 78
	ld	l, (0x2740:16)
	ld	(0x287f:16), wa
	extz	hl
	ld	wa, hl
	ld	bc, hl
	call	SeqVoice_SeekToBar
	cp	(0x287a:16), 0
	jr	nz, 69
	call	SeqData_ReadNextByte
	cp	l, 130
	jr	z, 44
	.byte 0xd1
	jr	z, 38
	pop_f
	.byte 0xd6
	ldb	h, 209
	.byte 0xaf
	pushw	wa
	pop_f
	.byte 0xd8, 0x26
	ldw	(9946:16), 1
	ld	wa, (9862:16)
	dec	1, wa
	ld	(9948:16), wa
	ld	xwa, 0x2732
	call	SeqVoice_SeekAndScanTracks
	cp	(0x287a:16), 0
	jr	nz, 16
	.byte 0xd1
	ldw	de, 6438
	.byte 0xde
	ldb	h, 209
	ld	h, (xiz)
	pop_f
	.byte 0xe0, 0x26
	call	SeqBufInit_MainSetup
	jp	SeqPlay_WriteErrorToVoiceTable

SeqPart_DualPartLoad:
	pushw_erp 0xfa
	ld a, (0x2879:16)
	res 0, a
	res 1, a
	ld (0x2879:16), a
	resda 0, 0x289d
	resda 2, 0x289d
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartAndTempo
	cps hl, 0
	jr z, SeqPart_DualLoadSetup
	ld (0x287a:16), 3
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadSetup:
	ld (0x287a:16), 0
	ld l, (0x287b:16)
	res 6, l
	ld (0x287b:16), l
	ld e, (0x2877:16)
	cp e, 0x7f
	jrl nz, SeqPart_DualLoadReturn
	ldib_erp 0xfb, 0

SeqPart_DualLoadCheck:
	stb_erp C, 0xfb
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
	setda 6, 0x287b

SeqPart_DualLoadLoop:
	stb_erp A, 0xfb
	inc 1, a
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cp (0x287a:16), 0
	jrl nz, SeqPart_DualLoadExit

SeqPart_DualLoadEvent:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqPart_DualLoadCheck
	call SeqPart_InitMultiVoicePages
	cp (0x287a:16), 0
	jrl nz, SeqPart_DualLoadExit
	ld (9782:16), 0
	ldib_erp 0xfb, 1
	cp (0x28a1:16), 1
	jr c, SeqPart_DualLoadComplete

SeqPart_DualLoadValidate:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
	ld (9810:16), a
	bit 6, (0x287b:16)
	jr z, SeqPart_DualLoadAdvance
	stb_erp C, 0xfb
	dec 1, c
	extz bc
	lda xwa, (0xf1a0:16)
	extz xbc
	add xbc, xwa
	cp (xbc), 0x10
	jr nz, SeqPart_DualLoadAdvance
	ld (0x287a:16), 0
	calr SeqPart_DrumPartHandler

SeqPart_DualLoadAdvance:
	calr SeqPart_MainNavigate
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_DualLoadFinish
	cps a, 1
	jr z, SeqPart_DualLoadFinish
	cp a, 0x8
	jr z, SeqPart_DualLoadFinish
	cp (9782:16), 0
	jr nz, SeqPart_DualLoadFinish
	ld (9782:16), a

SeqPart_DualLoadFinish:
	inc1b_erp 0xfb
	stb_erp A, 0xfb
	cpda8 a, 0x28a1
	jr ule, SeqPart_DualLoadValidate

SeqPart_DualLoadComplete:
	ldmm8 0x287a, 9782
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadReturn:
	ld a, e
	dec 1, a
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	cpda8 e, 9858
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
	setda 1, 0x2879
	jr SeqPart_DualLoadFinal

SeqPart_DualLoadCleanup:
	resda 1, 0x2879

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
	ld (0x287a:16), 9
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadPartA:
	cp e, 0xc
	jr nz, SeqPart_DualLoadPartADone
	setda 0, 0x2879
	jr SeqPart_DualLoadPartB

SeqPart_DualLoadPartADone:
	resda 0, 0x2879

SeqPart_DualLoadPartB:
	ldmm8 9780, 0x2877
	ldmm8 9810, 9858
	calr SeqPart_Exchange
	cp (0x287a:16), 0
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
	lda xbc, (FontPalette_Gradient7_0x32:24)
	ldmm_srib 0x07, 0xe4, 0xe0, 0x7c, 0x28
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cps l, 0
	jrl z, SeqPart_DrumPartJumpExit
	ld (0x2740:16), l
	ld a, l
	extz wa
	ld (0x287d:16), wa
	extz hl
	ld wa, hl
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
	jrl nz, SeqPart_DrumPartJumpExit
	ldmm16 9822, 9830
	ldmm16 9820, 0x28af
	ld wa, (9778:16)
	cpda16 xwa, 9862
	jrl z, SeqPart_DrumPartJumpExit
	ld l, (0x2740:16)
	ld (0x287f:16), wa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_DrumPartJumpExit
	ld wa, (9862:16)
	ld de, wa
	ld bc, (9694:16)
	add de, bc
	cpda16 xde, 9778
	jr z, SeqPart_DrumPartBoundary
	ld l, (0x2740:16)
	addda16 xwa, 9694
	ld (0x287f:16), wa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_DrumPartExtended
	cp a, 0x8
	jr nz, SeqPart_DrumPartJumpExit
	ld (0x287a:16), 0

SeqPart_DrumPartBoundary:
	ldmm16 9950, 9778
	ldmm16 9952, 9862
	ld wa, (9694:16)
	adddm16 9952, xwa
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
	addda16 xwa, 9694
	dec 1, wa
	ld (9948:16), wa
	ld xwa, 0x2732
	call SeqVoice_SeekAndScanTracks
	cp (0x287a:16), 0
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
	ld (0x287a:16), 0
	ld a, (9810:16)
	cpda8 a, 9780
	jr z, SeqPart_ExchangeProcess
	extz wa
	call Part_ValidateVoiceChannel
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_ExchangeProcess
	cps a, 1
	jrl nz, SeqPart_ExchangeCleanup
	ld (0x287a:16), 0
	cp (7528:16), 1
	jr nc, SeqPart_ExchangeInit
	ld (0x287a:16), 5
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeInit:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	ld c, (9810:16)
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ld c, (9810:16)
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ld c, (9810:16)
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ld c, (9810:16)
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xffff
	call PartCtrl_WriteWord
	setda 7, 0x287b

SeqPart_ExchangeProcess:
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
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
	ldmmw_dri 0x07, 0xe4, 0xe0, 0x66, 0x26
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3311:16)
	ldmmw_dri 0x07, 0xe4, 0xe0, 0xaf, 0x28
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	jrl nz, SeqPart_ExchangeCleanup
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_ExchangeValidate
	cps a, 7
	jrl nz, SeqPart_ExchangeCleanup
	setda 3, 0x287b
	ld (0x287a:16), 0

SeqPart_ExchangeValidate:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ld xwa, (9690:16)
	stda32 0x27e0, xwa
	resda 0, 0x282a
	ld l, (0x288d:16)
	ld a, (9810:16)
	ldmm16 0x287f, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_ExchangeCheckDone
	cp a, 0x8
	jrl nz, SeqPart_ExchangeCleanup
	calr SeqPart_Splice
	cp (0x287a:16), 0
	jr z, SeqPart_ExchangeAdvance
	calr SeqPart_RestoreState
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeAdvance:
	ldmm16 0x28af, 0x288b
	ldmm16 9830, 0x2889
	setda 0, 0x282a
	ld c, (9810:16)
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	ld (9822:16), hl
	ld c, (9810:16)
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	ld (9820:16), hl

SeqPart_ExchangeCheckDone:
	ldmm16 0x2885, 9830
	ldmm16 0x2887, 0x28af
	call SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_ExchangeUpdate
	cps a, 7
	jr nz, SeqPart_ExchangeCleanup
	setda 4, 0x287b
	ld (0x287a:16), 0

SeqPart_ExchangeUpdate:
	ldmm16 0x27ea, 9830
	ldmm16 0x27e8, 0x28af
	ld xwa, (9690:16)
	stda32 0x27e4, xwa
	ld xbc, (0x27e0:16)
	stda32 9690, xbc
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
	cp (0x287a:16), 0
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
	subdm32 9690, xwa
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	ld a, (0x287b:16)
	bit 4, a
	jr z, SeqPart_PosForwardLoop
	bit 3, a
	jr nz, SeqPart_PosForwardLoop
	lds32 xwa, 1
	adddm32 9690, xwa

SeqPart_PosForwardLoop:
	call SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cps bc, 4
	ret ugt
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cps wa, 0
	jr z, SeqPart_PosForwardValidate
	ldw (0x27ee:16), 255
	ret

SeqPart_PosForwardCheck:
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_PosForwardDone
	cpda8 a, 9858
	ret nz

SeqPart_PosForwardDone:
	bit 0, (0x282a:16)
	ret z
	bit 3, e
	ret z
	dec 1, bc
	ld (0x27ee:16), bc
	cps bc, 4
	jr ugt, SeqPart_PosForwardUpdate
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cps wa, 0
	jr z, SeqPart_PosForwardValidate
	ldw (0x27ee:16), 255

SeqPart_PosForwardUpdate:
	ld wa, (9898:16)
	dec 1, wa
	ld (9898:16), wa
	cps wa, 4
	ret ugt
	ld wa, (9896:16)
	call PartCtrl_ReadWord_Off1
	ld (9896:16), hl
	ld wa, (9896:16)
	cps wa, 0
	jr nz, SeqPart_PosForwardError

SeqPart_PosForwardValidate:
	ld (0x287a:16), 11

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
	stda32 9690, xbc
	ldmm16 0x27ec, 0x27e8
	ldmm16 0x27ee, 0x27ea
	ld xwa, 0x27ec
	ld xbc, 0x27ee
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_PosBackwardReturn
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
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
	cp (0x287a:16), 0
	jr nz, SeqPart_PosBackwardReturn
	ld a, (0x287b:16)
	bit 4, a
	ret z
	bit 3, a
	ret nz
	ld wa, (0x27ee:16)
	dec 1, wa
	ld (0x27ee:16), wa
	cps wa, 5
	ret nc
	ld wa, (0x27ec:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27ec:16), hl
	ld wa, (0x27ec:16)
	cps wa, 0
	jr nz, SeqPart_PosBackwardValidate
	ld (0x287a:16), 10
	jr SeqPart_PosBackwardReturn

SeqPart_PosBackwardValidate:
	call PartCtrl_TestBit7
	cps l, 0
	ret nz
	ld (0x287a:16), 11

SeqPart_PosBackwardReturn:
	calr SeqPart_UndoAllocOnError
	ret

SeqPart_PositionEqual:
	ld bc, (0x27ea:16)
	ld a, (0x2877:16)
	cp a, 0x7f
	jr z, SeqPart_PosEqualSpecial
	cpda8 a, 9858
	jr nz, SeqPart_PosEqualStore

SeqPart_PosEqualSpecial:
	bit 0, (0x282a:16)
	jr z, SeqPart_PosEqualStore
	bit 3, (0x287b:16)
	jr z, SeqPart_PosEqualStore
	dec 1, bc
	cps bc, 4
	jr ugt, SeqPart_PosEqualStore
	ld wa, (0x27e8:16)
	call PartCtrl_ReadWord_Off1
	ld (0x27e8:16), hl
	ld wa, (0x27e8:16)
	cps wa, 0
	jr nz, SeqPart_PosEqualSetFF
	ld (0x287a:16), 11
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
	cp (0x287a:16), 0
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
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
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
	ld (0x287a:16), 0
	ld a, (9810:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9810:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 9906, 9830
	ldmm16 9904, 0x28af
	call SeqData_ScanAllTracks
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_NavBackwardProcess
	cps a, 7
	jrl nz, SeqPart_NavExit
	setda 3, 0x287b
	ld (0x287a:16), 0

SeqPart_NavBackwardProcess:
	ldmm16 9898, 9830
	ldmm16 9896, 0x28af
	ld xwa, (9690:16)
	stda32 0x27e0, xwa
	ld l, (0x288d:16)
	ld a, (9810:16)
	ldmm16 0x287f, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 0x2885, 9830
	ldmm16 0x2887, 0x28af
	call SeqData_ScanAllTracks
	cp (0x287a:16), 0
	jr z, SeqPart_NavBackwardValidate
	setda 4, 0x287b
	ld (0x287a:16), 0

SeqPart_NavBackwardValidate:
	ldmm16 0x27ea, 9830
	ldmm16 0x27e8, 0x28af
	ld xbc, (9690:16)
	stda32 0x27e4, xbc
	ld xbc, (0x27e0:16)
	stda32 9690, xbc
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
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
	stda32 9690, xbc
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
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
	addda16 xde, 9694
	lda xbc, (0x2834:16)
	lda xwa, (xbc + 2)
	cpda16 xde, 9778
	jr ule, SeqPart_NavBackwardReturn
	ldmw2 (xbc), 0x26b0
	ldmw2 (xwa), 0x26b2
	call SeqPart_CopyDataSecondary
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	lda xwa, (0x2834:16)
	mrdw5 0x98, 0x02, 0x19, 0xb2, 0x26
	mriw4 0x90, 0x19, 0xb0, 0x26

SeqPart_NavBackwardCleanup:
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call SeqPart_ConsumeTicksFromBuffer
	cp (0x287a:16), 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavBackwardReturn:
	ldmw2 (xbc), 0x27e8
	ldmw2 (xwa), 0x27ea
	call SeqPart_CopyDataSecondary
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26b0
	ld xbc, 0x26b2
	call SeqPart_ConsumeTicksFromBuffer
	cp (0x287a:16), 0
	jr z, SeqPart_NavBackwardCleanup
	jrl SeqPart_NavExit

SeqPart_NavProcessWalker:
	cp xwa, xbc
	jrl ule, SeqPart_NavWalkerCleanup
	sub xwa, xbc
	stda32 9690, xwa
	ld wa, (9862:16)
	addda16 xwa, 9694
	cpda16 xwa, 9778
	jrl ugt, SeqPart_NavWalkerFinish
	ld xwa, 0x26b0
	ld xbc, 0x26b2
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ldmm16 0x27ec, 0x27e8
	ldmm16 0x27ee, 0x27ea
	ld xwa, 0x27ec
	ld xbc, 0x27ee
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavWalkerFinish:
	ld xwa, 0x26a8
	ld xbc, 0x26aa
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	ldmw2 (xsp + 2), 0x26b0
	ldmw2 (xsp), 0x26b2
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call PartCtrl_FindActiveByLimit
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_NavExit
	lda xde, (0x2834:16)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
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
	cp (0x287a:16), 0
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
	ld (0x287a:16), 0
	call SeqVoice_FindDrumPartIndex
	ld a, (9810:16)
	ldw (0x287f:16), 1
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_CountCheckEnd
	jr SeqPart_CountBoundary

SeqPart_CountError:
	call PartCtrl_AdvanceReadPos
	cp (0x287a:16), 0
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
	ld (0x287a:16), 0
	ld c, (0x288d:16)
	ld e, (9810:16)
	ld (0x287f:16), wa
	extz de
	extz bc
	ld wa, de
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	jr nz, SeqPart_StepCountPopReturn
	lds iz, 0
	lds32 xwa, 0
	stda32 9690, xwa

SeqPart_StepCountLoop:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, SeqPart_StepCountCheck
	ld bc, iz
	extz xbc
	lds32 xwa, 0
	ld a, (0x288e:16)
	sub xwa, xbc
	stda32 9690, xwa
	lds iz, 0
	cpdi16 0x27f4, 0
	jr z, SeqPart_StepCountError

SeqPart_StepCountAdvance:
	call SeqTrack_ProcessControlBytes
	cp (0x287a:16), 0
	jr z, SeqPart_StepCountReturn
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountCheck:
	cp l, 0x81
	jr nz, SeqPart_StepCountDone
	inc 1, iz

SeqPart_StepCountDone:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqPart_StepCountLoop
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountReturn:
	inc 1, iz
	lds32 xwa, 0
	ld a, (0x288e:16)
	adddm32 9690, xwa
	cpda16 xiz, 0x27f4
	jr nz, SeqPart_StepCountAdvance

SeqPart_StepCountError:
	lds32 xwa, 1
	adddm32 9690, xwa

SeqPart_StepCountPopReturn:
	popw iz
	ret

SeqPart_ReplayForward:
	push xiz
	ld (0x287a:16), 0
	ldmm16 0x288b, 9820
	ldmm16 0x2889, 9822
	ld xwa, (9690:16)
	dec 1, xwa
	stda32 9690, xwa
	lds32 xiz, 0
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
	cp (0x287a:16), 0
	jr nz, SeqPart_ReplayReturn
	cpdm32 9690, xiz
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
	ld (0x287a:16), 0
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr SeqPart_CountEventsInRange
	cp (0x287a:16), 0
	jr nz, SeqPart_SpliceReturn
	ld wa, (9862:16)
	sub wa, (xsp + 2)
	dec 1, wa
	ld (0x27f4:16), wa
	ld wa, (xsp + 2)
	calr SeqPart_ComputeStepCount
	cp (0x287a:16), 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cp (0x287a:16), 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9900, 9912
	ld xwa, (9914:16)
	ld (9902:16), wa
	calr SeqPart_ReplayForward
	cp (0x287a:16), 0
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
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	ret z
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3311:16)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0xaf, 0x28
	ldmm16 9820, 0x28af
	ld a, (9810:16)
	dec 1, a
	extz wa
	add wa, wa
	lda xbc, (3343:16)
	ldmm_sriw 0x07, 0xe4, 0xe0, 0x66, 0x26
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
	cps hl, 0
	jr nz, SeqPart_TransposeInit

SeqPart_TransposeCheck:
	ld wa, (9778:16)
	call Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_TransposeInit
	ld wa, (9694:16)
	call Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_TransposeInit
	ld a, (9812:16)
	cp a, 0x80
	jr nz, SeqPart_TransposeMode

SeqPart_TransposeInit:
	ld (0x287a:16), 3
	jrl SeqPart_TransposeExit

SeqPart_TransposeMode:
	ld (0x287a:16), 0
	resda 6, 0x287b
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
	ld (0x287a:16), 9
	jr SeqPart_TransposeExit

SeqPart_TransposeValidate:
	ld (9780:16), c
	calr SeqPart_TransposeWalker
	jr SeqPart_TransposeExit

SeqPart_TransposeBoundsOk:
	ldib_erp 0xfb, 0

SeqPart_TransposeStartWalk:
	stb_erp A, 0xfb
	inc 1, a
	ld (9780:16), a
	stb_erp A, 0xfb
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
	call_24 nz, SeqPart_TransposeWalker

SeqPart_TransposeFinish:
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_TransposeReturn
	cps a, 1
	jr z, SeqPart_TransposeReturn
	cp (9782:16), 0
	jr nz, SeqPart_TransposeReturn
	ld (9782:16), a

SeqPart_TransposeReturn:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr c, SeqPart_TransposeStartWalk
	ldmm8 0x287a, 9782

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
	cp (0x287a:16), 0
	jrl nz, SeqPart_TransposePopReturn
	lds iz, 0
	cpdi16 9694, 0
	jrl z, SeqPart_TransposePopReturn

SeqPart_TransposeWalkLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_TransposeError
	jr SeqPart_TransposePopReturn

SeqPart_TransposeClampLow:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_TransposeDone
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_ReadNextByte
	extz hl
	ld a, (9812:16)
	exts wa
	add hl, wa
	jr ge, SeqPart_TransposeSkip
	lds hl, 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_TransposeApply
	jr SeqPart_TransposePopReturn

SeqPart_TransposeError:
	cpda16 xiz, 9694
	jrl nz, SeqPart_TransposeWalkLoop

SeqPart_TransposePopReturn:
	pop xiz
	ret

SeqPart_VelocityEditSetup:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndKey
	cps hl, 0
	jr z, SeqPart_VelEditCheck
	ld (0x287a:16), 3
	jrl SeqPart_VelEditReturn

SeqPart_VelEditCheck:
	ld (0x287a:16), 0
	resda 6, 0x287b
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
	ld (0x287a:16), 9
	jr SeqPart_VelEditReturn

SeqPart_VelEditMode:
	ldib_erp 0xfb, 1

SeqPart_VelEditBounds:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
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
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_VelEditStartWalk
	cps a, 1
	jr z, SeqPart_VelEditStartWalk
	cp (9782:16), 0
	jr nz, SeqPart_VelEditStartWalk
	ld (9782:16), a

SeqPart_VelEditStartWalk:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VelEditBounds
	ldmm8 0x287a, 9782

SeqPart_VelEditReturn:
	call AppEvent_ExtendedHandler
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_VelocityCurveCalc:
	ld a, (9726:16)
	ld c, (9784:16)
	extz wa
	cps wa, 0
	jrl mi, SeqPart_VelRangeToZone
	cp wa, 0xa
	jrl gt, SeqPart_VelRangeToZone
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x68:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (SeqPart_VelCurveData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

SeqPart_VelCurveData:
	ld	(9792:16), 48
	ld	(9794:16), 48
	jrl	494
	ld	a, c
	ldb	e, 0
	cp	c, 24
	jr	c, 7
	cp	a, 72
	jr	nc, 2
	ldb	e, 1
	extz	de
	lda	xbc, (Display_FontPalette_Table_0x1E:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	.byte 0x40, 0x26
	ld	xbc, Display_FontPalette_Table_0x44
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	.byte 0x42, 0x26
	jrl	449
	ld	a, c
	cp	c, 12
	jr	nc, 4
	ldb	e, 0
	jr	27
	cp	a, 36
	jr	nc, 4
	ldb	e, 1
	jr	18
	cp	a, 60
	jr	nc, 4
	ldb	e, 2
	jr	9
	ldb	e, 0
	cp	a, 84
	jr	nc, 2
	ldb	e, 3
	extz	de
	lda	xbc, (Display_FontPalette_Table_0x20:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	.byte 0x40, 0x26
	ld	xbc, Display_FontPalette_Table_0x46
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	.ascii "B&x~"
	.byte 0x01
	ld	a, c
	cps	c, 6
	jr	nc, 4
	ldb	e, 0
	jr	63
	cp	a, 18
	jr	nc, 4
	ldb	e, 1
	jr	54
	cp	a, 30
	jr	nc, 4
	ldb	e, 2
	jr	45
	cp	a, 42
	jr	nc, 4
	ldb	e, 3
	jr	36
	cp	a, 54
	jr	nc, 4
	ldb	e, 4
	jr	27
	cp	a, 66
	jr	nc, 4
	ldb	e, 5
	jr	18
	cp	a, 78
	jr	nc, 4
	ldb	e, 6
	jr	9
	ldb	e, 0
	cp	a, 90
	jr	nc, 2
	ldb	e, 7
	extz	de
	lda	xbc, (Display_FontPalette_Table_0x24:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xwa, 0x4ea24126
	.byte 0xe4
	nop
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xde, 0x01187826
	ld	a, c
	cp	c, 16
	jr	nc, 4
	ldb	e, 0
	jr	18
	cp	a, 48
	jr	nc, 4
	ldb	e, 1
	jr	9
	ldb	e, 0
	cp	a, 80
	jr	nc, 2
	ldb	e, 2
	extz	de
	lda	xbc, (Display_FontPalette_Table_0x2C:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xwa, 0x4eaa4126
	.byte 0xe4
	nop
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xde, 0xde7826
	ld	a, c
	cp	c, 8
	jr	nc, 4
	ldb	e, 0
	jr	45
	cp	a, 24
	jr	nc, 4
	ldb	e, 1
	jr	36
	cp	a, 40
	jr	nc, 4
	ldb	e, 2
	jr	27
	cp	a, 56
	jr	nc, 4
	ldb	e, 3
	jr	18
	cp	a, 72
	jr	nc, 4
	ldb	e, 4
	jr	9
	ldb	e, 0
	cp	a, 88
	jr	nc, 2
	ldb	e, 5
	extz	de
	lda	xbc, (Display_FontPalette_Table_0x30:24)
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xwa, 0x4eae4126
	.byte 0xe4
	nop
	.byte 0xc3
	reti
	.byte 0xe4, 0xe8
	pop_f
	ld	xde, 0x897826

SeqPart_VelRangeToZone:
	ld a, (9784:16)
	cps a, 4
	jr nc, SeqPart_VelZone1
	ldb e, 0x0
	jr SeqPart_VelZoneLookup

SeqPart_VelZone1:
	cp a, 0xc
	jr nc, SeqPart_VelZone2
	ldb e, 0x1
	jr SeqPart_VelZoneLookup

SeqPart_VelZone2:
	cp a, 0x14
	jr nc, SeqPart_VelZone3
	ldb e, 0x2
	jr SeqPart_VelZoneLookup

SeqPart_VelZone3:
	cp a, 0x1c
	jr nc, SeqPart_VelZone4
	ldb e, 0x3
	jr SeqPart_VelZoneLookup

SeqPart_VelZone4:
	cp a, 0x24
	jr nc, SeqPart_VelZone5
	ldb e, 0x4
	jr SeqPart_VelZoneLookup

SeqPart_VelZone5:
	cp a, 0x2c
	jr nc, SeqPart_VelZone6
	ldb e, 0x5
	jr SeqPart_VelZoneLookup

SeqPart_VelZone6:
	cp a, 0x34
	jr nc, SeqPart_VelZone7
	ldb e, 0x6
	jr SeqPart_VelZoneLookup

SeqPart_VelZone7:
	cp a, 0x3c
	jr nc, SeqPart_VelZone8
	ldb e, 0x7
	jr SeqPart_VelZoneLookup

SeqPart_VelZone8:
	cp a, 0x44
	jr nc, SeqPart_VelZone9
	ldb e, 0x8
	jr SeqPart_VelZoneLookup

SeqPart_VelZone9:
	cp a, 0x4c
	jr nc, SeqPart_VelZone10
	ldb e, 0x9
	jr SeqPart_VelZoneLookup

SeqPart_VelZone10:
	cp a, 0x54
	jr nc, SeqPart_VelZone11
	ldb e, 0xa
	jr SeqPart_VelZoneLookup

SeqPart_VelZone11:
	ldb e, 0x0
	cp a, 0x5c
	jr nc, SeqPart_VelZoneLookup
	ldb e, 0xb

SeqPart_VelZoneLookup:
	extz de
	lda xbc, (Display_FontPalette_Table_0x36:24)
	ldmm_srib 0x07, 0xe4, 0xe8, 0x40, 0x26
	ld xbc, Display_FontPalette_Table_0x5C
	ldmm_srib 0x07, 0xe4, 0xe8, 0x42, 0x26
	ld l, (9792:16)
	ld c, (9786:16)
	ld e, c
	cp c, 0x7f
	jr nz, SeqPart_VelCalcSubtract
	ldb e, 0x0

SeqPart_VelCalcSubtract:
	sub l, e
	ld a, (9730:16)
	ld e, a
	cps a, 0
	jr ge, SeqPart_VelCalcMultiply
	ld e, a
	add e, 0x64

SeqPart_VelCalcMultiply:
	mul8rr l, e
	extz hl
	div l, 0x64
	ld e, c
	ld a, c
	cp c, 0x7f
	jr nz, SeqPart_VelCalcAdd
	ldb e, 0x0

SeqPart_VelCalcAdd:
	add e, l
	ld (9790:16), e
	cps a, 0
	jr z, SeqPart_VelCalcClamp
	cp a, 0x7f
	jr nz, SeqPart_VelCalcStore

SeqPart_VelCalcClamp:
	ldb a, 0x60

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
	ld_sril3 XWA, 0x07, 0xe4, 0xec
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_VelExprExit

SeqPart_VelExprLoop:
	ldiw_erp 0xfa, 0
	resda 0, 0x287b
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqPart_VelExprCheckNote

SeqPart_VelExprReadEvent:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_VelExprFinalExit
	cp l, 0x81
	jr nz, SeqPart_VelExprDone
	calr SeqStep_MeasureRead
	calr SeqStep_EventAdvance
	cp (0x287a:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	inc1w_erp 0xfa
	call SeqData_AdvancePosition
	resda 0, 0x287b
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
	cp (0x287a:16), 0
	jr nz, SeqPart_VelExprExit
	cpda16 xiz, 9694
	jr nz, SeqPart_VelExprLoop

SeqPart_VelExprExit:
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprDone:
	bit 7, l
	jr nz, SeqPart_VelExprApply
	call SeqData_ReadParamBlockAlt
	cp (0x287a:16), 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprApply:
	and l, 0xf0
	cp l, 0x90
	jr z, SeqPart_VelExprClamp
	call SeqData_ReadParamBlockAlt
	cp (0x287a:16), 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprClamp:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl nz, SeqPart_VelExprFinalExit
	call SeqData_ReadNextByte
	ld (9784:16), l
	extz hl
	ld xwa, (xsp + 4)
	ldmm_srib 0x07, 0xe0, 0xec, 0x3a, 0x26
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
	cps a, 0
	jr nz, SeqPart_VelExprWrite
	ld a, (9784:16)
	cpda8 a, 9790
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprWrite:
	cp e, 0x7f
	jr nz, SeqPart_VelExprSkip
	ld a, (9784:16)
	cpda8 a, 9788
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprSkip:
	ld a, c
	cpda8 c, 9788
	jr c, SeqPart_VelExprAdvance
	cpda8 a, 9790
	jr ule, SeqPart_VelExprContinue

SeqPart_VelExprAdvance:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	ldb b, 0x60

SeqPart_VelExprBoundary:
	ld l, (9784:16)
	cp l, b
	jr nc, SeqPart_VelExprComplete
	sub b, l
	ld a, b
	jr SeqPart_VelExprUpdate

SeqPart_VelExprError:
	ld e, a
	cps a, 0
	jr nz, SeqPart_VelExprReturn
	ld a, (9784:16)
	cpda8 a, 9790
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprReturn:
	cp e, 0x7f
	jr nz, SeqPart_VelExprFinish
	ld a, (9784:16)
	cpda8 a, 9788
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jr SeqPart_VelExprFinalExit

SeqPart_VelExprFinish:
	ld a, c
	cpda8 c, 9788
	jr ule, SeqPart_VelExprContinue
	cpda8 a, 9790
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jrl z, SeqPart_VelExprCheckEnd
	jr SeqPart_VelExprFinalExit

SeqPart_VelExprComplete:
	ld w, l
	sub w, b
	ld a, w

SeqPart_VelExprUpdate:
	extz wa
	extz bc
	mul xwa, xbc
	extz xwa
	div wa, 0x64
	ld b, e
	cp e, 0x7f
	jr nz, SeqPart_VelExprStore
	ldb b, 0x60

SeqPart_VelExprStore:
	cp l, b
	jr nc, SeqPart_VelExprPopIz
	add l, a
	cp l, 0x60
	jr c, SeqPart_VelExprPopReturn
	ldb l, 0x7f
	jr SeqPart_VelExprClampMax

SeqPart_VelExprPopIz:
	sub l, a

SeqPart_VelExprPopReturn:
	cp l, 0x7f
	jr nz, SeqPart_VelExprClampMin

SeqPart_VelExprClampMax:
	setda 0, 0x287b

SeqPart_VelExprClampMin:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr nz, SeqPart_BufferSwapReturn
	ldmm16 0x2887, 0x28af
	ldmm16 0x2885, 9830
	call PartCtrl_NavigateBackwardAlt
	call SeqPart_ReadByte_Primary
	cp l, 0x81
	jr z, SeqPart_BufferSwapReturn
	call PartCtrl_AdvanceToNextEntry
	call PartCtrl_AdvanceToNextEntry
	cp (0x287a:16), 0
	jr nz, SeqPart_BufferSwapReturn
	ldw wa, 0x82
	call SeqPart_WriteByte_Primary
	ld wa, (0x287d:16)
	ldw_erp WA, 0xfa
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld wa, (0x2885:16)
	ld c, a
	extz bc
	ld wa, (0x2887:16)
	call Part_WriteWordAndByte
	stw_erp WA, 0xfa
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
	cps hl, 0
	jr z, SeqPart_PartSelectLoop
	ld (0x287a:16), 3
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
	ld (0x287a:16), 9
	jr SeqPart_PartSelectExit

SeqPart_PartSelectSkip:
	ld (9780:16), c
	ld (0x287a:16), 0
	calr SeqPart_InnerProcess
	jr SeqPart_PartSelectExit

SeqPart_PartSelectDone:
	ldib_erp 0xfb, 1

SeqPart_PartSelectProcess:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
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
	call_24 nz, SeqPart_InnerProcess

SeqPart_PartSelectFinish:
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_PartSelectReturn
	cps a, 1
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
	ldmm8 0x287a, 9782

SeqPart_PartSelectExit:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_InnerProcess:
	push xiz
	ld (0x287a:16), 0
	cp (9762:16), 0
	jrl z, SeqPart_InnerReturn
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
	jrl nz, SeqPart_InnerReturn
	call SeqVoice_FindDrumPartIndex
	ld a, (9780:16)
	ldmm16 0x287f, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cp (0x287a:16), 0
	jrl nz, SeqPart_InnerReturn
	lds iz, 0
	cpdi16 9694, 0
	jrl z, SeqPart_InnerReturn

SeqPart_InnerLoop:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqPart_InnerCheckNote

SeqPart_InnerReadEvent:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_InnerReturn
	cp l, 0x81
	jr nz, SeqPart_InnerCheck90
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jr z, SeqPart_InnerBoundary
	jr SeqPart_InnerReturn

SeqPart_InnerCheck90:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_InnerAdvance
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_InnerReturn
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_InnerReturn
	call SeqData_ReadNextByte
	ld c, (9762:16)
	cps c, 0
	jr le, SeqPart_InnerVelAddNeg
	ldb e, 0x7f
	sub e, l
	ld a, c
	cp e, a
	jr ugt, SeqPart_InnerVelAdd
	ldb l, 0x7f
	jr SeqPart_InnerVelStore

SeqPart_InnerVelAdd:
	add l, c
	jr SeqPart_InnerVelStore

SeqPart_InnerVelAddNeg:
	add l, c
	jr ge, SeqPart_InnerVelStore
	ldb l, 0x0

SeqPart_InnerVelStore:
	ld a, l
	call PartCtrl_WriteByte_Indexed

SeqPart_InnerAdvance:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqPart_InnerCheckType
	jr SeqPart_InnerReturn

SeqPart_InnerBoundary:
	cpda16 xiz, 9694
	jrl nz, SeqPart_InnerLoop

SeqPart_InnerReturn:
	pop xiz
	ret

SeqPart_PartVoiceCheck:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	call Seq_ValidatePartTempoAndRange
	cps hl, 0
	jr z, SeqPart_VoiceCheckCompare
	ld (0x287a:16), 3
	jrl SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckCompare:
	ld a, (9750:16)
	cpda8 a, 9816
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
	ld (0x287a:16), 9
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckOk:
	ld (9780:16), c
	ld (0x287a:16), 0
	calr SeqPart_VoiceCheckSetup
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckMulti:
	ldib_erp 0xfb, 1

SeqPart_VoiceCheckMultiLoop:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
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
	call_24 nz, SeqPart_VoiceCheckSetup

SeqPart_VoiceCheckMultiNext:
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_VoiceCheckMultiDone
	cps a, 1
	jr z, SeqPart_VoiceCheckMultiDone
	cp a, 0x8
	jr z, SeqPart_VoiceCheckMultiDone
	ld a, (9782:16)
	cps a, 0
	jr nz, SeqPart_VoiceCheckMultiDone
	ld (0x287a:16), a

SeqPart_VoiceCheckMultiDone:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VoiceCheckMultiLoop
	ldmm8 0x287a, 9782

SeqPart_VoiceCheckReturn:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	popw_erp 0xfa
	ret

SeqPart_VoiceCheckSetup:
	push xiz
	ld (0x287a:16), 0
	ld a, (9750:16)
	cpda8 a, 9816
	jrl z, SeqPart_VoiceCheckModeA
	ld a, (9780:16)
	extz wa
	ld (0x287d:16), wa
	ld a, (9780:16)
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cp (0x287a:16), 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_VoiceCheckModeA
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld wa, (9830:16)
	ld (0x2885:16), wa
	ldmm16 0x2889, 9830
	ldmm16 0x288b, 0x28af
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_VoiceCheckComplete

SeqPart_VoiceCheckSetupDone:
	ldiw_erp 0xfa, 0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
	jr z, SeqPart_VoiceCheckValidate

SeqPart_VoiceCheckSetupReturn:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqPart_VoiceCheckModeA
	cp l, 0x81
	jr nz, SeqPart_VoiceCheckFinal
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
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
	cpda16 xiz, 9694
	jr nz, SeqPart_VoiceCheckSetupDone

SeqPart_VoiceCheckComplete:
	jr SeqPart_VoiceCheckModeA

SeqPart_VoiceCheckFinal:
	and l, 0xf0
	cp l, 0x90
	jr nz, SeqPart_VoiceCheckDispatch
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_ReadNextByte
	cpda8 l, 9750
	jr nz, SeqPart_VoiceCheckDispatch
	ld a, (9816:16)
	extz wa
	call PartCtrl_WriteByte_Indexed

SeqPart_VoiceCheckDispatch:
	call SeqData_ReadParamBlockAlt
	cp (0x287a:16), 0
	jr z, SeqPart_VoiceCheckProcess

SeqPart_VoiceCheckModeA:
	pop xiz
	ret

SeqPart_VoiceCheckModeB:
	pushw_erp 0xfa
	call SeqVoice_SetDefaultParams
	ld (0x287a:16), 0
	call Seq_ValidatePartAndTempoAlt
	cps hl, 0
	jr z, SeqPart_VoiceCheckModeC
	ld (0x287a:16), 3
	jrl SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckModeC:
	ld (0x287a:16), 0
	resda 6, 0x287b
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
	ld (0x287a:16), 9
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckStore:
	ld (9780:16), c
	calr SeqPart_VoiceCheckWalkReturn
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckCleanup:
	ldib_erp 0xfb, 1

SeqPart_VoiceCheckFinish:
	stb_erp A, 0xfb
	ld (9780:16), a
	stb_erp A, 0xfb
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
	call_24 nz, SeqPart_VoiceCheckWalkReturn

SeqPart_VoiceCheckWalk:
	ld a, (0x287a:16)
	cps a, 0
	jr z, SeqPart_VoiceCheckWalkLoop
	cps a, 1
	jr z, SeqPart_VoiceCheckWalkLoop
	cp (9782:16), 0
	jr nz, SeqPart_VoiceCheckWalkLoop
	ld (9782:16), a

SeqPart_VoiceCheckWalkLoop:
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x10
	jr ule, SeqPart_VoiceCheckFinish
	ldmm8 0x287a, 9782

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
	cp (0x287a:16), 0
	jrl nz, SeqPart_VoiceCheckEndCleanup
	ldw (xsp + 4), 0x0
	cpdi16 9694, 0
	jrl z, SeqPart_VoiceCheckWalkFinish

SeqPart_VoiceCheckWalkAdvance:
	lds iz, 0
	ld (9824:16), 0
	ld (9826:16), 0
	resda 0, 0x287b
	ldmm16 0x273e, 9830
	ldmm16 0x273c, 0x28af
	ld (xsp + 6), 0x0
	ld a, (0x288e:16)
	extz wa
	cps wa, 0
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
	cp (0x287a:16), 0
	jrl nz, SeqPart_VoiceCheckEndAdvance
	inc 1, iz
	call SeqData_AdvancePosition
	ld (9824:16), 0
	ld (9826:16), 0
	resda 0, 0x287b
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
	cp (0x287a:16), 0
	jr nz, SeqPart_VoiceCheckWalkFinish
	ld wa, (xsp + 4)
	cpda16 xwa, 9694
	jrl nz, SeqPart_VoiceCheckWalkAdvance

SeqPart_VoiceCheckWalkFinish:
	cp (0x287a:16), 0
	jr z, SeqPart_VoiceCheckEndReturn

SeqPart_VoiceCheckWalkExit:
	jr SeqPart_VoiceCheckEndCleanup

SeqPart_VoiceCheckFinalReturn:
	bit 7, l
	jr z, SeqPart_VoiceCheckEndStore
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr nz, SeqPart_VoiceCheckEndAdvance
	call SeqData_ReadNextByte
	ldb_erp L, 0xfb
	stb_erp A, 0xfb
	addda8 a, 9740
	ldb_erp A, 0xfb
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xfb, 0x07
	jr nz, SeqPart_VoiceCheckEndCheck
	cp_erpb 0xfb, 0x60
	jr c, SeqPart_VoiceCheckEndStore

SeqPart_VoiceCheckEndCheck:
	setda 0, 0x287b

SeqPart_VoiceCheckEndStore:
	call SeqData_AdvancePosition
	cp (0x287a:16), 0
	jr z, SeqPart_VoiceCheckWalkError

SeqPart_VoiceCheckEndAdvance:
	ld (xsp + 6), 0x1
	cp (0x287a:16), 0
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
