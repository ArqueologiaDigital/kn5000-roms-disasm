; =============================================================================
; UI Playback Mode Handlers (3K lines)
; =============================================================================
;
; UI state event handling and playback mode control: voice parameter
; handlers, sequencer timer/tempo, part validation, play/song/medley
; mode dispatch, part format handlers, and display mode transitions.
; =============================================================================

UIStateEvt_VoiceParamHandler:
	.incbin "includes/generated/v7_transplant_UIStateEvt_VoiceParamHandler.bin"
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
	.incbin "includes/generated/v7_transplant_SeqTimer_PostTempoUpdate.bin"
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
	.incbin "includes/generated/v7_transplant_PlaybackMode_DispatchByType.bin"
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
	.incbin "includes/generated/v7_transplant_PlayMode_SendModeCommand.bin"
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
	.incbin "includes/generated/v7_transplant_PlayMode_StartAndSendCommand.bin"
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
	.incbin "includes/generated/v7_transplant_SeqRestart_SendPlaybackNotify.bin"
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
	.incbin "includes/generated/v7_transplant_SongMode_AbortAndClearBit2.bin"
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
	.incbin "includes/generated/v7_transplant_VoiceState_SetStatus1AndDispatch.bin"
PartFormat_PartTypeDisp:
	.incbin "includes/generated/v7_transplant_PartFormat_PartTypeDisp.bin"
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
	.incbin "includes/generated/v7_transplant_PartFormat_AbortAndClearBit2.bin"
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
	.incbin "includes/generated/v7_transplant_PlayModeStop_InitFlagBlock.bin"
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
	.incbin "includes/generated/v7_transplant_PlayMode_StopAndAbort.bin"
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
	.incbin "includes/generated/v7_transplant_PlayModeStop_ClearFlagBlock.bin"
SqSngNameTtl_Dispatch:
	xor wa, wa
	ldb a, 0x73
	call UI_PostModeChangeEvent
	ret

CDlikeSwitch_NullRet:
	ret

CDlikeSwitch_PlaybackTimer:
	.incbin "includes/generated/v7_transplant_CDlikeSwitch_PlaybackTimer.bin"
CDlikeTimer_ResetAccompaniment:
	pushw wa
	anddi8 (0x28b2), 249
	anddi8 (0x28a7), 247
	call Seq_ResetAndRestartAccompaniment
	popw wa
	jr CDlikeSwTtl_StorePlaybackMode

CDlikeTimer_CheckZeroCount:
	.incbin "includes/generated/v7_transplant_CDlikeTimer_CheckZeroCount.bin"
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
	.incbin "includes/generated/v7_transplant_CDlike_InitModeAndLoadBank.bin"
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
	.incbin "includes/generated/v7_transplant_CDlike_ExitModeAndRestore.bin"
CDlikeExit_CheckPlaybackType:
	.incbin "includes/generated/v7_transplant_CDlikeExit_CheckPlaybackType.bin"
PlayMode_ResetAndSchedule:
	.incbin "includes/generated/v7_transplant_PlayMode_ResetAndSchedule.bin"
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
	.incbin "includes/generated/v7_transplant_SongBank_SendAccompEvent.bin"
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
	.incbin "includes/generated/v7_transplant_SongBank_SendBassEvent.bin"
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
	.incbin "includes/generated/v7_transplant_SQTR_DISPATCH_TABLE_2.bin"
SQTR_DISPATCH_TABLE_2_CASE1:
	.incbin "includes/generated/v7_transplant_SQTR_DISPATCH_TABLE_2_CASE1.bin"
SQTR_DISPATCH_TABLE_2_CASE2:
	.incbin "includes/generated/v7_transplant_SQTR_DISPATCH_TABLE_2_CASE2.bin"
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
	.incbin "includes/generated/v7_transplant_SqTrAsPsTtl_CaseF.bin"
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
	.incbin "includes/generated/v7_transplant_DkMdlyPly_CheckState.bin"
Snd_ParamLookupSetupWerp:
	ldiw_erp 0xfa, 0

; DkMdlyPly handle result
DkMdlyPly_HandleResult:
	.incbin "includes/generated/v7_transplant_DkMdlyPly_HandleResult.bin"
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
	.incbin "includes/generated/v7_transplant_DisplayMode_DispatchEvents.bin"
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
	.incbin "includes/generated/v7_transplant_DisplayMode_RefreshState.bin"
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
	.incbin "includes/generated/v7_transplant_DpMdlySmfTtl_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_DpMdlySmfLyrTtl_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_NameGetFuncCall_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_ShowSongTitle.bin"
CDlikeSwTtl_ShowDocTitle:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_ShowDocTitle.bin"
CDlikeSwTtl_ShowPdTitle:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_ShowPdTitle.bin"
CDlikeSwTtl_SongBit1Check:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongBit1Check.bin"
CDlikeSwTtl_SongBit0Check:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongBit0Check.bin"
CDlikeSwTtl_JumpToFA9D58:
	jp ApPostEvent

CDlikeSwTtl_DocBitCheck:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocBitCheck.bin"
CDlikeSwTtl_DocRedraw:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocRedraw.bin"
CDlikeSwTtl_PdBitCheck:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdBitCheck.bin"
CDlikeSwTtl_PdRedraw:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdRedraw.bin"
CDlikeSwTtl_SongConfirmStart:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongConfirmStart.bin"
CDlikeSwTtl_SongConfirmBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongConfirmBit0.bin"
CDlikeSwTtl_SongConfirmDefault:
	stdi8 (7498), 1
	calr CDlikeSwTtl_ShowSongTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_SongConfirmJump:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongConfirmJump.bin"
CDlikeSwTtl_SongConfirmDispatch:
	ldb_d8 a, (7498)
	cps a, 2
	jr z, CDlikeSwTtl_SongConfirmState2
	cps a, 1
	jr z, CDlikeSwTtl_SongConfirmState1
	cps a, 3
	ret nz

CDlikeSwTtl_SongConfirmState1:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongConfirmState1.bin"
CDlikeSwTtl_SongConfirmState2:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongConfirmState2.bin"
CDlikeSwTtl_DocConfirmStart:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocConfirmStart.bin"
CDlikeSwTtl_DocConfirmBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocConfirmBit0.bin"
CDlikeSwTtl_DocConfirmDefault:
	stdi8 (7498), 1
	calr CDlikeSwTtl_ShowDocTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_DocConfirmJump:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocConfirmJump.bin"
CDlikeSwTtl_PdConfirmStart:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdConfirmStart.bin"
CDlikeSwTtl_PdConfirmBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdConfirmBit0.bin"
CDlikeSwTtl_PdConfirmDefault:
	stdi8 (7498), 1
	calr CDlikeSwTtl_ShowPdTitle
	calr SeqRecPlay_EnablePlayOnly

CDlikeSwTtl_PdConfirmJump:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdConfirmJump.bin"
CDlikeSwTtl_SongNavDispatch:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongNavDispatch.bin"
CDlikeSwTtl_SongNavBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_SongNavBit0.bin"
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
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocNavDispatch.bin"
CDlikeSwTtl_DocNavBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_DocNavBit0.bin"
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
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdNavDispatch.bin"
CDlikeSwTtl_PdNavBit0:
	.incbin "includes/generated/v7_transplant_CDlikeSwTtl_PdNavBit0.bin"
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
	.incbin "includes/generated/v7_transplant_DpDocTtl_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_DpDoc_CaseC.bin"
DpDoc_CheckBit0PlayMode:
	.incbin "includes/generated/v7_transplant_DpDoc_CheckBit0PlayMode.bin"
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
	.incbin "includes/generated/v7_transplant_DpPdTtl_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_DpPd_CaseC.bin"
DpPd_CheckBit0PlayMode:
	.incbin "includes/generated/v7_transplant_DpPd_CheckBit0PlayMode.bin"
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
	.incbin "includes/generated/v7_transplant_DpSmfTtl_Dispatch.bin"
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
	.incbin "includes/generated/v7_transplant_DpSmf_CaseC.bin"
DpSmf_CheckBit0PlayMode:
	.incbin "includes/generated/v7_transplant_DpSmf_CheckBit0PlayMode.bin"
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
	.incbin "includes/generated/v7_transplant_SeqRecPlay_ToggleRecordOrPlay.bin"
DpSmfLyr_CheckBit0PlayMode:
	.incbin "includes/generated/v7_transplant_DpSmfLyr_CheckBit0PlayMode.bin"
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
