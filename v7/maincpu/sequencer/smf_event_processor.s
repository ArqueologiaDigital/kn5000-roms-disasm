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
	ld xiz, (4349:16)
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
	ld (0x287a:16), 5
	jr ToneGen_DispatchReturn

ToneGen_StoreBlockAndLink:
	ld xhl, (4349:16)
	ld (xhl + 3), ix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ld wa, (3308:16)
	ld xhl, (4349:16)
	ld (xhl + 1), wa
	ldw (xhl + 3), 0xffff
	ld (3308:16), ix
	lds ix, 5

ToneGen_DispatchReturn:
	ret

ToneGen_DispatchAndLinkBlock:
	push xix
	push xiy
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld (xhl + 3), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld bc, (0x28af:16)
	ld (xhl + 1), bc
	ldw (xhl + 3), 0xffff
	ld (0x28af:16), wa
	stdi16 (9830), 5
	pop xiy
	pop xix
	ret

VoiceChannel_GetCombinedStatus:
	cp (4012:16), 6
	jr z, VoiceChannel_GetStatusBank2First
	push xix
	ld xix, 0x10d3
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix
	ld l, a
	push xix
	ld xix, 0x10c3
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	jr VoiceChannel_CombineStatusBits

VoiceChannel_GetStatusBank2First:
	push xix
	ld xix, 0x10c3
	stb_dri A, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	ldb_sri L, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_CombineStatusBits:
	rlc_i_8 l, 2
	and l, 0x1
	sla a, 1
	or a, l
	ret

VoiceChannel_LookupParams:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ldb_sri L, 0x07, 0xf0, 0xf4
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
	ldb_sri A, 0x07, 0xec, 0xf4
	ld (4234:16), a
	call SoundGen_PrepareAndBuildVoice

VoiceChannel_LookupReturn:
	ret

VoiceChannel_SetPanDirection:
	call VoiceChannel_GetParamBlock
	ld w, (xiy + 4)
	and w, 0xf7
	xor a, a
	cp (4013:16), 64
	jr c, VoiceChannel_MergePanBit
	or a, 0x8

VoiceChannel_MergePanBit:
	or w, a
	or w, 0x10
	ld (xiy + 4), w
	ret

VoiceChannel_UpdateWithPitch:
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xb0
	bitda 7, (4235)
	jr z, VoiceChannel_ApplyPitchFlags
	or a, 0x2
	bitda 7, (4234)
	jr z, VoiceChannel_ApplyPitchFlags
	or a, 0x1

VoiceChannel_ApplyPitchFlags:
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceChannel_NullRet
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceChannel_NullRet
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	cp (4600:16), 1
	jr z, VoiceChannel_SelectChannelBank
	ld xix, SeqTrack_ChannelMapIdentity_0x10

VoiceChannel_SelectChannelBank:
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet
	ld a, (4233:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet
	ld a, (4234:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet
	ld a, (4235:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0

VoiceChannel_NullRet:
	ret

SoundGen_ClampUpdateVoice:
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ldb a, 0xb0
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	sla iy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	ld a, (4011:16)
	and a, 0xf
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	ld a, (4233:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	ld a, (4234:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	ld a, (4235:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jr nz, VoiceChannel_NullRet2
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	ld (4323:16), 0

VoiceChannel_NullRet2:
	ret

VoiceChannel_SetParamByte7:
	call VoiceChannel_GetParamBlock
	ld a, (4013:16)
	ld w, (xiy + 7)
	and w, 0x80
	or w, a
	ld (xiy + 7), w
	ret

VoiceChannel_MergeParamByte5:
	call VoiceChannel_GetParamBlock
	ld a, (4013:16)
	ld w, (xiy + 5)
	and w, 0x80
	or w, a
	ld (xiy + 5), w
	ret

SoundGen_LookupChannelBankParams:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x1093
	ldb_sri A, 0x07, 0xf0, 0xf4
	ld xix, 0x10a3
	ldb_sri W, 0x07, 0xf0, 0xf4
	pop xix
	cps a, 0
	jr nz, ToneGen_StoreBadValue
	cps w, 0
	jr c, ToneGen_StoreBadValue
	cps w, 2
	jr ugt, ToneGen_StoreBadValue
	push xix
	ld xix, 0x10b3
	stb_dri W, 0x07, 0xf0, 0xf4
	pop xix
	jr SoundGen_LookupReturn

ToneGen_StoreBadValue:
	ldb a, 0xff
	push xix
	ld xix, 0x10b3
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix

SoundGen_LookupReturn:
	ret

VoiceChannel_GetParamBlock:
	xor h, h
	ld l, (4011:16)
	and l, 0xf
	sla hl, 2
	cp (4600:16), 1
	jr nz, VoiceChannel_GetParamBlockAlt
	push xix
	ld xix, VoiceChannel_ParamTable1
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	jr VoiceChannel_StoreParamPtr

VoiceChannel_GetParamBlockAlt:
	push xix
	ld xix, VoiceChannel_ParamTable1_0x40
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
	push	sr
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
	push	sr
	.byte 0xf6
	nop
	nop
	.byte 0x80, 0xf5
	nop
	nop
	call	VoiceChannel_GetParamBlock
	ld	a, (4013:16)
	ld	(xiy+3), a
	ret

SoundGen_PrepareAndBuildVoice:
	push xiy
	cpdi16 3932, 0
	jr z, SoundGen_CaptureAndBuildParams
	cpdi16 3934, 2
	jr c, SoundGen_CaptureAndBuildParams
	ld iy, (4237:16)
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
	bitda 7, (4234)
	jr z, SoundGen_UpdateAndWriteChannel
	or a, 0x1

SoundGen_UpdateAndWriteChannel:
	push xiy
	pushw bc
	call SoundGen_UpdateAndRefresh
	popw bc
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	pushw bc
	push xiy
	call SoundGen_ScalePitchByTempo
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	ld l, c
	xor h, h
	ld l, (4011:16)
	and l, 0xf
	xor h, h
	cpdi16 3932, 0
	jr z, SoundGen_SelectChannelTable
	cpdi16 3934, 2
	jr c, SoundGen_SelectChannelTable
	ld a, l
	jr SoundGen_ApplyChannelParam

SoundGen_SelectChannelTable:
	ld xix, SeqTrack_ChannelMapIdentity_0x10
	cp (4600:16), 1
	jr nz, SoundGen_SelectAltChannelTable
	ld xix, SeqTrack_ChannelMapIdentity

SoundGen_SelectAltChannelTable:
	ldb_sri A, 0x07, 0xf0, 0xec

SoundGen_ApplyChannelParam:
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	pop xiy
	push xiy
	push xde
	ld xde, SoundGen_VoiceParamData
	ldb_sri A, 0x03, 0xe8, 0xe4
	pop xde
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	ld a, (4234:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	ldb a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	call ToneGen_SetSustainBit
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	cpdi16 3932, 0
	jr z, SoundGen_CommitChannelRegs
	cpdi16 3934, 2
	jr c, SoundGen_CommitChannelRegs
	ld iy, (4237:16)
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_CommitChannelRegs:
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0

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
	ld (6749:16), 176
	ld (6750:16), 154
	bitda 7, (6750)
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
	ld a, (6749:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ldb a, 0x0
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ld a, (6750:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ld xde, SoundGen_InitVoiceData
	ldb_sri A, 0x07, 0xe8, 0xf4
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
	max
	halt
	.byte 0x06

SndParam_LookupChannelVoice:
	push XHL
	cp (0x11f8:16), 0x02
	jr nz, SndParam_LookupDefault
	ld a, (0x0fab:16)
	and A,0x0f
	cp A,0x09
	jr nz, SndParam_LookupDefault
	push XIX
	push XBC
	push XDE
	xor XHL,XHL
	ld L,A
	mul L,0x02
	xor XWA,XWA
	xor XBC,XBC
	xor XDE,XDE
	ld XIX,0x00001a37
	ldb A, 0x04
	ldw_dri bc, 0x07, 0xf0, 0xec
	ld E,B
	xor HL,HL
	ld l, (0x0fac:16)
	pushw hl
	call 0xfee2f8
	ld A,L
	pop XDE
	pop XBC
	pop XIX
	cp A,0xff
	jr z, SndParam_LookupReturn
SndParam_LookupDefault:
	ldb a, 0x0

SndParam_LookupReturn:
	pop xhl
	ret

VoiceChannel_StoreVoiceIdx:
	push XDE
	xor DE,DE
	ld e, (0x0fab:16)
	and E,0x0f
	ld (0x1a5f:16), de
	pop XDE
	cpdi16 (0x1a5f), 0x0009
	jr nz, VoiceChannel_StoreVoiceReturn
	ld XWA,0x00001a57
	call 0xfee195
	ld XHL,0x00001a37
	ld bc, (0x1a5f:16)
	mul C,0x02
	add XHL,XBC
	ld a, (0x1a5a:16)
	ld (XHL),A
	ld a, (0x1a5b:16)
	ld (XHL+0x01),A
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
	ld xwa, (6701:16)
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
	cp (0x11f8:16), 0x01
	jr z, Seq_AdvanceBlock
	ldb A, 0x7f
	ld BC,IX
	sub A,C
	sub A,0x01
	cpdi16 (0x1074), 0x0000
	jr nz, Seq_AdvanceBlock
	.byte 0xc1, 0x73, 0x10, 0xf9, 0x6b, 0x25, 0xdc, 0x89
	.byte 0xed, 0x8c, 0x45, 0x6e, 0x10, 0x00, 0x00, 0x85
	.byte 0x11, 0x1d, 0x53, 0x6f, 0xf2, 0xc1, 0xe0, 0x1a
	.byte 0x3f, 0xff, 0x66, 0x13, 0x40, 0x61, 0x1a, 0x00
	.byte 0x00, 0xe9, 0xa8, 0x1d, 0x25, 0xa6, 0xfd, 0x1b
	.byte 0x52, 0x6f, 0xf2
Seq_AdvanceBlock:
	call Sequencer_AdvanceBlockPosition

Seq_ReturnToDispatcher:
	ret

SysEx_ReadBytesLoop_Init:
	ld (6880:16), 0

SysEx_ReadBytesLoop:
	cp (4211:16), 0
	jr ule, SysEx_ReadBytesReturn
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld (6880:16), 255

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
	ld (4599:16), a
	ld (6709:16), c
	ld (6710:16), e
	push xiz
	push xix
	push xde
	call SetWall_LoadBankToToneGen
	ld a, (4599:16)
	cpda8_24 a, (0xffe3)
	jr z, SMF_LoadBank_ClearAndPrepare
	ld a, (4599:16)
	stb_da (0x00ffe3), a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay

SMF_LoadBank_ClearAndPrepare:
	call SMF_ClearFileBuffer
	call SMF_InitPlaybackState
	pop xde
	pop xix
	pop xiz
	ld hl, (6699:16)
	bit 15, hl
	jr nz, SMF_SeekAndPreparePlayback
	cps hl, 2
	jr z, SMF_SeekAndPreparePlayback
	set 15, hl

SMF_SeekAndPreparePlayback:
	.byte 0xdb, 0x33, 0x0f, 0x6e, 0x3a, 0xc1, 0xec, 0x8c
	.byte 0x3c, 0xfe, 0x1d, 0xef, 0x8d, 0xf2, 0x38, 0x39
	.byte 0xe1, 0x31, 0x1a, 0x21, 0xe9, 0xca, 0xfa, 0x13
	.byte 0x00, 0x00, 0xe9, 0x88, 0xe9, 0xa8, 0x1d, 0xd3
	.byte 0x8a, 0xf8, 0xeb, 0xcf, 0x00, 0x00, 0x00, 0x00
	.byte 0x61, 0x04, 0x1b, 0x20, 0x70, 0xf2
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
	.byte 0xf1, 0xa5, 0x28, 0xc8, 0x66, 0x0f, 0xd2, 0xec
	.byte 0xff, 0x00, 0x20, 0xf1, 0x9e, 0xf1, 0x50, 0x3b
	.byte 0x1d, 0x9e, 0xd6, 0xfd, 0x5b
SMF_SeekReturn:
	ret

SeqPlay_StartWithDisplay:
	call SeqPlay_CheckStartConditions
	cp (0xf23d:16), 255
	jr z, SeqPlay_SetFlagAndMode
	anddi8 (0xfdad), 251
	xor a, a
	jr SeqPlay_QueueDisplayEvent

SeqPlay_SetFlagAndMode:
	ordi8 0xfdad, 4
	ldb a, 0x4

SeqPlay_QueueDisplayEvent:
	ld	(4330:16), 1
	ldb	e, 145
	ldb	d, 3
	ldb	w, 4
	call	16624640
	call	15668398
	call	16625070
	ret
SMF_InitPlaybackState:
	pushw wa
	cpdi16 0xf19c, 0
	jr z, SMF_InitChannelState
	stdi16 (6699), 9
	jrl SMF_PopReturn

SMF_InitChannelState:
	xor wa, wa
	ld (4236:16), a
	ld (4347:16), wa
	ld (4344:16), a
	cpw_da (0xffec), 0
	jr z, SMF_SetStatusAndJump
	xor c, c

SMF_ScanChannelLoop:
	ldw_da xde, (0x00ffec)
	ld a, c
	scf
	xorcf_a_16 de
	jr c, SMF_LoopNextChannel
	ld l, c
	xor h, h
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x10
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
	stdi16 (6699), 47
	jrl SMF_Finalize_PopReturn

SMF_FoundActiveChannel:
	call Vga_SetupMultiPlaneDisplay
	ldw_da xwa, (0x00ffec)
	ld (4325:16), wa
	ld (4324:16), 255
	bitda 2, (0xfdad)
	jr nz, SMF_InitChannelScan
	ld (4324:16), 0

SMF_InitChannelScan:
	call SMF_ScanChannels
	call SMF_CountActiveChannels
	call SMF_ClearWorkArea
	call SMF_ClearWorkArea
	xor wa, wa
	ld (4347:16), wa
	ld (4236:16), a
	ld (4344:16), a
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
	stdi16 (6699), 3
	jrl SMF_Finalize_RestoreAndPlay

SMF_SetupActiveChannel:
	ld (0x2877:16), c
	inc 1, hl
	push xde
	ld xde, 0xf250
	ldw_sri HL, 0x07, 0xe8, 0xec
	pop xde
	ld (0x28af:16), hl
	stdi16 (9830), 5
	ld xiy, SMF_HeaderConstants_0x4
	ld xix, 0x13fa
	lds bc, 7
	ldirw
	ld xiy, SMF_HeaderConstants_0x12
	lds bc, 4
	ldir85
	xor wa, wa
	ld (4002:16), wa
	ld (4004:16), wa
	stda32 6705, xix
	ld wa, (4002:16)
	stw_dpi WA, 0xf1
	ld wa, (4004:16)
	stw_dpi WA, 0xf1
	stda32 4376, xix
	ld xix, (4376:16)
	ld xiy, SMF_HeaderConstants
	lds bc, 4
	ldir85
	ld xiy, 0xf280
	ldw bc, 0x10
	ldir85
	stda32 4376, xix
	stdi16 (4206), 0
	ld (4208:16), 0
	ld xiy, 0x106e
	ld xix, (4376:16)

SMF_WaitForReady:
	ldb_spi A, 0xf4
	lda_dpi XBC, 0xf0
	bit 7, a
	jr nz, SMF_WaitForReady
	ldw wa, 0x58ff
	stw_dpi WA, 0xf1
	ldb a, 0x4
	ld w, (1075:16)
	stw_dpi WA, 0xf1
	ldw wa, 0x1802
	stw_dpi WA, 0xf1
	ldb a, 0x8
	lda_dpi XBC, 0xf0
	stda32 4376, xix
	ld l, (0xfc62:16)
	xor h, h
	pushw bc
	ld b, (0xfc63:16)
	and b, 0x1
	xor c, c
	or hl, bc
	popw bc
	call SMF_CalcTempoRate
	call SMF_OutputCommandSeq
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xiy, SMF_HeaderConstants_0x42
	cp (4324:16), 0
	jr nz, SMF_Setup_SelectTablePtr
	ld xiy, SMF_HeaderConstants_0x4A

SMF_Setup_SelectTablePtr:
	ld xix, (4376:16)
	ldw bc, 0x8

SMF_WriteChannelDataLoop:
	ldb_spi A, 0xf4
	lda_dpi XBC, 0xf0
	pushw bc
	push xiy
	push xix
	call SMF_WriteByte
	pop xix
	pop xiy
	popw bc
	ld xix, (4376:16)
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	djnz16 bc, -46

	stda32 4376, xix

	cp (6709:16), 0

	jrl z, 1309

	call 16625030

	ld (0x2877:16), 0



SMF_ScanAndProcessChannel:
	ld xiy, 0xf460
	xor hl, hl
	ld l, (0x2877:16)
	ld c, l
	ld de, (4325:16)
	ld a, c
	scf
	xorcf_a_16 de
	jrl c, SMF_AdvanceChannelScan
	push xix
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	pop xix
	ld b, l
	sla l, 1
	push xix
	ld xix, SMF_HeaderConstants_0x1A
	ldw_sri HL, 0x07, 0xf0, 0xec
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
	lda_rr	xiy, xiy, hl
	ld	c, (xiy+256)
	ld	d, (xiy+1)
	ld	b, (xiy+3)
	ld	e, (xiy+4)
	ld	a, (xiy+5)
	ld	(4359:16), a
	ld	a, (xiy+7)
	ld	(4332:16), a
	.byte 0xc1, 0x77, 0x28, 0x3c, 0x0f
	ld	l, (10359:16)
	xor	h, h
	push	xix
	ld	xix, 61856
	ld_rrb	l, xix, hl
	pop	xix
	cp	(4324:16), 255
	jrl	nz, 172
	call	15896124
	ld	a, (6881:16)
	or	a, 192
	ld	l, c
	ld	(6746:16), l
	ld	(6747:16), d
	ld	l, (xiy-2)
	ld	(6748:16), l
	pushw	bc
	pushw	de
	ld	xwa, 6743
	call	16703738
	popw	de
	popw	bc
	ld	a, (6881:16)
	or	a, 176
	xor	w, w
	ld	l, (6744:16)
	pushw	wa
	pushw	bc
	pushw	de
	call	15893900
	popw	de
	popw	bc
	popw	wa
	push	xwa
	push	xbc
	lds32	xbc, 0
	ld	xwa, (6701:16)
	cp	xwa, xbc
	jr	lt, 6
	pop	xbc
	pop	xwa
	jp	15889252
SMF_WriteNote_FileUnderflow1:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_BankSelect:
	ldb w, 0x20
	ld l, (6743:16)
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld a, (6881:16)
	or a, 0xc0
	ld w, (6745:16)
	and w, 0x7f
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld a, (6881:16)
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
	ld xwa, (6701:16)
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
	ld a, (6881:16)
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
	ld xwa, (6701:16)
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
	ld a, (6881:16)
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
	ld xwa, (6701:16)
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
	ld a, (6881:16)
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
	ld xwa, (6701:16)
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
	ld l, (4359:16)
	pushw wa
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld l, (4332:16)
	and l, 0x7f
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (0x2877:16)
	xor h, h
	push xix
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	pop xix
	cp l, 0xc
	jrl z, SMF_AdvanceChannelScan
	ld b, l
	xor h, h
	sla l, 1
	push xix
	ld xix, SMF_HeaderConstants_0x1A
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	cp hl, 0xffff
	jrl z, SMF_AdvanceChannelScan
	ld a, (6881:16)
	or a, 0xb0
	ld c, l
	ld xiy, 0xf460
	ldfr_lerp XIY, 0x38
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld l, (0x2877:16)
	xor h, h
	push xix
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	sla hl, 1
	ld xix, SMF_HeaderConstants_0x1A
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	lda_dri XIY, 0x07, 0xf4, 0xec
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld l, (0x2877:16)
	xor h, h
	push xix
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	sla l, 1
	ld xix, SMF_HeaderConstants_0x1A
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	ldfr_lerp XIY, 0x38
	lda_dri XIY, 0x07, 0xf4, 0xec
	ld l, (xiy + 9)
	ldto_lerp XIY, 0x38
	ldb w, 0x6
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	ld l, (0x2877:16)
	xor h, h
	push xix
	ld xix, 0xf1a0
	ldb_sri L, 0x07, 0xf0, 0xec
	sla l, 1
	ld xix, SMF_HeaderConstants_0x1A
	ldw_sri HL, 0x07, 0xf0, 0xec
	pop xix
	ld xiy, 0xf460
	lda_dri XIY, 0x07, 0xf4, 0xec
	ld l, (xiy + 11)
	ldb w, 0x6
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	incdi8 1, (0x2877)
	cp (0x2877:16), 15
	jrl ule, SMF_ScanAndProcessChannel

SMF_FinishChannelAndGetNextEvent:
	call SMF_ChannelHelperReturn
	xor wa, wa
	ld (3942:16), wa
	ld (3944:16), wa
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
	ld (3944:16), a

SMF_ResetEventTimers:
	stdi16 (3946), 0
	stdi16 (3938), 0
	stdi16 (3940), 0

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
	stb_dri A, 0x07, 0xe8, 0xec
	pop xde
	push xhl
	call SMF_AdvancePosition
	call SMF_GetNextEvent
	pop xhl
	inc 1, hl
	bit 7, a
	jr z, SMF_EventLoop_ReadDataBytes
	ld a, (4211:16)
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
	incdi16 1, (3946)

SMF_MetaTiming_GetNextLoop:
	call SMF_GetNextEvent
	cp a, 0x81
	jr nz, SMF_MetaTiming_ApplyMultiplier
	incdi16 1, (3946)
	call SMF_AdvancePosition
	jr SMF_MetaTiming_GetNextLoop

SMF_MetaTiming_ApplyMultiplier:
	ld wa, (3946:16)
	ldw de, 0x60
	mul xwa, xde
	stw_erp DE, 0xe2
	adddm16 3938, xwa
	ld (3940:16), de
	stdi16 (3946), 0
	jrl SMF_ProcessEventLoop

SMF_PolyAftertouch_Dispatch:
	cps hl, 3
	jr z, SMF_PolyAftertouch_3Byte_CalcTime
	cps hl, 4
	jrl nz, SMF_ProcessEventLoop
	ld c, (4212:16)
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld hl, (4213:16)
	and l, 0x7f
	and h, 0x1
	rrc h
	and h, 0x80
	or l, h
	xor h, h
	pushw wa
	ld w, (4214:16)
	and w, 0x2
	srl w, 1
	xor a, a
	or hl, wa
	popw wa
	call SMF_CalcTempoRate
	call SMF_OutputCommandSeq
	jrl SMF_ProcessEventLoop

SMF_PolyAftertouch_3Byte_CalcTime:
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4213:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
	ld l, (4214:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	cpib_sri 0x07, 0xf0, 0xec, 0x0f
	pop xix
	jrl z, SMF_ProcessEventLoop
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4213:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld c, (4212:16)
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
	ld c, (4212:16)
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld a, (4211:16)
	ld w, (4213:16)
	ld l, (4214:16)
	call SMF_WriteByteLoop
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	lda_dri XIX, 0x07, 0xf0, 0xec
	ldb a, 0x80
	lda_dpi XBC, 0xf0
	ld a, (4211:16)
	lda_dpi XBC, 0xf0
	ld a, (4213:16)
	lda_dpi XBC, 0xf0
	ld a, (4216:16)
	ldb w, 0x60
	muls8rr a, w
	xor hl, hl
	ld l, (4215:16)
	add wa, hl
	stw_dpi WA, 0xf1
	jrl SMF_ProcessEventLoop

SMF_ProgramChange_Handler:
	cps hl, 6
	jrl nz, SMF_ProcessEventLoop
	cp (4213:16), 127
	jrl z, SMF_ProcessEventLoop
	ld a, (4214:16)
	cps a, 0
	jrl nz, SMF_ProcessEventLoop
	cp (6709:16), 0
	jr z, SMF_ProgramChange_CalcTime
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_ProgramChange_CalcTime:
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	cp (0x10e4:16), 0x00
	jrl z, SMF_ProgramChange_DirectWrite
	ld l, (0x1073:16)
	ld H,L
	and L,0x01
	rrc	l
	ld	a, (4215:16)
	or	l, a
	ld	(6746:16), l
	ld	l, (4211:16)
	and	l, 2
	rrc_i_8	l, 2
	ld	a, (4216:16)
	and	a, 127
	or	a, l
	ld	(6747:16), a
	push	xix
	xor	hl, hl
	ld	l, (4213:16)
	ld	xix, 61856
	ld_rrb	l, xix, hl
	ld	xix, 15893090
	ld_rrb	l, xix, hl
	ld	(6748:16), l
	pop	xix
	ld	xwa, 6743
	call	16703738
	ldb	a, 176
	ld	w, (4213:16)
	or	a, w
	xor	w, w
	ld	l, (6744:16)
	pushw	wa
	call	15893900
	popw	wa
	push	xwa
	push	xbc
	lds32	xbc, 0
	ld	xwa, (6701:16)
	cp	xwa, xbc
	jr	lt, 6
	pop	xbc
	pop	xwa
	jp	15891442
SMF_ProgramChange_WriteBankMSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WriteBankMSB_Data:
	stdi16 (4206), 0
	ld (4208:16), 0
	ldb w, 0x20
	ld l, (6743:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, (6745:16)
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4211:16)
	and l, 0x1
	call SMF_SendChannelConfig
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	stdi16 (4206), 0
	ld (4208:16), 0
	ldb w, 0x20
	ld h, (4211:16)
	and h, 0xc
	ld l, (4214:16)
	srl l, 5
	and l, 0x3
	or l, h
	sla l, 4
	and l, 0x7f
	ld l, (4216:16)
	and l, 0x7
	sla l, 4
	call SMF_SendChannelConfig
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, (4215:16)
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	cp (4213:16), 127
	jrl z, SMF_ProcessEventLoop_Entry
	ld l, (4214:16)
	ld a, (4213:16)
	jrl SMF_ControlChange_ValidateRange
	ld l, (4214:16)
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
	ld w, (4213:16)
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
	cp (6709:16), 0
	jrl z, SMF_CC_RPN_CalcTime
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_RPN_CalcTime:
	ld c, (4212:16)
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
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
	ld xwa, (6701:16)
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
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4215:16)
	ld h, (4211:16)
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
	ld xwa, (6701:16)
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
	ld l, (4215:16)
	and l, 0x1
	rrc_i_8 l, 2
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	cp (6709:16), 0
	jrl z, SMF_CC_PitchBendSens_CalcTime
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_PitchBendSens_CalcTime:
	ld c, (4212:16)
	pushw wa
	pushw hl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw hl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
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
	ld xwa, (6701:16)
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
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4215:16)
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	cp (6709:16), 0
	jrl z, SMF_CC_Modulation_CalcTime
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Modulation_CalcTime:
	ld c, (4212:16)
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
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
	ld xwa, (6701:16)
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
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld l, (4215:16)
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld xwa, (6701:16)
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
	cp (6709:16), 0
	jr z, SMF_CC_Pan_CalcTime
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Pan_CalcTime:
	ld c, (4212:16)
	pushw wa
	push xhl
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	pop xhl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ldb w, 0xa
	ld l, (4215:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ld xwa, (6701:16)
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
	ld bc, (4215:16)
	bit 3, b
	jr nz, SMF_CC_Sustain_CheckBits
	jrl SMF_ProcessEventLoop

SMF_CC_Reverb_Handler:
	cp (6709:16), 0
	jr z, SMF_CC_Reverb_SetupCC93
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Reverb_SetupCC93:
	ldb w, 0x5d
	ld l, (4215:16)
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Sustain_CheckBits:
	ld bc, (4215:16)
	bit 3, b
	jrl z, SMF_ProcessEventLoop
	cp (6709:16), 0
	jr z, SMF_CC_Sustain_SetCC64Value
	bitda 0, (4236)
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
	cp (6709:16), 0
	jr z, SMF_CC_Chorus_SetupCC91
	bitda 0, (4236)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Chorus_SetupCC91:
	ld l, (4215:16)
	and l, 0x7f
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Volume_Handler:
	cp (6709:16), 0
	jr z, SMF_ProcessTimedEvent_Entry
	bitda 0, (4236)
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
	lda xwa, (FileClose:24)
	stl_da (0x0210f6), xwa
	ld (xsp + 4), 0x4
	cp (xbc), 0x0
	jr z, FileOpen_AllocBuffer

FileOpen_ParseModeLoop:
	ldb_spi A, 0xe4
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
	ld	xwa, (xsp+24)
	push	xwa
	call	16713667
	inc	1, hl
	pushw	hl
	calr	65347
	inc	6, xsp
	ld	(xsp+12), xhl
	or	xhl, xhl
	jr	nz, 5
	lds32	xhl, 0
	jrl	570
FileOpen_CopyFilename:
	ld	xwa, (xsp+24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713584
	inc	8, xsp
	ld	xwa, (xsp+12)
	ld	(xsp+16), xwa
FileOpen_NormalizeName:
	ld xde, (xsp + 16)
	ld xwa, xde
	ld a, (xwa)
	extz wa
	lda xbc, (CharMap_FullPermutation_0x660:24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	bit 1, a
	jr z, FileOpen_NormalizeNoUpper
	ld xwa, (xsp + 16)
	ld a, (xwa)
	exts wa
	sub wa, 0x20
	jr FileOpen_StoreNormChar

FileOpen_ScanForColon:
	ld xwa, (xsp + 16)
	ldb_spi C, 0xe0
	ld (xsp + 16), xwa
	cp c, 0x3a
	jr nz, FileOpen_NormalizeName
	lds32 xwa, 1
	sub (xsp + 16), xwa
	ld xwa, (xsp + 16)
	stib_dsp 0xe0, 0x00
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
	ld	xwa, (xsp+16)
	push	xwa
	call	16713667
	ld	iz, hl
	extz	xiz
	ld	xwa, (xsp+28)
	push	xwa
	call	16713667
	inc	8, xsp
	ld	wa, hl
	extz	xwa
	ld	xbc, (xsp+24)
	ld	(xsp+16), xbc
	add	(xsp+16), xwa
	sub	(xsp+16), xiz
	ld	(xsp+6), 0
	lda	xwa, (254908:24)
	ld	(xsp+8), xwa
	ld	a, (xsp+6)
	extz	wa
	cpda16_24	xwa, (254942)
	jr	ge, 44	; -> 0xF4E8FC
FileOpen_DeviceSearchLoop:
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+22)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713560
	inc	8, xsp
	cps	hl, 0
	jr	z, 23	; -> 0xF4E8FC
	incm8	1, (xsp+6)
	ld	xwa, 34
	add	(xsp+8), xwa
	ld	a, (xsp+6)
	extz	wa
	cpda16_24	xwa, (254942)
	jr	lt, -44	; -> 0xF4E8D0
FileOpen_DeviceFound:
	ld xwa, (xsp + 12)
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld a, (xsp + 6)
	extz wa
	cpda16_24 xwa, (0x3e3de)
	jr nz, FileOpen_CheckPermission

FileOpen_ErrorNoFile:
	stiw_da (0x01e53c), 0x0007
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
	stiw_da (0x01e53c), 0x0002
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_FindFreeSlot:
	incdi8_24 1, (0x210f4)
	ld (xsp + 14), 0x0
	cp (xsp + 14), 0x10
	jr nc, FileOpen_SlotExhausted

FileOpen_SlotSearchLoop:
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda xbc, (0x0210b4:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	or xwa, xwa
	jr z, FileOpen_SlotExhausted
	incm8 1, (xsp + 14)
	cp (xsp + 14), 0x10
	jr c, FileOpen_SlotSearchLoop

FileOpen_SlotExhausted:
	cp (xsp + 14), 0x10
	jr nz, FileOpen_InitSlot
	stiw_da (0x01e53c), 0x0004
	call SeqStep_FileNopB
	lds32 xhl, 0
	jrl FileOpen_Return

FileOpen_InitSlot:
	ld a, (xsp + 14)
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (0x0210b4:24)
	ld xwa, 0xffffffff
	stl_dri XWA, 0x07, 0xe8, 0xe4
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
	lda xde, (0x0210b4:24)
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xe8, 0xe4
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
	ldb_da a, (0x03e2e2)
	ld (xiz + 1), a
	ld (xiz + 2), 0xd
	ld a, (xsp + 4)
	ld (xiz + 3), a
	ei 7
	ld a, (xsp + 14)
	extz wa
	sla wa, 2
	lda xbc, (0x0210b4:24)
	stl_dri XIZ, 0x07, 0xe4, 0xe0
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
	lda xde, (0x0210b4:24)
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xe8, 0xe4
	ld a, l
	exts wa
	stw_da (0x01e53c), xwa
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
	stiw_da (0x01e53c), 0x0011
	lds hl, 0
	ret

SeqStep_FileReadCheck:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadProcess
	stiw_da (0x01e53c), 0x000d
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
	stiw_da (0x01e53c), 0x0011
	lds hl, 0
	ret

SeqStep_FileReadLoop:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileReadDone
	stiw_da (0x01e53c), 0x000d
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
	stiw_da (0x01e53c), 0x0011
	ldw hl, 0xffff
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadCleanup:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadComplete
	stiw_da (0x01e53c), 0x000d
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
	stiw_da	(0x1e53c), 17
	lds32	xhl, 0
	jr	53
	.byte 0xb9, 0x04
	dec	6, w
	pushw	0x3cf2
	.byte 0xe5, 0x01
	push	sr
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
	stiw_da (0x01e53c), 0x0011
	ldw hl, 0xffff
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteCheckMode:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileWriteProcess
	stiw_da (0x01e53c), 0x000d
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
	stiw_da	(0x1e53c), 17
	ldw	hl, 0xffff
	ret
	.byte 0xb9, 0x04
	dec	6, a
	pushw	0x3cf2
	.byte 0xe5, 0x01
	push	sr
	decf
	nop
	ldw	hl, 0xffff
	ret
	lds	hl, 0
	ld	xwa, (xsp+4)
	cp_spib_im 224, 0
	jr	z, 8
	inc	1, hl
	cp_spib_im 224, 0
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
	lda xbc, (0x0210b4:24)
	cpl_sri_mr XIZ, 0x07, 0xe4, 0xe0
	jr z, SeqStep_FileCloseProcess

SeqStep_FileCloseCheck:
	stiw_da (0x01e53c), 0x0011
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
	stw_da (0x01e53c), xwa

SeqStep_FileCloseReturn:
	incdi8_24 1, (0x210f4)
	ld a, (xiz + 5)
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (0x0210b4:24)
	lds32 xwa, 0
	stl_dri XWA, 0x07, 0xe8, 0xe4
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
	stiw_da (0x01e53c), 0x0026

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
	stiw_da	(0x1e53c), 25
	ldw	hl, 0xffff
	jr	119
	ld qiz, 0
	cpw qiz, 16
	jr	ge, 107
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	or xwa, xwa
	jr	z, 77
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	cp xwa, 4294967295
	jr	z, 53
	ld	xwa, (xsp+4)
	push	xwa
	pushw	1
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	push xwa
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	ld xwa, (xwa+14)
	ld xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	or	iz, hl
	inc 1, qiz
	cpw qiz, 16
	jr	lt, -107
	ld	hl, iz
	pop	xiz
	inc	4, xsp
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	nz, 11
	stiw_da	(0x1e53c), 17
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
	ldw (xwa+6), 0
	ret

SeqStep_FileNopA:
	ret

SeqStep_FileNopB:
	ret

SeqStep_FreeMemory:
	ld	xwa, (xsp+4)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	ret
SeqStep_MallocWrapper:
	ld	xwa, (xsp+6)
	pushw	wa
	call	16713379
	inc	2, xsp
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
	ldw_da	wa, (0x1e53c)
	ld	(xsp+4), wa
	stiw_da	(0x1e53c), 0
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
	stiw_da	(0x1e53c), 21
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
	stw_da	(0x1e53c), wa
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
	stiw_da	(0x1e53c), 17
	ldw	hl, 17
	ret
	ld	xwa, (xde+18)
	.byte 0x80
	push	xsp
	normal
	jr	nz, 11
	ld	xbc, (xsp+8)
	ld	xwa, (xde+22)
	ld	(xbc), xwa
	lds	hl, 0
	ret
	stiw_da	(0x1e53c), 18
	ldw	hl, 18
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, 6
	.byte 0x89, 0x04
	push	xsp
	nop
	jr	nz, 11
	stiw_da	(0x1e53c), 17
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
	stw_da	(0x1e53c), wa
	ret

SeqStep_FileSeekSetup:
	ld xde, (xsp + 8)
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekNoHandle
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekProcess

SeqStep_FileSeekNoHandle:
	stiw_da (0x01e53c), 0x0011
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
	stw_da (0x01e53c), xwa
	ret

SeqStep_FileSeekStore:
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekComplete
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekFinal

SeqStep_FileSeekComplete:
	stiw_da (0x01e53c), 0x0011
	ld xhl, 0xffffffff
	ret

SeqStep_FileSeekFinal:
	ld xwa, (xbc + 18)
	cp (xwa), 0x1
	jr nz, SeqStep_FileSeekExit
	ld xhl, (xbc + 22)
	ret

SeqStep_FileSeekExit:
	stiw_da (0x01e53c), 0x0012
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
	cpw_da (0x1e53c), 13
	jr nz, SeqStep_FileTellSetup
	stiw_da (0x01e53c), 0x0000
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
	cpw_da (0x1e53c), 13
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
	stiw_da (0x01e53c), 0x0015
	ldw hl, 0xffff
	jr SeqStep_FileTellExit

SeqStep_FileTellProcess:
	stiw_da (0x01e53c), 0x0000
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
	stiw_da (0x01e53c), 0x001a
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
	stiw_da	(0x1e53c), 13
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
	stiw_da	(0x1e53c), 27
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
	incw 2, (xhl + 18)
	ld wa, (xsp + 22)
	or (xhl + 22), a
	jrl SeqStep_FileIoPopReturn

SeqStep_FileIoDone:
	ld xwa, (xsp + 14)
	cp xwa, 0x1
	jr nz, SeqStep_FileIoReturn
	ldw (xsp + 4), 0x1

SeqStep_FileIoReturn:
	lda xwa, (0x02121a:24)
	ld xix, xwa
	lds32 xhl, 0
	lds32 xiz, 0
	ldw de, 0x8000
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0xa
	jr ge, SeqStep_FileIoUpdate

SeqStep_FileIoError:
	cpib_da (0x03e3e0), 0x00
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
	incw 1, (xsp + 4)
	lda_dri XIX, 0xf1, 0x1a, 0x02
	cpw (xsp + 4), 0xa
	jr lt, SeqStep_FileIoError

SeqStep_FileIoUpdate:
	stib_da (0x03e3e0), 0x00
	or xhl, xhl
	jr z, SeqStep_FileIoValidate
	addiw_da (xhl + 18), 0x14
	ld wa, (xhl + 18)
	bit 15, wa
	jr z, SeqStep_FileIoStore
	stib_da (0x03e3e0), 0x01

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
	incw 1, (xsp + 4)
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
	stib_da (0x03e3e0), 0x01

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
	lda xbc, (0x0210b4:24)
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
	lda xbc, (0x0210b4:24)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	ld (xwa + 6), de
	incw 1, (xsp + 4)

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
	lda xwa, (0x02121a:24)
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
	incw 1, (xsp + 4)
	lda_dri XBC, 0xe5, 0x1a, 0x02
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
	push	sr
	nop
	nop
	lda	xwa, (0x2121a:24)
	ld	xiz, xwa
	ldw (xsp+6), 0
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
	incw	1, (xsp+6)
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
	ld	xwa, xhl
	srl	xwa, 0
	and	xwa, 255
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
	dec	4, xsp
	push	xiz
	ld	xiz, (xsp+16)
	lda	xwa, (xiz+22)
	ld	(xsp+4), xwa
	pushw	11
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	call	16713148
	ld	xwa, (xsp+22)
	ld	(xwa+11), 0
	ld	xwa, (xsp+22)
	ld	c, (xiz+11)
	ld	(xwa+12), c
	lda	xwa, (xsp+14)
	push	xwa
	calr	65260
	ld	xwa, (xsp+26)
	ld	(xwa+13), hl
	lda	xwa, (xsp+18)
	push	xwa
	calr	65247
	ld	xwa, (xsp+30)
	ld	(xwa+15), hl
	lda	xwa, (xsp+22)
	push	xwa
	calr	65234
	ld	xwa, (xsp+34)
	ld	(xwa+17), hl
	lda	xwa, (xsp+26)
	push	xwa
	calr	65253
	lda	xsp, (xsp+26)
	ld	xwa, (xsp+12)
	ld	(xwa+19), xhl
	pop	xiz
	inc	4, xsp
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
	call	16713148
	lda	xsp, (xsp+10)
	ld	xwa, (xsp+4)
	ld	c, (xiz+12)
	ld	(xwa+11), c
	ld	xwa, 22
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+13)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+13)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+15)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+15)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+17)
	ldb	w, 0
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	wa, (xiz+17)
	srl	wa, 8
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	srl	xwa, 8
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xsp+4)
	stb_dpi	a, 224
	ld	(xsp+4), xwa
	ld	xwa, (xiz+19)
	srl	xwa, 0
	and	xwa, 255
	ld	(xbc), a
	ld	xwa, (xiz+19)
	srl	xwa, 8
	srl	xwa, 0
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
	dec 2,XSP
	push XIZ
	ld XWA,(XSP+0x0a)
	ld XDE,(XWA+0x1e)
	cpw (XDE+0x24), 0x0fff
	jrl nz, .Lc_f4fa13
	ld WA,(XSP+0x0e)
	mul WA,0x0003
	srl wa, 1
	ld BC,WA
	extz XBC
	ld XWA,XBC
	and XWA,0x000001ff
	ld (XSP+0x04),WA
	ld XIZ,XBC
	srl xiz, 9
	add XIZ,(XDE+0x18)
	pushw 0x0006
	ld XWA,(XSP+0x0c)
	ld XWA,(XWA+0x26)
	push XWA
	push XIZ
	ld XWA,(XSP+0x14)
	push XWA
	calr SeqStep_FileIoCheck
	lda xsp, (xsp + 0x0e)
	ld XBC,XHL
	ld XWA,(XSP+0x0a)
	ld (XWA+0x26),XBC
	or XHL,XHL
	jrl z, .Lc_f4fa7f
	ld WA,(XSP+0x0e)
	bit 0x00,A
	jr z, .Lc_f4f984
	ld WA,(XSP+0x10)
	and WA,0x000f
	ld BC,WA
	sll bc, 4
	ld WA,(XSP+0x04)
	extz XWA
	add XWA,0x0000001a
	add XWA,XHL
	ld A,(XWA)
	and A,0x0f
	extz WA
	or WA,BC
	ld C,A
	ld WA,(XSP+0x04)
	extz XWA
	add XWA,0x0000001a
	add XWA,XHL
	ld (XWA),C
	cpw (XSP+0x04), 0x01ff
	jr nz, .Lc_f4f968
	pushw 0x0006
	lds32 xwa, 0
	push XWA
	ld XWA,XIZ
	inc 1,XWA
	push XWA
	ld XWA,(XSP+0x14)
	push XWA
	calr SeqStep_FileIoCheck
	add XSP,0x0000000e
	or XHL,XHL
	jrl z, .Lc_f4fa7f
	ld WA,(XSP+0x10)
	srl wa, 4
	ld (XHL+0x1a),A
	jrl t, .Lc_f4fa7f
.Lc_f4f968:
	ld WA,(XSP+0x04)
	inc 1,WA
	extz XWA
	add XWA,0x0000001a
	ld XBC,XWA
	add XBC,XHL
	ld WA,(XSP+0x10)
	srl wa, 4
	ld (XBC),A
	jrl t, .Lc_f4fa7f
.Lc_f4f984:
	ld WA,(XSP+0x04)
	extz XWA
	add XWA,0x0000001a
	ld XBC,XWA
	add XBC,XHL
	ld WA,(XSP+0x10)
	ldb W, 0x00
	ld (XBC),A
	cpw (XSP+0x04), 0x01ff
	jr nz, .Lc_f4f9da
	pushw 0x0006
	lds32 xwa, 0
	push XWA
	ld XWA,XIZ
	inc 1,XWA
	push XWA
	ld XWA,(XSP+0x14)
	push XWA
	calr SeqStep_FileIoCheck
	add XSP,0x0000000e
	or XHL,XHL
	jrl z, .Lc_f4fa7f
	ld WA,(XSP+0x10)
	srl wa, 8
	ld BC,WA
	and BC,0x000f
	ld A,(XHL+0x1a)
	and A,0xf0
	extz WA
	or WA,BC
	ld (XHL+0x1a),A
	jrl t, .Lc_f4fa7f
.Lc_f4f9da:
	ld WA,(XSP+0x10)
	srl wa, 8
	ld BC,WA
	and BC,0x000f
	ld WA,(XSP+0x04)
	inc 1,WA
	extz XWA
	add XWA,0x0000001a
	add XWA,XHL
	ld A,(XWA)
	and A,0xf0
	extz WA
	or WA,BC
	ld C,A
	ld WA,(XSP+0x04)
	inc 1,WA
	extz XWA
	add XWA,0x0000001a
	add XWA,XHL
	ld (XWA),C
	jr t, .Lc_f4fa7f
.Lc_f4fa13:
	ld WA,(XSP+0x0e)
	extz XWA
	ld XBC,XWA
	add XBC,XBC
	ld XWA,XBC
	and XWA,0x000001ff
	ld (XSP+0x04),WA
	ld XIZ,XBC
	srl xiz, 9
	add XIZ,(XDE+0x18)
	pushw 0x0006
	ld XWA,(XSP+0x0c)
	ld XWA,(XWA+0x26)
	push XWA
	push XIZ
	ld XWA,(XSP+0x14)
	push XWA
	calr SeqStep_FileIoCheck
	lda xsp, (xsp + 0x0e)
	ld XBC,XHL
	ld XWA,(XSP+0x0a)
	ld (XWA+0x26),XBC
	or XHL,XHL
	jr z, .Lc_f4fa7f
	ld WA,(XSP+0x04)
	extz XWA
	add XWA,0x0000001a
	ld XBC,XWA
	add XBC,XHL
	ld WA,(XSP+0x10)
	ldb W, 0x00
	ld (XBC),A
	ld WA,(XSP+0x04)
	inc 1,WA
	extz XWA
	add XWA,0x0000001a
	ld XBC,XWA
	add XBC,XHL
	ld WA,(XSP+0x10)
	srl wa, 8
	ld (XBC),A
.Lc_f4fa7f:
	pop XIZ
	inc 2,XSP
	ret
	.byte 0xef, 0x6c, 0x3e, 0xaf, 0x0c, 0x26, 0xae, 0x1e
	.byte 0x20, 0x98, 0x24, 0x20, 0xd8, 0x68, 0xbf, 0x06
	.byte 0x50, 0x9e, 0x2a, 0x20, 0xbf, 0x04, 0x50, 0x9f
	.byte 0x04, 0x3f, 0x00, 0x00, 0x6e, 0x09, 0xbe, 0x2c
	.byte 0x02, 0x00, 0x00, 0xdb, 0xa8, 0x68, 0x27, 0xbe
	.byte 0x2c, 0x02, 0x01, 0x00, 0x68, 0x0d, 0x9f, 0x04
	.byte 0x61, 0x9f, 0x04, 0x20, 0xdb, 0xf0, 0x6e, 0x13
	.byte 0x9e, 0x2c, 0x61, 0x9f, 0x04, 0x04, 0x3e, 0x1e
	.byte 0xdc, 0xfc, 0xef, 0x66, 0xdb, 0x88, 0x9f, 0x06
	.byte 0xf0, 0x63, 0xe3, 0x9e, 0x2c, 0x23, 0x5e, 0xef
	.byte 0x64, 0x0e, 0xbf, 0xf4, 0x37, 0x3e, 0xbf, 0x08
	.byte 0x02, 0x00, 0x00, 0xbf, 0x0a, 0x02, 0x00, 0x00
	.byte 0xaf, 0x14, 0x20, 0xa8, 0x12, 0x20, 0xa8, 0x1a
	.byte 0x20, 0xbf, 0x0c, 0x60, 0xaf, 0x14, 0x20, 0xa8
	.byte 0x1e, 0x20, 0x98, 0x36, 0x20, 0xbf, 0x04, 0x50
	.byte 0xaf, 0x14, 0x20, 0x98, 0x2a, 0x20, 0xbf, 0x06
	.byte 0x50, 0x9f, 0x1a, 0x20, 0x9f, 0x1a, 0x69, 0xd8
	.byte 0xd8, 0x76, 0xdd, 0x00, 0xd9, 0xaa, 0x9f, 0x06
	.byte 0x20, 0xd8, 0x61, 0xd8, 0xda, 0x67, 0x05, 0x9f
	.byte 0x06, 0x21, 0xd9, 0x61, 0xd9, 0x8e, 0x9f, 0x04
	.byte 0xf6, 0x6b, 0x15, 0x2e, 0xaf, 0x16, 0x20, 0x38
	.byte 0x1e, 0x73, 0xfc, 0xef, 0x66, 0xdb, 0xd8, 0x66
	.byte 0x39, 0xde, 0x61, 0x9f, 0x04, 0xf6, 0x63, 0xeb
	.byte 0xde, 0xaa, 0x9f, 0x06, 0xf6, 0x6f, 0x15, 0x2e
	.byte 0xaf, 0x16, 0x20, 0x38, 0x1e, 0x57, 0xfc, 0xef
	.byte 0x66, 0xdb, 0xd8, 0x66, 0x1d, 0xde, 0x61, 0x9f
	.byte 0x06, 0xf6, 0x67, 0xeb, 0xaf, 0x14, 0x20, 0x38
	.byte 0x1e, 0x00, 0x08, 0xaf, 0x18, 0x20, 0x38, 0x1e
	.byte 0xb1, 0xf9, 0xef, 0x60, 0x33, 0x0f, 0x00, 0x78
	.byte 0xf1, 0x00, 0xaf, 0x14, 0x20, 0xa8, 0x1e, 0x20
	.byte 0x98, 0x24, 0x04, 0x2e, 0xaf, 0x18, 0x20, 0x38
	.byte 0x1e, 0x2b, 0xfd, 0xef, 0x60, 0xaf, 0x14, 0x20
	.byte 0x98, 0x45, 0x3f, 0x00, 0x00, 0x6e, 0x08, 0xaf
	.byte 0x14, 0x20, 0xb8, 0x45, 0x56, 0x68, 0x1a, 0x2e
	.byte 0x9f, 0x08, 0x04, 0xaf, 0x18, 0x20, 0x38, 0x1e
	.byte 0x0c, 0xfd, 0xef, 0x60, 0x9f, 0x08, 0x3f, 0x00
	.byte 0x00, 0x6e, 0x06, 0xaf, 0x14, 0x20, 0x98, 0x2e
	.byte 0x61, 0xbf, 0x06, 0x56, 0x9f, 0x0a, 0x61, 0x9f
	.byte 0x0a, 0x20, 0xde, 0xf0, 0x6e, 0x08, 0xaf, 0x14
	.byte 0x20, 0x98, 0x2c, 0x61, 0x68, 0x05, 0xbf, 0x0a
	.byte 0x02, 0x00, 0x00, 0x9f, 0x08, 0x3f, 0x00, 0x00
	.byte 0x6e, 0x14, 0xaf, 0x14, 0x20, 0xb8, 0x2a, 0x56
	.byte 0xbf, 0x08, 0x56, 0xbf, 0x0a, 0x56, 0xaf, 0x14
	.byte 0x20, 0xb8, 0x2c, 0x02, 0x01, 0x00, 0x9f, 0x1a
	.byte 0x20, 0x9f, 0x1a, 0x69, 0xd8, 0xd8, 0x7e, 0x23
	.byte 0xff, 0x9f, 0x18, 0x3f, 0x00, 0x00, 0x66, 0x69
	.byte 0xaf, 0x0c, 0x20, 0xb8, 0x20, 0x31, 0xde, 0x88
	.byte 0xd8, 0x6a, 0xe8, 0x12, 0xa1, 0x21, 0x1d, 0x7f
	.byte 0x02, 0xff, 0xaf, 0x0c, 0x20, 0xa8, 0x14, 0x20
	.byte 0xeb, 0x80, 0xbf, 0x08, 0x60, 0xe8, 0x8e, 0x68
	.byte 0x3b, 0x0b, 0x22, 0x00, 0xe8, 0xa8, 0x38, 0x3e
	.byte 0xaf, 0x1e, 0x20, 0x38, 0x1e, 0xd7, 0xf5, 0xef
	.byte 0xc8, 0x0e, 0x00, 0x00, 0x00, 0xeb, 0xe3, 0x6e
	.byte 0x05, 0x33, 0x0a, 0x00, 0x68, 0x2d, 0x9b, 0x14
	.byte 0x3f, 0x00, 0x00, 0x66, 0x05, 0x9b, 0x14, 0x23
	.byte 0x68, 0x21, 0x0b, 0x00, 0x02, 0x0b, 0x00, 0x00
	.byte 0xbb, 0x1a, 0x30, 0x38, 0x1d, 0x1d, 0x08, 0xff
	.byte 0xef, 0x60, 0xee, 0x61, 0xaf, 0x08, 0x21, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x20, 0x81, 0xe9, 0xf6, 0x67
	.byte 0xb8, 0xdb, 0xa8, 0x5e, 0xbf, 0x0c, 0x37, 0x0e
	.byte 0x3e, 0xaf, 0x0c, 0x26, 0x0b, 0x0b, 0x00, 0x0b
	.byte 0x20, 0x00, 0xaf, 0x0c, 0x20, 0x38, 0x1d, 0x1d
	.byte 0x08, 0xff, 0xef, 0x60, 0xaf, 0x08, 0x20, 0xb8
	.byte 0x0b, 0x00, 0x00, 0xdb, 0xa8, 0xa6
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
	.byte 0x61, 0xb0, 0xa6, 0x20, 0x80, 0x3f, 0x2f, 0x66
	.byte 0x07, 0xa6, 0x20, 0x80, 0x3f, 0x5c, 0x6e, 0x04
	.byte 0xdb, 0xa9, 0x68, 0x0a, 0xa6, 0x20, 0x80, 0x3f
	.byte 0x00, 0x66, 0x03, 0x33, 0xff, 0xff, 0xaf, 0x08
	.byte 0x20, 0x80, 0x3f, 0x2e, 0x6e, 0x0a, 0xaf, 0x08
	.byte 0x20, 0x88, 0x01, 0x3f, 0x20, 0x76, 0x4f, 0xff
	.byte 0x5e, 0x0e, 0xbf, 0xe0, 0x37, 0x2e, 0xaf, 0x26
	.byte 0x20, 0xa8, 0x12, 0x20, 0x38, 0xaf, 0x2a, 0x20
	.byte 0xa8, 0x0a, 0x20, 0xa8, 0x1c, 0x20, 0xb0, 0xe8
	.byte 0xef, 0x64, 0xdb, 0xd8, 0x66, 0x4f, 0xf2, 0x1a
	.byte 0x12, 0x02, 0x30, 0xbf, 0x10, 0x60, 0xde, 0xa8
	.byte 0xde, 0xcf, 0x0a, 0x00, 0x69, 0x36, 0xaf, 0x26
	.byte 0x20, 0xa8, 0x12, 0x21, 0xaf, 0x10, 0x20, 0xa0
	.byte 0xf1, 0x6e, 0x19, 0xaf, 0x10, 0x20, 0x88, 0x16
	.byte 0x21, 0xc9, 0xcc, 0x03, 0xc9, 0xdb, 0x6e, 0x05
	.byte 0xdb, 0xae, 0x78, 0xa4, 0x03, 0xaf, 0x10, 0x20
	.byte 0x88, 0x16, 0x3c, 0xf6, 0xde, 0x61, 0x40, 0x1a
	.byte 0x02, 0x00, 0x00, 0xaf, 0x10, 0x88, 0xde, 0xcf
	.byte 0x0a, 0x00, 0x61, 0xca, 0xaf, 0x26, 0x20, 0xa8
	.byte 0x12, 0x20, 0xb8, 0x02, 0xb9, 0xaf, 0x26, 0x20
	.byte 0xa8, 0x12, 0x20, 0xa8, 0x1a, 0x20, 0xbf, 0x04
	.byte 0x60, 0xbf, 0x2a, 0x30, 0x38, 0xbf, 0x1a, 0x30
	.byte 0x38, 0x1e, 0xc7, 0xfe, 0xef, 0x60, 0xbf, 0x14
	.byte 0x53, 0x9f, 0x14, 0x3f, 0xff, 0xff, 0x6e, 0x06
	.byte 0x33, 0x0b, 0x00, 0x78, 0x5b, 0x03, 0x8f, 0x16
	.byte 0x3f, 0x20, 0x7e, 0x32, 0x01, 0xaf, 0x26, 0x20
	.byte 0xb8, 0x03, 0xce, 0x76, 0x29, 0x01, 0xaf, 0x04
	.byte 0x20, 0x98, 0x2c, 0x21, 0xd9, 0xee, 0x05, 0xe9
	.byte 0x12, 0xaf, 0x26, 0x20, 0xb8, 0x47, 0x61, 0xaf
	.byte 0x26, 0x20, 0xb8, 0x03, 0xb1, 0xaf, 0x26, 0x20
	.byte 0xe9, 0xa8, 0xb8, 0x1a, 0x61, 0xdb, 0xa8, 0x78
	.byte 0x27, 0x03, 0xaf, 0x10, 0x20, 0x98, 0x14, 0x3f
	.byte 0x00, 0x00, 0x66, 0x09, 0xaf, 0x10, 0x20, 0x98
	.byte 0x14, 0x23, 0x78, 0x14, 0x03, 0xaf, 0x10, 0x20
	.byte 0xb8, 0x1a, 0x30, 0xbf, 0x08, 0x60, 0xde, 0xa8
	.byte 0x78, 0xa0, 0x00, 0xaf, 0x08, 0x20, 0x80, 0x3f
	.byte 0x00, 0x76, 0xf1, 0x01, 0x0b, 0x0b, 0x00, 0xaf
	.byte 0x0a, 0x20, 0x38, 0xbf, 0x1c, 0x30, 0x38, 0x1d
	.byte 0xe4, 0x04, 0xff, 0xef, 0xc8, 0x0a, 0x00, 0x00
	.byte 0x00, 0xdb, 0xd8, 0x6e, 0x74, 0xc7, 0xf8, 0x8b
	.byte 0xaf, 0x26, 0x20, 0xb8, 0x33, 0x43, 0xaf, 0x08
	.byte 0x20, 0x38, 0xaf, 0x2a, 0x20, 0xb8, 0x34, 0x30
	.byte 0x38, 0x1e, 0x19, 0xf8, 0xaf, 0x2e, 0x20, 0x98
	.byte 0x45, 0x21, 0xaf, 0x2e, 0x20, 0xb8, 0x2a, 0x51
	.byte 0xbf, 0x16, 0x51, 0xaf, 0x2e, 0x20, 0x38, 0x1e
	.byte 0x31, 0xfc, 0xbf, 0x0c, 0x37, 0xaf, 0x26, 0x20
	.byte 0xe9, 0xa8, 0xb8, 0x16, 0x61, 0xaf, 0x26, 0x20
	.byte 0xe9, 0xa8, 0xb8, 0x22, 0x61, 0xaf, 0x10, 0x20
	.byte 0xb8, 0x16, 0xb3, 0x9f, 0x14, 0x3f, 0x00, 0x00
	.byte 0x76, 0x22, 0x02, 0xaf, 0x26, 0x20, 0xb8, 0x40
	.byte 0xcc, 0x76, 0x07, 0x02, 0xbf, 0x2a, 0x30, 0x38
	.byte 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0xdc, 0xfd, 0xef
	.byte 0x60, 0xbf, 0x14, 0x53, 0x9f, 0x14, 0x3f, 0xff
	.byte 0xff, 0x6e, 0x47, 0x33, 0x0b, 0x00, 0x78, 0x70
	.byte 0x02, 0xde, 0x61, 0x40, 0x20, 0x00, 0x00, 0x00
	.byte 0xaf, 0x08, 0x88, 0x30, 0x10, 0x00, 0x9f, 0x02
	.byte 0x3f, 0x10, 0x00, 0x6a, 0x03, 0x9f, 0x02, 0x20
	.byte 0xd8, 0xf6, 0x71, 0x4e, 0xff, 0xaf, 0x10, 0x20
	.byte 0xb8, 0x16, 0xb3, 0xaf, 0x0c, 0x20, 0xe9, 0xa9
	.byte 0xa0, 0x89, 0x9f, 0x02, 0x3a, 0x10, 0x00, 0x6a
	.byte 0x4a, 0x9f, 0x14, 0x3f, 0x00, 0x00, 0x66, 0x05
	.byte 0xdb, 0xaf, 0x78, 0x34, 0x02, 0xdb, 0xad, 0x78
	.byte 0x2f, 0x02, 0xbf, 0x0c, 0x02, 0x01, 0x00, 0x9f
	.byte 0x0e, 0x3f, 0x00, 0x00, 0x7e, 0x67, 0x01, 0xaf
	.byte 0x26, 0x20, 0xb8, 0x30, 0x02, 0x00, 0x00, 0xaf
	.byte 0x26, 0x20, 0xb8, 0x1a, 0x30, 0xbf, 0x0c, 0x60
	.byte 0xaf, 0x04, 0x20, 0xaf, 0x0c, 0x21, 0xa8, 0x1c
	.byte 0x20, 0xb1, 0x60, 0xaf, 0x04, 0x20, 0x98, 0x2c
	.byte 0x20, 0xbf, 0x02, 0x50, 0x9f, 0x02, 0x3f, 0x00
	.byte 0x00, 0x62, 0xb6, 0x0b, 0x08, 0x00, 0xe8, 0xa8
	.byte 0x38, 0xaf, 0x12, 0x20, 0xa0, 0x20, 0x38, 0xaf
	.byte 0x30, 0x20, 0x38, 0x1e, 0xd3, 0xf2, 0xbf, 0x0e
	.byte 0x37, 0xbf, 0x10, 0x63, 0xaf, 0x10, 0x20, 0xe8
	.byte 0xe0, 0x7e, 0xae, 0xfe, 0xaf, 0x26, 0x20, 0x98
	.byte 0x06, 0x23, 0x78, 0xcc, 0x01, 0x0b, 0x08, 0x00
	.byte 0xe8, 0xa8, 0x38, 0xaf, 0x2c, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x38, 0xaf, 0x30, 0x20, 0x38, 0x1e, 0xa8
	.byte 0xf2, 0xbf, 0x0e, 0x37, 0xbf, 0x10, 0x63, 0xaf
	.byte 0x10, 0x20, 0xe8, 0xe0, 0x6e, 0x09, 0xaf, 0x26
	.byte 0x20, 0x98, 0x06, 0x23, 0x78, 0xa2, 0x01, 0xaf
	.byte 0x10, 0x20, 0x98, 0x14, 0x3f, 0x00, 0x00, 0x66
	.byte 0x09, 0xaf, 0x10, 0x20, 0x98, 0x14, 0x23, 0x78
	.byte 0x8f, 0x01, 0xaf, 0x10, 0x20, 0xb8, 0x1a, 0x30
	.byte 0xbf, 0x08, 0x60, 0xaf, 0x26, 0x20, 0xb8, 0x33
	.byte 0x00, 0x00, 0xaf, 0x26, 0x20, 0x88, 0x33, 0x3f
	.byte 0x10, 0x7f, 0x8e, 0x00, 0xaf, 0x08, 0x20, 0x80
	.byte 0x3f, 0x00, 0x66, 0x61, 0x0b, 0x0b, 0x00, 0xaf
	.byte 0x0a, 0x20, 0x38, 0xbf, 0x1c, 0x30, 0x38, 0x1d
	.byte 0xe4, 0x04, 0xff, 0xef, 0xc8, 0x0a, 0x00, 0x00
	.byte 0x00, 0xdb, 0xd8, 0x6e, 0x55, 0xbf, 0x0c, 0x02
	.byte 0x00, 0x00, 0xaf, 0x08, 0x20, 0x38, 0xaf, 0x2a
	.byte 0x20, 0xb8, 0x34, 0x30, 0x38, 0x1e, 0x8d, 0xf6
	.byte 0xaf, 0x2e, 0x20, 0x98, 0x45, 0x21, 0xaf, 0x2e
	.byte 0x20, 0xb8, 0x2a, 0x51, 0xbf, 0x16, 0x51, 0xaf
	.byte 0x2e, 0x20, 0xb8, 0x30, 0x51, 0xaf, 0x2e, 0x20
	.byte 0x38, 0x1e, 0x9f, 0xfa, 0xbf, 0x0c, 0x37, 0xaf
	.byte 0x10, 0x20, 0xb8, 0x16, 0xb3, 0xaf, 0x26, 0x20
	.byte 0xe9, 0xa8, 0xb8, 0x22, 0x61, 0x9f, 0x0c, 0x3f
	.byte 0x00, 0x00, 0x76, 0x90, 0x00, 0x9f, 0x14, 0x3f
	.byte 0x00, 0x00, 0x76, 0x84, 0x00, 0xdb, 0xaf, 0x78
	.byte 0xff, 0x00, 0xaf, 0x26, 0x20, 0x88, 0x33, 0x61
	.byte 0x40, 0x20, 0x00, 0x00, 0x00, 0xaf, 0x08, 0x88
	.byte 0xaf, 0x26, 0x20, 0x88, 0x33, 0x3f, 0x10, 0x77
	.byte 0x72, 0xff, 0xaf, 0x10, 0x20, 0xb8, 0x16, 0xb3
	.byte 0xaf, 0x26, 0x20, 0xe9, 0xa9, 0xa8, 0x1a, 0x89
	.byte 0x9f, 0x02, 0x61, 0xaf, 0x04, 0x20, 0xa8, 0x20
	.byte 0x20, 0x9f, 0x02, 0xf8, 0x71, 0xfe, 0xfe, 0x9f
	.byte 0x0e, 0x04, 0xaf, 0x28, 0x20, 0x38, 0x1e, 0x58
	.byte 0xf7, 0xef, 0x66, 0xbf, 0x0e, 0x53, 0xaf, 0x04
	.byte 0x20, 0x98, 0x24, 0x20, 0xd8, 0x68, 0x9f, 0x0e
	.byte 0xf8, 0x6b, 0x9a, 0xaf, 0x04, 0x20, 0xb8, 0x20
	.byte 0x31, 0x9f, 0x0e, 0x20, 0xd8, 0x6a, 0xe8, 0x12
	.byte 0xa1, 0x21, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x04
	.byte 0x20, 0xa8, 0x14, 0x21, 0xeb, 0x81, 0xaf, 0x26
	.byte 0x20, 0xb8, 0x1a, 0x61, 0xbf, 0x02, 0x02, 0x00
	.byte 0x00, 0x68, 0xb0, 0x33, 0x0c, 0x00, 0x78, 0x80
	.byte 0x00, 0xdb, 0xad, 0x68, 0x7c, 0x9f, 0x14, 0x3f
	.byte 0x00, 0x00, 0x7e, 0xde, 0xfd, 0xaf, 0x26, 0x20
	.byte 0xb8, 0x03, 0xce, 0x66, 0x45, 0xaf, 0x26, 0x20
	.byte 0xb8, 0x40, 0xcc, 0x6e, 0x05, 0x33, 0x0d, 0x00
	.byte 0x68, 0x5f, 0x9f, 0x0e, 0x3f, 0x00, 0x00, 0x6e
	.byte 0x20, 0x78, 0x0a, 0xfd, 0xaf, 0x04, 0x20, 0x98
	.byte 0x28, 0x21, 0xe9, 0x12, 0xaf, 0x26, 0x20, 0xa8
	.byte 0x47, 0x89, 0x9f, 0x0e, 0x04, 0xaf, 0x28, 0x20
	.byte 0x38, 0x1e, 0xd5, 0xf6, 0xef, 0x66, 0xbf, 0x0e
	.byte 0x53, 0xaf, 0x04, 0x20, 0x98, 0x24, 0x20, 0xd8
	.byte 0x68, 0x9f, 0x0e, 0xf8, 0x63, 0xd6, 0xdb, 0xa8
	.byte 0x68, 0x27, 0xaf, 0x26, 0x20, 0x88, 0x40, 0x21
	.byte 0xc9, 0xcc, 0x18, 0x66, 0x05, 0x33, 0x0d, 0x00
	.byte 0x68, 0x17, 0xaf, 0x26, 0x20, 0xb8, 0x40, 0xc8
	.byte 0x66, 0x0d, 0xaf, 0x26, 0x20, 0xb8, 0x03, 0xc9
	.byte 0x66, 0x05, 0x33, 0x0e, 0x00, 0x68, 0x02, 0xdb
	.byte 0xa8, 0x4e, 0xbf, 0x20, 0x37, 0x0e, 0xbf, 0xe2
	.byte 0x37, 0x3e, 0xaf, 0x26, 0x26, 0xae, 0x12, 0x20
	.byte 0xa8, 0x1a, 0x20, 0xbf, 0x06, 0x60, 0xbf, 0x2a
	.byte 0x30, 0x38, 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0x3a
	.byte 0xfb, 0xef, 0x60, 0xdb, 0xd8, 0x7e, 0x16, 0x01
	.byte 0xbe, 0x1a, 0x30, 0xbf, 0x0e, 0x60, 0xaf, 0x06
	.byte 0x20, 0xaf, 0x0e, 0x21, 0xa8, 0x1c, 0x20, 0xb1
	.byte 0x60, 0xaf, 0x06, 0x20, 0x98, 0x2c, 0x20, 0xbf
	.byte 0x04, 0x50, 0x9f, 0x04, 0x3f, 0x00, 0x00, 0x71
	.byte 0xee, 0x00, 0x0b, 0x18, 0x00, 0xe8, 0xa8, 0x38
	.byte 0xaf, 0x14, 0x20, 0xa0, 0x20, 0x38, 0x3e, 0x1e
	.byte 0x97, 0xf0, 0xbf, 0x0e, 0x37, 0xbf, 0x12, 0x63
	.byte 0xaf, 0x12, 0x20, 0xe8, 0xe0, 0x6e, 0x06, 0x9e
	.byte 0x06, 0x23, 0x78, 0xe4, 0x01, 0xaf, 0x12, 0x20
	.byte 0x98, 0x14, 0x3f, 0x00, 0x00, 0x66, 0x09, 0xaf
	.byte 0x12, 0x20, 0x98, 0x14, 0x23, 0x78, 0xd1, 0x01
	.byte 0xaf, 0x12, 0x20, 0xb8, 0x1a, 0x30, 0xbf, 0x0a
	.byte 0x60, 0xdb, 0xa8, 0x68, 0x7e, 0xaf, 0x0a, 0x20
	.byte 0x80, 0x3f, 0xe5, 0x66, 0x08, 0xaf, 0x0a, 0x20
	.byte 0x80, 0x3f, 0x00, 0x6e, 0x64, 0xbe, 0x33, 0x47
	.byte 0xbe, 0x2a, 0x02, 0x00, 0x00, 0xbe, 0x2e, 0x02
	.byte 0x00, 0x00, 0xbe, 0x32, 0x00, 0x00, 0x0b, 0x0b
	.byte 0x00, 0xbf, 0x18, 0x30, 0x38, 0xbe, 0x34, 0x30
	.byte 0x38, 0x1d, 0xbc, 0x05, 0xff, 0xbe, 0x40, 0x00
	.byte 0x00, 0xbe, 0x45, 0x02, 0x00, 0x00, 0xe8, 0xa8
	.byte 0xbe, 0x47, 0x60, 0xe8, 0xa8, 0xbe, 0x22, 0x60
	.byte 0xbe, 0x41, 0x30, 0x38, 0xae, 0x0a, 0x20, 0xa8
	.byte 0x18, 0x20, 0xb0, 0xe8, 0xaf, 0x18, 0x20, 0x38
	.byte 0xbe, 0x34, 0x30, 0x38, 0x1e, 0xcb, 0xf4, 0xaf
	.byte 0x28, 0x20, 0xb8, 0x16, 0xb9, 0xaf, 0x28, 0x20
	.byte 0x88, 0x16, 0x3c, 0xe7, 0xaf, 0x28, 0x20, 0x38
	.byte 0x1e, 0x33, 0xf2, 0xbf, 0x1a, 0x37, 0x78, 0x50
	.byte 0x01, 0xdb, 0x61, 0x40, 0x20, 0x00, 0x00, 0x00
	.byte 0xaf, 0x0a, 0x88, 0x30, 0x10, 0x00, 0x9f, 0x04
	.byte 0x3f, 0x10, 0x00, 0x6a, 0x03, 0x9f, 0x04, 0x20
	.byte 0xd8, 0xf3, 0x71, 0x70, 0xff, 0xaf, 0x12, 0x20
	.byte 0x88, 0x16, 0x3c, 0xe7, 0x9f, 0x04, 0x3a, 0x10
	.byte 0x00, 0xaf, 0x0e, 0x20, 0xe9, 0xa9, 0xa0, 0x89
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00, 0x79, 0x12, 0xff
	.byte 0x33, 0x10, 0x00, 0x78, 0x13, 0x01, 0x9e, 0x45
	.byte 0x20, 0xbe, 0x30, 0x50, 0xbf, 0x2a, 0x30, 0x38
	.byte 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0x0c, 0xfa, 0xef
	.byte 0x60, 0xdb, 0xd8, 0x76, 0xd0, 0x00, 0xbf, 0x2a
	.byte 0x30, 0x38, 0xbf, 0x1a, 0x30, 0x38, 0x1e, 0xfa
	.byte 0xf9, 0xef, 0x60, 0xdb, 0xd8, 0x6e, 0xef, 0x78
	.byte 0xbc, 0x00, 0xaf, 0x06, 0x20, 0xb8, 0x20, 0x31
	.byte 0x9e, 0x2a, 0x20, 0xd8, 0x6a, 0xe8, 0x12, 0xa1
	.byte 0x21, 0x1d, 0x7f, 0x02, 0xff, 0xaf, 0x06, 0x20
	.byte 0xa8, 0x14, 0x20, 0xeb, 0x80, 0xbe, 0x1a, 0x60
	.byte 0xbf, 0x04, 0x02, 0x00, 0x00, 0x68, 0x79, 0x0b
	.byte 0x18, 0x00, 0xe8, 0xa8, 0x38, 0xae, 0x1a, 0x20
	.byte 0x38, 0x3e, 0x1e, 0x54, 0xef, 0xbf, 0x0e, 0x37
	.byte 0xbf, 0x12, 0x63, 0xaf, 0x12, 0x20, 0xe8, 0xe0
	.byte 0x6e, 0x06, 0x9e, 0x06, 0x23, 0x78, 0xa1, 0x00
	.byte 0xaf, 0x12, 0x20, 0x98, 0x14, 0x3f, 0x00, 0x00
	.byte 0x66, 0x09, 0xaf, 0x12, 0x20, 0x98, 0x14, 0x23
	.byte 0x78, 0x8e, 0x00, 0xaf, 0x12, 0x20, 0xb8, 0x1a
	.byte 0x30, 0xbf, 0x0a, 0x60, 0xbe, 0x33, 0x00, 0x00
	.byte 0x8e, 0x33, 0x3f, 0x10, 0x6f, 0x23, 0xaf, 0x0a
	.byte 0x20, 0x80, 0x3f, 0xe5, 0x76, 0xc1, 0xfe, 0xaf
	.byte 0x0a, 0x20, 0x80, 0x3f, 0x00, 0x76, 0xb8, 0xfe
	.byte 0x8e, 0x33, 0x61, 0x40, 0x20, 0x00, 0x00, 0x00
	.byte 0xaf, 0x0a, 0x88, 0x8e, 0x33, 0x3f, 0x10, 0x67
	.byte 0xdd, 0xaf, 0x12, 0x20, 0x88, 0x16, 0x3c, 0xe7
	.byte 0xe8, 0xa9, 0xae, 0x1a, 0x88, 0x9f, 0x04, 0x61
	.byte 0xaf, 0x06, 0x20, 0xa8, 0x20, 0x20, 0x9f, 0x04
	.byte 0xf8, 0x71, 0x7b, 0xff, 0x9e, 0x2a, 0x20, 0xbf
	.byte 0x14, 0x50, 0x9e, 0x2a, 0x04, 0x3e, 0x1e, 0x78
	.byte 0xf4, 0xef, 0x66, 0xbe, 0x2a, 0x53, 0xaf, 0x06
	.byte 0x20, 0x98, 0x24, 0x20, 0xd8, 0x68, 0x9e, 0x2a
	.byte 0xf8, 0x73, 0x36, 0xff, 0xbe, 0x33, 0x00, 0x00
	.byte 0x9f, 0x14, 0x20, 0xbe, 0x2a, 0x50, 0x0b, 0x01
	.byte 0x00, 0x0b, 0x01, 0x00, 0x3e, 0x1e, 0x85, 0xf7
	.byte 0xef, 0x60, 0xdb, 0x88, 0xd8, 0xd8, 0x76, 0x19
	.byte 0xff, 0x5e, 0xbf, 0x1e, 0x37, 0x0e
	dec 4,XSP
	push XIZ
	ld XIZ,(XSP+0x0c)
	lda xwa, (xiz + 0x41)
	push XWA
	ld XWA,(XIZ+0x0a)
	ld XWA,(XWA+0x18)
	call (XWA)
	pushw 0x001a
	.byte 0xe8, 0xa8, 0x38, 0xae, 0x1a, 0x20, 0x38, 0x3e
	.byte 0x1e, 0x7b, 0xee, 0xbf, 0x12, 0x37, 0xbf, 0x04
	.byte 0x63, 0xaf, 0x04, 0x20, 0xe8, 0xe0, 0x6e, 0x05
	.byte 0x33, 0x0a, 0x00, 0x68, 0x29, 0x8e, 0x33, 0x21
	.byte 0xd8, 0x12, 0xd8, 0xec, 0x05, 0xd8, 0x89, 0xd9
	.byte 0xc8, 0x1a, 0x00, 0xaf, 0x04, 0x20, 0xf3, 0x07
	.byte 0xe0, 0xe4, 0x30, 0x38, 0xbe, 0x34, 0x30, 0x38
	.byte 0x1e, 0x0c, 0xf3, 0xef, 0x60, 0xaf, 0x04, 0x20
	.byte 0x88, 0x16, 0x3c, 0xe7, 0xdb, 0xa8, 0x5e, 0xef
	.byte 0x64, 0x0e, 0x3e, 0xaf, 0x08, 0x20, 0x98, 0x45
	.byte 0x26, 0xde, 0xd8, 0x6e, 0x21, 0xd7, 0xfa, 0xa8
	.byte 0x68, 0x1c, 0x2e, 0xaf, 0x0a, 0x20, 0x38, 0x1e
	.byte 0xcc, 0xf3, 0xd7, 0xfa, 0x9b, 0x0b, 0x00, 0x00
	.byte 0x2e, 0xaf, 0x12, 0x20, 0x38, 0x1e, 0xc6, 0xf4
	.byte 0xbf, 0x0e, 0x37, 0xd7, 0xfa, 0x8e, 0xde, 0xd8
	.byte 0x66, 0x0f, 0xaf, 0x08, 0x20, 0xa8, 0x1e, 0x20
	.byte 0x98, 0x24, 0x20, 0xd8, 0x68, 0xd8, 0xf6, 0x63
	.byte 0xd1, 0xaf, 0x08, 0x20, 0xb8, 0x03, 0xcd, 0x6e
	.byte 0x18, 0xaf, 0x08, 0x20, 0xb8, 0x45, 0x02, 0x00
	.byte 0x00, 0xd9, 0xa8, 0xaf, 0x08, 0x20, 0xb8, 0x2a
	.byte 0x51, 0xaf, 0x08, 0x20, 0xe9, 0xa8, 0xb8, 0x47
	.byte 0x61, 0x5e, 0x0e
	lda xsp, (xsp - 0x22)
	push XIZ
	ldw (XSP+0x12), 0x0000
	ldw (XSP+0x14), 0x0000
	ldw (XSP+0x16), 0x0001
	.byte 0xe8, 0xa8, 0xbf, 0x18, 0x60, 0xeb, 0xa8, 0xbf
	.byte 0x20, 0x02, 0xff, 0x0f, 0xaf, 0x2a, 0x20, 0xa8
	.byte 0x1a, 0x20, 0xbf, 0x04, 0x60, 0xaf, 0x2a, 0x20
	.byte 0xb8, 0x02, 0xb0, 0x0b, 0x1a, 0x02, 0x1d, 0x62
	.byte 0xe7, 0xf4, 0xef, 0x62, 0xbf, 0x08, 0x63, 0xeb
	.byte 0x88, 0xe8, 0xe0, 0x6e, 0x05, 0xdb, 0xab, 0x78
	.byte 0x17, 0x04, 0xaf, 0x08, 0x20, 0xaf, 0x2a, 0x21
	.byte 0xb0, 0x61, 0xaf, 0x08, 0x20, 0xe9, 0xa8, 0xb8
	.byte 0x0c, 0x61, 0xaf, 0x04, 0x20, 0xb8, 0x32, 0x02
	.byte 0x20, 0x00, 0xaf, 0x04, 0x20, 0xb8, 0x34, 0x02
	.byte 0x08, 0x00, 0xaf, 0x2a, 0x20, 0xb8, 0x04, 0xcf
	.byte 0x76, 0x1f, 0x01, 0xbf, 0x10, 0x02, 0x00, 0x00
	.byte 0x78, 0xfb, 0x00, 0xaf, 0x08, 0x20, 0x38, 0xaf
	.byte 0x1c, 0x20, 0x38, 0xaf, 0x32, 0x20, 0xa8, 0x0e
	.byte 0x20, 0xa8, 0x10, 0x20, 0xb0, 0xe8, 0xef, 0x60
	.byte 0xdb, 0x8e, 0xde, 0xd8, 0x6e, 0x19, 0xaf, 0x08
	.byte 0x20, 0xc3, 0xe1, 0x18, 0x02, 0x3f, 0x55, 0x6e
	.byte 0x0b, 0xaf, 0x08, 0x20, 0xc3, 0xe1, 0x19, 0x02
	.byte 0x3f, 0xaa, 0x66, 0x12, 0x36, 0x16, 0x00, 0xaf
	.byte 0x08, 0x20, 0x38, 0x1d, 0x03, 0xee, 0xf4, 0xef
	.byte 0x64, 0xde, 0x8b, 0x78, 0xa3, 0x03, 0xaf, 0x08
	.byte 0x20, 0xf3, 0xe1, 0xd8, 0x01, 0x30, 0xbf, 0x0c
	.byte 0x60, 0x88, 0x06, 0x21, 0xc9, 0xcc, 0x3f, 0xc9
	.byte 0x8b, 0xd9, 0x12, 0xaf, 0x04, 0x20, 0xb8, 0x32
	.byte 0x51, 0xaf, 0x0c, 0x20, 0x88, 0x05, 0x21, 0xc9
	.byte 0xcc, 0x3f, 0xd8, 0x12, 0xd8, 0x61, 0xd8, 0x89
	.byte 0xaf, 0x04, 0x20, 0xb8, 0x34, 0x51, 0xaf, 0x0c
	.byte 0x20, 0xe8, 0x60, 0xbf, 0x22, 0x60, 0xbf, 0x22
	.byte 0x30, 0x38, 0x1e, 0x7c, 0xf0, 0xef, 0x64, 0xaf
	.byte 0x18, 0x20, 0xeb, 0x80, 0xbf, 0x1c, 0x60, 0xaf
	.byte 0x2a, 0x20, 0x88, 0x05, 0x21, 0xd8, 0x12, 0x9f
	.byte 0x10, 0xf8, 0x69, 0x26, 0xaf, 0x18, 0x8b, 0xbf
	.byte 0x22, 0x30, 0x38, 0x1e, 0x5b, 0xf0, 0xef, 0x64
	.byte 0xaf, 0x18, 0x8b, 0x40, 0x10, 0x00, 0x00, 0x00
	.byte 0xaf, 0x0c, 0x88, 0xaf, 0x0c, 0x20, 0x88, 0x04
	.byte 0x3f, 0x05, 0x66, 0x06, 0x36, 0x17, 0x00, 0x78
	.byte 0x75, 0xff, 0xaf, 0x0c, 0x20, 0x88, 0x02, 0x21
	.byte 0xc9, 0xcc, 0x3f, 0xd8, 0x12, 0xbf, 0x16, 0x50
	.byte 0xaf, 0x0c, 0x20, 0x88, 0x01, 0x21, 0xd8, 0x12
	.byte 0xbf, 0x14, 0x50, 0xaf, 0x0c, 0x20, 0x88, 0x03
	.byte 0x21, 0xc9, 0x8b, 0xd9, 0x12, 0xaf, 0x0c, 0x20
	.byte 0x88, 0x02, 0x21, 0xc9, 0xcc, 0xc0, 0xd8, 0x12
	.byte 0xbf, 0x12, 0x50, 0xd8, 0xec, 0x02, 0xd9, 0x80
	.byte 0xbf, 0x12, 0x50, 0x9f, 0x10, 0x61, 0xaf, 0x2a
	.byte 0x20, 0x88, 0x05, 0x21, 0xd8, 0x12, 0x9f, 0x10
	.byte 0xf8, 0x72, 0xf7, 0xfe, 0xaf, 0x0c, 0x20, 0x88
	.byte 0x04, 0x3f, 0x04, 0x67, 0x05, 0xbf, 0x20, 0x02
	.byte 0xff, 0xff, 0xaf, 0x2a, 0x20, 0xb8, 0x04, 0xcf
	.byte 0x66, 0x19, 0xaf, 0x08, 0x20, 0x38, 0xaf, 0x20
	.byte 0x20, 0x38, 0xaf, 0x32, 0x20, 0xa8, 0x0e, 0x20
	.byte 0xa8, 0x10, 0x20, 0xb0, 0xe8, 0xef, 0x60, 0xdb
	.byte 0x8e, 0x68, 0x27, 0xaf, 0x08, 0x20, 0xb8, 0x1a
	.byte 0x30, 0x38, 0x0b, 0x01, 0x00, 0x9f, 0x1c, 0x04
	.byte 0x9f, 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0xaf, 0x36
	.byte 0x20, 0x38, 0xaf, 0x3a, 0x20, 0xa8, 0x0e, 0x20
	.byte 0xa8, 0x04, 0x20, 0xb0, 0xe8, 0xbf, 0x10, 0x37
	.byte 0xdb, 0x8e, 0xde, 0xcf, 0x09, 0x00, 0x6e, 0x55
	.byte 0x0b, 0x1a, 0x02, 0x1d, 0x62, 0xe7, 0xf4, 0xeb
	.byte 0x8e, 0xaf, 0x0a, 0x20, 0x38, 0x1d, 0x03, 0xee
	.byte 0xf4, 0xef, 0x66, 0xee, 0xe6, 0x6e, 0x05, 0xdb
	.byte 0xab, 0x78, 0x65, 0x02, 0xbf, 0x08, 0x66, 0xee
	.byte 0x88, 0xaf, 0x2a, 0x21, 0xb0, 0x61, 0xaf, 0x08
	.byte 0x20, 0xe9, 0xa8, 0xb8, 0x0c, 0x61, 0xaf, 0x08
	.byte 0x20, 0xb8, 0x1a, 0x30, 0x38, 0x0b, 0x01, 0x00
	.byte 0x9f, 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0x9f, 0x1c
	.byte 0x04, 0xaf, 0x36, 0x20, 0x38, 0xaf, 0x3a, 0x20
	.byte 0xa8, 0x0e, 0x20, 0xa8, 0x04, 0x20, 0xb0, 0xe8
	.byte 0xbf, 0x10, 0x37, 0xdb, 0x8e, 0xde, 0xde, 0x6e
	.byte 0x48, 0xaf, 0x2a, 0x20, 0xb8, 0x04, 0xcf, 0x66
	.byte 0x19, 0xaf, 0x08, 0x20, 0x38, 0xaf, 0x20, 0x20
	.byte 0x38, 0xaf, 0x32, 0x20, 0xa8, 0x0e, 0x20, 0xa8
	.byte 0x10, 0x20, 0xb0, 0xe8, 0xef, 0x60, 0xdb, 0x8e
	.byte 0x68, 0x27, 0xaf, 0x08, 0x20, 0xb8, 0x1a, 0x30
	.byte 0x38, 0x0b, 0x01, 0x00, 0x9f, 0x1c, 0x04, 0x9f
	.byte 0x1c, 0x04, 0x9f, 0x1c, 0x04, 0xaf, 0x36, 0x20
	.byte 0x38, 0xaf, 0x3a, 0x20, 0xa8, 0x0e, 0x20, 0xa8
	.byte 0x04, 0x20, 0xb0, 0xe8, 0xbf, 0x10, 0x37, 0xdb
	.byte 0x8e, 0xde, 0xd8, 0x7e, 0x29, 0xfe, 0xaf, 0x08
	.byte 0x20, 0xb8, 0x25, 0x30, 0xbf, 0x22, 0x60, 0xbf
	.byte 0x22, 0x30, 0x38, 0x1e, 0xc3, 0xee, 0xef, 0x64
	.byte 0xaf, 0x04, 0x20, 0xb8, 0x26, 0x53, 0xaf, 0x22
	.byte 0x21, 0xe8, 0xa9, 0xaf, 0x22, 0x88, 0x81, 0x21
	.byte 0xe9, 0xa8, 0xc9, 0x8b, 0xaf, 0x04, 0x20, 0xb8
	.byte 0x20, 0x61, 0xaf, 0x04, 0x20, 0x98, 0x26, 0x3f
	.byte 0x00, 0x00, 0x66, 0x0a, 0xaf, 0x04, 0x20, 0xa8
	.byte 0x20, 0x20, 0xe8, 0xe0, 0x6e, 0x06, 0x36, 0x28
	.byte 0x00, 0x78, 0xe3, 0xfd, 0xbf, 0x22, 0x30, 0x38
	.byte 0x1e, 0x86, 0xee, 0xaf, 0x08, 0x20, 0xb8, 0x2a
	.byte 0x53, 0xaf, 0x26, 0x21, 0xe8, 0xa9, 0xaf, 0x26
	.byte 0x88, 0xaf, 0x08, 0x20, 0x81, 0x23, 0xb8, 0x3a
	.byte 0x43, 0xbf, 0x26, 0x30, 0x38, 0x1e, 0x69, 0xee
	.byte 0xaf, 0x0c, 0x20, 0xb8, 0x2c, 0x53, 0xbf, 0x2a
	.byte 0x30, 0x38, 0x1e, 0x5c, 0xee, 0xdb, 0x89, 0xe9
	.byte 0x12, 0xaf, 0x10, 0x20, 0xb8, 0x08, 0x61, 0xaf
	.byte 0x2e, 0x21, 0xe8, 0xa9, 0xaf, 0x2e, 0x88, 0xaf
	.byte 0x10, 0x20, 0x81, 0x23, 0xb8, 0x3b, 0x43, 0xbf
	.byte 0x2e, 0x30, 0x38, 0x1e, 0x3b, 0xee, 0xaf, 0x14
	.byte 0x20, 0xb8, 0x30, 0x53, 0xbf, 0x32, 0x30, 0x38
	.byte 0x1e, 0x2e, 0xee, 0xaf, 0x18, 0x20, 0xb8, 0x32
	.byte 0x53, 0xbf, 0x36, 0x30, 0x38, 0x1e, 0x21, 0xee
	.byte 0xaf, 0x1c, 0x20, 0xb8, 0x34, 0x53, 0xbf, 0x3a
	.byte 0x30, 0x38, 0x1e, 0x14, 0xee, 0xbf, 0x1c, 0x37
	.byte 0xdb, 0x89, 0xe9, 0x12, 0xaf, 0x04, 0x20, 0xb8
	.byte 0x10, 0x61, 0xaf, 0x04, 0x20, 0xe9, 0xa8, 0xb8
	.byte 0x0c, 0x61, 0xaf, 0x04, 0x20, 0xb8, 0x3c, 0x00
	.byte 0x00, 0xaf, 0x04, 0x20, 0x98, 0x2a, 0x20, 0xe8
	.byte 0x12, 0xe8, 0x89, 0xaf, 0x04, 0x20, 0xa8, 0x10
	.byte 0x81, 0xaf, 0x18, 0x81, 0xaf, 0x04, 0x20, 0xb8
	.byte 0x18, 0x61, 0xaf, 0x04, 0x20, 0x88, 0x3a, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x89, 0xaf, 0x04, 0x20, 0x98
	.byte 0x30, 0x41, 0xaf, 0x04, 0x20, 0xa8, 0x18, 0x22
	.byte 0xe9, 0x82, 0xaf, 0x04, 0x20, 0xb8, 0x1c, 0x62
	.byte 0xaf, 0x04, 0x20, 0x98, 0x26, 0x21, 0xd9, 0xef
	.byte 0x05, 0xaf, 0x04, 0x20, 0x98, 0x2c, 0x20, 0xe8
	.byte 0x12, 0xd9, 0x50, 0xd8, 0x89, 0xaf, 0x04, 0x20
	.byte 0xb8, 0x2e, 0x51, 0xaf, 0x04, 0x20, 0xb8, 0x20
	.byte 0x31, 0xaf, 0x04, 0x20, 0x98, 0x26, 0x20, 0xe8
	.byte 0x12, 0xa1, 0x21, 0x1d, 0x7f, 0x02, 0xff, 0xaf
	.byte 0x04, 0x20, 0xb8, 0x28, 0x53, 0xaf, 0x04, 0x20
	.byte 0x98, 0x2e, 0x20, 0xe8, 0x12, 0xe8, 0x89, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x1c, 0x81, 0xaf, 0x04, 0x20
	.byte 0xb8, 0x14, 0x61, 0xaf, 0x04, 0x20, 0x98, 0x26
	.byte 0x20, 0xd8, 0x69, 0xd8, 0x89, 0xe9, 0x12, 0xaf
	.byte 0x04, 0x20, 0xb8, 0x04, 0x61, 0xaf, 0x04, 0x20
	.byte 0x88, 0x3a, 0x21, 0xd8, 0x12, 0xd8, 0x89, 0xaf
	.byte 0x04, 0x20, 0x98, 0x30, 0x41, 0xe9, 0x8b, 0xaf
	.byte 0x04, 0x20, 0x98, 0x2e, 0x21, 0xe9, 0x12, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x08, 0x22, 0xe9, 0xa2, 0xaf
	.byte 0x04, 0x20, 0x98, 0x2a, 0x20, 0xe8, 0x12, 0xe8
	.byte 0xa2, 0xeb, 0xa2, 0xea, 0x88, 0xaf, 0x04, 0x21
	.byte 0xa9, 0x20, 0x21, 0x1d, 0x3b, 0x04, 0xff, 0xeb
	.byte 0x61, 0xaf, 0x04, 0x20, 0xb8, 0x36, 0x53, 0xaf
	.byte 0x04, 0x20, 0x98, 0x36, 0x3f, 0xf7, 0x0f, 0x63
	.byte 0x05, 0xbf, 0x20, 0x02, 0xff, 0xff, 0xaf, 0x04
	.byte 0x20, 0x9f, 0x20, 0x21, 0xb8, 0x24, 0x51, 0xaf
	.byte 0x2a, 0x20, 0xb8, 0x02, 0xb8, 0xaf, 0x08, 0x20
	.byte 0x38, 0x1d, 0x03, 0xee, 0xf4, 0xef, 0x64, 0xdb
	.byte 0xa8, 0x5e, 0xbf, 0x22, 0x37, 0x0e
SeqByteBlock_ChannelContainer:
	; framing ported from v10's source for the same label (same span length, statement for statement); 697 of 793 slots byte-identical
	dec	8, xsp
	pushw	iz
	ld	xwa, (xsp+14)
	ld	xwa, (xwa+18)
	ld	(xsp+2), xwa
	ld	xwa, (xwa+26)
	ld	(xsp+6), xwa
	ld	xwa, (xsp+2)
	.byte 0xb8	; v10 does not spell this byte either
	push	sr
	dec	6, c
	ldb	w, 175
	push	sr
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
	.byte 0xb8	; v10 does not spell this byte either
	push	sr
	ldw	(xhl-81), 47136
	push	sr
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
	.byte 0x98	; v10 does not spell this byte either
	ldb	h, 63
	nop
	push	sr
	jr	z, 5
	lds	hl, 1
	jrl	141
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+6)
	ld	(xwa+30), xbc
	ld	xwa, (xsp+14)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
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
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, l
	ld	xhl, 359061726
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
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, c
	pushw	3759
	ldb	w, 232
	.byte 0x89	; v10 does not spell this byte either
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	ld	xwa, (xsp+14)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, d
	retd	3759
	ldb	w, 56
	calr	64111
	inc	4, xsp
	ld	xwa, (xsp+14)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	.byte 0xbf	; v10 does not spell this byte either
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
	call	16712763
	ld	xwa, (xsp+8)
	ld	xbc, (xwa+28)
	add	xbc, xhl
	ld	xwa, (xsp+22)
	ld	(xwa), xbc
	ld	xwa, (xsp+22)
	ld	xbc, (xwa)
	ld	xwa, (xsp+8)
	.byte 0xa8	; v10 does not spell this byte either
	.byte 0x1c	; v10 does not spell this byte either
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
	.byte 0x98	; v10 does not spell this byte either
	pushw	wa
	.byte 0x51	; v10 does not spell this byte either
	ld	(xsp+4), bc
	ld	xwa, (xsp+8)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+22)
	call	16712757
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+38)
	extz	xbc
	ld	xwa, xiz
	call	16712763
	ld	a, l
	ld	(xsp+6), a
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	nz, 66
	ld	xwa, (xsp+16)
	.byte 0x98	; v10 does not spell this byte either
	pushw	de
	push	xsp
	nop
	nop
	jr	nz, 33
	ld	xwa, (xsp+16)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, a
	pop_f
	.byte 0x9f	; v10 does not spell this byte either
	push_a
	.byte 0x04	; v10 does not spell this byte either
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
	.byte 0x98	; v10 does not spell this byte either
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
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
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
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
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
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, a
	ldf	159
	push_a
	.byte 0x04	; v10 does not spell this byte either
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
	incw	1, (xwa+46)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	c, -99
	ld	xwa, (xsp+16)
	push	xwa
	calr	61342
	inc	4, xsp
	lds32	xwa, 0
	ld	a, (xsp+6)
	ld	xbc, xwa
	ld	xwa, (xsp+8)
	.byte 0xa8	; v10 does not spell this byte either
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
	call	16712319
	ld	xwa, (xsp+22)
	add	(xwa), xhl
	ld	xwa, (xsp+16)
	ld	wa, (xwa+44)
	extz	xwa
	ld	xbc, (xsp+8)
	ld	xbc, (xbc+32)
	call	16712319
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
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x1c	; v10 does not spell this byte either
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
	.byte 0x98	; v10 does not spell this byte either
	pushw	wa
	.byte 0x51	; v10 does not spell this byte either
	ld	(xsp+4), bc
	ld	wa, (xsp+28)
	exts	xwa
	ld	xbc, xwa
	.byte 0xae	; v10 does not spell this byte either
	ex_ff
	sub	(xbc), l
	.byte 0x06	; v10 does not spell this byte either
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
	call	16712763
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
	stw_da	(124220), wa
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
	.byte 0xb8	; v10 does not spell this byte either
	ex_ff
	.byte 0xb3	; v10 does not spell this byte either
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
	.byte 0xbe	; v10 does not spell this byte either
	ei	2
	ldwio	0, 15602
	.byte 0xe5	; v10 does not spell this byte either
	.byte 0x01	; v10 does not spell this byte either
	push	sr
	ldwio	0, 43227
	jrl	202
	ld	xbc, (xiz+34)
	ld	xwa, (xsp+24)
	ld	(xbc+12), xwa
	ld	wa, (xsp+28)
	ld	(xsp+4), wa
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98	; v10 does not spell this byte either
	ldb	h, 81
	ld	(xsp+4), bc
	ld	xbc, (xiz+34)
	lda	xbc, (xbc+16)
	ld	wa, (xsp+4)
	.byte 0x9f	; v10 does not spell this byte either
	ldwio	240, 1391
	ld	wa, (xsp+4)
	jr	3
	ld	wa, (xsp+10)
	ld	(xbc), wa
	ld	xwa, (xiz+34)
	ld	wa, (xwa+16)
	ld	(xsp+4), wa
	.byte 0x9f	; v10 does not spell this byte either
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
	.byte 0xb8	; v10 does not spell this byte either
	ex_ff
	.byte 0xb3	; v10 does not spell this byte either
	ld	xbc, (xiz+34)
	lds32	xwa, 0
	ld	(xbc+12), xwa
	ld	xwa, (xiz+34)
	.byte 0x98	; v10 does not spell this byte either
	push_a
	push	xsp
	nop
	nop
	jr	z, 4
	lds	hl, 0
	jr	11
	ld	bc, (xsp+4)
	ld	xwa, (xsp+6)
	.byte 0x98	; v10 does not spell this byte either
	ldb	h, 65
	ld	hl, bc
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+6)
	.byte 0x98	; v10 does not spell this byte either
	pushw	wa
	.byte 0x51	; v10 does not spell this byte either
	sub	(xiz+44), bc
	ld	xwa, (xiz+34)
	ld	(xwa+22), 0
	ld	xwa, (xiz+34)
	.byte 0x98	; v10 does not spell this byte either
	push_a
	push	xsp
	ldb	c, 0
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
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	.byte 0xf1	; v10 does not spell this byte either
	jr	nz, 13
	ld	xwa, (xsp+10)
	.byte 0x98	; v10 does not spell this byte either
	.byte 0x06	; v10 does not spell this byte either
	push	xiz
	nop
	xor	(xwa), c
	cp	(xwa+120), xhl
	normal
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	.byte 0xa1	; v10 does not spell this byte either
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
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	.byte 0xa1	; v10 does not spell this byte either
	ld	(xsp+18), bc
	.byte 0x9f	; v10 does not spell this byte either
	ccf
	push	xsp
	nop
	nop
	jrl	z, 435
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	subdm8	(10350), l
	ldwio	32, 1688
	push	xsp
	ldb	c, 0
	jr	z, 30
	ld	xwa, (xsp+10)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	dec	6, b
	ex_ff
	.byte 0x9f	; v10 does not spell this byte either
	push_a
	push	xsp
	nop
	nop
	jr	nz, 15
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+30)
	ld	wa, (xsp+18)
	.byte 0x99	; v10 does not spell this byte either
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
	stw_da	(124220), wa
	ld	hl, (xsp+2)
	jrl	354
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	.byte 0xb8	; v10 does not spell this byte either
	ex_ff
	inc	6, w
	.byte 0xd4	; v10 does not spell this byte either
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	ld	w, (2735:16)
	ld	xwa, (xwa+30)
	ld	de, (xwa+38)
	sub	de, bc
	ld	wa, bc
	extz	xwa
	lda	xbc, (xwa+26)
	ld	xwa, (xsp+10)
	.byte 0xa8	; v10 does not spell this byte either
	ldb	b, 129
	ld	xwa, (xsp+10)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	scc	nz, b
	.byte 0x94	; v10 does not spell this byte either
	nop
	.byte 0x9f	; v10 does not spell this byte either
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
	call	16713148
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
	.byte 0x9f	; v10 does not spell this byte either
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
	cpl	qwa
	ld	bc, (xsp+20)
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
	.byte 0x98	; v10 does not spell this byte either
	.byte 0x06	; v10 does not spell this byte either
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
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, b
	push	129
	push	xsp
	decf
	jr	nz, 4
	inc	1, xbc
	jr	40
	decm	1, (xsp+18)
	incw	1, (xsp+2)
	ldb_spi	e, 228
	ld	xwa, (xsp+14)
	lda_dpi	xiy, 224
	ld	(xsp+14), xwa
	ld	xwa, (xsp+10)
	cp	(xwa+2), e
	jr	nz, 14
	.byte 0x9f	; v10 does not spell this byte either
	push_a
	push	xsp
	nop
	nop
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
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	subdm8	(4462), l
	ldwio	32, 8872
	ldb	w, 184
	ex_ff
	.byte 0xb3	; v10 does not spell this byte either
	ld	xwa, (xsp+10)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	.byte 0x9f	; v10 does not spell this byte either
	ccf
	push	xsp
	nop
	nop
	jrl	nz, -435
	ld	wa, (xsp+2)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	nc, 8
	ld	xwa, (xsp+10)
	.byte 0x98	; v10 does not spell this byte either
	.byte 0x06	; v10 does not spell this byte either
	push	xiz
	nop
	.byte 0x80	; v10 does not spell this byte either
	ld	hl, (xsp+2)
	popw	iz
	inc	4, xsp
	ret
SeqChan_SetupAndCallHelper:
	pushw 0
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 259 of 292 slots byte-identical
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
	ldw	(xsp+6), 0
	cpw	(xsp+20), 0
	jr	z, 12
	ld	xwa, (xsp+12)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	.byte 0xbf	; v10 does not spell this byte either
	ld	xwa, (xsp+12)
	.byte 0xb8	; v10 does not spell this byte either
	ld	xwa, 1058316221
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
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	subdm8	(10350), l
	incf
	ldb	w, 152
	ei	63
	ldb	c, 0
	jr	z, 30
	ld	xwa, (xsp+12)
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
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
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
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
	stw_da	(124220), wa
	ld	hl, (xsp+2)
	jrl	442
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	.byte 0xb8	; v10 does not spell this byte either
	ex_ff
	.byte 0xb9	; v10 does not spell this byte either
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
	.byte 0xf3	; v10 does not spell this byte either
	reti
	.byte 0xe0	; v10 does not spell this byte either
	.byte 0xe4	; v10 does not spell this byte either
	ldw	de, 3247
	ldb	w, 184
	pop	sr
	scc	nz, b
	.byte 0x9d	; v10 does not spell this byte either
	nop
	.byte 0x9f	; v10 does not spell this byte either
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
	call	16713148
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
	.byte 0x9f	; v10 does not spell this byte either
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
	cpl	qwa
	ld	bc, (xsp+22)
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
	.byte 0x98	; v10 does not spell this byte either
	.byte 0x06	; v10 does not spell this byte either
	push	xsp
	nop
	nop
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
	.byte 0xb8	; v10 does not spell this byte either
	pop	sr
	inc	6, b
	popw	sp
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x06	; v10 does not spell this byte either
	push	xsp
	nop
	nop
	jr	z, 28
	stib_dsp	232, 10
	ldw	(xsp+6), 0
	decm	1, (xsp+20)
	.byte 0x9f	; v10 does not spell this byte either
	ex_ff
	push	xsp
	nop
	nop
	jr	z, 95
	ldw	(xsp+20), 0
	lds	iz, 1
	jr	86
	ld	xwa, (xsp+16)
	.byte 0x80	; v10 does not spell this byte either
	push	xsp
	ldwio	110, 62736
	.byte 0xe8	; v10 does not spell this byte either
	nop
	decf
	lds32	xwa, 1
	add	(xsp+16), xwa
	.byte 0xbf	; v10 does not spell this byte either
	ei	2
	.byte 0x01	; v10 does not spell this byte either
	nop
	jr	15
	ld	xwa, (xsp+16)
	ldb_spi	c, 224
	lda_dpi	xhl, 232
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incw	1, (xsp+2)
	jr	42
	ld	xwa, (xsp+16)
	ldb_spi	c, 224
	ld	(xde), c
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incw	1, (xsp+2)
	ld	xwa, (xsp+12)
	ld	a, (xwa+2)
	cp_spib	a, 232
	jr	nz, 14
	.byte 0x9f	; v10 does not spell this byte either
	ex_ff
	push	xsp
	nop
	nop
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
	.byte 0xa8	; v10 does not spell this byte either
	ld	xsp, 2936759281
	incf
	ldb	w, 232
	.byte 0x89	; v10 does not spell this byte either
	ld	xwa, (xwa+22)
	ld	(xbc+71), xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	.byte 0xa8	; v10 does not spell this byte either
	ex_ff
	subdm8	(4462), l
	incf
	ldb	w, 168
	ldb	b, 32
	.byte 0xb8	; v10 does not spell this byte either
	ex_ff
	.byte 0xb3	; v10 does not spell this byte either
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	.byte 0x9f	; v10 does not spell this byte either
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
	pop	sr
	push	xsp
	nop
	jr	nz, 4
	lds	hl, 0
	jr	31
	.byte 0xbe
	pop	sr
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
	ldw	(xsp+6), 0
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+71)
	.byte 0xaf, 0x10, 0xf0
	jr	nc, 116
	ld	xwa, (xsp+12)
	.byte 0xb8, 0x03, 0xc9
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
	call	16712763
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
	.byte 0xb8, 0x03, 0xbf
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	z, 18
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	.byte 0x88, 0x16, 0x3c, 0xe7
	ld	xwa, (xsp+12)
	lds32	xbc, 0
	ld	(xwa+34), xbc
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+22), xbc
	lda	xwa, (135706:24)
	ld	xiz, xwa
	ldw	(xsp+4), 0
	.byte 0x9f, 0x04, 0x3f, 0x0a, 0x00
	jr	ge, 49
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	.byte 0x8e, 0x17, 0xf1
	jr	nz, 23
	ld	a, (xiz+22)
	and	a, 3
	cps	a, 3
	jr	nz, 13
	push	xiz
	calr	-7909
	inc	4, xsp
	or	(xsp+6), hl
	.byte 0x8e, 0x16, 0x3c, 0xe5
	incw	1, (xsp+4)
	lda	xiz, (xiz+538)
	.byte 0x9f, 0x04, 0x3f, 0x0a, 0x00
	jr	lt, -49
	ld	hl, (xsp+6)
	pop	xiz
	inc	4, xsp
	ret
SeqChan_ReadNextFromLoop:
	lda	xsp, (xsp-30)
	push	xiz
	ld	xiz, (xsp+38)
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x01, 0x00
	push	xiz
	calr	-6262
	inc	8, xsp
	ld	(xsp+4), hl
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jrl	nz, 136
	pushw 0
	push	xiz
	calr	-2087
	inc	6, xsp
	ld	(xsp+4), hl
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	nz, 117
	ld	xwa, (xiz+34)
	lda	xwa, (xwa+26)
	ld	(xsp+6), xwa
	pushw 228
	pushw 20522
	lda	xwa, (xsp+14)
	push	xwa
	call	16713584
	ld	(xsp+30), 16
	lda	xwa, (xsp+31)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call (xwa)
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
	.byte 0xb8, 0x16, 0xb9
	ld	xwa, (xiz+34)
	.byte 0xb8, 0x16, 0xb3
	lds32	xwa, 0
	ld	(xiz+71), xwa
	ld	(xiz+64), 16
	.byte 0xbe, 0x03, 0xbf
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
	lda	xde, (0x210b4:24)
	lds32	xwa, 0
	st_rrl xwa, xde, bc
	ld xwa, xiz
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
	pop	sr
	.byte 0xbf, 0xb9
	pop	sr
	.byte 0xbf
	lds	hl, 0
	jr	25
	push	xiz
	calr	61237
	inc	4, xsp
	ld	(xiz+52), 229
	.byte 0xbe
	pop	sr
	.byte 0xbf
	jr	-19
	stiw_da	(0x1e53c), 18
	ldw	hl, 0xffff
	pop	xiz
	ret

SeqStep_CountValidSectors:
	push xiz
	ldiw_erp 0xfa, 0
	stiw_da (0x01e53c), 0x0000
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
	inc1w_erp 0xfa

SeqStep_CountLoop_CheckEnd:
	cpw_da (0x1e53c), 0
	jr nz, SeqStep_CountLoop_ResetWerp
	ld xwa, (xsp + 8)
	cpw (xwa + 6), 0x0
	jr z, SeqStep_CountLoop_IncIz

SeqStep_CountLoop_ResetWerp:
	ldiw_erp 0xfa, 0
	jr SeqStep_CountLoop_Done

SeqStep_CountLoop_IncIz:
	inc 1, iz

SeqStep_CountLoop_Compare:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 30)
	cp iz, (xwa + 54)
	jr ule, SeqStep_CountLoop_Body

SeqStep_CountLoop_Done:
	stw_erp HL, 0xfa
	pop xiz
	ret

SeqStep_CalcTotalSectors:
	ld	xwa, (xsp+4)
	push	xwa
	calr	65455
	inc	4, xsp
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+40)
	extz	xwa
	call	16712319
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
	stiw_da	(0x1e53c), 13
	ldw	hl, 0xffff
	ret
	ld	wa, (xsp+10)
	ld	(xde+64), a
	.byte 0xba
	pop	sr
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
	call	16063039
	cps	hl, 0
	jr	z, 9
	call	16063021
	lds	hl, 6
	jrl	136
	call	16063045
	cps	l, 2
	jr	nz, 97
	.byte 0x9f, 0x0c, 0x3f, 0x00, 0x00
	jr	nz, 90
	.byte 0x9f, 0x0e, 0x3f, 0x00, 0x00
	jr	nz, 83
	.byte 0x9f, 0x10, 0x3f, 0x01, 0x00
	jr	nz, 76
	stdi16	35188, 65535
	push	xiz
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x01, 0x00, 0x0b, 0x00, 0x00, 0x0b, 0x00, 0x00
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 3
	calr	-176
	lda	xsp, (xsp+16)
	stdi16	35188, 0
	cps	hl, 0
	jr	nz, 8
	ld	(xiz+16), 2
	lds	hl, 0
	jr	52
	pushw 512
	pushw 228
	pushw 20536
	push	xiz
	call	16713148
	lda	xsp, (xsp+10)
	lds	hl, 0
	jr	31
	push	xiz
	.byte 0x9f, 0x16, 0x04, 0x9f, 0x16, 0x04, 0x9f, 0x14, 0x04, 0x9f, 0x18, 0x04
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
	push	sr
	nop
	nop
	cpw	(xbc), 0
	jr	nz, 5
	lds	hl, 0
	jrl	220
	incdi16_24	1, (0x2271e)
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
	ldw (xbc), 31
	lds	hl, 0
	jrl	170
	ld	xwa, (xiz)
	.byte 0xb8
	push	sr
	.byte 0xb3, 0xb1
	push	sr
	ldb	a, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65246
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	121
	.byte 0xbf, 0x04
	push	sr
	.byte 0x01
	nop
	jr	114
	ld	xwa, (xiz)
	.byte 0xb8
	push	sr
	.byte 0xb3, 0xb1
	push	sr
	di
	ld	xwa, (xiz)
	ld	xwa, (xwa+26)
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	4, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	82
	.byte 0xbf, 0x04
	push	sr
	.byte 0x01
	nop
	jr	75
	ld	xwa, (xiz)
	.byte 0xb8
	push	sr
	.byte 0xb3, 0xb1
	push	sr
	ldb	w, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65167
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	42
	lds	hl, 0
	jr	54
	ld	xwa, (xiz)
	.byte 0xb8
	push	sr
	.byte 0xb3, 0xb1
	push	sr
	ldb	d, 0
	ld	xwa, (xiz)
	push	xwa
	calr	65130
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cps	hl, 0
	jr	z, 5
	ld	(xiz+20), hl
	jr	5
	.byte 0xbf, 0x04
	push	sr
	.byte 0x01
	nop
	.byte 0xd2
	calr	551
	push	xsp
	normal
	nop
	jr	lt, 4
	lds	hl, 0
	jr	3
	ld	hl, (xsp+4)
	pop	xiz
	inc	2, xsp
	ret
SeqChan_ByteBlockE:
	; framing ported from v10's source for the same label (same span length, statement for statement); 116 of 134 slots byte-identical
	lda	xsp, (xsp-12)
	pushw	iz
	stiw_da	(141086), 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	de, 55121
	.byte 0xe6	; v10 does not spell this byte either
	.byte 0x88	; v10 does not spell this byte either
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16712763
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 55121
	.byte 0xe6	; v10 does not spell this byte either
	.byte 0x88	; v10 does not spell this byte either
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 48979
	ldio	83, 175
	ex_ff
	ldb	w, 168
	incf
	ldb	w, 232
	.byte 0xe0	; v10 does not spell this byte either
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	.byte 0x9f	; v10 does not spell this byte either
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
	.byte 0x98	; v10 does not spell this byte either
	rcf
	push	xsp
	nop
	nop
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldb	h, 65
	.byte 0xa2	; v10 does not spell this byte either
	.byte 0x81	; v10 does not spell this byte either
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	.byte 0x98	; v10 does not spell this byte either
	ldw	de, 26609
	.byte 0x8b	; v10 does not spell this byte either
	.byte 0xbf	; v10 does not spell this byte either
	ldwio	2, 0
	incw	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 32497
	jrl	c, -16385
	ei	2
	nop
	nop
	incw	1, (xsp+8)
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
	; framing ported from v10's source for the same label (same span length, statement for statement); 116 of 134 slots byte-identical
	lda	xsp, (xsp-12)
	pushw	iz
	stiw_da	(141086), 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	de, 55121
	.byte 0xe6	; v10 does not spell this byte either
	.byte 0x88	; v10 does not spell this byte either
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16712763
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 55121
	.byte 0xe6	; v10 does not spell this byte either
	.byte 0x88	; v10 does not spell this byte either
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 48979
	ldio	83, 175
	ex_ff
	ldb	w, 168
	incf
	ldb	w, 232
	.byte 0xe0	; v10 does not spell this byte either
	jrl	z, 148
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	.byte 0x9f	; v10 does not spell this byte either
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
	.byte 0x98	; v10 does not spell this byte either
	rcf
	push	xsp
	nop
	nop
	jr	z, 102
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	.byte 0x98	; v10 does not spell this byte either
	ldb	h, 65
	.byte 0xa2	; v10 does not spell this byte either
	.byte 0x81	; v10 does not spell this byte either
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	.byte 0x98	; v10 does not spell this byte either
	ldw	de, 26609
	.byte 0x8b	; v10 does not spell this byte either
	.byte 0xbf	; v10 does not spell this byte either
	ldwio	2, 0
	incw	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	.byte 0x98	; v10 does not spell this byte either
	ldw	ix, 32497
	jrl	c, -16385
	ei	2
	nop
	nop
	incw	1, (xsp+8)
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
	stb_da (0x03e3e4), a
	stiw_da (0x03e3e6), 0x0001
	stib_da (0x03e3be), 0x00
	ret

FDC_ClearDiskChangeStatus:
	stiw_da	(0x3e3e6), 0
	ldb_da	a, (0x3e3e4)
	stb_da	(0x3e3e2), a
	ret
	ldw_da	hl, (0x3e3e6)
	ret

FDC_ReadDiskType:
	ldb_da l, (0x03e3e4)
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
	stiw_da (0x01e53c), 0x001f
	ret

FDC_SectorLen_0x21:
	stiw_da (0x01e53c), 0x0021
	ret

FDC_SectorLen_0x06:
	stiw_da (0x01e53c), 0x0006
	ret

FDC_SectorLen_0x20:
	stiw_da (0x01e53c), 0x0020
	ret

FDC_SectorLen_0x24:
	stiw_da (0x01e53c), 0x0024
	ret

FDC_Format2DD_Start:
	lda xsp, (xsp - 20)
	pushw_erp 0xfa
	lds wa, 0
	calr FDC_SetSectorLength
	lda xwa, (Display_FontPalette_Table_0x21E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, FDC_Format2DD_Step2
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_Step2:
	lda xwa, (Display_FontPalette_Table_0x1FE:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, FDC_Format2DD_AllocBuf
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_AllocBuf:
	pushw	512
	call	16713379
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, 5
	lds	hl, 0
	jrl	891
FDC_Format2DD_WriteBoot:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	pushw	32
	lda	xwa, (14962870:24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713148
	ldw	(xsp+24), 4
	ldw	(xsp+26), 0
	ldw	(xsp+28), 0
	ldw	(xsp+30), 0
	ldw	(xsp+32), 1
	ldw	(xsp+34), 1
	ld	xwa, (xsp+20)
	ld	(xsp+36), xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+22)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51B78
	stb_erp	a, 251
	extz	wa
	calr	65266
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	782	; -> 0xF51E86
FDC_Format2DD_WriteFAT1:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	pushw	3
	lda	xwa, (14962902:24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713148
	ldw	(xsp+24), 4
	ldw	(xsp+26), 0
	ldw	(xsp+28), 0
	ldw	(xsp+30), 0
	ldw	(xsp+32), 2
	ldw	(xsp+34), 1
	ld	xwa, (xsp+20)
	ld	(xsp+36), xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+22)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51BE5
	stb_erp	a, 251
	extz	wa
	calr	65157
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	673	; -> 0xF51E86
FDC_Format2DD_WriteFAT2:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	ldw	(xsp+22), 3
	lda	xwa, (xsp+14)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+12)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51C22
	stb_erp	a, 251
	extz	wa
	calr	65096
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	612	; -> 0xF51E86
FDC_Format2DD_WriteRoot:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	ldw	(xsp+22), 4
	lda	xwa, (xsp+14)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+12)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51C5F
	stb_erp	a, 251
	extz	wa
	calr	65035
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	551	; -> 0xF51E86
FDC_Format2DD_WriteDataSec1:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	pushw	3
	lda	xwa, (14962902:24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713148
	ldw	(xsp+24), 4
	ldw	(xsp+26), 0
	ldw	(xsp+28), 0
	ldw	(xsp+30), 0
	ldw	(xsp+32), 5
	ldw	(xsp+34), 1
	ld	xwa, (xsp+20)
	ld	(xsp+36), xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+22)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51CCC
	stb_erp	a, 251
	extz	wa
	calr	64926
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	442	; -> 0xF51E86
FDC_Format2DD_WriteDataSec2:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	ldw	(xsp+22), 6
	lda	xwa, (xsp+14)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+12)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51D09
	stb_erp	a, 251
	extz	wa
	calr	64865
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	381	; -> 0xF51E86
FDC_Format2DD_WriteDataSec3:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	ldw	(xsp+22), 7
	lda	xwa, (xsp+14)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+12)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51D46
	stb_erp	a, 251
	extz	wa
	calr	64804
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	320	; -> 0xF51E86
FDC_Format2DD_InitTrackLoop:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	inc	8, xsp
	ldw	(xsp+6), 4
	ldw	(xsp+8), 0
	ldw	(xsp+10), 0
	ldw	(xsp+12), 0
	ldw	(xsp+16), 1
	ld	xwa, (xsp+2)
	ld	(xsp+18), xwa
	ldw	(xsp+14), 8
	jr	44	; -> 0xF51DA8
FDC_Format2DD_TrackBody:
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	inc	4, xsp
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51DA5
	stb_erp	a, 251
	extz	wa
	calr	64709
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	225	; -> 0xF51E86
FDC_Format2DD_TrackInc:
	incw 1, (xsp + 14)

FDC_Format2DD_TrackTest:
	cpw (xsp + 14), 0x9
	jr ule, FDC_Format2DD_TrackBody
	ldw (xsp + 10), 0x1
	ldw (xsp + 14), 0x1
	jr FDC_Format2DD_Side1Test

FDC_Format2DD_Side1Body:
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	inc	4, xsp
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51DE4
	stb_erp	a, 251
	extz	wa
	calr	64646
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	162	; -> 0xF51E86
FDC_Format2DD_Side1Inc:
	incw 1, (xsp + 14)

FDC_Format2DD_Side1Test:
	.byte 0x9f, 0x0e, 0x3f, 0x05, 0x00, 0x63, 0xcd, 0xbf
	.byte 0x06, 0x02, 0x03, 0x00, 0xbf, 0x08, 0x02, 0x00
	.byte 0x00, 0xbf, 0x0a, 0x02, 0x00, 0x00, 0xbf, 0x0c
	.byte 0x02, 0x4f, 0x00, 0xbf, 0x0e, 0x02, 0x09, 0x00
	.byte 0xbf, 0x10, 0x02, 0x01, 0x00, 0xaf, 0x02, 0x20
	.byte 0xbf, 0x12, 0x60, 0xbf, 0x06, 0x30, 0x38, 0x1d
	.byte 0xbd, 0x78, 0xf9, 0xef, 0x64, 0xc7, 0xfb, 0x9f
	.byte 0xc7, 0xfb, 0xd8, 0x66, 0x16, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0x1e, 0x2f, 0xfc, 0xaf, 0x02, 0x20
	.byte 0x38, 0x1d, 0x15, 0x03, 0xff, 0xef, 0x64, 0xdb
	.byte 0xa8, 0x68, 0x4c
FDC_Format2DD_FinalTrack:
	ldw	(xsp+6), 3
	ldw	(xsp+8), 0
	ldw	(xsp+10), 0
	ldw	(xsp+12), 0
	ldw	(xsp+14), 9
	ldw	(xsp+16), 1
	ld	xwa, (xsp+2)
	ld	(xsp+18), xwa
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	ldb_erp	l, 251
	ld	xwa, (xsp+6)
	push	xwa
	call	16712469
	inc	8, xsp
	cpib_erp	251, 0
	jr	nz, 4	; -> 0xF51E7C
	lds	hl, 1
	jr	10	; -> 0xF51E86
FDC_Format2DD_SetSectorAndRet:
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FDC_CmdFrame_Epilogue:
	popw_erp 0xfa
	lda xsp, (xsp + 20)
	ret

FDC_Format2HD_Start:
	lda xsp, (xsp - 20)
	pushw_erp 0xfa
	lds wa, 0
	calr FDC_SetSectorLength
	lda xwa, (Display_FontPalette_Table_0x23E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, FDC_Format2HD_Step2
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_Step2:
	lda xwa, (Display_FontPalette_Table_0x1FE:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldb_erp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, FDC_Format2HD_AllocBuf
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0
	jrl FdcOp_Epilogue20

FDC_Format2HD_AllocBuf:
	pushw	512
	call	16713379
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, 5
	lds	hl, 0
	jrl	752
FDC_Format2HD_WriteBoot:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	pushw	32
	lda	xwa, (14962906:24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713148
	ldw	(xsp+24), 4
	ldw	(xsp+26), 0
	ldw	(xsp+28), 0
	ldw	(xsp+30), 0
	ldw	(xsp+32), 1
	ldw	(xsp+34), 1
	ld	xwa, (xsp+20)
	ld	(xsp+36), xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+22)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51F5E
	stb_erp	a, 251
	extz	wa
	calr	64268
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	643	; -> 0xF521E1
FDC_Format2HD_WriteFAT1:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	pushw	3
	lda	xwa, (14962938:24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713148
	ldw	(xsp+24), 4
	ldw	(xsp+26), 0
	ldw	(xsp+28), 0
	ldw	(xsp+30), 0
	ldw	(xsp+32), 2
	ldw	(xsp+34), 1
	ld	xwa, (xsp+20)
	ld	(xsp+36), xwa
	lda	xwa, (xsp+24)
	push	xwa
	call	FDC_CommandEntry
	lda	xsp, (xsp+22)
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF51FCB
	stb_erp	a, 251
	extz	wa
	calr	64159
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	534	; -> 0xF521E1
FDC_Format2HD_InitTrackLoop:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	inc	8, xsp
	ldw	(xsp+14), 3
	jr	44	; -> 0xF5200E
FDC_Format2HD_TrackBody:
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	inc	4, xsp
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF5200B
	stb_erp	a, 251
	extz	wa
	calr	64095
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	470	; -> 0xF521E1
FDC_Format2HD_TrackInc:
	incw 1, (xsp + 14)

FDC_Format2HD_TrackTest:
	.byte 0x9f, 0x0e, 0x3f, 0x0a, 0x00, 0x63, 0xcd, 0x0b
	.byte 0x00, 0x02, 0x0b, 0x00, 0x00, 0xaf, 0x06, 0x20
	.byte 0x38, 0x1d, 0x1d, 0x08, 0xff, 0x0b, 0x03, 0x00
	.byte 0xf2, 0xfa, 0x50, 0xe4, 0x30, 0x38, 0xaf, 0x10
	.byte 0x20, 0x38, 0x1d, 0xbc, 0x05, 0xff, 0xbf, 0x18
	.byte 0x02, 0x04, 0x00, 0xbf, 0x1a, 0x02, 0x00, 0x00
	.byte 0xbf, 0x1c, 0x02, 0x00, 0x00, 0xbf, 0x1e, 0x02
	.byte 0x00, 0x00, 0xbf, 0x20, 0x02, 0x0b, 0x00, 0xbf
	.byte 0x22, 0x02, 0x01, 0x00, 0xaf, 0x14, 0x20, 0xbf
	.byte 0x24, 0x60, 0xbf, 0x18, 0x30, 0x38, 0x1d, 0xbd
	.byte 0x78, 0xf9, 0xbf, 0x16, 0x37, 0xc7, 0xfb, 0x9f
	.byte 0xc7, 0xfb, 0xd8, 0x66, 0x17, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0x1e, 0xe8, 0xf9, 0xaf, 0x02, 0x20
	.byte 0x38, 0x1d, 0x15, 0x03, 0xff, 0xef, 0x64, 0xdb
	.byte 0xa8, 0x78, 0x5f, 0x01
FDC_Format2HD_WriteFAT2:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	inc	8, xsp
	ldw	(xsp+14), 12
	jr	44	; -> 0xF520C5
FDC_Format2HD_Side2Body:
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	inc	4, xsp
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF520C2
	stb_erp	a, 251
	extz	wa
	calr	63912
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	287	; -> 0xF521E1
FDC_Format2HD_Side2Inc:
	incw 1, (xsp + 14)

FDC_Format2HD_Side2Test:
	.byte 0x9f, 0x0e, 0x3f, 0x12, 0x00, 0x63, 0xcd, 0xbf
	.byte 0x0a, 0x02, 0x01, 0x00, 0xbf, 0x0e, 0x02, 0x01
	.byte 0x00, 0xbf, 0x06, 0x30, 0x38, 0x1d, 0xbd, 0x78
	.byte 0xf9, 0xef, 0x64, 0xc7, 0xfb, 0x9f, 0xc7, 0xfb
	.byte 0xd8, 0x66, 0x17, 0xc7, 0xfb, 0x89, 0xd8, 0x12
	.byte 0x1e, 0x6b, 0xf9, 0xaf, 0x02, 0x20, 0x38, 0x1d
	.byte 0x15, 0x03, 0xff, 0xef, 0x64, 0xdb, 0xa8, 0x78
	.byte 0xe2, 0x00
FDC_Format2HD_InitSide1Loop:
	pushw	512
	pushw	0
	ld	xwa, (xsp+6)
	push	xwa
	call	16713757
	inc	8, xsp
	ldw	(xsp+14), 2
	jr	44	; -> 0xF52142
FDC_Format2HD_Side1Body:
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	inc	4, xsp
	ldb_erp	l, 251
	cpib_erp	251, 0
	jr	z, 23	; -> 0xF5213F
	stb_erp	a, 251
	extz	wa
	calr	63787
	ld	xwa, (xsp+2)
	push	xwa
	call	16712469
	inc	4, xsp
	lds	hl, 0
	jrl	162	; -> 0xF521E1
FDC_Format2HD_Side1Inc:
	incw 1, (xsp + 14)

FDC_Format2HD_Side1Test:
	.byte 0x9f, 0x0e, 0x3f, 0x0f, 0x00, 0x63, 0xcd, 0xbf
	.byte 0x06, 0x02, 0x03, 0x00, 0xbf, 0x08, 0x02, 0x00
	.byte 0x00, 0xbf, 0x0a, 0x02, 0x00, 0x00, 0xbf, 0x0c
	.byte 0x02, 0x4f, 0x00, 0xbf, 0x0e, 0x02, 0x12, 0x00
	.byte 0xbf, 0x10, 0x02, 0x01, 0x00, 0xaf, 0x02, 0x20
	.byte 0xbf, 0x12, 0x60, 0xbf, 0x06, 0x30, 0x38, 0x1d
	.byte 0xbd, 0x78, 0xf9, 0xef, 0x64, 0xc7, 0xfb, 0x9f
	.byte 0xc7, 0xfb, 0xd8, 0x66, 0x16, 0xc7, 0xfb, 0x89
	.byte 0xd8, 0x12, 0x1e, 0xd4, 0xf8, 0xaf, 0x02, 0x20
	.byte 0x38, 0x1d, 0x15, 0x03, 0xff, 0xef, 0x64, 0xdb
	.byte 0xa8, 0x68, 0x4c
FDC_Format2HD_FinalTrack:
	ldw	(xsp+6), 3
	ldw	(xsp+8), 0
	ldw	(xsp+10), 0
	ldw	(xsp+12), 0
	ldw	(xsp+14), 18
	ldw	(xsp+16), 1
	ld	xwa, (xsp+2)
	ld	(xsp+18), xwa
	lda	xwa, (xsp+6)
	push	xwa
	call	FDC_CommandEntry
	ldb_erp	l, 251
	ld	xwa, (xsp+6)
	push	xwa
	call	16712469
	inc	8, xsp
	cpib_erp	251, 0
	jr	nz, 4	; -> 0xF521D7
	lds	hl, 1
	jr	10	; -> 0xF521E1
FDC_Format2HD_SetSectorAndRet:
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	lds hl, 0

FdcOp_Epilogue20:
	popw_erp 0xfa
	lda xsp, (xsp + 20)
	ret

GetMediaType:
	lda xsp, (xsp - 0x14)
	push QIZ
	call Reset_Floppy_Disk_Controller
	pushw 0x0400
	call 0xff06a3
	inc 2,XSP
	ld (XSP+0x02),XHL
	ld XWA,XHL
	or XWA,XWA
	jr nz, .Lc_f52218
	lds_erpb 0xfb, 0
	ld_erpb_rr a, 0xfb
	extz WA
	pushw wa
	calr FDC_StoreDiskType
	inc 2,XSP
	ld_erpb_rr l, 0xfb
	jrl t, GetMediaType_ReturnAndCleanup
GetMediaType_SetupReadCmd:
.Lc_f52218:
	ldw (XSP+0x06), 0x0003
	ldw (XSP+0x08), 0x0000
	ldw (XSP+0x0a), 0x0000
	ldw (XSP+0x0c), 0x0000
	ldw (XSP+0x0e), 0x0002
	ldw (XSP+0x10), 0x0001
	ld XWA,(XSP+0x02)
	ld (XSP+0x12),XWA
	stdi16 (0x8974), 0xffff
	lds_erpb 0xfb, 0
	call Check_for_Floppy_Disk_Change
	cps l, 0
	jr nz, GetMediaType_TryRecalib
	lds_erpb 0xfb, 1
	jrl t, GetMediaType_Epilogue
GetMediaType_TryRecalib:
	lda xwa, (Display_FontPalette_Table_0x24E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_TryFormat2HD
	ldib_erp 0xfb, 0
	jrl GetMediaType_Epilogue

GetMediaType_TryFormat2HD:
	lda xwa, (Display_FontPalette_Table_0x23E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_ReadSector
	ldib_erp 0xfb, 0
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
	ldib_erp 0xfb, 3
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
	ldib_erp 0xfb, 3
	jr GetMediaType_Epilogue

GetMediaType_Invalid:
	ldib_erp 0xfb, 0
	jr GetMediaType_Epilogue

GetMediaType_Try2DDHeader:
	lda xwa, (Display_FontPalette_Table_0x21E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cps hl, 0
	jr z, GetMediaType_Read2DDSector
	ldib_erp 0xfb, 0
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
	ldib_erp 0xfb, 6
	jr GetMediaType_Epilogue

GetMediaType_F9Check:
	ld xwa, (xsp + 2)
	cp (xwa), 0xf9
	jr nz, GetMediaType_CheckExtraFormat
	ldib_erp 0xfb, 2
	jr GetMediaType_Epilogue

GetMediaType_CheckExtraFormat:
	call FDC_DetectDiskFormat
	cps hl, 0
	jr nz, GetMediaType_Epilogue
	ldib_erp 0xfb, 5

GetMediaType_Epilogue:
	stdi16 (35188), 0

	ld xwa, (xsp + 2)

	push xwa

	call	16712469

	stb_erp A, 0xfb

	extz wa

	pushw wa

	calr 63190

	inc 6, xsp

	stb_erp L, 0xfb



GetMediaType_ReturnAndCleanup:
	popw_erp 0xfa
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
	lda xix, (Display_FontPalette_Table_0x2AC:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (GetDiskFreeSpace_JumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	lda xix, (Display_FontPalette_Table_0x2C0:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (GetVolumeLabel_JumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

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
	lda	xwa, (xsp+4)
	push	xwa
	lda	xwa, (xsp+40)
	push	xwa
	call	16053845
	inc	8, xsp
	.byte 0xbf, 0x30, 0xc9
	jr	nz, 55
	.byte 0x8f, 0x24, 0x3f, 0xe5
	jr	z, 49
	.byte 0x8f, 0x24, 0x3f, 0x00
	jr	z, 65
	.byte 0xbf, 0x30, 0xcb
	jr	z, 38
	pushw 11
	lda	xwa, (xsp+38)
	push	xwa
	lda	xwa, (141088:24)
	push	xwa
	call	16713148
	stib_da	141099, 0
	push	xiz
	call	16051286
	lda	xsp, (xsp+14)
	lda	xhl, (141088:24)
	jr	31
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
	ld	(xsp+6), 0
	pushw	228
	pushw	20774
	lda	xwa, (xsp+10)
	push	xwa
	call	16713188
	ld	xwa, xiz
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	16713188
	pushw	228
	pushw	20778
	lda	xwa, (xsp+26)
	push	xwa
	call	16050067
	add	xsp, 24
	or	xhl, xhl
	jr	nz, 4
	lds	hl, 0
	jr	31
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
	.byte 0xa6, 0x20, 0x80, 0x3f, 0x5c, 0x6e, 0x48, 0xbf
	.byte 0x04, 0x30, 0xf3, 0x07, 0xe0, 0xe8, 0x00, 0x00
	.byte 0xaf, 0x12, 0x20, 0x80, 0x3f, 0x00, 0x66, 0x10
	.byte 0x0b, 0xe4, 0x00, 0x0b, 0x2e, 0x51, 0xaf, 0x16
	.byte 0x20, 0x38, 0x1d, 0xe4, 0x05, 0xff, 0xef, 0x60
FileIO_ParseLoop_AppendSlash:
	lda	xwa, (xsp+4)
	push	xwa
	ld	xwa, (xsp+22)
	push	xwa
	call	16713188
	inc	8, xsp
	lds	de, 0
	ld	xwa, (xiz)
	inc	1, xwa
	ld	xhl, xwa
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
	stb_dri A, 0x07, 0xe4, 0xe8
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
	cpib_da (0x03e3e4), 0x05
	jr nz, FindFirst_AllocHandle
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	calr FindFirst_SndTable
	jrl FdcFile_Epilogue20

FindFirst_AllocHandle:
	pushw	8
	call	16713379
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, 8
	ld	xhl, 4294967295
	jrl	227
FindFirst_AllocPathBuf:
	pushw	260
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 18
	ld	xwa, (xsp+8)
	push	xwa
	call	16712469
	inc	4, xsp
	ld	xhl, 4294967295
	jrl	194
FindFirst_ParseAndOpen:
	ld	xwa, (xsp+20)
	ld	(xsp+12), xwa
	ld	xwa, xiz
	lda	xbc, (xsp+12)
	calr	65305
	cps	hl, 0
	jr	z, 25
	ld	xwa, (xsp+8)
	push	xwa
	call	16712469
	ld	xwa, xiz
	push	xwa
	call	16712469
	inc	8, xsp
	ld	xhl, 4294967295
	jrl	151
FindFirst_OpenDir:
	pushw	228
	pushw	20784
	ld	xwa, xiz
	push	xwa
	call	16050067
	inc	8, xsp
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, 24
	ld	xwa, (xsp+8)
	push	xwa
	call	16712469
	ld	xwa, xiz
	push	xwa
	call	16712469
	inc	8, xsp
	ld	xhl, 4294967295
	jr	102
FindFirst_AllocPattern:
	ld	xwa, xiz
	push	xwa
	call	16712469
	ld	xwa, (xsp+16)
	push	xwa
	call	16713667
	inc	1, hl
	pushw	hl
	call	16713379
	lda	xsp, (xsp+10)
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, 17
	ld	xwa, (xsp+8)
	push	xwa
	call	16712469
	inc	4, xsp
	ld	xhl, 4294967295
	jr	54
FindFirst_CopyAndSearch:
	ld	xwa, (xsp+12)
	push	xwa
	push	xiz
	call	16713584
	inc	8, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+4), xiz
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+4)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+16)
	calr	87
	cps	hl, 0
	jr	nz, 5
	ld	xhl, (xsp+8)
	jr	11
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
	cpib_da (0x03e3e4), 0x05
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
	ld	xwa, xiz
	ld	xwa, (xwa)
	push	xwa
	call	16051286
	ld	xwa, xiz
	ld	xwa, (xwa+4)
	push	xwa
	call	16712469
	ld	xwa, xiz
	push	xwa
	call	16712469
	lda	xsp, (xsp+12)
	lds	hl, 0
FindClose_Return:
	pop xiz
	ret

_findnext:
	lda xsp, (xsp - 64)
	push xiz
	ld xiz, xbc
	cpib_da (0x03e3e4), 0x05
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
	.byte 0xbf, 0x0c, 0x30, 0x38, 0xbf, 0x30, 0x30, 0x38
	.byte 0x1d, 0x55, 0xf6, 0xf4, 0xef, 0x60, 0x8f, 0x2c
	.byte 0x3f, 0xe5, 0x66, 0x53, 0x8f, 0x2c, 0x3f, 0x00
	.byte 0x66, 0x66, 0xbf, 0x38, 0xcb, 0x6e, 0x48, 0xbf
	.byte 0x2c, 0x30, 0xaf, 0x08, 0x21, 0xa9, 0x04, 0x21
	.byte 0x1e, 0x5d, 0x00, 0xdb, 0xd9, 0x6e, 0x38, 0x0b
	.byte 0x08, 0x00, 0xbf, 0x2e, 0x30, 0x38, 0xbe, 0x06
	.byte 0x30, 0x38, 0x1d, 0xbc, 0x05, 0xff, 0xbe, 0x0e
	.byte 0x00, 0x2e, 0x0b, 0x03, 0x00, 0xbf, 0x40, 0x30
	.byte 0x38, 0xbe, 0x0f, 0x30, 0x38, 0x1d, 0xbc, 0x05
	.byte 0xff, 0xbf, 0x14, 0x37, 0xbe, 0x12, 0x00, 0x00
	.byte 0xaf, 0x3f, 0x20, 0xbe, 0x02, 0x60, 0x8f, 0x38
	.byte 0x21, 0xb6, 0x41, 0xdb, 0xa8, 0x68, 0x1c
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
	.byte 0x0b, 0x0b, 0x00, 0x0b, 0x3f, 0x00, 0xbf, 0x08
	.byte 0x30, 0x38, 0x1d, 0x1d, 0x08, 0xff, 0xef, 0x60
	.byte 0xbf, 0x0f, 0x00, 0x00, 0xbf, 0x04, 0x30, 0xe8
	.byte 0x89, 0x86, 0x3f, 0x00, 0x66, 0x19
WildMatch_ScanLoop:
	cp (xiz), 0x2e
	jr nz, WildMatch_CopyChar
	lda xwa, (xsp + 12)
	ld xbc, xwa
	inc 1, xiz
	jr WildMatch_CheckEnd

WildMatch_CopyChar:
	ldb_spi A, 0xf8
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
	cpib_sri 0x07, 0xe0, 0xe4, 0x2a
	jr nz, WildMatch_NameNext
	cp bc, 0x8
	jr ge, WildMatch_NameNext

WildMatch_StarFillName:
	lda xwa, (xsp + 4)
	stib_ind 0x07, 0xe0, 0xe4, 0x3f
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
	cpib_sri 0x07, 0xe0, 0xe4, 0x2a
	jr nz, WildMatch_ExtNext
	cp bc, 0xb
	jr ge, WildMatch_ExtNext

WildMatch_StarFillExt:
	lda xwa, (xsp + 4)
	stib_ind 0x07, 0xe0, 0xe4, 0x3f
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
	stiw_da (0x02272c), 0x0000
	lda xwa, (0x02272c:24)
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
	.byte 0xe8, 0x8e, 0x96, 0x3f, 0x50, 0x00, 0x69, 0x59
	.byte 0x96, 0x20, 0xd8, 0x09, 0x2c, 0x00, 0xf2, 0xa8
	.byte 0x35, 0x02, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3f
	.byte 0xfe, 0xfe, 0x66, 0x45, 0x0b, 0x14, 0x00, 0x96
	.byte 0x20, 0xd8, 0x09, 0x2c, 0x00, 0xf2, 0x8e, 0x35
	.byte 0x02, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0x38, 0xaf
	.byte 0x0a, 0x20, 0xe8, 0x66, 0x38, 0x1d, 0xbc, 0x05
	.byte 0xff, 0xbf, 0x0a, 0x37, 0xaf, 0x04, 0x20, 0xb8
	.byte 0x1a, 0x00, 0x00, 0x96, 0x20, 0xd8, 0x09, 0x2c
	.byte 0x00, 0xf2, 0xa6, 0x35, 0x02, 0x31, 0xd3, 0x07
	.byte 0xe4, 0xe0, 0x21, 0xe9, 0x12, 0xaf, 0x04, 0x20
	.byte 0xb8, 0x02, 0x61, 0x96, 0x61, 0xdb, 0xa8, 0x68
	.byte 0x03
FileIO_ReadDirEntry_End:
	ldw hl, 0xffff

FileIO_ReadDirEntry_Return:
	pop xiz
	inc 4, xsp
	ret

SndTable_ByteBlock_ReadOps:
	.byte 0xc2
	or	xhl, xix
	pop	sr
	push	xsp
	nop
	jr	nz, 48
	ldl_da	xbc, (0x2357a)
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
	ldl_da	xwa, (0x2357a)
	ld	wa, (xwa+6)
	and	wa, 0x7fff
	jr	nz, 3
	lds	hl, 0
	ret
	ldw	hl, 0xffff
	ret
	.byte 0xc2
	or	xhl, xix
	pop	sr
	push	xsp
	normal
	jr	nz, 6
	calr	759
	extz	hl
	ret
	ldw	hl, 0xffff
	ret
	dec	2, xsp
	push	xiz
	stib_da	(0x2357e), 1
	ldl_da	xwa, (0x3e3e8)
	stl_da	(0x2272e), xwa
	ldl_da	xwa, (0x3e3ee)
	ldw	(xwa+2), 0
	ldl_da	xwa, (0x3e3ee)
	.byte 0xf3, 0xe1
	ei	4
	push	sr
	nop
	nop
	ldl_da	xbc, (0x3e3ee)
	lds	wa, 2
	call	TaskMsg_Send
	ldl_da	xwa, (0x3e3ee)
	lda	xwa, (xwa+1028)
	ld	xbc, xwa
	lds	wa, 2
	call	TaskMsg_Send
	.byte 0xbf, 0x04
	push	sr
	nop
	nop
	ld	wa, (xsp+4)
	extz	xwa
	cpda32_24 xwa, (141102)
	jrl	ugt, 134
	lds	wa, 2
	call	TaskMsg_Receive
	ld	xiz, xhl
	.byte 0x9e
	push	sr
	push	xsp
	nop
	nop
	jr	z, 17
	ldw (xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	jr	102
	lda	xwa, (xiz+4)
	calr	65336
	cps	hl, 0
	jr	z, 21
	ldw (xiz), 0
	ldw (xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	jr	71
	.byte 0xb6
	push	sr
	nop
	.byte 0x04
	ld	wa, (xsp+4)
	extz	xwa
	ldl_da	xbc, (0x2272e)
	sub	xbc, xwa
	cp	xbc, 1024
	jr	ugt, 14
	ld	wa, (xsp+4)
	extz	xwa
	ldl_da	xbc, (0x2272e)
	sub	xbc, xwa
	ld	(xiz), bc
	ldw (xiz+2), 0
	ld	xwa, xiz
	ld	xbc, xwa
	lds	wa, 3
	call	TaskMsg_Send
	.byte 0x9f, 0x04
	push	xwa
	nop
	max
	ld	wa, (xsp+4)
	extz	xwa
	cpda32_24 xwa, (141102)
	jrl	ule, -134
	stib_da	(0x2357e), 0
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
	cpib_da (0x02358a), 0x01
	jrl nz, TaskBuf_Error
	cpw_da (0x23580), 0
	jr nz, TaskBuf_CheckPendingData
	lds wa, 3
	call TaskMsg_Receive
	stl_da (0x023582), xhl
	ld wa, (xhl)
	stw_da (0x023580), xwa
	ldl_da xwa, (0x023582)
	inc 4, xwa
	stl_da (0x023586), xwa

TaskBuf_CheckPendingData:
	ldl_da xwa, (0x023582)
	cpw (xwa + 2), 0x0
	jr z, TaskBuf_EmptyAndReturn
	stib_da (0x02358a), 0x02
	ldl_da xwa, (0x023582)
	ld hl, (xwa + 2)
	jr TaskBuf_PopIzRet

TaskBuf_EmptyAndReturn:
	cpw_da (0x23580), 0
	jr nz, TaskBuf_ReadAndDecrement
	stib_da (0x02358a), 0x02
	ldw hl, 0xffff
	jr TaskBuf_PopIzRet

TaskBuf_ReadAndDecrement:
	ldl_da xbc, (0x023586)
	lds32 xwa, 1
	addl_da 0x023586, xwa
	ld a, (xbc)
	ldb_erp A, 0xf8
	extz iz
	subdi16_24 (0x23580), 1
	jr nz, TaskBuf_ReturnByte
	ldl_da xwa, (0x023582)
	cpw (xwa), 0x400
	jr z, TaskBuf_SendBufferFull
	stib_da (0x02358a), 0x02
	ld hl, iz
	jr TaskBuf_PopIzRet

TaskBuf_SendBufferFull:
	ldl_da xbc, (0x023582)
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
	ldl_da xwa, (0x023582)
	ldw (xwa + 2), 0xffff
	ldl_da xbc, (0x023582)
	lds wa, 2
	call TaskMsg_Send
	cpib_da (0x02357e), 0x00
	jr z, FDC_DrainQueue3_Start

FDC_WaitQueueEmpty_Loop:
	cpib_da (0x02357e), 0x00
	jr nz, FDC_WaitQueueEmpty_Loop

FDC_DrainQueue3_Start:
	stib_da (0x02358a), 0x02
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
	cpib_da (0x03e3ec), 0x00
	ret nz
	ldl_da xwa, (0x02357a)
	push xwa
	call FileClose
	inc 4, xsp
	ret

SndTable_LookupA:
	stib_da (0x03e3ec), 0x00
	stiw_da (0x023580), 0x0000
	stib_da (0x02358a), 0x01
	lda xbc, (0x022d72:24)
	stl_da (0x03e3ee), xbc
	pushw 0xe4
	pushw 0x5132
	push xwa
	call FileOpen
	inc 8, xsp
	stl_da (0x02357a), xhl
	ldl_da xwa, (0x02357a)
	or xwa, xwa
	jr nz, SndTable_LookupA_GotFile
	stib_da (0x02358a), 0x02
	ldw hl, 0xffff
	ret

SndTable_LookupA_GotFile:
	ldl_da xwa, (0x02357a)
	ld xwa, (xwa + 71)
	stl_da (0x03e3e8), xwa
	lds wa, 2
	call Show_ScreenGroup
	lds hl, 0
	ret

SndTable_CalcSectorPosition:
	ld hl, wa
	extz xhl
	div hl, 0x9
	stw_erp HL, 0xee
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
	ldw_da	wa, (0x2358c)
	ld	xbc, xiz
	calr	65445
	incdi16_24	1, (0x2358c)
	cps	hl, 0
	jr	nz, 22
	ldw_da	de, (0x2358c)
	lda	xwa, (xiz+512)
	ld	xbc, xwa
	ld	wa, de
	calr	65419
	incdi16_24	1, (0x2358c)
	pop	xiz
	ret

SndTable_LookupB:
	jrl TaskBuf_ReadNextByte

SndTable_LookupC:
	calr FDC_DrainQueuesAndReset
	stib_da (0x03e3ec), 0x00
	jrl FDC_RecalibrateCommand

SndTable_LookupD_CalcAddr:
	ld bc, wa
	muls bc, 0x2c
	lda xde, (0x0235a8:24)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	stw_da (0x02358c), xbc
	muls wa, 0x2c
	lda xbc, (0x0235a6:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	stw_da (0x02474e), xwa
	ldw_da xwa, (0x02474e)
	extz xwa
	sll xwa, 9
	stl_da (0x03e3e8), xwa
	lds hl, 0
	ret

SndTable_LookupD:
	stib_da (0x03e3ec), 0x01
	stiw_da (0x023580), 0x0000
	stib_da (0x02358a), 0x01
	lda xbc, (0x022d72:24)
	stl_da (0x03e3ee), xbc
	calr SndTable_LookupD_CalcAddr
	cps l, 0
	jr z, SndTable_LookupD_ShowScreen
	stib_da (0x02358a), 0x02
	stib_da (0x03e3ec), 0x00
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
	lda xwa, (0x02434e:24)
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
	pushw	11
	pushw	228
	pushw	20790
	lda	xwa, (148302:24)
	push	xwa
	call	16712932
	add	xsp, 10
	cps	hl, 0
	jr	nz, 3
	lds	hl, 0
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
	lda xwa, (0x02358e:24)
	add xwa, xbc
	ld xbc, xwa
	ld wa, de
	calr FDC_ExecuteSectorCommand
	ldw_erp HL, 0xfa
	calr FDC_RecalibrateCommand
	cpiw_erp 0xfa, 0
	jr z, FileIO_ReadDir_NextSector
	stw_erp HL, 0xfa
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
	.byte 0xde, 0x88, 0xd8, 0x09, 0x2c, 0x00, 0xf2, 0xa8
	.byte 0x35, 0x02, 0x31, 0xd3, 0x07, 0xe4, 0xe0, 0x3f
	.byte 0xfe, 0xfe, 0x66, 0x32, 0x0b, 0x14, 0x00, 0xde
	.byte 0x88, 0xd8, 0x09, 0x2c, 0x00, 0xf2, 0x8e, 0x35
	.byte 0x02, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0x38, 0xde
	.byte 0x88, 0xd8, 0x09, 0x14, 0x00, 0xf2, 0x32, 0x27
	.byte 0x02, 0x31, 0xe8, 0x13, 0xe9, 0x80, 0x38, 0x1d
	.byte 0xbc, 0x05, 0xff, 0xbf, 0x0a, 0x37, 0xde, 0x61
	.byte 0xde, 0xcf, 0x50, 0x00, 0x61, 0xba
FileIO_FillRemainingEntries:
	stw_da (0x024750), xiz
	cp iz, 0x50
	jr ge, FileIO_ReadDir_GetRetVal

FileIO_FillRemaining_Loop:
	pushw	20
	pushw	32
	ld	wa, iz
	muls	wa, 20
	lda	xbc, (141106:24)
	exts	xwa
	add	xwa, xbc
	push	xwa
	call	16713757
	inc	8, xsp
	inc	1, iz
	cp	iz, 80
	jr	lt, -36
FileIO_ReadDir_GetRetVal:
	stw_erp HL, 0xfa

FileIO_ReadDir_Return:
	pop xiz
	ret

SeqByteBlock_DispatchJumpTable:
	.long SeqDispatch_ResetAndValidate
	.long SeqDispatch_ReturnNop
	.long SeqDispatch_InitWithPayload
	.long SeqDispatch_ReturnNop
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
	.byte 0xc1, 0x57, 0x32, 0x3c, 0xfe	; anddi8 (0x32f3), 254 (v7 patched)

	ret



SeqDispatch_TrampolineBlock:
	jp	SeqDispatch_TrampolineBlock_0xB
	ret
	jp	SeqDispatch_TrampolineBlock_0xC
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
	jp	AccStyle_TempoLookupData_0x6

Seq_DispatcherTick:
	cp (0x8c9a:16), 0x10
	jr c, .Lc_f52f24
	cp (0x8c9a:16), 0x16
	jr ugt, .Lc_f52f24
	jr t, Seq_DispatcherTickReturn
Seq_DispatcherTick_Process:
.Lc_f52f24:
	call RhythmROM_CheckValid
	cps c, 0
	jr nz, Seq_DispatcherTickReturn
	calr SeqTick_ReadControlState
	call Seq_ReadTempoLookup
	calr Seq_ProcessAllInputState
	call Rhythm_CompareAndTrigger
	anddi8 (0x3258), 0x9f
	call AccTick_Main
	ld a, (0x3258:16)
	and A,0x60
	call Rhythm_SaveState
	call Seq_RhythmProcessor
	call Rhythm_AdvanceTick
	call AccDir_Entry
	call AccStyle_Entry
	call AccProcess_Entry
Seq_DispatcherTickReturn:
	ret

SeqTick_ReadControlState:
	ld	a, (64602:16)
	ld	(12889:16), a
	ld	a, (64603:16)
	and	a, 127
	and	a, 7
	ld	(12891:16), a
	calr	157
	nop
	nop
	nop
	nop
	ld	a, (64605:16)
	or	a, 224
	srl	a, 5
	ld	(12893:16), a
	ld	w, (64607:16)
	xor	a, a
	bit	6, w
	jr	z, 3
	or	a, 1
SeqCtl_CheckBit6:
	bit 7, w
	jr z, SeqCtl_CheckBit7
	or a, 0x2

SeqCtl_CheckBit7:
	ld	(12895:16), a
	xor	a, a
	bit	4, w
	jr	z, 3
	or	a, 1
SeqCtl_CheckBit4:
	bit 5, w
	jr z, SeqCtl_CheckBit5
	or a, 0x2

SeqCtl_CheckBit5:
	ld	(12897:16), a
	xor	a, a
	bit	2, w
	jr	z, 3
	or	a, 1
SeqCtl_CheckBit2:
	bit 3, w
	jr z, SeqCtl_CheckBit3
	or a, 0x2

SeqCtl_CheckBit3:
	ld w, (0xfc60:16)
	bit 2, w
	jr z, SeqCtl_StorePedalFlags
	or a, 0x4

SeqCtl_StorePedalFlags:
	.byte 0xf1, 0x63, 0x32, 0x41, 0xc1, 0x99, 0xfd, 0x21
	.byte 0xc9, 0xcc, 0x01, 0xf1, 0x65, 0x32, 0x41, 0xc1
	.byte 0x5e, 0xfc, 0x21, 0xc9, 0xcc, 0x10, 0xc9, 0xef
	.byte 0x04, 0x21, 0x00, 0xf1, 0x67, 0x32, 0x41, 0xc1
	.byte 0x61, 0xfc, 0x21, 0xc9, 0xcc, 0x30, 0xc9, 0xef
	.byte 0x04, 0xf1, 0x69, 0x32, 0x41, 0xc9, 0xd1, 0xf1
	.byte 0xad, 0xfd, 0xca, 0x6e, 0x03, 0xc9, 0xce, 0x3f
SeqCtl_StoreKeyMask:
	ld	(12907:16), a
	ret
VoiceParam_ClampAndStore:
	ld	l, (12889:16)
	ld	h, (12891:16)
	calr	15
	ld	(12889:16), l
	and	h, 127
	and	h, 7
	ld	(12891:16), h
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
	ldw_sri HL, 0x07, 0xe0, 0xec

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
	call	16624672
	ret
Seq_ReadTempoLookup:
	xor	xhl, xhl
	ld	wa, (1033:16)
	ld	l, a
	add	xhl, 14969879
	ld	a, (xhl)
	ld	(12975:16), wa
	ret
Seq_ProcessAllInputState:
	ld a, (0x31e7:16)
	and A,0xfe
	bitda 2, (0x041e)
	jr z, .Lc_f53115
	or A,0x01
Seq_InputState_StoreFlag:
.Lc_f53115:
	ld (0x31e7:16), a
	calr AccKey_ScanAndSetDirty
	calr AccState_ReadAccompParams
	calr AudioMode_CheckAndUpdateStereo
	calr AccChord_ReadAndStoreKeys
	calr AudioMode_MergeOutputBits
	calr AudioMode_CopyChannelMode
	calr AudioMode_CopyAccentFlags
	calr AccPedal_SetFlag13155
	xor XHL,XHL
	ld l, (0x31e4:16)
	sla L, 0x01
	add XHL,Display_FontPalette_Table_0x1D46
	ld BC,(XHL)
	xor HL,HL
	ld l, (0x31e3:16)
	add BC,HL
	ld (0x31e1:16), bc
	ld (0x324d:16), 0x18
	bitda 0, (0x31e7)
	jr z, AccInput_CheckRecordMode
	call AccTuning_DisableIfNoStyle
	bitda 0, (0x32c7)
	jr nz, .Lc_f53166
	calr AccPedal_ProcessAllChanges
AccInput_ProcessWithPedal:
.Lc_f53166:
	calr AccChannel_CompareAndMarkDirty
	calr AccVoice_ProcessPedalChanges
	calr AccVoice_ProcessLeftPedalChanges
	calr AccPitch_CheckTransposeFlags
	calr AccChord_ProcessKeyChanges
	bitda 0, (0x32c7)
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

	.byte 0xc1, 0xe8, 0x31, 0x3c, 0xfd	; anddi8 (0x3284), 253 (v7 patched)

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
	.byte 0xd1, 0x9e, 0xf1, 0xc0, 0x66, 0x05, 0xc1, 0xe8
	.byte 0x31, 0x3e, 0x02
AccKey_ScanDone:
	pop xbc
	ret

AccChord_ReadAndStoreKeys:
	ld a, (0xce44:16)
	ld (0x323d:16), a
	ld a, (0xce43:16)
	ld (0x323c:16), a
	ld a, (0xce45:16)
	ld (0x323e:16), a
	ld a, (0xce42:16)
	ld (0x323b:16), a
	cp (0x2308:16), 0x00
	jr z, .Lc_f53209
	ld a, (0x2302:16)
	ld (0x323d:16), a
	ld a, (0x2300:16)
	ld (0x323c:16), a
	ld a, (0x2304:16)
	ld (0x323e:16), a
	ld a, (0x2306:16)
	ld (0x323b:16), a
AccChord_CheckKeyOverride:
.Lc_f53209:
	bitda 1, (0x323b)
	jr nz, .Lc_f53217
	ld a, (0x323d:16)
	ld (0x323e:16), a
AccChord_CheckUIState:
.Lc_f53217:
	cp (0x8c98:16), 0x0e
	jr nz, AccChord_CheckUIStateExit
	cp (0x8c9a:16), 0xb1
	jr z, AccChord_CheckKeyFlags
	cp (0x8c9a:16), 0xb0
	jr nz, AccChord_SetDefaultKeys
AccChord_CheckKeyFlags:
	ld a, (1054:16)
	and a, 0x18
	jr nz, AccChord_CheckUIStateExit

AccChord_SetDefaultKeys:
	.byte 0xf1, 0x3b, 0x32, 0x00, 0x00, 0xf1, 0x3c, 0x32
	.byte 0x00, 0x01, 0xf1, 0xa6, 0x8c, 0x00, 0x01, 0xf1
	.byte 0x4e, 0x34, 0xcc, 0x66, 0x0a, 0xf1, 0x3c, 0x32
	.byte 0x00, 0x05, 0xf1, 0xa6, 0x8c, 0x00, 0x05
AccChord_ReadChannelKeys:
	ld	a, (13389:16)
	and	a, 15
	inc	1, a
	ld	(12861:16), a
	ld	(36004:16), a
	ld	(12862:16), a
AccChord_CheckUIStateExit:
	.byte 0xc1, 0x98, 0x8c, 0x3f, 0x0e, 0x66, 0x1a, 0xc1
	.byte 0x55, 0x32, 0x3f, 0x0e, 0x6e, 0x13, 0xc1, 0x43
	.byte 0xce, 0x21, 0xf1, 0xa6, 0x8c, 0x41, 0xc1, 0x44
	.byte 0xce, 0x21, 0xf1, 0xa4, 0x8c, 0x41, 0x1e, 0x93
	.byte 0x00
AccChord_CheckModeAndUpdate:
	ld	a, (12920:16)
	orda8	xbc, (12921)
	and	a, 63
	jrl	z, 132	; -> 0xF5331C
	ld	a, (12860:16)
	cps	a, 0
	jr	nz, 124	; -> 0xF5331C
	ld	a, (12864:16)
	cpda8	xbc, (12860)
	jr	z, 114	; -> 0xF5331C
	ld	(12860:16), a
	ld	(52803:16), a
	ld	(36006:16), a
	ld	(8960:16), a
	ld	a, (12865:16)
	ld	(12861:16), a
	ld	(52804:16), a
	ld	(36004:16), a
	ld	(8962:16), a
	ld	a, (12866:16)
	ld	(12862:16), a
	ld	(52805:16), a
	ld	(36008:16), a
	ld	(8964:16), a
	cpda8	xbc, (12865)
	jr	nz, 5	; -> 0xF532ED
	ld	(36008:16), 0
AccChord_CompareNoteC:
	.byte 0xc1, 0x3f, 0x32, 0x21, 0xf1, 0x3b, 0x32, 0x41
	.byte 0xf1, 0x42, 0xce, 0x41, 0xf1, 0x06, 0x23, 0x41
	.byte 0x1d, 0x06, 0x15, 0xfe, 0x1d, 0xea, 0x14, 0xfe
	.byte 0xc1, 0x5d, 0xfc, 0x21, 0xc9, 0xcc, 0x07, 0xc9
	.byte 0xd8, 0x66, 0x0c, 0xf1, 0xe8, 0x31, 0xc9, 0x66
	.byte 0x06, 0x1d, 0x6a, 0x3e, 0xfb, 0x68, 0x00
AccChord_ReadKeysRet:
	ret

AccDisplay_RefreshIfDiskActive:
	push xwa
	ld a, (0xfc5d:16)
	and a, 0x7
	cps a, 0
	jr z, AccDisplay_RefreshDone
	call BitMapOut_CheckDiskAndApply

AccDisplay_RefreshDone:
	pop xwa
	ret

AccState_ReadAccompParams:
	ldb A, 0x00
	ei 0x06
	ld (0x0464:16), a
	ld a, (0x0416:16)
	ld (0x31e4:16), a
	ld a, (0x0434:16)
	ld (0x3218:16), a
	ld a, (0x0435:16)
	ld (0x3217:16), a
	ld a, (0x0415:16)
