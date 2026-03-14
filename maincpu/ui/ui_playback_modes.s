; =============================================================================
; UI Playback Mode Handlers (3K lines)
; =============================================================================
;
; UI state event handling and playback mode control: voice parameter
; handlers, sequencer timer/tempo, part validation, play/song/medley
; mode dispatch, part format handlers, and display mode transitions.
; =============================================================================

UIStateEvt_VoiceParamHandler:
	.byte 0xc1, 0x36, 0x8d, 0x21, 0xc9, 0xcf, 0x8e, 0x66
	.byte 0x13, 0xc9, 0xcf, 0x64, 0x66, 0x0e, 0xc9, 0xcf
	.byte 0x6c, 0x61, 0x11, 0xc9, 0xcf, 0x7a, 0x62, 0x04
	.byte 0x1b, 0x10, 0x03, 0xf2, 0xf1, 0xea, 0x10, 0x00
	.byte 0x00, 0x78, 0xa4, 0x00, 0xc1, 0x7d, 0xc0, 0x21
	.byte 0xc9, 0xdb, 0xf2, 0xb4, 0x03, 0xf2, 0xde, 0xc1
	.byte 0x7e, 0xc0, 0x21, 0xc1, 0x7f, 0xc0, 0x20, 0xc8
	.byte 0xcf, 0xff, 0x6e, 0x08, 0xc1, 0xea, 0x10, 0x3c
	.byte 0xfe, 0x78, 0x84, 0x00, 0xc8, 0x33, 0x02, 0x6e
	.byte 0x02, 0x68, 0x7d, 0xf1, 0xea, 0x10, 0xc8, 0x66
	.byte 0x07, 0xc1, 0xea, 0x10, 0x3c, 0xfe, 0x68, 0x70
	.byte 0xc8, 0xc1, 0xc9, 0xcc, 0x04, 0xc9, 0x33, 0x02
	.byte 0x66, 0x35, 0x28, 0xc9, 0xd1, 0x1d, 0x54, 0x19
	.byte 0xf4, 0x48, 0x1d, 0x1b, 0x04, 0xf2, 0x1d, 0xb5
	.byte 0x03, 0xf2, 0x1d, 0xb9, 0x9a, 0xf5, 0x1d, 0x57
	.byte 0x24, 0xef, 0xf1, 0x31, 0x04, 0x00, 0x00, 0xc1
	.byte 0xb3, 0x28, 0x3e, 0x10, 0xf1, 0x9e, 0xf1, 0x02
	.byte 0x00, 0x00, 0xc1, 0xa5, 0x28, 0x3c, 0xfe, 0x21
	.byte 0x4c, 0x1d, 0x3d, 0x79, 0xfc, 0x68, 0x31, 0x28
	.byte 0xc9, 0xd1, 0x1d, 0xf2, 0x18, 0xf4, 0x48, 0x1d
	.byte 0x1b, 0x04, 0xf2, 0x1d, 0xb5, 0x03, 0xf2, 0x1d
	.byte 0xb9, 0x9a, 0xf5, 0x1d, 0x57, 0x24, 0xef, 0xf1
	.byte 0x31, 0x04, 0x00, 0x00, 0xc1, 0xb3, 0x28, 0x3e
	.byte 0x10, 0xf1, 0x9e, 0xf1, 0x02, 0x00, 0x00, 0xf1
	.byte 0xf4, 0x11, 0x00, 0x00, 0x1d, 0x03, 0xc9, 0xf3
	.byte 0x0e, 0x44, 0xa0, 0xf1, 0x00, 0x00, 0xd9, 0xd1
	.byte 0x23, 0x10, 0x21, 0x10, 0xc5, 0xf0, 0xf1, 0x66
	.byte 0x05, 0xd9, 0x1c, 0xf8, 0x68, 0x44, 0xd8, 0xd0
	.byte 0x21, 0x10, 0xd9, 0xa0, 0xc9, 0x8b, 0xc9, 0x8a
	.byte 0xd1, 0x9e, 0xf1, 0x26, 0xcb, 0x89, 0x11, 0xde
	.byte 0x2a, 0xca, 0x89
	.ascii "g-(CP"
	.byte 0xf2, 0x00, 0x00, 0x23, 0x03, 0xcb, 0x41, 0xd8
	.byte 0x8d, 0xf3, 0x07, 0xec, 0xf4, 0xcf, 0x66, 0x03
	.byte 0x48, 0x68, 0x03, 0x48, 0x68, 0x14, 0xc9, 0x61
	.byte 0xc9, 0x88, 0xf1, 0x56, 0x0d, 0x40, 0xc1, 0x54
	.byte 0x0d, 0x3e, 0x01, 0xc1, 0x7b, 0x28, 0x3e, 0x04
	.byte 0x68, 0x0c, 0xc1, 0x54, 0x0d, 0x3c, 0xfe, 0xc1
	.byte 0x7b, 0x28, 0x3c, 0xfb, 0xc8, 0xd0, 0x0e

SeqPlay_RestoreVoiceState_Return:
	ldda8 a, 10360
	pushw wa
	ld8_24 a, 0x00ffe3
	stda8 10360, a
	call SeqVoice_InitEntry
	popw wa
	stda8 10360, a
	ret

SeqTimer_PostTempoUpdate:
	ld xhl, 0xF460
	ld xwa, 0x2DA
	add xhl, xwa
	ld wa, (xhl + 8)
	pushw wa
	ldb e, 0x48
	ldb d, 0x8
	ldb w, 0xFF
	call SwbtWr_QueuePostEvent
	popw wa
	stda16 64610, xwa
	call SeqTimer_UpdateTempoReg
	ret

PlayMode_NullRet:
	ret
PlayMode_SetupAndDispatch:
	; --- Setup: load/store/call/set flag ---
	ldda16	wa, 61854
	stda16	10357, wa
	stdi8	3424, 0
	call AccWrap_PlayModeDispatch
	.byte 0xc1, 0xa7, 0x28, 0x3e, 0x04		; or (0x28A7), 0x04  [C1 prefix]
	ret
PlayMode_TeardownAndRestore:
	; --- Teardown: load/store/clear flags ---
	ldda16	wa, 10357
	stda16	61854, wa
	.byte 0xc1, 0xa7, 0x28, 0x3c, 0xfb		; and (0x28A7), 0xFB  [C1 prefix]
	.byte 0xc1, 0xb3, 0x28, 0x3e, 0x10		; or (0x28B3), 0x10  [C1 prefix]
	.byte 0xc1, 0xa7, 0x28, 0x3c, 0xf7		; and (0x28A7), 0xF7  [C1 prefix]
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
	ldb c, 0x0A
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0B:
	ldb c, 0x0B
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0C:
	ldb c, 0x0C
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0D:
	ldb c, 0x0D
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0E:
	ldb c, 0x0E
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0F:
	ldb c, 0x0F
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
Part_LookupParam:
	; --- Lookup function: load from table[IY], store ---
	ld xhl, 0x0000F1A0
	xor b, b
	ld iy, bc
	ld e, c
	.byte 0xc3, 0x07, 0xec, 0xf4, 0x21		; ld a, (xhl + iy)  [R+R addressing]
	stda8	3423, a
	inc 1, e
	stda8	3424, e
	ret
Part_ValidateAndActivate:
	; --- Validation: check range, optionally call ---
	stdi16	10367, 1
	stdi16	3383, 0
	.byte 0xc1, 0x60, 0x0d, 0x3f, 0x00		; cp (0x0D60), 0x00  [C1 prefix]
	jr z, PartValidate_Done
	.byte 0xc1, 0x60, 0x0d, 0x3f, 0x10		; cp (0x0D60), 0x10  [C1 prefix]
	jr ugt, PartValidate_Done
	stdi16	4360, 0
	xor	wa, wa
	ldb a, 0x8A
	call UI_PostModeChangeEvent
PartValidate_Done:
	ret
PlaybackDispatch_NullRet:
	ret


PlaybackMode_DispatchByType:
	bitda 0, 3381
	jrl z, DispatchHandler_ClearActiveFlag
	cpdi8 36150, 122
	jr z, PlaybackDisp_Type122_Play
	cpdi8 36150, 120
	jr z, PlaybackDisp_Type120_Play
	cpdi8 36150, 115
	jr z, PlaybackDisp_Type115_Stop
	cpdi8 36150, 118
	jr z, PlaybackDisp_Type118_Stop
	cpdi8 36150, 116
	jr z, PlaybackDisp_Type116_Song
	cpdi8 36150, 117
	jrl z, PlaybackDisp_Type117_PartFmt
	cpdi8 36150, 111
	jr z, PlaybackDisp_Type111_CDSong
	cpdi8 36150, 114
	jr z, PlaybackDisp_Type114_CDSong
	cpdi8 36150, 112
	jr z, PlaybackDisp_Type112_CDDoc
	cpdi8 36150, 113
	jrl z, PlaybackDisp_Type113_CDPd
	cpdi8 36150, 121
	jr z, Part_ValidateCallAndClear
	cpdi8 36150, 119
	jr z, Part_ValidateCallAndClear
	cpdi8 36150, 108
	jr z, Part_ValidateCallAndClear
	cpdi8 36150, 109
	jr z, Part_ValidateCallAndClear
	cpdi8 36150, 110
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
	.byte 0x1d, 0x3e, 0x06, 0xf2, 0x0e, 0xc1, 0x34, 0x0d
	.byte 0x3f, 0x00, 0x6e, 0x09, 0xf1, 0x34, 0x0d, 0x00
	.byte 0x01, 0x1d, 0x4f, 0x06, 0xf2, 0x0e, 0xc1, 0xac
	.byte 0x28, 0x3e, 0x04, 0xf1, 0x44, 0x11, 0x00, 0x0a
	.byte 0x0e

SongBank_ScanActiveVoices:
	xor bc, bc
	ld l, a
	extz hl
	mul hl, 0x800
	add xhl, 0xAB0D0
	ld xiy, xhl
	ldb b, 0x10
	cp_sriw_im 0xF5, 0x4E, 0xFF, 0x00, 0x00
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
	.byte 0xf1, 0x34, 0x0d, 0x00, 0x00, 0x0e

PlayMode_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, PlayMode_SendModeCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call PlayMode_DispatchAndClearBit2
	bitda 2, 3394
	jr z, PlayMode_SendModeCommand
	jr __jrt_nop_F206AA
__jrt_nop_F206AA:

PlayMode_SendModeCommand:
	stdi8 4437, 0
	cpdi8 36150, 122
	jr z, PlayCheck_PostMode79
	cpdi8 36150, 120
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
	anddi8 10412, 251
	ret

PlayMode_StartAndSendCommand:
	cpdi8 3380, 1
	jr nz, SongMode_PostEvtRetZero
	cpdi8 4420, 0
	jr nz, SongMode_PostEvtRetZero
	call PlayMode_DispatchAndClearBit2
	stdi8 4437, 1
	cpdi8 36150, 122
	jr z, PlayStart_PostMode79
	cpdi8 36150, 120
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
	bitda 2, 10412
	jr z, SeqRestart_Return
	ld iz, wa
	ldda8 a, 64607
	and a, 0x30
	ld wa, iz
	jr nz, SeqRestart_Return
	call AccWrap_PlayModeDispatch
	ldw bc, 0xF000

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
	bitda 2, 10412
	jr z, SeqNotify_Return
	stdi8 4437, 1
	cpdi8 36150, 122
	jr z, SeqNotify_PostMode79
	cpdi8 36150, 120
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
	.byte 0x0e, 0x0e, 0x1d, 0x7b, 0x07, 0xf2, 0x0e, 0xc1
	.byte 0x34, 0x0d, 0x3f, 0x00, 0x6e, 0x09, 0xf1, 0x34
	.byte 0x0d, 0x00, 0x01, 0x1d, 0x8c, 0x07, 0xf2, 0x0e
	.byte 0xc1, 0xac, 0x28, 0x3e, 0x04, 0xf1, 0x44, 0x11
	.byte 0x00, 0x0a, 0x0e, 0xf1, 0x34, 0x0d, 0x00, 0x00
	.byte 0x0e

SongMode_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, SongMode_SendStopCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call SongMode_AbortAndClearBit2
	bitda 2, 3394
	jr z, SongMode_SendStopCommand
	jr __jrt_nop_F207BA
__jrt_nop_F207BA:

SongMode_SendStopCommand:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6D
	call UI_PostModeChangeEvent
	ret

SongMode_AbortAndClearBit2:
	anddi8 10412, 251
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
	ldb a, 0x6D
	call UI_PostModeChangeEvent

SongMode_StartReturn:
	ret

SongMode_VoiceStateDisp:
	cp wa, 0xFFFF
	jr z, VoiceState_SetStatus2
	cp wa, 0xFFFE
	jr z, VoiceState_SetStatus3
	cp wa, 0xFFFC
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
	cpdi8 36150, 116
	jr z, PartFormat_PostMode6D
	cpdi8 36150, 112
	jrl z, VoiceState_SqTrSelCaseD
	cpdi8 36150, 117
	jr z, PartFormat_PostMode6E
	cpdi8 36150, 113
	jrl z, VoiceState_SqTrSelCaseF
	cpdi8 36150, 115
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 36150, 111
	jr z, VoiceState_SqTrSelCaseE
	cpdi8 36150, 118
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 36150, 114
	jr z, VoiceState_SqTrSelCaseE
	jp PartFormat_NullRet

PartFormat_PartTypeDisp:
	cpdi8 36150, 116
	jr z, PartFormat_PostMode6D
	cpdi8 36150, 112
	jr z, PartFormat_PostMode6D
	cpdi8 36150, 117
	jr z, PartFormat_PostMode6E
	cpdi8 36150, 113
	jr z, PartFormat_PostMode6E
	cpdi8 36150, 115
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 36150, 111
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 36150, 118
	jr z, PartFormat_SendPlaybackCmd
	cpdi8 36150, 114
	jr z, PartFormat_SendPlaybackCmd
	jp PartFormat_NullRet

PartFormat_PostMode6D:
	xor wa, wa
	ldb a, 0x6D
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_PostMode6E:
	xor wa, wa
	ldb a, 0x6E
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_SendPlaybackCmd:
	call PlayMode_SendStopEvent
	xor wa, wa
	ldb a, 0x6C
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
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0x1d, 0xe1, 0x08
	.byte 0xf2, 0x0e, 0xc1, 0x34, 0x0d, 0x3f, 0x00, 0x6e
	.byte 0x09, 0xf1, 0x34, 0x0d, 0x00, 0x01, 0x1d, 0xf2
	.byte 0x08, 0xf2, 0x0e, 0xc1, 0xac, 0x28, 0x3e, 0x04
	.byte 0xf1, 0x44, 0x11, 0x00, 0x0a, 0x0e, 0xf1, 0x34
	.byte 0x0d, 0x00, 0x00, 0x0e

PartFormat_CheckAndDispatch:
	cpdi8 3380, 1
	jr nz, PartFormat_SendStopCommand
	stdi8 3380, 0
	stdi8 4420, 0
	call PartFormat_AbortAndClearBit2
	bitda 2, 3394
	jr z, PartFormat_SendStopCommand
	jr __jrt_nop_F20920
__jrt_nop_F20920:

PartFormat_SendStopCommand:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6E
	call UI_PostModeChangeEvent
	ret

PartFormat_AbortAndClearBit2:
	anddi8 10412, 251
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
	ldb a, 0x6E
	call UI_PostModeChangeEvent

PartFormat_StartReturn:
	ret

PlayModeStop_InitFlagBlock:
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0xc1, 0x37, 0x8d, 0x3f
	.byte 0x76, 0x66, 0x04, 0x1d, 0x6a, 0x09, 0xf2, 0x0e
	.byte 0xc1, 0x34, 0x0d, 0x3f, 0x00, 0x6e, 0x09, 0xf1
	.byte 0x34, 0x0d, 0x00, 0x01, 0x1d, 0x7b, 0x09, 0xf2
	.byte 0x0e, 0xc1, 0xac, 0x28, 0x3e, 0x04, 0xf1, 0x44
	.byte 0x11, 0x00, 0x0a, 0x0e, 0xc1, 0x36, 0x8d, 0x3f
	.byte 0x6c, 0x6e, 0x05, 0xf1, 0x34, 0x0d, 0x00, 0x00
	.byte 0x0e

PlayMode_StopAbortRetZero:
	cpdi8 3380, 1
	jr nz, PlayModeStop_SendStopCmd
	stdi8 3380, 0
	stdi8 4420, 0
	call PlayMode_StopAndAbort
	bitda 2, 3394
	jr z, PlayModeStop_SendStopCmd
	jr __jrt_nop_F209B0
__jrt_nop_F209B0:

PlayModeStop_SendStopCmd:
	stdi8 4437, 0
	xor wa, wa
	ldb a, 0x6C
	call UI_PostModeChangeEvent
	ret

PlayMode_StopAndAbort:
	anddi8 10412, 251
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
	ldb a, 0x6C
	call UI_PostModeChangeEvent

PlayModeStop_SendReturn:
	ret

PlayModeStop_ClearFlagBlock:
	.byte 0x0e, 0x0e, 0x0e, 0x0e, 0x0e, 0xc1, 0x36, 0x8d
	.byte 0x3f, 0x6c, 0x6e, 0x05, 0xf1, 0x34, 0x0d, 0x00
	.byte 0x00, 0x0e

; SqSngNameTtlFunc title dispatch
SqSngNameTtl_Dispatch:
	xor wa, wa
	ldb a, 0x73
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	.byte 0x0e

CDlikeSwitch_PlaybackTimer:
	ldda8 w, 4420
	cps w, 0
	jr z, CDlikeTimer_Return
	dec 1, w
	cps w, 5
	jr nz, CDlikeTimer_CheckZeroCount
	cpdi8 36150, 122
	jr z, CDlikeTimer_ResetAccompaniment
	cpdi8 36150, 120
	jr z, CDlikeTimer_ResetAccompaniment
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ResetAccompaniment:
	pushw wa
	anddi8 10418, 249
	anddi8 10407, 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_CheckZeroCount:
	cps w, 0
	jr nz, CDlikeSwTtl_StorePlaybackMode
	cpdi8 36150, 122
	jr z, CDlikeTimer_InitResetState
	cpdi8 36150, 120
	jr z, CDlikeTimer_InitResetState
	cpdi8 36150, 116
	jr z, CDlikeTimer_ShowDocTitle
	cpdi8 36150, 117
	jr z, CDlikeTimer_ShowPdTitle
	cpdi8 36150, 115
	jr z, CDlikeTimer_ShowSongTitle
	cpdi8 36150, 118
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
	bitda 1, 10407
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
	ordi8 47074, 64
	ldda8 a, 64941
	stda8 3394, a
	stdi8 3380, 0
	stdi8 4420, 0
	call CDlike_LoadSongBankData
	cpdi8 36150, 119
	jr z, CDlikeSw_NullRet
	cpdi8 36150, 120
	jr z, CDlikeSw_NullRet
	cpdi8 36150, 121
	jr z, CDlikeSw_NullRet
	cpdi8 36150, 122
	jr z, CDlikeSw_NullRet
	call SqTrAs_InitWall
	ldda16 xwa, 61854
	stda16 10357, xwa
	stdi16 61854, 0
	stdi16 8980, 0
	ld xiy, 0xF9A0
	ld xix, 0x3CF04
	ldw bc, 0x310
	ldirw

CDlikeSw_NullRet:
	ret

CDlike_LoadSongBankData:
	stdi8 6882, 0
	cpdi16 61854, 0
	jr nz, CDlikeBankLoad_CheckSavedState
	stdi8 6882, 1

CDlikeBankLoad_CheckSavedState:
	ld16_24 xwa, 0x00ffec
	stda16 61854, xwa
	ld xiy, 0xF180
	ld xix, 0xAB000
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	add xix, xwa
	ldw bc, 0x800
	ldir85
	cpdi8 6882, 1
	jr nz, CDlikeBankLoad_Return
	stdi16 61854, 0

CDlikeBankLoad_Return:
	ret

CDlike_ExitModeAndRestore:
	call PlayMode_CheckAndAbort
	anddi8 47074, 191
	anddi8 10412, 251
	stdi8 4420, 0
	bitda 2, 3394
	jr z, CDlikeExit_CheckPlaybackType
	jr __jrt_nop_F20B8B
__jrt_nop_F20B8B:

CDlikeExit_CheckPlaybackType:
	cpdi8 36151, 119
	jr z, PlayMode_ResetAndSchedule
	cpdi8 36151, 120
	jr z, PlayMode_ResetAndSchedule
	cpdi8 36151, 121
	jr z, PlayMode_ResetAndSchedule
	cpdi8 36151, 122
	jr z, PlayMode_ResetAndSchedule
	stdi8 4330, 1
	call ToneGen_FileIO_RestoreFromBackup
	call SeqTimer_UpdateTempoReg
	call SwbtWr_ResetAllChannels
	call SqTrAs_Setup
	ldda16 xwa, 10357
	stda16 61854, xwa

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
	ldda16 xwa, 61999
	stda16 10351, xwa
	ldda16 xwa, 62001
	stda16 10353, xwa
	call SongBank_LoadToWorkArea
	call SongBank_CheckAccompanimentMode
	anddi8 10417, 254
	ret

SongBank_LoadToWorkArea:
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	ld xiy, 0xAB000
	add xiy, xwa
	ld xix, 0xF180
	ldw bc, 0x800
	ldir85
	ldda16 xwa, 61854
	st16_24 0x00ffec, xwa
	ldda16 xwa, 10351
	stda16 61999, xwa
	ldda16 xwa, 10353
	stda16 62001, xwa
	ret

SongBank_CheckAccompanimentMode:
	cpdi8 62013, 255
	jr z, SongBank_EnableAccompaniment
	bitda 2, 64941
	jr z, SongBank_CheckBassMode
	anddi8 64941, 251
	xor a, a
	jr SongBank_SendAccompEvent

SongBank_EnableAccompaniment:
	bitda 2, 64941
	jr nz, SongBank_CheckBassMode
	ordi8 64941, 4
	ldb a, 0x4

SongBank_SendAccompEvent:
	stdi8 4330, 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks

SongBank_CheckBassMode:
	cpdi8 62027, 255
	jr z, SongBank_EnableBassMode
	anddi8 64941, 254
	xor a, a
	jr SongBank_SendBassEvent

SongBank_EnableBassMode:
	ordi8 64941, 1
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
	ld xiy, 0xCCE
	ld xix, 0xF1A0
	xor bc, bc
	ldb c, 0x10
	ldir85
	ret

; SqTrAs init wall data
SqTrAs_InitWall:
	ld xix, 0xCCE
	ld xiy, 0xF1A0
	xor bc, bc
	ldb c, 0x10
	ldir85
	ret

; SqTrAs load inline code
SqTrAs_LoadInline:
	.byte 0x0e

SqAftSetTtlFunc:
	lds32 xhl, 0
	ret

SqSngSelTtlFunc:
	cp xbc, 0x1C00013
	jr nz, SqSngName_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqSngName_ReturnZero
	cp xde, 0x5
	jr ugt, SqSngName_ReturnZero
	add xde, xde
	add xde, 0xE1FFFA
	ld de, (xde)
	lda_24 xix, 0xf20cec
	jp_dri 8, 0x07, 0xF0, 0xE8

; SqTrAs conditional voice check
SqTrAs_CondCheck:
	.ascii ":;<>"
	.byte 0x1d, 0x87, 0x00, 0xf2
	.ascii "^\\[Zh"
	.byte 0x0c, 0x3a, 0x3b
	.byte 0x3c, 0x3e, 0x1d, 0xc6, 0x00, 0xf2, 0x5e, 0x5c
	.byte 0x5b, 0x5a

SqSngName_ReturnZero:
	lds32 xhl, 0
	ret

SqSngNameTtlFunc:
	cp xbc, 0x1C00013
	jr nz, SqTrAs_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrAs_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrAs_ReturnZero
	add xde, xde
	add xde, 0xE20006
	ld de, (xde)
	lda_24 xix, 0xf20d37
	jp_dri 8, 0x07, 0xF0, 0xE8

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
	cp xbc, 0x1C00007
	jrl z, SqTrAs_EventHandler
	cp xbc, 0x1C00013
	jrl nz, CDlikeSwTtl_ReturnZero2
	dec 2, xde
	cp xde, 0x0
	jrl c, CDlikeSwTtl_ReturnZero2
	cp xde, 0x5
	jrl ugt, CDlikeSwTtl_ReturnZero2
	add xde, xde
	add xde, 0xE20012
	ld de, (xde)
	lda_24 xix, 0xf20d8e
	jp_dri 8, 0x07, 0xF0, 0xE8
; Sequencer track dispatch table 2 - SqTrAsTtlFunc handler
; 6 dispatch cases (XDE 0-5)
SQTR_DISPATCH_TABLE_2:
	ld xwa, 0x8B0004
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0002
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
	setda 0, 36700	; F20DAD: LD (XIX+5Ch), 0B8h (TMP94C241 encoding)
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
	resda 0, 36700	; F20DCD: LD (XIX+5Ch), 0B0h (TMP94C241 encoding)
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit
	jr CDlikeSwTtl_ReturnZero2
SQTR_DISPATCH_TABLE_2_CASE2:
	cpdi8 36150, 139
	jr nz, CDlikeSwTtl_ReturnZero2
	cpdi8 32578, 35
	scc16 z, bc
	cpdi8 36153, 238
	scc16 z, wa
	and wa, bc
	jr z, SQTR_DISPATCH_TABLE_2_CASE5
	ld xwa, 0x8B0004
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0002
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
	cp xde, 0xB
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
	cp xbc, 0x1C00007
	jr nz, SqTrAsPs_ReturnZero
	cp xde, 0xF
	jr z, SqTrAsPsTtl_CaseB
	cp xde, 0xB
	jr z, SqTrAsPsTtl_CaseA
	cp xde, 0xA
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
	cp xbc, 0x1C00007
	jr z, SqTrAsPsTtl_CaseD
	cp xbc, 0x1C00013
	jrl nz, SqTrAsPsTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrAsPsTtl_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrAsPsTtl_ReturnZero
	add xde, xde
	add xde, 0xE2001E
	ld de, (xde)
	lda_24 xix, 0xf20ebd
	jp_dri 8, 0x07, 0xF0, 0xE8
SqTrAsPsTtl_Dispatch:	.ascii ":;<>"
	call	15855868
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 9175044
	ld	xbc, 31457357
	lds32	xde, 1
	call	16424280
	ld	xwa, 9175045
	ld	xbc, 31457357
	lds32	xde, 0
	call	16424280
	ld	xwa, 9175046
	ld	xbc, 31457357
	lds32	xde, 0
	call	16424280
	.ascii "h\":;<>"
	.byte 0x1d, 0x0b, 0xf1, 0xf1, 0x5e, 0x5c
	.byte 0x5b, 0x5a, 0x68, 0x14

; SqTrAsPsTtl case D
SqTrAsPsTtl_CaseD:
	cp xde, 0xB
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
	cp xbc, 0x1C00007
	jr nz, SetWall_ReturnZero
	cp xde, 0xB
	jr z, SqTrAsPsTtl_CaseE
	cp xde, 0xA
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
	.byte 0xc1, 0x36, 0x8d, 0x21, 0xd8, 0x12, 0xd8, 0xca
	.byte 0x6c, 0x00, 0xd8, 0xd8, 0x61, 0x29, 0xd8, 0xcf
	.byte 0x0d, 0x00, 0x6a, 0x23, 0xf2, 0x2a, 0x00, 0xe2
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xd8, 0x12
	.byte 0xd8, 0xee, 0x01, 0x44, 0x38, 0x00, 0xe2, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0x8c, 0x0f
	.byte 0xf2, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0x3a
	.byte 0x3b, 0x3c, 0x3e, 0x1d, 0x70, 0x0b, 0xf2, 0x5e
	.byte 0x5c, 0x5b, 0x5a, 0x0e

SqMdlyPlyTtlFunc:
	cp xbc, 0x1C00007
	jr z, SqMdlyPly_InitPlay
	cp xbc, 0x1C00013
	jrl nz, SqMdlyPly_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqMdlyPly_ReturnZero
	cp xde, 0x5
	jr ugt, SqMdlyPly_ReturnZero
	add xde, xde
	add xde, 0xE2003C
	ld de, (xde)
	lda_24 xix, 0xf20fd0
	jp_dri 8, 0x07, 0xF0, 0xE8
SqMdlyPlyTtl_Dispatch:	.ascii ":;<>"
	.byte 0x1d, 0x39, 0x06, 0xf2
	.ascii "^\\[ZhL:;<>"
	.byte 0x1d, 0x87, 0x06, 0xf2, 0x5e, 0x5c
	.byte 0x5b, 0x5a, 0x1e, 0x68, 0xff, 0x68, 0x3b

; SqMdlyPly init playback
SqMdlyPly_InitPlay:
	cp xde, 0xF
	jr z, SqMdlyPly_CheckState
	cp xde, 0x8A
	jr z, SqMdlyPly_SendAudioCmd
	cp xde, 0xA
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
	ldw wa, 0xA5
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
	cp xbc, 0x1C00007
	jr z, DkMdlyPly_InitPlay
	cp xbc, 0x1C00013
	jrl nz, DkMdlyPly_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, DkMdlyPly_ReturnZero
	cp xde, 0x5
	jr ugt, DkMdlyPly_ReturnZero
	add xde, xde
	add xde, 0xE20048
	ld de, (xde)
	lda_24 xix, 0xf21064
	jp_dri 8, 0x07, 0xF0, 0xE8
DkMdlyPlyTtl_Dispatch:	.ascii ":;<>"
	.byte 0x1d, 0x39, 0x06, 0xf2
	.ascii "^\\[ZhL:;<>"
	.byte 0x1d, 0x87, 0x06, 0xf2, 0x5e, 0x5c
	.byte 0x5b, 0x5a, 0x1e, 0xd4, 0xfe, 0x68, 0x3b

; DkMdlyPly init playback
DkMdlyPly_InitPlay:
	cp xde, 0xF
	jr z, DkMdlyPly_CheckPlayState
	cp xde, 0x8A
	jr z, DkMdlyPly_SendAudioA5
	cp xde, 0xA
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
	ldw wa, 0xA5
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
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
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
	ldda8 a, 36150
	cp a, 0x6F
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x72
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x73
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x76
	jr nz, DkMdlyPly_Finalize

Snd_ParamLookupSetupWerp:
	ldi_werp 0xFA, 0

; DkMdlyPly handle result
DkMdlyPly_HandleResult:
	ldto_werp WA, 0xFA
	add wa, wa
	lda_24 xbc, 0xe20074
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	ldw bc, 0x401
	call SndParam_LookupViaEncode
	ld iz, hl
	ld wa, (xsp + 4)
	calr DkMdlyPly_SendAudioCmd
	cp hl, iz
	jr nz, DkMdlyPly_ExtendedCheck
	ldto_werp WA, 0xFA
	add wa, wa
	lda_24 xbc, 0xe20074
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	stda8 36154, a
	ld e, a
	extz de
	pushw 0xFF
	ldw wa, 0x90
	ldw bc, 0x10
	call AddswbWr
	call AudioMode_ResetVoiceState
	jr DkMdlyPly_Finalize

; DkMdlyPly extended check
DkMdlyPly_ExtendedCheck:
	inc1_werp 0xFA
	cp_erpw 0xFA, 0x20, 0x00
	jr lt, DkMdlyPly_HandleResult

; DkMdlyPly finalize
DkMdlyPly_Finalize:
	pop xiz
	inc 2, xsp
	ret

DisplayMode_DispatchEvents:
	ldda8 a, 36150
	extz wa
	sub wa, 0x6F
	cps wa, 0
	ret lt
	cps wa, 6
	ret gt
	add wa, wa
	lda_24 xix, 0xe200b4
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf21181
	jp_dri 8, 0x07, 0xF0, 0xE0

; --- DisplayMode_BatchEventSend: Dispatch events for display mode transitions ---
; Multiple entry points, each dispatching 2-3 events for a specific mode.
; Pattern per entry: XWA=event_id, XBC=0x1E0043B (target), XDE=0 (param),
;   then call EventDispatch (0xFAC558) or jump to common tail.
; Event IDs encode mode/sub-function: 0x6F000A, 0x70000x, 0x73000C, etc.
DisplayMode_BatchEventSend:
	ld	xwa, 7274506
	ld	xbc, 31457339
	lds32	xde, 0
	jrl	165
	ld	xwa, 7536652
	ld	xbc, 31457339
	lds32	xde, 0
	jrl	150
	ld	xwa, 7340039
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7340040
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7340041
	ld	xbc, 31457339
	lds32	xde, 0
	jr	104
	ld	xwa, 7602186
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7602187
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7602188
	ld	xbc, 31457339
	lds32	xde, 0
	jr	58
	ld	xwa, 7405575
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7405576
	ld	xbc, 31457339
	lds32	xde, 0
	jr	28
	ld	xwa, 7667721
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	ld	xwa, 7667722
	ld	xbc, 31457339
	lds32	xde, 0
	call	16424280
	.byte 0x0e

DisplayMode_RefreshState:
	ld16_24 xwa, 0x021086
	calr DkMdlyPly_CheckState
	ld16_24 xwa, 0x021086
	jp FileIO_ReadChunk

DpMdlyDocTtlFunc:
	cp xbc, 0x1C00007
	jr z, DpMdlyDoc_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpMdlyDoc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlyDoc_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlyDoc_ReturnZero
	add xde, xde
	add xde, 0xE200C2
	ld de, (xde)
	lda_24 xix, 0xf21284
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpMdlyDocTtlFunc title dispatch
DpMdlyDocTtl_Dispatch:
	sti16_24	135302, 0
	calr	65452
	calr	65224
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15861622
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	.byte 0x1d
	.byte 0x97, 0x07, 0xf2
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0x1e
	.byte 0xa7, 0xfc, 0x68, 0x48

; DpMdlyDoc case A
DpMdlyDoc_CaseA:
	cp xde, 0xF
	jr z, DpMdlyDoc_CaseE
	cp xde, 0x8C
	jr z, DpMdlyDoc_CaseD
	cp xde, 0x89
	jr z, DpMdlyDoc_CaseB
	cp xde, 0x8A
	jr nz, DpMdlyDoc_ReturnZero
	ldw wa, 0xA5
	jr DpMdlyDoc_CaseC

; DpMdlyDoc case B
DpMdlyDoc_CaseB:
	ldw wa, 0xD6

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
	cp xbc, 0x1C00007
	jr z, DpMdlyPd_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpMdlyPd_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlyPd_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlyPd_ReturnZero
	add xde, xde
	add xde, 0xE200CE
	ld de, (xde)
	lda_24 xix, 0xf21334
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpMdlyPdTtlFunc title dispatch
DpMdlyPdTtl_Dispatch:
	sti16_24	135302, 0
	calr	65276
	calr	65048
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15861980
	pop	xiz
	pop	xix
	pop	xhl
	.ascii "ZhY:;<>"
	.byte 0x1d
	.byte 0xfd, 0x08, 0xf2
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0x1e
	.byte 0xf7, 0xfb, 0x68, 0x48

; DpMdlyPd case A
DpMdlyPd_CaseA:
	cp xde, 0xF
	jr z, DpMdlyPd_CaseE
	cp xde, 0x8C
	jr z, DpMdlyPd_CaseD
	cp xde, 0x89
	jr z, DpMdlyPd_CaseB
	cp xde, 0x8A
	jr nz, DpMdlyPd_ReturnZero
	ldw wa, 0xA5
	jr DpMdlyPd_CaseC

; DpMdlyPd case B
DpMdlyPd_CaseB:
	ldw wa, 0xD6

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
	cp xbc, 0x1C00007
	jr z, DpMdlySmf_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpMdlySmf_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlySmf_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlySmf_ReturnZero
	add xde, xde
	add xde, 0xE200DA
	ld de, (xde)
	lda_24 xix, 0xf213e4
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpMdlySmfTtlFunc title dispatch
DpMdlySmfTtl_Dispatch:
	.byte 0xc1, 0x37, 0x8d, 0x3f, 0x76, 0x66, 0x13, 0xf2
	.byte 0x88, 0x10, 0x02, 0x00, 0x00, 0xf2, 0x86, 0x10
	.byte 0x02, 0x02, 0x00, 0x00, 0x1e, 0x3f, 0xfe, 0x1e
	.byte 0x5b, 0xfd
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0x5e
	.byte 0x09, 0xf2
	.ascii "^\\[ZhY:;<>"
	.byte 0x1d, 0x86, 0x09, 0xf2
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	.byte 0x1e, 0x3a, 0xfb, 0x68
	.byte 0x48

; DpMdlySmf case A
DpMdlySmf_CaseA:
	cp xde, 0xF
	jr z, DpMdlySmf_CaseE
	cp xde, 0x8C
	jr z, DpMdlySmf_CaseD
	cp xde, 0x89
	jr z, DpMdlySmf_CaseB
	cp xde, 0x8A
	jr nz, DpMdlySmf_ReturnZero
	ldw wa, 0xA5
	jr DpMdlySmf_CaseC

; DpMdlySmf case B
DpMdlySmf_CaseB:
	ldw wa, 0xD6

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
	cp xbc, 0x1C00007
	jrl z, DpMdlySmfLyr_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpMdlySmfLyr_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpMdlySmfLyr_ReturnZero
	cp xde, 0x5
	jrl ugt, DpMdlySmfLyr_ReturnZero
	add xde, xde
	add xde, 0xE200E6
	ld de, (xde)
	lda_24 xix, 0xf214a2
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpMdlySmfLyrTtlFunc title dispatch
DpMdlySmfLyrTtl_Dispatch:
	.byte 0xc1, 0x37, 0x8d, 0x21, 0xc9, 0xcf, 0x6c, 0x6e
	.byte 0x26, 0xc9, 0xcf, 0x76, 0x66, 0x13, 0xf2, 0x88
	.byte 0x10, 0x02, 0x00, 0x00, 0xf2, 0x86, 0x10, 0x02
	.byte 0x02, 0x00, 0x00, 0x1e, 0x7a, 0xfd, 0x1e, 0x96
	.byte 0xfc
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0x5e, 0x09
	.byte 0xf2
	.ascii "^\\[Zh"
	.byte 0x0c, 0x3a
	.byte 0x3b, 0x3c, 0x3e, 0x1d, 0xf2, 0x09, 0xf2
	aligned_string "^\\[Z@&"
	jr	nc, 0x00
	.byte 0x41, 0x0a, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x68
	.byte 0x1d
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d, 0xf3, 0x09
	.byte 0xf2
	.byte 0x5e, 0x5c, 0x5b, 0x5a
	calr	0xfa5b
	.asciz "hM@&"
	jr	nc, 0
	ld	xbc, 29818890
	lds32	xde, 0
	call	16424280
	jr	59

; DpMdlySmfLyr case A
DpMdlySmfLyr_CaseA:
	cp xde, 0xF
	jr z, DpMdlySmfLyr_CaseC
	cp xde, 0x8C
	jr z, DpMdlySmfLyr_CaseB
	cp xde, 0x88
	jr nz, DpMdlySmfLyr_ReturnZero
	ldw wa, 0xD6
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
	sub xbc, 0x1E7000D
	cp xbc, 0x0
	jrl lt, NameGetFunc_Entry
	cp xbc, 0xD
	jrl gt, NameGetFunc_Entry
	add xbc, xbc
	add xbc, 0xE20120
	ld bc, (xbc)
	lda_24 xix, 0xf21578
	jp_dri 8, 0x07, 0xF0, 0xE4
; NameGetFuncCall dispatch
NameGetFuncCall_Dispatch:
	.byte 0x0b, 0x10, 0x00, 0x0b, 0x00, 0x00, 0x0b, 0x80
	.byte 0xf2, 0x0b, 0x00, 0x00, 0x0b, 0xe8, 0x1a, 0x1d
	.byte 0xf3, 0x0c, 0xff, 0xf1, 0xe8, 0x1a, 0x30, 0xb8
	.byte 0x10, 0x00, 0x00, 0x38, 0xc2, 0xe3, 0xff, 0x00
	.byte 0x21, 0xc9, 0x61, 0xd8, 0x12, 0x28, 0x0b, 0xe2
	.byte 0x00, 0x0b, 0xf2, 0x00, 0x0b, 0x00, 0x00, 0x0b
	.byte 0x50, 0x1c, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x18
	.byte 0x37, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x00
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x6d, 0x02
	.byte 0x1d, 0xef, 0x95, 0xf8, 0xdb, 0x88, 0x1d, 0x23
	.byte 0x96, 0xf8, 0x3b, 0x1d, 0xef, 0x95, 0xf8, 0xdb
	.byte 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b, 0xfc, 0x00
	.byte 0x0b, 0x00, 0x00, 0x0b, 0x66, 0x1c, 0x1d, 0x72
	.byte 0x0a, 0xff, 0xbf, 0x0e, 0x37, 0xf1, 0x73, 0x1c
	.byte 0x00, 0x00, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x01, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x34
	.byte 0x02, 0x1d, 0xc7, 0x9a, 0xf8, 0xdb, 0x88, 0x1d
	.byte 0xf0, 0x9b, 0xf8, 0x3b, 0x1d, 0xc7, 0x9a, 0xf8
	.byte 0xdb, 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b, 0x08
	.byte 0x01, 0x0b, 0x00, 0x00, 0x0b, 0x74, 0x1c, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0e, 0x37, 0xf1, 0x74
	.byte 0x1c, 0x30, 0xb8, 0x10, 0x00, 0x00, 0x1d, 0x9d
	.byte 0x92, 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x02, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x78, 0xf4
	.byte 0x01, 0x0b, 0x14, 0x00, 0x1d, 0xc7, 0x9a, 0xf8
	.byte 0xdb, 0x88, 0x1d, 0x7f, 0xa0, 0xf8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0x88, 0x1c, 0x1d, 0xf3, 0x0c
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x88, 0x1c, 0x30
	.byte 0xb8, 0x14, 0x00, 0x00, 0x32, 0x13, 0x00, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f, 0x20, 0x6e
	.byte 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca, 0x01, 0x00
	.byte 0x6a, 0xed, 0x1d, 0x9d, 0x92, 0xf8, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x03, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0xa8, 0x01, 0x1d, 0xce, 0xa7
	.byte 0xf8, 0xdb, 0x61, 0x2b, 0x0b, 0xe2, 0x00, 0x0b
	.byte 0x10, 0x01, 0x0b, 0x00, 0x00, 0x0b, 0xc2, 0x1c
	.byte 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0xf1
	.byte 0xc5, 0x1c, 0x00, 0x00, 0x40, 0xff, 0xff, 0xff
	.byte 0xff, 0x41, 0x06, 0x00, 0xc7, 0x01, 0xea, 0xa8
	.byte 0x78, 0x7a, 0x01, 0x0b, 0x0c, 0x00, 0x1d, 0xce
	.byte 0xa7, 0xf8, 0xdb, 0x88, 0x1d, 0xbb, 0xab, 0xf8
	.byte 0x3b, 0x0b, 0x00, 0x00, 0x0b, 0x9e, 0x1c, 0x1d
	.byte 0xf3, 0x0c, 0xff, 0xbf, 0x0a, 0x37, 0xf1, 0x9e
	.byte 0x1c, 0x30, 0xb8, 0x0c, 0x00, 0x00, 0x32, 0x0b
	.byte 0x00, 0xf3, 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f
	.byte 0x20, 0x6e, 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca
	.byte 0x01, 0x00, 0x6a, 0xed, 0x1d, 0x9d, 0x92, 0xf8
	.byte 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x05, 0x00
	.byte 0xc7, 0x01, 0xea, 0xa8, 0x78, 0x2e, 0x01, 0x1d
	.byte 0xc8, 0xa4, 0xf8, 0xdb, 0x61, 0x2b, 0x0b, 0xe2
	.byte 0x00, 0x0b, 0x18, 0x01, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xc6, 0x1c, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0xf1, 0xc9, 0x1c, 0x00, 0x00, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x08, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0x00, 0x01, 0x1d, 0xc8, 0xa4
	.byte 0xf8, 0xdb, 0x88, 0x1d, 0xf1, 0xa5, 0xf8, 0x3b
	.byte 0x0b, 0x00, 0x00, 0x0b, 0xac, 0x1c, 0x1d, 0x4d
	.byte 0x0f, 0xff, 0xef, 0x60, 0xf1, 0xac, 0x1c, 0x30
	.byte 0xb8, 0x14, 0x00, 0x00, 0x32, 0x13, 0x00, 0xf3
	.byte 0x07, 0xe0, 0xe8, 0x31, 0x81, 0x3f, 0x20, 0x6e
	.byte 0x09, 0xb1, 0x00, 0x00, 0xda, 0xca, 0x01, 0x00
	.byte 0x6a, 0xed, 0x1d, 0x9d, 0x92, 0xf8, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x07, 0x00, 0xc7, 0x01
	.byte 0xea, 0xa8, 0x78, 0xb8, 0x00, 0x1d, 0xc7, 0x9a
	.byte 0xf8, 0xdb, 0x88, 0x1d, 0x7f, 0xa0, 0xf8, 0x3b
	.byte 0x0b, 0x00, 0x00, 0x0b, 0xca, 0x1c, 0x1d, 0x4d
	.byte 0x0f, 0xff, 0x0b, 0x14, 0x00, 0x0b, 0x00, 0x00
	.byte 0x0b, 0xca, 0x1c, 0x0b, 0x02, 0x00, 0x0b, 0x4e
	.byte 0x10, 0x1d, 0xf3, 0x0c, 0xff, 0xbf, 0x12, 0x37
	.byte 0xf2, 0x4e, 0x10, 0x02, 0x30, 0xb8, 0x14, 0x00
	.byte 0x00, 0x32, 0x13, 0x00, 0xf3, 0x07, 0xe0, 0xe8
	.byte 0x31, 0x81, 0x3f, 0x20, 0x6e, 0x09, 0xb1, 0x00
	.byte 0x00, 0xda, 0xca, 0x01, 0x00, 0x6a, 0xed, 0x1d
	.byte 0x9d, 0x92, 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff
	.byte 0x41, 0x0f, 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x68
	.byte 0x5c, 0x1d, 0xc7, 0x9a, 0xf8, 0xdb, 0x88, 0x1d
	.byte 0x7f, 0xa0, 0xf8, 0x3b, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xca, 0x1c, 0x1d, 0x4d, 0x0f, 0xff, 0x0b, 0x3b
	.byte 0x00, 0x0b, 0x00, 0x00, 0x0b, 0xca, 0x1c, 0x1d
	.byte 0x6d, 0x0e, 0xff, 0xbf, 0x0e, 0x37, 0xf2, 0x64
	.byte 0x10, 0x02, 0x30, 0xeb, 0xe3, 0x66, 0x16, 0xeb
	.byte 0x61, 0x0b, 0x1c, 0x00, 0x3b, 0x38, 0x1d, 0xf3
	.byte 0x0c, 0xff, 0xbf, 0x0a, 0x37, 0xf2, 0x80, 0x10
	.byte 0x02, 0x00, 0x00, 0x68, 0x03, 0xb0, 0x00, 0x00
	.byte 0x40, 0x64, 0x10, 0x02, 0x00, 0x1d, 0x9d, 0x92
	.byte 0xf8, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41, 0x0e
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x1d, 0x58, 0x9d
	.byte 0xfa

; NameGetFuncCall entry handler
NameGetFunc_Entry:
	lds32 xhl, 0
	ret

CDlikeSwTtlFunc:
	cp xbc, 0x1C00007
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
	ld xbc, 0x1C70010
	lds32 xde, 0
	call ApPostEvent
	pushw 0xC
	call GetFirstPageBase
	ld wa, hl
	call GetRecordPtrForFile
	push xhl
	pushw 0x0
	pushw 0x1C1E
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7198
	ld (xbc + 12), 0x0
	lds wa, 1
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, 0xF207F4
	calr SeqRecPlay_EnableRecordOnly
	stdi8 4437, 0
	ret

CDlikeSwTtl_ShowDocTitle:
	call SeqState_GetFlags
	bit 0, hl
	ret nz
	pushw 0xC
	call FileIO_GetCurrentFileIndex_Alt
	ld wa, hl
	call FileIO_GetFileEntryByIndex
	push xhl
	pushw 0x0
	pushw 0x1C2C
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7212
	ld (xbc + 12), 0x0
	lds wa, 2
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, 0xF207F4
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
	pushw 0x1C3A
	call Strncpy
	lda xsp, (xsp + 10)
	ldada xbc, 7226
	ld (xbc + 20), 0x0
	lds wa, 4
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cps wa, 0
	jp_24 nz, 0xF207F4
	calr SeqRecPlay_EnableRecordOnly
	stdi8 4437, 0
	ret

CDlikeSwTtl_SongBit1Check:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_SongBit0Check
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	jr CDlikeSwTtl_JumpToFA9D58

CDlikeSwTtl_SongBit0Check:
	call SeqState_GetFlags
	bit 0, hl
	jrl z, CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
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
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7000F
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7001A
	lds32 xde, 0
	jr CDlikeSwTtl_SongNavFinishNames

CDlikeSwTtl_SongNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_SongNavNoRedraw
	call Song_AbortPlayback
	ld xwa, 0x6F0026
	ld xbc, 0x1C70009
	lds32 xde, 0
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7000F
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7001A
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7000F
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70010
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70019
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E7001A
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70012
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70012
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70013
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70012
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70014
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70014
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70015
	lds32 xde, 0
	calr NameGetFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E70014
	lds32 xde, 0
	calr NameGetFuncCall

CDlikeSwTtl_PdNavReturn:
	popw iz
	ret

DpDocTtlFunc:
	cp xbc, 0x1C00009
	jrl z, DpDoc_CaseI
	cp xbc, 0x1C00008
	jrl z, DpDoc_CaseG
	cp xbc, 0x1C00007
	jr z, DpDoc_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpDocTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpDocTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpDocTtl_ReturnZero
	add xde, xde
	add xde, 0xE20150
	ld de, (xde)
	lda_24 xix, 0xf21d5a
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpDocTtlFunc title dispatch
DpDocTtl_Dispatch:
	.byte 0xf2, 0x86, 0x10, 0x02, 0x02, 0x00, 0x00, 0x1e
	.byte 0xd6, 0xf4, 0x1e, 0xf2, 0xf3, 0x1e, 0x51, 0xfb
	.byte 0x78, 0xce, 0x00, 0x1d, 0x7a, 0xbf, 0xfe, 0xdb
	.byte 0x33, 0x00, 0x66, 0x07, 0x1e, 0x46, 0x0d, 0x1d
	.byte 0x1c, 0xc1, 0xfe, 0x1e, 0xd5, 0xf1, 0x78, 0xb8
	.byte 0x00

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
	add xwa, 0xE2013C
	ld wa, (xwa)
	lda_24 xix, 0xf21dd0
	jp_dri 8, 0x07, 0xF0, 0xE0

; DpDocTtl case B
DpDoc_CaseB:
	ldw wa, 0xFFFF
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
	ldw wa, 0xA5
	jr DpDoc_CaseF
	ldw wa, 0xD6

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
	cp xbc, 0x1C00009
	jrl z, DpPd_CaseI
	cp xbc, 0x1C00008
	jrl z, DpPd_CaseG
	cp xbc, 0x1C00007
	jr z, DpPd_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpPdTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpPdTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpPdTtl_ReturnZero
	add xde, xde
	add xde, 0xE20170
	ld de, (xde)
	lda_24 xix, 0xf21e89
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpPdTtlFunc title dispatch
DpPdTtl_Dispatch:
	.byte 0xf2, 0x86, 0x10, 0x02, 0x02, 0x00, 0x00, 0x1e
	.byte 0xa7, 0xf3, 0x1e, 0xc3, 0xf2, 0x1e, 0x66, 0xfa
	.byte 0x78, 0xce, 0x00, 0x1d, 0x7a, 0xbf, 0xfe, 0xdb
	.byte 0x33, 0x00, 0x66, 0x07, 0x1e, 0x17, 0x0c, 0x1d
	.byte 0x1c, 0xc1, 0xfe, 0x1e, 0xa6, 0xf0, 0x78, 0xb8
	.byte 0x00

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
	add xwa, 0xE2015C
	ld wa, (xwa)
	lda_24 xix, 0xf21eff
	jp_dri 8, 0x07, 0xF0, 0xE0

; DpPdTtl case B
DpPd_CaseB:
	ldw wa, 0xFFFF
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
	ldw wa, 0xA5
	jr DpPd_CaseF
	ldw wa, 0xD6

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
	cp xbc, 0x1C00009
	jrl z, DpSmf_CaseI
	cp xbc, 0x1C00008
	jrl z, DpSmf_CaseG
	cp xbc, 0x1C00007
	jrl z, DpSmf_CaseA
	cp xbc, 0x1C00013
	jrl nz, DpSmfTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, DpSmfTtl_ReturnZero
	cp xde, 0x5
	jrl ugt, DpSmfTtl_ReturnZero
	add xde, xde
	add xde, 0xE20190
	ld de, (xde)
	lda_24 xix, 0xf21fb9
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpSmfTtlFunc title dispatch
DpSmfTtl_Dispatch:
	.byte 0xc1, 0x37, 0x8d, 0x3f, 0x72, 0x76, 0xff, 0x00
	.byte 0xf2, 0x88, 0x10, 0x02, 0x00, 0x00, 0xf2, 0x86
	.byte 0x10, 0x02, 0x02, 0x00, 0x00, 0x1e, 0x69, 0xf2
	.byte 0x1e, 0x85, 0xf1, 0x1e, 0x90, 0xf8, 0x78, 0xe6
	.byte 0x00, 0xc1, 0x36, 0x8d, 0x3f, 0x72, 0x76, 0xde
	.byte 0x00, 0x1d, 0x7a, 0xbf, 0xfe, 0xdb, 0x33, 0x00
	.byte 0x66, 0x17, 0x1e, 0xd1, 0x0a, 0x1d, 0x1c, 0xc1
	.byte 0xfe, 0x40, 0x26, 0x00, 0x6f, 0x00, 0x41, 0x09
	.byte 0x00, 0xc7, 0x01, 0xea, 0xa8, 0x1d, 0x58, 0x9d
	.byte 0xfa, 0x1e, 0x50, 0xef, 0x78, 0xb8, 0x00

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
	add xwa, 0xE2017C
	ld wa, (xwa)
	lda_24 xix, 0xf22055
	jp_dri 8, 0x07, 0xF0, 0xE0

; DpSmfTtl case B
DpSmf_CaseB:
	ldw wa, 0xFFFF
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
	ldw wa, 0xA5
	jr DpSmf_CaseF
	ldw wa, 0xD6

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
	cp xbc, 0x1C00009
	jrl z, DpSmfLyr_CaseC
	cp xbc, 0x1C00008
	jrl z, DpSmfLyr_CaseB
	cp xbc, 0x1C00007
	jr z, DpSmfLyr_CaseA
	cp xbc, 0x1C00013
	jrl nz, SeqStep_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jrl c, SeqStep_ReturnZero
	cp xde, 0x5
	jrl ugt, SeqStep_ReturnZero
	add xde, xde
	add xde, 0xE2019C
	ld de, (xde)
	lda_24 xix, 0xf2210e
	jp_dri 8, 0x07, 0xF0, 0xE8
; DpSmfLyrTtlFunc title dispatch
DpSmfLyrTtl_Dispatch:
	ld	xwa, 7274534
	ld	xbc, 29818890
	lds32	xde, 0
	jr	18
	calr	60982
	jrl	193
	ld	xwa, 7274534
	ld	xbc, 29818890
	lds32	xde, 0
	call	16424280
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
	ldw wa, 0xFFFF
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
	ldw wa, 0xD6
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
	cp xbc, 0x1C00013
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
	cp xbc, 0x1C00013
	jr nz, SqTrSelTtl_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SqTrSelTtl_ReturnZero
	cp xde, 0x5
	jr ugt, SqTrSelTtl_ReturnZero
	add xde, xde
	add xde, 0xE201A8
	ld de, (xde)
	lda_24 xix, 0xf22245
	jp_dri 8, 0x07, 0xF0, 0xE8
SqTrSelTtl_Dispatch:	.ascii ":;<>"
	.byte 0x1d, 0x58, 0x04, 0xf2
	.ascii "^\\[Zh"
	.byte 0x0c, 0x3a, 0x3b
	.byte 0x3c, 0x3e, 0x1d, 0x6f, 0x04, 0xf2, 0x5e, 0x5c
	.byte 0x5b, 0x5a

SqTrSelTtl_ReturnZero:
	lds32 xhl, 0
	ret

Display_InitGraphicsAndScreen:
	; --- Init sequence + 4 register-save call thunks ---
	ldw wa, 0x00FF
	call GraphicsRender_ByteData
	ldw wa, 0x00F5
	call 0xFB144A
	call 0xFB14B7
	ldw wa, 0x00FF
	call 0xFB1456
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
	ld xiy, 0xE201B4
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret


; --- Demo Routines ---
