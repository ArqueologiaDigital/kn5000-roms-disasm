; =============================================================================
; UI Playback Mode Handlers (3K lines)
; =============================================================================
;
; UI state event handling and playback mode control: voice parameter
; handlers, sequencer timer/tempo, part validation, play/song/medley
; mode dispatch, part format handlers, and display mode transitions.
; =============================================================================

UIStateEvt_VoiceParamHandler:
	ld	a, (0x8d36:16)
	cp	a, 142
	jr	z, UIStateEvt_VoiceParamHandler_Skip
	cp	a, 100
	jr	z, UIStateEvt_VoiceParamHandler_Skip
	cp	a, 108
	jr	lt, UIStateEvt_VoiceParamHandler_Skip2
	cp	a, 122
	jr	le, UIStateEvt_VoiceParamHandler_Skip
	jp	UIStateEvt_VoiceParamHandler_0x24
UIStateEvt_VoiceParamHandler_Skip:
	ld	(4330:16), 0
	jrl	UIStateEvt_VoiceParamHandler_Return
UIStateEvt_VoiceParamHandler_Skip2:
	ld	a, (0xc07d:16)
	cp	a, 3:i3
	jp_24 nz, (15860660)
	ldb_d8 a, (49278)
	ld	w, (0xc07f:16)
	cp	w, 255
	jr	nz, UIStateEvt_VoiceParamHandler_Skip4
	anddi8 (4330), 254
	jrl	UIStateEvt_VoiceParamHandler_Return
UIStateEvt_VoiceParamHandler_Skip4:
	bit	2, w
	jr	nz, UIStateEvt_VoiceParamHandler_Skip5
	jr	UIStateEvt_VoiceParamHandler_Return
UIStateEvt_VoiceParamHandler_Skip5:
	bitda 0, (4330)
	jr z, UIStateEvt_VoiceParamHandler_Skip6
	anddi8 (4330), 254
	jr	UIStateEvt_VoiceParamHandler_Return
UIStateEvt_VoiceParamHandler_Skip6:
	and	a, w
	and	a, 4
	bit	2, a
	jr	z, UIStateEvt_VoiceParamHandler_Skip7
	pushw	wa
	xor	a, a
	call	Part_WriteAllVoiceSubBlocks_B
	popw	wa
	call	SeqPlay_RestoreVoiceState_Return
	call	UIStateEvt_VoiceParamHandler_0xC9
	call	AccWrap_PlayModeDispatch
	call	SeqBuf_Init
	ld	(1073:16), 0
	ordi8 (10419), 16
	ldw	(0xf19e:16), 0
	anddi8 (10405), 254
	ld	a, 76:opc
	call	CtrlPanel_SetIndicatorBit
	jr	UIStateEvt_VoiceParamHandler_Return
UIStateEvt_VoiceParamHandler_Skip7:
	pushw	wa
	xor	a, a
	call	Part_WriteAllVoiceSubBlocks_A
	popw	wa
	call	SeqPlay_RestoreVoiceState_Return
	call	UIStateEvt_VoiceParamHandler_0xC9
	call	AccWrap_PlayModeDispatch
	call	SeqBuf_Init
	ld	(1073:16), 0
	ordi8 (10419), 16
	ldw	(0xf19e:16), 0
	ld	(4596:16), 0
	call	SeqPlay_CheckStartConditions
UIStateEvt_VoiceParamHandler_Return:
	ret
	ld	xix, 0xf1a0
	xor	bc, bc
	ld	c, 16:opc
	ld	a, 16:opc
	cp	a, (xix+)
	jr	z, UIStateEvt_VoiceParamHandler_Skip3
	djnz16	bc, -8
	jr	UIStateEvt_VoiceParamHandler_Join
UIStateEvt_VoiceParamHandler_Skip3:
	xor	wa, wa
	ld	a, 16:opc
	sub	wa, bc
	ld	c, a
	ld	b, a
	ld	iz, (0xf19e:16)
	ld	a, c
	scf
	.byte 0xde
	pushw	de
	ld	a, b
	jr c, 45
	pushw wa
	ld xhl, 62032
	ld	c, 3:opc
	mul	wa, c
	ld	iy, wa
	.byte 0xf3
	reti
	cp	xix, xix
	inc	6, l
	pop	sr
	popw	wa
	jr	3
	popw	wa
	jr	20
	inc	1, a
	ld	w, a
	ld	(3414:16), w
	ordi8 (3412), 1
	ordi8 (10363), 4
	jr	UIStateEvt_VoiceParamHandler_Return2
UIStateEvt_VoiceParamHandler_Join:
	anddi8 (3412), 254
	anddi8 (10363), 251
	xor	w, w
UIStateEvt_VoiceParamHandler_Return2:
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
	ld xhl, 0xf460
	ld xwa, 0x2da
	add xhl, xwa
	ld wa, (xhl + 8)
	pushw wa
	ld e, 0x48:opc
	ld d, 0x8:opc
	ld w, 0xff:opc
	call SwbtWr_QueuePostEvent
	popw wa
	ld (0xfc62:16), wa
	call SeqTimer_UpdateTempoReg
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
	ld c, 0x00:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_01:
	ld c, 0x01:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_02:
	ld c, 0x02:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_03:
	ld c, 0x03:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_04:
	ld c, 0x04:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_05:
	ld c, 0x05:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_06:
	ld c, 0x06:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_07:
	ld c, 0x07:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_08:
	ld c, 0x08:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_09:
	ld c, 0x09:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0A:
	ld c, 0x0a:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0B:
	ld c, 0x0b:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0C:
	ld c, 0x0c:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0D:
	ld c, 0x0d:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0E:
	ld c, 0x0e:opc
	call Part_LookupParam
	call Part_ValidateAndActivate
	ret
PartParam_Handler_0F:
	ld c, 0x0f:opc
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
	ld a, 0x8a:opc
	call UI_PostModeChangeEvent
PartValidate_Done:
	ret
PlaybackDispatch_NullRet:
	ret


PlaybackMode_DispatchByType:
	bit 0, (3381:16)
	jrl z, DispatchHandler_ClearActiveFlag
	cp (0x8d36:16), 122
	jr z, PlaybackDisp_Type122_Play
	cp (0x8d36:16), 120
	jr z, PlaybackDisp_Type120_Play
	cp (0x8d36:16), 115
	jr z, PlaybackDisp_Type115_Stop
	cp (0x8d36:16), 118
	jr z, PlaybackDisp_Type118_Stop
	cp (0x8d36:16), 116
	jr z, PlaybackDisp_Type116_Song
	cp (0x8d36:16), 117
	jrl z, PlaybackDisp_Type117_PartFmt
	cp (0x8d36:16), 111
	jr z, PlaybackDisp_Type111_CDSong
	cp (0x8d36:16), 114
	jr z, PlaybackDisp_Type114_CDSong
	cp (0x8d36:16), 112
	jr z, PlaybackDisp_Type112_CDDoc
	cp (0x8d36:16), 113
	jrl z, PlaybackDisp_Type113_CDPd
	cp (0x8d36:16), 121
	jr z, Part_ValidateCallAndClear
	cp (0x8d36:16), 119
	jr z, Part_ValidateCallAndClear
	cp (0x8d36:16), 108
	jr z, Part_ValidateCallAndClear
	cp (0x8d36:16), 109
	jr z, Part_ValidateCallAndClear
	cp (0x8d36:16), 110
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
	cpdi8 (3380), 0
	jr	nz, PlayMode_InitFlagBlock_Return
	ld	(3380:16), 1
	call	PlayMode_InitFlagBlock_0x16
PlayMode_InitFlagBlock_Return:
	ret
	ordi8 (10412), 4
	ld	(4420:16), 10
	ret

SongBank_ScanActiveVoices:
	xor bc, bc
	ld l, a
	extz hl
	mul hl, 0x800
	add xhl, 0xab0d0
	ld xiy, xhl
	ld b, 0x10:opc
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
	ld hl, 1:i3

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
	ld (4437:16), 0
	cp (0x8d36:16), 122
	jr z, PlayCheck_PostMode79
	cp (0x8d36:16), 120
	jr z, PlayCheck_PostMode77

PlayCheck_PostMode79:
	xor wa, wa
	ld a, 0x79:opc
	call UI_PostModeChangeEvent
	jr PlayCheck_Return

PlayCheck_PostMode77:
	xor wa, wa
	ld a, 0x77:opc
	call UI_PostModeChangeEvent

PlayCheck_Return:
	ret

PlayMode_DispatchAndClearBit2:
	call AccWrap_PlayModeDispatch
	and (0x28ac:16), 251
	ret

PlayMode_StartAndSendCommand:
	cp (3380:16), 1
	jr nz, SongMode_PostEvtRetZero
	cp (4420:16), 0
	jr nz, SongMode_PostEvtRetZero
	call PlayMode_DispatchAndClearBit2
	ld (4437:16), 1
	cp (0x8d36:16), 122
	jr z, PlayStart_PostMode79
	cp (0x8d36:16), 120
	jr z, PlayStart_PostMode77

PlayStart_PostMode79:
	xor wa, wa
	ld a, 0x79:opc
	call UI_PostModeChangeEvent
	jr SongMode_PostEvtRetZero

PlayStart_PostMode77:
	xor wa, wa
	ld a, 0x77:opc
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
	djnz16 bc, SeqRestart_WaitBit2Loop

SeqRestart_DispatchAndNotify:
	call Seq_DispatcherEntry
	call SeqRestart_SendPlaybackNotify

SeqRestart_Return:
	ret

SeqRestart_SendPlaybackNotify:
	bit 2, (0x28ac:16)
	jr z, SeqNotify_Return
	ld (4437:16), 1
	cp (0x8d36:16), 122
	jr z, SeqNotify_PostMode79
	cp (0x8d36:16), 120
	jr z, SeqNotify_PostMode77

SeqNotify_PostMode79:
	xor wa, wa
	ld a, 0x79:opc
	call UI_PostModeChangeEvent
	jr SeqNotify_Return

SeqNotify_PostMode77:
	xor wa, wa
	ld a, 0x77:opc
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
	cpdi8 (3380), 0
	jr	nz, Medley_GetPlaybackStatus_Return
	ld	(3380:16), 1
	call	SongMode_InitFlagBlock_0x18
Medley_GetPlaybackStatus_Return:
	ret
	ordi8 (10412), 4
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
	ld a, 0x6d:opc
	call UI_PostModeChangeEvent
	ret

SongMode_AbortAndClearBit2:
	and (0x28ac:16), 251
	call Song_AbortPlayback
	ret

SongMode_StartPlayback:
	cp (3380:16), 1
	jrl nz, SongMode_StartReturn
	cp (4420:16), 0
	jrl nz, SongMode_StartReturn
	call SongMode_AbortAndClearBit2
	ld (4437:16), 1
	xor wa, wa
	ld a, 0x6d:opc
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
	ld (4437:16), 1
	cp (0x8d36:16), 116
	jr z, PartFormat_PostMode6D
	cp (0x8d36:16), 112
	jrl z, VoiceState_SqTrSelCaseD
	cp (0x8d36:16), 117
	jr z, PartFormat_PostMode6E
	cp (0x8d36:16), 113
	jrl z, VoiceState_SqTrSelCaseF
	cp (0x8d36:16), 115
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8d36:16), 111
	jr z, VoiceState_SqTrSelCaseE
	cp (0x8d36:16), 118
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8d36:16), 114
	jr z, VoiceState_SqTrSelCaseE
	jp PartFormat_NullRet

PartFormat_PartTypeDisp:
	cp (0x8d36:16), 116
	jr z, PartFormat_PostMode6D
	cp (0x8d36:16), 112
	jr z, PartFormat_PostMode6D
	cp (0x8d36:16), 117
	jr z, PartFormat_PostMode6E
	cp (0x8d36:16), 113
	jr z, PartFormat_PostMode6E
	cp (0x8d36:16), 115
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8d36:16), 111
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8d36:16), 118
	jr z, PartFormat_SendPlaybackCmd
	cp (0x8d36:16), 114
	jr z, PartFormat_SendPlaybackCmd
	jp PartFormat_NullRet

PartFormat_PostMode6D:
	xor wa, wa
	ld a, 0x6d:opc
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_PostMode6E:
	xor wa, wa
	ld a, 0x6e:opc
	call UI_PostModeChangeEvent
	jr PartFormat_NullRet

PartFormat_SendPlaybackCmd:
	call PlayMode_SendStopEvent
	xor wa, wa
	ld a, 0x6c:opc
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
	cpdi8 (3380), 0
	jr	nz, SongMode_VoiceStateDisp_Return
	ld	(3380:16), 1
	call	PartFormat_InitFlagBlock_0x1B
SongMode_VoiceStateDisp_Return:
	ret
	ordi8 (10412), 4
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
	ld a, 0x6e:opc
	call UI_PostModeChangeEvent
	ret

PartFormat_AbortAndClearBit2:
	and (0x28ac:16), 251
	call Song_AbortPlayback
	ret

PartFormat_StartPlayback:
	cp (3380:16), 1
	jrl nz, PartFormat_StartReturn
	cp (4420:16), 0
	jrl nz, PartFormat_StartReturn
	call PartFormat_AbortAndClearBit2
	ld (4437:16), 1
	xor wa, wa
	ld a, 0x6e:opc
	call UI_PostModeChangeEvent

PartFormat_StartReturn:
	ret

PlayModeStop_InitFlagBlock:
	ret
	ret
	ret
	ret
	cpdi8 (36151), 118
	jr z, PartFormat_StartPlayback_Return
	call	PlayModeStop_InitFlagBlock_0x10
PartFormat_StartPlayback_Return:
	ret
	cpdi8 (3380), 0
	jr	nz, PartFormat_StartPlayback_Return2
	ld	(3380:16), 1
	call	PlayModeStop_InitFlagBlock_0x21
PartFormat_StartPlayback_Return2:
	ret
	ordi8 (10412), 4
	ld	(4420:16), 10
	ret
	cpdi8 (36150), 108
	jr nz, PartFormat_StartPlayback_Return3
	ld	(3380:16), 0
PartFormat_StartPlayback_Return3:
	ret

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
	ld a, 0x6c:opc
	call UI_PostModeChangeEvent
	ret

PlayMode_StopAndAbort:
	and (0x28ac:16), 251
	call PlayMode_SendStopEvent
	call Song_AbortPlayback
	ret

PlayMode_SendCommand6C:
	cp (3380:16), 1
	jrl nz, PlayModeStop_SendReturn
	cp (4420:16), 0
	jrl nz, PlayModeStop_SendReturn
	call PlayMode_StopAndAbort
	ld (4437:16), 1
	xor wa, wa
	ld a, 0x6c:opc
	call UI_PostModeChangeEvent

PlayModeStop_SendReturn:
	ret

PlayModeStop_ClearFlagBlock:
	ret
	ret
	ret
	ret
	ret
	cpdi8 (36150), 108
	jr nz, PlayMode_SendCommand6C_Return
	ld	(3380:16), 0
PlayMode_SendCommand6C_Return:
	ret

; SqSngNameTtlFunc title dispatch
SqSngNameTtl_Dispatch:
	xor wa, wa
	ld a, 0x73:opc
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	ret

CDlikeSwitch_PlaybackTimer:
	ld w, (4420:16)
	cp w, 0:i3
	jr z, CDlikeTimer_Return
	dec 1, w
	cp w, 5:i3
	jr nz, CDlikeTimer_CheckZeroCount
	cp (0x8d36:16), 122
	jr z, CDlikeTimer_ResetAccompaniment
	cp (0x8d36:16), 120
	jr z, CDlikeTimer_ResetAccompaniment
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_ResetAccompaniment:
	pushw wa
	and (0x28b2:16), 249
	and (0x28a7:16), 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_CheckZeroCount:
	cp w, 0:i3
	jr nz, CDlikeSwTtl_StorePlaybackMode
	cp (0x8d36:16), 122
	jr z, CDlikeTimer_InitResetState
	cp (0x8d36:16), 120
	jr z, CDlikeTimer_InitResetState
	cp (0x8d36:16), 116
	jr z, CDlikeTimer_ShowDocTitle
	cp (0x8d36:16), 117
	jr z, CDlikeTimer_ShowPdTitle
	cp (0x8d36:16), 115
	jr z, CDlikeTimer_ShowSongTitle
	cp (0x8d36:16), 118
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
	or (0xb7e2:16), 64
	ld a, (0xfdad:16)
	ld (3394:16), a
	ld (3380:16), 0
	ld (4420:16), 0
	call CDlike_LoadSongBankData
	cp (0x8d36:16), 119
	jr z, CDlikeSw_NullRet
	cp (0x8d36:16), 120
	jr z, CDlikeSw_NullRet
	cp (0x8d36:16), 121
	jr z, CDlikeSw_NullRet
	cp (0x8d36:16), 122
	jr z, CDlikeSw_NullRet
	call SqTrAs_InitWall
	ld wa, (0xf19e:16)
	ld (0x2875:16), wa
	ldw (0xf19e:16), 0
	ldw (8980:16), 0
	ld xiy, 0xf9a0
	ld xix, 0x3cf04
	ldw bc, 0x310
	ldirw

CDlikeSw_NullRet:
	ret

CDlike_LoadSongBankData:
	ld (6882:16), 0
	cpw (0xf19e:16), 0
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
	and (0xb7e2:16), 191
	and (0x28ac:16), 251
	ld (4420:16), 0
	bit 2, (3394:16)
	jr z, CDlikeExit_CheckPlaybackType
	jr CDlikeExit_CheckPlaybackType

CDlikeExit_CheckPlaybackType:
	cp (0x8d37:16), 119
	jr z, PlayMode_ResetAndSchedule
	cp (0x8d37:16), 120
	jr z, PlayMode_ResetAndSchedule
	cp (0x8d37:16), 121
	jr z, PlayMode_ResetAndSchedule
	cp (0x8d37:16), 122
	jr z, PlayMode_ResetAndSchedule
	ld (4330:16), 1
	call ToneGen_FileIO_RestoreFromBackup
	call SeqTimer_UpdateTempoReg
	call SwbtWr_ResetAllChannels
	call SqTrAs_Setup
	ld wa, (0x2875:16)
	ld (0xf19e:16), wa

PlayMode_ResetAndSchedule:
	ld (3380:16), 0
	call Audio_CheckSubsystemReady
	ret

SongBank_SwitchAndUpdateTempo:
	ld (0x00ffe3:24), a
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
	ld a, 0x4:opc

SongBank_SendAccompEvent:
	ld (4330:16), 1
	ld e, 0x91:opc
	ld d, 0x3:opc
	ld w, 0x4:opc
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks

SongBank_CheckBassMode:
	cp (0xf24b:16), 255
	jr z, SongBank_EnableBassMode
	and (0xfdad:16), 254
	xor a, a
	jr SongBank_SendBassEvent

SongBank_EnableBassMode:
	or (0xfdad:16), 1
	ld a, 0x1:opc

SongBank_SendBassEvent:
	ld e, 0x91:opc
	ld d, 0x3:opc
	ld w, 0x1:opc
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks
	ld (4596:16), 1
	call BitMapOut_RenderDisplay
	call Audio_CheckSubsystemReady
	ret

; SqTrAs setup handler
SqTrAs_Setup:
	ld xiy, 0xcce
	ld xix, 0xf1a0
	xor bc, bc
	ld c, 0x10:opc
	ldir85
	ret

; SqTrAs init wall data
SqTrAs_InitWall:
	ld xix, 0xcce
	ld xiy, 0xf1a0
	xor bc, bc
	ld c, 0x10:opc
	ldir85
	ret

; SqTrAs load inline code
SqTrAs_LoadInline:
	ret

SqAftSetTtlFunc:
	ld xhl, 0:i3
	ret

SqSngSelTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
	push xde
	push xhl
	push xix
	push xiz
	call	SetWall_InlineCodeBlock3_0x1
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqSngName_ReturnZero
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
	ld xhl, 0:i3
	ret

SqSngNameTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
	ld xhl, 0:i3
	ret

SqTrAsTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, SqTrAs_EventHandler
	cp xbc, EVT_ACTIVATE_STATE
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
	ld xwa, 0x8b0004
	ld xbc, EVT_SET_SELECTED_CEL
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
	set 0, (0x8f5c:16)	; F20DAD: LD (XIX+5Ch), 0B8h (TMP94C241 encoding)
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
	res 0, (0x8f5c:16)	; F20DCD: LD (XIX+5Ch), 0B0h (TMP94C241 encoding)
	ldw wa, 0x60
	call CtrlPanel_SetIndicatorBit
	jr CDlikeSwTtl_ReturnZero2
SQTR_DISPATCH_TABLE_2_CASE2:
	cp (0x8d36:16), 139
	jr nz, CDlikeSwTtl_ReturnZero2
	cp (0x7f42:16), 35
	scc16 z, bc
	cp (0x8d39:16), 238
	scc16 z, wa
	and wa, bc
	jr z, SQTR_DISPATCH_TABLE_2_CASE5
	ld xwa, 0x8b0004
	ld xbc, EVT_SET_SELECTED_CEL
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
	ld xhl, 0:i3
	ret

SqTrAsSureFunc:
	cp xbc, EVT_SW_IN
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
	ld xhl, 0:i3
	ret

SqTrAsPsTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, SqTrAsPsTtl_CaseD
	cp xbc, EVT_ACTIVATE_STATE
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
SqTrAsPsTtl_Dispatch:
	push xde
	push xhl
	push xix
	push xiz
	call	SetWall_DataBlock1
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	xwa, 0x8c0004
	ld	xbc, EVT_SET_SELECTED
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, 0x8c0005
	ld	xbc, EVT_SET_SELECTED
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x8c0006
	ld	xbc, EVT_SET_SELECTED
	ld	xde, 0:i3
	call	ApPostEvent
	jr SqTrAsPsTtl_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	SetWall_DataBlock1_0xF
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	SqTrAsPsTtl_ReturnZero

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
	ld xhl, 0:i3
	ret

SqTrAsPsSureFunc:
	cp xbc, EVT_SW_IN
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
	ld xhl, 0:i3
	ret

; SqTrAsPsTtl case F
SqTrAsPsTtl_CaseF:
	ld	a, (0x8d36:16)
	extz	wa
	sub	wa, 108
	cp	wa, 0:i3
	jr	lt, SqTrAsPsTtl_CaseF_Skip
	cp	wa, 13
	jr	gt, SqTrAsPsTtl_CaseF_Skip
	lda	xix, (SepaOut_Config_0_0x44:24)
	ld_rrw wa, xix, wa
	extz wa
	sll	wa, 1
	ld	xix, SepaOut_Config_0_0x52
	ld_rrw wa, xix, wa
	lda xix, (15863692:24)
	jp_rr 8, xix, wa
SqTrAsPsTtl_CaseF_Skip:
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
	cp xbc, EVT_SW_IN
	jr z, SqMdlyPly_InitPlay
	cp xbc, EVT_ACTIVATE_STATE
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
SqMdlyPlyTtl_Dispatch:
	push xde
	push xhl
	push xix
	push xiz
	call	PlayMode_InitFlagBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqMdlyPly_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	PlayMode_ClearModeFlag
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SqTrAsPsTtl_CaseF
	jr	SqMdlyPly_ReturnZero

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
	ld xhl, 0:i3
	ret

DkMdlyPlyTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DkMdlyPly_InitPlay
	cp xbc, EVT_ACTIVATE_STATE
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
DkMdlyPlyTtl_Dispatch:
	push xde
	push xhl
	push xix
	push xiz
	call	PlayMode_InitFlagBlock
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DkMdlyPly_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	PlayMode_ClearModeFlag
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SqTrAsPsTtl_CaseF
	jr	DkMdlyPly_ReturnZero

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
	ld xhl, 0:i3
	ret

; DkMdlyPly send audio command
DkMdlyPly_SendAudioCmd:
	ld hl, 0:i3
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
	dec 2, xsp
	push xiz
	ld (xsp + 4), wa
	ld a, (0x8d36:16)
	cp a, 0x6f
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x72
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x73
	jr z, Snd_ParamLookupSetupWerp
	cp a, 0x76
	jr nz, DkMdlyPly_Finalize

Snd_ParamLookupSetupWerp:
	ldiw_erp 0xfa, 0

; DkMdlyPly handle result
DkMdlyPly_HandleResult:
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (SepaOut_Config_0_0x8E:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ldw bc, 0x401
	call SndParam_LookupViaEncode
	ld iz, hl
	ld wa, (xsp + 4)
	calr DkMdlyPly_SendAudioCmd
	cp hl, iz
	jr nz, DkMdlyPly_ExtendedCheck
	ldto_werp WA, 0xfa
	add wa, wa
	lda xbc, (SepaOut_Config_0_0x8E:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ld (0x8d3a:16), a
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
	inc1w_erp 0xfa
	cp_erpw 0xfa, 0x20, 0x00
	jr lt, DkMdlyPly_HandleResult

; DkMdlyPly finalize
DkMdlyPly_Finalize:
	pop xiz
	inc 2, xsp
	ret

DisplayMode_DispatchEvents:
	ld a, (0x8d36:16)
	extz wa
	sub wa, 0x6f
	cp wa, 0:i3
	ret lt
	cp wa, 6:i3
	ret gt
	add wa, wa
	lda xix, (SepaOut_Config_0_0xCE:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (DisplayMode_BatchEventSend:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; --- DisplayMode_BatchEventSend: Dispatch events for display mode transitions ---
; Multiple entry points, each dispatching 2-3 events for a specific mode.
; Pattern per entry: XWA=event_id, XBC=0x1e0043b (target), XDE=0 (param),
;   then call EventDispatch (0xfac558) or jump to common tail.
; Event IDs encode mode/sub-function: 0x6f000a, 0x70000x, 0x73000c, etc.
DisplayMode_BatchEventSend:
	ld	xwa, 0x6f000a
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	jrl	DisplayMode_DispatchEvents_Join
	ld	xwa, 0x73000c
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	jrl	DisplayMode_DispatchEvents_Join
	ld	xwa, 0x700007
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x700008
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x700009
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	jr	DisplayMode_DispatchEvents_Join
	ld	xwa, 0x74000a
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x74000b
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x74000c
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	jr	DisplayMode_DispatchEvents_Join
	ld	xwa, 0x710007
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x710008
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	jr	DisplayMode_DispatchEvents_Join
	ld	xwa, 0x750009
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
	call	ApPostEvent
	ld	xwa, 0x75000a
	ld	xbc, EVT_SET_PARAM
	ld	xde, 0:i3
DisplayMode_DispatchEvents_Join:
	call	ApPostEvent
	ret

DisplayMode_RefreshState:
	ld wa, (0x021086:24)
	calr DkMdlyPly_CheckState
	ld wa, (0x021086:24)
	jp FileIO_ReadChunk

DpMdlyDocTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DpMdlyDoc_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SongMode_InitFlagBlock_0x2
	pop	xiz
	pop	xix
	pop	xhl
	pop xde
	jr DpMdlyDoc_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	SongMode_InitFlagBlock_0x23
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SqTrAsPsTtl_CaseF
	jr	DpMdlyDoc_ReturnZero

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
	ld xhl, 0:i3
	ret

DpMdlyPdTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DpMdlyPd_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PartFormat_InitFlagBlock_0x5
	pop	xiz
	pop	xix
	pop	xhl
	pop xde
	jr DpMdlyPd_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	PartFormat_InitFlagBlock_0x26
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SqTrAsPsTtl_CaseF
	jr	DpMdlyPd_ReturnZero

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
	ld xhl, 0:i3
	ret

DpMdlySmfTtlFunc:
	cp xbc, EVT_SW_IN
	jr z, DpMdlySmf_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	cp	(0x8d37:16), 118
	jr	z, DpMdlySmfTtlFunc_Skip
	ld	(0x021088:24), 0
	ldw	(0x021086:24), 0
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
DpMdlySmfTtlFunc_Skip:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PlayModeStop_InitFlagBlock_0x4
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlySmf_ReturnZero
	push xde
	push xhl
	push xix
	push xiz
	call	PlayModeStop_InitFlagBlock_0x2C
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	SqTrAsPsTtl_CaseF
	jr	DpMdlySmf_ReturnZero

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
	ld xhl, 0:i3
	ret

DpMdlySmfLyrTtlFunc:
	cp xbc, EVT_SW_IN
	jrl z, DpMdlySmfLyr_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	ld	a, (0x8d37:16)
	cp	a, 108
	jr	nz, DpMdlySmfLyrTtlFunc_Skip2
	cp	a, 118
	jr	z, DpMdlySmfLyrTtlFunc_Skip
	ld	(0x021088:24), 0
	ldw	(0x021086:24), 0
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
DpMdlySmfLyrTtlFunc_Skip:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	PlayModeStop_InitFlagBlock_0x4
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr DpMdlySmfLyrTtlFunc_Join
DpMdlySmfLyrTtlFunc_Skip2:
	push xde
	push xhl
	push xix
	push xiz
	call	PlayModeStop_ClearFlagBlock_0x4
	pop xiz
	pop xix
	pop xhl
	pop xde
DpMdlySmfLyrTtlFunc_Join:
	ld xwa, 7274534
	ld	xbc, EVT_LYRICS_ALL_DRAW
	ld	xde, 0:i3
	jr	t, DpMdlySmfLyrTtlFunc_Join2
	push xde
	push xhl
	push xix
	push xiz
	call	PlayModeStop_ClearFlagBlock_0x5
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr	SqTrAsPsTtl_CaseF
	jr DpMdlySmfLyr_ReturnZero
	ld xwa, 7274534
	ld	xbc, EVT_LYRICS_ALL_DRAW
	ld	xde, 0:i3
DpMdlySmfLyrTtlFunc_Join2:
	call	ApPostEvent
	jr	DpMdlySmfLyr_ReturnZero

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
	ld xhl, 0:i3
	ret

NameGetFuncCall:
	sub xbc, EVT_GET_CUR_SONG_NAME
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
	pushw	16
	pushw	0
	pushw	0xf280
	pushw	0
	pushw	6888
	call	Strncpy
	lda	xwa, (6888:16)
	ld	(xwa+16), 0
	push	xwa
	ld	a, (0xffe3:24)
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
	ld	xbc, EVT_CUR_SONG_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
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
	ld	(7283:16), 0
	ld	xwa, 0xffffffff
	ld	xbc, EVT_DISK_FILE_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
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
	lda	xwa, (7284:16)
	ld	(xwa+16), 0
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SMF_FILE_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
	pushw	20
	call	GetFirstPageBase
	ld	wa, hl
	call	GetFileEntryByIndex
	push	xhl
	pushw	0
	pushw	7304
	call	Strncpy
	lda	xsp, (xsp+10)
	lda	xwa, (7304:16)
	ld	(xwa+20), 0
	ldw	de, 19
NameGetFuncCall_Loop:
	lda_rr xbc, xwa, de
	cp (xbc), 32
	jr nz, NameGetFuncCall_Skip2
	ld (xbc), 0
	sub	de, 1
	jr	gt, NameGetFuncCall_Loop
NameGetFuncCall_Skip2:
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SMF_SONG_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
	call	FileIO_GetCurrentFileIndex_Alt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	272
	pushw	0
	pushw	7362
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	(7365:16), 0
	ld	xwa, 0xffffffff
	ld	xbc, EVT_DOC_FILE_NO
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
	pushw	12
	call	FileIO_GetCurrentFileIndex_Alt
	ld	wa, hl
	call	FileIO_GetFileEntryWithRefresh
	push	xhl
	pushw	0
	pushw	7326
	call	Strncpy
	lda	xsp, (xsp+10)
	lda	xwa, (7326:16)
	ld	(xwa+12), 0
	ldw	de, 11
NameGetFuncCall_Loop2:
	lda_rr xbc, xwa, de
	cp (xbc), 32
	jr nz, NameGetFuncCall_Skip3
	ld (xbc), 0
	sub	de, 1
	jr	gt, NameGetFuncCall_Loop2
NameGetFuncCall_Skip3:
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_DOC_SONG_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
	call	GetCurrentFileIndexAlt
	inc	1, hl
	pushw	hl
	pushw	226
	pushw	280
	pushw	0
	pushw	7366
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	ld	(7369:16), 0
	ld	xwa, 0xffffffff
	ld	xbc, EVT_PD_FILE_NO
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
	call	GetCurrentFileIndexAlt
	ld	wa, hl
	call	GetFileRecordPtr
	push	xhl
	pushw	0
	pushw	7340
	call	Strcpy
	inc	8, xsp
	lda	xwa, (7340:16)
	ld	(xwa+20), 0
	ldw	de, 19
NameGetFuncCall_Loop3:
	lda_rr xbc, xwa, de
	cp (xbc), 32
	jr nz, NameGetFuncCall_Skip4
	ld (xbc), 0
	sub	de, 1
	jr	gt, NameGetFuncCall_Loop3
NameGetFuncCall_Skip4:
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_PD_SONG_NAME
	ld	xde, 0:i3
	jrl	NameGetFuncCall_Join2
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
	lda	xwa, (0x02104e:24)
	ld	(xwa+20), 0
	ldw	de, 19
NameGetFuncCall_Loop4:
	lda_rr xbc, xwa, de
	cp (xbc), 32
	jr nz, NameGetFuncCall_Skip5
	ld (xbc), 0
	sub	de, 1
	jr	gt, NameGetFuncCall_Loop4
NameGetFuncCall_Skip5:
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SONG_WRITE
	ld	xde, 0:i3
	jr	NameGetFuncCall_Join2
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
	lda	xwa, (0x021064:24)
	or	xhl, xhl
	jr	z, NameGetFuncCall_Skip
	inc	1, xhl
	pushw	28
	push	xhl
	push	xwa
	call	Strncpy
	lda	xsp, (xsp+10)
	ld	(0x021080:24), 0
	jr	NameGetFuncCall_Join
NameGetFuncCall_Skip:
	ld	(xwa), 0
NameGetFuncCall_Join:
	ld	xwa, 0x021064
	call	FileIO_GetRecordType_Extended
	ld	xwa, 0xffffffff
	ld	xbc, EVT_COMPOSER_WRITE
	ld	xde, 0:i3
NameGetFuncCall_Join2:
	call	ApPostEvent

; NameGetFuncCall entry handler
NameGetFunc_Entry:
	ld xhl, 0:i3
	ret

CDlikeSwTtlFunc:
	cp xbc, EVT_SW_IN
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
	ld xhl, 0:i3
	ret

CDlikeSwTtl_ShowSongTitle:
	call SeqState_GetFlags
	bit 0, hl
	ret nz
	ld xwa, 0x720006
	ld xbc, EVT_LYRICS_PLAY_START_INI
	ld xde, 0:i3
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
	lda xbc, (7198:16)
	ld (xbc + 12), 0x0
	ld wa, 1:i3
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cp wa, 0:i3
	jp nz, (SongMode_VoiceStateDisp:24)
	calr SeqRecPlay_EnableRecordOnly
	ld (4437:16), 0
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
	lda xbc, (7212:16)
	ld (xbc + 12), 0x0
	ld wa, 2:i3
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cp wa, 0:i3
	jp nz, (SongMode_VoiceStateDisp:24)
	calr SeqRecPlay_EnableRecordOnly
	ld (4437:16), 0
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
	lda xbc, (7226:16)
	ld (xbc + 20), 0x0
	ld wa, 4:i3
	call Acc_LoadAndStartPlayback
	ld wa, hl
	cp wa, 0:i3
	jp nz, (SongMode_VoiceStateDisp:24)
	calr SeqRecPlay_EnableRecordOnly
	ld (4437:16), 0
	ret

CDlikeSwTtl_SongBit1Check:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_SongBit0Check
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3
	jr CDlikeSwTtl_JumpToFA9D58

CDlikeSwTtl_SongBit0Check:
	call SeqState_GetFlags
	bit 0, hl
	jrl z, CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_DisableBoth
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3

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
	ld (7498:16), 3
	jr CDlikeSwTtl_SongConfirmJump

CDlikeSwTtl_SongConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_SongConfirmDefault
	ld (7498:16), 2
	jr CDlikeSwTtl_SongConfirmJump

CDlikeSwTtl_SongConfirmDefault:
	ld (7498:16), 1
	calr CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_SongConfirmJump:
	jp Acc_StartFillIn

CDlikeSwTtl_SongConfirmDispatch:
	ld a, (7498:16)
	cp a, 2:i3
	jr z, CDlikeSwTtl_SongConfirmState2
	cp a, 1:i3
	jr z, CDlikeSwTtl_SongConfirmState1
	cp a, 3:i3
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
	ld (7498:16), 3
	jr CDlikeSwTtl_DocConfirmJump

CDlikeSwTtl_DocConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_DocConfirmDefault
	ld (7498:16), 2
	jr CDlikeSwTtl_DocConfirmJump

CDlikeSwTtl_DocConfirmDefault:
	ld (7498:16), 1
	calr CDlikeSwTtl_ShowDocTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_DocConfirmJump:
	jp Acc_StartFillIn

CDlikeSwTtl_PdConfirmStart:
	call SeqState_GetFlags
	bit 1, hl
	jr z, CDlikeSwTtl_PdConfirmBit0
	ld (7498:16), 3
	jr CDlikeSwTtl_PdConfirmJump

CDlikeSwTtl_PdConfirmBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_PdConfirmDefault
	ld (7498:16), 2
	jr CDlikeSwTtl_PdConfirmJump

CDlikeSwTtl_PdConfirmDefault:
	ld (7498:16), 1
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
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	ld (0x021088:24), 0x00
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_SMF_FILE_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_SMF_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_LYRICS_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_COMPOSER_NAME
	ld xde, 0:i3
	jr CDlikeSwTtl_SongNavFinishNames

CDlikeSwTtl_SongNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_SongNavNoRedraw
	call Song_AbortPlayback
	ld xwa, 0x6f0026
	ld xbc, EVT_LYRICS_ALL_CLEAR
	ld xde, 0:i3
	call ApPostEvent
	ld wa, iz
	call NavigateSongList
	ld (0x021088:24), 0x00
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_SMF_FILE_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_SMF_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_LYRICS_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_COMPOSER_NAME
	ld xde, 0:i3

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
	ld xbc, EVT_GET_SMF_FILE_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_SMF_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_LYRICS_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_COMPOSER_NAME
	ld xde, 0:i3
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
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_DOC_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_DOC_SONG_NAME
	ld xde, 0:i3
	jr CDlikeSwTtl_DocNavFinishNames

CDlikeSwTtl_DocNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_DocNavNoRedraw
	call Song_AbortPlayback
	ld wa, iz
	call NavigateDocList
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_DOC_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_DOC_SONG_NAME
	ld xde, 0:i3

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
	ld xbc, EVT_GET_DOC_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_DOC_SONG_NAME
	ld xde, 0:i3
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
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_PD_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_PD_SONG_NAME
	ld xde, 0:i3
	jr CDlikeSwTtl_PdNavFinishNames

CDlikeSwTtl_PdNavBit0:
	call SeqState_GetFlags
	bit 0, hl
	jr z, CDlikeSwTtl_PdNavNoRedraw
	call Song_AbortPlayback
	ld wa, iz
	call NavigatePdList
	ldw (0x021086:24), 0x0000
	calr DisplayMode_RefreshState
	calr DisplayMode_DispatchEvents
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_PD_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_PD_SONG_NAME
	ld xde, 0:i3

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
	ld xbc, EVT_GET_PD_FILE_NO
	ld xde, 0:i3
	calr NameGetFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_GET_PD_SONG_NAME
	ld xde, 0:i3
	calr NameGetFuncCall

CDlikeSwTtl_PdNavReturn:
	popw iz
	ret

DpDocTtlFunc:
	cp xbc, EVT_SW_OFF
	jrl z, DpDoc_CaseI
	cp xbc, EVT_SW_ON
	jrl z, DpDoc_CaseG
	cp xbc, EVT_SW_IN
	jr z, DpDoc_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	ldw	(0x021086:24), 0
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
	calr	CDlikeSwTtl_ShowDocTitle
	jrl	DpDocTtl_ReturnZero
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, DpDocTtlFunc_Skip
	calr	SeqRecPlay_DisableBoth
	call	Song_AbortPlayback
DpDocTtlFunc_Skip:
	calr	SqTrAsPsTtl_CaseF
	jrl	DpDocTtl_ReturnZero

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
	ld wa, 1:i3

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
	ld xhl, 0:i3
	ret

DpPdTtlFunc:
	cp xbc, EVT_SW_OFF
	jrl z, DpPd_CaseI
	cp xbc, EVT_SW_ON
	jrl z, DpPd_CaseG
	cp xbc, EVT_SW_IN
	jr z, DpPd_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	ldw	(0x021086:24), 0
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
	calr	CDlikeSwTtl_ShowPdTitle
	jrl	DpPdTtl_ReturnZero
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, DpPdTtlFunc_Skip
	calr	SeqRecPlay_DisableBoth
	call	Song_AbortPlayback
DpPdTtlFunc_Skip:
	calr	SqTrAsPsTtl_CaseF
	jrl	DpPdTtl_ReturnZero

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
	ld wa, 1:i3

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
	ld xhl, 0:i3
	ret

DpSmfTtlFunc:
	cp xbc, EVT_SW_OFF
	jrl z, DpSmf_CaseI
	cp xbc, EVT_SW_ON
	jrl z, DpSmf_CaseG
	cp xbc, EVT_SW_IN
	jrl z, DpSmf_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	cp	(0x8d37:16), 114
	jrl	z, DpSmfTtl_ReturnZero
	ld	(0x021088:24), 0
	ldw	(0x021086:24), 0
	calr	DisplayMode_RefreshState
	calr	DisplayMode_DispatchEvents
	calr	CDlikeSwTtl_ShowSongTitle
	jrl	DpSmfTtl_ReturnZero
	cp	(0x8d36:16), 114
	jrl	z, DpSmfTtl_ReturnZero
	call	SeqState_GetFlags
	bit	0, hl
	jr	z, DpSmfTtlFunc_Skip
	calr	SeqRecPlay_DisableBoth
	call	Song_AbortPlayback
	ld	xwa, 0x6f0026
	ld	xbc, EVT_LYRICS_ALL_CLEAR
	ld	xde, 0:i3
	call	ApPostEvent
DpSmfTtlFunc_Skip:
	calr	SqTrAsPsTtl_CaseF
	jrl	DpSmfTtl_ReturnZero

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
	ld wa, 1:i3

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
	ld xhl, 0:i3
	ret

DpSmfLyrTtlFunc:
	cp xbc, EVT_SW_OFF
	jrl z, DpSmfLyr_CaseC
	cp xbc, EVT_SW_ON
	jrl z, DpSmfLyr_CaseB
	cp xbc, EVT_SW_IN
	jr z, DpSmfLyr_CaseA
	cp xbc, EVT_ACTIVATE_STATE
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
	ld	xbc, EVT_LYRICS_ALL_DRAW
	ld	xde, 0:i3
	jr	DpSmfLyrTtlFunc_Join
	calr	SqTrAsPsTtl_CaseF
	jrl	SeqStep_ReturnZero
	ld	xwa, 0x6f0026
	ld	xbc, EVT_LYRICS_ALL_DRAW
	ld	xde, 0:i3
DpSmfLyrTtlFunc_Join:
	call	ApPostEvent
	jrl	SeqStep_ReturnZero

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
	ld wa, 1:i3

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
	ld xhl, 0:i3
	ret

SeqStepModeFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
	ld xhl, 0:i3
	ret

SqTrSelTtlFunc:
	cp xbc, EVT_ACTIVATE_STATE
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
SqTrSelTtl_Dispatch:
	push xde
	push xhl
	push xix
	push xiz
	call	PlayMode_SetupAndDispatch
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr SqTrSelTtl_ReturnZero
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
	ld xhl, 0:i3
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
