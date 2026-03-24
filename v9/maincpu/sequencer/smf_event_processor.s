; =============================================================================
; SMF Event Processor
; =============================================================================
;
; Standard MIDI File (SMF) event processing, tone generation
; dispatch, and voice channel management. Bridges SMF playback
; data to the audio engine.
; =============================================================================

	and ix, 0xff
	inc 1, ix
	cp ix, 0xff
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
	cpda16 xix, 0x286d
	jr ule, ToneGen_StoreBlockAndLink
	stdi8 0x287a, 5
	jr ToneGen_DispatchReturn

ToneGen_StoreBlockAndLink:
	ldda32 xhl, 4349
	ld (xhl + 3), ix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ldda16 xwa, 3308
	ldda32 xhl, 4349
	ld (xhl + 1), wa
	ldw (xhl + 3), 0xffff
	stda16 3308, xix
	lds ix, 5

ToneGen_DispatchReturn:
	ret

ToneGen_DispatchAndLinkBlock:
	push xix
	push xiy
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	ldda16 xhl, 0x28af
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ld (xhl + 3), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ldda16 xbc, 0x28af
	ld (xhl + 1), bc
	ldw (xhl + 3), 0xffff
	stda16 0x28af, xwa
	stdi16 9830, 5
	pop xiy
	pop xix
	ret

VoiceChannel_GetCombinedStatus:
	cpdi8 4012, 6
	jr z, VoiceChannel_GetStatusBank2First
	push xix
	ld xix, 0x10d3
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix
	ld l, a
	push xix
	ld xix, 0x10c3
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	jr VoiceChannel_CombineStatusBits

VoiceChannel_GetStatusBank2First:
	push xix
	ld xix, 0x10c3
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_CombineStatusBits:
	rlc_i_8 l, 2
	and l, 0x1
	sla a, 1
	or a, l
	ret

VoiceChannel_LookupParams:
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xix
	xor h, h
	cp l, 0xff
	jr z, VoiceChannel_LookupReturn
	ld c, l
	sla hl, 2
	push xix
	ld xix, VoiceSynth_DataEntry_PtrTable
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	ld_srib3 A, 0x07, 0xec, 0xf4
	stda8 4234, a
	call SoundGen_PrepareAndBuildVoice

VoiceChannel_LookupReturn:
	ret

VoiceChannel_SetPanDirection:
	call VoiceChannel_GetParamBlock
	ld w, (xiy + 4)
	and w, 0xf7
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
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xb0
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
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
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
	ld xix, SeqTrack_ChannelMapIdentity
	cpdi8 4600, 1
	jr z, VoiceChannel_SelectChannelBank
	ld xix, 0xf2436b

VoiceChannel_SelectChannelBank:
	ld_srib3 A, 0x07, 0xf0, 0xf4
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
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet
	ldda8 a, 4235
	and a, 0x7f
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
	and iy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ldb a, 0xb0
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jr nz, VoiceChannel_NullRet2
	sla iy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
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
	and a, 0xf
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
	and iy, 0xf
	push xix
	ld xix, 0x1093
	ld_srib3 A, 0x07, 0xf0, 0xf4
	ld xix, 0x10a3
	ld_srib3 W, 0x07, 0xf0, 0xf4
	pop xix
	cps a, 0
	jr nz, ToneGen_StoreBadValue
	cps w, 0
	jr c, ToneGen_StoreBadValue
	cps w, 2
	jr ugt, ToneGen_StoreBadValue
	push xix
	ld xix, 0x10b3
	lda_dri3 XWA, 0x07, 0xf0, 0xf4
	pop xix
	jr SoundGen_LookupReturn

ToneGen_StoreBadValue:
	ldb a, 0xff
	push xix
	ld xix, 0x10b3
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix

SoundGen_LookupReturn:
	ret

VoiceChannel_GetParamBlock:
	xor h, h
	ldda8 l, 4011
	and l, 0xf
	sla hl, 2
	cpdi8 4600, 1
	jr nz, VoiceChannel_GetParamBlockAlt
	push xix
	ld xix, VoiceChannel_ParamTable1
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	jr VoiceChannel_StoreParamPtr

VoiceChannel_GetParamBlockAlt:
	push xix
	ld xix, 0xf26c5e
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix

VoiceChannel_StoreParamPtr:
	ld xiy, xhl
	ret

VoiceChannel_ParamTable1:
	.byte 0x96, 0xf4
	nop
	nop
	ret	ov
	nop
	nop
	cp	d, b
	nop
	nop
	.byte 0xe4, 0xf4
	nop
	nop
	swi	6
	.byte 0xf4
	nop
	nop
	push_f
	.byte 0xf5
	nop
	nop
	ldw	de, 245
	nop
	popw	ix
	.byte 0xf5
	nop
	nop
	jr	z, -11
	nop
	nop
	.byte 0x80, 0xf5
	nop
	nop
	.byte 0x9a, 0xf5
	nop
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
	.byte 0x1c, 0xf6
	nop
	nop
	.byte 0x96, 0xf4
	nop
	nop
	ret	ov
	nop
	nop
	cp	d, b
	nop
	nop
	.byte 0xe4, 0xf4
	nop
	nop
	swi	6
	.byte 0xf4
	nop
	nop
	push_f
	.byte 0xf5
	nop
	nop
	ldw	de, 245
	nop
	popw	ix
	.byte 0xf5
	nop
	nop
	jr	z, -11
	nop
	nop
	.byte 0x1c, 0xf6
	nop
	nop
	.byte 0x9a, 0xf5
	nop
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
	.byte 0x80, 0xf5
	nop
	nop
	call	VoiceChannel_GetParamBlock
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
	ldb a, 0xb0
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
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
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
	and l, 0xf
	xor h, h
	cpdi16 3932, 0
	jr z, SoundGen_SelectChannelTable
	cpdi16 3934, 2
	jr c, SoundGen_SelectChannelTable
	ld a, l
	jr SoundGen_ApplyChannelParam

SoundGen_SelectChannelTable:
	ld xix, 0xf2436b
	cpdi8 4600, 1
	jr nz, SoundGen_SelectAltChannelTable
	ld xix, SeqTrack_ChannelMapIdentity

SoundGen_SelectAltChannelTable:
	ld_srib3 A, 0x07, 0xf0, 0xec

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
	ld xde, SoundGen_VoiceParamData
	ld_srib3 A, 0x03, 0xe8, 0xe4
	pop xde
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	ldda8 a, 4234
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	ldb a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_PopIyRet
	call ToneGen_SetSustainBit
	ldda16 xiy, 4011
	and iy, 0xf
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
	ld xwa, 0x13fa
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
	ld xwa, 0x13fa
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
	ld xde, SoundGen_InitVoiceData
	ld_srib3 A, 0x07, 0xe8, 0xf4
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x2
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x7f
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
	.byte 0x04
	halt
	.byte 0x06

SndParam_LookupChannelVoice:
	push xhl
	cpdi8 4600, 2
	jr nz, SndParam_LookupDefault
	ldda8 a, 4011
	and a, 0xf
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
	ld xix, 0x1a37
	ldb a, 0x4
	ld_sriw3 BC, 0x07, 0xf0, 0xec
	ld e, b
	xor hl, hl
	ldda8 l, 4012
	pushw hl
	call SndParam_LookupByChannel
	ld a, l
	pop xde
	pop xbc
	pop xix
	cp a, 0xff
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
	and e, 0xf
	stda16 6751, xde
	pop xde
	cpdi16 6751, 9
	jr nz, VoiceChannel_StoreVoiceReturn
	ld xwa, 0x1a57
	call SndParam_ApplyVoiceValue
	ld xhl, 0x1a37
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
	ld xiy, 0x1a61
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
	ldb a, 0x7f
	ld bc, ix
	sub a, c
	sub a, 0x1
	cpdi16 4212, 0
	jr nz, Seq_AdvanceBlock
	cpdm8 4211, a
	jr ugt, Seq_AdvanceBlock
	ld bc, ix
	ld xix, xiy
	ld xiy, 0x106e
	ldir85
	call SysEx_ReadBytesLoop_Init
	cpdi8 6880, 255
	jr z, Seq_ReturnToDispatcher
	ld xwa, 0x1a61
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
	ldb c, 0x7f
	ld xiy, 0x1a61

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
	cpda8_24 a, 0xffe3
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
	anddi8 0x8d88, 254
	call SMF_CalcFilePosition
	push xwa
	push xbc
	ldda32 xbc, 6705
	sub xbc, 0x13fa
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
	ld xwa, 0xfa2
	lds32 xbc, 4
	call FileIO_WriteByte_Impl
	pop xbc
	pop xwa

SMF_RestoreTimerState:
	bitda 0, 0x28a5
	jr z, SMF_SeekReturn
	ld16_24 xwa, 0x00ffec
	stda16 0xf19e, xwa
	push xhl
	call Audio_CheckSubsystemReady
	pop xhl

SMF_SeekReturn:
	ret

SeqPlay_StartWithDisplay:
	call SeqPlay_CheckStartConditions
	cpdi8 0xf23d, 255
	jr z, SeqPlay_SetFlagAndMode
	anddi8 0xfdad, 251
	xor a, a
	jr SeqPlay_QueueDisplayEvent

SeqPlay_SetFlagAndMode:
	ordi8 0xfdad, 4
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
	cpdi16 0xf19c, 0
	jr z, SMF_InitChannelState
	stdi16 6699, 9
	jrl SMF_PopReturn

SMF_InitChannelState:
	xor wa, wa
	stda8 4236, a
	stda16 4347, xwa
	stda8 4344, a
	cpdi16_24 0xffec, 0
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
	ld xix, 0xf1a0
	cp_srib_im 0x07, 0xf0, 0xec, 0x10
	pop xix
	jr z, SMF_LoopNextChannel
	ld a, l
	sla l, 1
	add l, a
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec
	pop xde
	jr nz, SMF_FoundActiveChannel

SMF_LoopNextChannel:
	inc 1, c
	cp c, 0xf
	jr ule, SMF_ScanChannelLoop

SMF_SetStatusAndJump:
	stdi16 6699, 47
	jrl SMF_Finalize_PopReturn

SMF_FoundActiveChannel:
	call Vga_SetupMultiPlaneDisplay
	ld16_24 xwa, 0x00ffec
	stda16 4325, xwa
	stdi8 4324, 255
	bitda 2, 0xfdad
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
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec
	pop xde
	jr nz, SMF_SetupActiveChannel
	add hl, 0x3
	inc 1, c
	cp c, 0xf
	jr ule, SMF_FindFirstActiveChannel
	stdi16 6699, 3
	jrl SMF_Finalize_RestoreAndPlay

SMF_SetupActiveChannel:
	stda8 0x2877, c
	inc 1, hl
	push xde
	ld xde, 0xf250
	ld_sriw3 HL, 0x07, 0xe8, 0xec
	pop xde
	stda16 0x28af, xhl
	stdi16 9830, 5
	ld xiy, 0xf2823e
	ld xix, 0x13fa
	lds bc, 7
	ldirw
	ld xiy, 0xf2824c
	lds bc, 4
	ldir85
	xor wa, wa
	stda16 4002, xwa
	stda16 4004, xwa
	stda32 6705, xix
	ldda16 xwa, 4002
	st_dpiw WA, 0xf1
	ldda16 xwa, 4004
	st_dpiw WA, 0xf1
	stda32 4376, xix
	ldda32 xix, 4376
	ld xiy, SMF_HeaderConstants
	lds bc, 4
	ldir85
	ld xiy, 0xf280
	ldw bc, 0x10
	ldir85
	stda32 4376, xix
	stdi16 4206, 0
	stdi8 4208, 0
	ld xiy, 0x106e
	ldda32 xix, 4376

SMF_WaitForReady:
	ld_spib A, 0xf4
	lda_dpi XBC, 0xf0
	bit 7, a
	jr nz, SMF_WaitForReady
	ldw wa, 0x58ff
	st_dpiw WA, 0xf1
	ldb a, 0x4
	ldda8 w, 1075
	st_dpiw WA, 0xf1
	ldw wa, 0x1802
	st_dpiw WA, 0xf1
	ldb a, 0x8
	lda_dpi XBC, 0xf0
	stda32 4376, xix
	ldda8 l, 0xfc62
	xor h, h
	pushw bc
	ldda8 b, 0xfc63
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
	ld xiy, 0xf2827c
	cpdi8 4324, 0
	jr nz, SMF_Setup_SelectTablePtr
	ld xiy, 0xf28284

SMF_Setup_SelectTablePtr:
	ldda32 xix, 4376
	ldw bc, 0x8

SMF_WriteChannelDataLoop:
	ld_spib A, 0xf4
	lda_dpi XBC, 0xf0
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
	stdi8 0x2877, 0

SMF_ScanAndProcessChannel:
	ld xiy, 0xf460
	xor hl, hl
	ldda8 l, 0x2877
	ld c, l
	ldda16 xde, 4325
	ld a, c
	scf
	xorcf_a_16 de
	jrl c, SMF_AdvanceChannelScan
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	pop xix
	ld b, l
	sla l, 1
	push xix
	ld xix, 0xf28254
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	pop xix
	cp hl, 0xffff
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
	st_dri3b E, 0x07, 0xf4, 0xec
	ld c, (xiy + 256)
	ld d, (xiy + 1)
	ld b, (xiy + 3)
	ld e, (xiy + 4)
	ld a, (xiy + 5)
	stda8 4359, a
	ld a, (xiy + 7)
	stda8 4332, a
	anddi8 0x2877, 15
	ldda8 l, 0x2877
	xor h, h
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	pop xix
	cpdi8 4324, 255
	jrl nz, SMF_WriteNote_AltPath
	call SMF_ResolveGlobalChannel
	ldda8 a, 6881
	or a, 0xc0
	ld l, c
	stda8 6746, l
	stda8 6747, d
	ld l, (xiy - 2)
	stda8 6748, l
	pushw bc
	pushw de
	ld xwa, 0x1a57
	call SndParam_InitBufferConverge
	popw de
	popw bc
	ldda8 a, 6881
	or a, 0xb0
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
	or a, 0xc0
	ldda8 w, 6745
	and w, 0x7f
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
	or a, 0xb0
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
	or a, 0xb0
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
	or a, 0xc0
	ld w, c
	and w, 0x7f
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
	or a, 0xb0
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
	ldb w, 0x5d
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
	ldb l, 0x7f
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
	ldb w, 0x5b
	ldda8 l, 4332
	and l, 0x7f
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
	ldda8 l, 0x2877
	xor h, h
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	pop xix
	cp l, 0xc
	jrl z, SMF_AdvanceChannelScan
	ld b, l
	xor h, h
	sla l, 1
	push xix
	ld xix, 0xf28254
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	pop xix
	cp hl, 0xffff
	jrl z, SMF_AdvanceChannelScan
	ldda8 a, 6881
	or a, 0xb0
	ld c, l
	ld xiy, 0xf460
	ldfr_lerp XIY, 0x38
	st_dri3b E, 0x07, 0xf4, 0xec
	ld l, (xiy + 8)
	ldto_lerp XIY, 0x38
	ldb w, 0xa
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
	ldda8 l, 0x2877
	xor h, h
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	sla hl, 1
	ld xix, 0xf28254
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	st_dri3b E, 0x07, 0xf4, 0xec
	ld l, (xiy + 10)
	ld c, l
	srl l, 1
	and l, 0x7f
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
	ldda8 l, 0x2877
	xor h, h
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	sla l, 1
	ld xix, 0xf28254
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	ldfr_lerp XIY, 0x38
	st_dri3b E, 0x07, 0xf4, 0xec
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
	ldda8 l, 0x2877
	xor h, h
	push xix
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	sla l, 1
	ld xix, 0xf28254
	ld_sriw3 HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	st_dri3b E, 0x07, 0xf4, 0xec
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
	incdi8 1, 0x2877
	cpdi8 0x2877, 15
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
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	call SMF_AdvancePosition
	call SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xaf, 0x28
	stda8 3944, a

SMF_ResetEventTimers:
	stdi16 3946, 0
	stdi16 3938, 0
	stdi16 3940, 0

; ============================================================================
; SMF_ProcessEventLoop - Process MIDI events from sequence data
; ============================================================================
; Reads and dispatches MIDI-style events in a loop:
;   0x90 = Note On, 0xa0 = Aftertouch, 0xb0 = Control Change,
;   0xc0 = Program Change, 0xd0 = Channel Pressure, 0xe0 = Pitch Bend,
;   0xf0 = System, 0x81-0x86 = Meta events
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
	lda_dri3 XBC, 0x07, 0xe8, 0xec
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
	and w, 0xf0
	cp w, 0x90
	jrl z, SMF_NoteOn_Handler
	cp w, 0xb0
	jrl z, SMF_ControlChange_Handler
	cp w, 0xc0
	jrl z, SMF_ProgramChange_Handler
	cp w, 0xd0
	jrl z, SMF_ChannelPressure_Handler
	cp w, 0xf0
	jrl z, SMF_SystemExclusive_Handler
	cp w, 0xa0
	jrl z, SMF_PolyAftertouch_Dispatch
	cp w, 0xe0
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
	ldto_werp DE, 0xe2
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
	and l, 0x7f
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
	and a, 0xf
	or a, 0xd0
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
	and a, 0xf
	or a, 0xb0
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
	and l, 0xf
	xor h, h
	push xix
	ld xix, 0xf1a0
	cp_srib_im 0x07, 0xf0, 0xec, 0x0f
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
	and a, 0xf
	or a, 0xb0
	ldb w, 0xb
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
	ld xde, 0x11f9
	bit_dri 7, 0x07, 0xe8, 0xec
	pop xde
	jr z, SMF_NoteOn_SlotFound
	add hl, 0x5
	cp hl, 0xa0
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
	ld xix, 0x11f9
	st_dri3b D, 0x07, 0xf0, 0xec
	ldb a, 0x80
	lda_dpi XBC, 0xf0
	ldda8 a, 4211
	lda_dpi XBC, 0xf0
	ldda8 a, 4213
	lda_dpi XBC, 0xf0
	ldda8 a, 4216
	ldb w, 0x60
	muls8rr a, w
	xor hl, hl
	ldda8 l, 4215
	add wa, hl
	st_dpiw WA, 0xf1
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
	and a, 0x7f
	or a, l
	stda8 6747, a
	push xix
	xor hl, hl
	ldda8 l, 4213
	ld xix, 0xf1a0
	ld_srib3 L, 0x07, 0xf0, 0xec
	ld xix, 0xf2828c
	ld_srib3 L, 0x07, 0xf0, 0xec
	stda8 6748, l
	pop xix
	ld xwa, 0x1a57
	call SndParam_InitBufferConverge
	ldb a, 0xb0
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
	ldb a, 0xc0
	ldda8 w, 4213
	and w, 0xf
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
	and h, 0xc
	ldda8 l, 4214
	srl l, 5
	and l, 0x3
	or l, h
	sla l, 4
	and l, 0x7f
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
	ldb a, 0xc0
	ldda8 w, 4213
	and w, 0xf
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
	cp l, 0x7f
	jrl z, SMF_ProcessEventLoop_Entry
	and l, 0x1f
	cps l, 0
	jrl c, SMF_ProcessEventLoop_Entry
	cp l, 0xf
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
	cp l, 0xb
	jrl ugt, SMF_ProcessEventLoop
	ldb a, 0xb0
	ldda8 w, 4213
	and w, 0xf
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
	cp l, 0xa
	jr z, SMF_CC_RPN_Handler
	cp l, 0xb
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
	ldb a, 0xb0
	ldda8 w, 4213
	and w, 0xf
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
	ldb a, 0xb0
	ldda8 w, 4213
	and w, 0xf
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
	ldb a, 0xb0
	ldda8 w, 4213
	and w, 0xf
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
	ldb a, 0xb0
	ldda8 w, 4213
	and w, 0xf
	or a, w
	ldb w, 0xa
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
	ldb w, 0x5d
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
	ldb l, 0x7f
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Chorus_Handler:
	ldb w, 0x5b
	ldb l, 0x0
	cpdi8 6709, 0
	jr z, SMF_CC_Chorus_SetupCC91
	bitda 0, 4236
	jrl z, SMF_ProcessEventLoop

SMF_CC_Chorus_SetupCC91:
	ldda8 l, 4215
	and l, 0x7f
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
	lda_24 xwa, FileClose
	st32_24 0x0210f6, xwa
	ld (xsp + 4), 0x4
	cp (xbc), 0x0
	jr z, FileOpen_AllocBuffer

FileOpen_ParseModeLoop:
	ld_spib A, 0xe4
	exts wa
	cp wa, 0x64
	jr z, FileOpen_ModeD
	cp wa, 0x7e
	jr z, FileOpen_ModeTilde
	cp wa, 0x62
	jr z, FileOpen_ModeB
	cp wa, 0x2b
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
	ormi8 (xsp + 4), 0x8a
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
	lda_24 xbc, CharMap_FullPermutation_0x660
	ld_srib3 A, 0x07, 0xe4, 0xe0
	bit 1, a
	jr z, FileOpen_NormalizeNoUpper
	ld xwa, (xsp + 16)
	ld a, (xwa)
	exts wa
	sub wa, 0x20
	jr FileOpen_StoreNormChar

FileOpen_ScanForColon:
	ld xwa, (xsp + 16)
	ld_spib C, 0xe0
	ld (xsp + 16), xwa
	cp c, 0x3a
	jr nz, FileOpen_NormalizeName
	lds32 xwa, 1
	sub (xsp + 16), xwa
	ld xwa, (xsp + 16)
	stib_dpi 0xe0, 0x00
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
	cpda16_24 xwa, 0x3e3de
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
	cpda16_24 xwa, 0x3e3de
	jr lt, FileOpen_DeviceSearchLoop

FileOpen_DeviceFound:
	ld xwa, (xsp + 12)
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld a, (xsp + 6)
	extz wa
	cpda16_24 xwa, 0x3e3de
	jr nz, FileOpen_CheckPermission

FileOpen_ErrorNoFile:
	sti16_24 0x01e53c, 0x0007
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_CheckPermission:
	ld a, (xsp + 4)
	and a, 0xf
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
	incdi8_24 1, 0x210f4
	ld (xsp + 14), 0x0
	cp (xsp + 14), 0x10
	jr nc, FileOpen_SlotExhausted

FileOpen_SlotSearchLoop:
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	ld xwa, 0xffffffff
	st_dri3l XWA, 0x07, 0xe8, 0xe4
	call SeqStep_FileNopB
	pushw 0x4b
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
	st_dri3l XWA, 0x07, 0xe8, 0xe4
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
	ld (xiz + 2), 0xd
	ld a, (xsp + 4)
	ld (xiz + 3), a
	ei 7
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda_24 xbc, 0x0210b4
	st_dri3l XIZ, 0x07, 0xe4, 0xe0
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
	st_dri3l XWA, 0x07, 0xe8, 0xe4
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
	mrdw3 0x9f, 0x0a, 0x48
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
	mrdw3 0x9f, 0x08, 0x58
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
	mrdw3 0x9f, 0x0a, 0x48
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
	mrdw3 0x9f, 0x08, 0x58
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
	ldw hl, 0xffff
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadCleanup:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadComplete
	sti16_24 0x01e53c, 0x000d
	ldw hl, 0xffff
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
	add xsp, 0xa
	cps hl, 0
	jr z, SeqStep_FileReadVtableFail
	ld l, (xsp)
	extz hl
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadVtableFail:
	ldw hl, 0xffff

SeqStep_FileReadVtableReturn:
	inc 2, xsp
	ret

SeqStep_ByteBlockEF56:
	push	xiz
	ld	xbc, (xsp+14)
	ld	xiz, (xsp+8)
	or	xbc, xbc
	jr	z, 6
	.byte 0x89, 0x04
	push	xsp
	nop
	jr	nz, 11
	sti16_24	0x1e53c, 17
	lds32	xhl, 0
	jr	53
	.byte 0xb9, 0x04
	dec	6, w
	pushw	0x3cf2
	.byte 0xe5, 0x01
	push_sr
	decf
	nop
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
	.byte 0xf3
	reti
	swi	0
	.byte 0xec
	nop
	nop
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
	ldw hl, 0xffff
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteCheckMode:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileWriteProcess
	sti16_24 0x01e53c, 0x000d
	ldw hl, 0xffff
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
	add xsp, 0xa
	cps hl, 0
	jr z, SeqStep_FileWriteFail
	ld l, (xsp)
	extz hl
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteFail:
	ldw hl, 0xffff

SeqStep_FileWriteReturn:
	inc 2, xsp
	ret

SeqStep_ByteBlockF002:
	ld	xbc, (xsp+8)
	or	xbc, xbc
	jr	z, 6
	.byte 0x89, 0x04
	push	xsp
	nop
	jr	nz, 11
	sti16_24	0x1e53c, 17
	ldw	hl, 0xffff
	ret
	.byte 0xb9, 0x04
	dec	6, a
	pushw	0x3cf2
	.byte 0xe5, 0x01
	push_sr
	decf
	nop
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ld	xwa, (xsp+4)
	.byte 0xc5, 0xe0
	push	xsp
	nop
	jr	z, 8
	inc	1, hl
	.byte 0xc5, 0xe0
	push	xsp
	nop
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
	ldw	hl, 0xffff
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
	cp_sril_mr XIZ, 0x07, 0xe4, 0xe0
	jr z, SeqStep_FileCloseProcess

SeqStep_FileCloseCheck:
	sti16_24 0x01e53c, 0x0011
	ldw hl, 0xffff
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
	incdi8_24 1, 0x210f4
	ld a, (xiz + 5)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, 0x0210b4
	lds32 xwa, 0
	st_dri3l XWA, 0x07, 0xe8, 0xe4
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
	ldw hl, 0xffff
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
	.byte 0x89, 0x04
	push	xsp
	nop
	jr	z, 24
	ld	xwa, (xsp+4)
	push	xwa
	pushw	1
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	jrl	131
	sti16_24	0x1e53c, 25
	ldw	hl, 0xffff
	jr	119
	.byte 0xd7
	swi	2
	cp	(xwa-41), xde
	.byte 0xcf
	rcf
	nop
	jr	ge, 107
	.byte 0xd7
	swi	2
	or	(xwa-40), d
	push_sr
	lda_24	xbc, 0x210b4
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 232
	.byte 0xe0
	jr	z, 77
	.byte 0xd7
	swi	2
	or	(xwa-40), d
	push_sr
	lda_24	xbc, 0x210b4
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 232
	.byte 0xcf
	swi	7
	swi	7
	swi	7
	swi	7
	jr	z, 53
	ld	xwa, (xsp+4)
	push	xwa
	pushw	1
	.byte 0xd7
	swi	2
	or	(xwa-40), d
	push_sr
	lda_24	xbc, 0x210b4
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 56
	.byte 0xd7
	swi	2
	or	(xwa-40), d
	push_sr
	lda_24	xbc, 0x210b4
	.byte 0xe3
	reti
	.byte 0xe4, 0xe0
	ldb	w, 168
	ret
	ldb	w, 168
	ldb	d, 32
	call	(xwa)
	lda	xsp, (xsp+10)
	or	iz, hl
	.byte 0xd7
	swi	2
	jr	lt, -41
	swi	2
	.byte 0xcf
	rcf
	nop
	jr	lt, -107
	ld	hl, iz
	pop	xiz
	inc	4, xsp
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	nz, 11
	sti16_24	0x1e53c, 17
	ldw	hl, 0xffff
	ret
	lda	xwa, (xsp+8)
	inc	2, xwa
	push	xwa
	.byte 0x9f
	incf
	.byte 0x04
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	ret
	ld	xwa, (xsp+4)
	.byte 0xb8
	ei	2
	nop
	nop
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
	pushw 0xe4
	pushw 0x5016
	ld xwa, (xsp + 8)
	push xwa
	call FileOpen
	inc 8, xsp
	or xhl, xhl
	jr nz, SeqStep_FileOpenSetupVtable
	ldw hl, 0xffff
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
	ld16_24	wa, 0x1e53c
	ld	(xsp+4), wa
	sti16_24	0x1e53c, 0
	pushw	228
	pushw	0x501a
	ld	xwa, (xsp+14)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 19
	push	xiz
	call	FileClose
	inc	4, xsp
	sti16_24	0x1e53c, 21
	ldw	hl, 0xffff
	jr	75
	.byte 0xd2
	push	xix
	.byte 0xe5, 0x01
	push	xsp
	halt
	nop
	jr	z, 5
	ldw	hl, 0xffff
	jr	61
	ld	wa, (xsp+4)
	exts	wa
	st16_24	0x1e53c, wa
	pushw	228
	pushw	0x501c
	ld	xwa, (xsp+14)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 5
	ldw	hl, 0xffff
	jr	24
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xiz+14)
	ld	xwa, (xwa+28)
	call	(xwa)
	ld	(xsp+8), hl
	push	xiz
	call	FileClose
	inc	8, xsp
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
	ld	xde, (xsp+4)
	or	xde, xde
	jr	z, 6
	.byte 0x8a, 0x04
	push	xsp
	nop
	jr	nz, 11
	sti16_24	0x1e53c, 17
	ldw	hl, 17
	ret
	ld	xwa, (xde+18)
	.byte 0x80
	push	xsp
	.byte 0x01
	jr	nz, 11
	ld	xbc, (xsp+8)
	ld	xwa, (xde+22)
	ld	(xbc), xwa
	lds	hl, 0
	ret
	sti16_24	0x1e53c, 18
	ldw	hl, 18
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, 6
	.byte 0x89, 0x04
	push	xsp
	nop
	jr	nz, 11
	sti16_24	0x1e53c, 17
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
	st16_24	0x1e53c, wa
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
	ld xhl, 0xffffffff
	ret

SeqStep_FileSeekFinal:
	ld xwa, (xbc + 18)
	cp (xwa), 0x1
	jr nz, SeqStep_FileSeekExit
	ld xhl, (xbc + 22)
	ret

SeqStep_FileSeekExit:
	sti16_24 0x01e53c, 0x0012
	ld xhl, 0xffffffff
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
	pushw 0xe4
	pushw 0x5020
	ld xwa, (xsp + 18)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, SeqStep_FileTellReturn
	cpdi16_24 0x1e53c, 13
	jr nz, SeqStep_FileTellSetup
	sti16_24 0x01e53c, 0x0000
	pushw 0xe4
	pushw 0x5022
	ld xwa, (xsp + 18)
	push xwa
	call FileOpen
	inc 8, xsp
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	or xwa, xwa
	jr nz, SeqStep_FileTellReturn
	cpdi16_24 0x1e53c, 13
	jr nz, SeqStep_FileTellReturn
	ldw hl, 0xffff
	jrl SeqStep_FileTellExit

SeqStep_FileTellSetup:
	ldw hl, 0xffff
	jrl SeqStep_FileTellExit

SeqStep_FileTellReturn:
	pushw 0xe4
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
	ldw hl, 0xffff
	jr SeqStep_FileTellExit

SeqStep_FileTellProcess:
	sti16_24 0x01e53c, 0x0000
	pushw 0xe4
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
	ldw hl, 0xffff
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
	ldw hl, 0xffff
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
	pushw	228
	pushw	0x5028
	ld	xwa, (xsp+48)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 6
	ldw	hl, 0xffff
	jrl	149
	ld	xwa, (xiz+26)
	or	xwa, xwa
	jr	nz, 9
	sti16_24	0x1e53c, 13
	jr	64
	pushw	0
	ld	xwa, 64
	push	xwa
	push	xiz
	calr	64983
	add	xsp, 10
	cps	hl, 0
	jr	nz, 41
	push	xiz
	pushw	1
	pushw	32
	lda	xwa, (xsp+16)
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cps	hl, 1
	jr	nz, 53
	.byte 0x8f
	ldio	63, 0
	jr	z, 47
	cp	(xsp+8), 229
	jr	z, 19
	sti16_24	0x1e53c, 27
	push	xiz
	call	FileClose
	inc	4, xsp
	ldw	hl, 0xffff
	jr	57
	push	xiz
	pushw	1
	pushw	32
	lda	xwa, (xsp+16)
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cps	hl, 1
	jr	z, -53
	ld	xwa, (xsp+4)
	push	xwa
	pushw	21
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xiz+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	add	xsp, 10
	cps	hl, 0
	jr	nz, -62
	push	xiz
	call	FileClose
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
	cpw (xsp + 4), 0xa
	jr ge, SeqStep_FileIoUpdate

SeqStep_FileIoError:
	cpi8_24 0x03e3e0, 0x00
	jr z, SeqStep_FileIoCleanup
	mrdw3 0x9c, 0x12, 0x7f

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
	st_dri3b D, 0xf1, 0x1a, 0x02
	cpw (xsp + 4), 0xa
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
	ldw (xwa + 6), 0xa

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
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
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
	cpw (xiz + 20), 0x1f
	jr nz, SeqStep_FileBufferCleanup
	resm 0, (xiz + 22)
	lda_24 xwa, 0x02121a
	ld xbc, xwa
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0xa
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
	st_dri3b A, 0xe5, 0x1a, 0x02
	cpw (xsp + 4), 0xa
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
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	lda_24	xwa, 0x2121a
	ld	xiz, xwa
	.byte 0xbf
	ei	2
	nop
	nop
	.byte 0x9f, 0x06
	push	xsp
	ldwio	0, 0x3a69
	ld	a, (xiz+22)
	and	a, 3
	cps	a, 3
	jr	nz, 13
	push	xiz
	calr	65271
	inc	4, xsp
	cps	hl, 0
	jr	z, 3
	ld	(xsp+4), hl
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	.byte 0x8e, 0x17, 0xf1
	jr	nz, 9
	.byte 0xbe
	ex_ff
	dec	6, b
	.byte 0x04, 0x8e
	ex_ff
	push	xix
	.byte 0x80
	incm	1, (xsp+6)
	lda	xiz, (xiz+538)
	.byte 0x9f, 0x06
	push	xsp
	ldwio	0, 0xc661
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
	.long (Sprintf_FillToVectors + 14)
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
	pushw 0xb
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
	pushw	11
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	xwa, (xsp+4)
	ld	c, (xiz+12)
	ld	(xwa+11), c
	ld	xwa, 22
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	decf
	ldb	w, 32
	nop
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	decf
	ldb	w, 216
	.byte 0xef
	ldio	177, 65
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	retd	8224
	nop
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	retd	0xd820
	.byte 0xef
	ldio	177, 65
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	scf
	ldb	w, 32
	nop
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -98
	scf
	ldb	w, 216
	.byte 0xef
	ldio	177, 65
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -82
	zcf
	ldb	w, 232
	.byte 0xcc
	swi	7
	nop
	nop
	nop
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -82
	zcf
	ldb	w, 232
	.byte 0xef
	ldio	232, 204
	swi	7
	nop
	nop
	nop
	ld	(xbc), a
	ld	xwa, (xsp+4)
	.byte 0xf5, 0xe0
	ldw	bc, 1215
	jr	f, -82
	zcf
	ldb	w, 232
	.byte 0xef
	nop
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
	cpw (xwa + 36), 0xfff
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
	and xwa, 0x1ff
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
	add xwa, 0x1a
	add xwa, xhl
	ld a, (xwa)
	extz wa
	ld (xsp + 10), wa
	cpw (xsp + 8), 0x1ff
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
	add xsp, 0xe
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
	add xwa, 0x1a
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
	and hl, 0xfff

SeqStep_FileSectorLoop:
	pop xiz
	lda xsp, (xsp + 10)
	ret

SeqStep_FileSectorPopReturn:
	dec	2, xsp
	push	xiz
	ld	xwa, (xsp+10)
	ld	xde, (xwa+30)
	.byte 0x9a
	ldb	d, 63
	swi	7
	retd	0x597e
	.byte 0x01
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
	pushw	6
	ld	xwa, (xsp+12)
	.byte 0xa8
	.ascii "& 8>"
	ld	xwa, (xsp+20)
	push	xwa
	calr	63756
	lda	xsp, (xsp+14)
	ld	xbc, xhl
	ld	xwa, (xsp+10)
	ld	(xwa+38), xbc
	or	xhl, xhl
	jrl	z, 386
	ld	wa, (xsp+14)
	bit	0, a
	jr	z, 127
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
	.byte 0x9f, 0x04
	push	xsp
	swi	7
	.byte 0x01
	jr	nz, 41
	pushw	6
	lds32	xwa, 0
	push	xwa
	ld	xwa, xiz
	inc	1, xwa
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	calr	63656
	add	xsp, 14
	or	xhl, xhl
	jrl	z, 291
	ld	wa, (xsp+16)
	srl	wa, 4
	ld	(xhl+26), a
	jrl	279
	ld	wa, (xsp+4)
	inc	1, wa
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	srl	wa, 4
	ld	(xbc), a
	jrl	251
	ld	wa, (xsp+4)
	extz	xwa
	add	xwa, 26
	ld	xbc, xwa
	add	xbc, xhl
	ld	wa, (xsp+16)
	ldb	w, 0
	ld	(xbc), a
	.byte 0x9f, 0x04
	push	xsp
	swi	7
	.byte 0x01
	jr	nz, 57
	pushw	6
	lds32	xwa, 0
	push	xwa
	ld	xwa, xiz
	inc	1, xwa
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	calr	63558
	add	xsp, 14
	or	xhl, xhl
	jrl	z, 193
	ld	wa, (xsp+16)
	srl	wa, 8
	ld	bc, wa
	and	bc, 15
	ld	a, (xhl+26)
	and	a, 240
	extz	wa
	or	wa, bc
	ld	(xhl+26), a
	jrl	165
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
	jr	108
	ld	wa, (xsp+14)
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	ld	xwa, xbc
	and	xwa, 511
	ld	(xsp+4), wa
	ld	xiz, xbc
	srl	xiz, 9
	.byte 0xaa
	push_f
	.byte 0x86
	pushw	6
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+38)
	push	xwa
	push	xiz
	ld	xwa, (xsp+20)
	push	xwa
	calr	63416
	lda	xsp, (xsp+14)
	ld	xbc, xhl
	ld	xwa, (xsp+10)
	ld	(xwa+38), xbc
	or	xhl, xhl
	jr	z, 47
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
	pop	xiz
	inc	2, xsp
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, (xsp+12)
	ld	xwa, (xiz+30)
	ld	wa, (xwa+36)
	dec	8, wa
	ld	(xsp+6), wa
	ld	wa, (xiz+42)
	ld	(xsp+4), wa
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jr	nz, 9
	.byte 0xbe
	pushw	ix
	push_sr
	nop
	nop
	lds	hl, 0
	jr	39
	.byte 0xbe
	pushw	ix
	push_sr
	.byte 0x01
	nop
	jr	13
	incm	1, (xsp+4)
	ld	wa, (xsp+4)
	cp	wa, hl
	jr	nz, 19
	incm	1, (xiz+44)
	.byte 0x9f, 0x04, 0x04
	push	xiz
	calr	64732
	inc	6, xsp
	ld	wa, hl
	.byte 0x9f, 0x06, 0xf0
	jr	ule, -29
	ld	hl, (xiz+44)
	pop	xiz
	inc	4, xsp
	ret
	lda	xsp, (xsp-12)
	push	xiz
	.byte 0xbf
	ldio	2, 0
	nop
	.byte 0xbf
	ldwio	2, 0
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
	decm	1, (xsp+26)
	cps	wa, 0
	jrl	z, 221
	lds	bc, 2
	ld	wa, (xsp+6)
	inc	1, wa
	cps	wa, 2
	jr	c, 5
	ld	bc, (xsp+6)
	inc	1, bc
	ld	iz, bc
	.byte 0x9f, 0x04, 0xf6
	jr	ugt, 21
	pushw	iz
	ld	xwa, (xsp+22)
	push	xwa
	calr	64627
	inc	6, xsp
	cps	hl, 0
	jr	z, 57
	inc	1, iz
	.byte 0x9f, 0x04, 0xf6
	jr	ule, -21
	lds	iz, 2
	.byte 0x9f, 0x06, 0xf6
	jr	nc, 21
	pushw	iz
	ld	xwa, (xsp+22)
	push	xwa
	calr	64599
	inc	6, xsp
	cps	hl, 0
	jr	z, 29
	inc	1, iz
	.byte 0x9f, 0x06, 0xf6
	jr	c, -21
	ld	xwa, (xsp+20)
	push	xwa
	calr	2048
	ld	xwa, (xsp+24)
	push	xwa
	calr	63921
	inc	8, xsp
	ldw	hl, 15
	jrl	241
	ld	xwa, (xsp+20)
	ld	xwa, (xwa+30)
	.byte 0x98
	ldb	d, 4
	pushw	iz
	ld	xwa, (xsp+24)
	push	xwa
	calr	64811
	inc	8, xsp
	ld	xwa, (xsp+20)
	.byte 0x98
	ld	xiy, 0x6e00003f
	ldio	175, 20
	ldb	w, 184
	ld	xiy, 0x2e1a6856
	.byte 0x9f
	ldio	4, 175
	push_f
	ldb	w, 56
	calr	64780
	inc	8, xsp
	.byte 0x9f
	ldio	63, 0
	nop
	jr	nz, 6
	ld	xwa, (xsp+20)
	incm	1, (xwa+46)
	ld	(xsp+6), iz
	incm	1, (xsp+10)
	ld	wa, (xsp+10)
	cp	wa, iz
	jr	nz, 8
	ld	xwa, (xsp+20)
	incm	1, (xwa+44)
	jr	5
	.byte 0xbf
	ldwio	2, 0
	.byte 0x9f
	ldio	63, 0
	nop
	jr	nz, 20
	ld	xwa, (xsp+20)
	ld	(xwa+42), iz
	ld	(xsp+8), iz
	ld	(xsp+10), iz
	ld	xwa, (xsp+20)
	.byte 0xb8
	pushw	ix
	push_sr
	.byte 0x01
	nop
	ld	wa, (xsp+26)
	decm	1, (xsp+26)
	cps	wa, 0
	jrl	nz, -221
	.byte 0x9f
	push_f
	push	xsp
	nop
	nop
	jr	z, 105
	ld	xwa, (xsp+12)
	lda	xbc, (xwa+32)
	ld	wa, iz
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	Math_MultiplyAccumulate
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+20)
	add	xwa, xhl
	ld	(xsp+8), xwa
	ld	xiz, xwa
	jr	59
	pushw	34
	lds32	xwa, 0
	push	xwa
	push	xiz
	ld	xwa, (xsp+30)
	push	xwa
	calr	62935
	add	xsp, 14
	or	xhl, xhl
	jr	nz, 5
	ldw	hl, 10
	jr	45
	.byte 0x9b
	push_a
	push	xsp
	nop
	nop
	jr	z, 5
	ld	hl, (xhl+20)
	jr	33
	pushw	512
	pushw	0
	lda	xwa, (xhl+26)
	push	xwa
	call	Memset
	inc	8, xsp
	inc	1, xiz
	ld	xbc, (xsp+8)
	ld	xwa, (xsp+12)
	.byte 0xa8
	ldb	w, 129
	cp	xiz, xbc
	jr	c, -72
	lds	hl, 0
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	push	xiz
	ld	xiz, (xsp+12)
	pushw	11
	pushw	32
	ld	xwa, (xsp+12)
	push	xwa
	call	Memset
	inc	8, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+11), 0
	lds	hl, 0
	.byte 0xa6
SeqByteBlock_MedleyPlayback:
	ldb	w, 128
	push	xsp
	pushw	sp
	jr	z, 7
SeqByteBlock_EffectsSeqData:
	ld	xwa, (xiz)
	.byte 0x80
	push	xsp
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
	.byte 0xe0, 0xe8
	ld	xhl, 0x88a6a9e8
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
	.byte 0x80
	push	xsp
	nop
	jr	z, 3
	ldw	hl, 0xffff
	ld	xwa, (xsp+8)
	cp	(xwa), 46
	jr	nz, 10
	ld	xwa, (xsp+8)
	.byte 0x88, 0x01
	.ascii "? vOÿ^"
	ret
	lda	xsp, (xsp-32)
	pushw	iz
	ld	xwa, (xsp+38)
	ld	xwa, (xwa+18)
	push	xwa
	ld	xwa, (xsp+42)
	ld	xwa, (xwa+10)
	ld	xwa, (xwa+28)
	call	(xwa)
	inc	4, xsp
	cps	hl, 0
	jr	z, 79
	lda_24	xwa, 0x2121a
	ld	(xsp+16), xwa
	lds	iz, 0
	cp	iz, 10
	jr	ge, 54
	ld	xwa, (xsp+38)
	ld	xbc, (xwa+18)
	ld	xwa, (xsp+16)
	.byte 0xa0, 0xf1
	jr	nz, 25
	ld	xwa, (xsp+16)
	ld	a, (xwa+22)
	and	a, 3
	cps	a, 3
	jr	nz, 5
	lds	hl, 6
	jrl	932
	ld	xwa, (xsp+16)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xf6
	inc	1, iz
	ld	xwa, 538
	add	(xsp+16), xwa
	cp	iz, 10
	jr	lt, -54
	ld	xwa, (xsp+38)
	ld	xwa, (xwa+18)
	.byte 0xb8
	push_sr
	.byte 0xb9
	ld	xwa, (xsp+38)
	ld	xwa, (xwa+18)
	ld	xwa, (xwa+26)
	ld	(xsp+4), xwa
	lda	xwa, (xsp+42)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	calr	65223
	inc	8, xsp
	ld	(xsp+20), hl
	.byte 0x9f
	push_a
	push	xsp
	swi	7
	swi	7
	jr	nz, 6
	ldw	hl, 11
	jrl	859
	.byte 0x8f
	ex_ff
	push	xsp
	ldb	w, 126
	ldw	de, 0xaf01
	ldb	h, 32
	.byte 0xb8
	pop_sr
	scc8	z, h
	pushw	bc
	.byte 0x01
	ld	xwa, (xsp+4)
	ld	bc, (xwa+44)
	sll	bc, 5
	extz	xbc
	ld	xwa, (xsp+38)
	ld	(xwa+71), xbc
	ld	xwa, (xsp+38)
	.byte 0xb8
	pop_sr
	.byte 0xb1
	ld	xwa, (xsp+38)
	lds32	xbc, 0
	ld	(xwa+26), xbc
	lds	hl, 0
	jrl	807
	ld	xwa, (xsp+16)
	.byte 0x98
	push_a
	push	xsp
	nop
	nop
	jr	z, 9
	ld	xwa, (xsp+16)
	ld	hl, (xwa+20)
	jrl	788
	ld	xwa, (xsp+16)
	lda	xwa, (xwa+26)
	ld	(xsp+8), xwa
	lds	iz, 0
	jrl	160
	ld	xwa, (xsp+8)
	.byte 0x80
	push	xsp
	nop
	jrl	z, 497
	pushw	11
	ld	xwa, (xsp+10)
	push	xwa
	lda	xwa, (xsp+28)
	push	xwa
	call	String_Compare
	add	xsp, 10
	cps	hl, 0
	jr	nz, 116
	.byte 0xc7
	swi	0
	ld	h, (xhl-81)
	ldb	w, 184
	ldw	hl, 0xaf43
	ldio	32, 56
	ld	xwa, (xsp+42)
	lda	xwa, (xwa+52)
	push	xwa
	calr	63513
	ld	xwa, (xsp+46)
	ld	bc, (xwa+69)
	ld	xwa, (xsp+46)
	ld	(xwa+42), bc
	ld	(xsp+22), bc
	ld	xwa, (xsp+46)
	push	xwa
	calr	64561
	lda	xsp, (xsp+12)
	ld	xwa, (xsp+38)
	lds32	xbc, 0
	ld	(xwa+22), xbc
	ld	xwa, (xsp+38)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	ld	xwa, (xsp+16)
	.byte 0xb8
	ex_ff
	.byte 0xb3, 0x9f
	push_a
	push	xsp
	nop
	nop
	jrl	z, 546
	ld	xwa, (xsp+38)
	.byte 0xb8
	ld	xwa, 0x20776cc
	lda	xwa, (xsp+42)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	calr	64988
	inc	8, xsp
	ld	(xsp+20), hl
	.byte 0x9f
	push_a
	push	xsp
	swi	7
	swi	7
	jr	nz, 71
	ldw	hl, 11
	jrl	624
	inc	1, iz
	ld	xwa, 32
	add	(xsp+8), xwa
	ldw	wa, 16
	.byte 0x9f
	push_sr
	push	xsp
	rcf
	nop
	jr	gt, 3
	ld	wa, (xsp+2)
	cp	iz, wa
	jrl	lt, -178
	ld	xwa, (xsp+16)
	.byte 0xb8
	ex_ff
	.byte 0xb3
	ld	xwa, (xsp+12)
	lds32	xbc, 1
	add	(xwa), xbc
	.byte 0x9f
	push_sr
	push	xde
	rcf
	nop
	jr	gt, 74
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jr	z, 5
	lds	hl, 7
	jrl	564
	lds	hl, 5
	jrl	559
	.byte 0xbf
	incf
	push_sr
	.byte 0x01
	nop
	.byte 0x9f
	ret
	push	xsp
	nop
	nop
	jrl	nz, 359
	ld	xwa, (xsp+38)
	.byte 0xb8
	ldw	wa, 2
	nop
	ld	xwa, (xsp+38)
	lda	xwa, (xwa+26)
	ld	(xsp+12), xwa
	ld	xwa, (xsp+4)
	ld	xbc, (xsp+12)
	ld	xwa, (xwa+28)
	ld	(xbc), xwa
	ld	xwa, (xsp+4)
	ld	wa, (xwa+44)
	ld	(xsp+2), wa
	.byte 0x9f
	push_sr
	push	xsp
	nop
	nop
	jr	le, -74
	pushw	8
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xsp+18)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+48)
	push	xwa
	calr	62163
	lda	xsp, (xsp+14)
	ld	(xsp+16), xhl
	ld	xwa, (xsp+16)
	or	xwa, xwa
	jrl	nz, -338
	ld	xwa, (xsp+38)
	ld	hl, (xwa+6)
	jrl	460
	pushw	8
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xsp+44)
	ld	xwa, (xwa+26)
	push	xwa
	ld	xwa, (xsp+48)
	push	xwa
	calr	62120
	lda	xsp, (xsp+14)
	ld	(xsp+16), xhl
	ld	xwa, (xsp+16)
	or	xwa, xwa
	jr	nz, 9
	ld	xwa, (xsp+38)
	ld	hl, (xwa+6)
	jrl	418
	ld	xwa, (xsp+16)
	.byte 0x98
	push_a
	push	xsp
	nop
	nop
	jr	z, 9
	ld	xwa, (xsp+16)
	ld	hl, (xwa+20)
	jrl	399
	ld	xwa, (xsp+16)
	lda	xwa, (xwa+26)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+38)
	ld	(xwa+51), 0
	ld	xwa, (xsp+38)
	.byte 0x88
	ldw	hl, 4159
	jrl	nc, 142
	ld	xwa, (xsp+8)
	.byte 0x80
	push	xsp
	nop
	jr	z, 97
	pushw	11
	ld	xwa, (xsp+10)
	push	xwa
	lda	xwa, (xsp+28)
	push	xwa
	call	String_Compare
	add	xsp, 10
	cps	hl, 0
	jr	nz, 85
	.byte 0xbf
	incf
	push_sr
	nop
	nop
	ld	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+42)
	lda	xwa, (xwa+52)
	push	xwa
	calr	63117
	ld	xwa, (xsp+46)
	ld	bc, (xwa+69)
	ld	xwa, (xsp+46)
	ld	(xwa+42), bc
	ld	(xsp+22), bc
	ld	xwa, (xsp+46)
	ld	(xwa+48), bc
	ld	xwa, (xsp+46)
	push	xwa
	calr	64159
	lda	xsp, (xsp+12)
	ld	xwa, (xsp+16)
	.byte 0xb8
	ex_ff
	.byte 0xb3
	ld	xwa, (xsp+38)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	.byte 0x9f
	incf
	push	xsp
	nop
	nop
	jrl	z, 144
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jrl	z, 132
	lds	hl, 7
	jrl	255
	ld	xwa, (xsp+38)
	incm8	1, (xwa+51)
	ld	xwa, 32
	add	(xsp+8), xwa
	ld	xwa, (xsp+38)
	.byte 0x88
	ldw	hl, 4159
	jrl	c, -142
	ld	xwa, (xsp+16)
	.byte 0xb8
	ex_ff
	.byte 0xb3
	ld	xwa, (xsp+38)
	lds32	xbc, 1
	add	(xwa+26), xbc
	incm	1, (xsp+2)
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+32)
	cp	(xsp+2), wa
	jrl	lt, -258
	.byte 0x9f
	ret
	.byte 0x04
	ld	xwa, (xsp+40)
	push	xwa
	calr	63320
	inc	6, xsp
	ld	(xsp+14), hl
	ld	xwa, (xsp+4)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	(xsp+14), wa
	jr	ugt, -102
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+32)
	ld	wa, (xsp+14)
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	Math_MultiplyAccumulate
	ld	xwa, (xsp+4)
	ld	xbc, (xwa+20)
	add	xbc, xhl
	ld	xwa, (xsp+38)
	ld	(xwa+26), xbc
	.byte 0xbf
	push_sr
	push_sr
	nop
	nop
	jr	-80
	ldw	hl, 12
	jrl	128
	lds	hl, 5
	jr	124
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jrl	nz, -546
	ld	xwa, (xsp+38)
	.byte 0xb8
	pop_sr
	inc	6, h
	ld	xiy, 0xb82026af
	ld	xwa, 0x33056ecc
	decf
	nop
	jr	95
	.byte 0x9f
	ret
	push	xsp
	nop
	nop
	jr	nz, 32
	jrl	-758
	ld	xwa, (xsp+4)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+38)
	add	(xwa+71), xbc
	.byte 0x9f
	ret
	.byte 0x04
	ld	xwa, (xsp+40)
	push	xwa
	calr	63189
	inc	6, xsp
	ld	(xsp+14), hl
	ld	xwa, (xsp+4)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	(xsp+14), wa
	jr	ule, -42
	lds	hl, 0
	jr	39
	ld	xwa, (xsp+38)
	ld	a, (xwa+64)
	and	a, 24
	jr	z, 5
	ldw	hl, 13
	jr	23
	ld	xwa, (xsp+38)
	.byte 0xb8
	ld	xwa, 0xaf0d66c8
	ldb	h, 32
	.byte 0xb8
	pop_sr
	inc	6, a
	halt
	ldw	hl, 14
	jr	2
	lds	hl, 0
	popw	iz
	lda	xsp, (xsp+32)
	ret
	lda	xsp, (xsp-30)
	push	xiz
	ld	xiz, (xsp+38)
	ld	xwa, (xiz+18)
	ld	xwa, (xwa+26)
	ld	(xsp+6), xwa
	lda	xwa, (xsp+42)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	calr	64314
	inc	8, xsp
	cps	hl, 0
	jrl	nz, 278
	lda	xwa, (xiz+26)
	ld	(xsp+14), xwa
	ld	xwa, (xsp+6)
	ld	xbc, (xsp+14)
	ld	xwa, (xwa+28)
	ld	(xbc), xwa
	ld	xwa, (xsp+6)
	ld	wa, (xwa+44)
	ld	(xsp+4), wa
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jrl	lt, 238
	pushw	24
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xsp+20)
	ld	xwa, (xwa)
	push	xwa
	push	xiz
	calr	61591
	lda	xsp, (xsp+14)
	ld	(xsp+18), xhl
	ld	xwa, (xsp+18)
	or	xwa, xwa
	jr	nz, 6
	ld	hl, (xiz+6)
	jrl	484
	ld	xwa, (xsp+18)
	.byte 0x98
	push_a
	push	xsp
	nop
	nop
	jr	z, 9
	ld	xwa, (xsp+18)
	ld	hl, (xwa+20)
	jrl	465
	ld	xwa, (xsp+18)
	lda	xwa, (xwa+26)
	ld	(xsp+10), xwa
	lds	hl, 0
	jr	126
	ld	xwa, (xsp+10)
	.byte 0x80
	push	xsp
	.byte 0xe5
	jr	z, 8
	ld	xwa, (xsp+10)
	.byte 0x80
	push	xsp
	nop
	jr	nz, 100
	ld	(xiz+51), l
	.byte 0xbe
	pushw	de
	push_sr
	nop
	nop
	.byte 0xbe
	pushw	iz
	push_sr
	nop
	nop
	ld	(xiz+50), 0
	pushw	11
	lda	xwa, (xsp+24)
	push	xwa
	lda	xwa, (xiz+52)
	push	xwa
	call	Mem_Copy
	ld	(xiz+64), 0
	.byte 0xbe
	ld	xiy, 0xe8000002
	.byte 0xa8
	ld	(xiz+71), xwa
	lds32	xwa, 0
	ld	(xiz+34), xwa
	lda	xwa, (xiz+65)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call	(xwa)
	ld	xwa, (xsp+24)
	push	xwa
	lda	xwa, (xiz+52)
	push	xwa
	calr	62667
	ld	xwa, (xsp+40)
	.byte 0xb8
	ex_ff
	.byte 0xb9
	ld	xwa, (xsp+40)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xe7
	ld	xwa, (xsp+40)
	push	xwa
	calr	62003
	lda	xsp, (xsp+26)
	jrl	336
	inc	1, hl
	ld	xwa, 32
	add	(xsp+10), xwa
	ldw	wa, 16
	.byte 0x9f, 0x04
	push	xsp
	rcf
	nop
	jr	gt, 3
	ld	wa, (xsp+4)
	cp	hl, wa
	jrl	lt, -144
	ld	xwa, (xsp+18)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xe7, 0x9f, 0x04
	push	xde
	rcf
	nop
	ld	xwa, (xsp+14)
	lds32	xbc, 1
	add	(xwa), xbc
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jrl	ge, -238
	ldw	hl, 16
	jrl	275
	ld	wa, (xiz+69)
	ld	(xiz+48), wa
	lda	xwa, (xsp+42)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	calr	64012
	inc	8, xsp
	cps	hl, 0
	jrl	z, 208
	lda	xwa, (xsp+42)
	push	xwa
	lda	xwa, (xsp+26)
	push	xwa
	calr	63994
	inc	8, xsp
	cps	hl, 0
	jr	nz, -17
	jrl	188
	ld	xwa, (xsp+6)
	lda	xbc, (xwa+32)
	ld	wa, (xiz+42)
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	Math_MultiplyAccumulate
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+20)
	add	xwa, xhl
	ld	(xiz+26), xwa
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	jr	121
	pushw	24
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xiz+26)
	push	xwa
	push	xiz
	calr	61268
	lda	xsp, (xsp+14)
	ld	(xsp+18), xhl
	ld	xwa, (xsp+18)
	or	xwa, xwa
	jr	nz, 6
	ld	hl, (xiz+6)
	jrl	161
	ld	xwa, (xsp+18)
	.byte 0x98
	push_a
	push	xsp
	nop
	nop
	jr	z, 9
	ld	xwa, (xsp+18)
	ld	hl, (xwa+20)
	jrl	142
	ld	xwa, (xsp+18)
	lda	xwa, (xwa+26)
	ld	(xsp+10), xwa
	ld	(xiz+51), 0
	.byte 0x8e
	ldw	hl, 4159
	jr	nc, 35
	ld	xwa, (xsp+10)
	.byte 0x80
	push	xsp
	.byte 0xe5
	jrl	z, -319
	ld	xwa, (xsp+10)
	.byte 0x80
	push	xsp
	nop
	jrl	z, -328
	.byte 0x8e
	.asciz "3a@ "
	nop
	nop
	add	(xsp+10), xwa
	.byte 0x8e
	ldw	hl, 4159
	jr	c, -35
	ld	xwa, (xsp+18)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xe7
	lds32	xwa, 1
	add	(xiz+26), xwa
	incm	1, (xsp+4)
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+32)
	cp	(xsp+4), wa
	jrl	lt, -133
	ld	wa, (xiz+42)
	ld	(xsp+20), wa
	.byte 0x9e
	pushw	de
	.byte 0x04
	push	xiz
	calr	62584
	inc	6, xsp
	ld	(xiz+42), hl
	ld	xwa, (xsp+6)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	(xiz+42), wa
	jrl	ule, -202
	ld	(xiz+51), 0
	ld	wa, (xsp+20)
	ld	(xiz+42), wa
	pushw	1
	pushw	1
	push	xiz
	calr	63365
	inc	8, xsp
	ld	wa, hl
	cps	wa, 0
	jrl	z, -231
	pop	xiz
	lda	xsp, (xsp+30)
	ret
	dec	4, xsp
	push	xiz
	ld	xiz, (xsp+12)
	lda	xwa, (xiz+65)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call	(xwa)
	pushw	26
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xiz+26)
	push	xwa
	push	xiz
	calr	61051
	lda	xsp, (xsp+18)
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 5
	ldw	hl, 10
	jr	41
	ld	a, (xiz+51)
	extz	wa
	sla	wa, 5
	ld	bc, wa
	add	bc, 26
	ld	xwa, (xsp+4)
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0xbe38
	ldw	ix, 0x3830
	calr	62220
	inc	8, xsp
	ld	xwa, (xsp+4)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xe7
	lds	hl, 0
	pop	xiz
	inc	4, xsp
	ret
	push	xiz
	ld	xwa, (xsp+8)
	ld	iz, (xwa+69)
	cps	iz, 0
	jr	nz, 33
	.byte 0xd7
	swi	2
	.byte 0xa8
	jr	28
	pushw	iz
	ld	xwa, (xsp+10)
	push	xwa
	calr	62412
	.byte 0xd7
	swi	2
	.byte 0x9b
	pushw	0
	pushw	iz
	ld	xwa, (xsp+18)
	push	xwa
	calr	62662
	lda	xsp, (xsp+14)
	.byte 0xd7
	swi	2
	xor	(xiz-34), w
	jr	z, 15
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	iz, wa
	jr	ule, -47
	ld	xwa, (xsp+8)
	.byte 0xb8
	pop_sr
	dec	6, e
	push_f
	ld	xwa, (xsp+8)
	.byte 0xb8
	ld	xiy, 0xd9000002
	.byte 0xa8
	ld	xwa, (xsp+8)
	ld	(xwa+42), bc
	ld	xwa, (xsp+8)
	lds32	xbc, 0
	ld	(xwa+71), xbc
	pop	xiz
	ret
	lda	xsp, (xsp-34)
	push	xiz
	.byte 0xbf
	ccf
	push_sr
	nop
	nop
	.byte 0xbf
	push_a
	push_sr
	nop
	nop
	.byte 0xbf
	ex_ff
	push_sr
	.byte 0x01
	nop
	lds32	xwa, 0
	ld	(xsp+24), xwa
	lds32	xhl, 0
	.byte 0xbf
	ldb	w, 2
	swi	7
	retd	0x2aaf
	ldb	w, 168
	.byte 0x1a
	ldb	w, 191
	.byte 0x04
	jr	f, -81
	pushw	de
	ldb	w, 184
	push_sr
	.byte 0xb0
	pushw	538
	call	SeqStep_MemAllocWrapper
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, 5
	lds	hl, 3
	jrl	1047
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+42)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	lds32	xbc, 0
	ld	(xwa+12), xbc
	ld	xwa, (xsp+4)
	.byte 0xb8
	ldw	de, 8194
	nop
	ld	xwa, (xsp+4)
	.byte 0xb8
	ldw	ix, 2050
	nop
	ld	xwa, (xsp+42)
	.byte 0xb8, 0x04
	scc8	z, l
	.byte 0x1f, 0x01, 0xbf
	rcf
	push_sr
	nop
	nop
	jrl	251
	ld	xwa, (xsp+8)
	push	xwa
	ld	xwa, (xsp+28)
	push	xwa
	ld	xwa, (xsp+50)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa+16)
	call	(xwa)
	inc	8, xsp
	ld	iz, hl
	cps	iz, 0
	jr	nz, 25
	ld	xwa, (xsp+8)
	cp	(xwa+536), 85
	jr	nz, 11
	ld	xwa, (xsp+8)
	.byte 0xc3, 0xe1
	pop_f
	push_sr
	push	xsp
	.byte 0xaa
	jr	z, 18
	ldw	iz, 22
	ld	xwa, (xsp+8)
	push	xwa
	call	SeqStep_FreeMemory
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
	calr	61564
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
	calr	61531
	inc	4, xsp
	add	(xsp+24), xhl
	ld	xwa, 16
	add	(xsp+12), xwa
	ld	xwa, (xsp+12)
	.byte 0x88, 0x04
	push	xsp
	halt
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
	.byte 0x88, 0x04
	push	xsp
	.byte 0x04
	jr	c, 5
	.byte 0xbf
	ldb	w, 2
	swi	7
	swi	7
	ld	xwa, (xsp+42)
	.byte 0xb8, 0x04
	inc	6, l
	pop_f
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
	pushw	1
	.byte 0x9f, 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0x9f, 0x1c
	.byte 0x04
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
	pushw	538
	call	SeqStep_MemAllocWrapper
	ld	xiz, xhl
	ld	xwa, (xsp+10)
	push	xwa
	call	SeqStep_FreeMemory
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
	pushw	1
	.byte 0x9f, 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0x9f, 0x1c
	.byte 0x04
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
	.byte 0xb8, 0x04
	inc	6, l
	pop_f
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
	pushw	1
	.byte 0x9f, 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0x9f, 0x1c
	.byte 0x04
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
	calr	61123
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
	.byte 0x98
	ldb	h, 63
	nop
	nop
	jr	z, 10
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+32)
	or	xwa, xwa
	jr	nz, 6
	ldw	iz, 40
	jrl	-541
	lda	xwa, (xsp+34)
	push	xwa
	calr	61062
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
	calr	61033
	ld	xwa, (xsp+12)
	ld	(xwa+44), hl
	lda	xwa, (xsp+42)
	push	xwa
	calr	61020
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
	calr	60987
	ld	xwa, (xsp+20)
	ld	(xwa+48), hl
	lda	xwa, (xsp+50)
	push	xwa
	calr	60974
	ld	xwa, (xsp+24)
	ld	(xwa+50), hl
	lda	xwa, (xsp+54)
	push	xwa
	calr	60961
	ld	xwa, (xsp+28)
	ld	(xwa+52), hl
	lda	xwa, (xsp+58)
	push	xwa
	calr	60948
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
	.byte 0xa8
	rcf
	sub	(xbc), l
	push_f
	sub	(xbc), l
	.byte 0x04
	ldb	w, 184
	push_f
	jr	lt, -81
	.byte 0x04
	ldb	w, 136
	push	xde
	ldb	a, 216
	ccf
	ld	bc, wa
	ld	xwa, (xsp+4)
	.byte 0x98
	ldw	wa, 0xaf41
	.byte 0x04
	ldb	w, 168
	push_f
	ldb	b, 233
	sub	(xde), l
	.byte 0x04
	ldb	w, 184
	.byte 0x1c
	jr	le, -81
	.byte 0x04
	ldb	w, 152
	ldb	h, 33
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
	call	Math_MultiplyAccumulate
	ld	xwa, (xsp+4)
	ld	(xwa+40), hl
	ld	xwa, (xsp+4)
	ld	wa, (xwa+46)
	extz	xwa
	ld	xbc, xwa
	ld	xwa, (xsp+4)
	.byte 0xa8, 0x1c
	sub	(xbc), l
	.byte 0x04
	ldb	w, 184
	push_a
	jr	lt, -81
	.byte 0x04
	ldb	w, 152
	ldb	h, 32
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
	.byte 0x98
	ldw	wa, 0xe941
	.byte 0x8b
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
	call	Math_DivideU32
	inc	1, xhl
	ld	xwa, (xsp+4)
	ld	(xwa+54), hl
	ld	xwa, (xsp+4)
	.byte 0x98
	ldw	iz, 0xf73f
	retd	1379
	.byte 0xbf
	ldb	w, 2
	swi	7
	swi	7
	ld	xwa, (xsp+4)
	ld	bc, (xsp+32)
	ld	(xwa+36), bc
	ld	xwa, (xsp+42)
	.byte 0xb8
	push_sr
	.byte 0xb8
	ld	xwa, (xsp+8)
	push	xwa
	call	SeqStep_FreeMemory
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
	.byte 0xb8
	push_sr
	dec	6, c
	ldb	w, 175
	push_sr
	ldb	w, 56
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
	.byte 0xb8
	push_sr
	.byte 0xbb
	ld	xwa, (xsp+2)
	.byte 0xb8
	push_sr
	dec	6, w
	push_a
	ld	xwa, (xsp+2)
	push	xwa
	calr	64342
	inc	4, xsp
	ld	iz, hl
	cps	iz, 0
	jr	z, 5
	ld	hl, iz
	jrl	156
	ld	xwa, (xsp+6)
	.byte 0x98
	ldb	h, 63
	nop
	push_sr
	jr	z, 5
	lds	hl, 1
	jrl	141
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+6)
	ld	(xwa+30), xbc
	ld	xwa, (xsp+14)
	.byte 0xb8
	pop_sr
	inc	6, b
	reti
	ld	xwa, (xsp+14)
	ld	(xwa+2), 10
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	62483
	inc	8, xsp
	ld	iz, hl
	ld	xwa, (xsp+14)
	.byte 0xb8
	pop_sr
	inc	6, l
	ld	xhl, 0x1566d8de
	cps	iz, 5
	jr	nz, 59
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	63464
	inc	8, xsp
	ld	iz, hl
	jr	42
	ld	xwa, (xsp+14)
	.byte 0xb8
	pop_sr
	inc	6, c
	pushw	3759
	ldb	w, 232
	.byte 0x89
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	ld	xwa, (xsp+14)
	.byte 0xb8
	pop_sr
	inc	6, d
	retd	3759
	ldb	w, 56
	calr	64111
	inc	4, xsp
	ld	xwa, (xsp+14)
	.byte 0xb8
	pop_sr
	.byte 0xbf
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
	call	Math_DivideU32
	ld	xwa, (xsp+8)
	ld	xbc, (xwa+28)
	add	xbc, xhl
	ld	xwa, (xsp+22)
	ld	(xwa), xbc
	ld	xwa, (xsp+22)
	ld	xbc, (xwa)
	ld	xwa, (xsp+8)
	.byte 0xa8, 0x1c
	sub	(xbc), xsp
	ldio	32, 152
	pushw	iz
	ldb	w, 232
	ccf
	sub	xwa, xbc
	ld	xbc, (xsp+26)
	ld	(xbc), wa
	lds	hl, 0
	jrl	363
	ld	xwa, (xsp+16)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+8)
	.byte 0x98
	pushw	wa
	.byte 0x51
	ld	(xsp+4), bc
	ld	xwa, (xsp+8)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+22)
	call	DivMod32
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+38)
	extz	xbc
	ld	xwa, xiz
	call	Math_DivideU32
	ld	a, l
	ld	(xsp+6), a
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f, 0x04, 0xf0
	jr	nz, 66
	ld	xwa, (xsp+16)
	.byte 0x98
	pushw	de
	push	xsp
	nop
	nop
	jr	nz, 33
	ld	xwa, (xsp+16)
	.byte 0xb8
	pop_sr
	inc	6, a
	pop_f
	.byte 0x9f
	push_a
	.byte 0x04
	pushw	0
	ld	xwa, (xsp+20)
	push	xwa
	calr	61612
	inc	8, xsp
	ld	wa, hl
	cps	wa, 0
	jrl	z, 181
	jrl	255
	ld	xwa, (xsp+16)
	.byte 0x98
	pushw	ix
	push	xsp
	nop
	nop
	jrl	nz, 167
	ld	xwa, (xsp+16)
	push	xwa
	calr	61500
	inc	4, xsp
	jrl	155
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f, 0x04, 0xf0
	jr	ule, 19
	ld	xwa, (xsp+16)
	ld	xbc, xwa
	ld	wa, (xwa+69)
	ld	(xbc+42), wa
	ld	xwa, (xsp+16)
	.byte 0xb8
	pushw	iz
	push_sr
	nop
	nop
	ld	xwa, (xsp+16)
	ld	hl, (xwa+42)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f, 0x04, 0xf0
	jr	nc, 99
	pushw	hl
	ld	xwa, (xsp+18)
	push	xwa
	calr	60702
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
	.byte 0xb8
	pop_sr
	inc	6, a
	.byte 0x17, 0x9f
	push_a
	.byte 0x04
	pushw	0
	ld	xwa, (xsp+20)
	push	xwa
	calr	61469
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
	.byte 0x9f, 0x04, 0xf0
	jr	c, -99
	ld	xwa, (xsp+16)
	push	xwa
	calr	61342
	inc	4, xsp
	lds32	xwa, 0
	ld	a, (xsp+6)
	ld	xbc, xwa
	ld	xwa, (xsp+8)
	.byte 0xa8
	push_a
	sub	(xbc), l
	ex_ff
	ldb	w, 176
	jr	lt, -81
	ldio	32, 184
	ldb	w, 49
	ld	xwa, (xsp+16)
	ld	wa, (xwa+42)
	dec	2, wa
	extz	xwa
	ld	xbc, (xbc)
	call	Math_MultiplyAccumulate
	ld	xwa, (xsp+22)
	add	(xwa), xhl
	ld	xwa, (xsp+16)
	ld	wa, (xwa+44)
	extz	xwa
	ld	xbc, (xsp+8)
	ld	xbc, (xbc+32)
	call	Math_MultiplyAccumulate
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
	pushw	1
	push	xiz
	calr	65064
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
	calr	59024
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
	.byte 0x9f, 0x1c
	push	xsp
	nop
	nop
	jr	nz, 5
	lds	hl, 0
	jrl	372
	ld	xwa, (xiz+30)
	ld	(xsp+6), xwa
	ld	xbc, (xiz+22)
	ld	xwa, (xsp+6)
	.byte 0x98
	pushw	wa
	.byte 0x51
	ld	(xsp+4), bc
	ld	wa, (xsp+28)
	exts	xwa
	ld	xbc, xwa
	.byte 0xae
	ex_ff
	sub	(xbc), l
	.byte 0x06
	ldb	w, 152
	pushw	wa
	ldb	w, 232
	ccf
	add	xwa, xbc
	ld	xde, xwa
	dec	1, xde
	ld	xwa, (xsp+6)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, xde
	call	Math_DivideU32
	ld	wa, (xsp+4)
	extz	xwa
	sub	xhl, xwa
	lda	xwa, (xsp+10)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	pushw	hl
	push	xiz
	calr	64914
	add	xsp, 14
	cps	hl, 0
	jr	z, 17
	ld	a, l
	exts	wa
	st16_24	0x1e53c, wa
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
	.byte 0xb8
	ex_ff
	.byte 0xb3
	pushw	40
	lds32	xwa, 0
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	push	xiz
	calr	58835
	lda	xsp, (xsp+14)
	ld	(xiz+34), xhl
	or	xhl, xhl
	jr	nz, 17
	.byte 0xbe
	ei	2
	ldwio	0, 0x3cf2
	.byte 0xe5, 0x01
	push_sr
	ldwio	0, 0xa8db
	jrl	202
	ld	xbc, (xiz+34)
	ld	xwa, (xsp+24)
	ld	(xbc+12), xwa
	ld	wa, (xsp+28)
	ld	(xsp+4), wa
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98
	ldb	h, 81
	ld	(xsp+4), bc
	ld	xbc, (xiz+34)
	lda	xbc, (xbc+16)
	ld	wa, (xsp+4)
	.byte 0x9f
	ldwio	240, 1391
	ld	wa, (xsp+4)
	jr	3
	ld	wa, (xsp+10)
	ld	(xbc), wa
	ld	xwa, (xiz+34)
	ld	wa, (xwa+16)
	ld	(xsp+4), wa
	.byte 0x9f
	calr	63
	nop
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
	.byte 0xb8
	ex_ff
	.byte 0xb3
	ld	xbc, (xiz+34)
	lds32	xwa, 0
	ld	(xbc+12), xwa
	ld	xwa, (xiz+34)
	.byte 0x98
	push_a
	push	xsp
	nop
	nop
	jr	z, 4
	lds	hl, 0
	jr	11
	ld	bc, (xsp+4)
	ld	xwa, (xsp+6)
	.byte 0x98
	ldb	h, 65
	ld	hl, bc
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98
	pushw	wa
	.byte 0x51
	sub	(xiz+44), bc
	ld	xwa, (xiz+34)
	ld	(xwa+22), 0
	ld	xwa, (xiz+34)
	.byte 0x98
	push_a
	push	xsp
	ldb	c, 0
	jr	nz, 8
	ld	xwa, (xiz+34)
	.byte 0xb8
	push_a
	push_sr
	nop
	nop
	pop	xiz
	lda	xsp, (xsp+12)
	ret
	dec	4, xsp
	pushw	iz
	.byte 0xbf
	push_sr
	push_sr
	nop
	nop
	ld	wa, (xsp+18)
	ld	(xsp+4), wa
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ex_ff
	.byte 0xf1
	jr	nz, 13
	ld	xwa, (xsp+10)
	.byte 0x98, 0x06
	push	xiz
	nop
	xor	(xwa), c
	cp	(xwa+120), xhl
	.byte 0x01
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ex_ff
	.byte 0xa1
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
	.byte 0xa8
	ex_ff
	.byte 0xa1
	ld	(xsp+18), bc
	.byte 0x9f
	ccf
	push	xsp
	nop
	nop
	jrl	z, 435
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ex_ff
	subdm8	0x286e, l
	ldwio	32, 1688
	push	xsp
	ldb	c, 0
	jr	z, 30
	ld	xwa, (xsp+10)
	.byte 0xb8
	pop_sr
	dec	6, b
	ex_ff
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jr	nz, 15
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+30)
	ld	wa, (xsp+18)
	.byte 0x99
	ldb	h, 240
	jrl	nc, 168
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	nz, 33
	pushw	64
	ld	xwa, (xsp+12)
	push	xwa
	calr	64893
	inc	6, xsp
	ld	wa, hl
	cps	wa, 0
	jr	z, 26
	ld	a, l
	exts	wa
	st16_24	0x1e53c, wa
	ld	hl, (xsp+2)
	jrl	354
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	.byte 0xb8
	ex_ff
	inc	6, w
	.byte 0xd4
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ex_ff
	ldda8	w, 2735
	ld	xwa, (xwa+30)
	ld	de, (xwa+38)
	sub	de, bc
	ld	wa, bc
	extz	xwa
	lda	xbc, (xwa+26)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ldb	b, 129
	ld	xwa, (xsp+10)
	.byte 0xb8
	pop_sr
	scc8	nz, b
	.byte 0x94
	nop
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
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
	call	Mem_Copy
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
	.byte 0x9f
	ccf
	push	xsp
	nop
	nop
	jrl	z, 168
	pushw	1
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xwa, (xwa+4)
	cpl	wa
	.byte 0xd7
	ld32_24	xbc, 0x149f06
	extz	xbc
	and	xbc, xwa
	pushw	bc
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	64785
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+10)
	.byte 0x98, 0x06
	push	xsp
	nop
	nop
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
	.byte 0xb8
	pop_sr
	inc	6, b
	push	129
	push	xsp
	decf
	jr	nz, 4
	inc	1, xbc
	jr	40
	decm	1, (xsp+18)
	incm	1, (xsp+2)
	.byte 0xc5, 0xe4
	ldb	e, 175
	ret
	ldb	w, 245
	.byte 0xe0
	ld	xiy, 0xaf600ebf
	ldwio	32, 648
	swi	5
	jr	nz, 14
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jr	z, 7
	.byte 0xbf
	ccf
	push_sr
	nop
	nop
	lds	iz, 1
	ld	xwa, (xsp+10)
	lds32	xde, 1
	add	(xwa+22), xde
	djnz16	iz, -68
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	.byte 0xa8
	ex_ff
	subdm8	4462, l
	ldwio	32, 8872
	ldb	w, 184
	ex_ff
	.byte 0xb3
	ld	xwa, (xsp+10)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	.byte 0x9f
	ccf
	push	xsp
	nop
	nop
	jrl	nz, -435
	ld	wa, (xsp+2)
	.byte 0x9f, 0x04, 0xf0
	jr	nc, 8
	ld	xwa, (xsp+10)
	.byte 0x98, 0x06
	push	xiz
	nop
	.byte 0x80
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
	pushw	1
	ld	wa, (xsp+14)
	pushw	wa
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	64944
	lda	xsp, (xsp+12)
	ret
	dec	6, xsp
	pushw	iz
	ldw	(xsp+2), 0
	.byte 0xbf
	ei	2
	nop
	nop
	cpw	(xsp+20), 0
	jr	z, 12
	ld	xwa, (xsp+12)
	.byte 0xb8
	pop_sr
	.byte 0xbf
	ld	xwa, (xsp+12)
	.byte 0xb8
	ld	xwa, 0x3f149fbd
	nop
	nop
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
	.byte 0xa8
	ex_ff
	subdm8	0x286e, l
	incf
	ldb	w, 152
	ei	63
	ldb	c, 0
	jr	z, 30
	ld	xwa, (xsp+12)
	.byte 0xb8
	pop_sr
	dec	6, b
	ex_ff
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
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
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
	calr	64306
	inc	6, xsp
	ld	wa, hl
	cps	wa, 0
	jr	z, 15
	ld	a, l
	exts	wa
	st16_24	0x1e53c, wa
	ld	hl, (xsp+2)
	jrl	442
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	.byte 0xb8
	ex_ff
	.byte 0xb9
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
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	de, 3247
	ldb	w, 184
	pop_sr
	scc8	nz, b
	.byte 0x9d
	nop
	.byte 0x9f
	ex_ff
	push	xsp
	nop
	nop
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
	call	Mem_Copy
	lda	xsp, (xsp+10)
	sub	(xsp+20), iz
	ld	xwa, (xsp+16)
	.byte 0xf3
	reti
	.byte 0xe0
	swi	0
	ldw	wa, 4287
	jr	f, -97
	push_sr
	add	(xiz-34), a
	exts	xbc
	ld	xwa, (xsp+12)
	add	(xwa+22), xbc
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jrl	z, 250
	pushw	0
	ld	xwa, (xsp+14)
	ld	xwa, (xwa+30)
	ld	xwa, (xwa+4)
	cpl	wa
	.byte 0xd7
	ld32_24	xbc, 0x169f06
	exts	xbc
	and	xbc, xwa
	pushw	bc
	ld	xwa, (xsp+20)
	push	xwa
	ld	xwa, (xsp+20)
	push	xwa
	calr	64201
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+12)
	.byte 0x98, 0x06
	push	xsp
	nop
	nop
	jr	z, 6
	ld	hl, (xsp+2)
	jrl	263
	sub	(xsp+20), iz
	ld	xwa, (xsp+16)
	.byte 0xf3
	reti
	.byte 0xe0
	swi	0
	ldw	wa, 4287
	jr	f, -97
	push_sr
	add	(xiz-34), a
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
	.byte 0xb8
	pop_sr
	inc	6, b
	popw	sp
	.byte 0x9f, 0x06
	push	xsp
	nop
	nop
	jr	z, 28
	.byte 0xf5, 0xe8
	nop
	ldwio	191, 518
	nop
	nop
	decm	1, (xsp+20)
	.byte 0x9f
	ex_ff
	push	xsp
	nop
	nop
	jr	z, 95
	.byte 0xbf
	push_a
	push_sr
	nop
	nop
	lds	iz, 1
	jr	86
	ld	xwa, (xsp+16)
	.byte 0x80
	push	xsp
	ldwio	110, 0xf510
	.byte 0xe8
	nop
	decf
	lds32	xwa, 1
	add	(xsp+16), xwa
	.byte 0xbf
	ei	2
	.byte 0x01
	nop
	jr	15
	ld	xwa, (xsp+16)
	.byte 0xc5, 0xe0
	ldb	c, 245
	.byte 0xe8
	ld	xhl, 0x9f6010bf
	push_a
	jr	ge, -97
	push_sr
	jr	lt, 104
	pushw	de
	ld	xwa, (xsp+16)
	.byte 0xc5, 0xe0
	ldb	c, 178
	ld	xhl, 0x9f6010bf
	push_a
	jr	ge, -97
	push_sr
	jr	lt, -81
	incf
	ldb	w, 136
	push_sr
	ldb	a, 197
	cp	xbc, xwa
	jr	nz, 14
	.byte 0x9f
	ex_ff
	push	xsp
	nop
	nop
	jr	z, 7
	.byte 0xbf
	push_a
	push_sr
	nop
	nop
	lds	iz, 1
	ld	xwa, (xsp+12)
	lds32	xbc, 1
	add	(xwa+22), xbc
	sub	iz, 1
	jrl	nz, -144
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+12)
	.byte 0xa8
	ld	xsp, 0xaf0b63f1
	incf
	ldb	w, 232
	.byte 0x89
	ld	xwa, (xwa+22)
	ld	(xbc+71), xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	.byte 0xa8
	ex_ff
	subdm8	4462, l
	incf
	ldb	w, 168
	ldb	b, 32
	.byte 0xb8
	ex_ff
	.byte 0xb3
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	.byte 0x9f
	push_a
	push	xsp
	nop
	nop
	jrl	nz, -584
	ld	hl, (xsp+2)
	popw	iz
	inc	6, xsp
	ret
SeqChan_ProcessEventArg0:
	pushw	0
	.byte 0x9f
	ret
	.byte 0x04
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	64888
	lda	xsp, (xsp+12)
	ret
SeqChan_ProcessEventArg1:
	pushw	1
	.byte 0x9f
	ret
	.byte 0x04
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	64867
	lda	xsp, (xsp+12)
	ret
SeqChan_ValidateAndDispatch:
	push	xiz
	ld	xiz, (xsp+8)
	ld	xwa, (xiz+34)
	or	xwa, xwa
	jr	z, 6
	ld	xwa, (xiz+34)
	.byte 0xb8
	ex_ff
	.byte 0xb3, 0xc2, 0xe2, 0xe2
	pop_sr
	push	xsp
	nop
	jr	nz, 4
	lds	hl, 0
	jr	31
	.byte 0xbe
	pop_sr
	inc	6, l
	ldwio	62, 0x331e
	.byte 0xf1
	inc	4, xsp
	cps	hl, 0
	jr	nz, 16
	ld	xwa, (xiz+18)
	decm8	1, (xwa+3)
	ld	(xiz+4), 0
	push	xiz
	calr	58071
	inc	4, xsp
	pop	xiz
	ret
SeqChan_TraverseAndProcess:
	dec	4, xsp
	push	xiz
	.byte 0xbf
	ei	2
	nop
	nop
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+71)
	cp	xwa, (xsp+16)
	jr	nc, 116
	ld	xwa, (xsp+12)
	.byte 0xb8
	pop_sr
	dec	6, a
	ldio	191, 6
	push_sr
	push_a
	nop
	jrl	205
	ld	xwa, (xsp+12)
	ld	xbc, xwa
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	pushw	32
	ld	xwa, (xsp+14)
	push	xwa
	calr	63677
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
	call	Math_DivideU32
	ld	xwa, (xsp+12)
	ld	wa, (xwa+46)
	extz	xwa
	sub	xhl, xwa
	pushw	hl
	pushw	0
	ld	xwa, (xsp+16)
	push	xwa
	calr	59430
	inc	8, xsp
	ld	(xsp+6), hl
	ld	wa, (xsp+6)
	cps	wa, 0
	jr	nz, 120
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+71), xbc
	ld	xwa, (xsp+12)
	.byte 0xb8
	pop_sr
	.byte 0xbf
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	z, 18
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	.byte 0x88
	ex_ff
	push	xix
	.byte 0xe7
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+22), xbc
	lda_24	xwa, 0x2121a
	ld	xiz, xwa
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	.byte 0x9f, 0x04
	push	xsp
	ldwio	0, 0x3169
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	.byte 0x8e, 0x17, 0xf1
	jr	nz, 23
	ld	a, (xiz+22)
	and	a, 3
	cps	a, 3
	jr	nz, 13
	push	xiz
	calr	57627
	inc	4, xsp
	or	(xsp+6), hl
	.byte 0x8e
	ex_ff
	push	xix
	.byte 0xe5
	incm	1, (xsp+4)
	.byte 0xf3
	swi	1
	.byte 0x1a
	push_sr
	ldw	iz, 1183
	push	xsp
	ldwio	0, 0xcf61
	ld	hl, (xsp+6)
	pop	xiz
	inc	4, xsp
	ret
SeqChan_ReadNextFromLoop:
	lda	xsp, (xsp-30)
	push	xiz
	ld	xiz, (xsp+38)
	pushw	1
	pushw	1
	push	xiz
	calr	59274
	inc	8, xsp
	ld	(xsp+4), hl
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jrl	nz, 136
	pushw	0
	push	xiz
	calr	63449
	inc	6, xsp
	ld	(xsp+4), hl
	.byte 0x9f, 0x04
	push	xsp
	nop
	nop
	jr	nz, 117
	ld	xwa, (xiz+34)
	lda	xwa, (xwa+26)
	ld	(xsp+6), xwa
	pushw	228
	pushw	0x502a
	lda	xwa, (xsp+14)
	push	xwa
	call	Strcpy
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
	calr	58122
	ld	(xsp+31), 46
	ld	wa, (xiz+48)
	ld	(xsp+47), wa
	ld	xwa, (xsp+26)
	push	xwa
	lda	xwa, (xsp+34)
	push	xwa
	calr	58101
	lda	xsp, (xsp+28)
	ld	xwa, (xiz+34)
	.byte 0xb8
	ex_ff
	.byte 0xb9
	ld	xwa, (xiz+34)
	.byte 0xb8
	ex_ff
	call	(xhl)
	.byte 0xa8
	ld	(xiz+71), xwa
	ld	(xiz+64), 16
	.byte 0xbe
	pop_sr
	.byte 0xbf
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
	calr	61288
	ld	(xsp+8), hl
	push	xiz
	calr	57625
	or	(xsp+12), hl
	ld	a, (xiz+5)
	extz	wa
	ld	bc, wa
	sla	bc, 2
	lda_24	xde, 0x210b4
	lds32	xwa, 0
	.byte 0xf3
	reti
	or	xix, xwa
	jr	f, -18
	.byte 0x88
	push	xwa
	call	SeqStep_FreeMemory
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
	calr	57556
	inc	4, xsp
	cps	hl, 0
	jr	z, 56
	ldw	hl, 0xffff
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
	.byte 0xbe
	pop_sr
	.byte 0xbf, 0xb9
	pop_sr
	.byte 0xbf
	lds	hl, 0
	jr	25
	push	xiz
	calr	61237
	inc	4, xsp
	ld	(xiz+52), 229
	.byte 0xbe
	pop_sr
	.byte 0xbf
	jr	-19
	sti16_24	0x1e53c, 18
	ldw	hl, 0xffff
	pop	xiz
	ret

SeqStep_CountValidSectors:
	push xiz
	ldi_werp 0xfa, 0
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
	inc1_werp 0xfa

SeqStep_CountLoop_CheckEnd:
	cpdi16_24 0x1e53c, 0
	jr nz, SeqStep_CountLoop_ResetWerp
	ld xwa, (xsp + 8)
	cpw (xwa + 6), 0x0
	jr z, SeqStep_CountLoop_IncIz

SeqStep_CountLoop_ResetWerp:
	ldi_werp 0xfa, 0
	jr SeqStep_CountLoop_Done

SeqStep_CountLoop_IncIz:
	inc 1, iz

SeqStep_CountLoop_Compare:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 30)
	cp iz, (xwa + 54)
	jr ule, SeqStep_CountLoop_Body

SeqStep_CountLoop_Done:
	ldto_werp HL, 0xfa
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
	.byte 0x9f
	ldio	63, 0
	nop
	jr	z, 40
	ld	bc, (xsp+10)
	and	bc, 24
	ld	a, (xde+64)
	extz	wa
	and	wa, 24
	cp	wa, bc
	jr	z, 11
	sti16_24	0x1e53c, 13
	ldw	hl, 0xffff
	ret
	ld	wa, (xsp+10)
	ld	(xde+64), a
	.byte 0xba
	pop_sr
	ld	(xsp-118), w
	ldb	l, 219
	ccf
	ret
	dec	2, xsp
	push	xiz
	pushw	228
	pushw	0x5036
	ld	xwa, (xsp+14)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 5
	ldw	hl, 0xffff
	jr	24
	.byte 0x9f
	ret
	.byte 0x04
	pushw	1
	push	xiz
	calr	65440
	ld	(xsp+12), hl
	push	xiz
	call	FileClose
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
	calr	57867
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
	call	0xf51e43
	cps	hl, 0
	jr	z, 9
	call	FDC_ClearDiskChangeStatus
	lds	hl, 6
	jrl	136
	call	FDC_ReadDiskType
	cps	l, 2
	jr	nz, 97
	cpw	(xsp+12), 0
	jr	nz, 90
	cpw	(xsp+14), 0
	jr	nz, 83
	cpw	(xsp+16), 1
	jr	nz, 76
	stdi16	0x8a10, 0xffff
	push	xiz
	pushw	1
	pushw	1
	pushw	0
	pushw	0
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw	3
	calr	65360
	lda	xsp, (xsp+16)
	stdi16	0x8a10, 0
	cps	hl, 0
	jr	nz, 8
	ld	(xiz+16), 2
	lds	hl, 0
	jr	52
	pushw	512
	pushw	228
	pushw	0x5038
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+10)
	lds	hl, 0
	jr	31
	push	xiz
	.byte 0x9f
	ex_ff
	.byte 0x04, 0x9f
	ex_ff
	.byte 0x04, 0x9f
	push_a
	.byte 0x04, 0x9f
	push_f
	.byte 0x04
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw	3
	calr	65290
	lda	xsp, (xsp+16)
	pop	xiz
	ret
SeqChan_ByteBlockD:
	ld	xwa, (xsp+16)
	push	xwa
	.byte 0x9f
	ccf
	.byte 0x04, 0x9f
	ccf
	.byte 0x04, 0x9f
	rcf
	.byte 0x04, 0x9f
	push_a
	.byte 0x04
	ld	xwa, (xsp+16)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw	4
	calr	65254
	lda	xsp, (xsp+16)
	ret
	dec	2, xsp
	push	xiz
	ld	xiz, (xsp+14)
	ld	xbc, (xsp+10)
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	cpw	(xbc), 0
	jr	nz, 5
	lds	hl, 0
	jrl	220
	incdi16_24	1, 0x2271e
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
	.byte 0xb1
	push_sr
	.byte 0x1f
	nop
	lds	hl, 0
	jrl	170
	ld	xwa, (xiz)
	.byte 0xb8
	push_sr
	.byte 0xb3, 0xb1
	push_sr
	ldb	a, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65246
	ld	xwa, (xiz)
	push	xwa
	call	0xf50822
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	121
	.byte 0xbf, 0x04
	push_sr
	.byte 0x01
	nop
	jr	114
	ld	xwa, (xiz)
	.byte 0xb8
	push_sr
	.byte 0xb3, 0xb1
	push_sr
	di
	ld	xwa, (xiz)
	ld	xwa, (xwa+26)
	ld	xwa, (xiz)
	push	xwa
	call	0xf50822
	inc	4, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	82
	.byte 0xbf, 0x04
	push_sr
	.byte 0x01
	nop
	jr	75
	ld	xwa, (xiz)
	.byte 0xb8
	push_sr
	.byte 0xb3, 0xb1
	push_sr
	ldb	w, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65167
	ld	xwa, (xiz)
	push	xwa
	call	0xf50822
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	42
	lds	hl, 0
	jr	54
	ld	xwa, (xiz)
	.byte 0xb8
	push_sr
	.byte 0xb3, 0xb1
	push_sr
	ldb	d, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65130
	ld	xwa, (xiz)
	push	xwa
	call	0xf50822
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	5
	.byte 0xbf, 0x04
	push_sr
	.byte 0x01
	nop
	.byte 0xd2
	calr	551
	push	xsp
	.byte 0x01
	nop
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
	sti16_24	0x2271e, 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	de, 0xd751
	.byte 0xe6, 0x88
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	Math_DivideU32
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	ix, 0xd751
	.byte 0xe6, 0x88
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	ix, 0xbf53
	ldio	83, 175
	ex_ff
	ldb	w, 168
	incf
	ldb	w, 232
	.byte 0xe0
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	.byte 0x9f
	ldwio	166, 5807
	ldb	w, 152
	rcf
	swi	6
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
	calr	64950
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cps	wa, 0
	jr	nz, 118
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	.byte 0x98
	rcf
	push	xsp
	nop
	nop
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98
	ldb	h, 65
	.byte 0xa2, 0x81
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	.byte 0x98
	ldw	de, 0x67f1
	.byte 0x8b, 0xbf
	ldwio	2, 0
	incm	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	.byte 0x98
	ldw	ix, 0x7ef1
	jrl	c, -16385
	ei	2
	nop
	nop
	incm	1, (xsp+8)
	jrl	-148
	ld	xwa, (xsp+22)
	lda	xwa, (xwa+26)
	push	xwa
	pushw	1
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
	calr	64825
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	65002
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
	sti16_24	0x2271e, 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	de, 0xd751
	.byte 0xe6, 0x88
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	Math_DivideU32
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	ix, 0xd751
	.byte 0xe6, 0x88
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98
	ldw	ix, 0xbf53
	ldio	83, 175
	ex_ff
	ldb	w, 168
	incf
	ldb	w, 232
	.byte 0xe0
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	.byte 0x9f
	ldwio	166, 5807
	ldb	w, 152
	rcf
	swi	6
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
	calr	64809
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cps	wa, 0
	jr	nz, 118
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	.byte 0x98
	rcf
	push	xsp
	nop
	nop
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98
	ldb	h, 65
	.byte 0xa2, 0x81
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	.byte 0x98
	ldw	de, 0x67f1
	.byte 0x8b, 0xbf
	ldwio	2, 0
	incm	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	.byte 0x98
	ldw	ix, 0x7ef1
	jrl	c, -16385
	ei	2
	nop
	nop
	incm	1, (xsp+8)
	jrl	-148
	ld	xwa, (xsp+22)
	lda	xwa, (xwa+26)
	push	xwa
	pushw	1
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
	calr	64684
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	64702
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
	sti16_24	0x3e3e6, 0
	ld8_24	a, 0x3e3e4
	st8_24	0x3e3e2, a
	ret
	ld16_24	hl, 0x3e3e6
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
; Output: Writes sector length to 0x01e53c
; Maps format codes: 0x2f->0x001F, 0x30/31->0x0020, 6->0x0006, etc.
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
	cp wa, 0x2f
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
	push_werp 0xfa
	lds wa, 0
	calr FDC_SetSectorLength
	lda_24 xwa, Display_FontPalette_Table_0x21E
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_Step2
	ldto_berp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_Step2:
	lda_24 xwa, Display_FontPalette_Table_0x1FE
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_AllocBuf
	ldto_berp A, 0xfb
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
	lda_24 xwa, Display_FontPalette_Table_0x25E
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteFAT1
	ldto_berp A, 0xfb
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
	lda_24 xwa, Display_FontPalette_Table_0x27E
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteFAT2
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteRoot
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteDataSec1
	ldto_berp A, 0xfb
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
	lda_24 xwa, Display_FontPalette_Table_0x27E
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteDataSec2
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_WriteDataSec3
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_InitTrackLoop
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_TrackInc
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_Side1Inc
	ldto_berp A, 0xfb
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
	ldw (xsp + 12), 0x4f
	ldw (xsp + 14), 0x9
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2DD_FinalTrack
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 8, xsp
	cpi_berp 0xfb, 0
	jr nz, FDC_Format2DD_SetSectorAndRet
	lds hl, 1
	jr FDC_CmdFrame_Epilogue

FDC_Format2DD_SetSectorAndRet:
	ldto_berp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FDC_CmdFrame_Epilogue:
	pop_werp 0xfa
	lda xsp, (xsp + 20)
	ret

FDC_Format2HD_Start:
	lda xsp, (xsp - 20)
	push_werp 0xfa
	lds wa, 0
	calr FDC_SetSectorLength
	lda_24 xwa, Display_FontPalette_Table_0x23E
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_Step2
	ldto_berp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_Step2:
	lda_24 xwa, Display_FontPalette_Table_0x1FE
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_AllocBuf
	ldto_berp A, 0xfb
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
	lda_24 xwa, Display_FontPalette_Table_0x282
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_WriteFAT1
	ldto_berp A, 0xfb
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
	lda_24 xwa, Display_FontPalette_Table_0x2A2
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_InitTrackLoop
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_TrackInc
	ldto_berp A, 0xfb
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
	cpw (xsp + 14), 0xa
	jr ule, FDC_Format2HD_TrackBody
	pushw 0x200
	pushw 0x0
	ld xwa, (xsp + 6)
	push xwa
	call Memset
	pushw 0x3
	lda_24 xwa, Display_FontPalette_Table_0x2A2
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Mem_Copy
	ldw (xsp + 24), 0x4
	ldw (xsp + 26), 0x0
	ldw (xsp + 28), 0x0
	ldw (xsp + 30), 0x0
	ldw (xsp + 32), 0xb
	ldw (xsp + 34), 0x1
	ld xwa, (xsp + 20)
	ld (xsp + 36), xwa
	lda xwa, (xsp + 24)
	push xwa
	call FDC_CommandEntry
	lda xsp, (xsp + 22)
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_WriteFAT2
	ldto_berp A, 0xfb
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
	ldw (xsp + 14), 0xc
	jr FDC_Format2HD_Side2Test

FDC_Format2HD_Side2Body:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_Side2Inc
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_InitSide1Loop
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_Side1Inc
	ldto_berp A, 0xfb
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
	cpw (xsp + 14), 0xf
	jr ule, FDC_Format2HD_Side1Body
	ldw (xsp + 6), 0x3
	ldw (xsp + 8), 0x0
	ldw (xsp + 10), 0x0
	ldw (xsp + 12), 0x4f
	ldw (xsp + 14), 0x12
	ldw (xsp + 16), 0x1
	ld xwa, (xsp + 2)
	ld (xsp + 18), xwa
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldfr_berp L, 0xfb
	cpi_berp 0xfb, 0
	jr z, FDC_Format2HD_FinalTrack
	ldto_berp A, 0xfb
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
	ldfr_berp L, 0xfb
	ld xwa, (xsp + 6)
	push xwa
	call Free
	inc 8, xsp
	cpi_berp 0xfb, 0
	jr nz, FDC_Format2HD_SetSectorAndRet
	lds hl, 1
	jr FdcOp_Epilogue20

FDC_Format2HD_SetSectorAndRet:
	ldto_berp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FdcOp_Epilogue20:
	pop_werp 0xfa
	lda xsp, (xsp + 20)
	ret

GetMediaType:
	lda xsp, (xsp - 20)
	push_werp 0xfa
	call Reset_Floppy_Disk_Controller
	pushw 0x400
	call Malloc
	inc 2, xsp
	ld (xsp + 2), xhl
	ld xwa, xhl
	or xwa, xwa
	jr nz, GetMediaType_SetupReadCmd
	ldi_berp 0xfb, 0
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	calr FDC_StoreDiskType
	inc 2, xsp
	ldto_berp L, 0xfb
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
	stdi16 0x8a10, 0xffff
	ldi_berp 0xfb, 0
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr nz, GetMediaType_TryRecalib
	ldi_berp 0xfb, 1
	jrl GetMediaType_Epilogue

GetMediaType_TryRecalib:
	lda_24 xwa, Display_FontPalette_Table_0x24E
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_TryFormat2HD
	ldi_berp 0xfb, 0
	jrl GetMediaType_Epilogue

GetMediaType_TryFormat2HD:
	lda_24 xwa, Display_FontPalette_Table_0x23E
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_ReadSector
	ldi_berp 0xfb, 0
	jrl GetMediaType_Epilogue

GetMediaType_ReadSector:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr nz, GetMediaType_Try2DDHeader
	ld xwa, (xsp + 2)
	cp (xwa), 0xf0
	jr nz, GetMediaType_Type3Check
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jr nz, GetMediaType_Type3Check
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xff
	jr nz, GetMediaType_Type3Check
	ldi_berp 0xfb, 3
	jr GetMediaType_Epilogue

GetMediaType_Type3Check:
	ld xwa, (xsp + 2)
	cp (xwa), 0xf9
	jr nz, GetMediaType_Invalid
	ld xwa, (xsp + 2)
	cp (xwa + 1), 0xff
	jr nz, GetMediaType_Invalid
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xff
	jr nz, GetMediaType_Invalid
	ldi_berp 0xfb, 3
	jr GetMediaType_Epilogue

GetMediaType_Invalid:
	ldi_berp 0xfb, 0
	jr GetMediaType_Epilogue

GetMediaType_Try2DDHeader:
	lda_24 xwa, Display_FontPalette_Table_0x21E
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_Read2DDSector
	ldi_berp 0xfb, 0
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
	cp (xwa + 1), 0xff
	jr nz, GetMediaType_F9Check
	ld xwa, (xsp + 2)
	cp (xwa + 2), 0xff
	jr nz, GetMediaType_F9Check
	ldi_berp 0xfb, 6
	jr GetMediaType_Epilogue

GetMediaType_F9Check:
	ld xwa, (xsp + 2)
	cp (xwa), 0xf9
	jr nz, GetMediaType_CheckExtraFormat
	ldi_berp 0xfb, 2
	jr GetMediaType_Epilogue

GetMediaType_CheckExtraFormat:
	call FDC_DetectDiskFormat
	cps hl, 0
	jr nz, GetMediaType_Epilogue
	ldi_berp 0xfb, 5

GetMediaType_Epilogue:
	stdi16 0x8a10, 0
	ld xwa, (xsp + 2)
	push xwa
	call Free
	ldto_berp A, 0xfb
	extz wa
	pushw wa
	calr FDC_StoreDiskType
	inc 6, xsp
	ldto_berp L, 0xfb

GetMediaType_ReturnAndCleanup:
	pop_werp 0xfa
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
	lda_24 xix, Display_FontPalette_Table_0x2AC
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, GetDiskFreeSpace_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

GetDiskFreeSpace_JumpTable:
	lds	hl, 0
	jr	72
	ld	xwa, 0xb2400
	ld	(xiz), xwa
	jr	16
	ld	xwa, 0x163e00
	ld	(xiz), xwa
	jr	7
	.byte 0x40, 0x00
	ld	xwa, 0x60b6000b

FileIO_ReadFreeSpaceViaFAT:
	pushw 0xe4
	pushw 0x50fe
	pushw 0xe4
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
	lda_24 xix, Display_FontPalette_Table_0x2C0
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, GetVolumeLabel_JumpTable
	jp_dri 8, 0x07, 0xf0, 0xe0

GetVolumeLabel_JumpTable:
	lds32	xhl, 0
	jrl	155

FileIO_ReadVolumeLabelEntry:
	pushw 0xe4
	pushw 0x5112
	pushw 0xe4
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
	cp (xsp + 36), 0xe5
	jr z, GetDiskSpace_ReadLoop
	cp (xsp + 36), 0x0
	jr z, GetVolumeLabel_NotFound
	bitm 3, (xsp + 48)
	jr z, GetDiskSpace_ReadLoop
	pushw 0xb
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
	pushw 0xe4
	pushw 0x5126
	lda xwa, (xsp + 10)
	push xwa
	call Strcat
	ld xwa, xiz
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call Strcat
	pushw 0xe4
	pushw 0x512a
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
	cp (xwa), 0x5c
	jr nz, FileIO_ParseLoop_CopyChar
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xe0, 0xe8, 0x00
	ld xwa, (xsp + 18)
	cp (xwa), 0x0
	jr z, FileIO_ParseLoop_AppendSlash
	pushw 0xe4
	pushw 0x512e
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
	lda_dri3 XBC, 0x07, 0xe4, 0xe8
	inc 1, de
	cp de, 0xc
	jr le, FileIO_ParseLoop_Advance
	ldw hl, 0xffff

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
	ld xhl, 0xffffffff
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
	ld xhl, 0xffffffff
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
	ld xhl, 0xffffffff
	jrl FdcFile_Epilogue20

FindFirst_OpenDir:
	pushw 0xe4
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
	ld xhl, 0xffffffff
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
	ld xhl, 0xffffffff
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
	ld xhl, 0xffffffff

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
	ldw hl, 0xffff
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
	ldw hl, 0xffff
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
	cp (xsp + 44), 0xe5
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
	ld (xiz + 14), 0x2e
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
	ldw hl, 0xffff

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
	pushw 0xb
	pushw 0x3f
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
	cp (xiz), 0x2e
	jr nz, WildMatch_CopyChar
	lda xwa, (xsp + 12)
	ld xbc, xwa
	inc 1, xiz
	jr WildMatch_CheckEnd

WildMatch_CopyChar:
	ld_spib A, 0xf8
	lda_dpi XBC, 0xe4

WildMatch_CheckEnd:
	cp (xiz), 0x0
	jr nz, WildMatch_ScanLoop

WildMatch_FillName:
	lds bc, 0
	cp bc, 0x8
	jr ge, WildMatch_FillExt

WildMatch_NameLoop:
	lda xwa, (xsp + 4)
	cp_srib_im 0x07, 0xe0, 0xe4, 0x2a
	jr nz, WildMatch_NameNext
	cp bc, 0x8
	jr ge, WildMatch_NameNext

WildMatch_StarFillName:
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xe0, 0xe4, 0x3f
	inc 1, bc
	cp bc, 0x8
	jr lt, WildMatch_StarFillName

WildMatch_NameNext:
	inc 1, bc
	cp bc, 0x8
	jr lt, WildMatch_NameLoop

WildMatch_FillExt:
	ldw bc, 0x8
	cp bc, 0xb
	jr ge, WildMatch_Compare

WildMatch_ExtLoop:
	lda xwa, (xsp + 4)
	cp_srib_im 0x07, 0xe0, 0xe4, 0x2a
	jr nz, WildMatch_ExtNext
	cp bc, 0xb
	jr ge, WildMatch_ExtNext

WildMatch_StarFillExt:
	lda xwa, (xsp + 4)
	stib_dri 0x07, 0xe0, 0xe4, 0x3f
	inc 1, bc
	cp bc, 0xb
	jr lt, WildMatch_StarFillExt

WildMatch_ExtNext:
	inc 1, bc
	cp bc, 0xb
	jr lt, WildMatch_ExtLoop

WildMatch_Compare:
	lds hl, 1
	ld xde, (xsp + 16)
	lda xwa, (xsp + 4)
	ld xbc, xwa
	cp (xde), 0x0
	jr z, WildMatch_Return

WildMatch_CompareLoop:
	cp (xbc), 0x3f
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
	ld xhl, 0xffffffff

FindFirst_SndTable_Return:
	pop xiz
	inc 4, xsp
	ret

FileIO_ValidateHandle:
	or xwa, xwa
	jr nz, FileIO_ValidateHandle_Ok
	ldw hl, 0xffff
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
	ldw hl, 0xffff
	jr FileIO_ReadDirEntry_Return

FileIO_ReadDirEntry_Body:
	ld xiz, xwa
	cpw (xiz), 0x50
	jr ge, FileIO_ReadDirEntry_End
	ld wa, (xiz)
	muls wa, 0x2c
	lda_24 xbc, 0x0235a8
	cp_sriw_im 0x07, 0xe4, 0xe0, 0xfe, 0xfe
	jr z, FileIO_ReadDirEntry_End
	pushw 0x14
	ld wa, (xiz)
	muls wa, 0x2c
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
	muls wa, 0x2c
	lda_24 xbc, 0x0235a6
	ld_sriw3 BC, 0x07, 0xe4, 0xe0
	extz xbc
	ld xwa, (xsp + 4)
	ld (xwa + 2), xbc
	incm 1, (xiz)
	lds hl, 0
	jr FileIO_ReadDirEntry_Return

FileIO_ReadDirEntry_End:
	ldw hl, 0xffff

FileIO_ReadDirEntry_Return:
	pop xiz
	inc 4, xsp
	ret

SndTable_ByteBlock_ReadOps:
	.byte 0xc2
	or	xhl, xix
	pop_sr
	push	xsp
	nop
	jr	nz, 48
	ld32_24	xbc, 0x2357a
	push	xbc
	pushw	1024
	pushw	1
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cps	hl, 0
	jr	lt, 3
	lds	hl, 0
	ret
	ld32_24	xwa, 0x2357a
	ld	wa, (xwa+6)
	and	wa, 0x7fff
	jr	nz, 3
	lds	hl, 0
	ret
	ldw	hl, 0xffff
	ret
	.byte 0xc2
	or	xhl, xix
	pop_sr
	push	xsp
	.byte 0x01
	jr	nz, 6
	calr	759
	extz	hl
	ret
	ldw	hl, 0xffff
	ret
	dec	2, xsp
	push	xiz
	sti8_24	0x2357e, 1
	ld32_24	xwa, 0x3e3e8
	st32_24	0x2272e, xwa
	ld32_24	xwa, 0x3e3ee
	ldw	(xwa+2), 0
	ld32_24	xwa, 0x3e3ee
	.byte 0xf3, 0xe1
	ei	4
	push_sr
	nop
	nop
	ld32_24	xbc, 0x3e3ee
	lds	wa, 2
	call	TaskMsg_Send
	ld32_24	xwa, 0x3e3ee
	lda	xwa, (xwa+1028)
	ld	xbc, xwa
	lds	wa, 2
	call	TaskMsg_Send
	.byte 0xbf, 0x04
	push_sr
	nop
	nop
	ld	wa, (xsp+4)
	extz	xwa
	.byte 0xe2
	pushw	iz
	ldb	l, 2
	.byte 0xf0
	jrl	ugt, 134
	lds	wa, 2
	call	TaskMsg_Receive
	ld	xiz, xhl
	.byte 0x9e
	push_sr
	push	xsp
	nop
	nop
	jr	z, 17
	.byte 0xbe
	push_sr
	push_sr
	swi	6
	swi	7
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	jr	102
	lda	xwa, (xiz+4)
	calr	65336
	cps	hl, 0
	jr	z, 21
	.byte 0xb6
	push_sr
	nop
	nop
	.byte 0xbe
	push_sr
	push_sr
	swi	6
	swi	7
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	jr	71
	.byte 0xb6
	push_sr
	nop
	.byte 0x04
	ld	wa, (xsp+4)
	extz	xwa
	ld32_24	xbc, 0x2272e
	sub	xbc, xwa
	cp	xbc, 1024
	jr	ugt, 14
	ld	wa, (xsp+4)
	extz	xwa
	ld32_24	xbc, 0x2272e
	sub	xbc, xwa
	ld	(xiz), bc
	.byte 0xbe
	push_sr
	push_sr
	nop
	nop
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	.byte 0x9f, 0x04
	push	xwa
	nop
	.byte 0x04
	ld	wa, (xsp+4)
	extz	xwa
	.byte 0xe2
	pushw	iz
	ldb	l, 2
	.byte 0xf0
	jrl	ule, -134
	sti8_24	0x2357e, 0
	call	Show_ScreenGroup_Entry_0x7A
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
	cpdi16_24 0x23580, 0
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
	cpdi16_24 0x23580, 0
	jr nz, TaskBuf_ReadAndDecrement
	sti8_24 0x02358a, 0x02
	ldw hl, 0xffff
	jr TaskBuf_PopIzRet

TaskBuf_ReadAndDecrement:
	ld32_24 xbc, 0x023586
	lds32 xwa, 1
	addm32_24 0x023586, xwa
	ld a, (xbc)
	ldfr_berp A, 0xf8
	extz iz
	subdi16_24 0x23580, 1
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
	ldw hl, 0xffff

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
	ldw (xwa + 2), 0xffff
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
	pushw 0xe4
	pushw 0x5132
	push xwa
	call FileOpen
	inc 8, xsp
	st32_24 0x02357a, xhl
	ld32_24 xwa, 0x02357a
	or xwa, xwa
	jr nz, SndTable_LookupA_GotFile
	sti8_24 0x02358a, 0x02
	ldw hl, 0xffff
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
	ldto_werp HL, 0xee
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
	ld16_24	wa, 0x2358c
	ld	xbc, xiz
	calr	65445
	incdi16_24	1, 0x2358c
	cps	hl, 0
	jr	nz, 22
	ld16_24	de, 0x2358c
	lda	xwa, (xiz+512)
	ld	xbc, xwa
	ld	wa, de
	calr	65419
	incdi16_24	1, 0x2358c
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
	muls bc, 0x2c
	lda_24 xde, 0x0235a8
	ld_sriw3 BC, 0x07, 0xe8, 0xe4
	st16_24 0x02358c, xbc
	muls wa, 0x2c
	lda_24 xbc, 0x0235a6
	ld_sriw3 WA, 0x07, 0xe4, 0xe0
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
	ldw hl, 0xffff
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
	cp hl, 0xfc
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
	cp hl, 0xfc
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
	pushw 0xb	; 11 bytes
	pushw 0xe4
	pushw 0x5136	; "1 PianoDisc"
	lda_24 xwa, 0x02434e
	push xwa
	call String_Compare
	add xsp, 0xa
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
	ldw (xsp + 6), 0xe0
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
	add wa, 0xa
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
	ldfr_werp HL, 0xfa
	calr FDC_RecalibrateCommand
	cpi_werp 0xfa, 0
	jr z, FileIO_ReadDir_NextSector
	ldto_werp HL, 0xfa
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
	muls wa, 0x2c
	lda_24 xbc, 0x0235a8
	cp_sriw_im 0x07, 0xe4, 0xe0, 0xfe, 0xfe
	jr z, FileIO_FillRemainingEntries
	pushw 0x14
	ld wa, iz
	muls wa, 0x2c
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
	ldto_werp HL, 0xfa

FileIO_ReadDir_Return:
	pop xiz
	ret

SeqByteBlock_DispatchJumpTable:
	.byte 0xb2, 0x32, 0xf5, 0x00, 0xb1, 0x32, 0xf5, 0x00
	.byte 0xbb, 0x32, 0xf5, 0x00, 0xb1, 0x32, 0xf5, 0x00

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
	anddi8 0x32f3, 254
	ret

SeqDispatch_TrampolineBlock:
	jp	0xf532dc
	ret
	jp	0xf532dd
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
	jp	Rhythm_TailPadding

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
	jp	0xf55be9

Seq_DispatcherTick:
	cpdi8 0x8d36, 16
	jr c, Seq_DispatcherTick_Process
	cpdi8 0x8d36, 22
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
	anddi8 0x32f4, 159
	call AccTick_Main
	ldda8 a, 0x32f4
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
	ldda8 a, 0xfc5a
	stda8 0x32f5, a
	ldda8 a, 0xfc5b
	and a, 0x7f
	and a, 0x7
	stda8 0x32f7, a
	calr VoiceParam_ClampAndStore
	nop
	nop
	nop
	nop
	ldda8 a, 0xfc5d
	or a, 0xe0
	srl a, 5
	stda8 0x32f9, a
	ldda8 w, 0xfc5f
	xor a, a
	bit 6, w
	jr z, SeqCtl_CheckBit6
	or a, 0x1

SeqCtl_CheckBit6:
	bit 7, w
	jr z, SeqCtl_CheckBit7
	or a, 0x2

SeqCtl_CheckBit7:
	stda8 0x32fb, a
	xor a, a
	bit 4, w
	jr z, SeqCtl_CheckBit4
	or a, 0x1

SeqCtl_CheckBit4:
	bit 5, w
	jr z, SeqCtl_CheckBit5
	or a, 0x2

SeqCtl_CheckBit5:
	stda8 0x32fd, a
	xor a, a
	bit 2, w
	jr z, SeqCtl_CheckBit2
	or a, 0x1

SeqCtl_CheckBit2:
	bit 3, w
	jr z, SeqCtl_CheckBit3
	or a, 0x2

SeqCtl_CheckBit3:
	ldda8 w, 0xfc60
	bit 2, w
	jr z, SeqCtl_StorePedalFlags
	or a, 0x4

SeqCtl_StorePedalFlags:
	stda8 0x32ff, a
	ldda8 a, 0xfd99
	and a, 0x1
	stda8 0x3301, a
	ldda8 a, 0xfc5e
	and a, 0x10
	srl a, 4
	ldb a, 0x0
	stda8 0x3303, a
	ldda8 a, 0xfc61
	and a, 0x30
	srl a, 4
	stda8 0x3305, a
	xor a, a
	bitda 2, 0xfdad
	jr nz, SeqCtl_StoreKeyMask
	or a, 0x3f

SeqCtl_StoreKeyMask:
	stda8 0x3307, a
	ret

VoiceParam_ClampAndStore:
	ldda8 l, 0x32f5
	ldda8 h, 0x32f7
	calr VoiceParam_ClampAndValidate
	stda8 0x32f5, l
	and h, 0x7f
	and h, 0x7
	stda8 0x32f7, h
	ret

VoiceParam_ClampAndValidate:
	cp l, 0x80
	jr c, VoiceParam_Clamp_LookupTable
	cp l, 0xf0
	jr c, VoiceParam_Clamp_CheckBank
	ldb h, 0x0
	and l, 0xf
	or l, 0x80
	jr TableLoad_Return

VoiceParam_Clamp_CheckBank:
	cps h, 7
	jr ule, VoiceParam_Clamp_CheckRange
	xor h, h

VoiceParam_Clamp_CheckRange:
	cp l, 0x9d
	jr ule, TableLoad_Return
	xor l, l
	jr TableLoad_Return

VoiceParam_Clamp_LookupTable:
	ld xwa, Display_FontPalette_Table_0x1532
	sla l, 1
	and h, 0x7f
	and h, 0x7
	ld_sriw3 HL, 0x07, 0xe0, 0xec

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
	add xhl, Display_FontPalette_Table_0x1DBF
	ld a, (xhl)
	stda16 0x334b, xwa
	ret

Seq_ProcessAllInputState:
	ldda8 a, 0x3283
	and a, 0xfe
	bitda 2, 1054
	jr z, Seq_InputState_StoreFlag
	or a, 0x1

Seq_InputState_StoreFlag:
	stda8 0x3283, a
	calr AccKey_ScanAndSetDirty
	calr AccState_ReadAccompParams
	calr AudioMode_CheckAndUpdateStereo
	calr AccChord_ReadAndStoreKeys
	calr AudioMode_MergeOutputBits
	calr AudioMode_CopyChannelMode
	calr AudioMode_CopyAccentFlags
	calr AccPedal_SetFlag13155
	xor xhl, xhl
	ldda8 l, 0x3280
	sla l, 1
	add xhl, Display_FontPalette_Table_0x1D46
	ld bc, (xhl)
	xor hl, hl
	ldda8 l, 0x327f
	add bc, hl
	stda16 0x327d, xbc
	stdi8 0x32e9, 24
	bitda 0, 0x3283
	jr z, AccInput_CheckRecordMode
	call AccTuning_DisableIfNoStyle
	bitda 0, 0x3363
	jr nz, AccInput_ProcessWithPedal
	calr AccPedal_ProcessAllChanges

AccInput_ProcessWithPedal:
	calr AccChannel_CompareAndMarkDirty
	calr AccVoice_ProcessPedalChanges
	calr AccVoice_ProcessLeftPedalChanges
	calr AccPitch_CheckTransposeFlags
	calr AccChord_ProcessKeyChanges
	bitda 0, 0x3363
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
	anddi8 0x3284, 253
	ldb a, 0x1
	ld xhl, 0xf1a0
	xor c, c

AccKey_ScanLoop:
	cp c, 0x10
	jr z, AccKey_ScanDone
	cp (xhl), 0xd
	jr z, AccKey_FoundActiveKey
	sla wa, 1
	inc 1, xhl
	inc 1, c
	jr AccKey_ScanLoop

AccKey_FoundActiveKey:
	andda16 xwa, 0xf19e
	jr z, AccKey_ScanDone
	ordi8 0x3284, 2

AccKey_ScanDone:
	pop xbc
	ret

AccChord_ReadAndStoreKeys:
	ldda8 a, 0xcee0
	stda8 0x32d9, a
	ldda8 a, 0xcedf
	stda8 0x32d8, a
	ldda8 a, 0xcee1
	stda8 0x32da, a
	ldda8 a, 0xcede
	stda8 0x32d7, a
	cpdi8 8968, 0
	jr z, AccChord_CheckKeyOverride
	ldda8 a, 8962
	stda8 0x32d9, a
	ldda8 a, 8960
	stda8 0x32d8, a
	ldda8 a, 8964
	stda8 0x32da, a
	ldda8 a, 8966
	stda8 0x32d7, a

AccChord_CheckKeyOverride:
	bitda 1, 0x32d7
	jr nz, AccChord_CheckUIState
	ldda8 a, 0x32d9
	stda8 0x32da, a

AccChord_CheckUIState:
	cpdi8 0x8d34, 14
	jr nz, AccChord_CheckUIStateExit
	cpdi8 0x8d36, 177
	jr z, AccChord_CheckKeyFlags
	cpdi8 0x8d36, 176
	jr nz, AccChord_SetDefaultKeys

AccChord_CheckKeyFlags:
	ldda8 a, 1054
	and a, 0x18
	jr nz, AccChord_CheckUIStateExit

AccChord_SetDefaultKeys:
	stdi8 0x32d7, 0
	stdi8 0x32d8, 1
	stdi8 0x8d42, 1
	bitda 4, 0x34ea
	jr z, AccChord_ReadChannelKeys
	stdi8 0x32d8, 5
	stdi8 0x8d42, 5

AccChord_ReadChannelKeys:
	ldda8 a, 0x34e9
	and a, 0xf
	inc 1, a
	stda8 0x32d9, a
	stda8 0x8d40, a
	stda8 0x32da, a

AccChord_CheckUIStateExit:
	cpdi8 0x8d34, 14
	jr z, AccChord_CheckModeAndUpdate
	cpdi8 0x32f1, 14
	jr nz, AccChord_CheckModeAndUpdate
	ldda8 a, 0xcedf
	stda8 0x8d42, a
	ldda8 a, 0xcee0
	stda8 0x8d40, a
	calr AccDisplay_RefreshIfDiskActive

AccChord_CheckModeAndUpdate:
	ldda8 a, 0x3314
	orda8 a, 0x3315
	and a, 0x3f
	jrl z, AccChord_ReadKeysRet
	ldda8 a, 0x32d8
	cps a, 0
	jr nz, AccChord_ReadKeysRet
	ldda8 a, 0x32dc
	cpda8 a, 0x32d8
	jr z, AccChord_ReadKeysRet
	stda8 0x32d8, a
	stda8 0xcedf, a
	stda8 0x8d42, a
	stda8 8960, a
	ldda8 a, 0x32dd
	stda8 0x32d9, a
	stda8 0xcee0, a
	stda8 0x8d40, a
	stda8 8962, a
	ldda8 a, 0x32de
	stda8 0x32da, a
	stda8 0xcee1, a
	stda8 0x8d44, a
	stda8 8964, a
	cpda8 a, 0x32dd
	jr nz, AccChord_CompareNoteC
	stdi8 0x8d44, 0

AccChord_CompareNoteC:
	ldda8 a, 0x32db
	stda8 0x32d7, a
	stda8 0xcede, a
	stda8 8966, a
	call Voice_InitSlotData
	call Voice_FindAndAllocBestMatch
	ldda8 a, 0xfc5d
	and a, 0x7
	cps a, 0
	jr z, AccChord_ReadKeysRet
	bitda 1, 0x3284
	jr z, AccChord_ReadKeysRet
	call BitMapOut_CheckDiskAndApply
	jr AccChord_ReadKeysRet

AccChord_ReadKeysRet:
	ret

AccDisplay_RefreshIfDiskActive:
	push xwa
	ldda8 a, 0xfc5d
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
	stda8 0x3280, a
	ldda8 a, 1076
	stda8 0x32b4, a
	ldda8 a, 1077
	stda8 0x32b3, a
	ldda8 a, 1045
