UIStateEvt_VoiceParamHandler:
	ld	a, (35994:16)
	cp	a, 142
	jr	z, 19
	cp	a, 100
	jr	z, 14
	cp	a, 108
	jr	lt, 17
	cp	a, 122
	jr	le, 4
	jp	15860454
	ld	(4330:16), 0
	jrl	164
	ld	a, (49121:16)
	cps	a, 3
	.byte 0xf2, 0x8a, 0x03, 0xf2, 0xde
	ld	a, (49122:16)
	ld	w, (49123:16)
	cp	w, 255
	jr	nz, 8
	.byte 0xc1, 0xea, 0x10, 0x3c, 0xfe
	jrl	132
	bit	2, w
	jr	nz, 2
	jr	125
	.byte 0xf1, 0xea, 0x10, 0xc8
	jr	z, 7
	.byte 0xc1, 0xea, 0x10, 0x3c, 0xfe
	jr	112
	and	a, w
	and	a, 4
	bit	2, a
	jr	z, 53
	pushw	wa
	xor	a, a
	call	15997254
	popw	wa
	call	15860721
	call	15860619
	call	16094901
	call	15672365
	ld	(1073:16), 0
	.byte 0xc1, 0xb3, 0x28, 0x3e, 0x10
	ldw	(61854:16), 0
	.byte 0xc1, 0xa5, 0x28, 0x3c, 0xfe
	ldb	a, 76
	call	16544114
	jr	49
	pushw	wa
	xor	a, a
	call	15997156
	popw	wa
	call	15860721
	call	15860619
	call	16094901
	call	15672365
	ld	(1073:16), 0
	.byte 0xc1, 0xb3, 0x28, 0x3e, 0x10
	ldw	(61854:16), 0
	ld	(4596:16), 0
	call	15976648
	ret
	ld	xix, 61856
	xor	bc, bc
	ldb	c, 16
	ldb	a, 16
	cp_spib	a, 240
	jr	z, 5
	djnz16	bc, -8
	jr	68
	xor	wa, wa
	ldb	a, 16
	sub	wa, bc
	ld	c, a
	ld	b, a
	ld	iz, (61854:16)
	ld	a, c
	scf
	.byte 0xde, 0x2a
	ld	a, b
	jr	c, 45
	pushw	wa
	ld	xhl, 62032
	ldb	c, 3
	mul8rr	a, c
	ld	iy, wa
	.byte 0xf3, 0x07, 0xec, 0xf4, 0xcf
	jr	z, 3
	popw	wa
	jr	3
	popw	wa
	jr	20
	inc	1, a
	ld	w, a
	ld	(3414:16), w
	.byte 0xc1, 0x54, 0x0d, 0x3e, 0x01, 0xc1, 0x7b, 0x28, 0x3e, 0x04
	jr	12
	.byte 0xc1, 0x54, 0x0d, 0x3c, 0xfe, 0xc1, 0x7b, 0x28, 0x3c, 0xfb
	xor	w, w
	ret
SeqPlay_RestoreVoiceState_Return:
	ld a, (0x2878:16)
	pushw wa
	ld a, (0x00ffe3:24)
	ld (0x2878:16), a
	call SeqVoice_InitEntry
	popw wa
	ld (0x2878:16), a
	ret

SeqTimer_PostTempoUpdate:
	ld	xhl, 62560
	ld	xwa, 730
	add	xhl, xwa
	ld	wa, (xhl+8)
	pushw	wa
	ldb	e, 72
	ldb	d, 8
	ldb	w, 255
	call	16624672
	popw	wa
	ld	(64610:16), wa
	call	16554829
	ret
PlayMode_NullRet:
	ret
PlayMode_SetupAndDispatch:
	; --- Setup: load/store/call/set flag ---
	ld	wa, (0xf19e:16)
	ld	(0x2875:16), wa
	ld	(3424:16), 0
	call AccWrap_PlayModeDispatch
	or	(0x28a7:16), 4
	ret
PlayMode_TeardownAndRestore:
	; --- Teardown: load/store/clear flags ---
	ld	wa, (0x2875:16)
	ld	(0xf19e:16), wa
	and	(0x28a7:16), 251
	or	(0x28b3:16), 16
	and	(0x28a7:16), 247
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
	ld	(3423:16), a
	inc 1, e
	ld	(3424:16), e
	ret
Part_ValidateAndActivate:
	; --- Validation: check range, optionally call ---
	ldw	(0x287f:16), 1
	ldw	(3383:16), 0
	cp	(3424:16), 0
	jr z, PartValidate_Done
	cp	(3424:16), 16
	jr ugt, PartValidate_Done
	ldw	(4360:16), 0
	xor	wa, wa
	ldb a, 0x8a
	call UI_PostModeChangeEvent
PartValidate_Done:
	ret
PlaybackDispatch_NullRet:
	ret


PlaybackMode_DispatchByType:
	bit 0, (0x0d35:16)
	jrl z, DispatchHandler_ClearActiveFlag
	cp (0x8c9a:16), 0x7a
	jr z, PlaybackDisp_Type122_Play
	cp (0x8c9a:16), 0x78
	jr z, PlaybackDisp_Type120_Play
	cp (0x8c9a:16), 0x73
	jr z, PlaybackDisp_Type115_Stop
	cp (0x8c9a:16), 0x76
	jr z, PlaybackDisp_Type118_Stop
	cp (0x8c9a:16), 0x74
	jr z, PlaybackDisp_Type116_Song
	cp (0x8c9a:16), 0x75
	jrl z, PlaybackDisp_Type117_PartFmt
	cp (0x8c9a:16), 0x6f
	jr z, PlaybackDisp_Type111_CDSong
	cp (0x8c9a:16), 0x72
	jr z, PlaybackDisp_Type114_CDSong
	cp (0x8c9a:16), 0x70
	jr z, PlaybackDisp_Type112_CDDoc
	cp (0x8c9a:16), 0x71
	jrl z, PlaybackDisp_Type113_CDPd
	cp (0x8c9a:16), 0x79
	jr z, Part_ValidateCallAndClear
	cp (0x8c9a:16), 0x77
	jr z, Part_ValidateCallAndClear
	cp (0x8c9a:16), 0x6c
	jr z, Part_ValidateCallAndClear
	cp (0x8c9a:16), 0x6d
	jr z, Part_ValidateCallAndClear
	cp (0x8c9a:16), 0x6e
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
	and (3381:16), 254
	ret

PlayMode_InitFlagBlock:
	call	PlayMode_InitFlagBlock_0x5
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	ld	(3380:16), 1
	call	PlayMode_InitFlagBlock_0x16
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	max
	ld	(4420:16), 10
	ret

SongBank_ScanActiveVoices:
	xor bc, bc
	ld l, a
	extz hl
	mul hl, 0x800
	add xhl, 0xab0d0
	ld xiy, xhl
	ldb b, 0x10
	cpiw_sri 0xf5, 0x4e, 0xff, 0x00, 0x00
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
	ld	(3380:16), 0
	ret

PlayMode_CheckAndDispatch:
	cp (3380:16), 1
	jr nz, PlayMode_SendModeCommand
	ld (3380:16), 0
	ld (4420:16), 0
	call PlayMode_DispatchAndClearBit2
	bit 2, (3394:16)
	jr z, PlayMode_SendModeCommand
	jr PlayMode_SendModeCommand

PlayMode_SendModeCommand:
	ld	(4437:16), 0
	cp	(35994:16), 122
	jr	z, 7
	cp	(35994:16), 120
	jr	z, 10
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
	and (0x28ac:16), 251
	ret

PlayMode_StartAndSendCommand:
	cp (0x0d34:16), 0x01
	jr nz, SongMode_PostEvtRetZero
	cp (0x1144:16), 0x00
	jr nz, SongMode_PostEvtRetZero
	call PlayMode_DispatchAndClearBit2
	ld (0x1155:16), 0x01
	cp (0x8c9a:16), 0x7a
	jr z, PlayStart_PostMode79
	cp (0x8c9a:16), 0x78
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
	bit 2, (0x28ac:16)
	jr z, SeqRestart_Return
	ld iz, wa
	ld a, (0xfc5f:16)
	and a, 0x30
	ld wa, iz
	jr nz, SeqRestart_Return
	call AccWrap_PlayModeDispatch
	ldw bc, 0xf000

SeqRestart_WaitBit2Loop:
	bit 2, (1056:16)
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
	bit 2, (0x28ac:16)
	jr z, SeqNotify_Return
	ld (0x1155:16), 0x01
	cp (0x8c9a:16), 0x7a
	jr z, SeqNotify_PostMode79
	cp (0x8c9a:16), 0x78
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
	ld l, (4437:16)
	ret

SongMode_InitFlagBlock:
	ret
	ret
	call	SongMode_InitFlagBlock_0x7
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	ld	(3380:16), 1
	call	SongMode_InitFlagBlock_0x18
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	max
	ld	(4420:16), 10
	ret
	ld	(3380:16), 0
	ret

SongMode_CheckAndDispatch:
	cp (3380:16), 1
	jr nz, SongMode_SendStopCommand
	ld (3380:16), 0
	ld (4420:16), 0
	call SongMode_AbortAndClearBit2
	bit 2, (3394:16)
	jr z, SongMode_SendStopCommand
	jr SongMode_SendStopCommand

SongMode_SendStopCommand:
	ld (4437:16), 0
	xor wa, wa
	ldb a, 0x6d
	call UI_PostModeChangeEvent
	ret

SongMode_AbortAndClearBit2:
	and (0x28ac:16), 251

	call	16693581

	ret



SongMode_StartPlayback:
	cp (3380:16), 1
	jrl nz, SongMode_StartReturn
	cp (4420:16), 0
	jrl nz, SongMode_StartReturn
	call SongMode_AbortAndClearBit2
	ld (4437:16), 1
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
	ld (4437:16), 2
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus3:
	ld (4437:16), 3
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus4:
	ld (4437:16), 4
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus1AndDispatch:
	ld (0x1155:16), 0x01
	cp (0x8c9a:16), 0x74
	jr z, PartFormat_PostMode6D
	cp (0x8c9a:16), 0x70
	jrl z, VoiceState_SqTrSelCaseD
	cp (0x8c9a:16), 0x75
	jr z, PartFormat_PostMode6E
	cp (0x8c9a:16), 0x71
	jrl z, VoiceState_SqTrSelCaseF
	cp (0x8c9a:16), 0x73
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8c9a:16), 0x6f
	jr z, VoiceState_SqTrSelCaseE
	cp (0x8c9a:16), 0x76
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8c9a:16), 0x72
	jr z, VoiceState_SqTrSelCaseE
	jp PartFormat_NullRet
PartFormat_PartTypeDisp:
	cp (0x8c9a:16), 0x74
	jr z, PartFormat_PostMode6D
	cp (0x8c9a:16), 0x70
	jr z, PartFormat_PostMode6D
	cp (0x8c9a:16), 0x75
	jr z, PartFormat_PostMode6E
	cp (0x8c9a:16), 0x71
	jr z, PartFormat_PostMode6E
	cp (0x8c9a:16), 0x73
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8c9a:16), 0x6f
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8c9a:16), 0x76
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8c9a:16), 0x72
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
	call	PartFormat_InitFlagBlock_0xA
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	ld	(3380:16), 1
	call	PartFormat_InitFlagBlock_0x1B
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	max
	ld	(4420:16), 10
	ret
	ld	(3380:16), 0
	ret

PartFormat_CheckAndDispatch:
	cp (3380:16), 1
	jr nz, PartFormat_SendStopCommand
	ld (3380:16), 0
	ld (4420:16), 0
	call PartFormat_AbortAndClearBit2
	bit 2, (3394:16)
	jr z, PartFormat_SendStopCommand
	jr PartFormat_SendStopCommand

PartFormat_SendStopCommand:
	ld (4437:16), 0
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent
	ret

PartFormat_AbortAndClearBit2:
	and (0x28ac:16), 251

	call 16693581

	ret



PartFormat_StartPlayback:
	cp (3380:16), 1
	jrl nz, PartFormat_StartReturn
	cp (4420:16), 0
	jrl nz, PartFormat_StartReturn
	call PartFormat_AbortAndClearBit2
	ld (4437:16), 1
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
	cp (0x8c9b:16), 0x76
	jr z, .Lc_f2093f
	call PlayModeStop_InitFlagBlock_0x10
.Lc_f2093f:
	ret
	.byte 0xc1, 0x34, 0x0d, 0x3f, 0x00, 0x6e, 0x09, 0xf1
	.byte 0x34, 0x0d, 0x00, 0x01, 0x1d, 0x51, 0x09, 0xf2
	.byte 0x0e, 0xc1, 0xac, 0x28, 0x3e, 0x04, 0xf1, 0x44
	.byte 0x11, 0x00, 0x0a, 0x0e, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x6c, 0x6e, 0x05, 0xf1, 0x34, 0x0d, 0x00, 0x00
	.byte 0x0e
PlayMode_StopAbortRetZero:
	cp (3380:16), 1
	jr nz, PlayModeStop_SendStopCmd
	ld (3380:16), 0
	ld (4420:16), 0
	call PlayMode_StopAndAbort
	bit 2, (3394:16)
	jr z, PlayModeStop_SendStopCmd
	jr PlayModeStop_SendStopCmd

PlayModeStop_SendStopCmd:
	ld (4437:16), 0
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent
	ret

PlayMode_StopAndAbort:
	and (0x28ac:16), 251

	.byte 0x1d, 0xfd, 0x2a, 0xf2	; call PlayMode_SendStopEvent (v7 addr)

	.byte 0x1d, 0x4d, 0xb9, 0xfe	; call Song_AbortPlayback (v7 addr)

	ret



PlayMode_SendCommand6C:
	cp (3380:16), 1
	jrl nz, PlayModeStop_SendReturn
	cp (4420:16), 0
	jrl nz, PlayModeStop_SendReturn
	call PlayMode_StopAndAbort
	ld (4437:16), 1
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
	cp (0x8c9a:16), 0x6c
	jr nz, .Lc_f209d5
	ld (0x0d34:16), 0x00
.Lc_f209d5:
	ret
SqSngNameTtl_Dispatch:
	xor wa, wa
	ldb a, 0x73
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	ret

CDlikeSwitch_PlaybackTimer:
	ld w, (0x1144:16)
	cps w, 0
	jr z, CDlikeTimer_Return
	dec 1,W
	cps w, 5
	jr nz, CDlikeTimer_CheckZeroCount
	cp (0x8c9a:16), 0x7a
	jr z, CDlikeTimer_ResetAccompaniment
	cp (0x8c9a:16), 0x78
	jr z, CDlikeTimer_ResetAccompaniment
	jr t, CDlikeSwTtl_StorePlaybackMode
CDlikeTimer_ResetAccompaniment:
	pushw wa
	and (0x28b2:16), 249
	and (0x28a7:16), 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode
CDlikeTimer_CheckZeroCount:
	cps	w, 0
	jr	nz, 74
	cp	(35994:16), 122
	jr	z, 61
	cp	(35994:16), 120
	jr	z, 54
	cp	(35994:16), 116
	jr	z, 39
	cp	(35994:16), 117
	jr	z, 16
	cp	(35994:16), 115
	jr	z, 17
	cp	(35994:16), 118
	jr	z, 10
	jr	30
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
	ld (4420:16), w

CDlikeTimer_Return:
	ret

CDlike_ResetPlaybackState:
	ei 6
	xor wa, wa
	ld (1052:16), wa
	ld (1051:16), a
	ld (1048:16), wa
	ld (1047:16), a
	bit 1, (0x28a7:16)
	jr z, CDlikeReset_SetTimerFlags
	ld (1054:16), 1
	ld (1045:16), 0
	ld (1046:16), 0
	ld (1076:16), 0
	ld (1077:16), 0

CDlikeReset_SetTimerFlags:
	ld (1057:16), 1
	ld (1056:16), 1
	ei 0
	ret

CDlike_InitModeAndLoadBank:
	or (0xb746:16), 0x40
	ld a, (0xfdad:16)
	ld (0x0d42:16), a
	ld (0x0d34:16), 0x00
	ld (0x1144:16), 0x00
	call CDlike_LoadSongBankData
	cp (0x8c9a:16), 0x77
	jr z, CDlikeSw_NullRet
	cp (0x8c9a:16), 0x78
	jr z, CDlikeSw_NullRet
	cp (0x8c9a:16), 0x79
	jr z, CDlikeSw_NullRet
	cp (0x8c9a:16), 0x7a
	jr z, CDlikeSw_NullRet
	call SqTrAs_InitWall
	ld wa, (0xf19e:16)
	ld (0x2875:16), wa
	ldw (0xf19e:16), 0x0000
	ldw (0x2314:16), 0x0000
	ld XIY,0x0000f9a0
	ld XIX,0x0003cf04
	ldw BC, 0x0310
	ldirw
CDlikeSw_NullRet:
	ret

CDlike_LoadSongBankData:
	ld (6882:16), 0
	cpdi16 0xf19e, 0
	jr nz, CDlikeBankLoad_CheckSavedState
	ld (6882:16), 1

CDlikeBankLoad_CheckSavedState:
	ld wa, (0x00ffec:24)
	ld (0xf19e:16), wa
	ld xiy, 0xf180
	ld xix, 0xab000
	xor xwa, xwa
	ld a, (0x00ffe3:24)
	sla xwa, 11
	add xix, xwa
	ldw bc, 0x800
	ldir85
	cp (6882:16), 1
	jr nz, CDlikeBankLoad_Return
	ldw (0xf19e:16), 0

CDlikeBankLoad_Return:
	ret

CDlike_ExitModeAndRestore:
	call PlayMode_CheckAndAbort
	and (0xb746:16), 0xbf
	and (0x28ac:16), 0xfb
	ld (0x1144:16), 0x00
	bit 2, (0x0d42:16)
	jr z, .Lc_f20b61
	jr t, .Lc_f20b61
CDlikeExit_CheckPlaybackType:
.Lc_f20b61:
	cp (0x8c9b:16), 0x77
	jr z, PlayMode_ResetAndSchedule
	cp (0x8c9b:16), 0x78
	jr z, PlayMode_ResetAndSchedule
	cp (0x8c9b:16), 0x79
	jr z, PlayMode_ResetAndSchedule
	cp (0x8c9b:16), 0x7a
	jr z, PlayMode_ResetAndSchedule
	ld (0x10ea:16), 0x01
	call ToneGen_FileIO_RestoreFromBackup
	call SeqTimer_UpdateTempoReg
	call 0xfd84c2
	call SqTrAs_Setup
	ld wa, (0x2875:16)
	ld (0xf19e:16), wa
PlayMode_ResetAndSchedule:
	ld	(3380:16), 0
	call	16635550
	ret
SongBank_SwitchAndUpdateTempo:
	stb_da (0x00ffe3), a
	call SongBank_SaveAndReload
	call SeqTimer_PostTempoUpdate
	ret

SongBank_SaveAndReload:
	ld wa, (0xf22f:16)
	ld (0x286f:16), wa
	ld wa, (0xf231:16)
	ld (0x2871:16), wa
	call SongBank_LoadToWorkArea
	call SongBank_CheckAccompanimentMode
	and (0x28b1:16), 254
	ret

SongBank_LoadToWorkArea:
	xor xwa, xwa
	ld a, (0x00ffe3:24)
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ld wa, (0xf19e:16)
	ld (0x00ffec:24), wa
	ld wa, (0x286f:16)
	ld (0xf22f:16), wa
	ld wa, (0x2871:16)
	ld (0xf231:16), wa
	ret

SongBank_CheckAccompanimentMode:
	cp (0xf23d:16), 255
	jr z, SongBank_EnableAccompaniment
	bit 2, (0xfdad:16)
	jr z, SongBank_CheckBassMode
	and (0xfdad:16), 251
	xor a, a
	jr SongBank_SendAccompEvent

SongBank_EnableAccompaniment:
	bit 2, (0xfdad:16)
	jr nz, SongBank_CheckBassMode
	or (0xfdad:16), 4
	ldb a, 0x4

SongBank_SendAccompEvent:
	ld	(4330:16), 1
	ldb	e, 145
	ldb	d, 3
	ldb	w, 4
	call	16624640
	call	15668398
SongBank_CheckBassMode:
	cp (0xf24b:16), 255
	jr z, SongBank_EnableBassMode
	and (0xfdad:16), 254
	xor a, a
	jr SongBank_SendBassEvent

SongBank_EnableBassMode:
	or (0xfdad:16), 1
	ldb a, 0x1

SongBank_SendBassEvent:
	ldb	e, 145
	ldb	d, 3
	ldb	w, 1
	call	16624640
	call	15668398
	ld	(4596:16), 1
	call	16625070
	call	16635550
	ret
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
	add xde, SepaOut_Config_0_0x14
	ld de, (xde)
	lda xix, (SqTrAs_CondCheck:24)
	jp_ind 8, 0x07, 0xf0, 0xe8

; SqTrAs conditional voice check
SqTrAs_CondCheck:
	.ascii ":;<>"
	call	SetWall_InlineCodeBlock3_0x1
	.ascii "^\\[Zh"
	incf
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SetWall_InlineCodeBlock3_0x40
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
	add xde, SepaOut_Config_0_0x20
	ld de, (xde)
	lda xix, (SQTR_DISPATCH_TABLE_1:24)
	jp_ind 8, 0x07, 0xf0, 0xe8

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
	add xde, SepaOut_Config_0_0x2C
	ld de, (xde)
	lda xix, (SQTR_DISPATCH_TABLE_2:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; Sequencer track dispatch table 2 - SqTrAsTtlFunc handler
; 6 dispatch cases (XDE 0-5)
SQTR_DISPATCH_TABLE_2:
	.byte 0x40, 0x04, 0x00, 0x8b, 0x00, 0x41, 0x8e, 0x00
	.byte 0xe0, 0x01, 0x42, 0x02, 0x00, 0xff, 0xff, 0x1d
	.byte 0x4b, 0x99, 0xfa, 0x3a, 0x3b, 0x3c, 0x3e, 0x1d
	.byte 0xe7, 0xed, 0xf1, 0x5e, 0x5c, 0x5b, 0x5a, 0xf1
	.byte 0xc0, 0x8e, 0xb8, 0x30, 0x60, 0x00, 0x1d, 0x72
	.byte 0x71, 0xfc, 0xf2, 0x82, 0x10, 0x02, 0x14, 0x73
	.byte 0x28, 0x68, 0x70
SQTR_DISPATCH_TABLE_2_CASE1:
	.byte 0x3a, 0x3b, 0x3c, 0x3e, 0x1d, 0x11, 0xee, 0xf1
	.byte 0x5e, 0x5c, 0x5b, 0x5a, 0xf1, 0xc0, 0x8e, 0xb0
	.byte 0x30, 0x60, 0x00, 0x1d, 0x72, 0x71, 0xfc, 0x68
	.byte 0x57
SQTR_DISPATCH_TABLE_2_CASE2:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x8b, 0x6e, 0x50, 0xc1
	.byte 0xa6, 0x7e, 0x3f, 0x23, 0xd9, 0x76, 0xc1, 0x9d
	.byte 0x8c, 0x3f, 0xee, 0xd8, 0x76, 0xd9, 0xc0, 0x66
	.byte 0x15, 0x40, 0x04, 0x00, 0x8b, 0x00, 0x41, 0x8e
	.byte 0x00, 0xe0, 0x01, 0x42, 0x02, 0x00, 0xff, 0xff
	.byte 0x1d, 0x4b, 0x99, 0xfa, 0x68, 0x29
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
	add xde, SepaOut_Config_0_0x38
	ld de, (xde)
	lda xix, (SqTrAsPsTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	call	SetWall_DataBlock1_0xF
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
SqTrAsPsTtl_CaseF:
	ld	a, (35994:16)
	extz	wa
	sub	wa, 108
	cps	wa, 0
	jr	lt, 41
	cp	wa, 13
	jr	gt, 35
	lda	xix, (14811178:24)
	ld_rrw	wa, xix, wa
	extz	wa
	sll	wa, 1
	ld	xix, 14811192
	ld_rrw	wa, xix, wa
	lda	xix, (15863650:24)
	jp_rr 8, xix, wa
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15862598
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
	add xde, SepaOut_Config_0_0x56
	ld de, (xde)
	lda xix, (SqMdlyPlyTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	add xde, SepaOut_Config_0_0x62
	ld de, (xde)
	lda xix, (DkMdlyPlyTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	lda xde, (SepaOut_Config_0_0x6E:24)

DkMdlyPly_VoiceScanLoop:
	ld bc, hl
	add bc, bc
	ldw_sri BC, 0x07, 0xe8, 0xe4
	and bc, wa
	ret nz
	inc 1, hl
	cp hl, 0x10
	jr lt, DkMdlyPly_VoiceScanLoop
	ret

; DkMdlyPly check playback state
DkMdlyPly_CheckState:
	dec	2, xsp
	push	xiz
	ld	(xsp+4), wa
	ld	a, (35994:16)
	cp	a, 111
	jr	z, 15
	cp	a, 114
	jr	z, 10
	cp	a, 115
	jr	z, 5
	cp	a, 118
	jr	nz, 89
Snd_ParamLookupSetupWerp:
	ldiw_erp 0xfa, 0

; DkMdlyPly handle result
DkMdlyPly_HandleResult:
	ld	wa, qiz
	add	wa, wa
	lda	xbc, (14811252:24)
	ld_rrw	wa, xbc, wa
	ldw	bc, 1025
	call	16567590
	ld	iz, hl
	ld	wa, (xsp+4)
	calr	65444
	cp	hl, iz
	jr	nz, 42	; -> 0xF21121
	ld	wa, qiz
	add	wa, wa
	lda	xbc, (14811252:24)
	ld_rrw	wa, xbc, wa
	ld	(35998:16), a
	ld	e, a
	extz	de
	pushw	255
	ldw	wa, 144
	ldw	bc, 16
	call	16624211
	call	16635862
	jr	10	; -> 0xF2112B
DkMdlyPly_ExtendedCheck:
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x20, 0x00
	jr lt, DkMdlyPly_HandleResult

; DkMdlyPly finalize
DkMdlyPly_Finalize:
	pop xiz
	inc 2, xsp
	ret

DisplayMode_DispatchEvents:
	ld a, (0x8c9a:16)
	extz WA
	sub WA,0x006f
	cps wa, 0
	ret LT
	.byte 0xd8, 0xde, 0xb0, 0xfa, 0xd8, 0x80, 0xf2, 0xb4
	.byte 0x00, 0xe2, 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20
	.byte 0xf2, 0x57, 0x11, 0xf2, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xe0, 0xd8
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
	ld	wa, (135302:24)
	calr	65180
	ld	wa, (135302:24)
	jp	16693595
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
	add xde, SepaOut_Config_0_0xDC
	ld de, (xde)
	lda xix, (DpMdlyDocTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlyDocTtlFunc title dispatch
DpMdlyDocTtl_Dispatch:
	ldw	(0x021086:24), 0
	calr	65452
	calr	65224
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SongMode_InitFlagBlock_0x2
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	call	SongMode_InitFlagBlock_0x23
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
	add xde, SepaOut_Config_0_0xE8
	ld de, (xde)
	lda xix, (DpMdlyPdTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlyPdTtlFunc title dispatch
DpMdlyPdTtl_Dispatch:
	ldw	(0x021086:24), 0
	calr	65276
	calr	65048
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PartFormat_InitFlagBlock_0x5
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	call	PartFormat_InitFlagBlock_0x26
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
	add xde, SepaOut_Config_0_0xF4
	ld de, (xde)
	lda xix, (DpMdlySmfTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlySmfTtlFunc title dispatch
DpMdlySmfTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0x76, 0x66, 0x13, 0xf2
	.byte 0x88, 0x10, 0x02, 0x00, 0x00, 0xf2, 0x86, 0x10
	.byte 0x02, 0x02, 0x00, 0x00, 0x1e, 0x3f, 0xfe, 0x1e
	.byte 0x5b, 0xfd, 0x3a, 0x3b, 0x3c, 0x3e, 0x1d, 0x34
	.byte 0x09, 0xf2, 0x5e, 0x5c, 0x5b, 0x5a, 0x68, 0x59
	.byte 0x3a, 0x3b, 0x3c, 0x3e, 0x1d, 0x5c, 0x09, 0xf2
	.byte 0x5e, 0x5c, 0x5b, 0x5a, 0x1e, 0x3a, 0xfb, 0x68
	.byte 0x48
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
	add xde, SepaOut_Config_0_0x100
	ld de, (xde)
	lda xix, (DpMdlySmfLyrTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlySmfLyrTtlFunc title dispatch
DpMdlySmfLyrTtl_Dispatch:
	ld	a, (35995:16)
	cp	a, 108
	jr	nz, 38
	cp	a, 118
	jr	z, 19
	ld	(135304:24), 0
	ldw	(135302:24), 0
	calr	64890
	calr	64662
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15862068
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	12
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15862216
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 7274534
	ld	xbc, 29818890
	lds32	xde, 0
	jr	29
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15862217
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	64091
	jr	77
	ld	xwa, 7274534
	ld	xbc, 29818890
	lds32	xde, 0
	call	16423243
	jr	59
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
	add xbc, SepaOut_Config_0_0x13A
	ld bc, (xbc)
	lda xix, (NameGetFuncCall_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe4
; NameGetFuncCall dispatch
NameGetFuncCall_Dispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 184 of 235 slots byte-identical
	pushw	16
	pushw	0
	pushw	62080
	pushw	0
	pushw	6888
	call	16712982
	lda	xwa, (6888:16)
	ld	(xwa+16), 0
	push	xwa
	ld	a, (65507:24)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	226
	pushw	242
	pushw	0
	pushw	7248
	call	16712341
	lda	xsp, (xsp+24)
	ld	xwa, 4294967295
	ld	xbc, 29818880
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
	call	16712341
	lda	xsp, (xsp+14)
	ld	(7283:16), 0
	ld	xwa, 4294967295
	ld	xbc, 29818881
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
	call	16712341
	lda	xsp, (xsp+14)
	lda	xwa, (7284:16)
	ld	(xwa+16), 0
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818882
	lds32	xde, 0
	jrl	500
	pushw	20
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7304
	call	16712982
	lda	xsp, (xsp+10)
	lda	xwa, (7304:16)
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe8	; v10 does not spell this byte either
	ldw	bc, 16257
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818883
	lds32	xde, 0
	jrl	424
	call	FileIO_GetCurrentFileIndex_Alt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	272
	pushw	0
	pushw	7362
	call	16712341
	lda	xsp, (xsp+10)
	ld	(7365:16), 0
	ld	xwa, 4294967295
	ld	xbc, 29818886
	lds32	xde, 0
	jrl	378
	pushw	12
	call	FileIO_GetCurrentFileIndex_Alt
	ld	wa, hl
	call	FileIO_GetFileEntryWithRefresh
	push	xhl
	pushw	0
	pushw	7326
	call	16712982
	lda	xsp, (xsp+10)
	lda	xwa, (7326:16)
	ld	(xwa+12), 0
	ldw	de, 11
	.byte 0xf3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe8	; v10 does not spell this byte either
	ldw	bc, 16257
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818885
	lds32	xde, 0
	jrl	302
	call	GetCurrentFileIndexAlt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	280
	pushw	0
	pushw	7366
	call	16712341
	lda	xsp, (xsp+10)
	ld	(7369:16), 0
	ld	xwa, 4294967295
	ld	xbc, 29818888
	lds32	xde, 0
	jrl	256
	call	GetCurrentFileIndexAlt
	ld	wa, hl
	call	GetFileRecordPtr
	push	xhl
	pushw	0
	pushw	7340
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (7340:16)
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe8	; v10 does not spell this byte either
	ldw	bc, 16257
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818887
	lds32	xde, 0
	jrl	184
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7370
	call	Free_Compare2
	pushw	20
	pushw	0
	pushw	7370
	pushw	2
	pushw	4174
	call	16712982
	lda	xsp, (xsp+18)
	lda	xwa, (135246:24)
	ld	(xwa+20), 0
	ldw	de, 19
	.byte 0xf3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe8	; v10 does not spell this byte either
	ldw	bc, 16257
	ldb	w, 110
	push	177
	nop
	nop
	sub	de, 1
	jr	gt, -19
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818895
	lds32	xde, 0
	jr	92
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7370
	call	Free_Compare2
	pushw	59
	pushw	0
	pushw	7370
	call	16713360
	lda	xsp, (xsp+14)
	lda	xwa, (135268:24)
	or	xhl, xhl
	jr	z, 22
	inc	1, xhl
	pushw	28
	push	xhl
	push	xwa
	call	16712982
	lda	xsp, (xsp+10)
	ld	(135296:24), 0
	jr	3
	ld	(xwa), 0
	ld	xwa, 135268
	call	FileIO_GetRecordType_Extended
	ld	xwa, 4294967295
	ld	xbc, 29818894
	lds32	xde, 0
	call	ApPostEvent
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
	call 0xfeb7ab
	bit 0x00,HL
	ret NZ
	ld	xwa, 7471110
	ld	xbc, 29818896
	lds32	xde, 0
	call	16423243
	pushw 12
	call	16291514
	ld	wa, hl
	call	16291811
	push	xhl
	pushw 0
	pushw 7198
	call	16712982
	lda	xsp, (xsp+10)
	lda	xbc, (7198:16)
	ld	(xbc+12), 0
	lds	wa, 1
	call	16693375
	ld	wa, hl
	cps	wa, 0
	.byte 0xf2, 0xca, 0x07, 0xf2, 0xde
	calr	4520
	ld	(4437:16), 0
	ret
CDlikeSwTtl_ShowDocTitle:
	call 0xfeb7ab
	bit 0x00,HL
	ret NZ
	.byte 0x0b, 0x0c, 0x00, 0x1d, 0xc1, 0xa3, 0xf8, 0xdb
	.byte 0x88, 0x1d, 0x95, 0xa5, 0xf8, 0x3b, 0x0b, 0x00
	.byte 0x00, 0x0b, 0x2c, 0x1c, 0x1d, 0x16, 0x05, 0xff
	.byte 0xbf, 0x0a, 0x37, 0xf1, 0x2c, 0x1c, 0x31, 0xb9
	.byte 0x0c, 0x00, 0x00, 0xd8, 0xaa, 0x1d, 0x7f, 0xb8
	.byte 0xfe, 0xdb, 0x88, 0xd8, 0xd8, 0xf2, 0xca, 0x07
	.byte 0xf2, 0xde, 0x1e, 0x64, 0x11, 0xf1, 0x55, 0x11
	.byte 0x00, 0x00, 0x0e
CDlikeSwTtl_ShowPdTitle:
	call 0xfeb7ab
	bit 0x00,HL
	ret NZ
	.byte 0x0b, 0x14, 0x00, 0x1d, 0xbb, 0xa0, 0xf8, 0xdb
	.byte 0x88, 0x1d, 0xe4, 0xa1, 0xf8, 0x3b, 0x0b, 0x00
	.byte 0x00, 0x0b, 0x3a, 0x1c, 0x1d, 0x16, 0x05, 0xff
	.byte 0xbf, 0x0a, 0x37, 0xf1, 0x3a, 0x1c, 0x31, 0xb9
	.byte 0x14, 0x00, 0x00, 0xd8, 0xac, 0x1d, 0x7f, 0xb8
	.byte 0xfe, 0xdb, 0x88, 0xd8, 0xd8, 0xf2, 0xca, 0x07
	.byte 0xf2, 0xde, 0x1e, 0x20, 0x11, 0xf1, 0x55, 0x11
	.byte 0x00, 0x00, 0x0e
CDlikeSwTtl_SongBit1Check:
	call	16693163
	bit	1, hl
	jr	z, 21
	calr	4464
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
	jr	29
CDlikeSwTtl_SongBit0Check:
	call	16693163
	bit	0, hl
	jrl	z, -260
	calr	4433
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
CDlikeSwTtl_JumpToFA9D58:
	jp ApPostEvent

CDlikeSwTtl_DocBitCheck:
	call	16693163
	bit	1, hl
	jr	nz, 10
	call	16693163
	bit	0, hl
	jrl	z, -218
CDlikeSwTtl_DocRedraw:
	calr	4391
	jp	16693581
CDlikeSwTtl_PdBitCheck:
	call	16693163
	bit	1, hl
	jr	nz, 10
	call	16693163
	bit	0, hl
	jrl	z, -176
CDlikeSwTtl_PdRedraw:
	calr	4365
	jp	16693581
CDlikeSwTtl_SongConfirmStart:
	call	16693163
	bit	1, hl
	jr	z, 7
	ld	(7498:16), 3
	jr	27
CDlikeSwTtl_SongConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	ld	(7498:16), 2
	jr	11
CDlikeSwTtl_SongConfirmDefault:
	ld (7498:16), 1
	calr CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_SongConfirmJump:
	jp	16693796
CDlikeSwTtl_SongConfirmDispatch:
	ld a, (7498:16)
	cps a, 2
	jr z, CDlikeSwTtl_SongConfirmState2
	cps a, 1
	jr z, CDlikeSwTtl_SongConfirmState1
	cps a, 3
	ret nz

CDlikeSwTtl_SongConfirmState1:
	calr	4246
	jp	16693748
CDlikeSwTtl_SongConfirmState2:
	calr	4190
	jp	16693778
CDlikeSwTtl_DocConfirmStart:
	call	16693163
	bit	1, hl
	jr	z, 7
	ld	(7498:16), 3
	jr	27
CDlikeSwTtl_DocConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	ld	(7498:16), 2
	jr	11
CDlikeSwTtl_DocConfirmDefault:
	ld (7498:16), 1
	calr CDlikeSwTtl_ShowDocTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_DocConfirmJump:
	jp	16693796
CDlikeSwTtl_PdConfirmStart:
	call	16693163
	bit	1, hl
	jr	z, 7
	ld	(7498:16), 3
	jr	27
CDlikeSwTtl_PdConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	ld	(7498:16), 2
	jr	11
CDlikeSwTtl_PdConfirmDefault:
	ld (7498:16), 1
	calr CDlikeSwTtl_ShowPdTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_PdConfirmJump:
	jp	16693796
CDlikeSwTtl_SongNavDispatch:
	pushw	iz
	ld	iz, wa
	call	16693163
	bit	1, hl
	jr	z, 104
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
	call	16423243
	ld	wa, iz
	call	16328724
	ld	(135304:24), 0
	ldw	(135302:24), 0
	calr	63395
	calr	63167
	ld	xwa, 4294967295
	ld	xbc, 31916047
	lds32	xde, 0
	calr	64163
	ld	xwa, 4294967295
	ld	xbc, 31916048
	lds32	xde, 0
	calr	64148
	ld	xwa, 4294967295
	ld	xbc, 31916057
	lds32	xde, 0
	calr	64133
	ld	xwa, 4294967295
	ld	xbc, 31916058
	lds32	xde, 0
	jr	111
CDlikeSwTtl_SongNavBit0:
	call	16693163
	bit	0, hl
	jr	z, 110
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
	call	16423243
	ld	wa, iz
	call	16328724
	ld	(135304:24), 0
	ldw	(135302:24), 0
	calr	63282
	calr	63054
	ld	xwa, 4294967295
	ld	xbc, 31916047
	lds32	xde, 0
	calr	64050
	ld	xwa, 4294967295
	ld	xbc, 31916048
	lds32	xde, 0
	calr	64035
	ld	xwa, 4294967295
	ld	xbc, 31916057
	lds32	xde, 0
	calr	64020
	ld	xwa, 4294967295
	ld	xbc, 31916058
	lds32	xde, 0
CDlikeSwTtl_SongNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowSongTitle
	jr CDlikeSwTtl_SongNavReturn

CDlikeSwTtl_SongNavNoRedraw:
	ld wa, iz
	call NavigateSongList
	ld (0x021088:24), 0x00
	ldw (0x021086:24), 0x0000
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
	pushw	iz
	ld	iz, wa
	call	16693163
	bit	1, hl
	jr	z, 52
	call	16693581
	ld	wa, iz
	call	16328803
	ldw	(135302:24), 0
	calr	63095
	calr	62867
	ld	xwa, 4294967295
	ld	xbc, 31916051
	lds32	xde, 0
	calr	63863
	ld	xwa, 4294967295
	ld	xbc, 31916050
	lds32	xde, 0
	jr	59
CDlikeSwTtl_DocNavBit0:
	call	16693163
	bit	0, hl
	jr	z, 58
	call	16693581
	ld	wa, iz
	call	16328803
	ldw	(135302:24), 0
	calr	63034
	calr	62806
	ld	xwa, 4294967295
	ld	xbc, 31916051
	lds32	xde, 0
	calr	63802
	ld	xwa, 4294967295
	ld	xbc, 31916050
	lds32	xde, 0
CDlikeSwTtl_DocNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowDocTitle
	jr CDlikeSwTtl_DocNavReturn

CDlikeSwTtl_DocNavNoRedraw:
	ld wa, iz
	call NavigateDocList
	ldw (0x021086:24), 0x0000
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
	pushw	iz
	ld	iz, wa
	call	16693163
	bit	1, hl
	jr	z, 52
	call	16693581
	ld	wa, iz
	call	16328863
	ldw	(135302:24), 0
	calr	62913
	calr	62685
	ld	xwa, 4294967295
	ld	xbc, 31916053
	lds32	xde, 0
	calr	63681
	ld	xwa, 4294967295
	ld	xbc, 31916052
	lds32	xde, 0
	jr	59
CDlikeSwTtl_PdNavBit0:
	call	16693163
	bit	0, hl
	jr	z, 58
	call	16693581
	ld	wa, iz
	call	16328863
	ldw	(135302:24), 0
	calr	62852
	calr	62624
	ld	xwa, 4294967295
	ld	xbc, 31916053
	lds32	xde, 0
	calr	63620
	ld	xwa, 4294967295
	ld	xbc, 31916052
	lds32	xde, 0
CDlikeSwTtl_PdNavFinishNames:
	calr NameGetFuncCall
	calr CDlikeSwTtl_ShowPdTitle
	jr CDlikeSwTtl_PdNavReturn

CDlikeSwTtl_PdNavNoRedraw:
	ld wa, iz
	call NavigatePdList
	ldw (0x021086:24), 0x0000
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
	add xde, SepaOut_Config_0_0x16A
	ld de, (xde)
	lda xix, (DpDocTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpDocTtlFunc title dispatch
DpDocTtl_Dispatch:
	ldw	(135302:24), 0
	calr	62678
	calr	62450
	calr	64337
	jrl	206
	call	16693163
	bit	0, hl
	jr	z, 7
	calr	3398
	call	16693581
	calr	61909
	jrl	184
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
	add xwa, SepaOut_Config_0_0x156
	ld wa, (xwa)
	lda xix, (DpDoc_CaseB:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DpDocTtl case B
DpDoc_CaseB:
	ldw wa, 0xffff
	jr DpDoc_NavigateBackward

; DpDocTtl case C
DpDoc_CaseC:
	call	16693163
	bit	1, hl
	jr	z, 9
	calr	3196
	call	16693778
	jr	84
DpDoc_CheckBit0PlayMode:
	call	16693163
	bit	0, hl
	jr	z, 75
	calr	3227
	call	16693748
	jr	66
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
	add xde, SepaOut_Config_0_0x18A
	ld de, (xde)
	lda xix, (DpPdTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpPdTtlFunc title dispatch
DpPdTtl_Dispatch:
	ldw	(135302:24), 0
	calr	62375
	calr	62147
	calr	64102
	jrl	206
	call	16693163
	bit	0, hl
	jr	z, 7
	calr	3095
	call	16693581
	calr	61606
	jrl	184
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
	add xwa, SepaOut_Config_0_0x176
	ld wa, (xwa)
	lda xix, (DpPd_CaseB:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DpPdTtl case B
DpPd_CaseB:
	ldw wa, 0xffff
	jr DpPd_NavigateBackward

; DpPdTtl case C
DpPd_CaseC:
	call	16693163
	bit	1, hl
	jr	z, 9
	calr	2893
	call	16693778
	jr	84
DpPd_CheckBit0PlayMode:
	call	16693163
	bit	0, hl
	jr	z, 75
	calr	2924
	call	16693748
	jr	66
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
	add xde, SepaOut_Config_0_0x1AA
	ld de, (xde)
	lda xix, (DpSmfTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpSmfTtlFunc title dispatch
DpSmfTtl_Dispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 16 of 21 slots byte-identical
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0x72	; differs from v10 here and llvm-objdump cannot read it
	jrl	z, 255
	ld	(135304:24), 0
	ldw	(135302:24), 0
	calr	62057
	calr	61829
	calr	63632
	jrl	230
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x72	; differs from v10 here and llvm-objdump cannot read it
	jrl	z, 222
	call	16693163
	bit	0, hl
	jr	z, 23
	calr	2769
	call	16693581
	ld	xwa, 7274534
	ld	xbc, 29818889
	lds32	xde, 0
	call	ApPostEvent
	calr	61264
	jrl	184
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
	add xwa, SepaOut_Config_0_0x196
	ld wa, (xwa)
	lda xix, (DpSmf_CaseB:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DpSmfTtl case B
DpSmf_CaseB:
	ldw wa, 0xffff
	jr DpSmf_NavigateBackward

; DpSmfTtl case C
DpSmf_CaseC:
	call	16693163
	bit	1, hl
	jr	z, 9
	calr	2551
	call	16693778
	jr	84
DpSmf_CheckBit0PlayMode:
	call	16693163
	bit	0, hl
	jr	z, 75
	calr	2582
	call	16693748
	jr	66
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
	add xde, SepaOut_Config_0_0x1B6
	ld de, (xde)
	lda xix, (DpSmfLyrTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	call	16693163
	bit	1, hl
	jr	z, 9
	calr	2255
	call	16693778
	jr	79
DpSmfLyr_CheckBit0PlayMode:
	call	16693163
	bit	0, hl
	jr	z, 70
	calr	2286
	call	16693748
	jr	61
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
	add xde, SepaOut_Config_0_0x1C2
	ld de, (xde)
	lda xix, (SqTrSelTtl_Dispatch:24)
	jp_ind 8, 0x07, 0xf0, 0xe8
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
	call TextRender_PopAndReturn_0x9
	call GraphicsRender_ByteData_0x67
	ldw wa, 0x00ff
	call GraphicsRender_ByteData_0x6
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
	ld xiy, SepaOut_Config_0_0x1CE
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret


; --- Demo Routines ---
