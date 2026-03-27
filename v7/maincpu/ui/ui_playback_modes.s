; =============================================================================
; UI Playback Mode Handlers (3K lines)
; =============================================================================
;
; UI state event handling and playback mode control: voice parameter
; handlers, sequencer timer/tempo, part validation, play/song/medley
; mode dispatch, part format handlers, and display mode transitions.
; =============================================================================

UIStateEvt_VoiceParamHandler:
	.byte 0xc1, 0x9a, 0x8c, 0x21, 0xc9, 0xcf, 0x8e, 0x66
	.byte 0x13, 0xc9, 0xcf, 0x64, 0x66, 0x0e, 0xc9, 0xcf
	.byte 0x6c, 0x61, 0x11, 0xc9, 0xcf, 0x7a, 0x62, 0x04
	.byte 0x1b, 0xe6, 0x02, 0xf2, 0xf1, 0xea, 0x10, 0x00
	.byte 0x00, 0x78, 0xa4, 0x00, 0xc1, 0xe1, 0xbf, 0x21
	.byte 0xc9, 0xdb, 0xf2, 0x8a, 0x03, 0xf2, 0xde, 0xc1
	.byte 0xe2, 0xbf, 0x21, 0xc1, 0xe3, 0xbf, 0x20, 0xc8
	.byte 0xcf, 0xff, 0x6e, 0x08, 0xc1, 0xea, 0x10, 0x3c
	.byte 0xfe, 0x78, 0x84, 0x00, 0xc8, 0x33, 0x02, 0x6e
	.byte 0x02, 0x68, 0x7d, 0xf1, 0xea, 0x10, 0xc8, 0x66
	.byte 0x07, 0xc1, 0xea, 0x10, 0x3c, 0xfe, 0x68, 0x70
	.byte 0xc8, 0xc1, 0xc9, 0xcc, 0x04, 0xc9, 0x33, 0x02
	.byte 0x66, 0x35, 0x28, 0xc9, 0xd1, 0x1d, 0x46, 0x19
	.byte 0xf4, 0x48, 0x1d, 0xf1, 0x03, 0xf2, 0x1d, 0x8b
	.byte 0x03, 0xf2, 0x1d, 0xb5, 0x96, 0xf5, 0x1d, 0x2d
	.byte 0x24, 0xef, 0xf1, 0x31, 0x04, 0x00, 0x00, 0xc1
	.byte 0xb3, 0x28, 0x3e, 0x10, 0xf1, 0x9e, 0xf1, 0x02
	.byte 0x00, 0x00, 0xc1, 0xa5, 0x28, 0x3c, 0xfe, 0x21
	.byte 0x4c, 0x1d, 0x72, 0x71, 0xfc, 0x68, 0x31, 0x28
	.byte 0xc9, 0xd1, 0x1d, 0xe4, 0x18, 0xf4, 0x48, 0x1d
	.byte 0xf1, 0x03, 0xf2, 0x1d, 0x8b, 0x03, 0xf2, 0x1d
	.byte 0xb5, 0x96, 0xf5, 0x1d, 0x2d, 0x24, 0xef, 0xf1
	.byte 0x31, 0x04, 0x00, 0x00, 0xc1, 0xb3, 0x28, 0x3e
	.byte 0x10, 0xf1, 0x9e, 0xf1, 0x02, 0x00, 0x00, 0xf1
	.byte 0xf4, 0x11, 0x00, 0x00, 0x1d, 0xc8, 0xc8, 0xf3
	.byte 0x0e, 0x44, 0xa0, 0xf1, 0x00, 0x00, 0xd9, 0xd1
	.byte 0x23, 0x10, 0x21, 0x10, 0xc5, 0xf0, 0xf1, 0x66
	.byte 0x05, 0xd9, 0x1c, 0xf8, 0x68, 0x44, 0xd8, 0xd0
	.byte 0x21, 0x10, 0xd9, 0xa0, 0xc9, 0x8b, 0xc9, 0x8a
	.byte 0xd1, 0x9e, 0xf1, 0x26, 0xcb, 0x89, 0x11, 0xde
	.byte 0x2a, 0xca, 0x89, 0x67, 0x2d, 0x28, 0x43, 0x50
	.byte 0xf2, 0x00, 0x00, 0x23, 0x03, 0xcb, 0x41, 0xd8
	.byte 0x8d, 0xf3, 0x07, 0xec, 0xf4, 0xcf, 0x66, 0x03
	.byte 0x48, 0x68, 0x03, 0x48, 0x68, 0x14, 0xc9, 0x61
	.byte 0xc9, 0x88, 0xf1, 0x56, 0x0d, 0x40, 0xc1, 0x54
	.byte 0x0d, 0x3e, 0x01, 0xc1, 0x7b, 0x28, 0x3e, 0x04
	.byte 0x68, 0x0c, 0xc1, 0x54, 0x0d, 0x3c, 0xfe, 0xc1
	.byte 0x7b, 0x28, 0x3c, 0xfb, 0xc8, 0xd0, 0x0e
SeqPlay_RestoreVoiceState_Return:
	ldb_d8 a, (0x2878)
	pushw wa
	ldb_da a, (0x00ffe3)
	stb_d8 (0x2878), a
	call SeqVoice_InitEntry
	popw wa
	stb_d8 (0x2878), a
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
	stda16	(64610), wa
	call	16554829
	ret
PlayMode_NullRet:
	ret
PlayMode_SetupAndDispatch:
	; --- Setup: load/store/call/set flag ---
	ldw_d16	wa, (0xf19e)
	stda16	(0x2875), wa
	stdi8	(3424), 0
	call AccWrap_PlayModeDispatch
	ordi8	0x28a7, 4
	ret
PlayMode_TeardownAndRestore:
	; --- Teardown: load/store/clear flags ---
	ldw_d16	wa, (0x2875)
	stda16	(0xf19e), wa
	anddi8	(0x28a7), 251
	ordi8	0x28b3, 16
	anddi8	(0x28a7), 247
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
	stb_d8	(3423), a
	inc 1, e
	stb_d8	(3424), e
	ret
Part_ValidateAndActivate:
	; --- Validation: check range, optionally call ---
	stdi16	(0x287f), 1
	stdi16	(3383), 0
	cpdi8	(3424), 0
	jr z, PartValidate_Done
	cpdi8	(3424), 16
	jr ugt, PartValidate_Done
	stdi16	(4360), 0
	xor	wa, wa
	ldb a, 0x8a
	call UI_PostModeChangeEvent
PartValidate_Done:
	ret
PlaybackDispatch_NullRet:
	ret


PlaybackMode_DispatchByType:
	.byte 0xf1, 0x35, 0x0d, 0xc8, 0x76, 0xaf, 0x00, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x7a, 0x66, 0x68, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x78, 0x66, 0x67, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x73, 0x66, 0x66, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x76, 0x66, 0x65, 0xc1, 0x9a, 0x8c, 0x3f, 0x74
	.byte 0x66, 0x64, 0xc1, 0x9a, 0x8c, 0x3f, 0x75, 0x76
	.byte 0x62, 0x00, 0xc1, 0x9a, 0x8c, 0x3f, 0x6f, 0x66
	.byte 0x61, 0xc1, 0x9a, 0x8c, 0x3f, 0x72, 0x66, 0x60
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x70, 0x66, 0x5f, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x71, 0x76, 0x5d, 0x00, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x79, 0x66, 0x5c, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x77, 0x66, 0x55, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x6c, 0x66, 0x4e, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x6d, 0x66, 0x47, 0xc1, 0x9a, 0x8c, 0x3f, 0x6e
	.byte 0x66, 0x40, 0x1b, 0x09, 0x06, 0xf2
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
	anddi8 (3381), 254
	ret

PlayMode_InitFlagBlock:
	call	PlayMode_InitFlagBlock_0x5
	ret
	.byte 0xc1
	ldw	ix, 0x3f0d
	nop
	jr	nz, 9
	stdi8	(3380), 1
	call	PlayMode_InitFlagBlock_0x16
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	(4420), 10
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
	stdi8	(3380), 0
	ret

PlayMode_CheckAndDispatch:
	cpdi8 (3380), 1
	jr nz, PlayMode_SendModeCommand
	stdi8 (3380), 0
	stdi8 (4420), 0
	call PlayMode_DispatchAndClearBit2
	bitda 2, (3394)
	jr z, PlayMode_SendModeCommand
	jr PlayMode_SendModeCommand

PlayMode_SendModeCommand:
	.byte 0xf1, 0x55, 0x11, 0x00, 0x00, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x7a, 0x66, 0x07, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x78, 0x66, 0x0a
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
	anddi8 (0x28ac), 251
	ret

PlayMode_StartAndSendCommand:
	.byte 0xc1, 0x34, 0x0d, 0x3f, 0x01, 0x6e, 0x30, 0xc1
	.byte 0x44, 0x11, 0x3f, 0x00, 0x6e, 0x29, 0x1d, 0xa6
	.byte 0x06, 0xf2, 0xf1, 0x55, 0x11, 0x00, 0x01, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x7a, 0x66, 0x07, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x78, 0x66, 0x0a
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
	bitda 2, (0x28ac)
	jr z, SeqRestart_Return
	ld iz, wa
	ldb_d8 a, (0xfc5f)
	and a, 0x30
	ld wa, iz
	jr nz, SeqRestart_Return
	call AccWrap_PlayModeDispatch
	ldw bc, 0xf000

SeqRestart_WaitBit2Loop:
	bitda 2, (1056)
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
	.byte 0xf1, 0xac, 0x28, 0xca, 0x66, 0x25, 0xf1, 0x55
	.byte 0x11, 0x00, 0x01, 0xc1, 0x9a, 0x8c, 0x3f, 0x7a
	.byte 0x66, 0x07, 0xc1, 0x9a, 0x8c, 0x3f, 0x78, 0x66
	.byte 0x0a
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
	ldb_d8 l, (4437)
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
	stdi8	(3380), 1
	call	SongMode_InitFlagBlock_0x18
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	(4420), 10
	ret
	stdi8	(3380), 0
	ret

SongMode_CheckAndDispatch:
	cpdi8 (3380), 1
	jr nz, SongMode_SendStopCommand
	stdi8 (3380), 0
	stdi8 (4420), 0
	call SongMode_AbortAndClearBit2
	bitda 2, (3394)
	jr z, SongMode_SendStopCommand
	jr SongMode_SendStopCommand

SongMode_SendStopCommand:
	stdi8 (4437), 0
	xor wa, wa
	ldb a, 0x6d
	call UI_PostModeChangeEvent
	ret

SongMode_AbortAndClearBit2:
	.byte 0xc1, 0xac, 0x28, 0x3c, 0xfb, 0x1d, 0x4d, 0xb9
	.byte 0xfe, 0x0e
SongMode_StartPlayback:
	cpdi8 (3380), 1
	jrl nz, SongMode_StartReturn
	cpdi8 (4420), 0
	jrl nz, SongMode_StartReturn
	call SongMode_AbortAndClearBit2
	stdi8 (4437), 1
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
	stdi8 (4437), 2
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus3:
	stdi8 (4437), 3
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus4:
	stdi8 (4437), 4
	jp PartFormat_PartTypeDisp

VoiceState_SetStatus1AndDispatch:
	.byte 0xf1, 0x55, 0x11, 0x00, 0x01, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x74, 0x66, 0x73, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x70, 0x76, 0x8d, 0x00, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x75, 0x66, 0x6e, 0xc1, 0x9a, 0x8c, 0x3f, 0x71
	.byte 0x76, 0x84, 0x00, 0xc1, 0x9a, 0x8c, 0x3f, 0x73
	.byte 0x66, 0x69, 0xc1, 0x9a, 0x8c, 0x3f, 0x6f, 0x66
	.byte 0x7c, 0xc1, 0x9a, 0x8c, 0x3f, 0x76, 0x66, 0x5b
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x72, 0x66, 0x6e, 0x1b
	.byte 0xac, 0x08, 0xf2
PartFormat_PartTypeDisp:
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x74, 0x66, 0x35, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x70, 0x66, 0x2e, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x75, 0x66, 0x31, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x71, 0x66, 0x2a, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x73, 0x66, 0x2d, 0xc1, 0x9a, 0x8c, 0x3f, 0x6f
	.byte 0x66, 0x26, 0xc1, 0x9a, 0x8c, 0x3f, 0x76, 0x66
	.byte 0x1f, 0xc1, 0x9a, 0x8c, 0x3f, 0x72, 0x66, 0x18
	.byte 0x1b, 0xac, 0x08, 0xf2
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
	stdi8	(3380), 1
	call	PartFormat_InitFlagBlock_0x1B
	ret
	.byte 0xc1, 0xac
	pushw	wa
	push	xiz
	.byte 0x04
	stdi8	(4420), 10
	ret
	stdi8	(3380), 0
	ret

PartFormat_CheckAndDispatch:
	cpdi8 (3380), 1
	jr nz, PartFormat_SendStopCommand
	stdi8 (3380), 0
	stdi8 (4420), 0
	call PartFormat_AbortAndClearBit2
	bitda 2, (3394)
	jr z, PartFormat_SendStopCommand
	jr PartFormat_SendStopCommand

PartFormat_SendStopCommand:
	stdi8 (4437), 0
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent
	ret

PartFormat_AbortAndClearBit2:
	.byte 0xc1, 0xac, 0x28, 0x3c, 0xfb, 0x1d, 0x4d, 0xb9
	.byte 0xfe, 0x0e
PartFormat_StartPlayback:
	cpdi8 (3380), 1
	jrl nz, PartFormat_StartReturn
	cpdi8 (4420), 0
	jrl nz, PartFormat_StartReturn
	call PartFormat_AbortAndClearBit2
	stdi8 (4437), 1
	xor wa, wa
	ldb a, 0x6e
	call UI_PostModeChangeEvent

PartFormat_StartReturn:
	ret

PlayModeStop_InitFlagBlock:
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0xc1, 0x9b, 0x8c, 0x3f
	.byte 0x76, 0x66, 0x04, 0x1d, 0x40, 0x09, 0xf2, 0x0e
	.byte 0xc1, 0x34, 0x0d, 0x3f, 0x00, 0x6e, 0x09, 0xf1
	.byte 0x34, 0x0d, 0x00, 0x01, 0x1d, 0x51, 0x09, 0xf2
	.byte 0x0e, 0xc1, 0xac, 0x28, 0x3e, 0x04, 0xf1, 0x44
	.byte 0x11, 0x00, 0x0a, 0x0e, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x6c, 0x6e, 0x05, 0xf1, 0x34, 0x0d, 0x00, 0x00
	.byte 0x0e
PlayMode_StopAbortRetZero:
	cpdi8 (3380), 1
	jr nz, PlayModeStop_SendStopCmd
	stdi8 (3380), 0
	stdi8 (4420), 0
	call PlayMode_StopAndAbort
	bitda 2, (3394)
	jr z, PlayModeStop_SendStopCmd
	jr PlayModeStop_SendStopCmd

PlayModeStop_SendStopCmd:
	stdi8 (4437), 0
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent
	ret

PlayMode_StopAndAbort:
	.byte 0xc1, 0xac, 0x28, 0x3c, 0xfb, 0x1d, 0xfd, 0x2a
	.byte 0xf2, 0x1d, 0x4d, 0xb9, 0xfe, 0x0e
PlayMode_SendCommand6C:
	cpdi8 (3380), 1
	jrl nz, PlayModeStop_SendReturn
	cpdi8 (4420), 0
	jrl nz, PlayModeStop_SendReturn
	call PlayMode_StopAndAbort
	stdi8 (4437), 1
	xor wa, wa
	ldb a, 0x6c
	call UI_PostModeChangeEvent

PlayModeStop_SendReturn:
	ret

PlayModeStop_ClearFlagBlock:
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x6c, 0x6e, 0x05, 0xf1, 0x34, 0x0d, 0x00
	.byte 0x00, 0x0e
SqSngNameTtl_Dispatch:
	xor wa, wa
	ldb a, 0x73
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	ret

CDlikeSwitch_PlaybackTimer:
	.byte 0xc1, 0x44, 0x11, 0x20, 0xc8, 0xd8, 0x66, 0x7a
	.byte 0xc8, 0x69, 0xc8, 0xdd, 0x6e, 0x22, 0xc1, 0x9a
	.byte 0x8c, 0x3f, 0x7a, 0x66, 0x09, 0xc1, 0x9a, 0x8c
	.byte 0x3f, 0x78, 0x66, 0x02, 0x68, 0x60
CDlikeTimer_ResetAccompaniment:
	pushw wa
	anddi8 (0x28b2), 249
	anddi8 (0x28a7), 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_CheckZeroCount:
	.byte 0xc8, 0xd8, 0x6e, 0x4a, 0xc1, 0x9a, 0x8c, 0x3f
	.byte 0x7a, 0x66, 0x3d, 0xc1, 0x9a, 0x8c, 0x3f, 0x78
	.byte 0x66, 0x36, 0xc1, 0x9a, 0x8c, 0x3f, 0x74, 0x66
	.byte 0x27, 0xc1, 0x9a, 0x8c, 0x3f, 0x75, 0x66, 0x10
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x73, 0x66, 0x11, 0xc1
	.byte 0x9a, 0x8c, 0x3f, 0x76, 0x66, 0x0a, 0x68, 0x1e
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
	stb_d8 (4420), w

CDlikeTimer_Return:
	ret

CDlike_ResetPlaybackState:
	ei 6
	xor wa, wa
	stda16 (1052), xwa
	stb_d8 (1051), a
	stda16 (1048), xwa
	stb_d8 (1047), a
	bitda 1, (0x28a7)
	jr z, CDlikeReset_SetTimerFlags
	stdi8 (1054), 1
	stdi8 (1045), 0
	stdi8 (1046), 0
	stdi8 (1076), 0
	stdi8 (1077), 0

CDlikeReset_SetTimerFlags:
	stdi8 (1057), 1
	stdi8 (1056), 1
	ei 0
	ret

CDlike_InitModeAndLoadBank:
	.byte 0xc1, 0x46, 0xb7, 0x3e, 0x40, 0xc1, 0xad, 0xfd
	.byte 0x21, 0xf1, 0x42, 0x0d, 0x41, 0xf1, 0x34, 0x0d
	.byte 0x00, 0x00, 0xf1, 0x44, 0x11, 0x00, 0x00, 0x1d
	.byte 0x02, 0x0b, 0xf2, 0xc1, 0x9a, 0x8c, 0x3f, 0x77
	.byte 0x66, 0x3c, 0xc1, 0x9a, 0x8c, 0x3f, 0x78, 0x66
	.byte 0x35, 0xc1, 0x9a, 0x8c, 0x3f, 0x79, 0x66, 0x2e
	.byte 0xc1, 0x9a, 0x8c, 0x3f, 0x7a, 0x66, 0x27, 0x1d
	.byte 0x7f, 0x0c, 0xf2, 0xd1, 0x9e, 0xf1, 0x20, 0xf1
	.byte 0x75, 0x28, 0x50, 0xf1, 0x9e, 0xf1, 0x02, 0x00
	.byte 0x00, 0xf1, 0x14, 0x23, 0x02, 0x00, 0x00, 0x45
	.byte 0xa0, 0xf9, 0x00, 0x00, 0x44, 0x04, 0xcf, 0x03
	.byte 0x00, 0x31, 0x10, 0x03, 0x95, 0x11
CDlikeSw_NullRet:
	ret

CDlike_LoadSongBankData:
	stdi8 (6882), 0
	cpdi16 0xf19e, 0
	jr nz, CDlikeBankLoad_CheckSavedState
	stdi8 (6882), 1

CDlikeBankLoad_CheckSavedState:
	ldw_da xwa, (0x00ffec)
	stda16 (0xf19e), xwa
	ld xiy, 0xf180
	ld xix, 0xab000
	xor xwa, xwa
	ldb_da a, (0x00ffe3)
	sla xwa, 11
	add xix, xwa
	ldw bc, 0x800
	ldir85
	cpdi8 (6882), 1
	jr nz, CDlikeBankLoad_Return
	stdi16 (0xf19e), 0

CDlikeBankLoad_Return:
	ret

CDlike_ExitModeAndRestore:
	.byte 0x1d, 0x72, 0x2b, 0xf2, 0xc1, 0x46, 0xb7, 0x3c
	.byte 0xbf, 0xc1, 0xac, 0x28, 0x3c, 0xfb, 0xf1, 0x44
	.byte 0x11, 0x00, 0x00, 0xf1, 0x42, 0x0d, 0xca, 0x66
	.byte 0x02, 0x68, 0x00
CDlikeExit_CheckPlaybackType:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0x77, 0x66, 0x32, 0xc1
	.byte 0x9b, 0x8c, 0x3f, 0x78, 0x66, 0x2b, 0xc1, 0x9b
	.byte 0x8c, 0x3f, 0x79, 0x66, 0x24, 0xc1, 0x9b, 0x8c
	.byte 0x3f, 0x7a, 0x66, 0x1d, 0xf1, 0xea, 0x10, 0x00
	.byte 0x01, 0x1d, 0xce, 0x4b, 0xfc, 0x1d, 0x4d, 0x9b
	.byte 0xfc, 0x1d, 0xc2, 0x84, 0xfd, 0x1d, 0x6e, 0x0c
	.byte 0xf2, 0xd1, 0x75, 0x28, 0x20, 0xf1, 0x9e, 0xf1
	.byte 0x50
PlayMode_ResetAndSchedule:
	stdi8	(3380), 0
	call	16635550
	ret
SongBank_SwitchAndUpdateTempo:
	stb_da (0x00ffe3), a
	call SongBank_SaveAndReload
	call SeqTimer_PostTempoUpdate
	ret

SongBank_SaveAndReload:
	ldw_d16 xwa, (0xf22f)
	stda16 (0x286f), xwa
	ldw_d16 xwa, (0xf231)
	stda16 (0x2871), xwa
	call SongBank_LoadToWorkArea
	call SongBank_CheckAccompanimentMode
	anddi8 (0x28b1), 254
	ret

SongBank_LoadToWorkArea:
	xor xwa, xwa
	ldb_da a, (0x00ffe3)
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ldw_d16 xwa, (0xf19e)
	stw_da (0x00ffec), xwa
	ldw_d16 xwa, (0x286f)
	stda16 (0xf22f), xwa
	ldw_d16 xwa, (0x2871)
	stda16 (0xf231), xwa
	ret

SongBank_CheckAccompanimentMode:
	cpdi8 (0xf23d), 255
	jr z, SongBank_EnableAccompaniment
	bitda 2, (0xfdad)
	jr z, SongBank_CheckBassMode
	anddi8 (0xfdad), 251
	xor a, a
	jr SongBank_SendAccompEvent

SongBank_EnableAccompaniment:
	bitda 2, (0xfdad)
	jr nz, SongBank_CheckBassMode
	ordi8 0xfdad, 4
	ldb a, 0x4

SongBank_SendAccompEvent:
	stdi8	(4330), 1
	ldb	e, 145
	ldb	d, 3
	ldb	w, 4
	call	16624640
	call	15668398
SongBank_CheckBassMode:
	cpdi8 (0xf24b), 255
	jr z, SongBank_EnableBassMode
	anddi8 (0xfdad), 254
	xor a, a
	jr SongBank_SendBassEvent

SongBank_EnableBassMode:
	ordi8 0xfdad, 1
	ldb a, 0x1

SongBank_SendBassEvent:
	ldb	e, 145
	ldb	d, 3
	ldb	w, 1
	call	16624640
	call	15668398
	stdi8	(4596), 1
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
	lda_24 xix, (SqTrAs_CondCheck)
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
	lda_24 xix, (SQTR_DISPATCH_TABLE_1)
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
	lda_24 xix, (SQTR_DISPATCH_TABLE_2)
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
	lda_24 xix, (SqTrAsPsTtl_Dispatch)
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

; SqTrAsPsTtl case F
SqTrAsPsTtl_CaseF:
	.byte 0xc1, 0x9a, 0x8c, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x6c, 0x00, 0xd8, 0xd8, 0x61, 0x29, 0xd8, 0xcf
	.byte 0x0d, 0x00, 0x6a, 0x23, 0xf2, 0x2a, 0x00, 0xe2
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xd8, 0x12
	.byte 0xd8, 0xee, 0x01, 0x44, 0x38, 0x00, 0xe2, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x62, 0x0f
	.byte 0xf2, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0x3a
	.byte 0x3b, 0x3c, 0x3e, 0x1d, 0x46, 0x0b, 0xf2, 0x5e
	.byte 0x5c, 0x5b, 0x5a, 0x0e
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
	lda_24 xix, (SqMdlyPlyTtl_Dispatch)
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
	lda_24 xix, (DkMdlyPlyTtl_Dispatch)
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
	lda_24 xde, (SepaOut_Config_0_0x6E)

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
	ldb_d8	a, (35994)
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
	.byte 0xd7, 0xfa, 0x88, 0xd8, 0x80, 0xf2, 0x74, 0x00
	.byte 0xe2, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x20, 0x31
	.byte 0x01, 0x04, 0x1d, 0x26, 0xcd, 0xfc, 0xdb, 0x8e
	.byte 0x9f, 0x04, 0x20, 0x1e, 0xa4, 0xff, 0xde, 0xf3
	.byte 0x6e, 0x2a, 0xd7, 0xfa, 0x88, 0xd8, 0x80, 0xf2
	.byte 0x74, 0x00, 0xe2, 0x31, 0xd3, 0x07, 0xe4, 0xe0
	.byte 0x20, 0xf1, 0x9e, 0x8c, 0x41, 0xc9, 0x8d, 0xda
	.byte 0x12, 0x0b, 0xff, 0x00, 0x30, 0x90, 0x00, 0x31
	.byte 0x10, 0x00, 0x1d, 0x53, 0xaa, 0xfd, 0x1d, 0xd6
	.byte 0xd7, 0xfd, 0x68, 0x0a
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
	.byte 0xc1, 0x9a, 0x8c, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x6f, 0x00, 0xd8, 0xd8, 0xb0, 0xf1, 0xd8, 0xde
	.byte 0xb0, 0xfa, 0xd8, 0x80, 0xf2, 0xb4, 0x00, 0xe2
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x57
	.byte 0x11, 0xf2, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
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
	ldw_da	wa, (135302)
	calr	65180
	ldw_da	wa, (135302)
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
	lda_24 xix, (DpMdlyDocTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlyDocTtlFunc title dispatch
DpMdlyDocTtl_Dispatch:
	stiw_da	(0x021086), 0
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
	lda_24 xix, (DpMdlyPdTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlyPdTtlFunc title dispatch
DpMdlyPdTtl_Dispatch:
	stiw_da	(0x021086), 0
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
	lda_24 xix, (DpMdlySmfTtl_Dispatch)
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
	lda_24 xix, (DpMdlySmfLyrTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpMdlySmfLyrTtlFunc title dispatch
DpMdlySmfLyrTtl_Dispatch:
	ldb_d8	a, (35995)
	cp	a, 108
	jr	nz, 38
	cp	a, 118
	jr	z, 19
	stib_da	(135304), 0
	stiw_da	(135302), 0
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
	lda_24 xix, (NameGetFuncCall_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4
; NameGetFuncCall dispatch
NameGetFuncCall_Dispatch:
	.byte 0x0b, 0x10, 0x00, 0x0b, 0x00, 0x00, 0x0b, 0x80
	.byte 0xf2, 0x0b, 0x00, 0x00, 0x0b, 0xe8, 0x1a, 0x1d
	.byte 0x16, 0x05, 0xff, 0xf1, 0xe8, 0x1a, 0x30, 0xb8
	.byte 0x10, 0x00, 0x00, 0x38, 0xc2, 0xe3, 0xff, 0x00
	.byte 0x21, 0xc9, 0x61, 0xd8, 0x12, 0x28, 0x0b, 0xe2
	.byte 0x00, 0x0b, 0xf2, 0x00, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x50, 0x1c, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x18
	.byte 0x37, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x00
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x6d, 0x02
	.byte 0x1d, 0xe2, 0x91, 0xf8, 0xdb, 0x88, 0x1d, 0x16
	.byte 0x92, 0xf8, 0x3b, 0x1d, 0xe2, 0x91, 0xf8, 0xdb
	.byte 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b, 0xfc, 0x00
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x66, 0x1c, 0x1d, 0x95
	.byte 0x02, 0xff, 0xbf, 0x0e, 0x37, 0xf1, 0x73, 0x1c
	.byte 0x00, 0x00, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x01, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x34
	.byte 0x02, 0x1d, 0xba, 0x96, 0xf8, 0xdb, 0x88, 0x1d
	.byte 0xe3, 0x97, 0xf8, 0x3b, 0x1d, 0xba, 0x96, 0xf8
	.byte 0xdb, 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b, 0x08
	.byte 0x01, 0x0b, 0x00, 0x00, 0x0b, 0x74, 0x1c, 0x1d
	.byte 0x95, 0x02, 0xff, 0xbf, 0x0e, 0x37, 0xf1, 0x74
	.byte 0x1c, 0x30, 0xb8, 0x10, 0x00, 0x00, 0x1d, 0x90
	.byte 0x8e, 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x02, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0xf4
	.byte 0x01, 0x0b, 0x14, 0x00, 0x1d, 0xba, 0x96, 0xf8
	.byte 0xdb, 0x88, 0x1d, 0x72, 0x9c, 0xf8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x88, 0x1c, 0x1d, 0x16, 0x05
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x88, 0x1c, 0x30
	.byte 0xb8, 0x14, 0x00, 0x00, 0x32, 0x13, 0x00, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f, 0x20, 0x6e
	.byte 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca, 0x01, 0x00
	.byte 0x6a, 0xed, 0x1d, 0x90, 0x8e, 0xf8, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x03, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0xa8, 0x01, 0x1d, 0xc1, 0xa3
	.byte 0xf8, 0xdb, 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b
	.byte 0x10, 0x01, 0x0b, 0x00, 0x00, 0x0b, 0xc2, 0x1c
	.byte 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0a, 0x37, 0xf1
	.byte 0xc5, 0x1c, 0x00, 0x00, 0x40, 0xff, 0xff, 0xff
	.byte 0xff, 0x41, 0x06, 0x00, 0xc7, 0x01, 0xea, 0xa8
	.byte 0x78, 0x7a, 0x01, 0x0b, 0x0c, 0x00, 0x1d, 0xc1
	.byte 0xa3, 0xf8, 0xdb, 0x88, 0x1d, 0xae, 0xa7, 0xf8
	.byte 0x3b, 0x0b, 0x00, 0x00, 0x0b, 0x9e, 0x1c, 0x1d
	.byte 0x16, 0x05, 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x9e
	.byte 0x1c, 0x30, 0xb8, 0x0c, 0x00, 0x00, 0x32, 0x0b
	.byte 0x00, 0xf3, 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f
	.byte 0x20, 0x6e, 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca
	.byte 0x01, 0x00, 0x6a, 0xed, 0x1d, 0x90, 0x8e, 0xf8
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x05, 0x00
	.byte 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x2e, 0x01, 0x1d
	.byte 0xbb, 0xa0, 0xf8, 0xdb, 0x61, 0x2b, 0x0b, 0xe2
	.byte 0x00, 0x0b, 0x18, 0x01, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xc6, 0x1c, 0x1d, 0x95, 0x02, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xf1, 0xc9, 0x1c, 0x00, 0x00, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x08, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0x00, 0x01, 0x1d, 0xbb, 0xa0
	.byte 0xf8, 0xdb, 0x88, 0x1d, 0xe4, 0xa1, 0xf8, 0x3b
	.byte 0x0b, 0x00, 0x00, 0x0b, 0xac, 0x1c, 0x1d, 0x70
	.byte 0x07, 0xff, 0xef, 0x60, 0xf1, 0xac, 0x1c, 0x30
	.byte 0xb8, 0x14, 0x00, 0x00, 0x32, 0x13, 0x00, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f, 0x20, 0x6e
	.byte 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca, 0x01, 0x00
	.byte 0x6a, 0xed, 0x1d, 0x90, 0x8e, 0xf8, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x07, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0xb8, 0x00, 0x1d, 0xba, 0x96
	.byte 0xf8, 0xdb, 0x88, 0x1d, 0x72, 0x9c, 0xf8, 0x3b
	.byte 0x0b, 0x00, 0x00, 0x0b, 0xca, 0x1c, 0x1d, 0x70
	.byte 0x07, 0xff, 0x0b, 0x14, 0x00, 0x0b, 0x00, 0x00
	.byte 0x0b, 0xca, 0x1c, 0x0b, 0x02, 0x00, 0x0b, 0x4e
	.byte 0x10, 0x1d, 0x16, 0x05, 0xff, 0xbf, 0x12, 0x37
	.byte 0xf2, 0x4e, 0x10, 0x02, 0x30, 0xb8, 0x14, 0x00
	.byte 0x00, 0x32, 0x13, 0x00, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x81, 0x3f, 0x20, 0x6e, 0x09, 0xb1, 0x00
	.byte 0x00, 0xda, 0xca, 0x01, 0x00, 0x6a, 0xed, 0x1d
	.byte 0x90, 0x8e, 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff
	.byte 0x41, 0x0f, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x68
	.byte 0x5c, 0x1d, 0xba, 0x96, 0xf8, 0xdb, 0x88, 0x1d
	.byte 0x72, 0x9c, 0xf8, 0x3b, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xca, 0x1c, 0x1d, 0x70, 0x07, 0xff, 0x0b, 0x3b
	.byte 0x00, 0x0b, 0x00, 0x00, 0x0b, 0xca, 0x1c, 0x1d
	.byte 0x90, 0x06, 0xff, 0xbf, 0x0e, 0x37, 0xf2, 0x64
	.byte 0x10, 0x02, 0x30, 0xeb, 0xe3, 0x66, 0x16, 0xeb
	.byte 0x61, 0x0b, 0x1c, 0x00, 0x3b, 0x38, 0x1d, 0x16
	.byte 0x05, 0xff, 0xbf, 0x0a, 0x37, 0xf2, 0x80, 0x10
	.byte 0x02, 0x00, 0x00, 0x68, 0x03, 0xb0, 0x00, 0x00
	.byte 0x40, 0x64, 0x10, 0x02, 0x00, 0x1d, 0x90, 0x8e
	.byte 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x0e
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99
	.byte 0xfa
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
	.byte 0x1d, 0xab, 0xb7, 0xfe, 0xdb, 0x33, 0x00, 0xb0
	.byte 0xfe, 0x40, 0x06, 0x00, 0x72, 0x00, 0x41, 0x10
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99
	.byte 0xfa, 0x0b, 0x0c, 0x00, 0x1d, 0xba, 0x96, 0xf8
	.byte 0xdb, 0x88, 0x1d, 0xe3, 0x97, 0xf8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x1e, 0x1c, 0x1d, 0x16, 0x05
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x1e, 0x1c, 0x31
	.byte 0xb9, 0x0c, 0x00, 0x00, 0xd8, 0xa9, 0x1d, 0x7f
	.byte 0xb8, 0xfe, 0xdb, 0x88, 0xd8, 0xd8, 0xf2, 0xca
	.byte 0x07, 0xf2, 0xde, 0x1e, 0xa8, 0x11, 0xf1, 0x55
	.byte 0x11, 0x00, 0x00, 0x0e
CDlikeSwTtl_ShowDocTitle:
	.byte 0x1d, 0xab, 0xb7, 0xfe, 0xdb, 0x33, 0x00, 0xb0
	.byte 0xfe, 0x0b, 0x0c, 0x00, 0x1d, 0xc1, 0xa3, 0xf8
	.byte 0xdb, 0x88, 0x1d, 0x95, 0xa5, 0xf8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x2c, 0x1c, 0x1d, 0x16, 0x05
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x2c, 0x1c, 0x31
	.byte 0xb9, 0x0c, 0x00, 0x00, 0xd8, 0xaa, 0x1d, 0x7f
	.byte 0xb8, 0xfe, 0xdb, 0x88, 0xd8, 0xd8, 0xf2, 0xca
	.byte 0x07, 0xf2, 0xde, 0x1e, 0x64, 0x11, 0xf1, 0x55
	.byte 0x11, 0x00, 0x00, 0x0e
CDlikeSwTtl_ShowPdTitle:
	.byte 0x1d, 0xab, 0xb7, 0xfe, 0xdb, 0x33, 0x00, 0xb0
	.byte 0xfe, 0x0b, 0x14, 0x00, 0x1d, 0xbb, 0xa0, 0xf8
	.byte 0xdb, 0x88, 0x1d, 0xe4, 0xa1, 0xf8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x3a, 0x1c, 0x1d, 0x16, 0x05
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x3a, 0x1c, 0x31
	.byte 0xb9, 0x14, 0x00, 0x00, 0xd8, 0xac, 0x1d, 0x7f
	.byte 0xb8, 0xfe, 0xdb, 0x88, 0xd8, 0xd8, 0xf2, 0xca
	.byte 0x07, 0xf2, 0xde, 0x1e, 0x20, 0x11, 0xf1, 0x55
	.byte 0x11, 0x00, 0x00, 0x0e
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
	stdi8	(7498), 3
	jr	27
CDlikeSwTtl_SongConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	stdi8	(7498), 2
	jr	11
CDlikeSwTtl_SongConfirmDefault:
	stdi8 (7498), 1
	calr CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_SongConfirmJump:
	jp	16693796
CDlikeSwTtl_SongConfirmDispatch:
	ldb_d8 a, (7498)
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
	stdi8	(7498), 3
	jr	27
CDlikeSwTtl_DocConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	stdi8	(7498), 2
	jr	11
CDlikeSwTtl_DocConfirmDefault:
	stdi8 (7498), 1
	calr CDlikeSwTtl_ShowDocTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_DocConfirmJump:
	jp	16693796
CDlikeSwTtl_PdConfirmStart:
	call	16693163
	bit	1, hl
	jr	z, 7
	stdi8	(7498), 3
	jr	27
CDlikeSwTtl_PdConfirmBit0:
	call	16693163
	bit	0, hl
	jr	z, 7
	stdi8	(7498), 2
	jr	11
CDlikeSwTtl_PdConfirmDefault:
	stdi8 (7498), 1
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
	stib_da	(135304), 0
	stiw_da	(135302), 0
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
	stib_da	(135304), 0
	stiw_da	(135302), 0
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
	stib_da (0x021088), 0x00
	stiw_da (0x021086), 0x0000
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
	stiw_da	(135302), 0
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
	stiw_da	(135302), 0
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
	stiw_da (0x021086), 0x0000
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
	stiw_da	(135302), 0
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
	stiw_da	(135302), 0
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
	stiw_da (0x021086), 0x0000
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
	lda_24 xix, (DpDocTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpDocTtlFunc title dispatch
DpDocTtl_Dispatch:
	stiw_da	(135302), 0
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
	lda_24 xix, (DpDoc_CaseB)
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
	lda_24 xix, (DpPdTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpPdTtlFunc title dispatch
DpPdTtl_Dispatch:
	stiw_da	(135302), 0
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
	lda_24 xix, (DpPd_CaseB)
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
	lda_24 xix, (DpSmfTtl_Dispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DpSmfTtlFunc title dispatch
DpSmfTtl_Dispatch:
	.byte 0xc1, 0x9b, 0x8c, 0x3f, 0x72, 0x76, 0xff, 0x00
	.byte 0xf2, 0x88, 0x10, 0x02, 0x00, 0x00, 0xf2, 0x86
	.byte 0x10, 0x02, 0x02, 0x00, 0x00, 0x1e, 0x69, 0xf2
	.byte 0x1e, 0x85, 0xf1, 0x1e, 0x90, 0xf8, 0x78, 0xe6
	.byte 0x00, 0xc1, 0x9a, 0x8c, 0x3f, 0x72, 0x76, 0xde
	.byte 0x00, 0x1d, 0xab, 0xb7, 0xfe, 0xdb, 0x33, 0x00
	.byte 0x66, 0x17, 0x1e, 0xd1, 0x0a, 0x1d, 0x4d, 0xb9
	.byte 0xfe, 0x40, 0x26, 0x00, 0x6f, 0x00, 0x41, 0x09
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x1d, 0x4b, 0x99
	.byte 0xfa, 0x1e, 0x50, 0xef, 0x78, 0xb8, 0x00
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
	lda_24 xix, (DpSmf_CaseB)
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
	lda_24 xix, (DpSmfLyrTtl_Dispatch)
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
	lda_24 xix, (SqTrSelTtl_Dispatch)
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
