NoteEditSy_SendCompoundWidgetUpdate:
	call NoteEditSy_SendWidgetCmd2
	jp NoteEditSy_SendModeWidgetCmd

LABEL_F3888B:
	call NoteEditSy_SendWidgetCmd1
	call NoteEditSy_UpdateGridPosition
	call NoteEditSy_SendWidgetCmd3or4
	call NoteEditSy_UpdateNoteDisplay
	bitda 0, 10591
	call_24 nz, 0xF38728
	jp NoteEditSy_UpdateEditModeGrid

LABEL_F388A8:
	lda xsp, (xsp - 16)
	push xiz
	ldda8 a, 7512
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0x0F
	jr nz, LABEL_F388F4
	lds iz, 0

LABEL_F388BB:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xF8
	extz bc
	lda xde, (xsp + 4)
	call LABEL_FEE712
	ld de, iz
	mul de, 0xD
	lda xhl, (xsp + 4)
	ld xbc, xhl
	ldda32 xwa, 7504
	add xde, xwa
	lda xhl, (xhl + 13)

LABEL_F388E0:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_F388E0
	inc 1, iz
	cp iz, 0x80
	jr c, LABEL_F388BB
	jr LABEL_F38907

LABEL_F388F4:
	ldda32 xbc, 7504
	ld xwa, xbc
	st_dri3b A, 0xE5, 0xA4, 0x06

LABEL_F388FF:
	stib_dpi 0xE0, 0x20
	cp xwa, xbc
	jr c, LABEL_F388FF

LABEL_F38907:
	pop xiz
	lda xsp, (xsp + 16)
	ret

LABEL_F3890C:
	call Accomp_UpdateModeFlag
	jr __jrt_nop_F38912
__jrt_nop_F38912:

LABEL_F38912:
	stdi16 9832, 1
	setda 1, 8970
	resda 3, 10407
	setda 4, 10419
	call AccWrap_PlayModeDispatch
	jp SeqBuffer_ClearAndInitIteration

SeqAcc_HandlePlaybackTick:
	cpdi8 36150, 136
	jr z, LABEL_F3894C
	bitda 1, 8970
	jr z, LABEL_F38948
	call PartSelect_UpdateDisplayState
	calr SeqAcc_ProcessTempoEvents
	call AccWrap_PlayModeDispatch
	resda 0, 9954

LABEL_F38948:
	resda 1, 8970

LABEL_F3894C:
	resda 2, 10407
	ret

LABEL_F38951:
	.byte 0xf1, 0xc5, 0x28, 0xbb, 0x0e

LABEL_F38956:
	call Accomp_UpdateModeFlag
	ldda16 xbc, 9832
	stda16 9964, xbc
	ldda16 xbc, 9832
	ld wa, bc
	extz xwa
	bit 15, wa
	jr nz, SeqAcc_StartPlayback
	ldda16 xwa, 62008
	cp bc, wa
	jr ule, LABEL_F38985
	subda16 xwa, 62015
	stda16 9832, xwa
	stda16 9964, xwa
	jr SeqAcc_StartPlayback

LABEL_F38985:
	dec 1, wa
	stda16 10435, xwa
	calr SeqAcc_UpdateEndPosition
	ldda16 xwa, 62008
	subda16 xwa, 62015
	stda16 9832, xwa
	stda16 9964, xwa

SeqAcc_StartPlayback:
	setda 0, 62012
	calr SeqAcc_SetupRepeatCount
	call SeqPlay_InitStartState
	jp SeqBuf_Init

LABEL_F389AD:
	cpdi8 36150, 136
	jr z, LABEL_F389BB
	resda 0, 62012
	calr SeqAcc_SetupRepeatCount

LABEL_F389BB:
	calr SeqAcc_HandlePlaybackTick
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	jp SeqPlay_SaveStateAndCleanup

SeqAcc_UpdateEndPosition:
	ldda16 xwa, 10435
	cpdm16 62015, xwa
	ret ule
	stda16 62015, xwa
	ret

SeqAcc_SetupRepeatCount:
	stdi16 10438, 0
	bitda 0, 62012
	jr z, SeqAcc_CheckRepeatEdgeCases
	ldda16 xwa, 62008
	cpda16 xwa, 9832
	jr nz, SeqAcc_CheckRepeatEdgeCases
	ldmm16 10438, 10408

SeqAcc_CheckRepeatEdgeCases:
	ldda16 xwa, 9832
	extz xwa
	bit 15, wa
	jr z, SeqAcc_UpdatePlaybackFlags
	cpdi16 62008, 1
	jr nz, SeqAcc_UpdatePlaybackFlags
	ldmm16 10438, 10408

SeqAcc_UpdatePlaybackFlags:
	ldda8 a, 10407
	res 3, a
	stda8 10407, a
	ldda16 xbc, 9832
	cps bc, 1
	jr z, SeqPlay_CheckFlagsAndInit
	extz xbc
	bit 15, bc
	jr nz, SeqPlay_CheckFlagsAndInit
	set 3, a
	stda8 10407, a

SeqPlay_CheckFlagsAndInit:
	jp SeqPlay_InitStartState

LABEL_F38A32:
	dec 4, xsp
	ldda8 a, 10437
	bit 5, a
	jr nz, LABEL_F38A4B
	bitda 2, 1057
	jr z, LABEL_F38A4B
	cpdi16 10408, 0
	jr nz, LABEL_F38A50

LABEL_F38A4B:
	ldw hl, 0xFFFF
	jr LABEL_F38A87

LABEL_F38A50:
	bit 6, a
	jr nz, LABEL_F38A75
	ei 6
	ldmm8 10440, 1051
	ldmm16 10441, 1052
	ei 0
	ldmm16 8998, 10441
	lda xwa, (xsp)
	ld (xwa), 0x0
	calr SeqPlay_ActivatePartsAndSendOff
	jr LABEL_F38A85

LABEL_F38A75:
	calr LABEL_F38AE5
	cpdi16 10420, 0
	jr nz, LABEL_F38A85
	stdi8 8956, 0

LABEL_F38A85:
	lds hl, 0

LABEL_F38A87:
	inc 4, xsp
	ret

SeqPlay_ActivatePartsAndSendOff:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), xwa
	setda 6, 10437
	ldda16 xwa, 10408
	andda16 xwa, 10420
	stda16 10410, xwa
	stda16 10438, xwa
	cpl wa
	anddm16 61854, xwa
	call Audio_CheckSubsystemReady
	ldi_berp 0xFB, 1

LABEL_F38AB3:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F38AC1
	slaa bc

LABEL_F38AC1:
	andda16 xbc, 10438
	jr z, LABEL_F38AD0
	ldto_berp A, 0xFB
	extz wa
	call Part_SendVoiceOffAndCCEvents

LABEL_F38AD0:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F38AB3
	ld xwa, (xsp + 2)
	calr SeqPlay_ProcessPartVoices
	pop_werp 0xFA
	inc 4, xsp
	ret

LABEL_F38AE5:
	push_werp 0xFA
	resda 6, 10437
	setda 5, 10437
	ldi_berp 0xFB, 1

LABEL_F38AF3:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F38B01
	slaa bc

LABEL_F38B01:
	andda16 xbc, 10438
	jr z, LABEL_F38B10
	ldto_berp A, 0xFB
	extz wa
	call SeqBuf_WriteNoteOffEntry

LABEL_F38B10:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_F38AF3
	ei 6
	ldmm8 10443, 1051
	ldmm16 10444, 1052
	stdi16 10410, 0
	ei 0
	stdi16 10408, 0
	ldda16 xwa, 10438
	orddm16 61854, xwa
	call Audio_CheckSubsystemReady
	pop_werp 0xFA
	ret

LABEL_F38B45:
	stdi8 10437, 0
	stdi16 10438, 0
	ldda8 a, 10418
	res 2, a
	res 1, a
	res 7, a
	stda8 10418, a
	bitda 0, 62012
	jr z, SeqPlay_InitTempoAndActivateParts
	ldda16 xwa, 62008
	cpda16 xwa, 9832
	jr nz, SeqPlay_InitTempoAndActivateParts
	ldmm16 10438, 10408

SeqPlay_InitTempoAndActivateParts:
	call TempoRingBuf_Init
	ldda16 xwa, 10408
	cps wa, 0
	jr z, SeqPlay_InitAccAndSetMode
	orddm16 61854, xwa
	setda 3, 10419
	call Audio_CheckSubsystemReady
	setda 0, 10437
	ldda8 a, 10418
	bit 0, a
	jr z, SeqPlay_InitAccAndSetMode
	set 1, a
	stda8 10418, a
	ldmm16 9014, 9832

SeqPlay_InitAccAndSetMode:
	call SeqAcc_InitPlaybackState
	ldb a, 0xC
	bitda 0, 10418
	jr nz, LABEL_F38BB7
	ldb a, 0xB

LABEL_F38BB7:
	stda8 8956, a
	lds hl, 0
	ret

LABEL_F38BBE:
	.byte 0xd1, 0x38, 0xf2, 0x20, 0xd8, 0x61, 0xf1, 0x38
	.byte 0xf2, 0x50, 0xd8, 0xcf, 0xe6, 0x03, 0x63, 0x06
	.byte 0xf1, 0x38, 0xf2, 0x02, 0xe6, 0x03, 0x1e, 0x27
	.byte 0x00, 0xd1, 0x38, 0xf2, 0x20, 0xd1, 0x3a, 0xf2
	.byte 0xf0, 0x67, 0x06, 0xd8, 0x61, 0xf1, 0x3a, 0xf2
	.byte 0x50, 0x78, 0xee, 0xfd, 0xd1, 0x38, 0xf2, 0x20
	.byte 0xd8, 0xd9, 0x63, 0x06, 0xd8, 0x69, 0xf1, 0x38
	.byte 0xf2, 0x50, 0x1e, 0x5d, 0x00, 0x78, 0xda, 0xfd
	.byte 0xf1, 0xb2, 0x28, 0xc8, 0x66, 0x36, 0xd1, 0x38
	.byte 0xf2, 0x20, 0xd8, 0xda, 0x6e, 0x13, 0xf1, 0x68
	.byte 0x26, 0x02, 0x02, 0x80, 0xf1, 0xec, 0x26, 0x02
	.byte 0x02, 0x80, 0xf1, 0x3f, 0xf2, 0x02, 0x03, 0x00
	.byte 0x0e, 0xd8, 0xdb, 0x6e, 0x13, 0xf1, 0x68, 0x26
	.byte 0x02, 0x01, 0x00, 0xf1, 0xec, 0x26, 0x02, 0x01
	.byte 0x00, 0xf1, 0x3f, 0xf2, 0x02, 0x02, 0x00, 0x0e
	.byte 0xd8, 0xdb, 0xb0, 0xf7, 0xd1, 0x38, 0xf2, 0x20
	.byte 0xd8, 0x69, 0xf1, 0xc3, 0x28, 0x50, 0x1e, 0x82
	.byte 0xfd, 0xd1, 0x38, 0xf2, 0x20, 0xd1, 0x3f, 0xf2
	.byte 0xa0, 0xf1, 0x68, 0x26, 0x50, 0xf1, 0xec, 0x26
	.byte 0x50, 0x0e, 0xf1, 0xb2, 0x28, 0xc8, 0x66, 0x36
	.byte 0xd1, 0x38, 0xf2, 0x20, 0xd8, 0xd9, 0x6e, 0x13
	.byte 0xf1, 0x68, 0x26, 0x02, 0x02, 0x80, 0xf1, 0xec
	.byte 0x26, 0x02, 0x02, 0x80, 0xf1, 0x3f, 0xf2, 0x02
	.byte 0x02, 0x00, 0x0e, 0xd8, 0xda, 0x6e, 0x13, 0xf1
	.byte 0x68, 0x26, 0x02, 0x02, 0x00, 0xf1, 0xec, 0x26
	.byte 0x02, 0x02, 0x80, 0xf1, 0x3f, 0xf2, 0x02, 0x03
	.byte 0x00, 0x0e, 0xd8, 0xdb, 0xb0, 0xf7, 0xd1, 0x38
	.byte 0xf2, 0x20, 0xd8, 0x69, 0xf1, 0xc3, 0x28, 0x50
	.byte 0x1e, 0x28, 0xfd, 0xd1, 0x38, 0xf2, 0x20, 0xd1
	.byte 0x3f, 0xf2, 0xa0, 0xf1, 0x68, 0x26, 0x50, 0xf1
	.byte 0xec, 0x26, 0x50, 0x0e, 0xd1, 0x3a, 0xf2, 0x20
	.byte 0xd8, 0xcf, 0xe7, 0x03, 0x67, 0x0b, 0xf1, 0x3a
	.byte 0xf2, 0x02, 0xe7, 0x03, 0x30, 0xe7, 0x03, 0x68
	.byte 0x0a, 0xd8, 0x61, 0xf1, 0x3a, 0xf2, 0x50, 0xd1
	.byte 0x3a, 0xf2, 0x20, 0xd1, 0x38, 0xf2, 0xf8, 0xb0
	.byte 0xf7, 0xd8, 0x69, 0xf1, 0x38, 0xf2, 0x50, 0x1e
	.byte 0x1e, 0xff, 0x1e, 0xf5, 0xfc, 0x0e, 0xd1, 0x3a
	.byte 0xf2, 0x20, 0xd8, 0xda, 0x6b, 0x0a, 0xf1, 0x3a
	.byte 0xf2, 0x02, 0x02, 0x00, 0xd8, 0xaa, 0x68, 0x0a
	.byte 0xd8, 0x69, 0xf1, 0x3a, 0xf2, 0x50, 0xd1, 0x3a
	.byte 0xf2, 0x20, 0xd1, 0x38, 0xf2, 0xf8, 0xb0, 0xf7
	.byte 0xd8, 0x69, 0xf1, 0x38, 0xf2, 0x50, 0x1e, 0x49
	.byte 0xff, 0x1e, 0xc6, 0xfc, 0x0e, 0xf1, 0xb2, 0x28
	.byte 0xc8, 0x66, 0x08, 0xd1, 0x38, 0xf2, 0x3f, 0x02
	.byte 0x00, 0xb0, 0xf3, 0xd1, 0x3f, 0xf2, 0x20, 0xd8
	.byte 0xcf, 0xe5, 0x03, 0x67, 0x08, 0xf1, 0x3f, 0xf2
	.byte 0x02, 0xe5, 0x03, 0x68, 0x06, 0xd8, 0x61, 0xf1
	.byte 0x3f, 0xf2, 0x50, 0xd1, 0x38, 0xf2, 0x20, 0xd8
	.byte 0x69, 0xf1, 0xc3, 0x28, 0x50, 0x1e, 0x83, 0xfc
	.byte 0xd1, 0x38, 0xf2, 0x20, 0xd1, 0x3f, 0xf2, 0xa0
	.byte 0xf1, 0x68, 0x26, 0x50, 0xf1, 0xec, 0x26, 0x50
	.byte 0x78, 0x7f, 0xfc, 0xf1, 0xb2, 0x28, 0xc8, 0x66
	.byte 0x08, 0xd1, 0x38, 0xf2, 0x3f, 0x02, 0x00, 0xb0
	.byte 0xf3, 0xd1, 0x3f, 0xf2, 0x20, 0xd8, 0xd8, 0x66
	.byte 0x06, 0xd8, 0x69, 0xf1, 0x3f, 0xf2, 0x50, 0xd1
	.byte 0x38, 0xf2, 0x20, 0xd8, 0x69, 0xf1, 0xc3, 0x28
	.byte 0x50, 0x1e, 0x47, 0xfc, 0xd1, 0x38, 0xf2, 0x20
	.byte 0xd1, 0x3f, 0xf2, 0xa0, 0xf1, 0x68, 0x26, 0x50
	.byte 0xf1, 0xec
	.ascii "&PxCü"

SeqPlay_ProcessPartVoices:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldmm16 10574, 10408
	ldi_berp 0xFB, 1

LABEL_F38DA4:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F38DB2
	slaa bc

LABEL_F38DB2:
	andda16 xbc, 10574
	jr z, LABEL_F38E25
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F38DE4
	stdi16 10408, 0
	stdi16 61854, 0
	stdi16 10410, 0
	stdi16 10420, 0
	call Audio_CheckSubsystemReady
	ldb l, 0x2
	jr LABEL_F38E40

LABEL_F38DE4:
	setda 0, 9834
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldto_berp C, 0xFB
	dec 1, c
	ld a, c
	extz wa
	add wa, wa
	ldada xde, 10446
	st_dri3w IZ, 0x07, 0xE8, 0xE0
	ldada xde, 10526
	st_dri3w IZ, 0x07, 0xE8, 0xE0
	ld a, c
	extz wa
	ldada xbc, 10558
	extz xwa
	add xwa, xbc
	ld (xwa), 0x5

LABEL_F38E25:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jrl ule, LABEL_F38DA4
	ld xwa, (xsp + 4)
	cp (xwa), 0x0
	jr z, LABEL_F38E3E
	ld xwa, (xsp + 4)
	call Seq_DispatchVoiceConfigEvent

LABEL_F38E3E:
	ldb l, 0x0

LABEL_F38E40:
	pop xiz
	inc 4, xsp
	ret

SeqAcc_ProcessTempoEvents:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ldda8 a, 10437
	and a, 0x60
	jrl z, LABEL_F38F7E
	lda xwa, (xsp + 2)
	call TempoRingBuf_ReadEventBytes
	cps l, 0
	jr z, LABEL_F38E71

LABEL_F38E5F:
	lda xwa, (xsp + 2)
	call Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 2)
	call TempoRingBuf_ReadEventBytes
	cps l, 0
	jr nz, LABEL_F38E5F

LABEL_F38E71:
	ldda8 e, 10443
	extz de
	ldda16 xbc, 10444
	ldw wa, 0x32
	call SeqData_ValidateProcess
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call VoiceAlloc_ProcessAll
	ldada xwa, 10558
	ld xbc, xwa
	ldada xde, 10510
	ldada xhl, 10526
	ldada xix, 10478
	lda xiy, (xwa + 16)

LABEL_F38EA2:
	ld_spiw WA, 0xED
	st_dpiw WA, 0xF1
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xiy
	jr c, LABEL_F38EA2
	ldda8 c, 10437
	ld a, c
	and a, 0x90
	jr nz, SeqPlay_AbortAndCleanup
	bit 5, c
	jr z, SeqPlay_AbortAndCleanup
	stdi8 9696, 0

LABEL_F38EC7:
	ldmm16 10576, 10574
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F38EDA
	slaa bc

LABEL_F38EDA:
	andda16 xbc, 10574
	jr z, LABEL_F38F3F
	calr LABEL_F39067
	bitda 7, 10437
	jr z, LABEL_F38EEF

SeqPlay_AbortAndCleanup:
	calr LABEL_F38FB1
	jrl SeqPlay_FinalizeAndReturn

LABEL_F38EEF:
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F38EFC
	slaa bc

LABEL_F38EFC:
	cpl bc
	anddm16 10574, xbc
	ldda8 a, 9696
	inc 1, a
	extz wa
	call LABEL_F40D30
	ldda8 a, 9696
	extz wa
	add wa, wa
	ldada xbc, 10446
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	call Part_StealAndReallocVoices
	ldda8 a, 9780
	ldfr_berp A, 0xFB
	ldda8 a, 9696
	inc 1, a
	stda8 9780, a
	call SeqPart_BufferSwap
	ldto_berp A, 0xFB
	stda8 9780, a

LABEL_F38F3F:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jrl c, LABEL_F38EC7
	stdi16 10410, 0
	stdi16 10420, 0
	stdi16 10408, 0
	ldda16 xwa, 10576
	orddm16 61854, xwa
	call Audio_CheckSubsystemReady
	setda 4, 10419
	resda 3, 10407
	ldw wa, 0x23
	call SoundCtrl_SaveAndSendCmd_EE
	jr SeqPlay_FinalizeAndReturn

LABEL_F38F7E:
	stdi16 10410, 0
	stdi16 10420, 0
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	setda 4, 10419
	resda 3, 10407
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call Part_ReinitAllActive

SeqPlay_FinalizeAndReturn:
	calr LABEL_F38FF2
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_F38FB1:
	bitda 4, 10437
	jr z, LABEL_F38FBC
	ldw wa, 0xF
	jr SeqPlay_SendStopAndClearParts

LABEL_F38FBC:
	cpdi8 36153, 136
	jr nz, LABEL_F38FC8
	ldw wa, 0x3B
	jr SeqPlay_SendStopAndClearParts

LABEL_F38FC8:
	ldw wa, 0x18

SeqPlay_SendStopAndClearParts:
	call SoundCtrl_SaveAndSendCmd_EE
	resda 0, 36232
	stdi16 10408, 0
	stdi16 10410, 0
	stdi16 10420, 0
	call Audio_CheckSubsystemReady
	setda 4, 10419
	resda 3, 10407
	ret

LABEL_F38FF2:
	calr LABEL_F3902B
	call SeqBuf_Init
	cpdi16 61854, 0
	jr z, LABEL_F3900C
	stdi8 4596, 0
	lds wa, 0
	call BitMapOut_PrepareAndRender

LABEL_F3900C:
	resda 3, 10419
	call Audio_CheckSubsystemReady
	stdi8 10437, 0
	ldda8 a, 10418
	res 7, a
	res 1, a
	res 2, a
	stda8 10418, a
	ret

LABEL_F3902B:
	push_werp 0xFA
	ldi_berp 0xFB, 1

LABEL_F39031:
	ldto_berp C, 0xFB
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F39041
	slaa de

LABEL_F39041:
	andda16 xde, 10574
	jr z, LABEL_F3905A
	ld a, c
	extz wa
	add wa, wa
	ldada xbc, 10446
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	call Part_StealAndReallocVoices

LABEL_F3905A:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F39031
	pop_werp 0xFA
	ret

LABEL_F39067:
	resda 2, 10363
	ldmm8 10584, 10440
	ldmm16 3299, 10441
	ldda8 a, 9696
	inc 1, a
	extz wa
	call SeqVoice_CountEventsInBar
	cpdi8 10362, 0
	jr nz, LABEL_F39094
	calr LABEL_F390D8
	cpdi8 10362, 0
	jr z, LABEL_F39099

LABEL_F39094:
	setda 7, 10437
	ret

LABEL_F39099:
	ldmm16 10578, 10415
	ldda16 xwa, 9830
	stda8 10580, a
	ldmm8 10584, 10443
	ldmm16 3299, 10444
	ldda8 a, 9696
	inc 1, a
	extz wa
	call SeqVoice_CountEventsInBar
	cpdi8 10362, 0
	call_24 z, 0xF3915B
	ldmm16 10581, 10415
	ldda16 xwa, 9830
	stda8 10583, a
	ret

LABEL_F390D8:
	push xiz
	stdi8 10362, 0
	call SeqData_ReadNextByte
	cpdi8 10584, 0
	jr nz, LABEL_F390F0
	cp l, 0x82
	jr nz, SeqData_HandleEndMark
	jr LABEL_F39154

LABEL_F390F0:
	cp l, 0x81
	jr z, SeqData_HandleEndMark

LABEL_F390F5:
	cp l, 0x82
	jr z, LABEL_F39154
	cp l, 0x84
	jr z, LABEL_F39154
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 10584
	jr c, SeqData_SkipToNextCommand

LABEL_F39118:
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz

LABEL_F39123:
	jr LABEL_F39159

SeqData_SkipToNextCommand:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqData_SkipToNextCommand
	cp l, 0x81
	jr nz, LABEL_F390F5

SeqData_HandleEndMark:
	cp l, 0x81
	jr nz, LABEL_F39123
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cp l, 0x82
	jr nz, LABEL_F39118

LABEL_F39154:
	stdi8 10362, 1

LABEL_F39159:
	pop xiz
	ret

LABEL_F3915B:
	push xiz
	stdi8 10362, 0
	cpdi8 10584, 0
	jr z, Seq_HandleBarMarkEvent
	call SeqData_ReadNextByte
	cp l, 0x81
	jr z, Seq_HandleBarMarkEvent

LABEL_F39171:
	cp l, 0x82
	jr z, Seq_HandleBarMarkEvent
	cp l, 0x84
	jr z, Seq_HandleBarMarkEvent
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	cpda8 l, 10584
	jr ule, SeqData_SkipToNextCommand_Fwd
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz
	jr LABEL_F391DA

SeqData_SkipToNextCommand_Fwd:
	call SeqData_AdvancePosition
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqData_SkipToNextCommand_Fwd
	cp l, 0x81
	jr nz, LABEL_F39171

Seq_HandleBarMarkEvent:
	cp l, 0x82
	jr nz, LABEL_F391DA
	ldda16 xwa, 9830
	cps wa, 5
	jr z, LABEL_F391C8
	dec 1, wa
	stda16 9830, xwa
	jr LABEL_F391DA

LABEL_F391C8:
	ldda16 xwa, 10415
	call PartCtrl_ReadWord_Off1
	stda16 10415, xhl
	stdi16 9830, 255

LABEL_F391DA:
	pop xiz
	ret

LABEL_F391DC:
	lda xsp, (xsp - 10)
	ldda8 a, 10437
	bit 5, a
	jr nz, LABEL_F3923A
	bit 6, a
	jr nz, LABEL_F3923A
	bitda 2, 1057
	jr z, LABEL_F3923A
	lda xwa, (xsp)
	call TempoRingBuf_ReadEventBytes
	bitm 7, (xsp + 256)
	jr nz, LABEL_F39205
	ldw wa, 0x68
	call SeqData_SetErrorCode

LABEL_F39205:
	lda xbc, (xsp + 1)
	ld a, (xbc)
	stda8 10440, a
	ldmm16 10441, 1052
	ld a, (xbc)
	cpda8 a, 1051
	jr ule, LABEL_F39229
	pushw 0x81
	call TempoRingBuf_WriteByte_Ext
	inc 2, xsp
	decdi16 1, 10441

LABEL_F39229:
	ldmm16 8998, 10441
	lds wa, 1
	call AppEvent_SendModeToggle
	lda xwa, (xsp)
	calr SeqPlay_ActivatePartsAndSendOff

LABEL_F3923A:
	lda xsp, (xsp + 10)
	ret

LABEL_F3923E:
	bitda 0, 10437
	ret z
	bitda 0, 62012
	ret z
	ldda16 xde, 1052
	ldda16 xwa, 62008
	ldda16 xbc, 9832
	cp bc, wa
	jr nz, LABEL_F3926C
	stda16 10585, xde
	ldda16 xwa, 10408
	andda16 xwa, 10420
	stda16 10438, xwa
	jr LABEL_F39287

LABEL_F3926C:
	cps wa, 1
	ret nz
	extz xbc
	bit 15, bc
	ret z
	stda16 10585, xde
	ldda16 xwa, 10408
	andda16 xwa, 10420
	stda16 10438, xwa

LABEL_F39287:
	cpl wa
	anddm16 61854, xwa
	jrl SeqPlay_ReactivatePartsAndResume

LABEL_F39290:
	pushw iz
	bitda 2, 1057
	jrl z, SeqPlay_PopIzRet
	ldda8 a, 10437
	bit 0, a
	jrl z, SeqPlay_PopIzRet
	bitda 0, 62012
	jrl z, SeqPlay_PopIzRet
	ldda16 xiy, 1052
	stda16 10585, xiy
	ldda8 a, 9010
	ldfr_berp A, 0xF8
	extz iz
	ldda16 xix, 9008
	ldfr_werp IY, 0xE2
	ldto_werp WA, 0xE2
	sub wa, ix
	ldfr_werp WA, 0xE2
	ldda16 xwa, 10408
	ldfr_werp WA, 0xE6
	andda16 xwa, 10420
	ldfr_werp WA, 0xE6
	ldda8 l, 10437
	ldda16 xbc, 9832
	ldto_werp DE, 0xE6
	cpl de
	bit 6, l
	jr nz, LABEL_F39327
	ldda16 xwa, 62008
	ld hl, bc
	cp bc, wa
	jr nz, LABEL_F392FA
	cp iy, ix
	jr z, LABEL_F3930C
	jrl SeqPlay_PopIzRet

LABEL_F392FA:
	cp iy, ix
	jrl c, SeqPlay_PopIzRet
	cp_werp IZ, 0xE2
	jrl ugt, SeqPlay_PopIzRet
	dec 1, wa
	cp wa, hl
	jrl nz, SeqPlay_PopIzRet

LABEL_F3930C:
	ldto_werp WA, 0xE6
	stda16 10410, xwa
	ldto_werp WA, 0xE6
	stda16 10438, xwa
	anddm16 61854, xde
	call Audio_CheckSubsystemReady
	calr SeqPlay_ReactivatePartsAndResume
	jr SeqPlay_PopIzRet

LABEL_F39327:
	ldda16 xwa, 62010
	ld de, bc
	cp bc, wa
	jr z, LABEL_F39342
	cp iy, ix
	jr c, SeqPlay_PopIzRet
	cp_werp IZ, 0xE2
	jr ugt, SeqPlay_PopIzRet
	inc 1, de
	cp de, wa
	jr z, LABEL_F39346
	jr SeqPlay_PopIzRet

LABEL_F39342:
	cp iy, ix
	jr nz, SeqPlay_PopIzRet

LABEL_F39346:
	res 6, l
	set 5, l
	stda8 10437, l
	stdi16 10408, 0
	stdi16 10410, 0
	ldda16 xwa, 10438
	orddm16 61854, xwa
	stdi16 10438, 0
	call Audio_CheckSubsystemReady
	ldda16 xwa, 10585
	dec 1, wa
	stda16 10444, xwa
	stdi8 10443, 95
	cpdi16 10420, 0
	jr nz, SeqPlay_PopIzRet
	stdi8 8956, 0
	ldmm16 9832, 62010
	call NoteEditSy_SendModeScrollReset

SeqPlay_PopIzRet:
	popw iz
	ret

SeqPlay_ReactivatePartsAndResume:
	dec 4, xsp
	push_werp 0xFA
	resda 3, 10419
	call Audio_CheckSubsystemReady
	setda 6, 10437
	ldi_berp 0xFB, 1

LABEL_F393AA:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F393B8
	slaa bc

LABEL_F393B8:
	andda16 xbc, 10438
	jr z, LABEL_F393C7
	ldto_berp A, 0xFB
	extz wa
	call Part_SendVoiceOffAndCCEvents

LABEL_F393C7:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F393AA
	ldda16 xwa, 10408
	andda16 xwa, 10420
	stda16 10410, xwa
	lda xwa, (xsp + 2)
	ld (xwa), 0x0
	calr SeqPlay_ProcessPartVoices
	ldmm16 10441, 10585
	stdi8 10440, 0
	ldmm16 8998, 10441
	pop_werp 0xFA
	inc 4, xsp
	ret

SeqAcc_InitPlaybackState:
	resda 5, 10419
	ldw wa, 0x32
	call SeqNotePool_Init
	resda 0, 1115
	call SeqPlay_CheckRepeatActive
	stda8 7570, l
	cpdi16 61854, 0
	jr nz, LABEL_F39434
	cpdi16 10408, 0
	jrl nz, SeqAcc_ClearStepCounter
	ldda8 a, 10407
	res 0, a
	set 1, a
	stda8 10407, a
	jr LABEL_F394B0

LABEL_F39434:
	bitda 1, 12931
	jr z, LABEL_F39441
	setda 4, 10419
	jrl LABEL_F394DE

LABEL_F39441:
	lds wa, 0
	ldw bc, 0xD
	call Part_FindVoiceByByte
	stda8 8988, l
	lds wa, 0
	ldw bc, 0x10
	call Part_FindVoiceByByte
	stda8 8990, l
	lds wa, 0
	ldw bc, 0xC
	call Part_FindVoiceByByte
	stda8 8992, l
	lds wa, 0
	ldw bc, 0xE
	call Part_FindVoiceByByte
	stda8 8994, l
	lds wa, 0
	ldw bc, 0xF
	call Part_FindVoiceByByte
	stda8 8996, l
	call BitMapOut_PrepareAndDisplay
	call BitMapOut_PrepareAndDisplaySimple
	setda 4, 10412
	bitda 3, 10407
	jr nz, LABEL_F39499
	calr LABEL_F394E1
	jr LABEL_F3949C

LABEL_F39499:
	calr LABEL_F395AF

LABEL_F3949C:
	resda 4, 10412
	cpdi16 8982, 0
	jr nz, LABEL_F394BC
	cpdi16 10408, 0
	jr nz, SeqAcc_ClearStepCounter

LABEL_F394B0:
	stdi8 8956, 0

SeqAcc_ClearStepCounter:
	stdi8 8968, 0
	jr SeqPlay_StateSetExit

LABEL_F394BC:
	calr SeqPlay_CheckDrumPartAndClearCounters
	cpdi16 10408, 0
	jr nz, SeqPlay_StateSetExit
	cpdi8 7570, 0
	jr nz, LABEL_F394D5
	stdi8 8956, 1
	jr SeqPlay_StateSetExit

LABEL_F394D5:
	stdi8 8956, 4

SeqPlay_StateSetExit:
	call SeqPlay_ResetStartState

LABEL_F394DE:
	ldb l, 0x0
	ret

LABEL_F394E1:
	resda 0, 10406
	call AccWrap_PositionClear
	resda 1, 8974
	stdi8 7560, 0
	stdi8 7562, 0
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ldmm8 9010, 1075
	call SeqMode_SendStatusUpdate
	stdi16 9008, 0
	stdi16 9832, 1
	call NoteEditSy_SendModeScrollReset
	stdi16 9004, 0
	call SeqBuf_Init
	stdi8 1073, 0
	ldda8 a, 10407
	set 0, a
	res 1, a
	stda8 10407, a
	cpdi8 7570, 1
	jr nz, LABEL_F39552
	ldda16 xwa, 9000
	lds bc, 0
	call Voice_ScanAvailableChannel
	call SeqPart_InitVoiceChannelConfig

LABEL_F39552:
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
	ldw bc, 0xD
	call Part_FindVoiceByByte
	cp l, 0xFF
	jr z, SeqPlay_MidiTimingJP
	ld a, l
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F39593
	slaa bc

LABEL_F39593:
	andda16 xbc, 61854
	jr z, SeqPlay_MidiTimingJP
	extz hl
	lds wa, 0
	ld bc, hl
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqPlay_MidiTimingJP
	setda 1, 10407

SeqPlay_MidiTimingJP:
	jp Seq_SyncPositionAndOutputMIDITiming

LABEL_F395AF:
	push_werp 0xFA
	ldi_berp 0xFB, 0
	stdi8 1073, 0
	stdi8 7560, 0
	stdi8 7562, 0
	ldda8 a, 10407
	set 0, a
	res 1, a
	stda8 10407, a
	call SeqBuf_Init
	cpdi8 7570, 1
	jr nz, SeqPlay_VoiceChannelCfg
	ldda16 xwa, 9000
	lds bc, 0
	call Voice_ScanAvailableChannel
	call SeqPart_InitVoiceChannelConfig
	ldda16 xwa, 1052
	cpda16 xwa, 9000
	jr nz, SeqPlay_VoiceChannelCfg
	cpdi8 1051, 0
	jr nz, SeqPlay_VoiceChannelCfg
	ldi_berp 0xFB, 1
	jr SeqPlay_ConfigureVoiceChannels

SeqPlay_VoiceChannelCfg:
	cpi_berp 0xFB, 0
	jr nz, SeqPlay_ConfigureVoiceChannels
	ldda8 c, 1051
	extz bc
	ldda16 xwa, 1052
	call Voice_ScanAvailableChannel

SeqPlay_ConfigureVoiceChannels:
	ldda16 xwa, 1052
	call SeqScan_ProcessAllParts
	ldda8 c, 1051
	extz bc
	ldda16 xwa, 1052
	calr SeqPlay_AssignAccompVoices
	ldda8 c, 1051
	extz bc
	ldda16 xwa, 1052
	calr SeqPlay_AssignBassVoices
	ldda8 c, 1051
	extz bc
	ldda16 xwa, 1052
	calr SeqPlay_AssignChordVoices
	call LABEL_F487DF
	bitda 0, 10406
	jr z, LABEL_F39651
	setda 1, 10407

LABEL_F39651:
	ldmm8 9010, 1075
	call SeqMode_SendStatusUpdate
	ldmm16 9008, 1052
	cpdi16 8980, 0
	jr z, LABEL_F3966D
	setda 0, 10407

LABEL_F3966D:
	lds wa, 0
	ldw bc, 0xD
	call Part_FindVoiceByByte
	cp l, 0xFF
	jr z, SeqPlay_MidiTimingSync
	ld a, l
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F39688
	slaa bc

LABEL_F39688:
	andda16 xbc, 61854
	jr z, SeqPlay_MidiTimingSync
	extz hl
	lds wa, 0
	ld bc, hl
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqPlay_MidiTimingSync
	setda 1, 10407

SeqPlay_MidiTimingSync:
	call Seq_SyncPositionAndOutputMIDITiming
	pop_werp 0xFA
	ret

LABEL_F396A8:
	dec 6, xsp
	push xiz
	resda 0, 1115
	bitda 1, 10407
	jrl z, SeqPlay_PopIzSkip6Ret
	cpdi16 10408, 0
	jr z, LABEL_F396C5
	bitda 0, 10418
	jrl nz, SeqPlay_PopIzSkip6Ret

LABEL_F396C5:
	lds wa, 0
	ldw bc, 0xD
	call Part_FindVoiceByByte
	ldfr_berp L, 0xFA
	cp_erpb 0xFA, 0xFF
	jr nz, LABEL_F396EA
	lds wa, 0
	ldw bc, 0xE
	call Part_FindVoiceByByte
	ldfr_berp L, 0xFA
	cp_erpb 0xFA, 0xFF
	jrl z, SeqPlay_PopIzSkip6Ret

LABEL_F396EA:
	ldto_berp A, 0xFA
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F396F8
	slaa bc

LABEL_F396F8:
	andda16 xbc, 61854
	jrl z, SeqPlay_PopIzSkip6Ret
	cpdi8 36148, 19
	jr nz, LABEL_F3970D
	setda 0, 1115
	jrl SeqPlay_PopIzSkip6Ret

LABEL_F3970D:
	ldto_berp C, 0xFA
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqPlay_PopIzSkip6Ret
	ldto_berp A, 0xFA
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9016
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	cpda16 xwa, 1052
	jr nz, SeqPlay_PopIzSkip6Ret
	ld a, (xbc + 2)
	cp a, 0x82
	jr z, SeqPlay_PopIzSkip6Ret
	ldfr_berp A, 0xFB
	and_erpb 0xFB, 0xF0
	ldto_berp A, 0xFA
	extz wa
	cp_erpb 0xFB, 0x90
	jr nz, LABEL_F39761
	cp (xbc + 3), 0x0
	jr nz, LABEL_F3975F
	setda 0, 1115
	calr SeqPlay_ProcessTempoVoiceEvent

LABEL_F3975F:
	jr SeqPlay_PopIzSkip6Ret

LABEL_F39761:
	ldmw2 (xsp + 4), 0x28AF
	ldda16 xiz, 9830
	lda xhl, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	mriw4 0x93, 0x19, 0xAF, 0x28
	mriw4 0x92, 0x19, 0x66, 0x26

Seq_ScanForBarMarker:
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x81
	jr z, SeqData_BarMarkerWrite
	cp_erpb 0xFB, 0x82
	jr nz, LABEL_F397B1

SeqData_BarMarkerWrite:
	mrdw5 0x9F, 0x04, 0x19, 0xAF, 0x28
	stda16 9830, xiz

SeqPlay_PopIzSkip6Ret:
	pop xiz
	inc 6, xsp
	ret

LABEL_F397B1:
	call SeqData_AdvancePosition
	cp_erpb 0xFB, 0x85
	jr z, Seq_ScanForBarMarker
	bit_erpb 0xFB, 0x07
	jr z, Seq_ScanForBarMarker
	cp_erpb 0xFB, 0x90
	jr nz, Seq_ScanForBarMarker
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr nz, SeqData_BarMarkerWrite
	setda 0, 1115
	ldto_berp A, 0xFA
	extz wa
	calr SeqPlay_ProcessTempoVoiceEvent
	jr SeqData_BarMarkerWrite

SeqPlay_ProcessTempoVoiceEvent:
	lda xsp, (xsp - 12)
	ld (xsp + 10), a
	ldw (xsp + 4), 0xFFFF
	ldw (xsp + 6), 0x0
	ld c, (xsp + 10)
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cp l, 0xE
	jrl nz, LABEL_F398B4
	ldmw2 (xsp), 0x28AF
	ldmw2 (xsp + 2), 0x2666
	ld a, (xsp + 10)
	extz wa
	call Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jrl nz, SeqVoice_ValidateAndWriteDefault

LABEL_F3981C:
	call SeqData_ReadNextByte
	bit 7, l
	jr z, SeqVoice_EventAdvanceLoop
	cp l, 0x82
	jr z, SeqVoice_ChannelValidation_Check
	cp l, 0x84
	jr z, SeqVoice_ChannelValidation_Check
	cp l, 0x81
	jr z, SeqVoice_ChannelValidation_Check
	and l, 0xF0
	cp l, 0x90
	jr nz, LABEL_F39860
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	call SeqData_ReadNextByte
	cp l, 0x10
	jr ugt, SeqVoice_ChannelValidation_Check
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	incm 1, (xsp + 6)
	jr SeqVoice_EventAdvanceLoop

LABEL_F39860:
	cp l, 0xB0
	jr nz, SeqVoice_EventAdvanceLoop
	lda xwa, (xsp + 8)
	calr LABEL_F398B8
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
	cpdi8 10362, 0
	jr nz, SeqVoice_ValidateAndWriteDefault
	cpw (xsp + 6), 0x3
	jr c, LABEL_F3981C

SeqVoice_ChannelValidation_Check:
	cpw (xsp + 4), 0x0
	jr ge, LABEL_F398A0
	resda 0, 1115

LABEL_F398A0:
	cpw (xsp + 6), 0x3
	jr nc, SeqVoice_ValidateAndWriteDefault
	resda 0, 1115

SeqVoice_ValidateAndWriteDefault:
	mriw4 0x97, 0x19, 0xAF, 0x28
	mrdw5 0x9F, 0x02, 0x19, 0x66, 0x26

LABEL_F398B4:
	lda xsp, (xsp + 12)
	ret

LABEL_F398B8:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), xwa
	ld xwa, (xsp + 2)
	ldw (xwa), 0xFFFF
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cp l, 0x48
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	cps l, 3
	jr nz, SeqData_EventParseExit
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqVoice_DataReadError_Return
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, LABEL_F3991B

SeqVoice_DataReadError_Return:
	ldw hl, 0xFFFF
	jr LABEL_F39935

LABEL_F3991B:
	call SeqData_ReadNextByte
	and l, 0x7
	cps l, 7
	jr nz, SeqData_EventParseExit
	ldto_berp C, 0xFB
	and c, 0x7
	extz bc
	ld xwa, (xsp + 2)
	ld (xwa), bc

SeqData_EventParseExit:
	lds hl, 0

LABEL_F39935:
	pop_werp 0xFA
	inc 4, xsp
	ret

SeqPlay_CheckDrumPartAndClearCounters:
	ldda8 a, 8988
	cp a, 0xFF
	jr z, SeqPlay_ClearCountersAndProcess
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3994F
	slaa bc

LABEL_F3994F:
	ld wa, bc
	andda16 xbc, 61854
	jr nz, LABEL_F3995D
	andda16 xwa, 8980
	jr z, SeqPlay_ClearCountersAndProcess

LABEL_F3995D:
	setda 6, 10412

SeqPlay_ClearCountersAndProcess:
	stdi8 7530, 0
	stdi8 10338, 0
	stdi8 10340, 0
	stdi8 10342, 0
	jrl LABEL_F396A8

SeqPlay_IterateAllChannels:
	lda xsp, (xsp - 22)
	push_werp 0xFA
	stdi8 7556, 0
	stdi8 7558, 0
	call LABEL_F3DAD7
	ld (xsp + 2), 0x1

LABEL_F39990:
	ld a, (xsp + 2)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3999E
	slaa bc

LABEL_F3999E:
	andda16 xbc, 61854
	jrl nz, SeqPlay_CheckChannelContinue
	jrl SeqPlay_IncrLoopCounter

LABEL_F399A8:
	ld a, (xsp + 2)
	extz wa
	lda xix, (xsp + 12)
	ld l, a
	ld e, l
	dec 1, e
	ld (xsp + 10), e
	extz de
	sla de, 3
	ldada xbc, 9016
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
	ldi_berp 0xE2, 0

LABEL_F399EA:
	ldto_berp L, 0xE2
	extz hl
	inc 2, hl
	ld e, (xsp + 4)
	dec 1, e
	extz de
	sla de, 3
	ld xbc, (xsp + 6)
	st_dri3b A, 0x07, 0xE4, 0xE8
	extz xhl
	add xhl, xbc
	ldto_berp E, 0xE2
	extz de
	ld c, (xhl)
	lda_dri3 XHL, 0x07, 0xF4, 0xE8
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F399EA
	ld e, (xix)
	ld c, e
	and c, 0xF0
	ldfr_berp C, 0xFB
	cp e, 0x82
	jr nz, LABEL_F39A43
	lds bc, 1
	ld a, (xsp + 10)
	and a, 0xF
	jr z, LABEL_F39A36
	slaa bc

LABEL_F39A36:
	cpl bc
	anddm16 8982, xbc
	anddm16 8980, xbc
	jrl SeqPlay_IncrLoopCounter

LABEL_F39A43:
	cp e, 0x81
	jrl z, SeqPlay_IncrLoopCounter
	cp e, 0x84
	jrl z, SeqPlay_IncrLoopCounter
	cp_erpb 0xFB, 0x90
	jrl z, SeqPlay_IncrLoopCounter
	cp e, 0x85
	jr nz, LABEL_F39A6A
	setda 1, 10407
	cpdi8 7572, 0
	jrl z, LABEL_F39B6B
	jrl LABEL_F39B76

LABEL_F39A6A:
	cp e, 0x86
	jr nz, LABEL_F39A7E
	resda 1, 10407
	cpdi8 7572, 0
	jrl z, LABEL_F39B6B
	jrl LABEL_F39B76

LABEL_F39A7E:
	lda xhl, (xix + 4)
	lda xbc, (xix + 5)
	cp_erpb 0xFB, 0xB0
	jrl nz, LABEL_F39B0C
	ld a, (xsp + 2)
	cpda8 a, 8988
	jrl nz, SeqCh_DispatchMidiEvent
	cp (xix + 2), 0x48
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xix + 3)
	cps a, 6
	jr nz, LABEL_F39AC0
	bitm 2, (xbc)
	jr z, SeqCh_DispatchMidiEvent
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	setda 1, 8974
	stdi16 4360, 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqCh_AllocSlotAndDispatch

LABEL_F39AC0:
	cps a, 5
	jr nz, SeqCh_DispatchMidiEvent
	ld a, (xbc)
	bit 2, a
	jr z, LABEL_F39AE5
	bitm 2, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	setda 1, 8974
	stdi16 4360, 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr SeqCh_AllocSlotAndDispatch

LABEL_F39AE5:
	bit 3, a
	jr z, SeqCh_DispatchMidiEvent
	bitm 3, (xhl)
	jr z, SeqCh_DispatchMidiEvent
	setda 1, 8974
	stdi16 4360, 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl

SeqCh_AllocSlotAndDispatch:
	call SeqBuf_AllocNextSlot
	stda8 8972, l
	jr SeqCh_DispatchMidiEvent

LABEL_F39B0C:
	cp e, 0xD3
	jr nz, SeqCh_DispatchMidiEvent
	setda 6, 10413

SeqCh_DispatchMidiEvent:
	ld a, (xsp + 2)
	extz wa
	cpdi8 7572, 0
	jr nz, LABEL_F39B26
	calr SeqNote_ProcessForChannel
	jr LABEL_F39B29

LABEL_F39B26:
	calr SeqNote_ProcessForChannelAlt

LABEL_F39B29:
	cps l, 0
	jr nz, SeqPlay_IncrLoopCounter
	cp_erpb 0xFB, 0xC0
	jr nz, SeqCh_DispatchChannelConfigLoad
	lda xwa, (xsp + 16)
	cp (xwa + 2), 0x48
	jr nz, SeqCh_DispatchChannelConfigLoad
	cp (xwa + 3), 0x0
	jr nz, SeqCh_DispatchChannelConfigLoad
	cp a, 0x10
	jr nz, SeqCh_DispatchChannelConfigLoad
	ldda8 a, 7564
	extz wa
	ldda8 c, 7566
	extz bc
	call Rhythm_NoteDispatchWrapper
	stda8 9010, l
	call SeqMode_SendStatusUpdate

SeqCh_DispatchChannelConfigLoad:
	cpdi8 7572, 0
	jr nz, LABEL_F39B71
	ld a, (xsp + 2)
	extz wa

LABEL_F39B6B:
	call SeqCh_LoadChannelConfig
	jr SeqPlay_CheckChannelContinue

LABEL_F39B71:
	ld a, (xsp + 2)
	extz wa

LABEL_F39B76:
	call SeqData_ParseSequenceStream

SeqPlay_CheckChannelContinue:
	ld a, (xsp + 2)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F39B88
	slaa bc

LABEL_F39B88:
	andda16 xbc, 8982
	jrl nz, LABEL_F399A8

SeqPlay_IncrLoopCounter:
	incm8 1, (xsp + 2)
	cp (xsp + 2), 0x10
	jrl ule, LABEL_F39990
	pop_werp 0xFA
	lda xsp, (xsp + 22)
	ret

LABEL_F39BA0:
	resda 5, 10419
	stdi16 9004, 0
	resda 0, 10406
	call AccWrap_PositionClear
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ldda8 l, 1075
	stda8 9010, l
	call SeqMode_SendStatusUpdate
	stdi8 1073, 0
	setda 0, 10407
	call SeqBuf_Init
	resda 1, 10407
	calr LABEL_F39C09
	calr SeqPlay_IterateAllChannels
	ldda8 a, 10404
	extz wa
	call Demo_ProcessRecordEntry
	cps l, 0
	jr z, LABEL_F39BF8
	setda 1, 10407
	jr LABEL_F39BFC

LABEL_F39BF8:
	resda 1, 10407

LABEL_F39BFC:
	call Seq_SyncPositionAndOutputMIDITiming
	calr SeqPlay_CheckDrumPartAndClearCounters
	stdi8 8956, 1
	ret

LABEL_F39C09:
	dec 4, xsp
	push_werp 0xFA
	ldda8 a, 10404
	ldfr_berp A, 0xFB
	extz wa
	call LABEL_F86F48
	stda32 10302, xhl
	ldto_berp A, 0xFB
	extz wa
	call LABEL_F86F92
	ld (xsp + 2), xhl
	ldi_berp 0xFB, 1

LABEL_F39C2E:
	ldto_berp E, 0xFB
	dec 1, e
	lds bc, 1
	ld a, e
	and a, 0xF
	jr z, LABEL_F39C3E
	slaa bc

LABEL_F39C3E:
	andda16 xbc, 61854
	jr z, LABEL_F39C92
	ldto_berp A, 0xFB
	mul a, 0x3
	dec 3, a
	ld c, a
	extz bc
	inc 1, bc
	ld xwa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE0, 0xE4
	ldfr_berp A, 0xF0
	extz ix
	ldto_berp A, 0xFB
	extz wa
	ld c, a
	dec 1, c
	extz bc
	sla bc, 2
	ldada xhl, 9184
	exts xbc
	add xbc, xhl
	ld (xbc), ix
	ldw (xbc + 2), 0x5
	ld c, e
	extz bc
	sla bc, 3
	ldada xde, 9016
	stiw_dri 0x07, 0xE8, 0xE4, 0x00, 0x00
	call SeqData_ParseSequenceStream

LABEL_F39C92:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F39C2E
	stdi8 8968, 0
	ldda16 xwa, 61854
	stda16 8982, xwa
	stda16 8980, xwa
	pop_werp 0xFA
	inc 4, xsp
	ret

SeqPlay_InitializePlayback:
	push_werp 0xFA
	resda 5, 10419
	stdi8 7572, 0
	ldda8 a, 36150
	cp a, 0x87
	jr z, LABEL_F39CCC
	cp a, 0x88
	jr nz, LABEL_F39CD5

LABEL_F39CCC:
	call LABEL_F38B45
	ldfr_berp L, 0xFB
	jr SeqPlay_FindVoicesAndReturn

LABEL_F39CD5:
	bitda 1, 10417
	jr nz, LABEL_F39CE3
	calr LABEL_F39CF3
	ldfr_berp L, 0xFB
	jr SeqPlay_FindVoicesAndReturn

LABEL_F39CE3:
	calr LABEL_F39DFF
	ldfr_berp L, 0xFB

SeqPlay_FindVoicesAndReturn:
	calr LABEL_F39EF0
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

LABEL_F39CF3:
	calr SeqAcc_InitPlaybackState
	ldda8 a, 10418
	res 2, a
	res 1, a
	res 7, a
	stda8 10418, a
	resda 3, 10419
	call Audio_CheckSubsystemReady
	resda 3, 10407
	cpdi16 10408, 0
	jrl z, LABEL_F39DFC
	stdi16 8998, 0
	stdi16 8954, 65535
	ldb l, 0x1
	ldb c, 0x0

LABEL_F39D2C:
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F39D37
	slaa de

LABEL_F39D37:
	andda16 xde, 10408
	jr z, LABEL_F39D52
	ld a, l
	extz wa
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F39D4C
	slaa de

LABEL_F39D4C:
	cpl de
	anddm16 8980, xde

LABEL_F39D52:
	inc 1, l
	inc 1, c
	cp l, 0x10
	jr ule, LABEL_F39D2C
	ldda8 a, 10418
	bit 0, a
	jr z, LABEL_F39D7B
	set 1, a
	stda8 10418, a
	ldda16 xwa, 9832
	stda16 9014, xwa
	setda 3, 10419
	call Audio_CheckSubsystemReady

LABEL_F39D7B:
	stdi16 9008, 0
	call NoteEditSy_SendModeScrollReset
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	ldda8 a, 1075
	stda8 9010, a
	call SeqMode_SendStatusUpdate
	cpdi16 61854, 0
	jr z, LABEL_F39DB2
	setda 3, 10419
	call Audio_CheckSubsystemReady
	jr LABEL_F39DCA

LABEL_F39DB2:
	stdi16 8980, 0
	ldda8 a, 10407
	set 0, a
	set 1, a
	stda8 10407, a
	call SeqBuf_Init

LABEL_F39DCA:
	call Audio_CheckSubsystemReady
	call TempoRingBuf_Init
	call BitMapOut_ComputeRegionDelta
	bitda 0, 10418
	jr nz, LABEL_F39DEC
	cpdi16 61854, 0
	jr z, LABEL_F39DE8
	ldb a, 0xB
	jr SeqPlay_StoreChannelVal

LABEL_F39DE8:
	ldb a, 0x7
	jr SeqPlay_StoreChannelVal

LABEL_F39DEC:
	ldb a, 0x8
	cpdi16 61854, 0
	jr z, SeqPlay_StoreChannelVal
	ldb a, 0xC

SeqPlay_StoreChannelVal:
	stda8 8956, a

LABEL_F39DFC:
	ldb l, 0x0
	ret

LABEL_F39DFF:
	push xiz
	calr SeqAcc_InitPlaybackState
	ldda8 a, 10418
	res 2, a
	res 1, a
	res 7, a
	stda8 10418, a
	cpdi16 10408, 0
	jrl z, LABEL_F39EEC
	ldmm16 8998, 1052
	stdi16 8954, 65535
	call LABEL_F3EFC5
	ldi_berp 0xFB, 1

LABEL_F39E30:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F39E3E
	slaa bc

LABEL_F39E3E:
	andda16 xbc, 10408
	jr z, LABEL_F39E56
	ldto_berp A, 0xFB
	stda8 8986, a
	ldto_berp A, 0xFB
	extz wa
	lds bc, 1
	call Chan_SetActiveBit

LABEL_F39E56:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F39E30
	ldda8 a, 10418
	ld c, a
	res 1, c
	ld a, c
	stda8 10418, c
	bit 0, c
	jr z, LABEL_F39E82
	set 1, a
	stda8 10418, a
	ldda16 xwa, 9832
	stda16 9014, xwa

LABEL_F39E82:
	setda 3, 10419
	call Audio_CheckSubsystemReady
	ldmm16 9008, 1052
	call NoteEditSy_SendModeScrollReset
	ldda8 a, 1075
	stda8 9010, a
	call SeqMode_SendStatusUpdate
	call Audio_CheckSubsystemReady
	call SeqBuf_Init
	call TempoRingBuf_Init
	call BitMapOut_ComputeRegionDelta
	ldda8 a, 8986
	ldfr_berp A, 0xFB
	extz wa
	lds bc, 0
	call Chan_SetActiveBit
	ldda16 xiz, 61854
	ldto_berp A, 0xFB
	extz wa
	lds bc, 1
	call Chan_SetActiveBit
	bitda 0, 10418
	jr nz, LABEL_F39EE0
	cps iz, 0
	jr z, LABEL_F39EDC
	ldb a, 0x13
	jr SeqPlay_StoreCheckValue

LABEL_F39EDC:
	ldb a, 0xF
	jr SeqPlay_StoreCheckValue

LABEL_F39EE0:
	ldb a, 0x10
	cps iz, 0
	jr z, SeqPlay_StoreCheckValue
	ldb a, 0x14

SeqPlay_StoreCheckValue:
	stda8 8956, a

LABEL_F39EEC:
	ldb l, 0x0
	pop xiz
	ret

LABEL_F39EF0:
	lds wa, 0
	ldw bc, 0xC
	call Part_FindVoiceByByte
	stda8 8992, l
	lds wa, 0
	ldw bc, 0xE
	call Part_FindVoiceByByte
	stda8 8994, l
	lds wa, 0
	ldw bc, 0xF
	call Part_FindVoiceByByte
	stda8 8996, l
	ldda8 a, 36150
	cp a, 0x87
	jr z, SeqPlay_ClearPositionAndFlags
	cp a, 0x88
	jr z, SeqPlay_ClearPositionAndFlags
	resda 1, 8970

SeqPlay_ClearPositionAndFlags:
	stdi8 7522, 0
	stdi16 9006, 0
	resda 1, 10419
	ret

LABEL_F39F39:
	push_werp 0xFA
	calr SeqPlay_PreparePlaybackState
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, LABEL_F39F4D
	resda 1, 10419
	jr SeqPlay_ReassignVoicesAlt

LABEL_F39F4D:
	bitda 0, 10437
	jr z, LABEL_F39F79
	resda 1, 10419
	ldda8 a, 8956
	extz wa
	lda_24 xbc, 0xe444e2
	ldmm_srib 0x07, 0xE4, 0xE0, 0xFC, 0x22
	bitda 0, 62012
	jr nz, SeqPlay_ReassignVoicesAlt
	resda 3, 10419
	call Audio_CheckSubsystemReady
	jr SeqPlay_ReassignVoicesAlt

LABEL_F39F79:
	resda 3, 10419
	call Audio_CheckSubsystemReady
	bitda 1, 10419
	jr nz, LABEL_F39F97
	bitda 0, 10418
	jr z, LABEL_F39F97
	ldmm16 9832, 9014
	call NoteEditSy_SendModeScrollReset

LABEL_F39F97:
	bitda 1, 10419
	jr nz, LABEL_F39FB7
	calr SeqPlay_ReassignVoiceChannels
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, LABEL_F39FAE

SeqPlay_ReassignVoicesAlt:
	ldto_berp L, 0xFB
	jrl LABEL_F3A096

LABEL_F39FAE:
	cpdi16 10410, 0
	jrl z, SeqPlay_ReturnFalse

LABEL_F39FB7:
	setda 0, 36232
	setda 0, 9834
	ldda8 a, 8956
	extz wa
	lda_24 xbc, 0xe444e2
	ldmm_srib 0x07, 0xE4, 0xE0, 0xFC, 0x22
	ldda8 c, 8970
	set 0, c
	stda8 8970, c
	ldda8 a, 10419
	bit 1, a
	jr z, LABEL_F39FEF
	res 1, a
	stda8 10419, a
	jrl SeqPlay_ReturnFalse

LABEL_F39FEF:
	res 1, c
	stda8 8970, c
	cpdi16 61854, 0
	jr z, LABEL_F3A005
	bitda 1, 10407
	jrl z, SeqPlay_ReturnFalse

LABEL_F3A005:
	bitda 0, 10418
	jrl nz, SeqPlay_ReturnFalse
	ldda8 e, 8996
	cp e, 0xFF
	jr z, SeqPlay_AssignBassVoice
	ld a, e
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3A022
	slaa bc

LABEL_F3A022:
	andda16 xbc, 10410
	jr z, SeqPlay_AssignBassVoice
	lda_24 xbc, 0xe444fa
	bitda 1, 10417
	jr z, LABEL_F3A03D
	ldw wa, 0x12
	lds de, 2
	calr ToneVoice_AssignChannel
	jr SeqPlay_AssignBassVoice

LABEL_F3A03D:
	extz de
	ld wa, de
	lds de, 2
	calr ToneVoice_AssignChannel
	ldda8 a, 8996
	extz wa
	call SeqEvent_CreateWithChannelValidation

SeqPlay_AssignBassVoice:
	ldda8 e, 8994
	cp e, 0xFF
	jr z, SeqPlay_ReturnFalse
	ld a, e
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3A066
	slaa bc

LABEL_F3A066:
	andda16 xbc, 10410
	jr z, SeqPlay_ReturnFalse
	lda_24 xbc, 0xe444fa
	bitda 1, 10417
	jr z, LABEL_F3A081
	ldw wa, 0x12
	lds de, 2
	calr ToneVoice_AssignChannel
	jr SeqPlay_ReturnFalse

LABEL_F3A081:
	extz de
	ld wa, de
	lds de, 2
	calr ToneVoice_AssignChannel
	ldda8 a, 8994
	extz wa
	call SeqEvent_CreateWithChannelValidation

SeqPlay_ReturnFalse:
	ldb l, 0x0

LABEL_F3A096:
	pop_werp 0xFA
	ret

SeqPlay_PreparePlaybackState:
	call KeyScan_Enable
	resda 2, 13434
	ldda8 a, 7558
	cps a, 1
	call_24 z, 0xF3DA8E
	lds wa, 0
	call UI_PostDialEnable
	ldda16 xwa, 8980
	cps wa, 0
	jr z, KeyScan_DisableComplete_Return
	stda16 10420, xwa
	bitda 0, 10437
	jr z, LABEL_F3A0D5
	bitda 0, 10418
	jr z, LABEL_F3A0D5
	ldmm16 9832, 9014
	call NoteEditSy_SendModeScrollReset

LABEL_F3A0D5:
	call LABEL_F3923E
	call LABEL_F3E250
	cpdi8 36148, 19
	jr z, LABEL_F3A0E8
	setda 3, 10407

LABEL_F3A0E8:
	calr LABEL_F3A6CE
	ldmm16 7588, 1052
	cpdi16 10408, 0
	jr nz, KeyScan_DisableComplete_Return
	cpdi8 7570, 0
	jr nz, LABEL_F3A107
	stdi8 8956, 3
	jr LABEL_F3A10C

LABEL_F3A107:
	stdi8 8956, 6

LABEL_F3A10C:
	ldda8 a, 36150
	cp a, 0x87
	jr z, KeyScan_DisableComplete_Return
	cp a, 0x88
	jr z, KeyScan_DisableComplete_Return
	resda 1, 8970

KeyScan_DisableComplete_Return:
	call KeyScan_Disable
	ldb l, 0x0
	ret

LABEL_F3A125:
	ldda8 a, 36150
	cp a, 0x87
	jr z, LABEL_F3A133
	cp a, 0x88
	jr nz, LABEL_F3A13A

LABEL_F3A133:
	call SeqAcc_ProcessTempoEvents
	jrl SeqPlay_ClearFlagsRet

LABEL_F3A13A:
	ldda8 a, 8970
	bit 1, a
	jr z, LABEL_F3A14D
	res 1, a
	stda8 8970, a
	jrl SeqPlay_ClearFlagsRet

LABEL_F3A14D:
	resda 7, 10414
	stdi8 7572, 0
	ldda16 xwa, 10420
	stda16 8980, xwa
	stdi16 10420, 0
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplaySimple
	call AccompSeq_StopSequence
	cpdi16 61854, 0
	jr z, SeqPlay_ClearFlagsRet
	cpdi8 36148, 19
	jr nz, LABEL_F3A19E
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	stdi16 10420, 0

LABEL_F3A19E:
	setda 2, 10407
	call Seq_SyncPositionAndOutputMIDITiming
	stdi8 1073, 0
	call Audio_CheckSubsystemReady
	ldda8 a, 13434
	bit 2, a
	jr z, SeqPlay_CheckSilentAndStop
	ldda8 e, 13076
	ldda8 c, 13077
	ldda8 a, 13096
	cps e, 0
	jr nz, LABEL_F3A1D0
	cps c, 0
	jr nz, LABEL_F3A1D0
	cps a, 0
	jr z, LABEL_F3A1D6

LABEL_F3A1D0:
	resda 0, 10406
	jr SeqPlay_CheckSilentAndStop

LABEL_F3A1D6:
	setda 0, 10406
	ldda8 a, 13434
	set 1, a
	stda8 13434, a

SeqPlay_CheckSilentAndStop:
	bitda 0, 10406
	jr z, LABEL_F3A1F3
	call AccWrap_FullStop
	setda 1, 10407

LABEL_F3A1F3:
	resda 2, 10407

SeqPlay_ClearFlagsRet:
	ldb l, 0x0
	ret

SeqPlay_ProcessVoiceAndNotes:
	lda xsp, (xsp - 12)
	push xiz
	ldda8 a, 36150
	cp a, 0x87
	jr z, LABEL_F3A20C
	cp a, 0x88
	jr nz, LABEL_F3A213

LABEL_F3A20C:
	call SeqAcc_ProcessTempoEvents
	jrl LABEL_F3A33B

LABEL_F3A213:
	cpdi16 10410, 0
	jr nz, LABEL_F3A289
	ldda8 a, 10430
	cp a, 0xFF
	jr z, SeqPlay_StopAndCleanup
	bitda 0, 8970
	jr nz, SeqPlay_StopAndCleanup
	inc 1, a
	ld c, a
	extz bc
	lds wa, 0
	ldw de, 0xD
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
	ldda8 a, 10418
	res 2, a
	res 1, a
	stda8 10418, a
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	stdi16 10420, 0
	resda 3, 10419
	call Audio_CheckSubsystemReady
	call SeqBuffer_ClearAndInitIteration
	call Audio_CheckSubsystemReady
	jrl LABEL_F3A33B

LABEL_F3A289:
	ldda16 xwa, 9012
	stda16 9832, xwa
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
	jr z, LABEL_F3A2AB

LABEL_F3A29B:
	lda xwa, (xsp + 8)
	calr Seq_DispatchVoiceConfigEvent
	lda xwa, (xsp + 8)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
	jr nz, LABEL_F3A29B

LABEL_F3A2AB:
	lda xiz, (xsp + 4)
	ei 6
	ldmw2 (xiz), 0x41C
	ldmi16 (xiz + 2), 0x41B
	ei 0
	lda xwa, (xsp + 4)
	ld e, (xwa + 2)
	extz de
	ld bc, (xwa)
	ldw wa, 0x32
	calr SeqData_ValidateProcess
	bitda 1, 10417
	jr z, LABEL_F3A2D6
	calr LABEL_F3D2A6
	jr LABEL_F3A2DD

LABEL_F3A2D6:
	call Part_CopyVoiceDataToAllChannels
	calr SeqPlay_ActivateAllChannels

LABEL_F3A2DD:
	stdi8 7522, 0
	stdi16 10420, 0
	ldda8 a, 10418
	res 2, a
	res 1, a
	stda8 10418, a
	call AccompSeq_StopSequence
	call AccWrap_PlayModeDispatch
	call AccWrap_DispatchAndWaitSync
	stdi8 7568, 1
	stdi8 7584, 1
	resda 3, 10407
	setda 1, 8970
	call SeqBuffer_ClearAndInitIteration
	stdi8 10430, 255
	bitda 1, 9834
	jr nz, LABEL_F3A333
	cpdi8 36148, 10
	jr z, LABEL_F3A337
	ldw wa, 0xA
	call UI_PostPartChangeEvent
	jr LABEL_F3A337

LABEL_F3A333:
	call LABEL_F994EA

LABEL_F3A337:
	resda 1, 9834

LABEL_F3A33B:
	ldb l, 0x0
	pop xiz
	lda xsp, (xsp + 12)
	ret

LABEL_F3A342:
	lda xsp, (xsp - 10)
	push xiz
	ldw (xsp + 4), 0x0
	calr SeqNote_ProcessNoteOn
	cps l, 0
	jr nz, LABEL_F3A3CC
	cpdi16 10408, 0
	jr z, SeqPlay_ReadTempoEvents_ReturnZero
	ldda8 a, 10437
	bit 0, a
	jr z, SeqPlay_ReadTempoEvents
	bit 6, a
	jr z, SeqPlay_ReadTempoEvents_ReturnZero

SeqPlay_ReadTempoEvents:
	lda xwa, (xsp + 6)
	calr TempoRingBuf_ReadEventBytes
	cps l, 0
	jr nz, LABEL_F3A384
	cpdi8 7570, 1
	jr nz, SeqPlay_ReadTempoEvents_ReturnZero
	bitda 1, 10417
	jr z, SeqPlay_ReadTempoEvents_ReturnZero
	calr LABEL_F3A56B
	jr SeqPlay_ReadTempoEvents_ReturnZero

LABEL_F3A384:
	cpdi8 7570, 1
	jr nz, SeqPlay_DispatchVoiceEvt
	ei 6
	ldda16 xiz, 1052
	ldda8 a, 1051
	ldfr_berp A, 0xFB
	ei 0
	ldda16 xwa, 7542
	cp wa, iz
	jr ugt, SeqPlay_DispatchVoiceEvt
	cp wa, iz
	jr nz, LABEL_F3A3AC
	cp_erpb 0xFB, 0x5F
	jr nz, SeqPlay_DispatchVoiceEvt

LABEL_F3A3AC:
	calr SeqPlay_ReconfigureVoices

SeqPlay_DispatchVoiceEvt:
	lda xwa, (xsp + 6)
	calr Seq_DispatchVoiceConfigEvent
	cpdi8 7528, 0
	jr nz, LABEL_F3A3C0
	ldb l, 0x3
	jr LABEL_F3A3CC

LABEL_F3A3C0:
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0xA
	jr c, SeqPlay_ReadTempoEvents

SeqPlay_ReadTempoEvents_ReturnZero:
	ldb l, 0x0

LABEL_F3A3CC:
	pop xiz
	lda xsp, (xsp + 10)
	ret

TempoRingBuf_ReadEventBytes:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ldi_berp 0xFB, 0
	jr LABEL_F3A3FA

LABEL_F3A3DC:
	ldto_berp C, 0xF8
	ld xwa, (xsp + 4)
	ld (xwa), c
	ld a, (xwa)
	extz wa
	call LABEL_F3EAF0
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr nz, LABEL_F3A404
	lds wa, 1
	call SeqData_SetErrorCode

LABEL_F3A3FA:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cps iz, 0
	jr ge, LABEL_F3A3DC

LABEL_F3A404:
	ldi_berp 0xFA, 1
	cpi_berp 0xFB, 1
	jr ule, LABEL_F3A437

LABEL_F3A40C:
	call TempoRingBuf_ReadByte
	ld iz, hl
	cps iz, 0
	jr ge, LABEL_F3A41C
	lds wa, 2
	call SeqData_SetErrorCode

LABEL_F3A41C:
	ldto_berp C, 0xFA
	extz bc
	ldto_berp E, 0xF8
	ld xwa, (xsp + 4)
	lda_dri3 XIY, 0x07, 0xE0, 0xE4
	inc1_berp 0xFA
	ldto_berp A, 0xFA
	cp_berp A, 0xFB
	jr c, LABEL_F3A40C

LABEL_F3A437:
	ldto_berp L, 0xFB
	pop xiz
	inc 4, xsp
	ret

Seq_DispatchVoiceConfigEvent:
	dec 6, xsp
	push xiz
	ld xiz, xwa
	ldmi16 (xsp + 6), 0x1D92
	ldmw2 (xsp + 8), 0x2326
	cp (xiz), 0x81
	jr nz, LABEL_F3A45F
	ld a, (xsp + 6)
	extz wa
	ld xbc, xiz
	calr LABEL_F3B8AA
	jrl SeqVoice_ReturnFalse

LABEL_F3A45F:
	cp (xsp + 6), 0x1
	jr nz, SeqVoice_DispatchByEventType
	ldda16 xwa, 9006
	cp (xsp + 8), wa
	jr nc, SeqVoice_DispatchByEventType
	ldw wa, 0x1E
	call SeqData_SetErrorCode
	jrl SeqVoice_ReturnFalse

SeqVoice_DispatchByEventType:
	ld c, (xiz + 1)
	extz bc
	cp (xiz), 0x80
	jr z, LABEL_F3A48C
	cp (xiz), 0x85
	jr z, LABEL_F3A48C
	cp (xiz), 0x86
	jr nz, LABEL_F3A4A0

LABEL_F3A48C:
	cp (xsp + 6), 0x1
	jr nz, LABEL_F3A498
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch

LABEL_F3A498:
	ld xwa, xiz
	calr LABEL_F3BBE1
	jrl SeqVoice_ReturnFalse

LABEL_F3A4A0:
	ld a, (xiz)
	and a, 0xF0
	cp a, 0xB0
	jr nz, LABEL_F3A4C5
	cp (xsp + 6), 0x1
	jr nz, LABEL_F3A4B6
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch

LABEL_F3A4B6:
	ld xwa, xiz
	calr LABEL_F3BEDB
	ld (xsp + 4), l
	cp (xsp + 4), 0x0
	jrl z, SeqVoice_ReturnFalse

LABEL_F3A4C5:
	ld xwa, xiz
	call LABEL_F3EB82
	cps l, 0
	jr ge, LABEL_F3A4D4
	ldb l, 0xFF
	jrl LABEL_F3A567

LABEL_F3A4D4:
	inc 1, l
	ld a, l
	cp (xsp + 6), 0x1
	jr nz, LABEL_F3A4E8
	ldda8 e, 8986
	cp a, e
	jr z, LABEL_F3A4F9
	jr SeqVoice_ReturnFalse

LABEL_F3A4E8:
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3A4F3
	slaa de

LABEL_F3A4F3:
	andda16 xde, 10408
	jr z, SeqVoice_ReturnFalse

LABEL_F3A4F9:
	ld a, (xiz)
	and a, 0xF0
	cp a, 0xC0
	jr z, LABEL_F3A514
	cp a, 0x90
	jr nz, LABEL_F3A51A
	ld a, (xsp + 6)
	extz wa
	ld xbc, xiz
	calr LABEL_F3BC97
	jr SeqVoice_ReturnFalse

LABEL_F3A514:
	ld (xsp + 4), 0x6
	jr SeqVoice_MatchAndAssignChannel

LABEL_F3A51A:
	ld a, (xiz)
	cp a, 0xD2
	jr z, LABEL_F3A536
	cp a, 0xD3
	jr z, LABEL_F3A530
	cp a, 0xD1
	jr z, LABEL_F3A530
	cp a, 0xD0
	jr nz, SeqVoice_MatchAndAssignChannel

LABEL_F3A530:
	ld (xsp + 4), 0x3
	jr SeqVoice_MatchAndAssignChannel

LABEL_F3A536:
	ld (xsp + 4), 0x4

SeqVoice_MatchAndAssignChannel:
	cp (xsp + 6), 0x1
	jr nz, LABEL_F3A557
	ld c, (xiz + 1)
	extz bc
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch
	ld e, (xsp + 4)
	extz de
	ldw wa, 0x12
	ld xbc, xiz
	jr LABEL_F3A562

LABEL_F3A557:
	extz hl
	ld e, (xsp + 4)
	extz de
	ld wa, hl
	ld xbc, xiz

LABEL_F3A562:
	calr ToneVoice_AssignChannel

SeqVoice_ReturnFalse:
	ldb l, 0x0

LABEL_F3A567:
	pop xiz
	inc 6, xsp
	ret

LABEL_F3A56B:
	dec 8, xsp
	jrl LABEL_F3A607

LABEL_F3A570:
	ld_srib A, (xhl + 0x008b)
	add a, 0x9
	cp bc, de
	jr nz, LABEL_F3A585
	cpdm8 1051, a
	jr nc, SeqVoice_CopyEventToSlot
	jrl LABEL_F3A619

LABEL_F3A585:
	ld c, a
	cp a, 0x60
	jr c, SeqVoice_CopyEventToSlot
	sub c, 0x60
	cpdm8 1051, c
	jrl c, LABEL_F3A619

SeqVoice_CopyEventToSlot:
	lda xix, (xsp)
	st_dri3b W, 0xED, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

LABEL_F3A5A5:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F3A5A5
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	ld e, l
	extz de
	cps hl, 0
	jr lt, LABEL_F3A5F9
	lda xbc, (xsp)
	cpdi8 7522, 1
	jr z, LABEL_F3A5E6
	ldw wa, 0x12
	jr LABEL_F3A5E1

LABEL_F3A5CD:
	cp wa, hl
	jr nz, LABEL_F3A5DE
	ld_srib A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, SeqVoice_ReadPartEvent

LABEL_F3A5DE:
	ldw wa, 0x12

LABEL_F3A5E1:
	calr ToneVoice_AssignChannel
	jr SeqVoice_ReadPartEvent

LABEL_F3A5E6:
	ldada xix, 9016
	ldda16 xwa, 7524
	ld_sriw HL, (xix + 0x0088)
	cp wa, hl
	jr ule, LABEL_F3A5CD
	jr SeqVoice_ReadPartEvent

LABEL_F3A5F9:
	lds wa, 3
	call SeqData_SetErrorCode

SeqVoice_ReadPartEvent:
	ldw wa, 0x13
	lds bc, 1
	calr SeqPart_ReadEventStream

LABEL_F3A607:
	ldada xhl, 9016
	ldda16 xbc, 1052
	ld_sriw DE, (xhl + 0x0088)
	cp bc, de
	jrl nc, LABEL_F3A570

LABEL_F3A619:
	inc 8, xsp
	ret

VoiceConfig_FindChannelMatch:
	lda xsp, (xsp - 10)
	pushw iz
	ld (xsp + 10), c
	ld iz, wa
	jr LABEL_F3A693

LABEL_F3A627:
	cp wa, iz
	jr nz, LABEL_F3A635
	ld_srib A, (xde + 0x008b)
	cp a, (xsp + 10)
	jr nc, LABEL_F3A6A0

LABEL_F3A635:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldi_berp 0xE2, 0

LABEL_F3A63D:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b C, 0xE9, 0x88, 0x00
	ld ix, wa
	extz xix
	add xix, xhl
	ldto_berp L, 0xE2
	extz hl
	ld a, (xix)
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3A63D
	ld a, (xbc)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, LABEL_F3A677
	lds wa, 4
	call SeqData_SetErrorCode
	jr LABEL_F3A6A0

LABEL_F3A677:
	ld e, l
	extz de
	lda xbc, (xsp + 2)
	cpdi8 7522, 1
	jr z, LABEL_F3A6BB
	ldw wa, 0x12

LABEL_F3A688:
	calr ToneVoice_AssignChannel

LABEL_F3A68B:
	ldw wa, 0x13
	lds bc, 1
	calr SeqPart_ReadEventStream

LABEL_F3A693:
	ldada xde, 9016
	ld_sriw WA, (xde + 0x0088)
	cp wa, iz
	jr ule, LABEL_F3A627

LABEL_F3A6A0:
	popw iz
	lda xsp, (xsp + 10)
	ret

LABEL_F3A6A5:
	cp wa, hl
	jr nz, LABEL_F3A6B6
	ld_srib A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, LABEL_F3A68B

LABEL_F3A6B6:
	ldw wa, 0x12
	jr LABEL_F3A688

LABEL_F3A6BB:
	ldada xix, 9016
	ldda16 xwa, 7524
	ld_sriw HL, (xix + 0x0088)
	cp wa, hl
	jr ule, LABEL_F3A6A5
	jr LABEL_F3A68B

LABEL_F3A6CE:
	stdi16 7586, 0
	ldda16 xwa, 8982
	bit 0, wa
	jr z, LABEL_F3A6ED
	ldda16 xwa, 1052
	cpda16 xwa, 9016
	jr c, LABEL_F3A6ED
	stdi16 7586, 1

LABEL_F3A6ED:
	ldda16 xwa, 8982
	bit 1, wa
	jr z, LABEL_F3A706
	ldda16 xwa, 1052
	cpda16 xwa, 9024
	jr c, LABEL_F3A706
	ordi16 7586, 2

LABEL_F3A706:
	ldda16 xwa, 8982
	bit 2, wa
	jr z, LABEL_F3A71F
	ldda16 xwa, 1052
	cpda16 xwa, 9032
	jr c, LABEL_F3A71F
	ordi16 7586, 4

LABEL_F3A71F:
	ldda16 xwa, 8982
	bit 3, wa
	jr z, LABEL_F3A738
	ldda16 xwa, 1052
	cpda16 xwa, 9040
	jr c, LABEL_F3A738
	ordi16 7586, 8

LABEL_F3A738:
	ldda16 xwa, 8982
	bit 4, wa
	jr z, LABEL_F3A751
	ldda16 xwa, 1052
	cpda16 xwa, 9048
	jr c, LABEL_F3A751
	ordi16 7586, 16

LABEL_F3A751:
	ldda16 xwa, 8982
	bit 5, wa
	jr z, LABEL_F3A76A
	ldda16 xwa, 1052
	cpda16 xwa, 9056
	jr c, LABEL_F3A76A
	ordi16 7586, 32

LABEL_F3A76A:
	ldda16 xwa, 8982
	bit 6, wa
	jr z, LABEL_F3A783
	ldda16 xwa, 1052
	cpda16 xwa, 9064
	jr c, LABEL_F3A783
	ordi16 7586, 64

LABEL_F3A783:
	ldda16 xwa, 8982
	bit 7, wa
	jr z, LABEL_F3A79C
	ldda16 xwa, 1052
	cpda16 xwa, 9072
	jr c, LABEL_F3A79C
	ordi16 7586, 128

LABEL_F3A79C:
	ldda16 xwa, 8982
	bit 8, wa
	jr z, LABEL_F3A7B5
	ldda16 xwa, 1052
	cpda16 xwa, 9080
	jr c, LABEL_F3A7B5
	ordi16 7586, 256

LABEL_F3A7B5:
	ldda16 xwa, 8982
	bit 9, wa
	jr z, LABEL_F3A7CE
	ldda16 xwa, 1052
	cpda16 xwa, 9088
	jr c, LABEL_F3A7CE
	ordi16 7586, 512

LABEL_F3A7CE:
	ldda16 xwa, 8982
	bit 10, wa
	jr z, LABEL_F3A7E7
	ldda16 xwa, 1052
	cpda16 xwa, 9096
	jr c, LABEL_F3A7E7
	ordi16 7586, 1024

LABEL_F3A7E7:
	ldda16 xwa, 8982
	bit 11, wa
	jr z, LABEL_F3A800
	ldda16 xwa, 1052
	cpda16 xwa, 9104
	jr c, LABEL_F3A800
	ordi16 7586, 2048

LABEL_F3A800:
	ldda16 xwa, 8982
	bit 12, wa
	jr z, LABEL_F3A819
	ldda16 xwa, 1052
	cpda16 xwa, 9112
	jr c, LABEL_F3A819
	ordi16 7586, 4096

LABEL_F3A819:
	ldda16 xwa, 8982
	bit 13, wa
	jr z, LABEL_F3A832
	ldda16 xwa, 1052
	cpda16 xwa, 9120
	jr c, LABEL_F3A832
	ordi16 7586, 8192

LABEL_F3A832:
	ldda16 xwa, 8982
	bit 14, wa
	jr z, LABEL_F3A84B
	ldda16 xwa, 1052
	cpda16 xwa, 9128
	jr c, LABEL_F3A84B
	ordi16 7586, 16384

LABEL_F3A84B:
	ldda16 xwa, 8982
	extz xwa
	bit 15, wa
	ret z
	ldda16 xwa, 1052
	cpda16 xwa, 9136
	ret c
	ordi16 7586, 32768
	ret

SeqNote_ProcessNoteOn:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), 0x0
	cpdi16 10420, 0
	jr nz, LABEL_F3A87C
	ldb l, 0x0
	jrl LABEL_F3AD25

LABEL_F3A87C:
	bitda 5, 10419
	jr z, LABEL_F3A89E
	ei 6
	ldda8 a, 1051
	inc 1, a
	stda8 1051, a
	cp a, 0x60
	jr c, LABEL_F3A89C
	stdi8 1051, 0
	incdi16 1, 1052

LABEL_F3A89C:
	ei 0

LABEL_F3A89E:
	cpdi8 7572, 1
	jr nz, LABEL_F3A8AE
	calr LABEL_F3AD2A
	ld (xsp + 6), l
	jrl SeqNote_LoadNoteParam_Return

LABEL_F3A8AE:
	ei 6
	ldmw2 (xsp + 4), 0x41C
	ldmi16 (xsp + 8), 0x41B
	ei 0
	cpdi8 7570, 1
	jrl nz, SeqNote_ProcessCurrentChannel
	ldda16 xwa, 7542
	cp wa, (xsp + 4)
	jr ugt, SeqNote_FindExtraChannel
	cp wa, (xsp + 4)
	jr nz, LABEL_F3A8D8
	cp (xsp + 8), 0x5F
	jr nz, SeqNote_FindExtraChannel

LABEL_F3A8D8:
	calr SeqPlay_ReconfigureVoices
	stdi8 7530, 0
	stdi8 10338, 0
	stdi8 10340, 0
	stdi8 10342, 0

SeqNote_FindExtraChannel:
	cpdi16 10408, 0
	jr z, SeqNote_AllocateMainChannel

LABEL_F3A8F7:
	ldada xbc, 9016
	ld_sriw WA, (xbc + 0x0080)
	cp (xsp + 4), wa
	jr c, SeqNote_AllocateMainChannel
	cp (xsp + 4), wa
	jr nz, LABEL_F3A914
	ld a, (xsp + 8)
	cp_srib_rm A, 0xE5, 0x83, 0x00
	jr c, SeqNote_AllocateMainChannel

LABEL_F3A914:
	ldw wa, 0x11
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl nz, SeqNote_LoadNoteParam_Return
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	cpdi16 10408, 0
	jr nz, LABEL_F3A8F7

SeqNote_AllocateMainChannel:
	ldda16 xwa, 7542
	cp (xsp + 4), wa
	jrl nz, SeqNote_ProcessCurrentChannel
	cpdi8 7538, 1
	jr nz, SeqNote_AllocateBassChannel
	cp (xsp + 8), 0x46
	jr c, SeqNote_AllocateBassChannel
	cpdi8 10338, 0
	jr nz, SeqNote_AllocateBassChannel
	ldda8 a, 8988
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9332
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ldda16 xwa, 7542
	inc 1, wa
	stda16 9168, xwa
	ld hl, (xhl)
	ld bc, (xde)
	ldada xwa, 9260
	ld (xwa), hl
	ld (xwa + 2), bc
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig
	stdi8 7530, 1
	stdi8 10338, 1

SeqNote_AllocateBassChannel:
	cpdi8 7539, 1
	jrl nz, SeqNote_AllocateSubChannel
	cp (xsp + 8), 0x38
	jrl c, SeqNote_AllocateSubChannel
	cpdi8 10340, 0
	jrl nz, SeqNote_AllocateSubChannel
	ldda8 a, 8990
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9332
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ldda8 a, 8990
	dec 1, a
	extz wa
	ld ix, wa
	sla ix, 3
	ldada xbc, 9016
	ldda16 xwa, 7542
	inc 1, wa
	st_dri3w WA, 0x07, 0xE4, 0xF0
	ldda8 a, 8990
	extz wa
	ld hl, (xhl)
	ld de, (xde)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ldda8 a, 8990
	extz wa
	call SeqCh_LoadChannelConfig
	ldda8 a, 8990
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3AA2F
	slaa bc

LABEL_F3AA2F:
	orddm16 8982, xbc
	stdi8 7530, 1
	stdi8 10340, 1

SeqNote_AllocateSubChannel:
	cpdi8 7540, 1
	jr nz, SeqNote_ProcessCurrentChannel
	cp (xsp + 8), 0x38
	jr c, SeqNote_ProcessCurrentChannel
	cpdi8 10342, 0
	jr nz, SeqNote_ProcessCurrentChannel
	ldda8 a, 8996
	extz wa
	lda xhl, (xsp + 10)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9332
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xde), wa
	ldda16 xwa, 7542
	inc 1, wa
	stda16 9176, xwa
	ld hl, (xhl)
	ld bc, (xde)
	ldada xwa, 9264
	ld (xwa), hl
	ld (xwa + 2), bc
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig
	ldda8 a, 8996
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3AAA5
	slaa bc

LABEL_F3AAA5:
	orddm16 8982, xbc
	stdi8 7530, 1
	stdi8 10342, 1

SeqNote_ProcessCurrentChannel:
	cpdi8 8988, 255
	jr nz, LABEL_F3AAF3
	jr VoiceConfig_SlotCheck

LABEL_F3AABC:
	ldada xwa, 9016
	ld_sriw DE, (xwa + 0x0098)
	ld_srib A, (xwa + 0x009b)
	cp a, 0x1A
	jr nc, LABEL_F3AAD4
	dec 1, de
	add a, 0x60

LABEL_F3AAD4:
	sub a, 0x1A
	cp (xsp + 4), de
	jr c, SeqNote_UpdateScoreDisplay
	cp (xsp + 4), de
	jr nz, LABEL_F3AAE6
	cp (xsp + 8), a
	jr c, SeqNote_UpdateScoreDisplay

LABEL_F3AAE6:
	ldw wa, 0x14
	calr SeqNote_ProcessForChannel
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig

LABEL_F3AAF3:
	ldda8 a, 8988
	dec 1, a
	extz wa
	add wa, wa
	lda_24 xbc, 0xe444fe
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	andda16 xwa, 8982
	jr nz, LABEL_F3AABC

SeqNote_UpdateScoreDisplay:
	cpdi16 7578, 65535
	jr nz, LABEL_F3AB30
	jr VoiceConfig_SlotCheck

LABEL_F3AB17:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, LABEL_F3AB26
	ld a, (xsp + 8)
	cp a, (xbc + 2)
	jr c, VoiceConfig_SlotCheck

LABEL_F3AB26:
	call BitMapOut_PrepareAndDisplaySimple
	stdi16 7578, 65535

LABEL_F3AB30:
	ldada xbc, 7578
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, LABEL_F3AB17

VoiceConfig_SlotCheck:
	cpdi8 8996, 255
	jr nz, LABEL_F3AB7B
	jr VoiceConfig_EventTypeChk

LABEL_F3AB44:
	ldada xwa, 9016
	ld_sriw DE, (xwa + 0x00a0)
	ld_srib A, (xwa + 0x00a3)
	cp a, 0x28
	jr nc, LABEL_F3AB5C
	dec 1, de
	add a, 0x60

LABEL_F3AB5C:
	sub a, 0x28
	cp (xsp + 4), de
	jr c, VoiceConfig_EventTypeChk
	cp (xsp + 4), de
	jr nz, LABEL_F3AB6E
	cp (xsp + 8), a
	jr c, VoiceConfig_EventTypeChk

LABEL_F3AB6E:
	ldw wa, 0x15
	calr SeqNote_ProcessForChannel
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig

LABEL_F3AB7B:
	ldda8 a, 8996
	dec 1, a
	extz wa
	add wa, wa
	lda_24 xbc, 0xe444fe
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	andda16 xwa, 8982
	jr nz, LABEL_F3AB44

VoiceConfig_EventTypeChk:
	cpdi8 8990, 255
	jr nz, LABEL_F3ABE6
	jrl SeqNote_CheckActiveChannels

LABEL_F3AB9F:
	sla wa, 3
	ldada xde, 9016
	exts xwa
	add xwa, xde
	ld de, (xwa)
	ld a, (xwa + 3)
	cp a, 0x28
	jr nc, LABEL_F3ABB9
	dec 1, de
	add a, 0x60

LABEL_F3ABB9:
	sub a, 0x28
	cp (xsp + 4), de
	jr c, SeqNote_CheckActiveChannels
	cp (xsp + 4), de
	jr nz, LABEL_F3ABCB
	cp (xsp + 8), a
	jr c, SeqNote_CheckActiveChannels

LABEL_F3ABCB:
	extz bc
	ld wa, bc
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl nz, SeqNote_LoadNoteParam_Return
	ldda8 a, 8990
	extz wa
	call SeqCh_LoadChannelConfig

LABEL_F3ABE6:
	ldda8 c, 8990
	ld a, c
	dec 1, a
	extz wa
	ld de, wa
	add de, de
	lda_24 xhl, 0xe444fe
	ld_sriw3 DE, 0x07, 0xEC, 0xE8
	andda16 xde, 8982
	jr nz, LABEL_F3AB9F
	jr SeqNote_CheckActiveChannels

LABEL_F3AC06:
	extz wa
	ld bc, wa
	muls bc, 0x9
	ldada xde, 7606
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld bc, (xde + 2)
	cp (xsp + 4), bc
	jr c, SeqNote_DispatchActiveChannels
	cp (xsp + 4), bc
	jr nz, LABEL_F3AC2C
	ld c, (xsp + 8)
	cp c, (xde + 5)
	jr c, SeqNote_DispatchActiveChannels

LABEL_F3AC2C:
	calr SeqNote_FlushPartEventToBuffer

SeqNote_CheckActiveChannels:
	ldda8 a, 7602
	cp a, 0xFF
	jr nz, LABEL_F3AC06

SeqNote_DispatchActiveChannels:
	ldda16 xwa, 7588
	cp wa, (xsp + 4)
	jr z, LABEL_F3AC49
	calr LABEL_F3A6CE
	mrdw5 0x9F, 0x04, 0x19, 0xA4, 0x1D

LABEL_F3AC49:
	ldda16 xiz, 7586
	ldi_berp 0xFB, 1
	cps iz, 0
	jr z, LABEL_F3ACD1

LABEL_F3AC54:
	bit 0, iz
	jr z, SeqNote_ShiftAndIncrement

LABEL_F3AC59:
	ldto_berp E, 0xFB
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	ldada xbc, 9016
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, LABEL_F3AC7D
	ld a, (xsp + 8)
	cp a, (xbc + 3)
	jr c, SeqNote_ShiftAndIncrement

LABEL_F3AC7D:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, LABEL_F3AC97
	lds bc, 1
	ld a, e
	and a, 0xF
	jr z, LABEL_F3AC8F
	slaa bc

LABEL_F3AC8F:
	cpl bc
	anddm16 7586, xbc
	jr SeqNote_ShiftAndIncrement

LABEL_F3AC97:
	ldto_berp A, 0xFB
	extz wa
	calr SeqNote_ProcessForChannel
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jr z, LABEL_F3ACB0
	cp (xsp + 6), 0x5
	jr z, SeqNote_ShiftAndIncrement
	jr SeqNote_LoadNoteParam_Return

LABEL_F3ACB0:
	ldto_berp A, 0xFB
	extz wa
	call SeqCh_LoadChannelConfig
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jr nz, SeqNote_ShiftAndIncrement
	bit 0, iz
	jr nz, LABEL_F3AC59

SeqNote_ShiftAndIncrement:
	srl iz, 1
	inc1_berp 0xFB
	cps iz, 0
	jr nz, LABEL_F3AC54

LABEL_F3ACD1:
	cpdi8 8988, 255
	jr z, SeqNote_ProcessSpecialChannels
	cpdi16 7574, 65535
	jr nz, LABEL_F3AD03
	jr SeqNote_ProcessSpecialChannels

LABEL_F3ACE2:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, LABEL_F3ACF1
	ld a, (xsp + 8)
	cp a, (xbc + 2)
	jr c, SeqNote_ProcessSpecialChannels

LABEL_F3ACF1:
	ldda8 a, 64607
	and a, 0x30
	call_24 z, 0xF3DF7C
	stdi16 7574, 65535

LABEL_F3AD03:
	ldada xbc, 7574
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, LABEL_F3ACE2

SeqNote_ProcessSpecialChannels:
	cpdi8 7556, 0
	call_24 nz, 0xF3DA7C
	cpdi8 7558, 0
	call_24 nz, 0xF3DA8E

SeqNote_LoadNoteParam_Return:
	ld l, (xsp + 6)

LABEL_F3AD25:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_F3AD2A:
	dec 6, xsp
	push xiz
	ld (xsp + 8), 0x0
	cpdi16 10420, 0
	jr nz, LABEL_F3AD3E
	ldb l, 0x0
	jrl LABEL_F3AE2A

LABEL_F3AD3E:
	ei 6
	ldmw2 (xsp + 4), 0x41C
	ldmi16 (xsp + 6), 0x41B
	ei 0
	jr LABEL_F3AD77

LABEL_F3AD4E:
	extz wa
	ld bc, wa
	muls bc, 0x9
	ldada xde, 7606
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld bc, (xde + 2)
	cp (xsp + 4), bc
	jr c, SeqNote_DispatchActiveChannels_NoteOff
	cp (xsp + 4), bc
	jr nz, LABEL_F3AD74
	ld c, (xsp + 6)
	cp c, (xde + 5)
	jr c, SeqNote_DispatchActiveChannels_NoteOff

LABEL_F3AD74:
	calr SeqNote_FlushPartEventToBuffer

LABEL_F3AD77:
	ldda8 a, 7602
	cp a, 0xFF
	jr nz, LABEL_F3AD4E

SeqNote_DispatchActiveChannels_NoteOff:
	ldda16 xwa, 7588
	cp wa, (xsp + 4)
	jr z, LABEL_F3AD94
	ldmm16 7586, 8982
	mrdw5 0x9F, 0x04, 0x19, 0xA4, 0x1D

LABEL_F3AD94:
	ldda16 xiz, 7586
	ldi_berp 0xFB, 1
	cps iz, 0
	jr z, LABEL_F3AE13

LABEL_F3AD9F:
	bit 0, iz
	jr z, SeqNote_StreamAdvanceJoin

LABEL_F3ADA4:
	ldto_berp E, 0xFB
	dec 1, e
	ld a, e
	extz wa
	sla wa, 3
	ldada xbc, 9016
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nz, LABEL_F3ADC8
	ld a, (xsp + 6)
	cp a, (xbc + 3)
	jr c, SeqNote_StreamAdvanceJoin

LABEL_F3ADC8:
	ld wa, (xsp + 4)
	cp wa, (xbc)
	jr nc, LABEL_F3ADE2
	lds bc, 1
	ld a, e
	and a, 0xF
	jr z, LABEL_F3ADDA
	slaa bc

LABEL_F3ADDA:
	cpl bc
	anddm16 7586, xbc
	jr SeqNote_StreamAdvanceJoin

LABEL_F3ADE2:
	ldto_berp A, 0xFB
	extz wa
	calr SeqNote_ProcessForChannelAlt
	ld (xsp + 8), l
	cp (xsp + 8), 0x0
	jr z, LABEL_F3ADFB
	cp (xsp + 8), 0x5
	jr z, SeqNote_StreamAdvanceJoin
	jr LABEL_F3AE27

LABEL_F3ADFB:
	ldto_berp A, 0xFB
	extz wa
	call SeqData_ParseSequenceStream
	bit 0, iz
	jr nz, LABEL_F3ADA4

SeqNote_StreamAdvanceJoin:
	srl iz, 1
	inc1_berp 0xFB
	cps iz, 0
	jr nz, LABEL_F3AD9F

LABEL_F3AE13:
	cpdi8 7556, 0
	call_24 nz, 0xF3DA7C
	cpdi8 7558, 0
	call_24 nz, 0xF3DA8E

LABEL_F3AE27:
	ld l, (xsp + 8)

LABEL_F3AE2A:
	pop xiz
	inc 6, xsp
	ret

SeqNote_FlushPartEventToBuffer:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	call LABEL_F3E6FD
	cpdi8 7558, 1
	call_24 z, 0xF3DA8E
	call SeqBuf_GetWritePos
	cp hl, 0xF
	call_24 lt, 0xF3DA7C
	ld a, (xsp)
	extz wa
	muls wa, 0x9
	ldada xbc, 7610
	exts xwa
	add xwa, xbc
	push xwa
	pushw 0x5
	call SeqBuf_WriteBytes
	inc 6, xsp
	stdi8 7556, 1
	inc 2, xsp
	ret

SeqPart_ScanNextEvent:
	lda xsp, (xsp - 18)
	push_werp 0xFA
	ld (xsp + 18), a
	ldi_berp 0xFB, 0
	call Get_Firmware_Version
	cp l, 0xFF
	jr z, LABEL_F3AEFE
	ld a, (xsp + 18)
	extz wa
	lda xde, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

LABEL_F3AEAA:
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
	jr lt, LABEL_F3AEF5
	ld c, (xsp + 18)
	extz bc
	lda xwa, (xsp + 2)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	ldb l, 0x0
	jr LABEL_F3AF00

LABEL_F3AEF5:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x12
	jr ule, LABEL_F3AEAA

LABEL_F3AEFE:
	ldb l, 0x1

LABEL_F3AF00:
	pop_werp 0xFA
	lda xsp, (xsp + 18)
	ret

SeqNote_ProcessForChannel:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 20), a
	ld (xsp + 6), 0x0
	ldda8 a, 8988
	ldfr_berp A, 0xFB
	ld a, (xsp + 20)
	cp_berp A, 0xFB
	jr nz, LABEL_F3AF58
	ldto_berp A, 0xFB
	extz wa
	calr Chan_IsActive
	cps l, 1
	jr nz, LABEL_F3AF3D
	lds wa, 1
	call Voice_AllocateFromSeqData
	ld (xsp + 6), l
	cp (xsp + 6), 0x0
	jrl z, SeqNote_ReturnNotProcessed

LABEL_F3AF3D:
	ld c, (xsp + 20)
	dec 1, c
	extz bc
	sla bc, 3
	ldada xwa, 9018
	cp_srib_im 0x07, 0xE0, 0xE4, 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld (xsp + 6), 0x0

LABEL_F3AF58:
	cp (xsp + 20), 0x14
	jr nz, LABEL_F3AF7F
	ldto_berp A, 0xFB
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

LABEL_F3AF7F:
	cp (xsp + 20), 0x0
	jr nz, LABEL_F3AF8C
	ldw wa, 0xC
	call SeqData_SetErrorCode

LABEL_F3AF8C:
	ld a, (xsp + 20)
	extz wa
	lda xbc, (xsp + 10)
	ld h, a
	ld xiy, xbc
	ldb l, 0x0

LABEL_F3AF9A:
	ld e, l
	extz de
	inc 2, de
	ld a, h
	dec 1, a
	extz wa
	sla wa, 3
	ldada xix, 9016
	exts xwa
	add xwa, xix
	ld iz, de
	extz xiz
	add xiz, xwa
	ld e, l
	extz de
	ld a, (xiz)
	lda_dri3 XBC, 0x07, 0xF4, 0xE8
	inc 1, l
	cps l, 6
	jr c, LABEL_F3AF9A
	cp (xsp + 20), 0x11
	jr nz, LABEL_F3AFE1
	cpdi16 10408, 0
	jr z, LABEL_F3AFE1
	ldmi16 (xsp + 20), 0x231A
	ld (xsp + 8), 0x11
	jr LABEL_F3AFE7

LABEL_F3AFE1:
	ld a, (xsp + 20)
	ld (xsp + 8), a

LABEL_F3AFE7:
	st_dri3b C, 0xF1, 0x82, 0x00
	cpdi8 7522, 1
	jr nz, SeqNote_HandleMasterChannel
	ld a, (xsp + 8)
	cpda8 a, 8986
	jr nz, LABEL_F3B014
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3B012
	slaa bc

LABEL_F3B012:
	jr SeqNote_DeactivateChannelBit

LABEL_F3B014:
	cp (xsp + 8), 0x11
	jr z, LABEL_F3B04C
	jr SeqNote_HandleMasterChannel

LABEL_F3B01C:
	cp wa, de
	jr nz, LABEL_F3B02D
	ld_srib A, (xix + 0x0083)
	extz wa
	cpdm16 7526, xwa
	jr ule, SeqNote_HandleMasterChannel

LABEL_F3B02D:
	cp (xhl), 0x82
	jrl nz, SeqNote_ReturnNotProcessed
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, SeqNote_DeactivateChannelBit
	slaa bc

SeqNote_DeactivateChannelBit:
	cpl bc
	anddm16 8982, xbc
	jrl SeqNote_ReturnNotProcessed

LABEL_F3B04C:
	ldda16 xwa, 7524
	ld_sriw DE, (xix + 0x0080)
	cp wa, de
	jr nc, LABEL_F3B01C

SeqNote_HandleMasterChannel:
	cp (xsp + 20), 0x14
	jr nz, SeqNote_HandleAccompChannel
	cp (xbc), 0x82
	jr nz, LABEL_F3B08A
	ld a, (xsp + 20)
	dec 1, a
	extz wa
	sla wa, 3
	stiw_dri 0x07, 0xF0, 0xE0, 0xFF, 0xFF
	ldda8 a, 64607
	and a, 0x30
	jr nz, SeqNote_ReturnNotProcessed
	bitda 2, 1054
	jr z, SeqNote_ReturnNotProcessed
	call AccWrap_PlayModeStartPlay
	jr SeqNote_ReturnNotProcessed

LABEL_F3B08A:
	ldda8 a, 8988
	cp a, 0xFF
	jr z, SeqNote_HandleAccompChannel
	ld (xsp + 20), a

SeqNote_HandleAccompChannel:
	ld a, (xsp + 20)
	cpda8 a, 8996
	jr z, LABEL_F3B0A5
	cp (xsp + 20), 0x15
	jr nz, LABEL_F3B0DC

LABEL_F3B0A5:
	ld a, (xsp + 20)
	extz wa
	calr LABEL_F3B2AE
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
	ldada xwa, 9016
	stiw_dri 0x07, 0xE0, 0xE4, 0xF0, 0xFF

SeqNote_ReturnNotProcessed:
	ldb l, 0x0
	jrl LABEL_F3B2A9

SeqNote_SetDrumChannelPair:
	ldmi16 (xsp + 20), 0x2324

LABEL_F3B0DC:
	lda xbc, (xsp + 10)
	ld e, (xbc)
	ld a, e
	and a, 0xF0
	ldfr_berp A, 0xFB
	ld (xsp + 4), 0x0
	cp_erpb 0xFB, 0xC0
	jr z, LABEL_F3B140
	cp_erpb 0xFB, 0xB0
	jr z, LABEL_F3B122
	cp_erpb 0xFB, 0x90
	jr nz, LABEL_F3B15E
	ld a, (xsp + 8)
	extz wa
	calr SeqNote_SetupVoice
	cps l, 0
	jr nz, LABEL_F3B11B
	ld a, (xsp + 20)
	extz wa
	calr Chan_IsActive
	cps l, 1
	jrl z, LABEL_F3B225
	jrl SeqNote_ConditionalWriteToBuffer

LABEL_F3B11B:
	ld (xsp + 4), 0x0
	jrl LABEL_F3B2A6

LABEL_F3B122:
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

LABEL_F3B140:
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

LABEL_F3B15E:
	cp e, 0x86
	jrl z, LABEL_F3B24C
	cp e, 0x85
	jrl z, LABEL_F3B233
	ld c, (xsp + 20)
	extz bc
	cp e, 0xD2
	jrl z, LABEL_F3B21C
	cp e, 0x80
	jrl z, LABEL_F3B202
	cp e, 0xD3
	jr z, LABEL_F3B1E9
	cp e, 0xD1
	jr z, LABEL_F3B1DD
	cp e, 0xD0
	jr z, LABEL_F3B1D1
	cp e, 0x82
	jrl nz, LABEL_F3B265
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3B19D
	slaa de

LABEL_F3B19D:
	cpl de
	anddm16 8982, xde
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	cpdi16 10408, 0
	jr nz, LABEL_F3B1CA
	cpdi8 7570, 0
	jr nz, LABEL_F3B1CA
	ldda16 xwa, 61854
	ldda16 xbc, 10420
	and wa, bc
	jr nz, LABEL_F3B1CA
	ld (xsp + 6), 0x1
	jrl SeqNote_ConditionalWriteToBuffer

LABEL_F3B1CA:
	ld (xsp + 6), 0x5
	jrl SeqNote_ConditionalWriteToBuffer

LABEL_F3B1D1:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

LABEL_F3B1DD:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr z, SeqNote_SendNoteOff
	jrl SeqNote_ConditionalWriteToBuffer

LABEL_F3B1E9:
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

LABEL_F3B202:
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

LABEL_F3B21C:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr nz, SeqNote_ConditionalWriteToBuffer

LABEL_F3B225:
	ld a, (xsp + 20)
	dec 1, a
	ld (xsp + 14), a
	ld (xsp + 4), 0x5
	jr SeqNote_WriteEventToBuffer

LABEL_F3B233:
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

LABEL_F3B24C:
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

LABEL_F3B265:
	ld wa, bc
	calr Chan_IsActive
	cps l, 1
	jr nz, LABEL_F3B27E
	ld a, (xsp + 20)
	extz wa
	calr SeqPart_ScanNextEvent
	cps l, 0
	jr z, SeqNote_ConditionalWriteToBuffer
	ldb l, 0x4
	jr LABEL_F3B2A9

LABEL_F3B27E:
	ld a, (xsp + 20)
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3B28E
	slaa bc

LABEL_F3B28E:
	cpl bc
	anddm16 10420, xbc

SeqNote_ConditionalWriteToBuffer:
	cp (xsp + 4), 0x0
	jr z, LABEL_F3B2A6

SeqNote_WriteEventToBuffer:
	lda xwa, (xsp + 10)
	ld c, (xsp + 4)
	extz bc
	call SeqBuf_WriteMidiEvent

LABEL_F3B2A6:
	ld l, (xsp + 6)

LABEL_F3B2A9:
	pop xiz
	lda xsp, (xsp + 18)
	ret

LABEL_F3B2AE:
	ldi_berp 0xE2, 0
	cp (xbc), 0x82
	jr z, LABEL_F3B2F3
	ld w, (xbc)
	and w, 0xF0
	lda xde, (xbc + 2)
	lda xhl, (xbc + 3)
	cp w, 0xC0
	jr nz, LABEL_F3B2D2
	cp (xde), 0x48
	jr nz, VoiceType_ValidateCode
	cp (xhl), 0x0
	jr z, LABEL_F3B2E6
	jr VoiceType_ValidateCode

LABEL_F3B2D2:
	ld c, (xbc)
	and c, 0xF0
	cp c, 0xB0
	jr nz, VoiceType_ValidateCode
	cp (xde), 0x48
	jr nz, VoiceType_ValidateCode
	cp (xhl), 0x7
	jr nz, VoiceType_ValidateCode

LABEL_F3B2E6:
	ldi_berp 0xE2, 1

VoiceType_ValidateCode:
	cp a, 0x15
	jr nz, LABEL_F3B2F6
	cpi_berp 0xE2, 1
	jr nz, LABEL_F3B2FB

LABEL_F3B2F3:
	lds hl, 0
	ret

LABEL_F3B2F6:
	cpi_berp 0xE2, 0
	jr z, LABEL_F3B2F3

LABEL_F3B2FB:
	ldw hl, 0xFFFF
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
	ldfr_berp W, 0xE6
	ld xiy, xde
	ldi_berp 0xE2, 0

LABEL_F3B31C:
	ldto_berp L, 0xE2
	extz hl
	ld iz, hl
	inc 2, iz
	ldto_berp L, 0xE6
	dec 1, l
	extz hl
	sla hl, 3
	ldada xix, 9016
	exts xhl
	add xhl, xix
	ld ix, iz
	extz xix
	add xix, xhl
	ldto_berp L, 0xE2
	extz hl
	ld a, (xix)
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3B31C
	ld l, (xde)
	ld h, l
	and h, 0xF0
	ldi_berp 0xFB, 0
	ld a, h
	cp h, 0xC0
	jr z, LABEL_F3B3A5
	cp a, 0xB0
	jr z, LABEL_F3B384
	cp a, 0x90
	jr nz, LABEL_F3B3B1
	ld wa, bc
	ld xbc, xde
	calr SeqNote_SetupVoice
	cps l, 0
	jr nz, SeqMidi_EmitEventToBuffer
	ld a, (xsp + 14)
	dec 1, a
	ld (xsp + 10), a

LABEL_F3B37F:
	ldi_berp 0xFB, 5
	jr SeqNote_WriteChannelToBuffer

LABEL_F3B384:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyChannel0
	ldfr_berp L, 0xFB

SeqMidi_EmitEventToBuffer:
	cpi_berp 0xFB, 0
	jr z, LABEL_F3B39F

SeqNote_WriteChannelToBuffer:
	lda xwa, (xsp + 6)
	ldto_berp C, 0xFB
	extz bc
	call SeqBuf_WriteMidiEvent

LABEL_F3B39F:
	ld l, (xsp + 4)
	jrl LABEL_F3B453

LABEL_F3B3A5:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyChannelDirect
	ldfr_berp L, 0xFB
	jr SeqMidi_EmitEventToBuffer

LABEL_F3B3B1:
	ld h, l
	cp l, 0x86
	jr z, LABEL_F3B436
	cp h, 0x85
	jr z, LABEL_F3B42E
	ld a, (xsp + 14)
	dec 1, a
	cp h, 0xD2
	jr z, LABEL_F3B428
	cp h, 0x80
	jr z, LABEL_F3B41B
	inc 3, xde
	cp h, 0xD3
	jr z, SeqNote_WriteChannelEvt
	cp h, 0xD1
	jr z, SeqNote_WriteChannelEvt
	cp h, 0xD0
	jr z, SeqNote_WriteChannelEvt
	cp h, 0x82
	jr nz, LABEL_F3B43E
	dec 1, w
	lds de, 1
	ld a, w
	and a, 0xF
	jr z, LABEL_F3B3EF
	slaa de

LABEL_F3B3EF:
	cpl de
	anddm16 8982, xde
	ld wa, bc
	calr SeqCh_ClearActivePartBit
	ldda16 xwa, 61854
	ldda16 xbc, 10420
	and wa, bc
	jr nz, LABEL_F3B40C
	ld (xsp + 4), 0x1
	jr SeqMidi_EmitEventToBuffer

LABEL_F3B40C:
	ld (xsp + 4), 0x5
	jrl SeqMidi_EmitEventToBuffer

SeqNote_WriteChannelEvt:
	ld (xde), a
	ldi_berp 0xFB, 4
	jrl SeqNote_WriteChannelToBuffer

LABEL_F3B41B:
	ld wa, bc
	ld xbc, xde
	calr AccPedalConfig_ApplyTempo
	ldfr_berp L, 0xFB
	jrl SeqMidi_EmitEventToBuffer

LABEL_F3B428:
	ld (xde + 4), a
	jrl LABEL_F3B37F

LABEL_F3B42E:
	ld xwa, xde
	calr SeqNote_UpdatePlayPosition_A
	jrl SeqMidi_EmitEventToBuffer

LABEL_F3B436:
	ld xwa, xde
	calr SeqNote_UpdatePlayPosition_B
	jrl SeqMidi_EmitEventToBuffer

LABEL_F3B43E:
	lds wa, 5
	call SeqData_SetErrorCode
	ld a, (xsp + 14)
	extz wa
	calr SeqPart_ScanNextEvent
	cps l, 0
	jrl z, SeqMidi_EmitEventToBuffer
	ldb l, 0x4

LABEL_F3B453:
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
	and a, 0xF
	jr z, LABEL_F3B46C
	slaa bc

LABEL_F3B46C:
	ldda16 xwa, 61854
	and wa, bc
	jr nz, Chan_IsActive_RetTrue
	ldb l, 0x0
	ret

Chan_IsActive_RetTrue:
	ldb l, 0x1
	ret

AccPedalConfig_ApplyChannel0:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	dec 1, a
	ld (xbc + 6), a
	cp (xbc + 2), 0x48
	jrl nz, AccPedalConfig_ReturnError7
	ld d, (xbc + 3)
	cps d, 5
	jr z, LABEL_F3B4A1
	cps d, 6
	jr z, LABEL_F3B4A1
	cps d, 7
	jrl nz, AccPedalConfig_ReturnError7

LABEL_F3B4A1:
	ld a, (xbc + 4)
	ldfr_berp A, 0xFA
	ld a, (xbc + 5)
	ldfr_berp A, 0xFB
	bitm 0, (xbc)
	jr z, LABEL_F3B4B5
	set_erpb 0xFA, 0x07

LABEL_F3B4B5:
	bitm 1, (xbc)
	jr z, LABEL_F3B4BD
	set_erpb 0xFB, 0x07

LABEL_F3B4BD:
	cps d, 7
	jr nz, LABEL_F3B513
	ldto_berp E, 0xFA
	extz de
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	ldw wa, 0x48
	lds bc, 7
	call AddswbWr
	stdi8 7546, 72
	stdi8 7548, 7
	ldto_berp A, 0xFA
	stda8 7550, a
	ldto_berp A, 0xFB
	stda8 7552, a
	ld a, (xsp + 2)
	dec 1, a
	stda8 7554, a
	ldda8 c, 7546
	ldda8 b, 7548
	ldda8 e, 7550
	ldda8 d, 7552
	ldda8 a, 7554
	call LABEL_FCB897

Chan_IsActive_RetFalse:
	ldb l, 0x0
	jrl LABEL_F3B6E5

LABEL_F3B513:
	ldfr_berp D, 0xF0
	extz ix
	ld iy, ix
	ldto_berp L, 0xFA
	extz hl
	ld bc, hl
	bitda 2, 1054
	jrl z, LABEL_F3B679
	ldto_berp E, 0xF4
	cps d, 6
	jr nz, LABEL_F3B575
	bit_erpb 0xFB, 0x02
	jr z, LABEL_F3B561
	bit_erpb 0xFA, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, LABEL_F3B54D
	cpdi8 7560, 0
	jrl nz, AccPedalConfig_ClearFlag7560

LABEL_F3B54D:
	ldto_berp A, 0xFB
	extz wa
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B561:
	ldto_berp A, 0xFB
	extz wa
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B575:
	ldda8 a, 8988
	bit_erpb 0xFB, 0x04
	jr z, LABEL_F3B5A7
	bit_erpb 0xFA, 0x04
	jrl z, AccPedalConfig_ReturnError7
	cp (xsp + 2), a
	jr nz, LABEL_F3B590
	stdi8 13026, 1

LABEL_F3B590:
	ldto_berp C, 0xFB
	extz bc
	ldto_berp A, 0xF0
	stda8 13448, a
	stda8 13429, l
	stda8 13430, c
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B5A7:
	bit_erpb 0xFB, 0x05
	jr z, LABEL_F3B5D5
	bit_erpb 0xFA, 0x05
	jrl z, AccPedalConfig_ReturnError7
	cp (xsp + 2), a
	jr nz, LABEL_F3B5BE
	stdi8 13026, 1

LABEL_F3B5BE:
	ldto_berp C, 0xFB
	extz bc
	ldto_berp A, 0xF0
	stda8 13448, a
	stda8 13429, l
	stda8 13430, c
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B5D5:
	bit_erpb 0xFB, 0x02
	jr z, LABEL_F3B606
	bit_erpb 0xFA, 0x02
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, LABEL_F3B5F2
	cpdi8 7560, 0
	jr nz, AccPedalConfig_ClearFlag7560

LABEL_F3B5F2:
	ldto_berp A, 0xFB
	extz wa
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B606:
	bit_erpb 0xFB, 0x03
	jr z, LABEL_F3B63F
	bit_erpb 0xFA, 0x03
	jrl z, AccPedalConfig_ReturnError7
	ld a, (xsp + 2)
	cpda8 a, 8990
	jr nz, AccPedalConfig_StorePedalValues
	cpdi8 7560, 0
	jr z, AccPedalConfig_StorePedalValues

AccPedalConfig_ClearFlag7560:
	stdi8 7560, 0
	jrl Chan_IsActive_RetFalse

AccPedalConfig_StorePedalValues:
	ldto_berp A, 0xFB
	extz wa
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jrl AccPedalConfig_ReplayAndReturnOK

LABEL_F3B63F:
	ldto_berp A, 0xFB
	extz wa
	bit_erpb 0xFB, 0x06
	jr z, LABEL_F3B65F
	bit_erpb 0xFA, 0x06
	jrl z, AccPedalConfig_ReturnError7
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jr AccPedalConfig_ReplayAndReturnOK

LABEL_F3B65F:
	bit_erpb 0xFB, 0x07
	jr z, LABEL_F3B66B
	bit_erpb 0xFA, 0x07
	jr z, AccPedalConfig_ReturnError7

LABEL_F3B66B:
	stda8 13448, e
	stda8 13429, c
	stda8 13430, a
	jr AccPedalConfig_ReplayAndReturnOK

LABEL_F3B679:
	bit_erpb 0xFB, 0x06
	jr z, LABEL_F3B6A6
	cpdi8 36152, 129
	jr nz, AccPedalConfig_ApplyChannelSettings
	bitda 5, 10419
	jr z, AccPedalConfig_ApplyChannelSettings
	res_erpb 0xFB, 0x06

AccPedalConfig_ApplyChannelSettings:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xF0
	ld e, a
	cps d, 6
	jr nz, AccPedalConfig_CheckMaskBits
	bit_erpb 0xFB, 0x02
	jr z, AccPedalConfig_CheckMaskBits
	jr LABEL_F3B6CA

LABEL_F3B6A6:
	bit_erpb 0xFB, 0x07
	jr nz, AccPedalConfig_ApplyChannelSettings
	ldto_berp E, 0xFB
	extz de
	ldto_berp A, 0xF4
	stda8 13448, a
	stda8 13429, c
	stda8 13430, e
	jr AccPedalConfig_ReplayAndReturnOK

AccPedalConfig_CheckMaskBits:
	ldto_berp A, 0xFB
	and a, 0xC
	jr z, LABEL_F3B6DD

LABEL_F3B6CA:
	stda8 13448, c
	stda8 13429, l
	stda8 13430, e

AccPedalConfig_ReplayAndReturnOK:
	call AccWrap_ReplaySavedPedal
	jrl Chan_IsActive_RetFalse

LABEL_F3B6DD:
	cpi_berp 0xFB, 0
	jrl z, Chan_IsActive_RetFalse

AccPedalConfig_ReturnError7:
	ldb l, 0x7

LABEL_F3B6E5:
	pop_werp 0xFA
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
	jr z, LABEL_F3B70D
	setm 7, (xsp + 4)

LABEL_F3B70D:
	extz bc
	ld e, (xsp + 4)
	extz de
	ld a, (xiz + 5)
	extz wa
	pushw wa
	ldw wa, 0x48
	call AddswbWr
	stdi8 7546, 72
	mrdb5 0x8E, 0x03, 0x19, 0x7C, 0x1D
	mrdb5 0x8F, 0x04, 0x19, 0x7E, 0x1D
	mrdb5 0x8E, 0x05, 0x19, 0x80, 0x1D
	ld a, (xsp + 6)
	dec 1, a
	stda8 7554, a
	ldda8 c, 7546
	ldda8 b, 7548
	ldda8 e, 7550
	ldda8 d, 7552
	ldda8 a, 7554
	call LABEL_FCB771
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cp l, 0x10
	jr nz, LABEL_F3B770
	mrdb5 0x8F, 0x04, 0x19, 0x8C, 0x1D
	mrdb5 0x8E, 0x05, 0x19, 0x8E, 0x1D

LABEL_F3B770:
	ldb l, 0x0
	jr LABEL_F3B77E

AccPedalConfig_ChannelDirect_Error:
	ld a, (xsp + 6)
	dec 1, a
	ld (xiz + 6), a
	ldb l, 0x7

LABEL_F3B77E:
	pop xiz
	inc 4, xsp
	ret

AccPedalConfig_ApplyTempo:
	push_werp 0xFA
	ld e, (xbc + 2)
	ld a, (xbc + 3)
	ldfr_berp A, 0xFB
	bit_erpb 0xFB, 0x00
	jr z, LABEL_F3B797
	set 7, e

LABEL_F3B797:
	srl_erpb 0xFB, 0x01
	ldada xbc, 64602
	ld (xbc + 8), e
	ldto_berp A, 0xFB
	ld (xbc + 9), a
	extz de
	pushw 0xFF
	ldw wa, 0x48
	ldw bc, 0x8
	call AddswbWr
	ldto_berp E, 0xFB
	extz de
	pushw 0x1
	ldw wa, 0x48
	ldw bc, 0x9
	call AddswbWr
	call SeqTimer_UpdateTempoReg
	ldb l, 0x0
	pop_werp 0xFA
	ret

SeqNote_UpdatePlayPosition_A:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	bitda 2, 1054
	jr nz, LABEL_F3B826
	bitda 4, 10412
	jr z, LABEL_F3B7EC
	setda 1, 10407
	jr LABEL_F3B826

LABEL_F3B7EC:
	ei 6
	ld a, (xsp)
	cpda8 a, 8988
	jr z, LABEL_F3B7FC
	cpda8 a, 8990
	jr nz, LABEL_F3B80F

LABEL_F3B7FC:
	ld xwa, (xsp + 2)
	inc 1, xwa
	cp (xwa), 0x0
	jr nz, LABEL_F3B809
	ld (xwa), 0x5F

LABEL_F3B809:
	mrib4 0x80, 0x19, 0x2F, 0x04
	jr LABEL_F3B820

LABEL_F3B80F:
	ldda8 a, 1051
	inc 1, a
	cp a, 0x5F
	jr ule, LABEL_F3B81C
	ldb a, 0x0

LABEL_F3B81C:
	stda8 1071, a

LABEL_F3B820:
	setda 0, 1073
	ei 0

LABEL_F3B826:
	inc 6, xsp
	ret

LABEL_F3B829:
	.byte 0x06, 0x06, 0xc1, 0x1b, 0x04, 0x21, 0xc9, 0x61
	.byte 0xc9, 0xcf, 0x60, 0x67, 0x02, 0x21, 0x00, 0xf1
	.byte 0x2f, 0x04, 0x41, 0xf1, 0x31, 0x04, 0xb8, 0x06
	.byte 0x00, 0x0e

SeqNote_UpdatePlayPosition_B:
	dec 6, xsp
	ld (xsp), c
	ld (xsp + 2), xwa
	bitda 2, 1054
	jr z, SeqNote_StackCleanupRet
	bitda 1, 10418
	jr nz, SeqNote_StackCleanupRet
	bitda 4, 10412
	jr nz, SeqNote_StackCleanupRet
	ei 6
	ld a, (xsp)
	cpda8 a, 8996
	jr z, LABEL_F3B86C
	cpda8 a, 8994
	jr nz, LABEL_F3B87F

LABEL_F3B86C:
	ldda8 a, 1051
	inc 1, a
	cp a, 0x5F
	jr ule, LABEL_F3B879
	ldb a, 0x0

LABEL_F3B879:
	stda8 1072, a
	jr LABEL_F3B887

LABEL_F3B87F:
	ld xwa, (xsp + 2)
	mrdb5 0x88, 0x01, 0x19, 0x30, 0x04

LABEL_F3B887:
	setda 3, 1073
	ei 0

SeqNote_StackCleanupRet:
	inc 6, xsp
	ret

LABEL_F3B890:
	.byte 0x06, 0x06, 0xc1, 0x1b, 0x04, 0x21, 0xc9, 0x61
	.byte 0xc9, 0xcf, 0x60, 0x67, 0x02, 0x21, 0x00, 0xf1
	.byte 0x30, 0x04, 0x41, 0xf1, 0x31, 0x04, 0xbb, 0x06
	.byte 0x00, 0x0e

LABEL_F3B8AA:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), a
	ldmw2 (xsp + 4), 0x2326
	ldda16 xhl, 8954
	ld wa, (xsp + 4)
	sub wa, hl
	cp wa, 0x78
	jrl ule, VoiceConfig_CounterIncr
	call LABEL_F3E69F
	ld wa, (xsp + 4)
	sub wa, hl
	cp wa, 0x78
	jrl ule, VoiceConfig_CounterIncr
	ldda8 a, 8182
	ldfr_berp A, 0xFA
	cp_erpb 0xFA, 0xFF
	jrl z, VoiceConfig_CounterIncr

LABEL_F3B8E7:
	ldto_berp A, 0xFA
	extz wa
	ld bc, wa
	muls bc, 0xC
	ldada xde, 8186
	exts xbc
	add xbc, xde
	ld hl, (xbc + 4)
	ld de, (xsp + 4)
	sub de, hl
	cp de, 0x78
	jrl c, LABEL_F3BAC2
	ld bc, (xsp + 4)
	ldw de, 0x5F
	calr Part_AssignVoiceConfig
	cp (xsp + 20), 0x1
	jr nz, LABEL_F3B92B
	lda xde, (xsp + 6)
	ldada xbc, 9252
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr SeqVoice_ApplyToChannels

LABEL_F3B92B:
	ldto_berp A, 0xFA
	extz wa
	muls wa, 0xC
	ld bc, wa
	ldada xwa, 8195
	ld_srib3 A, 0x07, 0xE0, 0xE4
	ldfr_berp A, 0xFB
	ldda8 l, 10437
	and l, 0x41
	ldto_berp A, 0xFB
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp l, 0x41
	jr nz, SeqVoice_LoadDefaultParams
	lds hl, 1
	ldto_berp A, 0xFB
	and a, 0xF
	jr z, LABEL_F3B969
	slaa hl

LABEL_F3B969:
	andda16 xhl, 10408
	jr z, SeqVoice_LoadDefaultParams
	lda xhl, (xsp + 6)
	add bc, bc
	ldada xwa, 10526
	ld_sriw3 WA, 0x07, 0xE0, 0xE4
	ld (xhl), wa
	extz de
	ldada xbc, 10558
	extz xde
	add xde, xbc
	ld a, (xde)
	extz wa
	ld (xhl + 2), wa
	jr SeqVoice_ApplyToChannels

SeqVoice_LoadDefaultParams:
	lda xde, (xsp + 6)
	sla bc, 2
	ldada xwa, 9184
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

SeqVoice_ApplyToChannels:
	ldto_berp A, 0xFA
	extz wa
	lda xbc, (xsp + 10)
	ldfr_berp A, 0xEE
	ld xix, xbc
	ldi_berp 0xEA, 0

LABEL_F3B9BA:
	ldto_berp L, 0xEA
	extz hl
	ldto_berp A, 0xEE
	extz wa
	muls wa, 0xC
	ld de, wa
	ldada xwa, 8186
	st_dri3b W, 0x07, 0xE0, 0xE8
	ld iy, hl
	extz xiy
	add xiy, xwa
	ldto_berp E, 0xEA
	extz de
	ld a, (xiy)
	lda_dri3 XBC, 0x07, 0xF0, 0xE8
	inc1_berp 0xEA
	cpi_berp 0xEA, 4
	jr c, LABEL_F3B9BA
	ld (xbc + 1), 0x0
	lda xwa, (xsp + 6)
	lds de, 4
	call Part_CopyBytesToVoiceBlock
	ldto_berp A, 0xFA
	extz wa
	muls wa, 0xC
	ldada xbc, 8186
	st_dri3b B, 0x07, 0xE4, 0xE0
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
	ldada xiy, 9184
	cp (xsp + 20), 0x1
	jr nz, LABEL_F3BA4E
	lda xwa, (xsp + 6)
	ld de, (xwa)
	ld bc, (xwa + 2)
	lda xwa, (xiy + 68)
	ld (xwa), de
	ld (xwa + 2), bc
	jr LABEL_F3BAAF

LABEL_F3BA4E:
	ldda8 d, 10437
	and d, 0x41
	lda xix, (xsp + 6)
	ldto_berp A, 0xFB
	inc 1, a
	extz wa
	lda xhl, (xix + 2)
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp d, 0x41
	jr nz, LABEL_F3BA9E
	lds iz, 1
	ldto_berp A, 0xFB
	and a, 0xF
	jr z, LABEL_F3BA7B
	slaa iz

LABEL_F3BA7B:
	andda16 xiz, 10408
	jr z, LABEL_F3BA9E
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	ldada xwa, 10526
	st_dri3w IX, 0x07, 0xE0, 0xE4
	extz de
	ldada xbc, 10558
	extz xde
	add xde, xbc
	ld (xde), l
	jr LABEL_F3BAAF

LABEL_F3BA9E:
	ld ix, (xix)
	ld de, (xhl)
	sla bc, 2
	st_dri3b W, 0x07, 0xF4, 0xE4
	ld (xwa), ix
	ld (xwa + 2), de

LABEL_F3BAAF:
	ldto_berp A, 0xFA
	extz wa
	muls wa, 0xC
	ld bc, wa
	ldada xwa, 8186
	exts xbc
	add xbc, xwa

LABEL_F3BAC2:
	ld a, (xbc + 11)
	ldfr_berp A, 0xFA
	cp_erpb 0xFA, 0xFF
	jrl nz, LABEL_F3B8E7

VoiceConfig_CounterIncr:
	ldda16 xwa, 8998
	inc 1, wa
	stda16 8998, xwa
	cp (xsp + 20), 0x1
	jr nz, LABEL_F3BAFA
	ldda16 xbc, 9006
	cp (xsp + 4), bc
	jr c, LABEL_F3BB27
	lds bc, 0
	calr VoiceConfig_FindChannelMatch
	ldw wa, 0x12
	ld xbc, (xsp + 16)
	lds de, 1
	calr ToneVoice_AssignChannel
	jr LABEL_F3BB27

LABEL_F3BAFA:
	ldi_berp 0xFB, 1

LABEL_F3BAFD:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3BB0B
	slaa bc

LABEL_F3BB0B:
	andda16 xbc, 10408
	jr z, LABEL_F3BB1E
	ldto_berp A, 0xFB
	extz wa
	ld xbc, (xsp + 16)
	lds de, 1
	calr ToneVoice_AssignChannel

LABEL_F3BB1E:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F3BAFD

LABEL_F3BB27:
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
	ldfr_berp A, 0xE7
	ld xiy, xde
	ldi_berp 0xE6, 0

LABEL_F3BB47:
	ldto_berp A, 0xE6
	ldfr_berp A, 0xF0
	extz ix
	ldto_berp A, 0xE7
	extz wa
	muls wa, 0xC
	ldada xhl, 8186
	exts xwa
	add xwa, xhl
	ld iz, ix
	extz xiz
	add xiz, xwa
	ldto_berp A, 0xE6
	ldfr_berp A, 0xF0
	extz ix
	ld a, (xiz)
	lda_dri3 XBC, 0x07, 0xF4, 0xF0
	inc1_berp 0xE6
	cpi_berp 0xE6, 4
	jr c, LABEL_F3BB47
	muls bc, 0xC
	st_dri3b D, 0x07, 0xEC, 0xE4
	ld iy, (xix + 4)
	ld l, (xde + 1)
	cp l, (xsp + 18)
	jr ule, LABEL_F3BB98
	decm 1, (xsp + 20)
	addmi8 (xsp + 18), 0x60

LABEL_F3BB98:
	lda xde, (xsp + 8)
	lda xbc, (xde + 1)
	cp (xsp + 20), iy
	jr c, LABEL_F3BBB3
	ld a, (xsp + 18)
	sub a, l
	ld (xde), a
	ld wa, (xsp + 20)
	sub wa, iy
	ld (xbc), a
	jr LABEL_F3BBB9

LABEL_F3BBB3:
	ld (xde), 0x2
	ld (xbc), 0x0

LABEL_F3BBB9:
	cp (xbc), 0x0
	jr nz, LABEL_F3BBC6
	cp (xde), 0x2
	jr nc, LABEL_F3BBC6
	ld (xde), 0x2

LABEL_F3BBC6:
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

LABEL_F3BBE1:
	push xiz
	ld xiz, xwa
	cp (xiz), 0x80
	jr nz, ToneVoice_VoiceTypeCheck
	ldda8 c, 8996
	cp c, 0xFF
	jr z, ToneVoice_VoiceTypeCheck
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3BBFF
	slaa de

LABEL_F3BBFF:
	andda16 xde, 10410
	jr z, ToneVoice_VoiceTypeCheck
	bitda 1, 10417
	jr z, LABEL_F3BC14
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 4
	jr LABEL_F3BC1C

LABEL_F3BC14:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 4

LABEL_F3BC1C:
	calr ToneVoice_AssignChannel

ToneVoice_VoiceTypeCheck:
	cp (xiz), 0x85
	jr z, LABEL_F3BC29
	cp (xiz), 0x86
	jr nz, ToneVoice_ChannelAssignRet

LABEL_F3BC29:
	ldda8 c, 8996
	cp c, 0xFF
	jr z, LABEL_F3BC5F
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3BC3F
	slaa de

LABEL_F3BC3F:
	andda16 xde, 10410
	jr z, LABEL_F3BC5F
	bitda 1, 10417
	jr z, LABEL_F3BC54
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 2
	jr LABEL_F3BC5C

LABEL_F3BC54:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 2

LABEL_F3BC5C:
	calr ToneVoice_AssignChannel

LABEL_F3BC5F:
	ldda8 c, 8994
	cp c, 0xFF
	jr z, ToneVoice_ChannelAssignRet
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3BC75
	slaa de

LABEL_F3BC75:
	andda16 xde, 10410
	jr z, ToneVoice_ChannelAssignRet
	bitda 1, 10417
	jr z, LABEL_F3BC8A
	ldw wa, 0x12
	ld xbc, xiz
	lds de, 2
	jr LABEL_F3BC92

LABEL_F3BC8A:
	extz bc
	ld wa, bc
	ld xbc, xiz
	lds de, 2

LABEL_F3BC92:
	calr ToneVoice_AssignChannel

ToneVoice_ChannelAssignRet:
	pop xiz
	ret

LABEL_F3BC97:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xbc
	ld (xsp + 14), a
	cp (xiz + 3), 0x0
	jrl z, LABEL_F3BE6A
	call LABEL_F3E7AC
	ld (xsp + 6), l
	cp (xsp + 6), 0xFF
	jrl z, SeqNote_VoiceConfigExit
	ld a, (xiz + 4)
	ld (xsp + 4), a
	ld c, (xsp + 6)
	extz bc
	ld a, c
	ldfr_berp A, 0xEE
	ld xix, xiz
	ldi_berp 0xE6, 0

LABEL_F3BCCA:
	ldto_berp L, 0xE6
	extz hl
	ldto_berp A, 0xEE
	extz wa
	muls wa, 0xC
	ldada xde, 8186
	exts xwa
	add xwa, xde
	ld iy, hl
	extz xiy
	add xiy, xwa
	ldto_berp A, 0xE6
	extz wa
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xiy), a
	inc1_berp 0xE6
	cpi_berp 0xE6, 4
	jr c, LABEL_F3BCCA
	muls bc, 0xC
	exts xbc
	add xbc, xde
	ld a, (xsp + 4)
	ld (xbc + 9), a
	ldmw2 (xsp + 8), 0x2326
	cp (xsp + 14), 0x1
	jr nz, LABEL_F3BD31
	ld c, (xiz + 1)
	extz bc
	ld wa, (xsp + 8)
	calr VoiceConfig_FindChannelMatch
	lda xde, (xsp + 10)
	ldada xbc, 9252
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr LABEL_F3BD99

LABEL_F3BD31:
	ldda8 l, 10437
	and l, 0x41
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp l, 0x41
	jr nz, LABEL_F3BD81
	lds hl, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F3BD58
	slaa hl

LABEL_F3BD58:
	andda16 xhl, 10408
	jr z, LABEL_F3BD81
	lda xhl, (xsp + 10)
	add bc, bc
	ldada xwa, 10526
	ld_sriw3 WA, 0x07, 0xE0, 0xE4
	ld (xhl), wa
	extz de
	ldada xbc, 10558
	extz xde
	add xde, xbc
	ld a, (xde)
	extz wa
	ld (xhl + 2), wa
	jr LABEL_F3BD99

LABEL_F3BD81:
	lda xde, (xsp + 10)
	sla bc, 2
	ldada xwa, 9184
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

LABEL_F3BD99:
	lda xwa, (xsp + 10)
	ld xbc, xiz
	lds de, 4
	call Part_CopyBytesToVoiceBlock
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xC
	ldada xbc, 8186
	st_dri3b B, 0x07, 0xE4, 0xE0
	lda xwa, (xsp + 10)
	ld bc, (xwa)
	ld (xde + 6), bc
	ld bc, (xwa + 2)
	ld (xde + 8), c
	ld bc, (xsp + 8)
	ld (xde + 4), bc
	cpdi16 8954, 65535
	jr nz, LABEL_F3BDD7
	mrdw5 0x9F, 0x08, 0x19, 0xFA, 0x22

LABEL_F3BDD7:
	ld (xiz), 0x0
	ld (xiz + 1), 0x0
	ld xbc, xiz
	lds de, 2
	call Part_CopyBytesToVoiceBlock
	lda xix, (xsp + 10)
	ldada xiy, 9184
	lda xhl, (xix + 2)
	cp (xsp + 14), 0x1
	jr nz, LABEL_F3BE04
	ld de, (xix)
	ld bc, (xhl)
	lda xwa, (xiy + 68)
	ld (xwa), de
	ld (xwa + 2), bc
	jr LABEL_F3BE5F

LABEL_F3BE04:
	ldda8 d, 10437
	and d, 0x41
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	dec 1, a
	ld e, a
	ld c, e
	extz bc
	cp d, 0x41
	jr nz, LABEL_F3BE4E
	lds iz, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F3BE2B
	slaa iz

LABEL_F3BE2B:
	andda16 xiz, 10408
	jr z, LABEL_F3BE4E
	ld ix, (xix)
	ld hl, (xhl)
	add bc, bc
	ldada xwa, 10526
	st_dri3w IX, 0x07, 0xE0, 0xE4
	extz de
	ldada xbc, 10558
	extz xde
	add xde, xbc
	ld (xde), l
	jr LABEL_F3BE5F

LABEL_F3BE4E:
	ld ix, (xix)
	ld de, (xhl)
	sla bc, 2
	st_dri3b W, 0x07, 0xF4, 0xE4
	ld (xwa), ix
	ld (xwa + 2), de

LABEL_F3BE5F:
	ld a, (xsp + 6)
	extz wa
	call LABEL_F3E5C6
	jr SeqNote_VoiceConfigExit

LABEL_F3BE6A:
	ldda8 a, 8182
	ld (xsp + 6), a
	cp (xsp + 6), 0xFF
	jr z, LABEL_F3BEAD
	ldada xhl, 8186
	ld c, (xiz + 2)

LABEL_F3BE7E:
	ld a, (xsp + 6)
	extz wa
	muls wa, 0xC
	st_dri3b B, 0x07, 0xEC, 0xE0
	ld w, (xde + 2)
	ld a, (xde + 9)
	ld (xsp + 4), a
	cp w, c
	jr nz, LABEL_F3BEA1
	ld a, (xsp + 4)
	cp a, (xiz + 4)
	jr z, LABEL_F3BEAD

LABEL_F3BEA1:
	ld a, (xde + 11)
	ld (xsp + 6), a
	cp (xsp + 6), 0xFF
	jr nz, LABEL_F3BE7E

LABEL_F3BEAD:
	cp (xsp + 6), 0xFF
	jr z, SeqNote_VoiceConfigExit
	ldda16 xbc, 8998
	ld a, (xsp + 6)
	extz wa
	ld e, (xiz + 1)
	extz de
	calr Part_AssignVoiceConfig
	ld a, (xsp + 6)
	extz wa
	call LABEL_F3E543
	ld a, (xsp + 6)
	extz wa
	call LABEL_F3E4EF

SeqNote_VoiceConfigExit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

LABEL_F3BEDB:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), xwa
	ld xbc, (xsp + 2)
	ld a, (xbc + 2)
	ldfr_berp A, 0xFB
	ld a, (xbc + 3)
	ldfr_berp A, 0xFA
	ld xwa, (xsp + 2)
	calr Part_CheckAndSetModifiedFlags
	cp_erpb 0xFB, 0x48
	jr nz, LABEL_F3BF7C
	cpi_berp 0xFA, 5
	jr z, LABEL_F3BF08
	cpi_berp 0xFA, 6
	jr nz, LABEL_F3BF7C

LABEL_F3BF08:
	ldda8 c, 8996
	cp c, 0xFF
	jr z, LABEL_F3BF40
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3BF1E
	slaa de

LABEL_F3BF1E:
	andda16 xde, 10410
	jr z, LABEL_F3BF40
	bitda 1, 10417
	jr z, LABEL_F3BF34
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	lds de, 6
	jr LABEL_F3BF3D

LABEL_F3BF34:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	lds de, 6

LABEL_F3BF3D:
	calr ToneVoice_AssignChannel

LABEL_F3BF40:
	ldda8 c, 8994
	cp c, 0xFF
	jr z, LABEL_F3BF78
	ld a, c
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3BF56
	slaa de

LABEL_F3BF56:
	andda16 xde, 10410
	jr z, LABEL_F3BF78
	bitda 1, 10417
	jr z, LABEL_F3BF6C
	ldw wa, 0x12
	ld xbc, (xsp + 2)
	lds de, 6
	jr LABEL_F3BF75

LABEL_F3BF6C:
	extz bc
	ld wa, bc
	ld xbc, (xsp + 2)
	lds de, 6

LABEL_F3BF75:
	calr ToneVoice_AssignChannel

LABEL_F3BF78:
	ldb l, 0x0
	jr LABEL_F3BF7E

LABEL_F3BF7C:
	ldb l, 0x6

LABEL_F3BF7E:
	pop_werp 0xFA
	inc 4, xsp
	ret

SeqNote_SetupVoice:
	dec 6, xsp
	push xiz
	ld (xsp + 4), xbc
	ld (xsp + 8), a
	ldda8 a, 7604
	ldfr_berp A, 0xFA
	cp_erpb 0xFA, 0xFF
	jr nz, LABEL_F3BF9F
	ldb l, 0x1
	jrl LABEL_F3C052

LABEL_F3BF9F:
	cp (xsp + 8), 0x0
	jr nz, LABEL_F3BFAC
	ldw wa, 0xD
	call SeqData_SetErrorCode

LABEL_F3BFAC:
	cp_erpb 0xFA, 0x40
	jr c, LABEL_F3BFB9
	ldw wa, 0xE
	call SeqData_SetErrorCode

LABEL_F3BFB9:
	ldto_berp A, 0xFA
	extz wa
	call LABEL_F3E6CF
	ld a, (xsp + 8)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9016
	exts xwa
	add xwa, xbc
	ld iz, (xwa)
	ld a, (xwa + 3)
	ldfr_berp A, 0xFB
	ld xwa, (xsp + 4)
	ldto_berp C, 0xFB
	add c, (xwa + 4)
	ldfr_berp C, 0xFB
	cp_erpb 0xFB, 0x60
	jr c, LABEL_F3BFF4
	sub_erpb 0xFB, 0x60
	inc 1, iz

LABEL_F3BFF4:
	ld xwa, (xsp + 4)
	ld a, (xwa + 5)
	extz wa
	add iz, wa
	cp (xsp + 8), 0x11
	jr nz, LABEL_F3C009
	ldmi16 (xsp + 8), 0x231A

LABEL_F3C009:
	cp_erpb 0xFB, 0x60
	jr ule, LABEL_F3C016
	ldw wa, 0xF
	call SeqData_SetErrorCode

LABEL_F3C016:
	ldto_berp A, 0xFA
	extz wa
	ld bc, wa
	muls bc, 0x9
	ldada xde, 7606
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld xhl, (xsp + 4)
	ld c, (xhl)
	ld (xde + 4), c
	ldto_berp C, 0xFB
	ld (xde + 5), c
	ld c, (xhl + 2)
	ld (xde + 6), c
	ld (xde + 7), 0x0
	ld c, (xsp + 8)
	dec 1, c
	ld (xde + 8), c
	ld (xde + 2), iz
	calr LABEL_F3C7A7
	ldb l, 0x0

LABEL_F3C052:
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
	ldda8 a, 10437
	and a, 0x41
	ldfr_berp A, 0xE2
	ld a, (xsp + 4)
	extz wa
	dec 1, a
	ld d, a
	ld l, d
	extz hl
	cp_erpb 0xE2, 0x41
	jr nz, LABEL_F3C0B0
	ld a, (xsp + 4)
	dec 1, a
	lds ix, 1
	and a, 0xF
	jr z, LABEL_F3C086
	slaa ix

LABEL_F3C086:
	andda16 xix, 10408
	jr z, LABEL_F3C0B0
	lda xix, (xsp)
	add hl, hl
	ldada xwa, 10526
	ld_sriw3 WA, 0x07, 0xE0, 0xEC
	ld (xix), wa
	ld a, d
	extz wa
	ldada xhl, 10558
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	extz wa
	ld (xix + 2), wa
	jr LABEL_F3C0C7

LABEL_F3C0B0:
	lda xix, (xsp)
	sla hl, 2
	ldada xwa, 9184
	exts xhl
	add xhl, xwa
	ld wa, (xhl)
	ld (xix), wa
	ld wa, (xhl + 2)
	ld (xix + 2), wa

LABEL_F3C0C7:
	lda xwa, (xsp)
	extz de
	call Part_CopyBytesToVoiceBlock
	ldda8 a, 10437
	and a, 0x41
	ldfr_berp A, 0xE2
	ld a, (xsp + 4)
	extz wa
	dec 1, a
	ldfr_berp A, 0xEE
	ldto_berp L, 0xEE
	extz hl
	lda xde, (xsp)
	lda xbc, (xde + 2)
	cp_erpb 0xE2, 0x41
	jr nz, LABEL_F3C127
	ld a, (xsp + 4)
	dec 1, a
	lds ix, 1
	and a, 0xF
	jr z, LABEL_F3C101
	slaa ix

LABEL_F3C101:
	andda16 xix, 10408
	jr z, LABEL_F3C127
	ld ix, (xde)
	ld de, (xbc)
	add hl, hl
	ldada xwa, 10526
	st_dri3w IX, 0x07, 0xE0, 0xEC
	ldto_berp A, 0xEE
	extz wa
	ldada xbc, 10558
	extz xwa
	add xwa, xbc
	ld (xwa), e
	jr LABEL_F3C13C

LABEL_F3C127:
	ld de, (xde)
	ld bc, (xbc)
	sla hl, 2
	ldada xwa, 9184
	st_dri3b W, 0x07, 0xE0, 0xEC
	ld (xwa), de
	ld (xwa + 2), bc

LABEL_F3C13C:
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
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa

LABEL_F3C169:
	lda xwa, (xsp)
	lda xbc, (xsp + 4)
	call SeqPart_ReadNextEventByte
	lda xhl, (xsp + 4)
	lda xbc, (xhl + 1)
	ld a, (xhl)
	cp a, 0x81
	jr nz, LABEL_F3C1C7
	incdi16 1, 9152
	ld (xbc), 0x0
	cp (xsp + 12), 0x0
	jr nz, LABEL_F3C169

LABEL_F3C18C:
	ld c, (xsp + 14)
	extz bc
	lda xwa, (xsp)
	ld ix, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), ix
	ld (xwa + 2), de
	ldada xwa, 9152
	ld xbc, xhl
	lda xde, (xwa + 2)
	inc 6, xhl

LABEL_F3C1B9:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_F3C1B9
	lda xsp, (xsp + 16)
	ret

LABEL_F3C1C7:
	cp a, 0x82
	jr nz, LABEL_F3C18C
	ld (xbc), 0x0
	jr LABEL_F3C18C

SeqPlay_ReassignVoiceChannels:
	dec 2, xsp
	push xiz
	ldmw2 (xsp + 4), 0x2668
	mrdw5 0x9F, 0x04, 0x19, 0x34, 0x23
	bitda 1, 10417
	jrl nz, LABEL_F3C291
	ldi_berp 0xFB, 1

LABEL_F3C1E8:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C1F6
	slaa bc

LABEL_F3C1F6:
	andda16 xbc, 10408
	jrl z, LABEL_F3C284
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F3C22B
	ldto_berp A, 0xFB
	extz wa
	call LABEL_F3F469
	ldto_berp A, 0xFB
	extz wa
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C225
	slaa bc

LABEL_F3C225:
	cpl bc
	anddm16 8982, xbc

LABEL_F3C22B:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xFFFF
	jr z, LABEL_F3C2B6
	cpdi8 7528, 0
	jr z, LABEL_F3C2B6
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldto_berp A, 0xFB
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), iz
	ldw (xwa + 2), 0x5

LABEL_F3C284:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jrl ule, LABEL_F3C1E8
	jrl LABEL_F3C352

LABEL_F3C291:
	ldda8 a, 8986
	ldfr_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C2A3
	slaa bc

LABEL_F3C2A3:
	andda16 xbc, 8980
	jrl nz, LABEL_F3C352
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F3C2BB

LABEL_F3C2B6:
	ldb l, 0x2
	jrl LABEL_F3C37C

LABEL_F3C2BB:
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	ldto_berp C, 0xFB
	extz bc
	ld l, c
	dec 1, l
	ld a, l
	extz wa
	sla wa, 2
	ldada xde, 9184
	exts xwa
	add xwa, xde
	ld (xwa), iz
	ldw (xwa + 2), 0x5
	lds de, 1
	ld a, l
	and a, 0xF
	jr z, LABEL_F3C310
	slaa de

LABEL_F3C310:
	orddm16 8982, xde
	orddm16 10420, xde
	orddm16 8980, xde
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ldto_berp A, 0xFB
	extz wa
	ld c, a
	dec 1, c
	extz bc
	sla bc, 3
	ldada xde, 9332
	exts xbc
	add xbc, xde
	ld (xbc), iz
	ldw (xbc + 2), 0x5
	call SeqCh_LoadChannelConfig

LABEL_F3C352:
	ldda16 xwa, 10408
	stda16 10410, xwa
	ldda16 xwa, 8982
	stda16 8984, xwa
	call SeqPlay_CheckRepeatActive
	call SeqAccomp_SendStopNotify
	cpw (xsp + 4), 0x1
	jr nz, LABEL_F3C37A
	bitda 1, 10417
	call_24 z, 0xF3D61F

LABEL_F3C37A:
	ldb l, 0x0

LABEL_F3C37C:
	pop xiz
	inc 2, xsp
	ret

SeqPlay_AssignAccompVoices:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 18), c
	ld (xsp + 20), wa
	stdi16 7574, 65535
	stdi16 7578, 65535
	lds wa, 0
	ldw bc, 0xD
	call Part_FindVoiceByByte
	ld (xsp + 4), l
	cp (xsp + 4), 0xFF
	jrl z, SeqPlay_RestoreReturn2
	ld a, (xsp + 4)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C3B7
	slaa bc

LABEL_F3C3B7:
	andda16 xbc, 8982
	jrl z, SeqPlay_RestoreReturn2
	addmi8 (xsp + 18), 0x1A
	cp (xsp + 18), 0x60
	jrl c, SeqPlay_WriteVoiceData
	submi8 (xsp + 18), 0x60
	incm 1, (xsp + 20)
	jrl SeqPlay_WriteVoiceData

LABEL_F3C3D3:
	cp wa, (xsp + 20)
	jr nz, LABEL_F3C3E3
	ld_srib A, (xhl + 0x009b)
	cp a, (xsp + 18)
	jrl ugt, LABEL_F3C506

LABEL_F3C3E3:
	lda xix, (xsp + 10)
	ld xiy, xix
	ldi_berp 0xE2, 0

LABEL_F3C3EB:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b A, 0xED, 0x98, 0x00
	ld de, wa
	extz xde
	add xde, xbc
	ldto_berp C, 0xE2
	extz bc
	ld a, (xde)
	lda_dri3 XBC, 0x07, 0xF4, 0xE4
	inc1_berp 0xE2
	lda xbc, (xix + 4)
	lda xde, (xix + 5)
	cpi_berp 0xE2, 6
	jr c, LABEL_F3C3EB
	ld a, (xsp + 4)
	dec 1, a
	lds hl, 1
	and a, 0xF
	jr z, LABEL_F3C425
	slaa hl

LABEL_F3C425:
	ld a, (xix)
	cp a, 0xB0
	jrl nz, LABEL_F3C53E
	cp (xix + 2), 0x48
	jr nz, ToneVoice_AssignChannel_LoadConfig
	ld a, (xix + 3)
	cps a, 5
	jrl nz, LABEL_F3C508
	ld xix, xde
	ld a, (xde)
	and a, 0xC
	jr z, ToneVoice_AssignChannel_LoadConfig
	ld xde, xbc
	ld a, (xbc)
	and a, 0xC
	jr z, ToneVoice_AssignChannel_LoadConfig
	setda 1, 8974
	andda16 xhl, 61854
	jr z, ToneVoice_AssignChannel_LoadConfig
	ld c, (xde)
	extz bc
	ld a, (xix)
	extz wa
	stdi8 13448, 5
	stda8 13429, c
	stda8 13430, a

LABEL_F3C46C:
	call AccWrap_ReplaySavedPedal

ToneVoice_AssignChannel_LoadConfig:
	ldw wa, 0x14
	call SeqCh_LoadChannelConfig
	lda xix, (xsp + 10)
	ld xiz, xix
	ldi_berp 0xE2, 0

LABEL_F3C47F:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	ldada xde, 9016
	st_dri3b A, 0xE9, 0x98, 0x00
	ld iy, wa
	extz xiy
	add xiy, xbc
	ldto_berp L, 0xE2
	extz hl
	ld a, (xiy)
	lda_dri3 XBC, 0x07, 0xF8, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3C47F
	cp (xix), 0x82
	jr nz, SeqPlay_WriteVoiceData
	st_dri3b C, 0xE9, 0x9B, 0x00
	ld a, (xhl)
	cp a, 0x30
	jr ule, LABEL_F3C4C6
	inc_sriw 1, 0xE9, 0x98, 0x00
	ld a, (xhl)
	sub a, 0x30
	ld (xhl), a

LABEL_F3C4C6:
	addmi8 (xhl), 0x30
	st_dri3b B, 0xE9, 0x98, 0x00
	ld wa, (xde)
	ld a, (xhl)
	ld (xix + 1), a
	ldb l, 0x0

LABEL_F3C4D7:
	ld e, l
	extz de
	inc 2, de
	extz xde
	add xde, xbc
	ld a, l
	extz wa
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xde), a
	inc 1, l
	cps l, 6
	jr c, LABEL_F3C4D7

SeqPlay_WriteVoiceData:
	ldada xhl, 9016
	st_dri3b W, 0xED, 0x98, 0x00
	ld (xsp + 6), xwa
	ld wa, (xwa)
	cp wa, (xsp + 20)
	jrl ule, LABEL_F3C3D3

LABEL_F3C506:
	jr SeqPlay_RestoreReturn2

LABEL_F3C508:
	cps a, 6
	jrl nz, ToneVoice_AssignChannel_LoadConfig
	ld xix, xde
	bitm 2, (xde)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	ld xwa, xbc
	bitm 2, (xbc)
	jrl z, ToneVoice_AssignChannel_LoadConfig
	setda 1, 8974
	andda16 xhl, 61854
	jrl z, ToneVoice_AssignChannel_LoadConfig
	ld c, (xwa)
	extz bc
	ld a, (xix)
	extz wa
	stdi8 13448, 6
	stda8 13429, c
	stda8 13430, a
	jrl LABEL_F3C46C

LABEL_F3C53E:
	cp a, 0x90
	jr nz, LABEL_F3C553
	andda16 xhl, 61854
	jrl z, ToneVoice_AssignChannel_LoadConfig
	lds wa, 0
	call Voice_AllocateFromSeqData
	jrl ToneVoice_AssignChannel_LoadConfig

LABEL_F3C553:
	cp a, 0x82
	jrl nz, ToneVoice_AssignChannel_LoadConfig
	ld xwa, (xsp + 6)
	ldw (xwa), 0xFFFF

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
	cp (xsp), 0xFF
	jrl z, SeqPlay_BassEpilogue18
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C58C
	slaa bc

LABEL_F3C58C:
	andda16 xbc, 8982
	jrl z, SeqPlay_BassEpilogue18
	addmi8 (xsp + 14), 0x28
	cp (xsp + 14), 0x60
	jrl c, LABEL_F3C650
	submi8 (xsp + 14), 0x60
	incm 1, (xsp + 16)
	jrl LABEL_F3C650

LABEL_F3C5A8:
	extz bc
	sla bc, 3
	ldada xwa, 9016
	ld (xsp + 2), xwa
	exts xbc
	add xbc, xwa
	ld wa, (xbc)
	cp wa, (xsp + 16)
	jrl ugt, SeqPlay_BassEpilogue18
	ld wa, (xbc)
	cp wa, (xsp + 16)
	jr nz, LABEL_F3C5D0
	ld a, (xbc + 3)
	cp a, (xsp + 14)
	jrl ugt, SeqPlay_BassEpilogue18

LABEL_F3C5D0:
	ld a, (xsp)
	extz wa
	lda xde, (xsp + 6)
	ld c, a
	ldfr_berp C, 0xEE
	ld xiy, xde
	ldi_berp 0xE2, 0

LABEL_F3C5E1:
	ldto_berp C, 0xE2
	extz bc
	ld ix, bc
	inc 2, ix
	ldto_berp L, 0xEE
	dec 1, l
	extz hl
	sla hl, 3
	ld xbc, (xsp + 2)
	st_dri3b A, 0x07, 0xE4, 0xEC
	extz xix
	add xix, xbc
	ldto_berp L, 0xE2
	extz hl
	ld c, (xix)
	lda_dri3 XHL, 0x07, 0xF4, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3C5E1
	cp (xde), 0x82
	jr z, SeqPlay_BassEpilogue18
	calr SeqNote_ProcessForChannel
	lda xwa, (xsp + 6)
	cp (xwa), 0xC0
	jr nz, SeqPlay_DispatchRhythm
	cp (xwa + 2), 0x48
	jr nz, SeqPlay_DispatchRhythm
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_DispatchRhythm
	ldda8 a, 7564
	extz wa
	ldda8 c, 7566
	extz bc
	call Rhythm_NoteDispatchWrapper
	stda8 9010, l
	call SeqMode_SendStatusUpdate

SeqPlay_DispatchRhythm:
	ld a, (xsp)
	extz wa
	call SeqCh_LoadChannelConfig

LABEL_F3C650:
	ld c, (xsp)
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F3C65F
	slaa de

LABEL_F3C65F:
	andda16 xde, 8982
	jrl nz, LABEL_F3C5A8

SeqPlay_BassEpilogue18:
	lda xsp, (xsp + 18)
	ret

SeqPlay_AssignChordVoices:
	lda xsp, (xsp - 14)
	ld (xsp + 10), c
	ld (xsp + 12), wa
	ld xiy, 0xE4451E
	lda xix, (xsp + 2)
	lds bc, 4
	ldirw
	lds wa, 0
	ldw bc, 0xF
	call Part_FindVoiceByByte
	ld (xsp), l
	cp (xsp), 0xFF
	jrl z, SeqPlay_ChordEpilogue14
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C69D
	slaa bc

LABEL_F3C69D:
	andda16 xbc, 8982
	jrl z, SeqPlay_ChordEpilogue14
	addmi8 (xsp + 10), 0x28
	cp (xsp + 10), 0x60
	jrl c, LABEL_F3C744
	submi8 (xsp + 10), 0x60
	incm 1, (xsp + 12)
	jrl LABEL_F3C744

LABEL_F3C6B9:
	ldada xde, 9016
	ld_sriw WA, (xde + 0x00a0)
	cp wa, (xsp + 12)
	jrl ugt, SeqPlay_ChordEpilogue14
	cp wa, (xsp + 12)
	jr nz, LABEL_F3C6D8
	ld_srib A, (xde + 0x00a3)
	cp a, (xsp + 10)
	jrl ugt, SeqPlay_ChordEpilogue14

LABEL_F3C6D8:
	lda xbc, (xsp + 2)
	ld xiy, xbc
	ldi_berp 0xE2, 0

LABEL_F3C6E0:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b C, 0xE9, 0xA0, 0x00
	ld ix, wa
	extz xix
	add xix, xhl
	ldto_berp L, 0xE2
	extz hl
	ld a, (xix)
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3C6E0
	cp (xbc), 0x82
	jr z, SeqPlay_ChordEpilogue14
	ldw wa, 0x15
	calr SeqNote_ProcessForChannel
	lda xwa, (xsp + 2)
	cp (xwa), 0xC0
	jr nz, SeqPlay_LoadChannelRet
	cp (xwa + 2), 0x48
	jr nz, SeqPlay_LoadChannelRet
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_LoadChannelRet
	ldda8 a, 7564
	extz wa
	ldda8 c, 7566
	extz bc
	call Rhythm_NoteDispatchWrapper
	stda8 9010, l
	call SeqMode_SendStatusUpdate

SeqPlay_LoadChannelRet:
	ldw wa, 0x15
	call SeqCh_LoadChannelConfig

LABEL_F3C744:
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3C751
	slaa bc

LABEL_F3C751:
	andda16 xbc, 8982
	jrl nz, LABEL_F3C6B9

SeqPlay_ChordEpilogue14:
	lda xsp, (xsp + 14)
	ret

SeqCh_ClearActivePartBit:
	ld c, a
	ld a, c
	extz wa
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3C76D
	slaa de

LABEL_F3C76D:
	cpl de
	anddm16 10420, xde
	anddm16 8980, xde
	ldda8 a, 64607
	and a, 0x30
	ret nz
	ldda8 a, 8988
	cp c, a
	ret nz
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F3C795
	slaa de

LABEL_F3C795:
	ldda16 xwa, 61854
	and wa, de
	ret z
	bitda 2, 1054
	ret z
	jp AccWrap_PlayModeStartPlay

LABEL_F3C7A7:
	dec 8, xsp
	push xiz
	ld (xsp + 10), a
	cp (xsp + 10), 0x40
	jr c, LABEL_F3C7BA
	ldw wa, 0x10
	call SeqData_SetErrorCode

LABEL_F3C7BA:
	ld a, (xsp + 10)
	extz wa
	muls wa, 0x9
	ldada xhl, 7606
	st_dri3b B, 0x07, 0xEC, 0xE0
	ld iy, (xde + 2)
	ld w, (xde + 5)
	ld (xsp + 8), w
	ldada xix, 7602
	lda xwa, (xix + 1)
	ld (xsp + 4), xwa
	ld a, (xwa)
	ldfr_berp A, 0xE2

LABEL_F3C7E4:
	lda xbc, (xde + 1)
	cp_erpb 0xE2, 0xFF
	jr nz, LABEL_F3C825
	ld (xde), 0xFF
	ld a, (xix)
	ldfr_berp A, 0xE2
	ld (xbc), a
	cp_erpb 0xE2, 0xFF
	jr z, LABEL_F3C810
	ldto_berp A, 0xE2
	extz wa
	muls wa, 0x9
	ld bc, wa
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xEC, 0xE4

LABEL_F3C810:
	ld a, (xsp + 10)
	ld (xix), a
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ldfr_berp A, 0xE2
	cp_erpb 0xE2, 0xFF
	jr z, LABEL_F3C874
	jr LABEL_F3C88C

LABEL_F3C825:
	ldto_berp A, 0xE2
	ldfr_berp A, 0xF8
	extz iz
	muls iz, 0x9
	exts xiz
	add xiz, xhl
	ld wa, (xiz + 2)
	ldfr_werp WA, 0xF6
	ld a, (xiz + 5)
	ldfr_berp A, 0xE3
	ldto_werp WA, 0xF6
	cp wa, iy
	jr ugt, LABEL_F3C857
	ldto_werp WA, 0xF6
	cp wa, iy
	jr nz, LABEL_F3C85E
	ldto_berp A, 0xE3
	cp a, (xsp + 8)
	jr ule, LABEL_F3C85E

LABEL_F3C857:
	ld a, (xiz)
	ldfr_berp A, 0xE2
	jr LABEL_F3C7E4

LABEL_F3C85E:
	ldto_berp A, 0xE2
	ld (xde), a
	lda xix, (xiz + 1)
	ld e, (xix)
	ld (xbc), e
	ld a, (xsp + 10)
	ld (xix), a
	cp e, 0xFF
	jr nz, LABEL_F3C87E

LABEL_F3C874:
	ld xwa, (xsp + 4)
	ld c, (xsp + 10)
	ld (xwa), c
	jr LABEL_F3C88C

LABEL_F3C87E:
	extz de
	muls de, 0x9
	ld a, (xsp + 10)
	lda_dri3 XBC, 0x07, 0xEC, 0xE8

LABEL_F3C88C:
	pop xiz
	inc 8, xsp
	ret

LABEL_F3C890:
	.byte 0xc1, 0x7f, 0xc0, 0x21, 0xc9, 0xd8, 0xb0, 0xf6
	.byte 0xc1, 0x7e, 0xc0, 0x21, 0xc9, 0xd8, 0xb0, 0xfe
	.byte 0xc1, 0x7d, 0xc0, 0x21, 0xf1, 0xb3, 0x28, 0xcd
	.byte 0xb0, 0xf6, 0xc9, 0xdc, 0xb0, 0xfe, 0x1e, 0x74
	.byte 0xd8, 0x1d, 0xdf, 0x87, 0xf4, 0xf1, 0xb3, 0x28
	.byte 0xb5, 0x0e
LABEL_F3C8BA:
	.byte 0xf1, 0xfe, 0x22, 0xcf, 0xb0, 0xfe
	.byte 0xc1, 0x34, 0x8d, 0x3f, 0x0e, 0xb0, 0xf6, 0xc1
	.byte 0x7d, 0xc0, 0x21, 0xc9, 0xdd, 0xb0, 0xfe, 0xc1
	.byte 0x7e, 0xc0, 0x23, 0xc1, 0x7f, 0xc0, 0x21, 0xc9
	.byte 0xc3, 0xcb, 0xcc, 0x40, 0xb0, 0xf6, 0xc1, 0x38
	.byte 0x8d, 0x3f, 0x8a, 0xb0, 0xf6, 0xd1, 0x9e, 0xf1
	.byte 0x3f, 0x00, 0x00, 0xb0, 0xf6, 0xf1, 0x21, 0x04
	.byte 0xca, 0xb0, 0xfe, 0xd1, 0xa8, 0x28, 0x3f, 0x00
	.byte 0x00, 0xb0, 0xfe, 0xf1, 0x1e, 0x04, 0xca, 0xb0
	.byte 0xfe, 0x68, 0x00

SeqPlay_CheckStartConditions:
	ldda8 a, 8958
	bit 7, a
	ret nz
	set 7, a
	stda8 8958, a
	cpdi16 61854, 0
	jr nz, LABEL_F3C927
	ldda8 a, 8958
	res 7, a
	stda8 8958, a
	ret

LABEL_F3C927:
	ldda8 a, 8958
	bitda 2, 1057
	jr z, LABEL_F3C939
	res 7, a
	stda8 8958, a
	ret

LABEL_F3C939:
	bitda 5, 10419
	jr z, LABEL_F3C947
	res 7, a
	stda8 8958, a
	ret

LABEL_F3C947:
	ldda8 a, 8958
	cpdi16 10408, 0
	jr z, LABEL_F3C95B
	res 7, a
	stda8 8958, a
	ret

LABEL_F3C95B:
	bitda 2, 1054
	jr z, LABEL_F3C969
	res 7, a
	stda8 8958, a
	ret

LABEL_F3C969:
	ldda16 xwa, 9832
	ldda8 c, 36152
	cp c, 0x85
	jr z, LABEL_F3C97B
	cp c, 0x86
	jr nz, LABEL_F3C9CB

LABEL_F3C97B:
	bitda 1, 10417
	jr nz, LABEL_F3C989
	stdi16 9832, 1
	jr LABEL_F3C9C4

LABEL_F3C989:
	ldda16 xbc, 9504
	cp wa, bc
	jr ugt, LABEL_F3C99F
	stdi16 9832, 1
	stdi16 1052, 0
	jr LABEL_F3C9C4

LABEL_F3C99F:
	stda16 9832, xbc
	ldda16 xwa, 9504
	call SeqBuf_AllocNextSlot
	stda16 9000, xhl
	stda16 1052, xhl
	stdi8 1051, 0
	ldda16 xwa, 9506
	call SeqBuf_AllocNextSlotAdjusted
	stda16 9002, xhl

LABEL_F3C9C4:
	stdi8 1051, 0
	jr LABEL_F3CA14

LABEL_F3C9CB:
	bitda 0, 10417
	jr nz, LABEL_F3C9D9
	stdi16 9832, 1
	jr LABEL_F3CA14

LABEL_F3C9D9:
	ldda16 xbc, 9500
	cp wa, bc
	jr ugt, LABEL_F3C9EF
	stdi16 9832, 1
	stdi16 1052, 0
	jr LABEL_F3CA14

LABEL_F3C9EF:
	stda16 9832, xbc
	ldda16 xwa, 9500
	call SeqBuf_AllocNextSlot
	stda16 9000, xhl
	stda16 1052, xhl
	stdi8 1051, 0
	ldda16 xwa, 9502
	call SeqBuf_AllocNextSlotAdjusted
	stda16 9002, xhl

LABEL_F3CA14:
	call NoteEditSy_SendModeScrollReset
	cpdi16 9832, 1
	jr nz, LABEL_F3CA31
	resda 3, 10407
	stdi8 4596, 0
	lds wa, 0
	call BitMapOut_PrepareAndRender
	jr LABEL_F3CA35

LABEL_F3CA31:
	setda 3, 10407

LABEL_F3CA35:
	calr SeqAcc_InitPlaybackState
	stdi8 1073, 0
	resda 0, 10406
	resda 7, 10414
	call MidiChannel_ResetAndConfigure
	resda 7, 8958
	ret

LABEL_F3CA4E:
	ldda8 a, 8976
	cps a, 0
	ret nz
	stdi8 8976, 1
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	call AccWrap_PositionClear
	resda 0, 10406
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	stdi8 8976, 0
	ret

Seq_ResetAndRestartAccompaniment:
	stdi16 10420, 0
	call LABEL_F43BD9
	resda 0, 10406
	resda 1, 13434
	resda 3, 10407
	resda 2, 10419
	cpdi8 36148, 19
	jr nz, LABEL_F3CAB5
	stdi8 7572, 1
	calr LABEL_F39BA0
	jr LABEL_F3CABD

LABEL_F3CAB5:
	stdi8 7572, 0
	calr SeqAcc_InitPlaybackState

LABEL_F3CABD:
	jp Audio_CheckSubsystemReady

SeqPlay_StopAndResetAll:
	bitda 0, 10437
	jr z, LABEL_F3CAD5
	cpdi16 10408, 0
	ret nz
	stdi8 8956, 0
	ret

LABEL_F3CAD5:
	ldda8 a, 1054
	bit 3, a
	jr nz, LABEL_F3CAF4
	bit 2, a
	jr z, LABEL_F3CAF4
	bitda 2, 1057
	ret z
	call AccWrap_PlayModeStopExpr
	stdi8 8956, 0
	jr LABEL_F3CAF8

LABEL_F3CAF4:
	call AccWrap_PlayModeDispatch

LABEL_F3CAF8:
	resda 5, 10419
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call AccompSeq_StopSequence
	resda 7, 10414
	call MidiChannel_ResetAndConfigure
	resda 3, 10407
	stdi16 9832, 1
	stdi16 10420, 0
	ldda8 a, 10419
	set 4, a
	set 2, a
	stda8 10419, a
	stdi8 8956, 0
	cpdi8 36148, 19
	ret nz
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	stdi16 10420, 0
	call LABEL_F994FA
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
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F3CB82
	ldw hl, 0xFFFF
	jr LABEL_F3CBC9

LABEL_F3CB82:
	ld c, (xsp + 22)
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	ld xwa, (xsp + 16)
	ld (xwa), hl
	ldw (xwa + 2), 0x5
	cpw (xsp + 20), 0x0
	jr ule, LABEL_F3CBC7

LABEL_F3CB9E:
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
	jr nz, LABEL_F3CBCD
	incm 1, (xsp)

LABEL_F3CBC0:
	ld wa, (xsp)
	cp wa, (xsp + 20)
	jr c, LABEL_F3CB9E

LABEL_F3CBC7:
	ld hl, (xsp)

LABEL_F3CBC9:
	lda xsp, (xsp + 24)
	ret

LABEL_F3CBCD:
	cp a, 0x82
	jr z, LABEL_F3CBD7
	cp a, 0x84
	jr nz, LABEL_F3CBC0

LABEL_F3CBD7:
	ld xwa, (xsp + 16)
	ld bc, (xsp + 2)
	ld (xwa), bc
	ld bc, (xsp + 4)
	ld (xwa + 2), bc
	jr LABEL_F3CBC7

SeqPlay_ReconfigureVoices:
	lda xsp, (xsp - 24)
	push xiz
	cpdi16 10408, 0
	scc8 nz, a
	ld (xsp + 18), a
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	cp (xsp + 18), 0x0
	call_24 nz, 0xF3CD85
	cp (xsp + 18), 0x0
	jr z, LABEL_F3CC19
	ldda16 xbc, 8998
	ldw wa, 0x32
	ldw de, 0x5F
	calr SeqData_ValidateProcess

LABEL_F3CC19:
	cp (xsp + 18), 0x0
	jr z, LABEL_F3CC29
	ldda16 xwa, 7542
	inc 1, wa
	stda16 9006, xwa

LABEL_F3CC29:
	ldmm16 8982, 8984
	cp (xsp + 18), 0x0
	jrl z, LABEL_F3CCFB
	lda xbc, (xsp + 24)
	ldada xwa, 9332
	ld (xsp + 4), xwa
	st_dri3b W, 0xE1, 0x88, 0x00
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
	st_dri3b D, 0xE1, 0x80, 0x00
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
	ldada xix, 9184
	lda xiy, (xix + 64)
	ld (xiy), wa
	ld (xiy + 2), iz
	ld wa, (xbc)
	ldfr_werp WA, 0xFA
	ld iz, (xde)
	ld xwa, (xsp + 4)
	st_dri3b E, 0xE1, 0x90, 0x00
	ldto_werp WA, 0xFA
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
	ldada xbc, 9016
	ldda16 xwa, 7542
	inc 1, wa
	st_dri3w WA, 0xE5, 0x80, 0x00
	ldda16 xwa, 7542
	inc 1, wa
	st_dri3w WA, 0xE5, 0x88, 0x00
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x13
	lds bc, 1
	calr SeqPart_ReadEventStream

LABEL_F3CCFB:
	ld (xsp + 18), 0x1

LABEL_F3CCFF:
	ld c, (xsp + 18)
	dec 1, c
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F3CD0F
	slaa de

LABEL_F3CD0F:
	andda16 xde, 8982
	jr z, LABEL_F3CD6F
	ld l, (xsp + 18)
	cpda8 l, 8990
	jr z, LABEL_F3CD6F
	ld e, c
	extz de
	sla de, 3
	ldada xbc, 9016
	ldda16 xwa, 7542
	inc 1, wa
	st_dri3w WA, 0x07, 0xE4, 0xE8
	ld a, l
	extz wa
	lda xix, (xsp + 24)
	ld e, a
	dec 1, e
	extz de
	ld bc, de
	sla bc, 3
	ldada xhl, 9332
	st_dri3b C, 0x07, 0xEC, 0xE4
	ld bc, (xhl)
	ld (xix), bc
	ld bc, (xhl + 2)
	ld (xix + 2), bc
	ld ix, (xix)
	sla de, 2
	ldada xhl, 9184
	exts xde
	add xde, xhl
	ld (xde), ix
	ld (xde + 2), bc
	call SeqCh_LoadChannelConfig

LABEL_F3CD6F:
	incm8 1, (xsp + 18)
	cp (xsp + 18), 0x10
	jr ule, LABEL_F3CCFF
	ldda16 xwa, 7544
	adddm16 7542, xwa
	pop xiz
	lda xsp, (xsp + 24)
	ret

LABEL_F3CD85:
	dec 8, xsp
	pushw iz
	ldda16 xwa, 8998
	cpda16 xwa, 9152
	jr nc, LABEL_F3CE10
	ld (xsp + 2), 0x81
	lds iz, 0
	jr LABEL_F3CDA7

LABEL_F3CD9A:
	lda xbc, (xsp + 2)
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	inc 1, iz

LABEL_F3CDA7:
	ldda16 xwa, 9152
	subda16 xwa, 8998
	cp iz, wa
	jr c, LABEL_F3CD9A
	jr LABEL_F3CE10

LABEL_F3CDB5:
	lda xix, (xsp + 2)
	st_dri3b W, 0xE1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

LABEL_F3CDC5:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F3CDC5
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, LABEL_F3CDE3
	lds wa, 6
	call SeqData_SetErrorCode
	jr LABEL_F3CE1C

LABEL_F3CDE3:
	ldada xix, 9016
	ld e, l
	extz de
	lda xbc, (xsp + 2)
	cp_srib_im 0xF1, 0x8A, 0x00, 0x81
	jr nz, LABEL_F3CDFB
	ldw wa, 0x12
	jr LABEL_F3CE05

LABEL_F3CDFB:
	cpdi8 7522, 1
	jr z, LABEL_F3CE44
	ldw wa, 0x12

LABEL_F3CE05:
	calr ToneVoice_AssignChannel

LABEL_F3CE08:
	ldw wa, 0x13
	lds bc, 0
	calr SeqPart_ReadEventStream

LABEL_F3CE10:
	ldada xwa, 9016
	cp_srib_im 0xE1, 0x8A, 0x00, 0x82
	jr nz, LABEL_F3CDB5

LABEL_F3CE1C:
	lda xbc, (xsp + 2)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	popw iz
	inc 8, xsp
	ret

LABEL_F3CE2E:
	cp wa, hl
	jr nz, LABEL_F3CE3F
	ld_srib A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, LABEL_F3CE08

LABEL_F3CE3F:
	ldw wa, 0x12
	jr LABEL_F3CE05

LABEL_F3CE44:
	ldda16 xwa, 7524
	ld_sriw HL, (xix + 0x0088)
	cp wa, hl
	jr ule, LABEL_F3CE2E
	jr LABEL_F3CE08

LABEL_F3CE53:
	lda xsp, (xsp - 32)
	pushw iz
	ldda16 xwa, 8998
	cpda16 xwa, 9152
	jrl nc, LABEL_F3CEED
	ld (xsp + 26), 0x81
	ldw (xsp + 16), 0x0
	jr LABEL_F3CE7B

LABEL_F3CE6D:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	incm 1, (xsp + 16)

LABEL_F3CE7B:
	ldda16 xwa, 9152
	subda16 xwa, 8998
	cp (xsp + 16), wa
	jr c, LABEL_F3CE6D
	jr LABEL_F3CEED

LABEL_F3CE8A:
	lda xix, (xsp + 26)
	st_dri3b W, 0xE1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

LABEL_F3CE9A:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F3CE9A
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, LABEL_F3CEB9
	ldw wa, 0x1A
	call SeqData_SetErrorCode
	jr LABEL_F3CEF9

LABEL_F3CEB9:
	ldada xix, 9016
	cp_srib_im 0xF1, 0x8A, 0x00, 0x81
	jr nz, LABEL_F3CED1
	lda xbc, (xsp + 26)
	extz hl
	ldw wa, 0x12
	ld de, hl
	jr LABEL_F3CEE2

LABEL_F3CED1:
	extz hl
	cpdi8 7522, 1
	jr z, LABEL_F3CF2C
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, hl

LABEL_F3CEE2:
	calr ToneVoice_AssignChannel

LABEL_F3CEE5:
	ldw wa, 0x13
	lds bc, 0
	calr SeqPart_ReadEventStream

LABEL_F3CEED:
	ldada xwa, 9016
	cp_srib_im 0xE1, 0x8A, 0x00, 0x82
	jr nz, LABEL_F3CE8A

LABEL_F3CEF9:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel
	cpdi8 7522, 0
	jr nz, LABEL_F3CF3B
	jrl SeqPlay_RestoreReturn

LABEL_F3CF11:
	cp wa, bc
	jr nz, LABEL_F3CF22
	ld_srib A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, LABEL_F3CEE5

LABEL_F3CF22:
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	ld de, hl
	jr LABEL_F3CEE2

LABEL_F3CF2C:
	ldda16 xwa, 7524
	ld_sriw BC, (xix + 0x0088)
	cp wa, bc
	jr ule, LABEL_F3CF11
	jr LABEL_F3CEE5

LABEL_F3CF3B:
	ldada xde, 9016
	ldda16 xwa, 7524
	ld_sriw BC, (xde + 0x0088)
	cp wa, bc
	jrl c, SeqPlay_RestoreReturn
	cp wa, bc
	jr nz, LABEL_F3CF5F
	ld_srib A, (xde + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jrl c, SeqPlay_RestoreReturn

LABEL_F3CF5F:
	lda xwa, (xsp + 18)
	ld (xsp + 2), xwa
	ldada xix, 9332
	st_dri3b B, 0xF1, 0x80, 0x00
	ld xwa, (xsp + 2)
	ld bc, (xde)
	st_dpiw BC, 0xE1
	ld (xsp + 6), xwa
	lda xbc, (xde + 2)
	ld hl, (xbc)
	ld xwa, (xsp + 6)
	ld (xwa), hl
	lda xhl, (xsp + 22)
	st_dri3b W, 0xF1, 0x88, 0x00
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
	st_dri3b W, 0xF1, 0x90, 0x00
	ld (xwa), de
	ld (xwa + 2), bc
	ld ix, (xhl)
	ld de, (xiy)
	ldada xbc, 9184
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
	jr LABEL_F3D054

LABEL_F3CFF8:
	lda xix, (xsp + 26)
	st_dri3b W, 0xE1, 0x88, 0x00
	ld xbc, xix
	lda xde, (xwa + 2)
	lda xhl, (xix + 6)

LABEL_F3D008:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F3D008
	ld a, (xix)
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, LABEL_F3D027
	ldw wa, 0x1B
	call SeqData_SetErrorCode
	jr LABEL_F3D063

LABEL_F3D027:
	ldada xix, 9016
	ld e, l
	extz de
	cp_srib_im 0xF1, 0x8A, 0x00, 0x81
	jr nz, LABEL_F3D03F
	lda xbc, (xsp + 26)
	ldw wa, 0x12
	jr LABEL_F3D04C

LABEL_F3D03F:
	lda xbc, (xsp + 26)
	cpdi8 7522, 1
	jr z, LABEL_F3D08C
	ldw wa, 0x12

LABEL_F3D04C:
	calr ToneVoice_AssignChannel

LABEL_F3D04F:
	ldw wa, 0x13
	lds bc, 0

LABEL_F3D054:
	calr SeqPart_ReadEventStream
	ldada xwa, 9016
	cp_srib_im 0xE1, 0x8A, 0x00, 0x82
	jr nz, LABEL_F3CFF8

LABEL_F3D063:
	lda xbc, (xsp + 26)
	ld (xbc), 0x82
	ldw wa, 0x12
	lds de, 1
	calr ToneVoice_AssignChannel

SeqPlay_RestoreReturn:
	popw iz
	lda xsp, (xsp + 32)
	ret

LABEL_F3D076:
	cp wa, hl
	jr nz, LABEL_F3D087
	ld_srib A, (xix + 0x008b)
	extz wa
	cpdm16 7526, xwa
	jr nc, LABEL_F3D04F

LABEL_F3D087:
	ldw wa, 0x12
	jr LABEL_F3D04C

LABEL_F3D08C:
	ldda16 xwa, 7524
	ld_sriw HL, (xix + 0x0088)
	cp wa, hl
	jr ule, LABEL_F3D076
	jr LABEL_F3D04F

LABEL_F3D09B:
	dec 8, xsp
	pushw iz
	ld (xsp + 6), xwa
	ld xwa, (xsp + 6)
	ldw (xwa), 0x0
	lds iz, 0
	lda xde, (xsp + 2)
	ldada xbc, 9468
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld de, (xde)
	ldada xbc, 9252
	ld (xbc), de
	ld (xbc + 2), wa

SeqCh_LoadProcessEvent:
	ldw wa, 0x12
	call SeqCh_LoadChannelConfig
	ldda8 a, 9154
	cp a, 0x82
	jr z, LABEL_F3D0FB
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr ge, LABEL_F3D0E8
	lds wa, 7
	call SeqData_SetErrorCode
	jr SeqCh_LoadProcessEvent

LABEL_F3D0E8:
	add iz, hl
	cp iz, 0xFB
	jr c, SeqCh_LoadProcessEvent
	sub iz, 0xFB
	ld xwa, (xsp + 6)
	incm 1, (xwa)
	jr SeqCh_LoadProcessEvent

LABEL_F3D0FB:
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
	jr nz, LABEL_F3D129
	cpw (xsp + 16), 0x0
	jrl z, LABEL_F3D257

LABEL_F3D129:
	lda xbc, (xsp + 4)
	ldada xde, 10284
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
	jr ule, LABEL_F3D193

LABEL_F3D170:
	ld wa, (xsp + 8)
	call Part_LinkVoiceToChain
	cp hl, 0xFFFF
	jr nz, LABEL_F3D189
	ldw wa, 0x66
	call SeqData_SetErrorCode
	ld wa, (xsp + 12)
	jr LABEL_F3D1B8

LABEL_F3D189:
	ld (xsp + 8), hl
	inc 1, iz
	cp iz, (xsp + 18)
	jr c, LABEL_F3D170

LABEL_F3D193:
	ld iz, (xsp + 14)
	add iz, (xsp + 16)
	lda xbc, (xsp + 8)
	cp iz, 0x100
	jr c, LABEL_F3D1D3
	ld wa, (xbc)
	call Part_LinkVoiceToChain
	cp hl, 0xFFFF
	jr nz, LABEL_F3D1C1
	ldw wa, 0x67
	call SeqData_SetErrorCode
	ld wa, (xsp + 12)

LABEL_F3D1B8:
	calr LABEL_F3D25E
	ldw hl, 0xFFFF
	jrl LABEL_F3D259

LABEL_F3D1C1:
	lda xbc, (xsp + 8)
	ld (xbc), hl
	ld wa, iz
	sub wa, 0xFB
	extz wa
	ld (xbc + 2), wa
	jr LABEL_F3D1DB

LABEL_F3D1D3:
	ldto_berp A, 0xF8
	extz wa
	ld (xbc + 2), wa

LABEL_F3D1DB:
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

LABEL_F3D1FB:
	lda xbc, (xsp + 12)
	lda xde, (xsp + 4)
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, LABEL_F3D224
	ld wa, (xde + 2)
	cp wa, (xbc + 2)
	jr nz, LABEL_F3D224
	ldada xhl, 10284
	lda xde, (xsp + 8)
	ld wa, (xde)
	ld (xhl), wa
	ld wa, (xde + 2)
	ld (xhl + 2), wa
	ld (xsp + 2), 0x1

LABEL_F3D224:
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
	jr z, LABEL_F3D1FB

LABEL_F3D257:
	lds hl, 0

LABEL_F3D259:
	popw iz
	lda xsp, (xsp + 20)
	ret

LABEL_F3D25E:
	push xiz
	ld iz, wa
	ld wa, iz
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LABEL_F3D2A4
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LABEL_F3D2A4

LABEL_F3D281:
	ldto_werp IZ, 0xFA
	ldto_werp WA, 0xFA
	lds bc, 0
	call PartCtrl_SetClearBit7
	ldto_werp WA, 0xFA
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ld wa, iz
	call PartCtrl_AppendToFreeList
	cp_erpw 0xFA, 0xFF, 0xFF
	jr nz, LABEL_F3D281

LABEL_F3D2A4:
	pop xiz
	ret

LABEL_F3D2A6:
	lda xsp, (xsp - 28)
	push xiz
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call Audio_CheckSubsystemReady
	cpdi16 10408, 0
	jrl z, LABEL_F3D53E
	calr LABEL_F3CE53
	call LABEL_F41DB9
	cpdi8 7522, 1
	call_24 z, 0xF3D840
	call LABEL_F3E91B
	lda xwa, (xsp + 20)
	calr LABEL_F3D09B
	lda xde, (xsp + 20)
	cpw (xde), 0x0
	jr nz, LABEL_F3D2FA
	cpw (xde + 2), 0x0
	jrl z, LABEL_F3D52E

LABEL_F3D2FA:
	ldmi16 (xsp + 4), 0x231A
	ld a, (xsp + 4)
	extz wa
	ld (xsp + 6), wa
	lda xhl, (xsp + 16)
	ld wa, (xsp + 6)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xiz, 9332
	st_dri3b A, 0x07, 0xF8, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	lda xix, (xhl + 2)
	ld wa, (xbc + 2)
	ld (xix), wa
	lda xiy, (xsp + 12)
	st_dri3b A, 0xF9, 0x88, 0x00
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
	ldada xhl, 10284
	ld wa, (xiy)
	ld (xhl), wa
	ld wa, (xbc)
	ld (xhl + 2), wa
	ld bc, (xde)
	ld de, (xde + 2)
	ld wa, (xsp + 6)
	calr PartCtrl_SwapIndexedEntries
	lda xbc, (xsp + 8)
	ldada xde, 10284
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
	ldada xde, 9184
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
	ldada xwa, 9016
	stiw_dri 0xE1, 0x80, 0x00, 0x00, 0x00
	stiw_dri 0xE1, 0x88, 0x00, 0x00, 0x00
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	ldw wa, 0x12
	lds bc, 0

LABEL_F3D3ED:
	calr SeqPart_ReadEventStream

SeqPlay_CheckEventTiming:
	ldada xix, 9016
	st_dri3b C, 0xF1, 0x80, 0x00
	ld_sriw WA, (xix + 0x0088)
	ld de, (xhl)
	lda xbc, (xsp + 24)
	cp de, wa
	jr c, LABEL_F3D417
	cp wa, de
	jr nz, SeqPlay_ProcessPendingChannels
	ld_srib A, (xix + 0x0083)
	cp_srib_rm A, 0xF1, 0x8B, 0x00
	jr nc, SeqPlay_ProcessPendingChannels

LABEL_F3D417:
	ld xde, xbc
	ld xiy, xbc
	ldi_berp 0xE2, 0

LABEL_F3D41E:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b A, 0xF1, 0x80, 0x00
	ld iz, wa
	extz xiz
	add xiz, xbc
	ldto_berp C, 0xE2
	extz bc
	ld a, (xiz)
	lda_dri3 XBC, 0x07, 0xF4, 0xE4
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3D41E
	ld a, (xde)
	cp a, 0x82
	jr nz, LABEL_F3D451
	ldw (xhl), 0xFFF0
	jr SeqPlay_CheckEventTiming

LABEL_F3D451:
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr le, LABEL_F3D46C
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 24)
	extz hl
	ld de, hl
	calr ToneVoice_AssignChannel
	jr LABEL_F3D473

LABEL_F3D46C:
	ldw wa, 0xA
	call SeqData_SetErrorCode

LABEL_F3D473:
	ldw wa, 0x11
	call SeqCh_LoadChannelConfig
	jrl SeqPlay_CheckEventTiming

SeqPlay_ProcessPendingChannels:
	ld xde, xbc
	ld xiy, xbc
	ldi_berp 0xE2, 0

LABEL_F3D484:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b A, 0xF1, 0x88, 0x00
	ld iz, wa
	extz xiz
	add xiz, xbc
	ldto_berp C, 0xE2
	extz bc
	ld a, (xiz)
	lda_dri3 XBC, 0x07, 0xF4, 0xE4
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F3D484
	ld a, (xde)
	cp a, 0x82
	jrl nz, LABEL_F3D547
	cpw (xhl), 0xFFF0
	jr nz, LABEL_F3D502
	ld c, (xsp + 4)
	extz bc
	lda xhl, (xsp + 20)
	ld a, c
	dec 1, a
	extz wa
	sla wa, 2
	ldada xde, 9184
	st_dri3b B, 0x07, 0xE8, 0xE0
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

LABEL_F3D502:
	ld (xsp + 4), 0x1

LABEL_F3D506:
	ld a, (xsp + 4)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D514
	slaa bc

LABEL_F3D514:
	andda16 xbc, 10408
	jr z, LABEL_F3D525
	ld a, (xsp + 4)
	extz wa
	lds bc, 1
	call Chan_SetActiveBit

LABEL_F3D525:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr ule, LABEL_F3D506

LABEL_F3D52E:
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	stdi16 10410, 0

LABEL_F3D53E:
	call Part_DeallocVoices1And2
	pop xiz
	lda xsp, (xsp + 28)
	ret

LABEL_F3D547:
	extz wa
	call SeqEvent_GetParamLength
	cps hl, 0
	jr le, LABEL_F3D562
	ld a, (xsp + 4)
	extz wa
	lda xbc, (xsp + 24)
	extz hl
	ld de, hl
	calr ToneVoice_AssignChannel
	jr LABEL_F3D569

LABEL_F3D562:
	ldw wa, 0xB
	call SeqData_SetErrorCode

LABEL_F3D569:
	ldw wa, 0x12
	lds bc, 0
	jrl LABEL_F3D3ED

SeqData_ValidateProcess:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 6), e
	ld (xsp + 8), bc
	ld (xsp + 10), a
	ldda8 a, 8182
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0xFF
	jrl z, LABEL_F3D618

LABEL_F3D58E:
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0xC
	ldada xbc, 8186
	st_dri3b C, 0x07, 0xE4, 0xE0
	ld a, (xhl + 9)
	ld c, a
	extz bc
	cp (xsp + 10), 0x32
	jr z, LABEL_F3D5B8
	inc 1, bc
	ld a, (xsp + 10)
	extz wa
	cp wa, bc
	jr nz, LABEL_F3D5F3

LABEL_F3D5B8:
	ld ix, (xsp + 8)
	ld a, (xsp + 6)
	ld c, (xhl + 1)
	cp c, a
	jr ule, LABEL_F3D5CA
	dec 1, ix
	add a, 0x60

LABEL_F3D5CA:
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
	jr LABEL_F3D5FA

LABEL_F3D5F3:
	ldw wa, 0x9
	call SeqData_SetErrorCode

LABEL_F3D5FA:
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0xC
	ld bc, wa
	ldada xwa, 8197
	ld_srib3 A, 0x07, 0xE0, 0xE4
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0xFF
	jrl nz, LABEL_F3D58E

LABEL_F3D618:
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_F3D61F:
	dec 8, xsp
	push_werp 0xFA
	lds wa, 0
	ldw bc, 0xE
	call Part_FindVoiceByByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0xFF
	jr z, Part_FindAndAssignDrumVoice
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D644
	slaa bc

LABEL_F3D644:
	andda16 xbc, 10410
	jr z, Part_FindAndAssignDrumVoice
	lda xwa, (xsp + 2)
	ld (xwa), 0xB0
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x48
	ld (xwa + 3), 0x3
	ldda8 c, 64605
	ld (xwa + 4), c
	ld (xwa + 5), 0x7
	calr Part_CheckAndSetModifiedFlags
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 2)
	lds de, 6
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xFB
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_FindAndAssignDrumVoice:
	lds wa, 0
	ldw bc, 0xF
	call Part_FindVoiceByByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0xFF
	jr z, Part_SendVoiceStatusLoop
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D6A0
	slaa bc

LABEL_F3D6A0:
	andda16 xbc, 10410
	jr z, Part_SendVoiceStatusLoop
	lda xbc, (xsp + 2)
	ld (xbc), 0xD3
	ld (xbc + 1), 0x0
	lda xde, (xbc + 2)
	ldda8 a, 36580
	ld (xde), a
	res 7, a
	ld (xde), a
	ldto_berp A, 0xFB
	extz wa
	lds de, 3
	calr ToneVoice_AssignChannel
	lda xbc, (xsp + 2)
	ld (xbc), 0x80
	ld (xbc + 1), 0x0
	ldada xwa, 64602
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
	jr z, LABEL_F3D6FA
	inc 1, a
	ld (xhl), a

LABEL_F3D6FA:
	ldto_berp A, 0xFB
	extz wa
	lds de, 4
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xFB
	extz wa
	call SeqEvent_CreateWithChannelValidation

Part_SendVoiceStatusLoop:
	ldi_berp 0xFB, 1

LABEL_F3D710:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D71E
	slaa bc

LABEL_F3D71E:
	andda16 xbc, 10408
	jr z, LABEL_F3D773
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	call Part_ReadVoiceByte
	cps l, 1
	jr z, Part_BuildAndSendVoiceCCEvent
	cps l, 0
	jr z, Part_BuildAndSendVoiceCCEvent
	cps l, 2
	jr nz, LABEL_F3D773

Part_BuildAndSendVoiceCCEvent:
	lda xwa, (xsp + 2)
	ld (xwa), 0xB0
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x9A
	ldto_berp C, 0xFB
	inc 3, c
	ld (xwa + 3), c
	ldmi16 (xwa + 4), 0xC5A8
	ld (xwa + 5), 0x7F
	calr Part_CheckAndSetModifiedFlags
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 2)
	lds de, 6
	calr ToneVoice_AssignChannel
	ldto_berp A, 0xFB
	extz wa
	call SeqEvent_CreateWithChannelValidation

LABEL_F3D773:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F3D710
	pop_werp 0xFA
	inc 8, xsp
	ret

SeqPlay_ActivateAllChannels:
	push_werp 0xFA
	ldi_berp 0xFB, 1

LABEL_F3D788:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D796
	slaa bc

LABEL_F3D796:
	andda16 xbc, 10408
	jr z, LABEL_F3D7A7
	ldto_berp A, 0xFB
	extz wa
	lds bc, 1
	call Chan_SetActiveBit

LABEL_F3D7A7:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F3D788
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	stdi16 10410, 0
	ldw wa, 0x32
	call SeqBuf_WriteNoteOffEntry
	call NoteMap_SendAllNotesOff
	call AudioInit_RefreshToneBank
	call VoiceAlloc_ProcessAll
	call BitMapOut_PrepareAndDisplay
	call Audio_CheckSubsystemReady
	pop_werp 0xFA
	ret

LABEL_F3D7DF:
	cpdi8 7570, 1
	jr nz, LABEL_F3D809
	cpdi16 10408, 0
	jr z, LABEL_F3D809
	ldda8 a, 8986
	bitda 2, 1057
	jr nz, SeqPlay_StartPlayback
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3D803
	slaa bc

LABEL_F3D803:
	andda16 xbc, 8982
	jr nz, SeqPlay_StartPlayback

LABEL_F3D809:
	ldw hl, 0xFFFF
	ret

SeqPlay_StartPlayback:
	call SeqBuffer_ClearAndInitIteration
	bitda 2, 1057
	jr nz, LABEL_F3D822
	calr LABEL_F3D840
	stdi8 7522, 0
	calr SeqPlay_InitializePlayback

LABEL_F3D822:
	stdi8 7522, 1
	ldda16 xwa, 1052
	addda16 xwa, 7544
	stda16 7524, xwa
	ldda8 a, 1051
	extz wa
	stda16 7526, xwa
	lds hl, 0
	ret

LABEL_F3D840:
	lda xsp, (xsp - 20)
	push xiz
	lds iz, 0
	ldda8 a, 8986
	ldfr_berp A, 0xFB
	extz wa
	lda xhl, (xsp + 12)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9332
	st_dri3b A, 0x07, 0xE4, 0xE0
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

LABEL_F3D88E:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 16)
	call SeqPart_ReadNextEventByte
	lda xbc, (xsp + 16)
	ld a, (xbc)
	cp a, 0x81
	jr nz, LABEL_F3D8AF
	lda xwa, (xsp + 4)
	lds de, 1
	call Part_CopyBytesToVoiceBlock
	inc 1, iz
	jr LABEL_F3D8B4

LABEL_F3D8AF:
	cp a, 0x82
	jr z, SeqPlay_StoreChannelPosition

LABEL_F3D8B4:
	cpda16 xiz, 7544
	jr c, LABEL_F3D88E

SeqPlay_StoreChannelPosition:
	ldto_berp C, 0xFB
	extz bc
	lda xde, (xsp + 4)
	ld a, c
	ld iy, (xde)
	ld ix, (xde + 2)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xhl, 9184
	exts xwa
	add xwa, xhl
	ld (xwa), iy
	ld (xwa + 2), ix
	ld a, (xsp + 16)
	cp a, 0x82
	jr z, LABEL_F3D8EA
	cp a, 0x84
	jr nz, LABEL_F3D91F

LABEL_F3D8EA:
	ld de, (xde)
	lds wa, 0
	call Part_WriteWord_Indexed
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 6)
	lds wa, 0
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	lds de, 1
	jr LABEL_F3D952

LABEL_F3D90A:
	lda xwa, (xsp + 8)
	call SeqPart_ReadNextEventByte
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	extz hl
	ld de, hl
	call Part_CopyBytesToVoiceBlock

LABEL_F3D91F:
	lda xbc, (xsp + 16)
	ld a, (xbc)
	cp a, 0x82
	jr z, LABEL_F3D92E
	cp a, 0x84
	jr nz, LABEL_F3D90A

LABEL_F3D92E:
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 4)
	lds wa, 0
	call Part_WriteWord_Indexed
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 6)
	lds wa, 0
	call Part_WriteByte_Indexed
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 16)
	lds de, 1

LABEL_F3D952:
	call Part_CopyBytesToVoiceBlock
	ld wa, (xsp + 4)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F3D973
	call Part_StealAndReallocVoices
	ld wa, (xsp + 4)
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord

LABEL_F3D973:
	pop xiz
	lda xsp, (xsp + 20)
	ret

Part_CheckAndSetModifiedFlags:
	lda xde, (xwa + 2)
	ld c, (xde)
	bit 7, c
	jr z, LABEL_F3D989
	res 7, c
	ld (xde), c
	setm 2, (xwa)

LABEL_F3D989:
	lda xde, (xwa + 4)
	ld c, (xde)
	bit 7, c
	jr z, LABEL_F3D99A
	res 7, c
	ld (xde), c
	setm 0, (xwa)

LABEL_F3D99A:
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
	and a, 0xF0
	cp a, 0x90
	jr nz, LABEL_F3D9E9
	cpdi8 7558, 0
	call_24 nz, 0xF3DA8E
	call SeqBuf_GetWritePos
	cp hl, 0xF
	call_24 lt, 0xF3DA7C
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	stdi8 7556, 1
	jr LABEL_F3DA12

LABEL_F3D9E9:
	cpdi8 7556, 0
	call_24 nz, 0xF3DA7C
	call SeqBuf_GetWritePos
	cp hl, 0xF
	call_24 lt, 0xF3DA8E
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	stdi8 7558, 1

LABEL_F3DA12:
	pop xiz
	inc 2, xsp
	ret

LABEL_F3DA16:
	dec 2, xsp
	push xiz
	ld (xsp + 4), c
	ld xiz, xwa
	ld a, (xiz)
	and a, 0xF0
	cp a, 0x90
	jr nz, LABEL_F3DA51
	cpdi8 7558, 0
	call_24 nz, 0xF3DA8E
	call SeqBuf_GetWritePos
	cp hl, 0xF
	call_24 lt, 0xF3DA7C
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_NoteEvents
	jr LABEL_F3DA78

LABEL_F3DA51:
	cpdi8 7556, 0
	call_24 nz, 0xF3DA7C
	call SeqBuf_GetWritePos
	cp hl, 0xF
	call_24 lt, 0xF3DA8E
	push xiz
	ld a, (xsp + 8)
	extz wa
	pushw wa
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_VoiceCCEvents

LABEL_F3DA78:
	pop xiz
	inc 2, xsp
	ret

SeqBuf_FlushAndReinit_NoteEvents:
	call SeqBuf_SaveWritePos
	call LABEL_FE09C4
	call SeqBuf_Init
	stdi8 7556, 0
	ret

SeqBuf_FlushAndReinit_VoiceCCEvents:
	call SeqBuf_SaveWritePos
	call LABEL_FCAD39
	call SeqBuf_Init
	call SwbtWr_ReinitBothBanks
	stdi8 7558, 0
	ret

LABEL_F3DAA4:
	ei 6
	setda 1, 1056
	setda 2, 1056
	ldda8 a, 1054
	bit 0, a
	jr z, LABEL_F3DAC1
	set 1, a
	set 2, a
	stda8 1054, a

LABEL_F3DAC1:
	ldda8 a, 1057
	bit 0, a
	jr z, LABEL_F3DAD4
	set 1, a
	set 2, a
	stda8 1057, a

LABEL_F3DAD4:
	ei 0
	ret

LABEL_F3DAD7:
	dec 6, xsp
	push_werp 0xFA
	cpdi16 61854, 0
	jr z, LABEL_F3DB3F
	ldi_berp 0xFB, 1

LABEL_F3DAE7:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3DAF5
	slaa bc

LABEL_F3DAF5:
	ldda16 xwa, 61854
	and wa, bc
	jr z, SeqBuf_IncrAndLoop16
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	calr Part_ReadVoiceByte
	cp l, 0xF
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0x10
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0xD
	jr z, SeqBuf_IncrAndLoop16
	cp l, 0xE
	jr z, SeqBuf_IncrAndLoop16
	lda xwa, (xsp + 2)
	ld (xwa), 0xD3
	ld (xwa + 1), 0x0
	ld (xwa + 2), 0x7F
	ldto_berp C, 0xFB
	dec 1, c
	ld (xwa + 3), c
	lds bc, 4
	calr SeqBuf_WriteMidiEvent

SeqBuf_IncrAndLoop16:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F3DAE7

LABEL_F3DB3F:
	pop_werp 0xFA
	inc 6, xsp
	ret

LABEL_F3DB45:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 4), 0x0

LABEL_F3DB4D:
	lds bc, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F3DB59
	slaa bc

LABEL_F3DB59:
	andda16 xbc, 3407
	jr z, LABEL_F3DB7F
	ld a, (xsp + 4)
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xD
	jr z, LABEL_F3DB88
	ldda8 a, 3431
	cps a, 4
	call_24 nz, 0xF3DA7C
	jrl LABEL_F3DCEA

LABEL_F3DB7F:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr c, LABEL_F3DB4D

LABEL_F3DB88:
	ld (xsp + 14), 0x0

LABEL_F3DB8C:
	call SeqBuf_ReadByte
	cps hl, 0
	jr ge, LABEL_F3DBAC

LABEL_F3DB94:
	lda xbc, (xsp + 14)
	cp (xbc), 0x0
	jrl z, LABEL_F3DC65
	ld (xsp + 4), 0x0
	ld (xsp + 10), xbc
	ld (xsp + 6), xbc
	lds hl, 0
	jrl LABEL_F3DC59

LABEL_F3DBAC:
	ld (xsp + 30), l
	ld (xsp + 4), 0x1

LABEL_F3DBB3:
	call SeqBuf_ReadByte
	lda xbc, (xsp + 30)
	cps hl, 0
	jr lt, LABEL_F3DBD1
	ld a, (xsp + 4)
	extz wa
	lda_dri3 XSP, 0x07, 0xE4, 0xE0
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x5
	jr c, LABEL_F3DBB3

LABEL_F3DBD1:
	ld (xsp + 10), xbc
	inc 1, xbc
	cp (xbc), 0x7F
	jr z, LABEL_F3DBF1
	lda xde, (xsp + 14)
	ld l, (xde)
	extz hl
	inc 1, hl
	ld xwa, (xsp + 10)
	ld a, (xwa + 2)
	lda_dri3 XBC, 0x07, 0xE8, 0xEC
	incm8 1, (xde)

LABEL_F3DBF1:
	ld c, (xbc)
	cp c, 0x7F
	jr z, SeqPlay_HandleEndOfData
	ld xwa, (xsp + 10)
	cp (xwa + 3), 0x0
	jr nz, SeqPlay_HandleEndOfData
	ld (xsp + 14), 0x0
	call SeqBuf_Init
	jr LABEL_F3DB94

SeqPlay_HandleEndOfData:
	cp c, 0x7F
	jrl nz, LABEL_F3DB8C
	calr BitMapOut_PrepareAndDisplay
	call SeqBuf_Init
	jrl LABEL_F3DCEA

LABEL_F3DC1B:
	ld d, (xsp + 4)
	inc 1, d
	ld wa, hl
	inc 1, wa
	st_dri3b E, 0x07, 0xE4, 0xE0
	ldfr_berp D, 0xF0
	extz ix
	jr LABEL_F3DC49

LABEL_F3DC30:
	ld wa, ix
	inc 1, wa
	st_dri3b H, 0x07, 0xE4, 0xE0
	ld a, (xiz)
	ld e, (xiy)
	cp e, a
	jr nc, LABEL_F3DC45
	ld (xiy), a
	ld (xiz), e

LABEL_F3DC45:
	inc 1, d
	inc 1, ix

LABEL_F3DC49:
	ld xwa, (xsp + 6)
	ld a, (xwa)
	dec 1, a
	cp d, a
	jr ule, LABEL_F3DC30
	incm8 1, (xsp + 4)
	inc 1, hl

LABEL_F3DC59:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	dec 1, a
	cp (xsp + 4), a
	jr c, LABEL_F3DC1B

LABEL_F3DC65:
	lda xwa, (xsp + 26)
	lds de, 2
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 26)
	mrib4 0x80, 0x19, 0xDF, 0xCE
	mrdb5 0x88, 0x01, 0x19, 0xE0, 0xCE
	mrdb5 0x88, 0x02, 0x19, 0xE1, 0xCE
	mrdb5 0x88, 0x03, 0x19, 0xDE, 0xCE
	ldda8 a, 3431
	cps a, 4
	jr z, LABEL_F3DCD0
	ldada xix, 52965
	lda xhl, (xsp + 14)
	ld a, (xhl)
	ld (xix), a
	ld (xsp + 4), 0x0
	ld xiy, xhl
	lds de, 1
	ld a, (xsp + 4)
	cp a, (xiy)
	jr nc, LABEL_F3DCC8

LABEL_F3DCA6:
	ld wa, de
	ldw bc, 0xFFFF
	add wa, bc
	inc 1, wa
	ld bc, de
	extz xbc
	add xbc, xix
	ld_srib3 A, 0x07, 0xEC, 0xE0
	ld (xbc), a
	incm8 1, (xsp + 4)
	inc 1, de
	ld a, (xsp + 4)
	cp a, (xiy)
	jr c, LABEL_F3DCA6

LABEL_F3DCC8:
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch

LABEL_F3DCD0:
	lda xwa, (xsp + 26)
	mrib4 0x80, 0x19, 0x42, 0x8D
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8D
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8D
	mrdb5 0x88, 0x03, 0x19, 0xDE, 0xCE
	call BitMapOut_CheckDiskAndApply

LABEL_F3DCEA:
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
	ldmi16 (xsp + 4), 0x231C
	cp (xsp + 4), 0xFF
	jrl z, BitMapOut_CompletionJoin
	cp (xsp + 44), 0x0
	jr nz, LABEL_F3DD1E
	ld (xsp + 4), 0x14

LABEL_F3DD1E:
	ld a, (xsp + 4)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9016
	exts xwa
	add xwa, xbc
	ld (xsp + 8), xwa
	cp (xwa + 2), 0x90
	jr z, LABEL_F3DD3E
	ldb l, 0xFF
	jrl LABEL_F3DF77

LABEL_F3DD3E:
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
	lda_dri3 XBC, 0x07, 0xE4, 0xE8
	incm8 1, (xbc)
	ld a, (xsp + 4)
	extz wa
	lda xde, (xsp + 16)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	cp (xsp + 44), 0x0
	jr nz, VoiceAlloc_ReadNextNoteEvent
	ldada xhl, 7574
	ld wa, (xix)
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld xwa, (xsp + 12)
	ld c, (xwa)
	ld (xde), c
	add c, (xix + 6)
	ld (xde), c
	cp c, 0x60
	jr c, LABEL_F3DDAF
	incm 1, (xhl)
	ld a, (xde)
	sub a, 0x60
	ld (xde), a

LABEL_F3DDAF:
	ld xwa, (xsp + 8)
	ld a, (xwa + 7)
	extz wa
	add (xhl), wa
	ldada xix, 7578
	ld wa, (xhl)
	ld (xix), wa
	lda xbc, (xix + 2)
	ld a, (xde)
	ld (xbc), a
	cp a, 0x1A
	jr nc, LABEL_F3DDD6
	decm 1, (xix)
	ld a, (xbc)
	add a, 0x60
	ld (xbc), a

LABEL_F3DDD6:
	submi8 (xbc), 0x1A

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
	lda_dri3 XBC, 0x07, 0xE4, 0xEC
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
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE8
	ld wa, (xsp + 12)
	ld (xbc), wa
	ld wa, (xsp + 14)
	ld (xbc + 2), wa
	jr VoiceAlloc_ReadNextNoteEvent

VoiceAlloc_ValidateNoteCount:
	cp (xbc), 0xA
	jr ule, LABEL_F3DE42
	ldw wa, 0x12
	calr SeqData_SetErrorCode

LABEL_F3DE42:
	ldb l, 0x0
	lda xbc, (xsp + 28)
	ld (xsp + 10), xbc
	ld (xsp + 6), xbc
	ldw (xsp + 14), 0x0
	jr LABEL_F3DE92

LABEL_F3DE54:
	ld d, l
	inc 1, d
	ld wa, (xsp + 14)
	inc 1, wa
	st_dri3b E, 0x07, 0xE4, 0xE0
	ldfr_berp D, 0xF0
	extz ix
	jr LABEL_F3DE82

LABEL_F3DE69:
	ld wa, ix
	inc 1, wa
	st_dri3b H, 0x07, 0xE4, 0xE0
	ld a, (xiz)
	ld e, (xiy)
	cp e, a
	jr nc, LABEL_F3DE7E
	ld (xiy), a
	ld (xiz), e

LABEL_F3DE7E:
	inc 1, d
	inc 1, ix

LABEL_F3DE82:
	ld xwa, (xsp + 6)
	ld a, (xwa)
	dec 1, a
	cp d, a
	jr ule, LABEL_F3DE69
	inc 1, l
	incm 1, (xsp + 14)

LABEL_F3DE92:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	dec 1, a
	cp l, a
	jr c, LABEL_F3DE54
	lda xwa, (xsp + 40)
	lds de, 2
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 40)
	cp (xsp + 44), 0x0
	jr z, LABEL_F3DEFB
	ld xde, xwa
	ldda8 c, 52959
	cp c, (xwa)
	jr nz, BitMapOut_WriteAltIdx
	ldda8 a, 52960
	cp a, (xde + 1)
	jr nz, BitMapOut_WriteAltIdx
	ldda8 a, 52961
	cp a, (xde + 2)
	jr nz, BitMapOut_WriteAltIdx
	ldda8 a, 52958
	cp a, (xde + 3)
	jrl z, BitMapOut_CompletionJoin

BitMapOut_WriteAltIdx:
	mrib4 0x82, 0x19, 0xDF, 0xCE
	mrdb5 0x8A, 0x01, 0x19, 0xE0, 0xCE
	mrdb5 0x8A, 0x02, 0x19, 0xE1, 0xCE
	mrdb5 0x8A, 0x03, 0x19, 0xDE, 0xCE
	ldada xiy, 52965
	lda xix, (xsp + 28)
	ld a, (xix)
	ld (xiy), a
	ldb l, 0x0
	ld xiz, xix
	lds de, 1
	jr LABEL_F3DF4F

LABEL_F3DEFB:
	ld xde, xwa
	ldda8 c, 8960
	cp c, (xwa)
	jr nz, BitMapOut_WriteMultiIdx
	ldda8 a, 8962
	cp a, (xde + 1)
	jr nz, BitMapOut_WriteMultiIdx
	ldda8 a, 8964
	cp a, (xde + 2)
	jr nz, BitMapOut_WriteMultiIdx
	ldda8 a, 8966
	cp a, (xde + 3)
	jr z, BitMapOut_CompletionJoin

BitMapOut_WriteMultiIdx:
	mrib4 0x82, 0x19, 0x00, 0x23
	mrdb5 0x8A, 0x01, 0x19, 0x02, 0x23
	mrdb5 0x8A, 0x02, 0x19, 0x04, 0x23
	mrdb5 0x8A, 0x03, 0x19, 0x06, 0x23
	jr BitMapOut_CompletionJoin

LABEL_F3DF35:
	ld wa, de
	ldw bc, 0xFFFF
	add wa, bc
	inc 1, wa
	ld bc, de
	extz xbc
	add xbc, xiy
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xbc), a
	inc 1, l
	inc 1, de

LABEL_F3DF4F:
	cp l, (xiz)
	jr c, LABEL_F3DF35
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	lda xwa, (xsp + 40)
	mrib4 0x80, 0x19, 0x42, 0x8D
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8D
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8D
	mrdb5 0x88, 0x03, 0x19, 0xDE, 0xCE
	call BitMapOut_CheckDiskAndApply

BitMapOut_CompletionJoin:
	ldb l, 0x0

LABEL_F3DF77:
	pop xiz
	lda xsp, (xsp + 42)
	ret

BitMapOut_PrepareAndDisplay:
	lda xsp, (xsp - 16)
	lda xbc, (xsp)
	ld (xbc), 0x0
	lda xwa, (xsp + 12)
	lds de, 2
	call NoteDisplay_StoreAndDispatch
	lda xwa, (xsp + 12)
	mrib4 0x80, 0x19, 0xDF, 0xCE
	mrdb5 0x88, 0x01, 0x19, 0xE0, 0xCE
	mrdb5 0x88, 0x02, 0x19, 0xE1, 0xCE
	mrdb5 0x88, 0x03, 0x19, 0xDE, 0xCE
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	lda xwa, (xsp + 12)
	mrib4 0x80, 0x19, 0x42, 0x8D
	mrdb5 0x88, 0x01, 0x19, 0x40, 0x8D
	mrdb5 0x88, 0x02, 0x19, 0x44, 0x8D
	mrdb5 0x88, 0x03, 0x19, 0xDE, 0xCE
	call BitMapOut_CheckDiskAndApply
	lda xsp, (xsp + 16)
	ret

BitMapOut_PrepareAndDisplaySimple:
	lda xsp, (xsp - 16)
	lda xbc, (xsp)
	ld (xbc), 0x0
	lda xwa, (xsp + 12)
	lds de, 2
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
	cpdi8 7558, 0
	call_24 nz, 0xF3DA8E
	lda xde, (xsp)
	ld (xde), 0x90
	ld (xde + 1), 0x7F
	ld (xde + 2), 0x0
	ld (xde + 3), 0x0
	lda xbc, (xde + 4)
	cp (xsp + 8), 0x32
	jr nz, LABEL_F3E02E
	ld (xbc), 0x7F
	jr LABEL_F3E035

LABEL_F3E02E:
	ld a, (xsp + 8)
	dec 1, a
	ld (xbc), a

LABEL_F3E035:
	push xde
	pushw 0x5
	call SeqBuf_WriteBytes
	inc 6, xsp
	calr SeqBuf_FlushAndReinit_NoteEvents
	cp (xsp + 8), 0x32
	jr nz, LABEL_F3E04E
	ldw wa, 0x32
	calr SeqNotePool_Init

LABEL_F3E04E:
	lda xsp, (xsp + 10)
	ret

Part_DetectSingleVoiceType:
	resda 0, 9954
	ldb l, 0x0
	ldb d, 0x1

LABEL_F3E05A:
	ld a, d
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3E067
	slaa bc

LABEL_F3E067:
	andda16 xbc, 10408
	jr z, LABEL_F3E071
	inc 1, l
	ld e, d

LABEL_F3E071:
	cps l, 1
	jr ugt, LABEL_F3E07C
	inc 1, d
	cp d, 0x10
	jr ule, LABEL_F3E05A

LABEL_F3E07C:
	cps l, 1
	jp_24 nz, 0xF98782
	extz de
	lds wa, 0
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xF
	ret z
	cp l, 0x13
	jr ule, LABEL_F3E098
	ldb l, 0x0

LABEL_F3E098:
	extz hl
	lda_24 xbc, 0xe44536
	ld_srib3 E, 0x07, 0xE4, 0xEC
	setda 0, 9954
	stda8 36154, e
	extz de
	pushw 0xFF
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ret

Part_DeactivateVoiceChannel:
	dec 2, xsp
	ld (xsp), a
	ld c, (xsp)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceByte
	cp l, 0xF
	jr nz, LABEL_F3E0D6
	resda 7, 10414
	call MidiChannel_ResetAndConfigure

LABEL_F3E0D6:
	ld a, (xsp)
	extz wa
	bitda 2, 1057
	jr z, LABEL_F3E119
	cpdi16 61854, 0
	jr nz, LABEL_F3E114
	stdi16 10420, 0
	ldw wa, 0x32
	calr SeqBuf_WriteNoteOffEntry
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr Chan_SetActiveBit
	calr VoiceAlloc_ProcessAll
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	call Audio_CheckSubsystemReady
	call SeqBuf_Init
	jr AccWrap_ClearPositionAndReset

LABEL_F3E114:
	calr Part_SendVoiceOffAndCCEvents
	jr AccWrap_ClearPositionAndReset

LABEL_F3E119:
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3E124
	slaa bc

LABEL_F3E124:
	cpl bc
	ldda16 xwa, 10420
	and wa, bc
	stda16 10420, xwa
	cpdi16 61854, 0
	jr nz, LABEL_F3E14E
	stdi16 10420, 0
	resda 7, 10413
	call SeqBuf_Init

AccWrap_ClearPositionAndReset:
	resda 0, 10406
	call AccWrap_PositionClear

LABEL_F3E14E:
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

Accomp_UpdateModeFlag:
	cpdi8 36150, 129
	jr z, LABEL_F3E164
	cpdi16 61854, 0
	jr z, LABEL_F3E16A

LABEL_F3E164:
	setda 0, 10405
	jr LABEL_F3E16E

LABEL_F3E16A:
	resda 0, 10405

LABEL_F3E16E:
	ld16_24 xwa, 0x00ffec
	stda16 61854, xwa
	call Audio_CheckSubsystemReady
	ldw wa, 0x4C
	jp CtrlPanel_SetIndicatorBit

Accomp_ValidateAutoPlayChordVoice:
	push_werp 0xFA
	ldi_berp 0xFB, 1
	lds wa, 0
	ldw bc, 0xD
	calr Part_FindVoiceByByte
	cp l, 0xFF
	jr nz, LABEL_F3E198
	ldi_berp 0xFB, 0

LABEL_F3E198:
	ld a, l
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3E1A5
	slaa bc

LABEL_F3E1A5:
	andda16 xbc, 61854
	jr nz, LABEL_F3E1AE
	ldi_berp 0xFB, 0

LABEL_F3E1AE:
	extz hl
	lds wa, 0
	ld bc, hl
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F3E1BE
	ldi_berp 0xFB, 0

LABEL_F3E1BE:
	ldto_berp A, 0xFB
	stda8 8968, a
	pop_werp 0xFA
	ret

Seq_SyncPositionAndOutputMIDITiming:
	dec 8, xsp
	push xiz
	ld xiy, 0xE445EE
	lda xix, (xsp + 4)
	ldi85
	ldiw
	cpdi8 58248, 1
	jr nz, LABEL_F3E1E6
	stdi8 58248, 0
	jr Seq_PopIzSkip8Ret

LABEL_F3E1E6:
	cpdi8 36148, 19
	jr z, Seq_PopIzSkip8Ret
	bitda 0, 47079
	jr nz, Seq_PopIzSkip8Ret
	lds wa, 4
	calr LABEL_F439BF
	cps l, 0
	jr z, Seq_PopIzSkip8Ret
	stdi8 1060, 242
	lda xiz, (xsp + 8)
	ei 6
	ldmw2 (xiz), 0x41C
	ldmi16 (xiz + 2), 0x41B
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
	and de, 0x7F
	srl bc, 7
	and bc, 0x7F
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

LABEL_F3E250:
	bitda 6, 10413
	ret z
	lds wa, 0
	ldw bc, 0xF
	calr Part_FindVoiceByByte
	cp l, 0xFF
	ret z
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xF
	jr z, LABEL_F3E270
	slaa bc

LABEL_F3E270:
	ld wa, bc
	andda16 xbc, 61854
	ret z
	andda16 xwa, 10420
	ret z
	setda 7, 10414
	ret

Part_CopyVoiceDataToAllChannels:
	dec 8, xsp
	push_werp 0xFA
	ld (xsp + 8), 0x81
	ld (xsp + 6), 0x82
	ldi_berp 0xFB, 1

LABEL_F3E293:
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3E2A1
	slaa bc

LABEL_F3E2A1:
	andda16 xbc, 10408
	jr z, LABEL_F3E319
	ldto_berp C, 0xFB
	extz bc
	lda xwa, (xsp + 2)
	dec 1, c
	extz bc
	sla bc, 2
	ldada xde, 9184
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld bc, (xde)
	ld (xwa), bc
	ld bc, (xde + 2)
	ld (xwa + 2), bc
	lda xbc, (xsp + 8)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 2)
	lds wa, 0
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 4)
	lds wa, 0
	calr Part_WriteByte_Indexed
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	ldto_berp C, 0xFB
	extz bc
	lda xwa, (xsp + 2)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de

LABEL_F3E319:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jrl ule, LABEL_F3E293
	pop_werp 0xFA
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
	and a, 0xF
	jr z, LABEL_F3E342
	slaa de

LABEL_F3E342:
	andda16 xde, 10408
	jr z, LABEL_F3E378
	extz bc
	lda xwa, (xsp)
	dec 1, c
	extz bc
	sla bc, 2
	ldada xde, 9184
	st_dri3b B, 0x07, 0xE8, 0xE4
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

LABEL_F3E378:
	inc 8, xsp
	ret

SeqEvent_GetParamLength:
	ld c, a
	and c, 0xF0
	cp c, 0xC0
	jr z, SeqEvent_ReturnError6
	cp c, 0xB0
	jr z, SeqEvent_ReturnError6
	cp c, 0x90
	jr z, SeqEvent_ReturnError6
	cp a, 0x82
	jr z, LABEL_F3E3D5
	cp a, 0x81
	jr z, LABEL_F3E3D5
	cp a, 0x86
	jr z, LABEL_F3E3D1
	cp a, 0x85
	jr z, LABEL_F3E3D1
	cp a, 0xA0
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xD3
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xD1
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0xD0
	jr z, SeqEvent_ReturnStatusThree
	cp a, 0x80
	jr z, LABEL_F3E3C9
	cp a, 0xD2
	jr z, LABEL_F3E3C9
	ldw hl, 0xFFFF

SeqEvent_NullRet:
	ret

SeqEvent_ReturnError6:
	lds hl, 6
	jr SeqEvent_NullRet

LABEL_F3E3C9:
	lds hl, 4
	jr SeqEvent_NullRet

SeqEvent_ReturnStatusThree:
	lds hl, 3
	jr SeqEvent_NullRet

LABEL_F3E3D1:
	lds hl, 2
	jr SeqEvent_NullRet

LABEL_F3E3D5:
	lds hl, 1
	jr SeqEvent_NullRet

SeqNotePool_Init:
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 10), a
	ldada xwa, 7602
	cp (xsp + 10), 0x32
	jr nz, LABEL_F3E427
	ld (xwa), 0xFF
	ld (xwa + 1), 0xFF
	ld (xwa + 2), 0x0
	ld (xwa + 3), 0x3F
	ldada xix, 7606
	ldb c, 0x1
	lda xde, (xix + 1)
	ld xhl, xix

LABEL_F3E406:
	ld a, c
	add a, 0xFE
	ld (xhl), a
	ld (xde), c
	lda xhl, (xhl + 9)
	lda xde, (xde + 9)
	inc 1, c
	cp c, 0x40
	jr ule, LABEL_F3E406
	ld (xix), 0xFF
	stib_dri 0xF1, 0x38, 0x02, 0xFF
	jr LABEL_F3E4A3

LABEL_F3E427:
	ld a, (xwa)
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0xFF
	jr z, LABEL_F3E4A3

LABEL_F3E432:
	ldto_berp A, 0xFB
	extz wa
	lda xde, (xsp + 2)
	ld c, a
	ldfr_berp C, 0xEE
	ld xix, xde
	ldi_berp 0xE2, 0

LABEL_F3E444:
	ldto_berp C, 0xE2
	extz bc
	ld iy, bc
	inc 4, iy
	ldto_berp C, 0xEE
	extz bc
	muls bc, 0x9
	ld hl, bc
	ldada xbc, 7606
	st_dri3b A, 0x07, 0xE4, 0xEC
	extz xiy
	add xiy, xbc
	ldto_berp L, 0xE2
	extz hl
	ld c, (xiy)
	lda_dri3 XHL, 0x07, 0xF0, 0xEC
	inc1_berp 0xE2
	cpi_berp 0xE2, 5
	jr c, LABEL_F3E444
	ld c, (xde + 4)
	inc 1, c
	cp c, (xsp + 10)
	call_24 z, 0xF3E6FD
	ldto_berp A, 0xFB
	extz wa
	muls wa, 0x9
	ld bc, wa
	ldada xwa, 7607
	ld_srib3 A, 0x07, 0xE0, 0xE4
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0xFF
	jr nz, LABEL_F3E432

LABEL_F3E4A3:
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_F3E4AA:
	.byte 0xd7, 0xfa, 0x04, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb
	.byte 0x8b, 0xcb, 0x61, 0xd9, 0x12, 0xd8, 0xa8, 0x1e
	.byte 0xce, 0x32, 0xc7, 0xfb, 0x8b, 0xcb, 0x61, 0xd9
	.byte 0x12, 0xdb, 0x12, 0xcb, 0x69, 0xcb, 0x89, 0xd9
	.byte 0xa9, 0xc9, 0xcc, 0x0f, 0x66, 0x02, 0xd9, 0xfc
	.byte 0xcf, 0xd8, 0x66, 0x06, 0xd1, 0x16, 0x23, 0xe9
	.byte 0x68, 0x06, 0xd9, 0x06, 0xd1, 0x16, 0x23, 0xc9
	.byte 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x10, 0x67
	.byte 0xc5, 0xd7, 0xfa, 0x05, 0x0e

LABEL_F3E4EF:
	push xiz
	cp a, 0xFF
	jr nz, LABEL_F3E4FA
	stdi8 58250, 255

LABEL_F3E4FA:
	ldada xiz, 8184
	lda xix, (xiz + 1)
	ld w, (xix)
	ld c, a
	extz bc
	muls bc, 0xC
	ld iy, bc
	ldada xhl, 8186
	st_dri3b A, 0x07, 0xEC, 0xF4
	lda xde, (xbc + 10)
	cp w, 0xFF
	jr nz, LABEL_F3E525
	ld (xiz), a
	ld (xde), 0xFF
	jr LABEL_F3E536

LABEL_F3E525:
	ld c, w
	extz bc
	muls bc, 0xC
	exts xbc
	add xbc, xhl
	ld (xbc + 11), a
	ld (xde), w

LABEL_F3E536:
	ld (xix), a
	st_dri3b W, 0x07, 0xEC, 0xF4
	ld (xwa + 11), 0xFF
	pop xiz
	ret

LABEL_F3E543:
	push xiz
	extz wa
	muls wa, 0xC
	ldada xiz, 8186
	st_dri3b A, 0x07, 0xF8, 0xE0
	ld a, (xbc + 10)
	ldfr_berp A, 0xF4
	ld a, (xbc + 11)
	ldfr_berp A, 0xF0
	ldada xde, 8182
	lda xbc, (xde + 1)
	cp_erpb 0xF4, 0xFF
	jr nz, VoiceAlloc_RelinkEntry
	cp_erpb 0xF0, 0xFF
	jr nz, VoiceAlloc_RelinkEntry
	ld (xde), 0xFF
	ld (xbc), 0xFF
	jr Bitmap_RestoreReturn

VoiceAlloc_RelinkEntry:
	ldto_berp A, 0xF0
	extz wa
	muls wa, 0xC
	exts xwa
	add xwa, xiz
	lda xhl, (xwa + 10)
	cp_erpb 0xF4, 0xFF
	jr nz, LABEL_F3E59A
	ldto_berp A, 0xF0
	ld (xde), a
	ld (xhl), 0xFF
	jr Bitmap_RestoreReturn

LABEL_F3E59A:
	ldto_berp A, 0xF4
	extz wa
	muls wa, 0xC
	exts xwa
	add xwa, xiz
	lda xde, (xwa + 11)
	cp_erpb 0xF0, 0xFF
	jr nz, LABEL_F3E5BA
	ldto_berp A, 0xF4
	ld (xbc), a
	ld (xde), 0xFF
	jr Bitmap_RestoreReturn

LABEL_F3E5BA:
	ldto_berp A, 0xF4
	ld (xhl), a
	ldto_berp A, 0xF0
	ld (xde), a

Bitmap_RestoreReturn:
	pop xiz
	ret

LABEL_F3E5C6:
	push xiz
	ldada xiz, 8182
	lda xix, (xiz + 1)
	ld w, (xix)
	ld c, a
	extz bc
	muls bc, 0xC
	ld iy, bc
	ldada xhl, 8186
	st_dri3b A, 0x07, 0xEC, 0xF4
	lda xde, (xbc + 10)
	cp w, 0xFF
	jr nz, LABEL_F3E5F2
	ld (xiz), a
	ld (xde), 0xFF
	jr LABEL_F3E603

LABEL_F3E5F2:
	ld c, w
	extz bc
	muls bc, 0xC
	exts xbc
	add xbc, xhl
	ld (xbc + 11), a
	ld (xde), w

LABEL_F3E603:
	ld (xix), a
	ldada xwa, 8197
	stib_dri 0x07, 0xE0, 0xF4, 0xFF
	pop xiz
	ret

SeqBuffer_ClearAndInitIteration:
	dec 6, xsp
	push xiz
	lda xde, (xsp + 4)
	ld xwa, xde
	lda xbc, (xde + 6)

LABEL_F3E61C:
	stib_dpi 0xE0, 0xFF
	cp xwa, xbc
	jr c, LABEL_F3E61C
	ldada xwa, 8182
	ld (xwa), 0xFF
	ld (xwa + 1), 0xFF
	ldada xwa, 8184
	ld (xwa), 0x0
	ld (xwa + 1), 0x3F
	ldb l, 0x0

LABEL_F3E63C:
	ld c, l
	extz bc
	ld a, c
	ldfr_berp A, 0xE6
	ld xiy, xde
	ldb h, 0x0

LABEL_F3E649:
	ldfr_berp H, 0xF8
	extz iz
	ldto_berp A, 0xE6
	extz wa
	muls wa, 0xC
	ldada xix, 8186
	exts xwa
	add xwa, xix
	extz xiz
	add xiz, xwa
	ld a, h
	extz wa
	ld_srib3 A, 0x07, 0xF4, 0xE0
	ld (xiz), a
	inc 1, h
	cps h, 4
	jr c, LABEL_F3E649
	muls bc, 0xC
	exts xbc
	add xbc, xix
	ld a, l
	dec 1, a
	ld (xbc + 10), a
	ld a, l
	inc 1, a
	ld (xbc + 11), a
	inc 1, l
	cp l, 0x3F
	jr ule, LABEL_F3E63C
	ld (xix + 10), 0xFF
	stib_dri 0xF1, 0xFF, 0x02, 0xFF
	pop xiz
	inc 6, xsp
	ret

LABEL_F3E69F:
	ldda8 a, 8182
	ldw hl, 0xFFFF
	cp a, 0xFF
	jr z, LABEL_F3E6CA
	ldada xbc, 8186

LABEL_F3E6AF:
	extz wa
	muls wa, 0xC
	exts xwa
	add xwa, xbc
	ld de, (xwa + 4)
	cp de, hl
	jr nc, LABEL_F3E6C2
	ld hl, de

LABEL_F3E6C2:
	ld a, (xwa + 11)
	cp a, 0xFF
	jr nz, LABEL_F3E6AF

LABEL_F3E6CA:
	stda16 8954, xhl
	ret

LABEL_F3E6CF:
	extz wa
	muls wa, 0x9
	ldada xbc, 7606
	exts xwa
	add xwa, xbc
	ld e, (xwa + 1)
	ldada xwa, 7602
	ld (xwa + 2), e
	cp e, 0xFF
	jr z, LABEL_F3E6F9
	extz de
	muls de, 0x9
	stib_dri 0x07, 0xE4, 0xE8, 0xFF
	ret

LABEL_F3E6F9:
	ld (xwa + 3), e
	ret

LABEL_F3E6FD:
	dec 4, xsp
	push xiz
	ld c, a
	extz bc
	muls bc, 0x9
	ldada xhl, 7606
	st_dri3b B, 0x07, 0xEC, 0xE4
	ld w, (xde)
	lda xbc, (xde + 1)
	ld (xsp + 4), xbc
	ld c, (xbc)
	ldfr_berp C, 0xE2
	cp w, 0xFF
	jr nz, NoteMap_RelinkEntry
	cp_erpb 0xE2, 0xFF
	jr nz, NoteMap_RelinkEntry
	ldada xbc, 7602
	ld (xbc), 0xFF
	ld (xbc + 1), 0xFF
	jr NoteMap_UpdateTailPointer

NoteMap_RelinkEntry:
	ldto_berp C, 0xE2
	extz bc
	muls bc, 0x9
	st_dri3b H, 0x07, 0xEC, 0xE4
	ldada xix, 7602
	cp w, 0xFF
	jr nz, LABEL_F3E756
	ldto_berp C, 0xE2
	ld (xix), c
	ldb w, 0xFF
	jr LABEL_F3E778

LABEL_F3E756:
	ld c, w
	extz bc
	muls bc, 0x9
	exts xbc
	add xbc, xhl
	lda xiy, (xbc + 1)
	cp_erpb 0xE2, 0xFF
	jr nz, LABEL_F3E773
	ld (xix + 1), w
	ld (xiy), 0xFF
	jr NoteMap_UpdateTailPointer

LABEL_F3E773:
	ldto_berp C, 0xE2
	ld (xiy), c

LABEL_F3E778:
	ld (xiz), w

NoteMap_UpdateTailPointer:
	ldada xbc, 7602
	lda xix, (xbc + 3)
	ld w, (xix)
	cp w, 0xFF
	jr nz, LABEL_F3E78F
	ld (xbc + 2), a
	ldb w, 0xFF
	jr LABEL_F3E79E

LABEL_F3E78F:
	ld c, w
	extz bc
	muls bc, 0x9
	exts xbc
	add xbc, xhl
	ld (xbc + 1), a

LABEL_F3E79E:
	ld (xde), w
	ld (xix), a
	ld xwa, (xsp + 4)
	ld (xwa), 0xFF
	pop xiz
	inc 4, xsp
	ret

LABEL_F3E7AC:
	ldada xde, 8184
	ld l, (xde)
	cp l, 0xFF
	ret z
	ld a, l
	extz wa
	muls wa, 0xC
	ldada xbc, 8186
	exts xwa
	add xwa, xbc
	ld h, (xwa + 11)
	cp h, 0xFF
	jr z, LABEL_F3E7DF
	ld a, h
	extz wa
	muls wa, 0xC
	exts xwa
	add xwa, xbc
	ld (xwa + 10), 0xFF

LABEL_F3E7DF:
	ld (xde), h
	cp h, 0xFF
	ret nz
	stda8 10344, l
	ret

SeqPlay_AllocBuffersAndInit:
	ldda8 c, 36150
	cp c, 0x85
	jr z, LABEL_F3E7F9
	cp c, 0x86
	jr nz, LABEL_F3E845

LABEL_F3E7F9:
	bitda 1, 10417
	jr nz, LABEL_F3E816
	stdi16 9000, 0
	stdi16 1052, 0
	stdi8 1051, 0
	resda 3, 10407
	jr LABEL_F3E85F

LABEL_F3E816:
	ldda16 xwa, 9504
	calr SeqBuf_AllocNextSlot
	stda16 9000, xhl
	stda16 1052, xhl
	stdi8 1051, 0
	cps hl, 0
	jr nz, LABEL_F3E834
	resda 3, 10407
	jr LABEL_F3E838

LABEL_F3E834:
	setda 3, 10407

LABEL_F3E838:
	ldda16 xwa, 9506
	calr SeqBuf_AllocNextSlotAdjusted
	stda16 9002, xhl
	jr LABEL_F3E85F

LABEL_F3E845:
	ldda16 xwa, 9832
	cp c, 0x87
	jr z, LABEL_F3E853
	cp c, 0x88
	jr nz, LABEL_F3E865

LABEL_F3E853:
	calr SeqBuf_AllocNextSlot
	stda16 1052, xhl
	stdi8 1051, 0

LABEL_F3E85F:
	call SeqPlay_InitializePlayback
	jr LABEL_F3E897

LABEL_F3E865:
	bitda 3, 10407
	jr z, LABEL_F3E877
	calr SeqBuf_AllocNextSlot
	stda16 1052, xhl
	stdi8 1051, 0

LABEL_F3E877:
	bitda 0, 10417
	jr z, LABEL_F3E893
	ldda16 xwa, 9500
	calr SeqBuf_AllocNextSlot
	stda16 9000, xhl
	ldda16 xwa, 9502
	calr SeqBuf_AllocNextSlotAdjusted
	stda16 9002, xhl

LABEL_F3E893:
	call SeqAcc_InitPlaybackState

LABEL_F3E897:
	jr SeqPlay_ResetStartState

SeqPlay_InitStartState:
	setda 4, 10419
	setda 2, 10407
	stdi8 9508, 1
	cpdi16 9832, 1
	jr z, LABEL_F3E8B9
	stdi8 7518, 250
	setda 3, 10407
	jr LABEL_F3E8E2

LABEL_F3E8B9:
	ldda8 a, 36150
	cp a, 0x85
	jr z, LABEL_F3E8C7
	cp a, 0x86
	jr nz, LABEL_F3E8CF

LABEL_F3E8C7:
	bitda 1, 10417
	jr z, Display_ClearHWState
	jr LABEL_F3E8EE

LABEL_F3E8CF:
	cp a, 0x87
	jr z, Display_ClearHWState
	cp a, 0x88
	jr nz, LABEL_F3E8E8

Display_ClearHWState:
	stdi8 7518, 0

LABEL_F3E8DE:
	resda 3, 10407

LABEL_F3E8E2:
	stdi8 58246, 1
	ret

LABEL_F3E8E8:
	bitda 0, 10417
	jr z, Display_ClearHWState

LABEL_F3E8EE:
	stdi8 7518, 250
	jr LABEL_F3E8DE

SeqPlay_ResetStartState:
	resda 4, 10419
	stdi8 7518, 0
	stdi8 9508, 0
	cpdi8 36150, 142
	ret z
	cpdi8 58246, 1
	jr nz, LABEL_F3E915
	resda 2, 10407

LABEL_F3E915:
	stdi8 58246, 0
	ret

LABEL_F3E91B:
	dec 8, xsp
	push xiz
	lds iz, 0
	ld (xsp + 6), 0x81
	ldda8 a, 8986
	ldfr_berp A, 0xFB
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	stda16 10415, xhl
	stdi16 9830, 5
	ldmw2 (xsp + 4), 0x232A
	cpw (xsp + 4), 0x0
	jrl c, LABEL_F3EA00

LABEL_F3E94C:
	calr SeqData_ReadNextByte
	cp l, 0x81
	jr nz, LABEL_F3E95C
	inc 1, iz
	calr SeqData_AdvancePosition
	jrl LABEL_F3E9FA

LABEL_F3E95C:
	cp l, 0x82
	jrl nz, LABEL_F3E9EC
	lda xwa, (xsp + 8)
	ldmw2 (xwa), 0x28AF
	ldmw2 (xwa + 2), 0x2666
	cp iz, (xsp + 4)
	jr ugt, LABEL_F3E985

LABEL_F3E973:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	inc 1, iz
	cp iz, (xsp + 4)
	jr ule, LABEL_F3E973

LABEL_F3E985:
	lda xwa, (xsp + 8)
	mriw4 0x90, 0x19, 0xAF, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x66, 0x26
	ldw wa, 0x82
	calr PartCtrl_WriteByte_Indexed
	ldto_berp C, 0xFB
	extz bc
	ldda16 xde, 10415
	lds wa, 0
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xFB
	extz bc
	ldda16 xwa, 9830
	ld e, a
	extz de
	lds wa, 0
	calr Part_WriteByte_Indexed
	ldda16 xbc, 9000
	ldto_berp A, 0xFB
	extz wa
	lda xde, (xsp + 8)
	call Part_ReadAndProcessVoiceData
	ldto_berp C, 0xFB
	extz bc
	lda xwa, (xsp + 8)
	ld hl, (xwa)
	ld de, (xwa + 2)
	dec 1, c
	ld a, c
	extz wa
	sla wa, 3
	ldada xbc, 9332
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	jr LABEL_F3E9FA

LABEL_F3E9EC:
	extz hl
	ld wa, hl
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

LABEL_F3E9FA:
	cp iz, (xsp + 4)
	jrl ule, LABEL_F3E94C

LABEL_F3EA00:
	pop xiz
	inc 8, xsp
	ret

SeqPart_InitVoiceChannelConfig:
	dec 4, xsp
	push xiz
	ldda16 xwa, 9002
	stda16 7542, xwa
	ldda16 xwa, 9002
	subda16 xwa, 9000
	inc 1, wa
	stda16 7544, xwa
	ldda16 xwa, 8982
	stda16 8984, xwa
	lds wa, 0
	ldw bc, 0xD
	calr Part_FindVoiceByByte
	cp l, 0xFF
	jr z, LABEL_F3EA53
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xF
	jr z, LABEL_F3EA3F
	slaa bc

LABEL_F3EA3F:
	andda16 xbc, 8982
	ldada xwa, 7538
	cps bc, 0
	jr z, LABEL_F3EA50
	ld (xwa), 0x1
	jr LABEL_F3EA53

LABEL_F3EA50:
	ld (xwa), 0x0

LABEL_F3EA53:
	lds wa, 0
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp l, 0xFF
	jr z, LABEL_F3EA81
	dec 1, l
	lds bc, 1
	ld a, l
	and a, 0xF
	jr z, LABEL_F3EA6D
	slaa bc

LABEL_F3EA6D:
	andda16 xbc, 8982
	ldada xwa, 7539
	cps bc, 0
	jr z, LABEL_F3EA7E
	ld (xwa), 0x1
	jr LABEL_F3EA81

LABEL_F3EA7E:
	ld (xwa), 0x0

LABEL_F3EA81:
	ldb b, 0x1
	ldb c, 0x0

LABEL_F3EA85:
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F3EA90
	slaa de

LABEL_F3EA90:
	andda16 xde, 8982
	jr z, LABEL_F3EAE3
	ld a, b
	extz wa
	lda xix, (xsp + 4)
	dec 1, a
	ld l, a
	extz hl
	ld wa, hl
	sla wa, 2
	ldada xde, 9184
	st_dri3b B, 0x07, 0xE8, 0xE0
	ld wa, (xde)
	ld (xix), wa
	lda xiy, (xix + 2)
	ld de, (xde + 2)
	ld (xiy), de
	ld wa, (xix)
	sla hl, 3
	ldada xiz, 9332
	exts xhl
	add xhl, xiz
	ld (xhl), wa
	ld (xhl + 2), de
	cpda8 b, 8988
	jr nz, LABEL_F3EAE3
	ld hl, (xix)
	ld de, (xiy)
	st_dri3b W, 0xF9, 0x98, 0x00
	ld (xwa), hl
	ld (xwa + 2), de

LABEL_F3EAE3:
	inc 1, b
	inc 1, c
	cp b, 0x10
	jr ule, LABEL_F3EA85
	pop xiz
	inc 4, xsp
	ret

LABEL_F3EAF0:
	ld c, a
	and c, 0xF0
	cp c, 0xC0
	jr z, LABEL_F3EB08
	cp c, 0xB0
	jr z, LABEL_F3EB08
	cp c, 0x90
	jr nz, LABEL_F3EB0C

LABEL_F3EB04:
	ldb l, 0x5
	jr SeqPart_NullRet

LABEL_F3EB08:
	ldb l, 0x7
	jr SeqPart_NullRet

LABEL_F3EB0C:
	cp a, 0x81
	jr z, LABEL_F3EB3F
	cp a, 0xD3
	jr z, SeqPart_ReturnStatusFour
	cp a, 0xD2
	jr z, LABEL_F3EB04
	cp a, 0xD1
	jr z, SeqPart_ReturnStatusFour
	cp a, 0xD0
	jr z, SeqPart_ReturnStatusFour
	cp a, 0x86
	jr z, LABEL_F3EB37
	cp a, 0x85
	jr z, LABEL_F3EB37
	cp a, 0x80
	jr z, SeqPart_ReturnStatusFour
	ldb l, 0x0

SeqPart_NullRet:
	ret

LABEL_F3EB37:
	ldb l, 0x2
	jr SeqPart_NullRet

SeqPart_ReturnStatusFour:
	ldb l, 0x4
	jr SeqPart_NullRet

LABEL_F3EB3F:
	ldb l, 0x1
	jr SeqPart_NullRet

SeqPlay_CheckRepeatActive:
	ldb l, 0x0
	ldda8 a, 36150
	cp a, 0x87
	ret z
	cp a, 0x88
	ret z
	ldda16 xbc, 9004
	ldda16 xwa, 9002
	ldda8 e, 36148
	cp e, 0xB
	jr nz, LABEL_F3EB70
	bitda 1, 10417
	ret z
	cp bc, wa
	jr ule, LABEL_F3EB7F
	jr LABEL_F3EB81

LABEL_F3EB70:
	cp e, 0x13
	ret z
	bitda 0, 10417
	ret z
	cp bc, wa
	ret ugt

LABEL_F3EB7F:
	ldb l, 0x1

LABEL_F3EB81:
	ret

LABEL_F3EB82:
	ld e, (xwa)
	and e, 0xF0
	lda xbc, (xwa + 4)
	cp e, 0xC0
	jr z, LABEL_F3EB9D
	ld l, (xbc)
	cp e, 0xB0
	jr z, LABEL_F3EB9D
	cp e, 0x90
	jr nz, LABEL_F3EBA1

LABEL_F3EB9B:
	jr LABEL_F3EBC2

LABEL_F3EB9D:
	lds bc, 6
	jr LABEL_F3EBB9

LABEL_F3EBA1:
	ld c, (xwa)
	cp c, 0xD2
	jr z, LABEL_F3EB9B
	cp c, 0xD3
	jr z, LABEL_F3EBB7
	cp c, 0xD1
	jr z, LABEL_F3EBB7
	cp c, 0xD0
	jr nz, LABEL_F3EBC0

LABEL_F3EBB7:
	lds bc, 3

LABEL_F3EBB9:
	ld_srib3 L, 0x07, 0xE0, 0xE4
	jr LABEL_F3EBC2

LABEL_F3EBC0:
	ldb l, 0xFF

LABEL_F3EBC2:
	ret

Part_SendVoiceOffAndCCEvents:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceByte
	ldfr_berp L, 0xFB
	ld a, (xsp + 2)
	extz wa
	calr SeqBuf_WriteNoteOffEntry
	ldada xwa, 58228
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 3), c
	lds bc, 4
	calr SeqBuf_WriteMidiEvent
	ldada xwa, 58232
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 4), c
	lds bc, 5
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents
	cp_erpb 0xFB, 0x0C
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xFB, 0x0D
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xFB, 0x10
	jr z, SeqBuf_MidiEventReturnPath
	cp_erpb 0xFB, 0x0F
	jr z, SeqBuf_MidiEventReturnPath
	ldto_berp A, 0xFB
	extz wa
	lda_24 xbc, 0xe44536
	ld_srib3 C, 0x07, 0xE4, 0xE0
	ldada xwa, 58238
	ld (xwa + 2), c
	ld c, (xsp + 2)
	dec 1, c
	ld (xwa + 6), c
	lds bc, 7
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents

SeqBuf_MidiEventReturnPath:
	pop_werp 0xFA
	inc 2, xsp
	ret

SeqVoice_FindSingleActive:
	resda 0, 9954
	ldb l, 0x0
	ldb d, 0x1

LABEL_F3EC51:
	ld a, d
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3EC5E
	slaa bc

LABEL_F3EC5E:
	andda16 xbc, 3407
	jr z, LABEL_F3EC68
	inc 1, l
	ld e, d

LABEL_F3EC68:
	cps l, 1
	jr ugt, LABEL_F3EC73
	inc 1, d
	cp d, 0x10
	jr ule, LABEL_F3EC51

LABEL_F3EC73:
	cps l, 1
	jp_24 nz, 0xF98782
	extz de
	lds wa, 0
	ld bc, de
	calr Part_ReadVoiceByte
	cp l, 0xF
	ret z
	cp l, 0x13
	jr ule, LABEL_F3EC8F
	ldb l, 0x0

LABEL_F3EC8F:
	extz hl
	lda_24 xbc, 0xe44536
	ld_srib3 E, 0x07, 0xE4, 0xEC
	setda 0, 9954
	stda8 36154, e
	extz de
	pushw 0xFF
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	ret

LABEL_F3ECB3:
	.byte 0xf1, 0xb3, 0x28, 0xb8, 0x0e

LABEL_F3ECB8:
	bitda 0, 10419
	ret z
	ldda8 a, 36150
	cp a, 0x87
	jr z, LABEL_F3ECCF
	cp a, 0x88
	call_24 nz, 0xFDB557

LABEL_F3ECCF:
	resda 0, 10419
	ret

LABEL_F3ECD4:
	cpdi16 61854, 0
	jr nz, LABEL_F3ECE5
	stdi8 8968, 0
	resda 3, 10407

LABEL_F3ECE5:
	resda 4, 1056
	resda 1, 1056
	ldda8 a, 1054
	res 4, a
	res 1, a
	stda8 1054, a
	cpdi8 36148, 19
	jr nz, LABEL_F3ED07
	calr LABEL_F3ED22
	jr Voice_LoadPresetReturn

LABEL_F3ED07:
	bitda 5, 10412
	jr nz, LABEL_F3ED18
	bitda 2, 1057
	jr nz, Voice_LoadPresetReturn
	bit 2, a
	jr nz, Voice_LoadPresetReturn

LABEL_F3ED18:
	calr LABEL_F3ED34

Voice_LoadPresetReturn:
	ldmm16 10296, 61854
	ret

LABEL_F3ED22:
	calr LABEL_F3ED2A
	stda16 8980, xhl
	ret

LABEL_F3ED2A:
	ldda8 a, 10404
	extz wa
	jp Voice_GetPresetFieldWord

LABEL_F3ED34:
	ldda16 xwa, 61854
	cps wa, 0
	jr z, LABEL_F3ED5E
	cpda16 xwa, 10296
	call_24 nz, 0xF393FC
	ldda8 a, 1075
	cpda8 a, 10346
	ret z
	stda8 9010, a
	call SeqMode_SendStatusUpdate
	ldmm8 10346, 1075
	ret

LABEL_F3ED5E:
	stdi16 8980, 0
	ldda8 a, 10407
	res 0, a
	stda8 10407, a
	cpdi16 10408, 0
	jr z, LABEL_F3ED7E
	set 0, a
	stda8 10407, a

LABEL_F3ED7E:
	setda 1, 10407
	ldda16 xwa, 61854
	cpda16 xwa, 10296
	jr z, LABEL_F3ED94
	call AccWrap_PositionClear
	resda 0, 10406

LABEL_F3ED94:
	resda 0, 1115
	ret

SeqCh_LoadChannelConfig:
	lda xsp, (xsp - 18)
	ld (xsp + 16), a
	cp (xsp + 16), 0x14
	jr ule, LABEL_F3EDAB
	ldw wa, 0x1D
	calr SeqData_SetErrorCode

LABEL_F3EDAB:
	ld a, (xsp + 16)
	extz wa
	lda xde, (xsp + 4)
	dec 1, a
	extz wa
	sla wa, 2
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld (xsp + 2), 0x0

LABEL_F3EDD1:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	cp hl, 0xFFFF
	jr nz, LABEL_F3EDE4
	ld (xsp + 9), 0x0

LABEL_F3EDE4:
	lda xhl, (xsp + 8)
	ld a, (xhl)
	ldfr_berp A, 0xE6
	ld e, (xsp + 16)
	dec 1, e
	extz de
	cp_erpb 0xE6, 0x81
	jr nz, LABEL_F3EE07
	sla de, 3
	ldada xwa, 9016
	inc_sriw 1, 0x07, 0xE0, 0xE8
	jr LABEL_F3EDD1

LABEL_F3EE07:
	ld a, (xsp + 16)
	extz wa
	ldada xix, 9016
	dec 1, a
	sla de, 3
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F3EE1E
	slaa bc

LABEL_F3EE1E:
	exts xde
	add xde, xix
	cpl bc
	cp_erpb 0xE6, 0x84
	jrl nz, LABEL_F3EEE8
	cp (xsp + 2), 0x1
	jr nz, LABEL_F3EE45
	cp (xsp + 16), 0x14
	jr z, LABEL_F3EE3E
	anddm16 8982, xbc
	jrl SeqCh_WriteVoiceDataToTable

LABEL_F3EE3E:
	ldw (xde), 0xFFF0
	jrl SeqCh_WriteVoiceDataToTable

LABEL_F3EE45:
	ld (xsp + 2), 0x1
	cp (xsp + 16), 0x11
	jr nc, LABEL_F3EE56
	ld a, (xsp + 16)
	ld (xsp), a
	jr LABEL_F3EE60

LABEL_F3EE56:
	cp (xsp + 16), 0x14
	jr nz, LABEL_F3EE60
	ldmi16 (xsp), 0x231C

LABEL_F3EE60:
	ld a, (xsp + 16)
	cpda8 a, 8990
	jr nz, LABEL_F3EE81
	lda xbc, (xsp + 4)
	ldada xde, 7594
	ld wa, (xde)
	ld (xbc), wa
	ld wa, (xde + 2)
	ld (xbc + 2), wa
	stdi8 7560, 1
	jr Voice_WriteIndexedData

LABEL_F3EE81:
	ld a, (xsp)
	cpda8 a, 8988
	jr nz, LABEL_F3EEB0
	lda xde, (xsp + 4)
	bitda 1, 8974
	jr z, LABEL_F3EEA0
	extz wa
	ldda8 c, 8972
	extz bc
	call Part_ReadAndProcessVoiceData
	jr Voice_WriteIndexedData

LABEL_F3EEA0:
	ldada xbc, 7590
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	jr Voice_WriteIndexedData

LABEL_F3EEB0:
	ld c, (xsp + 16)
	extz bc
	lds wa, 0
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
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de
	jrl LABEL_F3EDD1

LABEL_F3EEE8:
	cp_erpb 0xE6, 0x82
	jrl nz, SeqCh_WriteVoiceDataToTable
	cpdi8 7570, 1
	jr nz, LABEL_F3EF49
	cp (xsp + 16), 0x10
	jr ugt, LABEL_F3EF02
	anddm16 8982, xbc
	jr LABEL_F3EF06

LABEL_F3EF02:
	ldw (xde), 0xFFF0

LABEL_F3EF06:
	ld a, (xsp + 16)
	extz wa
	lda xbc, (xsp + 4)
	ld iy, (xbc)
	ld ix, (xbc + 2)
	dec 1, a
	extz wa
	ld bc, wa
	sla bc, 2
	ldada xde, 9184
	exts xbc
	add xbc, xde
	ld (xbc), iy
	ld (xbc + 2), ix
	ld de, wa
	sla de, 3
	ldada xwa, 9018
	ld xbc, xhl
	exts xde
	add xde, xwa
	inc 6, xhl

LABEL_F3EF3A:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_F3EF3A
	ldw hl, 0xFFFF
	jr LABEL_F3EFC1

LABEL_F3EF49:
	ld (xhl + 1), 0x0
	lds wa, 0
	ldw bc, 0xD
	calr Part_FindVoiceByByte
	ld (xsp), l
	ld a, (xsp + 16)
	cp a, (xsp)
	jr z, LABEL_F3EF64
	cp (xsp + 16), 0x14
	jr nz, SeqCh_WriteVoiceDataToTable

LABEL_F3EF64:
	ld a, (xsp + 16)
	dec 1, a
	extz wa
	sla wa, 3
	ldada xbc, 9016
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
	ldada xde, 9184
	exts xbc
	add xbc, xde
	ld (xbc), ix
	ld (xbc + 2), hl
	lda xhl, (xsp + 8)
	ld de, wa
	sla de, 3
	ldada xwa, 9018
	ld xbc, xhl
	exts xde
	add xde, xwa
	inc 6, xhl

LABEL_F3EFB5:
	ld_spib A, 0xE4
	lda_dpi XBC, 0xE8
	cp xbc, xhl
	jr c, LABEL_F3EFB5
	lds hl, 0

LABEL_F3EFC1:
	lda xsp, (xsp + 18)
	ret

LABEL_F3EFC5:
	dec 8, xsp
	pushw iz
	ld (xsp + 8), 0x81
	ld (xsp + 6), 0x82
	calr LABEL_F3F180
	ldada xbc, 9332
	st_dri3b W, 0xE5, 0x80, 0x00
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	st_dri3b W, 0xE5, 0x90, 0x00
	ldw (xwa), 0x1
	ldw (xwa + 2), 0x5
	st_dri3b W, 0xE5, 0x88, 0x00
	ldw (xwa), 0x2
	ldw (xwa + 2), 0x5
	ldada xbc, 9184
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
	ldda16 xwa, 9002
	subda16 xwa, 9000
	jr c, LABEL_F3F05A

LABEL_F3F041:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 8)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	inc 1, iz
	ldda16 xwa, 9002
	subda16 xwa, 9000
	cp iz, wa
	jr ule, LABEL_F3F041

LABEL_F3F05A:
	lda xwa, (xsp + 2)
	lda xbc, (xsp + 6)
	lds de, 1
	calr Part_CopyBytesToVoiceBlock
	ldada xwa, 9016
	ldmmw_dri 0xE1, 0x80, 0x00, 0x28, 0x23
	ldmmw_dri 0xE1, 0x88, 0x00, 0x28, 0x23
	ldw wa, 0x11
	calr SeqCh_LoadChannelConfig
	ldw wa, 0x13
	lds bc, 1
	call SeqPart_ReadEventStream
	popw iz
	inc 8, xsp
	ret

LABEL_F3F08A:
	push_werp 0xFA
	ldda16 xbc, 10408
	cps bc, 0
	jrl z, LABEL_F3F175
	ldi_berp 0xFB, 1

LABEL_F3F099:
	ldto_berp A, 0xFB
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F3F0A7
	slaa de

LABEL_F3F0A7:
	and de, bc
	jr nz, LABEL_F3F0B4
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F3F099

LABEL_F3F0B4:
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xE
	jr nz, LABEL_F3F116
	cpdi8 10430, 255
	jr z, LABEL_F3F0F2
	ldto_berp A, 0xFB
	extz wa
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld (xwa), 0xD
	stdi8 10430, 255
	jr LABEL_F3F116

LABEL_F3F0F2:
	ldada xwa, 64602
	ld e, (xwa + 3)
	and e, 0x7
	lda xbc, (xwa + 4)
	ld a, (xbc)
	and a, 0xF8
	or e, a
	ld (xbc), e
	extz de
	pushw 0x7
	ldw wa, 0x48
	lds bc, 4
	call AddswbWr

LABEL_F3F116:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	ldfr_berp A, 0xFA
	cp_erpb 0xFB, 0x10
	jr ugt, LABEL_F3F172

LABEL_F3F125:
	ldto_berp A, 0xFA
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xE
	jr nz, LABEL_F3F161
	cpdi8 10430, 255
	jr z, LABEL_F3F161
	ldto_berp A, 0xFA
	extz wa
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	ldto_berp A, 0xFA
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld (xwa), 0xD
	stdi8 10430, 255

LABEL_F3F161:
	ldto_berp A, 0xFA
	extz wa
	calr SeqVoice_DeactivateAndReinit
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x10
	jr ule, LABEL_F3F125

LABEL_F3F172:
	calr Accomp_ValidateAutoPlayChordVoice

LABEL_F3F175:
	pop_werp 0xFA
	ret

VoiceAlloc_ProcessAll:
	push xiz
	call Part_ReinitAllActive
	pop xiz
	ret

LABEL_F3F180:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), 0x0
	ld (xsp + 8), 0x1

LABEL_F3F18C:
	ld8_24 a, 0x00ffe3
	inc 1, a
	cp a, (xsp + 8)
	jr nz, LABEL_F3F19E
	ld (xsp + 4), 0x0
	jr LABEL_F3F1A4

LABEL_F3F19E:
	ld a, (xsp + 8)
	ld (xsp + 4), a

LABEL_F3F1A4:
	ld (xsp + 6), 0x1

LABEL_F3F1A8:
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
	cpw (xsp + 10), 0xFFFF
	jrl z, PartCtrl_IncrAndLoop
	cpw (xsp + 10), 0xFFFF
	jrl z, PartCtrl_IncrAndLoop

LABEL_F3F1DA:
	cpw (xsp + 10), 0x1
	jr z, LABEL_F3F1E9
	cpw (xsp + 10), 0x2
	jrl nz, PartCtrl_ReadWordCheck

LABEL_F3F1E9:
	ld (xsp + 14), 0x1
	ldmw2 (xsp + 12), 0xF22F
	cpw (xsp + 12), 0x1
	jr nz, LABEL_F3F209

PartCtrl_SkipLinkedEntries:
	ld wa, (xsp + 12)
	calr PartCtrl_ReadWord
	ld (xsp + 12), hl
	cpw (xsp + 12), 0x1
	jr z, PartCtrl_SkipLinkedEntries

LABEL_F3F209:
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
	ldda32 xwa, 7514
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

LABEL_F3F242:
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
	jr c, LABEL_F3F242
	ld wa, (xsp + 10)
	calr PartCtrl_ReadWord_Off1
	ld wa, hl
	cps wa, 0
	jr z, LABEL_F3F270
	ld bc, (xsp + 12)
	calr PartCtrl_WriteWord
	jr LABEL_F3F299

LABEL_F3F270:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 12)
	calr Part_WriteVoiceWord
	ld a, (xsp + 8)
	dec 1, a
	cpda8_24 a, 65507
	jr nz, LABEL_F3F299
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
	ld de, (xsp + 12)
	calr Part_WriteVoiceWord

LABEL_F3F299:
	ld wa, (xsp + 10)
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F3F2AF
	ld bc, (xsp + 12)
	calr PartCtrl_WriteWord_Off1
	jr PartCtrl_ReadWordCheck

LABEL_F3F2AF:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 12)
	calr Part_WriteWord_Indexed
	ld a, (xsp + 8)
	dec 1, a
	cpda8_24 a, 65507
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
	cpw (xsp + 10), 0xFFFF
	jrl nz, LABEL_F3F1DA

PartCtrl_IncrAndLoop:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x10
	jrl ule, LABEL_F3F1A8
	incm8 1, (xsp + 8)
	cp (xsp + 8), 0xA
	jrl ule, LABEL_F3F18C
	cp (xsp + 14), 0x1
	jr nz, LABEL_F3F345
	lds wa, 1
	lds bc, 1
	calr PartCtrl_SetClearBit7
	lds wa, 1
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xFFFF
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
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	jr LABEL_F3F355

LABEL_F3F345:
	cpdi16 61999, 1
	jr nz, LABEL_F3F352
	calr Part_UnlinkVoiceFromChain
	jr LABEL_F3F355

LABEL_F3F352:
	calr Part_DeallocVoices1And2

LABEL_F3F355:
	pop xiz
	lda xsp, (xsp + 12)
	ret

Part_ReleaseVoicesForRange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), c
	ld (xsp + 12), a
	cp (xsp + 12), 0xB
	jr nz, LABEL_F3F373
	ldi_berp 0xFB, 0
	ld (xsp + 4), 0xA
	jr LABEL_F3F37C

LABEL_F3F373:
	ld a, (xsp + 12)
	ldfr_berp A, 0xFB
	ld (xsp + 4), a

LABEL_F3F37C:
	cp (xsp + 10), 0x32
	jr nz, LABEL_F3F38C
	ld (xsp + 6), 0x1
	ld (xsp + 8), 0x10
	jr LABEL_F3F395

LABEL_F3F38C:
	ld a, (xsp + 10)
	ld (xsp + 6), a
	ld (xsp + 8), a

LABEL_F3F395:
	cp (xsp + 12), 0xB
	jr nz, LABEL_F3F3AE
	cp (xsp + 10), 0x32
	jr nz, LABEL_F3F3AE
	calr PartCtrl_InitChainLinkedList
	sti16_24 0x00ffec, 0x0000
	calr Part_UnlinkVoiceFromChain

LABEL_F3F3AE:
	ldto_berp A, 0xFB
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jrl ugt, LABEL_F3F456

LABEL_F3F3BA:
	ld a, (xsp + 6)
	ldfr_berp A, 0xFA
	cp a, (xsp + 8)
	jrl ugt, LABEL_F3F44A

LABEL_F3F3C6:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	calr Part_ReadVoiceWord
	ld iz, hl
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteWord_Indexed
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	lds de, 5
	calr Part_WriteByte_Indexed
	cp (xsp + 12), 0xB
	jr nz, LABEL_F3F41F
	cp (xsp + 10), 0x32
	jr z, LABEL_F3F424

LABEL_F3F41F:
	ld wa, iz
	calr Part_StealAndReallocVoices

LABEL_F3F424:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1C
	lds de, 0
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xCB
	lds de, 0
	calr Part_WriteByte
	inc1_berp 0xFA
	ldto_berp A, 0xFA
	cp a, (xsp + 8)
	jrl ule, LABEL_F3F3C6

LABEL_F3F44A:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jrl ule, LABEL_F3F3BA

LABEL_F3F456:
	pushw 0x1
	ldw wa, 0x91
	lds bc, 3
	lds de, 0
	call AddswbWr
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_F3F469:
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
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
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
	stdi8 61906, 0
	stdi16 9704, 0
	stdi8 61907, 1
	stdi8 61908, 2
	stdi8 61909, 3
	stdi8 61910, 1
	stdi16 61911, 1
	stdi16 61913, 1
	stdi16 9772, 1
	stdi8 61915, 1
	stdi16 61916, 1
	stdi16 61918, 1
	stdi16 9766, 1
	stdi8 61920, 0
	stdi8 61921, 1
	stdi16 61922, 1
	stdi16 61924, 1
	stdi8 61926, 1
	stdi16 61927, 1
	stdi16 9774, 1
	stdi8 9776, 0
	stdi8 61929, 1
	stdi16 61930, 1
	stdi16 61932, 1
	stdi8 61934, 1
	stdi16 61935, 1
	stdi8 9770, 0
	stdi16 9768, 1
	stdi8 61992, 1
	stdi16 61993, 1
	stdi16 61995, 1
	stdi16 9722, 1
	stdi8 61997, 0
	stdi8 61998, 0
	stdi8 62003, 0
	stdi8 62004, 0
	stdi8 61937, 1
	stdi16 61938, 1
	stdi16 61940, 1
	stdi16 9724, 1
	stdi8 61942, 3
	stdi8 9702, 0
	stdi8 9728, 100
	stdi8 9730, 100
	stdi8 9742, 1
	stdi16 9744, 1
	stdi16 9746, 1
	stdi16 9748, 1
	stdi8 9750, 60
	stdi8 9816, 60
	stdi16 9754, 1
	stdi8 9756, 1
	stdi16 9758, 1
	stdi16 9760, 1
	stdi8 9762, 0
	stdi8 9764, 1
	stdi8 9732, 1
	stdi16 9734, 1
	stdi16 9736, 1
	stdi16 9738, 1
	stdi8 9740, 0
	ret

Seq_ValidatePartNumber:
	cps a, 1
	jr c, LABEL_F3F60E
	cpda8 a, 10401
	jr ule, LABEL_F3F612

LABEL_F3F60E:
	ldw hl, 0xFFFF
	ret

LABEL_F3F612:
	lds hl, 0
	ret

Seq_ValidateTempoValue:
	cps wa, 1
	jr c, LABEL_F3F61F
	cp wa, 0x3E7
	jr ule, LABEL_F3F623

LABEL_F3F61F:
	ldw hl, 0xFFFF
	ret

LABEL_F3F623:
	lds hl, 0
	ret

LABEL_F3F626:
	ldda8	a, 10359
	cp	a, 127
	jr	z, 22
	extz	wa
	calr	65488
	cps	hl, 0
	jr	nz, 46
	ldda8	a, 9858
	extz	wa
	calr	65475
	cps	hl, 0
	jr	nz, 33
	ldda16	wa, 9778
	calr	65481
	cps	hl, 0
	jr	nz, 22
	ldda16	wa, 9694
	calr	65470
	cps	hl, 0
	jr	nz, 11
	ldda16	wa, 9862
	calr	65459
	cps	hl, 0
	jr	z, 4
	ldw	hl, 65535
	ret
	lds	hl, 0
	ret

LABEL_F3F66D:
	ldda8 a, 10359
	cp a, 0x7F
	jr z, LABEL_F3F68C
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ldda8 a, 9858
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn

LABEL_F3F68C:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_TempoValidationFailReturn
	ldda16 xwa, 9862
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, LABEL_F3F6B1

Seq_TempoValidationFailReturn:
	ldw hl, 0xFFFF
	ret

LABEL_F3F6B1:
	lds hl, 0
	ret

LABEL_F3F6B4:
	ldda8 a, 10359
	cp a, 0x7F
	jr z, LABEL_F3F6C6
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	ret nz

LABEL_F3F6C6:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	ret nz
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	ret nz
	ldda8 a, 9726
	extz wa
	cps wa, 0
	jr mi, LABEL_F3F6EC
	cp wa, 0xC
	jr le, LABEL_F3F6EF

LABEL_F3F6EC:
	ldw wa, 0xD

LABEL_F3F6EF:
	lda_24 xix, 0xe445f2
	ld_srib3 L, 0x07, 0xF0, 0xE0
	exts hl
	ret

LABEL_F3F6FC:
	ldda8 a, 10359
	cp a, 0x7F
	jr z, LABEL_F3F70E
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF

LABEL_F3F70E:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_ErrorReturnFFFF
	ldda8 a, 9808
	cps a, 0
	jr z, SeqPart_SuccessReturn
	cps a, 1
	jr z, SeqPart_SuccessReturn
	cps a, 2
	jr z, SeqPart_SuccessReturn

SeqPart_ErrorReturnFFFF:
	ldw hl, 0xFFFF
	ret

SeqPart_SuccessReturn:
	lds hl, 0
	ret

LABEL_F3F73B:
	ldda8 a, 10359
	cp a, 0x11
	jr z, LABEL_F3F74D
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, LABEL_F3F763

LABEL_F3F74D:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, LABEL_F3F763
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, LABEL_F3F767

LABEL_F3F763:
	ldw hl, 0xFFFF
	ret

LABEL_F3F767:
	lds hl, 0
	ret

LABEL_F3F76A:
	ldda8	a, 10359
	cp	a, 127
	jr	z, 9
	extz	wa
	calr	65164
	cps	hl, 0
	jr	nz, 22
	ldda16	wa, 9778
	calr	65170
	cps	hl, 0
	jr	nz, 11
	ldda16	wa, 9694
	calr	65159
	cps	hl, 0
	jr	z, 4
	ldw	hl, 65535
	ret
	lds	hl, 0
	ret

LABEL_F3F799:
	dec 2, xsp
	push xiz
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xwa, 9830
	ld (xsp + 4), wa
	dec 1, wa
	stda16 9830, xwa
	cps wa, 5
	jr nc, LABEL_F3F809
	ldda16 xwa, 10415
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	cps iz, 0
	jr z, LABEL_F3F7C7
	cp iz, 0x4D8
	jr ule, LABEL_F3F7DD

LABEL_F3F7C7:
	stdi8 10362, 10
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	mrdw5 0x9F, 0x04, 0x19, 0x66, 0x26
	ldw wa, 0x50
	jr LABEL_F3F7FA

LABEL_F3F7DD:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3F7FF
	stdi8 10362, 11
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	mrdw5 0x9F, 0x04, 0x19, 0x66, 0x26
	ldw wa, 0x51

LABEL_F3F7FA:
	calr SeqData_SetErrorCode
	jr LABEL_F3F809

LABEL_F3F7FF:
	stda16 10415, xiz
	stdi16 9830, 255

LABEL_F3F809:
	pop xiz
	inc 2, xsp
	ret

LABEL_F3F80D:
	.byte 0xd7, 0xfa, 0x04, 0xc1, 0x78, 0x28, 0x21, 0xc7
	.byte 0xfb, 0x99, 0xc2, 0xe3, 0xff, 0x00, 0x19, 0x78
	.byte 0x28, 0x1d, 0x66, 0x9a, 0xf4, 0xc7, 0xfb, 0x89
	.byte 0xf1, 0x78, 0x28, 0x41, 0xd7, 0xfa, 0x05, 0x0e
	.byte 0x1e, 0x77, 0x08, 0xd1, 0x68, 0x26, 0x19, 0x7f
	.byte 0x28, 0xdb, 0x12, 0xdb, 0x88, 0xdb, 0x89, 0x1e
	.byte 0x0d, 0x06, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x66
	.byte 0x07, 0xc1, 0x33, 0x04, 0x19, 0x5a, 0x26, 0x0e
	.byte 0xc1, 0x8e, 0x28, 0x19, 0x5a, 0x26, 0x0e

LABEL_F3F854:
	ldda8 a, 10359
	cp a, 0x11
	jr z, LABEL_F3F866
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, Seq_ValidationFailReturn

LABEL_F3F866:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_ValidationFailReturn
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, Seq_ValidationFailReturn
	cpdi8 9750, 127
	jr ugt, Seq_ValidationFailReturn
	cpdi8 9816, 127
	jr ule, LABEL_F3F88E

Seq_ValidationFailReturn:
	ldw hl, 0xFFFF
	ret

LABEL_F3F88E:
	lds hl, 0
	ret

LABEL_F3F891:
	.byte 0xd7, 0xfa, 0x04, 0xc1, 0x78, 0x28, 0x21, 0xc7
	.byte 0xfb, 0x99, 0xc1, 0x2a, 0x27, 0x19, 0x78, 0x28
	.byte 0x1e, 0x0b, 0x00, 0xc7, 0xfb, 0x89, 0xf1, 0x78
	.byte 0x28, 0x41, 0xd7, 0xfa, 0x05, 0x0e

SeqVoice_InitAllChannelParams:
	push xiz
	calr SeqVoice_SetDefaultParams
	ldda8 a, 10359
	ldfr_berp A, 0xFA
	stdi8 10359, 1
	ldda8 a, 10360
	cpda8_24 a, 65507
	jr nz, LABEL_F3F8CF
	ldi_berp 0xFB, 0
	jr LABEL_F3F8D4

LABEL_F3F8CF:
	inc 1, a
	ldfr_berp A, 0xFB

LABEL_F3F8D4:
	ldi_berp 0xF9, 1

LABEL_F3F8D7:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xF9
	extz bc
	calr Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F3F900
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xF9
	extz bc
	calr Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xFFFF
	call_24 nz, 0xF41F7C

LABEL_F3F900:
	inc1_berp 0xF9
	cp_erpb 0xF9, 0x10
	jr ule, LABEL_F3F8D7
	ldi_berp 0xF9, 1

LABEL_F3F90C:
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xF9
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteWord_Indexed
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xF9
	extz bc
	lds de, 5
	calr Part_WriteByte_Indexed
	inc1_berp 0xF9
	cp_erpb 0xF9, 0x10
	jr ule, LABEL_F3F90C
	ldi_berp 0xF9, 1

LABEL_F3F93D:
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xF9
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xF9
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	inc1_berp 0xF9
	cp_erpb 0xF9, 0x10
	jr ule, LABEL_F3F93D
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldw bc, 0x1E
	lds de, 0
	calr Part_WriteWord
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldw bc, 0x1C
	lds de, 0
	calr Part_WriteWord
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldw bc, 0xCB
	lds de, 0
	calr Part_WriteByte
	ldda8 a, 10360
	cpda8_24 a, 65507
	jr nz, LABEL_F3FA0C
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	sti16_24 0x00ffec, 0x0000
	stdi16 61852, 0
	stdi8 62027, 0
	ldi_berp 0xF9, 1

LABEL_F3F9C5:
	ldto_berp C, 0xF9
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	calr Part_WriteWord_Indexed
	ldto_berp C, 0xF9
	extz bc
	lds wa, 0
	lds de, 5
	calr Part_WriteByte_Indexed
	inc1_berp 0xF9
	cp_erpb 0xF9, 0x10
	jr ule, LABEL_F3F9C5
	ldi_berp 0xF9, 1

LABEL_F3F9EA:
	ldto_berp C, 0xF9
	extz bc
	lds wa, 0
	lds de, 0
	calr Part_SetClearVoiceBit7
	ldto_berp C, 0xF9
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	inc1_berp 0xF9
	cp_erpb 0xF9, 0x10
	jr ule, LABEL_F3F9EA

LABEL_F3FA0C:
	ldto_berp A, 0xFA
	stda8 10359, a
	pop xiz
	ret

LABEL_F3FA15:
	push_werp 0xFA
	ldi_berp 0xFB, 1

LABEL_F3FA1B:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1C
	lds de, 0
	calr Part_WriteWord
	ldi_berp 0xFA, 1

LABEL_F3FA2B:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteWord_Indexed
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	lds de, 5
	calr Part_WriteByte_Indexed
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x10
	jr ule, LABEL_F3FA2B
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1E
	lds de, 0
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xCB
	lds de, 0
	calr Part_WriteByte
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F3FA1B
	stdi16 61854, 0
	sti16_24 0x00ffec, 0x0000
	call Audio_CheckSubsystemReady
	stdi8 62027, 0
	calr SeqStatus_ResetAndSendCmd
	stdi16 10357, 0
	sti16_24 0x00ffec, 0x0000
	pop_werp 0xFA
	ret

LABEL_F3FABF:
	ldda8 a, 10359
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturn
	ldda8 a, 9858
	cpdm8 10359, a
	jr z, SeqPart_ErrorReturn
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_ErrorReturn
	ldda8 a, 9860
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr z, LABEL_F3FAF0

SeqPart_ErrorReturn:
	ldw hl, 0xFFFF
	ret

LABEL_F3FAF0:
	lds hl, 0
	ret

; ============================================================================
; PartCtrl_AdvanceReadPos - Advance read cursor through part control data
; ============================================================================
; Reads 16-bit counter from DRAM[10377]. If not at max (0xFF), increments.
; At max, advances to next data block via PartCtrl_ReadWord, validates
; bit 7 flag. Sets error code 2 on validation failure.
; ============================================================================
PartCtrl_AdvanceReadPos:
	pushw iz
	ldda16 xwa, 10377
	cp wa, 0xFF
	jr z, LABEL_F3FB06
	inc 1, wa
	stda16 10377, xwa
	jr LABEL_F3FB29

LABEL_F3FB06:
	ldda16 xwa, 10379
	calr PartCtrl_ReadWord
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3FB1F
	stdi8 10362, 2
	jr LABEL_F3FB29

LABEL_F3FB1F:
	stda16 10379, xiz
	stdi16 10377, 5

LABEL_F3FB29:
	popw iz
	ret

PartCtrl_NavigateBackward:
	pushw iz
	ldda16 xwa, 10377
	cps wa, 5
	jr z, LABEL_F3FB3C
	dec 1, wa
	stda16 10377, xwa
	jr SeqPart_RestoreReturn3

LABEL_F3FB3C:
	ldda16 xwa, 10379
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3FB5B
	ldw wa, 0x47
	calr SeqData_SetErrorCode
	stdi8 10362, 2
	jr SeqPart_RestoreReturn3

LABEL_F3FB5B:
	cps iz, 0
	jr z, LABEL_F3FB65
	cp iz, 0xFFFF
	jr nz, LABEL_F3FB6C

LABEL_F3FB65:
	stdi8 10362, 11
	jr SeqPart_RestoreReturn3

LABEL_F3FB6C:
	stda16 10379, xiz
	stdi16 10377, 255

SeqPart_RestoreReturn3:
	popw iz
	ret

PartCtrl_AdvanceToNextEntry:
	pushw iz
	ldda16 xwa, 10373
	cp wa, 0xFF
	jr z, LABEL_F3FB8B
	inc 1, wa
	stda16 10373, xwa
	jr PartCtrl_RestoreReturn

LABEL_F3FB8B:
	ldda16 xwa, 10375
	calr PartCtrl_ReadWord
	ld iz, hl
	ld wa, iz
	cp wa, 0xFFFF
	jr nz, LABEL_F3FBB0
	ldda16 xwa, 10375
	calr Part_LinkVoiceToChain
	ld iz, hl
	cps iz, 0
	jr ge, PartCtrl_SaveChainPosition
	stdi8 10362, 5
	jr PartCtrl_RestoreReturn

LABEL_F3FBB0:
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, PartCtrl_SaveChainPosition
	stdi8 10362, 2
	jr PartCtrl_RestoreReturn

PartCtrl_SaveChainPosition:
	stda16 10375, xiz
	stdi16 10373, 5

PartCtrl_RestoreReturn:
	popw iz
	ret

PartCtrl_NavigateBackwardAlt:
	pushw iz
	ldda16 xwa, 10373
	cps wa, 5
	jr z, LABEL_F3FBDB
	dec 1, wa
	stda16 10373, xwa
	jr SeqPart_RestoreReturn2

LABEL_F3FBDB:
	ldda16 xwa, 10375
	calr PartCtrl_ReadWord_Off1
	ld iz, hl
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3FBFA
	ldw wa, 0x48
	calr SeqData_SetErrorCode
	stdi8 10362, 2
	jr SeqPart_RestoreReturn2

LABEL_F3FBFA:
	cps iz, 0
	jr z, LABEL_F3FC04
	cp iz, 0xFFFF
	jr nz, LABEL_F3FC0B

LABEL_F3FC04:
	stdi8 10362, 11
	jr SeqPart_RestoreReturn2

LABEL_F3FC0B:
	stda16 10375, xiz
	stdi16 10373, 255

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
	ldda16 xwa, 10377
	ld c, a
	extz bc
	ldda16 xwa, 10379
	jrl PartCtrl_ReadByte

LABEL_F3FC26:
	ldda16 xwa, 10373
	ld c, a
	extz bc
	ldda16 xwa, 10375
	jrl PartCtrl_ReadByte

LABEL_F3FC35:
	ld e, a
	ldda16 xbc, 10377
	extz bc
	extz de
	ldda16 xwa, 10379
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
	ldda16 xbc, 10373
	extz bc
	extz de
	ldda16 xwa, 10375
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
	jr nz, LABEL_F3FC72
	stdi8 10362, 1
	jr PartCtrl_ConfigureAndReturn

LABEL_F3FC72:
	ld c, (xsp + 2)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F3FC8B
	stdi8 10362, 2
	jr PartCtrl_ConfigureAndReturn

LABEL_F3FC8B:
	cp iz, 0x4D8
	jr ule, LABEL_F3FC98
	stdi8 10362, 10
	jr PartCtrl_ConfigureAndReturn

LABEL_F3FC98:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3FCA8
	stdi8 10362, 11
	jr PartCtrl_ConfigureAndReturn

LABEL_F3FCA8:
	stda16 10415, xiz
	stdi16 9830, 5
	stdi8 10362, 0

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
	cpdi8 10362, 0
	jr nz, SeqPart_DecisionReturn
	ld c, (xsp)
	dec 1, c
	extz bc
	ldada xwa, 61976
	ld de, bc
	extz xde
	add xde, xwa
	ld e, (xde)
	extz de
	cps de, 5
	jr c, LABEL_F3FD19
	cp de, 0xFF
	jr ugt, LABEL_F3FD19
	add bc, bc
	ldada xwa, 61944
	extz xbc
	add xbc, xwa
	ld wa, (xbc)
	cp wa, 0x4D8
	jr ule, LABEL_F3FD04
	stdi8 10362, 10
	jr SeqPart_DecisionReturn

LABEL_F3FD04:
	stda16 10415, xwa
	stda16 9830, xde
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F3FD20
	cp l, 0x84
	jr z, LABEL_F3FD20

LABEL_F3FD19:
	stdi8 10362, 11
	jr SeqPart_DecisionReturn

LABEL_F3FD20:
	stdi8 10362, 0

SeqPart_DecisionReturn:
	inc 2, xsp
	ret

LABEL_F3FD28:
	ldda8	a, 10359
	cp	a, 127
	jr	z, 9
	extz	wa
	calr	63694
	cps	hl, 0
	jr	nz, 31
	ldda16	wa, 9778
	calr	63700
	cps	hl, 0
	jr	nz, 20
	ldda16	wa, 9694
	calr	63689
	cps	hl, 0
	jr	nz, 9
	ldda8	a, 9812
	cp	a, 128
	jr	nz, 4
	ldw	hl, 65535
	ret
	lds	hl, 0
	ret

LABEL_F3FD60:
	push_werp 0xFA
	ldda8 a, 9770
	cps a, 0
	jr z, Part_PopRetFA2
	bitda 3, 10363
	jr nz, Part_PopRetFA2
	ldda8 a, 61934
	cp a, 0x11
	jr nz, LABEL_F3FD7C
	ldb a, 0x7F

LABEL_F3FD7C:
	stda8 10359, a
	ldda16 xwa, 61935
	stda16 9778, xwa
	ldda16 xwa, 61935
	addda16 xwa, 9694
	stda16 9862, xwa
	ldi_berp 0xFB, 0
	ldda8 a, 9770
	cps a, 0
	jr ule, Part_PopRetFA2

LABEL_F3FD9F:
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_DualPartLoad
	cpdi8 32578, 35
	jr nz, Part_PopRetFA2
	bitda 3, 10363
	jr nz, Part_PopRetFA2
	ldda16 xwa, 9862
	addda16 xwa, 9694
	stda16 9862, xwa
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cpda8 a, 9770
	jr c, LABEL_F3FD9F

Part_PopRetFA2:
	pop_werp 0xFA
	ret

LABEL_F3FDD6:
	.byte 0xd7, 0xfa, 0x04, 0xc1, 0x30, 0x26, 0x21, 0xc9
	.byte 0xd8, 0x66, 0x67, 0xf1, 0x7b, 0x28, 0xcb, 0x6e
	.byte 0x61, 0xc1, 0xe6, 0xf1, 0x21, 0xc9, 0xcf, 0x11
	.byte 0x6e, 0x02, 0x21, 0x7f, 0xf1, 0x77, 0x28, 0x41
	.byte 0xd1, 0xe7, 0xf1, 0x20, 0xf1, 0x32, 0x26, 0x50
	.byte 0xd1, 0xe7, 0xf1, 0x20, 0xd1, 0xde, 0x25, 0x80
	.byte 0xf1, 0x86, 0x26, 0x50, 0xc7, 0xfb, 0xa8, 0xc1
	.byte 0x30, 0x26, 0x21, 0xc9, 0xd8, 0x63, 0x33, 0xf1
	.byte 0x42, 0x7f, 0x00, 0xff, 0xf1, 0x7a, 0x28, 0x00
	.byte 0x00, 0x1d, 0x5a, 0xa9, 0xf4, 0xc1, 0x42, 0x7f
	.byte 0x3f, 0x23, 0x6e, 0x1e, 0xf1, 0x7b, 0x28, 0xcb
	.byte 0x6e, 0x18, 0xd1, 0x86, 0x26, 0x20, 0xd1, 0xde
	.byte 0x25, 0x80, 0xf1, 0x86, 0x26, 0x50, 0xc7, 0xfb
	.byte 0x61, 0xc7, 0xfb, 0x89, 0xc1, 0x30, 0x26, 0xf1
	.byte 0x67, 0xcd, 0xd7, 0xfa, 0x05, 0x0e

SeqVoice_SeekToBar:
	push xiz
	lds iz, 1
	ldi_werp 0xFA, 0
	stdi8 10362, 0
	stda8 10381, c
	extz wa
	calr Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jr nz, SeqVoice_PopIzRet2
	calr SeqVoice_ValidateAndProcessState
	cpdi16 10367, 1
	jr z, SeqVoice_PopIzRet2

LABEL_F3FE72:
	ldda8 a, 10382
	extz wa
	ldto_werp BC, 0xFA
	calr SeqData_SkipSections
	ldfr_werp HL, 0xFA
	cpdi8 10362, 0
	jr nz, SeqVoice_PopIzRet2
	inc 1, iz
	calr SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr nz, SeqVoice_PopIzRet2
	cpda16 xiz, 10367
	jr nz, LABEL_F3FE72

SeqVoice_PopIzRet2:
	pop xiz
	ret

SeqData_SkipSections:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), bc
	ld (xsp + 4), a
	ldi_berp 0xFB, 0
	cp (xsp + 4), 0x0
	jr z, SeqData_UpdatePositionAndReturn

LABEL_F3FEB0:
	calr SeqData_ReadNextByte
	cp l, 0x84
	jr z, LABEL_F3FEBD
	cp l, 0x82
	jr nz, LABEL_F3FEC4

LABEL_F3FEBD:
	stdi8 10362, 8
	jr SeqData_UpdatePositionAndReturn

LABEL_F3FEC4:
	cp l, 0x81
	jr nz, LABEL_F3FED8
	inc1_berp 0xFB
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, LABEL_F3FEE3
	jr SeqData_UpdatePositionAndReturn

LABEL_F3FED8:
	call SeqData_ReadParamBlock
	cpdi8 10362, 0
	jr nz, SeqData_UpdatePositionAndReturn

LABEL_F3FEE3:
	ldto_berp A, 0xFB
	cp a, (xsp + 4)
	jr nz, LABEL_F3FEB0

SeqData_UpdatePositionAndReturn:
	ldto_berp A, 0xFB
	extz wa
	add wa, (xsp + 2)
	ld hl, wa
	pop_werp 0xFA
	inc 4, xsp
	ret

SeqVoice_SetDefaultParams:
	stdi8 10401, 16
	stdi8 10398, 15
	ldmm16 10402, 10349
	ldda32 xwa, 7514
	stda32 3304, xwa
	stdi16 3376, 0
	ret

SeqVoice_InitReturnZero:
	lds wa, 0
	jrl Part_InitVoiceDefaults

LABEL_F3FF1F:
	ld xwa, 0xE445A6
	jr Part_LoadAndApplyVoiceTable
	ld xwa, 0xE445B2
	jr Part_LoadAndApplyVoiceTable

LABEL_F3FF2D:
	ld xwa, 0xE445BE
	jr Part_LoadAndApplyVoiceTable

Part_ApplyVoiceTableA:
	ld xwa, 0xE445CA
	jr Part_LoadAndApplyVoiceTable

LABEL_F3FF3B:
	ld xwa, 0xE445D6
	jr Part_LoadAndApplyVoiceTable

SeqVoice_ApplyTableEntry:
	ld xwa, 0xE4459A
	jr __jrt_nop_F3FF49
__jrt_nop_F3FF49:

Part_LoadAndApplyVoiceTable:
	ldda8 c, 10362
	extz bc
	ldmm_srib 0x07, 0xE0, 0xE4, 0x42, 0x7F
	ret

Part_ValidateAndSetupVoiceChannel:
	dec 4, xsp
	pushw iz
	ld (xsp + 4), a
	ld a, (xsp + 4)
	extz wa
	calr Part_ValidateVoiceChannel
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F3FF78
	cps a, 1
	jr nz, LABEL_F3FF76
	stdi8 10362, 0

LABEL_F3FF76:
	jr SeqData_TrackProcessComplete

LABEL_F3FF78:
	stdi8 10362, 0
	ld c, (xsp + 4)
	dec 1, c
	extz bc
	ldada xwa, 61976
	ld de, bc
	extz xde
	add xde, xwa
	ld a, (xde)
	ld (xsp + 2), a
	cp (xsp + 2), 0x5
	jr c, LABEL_F3FFBB
	add bc, bc
	ldada xwa, 61944
	extz xbc
	add xbc, xwa
	ld iz, (xbc)
	cp iz, 0x4D8
	jr ule, LABEL_F3FFB2
	stdi8 10362, 10
	jr SeqData_TrackProcessComplete

LABEL_F3FFB2:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F3FFC2

LABEL_F3FFBB:
	stdi8 10362, 11
	jr SeqData_TrackProcessComplete

LABEL_F3FFC2:
	stda16 10415, xiz
	ld a, (xsp + 2)
	extz wa
	stda16 9830, xwa
	calr SeqData_ReadNextByte
	cp l, 0x84
	jr nz, SeqData_TrackProcessComplete
	stdi8 10362, 6

SeqData_TrackProcessComplete:
	popw iz
	inc 4, xsp
	ret

SeqData_ScanAllTracks:
	push xiz
	lds iz, 0
	lds32 xwa, 1
	stda32 9690, xwa
	resda 1, 10363
	cpdi16 9694, 0
	jr z, SeqData_PopIzRet

LABEL_F3FFF5:
	ldi_werp 0xFA, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, LABEL_F4003E

LABEL_F40002:
	bitda 1, 10363
	jr z, LABEL_F40018
	lds32 xwa, 1
	adddm32 9690, xwa
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqData_PopIzRet

LABEL_F40018:
	setda 1, 10363
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr nz, LABEL_F4002B
	stdi8 10362, 7
	jr SeqData_PopIzRet

LABEL_F4002B:
	cp l, 0x81
	jr nz, LABEL_F40033
	inc1_werp 0xFA

LABEL_F40033:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, LABEL_F40002

LABEL_F4003E:
	inc 1, iz
	calr SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr nz, SeqData_PopIzRet
	cpda16 xiz, 9694
	jr nz, LABEL_F3FFF5

SeqData_PopIzRet:
	pop xiz
	ret

; ============================================================================
; SeqData_AdvancePosition - Advance read position in sequence data
; ============================================================================
; Increments position counter at address 9830. When it reaches 0xFF,
; advances the data pointer (10415) to the next block, validating:
;   0xFFFF = end of data, > 0x4D8 = overflow error
; Sets error codes in 10362 (values 8, 10, 11, 0).
; ============================================================================
SeqData_AdvancePosition:
	pushw iz
	ldda16 xwa, 9830
	inc 1, wa
	stda16 9830, xwa
	cp wa, 0xFF
	jr ule, SeqData_PopIzRet2
	ldda16 xwa, 10415
	calr PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F40079
	stdi8 10362, 8
	jr SeqData_PopIzRet2

LABEL_F40079:
	cp iz, 0x4D8
	jr ule, LABEL_F40086
	stdi8 10362, 10
	jr SeqData_PopIzRet2

LABEL_F40086:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F40096
	stdi8 10362, 11
	jr SeqData_PopIzRet2

LABEL_F40096:
	stda16 10415, xiz
	stdi16 9830, 5
	stdi8 10362, 0

SeqData_PopIzRet2:
	popw iz
	ret

SeqVoice_FindDrumPartIndex:
	ldda8 a, 10363
	res 2, a
	stda8 10363, a
	ldb l, 0x0
	ldada xde, 61856

LABEL_F400B8:
	ld c, l
	extz bc
	extz xbc
	add xbc, xde
	cp (xbc), 0x10
	jr nz, LABEL_F400CF
	set 2, a
	stda8 10363, a
	inc 1, l
	ret

LABEL_F400CF:
	inc 1, l
	cp l, 0x10
	jr c, LABEL_F400B8
	ldb l, 0x0
	ret

SeqVoice_ValidateAndProcessState:
	push xiz
	ldmm8 10382, 1075
	bitda 2, 10363
	jrl z, LABEL_F40193
	ldda8 a, 10381
	dec 1, a
LABEL_F400ED:
	stda8 9696, a
	ldda16 xiz, 10415
	ldda16 xwa, 9830
	ldfr_werp WA, 0xFA
	ldda8 a, 10381
	extz wa
	calr Part_ValidateVoiceChannel
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F40118
	resda 2, 10363
	stdi8 10362, 0
	jr LABEL_F40188

LABEL_F40118:
	ldmm16 9698, 10415
	ldmm16 10395, 9830
	ldmm16 9700, 10415
	stdi16 9830, 5

SeqData_RhythmDispatchLoop:
	calr SeqData_ReadNextByte
	ld a, l
	and a, 0xF0
	cp a, 0xC0
	jr nz, LABEL_F4016B
	calr SeqData_ReadParamBlockAlt
	ldada xbc, 9606
	cp (xbc + 2), 0x48
	jr nz, SeqData_RhythmDispatchLoop
	cp (xbc + 3), 0x0
	jr nz, SeqData_RhythmDispatchLoop
	bitm 0, (xbc)
	jr z, LABEL_F40157
	setm 7, (xbc + 4)

LABEL_F40157:
	ld a, (xbc + 4)
	extz wa
	ld c, (xbc + 5)
	extz bc
	call Rhythm_NoteDispatchWrapper
	stda8 10382, l
	jr SeqData_RhythmDispatchLoop

LABEL_F4016B:
	ldda8 a, 1075
	cp l, 0x82
	jr nz, LABEL_F40195

LABEL_F40174:
	stda8 10382, a
	setda 5, 10363

LABEL_F4017C:
	ldmm16 9698, 10415
	ldmm16 10395, 9830

LABEL_F40188:
	stda16 10415, xiz
	ldto_werp WA, 0xFA
	stda16 9830, xwa

LABEL_F40193:
	pop xiz
	ret

LABEL_F40195:
	cp l, 0x84
	jr z, LABEL_F40174
	cp l, 0x81
	jr z, LABEL_F4017C
	calr SeqData_ReadParamBlockAlt
	jr SeqData_RhythmDispatchLoop

SeqTrack_ProcessControlBytes:
	push xiz
	stdi8 10362, 0
	ldda8 a, 10363
	bit 2, a
	jrl z, LABEL_F4023B
	bit 5, a
	jrl nz, LABEL_F4023B
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830

LABEL_F401C5:
	ldmm16 10415, 9698
	ldmm16 9830, 10395

LABEL_F401D1:
	calr SeqData_ReadNextByte
	ld a, l
	and a, 0xF0
	cp a, 0xC0
	jr nz, LABEL_F40207
	calr SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr nz, SeqData_SaveIndexReturn
	ldada xbc, 9606
	bitm 0, (xbc)
	jr z, LABEL_F401F3
	setm 7, (xbc + 4)

LABEL_F401F3:
	ld a, (xbc + 4)
	extz wa
	ld c, (xbc + 5)
	extz bc
	call Rhythm_NoteDispatchWrapper
	stda8 10382, l
	jr LABEL_F401D1

LABEL_F40207:
	cp l, 0x82
	jr nz, LABEL_F40212
	setda 5, 10363
	jr SeqData_SaveIndexReturn

LABEL_F40212:
	cp l, 0x84
	jr z, LABEL_F401C5
	cp l, 0x81
	jr nz, LABEL_F40221
	calr LABEL_F4023D
	jr SeqData_SaveIndexReturn

LABEL_F40221:
	calr SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr z, LABEL_F401D1

SeqData_SaveIndexReturn:
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz
	stdi8 10362, 0

LABEL_F4023B:
	pop xiz
	ret

LABEL_F4023D:
	push xiz
	lds iz, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, LABEL_F40284

LABEL_F4024A:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x82
	jr z, LABEL_F40290
	cp_erpb 0xFB, 0x81
	jr nz, LABEL_F40268
	inc 1, iz
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, LABEL_F402A0

LABEL_F40268:
	cp_erpb 0xFB, 0x84
	jr nz, LABEL_F40296
	ldmm16 10415, 9700
	stdi16 9830, 5

LABEL_F4027A:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jr nz, LABEL_F4024A

LABEL_F40284:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x82
	jr nz, LABEL_F402AB

LABEL_F40290:
	setda 5, 10363
	jr LABEL_F402C9

LABEL_F40296:
	calr SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr z, LABEL_F4027A

LABEL_F402A0:
	setda 5, 10363
	stdi8 10362, 0
	jr LABEL_F402C9

LABEL_F402AB:
	cp_erpb 0xFB, 0x84
	jr nz, LABEL_F402BD
	ldmm16 10415, 9700
	stdi16 9830, 5

LABEL_F402BD:
	ldmm16 10395, 9830
	ldmm16 9698, 10415

LABEL_F402C9:
	pop xiz
	ret

SeqData_ReadParamBlockAlt:
	pushw iz
	lds iz, 0
	calr SeqData_ReadNextByte
	stda8 9606, l
	cp l, 0x82
	jr z, LABEL_F40303
	cp l, 0x84
	jr z, LABEL_F40303

LABEL_F402DF:
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, LABEL_F40308
	calr SeqData_ReadNextByte
	bit 7, l
	jr nz, LABEL_F40308
	ld bc, iz
	ldada xwa, 9607
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cps iz, 7
	jr ule, LABEL_F402DF

LABEL_F40303:
	stdi8 10362, 1

LABEL_F40308:
	popw iz
	ret

LABEL_F4030A:
	push_werp 0xFA
	stdi8 10362, 0
	ldi_berp 0xFB, 1
	cpdi8 10401, 1
	jr c, SeqPart_RestoreReturn

LABEL_F4031C:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ldda8 a, 10362
	cps a, 0
	jr nz, LABEL_F4035C
	calr SeqVoice_FindDrumPartIndex
	ldmm16 10367, 9778
	ldda8 a, 9780
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F4036A
	cps a, 1
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr z, SeqData_ClearAndLoop
	jr SeqPart_RestoreReturn

LABEL_F4035C:
	cps a, 1
	jr z, SeqData_ClearAndLoop
	cp a, 0x8
	jr nz, SeqPart_RestoreReturn

SeqData_ClearAndLoop:
	stdi8 10362, 0

LABEL_F4036A:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cpda8 a, 10401
	jr ule, LABEL_F4031C

SeqPart_RestoreReturn:
	pop_werp 0xFA
	ret

LABEL_F4037A:
	.byte 0xf1, 0xfa, 0x25, 0x02, 0x01, 0x00, 0xf1, 0xfc
	.byte 0x25, 0x02, 0x01, 0x00, 0xf1, 0x26, 0x26, 0x02
	.byte 0x01, 0x00, 0xf1, 0x28, 0x26, 0x02, 0x01, 0x00
	.byte 0xf1, 0x2c, 0x26, 0x02, 0x01, 0x00, 0xf1, 0x2e
	.byte 0x26, 0x02, 0x01, 0x00, 0x0e

Part_WriteWordAndByte:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), c
	ld iz, wa
	ldda16 xwa, 10365
	ld c, a
	extz bc
	lds wa, 0
	ld de, iz
	calr Part_WriteWord_Indexed
	ldda16 xwa, 10365
	ld c, a
	extz bc
	ld e, (xsp + 2)
	extz de
	lds wa, 0
	calr Part_WriteByte_Indexed
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda16 xbc, 10365
	extz bc
	ld de, iz
	calr Part_WriteWord_Indexed
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda16 xbc, 10365
	extz bc
	ld e, (xsp + 2)
	extz de
	calr Part_WriteByte_Indexed
	popw iz
	inc 2, xsp
	ret

LABEL_F403F7:
	pushw iz
	ldda8 a, 9780
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	jr nz, LABEL_F40416
	ld xwa, 0xA
	adddm32 9690, xwa

LABEL_F40416:
	ldw iz, 0xFF
	ldda8 c, 9780
	extz bc
	lds wa, 0
	calr Part_ReadWord_Indexed
	sub iz, hl
	ld wa, iz
	extz xwa
	ldda32 xhl, 9690
	cp xhl, xwa
	jr ugt, LABEL_F4043A
	lds32 xwa, 0
	stda32 9914, xwa
	jr LABEL_F40453

LABEL_F4043A:
	sub xhl, xwa
	add xhl, 0xFB
	dec 1, xhl
	ld xwa, xhl
	ld xbc, 0xFB
	call Math_DivideU32
	stda32 9914, xhl

LABEL_F40453:
	ldda32 xwa, 9914
	stda16 9930, xwa
	popw iz
	ret

LABEL_F4045D:
	.byte 0xd7, 0xfa, 0x04, 0xd1, 0x31, 0xf2, 0x19, 0xcc
	.byte 0x26, 0xf1, 0x7a, 0x28, 0x00, 0x00, 0xc7, 0xfb
	.byte 0xa9, 0xc1, 0xa1, 0x28, 0x3f, 0x01, 0x77, 0xba
	.byte 0x00, 0xc7, 0xfb, 0x89, 0xf1, 0x34, 0x26, 0x41
	.byte 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0x1e, 0x36, 0xf8
	.byte 0xc1, 0x7a, 0x28, 0x21, 0xc9, 0xd8, 0x66, 0x0c
	.byte 0xc9, 0xcf, 0x08, 0x66, 0x31, 0xc9, 0xd9, 0x66
	.byte 0x2d, 0x78, 0x97, 0x00, 0x1e, 0x0b, 0xfc, 0xd1
	.byte 0x86, 0x26, 0x19, 0x7f, 0x28, 0xc1, 0x34, 0x26
	.byte 0x21, 0xc7, 0xfb, 0x99, 0xd8, 0x12, 0xdb, 0x12
	.byte 0xdb, 0x89, 0x1e, 0x9a, 0xf9, 0xc1, 0x7a, 0x28
	.byte 0x21, 0xc9, 0xd8, 0x66, 0x10, 0xc9, 0xcf, 0x08
	.byte 0x66, 0x04, 0xc9, 0xd9, 0x6e, 0x6d, 0xf1, 0x7a
	.byte 0x28, 0x00, 0x00, 0x68, 0x59, 0xd1, 0x32, 0x26
	.byte 0x19, 0x7f, 0x28, 0xc1, 0x8d, 0x28, 0x27, 0xc1
	.byte 0x34, 0x26, 0x21, 0xc7, 0xfb, 0x99, 0xd8, 0x12
	.byte 0xdb, 0x12, 0xdb, 0x89, 0x1e, 0x68, 0xf9, 0xc1
	.byte 0x7a, 0x28, 0x21, 0xc9, 0xd8, 0x66, 0x07, 0xc9
	.byte 0xcf, 0x08, 0x66, 0xd2, 0x68, 0x3d, 0x1e, 0xea
	.byte 0xfa, 0xc1, 0x7a, 0x28, 0x21, 0xc9, 0xd8, 0x66
	.byte 0x09, 0xc9, 0xdf, 0x6e, 0x19, 0xf1, 0x7a, 0x28
	.byte 0x00, 0x00, 0x1e, 0xed, 0xfe, 0xd1, 0xcc, 0x26
	.byte 0x20, 0xd1, 0xca, 0x26, 0x21, 0xd9, 0xf0, 0x6f
	.byte 0x07, 0xf1, 0x7a, 0x28, 0x00, 0x05, 0x68, 0x13
	.byte 0xd9, 0xa0, 0xf1, 0xcc, 0x26, 0x50, 0xc7, 0xfb
	.byte 0x61, 0xc7, 0xfb, 0x89, 0xc1, 0xa1, 0x28, 0xf1
	.byte 0x73, 0x46, 0xff, 0xd7, 0xfa, 0x05, 0x0e

LABEL_F40534:
	ldda8 c, 9780
	extz bc
	lds wa, 0
	calr Part_ReadByte_Indexed
	ld wa, hl
	dec 5, wa
	extz xwa
	ldda32 xhl, 9690
	cp xhl, xwa
	jr ugt, LABEL_F40551
	lds32 xhl, 0
	jr LABEL_F40560

LABEL_F40551:
	sub xhl, xwa
	ld xwa, xhl
	ld xbc, 0xFB
	call Math_DivideU32
	inc 1, xhl

LABEL_F40560:
	stda16 9930, xhl
	ret

SeqPart_CopyDataPrimary:
	dec 4, xsp
	push xiz
	ldda16 xiz, 10379
	ldda16 xwa, 10377
	ldfr_werp WA, 0xFA
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	ldada xwa, 10284
	mriw4 0x90, 0x19, 0x8B, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	ldada xwa, 10288
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	stdi8 10362, 0

LABEL_F4059C:
	ldada xbc, 10292
	ldda16 xwa, 10379
	cp wa, (xbc)
	jr nz, LABEL_F405C7
	ldda16 xwa, 10377
	cp wa, (xbc + 2)
	jr nz, LABEL_F405C7
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr z, LABEL_F405E7
	jr SeqPart_SaveIndexReturn

LABEL_F405C7:
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqPart_SaveIndexReturn
	calr PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr z, LABEL_F4059C
	jr SeqPart_SaveIndexReturn

LABEL_F405E7:
	ldada xbc, 10292
	ldda16 xwa, 10375
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2885

SeqPart_SaveIndexReturn:
	stda16 10379, xiz
	ldto_werp WA, 0xFA
	stda16 10377, xwa
	mrdw5 0x9F, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9F, 0x04, 0x19, 0x85, 0x28
	pop xiz
	inc 4, xsp
	ret

SeqPart_CopyDataSecondary:
	dec 4, xsp
	push xiz
	ldda16 xiz, 10379
	ldda16 xwa, 10377
	ldfr_werp WA, 0xFA
	ldmw2 (xsp + 6), 0x2887
	ldmw2 (xsp + 4), 0x2885
	ldada xwa, 10284
	mriw4 0x90, 0x19, 0x8B, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x89, 0x28
	ldada xwa, 10288
	mriw4 0x90, 0x19, 0x87, 0x28
	mrdw5 0x98, 0x02, 0x19, 0x85, 0x28
	stdi8 10362, 0

LABEL_F40646:
	ldada xbc, 10292
	ldda16 xwa, 10379
	cp wa, (xbc)
	jr nz, LABEL_F40676
	ldda16 xwa, 10377
	cp wa, (xbc + 2)
	jr nz, LABEL_F40676
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	ldada xbc, 10292
	ldda16 xwa, 10375
	ld (xbc), wa
	ldmw2 (xbc + 2), 0x2885
	jr LABEL_F40694

LABEL_F40676:
	calr SeqPart_ReadByte_Secondary
	extz hl
	ld wa, hl
	calr SeqPart_WriteByte_Primary
	calr PartCtrl_NavigateBackward
	cpdi8 10362, 0
	jr nz, LABEL_F40694
	calr PartCtrl_NavigateBackwardAlt
	cpdi8 10362, 0
	jr z, LABEL_F40646

LABEL_F40694:
	stda16 10379, xiz
	ldto_werp WA, 0xFA
	stda16 10377, xwa
	mrdw5 0x9F, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9F, 0x04, 0x19, 0x85, 0x28
	pop xiz
	inc 4, xsp
	ret

SeqBuf_ComputePageLayout:
	dec 2, xsp
	push xiz
	ld xbc, 0xFF
	ldda16 xwa, 9890
	extz xwa
	sub xbc, xwa
	ldda32 xwa, 9690
	cp xwa, xbc
	jr ugt, LABEL_F406E2
	stdi16 9882, 0
	ldda16 xwa, 9890
	extz xwa
	addda32 xwa, 9690
	stda32 9914, xwa
	ldmm16 9912, 9884
	jrl LABEL_F40779

LABEL_F406E2:
	sub xwa, xbc
	stda32 9922, xwa
	add xwa, 0xFB
	dec 1, xwa
	ld xbc, 0xFB
	call Math_DivideU32
	ld iz, hl
	stda16 9882, xiz
	ld wa, iz
	extz xwa
	ld xbc, 0xFB
	call Math_MultiplyAccumulate
	subda32 xhl, 9922
	ldb a, 0xFB
	sub a, l
	inc 4, a
	ldb w, 0x0
	extz xwa
	stda32 9914, xwa
	cpda16 xiz, 62001
	jr ugt, LABEL_F40746
	ldda16 xiz, 9884
	stda16 9912, xiz
	ldw (xsp + 4), 0x0
	cpdi16 9882, 0
	jr ule, LABEL_F40775

LABEL_F40739:
	calr PartCtrl_ReadWordRoutine
	ldfr_werp HL, 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr nz, LABEL_F4074D

LABEL_F40746:
	stdi8 10362, 5
	jr LABEL_F40779

LABEL_F4074D:
	ld wa, iz
	ldto_werp BC, 0xFA
	calr PartCtrl_WriteWord
	ldto_werp WA, 0xFA
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	ldto_werp WA, 0xFA
	ld bc, iz
	calr PartCtrl_WriteWord_Off1
	ldto_werp IZ, 0xFA
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cpda16 xwa, 9882
	jr c, LABEL_F40739

LABEL_F40775:
	stda16 9912, xiz

LABEL_F40779:
	pop xiz
	inc 2, xsp
	ret

LABEL_F4077D:
	push_werp 0xFA
	ldda8 a, 10363
	res 3, a
	res 4, a
	stda8 10363, a
	ldmm16 9932, 62001
	stdi8 10362, 0
	ldi_berp 0xFB, 1
	cpdi8 10401, 1
	jrl c, SeqPart_PopRetFA

LABEL_F407A4:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	extz wa
	calr Part_ValidateVoiceAndSetupSeq
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F407C9
	cps a, 1
	jrl z, SeqData_ClearError
	cp a, 0x8
	jrl z, SeqData_ClearError
	jrl SeqPart_PopRetFA

LABEL_F407C9:
	calr SeqVoice_FindDrumPartIndex
	ldmm16 10367, 9862
	ldda8 a, 9780
	ldfr_berp A, 0xFB
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F40803
	cps a, 1
	jr z, SeqData_ClearError
	cp a, 0x8
	jr nz, SeqPart_PopReturn
	ldda16 xwa, 9778
	cpda16 xwa, 9862
	jrl ugt, SeqPart_PopRetFA
	stdi8 10362, 0

LABEL_F40803:
	calr SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F4081B
	cps a, 7
	jr nz, SeqPart_PopReturn
	setda 4, 10363
	stdi8 10362, 0

LABEL_F4081B:
	ldda32 xwa, 9690
	stda32 9934, xwa
	ldmm16 10367, 9778
	ldda8 l, 10381
	ldda8 a, 9780
	ldfr_berp A, 0xFB
	extz wa
	extz hl
	ld bc, hl
	calr SeqVoice_SeekToBar
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F40855
	cp a, 0x8
	jr nz, SeqPart_PopReturn

SeqData_ClearError:
	stdi8 10362, 0
	jrl SeqVoice_AdvanceReadLoop

SeqPart_PopReturn:
	jrl SeqPart_PopRetFA

LABEL_F40855:
	calr SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, LABEL_F4086E
	cps a, 7
	jrl nz, SeqPart_PopRetFA
	setda 3, 10363
	stdi8 10362, 0

LABEL_F4086E:
	ldda32 xwa, 9934
	ldda32 xbc, 9690
	cp xwa, xbc
	jr ule, LABEL_F408AD
	sub xwa, xbc
	stda32 9934, xwa
	ldda8 a, 10363
	bit 4, a
	jr z, LABEL_F40898
	bit 3, a
	jr nz, LABEL_F40898
	ldda32 xwa, 9934
	dec 1, xwa
	stda32 9934, xwa

LABEL_F40898:
	ldda32 xwa, 9934
	stda32 9690, xwa
	calr LABEL_F40534
	ldda16 xwa, 9930
	adddm16 9932, xwa
	jr SeqVoice_AdvanceReadLoop

LABEL_F408AD:
	cp xwa, xbc
	jr nc, SeqVoice_AdvanceReadLoop
	sub xbc, xwa
	stda32 9690, xbc
	ldda8 a, 10363
	bit 4, a
	jr z, LABEL_F408CF
	bit 3, a
	jr nz, LABEL_F408CF
	ldda32 xwa, 9690
	inc 1, xwa
	stda32 9690, xwa

LABEL_F408CF:
	calr LABEL_F403F7
	ldda16 xwa, 9932
	ldda16 xbc, 9930
	cp wa, bc
	jr ugt, LABEL_F408E5
	stdi8 10362, 5
	jr SeqPart_PopRetFA

LABEL_F408E5:
	sub wa, bc
	stda16 9932, xwa

SeqVoice_AdvanceReadLoop:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cpda8 a, 10401
	jrl ule, LABEL_F407A4

SeqPart_PopRetFA:
	pop_werp 0xFA
	ret

SeqPart_CountActiveVoices:
	push xiz
	cpda8_24 a, 65507
	jr nz, LABEL_F40909
	ldi_berp 0xFB, 0
	jr LABEL_F4090E

LABEL_F40909:
	inc 1, a
	ldfr_berp A, 0xFB

LABEL_F4090E:
	lds iz, 0
	ldi_berp 0xFA, 1

LABEL_F40913:
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	calr Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F40933
	ldto_berp A, 0xFB
	extz wa
	ldto_berp C, 0xFA
	extz bc
	calr LABEL_F40995
	add iz, hl

LABEL_F40933:
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x10
	jr ule, LABEL_F40913
	cps iz, 0
	jr nz, LABEL_F4094D
	stdi8 10348, 0
	stdi16 10024, 0
	jr LABEL_F40993

LABEL_F4094D:
	ldw de, 0x4D8
	cp iz, 0x4D8
	jr ule, LABEL_F40959
	ldw iz, 0x4D8

LABEL_F40959:
	ld bc, iz

LABEL_F4095B:
	srl de, 1
	srl iz, 1
	cp de, 0x258
	jr ugt, LABEL_F4095B
	mul iz, 0x64
	extz xiz
	div xiz, xde
	cp iz, 0x64
	jr nz, LABEL_F40979
	dec 1, iz
	jr LABEL_F4097F

LABEL_F40979:
	cps iz, 0
	jr nz, LABEL_F4097F
	inc 1, iz

LABEL_F4097F:
	ldto_berp A, 0xF8
	stda8 10348, a
	ld iz, bc
	srl iz, 2
	jr nz, LABEL_F4098F
	inc 1, iz

LABEL_F4098F:
	stda16 10024, xiz

LABEL_F40993:
	pop xiz
	ret

LABEL_F40995:
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
	cp iz, 0xFFFF
	jr z, LABEL_F409C4
	ld a, (xsp + 6)
	extz wa
	ld c, (xsp + 4)
	extz bc
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F409C8

LABEL_F409C4:
	lds hl, 0
	jr LABEL_F409EF

LABEL_F409C8:
	ldw (xsp + 2), 0x1
	cp iz, 0xFFFF
	jr z, LABEL_F409EC

LABEL_F409D3:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr z, LABEL_F409EC
	ld wa, iz
	calr PartCtrl_ReadWord
	ld iz, hl
	incm 1, (xsp + 2)
	cp iz, 0xFFFF
	jr nz, LABEL_F409D3

LABEL_F409EC:
	ld hl, (xsp + 2)

LABEL_F409EF:
	popw iz
	inc 6, xsp
	ret

SeqData_CopyBlockWithLookup:
	lda xsp, (xsp - 34)
	ld xiy, 0xE44600
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	ldda8 a, 10360
	cp a, 0xA
	jr nz, LABEL_F40A22
	lda xde, (xsp)
	ldada xwa, 9706
	ld xbc, xwa
	lda xhl, (xwa + 16)

LABEL_F40A16:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F40A16
	jr LABEL_F40A4D

LABEL_F40A22:
	cpdm8_24 65507, a
	jr nz, LABEL_F40A2D
	ldb a, 0x0
	jr LABEL_F40A2F

LABEL_F40A2D:
	inc 1, a

LABEL_F40A2F:
	extz wa
	lda xbc, (xsp + 16)
	calr SeqData_CopyBlock2K
	lda xde, (xsp + 16)
	ldada xwa, 9706
	ld xbc, xwa
	lda xhl, (xwa + 16)

LABEL_F40A43:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	cp xbc, xhl
	jr c, LABEL_F40A43

LABEL_F40A4D:
	lda xsp, (xsp + 34)
	ret

LABEL_F40A51:
	.byte 0xd7, 0xfa, 0x04, 0x1e, 0x8d, 0x00, 0x1e, 0x4d
	.byte 0xf6, 0xc7, 0xfb, 0x9f, 0xc7, 0xfb, 0xd8, 0x66
	.byte 0x7b, 0xc7, 0xfb, 0x89, 0xf1, 0x40, 0x27, 0x41
	.byte 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xf1, 0x7d, 0x28
	.byte 0x50, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0x1e, 0x41
	.byte 0xf2, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x5c
	.byte 0xd1, 0x66, 0x26, 0x19, 0x5e, 0x26, 0xd1, 0xaf
	.byte 0x28, 0x19, 0x5c, 0x26, 0xd1, 0x32, 0x26, 0x19
	.byte 0x7f, 0x28, 0xc7, 0xfb, 0x8b, 0xd9, 0x12, 0xd9
	.byte 0x88, 0x1e, 0xaf, 0xf3, 0xc1, 0x7a, 0x28, 0x3f
	.byte 0x00, 0x6e, 0x39, 0xd1, 0x32, 0x26, 0x20, 0xd1
	.byte 0xde, 0x25, 0x80, 0xf1, 0x7f, 0x28, 0x50, 0xc7
	.byte 0xfb, 0x8b, 0xd9, 0x12, 0xd9, 0x88, 0x1e, 0x92
	.byte 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x1c
	.byte 0x1e, 0xe2, 0x16, 0xcf, 0xcf, 0x82, 0x66, 0x14
	.byte 0xd1, 0x32, 0x26, 0x19, 0xda, 0x26, 0xd1, 0xde
	.byte 0x25, 0x19, 0xdc
	.asciz "&@,'"
	.byte 0x00, 0x1e, 0x20, 0x00, 0x1e, 0x66, 0x2f, 0xd7
	.byte 0xfa, 0x05, 0x0e

LABEL_F40AE4:
	ldada xde, 10034
	ld xwa, xde
	ldada xbc, 10028
	inc 6, xde

LABEL_F40AF0:
	stib_dpi 0xE4, 0x00
	stib_dpi 0xE0, 0x00
	cp xwa, xde
	jr c, LABEL_F40AF0
	ret

SeqVoice_SeekAndScanTracks:
	dec 6, xsp
	push xiz
	ld (xsp + 6), xwa
	ldda8 c, 10048
	ldmm16 10367, 9946
	extz bc
	ld wa, bc
	calr SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqVoice_WriteErrorAndReturn
	ldmm16 10377, 9830
	ldmm16 10379, 10415
	ldw (xsp + 4), 0x0
	cpdi16 9948, 0
	jrl z, SeqVoice_WriteErrorAndReturn

LABEL_F40B36:
	lds iz, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, LABEL_F40BAF

LABEL_F40B42:
	calr SeqPart_ReadByte_Secondary
	cp l, 0x81
	jr nz, LABEL_F40B58
	inc 1, iz
	calr PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, LABEL_F40BA5
	jr SeqVoice_WriteErrorAndReturn

LABEL_F40B58:
	cp l, 0x82
	jr z, SeqVoice_WriteErrorAndReturn
	ld a, l
	and a, 0xF0
	cp a, 0xC0
	jr nz, SeqTrack_ProcessLoop
	cps iz, 0
	jr nz, SeqTrack_ProcessLoop
	ldi_berp 0xFB, 0

LABEL_F40B6E:
	ldto_berp C, 0xFB
	extz bc
	ld xwa, (xsp + 6)
	lda_dri3 XSP, 0x07, 0xE0, 0xE4
	calr PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, SeqVoice_WriteErrorAndReturn
	calr SeqPart_ReadByte_Secondary
	bit 7, l
	jr z, LABEL_F40B9A
	cpi_berp 0xFB, 5
	jr z, LABEL_F40B9A
	ld xwa, (xsp + 6)
	calr LABEL_F40BC6
	jr SeqTrack_ProcessLoop

LABEL_F40B9A:
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr ule, LABEL_F40B6E

SeqTrack_ProcessLoop:
	calr PartCtrl_AdvanceReadPos

LABEL_F40BA5:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jr nz, LABEL_F40B42

LABEL_F40BAF:
	incm 1, (xsp + 4)
	calr SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cpda16 xwa, 9948
	jrl nz, LABEL_F40B36

SeqVoice_WriteErrorAndReturn:
	calr SeqPlay_WriteErrorToVoiceTable
	pop xiz
	inc 6, xsp
	ret

LABEL_F40BC6:
	ld xbc, xwa
	inc 6, xwa

LABEL_F40BCA:
	stib_dpi 0xE4, 0x00
	cp xbc, xwa
	jr c, LABEL_F40BCA
	ret

LABEL_F40BD3:
	ldda8 a, 10359
	cp a, 0x11
	jr z, LABEL_F40BE5
	extz wa
	calr Seq_ValidatePartNumber
	cps hl, 0
	jr nz, LABEL_F40BFB

LABEL_F40BE5:
	ldda16 xwa, 9778
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr nz, LABEL_F40BFB
	ldda16 xwa, 9694
	calr Seq_ValidateTempoValue
	cps hl, 0
	jr z, LABEL_F40BFF

LABEL_F40BFB:
	ldw hl, 0xFFFF
	ret

LABEL_F40BFF:
	lds hl, 0
	ret

SeqVoice_CountEventsInBar:
	dec 8, xsp
	ld (xsp + 6), a
	calr SeqVoice_SetDefaultParams
	stdi8 10362, 0
	stdi8 10381, 0
	ld a, (xsp + 6)
	extz wa
	calr Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jr z, LABEL_F40C28
	ldw hl, 0xFFFF
	jr LABEL_F40C89

LABEL_F40C28:
	calr SeqVoice_ValidateAndProcessState
	ldw (xsp + 2), 0x1
	ldw (xsp + 4), 0x0
	ldw (xsp), 0x0
	cpdi16 3299, 0
	jr z, SeqData_EOL_Cleanup

LABEL_F40C41:
	ldda8 a, 10382
	extz wa
	cp wa, (xsp)
	jr nz, LABEL_F40C55
	incm 1, (xsp + 2)
	calr SeqTrack_ProcessControlBytes
	ldw (xsp), 0x0

LABEL_F40C55:
	calr SeqData_ReadNextByte
	cp l, 0x82
	jr z, LABEL_F40C62
	cp l, 0x84
	jr nz, LABEL_F40C69

LABEL_F40C62:
	stdi8 10362, 8
	jr SeqData_EOL_Cleanup

LABEL_F40C69:
	cp l, 0x81
	jr nz, LABEL_F40C73
	incm 1, (xsp)
	incm 1, (xsp + 4)

LABEL_F40C73:
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqData_EOL_Cleanup
	ld wa, (xsp + 4)
	cpda16 xwa, 3299
	jr nz, LABEL_F40C41

SeqData_EOL_Cleanup:
	ld hl, (xsp + 2)

LABEL_F40C89:
	inc 8, xsp
	ret

SeqPart_ComputePlaybackDelta:
	push xiz
	ld xiz, xwa
	ldada xhl, 10284
	ldada xix, 10288
	lda xbc, (xhl + 2)
	lda xde, (xiz + 2)
	ld wa, (xix)
	cp wa, (xhl)
	jr nz, LABEL_F40CC4
	ld xhl, xbc
	inc 2, xix
	ld wa, (xix)
	ld bc, (xbc)
	cp bc, wa
	jr ugt, LABEL_F40CBF
	ldw (xiz), 0x0
	ld wa, (xix)
	sub wa, (xhl)
	ld (xde), wa
	inc 1, wa
	ld (xde), wa
	jr LABEL_F40D0E

LABEL_F40CBF:
	ldw wa, 0x64
	jr LABEL_F40D28

LABEL_F40CC4:
	ldw (xiz), 0x0
	ldw wa, 0x100
	sub wa, (xbc)
	ld (xde), wa
	ld wa, (xhl)
	calr PartCtrl_ReadWord
	stda16 10284, xhl

LABEL_F40CD8:
	ldada xbc, 10284
	ldada xde, 10288
	ld wa, (xde)
	cp wa, (xbc)
	jr nz, LABEL_F40D12
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
	cp bc, 0xFB
	jr c, LABEL_F40D0E
	incm 1, (xiz)
	ld wa, (xhl)
	sub wa, 0xFB
	ld (xhl), wa

LABEL_F40D0E:
	lds hl, 0
	jr LABEL_F40D2E

LABEL_F40D12:
	incm 1, (xiz)
	ld wa, (xbc)
	calr PartCtrl_ReadWord
	ldada xwa, 10284
	ld (xwa), hl
	cpw (xwa), 0x4D8
	jr ule, LABEL_F40CD8
	ldw wa, 0x65

LABEL_F40D28:
	calr SeqData_SetErrorCode
	ldw hl, 0xFFFF

LABEL_F40D2E:
	pop xiz
	ret

LABEL_F40D30:
	lda xsp, (xsp - 34)
	push xiz
	ld (xsp + 36), a
	ldada xbc, 10284
	ldmw2 (xbc), 0x2952
	ldda8 a, 10580
	extz wa
	ld (xbc + 2), wa
	ldada xhl, 10288
	ldmw2 (xhl), 0x2955
	lda xde, (xhl + 2)
	ldda8 c, 10583
	extz bc
	ld wa, bc
	ld (xde), bc
	cps bc, 5
	jr nz, LABEL_F40D73
	ld wa, (xhl)
	calr PartCtrl_ReadWord_Off1
	ldada xwa, 10288
	ld (xwa), hl
	ldw (xwa + 2), 0xFF
	jr LABEL_F40D77

LABEL_F40D73:
	dec 1, wa
	ld (xde), wa

LABEL_F40D77:
	lda xwa, (xsp + 32)
	calr SeqPart_ComputePlaybackDelta
	cps hl, 0
	jrl nz, LABEL_F40E1B
	ldada xbc, 10284
	ld l, (xsp + 36)
	dec 1, l
	ld e, l
	extz de
	add de, de
	ldada xwa, 10446
	ld_sriw3 WA, 0x07, 0xE0, 0xE8
	ld (xbc), wa
	ldw (xbc + 2), 0x5
	ld c, l
	extz bc
	ldada xhl, 10510
	extz xbc
	add xbc, xhl
	ld a, (xbc)
	cps a, 5
	jr nz, LABEL_F40DE2
	ldada xwa, 10478
	ld_sriw3 WA, 0x07, 0xE0, 0xE8
	calr PartCtrl_ReadWord_Off1
	ld c, (xsp + 36)
	dec 1, c
	ld e, c
	extz de
	add de, de
	ldada xwa, 10478
	st_dri3w HL, 0x07, 0xE0, 0xE8
	extz bc
	ldada xwa, 10510
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFF
	jr LABEL_F40DE6

LABEL_F40DE2:
	dec 1, a
	ld (xbc), a

LABEL_F40DE6:
	ldada xbc, 10288
	ld e, (xsp + 36)
	dec 1, e
	ld l, e
	extz hl
	add hl, hl
	ldada xwa, 10478
	ld_sriw3 WA, 0x07, 0xE0, 0xEC
	ld (xbc), wa
	extz de
	ldada xwa, 10510
	extz xde
	add xde, xwa
	ld a, (xde)
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 28)
	calr SeqPart_ComputePlaybackDelta
	cps hl, 0
	jr z, LABEL_F40E21

LABEL_F40E1B:
	ldw hl, 0xFFFF
	jrl LABEL_F41037

LABEL_F40E21:
	lda xiz, (xsp + 32)
	ld wa, (xiz)
	extz xwa
	ld (xsp + 4), xwa
	ld xbc, 0xFB
	call Math_MultiplyAccumulate
	ld (xsp + 4), xhl
	ld wa, (xiz + 2)
	extz xwa
	add (xsp + 4), xwa
	lda xiz, (xsp + 28)
	ld wa, (xiz)
	extz xwa
	ld (xsp + 8), xwa
	ld xbc, 0xFB
	call Math_MultiplyAccumulate
	ld (xsp + 8), xhl
	ld wa, (xiz + 2)
	extz xwa
	add (xsp + 8), xwa
	ldada xde, 10446
	ldada xbc, 10292
	ldada xwa, 10288
	ld (xsp + 16), xwa
	ldada xiy, 10478
	ld l, (xsp + 36)
	dec 1, l
	ldfr_berp L, 0xF8
	extz iz
	ld xwa, (xsp + 16)
	inc 2, xwa
	ld (xsp + 20), xwa
	lda xix, (xbc + 2)
	ld wa, iz
	add wa, wa
	st_dri3b B, 0x07, 0xE8, 0xE0
	st_dri3b E, 0x07, 0xF4, 0xE0
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 8)
	jrl ule, LABEL_F40F63
	ldada xiz, 10284
	ld wa, (xde)
	ld (xiz), wa
	ldw (xiz + 2), 0x5
	ld wa, (xiy)
	ld (xbc), wa
	extz hl
	ldada xwa, 10510
	extz xhl
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xix), wa
	ld xwa, (xsp + 16)
	ldmw2 (xwa), 0x2952
	ldda8 c, 10580
	extz bc
	ld xwa, (xsp + 20)
	ld (xwa), bc
	calr SeqPart_CopyDataPrimary
	ldada xde, 10288
	ldada xbc, 10292
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ldada xbc, 10284
	ldmw2 (xbc), 0x2955
	ldda8 a, 10583
	extz wa
	ld (xbc + 2), wa
	ld c, (xsp + 36)
	extz bc
	lds wa, 0
	calr Part_ReadWord_Indexed
	stda16 10292, xhl
	ld c, (xsp + 36)
	extz bc
	lds wa, 0
	calr Part_ReadByte_Indexed
	stda16 10294, xhl
	calr SeqPart_CopyDataPrimary
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr nz, LABEL_F40F40
	ld wa, (xde)
	calr PartCtrl_ReadWord_Off1
	ld (xsp + 22), hl
	ldda16 xwa, 10292
	calr Part_StealAndReallocVoices
	ldada xbc, 10292
	ld wa, (xsp + 22)
	ld (xbc), wa
	ldw (xbc + 2), 0xFF
	jr LABEL_F40F44

LABEL_F40F40:
	dec 1, wa
	ld (xbc), wa

LABEL_F40F44:
	ld c, (xsp + 36)
	extz bc
	ldda16 xde, 10292
	lds wa, 0
	calr Part_WriteWord_Indexed
	ld c, (xsp + 36)
	extz bc
	ldda16 xde, 10294
	lds wa, 0
	calr Part_WriteByte_Indexed
	jrl LABEL_F41035

LABEL_F40F63:
	ldada xwa, 10284
	ld (xsp + 12), xwa
	inc 2, xwa
	ld (xsp + 24), xwa
	ld xwa, (xsp + 4)
	cp xwa, (xsp + 8)
	jrl nc, LABEL_F4100A
	sub (xsp + 8), xwa
	ld xwa, (xsp + 8)
	ld xbc, 0xFB
	call Math_DivideU32
	ld (xsp + 22), hl
	ld xwa, (xsp + 8)
	ld xbc, 0xFB
	call DivMod32
	ld xwa, (xsp + 12)
	ldmw2 (xwa), 0x2955
	ldda8 c, 10583
	extz bc
	ld xwa, (xsp + 24)
	ld (xwa), bc
	ld a, (xsp + 36)
	extz wa
	extz hl
	ld bc, (xsp + 22)
	ld de, hl
	call PartCtrl_SwapIndexedEntries
	ldada xde, 10284
	ld l, (xsp + 36)
	dec 1, l
	ld c, l
	extz bc
	add bc, bc
	ldada xwa, 10446
	ld_sriw3 WA, 0x07, 0xE0, 0xE4
	ld (xde), wa
	ldw (xde + 2), 0x5
	ldada xde, 10292
	ldada xwa, 10478
	ld_sriw3 WA, 0x07, 0xE0, 0xE4
	ld (xde), wa
	extz hl
	ldada xwa, 10510
	extz xhl
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xde + 2), wa
	ldada xbc, 10288
	ldmw2 (xbc), 0x2952
	ldda8 a, 10580
	extz wa
	ld (xbc + 2), wa
	jr LABEL_F41032

LABEL_F4100A:
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
	ldda8 c, 10580
	extz bc
	ld xwa, (xsp + 20)
	ld (xwa), bc

LABEL_F41032:
	calr SeqPart_CopyDataPrimary

LABEL_F41035:
	lds hl, 0

LABEL_F41037:
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
	ldda32 xwa, 9690
	cp xbc, xwa
	jr ule, LABEL_F4105D
	ld bc, wa
	add (xde), bc
	jr SeqPart_StoredExit

LABEL_F4105D:
	ld xiz, xwa
	sub xiz, xbc

LABEL_F41061:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	calr PartCtrl_ReadWord
	cp hl, 0x4D8
	jr ule, LABEL_F41076
	stdi8 10362, 10
	jr SeqPart_StoredExit

LABEL_F41076:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F4108B
	stdi8 10362, 11
	jr SeqPart_StoredExit

LABEL_F4108B:
	cp xiz, 0xFB
	jr ugt, LABEL_F410A0
	ld xbc, xiz
	inc 5, xbc
	ld xwa, (xsp + 4)
	ld (xwa), bc

SeqPart_StoredExit:
	pop xiz
	inc 8, xsp
	ret

LABEL_F410A0:
	sub xiz, 0xFB
	jr LABEL_F41061

SeqPart_ApplyControlChanges:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), xwa
	ldi_berp 0xFB, 0

LABEL_F410B3:
	ldto_berp C, 0xFB
	extz bc
	ld xwa, (xsp + 2)
	ld_srib3 A, 0x07, 0xE0, 0xE4
	extz wa
	calr LABEL_F3FC35
	calr PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr nz, LABEL_F410D7
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr ule, LABEL_F410B3

LABEL_F410D7:
	calr SeqPlay_WriteErrorToVoiceTable
	pop_werp 0xFA
	inc 4, xsp
	ret

LABEL_F410E0:
	push xiz
	cpdi8 10048, 0
	jrl z, SeqPart_AbortAndUpdateState
	ldada xbc, 10034
	ldda16 xwa, 9820
	cpdi8 10028, 0
	jrl nz, LABEL_F41179
	cp (xbc), 0x0
	jrl z, SeqPart_AbortAndUpdateState
	stda16 9884, xwa
	ldmm16 9890, 9822
	lds32 xwa, 6
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	ld c, a
	extz bc
	ldda16 xwa, 9900
	calr Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldada xwa, 10292
	ldmw2 (xwa), 0x26D8
	ldmw2 (xwa + 2), 0x26D6
	calr SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 10379, 9944
	ldmm16 10377, 9942
	ld xwa, 0x2732
	jrl PartCtrl_ApplyChanges

LABEL_F41179:
	stda16 9884, xwa
	ldmm16 9890, 9822
	cp (xbc), 0x0
	jr nz, LABEL_F411F8
	lds32 xwa, 6
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	ld c, a
	extz bc
	ldda16 xwa, 9900
	calr Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldada xwa, 10292
	ldmw2 (xwa), 0x26D4
	ldmw2 (xwa + 2), 0x26D2
	calr SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldmm16 10379, 9940
	ldmm16 10377, 9938
	ld xwa, 0x272C
	jrl PartCtrl_ApplyChanges

LABEL_F411F8:
	ld xwa, 0xC
	stda32 9690, xwa
	calr SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jrl nz, SeqPart_AbortAndUpdateState
	ldda16 xwa, 9912
	ldfr_werp WA, 0xFA
	ldda32 xwa, 9914
	ld iz, wa
	dec 6, iz
	cps iz, 5
	jr nc, LABEL_F41234
	ldto_werp WA, 0xFA
	calr PartCtrl_ReadWord_Off1
	stda16 9900, xhl
	lds wa, 5
	sub wa, iz
	ldw iz, 0xFF
	sub iz, wa
	jr LABEL_F4123B

LABEL_F41234:
	ldto_werp WA, 0xFA
	stda16 9900, xwa

LABEL_F4123B:
	stda16 9902, xiz
	ldto_berp C, 0xF8
	extz bc
	ldda16 xwa, 9900
	calr Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldada xde, 10292
	lda xbc, (xde + 2)
	ldda16 xwa, 9950
	cpda16 xwa, 9952
	jr ule, LABEL_F41280
	ldmw2 (xde), 0x26D4
	ldmw2 (xbc), 0x26D2
	jr LABEL_F41288

LABEL_F41280:
	ldmw2 (xde), 0x26D8
	ldmw2 (xbc), 0x26D6

LABEL_F41288:
	calr SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, LABEL_F4135B
	ldda16 xwa, 9950
	cpda16 xwa, 9952
	jr ule, LABEL_F412AF
	ldada xwa, 10028
	ldmm16 10379, 9940
	ldmm16 10377, 9938
	jr LABEL_F412BF

LABEL_F412AF:
	ldada xwa, 10034
	ldmm16 10379, 9944
	ldmm16 10377, 9942

LABEL_F412BF:
	calr SeqPart_ApplyControlChanges
	ldda8 c, 10048
	extz bc
	lds wa, 0
	calr Part_ReadByte_Indexed
	stda16 10286, xhl
	ldda8 c, 10048
	extz bc
	lds wa, 0
	calr Part_ReadWord_Indexed
	stda16 10284, xhl
	ldada xde, 10288
	ldto_werp WA, 0xFA
	ld (xde), wa
	ldda32 xwa, 9914
	ld (xde + 2), wa
	ld c, a
	extz bc
	ld wa, (xde)
	calr Part_WriteWordAndByte
	ldda16 xwa, 9950
	cpda16 xwa, 9952
	jr ule, LABEL_F41312
	ldada xwa, 10292
	ldmw2 (xwa), 0x26D8
	ldmw2 (xwa + 2), 0x26D6
	jr LABEL_F4131F

LABEL_F41312:
	ldada xwa, 10292
	ldmw2 (xwa), 0x26D4
	ldmw2 (xwa + 2), 0x26D2

LABEL_F4131F:
	calr SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jr nz, SeqPart_AbortAndUpdateState
	ldda16 xwa, 9950
	cpda16 xwa, 9952
	jr ule, LABEL_F41345
	ldada xwa, 10034
	ldmm16 10379, 9944
	ldmm16 10377, 9942
	jr PartCtrl_ApplyChanges

LABEL_F41345:
	ldada xwa, 10028
	ldmm16 10379, 9940
	ldmm16 10377, 9938

PartCtrl_ApplyChanges:
	calr SeqPart_ApplyControlChanges

SeqPart_AbortAndUpdateState:
	calr SeqPlay_WriteErrorToVoiceTable

LABEL_F4135B:
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
	ldda32 xwa, 9690
	cp xbc, xwa
	jr ule, LABEL_F4137D
	sub xbc, xwa
	inc 4, xbc
	jr LABEL_F413C2

LABEL_F4137D:
	ld xiz, xwa
	sub xiz, xbc

LABEL_F41381:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	calr PartCtrl_ReadWord_Off1
	cp hl, 0x4D8
	jr ule, LABEL_F41396
	stdi8 10362, 10
	jr LABEL_F413C7

LABEL_F41396:
	ld xwa, (xsp + 8)
	ld (xwa), hl
	ld wa, hl
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F413AB
	stdi8 10362, 11
	jr LABEL_F413C7

LABEL_F413AB:
	cp xiz, 0xFB
	jr ule, LABEL_F413BB
	sub xiz, 0xFB
	jr LABEL_F41381

LABEL_F413BB:
	ld xbc, 0xFF
	sub xbc, xiz

LABEL_F413C2:
	ld xwa, (xsp + 4)
	ld (xwa), bc

LABEL_F413C7:
	pop xiz
	inc 8, xsp
	ret

SeqData_SkipToNextEvent:
	calr SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	jr nz, LABEL_F413D9
	ret

LABEL_F413D9:
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqData_SkipEventParams
	ldw wa, 0xD2
	jr LABEL_F41407

SeqData_SkipEventParams:
	calr SeqData_ReadNextByte
	cp l, 0x82
	ret z
	cp l, 0x84
	ret z
	bit 7, l
	ret nz
	calr SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqData_SkipEventParams
	ldw wa, 0xD3

LABEL_F41407:
	calr SeqData_SetErrorCode
	ret

SeqData_CopyBlockToBuffer:
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda_24 xde, 0x0ab000
	add xde, xwa
	ld xiy, 0xF180
	ld xix, xde
	ldw bc, 0x400
	ldirw
	ret

VoicePreset_LoadAndInitPan:
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda_24 xbc, 0x0ab000
	add xbc, xwa
	ld xiy, xbc
	ld xix, 0xF180
	ldw bc, 0x400
	ldirw
	jp VoiceChannels_InitPanFromPreset

Part_WriteWordBlock_OffsetAF:
	push xiz
	ld iz, wa
	ldi_berp 0xFB, 0

LABEL_F4144A:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xAF
	ld de, iz
	calr Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F4144A
	pop xiz
	ret

Chan_SetActiveBit:
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F4146D
	slaa de

LABEL_F4146D:
	cps c, 0
	jr z, LABEL_F41477
	orddm16 61854, xde
	jr LABEL_F4147D

LABEL_F41477:
	cpl de
	anddm16 61854, xde

LABEL_F4147D:
	jp Audio_CheckSubsystemReady

SeqVoice_SetOrClearBitMask:
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, LABEL_F4148C
	slaa de

LABEL_F4148C:
	cps c, 0
	jr z, LABEL_F41496
	orddm16 10408, xde
	jr LABEL_F4149C

LABEL_F41496:
	cpl de
	anddm16 10408, xde

LABEL_F4149C:
	jp Audio_CheckSubsystemReady

Part_CopyBlock16:
	cps a, 0
	jr nz, LABEL_F414AA
	ldada xhl, 62080
	jr LABEL_F414BF

LABEL_F414AA:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	st_dri3b W, 0xE1, 0x00, 0x01
	lda_24 xhl, 0x0ab000
	add xhl, xwa

LABEL_F414BF:
	ld xde, xbc
	lda xbc, (xbc + 16)

LABEL_F414C4:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xEC
	cp xde, xbc
	jr c, LABEL_F414C4
	ret

Part_CopyToBuffer:
	cps a, 0
	jr nz, LABEL_F414D9
	ldada xde, 62560
	jr LABEL_F414EE

LABEL_F414D9:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	st_dri3b W, 0xE1, 0xE0, 0x02
	lda_24 xde, 0x0ab000
	add xde, xwa

LABEL_F414EE:
	cps c, 0
	jr nz, LABEL_F414F8
	ldada xbc, 62560
	jr LABEL_F4150D

LABEL_F414F8:
	dec 1, c
	ldb b, 0x0
	extz xbc
	sll xbc, 11
	st_dri3b W, 0xE5, 0xE0, 0x02
	lda_24 xbc, 0x0ab000
	add xbc, xwa

LABEL_F4150D:
	lds hl, 0

LABEL_F4150F:
	ld_spib A, 0xE8
	lda_dpi XBC, 0xE4
	inc 1, hl
	cp hl, 0x520
	jr c, LABEL_F4150F
	ret

; ============================================================================
; Part_WriteByte - Write byte to part/channel data structure
; ============================================================================
; Input:  A = part number (0 = direct base, 1+ = indexed)
;         BC = offset within part structure
;         E = byte value to write
; Address: 0xAB000 + (A-1)*2048 + BC  (2KB per part)
; If A==0, uses direct base address from RAM[61824].
; See also: Part_WriteWord (16-bit write companion)
; ============================================================================
Part_WriteByte:
	cps a, 0
	jr nz, LABEL_F4152C
	ldada xwa, 61824
	extz xbc
	add xbc, xwa
	jr LABEL_F41540

LABEL_F4152C:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda_24 xbc, 0x0ab000
	add xbc, xwa

LABEL_F41540:
	ld (xbc), e
	ret

; ============================================================================
; Part_WriteWord - Write 16-bit word to part/channel data structure
; ============================================================================
; Input:  A = part number (0 = direct base, 1+ = indexed)
;         BC = offset within part structure
;         DE = 16-bit value to write
; Address: 0xAB000 + (A-1)*2048 + BC  (2KB per part)
; See also: Part_WriteByte (8-bit write companion)
; ============================================================================
Part_WriteWord:
	cps a, 0
	jr nz, LABEL_F41551
	ldada xwa, 61824
	extz xbc
	add xbc, xwa
	jr LABEL_F41565

LABEL_F41551:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, 0xAB000
	add xbc, xwa

LABEL_F41565:
	ld (xbc), de
	ret

Part_ReadByteDirect:
	cps a, 0
	jr nz, LABEL_F41576
	ldada xwa, 61824
	extz xbc
	add xbc, xwa
	jr LABEL_F4158A

LABEL_F41576:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	lda_24 xbc, 0x0ab000
	add xbc, xwa

LABEL_F4158A:
	ld l, (xbc)
	ret

Part_ReadWord:
	cps a, 0
	jr nz, LABEL_F4159B
	ldada xwa, 61824
	extz xbc
	add xbc, xwa
	jr LABEL_F415AF

LABEL_F4159B:
	extz xbc
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	add xwa, xbc
	ld xbc, 0xAB000
	add xbc, xwa

LABEL_F415AF:
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
	ldi_berp 0xFB, 0

LABEL_F41606:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB1
	ld de, iz
	calr Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F41606
	calr Seq_ComputePercentClamped99
	stda8 7528, l
	call SeqAccomp_SendStopNotify
	pop xiz
	ret

Part_IncrementVoicePos:
	push xiz
	lds wa, 0
	ldw bc, 0xB1
	calr Part_ReadWord
	ld iz, hl
	cp iz, 0x4D8
	jr c, LABEL_F4163F
	ldw hl, 0xFFFF
	jr LABEL_F41667

LABEL_F4163F:
	inc 1, iz
	ldi_berp 0xFB, 0

LABEL_F41644:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB1
	ld de, iz
	calr Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F41644
	calr Seq_ComputePercentClamped99
	stda8 7528, l
	call SeqAccomp_SendStopNotify
	lds hl, 0

LABEL_F41667:
	pop xiz
	ret

Part_DecrementVoicePos:
	push xiz
	lds wa, 0
	ldw bc, 0xB1
	calr Part_ReadWord
	ld iz, hl
	cps iz, 0
	jr nz, LABEL_F4167D
	ldw hl, 0xFFFF
	jr LABEL_F416A5

LABEL_F4167D:
	dec 1, iz
	ldi_berp 0xFB, 0

LABEL_F41682:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB1
	ld de, iz
	calr Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F41682
	calr Seq_ComputePercentClamped99
	stda8 7528, l
	call SeqAccomp_SendStopNotify
	lds hl, 0

LABEL_F416A5:
	pop xiz
	ret

Part_WriteSubBlock32:
	cps a, 0
	jr nz, LABEL_F416B1
	ldada xhl, 61856
	jr LABEL_F416C4

LABEL_F416B1:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda_24 xhl, 0x0ab000
	add xhl, xwa

LABEL_F416C4:
	extz bc
	st_dri3b W, 0x07, 0xEC, 0xE4
	ld (xwa - 1), e
	jp Audio_CheckSubsystemReady

Part_ReadSubBlock32:
	cps a, 0
	jr nz, LABEL_F416DC
	ldada xde, 61856
	jr LABEL_F416EF

LABEL_F416DC:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 32)
	lda_24 xde, 0x0ab000
	add xde, xwa

LABEL_F416EF:
	extz bc
	st_dri3b W, 0x07, 0xE8, 0xE4
	ld l, (xwa - 1)
	ret

Part_WriteSubBlock48:
	cps a, 0
	jr nz, LABEL_F41704
	ldada xhl, 61872
	jr LABEL_F41717

LABEL_F41704:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	lda xwa, (xwa + 48)
	lda_24 xhl, 0x0ab000
	add xhl, xwa

LABEL_F41717:
	extz bc
	st_dri3b W, 0x07, 0xEC, 0xE4
	ld (xwa - 1), e
	jp Audio_CheckSubsystemReady
LABEL_F41725:
	.byte 0xc9, 0xd8, 0x6e, 0x06, 0xf1, 0xb0, 0xf1, 0x32
	.byte 0x68, 0x13, 0xc9, 0x69, 0x20, 0x00, 0xe8, 0x12
	.byte 0xe8, 0xee, 0x0b, 0xb8, 0x30, 0x30, 0xf2, 0x00
	.byte 0xb0, 0x0a, 0x32, 0xe8, 0x82, 0xd9, 0x12, 0xf3
	.byte 0x07, 0xe8, 0xe4, 0x30, 0x88, 0xff, 0x27, 0x0e

Part_FindVoiceByByte:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 2), c
	ld (xsp + 4), a
	ldi_berp 0xFB, 1

LABEL_F4175B:
	ld a, (xsp + 4)
	extz wa
	ldto_berp C, 0xFB
	extz bc
	calr Part_ReadSubBlock32
	cp l, (xsp + 2)
	jr nz, LABEL_F41772
	ldto_berp L, 0xFB
	jr LABEL_F4177D

LABEL_F41772:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F4175B
	ldb l, 0xFF

LABEL_F4177D:
	pop_werp 0xFA
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
	add c, 0xD0
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
	add c, 0xD0
	extz bc
	calr Part_ReadByteDirect
	cp (xsp), 0x0
	jr z, LABEL_F417C6
	set 7, l
	jr LABEL_F417C9

LABEL_F417C6:
	res 7, l

LABEL_F417C9:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 2)
	mul c, 0x3
	dec 3, c
	add c, 0xD0
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
	add c, 0xD1
	extz bc
	jrl Part_ReadWord

Part_WriteVoiceWord:
	extz wa
	mul c, 0x3
	dec 3, c
	add c, 0xD1
	extz bc
	jrl Part_WriteWord

Part_InitVoiceDefaults:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	ld a, (xsp + 2)
	extz wa
	lds bc, 0
	ldw de, 0x5A
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 1
	ldw de, 0x5A
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 2
	ldw de, 0x5A
	calr Part_WriteByte
	ld a, (xsp + 2)
	extz wa
	lds bc, 3
	ldw de, 0x5A
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
	call LABEL_EF0839
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
	ldw de, 0x2E
	calr Part_WriteWord
	ld a, (xsp + 2)
	extz wa
	ldw bc, 0x1A
	ldw de, 0x520
	calr Part_WriteWord
	lds iz, 0

LABEL_F418BA:
	ld a, (xsp + 2)
	extz wa
	ld bc, iz
	add bc, 0x42
	lds de, 0
	calr Part_WriteByte
	inc 1, iz
	cp iz, 0xC
	jr c, LABEL_F418BA
	calr SeqStatus_CheckBit2
	ld a, (xsp + 2)
	extz wa
	cps l, 0
	jr nz, LABEL_F418E5
	ldw bc, 0xBD
	lds de, 0
	jr LABEL_F418EB

LABEL_F418E5:
	ldw bc, 0xBD
	ldw de, 0xFF

LABEL_F418EB:
	calr Part_WriteByte
	popw iz
	inc 2, xsp
	ret

Part_WriteAllVoiceSubBlocks_A:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ldi_berp 0xFB, 1

LABEL_F418FD:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldto_berp E, 0xFB
	dec 1, e
	extz de
	lda_24 xhl, 0xe4454a
	ld_srib3 E, 0x07, 0xEC, 0xE8
	calr Part_WriteSubBlock32
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F418FD
	ldi_berp 0xFB, 1

LABEL_F41927:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldto_berp E, 0xFB
	dec 1, e
	extz de
	lda_24 xhl, 0xe4456a
	ld_srib3 E, 0x07, 0xEC, 0xE8
	calr Part_WriteSubBlock48
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F41927
	pop_werp 0xFA
	inc 2, xsp
	ret

Part_WriteAllVoiceSubBlocks_B:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ldi_berp 0xFB, 1

LABEL_F4195F:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldto_berp E, 0xFB
	dec 1, e
	extz de
	lda_24 xhl, 0xe4455a
	ld_srib3 E, 0x07, 0xEC, 0xE8
	calr Part_WriteSubBlock32
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F4195F
	ldi_berp 0xFB, 1

LABEL_F41989:
	ld a, (xsp + 2)
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldto_berp E, 0xFB
	dec 1, e
	extz de
	lda_24 xhl, 0xe4456a
	ld_srib3 E, 0x07, 0xEC, 0xE8
	calr Part_WriteSubBlock48
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F41989
	pop_werp 0xFA
	inc 2, xsp
	ret

LABEL_F419B6:
	push_werp 0xFA
	cpdi8 10360, 10
	jr nz, LABEL_F419E2
	sti16_24 0x00ffec, 0x0000
	ldi_berp 0xFB, 1

LABEL_F419CA:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1E
	lds de, 0
	calr Part_WriteWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F419CA
	jr LABEL_F419F1

LABEL_F419E2:
	ldto_berp A, 0xFB
	inc 1, a
	extz wa
	ldw bc, 0x1E
	lds de, 0
	calr Part_WriteWord

LABEL_F419F1:
	pop_werp 0xFA
	ret

SeqData_CopyBlock2K:
	cps a, 0
	jr nz, LABEL_F419FF
	ldada xhl, 62080
	jr LABEL_F41A14

LABEL_F419FF:
	dec 1, a
	ldb w, 0x0
	extz xwa
	sll xwa, 11
	st_dri3b W, 0xE1, 0x00, 0x01
	lda_24 xhl, 0x0ab000
	add xhl, xwa

LABEL_F41A14:
	ld xde, xbc
	lda xbc, (xbc + 16)

LABEL_F41A19:
	ld_spib A, 0xEC
	lda_dpi XBC, 0xE8
	cp xde, xbc
	jr c, LABEL_F41A19
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
	lda_24 xde, 0x0b0000
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
	jr z, LABEL_F41A5A
	cp (xwa), 0x84
	jr nz, LABEL_F41A5F

LABEL_F41A5A:
	lds hl, 1
	jrl LABEL_F41AF4

LABEL_F41A5F:
	ld wa, (xhl)
	cp wa, 0xFF
	jr nz, LABEL_F41A8A
	ldw (xhl), 0x5
	ld wa, (xiz)
	calr PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0xFFFF
	jr z, LABEL_F41ACE
	ld wa, (xiz)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda_24 xde, 0x0b0000
	add xde, xwa
	jr LABEL_F41A8E

LABEL_F41A8A:
	inc 1, wa
	ld (xhl), wa

LABEL_F41A8E:
	ld xwa, (xsp + 6)
	bitm 7, (xwa)
	jr z, LABEL_F41ACE

LABEL_F41A95:
	ld l, (xsp + 4)
	extz hl
	lda xix, (xiz + 2)
	ld wa, (xix)
	extz xwa
	add xwa, xde
	ld c, (xwa)
	ld xwa, (xsp + 6)
	lda_dri3 XHL, 0x07, 0xE0, 0xEC
	bit 7, c
	jr nz, LABEL_F41AEF
	incm8 1, (xsp + 4)
	ld wa, (xix)
	cp wa, 0xFF
	jr nz, LABEL_F41AE5
	ldw (xix), 0x5
	ld wa, (xiz)
	calr PartCtrl_ReadWord
	ld (xiz), hl
	cpw (xiz), 0xFFFF
	jr nz, LABEL_F41AD3

LABEL_F41ACE:
	ldw hl, 0xFFFF
	jr LABEL_F41AF4

LABEL_F41AD3:
	ld wa, (xiz)
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda_24 xde, 0x0b0000
	add xde, xwa
	jr LABEL_F41AE9

LABEL_F41AE5:
	inc 1, wa
	ld (xix), wa

LABEL_F41AE9:
	cp (xsp + 4), 0x8
	jr c, LABEL_F41A95

LABEL_F41AEF:
	ld l, (xsp + 4)
	extz hl

LABEL_F41AF4:
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
	lda_24 xde, 0x0b0000
	add xde, xwa
	ldw (xsp + 4), 0x0
	ld a, (xsp + 6)
	extz wa
	cps wa, 0
	jrl ule, LABEL_F41BE7

LABEL_F41B27:
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
	cp hl, 0xFF
	jr z, LABEL_F41B4E
	inc 1, hl
	ld (xbc), hl
	jrl LABEL_F41BD9

LABEL_F41B4E:
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	cp_erpw 0xFA, 0xFF, 0xFF
	jr nz, LABEL_F41BB9
	ldda16 xiz, 61999
	cp iz, 0xFFFF
	jr nz, LABEL_F41B6F
	ldw hl, 0xFFFF
	jr LABEL_F41BE9

LABEL_F41B6F:
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LABEL_F41B8C
	ldto_werp WA, 0xFA
	lds bc, 0
	calr PartCtrl_WriteWord_Off1

LABEL_F41B8C:
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	ld bc, iz
	calr PartCtrl_WriteWord
	ld xwa, (xsp + 12)
	ld bc, (xwa)
	ld wa, iz
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	ld wa, iz
	lds bc, 1
	calr PartCtrl_SetClearBit7
	ld xwa, (xsp + 12)
	ld (xwa), iz
	calr Part_DecrementVoicePos
	jr LABEL_F41BC1

LABEL_F41BB9:
	ld xwa, (xsp + 12)
	ldto_werp BC, 0xFA
	ld (xwa), bc

LABEL_F41BC1:
	ld xbc, (xsp + 12)
	ld wa, (xbc)
	dec 1, wa
	extz xwa
	sll xwa, 8
	ld xde, 0xB0000
	add xde, xwa
	ldw (xbc + 2), 0x5

LABEL_F41BD9:
	incm 1, (xsp + 4)
	ld a, (xsp + 6)
	extz wa
	cp (xsp + 4), wa
	jrl c, LABEL_F41B27

LABEL_F41BE7:
	lds hl, 0

LABEL_F41BE9:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PartCtrl_InitChainLinkedList:
	pushw iz
	lds wa, 1
	calr Part_WriteWordBlock_OffsetAF
	ldw wa, 0x4D8
	calr Part_SetAllVoicePos
	lds iz, 1

LABEL_F41BFC:
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
	cp iz, 0x4D8
	jr ule, LABEL_F41BFC
	lds wa, 1
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	ldw wa, 0x4D8
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	popw iz
	ret

PartCtrl_ReadWord_Off1:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 1, xwa
	ld xbc, 0xB0000
	add xbc, xwa
	ld hl, (xbc)
	ret

PartCtrl_WriteWord_Off1:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 1, xwa
	ld xde, 0xB0000
	add xde, xwa
	ld (xde), bc
	ret

PartCtrl_ReadWord:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 3, xwa
	ld xbc, 0xB0000
	add xbc, xwa
	ld hl, (xbc)
	ret

; ============================================================================
; PartCtrl_WriteWord - Write 16-bit word to part control register
; ============================================================================
; Input:  WA = part number (1-based)
;         BC = 16-bit value to write
; Address: 0xB0000 + (WA-1)*256 + 3  (256 bytes per part)
; Family: offset 1 (PartCtrl_WriteWord_Off1), offset 3 (this), read (PartCtrl_ReadWord),
;         bit 7 test (PartCtrl_TestBit7), bit 7 set/clear (PartCtrl_SetClearBit7)
; ============================================================================
PartCtrl_WriteWord:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 3, xwa
	ld xde, 0xB0000
	add xde, xwa
	ld (xde), bc
	ret

PartCtrl_TestBit7:
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda_24 xbc, 0x0b0000
	add xbc, xwa
	ld l, (xbc)
	and l, 0x80
	ret

PartCtrl_SetClearBit7:
	dec 1, wa
	extz xwa
	sll xwa, 8
	lda_24 xde, 0x0b0000
	add xde, xwa
	cps c, 0
	jr z, LABEL_F41CAE
	setm 7, (xde)
	ret

LABEL_F41CAE:
	resm 7, (xde)
	ret

PartCtrl_ReadByte:
	extz bc
	dec 1, wa
	extz xwa
	sll xwa, 8
	st_dri3b W, 0x07, 0xE0, 0xE4
	lda_24 xbc, 0x0b0000
	add xbc, xwa
	ld l, (xbc)
	ret

PartCtrl_WriteByteToBuf:
	extz bc
	dec 1, wa
	extz xwa
	sll xwa, 8
	st_dri3b W, 0x07, 0xE0, 0xE4
	lda_24 xbc, 0x0b0000
	add xbc, xwa
	ld (xbc), e
	ret

LABEL_F41CE1:
	.byte 0x3e, 0xe8, 0x8e, 0xbe, 0x02, 0x32, 0x92, 0x23
	.byte 0xeb, 0x12, 0x96, 0x20, 0xd8, 0x69, 0xe8, 0x12
	.byte 0xe8, 0xee, 0x08, 0xeb, 0x80, 0xf2, 0x00, 0x00
	.byte 0x0b, 0x33, 0xe8, 0x83, 0xb3, 0x43, 0x92, 0x23
	.byte 0xdb, 0xdd, 0x66, 0x06, 0xdb, 0x69, 0xb2, 0x53
	.byte 0x68, 0x15, 0x96, 0x20, 0x1e, 0x29, 0xff, 0xdb
	.byte 0xd8, 0x6e, 0x05, 0x33, 0xff, 0xff, 0x68, 0x09
	.byte 0xb6, 0x53, 0xbe, 0x02, 0x02, 0x05, 0x00, 0xdb
	.byte 0xa8, 0x5e, 0x0e, 0x3e, 0xe8, 0x8e, 0xbe, 0x02
	.byte 0x32, 0x92, 0x23, 0xeb, 0x12, 0x96, 0x20, 0xd8
	.byte 0x69, 0xe8, 0x12, 0xe8, 0xee, 0x08, 0xeb, 0x80
	.byte 0xf2, 0x00, 0x00, 0x0b, 0x33, 0xe8, 0x83, 0x83
	.byte 0x21, 0xb1, 0x41, 0x92, 0x23, 0xdb, 0xdd, 0x66
	.byte 0x06, 0xdb, 0x69, 0xb2, 0x53, 0x68, 0x15, 0x96
	.byte 0x20, 0x1e, 0xe4, 0xfe, 0xdb, 0xd8, 0x6e, 0x05
	.byte 0x33, 0xff, 0xff, 0x68, 0x09, 0xb6, 0x53, 0xbe
	.byte 0x02, 0x02, 0x05, 0x00, 0xdb, 0xa8, 0x5e, 0x0e

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
	lda_24 xhl, 0x0b0000
	add xhl, xde
	ld e, (xiz)
	ld (xhl), e
	cp bc, 0xFF
	jr nz, LABEL_F41DAE
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_F41D9C
	ldw hl, 0xFFFF
	jr LABEL_F41DB7

LABEL_F41D9C:
	dec 1, wa
	extz xwa
	sll xwa, 8
	inc 5, xwa
	lda_24 xhl, 0x0b0000
	add xhl, xwa
	jr LABEL_F41DB0

LABEL_F41DAE:
	inc 1, xhl

LABEL_F41DB0:
	ld a, (xiz + 1)
	ld (xhl), a
	lds hl, 0

LABEL_F41DB7:
	pop xiz
	ret

LABEL_F41DB9:
	dec 4, xsp
	lda xde, (xsp)
	ldada xbc, 9460
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld wa, (xde)
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F41DE4
	calr Part_StealAndReallocVoices
	ld wa, (xsp + 256)
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F41DE4:
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
	cp wa, 0xFFFF
	jr z, LABEL_F41E0A
	calr Part_StealAndReallocVoices
	lds wa, 1
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F41E0A:
	lds wa, 1
	lds bc, 5
	ldw de, 0x82
	calr PartCtrl_WriteByteToBuf
	lds wa, 2
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F41E2C
	calr Part_StealAndReallocVoices
	lds wa, 2
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F41E2C:
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	jrl PartCtrl_WriteByteToBuf

Part_UnlinkVoiceFromChain:
	push xiz
	lds wa, 1
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F41E9F
	lds wa, 1
	lds bc, 1
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	lds wa, 1
	calr PartCtrl_ReadWord_Off1
	ldfr_werp HL, 0xFA
	lds wa, 1
	calr PartCtrl_ReadWord
	ld iz, hl
	cpi_werp 0xFA, 0
	jr nz, LABEL_F41E6F
	cp iz, 0xFFFF
	jr z, LABEL_F41E90
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	lds bc, 0
	jr LABEL_F41E8D

LABEL_F41E6F:
	cp iz, 0xFFFF
	jr nz, LABEL_F41E80
	ldto_werp WA, 0xFA
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	jr LABEL_F41E90

LABEL_F41E80:
	ldto_werp WA, 0xFA
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ldto_werp BC, 0xFA

LABEL_F41E8D:
	calr PartCtrl_WriteWord_Off1

LABEL_F41E90:
	lds wa, 1
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F41E9F:
	lds wa, 2
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F41F07
	lds wa, 2
	lds bc, 1
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos
	lds wa, 2
	calr PartCtrl_ReadWord_Off1
	ldfr_werp HL, 0xFA
	lds wa, 2
	calr PartCtrl_ReadWord
	ld iz, hl
	cpi_werp 0xFA, 0
	jr nz, LABEL_F41ED7
	cp iz, 0xFFFF
	jr z, LABEL_F41EF8
	ld wa, iz
	calr Part_WriteWordBlock_OffsetAF
	ld wa, iz
	lds bc, 0
	jr LABEL_F41EF5

LABEL_F41ED7:
	cp iz, 0xFFFF
	jr nz, LABEL_F41EE8
	ldto_werp WA, 0xFA
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	jr LABEL_F41EF8

LABEL_F41EE8:
	ldto_werp WA, 0xFA
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ldto_werp BC, 0xFA

LABEL_F41EF5:
	calr PartCtrl_WriteWord_Off1

LABEL_F41EF8:
	lds wa, 2
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	lds wa, 2
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F41F07:
	pop xiz
	ret

Part_ClearAllVoiceChannels:
	push_werp 0xFA
	calr PartCtrl_InitChainLinkedList
	sti16_24 0x00ffec, 0x0000
	calr Part_UnlinkVoiceFromChain
	ldi_berp 0xFA, 0

LABEL_F41F1C:
	ldi_berp 0xFB, 1

LABEL_F41F1F:
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	lds de, 0
	calr Part_SetClearVoiceBit7
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteVoiceWord
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	add_berp C, 0xFB
	add c, 0x76
	extz bc
	ldw de, 0xFFFF
	calr Part_WriteWord
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	add c, 0x97
	extz bc
	lds de, 5
	calr Part_WriteByte
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F41F1F
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x0A
	jr ule, LABEL_F41F1C
	pop_werp 0xFA
	ret

Part_StealAndReallocVoices:
	push xiz
	ld iz, wa
	cp iz, 0xFFFF
	jr z, LABEL_F41FB3

LABEL_F41F85:
	ld wa, iz
	calr PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F41F96
	ldw wa, 0x28
	calr SeqData_SetErrorCode
	jr LABEL_F41FB3

LABEL_F41F96:
	ld wa, iz
	lds bc, 0
	calr PartCtrl_SetClearBit7
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ld wa, iz
	calr PartCtrl_AppendToFreeList
	ldto_werp IZ, 0xFA
	cp iz, 0xFFFF
	jr nz, LABEL_F41F85

LABEL_F41FB3:
	pop xiz
	ret

PartCtrl_AppendToFreeList:
	pushw iz
	ld iz, wa
	ldda16 xbc, 61999
	ld wa, iz
	calr PartCtrl_WriteWord
	ldda16 xwa, 61999
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
	cp hl, 0xFFFF
	jr z, LABEL_F42006
	ldw wa, 0x8
	calr SeqData_SetErrorCode
	jr LABEL_F42011

LABEL_F42006:
	calr Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F42016

LABEL_F42011:
	ldw hl, 0xFFFF
	jr LABEL_F42037

LABEL_F42016:
	ld wa, (xsp + 2)
	ld bc, iz
	calr PartCtrl_WriteWord
	ld wa, iz
	ld bc, (xsp + 2)
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	ld wa, iz
	lds bc, 1
	calr PartCtrl_SetClearBit7
	ld hl, iz

LABEL_F42037:
	popw iz
	inc 2, xsp
	ret

Part_ProcessAndDecrementVoice:
	push xiz
	ldda16 xiz, 61999
	cp iz, 0xFFFF
	jr z, LABEL_F4206D
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ldto_werp WA, 0xFA
	calr Part_WriteWordBlock_OffsetAF
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LABEL_F42063
	ldto_werp WA, 0xFA
	lds bc, 0
	calr PartCtrl_WriteWord_Off1

LABEL_F42063:
	ld wa, iz
	lds bc, 1
	calr PartCtrl_SetClearBit7
	calr Part_DecrementVoicePos

LABEL_F4206D:
	ld hl, iz
	pop xiz
	ret

MIDI_GetEventSize:
	ld c, a
	and c, 0xF0
	cp c, 0xC0
	jr z, MIDI_Status_6
	cp c, 0xB0
	jr z, MIDI_Status_6
	cp c, 0x90
	jr z, MIDI_Status_6
	cp a, 0xD3
	jr z, MIDI_Status_3
	cp a, 0xD2
	jr z, LABEL_F420B7
	cp a, 0xD1
	jr z, MIDI_Status_3
	cp a, 0xD0
	jr z, MIDI_Status_3
	cp a, 0x86
	jr z, LABEL_F420AF
	cp a, 0x85
	jr z, LABEL_F420AF
	cp a, 0x80
	jr z, LABEL_F420B7
	ldb l, 0x1

MIDI_NullRet:
	ret

MIDI_Status_6:
	ldb l, 0x6
	jr MIDI_NullRet

LABEL_F420AF:
	ldb l, 0x2
	jr MIDI_NullRet

MIDI_Status_3:
	ldb l, 0x3
	jr MIDI_NullRet

LABEL_F420B7:
	ldb l, 0x4
	jr MIDI_NullRet

SeqPos_AdvanceWithWrap:
	ld c, a
	extz bc
	ldda16 xwa, 9830
	add wa, bc
	stda16 9830, xwa
	cp wa, 0xFF
	ret ule
	sub wa, 0x100
	inc 5, wa
	stda16 9830, xwa
	ldda16 xwa, 10415
	calr PartCtrl_ReadWord
	stda16 10415, xhl
	ret

LABEL_F420E5:
	.byte 0xef, 0x6c, 0x3e, 0xbf, 0x04, 0x62, 0xd9, 0x8e
	.byte 0xc9, 0x8b, 0xc7, 0xfb, 0xa8, 0xd9, 0x12, 0xd8
	.byte 0xa8, 0x1e, 0xec, 0xf6, 0xf1, 0xaf, 0x28, 0x53
	.byte 0xdb, 0xcf, 0xff, 0xff, 0x6e, 0x05, 0x33, 0xff
	.byte 0xff, 0x68, 0x4a, 0xf1, 0x66, 0x26, 0x02, 0x05
	.byte 0x00, 0xde, 0xd8, 0x63, 0x2c, 0x1e, 0x91, 0x00
	.byte 0xcf, 0xcf, 0x81, 0x6e, 0x08, 0xc7, 0xfb, 0x61
	.byte 0x1e, 0xa6, 0x00, 0x68, 0x13, 0xcf, 0xcf, 0x82
	.byte 0x66, 0x17, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x43
	.byte 0xff, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x86, 0xff
	.byte 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xde, 0xf0, 0x67
	.byte 0xd4, 0xaf, 0x04, 0x22, 0xb2, 0x16, 0xaf, 0x28
	.byte 0xd1, 0x66, 0x26, 0x20, 0xc9, 0x8b, 0xd9, 0x12
	.byte 0xba, 0x02, 0x51, 0xdb, 0xa8, 0x5e, 0xef, 0x64
	.byte 0x0e

SeqData_SkipToCurrentBar:
	push_werp 0xFA
	ldi_berp 0xFB, 0
	cpdi8 8972, 0
	jr ule, LABEL_F4218A

LABEL_F42163:
	calr SeqData_ReadNextByte
	cp l, 0x81
	jr nz, LABEL_F42173
	inc1_berp 0xFB
	calr PartCtrl_RefreshWordPeriodic
	jr LABEL_F42181

LABEL_F42173:
	extz hl
	ld wa, hl
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

LABEL_F42181:
	ldto_berp A, 0xFB
	cpda8 a, 8972
	jr c, LABEL_F42163

LABEL_F4218A:
	pop_werp 0xFA
	ret

SeqData_SeekToPartStart:
	ldda8 c, 9696
	inc 1, c
	extz bc
	lds wa, 0
	calr Part_ReadVoiceWord
	stda16 10415, xhl
	stdi16 9830, 5
	ret

; ============================================================================
; SeqData_ReadNextByte - Read next byte from sequence data stream
; ============================================================================
; Reads from Table Data ROM at 0x0B0000 region using current position (9830)
; and data pointer (10415). Returns byte in L register.
; Called by sequencer routines that check for end marks (0x81, 0x82, 0x84).
; ============================================================================
SeqData_ReadNextByte:
	ldda16 xwa, 9830
	ld c, a
	extz bc
	ldda16 xwa, 10415
	jrl PartCtrl_ReadByte

PartCtrl_WriteByte_Indexed:
	ld e, a
	ldda16 xbc, 9830
	extz bc
	extz de
	ldda16 xwa, 10415
	jrl PartCtrl_WriteByteToBuf

PartCtrl_RefreshWordPeriodic:
	ldda16 xwa, 9830
	cp wa, 0xFF
	jr nz, LABEL_F421E2
	ldda16 xwa, 10415
	calr PartCtrl_ReadWord
	stda16 10415, xhl
	stdi16 9830, 5
	ret

LABEL_F421E2:
	inc 1, wa
	stda16 9830, xwa
	ret

LABEL_F421E9:
	ldda16 xwa, 10415
	ldda16 xbc, 9830
	cp bc, 0xFF
	jr nz, LABEL_F42200
	calr PartCtrl_ReadWord
	ld wa, hl
	lds bc, 5
	jr LABEL_F42202

LABEL_F42200:
	inc 1, bc

LABEL_F42202:
	extz bc
	jrl PartCtrl_ReadByte

Voice_ScanAvailableChannel:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 16), c
	ld iz, wa
	stdi8 9696, 0

LABEL_F42215:
	ldda8 c, 9696
	inc 1, c
	extz bc
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F42235
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F42233
	slaa bc

LABEL_F42233:
	jr LABEL_F42256

LABEL_F42235:
	ldda8 a, 9696
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F42242
	slaa bc

LABEL_F42242:
	ld wa, bc
	andda16 xwa, 10408
	jr z, SeqScan_PartEntry
	bitda 1, 10417
	jr nz, SeqScan_PartEntry
	bitda 0, 10437
	jr nz, SeqScan_PartEntry

LABEL_F42256:
	cpl bc
	anddm16 8982, xbc
	jrl SeqScan_AdvancePartIndex

SeqScan_PartEntry:
	orddm16 8982, xbc
	stdi16 9614, 0
	calr SeqData_SeekToPartStart
	ldda8 a, 9696
	inc 1, a
	cpda8 a, 8988
	jrl nz, LABEL_F42342
	ldada xbc, 7590
	ldda16 xwa, 10415
	ld (xbc), wa
	ldda16 xwa, 9830
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 4)
	ldmw2 (xwa), 0x28AF
	ldmw2 (xwa + 2), 0x2666

SeqPart_ScanControlChanges:
	lda xwa, (xsp + 4)
	lda xbc, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	lda xhl, (xsp + 8)
	lda xde, (xhl + 4)
	lda xbc, (xhl + 5)
	cp (xhl + 1), 0x0
	jrl nz, LABEL_F4233F
	ld a, (xhl)
	cp a, 0x81
	jrl z, LABEL_F4233F
	cp a, 0x82
	jrl z, LABEL_F4233F
	and a, 0xF0
	cp a, 0xB0
	jr nz, SeqPart_ScanControlChanges
	ld a, (xhl + 3)
	cps a, 6
	jr nz, LABEL_F422EC
	bitm 2, (xbc)
	jr z, SeqPart_ScanControlChanges
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	setda 1, 8974
	stdi16 4360, 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr LABEL_F4232F

LABEL_F422EC:
	cps a, 5
	jr nz, SeqPart_ScanControlChanges
	ld a, (xbc)
	bit 2, a
	jr z, LABEL_F42311
	bitm 2, (xde)
	jr z, SeqPart_ScanControlChanges
	setda 1, 8974
	stdi16 4360, 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	jr LABEL_F4232F

LABEL_F42311:
	bit 3, a
	jr z, SeqPart_ScanControlChanges
	bitm 3, (xde)
	jrl z, SeqPart_ScanControlChanges
	setda 1, 8974
	stdi16 4360, 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl

LABEL_F4232F:
	calr SeqBuf_AllocNextSlot
	stda8 8972, l
	stdi16 4360, 0
	jrl SeqPart_ScanControlChanges

LABEL_F4233F:
	calr SeqData_SeekToPartStart

LABEL_F42342:
	ldda8 a, 9696
	inc 1, a
	cpda8 a, 8990
	jr nz, LABEL_F4235B
	ldada xwa, 7594
	ldmw2 (xwa), 0x28AF
	ldmw2 (xwa + 2), 0x2666

LABEL_F4235B:
	cpdm16 9614, xiz
	jrl nc, SeqScan_CheckPartActiveAndStore

LABEL_F42362:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x81
	jr nz, LABEL_F42378
	incdi16 1, 9614
	calr PartCtrl_RefreshWordPeriodic
	jrl SeqData_ContinuePos

LABEL_F42378:
	cp_erpb 0xFB, 0x82
	jr nz, LABEL_F423D4
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F4238B
	slaa bc

LABEL_F4238B:
	cpl bc
	ld wa, bc
	ldda16 xbc, 8982
	and bc, wa
	stda16 8982, xbc
	cpdi16 10408, 0
	jrl z, SeqScan_CheckPartActiveAndStore
	bitda 1, 10417
	jrl z, SeqScan_CheckPartActiveAndStore
	cpdi8 36148, 11
	jrl nz, SeqScan_CheckPartActiveAndStore
	ldda8 e, 9696
	ld a, e
	inc 1, a
	cpda8 a, 8986
	jrl nz, SeqScan_CheckPartActiveAndStore
	lds hl, 1
	ld a, e
	and a, 0xF
	jr z, LABEL_F423CB
	slaa hl

LABEL_F423CB:
	or bc, hl
	stda16 8982, xbc
	jrl SeqScan_CheckPartActiveAndStore

LABEL_F423D4:
	cp_erpb 0xFB, 0x84
	jr nz, LABEL_F423EE
	calr SeqData_SeekToPartStart
	ldda8 a, 9696
	inc 1, a
	cpda8 a, 8988
	jr nz, SeqData_ContinuePos
	calr SeqData_SkipToCurrentBar
	jr SeqData_ContinuePos

LABEL_F423EE:
	ldto_berp A, 0xFB
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqData_ContinuePos:
	cpdm16 9614, xiz
	jrl c, LABEL_F42362
	jrl SeqScan_CheckPartActiveAndStore

LABEL_F42407:
	calr SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x81
	jrl z, SeqScan_StoreTrackEndData
	cp_erpb 0xFB, 0x82
	jr nz, LABEL_F4246B
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F42427
	slaa bc

LABEL_F42427:
	cpl bc
	ld wa, bc
	ldda16 xbc, 8982
	and bc, wa
	stda16 8982, xbc
	cpdi16 10408, 0
	jr z, SeqScan_StoreTrackEndData
	bitda 1, 10417
	jr z, SeqScan_StoreTrackEndData
	cpdi8 36148, 11
	jr nz, SeqScan_StoreTrackEndData
	ldda8 e, 9696
	ld a, e
	inc 1, a
	cpda8 a, 8986
	jr nz, SeqScan_StoreTrackEndData
	lds hl, 1
	ld a, e
	and a, 0xF
	jr z, LABEL_F42463
	slaa hl

LABEL_F42463:
	or bc, hl
	stda16 8982, xbc
	jr SeqScan_StoreTrackEndData

LABEL_F4246B:
	cp_erpb 0xFB, 0x84
	jr nz, LABEL_F42485
	calr SeqData_SeekToPartStart
	ldda8 a, 9696
	inc 1, a
	cpda8 a, 8988
	jr nz, SeqScan_CheckPartActiveAndStore
	calr SeqData_SkipToCurrentBar
	jr SeqScan_CheckPartActiveAndStore

LABEL_F42485:
	calr LABEL_F421E9
	cp l, (xsp + 16)
	jr nc, SeqScan_StoreTrackEndData
	ldto_berp A, 0xFB
	extz wa
	calr MIDI_GetEventSize
	extz hl
	ld wa, hl
	calr SeqPos_AdvanceWithWrap

SeqScan_CheckPartActiveAndStore:
	lds bc, 1
	ldda8 a, 9696
	and a, 0xF
	jr z, LABEL_F424A9
	slaa bc

LABEL_F424A9:
	andda16 xbc, 8982
	jrl nz, LABEL_F42407

SeqScan_StoreTrackEndData:
	ldda8 c, 9696
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F424BF
	slaa de

LABEL_F424BF:
	andda16 xde, 8982
	jr z, SeqScan_AdvancePartIndex
	inc 1, c
	extz bc
	ldda16 xhl, 10415
	ldda16 xde, 9830
	dec 1, c
	ld a, c
	extz wa
	sla wa, 2
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ld (xwa), hl
	ld (xwa + 2), de

SeqScan_AdvancePartIndex:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jrl c, LABEL_F42215
	calr Accomp_ValidateAutoPlayChordVoice
	pop xiz
	lda xsp, (xsp + 14)
	ret

SeqScan_ProcessAllParts:
	dec 6, xsp
	push xiz
	ld (xsp + 8), wa
	ldda16 xwa, 8982
	stda16 8980, xwa
	stdi8 9696, 0

LABEL_F42512:
	ldda8 a, 9696
	ldfr_berp A, 0xF0
	lds bc, 1
	ldto_berp A, 0xF0
	and a, 0xF
	jr z, LABEL_F42525
	slaa bc

LABEL_F42525:
	ld wa, bc
	andda16 xwa, 8982
	lda xde, (xsp + 4)
	ldada xhl, 9184
	lda xbc, (xde + 2)
	cps wa, 0
	jrl z, LABEL_F425CE
	ldto_berp A, 0xF0
	extz wa
	ld iy, wa
	sla iy, 3
	ldada xix, 9016
	ld wa, (xsp + 8)
	st_dri3w WA, 0x07, 0xF0, 0xF4
	ldda8 a, 9696
	inc 1, a
	ldfr_berp A, 0xE2
	extz wa
	dec 1, a
	extz wa
	sla wa, 2
	st_dri3b H, 0x07, 0xEC, 0xE0
	lda xiy, (xiz + 2)
	ldto_berp A, 0xE2
	cpda8 a, 8988
	jr nz, LABEL_F42596
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
	st_dri3w WA, 0xF1, 0x98, 0x00
	ldw wa, 0x14
	jr LABEL_F425C0

LABEL_F42596:
	ldto_berp A, 0xE2
	cpda8 a, 8996
	jr nz, LABEL_F425C3
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
	st_dri3w WA, 0xF1, 0xA0, 0x00
	ldw wa, 0x15

LABEL_F425C0:
	calr SeqCh_LoadChannelConfig

LABEL_F425C3:
	ldda8 a, 9696
	inc 1, a
	extz wa
	calr SeqCh_LoadChannelConfig

LABEL_F425CE:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jrl c, LABEL_F42512
	pop xiz
	inc 6, xsp
	ret

Part_CheckAndReallocVoices:
	pushw iz
	ld iz, wa
	ld wa, iz
	calr PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F4260A
	cp wa, 0x4D8
	jr ule, LABEL_F425FF
	stdi8 10362, 10
	jr LABEL_F4260A

LABEL_F425FF:
	calr Part_StealAndReallocVoices
	ld wa, iz
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord

LABEL_F4260A:
	popw iz
	ret

LABEL_F4260C:
	.byte 0xef, 0x68, 0x3e, 0xd8, 0x8e, 0xbf, 0x08, 0x51
	.byte 0xbf, 0x0a, 0x16, 0x2f, 0xf2, 0xf1, 0x2f, 0xf2
	.byte 0x56, 0xbf, 0x04, 0x02, 0x00, 0x00, 0xde, 0x88
	.byte 0x1e, 0x12, 0xf6, 0xbf, 0x06, 0x53, 0xde, 0x88
	.byte 0xd9, 0xa8, 0x1e, 0x1b, 0xf6, 0xde, 0x88, 0x1e
	.byte 0x29, 0xf6, 0xd7, 0xfa, 0x9b, 0xd7, 0xfa, 0xcf
	.byte 0xff, 0xff, 0x6e, 0x46, 0xbf, 0x08, 0x56, 0x9f
	.byte 0x04, 0x61, 0x9f, 0x06, 0x3f, 0x00, 0x00, 0x66
	.byte 0x09, 0x9f, 0x06, 0x20, 0xd7, 0xfa, 0x89, 0x1e
	.byte 0x1c, 0xf6, 0x9f, 0x08, 0x20, 0xd9, 0xa8, 0x1e
	.byte 0x3b, 0xf6, 0x9f, 0x08, 0x20, 0xd9, 0xad, 0x32
	.byte 0x82, 0x00, 0x1e, 0x60, 0xf6, 0x9f, 0x08, 0x20
	.byte 0x9f, 0x0a, 0x21, 0x1e, 0x00, 0xf6, 0x9f, 0x0a
	.byte 0x20, 0x9f, 0x08, 0x21, 0x1e, 0xd1, 0xf5, 0x9f
	.byte 0x04, 0x20, 0xd1, 0x31, 0xf2, 0x88, 0x5e, 0xef
	.byte 0x60, 0x0e, 0xde, 0x88, 0xd9, 0xa8, 0x1e, 0x0c
	.byte 0xf6, 0xde, 0x88, 0xd9, 0xad, 0x32, 0x82, 0x00
	.byte 0x1e, 0x32, 0xf6, 0x9f, 0x04, 0x61, 0x9f, 0x04
	.byte 0x20, 0x9f, 0x08, 0xf0, 0x6e, 0x16, 0xbf, 0x08
	.byte 0x56, 0xde, 0x88, 0x1e, 0xb5, 0xf5, 0xd7, 0xfa
	.byte 0x9b, 0xd7, 0xfa, 0x88, 0x9f, 0x06, 0x21, 0x1e
	.byte 0x96, 0xf5, 0x68, 0x8e, 0xd7, 0xfa, 0x8e, 0x78
	.byte 0x73, 0xff

PartCtrl_ReadWordRoutine:
	push xiz
	ldda16 xiz, 61999
	cp iz, 0xFFFF
	jr nz, LABEL_F426CE
	ldw hl, 0xFFFF
	jr LABEL_F42708

LABEL_F426CE:
	ld wa, iz
	calr PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ld wa, iz
	lds bc, 0
	calr PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	calr PartCtrl_WriteWord
	ld wa, iz
	lds bc, 1
	calr PartCtrl_SetClearBit7
	ldto_werp WA, 0xFA
	stda16 61999, xwa
	cp_erpw 0xFA, 0xFF, 0xFF
	jr z, LABEL_F42702
	ldto_werp WA, 0xFA
	lds bc, 0
	calr PartCtrl_WriteWord_Off1

LABEL_F42702:
	decdi16 1, 62001
	ld hl, iz

LABEL_F42708:
	pop xiz
	ret

Rhythm_ComputeNoteAllocation:
	dec 4, xsp
	ldw (xsp + 2), 0x0
	ld (xsp), 0x0
	lda xbc, (xsp + 2)
	lda xde, (xsp)
	calr LABEL_F42852
	ld hl, (xsp + 2)
	inc 4, xsp
	ret

LABEL_F42722:
	.byte 0xef, 0x68, 0x3e, 0xbf, 0x06, 0x62, 0xd9, 0x8e
	.byte 0xbf, 0x0a, 0x41, 0xbf, 0x04, 0x02, 0x00, 0x00
	.byte 0x8f, 0x0a, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1e
	.byte 0x96, 0xef, 0xc7, 0xfb, 0x9f, 0xbf, 0x04, 0x31
	.byte 0xde, 0x88, 0xaf, 0x06, 0x22, 0x1e, 0x08, 0x01
	.byte 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0xc7, 0xfb, 0xcf
	.byte 0x0d, 0x66, 0x11, 0xc7, 0xfb, 0xcf, 0x10, 0x6e
	.byte 0x49, 0x1e, 0xad, 0x05, 0xdb, 0x8e, 0xde, 0xd8
	.ascii "n3h>"
	.byte 0x1e, 0xa2, 0x05, 0xdb
	.byte 0x8e, 0xde, 0xd8, 0x66, 0x35, 0x9f, 0x04, 0xfe
	.byte 0x67, 0x30, 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0x1e
	.byte 0x02, 0x06, 0xdb, 0xd8, 0x66, 0x17, 0xde, 0x89
	.byte 0xdb, 0xa1, 0x9f, 0x04, 0x20, 0xdb, 0xa0, 0xe8
	.byte 0x12, 0xd9, 0x50, 0xd7, 0xe2, 0x88, 0xdb, 0x80
	.byte 0xbf, 0x04, 0x50, 0x68, 0x0d, 0x9f, 0x04, 0x20
	.byte 0xe8, 0x12, 0xde, 0x50, 0xd7, 0xe2, 0x88, 0xbf
	.byte 0x04, 0x50, 0x9f, 0x04, 0x23, 0x5e, 0xef, 0x60
	.byte 0x0e

LABEL_F427AB:
	dec 6, xsp
	push xiz
	ldw (xsp + 8), 0x0
	ld (xsp + 6), 0x0
	ld (xsp + 4), 0x0
	calr LABEL_F42828
	cps l, 0
	jr z, LABEL_F427D3
	calr LABEL_F42835
	cpdi16 61854, 0
	jr z, LABEL_F427D3
	bitda 2, 1057
	jr z, LABEL_F427D7

LABEL_F427D3:
	ldb l, 0xFF
	jr LABEL_F42824

LABEL_F427D7:
	calr LABEL_F4283A
	ld iz, hl
	srl iz, 2
	and hl, 0x3
	ldfr_berp L, 0xFB
	lda xbc, (xsp + 8)
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	ld wa, iz
	calr LABEL_F429A0
	stda16 1052, xiz
	ldto_berp A, 0xFB
	mul a, 0x18
	stda8 1051, a
	mrdb5 0x8F, 0x04, 0x19, 0x32, 0x23
	call SeqMode_SendStatusUpdate
	mrdw5 0x9F, 0x08, 0x19, 0x68, 0x26
	call NoteEditSy_SendModeScrollReset
	ld c, (xsp + 6)
	extz bc
	ld wa, iz
	sub wa, bc
	stda16 9008, xwa
	ldb l, 0x0

LABEL_F42824:
	pop xiz
	inc 6, xsp
	ret

LABEL_F42828:
	ldda8 a, 1070
	and a, 0x80
	srl a, 7
	ld l, a
	ret

LABEL_F42835:
	resda 7, 1070
	ret

LABEL_F4283A:
	ldda8 l, 1069
	res 7, l
	extz hl
	ldda8 a, 1070
	res 7, a
	extz wa
	sll wa, 7
	add hl, wa
	ret

LABEL_F42852:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 14), xde
	ld (xsp + 18), xbc
	ld (xsp + 22), wa
	ld xiy, 0xE44610
	lda xix, (xsp + 10)
	ldiw
	ldiw
	ld xiy, 0xE44614
	lda xix, (xsp + 6)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr nz, LABEL_F4289F
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
	jrl LABEL_F42981

LABEL_F4289F:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xFA
	lds iz, 1
	ldw (xsp + 4), 0x0
	ld xwa, (xsp + 18)
	ldw (xwa), 0x0
	ldto_berp C, 0xFB
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
	ldi_berp 0xFB, 1
	cpw (xsp + 22), 0x1
	jr ule, LABEL_F42950

LABEL_F428DB:
	lda xwa, (xsp + 6)
	calr SeqEvent_ProcessRhythm4Ch
	ld e, l
	ldto_berp C, 0xFA
	extz bc
	cp l, 0xB1
	jr z, SeqPart_NoteProcessing_Loop
	cp e, 0xB0
	jr z, SeqPart_NoteProcessing_Loop
	cp e, 0x84
	jr z, LABEL_F42936
	cp e, 0x82
	jr z, LABEL_F42917
	cp e, 0x81
	jr nz, LABEL_F42948
	ld xwa, (xsp + 18)
	incm 1, (xwa)
	incm 1, (xsp + 4)
	cp (xsp + 4), bc
	jr c, SeqPart_NoteProcessing_Loop
	inc 1, iz
	ldw (xsp + 4), 0x0
	jr SeqPart_NoteProcessing_Loop

LABEL_F42917:
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
	ldi_berp 0xFB, 0
	jr SeqPart_NoteProcessing_Loop

LABEL_F42936:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xFA
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr SeqPart_NoteProcessing_Loop

LABEL_F42948:
	ldfr_berp L, 0xFA

SeqPart_NoteProcessing_Loop:
	cp iz, (xsp + 22)
	jr c, LABEL_F428DB

LABEL_F42950:
	cpi_berp 0xFB, 1
	jr nz, LABEL_F42979

LABEL_F42955:
	lda xwa, (xsp + 6)
	calr SeqEvent_ProcessRhythm4Ch
	cp l, 0x82
	jr z, LABEL_F4299B
	cp l, 0x81
	jr z, LABEL_F4299B
	cp l, 0x84
	jr z, LABEL_F42986
	cp l, 0xB1
	jr z, LABEL_F42974
	cp l, 0xB0
	jr nz, LABEL_F42998

LABEL_F42974:
	cpi_berp 0xFB, 1
	jr z, LABEL_F42955

LABEL_F42979:
	ld xwa, (xsp + 14)
	ldto_berp C, 0xFA
	ld (xwa), c

LABEL_F42981:
	pop xiz
	lda xsp, (xsp + 20)
	ret

LABEL_F42986:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xFA
	lda xiy, (xsp + 10)
	lda xix, (xsp + 6)
	ldiw
	ldiw
	jr LABEL_F42974

LABEL_F42998:
	ldfr_berp L, 0xFA

LABEL_F4299B:
	ldi_berp 0xFB, 0
	jr LABEL_F42979

LABEL_F429A0:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 16), xde
	ld (xsp + 20), xbc
	ld (xsp + 24), wa
	ld xiy, 0xE44618
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, 0xE4461C
	lda xix, (xsp + 8)
	ldiw
	ldiw
	calr SeqPart_FindActiveVoiceSlot
	ldfr_berp L, 0xFA
	cpi_berp 0xFA, 0
	jr nz, LABEL_F429F6
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
	jrl LABEL_F42ACC

LABEL_F429F6:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xFB
	ldw (xsp + 4), 0x1
	ldw (xsp + 6), 0x0
	ldi_berp 0xF9, 0
	ld xwa, (xsp + 20)
	ldw (xwa), 0x1
	ldto_berp C, 0xFA
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
	jrl ule, LABEL_F42AB9

LABEL_F42A36:
	lda xwa, (xsp + 8)
	calr SeqEvent_ProcessRhythm4Ch
	ld a, l
	cp l, 0xB1
	jr z, Rhythm_NoteAllocation_Finalize
	cp a, 0xB0
	jr z, Rhythm_NoteAllocation_Finalize
	cp a, 0x84
	jr z, LABEL_F42A9B
	cp a, 0x82
	jr z, LABEL_F42A6D
	cp a, 0x81
	jr nz, LABEL_F42AAD
	incm 1, (xsp + 6)
	inc1_berp 0xF9
	ldto_berp A, 0xF9
	cp_berp A, 0xFB
	jr c, Rhythm_NoteAllocation_Finalize
	incm 1, (xsp + 4)
	ldi_berp 0xF9, 0
	jr Rhythm_NoteAllocation_Finalize

LABEL_F42A6D:
	ldto_berp A, 0xFB
	sub_berp A, 0xF9
	extz wa
	add (xsp + 6), wa
	incm 1, (xsp + 4)
	ldto_berp C, 0xFB
	extz bc
	ld de, (xsp + 24)
	sub de, (xsp + 6)
	ld wa, de
	extz xwa
	div xwa, xbc
	add (xsp + 4), wa
	extz xde
	div xde, xbc
	ldto_werp WA, 0xEA
	ldfr_berp A, 0xF9
	jr Rhythm_NoteAllocation_Finalize

LABEL_F42A9B:
	calr SeqPart_DispatchRhythmNote
	ldfr_berp L, 0xFB
	lda xiy, (xsp + 12)
	lda xix, (xsp + 8)
	ldiw
	ldiw
	jr Rhythm_NoteAllocation_Finalize

LABEL_F42AAD:
	ldfr_berp L, 0xFB

Rhythm_NoteAllocation_Finalize:
	ld wa, (xsp + 6)
	cp wa, (xsp + 24)
	jrl c, LABEL_F42A36

LABEL_F42AB9:
	ld xwa, (xsp + 20)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ld xwa, (xsp + 30)
	ldto_berp C, 0xFB
	ld (xwa), c
	ldto_berp C, 0xF9

LABEL_F42ACC:
	ld xwa, (xsp + 16)
	ld (xwa), c
	pop xiz
	lda xsp, (xsp + 22)
	retd 0x4

SeqPart_FindActiveVoiceSlot:
	push_werp 0xFA
	ldi_berp 0xFB, 1

LABEL_F42ADE:
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	calr Part_ReadSubBlock32
	cp l, 0x10
	jr nz, LABEL_F42B15
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F42AFB
	slaa bc

LABEL_F42AFB:
	andda16 xbc, 61854
	jr z, LABEL_F42B0F
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F42B1E

LABEL_F42B0F:
	ldi_erpb 0xFB, 0x11
	jr LABEL_F42B24

LABEL_F42B15:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F42ADE

LABEL_F42B1E:
	cp_erpb 0xFB, 0x11
	jr nz, LABEL_F42B27

LABEL_F42B24:
	ldi_berp 0xFB, 0

LABEL_F42B27:
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

SeqPart_DispatchRhythmNote:
	push xiz
	ldada xwa, 64602
	sub xwa, 0xF980
	ld iz, wa
	add iz, 0x2E0
	lds wa, 0
	ld bc, iz
	calr Part_ReadByteDirect
	ldfr_berp L, 0xFB
	ld bc, iz
	inc 1, bc
	lds wa, 0
	calr Part_ReadByteDirect
	ldto_berp A, 0xFB
	extz wa
	extz hl
	ld bc, hl
	call Rhythm_NoteDispatchWrapper
	pop xiz
	ret

SeqEvent_ProcessRhythm4Ch:
	lda xsp, (xsp - 12)
	push_werp 0xFA
	ld (xsp + 10), xwa
	ld xiy, 0xE44620
	lda xix, (xsp + 2)
	lds bc, 4
	ldirw
	ldi_berp 0xFB, 1

LABEL_F42B79:
	lda xbc, (xsp + 2)
	ld xwa, (xsp + 10)
	calr SeqPart_ReadNextEventByte
	lda xbc, (xsp + 2)
	ld a, (xbc)
	cp a, 0xC1
	jr z, SeqEvent_DispatchRhythmIfMatch
	cp a, 0xC0
	jr z, SeqEvent_DispatchRhythmIfMatch
	cp a, 0x84
	jr z, SeqEvent_ProcessRhythm3Ch
	cp a, 0x82
	jr z, SeqEvent_ProcessRhythm3Ch
	cp a, 0x81
	jr z, SeqEvent_ProcessRhythm3Ch

LABEL_F42BA0:
	cpi_berp 0xFB, 1
	jr z, LABEL_F42B79

LABEL_F42BA5:
	ld l, (xsp + 2)
	pop_werp 0xFA
	lda xsp, (xsp + 12)
	ret

SeqEvent_DispatchRhythmIfMatch:
	cp (xbc + 2), 0x48
	jr nz, LABEL_F42BA0
	cp (xbc + 3), 0x0
	jr nz, LABEL_F42BA0
	and a, 0x1
	sll a, 7
	add a, (xbc + 4)
	ld c, (xbc + 5)
	extz wa
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld (xsp + 2), l

SeqEvent_ProcessRhythm3Ch:
	ldi_berp 0xFB, 0
	jr LABEL_F42BA5
	lda xsp, (xsp - 10)
	push_werp 0xFA
	ld (xsp + 8), xwa
	ld xiy, 0xE44628
	lda xix, (xsp + 2)
	lds bc, 3
	ldirw
	ldi_berp 0xFB, 1

LABEL_F42BEF:
	lda xbc, (xsp + 2)
	ld xwa, (xsp + 8)
	calr SeqPart_ReadNextEventByte
	lda xiy, (xsp + 2)
	ld a, (xiy)
	lda xbc, (xiy + 2)
	lda xde, (xiy + 3)
	lda xhl, (xiy + 4)
	lda xix, (xiy + 5)
	cp a, 0xC1
	jrl z, LABEL_F42CD7
	cp a, 0xC0
	jrl z, LABEL_F42CD7
	cp a, 0x84
	jrl z, Rhythm_ClearAndReturn
	cp a, 0x82
	jrl z, Rhythm_ClearAndReturn
	cp a, 0x81
	jrl z, Rhythm_ClearAndReturn
	cp a, 0xB7
	jrl ugt, AppEvent_CheckAndBranch
	cp a, 0xB0
	jrl c, AppEvent_CheckAndBranch
	cp (xbc), 0x48
	jrl nz, AppEvent_CheckAndBranch
	cp (xde), 0x5
	jr nz, LABEL_F42C6A
	ld a, (xix)
	and a, (xhl)
	bit 2, a
	jr z, LABEL_F42C6A
	ld (xiy), 0xB0
	stdi16 4360, 4
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	stda8 8972, l
	stdi16 4360, 0
	ldi_berp 0xFB, 0

LABEL_F42C6A:
	lda xbc, (xsp + 2)
	cp (xbc + 3), 0x6
	jr nz, LABEL_F42CA1
	ld a, (xbc + 5)
	and a, (xbc + 4)
	bit 2, a
	jr z, LABEL_F42CA1
	ld (xbc), 0xB0
	stdi16 4360, 1024
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	stda8 8972, l
	stdi16 4360, 0
	ldi_berp 0xFB, 0

LABEL_F42CA1:
	lda xbc, (xsp + 2)
	cp (xbc + 3), 0x5
	jr nz, AppEvent_CheckAndBranch
	ld a, (xbc + 5)
	and a, (xbc + 4)
	bit 3, a
	jr z, AppEvent_CheckAndBranch
	ld (xbc), 0xB1
	stdi16 4360, 8
	call AccTone_ReadAndProcess
	extz hl
	inc 1, hl
	ld wa, hl
	calr SeqBuf_AllocNextSlot
	stda8 8972, l
	stdi16 4360, 0
	jr Rhythm_ClearAndReturn

LABEL_F42CD7:
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
	ldi_berp 0xFB, 0
	jr LABEL_F42D01

AppEvent_CheckAndBranch:
	cpi_berp 0xFB, 1
	jrl z, LABEL_F42BEF

LABEL_F42D01:
	ld l, (xsp + 2)
	pop_werp 0xFA
	lda xsp, (xsp + 10)
	ret

LABEL_F42D0B:
	.byte 0xbf, 0xf6, 0x37, 0xbf, 0x08, 0x41, 0xb7, 0x02
	.byte 0x00, 0x00, 0xbf, 0x02, 0x00, 0x01, 0x45, 0x2e
	.byte 0x46, 0xe4, 0x00, 0xbf, 0x04, 0x34, 0x95, 0x10
	.byte 0x95, 0x10, 0x8f, 0x08, 0x23, 0xd9, 0x12, 0xd8
	.byte 0xa8, 0x1e, 0xa3, 0xe9, 0xcf, 0xcf, 0x10, 0x66
	.byte 0x09, 0xcf, 0xcf, 0x0d, 0x66, 0x04, 0xdb, 0xa8
	.byte 0x68, 0x33, 0x8f, 0x08, 0x23, 0xd9, 0x12, 0xd8
	.byte 0xa8, 0x1e, 0x9e, 0xea, 0xbf, 0x04, 0x30, 0xb0
	.byte 0x53, 0xb8, 0x02, 0x02, 0x05, 0x00, 0xbf, 0x04
	.byte 0x30, 0x1e, 0x0a, 0xfe, 0xcf, 0xcf, 0x84, 0x66
	.byte 0x1c, 0xcf, 0xcf, 0x82, 0x66, 0x13, 0xcf, 0xcf
	.byte 0x81, 0x6e, 0x02, 0x97, 0x61, 0x8f, 0x02, 0x3f
	.byte 0x01, 0x66, 0xe3, 0x97, 0x23, 0xbf, 0x0a, 0x37
	.byte 0x0e, 0xb7, 0x02, 0x00, 0x00, 0xbf, 0x02, 0x00
	.byte 0x00, 0x68, 0xf0, 0xbf, 0xf6, 0x37, 0xbf, 0x08
	.byte 0x41, 0xb7, 0x02, 0x00, 0x00, 0xbf, 0x02, 0x00
	.byte 0x01, 0x45, 0x32, 0x46, 0xe4, 0x00, 0xbf, 0x04
	.byte 0x34, 0x95, 0x10, 0x95, 0x10, 0x8f, 0x08, 0x23
	.byte 0xd9, 0x12, 0xd8, 0xa8, 0x1e, 0x30, 0xe9, 0xcf
	.byte 0xcf, 0x0d, 0x66, 0x04, 0xdb, 0xa8, 0x68, 0x3b
	.byte 0x8f, 0x08, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1e
	.byte 0x30, 0xea, 0xbf, 0x04, 0x30, 0xb0, 0x53, 0xb8
	.byte 0x02, 0x02, 0x05, 0x00, 0xbf, 0x04, 0x30, 0x1e
	.byte 0x12, 0xfe, 0xcf, 0xcf, 0xb1, 0x66, 0x20, 0xcf
	.byte 0xcf, 0xb0, 0x66, 0x1b, 0xcf, 0xcf, 0x84, 0x66
	.byte 0x1e, 0xcf, 0xcf, 0x82, 0x66, 0x19, 0xcf, 0xcf
	.byte 0x81, 0x66, 0x14, 0x8f, 0x02, 0x3f, 0x01, 0x66
	.byte 0xdb, 0x97, 0x23, 0xbf, 0x0a, 0x37, 0x0e, 0xc1
	.byte 0x0c, 0x23, 0x21, 0xd8, 0x12, 0xb7, 0x50, 0xbf
	.byte 0x02, 0x00, 0x00, 0x68, 0xec

LABEL_F42DF8:
	ret

LABEL_F42DF9:
	stdi16 10349, 1240
	lda_24 xwa, 0x0b0000
	stda32 7514, xwa
	ret

LABEL_F42E09:
	jrl Part_InitFromPreset

LABEL_F42E0C:
	push_werp 0xFA
	stdi16 9832, 1
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	calr SeqVoice_SetDefaultParams
	calr LABEL_F431F5
	calr SeqParams_InitDefaults
	call BmDrEdit_InitDisplayParams
	call Audio_CheckSubsystemReady
	ldi_berp 0xFB, 0

LABEL_F42E33:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xCB
	lds de, 0
	calr Part_WriteByte
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F42E33
	pushw 0x1
	ldw wa, 0x91
	lds bc, 3
	lds de, 0
	call AddswbWr
	ldi_berp 0xFB, 0

LABEL_F42E5A:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1C
	calr Part_ReadWord
	cps hl, 0
	jr z, LABEL_F42E74
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x32
	calr Part_ReleaseVoicesForRange

LABEL_F42E74:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F42E5A
	stdi16 9500, 1
	stdi16 9502, 1
	stdi16 9504, 1
	stdi16 9506, 1
	stdi8 10417, 0
	lds wa, 0
	call VoiceParam_SetD6Group
	pop_werp 0xFA
	ret

Part_InitFromPreset:
	lda xsp, (xsp - 16)
	push xiz
	ld xiy, 0xE44646
	lda xix, (xsp + 4)
	ldw bc, 0x8
	ldirw
	ldi_berp 0xFB, 0

LABEL_F42EB8:
	ldto_berp A, 0xFB
	extz wa
	call DataBuf_InitSlotFromPreset
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F42EB8
	ldi_berp 0xFB, 0

LABEL_F42ECD:
	ldto_berp A, 0xFB
	extz wa
	calr Part_InitVoiceDefaults
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1C
	lds de, 0
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x1E
	lds de, 0
	calr Part_WriteWord
	calr SeqStatus_CheckBit2
	ldto_berp A, 0xFB
	extz wa
	cps l, 0
	jr nz, LABEL_F42F00
	calr Part_WriteAllVoiceSubBlocks_A
	jr LABEL_F42F03

LABEL_F42F00:
	calr Part_WriteAllVoiceSubBlocks_B

LABEL_F42F03:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x50
	ldw de, 0xFFFF
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x52
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x53
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x54
	lds de, 2
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x55
	lds de, 3
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x56
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x57
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x59
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x5B
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x5C
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x5E
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x60
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x61
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x62
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x64
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x66
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x67
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x69
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x6A
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x6C
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x6E
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x6F
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x71
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x72
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x74
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x76
	lds de, 3
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x77
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xA8
	lds de, 1
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xA9
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xAB
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xAD
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xAE
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB3
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB4
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB5
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB6
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xB8
	lds de, 1
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xBA
	lds de, 2
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xBC
	lds de, 0
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xBF
	lds de, 0
	calr Part_WriteWord
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xBE
	calr Part_ReadByteDirect
	set 0, l
	ldto_berp A, 0xFB
	extz wa
	extz hl
	ldw bc, 0xBE
	ld de, hl
	calr Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0xCB
	lds de, 0
	calr Part_WriteByte
	lds iz, 0

LABEL_F43138:
	ldto_berp A, 0xFB
	extz wa
	ld bc, iz
	add bc, 0x113
	lds de, 0
	calr Part_WriteByte
	inc 1, iz
	cp iz, 0x1CD
	jr c, LABEL_F43138
	ldto_berp A, 0xFB
	extz wa
	lda xbc, (xsp + 4)
	calr Part_CopyBlock16
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x110
	ldw de, 0xFFFF
	calr Part_WriteWord
	call VoiceChannels_InitPanFromPreset
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x112
	lds de, 1
	calr Part_WriteByte
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jrl ule, LABEL_F42ECD
	call Audio_CheckSubsystemReady
	resda 0, 10405
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	ldw wa, 0xB
	ldw bc, 0x32
	calr Part_ReleaseVoicesForRange
	calr Part_UnlinkVoiceFromChain
	stdi8 10418, 0
	stdi16 9832, 1
	sti8_24 0x00ffe3, 0x00
	stdi16 9500, 1
	stdi16 9502, 1
	stdi16 9504, 1
	stdi16 9506, 1
	stdi8 10417, 0
	stdi8 8956, 0
	resda 0, 8970
	stdi8 10430, 255
	stdi8 8976, 0
	resda 0, 36232
	stdi8 7518, 0
	calr SeqParams_InitDefaults
	call BmDrEdit_InitDisplayParams
	pop xiz
	lda xsp, (xsp + 16)
	ret

LABEL_F431F5:
	ldda8 a, 10407
	res 3, a
	res 1, a
	res 0, a
	stda8 10407, a
	jp SeqAcc_InitPlaybackState

LABEL_F4320A:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F4321B
	slaa bc

LABEL_F4321B:
	andda16 xbc, 61854
	ld a, (xsp)
	extz wa
	bitda 2, 1057
	jr z, LABEL_F43242
	cps bc, 0
	jr z, LABEL_F43232
	calr LABEL_F43374
	jr SeqPlay_PostInitReturn

LABEL_F43232:
	calr Part_IsVoiceActive
	cps hl, 0
	jr z, SeqPlay_PostInitReturn
	ld a, (xsp)
	extz wa
	calr LABEL_F43309
	jr SeqPlay_PostInitReturn

LABEL_F43242:
	cps bc, 0
	jr z, LABEL_F4324B
	calr Part_DeactivateChannel
	jr LABEL_F43259

LABEL_F4324B:
	calr Part_IsVoiceActive
	cps hl, 0
	jr z, SeqPlay_PostInitReturn
	ld a, (xsp)
	extz wa
	calr SeqVoice_ActivateWithBarSync

LABEL_F43259:
	calr SeqPlay_InitStartState

SeqPlay_PostInitReturn:
	calr Accomp_ValidateAutoPlayChordVoice
	ldmm16 10296, 61854
	inc 2, xsp
	ret

LABEL_F43268:
	dec 2, xsp
	ld (xsp), a
	bitda 2, 1057
	jrl nz, LABEL_F43306
	stdi8 9508, 1
	ld a, (xsp)
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F43285
	slaa bc

LABEL_F43285:
	ld de, bc
	andda16 xde, 10408
	ld a, (xsp)
	extz wa
	cps de, 0
	jr nz, LABEL_F432AA
	andda16 xbc, 61854
	jr nz, LABEL_F4329E
	calr LABEL_F4342B
	jr SeqPlay_ClearFlags_Exit

LABEL_F4329E:
	calr Part_DeactivateChannel
	ld a, (xsp)
	extz wa
	calr SeqVoice_DeactivateAndReinit
	jr SeqPlay_ClearFlags_Exit

LABEL_F432AA:
	calr SeqVoice_DeactivateAndReinit
	ld a, (xsp)
	extz wa
	calr Part_IsVoiceActive
	ld a, (xsp)
	extz wa
	cps hl, 0
	jr z, LABEL_F432C1
	calr SeqVoice_ActivateWithBarSync
	jr SeqPlay_ClearFlags_Exit

LABEL_F432C1:
	calr Part_DeactivateChannel

SeqPlay_ClearFlags_Exit:
	resda 3, 10407
	ldda8 a, 36150
	cp a, 0x87
	jr z, SeqPlay_ResetModeAndDisplay
	cp a, 0x88
	jr z, SeqPlay_ResetModeAndDisplay
	bitda 1, 10417
	jr nz, LABEL_F432E4
	stdi16 9832, 1
	jr SeqPlay_ResetModeAndDisplay

LABEL_F432E4:
	ldmm16 9832, 9504
	cpdi16 9832, 1
	jr z, SeqPlay_ResetModeAndDisplay
	setda 3, 10407

SeqPlay_ResetModeAndDisplay:
	call NoteEditSy_SendModeScrollReset
	calr SeqPlay_InitStartState
	calr Accomp_ValidateAutoPlayChordVoice
	ldmm16 10296, 61854

LABEL_F43306:
	inc 2, xsp
	ret

LABEL_F43309:
	dec 2, xsp
	ld (xsp), a
	cpdi16 61854, 0
	jr nz, LABEL_F4334A
	bitda 0, 10417
	jr z, LABEL_F43325
	ldda16 xwa, 9500
	cpdm16 9832, xwa
	jr ugt, LABEL_F4332D

LABEL_F43325:
	stdi16 9832, 1
	jr LABEL_F43331

LABEL_F4332D:
	stda16 9832, xwa

LABEL_F43331:
	call NoteEditSy_SendModeScrollReset
	cpdi16 9832, 1
	jr nz, LABEL_F43343
	resda 3, 10407
	jr LABEL_F43347

LABEL_F43343:
	setda 3, 10407

LABEL_F43347:
	calr SeqPlay_InitStartState

LABEL_F4334A:
	ld a, (xsp)
	cpda8 a, 8996
	jr nz, Chan_ActivateAndNotify
	bitda 6, 10413
	jr z, Chan_ActivateAndNotify
	ldda8 a, 9828
	stda8 10414, a
	setda 7, 10414

Chan_ActivateAndNotify:
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

LABEL_F43374:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	cpda8 a, 8996
	jr nz, LABEL_F43388
	resda 7, 10414
	call MidiChannel_ResetAndConfigure

LABEL_F43388:
	ld a, (xsp)
	extz wa
	lds bc, 0
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	cpdi16 61854, 0
	jr nz, Chan_DeactivateAfterAccomp
	bitda 2, 1054
	jr z, LABEL_F433A9
	call AccWrap_PlayModeStopExpr
	jr Chan_DeactivateAfterAccomp

LABEL_F433A9:
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
	cpdi16 61854, 0
	jr nz, LABEL_F433F9
	bitda 0, 10417
	jr z, LABEL_F433D3
	ldda16 xwa, 9500
	cpdm16 9832, xwa
	jr ugt, LABEL_F433DB

LABEL_F433D3:
	stdi16 9832, 1
	jr LABEL_F433DF

LABEL_F433DB:
	stda16 9832, xwa

LABEL_F433DF:
	call NoteEditSy_SendModeScrollReset
	cpdi16 9832, 1
	jr nz, LABEL_F433F1
	resda 3, 10407
	jr LABEL_F433F5

LABEL_F433F1:
	setda 3, 10407

LABEL_F433F5:
	call AccWrap_PlayModeDispatch

LABEL_F433F9:
	ld a, (xsp)
	extz wa
	calr SeqVoice_UpdateSubBlockAssign
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	inc 2, xsp
	ret

Part_DeactivateChannel:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	lds bc, 0
	calr Chan_SetActiveBit
	call Audio_CheckSubsystemReady
	ld a, (xsp)
	extz wa
	calr Part_DeactivateVoiceChannel
	inc 2, xsp
	ret

LABEL_F4342B:
	dec 2, xsp
	ld (xsp), a
	lds wa, 0
	ldw bc, 0x10
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, LABEL_F43452
	ld a, (xsp)
	extz wa
	calr Part_IsVoiceActive
	cps hl, 0
	jr z, LABEL_F4344F
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr Chan_SetActiveBit

LABEL_F4344F:
	jrl LABEL_F434EF

LABEL_F43452:
	lds wa, 0
	ldw bc, 0xD
	calr Part_FindVoiceByByte
	cp (xsp), l
	jr nz, LABEL_F43471
	bitda 1, 10417
	jr z, LABEL_F43471
	ld c, (xsp)
	extz bc
	lds wa, 0
	calr Part_ReadVoiceBit7
	cps l, 0
	jr nz, LABEL_F434EF

LABEL_F43471:
	cpdi16 10408, 0
	jr nz, LABEL_F4347D
	resda 2, 10407

LABEL_F4347D:
	ld a, (xsp)
	extz wa
	calr LABEL_F4357E
	bitda 1, 10417
	jr z, LABEL_F43494
	stdi16 10408, 0
	call Audio_CheckSubsystemReady

LABEL_F43494:
	ld a, (xsp)
	extz wa
	lds bc, 1
	calr SeqVoice_SetOrClearBitMask
	ld a, (xsp)
	extz wa
	lds bc, 0
	calr Chan_SetActiveBit
	cpdi8 36148, 11
	jr z, LABEL_F434DC
	stdi16 10420, 0
	stdi16 9008, 0
	stdi16 9832, 1
	ldmm8 9010, 1075
	resda 3, 10407
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	call SeqBuf_Init

LABEL_F434DC:
	call Audio_CheckSubsystemReady
	ldda8 a, 1056
	and a, 0x5
	call_24 z, 0xF59AB9
	calr Part_DetectSingleVoiceType

LABEL_F434EF:
	inc 2, xsp
	ret

SeqVoice_DeactivateAndReinit:
	dec 2, xsp
	ld (xsp), a
	ld a, (xsp)
	extz wa
	lds bc, 0
	calr SeqVoice_SetOrClearBitMask
	call Audio_CheckSubsystemReady
	ld a, (xsp)
	extz wa
	calr SeqVoice_UpdateSubBlockAssign
	cpdi8 36148, 11
	jr z, LABEL_F43540
	stdi16 10420, 0
	stdi16 9008, 0
	stdi16 9832, 1
	ldmm8 9010, 1075
	resda 3, 10407
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	call SeqBuf_Init

LABEL_F43540:
	calr Part_DetectSingleVoiceType
	inc 2, xsp
	ret

SeqVoice_UpdateSubBlockAssign:
	dec 2, xsp
	ld (xsp), a
	cpdi8 36148, 11
	jr z, LABEL_F43558
	cpdi8 36150, 135
	jr nz, Part_WriteSubBlock_Exit

LABEL_F43558:
	lds wa, 0
	ldw bc, 0xE
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, Part_WriteSubBlock_Exit
	ldda8 l, 10430
	cp l, 0xFF
	jr z, Part_WriteSubBlock_Exit
	inc 1, l
	extz hl
	lds wa, 0
	ld bc, hl
	ldw de, 0xD
	calr Part_WriteSubBlock32

Part_WriteSubBlock_Exit:
	inc 2, xsp
	ret

LABEL_F4357E:
	dec 2, xsp
	ld (xsp), a
	lds wa, 0
	ldw bc, 0xD
	calr Part_FindVoiceByByte
	cp l, (xsp)
	jr nz, LABEL_F435A6
	extz hl
	lds wa, 0
	ld bc, hl
	ldw de, 0xE
	calr Part_WriteSubBlock32
	resda 0, 8970
	ld a, (xsp)
	dec 1, a
	stda8 10430, a

LABEL_F435A6:
	inc 2, xsp
	ret

SeqVoice_SendNoteOffAndFlush:
	push_werp 0xFA
	ldda8 a, 8988
	ldfr_berp A, 0xFB
	cp_erpb 0xFB, 0xFF
	jrl z, SeqVoice_PopRetFA
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F435C8
	slaa bc

LABEL_F435C8:
	andda16 xbc, 61854
	jrl z, SeqVoice_PopRetFA
	calr BitMapOut_PrepareAndDisplay
	ldto_berp A, 0xFB
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, LABEL_F435E0
	slaa bc

LABEL_F435E0:
	ldda16 xde, 10420
	and bc, de
	jr z, SeqVoice_PopRetFA
	ldto_berp C, 0xFB
	extz bc
	ld a, c
	dec 1, a
	lds hl, 1
	and a, 0xF
	jr z, LABEL_F435FA
	slaa hl

LABEL_F435FA:
	cpl hl
	and de, hl
	stda16 10420, xde
	ld wa, bc
	calr SeqBuf_WriteNoteOffEntry
	ldada xwa, 58228
	ldto_berp C, 0xFB
	dec 1, c
	ld (xwa + 3), c
	lds bc, 4
	calr SeqBuf_WriteMidiEvent
	ldada xwa, 58232
	ldto_berp C, 0xFB
	dec 1, c
	ld (xwa + 4), c
	lds bc, 5
	calr SeqBuf_WriteMidiEvent
	calr SeqBuf_FlushAndReinit_VoiceCCEvents
	pushw 0x30
	ldw wa, 0x48
	lds bc, 5
	lds de, 0
	call AddswbWr
	cpdi16 10408, 0
	jr nz, SeqVoice_PopRetFA
	cpdi8 7570, 0
	jr nz, SeqVoice_PopRetFA
	ldda16 xwa, 61854
	ldda16 xbc, 10420
	and wa, bc
	call_24 z, 0xF3CAC1

SeqVoice_PopRetFA:
	pop_werp 0xFA
	ret

SeqPlay_SaveStateAndCleanup:
	ldda16 xwa, 61854
	st16_24 0x00ffec, xwa
	bitda 0, 10405
	jr nz, LABEL_F43675
	stdi16 61854, 0
	call Audio_CheckSubsystemReady

LABEL_F43675:
	jp Audio_CheckSubsystemReady

SeqPlay_CheckAndStartPlayback:
	cpdi8 9508, 0
	jp_24 nz, 0xEF2505
	bitda 0, 10437
	jp_24 nz, 0xF391DC
	ldda8 a, 1057
	and a, 0x5
	ret nz
	call TempoRingBuf_CheckEmpty
	cps hl, 0
	ret z
	cpdi16 61854, 0
	ret nz
	cpdi16 10408, 0
	ret z
	cpdi16 10410, 0
	ret nz
	bitda 1, 10418
	ret nz
	call SeqPlay_ReassignVoiceChannels
	cps l, 0
	jrl nz, SeqPlay_StopAndClearChannels
	cpdi16 10410, 0
	ret z
	setda 1, 10419
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ei 0
	call AccWrap_PlayModeStart
	bitda 2, 64848
	ret z
	calr LABEL_F3DAA4
	ret

SeqAcc_SetIndicator_PB:
	ldda16 xwa, 61854
	stda16 10357, xwa
	call __jrt_nop_F86E7B
	resda 0, 10405
	ldw wa, 0x4C
	jp CtrlPanel_SetIndicatorBit

SeqAcc_RestorePlaybackState:
	pushw iz
	ldda16 xiz, 10357
	stda16 61854, xiz
	call Audio_CheckSubsystemReady
	cps iz, 0
	jr z, LABEL_F43727
	resda 3, 10407
	call SeqAcc_InitPlaybackState
	call Audio_CheckSubsystemReady
	setda 0, 10405
	jr LABEL_F4372B

LABEL_F43727:
	resda 0, 10405

LABEL_F4372B:
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	popw iz
	ret

LABEL_F43734:
	jrl Part_CopyVoiceDataToAllChannels

SeqPlay_SetBarAndResetScroll:
	stdi16 9832, 32770
	jp NoteEditSy_SendModeScrollReset

SeqPlay_HandleVoiceReassign:
	bitda 2, 10419
	jr z, LABEL_F43762
	ldda8 a, 64607
	and a, 0x30
	jr nz, LABEL_F43762
	call LABEL_F20712
	ldda8 a, 10419
	res 2, a
	set 4, a
	stda8 10419, a

LABEL_F43762:
	cpdi8 7568, 0
	jr z, SeqPlay_InitBuffers
	bitda 2, 1054
	jr nz, SeqPlay_InitBuffers
	ldda8 a, 1057
	and a, 0x14
	jr nz, SeqPlay_InitBuffers
	stdi8 4596, 0
	lds wa, 0
	call BitMapOut_PrepareAndRender
	stdi8 7568, 0

SeqPlay_InitBuffers:
	bitda 4, 10419
	jr z, SeqPlay_CheckMidiPending
	bitda 2, 1054
	jr nz, SeqPlay_CheckMidiPending
	ldda8 a, 1057
	and a, 0x14
	jr nz, SeqPlay_CheckMidiPending
	cpdi8 7518, 0
	jr nz, SeqPlay_CheckMidiPending
	bitda 1, 12931
	jr nz, SeqPlay_CheckMidiPending
	calr SeqPlay_AllocBuffersAndInit
	resda 4, 10419

SeqPlay_CheckMidiPending:
	cpdi8 7584, 0
	ret z
	ldda8 a, 1057
	and a, 0x1C
	ret nz
	call SeqPlay_CheckStartConditions
	stdi8 7584, 0
	ret

LABEL_F437CB:
	calr LABEL_F427AB
	cps l, 0
	ret nz
	cpdi16 1052, 0
	jr nz, LABEL_F437E1
	cpdi8 1051, 0
	jr z, LABEL_F437E7

LABEL_F437E1:
	setda 3, 10407
	jr LABEL_F437EB

LABEL_F437E7:
	resda 3, 10407

LABEL_F437EB:
	stdi8 58248, 1
	call SeqAcc_InitPlaybackState
	stdi8 58248, 0
	ret

LABEL_F437FA:
	call AccWrap_PlayModeDispatch
	calr Part_CopyVoiceDataToAllChannels
	call SeqPlay_ActivateAllChannels
	stdi8 4596, 0
	lds wa, 0
	call BitMapOut_PrepareAndRender
	resda 3, 10407
	call TempoRingBuf_Init
	setda 4, 10419
	ldw wa, 0xF
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd

SeqPlay_StopAndClearChannels:
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	stdi16 10410, 0
	call TempoRingBuf_Init
	ldw wa, 0xF
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd

LABEL_F4384C:
	call AccWrap_PlayModeDispatch
	stdi16 10420, 0
	ldw wa, 0x32
	calr SeqBuf_WriteNoteOffEntry
	calr VoiceAlloc_ProcessAll
	stdi8 1073, 0
	resda 5, 10419
	ldw wa, 0xE
	call SoundCtrl_SaveAndSendCmd_EE
	ldw wa, 0x8
	jp MIDI_SendSysExCmd
LABEL_F43876:
	.byte 0xd1, 0x30, 0x23, 0x20, 0xd1, 0x1c, 0x04, 0x21
	.byte 0xd8, 0xf1, 0xb0, 0xf7, 0xc1, 0x32, 0x23, 0x25
	.byte 0xd8, 0xa1, 0xcb, 0xf5, 0xb0, 0xfb, 0xd1, 0x68
	.byte 0x26, 0x20, 0xc1, 0x36, 0x8d, 0x3f, 0x85, 0x66
	.byte 0x07, 0xc1, 0x38, 0x8d, 0x3f, 0x86, 0x6e, 0x0c
	.byte 0xd1, 0x22, 0x25, 0xf0, 0x67, 0x0c, 0xd1, 0x20
	.byte 0x25, 0x20, 0x68, 0x0e, 0xd1, 0x1e, 0x25, 0xf0
	.byte 0x6f, 0x04, 0xd8, 0x61, 0x68, 0x04, 0xd1, 0x1c
	.byte 0x25, 0x20, 0xf1, 0x68, 0x26, 0x50, 0x1d, 0xe4
	.byte 0x64, 0xf4, 0xd1, 0x1c, 0x04, 0x19, 0x30, 0x23
	.byte 0xc1, 0x33, 0x04, 0x25, 0xf1, 0x32, 0x23, 0x45
	.byte 0x1b, 0x6c, 0x65, 0xf4, 0xf1, 0xb2, 0x28, 0xca
	.byte 0xb0, 0xf6, 0xd1, 0x68, 0x26, 0x20, 0xd8, 0xcf
	.byte 0x02, 0x80, 0xb0, 0xfe, 0xc1, 0x34, 0x04, 0x21
	.byte 0xc9, 0xd9, 0xb0, 0xf7, 0xf1, 0x68, 0x26, 0x02
	.byte 0x01, 0x80, 0x1d, 0xe4, 0x64, 0xf4, 0x0e, 0xd1
	.byte 0x30, 0x23, 0x20, 0xd1, 0x1c, 0x04, 0x21, 0xd8
	.byte 0xf1, 0xb0, 0xf7, 0xc1, 0x32, 0x23, 0x25, 0xd8
	.byte 0xa1, 0xcb, 0xf5, 0xb0, 0xfb, 0xd1, 0x68, 0x26
	.byte 0x20, 0xd8, 0xcf, 0xe7, 0x03, 0xb0, 0xff, 0xd8
	.byte 0x61, 0xf1, 0x68, 0x26, 0x50, 0x1d, 0xe4, 0x64
	.byte 0xf4, 0xd1, 0x1c, 0x04, 0x19, 0x30, 0x23, 0xc1
	.byte 0x33, 0x04, 0x25, 0xf1, 0x32, 0x23, 0x45, 0x1b
	.byte 0x6c, 0x65, 0xf4, 0xf1, 0xb2, 0x28, 0xc9, 0xb0
	.byte 0xf6, 0xd1, 0x68, 0x26, 0x20, 0xd8, 0xcf, 0x01
	.byte 0x80, 0xb0, 0xfe, 0xc1, 0x33, 0x04, 0x21, 0xc1
	.byte 0x16, 0x04, 0x23, 0xc9, 0x69, 0xcb, 0xf1, 0xb0
	.byte 0xfe, 0xc1, 0x15, 0x04, 0x21, 0xc9, 0xcf, 0x48
	.byte 0xb0, 0xf7, 0xf1, 0xb3, 0x28, 0xb3, 0x1d, 0x6f
	.byte 0xde, 0xfd, 0x1d, 0x6f, 0xde, 0xfd, 0xc1, 0xfc
	.byte 0x22, 0x21, 0xc9, 0xcf, 0x14, 0x66, 0x1b, 0xc9
	.byte 0xcf, 0x10, 0x66, 0x12, 0xc9, 0xcf, 0x0c, 0x66
	.byte 0x09, 0xc9, 0xcf, 0x08, 0x6e, 0x0e, 0x21, 0x09
	.byte 0x68, 0x0a, 0x21, 0x0d, 0x68, 0x06, 0x21, 0x11
	.byte 0x68, 0x02, 0x21, 0x15, 0xf1, 0xfc, 0x22, 0x41
	.byte 0x0e

AccWrap_DispatchAndWaitSync:
	call AccWrap_PlayModeDispatch
	ldw bc, 0xFFFF
	ldda8 a, 1056
	bit 2, a
	ret z

LABEL_F4399F:
	sub bc, 0x1
	ret z
	bit 2, a
	jr nz, LABEL_F4399F
	ret

; ============================================================================
; SeqData_SetErrorCode - Set sequence error code (first-error-wins)
; ============================================================================
; Input:  A = error code to set
; Only stores if DRAM[7520] is currently zero (no existing error).
; Called with error values 0xB8, 0xCF, 0xD0, 0xD1 from sequence processing.
; ============================================================================
SeqData_SetErrorCode:
	cpdi8 7520, 0
	ret nz
	stda8 7520, a
	ret

SeqStatus_CheckBit2:
	ldda8 l, 64941
	and l, 0x4
	ret

LABEL_F439BF:
	ldda8 l, 64850
	and l, a
	ret

Seq_ComputePercentClamped99:
	ldw bc, 0x4D8
	ldda16 xwa, 62001
	cp wa, 0x258
	jr ule, LABEL_F439DF

LABEL_F439D3:
	srl bc, 1
	srl wa, 1
	cp wa, 0x258
	jr ugt, LABEL_F439D3

LABEL_F439DF:
	mul wa, 0x64
	extz xwa
	div xwa, xbc
	ld l, a
	cp l, 0x64
	ret nz
	ldb l, 0x63
	ret

SeqStatus_SetOrClearBit:
	ldada xde, 64941
	cps c, 0
	jr z, LABEL_F439FC
	or (xde), a
	ret

LABEL_F439FC:
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
	cp wa, 0xFFFF
	jr z, SeqStatus_Exit
	calr PartCtrl_TestBit7
	cps l, 0
	jr z, SeqStatus_Exit
	lds hl, 1
	jr LABEL_F43A30

SeqStatus_Exit:
	lds hl, 0

LABEL_F43A30:
	inc 2, xsp
	ret

SeqStatus_ResetAndSendCmd:
	resda 0, 64941
	pushw 0x1
	ldw wa, 0x91
	lds bc, 3
	lds de, 0
	call AddswbWr
	ret

SeqPlay_WriteErrorToVoiceTable:
	ldda8 a, 10362
	extz wa
	lda_24 xbc, 0xe445e2
	ldmm_srib 0x07, 0xE4, 0xE0, 0x7A, 0x28
	ret

SeqData_SendVoiceTableBlock:
	dec 6, xsp
	ld xiy, 0xE44656
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
	ldada xbc, 9184
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld wa, (xbc + 2)
	ld (xde + 2), wa
	ld wa, (xde)
	sll wa, 8
	sub wa, 0x100
	extz xwa
	addda32 xwa, 10302
	ld xhl, xwa

LABEL_F43AAF:
	lda xde, (xsp + 4)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	ld (xsp + 8), a
	ld wa, (xbc)
	cp wa, 0xFF
	jr nz, LABEL_F43AE6
	ld wa, (xde)
	calr SeqData_ResolveNextBlock
	lda xwa, (xsp + 4)
	ld (xwa), hl
	sll hl, 8
	sub hl, 0x100
	extz xhl
	addda32 xhl, 10302
	ldw (xwa + 2), 0x5
	jr LABEL_F43AEA

LABEL_F43AE6:
	inc 1, wa
	ld (xbc), wa

LABEL_F43AEA:
	ld e, (xsp + 8)
	ldada xbc, 9016
	ld a, (xsp + 18)
	dec 1, a
	extz wa
	sla wa, 3
	exts xwa
	add xwa, xbc
	cp e, 0x81
	jr nz, LABEL_F43B08
	incm 1, (xwa)
	jr LABEL_F43AAF

LABEL_F43B08:
	ld xbc, xwa
	ld (xwa + 2), e
	cp e, 0x82
	jr nz, LABEL_F43B18
	ld (xbc + 3), 0x0
	jr SeqData_SaveParsedState

LABEL_F43B18:
	ldi_werp 0xFA, 1

LABEL_F43B1B:
	lda xde, (xsp + 4)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	extz xwa
	add xwa, xhl
	ld a, (xwa)
	ldfr_berp A, 0xF8
	bit_erpb 0xF8, 0x07
	jr nz, SeqData_SaveParsedState
	ldto_werp IY, 0xFA
	inc 2, iy
	ld a, (xsp + 18)
	dec 1, a
	extz wa
	ld ix, wa
	sla ix, 3
	ldada xwa, 9016
	st_dri3b W, 0x07, 0xE0, 0xF0
	ld ix, iy
	extz xix
	add xix, xwa
	ldto_berp A, 0xF8
	ld (xix), a
	ld wa, (xbc)
	cp wa, 0xFF
	jr nz, LABEL_F43B7D
	ld wa, (xde)
	calr SeqData_ResolveNextBlock
	lda xwa, (xsp + 4)
	ld (xwa), hl
	sll hl, 8
	sub hl, 0x100
	extz xhl
	addda32 xhl, 10302
	ldw (xwa + 2), 0x5
	jr LABEL_F43B81

LABEL_F43B7D:
	inc 1, wa
	ld (xbc), wa

LABEL_F43B81:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x08, 0x00
	jr c, LABEL_F43B1B

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
	ldada xbc, 9184
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
	addda32 xwa, 10302
	ld a, (xwa + 3)
	ldfr_berp A, 0xF8
	extz iz
	cp iz, 0xFFFF
	jr nz, LABEL_F43BD5
	ldw wa, 0x32
	calr SeqData_SetErrorCode

LABEL_F43BD5:
	ld hl, iz
	popw iz
	ret

LABEL_F43BD9:
	dec 4, xsp
	push_werp 0xFA
	cpdi8 36148, 19
	jr nz, LABEL_F43C37
	ldda8 a, 10404
	ldfr_berp A, 0xFB
	extz wa
	call Voice_GetPresetFieldWord
	stda16 61854, xhl
	call Audio_CheckSubsystemReady
	ldto_berp A, 0xFB
	extz wa
	call LABEL_F86FDC
	ld (xsp + 2), xhl
	ldi_berp 0xFB, 1

LABEL_F43C09:
	ldto_berp C, 0xFB
	extz bc
	ldto_berp E, 0xFB
	dec 1, e
	extz de
	ld xwa, (xsp + 2)
	ld_srib3 E, 0x07, 0xE0, 0xE8
	extz de
	lds wa, 0
	calr Part_WriteSubBlock32
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F43C09
	resda 7, 10414
	call MidiChannel_ResetAndConfigure
	jr LABEL_F43CA3

LABEL_F43C37:
	resda 3, 10407
	setda 4, 10419
	lds wa, 0
	ldw bc, 0xBD
	calr Part_ReadByteDirect
	ldada xwa, 64941
	cp l, 0xFF
	jr nz, LABEL_F43C6C
	bitm 2, (xwa)
	jr nz, LABEL_F43C8A
	lds wa, 4
	lds bc, 1
	calr SeqStatus_SetOrClearBit
	stdi8 4330, 1
	pushw 0x4
	ldw wa, 0x91
	lds bc, 3
	lds de, 4
	jr LABEL_F43C86

LABEL_F43C6C:
	bitm 2, (xwa)
	jr z, LABEL_F43C8A
	lds wa, 4
	lds bc, 0
	calr SeqStatus_SetOrClearBit
	stdi8 4330, 1
	pushw 0x4
	ldw wa, 0x91
	lds bc, 3
	lds de, 0

LABEL_F43C86:
	call AssswbWr

LABEL_F43C8A:
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	cpdi16 61854, 0
	jr z, LABEL_F43CA3
	stdi8 4596, 0
	lds wa, 0
	call BitMapOut_PrepareAndRender

LABEL_F43CA3:
	pop_werp 0xFA
	inc 4, xsp
	ret

LABEL_F43CA9:
	cpdi8 36148, 19
	jr nz, LABEL_F43CFF
	ldda8 a, 10598
	bit 7, a
	ret z
	dec 1, a
	stda8 10598, a
	cp a, 0x80
	ret nz
	ei 6
	stdi16 1052, 0
	stdi8 1051, 0
	ldda8 a, 10404
	extz wa
	call Demo_ProcessRecordEntry
	cps l, 0
	jr z, LABEL_F43CF3
	stdi8 1054, 1
	stdi8 1045, 0
	stdi8 1046, 0
	stdi8 1076, 0

LABEL_F43CF3:
	stdi8 1057, 1
	stdi8 1056, 1
	ei 0

LABEL_F43CFF:
	stdi8 10598, 0
	ret

LABEL_F43D05:
	cpdi16 61854, 0
	jr z, LABEL_F43D16
	anddi8 10407, 247
	call SeqAcc_InitPlaybackState

LABEL_F43D16:
	anddi8 10412, 223
	ret

ApEditSyori:
	cp xbc, 0x1E80015
	jr z, LABEL_F43D44
	cp xbc, 0x1E80014
	jr z, LABEL_F43D3D
	cp xbc, 0x1C0000B
	jr nz, LABEL_F43D49
	stda32 10610, xde
	calr LABEL_F43D4C
	jr LABEL_F43D49

LABEL_F43D3D:
	ld xwa, xde
	calr LABEL_F44147
	jr LABEL_F43D49

LABEL_F43D44:
	ld xwa, xde
	calr LABEL_F44882

LABEL_F43D49:
	lds32 xhl, 0
	ret

LABEL_F43D4C:
	ldda8 a, 36150
	cp a, 0x91
	jrl z, LABEL_F440A7
	cp a, 0x90
	jr z, LABEL_F43D83
	extz wa
	sub wa, 0x9B
	cps wa, 0
	jrl lt, AppEvent_PostDefaultEvents
	cp wa, 0xD
	jrl gt, AppEvent_PostDefaultEvents
	add wa, wa
	lda_24 xix, 0xe4487e
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf43d83
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F43D83:
	call SeqData_CopyBlockWithLookup
	ldda8 a, 10360
	extz wa
	call SeqPart_CountActiveVoices
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1E
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1F
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x20
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x21
	jrl AppEvent_PostEvent_Stub
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xA
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xB
	jrl AppEvent_PostEvent_Stub
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 5
	jrl AppEvent_PostEvent_Stub
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 4
	jrl AppEvent_PostEvent_Stub
	ldda16 xwa, 61911
	addda16 xwa, 61913
	dec 1, wa
	stda16 9772, xwa
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	jrl AppEvent_PostEvent_Stub
	ldda16 xwa, 61916
	addda16 xwa, 61918
	dec 1, wa
	stda16 9766, xwa
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 6
	jrl AppEvent_PostEvent_Stub
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 7
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x8
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x9
	jrl AppEvent_PostEvent_Stub
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xC
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xD
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xE
	jrl AppEvent_PostEvent_Stub
	ldda16 xwa, 61930
	addda16 xwa, 61932
	dec 1, wa
	stda16 9768, xwa
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jrl AppEvent_PostEvent_Stub
	ldda16 xwa, 61922
	addda16 xwa, 61924
	dec 1, wa
	stda16 9774, xwa
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1A
	jrl AppEvent_PostEvent_Stub

LABEL_F440A7:
	ldda8 a, 9992
	extz wa
	ld xbc, 0x2842
	call SeqData_CopyBlock2K
	ldda8 a, 9994
	extz wa
	ld xbc, 0x2852
	call SeqData_CopyBlock2K
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1E
	jr AppEvent_PostEvent_Stub

AppEvent_PostDefaultEvents:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 3

AppEvent_PostEvent_Stub:
	jp ApDeliveryEvent

LABEL_F44147:
	dec 4, xsp
	push xiz
	ld xbc, xwa
	cp xbc, 0x1F
	jrl ugt, AppEvent_Epilogue
	add xbc, xbc
	add xbc, 0xE448F6
	ld bc, (xbc)
	lda_24 xix, 0xf44169
	jp_dri 8, 0x07, 0xF0, 0xE4
; Application event handler dispatch table
; Handles up to 32 event types (XBC 0-0x1F), used by ApDeliveryEvent system
; Each handler increments counters, sends notifications via CALL 0FA9E07h
APP_EVENT_HANDLER_TABLE:	; F44169
	ldda8 a, 36150
	extz wa
	sub wa, 0x9C
	cps wa, 0
	jr lt, APP_EVENT_HANDLER_F4417B
	cps wa, 7
	jr le, APP_EVENT_HANDLER_F4417E
APP_EVENT_HANDLER_F4417B:
	ldw wa, 0x8
APP_EVENT_HANDLER_F4417E:
	sll wa, 2
	lda_24 xix, 0xe448d2
	ld_sril3 XWA, 0x07, 0xF0, 0xE0
	cp (xwa), 0x11
	jrl nc, AppEvent_Epilogue
	incm8 1, (xwa)
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 36150
	extz wa
	sub wa, 0x9C
	cps wa, 0
	jr lt, APP_EVENT_HANDLER_F44205
	cps wa, 7
	jr gt, APP_EVENT_HANDLER_F44205
	add wa, wa
	lda_24 xix, 0xe448c2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf441c9
	jp_dri 8, 0x07, 0xF0, 0xE0
	ldada xiz, 9744
	ldada xwa, 9746
	jr APP_EVENT_HANDLER_F4420D
	ldada xiz, 61993
	ldada xwa, 9722
	jr APP_EVENT_HANDLER_F4420D
	ldada xiz, 9758
	ldada xwa, 9760
	jr APP_EVENT_HANDLER_F4420D
	ldada xiz, 61911
	ldada xwa, 9772
	jr APP_EVENT_HANDLER_F4420D
	ldada xiz, 61916
	ldada xwa, 9766
	jr APP_EVENT_HANDLER_F4420D
	ldada xiz, 61938
	ldada xwa, 9724
	jr APP_EVENT_HANDLER_F4420D
APP_EVENT_HANDLER_F44205:
	ldada xiz, 9734
	ldada xwa, 9736
APP_EVENT_HANDLER_F4420D:
	ld (xsp + 4), xwa
	cpw (xiz), 0x3E7
	jr nc, APP_EVENT_HANDLER_F44227
	incm 1, (xiz)
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
APP_EVENT_HANDLER_F44227:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, APP_EVENT_HANDLER_F44243
	ld bc, (xiz)
	ld (xwa), bc
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
APP_EVENT_HANDLER_F44243:
	ldda8 a, 36150
	cp a, 0xA3
	jrl z, APP_EVENT_HANDLER_F44304
	cp a, 0xA1
	jrl z, APP_EVENT_HANDLER_F4431B
	jrl AppEvent_Epilogue
	ldda8 a, 36150
	extz wa
	sub wa, 0x9C
	cps wa, 0
	jr lt, APP_EVENT_HANDLER_F442BA
	cps wa, 7
	jr gt, APP_EVENT_HANDLER_F442BA
	add wa, wa
	lda_24 xix, 0xe448b2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf4427e
	jp_dri 8, 0x07, 0xF0, 0xE0
	ldada xiz, 9744
	ldada xwa, 9746
	jr APP_EVENT_HANDLER_F442C2
	ldada xiz, 61993
	ldada xwa, 9722
	jr APP_EVENT_HANDLER_F442C2
	ldada xiz, 9758
	ldada xwa, 9760
	jr APP_EVENT_HANDLER_F442C2
	ldada xiz, 61911
	ldada xwa, 9772
	jr APP_EVENT_HANDLER_F442C2
	ldada xiz, 61916
	ldada xwa, 9766
	jr APP_EVENT_HANDLER_F442C2
	ldada xiz, 61938
	ldada xwa, 9724
	jr APP_EVENT_HANDLER_F442C2
APP_EVENT_HANDLER_F442BA:
	ldada xiz, 9734
	ldada xwa, 9736
APP_EVENT_HANDLER_F442C2:
	ld (xsp + 4), xwa
	cpw (xwa), 0x3E7
	jr nc, APP_EVENT_HANDLER_F442DF
	ld xwa, (xsp + 4)
	incm 1, (xwa)
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
APP_EVENT_HANDLER_F442DF:
	ld bc, (xiz)
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr ule, APP_EVENT_HANDLER_F442FB
	ld wa, (xwa)
	ld (xiz), wa
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
APP_EVENT_HANDLER_F442FB:
	ldda8 a, 36150
	cp a, 0xA3
	jr nz, APP_EVENT_HANDLER_F44315
APP_EVENT_HANDLER_F44304:
	ldda16 xwa, 9772
	subda16 xwa, 61911
	inc 1, wa
	stda16 61913, xwa
	jrl AppEvent_Epilogue
APP_EVENT_HANDLER_F44315:
	cp a, 0xA1
	jrl nz, AppEvent_Epilogue
APP_EVENT_HANDLER_F4431B:
	ldda16 xwa, 9766
	subda16 xwa, 61916
	inc 1, wa
	stda16 61918, xwa
	jrl AppEvent_Epilogue
	ldda8 a, 9740
	cp a, 0x60
	jrl ge, AppEvent_Epilogue
	inc 1, a
	stda8 9740, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 3
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 9762
	cp a, 0x7F
	jrl ge, AppEvent_Epilogue
	inc 1, a
	stda8 9762, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 4
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61998
	cp a, 0x7F
	jrl ge, AppEvent_Epilogue
	inc 1, a
	stda8 61998, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 5
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61920
	cps a, 2
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 61920, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 6
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61942
	cps a, 6
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 61942, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 7
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 9728
	cp a, 0x64
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 9728, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x8
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 9730
	cp a, 0x64
	jrl ge, AppEvent_Epilogue
	inc 1, a
	stda8 9730, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x9
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 9750
	cp a, 0x7F
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 9750, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xA
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 9816
	cp a, 0x7F
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 9816, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xB
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61907
	cp a, 0x10
	jr nc, APP_EVENT_HANDLER_F44455
	inc 1, a
	stda8 61907, a
	jr APP_EVENT_HANDLER_F4445E
APP_EVENT_HANDLER_F44455:
	stdi8 61907, 1
	ldda8 a, 61907
APP_EVENT_HANDLER_F4445E:
	cpda8 a, 61908
	jr nz, APP_EVENT_HANDLER_F44476
	cp a, 0x10
	jr nc, APP_EVENT_HANDLER_F44471
	inc 1, a
	stda8 61907, a
	jr APP_EVENT_HANDLER_F44476
APP_EVENT_HANDLER_F44471:
	stdi8 61907, 1
APP_EVENT_HANDLER_F44476:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xC
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61908
	cp a, 0x10
	jr nc, APP_EVENT_HANDLER_F44498
	inc 1, a
	stda8 61908, a
	jr APP_EVENT_HANDLER_F444A1
APP_EVENT_HANDLER_F44498:
	stdi8 61908, 1
	ldda8 a, 61908
APP_EVENT_HANDLER_F444A1:
	cpda8 a, 61907
	jr nz, APP_EVENT_HANDLER_F444B9
	cp a, 0x10
	jr nc, APP_EVENT_HANDLER_F444B4
	inc 1, a
	stda8 61908, a
	jr APP_EVENT_HANDLER_F444B9
APP_EVENT_HANDLER_F444B4:
	stdi8 61908, 1
APP_EVENT_HANDLER_F444B9:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xD
	jrl APP_EVENT_HANDLER_F4487A
	ldda8 a, 61909
	cp a, 0x10
	jrl nc, AppEvent_Epilogue
	inc 1, a
	stda8 61909, a
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xE
	jrl APP_EVENT_HANDLER_F4487A
	sub xwa, 0xF
	cp xwa, 0x0
	jrl c, APP_EVENT_HANDLER_F445B0
	cp xwa, 0x5
	jrl ugt, APP_EVENT_HANDLER_F445B0
	add xwa, xwa
	add xwa, 0xE448A6
	ld wa, (xwa)
	lda_24 xix, 0xf44517
	jp_dri 8, 0x07, 0xF0, 0xE0
	ldda8 a, 61929
	cp a, 0x11
	jrl nc, APP_EVENT_HANDLER_F445B0
	inc 1, a
	stda8 61929, a
	cp a, 0x11
	jrl nz, APP_EVENT_HANDLER_F445B0
	stdi8 61934, 17
	jr APP_EVENT_HANDLER_F445B0
	ldda16 xwa, 61930
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F44544
	inc 1, wa
	stda16 61930, xwa
APP_EVENT_HANDLER_F44544:
	ldda16 xwa, 61930
	cpda16 xwa, 9768
	jr ule, APP_EVENT_HANDLER_F44564
	stda16 9768, xwa
	jr APP_EVENT_HANDLER_F44564
	ldda16 xwa, 9768
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F44564
	inc 1, wa
	stda16 9768, xwa
APP_EVENT_HANDLER_F44564:
	ldda16 xwa, 9768
	subda16 xwa, 61930
	inc 1, wa
	stda16 61932, xwa
	jr APP_EVENT_HANDLER_F445B0
	ldda8 a, 61934
	cp a, 0x11
	jr nc, APP_EVENT_HANDLER_F445B0
	inc 1, a
	stda8 61934, a
	cp a, 0x11
	jr nz, APP_EVENT_HANDLER_F445B0
	stdi8 61929, 17
	jr APP_EVENT_HANDLER_F445B0
	ldda16 xwa, 61935
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F445B0
	inc 1, wa
	stda16 61935, xwa
	jr APP_EVENT_HANDLER_F445B0
	ldda8 a, 9770
	cp a, 0x7F
	jr nc, APP_EVENT_HANDLER_F445B0
	inc 1, a
	stda8 9770, a
APP_EVENT_HANDLER_F445B0:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jrl APP_EVENT_HANDLER_F4487A
	sub xwa, 0x15
	cp xwa, 0x0
	jrl c, APP_EVENT_HANDLER_F446E0
	cp xwa, 0x5
	jrl ugt, APP_EVENT_HANDLER_F446E0
	add xwa, xwa
	add xwa, 0xE4489A
	ld wa, (xwa)
	lda_24 xix, 0xf44647
	jp_dri 8, 0x07, 0xF0, 0xE0
	ldda8 a, 61921
	cp a, 0x11
	jrl nc, APP_EVENT_HANDLER_F446E0
	inc 1, a
	stda8 61921, a
	cp a, 0x11
	jrl nz, APP_EVENT_HANDLER_F446E0
	stdi8 61926, 17
	jr APP_EVENT_HANDLER_F446E0
	ldda16 xwa, 61922
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F44674
	inc 1, wa
	stda16 61922, xwa
APP_EVENT_HANDLER_F44674:
	ldda16 xwa, 61922
	cpda16 xwa, 9774
	jr ule, APP_EVENT_HANDLER_F44694
	stda16 9774, xwa
	jr APP_EVENT_HANDLER_F44694
	ldda16 xwa, 9774
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F44694
	inc 1, wa
	stda16 9774, xwa
APP_EVENT_HANDLER_F44694:
	ldda16 xwa, 9774
	subda16 xwa, 61922
	inc 1, wa
	stda16 61924, xwa
	jr APP_EVENT_HANDLER_F446E0
	ldda8 a, 61926
	cp a, 0x11
	jr nc, APP_EVENT_HANDLER_F446E0
	inc 1, a
	stda8 61926, a
	cp a, 0x11
	jr nz, APP_EVENT_HANDLER_F446E0
	stdi8 61921, 17
	jr APP_EVENT_HANDLER_F446E0
	ldda16 xwa, 61927
	cp wa, 0x3E7
	jr nc, APP_EVENT_HANDLER_F446E0
	inc 1, wa
	stda16 61927, xwa
	jr APP_EVENT_HANDLER_F446E0
	ldda8 a, 9776
	cp a, 0x7F
	jr nc, APP_EVENT_HANDLER_F446E0
	inc 1, a
	stda8 9776, a
APP_EVENT_HANDLER_F446E0:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1A
	jrl APP_EVENT_HANDLER_F4487A
	cp xwa, 0x1E
	jr z, APP_EVENT_HANDLER_F447BA
	cp xwa, 0x1D
	jr z, APP_EVENT_HANDLER_F4479E
	cp xwa, 0x1C
	jr z, APP_EVENT_HANDLER_F44783
	cp xwa, 0x1B
	jr nz, APP_EVENT_HANDLER_F447D3
	ldda8 a, 9992
	cp a, 0xA
	jr nc, APP_EVENT_HANDLER_F447D3
	inc 1, a
	stda8 9992, a
	extz wa
	ld xbc, 0x2842
	jr APP_EVENT_HANDLER_F447B4
APP_EVENT_HANDLER_F44783:
	ldda8 a, 9996
	cp a, 0x11
	jr nc, APP_EVENT_HANDLER_F447D3
	inc 1, a
	stda8 9996, a
	cp a, 0x11
	jr nz, APP_EVENT_HANDLER_F447D3
	stdi8 9998, 17
	jr APP_EVENT_HANDLER_F447D3
APP_EVENT_HANDLER_F4479E:
	ldda8 a, 9994
	cp a, 0xA
	jr nc, APP_EVENT_HANDLER_F447D3
	inc 1, a
	stda8 9994, a
	extz wa
	ld xbc, 0x2852
APP_EVENT_HANDLER_F447B4:
	call SeqData_CopyBlock2K
	jr APP_EVENT_HANDLER_F447D3
APP_EVENT_HANDLER_F447BA:
	ldda8 a, 9998
	cp a, 0x11
	jr nc, APP_EVENT_HANDLER_F447D3
	inc 1, a
	stda8 9998, a
	cp a, 0x11
	jr nz, APP_EVENT_HANDLER_F447D3
	stdi8 9996, 17
APP_EVENT_HANDLER_F447D3:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1E
	jr APP_EVENT_HANDLER_F4487A
	ldda8 a, 10360
	cp a, 0xA
	jr nc, AppEvent_Epilogue
	inc 1, a
	stda8 10360, a
	call SeqData_CopyBlockWithLookup
	ldda8 a, 10360
	extz wa
	call SeqPart_CountActiveVoices
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x1F
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x20
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x21
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x22
APP_EVENT_HANDLER_F4487A:
	call ApDeliveryEvent
AppEvent_Epilogue:
	pop xiz
	inc 4, xsp
	ret

LABEL_F44882:
	dec 4, xsp
	push xiz
	ld xbc, xwa
	cp xbc, 0x1F
	jrl ugt, LABEL_F44F98
	add xbc, xbc
	add xbc, 0xE44992
	ld bc, (xbc)
	lda_24 xix, 0xf448a4
	jp_dri 8, 0x07, 0xF0, 0xE4
LABEL_F448A4:
	.byte 0xc1, 0x36, 0x8d, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x9c, 0x00, 0xd8, 0xd8, 0x61, 0x04, 0xd8, 0xdf
	.byte 0x62, 0x03, 0x30, 0x08, 0x00, 0xd8, 0xee, 0x02
	.byte 0xf2, 0x6e, 0x49, 0xe4, 0x34, 0xe3, 0x07, 0xf0
	.byte 0xe0, 0x20, 0x80, 0x3f, 0x01, 0x73, 0xcc, 0x06
	.byte 0x80, 0x69, 0xe1
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78, 0xb8, 0x06
	.byte 0xc1, 0x36, 0x8d, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x9c, 0x00, 0xd8, 0xd8, 0x61, 0x56, 0xd8, 0xdf
	.byte 0x6a, 0x52, 0xd8, 0x80, 0xf2, 0x5e, 0x49, 0xe4
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x04
	.byte 0x49, 0xf4, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	.byte 0xf1, 0x10, 0x26, 0x36, 0xf1, 0x12, 0x26, 0x30
	.byte 0x68, 0x3a, 0xf1, 0x29, 0xf2, 0x36, 0xf1, 0xfa
	.ascii "%0h0"
	.byte 0xf1, 0x1e, 0x26, 0x36
	.byte 0xf1
	.ascii " &0h&ñ×ñ6ñ,&0h"
	.byte 0x1c
	.byte 0xf1, 0xdc, 0xf1, 0x36, 0xf1, 0x26, 0x26, 0x30
	.byte 0x68, 0x12, 0xf1, 0xf2, 0xf1, 0x36, 0xf1, 0xfc
	.byte 0x25, 0x30, 0x68, 0x08, 0xf1, 0x06, 0x26, 0x36
	.byte 0xf1, 0x08, 0x26, 0x30, 0xbf, 0x04, 0x60, 0x96
	.byte 0x3f, 0x01, 0x00, 0x63, 0x11, 0x96, 0x69, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa9, 0x1d, 0x07, 0x9e, 0xfa, 0x96, 0x21
	.byte 0xaf, 0x04, 0x20, 0x90, 0xf1, 0x63, 0x13, 0x96
	.byte 0x21, 0xb0, 0x51, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xaa, 0x1d, 0x07
	.byte 0x9e, 0xfa, 0xc1, 0x36, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0xa3, 0x76, 0xb7, 0x00, 0xc9, 0xcf, 0xa1, 0x76
	.byte 0xc8, 0x00, 0x78, 0x07, 0x06, 0xc1, 0x36, 0x8d
	.byte 0x21, 0xd8, 0x12, 0xd8, 0xca, 0x9c, 0x00, 0xd8
	.byte 0xd8, 0x61, 0x56, 0xd8, 0xdf, 0x6a, 0x52, 0xd8
	.byte 0x80, 0xf2, 0x4e, 0x49, 0xe4, 0x34, 0xd3, 0x07
	.byte 0xf0, 0xe0, 0x20, 0xf2, 0xb9, 0x49, 0xf4, 0x34
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xf1, 0x10, 0x26
	ldw	iz, 0x12f1
	.ascii "&0h:ñ)ò6ñú%0h"
	.byte 0x30, 0xf1, 0x1e, 0x26, 0x36, 0xf1, 0x20, 0x26
	.byte 0x30, 0x68, 0x26, 0xf1, 0xd7, 0xf1, 0x36, 0xf1
	.ascii ",&0h"
	.byte 0x1c, 0xf1, 0xdc, 0xf1
	.byte 0x36, 0xf1
	.ascii "&&0h"
	.byte 0x12, 0xf1
	.byte 0xf2, 0xf1, 0x36, 0xf1, 0xfc, 0x25, 0x30, 0x68
	.byte 0x08, 0xf1, 0x06, 0x26, 0x36, 0xf1, 0x08, 0x26
	.byte 0x30, 0xbf, 0x04, 0x60, 0x90, 0x3f, 0x01, 0x00
	.byte 0x63, 0x14, 0xaf, 0x04, 0x20, 0x90, 0x69, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xaa, 0x1d, 0x07, 0x9e, 0xfa, 0x96, 0x21
	.byte 0xaf, 0x04, 0x20, 0x90, 0xf1, 0x63, 0x13, 0x90
	.byte 0x20, 0xb6, 0x50, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xa9, 0x1d, 0x07
	.byte 0x9e, 0xfa, 0xc1, 0x36, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0xa3, 0x6e, 0x11, 0xd1, 0x2c, 0x26, 0x20, 0xd1
	.byte 0xd7, 0xf1, 0xa0, 0xd8, 0x61, 0xf1, 0xd9, 0xf1
	.byte 0x50, 0x78, 0x48, 0x05, 0xc9, 0xcf, 0xa1, 0x7e
	.byte 0x42, 0x05, 0xd1, 0x26, 0x26, 0x20, 0xd1, 0xdc
	.byte 0xf1, 0xa0, 0xd8, 0x61, 0xf1, 0xde, 0xf1, 0x50
	.byte 0x78, 0x31, 0x05, 0xc1, 0x0c, 0x26, 0x21, 0xc9
	.byte 0xcf, 0xa0, 0x72, 0x27, 0x05, 0xc9, 0x69, 0xf1
	.byte 0x0c, 0x26, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xab, 0x78, 0x0f
	.byte 0x05, 0xc1, 0x22, 0x26, 0x21, 0xc9, 0xcf, 0x81
	.byte 0x72, 0x09, 0x05, 0xc9, 0x69, 0xf1, 0x22, 0x26
	.byte 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0xea, 0xac, 0x78, 0xf1, 0x04, 0xc1
	.byte 0x2e, 0xf2, 0x21, 0xc9, 0xcf, 0x81, 0x72, 0xeb
	.byte 0x04, 0xc9, 0x69, 0xf1, 0x2e, 0xf2, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xad, 0x78, 0xd3, 0x04, 0xc1, 0xe0, 0xf1
	.byte 0x21, 0xc9, 0xd8, 0x76, 0xce, 0x04, 0xc9, 0x69
	.byte 0xf1, 0xe0, 0xf1, 0x41, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xae, 0x78
	.byte 0xb6, 0x04, 0xc1, 0xf6, 0xf1, 0x21, 0xc9, 0xd8
	.byte 0x76, 0xb1, 0x04, 0xc9, 0x69, 0xf1, 0xf6, 0xf1
	.byte 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0xea, 0xaf, 0x78, 0x99, 0x04, 0xc1
	.byte 0x00, 0x26, 0x21, 0xc9, 0xd8, 0x76, 0x94, 0x04
	.byte 0xc9, 0x69, 0xf1, 0x00, 0x26, 0x41, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x08, 0x00, 0x00, 0x00, 0x78, 0x79, 0x04, 0xc1
	.byte 0x02, 0x26, 0x21, 0xc9, 0xcf, 0x9c, 0x72, 0x73
	.byte 0x04, 0xc9, 0x69, 0xf1, 0x02, 0x26, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x09, 0x00, 0x00, 0x00, 0x78, 0x58, 0x04
	.byte 0xc1, 0x16, 0x26, 0x21, 0xc9, 0xd8, 0x76, 0x53
	.byte 0x04, 0xc9, 0x69, 0xf1, 0x16, 0x26, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x0a, 0x00, 0x00, 0x00, 0x78, 0x38, 0x04
	.byte 0xc1, 0x58, 0x26, 0x21, 0xc9, 0xd8, 0x76, 0x33
	.byte 0x04, 0xc9, 0x69, 0xf1, 0x58, 0x26, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x0b, 0x00, 0x00, 0x00, 0x78, 0x18, 0x04
	.byte 0xc1, 0xd3, 0xf1, 0x21, 0xc9, 0xd9, 0x63, 0x08
	.byte 0xc9, 0x69, 0xf1, 0xd3, 0xf1, 0x41, 0x68, 0x09
	.byte 0xf1, 0xd3, 0xf1, 0x00, 0x10, 0xc1, 0xd3, 0xf1
	.byte 0x21, 0xc1, 0xd4, 0xf1, 0xf1, 0x6e, 0x11, 0xc9
	.byte 0xd9, 0x63, 0x08, 0xc9, 0x69, 0xf1, 0xd3, 0xf1
	.byte 0x41, 0x68, 0x05, 0xf1, 0xd3, 0xf1, 0x00, 0x10
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0x0c, 0x00, 0x00, 0x00, 0x78, 0xd7
	.byte 0x03, 0xc1, 0xd4, 0xf1, 0x21, 0xc9, 0xd9, 0x63
	.byte 0x08, 0xc9, 0x69, 0xf1, 0xd4, 0xf1, 0x41, 0x68
	.byte 0x09, 0xf1, 0xd4, 0xf1, 0x00, 0x10, 0xc1, 0xd4
	.byte 0xf1, 0x21, 0xc1, 0xd3, 0xf1, 0xf1, 0x6e, 0x11
	.byte 0xc9, 0xd9, 0x63, 0x08, 0xc9, 0x69, 0xf1, 0xd4
	.byte 0xf1, 0x41, 0x68, 0x05, 0xf1, 0xd4, 0xf1, 0x00
	.byte 0x10, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0x42, 0x0d, 0x00, 0x00, 0x00, 0x78
	.byte 0x96, 0x03, 0xc1, 0xd5, 0xf1, 0x21, 0xc9, 0xd9
	.byte 0x73, 0x91, 0x03, 0xc9, 0x69, 0xf1, 0xd5, 0xf1
	.byte 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0x42, 0x0e, 0x00, 0x00, 0x00, 0x78
	.byte 0x76, 0x03, 0xe8, 0xca, 0x0f, 0x00, 0x00, 0x00
	.byte 0xe8, 0xcf, 0x00, 0x00, 0x00, 0x00, 0x77, 0xac
	.byte 0x00, 0xe8, 0xcf, 0x05, 0x00, 0x00, 0x00, 0x7b
	.byte 0xa3, 0x00, 0xe8, 0x80, 0xe8, 0xc8, 0x42, 0x49
	.byte 0xe4, 0x00, 0x90, 0x20, 0xf2, 0x4a, 0x4c, 0xf4
	.byte 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xc1, 0xe9
	.byte 0xf1, 0x21, 0xc9, 0xd9, 0x73, 0x86, 0x00, 0xc9
	.byte 0x69, 0xf1, 0xe9, 0xf1, 0x41, 0xc9, 0xcf, 0x10
	.byte 0x6e, 0x7b, 0xf1, 0xee, 0xf1, 0x00, 0x10, 0x68
	.byte 0x74, 0xd1, 0xea, 0xf1, 0x20, 0xd8, 0xd9, 0x63
	.byte 0x24, 0xd8, 0x69, 0xf1, 0xea, 0xf1, 0x50, 0x68
	.byte 0x1c, 0xd1, 0x28, 0x26, 0x20, 0xd8, 0xd9, 0x63
	.byte 0x06, 0xd8, 0x69, 0xf1, 0x28, 0x26, 0x50, 0xd1
	.byte 0x28, 0x26, 0x20, 0xd1, 0xea, 0xf1, 0xf8, 0x63
	.byte 0x04, 0xf1, 0xea, 0xf1, 0x50, 0xd1, 0x28, 0x26
	.byte 0x20, 0xd1, 0xea, 0xf1, 0xa0, 0xd8, 0x61, 0xf1
	.byte 0xec, 0xf1, 0x50, 0x68, 0x38, 0xc1, 0xee, 0xf1
	.byte 0x21, 0xc9, 0xd9, 0x63, 0x30, 0xc9, 0x69, 0xf1
	.byte 0xee, 0xf1, 0x41, 0xc9, 0xcf, 0x10, 0x6e, 0x25
	.byte 0xf1, 0xe9, 0xf1, 0x00, 0x10, 0x68, 0x1e, 0xd1
	.byte 0xef, 0xf1, 0x20, 0xd8, 0xd9, 0x63, 0x16, 0xd8
	.byte 0x69, 0xf1, 0xef, 0xf1, 0x50, 0x68, 0x0e, 0xc1
	.byte 0x2a, 0x26, 0x21, 0xc9, 0xd8, 0x66, 0x06, 0xc9
	.byte 0x69, 0xf1, 0x2a, 0x26, 0x41, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x0f
	.byte 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x10, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0x42, 0x11, 0x00, 0x00, 0x00, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x12, 0x00, 0x00
	.byte 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x13
	.byte 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x14, 0x00, 0x00, 0x00, 0x78, 0x50, 0x02
	.byte 0xe8, 0xca, 0x15, 0x00, 0x00, 0x00, 0xe8, 0xcf
	.byte 0x00, 0x00, 0x00, 0x00, 0x77, 0xac, 0x00, 0xe8
	.byte 0xcf, 0x05, 0x00, 0x00, 0x00, 0x7b, 0xa3, 0x00
	.byte 0xe8, 0x80, 0xe8, 0xc8, 0x36, 0x49, 0xe4, 0x00
	.byte 0x90, 0x20, 0xf2, 0x70, 0x4d, 0xf4, 0x34, 0xf3
	.byte 0x07, 0xf0, 0xe0, 0xd8, 0xc1, 0xe1, 0xf1, 0x21
	.byte 0xc9, 0xd9, 0x73, 0x86, 0x00, 0xc9, 0x69, 0xf1
	.byte 0xe1, 0xf1, 0x41, 0xc9, 0xcf, 0x10, 0x6e, 0x7b
	.byte 0xf1, 0xe6, 0xf1, 0x00, 0x10, 0x68, 0x74, 0xd1
	.byte 0xe2, 0xf1, 0x20, 0xd8, 0xd9, 0x63, 0x24, 0xd8
	.byte 0x69, 0xf1, 0xe2, 0xf1, 0x50, 0x68, 0x1c, 0xd1
	.byte 0x2e, 0x26, 0x20, 0xd8, 0xd9, 0x63, 0x06, 0xd8
	.byte 0x69, 0xf1, 0x2e, 0x26, 0x50, 0xd1, 0x2e, 0x26
	.byte 0x20, 0xd1, 0xe2, 0xf1, 0xf8, 0x63, 0x04, 0xf1
	.byte 0xe2, 0xf1, 0x50, 0xd1, 0x2e, 0x26, 0x20, 0xd1
	.byte 0xe2, 0xf1, 0xa0, 0xd8, 0x61, 0xf1, 0xe4, 0xf1
	.byte 0x50, 0x68, 0x38, 0xc1, 0xe6, 0xf1, 0x21, 0xc9
	.byte 0xd9, 0x63, 0x30, 0xc9, 0x69, 0xf1, 0xe6, 0xf1
	.byte 0x41, 0xc9, 0xcf, 0x10, 0x6e, 0x25, 0xf1, 0xe1
	.byte 0xf1, 0x00, 0x10, 0x68, 0x1e, 0xd1, 0xe7, 0xf1
	.byte 0x20, 0xd8, 0xd9, 0x63, 0x16, 0xd8, 0x69, 0xf1
	.byte 0xe7, 0xf1, 0x50, 0x68, 0x0e, 0xc1, 0x30, 0x26
	.byte 0x21, 0xc9, 0xd8, 0x66, 0x06, 0xc9, 0x69, 0xf1
	.byte 0x30, 0x26, 0x41, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x15, 0x00, 0x00
	.byte 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x16
	.byte 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0x42, 0x17, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e
	.byte 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0x42, 0x18, 0x00, 0x00, 0x00, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x19, 0x00, 0x00
	.byte 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x1a
	.byte 0x00, 0x00, 0x00, 0x78, 0x2a, 0x01, 0xe8, 0xcf
	.byte 0x1e, 0x00, 0x00, 0x00, 0x66, 0x64, 0xe8, 0xcf
	.byte 0x1d, 0x00, 0x00, 0x00, 0x66, 0x41, 0xe8, 0xcf
	.byte 0x1c, 0x00, 0x00, 0x00, 0x66, 0x1f, 0xe8, 0xcf
	.byte 0x1b, 0x00, 0x00, 0x00, 0x6e, 0x64, 0xc1, 0x08
	.byte 0x27, 0x21, 0xc9, 0xd9, 0x63, 0x5c, 0xc9, 0x69
	.byte 0xf1, 0x08, 0x27, 0x41, 0xd8, 0x12, 0x41, 0x42
	.byte 0x28, 0x00, 0x00, 0x68, 0x2f, 0xc1, 0x0c, 0x27
	.byte 0x21, 0xc9, 0xd9, 0x63, 0x45, 0xc9, 0x69, 0xf1
	.byte 0x0c, 0x27, 0x41, 0xc9, 0xcf, 0x10, 0x6e, 0x3a
	.byte 0xf1, 0x0e, 0x27, 0x00, 0x10, 0x68, 0x33, 0xc1
	.byte 0x0a, 0x27, 0x21, 0xc9, 0xd9, 0x63, 0x2b, 0xc9
	.byte 0x69, 0xf1, 0x0a, 0x27, 0x41, 0xd8, 0x12, 0x41
	.byte 0x52, 0x28, 0x00, 0x00, 0x1d, 0xf5, 0x19, 0xf4
	.byte 0x68, 0x18, 0xc1, 0x0e, 0x27, 0x21, 0xc9, 0xd9
	.byte 0x63, 0x10, 0xc9, 0x69, 0xf1, 0x0e, 0x27, 0x41
	.byte 0xc9, 0xcf, 0x10, 0x6e, 0x05, 0xf1, 0x0c, 0x27
	.byte 0x00, 0x10, 0xe1
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0x42, 0x1b, 0x00, 0x00, 0x00
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x1c, 0x00
	.byte 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x1d, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0x1e, 0x00, 0x00, 0x00, 0x68, 0x60
	.byte 0xc1, 0x78, 0x28, 0x21, 0xc9, 0xd8, 0x66, 0x5c
	.byte 0xc9, 0x69, 0xf1, 0x78, 0x28, 0x41, 0x1d, 0xf3
	.byte 0x09, 0xf4, 0xc1, 0x78, 0x28, 0x21, 0xd8, 0x12
	.byte 0x1d, 0xfc, 0x08, 0xf4, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x1f, 0x00
	.byte 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x20, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0x21, 0x00, 0x00, 0x00, 0x1d, 0x07
	or	bc, (xiz-6)
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0x42, 0x22, 0x00, 0x00, 0x00
	.byte 0x1d, 0x07, 0x9e, 0xfa

LABEL_F44F98:
	pop xiz
	inc 4, xsp
	ret

SeqVoice_DispatchAllEvents:
	push_werp 0xFA
	ldi_berp 0xFB, 0

LABEL_F44FA2:
	ldto_berp A, 0xFB
	extz wa
	calr SeqVoice_DispatchEventToHandler
	ldto_berp A, 0xFB
	extz wa
	calr SeqVoice_ComputeStatusFlags
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, LABEL_F44FA2
	pop_werp 0xFA
	ret

SeqVoice_DispatchEventToHandler:
	dec 2, xsp
	push_werp 0xFA
	ld (xsp + 2), a
	ld a, (xsp + 2)
	inc 1, a
	extz wa
	call Part_IsVoiceActive
	ldfr_berp L, 0xFB
	ld c, (xsp + 2)
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadSubBlock32
	lds32 xbc, 0
	ldto_berp C, 0xFB
	sll xbc, 8
	lds32 xwa, 0
	ld a, (xsp + 2)
	sll xwa, 0
	ld xix, xwa
	add xix, xbc
	ldb h, 0x0
	extz xhl
	add xhl, xix
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002D
	ld xde, xhl
	call ApPostEvent
	pop_werp 0xFA
	inc 2, xsp
	ret

SeqVoice_ComputeStatusFlags:
	dec 2, xsp
	ld (xsp), a
	ldda8 e, 36152
	lds bc, 1
	ld a, (xsp)
	and a, 0xF
	jr z, LABEL_F45025
	slaa bc

LABEL_F45025:
	cp e, 0x9A
	jr z, LABEL_F45097
	ld a, (xsp)
	inc 1, a
	extz wa
	cp e, 0x87
	jr z, LABEL_F45079
	cp e, 0x85
	jr z, LABEL_F45079
	cp e, 0x7A
	jr z, LABEL_F45049
	cp e, 0x78
	jr z, LABEL_F45049
	cp e, 0x81
	jr nz, SeqVoice_PostStatusEvent_Inactive

LABEL_F45049:
	andda16 xbc, 61854
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cps hl, 0
	jr nz, LABEL_F45093

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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002E
	call ApPostEvent
	inc 2, xsp
	ret

LABEL_F45079:
	ld de, bc
	andda16 xbc, 10408
	jr z, LABEL_F45085
	ldb c, 0x1
	jr SeqVoice_PostStatus_Loop

LABEL_F45085:
	andda16 xde, 61854
	jr z, SeqVoice_PostStatusEvent_Inactive
	call Part_IsVoiceActive
	cps hl, 0
	jr z, SeqVoice_PostStatusEvent_Inactive

LABEL_F45093:
	ldb c, 0x2
	jr SeqVoice_PostStatus_Loop

LABEL_F45097:
	andda16 xbc, 9704
	jr z, SeqVoice_PostStatusEvent_Inactive
	ldb c, 0x4
	jr SeqVoice_PostStatus_Loop

LABEL_F450A1:
	dec 2, xsp
	push xiz
	ld (xsp + 4), a
	ldda8 e, 36150
	cp e, 0x9A
	jrl z, LABEL_F45279
	ld c, (xsp + 4)
	inc 1, c
	cp e, 0x97
	jrl z, LABEL_F45231
	cp e, 0x94
	jrl z, LABEL_F45231
	cp e, 0x89
	jrl z, LABEL_F4519B
	ldda16 xwa, 61854
	ldfr_werp WA, 0xFA
	extz bc
	cp e, 0x87
	jr z, LABEL_F45136
	cp e, 0x85
	jr z, LABEL_F45136
	cp e, 0x7A
	jr z, LABEL_F450EB
	cp e, 0x78
	jr z, LABEL_F450EB
	cp e, 0x81
	jrl nz, AppEvent_PopIzSkip2Ret

LABEL_F450EB:
	ld wa, bc
	call LABEL_F4320A
	ldda16 xbc, 61854
	cp_werp BC, 0xFA
	jrl z, AppEvent_PopIzSkip2Ret
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F45107
	slaa de

LABEL_F45107:
	and de, bc
	ldb l, 0x0
	cps de, 0
	jr z, LABEL_F45111
	ldb l, 0x2

LABEL_F45111:
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002E
	call ApPostEvent
	ld a, (xsp + 4)
	extz wa
	jr LABEL_F45195

LABEL_F45136:
	ldda16 xiz, 10408
	ld wa, bc
	call LABEL_F43268
	ldda16 xbc, 61854
	cp_werp BC, 0xFA
	jr nz, LABEL_F45150
	cpdm16 10408, xiz
	jrl z, AppEvent_PopIzSkip2Ret

LABEL_F45150:
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F4515C
	slaa de

LABEL_F4515C:
	ld wa, de
	andda16 xde, 10408
	jr z, LABEL_F45168
	ldb l, 0x1
	jr LABEL_F45172

LABEL_F45168:
	and wa, bc
	ldb l, 0x0
	cps wa, 0
	jr z, LABEL_F45172
	ldb l, 0x2

LABEL_F45172:
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002E
	call ApPostEvent
	ld a, (xsp + 4)
	extz wa

LABEL_F45195:
	calr SeqVoice_DispatchEventToHandler
	jrl AppEvent_PopIzSkip2Ret

LABEL_F4519B:
	extz bc
	dec 1, bc
	cps bc, 0
	jrl lt, AppEvent_PopIzSkip2Ret
	cp bc, 0xF
	jrl gt, AppEvent_PopIzSkip2Ret
	add bc, bc
	lda_24 xix, 0xe449e2
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xf451c1
	jp_dri 8, 0x07, 0xF0, 0xE4
LABEL_F451C1:
	.byte 0x1d, 0x88, 0x04, 0xf2, 0x78, 0xf5, 0x00, 0x1d
	.byte 0x93, 0x04, 0xf2, 0x78, 0xee, 0x00, 0x1d, 0x9e
	.byte 0x04, 0xf2, 0x78, 0xe7, 0x00, 0x1d, 0xa9, 0x04
	.long SoundData_Flute_Extra
	call	15860916
	jrl	217
	call	15860927
	jrl	210
	call	15860938
	jrl	203
	call	15860949
	jrl	196
	call	15860960
	jrl	189
	call	15860971
	jrl	182
	call	15860982
	jrl	175
	call	15860993
	jrl	168
	call	15861004
	jrl	161
	call	15861015
	jrl	154
	call	15861026
	jrl	147
	call	15861037
	jrl	140

LABEL_F45231:
	extz bc
	dec 2, bc
	cps bc, 0
	jr lt, LABEL_F4523F
	cp bc, 0xE
	jr le, LABEL_F45242

LABEL_F4523F:
	ldw bc, 0xF

LABEL_F45242:
	lda_24 xix, 0xe449d2
	ld_srib3 A, 0x07, 0xF0, 0xE4
	ld (xsp + 4), a
	inc 1, a
	extz wa
	call BmDrEdit_CheckNoteType
	cps hl, 0
	jr nz, AppEvent_PopIzSkip2Ret
	mrdb5 0x8F, 0x04, 0x19, 0x65, 0x29
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	lda_24 xbc, 0xe4485c
	ldmm_sriw 0x07, 0xE4, 0xE0, 0x4F, 0x0D
	call BmDrEdit_SaveSequencerState
	jr AppEvent_PopIzSkip2Ret

LABEL_F45279:
	lds de, 1
	ld a, (xsp + 4)
	and a, 0xF
	jr z, LABEL_F45285
	slaa de

LABEL_F45285:
	ld wa, de
	ldda16 xbc, 9704
	and wa, bc
	jr z, LABEL_F45297
	ldb l, 0x0
	cpl de
	and bc, de
	jr LABEL_F4529B

LABEL_F45297:
	ldb l, 0x4
	or bc, de

LABEL_F4529B:
	stda16 9704, xbc
	ldb h, 0x0
	extz xhl
	lds32 xwa, 0
	ld a, (xsp + 4)
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002E
	call ApPostEvent

AppEvent_PopIzSkip2Ret:
	pop xiz
	inc 2, xsp
	ret

EffEditMain:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	ldda8 e, 36152
	cp xbc, 0x1E80012
	jrl z, LABEL_F45489
	cp xbc, 0x1E80011
	jrl z, LABEL_F45365
	cp xbc, 0x1C0000B
	jrl nz, AppEvent_ReturnZeroEpilogue4
	ld xwa, (xsp + 2)
	stda32 10610, xwa
	calr LABEL_F457CF
	cps hl, 0
	jrl nz, AppEvent_ReturnZeroEpilogue4
	ld xwa, (xsp + 2)
	ld xbc, 0x1E8000E
	lds32 xde, 0
	call ApDeliveryEvent
	ldda8 a, 36152
	cp a, 0xD6
	jr z, LABEL_F4534A
	cp a, 0xE
	jr z, LABEL_F45339
	cp a, 0xB
	jr z, LABEL_F4531C
	cp a, 0xA
	jrl nz, AppEvent_ReturnZeroEpilogue4

LABEL_F4531C:
	lds iz, 0

LABEL_F4531E:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1E8000F
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F4531E
	jrl AppEvent_ReturnZeroEpilogue4

LABEL_F45339:
	ld xwa, (xsp + 2)
	ld xbc, 0x1E8000F
	lds32 xde, 0
	call ApDeliveryEvent
	jrl AppEvent_ReturnZeroEpilogue4

LABEL_F4534A:
	lds iz, 0

LABEL_F4534C:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1E8000F
	call ApDeliveryEvent
	inc 1, iz
	cps iz, 4
	jr c, LABEL_F4534C
	jrl AppEvent_ReturnZeroEpilogue4

LABEL_F45365:
	ld xbc, (xsp + 2)
	cp e, 0xB
	jrl z, LABEL_F45410
	cp e, 0xA
	jr z, LABEL_F45398
	cp e, 0xD6
	jr z, LABEL_F4538B
	cp e, 0xE
	jrl nz, AppEvent_ReturnZeroEpilogue4
	stdi8 58252, 1
	ld xwa, 0x4D00
	jrl LABEL_F454E7

LABEL_F4538B:
	stdi8 58252, 1
	ld xwa, 0x4E00
	jrl LABEL_F454E7

LABEL_F45398:
	stdi8 58252, 1
	ldda16 xwa, 10614
	extz wa
	lda_24 xde, 0xe447dc
	ld_srib3 E, 0x07, 0xE8, 0xE0
	lda_24 xwa, 0xe4475c
	cps e, 0
	jr ge, LABEL_F453C2
	ld c, (xwa)
	exts bc
	ld xwa, 0x4B00
	jrl EffEdit_WriteDSPAndReturn

LABEL_F453C2:
	cps bc, 0
	jr le, LABEL_F453DB
	inc 1, e
	ld_srib3 C, 0x03, 0xE0, 0xE8
	cps c, 0
	jr lt, AppEvent_DeliveryLoop
	exts bc
	ld xwa, 0x4B00
	jrl EffEdit_WriteDSPAndReturn

LABEL_F453DB:
	cps bc, 0
	jr ge, AppEvent_DeliveryLoop
	cps e, 0
	jr z, AppEvent_DeliveryLoop
	dec 1, e
	ld_srib3 C, 0x03, 0xE0, 0xE8
	exts bc
	ld xwa, 0x4B00
	jr EffEdit_WriteDSPAndReturn

AppEvent_DeliveryLoop:
	lds iz, 0

LABEL_F453F5:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1E8000F
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F453F5
	jrl AppEvent_ReturnZeroEpilogue4

LABEL_F45410:
	stdi8 58252, 1
	ldda16 xwa, 10614
	extz wa
	lda_24 xde, 0xe446dc
	ld_srib3 E, 0x07, 0xE8, 0xE0
	lda_24 xwa, 0xe4465c
	cps e, 0
	jr ge, LABEL_F45439
	ld c, (xwa)
	exts bc
	ld xwa, 0x4900
	jr EffEdit_WriteDSPAndReturn

LABEL_F45439:
	cps bc, 0
	jr le, LABEL_F45451
	inc 1, e
	ld_srib3 C, 0x03, 0xE0, 0xE8
	cps c, 0
	jr lt, AppEvent_DeliveryNoRet
	exts bc
	ld xwa, 0x4900
	jr EffEdit_WriteDSPAndReturn

LABEL_F45451:
	cps bc, 0
	jr ge, AppEvent_DeliveryNoRet
	cps e, 0
	jr z, AppEvent_DeliveryNoRet
	dec 1, e
	ld_srib3 C, 0x03, 0xE0, 0xE8
	exts bc
	ld xwa, 0x4900

EffEdit_WriteDSPAndReturn:
	call DSPCfg_WriteParamFull
	jr AppEvent_ReturnZeroEpilogue4

AppEvent_DeliveryNoRet:
	lds iz, 0

LABEL_F4546F:
	ld xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, 0x1E8000F
	call ApDeliveryEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F4546F
	jr AppEvent_ReturnZeroEpilogue4

LABEL_F45489:
	ld xwa, (xsp + 2)
	and xwa, 0xFF
	ldb w, 0x0
	extz xwa
	cp e, 0xD6
	jr z, LABEL_F454DF
	cp e, 0xE
	jr z, LABEL_F454D8
	cp e, 0xC
	jr z, LABEL_F454D0
	cp e, 0xB
	jr z, LABEL_F454C8
	cp e, 0xA
	jr nz, AppEvent_ReturnZeroEpilogue4
	add xwa, 0x4B10

Voice_OffsetAndDispatch:
	ld xbc, (xsp + 2)
	srl xbc, 8
	ldi_werp 0xE6, 0
	cp e, 0xC
	jr nz, LABEL_F454E7
	calr LABEL_F459E9
	jr AppEvent_ReturnZeroEpilogue4

LABEL_F454C8:
	add xwa, 0x4910
	jr Voice_OffsetAndDispatch

LABEL_F454D0:
	add xwa, 0x4C10
	jr Voice_OffsetAndDispatch

LABEL_F454D8:
	ld xwa, 0x4D10
	jr Voice_OffsetAndDispatch

LABEL_F454DF:
	add xwa, 0x4E10
	jr Voice_OffsetAndDispatch

LABEL_F454E7:
	call DSPCfg_WriteParamDelta

AppEvent_ReturnZeroEpilogue4:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

LABEL_F454F1:
	.byte 0xef, 0x6c, 0x2e, 0xc1, 0x80, 0xc0, 0x21, 0xd8
	.byte 0x12, 0xc1, 0x7d, 0xc0, 0x23, 0xd9, 0x12, 0xc1
	.byte 0x7f, 0xc0, 0x25, 0xda, 0x12, 0xbf, 0x02, 0x33
	.byte 0x3b, 0x1d, 0xa0, 0xce, 0xfd, 0xdb, 0xd8, 0x71
	.byte 0xb8, 0x02, 0xc1, 0x38, 0x8d, 0x21, 0xc9, 0xcf
	.byte 0xd6, 0x76, 0x11, 0x02, 0xc9, 0xcf, 0x0e, 0x76
	.byte 0xa6, 0x01, 0xc9, 0xcf, 0x0c, 0x76, 0x58, 0x01
	.byte 0xc9, 0xcf, 0x0b, 0x76, 0xac, 0x00, 0xc9, 0xcf
	.byte 0x0a, 0x7e, 0x96, 0x02, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x00, 0x4b, 0x00, 0x00, 0x77, 0x8a, 0x02
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x47, 0x4b, 0x00
	.byte 0x00, 0x7f, 0x7e, 0x02, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x00, 0x4b, 0x00, 0x00, 0x6e, 0x53, 0x1e
	.byte 0x74, 0x02, 0xdb, 0xd8, 0x7e, 0x6b, 0x02, 0xe1
	.ascii "r) A"
	.byte 0x0e, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0xc1, 0x8c
	.byte 0xe3, 0x3f, 0x01, 0x7e, 0x06, 0x02, 0xde, 0xa8
	.byte 0x68, 0x20, 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x10, 0x4b, 0x00, 0x00, 0x1d, 0xfe, 0xc7, 0xfd
	.byte 0xdb, 0x89, 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8
	.byte 0x10, 0x4b, 0x00, 0x00, 0x1d, 0x01, 0xc9, 0xfd
	.byte 0xde, 0x61, 0xd1, 0xaa, 0x29, 0xf6, 0x7f, 0xdb
	.byte 0x01, 0xde, 0xcf, 0x19, 0x00, 0x67, 0xd3, 0x78
	.byte 0xd2, 0x01, 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10
	.byte 0x4b, 0x00, 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20
	.byte 0x1d, 0xf9, 0xc7, 0xfd, 0xde, 0x88, 0xd8, 0x80
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
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xc1, 0x8c, 0xe3, 0x3f
	.byte 0x01, 0x7e, 0x60, 0x01, 0xde, 0xa8, 0x68, 0x20
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x49
	.byte 0x00, 0x00, 0x1d, 0xfe, 0xc7, 0xfd, 0xdb, 0x89
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x49
	.byte 0x00, 0x00, 0x1d, 0x01, 0xc9, 0xfd, 0xde, 0x61
	.byte 0xd1, 0xaa, 0x29, 0xf6, 0x7f, 0x35, 0x01, 0xde
	.byte 0xcf, 0x19, 0x00, 0x67, 0xd3, 0x78, 0x2c, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10, 0x49, 0x00
	.byte 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x1d, 0xf9
	.byte 0xc7, 0xfd, 0xde, 0x88, 0xd8, 0x80, 0xf1, 0x78
	.byte 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0x53
	.byte 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a, 0xea, 0x12
	.byte 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x78, 0x46, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x10, 0x4c, 0x00
	.byte 0x00, 0x77, 0x3e, 0x01, 0xaf, 0x02, 0x20, 0xe8
	.byte 0xcf, 0x17, 0x4c, 0x00, 0x00, 0x7b, 0x32, 0x01
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10, 0x4c, 0x00
	.byte 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x1d, 0xf9
	.byte 0xc7, 0xfd, 0xde, 0x88, 0xd8, 0x80, 0xf1, 0x78
	.byte 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0, 0x53
	.byte 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a, 0xea, 0x12
	.byte 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x78, 0xfe, 0x00
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x00, 0x4d, 0x00
	.byte 0x00, 0x6e, 0x35, 0x1e, 0xf8, 0x00, 0xdb, 0xd8
	.byte 0x7e, 0xef, 0x00, 0xe1
	.ascii "r) A"
	.byte 0x0e, 0x00, 0xe8, 0x01, 0xea, 0xa8, 0x1d, 0x07
	.byte 0x9e, 0xfa, 0xc1, 0x8c, 0xe3, 0x3f, 0x01, 0x7e
	.byte 0x8a, 0x00, 0x40, 0x10, 0x4d, 0x00, 0x00, 0x1d
	.byte 0xfe, 0xc7, 0xfd, 0xdb, 0x89, 0x40, 0x10, 0x4d
	.byte 0x00, 0x00, 0x1d, 0x01, 0xc9, 0xfd, 0x68, 0x74
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x10, 0x4d, 0x00
	.byte 0x00, 0x7e, 0xb6, 0x00, 0xaf, 0x02, 0x20, 0x1d
	.byte 0xf9, 0xc7, 0xfd, 0xf1, 0x78, 0x29, 0x53, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x78, 0x99, 0x00, 0xaf, 0x02, 0x20
	.byte 0xe8, 0xcf, 0x00, 0x4e, 0x00, 0x00, 0x6e, 0x4b
	.byte 0x1e, 0x93, 0x00, 0xdb, 0xd8, 0x7e, 0x8a, 0x00
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0e, 0x00, 0xe8
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x07, 0x9e, 0xfa, 0xc1
	.byte 0x8c, 0xe3, 0x3f, 0x01, 0x6e, 0x26, 0xde, 0xa8
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x4e
	.byte 0x00, 0x00, 0x1d, 0xfe, 0xc7, 0xfd, 0xdb, 0x89
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0xc8, 0x10, 0x4e
	.byte 0x00, 0x00, 0x1d, 0x01, 0xc9, 0xfd, 0xde, 0x61
	.byte 0xde, 0xdc, 0x67, 0xdc, 0xf1, 0x8c, 0xe3, 0x00
	.byte 0x00, 0x68, 0x47, 0xaf, 0x02, 0x20, 0xe8, 0xcf
	.byte 0x10, 0x4e, 0x00, 0x00, 0x67, 0x3c, 0xaf, 0x02
	.byte 0x20, 0xe8, 0xcf, 0x13, 0x4e, 0x00, 0x00, 0x6b
	.byte 0x31, 0xaf, 0x02, 0x20, 0xe8, 0xca, 0x10, 0x4e
	.byte 0x00, 0x00, 0xd8, 0x8e, 0xaf, 0x02, 0x20, 0x1d
	.byte 0xf9, 0xc7, 0xfd, 0xde, 0x88, 0xd8, 0x80, 0xf1
	.byte 0x78, 0x29, 0x31, 0xe8, 0x12, 0xe9, 0x80, 0xb0
	.byte 0x53, 0xe1, 0x72, 0x29, 0x20, 0xde, 0x8a, 0xea
	.byte 0x12, 0x41, 0x0f, 0x00, 0xe8, 0x01, 0x1d, 0x07
	.byte 0x9e, 0xfa, 0x4e, 0xef, 0x64, 0x0e

LABEL_F457CF:
	push_werp 0xFA
	ldada xde, 10668
	ld xwa, xde
	ldada xbc, 10616
	lda xde, (xde + 25)

LABEL_F457DF:
	stiw_dpi 0xE5, 0x00, 0x00
	stib_dpi 0xE0, 0x00
	cp xwa, xde
	jr c, LABEL_F457DF
	ldda8 a, 36152
	cp a, 0xD6
	jrl z, LABEL_F45986
	cp a, 0xE
	jrl z, LABEL_F45965
	cp a, 0xC
	jrl z, LABEL_F45937
	cp a, 0xB
	jrl z, LABEL_F458A7
	cp a, 0xA
	jrl nz, LABEL_F459E2
	ld xwa, 0x4B00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7F
	stda16 10614, xhl
	ld xwa, 0x4B04
	call DSPCfg_ReadParam_Map0
	stda16 10666, xhl
	ldi_berp 0xFB, 0
	jr LABEL_F45871

LABEL_F45831:
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4B10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	ldada xbc, 10616
	st_dri3w HL, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4B10
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xFB
	extz bc
	ldada xwa, 10668
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1_berp 0xFB

LABEL_F45871:
	ldto_berp C, 0xFB
	extz bc
	ldda16 xwa, 10666
	cp bc, wa
	jr nc, LABEL_F45884
	cp_erpb 0xFB, 0x19
	jr c, LABEL_F45831

LABEL_F45884:
	ld bc, wa
	lda_24 xwa, 0x0029ab
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	cps a, 3
	jr nz, EffEdit_ReturnZeroJmp
	ld (xbc), 0x0
	ldda16 xwa, 10666
	dec 1, wa
	stda16 10666, xwa

EffEdit_ReturnZeroJmp:
	lds hl, 0
	jrl LABEL_F459E5

LABEL_F458A7:
	ld xwa, 0x4900
	call DSPCfg_ReadParam_Map0
	and hl, 0x7F
	stda16 10614, xhl
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	stda16 10666, xhl
	ldi_berp 0xFB, 0
	jr LABEL_F4590A

LABEL_F458CA:
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	ldada xbc, 10616
	st_dri3w HL, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4910
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xFB
	extz bc
	ldada xwa, 10668
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1_berp 0xFB

LABEL_F4590A:
	ldto_berp C, 0xFB
	extz bc
	ldda16 xwa, 10666
	cp bc, wa
	jr nc, LABEL_F4591D
	cp_erpb 0xFB, 0x19
	jr c, LABEL_F458CA

LABEL_F4591D:
	ld de, wa
	lda_24 xbc, 0x0029ab
	extz xde
	add xde, xbc
	cp (xde), 0x55
	jrl nz, EffEdit_ReturnZeroJmp
	dec 1, wa
	stda16 10666, xwa
	jrl EffEdit_ReturnZeroJmp

LABEL_F45937:
	ldi_berp 0xFB, 0

LABEL_F4593A:
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4C10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	ldada xbc, 10616
	st_dri3w HL, 0x07, 0xE4, 0xE0
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x08
	jr c, LABEL_F4593A
	jrl EffEdit_ReturnZeroJmp

LABEL_F45965:
	ld xwa, 0x4D00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7F
	stda16 10614, xhl
	ld xwa, 0x4D10
	call DSPCfg_ReadParam_Map0
	stda16 10616, xhl
	jrl EffEdit_ReturnZeroJmp

LABEL_F45986:
	ld xwa, 0x4E00
	call DSPCfg_ReadParam_Map0
	and hl, 0x7F
	stda16 10614, xhl
	ldi_berp 0xFB, 0

LABEL_F4599A:
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4E10
	call DSPCfg_ReadParam_Map0
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	ldada xbc, 10616
	st_dri3w HL, 0x07, 0xE4, 0xE0
	lds32 xwa, 0
	ldto_berp A, 0xFB
	add xwa, 0x4E10
	call DSPCfg_ResolveAndExtract
	ldto_berp C, 0xFB
	extz bc
	ldada xwa, 10668
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc1_berp 0xFB
	cpi_berp 0xFB, 4
	jr c, LABEL_F4599A
	jrl EffEdit_ReturnZeroJmp

LABEL_F459E2:
	ldw hl, 0xFFFF

LABEL_F459E5:
	pop_werp 0xFA
	ret

LABEL_F459E9:
	dec 8, xsp
	push xiz
	ld (xsp + 6), bc
	ld (xsp + 8), xwa
	ld xwa, 0x4C10
	call DSPCfg_ReadParam_Map0
	ld (xsp + 4), hl
	ld xwa, 0x4C12
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	ld xwa, 0x4C14
	call DSPCfg_ReadParam_Map0
	ld iz, hl
	ld xwa, 0x4C16
	call DSPCfg_ReadParam_Map0
	ldto_werp BC, 0xFA
	sub bc, (xsp + 4)
	ld xwa, (xsp + 8)
	cp xwa, 0x4C10
	jr nz, LABEL_F45A3C
	cpw (xsp + 6), 0x0
	jr le, EffEdit_WriteValidDelta
	cps bc, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

LABEL_F45A3C:
	ld de, iz
	sub_werp DE, 0xFA
	ld xwa, (xsp + 8)
	cp xwa, 0x4C12
	jr nz, LABEL_F45A5F
	cpw (xsp + 6), 0x0
	jr ge, LABEL_F45A59
	cps bc, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

LABEL_F45A59:
	cps de, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

LABEL_F45A5F:
	sub hl, iz
	ld xwa, (xsp + 8)
	cp xwa, 0x4C14
	jr nz, LABEL_F45A89
	cpw (xsp + 6), 0x0
	jr ge, LABEL_F45A79
	cps de, 1
	jr gt, EffEdit_WriteValidDelta
	jr EffEdit_PopIzSkip8Ret

LABEL_F45A79:
	cps hl, 1
	jr le, EffEdit_PopIzSkip8Ret

EffEdit_WriteValidDelta:
	ld xwa, (xsp + 8)
	ld bc, (xsp + 6)
	call DSPCfg_WriteParamDelta
	jr EffEdit_PopIzSkip8Ret

LABEL_F45A89:
	ld xwa, (xsp + 8)
	cp xwa, 0x4C16
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
	cp xbc, 0x1E0003B
	jr nz, LABEL_F45AB5
	or xde, xde
	scc8 nz, a
	extz wa
	call LABEL_FDE01C

LABEL_F45AB5:
	lds32 xhl, 0
	ret

ApPlaySyori:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xde
	cp xbc, 0x1E80046
	jrl z, LABEL_F46358
	cp xbc, 0x1E80045
	jrl z, LABEL_F462D3
	cp xbc, 0x1E80044
	jrl z, LABEL_F46210
	ldda16 xde, 9832
	ldda16 xhl, 9506
	ldda16 xiy, 9504
	ldda16 xiz, 9502
	ldda16 xwa, 9500
	ldfr_werp WA, 0xEA
	ldda8 a, 10298
	ldfr_berp A, 0xEE
	ldda8 a, 36150
	ldfr_berp A, 0xEF
	cp xbc, 0x1E80015
	jrl z, LABEL_F45FD9
	cp xbc, 0x1E80014
	jrl z, LABEL_F45DC1
	cp xbc, 0x1C0000B
	jrl nz, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	stda32 10610, xwa
	ldda8 c, 36150
	cp c, 0x99
	jrl z, SeqAccomp_DispatchRhythmEvents
	cp c, 0x96
	jrl z, SeqAccomp_DispatchRhythmEvents
	ld xwa, (xsp + 2)
	cp c, 0x7A
	jr z, SeqAccomp_StartAndPostEvents
	cp c, 0x78
	jr z, SeqAccomp_StartAndPostEvents
	extz bc
	sub bc, 0x81
	cps bc, 0
	jrl lt, AppEvent_ReturnZero
	cps bc, 7
	jrl gt, AppEvent_ReturnZero
	add bc, bc
	lda_24 xix, 0xe44a32
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xf45b63
	jp_dri 8, 0x07, 0xF0, 0xE4
LABEL_F45B63:
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d
	.byte 0x07, 0x9e, 0xfa, 0xc1, 0x33, 0x04, 0x19, 0x32
	ldb	c, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa9, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xc1, 0xb1, 0x28, 0x21, 0xc9, 0xcc, 0x01, 0xc9
	.byte 0xd8, 0xde, 0x7e, 0xde, 0x88, 0xe8, 0x13, 0x78
	.byte 0x2b, 0x07

SeqAccomp_StartAndPostEvents:
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl SeqAccomp_StartHandler
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	stda8 7528, l
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	bitda 1, 10417
	jr z, LABEL_F45BF7
	lds iz, 1
	ld xwa, 0x850014
	lds bc, 1
	call SetVisible
	ld xwa, 0x850013
	ld xbc, 0x1E0009C
	lds32 xde, 1
	jr LABEL_F45C10

LABEL_F45BF7:
	lds iz, 0
	ld xwa, 0x850014
	lds bc, 0
	call SetVisible
	ld xwa, 0x850013
	ld xbc, 0x1E0009C
	lds32 xde, 0

LABEL_F45C10:
	call ApPostEvent
	ld wa, iz
	exts xwa
	calr AppEvent_SendPlayStatus
	ldda8 a, 10418
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld wa, iz
	exts xwa
	jrl LABEL_F46301
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	ldmm8 9010, 1075
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	call ApDeliveryEvent
	call Seq_ComputePercentClamped99
	stda8 7528, l
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ldda8 a, 10418
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x87000D
	ld xbc, 0x1E0003B
	call ApDeliveryEvent
	lds wa, 0
	jrl LABEL_F46378
	bitda 2, 1057
	jr nz, SeqAcc_SendParamsAndStart
	ldda16 xbc, 9832
	stda16 9964, xbc
	ldda16 xbc, 9832
	ld wa, bc
	extz xwa
	bit 15, wa
	jr nz, SeqAcc_SendParamsAndStart
	ldda16 xwa, 62008
	cp bc, wa
	jr ule, LABEL_F45CB7
	subda16 xwa, 62015
	stda16 9832, xwa
	stda16 9964, xwa
	jr SeqAcc_SendParamsAndStart

LABEL_F45CB7:
	dec 1, wa
	stda16 10435, xwa
	call SeqAcc_UpdateEndPosition
	ldda16 xwa, 62008
	subda16 xwa, 62015
	stda16 9832, xwa
	stda16 9964, xwa

SeqAcc_SendParamsAndStart:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 7
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x8
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x9
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xA
	call ApDeliveryEvent
	ldda8 a, 10418
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld de, iz
	exts xde
	ld xwa, 0x880004
	ld xbc, 0x1E0003B
	jrl SeqAccomp_StartHandler
	ldda8 a, 10418
	and a, 0x1
	cps a, 0
	scc16 nz, iz
	ld wa, iz
	exts xwa
	calr AppEvent_SendAccompStatus
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 3
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 4
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 5
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 6
	jrl SeqAccomp_StartHandler

SeqAccomp_DispatchRhythmEvents:
	call LABEL_F387F4
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 3
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 5
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 6
	call ApDeliveryEvent
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xB
	jrl SeqAccomp_StartHandler

LABEL_F45DC1:
	ld xwa, (xsp + 2)
	cp xwa, 0xB
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, 0xE44A1A
	ld wa, (xwa)
	lda_24 xix, 0xf45de1
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F45DE1:
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x93, 0x05, 0xda
	.byte 0x88, 0xda, 0xcf, 0xe7, 0x03, 0x7f, 0x8a, 0x05
	.byte 0xd8, 0x61, 0xf1, 0x68, 0x26, 0x50, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa8, 0x78, 0x4e, 0x03, 0xf1, 0x21, 0x04, 0xca
	.byte 0x7e, 0x6f, 0x05, 0xc7, 0xef, 0x89, 0xc7, 0xef
	.byte 0xcf, 0x82, 0x6e, 0x13, 0xc1, 0xb1, 0x28, 0x21
	.byte 0xc9, 0x33, 0x00, 0x7e, 0x5c, 0x05, 0xc9, 0x31
	.byte 0x00, 0xf1, 0xb1
	.ascii "(Ah0ÉÏ†n+ñ²(Ê"
	.byte 0x7e, 0x47, 0x05, 0xf1, 0xb1, 0x28, 0xc9, 0x7e
	.byte 0x40, 0x05, 0x1d, 0x8a, 0xf0, 0xf3, 0xf1, 0xb1
	.byte 0x28, 0xb9, 0xd1, 0x20, 0x25, 0x19, 0x68, 0x26
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0xea, 0xab, 0x1d, 0x07, 0x9e, 0xfa, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xac, 0x78, 0xed, 0x02, 0xf1, 0x21, 0x04
	.byte 0xca, 0x7e, 0x0e, 0x05, 0xc1, 0x36, 0x8d, 0x3f
	.byte 0x86, 0x6e, 0x2c, 0xdd, 0x88, 0xdd, 0xcf, 0xe7
	.byte 0x03, 0x7f, 0xfe, 0x04, 0xd8, 0x61, 0xf1, 0x20
	.byte 0x25, 0x50, 0xf1, 0x68, 0x26, 0x50, 0xd1, 0x22
	.byte 0x25, 0xf0, 0x63, 0x43, 0xd1, 0x20, 0x25, 0x19
	.byte 0x22, 0x25, 0xe1
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0xea, 0xae, 0x68, 0x2c, 0xd7
	.byte 0xea, 0x88, 0xd7, 0xea, 0xcf, 0xe7, 0x03, 0x7f
	.byte 0xd0, 0x04, 0xd8, 0x61, 0xf1, 0x1c, 0x25, 0x50
	.byte 0xf1, 0x68, 0x26, 0x50, 0xd1, 0x1e, 0x25, 0xf0
	.byte 0x63, 0x15, 0xd1, 0x1c, 0x25, 0x19, 0x1e, 0x25
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0xea, 0xae, 0x1d, 0x07, 0x9e, 0xfa, 0x1e
	.byte 0x11, 0x06, 0xe1
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0xea, 0xad, 0x78, 0x72, 0x02
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x93, 0x04, 0xc1
	.byte 0x36, 0x8d, 0x3f, 0x86, 0x6e, 0x17, 0xdb, 0x88
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
	.byte 0x00, 0x00, 0x00, 0x6e, 0x10, 0x1d, 0xbe, 0x8b
	.byte 0xf3, 0x68, 0x0a, 0x1d, 0xb2, 0x8c, 0xf3, 0x68
	.byte 0x04, 0x1d, 0x13, 0x8d, 0xf3, 0xe1, 0x72, 0x29
	.byte 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xaf
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x08, 0x00
	.byte 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x09, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0
	.byte 0x01, 0x42, 0x0a, 0x00, 0x00, 0x00, 0x78, 0x2b
	.byte 0x02, 0xc7, 0xee, 0xd9, 0x76, 0xd3, 0x03, 0xf1
	.byte 0x3a, 0x28, 0x00, 0x01, 0xd1, 0x63, 0x29, 0x19
	.byte 0x9e, 0xf1, 0x1d, 0x6f, 0xde, 0xfd, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x0b, 0x00, 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa
	.byte 0xd1, 0x9e, 0xf1, 0x19, 0x38, 0x28, 0xf1, 0x21
	.byte 0x04, 0xca, 0x76, 0x33, 0x02, 0x78, 0xa2, 0x03

LABEL_F45FD9:
	ld xwa, (xsp + 2)
	cp xwa, 0xB
	jrl ugt, AppEvent_ReturnZero
	add xwa, xwa
	add xwa, 0xE44A02
	ld wa, (xwa)
	lda_24 xix, 0xf45ff9
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F45FF9:
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x7b, 0x03, 0xda
	.byte 0x88, 0xda, 0xd9, 0x73, 0x4b, 0x03, 0xd8, 0x69
	.byte 0xf1, 0x68, 0x26, 0x50, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x78
	.byte 0x38, 0x01, 0xc7, 0xef, 0x8b, 0xc1, 0xb1, 0x28
	.byte 0x21, 0xc7, 0xef, 0xcf, 0x82, 0x6e, 0x1c, 0xc9
	.byte 0x8b, 0xc9, 0x33, 0x00, 0x76, 0x4b, 0x03, 0xf1
	.byte 0x21, 0x04, 0xca, 0x66, 0x05, 0x1e, 0x48, 0x03
	.byte 0x68, 0x4c, 0xcb, 0x30, 0x00, 0xf1, 0xb1, 0x28
	.byte 0x43, 0x68, 0x3f, 0xcb, 0xcf, 0x86, 0x6e, 0x3e
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x2b, 0x03, 0xf1
	.byte 0xb2, 0x28, 0xca, 0x7e, 0x24, 0x03, 0xc9, 0x8b
	.byte 0xc9, 0x33, 0x01, 0x76, 0x1c, 0x03, 0xcb, 0x30
	.byte 0x01, 0xf1, 0xb1, 0x28, 0x43, 0xf1, 0x68, 0x26
	.byte 0x02, 0x01, 0x00, 0x1e, 0x75, 0x04, 0xd1, 0xa8
	.byte 0x28, 0x20, 0xd1, 0x9e, 0xf1, 0x21, 0xd8, 0x06
	.byte 0xd8, 0xc1, 0xf1, 0x9e, 0xf1, 0x51, 0x1d, 0x6f
	.byte 0xde, 0xfd, 0x1d, 0x99, 0xe8, 0xf3, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0xea
	.byte 0xac, 0x78, 0x38, 0x01, 0xf1, 0x21, 0x04, 0xca
	.byte 0x7e, 0xdf, 0x02, 0xc1, 0x36, 0x8d, 0x3f, 0x86
	.byte 0x6e, 0x13, 0xdd, 0x88, 0xdd, 0xd9, 0x73, 0xd1
	.byte 0x02, 0xd8, 0x69, 0xf1, 0x20, 0x25, 0x50, 0xf1
	.ascii "h&Ph"
	.byte 0x13, 0xd7, 0xea, 0x88
	.byte 0xd7, 0xea, 0xd9, 0x73, 0xbc, 0x02, 0xd8, 0x69
	.byte 0xf1, 0x1c, 0x25, 0x50, 0xf1, 0x68, 0x26, 0x50
	.byte 0x1e, 0x18, 0x04, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xad, 0x68, 0x7a
	.byte 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x9b, 0x02, 0xc1
	.byte 0x36, 0x8d, 0x3f, 0x86, 0x6e, 0x30, 0xdb, 0x88
	.byte 0xdb, 0xd9, 0x73, 0x8d, 0x02, 0xd8, 0x69, 0xf1
	.byte 0x22, 0x25, 0x50, 0xd1, 0x20, 0x25, 0xf8, 0x63
	.byte 0x15, 0xd1, 0x22, 0x25, 0x19, 0x20, 0x25, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xad, 0x1d, 0x07, 0x9e, 0xfa, 0xd1, 0x20
	ldb	e, 0x19
	.ascii "h&h."
	ld	wa, iz
	.byte 0xde, 0xd9, 0x73, 0x5d, 0x02, 0xd8, 0x69, 0xf1
	.byte 0x1e, 0x25, 0x50, 0xd1, 0x1c, 0x25, 0xf8, 0x63
	.byte 0x15, 0xd1, 0x1e, 0x25, 0x19, 0x1c, 0x25, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xad, 0x1d, 0x07, 0x9e, 0xfa, 0xd1, 0x1c
	.byte 0x25, 0x19, 0x68, 0x26, 0x1e, 0x9c, 0x03, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01
	.byte 0xea, 0xae, 0x1d, 0x07, 0x9e, 0xfa, 0x78, 0xf8
	.byte 0x01, 0xf1, 0x21, 0x04, 0xca, 0x7e, 0x1a, 0x02
	.byte 0xaf, 0x02, 0x20, 0xe8, 0xcf, 0x0a, 0x00, 0x00
	.byte 0x00, 0x66, 0x1c, 0xe8, 0xcf, 0x09, 0x00, 0x00
	.byte 0x00, 0x66, 0x0e, 0xe8, 0xcf, 0x08, 0x00, 0x00
	.byte 0x00, 0x6e, 0x10, 0x1d, 0xea, 0x8b, 0xf3, 0x68
	.byte 0x0a, 0x1d, 0xe4, 0x8c, 0xf3, 0x68, 0x04, 0x1d
	.byte 0x59, 0x8d, 0xf3, 0xe1
	.ascii "r) A"
	.byte 0x0f, 0x00, 0xc0, 0x01, 0xea, 0xaf, 0x1d, 0x07
	or	bc, (xiz-6)
	.ascii "r) A"
	.byte 0x0f
	.byte 0x00, 0xc0, 0x01, 0x42, 0x08, 0x00, 0x00, 0x00
	.byte 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42, 0x09, 0x00
	.byte 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xe1, 0x72
	.byte 0x29, 0x20, 0x41, 0x0f, 0x00, 0xc0, 0x01, 0x42
	.byte 0x0a, 0x00, 0x00, 0x00

SeqAccomp_StartHandler:
	call ApDeliveryEvent
	jrl AppEvent_ReturnZero
	cpi_berp 0xEE, 0
	jrl z, AppEvent_ReturnZero
	stdi8 10298, 0
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	call Audio_CheckSubsystemReady
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xB
	call ApDeliveryEvent
	ldmm16 10296, 61854
	bitda 2, 1057
	jrl nz, AppEvent_ReturnZero
	call SeqPlay_AllocBuffersAndInit
	jrl AppEvent_ReturnZero

LABEL_F46210:
	cpdi8 36150, 133
	jrl nz, LABEL_F46298
	bitda 2, 1057
	jr nz, LABEL_F46224
	bitda 2, 10418
	jr z, LABEL_F46240

LABEL_F46224:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F46232
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr LABEL_F46237

LABEL_F46232:
	lds32 xwa, 0
	ld (xsp + 2), xwa

LABEL_F46237:
	ld xwa, (xsp + 2)
	calr AppEvent_SendPlayStatus
	jrl AppEvent_ReturnZero

LABEL_F46240:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F46283
	resda 1, 10417
	stdi16 9832, 1
	ldda16 xwa, 10408
	ldda16 xbc, 61854
	cpl wa
	and bc, wa
	stda16 61854, xbc
	call Audio_CheckSubsystemReady
	ld xwa, 0x850014
	lds bc, 0
	call SetVisible
	ld xwa, 0x850013
	ld xbc, 0x1E0009C
	lds32 xde, 0
	call ApDeliveryEvent
	jrl SeqAccomp_InitAndReturn

LABEL_F46283:
	call LABEL_F3F08A
	setda 1, 10417
	ldda16 xwa, 9504
	stda16 9832, xwa
	ldw wa, 0x86
	jr LABEL_F462CD

LABEL_F46298:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F462B8
	bitda 2, 1057
	jr z, LABEL_F462B1
	calr LABEL_F46381
	cps hl, 0
	jrl z, AppEvent_ReturnZero
	lds32 xwa, 1
	jr LABEL_F462C0

LABEL_F462B1:
	resda 0, 10417
	jrl SeqAccomp_InitAndReturn

LABEL_F462B8:
	bitda 2, 1057
	jr z, LABEL_F462C6
	lds32 xwa, 0

LABEL_F462C0:
	calr AppEvent_SendVoiceUpdate
	jrl AppEvent_ReturnZero

LABEL_F462C6:
	setda 0, 10417
	ldw wa, 0x82

LABEL_F462CD:
	call UI_PostModeChangeEvent
	jr SeqAccomp_InitAndReturn

LABEL_F462D3:
	bitda 2, 1057
	jr nz, LABEL_F462E2
	ldda8 c, 10418
	bit 2, c
	jr z, LABEL_F4632D

LABEL_F462E2:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F462F0
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr LABEL_F462F5

LABEL_F462F0:
	lds32 xwa, 0
	ld (xsp + 2), xwa

LABEL_F462F5:
	ldda8 a, 36152
	cp a, 0x85
	jr nz, LABEL_F46306
	ld xwa, (xsp + 2)

LABEL_F46301:
	calr LABEL_F464A4
	jr AppEvent_ReturnZero

LABEL_F46306:
	cp a, 0x86
	jr nz, LABEL_F46313
	ld xwa, (xsp + 2)
	calr AppEvent_SendAccompStatus
	jr AppEvent_ReturnZero

LABEL_F46313:
	cp a, 0x87
	jr nz, LABEL_F46320
	ld xwa, (xsp + 2)
	calr LABEL_F464C4
	jr AppEvent_ReturnZero

LABEL_F46320:
	cp a, 0x88
	jr nz, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	calr LABEL_F464D4
	jr AppEvent_ReturnZero

LABEL_F4632D:
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F4633D
	res 0, c
	stda8 10418, c
	jr SeqAccomp_InitAndReturn

LABEL_F4633D:
	set 0, c
	stda8 10418, c
	cpdi8 36152, 133
	jr nz, SeqAccomp_InitAndReturn
	ldw wa, 0xAB
	call SoundCtrl_SendCommand

SeqAccomp_InitAndReturn:
	call SeqPlay_InitStartState
	jr AppEvent_ReturnZero

LABEL_F46358:
	call LABEL_F38A32
	cps hl, 0
	jr z, AppEvent_ReturnZero
	ld xwa, (xsp + 2)
	or xwa, xwa
	jr nz, LABEL_F4636E
	lds32 xwa, 1
	ld (xsp + 2), xwa
	jr LABEL_F46373

LABEL_F4636E:
	lds32 xwa, 0
	ld (xsp + 2), xwa

LABEL_F46373:
	ld xwa, (xsp + 2)
	extz wa

LABEL_F46378:
	calr AppEvent_SendModeToggle

AppEvent_ReturnZero:
	lds32 xhl, 0
	popw iz
	inc 4, xsp
	ret

LABEL_F46381:
	lda xsp, (xsp - 18)
	push xiz
	cpdi8 7530, 0
	jr z, LABEL_F46392
	ldw hl, 0xFFFF
	jrl LABEL_F4646B

LABEL_F46392:
	resda 0, 10417
	stdi8 8956, 3
	stdi8 7570, 0
	ldda16 xwa, 10420
	stda16 8982, xwa
	ldda8 a, 8988
	cp a, 0xFF
	jrl z, LABEL_F46469
	extz wa
	lda xhl, (xsp + 18)
	ld e, a
	dec 1, a
	extz wa
	ld (xsp + 4), wa
	sla wa, 2
	ldada xix, 9184
	st_dri3b A, 0x07, 0xF0, 0xE0
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xbc + 2)
	ld (xhl + 2), wa
	ld hl, (xhl)
	lda xbc, (xix + 76)
	ld (xbc), hl
	ld (xbc + 2), wa
	lda xbc, (xsp + 6)
	ldfr_berp E, 0xEA
	ld xix, xbc
	ldi_berp 0xE2, 0

LABEL_F463EB:
	ldto_berp E, 0xE2
	extz de
	inc 2, de
	ldto_berp A, 0xEA
	dec 1, a
	extz wa
	sla wa, 3
	ldada xhl, 9016
	st_dri3b E, 0x07, 0xEC, 0xE0
	ld iz, de
	extz xiz
	add xiz, xiy
	ldto_berp E, 0xE2
	extz de
	ld a, (xiz)
	lda_dri3 XBC, 0x07, 0xF0, 0xE8
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F463EB
	ld xix, xbc
	ldi_berp 0xE2, 0

LABEL_F46424:
	ldto_berp A, 0xE2
	extz wa
	inc 2, wa
	st_dri3b A, 0xED, 0x98, 0x00
	ld de, wa
	extz xde
	add xde, xbc
	ldto_berp A, 0xE2
	extz wa
	ld_srib3 A, 0x07, 0xF0, 0xE0
	ld (xde), a
	inc1_berp 0xE2
	cpi_berp 0xE2, 6
	jr c, LABEL_F46424
	lda xde, (xsp + 14)
	ld wa, (xsp + 4)
	sla wa, 3
	st_dri3b A, 0x07, 0xEC, 0xE0
	ld wa, (xbc)
	ld (xde), wa
	ld a, (xbc + 3)
	ld (xde + 2), a
	ld wa, (xde)
	st_dri3w WA, 0xED, 0x98, 0x00

LABEL_F46469:
	lds hl, 0

LABEL_F4646B:
	pop xiz
	lda xsp, (xsp + 18)
	ret

AppEvent_SendModeToggle:
	cps a, 0
	scc16 nz, de
	extz xde
	ld xwa, 0x87000E
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

AppEvent_SendVoiceUpdate:
	ld xde, xwa
	ld xwa, 0x810003
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

AppEvent_SendPlayStatus:
	ld xde, xwa
	ld xwa, 0x850004
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

LABEL_F464A4:
	ld xde, xwa
	ld xwa, 0x850006
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

AppEvent_SendAccompStatus:
	ld xde, xwa
	ld xwa, 0x860007
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

LABEL_F464C4:
	ld xde, xwa
	ld xwa, 0x87000D
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

LABEL_F464D4:
	ld xde, xwa
	ld xwa, 0x880004
	ld xbc, 0x1E0003B
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollReset:
	ldda8 c, 36152
	ldda32 xwa, 10610
	cp c, 0x99
	jr z, LABEL_F46557
	cp c, 0x96
	jr z, LABEL_F46557
	cp c, 0x7A
	jr z, LABEL_F4654E
	cp c, 0x78
	jr z, LABEL_F4654E
	extz bc
	sub bc, 0x81
	cps bc, 0
	ret lt
	cps bc, 7
	ret gt
	add bc, bc
	lda_24 xix, 0xe44a42
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xf46524
	jp_dri 8, 0x07, 0xF0, 0xE4

LABEL_F46524:
	ld xwa, 0x810005
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

LABEL_F46532:
	ld xwa, 0x850007
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

LABEL_F46540:
	ld xwa, 0x870003
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

LABEL_F4654E:
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr NoteEditSy_DeliverEvent

LABEL_F46557:
	ld xbc, 0x1C0000F
	lds32 xde, 3
	jr NoteEditSy_DeliverEvent

LABEL_F46560:
	ld xbc, 0x1C0000F
	lds32 xde, 7

NoteEditSy_DeliverEvent:
	call ApDeliveryEvent

LABEL_F4656B:
	ret

SeqMode_SendStatusUpdate:
	ldda8 a, 36152
	cp a, 0x87
	jr z, LABEL_F4659B
	cp a, 0x85
	jr z, LABEL_F4658D
	cp a, 0x81
	ret nz
	ld xwa, 0x810005
	ld xbc, 0x1C0000F
	lds32 xde, 1
	jr LABEL_F465A7

LABEL_F4658D:
	ld xwa, 0x850007
	ld xbc, 0x1C0000F
	lds32 xde, 1
	jr LABEL_F465A7

LABEL_F4659B:
	ld xwa, 0x870003
	ld xbc, 0x1C0000F
	lds32 xde, 1

LABEL_F465A7:
	call ApDeliveryEvent
	ret

SeqAccomp_SendStopNotify:
	ldda8 a, 36152
	cp a, 0x85
	jr z, LABEL_F465BA
	cp a, 0x87
	ret nz

LABEL_F465BA:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	call ApDeliveryEvent
	ret

SngSelSyori:
	push_werp 0xFA
	ld8_24 a, 0x00ffe3
	ldfr_berp A, 0xFB
	cp xbc, 0x1C00018
	jr z, LABEL_F46630
	cp xbc, 0x1C00017
	jr z, LABEL_F46600
	cp xbc, 0x1C0000B
	jr nz, SeqAcc_CheckLoopAndSendEvent
	stda32 10694, xde
	ld xwa, xde
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent
	jr SeqAcc_CheckLoopAndSendEvent

LABEL_F46600:
	bitda 2, 1057
	jr nz, SeqAcc_CheckLoopAndSendEvent
	cp_erpb 0xFB, 0x09
	jr nc, SeqAcc_CheckLoopAndSendEvent
	ldto_berp A, 0xFB
	stda8 7500, a
	ld8_24 a, 0x00ffe3
	inc 1, a
	stda8 7502, a
	call SetWall_LoadToneGenData
	cpdi8 36152, 129
	jr nz, SeqAcc_ResetAndReinit
	calr SeqVoice_DispatchAllEvents
	lds32 xwa, 0
	jr LABEL_F4665D

LABEL_F46630:
	bitda 2, 1057
	jr nz, SeqAcc_CheckLoopAndSendEvent
	cpi_berp 0xFB, 0
	jr z, SeqAcc_CheckLoopAndSendEvent
	ldto_berp A, 0xFB
	stda8 7500, a
	ld8_24 a, 0x00ffe3
	dec 1, a
	stda8 7502, a
	call SetWall_LoadToneGenData
	cpdi8 36152, 129
	jr nz, SeqAcc_ResetAndReinit
	calr SeqVoice_DispatchAllEvents
	lds32 xwa, 0

LABEL_F4665D:
	calr AppEvent_SendVoiceUpdate

SeqAcc_ResetAndReinit:
	resda 0, 10417
	resda 3, 10407
	call SeqAcc_InitPlaybackState

SeqAcc_CheckLoopAndSendEvent:
	ld8_24 a, 0x00ffe3
	cp_berp A, 0xFB
	jr z, LABEL_F46685
	ldda32 xwa, 10694
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call ApDeliveryEvent

LABEL_F46685:
	lds32 xhl, 0
	pop_werp 0xFA
	ret

SoundCtrl_SaveAndSendCmd_EE:
	stda8 32578, a
	ldw wa, 0xEE
	jp SoundCtrl_SendCommand

SoundCtrl_SendCmd_EE:
	ldw wa, 0xEE
	jp SoundCtrl_SendCommand

NoteEditSyori:
	cp xbc, 0x1C00018
	jrl z, NoteEditSy_HandleDownScroll
	cp xbc, 0x1C00017
	jr z, NoteEditSy_HandleUpScroll
	cp xbc, 0x1C0000B
	jrl nz, NoteEditSy_ReturnZero
	stda32 10610, xde
	bitda 0, 10050
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
	bitda 0, 10050
	call_24 z, 0xF468BD
	calr NoteEditSy_UpdateNoteDisplay
	bitda 0, 10591
	jrl z, NoteEditSy_ReturnZero
	call LABEL_F38728
	jrl NoteEditSy_ReturnZero

NoteEditSy_HandleUpScroll:
	cp xde, 0xE
	jrl ugt, NoteEditSy_ReturnZero
	add xde, xde
	add xde, 0xE44A6A
	ld de, (xde)
	lda_24 xix, 0xf4670f
	jp_dri 8, 0x07, 0xF0, 0xE8

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
	call LABEL_F375D7
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param7:
	call BmDrEdit_ChordScrollUp_Check
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param8:
	call LABEL_F37EDC
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param9:
	call LABEL_F37AA3
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param10:
	call BmDrEdit_InsertNoteEvent
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param11:
	call LABEL_F37A39
	jr NoteEditSy_ReturnZero

NoteEditSy_UpScroll_Param12:
	call LABEL_F37B09
	jr NoteEditSy_ReturnZero

NoteEditSy_HandleDownScroll:
	cp xde, 0xB
	jr ugt, NoteEditSy_ReturnZero
	add xde, xde
	add xde, 0xE44A52
	ld de, (xde)
	lda_24 xix, 0xf4677e
	jp_dri 8, 0x07, 0xF0, 0xE8

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
	call LABEL_F378D7
	jr NoteEditSy_ReturnZero

NoteEditSy_DownScroll_Param7:
	call BmDrEdit_ChordScrollDown_Check
	jr NoteEditSy_ReturnZero
	call LABEL_F37A4C

NoteEditSy_ReturnZero:
	lds32 xhl, 0
	ret

NoteEditSy_SendScrollCmd0:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd1:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 1
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd2:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 2
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd0:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	lds32 xde, 0
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd1:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	lds32 xde, 1
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd2:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	lds32 xde, 2
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmd3or4:
	lds32 xde, 3
	bitda 0, 10050
	jr z, NoteEditSy_SendWidgetCmdDispatch
	lds32 xde, 4

NoteEditSy_SendWidgetCmdDispatch:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	jp ApDeliveryEvent

NoteEditSy_UpdateGridPosition:
	dec 4, xsp
	push xiz
	ldda16 xbc, 10138
	srl bc, 2
	ld wa, bc
	stda16 10166, xbc
	bitda 0, 10050
	jr z, NoteEditSy_GridPosPlayOffset
	add wa, 0x53
	jr NoteEditSy_GridPosStore

NoteEditSy_GridPosPlayOffset:
	add wa, 0xF

NoteEditSy_GridPosStore:
	stda16 10166, xwa
	ldda16 xwa, 10415
	ldfr_werp WA, 0xFA
	ldda16 xiz, 9830
	ldmw2 (xsp + 4), 0x275E
	ldmi16 (xsp + 6), 0x2760
	call BmDrEdit_LoadAlternateAndCountNotes
	ldto_werp WA, 0xFA
	stda16 10415, xwa
	stda16 9830, xiz
	mrdw5 0x9F, 0x04, 0x19, 0x5E, 0x27
	mrdb5 0x8F, 0x06, 0x19, 0x60, 0x27
	ldda8 c, 10100
	extz bc
	ldda16 xwa, 10098
	cp wa, bc
	jr ugt, NoteEditSy_GridPosOutOfRange
	mul wa, 0x18
	bitda 0, 10050
	jr z, NoteEditSy_GridPosEdit
	add wa, 0x53
	stda16 10164, xwa
	jr NoteEditSy_GridPosFinish

NoteEditSy_GridPosEdit:
	add wa, 0xF
	stda16 10164, xwa
	jr NoteEditSy_GridPosFinish

NoteEditSy_GridPosOutOfRange:
	stdi16 10164, 0

NoteEditSy_GridPosFinish:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	lds32 xde, 5
	call ApDeliveryEvent
	pop xiz
	inc 4, xsp
	ret

NoteEditSy_UpdateEditModeGrid:
	bitda 0, 10050
	ret nz
	ldda16 xwa, 10138
	srl wa, 2
	add wa, 0x16
	stda16 10168, xwa
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	lds32 xde, 7
	jp ApDeliveryEvent

NoteEditSy_SendModeScrollCmd:
	ldda32 xwa, 10610
	bitda 0, 10050
	jr z, NoteEditSy_SendScrollCmdEdit
	ld xbc, 0x1C0000F
	ld xde, 0x9
	jr NoteEditSy_JumpFA9E07

NoteEditSy_SendScrollCmdEdit:
	ld xbc, 0x1C0000F
	lds32 xde, 6

NoteEditSy_JumpFA9E07:
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd3:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 3
	jp ApDeliveryEvent

NoteEditSy_SendVelocityCmd:
	ldmm8 10602, 10122
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0xA
	jp ApDeliveryEvent

NoteEditSy_SendGateCmd:
	ldmm8 10602, 10120
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 4
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd5:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	lds32 xde, 5
	jp ApDeliveryEvent

NoteEditSy_SendScrollCmd8:
	ldda32 xwa, 10610
	ld xbc, 0x1C0000F
	ld xde, 0x8
	jp ApDeliveryEvent

NoteEditSy_SendModeWidgetCmd:
	ldda32 xwa, 10610
	bitda 0, 10050
	jr z, NoteEditSy_WidgetCmdEdit
	ld xbc, 0x1C80004
	ld xde, 0xD
	jr NoteEditSy_JumpFA9E07_2

NoteEditSy_WidgetCmdEdit:
	ld xbc, 0x1C80004
	ld xde, 0x8

NoteEditSy_JumpFA9E07_2:
	jp ApDeliveryEvent

NoteEditSy_UpdateNoteDisplay:
	dec 4, xsp
	ldmm16 10238, 10090
	ldda8 a, 10092
	extz wa
	stda16 10240, xwa
	ldmm16 10242, 10094
	ldda8 a, 10096
	extz wa
	stda16 10244, xwa
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call BmDrEdit_SetupScrollRegion
	mrdb5 0x8F, 0x02, 0x19, 0x22, 0x28
	mrib4 0x87, 0x19, 0x24, 0x28
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	ld xde, 0x9
	call ApDeliveryEvent
	inc 4, xsp
	ret

NoteEditSy_SendWidgetCmdC:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	ld xde, 0xC
	jp ApDeliveryEvent
NoteEditSy_DisplayUpdateData:
	.byte 0xef, 0x6c, 0xd1, 0x6a, 0x27, 0x19, 0xfe, 0x27
	.byte 0xc1, 0x6c, 0x27, 0x21, 0xd8, 0x12, 0xf1, 0x00
	.byte 0x28, 0x50, 0xd1, 0x6e, 0x27, 0x19, 0x02, 0x28
	.byte 0xc1, 0x70, 0x27, 0x21, 0xd8, 0x12, 0xf1, 0x04
	.byte 0x28, 0x50, 0xbf, 0x02, 0x30, 0xb7, 0x31, 0x1d
	.byte 0xf2, 0x6e, 0xf3, 0x8f, 0x02, 0x19, 0x22, 0x28
	.byte 0x87, 0x19, 0x24, 0x28, 0xe1, 0x72, 0x29, 0x20
	.byte 0x41, 0x04, 0x00, 0xc8, 0x01, 0x42, 0x0a, 0x00
	.byte 0x00, 0x00, 0x1d, 0x07, 0x9e, 0xfa, 0xef, 0x64
	.byte 0x0e

NoteEditSy_UpdateChordDisplay:
	bitda 0, 10050
	jr z, NoteEditSy_ChordDisplayEdit
	call BmDrEdit_CalcTrackPosition
	jp BmDrEdit_SendWidgetCmd

NoteEditSy_ChordDisplayEdit:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	ld xde, 0xB
	jp ApDeliveryEvent

NoteEditSy_SendWidgetCmdE:
	ldda32 xwa, 10610
	ld xbc, 0x1C80004
	ld xde, 0xE
	jp ApDeliveryEvent

SeqModeFunc:
	cp xbc, 0x1C00013
	jr nz, SeqErecMode_ReturnZero
	cp xde, 0x1
	jr z, LABEL_F46A7D
	or xde, xde
	jr nz, SeqErecMode_ReturnZero
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	resda 5, 10419
	calr LABEL_F47807
	jr SeqErecMode_ReturnZero

LABEL_F46A7D:
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	resda 2, 10407
	resda 0, 9834
	resda 4, 10413

SeqErecMode_ReturnZero:
	lds32 xhl, 0
	ret

SeqErecModeFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46AB3
	cp xde, 0x1
	jr z, LABEL_F46AAC
	or xde, xde
	jr nz, LABEL_F46AB3
	ldw wa, 0x4C
	jr LABEL_F46AAF

LABEL_F46AAC:
	ldw wa, 0x4C

LABEL_F46AAF:
	call CtrlPanel_SetIndicatorBit

LABEL_F46AB3:
	lds32 xhl, 0
	ret

SeqPlayModeFunc:
	cp xbc, 0x1C00013
	jr nz, SeqPlayMode_ReturnZero
	cp xde, 0x1
	jr z, LABEL_F46AE3
	or xde, xde
	jr nz, SeqPlayMode_ReturnZero
	call Accomp_UpdateModeFlag
	stdi8 58254, 0
	resda 0, 9834
	bitda 2, 1057
	jr nz, SeqPlayMode_ReturnZero
	call AccWrap_PlayModeDispatch
	jr SeqPlayMode_ReturnZero

LABEL_F46AE3:
	call SeqPlay_SaveStateAndCleanup
	stdi8 58254, 0

SeqPlayMode_ReturnZero:
	lds32 xhl, 0
	ret

SeqRealModeFunc:
	pushw iz
	cp xbc, 0x1C00013
	jrl nz, SeqAcc_ProcessedReturn
	cp xde, 0x1
	jr z, LABEL_F46B39
	or xde, xde
	jrl nz, SeqAcc_ProcessedReturn
	call AccWrap_PlayModeDispatch
	call Accomp_UpdateModeFlag
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	call SeqBuffer_ClearAndInitIteration
	stdi8 10430, 255
	bitda 1, 10417
	jr nz, LABEL_F46B2C
	stdi16 9832, 1
	jr LABEL_F46B32

LABEL_F46B2C:
	ldmm16 9832, 9504

LABEL_F46B32:
	call SeqPlay_InitStartState
	jrl SeqAcc_ProcessedReturn

LABEL_F46B39:
	call PartSelect_UpdateDisplayState
	call SeqPlay_ProcessVoiceAndNotes
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	call SeqPlay_SaveStateAndCleanup
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	stdi8 9980, 0
	resda 0, 9954
	ldda8 a, 10417
	bit 0, a
	jr z, LABEL_F46BA9
	call AccWrap_DispatchAndWaitSync
	ldda16 xwa, 9500
	stda16 9832, xwa
	ldda16 xwa, 9500
	call SeqBuf_AllocNextSlot
	stda16 9000, xhl
	stda16 1052, xhl
	stdi8 1051, 0
	ldda16 xwa, 9502
	call SeqBuf_AllocNextSlotAdjusted
	stda16 9002, xhl
	cpdi16 9832, 1
	jr nz, LABEL_F46BA3
	resda 3, 10407
	jr SeqAcc_SaveChannelAndReinit

LABEL_F46BA3:
	setda 3, 10407
	jr SeqAcc_SaveChannelAndReinit

LABEL_F46BA9:
	bit 1, a
	jr z, SeqAcc_ProcessedReturn
	resda 3, 10407

SeqAcc_SaveChannelAndReinit:
	ldda16 xiz, 61854
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	call SeqAcc_InitPlaybackState
	stda16 61854, xiz

SeqAcc_ProcessedReturn:
	lds32 xhl, 0
	popw iz
	ret

SeqEditModeFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46BEF
	cp xde, 0x1
	jr z, LABEL_F46BE7
	or xde, xde
	jr nz, LABEL_F46BEF
	call SeqAcc_SetIndicator_PB
	setda 2, 10407
	jr LABEL_F46BEF

LABEL_F46BE7:
	call SeqAcc_RestorePlaybackState
	resda 2, 10407

LABEL_F46BEF:
	lds32 xhl, 0
	ret

SqRealRecTitleFunc:
	push_werp 0xFA
	cp xbc, 0x1C00013
	jrl nz, SqRealRec_ReturnZero
	cp xde, 0x3
	jr z, LABEL_F46C7C
	cp xde, 0x2
	jr nz, SqRealRec_ReturnZero
	cpdi8 36153, 131
	jr nz, SqRealRec_ReturnZero
	cpdi8 9980, 1
	jr nz, SqRealRec_ReturnZero
	stdi8 9508, 1
	stdi16 10408, 0
	call Audio_CheckSubsystemReady
	ldi_berp 0xFB, 1

LABEL_F46C2E:
	ldto_berp A, 0xFB
	extz wa
	lds bc, 1
	call SeqVoice_SetOrClearBitMask
	inc1_berp 0xFB
	cpi_berp 0xFB, 5
	jr ule, LABEL_F46C2E
	lds wa, 0
	ldw bc, 0xD
	call Part_FindVoiceByByte
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 5
	jr ugt, LABEL_F46C69
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	ldw de, 0xE
	call Part_WriteSubBlock32
	ldto_berp A, 0xFB
	dec 1, a
	stda8 10430, a

LABEL_F46C69:
	call Part_DetectSingleVoiceType
	call Audio_CheckSubsystemReady
	call SeqPlay_InitializePlayback
	stdi8 9508, 0
	jr SqRealRec_ReturnZero

LABEL_F46C7C:
	cpdi8 36148, 10
	jr z, SqRealRec_ReturnZero
	resda 0, 36232

SqRealRec_ReturnZero:
	lds32 xhl, 0
	pop_werp 0xFA
	ret

SqPlayTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqPlay_ReturnZero
	cp xde, 0x3
	jr z, LABEL_F46CCA
	cp xde, 0x2
	jr nz, SqPlay_ReturnZero
	bitda 0, 10417
	jr z, SqPlay_ReturnZero
	bitda 2, 1057
	jr nz, SqPlay_ReturnZero
	cpdi8 36153, 130
	jr z, SqPlay_ReturnZero
	ldmm16 9832, 9500
	call SeqPlay_InitStartState
	ldmm16 10296, 61854
	jr SqPlay_ReturnZero

LABEL_F46CCA:
	cpdi8 36148, 1
	jr z, SqPlay_ReturnZero
	resda 0, 36232

SqPlay_ReturnZero:
	lds32 xhl, 0
	ret

SqQtzTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqQtzTtl_ReturnZero
	cp xde, 0x3
	jr z, SqQtzTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqQtzTtl_ReturnZero
	cpdi8 61937, 17
	jr nz, LABEL_F46CFD
	setda 4, 9702
	jr SqQtzTtl_ReturnZero

LABEL_F46CFD:
	resda 4, 9702

SqQtzTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMdelTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqMdelTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMdelTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMdelTtl_ReturnZero
	cpdi8 61910, 17
	jr nz, LABEL_F46D29
	setda 0, 9702
	jr SqMdelTtl_ReturnZero

LABEL_F46D29:
	resda 0, 9702

SqMdelTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMersTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqMersTtl_ReturnZero
	cp xde, 0x3
	jr z, SqMersTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqMersTtl_ReturnZero
	cpdi8 61915, 17
	jr nz, LABEL_F46D55
	setda 1, 9702
	jr SqMersTtl_ReturnZero

LABEL_F46D55:
	resda 1, 9702

SqMersTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqVcngTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqVcngTtl_ReturnZero
	cp xde, 0x3
	jr z, SqVcngTtl_ReturnZero
	cp xde, 0x2
	jr nz, SqVcngTtl_ReturnZero
	cpdi8 61992, 17
	jr nz, LABEL_F46D81
	setda 5, 9702
	jr SqVcngTtl_ReturnZero

LABEL_F46D81:
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
	cp xbc, 0x1C00013
	jr nz, SqMcpy_ReturnZero
	cp xde, 0x3
	jr z, SqMcpy_ReturnZero
	cp xde, 0x2
	jr nz, SqMcpy_ReturnZero
	ldmm_sd24b 0xE3, 0xFF, 0x00, 0x78, 0x28

SqMcpy_ReturnZero:
	lds32 xhl, 0
	ret

SqMcpyTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqMcpyTtl_ReturnZero
	cp xde, 0x3
	jr z, LABEL_F46DDB
	cp xde, 0x2
	jr nz, SqMcpyTtl_ReturnZero
	cpdi8 61929, 17
	jr nz, LABEL_F46DD5
	setda 3, 9702
	jr SqMcpyTtl_ReturnZero

LABEL_F46DD5:
	resda 3, 9702
	jr SqMcpyTtl_ReturnZero

LABEL_F46DDB:
	ldda16 xwa, 10357
	ordm16_24 65516, xwa

SqMcpyTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqMinsTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqMinsTtl_ReturnZero
	cp xde, 0x3
	jr z, LABEL_F46E12
	cp xde, 0x2
	jr nz, SqMinsTtl_ReturnZero
	cpdi8 61921, 17
	jr nz, LABEL_F46E0C
	setda 2, 9702
	jr SqMinsTtl_ReturnZero

LABEL_F46E0C:
	resda 2, 9702
	jr SqMinsTtl_ReturnZero

LABEL_F46E12:
	ldmmw_dd24 0xEC, 0xFF, 0x00, 0x75, 0x28

SqMinsTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqTrclTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqSngcp_ReturnZero
	cp xde, 0x3
	jr z, LABEL_F46E3C
	cp xde, 0x2
	jr nz, SqSngcp_ReturnZero
	stdi16 9704, 0
	jr SqSngcp_ReturnZero

LABEL_F46E3C:
	ldda16 xwa, 10040
	cpl wa
	anddm16_24 65516, xwa

SqSngcp_ReturnZero:
	lds32 xhl, 0
	ret

SqSngcpTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqRepeat_HandleReturn
	cp xde, 0x3
	jr z, SqRepeat_HandleReturn
	cp xde, 0x2
	jr nz, SqRepeat_HandleReturn
	stdi8 9992, 1
	stdi8 9994, 1
	stdi8 9996, 1
	stdi8 9998, 1

SqRepeat_HandleReturn:
	lds32 xhl, 0
	ret

SqTrmgTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46E92
	cp xde, 0x3
	jr nz, LABEL_F46E92
	ldda16 xwa, 10357
	ordm16_24 65516, xwa

LABEL_F46E92:
	lds32 xhl, 0
	ret

SqAdlyTitleFunc:
	lds32 xhl, 0
	ret

SqPunchTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqPunch_HandleReturn
	cp xde, 0x3
	jr z, LABEL_F46EB6
	cp xde, 0x2
	jr nz, SqPunch_HandleReturn
	call LABEL_F3890C
	jr SqPunch_HandleReturn

LABEL_F46EB6:
	call SeqAcc_HandlePlaybackTick

SqPunch_HandleReturn:
	lds32 xhl, 0
	ret

SqPunchmTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqPunchm_HandleReturn
	cp xde, 0x3
	jr z, LABEL_F46EDB
	cp xde, 0x2
	jr nz, SqPunchm_HandleReturn
	call LABEL_F38956
	jr SqPunchm_HandleReturn

LABEL_F46EDB:
	call LABEL_F389AD

SqPunchm_HandleReturn:
	lds32 xhl, 0
	ret

SqNoteSelTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqNoteSel_HandleReturn
	cp xde, 0x3
	jr z, SqNoteSel_HandleReturn
	cp xde, 0x2
	jr nz, SqNoteSel_HandleReturn
	resda 0, 10050

SqNoteSel_HandleReturn:
	lds32 xhl, 0
	ret

SqNoteEdtTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46F14
	cp xde, 0x3
	call_24 z, 0xF37156

LABEL_F46F14:
	lds32 xhl, 0
	ret

SqDrmSelTitleFunc:
	cp xbc, 0x1C00013
	jr nz, SqDrmSel_HandleReturn
	cp xde, 0x3
	jr z, SqDrmSel_HandleReturn
	cp xde, 0x2
	jr nz, SqDrmSel_HandleReturn
	resda 0, 10587
	setda 0, 10050

SqDrmSel_HandleReturn:
	lds32 xhl, 0
	ret

SqDrmEdtTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46F4D
	cp xde, 0x3
	call_24 z, 0xF37134

LABEL_F46F4D:
	lds32 xhl, 0
	ret

SdRevsetTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46F6D
	cp xde, 0x3
	jr z, LABEL_F46F68
	cp xde, 0x2
	jr nz, LABEL_F46F6D

LABEL_F46F68:
	stdi8 58252, 0

LABEL_F46F6D:
	lds32 xhl, 0
	ret

SdDspeffTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46F8D
	cp xde, 0x3
	jr z, LABEL_F46F88
	cp xde, 0x2
	jr nz, LABEL_F46F8D

LABEL_F46F88:
	stdi8 58252, 0

LABEL_F46F8D:
	lds32 xhl, 0
	ret

SdAccillTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46FAD
	cp xde, 0x3
	jr z, LABEL_F46FA8
	cp xde, 0x2
	jr nz, LABEL_F46FAD

LABEL_F46FA8:
	stdi8 58252, 0

LABEL_F46FAD:
	lds32 xhl, 0
	ret

SqNoteCycpTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46FC3
	cp xde, 0x3
	call_24 z, 0xF3884C

LABEL_F46FC3:
	lds32 xhl, 0
	ret

SqDrmCycpTitleFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46FD9
	cp xde, 0x3
	call_24 z, 0xF3884C

LABEL_F46FD9:
	lds32 xhl, 0
	ret

HelpModeFunc:
	cp xbc, 0x1C00013
	jr nz, LABEL_F46FF3
	cp xde, 0x1
	jr z, LABEL_F46FF3
	or xde, xde
	call_24 z, 0xF59AB9

LABEL_F46FF3:
	lds32 xhl, 0
	ret

HelpTitleFunc:
	lds32 xhl, 0
	ret

EtmenuTitleFunc:
	cp xbc, 0x1C00013
	jrl nz, EtmenuTtl_ReturnZero
	cp xde, 0x7
	jrl z, LABEL_F4709C
	cp xde, 0x3
	jrl z, LABEL_F47097
	cp xde, 0x2
	jrl nz, EtmenuTtl_ReturnZero
	stdi8 58252, 0
	cpdi8 36148, 7
	jr nz, EtmenuTtl_ReturnZero
	ld xwa, 0xD60003
	lds bc, 1
	call SetVisible
	ld xwa, 0xD60004
	lds bc, 1
	call SetVisible
	ld xwa, 0xD60005
	lds bc, 1
	call SetVisible
	ld xwa, 0xD60006
	lds bc, 1
	call SetVisible
	ld xwa, 0xD60003
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xD60004
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xD60005
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call ApDeliveryEvent
	ld xwa, 0xD60006
	ld xbc, 0x1C0000D
	lds32 xde, 0
	call ApDeliveryEvent
	jr EtmenuTtl_ReturnZero

LABEL_F47097:
	stdi8 58252, 0

LABEL_F4709C:
	lds wa, 0
	calr VoiceParam_SetD6Group

EtmenuTtl_ReturnZero:
	lds32 xhl, 0
	ret

MainExeCall:
	ldda8 a, 36152
	cp a, 0x91
	jrl z, MainExe_Handle91
	cp a, 0x8D
	jrl z, MainExe_Handle8D
	cp a, 0x90
	jrl z, MainExe_Handle90
	cp a, 0x86
	jrl z, MainExe_Handle86
	cp a, 0x85
	jr z, MainExe_Handle85
	cp a, 0x83
	jr z, MainExe_Handle83
	cp a, 0xD6
	jr z, MainExe_HandleD6
	extz wa
	sub wa, 0x9A
	cps wa, 0
	jrl lt, MainExe_ReturnZero
	cp wa, 0x10
	jrl gt, MainExe_ReturnZero
	add wa, wa
	lda_24 xix, 0xe44a88
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf470f7
	jp_dri 8, 0x07, 0xF0, 0xE0

MainExe_HandleD6:
	call NoteMap_ProcessAndMerge
	call MIDI_BroadcastControlChange
	call SeqData_SendVoiceTableBlock
	jrl MainExe_ReturnZero

MainExe_Handle83:
	calr MainExe_SequencerStop
	jrl MainExe_ReturnZero

MainExe_Handle85:
	and e, 0xF
	cp e, 0xA
	jr nz, MainExe_Handle85_SubE9
	ldda8 a, 1057
	and a, 0x14
	jrl z, MainExe_ReturnZero
	cpdi16 10408, 0
	jrl z, MainExe_ReturnZero
	setda 1, 9834
	call SeqPlay_ProcessVoiceAndNotes
	jrl MainExe_ReturnZero

MainExe_Handle85_SubE9:
	cp e, 0x9
	jrl nz, MainExe_ReturnZero
	bitda 1, 10417
	jrl z, MainExe_ReturnZero
	bitda 2, 10418
	jr z, MainExe_StartSongPlay
	bitda 2, 1057
	jr nz, MainExe_StartSongPlay
	jrl MainExe_ReturnZero

MainExe_Handle86:
	bitda 1, 10417
	jrl z, MainExe_ReturnZero
	bitda 2, 10418
	jr z, MainExe_StartSongPlay
	bitda 2, 1057
	jrl z, MainExe_ReturnZero

MainExe_StartSongPlay:
	call LABEL_F3D7DF
	jrl MainExe_ReturnZero

MainExe_Handle90:
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqVoice_InitEntry
	call LABEL_F419B6
	ld8_24 a, 0x00ffe3
	cpda8 a, 10360
	jr nz, MainExe_Handle90_Finish
	stdi16 10357, 0
	sti16_24 0x00ffec, 0x0000

MainExe_Handle90_Finish:
	ldw wa, 0x23
	calr SoundCtrl_SaveAndSendCmd_EE
	resda 0, 36232
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
	cpdi16 9704, 0
	jr nz, MainExe_SongMemStart
	ldw wa, 0x9A
	jrl MainExe_CallModeSwitch

MainExe_SongMemStart:
	stdi8 10359, 1

MainExe_SongMemIterLoop:
	ldda8 a, 10359
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_SongMemShiftMask
	slaa bc

MainExe_SongMemShiftMask:
	andda16 xbc, 9704
	jr z, MainExe_SongMemNextPart
	stdi8 32578, 255
	stdi8 10362, 0
	call LABEL_F49B2F

MainExe_SongMemNextPart:
	ldda8 a, 10359
	inc 1, a
	stda8 10359, a
	cp a, 0x10
	jr ule, MainExe_SongMemIterLoop
	ldda16 xwa, 9704
	ldda16 xbc, 10357
	and wa, bc
	cpl wa
	and bc, wa
	stda16 10357, xbc
	ldmm16 10040, 9704
	stdi16 9704, 0
	ldw wa, 0x23

MainExe_CallSongHandler:
	calr SoundCtrl_SaveAndSendCmd_EE
	jrl MainExe_ReturnZero
	ldmm8 10359, 61907
	ldmm8 9858, 61908
	ldmm8 9860, 61909
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_Compare
	ldda8 a, 10359
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_ClearPartMask1
	slaa bc

MainExe_ClearPartMask1:
	cpl bc
	anddm16 10357, xbc
	ldda8 a, 10359
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_ClearPartMask2
	slaa bc

MainExe_ClearPartMask2:
	cpl bc
	anddm16_24 65516, xbc
	ldda8 a, 9858
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_ClearPartMask3
	slaa bc

MainExe_ClearPartMask3:
	cpl bc
	anddm16 10357, xbc
	ldda8 a, 9858
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_ClearPartMask4
	slaa bc

MainExe_ClearPartMask4:
	cpl bc
	anddm16_24 65516, xbc
	ldda8 a, 9860
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_SetPartMask
	slaa bc

MainExe_SetPartMask:
	orddm16 10357, xbc
	ldda8 a, 9860
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_SetPartMaskFFE0
	slaa bc

MainExe_SetPartMaskFFE0:
	ordm16_24 65516, xbc
	ldda8 a, 32578
	cp a, 0xFF
	jr nz, MainExe_CheckResultCode
	ldw wa, 0x9B
	jrl MainExe_CallModeSwitch

MainExe_CheckResultCode:
	cp a, 0x23
	jrl z, MainExe_SongMemoryLoop
	ldda8 a, 10359
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_CalcRemainingMask
	slaa bc

MainExe_CalcRemainingMask:
	cpl bc
	ld wa, bc
	ldda16 xbc, 10357
	and bc, wa
	ldda8 a, 9858
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, MainExe_MaskSecondary
	slaa de

MainExe_MaskSecondary:
	cpl de
	and bc, de
	ldda8 a, 9860
	dec 1, a
	lds de, 1
	and a, 0xF
	jr z, MainExe_MaskTertiary
	slaa de

MainExe_MaskTertiary:
	cpl de
	and bc, de
	stda16 10357, xbc
	jrl MainExe_SongMemoryLoop
	ldda8 a, 61937
	cp a, 0x11
	jr nz, MainExe_StorePartDirect
	stdi8 10359, 127
	jr MainExe_PatternLoad

MainExe_StorePartDirect:
	stda8 10359, a

MainExe_PatternLoad:
	ldda16 xwa, 61938
	stda16 9778, xwa
	ldda16 xwa, 9724
	subda16 xwa, 61938
	inc 1, wa
	stda16 9694, xwa
	ldda8 a, 61942
	sll a, 1
	stda8 9726, a
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_VelocityEditSetup
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9C
	jrl MainExe_CallModeSwitch
	ldmm8 10359, 9756
	ldda16 xwa, 9758
	stda16 9778, xwa
	ldda16 xwa, 9760
	subda16 xwa, 9758
	inc 1, wa
	stda16 9694, xwa
	call SeqPart_PartSelect
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9D
	jrl MainExe_CallModeSwitch
	ldda8 a, 61992
	cp a, 0x11
	jr nz, MainExe_RhythmStorePartDirect
	stdi8 10359, 127
	jr MainExe_RhythmLoad

MainExe_RhythmStorePartDirect:
	stda8 10359, a

MainExe_RhythmLoad:
	ldda16 xwa, 61993
	stda16 9778, xwa
	ldda16 xwa, 9722
	subda16 xwa, 61993
	inc 1, wa
	stda16 9694, xwa
	ldmm8 9812, 61998
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_TransposeSetup
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9E
	jrl MainExe_CallModeSwitch
	ldmm8 10359, 9742
	ldda16 xwa, 9744
	stda16 9778, xwa
	ldda16 xwa, 9746
	subda16 xwa, 9744
	inc 1, wa
	stda16 9694, xwa
	call SeqPart_PartVoiceCheck
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0x9F
	jrl MainExe_CallModeSwitch
	ldmm8 10359, 9732
	ldda16 xwa, 9734
	stda16 9778, xwa
	ldda16 xwa, 9736
	subda16 xwa, 9734
	inc 1, wa
	stda16 9694, xwa
	call SeqPart_VoiceCheckModeB
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0xA0
	jrl MainExe_CallModeSwitch
	ldda8 a, 61915
	cp a, 0x11
	jr nz, MainExe_AccompStorePartDirect
	stdi8 10359, 127
	jr MainExe_AccompLoad

MainExe_AccompStorePartDirect:
	stda8 10359, a

MainExe_AccompLoad:
	ldda16 xwa, 61916
	stda16 9778, xwa
	ldda16 xwa, 9766
	subda16 xwa, 61916
	inc 1, wa
	stda16 9694, xwa
	ldmm8 9808, 61920
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_SinglePartLoad
	cpdi8 32578, 255
	jrl nz, MainExe_SongMemoryLoop
	ldw wa, 0xA1
	jrl MainExe_CallModeSwitch
	ldda16 xwa, 61930
	stda16 9778, xwa
	ldmm16 9862, 61935
	ldda16 xwa, 9768
	subda16 xwa, 61930
	inc 1, wa
	stda16 9694, xwa
	ldmm8 9858, 61934
	ldda8 a, 61929
	cp a, 0x11
	jr nz, MainExe_SongLoadStorePartDirect
	stdi8 10359, 127
	jr MainExe_SongLoad

MainExe_SongLoadStorePartDirect:
	stda8 10359, a

MainExe_SongLoad:
	stdi8 32578, 255
	stdi8 10362, 0
	call SeqPart_DualPartLoad
	ldda8 a, 32578
	cp a, 0xFF
	jr nz, MainExe_SongLoadCheckRedirect
	ldw wa, 0xA2
	jrl MainExe_CallModeSwitch

MainExe_SongLoadCheckRedirect:
	cp a, 0x23
	jr nz, MainExe_SongLoadFinish
	call LABEL_F3FD60
	cpdi8 32578, 255
	jr nz, MainExe_SongLoadFinish
	ldw wa, 0xA2
	jrl MainExe_CallModeSwitch

MainExe_SongLoadFinish:
	calr SoundCtrl_SendCmd_EE
	cpdi8 32578, 35
	jr z, MainExe_ReturnZero
	cpdi8 10359, 127
	jrl z, MainExe_SetAllPartsMask

MainExe_SetPartBitMask:
	ldda8 a, 9858
	dec 1, a
	lds bc, 1
	and a, 0xF
	jr z, MainExe_OrPartMask
	slaa bc

MainExe_OrPartMask:
	orddm16 10357, xbc

MainExe_ReturnZero:
	lds32 xhl, 0
	ret

MainExe_InlineByteData:
	.byte 0xc1, 0xd6, 0xf1, 0x21, 0xc9, 0xcf, 0x11, 0x6e
	.byte 0x07, 0xf1, 0x77, 0x28, 0x00, 0x7f, 0x68, 0x04
	.byte 0xf1, 0x77, 0x28, 0x41, 0xd1, 0xd7, 0xf1, 0x20
	.byte 0xf1, 0x32, 0x26, 0x50, 0xd1, 0x2c, 0x26, 0x20
	.byte 0xd1, 0xd7, 0xf1, 0xa0, 0xd8, 0x61, 0xf1, 0xde
	.byte 0x25, 0x50, 0xf1, 0x42, 0x7f, 0x00, 0xff, 0xf1
	.byte 0x7a, 0x28, 0x00, 0x00, 0x1d, 0x07, 0xa2, 0xf4
	.byte 0xc1, 0x42, 0x7f, 0x3f, 0xff, 0x7e, 0x52, 0xfc
	.byte 0x30, 0xa3, 0x00, 0x68, 0x65, 0xd1, 0xe2, 0xf1
	.byte 0x20, 0xf1, 0x32, 0x26, 0x50, 0xd1, 0xe7, 0xf1
	.byte 0x19, 0x86, 0x26, 0xd1, 0x2e, 0x26, 0x20, 0xd1
	.byte 0xe2, 0xf1, 0xa0, 0xd8, 0x61, 0xf1, 0xde, 0x25
	.byte 0x50, 0xc1, 0xe6, 0xf1, 0x19, 0x82, 0x26, 0xc1
	.byte 0xe1, 0xf1, 0x21, 0xc9, 0xcf, 0x11, 0x6e, 0x07
	.byte 0xf1, 0x77, 0x28, 0x00, 0x7f, 0x68, 0x04, 0xf1
	.byte 0x77, 0x28, 0x41, 0xf1, 0x42, 0x7f, 0x00, 0xff
	.byte 0xf1, 0x7a, 0x28, 0x00, 0x00, 0x1d, 0x5a, 0xa9
	.byte 0xf4, 0xc1, 0x42, 0x7f, 0x21, 0xc9, 0xcf, 0xff
	.byte 0x6e, 0x05, 0x30, 0xa4, 0x00, 0x68, 0x13, 0xc9
	.byte 0xcf, 0x23, 0x6e, 0x15, 0x1d, 0xd6, 0xfd, 0xf3
	.byte 0xc1, 0x42, 0x7f, 0x3f, 0xff, 0x6e, 0x0a, 0x30
	.byte 0xa4, 0x00

MainExe_CallModeSwitch:
	call UI_PostModeChangeEvent
	jrl MainExe_ReturnZero
	calr SoundCtrl_SendCmd_EE
	cpdi8 32578, 35
	jrl z, MainExe_ReturnZero
	cpdi8 10359, 127
	jrl nz, MainExe_SetPartBitMask

MainExe_SetAllPartsMask:
	stdi16 10357, 65535
	jrl MainExe_ReturnZero

MainExe_SequencerStop:
	stdi8 7572, 0
	call SeqPlay_SaveStateAndCleanup
	ldw wa, 0x4C
	call CtrlPanel_SetIndicatorBit
	resda 1, 10417
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
	lds wa, 0
	ldw bc, 0x50
	ldw de, 0xFFFF
	call Part_WriteWord
	lds wa, 0
	ldw bc, 0x32
	call Part_ReleaseVoicesForRange
	stdi16 61854, 0
	call Audio_CheckSubsystemReady
	call AccWrap_PositionClear
	resda 0, 10406
	sti16_24 0x00ffec, 0x0000
	stdi8 9980, 1
	call Part_DetectSingleVoiceType
	ldw wa, 0xB
	jp UI_PostPartChangeEvent

MainPanic:
	cp xbc, 0x1E80076
	jr nz, LABEL_F47664
	call NoteMap_ProcessAndMerge
	call MIDI_BroadcastControlChange
	call SeqData_SendVoiceTableBlock

LABEL_F47664:
	lds32 xhl, 0
	ret

LABEL_F47667:
	.byte 0xc1, 0x7d, 0xc0, 0x21, 0xc9, 0xcf, 0x13, 0xb0
	.byte 0xfe, 0xc1, 0x7e, 0xc0, 0x21, 0xf1, 0x6e, 0x29
	.byte 0x41, 0xc1, 0x70, 0x29, 0xf1, 0xb0, 0xf6, 0xc9
	.byte 0xcf, 0x31, 0xb0, 0xfb, 0xf1, 0x70, 0x29, 0x41
	.byte 0xc1, 0x38, 0x8d, 0x3f, 0xe7, 0xb0, 0xfe, 0xc2
	.byte 0xe4, 0x40, 0x03, 0x25, 0xc1, 0x6e, 0x29, 0x23
	.byte 0xd9, 0x12, 0xcd, 0xdd, 0x66, 0x21, 0xcd, 0xdb
	.byte 0x66, 0x16, 0xcd, 0xda, 0x66, 0x0b, 0xcd, 0xd9
	.byte 0x6e, 0x1c, 0x40, 0xdc, 0x4a, 0xe4, 0x00, 0x68
	.byte 0x1a, 0x40, 0x0e, 0x4b, 0xe4, 0x00, 0x68, 0x13
	.byte 0x40, 0x40, 0x4b, 0xe4, 0x00, 0x68, 0x0c, 0x40
	.long LABEL_E44B72
	.byte 0x68, 0x05, 0x40, 0xaa
	.byte 0x4a, 0xe4, 0x00, 0xc3, 0x07, 0xe0, 0xe4, 0x21
	.byte 0xc9, 0xd9, 0x6e, 0x1e, 0x40, 0x0e, 0x00, 0xe7
	.byte 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x1d, 0x58, 0x9d, 0xfa, 0x40, 0x10, 0x00, 0xe7
	.byte 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x68, 0x60, 0xc9, 0xda, 0x6e, 0x1e, 0x40, 0x17
	.byte 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0x40, 0x19
	.byte 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x68, 0x3e, 0xc9, 0xdb, 0x6e, 0x1e
	.byte 0x40, 0x24, 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x58, 0x9d, 0xfa
	.byte 0x40, 0x26, 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00
	.byte 0xc0, 0x01, 0xea, 0xa8, 0x68, 0x1c, 0x40, 0x2c
	.byte 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0x40, 0x2f
	.byte 0x00, 0xe7, 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0x0e

HelpLangChkMain:
	cp xbc, 0x1E80070
	jr z, LABEL_F477BA
	cp xbc, 0x1C00001
	jr nz, LABEL_F477D7
	cpdi8 36152, 231
	jr nz, HelpLang_SetFlashAndLoadSlide
	cpdi8 36153, 238
	jr z, HelpLang_SetFlashAndLoadSlide
	call Get_Region_Code
	cps l, 3
	jr nz, LABEL_F4778A
	ld xwa, 0xE7000A
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr LABEL_F47796

LABEL_F4778A:
	ld xwa, 0xE70005
	ld xbc, 0x1C00001
	lds32 xde, 0

LABEL_F47796:
	call ApPostEvent

HelpLang_SetFlashAndLoadSlide:
	stdi8 10608, 255
	ld8_24 a, 0x0340e4
	sll a, 2
	ldb w, 0x0
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800
	jr LABEL_F477D3

LABEL_F477BA:
	ld8_24 a, 0x0340e4
	sll a, 2
	ldb w, 0x0
	extz xwa
	add xwa, 0x988018
	ld xwa, (xwa)
	ld xbc, 0x69800

LABEL_F477D3:
	call SLIDE_Parse_Header

LABEL_F477D7:
	lds32 xhl, 0
	ret

HelpFlashFunc:
	cp xbc, 0x1E80075
	jr z, LABEL_F477FE
	cp xbc, 0x1E80074
	jr nz, LABEL_F47804
	ldw wa, 0x25
	calr SoundCtrl_SaveAndSendCmd_EE
	lds wa, 4
	call CtrlPanel_IndicatorJumpTable
	ldw wa, 0x23
	calr SoundCtrl_SaveAndSendCmd_EE
	jr LABEL_F47804

LABEL_F477FE:
	lds wa, 4
	call Audio_DispatchCommand

LABEL_F47804:
	lds32 xhl, 0
	ret

LABEL_F47807:
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
	ld xwa, 0xD60003
	ld bc, iz
	call SetVisible
	ld xwa, 0xD60004
	ld bc, iz
	call SetVisible
	ld xwa, 0xD60005
	ld bc, iz
	call SetVisible
	ld xwa, 0xD60006
	ld bc, iz
	call SetVisible
	popw iz
	ret

SeqLoadPre:
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

SeqLoadPost:
	cps wa, 0
	jr ge, LABEL_F47864
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

LABEL_F47864:
	lds wa, 1
	lds bc, 4
	lds de, 0
	call Part_WriteByte
	calr LABEL_F47FA4
	call SeqStep_FindLastUsedPart
	ld8_24 a, 0x00ffe3
	extz wa
	call VoicePreset_LoadAndInitPan
	cpdi16 61902, 0
	jr z, LABEL_F47899
	call SeqStep_FindAndCompactEntry
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	call Audio_CheckSubsystemReady
	jr LABEL_F478A2

LABEL_F47899:
	stdi16 61999, 3
	calr SeqBar_ComputeAndSetPositions

LABEL_F478A2:
	calr SeqLoad_CheckAutoAccompFlag
	ld8_24 a, 0x00ffe3
	extz wa
	call SeqData_CopyBlockToBuffer
	calr SeqLoad_InitPartPanPresets
	calr SeqLoad_ProcessAllVoiceData
	jp Seq_ResetAndRestartAccompaniment

LABEL_F478BA:
	jp Part_InitFromPreset

LABEL_F478BE:
	cps wa, 0
	jr ge, LABEL_F478CA
	call Part_ClearAllVoiceChannels
	jp Part_UnlinkVoiceFromChain

LABEL_F478CA:
	lds wa, 1
	lds bc, 4
	lds de, 0
	call Part_WriteByte
	sti8_24 0x00ffe3, 0x00
	call SeqStep_FindLastUsedPart
	ld8_24 a, 0x00ffe3
	extz wa
	call VoicePreset_LoadAndInitPan
	ldmmw_dd24 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	cpdi16 61902, 0
	jr z, LABEL_F47902
	call SeqStep_FindAndCompactEntry
	call Audio_CheckSubsystemReady
	jr LABEL_F4790B

LABEL_F47902:
	stdi16 61999, 3
	calr SeqBar_ComputeAndSetPositions

LABEL_F4790B:
	calr SeqLoad_CheckAutoAccompFlag
	ld8_24 a, 0x00ffe3
	extz wa
	call SeqData_CopyBlockToBuffer
	calr SeqLoad_InitPartPanPresets
	calr SeqLoad_ProcessAllVoiceData
	jp Seq_ResetAndRestartAccompaniment

SeqSavePre:
	push xiz
	call SeqStep_ReinitPartTable
	ld xiz, xhl
	ld8_24 a, 0x00ffe3
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
	ld iz, wa
	lds wa, 1
	lds bc, 4
	lds de, 0
	call Part_WriteByte
	cps iz, 0
	jr lt, LABEL_F47958
	resda 0, 36232

LABEL_F47958:
	popw iz
	ret

LABEL_F4795A:
	.byte 0xef, 0x6e, 0xd7, 0xfa, 0x04, 0xbf, 0x06, 0x41
	.byte 0xe8, 0xa8, 0xbf, 0x02, 0x60, 0xc7, 0xfb, 0xa9
	.byte 0x8f, 0x06, 0x21, 0xc9, 0x61, 0xd8, 0x12, 0xc7
	.byte 0xfb, 0x8b, 0xd9, 0x12, 0x1d, 0x8a, 0x17, 0xf4
	.byte 0xcf, 0xd8, 0x66, 0x29, 0x8f, 0x06, 0x21, 0xc9
	.byte 0x61, 0xd8, 0x12, 0xc7, 0xfb, 0x8b, 0xd9, 0x12
	.byte 0x1d, 0xe5, 0x17, 0xf4, 0xdb, 0x88, 0xd8, 0xcf
	.byte 0xff, 0xff, 0x66, 0x11, 0xe9, 0xa9, 0xaf, 0x02
	.byte 0x89, 0x1d, 0x5f, 0x1c, 0xf4, 0xdb, 0x88, 0xd8
	.byte 0xcf, 0xff, 0xff, 0x6e, 0xef, 0xc7, 0xfb, 0x61
	.byte 0xc7, 0xfb, 0xcf, 0x10, 0x63, 0xba, 0xd1, 0x2f
	.byte 0xf2, 0x20, 0xd8, 0xcf, 0xff, 0xff, 0x66, 0x11
	.byte 0xe9, 0xa9, 0xaf, 0x02, 0x89, 0x1d, 0x5f, 0x1c
	.byte 0xf4, 0xdb, 0x88, 0xd8, 0xcf, 0xff, 0xff, 0x6e
	.byte 0xef, 0xaf, 0x02, 0x23, 0xeb, 0xee, 0x08, 0xbf
	.byte 0x02, 0x63, 0xd7, 0xfa, 0x05, 0xef, 0x66, 0x0e
	.byte 0xef, 0x6a, 0x2e, 0xbf, 0x02, 0x41, 0xd2, 0xec
	.byte 0xff, 0x00, 0x19, 0x9e, 0xf1, 0x1d, 0x6f, 0xde
	.byte 0xfd, 0xc2, 0xe3, 0xff, 0x00, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x0b, 0x14, 0xf4, 0x8f, 0x02, 0x21, 0xd8
	.byte 0x12, 0x1d, 0x26, 0x14, 0xf4, 0x8f, 0x02, 0x21
	.byte 0xf2, 0xe3, 0xff, 0x00, 0x41, 0x1d, 0x0d, 0xf8
	.byte 0xf3, 0xc2, 0xe3, 0xff, 0x00, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x0b, 0x14, 0xf4, 0xd1, 0xce, 0xf1, 0x26
	.byte 0x1d, 0xb4, 0xe7, 0xf4, 0xf1, 0xce, 0xf1, 0x56
	.byte 0x4e, 0xef, 0x62, 0x0e, 0xef, 0x68, 0x3e, 0xbf
	.byte 0x0a, 0x41, 0xd9, 0xd8, 0x69, 0x07, 0x1d, 0x0d
	.byte 0xf8, 0xf3, 0x78, 0xf9, 0x00, 0x1e, 0xc7, 0x04
	.byte 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0x1d, 0x26, 0x14
	.byte 0xf4, 0x1e, 0xc8, 0x04, 0x1e, 0xd2, 0x04, 0xbf
	.byte 0x06, 0x53, 0xc7, 0xfb, 0xa9, 0xc7, 0xfb, 0x8b
	.byte 0xd9, 0x12, 0xd8, 0xa8, 0x1d, 0xe5, 0x17, 0xf4
	.byte 0xdb, 0x8e, 0xde, 0xd8, 0x66, 0x33, 0xde, 0xcf
	.byte 0xff, 0xff, 0x66, 0x2d, 0x9f, 0x06, 0x86, 0xc7
	.byte 0xfb, 0x8b, 0xd9, 0x12, 0xd8, 0xa8, 0xde, 0x8a
	.byte 0x1d, 0xf4, 0x17, 0xf4, 0xc7, 0xfb, 0x8b, 0xd9
	.byte 0x12, 0xd8, 0xa8, 0x1d, 0xc8, 0x15, 0xf4, 0xdb
	.byte 0x8e, 0x9f, 0x06, 0x86, 0xc7, 0xfb, 0x8b, 0xd9
	.byte 0x12, 0xd8, 0xa8, 0xde, 0x8a, 0x1d, 0xb2, 0x15
	.byte 0xf4, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf, 0x10
	.byte 0x63, 0xb3, 0xbf, 0x08, 0x16, 0xce, 0xf1, 0x9f
	.byte 0x08, 0x20, 0xd8, 0xef, 0x04, 0xbf, 0x08, 0x50
	.byte 0xd1, 0x2f, 0xf2, 0x26, 0xbf, 0x04, 0x02, 0x00
	.byte 0x00, 0x9f, 0x08, 0x3f, 0x00, 0x00, 0x63, 0x4d
	.byte 0xde, 0x88, 0x9f, 0x04, 0x80, 0x1d, 0x39, 0x1c
	.byte 0xf4, 0xdb, 0x89, 0xd9, 0xcf, 0xff, 0xff, 0x66
	.byte 0x10, 0xd9, 0xd8, 0x66, 0x0c, 0x9f, 0x06, 0x81
	.byte 0xde, 0x88, 0x9f, 0x04, 0x80, 0x1d, 0x4c, 0x1c
	.byte 0xf4, 0xde, 0x88, 0x9f, 0x04, 0x80, 0x1d, 0x5f
	.byte 0x1c, 0xf4, 0xdb, 0x89, 0xd9, 0xcf, 0xff, 0xff
	.byte 0x66, 0x10, 0xd9, 0xd8, 0x66, 0x0c, 0x9f, 0x06
	.byte 0x81, 0xde, 0x88, 0x9f, 0x04, 0x80, 0x1d, 0x72
	.byte 0x1c, 0xf4, 0x9f, 0x04, 0x61, 0x9f, 0x04, 0x20
	.byte 0x9f, 0x08, 0xf0, 0x67, 0xb3, 0x1e, 0x62, 0x03
	.byte 0xf1, 0x68, 0x26, 0x02, 0x01, 0x00, 0x1e, 0x47
	.byte 0x04, 0x1e, 0xcd, 0x06, 0x8f, 0x0a, 0x21, 0xd8
	.byte 0x12, 0x1d, 0x0b, 0x14, 0xf4, 0x1e, 0x8d, 0x08
	.byte 0x1e, 0xf1, 0x06, 0x1d, 0x8a, 0xca, 0xf3, 0xf2
	.byte 0xec, 0xff, 0x00, 0x16, 0x9e, 0xf1, 0x5e, 0xef
	jr	f, 0x0e

LABEL_F47B34:
	dec 2, xsp
	push xiz
	ld (xsp + 4), bc
	lds32 xhl, 0
	ldda32 xiz, 7514
	extz xwa
	dec 1, xwa
	sll xwa, 8
	add xiz, xwa
	ldda32 xix, 10734
	ldda16 xwa, 10742
	extz xwa
	sll xwa, 8
	add xix, xwa
	ld xde, xix
	lds iy, 0

LABEL_F47B5C:
	ld wa, iy
	extz xwa
	ld xbc, xwa
	add xbc, xde
	add xwa, xiz
	ld a, (xwa)
	ld (xbc), a
	inc 1, iy
	cp iy, 0x100
	jr c, LABEL_F47B5C
	ldda16 xwa, 10740
	ldda16 xbc, 10738
	add bc, wa
	ld wa, bc
	dec 1, wa
	ld (xix + 1), wa
	inc 1, bc
	ld (xix + 3), bc
	cpdi16 10740, 0
	jr nz, LABEL_F47B95
	ldw (xde + 1), 0x0

LABEL_F47B95:
	cpw (xsp + 4), 0xFFFF
	jr nz, LABEL_F47BA1
	ldw (xix + 3), 0xFFFF

LABEL_F47BA1:
	ldda16 xwa, 10742
	inc 1, wa
	stda16 10742, xwa
	cp wa, 0x20
	jr c, LABEL_F47BC4
	ldda32 xwa, 10734
	ld xbc, 0x2000
	call FileIO_WriteByte_Impl
	stdi16 10742, 0

LABEL_F47BC4:
	pop xiz
	inc 2, xsp
	ret

LABEL_F47BC8:
	lds32 xhl, 0
	ldda16 xbc, 10742
	cps bc, 0
	ret z
	ldda32 xwa, 10734
	sll bc, 8
	extz xbc
	call FileIO_WriteByte_Impl
	ret

LABEL_F47BE0:
	dec 6, xsp
	push xiz
	ld (xsp + 8), a
	ldw (xsp + 6), 0x0
	stdi16 10738, 1
	stdi16 10742, 0
	ld (xsp + 4), 0x1

LABEL_F47BFB:
	stdi16 10740, 0
	ld a, (xsp + 8)
	inc 1, a
	extz wa
	ld c, (xsp + 4)
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F47C5D
	ld a, (xsp + 8)
	inc 1, a
	extz wa
	ld c, (xsp + 4)
	extz bc
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xFFFF
	jr z, LABEL_F47C55

LABEL_F47C2D:
	ld wa, iz
	call PartCtrl_ReadWord
	ldfr_werp HL, 0xFA
	ld wa, iz
	ldto_werp BC, 0xFA
	calr LABEL_F47B34
	ld (xsp + 6), hl
	cpw (xsp + 6), 0x0
	jr lt, LABEL_F47C69
	ldto_werp IZ, 0xFA
	incdi16 1, 10740
	cp iz, 0xFFFF
	jr nz, LABEL_F47C2D

LABEL_F47C55:
	ldda16 xwa, 10740
	adddm16 10738, xwa

LABEL_F47C5D:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jr ule, LABEL_F47BFB
	calr LABEL_F47BC8

LABEL_F47C69:
	ld hl, (xsp + 6)
	pop xiz
	inc 6, xsp
	ret

LABEL_F47C70:
	dec 6, xsp
	push xiz
	ld (xsp + 8), a
	ld8_24 a, 0x00ffe3
	cp a, (xsp + 8)
	jr nz, LABEL_F47C8B
	ldmm_sd24w 0xEC, 0xFF, 0x00, 0x9E, 0xF1
	call Audio_CheckSubsystemReady

LABEL_F47C8B:
	ld8_24 a, 0x00ffe3
	extz wa
	call SeqData_CopyBlockToBuffer
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldw bc, 0xC7
	lds de, 0
	call Part_WriteByte
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldw bc, 0x1E
	call Part_ReadWord
	ld de, hl
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldw bc, 0xC8
	call Part_WriteWord
	ld a, (xsp + 8)
	extz wa
	calr LABEL_F47FE1
	ld (xsp + 4), xhl
	ld xhl, (xsp + 4)
	cp xhl, 0x0
	jrl lt, AppEvent_PopIzSkip6Ret
	call GetEncodedFreeSpaceData
	cp xhl, 0x0
	jrl lt, AppEvent_PopIzSkip6Ret
	cp (xsp + 4), xhl
	jr le, LABEL_F47CF9
	ldw hl, 0xFF9B
	jrl AppEvent_PopIzSkip6Ret

LABEL_F47CF9:
	ld a, (xsp + 8)
	extz wa
	calr LABEL_F48094
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	pushw 0x2020
	call Malloc
	inc 2, xsp
	stda32 10734, xhl
	or xhl, xhl
	jr nz, LABEL_F47D23
	ldw hl, 0xFFFD
	jrl AppEvent_PopIzSkip6Ret

LABEL_F47D23:
	ld a, (xsp + 8)
	extz wa
	calr LABEL_F47BE0
	ld iz, hl
	exts xiz
	ldda32 xwa, 10734
	push xwa
	call Free
	inc 4, xsp
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	lds bc, 0
	ldada xde, 10702
	ld xwa, xde
	lda xde, (xde + 32)

LABEL_F47D4E:
	add_spiw BC, 0xE1
	cp xwa, xde
	jr c, LABEL_F47D4E
	sll bc, 4
	ld xwa, 0x4E
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	lds32 xwa, 4
	lds bc, 0
	calr LABEL_F480AD
	ld xiz, xhl
	cp xiz, 0x0
	jrl lt, AppEvent_LoadIzToHL
	ldw (xsp + 6), 0x0
	ld (xsp + 4), 0x0

LABEL_F47D86:
	ld c, (xsp + 4)
	extz bc
	add bc, bc
	ldada xde, 10702
	ld a, (xsp + 4)
	mul a, 0x3
	add a, 0xD1
	ldb w, 0x0
	extz xwa
	cp_sriw_im 0x07, 0xE8, 0xE4, 0x00, 0x00
	jr nz, LABEL_F47DD6
	ldw bc, 0xFFFF
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	add a, (xsp + 4)
	add a, 0x78
	ldb w, 0x0
	extz xwa
	ldw bc, 0xFFFF
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr ge, LABEL_F47E28
	jr AppEvent_LoadIzToHL

LABEL_F47DD6:
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
	ldada xhl, 10702
	ld bc, (xsp + 6)
	add_sriw_rm BC, 0x07, 0xEC, 0xE8
	calr FileIO_SeekAndRead16BitValue
	ld xiz, xhl
	cp xiz, 0x0
	jr lt, AppEvent_LoadIzToHL
	ld a, (xsp + 4)
	extz wa
	add wa, wa
	ldada xbc, 10702
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add (xsp + 6), wa

LABEL_F47E28:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x10
	jrl c, LABEL_F47D86
	resda 0, 36232

AppEvent_LoadIzToHL:
	ld hl, iz

AppEvent_PopIzSkip6Ret:
	pop xiz
	inc 6, xsp
	ret

LABEL_F47E3C:
	cp (xwa + 5), 0x1
	jr nz, LABEL_F47E56
	ld l, (xwa + 6)
	cps l, 3
	jr z, SeqLoad_FetchPartLength
	cps l, 6
	jr z, SeqLoad_FetchPartLength
	cps l, 7
	jr z, SeqLoad_FetchPartLength
	cp l, 0x8
	jr z, SeqLoad_FetchPartLength

LABEL_F47E56:
	ldw hl, 0xFF9A
	ret

SeqLoad_FetchPartLength:
	ld l, (xwa + 4)
	extz hl
	ret

LABEL_F47E60:
	jrl SeqLoadPre

LABEL_F47E63:
	jrl SeqLoadPost

LABEL_F47E66:
	jrl LABEL_F478BA

LABEL_F47E69:
	jrl LABEL_F478BE

SeqBar_ComputeAndSetPositions:
	pushw iz
	ldda16 xbc, 61999
	ldda16 xwa, 61902
	srl wa, 4
	add bc, wa
	cp bc, 0x4D8
	jr c, LABEL_F47E83
	ldw bc, 0xFFFF

LABEL_F47E83:
	ld wa, bc
	call Part_WriteWordBlock_OffsetAF
	ldda16 xbc, 61999
	cp bc, 0xFFFF
	jr nz, LABEL_F47E9D
	stdi16 62001, 0
	lds wa, 0
	jr LABEL_F47EAC

LABEL_F47E9D:
	ldw wa, 0x4D8
	sub wa, bc
	inc 1, wa
	call Part_SetAllVoicePos
	ldda16 xwa, 62001

LABEL_F47EAC:
	cps wa, 0
	jr z, LABEL_F47EFF
	ldda16 xiz, 61999
	cp iz, wa
	jr ugt, LABEL_F47EEB

LABEL_F47EB8:
	ld wa, iz
	lds bc, 0
	call PartCtrl_SetClearBit7
	ld wa, iz
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf
	cps iz, 0
	jr z, LABEL_F47ED9
	ld bc, iz
	dec 1, bc
	ld wa, iz
	call PartCtrl_WriteWord_Off1

LABEL_F47ED9:
	ld bc, iz
	inc 1, bc
	ld wa, iz
	call PartCtrl_WriteWord
	inc 1, iz
	cpda16 xiz, 62001
	jr ule, LABEL_F47EB8

LABEL_F47EEB:
	ldda16 xwa, 61999
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ldw wa, 0x4D8
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord

LABEL_F47EFF:
	popw iz
	ret

LABEL_F47F01:
	.byte 0xd1, 0x2f, 0xf2, 0x19, 0xca, 0x29, 0xd1, 0x31
	.byte 0xf2, 0x19, 0xcc, 0x29, 0x0e, 0xd1, 0xca, 0x29
	.byte 0x19, 0x2f, 0xf2, 0xd1, 0xcc, 0x29, 0x19, 0x31
	.byte 0xf2, 0x0e, 0xdb, 0xa8, 0xd1, 0x2f, 0xf2, 0x20
	.byte 0xd8, 0xd8, 0xb0, 0xf6, 0xd8, 0x8b, 0xdb, 0x69
	.byte 0x0e, 0xef, 0x6c, 0xb7, 0x51, 0xbf, 0x02, 0x41
	.byte 0x8f, 0x02, 0x23, 0xd9, 0x12, 0xd8, 0xa8, 0x1d
	.byte 0xe5, 0x17, 0xf4, 0xdb, 0x8a, 0xda, 0xcf, 0xff
	.byte 0xff, 0x66, 0x04, 0xda, 0xd8, 0x6e, 0x02, 0x68
	.byte 0x0d, 0x97, 0x82, 0x8f, 0x02, 0x23, 0xd9, 0x12
	.byte 0xd8, 0xa8, 0x1d, 0xf4, 0x17, 0xf4, 0xef, 0x64
	.byte 0x0e, 0xd8, 0xa8, 0xd9, 0xad, 0x1d, 0x68, 0x15
	.byte 0xf4, 0xcf, 0xd9, 0xb0, 0xfe, 0xd8, 0xa8, 0xd9
	.byte 0xae, 0x1d, 0x68, 0x15, 0xf4, 0xcf, 0xdf, 0x66
	.byte 0x05, 0xcf, 0xcf, 0x08, 0xb0, 0xfe, 0xf1, 0x5a
	.byte 0xfc, 0x32, 0xba, 0x08, 0x31, 0xe9, 0x88, 0xe8
	.byte 0xca, 0x80, 0xf9, 0x00, 0x00, 0xd8, 0x8c, 0xf1
	.byte 0x60, 0xf4, 0x33, 0xdc, 0x88, 0xe8, 0x12, 0xeb
	.byte 0x80, 0x80, 0x21, 0xb1, 0x41, 0xdc, 0x88, 0xd8
	.byte 0x61, 0xe8, 0x12, 0xeb, 0x80, 0x80, 0x21, 0xba
	.byte 0x09, 0x41, 0x0e

LABEL_F47FA4:
	lds wa, 1
	ldw bc, 0xC7
	call Part_ReadByteDirect
	st8_24 0x00ffe3, l
	lds wa, 1
	ldw bc, 0xC7
	lds de, 0
	call Part_WriteByte
	lds wa, 1
	ldw bc, 0xC8
	call Part_ReadWord
	st16_24 0x00ffec, xhl
	lds wa, 1
	ldw bc, 0xC8
	lds de, 0
	call Part_WriteWord
	stdi16 9832, 1
	resda 3, 10407
	ret

LABEL_F47FE1:
	dec 4, xsp
	push_werp 0xFA
	ld (xsp + 4), a
	ldw (xsp + 2), 0x0
	cp (xsp + 4), 0x10
	jr c, LABEL_F47FFB
	ld xhl, 0xFFFFFFFF
	jr LABEL_F48076

LABEL_F47FFB:
	ldi_berp 0xFB, 1

LABEL_F47FFE:
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	add wa, wa
	ldada xbc, 10702
	stiw_dri 0x07, 0xE4, 0xE0, 0x00, 0x00
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	ldto_berp C, 0xFB
	extz bc
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F4805F
	ld a, (xsp + 4)
	inc 1, a
	extz wa
	ldto_berp C, 0xFB
	extz bc
	call Part_ReadVoiceWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F4805F

LABEL_F4803E:
	ldto_berp C, 0xFB
	dec 1, c
	extz bc
	add bc, bc
	ldada xde, 10702
	inc_sriw 1, 0x07, 0xE8, 0xE4
	incm 1, (xsp + 2)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr nz, LABEL_F4803E

LABEL_F4805F:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F47FFE
	ld hl, (xsp + 2)
	extz xhl
	sll xhl, 8
	add xhl, 0x800

LABEL_F48076:
	pop_werp 0xFA
	inc 4, xsp
	ret

LABEL_F4807C:
	ldda32	xbc, 7514
	extz	xwa
	dec	1, xwa
	sll	xwa, 8
	add	xbc, xwa
	ld	xwa, xbc
	ld	xbc, 256
	jp	16289320

LABEL_F48094:
	ld c, a
	ldb b, 0x0
	extz xbc
	sll xbc, 11
	ld xwa, 0xAB000
	add xwa, xbc
	ld xbc, 0x800
	jp FileIO_WriteByte_Impl

LABEL_F480AD:
	dec 2, xsp
	ld (xsp), c
	lds bc, 0
	call FileIO_SeekAndReadBlock
	exts xhl
	or xhl, xhl
	jr nz, LABEL_F480C7
	ld a, (xsp)
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl

LABEL_F480C7:
	inc 2, xsp
	ret

FileIO_SeekAndRead16BitValue:
	pushw iz
	ld iz, bc
	lds bc, 0
	call FileIO_SeekAndReadBlock
	exts xhl
	or xhl, xhl
	jr nz, LABEL_F480F6
	ld wa, iz
	ldb w, 0x0
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl
	or xhl, xhl
	jr nz, LABEL_F480F6
	ld wa, iz
	srl wa, 8
	extz wa
	call FileIO_ReadByte_BufferHit
	exts xhl

LABEL_F480F6:
	popw iz
	ret

LABEL_F480F8:
	.byte 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0c, 0x41, 0x8f
	.byte 0x0c, 0x21, 0xd8, 0x12, 0xd8, 0x80, 0xf1, 0xce
	.byte 0x29, 0x32, 0xd3, 0x07, 0xe8, 0xe0, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x05, 0xeb, 0xa8, 0x78, 0xc6, 0x00
	.byte 0x40, 0x00, 0x08, 0x00, 0x00, 0xbf, 0x04, 0x60
	.byte 0xbf, 0x0a, 0x02, 0x00, 0x00, 0xbf, 0x08, 0x02
	.byte 0x00, 0x00, 0x8f, 0x0c, 0x23, 0xd9, 0x12, 0xd9
	.byte 0xd8, 0x63, 0x20, 0x9f, 0x08, 0x20, 0xd8, 0x80
	.byte 0xe8, 0x12, 0xea, 0x80, 0x90, 0x23, 0xeb, 0x12
	.byte 0xeb, 0xee, 0x08, 0xaf, 0x04, 0x8b, 0x90, 0x20
	.byte 0x9f, 0x0a, 0x88, 0x9f, 0x08, 0x61, 0x9f, 0x08
	.byte 0xf9, 0x67, 0xe0, 0xe8, 0xa9, 0xaf, 0x04, 0x88
	.byte 0xbf, 0x08, 0x02, 0x01, 0x00, 0x68, 0x37, 0xaf
	.byte 0x04, 0x20, 0x1e, 0x65, 0xff, 0xeb, 0x8e, 0xee
	.byte 0xe6, 0x66, 0x05, 0x30, 0xc8, 0x00, 0x68, 0x68
	.byte 0xaf, 0x04, 0x20, 0xe8, 0x62, 0x9f, 0x0a, 0x21
	.byte 0x9f, 0x08, 0x81, 0xd9, 0x61, 0x1e, 0x4a, 0xff
	.byte 0xeb, 0x8e, 0xee, 0xe6, 0x66, 0x05, 0x30, 0xc9
	.byte 0x00, 0x68, 0x4d, 0x40, 0x00, 0x01, 0x00, 0x00
	.byte 0xaf, 0x04, 0x88, 0x9f, 0x08, 0x61, 0x8f, 0x0c
	.byte 0x27, 0xdb, 0x12, 0xdb, 0x83, 0xf1, 0xce, 0x29
	.byte 0x32, 0x9f, 0x0a, 0x21, 0x9f, 0x08, 0x81, 0xd9
	.byte 0x69, 0x9f, 0x08, 0x20, 0xd3, 0x07, 0xe8, 0xec
	.byte 0xf0, 0x67, 0xac, 0xaf, 0x04, 0x20, 0x1e, 0x11
	.byte 0xff, 0xeb, 0x8e, 0xee, 0xe6, 0x66, 0x05, 0x30
	.byte 0xca, 0x00, 0x68, 0x14, 0xaf, 0x04, 0x20, 0xe8
	.byte 0x62, 0x31, 0xff, 0xff, 0x1e, 0xfb, 0xfe, 0xeb
	.byte 0x8e, 0xee, 0xe6, 0x66, 0x07, 0x30, 0xcb, 0x00
	.byte 0x1d, 0xab, 0x39, 0xf4, 0xee, 0x8b, 0x5e, 0xbf
	.byte 0x0a, 0x37, 0x0e

SeqLoad_CheckAutoAccompFlag:
	lds wa, 0
	lds bc, 6
	call Part_ReadByteDirect
	cps l, 3
	jr nc, SeqLoad_SkipBitCheck
	setda 0, 62014
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
	resda 0, 62014

SeqLoad_SkipBitCheck:
	jr __jrt_nop_F48211
__jrt_nop_F48211:

LABEL_F48211:
	resda 1, 62014
	ret

SeqLoad_ProcessAllVoiceData:
	dec 8, xsp
	push xiz
	ld (xsp + 4), 0x1

LABEL_F4821D:
	ld (xsp + 6), 0x1

LABEL_F48221:
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
	cpw (xsp + 8), 0xFFFF
	jrl z, VoiceData_LoopEnd
	cpw (xsp + 8), 0xFFFF
	jrl z, VoiceData_LoopEnd

LABEL_F48255:
	cpw (xsp + 8), 0x1
	jr z, VoiceData_ProcessLoop
	cpw (xsp + 8), 0x2
	jrl nz, VoiceData_NextWord

VoiceData_ProcessLoop:
	call Part_ProcessAndDecrementVoice
	ld (xsp + 10), hl
	cpw (xsp + 10), 0x4D8
	jrl ugt, LABEL_F483AB
	cpw (xsp + 10), 0x1
	jr z, VoiceData_ProcessLoop
	cpw (xsp + 10), 0x2
	jr z, VoiceData_ProcessLoop
	ldda32 xwa, 7514
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

LABEL_F4829F:
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
	jr c, LABEL_F4829F
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord_Off1
	ld wa, hl
	cps wa, 0
	jr z, LABEL_F482CF
	ld bc, (xsp + 10)
	call PartCtrl_WriteWord
	jr LABEL_F482FA

LABEL_F482CF:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 10)
	call Part_WriteVoiceWord
	ld a, (xsp + 4)
	dec 1, a
	cpda8_24 a, 65507
	jr nz, LABEL_F482FA
	ld c, (xsp + 6)
	extz bc
	lds wa, 0
	ld de, (xsp + 10)
	call Part_WriteVoiceWord

LABEL_F482FA:
	ld wa, (xsp + 8)
	call PartCtrl_ReadWord
	ld wa, hl
	cp wa, 0xFFFF
	jr z, LABEL_F48312
	ld bc, (xsp + 10)
	call PartCtrl_WriteWord_Off1
	jr VoiceData_NextWord

LABEL_F48312:
	ld a, (xsp + 4)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ld de, (xsp + 10)
	call Part_WriteWord_Indexed
	ld a, (xsp + 4)
	dec 1, a
	cpda8_24 a, 65507
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
	cpw (xsp + 8), 0xFFFF
	jrl nz, LABEL_F48255

VoiceData_LoopEnd:
	incm8 1, (xsp + 6)
	cp (xsp + 6), 0x10
	jrl ule, LABEL_F48221
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0xA
	jrl ule, LABEL_F4821D
	lds wa, 1
	lds bc, 1
	call PartCtrl_SetClearBit7
	lds wa, 1
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	lds wa, 1
	ldw bc, 0xFFFF
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
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	lds wa, 2
	lds bc, 5
	ldw de, 0x82
	call PartCtrl_WriteByteToBuf

LABEL_F483AB:
	pop xiz
	inc 8, xsp
	ret

SeqLoad_InitPartPanPresets:
	push_werp 0xFA
	ldi_berp 0xFB, 0

LABEL_F483B5:
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x112
	call Part_ReadByteDirect
	cps l, 1
	jr z, LABEL_F483F6
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x112
	lds de, 1
	call Part_WriteByte
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x110
	call Part_ReadWord
	cps hl, 0
	jr nz, LABEL_F483F6
	ldto_berp A, 0xFB
	extz wa
	ldw bc, 0x110
	ldw de, 0xFFFF
	call Part_WriteWord
	call VoiceChannels_InitPanFromPreset

LABEL_F483F6:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0A
	jr ule, LABEL_F483B5
	pop_werp 0xFA
	ret

LABEL_F48403:
	cps bc, 0
	ret lt
	cps a, 2
	jr z, LABEL_F4840D
	jr LABEL_F4840E

LABEL_F4840D:
	ret

LABEL_F4840E:
	push_werp 0xFA
	calr LABEL_F4878B
	ldi_berp 0xFA, 1

LABEL_F48417:
	ldi_berp 0xFB, 1

LABEL_F4841A:
	ldto_berp A, 0xFA
	extz wa
	ldto_berp C, 0xFB
	extz bc
	calr LABEL_F48440
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F4841A
	inc1_berp 0xFA
	cp_erpb 0xFA, 0x0A
	jr ule, LABEL_F48417
	calr LABEL_F485B5
	pop_werp 0xFA
	ret

LABEL_F48440:
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
	cps l, 0
	jr nz, LABEL_F48471
	calr Part_ClearVoiceSlot
	jrl LABEL_F48563

LABEL_F48471:
	call Part_ReadVoiceWord
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	calr LABEL_F4868A
	cps hl, 0
	jr z, LABEL_F48492
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10
	jrl SeqScan_CallCompare

LABEL_F48492:
	ldi_werp 0xFA, 0
	ld iz, (xsp + 4)
	ld wa, iz

LABEL_F4849A:
	call PartCtrl_ReadWord
	ld (xsp + 4), hl
	cpi_werp 0xFA, 0
	jr nz, LABEL_F484B4
	ld wa, iz
	calr VoiceAlloc_TestBitInMap
	cps l, 0
	jr z, LABEL_F484B4
	setm 4, (xsp + 6)
	jr LABEL_F484C1

LABEL_F484B4:
	ld wa, iz
	ldto_werp BC, 0xFA
	lds de, 1
	calr PartCtrl_CheckOwnerAndToggle
	ld (xsp + 6), hl

LABEL_F484C1:
	cpw (xsp + 6), 0x0
	jr z, LABEL_F484EA
	ld wa, (xsp + 6)
	bit 4, wa
	jr z, LABEL_F484E0
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10
	jrl SeqScan_CallCompare

LABEL_F484E0:
	ld wa, (xsp + 6)
	ld bc, iz
	lds de, 0
	calr PartCtrl_AppendToEventQueue

LABEL_F484EA:
	ld wa, iz
	calr LABEL_F486A3
	ld (xsp + 8), hl
	cpw (xsp + 8), 0x100
	jr nc, LABEL_F48567
	cpw (xsp + 4), 0xFFFF
	jr z, LABEL_F48519
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x40
	calr PartCtrl_AppendToEventQueue
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord

LABEL_F48519:
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
	cp iz, 0xFFFF
	jr z, LABEL_F48563

LABEL_F48550:
	ld wa, iz
	calr LABEL_F4879F
	ld wa, iz
	call PartCtrl_ReadWord
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, LABEL_F48550

LABEL_F48563:
	lds hl, 0
	jr LABEL_F485A5

LABEL_F48567:
	cpw (xsp + 4), 0xFFFF
	jr nz, LABEL_F4857D
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x80
	jr SeqScan_CallCompare

LABEL_F4857D:
	cpw (xsp + 4), 0xFFFF
	jr z, LABEL_F4858B
	cpw (xsp + 4), 0x4D8
	jr ugt, LABEL_F48592

LABEL_F4858B:
	cpw (xsp + 4), 0x0
	jr nz, LABEL_F485AA

LABEL_F48592:
	ld c, (xsp + 12)
	extz bc
	ld e, (xsp + 10)
	extz de
	ldw wa, 0x10

SeqScan_CallCompare:
	calr LABEL_F486CF
	ldw hl, 0xFFFF

LABEL_F485A5:
	pop xiz
	lda xsp, (xsp + 10)
	ret

LABEL_F485AA:
	ldfr_werp IZ, 0xFA
	ld iz, (xsp + 4)
	ld wa, iz
	jrl LABEL_F4849A

LABEL_F485B5:
	push xiz
	ldi_werp 0xFA, 0
	lds wa, 0
	call Part_WriteWordBlock_OffsetAF
	ldw iz, 0x4D8

LABEL_F485C2:
	ld wa, iz
	calr VoiceAlloc_TestBitInMap
	cps l, 0
	jr nz, LABEL_F485DC
	ld wa, iz
	calr LABEL_F485EB
	ld wa, iz
	lds bc, 0
	lds de, 0
	calr PartCtrl_CheckOwnerAndToggle
	inc1_werp 0xFA

LABEL_F485DC:
	dec 1, iz
	cps iz, 2
	jr ugt, LABEL_F485C2
	ldto_werp WA, 0xFA
	call Part_SetAllVoicePos
	pop xiz
	ret

LABEL_F485EB:
	dec 2, xsp
	pushw iz
	ld iz, wa
	ldda16 xwa, 61999
	ld (xsp + 2), wa
	cpw (xsp + 2), 0x0
	jr nz, LABEL_F48605
	ld wa, iz
	ldw bc, 0xFFFF
	jr LABEL_F48613

LABEL_F48605:
	ld wa, (xsp + 2)
	ld bc, iz
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ld bc, (xsp + 2)

LABEL_F48613:
	call PartCtrl_WriteWord
	ld wa, iz
	lds bc, 0
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
	jr z, LABEL_F48649
	setm 4, (xsp + 2)
	jr PartCtrl_AdjustAndReturn

LABEL_F48649:
	cpw (xsp + 4), 0x0
	jr nz, LABEL_F48667
	ld wa, iz
	call PartCtrl_TestBit7
	cps l, 0
	jr z, LABEL_F48667
	ld wa, iz
	lds bc, 0
	call PartCtrl_SetClearBit7
	setm 1, (xsp + 2)
	jr PartCtrl_AdjustAndReturn

LABEL_F48667:
	cpw (xsp + 4), 0x1
	jr nz, PartCtrl_AdjustAndReturn
	ld wa, iz
	call PartCtrl_TestBit7
	cps l, 0
	jr nz, PartCtrl_AdjustAndReturn
	ld wa, iz
	lds bc, 1
	call PartCtrl_SetClearBit7
	setm 2, (xsp + 2)

PartCtrl_AdjustAndReturn:
	ld hl, (xsp + 2)
	popw iz
	inc 6, xsp
	ret

LABEL_F4868A:
	cp wa, 0x4D8
	jr ugt, LABEL_F4869C
	cps wa, 0
	jr z, LABEL_F4869C
	call PartCtrl_TestBit7
	cps l, 0
	jr nz, LABEL_F486A0

LABEL_F4869C:
	ldw hl, 0xFFFF
	ret

LABEL_F486A0:
	lds hl, 0
	ret

LABEL_F486A3:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), wa
	lds iz, 5

LABEL_F486AB:
	ldto_berp C, 0xF8
	extz bc
	ld wa, (xsp + 2)
	call PartCtrl_ReadByte
	cp l, 0x82
	jr z, LABEL_F486C9
	cp l, 0x84
	jr z, LABEL_F486C9
	inc 1, iz
	cp iz, 0xFF
	jr ule, LABEL_F486AB

LABEL_F486C9:
	ld hl, iz
	popw iz
	inc 2, xsp
	ret

LABEL_F486CF:
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
	ldw de, 0xFFFF
	call Part_WriteWord_Indexed
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	lds de, 5
	call Part_WriteByte_Indexed
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp)
	extz bc
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	cp (xsp + 2), 0x0
	jr nz, LABEL_F48746
	ld a, (xsp)
	extz wa
	lds bc, 0
	call Chan_SetActiveBit

LABEL_F48746:
	inc 4, xsp
	ret

PartCtrl_AppendToEventQueue:
	ldda16 xhl, 58296
	cp hl, 0xA
	ret nc
	ld ix, hl
	sll ix, 2
	ldada xhl, 58256
	extz xix
	add xix, xhl
	extz wa
	ld (xix), wa
	ldda16 xwa, 58296
	sll wa, 2
	extz xwa
	add xwa, xhl
	ld (xwa + 2), c
	ldda16 xwa, 58296
	sll wa, 2
	extz xwa
	add xwa, xhl
	ld (xwa + 3), e
	ldda16 xwa, 58296
	inc 1, wa
	stda16 58296, xwa
	ret

LABEL_F4878B:
	ldada xbc, 10744
	ld xwa, xbc
	st_dri3b A, 0xE5, 0x9B, 0x00

LABEL_F48796:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F48796
	ret

LABEL_F4879F:
	dec 1, wa
	ld hl, wa
	srl hl, 3
	and wa, 0x7
	lds de, 1
	and a, 0xF
	jr z, LABEL_F487B3
	slaa de

LABEL_F487B3:
	ldada xwa, 10744
	extz xhl
	add xhl, xwa
	or (xhl), e
	ret

VoiceAlloc_TestBitInMap:
	dec 1, wa
	ld hl, wa
	srl hl, 3
	and wa, 0x7
	lds de, 1
	and a, 0xF
	jr z, LABEL_F487D2
	slaa de

LABEL_F487D2:
	ldada xwa, 10744
	extz xhl
	add xhl, xwa
	ld l, (xhl)
	and l, e
	ret

LABEL_F487DF:
	calr LABEL_F48878
	calr LABEL_F498D9
	calr LABEL_F4957B
	jrl LABEL_F48C1C

LABEL_F487EB:
	ldb l, 0x0

LABEL_F487ED:
	lds bc, 1
	ld a, l
	and a, 0xF
	jr z, LABEL_F487F8
	slaa bc

LABEL_F487F8:
	andda16 xbc, 61854
	jr z, LABEL_F4881C
	ld a, l
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xF
	jr nz, LABEL_F48814
	ldb l, 0xF
	ret

LABEL_F48814:
	cp a, 0x10
	jr nz, LABEL_F4881C
	ldb l, 0x10
	ret

LABEL_F4881C:
	inc 1, l
	cp l, 0x10
	jr c, LABEL_F487ED
	ret

LABEL_F48824:
	ldda8 a, 9696
	extz wa
	ldada xbc, 9542
	ld de, wa
	extz xde
	add xde, xbc
	ldda8 a, 9607
	ld (xde), a
	ldda8 a, 9696
	extz wa
	add wa, wa
	ldada xbc, 9510
	ldmmw_dri 0x07, 0xE4, 0xE0, 0x8E, 0x25
	ret

SeqScan_StoreResultB:
	ldda8 a, 9696
	extz wa
	ldada xbc, 9590
	ld de, wa
	extz xde
	add xde, xbc
	ldda8 a, 9607
	ld (xde), a
	ldda8 a, 9696
	extz wa
	add wa, wa
	ldada xbc, 9558
	ldmmw_dri 0x07, 0xE4, 0xE0, 0x8E, 0x25
	ret

LABEL_F48878:
	stdi16 9616, 0
	stdi8 9618, 0
	resda 0, 10406
	stdi8 9696, 0
	ldada xix, 9510
	ldada xhl, 9558
	ldada xde, 9542
	ldada xbc, 9590

LABEL_F4889C:
	ldda8 a, 9696
	extz wa
	add wa, wa
	stiw_dri 0x07, 0xF0, 0xE0, 0xFF, 0xFF
	ldda8 a, 9696
	extz wa
	add wa, wa
	stiw_dri 0x07, 0xEC, 0xE0, 0xFF, 0xFF
	ldda8 a, 9696
	extz wa
	extz xwa
	add xwa, xde
	ld (xwa), 0xFF
	ldda8 a, 9696
	extz wa
	extz xwa
	add xwa, xbc
	ld (xwa), 0xFF
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jr c, LABEL_F4889C
	stdi8 9696, 0

LABEL_F488E8:
	ldda8 c, 9696
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F488F7
	slaa de

LABEL_F488F7:
	andda16 xde, 61854
	jr z, SeqScan_AdvanceToNextPart
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqScan_AdvanceToNextPart
	stdi16 9614, 0
	call SeqData_SeekToPartStart
	ldda8 a, 9696
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xD
	jr nz, SeqScan_ParsePartEvents
	stdi8 9607, 0
	stdi16 9614, 0
	calr LABEL_F48AA9
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart

SeqScan_ParsePartEvents:
	call SeqData_ReadNextByte
	ld a, l
	and a, 0xF0
	cp a, 0x90
	jr nz, LABEL_F4894D
	calr LABEL_F489B9
	jr SeqScan_ParsePartEvents

LABEL_F4894D:
	cp l, 0x81
	jr nz, LABEL_F48969
	calr LABEL_F489E0
	cps l, 1
	jr nz, SeqScan_ParsePartEvents

SeqScan_AdvanceToNextPart:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jr c, LABEL_F488E8
	ret

LABEL_F48969:
	cp a, 0xB0
	jr nz, LABEL_F48977
	calr LABEL_F489F3
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

LABEL_F48977:
	cp l, 0x85
	jr nz, LABEL_F48985
	calr LABEL_F48A97
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

LABEL_F48985:
	cp l, 0x86
	jr nz, LABEL_F48993
	calr LABEL_F48AD1
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

LABEL_F48993:
	cp l, 0x82
	jr z, SeqScan_AdvanceToNextPart
	cp l, 0x84
	jr nz, LABEL_F489A6
	calr LABEL_F48B07
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

LABEL_F489A6:
	bit 7, l
	jr nz, LABEL_F489B0
	calr SeqData_ReadParamBlock
	jr SeqScan_ParsePartEvents

LABEL_F489B0:
	calr LABEL_F48B24
	cps l, 1
	jr z, SeqScan_AdvanceToNextPart
	jr SeqScan_ParsePartEvents

LABEL_F489B9:
	ldda16 xwa, 9830
	inc 6, wa
	stda16 9830, xwa
	cp wa, 0xFF
	ret ule
	sub wa, 0x100
	inc 5, wa
	stda16 9830, xwa
	ldda16 xwa, 10415
	call PartCtrl_ReadWord
	stda16 10415, xhl
	ret

LABEL_F489E0:
	call PartCtrl_RefreshWordPeriodic
	incdi16 1, 9614
	ldda16 xwa, 9614
	cpda16 xwa, 1052
	scc8 ugt, l
	ret

LABEL_F489F3:
	pushw iz
	calr SeqData_ReadParamBlock
	ldada xhl, 9606
	bitm 2, (xhl)
	jr z, LABEL_F48A02
	setm 7, (xhl + 2)

LABEL_F48A02:
	cp (xhl + 2), 0x48
	jrl nz, SeqScan_StoreAndReturn
	ld a, (xhl + 3)
	and a, 0x1F
	cps a, 5
	jr nz, SeqScan_StoreAndReturn
	lda xbc, (xhl + 4)
	bitm 0, (xhl)
	jr z, LABEL_F48A1C
	setm 7, (xbc)

LABEL_F48A1C:
	bitm 1, (xhl)
	jr z, LABEL_F48A23
	setm 7, (xhl + 5)

LABEL_F48A23:
	ld a, (xhl + 5)
	and a, (xbc)
	and a, 0x30
	jr z, SeqScan_StoreAndReturn
	ldda16 xbc, 9614
	ld iz, bc
	lda xwa, (xhl + 1)
	cps bc, 0
	jr z, LABEL_F48A55
	ld xde, xwa
	ld a, (xwa)
	cp a, 0x28
	jr nc, LABEL_F48A50
	dec 1, bc
	stda16 9614, xbc
	ld a, (xde)
	add a, 0x5F
	ld (xde), a

LABEL_F48A50:
	submi8 (xde), 0x28
	jr LABEL_F48A68

LABEL_F48A55:
	ld xbc, xwa
	ld a, (xwa)
	cp a, 0x28
	jr ule, LABEL_F48A65
	sub a, 0x28
	ld (xbc), a
	jr LABEL_F48A68

LABEL_F48A65:
	ld (xbc), 0x0

LABEL_F48A68:
	ldda16 xwa, 9614
	ldda16 xbc, 1052
	cp wa, bc
	jr c, LABEL_F48A81
	cp wa, bc
	jr ugt, LABEL_F48A8F
	ld a, (xhl + 1)
	cpda8 a, 1051
	jr ugt, LABEL_F48A8F

LABEL_F48A81:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	stda16 9614, xiz

SeqScan_StoreAndReturn:
	ldb l, 0x0
	jr LABEL_F48A95

LABEL_F48A8F:
	stda16 9614, xiz
	ldb l, 0x1

LABEL_F48A95:
	popw iz
	ret

LABEL_F48A97:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	stda8 9607, l
	call PartCtrl_RefreshWordPeriodic
	jr __jrt_nop_F48AA9
__jrt_nop_F48AA9:

LABEL_F48AA9:
	ldda16 xwa, 9614
	cpda16 xwa, 1052
	jr nc, LABEL_F48ABC

LABEL_F48AB3:
	calr LABEL_F48824
	calr LABEL_F48B48
	ldb l, 0x0
	ret

LABEL_F48ABC:
	ldda8 c, 1051
	ld e, c
	extz de
	cp wa, de
	jr ugt, LABEL_F48ACE
	cpdm8 9607, c
	jr ule, LABEL_F48AB3

LABEL_F48ACE:
	ldb l, 0x1
	ret

LABEL_F48AD1:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	stda8 9607, l
	call PartCtrl_RefreshWordPeriodic
	ldda16 xwa, 9614
	ldda16 xbc, 1052
	cp wa, bc
	jr nc, LABEL_F48AF6

LABEL_F48AED:
	calr SeqScan_StoreResultB
	calr SeqScan_UpdateBestPositionB
	ldb l, 0x0
	ret

LABEL_F48AF6:
	cp wa, bc
	jr ugt, LABEL_F48B04
	ldda8 a, 9607
	cpda8 a, 1051
	jr ule, LABEL_F48AED

LABEL_F48B04:
	ldb l, 0x1
	ret

LABEL_F48B07:
	ldda8 a, 9696
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xD
	jr nz, LABEL_F48B1D
	ldb l, 0x1
	ret

LABEL_F48B1D:
	call SeqData_SeekToPartStart
	ldb l, 0x0
	ret

LABEL_F48B24:
	calr SeqData_ReadParamBlock
	ldda16 xwa, 9614
	ldda16 xbc, 1052
	cp wa, bc
	jr nc, LABEL_F48B36
	ldb l, 0x0
	ret

LABEL_F48B36:
	cp wa, bc
	jr ule, LABEL_F48B3D
	ldb l, 0x1
	ret

LABEL_F48B3D:
	ldda8 a, 9607
	cpda8 a, 1051
	scc8 ugt, l
	ret

LABEL_F48B48:
	ldda16 xbc, 9614
	ldda16 xwa, 9616
	cp wa, bc
	ret ugt
	cp wa, bc
	jr nz, LABEL_F48B62
	ldda8 a, 9618
	cpda8 a, 9607
	ret ugt

LABEL_F48B62:
	stda16 9616, xbc
	ldmm8 9618, 9607
	setda 0, 10406
	ret

SeqScan_UpdateBestPositionB:
	ldda16 xbc, 9614
	ldda16 xwa, 9616
	cp wa, bc
	ret ugt
	cp wa, bc
	jr nz, LABEL_F48B8B
	ldda8 a, 9618
	cpda8 a, 9607
	ret ugt

LABEL_F48B8B:
	stda16 9616, xbc
	ldmm8 9618, 9607
	resda 0, 10406
	ret

LABEL_F48B9A:
	stdi16 9614, 0
	stdi16 9620, 0
	stdi16 9622, 0
	stdi8 9696, 0
	stdi16 9624, 0
	stdi16 9628, 0
	stdi16 9626, 0
	stdi16 9630, 0
	ldda16 xwa, 9616
	stda16 9632, xwa
	stda16 9636, xwa
	stda16 9640, xwa
	stda16 9648, xwa
	stda16 9644, xwa
	ldda8 a, 9618
	stda8 9634, a
	stda8 9638, a
	stda8 9642, a
	stda8 9650, a
	stda8 9646, a
	ldda16 xwa, 9652
	stda16 9654, xwa
	stda16 9656, xwa
	stda16 9660, xwa
	stda16 9662, xwa
	stda16 9658, xwa
	stdi8 1079, 255
	stdi8 1078, 255
	ret

LABEL_F48C1C:
	calr LABEL_F48B9A
	stdi8 9696, 0

LABEL_F48C24:
	ldda8 c, 9696
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F48C33
	slaa de

LABEL_F48C33:
	andda16 xde, 61854
	jr z, Seq_TickReturn
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, Seq_TickReturn
	call SeqData_SeekToPartStart
	ldda8 a, 9696
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ldda16 xbc, 10415
	cp (xwa), 0xF
	jr nz, LABEL_F48C72
	stda16 9624, xbc
	ldmm16 9628, 9830
	ldmm8 9664, 9696

LABEL_F48C72:
	ldda8 a, 9696
	extz wa
	extz xwa
	add xwa, xde
	cp (xwa), 0x10
	jr nz, Seq_TickReturn
	stda16 9626, xbc
	ldmm16 9630, 9830
	ldmm8 9666, 9696

Seq_TickReturn:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jr c, LABEL_F48C24
	ldda16 xwa, 9624
	ldda16 xbc, 9626
	ld de, wa
	or de, bc
	ret z
	cps wa, 0
	jr nz, LABEL_F48CBF
	stda16 10415, xbc
	ldmm16 9830, 9630
	jrl LABEL_F48E91

LABEL_F48CBF:
	stda16 10415, xwa
	ldmm16 9830, 9628
	ldda16 xwa, 9626
	cps wa, 0
	jrl nz, LABEL_F48F97
	jr __jrt_nop_F48CD4
__jrt_nop_F48CD4:

LABEL_F48CD4:
	stdi16 9614, 0

Seq_AdvanceNoteStep:
	calr SeqData_ReadParamBlock
	cps hl, 7
	jr c, LABEL_F48CEA
	ldda8 a, 9664
	extz wa
	jrl Portamento_NotifyParams

LABEL_F48CEA:
	ldada xix, 9606
	ld a, (xix)
	ldfr_berp A, 0xE2
	cp_erpb 0xE2, 0x82
	jr nz, LABEL_F48D02
	ldda8 a, 9664
	extz wa
	jrl SeqStep_CallHandleNoteOverflow

LABEL_F48D02:
	cp_erpb 0xE2, 0x84
	jr nz, LABEL_F48D14
	ldmm8 9696, 9664
	call SeqData_SeekToPartStart
	jr Seq_AdvanceNoteStep

LABEL_F48D14:
	ldda16 xhl, 1052
	ld bc, hl
	inc 1, bc
	ldda16 xde, 9614
	cp bc, de
	jr ugt, LABEL_F48D2D
	ldda8 a, 9664
	extz wa
	jrl SeqStep_CallHandleNoteOverflow

LABEL_F48D2D:
	cp_erpb 0xE2, 0x81
	jr nz, LABEL_F48D3B
	inc 1, de
	stda16 9614, xde
	jr Seq_AdvanceNoteStep

LABEL_F48D3B:
	ldto_berp W, 0xE2
	and w, 0xF0
	lda xbc, (xix + 2)
	cp w, 0xC0
	jr nz, LABEL_F48DBB
	cp (xbc), 0x48
	jr nz, Seq_AdvanceNoteStep
	cp (xix + 3), 0x0
	jr nz, Seq_AdvanceNoteStep
	ldda16 xwa, 9616
	cp wa, de
	jrl ugt, Seq_AdvanceNoteStep
	lda xbc, (xix + 1)
	cp wa, de
	jr nz, LABEL_F48D6D
	ldda8 a, 9618
	cp a, (xbc)
	jrl ugt, Seq_AdvanceNoteStep

LABEL_F48D6D:
	ldda8 a, 9664
	extz wa
	cp de, hl
	jrl ugt, SeqStep_CallHandleNoteOverflow
	cp de, hl
	jr nz, LABEL_F48D85
	ld c, (xbc)
	cpda8 c, 1051
	jrl ugt, SeqStep_CallHandleNoteOverflow

LABEL_F48D85:
	ld w, (xix + 4)
	bit_erpb 0xE2, 0x00
	jr z, LABEL_F48D91
	set 7, w

LABEL_F48D91:
	ld c, (xix + 5)
	extz bc
	sll bc, 8
	ld a, w
	extz wa
	add bc, wa
	stda16 9652, xbc
	ldmm16 9632, 9614
	mrdb5 0x8C, 0x01, 0x19, 0xA2, 0x25
	ldmm16 9658, 9656
	stda16 9656, xbc
	jrl LABEL_F48E8B

LABEL_F48DBB:
	ldto_berp W, 0xE2
	and w, 0xF0
	cp w, 0xB0
	jrl nz, Seq_AdvanceNoteStep
	bit_erpb 0xE2, 0x02
	jr z, LABEL_F48DCF
	setm 7, (xbc)

LABEL_F48DCF:
	cp (xbc), 0x98
	jrl nz, Seq_AdvanceNoteStep
	ld w, (xix + 3)
	and w, 0x1F
	cps w, 1
	jrl nz, Seq_AdvanceNoteStep
	ld w, (xix + 4)
	res 7, w
	cps w, 0
	jrl z, Seq_AdvanceNoteStep
	cp w, 0x50
	jrl ugt, Seq_AdvanceNoteStep
	bitda 6, 64919
	jrl z, Seq_AdvanceNoteStep
	dec 1, w
	ld c, w
	extz bc
	mul bc, 0x3B0
	ldada xwa, 64602
	sub xwa, 0xF9A0
	ld hl, wa
	add hl, bc
	ld bc, hl
	extz xbc
	lda_24 xwa, 0x1ed400
	ld xde, xwa
	add xde, xbc
	mrib4 0x82, 0x19, 0xCA, 0x25
	inc 1, hl
	extz xhl
	add xwa, xhl
	ld l, (xwa)
	stda8 9676, l
	ldda16 xbc, 9614
	ldda16 xwa, 9616
	cp wa, bc
	jrl ugt, Seq_AdvanceNoteStep
	inc 1, xix
	cp wa, bc
	jr nz, LABEL_F48E49
	ldda8 a, 9618
	cp a, (xix)
	jrl ugt, Seq_AdvanceNoteStep

LABEL_F48E49:
	ldda8 a, 9664
	extz wa
	ldda16 xde, 1052
	cp bc, de
	jr ugt, SeqStep_CallHandleNoteOverflow
	cp bc, de
	jr nz, LABEL_F48E66
	ld c, (xix)
	cpda8 c, 1051
	jr ule, LABEL_F48E66

SeqStep_CallHandleNoteOverflow:
	jrl SeqStep_HandleNoteOverflow

LABEL_F48E66:
	extz hl
	sll hl, 8
	ldda8 a, 9674
	extz wa
	add hl, wa
	stda16 9652, xhl
	ldmm16 9632, 9614
	mrib4 0x84, 0x19, 0xA2, 0x25
	ldmm16 9658, 9656
	stda16 9656, xhl

LABEL_F48E8B:
	calr SeqTiming_CompareAndUpdateState
	jrl Seq_AdvanceNoteStep

LABEL_F48E91:
	stdi16 9614, 0

SeqStep_ParseEventLoop:
	calr SeqData_ReadParamBlock
	ldda8 a, 9666
	extz wa
	cps hl, 7
	jrl nc, Portamento_NotifyParams
	ldada xiy, 9606
	ld c, (xiy)
	ldfr_berp C, 0xE2
	cp_erpb 0xE2, 0x82
	jr z, SeqStep_OverflowCheck
	cp_erpb 0xE2, 0x84
	jr nz, LABEL_F48EC6
	ldmm8 9696, 9666
	call SeqData_SeekToPartStart
	jr SeqStep_ParseEventLoop

LABEL_F48EC6:
	ldda16 xhl, 1052
	ld bc, hl
	inc 1, bc
	ldda16 xde, 9614
	cp bc, de
	jr ule, SeqStep_OverflowCheck
	cp_erpb 0xE2, 0x81
	jr nz, LABEL_F48EE4
	inc 1, de
	stda16 9614, xde
	jr SeqStep_ParseEventLoop

LABEL_F48EE4:
	ldto_berp C, 0xE2
	and c, 0xF0
	ldfr_berp C, 0xE6
	lda xix, (xiy + 1)
	cp_erpb 0xE6, 0xC0
	jr nz, SeqStep_ParseEventLoop
	cp (xiy + 2), 0x48
	jr nz, SeqStep_ParseEventLoop
	cp (xiy + 3), 0x0
	jr nz, SeqStep_ParseEventLoop
	ldda16 xbc, 9616
	cp bc, de
	jr ugt, SeqStep_ParseEventLoop
	cp bc, de
	jr nz, LABEL_F48F16
	ldda8 c, 9618
	cp c, (xix)
	jr ugt, SeqStep_ParseEventLoop

LABEL_F48F16:
	cp de, hl
	jr ugt, SeqStep_OverflowCheck
	cp de, hl
	jr nz, LABEL_F48F28
	ld c, (xix)
	cpda8 c, 1051
	jr ule, LABEL_F48F28

SeqStep_OverflowCheck:
	jr SeqStep_HandleNoteOverflow

LABEL_F48F28:
	ld a, (xiy + 4)
	ldfr_berp A, 0xE6
	bit_erpb 0xE2, 0x00
	jr z, LABEL_F48F38
	set_erpb 0xE6, 0x07

LABEL_F48F38:
	ld c, (xiy + 5)
	extz bc
	sll bc, 8
	ldto_berp A, 0xE6
	extz wa
	add bc, wa
	stda16 9652, xbc
	ldmm16 9632, 9614
	mrib4 0x84, 0x19, 0xA2, 0x25
	ldda16 xwa, 9656
	stda16 9658, xwa
	stda16 9656, xbc
	calr SeqTiming_CompareAndUpdateState
	jrl SeqStep_ParseEventLoop

SeqStep_HandleNoteOverflow:
	dec 2, xsp
	ld (xsp), a
	cpdi8 1079, 255
	jr z, LABEL_F48F78
	ld a, (xsp)
	extz wa
	jr LABEL_F48F91

LABEL_F48F78:
	ldmm16 9632, 9616
	ldmm8 9634, 9618
	ldmm16 9656, 9652
	calr SeqTiming_CompareAndUpdateState
	ld a, (xsp)
	extz wa

LABEL_F48F91:
	calr Portamento_NotifyParams
	inc 2, xsp
	ret

LABEL_F48F97:
	push_werp 0xFA
	ldi_berp 0xFB, 0

SeqEvt_ReadAndDispatchLoop:
	calr SeqData_ReadParamBlock
	cps hl, 7
	jr c, LABEL_F48FBD
	cpi_berp 0xFB, 0
	jr nz, LABEL_F48FB1
	ldda8 a, 9664
	extz wa
	jr LABEL_F48FB7

LABEL_F48FB1:
	ldda8 a, 9666
	extz wa

LABEL_F48FB7:
	calr Portamento_NotifyParams
	jrl SeqEvt_DispatchLoop_Return

LABEL_F48FBD:
	ldada xwa, 9606
	cpi_berp 0xFB, 0
	jrl nz, LABEL_F49198
	cp (xwa), 0x82
	jr nz, LABEL_F48FD8
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F48FD8:
	cpdi8 9606, 132
	jr nz, LABEL_F48FE8
	ldmm8 9696, 9664
	jrl LABEL_F491B6

LABEL_F48FE8:
	ldda16 xwa, 1052
	inc 1, wa
	cpda16 xwa, 9620
	jr ugt, LABEL_F49000
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F49000:
	ldada xde, 9606
	ld a, (xde)
	cp a, 0x81
	jr nz, LABEL_F49011
	incdi16 1, 9620
	jr SeqEvt_ReadAndDispatchLoop

LABEL_F49011:
	ld l, a
	and l, 0xF0
	lda xbc, (xde + 2)
	cp l, 0xC0
	jrl nz, LABEL_F490B1
	cp (xbc), 0x48
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 3), 0x0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ldda16 xbc, 9620
	ldda16 xwa, 9616
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, LABEL_F49047
	ldda8 a, 9618
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

LABEL_F49047:
	cpda16 xbc, 1052
	jr ule, LABEL_F49059
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F49059:
	ldda16 xwa, 9620
	cpda16 xwa, 1052
	jr nz, SeqEvt_SaveScanAndDispatch
	ldda8 a, 9607
	cpda8 a, 1051
	jr ule, SeqEvt_SaveScanAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SaveScanAndDispatch:
	ldmm16 9624, 10415
	ldmm16 9628, 9830
	ldmm16 9636, 9620
	ldada xwa, 9606
	mrdb5 0x88, 0x01, 0x19, 0xA6, 0x25
	ld l, (xwa + 4)
	bitm 0, (xwa)
	jr z, LABEL_F4909E
	set 7, l

LABEL_F4909E:
	ld a, (xwa + 5)
	extz wa
	sll wa, 8
	extz hl
	add wa, hl
	stda16 9660, xwa
	jrl SeqEvt_ResolveNotePosition

LABEL_F490B1:
	ld l, a
	and l, 0xF0
	cp l, 0xB0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xbc)
	bit 2, a
	jr z, LABEL_F490C6
	set 7, l

LABEL_F490C6:
	cp l, 0x98
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xde + 3)
	and l, 0x1F
	cps l, 1
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ld l, (xde + 4)
	res 7, l
	cps l, 0
	jrl z, SeqEvt_ReadAndDispatchLoop
	cp l, 0x50
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	bitda 6, 64919
	jrl z, SeqEvt_ReadAndDispatchLoop
	extz hl
	dec 1, hl
	ld bc, hl
	mul bc, 0x3B0
	ld hl, bc
	ldada xwa, 64602
	sub xwa, 0xF9A0
	ld ix, wa
	add ix, hl
	ld bc, ix
	extz xbc
	lda_24 xwa, 0x1ed400
	ld xhl, xwa
	add xhl, xbc
	mrib4 0x83, 0x19, 0xCA, 0x25
	inc 1, ix
	ld bc, ix
	extz xbc
	add xwa, xbc
	mrib4 0x80, 0x19, 0xCC, 0x25
	ldda16 xbc, 9620
	ldda16 xwa, 9616
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, LABEL_F49141
	ldda8 a, 9618
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

LABEL_F49141:
	cpda16 xbc, 1052
	jr ule, LABEL_F49153
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F49153:
	ldda16 xwa, 9620
	cpda16 xwa, 1052
	jr nz, SeqEvt_SavePortamentoAndDispatch
	ldda8 a, 9607
	cpda8 a, 1051
	jr ule, SeqEvt_SavePortamentoAndDispatch
	calr SeqVoice_InitFirstSlotSearch
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

SeqEvt_SavePortamentoAndDispatch:
	ldmm16 9624, 10415
	ldmm16 9628, 9830
	ldmm16 9636, 9620
	ldmm8 9638, 9607
	ldda8 a, 9674
	extz wa
	stda16 9660, xwa
	jrl SeqEvt_ResolveNotePosition

LABEL_F49198:
	cp (xwa), 0x82
	jr nz, LABEL_F491A9
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F491A9:
	cpdi8 9606, 132
	jr nz, LABEL_F491BD
	ldmm8 9696, 9666

LABEL_F491B6:
	call SeqData_SeekToPartStart
	jrl SeqEvt_ReadAndDispatchLoop

LABEL_F491BD:
	ldda16 xwa, 1052
	inc 1, wa
	cpda16 xwa, 9622
	jr ugt, LABEL_F491D5
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl lt, SeqEvt_DispatchLoop_Return

LABEL_F491D5:
	ldada xde, 9606
	ld l, (xde)
	cp l, 0x81
	jr nz, LABEL_F491E7
	incdi16 1, 9622
	jrl SeqEvt_ReadAndDispatchLoop

LABEL_F491E7:
	and l, 0xF0
	cp l, 0xC0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 2), 0x48
	jrl nz, SeqEvt_ReadAndDispatchLoop
	cp (xde + 3), 0x0
	jrl nz, SeqEvt_ReadAndDispatchLoop
	ldda16 xbc, 9622
	ldda16 xwa, 9616
	cp wa, bc
	jrl ugt, SeqEvt_ReadAndDispatchLoop
	cp wa, bc
	jr nz, LABEL_F49219
	ldda8 a, 9618
	cp a, (xde + 1)
	jrl ugt, SeqEvt_ReadAndDispatchLoop

LABEL_F49219:
	cpda16 xbc, 1052
	jr ule, LABEL_F4922A
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr lt, SeqEvt_DispatchLoop_Return

LABEL_F4922A:
	ldda16 xwa, 9622
	cpda16 xwa, 1052
	jr nz, SeqEvt_SaveAccompAndDispatch
	ldda8 a, 9607
	cpda8 a, 1051
	jr ule, SeqEvt_SaveAccompAndDispatch
	calr SeqSearch_InitNotFound
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr lt, SeqEvt_DispatchLoop_Return

SeqEvt_SaveAccompAndDispatch:
	ldmm16 9626, 10415
	ldmm16 9630, 9830
	ldmm16 9640, 9622
	ldada xwa, 9606
	mrdb5 0x88, 0x01, 0x19, 0xAA, 0x25
	ld l, (xwa + 4)
	bitm 0, (xwa)
	jr z, LABEL_F4926E
	set 7, l

LABEL_F4926E:
	ld a, (xwa + 5)
	extz wa
	sll wa, 8
	stda16 9662, xwa
	extz hl
	adddm16 9662, xhl

SeqEvt_ResolveNotePosition:
	calr SeqEvt_SelectNearestTiming
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jrl ge, SeqEvt_ReadAndDispatchLoop

SeqEvt_DispatchLoop_Return:
	pop_werp 0xFA
	ret

SeqVoice_InitFirstSlotSearch:
	stdi16 9636, 65535
	stdi8 9638, 255
	ldmm16 9660, 9652
	jr SeqEvt_SelectNearestTiming

SeqSearch_InitNotFound:
	stdi16 9640, 65535
	stdi8 9642, 255
	ldmm16 9662, 9652
	jr __jrt_nop_F492B6
__jrt_nop_F492B6:

SeqEvt_SelectNearestTiming:
	ldda16 xbc, 9636
	cp bc, 0xFFFF
	jr nz, LABEL_F492D4
	cpdi16 9640, 65535
	jr nz, LABEL_F492D4
	ldda8 a, 9666
	extz wa
	calr SeqStep_HandleNoteOverflow
	ldb l, 0xFF
	ret

LABEL_F492D4:
	ldda16 xde, 9640
	cp bc, de
	jr nz, LABEL_F492E6
	ldda8 a, 9638
	cpda8 a, 9642
	jr z, LABEL_F49328

LABEL_F492E6:
	cp bc, de
	jr c, LABEL_F492F8
	cp bc, de
	jr nz, LABEL_F49310
	ldda8 a, 9638
	cpda8 a, 9642
	jr nc, LABEL_F49310

LABEL_F492F8:
	stda16 9632, xbc
	ldmm8 9634, 9638
	ldmm16 9658, 9656
	ldmm16 9656, 9660
	jr LABEL_F49350

LABEL_F49310:
	stda16 9632, xde
	ldmm8 9634, 9642
	ldmm16 9658, 9656
	ldmm16 9656, 9662
	jr LABEL_F4937B

LABEL_F49328:
	cps bc, 0
	jr nz, LABEL_F49330
	cps a, 0
	jr z, LABEL_F49338

LABEL_F49330:
	calr LABEL_F487EB
	cp l, 0xF
	jr nz, LABEL_F49363

LABEL_F49338:
	ldmm16 9632, 9640
	ldmm8 9634, 9642
	ldmm16 9658, 9656
	ldmm16 9656, 9662

LABEL_F49350:
	calr SeqTiming_CompareAndUpdateState
	ldmm16 10415, 9624
	ldmm16 9830, 9628
	ldb l, 0x0
	jr LABEL_F4938C

LABEL_F49363:
	ldmm16 9632, 9636
	ldmm8 9634, 9638
	ldmm16 9658, 9656
	ldmm16 9656, 9660

LABEL_F4937B:
	calr SeqTiming_CompareAndUpdateState
	ldmm16 10415, 9626
	ldmm16 9830, 9630
	ldb l, 0x1

LABEL_F4938C:
	ret

Portamento_NotifyParams:
	push_werp 0xFA
	ldda16 xbc, 9652
	ld a, c
	and a, 0xFF
	ldfr_berp A, 0xFB
	srl bc, 8
	extz bc
	ld xwa, 0x28001
	lds de, 3
	call SoundParam_NotifyChange
	ldto_berp C, 0xFB
	extz bc
	ld xwa, 0x28000
	lds de, 3
	call SoundParam_NotifyChange
	pop_werp 0xFA
	ret

SeqTiming_CompareAndUpdateState:
	push xiz
	ldda16 xbc, 9644
	ldda16 xwa, 9632
	cp bc, wa
	jr ugt, Portamento_CheckPos
	cp bc, wa
	jr nz, Portamento_CheckPos
	ldda8 a, 9646
	cpda8 a, 9634
	jr ugt, Portamento_CheckPos
	stda16 9648, xbc
	ldmm8 9650, 9646
	ldmm16 9654, 9658

Portamento_CheckPos:
	ldda8 a, 9634
	ldda8 c, 9650
	cp a, c
	jr nc, LABEL_F49416
	ldda16 xwa, 9632
	dec 1, wa
	subda16 xwa, 9648
	stda16 9632, xwa
	ldda8 a, 9634
	add a, 0x5F
	subda8 a, 9650
	stda8 9634, a
	jr LABEL_F4942A

LABEL_F49416:
	ldda16 xwa, 9648
	subdm16 9632, xwa
	ldda8 a, 9634
	subda8 a, 9650
	stda8 9634, a

LABEL_F4942A:
	ldda16 xbc, 9632
	cps bc, 0
	jr z, LABEL_F49453
	ldda8 a, 9634
	cp a, 0x28
	jr ugt, LABEL_F4944C
	dec 1, bc
	stda16 9632, xbc
	ldda8 a, 9634
	add a, 0x5F
	stda8 9634, a

LABEL_F4944C:
	subdi8 9634, 40
	jr LABEL_F4946A

LABEL_F49453:
	ldda8 a, 9634
	cp a, 0x28
	jr ule, LABEL_F49465
	sub a, 0x28
	stda8 9634, a
	jr LABEL_F4946A

LABEL_F49465:
	stdi8 9634, 0

LABEL_F4946A:
	ldda16 xbc, 9654
	ld wa, bc
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ldfr_berp L, 0xF0
	extz ix
	ldda16 xbc, 9632
	ld iy, bc
	extz xiy
	div xiy, xix
	extz xbc
	div xbc, xix
	ldto_werp WA, 0xE6
	ldda8 e, 9650
	stda8 9646, e
	cps l, 1
	jr z, LABEL_F494B5
	cps wa, 1
	jr nc, LABEL_F494B5
	mul xiy, xix
	ldda16 xwa, 9648
	add wa, iy
	stda16 9648, xwa
	stda16 9644, xwa
	jr LABEL_F4951F

LABEL_F494B5:
	inc 1, iy
	mul xix, xiy
	ldda16 xbc, 9648
	add bc, ix
	stda16 9648, xbc
	stda16 9644, xbc
	ldda16 xwa, 1052
	cp bc, wa
	jr ugt, LABEL_F494D9
	cp bc, wa
	jr nz, LABEL_F4951F
	cpda8 e, 1051
	jr ule, LABEL_F4951F

LABEL_F494D9:
	ldda16 xbc, 9656
	ld wa, bc
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ldda16 xbc, 9644
	ld iz, bc
	ldda8 a, 9646
	ldfr_berp A, 0xFB
	cpda8 a, 1051
	jr nc, LABEL_F49501
	dec 1, iz

LABEL_F49501:
	subda16 xiz, 1052
	extz hl
	cp iz, hl
	jr ule, LABEL_F49519
	ld iy, iz
	extz xiy
	div xiy, xhl
	inc 1, iy
	mul xhl, xiy
	sub bc, hl
	jr LABEL_F4951B

LABEL_F49519:
	sub bc, hl

LABEL_F4951B:
	stda16 9644, xbc

LABEL_F4951F:
	ldda16 xiz, 1052
	ldda8 a, 1051
	ldfr_berp A, 0xFB
	ldda8 c, 9646
	ldto_berp A, 0xFB
	cp a, c
	jr nc, LABEL_F49541
	dec 1, iz
	subda16 xiz, 9644
	add_erpb 0xFB, 0x5F
	jr LABEL_F49545

LABEL_F49541:
	subda16 xiz, 9644

LABEL_F49545:
	ldto_berp A, 0xFB
	sub a, c
	ldfr_berp A, 0xFB
	ldda16 xbc, 9656
	ld wa, bc
	ldb w, 0x0
	extz wa
	srl bc, 8
	extz bc
	call Rhythm_NoteDispatchWrapper
	ld wa, iz
	div8rr a, l
	stda8 1079, w
	ldto_berp A, 0xFB
	stda8 1078, a
	ldmm16 9652, 9656
	call AccWrap_FullStop
	pop xiz
	ret

LABEL_F4957B:
	push xiz
	stdi16 9614, 0
	stdi8 9696, 0
	stdi16 9668, 0
	stdi8 9670, 0
	stdi8 9672, 0
	ldada xwa, 64602
	sub xwa, 0xF980
	ld iz, wa
	add iz, 0x2E0
	lds wa, 0
	ld bc, iz
	call Part_ReadByteDirect
	ldfr_berp L, 0xFB
	ld bc, iz
	inc 1, bc
	lds wa, 0
	call Part_ReadByteDirect
	ldto_berp A, 0xFB
	stda8 9674, a
	stda8 9676, l
	extz hl
	sll hl, 8
	stda16 9652, xhl
	ldto_berp A, 0xFB
	extz wa
	adddm16 9652, xwa
	stdi8 9696, 0

LABEL_F495DE:
	ldda8 c, 9696
	lds de, 1
	ld a, c
	and a, 0xF
	jr z, LABEL_F495ED
	slaa de

LABEL_F495ED:
	andda16 xde, 61854
	jr z, LABEL_F49631
	inc 1, c
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, LABEL_F49631
	call SeqData_SeekToPartStart
	ldda8 a, 9696
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xF
	call_24 z, 0xF496F9
	ldda8 a, 9696
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0x10
	call_24 z, 0xF49642

LABEL_F49631:
	ldda8 a, 9696
	inc 1, a
	stda8 9696, a
	cp a, 0x10
	jr c, LABEL_F495DE
	pop xiz
	ret

LABEL_F49642:
	stdi16 9614, 0

Portamento_ScanSeqEvents:
	stdi8 9672, 1
	calr SeqData_ReadParamBlock
	cps hl, 7
	jr c, LABEL_F4965D
	ldda8 a, 9696
	extz wa
	jrl Portamento_NotifyParams

LABEL_F4965D:
	ldada xiy, 9606
	ld l, (xiy)
	cp l, 0x82
	ret z
	cp l, 0x84
	jr nz, LABEL_F49673
	call SeqData_SeekToPartStart
	jr Portamento_ScanSeqEvents

LABEL_F49673:
	ldda16 xde, 9616
	ld wa, de
	inc 1, wa
	ldda16 xbc, 9614
	cp wa, bc
	ret ule
	cp l, 0x81
	jr nz, LABEL_F49690
	inc 1, bc
	stda16 9614, xbc
	jr Portamento_ScanSeqEvents

LABEL_F49690:
	ld h, l
	and h, 0xF0
	lda xix, (xiy + 1)
	cp h, 0xC0
	jr nz, Portamento_ScanSeqEvents
	cp (xiy + 2), 0x48
	jr nz, Portamento_ScanSeqEvents
	cp (xiy + 3), 0x0
	jr nz, Portamento_ScanSeqEvents
	ldda16 xwa, 9668
	cp wa, bc
	jr ugt, Portamento_ScanSeqEvents
	cp wa, bc
	jr nz, LABEL_F496BD
	ldda8 a, 9670
	cp a, (xix)
	jr ugt, Portamento_ScanSeqEvents

LABEL_F496BD:
	cp bc, de
	ret ugt
	cp bc, de
	jr nz, LABEL_F496CD
	ld a, (xix)
	cpda8 a, 9618
	ret ugt

LABEL_F496CD:
	ld h, (xiy + 4)
	bit 0, l
	jr z, LABEL_F496D8
	set 7, h

LABEL_F496D8:
	ld a, (xiy + 5)
	extz wa
	sll wa, 8
	stda16 9652, xwa
	ld l, h
	extz hl
	adddm16 9652, xhl
	ldmm16 9668, 9614
	mrib4 0x84, 0x19, 0xC6, 0x25
	jrl Portamento_ScanSeqEvents

LABEL_F496F9:
	stdi16 9614, 0

SeqSearch_AdvanceToPosition:
	calr SeqData_ReadParamBlock
	cps hl, 7
	jr c, LABEL_F4970F
	ldda8 a, 9696
	extz wa
	jrl Portamento_NotifyParams

LABEL_F4970F:
	ldada xiy, 9606
	ld d, (xiy)
	cp d, 0x82
	ret z
	cp d, 0x84
	jr nz, LABEL_F49725
	call SeqData_SeekToPartStart
	jr SeqSearch_AdvanceToPosition

LABEL_F49725:
	ldda16 xix, 9616
	ld wa, ix
	inc 1, wa
	ldda16 xbc, 9614
	cp wa, bc
	ret ule
	cp d, 0x81
	jr nz, LABEL_F49742
	inc 1, bc
	stda16 9614, xbc
	jr SeqSearch_AdvanceToPosition

LABEL_F49742:
	ld e, d
	and e, 0xF0
	lda xwa, (xiy + 2)
	cp e, 0xC0
	jr nz, LABEL_F497C7
	cp (xwa), 0x48
	jr nz, SeqSearch_AdvanceToPosition
	cp (xiy + 3), 0x0
	jr nz, SeqSearch_AdvanceToPosition
	ldda16 xhl, 9668
	cp hl, bc
	jr ugt, SeqSearch_AdvanceToPosition
	cp hl, bc
	jr nz, LABEL_F4976F
	ldda8 a, 9670
	cp a, (xiy + 1)
	jr ugt, SeqSearch_AdvanceToPosition

LABEL_F4976F:
	lda xwa, (xiy + 1)
	cp hl, bc
	jr nz, SeqSearch_ComparePosition
	ldda8 e, 9670
	cp e, (xwa)
	jr nz, SeqSearch_ComparePosition
	cpdi8 9672, 1
	jr nz, SeqSearch_ComparePosition
	cps hl, 0
	jr nz, SeqSearch_ComparePosition
	cps e, 0
	jrl z, SeqSearch_AdvanceToPosition

SeqSearch_ComparePosition:
	cp bc, ix
	ret ugt
	cp bc, ix
	jr nz, LABEL_F4979E
	ld a, (xwa)
	cpda8 a, 9618
	ret ugt

LABEL_F4979E:
	ld e, (xiy + 4)
	bit 0, d
	jr z, LABEL_F497A9
	set 7, e

LABEL_F497A9:
	ld a, (xiy + 5)
	extz wa
	sll wa, 8
	extz de
	add wa, de
	stda16 9652, xwa
	ldmm16 9668, 9614
	mrdb5 0x8D, 0x01, 0x19, 0xC6, 0x25
	jrl SeqSearch_AdvanceToPosition

LABEL_F497C7:
	ld e, d
	and e, 0xF0
	cp e, 0xB0
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xwa)
	bit 2, d
	jr z, LABEL_F497DC
	set 7, e

LABEL_F497DC:
	cp e, 0x98
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xiy + 3)
	and e, 0x1F
	cps e, 1
	jrl nz, SeqSearch_AdvanceToPosition
	ld e, (xiy + 4)
	res 7, e
	cps e, 0
	jrl z, SeqSearch_AdvanceToPosition
	cp e, 0x50
	jrl ugt, SeqSearch_AdvanceToPosition
	bitda 6, 64919
	jrl z, SeqSearch_AdvanceToPosition
	dec 1, e
	extz de
	ld bc, de
	mul bc, 0x3B0
	ld de, bc
	ldada xwa, 64602
	sub xwa, 0xF9A0
	ld hl, wa
	add hl, de
	ld bc, hl
	extz xbc
	lda_24 xwa, 0x1ed400
	ld xde, xwa
	add xde, xbc
	mrib4 0x82, 0x19, 0xCA, 0x25
	inc 1, hl
	extz xhl
	add xwa, xhl
	ld e, (xwa)
	stda8 9676, e
	ldda16 xbc, 9614
	ldda16 xwa, 9668
	cp wa, bc
	jrl ugt, SeqSearch_AdvanceToPosition
	lda xhl, (xiy + 1)
	cp wa, bc
	jr nz, LABEL_F49859
	ldda8 a, 9670
	cp a, (xhl)
	jrl ugt, SeqSearch_AdvanceToPosition

LABEL_F49859:
	ldda16 xwa, 9616
	cp bc, wa
	ret ugt
	cp bc, wa
	jr nz, LABEL_F4986D
	ld a, (xhl)
	cpda8 a, 9618
	ret ugt

LABEL_F4986D:
	extz de
	sll de, 8
	ldda8 a, 9674
	extz wa
	add de, wa
	stda16 9652, xde
	ldmm16 9668, 9614
	mrib4 0x83, 0x19, 0xC6, 0x25
	jrl SeqSearch_AdvanceToPosition

SeqData_ReadParamBlock:
	pushw iz
	lds iz, 0
	call SeqData_ReadNextByte
	stda8 9606, l
	cp l, 0x82
	jr z, LABEL_F498A0
	cp l, 0x84
	jr nz, SeqVoice_ReadByteLoop

LABEL_F498A0:
	lds hl, 0
	jr LABEL_F498D7

SeqVoice_ReadByteLoop:
	call PartCtrl_RefreshWordPeriodic
	call SeqData_ReadNextByte
	bit 7, l
	jr nz, LABEL_F498D5
	cps iz, 5
	jr nc, SeqVoice_ReadByteLoop
	ld bc, iz
	ldada xwa, 9607
	extz xbc
	add xbc, xwa
	ld (xbc), l
	inc 1, iz
	cps iz, 7
	jr c, SeqVoice_ReadByteLoop
	resda 0, 10406
	stdi8 1079, 0
	stdi8 1078, 0

LABEL_F498D5:
	ld hl, iz

LABEL_F498D7:
	popw iz
	ret

LABEL_F498D9:
	bitda 0, 10406
	jr nz, LABEL_F498FD
	ret

LABEL_F498E0:
	calr LABEL_F49A14
	ldda16 xde, 9678
	ldda16 xwa, 9684
	cp wa, de
	ret ugt
	cp wa, de
	jr nc, LABEL_F49971

SeqScan_SaveBarPosition:
	stda16 9616, xde

LABEL_F498F7:
	ldmm8 9618, 9680

LABEL_F498FD:
	cpdi16 9616, 0
	jr nz, LABEL_F4990C
	cpdi8 9618, 0
	ret z

LABEL_F4990C:
	calr LABEL_F4998E
	lds de, 0
	ldada xbc, 9510

LABEL_F49915:
	ld wa, de
	add wa, wa
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr nz, LABEL_F4992B
	inc 1, de
	cp de, 0x10
	jr c, LABEL_F49915

LABEL_F4992B:
	cp de, 0x10
	ret nc
	calr LABEL_F499C2
	ldmm16 9678, 9684
	ldmm8 9680, 9686
	ldmm8 9682, 9688
	lds de, 0
	ldada xbc, 9558

LABEL_F4994C:
	ld wa, de
	add wa, wa
	extz xwa
	add xwa, xbc
	cpw (xwa), 0xFFFF
	jr nz, LABEL_F49962
	inc 1, de
	cp de, 0x10
	jr c, LABEL_F4994C

LABEL_F49962:
	cp de, 0x10
	jrl c, LABEL_F498E0
	ldmm16 9616, 9678
	jr LABEL_F498F7

LABEL_F49971:
	ldda8 a, 9680
	ldda8 c, 9686
	cp c, a
	jrl c, SeqScan_SaveBarPosition
	cp c, a
	ret ugt
	ldda8 a, 9682
	cpda8 a, 9688
	jrl nc, SeqScan_SaveBarPosition
	ret

LABEL_F4998E:
	lds hl, 0
	ldada xbc, 9542

LABEL_F49994:
	ld a, (xbc)
	cpda8 a, 9618
	jr nz, LABEL_F499B7
	ld de, hl
	add de, de
	ldada xwa, 9510
	extz xde
	add xde, xwa
	ld wa, (xde)
	cpda16 xwa, 9616
	jr nz, LABEL_F499B7
	ldw (xde), 0xFFFF
	ld (xbc), 0xFF

LABEL_F499B7:
	inc 1, hl
	inc 1, xbc
	cp hl, 0x10
	jr c, LABEL_F49994
	ret

LABEL_F499C2:
	pushw iz
	ldada xix, 9510
	ld iy, (xix)
	ldada xhl, 9542
	ld a, (xhl)
	ldfr_berp A, 0xE6
	lds iz, 1

LABEL_F499D4:
	ld de, iz
	extz xde
	add xde, xhl
	ld wa, iz
	add wa, wa
	extz xwa
	add xwa, xix
	cp iy, 0xFFFF
	jr nz, LABEL_F499EC
	ld iy, (xwa)
	jr LABEL_F49A05

LABEL_F499EC:
	ld bc, (xwa)
	cp bc, iy
	jr ugt, LABEL_F499FD
	cp bc, iy
	jr c, SeqScan_PartLoopEnd
	ld a, (xde)
	cp_berp A, 0xE6
	jr ule, SeqScan_PartLoopEnd

LABEL_F499FD:
	cp bc, 0xFFFF
	jr z, SeqScan_PartLoopEnd
	ld iy, bc

LABEL_F49A05:
	ld a, (xde)
	ldfr_berp A, 0xE6

SeqScan_PartLoopEnd:
	inc 1, iz
	cp iz, 0x10
	jr c, LABEL_F499D4
	popw iz
	ret

LABEL_F49A14:
	pushw iz
	ldada xix, 9558
	ld iy, (xix)
	ldada xhl, 9590
	ld a, (xhl)
	ldfr_berp A, 0xE6
	lds iz, 1

LABEL_F49A26:
	ld de, iz
	extz xde
	add xde, xhl
	ld wa, iz
	add wa, wa
	extz xwa
	add xwa, xix
	cp iy, 0xFFFF
	jr nz, LABEL_F49A3E
	ld iy, (xwa)
	jr LABEL_F49A57

LABEL_F49A3E:
	ld bc, (xwa)
	cp bc, iy
	jr ugt, LABEL_F49A4F
	cp bc, iy
	jr c, SeqScan_PartSearchEnd
	ld a, (xde)
	cp_berp A, 0xE6
	jr ule, SeqScan_PartSearchEnd

LABEL_F49A4F:
	cp bc, 0xFFFF
	jr z, SeqScan_PartSearchEnd
	ld iy, bc

LABEL_F49A57:
	ld a, (xde)
	ldfr_berp A, 0xE6

SeqScan_PartSearchEnd:
	inc 1, iz
	cp iz, 0x10
	jr c, LABEL_F49A26
	popw iz
	ret

SeqVoice_InitEntry:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	cpdi8 10360, 10
	jr nz, LABEL_F49A85
	call LABEL_F3FA15
	stdi16 61852, 0
	call Part_ClearAllVoiceChannels
	jrl LABEL_F49B23

LABEL_F49A85:
	call SeqVoice_InitAllChannelParams
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldw bc, 0x1C
	lds de, 0
	call Part_WriteWord
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldw bc, 0xCB
	lds de, 0
	call Part_WriteByte
	ldi_berp 0xFB, 1

LABEL_F49AAE:
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xFB
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 a, 10360
	inc 1, a
	extz wa
	ldto_berp C, 0xFB
	extz bc
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F49AAE
	ld8_24 a, 0x00ffe3
	cpda8 a, 10360
	jr nz, LABEL_F49B1F
	stdi8 62027, 0
	call SeqStatus_ResetAndSendCmd
	stdi16 61852, 0
	ldi_berp 0xFB, 1

LABEL_F49AFB:
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ldto_berp C, 0xFB
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, LABEL_F49AFB

LABEL_F49B1F:
	call SeqVoice_InitAllChannelParams

LABEL_F49B23:
	call SeqParams_InitDefaults
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

LABEL_F49B2F:
	jr __jrt_nop_F49B31
__jrt_nop_F49B31:

SeqPart_InitClear:
	pushw iz
	call SeqVoice_SetDefaultParams
	ldda8 a, 10359
	extz wa
	call Seq_ValidatePartNumber
	cps hl, 0
	jr z, SeqPart_InitSlots
	stdi8 10362, 3
	jr SeqPart_InitFinish

SeqPart_InitSlots:
	ldda8 c, 10359
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	call Part_WriteWord_Indexed
	ldda8 c, 10359
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ldda8 c, 10359
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jr z, SeqPart_InitFinish
	ldda8 c, 10359
	extz bc
	lds wa, 0
	lds de, 0
	call Part_SetClearVoiceBit7
	ldda8 c, 10359
	extz bc
	lds wa, 0
	call Part_ReadVoiceWord
	ld iz, hl
	cp iz, 0xFFFF
	jr z, SeqPart_InitFinish
	ldda8 c, 10359
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	ld wa, iz
	call Part_StealAndReallocVoices

SeqPart_InitFinish:
	call SeqVoice_InitReturnZero
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda8 c, 10359
	extz bc
	lds de, 0
	call Part_SetClearVoiceBit7
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda8 c, 10359
	extz bc
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda8 c, 10359
	extz bc
	ldw de, 0xFFFF
	call Part_WriteWord_Indexed
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	ldda8 c, 10359
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
	ldda8 a, 10359
	extz wa
	calr SeqPart_CheckVoiceType
	cps l, 0
	jrl lt, SeqPart_CompareLongReturn
	ldfr_berp L, 0xFB
	ldda8 a, 9858
	extz wa
	calr SeqPart_CheckVoiceType
	cps l, 0
	jrl lt, SeqPart_CompareLongReturn
	stdi8 10194, 0
	calr SeqPart_CheckBothCompatible
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	calr SeqPart_SetupLeftPos
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	ldmw2 (xsp + 4), 0x27D4
	calr SeqPart_SetupRightPos
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	ldda16 xiz, 10200
	calr SeqPart_HandlePartChange
	ldda8 a, 10359
	extz wa
	calr SeqPart_ClearSingle
	ldda8 a, 9858
	extz wa
	calr SeqPart_ClearSingle
	ldto_berp A, 0xFB
	extz wa
	calr SeqPart_AllocNewEntry
	cps hl, 0
	jrl nz, SeqPart_CompareLongReturn
	calr SeqPart_CompareLeft
	ld (xsp + 8), l
	calr SeqPart_CompareRight
	ld (xsp + 6), l
	cpdi8 10194, 255
	jr z, SeqPart_CompareLong

SeqPart_CompareFields:
	ld a, (xsp + 8)
	extz wa
	ld c, (xsp + 6)
	extz bc
	ldda8 e, 10194
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
	ldda8 e, 10204
	cpda8 e, 10206
	jr ugt, SeqPart_CompareSetFlag
	calr SeqPart_ValidateLeft
	ld (xsp + 8), l
	jr SeqPart_CompareReturn

SeqPart_CompareSetFlag:
	ld wa, bc
	calr SeqPart_ValidateRight
	ld (xsp + 6), l

SeqPart_CompareReturn:
	cpdi8 10194, 255
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
	stdi8 10362, 0
	ldda8 a, 10361
	res 0, a
	res 1, a
	stda8 10361, a
	call SeqVoice_SetDefaultParams
	cpdi8 3301, 15
	jp_24 ugt, 0xF3FF1A
	ldda8 a, 10359
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cp (xwa), 0xC
	jr nz, SeqPart_DispatchReturn
	setda 0, 10361

SeqPart_DispatchReturn:
	ldda8 a, 9858
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	cp (xwa), 0xC
	jr nz, SeqPart_DispatchCheckEvent
	setda 1, 10361

SeqPart_DispatchCheckEvent:
	ldda8 a, 3301
	inc 1, a
	extz wa
	calr SeqPart_EventLoop
	call SeqVoice_InitReturnZero
	ldda8 a, 10361
	res 0, a
	res 1, a
	stda8 10361, a
	ret

SeqPart_EventLoop:
	resda 2, 10363
	stdi8 10362, 0
	extz wa
	stda16 10365, xwa
	stdi16 10367, 1
	ldda16 xwa, 10365
	extz wa
	lds bc, 0
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	ret nz
	ldda16 xwa, 9830
	stda16 10373, xwa
	ldda16 xwa, 10415
	stda16 10375, xwa
	ldmm16 10377, 9830
	ldmm16 10379, 10415

SeqPart_EventLoopD0:
	call SeqPart_ReadByte_Secondary
	ld a, l
	extz wa
	cp l, 0xD1
	jr z, SeqPart_EventLoopNote
	cp l, 0xD2
	jr z, SeqPart_EventLoopNote
	cp l, 0xD3
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
	and l, 0xF0
	cp l, 0xB0
	jr z, SeqPart_EventLoop90
	cp l, 0xC0
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
	cpdi8 10362, 0
	jr z, SeqPart_EventLoopD0
	ret

SeqPart_EventLoopContinue:
	ldmm8 3378, 10355
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
	ldw de, 0xFFFF
	call Part_WriteVoiceWord
	ld c, (xsp)
	extz bc
	lds wa, 0
	ldw de, 0xFFFF
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
	ldada xbc, 9184
	exts xwa
	add xwa, xbc
	ldw (xwa), 0xFFFF
	ldw (xwa + 2), 0x5
	inc 2, xsp
	ret

SeqPart_ClearSingleReturn:
	.byte 0x0e

SeqPart_CompareLeft:
	push_werp 0xFA
	resda 0, 10194
	ldda16 xwa, 10196
	ldda16 xbc, 10198
	call PartCtrl_ReadByteExtended
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x82
	jr z, SeqPart_CompareLeftCheck
	cp_erpb 0xFB, 0x81
	jr nz, SeqPart_CompareLeftLoop

SeqPart_CompareLeftCheck:
	setda 0, 10194
	jr SeqPart_CompareLeftDone

SeqPart_CompareLeftLoop:
	ld xwa, 0x27D4
	ld xbc, 0x27D6
	call PartCtrl_ReadWordWithBoundsCheck
	ldda16 xwa, 10196
	ldda16 xbc, 10198
	call PartCtrl_ReadByteExtended
	stda8 10204, l

SeqPart_CompareLeftDone:
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

SeqPart_CompareRight:
	push_werp 0xFA
	resda 1, 10194
	ldda16 xwa, 10200
	ldda16 xbc, 10202
	call PartCtrl_ReadByteExtended
	ldfr_berp L, 0xFB
	cp_erpb 0xFB, 0x82
	jr z, SeqPart_CompareRightCheck
	cp_erpb 0xFB, 0x81
	jr nz, SeqPart_CompareRightLoop

SeqPart_CompareRightCheck:
	setda 1, 10194
	jr SeqPart_CompareRightDone

SeqPart_CompareRightLoop:
	ld xwa, 0x27D8
	ld xbc, 0x27DA
	call PartCtrl_ReadWordWithBoundsCheck
	ldda16 xwa, 10200
	ldda16 xbc, 10202
	call PartCtrl_ReadByteExtended
	stda8 10206, l

SeqPart_CompareRightDone:
	ldto_berp L, 0xFB
	pop_werp 0xFA
	ret

SeqPart_WaitLeftMatch:
	ld l, a

SeqPart_WaitLeftLoop:
	extz hl
	ld wa, hl
	calr SeqPart_ValidateLeft
	bitda 0, 10194
	jr z, SeqPart_WaitLeftLoop
	ret

SeqPart_WaitRightMatch:
	ld l, a

SeqPart_WaitRightLoop:
	extz hl
	ld wa, hl
	calr SeqPart_ValidateRight
	bitda 1, 10194
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
	stdi8 10194, 255
	ldda8 a, 9860
	extz wa
	stda16 10365, xwa
	ldda16 xwa, 10373
	ld c, a
	extz bc
	ldda16 xwa, 10375
	call Part_WriteWordAndByte
	jr SeqPart_DualSwapReturn

SeqPart_DualSwapFinish:
	ldw wa, 0x81
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	ld xwa, 0x27D4
	ld xbc, 0x27D6
	call PartCtrl_ReadWordWithBoundsCheck
	calr SeqPart_CompareLeft
	ld (xiz), l
	ld xwa, 0x27D8
	ld xbc, 0x27DA
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
	bitda 1, 10194
	jr nz, SeqPart_ValidateRightCore
	call PartCtrl_AdvanceToNextEntry
	ldda8 a, 10206
	extz wa

SeqPart_ValidateRightLoop:
	call SeqPart_WriteByte_Primary

SeqPart_ValidateRightCore:
	ld xwa, 0x27D8
	ld xbc, 0x27DA
	call PartCtrl_ReadWordWithBoundsCheck
	call PartCtrl_AdvanceToNextEntry
	ldda16 xwa, 10200
	ldda16 xbc, 10202
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
	bitda 0, 10194
	jr nz, SeqPart_ValidateLeftCore
	call PartCtrl_AdvanceToNextEntry
	ldda8 a, 10204
	extz wa

SeqPart_ValidateLeftLoop:
	call SeqPart_WriteByte_Primary

SeqPart_ValidateLeftCore:
	ld xwa, 0x27D4
	ld xbc, 0x27D6
	call PartCtrl_ReadWordWithBoundsCheck
	call PartCtrl_AdvanceToNextEntry
	ldda16 xwa, 10196
	ldda16 xbc, 10198
	call PartCtrl_ReadByteExtended
	bit 7, l
	jrl nz, SeqPart_CompareLeft
	extz hl
	ld wa, hl
	jr SeqPart_ValidateLeftLoop

SeqPart_InitWithValidation:
	call SeqVoice_SetDefaultParams
	call LABEL_F3FABF
	cps hl, 0
	jr z, SeqPart_InitValidOk
	stdi8 10362, 3
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xFFFF
	ret

SeqPart_InitValidOk:
	stdi8 10362, 0
	resda 6, 10363
	lds hl, 0
	ret

SeqPart_CheckVoiceType:
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	cp l, 0xF
	jr z, SeqPart_CheckVoiceIsDrum
	cp l, 0x10
	jr z, SeqPart_CheckVoiceIsDrum
	cp l, 0xD
	ret nz

SeqPart_CheckVoiceIsDrum:
	stdi8 10362, 9
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldb l, 0xFF
	ret

SeqPart_CheckBothCompatible:
	ldda8 a, 10359
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	ldda8 a, 9858
	dec 1, a
	ld e, a
	extz de
	extz xde
	add xde, xbc
	cp l, (xde)
	jr z, SeqPart_CompatReturn
	stda8 3301, a
	ldda8 a, 9858
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x73, 0x28
	ldda8 a, 10359
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0xe44ba4
	ldmm_srib 0x07, 0xE4, 0xE0, 0x7C, 0x28
	calr SeqPart_SetupWithDispatch
	cpdi8 10362, 0
	jr z, SeqPart_CompatReturn
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xFFFF
	ret

SeqPart_CompatReturn:
	lds hl, 0
	ret

SeqPart_SetupLeftPos:
	ldda8 a, 10359
	extz wa
	call Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jr z, SeqPart_SetupLeftDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xFFFF
	ret

SeqPart_SetupLeftDone:
	ldmm16 10196, 10415
	stdi16 10198, 5
	lds hl, 0
	ret

SeqPart_SetupRightPos:
	ldda8 a, 9858
	extz wa
	call Part_ValidateVoiceChannel
	cpdi8 10362, 0
	jr z, SeqPart_SetupRightDone
	call Part_ApplyVoiceTableA
	call SeqVoice_InitReturnZero
	ldw hl, 0xFFFF
	ret

SeqPart_SetupRightDone:
	ldmm16 10200, 10415
	stdi16 10202, 5
	lds hl, 0
	ret

SeqPart_HandlePartChange:
	push_werp 0xFA
	ldda8 a, 10359
	ldfr_berp A, 0xFB
	ldda8 a, 9860
	cp_berp A, 0xFB
	jr z, SeqPart_PartChangeError
	cpda8 a, 9858
	jr z, SeqPart_PartChangeError
	stda8 10359, a
	calr SeqPart_InitClear
	ldto_berp A, 0xFB
	stda8 10359, a

SeqPart_PartChangeError:
	pop_werp 0xFA
	ret

SeqPart_AllocNewEntry:
	dec 2, xsp
	pushw iz
	ld (xsp + 2), a
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	cp iz, 0xFFFF
	jr nz, SeqPart_AllocDone
	ldw hl, 0xFFFF
	jr SeqPart_AllocReturn

SeqPart_AllocDone:
	ldda8 a, 9860
	dec 1, a
	extz wa
	ldada xbc, 61856
	ld de, wa
	extz xde
	add xde, xbc
	ld a, (xsp + 2)
	ld (xde), a
	ldda8 c, 9860
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 c, 9860
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	stda16 10375, xiz
	stdi16 10373, 5
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	lds hl, 0

SeqPart_AllocReturn:
	popw iz
	inc 2, xsp
	ret

SeqPart_ByteBlockA207:
	.byte 0xd7, 0xfa, 0x04, 0x1d, 0xfb, 0xfe, 0xf3, 0x1d
	.byte 0x6a, 0xf7, 0xf3, 0xdb, 0xd8, 0x66, 0x08, 0xf1
	.byte 0x7a, 0x28, 0x00, 0x03, 0x78, 0x3f, 0x01, 0xf1
	.byte 0x7a, 0x28, 0x00, 0x00, 0xc1, 0x7b, 0x28, 0x23
	.byte 0xcb, 0x30, 0x06, 0xf1, 0x7b, 0x28, 0x43, 0xc1
	.byte 0x77, 0x28, 0x21, 0xc9, 0xcf, 0x7f, 0x66, 0x57
	.byte 0xc9, 0x69, 0xd8, 0x12, 0xf1, 0xa0, 0xf1, 0x32
	.byte 0xe8, 0x12, 0xea, 0x80, 0x80, 0x21, 0xc7, 0xfb
	.byte 0x99, 0xc7, 0xfb, 0xcf, 0x0d, 0x66, 0x06, 0xc7
	.byte 0xfb, 0xcf, 0x10, 0x6e, 0x1f, 0xc7, 0xfb, 0xcf
	.byte 0x10, 0x6e, 0x07, 0xcb, 0x31, 0x06, 0xf1, 0x7b
	.byte 0x28, 0x43, 0xc1, 0x77, 0x28, 0x21, 0xd8, 0x12
	.byte 0x1d, 0x57, 0xff, 0xf3, 0xc1, 0x7a, 0x28, 0x3f
	.long LABEL_EA7E00
	.byte 0xc1, 0x77, 0x28, 0x19
	.byte 0x34, 0x26, 0xf1, 0x7b, 0x28, 0xce, 0x66, 0x09
	.byte 0xc7, 0xfb, 0xcf, 0x10, 0xf2, 0x51, 0x0a, 0xf4
	.byte 0xe6, 0x1e, 0xde, 0x00, 0x78, 0xc9, 0x00, 0xc7
	.byte 0xfa, 0xa9, 0xc7, 0xfa, 0x89, 0xc9, 0x69, 0xd8
	.byte 0x12, 0xf1, 0xa0, 0xf1, 0x31, 0xe8, 0x12, 0xe9
	.byte 0x80, 0x80, 0x21, 0xc7, 0xfb, 0x99, 0xc7, 0xfb
	.byte 0xcf, 0x0d, 0x66, 0x06, 0xc7, 0xfb, 0xcf, 0x10
	.byte 0x6e, 0x1b, 0xc7, 0xfb, 0xcf, 0x10, 0x6e, 0x04
	.byte 0xf1, 0x7b, 0x28, 0xbe, 0xc7, 0xfa, 0x89, 0xd8
	.byte 0x12, 0x1d, 0x57, 0xff, 0xf3, 0xc1, 0x7a, 0x28
	.byte 0x3f, 0x00, 0x7e, 0x91, 0x00, 0xc7, 0xfa, 0x61
	.byte 0xc7, 0xfa, 0xcf, 0x10, 0x63, 0xbc, 0x1d, 0x0a
	.byte 0x03, 0xf4, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x6e
	.byte 0x7d, 0xf1, 0x36, 0x26, 0x00, 0x00, 0xc7, 0xfa
	.byte 0xa9, 0xc1, 0xa1, 0x28, 0x3f, 0x01, 0x67, 0x68
	.byte 0xc7, 0xfa, 0x89, 0xf1, 0x34, 0x26, 0x41, 0xf1
	.byte 0x7b, 0x28, 0xce, 0x66, 0x1d, 0xc7, 0xfa, 0x89
	.byte 0xc9, 0x69, 0xd8, 0x12, 0xf1, 0xa0, 0xf1, 0x31
	.byte 0xe8, 0x12, 0xe9, 0x80, 0x80, 0x3f, 0x10, 0x6e
	.byte 0x09, 0xf1, 0x7a, 0x28, 0x00, 0x00, 0x1d, 0x51
	.byte 0x0a, 0xf4, 0x1e, 0x4d, 0x00, 0xc1, 0x7a, 0x28
	.byte 0x23, 0xcb, 0xd8, 0x6e, 0x13, 0xf1, 0x7b, 0x28
	.byte 0xce, 0x66, 0x21, 0xc7, 0xfa, 0x89, 0xc1, 0x8d
	.byte 0x28, 0xf1, 0x6e, 0x18, 0xcb, 0xd8, 0x66, 0x14
	.byte 0xcb, 0xd9, 0x66, 0x10, 0xcb, 0xcf, 0x08, 0x66
	.byte 0x0b, 0xc1, 0x36, 0x26, 0x3f, 0x00, 0x6e, 0x04
	.byte 0xf1, 0x36, 0x26, 0x43, 0xc7, 0xfa, 0x61, 0xc7
	.byte 0xfa, 0x89, 0xc1, 0xa1, 0x28, 0xf1, 0x63, 0x98
	.byte 0xc1, 0x36, 0x26, 0x19, 0x7a, 0x28, 0x1d, 0x42
	.byte 0xff, 0xf3, 0x1d, 0x1a, 0xff, 0xf3, 0xd7, 0xfa
	.byte 0x05, 0x0e, 0xf1, 0x7a, 0x28, 0x00, 0x00, 0xc1
	.byte 0x34, 0x26, 0x21, 0xd8, 0x12, 0xf1, 0x7d, 0x28
	.byte 0x50, 0xc1, 0x34, 0x26, 0x21, 0xd8, 0x12, 0x1d
	.byte 0xbb, 0xfc, 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00
	.byte 0xb0, 0xfe, 0xd1, 0x66, 0x26, 0x19, 0x5e, 0x26
	.byte 0xd1, 0xaf, 0x28, 0x19, 0x5c, 0x26, 0x1d, 0xa7
	.byte 0x00, 0xf4, 0xc1, 0x34, 0x26, 0x21, 0xd1, 0x32
	.byte 0x26, 0x19, 0x7f, 0x28, 0xd8, 0x12, 0xdb, 0x12
	.byte 0xdb, 0x89, 0x1d, 0x4c, 0xfe, 0xf3, 0xc1, 0x7a
	.byte 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xd1, 0x66, 0x26
	.byte 0x19, 0x85, 0x28, 0xd1, 0xaf, 0x28, 0x19, 0x87
	.byte 0x28, 0xd1, 0x32, 0x26, 0x20, 0xd8, 0xd9, 0x6e
	.byte 0x57, 0xd1, 0xde, 0x25, 0x80, 0xf1, 0x7f, 0x28
	.byte 0x50, 0xc1, 0x34, 0x26, 0x21, 0xc1, 0x8d, 0x28
	.byte 0x27, 0xd8, 0x12, 0xdb, 0x12, 0xdb, 0x89, 0x1d
	.byte 0x4c, 0xfe, 0xf3, 0xc1, 0x7a, 0x28, 0x21, 0xc9
	.byte 0xd8, 0x66, 0x0c, 0xc9, 0xcf, 0x08, 0xb0, 0xfe
	.byte 0xf1, 0x7a, 0x28, 0x00, 0x00, 0x68, 0x09, 0x1d
	.byte 0xa6, 0x21, 0xf4, 0xcf, 0xcf, 0x82, 0x6e, 0x20
	.byte 0xc1, 0x34, 0x26, 0x19, 0x77, 0x28, 0x1e, 0x29
	.byte 0xf7, 0xc1, 0x77, 0x28, 0x21, 0xc9, 0x69, 0xd9
	.byte 0xa9, 0xc9, 0xcc, 0x0f, 0x66, 0x02, 0xd9, 0xfc
	.byte 0xd9, 0x06, 0xd2, 0xec, 0xff, 0x00, 0xc9, 0x0e
	.byte 0xc1, 0x8d, 0x28, 0x27, 0xc1, 0x34, 0x26, 0x21
	.byte 0xd1, 0x32, 0x26, 0x19, 0x7f, 0x28, 0xd8, 0x12
	.byte 0xdb, 0x12, 0xdb, 0x89, 0x1d, 0x4c, 0xfe, 0xf3
	.byte 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xd1
	.byte 0x87, 0x28, 0x19, 0xaf, 0x28, 0xd1, 0x85, 0x28
	.byte 0x19, 0x66, 0x26, 0x1d, 0xe0, 0xff, 0xf3, 0xc1
	.byte 0x7a, 0x28, 0x21, 0xc9, 0xd8, 0x66, 0x05, 0xc9
	.byte 0xdf, 0x66, 0x0c, 0x0e, 0x1d, 0x52, 0x00, 0xf4
	.byte 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xf1
	.byte 0x7a, 0x28, 0x00, 0x00, 0xd1, 0x66, 0x26, 0x19
	.byte 0x89, 0x28, 0xd1, 0xaf, 0x28, 0x19, 0x8b, 0x28
	.byte 0xf1, 0x2c, 0x28, 0x30, 0xb0, 0x16, 0x8b, 0x28
	.byte 0xb8, 0x02, 0x16, 0x89, 0x28, 0xf1, 0x30, 0x28
	.byte 0x30, 0xb0, 0x16, 0x87, 0x28, 0xb8, 0x02, 0x16
	.byte 0x85, 0x28, 0xf1, 0x34, 0x28, 0x30, 0xb0, 0x16
	.byte 0x5c, 0x26, 0xb8, 0x02, 0x16, 0x5e, 0x26, 0x1d
	.byte 0x65, 0x05, 0xf4, 0xc1, 0x7a, 0x28, 0x3f, 0x00
	.byte 0xb0, 0xfe, 0xf1, 0x34, 0x28, 0x32, 0xba, 0x02
	.byte 0x31, 0x91, 0x20, 0xd8, 0xdd, 0x6e, 0x17, 0x92
	.byte 0x20, 0x1d, 0x39, 0x1c, 0xf4, 0xdb, 0xd8, 0xb0
	.byte 0xf6, 0xf1, 0x34, 0x28, 0x30, 0xb0, 0x53, 0xb8
	.byte 0x02, 0x02, 0xff, 0x00, 0x68, 0x04, 0xd8, 0x69
	.byte 0xb1, 0x50, 0xf1, 0x34, 0x28, 0x32, 0x9a, 0x02
	.byte 0x20, 0xc9, 0x8b, 0xd9, 0x12, 0x92, 0x20, 0x1d
	.byte 0x9f, 0x03, 0xf4, 0xd1, 0x34, 0x28, 0x20, 0x1b
	.byte 0xe2, 0x25, 0xf4

SeqPart_SinglePartLoad:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	call LABEL_F3F6FC
	cps hl, 0
	jr z, SeqPart_SingleLoadCheckType
	stdi8 10362, 3
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadCheckType:
	stdi8 10362, 0
	ldda8 c, 10363
	res 6, c
	stda8 10363, c
	ldda8 a, 10359
	cp a, 0x7F
	jr z, SeqPart_SingleLoadMode1
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_SingleLoadSetup
	cp a, 0x10
	jr nz, SeqPart_SingleLoadMode0

SeqPart_SingleLoadSetup:
	cp a, 0x10
	jr nz, SeqPart_SingleLoadMode
	set 6, c
	stda8 10363, c

SeqPart_SingleLoadMode:
	ldda8 a, 10359
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cpdi8 10362, 0
	jrl nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode0:
	ldmm8 9780, 10359
	calr SeqPart_FullLoad
	jrl SeqPart_SingleLoadCleanup

SeqPart_SingleLoadMode1:
	ldi_berp 0xFB, 1

SeqPart_SingleLoadMode2:
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_SingleLoadInit
	cp a, 0x10
	jr nz, SeqPart_SingleLoadVoiceSetup

SeqPart_SingleLoadInit:
	cp a, 0x10
	jr nz, SeqPart_SingleLoadSkipDrum
	setda 6, 10363

SeqPart_SingleLoadSkipDrum:
	ldto_berp A, 0xFB
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cpdi8 10362, 0
	jr nz, SeqPart_SingleLoadCleanup

SeqPart_SingleLoadVoiceSetup:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqPart_SingleLoadMode2
	call LABEL_F4030A
	cpdi8 10362, 0
	jr nz, SeqPart_SingleLoadCleanup
	stdi8 9782, 0
	ldi_berp 0xFB, 1
	cpdi8 10401, 1
	jr c, SeqPart_SingleLoadReturn

SeqPart_SingleLoadFinish:
	ldto_berp A, 0xFB
	stda8 9780, a
	calr SeqPart_FullLoad
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_SingleLoadError
	cps a, 1
	jr z, SeqPart_SingleLoadError
	cp a, 0x8
	jr z, SeqPart_SingleLoadError
	cpdi8 9782, 0
	jr nz, SeqPart_SingleLoadError
	stda8 9782, a

SeqPart_SingleLoadError:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cpda8 a, 10401
	jr ule, SeqPart_SingleLoadFinish

SeqPart_SingleLoadReturn:
	ldmm8 10362, 9782

SeqPart_SingleLoadCleanup:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_FullLoad:
	dec 2, xsp
	push xiz
	stdi8 10362, 0
	ldda8 a, 9780
	extz wa
	stda16 10365, xwa
	ldda8 a, 9780
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	ldmm16 9822, 9830
	ldmm16 9820, 10415
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	ldda16 xwa, 9830
	stda16 10373, xwa
	ldda16 xwa, 10415
	stda16 10375, xwa
	ldmm16 10377, 9830
	ldmm16 10379, 10415
	ldda8 a, 9808
	ldw (xsp + 4), 0x0
	cps a, 0
	jrl nz, SeqPart_FullLoadMode1
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadWalk:
	lds iz, 0
	ldi_berp 0xFB, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, SeqPart_FullLoadComplete

SeqPart_FullLoadReadEvent:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	cp_erpb 0xFA, 0x82
	jr nz, SeqPart_FullLoadCheck81
	ldi_berp 0xFB, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadCheck81:
	cp_erpb 0xFA, 0x81
	jr nz, SeqPart_FullLoadSrcMatch
	ldto_berp A, 0xFA
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz

SeqPart_FullLoadCountCheck:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jr nz, SeqPart_FullLoadReadEvent

SeqPart_FullLoadComplete:
	cpi_berp 0xFB, 1
	jrl z, SeqPart_FullLoadExit
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cpda16 xwa, 9694
	jr nz, SeqPart_FullLoadWalk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadSrcMatch:
	ldda8 a, 9780
	cpda8 a, 10381
	jr nz, SeqPart_FullLoadValidate
	ldto_berp A, 0xFA
	and a, 0xF0
	cp a, 0xC0
	jr nz, SeqPart_FullLoadValidate

SeqPart_FullLoadProcess:
	ldto_berp A, 0xFA
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	bit_erpb 0xFA, 0x07
	jr nz, SeqPart_FullLoadCountCheck
	ldto_berp A, 0xFA
	extz wa
	call SeqPart_WriteByte_Primary
	jr SeqPart_FullLoadProcess

SeqPart_FullLoadValidate:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqPart_FullLoadCountCheck
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode1:
	cps a, 1
	jrl nz, SeqPart_FullLoadMode2
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode1Walk:
	lds iz, 0
	ldi_berp 0xFB, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, SeqPart_FullLoadMode1Done

SeqPart_FullLoadMode1Read:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	cp_erpb 0xFA, 0x82
	jr nz, SeqPart_FullLoadMode1Check81
	ldi_berp 0xFB, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Check81:
	ldto_berp A, 0xFA
	extz wa
	cp_erpb 0xFA, 0x81
	jr nz, SeqPart_FullLoadMode1Src
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz

SeqPart_FullLoadMode1Count:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jr nz, SeqPart_FullLoadMode1Read

SeqPart_FullLoadMode1Done:
	cpi_berp 0xFB, 1
	jrl z, SeqPart_FullLoadExit
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cpda16 xwa, 9694
	jr nz, SeqPart_FullLoadMode1Walk
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode1Src:
	ldto_berp C, 0xFA
	and c, 0xF0
	cp c, 0x90
	jr nz, SeqPart_FullLoadMode1Validate

SeqPart_FullLoadMode1Process:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	bit_erpb 0xFA, 0x07
	jr z, SeqPart_FullLoadMode1Process
	jr SeqPart_FullLoadMode1Count

SeqPart_FullLoadMode1Validate:
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr z, SeqPart_FullLoadMode1Count
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2:
	cpdi16 9694, 0
	jrl z, SeqPart_FullLoadExit

SeqPart_FullLoadMode2Walk:
	lds iz, 0
	ldi_berp 0xFB, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jrl z, SeqPart_FullLoadMode2Validate

SeqPart_FullLoadMode2Read:
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	cp_erpb 0xFA, 0x82
	jr nz, SeqPart_FullLoadMode2Check81
	ldi_berp 0xFB, 1
	jrl SeqPart_FullLoadExit

SeqPart_FullLoadMode2Check81:
	cp_erpb 0xFA, 0x81
	jr nz, SeqPart_FullLoadMode2Count
	ldto_berp A, 0xFA
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	inc 1, iz
	jr SeqPart_FullLoadMode2Done

SeqPart_FullLoadMode2Count:
	ldto_berp C, 0xFA
	and c, 0xF0
	cp c, 0x90
	jr z, SeqPart_FullLoadMode2Process
	ldda8 a, 9780
	cpda8 a, 10381
	jr z, SeqPart_FullLoadMode2Src
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Src:
	cp c, 0xC0
	jr z, SeqPart_FullLoadMode2Process
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqPart_FullLoadMode2Done
	jrl SeqPart_FullLoadErrorExit

SeqPart_FullLoadMode2Process:
	ldto_berp A, 0xFA
	extz wa
	call SeqPart_WriteByte_Primary
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jrl nz, SeqPart_FullLoadErrorExit
	call SeqPart_ReadByte_Secondary
	ldfr_berp L, 0xFA
	bit_erpb 0xFA, 0x07
	jr z, SeqPart_FullLoadMode2Process

SeqPart_FullLoadMode2Done:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jrl nz, SeqPart_FullLoadMode2Read

SeqPart_FullLoadMode2Validate:
	cpi_berp 0xFB, 1
	jr z, SeqPart_FullLoadExit
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	ld wa, (xsp + 4)
	cpda16 xwa, 9694
	jrl nz, SeqPart_FullLoadMode2Walk

SeqPart_FullLoadExit:
	ldada xwa, 10284
	ldmw2 (xwa), 0x288B
	ldmw2 (xwa + 2), 0x2889
	ldada xwa, 10292
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jr nz, SeqPart_FullLoadErrorExit
	ldada xde, 10292
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
	ldada xwa, 10292
	ld (xwa), hl
	ldw (xwa + 2), 0xFF

SeqPart_FullLoadWriteReturn:
	ldada xde, 10292
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ldda16 xwa, 10292
	call Part_CheckAndReallocVoices

SeqPart_FullLoadErrorExit:
	pop xiz
	inc 2, xsp
	ret

SeqPart_ByteBlockA95A:
	.byte 0xd7, 0xfa, 0x04, 0xc1, 0x79, 0x28, 0x21, 0xc9
	.byte 0x30, 0x00, 0xc9, 0x30, 0x01, 0xf1, 0x79, 0x28
	.byte 0x41, 0xf1, 0x9d, 0x28, 0xb0, 0xf1, 0x9d, 0x28
	.byte 0xb2, 0x1d, 0xfb, 0xfe, 0xf3, 0x1d, 0x26, 0xf6
	.byte 0xf3, 0xdb, 0xd8, 0x66, 0x0e, 0xf1, 0x7a, 0x28
	.byte 0x00, 0x03, 0x1e, 0x2d, 0x02, 0x30, 0x3d, 0x00
	.byte 0x78, 0xb1, 0x00, 0xf1, 0x7a, 0x28, 0x00, 0x00
	.byte 0xc1, 0x7b, 0x28, 0x27, 0xcf, 0x30, 0x06, 0xf1
	.byte 0x7b, 0x28, 0x47, 0xc1, 0x77, 0x28, 0x25, 0xcd
	.byte 0xcf, 0x7f, 0x76, 0x4d, 0x01, 0xf1, 0xa0, 0xf1
	.byte 0x31, 0xcd, 0x89, 0xc9, 0x69, 0xd8, 0x12, 0xe8
	.byte 0x12, 0xe9, 0x80, 0xc1, 0x82, 0x26, 0xf5, 0x76
	.byte 0xd6, 0x00, 0x80, 0x25, 0xcd, 0xcf, 0x10, 0x66
	.byte 0x0a, 0xcd, 0xcf, 0x0d, 0x66, 0x05, 0xcd, 0xcf
	.byte 0x0f, 0x6e, 0x0d, 0xf1, 0x7a, 0x28, 0x00, 0x09
	.byte 0x1e, 0xdf, 0x01, 0x30, 0x3e, 0x00, 0x68, 0x64
	.byte 0xcd, 0xcf, 0x0c, 0x6e, 0x06, 0xf1, 0x79, 0x28
	.byte 0xb9, 0x68, 0x04, 0xf1, 0x79, 0x28, 0xb1, 0xc1
	.byte 0x82, 0x26, 0x21, 0xc9, 0x69, 0xd8, 0x12, 0xe8
	.byte 0x12, 0xe9, 0x80, 0x80, 0x25, 0xcd, 0xcf, 0x10
	.byte 0x66, 0x0a, 0xcd, 0xcf, 0x0d, 0x66, 0x05, 0xcd
	.byte 0xcf, 0x0f, 0x6e, 0x0d, 0xf1, 0x7a, 0x28, 0x00
	.byte 0x09, 0x1e, 0xa6, 0x01, 0x30, 0x3f, 0x00, 0x68
	.byte 0x2b, 0xcd, 0xcf, 0x0c, 0x6e, 0x06, 0xf1, 0x79
	.byte 0x28, 0xb8, 0x68, 0x04, 0xf1, 0x79, 0x28, 0xb0
	.byte 0xc1, 0x77, 0x28, 0x19, 0x34, 0x26, 0xc1, 0x82
	.byte 0x26, 0x19, 0x52, 0x26, 0x1e, 0x9f, 0x01, 0xc1
	.byte 0x7a, 0x28, 0x3f, 0x00, 0x66, 0x0d, 0x1e, 0x79
	.byte 0x01, 0x30, 0x40, 0x00, 0x1d, 0xab, 0x39, 0xf4
	.byte 0x78, 0x6b, 0x01, 0xc1, 0x77, 0x28, 0x21, 0xc9
	.byte 0x69, 0xd8, 0x12, 0xf1, 0xa0, 0xf1, 0x31, 0xe8
	.byte 0x12, 0xe9, 0x80, 0x80, 0x25, 0xc1, 0x82, 0x26
	.byte 0x21, 0xc9, 0x69, 0xd8, 0x12, 0xe8, 0x12, 0xe9
	.byte 0x80, 0x80, 0x21, 0xc9, 0xf5, 0x76, 0x43, 0x01
	.byte 0xf1, 0x3a, 0x0d, 0x41, 0xd8, 0x12, 0xf2, 0xa4
	.byte 0x4b, 0xe4, 0x32, 0xc3, 0x07, 0xe8, 0xe0, 0x19
	.byte 0x7c, 0x28, 0xc1, 0x77, 0x28, 0x21, 0xc9, 0x69
	.byte 0xd8, 0x12, 0xe8, 0x12, 0xe9, 0x80, 0x80, 0x19
	.byte 0x32, 0x0d, 0x1e, 0x3e, 0x01, 0x78, 0x1b, 0x01
	.byte 0x80, 0x25, 0xcd, 0xcf, 0x0d, 0x66, 0x05, 0xcd
	.byte 0xcf, 0x10, 0x6e, 0x1e, 0xcd, 0xcf, 0x10, 0x6e
	.byte 0x07, 0xcf, 0x31, 0x06, 0xf1, 0x7b, 0x28, 0x47
	.byte 0xc1, 0x77, 0x28, 0x21, 0xd8, 0x12, 0x1d, 0x57
	.byte 0xff, 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x7e
	.byte 0xf1, 0x00, 0xc1, 0x77, 0x28, 0x19, 0x34, 0x26
	.byte 0xc1, 0x77, 0x28, 0x19, 0x52, 0x26, 0xf1, 0x7b
	.byte 0x28, 0xce, 0x66, 0x20, 0xc1, 0x77, 0x28, 0x23
	.byte 0xcb, 0x69, 0xd9, 0x12, 0xf1, 0xa0, 0xf1, 0x30
	.byte 0xe9, 0x12, 0xe8, 0x81, 0x81, 0x3f, 0x10, 0x6e
	.byte 0x0b, 0x1e, 0xf8, 0x05, 0xc1, 0x7a, 0x28, 0x3f
	.byte 0x00, 0x7e, 0xbf, 0x00, 0x1e, 0xa1, 0x02, 0x78
	.byte 0xb9, 0x00, 0xc7, 0xfb, 0xa9, 0xc7, 0xfb, 0x8b
	.byte 0xcb, 0x69, 0xd9, 0x12, 0xf1, 0xa0, 0xf1, 0x30
	.byte 0xe9, 0x12, 0xe8, 0x81, 0x81, 0x25, 0xcd, 0xcf
	.byte 0x0d, 0x66, 0x05, 0xcd, 0xcf, 0x10, 0x6e, 0x1a
	.byte 0xcd, 0xcf, 0x10, 0x6e, 0x04, 0xf1, 0x7b, 0x28
	.byte 0xbe, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0x1d, 0x57
	.byte 0xff, 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x7e
	.byte 0x81, 0x00, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf
	.byte 0x10, 0x63, 0xc2, 0x1d, 0x5d, 0x04, 0xf4, 0xc1
	.byte 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x6d, 0xf1, 0x36
	.byte 0x26, 0x00, 0x00, 0xc7, 0xfb, 0xa9, 0xc7, 0xfb
	.byte 0x89, 0xf1, 0x34, 0x26, 0x41, 0xc7, 0xfb, 0x89
	.byte 0xf1, 0x52, 0x26, 0x41, 0xf1, 0x7b, 0x28, 0xce
	.byte 0x66, 0x23, 0xc7, 0xfb, 0x8b, 0xcb, 0x69, 0xd9
	.byte 0x12, 0xf1, 0xa0, 0xf1, 0x30, 0xe9, 0x12, 0xe8
	.byte 0x81, 0x81, 0x3f, 0x10, 0x6e, 0x0f, 0xf1, 0x7a
	.byte 0x28, 0x00, 0x00, 0x1e, 0x66, 0x05, 0xc1, 0x7a
	.byte 0x28, 0x3f, 0x00, 0x6e, 0x03, 0x1e, 0x10, 0x02
	.byte 0xc1, 0x7a, 0x28, 0x21, 0xc9, 0xd8, 0x66, 0x14
	.byte 0xc9, 0xd9, 0x66, 0x10, 0xc9, 0xcf, 0x08, 0x66
	.byte 0x0b, 0xc1, 0x36, 0x26, 0x3f, 0x00, 0x6e, 0x04
	.byte 0xf1, 0x36, 0x26, 0x41, 0xc7, 0xfb, 0x61, 0xc7
	.byte 0xfb, 0xcf, 0x10, 0x63, 0xa1, 0xc1, 0x36, 0x26
	.byte 0x19, 0x7a, 0x28, 0x1e, 0x04, 0x00, 0xd7, 0xfa
	.byte 0x05, 0x0e, 0x1d, 0x26, 0xff, 0xf3, 0x1d, 0x1a
	.byte 0xff, 0xf3, 0xf1, 0x79, 0x28, 0xb0, 0xf1, 0x79
	.byte 0x28, 0xb1, 0xf1, 0x9d, 0x28, 0xb0, 0xf1, 0x9d
	.byte 0x28, 0xb2, 0x0e

SeqPart_DualCopySetup:
	jrl SeqPart_MultiPartWalker
	resda 3, 10363
	stdi8 10362, 0
	ldda8 a, 9810
	extz wa
	stda16 10365, xwa
	ldda8 a, 9810
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyCheck
	ldw wa, 0x41
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyCheck:
	ldmm16 9822, 9830
	ldmm16 9820, 10415
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9810
	ldmm16 10367, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyInit
	ldw wa, 0x42
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyInit:
	ldmm16 10373, 9830
	ldmm16 10375, 10415
	ldda8 l, 10381
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyProcess
	ldw wa, 0x42
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyProcess:
	ldmm16 9906, 9830
	ldmm16 9904, 10415
	call SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_DualCopyAdvance
	cps a, 7
	jr z, SeqPart_DualCopyValidate
	ldw wa, 0x43
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyValidate:
	setda 3, 10363
	stdi8 10362, 0

SeqPart_DualCopyAdvance:
	ldmm16 9898, 9830
	ldmm16 9896, 10415
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyFinish
	ldw wa, 0x44
	jrl SeqPart_DualCopyJumpExit

SeqPart_DualCopyFinish:
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	ld c, a
	extz bc
	ldda16 xwa, 9900
	call Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldada xwa, 10292
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	call SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyReturn
	ldw wa, 0x45
	jr SeqPart_DualCopyJumpExit

SeqPart_DualCopyReturn:
	ldmm16 10426, 9896
	ldmm16 10428, 9898
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr ugt, SeqPart_DualCopyErrorCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	ldw (xwa + 2), 0xFF
	jr SeqPart_DualCopyErrorExit

SeqPart_DualCopyErrorCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_DualCopyErrorExit:
	ldada xwa, 10284
	ldmw2 (xwa), 0x28BA
	ldmw2 (xwa + 2), 0x28BC
	ldada xhl, 10288
	ldada xde, 10292
	ld wa, (xde)
	ld (xhl), wa
	lda xbc, (xde + 2)
	ld wa, (xbc)
	ld (xhl + 2), wa
	mriw4 0x92, 0x19, 0xA4, 0x26
	mriw4 0x91, 0x19, 0xA6, 0x26
	ldmw2 (xde), 0x26B0
	ldmw2 (xbc), 0x26B2
	call SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jr z, SeqPart_DualCopyBit3Check
	ldw wa, 0x46

SeqPart_DualCopyJumpExit:
	jp SeqData_SetErrorCode

SeqPart_DualCopyBit3Check:
	bitda 3, 10363
	ret z
	ldda16 xwa, 9894
	ld c, a
	extz bc
	ldda16 xwa, 9892
	call Part_WriteWordAndByte
	ldda16 xwa, 9892
	jp Part_CheckAndReallocVoices
SeqPart_ByteBlockAD92:
	.byte 0xd1, 0x32, 0x26, 0x20, 0xd1, 0x86, 0x26, 0xf0
	.byte 0x73, 0x33, 0xfe, 0xf1, 0x7b, 0x28, 0xb3, 0xf1
	.byte 0x7a, 0x28, 0x00, 0x00, 0xc1, 0x52, 0x26, 0x21
	.byte 0xd8, 0x12, 0xf1, 0x7d, 0x28, 0x50, 0xc1, 0x52
	.byte 0x26, 0x21, 0xd8, 0x12, 0x1d, 0xbb, 0xfc, 0xf3
	.byte 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xd1
	.byte 0x66, 0x26, 0x19, 0x5e, 0x26, 0xd1, 0xaf, 0x28
	.byte 0x19, 0x5c, 0x26, 0x1d, 0xa7, 0x00, 0xf4, 0xc1
	.byte 0x52, 0x26, 0x21, 0xd1, 0x86, 0x26, 0x19, 0x7f
	.byte 0x28, 0xd8, 0x12, 0xdb, 0x12, 0xdb, 0x89, 0x1d
	.byte 0x4c, 0xfe, 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00
	.byte 0xb0, 0xfe, 0xd1, 0x66, 0x26, 0x19, 0x85, 0x28
	.byte 0xd1, 0xaf, 0x28, 0x19, 0x87, 0x28, 0xc1, 0x8d
	.byte 0x28, 0x27, 0xc1, 0x34, 0x26, 0x21, 0xd1, 0x32
	.byte 0x26, 0x19, 0x7f, 0x28, 0xd8, 0x12, 0xdb, 0x12
	.byte 0xdb, 0x89, 0x1d, 0x4c, 0xfe, 0xf3, 0xc1, 0x7a
	.byte 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xd1, 0x66, 0x26
	.byte 0x19, 0xb2, 0x26, 0xd1, 0xaf, 0x28, 0x19, 0xb0
	.byte 0x26, 0x1d, 0xe0, 0xff, 0xf3, 0xc1, 0x7a, 0x28
	.byte 0x21, 0xc9, 0xd8, 0x66, 0x0d, 0xc9, 0xdf, 0xb0
	.byte 0xfe, 0xf1, 0x7b, 0x28, 0xbb, 0xf1, 0x7a, 0x28
	.byte 0x00, 0x00, 0xd1, 0x66, 0x26, 0x19, 0xaa, 0x26
	.byte 0xd1, 0xaf, 0x28, 0x19, 0xa8, 0x26, 0xd1, 0x5c
	.byte 0x26, 0x19, 0x9c, 0x26, 0xd1, 0x5e, 0x26, 0x19
	.byte 0xa2, 0x26, 0x1d, 0xad, 0x06, 0xf4, 0xc1, 0x7a
	.byte 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xd1, 0xb8, 0x26
	.byte 0x19, 0xac, 0x26, 0xe1, 0xba, 0x26, 0x20, 0xf1
	.byte 0xae, 0x26, 0x50, 0xc9, 0x8b, 0xd9, 0x12, 0xd1
	.byte 0xac, 0x26, 0x20, 0x1d, 0x9f, 0x03, 0xf4, 0xf1
	.byte 0x2c, 0x28, 0x30, 0xb0, 0x16, 0x5c, 0x26, 0xb8
	.byte 0x02, 0x16, 0x5e, 0x26, 0xf1, 0x30, 0x28, 0x30
	.byte 0xb0, 0x16, 0xac, 0x26, 0xb8, 0x02, 0x16, 0xae
	.byte 0x26, 0xf1, 0x34, 0x28, 0x30, 0xb0, 0x16, 0x87
	.byte 0x28, 0xb8, 0x02, 0x16, 0x85, 0x28, 0x1d, 0x0f
	.byte 0x06, 0xf4, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0xb0
	.byte 0xfe, 0x40, 0xb0, 0x26, 0x00, 0x00, 0x41, 0xb2
	.byte 0x26, 0x00, 0x00, 0x1d, 0x3c, 0x10, 0xf4, 0xc1
	.byte 0x7a, 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0x40, 0xa8
	.byte 0x26, 0x00, 0x00, 0x41, 0xaa, 0x26, 0x00, 0x00
	.byte 0x1d, 0x3c, 0x10, 0xf4, 0xc1, 0x7a, 0x28, 0x3f
	.byte 0x00, 0xb0, 0xfe, 0xf1, 0x2c, 0x28, 0x30, 0xb0
	.byte 0x16, 0xb0, 0x26, 0xb8, 0x02, 0x16, 0xb2, 0x26
	.byte 0xf1, 0x30, 0x28, 0x30, 0xb0, 0x16, 0x87, 0x28
	.byte 0xb8, 0x02, 0x16, 0x85, 0x28, 0xf1, 0x34, 0x28
	.byte 0x30, 0xb0, 0x16, 0xa8, 0x26, 0xb8, 0x02, 0x16
	.byte 0xaa, 0x26, 0x1d, 0x65, 0x05, 0xf4, 0xc1, 0x7a
	.byte 0x28, 0x3f, 0x00, 0xb0, 0xfe, 0xf1, 0x7b, 0x28
	.byte 0xcb, 0xb0, 0xf6, 0xf1, 0x34, 0x28, 0x32, 0xba
	.byte 0x02, 0x31, 0x91, 0x20, 0xd8, 0xdd, 0x66, 0x06
	.byte 0xd8, 0x69, 0xb1, 0x50, 0x68, 0x15, 0x92, 0x20
	.byte 0x1d, 0x39, 0x1c, 0xf4, 0xdb, 0xd8, 0xb0, 0xf6
	.byte 0xf1, 0x34, 0x28, 0x30, 0xb0, 0x53, 0xb8, 0x02
	.byte 0x02, 0xff, 0x00, 0xf1, 0x34, 0x28, 0x32, 0x9a
	.byte 0x02, 0x20, 0xc9, 0x8b, 0xd9, 0x12, 0x92, 0x20
	.byte 0x1d, 0x9f, 0x03, 0xf4, 0xd1, 0x34, 0x28, 0x20
	.byte 0x1b, 0xe2, 0x25, 0xf4

SeqPart_MultiPartWalker:
	push xiz
	stdi8 10362, 0
	ldda8 e, 10381
	ldda8 l, 9858
	ldda8 a, 10359
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	mrib4 0x80, 0x19, 0x73, 0x28
	ldmm16 10367, 9862
	extz hl
	extz de
	ld wa, hl
	ld bc, de
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_WalkerExit
	ldda16 xwa, 10415
	stda16 10375, xwa
	ldda16 xwa, 9830
	stda16 10373, xwa
	ldmm16 10379, 10415
	ldmm16 10377, 9830
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_WalkerNote

SeqPart_WalkerLoop:
	ldi_werp 0xFA, 0
	ldda8 a, 10382
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
	inc1_werp 0xFA

SeqPart_WalkerD0:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, SeqPart_WalkerCheckType

SeqPart_WalkerD1D2D3:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cpda16 xiz, 9694
	jr nz, SeqPart_WalkerLoop

SeqPart_WalkerNote:
	ldada xwa, 10284
	ldmw2 (xwa), 0x288B
	ldmw2 (xwa + 2), 0x2889
	ldada xwa, 10288
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	ldda8 c, 9858
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	stda16 10292, xhl
	ldda8 c, 9858
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	stda16 10294, xhl
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jr z, SeqPart_WalkerNextSet
	jrl SeqPart_WalkerExit

SeqPart_WalkerB0:
	cp l, 0xD2
	jr z, SeqPart_WalkerC0
	cp l, 0xD1
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
	and l, 0xF0
	cp l, 0x90
	jr nz, SeqPart_WalkerBoundary
	calr SeqStep_SkipInvertedB
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerBoundary:
	cp l, 0xB0
	jr nz, SeqPart_WalkerEndCheck
	calr SeqStep_ProcessB0
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerEndCheck:
	cp l, 0xC0
	jr nz, SeqPart_WalkerAdvance
	calr SeqStep_ProcessC0
	cps hl, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerAdvance:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jrl z, SeqPart_WalkerD0
	jr SeqPart_WalkerExit

SeqPart_WalkerNextSet:
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr ugt, SeqPart_WalkerComplete
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	ldw (xwa + 2), 0xFF
	jr SeqPart_WalkerReturn

SeqPart_WalkerComplete:
	dec 1, wa
	ld (xbc), wa

SeqPart_WalkerReturn:
	ldada xde, 10292
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ldda16 xwa, 10292
	call Part_CheckAndReallocVoices

SeqPart_WalkerExit:
	pop xiz
	ret

SeqPart_ByteBlockB0DE:
	.byte 0x1d, 0xe4, 0x0a, 0xf4, 0x1d, 0xa7, 0x00, 0xf4
	.byte 0xcf, 0xd8, 0x76, 0xe2, 0x00, 0xf1, 0x40, 0x27
	.byte 0x47, 0xcf, 0x89, 0xd8, 0x12, 0xf1, 0x7d, 0x28
	.byte 0x50, 0xdb, 0x12, 0xdb, 0x88, 0x1d, 0xbb, 0xfc
	.byte 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x7e, 0xc6
	.byte 0x00, 0xd1, 0x66, 0x26, 0x19, 0x5e, 0x26, 0xd1
	.byte 0xaf, 0x28, 0x19, 0x5c, 0x26, 0xc1, 0x40, 0x27
	.byte 0x27, 0xd1, 0x32, 0x26, 0x19, 0x7f, 0x28, 0xdb
	.byte 0x12, 0xdb, 0x88, 0xdb, 0x89, 0x1d, 0x4c, 0xfe
	.byte 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x7e, 0x9e
	.byte 0x00, 0x1d, 0xa6, 0x21, 0xf4, 0xcf, 0xcf, 0x82
	.byte 0x76, 0x94, 0x00, 0xd1, 0x66, 0x26, 0x19, 0xd2
	.byte 0x26, 0xd1, 0xaf, 0x28, 0x19, 0xd4, 0x26, 0xf1
	.byte 0xda, 0x26, 0x02, 0x01, 0x00, 0xd1, 0x32, 0x26
	.byte 0x20, 0xd8, 0x69, 0xf1, 0xdc, 0x26, 0x50, 0x40
	.byte 0x2c, 0x27, 0x00, 0x00, 0x1d, 0xfd, 0x0a, 0xf4
	.byte 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x68, 0xd1
	.byte 0x86, 0x26, 0x20, 0xd1, 0x32, 0x26, 0xf8, 0x66
	.byte 0x4e, 0xc1, 0x40, 0x27, 0x27, 0xf1, 0x7f, 0x28
	.byte 0x50, 0xdb, 0x12, 0xdb, 0x88, 0xdb, 0x89, 0x1d
	.byte 0x4c, 0xfe, 0xf3, 0xc1, 0x7a, 0x28, 0x3f, 0x00
	.byte 0x6e, 0x45, 0x1d, 0xa6, 0x21, 0xf4, 0xcf, 0xcf
	.byte 0x82, 0x66, 0x2c, 0xd1, 0x66, 0x26, 0x19, 0xd6
	.byte 0x26, 0xd1, 0xaf, 0x28, 0x19, 0xd8, 0x26, 0xf1
	.byte 0xda, 0x26, 0x02, 0x01, 0x00, 0xd1, 0x86, 0x26
	.byte 0x20, 0xd8, 0x69, 0xf1, 0xdc, 0x26, 0x50, 0x40
	.byte 0x32, 0x27, 0x00, 0x00, 0x1d, 0xfd, 0x0a, 0xf4
	.byte 0xc1, 0x7a, 0x28, 0x3f, 0x00, 0x6e, 0x10, 0xd1
	.byte 0x32, 0x26, 0x19, 0xde, 0x26, 0xd1, 0x86, 0x26
	.byte 0x19, 0xe0, 0x26, 0x1d, 0xe0, 0x10, 0xf4, 0x1b
	.byte 0x46, 0x3a, 0xf4

SeqPart_DualPartLoad:
	push_werp 0xFA
	ldda8 a, 10361
	res 0, a
	res 1, a
	stda8 10361, a
	resda 0, 10397
	resda 2, 10397
	call SeqVoice_SetDefaultParams
	call LABEL_F3F66D
	cps hl, 0
	jr z, SeqPart_DualLoadSetup
	stdi8 10362, 3
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadSetup:
	stdi8 10362, 0
	ldda8 l, 10363
	res 6, l
	stda8 10363, l
	ldda8 e, 10359
	cp e, 0x7F
	jrl nz, SeqPart_DualLoadReturn
	ldi_berp 0xFB, 0

SeqPart_DualLoadCheck:
	ldto_berp C, 0xFB
	extz bc
	ldada xwa, 61856
	extz xbc
	add xbc, xwa
	ld e, (xbc)
	cp e, 0xD
	jr z, SeqPart_DualLoadInit
	cp e, 0x10
	jr nz, SeqPart_DualLoadEvent

SeqPart_DualLoadInit:
	cp e, 0x10
	jr nz, SeqPart_DualLoadLoop
	setda 6, 10363

SeqPart_DualLoadLoop:
	ldto_berp A, 0xFB
	inc 1, a
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cpdi8 10362, 0
	jrl nz, SeqPart_DualLoadExit

SeqPart_DualLoadEvent:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, SeqPart_DualLoadCheck
	call LABEL_F4077D
	cpdi8 10362, 0
	jrl nz, SeqPart_DualLoadExit
	stdi8 9782, 0
	ldi_berp 0xFB, 1
	cpdi8 10401, 1
	jr c, SeqPart_DualLoadComplete

SeqPart_DualLoadValidate:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	stda8 9810, a
	bitda 6, 10363
	jr z, SeqPart_DualLoadAdvance
	ldto_berp C, 0xFB
	dec 1, c
	extz bc
	ldada xwa, 61856
	extz xbc
	add xbc, xwa
	cp (xbc), 0x10
	jr nz, SeqPart_DualLoadAdvance
	stdi8 10362, 0
	calr SeqPart_DrumPartHandler

SeqPart_DualLoadAdvance:
	calr SeqPart_MainNavigate
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_DualLoadFinish
	cps a, 1
	jr z, SeqPart_DualLoadFinish
	cp a, 0x8
	jr z, SeqPart_DualLoadFinish
	cpdi8 9782, 0
	jr nz, SeqPart_DualLoadFinish
	stda8 9782, a

SeqPart_DualLoadFinish:
	inc1_berp 0xFB
	ldto_berp A, 0xFB
	cpda8 a, 10401
	jr ule, SeqPart_DualLoadValidate

SeqPart_DualLoadComplete:
	ldmm8 10362, 9782
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadReturn:
	ld a, e
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	cpda8 e, 9858
	jrl z, SeqPart_DualLoadPartBCheck
	ld e, (xwa)
	cp e, 0x10
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xF
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xD
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xC
	jr nz, SeqPart_DualLoadCleanup
	setda 1, 10361
	jr SeqPart_DualLoadFinal

SeqPart_DualLoadCleanup:
	resda 1, 10361

SeqPart_DualLoadFinal:
	ldda8 a, 9858
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld e, (xwa)
	cp e, 0x10
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xF
	jr z, SeqPart_DualLoadErrorCheck
	cp e, 0xD
	jr nz, SeqPart_DualLoadPartA

SeqPart_DualLoadErrorCheck:
	stdi8 10362, 9
	jrl SeqPart_DualLoadExit

SeqPart_DualLoadPartA:
	cp e, 0xC
	jr nz, SeqPart_DualLoadPartADone
	setda 0, 10361
	jr SeqPart_DualLoadPartB

SeqPart_DualLoadPartADone:
	resda 0, 10361

SeqPart_DualLoadPartB:
	ldmm8 9780, 10359
	ldmm8 9810, 9858
	calr SeqPart_Exchange
	cpdi8 10362, 0
	jrl nz, SeqPart_DualLoadExit
	ldda8 a, 10359
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld e, (xwa)
	ldda8 a, 9858
	dec 1, a
	extz wa
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp e, a
	jr z, SeqPart_DualLoadExit
	stda8 3386, a
	extz wa
	lda_24 xbc, 0xe44ba4
	ldmm_srib 0x07, 0xE4, 0xE0, 0x7C, 0x28
	stda8 3378, e
	calr SeqPart_DualCopySetup
	jr SeqPart_DualLoadExit

SeqPart_DualLoadPartBCheck:
	ld e, (xwa)
	cp e, 0xD
	jr z, SeqPart_DualLoadPartBInit
	cp e, 0x10
	jr nz, SeqPart_DualLoadPartBFinish

SeqPart_DualLoadPartBInit:
	cp e, 0x10
	jr nz, SeqPart_DualLoadPartBRun
	set 6, l
	stda8 10363, l

SeqPart_DualLoadPartBRun:
	ldda8 a, 10359
	extz wa
	call Part_ValidateAndSetupVoiceChannel
	cpdi8 10362, 0
	jr nz, SeqPart_DualLoadExit

SeqPart_DualLoadPartBFinish:
	ldmm8 9780, 10359
	ldmm8 9810, 10359
	bitda 6, 10363
	jr z, SeqPart_DualLoadNavigate
	ldda8 c, 10359
	dec 1, c
	extz bc
	ldada xwa, 61856
	extz xbc
	add xbc, xwa
	cp (xbc), 0x10
	jr nz, SeqPart_DualLoadNavigate
	calr SeqPart_DrumPartHandler
	cpdi8 10362, 0
	jr nz, SeqPart_DualLoadExit

SeqPart_DualLoadNavigate:
	calr SeqPart_MainNavigate

SeqPart_DualLoadExit:
	call LABEL_F3FF2D
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_DrumPartHandler:
	call LABEL_F40AE4
	call SeqVoice_FindDrumPartIndex
	cps l, 0
	jrl z, SeqPart_DrumPartJumpExit
	stda8 10048, l
	ld a, l
	extz wa
	stda16 10365, xwa
	extz hl
	ld wa, hl
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_DrumPartJumpExit
	ldmm16 9822, 9830
	ldmm16 9820, 10415
	ldda16 xwa, 9778
	cpda16 xwa, 9862
	jrl z, SeqPart_DrumPartJumpExit
	ldda8 l, 10048
	stda16 10367, xwa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_DrumPartJumpExit
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_DrumPartJumpExit
	ldmm16 9938, 9830
	ldmm16 9940, 10415
	stdi16 9946, 1
	ldda16 xwa, 9778
	dec 1, wa
	stda16 9948, xwa
	ld xwa, 0x272C
	call SeqVoice_SeekAndScanTracks
	cpdi8 10362, 0
	jrl nz, SeqPart_DrumPartJumpExit
	ldda16 xwa, 9862
	ld de, wa
	ldda16 xbc, 9694
	add de, bc
	cpda16 xde, 9778
	jr z, SeqPart_DrumPartBoundary
	ldda8 l, 10048
	addda16 xwa, 9694
	stda16 10367, xwa
	extz hl
	ld wa, hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_DrumPartExtended
	cp a, 0x8
	jr nz, SeqPart_DrumPartJumpExit
	stdi8 10362, 0

SeqPart_DrumPartBoundary:
	ldmm16 9950, 9778
	ldmm16 9952, 9862
	ldda16 xwa, 9694
	adddm16 9952, xwa
	call LABEL_F410E0
	jr SeqPart_DrumPartJumpExit

SeqPart_DrumPartExtended:
	call SeqData_ReadNextByte
	cp l, 0x82
	jr z, SeqPart_DrumPartBoundary
	ldmm16 9942, 9830
	ldmm16 9944, 10415
	stdi16 9946, 1
	ldda16 xwa, 9862
	addda16 xwa, 9694
	dec 1, wa
	stda16 9948, xwa
	ld xwa, 0x2732
	call SeqVoice_SeekAndScanTracks
	cpdi8 10362, 0
	jr z, SeqPart_DrumPartBoundary

SeqPart_DrumPartJumpExit:
	jp SeqPlay_WriteErrorToVoiceTable

SeqPart_Exchange:
	pushw iz
	ldda8 a, 10363
	res 3, a
	res 4, a
	res 7, a
	stda8 10363, a
	stdi8 10362, 0
	ldda8 a, 9810
	cpda8 a, 9780
	jr z, SeqPart_ExchangeProcess
	extz wa
	call Part_ValidateVoiceChannel
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_ExchangeProcess
	cps a, 1
	jrl nz, SeqPart_ExchangeCleanup
	stdi8 10362, 0
	cpdi8 7528, 1
	jr nc, SeqPart_ExchangeInit
	stdi8 10362, 5
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeInit:
	call Part_ProcessAndDecrementVoice
	ld iz, hl
	ldda8 c, 9810
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteWord_Indexed
	ldda8 c, 9810
	extz bc
	lds wa, 0
	lds de, 5
	call Part_WriteByte_Indexed
	ldda8 c, 9810
	extz bc
	lds wa, 0
	lds de, 1
	call Part_SetClearVoiceBit7
	ldda8 c, 9810
	extz bc
	lds wa, 0
	ld de, iz
	call Part_WriteVoiceWord
	ld wa, iz
	lds bc, 0
	call PartCtrl_WriteWord_Off1
	ld wa, iz
	ldw bc, 0xFFFF
	call PartCtrl_WriteWord
	setda 7, 10363

SeqPart_ExchangeProcess:
	ldda8 a, 9810
	extz wa
	stda16 10365, xwa
	ldda8 a, 9810
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_ExchangeCleanup
	ldda16 xwa, 9830
	stda16 9822, xwa
	ldda16 xwa, 10415
	stda16 9820, xwa
	ldda8 a, 9810
	dec 1, a
	extz wa
	add wa, wa
	ldada xbc, 3343
	ldmmw_dri 0x07, 0xE4, 0xE0, 0x66, 0x26
	ldda8 a, 9810
	dec 1, a
	extz wa
	add wa, wa
	ldada xbc, 3311
	ldmmw_dri 0x07, 0xE4, 0xE0, 0xAF, 0x28
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_ExchangeCleanup
	ldmm16 9906, 9830
	ldmm16 9904, 10415
	call SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_ExchangeValidate
	cps a, 7
	jrl nz, SeqPart_ExchangeCleanup
	setda 3, 10363
	stdi8 10362, 0

SeqPart_ExchangeValidate:
	ldmm16 9898, 9830
	ldmm16 9896, 10415
	ldda32 xwa, 9690
	stda32 10208, xwa
	resda 0, 10282
	ldda8 l, 10381
	ldda8 a, 9810
	ldmm16 10367, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_ExchangeCheckDone
	cp a, 0x8
	jrl nz, SeqPart_ExchangeCleanup
	calr SeqPart_Splice
	cpdi8 10362, 0
	jr z, SeqPart_ExchangeAdvance
	calr SeqPart_RestoreState
	jrl SeqPart_ExchangeCleanup

SeqPart_ExchangeAdvance:
	ldmm16 10415, 10379
	ldmm16 9830, 10377
	setda 0, 10282
	ldda8 c, 9810
	extz bc
	lds wa, 0
	call Part_ReadByte_Indexed
	stda16 9822, xhl
	ldda8 c, 9810
	extz bc
	lds wa, 0
	call Part_ReadWord_Indexed
	stda16 9820, xhl

SeqPart_ExchangeCheckDone:
	ldmm16 10373, 9830
	ldmm16 10375, 10415
	call SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_ExchangeUpdate
	cps a, 7
	jr nz, SeqPart_ExchangeCleanup
	setda 4, 10363
	stdi8 10362, 0

SeqPart_ExchangeUpdate:
	ldmm16 10218, 9830
	ldmm16 10216, 10415
	ldda32 xwa, 9690
	stda32 10212, xwa
	ldda32 xbc, 10208
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
	cpdi8 10362, 0
	jr nz, SeqPart_ExchangeJump
	ldada xwa, 10284
	ldmw2 (xwa), 0x26A8
	ldmw2 (xwa + 2), 0x26AA
	ldada xwa, 10288
	ldmw2 (xwa), 0x27EC
	ldmw2 (xwa + 2), 0x27EE
	ldada xwa, 10292
	ldmw2 (xwa), 0x26B0
	ldmw2 (xwa + 2), 0x26B2
	call SeqPart_CopyDataSecondary

SeqPart_ExchangeCleanup:
	calr SeqPart_UndoAllocOnError

SeqPart_ExchangeJump:
	popw iz
	ret

SeqPart_PositionForward:
	ldda32 xwa, 10212
	subdm32 9690, xwa
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	ldda8 a, 10363
	bit 4, a
	jr z, SeqPart_PosForwardLoop
	bit 3, a
	jr nz, SeqPart_PosForwardLoop
	lds32 xwa, 1
	adddm32 9690, xwa

SeqPart_PosForwardLoop:
	call SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jr z, SeqPart_PosForwardStep
	bitda 0, 10282
	jrl z, SeqPart_PosForwardReturn
	calr SeqPart_RestoreState
	jrl SeqPart_PosForwardReturn

SeqPart_PosForwardStep:
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	ld c, a
	extz bc
	ldda16 xwa, 9900
	call Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldada xwa, 10292
	ldmw2 (xwa), 0x27E8
	ldmw2 (xwa + 2), 0x27EA
	call SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, SeqPart_PosForwardReturn
	ldada xwa, 10292
	mriw4 0x90, 0x19, 0xEC, 0x27
	ld bc, (xwa + 2)
	stda16 10222, xbc
	ldda8 e, 10363
	bit 4, e
	ret z
	bit 3, e
	jr nz, SeqPart_PosForwardCheck
	dec 1, bc
	stda16 10222, xbc
	cps bc, 4
	ret ugt
	ldda16 xwa, 10220
	call PartCtrl_ReadWord_Off1
	stda16 10220, xhl
	ldda16 xwa, 10220
	cps wa, 0
	jr z, SeqPart_PosForwardValidate
	stdi16 10222, 255
	ret

SeqPart_PosForwardCheck:
	ldda8 a, 10359
	cp a, 0x7F
	jr z, SeqPart_PosForwardDone
	cpda8 a, 9858
	ret nz

SeqPart_PosForwardDone:
	bitda 0, 10282
	ret z
	bit 3, e
	ret z
	dec 1, bc
	stda16 10222, xbc
	cps bc, 4
	jr ugt, SeqPart_PosForwardUpdate
	ldda16 xwa, 10220
	call PartCtrl_ReadWord_Off1
	stda16 10220, xhl
	ldda16 xwa, 10220
	cps wa, 0
	jr z, SeqPart_PosForwardValidate
	stdi16 10222, 255

SeqPart_PosForwardUpdate:
	ldda16 xwa, 9898
	dec 1, wa
	stda16 9898, xwa
	cps wa, 4
	ret ugt
	ldda16 xwa, 9896
	call PartCtrl_ReadWord_Off1
	stda16 9896, xhl
	ldda16 xwa, 9896
	cps wa, 0
	jr nz, SeqPart_PosForwardError

SeqPart_PosForwardValidate:
	stdi8 10362, 11

SeqPart_PosForwardReturn:
	jrl SeqPart_UndoAllocOnError

SeqPart_PosForwardError:
	stdi16 9898, 255
	ret

SeqPart_PositionBackward:
	ldda32 xwa, 9690
	ldda32 xbc, 10212
	sub xbc, xwa
	ldda8 a, 10363
	bit 4, a
	jr z, SeqPart_PosBackwardLoop
	bit 3, a
	jr nz, SeqPart_PosBackwardLoop
	dec 1, xbc

SeqPart_PosBackwardLoop:
	stda32 9690, xbc
	ldmm16 10220, 10216
	ldmm16 10222, 10218
	ld xwa, 0x27EC
	ld xbc, 0x27EE
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_PosBackwardReturn
	ldada xwa, 10284
	ldmw2 (xwa), 0x27E8
	ldmw2 (xwa + 2), 0x27EA
	ldada xwa, 10288
	ldmw2 (xwa), 0x27EC
	ldmw2 (xwa + 2), 0x27EE
	ldada xwa, 10292
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jrl nz, SeqPart_PosBackwardReturn
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr nz, SeqPart_PosBackwardCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_PosBackwardReturn
	ldw (xwa + 2), 0xFF
	jr SeqPart_PosBackwardDone

SeqPart_PosBackwardCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_PosBackwardDone:
	bitda 3, 10363
	jr z, SeqPart_PosBackwardUpdate
	ldmm16 9822, 10222
	ldmm16 9820, 10220

SeqPart_PosBackwardUpdate:
	ldda16 xwa, 9822
	ld c, a
	extz bc
	ldda16 xwa, 9820
	call Part_WriteWordAndByte
	ldda16 xwa, 9820
	call Part_CheckAndReallocVoices
	cpdi8 10362, 0
	jr nz, SeqPart_PosBackwardReturn
	ldda8 a, 10363
	bit 4, a
	ret z
	bit 3, a
	ret nz
	ldda16 xwa, 10222
	dec 1, wa
	stda16 10222, xwa
	cps wa, 5
	ret nc
	ldda16 xwa, 10220
	call PartCtrl_ReadWord_Off1
	stda16 10220, xhl
	ldda16 xwa, 10220
	cps wa, 0
	jr nz, SeqPart_PosBackwardValidate
	stdi8 10362, 10
	jr SeqPart_PosBackwardReturn

SeqPart_PosBackwardValidate:
	call PartCtrl_TestBit7
	cps l, 0
	ret nz
	stdi8 10362, 11

SeqPart_PosBackwardReturn:
	calr SeqPart_UndoAllocOnError
	ret

SeqPart_PositionEqual:
	ldda16 xbc, 10218
	ldda8 a, 10359
	cp a, 0x7F
	jr z, SeqPart_PosEqualSpecial
	cpda8 a, 9858
	jr nz, SeqPart_PosEqualStore

SeqPart_PosEqualSpecial:
	bitda 0, 10282
	jr z, SeqPart_PosEqualStore
	bitda 3, 10363
	jr z, SeqPart_PosEqualStore
	dec 1, bc
	cps bc, 4
	jr ugt, SeqPart_PosEqualStore
	ldda16 xwa, 10216
	call PartCtrl_ReadWord_Off1
	stda16 10216, xhl
	ldda16 xwa, 10216
	cps wa, 0
	jr nz, SeqPart_PosEqualSetFF
	stdi8 10362, 11
	jr SeqPart_UndoAllocOnError

SeqPart_PosEqualSetFF:
	ldw bc, 0xFF

SeqPart_PosEqualStore:
	stda16 10222, xbc
	ldmm16 10220, 10216
	ret

SeqPart_UndoAllocOnError:
	bitda 7, 10363
	ret z
	cpdi8 10362, 0
	ret z
	ldmm8 10359, 9810
	calr SeqPart_InitClear
	ret

SeqPart_MainNavigate:
	dec 4, xsp
	ldda16 xwa, 9862
	ldda16 xbc, 9778
	cp bc, wa
	jr nz, SeqPart_NavForward
	ldda8 c, 9810
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	jrl z, SeqPart_NavExit
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
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
	ldda8 a, 10363
	res 3, a
	res 4, a
	res 7, a
	stda8 10363, a
	stdi8 10362, 0
	ldda8 a, 9810
	extz wa
	stda16 10365, xwa
	ldda8 a, 9810
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmm16 9822, 9830
	ldmm16 9820, 10415
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmm16 9906, 9830
	ldmm16 9904, 10415
	call SeqData_ScanAllTracks
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_NavBackwardProcess
	cps a, 7
	jrl nz, SeqPart_NavExit
	setda 3, 10363
	stdi8 10362, 0

SeqPart_NavBackwardProcess:
	ldmm16 9898, 9830
	ldmm16 9896, 10415
	ldda32 xwa, 9690
	stda32 10208, xwa
	ldda8 l, 10381
	ldda8 a, 9810
	ldmm16 10367, 9862
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmm16 10373, 9830
	ldmm16 10375, 10415
	call SeqData_ScanAllTracks
	cpdi8 10362, 0
	jr z, SeqPart_NavBackwardValidate
	setda 4, 10363
	stdi8 10362, 0

SeqPart_NavBackwardValidate:
	ldmm16 10218, 9830
	ldmm16 10216, 10415
	ldda32 xbc, 9690
	stda32 10212, xbc
	ldda32 xbc, 10208
	stda32 9690, xbc
	bitda 3, 10363
	jr z, SeqPart_NavBackwardWrite
	ldada xwa, 10284
	ldmw2 (xwa), 0x26B0
	ldmw2 (xwa + 2), 0x26B2
	ldada xwa, 10288
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	ldada xwa, 10292
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr nz, SeqPart_NavBackwardCheck
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_NavExit
	ldw (xwa + 2), 0xFF
	jr SeqPart_NavBackwardDone

SeqPart_NavBackwardCheck:
	dec 1, wa
	ld (xbc), wa

SeqPart_NavBackwardDone:
	ldada xde, 10292
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ldda16 xwa, 10292
	call Part_CheckAndReallocVoices
	jrl SeqPart_NavExit

SeqPart_NavBackwardWrite:
	ldda32 xwa, 10212
	cp xwa, xbc
	jrl nc, SeqPart_NavProcessWalker
	sub xbc, xwa
	stda32 9690, xbc
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	ld c, a
	extz bc
	ldda16 xwa, 9900
	call Part_WriteWordAndByte
	ldada xwa, 10284
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	ldada xwa, 10288
	ldmw2 (xwa), 0x26AC
	ldmw2 (xwa + 2), 0x26AE
	ldda16 xde, 9862
	addda16 xde, 9694
	ldada xbc, 10292
	lda xwa, (xbc + 2)
	cpda16 xde, 9778
	jr ule, SeqPart_NavBackwardReturn
	ldmw2 (xbc), 0x26B0
	ldmw2 (xwa), 0x26B2
	call SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldada xwa, 10292
	mrdw5 0x98, 0x02, 0x19, 0xB2, 0x26
	mriw4 0x90, 0x19, 0xB0, 0x26

SeqPart_NavBackwardCleanup:
	ld xwa, 0x26A8
	ld xbc, 0x26AA
	call SeqPart_ConsumeTicksFromBuffer
	cpdi8 10362, 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavBackwardReturn:
	ldmw2 (xbc), 0x27E8
	ldmw2 (xwa), 0x27EA
	call SeqPart_CopyDataSecondary
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26B0
	ld xbc, 0x26B2
	call SeqPart_ConsumeTicksFromBuffer
	cpdi8 10362, 0
	jr z, SeqPart_NavBackwardCleanup
	jrl SeqPart_NavExit

SeqPart_NavProcessWalker:
	cp xwa, xbc
	jrl ule, SeqPart_NavWalkerCleanup
	sub xwa, xbc
	stda32 9690, xwa
	ldda16 xwa, 9862
	addda16 xwa, 9694
	cpda16 xwa, 9778
	jrl ugt, SeqPart_NavWalkerFinish
	ld xwa, 0x26B0
	ld xbc, 0x26B2
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ld xwa, 0x26A8
	ld xbc, 0x26AA
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmm16 10220, 10216
	ldmm16 10222, 10218
	ld xwa, 0x27EC
	ld xbc, 0x27EE
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldada xwa, 10284
	ldmw2 (xwa), 0x27E8
	ldmw2 (xwa + 2), 0x27EA
	ldada xwa, 10288
	ldmw2 (xwa), 0x27EC
	ldmw2 (xwa + 2), 0x27EE
	ldada xwa, 10292
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldada xwa, 10292
	cpw (xwa + 2), 0x5
	jr nz, SeqPart_NavWalkerValidate
	ld wa, (xwa)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	cpw (xwa), 0x0
	jrl z, SeqPart_NavExit
	ldw (xwa + 2), 0xFF

SeqPart_NavWalkerValidate:
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ldda16 xwa, 10292
	call Part_CheckAndReallocVoices
	cpdi8 10362, 0
	jrl z, SeqPart_NavWalkerCleanup
	jrl SeqPart_NavExit

SeqPart_NavWalkerFinish:
	ld xwa, 0x26A8
	ld xbc, 0x26AA
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldmw2 (xsp + 2), 0x26B0
	ldmw2 (xsp), 0x26B2
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	call PartCtrl_FindActiveByLimit
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	mrdw5 0x9F, 0x02, 0x19, 0xF2, 0x27
	mriw4 0x97, 0x19, 0xF0, 0x27
	ldada xwa, 10284
	ldmw2 (xwa), 0x26B0
	ldmw2 (xwa + 2), 0x26B2
	ldada xwa, 10288
	ldmw2 (xwa), 0x27F0
	ldmw2 (xwa + 2), 0x27F2
	ldada xwa, 10292
	ldmw2 (xwa), 0x265C
	ldmw2 (xwa + 2), 0x265E
	call SeqPart_CopyDataPrimary
	cpdi8 10362, 0
	jrl nz, SeqPart_NavExit
	ldada xde, 10292
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 5
	jr nz, SeqPart_NavWalkerReturn
	ld wa, (xde)
	call PartCtrl_ReadWord_Off1
	ldada xwa, 10292
	ld (xwa), hl
	cpw (xwa), 0x0
	jr z, SeqPart_NavExit
	ldw (xwa + 2), 0xFF
	jr SeqPart_NavWalkerError

SeqPart_NavWalkerReturn:
	dec 1, wa
	ld (xbc), wa

SeqPart_NavWalkerError:
	ldada xde, 10292
	ld wa, (xde + 2)
	ld c, a
	extz bc
	ld wa, (xde)
	call Part_WriteWordAndByte
	ldda16 xwa, 10292
	call Part_CheckAndReallocVoices
	cpdi8 10362, 0
	jr nz, SeqPart_NavExit
	ldmm16 9904, 10224
	ldmm16 9906, 10226

SeqPart_NavWalkerCleanup:
	ldada xwa, 10284
	ldmw2 (xwa), 0x26B0
	ldmw2 (xwa + 2), 0x26B2
	ldada xwa, 10288
	ldmw2 (xwa), 0x2887
	ldmw2 (xwa + 2), 0x2885
	ldada xwa, 10292
	ldmw2 (xwa), 0x26A8
	ldmw2 (xwa + 2), 0x26AA
	call SeqPart_CopyDataPrimary

SeqPart_NavExit:
	inc 4, xsp
	ret

SeqPart_CountEventsInRange:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xiz, xwa
	stdi8 10362, 0
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9810
	stdi16 10367, 1
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jr nz, SeqPart_CountBoundary
	ldmm16 10379, 10415
	ldmm16 10377, 9830
	ldw (xiz), 0x0

SeqPart_CountLoop:
	ld xwa, (xsp + 4)
	ldw (xwa), 0x0

SeqPart_CountCheckEnd:
	ldda8 c, 10382
	extz bc
	ld xwa, (xsp + 4)
	cp bc, (xwa)
	jr nz, SeqPart_CountAdvance
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr z, SeqPart_CountDone
	jr SeqPart_CountBoundary

SeqPart_CountAdvance:
	call SeqPart_ReadByte_Secondary
	cp l, 0x82
	jr nz, SeqPart_CountReturn
	incm 1, (xiz)
	jr SeqPart_CountBoundary

SeqPart_CountReturn:
	cp l, 0x81
	jr nz, SeqPart_CountError
	ld xwa, (xsp + 4)
	incm 1, (xwa)
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqPart_CountCheckEnd
	jr SeqPart_CountBoundary

SeqPart_CountError:
	call PartCtrl_AdvanceReadPos
	cpdi8 10362, 0
	jr z, SeqPart_CountCheckEnd

SeqPart_CountBoundary:
	pop xiz
	inc 4, xsp
	ret

SeqPart_CountDone:
	incm 1, (xiz)
	jr SeqPart_CountLoop

SeqPart_ComputeStepCount:
	pushw iz
	stdi8 10362, 0
	ldda8 c, 10381
	ldda8 e, 9810
	stda16 10367, xwa
	extz de
	extz bc
	ld wa, de
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
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
	ldda8 a, 10382
	sub xwa, xbc
	stda32 9690, xwa
	lds iz, 0
	cpdi16 10228, 0
	jr z, SeqPart_StepCountError

SeqPart_StepCountAdvance:
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr z, SeqPart_StepCountReturn
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountCheck:
	cp l, 0x81
	jr nz, SeqPart_StepCountDone
	inc 1, iz

SeqPart_StepCountDone:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqPart_StepCountLoop
	jr SeqPart_StepCountPopReturn

SeqPart_StepCountReturn:
	inc 1, iz
	lds32 xwa, 0
	ldda8 a, 10382
	adddm32 9690, xwa
	cpda16 xiz, 10228
	jr nz, SeqPart_StepCountAdvance

SeqPart_StepCountError:
	lds32 xwa, 1
	adddm32 9690, xwa

SeqPart_StepCountPopReturn:
	popw iz
	ret

SeqPart_ReplayForward:
	push xiz
	stdi8 10362, 0
	ldmm16 10379, 9820
	ldmm16 10377, 9822
	ldda32 xwa, 9690
	dec 1, xwa
	stda32 9690, xwa
	lds32 xiz, 0
	or xwa, xwa
	jr z, SeqPart_ReplayEnd

SeqPart_ReplayLoop:
	ldda16 xwa, 10379
	ldda16 xbc, 10377
	ldw de, 0x81
	call PartCtrl_WriteByte_ZeroExtended
	inc 1, xiz
	ld xwa, 0x288B
	ld xbc, 0x2889
	call PartCtrl_ReadWordWithBoundsCheck
	cpdi8 10362, 0
	jr nz, SeqPart_ReplayReturn
	cpdm32 9690, xiz
	jr nz, SeqPart_ReplayLoop

SeqPart_ReplayEnd:
	ldda16 xwa, 10379
	ldda16 xbc, 10377
	ldw de, 0x82
	call PartCtrl_WriteByte_ZeroExtended

SeqPart_ReplayReturn:
	pop xiz
	ret

SeqPart_Splice:
	dec 4, xsp
	stdi8 10362, 0
	lda xwa, (xsp + 2)
	lda xbc, (xsp)
	calr SeqPart_CountEventsInRange
	cpdi8 10362, 0
	jr nz, SeqPart_SpliceReturn
	ldda16 xwa, 9862
	sub wa, (xsp + 2)
	dec 1, wa
	stda16 10228, xwa
	ld wa, (xsp + 2)
	calr SeqPart_ComputeStepCount
	cpdi8 10362, 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9884, 9820
	ldmm16 9890, 9822
	call SeqBuf_ComputePageLayout
	cpdi8 10362, 0
	jr nz, SeqPart_SpliceReturn
	ldmm16 9900, 9912
	ldda32 xwa, 9914
	stda16 9902, xwa
	calr SeqPart_ReplayForward
	cpdi8 10362, 0
	jr nz, SeqPart_SpliceReturn
	ldda8 a, 9810
	extz wa
	stda16 10365, xwa
	ldmm16 9822, 10377
	ldda16 xwa, 10379
	stda16 9820, xwa
	ldda16 xbc, 9822
	extz bc
	call Part_WriteWordAndByte

SeqPart_SpliceReturn:
	inc 4, xsp
	ret

SeqPart_RestoreState:
	ldda8 c, 9810
	extz bc
	lds wa, 0
	call Part_ReadVoiceBit7
	cps l, 0
	ret z
	ldda8 a, 9810
	dec 1, a
	extz wa
	add wa, wa
	ldada xbc, 3311
	ldmm_sriw 0x07, 0xE4, 0xE0, 0xAF, 0x28
	ldmm16 9820, 10415
	ldda8 a, 9810
	dec 1, a
	extz wa
	add wa, wa
	ldada xbc, 3343
	ldmm_sriw 0x07, 0xE4, 0xE0, 0x66, 0x26
	ldmm16 9822, 9830
	ldw wa, 0x82
	call PartCtrl_WriteByte_Indexed
	ldda8 a, 9810
	extz wa
	stda16 10365, xwa
	ldda16 xwa, 9822
	ld c, a
	extz bc
	ldda16 xwa, 9820
	call Part_WriteWordAndByte
	ldda16 xwa, 9820
	jp Part_CheckAndReallocVoices

SeqPart_TransposeSetup:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	ldda8 a, 10359
	cp a, 0x7F
	jr z, SeqPart_TransposeCheck
	extz wa
	call Seq_ValidatePartNumber
	cps hl, 0
	jr nz, SeqPart_TransposeInit

SeqPart_TransposeCheck:
	ldda16 xwa, 9778
	call Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_TransposeInit
	ldda16 xwa, 9694
	call Seq_ValidateTempoValue
	cps hl, 0
	jr nz, SeqPart_TransposeInit
	ldda8 a, 9812
	cp a, 0x80
	jr nz, SeqPart_TransposeMode

SeqPart_TransposeInit:
	stdi8 10362, 3
	jrl SeqPart_TransposeExit

SeqPart_TransposeMode:
	stdi8 10362, 0
	resda 6, 10363
	ldda8 c, 10359
	cp c, 0x7F
	jr z, SeqPart_TransposeBoundsOk
	ld a, c
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_TransposeSetBounds
	cp a, 0xF
	jr z, SeqPart_TransposeSetBounds
	cp a, 0x10
	jr nz, SeqPart_TransposeValidate

SeqPart_TransposeSetBounds:
	stdi8 10362, 9
	jr SeqPart_TransposeExit

SeqPart_TransposeValidate:
	stda8 9780, c
	calr SeqPart_TransposeWalker
	jr SeqPart_TransposeExit

SeqPart_TransposeBoundsOk:
	ldi_berp 0xFB, 0

SeqPart_TransposeStartWalk:
	ldto_berp A, 0xFB
	inc 1, a
	stda8 9780, a
	ldto_berp A, 0xFB
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_TransposeFinish
	cp a, 0xF
	jr z, SeqPart_TransposeFinish
	cp a, 0x10
	call_24 nz, 0xF4C1D6

SeqPart_TransposeFinish:
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_TransposeReturn
	cps a, 1
	jr z, SeqPart_TransposeReturn
	cpdi8 9782, 0
	jr nz, SeqPart_TransposeReturn
	stda8 9782, a

SeqPart_TransposeReturn:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr c, SeqPart_TransposeStartWalk
	ldmm8 10362, 9782

SeqPart_TransposeExit:
	call LABEL_F3FF3B
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_TransposeWalker:
	push xiz
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_TransposePopReturn
	lds iz, 0
	cpdi16 9694, 0
	jrl z, SeqPart_TransposePopReturn

SeqPart_TransposeWalkLoop:
	ldi_werp 0xFA, 0
	ldda8 a, 10382
	extz wa
	cps wa, 0
	jr z, SeqPart_TransposeClampHigh

SeqPart_TransposeCheckNote:
	call SeqData_ReadNextByte
	cp l, 0x82
	jrl z, SeqPart_TransposePopReturn
	cp l, 0x81
	jr nz, SeqPart_TransposeClampLow
	inc1_werp 0xFA
	call SeqData_AdvancePosition

SeqPart_TransposeApply:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, SeqPart_TransposeCheckNote

SeqPart_TransposeClampHigh:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr z, SeqPart_TransposeError
	jr SeqPart_TransposePopReturn

SeqPart_TransposeClampLow:
	and l, 0xF0
	cp l, 0x90
	jr nz, SeqPart_TransposeDone
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_TransposePopReturn
	call SeqData_ReadNextByte
	extz hl
	ldda8 a, 9812
	exts wa
	add hl, wa
	jr ge, SeqPart_TransposeSkip
	lds hl, 0
	jr SeqPart_TransposeAdvance

SeqPart_TransposeSkip:
	cp hl, 0x7F
	jr le, SeqPart_TransposeAdvance
	ldw hl, 0x7F

SeqPart_TransposeAdvance:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed

SeqPart_TransposeDone:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqPart_TransposeApply
	jr SeqPart_TransposePopReturn

SeqPart_TransposeError:
	cpda16 xiz, 9694
	jrl nz, SeqPart_TransposeWalkLoop

SeqPart_TransposePopReturn:
	pop xiz
	ret

SeqPart_VelocityEditSetup:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	call LABEL_F3F6B4
	cps hl, 0
	jr z, SeqPart_VelEditCheck
	stdi8 10362, 3
	jrl SeqPart_VelEditReturn

SeqPart_VelEditCheck:
	stdi8 10362, 0
	resda 6, 10363
	ldda8 c, 10359
	cp c, 0x7F
	jr z, SeqPart_VelEditMode
	ld a, c
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VelEditInit
	cp a, 0xF
	jr z, SeqPart_VelEditInit
	cp a, 0x10
	jr z, SeqPart_VelEditInit
	stda8 9780, c
	calr SeqPart_VelExprEdit
	calr SeqPart_BufferSwap
	jr SeqPart_VelEditReturn

SeqPart_VelEditInit:
	stdi8 10362, 9
	jr SeqPart_VelEditReturn

SeqPart_VelEditMode:
	ldi_berp 0xFB, 1

SeqPart_VelEditBounds:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VelEditValidate
	cp a, 0xF
	jr z, SeqPart_VelEditValidate
	cp a, 0x10
	jr z, SeqPart_VelEditValidate
	calr SeqPart_VelExprEdit
	calr SeqPart_BufferSwap

SeqPart_VelEditValidate:
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_VelEditStartWalk
	cps a, 1
	jr z, SeqPart_VelEditStartWalk
	cpdi8 9782, 0
	jr nz, SeqPart_VelEditStartWalk
	stda8 9782, a

SeqPart_VelEditStartWalk:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqPart_VelEditBounds
	ldmm8 10362, 9782

SeqPart_VelEditReturn:
	call LABEL_F3FF1F
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_VelocityCurveCalc:
	ldda8 a, 9726
	ldda8 c, 9784
	extz wa
	cps wa, 0
	jrl mi, SeqPart_VelRangeToZone
	cp wa, 0xA
	jrl gt, SeqPart_VelRangeToZone
	add wa, wa
	lda_24 xix, 0xe44ec0
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf4c38c
	jp_dri 8, 0x07, 0xF0, 0xE0

SeqPart_VelCurveData:
	.byte 0xf1, 0x40, 0x26, 0x00, 0x30, 0xf1, 0x42, 0x26
	.byte 0x00, 0x30, 0x78, 0xee, 0x01, 0xcb, 0x89, 0x25
	.byte 0x00, 0xcb, 0xcf, 0x18, 0x67, 0x07, 0xc9, 0xcf
	.byte 0x48, 0x6f, 0x02, 0x25, 0x01, 0xda, 0x12, 0xf2
	.byte 0x76, 0x4e, 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe8
	.byte 0x19, 0x40, 0x26, 0x41, 0x9c, 0x4e, 0xe4, 0x00
	.byte 0xc3, 0x07, 0xe4, 0xe8, 0x19, 0x42, 0x26, 0x78
	.byte 0xc1, 0x01, 0xcb, 0x89, 0xcb, 0xcf, 0x0c, 0x6f
	.byte 0x04, 0x25, 0x00, 0x68, 0x1b, 0xc9, 0xcf, 0x24
	.byte 0x6f, 0x04, 0x25, 0x01, 0x68, 0x12, 0xc9, 0xcf
	.byte 0x3c, 0x6f, 0x04, 0x25, 0x02, 0x68, 0x09, 0x25
	.byte 0x00, 0xc9, 0xcf, 0x54, 0x6f, 0x02, 0x25, 0x03
	.byte 0xda, 0x12, 0xf2, 0x78, 0x4e, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe8, 0x19, 0x40, 0x26, 0x41, 0x9e
	.byte 0x4e, 0xe4, 0x00, 0xc3, 0x07, 0xe4, 0xe8, 0x19
	.ascii "B&x~"
	.byte 0x01, 0xcb, 0x89, 0xcb
	.byte 0xde, 0x6f, 0x04, 0x25, 0x00, 0x68, 0x3f, 0xc9
	.byte 0xcf, 0x12, 0x6f, 0x04, 0x25, 0x01, 0x68, 0x36
	.byte 0xc9, 0xcf, 0x1e, 0x6f, 0x04, 0x25, 0x02, 0x68
	.byte 0x2d, 0xc9, 0xcf, 0x2a, 0x6f, 0x04, 0x25, 0x03
	.byte 0x68, 0x24, 0xc9, 0xcf, 0x36, 0x6f, 0x04, 0x25
	.byte 0x04, 0x68, 0x1b, 0xc9, 0xcf, 0x42, 0x6f, 0x04
	.byte 0x25, 0x05, 0x68, 0x12, 0xc9, 0xcf, 0x4e, 0x6f
	.byte 0x04, 0x25, 0x06, 0x68, 0x09, 0x25, 0x00, 0xc9
	.byte 0xcf, 0x5a, 0x6f, 0x02, 0x25, 0x07, 0xda, 0x12
	.byte 0xf2, 0x7c, 0x4e, 0xe4, 0x31, 0xc3, 0x07, 0xe4
	.byte 0xe8, 0x19, 0x40, 0x26, 0x41, 0xa2, 0x4e, 0xe4
	.byte 0x00, 0xc3, 0x07, 0xe4, 0xe8, 0x19, 0x42, 0x26
	.byte 0x78, 0x18, 0x01, 0xcb, 0x89, 0xcb, 0xcf, 0x10
	.byte 0x6f, 0x04, 0x25, 0x00, 0x68, 0x12, 0xc9, 0xcf
	.byte 0x30, 0x6f, 0x04, 0x25, 0x01, 0x68, 0x09, 0x25
	.byte 0x00, 0xc9, 0xcf, 0x50, 0x6f, 0x02, 0x25, 0x02
	.byte 0xda, 0x12, 0xf2, 0x84, 0x4e, 0xe4, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xe8, 0x19, 0x40, 0x26, 0x41, 0xaa
	.byte 0x4e, 0xe4, 0x00, 0xc3, 0x07, 0xe4, 0xe8, 0x19
	.byte 0x42, 0x26, 0x78, 0xde, 0x00, 0xcb, 0x89, 0xcb
	.byte 0xcf, 0x08, 0x6f, 0x04, 0x25, 0x00, 0x68, 0x2d
	.byte 0xc9, 0xcf, 0x18, 0x6f, 0x04, 0x25, 0x01, 0x68
	.byte 0x24, 0xc9, 0xcf, 0x28, 0x6f, 0x04, 0x25, 0x02
	.byte 0x68, 0x1b, 0xc9, 0xcf, 0x38, 0x6f, 0x04, 0x25
	.byte 0x03, 0x68, 0x12, 0xc9, 0xcf, 0x48, 0x6f, 0x04
	.byte 0x25, 0x04, 0x68, 0x09, 0x25, 0x00, 0xc9, 0xcf
	.byte 0x58, 0x6f, 0x02, 0x25, 0x05, 0xda, 0x12, 0xf2
	.byte 0x88, 0x4e, 0xe4, 0x31, 0xc3, 0x07, 0xe4, 0xe8
	.byte 0x19, 0x40, 0x26, 0x41, 0xae, 0x4e, 0xe4, 0x00
	.byte 0xc3, 0x07, 0xe4, 0xe8, 0x19, 0x42, 0x26, 0x78
	.byte 0x89, 0x00

SeqPart_VelRangeToZone:
	ldda8 a, 9784
	cps a, 4
	jr nc, SeqPart_VelZone1
	ldb e, 0x0
	jr SeqPart_VelZoneLookup

SeqPart_VelZone1:
	cp a, 0xC
	jr nc, SeqPart_VelZone2
	ldb e, 0x1
	jr SeqPart_VelZoneLookup

SeqPart_VelZone2:
	cp a, 0x14
	jr nc, SeqPart_VelZone3
	ldb e, 0x2
	jr SeqPart_VelZoneLookup

SeqPart_VelZone3:
	cp a, 0x1C
	jr nc, SeqPart_VelZone4
	ldb e, 0x3
	jr SeqPart_VelZoneLookup

SeqPart_VelZone4:
	cp a, 0x24
	jr nc, SeqPart_VelZone5
	ldb e, 0x4
	jr SeqPart_VelZoneLookup

SeqPart_VelZone5:
	cp a, 0x2C
	jr nc, SeqPart_VelZone6
	ldb e, 0x5
	jr SeqPart_VelZoneLookup

SeqPart_VelZone6:
	cp a, 0x34
	jr nc, SeqPart_VelZone7
	ldb e, 0x6
	jr SeqPart_VelZoneLookup

SeqPart_VelZone7:
	cp a, 0x3C
	jr nc, SeqPart_VelZone8
	ldb e, 0x7
	jr SeqPart_VelZoneLookup

SeqPart_VelZone8:
	cp a, 0x44
	jr nc, SeqPart_VelZone9
	ldb e, 0x8
	jr SeqPart_VelZoneLookup

SeqPart_VelZone9:
	cp a, 0x4C
	jr nc, SeqPart_VelZone10
	ldb e, 0x9
	jr SeqPart_VelZoneLookup

SeqPart_VelZone10:
	cp a, 0x54
	jr nc, SeqPart_VelZone11
	ldb e, 0xA
	jr SeqPart_VelZoneLookup

SeqPart_VelZone11:
	ldb e, 0x0
	cp a, 0x5C
	jr nc, SeqPart_VelZoneLookup
	ldb e, 0xB

SeqPart_VelZoneLookup:
	extz de
	lda_24 xbc, 0xe44e8e
	ldmm_srib 0x07, 0xE4, 0xE8, 0x40, 0x26
	ld xbc, 0xE44EB4
	ldmm_srib 0x07, 0xE4, 0xE8, 0x42, 0x26
	ldda8 l, 9792
	ldda8 c, 9786
	ld e, c
	cp c, 0x7F
	jr nz, SeqPart_VelCalcSubtract
	ldb e, 0x0

SeqPart_VelCalcSubtract:
	sub l, e
	ldda8 a, 9730
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
	cp c, 0x7F
	jr nz, SeqPart_VelCalcAdd
	ldb e, 0x0

SeqPart_VelCalcAdd:
	add e, l
	stda8 9790, e
	cps a, 0
	jr z, SeqPart_VelCalcClamp
	cp a, 0x7F
	jr nz, SeqPart_VelCalcStore

SeqPart_VelCalcClamp:
	ldb a, 0x60

SeqPart_VelCalcStore:
	sub a, l
	stda8 9788, a
	ret

SeqPart_VelExprEdit:
	dec 4, xsp
	push xiz
	ldda8 l, 9726
	srl l, 1
	extz hl
	sla hl, 2
	lda_24 xbc, 0xe44e58
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	ld (xsp + 4), xwa
	cpdi8 9728, 0
	jrl z, SeqPart_VelExprFinalExit
	cpdi8 9730, 0
	jrl z, SeqPart_VelExprFinalExit
	call SeqVoice_FindDrumPartIndex
	ldmm16 10367, 9778
	ldda8 a, 9780
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_VelExprFinalExit
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_VelExprExit

SeqPart_VelExprLoop:
	ldi_werp 0xFA, 0
	resda 0, 10363
	ldmm16 10046, 9830
	ldmm16 10044, 10415
	ldda8 a, 10382
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
	cpdi8 10362, 0
	jrl nz, SeqPart_VelExprFinalExit
	inc1_werp 0xFA
	call SeqData_AdvancePosition
	resda 0, 10363
	ldmm16 10046, 9830
	ldmm16 10044, 10415

SeqPart_VelExprCheckEnd:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, SeqPart_VelExprReadEvent

SeqPart_VelExprCheckNote:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr nz, SeqPart_VelExprExit
	cpda16 xiz, 9694
	jr nz, SeqPart_VelExprLoop

SeqPart_VelExprExit:
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprDone:
	bit 7, l
	jr nz, SeqPart_VelExprApply
	call SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprApply:
	and l, 0xF0
	cp l, 0x90
	jr z, SeqPart_VelExprClamp
	call SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprClamp:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl nz, SeqPart_VelExprFinalExit
	call SeqData_ReadNextByte
	stda8 9784, l
	extz hl
	ld xwa, (xsp + 4)
	ldmm_srib 0x07, 0xE0, 0xEC, 0x3A, 0x26
	ldda8 a, 9730
	cp a, 0x64
	jr z, SeqPart_VelExprContinue
	cp a, 0x9C
	jr z, SeqPart_VelExprContinue
	calr SeqPart_VelocityCurveCalc
	ldda8 e, 9730
	ldda8 a, 9786
	ldda8 c, 9784
	bit 7, e
	jrl nz, SeqPart_VelExprError
	ld e, a
	cps a, 0
	jr nz, SeqPart_VelExprWrite
	ldda8 a, 9784
	cpda8 a, 9790
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprWrite:
	cp e, 0x7F
	jr nz, SeqPart_VelExprSkip
	ldda8 a, 9784
	cpda8 a, 9788
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cpdi8 10362, 0
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
	cpdi8 10362, 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprContinue:
	ldda8 e, 9786
	ld b, e
	ld l, e
	ldda8 c, 9728
	cp c, 0x64
	jrl z, SeqPart_VelExprPopReturn
	cp e, 0x7F
	jr nz, SeqPart_VelExprBoundary
	ldb b, 0x60

SeqPart_VelExprBoundary:
	ldda8 l, 9784
	cp l, b
	jr nc, SeqPart_VelExprComplete
	sub b, l
	ld a, b
	jr SeqPart_VelExprUpdate

SeqPart_VelExprError:
	ld e, a
	cps a, 0
	jr nz, SeqPart_VelExprReturn
	ldda8 a, 9784
	cpda8 a, 9790
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl z, SeqPart_VelExprCheckEnd
	jrl SeqPart_VelExprFinalExit

SeqPart_VelExprReturn:
	cp e, 0x7F
	jr nz, SeqPart_VelExprFinish
	ldda8 a, 9784
	cpda8 a, 9788
	jr ule, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jrl z, SeqPart_VelExprCheckEnd
	jr SeqPart_VelExprFinalExit

SeqPart_VelExprFinish:
	ld a, c
	cpda8 c, 9788
	jr ule, SeqPart_VelExprContinue
	cpda8 a, 9790
	jr nc, SeqPart_VelExprContinue
	call SeqData_AdvancePosition
	cpdi8 10362, 0
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
	cp e, 0x7F
	jr nz, SeqPart_VelExprStore
	ldb b, 0x60

SeqPart_VelExprStore:
	cp l, b
	jr nc, SeqPart_VelExprPopIz
	add l, a
	cp l, 0x60
	jr c, SeqPart_VelExprPopReturn
	ldb l, 0x7F
	jr SeqPart_VelExprClampMax

SeqPart_VelExprPopIz:
	sub l, a

SeqPart_VelExprPopReturn:
	cp l, 0x7F
	jr nz, SeqPart_VelExprClampMin

SeqPart_VelExprClampMax:
	setda 0, 10363

SeqPart_VelExprClampMin:
	extz hl
	ld wa, hl
	call PartCtrl_WriteByte_Indexed
	call SeqData_AdvancePosition
	cpdi8 10362, 0
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
	ldda16 xiz, 10415
	ldmw2 (xsp + 4), 0x2666
	ldda8 a, 9780
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jr nz, SeqPart_BufferSwapReturn
	ldmm16 10375, 10415
	ldmm16 10373, 9830
	call PartCtrl_NavigateBackwardAlt
	call LABEL_F3FC26
	cp l, 0x81
	jr z, SeqPart_BufferSwapReturn
	call PartCtrl_AdvanceToNextEntry
	call PartCtrl_AdvanceToNextEntry
	cpdi8 10362, 0
	jr nz, SeqPart_BufferSwapReturn
	ldw wa, 0x82
	call SeqPart_WriteByte_Primary
	ldda16 xwa, 10365
	ldfr_werp WA, 0xFA
	ldda8 a, 9780
	extz wa
	stda16 10365, xwa
	ldda16 xwa, 10373
	ld c, a
	extz bc
	ldda16 xwa, 10375
	call Part_WriteWordAndByte
	ldto_werp WA, 0xFA
	stda16 10365, xwa
	call PartCtrl_NavigateBackwardAlt
	ldw wa, 0x81
	call SeqPart_WriteByte_Primary

SeqPart_BufferSwapReturn:
	mrdw5 0x9F, 0x06, 0x19, 0x87, 0x28
	mrdw5 0x9F, 0x08, 0x19, 0x85, 0x28
	stda16 10415, xiz
	mrdw5 0x9F, 0x04, 0x19, 0x66, 0x26
	pop xiz
	inc 6, xsp
	ret

SeqPart_PartSelect:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	call LABEL_F40BD3
	cps hl, 0
	jr z, SeqPart_PartSelectLoop
	stdi8 10362, 3
	jrl SeqPart_PartSelectExit

SeqPart_PartSelectLoop:
	ldda8 c, 10359
	cp c, 0x11
	jr z, SeqPart_PartSelectDone
	ld a, c
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_PartSelectCheck
	cp a, 0x10
	jr z, SeqPart_PartSelectCheck
	cp a, 0xF
	jr z, SeqPart_PartSelectCheck
	cp a, 0xE
	jr nz, SeqPart_PartSelectSkip

SeqPart_PartSelectCheck:
	stdi8 10362, 9
	jr SeqPart_PartSelectExit

SeqPart_PartSelectSkip:
	stda8 9780, c
	stdi8 10362, 0
	calr SeqPart_InnerProcess
	jr SeqPart_PartSelectExit

SeqPart_PartSelectDone:
	ldi_berp 0xFB, 1

SeqPart_PartSelectProcess:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_PartSelectFinish
	cp a, 0xF
	jr z, SeqPart_PartSelectFinish
	cp a, 0x10
	call_24 nz, 0xF4C98A

SeqPart_PartSelectFinish:
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_PartSelectReturn
	cps a, 1
	jr z, SeqPart_PartSelectReturn
	cp a, 0x8
	jr z, SeqPart_PartSelectReturn
	cpdi8 9782, 0
	jr nz, SeqPart_PartSelectReturn
	stda8 9782, a

SeqPart_PartSelectReturn:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqPart_PartSelectProcess
	ldmm8 10362, 9782

SeqPart_PartSelectExit:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_InnerProcess:
	push xiz
	stdi8 10362, 0
	cpdi8 9762, 0
	jrl z, SeqPart_InnerReturn
	ldda8 a, 9780
	extz wa
	stda16 10365, xwa
	ldda8 a, 9780
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_InnerReturn
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_InnerReturn
	lds iz, 0
	cpdi16 9694, 0
	jrl z, SeqPart_InnerReturn

SeqPart_InnerLoop:
	ldi_werp 0xFA, 0
	ldda8 a, 10382
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
	cpdi8 10362, 0
	jr nz, SeqPart_InnerReturn
	inc1_werp 0xFA

SeqPart_InnerCheckType:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, SeqPart_InnerReadEvent

SeqPart_InnerCheckNote:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr z, SeqPart_InnerBoundary
	jr SeqPart_InnerReturn

SeqPart_InnerCheck90:
	and l, 0xF0
	cp l, 0x90
	jr nz, SeqPart_InnerAdvance
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_InnerReturn
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_InnerReturn
	call SeqData_ReadNextByte
	ldda8 c, 9762
	cps c, 0
	jr le, SeqPart_InnerVelAddNeg
	ldb e, 0x7F
	sub e, l
	ld a, c
	cp e, a
	jr ugt, SeqPart_InnerVelAdd
	ldb l, 0x7F
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
	cpdi8 10362, 0
	jr z, SeqPart_InnerCheckType
	jr SeqPart_InnerReturn

SeqPart_InnerBoundary:
	cpda16 xiz, 9694
	jrl nz, SeqPart_InnerLoop

SeqPart_InnerReturn:
	pop xiz
	ret

SeqPart_PartVoiceCheck:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	call LABEL_F3F854
	cps hl, 0
	jr z, SeqPart_VoiceCheckCompare
	stdi8 10362, 3
	jrl SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckCompare:
	ldda8 a, 9750
	cpda8 a, 9816
	jrl z, SeqPart_VoiceCheckReturn
	ldda8 c, 10359
	cp c, 0x11
	jr z, SeqPart_VoiceCheckMulti
	ld a, c
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0x10
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0xF
	jr z, SeqPart_VoiceCheckDrum
	cp a, 0xE
	jr nz, SeqPart_VoiceCheckOk

SeqPart_VoiceCheckDrum:
	stdi8 10362, 9
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckOk:
	stda8 9780, c
	stdi8 10362, 0
	calr SeqPart_VoiceCheckSetup
	jr SeqPart_VoiceCheckReturn

SeqPart_VoiceCheckMulti:
	ldi_berp 0xFB, 1

SeqPart_VoiceCheckMultiLoop:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VoiceCheckMultiNext
	cp a, 0xF
	jr z, SeqPart_VoiceCheckMultiNext
	cp a, 0x10
	call_24 nz, 0xF4CB4A

SeqPart_VoiceCheckMultiNext:
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_VoiceCheckMultiDone
	cps a, 1
	jr z, SeqPart_VoiceCheckMultiDone
	cp a, 0x8
	jr z, SeqPart_VoiceCheckMultiDone
	ldda8 a, 9782
	cps a, 0
	jr nz, SeqPart_VoiceCheckMultiDone
	stda8 10362, a

SeqPart_VoiceCheckMultiDone:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqPart_VoiceCheckMultiLoop
	ldmm8 10362, 9782

SeqPart_VoiceCheckReturn:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_VoiceCheckSetup:
	push xiz
	stdi8 10362, 0
	ldda8 a, 9750
	cpda8 a, 9816
	jrl z, SeqPart_VoiceCheckModeA
	ldda8 a, 9780
	extz wa
	stda16 10365, xwa
	ldda8 a, 9780
	extz wa
	call Part_ValidateVoiceAndSetupSeq
	cpdi8 10362, 0
	jrl nz, SeqPart_VoiceCheckModeA
	ldmm16 9820, 10415
	ldmm16 9822, 9830
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_VoiceCheckModeA
	ldda16 xwa, 10415
	stda16 10375, xwa
	ldda16 xwa, 9830
	stda16 10373, xwa
	ldmm16 10377, 9830
	ldmm16 10379, 10415
	lds iz, 0
	cpdi16 9694, 0
	jr z, SeqPart_VoiceCheckComplete

SeqPart_VoiceCheckSetupDone:
	ldi_werp 0xFA, 0
	ldda8 a, 10382
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
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckModeA
	inc1_werp 0xFA

SeqPart_VoiceCheckProcess:
	ldda8 a, 10382
	extz wa
	cp_werp WA, 0xFA
	jr nz, SeqPart_VoiceCheckSetupReturn

SeqPart_VoiceCheckValidate:
	inc 1, iz
	call SeqTrack_ProcessControlBytes
	cpda16 xiz, 9694
	jr nz, SeqPart_VoiceCheckSetupDone

SeqPart_VoiceCheckComplete:
	jr SeqPart_VoiceCheckModeA

SeqPart_VoiceCheckFinal:
	and l, 0xF0
	cp l, 0x90
	jr nz, SeqPart_VoiceCheckDispatch
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckModeA
	call SeqData_ReadNextByte
	cpda8 l, 9750
	jr nz, SeqPart_VoiceCheckDispatch
	ldda8 a, 9816
	extz wa
	call PartCtrl_WriteByte_Indexed

SeqPart_VoiceCheckDispatch:
	call SeqData_ReadParamBlockAlt
	cpdi8 10362, 0
	jr z, SeqPart_VoiceCheckProcess

SeqPart_VoiceCheckModeA:
	pop xiz
	ret

SeqPart_VoiceCheckModeB:
	push_werp 0xFA
	call SeqVoice_SetDefaultParams
	stdi8 10362, 0
	call LABEL_F3F73B
	cps hl, 0
	jr z, SeqPart_VoiceCheckModeC
	stdi8 10362, 3
	jrl SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckModeC:
	stdi8 10362, 0
	resda 6, 10363
	ldda8 c, 10359
	cp c, 0x11
	jr z, SeqPart_VoiceCheckCleanup
	ld a, c
	dec 1, a
	extz wa
	ldada xde, 61856
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VoiceCheckUpdate
	cp a, 0xF
	jr z, SeqPart_VoiceCheckUpdate
	cp a, 0x10
	jr nz, SeqPart_VoiceCheckStore

SeqPart_VoiceCheckUpdate:
	stdi8 10362, 9
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckStore:
	stda8 9780, c
	calr SeqPart_VoiceCheckWalkReturn
	jr SeqPart_VoiceCheckWalkDone

SeqPart_VoiceCheckCleanup:
	ldi_berp 0xFB, 1

SeqPart_VoiceCheckFinish:
	ldto_berp A, 0xFB
	stda8 9780, a
	ldto_berp A, 0xFB
	dec 1, a
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xD
	jr z, SeqPart_VoiceCheckWalk
	cp a, 0xF
	jr z, SeqPart_VoiceCheckWalk
	cp a, 0x10
	call_24 nz, 0xF4CD06

SeqPart_VoiceCheckWalk:
	ldda8 a, 10362
	cps a, 0
	jr z, SeqPart_VoiceCheckWalkLoop
	cps a, 1
	jr z, SeqPart_VoiceCheckWalkLoop
	cpdi8 9782, 0
	jr nz, SeqPart_VoiceCheckWalkLoop
	stda8 9782, a

SeqPart_VoiceCheckWalkLoop:
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x10
	jr ule, SeqPart_VoiceCheckFinish
	ldmm8 10362, 9782

SeqPart_VoiceCheckWalkDone:
	call SeqVoice_ApplyTableEntry
	call SeqVoice_InitReturnZero
	pop_werp 0xFA
	ret

SeqPart_VoiceCheckWalkReturn:
	dec 4, xsp
	push xiz
	call SeqVoice_FindDrumPartIndex
	ldda8 a, 9780
	ldmm16 10367, 9778
	extz wa
	extz hl
	ld bc, hl
	call SeqVoice_SeekToBar
	cpdi8 10362, 0
	jrl nz, SeqPart_VoiceCheckEndCleanup
	ldw (xsp + 4), 0x0
	cpdi16 9694, 0
	jrl z, SeqPart_VoiceCheckWalkFinish

SeqPart_VoiceCheckWalkAdvance:
	lds iz, 0
	stdi8 9824, 0
	stdi8 9826, 0
	resda 0, 10363
	ldmm16 10046, 9830
	ldmm16 10044, 10415
	ld (xsp + 6), 0x0
	ldda8 a, 10382
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
	cpdi8 10362, 0
	jrl nz, SeqPart_VoiceCheckEndAdvance
	inc 1, iz
	call SeqData_AdvancePosition
	stdi8 9824, 0
	stdi8 9826, 0
	resda 0, 10363
	ldmm16 10046, 9830
	ldmm16 10044, 10415

SeqPart_VoiceCheckWalkError:
	ldda8 a, 10382
	extz wa
	cp wa, iz
	jr nz, SeqPart_VoiceCheckWalkValidate

SeqPart_VoiceCheckWalkCleanup:
	cp (xsp + 6), 0x0
	jr nz, SeqPart_VoiceCheckWalkFinish
	incm 1, (xsp + 4)
	call SeqTrack_ProcessControlBytes
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckWalkFinish
	ld wa, (xsp + 4)
	cpda16 xwa, 9694
	jrl nz, SeqPart_VoiceCheckWalkAdvance

SeqPart_VoiceCheckWalkFinish:
	cpdi8 10362, 0
	jr z, SeqPart_VoiceCheckEndReturn

SeqPart_VoiceCheckWalkExit:
	jr SeqPart_VoiceCheckEndCleanup

SeqPart_VoiceCheckFinalReturn:
	bit 7, l
	jr z, SeqPart_VoiceCheckEndStore
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckEndAdvance
	call SeqData_ReadNextByte
	ldfr_berp L, 0xFB
	ldto_berp A, 0xFB
	addda8 a, 9740
	ldfr_berp A, 0xFB
	extz wa
	call PartCtrl_WriteByte_Indexed
	bit_erpb 0xFB, 0x07
	jr nz, SeqPart_VoiceCheckEndCheck
	cp_erpb 0xFB, 0x60
	jr c, SeqPart_VoiceCheckEndStore

SeqPart_VoiceCheckEndCheck:
	setda 0, 10363

SeqPart_VoiceCheckEndStore:
	call SeqData_AdvancePosition
	cpdi8 10362, 0
	jr z, SeqPart_VoiceCheckWalkError

SeqPart_VoiceCheckEndAdvance:
	ld (xsp + 6), 0x1
	cpdi8 10362, 0
	jr nz, SeqPart_VoiceCheckWalkExit

SeqPart_VoiceCheckEndReturn:
	ldda8 a, 9740
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
	bitda 0, 10363
	ret z
	ldda8 e, 9740
	bit 7, e
	jrl nz, SeqStep_EventProcess
	jr __jrt_nop_F4CE4D
__jrt_nop_F4CE4D:

	.include "seq_step_routines.s"
