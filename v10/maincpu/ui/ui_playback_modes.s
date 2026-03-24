; =============================================================================
; UI Playback Mode Handlers (3K lines)
; =============================================================================
;
; UI state event handling and playback mode control: voice parameter
; handlers, sequencer timer/tempo, part validation, play/song/medley
; mode dispatch, part format handlers, and display mode transitions.
; =============================================================================

UIStateEvt_VoiceParamHandler:
	ldda8	a, 0x8d36
	cp	a, 142
	jr	z, 19
	cp	a, 100
	jr	z, 14
	cp	a, 108
	jr	lt, 17
	cp	a, 122
	jr	le, 4
	jp	0xf20310
	stdi8	4330, 0
	jrl	164
	ldda8	a, 0xc07d
	cps	a, 3
	.byte 0xf2, 0xb4
	pop_sr
	.byte 0xf2
	and	bc, iz
	jrl	nz, 8640
	ldda8	w, 0xc07f
	cp	w, 255
	jr	nz, 8
	.byte 0xc1, 0xea
	rcf
	push	xix
	swi	6
	jrl	132
	bit	2, w
	jr	nz, 2
	jr	125
	.byte 0xf1, 0xea
	rcf
	inc	6, w
	reti
	.byte 0xc1, 0xea
	rcf
	push	xix
	swi	6
	jr	112
	and	a, w
	and	a, 4
	bit	2, a
	jr	z, 53
	pushw	wa
	xor	a, a
	call	Part_WriteAllVoiceSubBlocks_B
	popw	wa
	call	SeqPlay_RestoreVoiceState_Return
	call	0xf203b5
	call	AccWrap_PlayModeDispatch
	call	SeqBuf_Init
	stdi8	1073, 0
	.byte 0xc1, 0xb3
	pushw	wa
	push	xiz
	rcf
	stdi16	0xf19e, 0
	.byte 0xc1, 0xa5
	pushw	wa
	push	xix
	swi	6
	ldb	a, 76
	call	CtrlPanel_SetIndicatorBit
	jr	49
	pushw	wa
	xor	a, a
	call	Part_WriteAllVoiceSubBlocks_A
	popw	wa
	call	SeqPlay_RestoreVoiceState_Return
	call	0xf203b5
	call	AccWrap_PlayModeDispatch
	call	SeqBuf_Init
	stdi8	1073, 0
	.byte 0xc1, 0xb3
	pushw	wa
	push	xiz
	rcf
	stdi16	0xf19e, 0
	stdi8	4596, 0
	call	SeqPlay_CheckStartConditions
	ret
	ld	xix, 0xf1a0
	xor	bc, bc
	ldb	c, 16
	ldb	a, 16
	.byte 0xc5, 0xf0, 0xf1
	jr	z, 5
	djnz16	bc, -8
	jr	68
	xor	wa, wa
	ldb	a, 16
	sub	wa, bc
	ld	c, a
	ld	b, a
	ldda16	iz, 0xf19e
	ld	a, c
	scf
	.byte 0xde
	pushw	de
	ld	a, b
	.ascii "g-(CP"
	.byte 0xf2
	nop
	nop
	ldb	c, 3
	mul8rr	a, c
	ld	iy, wa
	.byte 0xf3
	reti
	cp	xix, xix
	inc	6, l
	pop_sr
	popw	wa
	jr	3
	popw	wa
	jr	20
	inc	1, a
	ld	w, a
	stda8	3414, w
	.byte 0xc1, 0x54
	decf
	push	xiz
	.byte 0x01, 0xc1
	jrl	ugt, 15912
	.byte 0x04
	jr	12
	.byte 0xc1, 0x54
	decf
	push	xix
	swi	6
	.byte 0xc1
	jrl	ugt, 15400
	swi	3
	xor	w, w
	ret

SeqPlay_RestoreVoiceState_Return:
	ldda8 a, 0x2878
	pushw wa
	ld8_24 a, 0x00ffe3
	stda8 0x2878, a
	call SeqVoice_InitEntry
	popw wa
	stda8 0x2878, a
	ret

SeqTimer_PostTempoUpdate:
	ld xhl, 0xf460
	ld xwa, 0x2da
	add xhl, xwa
	ld wa, (xhl + 8)
	pushw wa
	ldb e, 0x48
	ldb d, 0x8
	ldb w, 0xff
	call SwbtWr_QueuePostEvent
	popw wa
	stda16 0xfc62, xwa
	call SeqTimer_UpdateTempoReg
	ret

PlayMode_NullRet:
	ret
PlayMode_SetupAndDispatch:
	; --- Setup: load/store/call/set flag ---
	ldda16	wa, 0xf19e
	stda16	0x2875, wa
	stdi8	3424, 0
	call AccWrap_PlayModeDispatch
	ordi8	0x28a7, 4
	ret
PlayMode_TeardownAndRestore:
	; --- Teardown: load/store/clear flags ---
	ldda16	wa, 0x2875
	stda16	0xf19e, wa
	anddi8	0x28a7, 251
	ordi8	0x28b3, 16
	anddi8	0x28a7, 247
	ret
PartLookup_NullRet:
	ret
PartParam_Handler_00:
	ldb c, 0x00
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_01:
	ldb c, 0x01
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_02:
	ldb c, 0x02
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_03:
	ldb c, 0x03
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_04:
	ldb c, 0x04
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_05:
	ldb c, 0x05
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_06:
	ldb c, 0x06
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_07:
	ldb c, 0x07
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_08:
	ldb c, 0x08
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_09:
	ldb c, 0x09
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0A:
	ldb c, 0x0a
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0B:
	ldb c, 0x0b
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0C:
	ldb c, 0x0c
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0D:
	ldb c, 0x0d
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0E:
	ldb c, 0x0e
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0F:
	ldb c, 0x0f
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
Part_LookupParam:
	; --- Lookup function: load from table[IY], store ---
	ld xhl, 0x0000f1a0
	xor b, b
	ld iy, bc
	ld e, c
	ld_rrb	a, xhl, iy
	stda8	3423, a
	inc 1, e
	stda8	3424, e
	ret
Part_ValidateAndActivate:
	; --- Validation: check range, optionally call ---
	stdi16	0x287f, 1
	stdi16	3383, 0
	cpdi8	3424, 0
	jr z, PartValidate_Done
	cpdi8	3424, 16
	jr ugt, PartValidate_Done
	stdi16	4360, 0
	xor	wa, wa
	ldb a, 0x8a
	call UI_PostModeChangeEvent
PartValidate_Done:
	ret
PlaybackDispatch_NullRet:
	ret


PlaybackMode_DispatchByType:
	bitda 0, 3381
	jrl z, DispatchHandler_ClearActiveFlag
	cpdi8 0x8d36, 122
	jr z, PlaybackDisp_Type122_Play
	cpdi8 0x8d36, 120
	jr z, PlaybackDisp_Type120_Play
	cpdi8 0x8d36, 115
	jr z, PlaybackDisp_Type115_Stop
	cpdi8 0x8d36, 118
	jr z, PlaybackDisp_Type118_Stop
	cpdi8 0x8d36, 116
	jr z, PlaybackDisp_Type116_Song
	cpdi8 0x8d36, 117
	jrl z, PlaybackDisp_Type117_PartFmt
	cpdi8 0x8d36, 111
	jr z, PlaybackDisp_Type111_CDSong
	cpdi8 0x8d36, 114
	jr z, PlaybackDisp_Type114_CDSong
	cpdi8 0x8d36, 112
	jr z, PlaybackDisp_Type112_CDDoc
	cpdi8 0x8d36, 113
	jrl z, PlaybackDisp_Type113_CDPd
	cpdi8 0x8d36, 121
	jr z, Part_ValidateCallAndClear
	cpdi8 0x8d36, 119
	jr z, Part_ValidateCallAndClear
	cpdi8 0x8d36, 108
	jr z, Part_ValidateCallAndClear
	cpdi8 0x8d36, 109
	jr z, Part_ValidateCallAndClear
	cpdi8 0x8d36, 110
	jr z, Part_ValidateCallAndClear
	jp DispatchHandler_ClearActiveFlag

PlaybackDisp_Type122_Play:
	call PlayMode_CheckAndDispatch
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type120_Play:
	call PlayMode_CheckAndDispatch
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type115_Stop:
	call PlayMode_StopAbortRetZero
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type118_Stop:
	call PlayMode_StopAbortRetZero
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type116_Song:
	call SongMode_CheckAndDispatch
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type117_PartFmt:
	call PartFormat_CheckAndDispatch
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type111_CDSong:
	call CDlikeSwTtl_SongBit1Check
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type114_CDSong:
	call CDlikeSwTtl_SongBit1Check
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type112_CDDoc:
	call CDlikeSwTtl_DocBitCheck
	jr DispatchHandler_ClearActiveFlag

PlaybackDisp_Type113_CDPd:
	call CDlikeSwTtl_PdBitCheck
	jr DispatchHandler_ClearActiveFlag

Part_ValidateCallAndClear:
	call FileIO_MedleyDispatchByMode

DispatchHandler_ClearActiveFlag:
	anddi8 3381, 254
	ret

PlayMode_InitFlagBlock:
	call	0xf2063e
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	stdi8	3380, 1
	call	0xf2064f
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	4420, 10
	ret

SongBank_ScanActiveVoices:
	xor bc, bc
	ld l, a
	extz hl
	mul hl, 0x800
	add xhl, 0xab0d0
	ld xiy, xhl
	ldb b, 0x10
	cp_sriw_im 0xf5, 0x4e, 0xff, 0x00, 0x00
	jr z, ScanVoice_NoneFound

ScanVoice_LoopCheckBit7:
	bitm 7, (xiy)
	jr nz, ScanVoice_Found
	inc 3, xiy
	djnz8 b, ScanVoice_LoopCheckBit7

ScanVoice_NoneFound:
	xor hl, hl
	jr ScanVoice_Return

ScanVoice_Found:
	lds hl, 1

ScanVoice_Return:
	ret

PlayMode_ClearModeFlag:
	stdi8	3380, 0
	ret

PlayMode_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, PlayMode_SendModeCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call PlayMode_DispatchAndClearBit2
	bitda 2, 3394
	jr z, PlayMode_SendModeCommand
	jr PlayMode_SendModeCommand

PlayMode_SendModeCommand:
	stdi8 4437, 0
	cpdi8 0x8d36, 122
	jr z, PlayCheck_PostMode79
	cpdi8 0x8d36, 120
	jr z, PlayCheck_PostMode77

PlayCheck_PostMode79:
	xor wa, wa
	ldb a, 0x79
	call UI_PostModeChangeEvent
	jr PlayCheck_Return

PlayCheck_PostMode77:
	xor wa, wa
	ldb a, 0x77
	call UI_PostModeChangeEvent

PlayCheck_Return:
	ret

PlayMode_DispatchAndClearBit2:
	call AccWrap_PlayModeDispatch
	anddi8 0x28ac, 251
	ret

PlayMode_StartAndSendCommand:
	cpdi8 3380, 1
	jr nz, SongMode_PostEvtRetZero
	cpdi8 4420, 0
	jr nz, SongMode_PostEvtRetZero
	call PlayMode_DispatchAndClearBit2
	stdi8 4437, 1
	cpdi8 0x8d36, 122
	jr z, PlayStart_PostMode79
	cpdi8 0x8d36, 120
	jr z, PlayStart_PostMode77

PlayStart_PostMode79:
	xor wa, wa
	ldb a, 0x79
	call UI_PostModeChangeEvent
	jr SongMode_PostEvtRetZero

PlayStart_PostMode77:
	xor wa, wa
	ldb a, 0x77
	call UI_PostModeChangeEvent

SongMode_PostEvtRetZero:
	ret

SeqRestart_CheckAndDispatch:
	bitda 2, 0x28ac
	jr z, SeqRestart_Return
	ld iz, wa
	ldda8 a, 0xfc5f
	and a, 0x30
	ld wa, iz
	jr nz, SeqRestart_Return
	call AccWrap_PlayModeDispatch
	ldw bc, 0xf000

SeqRestart_WaitBit2Loop:
	bitda 2, 1056
	jr z, SeqRestart_DispatchAndNotify
	nop
	nop
	nop
	djnz xbc, SeqRestart_WaitBit2Loop

SeqRestart_DispatchAndNotify:
	call Seq_DispatcherEntry
	call SeqRestart_SendPlaybackNotify

SeqRestart_Return:
	ret

SeqRestart_SendPlaybackNotify:
	bitda 2, 0x28ac
	jr z, SeqNotify_Return
	stdi8 4437, 1
	cpdi8 0x8d36, 122
	jr z, SeqNotify_PostMode79
	cpdi8 0x8d36, 120
	jr z, SeqNotify_PostMode77

SeqNotify_PostMode79:
	xor wa, wa
	ldb a, 0x79
	call UI_PostModeChangeEvent
	jr SeqNotify_Return

SeqNotify_PostMode77:
	xor wa, wa
	ldb a, 0x77
	call UI_PostModeChangeEvent

SeqNotify_Return:
	ret

Medley_GetPlaybackStatus:
	xor hl, hl
	ldda8 l, 4437
	ret

SongMode_InitFlagBlock:
	ret
	ret
	call	0xf2077b
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	stdi8	3380, 1
	call	0xf2078c
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	4420, 10
	ret
	stdi8	3380, 0
	ret

SongMode_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, SongMode_SendStopCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call SongMode_AbortAndClearBit2
	bitda 2, 3394
	jr z, SongMode_SendStopCommand
	jr SongMode_SendStopCommand

SongMode_SendStopCommand:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6d
	call UI_PostModeChangeEvent
	ret

SongMode_AbortAndClearBit2:
	anddi8 0x28ac, 251
	call Song_AbortPlayback
	ret

SongMode_StartPlayback:
	cpdi8 3380, 1
	jrl nz, SongMode_StartReturn
	cpdi8 4420, 0
	jrl nz, SongMode_StartReturn
	call SongMode_AbortAndClearBit2
	stdi8 4437, 1
	xor wa, wa
	ldb a, 0x6d
	call UI_PostModeChangeEvent

SongMode_StartReturn:
	ret

SongMode_VoiceStateDisp:
	cp wa, 0xffff
	jr z, VoiceState_SetStatus2
	cp wa, 0xfffe
	jr z, VoiceState_SetStatus3
	cp wa, 0xfffc
	jr z, VoiceState_SetStatus4
	jp VoiceState_SetStatus1AndDispatch

VoiceState_SetStatus2:
	stdi8 4437, 2
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus3:
	stdi8 4437, 3
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus4:
	stdi8 4437, 4
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus1AndDispatch:
	stdi8 4437, 1
	cpdi8 0x8d36, 116
	jr z, PartFormat_PostMode6D
	cpdi8 0x8d36, 112
	jrl z, VoiceState_SqTrSelCaseD
	cpdi8 0x8d36, 117
	jr z, PartFormat_PostMode6E
	cpdi8 0x8d36, 113
	jrl z, VoiceState_SqTrSelCaseF
	cpdi8 0x8d36, 115
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 0x8d36, 111
	jr z, VoiceState_SqTrSelCaseE
	cpdi8 0x8d36, 118
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 0x8d36, 114
	jr z, VoiceState_SqTrSelCaseE
	jp PartFormat_NullRet

PartFormat_PartTypeDisp:
	cpdi8 0x8d36, 116
	jr z, PartFormat_PostMode6D
	cpdi8 0x8d36, 112
	jr z, PartFormat_PostMode6D
	cpdi8 0x8d36, 117
	jr z, PartFormat_PostMode6E
	cpdi8 0x8d36, 113
	jr z, PartFormat_PostMode6E
	cpdi8 0x8d36, 115
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 0x8d36, 111
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 0x8d36, 118
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 0x8d36, 114
	jr z, PartFormat_SendPlaybackCmd
	jp PartFormat_NullRet

PartFormat_PostMode6D:
	xor wa, wa
	ldb a, 0x6d
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_PostMode6E:
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_SendPlaybackCmd:
	call PlayMode_SendStopEvent
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

VoiceState_SqTrSelCaseD:
	call SqTrSel_CaseD
	jr PartFormat_NullRet

VoiceState_SqTrSelCaseF:
	call SqTrSel_CaseF
	jr PartFormat_NullRet

VoiceState_SqTrSelCaseE:
	call SqTrSel_CaseE

PartFormat_NullRet:
	ret

PartFormat_InitFlagBlock:
	ret
	ret
	ret
	ret
	ret
	call	0xf208e1
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	stdi8	3380, 1
	call	0xf208f2
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	4420, 10
	ret
	stdi8	3380, 0
	ret

PartFormat_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, PartFormat_SendStopCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call PartFormat_AbortAndClearBit2
	bitda 2, 3394
	jr z, PartFormat_SendStopCommand
	jr PartFormat_SendStopCommand

PartFormat_SendStopCommand:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent
	ret

PartFormat_AbortAndClearBit2:
	anddi8 0x28ac, 251
	call Song_AbortPlayback
	ret

PartFormat_StartPlayback:
	cpdi8 3380, 1
	jrl nz, PartFormat_StartReturn
	cpdi8 4420, 0
	jrl nz, PartFormat_StartReturn
	call PartFormat_AbortAndClearBit2
	stdi8 4437, 1
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent

PartFormat_StartReturn:
	ret

PlayModeStop_InitFlagBlock:
	ret
	ret
	ret
	ret
	.byte 0xc1, 0x37, 0x8d
	push	xsp
	jrl	z, 1126
	call	0xf2096a
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	stdi8	3380, 1
	call	0xf2097b
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	4420, 10
	ret
	.byte 0xc1
	ldw	iz, 0x3f8d
	jr	nov, 110
	halt
	stdi8	3380, 0
	ret

PlayMode_StopAbortRetZero:
	cpdi8 3380, 1
	jr nz, PlayModeStop_SendStopCmd
	stdi8 3380, 0
	stdi8 4420, 0
	call PlayMode_StopAndAbort
	bitda 2, 3394
	jr z, PlayModeStop_SendStopCmd
	jr PlayModeStop_SendStopCmd

PlayModeStop_SendStopCmd:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent
	ret

PlayMode_StopAndAbort:
	anddi8 0x28ac, 251
	call PlayMode_SendStopEvent
	call Song_AbortPlayback
	ret

PlayMode_SendCommand6C:
	cpdi8 3380, 1
	jrl nz, PlayModeStop_SendReturn
	cpdi8 4420, 0
	jrl nz, PlayModeStop_SendReturn
	call PlayMode_StopAndAbort
	stdi8 4437, 1
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent

PlayModeStop_SendReturn:
	ret

PlayModeStop_ClearFlagBlock:
	ret
	ret
	ret
	ret
	ret
	.byte 0xc1
	ldw	iz, 0x3f8d
	jr	nov, 110
	halt
	stdi8	3380, 0
	ret

; SqSngNameTtlFunc title dispatch
SqSngNameTtl_Dispatch:
	xor wa, wa
	ldb a, 0x73
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	ret

CDlikeSwitch_PlaybackTimer:
	ldda8 w, 4420
	cps w, 0
	jr z, CDlikeTimer_Return
	dec 1, w
	cps w, 5
	jr nz, CDlikeTimer_CheckZeroCount
	cpdi8 0x8d36, 122
	jr z, CDlikeTimer_ResetAccompaniment
	cpdi8 0x8d36, 120
	jr z, CDlikeTimer_ResetAccompaniment
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ResetAccompaniment:
	pushw wa
	anddi8 0x28b2, 249
	anddi8 0x28a7, 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_CheckZeroCount:
	cps w, 0
	jr nz, CDlikeSwTtl_StorePlaybackMode
	cpdi8 0x8d36, 122
	jr z, CDlikeTimer_InitResetState
	cpdi8 0x8d36, 120
	jr z, CDlikeTimer_InitResetState
	cpdi8 0x8d36, 116
	jr z, CDlikeTimer_ShowDocTitle
	cpdi8 0x8d36, 117
	jr z, CDlikeTimer_ShowPdTitle
	cpdi8 0x8d36, 115
	jr z, CDlikeTimer_ShowSongTitle
	cpdi8 0x8d36, 118
	jr z, CDlikeTimer_ShowSongTitle
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ShowPdTitle:
	pushw wa
	call CDlikeSwTtl_ShowPdTitle
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ShowSongTitle:
	pushw wa
	call CDlikeSwTtl_ShowSongTitle
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ShowDocTitle:
	pushw wa
	call CDlikeSwTtl_ShowDocTitle
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_InitResetState:
	pushw wa
	call CDlike_ResetPlaybackState
	popw wa

CDlikeSwTtl_StorePlaybackMode:
	stda8 4420, w

CDlikeTimer_Return:
	ret

CDlike_ResetPlaybackState:
	ei 6
	xor wa, wa
	stda16 1052, xwa
	stda8 1051, a
	stda16 1048, xwa
	stda8 1047, a
	bitda 1, 0x28a7
	jr z, CDlikeReset_SetTimerFlags
	stdi8 1054, 1
	stdi8 1045, 0
	stdi8 1046, 0
	stdi8 1076, 0
	stdi8 1077, 0

CDlikeReset_SetTimerFlags:
	stdi8 1057, 1
	stdi8 1056, 1
	ei 0
	ret

CDlike_InitModeAndLoadBank:
	ordi8 0xb7e2, 64
	ldda8 a, 0xfdad
	stda8 3394, a
	stdi8 3380, 0
	stdi8 4420, 0
	call CDlike_LoadSongBankData
	cpdi8 0x8d36, 119
	jr z, CDlikeSw_NullRet
	cpdi8 0x8d36, 120
	jr z, CDlikeSw_NullRet
	cpdi8 0x8d36, 121
	jr z, CDlikeSw_NullRet
	cpdi8 0x8d36, 122
	jr z, CDlikeSw_NullRet
	call SqTrAs_InitWall
	ldda16 xwa, 0xf19e
	stda16 0x2875, xwa
	stdi16 0xf19e, 0
	stdi16 8980, 0
	ld xiy, 0xf9a0
	ld xix, 0x3cf04
	ldw bc, 0x310
	ldirw

CDlikeSw_NullRet:
	ret

CDlike_LoadSongBankData:
	stdi8 6882, 0
	cpdi16 0xf19e, 0
	jr nz, CDlikeBankLoad_CheckSavedState
	stdi8 6882, 1

CDlikeBankLoad_CheckSavedState:
	ld16_24 xwa, 0x00ffec
	stda16 0xf19e, xwa
	ld xiy, 0xf180
	ld xix, 0xab000
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	add xix, xwa
	ldw bc, 0x800
	ldir85
	cpdi8 6882, 1
	jr nz, CDlikeBankLoad_Return
	stdi16 0xf19e, 0

CDlikeBankLoad_Return:
	ret

CDlike_ExitModeAndRestore:
	call PlayMode_CheckAndAbort
	anddi8 0xb7e2, 191
	anddi8 0x28ac, 251
	stdi8 4420, 0
	bitda 2, 3394
	jr z, CDlikeExit_CheckPlaybackType
	jr CDlikeExit_CheckPlaybackType

CDlikeExit_CheckPlaybackType:
	cpdi8 0x8d37, 119
	jr z, PlayMode_ResetAndSchedule
	cpdi8 0x8d37, 120
	jr z, PlayMode_ResetAndSchedule
	cpdi8 0x8d37, 121
	jr z, PlayMode_ResetAndSchedule
	cpdi8 0x8d37, 122
	jr z, PlayMode_ResetAndSchedule
	stdi8 4330, 1
	call ToneGen_FileIO_RestoreFromBackup
	call SeqTimer_UpdateTempoReg
	call SwbtWr_ResetAllChannels
	call SqTrAs_Setup
	ldda16 xwa, 0x2875
	stda16 0xf19e, xwa

PlayMode_ResetAndSchedule:
	stdi8 3380, 0
	call Audio_CheckSubsystemReady
	ret

SongBank_SwitchAndUpdateTempo:
	st8_24 0x00ffe3, a
	call SongBank_SaveAndReload
	call SeqTimer_PostTempoUpdate
	ret

SongBank_SaveAndReload:
	ldda16 xwa, 0xf22f
	stda16 0x286f, xwa
	ldda16 xwa, 0xf231
	stda16 0x2871, xwa
	call SongBank_LoadToWorkArea
	call SongBank_CheckAccompanimentMode
	anddi8 0x28b1, 254
	ret

SongBank_LoadToWorkArea:
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ldda16 xwa, 0xf19e
	st16_24 0x00ffec, xwa
	ldda16 xwa, 0x286f
	stda16 0xf22f, xwa
	ldda16 xwa, 0x2871
	stda16 0xf231, xwa
	ret

SongBank_CheckAccompanimentMode:
	cpdi8 0xf23d, 255
	jr z, SongBank_EnableAccompaniment
	bitda 2, 0xfdad
	jr z, SongBank_CheckBassMode
	anddi8 0xfdad, 251
	xor a, a
	jr SongBank_SendAccompEvent

SongBank_EnableAccompaniment:
	bitda 2, 0xfdad
	jr nz, SongBank_CheckBassMode
	ordi8 0xfdad, 4
	ldb a, 0x4

SongBank_SendAccompEvent:
	stdi8 4330, 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks

SongBank_CheckBassMode:
	cpdi8 0xf24b, 255
	jr z, SongBank_EnableBassMode
	anddi8 0xfdad, 254
	xor a, a
	jr SongBank_SendBassEvent

SongBank_EnableBassMode:
	ordi8 0xfdad, 1
	ldb a, 0x1

SongBank_SendBassEvent:
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x1
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks
	stdi8 4596, 1
	call BitMapOut_RenderDisplay
	call Audio_CheckSubsystemReady
	ret

; SqTrAs setup handler
SqTrAs_Setup:
	ld xiy, 0xcce
	ld xix, 0xf1a0
	xor bc, bc
	ldb c, 0x10
	ldir85
	ret

; SqTrAs init wall data
SqTrAs_InitWall:
	ld xix, 0xcce
	ld xiy, 0xf1a0
	xor bc, bc
	ldb c, 0x10
	ldir85
	ret

; SqTrAs load inline code
SqTrAs_LoadInline:
	ret

SqAftSetTtlFunc:
	lds32 xhl, 0
	ret

SqSngSelTtlFunc:
	cp xbc, 0x1c00013
	jr nz, SqSngName_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqSngName_ReturnZero
	cp xde, 0x5
	jr ugt, SqSngName_ReturnZero
	add xde, xde
	add xde, 0xe1fffa
	ld de, (xde)
	lda_24 xix, SqTrAs_CondCheck
	jp_dri 8, 0x07, 0xf0, 0xe8

; SqTrAs conditional voice check
SqTrAs_CondCheck:
	.ascii ":;<>"
	call	0xf20087
	.ascii "^\\[Zh"
	incf
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	0xf200c6
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde

SqSngName_ReturnZero:
	lds32 xhl, 0
	ret

SqSngNameTtlFunc:
	cp xbc, 0x1c00013
	jr nz, SqTrAs_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrAs_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrAs_ReturnZero
	add xde, xde
	add xde, 0xe20006
	ld de, (xde)
	lda_24 xix, SQTR_DISPATCH_TABLE_1
	jp_dri 8, 0x07, 0xf0, 0xe8

; Sequencer track dispatch table 1 - Handler for SqTrAsTtlFunc, 6 cases (XDE 0-5)
SQTR_DISPATCH_TABLE_1:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_RetStub2
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqTrAs_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_MiscDataAndCode
	pop xiz
	pop xix
	pop xhl
	pop xde

SqTrAs_ReturnZero:
	lds32 xhl, 0
	ret

SqTrAsTtlFunc:
	cp xbc, 0x1c00007
	jrl z, SqTrAs_EventHandler
	cp xbc, 0x1c00013
	jrl nz, CDlikeSwTtl_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CDlikeSwTtl_ReturnZero2
	cp xde, 0x5
	jrl ugt, CDlikeSwTtl_ReturnZero2
	add xde, xde
	add xde, 0xe20012
	ld de, (xde)
	lda_24 xix, SQTR_DISPATCH_TABLE_2
	jp_dri 8, 0x07, 0xf0, 0xe8
; Sequencer track dispatch table 2 - SqTrAsTtlFunc handler
; 6 dispatch cases (XDE 0-5)
SQTR_DISPATCH_TABLE_2:
	ld xwa, 0x8b0004
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call ApPostEvent
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_JumpStubData
	pop xiz
	pop xix
	pop xhl
	pop xde
	setda 0, 0x8f5c	; F20DAD: LD (XIX+5Ch), 0B8h (TMP94C241 encoding)
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit
	ldmmb_dd24 0x82, 0x10, 0x02, 0x73, 0x28
	jr CDlikeSwTtl_ReturnZero2
SQTR_DISPATCH_TABLE_2_CASE1:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_InlineCodeBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	resda 0, 0x8f5c	; F20DCD: LD (XIX+5Ch), 0B0h (TMP94C241 encoding)
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit
	jr CDlikeSwTtl_ReturnZero2
SQTR_DISPATCH_TABLE_2_CASE2:
	cpdi8 0x8d36, 139
	jr nz, CDlikeSwTtl_ReturnZero2
	cpdi8 0x7f42, 35
	scc16 z, bc
	cpdi8 0x8d39, 238
	scc16 z, wa
	and wa, bc
	jr z, SQTR_DISPATCH_TABLE_2_CASE5
	ld xwa, 0x8b0004
	ld xbc, 0x1e0008e
	ld xde, 0xffff0002
	call ApPostEvent
	jr CDlikeSwTtl_ReturnZero2
SQTR_DISPATCH_TABLE_2_CASE5:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_UpdateSlotIndex
	ldmmb_dd24 0x82, 0x10, 0x02, 0x73, 0x28
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr CDlikeSwTtl_ReturnZero2
; SqTrAs event handler
SqTrAs_EventHandler:
	cp xde, 0xb
	jr nz, CDlikeSwTtl_ReturnZero2
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_EventHandler
	pop xiz
	pop xix
	pop xhl
	pop xde

CDlikeSwTtl_ReturnZero2:
	lds32 xhl, 0
	ret

SqTrAsSureFunc:
	cp xbc, 0x1c00007
	jr nz, SqTrAsPs_ReturnZero
	cp xde, 0xf
	jr z, SqTrAsPsTtl_CaseB
	cp xde, 0xb
	jr z, SqTrAsPsTtl_CaseA
	cp xde, 0xa
	jr nz, SqTrAsPs_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_SlotSetup
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqTrAsPs_ReturnZero

; SqTrAsPsTtl case A
SqTrAsPsTtl_CaseA:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_SlotUpdate
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqTrAsPsTtl_CaseC

; SqTrAsPsTtl case B
SqTrAsPsTtl_CaseB:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_SlotUpdate
	pop xiz
	pop xix
	pop xhl
	pop xde

; SqTrAsPsTtl case C
SqTrAsPsTtl_CaseC:
	ldmmb_dd24 0x82, 0x10, 0x02, 0x73, 0x28

SqTrAsPs_ReturnZero:
	lds32 xhl, 0
	ret

SqTrAsPsTtlFunc:
	cp xbc, 0x1c00007
	jr z, SqTrAsPsTtl_CaseD
	cp xbc, 0x1c00013
	jrl nz, SqTrAsPsTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrAsPsTtl_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrAsPsTtl_ReturnZero
	add xde, xde
	add xde, 0xe2001e
	ld de, (xde)
	lda_24 xix, SqTrAsPsTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
SqTrAsPsTtl_Dispatch:	.ascii ":;<>"
	call	SetWall_DataBlock1
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 0x8c0004
	ld	xbc, 0x01e0004d
	lds32	xde, 1
	call	ApPostEvent
	ld	xwa, 0x8c0005
	ld	xbc, 0x01e0004d
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x8c0006
	ld	xbc, 0x01e0004d
	lds32	xde, 0
	call	ApPostEvent
	.ascii "h\":;<>"
	call	0xf1f10b
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	20

; SqTrAsPsTtl case D
SqTrAsPsTtl_CaseD:
	cp xde, 0xb
	jr nz, SqTrAsPsTtl_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_ACSlotChange
	pop xiz
	pop xix
	pop xhl
	pop xde

SqTrAsPsTtl_ReturnZero:
	lds32 xhl, 0
	ret

SqTrAsPsSureFunc:
	cp xbc, 0x1c00007
	jr nz, SetWall_ReturnZero
	cp xde, 0xb
	jr z, SqTrAsPsTtl_CaseE
	cp xde, 0xa
	jr nz, SetWall_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_LocalSlotChange
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SetWall_ReturnZero

; SqTrAsPsTtl case E
SqTrAsPsTtl_CaseE:
	push xde
	push xhl
	push xix
	push xiz
	call SetWall_ExternalSync
	pop xiz
	pop xix
	pop xhl
	pop xde

SetWall_ReturnZero:
	lds32 xhl, 0
	ret

; SqTrAsPsTtl case F
SqTrAsPsTtl_CaseF:
	ldda8	a, 0x8d36
	extz	wa
	sub	wa, 108
	cps	wa, 0
	jr	lt, 41
	cp	wa, 13
	jr	gt, 35
	lda_24	xix, 0xe2002a
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 216
	ccf
	sll	wa, 1
	ld	xix, 0xe20038
	.byte 0xd3
	reti
	.byte 0xf0, 0xe0
	ldb	w, 242
	.byte 0x8c
	retd	0x34f2
	.byte 0xf3
	reti
	.byte 0xf0, 0xe0, 0xd8
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CDlike_ExitModeAndRestore
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret

SqMdlyPlyTtlFunc:
	cp xbc, 0x1c00007
	jr z, SqMdlyPly_InitPlay
	cp xbc, 0x1c00013
	jrl nz, SqMdlyPly_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqMdlyPly_ReturnZero
	cp xde, 0x5
	jr ugt, SqMdlyPly_ReturnZero
	add xde, xde
	add xde, 0xe2003c
	ld de, (xde)
	lda_24 xix, SqMdlyPlyTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
SqMdlyPlyTtl_Dispatch:	.ascii ":;<>"
	call	PlayMode_InitFlagBlock
	.ascii "^\\[ZhL:;<>"
	call	PlayMode_ClearModeFlag
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	65384
	jr	59

; SqMdlyPly init playback
SqMdlyPly_InitPlay:
	cp xde, 0xf
	jr z, SqMdlyPly_CheckState
	cp xde, 0x8a
	jr z, SqMdlyPly_SendAudioCmd
	cp xde, 0xa
	jr nz, SqMdlyPly_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_StartAndSendCommand
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqMdlyPly_ReturnZero

; SqMdlyPly send audio command
SqMdlyPly_SendAudioCmd:
	ldw wa, 0xa5
	call SoundCtrl_SendCommand
	jr SqMdlyPly_ReturnZero

; SqMdlyPly check playback state
SqMdlyPly_CheckState:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_CheckAndDispatch
	pop xiz
	pop xix
	pop xhl
	pop xde

SqMdlyPly_ReturnZero:
	lds32 xhl, 0
	ret

DkMdlyPlyTtlFunc:
	cp xbc, 0x1c00007
	jr z, DkMdlyPly_InitPlay
	cp xbc, 0x1c00013
	jrl nz, DkMdlyPly_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, DkMdlyPly_ReturnZero
	cp xde, 0x5
	jr ugt, DkMdlyPly_ReturnZero
	add xde, xde
	add xde, 0xe20048
	ld de, (xde)
	lda_24 xix, DkMdlyPlyTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
DkMdlyPlyTtl_Dispatch:	.ascii ":;<>"
	call	PlayMode_InitFlagBlock
	.ascii "^\\[ZhL:;<>"
	call	PlayMode_ClearModeFlag
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	65236
	jr	59

; DkMdlyPly init playback
DkMdlyPly_InitPlay:
	cp xde, 0xf
	jr z, DkMdlyPly_CheckPlayState
	cp xde, 0x8a
	jr z, DkMdlyPly_SendAudioA5
	cp xde, 0xa
	jr nz, DkMdlyPly_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_StartAndSendCommand
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DkMdlyPly_ReturnZero

DkMdlyPly_SendAudioA5:
	ldw wa, 0xa5
	call SoundCtrl_SendCommand
	jr DkMdlyPly_ReturnZero

DkMdlyPly_CheckPlayState:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_CheckAndDispatch
	pop xiz
	pop xix
	pop xhl
	pop xde

DkMdlyPly_ReturnZero:
	lds32 xhl, 0
	ret

; DkMdlyPly send audio command
DkMdlyPly_SendAudioCmd:
	lds hl, 0
	lda_24 xde, 0xe20054

DkMdlyPly_VoiceScanLoop:
	ld bc, hl
	add bc, bc
	ld_sriw3 BC, 0x07, 0xe8, 0xe4
	and bc, wa
	ret nz
	inc 1, hl
	cp hl, 0x10
	jr lt, DkMdlyPly_VoiceScanLoop
	ret

; DkMdlyPly check playback state
DkMdlyPly_CheckState:
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	ldda8 a, 0x8d36
	cp a, 0x6f
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x72
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x73
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x76
	jr nz, DkMdlyPly_Finalize

Snd_ParamLookupSetupWerp:
	ldi_werp 0xfa, 0

; DkMdlyPly handle result
DkMdlyPly_HandleResult:
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe20074
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	ldw bc, 0x401
	call SndParam_LookupViaEncode
	ld iz, hl
	ld wa, (xsp + 4)
	calr DkMdlyPly_SendAudioCmd
	cp hl, iz
	jr nz, DkMdlyPly_ExtendedCheck
	ldto_werp WA, 0xfa
	add wa, wa
	lda_24 xbc, 0xe20074
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
	stda8 0x8d3a, a
	ld e, a
	extz de
	pushw 0xff
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	call AudioMode_ResetVoiceState
	jr DkMdlyPly_Finalize

; DkMdlyPly extended check
DkMdlyPly_ExtendedCheck:
	inc1_werp 0xfa
	cp_erpw 0xfa, 0x20, 0x00
	jr lt, DkMdlyPly_HandleResult

; DkMdlyPly finalize
DkMdlyPly_Finalize:
	pop xiz
	inc 2, xsp
	ret

DisplayMode_DispatchEvents:
	ldda8 a, 0x8d36
	extz wa
	sub wa, 0x6f
	cps wa, 0
	ret lt
	cps wa, 6
	ret gt
	add wa, wa
	lda_24 xix, 0xe200b4
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, DisplayMode_BatchEventSend
	jp_dri 8, 0x07, 0xf0, 0xe0

; --- DisplayMode_BatchEventSend: Dispatch events for display mode transitions ---
; Multiple entry points, each dispatching 2-3 events for a specific mode.
; Pattern per entry: XWA=event_id, XBC=0x1e0043b (target), XDE=0 (param),
;   then call EventDispatch (0xfac558) or jump to common tail.
; Event IDs encode mode/sub-function: 0x6f000a, 0x70000x, 0x73000c, etc.
DisplayMode_BatchEventSend:
	ld	xwa, 0x6f000a
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	jrl	165
	ld	xwa, 0x73000c
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	jrl	150
	ld	xwa, 0x700007
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x700008
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x700009
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	jr	104
	ld	xwa, 0x74000a
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x74000b
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x74000c
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	jr	58
	ld	xwa, 0x710007
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x710008
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	jr	28
	ld	xwa, 0x750009
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ld	xwa, 0x75000a
	ld	xbc, 0x01e0003b
	lds32	xde, 0
	call	ApPostEvent
	ret

DisplayMode_RefreshState:
	ld16_24 xwa, 0x021086
	calr DkMdlyPly_CheckState
	ld16_24 xwa, 0x021086
	jp FileIO_ReadChunk

DpMdlyDocTtlFunc:
	cp xbc, 0x1c00007
	jr z, DpMdlyDoc_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpMdlyDoc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlyDoc_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlyDoc_ReturnZero
	add xde, xde
	add xde, 0xe200c2
	ld de, (xde)
	lda_24 xix, DpMdlyDocTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpMdlyDocTtlFunc title dispatch
DpMdlyDocTtl_Dispatch:
	sti16_24	0x021086, 0
	calr	65452
	calr	65224
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	0xf20776
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	call	0xf20797
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	64679
	jr	72

; DpMdlyDoc case A
DpMdlyDoc_CaseA:
	cp xde, 0xf
	jr z, DpMdlyDoc_CaseE
	cp xde, 0x8c
	jr z, DpMdlyDoc_CaseD
	cp xde, 0x89
	jr z, DpMdlyDoc_CaseB
	cp xde, 0x8a
	jr nz, DpMdlyDoc_ReturnZero
	ldw wa, 0xa5
	jr DpMdlyDoc_CaseC

; DpMdlyDoc case B
DpMdlyDoc_CaseB:
	ldw wa, 0xd6

; DpMdlyDoc case C
DpMdlyDoc_CaseC:
	call SoundCtrl_SendCommand
	jr DpMdlyDoc_ReturnZero

; DpMdlyDoc case D
DpMdlyDoc_CaseD:
	push xde
	push xhl
	push xix
	push xiz
	call SongMode_StartPlayback
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlyDoc_ReturnZero

; DpMdlyDoc case E
DpMdlyDoc_CaseE:
	push xde
	push xhl
	push xix
	push xiz
	call SongMode_CheckAndDispatch
	pop xiz
	pop xix
	pop xhl
	pop xde

DpMdlyDoc_ReturnZero:
	lds32 xhl, 0
	ret

DpMdlyPdTtlFunc:
	cp xbc, 0x1c00007
	jr z, DpMdlyPd_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpMdlyPd_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlyPd_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlyPd_ReturnZero
	add xde, xde
	add xde, 0xe200ce
	ld de, (xde)
	lda_24 xix, DpMdlyPdTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpMdlyPdTtlFunc title dispatch
DpMdlyPdTtl_Dispatch:
	sti16_24	0x021086, 0
	calr	65276
	calr	65048
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	0xf208dc
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	call	0xf208fd
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	64503
	jr	72

; DpMdlyPd case A
DpMdlyPd_CaseA:
	cp xde, 0xf
	jr z, DpMdlyPd_CaseE
	cp xde, 0x8c
	jr z, DpMdlyPd_CaseD
	cp xde, 0x89
	jr z, DpMdlyPd_CaseB
	cp xde, 0x8a
	jr nz, DpMdlyPd_ReturnZero
	ldw wa, 0xa5
	jr DpMdlyPd_CaseC

; DpMdlyPd case B
DpMdlyPd_CaseB:
	ldw wa, 0xd6

; DpMdlyPd case C
DpMdlyPd_CaseC:
	call SoundCtrl_SendCommand
	jr DpMdlyPd_ReturnZero

; DpMdlyPd case D
DpMdlyPd_CaseD:
	push xde
	push xhl
	push xix
	push xiz
	call PartFormat_StartPlayback
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlyPd_ReturnZero

; DpMdlyPd case E
DpMdlyPd_CaseE:
	push xde
	push xhl
	push xix
	push xiz
	call PartFormat_CheckAndDispatch
	pop xiz
	pop xix
	pop xhl
	pop xde

DpMdlyPd_ReturnZero:
	lds32 xhl, 0
	ret

DpMdlySmfTtlFunc:
	cp xbc, 0x1c00007
	jr z, DpMdlySmf_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpMdlySmf_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlySmf_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlySmf_ReturnZero
	add xde, xde
	add xde, 0xe200da
	ld de, (xde)
	lda_24 xix, DpMdlySmfTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpMdlySmfTtlFunc title dispatch
DpMdlySmfTtl_Dispatch:
	cpdi8	0x8d37, 118
	jr	z, 19
	sti8_24	0x021088, 0
	sti16_24	0x021086, 0
	calr	65087
	calr	64859
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	0xf2095e
	.ascii "^\\[ZhY:;<>"
	call	0xf20986
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	64314
	jr	72

; DpMdlySmf case A
DpMdlySmf_CaseA:
	cp xde, 0xf
	jr z, DpMdlySmf_CaseE
	cp xde, 0x8c
	jr z, DpMdlySmf_CaseD
	cp xde, 0x89
	jr z, DpMdlySmf_CaseB
	cp xde, 0x8a
	jr nz, DpMdlySmf_ReturnZero
	ldw wa, 0xa5
	jr DpMdlySmf_CaseC

; DpMdlySmf case B
DpMdlySmf_CaseB:
	ldw wa, 0xd6

; DpMdlySmf case C
DpMdlySmf_CaseC:
	call SoundCtrl_SendCommand
	jr DpMdlySmf_ReturnZero

; DpMdlySmf case D
DpMdlySmf_CaseD:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_SendCommand6C
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlySmf_ReturnZero

; DpMdlySmf case E
DpMdlySmf_CaseE:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_StopAbortRetZero
	pop xiz
	pop xix
	pop xhl
	pop xde

DpMdlySmf_ReturnZero:
	lds32 xhl, 0
	ret

DpMdlySmfLyrTtlFunc:
	cp xbc, 0x1c00007
	jrl z, DpMdlySmfLyr_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpMdlySmfLyr_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlySmfLyr_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlySmfLyr_ReturnZero
	add xde, xde
	add xde, 0xe200e6
	ld de, (xde)
	lda_24 xix, DpMdlySmfLyrTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpMdlySmfLyrTtlFunc title dispatch
DpMdlySmfLyrTtl_Dispatch:
	ldda8	a, 0x8d37
	cp	a, 108
	jr	nz, 38
	cp	a, 118
	jr	z, 19
	sti8_24	0x021088, 0
	sti16_24	0x021086, 0
	calr	64890
	calr	64662
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	0xf2095e
	.ascii "^\\[Zh"
	incf
	push xde
	push xhl
	push xix
	push xiz
	call	0xf209f2
	aligned_string "^\\[Z@&"
	jr	nc, 0x00
	ld	xbc, 0x01c7000a
	lds32	xde, 0
	jr	t, 29
	push xde
	push xhl
	push xix
	push xiz
	call	0xf209f3
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr	0xfa5b
	.asciz "hM@&"
	jr	nc, 0
	ld	xbc, 0x01c7000a
	lds32	xde, 0
	call	ApPostEvent
	jr	59

; DpMdlySmfLyr case A
DpMdlySmfLyr_CaseA:
	cp xde, 0xf
	jr z, DpMdlySmfLyr_CaseC
	cp xde, 0x8c
	jr z, DpMdlySmfLyr_CaseB
	cp xde, 0x88
	jr nz, DpMdlySmfLyr_ReturnZero
	ldw wa, 0xd6
	call SoundCtrl_SendCommand
	jr DpMdlySmfLyr_ReturnZero

; DpMdlySmfLyr case B
DpMdlySmfLyr_CaseB:
	push xde
	push xhl
	push xix
	push xiz
	call PlayMode_SendCommand6C
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlySmfLyr_ReturnZero

; DpMdlySmfLyr case C
DpMdlySmfLyr_CaseC:
	push xde
	push xhl
	push xix
	push xiz
	call SqSngNameTtl_Dispatch
	pop xiz
	pop xix
	pop xhl
	pop xde

DpMdlySmfLyr_ReturnZero:
	lds32 xhl, 0
	ret

NameGetFuncCall:
	sub xbc, 0x1e7000d
	cp xbc, 0x0
	jrl lt, NameGetFunc_Entry
	cp xbc, 0xd
	jrl gt, NameGetFunc_Entry
	add xbc, xbc
	add xbc, 0xe20120
	ld bc, (xbc)
	lda_24 xix, NameGetFuncCall_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe4
; NameGetFuncCall dispatch
NameGetFuncCall_Dispatch:
	pushw	16
	pushw	0
	pushw	0xf280
	pushw	0
	pushw	6888
	call	Strncpy
	ldada	xwa, 6888
	ld	(xwa+16), 0
	push	xwa
	ld8_24	a, 0xffe3
	inc	1, a
	extz	wa
	pushw	wa
	pushw	226
	pushw	242
	pushw	0
	pushw	7248
	call	Sprintf_Locked
	lda	xsp, (xsp+24)
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70000
	lds32	xde, 0
	jrl	621
	call	GetCurrentFileIndex
	ld	wa, hl
	call	GetFileEntryPtr
	push	xhl
	call	GetCurrentFileIndex
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	252
	pushw	0
	pushw	7270
	call	Sprintf_Locked
	lda	xsp, (xsp+14)
	stdi8	7283, 0
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70001
	lds32	xde, 0
	jrl	564
	call	GetFirstPageBase
	ld	wa, hl
	call	GetRecordPtrForFile
	push	xhl
	call	GetFirstPageBase
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	264
	pushw	0
	pushw	7284
	call	Sprintf_Locked
	lda	xsp, (xsp+14)
	ldada	xwa, 7284
	ld	(xwa+16), 0
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70002
	lds32	xde, 0
	jrl	500
	pushw	20
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7304
	call	Strncpy
	lda	xsp, (xsp+10)
	ldada	xwa, 7304
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	bc, 0x3f81
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70003
	lds32	xde, 0
	jrl	424
	call	FileIO_GetCurrentFileIndex_Alt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	272
	pushw	0
	pushw	7362
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	stdi8	7365, 0
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70006
	lds32	xde, 0
	jrl	378
	pushw	12
	call	FileIO_GetCurrentFileIndex_Alt
	ld	wa, hl
	call	FileIO_GetFileEntryWithRefresh
	push	xhl
	pushw	0
	pushw	7326
	call	Strncpy
	lda	xsp, (xsp+10)
	ldada	xwa, 7326
	ld	(xwa+12), 0
	ldw	de, 11
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	bc, 0x3f81
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70005
	lds32	xde, 0
	jrl	302
	call	GetCurrentFileIndexAlt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	280
	pushw	0
	pushw	7366
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	stdi8	7369, 0
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70008
	lds32	xde, 0
	jrl	256
	call	GetCurrentFileIndexAlt
	ld	wa, hl
	call	GetFileRecordPtr
	push	xhl
	pushw	0
	pushw	7340
	call	Strcpy
	inc	8, xsp
	ldada	xwa, 7340
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	bc, 0x3f81
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c70007
	lds32	xde, 0
	jrl	184
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7370
	call	Strcpy
	pushw	20
	pushw	0
	pushw	7370
	pushw	2
	pushw	4174
	call	Strncpy
	lda	xsp, (xsp+18)
	lda_24	xwa, 0x02104e
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3
	reti
	.byte 0xe0, 0xe8
	ldw	bc, 0x3f81
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c7000f
	lds32	xde, 0
	jr	92
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7370
	call	Strcpy
	pushw	59
	pushw	0
	pushw	7370
	call	NumFormat_DivideAndC_Data
	lda	xsp, (xsp+14)
	lda_24	xwa, 0x021064
	or	xhl, xhl
	jr	z, 22
	inc	1, xhl
	pushw	28
	push	xhl
	push	xwa
	call	Strncpy
	lda	xsp, (xsp+10)
	sti8_24	0x021080, 0
	jr	3
	ld	(xwa), 0
	ld	xwa, 0x021064
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c7000e
	lds32	xde, 0
	call	ApPostEvent

; NameGetFuncCall entry handler
NameGetFunc_Entry:
	lds32 xhl, 0
	ret

CDlikeSwTtlFunc:
	cp xbc, 0x1c00007
	jr nz, CDlikeSwTtl_ReturnZero
	cp xde, 0x85
	jr z, CDlikeSwTtl_ReturnZero
	cp xde, 0x5
	jr z, CDlikeSwTtl_ReturnZero
	cp xde, 0x84
	jr z, CDlikeSwTtl_ReturnZero
	cp xde, 0x4
	jr z, CDlikeSwTtl_ReturnZero
	cp xde, 0x83
	jr z, CDlikeSwTtl_ReturnZero

CDlikeSwTtl_ReturnZero:
	lds32 xhl, 0
	ret

CDlikeSwTtl_ShowSongTitle:
	call SeqState_GetFlags
	bit 0, hl
	ret nz
	ld xwa, 0x720006
	ld xbc, 0x1c70010
	lds32 xde, 0
	call ApPostEvent
	pushw 0xc
	call GetFirstPageBase
	ld wa, hl
	call GetRecordPtrForFile
	push xhl
	pushw 0x0
	pushw 0x1c1e
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7198
	ld (xbc + 12), 0x0
	lds wa, 1
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, SongMode_VoiceStateDisp
	calr SeqRecPlay_EnableRecordOnly
	stdi8 4437, 0
	ret

CDlikeSwTtl_ShowDocTitle:
	call SeqState_GetFlags
	bit 0, hl
	ret nz
	pushw 0xc
	call FileIO_GetCurrentFileIndex_Alt
	ld wa, hl
	call FileIO_GetFileEntryByIndex
	push xhl
	pushw 0x0
	pushw 0x1c2c
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7212
	ld (xbc + 12), 0x0
	lds wa, 2
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, SongMode_VoiceStateDisp
	calr SeqRecPlay_EnableRecordOnly
	stdi8 4437, 0
	ret

CDlikeSwTtl_ShowPdTitle:
	call SeqState_GetFlags
	bit 0, hl
	ret nz
	pushw 0x14
	call GetCurrentFileIndexAlt
	ld wa, hl
	call GetFileRecordPtr
	push xhl
	pushw 0x0
	pushw 0x1c3a
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7226
	ld (xbc + 20), 0x0
	lds wa, 4
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, SongMode_VoiceStateDisp
	calr SeqRecPlay_EnableRecordOnly
	stdi8 4437, 0
	ret

CDlikeSwTtl_SongBit1Check:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_SongBit0Check
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	lds32 xde, 0
	jr CDlikeSwTtl_JumpToFA9D58

CDlikeSwTtl_SongBit0Check:
	call SeqState_GetFlags
	bit 0, hl
	jrl z, CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	lds32 xde, 0

CDlikeSwTtl_JumpToFA9D58:
	jp ApPostEvent

CDlikeSwTtl_DocBitCheck:
	call SeqState_GetFlags
	bit 1, hl
	jr nz, CDlikeSwTtl_DocRedraw
	call SeqState_GetFlags
	bit 0, hl
	jrl z, CDlikeSwTtl_ShowDocTitle

CDlikeSwTtl_DocRedraw:
	calr SeqRecPlay_DisableBoth
	jp Song_AbortPlayback

CDlikeSwTtl_PdBitCheck:
	call SeqState_GetFlags
	bit 1, hl
	jr nz, CDlikeSwTtl_PdRedraw
	call SeqState_GetFlags
	bit 0, hl
	jrl z, CDlikeSwTtl_ShowPdTitle

CDlikeSwTtl_PdRedraw:
	calr SeqRecPlay_DisableBoth
	jp Song_AbortPlayback

CDlikeSwTtl_SongConfirmStart:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_SongConfirmBit0
	stdi8 7498, 3
	jr CDlikeSwTtl_SongConfirmJump

CDlikeSwTtl_SongConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_SongConfirmDefault
	stdi8 7498, 2
	jr CDlikeSwTtl_SongConfirmJump

CDlikeSwTtl_SongConfirmDefault:
	stdi8 7498, 1
	calr CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_SongConfirmJump:
	jp Acc_StartFillIn

CDlikeSwTtl_SongConfirmDispatch:
	ldda8 a, 7498
	cps a, 2
	jr z, CDlikeSwTtl_SongConfirmState2
	cps a, 1
	jr z, CDlikeSwTtl_SongConfirmState1
	cps a, 3
	ret nz

CDlikeSwTtl_SongConfirmState1:
	calr SeqRecPlay_EnablePlayOnly
	jp Acc_TransitionPlayMode

CDlikeSwTtl_SongConfirmState2:
	calr SeqRecPlay_EnableRecordOnly
	jp Acc_StopPlayMode

CDlikeSwTtl_DocConfirmStart:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_DocConfirmBit0
	stdi8 7498, 3
	jr CDlikeSwTtl_DocConfirmJump

CDlikeSwTtl_DocConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_DocConfirmDefault
	stdi8 7498, 2
	jr CDlikeSwTtl_DocConfirmJump

CDlikeSwTtl_DocConfirmDefault:
	stdi8 7498, 1
	calr CDlikeSwTtl_ShowDocTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_DocConfirmJump:
	jp Acc_StartFillIn

CDlikeSwTtl_PdConfirmStart:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_PdConfirmBit0
	stdi8 7498, 3
	jr CDlikeSwTtl_PdConfirmJump

CDlikeSwTtl_PdConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_PdConfirmDefault
	stdi8 7498, 2
	jr CDlikeSwTtl_PdConfirmJump

CDlikeSwTtl_PdConfirmDefault:
	stdi8 7498, 1
	calr CDlikeSwTtl_ShowPdTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_PdConfirmJump:
	jp Acc_StartFillIn

CDlikeSwTtl_SongNavDispatch:
	pushw iz
	ld iz, wa
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_SongNavBit0
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	lds32 xde, 0
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e7000f
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e7001a
	lds32 xde, 0
	jr CDlikeSwTtl_SongNavFinishNames

CDlikeSwTtl_SongNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_SongNavNoRedraw
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, 0x1c70009
	lds32 xde, 0
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e7000f
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e7001a
	lds32 xde, 0

CDlikeSwTtl_SongNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowSongTitle
	jr CDlikeSwTtl_SongNavReturn

CDlikeSwTtl_SongNavNoRedraw:
	ld wa, iz
	call NavigateSongList
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e7000f
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e7001a
	lds32 xde, 0
	calr NameGetFuncCall

CDlikeSwTtl_SongNavReturn:
	popw iz
	ret

CDlikeSwTtl_DocNavDispatch:
	pushw iz
	ld iz, wa
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_DocNavBit0
	call Song_AbortPlayback
	ld wa, iz
	call NavigateDocList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70012
	lds32 xde, 0
	jr CDlikeSwTtl_DocNavFinishNames

CDlikeSwTtl_DocNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_DocNavNoRedraw
	call Song_AbortPlayback
	ld wa, iz
	call NavigateDocList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70012
	lds32 xde, 0

CDlikeSwTtl_DocNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowDocTitle
	jr CDlikeSwTtl_DocNavReturn

CDlikeSwTtl_DocNavNoRedraw:
	ld wa, iz
	call NavigateDocList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70012
	lds32 xde, 0
	calr NameGetFuncCall

CDlikeSwTtl_DocNavReturn:
	popw iz
	ret

CDlikeSwTtl_PdNavDispatch:
	pushw iz
	ld iz, wa
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_PdNavBit0
	call Song_AbortPlayback
	ld wa, iz
	call NavigatePdList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70014
	lds32 xde, 0
	jr CDlikeSwTtl_PdNavFinishNames

CDlikeSwTtl_PdNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_PdNavNoRedraw
	call Song_AbortPlayback
	ld wa, iz
	call NavigatePdList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70014
	lds32 xde, 0

CDlikeSwTtl_PdNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowPdTitle
	jr CDlikeSwTtl_PdNavReturn

CDlikeSwTtl_PdNavNoRedraw:
	ld wa, iz
	call NavigatePdList
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, 0x1e70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, 0x1e70014
	lds32 xde, 0
	calr NameGetFuncCall

CDlikeSwTtl_PdNavReturn:
	popw iz
	ret

DpDocTtlFunc:
	cp xbc, 0x1c00009
	jrl z, DpDoc_CaseI
	cp xbc, 0x1c00008
	jrl z, DpDoc_CaseG
	cp xbc, 0x1c00007
	jr z, DpDoc_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpDocTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpDocTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpDocTtl_ReturnZero
	add xde, xde
	add xde, 0xe20150
	ld de, (xde)
	lda_24 xix, DpDocTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpDocTtlFunc title dispatch
DpDocTtl_Dispatch:
	sti16_24	0x021086, 0
	calr	62678
	calr	62450
	calr	64337
	jrl	206
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, 7
	calr	3398
	call	Song_AbortPlayback
	calr	61909
	jrl	184

; DpDocTtl case A
DpDoc_CaseA:
	ld xwa, xde
	cp xde, 0x5
	jr z, DpDoc_CaseE
	cp xde, 0x3
	jr z, DpDoc_CaseD
	cp xde, 0x2
	jr z, DpDoc_CaseC
	cp xde, 0x1
	jr z, DpDoc_CaseB
	sub xwa, 0x81
	cp xwa, 0x0
	jrl c, DpDocTtl_ReturnZero
	cp xwa, 0x9
	jr ugt, DpDocTtl_ReturnZero
	add xwa, xwa
	add xwa, 0xe2013c
	ld wa, (xwa)
	lda_24 xix, DpDoc_CaseB
	jp_dri 8, 0x07, 0xf0, 0xe0

; DpDocTtl case B
DpDoc_CaseB:
	ldw wa, 0xffff
	jr DpDoc_NavigateBackward

; DpDocTtl case C
DpDoc_CaseC:
	call SeqState_GetFlags
	bit 1, hl
	jr z, DpDoc_CheckBit0PlayMode
	calr SeqRecPlay_EnableRecordOnly
	call Acc_StopPlayMode
	jr DpDocTtl_ReturnZero

DpDoc_CheckBit0PlayMode:
	call SeqState_GetFlags
	bit 0, hl
	jr z, DpDocTtl_ReturnZero
	calr SeqRecPlay_EnablePlayOnly
	call Acc_TransitionPlayMode
	jr DpDocTtl_ReturnZero

; DpDocTtl case D
DpDoc_CaseD:
	calr CDlikeSwTtl_DocBitCheck
	jr DpDocTtl_ReturnZero

; DpDocTtl case E
DpDoc_CaseE:
	lds wa, 1

DpDoc_NavigateBackward:
	calr CDlikeSwTtl_DocNavDispatch
	jr DpDocTtl_ReturnZero
	ldw wa, 0xa5
	jr DpDoc_CaseF
	ldw wa, 0xd6

; DpDocTtl case F
DpDoc_CaseF:
	call SoundCtrl_SendCommand
	jr DpDocTtl_ReturnZero

; DpDocTtl case G
DpDoc_CaseG:
	cp xde, 0x84
	jr z, DpDoc_CaseH
	cp xde, 0x4
	jr nz, DpDocTtl_ReturnZero

; DpDocTtl case H
DpDoc_CaseH:
	calr CDlikeSwTtl_DocConfirmStart
	jr DpDocTtl_ReturnZero

; DpDocTtl case I
DpDoc_CaseI:
	cp xde, 0x84
	jr z, DpDoc_CaseJ
	cp xde, 0x4
	jr nz, DpDocTtl_ReturnZero

; DpDocTtl case J
DpDoc_CaseJ:
	calr CDlikeSwTtl_SongConfirmDispatch

DpDocTtl_ReturnZero:
	lds32 xhl, 0
	ret

DpPdTtlFunc:
	cp xbc, 0x1c00009
	jrl z, DpPd_CaseI
	cp xbc, 0x1c00008
	jrl z, DpPd_CaseG
	cp xbc, 0x1c00007
	jr z, DpPd_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpPdTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpPdTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpPdTtl_ReturnZero
	add xde, xde
	add xde, 0xe20170
	ld de, (xde)
	lda_24 xix, DpPdTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpPdTtlFunc title dispatch
DpPdTtl_Dispatch:
	sti16_24	0x021086, 0
	calr	62375
	calr	62147
	calr	64102
	jrl	206
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, 7
	calr	3095
	call	Song_AbortPlayback
	calr	61606
	jrl	184

; DpPdTtl case A
DpPd_CaseA:
	ld xwa, xde
	cp xde, 0x5
	jr z, DpPd_CaseE
	cp xde, 0x3
	jr z, DpPd_CaseD
	cp xde, 0x2
	jr z, DpPd_CaseC
	cp xde, 0x1
	jr z, DpPd_CaseB
	sub xwa, 0x81
	cp xwa, 0x0
	jrl c, DpPdTtl_ReturnZero
	cp xwa, 0x9
	jr ugt, DpPdTtl_ReturnZero
	add xwa, xwa
	add xwa, 0xe2015c
	ld wa, (xwa)
	lda_24 xix, DpPd_CaseB
	jp_dri 8, 0x07, 0xf0, 0xe0

; DpPdTtl case B
DpPd_CaseB:
	ldw wa, 0xffff
	jr DpPd_NavigateBackward

; DpPdTtl case C
DpPd_CaseC:
	call SeqState_GetFlags
	bit 1, hl
	jr z, DpPd_CheckBit0PlayMode
	calr SeqRecPlay_EnableRecordOnly
	call Acc_StopPlayMode
	jr DpPdTtl_ReturnZero

DpPd_CheckBit0PlayMode:
	call SeqState_GetFlags
	bit 0, hl
	jr z, DpPdTtl_ReturnZero
	calr SeqRecPlay_EnablePlayOnly
	call Acc_TransitionPlayMode
	jr DpPdTtl_ReturnZero

; DpPdTtl case D
DpPd_CaseD:
	calr CDlikeSwTtl_PdBitCheck
	jr DpPdTtl_ReturnZero

; DpPdTtl case E
DpPd_CaseE:
	lds wa, 1

DpPd_NavigateBackward:
	calr CDlikeSwTtl_PdNavDispatch
	jr DpPdTtl_ReturnZero
	ldw wa, 0xa5
	jr DpPd_CaseF
	ldw wa, 0xd6

; DpPdTtl case F
DpPd_CaseF:
	call SoundCtrl_SendCommand
	jr DpPdTtl_ReturnZero

; DpPdTtl case G
DpPd_CaseG:
	cp xde, 0x84
	jr z, DpPd_CaseH
	cp xde, 0x4
	jr nz, DpPdTtl_ReturnZero

; DpPdTtl case H
DpPd_CaseH:
	calr CDlikeSwTtl_PdConfirmStart
	jr DpPdTtl_ReturnZero

; DpPdTtl case I
DpPd_CaseI:
	cp xde, 0x84
	jr z, DpPd_CaseJ
	cp xde, 0x4
	jr nz, DpPdTtl_ReturnZero

; DpPdTtl case J
DpPd_CaseJ:
	calr CDlikeSwTtl_SongConfirmDispatch

DpPdTtl_ReturnZero:
	lds32 xhl, 0
	ret

DpSmfTtlFunc:
	cp xbc, 0x1c00009
	jrl z, DpSmf_CaseI
	cp xbc, 0x1c00008
	jrl z, DpSmf_CaseG
	cp xbc, 0x1c00007
	jrl z, DpSmf_CaseA
	cp xbc, 0x1c00013
	jrl nz, DpSmfTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpSmfTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpSmfTtl_ReturnZero
	add xde, xde
	add xde, 0xe20190
	ld de, (xde)
	lda_24 xix, DpSmfTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpSmfTtlFunc title dispatch
DpSmfTtl_Dispatch:
	cpdi8	0x8d37, 114
	jrl	z, 255
	sti8_24	0x021088, 0
	sti16_24	0x021086, 0
	calr	62057
	calr	61829
	calr	63632
	jrl	230
	cpdi8	0x8d36, 114
	jrl	z, 222
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, 23
	calr	2769
	call	Song_AbortPlayback
	ld	xwa, 0x6f0026
	ld	xbc, 0x01c70009
	lds32	xde, 0
	call	ApPostEvent
	calr	61264
	jrl	184

; DpSmfTtl case A
DpSmf_CaseA:
	ld xwa, xde
	cp xde, 0x5
	jr z, DpSmf_CaseE
	cp xde, 0x3
	jr z, DpSmf_CaseD
	cp xde, 0x2
	jr z, DpSmf_CaseC
	cp xde, 0x1
	jr z, DpSmf_CaseB
	sub xwa, 0x81
	cp xwa, 0x0
	jrl c, DpSmfTtl_ReturnZero
	cp xwa, 0x9
	jr ugt, DpSmfTtl_ReturnZero
	add xwa, xwa
	add xwa, 0xe2017c
	ld wa, (xwa)
	lda_24 xix, DpSmf_CaseB
	jp_dri 8, 0x07, 0xf0, 0xe0

; DpSmfTtl case B
DpSmf_CaseB:
	ldw wa, 0xffff
	jr DpSmf_NavigateBackward

; DpSmfTtl case C
DpSmf_CaseC:
	call SeqState_GetFlags
	bit 1, hl
	jr z, DpSmf_CheckBit0PlayMode
	calr SeqRecPlay_EnableRecordOnly
	call Acc_StopPlayMode
	jr DpSmfTtl_ReturnZero

DpSmf_CheckBit0PlayMode:
	call SeqState_GetFlags
	bit 0, hl
	jr z, DpSmfTtl_ReturnZero
	calr SeqRecPlay_EnablePlayOnly
	call Acc_TransitionPlayMode
	jr DpSmfTtl_ReturnZero

; DpSmfTtl case D
DpSmf_CaseD:
	calr CDlikeSwTtl_SongBit1Check
	jr DpSmfTtl_ReturnZero

; DpSmfTtl case E
DpSmf_CaseE:
	lds wa, 1

DpSmf_NavigateBackward:
	calr CDlikeSwTtl_SongNavDispatch
	jr DpSmfTtl_ReturnZero
	ldw wa, 0xa5
	jr DpSmf_CaseF
	ldw wa, 0xd6

; DpSmfTtl case F
DpSmf_CaseF:
	call SoundCtrl_SendCommand
	jr DpSmfTtl_ReturnZero

; DpSmfTtl case G
DpSmf_CaseG:
	cp xde, 0x84
	jr z, DpSmf_CaseH
	cp xde, 0x4
	jr nz, DpSmfTtl_ReturnZero

; DpSmfTtl case H
DpSmf_CaseH:
	calr CDlikeSwTtl_SongConfirmStart
	jr DpSmfTtl_ReturnZero

; DpSmfTtl case I
DpSmf_CaseI:
	cp xde, 0x84
	jr z, DpSmf_CaseJ
	cp xde, 0x4
	jr nz, DpSmfTtl_ReturnZero

; DpSmfTtl case J
DpSmf_CaseJ:
	calr CDlikeSwTtl_SongConfirmDispatch

DpSmfTtl_ReturnZero:
	lds32 xhl, 0
	ret

DpSmfLyrTtlFunc:
	cp xbc, 0x1c00009
	jrl z, DpSmfLyr_CaseC
	cp xbc, 0x1c00008
	jrl z, DpSmfLyr_CaseB
	cp xbc, 0x1c00007
	jr z, DpSmfLyr_CaseA
	cp xbc, 0x1c00013
	jrl nz, SeqStep_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, SeqStep_ReturnZero
	cp xde, 0x5
	jrl ugt, SeqStep_ReturnZero
	add xde, xde
	add xde, 0xe2019c
	ld de, (xde)
	lda_24 xix, DpSmfLyrTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
; DpSmfLyrTtlFunc title dispatch
DpSmfLyrTtl_Dispatch:
	ld	xwa, 0x6f0026
	ld	xbc, 0x01c7000a
	lds32	xde, 0
	jr	18
	calr	60982
	jrl	193
	ld	xwa, 0x6f0026
	ld	xbc, 0x01c7000a
	lds32	xde, 0
	call	ApPostEvent
	jrl	174

; DpSmfLyrTtl case A
DpSmfLyr_CaseA:
	cp xde, 0x88
	jr z, DpSmfLyr_SendSoundD6
	cp xde, 0x85
	jr z, DpSmfLyr_NavigateForward
	cp xde, 0x5
	jr z, DpSmfLyr_NavigateForward
	cp xde, 0x83
	jr z, DpSmfLyr_CheckSongBit1
	cp xde, 0x3
	jr z, DpSmfLyr_CheckSongBit1
	cp xde, 0x82
	jr z, SeqRecPlay_ToggleRecordOrPlay
	cp xde, 0x2
	jr z, SeqRecPlay_ToggleRecordOrPlay
	cp xde, 0x81
	jr z, DpSmfLyr_NavigateBackward
	cp xde, 0x1
	jr nz, SeqStep_ReturnZero

DpSmfLyr_NavigateBackward:
	ldw wa, 0xffff
	jr DpSmfLyr_DispatchNavigation

SeqRecPlay_ToggleRecordOrPlay:
	call SeqState_GetFlags
	bit 1, hl
	jr z, DpSmfLyr_CheckBit0PlayMode
	calr SeqRecPlay_EnableRecordOnly
	call Acc_StopPlayMode
	jr SeqStep_ReturnZero

DpSmfLyr_CheckBit0PlayMode:
	call SeqState_GetFlags
	bit 0, hl
	jr z, SeqStep_ReturnZero
	calr SeqRecPlay_EnablePlayOnly
	call Acc_TransitionPlayMode
	jr SeqStep_ReturnZero

DpSmfLyr_CheckSongBit1:
	calr CDlikeSwTtl_SongBit1Check
	jr SeqStep_ReturnZero

DpSmfLyr_NavigateForward:
	lds wa, 1

DpSmfLyr_DispatchNavigation:
	calr CDlikeSwTtl_SongNavDispatch
	jr SeqStep_ReturnZero

DpSmfLyr_SendSoundD6:
	ldw wa, 0xd6
	call SoundCtrl_SendCommand
	jr SeqStep_ReturnZero

; DpSmfLyrTtl case B
DpSmfLyr_CaseB:
	cp xde, 0x84
	jr z, DpSmfLyr_ConfirmStart
	cp xde, 0x4
	jr nz, SeqStep_ReturnZero

DpSmfLyr_ConfirmStart:
	calr CDlikeSwTtl_SongConfirmStart
	jr SeqStep_ReturnZero

; DpSmfLyrTtl case C
DpSmfLyr_CaseC:
	cp xde, 0x84
	jr z, DpSmfLyr_ConfirmDispatch
	cp xde, 0x4
	jr nz, SeqStep_ReturnZero

DpSmfLyr_ConfirmDispatch:
	calr CDlikeSwTtl_SongConfirmDispatch

SeqStep_ReturnZero:
	lds32 xhl, 0
	ret

SeqStepModeFunc:
	cp xbc, 0x1c00013
	jr nz, SeqStepMode_ReturnZero
	cp xde, 0x1
	jr z, DpSmfLyr_CaseD
	or xde, xde
	jr nz, SeqStepMode_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call ChannelFilter_InitAndApply
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SeqStepMode_ReturnZero

; DpSmfLyrTtl case D
DpSmfLyr_CaseD:
	push xde
	push xhl
	push xix
	push xiz
	call Display_LoadAndSetIndicator
	pop xiz
	pop xix
	pop xhl
	pop xde

SeqStepMode_ReturnZero:
	lds32 xhl, 0
	ret

SqTrSelTtlFunc:
	cp xbc, 0x1c00013
	jr nz, SqTrSelTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrSelTtl_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrSelTtl_ReturnZero
	add xde, xde
	add xde, 0xe201a8
	ld de, (xde)
	lda_24 xix, SqTrSelTtl_Dispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
SqTrSelTtl_Dispatch:	.ascii ":;<>"
	call	PlayMode_SetupAndDispatch
	.ascii "^\\[Zh"
	incf
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PlayMode_TeardownAndRestore
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde

SqTrSelTtl_ReturnZero:
	lds32 xhl, 0
	ret

Display_InitGraphicsAndScreen:
	; --- Init sequence + 4 register-save call thunks ---
	ldw wa, 0x00ff
	call GraphicsRender_ByteData
	ldw wa, 0x00f5
	call 0xfb144a
	call 0xfb14b7
	ldw wa, 0x00ff
	call 0xfb1456
Display_CallInitScreenLayout:
	push xde
	push xhl
	push xix
	push xiz
	call Display_InitScreenLayout
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
Display_CallConditionalCompare:
	push xde
	push xhl
	push xix
	push xiz
	call Display_ConditionalCompare
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
Display_CallPollAudioUpdate:
	push xde
	push xhl
	push xix
	push xiz
	call Display_PollAudioAndUpdate
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret
; SqTrSelTtl case A
SqTrSel_CaseA:
	push xde
	push xhl
	push xix
	push xiz
	call Display_NullHandler
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret


SqStepTtlFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, 0xe201b4
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret


; --- Demo Routines ---
