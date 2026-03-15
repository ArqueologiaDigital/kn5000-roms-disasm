; =============================================================================
; SMF Event Processor
; =============================================================================
;
; Standard MIDI File (SMF) event processing, tone generation
; dispatch, and voice channel management. Bridges SMF playback
; data to the audio engine.
; =============================================================================

	and ix, 0xFF
	inc 1, ix
	cp ix, 0xFF
	jr ugt, ToneGen_DispatchSubHandler
	jr ToneGen_DispatchReturn

ToneGen_DispatchSubHandler:
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	push xiy
	pushw bc
	call DispatchHandler_JumpToSubHandler
	popw bc
	pop xiy
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	cpda16 xix, 10349
	jr ule, ToneGen_StoreBlockAndLink
	stdi8 10362, 5
	jr ToneGen_DispatchReturn

ToneGen_StoreBlockAndLink:
	ldda32 xhl, 4349
	ld (xhl + 3), ix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ldda16 xwa, 3308
	ldda32 xhl, 4349
	ld (xhl + 1), wa
	ldw (xhl + 3), 0xFFFF
	stda16 3308, xix
	lds ix, 5

ToneGen_DispatchReturn:
	ret

ToneGen_DispatchAndLinkBlock:
	push xix
	push xiy
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ld (xhl + 3), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ldda16 xbc, 10415
	ld (xhl + 1), bc
	ldw (xhl + 3), 0xFFFF
	stda16 10415, xwa
	stdi16 9830, 5
	pop xiy
	pop xix
	ret

VoiceChannel_GetCombinedStatus:
	cpdi8 4012, 6
	jr z, VoiceChannel_GetStatusBank2First
	push xix
	ld xix, 0x10D3
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix
	ld l, a
	push xix
	ld xix, 0x10C3
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	jr VoiceChannel_CombineStatusBits

VoiceChannel_GetStatusBank2First:
	push xix
	ld xix, 0x10C3
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	ld xix, 0x10D3
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xix

VoiceChannel_CombineStatusBits:
	rlc_i_8 l, 2
	and l, 0x1
	sla a, 1
	or a, l
	ret

VoiceChannel_LookupParams:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x10B3
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xix
	xor h, h
	cp l, 0xFF
	jr z, VoiceChannel_LookupReturn
	ld c, l
	sla hl, 2
	push xix
	ld xix, 0xF25EAC
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	ld_srib3 A, 0x07, 0xEC, 0xF4
	stda8 4234, a
	call SoundGen_PrepareAndBuildVoice

VoiceChannel_LookupReturn:
	ret

VoiceChannel_SetPanDirection:
	call VoiceChannel_GetParamBlock
	ld w, (xiy + 4)
	and w, 0xF7
	xor a, a
	cpdi8 4013, 64
	jr c, VoiceChannel_MergePanBit
	or a, 0x8

VoiceChannel_MergePanBit:
	or w, a
	or w, 0x10
	ld (xiy + 4), w
	ret

VoiceChannel_UpdateWithPitch:
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xB0
	bitda 7, 4235
	jr z, VoiceChannel_ApplyPitchFlags
	or a, 0x2
	bitda 7, 4234
	jr z, VoiceChannel_ApplyPitchFlags
	or a, 0x1

VoiceChannel_ApplyPitchFlags:
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceChannel_NullRet
	sla xiy, 1
	push xix
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	pop xix
	srl xiy, 1
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceChannel_NullRet
	push xix
	ld xix, 0xF2435B
	cpdi8 4600, 1
	jr z, VoiceChannel_SelectChannelBank
	ld xix, 0xF2436B

VoiceChannel_SelectChannelBank:
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet
	ldda8 a, 4233
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet
	ldda8 a, 4234
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet
	ldda8 a, 4235
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0

VoiceChannel_NullRet:
	ret

SoundGen_ClampUpdateVoice:
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xF
	push xiy
	call SoundGen_ReadVoiceRegs
	ldb a, 0xB0
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	sla iy, 1
	push xix
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	pop xix
	srl iy, 1
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	ldda8 a, 4011
	and a, 0xF
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	ldda8 a, 4233
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	ldda8 a, 4234
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	ldda8 a, 4235
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0

VoiceChannel_NullRet2:
	ret

VoiceChannel_SetParamByte7:
	call VoiceChannel_GetParamBlock
	ldda8 a, 4013
	ld w, (xiy + 7)
	and w, 0x80
	or w, a
	ld (xiy + 7), w
	ret

VoiceChannel_MergeParamByte5:
	call VoiceChannel_GetParamBlock
	ldda8 a, 4013
	ld w, (xiy + 5)
	and w, 0x80
	or w, a
	ld (xiy + 5), w
	ret

SoundGen_LookupChannelBankParams:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x1093
	ld_srib3 A, 0x07, 0xF0, 0xF4
	ld xix, 0x10A3
	ld_srib3 W, 0x07, 0xF0, 0xF4
	pop xix
	cps a, 0
	jr nz, ToneGen_StoreBadValue
	cps w, 0
	jr c, ToneGen_StoreBadValue
	cps w, 2
	jr ugt, ToneGen_StoreBadValue
	push xix
	ld xix, 0x10B3
	lda_dri3 XWA, 0x07, 0xF0, 0xF4
	pop xix
	jr SoundGen_LookupReturn

ToneGen_StoreBadValue:
	ldb a, 0xFF
	push xix
	ld xix, 0x10B3
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix

SoundGen_LookupReturn:
	ret

VoiceChannel_GetParamBlock:
	xor h, h
	ldda8 l, 4011
	and l, 0xF
	sla hl, 2
	cpdi8 4600, 1
	jr nz, VoiceChannel_GetParamBlockAlt
	push xix
	ld xix, 0xF26C1E
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	jr VoiceChannel_StoreParamPtr

VoiceChannel_GetParamBlockAlt:
	push xix
	ld xix, 0xF26C5E
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix

VoiceChannel_StoreParamPtr:
	ld xiy, xhl
	ret

VoiceChannel_ParamTable1:
	cp	ix, (xiz)
	nop
	nop
	ret	pe
	nop
	nop
	cp	d, b
	nop
	nop
	.byte 0xe4, 0xf4, 0x00
	nop
	swi	6
	.byte 0xf4, 0x00, 0x00, 0x18, 0xf5, 0x00, 0x00, 0x32, 0xf5, 0x00, 0x00, 0x4c, 0xf5, 0x00, 0x00, 0x66, 0xf5, 0x00, 0x00, 0x80, 0xf5, 0x00, 0x00, 0x9a, 0xf5, 0x00, 0x00, 0xb4, 0xf5, 0x00, 0x00, 0xce, 0xf5, 0x00, 0x00, 0xe8, 0xf5, 0x00, 0x00, 0x02, 0xf6
	nop
	nop
	call16	246
	nop
	cp	ix, (xiz)
	nop
	nop
	ret	pe
	nop
	nop
	cp	d, b
	nop
	nop
	.byte 0xe4, 0xf4, 0x00
	nop
	swi	6
	.byte 0xf4, 0x00, 0x00, 0x18, 0xf5, 0x00, 0x00, 0x32, 0xf5, 0x00, 0x00, 0x4c, 0xf5, 0x00, 0x00, 0x66, 0xf5, 0x00, 0x00, 0x1c, 0xf6
	nop
	nop
	.byte 0x9a, 0xf5, 0x00
	nop
	.byte 0xb4, 0xf5
	nop
	nop
	cp	e, h
	nop
	nop
	cp	xiy, xwa
	nop
	nop
	push_sr
	.byte 0xf6
	nop
	nop
	cp	e, (xwa)
	nop
	nop
	call	15887342
	ldda8	a, 4013
	ld	(xiy+3), a
	ret

SoundGen_PrepareAndBuildVoice:
	push xiy
	cpdi16 3932, 0
	jr z, SoundGen_CaptureAndBuildParams
	cpdi16 3934, 2
	jr c, SoundGen_CaptureAndBuildParams
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_CaptureAndBuildParams:
	push xiy
	pushw bc
	call SoundGen_CaptureVoiceParams
	popw bc
	pop xiy
	ldb a, 0xB0
	cps c, 1
	jr nz, SoundGen_UpdateAndWriteChannel
	or a, 0x2
	bitda 7, 4234
	jr z, SoundGen_UpdateAndWriteChannel
	or a, 0x1

SoundGen_UpdateAndWriteChannel:
	push xiy
	pushw bc
	call SoundGen_UpdateAndRefresh
	popw bc
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	sla xiy, 1
	push xix
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	pop xix
	srl xiy, 1
	pushw bc
	push xiy
	call SoundGen_ScalePitchByTempo
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	ld l, c
	xor h, h
	ldda8 l, 4011
	and l, 0xF
	xor h, h
	cpdi16 3932, 0
	jr z, SoundGen_SelectChannelTable
	cpdi16 3934, 2
	jr c, SoundGen_SelectChannelTable
	ld a, l
	jr SoundGen_ApplyChannelParam

SoundGen_SelectChannelTable:
	ld xix, 0xF2436B
	cpdi8 4600, 1
	jr nz, SoundGen_SelectAltChannelTable
	ld xix, 0xF2435B

SoundGen_SelectAltChannelTable:
	ld_srib3 A, 0x07, 0xF0, 0xEC

SoundGen_ApplyChannelParam:
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	pop xiy
	push xiy
	push xde
	ld xde, 0xF26DD0
	ld_srib3 A, 0x03, 0xE8, 0xE4
	pop xde
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	ldda8 a, 4234
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	ldb a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	call ToneGen_SetSustainBit
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	cpdi16 3932, 0
	jr z, SoundGen_CommitChannelRegs
	cpdi16 3934, 2
	jr c, SoundGen_CommitChannelRegs
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_CommitChannelRegs:
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0

SoundGen_PopIyRet:
	pop xiy
	ret

SoundGen_VoiceParamData:
	pushw 0x090a

FileIO_ReadBlockToBuffer:
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13FA
	ld xbc, 0x400
	call FileIO_ReadBlock
	stda32 6701, xhl
	pop xhl
	pop xbc
	pop xwa
	ret

FileIO_ReadBlockToFilePos:
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13FA
	ld xbc, 0x400
	call FileIO_ReadBlock
	stda32 6701, xhl
	pop xhl
	pop xbc
	pop xwa
	ret

SoundGen_InitAllVoiceChannels:
	push xwa
	push xbc
	push xde
	push xhl
	push xix
	push xiy
	stdi8 6749, 176
	stdi8 6750, 154
	bitda 7, 6750
	jr nz, SoundGen_SetInitFlags
	jp SoundGen_InitLoopStart

SoundGen_SetInitFlags:
	setda 2, 6749
	resda 7, 6750

SoundGen_InitLoopStart:
	xor iy, iy

SoundGen_InitVoiceLoop:
	push xiy
	call SoundGen_CaptureVoiceParams
	pop xiy
	ldda8 a, 6749
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x0
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldda8 a, 6750
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ld xde, 0xF26E7E
	ld_srib3 A, 0x07, 0xE8, 0xF4
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x2
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	push xiy
	call ToneGen_WriteChannelRegs
	pop xiy
	inc 1, iy
	cps iy, 2
	jr ule, SoundGen_InitVoiceLoop
	pop xiy
	pop xix
	pop xhl
	pop xde
	pop xbc
	pop xwa
	ret

SoundGen_InitVoiceData:
	max
	halt
	.byte 0x06

SndParam_LookupChannelVoice:
	push xhl
	cpdi8 4600, 2
	jr nz, SndParam_LookupDefault
	ldda8 a, 4011
	and a, 0xF
	cp a, 0x9
	jr nz, SndParam_LookupDefault
	push xix
	push xbc
	push xde
	xor xhl, xhl
	ld l, a
	mul l, 0x2
	xor xwa, xwa
	xor xbc, xbc
	xor xde, xde
	ld xix, 0x1A37
	ldb a, 0x4
	ld_sriw3 BC, 0x07, 0xF0, 0xEC
	ld e, b
	xor hl, hl
	ldda8 l, 4012
	pushw hl
	call SndParam_LookupByChannel
	ld a, l
	pop xde
	pop xbc
	pop xix
	cp a, 0xFF
	jr z, SndParam_LookupReturn

SndParam_LookupDefault:
	ldb a, 0x0

SndParam_LookupReturn:
	pop xhl
	ret

VoiceChannel_StoreVoiceIdx:
	push xde
	xor de, de
	ldda8 e, 4011
	and e, 0xF
	stda16 6751, xde
	pop xde
	cpdi16 6751, 9
	jr nz, VoiceChannel_StoreVoiceReturn
	ld xwa, 0x1A57
	call SndParam_ApplyVoiceValue
	ld xhl, 0x1A37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

VoiceChannel_StoreVoiceReturn:
	ret

SMF_ProcessSysExBlock:
	call SysEx_ClearBuffer
	xor xiy, xiy
	ld xiy, 0x1A61
	ld (xiy), a
	inc 1, xiy
	push xiy
	call Sequencer_ValidateFileData
	pop xiy
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SysEx_FileUnderflow
	pop xbc
	pop xwa
	jp SMF_SysEx_CheckBlockLimit

SMF_SysEx_FileUnderflow:
	pop xbc
	pop xwa
	jp Seq_ReturnToDispatcher

SMF_SysEx_CheckBlockLimit:
	cpdi8 4600, 1
	jr z, Seq_AdvanceBlock
	ldb a, 0x7F
	ld bc, ix
	sub a, c
	sub a, 0x1
	cpdi16 4212, 0
	jr nz, Seq_AdvanceBlock
	cpdm8 4211, a
	jr ugt, Seq_AdvanceBlock
	ld bc, ix
	ld xix, xiy
	ld xiy, 0x106E
	ldir85
	call SysEx_ReadBytesLoop_Init
	cpdi8 6880, 255
	jr z, Seq_ReturnToDispatcher
	ld xwa, 0x1A61
	lds32 xbc, 0
	call SysEx_ValidateRolandHeader
	jp Seq_ReturnToDispatcher

Seq_AdvanceBlock:
	call Sequencer_AdvanceBlockPosition

Seq_ReturnToDispatcher:
	ret

SysEx_ReadBytesLoop_Init:
	stdi8 6880, 0

SysEx_ReadBytesLoop:
	cpdi8 4211, 0
	jr ule, SysEx_ReadBytesReturn
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SysEx_ReadBytes_FileUnderflow
	pop xbc
	pop xwa
	jp SysEx_ReadBytes_StoreByte

SysEx_ReadBytes_FileUnderflow:
	pop xbc
	pop xwa
	jp SysEx_ReadBytes_SetOverflow

SysEx_ReadBytes_StoreByte:
	ld (xix), a
	decdi8 1, 4211
	inc 1, xix
	jp SysEx_ReadBytesLoop

SysEx_ReadBytes_SetOverflow:
	stdi8 6880, 255

SysEx_ReadBytesReturn:
	ret

SysEx_ClearBuffer:
	ldb c, 0x7F
	ld xiy, 0x1A61

SysEx_ClearLoop:
	cps c, 0
	jr ule, SysEx_ClearReturn
	ld (xiy), 0x0
	dec 1, c
	inc 1, xiy
	jp SysEx_ClearLoop

SysEx_ClearReturn:
	ret

SMF_LoadSoundBankAndPlay:
	stda8 4599, a
	stda8 6709, c
	stda8 6710, e
	push xiz
	push xix
	push xde
	call SetWall_LoadBankToToneGen
	ldda8 a, 4599
	cpda8_24 a, 65507
	jr z, SMF_LoadBank_ClearAndPrepare
	ldda8 a, 4599
	st8_24 0x00ffe3, a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay

SMF_LoadBank_ClearAndPrepare:
	call SMF_ClearFileBuffer
	call SMF_InitPlaybackState
	pop xde
	pop xix
	pop xiz
	ldda16 xhl, 6699
	bit 15, hl
	jr nz, SMF_SeekAndPreparePlayback
	cps hl, 2
	jr z, SMF_SeekAndPreparePlayback
	set 15, hl

SMF_SeekAndPreparePlayback:
	bit 15, hl
	jr nz, SMF_RestoreTimerState
	anddi8 36232, 254
	call SMF_CalcFilePosition
	push xwa
	push xbc
	ldda32 xbc, 6705
	sub xbc, 0x13FA
	ld xwa, xbc
	lds32 xbc, 0
	call FileIO_SeekAndReadBlock
	cp xhl, 0x0
	jr lt, SMF_Seek_FileError
	jp SMF_Seek_WritePosition

SMF_Seek_FileError:
	pop xbc
	pop xwa
	jr SMF_RestoreTimerState

SMF_Seek_WritePosition:
	ld xwa, 0xFA2
	lds32 xbc, 4
	call FileIO_WriteByte_Impl
	pop xbc
	pop xwa

SMF_RestoreTimerState:
	bitda 0, 10405
	jr z, SMF_SeekReturn
	ld16_24 xwa, 0x00ffec
	stda16 61854, xwa
	push xhl
	call Audio_CheckSubsystemReady
	pop xhl

SMF_SeekReturn:
	ret

SeqPlay_StartWithDisplay:
	call SeqPlay_CheckStartConditions
	cpdi8 62013, 255
	jr z, SeqPlay_SetFlagAndMode
	anddi8 64941, 251
	xor a, a
	jr SeqPlay_QueueDisplayEvent

SeqPlay_SetFlagAndMode:
	ordi8 64941, 4
	ldb a, 0x4

SeqPlay_QueueDisplayEvent:
	stdi8 4330, 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks
	call BitMapOut_RenderDisplay
	ret

SMF_InitPlaybackState:
	pushw wa
	cpdi16 61852, 0
	jr z, SMF_InitChannelState
	stdi16 6699, 9
	jrl SMF_PopReturn

SMF_InitChannelState:
	xor wa, wa
	stda8 4236, a
	stda16 4347, xwa
	stda8 4344, a
	cpdi16_24 65516, 0
	jr z, SMF_SetStatusAndJump
	xor c, c

SMF_ScanChannelLoop:
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	jr c, SMF_LoopNextChannel
	ld l, c
	xor h, h
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xEC, 0x10
	pop xix
	jr z, SMF_LoopNextChannel
	ld a, l
	sla l, 1
	add l, a
	push xde
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xEC
	pop xde
	jr nz, SMF_FoundActiveChannel

SMF_LoopNextChannel:
	inc 1, c
	cp c, 0xF
	jr ule, SMF_ScanChannelLoop

SMF_SetStatusAndJump:
	stdi16 6699, 47
	jrl SMF_Finalize_PopReturn

SMF_FoundActiveChannel:
	call Vga_SetupMultiPlaneDisplay
	ld16_24 xwa, 0x00ffec
	stda16 4325, xwa
	stdi8 4324, 255
	bitda 2, 64941
	jr nz, SMF_InitChannelScan
	stdi8 4324, 0

SMF_InitChannelScan:
	call SMF_ScanChannels
	call SMF_CountActiveChannels
	call SMF_ClearWorkArea
	call SMF_ClearWorkArea
	xor wa, wa
	stda16 4347, xwa
	stda8 4236, a
	stda8 4344, a
	xor hl, hl
	xor bc, bc

SMF_FindFirstActiveChannel:
	push xde
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xEC
	pop xde
	jr nz, SMF_SetupActiveChannel
	add hl, 0x3
	inc 1, c
	cp c, 0xF
	jr ule, SMF_FindFirstActiveChannel
	stdi16 6699, 3
	jrl SMF_Finalize_RestoreAndPlay

SMF_SetupActiveChannel:
	stda8 10359, c
	inc 1, hl
	push xde
	ld xde, 0xF250
	ld_sriw3 HL, 0x07, 0xE8, 0xEC
	pop xde
	stda16 10415, xhl
	stdi16 9830, 5
	ld xiy, 0xF2823E
	ld xix, 0x13FA
	lds bc, 7
	ldirw
	ld xiy, 0xF2824C
	lds bc, 4
	ldir85
	xor wa, wa
	stda16 4002, xwa
	stda16 4004, xwa
	stda32 6705, xix
	ldda16 xwa, 4002
	st_dpiw WA, 0xF1
	ldda16 xwa, 4004
	st_dpiw WA, 0xF1
	stda32 4376, xix
	ldda32 xix, 4376
	ld xiy, 0xF2823A
	lds bc, 4
	ldir85
	ld xiy, 0xF280
	ldw bc, 0x10
	ldir85
	stda32 4376, xix
	stdi16 4206, 0
	stdi8 4208, 0
	ld xiy, 0x106E
	ldda32 xix, 4376

SMF_WaitForReady:
	ld_spib A, 0xF4
	lda_dpi XBC, 0xF0
	bit 7, a
	jr nz, SMF_WaitForReady
	ldw wa, 0x58FF
	st_dpiw WA, 0xF1
	ldb a, 0x4
	ldda8 w, 1075
	st_dpiw WA, 0xF1
	ldw wa, 0x1802
	st_dpiw WA, 0xF1
	ldb a, 0x8
	lda_dpi XBC, 0xF0
	stda32 4376, xix
	ldda8 l, 64610
	xor h, h
	pushw bc
	ldda8 b, 64611
	and b, 0x1
	xor c, c
	or hl, bc
	popw bc
	call SMF_CalcTempoRate
	call SMF_OutputCommandSeq
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_Setup_FileUnderflow
	pop xbc
	pop xwa
	jp SMF_Setup_WriteLoop

SMF_Setup_FileUnderflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_Setup_WriteLoop:
	ld xiy, 0xF2827C
	cpdi8 4324, 0
	jr nz, SMF_Setup_SelectTablePtr
	ld xiy, 0xF28284

SMF_Setup_SelectTablePtr:
	ldda32 xix, 4376
	ldw bc, 0x8

SMF_WriteChannelDataLoop:
	ld_spib A, 0xF4
	lda_dpi XBC, 0xF0
	pushw bc
	push xiy
	push xix
	call SMF_WriteByte
	pop xix
	pop xiy
	popw bc
	ldda32 xix, 4376
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteChannel_FileUnderflow
	pop xbc
	pop xwa
	jp SMF_WriteChannel_Continue

SMF_WriteChannel_FileUnderflow:
	pop xbc
	pop xwa
	jrl SMF_FlushAndFinalize

SMF_WriteChannel_Continue:
	djnz xbc, SMF_WriteChannelDataLoop
	stda32 4376, xix
	cpdi8 6709, 0
	jrl z, SMF_FinishChannelAndGetNextEvent
	call BitMapOut_ComputeRegionDelta
	stdi8 10359, 0

SMF_ScanAndProcessChannel:
	ld xiy, 0xF460
	xor hl, hl
	ldda8 l, 10359
	ld c, l
	ldda16 xde, 4325
	ld a, c
	scf
	xorcf_a_16 de
	jrl c, SMF_AdvanceChannelScan
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	pop xix
	ld b, l
	sla l, 1
	push xix
	ld xix, 0xF28254
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	pop xix
	cp hl, 0xFFFF
	jrl z, SMF_AdvanceChannelScan
	cps c, 0
	jr z, SMF_WriteChannelNoteData
	push xhl
	xor hl, hl

SMF_ScanChannel_PopAndWrite:
	pop xhl
	jr SMF_WriteChannelNoteData
	cp l, c
	jr z, SMF_ScanChannel_PopAndWrite
	pop xhl
	jrl SMF_FinishChannelAndGetNextEvent

SMF_WriteChannelNoteData:
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld c, (xiy + 256)
	ld d, (xiy + 1)
	ld b, (xiy + 3)
	ld e, (xiy + 4)
	ld a, (xiy + 5)
	stda8 4359, a
	ld a, (xiy + 7)
	stda8 4332, a
	anddi8 10359, 15
	ldda8 l, 10359
	xor h, h
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	pop xix
	cpdi8 4324, 255
	jrl nz, SMF_WriteNote_AltPath
	call SMF_ResolveGlobalChannel
	ldda8 a, 6881
	or a, 0xC0
	ld l, c
	stda8 6746, l
	stda8 6747, d
	ld l, (xiy - 2)
	stda8 6748, l
	pushw bc
	pushw de
	ld xwa, 0x1A57
	call SndParam_InitBufferConverge
	popw de
	popw bc
	ldda8 a, 6881
	or a, 0xB0
	xor w, w
	ldda8 l, 6744
	pushw wa
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow1
	pop xbc
	pop xwa
	jp SMF_WriteNote_BankSelect

SMF_WriteNote_FileUnderflow1:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_BankSelect:
	ldb w, 0x20
	ldda8 l, 6743
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow2
	pop xbc
	pop xwa
	jp SMF_WriteNote_ProgramChange

SMF_WriteNote_FileUnderflow2:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_ProgramChange:
	ldda8 a, 6881
	or a, 0xC0
	ldda8 w, 6745
	and w, 0x7F
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow3
	pop xbc
	pop xwa
	jp SMF_WriteChannelVolume

SMF_WriteNote_FileUnderflow3:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_AltPath:
	call SMF_ResolveGlobalChannel
	ldda8 a, 6881
	or a, 0xB0
	ldb w, 0x0
	ld l, c
	rlc l
	and l, 0x1
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow4
	pop xbc
	pop xwa
	jp SMF_WriteNote_BankSelectLSB

SMF_WriteNote_FileUnderflow4:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_BankSelectLSB:
	ldda8 a, 6881
	or a, 0xB0
	ldb w, 0x20
	ld l, d
	and l, 0x7
	sla l, 4
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow5
	pop xbc
	pop xwa
	jp SMF_WriteNote_ProgramNumber

SMF_WriteNote_FileUnderflow5:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_ProgramNumber:
	ldda8 a, 6881
	or a, 0xC0
	ld w, c
	and w, 0x7F
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteNote_FileUnderflow6
	pop xbc
	pop xwa
	jp SMF_WriteChannelVolume

SMF_WriteNote_FileUnderflow6:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteChannelVolume:
	ldda8 a, 6881
	or a, 0xB0
	ldb w, 0x7
	ld l, b
	pushw wa
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteVol_FileUnderflow1
	pop xbc
	pop xwa
	jp SMF_WriteVol_Chorus

SMF_WriteVol_FileUnderflow1:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteVol_Chorus:
	ldb w, 0x5D
	ldda8 l, 4359
	pushw wa
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteVol_FileUnderflow2
	pop xbc
	pop xwa
	jp SMF_WriteVol_SustainPedal

SMF_WriteVol_FileUnderflow2:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteVol_SustainPedal:
	ldb w, 0x40
	ldb l, 0x7F
	bit 3, e
	jr nz, SMF_WriteVol_SustainValue
	ldb l, 0x0

SMF_WriteVol_SustainValue:
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteVol_FileUnderflow3
	pop xbc
	pop xwa
	jp SMF_WriteVol_Reverb

SMF_WriteVol_FileUnderflow3:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteVol_Reverb:
	ldb w, 0x5B
	ldda8 l, 4332
	and l, 0x7F
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteVol_FileUnderflow4
	pop xbc
	pop xwa
	jp SMF_WriteVol_PanAndPitch

SMF_WriteVol_FileUnderflow4:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteVol_PanAndPitch:
	ldda8 l, 10359
	xor h, h
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	pop xix
	cp l, 0xC
	jrl z, SMF_AdvanceChannelScan
	ld b, l
	xor h, h
	sla l, 1
	push xix
	ld xix, 0xF28254
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	pop xix
	cp hl, 0xFFFF
	jrl z, SMF_AdvanceChannelScan
	ldda8 a, 6881
	or a, 0xB0
	ld c, l
	ld xiy, 0xF460
	ldfr_lerp XIY, 0x38
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld l, (xiy + 8)
	ldto_lerp XIY, 0x38
	ldb w, 0xA
	pushw wa
	pushw bc
	call SMF_WriteByteLoop
	popw bc
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow1
	pop xbc
	pop xwa
	jp SMF_WriteRPN_MSBZero

SMF_WriteRPN_FileUnderflow1:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_MSBZero:
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow2
	pop xbc
	pop xwa
	jp SMF_WriteRPN_LSBOne

SMF_WriteRPN_FileUnderflow2:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_LSBOne:
	ldb w, 0x64
	ldb l, 0x1
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow3
	pop xbc
	pop xwa
	jp SMF_WriteRPN_FineTune

SMF_WriteRPN_FileUnderflow3:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_FineTune:
	ldda8 l, 10359
	xor h, h
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	sla hl, 1
	ld xix, 0xF28254
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	pop xix
	ld xiy, 0xF460
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld l, (xiy + 10)
	ld c, l
	srl l, 1
	and l, 0x7F
	ldb w, 0x6
	pushw wa
	pushw bc
	call SMF_WriteByteLoop
	popw bc
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow4
	pop xbc
	pop xwa
	jp SMF_WriteRPN_FineTuneLSB

SMF_WriteRPN_FileUnderflow4:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_FineTuneLSB:
	ld l, c
	and l, 0x1
	rrc_i_8 l, 2
	ldb w, 0x26
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow5
	pop xbc
	pop xwa
	jp SMF_WriteRPN_MSBZero2

SMF_WriteRPN_FileUnderflow5:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_MSBZero2:
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow6
	pop xbc
	pop xwa
	jp SMF_WriteRPN_LSBTwo

SMF_WriteRPN_FileUnderflow6:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_LSBTwo:
	ldb w, 0x64
	ldb l, 0x2
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow7
	pop xbc
	pop xwa
	jp SMF_WriteRPN_CoarseTune

SMF_WriteRPN_FileUnderflow7:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_CoarseTune:
	ldda8 l, 10359
	xor h, h
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	sla l, 1
	ld xix, 0xF28254
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	pop xix
	ld xiy, 0xF460
	ldfr_lerp XIY, 0x38
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld l, (xiy + 9)
	ldto_lerp XIY, 0x38
	ldb w, 0x6
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow8
	pop xbc
	pop xwa
	jp SMF_WriteRPN_CoarseTuneLSB

SMF_WriteRPN_FileUnderflow8:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_CoarseTuneLSB:
	ldb w, 0x26
	xor l, l
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow9
	pop xbc
	pop xwa
	jp SMF_WriteRPN_MSBZero3

SMF_WriteRPN_FileUnderflow9:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_MSBZero3:
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow10
	pop xbc
	pop xwa
	jp SMF_WriteRPN_LSBZero

SMF_WriteRPN_FileUnderflow10:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_LSBZero:
	ldb w, 0x64
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow11
	pop xbc
	pop xwa
	jp SMF_WriteRPN_Transpose

SMF_WriteRPN_FileUnderflow11:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_Transpose:
	ldda8 l, 10359
	xor h, h
	push xix
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	sla l, 1
	ld xix, 0xF28254
	ld_sriw3 HL, 0x07, 0xF0, 0xEC
	pop xix
	ld xiy, 0xF460
	st_dri3b E, 0x07, 0xF4, 0xEC
	ld l, (xiy + 11)
	ldb w, 0x6
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow12
	pop xbc
	pop xwa
	jp SMF_WriteRPN_TransposeLSB

SMF_WriteRPN_FileUnderflow12:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteRPN_TransposeLSB:
	ldb w, 0x26
	xor l, l
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_WriteRPN_FileUnderflow13
	pop xbc
	pop xwa
	jp SMF_AdvanceChannelScan

SMF_WriteRPN_FileUnderflow13:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_AdvanceChannelScan:
	incdi8 1, 10359
	cpdi8 10359, 15
	jrl ule, SMF_ScanAndProcessChannel

SMF_FinishChannelAndGetNextEvent:
	call SMF_ChannelHelperReturn
	xor wa, wa
	stda16 3942, xwa
	stda16 3944, xwa
	call SMF_GetNextEvent
	cp a, 0x82
	jr z, SMF_ResetEventTimers
	cp a, 0x84
	jr z, SMF_ResetEventTimers
	cp a, 0x81
	jr z, SMF_ResetEventTimers
	push_sd16w 0xAF, 0x28
	push_sd16w 0x66, 0x26
	call SMF_AdvancePosition
	call SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xAF, 0x28
	stda8 3944, a

SMF_ResetEventTimers:
	stdi16 3946, 0
	stdi16 3938, 0
	stdi16 3940, 0

; ============================================================================
; SMF_ProcessEventLoop - Process MIDI events from sequence data
; ============================================================================
; Reads and dispatches MIDI-style events in a loop:
;   0x90 = Note On, 0xA0 = Aftertouch, 0xB0 = Control Change,
;   0xC0 = Program Change, 0xD0 = Channel Pressure, 0xE0 = Pitch Bend,
;   0xF0 = System, 0x81-0x86 = Meta events
; Calls SMF_GetNextEvent and SMF_AdvancePosition internally.
; ============================================================================
SMF_ProcessEventLoop:
	xor xhl, xhl
	push xhl
	call VoiceChannel_ClearParamTable
	call SMF_GetNextEvent
	pop xhl
	cp a, 0x82
	jrl z, SMF_IncrementPosition

SMF_EventLoop_ReadDataBytes:
	push xde
	ld xde, 0x1073
	lda_dri3 XBC, 0x07, 0xE8, 0xEC
	pop xde
	push xhl
	call SMF_AdvancePosition
	call SMF_GetNextEvent
	pop xhl
	inc 1, hl
	bit 7, a
	jr z, SMF_EventLoop_ReadDataBytes
	ldda8 a, 4211
	cp a, 0x82
	jrl z, SMF_IncrementPosition
	cp a, 0x84
	jrl z, SMF_IncrementPosition
	cp a, 0x81
	jr z, SMF_MetaTiming_IncrementCount
	cp a, 0x85
	jrl z, SMF_ProcessEventLoop
	cp a, 0x86
	jrl z, SMF_ProcessEventLoop
	ld w, a
	and w, 0xF0
	cp w, 0x90
	jrl z, SMF_NoteOn_Handler
	cp w, 0xB0
	jrl z, SMF_ControlChange_Handler
	cp w, 0xC0
	jrl z, SMF_ProgramChange_Handler
	cp w, 0xD0
	jrl z, SMF_ChannelPressure_Handler
	cp w, 0xF0
	jrl z, SMF_SystemExclusive_Handler
	cp w, 0xA0
	jrl z, SMF_PolyAftertouch_Dispatch
	cp w, 0xE0
	jrl z, SMF_PitchBend_Handler
	jrl SMF_ProcessEventLoop

SMF_MetaTiming_IncrementCount:
	incdi16 1, 3946

SMF_MetaTiming_GetNextLoop:
	call SMF_GetNextEvent
	cp a, 0x81
	jr nz, SMF_MetaTiming_ApplyMultiplier
	incdi16 1, 3946
	call SMF_AdvancePosition
	jr SMF_MetaTiming_GetNextLoop

SMF_MetaTiming_ApplyMultiplier:
	ldda16 xwa, 3946
	ldw de, 0x60
	mul xwa, xde
	ldto_werp DE, 0xE2
	adddm16 3938, xwa
	stda16 3940, xde
	stdi16 3946, 0
	jrl SMF_ProcessEventLoop

SMF_PolyAftertouch_Dispatch:
	cps hl, 3
	jr z, SMF_PolyAftertouch_3Byte_CalcTime
	cps hl, 4
	jrl nz, SMF_ProcessEventLoop
	ldda8 c, 4212
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_PolyAftertouch_4Byte_Underflow
	pop xbc
	pop xwa
	jp SMF_PolyAftertouch_4Byte_WriteOutput

SMF_PolyAftertouch_4Byte_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_PolyAftertouch_4Byte_WriteOutput:
	ldda16 xhl, 4213
	and l, 0x7F
	and h, 0x1
	rrc h
	and h, 0x80
	or l, h
	xor h, h
	pushw wa
	ldda8 w, 4214
	and w, 0x2
	srl w, 1
	xor a, a
	or hl, wa
	popw wa
	call SMF_CalcTempoRate
	call SMF_OutputCommandSeq
	jrl SMF_ProcessEventLoop

SMF_PolyAftertouch_3Byte_CalcTime:
	ldda8 c, 4212
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_PolyAftertouch_3Byte_Underflow
	pop xbc
	pop xwa
	jp SMF_PolyAftertouch_3Byte_SendStatus

SMF_PolyAftertouch_3Byte_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_PolyAftertouch_3Byte_SendStatus:
	and a, 0xF
	or a, 0xD0
	ldda8 w, 4213
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_PolyAftertouch_3Byte_WriteUnderflow
	pop xbc
	pop xwa
	jp SMF_PolyAftertouch_3Byte_Done

SMF_PolyAftertouch_3Byte_WriteUnderflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_PolyAftertouch_3Byte_Done:
	jrl SMF_ProcessEventLoop

SMF_ChannelPressure_Handler:
	cps hl, 3
	jrl nz, SMF_ProcessEventLoop
	ldda8 c, 4212
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ChannelPressure_Underflow
	pop xbc
	pop xwa
	jp SMF_ChannelPressure_WriteCC

SMF_ChannelPressure_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ChannelPressure_WriteCC:
	and a, 0xF
	or a, 0xB0
	ldb w, 0x1
	ldda8 l, 4213
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ChannelPressure_WriteUnderflow
	pop xbc
	pop xwa
	jp SMF_ChannelPressure_Done

SMF_ChannelPressure_WriteUnderflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ChannelPressure_Done:
	jrl SMF_ProcessEventLoop

SMF_PitchBend_Handler:
	cps hl, 4
	jrl nz, SMF_ProcessEventLoop
	ldda8 c, 4212
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_PitchBend_Underflow
	pop xbc
	pop xwa
	jp SMF_PitchBend_WriteCC_MSB

SMF_PitchBend_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_PitchBend_WriteCC_MSB:
	ldda8 w, 4213
	ldda8 l, 4214
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_PitchBend_WriteCC_MSB_Underflow
	pop xbc
	pop xwa
	jp SMF_PitchBend_WriteCC_LSB

SMF_PitchBend_WriteCC_MSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_PitchBend_WriteCC_LSB:
	jrl SMF_ProcessEventLoop

SMF_SystemExclusive_Handler:
	cps hl, 3
	jrl nz, SMF_ProcessEventLoop
	ld l, a
	and l, 0xF
	xor h, h
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xEC, 0x0F
	pop xix
	jrl z, SMF_ProcessEventLoop
	ldda8 c, 4212
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SystemExclusive_Underflow
	pop xbc
	pop xwa
	jp SMF_SystemExclusive_WriteCC_MSB

SMF_SystemExclusive_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_SystemExclusive_WriteCC_MSB:
	and a, 0xF
	or a, 0xB0
	ldb w, 0xB
	ldda8 l, 4213
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SystemExclusive_WriteCC_MSB_Underflow
	pop xbc
	pop xwa
	jp SMF_SystemExclusive_Done

SMF_SystemExclusive_WriteCC_MSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_SystemExclusive_Done:
	jrl SMF_ProcessEventLoop

SMF_NoteOn_Handler:
	cps hl, 6
	jrl nz, SMF_ProcessEventLoop
	xor xhl, xhl

SMF_NoteOn_FindVoiceSlot:
	push xde
	ld xde, 0x11F9
	bit_dri 7, 0x07, 0xE8, 0xEC
	pop xde
	jr z, SMF_NoteOn_SlotFound
	add hl, 0x5
	cp hl, 0xA0
	jr ule, SMF_NoteOn_FindVoiceSlot
	push xiy
	push xix
	push xwa
	push xbc
	push xde
	push xhl
	push xiz
	ldda8 c, 4212
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xiz
	pop xhl
	pop xde
	pop xbc
	pop xwa
	pop xix
	pop xiy
	jrl SMF_ProcessEventLoop

SMF_NoteOn_SlotFound:
	ordi8 4236, 1
	pushw hl
	ldda8 c, 4212
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_NoteOn_SlotFound_Underflow
	pop xbc
	pop xwa
	jp SMF_NoteOn_WriteEventBytes

SMF_NoteOn_SlotFound_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_NoteOn_WriteEventBytes:
	pushw hl
	ldda8 a, 4211
	ldda8 w, 4213
	ldda8 l, 4214
	call SMF_WriteByteLoop
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_NoteOn_WriteEvent_Underflow
	pop xbc
	pop xwa
	jp SMF_NoteOn_StoreVoiceData

SMF_NoteOn_WriteEvent_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_NoteOn_StoreVoiceData:
	ld xix, 0x11F9
	st_dri3b D, 0x07, 0xF0, 0xEC
	ldb a, 0x80
	lda_dpi XBC, 0xF0
	ldda8 a, 4211
	lda_dpi XBC, 0xF0
	ldda8 a, 4213
	lda_dpi XBC, 0xF0
	ldda8 a, 4216
	ldb w, 0x60
	muls8rr a, w
	xor hl, hl
	ldda8 l, 4215
	add wa, hl
	st_dpiw WA, 0xF1
	jrl SMF_ProcessEventLoop

SMF_ProgramChange_Handler:
	cps hl, 6
	jrl nz, SMF_ProcessEventLoop
	cpdi8 4213, 127
	jrl z, SMF_ProcessEventLoop
	ldda8 a, 4214
	cps a, 0
	jrl nz, SMF_ProcessEventLoop
	cpdi8 6709, 0
	jr z, SMF_ProgramChange_CalcTime
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_ProgramChange_CalcTime:
	ldda8 c, 4212
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_ProcessPatch

SMF_ProgramChange_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_ProcessPatch:
	cpdi8 4324, 0
	jrl z, SMF_ProgramChange_DirectWrite
	ldda8 l, 4211
	ld h, l
	and l, 0x1
	rrc l
	ldda8 a, 4215
	or l, a
	stda8 6746, l
	ldda8 l, 4211
	and l, 0x2
	rrc_i_8 l, 2
	ldda8 a, 4216
	and a, 0x7F
	or a, l
	stda8 6747, a
	push xix
	xor hl, hl
	ldda8 l, 4213
	ld xix, 0xF1A0
	ld_srib3 L, 0x07, 0xF0, 0xEC
	ld xix, 0xF2828C
	ld_srib3 L, 0x07, 0xF0, 0xEC
	stda8 6748, l
	pop xix
	ld xwa, 0x1A57
	call SndParam_InitBufferConverge
	ldb a, 0xB0
	ldda8 w, 4213
	or a, w
	xor w, w
	ldda8 l, 6744
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_WriteBankMSB_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_WriteBankMSB_Data

SMF_ProgramChange_WriteBankMSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WriteBankMSB_Data:
	stdi16 4206, 0
	stdi8 4208, 0
	ldb w, 0x20
	ldda8 l, 6743
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_WriteBankLSB_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_WriteBankLSB_Data

SMF_ProgramChange_WriteBankLSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WriteBankLSB_Data:
	ldb a, 0xC0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldda8 w, 6745
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_WriteVolume_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_WriteVolume_Data

SMF_ProgramChange_WriteVolume_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WriteVolume_Data:
	jrl SMF_ProcessEventLoop

SMF_ProgramChange_DirectWrite:
	ldb w, 0x0
	ldda8 l, 4211
	and l, 0x1
	call SMF_SendChannelConfig
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_SendConfig_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_SendConfig_Data

SMF_ProgramChange_SendConfig_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_SendConfig_Data:
	stdi16 4206, 0
	stdi8 4208, 0
	ldb w, 0x20
	ldda8 h, 4211
	and h, 0xC
	ldda8 l, 4214
	srl l, 5
	and l, 0x3
	or l, h
	sla l, 4
	and l, 0x7F
	ldda8 l, 4216
	and l, 0x7
	sla l, 4
	call SMF_SendChannelConfig
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_WritePatch_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_WritePatchByte

SMF_ProgramChange_WritePatch_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WritePatchByte:
	ldb a, 0xC0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldda8 w, 4215
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ProgramChange_WritePatch_Done_Underflow
	pop xbc
	pop xwa
	jp SMF_ProgramChange_WritePatch_Done

SMF_ProgramChange_WritePatch_Done_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WritePatch_Done:
	jrl SMF_ProcessEventLoop

SMF_ControlChange_Handler:
	cps hl, 6
	jrl nz, SMF_ProcessEventLoop
	cpdi8 4213, 127
	jrl z, SMF_ProcessEventLoop_Entry
	ldda8 l, 4214
	ldda8 a, 4213
	jrl SMF_ControlChange_ValidateRange
	ldda8 l, 4214
	cp l, 0x7F
	jrl z, SMF_ProcessEventLoop_Entry
	and l, 0x1F
	cps l, 0
	jrl c, SMF_ProcessEventLoop_Entry
	cp l, 0xF
	jrl ugt, SMF_ProcessEventLoop_Entry
	jrl SMF_ProcessEventLoop
	jrl SMF_ProcessEventLoop
	jrl SMF_ProcessEventLoop
	jrl SMF_ProcessEventLoop
	jrl SMF_ProcessEventLoop
	jrl SMF_ProcessEventLoop

SMF_ControlChange_ValidateRange:
	cps l, 3
	jrl c, SMF_ProcessEventLoop
	cp l, 0xB
	jrl ugt, SMF_ProcessEventLoop
	ldb a, 0xB0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldb w, 0x7
	cps l, 3
	jrl z, SMF_CC_Volume_Handler
	cps l, 4
	jrl z, SMF_CC_Portamento_CheckBit3
	cps l, 5
	jrl z, SMF_CC_Reverb_Handler
	cps l, 7
	jrl z, SMF_CC_Chorus_Handler
	cp l, 0x8
	jrl z, SMF_CC_Pan_Handler
	cp l, 0x9
	jrl z, SMF_CC_Modulation_Handler
	cp l, 0xA
	jr z, SMF_CC_RPN_Handler
	cp l, 0xB
	jrl z, SMF_CC_PitchBendSens_Handler
	jrl nz, SMF_ProcessEventLoop

SMF_CC_RPN_Handler:
	cpdi8 6709, 0
	jrl z, SMF_CC_RPN_CalcTime
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_RPN_CalcTime:
	ldda8 c, 4212
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_RPN_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_RPN_WriteCC101

SMF_CC_RPN_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_RPN_WriteCC101:
	ldb a, 0xB0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_RPN_WriteCC101_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_RPN_WriteCC100

SMF_CC_RPN_WriteCC101_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_RPN_WriteCC100:
	ldb w, 0x64
	ldb l, 0x1
	stdi8 4206, 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_RPN_WriteCC100_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_RPN_WriteCC6_DataEntry

SMF_CC_RPN_WriteCC100_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_RPN_WriteCC6_DataEntry:
	ldb w, 0x6
	ldda8 l, 4215
	ldda8 h, 4211
	and h, 0x1
	rrc_i_8 h, 2
	srl l, 1
	or l, h
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_RPN_WriteCC6_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_RPN_WriteCC38_DataEntryLSB

SMF_CC_RPN_WriteCC6_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_RPN_WriteCC38_DataEntryLSB:
	ldb w, 0x26
	ldda8 l, 4215
	and l, 0x1
	rrc_i_8 l, 2
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_RPN_WriteCC38_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_RPN_Done

SMF_CC_RPN_WriteCC38_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_RPN_Done:
	jrl SMF_ProcessEventLoop

SMF_CC_PitchBendSens_Handler:
	cpdi8 6709, 0
	jrl z, SMF_CC_PitchBendSens_CalcTime
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_PitchBendSens_CalcTime:
	ldda8 c, 4212
	pushw wa
	pushw hl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw hl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_PitchBendSens_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_PitchBendSens_WriteCC101

SMF_CC_PitchBendSens_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_PitchBendSens_WriteCC101:
	ldb a, 0xB0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_PitchBendSens_WriteCC101_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_PitchBendSens_WriteCC100

SMF_CC_PitchBendSens_WriteCC101_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_PitchBendSens_WriteCC100:
	ldb w, 0x64
	ldb l, 0x0
	stdi8 4206, 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_PitchBendSens_WriteCC100_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_PitchBendSens_WriteCC6

SMF_CC_PitchBendSens_WriteCC100_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_PitchBendSens_WriteCC6:
	ldb w, 0x6
	ldda8 l, 4215
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_PitchBendSens_WriteCC6_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_PitchBendSens_WriteCC38

SMF_CC_PitchBendSens_WriteCC6_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_PitchBendSens_WriteCC38:
	ldb w, 0x26
	ldb l, 0x0
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_PitchBendSens_WriteCC38_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_PitchBendSens_Done

SMF_CC_PitchBendSens_WriteCC38_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_PitchBendSens_Done:
	jrl SMF_ProcessEventLoop

SMF_CC_Modulation_Handler:
	cpdi8 6709, 0
	jrl z, SMF_CC_Modulation_CalcTime
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Modulation_CalcTime:
	ldda8 c, 4212
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Modulation_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Modulation_WriteCC101

SMF_CC_Modulation_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Modulation_WriteCC101:
	ldb a, 0xB0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldb w, 0x65
	ldb l, 0x0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Modulation_WriteCC101_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Modulation_WriteCC100

SMF_CC_Modulation_WriteCC101_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Modulation_WriteCC100:
	ldb w, 0x64
	ldb l, 0x2
	stdi8 4206, 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Modulation_WriteCC100_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Modulation_WriteCC6

SMF_CC_Modulation_WriteCC100_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Modulation_WriteCC6:
	ldb w, 0x6
	ldda8 l, 4215
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Modulation_WriteCC6_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Modulation_WriteCC38

SMF_CC_Modulation_WriteCC6_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Modulation_WriteCC38:
	ldb w, 0x26
	ldb l, 0x0
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Modulation_WriteCC38_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Modulation_Done

SMF_CC_Modulation_WriteCC38_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Modulation_Done:
	jrl SMF_ProcessEventLoop

SMF_CC_Pan_Handler:
	cpdi8 6709, 0
	jr z, SMF_CC_Pan_CalcTime
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Pan_CalcTime:
	ldda8 c, 4212
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Pan_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Pan_WriteCC10

SMF_CC_Pan_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Pan_WriteCC10:
	ldb a, 0xB0
	ldda8 w, 4213
	and w, 0xF
	or a, w
	ldb w, 0xA
	ldda8 l, 4215
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_CC_Pan_WriteCC10_Underflow
	pop xbc
	pop xwa
	jp SMF_CC_Pan_Done

SMF_CC_Pan_WriteCC10_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_CC_Pan_Done:
	jrl SMF_ProcessEventLoop

SMF_CC_Portamento_CheckBit3:
	ldda16 xbc, 4215
	bit 3, b
	jr nz, SMF_CC_Sustain_CheckBits
	jrl SMF_ProcessEventLoop

SMF_CC_Reverb_Handler:
	cpdi8 6709, 0
	jr z, SMF_CC_Reverb_SetupCC93
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Reverb_SetupCC93:
	ldb w, 0x5D
	ldda8 l, 4215
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Sustain_CheckBits:
	ldda16 xbc, 4215
	bit 3, b
	jrl z, SMF_ProcessEventLoop
	cpdi8 6709, 0
	jr z, SMF_CC_Sustain_SetCC64Value
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Sustain_SetCC64Value:
	ldb w, 0x40
	ldb l, 0x0
	bit 3, c
	jr z, SMF_ProcessTimedEvent_Continue
	ldb l, 0x7F
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Chorus_Handler:
	ldb w, 0x5B
	ldb l, 0x0
	cpdi8 6709, 0
	jr z, SMF_CC_Chorus_SetupCC91
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Chorus_SetupCC91:
	ldda8 l, 4215
	and l, 0x7F
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Volume_Handler:
	cpdi8 6709, 0
	jr z, SMF_ProcessTimedEvent_Entry
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

	.include "sequencer/smf_config_routines.s"
	.include "sequencer/sequencer_ui.s"
	.include "sequencer/sequencer_engine.s"

FileOpen:
	lda xsp, (xsp - 16)
	push xiz
	ld xbc, (xsp + 28)
	ld xwa, (xsp + 24)
	or xwa, xwa
	jrl z, FileOpen_ErrorNoFile
	lda_24 xwa, 0xf4f05a
	st32_24 0x0210f6, xwa
	ld (xsp + 4), 0x4
	cp (xbc), 0x0
	jr z, FileOpen_AllocBuffer

FileOpen_ParseModeLoop:
	ld_spib A, 0xE4
	exts wa
	cp wa, 0x64
	jr z, FileOpen_ModeD
	cp wa, 0x7E
	jr z, FileOpen_ModeTilde
	cp wa, 0x62
	jr z, FileOpen_ModeB
	cp wa, 0x2B
	jr z, FileOpen_ModePlus
	cp wa, 0x61
	jr z, FileOpen_ModeA
	cp wa, 0x77
	jr z, FileOpen_ModeW
	cp wa, 0x72
	jr nz, FileOpen_ParseModeNext
	setm 0, (xsp + 4)
	jr FileOpen_ParseModeNext

FileOpen_ModeW:
	ormi8 (xsp + 4), 0x92
	jr FileOpen_ParseModeNext

FileOpen_ModeA:
	ormi8 (xsp + 4), 0x8A
	jr FileOpen_ParseModeNext

FileOpen_ModePlus:
	ormi8 (xsp + 4), 0x3
	jr FileOpen_ParseModeNext

FileOpen_ModeB:
	resm 2, (xsp + 4)
	jr FileOpen_ParseModeNext

FileOpen_ModeTilde:
	setm 5, (xsp + 4)
	jr FileOpen_ParseModeNext

FileOpen_ModeD:
	ormi8 (xsp + 4), 0x41
	resm 2, (xsp + 4)

FileOpen_ParseModeNext:
	cp (xbc), 0x0
	jr nz, FileOpen_ParseModeLoop

FileOpen_AllocBuffer:
	ld xwa, (xsp + 24)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	calr SeqStep_MemAllocWrapper
	inc 6, xsp
	ld (xsp + 12), xhl
	or xhl, xhl
	jr nz, FileOpen_CopyFilename
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_CopyFilename:
	ld xwa, (xsp + 24)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 12)
	ld (xsp + 16), xwa

FileOpen_NormalizeName:
	ld xde, (xsp + 16)
	ld xwa, xde
	ld a, (xwa)
	extz wa
	lda_24 xbc, 0xeed778
	ld_srib3 A, 0x07, 0xE4, 0xE0
	bit 1, a
	jr z, FileOpen_NormalizeNoUpper
	ld xwa, (xsp + 16)
	ld a, (xwa)
	exts wa
	sub wa, 0x20
	jr FileOpen_StoreNormChar

FileOpen_ScanForColon:
	ld xwa, (xsp + 16)
	ld_spib C, 0xE0
	ld (xsp + 16), xwa
	cp c, 0x3A
	jr nz, FileOpen_NormalizeName
	lds32 xwa, 1
	sub (xsp + 16), xwa
	ld xwa, (xsp + 16)
	stib_dpi 0xE0, 0x00
	ld (xsp + 16), xwa
	jr FileOpen_MatchDevice

FileOpen_NormalizeNoUpper:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	exts wa

FileOpen_StoreNormChar:
	ld (xde), a
	cps a, 0
	jr nz, FileOpen_ScanForColon

FileOpen_MatchDevice:
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	ld iz, hl
	extz xiz
	ld xwa, (xsp + 28)
	push xwa
	call Strlen
	inc 8, xsp
	ld wa, hl
	extz xwa
	ld xbc, (xsp + 24)
	ld (xsp + 16), xbc
	add (xsp + 16), xwa
	sub (xsp + 16), xiz
	ld (xsp + 6), 0x0
	lda_24 xwa, 0x03e3bc
	ld (xsp + 8), xwa
	ld a, (xsp + 6)
	extz wa
	cpda16_24 xwa, 254942
	jr ge, FileOpen_DeviceFound

FileOpen_DeviceSearchLoop:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 22)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcmp
	inc 8, xsp
	cps hl, 0
	jr z, FileOpen_DeviceFound
	incm8 1, (xsp + 6)
	ld xwa, 0x22
	add (xsp + 8), xwa
	ld a, (xsp + 6)
	extz wa
	cpda16_24 xwa, 254942
	jr lt, FileOpen_DeviceSearchLoop

FileOpen_DeviceFound:
	ld xwa, (xsp + 12)
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld a, (xsp + 6)
	extz wa
	cpda16_24 xwa, 254942
	jr nz, FileOpen_CheckPermission

FileOpen_ErrorNoFile:
	sti16_24 0x01e53c, 0x0007
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_CheckPermission:
	ld a, (xsp + 4)
	and a, 0xF
	ld c, a
	ld xwa, (xsp + 8)
	ld a, (xwa + 1)
	extz wa
	cpl wa
	and a, c
	jr z, FileOpen_FindFreeSlot
	sti16_24 0x01e53c, 0x0002
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_FindFreeSlot:
	incdi8_24 1, 135412
	ld (xsp + 14), 0x0
	cp (xsp + 14), 0x10
	jr nc, FileOpen_SlotExhausted

FileOpen_SlotSearchLoop:
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	or xwa, xwa
	jr z, FileOpen_SlotExhausted
	incm8 1, (xsp + 14)
	cp (xsp + 14), 0x10
	jr c, FileOpen_SlotSearchLoop

FileOpen_SlotExhausted:
	cp (xsp + 14), 0x10
	jr nz, FileOpen_InitSlot
	sti16_24 0x01e53c, 0x0004
	call SeqStep_FileNopB
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_InitSlot:
	ld a, (xsp + 14)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, 0x0210b4
	ld xwa, 0xFFFFFFFF
	st_dri3l XWA, 0x07, 0xE8, 0xE4
	call SeqStep_FileNopB
	pushw 0x4B
	calr SeqStep_MemAllocWrapper
	inc 2, xsp
	ld xwa, (xsp + 8)
	ld (xwa + 30), xhl
	ld xiz, xhl
	or xiz, xiz
	jr nz, FileOpen_PopulateStruct
	ld a, (xsp + 14)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, 0x0210b4
	lds32 xwa, 0
	st_dri3l XWA, 0x07, 0xE8, 0xE4
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_PopulateStruct:
	ld a, (xsp + 14)
	ld (xiz + 5), a
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 14)
	ld (xiz + 10), xwa
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 18)
	ld (xiz + 14), xwa
	ld xwa, (xsp + 8)
	ld wa, (xwa + 12)
	ld (xiz + 8), wa
	ld xwa, (xsp + 8)
	ld (xiz + 18), xwa
	ld a, (xsp + 6)
	ld (xiz), a
	ld8_24 a, 0x03e2e2
	ld (xiz + 1), a
	ld (xiz + 2), 0xD
	ld a, (xsp + 4)
	ld (xiz + 3), a
	ei 7
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	st_dri3l XIZ, 0x07, 0xE4, 0xE0
	ei 6
	ld xwa, (xsp + 16)
	push xwa
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 16)
	ld xwa, (xwa + 18)
	ld xwa, (xwa)
	call (xwa)
	inc 8, xsp
	cps hl, 0
	jr z, FileOpen_ReturnHandle
	ld a, (xsp + 14)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, 0x0210b4
	lds32 xwa, 0
	st_dri3l XWA, 0x07, 0xE8, 0xE4
	ld a, l
	exts wa
	st16_24 0x01e53c, xwa
	ld xwa, xiz
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	lds32 xiz, 0

FileOpen_ReturnHandle:
	ld xhl, xiz

FileOpen_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

FileRead:
	ld xbc, (xsp + 12)
	or xbc, xbc
	jr z, SeqStep_FileReadSetup
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileReadCheck

SeqStep_FileReadSetup:
	sti16_24 0x01e53c, 0x0011
	lds hl, 0
	ret

SeqStep_FileReadCheck:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadProcess
	sti16_24 0x01e53c, 0x000d
	lds hl, 0
	ret

SeqStep_FileReadProcess:
	ld wa, (xsp + 8)
	mrdw3 0x9F, 0x0A, 0x48
	pushw wa
	ld xwa, (xsp + 6)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 4)
	call (xwa)
	lda xsp, (xsp + 10)
	ld wa, hl
	exts xwa
	mrdw3 0x9F, 0x08, 0x58
	ld hl, wa
	ret

FileWrite:
	ld xbc, (xsp + 12)
	or xbc, xbc
	jr z, SeqStep_FileReadAdvance
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileReadLoop

SeqStep_FileReadAdvance:
	sti16_24 0x01e53c, 0x0011
	lds hl, 0
	ret

SeqStep_FileReadLoop:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileReadDone
	sti16_24 0x01e53c, 0x000d
	lds hl, 0
	ret

SeqStep_FileReadDone:
	ld wa, (xsp + 8)
	mrdw3 0x9F, 0x0A, 0x48
	pushw wa
	ld xwa, (xsp + 6)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 12)
	call (xwa)
	lda xsp, (xsp + 10)
	ld wa, hl
	exts xwa
	mrdw3 0x9F, 0x08, 0x58
	ld hl, wa
	ret

SeqStep_FileReadReturn:
	dec 2, xsp
	ld xbc, (xsp + 6)
	or xbc, xbc
	jr z, SeqStep_FileReadError
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileReadCleanup

SeqStep_FileReadError:
	sti16_24 0x01e53c, 0x0011
	ldw hl, 0xFFFF
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadCleanup:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadComplete
	sti16_24 0x01e53c, 0x000d
	ldw hl, 0xFFFF
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadComplete:
	pushw 0x1
	lda xwa, (xsp + 2)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 4)
	call (xwa)
	add xsp, 0xA
	cps hl, 0
	jr z, SeqStep_FileReadVtableFail
	ld l, (xsp)
	extz hl
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadVtableFail:
	ldw hl, 0xFFFF

SeqStep_FileReadVtableReturn:
	inc 2, xsp
	ret

SeqStep_ByteBlockEF56:
	push	xiz
	ld	xbc, (xsp+14)
	ld	xiz, (xsp+8)
	or	xbc, xbc
	jr	z, 6
	cp	(xbc+4), 0
	jr	nz, 11
	sti16_24	124220, 17
	lds32	xhl, 0
	jr	53
	bitm	0, (xbc+4)
	jr	nz, 11
	sti16_24	124220, 13
	lds32	xhl, 0
	jr	37
	ld	wa, (xsp+12)
	dec	1, wa
	pushw	wa
	push	xiz
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+8)
	call	(xwa)
	lda	xsp, (xsp+10)
	.byte 0xf3, 0x07, 0xf8, 0xec, 0x00, 0x00
	cps	hl, 0
	jr	z, 4
	ld	xhl, xiz
	jr	2
	lds32	xhl, 0
	pop	xiz
	ret

SeqStep_FileWriteSetup:
	dec 2, xsp
	ld xbc, (xsp + 8)
	or xbc, xbc
	jr z, SeqStep_FileWriteNoHandle
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileWriteCheckMode

SeqStep_FileWriteNoHandle:
	sti16_24 0x01e53c, 0x0011
	ldw hl, 0xFFFF
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteCheckMode:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileWriteProcess
	sti16_24 0x01e53c, 0x000d
	ldw hl, 0xFFFF
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteProcess:
	ld wa, (xsp + 6)
	ld (xsp), a
	pushw 0x1
	lda xwa, (xsp + 2)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 12)
	call (xwa)
	add xsp, 0xA
	cps hl, 0
	jr z, SeqStep_FileWriteFail
	ld l, (xsp)
	extz hl
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteFail:
	ldw hl, 0xFFFF

SeqStep_FileWriteReturn:
	inc 2, xsp
	ret

SeqStep_ByteBlockF002:
	ld	xbc, (xsp+8)
	or	xbc, xbc
	jr	z, 6
	cp	(xbc+4), 0
	jr	nz, 11
	sti16_24	124220, 17
	ldw	hl, 65535
	ret
	bitm	1, (xbc+4)
	jr	nz, 11
	sti16_24	124220, 13
	ldw	hl, 65535
	ret
	lds	hl, 0
	ld	xwa, (xsp+4)
	.byte 0xc5, 0xe0, 0x3f, 0x00
	jr	z, 8
	inc	1, hl
	.byte 0xc5, 0xe0, 0x3f, 0x00
	jr	nz, -8
	pushw	hl
	ld	xwa, (xsp+6)
	push	xwa
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+12)
	call	(xwa)
	lda	xsp, (xsp+10)
	ld	wa, hl
	cps	wa, 0
	ret	nz
	ldw	hl, 65535
	ret

FileClose:
	ld xwa, (xsp + 4)
	push xwa
	calr SeqStep_FileCloseInner
	inc 4, xsp
	jp SeqStep_ParseHeaderContinue

SeqStep_FileCloseInner:
	dec 4, xsp
	push xiz
	ld xiz, (xsp + 12)
	or xiz, xiz
	jr z, SeqStep_FileCloseCheck
	cp (xiz + 4), 0x0
	jr z, SeqStep_FileCloseCheck
	ld a, (xiz + 5)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	cp_sril_mr XIZ, 0x07, 0xE4, 0xE0
	jr z, SeqStep_FileCloseProcess

SeqStep_FileCloseCheck:
	sti16_24 0x01e53c, 0x0011
	ldw hl, 0xFFFF
	jrl SeqStep_FileCloseFinal

SeqStep_FileCloseProcess:
	ld xwa, xiz
	push xwa
	ld xwa, (xiz + 14)
	ld xwa, (xwa + 20)
	call (xwa)
	inc 4, xsp
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jr z, SeqStep_FileCloseReturn
	ld wa, (xsp + 4)
	exts wa
	st16_24 0x01e53c, xwa

SeqStep_FileCloseReturn:
	incdi8_24 1, 135412
	ld a, (xiz + 5)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, 0x0210b4
	lds32 xwa, 0
	st_dri3l XWA, 0x07, 0xE8, 0xE4
	ld a, (xiz + 5)
	extz wa
	ld (xsp + 6), wa
	ld xwa, xiz
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld iz, hl
	cps iz, 0
	jr z, SeqStep_FileCloseCleanup
	cpw (xsp + 4), 0x0
	jr nz, SeqStep_FileCloseCleanup
	sti16_24 0x01e53c, 0x0026

SeqStep_FileCloseCleanup:
	ld wa, (xsp + 6)
	add wa, 0x64
	pushw wa
	call SeqStep_FileNopA
	inc 2, xsp
	call SeqStep_FileNopB
	cpw (xsp + 4), 0x0
	jr nz, SeqStep_FileCloseDone
	cps iz, 0
	jr z, SeqStep_FileCloseComplete

SeqStep_FileCloseDone:
	ldw hl, 0xFFFF
	jr SeqStep_FileCloseFinal

SeqStep_FileCloseComplete:
	lds hl, 0

SeqStep_FileCloseFinal:
	pop xiz
	inc 4, xsp
	ret

SeqStep_FileCloseExit:
	dec	4, xsp
	push	xiz
	ld	xbc, (xsp+12)
	lds	iz, 0
	or	xbc, xbc
	jr	z, 42
	cp	(xbc+4), 0
	jr	z, 24
	ld	xwa, (xsp+4)
	push	xwa
	pushw 1
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	jrl	131
	sti16_24	124220, 25
	ldw	hl, 65535
	jr	119
	ld	qiz, 0
	cpw	qiz, 16
	jr	ge, 107
	ld	wa, qiz
	sla	wa, 2
	lda_24	xbc, 135348
	ld_rrl	xwa, xbc, wa
	or	xwa, xwa
	jr	z, 77
	ld	wa, qiz
	sla	wa, 2
	lda_24	xbc, 135348
	ld_rrl	xwa, xbc, wa
	cp	xwa, 4294967295
	jr	z, 53
	ld	xwa, (xsp+4)
	push	xwa
	pushw 1
	ld	wa, qiz
	sla	wa, 2
	lda_24	xbc, 135348
	ld_rrl	xwa, xbc, wa
	push	xwa
	ld	wa, qiz
	sla	wa, 2
	lda_24	xbc, 135348
	ld_rrl	xwa, xbc, wa
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	or	iz, hl
	inc	1, qiz
	cpw	qiz, 16
	jr	lt, -107
	ld	hl, iz
	pop	xiz
	inc	4, xsp
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	nz, 11
	sti16_24	124220, 17
	ldw	hl, 65535
	ret
	lda	xwa, (xsp+8)
	inc	2, xwa
	push	xwa
	pushm	(xsp+12)
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	ret
	ld	xwa, (xsp+4)
	ldw	(xwa+6), 0
	ret

SeqStep_FileNopA:
	ret

SeqStep_FileNopB:
	ret

SeqStep_FreeMemory:
	ld xwa, (xsp + 4)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	ret

SeqStep_MallocWrapper:
	ld xwa, (xsp + 6)
	pushw wa
	call Malloc
	inc 2, xsp
	ret

FileOpenDefault:
	pushw 0xE4
	pushw 0x5016
	ld xwa, (xsp + 8)
	push xwa
	call FileOpen
	inc 8, xsp
	or xhl, xhl
	jr nz, SeqStep_FileOpenSetupVtable
	ldw hl, 0xFFFF
	ret

SeqStep_FileOpenSetupVtable:
	ld xwa, xhl
	push xwa
	ld xwa, (xhl + 14)
	ld xwa, (xwa + 32)
	call (xwa)
	inc 4, xsp
	ret

SeqStep_ByteBlockF245:
	dec	2, xsp
	push	xiz
	ld16_24	wa, 124220
	ld	(xsp+4), wa
	sti16_24	124220, 0
	pushw 228
	pushw 20506
	ld	xwa, (xsp+14)
	push	xwa
	call	16051095
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 19
	push	xiz
	call	16052314
	inc	4, xsp
	sti16_24	124220, 21
	ldw	hl, 65535
	jr	75
	cpdi16_24	124220, 5
	jr	z, 5
	ldw	hl, 65535
	jr	61
	ld	wa, (xsp+4)
	exts	wa
	st16_24	124220, wa
	pushw 228
	pushw 20508
	ld	xwa, (xsp+14)
	push	xwa
	call	16051095
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 5
	ldw	hl, 65535
	jr	24
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xiz+14)
	ld	xwa, (xwa+28)
	call	(xwa)
	ld	(xsp+8), hl
	push	xiz
	call	16052314
	inc	8, xsp
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
	ld	xde, (xsp+4)
	or	xde, xde
	jr	z, 6
	cp	(xde+4), 0
	jr	nz, 11
	sti16_24	124220, 17
	ldw	hl, 17
	ret
	ld	xwa, (xde+18)
	cp	(xwa), 1
	jr	nz, 11
	ld	xbc, (xsp+8)
	ld	xwa, (xde+22)
	ld	(xbc), xwa
	lds	hl, 0
	ret
	sti16_24	124220, 18
	ldw	hl, 18
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, 6
	cp	(xbc+4), 0
	jr	nz, 11
	sti16_24	124220, 17
	ldw	hl, 17
	ret
	ld	xwa, (xsp+8)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+24)
	call	(xwa)
	inc	8, xsp
	cps	hl, 0
	ret	z
	ld	a, l
	exts	wa
	st16_24	124220, wa
	ret

SeqStep_FileSeekSetup:
	ld xde, (xsp + 8)
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekNoHandle
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekProcess

SeqStep_FileSeekNoHandle:
	sti16_24 0x01e53c, 0x0011
	ldw hl, 0x11
	ret

SeqStep_FileSeekProcess:
	ld wa, (xsp + 12)
	cps wa, 2
	jr z, SeqStep_FileSeekDone
	cps wa, 1
	jr z, SeqStep_FileSeekCheck
	cps wa, 0
	jr nz, SeqStep_FileSeekReturn
	ld xwa, xde
	cp xwa, (xbc + 71)
	jr c, SeqStep_FileSeekValidate
	ldw hl, 0x14
	jr SeqStep_FileSeekUpdate

SeqStep_FileSeekValidate:
	ld xwa, xde
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 24)
	call (xwa)
	inc 8, xsp
	jr SeqStep_FileSeekUpdate

SeqStep_FileSeekCheck:
	ld xwa, xde
	add xwa, (xbc + 22)
	cp xwa, (xbc + 71)
	jr c, SeqStep_FileSeekAdvance
	ldw hl, 0x14
	jr SeqStep_FileSeekUpdate

SeqStep_FileSeekAdvance:
	ld xwa, xde
	add xwa, (xbc + 22)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 24)
	call (xwa)
	inc 8, xsp
	jr SeqStep_FileSeekUpdate

SeqStep_FileSeekDone:
	ld xwa, xde
	add xwa, (xbc + 71)
	push xwa
	ld xwa, xbc
	push xwa
	ld xwa, (xbc + 14)
	ld xwa, (xwa + 24)
	call (xwa)
	inc 8, xsp
	jr SeqStep_FileSeekUpdate

SeqStep_FileSeekReturn:
	ldw hl, 0x13

SeqStep_FileSeekUpdate:
	cps hl, 0
	ret z
	ld a, l
	exts wa
	st16_24 0x01e53c, xwa
	ret

SeqStep_FileSeekStore:
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekComplete
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekFinal

SeqStep_FileSeekComplete:
	sti16_24 0x01e53c, 0x0011
	ld xhl, 0xFFFFFFFF
	ret

SeqStep_FileSeekFinal:
	ld xwa, (xbc + 18)
	cp (xwa), 0x1
	jr nz, SeqStep_FileSeekExit
	ld xhl, (xbc + 22)
	ret

SeqStep_FileSeekExit:
	sti16_24 0x01e53c, 0x0012
	ld xhl, 0xFFFFFFFF
	ret

SeqStep_FileSeekError:
	lda xwa, (xsp + 4)
	inc 4, xwa
	push xwa
	pushw 0x14
	ld xwa, (xsp + 10)
	push xwa
	ld xwa, (xsp + 14)
	ld xwa, (xwa + 14)
	ld xwa, (xwa + 36)
	call (xwa)
	lda xsp, (xsp + 10)
	lds32 xwa, 0
	ret

SeqStep_FileSeekCleanup:
	dec 6, xsp
	push xiz
	pushw 0xE4
	pushw 0x5020
	ld xwa, (xsp + 18)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, SeqStep_FileTellReturn
	cpdi16_24 124220, 13
	jr nz, SeqStep_FileTellSetup
	sti16_24 0x01e53c, 0x0000
	pushw 0xE4
	pushw 0x5022
	ld xwa, (xsp + 18)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, SeqStep_FileTellReturn
	cpdi16_24 124220, 13
	jr nz, SeqStep_FileTellReturn
	ldw hl, 0xFFFF
	jrl SeqStep_FileTellExit

SeqStep_FileTellSetup:
	ldw hl, 0xFFFF
	jrl SeqStep_FileTellExit

SeqStep_FileTellReturn:
	pushw 0xE4
	pushw 0x5024
	ld xwa, (xsp + 22)
	push xwa
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, SeqStep_FileTellProcess
	ld xwa, (xsp + 4)
	push xwa
	call FileClose
	push xiz
	call FileClose
	inc 8, xsp
	sti16_24 0x01e53c, 0x0015
	ldw hl, 0xFFFF
	jr SeqStep_FileTellExit

SeqStep_FileTellProcess:
	sti16_24 0x01e53c, 0x0000
	pushw 0xE4
	pushw 0x5026
	ld xwa, (xsp + 22)
	push xwa
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, SeqStep_FileTellDone
	ld xwa, (xsp + 4)
	push xwa
	call FileClose
	inc 4, xsp
	ldw hl, 0xFFFF
	jr SeqStep_FileTellExit

SeqStep_FileTellDone:
	ld xbc, (xiz + 18)
	ld xwa, (xsp + 4)
	cp xbc, (xwa + 18)
	jr z, SeqStep_FileTellComplete
	ld xwa, (xsp + 4)
	push xwa
	call FileClose
	push xiz
	call FileClose
	ld xwa, (xsp + 26)
	push xwa
	calr FileOpenDefault
	lda xsp, (xsp + 12)
	sti16_24 0x01e53c, 0x001a
	ldw hl, 0xFFFF
	jr SeqStep_FileTellExit

SeqStep_FileTellComplete:
	push xiz
	ld xwa, (xsp + 8)
	push xwa
	calr SeqStep_FileSeekError
	ld (xsp + 16), hl
	ld xwa, (xsp + 12)
	push xwa
	call FileClose
	push xiz
	call FileClose
	lda xsp, (xsp + 16)
	ld hl, (xsp + 8)

SeqStep_FileTellExit:
	pop xiz
	inc 6, xsp
	ret

SeqStep_FileTellFinal:
	lda	xsp, (xsp-36)
	push	xiz
	pushw 228
	pushw 20520
	ld	xwa, (xsp+48)
	push	xwa
	call	16051095
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 6
	ldw	hl, 65535
	jrl	149
	ld	xwa, (xiz+26)
	or	xwa, xwa
	jr	nz, 9
	sti16_24	124220, 13
	jr	64
	pushw 0
	ld	xwa, 64
	push	xwa
	push	xiz
	calr	-553
	add	xsp, 10
	cps	hl, 0
	jr	nz, 41
	push	xiz
	pushw 1
	pushw 32
	lda	xwa, (xsp+16)
	push	xwa
	call	16051824
	lda	xsp, (xsp+12)
	cps	hl, 1
	jr	nz, 53
	cp	(xsp+8), 0
	jr	z, 47
	cp	(xsp+8), 229
	jr	z, 19
	sti16_24	124220, 27
	push	xiz
	call	16052314
	inc	4, xsp
	ldw	hl, 65535
	jr	57
	push	xiz
	pushw 1
	pushw 32
	lda	xwa, (xsp+16)
	push	xwa
	call	16051824
	lda	xsp, (xsp+12)
	cps	hl, 1
	jr	z, -53
	ld	xwa, (xsp+4)
	push	xwa
	pushw 21
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xiz+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	add	xsp, 10
	cps	hl, 0
	jr	nz, -62
	push	xiz
	call	16052314
	inc	4, xsp
	pop	xiz
	lda	xsp, (xsp+36)
	ret

SeqStep_FileIoHelper:
	pushw 0x0
	lds32 xwa, 0
	push xwa
	ld xwa, (xsp + 10)
	push xwa
	calr SeqStep_FileSeekSetup
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ldw (xwa + 6), 0x0
	ret

SeqStep_FileIoCheck:
	dec 2, xsp
	push xiz
	ld xhl, (xsp + 18)
	or xhl, xhl
	jr z, SeqStep_FileIoDone
	ld wa, (xsp + 22)
	bit 6, a
	jr z, SeqStep_FileIoAdvance
	ld xiz, xhl

SeqStep_FileIoProcess:
	ld a, (xiz + 22)
	and a, 0x3
	cps a, 3
	jrl nz, SeqStep_FileIoLoopReturn
	push xiz
	calr SeqStep_FileBufferSetup
	inc 4, xsp
	ld (xiz + 20), hl
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl
	cps hl, 0
	jrl z, SeqStep_FileIoLoopReturn
	ld (xiz + 22), 0x0
	ld xhl, xiz
	jrl SeqStep_FileIoPopReturn

SeqStep_FileIoAdvance:
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	cp xwa, (xhl)
	jr nz, SeqStep_FileIoDone
	ld xwa, (xhl + 4)
	cp xwa, (xsp + 14)
	jr nz, SeqStep_FileIoDone
	incm 2, (xhl + 18)
	ld wa, (xsp + 22)
	or (xhl + 22), a
	jrl SeqStep_FileIoPopReturn

SeqStep_FileIoDone:
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr nz, SeqStep_FileIoReturn
	ldw (xsp + 4), 0x1

SeqStep_FileIoReturn:
	lda_24 xwa, 0x02121a
	ld xix, xwa
	lds32 xhl, 0
	lds32 xiz, 0
	ldw de, 0x8000
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0xA
	jr ge, SeqStep_FileIoUpdate

SeqStep_FileIoError:
	cpi8_24 0x03e3e0, 0x00
	jr z, SeqStep_FileIoCleanup
	mrdw3 0x9C, 0x12, 0x7F

SeqStep_FileIoCleanup:
	cpw (xix + 18), 0x0
	jr z, SeqStep_FileIoExit
	decm 1, (xix + 18)

SeqStep_FileIoExit:
	cp (xix + 18), de
	jr nc, SeqStep_FileIoComplete
	ld a, (xix + 22)
	and a, 0x88
	jr nz, SeqStep_FileIoComplete
	ld xiz, xix
	ld de, (xix + 18)

SeqStep_FileIoComplete:
	bitm 0, (xix + 22)
	jr z, SeqStep_FileIoFinal
	ld xbc, (xix)
	ld xwa, (xsp + 10)
	cp xbc, (xwa + 18)
	jr nz, SeqStep_FileIoFinal
	ld xwa, (xsp + 14)
	cp xwa, (xix + 4)
	jr nz, SeqStep_FileIoFinal
	ld xhl, xix

SeqStep_FileIoFinal:
	incm 1, (xsp + 4)
	st_dri3b D, 0xF1, 0x1A, 0x02
	cpw (xsp + 4), 0xA
	jr lt, SeqStep_FileIoError

SeqStep_FileIoUpdate:
	sti8_24 0x03e3e0, 0x00
	or xhl, xhl
	jr z, SeqStep_FileIoValidate
	addmi16 (xhl + 18), 0x14
	ld wa, (xhl + 18)
	bit 15, wa
	jr z, SeqStep_FileIoStore
	sti8_24 0x03e3e0, 0x01

SeqStep_FileIoStore:
	ld wa, (xsp + 22)
	or (xhl + 22), a
	ld xwa, (xsp + 10)
	ld a, (xwa + 5)
	ld (xhl + 23), a
	jrl SeqStep_FileIoPopReturn

SeqStep_FileIoValidate:
	or xiz, xiz
	jrl nz, SeqStep_FileIoProcess
	ld xwa, (xsp + 10)
	ldw (xwa + 6), 0xA

SeqStep_FileIoLoop:
	lds32 xhl, 0
	jrl SeqStep_FileIoPopReturn

SeqStep_FileIoLoopReturn:
	ld xwa, (xsp + 14)
	ld (xiz + 4), xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	ld (xiz), xwa
	ld xwa, (xsp + 10)
	ld a, (xwa + 5)
	ld (xiz + 23), a
	ld xwa, (xsp + 10)
	ld a, (xwa)
	ld (xiz + 24), a
	ldw (xiz + 20), 0x0
	ld wa, (xsp + 22)
	bit 5, a
	jrl nz, SeqStep_FileIoSetupResult
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 10)
	ld xwa, (xwa + 16)
	call (xwa)
	inc 8, xsp
	ld (xiz + 20), hl
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl
	cpw (xiz + 20), 0x0
	jr z, SeqStep_FileIoSetSuccess
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	bitm 1, (xwa + 2)
	jr z, SeqStep_FileIoSetSuccess
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 10)
	ld xwa, (xwa + 16)
	call (xwa)
	inc 8, xsp
	ld (xiz + 20), hl
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	resm 1, (xwa + 2)

SeqStep_FileIoSetSuccess:
	ldw (xsp + 4), 0x1
	jr SeqStep_FileIoRetryCheck

SeqStep_FileIoRetryLoop:
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	ld xwa, (xwa + 26)
	ld wa, (xwa + 48)
	extz xwa
	add (xsp + 14), xwa
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 10)
	ld xwa, (xwa + 16)
	call (xwa)
	inc 8, xsp
	ld (xiz + 20), hl
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl

SeqStep_FileIoRetryCheck:
	cpw (xiz + 20), 0x0
	jr z, SeqStep_FileIoSetupResult
	ld wa, (xsp + 22)
	bit 2, a
	jr z, SeqStep_FileIoSetupResult
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	ld xwa, (xwa + 26)
	ld a, (xwa + 58)
	extz wa
	ld bc, (xsp + 4)
	incm 1, (xsp + 4)
	cp bc, wa
	jr lt, SeqStep_FileIoRetryLoop

SeqStep_FileIoSetupResult:
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	ld xwa, (xwa + 26)
	ld xwa, (xwa + 12)
	ld (xiz + 8), xwa
	cpw (xiz + 20), 0x0
	jr nz, SeqStep_FileIoClearStatus
	ld wa, (xsp + 22)
	res 5, wa
	set 0, wa
	ld (xiz + 22), a
	ldw (xiz + 18), 0x14
	ldw wa, 0x14
	bit 15, wa
	jr z, SeqStep_FileIoSetFlag
	sti8_24 0x03e3e0, 0x01

SeqStep_FileIoSetFlag:
	ld xhl, xiz

SeqStep_FileIoPopReturn:
	pop xiz
	inc 2, xsp
	ret

SeqStep_FileIoClearStatus:
	ld (xiz + 22), 0x0
	ld xwa, (xsp + 10)
	ld bc, (xiz + 20)
	ld (xwa + 6), bc
	jrl SeqStep_FileIoLoop

SeqStep_FileBufferSetup:
	dec 6, xsp
	push xiz
	ld xiz, (xsp + 14)
	ld xwa, xiz
	push xwa
	ld xwa, (xiz + 4)
	push xwa
	ld xwa, (xiz)
	ld xwa, (xwa + 14)
	ld xwa, (xwa + 20)
	call (xwa)
	inc 8, xsp
	ld (xiz + 20), hl
	ld a, (xiz + 23)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xwa + 6), hl
	resm 1, (xiz + 22)
	bitm 2, (xiz + 22)
	jr z, SeqStep_FileBufferCheck
	ld xwa, (xiz + 4)
	ld (xsp + 6), xwa
	ldw (xsp + 4), 0x1
	jr SeqStep_FileBufferInit

SeqStep_FileBufferAlloc:
	ld xwa, (xiz)
	ld xwa, (xwa + 26)
	ld wa, (xwa + 48)
	extz xwa
	add (xsp + 6), xwa
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 10)
	push xwa
	ld xwa, (xiz)
	ld xwa, (xwa + 14)
	ld xwa, (xwa + 20)
	call (xwa)
	inc 8, xsp
	lda xwa, (xiz + 20)
	or (xwa), hl
	ld de, (xwa)
	ld a, (xiz + 23)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xwa + 6), de
	incm 1, (xsp + 4)

SeqStep_FileBufferInit:
	ld xwa, (xiz)
	ld xwa, (xwa + 26)
	ld a, (xwa + 58)
	extz wa
	cp (xsp + 4), wa
	jr lt, SeqStep_FileBufferAlloc

SeqStep_FileBufferCheck:
	cpw (xiz + 20), 0x0
	jr nz, SeqStep_FileBufferDone
	lds hl, 0
	jr SeqStep_FileBufferExit

SeqStep_FileBufferDone:
	cpw (xiz + 20), 0x1F
	jr nz, SeqStep_FileBufferCleanup
	resm 0, (xiz + 22)
	lda_24 xwa, 0x02121a
	ld xbc, xwa
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0xA
	jr ge, SeqStep_FileBufferCleanup

SeqStep_FileBufferReturn:
	bitm 1, (xbc + 22)
	jr z, SeqStep_FileBufferError
	ld xwa, (xiz)
	cp xwa, (xbc)
	jr nz, SeqStep_FileBufferError
	resm 0, (xbc + 22)

SeqStep_FileBufferError:
	incm 1, (xsp + 4)
	st_dri3b A, 0xE5, 0x1A, 0x02
	cpw (xsp + 4), 0xA
	jr lt, SeqStep_FileBufferReturn

SeqStep_FileBufferCleanup:
	ld hl, (xiz + 20)

SeqStep_FileBufferExit:
	pop xiz
	inc 6, xsp
	ret

SeqStep_FileBufferFinal:
	dec	4, xsp
	push	xiz
	ldw	(xsp+4), 0
	lda_24	xwa, 135706
	ld	xiz, xwa
	ldw	(xsp+6), 0
	cpw	(xsp+6), 10
	jr	ge, 58
	ld	a, (xiz+22)
	and	a, 3
	cps	a, 3
	jr	nz, 13
	push	xiz
	calr	-265
	inc	4, xsp
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	cp	a, (xiz+23)
	jr	nz, 9
	bitm	2, (xiz+22)
	jr	nz, 4
	andmi8	(xiz+22), 128
	incm	1, (xsp+6)
	lda	xiz, (xiz+538)
	cpw	(xsp+6), 10
	jr	lt, -58
	ld	hl, (xsp+4)
	pop	xiz
	inc	4, xsp
	ret

SeqStep_FileSectorRead:
	ld xbc, (xsp + 4)
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	ld l, (xde)
	extz hl
	ld xbc, (xsp + 4)
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	ld a, (xde)
	extz wa
	sll wa, 8
	add hl, wa
	ret

SeqStep_FileSectorProcess:
	ld xix, (xsp + 4)
	ld xbc, xix
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	ld a, (xde)
	lds32 xhl, 0
	ld l, a
	ld xbc, xix
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	lds32 xwa, 0
	ld a, (xde)
	sll xwa, 8
	add xhl, xwa
	ld xbc, xix
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	lds32 xwa, 0
	ld a, (xde)
	sll xwa, 0
	add xhl, xwa
	ld xbc, xix
	ld xde, (xbc)
	lds32 xwa, 1
	add (xbc), xwa
	lds32 xwa, 0
	ld a, (xde)
	sll xwa, 8
	sll xwa, 0
	add xhl, xwa
	ret

SeqStep_FileSectorDone:
	ld	xbc, (xsp+6)
	ld	xde, (xbc)
	lds32	xwa, 1
	add	(xbc), xwa
	ld	wa, (xsp+4)
	ldb	w, 0
	ld	(xde), a
	ld	xbc, (xsp+6)
	ld	xde, (xbc)
	lds32	xwa, 1
	add	(xbc), xwa
	ld	wa, (xsp+4)
	srl	wa, 8
	ld	(xde), a
	ret
	ld	xbc, (xsp+8)
	ld	xhl, (xsp+4)
	ld	xde, xbc
	ld	xix, (xde)
	lds32	xwa, 1
	add	(xde), xwa
	ld	xwa, xhl
	and	xwa, 255
	ld	(xix), a
	ld	xde, xbc
	ld	xix, (xde)
	lds32	xwa, 1
	add	(xde), xwa
	ld	xwa, xhl
	srl	xwa, 8
	and	xwa, 255
	ld	(xix), a
	ld	xde, xbc
	ld	xix, (xde)
	lds32	xwa, 1
	add	(xde), xwa
	.byte 0xeb
	.long OscScope_RefreshLoop
	.long AudioCmd_FillToVectors
	nop
	nop
	ld	(xix), a
	ld	xde, (xbc)
	lds32	xwa, 1
	add	(xbc), xwa
	ld	xwa, xhl
	srl	xwa, 8
	srl	xwa, 0
	and	xwa, 255
	ld	(xde), a
	ret

SeqStep_FileSectorComplete:
	dec 4, xsp
	push xiz
	ld xiz, (xsp + 16)
	lda xwa, (xiz + 22)
	ld (xsp + 4), xwa
	pushw 0xB
	ld xwa, xiz
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	call Mem_Copy
	ld xwa, (xsp + 22)
	ld (xwa + 11), 0x0
	ld xwa, (xsp + 22)
	ld c, (xiz + 11)
	ld (xwa + 12), c
	lda xwa, (xsp + 14)
	push xwa
	calr SeqStep_FileSectorRead
	ld xwa, (xsp + 26)
	ld (xwa + 13), hl
	lda xwa, (xsp + 18)
	push xwa
	calr SeqStep_FileSectorRead
	ld xwa, (xsp + 30)
	ld (xwa + 15), hl
	lda xwa, (xsp + 22)
	push xwa
	calr SeqStep_FileSectorRead
	ld xwa, (xsp + 34)
	ld (xwa + 17), hl
	lda xwa, (xsp + 26)
	push xwa
	calr SeqStep_FileSectorProcess
	lda xsp, (xsp + 26)
	ld xwa, (xsp + 12)
	ld (xwa + 19), xhl
	pop xiz
	inc 4, xsp
	ret

SeqStep_FileSectorReturn:
	dec	4, xsp
	push	xiz
	ld	xiz, (xsp+12)
	ld	xwa, (xsp+16)
	ld	(xsp+4), xwa
	pushw 11
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	16715161
	lda	xsp, (xsp+10)
	ld	xwa, (xsp+4)
	ld	c, (xiz+12)
	ld	(xwa+11), c
	ld	xwa, 22
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+13)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+13)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+15)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+15)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+17)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	wa, (xiz+17)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	srl	xwa, 8
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0, 0x31
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	srl	xwa, 0
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xiz+19)
	.byte 0xe8, 0xef
	.long OscScope_DrawWaveform
	ld	c, a
	ld	xwa, (xsp+4)
	ld	(xwa), c
	pop	xiz
	inc	4, xsp
	ret

SeqStep_FileSectorError:
	lda xsp, (xsp - 10)
	push xiz
	ldw (xsp + 12), 0x0
	ld xwa, (xsp + 18)
	ld xwa, (xwa + 30)
	ld (xsp + 4), xwa
	cpw (xwa + 36), 0xFFF
	jr nz, SeqStep_FileSectorCleanup
	ld wa, (xsp + 22)
	mul wa, 0x3
	srl wa, 1
	ld bc, wa
	extz xbc
	jr SeqStep_FileSectorExit

SeqStep_FileSectorCleanup:
	ldw (xsp + 12), 0x1
	ld wa, (xsp + 22)
	extz xwa
	ld xbc, xwa
	add xbc, xbc

SeqStep_FileSectorExit:
	ld xwa, xbc
	and xwa, 0x1FF
	ld (xsp + 8), wa
	ld xiz, xbc
	srl xiz, 9
	ld xwa, (xsp + 4)
	add xiz, (xwa + 24)
	pushw 0x4
	ld xwa, (xsp + 20)
	ld xwa, (xwa + 38)
	push xwa
	push xiz
	ld xwa, (xsp + 28)
	push xwa
	calr SeqStep_FileIoCheck
	lda xsp, (xsp + 14)
	ld xbc, xhl
	ld xwa, (xsp + 18)
	ld (xwa + 38), xbc
	or xhl, xhl
	jr nz, SeqStep_FileSectorFinal
	ld xwa, (xsp + 4)
	ld hl, (xwa + 36)
	dec 8, hl
	jrl SeqStep_FileSectorLoop

SeqStep_FileSectorFinal:
	ld wa, (xsp + 8)
	extz xwa
	add xwa, 0x1A
	add xwa, xhl
	ld a, (xwa)
	extz wa
	ld (xsp + 10), wa
	cpw (xsp + 8), 0x1FF
	jr nz, SeqStep_FileSectorStore
	pushw 0x4
	lds32 xwa, 0
	push xwa
	ld xwa, xiz
	inc 1, xwa
	push xwa
	ld xwa, (xsp + 28)
	push xwa
	calr SeqStep_FileIoCheck
	add xsp, 0xE
	or xhl, xhl
	jr nz, SeqStep_FileSectorUpdate
	ld xwa, (xsp + 4)
	ld hl, (xwa + 36)
	dec 8, hl
	jr SeqStep_FileSectorLoop

SeqStep_FileSectorUpdate:
	ld a, (xhl + 26)
	extz wa
	sll wa, 8
	add (xsp + 10), wa
	jr SeqStep_FileSectorValidate

SeqStep_FileSectorStore:
	ld wa, (xsp + 8)
	inc 1, wa
	extz xwa
	add xwa, 0x1A
	add xwa, xhl
	ld a, (xwa)
	extz wa
	sll wa, 8
	add (xsp + 10), wa

SeqStep_FileSectorValidate:
	cpw (xsp + 12), 0x0
	jr z, SeqStep_FileSectorCheck
	ld hl, (xsp + 10)
	jr SeqStep_FileSectorLoop

SeqStep_FileSectorCheck:
	ld wa, (xsp + 22)
	bit 0, a
	jr z, SeqStep_FileSectorAdvance
	ld hl, (xsp + 10)
	srl hl, 4
	jr SeqStep_FileSectorLoop

SeqStep_FileSectorAdvance:
	ld hl, (xsp + 10)
	and hl, 0xFFF

SeqStep_FileSectorLoop:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeqStep_FileSectorPopReturn:
	dec	2, xsp
	push	xiz
	ld	xwa, (xsp+10)
	ld	xde, (xwa+30)
	cpw	(xde+36), 4095
	jrl	nz, 345
	ld	wa, (xsp+14)
	mul	wa, 3
	srl	wa, 1
	ld	bc, wa
	extz	xbc
	ld	xwa, xbc
	and	xwa, 511
	ld	(xsp+4), wa
	ld	xiz, xbc
	srl	xiz, 9
	add	xiz, (xde+24)
	pushw 6
	ld	xwa, (xsp+12)
	.byte 0xa8
	.ascii "& 8>"
	ld	xwa, (xsp+20)
	push xwa
	.byte 0x1e, 0x0c, 0xf9
	lda	xsp, (xsp+14)
	ld	xbc, xhl
	ld	xwa, (xsp+10)
	ld	(xwa+38), xbc
	or	xhl, xhl
	.byte 0x76, 0x82, 0x01
	ld	wa, (xsp+14)
	bit	0, a
	.byte 0x66, 0x7f
	ld	wa, (xsp+16)
	and	wa, 15
	ld	bc, wa
	sll	bc, 4
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, 26
	add	xwa, xhl
	ld	a, (xwa)
	and	a, 15
	extz	wa
	or	wa, bc
	ld	c, a
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, 26
	add	xwa, xhl
	ld	(xwa), c
	cpw	(xsp+4), 511
	.byte 0x6e, 0x29
	pushw 6
	lds32	xwa, 0
	push xwa
	ld	xwa, xiz
	inc	1, xwa
	push xwa
	ld	xwa, (xsp+20)
	push xwa
	.byte 0x1e, 0xa8, 0xf8
	add	xsp, 14
	or	xhl, xhl
	.byte 0x76, 0x23, 0x01
	ld	wa, (xsp+16)
	srl	wa, 4
	ld	(xhl+26), a
	.byte 0x78, 0x17, 0x01
	ld	wa, (xsp+4)
	inc	1, wa
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	srl	wa, 4
	ld	(xbc), a
	.byte 0x78, 0xfb, 0x00
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	ldb	w, 0
	ld	(xbc), a
	cpw	(xsp+4), 511
	.byte 0x6e, 0x39
	pushw 6
	lds32	xwa, 0
	push xwa
	ld	xwa, xiz
	inc	1, xwa
	push xwa
	ld	xwa, (xsp+20)
	push xwa
	.byte 0x1e, 0x46, 0xf8
	add	xsp, 14
	or	xhl, xhl
	.byte 0x76, 0xc1, 0x00
	ld	wa, (xsp+16)
	srl	wa, 8
	ld	bc, wa
	and	bc, 15
	ld	a, (xhl+26)
	and	a, 240
	extz	wa
	or	wa, bc
	ld	(xhl+26), a
	.byte 0x78, 0xa5, 0x00
	ld	wa, (xsp+16)
	srl	wa, 8
	ld	bc, wa
	and	bc, 15
	ld	wa, (xsp+4)
	inc	1, wa
	extz	xwa
	add	xwa, 26
	add	xwa, xhl
	ld	a, (xwa)
	and	a, 240
	extz	wa
	or	wa, bc
	ld	c, a
	ld	wa, (xsp+4)
	inc	1, wa
	extz	xwa
	add	xwa, 26
	add	xwa, xhl
	ld	(xwa), c
	.byte 0x68, 0x6c
	ld	wa, (xsp+14)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	ld	xwa, xbc
	and	xwa, 511
	ld	(xsp+4), wa
	ld	xiz, xbc
	srl	xiz, 9
	add	xiz, (xde+24)
	pushw 6
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+38)
	push xwa
	push xiz
	ld	xwa, (xsp+20)
	push xwa
	.byte 0x1e, 0xb8, 0xf7
	lda	xsp, (xsp+14)
	ld	xbc, xhl
	ld	xwa, (xsp+10)
	ld	(xwa+38), xbc
	or	xhl, xhl
	.byte 0x66, 0x2f
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	ldb	w, 0
	ld	(xbc), a
	ld	wa, (xsp+4)
	inc	1, wa
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	srl	wa, 8
	ld	(xbc), a
	pop xiz
	inc	2, xsp
	ret
	dec	4, xsp
	push xiz
	ld	xiz, (xsp+12)
	ld	xwa, (xiz+30)
	ld	wa, (xwa+36)
	dec	0, wa
	ld	(xsp+6), wa
	ld	wa, (xiz+42)
	ld	(xsp+4), wa
	cpw	(xsp+4), 0
	.byte 0x6e, 0x09
	ldw	(xiz+44), 0
	lds	hl, 0
	.byte 0x68, 0x27
	ldw	(xiz+44), 1
	.byte 0x68, 0x0d, 0x9f, 0x04, 0x61
	ld	wa, (xsp+4)
	cp	wa, hl
	.byte 0x6e, 0x13, 0x9e, 0x2c, 0x61
	pushm	(xsp+4)
	push xiz
	.byte 0x1e, 0xdc, 0xfc
	inc	6, xsp
	ld	wa, hl
	cp	wa, (xsp+6)
	.byte 0x63, 0xe3
	ld	hl, (xiz+44)
	pop xiz
	inc	4, xsp
	ret
	.byte 0xbf, 0xf4, 0x37
	push xiz
	ldw	(xsp+8), 0
	ldw	(xsp+10), 0
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+18)
	ld	xwa, (xwa+26)
	ld	(xsp+12), xwa
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+54)
	ld	(xsp+4), wa
	ld	xwa, (xsp+20)
	ld	wa, (xwa+42)
	ld	(xsp+6), wa
	ld	wa, (xsp+26)
	.byte 0x9f, 0x1a, 0x69
	cps	wa, 0
	.byte 0x76, 0xdd, 0x00
	lds	bc, 2
	ld	wa, (xsp+6)
	inc	1, wa
	cps	wa, 2
	.byte 0x67, 0x05
	ld	bc, (xsp+6)
	inc	1, bc
	ld	iz, bc
	cp	iz, (xsp+4)
	.byte 0x6b, 0x15
	pushw iz
	ld	xwa, (xsp+22)
	push xwa
	.byte 0x1e, 0x73, 0xfc
	inc	6, xsp
	cps	hl, 0
	.byte 0x66, 0x39
	inc	1, iz
	cp	iz, (xsp+4)
	.byte 0x63, 0xeb
	lds	iz, 2
	cp	iz, (xsp+6)
	.byte 0x6f, 0x15
	pushw iz
	ld	xwa, (xsp+22)
	push xwa
	.byte 0x1e, 0x57, 0xfc
	inc	6, xsp
	cps	hl, 0
	.byte 0x66, 0x1d
	inc	1, iz
	cp	iz, (xsp+6)
	.byte 0x67, 0xeb
	ld	xwa, (xsp+20)
	push xwa
	.byte 0x1e, 0x00, 0x08
	ld	xwa, (xsp+24)
	push xwa
	.byte 0x1e, 0xb1, 0xf9
	inc	0, xsp
	ldw	hl, 15
	.byte 0x78, 0xf1, 0x00
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+30)
	pushm	(xwa+36)
	pushw iz
	ld	xwa, (xsp+24)
	push xwa
	.byte 0x1e, 0x2b, 0xfd
	inc	0, xsp
	ld	xwa, (xsp+20)
	cpw	(xwa+69), 0
	.byte 0x6e, 0x08
	ld	xwa, (xsp+20)
	ld	(xwa+69), iz
	.byte 0x68, 0x1a
	pushw iz
	pushm	(xsp+8)
	ld	xwa, (xsp+24)
	push xwa
	.byte 0x1e, 0x0c, 0xfd
	inc	0, xsp
	cpw	(xsp+8), 0
	.byte 0x6e, 0x06
	ld	xwa, (xsp+20)
	.byte 0x98, 0x2e, 0x61
	ld	(xsp+6), iz
	.byte 0x9f, 0x0a, 0x61
	ld	wa, (xsp+10)
	cp	wa, iz
	.byte 0x6e, 0x08
	ld	xwa, (xsp+20)
	.byte 0x98, 0x2c, 0x61, 0x68, 0x05
	ldw	(xsp+10), 0
	cpw	(xsp+8), 0
	.byte 0x6e, 0x14
	ld	xwa, (xsp+20)
	ld	(xwa+42), iz
	ld	(xsp+8), iz
	ld	(xsp+10), iz
	ld	xwa, (xsp+20)
	ldw	(xwa+44), 1
	ld	wa, (xsp+26)
	.byte 0x9f, 0x1a, 0x69
	cps	wa, 0
	.byte 0x7e, 0x23, 0xff
	cpw	(xsp+24), 0
	.byte 0x66, 0x69
	ld	xwa, (xsp+12)
	lda	xbc, (xwa+32)
	ld	wa, iz
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	16714332
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+20)
	add	xwa, xhl
	ld	(xsp+8), xwa
	ld	xiz, xwa
	.byte 0x68, 0x3b
	pushw 34
	lds32	xwa, 0
	push xwa
	push xiz
	ld	xwa, (xsp+30)
	push xwa
	.byte 0x1e, 0xd7, 0xf5
	add	xsp, 14
	or	xhl, xhl
	.byte 0x6e, 0x05
	ldw	hl, 10
	.byte 0x68, 0x2d
	cpw	(xhl+20), 0
	.byte 0x66, 0x05
	ld	hl, (xhl+20)
	.byte 0x68, 0x21
	pushw 512
	pushw 0
	lda	xwa, (xhl+26)
	push xwa
	call	16715770
	inc	0, xsp
	inc	1, xiz
	ld	xbc, (xsp+8)
	ld	xwa, (xsp+12)
	add	xbc, (xwa+32)
	cp	xiz, xbc
	.byte 0x67, 0xb8
	lds	hl, 0
	pop xiz
	lda	xsp, (xsp+12)
	ret
	push xiz
	ld	xiz, (xsp+12)
	pushw 11
	pushw 32
	ld	xwa, (xsp+12)
	push xwa
	call	16715770
	inc	0, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+11), 0
	lds	hl, 0
	.byte 0xa6
SeqByteBlock_MedleyPlayback:
	ldb	w, 128
	push	xsp
	.byte 0x2f
	jr	z, 7
SeqByteBlock_EffectsSeqData:
	ld	xwa, (xiz)
	.byte 0x80, 0x3f
SeqByteBlock_EffectsSeqEntry:
	pop	xix
	jr	nz, 4
	.byte 0xe8
SeqByteBlock_MedleyPlaybackB:
	add	(xbc-90), xwa
	lds	de, 0
	cp	de, 11
	jr	ge, 80
	ld	xwa, (xiz)
	cp	(xwa), 0
	jr	z, 73
	ld	xwa, (xiz)
	cp	(xwa), 47
	jr	z, 7
	ld	xwa, (xiz)
	cp	(xwa), 92
	jr	nz, 4
	lds	hl, 1
SeqByteBlock_EffectsSeqDotExt:
	jr	55
	ld	xwa, (xiz)
	cp	(xwa), 46
	jr	nz, 24
	cps	de, 1
	jr	gt, 12
	cps	de, 1
	jr	nz, 16
	ld	xwa, (xsp+8)
	cp	(xwa), 46
	jr	z, 8
	lds	de, 7
	lds32	xwa, 1
	add	(xiz), xwa
	jr	16
SeqByteBlock_TechnichordCfgA:
	.byte 0xa6
SeqByteBlock_PathNormalize:
	ldb	a, 175
	ldio	32, 129
	ldb	c, 243
	reti
	.byte 0xe0, 0xe8, 0x43
	lds32	xwa, 1
	add	(xiz), xwa
	inc	1, de
	.byte 0xda
SeqByteBlock_TechnichordCfgB:
	divs	l, 0
SeqByteBlock_StyleBitmapRef:
	jr	lt, -80
	ld	xwa, (xiz)
	cp	(xwa), 47
	jr	z, 7
	ld	xwa, (xiz)
	cp	(xwa), 92
	jr	nz, 4
	lds	hl, 1
	jr	10
	ld	xwa, (xiz)
	cp	(xwa), 0
	jr	z, 3
	ldw	hl, 65535
	ld	xwa, (xsp+8)
	cp	(xwa), 46
	jr	nz, 10
	ld	xwa, (xsp+8)
	.byte 0x88, 0x01
	.ascii "? vOÿ^"
	.byte 0x0e, 0xbf, 0xe0, 0x37, 0x2e, 0xaf, 0x26, 0x20
	.byte 0xa8, 0x12, 0x20, 0x38, 0xaf, 0x2a, 0x20, 0xa8
	.byte 0x0a, 0x20, 0xa8, 0x1c, 0x20, 0xb0, 0xe8, 0xef
	.byte 0x64, 0xdb, 0xd8, 0x66, 0x4f, 0xf2, 0x1a, 0x12
	.byte 0x02, 0x30, 0xbf, 0x10, 0x60, 0xde, 0xa8, 0xde
	.byte 0xcf, 0x0a, 0x00, 0x69, 0x36, 0xaf, 0x26, 0x20
	.byte 0xa8, 0x12, 0x21, 0xaf, 0x10, 0x20, 0xa0, 0xf1
	.byte 0x6e, 0x19, 0xaf, 0x10, 0x20, 0x88, 0x16, 0x21
	.byte 0xc9, 0xcc, 0x03, 0xc9, 0xdb, 0x6e, 0x05, 0xdb
	.byte 0xae, 0x78, 0xa4, 0x03, 0xaf, 0x10, 0x20, 0x88
	.byte 0x16, 0x3c, 0xf6, 0xde, 0x61, 0x40, 0x1a, 0x02
	.byte 0x00, 0x00, 0xaf, 0x10, 0x88, 0xde, 0xcf, 0x0a
	.byte 0x00, 0x61, 0xca, 0xaf, 0x26, 0x20, 0xa8, 0x12
	.byte 0x20, 0xb8, 0x02, 0xb9, 0xaf, 0x26, 0x20, 0xa8
	.byte 0x12, 0x20, 0xa8, 0x1a, 0x20, 0xbf, 0x04, 0x60
	.byte 0xbf, 0x2a, 0x30, 0x38, 0xbf, 0x1a, 0x30, 0x38
	.byte 0x1e, 0xc7, 0xfe, 0xef, 0x60, 0xbf, 0x14, 0x53
	.byte 0x9f, 0x14, 0x3f, 0xff, 0xff, 0x6e, 0x06, 0x33
	.byte 0x0b, 0x00, 0x78, 0x5b, 0x03, 0x8f, 0x16, 0x3f
	.byte 0x20, 0x7e, 0x32, 0x01, 0xaf, 0x26, 0x20, 0xb8
	.byte 0x03, 0xce, 0x76, 0x29, 0x01, 0xaf, 0x04, 0x20
	.byte 0x98, 0x2c, 0x21, 0xd9, 0xee, 0x05, 0xe9, 0x12
	.byte 0xaf, 0x26, 0x20, 0xb8, 0x47, 0x61, 0xaf, 0x26
	.byte 0x20, 0xb8, 0x03, 0xb1, 0xaf, 0x26, 0x20, 0xe9
	.byte 0xa8, 0xb8, 0x1a, 0x61, 0xdb, 0xa8, 0x78, 0x27
	.byte 0x03, 0xaf, 0x10, 0x20, 0x98, 0x14, 0x3f, 0x00
	.byte 0x00, 0x66, 0x09, 0xaf, 0x10, 0x20, 0x98, 0x14
	.byte 0x23, 0x78, 0x14, 0x03, 0xaf, 0x10, 0x20, 0xb8
	.byte 0x1a, 0x30, 0xbf, 0x08, 0x60, 0xde, 0xa8, 0x78
	.byte 0xa0, 0x00, 0xaf, 0x08, 0x20, 0x80, 0x3f, 0x00
	.byte 0x76, 0xf1, 0x01, 0x0b, 0x0b, 0x00, 0xaf, 0x0a
	.byte 0x20, 0x38, 0xbf, 0x1c, 0x30, 0x38, 0x1d, 0xc1
	.byte 0x0c, 0xff, 0xef, 0xc8, 0x0a, 0x00, 0x00, 0x00
	.byte 0xdb, 0xd8, 0x6e, 0x74, 0xc7, 0xf8, 0x8b, 0xaf
	.byte 0x26, 0x20, 0xb8, 0x33, 0x43, 0xaf, 0x08, 0x20
	.byte 0x38, 0xaf, 0x2a, 0x20, 0xb8, 0x34, 0x30, 0x38
	.byte 0x1e, 0x19, 0xf8, 0xaf, 0x2e, 0x20, 0x98, 0x45
	.byte 0x21, 0xaf, 0x2e, 0x20, 0xb8, 0x2a, 0x51, 0xbf
	.byte 0x16, 0x51, 0xaf, 0x2e, 0x20, 0x38, 0x1e, 0x31
	.byte 0xfc, 0xbf, 0x0c, 0x37, 0xaf, 0x26, 0x20, 0xe9
	.byte 0xa8, 0xb8, 0x16, 0x61, 0xaf, 0x26, 0x20, 0xe9
	.byte 0xa8, 0xb8, 0x22, 0x61, 0xaf, 0x10, 0x20, 0xb8
	.byte 0x16, 0xb3, 0x9f, 0x14, 0x3f, 0x00, 0x00, 0x76
	.byte 0x22, 0x02, 0xaf, 0x26, 0x20, 0xb8, 0x40, 0xcc
	.byte 0x76, 0x07, 0x02, 0xbf, 0x2a, 0x30, 0x38, 0xbf
	.byte 0x1a, 0x30, 0x38, 0x1e, 0xdc, 0xfd, 0xef, 0x60
	.byte 0xbf, 0x14, 0x53, 0x9f, 0x14, 0x3f, 0xff, 0xff
	.byte 0x6e, 0x47, 0x33, 0x0b, 0x00, 0x78, 0x70, 0x02
	.byte 0xde, 0x61, 0x40, 0x20, 0x00, 0x00, 0x00, 0xaf
	.byte 0x08, 0x88, 0x30, 0x10, 0x00, 0x9f, 0x02, 0x3f
	.byte 0x10, 0x00, 0x6a, 0x03, 0x9f, 0x02, 0x20, 0xd8
	.byte 0xf6, 0x71, 0x4e, 0xff, 0xaf, 0x10, 0x20, 0xb8
	.byte 0x16, 0xb3, 0xaf, 0x0c, 0x20, 0xe9, 0xa9, 0xa0
	.byte 0x89, 0x9f, 0x02, 0x3a, 0x10, 0x00, 0x6a, 0x4a
	.byte 0x9f, 0x14, 0x3f, 0x00, 0x00, 0x66, 0x05, 0xdb
	.byte 0xaf, 0x78, 0x34, 0x02, 0xdb, 0xad, 0x78, 0x2f
	.byte 0x02, 0xbf, 0x0c, 0x02, 0x01, 0x00, 0x9f, 0x0e
	.byte 0x3f, 0x00, 0x00, 0x7e, 0x67, 0x01, 0xaf, 0x26
	.byte 0x20, 0xb8, 0x30, 0x02, 0x00, 0x00, 0xaf, 0x26
	.byte 0x20, 0xb8, 0x1a, 0x30, 0xbf, 0x0c, 0x60, 0xaf
	.byte 0x04, 0x20, 0xaf, 0x0c, 0x21, 0xa8, 0x1c, 0x20
	.byte 0xb1, 0x60, 0xaf, 0x04, 0x20, 0x98, 0x2c, 0x20
	.byte 0xbf, 0x02, 0x50, 0x9f, 0x02, 0x3f, 0x00, 0x00
	.byte 0x62, 0xb6, 0x0b, 0x08, 0x00, 0xe8, 0xa8, 0x38
	.byte 0xaf, 0x12, 0x20, 0xa0, 0x20, 0x38, 0xaf, 0x30
	.byte 0x20, 0x38, 0x1e, 0xd3, 0xf2, 0xbf, 0x0e, 0x37
	.byte 0xbf, 0x10, 0x63, 0xaf, 0x10, 0x20, 0xe8, 0xe0
	.byte 0x7e, 0xae, 0xfe, 0xaf, 0x26, 0x20, 0x98, 0x06
	.byte 0x23, 0x78, 0xcc, 0x01, 0x0b, 0x08, 0x00, 0xe8
	.byte 0xa8, 0x38, 0xaf, 0x2c, 0x20, 0xa8, 0x1a, 0x20
	.byte 0x38, 0xaf, 0x30, 0x20, 0x38, 0x1e, 0xa8, 0xf2
	.byte 0xbf, 0x0e, 0x37, 0xbf, 0x10, 0x63, 0xaf, 0x10
	.byte 0x20, 0xe8, 0xe0, 0x6e, 0x09, 0xaf, 0x26, 0x20
	.byte 0x98, 0x06, 0x23, 0x78, 0xa2, 0x01, 0xaf, 0x10
	.byte 0x20, 0x98, 0x14, 0x3f, 0x00, 0x00, 0x66, 0x09
	.byte 0xaf, 0x10, 0x20, 0x98, 0x14, 0x23, 0x78, 0x8f
	.byte 0x01, 0xaf, 0x10, 0x20, 0xb8, 0x1a, 0x30, 0xbf
	.byte 0x08, 0x60, 0xaf, 0x26, 0x20, 0xb8, 0x33, 0x00
	.byte 0x00, 0xaf, 0x26, 0x20, 0x88, 0x33, 0x3f, 0x10
	.byte 0x7f, 0x8e, 0x00, 0xaf, 0x08, 0x20, 0x80, 0x3f
	.byte 0x00, 0x66, 0x61, 0x0b, 0x0b, 0x00, 0xaf, 0x0a
	.byte 0x20, 0x38, 0xbf, 0x1c, 0x30, 0x38, 0x1d, 0xc1
	.byte 0x0c, 0xff, 0xef, 0xc8, 0x0a, 0x00, 0x00, 0x00
	.byte 0xdb, 0xd8, 0x6e, 0x55, 0xbf, 0x0c, 0x02, 0x00
	.byte 0x00, 0xaf, 0x08, 0x20, 0x38, 0xaf, 0x2a, 0x20
	.byte 0xb8, 0x34, 0x30, 0x38, 0x1e, 0x8d, 0xf6, 0xaf
	.byte 0x2e, 0x20, 0x98, 0x45, 0x21, 0xaf, 0x2e, 0x20
	.byte 0xb8, 0x2a, 0x51, 0xbf, 0x16, 0x51, 0xaf, 0x2e
	.byte 0x20, 0xb8, 0x30, 0x51, 0xaf, 0x2e, 0x20, 0x38
	.byte 0x1e, 0x9f, 0xfa, 0xbf, 0x0c, 0x37, 0xaf, 0x10
	.byte 0x20, 0xb8, 0x16, 0xb3, 0xaf, 0x26, 0x20, 0xe9
	.byte 0xa8, 0xb8, 0x22, 0x61, 0x9f, 0x0c, 0x3f, 0x00
	.byte 0x00, 0x76, 0x90, 0x00, 0x9f, 0x14, 0x3f, 0x00
	.byte 0x00, 0x76, 0x84, 0x00, 0xdb, 0xaf, 0x78, 0xff
	.byte 0x00, 0xaf, 0x26, 0x20, 0x88, 0x33, 0x61, 0x40
	.byte 0x20, 0x00, 0x00, 0x00, 0xaf, 0x08, 0x88, 0xaf
	.byte 0x26, 0x20, 0x88, 0x33, 0x3f, 0x10, 0x77, 0x72
	.byte 0xff, 0xaf, 0x10, 0x20, 0xb8, 0x16, 0xb3, 0xaf
	.byte 0x26, 0x20, 0xe9, 0xa9, 0xa8, 0x1a, 0x89, 0x9f
	.byte 0x02, 0x61, 0xaf, 0x04, 0x20, 0xa8, 0x20, 0x20
	.byte 0x9f, 0x02, 0xf8, 0x71, 0xfe, 0xfe, 0x9f, 0x0e
	.byte 0x04, 0xaf, 0x28, 0x20, 0x38, 0x1e, 0x58, 0xf7
	.byte 0xef, 0x66, 0xbf, 0x0e, 0x53, 0xaf, 0x04, 0x20
	.byte 0x98, 0x24, 0x20, 0xd8, 0x68, 0x9f, 0x0e, 0xf8
	.byte 0x6b, 0x9a, 0xaf, 0x04, 0x20, 0xb8, 0x20, 0x31
	.byte 0x9f, 0x0e, 0x20, 0xd8, 0x6a, 0xe8, 0x12, 0xa1
	.byte 0x21, 0x1d, 0x5c, 0x0a, 0xff, 0xaf, 0x04, 0x20
	.byte 0xa8, 0x14, 0x21, 0xeb, 0x81, 0xaf, 0x26, 0x20
	.byte 0xb8, 0x1a, 0x61, 0xbf, 0x02, 0x02, 0x00, 0x00
	.byte 0x68, 0xb0, 0x33, 0x0c, 0x00, 0x78, 0x80, 0x00
	.byte 0xdb, 0xad, 0x68, 0x7c, 0x9f, 0x14, 0x3f, 0x00
	.byte 0x00, 0x7e, 0xde, 0xfd, 0xaf, 0x26, 0x20, 0xb8
	.byte 0x03, 0xce, 0x66, 0x45, 0xaf, 0x26, 0x20, 0xb8
	.byte 0x40, 0xcc, 0x6e, 0x05, 0x33, 0x0d, 0x00, 0x68
	.byte 0x5f, 0x9f, 0x0e, 0x3f, 0x00, 0x00, 0x6e, 0x20
	.byte 0x78, 0x0a, 0xfd, 0xaf, 0x04, 0x20, 0x98, 0x28
	.byte 0x21, 0xe9, 0x12, 0xaf, 0x26, 0x20, 0xa8, 0x47
	.byte 0x89, 0x9f, 0x0e, 0x04, 0xaf, 0x28, 0x20, 0x38
	.byte 0x1e, 0xd5, 0xf6, 0xef, 0x66, 0xbf, 0x0e, 0x53
	.byte 0xaf, 0x04, 0x20, 0x98, 0x24, 0x20, 0xd8, 0x68
	.byte 0x9f, 0x0e, 0xf8, 0x63, 0xd6, 0xdb, 0xa8, 0x68
	.byte 0x27, 0xaf, 0x26, 0x20, 0x88, 0x40, 0x21, 0xc9
	.byte 0xcc, 0x18, 0x66, 0x05, 0x33, 0x0d, 0x00, 0x68
	.byte 0x17, 0xaf, 0x26, 0x20, 0xb8, 0x40, 0xc8, 0x66
	.byte 0x0d, 0xaf, 0x26, 0x20, 0xb8, 0x03, 0xc9, 0x66
	.byte 0x05, 0x33, 0x0e, 0x00, 0x68, 0x02, 0xdb, 0xa8
	.byte 0x4e, 0xbf, 0x20, 0x37, 0x0e, 0xbf, 0xe2, 0x37
	.byte 0x3e, 0xaf, 0x26, 0x26, 0xae, 0x12, 0x20, 0xa8
	.byte 0x1a, 0x20, 0xbf, 0x06, 0x60, 0xbf, 0x2a, 0x30
	.byte 0x38, 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0x3a, 0xfb
	.byte 0xef, 0x60, 0xdb, 0xd8, 0x7e, 0x16, 0x01, 0xbe
	.byte 0x1a, 0x30, 0xbf, 0x0e, 0x60, 0xaf, 0x06, 0x20
	.byte 0xaf, 0x0e, 0x21, 0xa8, 0x1c, 0x20, 0xb1, 0x60
	.byte 0xaf, 0x06, 0x20, 0x98, 0x2c, 0x20, 0xbf, 0x04
	.byte 0x50, 0x9f, 0x04, 0x3f, 0x00, 0x00, 0x71, 0xee
	.byte 0x00, 0x0b, 0x18, 0x00, 0xe8, 0xa8, 0x38, 0xaf
	.byte 0x14, 0x20, 0xa0, 0x20, 0x38, 0x3e, 0x1e, 0x97
	.byte 0xf0, 0xbf, 0x0e, 0x37, 0xbf, 0x12, 0x63, 0xaf
	.byte 0x12, 0x20, 0xe8, 0xe0, 0x6e, 0x06, 0x9e, 0x06
	.byte 0x23, 0x78, 0xe4, 0x01, 0xaf, 0x12, 0x20, 0x98
	.byte 0x14, 0x3f, 0x00, 0x00, 0x66, 0x09, 0xaf, 0x12
	.byte 0x20, 0x98, 0x14, 0x23, 0x78, 0xd1, 0x01, 0xaf
	.byte 0x12, 0x20, 0xb8, 0x1a, 0x30, 0xbf, 0x0a, 0x60
	.byte 0xdb, 0xa8, 0x68, 0x7e, 0xaf, 0x0a, 0x20, 0x80
	.byte 0x3f, 0xe5, 0x66, 0x08, 0xaf, 0x0a, 0x20, 0x80
	.byte 0x3f, 0x00, 0x6e, 0x64, 0xbe, 0x33, 0x47, 0xbe
	.byte 0x2a, 0x02, 0x00, 0x00, 0xbe, 0x2e, 0x02, 0x00
	.byte 0x00, 0xbe, 0x32, 0x00, 0x00, 0x0b, 0x0b, 0x00
	.byte 0xbf, 0x18, 0x30, 0x38, 0xbe, 0x34, 0x30, 0x38
	.byte 0x1d, 0x99, 0x0d, 0xff, 0xbe, 0x40, 0x00, 0x00
	.byte 0xbe, 0x45, 0x02, 0x00, 0x00, 0xe8, 0xa8, 0xbe
	.byte 0x47, 0x60, 0xe8, 0xa8, 0xbe, 0x22, 0x60, 0xbe
	.byte 0x41, 0x30, 0x38, 0xae, 0x0a, 0x20, 0xa8, 0x18
	.byte 0x20, 0xb0, 0xe8, 0xaf, 0x18, 0x20, 0x38, 0xbe
	.byte 0x34, 0x30, 0x38, 0x1e, 0xcb, 0xf4, 0xaf, 0x28
	.byte 0x20, 0xb8, 0x16, 0xb9, 0xaf, 0x28, 0x20, 0x88
	.byte 0x16, 0x3c, 0xe7, 0xaf, 0x28, 0x20, 0x38, 0x1e
	.byte 0x33, 0xf2, 0xbf, 0x1a, 0x37, 0x78, 0x50, 0x01
	.byte 0xdb, 0x61, 0x40, 0x20, 0x00, 0x00, 0x00, 0xaf
	.byte 0x0a, 0x88, 0x30, 0x10, 0x00, 0x9f, 0x04, 0x3f
	.byte 0x10, 0x00, 0x6a, 0x03, 0x9f, 0x04, 0x20, 0xd8
	.byte 0xf3, 0x71, 0x70, 0xff, 0xaf, 0x12, 0x20, 0x88
	.byte 0x16, 0x3c, 0xe7, 0x9f, 0x04, 0x3a, 0x10, 0x00
	.byte 0xaf, 0x0e, 0x20, 0xe9, 0xa9, 0xa0, 0x89, 0x9f
	.byte 0x04, 0x3f, 0x00, 0x00, 0x79, 0x12, 0xff, 0x33
	.byte 0x10, 0x00, 0x78, 0x13, 0x01, 0x9e, 0x45, 0x20
	.byte 0xbe, 0x30, 0x50, 0xbf, 0x2a, 0x30, 0x38, 0xbf
	.byte 0x1a, 0x30, 0x38, 0x1e, 0x0c, 0xfa, 0xef, 0x60
	.byte 0xdb, 0xd8, 0x76, 0xd0, 0x00, 0xbf, 0x2a, 0x30
	.byte 0x38, 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0xfa, 0xf9
	.byte 0xef, 0x60, 0xdb, 0xd8, 0x6e, 0xef, 0x78, 0xbc
	.byte 0x00, 0xaf, 0x06, 0x20, 0xb8, 0x20, 0x31, 0x9e
	.byte 0x2a, 0x20, 0xd8, 0x6a, 0xe8, 0x12, 0xa1, 0x21
	.byte 0x1d, 0x5c, 0x0a, 0xff, 0xaf, 0x06, 0x20, 0xa8
	.byte 0x14, 0x20, 0xeb, 0x80, 0xbe, 0x1a, 0x60, 0xbf
	.byte 0x04, 0x02, 0x00, 0x00, 0x68, 0x79, 0x0b, 0x18
	.byte 0x00, 0xe8, 0xa8, 0x38, 0xae, 0x1a, 0x20, 0x38
	.byte 0x3e, 0x1e, 0x54, 0xef, 0xbf, 0x0e, 0x37, 0xbf
	.byte 0x12, 0x63, 0xaf, 0x12, 0x20, 0xe8, 0xe0, 0x6e
	.byte 0x06, 0x9e, 0x06, 0x23, 0x78, 0xa1, 0x00, 0xaf
	.byte 0x12, 0x20, 0x98, 0x14, 0x3f, 0x00, 0x00, 0x66
	.byte 0x09, 0xaf, 0x12, 0x20, 0x98, 0x14, 0x23, 0x78
	.byte 0x8e, 0x00, 0xaf, 0x12, 0x20, 0xb8, 0x1a, 0x30
	.byte 0xbf, 0x0a, 0x60, 0xbe, 0x33, 0x00, 0x00, 0x8e
	.byte 0x33, 0x3f, 0x10, 0x6f, 0x23, 0xaf, 0x0a, 0x20
	.byte 0x80, 0x3f, 0xe5, 0x76, 0xc1, 0xfe, 0xaf, 0x0a
	.byte 0x20, 0x80, 0x3f, 0x00, 0x76, 0xb8, 0xfe, 0x8e
	.asciz "3a@ "
	nop
	nop
	add	(xsp+10), xwa
	cp	(xiz+51), 16
	.byte 0x67, 0xdd
	ld	xwa, (xsp+18)
	andmi8	(xwa+22), 231
	lds32	xwa, 1
	add	(xiz+26), xwa
	.byte 0x9f, 0x04, 0x61
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+32)
	cp	(xsp+4), wa
	.byte 0x71, 0x7b, 0xff
	ld	wa, (xiz+42)
	ld	(xsp+20), wa
	pushm	(xiz+42)
	push xiz
	.byte 0x1e, 0x78, 0xf4
	inc	6, xsp
	ld	(xiz+42), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa+36)
	dec	0, wa
	cp	(xiz+42), wa
	.byte 0x73, 0x36, 0xff
	ld	(xiz+51), 0
	ld	wa, (xsp+20)
	ld	(xiz+42), wa
	pushw 1
	pushw 1
	push xiz
	.byte 0x1e, 0x85, 0xf7
	inc	0, xsp
	ld	wa, hl
	cps	wa, 0
	.byte 0x76, 0x19, 0xff
	pop xiz
	lda	xsp, (xsp+30)
	ret
	dec	4, xsp
	push xiz
	ld	xiz, (xsp+12)
	lda	xwa, (xiz+65)
	push xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call	(xwa)
	pushw 26
	lds32	xwa, 0
	push xwa
	ld	xwa, (xiz+26)
	push xwa
	push xiz
	.byte 0x1e, 0x7b, 0xee
	lda	xsp, (xsp+18)
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	.byte 0x6e, 0x05
	ldw	hl, 10
	.byte 0x68, 0x29
	ld	a, (xiz+51)
	extz	wa
	sla	wa, 5
	ld	bc, wa
	add	bc, 26
	ld	xwa, (xsp+4)
	lda_rr	xwa, xwa, bc
	push xwa
	lda	xwa, (xiz+52)
	push xwa
	.byte 0x1e, 0x0c, 0xf3
	inc	0, xsp
	ld	xwa, (xsp+4)
	andmi8	(xwa+22), 231
	lds	hl, 0
	pop xiz
	inc	4, xsp
	ret
	push xiz
	ld	xwa, (xsp+8)
	ld	iz, (xwa+69)
	cps	iz, 0
	.byte 0x6e, 0x21
	ld	qiz, 0
	.byte 0x68, 0x1c
	pushw iz
	ld	xwa, (xsp+10)
	push xwa
	.byte 0x1e, 0xcc, 0xf3
	ld	qiz, hl
	pushw 0
	pushw iz
	ld	xwa, (xsp+18)
	push xwa
	.byte 0x1e, 0xc6, 0xf4
	lda	xsp, (xsp+14)
	ld	iz, qiz
	cps	iz, 0
	.byte 0x66, 0x0f
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+36)
	dec	0, wa
	cp	iz, wa
	.byte 0x63, 0xd1
	ld	xwa, (xsp+8)
	bitm	5, (xwa+3)
	.byte 0x6e, 0x18
	ld	xwa, (xsp+8)
	ldw	(xwa+69), 0
	lds	bc, 0
	ld	xwa, (xsp+8)
	ld	(xwa+42), bc
	ld	xwa, (xsp+8)
	lds32	xbc, 0
	ld	(xwa+71), xbc
	pop xiz
	ret
	.byte 0xbf, 0xde, 0x37
	push xiz
	ldw	(xsp+18), 0
	ldw	(xsp+20), 0
	ldw	(xsp+22), 1
	lds32	xwa, 0
	ld	(xsp+24), xwa
	lds32	xhl, 0
	ldw	(xsp+32), 4095
	ld	xwa, (xsp+42)
	ld	xwa, (xwa+26)
	ld	(xsp+4), xwa
	ld	xwa, (xsp+42)
	resm	0, (xwa+2)
	pushw 538
	call	16051046
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, xhl
	or	xwa, xwa
	.byte 0x6e, 0x05
	lds	hl, 3
	.byte 0x78, 0x17, 0x04
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+42)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	lds32	xbc, 0
	ld	(xwa+12), xbc
	ld	xwa, (xsp+4)
	ldw	(xwa+50), 32
	ld	xwa, (xsp+4)
	ldw	(xwa+52), 8
	ld	xwa, (xsp+42)
	bitm	7, (xwa+4)
	.byte 0x76, 0x1f, 0x01
	ldw	(xsp+16), 0
	.byte 0x78, 0xfb, 0x00
	ld	xwa, (xsp+8)
	push xwa
	ld	xwa, (xsp+28)
	push xwa
	ld	xwa, (xsp+50)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+16)
	call	(xwa)
	inc	0, xsp
	ld	iz, hl
	cps	iz, 0
	.byte 0x6e, 0x19
	ld	xwa, (xsp+8)
	cp	(xwa+536), 85
	jr	nz, 11
	ld	xwa, (xsp+8)
	cp	(xwa+537), 170
	jr	z, 18
	ldw	iz, 22
	ld	xwa, (xsp+8)
	push	xwa
	call	16052743
	inc	4, xsp
	ld	hl, iz
	jrl	931
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+472)
	ld	(xsp+12), xwa
	ld	a, (xwa+6)
	and	a, 63
	ld	c, a
	extz	bc
	ld	xwa, (xsp+4)
	ld	(xwa+50), bc
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	and	a, 63
	extz	wa
	inc	1, wa
	ld	bc, wa
	ld	xwa, (xsp+4)
	ld	(xwa+52), bc
	ld	xwa, (xsp+12)
	inc	8, xwa
	ld	(xsp+34), xwa
	lda	xwa, (xsp+34)
	push	xwa
	calr	-3972
	inc	4, xsp
	ld	xwa, (xsp+24)
	add	xwa, xhl
	ld	(xsp+28), xwa
	ld	xwa, (xsp+42)
	ld	a, (xwa+5)
	extz	wa
	cp	(xsp+16), wa
	jr	ge, 38
	add	(xsp+24), xhl
	lda	xwa, (xsp+34)
	push	xwa
	calr	-4005
	inc	4, xsp
	add	(xsp+24), xhl
	ld	xwa, 16
	add	(xsp+12), xwa
	ld	xwa, (xsp+12)
	cp	(xwa+4), 5
	jr	z, 6
	ldw	iz, 23
	jrl	-139
	ld	xwa, (xsp+12)
	ld	a, (xwa+2)
	and	a, 63
	extz	wa
	ld	(xsp+22), wa
	ld	xwa, (xsp+12)
	ld	a, (xwa+1)
	extz	wa
	ld	(xsp+20), wa
	ld	xwa, (xsp+12)
	ld	a, (xwa+3)
	ld	c, a
	extz	bc
	ld	xwa, (xsp+12)
	ld	a, (xwa+2)
	and	a, 192
	extz	wa
	ld	(xsp+18), wa
	sla	wa, 2
	add	wa, bc
	ld	(xsp+18), wa
	incm	1, (xsp+16)
	ld	xwa, (xsp+42)
	ld	a, (xwa+5)
	extz	wa
	cp	(xsp+16), wa
	jrl	le, -265
	ld	xwa, (xsp+12)
	cp	(xwa+4), 4
	jr	c, 5
	ldw	(xsp+32), 65535
	ld	xwa, (xsp+42)
	bitm	7, (xwa+4)
	jr	z, 25
	ld	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+32)
	push	xwa
	ld	xwa, (xsp+50)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+16)
	call	(xwa)
	inc	8, xsp
	ld	iz, hl
	jr	39
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+26)
	push	xwa
	pushw 1
	pushm	(xsp+28)
	pushm	(xsp+28)
	pushm	(xsp+28)
	ld	xwa, (xsp+54)
	push	xwa
	ld	xwa, (xsp+58)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+4)
	call	(xwa)
	lda	xsp, (xsp+16)
	ld	iz, hl
	cp	iz, 9
	jr	nz, 85
	pushw 538
	call	16051046
	ld	xiz, xhl
	ld	xwa, (xsp+10)
	push	xwa
	call	16052743
	inc	6, xsp
	or	xiz, xiz
	jr	nz, 5
	lds	hl, 3
	jrl	613
	ld	(xsp+8), xiz
	ld	xwa, xiz
	ld	xbc, (xsp+42)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	lds32	xbc, 0
	ld	(xwa+12), xbc
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+26)
	push	xwa
	pushw 1
	pushm	(xsp+28)
	pushm	(xsp+28)
	pushm	(xsp+28)
	ld	xwa, (xsp+54)
	push	xwa
	ld	xwa, (xsp+58)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+4)
	call	(xwa)
	lda	xsp, (xsp+16)
	ld	iz, hl
	cps	iz, 6
	jr	nz, 72
	ld	xwa, (xsp+42)
	bitm	7, (xwa+4)
	jr	z, 25
	ld	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+32)
	push	xwa
	ld	xwa, (xsp+50)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+16)
	call	(xwa)
	inc	8, xsp
	ld	iz, hl
	jr	39
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+26)
	push	xwa
	pushw 1
	pushm	(xsp+28)
	pushm	(xsp+28)
	pushm	(xsp+28)
	ld	xwa, (xsp+54)
	push	xwa
	ld	xwa, (xsp+58)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+4)
	call	(xwa)
	lda	xsp, (xsp+16)
	ld	iz, hl
	cps	iz, 0
	jrl	nz, -471
	ld	xwa, (xsp+8)
	lda	xwa, (xwa+37)
	ld	(xsp+34), xwa
	lda	xwa, (xsp+34)
	push	xwa
	calr	-4413
	inc	4, xsp
	ld	xwa, (xsp+4)
	ld	(xwa+38), hl
	ld	xbc, (xsp+34)
	lds32	xwa, 1
	add	(xsp+34), xwa
	ld	a, (xbc)
	lds32	xbc, 0
	ld	c, a
	ld	xwa, (xsp+4)
	ld	(xwa+32), xbc
	ld	xwa, (xsp+4)
	cpw	(xwa+38), 0
	jr	z, 10
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+32)
	or	xwa, xwa
	jr	nz, 6
	ldw	iz, 40
	jrl	-541
	lda	xwa, (xsp+34)
	push	xwa
	calr	-4474
	ld	xwa, (xsp+8)
	ld	(xwa+42), hl
	ld	xbc, (xsp+38)
	lds32	xwa, 1
	add	(xsp+38), xwa
	ld	xwa, (xsp+8)
	ld	c, (xbc)
	ld	(xwa+58), c
	lda	xwa, (xsp+38)
	push	xwa
	calr	-4503
	ld	xwa, (xsp+12)
	ld	(xwa+44), hl
	lda	xwa, (xsp+42)
	push	xwa
	calr	-4516
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+16)
	ld	(xwa+8), xbc
	ld	xbc, (xsp+46)
	lds32	xwa, 1
	add	(xsp+46), xwa
	ld	xwa, (xsp+16)
	ld	c, (xbc)
	ld	(xwa+59), c
	lda	xwa, (xsp+46)
	push	xwa
	calr	-4549
	ld	xwa, (xsp+20)
	ld	(xwa+48), hl
	lda	xwa, (xsp+50)
	push	xwa
	calr	-4562
	ld	xwa, (xsp+24)
	ld	(xwa+50), hl
	lda	xwa, (xsp+54)
	push	xwa
	calr	-4575
	ld	xwa, (xsp+28)
	ld	(xwa+52), hl
	lda	xwa, (xsp+58)
	push	xwa
	calr	-4588
	lda	xsp, (xsp+28)
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+4)
	ld	(xwa+16), xbc
	ld	xwa, (xsp+4)
	lds32	xbc, 0
	ld	(xwa+12), xbc
	ld	xwa, (xsp+4)
	ld	(xwa+60), 0
	ld	xwa, (xsp+4)
	ld	wa, (xwa+42)
	extz	xwa
	ld	xbc, xwa
	ld	xwa, (xsp+4)
	add	xbc, (xwa+16)
	add	xbc, (xsp+24)
	ld	xwa, (xsp+4)
	ld	(xwa+24), xbc
	ld	xwa, (xsp+4)
	ld	a, (xwa+58)
	extz	wa
	ld	bc, wa
	ld	xwa, (xsp+4)
	.byte 0x98, 0x30, 0x41
	ld	xwa, (xsp+4)
	ld	xde, (xwa+24)
	add	xde, xbc
	ld	xwa, (xsp+4)
	ld	(xwa+28), xde
	ld	xwa, (xsp+4)
	ld	bc, (xwa+38)
	srl	bc, 5
	ld	xwa, (xsp+4)
	ld	wa, (xwa+44)
	extz	xwa
	div	xwa, xbc
	ld	bc, wa
	ld	xwa, (xsp+4)
	ld	(xwa+46), bc
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+32)
	ld	xwa, (xsp+4)
	ld	wa, (xwa+38)
	extz	xwa
	ld	xbc, (xbc)
	call	16714332
	ld	xwa, (xsp+4)
	ld	(xwa+40), hl
	ld	xwa, (xsp+4)
	ld	wa, (xwa+46)
	extz	xwa
	ld	xbc, xwa
	ld	xwa, (xsp+4)
	add	xbc, (xwa+28)
	ld	xwa, (xsp+4)
	ld	(xwa+20), xbc
	ld	xwa, (xsp+4)
	ld	wa, (xwa+38)
	dec	1, wa
	ld	bc, wa
	extz	xbc
	ld	xwa, (xsp+4)
	ld	(xwa+4), xbc
	ld	xwa, (xsp+4)
	ld	a, (xwa+58)
	extz	wa
	ld	bc, wa
	ld	xwa, (xsp+4)
	.byte 0x98, 0x30, 0x41
	ld	xhl, xbc
	ld	xwa, (xsp+4)
	ld	bc, (xwa+46)
	extz	xbc
	ld	xwa, (xsp+4)
	ld	xde, (xwa+8)
	sub	xde, xbc
	ld	xwa, (xsp+4)
	ld	wa, (xwa+42)
	extz	xwa
	sub	xde, xwa
	sub	xde, xhl
	ld	xwa, xde
	ld	xbc, (xsp+4)
	ld	xbc, (xbc+32)
	call	16714776
	inc	1, xhl
	ld	xwa, (xsp+4)
	ld	(xwa+54), hl
	ld	xwa, (xsp+4)
	cpw	(xwa+54), 4087
	jr	ule, 5
	ldw	(xsp+32), 65535
	ld	xwa, (xsp+4)
	ld	bc, (xsp+32)
	ld	(xwa+36), bc
	ld	xwa, (xsp+42)
	setm	0, (xwa+2)
	ld	xwa, (xsp+8)
	push	xwa
	call	16052743
	inc	4, xsp
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+34)
	ret
SeqByteBlock_ChannelContainer:
	dec	8, xsp
	pushw	iz
	ld	xwa, (xsp+14)
	ld	xwa, (xwa+18)
	ld	(xsp+2), xwa
	ld	xwa, (xwa+26)
	ld	(xsp+6), xwa
	ld	xwa, (xsp+2)
	bitm	3, (xwa+2)
	jr	nz, 32
	ld	xwa, (xsp+2)
	push	xwa
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa)
	call	(xwa)
	inc	4, xsp
	cps	hl, 0
	jr	z, 6
	ldw	hl, 42
	jrl	190
	ld	xwa, (xsp+2)
	setm	3, (xwa+2)
	ld	xwa, (xsp+2)
	bitm	0, (xwa+2)
	jr	nz, 20
	ld	xwa, (xsp+2)
	push	xwa
	calr	-1194
	inc	4, xsp
	ld	iz, hl
	cps	iz, 0
	jr	z, 5
	ld	hl, iz
	jrl	156
	ld	xwa, (xsp+6)
	cpw	(xwa+38), 512
	jr	z, 5
	lds	hl, 1
	jrl	141
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+6)
	ld	(xwa+30), xbc
	ld	xwa, (xsp+14)
	bitm	2, (xwa+3)
	jr	z, 7
	ld	xwa, (xsp+14)
	ld	(xwa+2), 10
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	-3053
	inc	8, xsp
	ld	iz, hl
	ld	xwa, (xsp+14)
	bitm	7, (xwa+3)
	jr	z, 67
	cps	iz, 0
	jr	z, 21
	cps	iz, 5
	jr	nz, 59
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	-2072
	inc	8, xsp
	ld	iz, hl
	jr	42
	ld	xwa, (xsp+14)
	bitm	3, (xwa+3)
	jr	z, 11
	ld	xwa, (xsp+14)
	ld	xbc, xwa
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	ld	xwa, (xsp+14)
	bitm	4, (xwa+3)
	jr	z, 15
	ld	xwa, (xsp+14)
	push	xwa
	calr	-1425
	inc	4, xsp
	ld	xwa, (xsp+14)
	setm	7, (xwa+3)
	cps	iz, 0
	jr	z, 4
	ld	hl, iz
	jr	19
	ld	xwa, (xsp+14)
	ld	xbc, xwa
	ld	a, (xwa+3)
	ld	(xbc+4), a
	ld	xwa, (xsp+2)
	incm8	1, (xwa+3)
	lds	hl, 0
	popw	iz
	inc	8, xsp
	ret
	dec	8, xsp
	push	xiz
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+30)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+26)
	or	xwa, xwa
	jr	nz, 62
	ld	xwa, (xsp+8)
	ld	bc, (xwa+38)
	extz	xbc
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+22)
	call	16714776
	ld	xwa, (xsp+8)
	ld	xbc, (xwa+28)
	add	xbc, xhl
	ld	xwa, (xsp+22)
	ld	(xwa), xbc
	ld	xwa, (xsp+22)
	ld	xbc, (xwa)
	ld	xwa, (xsp+8)
	sub	xbc, (xwa+28)
	ld	xwa, (xsp+8)
	ld	wa, (xwa+46)
	extz	xwa
	sub	xwa, xbc
	ld	xbc, (xsp+26)
	ld	(xbc), wa
	lds	hl, 0
	jrl	363
	ld	xwa, (xsp+16)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+8)
	.byte 0x98, 0x28, 0x51
	ld	(xsp+4), bc
	ld	xwa, (xsp+8)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+22)
	call	16714770
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+38)
	extz	xbc
	ld	xwa, xiz
	call	16714776
	ld	a, l
	ld	(xsp+6), a
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	cp	wa, (xsp+4)
	jr	nz, 66
	ld	xwa, (xsp+16)
	cpw	(xwa+42), 0
	jr	nz, 33
	ld	xwa, (xsp+16)
	bitm	1, (xwa+3)
	jr	z, 25
	pushm	(xsp+20)
	pushw 0
	ld	xwa, (xsp+20)
	push	xwa
	calr	-3924
	inc	8, xsp
	ld	wa, hl
	cps	wa, 0
	jrl	z, 181
	jrl	255
	ld	xwa, (xsp+16)
	cpw	(xwa+44), 0
	jrl	nz, 167
	ld	xwa, (xsp+16)
	push	xwa
	calr	-4036
	inc	4, xsp
	jrl	155
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	cp	wa, (xsp+4)
	jr	ule, 19
	ld	xwa, (xsp+16)
	ld	xbc, xwa
	ld	wa, (xwa+69)
	ld	(xbc+42), wa
	ld	xwa, (xsp+16)
	ldw	(xwa+46), 0
	ld	xwa, (xsp+16)
	ld	hl, (xwa+42)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	cp	wa, (xsp+4)
	jr	nc, 99
	pushw	hl
	ld	xwa, (xsp+18)
	push	xwa
	calr	-4834
	inc	6, xsp
	ld	xwa, (xsp+8)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	wa, hl
	jr	nz, 6
	ldw	hl, 39
	jrl	157
	ld	xwa, (xsp+8)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	hl, wa
	jr	ule, 36
	ld	xwa, (xsp+16)
	bitm	1, (xwa+3)
	jr	z, 23
	pushm	(xsp+20)
	pushw 0
	ld	xwa, (xsp+20)
	push	xwa
	calr	-4067
	inc	8, xsp
	ld	wa, hl
	cps	wa, 0
	jr	z, 39
	jr	114
	ldw	hl, 8
	jr	109
	ld	xwa, (xsp+16)
	ld	(xwa+42), hl
	ld	xwa, (xsp+16)
	incm	1, (xwa+46)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	cp	wa, (xsp+4)
	jr	c, -99
	ld	xwa, (xsp+16)
	push	xwa
	calr	-4194
	inc	4, xsp
	lds32	xwa, 0
	ld	a, (xsp+6)
	ld	xbc, xwa
	ld	xwa, (xsp+8)
	add	xbc, (xwa+20)
	ld	xwa, (xsp+22)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	lda	xbc, (xwa+32)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+42)
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	16714332
	ld	xwa, (xsp+22)
	add	(xwa), xhl
	ld	xwa, (xsp+16)
	ld	wa, (xwa+44)
	extz	xwa
	ld	xbc, (xsp+8)
	ld	xbc, (xbc+32)
	call	16714332
	lds32	xwa, 0
	ld	a, (xsp+6)
	sub	xhl, xwa
	ld	xwa, (xsp+26)
	ld	(xwa), hl
	lds	hl, 0
	pop	xiz
	inc	8, xsp
	ret
	dec	6, xsp
	push	xiz
	ld	xiz, (xsp+14)
	lda	xwa, (xsp+4)
	push	xwa
	lda	xwa, (xsp+10)
	push	xwa
	pushw 1
	push	xiz
	calr	-472
	lda	xsp, (xsp+14)
	ld	wa, hl
	cps	wa, 0
	jr	nz, 42
	ld	wa, (xsp+18)
	set	3, wa
	pushw	wa
	ld	xwa, (xiz+34)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	push	xiz
	calr	-6512
	lda	xsp, (xsp+14)
	ld	(xiz+34), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, 5
	ldw	hl, 10
	jr	6
	ld	xwa, (xiz+34)
	ld	hl, (xwa+20)
	pop	xiz
	inc	6, xsp
	ret
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, (xsp+20)
	cpw	(xsp+28), 0
	jr	nz, 5
	lds	hl, 0
	jrl	372
	ld	xwa, (xiz+30)
	ld	(xsp+6), xwa
	ld	xbc, (xiz+22)
	ld	xwa, (xsp+6)
	.byte 0x98, 0x28, 0x51
	ld	(xsp+4), bc
	ld	wa, (xsp+28)
	exts	xwa
	ld	xbc, xwa
	add	xbc, (xiz+22)
	ld	xwa, (xsp+6)
	ld	wa, (xwa+40)
	extz	xwa
	add	xwa, xbc
	ld	xde, xwa
	dec	1, xde
	ld	xwa, (xsp+6)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, xde
	call	16714776
	ld	wa, (xsp+4)
	extz	xwa
	sub	xhl, xwa
	lda	xwa, (xsp+10)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	pushw	hl
	push	xiz
	calr	-622
	add	xsp, 14
	cps	hl, 0
	jr	z, 17
	ld	a, l
	exts	wa
	st16_24	124220, wa
	ld	(xiz+6), wa
	lds	hl, 0
	jrl	269
	ld	xwa, (xiz+34)
	or	xwa, xwa
	jr	z, 19
	ld	xwa, (xiz+34)
	ld	a, (xwa+22)
	and	a, 3
	cps	a, 3
	jr	nz, 47
	ld	xwa, (xiz+34)
	resm	3, (xwa+22)
	pushw 40
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	push	xiz
	calr	-6701
	lda	xsp, (xsp+14)
	ld	(xiz+34), xhl
	or	xhl, xhl
	jr	nz, 17
	ldw	(xiz+6), 10
	sti16_24	124220, 10
	lds	hl, 0
	jrl	202
	ld	xbc, (xiz+34)
	ld	xwa, (xsp+24)
	ld	(xbc+12), xwa
	ld	wa, (xsp+28)
	ld	(xsp+4), wa
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98, 0x26, 0x51
	ld	(xsp+4), bc
	ld	xbc, (xiz+34)
	lda	xbc, (xbc+16)
	ld	wa, (xsp+4)
	cp	wa, (xsp+10)
	jr	nc, 5
	ld	wa, (xsp+4)
	jr	3
	ld	wa, (xsp+10)
	ld	(xbc), wa
	ld	xwa, (xiz+34)
	ld	wa, (xwa+16)
	ld	(xsp+4), wa
	cpw	(xsp+30), 0
	jr	z, 29
	ld	xwa, (xiz+34)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+16)
	call	(xwa)
	inc	8, xsp
	ld	xwa, (xiz+34)
	ld	(xwa+20), hl
	ld	(xiz+6), hl
	jr	27
	ld	xwa, (xiz+34)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+20)
	call	(xwa)
	inc	8, xsp
	ld	xwa, (xiz+34)
	ld	(xwa+20), hl
	ld	(xiz+6), hl
	ld	xwa, (xiz+34)
	resm	3, (xwa+22)
	ld	xbc, (xiz+34)
	lds32	xwa, 0
	ld	(xbc+12), xwa
	ld	xwa, (xiz+34)
	cpw	(xwa+20), 0
	jr	z, 4
	lds	hl, 0
	jr	11
	ld	bc, (xsp+4)
	ld	xwa, (xsp+6)
	.byte 0x98, 0x26, 0x41
	ld	hl, bc
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98, 0x28, 0x51
	sub	(xiz+44), bc
	ld	xwa, (xiz+34)
	ld	(xwa+22), 0
	ld	xwa, (xiz+34)
	cpw	(xwa+20), 35
	jr	nz, 8
	ld	xwa, (xiz+34)
	ldw	(xwa+20), 0
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	dec	4, xsp
	pushw	iz
	ldw	(xsp+2), 0
	ld	wa, (xsp+18)
	ld	(xsp+4), wa
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	cp	xbc, (xwa+22)
	jr	nz, 13
	ld	xwa, (xsp+10)
	.byte 0x98, 0x06, 0x3e, 0x00, 0x80
	lds	hl, 0
	jrl	507
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	sub	xbc, (xwa+22)
	ld	wa, (xsp+18)
	extz	xwa
	cp	xwa, xbc
	jr	nc, 9
	ld	wa, (xsp+18)
	extz	xwa
	ld	xbc, xwa
	jr	12
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	sub	xbc, (xwa+22)
	ld	(xsp+18), bc
	cpw	(xsp+18), 0
	jrl	z, 435
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	and	xbc, (xwa+22)
	jr	nz, 40
	ld	xwa, (xsp+10)
	cpw	(xwa+6), 35
	jr	z, 30
	ld	xwa, (xsp+10)
	bitm	2, (xwa+3)
	jr	nz, 22
	cpw	(xsp+20), 0
	jr	nz, 15
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+30)
	ld	wa, (xsp+18)
	cp	wa, (xbc+38)
	jrl	nc, 168
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	nz, 33
	pushw 64
	ld	xwa, (xsp+12)
	push	xwa
	calr	-643
	inc	6, xsp
	ld	wa, hl
	cps	wa, 0
	jr	z, 26
	ld	a, l
	exts	wa
	st16_24	124220, wa
	ld	hl, (xsp+2)
	jrl	354
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	bitm	0, (xwa+22)
	jr	z, -44
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	and	xbc, (xwa+22)
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	de, (xwa+38)
	sub	de, bc
	ld	wa, bc
	extz	xwa
	lda	xbc, (xwa+26)
	ld	xwa, (xsp+10)
	add	xbc, (xwa+34)
	ld	xwa, (xsp+10)
	bitm	2, (xwa+3)
	jrl	nz, 148
	cpw	(xsp+20), 0
	jrl	nz, 140
	cp	(xsp+18), de
	jr	nc, 5
	ld	wa, (xsp+18)
	jr	2
	ld	wa, de
	ld	iz, wa
	pushw	wa
	push	xbc
	ld	xwa, (xsp+20)
	push	xwa
	call	16715161
	lda	xsp, (xsp+10)
	sub	(xsp+18), iz
	ld	wa, iz
	extz	xwa
	add	(xsp+14), xwa
	add	(xsp+2), iz
	ld	bc, iz
	extz	xbc
	ld	xwa, (xsp+10)
	add	(xwa+22), xbc
	cpw	(xsp+18), 0
	jrl	z, 168
	pushw 1
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xwa, (xwa+4)
	cpl	wa
	cpl	qwa
	ld	bc, (xsp+20)
	extz	xbc
	and	xbc, xwa
	pushw	bc
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	-751
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+10)
	cpw	(xwa+6), 0
	jr	z, 6
	ld	hl, (xsp+2)
	jrl	172
	sub	(xsp+18), iz
	ld	wa, iz
	extz	xwa
	add	(xsp+14), xwa
	add	(xsp+2), iz
	ld	bc, iz
	extz	xbc
	ld	xwa, (xsp+10)
	add	(xwa+22), xbc
	jr	86
	cp	(xsp+18), de
	jr	nc, 5
	ld	wa, (xsp+18)
	jr	2
	ld	wa, de
	ld	iz, wa
	cps	iz, 0
	jr	z, 68
	ld	xwa, (xsp+10)
	bitm	2, (xwa+3)
	jr	z, 9
	cp	(xbc), 13
	jr	nz, 4
	inc	1, xbc
	jr	40
	decm	1, (xsp+18)
	incm	1, (xsp+2)
	ld_spib	e, 228
	ld	xwa, (xsp+14)
	.byte 0xf5, 0xe0, 0x45
	ld	(xsp+14), xwa
	ld	xwa, (xsp+10)
	cp	(xwa+2), e
	jr	nz, 14
	cpw	(xsp+20), 0
	jr	z, 7
	ldw	(xsp+18), 0
	lds	iz, 1
	ld	xwa, (xsp+10)
	lds32	xde, 1
	add	(xwa+22), xde
	djnz16	iz, -68
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	and	xbc, (xwa+22)
	jr	nz, 17
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	resm	3, (xwa+22)
	ld	xwa, (xsp+10)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	cpw	(xsp+18), 0
	jrl	nz, -435
	ld	wa, (xsp+2)
	cp	wa, (xsp+4)
	jr	nc, 8
	ld	xwa, (xsp+10)
	.byte 0x98, 0x06, 0x3e, 0x00, 0x80
	ld	hl, (xsp+2)
	popw	iz
	inc	4, xsp
	ret
SeqChan_SetupAndCallHelper:
	.byte 0x0b
	nop
	nop
	ld	wa, (xsp+14)
	pushw	wa
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	64966
	lda	xsp, (xsp+12)
	ret
SeqChan_InitChannelState:
	pushw 1
	ld	wa, (xsp+14)
	pushw	wa
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	-592
	lda	xsp, (xsp+12)
	ret
	dec	6, xsp
	pushw	iz
	ldw	(xsp+2), 0
	ldw	(xsp+6), 0
	cpw	(xsp+20), 0
	jr	z, 12
	ld	xwa, (xsp+12)
	setm	7, (xwa+3)
	ld	xwa, (xsp+12)
	setm	5, (xwa+64)
	cpw	(xsp+20), 0
	jrl	z, 584
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	and	xbc, (xwa+22)
	ld	(xsp+4), bc
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	and	xbc, (xwa+22)
	jr	nz, 40
	ld	xwa, (xsp+12)
	cpw	(xwa+6), 35
	jr	z, 30
	ld	xwa, (xsp+12)
	bitm	2, (xwa+3)
	jr	nz, 22
	cpw	(xsp+22), 0
	jr	nz, 15
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+38)
	cp	(xsp+20), wa
	jrl	ge, 192
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	nz, 60
	cpw	(xsp+4), 0
	jr	nz, 14
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+38)
	cp	(xsp+20), wa
	jr	ge, 5
	ldw	wa, 64
	jr	3
	ldw	wa, 96
	pushw	wa
	ld	xwa, (xsp+14)
	push	xwa
	calr	-1230
	inc	6, xsp
	ld	wa, hl
	cps	wa, 0
	jr	z, 15
	ld	a, l
	exts	wa
	st16_24	124220, wa
	ld	hl, (xsp+2)
	jrl	442
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	setm	1, (xwa+22)
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	bc, (xsp+4)
	ld	wa, (xwa+38)
	sub	wa, bc
	ld	hl, wa
	ld	bc, (xsp+4)
	add	bc, 26
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	lda_rr	xde, xwa, bc
	ld	xwa, (xsp+12)
	bitm	2, (xwa+3)
	jrl	nz, 157
	cpw	(xsp+22), 0
	jrl	nz, 149
	cp	(xsp+20), hl
	jr	ge, 5
	ld	wa, (xsp+20)
	jr	2
	ld	wa, hl
	ld	iz, wa
	pushw	wa
	ld	xwa, (xsp+18)
	push	xwa
	push	xde
	call	16715161
	lda	xsp, (xsp+10)
	sub	(xsp+20), iz
	ld	xwa, (xsp+16)
	lda_rr	xwa, xwa, iz
	ld	(xsp+16), xwa
	add	(xsp+2), iz
	ld	bc, iz
	exts	xbc
	ld	xwa, (xsp+12)
	add	(xwa+22), xbc
	cpw	(xsp+20), 0
	jrl	z, 250
	pushw 0
	ld	xwa, (xsp+14)
	ld	xwa, (xwa+30)
	ld	xwa, (xwa+4)
	cpl	wa
	cpl	qwa
	ld	bc, (xsp+22)
	exts	xbc
	and	xbc, xwa
	pushw	bc
	ld	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	calr	-1335
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+12)
	cpw	(xwa+6), 0
	jr	z, 6
	ld	hl, (xsp+2)
	jrl	263
	sub	(xsp+20), iz
	ld	xwa, (xsp+16)
	lda_rr	xwa, xwa, iz
	ld	(xsp+16), xwa
	add	(xsp+2), iz
	ld	bc, iz
	exts	xbc
	ld	xwa, (xsp+12)
	add	(xwa+22), xbc
	jrl	163
	cp	(xsp+20), hl
	jr	ge, 5
	ld	wa, (xsp+20)
	jr	2
	ld	wa, hl
	ld	iz, wa
	cps	iz, 0
	jrl	z, 144
	ld	xwa, (xsp+12)
	bitm	2, (xwa+3)
	jr	z, 79
	cpw	(xsp+6), 0
	jr	z, 28
	stib_dpi	232, 10
	ldw	(xsp+6), 0
	decm	1, (xsp+20)
	cpw	(xsp+22), 0
	jr	z, 95
	ldw	(xsp+20), 0
	lds	iz, 1
	jr	86
	ld	xwa, (xsp+16)
	cp	(xwa), 10
	jr	nz, 16
	stib_dpi	232, 13
	lds32	xwa, 1
	add	(xsp+16), xwa
	ldw	(xsp+6), 1
	jr	15
	ld	xwa, (xsp+16)
	ld_spib	c, 224
	.byte 0xf5, 0xe8, 0x43
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incm	1, (xsp+2)
	jr	42
	ld	xwa, (xsp+16)
	ld_spib	c, 224
	ld	(xde), c
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incm	1, (xsp+2)
	ld	xwa, (xsp+12)
	ld	a, (xwa+2)
	.byte 0xc5, 0xe8, 0xf1
	jr	nz, 14
	cpw	(xsp+22), 0
	jr	z, 7
	ldw	(xsp+20), 0
	lds	iz, 1
	ld	xwa, (xsp+12)
	lds32	xbc, 1
	add	(xwa+22), xbc
	sub	iz, 1
	jrl	nz, -144
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+12)
	cp	xbc, (xwa+71)
	jr	ule, 11
	ld	xwa, (xsp+12)
	ld	xbc, xwa
	ld	xwa, (xwa+22)
	ld	(xbc+71), xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	and	xbc, (xwa+22)
	jr	nz, 17
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	resm	3, (xwa+22)
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	cpw	(xsp+20), 0
	jrl	nz, -584
	ld	hl, (xsp+2)
	popw	iz
	inc	6, xsp
	ret
SeqChan_ProcessEventArg0:
	pushw 0
	pushm	(xsp+14)
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	-648
	lda	xsp, (xsp+12)
	ret
SeqChan_ProcessEventArg1:
	pushw 1
	pushm	(xsp+14)
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	-669
	lda	xsp, (xsp+12)
	ret
SeqChan_ValidateAndDispatch:
	push	xiz
	ld	xiz, (xsp+8)
	ld	xwa, (xiz+34)
	or	xwa, xwa
	jr	z, 6
	ld	xwa, (xiz+34)
	resm	3, (xwa+22)
	cpi8_24	254690, 0
	jr	nz, 4
	lds	hl, 0
	jr	31
	bitm	7, (xiz+3)
	jr	z, 10
	push	xiz
	calr	-3789
	inc	4, xsp
	cps	hl, 0
	jr	nz, 16
	ld	xwa, (xiz+18)
	decm8	1, (xwa+3)
	ld	(xiz+4), 0
	push	xiz
	calr	-7465
	inc	4, xsp
	pop	xiz
	ret
SeqChan_TraverseAndProcess:
	dec	4, xsp
	push	xiz
	ldw	(xsp+6), 0
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+71)
	cp	xwa, (xsp+16)
	jr	nc, 116
	ld	xwa, (xsp+12)
	bitm	1, (xwa+3)
	jr	nz, 8
	ldw	(xsp+6), 20
	jrl	205
	ld	xwa, (xsp+12)
	ld	xbc, xwa
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	pushw 32
	ld	xwa, (xsp+14)
	push	xwa
	calr	-1859
	inc	6, xsp
	ld	(xsp+6), hl
	ld	wa, (xsp+6)
	cps	wa, 0
	jrl	nz, 171
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+16)
	call	16714776
	ld	xwa, (xsp+12)
	ld	wa, (xwa+46)
	extz	xwa
	sub	xhl, xwa
	pushw	hl
	pushw 0
	ld	xwa, (xsp+16)
	push	xwa
	calr	-6106
	inc	8, xsp
	ld	(xsp+6), hl
	ld	wa, (xsp+6)
	cps	wa, 0
	jr	nz, 120
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+71), xbc
	ld	xwa, (xsp+12)
	setm	7, (xwa+3)
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	z, 18
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	andmi8	(xwa+22), 231
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+22), xbc
	lda_24	xwa, 135706
	ld	xiz, xwa
	ldw	(xsp+4), 0
	cpw	(xsp+4), 10
	jr	ge, 49
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	cp	a, (xiz+23)
	jr	nz, 23
	ld	a, (xiz+22)
	and	a, 3
	cps	a, 3
	jr	nz, 13
	push	xiz
	calr	-7909
	inc	4, xsp
	or	(xsp+6), hl
	andmi8	(xiz+22), 229
	incm	1, (xsp+4)
	lda	xiz, (xiz+538)
	cpw	(xsp+4), 10
	jr	lt, -49
	ld	hl, (xsp+6)
	pop	xiz
	inc	4, xsp
	ret
SeqChan_ReadNextFromLoop:
	lda	xsp, (xsp-30)
	push	xiz
	ld	xiz, (xsp+38)
	pushw 1
	pushw 1
	push	xiz
	calr	-6262
	inc	8, xsp
	ld	(xsp+4), hl
	cpw	(xsp+4), 0
	jrl	nz, 136
	pushw 0
	push	xiz
	calr	-2087
	inc	6, xsp
	ld	(xsp+4), hl
	cpw	(xsp+4), 0
	jr	nz, 117
	ld	xwa, (xiz+34)
	lda	xwa, (xwa+26)
	ld	(xsp+6), xwa
	pushw 228
	pushw 20522
	lda	xwa, (xsp+14)
	push	xwa
	call	16715597
	ld	(xsp+30), 16
	lda	xwa, (xsp+31)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call	(xwa)
	ld	wa, (xiz+69)
	ld	(xsp+39), wa
	lds32	xwa, 0
	ld	(xsp+41), xwa
	ld	xbc, (xsp+18)
	ld	xwa, 32
	add	(xsp+18), xwa
	push	xbc
	lda	xwa, (xsp+26)
	push	xwa
	calr	-7414
	ld	(xsp+31), 46
	ld	wa, (xiz+48)
	ld	(xsp+47), wa
	ld	xwa, (xsp+26)
	push	xwa
	lda	xwa, (xsp+34)
	push	xwa
	calr	-7435
	lda	xsp, (xsp+28)
	ld	xwa, (xiz+34)
	setm	1, (xwa+22)
	ld	xwa, (xiz+34)
	resm	3, (xwa+22)
	lds32	xwa, 0
	ld	(xiz+71), xwa
	ld	(xiz+64), 16
	setm	7, (xiz+3)
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+30)
	ret
SeqChan_WritePatchData:
	dec	2, xsp
	push	xiz
	ld	xiz, (xsp+10)
	ld	(xiz+52), 229
	push	xiz
	calr	-4248
	ld	(xsp+8), hl
	push	xiz
	calr	-7911
	or	(xsp+12), hl
	ld	a, (xiz+5)
	extz	wa
	ld	bc, wa
	sla	bc, 2
	lda_24	xde, 135348
	lds32	xwa, 0
	.byte 0xf3, 0x07, 0xe8, 0xe4, 0x60
	ld	xwa, xiz
	push	xwa
	call	16052743
	lda	xsp, (xsp+12)
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
SeqChan_WriteExtendedPatch:
	push	xiz
	ld	xiz, (xsp+8)
	ld	wa, (xsp+12)
	cp	wa, 21
	jr	z, 80
	cp	wa, 20
	jr	z, 19
	cps	wa, 1
	jr	nz, 85
	push	xiz
	calr	-7980
	inc	4, xsp
	cps	hl, 0
	jr	z, 56
	ldw	hl, 65535
	jr	80
	lds32	xwa, 4
	add	(xsp+14), xwa
	ld	xwa, (xsp+14)
	ld	xbc, (xwa-4)
	ld	a, (xiz+64)
	ld	(xbc+64), a
	ld	wa, (xiz+65)
	ld	(xbc+65), wa
	ld	wa, (xiz+67)
	ld	(xbc+67), wa
	ld	wa, (xiz+69)
	ld	(xbc+69), wa
	ld	xwa, (xiz+71)
	ld	(xbc+71), xwa
	ld	(xiz+52), 229
	setm	7, (xiz+3)
	setm	7, (xbc+3)
	lds	hl, 0
	jr	25
	push	xiz
	calr	-4299
	inc	4, xsp
	ld	(xiz+52), 229
	setm	7, (xiz+3)
	jr	-19
	sti16_24	124220, 18
	ldw	hl, 65535
	pop	xiz
	ret

SeqStep_CountValidSectors:
	push xiz
	ldi_werp 0xFA, 0
	sti16_24 0x01e53c, 0x0000
	lds iz, 0
	jr SeqStep_CountLoop_Compare

SeqStep_CountLoop_Body:
	pushw iz
	ld xwa, (xsp + 10)
	push xwa
	calr SeqStep_FileSectorError
	inc 6, xsp
	cps hl, 0
	jr nz, SeqStep_CountLoop_CheckEnd
	inc1_werp 0xFA

SeqStep_CountLoop_CheckEnd:
	cpdi16_24 124220, 0
	jr nz, SeqStep_CountLoop_ResetWerp
	ld xwa, (xsp + 8)
	cpw (xwa + 6), 0x0
	jr z, SeqStep_CountLoop_IncIz

SeqStep_CountLoop_ResetWerp:
	ldi_werp 0xFA, 0
	jr SeqStep_CountLoop_Done

SeqStep_CountLoop_IncIz:
	inc 1, iz

SeqStep_CountLoop_Compare:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 30)
	cp iz, (xwa + 54)
	jr ule, SeqStep_CountLoop_Body

SeqStep_CountLoop_Done:
	ldto_werp HL, 0xFA
	pop xiz
	ret

SeqStep_CalcTotalSectors:
	ld xwa, (xsp + 4)
	push xwa
	calr SeqStep_CountValidSectors
	inc 4, xsp
	ld bc, hl
	extz xbc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 30)
	ld wa, (xwa + 40)
	extz xwa
	call Math_MultiplyAccumulate
	ret

SeqStep_SectorCompareBlock:
	ld	xde, (xsp+4)
	cpw	(xsp+8), 0
	jr	z, 40
	ld	bc, (xsp+10)
	and	bc, 24
	ld	a, (xde+64)
	extz	wa
	and	wa, 24
	cp	wa, bc
	jr	z, 11
	sti16_24	124220, 13
	ldw	hl, 65535
	ret
	ld	wa, (xsp+10)
	ld	(xde+64), a
	setm	7, (xde+3)
	ld	l, (xde+64)
	extz	hl
	ret
	dec	2, xsp
	push	xiz
	pushw 228
	pushw 20534
	ld	xwa, (xsp+14)
	push	xwa
	call	16051095
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 5
	ldw	hl, 65535
	jr	24
	pushm	(xsp+14)
	pushw 1
	push	xiz
	calr	-96
	ld	(xsp+12), hl
	push	xiz
	call	16052314
	lda	xsp, (xsp+12)
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
	ld	hl, (xsp+8)
	ld	xbc, (xsp+4)
	ld	xwa, (xbc+30)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	hl, wa
	jr	ule, 3
	lds	hl, 0
	ret
	cps	hl, 0
	jr	z, 8
	pushw	hl
	push	xbc
	calr	-7669
	inc	6, xsp
	ret
	ld	hl, (xbc+69)
	ret

SeqStep_ParseVariableHeader:
	lda xsp, (xsp - 16)
	ld wa, (xsp + 20)
	ld (xsp + 256), wa
	ld wa, (xsp + 22)
	ld (xsp + 2), wa
	ld wa, (xsp + 24)
	ld (xsp + 4), wa
	ld wa, (xsp + 26)
	ld (xsp + 6), wa
	ld wa, (xsp + 28)
	ld (xsp + 8), wa
	ld wa, (xsp + 30)
	ld (xsp + 10), wa
	ld xwa, (xsp + 32)
	ld (xsp + 12), xwa
	lda xwa, (xsp)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	lda xsp, (xsp + 16)
	ret

SeqStep_ParseHeaderContinue:
	lds32 xwa, 0
	push xwa
	pushw 0x0
	pushw 0x0
	pushw 0x0
	pushw 0x0
	pushw 0x0
	pushw 0x7
	calr SeqStep_ParseVariableHeader
	lda xsp, (xsp + 16)
	ret

SeqChan_ByteBlockA:
	lds	hl, 0
	ret
SeqChan_ByteBlockB:
	lds	hl, 0
	ret
SeqChan_ByteBlockC:
	push	xiz
	ld	xiz, (xsp+20)
	call	16064067
	cps	hl, 0
	jr	z, 9
	call	16064049
	lds	hl, 6
	jrl	136
	call	16064073
	cps	l, 2
	jr	nz, 97
	cpw	(xsp+12), 0
	jr	nz, 90
	cpw	(xsp+14), 0
	jr	nz, 83
	cpw	(xsp+16), 1
	jr	nz, 76
	stdi16	35344, 65535
	push	xiz
	pushw 1
	pushw 1
	pushw 0
	pushw 0
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 3
	calr	-176
	lda	xsp, (xsp+16)
	stdi16	35344, 0
	cps	hl, 0
	jr	nz, 8
	ld	(xiz+16), 2
	lds	hl, 0
	jr	52
	pushw 512
	pushw 228
	pushw 20536
	push	xiz
	call	16715161
	lda	xsp, (xsp+10)
	lds	hl, 0
	jr	31
	push	xiz
	pushm	(xsp+22)
	pushm	(xsp+22)
	pushm	(xsp+20)
	pushm	(xsp+24)
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 3
	calr	-246
	lda	xsp, (xsp+16)
	pop	xiz
	ret
SeqChan_ByteBlockD:
	ld	xwa, (xsp+16)
	push	xwa
	pushm	(xsp+18)
	pushm	(xsp+18)
	pushm	(xsp+16)
	pushm	(xsp+20)
	ld	xwa, (xsp+16)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 4
	calr	-282
	lda	xsp, (xsp+16)
	ret
	dec	2, xsp
	push	xiz
	ld	xiz, (xsp+14)
	ld	xbc, (xsp+10)
	ldw	(xsp+4), 0
	cpw	(xbc), 0
	jr	nz, 5
	lds	hl, 0
	jrl	220
	incdi16_24	1, 141086
	ld	wa, (xbc)
	cp	wa, 49
	jr	z, 116
	cp	wa, 48
	jr	z, 110
	cps	wa, 6
	jr	z, 67
	cp	wa, 51
	jr	z, 21
	cp	wa, 53
	jr	z, 15
	cp	wa, 47
	jr	nz, 125
	ldw	(xbc), 31
	lds	hl, 0
	jrl	170
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 33
	ld	xwa, (xiz)
	push	xwa
	calr	-290
	ld	xwa, (xiz)
	push	xwa
	call	16058402
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	121
	ldw	(xsp+4), 1
	jr	114
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 6
	ld	xwa, (xiz)
	ld	xwa, (xwa+26)
	ld	xwa, (xiz)
	push	xwa
	call	16058402
	inc	4, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	82
	ldw	(xsp+4), 1
	jr	75
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 32
	ld	xwa, (xiz)
	push	xwa
	calr	-369
	ld	xwa, (xiz)
	push	xwa
	call	16058402
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	42
	lds	hl, 0
	jr	54
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 36
	ld	xwa, (xiz)
	push	xwa
	calr	-406
	ld	xwa, (xiz)
	push	xwa
	call	16058402
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	5
	ldw	(xsp+4), 1
	cpdi16_24	141086, 1
	jr	lt, 4
	lds	hl, 0
	jr	3
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
SeqChan_ByteBlockE:
	lda	xsp, (xsp-12)
	pushw	iz
	sti16_24	141086, 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98, 0x32, 0x51
	ld	wa, qbc
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16714776
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98, 0x34, 0x51
	ld	wa, qbc
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98, 0x34, 0x53
	ld	(xsp+8), hl
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	or	xwa, xwa
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	sub	iz, (xsp+10)
	ld	xwa, (xsp+22)
	cp	(xwa+16), iz
	jr	nc, 6
	ld	xwa, (xsp+22)
	ld	iz, (xwa+16)
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	push	xwa
	ld	wa, iz
	pushw	wa
	ld	wa, (xsp+16)
	inc	1, wa
	pushw	wa
	ld	wa, (xsp+14)
	pushw	wa
	ld	wa, (xsp+18)
	pushw	wa
	ld	xwa, (xsp+34)
	ld	xwa, (xwa)
	push	xwa
	calr	-586
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cps	wa, 0
	jr	nz, 118
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	cpw	(xwa+16), 0
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98, 0x26, 0x41
	add	xbc, (xde)
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	cp	bc, (xwa+50)
	jr	c, -117
	ldw	(xsp+10), 0
	incm	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	cp	bc, (xwa+52)
	jrl	nz, -137
	ldw	(xsp+6), 0
	incm	1, (xsp+8)
	jrl	-148
	ld	xwa, (xsp+22)
	lda	xwa, (xwa+26)
	push	xwa
	pushw 1
	ld	wa, (xsp+16)
	inc	1, wa
	pushw	wa
	ld	wa, (xsp+14)
	pushw	wa
	ld	wa, (xsp+18)
	pushw	wa
	ld	xwa, (xsp+34)
	ld	xwa, (xwa)
	push	xwa
	calr	-711
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	-534
	inc	8, xsp
	cps	hl, 0
	jrl	nz, -216
	ld	hl, (xsp+12)
	popw	iz
	lda	xsp, (xsp+12)
	ret
SeqChan_ByteBlockF:
	lda	xsp, (xsp-12)
	pushw	iz
	sti16_24	141086, 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98, 0x32, 0x51
	ld	wa, qbc
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16714776
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98, 0x34, 0x51
	ld	wa, qbc
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98, 0x34, 0x53
	ld	(xsp+8), hl
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	or	xwa, xwa
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	sub	iz, (xsp+10)
	ld	xwa, (xsp+22)
	cp	(xwa+16), iz
	jr	nc, 6
	ld	xwa, (xsp+22)
	ld	iz, (xwa+16)
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	push	xwa
	ld	wa, iz
	pushw	wa
	ld	wa, (xsp+16)
	inc	1, wa
	pushw	wa
	ld	wa, (xsp+14)
	pushw	wa
	ld	wa, (xsp+18)
	pushw	wa
	ld	xwa, (xsp+34)
	ld	xwa, (xwa)
	push	xwa
	calr	-727
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cps	wa, 0
	jr	nz, 118
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	cpw	(xwa+16), 0
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98, 0x26, 0x41
	add	xbc, (xde)
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	cp	bc, (xwa+50)
	jr	c, -117
	ldw	(xsp+10), 0
	incm	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	cp	bc, (xwa+52)
	jrl	nz, -137
	ldw	(xsp+6), 0
	incm	1, (xsp+8)
	jrl	-148
	ld	xwa, (xsp+22)
	lda	xwa, (xwa+26)
	push	xwa
	pushw 1
	ld	wa, (xsp+16)
	inc	1, wa
	pushw	wa
	ld	wa, (xsp+14)
	pushw	wa
	ld	wa, (xsp+18)
	pushw	wa
	ld	xwa, (xsp+34)
	ld	xwa, (xwa)
	push	xwa
	calr	-852
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	-834
	inc	8, xsp
	cps	hl, 0
	jrl	nz, -216
	ld	hl, (xsp+12)
	popw	iz
	lda	xsp, (xsp+12)
	ret
FDC_ReturnZeroLong:
	ld	xwa, (xsp+4)
	ldw	(xwa), 0
	ret
FDC_ReturnAndPop:
	lds	hl, 1
	ret

FDC_StoreDiskType:
	ld a, (xsp + 4)
	st8_24 0x03e3e4, a
	sti16_24 0x03e3e6, 0x0001
	sti8_24 0x03e3be, 0x00
	ret

FDC_ClearDiskChangeStatus:
	sti16_24	254950, 0
	ld8_24	a, 254948
	st8_24	254946, a
	ret
	ld16_24	hl, 254950
	ret

FDC_ReadDiskType:
	ld8_24 l, 0x03e3e4
	ret

format_FD:
	extz wa
	cps wa, 3
	jrl z, FDC_Format2HD_Start
	cps wa, 2
	jr nz, FDC_Format_InvalidType
	jr FDC_Format2DD_Start

FDC_Format_InvalidType:
	lds hl, 0
	ret

; ============================================================================
; FDC_SetSectorLength - Set FDC sector length register
; ============================================================================
; Input:  WA = disk format type code
; Output: Writes sector length to 0x01E53C
; Maps format codes: 0x2F->0x001F, 0x30/31->0x0020, 6->0x0006, etc.
; Called before FDC_CommandEntry to configure sector size.
; ============================================================================
FDC_SetSectorLength:
	extz wa
	cp wa, 0x31
	jr z, FDC_SectorLen_0x20
	cp wa, 0x30
	jr z, FDC_SectorLen_0x20
	cps wa, 6
	jr z, FDC_SectorLen_0x06
	cp wa, 0x33
	jr z, FDC_SectorLen_0x21
	cp wa, 0x35
	jr z, FDC_SectorLen_0x21
	cp wa, 0x2F
	jr nz, FDC_SectorLen_0x24
	sti16_24 0x01e53c, 0x001f
	ret

FDC_SectorLen_0x21:
	sti16_24 0x01e53c, 0x0021
	ret

FDC_SectorLen_0x06:
	sti16_24 0x01e53c, 0x0006
	ret

FDC_SectorLen_0x20:
	sti16_24 0x01e53c, 0x0020
	ret

FDC_SectorLen_0x24:
	sti16_24 0x01e53c, 0x0024
	ret

FDC_Format2DD_Start:
	lda xsp, (xsp - 20)
	push_werp 0xFA
	lds wa, 0
	calr FDC_SetSectorLength
	lda_24 xwa, 0xe45076
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_Step2
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_Step2:
	lda_24 xwa, 0xe45056
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_AllocBuf
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_AllocBuf:
	pushw 0x200
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, FDC_Format2DD_WriteBoot
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteBoot:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x20
	lda_24 xwa, 0xe450b6
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0x1
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteFAT1
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteFAT1:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x3
	lda_24 xwa, 0xe450d6
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0x2
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteFAT2
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteFAT2:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	ldw (xsp + 22), 0x3
	lda xwa, (xsp + 14)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 12)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteRoot
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteRoot:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	ldw (xsp + 22), 0x4
	lda xwa, (xsp + 14)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 12)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteDataSec1
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteDataSec1:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x3
	lda_24 xwa, 0xe450d6
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0x5
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteDataSec2
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteDataSec2:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	ldw (xsp + 22), 0x6
	lda xwa, (xsp + 14)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 12)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_WriteDataSec3
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_WriteDataSec3:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	ldw (xsp + 22), 0x7
	lda xwa, (xsp + 14)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 12)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_InitTrackLoop
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_InitTrackLoop:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	inc 8, xsp
	ldw (xsp + 6), 0x4
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x0
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	ldw (xsp + 14), 0x8
	jr FDC_Format2DD_TrackTest

FDC_Format2DD_TrackBody:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_TrackInc
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_TrackInc:
	incm 1, (xsp + 14)

FDC_Format2DD_TrackTest:
	cpw (xsp + 14), 0x9
	jr ule, FDC_Format2DD_TrackBody
	ldw (xsp + 10), 0x1
	ldw (xsp + 14), 0x1
	jr FDC_Format2DD_Side1Test

FDC_Format2DD_Side1Body:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_Side1Inc
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_Side1Inc:
	incm 1, (xsp + 14)

FDC_Format2DD_Side1Test:
	cpw (xsp + 14), 0x5
	jr ule, FDC_Format2DD_Side1Body
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x4F
	ldw (xsp + 14), 0x9
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2DD_FinalTrack
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jr FDC_CmdFrame_Epilogue

FDC_Format2DD_FinalTrack:
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x0
	ldw (xsp + 14), 0x9
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	ldfr_berp L, 0xFB
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 8, xsp
	cpi_berp 0xFB, 0
	jr nz, FDC_Format2DD_SetSectorAndRet
	lds hl, 1
	jr FDC_CmdFrame_Epilogue

FDC_Format2DD_SetSectorAndRet:
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FDC_CmdFrame_Epilogue:
	pop_werp 0xFA
	lda xsp, (xsp + 20)
	ret

FDC_Format2HD_Start:
	lda xsp, (xsp - 20)
	push_werp 0xFA
	lds wa, 0
	calr FDC_SetSectorLength
	lda_24 xwa, 0xe45096
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_Step2
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_Step2:
	lda_24 xwa, 0xe45056
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_AllocBuf
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_AllocBuf:
	pushw 0x200
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, FDC_Format2HD_WriteBoot
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_WriteBoot:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x20
	lda_24 xwa, 0xe450da
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0x1
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_WriteFAT1
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_WriteFAT1:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x3
	lda_24 xwa, 0xe450fa
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0x2
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_InitTrackLoop
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_InitTrackLoop:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	inc 8, xsp
	ldw (xsp + 14), 0x3
	jr FDC_Format2HD_TrackTest

FDC_Format2HD_TrackBody:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_TrackInc
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_TrackInc:
	incm 1, (xsp + 14)

FDC_Format2HD_TrackTest:
	cpw (xsp + 14), 0xA
	jr ule, FDC_Format2HD_TrackBody
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x3
	lda_24 xwa, 0xe450fa
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0xB
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_WriteFAT2
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_WriteFAT2:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	inc 8, xsp
	ldw (xsp + 14), 0xC
	jr FDC_Format2HD_Side2Test

FDC_Format2HD_Side2Body:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_Side2Inc
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_Side2Inc:
	incm 1, (xsp + 14)

FDC_Format2HD_Side2Test:
	cpw (xsp + 14), 0x12
	jr ule, FDC_Format2HD_Side2Body
	ldw (xsp + 10), 0x1
	ldw (xsp + 14), 0x1
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_InitSide1Loop
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_InitSide1Loop:
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	inc 8, xsp
	ldw (xsp + 14), 0x2
	jr FDC_Format2HD_Side1Test

FDC_Format2HD_Side1Body:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_Side1Inc
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_Side1Inc:
	incm 1, (xsp + 14)

FDC_Format2HD_Side1Test:
	cpw (xsp + 14), 0xF
	jr ule, FDC_Format2HD_Side1Body
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x4F
	ldw (xsp + 14), 0x12
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, FDC_Format2HD_FinalTrack
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	ld xwa, (xsp + 2)
	push xwa
	call Free
	inc 4, xsp
	lds hl, 0
	jr FdcOp_Epilogue20

FDC_Format2HD_FinalTrack:
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x0
	ldw (xsp + 14), 0x12
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	ldfr_berp L, 0xFB
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 8, xsp
	cpi_berp 0xFB, 0
	jr nz, FDC_Format2HD_SetSectorAndRet
	lds hl, 1
	jr FdcOp_Epilogue20

FDC_Format2HD_SetSectorAndRet:
	ldto_berp A, 0xFB
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FdcOp_Epilogue20:
	pop_werp 0xFA
	lda xsp, (xsp + 20)
	ret

GetMediaType:
	lda xsp, (xsp - 20)
	push_werp 0xFA
	call Reset_Floppy_Disk_Controller
	pushw 0x400
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, GetMediaType_SetupReadCmd
	ldi_berp 0xFB, 0
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	calr FDC_StoreDiskType
	inc 2, xsp
	ldto_berp L, 0xFB
	jrl GetMediaType_ReturnAndCleanup

GetMediaType_SetupReadCmd:
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x0
	ldw (xsp + 14), 0x2
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	stdi16 35344, 65535
	ldi_berp 0xFB, 0
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr nz, GetMediaType_TryRecalib
	ldi_berp 0xFB, 1
	jrl GetMediaType_Epilogue

GetMediaType_TryRecalib:
	lda_24 xwa, 0xe450a6
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_TryFormat2HD
	ldi_berp 0xFB, 0
	jrl GetMediaType_Epilogue

GetMediaType_TryFormat2HD:
	lda_24 xwa, 0xe45096
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_ReadSector
	ldi_berp 0xFB, 0
	jrl GetMediaType_Epilogue

GetMediaType_ReadSector:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr nz, GetMediaType_Try2DDHeader
	ld xwa, (xsp + 2)
	cp (xwa), 0xF0
	jr nz, GetMediaType_Type3Check
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jr nz, GetMediaType_Type3Check
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xFF
	jr nz, GetMediaType_Type3Check
	ldi_berp 0xFB, 3
	jr GetMediaType_Epilogue

GetMediaType_Type3Check:
	ld xwa, (xsp + 2)
	cp (xwa), 0xF9
	jr nz, GetMediaType_Invalid
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jr nz, GetMediaType_Invalid
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xFF
	jr nz, GetMediaType_Invalid
	ldi_berp 0xFB, 3
	jr GetMediaType_Epilogue

GetMediaType_Invalid:
	ldi_berp 0xFB, 0
	jr GetMediaType_Epilogue

GetMediaType_Try2DDHeader:
	lda_24 xwa, 0xe45076
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_Read2DDSector
	ldi_berp 0xFB, 0
	jr GetMediaType_Epilogue

GetMediaType_Read2DDSector:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr nz, GetMediaType_Epilogue
	ld xwa, (xsp + 2)
	cp (xwa), 0x0
	jr nz, GetMediaType_F9Check
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xFF
	jr nz, GetMediaType_F9Check
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xFF
	jr nz, GetMediaType_F9Check
	ldi_berp 0xFB, 6
	jr GetMediaType_Epilogue

GetMediaType_F9Check:
	ld xwa, (xsp + 2)
	cp (xwa), 0xF9
	jr nz, GetMediaType_CheckExtraFormat
	ldi_berp 0xFB, 2
	jr GetMediaType_Epilogue

GetMediaType_CheckExtraFormat:
	call FDC_DetectDiskFormat
	cps hl, 0
	jr nz, GetMediaType_Epilogue
	ldi_berp 0xFB, 5

GetMediaType_Epilogue:
	stdi16 35344, 0
	ld xwa, (xsp + 2)
	push xwa
	call Free
	ldto_berp A, 0xFB
	extz wa
	pushw wa
	calr FDC_StoreDiskType
	inc 6, xsp
	ldto_berp L, 0xFB

GetMediaType_ReturnAndCleanup:
	pop_werp 0xFA
	lda xsp, (xsp + 20)
	ret

GetDiskFreeSpace:
	dec 4, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), xwa
	calr FDC_ReadDiskType
	ld a, l
	extz wa
	cps wa, 0
	jr mi, FileIO_ReadFreeSpaceViaFAT
	cps wa, 6
	jr gt, FileIO_ReadFreeSpaceViaFAT
	add wa, wa
	lda_24 xix, 0xe45104
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf5277e
	jp_dri 8, 0x07, 0xF0, 0xE0

GetDiskFreeSpace_JumpTable:
	lds	hl, 0
	jr	72
	ld	xwa, 730112
	ld	(xiz), xwa
	jr	16
	ld	xwa, 1457664
	ld	(xiz), xwa
	jr	7
	.byte 0x40, 0x00
	ld	xwa, 0x60b6000b

FileIO_ReadFreeSpaceViaFAT:
	pushw 0xE4
	pushw 0x50FE
	pushw 0xE4
	pushw 0x5100
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, GetDiskFreeSpace_ReadFAT
	lds hl, 0
	jr GetDiskFreeSpace_Epilogue

GetDiskFreeSpace_ReadFAT:
	push xiz
	call SeqStep_CalcTotalSectors
	ld xwa, (xsp + 8)
	ld (xwa), xhl
	push xiz
	call FileClose
	inc 8, xsp
	lds hl, 1

GetDiskFreeSpace_Epilogue:
	pop xiz
	inc 4, xsp
	ret

GetVolumeLabel:
	lda xsp, (xsp - 56)
	push xiz
	calr FDC_ReadDiskType
	ld a, l
	extz wa
	cps wa, 0
	jr mi, FileIO_ReadVolumeLabelEntry
	cps wa, 6
	jr gt, FileIO_ReadVolumeLabelEntry
	add wa, wa
	lda_24 xix, 0xe45118
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf527f7
	jp_dri 8, 0x07, 0xF0, 0xE0

GetVolumeLabel_JumpTable:
	lds32	xhl, 0
	jrl	155

FileIO_ReadVolumeLabelEntry:
	pushw 0xE4
	pushw 0x5112
	pushw 0xE4
	pushw 0x5114
	call FileOpen
	inc 8, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, GetVolumeLabel_ReadDir
	lds32 xhl, 0
	jr GetVolumeLabel_Return

GetVolumeLabel_ReadDir:
	push xiz
	pushw 0x1
	pushw 0x20
	lda xwa, (xsp + 12)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cps hl, 1
	jr nz, GetVolumeLabel_NotFound

GetVolumeLabel_ScanEntry:
	lda xwa, (xsp + 4)
	push xwa
	lda xwa, (xsp + 40)
	push xwa
	call SeqStep_FileSectorComplete
	inc 8, xsp
	bitm 1, (xsp + 48)
	jr nz, GetDiskSpace_ReadLoop
	cp (xsp + 36), 0xE5
	jr z, GetDiskSpace_ReadLoop
	cp (xsp + 36), 0x0
	jr z, GetVolumeLabel_NotFound
	bitm 3, (xsp + 48)
	jr z, GetDiskSpace_ReadLoop
	pushw 0xB
	lda xwa, (xsp + 38)
	push xwa
	lda_24 xwa, 0x022720
	push xwa
	call Mem_Copy
	sti8_24 0x02272b, 0x00
	push xiz
	call FileClose
	lda xsp, (xsp + 14)
	lda_24 xhl, 0x022720
	jr GetVolumeLabel_Return

GetDiskSpace_ReadLoop:
	push xiz
	pushw 0x1
	pushw 0x20
	lda xwa, (xsp + 12)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cps hl, 1
	jr z, GetVolumeLabel_ScanEntry

GetVolumeLabel_NotFound:
	push xiz
	call FileClose
	inc 4, xsp
	lds32 xhl, 0

GetVolumeLabel_Return:
	pop xiz
	lda xsp, (xsp + 56)
	ret

FileIO_CheckPathAndVolumeLabel:
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xwa
	calr GetVolumeLabel
	or xhl, xhl
	jr z, PathInfo_BuildAndOpen
	lds hl, 0
	jr PathInfo_RetVal

PathInfo_BuildAndOpen:
	ld (xsp + 6), 0x0
	pushw 0xE4
	pushw 0x5126
	lda xwa, (xsp + 10)
	push xwa
	call Strcat
	ld xwa, xiz
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call Strcat
	pushw 0xE4
	pushw 0x512A
	lda xwa, (xsp + 26)
	push xwa
	call FileOpen
	add xsp, 0x18
	or xhl, xhl
	jr nz, PathInfo_CheckAttrib
	lds hl, 0
	jr PathInfo_RetVal

PathInfo_CheckAttrib:
	ld (xhl + 64), 0x28
	setm 7, (xhl + 3)
	push xhl
	call FileClose
	inc 4, xsp
	ld wa, (xsp + 4)
	and a, 0x8
	cp a, 0x8
	jr z, PathInfo_FoundSubdir
	lds hl, 0
	jr PathInfo_RetVal

PathInfo_FoundSubdir:
	lds hl, 1

PathInfo_RetVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_ParsePathComponents:
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xbc
	ld (xsp + 18), xwa
	lds de, 0
	ld xwa, (xsp + 18)
	ld (xwa), 0x0
	ld xhl, (xiz)
	jr FileIO_ParseLoop_Test

FileIO_ParseLoop_CheckChar:
	ld xwa, (xiz)
	cp (xwa), 0x5C
	jr nz, FileIO_ParseLoop_CopyChar
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE8, 0x00
	ld xwa, (xsp + 18)
	cp (xwa), 0x0
	jr z, FileIO_ParseLoop_AppendSlash
	pushw 0xE4
	pushw 0x512E
	ld xwa, (xsp + 22)
	push xwa
	call Strcat
	inc 8, xsp

FileIO_ParseLoop_AppendSlash:
	lda xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 22)
	push xwa
	call Strcat
	inc 8, xsp
	lds de, 0
	ld xwa, (xiz)
	inc 1, xwa
	ld xhl, xwa

FileIO_ParseLoop_Advance:
	lds32 xwa, 1
	add (xiz), xwa

FileIO_ParseLoop_Test:
	ld xwa, (xiz)
	cp (xwa), 0x0
	jr nz, FileIO_ParseLoop_CheckChar
	ld (xiz), xhl
	lds hl, 0
	jr FileIO_ParsePath_Return

FileIO_ParseLoop_CopyChar:
	lda xbc, (xsp + 4)
	ld xwa, (xiz)
	ld a, (xwa)
	lda_dri3 XBC, 0x07, 0xE4, 0xE8
	inc 1, de
	cp de, 0xC
	jr le, FileIO_ParseLoop_Advance
	ldw hl, 0xFFFF

FileIO_ParsePath_Return:
	pop xiz
	lda xsp, (xsp + 18)
	ret

_findfirst:
	lda xsp, (xsp - 20)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), xwa
	cpi8_24 0x03e3e4, 0x05
	jr nz, FindFirst_AllocHandle
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	calr FindFirst_SndTable
	jrl FdcFile_Epilogue20

FindFirst_AllocHandle:
	pushw 0x8
	call Malloc
	inc 2, xsp
	ld (xsp + 8), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, FindFirst_AllocPathBuf
	ld xhl, 0xFFFFFFFF
	jrl FdcFile_Epilogue20

FindFirst_AllocPathBuf:
	pushw 0x104
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jr nz, FindFirst_ParseAndOpen
	ld xwa, (xsp + 8)
	push xwa
	call Free
	inc 4, xsp
	ld xhl, 0xFFFFFFFF
	jrl FdcFile_Epilogue20

FindFirst_ParseAndOpen:
	ld xwa, (xsp + 20)
	ld (xsp + 12), xwa
	ld xwa, xiz
	lda xbc, (xsp + 12)
	calr FileIO_ParsePathComponents
	cps hl, 0
	jr z, FindFirst_OpenDir
	ld xwa, (xsp + 8)
	push xwa
	call Free
	ld xwa, xiz
	push xwa
	call Free
	inc 8, xsp
	ld xhl, 0xFFFFFFFF
	jrl FdcFile_Epilogue20

FindFirst_OpenDir:
	pushw 0xE4
	pushw 0x5130
	ld xwa, xiz
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, FindFirst_AllocPattern
	ld xwa, (xsp + 8)
	push xwa
	call Free
	ld xwa, xiz
	push xwa
	call Free
	inc 8, xsp
	ld xhl, 0xFFFFFFFF
	jr FdcFile_Epilogue20

FindFirst_AllocPattern:
	ld xwa, xiz
	push xwa
	call Free
	ld xwa, (xsp + 16)
	push xwa
	call Strlen
	inc 1, hl
	pushw hl
	call Malloc
	lda xsp, (xsp + 10)
	ld xiz, xhl
	or xiz, xiz
	jr nz, FindFirst_CopyAndSearch
	ld xwa, (xsp + 8)
	push xwa
	call Free
	inc 4, xsp
	ld xhl, 0xFFFFFFFF
	jr FdcFile_Epilogue20

FindFirst_CopyAndSearch:
	ld xwa, (xsp + 12)
	push xwa
	push xiz
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld (xwa + 4), xiz
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 16)
	calr _findnext
	cps hl, 0
	jr nz, FindFirst_FailAndClose
	ld xhl, (xsp + 8)
	jr FdcFile_Epilogue20

FindFirst_FailAndClose:
	ld xwa, (xsp + 8)
	calr _findclose
	ld xhl, 0xFFFFFFFF

FdcFile_Epilogue20:
	pop xiz
	lda xsp, (xsp + 20)
	ret

_findclose:
	push xiz
	ld xiz, xwa
	cpi8_24 0x03e3e4, 0x05
	jr nz, FindClose_CheckNull
	ld xwa, xiz
	calr FileIO_ValidateHandle
	jr FindClose_Return

FindClose_CheckNull:
	ld xwa, xiz
	or xwa, xwa
	jr nz, FindClose_FreeResources
	ldw hl, 0xFFFF
	jr FindClose_Return

FindClose_FreeResources:
	ld xwa, xiz
	ld xwa, (xwa)
	push xwa
	call FileClose
	ld xwa, xiz
	ld xwa, (xwa + 4)
	push xwa
	call Free
	ld xwa, xiz
	push xwa
	call Free
	lda xsp, (xsp + 12)
	lds hl, 0

FindClose_Return:
	pop xiz
	ret

_findnext:
	lda xsp, (xsp - 64)
	push xiz
	ld xiz, xbc
	cpi8_24 0x03e3e4, 0x05
	jr nz, FindNext_CheckNull
	ld xbc, xiz
	calr FileIO_ReadNextDirEntry
	jrl FindNext_Epilogue

FindNext_CheckNull:
	ld xbc, xwa
	or xbc, xbc
	jr nz, FindNext_ReadFirstEntry
	ldw hl, 0xFFFF
	jrl FindNext_Epilogue

FindNext_ReadFirstEntry:
	ld (xsp + 8), xwa
	ld xwa, (xwa)
	ld (xsp + 4), xwa
	push xwa
	pushw 0x1
	pushw 0x20
	lda xwa, (xsp + 20)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cps hl, 1
	jrl nz, FindNext_NoMoreEntries

FindNext_MatchEntry:
	lda xwa, (xsp + 12)
	push xwa
	lda xwa, (xsp + 48)
	push xwa
	call SeqStep_FileSectorComplete
	inc 8, xsp
	cp (xsp + 44), 0xE5
	jr z, FindNext_ReadFile
	cp (xsp + 44), 0x0
	jr z, FindNext_NoMoreEntries
	bitm 3, (xsp + 56)
	jr nz, FindNext_ReadFile
	lda xwa, (xsp + 44)
	ld xbc, (xsp + 8)
	ld xbc, (xbc + 4)
	calr FileIO_MatchWildcard
	cps hl, 1
	jr nz, FindNext_ReadFile
	pushw 0x8
	lda xwa, (xsp + 46)
	push xwa
	lda xwa, (xiz + 6)
	push xwa
	call Mem_Copy
	ld (xiz + 14), 0x2E
	pushw 0x3
	lda xwa, (xsp + 64)
	push xwa
	lda xwa, (xiz + 15)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	ld (xiz + 18), 0x0
	ld xwa, (xsp + 63)
	ld (xiz + 2), xwa
	ld a, (xsp + 56)
	ld (xiz), a
	lds hl, 0
	jr FindNext_Epilogue

FindNext_ReadFile:
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x1
	pushw 0x20
	lda xwa, (xsp + 20)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cps hl, 1
	jr z, FindNext_MatchEntry

FindNext_NoMoreEntries:
	ldw hl, 0xFFFF

FindNext_Epilogue:
	pop xiz
	lda xsp, (xsp + 64)
	ret

FileIO_MatchWildcard:
	lda xsp, (xsp - 16)
	push xiz
	ld xiz, xbc
	ld (xsp + 16), xwa
	lds wa, 0
	cp (xiz), 0x0
	jr nz, WildMatch_InitBuffer
	lds hl, 0
	jrl WildMatch_Return

WildMatch_InitBuffer:
	pushw 0xB
	pushw 0x3F
	lda xwa, (xsp + 8)
	push xwa
	call Memset
	inc 8, xsp
	ld (xsp + 15), 0x0
	lda xwa, (xsp + 4)
	ld xbc, xwa
	cp (xiz), 0x0
	jr z, WildMatch_FillName

WildMatch_ScanLoop:
	cp (xiz), 0x2E
	jr nz, WildMatch_CopyChar
	lda xwa, (xsp + 12)
	ld xbc, xwa
	inc 1, xiz
	jr WildMatch_CheckEnd

WildMatch_CopyChar:
	ld_spib A, 0xF8
	lda_dpi XBC, 0xE4

WildMatch_CheckEnd:
	cp (xiz), 0x0
	jr nz, WildMatch_ScanLoop

WildMatch_FillName:
	lds bc, 0
	cp bc, 0x8
	jr ge, WildMatch_FillExt

WildMatch_NameLoop:
	lda xwa, (xsp + 4)
	cp_srib_im 0x07, 0xE0, 0xE4, 0x2A
	jr nz, WildMatch_NameNext
	cp bc, 0x8
	jr ge, WildMatch_NameNext

WildMatch_StarFillName:
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE4, 0x3F
	inc 1, bc
	cp bc, 0x8
	jr lt, WildMatch_StarFillName

WildMatch_NameNext:
	inc 1, bc
	cp bc, 0x8
	jr lt, WildMatch_NameLoop

WildMatch_FillExt:
	ldw bc, 0x8
	cp bc, 0xB
	jr ge, WildMatch_Compare

WildMatch_ExtLoop:
	lda xwa, (xsp + 4)
	cp_srib_im 0x07, 0xE0, 0xE4, 0x2A
	jr nz, WildMatch_ExtNext
	cp bc, 0xB
	jr ge, WildMatch_ExtNext

WildMatch_StarFillExt:
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xE0, 0xE4, 0x3F
	inc 1, bc
	cp bc, 0xB
	jr lt, WildMatch_StarFillExt

WildMatch_ExtNext:
	inc 1, bc
	cp bc, 0xB
	jr lt, WildMatch_ExtLoop

WildMatch_Compare:
	lds hl, 1
	ld xde, (xsp + 16)
	lda xwa, (xsp + 4)
	ld xbc, xwa
	cp (xde), 0x0
	jr z, WildMatch_Return

WildMatch_CompareLoop:
	cp (xbc), 0x3F
	jr z, WildMatch_CompareAdvance
	ld a, (xbc)
	cp a, (xde)
	jr z, WildMatch_CompareAdvance
	lds hl, 0
	jr WildMatch_Return

WildMatch_CompareAdvance:
	inc 1, xde
	inc 1, xbc
	cp (xde), 0x0
	jr nz, WildMatch_CompareLoop

WildMatch_Return:
	pop xiz
	lda xsp, (xsp + 16)
	ret

FindFirst_SndTable:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	sti16_24 0x02272c, 0x0000
	lda_24 xwa, 0x02272c
	ld xiz, xwa
	call FileIO_ReadAllDirEntries
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr FileIO_ReadNextDirEntry
	cps hl, 0
	jr nz, FindFirst_SndTable_Fail
	ld xhl, xiz
	jr FindFirst_SndTable_Return

FindFirst_SndTable_Fail:
	ld xwa, xiz
	calr FileIO_ValidateHandle
	ld xhl, 0xFFFFFFFF

FindFirst_SndTable_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_ValidateHandle:
	or xwa, xwa
	jr nz, FileIO_ValidateHandle_Ok
	ldw hl, 0xFFFF
	ret

FileIO_ValidateHandle_Ok:
	lds hl, 0
	ret

FileIO_ReadNextDirEntry:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld xbc, xwa
	or xbc, xbc
	jr nz, FileIO_ReadDirEntry_Body
	ldw hl, 0xFFFF
	jr FileIO_ReadDirEntry_Return

FileIO_ReadDirEntry_Body:
	ld xiz, xwa
	cpw (xiz), 0x50
	jr ge, FileIO_ReadDirEntry_End
	ld wa, (xiz)
	muls wa, 0x2C
	lda_24 xbc, 0x0235a8
	cp_sriw_im 0x07, 0xE4, 0xE0, 0xFE, 0xFE
	jr z, FileIO_ReadDirEntry_End
	pushw 0x14
	ld wa, (xiz)
	muls wa, 0x2C
	lda_24 xbc, 0x02358e
	exts xwa
	add xwa, xbc
	push xwa
	ld xwa, (xsp + 10)
	inc 6, xwa
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ld (xwa + 26), 0x0
	ld wa, (xiz)
	muls wa, 0x2C
	lda_24 xbc, 0x0235a6
	ld_sriw3 BC, 0x07, 0xE4, 0xE0
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa + 2), xbc
	incm 1, (xiz)
	lds hl, 0
	jr FileIO_ReadDirEntry_Return

FileIO_ReadDirEntry_End:
	ldw hl, 0xFFFF

FileIO_ReadDirEntry_Return:
	pop xiz
	inc 4, xsp
	ret

SndTable_ByteBlock_ReadOps:
	cpi8_24	254956, 0
	jr	nz, 48
	ld32_24	xbc, 144762
	push	xbc
	pushw 1024
	pushw 1
	push	xwa
	call	16051824
	lda	xsp, (xsp+12)
	cps	hl, 0
	jr	lt, 3
	lds	hl, 0
	ret
	ld32_24	xwa, 144762
	ld	wa, (xwa+6)
	and	wa, 32767
	jr	nz, 3
	lds	hl, 0
	ret
	ldw	hl, 65535
	ret
	cpi8_24	254956, 1
	jr	nz, 6
	calr	759
	extz	hl
	ret
	ldw	hl, 65535
	ret
	dec	2, xsp
	push	xiz
	sti8_24	144766, 1
	ld32_24	xwa, 254952
	st32_24	141102, xwa
	ld32_24	xwa, 254958
	ldw	(xwa+2), 0
	ld32_24	xwa, 254958
	ldw	(xwa+1030), 0
	ld32_24	xbc, 254958
	lds	wa, 2
	call	15671408
	ld32_24	xwa, 254958
	lda	xwa, (xwa+1028)
	ld	xbc, xwa
	lds	wa, 2
	call	15671408
	ldw	(xsp+4), 0
	ld	wa, (xsp+4)
	extz	xwa
	cpda32_24	xwa, 141102
	jrl	ugt, 134
	lds	wa, 2
	call	15671777
	ld	xiz, xhl
	cpw	(xiz+2), 0
	jr	z, 17
	ldw	(xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	15671408
	jr	102
	lda	xwa, (xiz+4)
	calr	-200
	cps	hl, 0
	jr	z, 21
	ldw	(xiz), 0
	ldw	(xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	15671408
	jr	71
	ldw	(xiz), 1024
	ld	wa, (xsp+4)
	extz	xwa
	ld32_24	xbc, 141102
	sub	xbc, xwa
	cp	xbc, 1024
	jr	ugt, 14
	ld	wa, (xsp+4)
	extz	xwa
	ld32_24	xbc, 141102
	sub	xbc, xwa
	ld	(xiz), bc
	ldw	(xiz+2), 0
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	15671408
	.byte 0x9f, 0x04, 0x38, 0x00, 0x04
	ld	wa, (xsp+4)
	extz	xwa
	cpda32_24	xwa, 141102
	jrl	ule, -134
	sti8_24	144766, 0
	call	15670294
	pop	xiz
	inc	2, xsp
	ret
	ld	xbc, xwa
	dec	1, xwa
	or	xbc, xbc
	ret	z
	ld	xbc, xwa
	dec	1, xwa
	or	xbc, xbc
	jr	nz, -8
	ret

TaskBuf_ReadNextByte:
	pushw iz
	cpi8_24 0x02358a, 0x01
	jrl nz, TaskBuf_Error
	cpdi16_24 144768, 0
	jr nz, TaskBuf_CheckPendingData
	lds wa, 3
	call TaskMsg_Receive
	st32_24 0x023582, xhl
	ld wa, (xhl)
	st16_24 0x023580, xwa
	ld32_24 xwa, 0x023582
	inc 4, xwa
	st32_24 0x023586, xwa

TaskBuf_CheckPendingData:
	ld32_24 xwa, 0x023582
	cpw (xwa + 2), 0x0
	jr z, TaskBuf_EmptyAndReturn
	sti8_24 0x02358a, 0x02
	ld32_24 xwa, 0x023582
	ld hl, (xwa + 2)
	jr TaskBuf_PopIzRet

TaskBuf_EmptyAndReturn:
	cpdi16_24 144768, 0
	jr nz, TaskBuf_ReadAndDecrement
	sti8_24 0x02358a, 0x02
	ldw hl, 0xFFFF
	jr TaskBuf_PopIzRet

TaskBuf_ReadAndDecrement:
	ld32_24 xbc, 0x023586
	lds32 xwa, 1
	addm32_24 0x023586, xwa
	ld a, (xbc)
	ldfr_berp A, 0xF8
	extz iz
	subdi16_24 144768, 1
	jr nz, TaskBuf_ReturnByte
	ld32_24 xwa, 0x023582
	cpw (xwa), 0x400
	jr z, TaskBuf_SendBufferFull
	sti8_24 0x02358a, 0x02
	ld hl, iz
	jr TaskBuf_PopIzRet

TaskBuf_SendBufferFull:
	ld32_24 xbc, 0x023582
	lds wa, 2
	call TaskMsg_Send

TaskBuf_ReturnByte:
	ld hl, iz
	jr TaskBuf_PopIzRet

TaskBuf_Error:
	ldw hl, 0xFFFF

TaskBuf_PopIzRet:
	popw iz
	ret

FDC_DrainQueuesAndReset:
	lds wa, 2
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainQueue2_Done

FDC_DrainQueue2_Loop:
	lds wa, 2
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue2_Loop

FDC_DrainQueue2_Done:
	ld32_24 xwa, 0x023582
	ldw (xwa + 2), 0xFFFF
	ld32_24 xbc, 0x023582
	lds wa, 2
	call TaskMsg_Send
	cpi8_24 0x02357e, 0x00
	jr z, FDC_DrainQueue3_Start

FDC_WaitQueueEmpty_Loop:
	cpi8_24 0x02357e, 0x00
	jr nz, FDC_WaitQueueEmpty_Loop

FDC_DrainQueue3_Start:
	sti8_24 0x02358a, 0x02
	lds wa, 3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainQueue2B_Start

FDC_DrainQueue3_Loop:
	lds wa, 3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue3_Loop

FDC_DrainQueue2B_Start:
	lds wa, 2
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainCloseFile

FDC_DrainQueue2B_Loop:
	lds wa, 2
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue2B_Loop

FDC_DrainCloseFile:
	cpi8_24 0x03e3ec, 0x00
	ret nz
	ld32_24 xwa, 0x02357a
	push xwa
	call FileClose
	inc 4, xsp
	ret

SndTable_LookupA:
	sti8_24 0x03e3ec, 0x00
	sti16_24 0x023580, 0x0000
	sti8_24 0x02358a, 0x01
	lda_24 xbc, 0x022d72
	st32_24 0x03e3ee, xbc
	pushw 0xE4
	pushw 0x5132
	push xwa
	call FileOpen
	inc 8, xsp
	st32_24 0x02357a, xhl
	ld32_24 xwa, 0x02357a
	or xwa, xwa
	jr nz, SndTable_LookupA_GotFile
	sti8_24 0x02358a, 0x02
	ldw hl, 0xFFFF
	ret

SndTable_LookupA_GotFile:
	ld32_24 xwa, 0x02357a
	ld xwa, (xwa + 71)
	st32_24 0x03e3e8, xwa
	lds wa, 2
	call Show_ScreenGroup
	lds hl, 0
	ret

SndTable_CalcSectorPosition:
	ld hl, wa
	extz xhl
	div hl, 0x9
	ldto_werp HL, 0xEE
	inc 1, hl
	ld (xbc), hl
	ld bc, wa
	extz xbc
	div bc, 0x9
	and bc, 0x1
	ld (xde), bc
	ld xbc, (xsp + 4)
	extz xwa
	div wa, 0x12
	ld (xbc), wa
	retd 0x4

FDC_ExecuteSectorCommand:
	lda xsp, (xsp - 22)
	push xiz
	ld xiz, xbc
	lda xbc, (xsp + 24)
	ld xhl, xbc
	lda xbc, (xsp + 22)
	ld xde, xbc
	lda xbc, (xsp + 20)
	push xbc
	ld xbc, xhl
	calr SndTable_CalcSectorPosition
	ldw (xsp + 4), 0x3
	ldw (xsp + 6), 0x0
	ld wa, (xsp + 22)
	ld (xsp + 8), wa
	ld wa, (xsp + 20)
	ld (xsp + 10), wa
	ld wa, (xsp + 24)
	ld (xsp + 12), wa
	ldw (xsp + 14), 0x1
	ld xwa, xiz
	ld (xsp + 16), xwa
	lda xwa, (xsp + 4)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	pop xiz
	lda xsp, (xsp + 22)
	ret

FDC_SectorCmd_ByteBlock:
	push	xiz
	ld	xiz, xwa
	ld16_24	wa, 144780
	ld	xbc, xiz
	calr	-91
	incdi16_24	1, 144780
	cps	hl, 0
	jr	nz, 22
	ld16_24	de, 144780
	lda	xwa, (xiz+512)
	ld	xbc, xwa
	ld	wa, de
	calr	-117
	incdi16_24	1, 144780
	pop	xiz
	ret

SndTable_LookupB:
	jrl TaskBuf_ReadNextByte

SndTable_LookupC:
	calr FDC_DrainQueuesAndReset
	sti8_24 0x03e3ec, 0x00
	jrl FDC_RecalibrateCommand

SndTable_LookupD_CalcAddr:
	ld bc, wa
	muls bc, 0x2C
	lda_24 xde, 0x0235a8
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
	st16_24 0x02358c, xbc
	muls wa, 0x2C
	lda_24 xbc, 0x0235a6
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	st16_24 0x02474e, xwa
	ld16_24 xwa, 0x02474e
	extz xwa
	sll xwa, 9
	st32_24 0x03e3e8, xwa
	lds hl, 0
	ret

SndTable_LookupD:
	sti8_24 0x03e3ec, 0x01
	sti16_24 0x023580, 0x0000
	sti8_24 0x02358a, 0x01
	lda_24 xbc, 0x022d72
	st32_24 0x03e3ee, xbc
	calr SndTable_LookupD_CalcAddr
	cps l, 0
	jr z, SndTable_LookupD_ShowScreen
	sti8_24 0x02358a, 0x02
	sti8_24 0x03e3ec, 0x00
	ldw hl, 0xFFFF
	ret

SndTable_LookupD_ShowScreen:
	lds wa, 2
	call Show_ScreenGroup
	lds hl, 0
	ret

FDC_DetectDiskFormat:
	calr FDC_ResetHeadCommand
	cps hl, 0
	jr z, FDC_DetectFormat_ReadSector
	cp hl, 0x31
	jr z, FDC_DetectFormat_ReturnOneB
	cp hl, 0x30
	jr z, FDC_DetectFormat_ReturnOneB
	cp hl, 0xFC
	jr nz, FDC_DetectFormat_ReturnOne
	lds hl, 2
	ret

FDC_DetectFormat_ReturnOne:
	lds hl, 1
	ret

FDC_DetectFormat_ReturnOneB:
	lds hl, 1
	ret

FDC_DetectFormat_ReadSector:
	lda_24 xwa, 0x02434e
	ld xbc, xwa
	ldw wa, 0x9
	calr FDC_ExecuteSectorCommand
	cp hl, 0x10
	jr z, FDC_DetectSector_Return3
	cp hl, 0xFC
	jr z, FDC_DetectSector_Return2
	cps hl, 0
	jr z, FDC_DetectSector_CheckPianoDisc
	cp hl, 0x31
	jr z, FDC_DetectSector_Return1
	cp hl, 0x30
	jr nz, FDC_DetectSector_Return1B

FDC_DetectSector_Return1:
	lds hl, 1
	ret

FDC_DetectSector_Return2:
	lds hl, 2
	ret

FDC_DetectSector_Return3:
	lds hl, 3
	ret

FDC_DetectSector_Return1B:
	lds hl, 1
	ret

FDC_DetectSector_CheckPianoDisc:
	pushw 0xB	; 11 bytes
	pushw 0xE4
	pushw 0x5136	; "1 PianoDisc"
	lda_24 xwa, 0x02434e
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, FDC_DetectSector_ReturnPD3
	lds hl, 0
	ret

FDC_DetectSector_ReturnPD3:
	lds hl, 3
	ret

FDC_ResetHeadCommand:
	lda xsp, (xsp - 16)
	ldw (xsp + 256), 0x0
	ldw (xsp + 2), 0x0
	ldw (xsp + 6), 0xE0
	lda xwa, (xsp)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	lda xsp, (xsp + 16)
	ret

FDC_RecalibrateCommand:
	lda xsp, (xsp - 16)
	ldw (xsp + 256), 0x7
	lda xwa, (xsp)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 20)
	ret

FileIO_ReadAllDirEntries:
	push xiz
	lds iz, 0
	cps iz, 7
	jr ge, FileIO_ReadDir_CopyEntries

FileIO_ReadDir_SectorLoop:
	ld wa, iz
	add wa, 0xA
	ld de, wa
	ld wa, iz
	sla wa, 9
	ld bc, wa
	exts xbc
	lda_24 xwa, 0x02358e
	add xwa, xbc
	ld xbc, xwa
	ld wa, de
	calr FDC_ExecuteSectorCommand
	ldfr_werp HL, 0xFA
	calr FDC_RecalibrateCommand
	cpi_werp 0xFA, 0
	jr z, FileIO_ReadDir_NextSector
	ldto_werp HL, 0xFA
	jrl FileIO_ReadDir_Return

FileIO_ReadDir_NextSector:
	inc 1, iz
	cps iz, 7
	jr lt, FileIO_ReadDir_SectorLoop

FileIO_ReadDir_CopyEntries:
	lds iz, 0
	cp iz, 0x50
	jr ge, FileIO_FillRemainingEntries

FileIO_ReadDir_CopyLoop:
	ld wa, iz
	muls wa, 0x2C
	lda_24 xbc, 0x0235a8
	cp_sriw_im 0x07, 0xE4, 0xE0, 0xFE, 0xFE
	jr z, FileIO_FillRemainingEntries
	pushw 0x14
	ld wa, iz
	muls wa, 0x2C
	lda_24 xbc, 0x02358e
	exts xwa
	add xwa, xbc
	push xwa
	ld wa, iz
	muls wa, 0x14
	lda_24 xbc, 0x022732
	exts xwa
	add xwa, xbc
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	inc 1, iz
	cp iz, 0x50
	jr lt, FileIO_ReadDir_CopyLoop

FileIO_FillRemainingEntries:
	st16_24 0x024750, xiz
	cp iz, 0x50
	jr ge, FileIO_ReadDir_GetRetVal

FileIO_FillRemaining_Loop:
	pushw 0x14
	pushw 0x20
	ld wa, iz
	muls wa, 0x14
	lda_24 xbc, 0x022732
	exts xwa
	add xwa, xbc
	push xwa
	call Memset
	inc 8, xsp
	inc 1, iz
	cp iz, 0x50
	jr lt, FileIO_FillRemaining_Loop

FileIO_ReadDir_GetRetVal:
	ldto_werp HL, 0xFA

FileIO_ReadDir_Return:
	pop xiz
	ret

SeqByteBlock_DispatchJumpTable:
	lda	xde, (xde)
	.byte 0xf5, 0x00, 0xb1
	ldw	de, 245
	.byte 0xbb, 0x32, 0xf5
	nop
	lda	xde, (xbc)
	.byte 0xf5, 0x00

SeqDispatch_ReturnNop:
	ret

SeqDispatch_ResetAndValidate:
	call AccBuf_ResetAllPositions
	call RhythmROM_ValidateHeader
	ret

SeqDispatch_InitWithPayload:
	call AccBuf_ResetAndReload
	call SubCPU_Payload_GetErrorFlag
	cps hl, 0
	jr z, SeqDispatch_PostInit
	call AccDemo_Init_Wrap

SeqDispatch_PostInit:
	anddi8 13043, 254
	ret

SeqDispatch_TrampolineBlock:
	jp	16069340
	ret
	jp	16069341
	ret
	ret
	ret
	calr	4418
	ret

Seq_DispatcherEntry:
	jp Seq_DispatcherTick

VoiceParam_ClampAndValidate_Tramp:
	jp VoiceParam_ClampAndValidate
SeqDispatch_TrampolineB:
	jp	16079790

Rhythm_DispatchNote_Tramp:
	jp Rhythm_DispatchNote

Rhythm_NoteDispatchWrapper:
	push xiz
	ld d, c
	call Rhythm_DispatchNote
	xor xhl, xhl
	ld l, a
	pop xiz
	ret

RhythmPart_CopyData_Tramp:
	jp RhythmPart_CopyData

Rhythm_LookupTempoVelocity_Wrap:
	push xiz
	call AccStyle_LookupTempoAndVelocity
	pop xiz
	ret

Rhythm_DispatchNote_Finalize:
	push xiz
	call AccStyle_LookupVelocityTable
	pop xiz
	ret

Rhythm_TransposeWithMod_Tramp:
	jp Rhythm_TransposeWithMod
Rhythm_TransposeTrampBlock:
	jp	16079849

Seq_DispatcherTick:
	cpdi8 36150, 16
	jr c, Seq_DispatcherTick_Process
	cpdi8 36150, 22
	jr ugt, Seq_DispatcherTick_Process
	jr Seq_DispatcherTickReturn

Seq_DispatcherTick_Process:
	call RhythmROM_CheckValid
	cps c, 0
	jr nz, Seq_DispatcherTickReturn
	calr SeqTick_ReadControlState
	call Seq_ReadTempoLookup
	calr Seq_ProcessAllInputState
	call Rhythm_CompareAndTrigger
	anddi8 13044, 159
	call AccTick_Main
	ldda8 a, 13044
	and a, 0x60
	call Rhythm_SaveState
	call Seq_RhythmProcessor
	call Rhythm_AdvanceTick
	call AccDir_Entry
	call AccStyle_Entry
	call AccProcess_Entry

Seq_DispatcherTickReturn:
	ret

SeqTick_ReadControlState:
	ldda8 a, 64602
	stda8 13045, a
	ldda8 a, 64603
	and a, 0x7F
	and a, 0x7
	stda8 13047, a
	calr VoiceParam_ClampAndStore
	nop
	nop
	nop
	nop
	ldda8 a, 64605
	or a, 0xE0
	srl a, 5
	stda8 13049, a
	ldda8 w, 64607
	xor a, a
	bit 6, w
	jr z, SeqCtl_CheckBit6
	or a, 0x1

SeqCtl_CheckBit6:
	bit 7, w
	jr z, SeqCtl_CheckBit7
	or a, 0x2

SeqCtl_CheckBit7:
	stda8 13051, a
	xor a, a
	bit 4, w
	jr z, SeqCtl_CheckBit4
	or a, 0x1

SeqCtl_CheckBit4:
	bit 5, w
	jr z, SeqCtl_CheckBit5
	or a, 0x2

SeqCtl_CheckBit5:
	stda8 13053, a
	xor a, a
	bit 2, w
	jr z, SeqCtl_CheckBit2
	or a, 0x1

SeqCtl_CheckBit2:
	bit 3, w
	jr z, SeqCtl_CheckBit3
	or a, 0x2

SeqCtl_CheckBit3:
	ldda8 w, 64608
	bit 2, w
	jr z, SeqCtl_StorePedalFlags
	or a, 0x4

SeqCtl_StorePedalFlags:
	stda8 13055, a
	ldda8 a, 64921
	and a, 0x1
	stda8 13057, a
	ldda8 a, 64606
	and a, 0x10
	srl a, 4
	ldb a, 0x0
	stda8 13059, a
	ldda8 a, 64609
	and a, 0x30
	srl a, 4
	stda8 13061, a
	xor a, a
	bitda 2, 64941
	jr nz, SeqCtl_StoreKeyMask
	or a, 0x3F

SeqCtl_StoreKeyMask:
	stda8 13063, a
	ret

VoiceParam_ClampAndStore:
	ldda8 l, 13045
	ldda8 h, 13047
	calr VoiceParam_ClampAndValidate
	stda8 13045, l
	and h, 0x7F
	and h, 0x7
	stda8 13047, h
	ret

VoiceParam_ClampAndValidate:
	cp l, 0x80
	jr c, VoiceParam_Clamp_LookupTable
	cp l, 0xF0
	jr c, VoiceParam_Clamp_CheckBank
	ldb h, 0x0
	and l, 0xF
	or l, 0x80
	jr TableLoad_Return

VoiceParam_Clamp_CheckBank:
	cps h, 7
	jr ule, VoiceParam_Clamp_CheckRange
	xor h, h

VoiceParam_Clamp_CheckRange:
	cp l, 0x9D
	jr ule, TableLoad_Return
	xor l, l
	jr TableLoad_Return

VoiceParam_Clamp_LookupTable:
	ld xwa, 0xE4638A
	sla l, 1
	and h, 0x7F
	and h, 0x7
	ld_sriw3 HL, 0x07, 0xE0, 0xEC

TableLoad_Return:
	ret

Rhythm_InitDataBlock:
	ret
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	.zero 121

Rhythm_QueuePartChangeEvent:
	call SwbtWr_QueuePostEvent
	ret

Seq_ReadTempoLookup:
	xor xhl, xhl
	ldda16 xwa, 1033
	ld l, a
	add xhl, 0xE46C17
	ld a, (xhl)
	stda16 13131, xwa
	ret

Seq_ProcessAllInputState:
	ldda8 a, 12931
	and a, 0xFE
	bitda 2, 1054
	jr z, Seq_InputState_StoreFlag
	or a, 0x1

Seq_InputState_StoreFlag:
	stda8 12931, a
	calr AccKey_ScanAndSetDirty
	calr AccState_ReadAccompParams
	calr AudioMode_CheckAndUpdateStereo
	calr AccChord_ReadAndStoreKeys
	calr AudioMode_MergeOutputBits
	calr AudioMode_CopyChannelMode
	calr AudioMode_CopyAccentFlags
	calr AccPedal_SetFlag13155
	xor xhl, xhl
	ldda8 l, 12928
	sla l, 1
	add xhl, 0xE46B9E
	ld bc, (xhl)
	xor hl, hl
	ldda8 l, 12927
	add bc, hl
	stda16 12925, xbc
	stdi8 13033, 24
	bitda 0, 12931
	jr z, AccInput_CheckRecordMode
	call AccTuning_DisableIfNoStyle
	bitda 0, 13155
	jr nz, AccInput_ProcessWithPedal
	calr AccPedal_ProcessAllChanges

AccInput_ProcessWithPedal:
	calr AccChannel_CompareAndMarkDirty
	calr AccVoice_ProcessPedalChanges
	calr AccVoice_ProcessLeftPedalChanges
	calr AccPitch_CheckTransposeFlags
	calr AccChord_ProcessKeyChanges
	bitda 0, 13155
	jr z, AccInput_CompareAndCheck
	calr AccChord_ResolveVoiceAndDispatch

AccInput_CompareAndCheck:
	calr AccChord_CompareAndSetDirty
	calr AccentVoice_DetectAndMarkChange
	call AccTuning_CheckChange
	jr AccInput_Return

AccInput_CheckRecordMode:
	call AccStyle_CheckRecordMode
	call AccStyle_DetectChanges

AccInput_Return:
	ret

AccKey_ScanAndSetDirty:
	push xbc
	anddi8 12932, 253
	ldb a, 0x1
	ld xhl, 0xF1A0
	xor c, c

AccKey_ScanLoop:
	cp c, 0x10
	jr z, AccKey_ScanDone
	cp (xhl), 0xD
	jr z, AccKey_FoundActiveKey
	sla wa, 1
	inc 1, xhl
	inc 1, c
	jr AccKey_ScanLoop

AccKey_FoundActiveKey:
	andda16 xwa, 61854
	jr z, AccKey_ScanDone
	ordi8 12932, 2

AccKey_ScanDone:
	pop xbc
	ret

AccChord_ReadAndStoreKeys:
	ldda8 a, 52960
	stda8 13017, a
	ldda8 a, 52959
	stda8 13016, a
	ldda8 a, 52961
	stda8 13018, a
	ldda8 a, 52958
	stda8 13015, a
	cpdi8 8968, 0
	jr z, AccChord_CheckKeyOverride
	ldda8 a, 8962
	stda8 13017, a
	ldda8 a, 8960
	stda8 13016, a
	ldda8 a, 8964
	stda8 13018, a
	ldda8 a, 8966
	stda8 13015, a

AccChord_CheckKeyOverride:
	bitda 1, 13015
	jr nz, AccChord_CheckUIState
	ldda8 a, 13017
	stda8 13018, a

AccChord_CheckUIState:
	cpdi8 36148, 14
	jr nz, AccChord_CheckUIStateExit
	cpdi8 36150, 177
	jr z, AccChord_CheckKeyFlags
	cpdi8 36150, 176
	jr nz, AccChord_SetDefaultKeys

AccChord_CheckKeyFlags:
	ldda8 a, 1054
	and a, 0x18
	jr nz, AccChord_CheckUIStateExit

AccChord_SetDefaultKeys:
	stdi8 13015, 0
	stdi8 13016, 1
	stdi8 36162, 1
	bitda 4, 13546
	jr z, AccChord_ReadChannelKeys
	stdi8 13016, 5
	stdi8 36162, 5

AccChord_ReadChannelKeys:
	ldda8 a, 13545
	and a, 0xF
	inc 1, a
	stda8 13017, a
	stda8 36160, a
	stda8 13018, a

AccChord_CheckUIStateExit:
	cpdi8 36148, 14
	jr z, AccChord_CheckModeAndUpdate
	cpdi8 13041, 14
	jr nz, AccChord_CheckModeAndUpdate
	ldda8 a, 52959
	stda8 36162, a
	ldda8 a, 52960
	stda8 36160, a
	calr AccDisplay_RefreshIfDiskActive

AccChord_CheckModeAndUpdate:
	ldda8 a, 13076
	orda8 a, 13077
	and a, 0x3F
	jrl z, AccChord_ReadKeysRet
	ldda8 a, 13016
	cps a, 0
	jr nz, AccChord_ReadKeysRet
	ldda8 a, 13020
	cpda8 a, 13016
	jr z, AccChord_ReadKeysRet
	stda8 13016, a
	stda8 52959, a
	stda8 36162, a
	stda8 8960, a
	ldda8 a, 13021
	stda8 13017, a
	stda8 52960, a
	stda8 36160, a
	stda8 8962, a
	ldda8 a, 13022
	stda8 13018, a
	stda8 52961, a
	stda8 36164, a
	stda8 8964, a
	cpda8 a, 13021
	jr nz, AccChord_CompareNoteC
	stdi8 36164, 0

AccChord_CompareNoteC:
	ldda8 a, 13019
	stda8 13015, a
	stda8 52958, a
	stda8 8966, a
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	ldda8 a, 64605
	and a, 0x7
	cps a, 0
	jr z, AccChord_ReadKeysRet
	bitda 1, 12932
	jr z, AccChord_ReadKeysRet
	call BitMapOut_CheckDiskAndApply
	jr __jrt_nop_F53720
__jrt_nop_F53720:

AccChord_ReadKeysRet:
	ret

AccDisplay_RefreshIfDiskActive:
	push xwa
	ldda8 a, 64605
	and a, 0x7
	cps a, 0
	jr z, AccDisplay_RefreshDone
	call BitMapOut_CheckDiskAndApply

AccDisplay_RefreshDone:
	pop xwa
	ret

AccState_ReadAccompParams:
	ldb a, 0x0
	ei 6
	stda8 1124, a
	ldda8 a, 1046
	stda8 12928, a
	ldda8 a, 1076
	stda8 12980, a
	ldda8 a, 1077
	stda8 12979, a
	ldda8 a, 1045
