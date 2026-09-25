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
	ld (4349:16), xiz
	pop xiz
	cp ix, (0x286d:16)
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
	ld ix, 5:i3

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
	ldw (9830:16), 5
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
	ld a, 0xb0:opc
	bit 7, (4235:16)
	jr z, VoiceChannel_ApplyPitchFlags
	or a, 0x2
	bit 7, (4234:16)
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
	ld a, 0xb0:opc
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
	cp a, 0:i3
	jr nz, ToneGen_StoreBadValue
	cp w, 0:i3
	jr c, ToneGen_StoreBadValue
	cp w, 2:i3
	jr ugt, ToneGen_StoreBadValue
	push xix
	ld xix, 0x10b3
	stb_dri W, 0x07, 0xf0, 0xf4
	pop xix
	jr SoundGen_LookupReturn

ToneGen_StoreBadValue:
	ld a, 0xff:opc
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
	cpw (3932:16), 0
	jr z, SoundGen_CaptureAndBuildParams
	cpw (3934:16), 2
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
	ld a, 0xb0:opc
	cp c, 1:i3
	jr nz, SoundGen_UpdateAndWriteChannel
	or a, 0x2
	bit 7, (4234:16)
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
	cpw (3932:16), 0
	jr z, SoundGen_SelectChannelTable
	cpw (3934:16), 2
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
	ld a, 0x7f:opc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_PopIyRet
	call ToneGen_SetSustainBit
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	cpw (3932:16), 0
	jr z, SoundGen_CommitChannelRegs
	cpw (3934:16), 2
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
	ld (6701:16), xhl
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
	ld (6701:16), xhl
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
	bit 7, (6750:16)
	jr nz, SoundGen_SetInitFlags
	jp SoundGen_InitLoopStart

SoundGen_SetInitFlags:
	set 2, (6749:16)
	res 7, (6750:16)

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
	ld a, 0x0:opc
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
	ld a, 0x2:opc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	ld a, 0x7f:opc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	push xiy
	call ToneGen_WriteChannelRegs
	pop xiy
	inc 1, iy
	cp iy, 2:i3
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
	ld A, 0x04:opc
	ldw_dri bc, 0x07, 0xf0, 0xec
	ld E,B
	xor HL,HL
	ld l, (0x0fac:16)
	pushw hl
	call ApplyProgramChangeAs_Block_Code_Sub
	ld A,L
	pop XDE
	pop XBC
	pop XIX
	cp A,0xff
	jr z, SndParam_LookupReturn
SndParam_LookupDefault:
	ld a, 0x0:opc

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
	cpw (0x1a5f:16), 0x0009
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
	ld xbc, 0:i3
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
	ld A, 0x7f:opc
	ld BC,IX
	sub A,C
	sub A,0x01
	cpw (0x1074:16), 0x0000
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
	ld xbc, 0:i3
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
	dec 1, (4211:16)
	inc 1, xix
	jp SysEx_ReadBytesLoop

SysEx_ReadBytes_SetOverflow:
	ld (6880:16), 255

SysEx_ReadBytesReturn:
	ret

SysEx_ClearBuffer:
	ld c, 0x7f:opc
	ld xiy, 0x1a61

SysEx_ClearLoop:
	cp c, 0:i3
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
	cp a, (0xffe3:24)
	jr z, SMF_LoadBank_ClearAndPrepare
	ld a, (4599:16)
	ld (0x00ffe3:24), a
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
	cp hl, 2:i3
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
	ld xbc, 4:i3
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
	and (0xfdad:16), 251
	xor a, a
	jr SeqPlay_QueueDisplayEvent

SeqPlay_SetFlagAndMode:
	or (0xfdad:16), 4
	ld a, 0x4:opc

SeqPlay_QueueDisplayEvent:
	ld	(4330:16), 1
	ld	e, 145:opc
	ld	d, 3:opc
	ld	w, 4:opc
	call	16624640
	call	15668398
	call	16625070
	ret
SMF_InitPlaybackState:
	pushw wa
	cpw (0xf19c:16), 0
	jr z, SMF_InitChannelState
	ldw (6699:16), 9
	jrl SMF_PopReturn

SMF_InitChannelState:
	xor wa, wa
	ld (4236:16), a
	ld (4347:16), wa
	ld (4344:16), a
	cpw (0xffec:24), 0
	jr z, SMF_SetStatusAndJump
	xor c, c

SMF_ScanChannelLoop:
	ld de, (0x00ffec:24)
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
	ldw (6699:16), 47
	jrl SMF_Finalize_PopReturn

SMF_FoundActiveChannel:
	call Vga_SetupMultiPlaneDisplay
	ld wa, (0x00ffec:24)
	ld (4325:16), wa
	ld (4324:16), 255
	bit 2, (0xfdad:16)
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
	ldw (6699:16), 3
	jrl SMF_Finalize_RestoreAndPlay

SMF_SetupActiveChannel:
	ld (0x2877:16), c
	inc 1, hl
	push xde
	ld xde, 0xf250
	ldw_sri HL, 0x07, 0xe8, 0xec
	pop xde
	ld (0x28af:16), hl
	ldw (9830:16), 5
	ld xiy, SMF_HeaderConstants_0x4
	ld xix, 0x13fa
	ld bc, 7:i3
	ldirw
	ld xiy, SMF_HeaderConstants_0x12
	ld bc, 4:i3
	ldir85
	xor wa, wa
	ld (4002:16), wa
	ld (4004:16), wa
	ld (6705:16), xix
	ld wa, (4002:16)
	stw_dpi WA, 0xf1
	ld wa, (4004:16)
	stw_dpi WA, 0xf1
	ld (4376:16), xix
	ld xix, (4376:16)
	ld xiy, SMF_HeaderConstants
	ld bc, 4:i3
	ldir85
	ld xiy, 0xf280
	ldw bc, 0x10
	ldir85
	ld (4376:16), xix
	ldw (4206:16), 0
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
	ld a, 0x4:opc
	ld w, (1075:16)
	stw_dpi WA, 0xf1
	ldw wa, 0x1802
	stw_dpi WA, 0xf1
	ld a, 0x8:opc
	lda_dpi XBC, 0xf0
	ld (4376:16), xix
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
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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

	ld (4376:16), xix

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
	cp c, 0:i3
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
	jrl	nz, SMF_WriteNote_AltPath
	call	SMF_ResolveGlobalChannel
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
	call	SMF_InitPlaybackState_Helper
	popw	de
	popw	bc
	ld	a, (6881:16)
	or	a, 176
	xor	w, w
	ld	l, (6744:16)
	pushw	wa
	pushw	bc
	pushw	de
	call	SMF_WriteByteLoop
	popw	de
	popw	bc
	popw	wa
	push	xwa
	push	xbc
	ld	xbc, 0:i3
	ld	xwa, (6701:16)
	cp	xwa, xbc
	jr	lt, SMF_WriteNote_FileUnderflow1
	pop	xbc
	pop	xwa
	jp	SMF_WriteNote_BankSelect
SMF_WriteNote_FileUnderflow1:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteNote_BankSelect:
	ld w, 0x20:opc
	ld l, (6743:16)
	pushw bc
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	ld w, 0x0:opc
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
	ld xbc, 0:i3
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
	ld w, 0x20:opc
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
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	ld w, 0x7:opc
	ld l, b
	pushw wa
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x5d:opc
	ld l, (4359:16)
	pushw wa
	pushw de
	call SMF_WriteByteLoop
	popw de
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x40:opc
	ld l, 0x7f:opc
	bit 3, e
	jr nz, SMF_WriteVol_SustainValue
	ld l, 0x0:opc

SMF_WriteVol_SustainValue:
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x5b:opc
	ld l, (4332:16)
	and l, 0x7f
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0xa:opc
	pushw wa
	pushw bc
	call SMF_WriteByteLoop
	popw bc
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x1:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
	pushw wa
	pushw bc
	call SMF_WriteByteLoop
	popw bc
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x2:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	xor l, l
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	xor l, l
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	inc 1, (0x2877:16)
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
	ldw (3946:16), 0
	ldw (3938:16), 0
	ldw (3940:16), 0

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
	incw 1, (3946:16)

SMF_MetaTiming_GetNextLoop:
	call SMF_GetNextEvent
	cp a, 0x81
	jr nz, SMF_MetaTiming_ApplyMultiplier
	incw 1, (3946:16)
	call SMF_AdvancePosition
	jr SMF_MetaTiming_GetNextLoop

SMF_MetaTiming_ApplyMultiplier:
	ld wa, (3946:16)
	ldw de, 0x60
	mul xwa, xde
	stw_erp DE, 0xe2
	add (3938:16), wa
	ld (3940:16), de
	ldw (3946:16), 0
	jrl SMF_ProcessEventLoop

SMF_PolyAftertouch_Dispatch:
	cp hl, 3:i3
	jr z, SMF_PolyAftertouch_3Byte_CalcTime
	cp hl, 4:i3
	jrl nz, SMF_ProcessEventLoop
	ld c, (4212:16)
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	cp hl, 3:i3
	jrl nz, SMF_ProcessEventLoop
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x1:opc
	ld l, (4213:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	cp hl, 4:i3
	jrl nz, SMF_ProcessEventLoop
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	cp hl, 3:i3
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
	ld xbc, 0:i3
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
	ld w, 0xb:opc
	ld l, (4213:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	cp hl, 6:i3
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
	or (4236:16), 1
	pushw hl
	ld c, (4212:16)
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw hl
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld xbc, 0:i3
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
	ld a, 0x80:opc
	lda_dpi XBC, 0xf0
	ld a, (4211:16)
	lda_dpi XBC, 0xf0
	ld a, (4213:16)
	lda_dpi XBC, 0xf0
	ld a, (4216:16)
	ld w, 0x60:opc
	muls8rr a, w
	xor hl, hl
	ld l, (4215:16)
	add wa, hl
	stw_dpi WA, 0xf1
	jrl SMF_ProcessEventLoop

SMF_ProgramChange_Handler:
	cp hl, 6:i3
	jrl nz, SMF_ProcessEventLoop
	cp (4213:16), 127
	jrl z, SMF_ProcessEventLoop
	ld a, (4214:16)
	cp a, 0:i3
	jrl nz, SMF_ProcessEventLoop
	cp (6709:16), 0
	jr z, SMF_ProgramChange_CalcTime
	bit 0, (4236:16)
	jrl z, SMF_ProcessEventLoop

SMF_ProgramChange_CalcTime:
	ld c, (4212:16)
	pushw wa
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	call	SMF_InitPlaybackState_Helper
	ld	a, 176:opc
	ld	w, (4213:16)
	or	a, w
	xor	w, w
	ld	l, (6744:16)
	pushw	wa
	call	SMF_WriteByteLoop
	popw	wa
	push	xwa
	push	xbc
	ld	xbc, 0:i3
	ld	xwa, (6701:16)
	cp	xwa, xbc
	jr	lt, SMF_ProgramChange_WriteBankMSB_Underflow
	pop	xbc
	pop	xwa
	jp	SMF_ProgramChange_WriteBankMSB_Data
SMF_ProgramChange_WriteBankMSB_Underflow:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_ProgramChange_WriteBankMSB_Data:
	ldw (4206:16), 0
	ld (4208:16), 0
	ld w, 0x20:opc
	ld l, (6743:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld a, 0xc0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, (6745:16)
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x0:opc
	ld l, (4211:16)
	and l, 0x1
	call SMF_SendChannelConfig
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ldw (4206:16), 0
	ld (4208:16), 0
	ld w, 0x20:opc
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
	ld xbc, 0:i3
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
	ld a, 0xc0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, (4215:16)
	xor l, l
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	cp hl, 6:i3
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
	cp l, 0:i3
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
	cp l, 3:i3
	jrl c, SMF_ProcessEventLoop
	cp l, 0xb
	jrl ugt, SMF_ProcessEventLoop
	ld a, 0xb0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, 0x7:opc
	cp l, 3:i3
	jrl z, SMF_CC_Volume_Handler
	cp l, 4:i3
	jrl z, SMF_CC_Portamento_CheckBit3
	cp l, 5:i3
	jrl z, SMF_CC_Reverb_Handler
	cp l, 7:i3
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
	bit 0, (4236:16)
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
	ld xbc, 0:i3
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
	ld a, 0xb0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x1:opc
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
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
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	ld l, (4215:16)
	and l, 0x1
	rrc_i_8 l, 2
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	bit 0, (4236:16)
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
	ld xbc, 0:i3
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
	ld a, 0xb0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x0:opc
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
	ld l, (4215:16)
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	ld l, 0x0:opc
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	bit 0, (4236:16)
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
	ld xbc, 0:i3
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
	ld a, 0xb0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, 0x65:opc
	ld l, 0x0:opc
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x64:opc
	ld l, 0x2:opc
	ld (4206:16), 0
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x6:opc
	ld l, (4215:16)
	pushw wa
	call SMF_WriteByteLoop
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
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
	ld w, 0x26:opc
	ld l, 0x0:opc
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	bit 0, (4236:16)
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
	ld xbc, 0:i3
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
	ld a, 0xb0:opc
	ld w, (4213:16)
	and w, 0xf
	or a, w
	ld w, 0xa:opc
	ld l, (4215:16)
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
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
	bit 0, (4236:16)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Reverb_SetupCC93:
	ld w, 0x5d:opc
	ld l, (4215:16)
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Sustain_CheckBits:
	ld bc, (4215:16)
	bit 3, b
	jrl z, SMF_ProcessEventLoop
	cp (6709:16), 0
	jr z, SMF_CC_Sustain_SetCC64Value
	bit 0, (4236:16)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Sustain_SetCC64Value:
	ld w, 0x40:opc
	ld l, 0x0:opc
	bit 3, c
	jr z, SMF_ProcessTimedEvent_Continue
	ld l, 0x7f:opc
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Chorus_Handler:
	ld w, 0x5b:opc
	ld l, 0x0:opc
	cp (6709:16), 0
	jr z, SMF_CC_Chorus_SetupCC91
	bit 0, (4236:16)
	jrl z, SMF_ProcessEventLoop

SMF_CC_Chorus_SetupCC91:
	ld l, (4215:16)
	and l, 0x7f
	jr SMF_ProcessTimedEvent_Continue

SMF_CC_Volume_Handler:
	cp (6709:16), 0
	jr z, SMF_ProcessTimedEvent_Entry
	bit 0, (4236:16)
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
	ld (0x0210f6:24), xwa
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
	call	LyricsTrack_ReadAndParse_Helper2
	inc	1, hl
	pushw	hl
	calr	SeqStep_MemAllocWrapper
	inc	6, xsp
	ld	(xsp+12), xhl
	or	xhl, xhl
	jr	nz, FileOpen_CopyFilename
	ld	xhl, 0:i3
	jrl	FileOpen_Return
FileOpen_CopyFilename:
	ld	xwa, (xsp+24)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
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
	ld xwa, 1:i3
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
	cp a, 0:i3
	jr nz, FileOpen_ScanForColon

FileOpen_MatchDevice:
	ld	xwa, (xsp+16)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	ld	iz, hl
	extz	xiz
	ld	xwa, (xsp+28)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
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
	cp	wa, (254942:24)
	jr	ge, FileOpen_DeviceFound	; -> 0xF4E8FC
FileOpen_DeviceSearchLoop:
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+22)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	16713560
	inc	8, xsp
	cp	hl, 0:i3
	jr	z, 23	; -> 0xF4E8FC
	incm8	1, (xsp+6)
	ld	xwa, 34
	add	(xsp+8), xwa
	ld	a, (xsp+6)
	extz	wa
	cp	wa, (254942:24)
	jr	lt, -44	; -> 0xF4E8D0
FileOpen_DeviceFound:
	ld xwa, (xsp + 12)
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld a, (xsp + 6)
	extz wa
	cp wa, (0x3e3de:24)
	jr nz, FileOpen_CheckPermission

FileOpen_ErrorNoFile:
	ldw (0x01e53c:24), 0x0007
	ld xhl, 0:i3
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
	ldw (0x01e53c:24), 0x0002
	ld xhl, 0:i3
	jrl FileOpen_Return

FileOpen_FindFreeSlot:
	inc 1, (0x210f4:24)
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
	ldw (0x01e53c:24), 0x0004
	call SeqStep_FileNopB
	ld xhl, 0:i3
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
	ld xwa, 0:i3
	stl_dri XWA, 0x07, 0xe8, 0xe4
	ld xhl, 0:i3
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
	ld a, (0x03e2e2:24)
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
	cp hl, 0:i3
	jr z, FileOpen_ReturnHandle
	ld a, (xsp + 14)
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (0x0210b4:24)
	ld xwa, 0:i3
	stl_dri XWA, 0x07, 0xe8, 0xe4
	ld a, l
	exts wa
	ld (0x01e53c:24), wa
	ld xwa, xiz
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld xiz, 0:i3

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
	ldw (0x01e53c:24), 0x0011
	ld hl, 0:i3
	ret

SeqStep_FileReadCheck:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadProcess
	ldw (0x01e53c:24), 0x000d
	ld hl, 0:i3
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
	ldw (0x01e53c:24), 0x0011
	ld hl, 0:i3
	ret

SeqStep_FileReadLoop:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileReadDone
	ldw (0x01e53c:24), 0x000d
	ld hl, 0:i3
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
	ldw (0x01e53c:24), 0x0011
	ldw hl, 0xffff
	jr SeqStep_FileReadVtableReturn

SeqStep_FileReadCleanup:
	bitm 0, (xbc + 4)
	jr nz, SeqStep_FileReadComplete
	ldw (0x01e53c:24), 0x000d
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
	cp hl, 0:i3
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
	jr	z, SeqStep_FileReadReturn_Skip
	cp	(xbc+4), 0
	jr	nz, SeqStep_FileReadReturn_Skip2
SeqStep_FileReadReturn_Skip:
	ldw	(0x1e53c:24), 17
	ld	xhl, 0:i3
	jr	SeqStep_FileReadReturn_Epilogue
SeqStep_FileReadReturn_Skip2:
	bitm	0, (xbc+4)
	jr	nz, SeqStep_FileReadReturn_Skip3
	stiw_da	(124220), 13
	ld	xhl, 0:i3
	jr	SeqStep_FileReadReturn_Epilogue
SeqStep_FileReadReturn_Skip3:
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
	.byte 0xf3, 0x07, 0xf8, 0xec, 0x00, 0x00	; ld (xiz+hl),0x00
	cp	hl, 0:i3
	jr	z, SeqStep_FileReadReturn_Skip4
	ld	xhl, xiz
	jr	SeqStep_FileReadReturn_Epilogue
SeqStep_FileReadReturn_Skip4:
	ld	xhl, 0:i3
SeqStep_FileReadReturn_Epilogue:
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
	ldw (0x01e53c:24), 0x0011
	ldw hl, 0xffff
	jr SeqStep_FileWriteReturn

SeqStep_FileWriteCheckMode:
	bitm 1, (xbc + 4)
	jr nz, SeqStep_FileWriteProcess
	ldw (0x01e53c:24), 0x000d
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
	cp hl, 0:i3
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
	jr	z, SeqStep_FileWriteSetup_Skip
	cp	(xbc+4), 0
	jr	nz, SeqStep_FileWriteSetup_Skip2
SeqStep_FileWriteSetup_Skip:
	ldw	(0x1e53c:24), 17
	ldw	hl, 0xffff
	ret
SeqStep_FileWriteSetup_Skip2:
	bitm	1, (xbc+4)
	jr	nz, SeqStep_FileWriteSetup_Skip3
	stiw_da	(124220), 13
	ldw	hl, 0xffff
	ret
SeqStep_FileWriteSetup_Skip3:
	ld	hl, 0:i3
	ld	xwa, (xsp+4)
	cp_spib_im 224, 0
	jr	z, SeqStep_FileWriteSetup_Skip4
SeqStep_FileWriteSetup_Loop:
	inc	1, hl
	cp_spib_im 224, 0
	jr	nz, SeqStep_FileWriteSetup_Loop
SeqStep_FileWriteSetup_Skip4:
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
	cp	wa, 0:i3
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
	ldw (0x01e53c:24), 0x0011
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
	ld (0x01e53c:24), wa

SeqStep_FileCloseReturn:
	inc 1, (0x210f4:24)
	ld a, (xiz + 5)
	extz wa
	ld bc, wa
	sla bc, 2
	lda xde, (0x0210b4:24)
	ld xwa, 0:i3
	stl_dri XWA, 0x07, 0xe8, 0xe4
	ld a, (xiz + 5)
	extz wa
	ld (xsp + 6), wa
	ld xwa, xiz
	push xwa
	call SeqStep_FreeMemory
	inc 4, xsp
	ld iz, hl
	cp iz, 0:i3
	jr z, SeqStep_FileCloseCleanup
	cpw (xsp + 4), 0x0
	jr nz, SeqStep_FileCloseCleanup
	ldw (0x01e53c:24), 0x0026

SeqStep_FileCloseCleanup:
	ld wa, (xsp + 6)
	add wa, 0x64
	pushw wa
	call SeqStep_FileNopA
	inc 2, xsp
	call SeqStep_FileNopB
	cpw (xsp + 4), 0x0
	jr nz, SeqStep_FileCloseDone
	cp iz, 0:i3
	jr z, SeqStep_FileCloseComplete

SeqStep_FileCloseDone:
	ldw hl, 0xffff
	jr SeqStep_FileCloseFinal

SeqStep_FileCloseComplete:
	ld hl, 0:i3

SeqStep_FileCloseFinal:
	pop xiz
	inc 4, xsp
	ret

SeqStep_FileCloseExit:
	dec	4, xsp
	push	xiz
	ld	xbc, (xsp+12)
	ld	iz, 0:i3
	or	xbc, xbc
	jr	z, SeqStep_FileCloseInner_Skip2
	cp	(xbc+4), 0
	jr	z, SeqStep_FileCloseInner_Skip
	ld	xwa, (xsp+4)
	push	xwa
	pushw	1
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	lda	xsp, (xsp+10)
	jrl	SeqStep_FileCloseInner_Epilogue2
SeqStep_FileCloseInner_Skip:
	ldw	(0x1e53c:24), 25
	ldw	hl, 0xffff
	jr	SeqStep_FileCloseInner_Epilogue2
SeqStep_FileCloseInner_Skip2:
	ld qiz, 0
	cpw qiz, 16
	jr	ge, SeqStep_FileCloseInner_Epilogue
SeqStep_FileCloseInner_Loop:
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	or xwa, xwa
	jr	z, SeqStep_FileCloseInner_Skip3
	ld wa, qiz
	sla wa, 2
	lda	xbc, (0x210b4:24)
	ld_rrl xwa, xbc, wa
	cp xwa, 4294967295
	jr	z, SeqStep_FileCloseInner_Skip3
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
SeqStep_FileCloseInner_Skip3:
	inc 1, qiz
	cpw qiz, 16
	jr	lt, SeqStep_FileCloseInner_Loop
SeqStep_FileCloseInner_Epilogue:
	ld	hl, iz
SeqStep_FileCloseInner_Epilogue2:
	pop	xiz
	inc	4, xsp
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	nz, SeqStep_FileCloseInner_Skip4
	ldw	(0x1e53c:24), 17
	ldw	hl, 0xffff
	ret
SeqStep_FileCloseInner_Skip4:
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
	ldw (xwa+6), 0
	ret

SeqStep_FileNopA:
	ret

SeqStep_FileNopB:
	ret

SeqStep_FreeMemory:
	ld	xwa, (xsp+4)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	ret
SeqStep_MallocWrapper:
	ld	xwa, (xsp+6)
	pushw	wa
	call	SLIDE_Decompress_4K_Init_Helper2
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
	ld	wa, (0x1e53c:24)
	ld	(xsp+4), wa
	ldw	(0x1e53c:24), 0
	pushw	228
	pushw	0x501a
	ld	xwa, (xsp+14)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, FileOpenDefault_Skip3
	push	xiz
	call	FileClose
	inc	4, xsp
	ldw	(0x1e53c:24), 21
	ldw	hl, 0xffff
	jr	FileOpenDefault_Epilogue
FileOpenDefault_Skip3:
	cpw_da	(124220), 5
	jr	z, FileOpenDefault_Skip4
	ldw	hl, 0xffff
	jr	FileOpenDefault_Epilogue
FileOpenDefault_Skip4:
	ld	wa, (xsp+4)
	exts	wa
	ld	(0x1e53c:24), wa
	pushw	228
	pushw	0x501c
	ld	xwa, (xsp+14)
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, FileOpenDefault_Skip
	ldw	hl, 0xffff
	jr	FileOpenDefault_Epilogue
FileOpenDefault_Skip:
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
FileOpenDefault_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
	ld	xde, (xsp+4)
	or	xde, xde
	jr	z, FileOpenDefault_Skip5
	cp	(xde+4), 0
	jr	nz, FileOpenDefault_Skip6
FileOpenDefault_Skip5:
	ldw	(0x1e53c:24), 17
	ldw	hl, 17
	ret
FileOpenDefault_Skip6:
	ld	xwa, (xde+18)
	cp	(xwa), 1
	jr	nz, FileOpenDefault_Skip7
	ld	xbc, (xsp+8)
	ld	xwa, (xde+22)
	ld	(xbc), xwa
	ld	hl, 0:i3
	ret
FileOpenDefault_Skip7:
	ldw	(0x1e53c:24), 18
	ldw	hl, 18
	ret
	ld	xbc, (xsp+4)
	or	xbc, xbc
	jr	z, FileOpenDefault_Skip8
	cp	(xbc+4), 0
	jr	nz, FileOpenDefault_Skip2
FileOpenDefault_Skip8:
	ldw	(0x1e53c:24), 17
	ldw	hl, 17
	ret
FileOpenDefault_Skip2:
	ld	xwa, (xsp+8)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, xbc
	push	xwa
	ld	xwa, (xbc+14)
	ld	xwa, (xwa+24)
	call	(xwa)
	inc	8, xsp
	cp	hl, 0:i3
	ret	z
	ld	a, l
	exts	wa
	ld	(0x1e53c:24), wa
	ret

SeqStep_FileSeekSetup:
	ld xde, (xsp + 8)
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekNoHandle
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekProcess

SeqStep_FileSeekNoHandle:
	ldw (0x01e53c:24), 0x0011
	ldw hl, 0x11
	ret

SeqStep_FileSeekProcess:
	ld wa, (xsp + 12)
	cp wa, 2:i3
	jr z, SeqStep_FileSeekDone
	cp wa, 1:i3
	jr z, SeqStep_FileSeekCheck
	cp wa, 0:i3
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
	cp hl, 0:i3
	ret z
	ld a, l
	exts wa
	ld (0x01e53c:24), wa
	ret

SeqStep_FileSeekStore:
	ld xbc, (xsp + 4)
	or xbc, xbc
	jr z, SeqStep_FileSeekComplete
	cp (xbc + 4), 0x0
	jr nz, SeqStep_FileSeekFinal

SeqStep_FileSeekComplete:
	ldw (0x01e53c:24), 0x0011
	ld xhl, 0xffffffff
	ret

SeqStep_FileSeekFinal:
	ld xwa, (xbc + 18)
	cp (xwa), 0x1
	jr nz, SeqStep_FileSeekExit
	ld xhl, (xbc + 22)
	ret

SeqStep_FileSeekExit:
	ldw (0x01e53c:24), 0x0012
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
	ld xwa, 0:i3
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
	cpw (0x1e53c:24), 13
	jr nz, SeqStep_FileTellSetup
	ldw (0x01e53c:24), 0x0000
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
	cpw (0x1e53c:24), 13
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
	ldw (0x01e53c:24), 0x0015
	ldw hl, 0xffff
	jr SeqStep_FileTellExit

SeqStep_FileTellProcess:
	ldw (0x01e53c:24), 0x0000
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
	ldw (0x01e53c:24), 0x001a
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
	jr	nz, SeqStep_FileSeekCleanup_Skip
	ldw	hl, 0xffff
	jrl	SeqStep_FileSeekCleanup_Epilogue
SeqStep_FileSeekCleanup_Skip:
	ld	xwa, (xiz+26)
	or	xwa, xwa
	jr	nz, SeqStep_FileSeekCleanup_Skip2
	ldw	(0x1e53c:24), 13
	jr	SeqStep_FileSeekCleanup_Loop
SeqStep_FileSeekCleanup_Skip2:
	pushw	0
	ld	xwa, 64
	push	xwa
	push	xiz
	calr	SeqStep_FileSeekSetup
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, SeqStep_FileSeekCleanup_Loop
	push	xiz
	pushw	1
	pushw	32
	lda	xwa, (xsp+16)
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cp	hl, 1:i3
	jr	nz, SeqStep_FileSeekCleanup_Skip4
SeqStep_FileSeekCleanup_Entry:
	cp	(xsp+8), 0
	jr	z, SeqStep_FileSeekCleanup_Skip4
	cp	(xsp+8), 229
	jr	z, SeqStep_FileSeekCleanup_Skip3
	ldw	(0x1e53c:24), 27
SeqStep_FileSeekCleanup_Loop:
	push	xiz
	call	FileClose
	inc	4, xsp
	ldw	hl, 0xffff
	jr	SeqStep_FileSeekCleanup_Epilogue
SeqStep_FileSeekCleanup_Skip3:
	push	xiz
	pushw	1
	pushw	32
	lda	xwa, (xsp+16)
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cp	hl, 1:i3
	jr	z, SeqStep_FileSeekCleanup_Entry
SeqStep_FileSeekCleanup_Skip4:
	ld	xwa, (xsp+4)
	push	xwa
	pushw	21
	ld	xwa, xiz
	push	xwa
	ld	xwa, (xiz+14)
	ld	xwa, (xwa+36)
	call	(xwa)
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, SeqStep_FileSeekCleanup_Loop
	push	xiz
	call	FileClose
	inc	4, xsp
SeqStep_FileSeekCleanup_Epilogue:
	pop	xiz
	lda	xsp, (xsp+36)
	ret

SeqStep_FileIoHelper:
	pushw 0x0
	ld xwa, 0:i3
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
	cp a, 3:i3
	jrl nz, SeqStep_FileIoLoopReturn
	push xiz
	calr SeqStep_FileBufferSetup
	inc 4, xsp
	ld (xiz + 20), hl
	ld xwa, (xsp + 10)
	ld (xwa + 6), hl
	cp hl, 0:i3
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
	ld xhl, 0:i3
	ld xiz, 0:i3
	ldw de, 0x8000
	ldw (xsp + 4), 0x0
	cpw (xsp + 4), 0xa
	jr ge, SeqStep_FileIoUpdate

SeqStep_FileIoError:
	cp (0x03e3e0:24), 0x00
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
	ld (0x03e3e0:24), 0x00
	or xhl, xhl
	jr z, SeqStep_FileIoValidate
	addiw_da (xhl + 18), 0x14
	ld wa, (xhl + 18)
	bit 15, wa
	jr z, SeqStep_FileIoStore
	ld (0x03e3e0:24), 0x01

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
	ld xhl, 0:i3
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
	ld (0x03e3e0:24), 0x01

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
	ld hl, 0:i3
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
	ldw	(xsp+4), 0
	lda	xwa, (0x2121a:24)
	ld	xiz, xwa
	ldw (xsp+6), 0
	cpw	(xsp+6), 10
	jr	ge, SeqStep_FileBufferFinal_Skip3
SeqStep_FileBufferFinal_Loop:
	ld	a, (xiz+22)
	and	a, 3
	cp	a, 3:i3
	jr	nz, SeqStep_FileBufferFinal_Skip
	push	xiz
	calr	SeqStep_FileBufferSetup
	inc	4, xsp
	cp	hl, 0:i3
	jr	z, SeqStep_FileBufferFinal_Skip
	ld	(xsp+4), hl
SeqStep_FileBufferFinal_Skip:
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	.byte 0x8e, 0x17, 0xf1
	jr	nz, SeqStep_FileBufferFinal_Skip2
	bitm	2, (xiz+22)
	jr	nz, SeqStep_FileBufferFinal_Skip2
	andmi8	(xiz+22), 128
SeqStep_FileBufferFinal_Skip2:
	incw	1, (xsp+6)
	lda	xiz, (xiz+538)
	cpw	(xsp+6), 10
	jr	lt, SeqStep_FileBufferFinal_Loop
SeqStep_FileBufferFinal_Skip3:
	ld	hl, (xsp+4)
	pop	xiz
	inc	4, xsp
	ret

SeqStep_FileSectorRead:
	ld xbc, (xsp + 4)
	ld xde, (xbc)
	ld xwa, 1:i3
	add (xbc), xwa
	ld l, (xde)
	extz hl
	ld xbc, (xsp + 4)
	ld xde, (xbc)
	ld xwa, 1:i3
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
	ld xwa, 1:i3
	add (xbc), xwa
	ld a, (xde)
	ld xhl, 0:i3
	ld l, a
	ld xbc, xix
	ld xde, (xbc)
	ld xwa, 1:i3
	add (xbc), xwa
	ld xwa, 0:i3
	ld a, (xde)
	sll xwa, 8
	add xhl, xwa
	ld xbc, xix
	ld xde, (xbc)
	ld xwa, 1:i3
	add (xbc), xwa
	ld xwa, 0:i3
	ld a, (xde)
	sll xwa, 0
	add xhl, xwa
	ld xbc, xix
	ld xde, (xbc)
	ld xwa, 1:i3
	add (xbc), xwa
	ld xwa, 0:i3
	ld a, (xde)
	sll xwa, 8
	sll xwa, 0
	add xhl, xwa
	ret

SeqStep_FileSectorDone:
	ld	xbc, (xsp+6)
	ld	xde, (xbc)
	ld	xwa, 1:i3
	add	(xbc), xwa
	ld	wa, (xsp+4)
	ld	w, 0:opc
	ld	(xde), a
	ld	xbc, (xsp+6)
	ld	xde, (xbc)
	ld	xwa, 1:i3
	add	(xbc), xwa
	ld	wa, (xsp+4)
	srl	wa, 8
	ld	(xde), a
	ret
	ld	xbc, (xsp+8)
	ld	xhl, (xsp+4)
	ld	xde, xbc
	ld	xix, (xde)
	ld	xwa, 1:i3
	add	(xde), xwa
	ld	xwa, xhl
	and	xwa, 255
	ld	(xix), a
	ld	xde, xbc
	ld	xix, (xde)
	ld	xwa, 1:i3
	add	(xde), xwa
	ld	xwa, xhl
	srl	xwa, 8
	and	xwa, 255
	ld	(xix), a
	ld	xde, xbc
	ld	xix, (xde)
	ld	xwa, 1:i3
	add	(xde), xwa
	ld	xwa, xhl
	srl	xwa, 0
	and	xwa, 255
	ld	(xix), a
	ld	xde, (xbc)
	ld	xwa, 1:i3
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
	calr	SeqStep_FileSectorRead
	ld	xwa, (xsp+26)
	ld	(xwa+13), hl
	lda	xwa, (xsp+18)
	push	xwa
	calr	SeqStep_FileSectorRead
	ld	xwa, (xsp+30)
	ld	(xwa+15), hl
	lda	xwa, (xsp+22)
	push	xwa
	calr	SeqStep_FileSectorRead
	ld	xwa, (xsp+34)
	ld	(xwa+17), hl
	lda	xwa, (xsp+26)
	push	xwa
	calr	SeqStep_FileSectorProcess
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
	ld	w, 0:opc
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
	ld	w, 0:opc
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
	ld	w, 0:opc
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
	ld xwa, 0:i3
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
	ld xwa, 0:i3
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
	ld W, 0x00:opc
	ld (XBC),A
	cpw (XSP+0x04), 0x01ff
	jr nz, .Lc_f4f9da
	pushw 0x0006
	ld xwa, 0:i3
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
	ld W, 0x00:opc
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
SeqByteBlock_StyleBitmapRef_Code_Helper:
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
	ld	w, 128:opc
	push	xsp
	pushw	sp
	jr	z, SeqStep_FileSectorError_Entry
SeqByteBlock_EffectsSeqData:
	ld	xwa, (xiz)
	cp	(xwa), 92
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper_Code_Skip
SeqStep_FileSectorError_Entry:
	ld	xwa, 1:i3
	add	(xiz), xwa
SeqByteBlock_StyleBitmapRef_Code_Helper_Code_Skip:
	ld	de, 0:i3
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
	ld	hl, 1:i3
SeqByteBlock_EffectsSeqDotExt:
	jr	55
	ld	xwa, (xiz)
	cp	(xwa), 46
	jr	nz, 24
	cp	de, 1:i3
	jr	gt, 12
	cp	de, 1:i3
	jr	nz, 16
	ld	xwa, (xsp+8)
	cp	(xwa), 46
	jr	z, 8
	ld	de, 7:i3
	ld	xwa, 1:i3
	add	(xiz), xwa
	jr	16
SeqByteBlock_TechnichordCfgA:
	ld	xbc, (xiz)
	ld	xwa, (xsp+8)
	ld	c, (xbc)
	st_rrb	c, xwa, de
	ld	xwa, 1:i3
	add	(xiz), xwa
	inc	1, de
	cp	de, 11
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
SeqByteBlock_StyleBitmapRef_Code_Helper2:
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
SeqByteBlock_StyleBitmapRef_Code_Helper3:
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
	; v10 does not spell this byte either
	bitm	3, (xwa+2)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip
	ld	xwa, (xsp+2)
	push	xwa
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+14)
	ld	xwa, (xwa)
	call	(xwa)
	inc	4, xsp
	cp	hl, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip
	ldw	hl, 42
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue
SeqByteBlock_StyleBitmapRef_Code_Skip:
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	setm	3, (xwa+2)
SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip:
	ld	xwa, (xsp+2)
	bitm	0, (xwa+2)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip2
	ld	xwa, (xsp+2)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper3
	inc	4, xsp
	ld	iz, hl
	cp	iz, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip2
	ld	hl, iz
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue
SeqByteBlock_StyleBitmapRef_Code_Skip2:
	ld	xwa, (xsp+6)
	; v10 does not spell this byte either
	cpw	(xwa+38), 512
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip2
	ld	hl, 1:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue
SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip2:
	ld	xwa, (xsp+14)
	ld	xbc, (xsp+6)
	ld	(xwa+30), xbc
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip3
	ld	xwa, (xsp+14)
	ld	(xwa+2), 10
SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip3:
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	62483
	inc	8, xsp
	ld	iz, hl
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	bitm	7, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Join
	cp	iz, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip4
	cp	iz, 5:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Join
	ld	xwa, (xsp+18)
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	calr	63464
	inc	8, xsp
	ld	iz, hl
	jr	SeqByteBlock_StyleBitmapRef_Code_Join
SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip4:
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	bitm	3, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip5
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	ld	xbc, xwa
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
SeqByteBlock_StyleBitmapRef_Code_Helper3_Skip5:
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	bitm	4, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Join
	ld	xwa, (xsp+14)
	push	xwa
	calr	64111
	inc	4, xsp
	ld	xwa, (xsp+14)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	setm	7, (xwa+3)
SeqByteBlock_StyleBitmapRef_Code_Join:
	cp	iz, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip3
	ld	hl, iz
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue
SeqByteBlock_StyleBitmapRef_Code_Skip3:
	ld	xwa, (xsp+14)
	ld	xbc, xwa
	ld	a, (xwa+3)
	ld	(xbc+4), a
	ld	xwa, (xsp+2)
	incm8	1, (xwa+3)
	ld	hl, 0:i3
SeqByteBlock_StyleBitmapRef_Code_Epilogue:
	popw	iz
	inc	8, xsp
	ret
SeqByteBlock_StyleBitmapRef_Code_Helper4:
	dec	8, xsp
	push	xiz
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+30)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+26)
	or	xwa, xwa
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip4
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
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sub	xbc, (xwa+28)
	ld	xwa, (xsp+8)
	ld	wa, (xwa+46)
	extz	xwa
	sub	xwa, xbc
	ld	xbc, (xsp+26)
	ld	(xbc), wa
	ld	hl, 0:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue2
SeqByteBlock_StyleBitmapRef_Code_Skip4:
	ld	xwa, (xsp+16)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+8)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	div	bc, (xwa+40)
	ld	(xsp+4), bc
	ld	xwa, (xsp+8)
	ld	bc, (xwa+40)
	extz	xbc
	ld	xwa, (xsp+16)
	ld	xwa, (xwa+22)
	call	FDC_SetupSectorParams_Helper
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
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip2
	ld	xwa, (xsp+16)
	; v10 does not spell this byte either
	cpw	(xwa+42), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip
	ld	xwa, (xsp+16)
	; v10 does not spell this byte either
	bitm	1, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	pushm	(xsp+20)
	pushw	0
	ld	xwa, (xsp+20)
	push	xwa
	calr	61612
	inc	8, xsp
	ld	wa, hl
	cp	wa, 0:i3
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Helper4_Join
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue2
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip:
	ld	xwa, (xsp+16)
	; v10 does not spell this byte either
	cpw	(xwa+44), 0
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper4_Join
	ld	xwa, (xsp+16)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper
	inc	4, xsp
	jrl	SeqByteBlock_StyleBitmapRef_Code_Helper4_Join
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip2:
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	ule, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip3
	ld	xwa, (xsp+16)
	ld	xbc, xwa
	ld	wa, (xwa+69)
	ld	(xbc+42), wa
	ld	xwa, (xsp+16)
	ldw	(xwa+46), 0
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip3:
	ld	xwa, (xsp+16)
	ld	hl, (xwa+42)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Skip5
SeqByteBlock_StyleBitmapRef_Code_Loop:
	pushw	hl
	ld	xwa, (xsp+18)
	push	xwa
	calr	SeqStep_FileSectorError
	inc	6, xsp
	ld	xwa, (xsp+8)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	wa, hl
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip4
	ldw	hl, 39
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue2
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip4:
	ld	xwa, (xsp+8)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	hl, wa
	jr	ule, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip6
	ld	xwa, (xsp+16)
	; v10 does not spell this byte either
	bitm	1, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip5
	; v10 does not spell this byte either
	pushm	(xsp+20)
	pushw	0
	ld	xwa, (xsp+20)
	push	xwa
	calr	61469
	inc	8, xsp
	ld	wa, hl
	cp	wa, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper4_Join
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue2
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip5:
	ldw	hl, 8
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue2
SeqByteBlock_StyleBitmapRef_Code_Helper4_Skip6:
	ld	xwa, (xsp+16)
	ld	(xwa+42), hl
	ld	xwa, (xsp+16)
	incw	1, (xwa+46)
	ld	xwa, (xsp+16)
	ld	wa, (xwa+46)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	c, SeqByteBlock_StyleBitmapRef_Code_Loop
SeqByteBlock_StyleBitmapRef_Code_Skip5:
	ld	xwa, (xsp+16)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper
	inc	4, xsp
SeqByteBlock_StyleBitmapRef_Code_Helper4_Join:
	ld	xwa, 0:i3
	ld	a, (xsp+6)
	ld	xbc, xwa
	ld	xwa, (xsp+8)
	; v10 does not spell this byte either
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
	call	InitializeKubo_Helper
	ld	xwa, (xsp+22)
	add	(xwa), xhl
	ld	xwa, (xsp+16)
	ld	wa, (xwa+44)
	extz	xwa
	ld	xbc, (xsp+8)
	ld	xbc, (xbc+32)
	call	InitializeKubo_Helper
	ld	xwa, 0:i3
	ld	a, (xsp+6)
	sub	xhl, xwa
	ld	xwa, (xsp+26)
	ld	(xwa), hl
	ld	hl, 0:i3
SeqByteBlock_StyleBitmapRef_Code_Epilogue2:
	pop	xiz
	inc	8, xsp
	ret
SeqByteBlock_StyleBitmapRef_Code_Helper5:
	dec	6, xsp
	push	xiz
	ld	xiz, (xsp+14)
	lda	xwa, (xsp+4)
	push	xwa
	lda	xwa, (xsp+10)
	push	xwa
	pushw	1
	push	xiz
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper4
	lda	xsp, (xsp+14)
	ld	wa, hl
	cp	wa, 0:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Epilogue3
	ld	wa, (xsp+18)
	set	3, wa
	pushw	wa
	ld	xwa, (xiz+34)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	push	xiz
	calr	SeqStep_FileIoCheck
	lda	xsp, (xsp+14)
	ld	(xiz+34), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip6
	ldw	hl, 10
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue3
SeqByteBlock_StyleBitmapRef_Code_Skip6:
	ld	xwa, (xiz+34)
	ld	hl, (xwa+20)
SeqByteBlock_StyleBitmapRef_Code_Epilogue3:
	pop	xiz
	inc	6, xsp
	ret
SeqByteBlock_StyleBitmapRef_Code_Helper6_Helper:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, (xsp+20)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpw	(xsp+28), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip
	ld	hl, 0:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue4
SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip:
	ld	xwa, (xiz+30)
	ld	(xsp+6), xwa
	ld	xbc, (xiz+22)
	ld	xwa, (xsp+6)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	div	bc, (xwa+40)
	ld	(xsp+4), bc
	ld	wa, (xsp+28)
	exts	xwa
	ld	xbc, xwa
	; v10 does not spell this byte either
	add	xbc, (xiz+22)
	; v10 does not spell this byte either
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper4
	add	xsp, 14
	cp	hl, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip7
	ld	a, l
	exts	wa
	ld	(124220:24), wa
	ld	(xiz+6), wa
	ld	hl, 0:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue4
SeqByteBlock_StyleBitmapRef_Code_Skip7:
	ld	xwa, (xiz+34)
	or	xwa, xwa
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip8
	ld	xwa, (xiz+34)
	ld	a, (xwa+22)
	and	a, 3
	cp	a, 3:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip9
	ld	xwa, (xiz+34)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	resm	3, (xwa+22)
SeqByteBlock_StyleBitmapRef_Code_Skip8:
	pushw	40
	ld	xwa, 0:i3
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	push	xiz
	calr	SeqStep_FileIoCheck
	lda	xsp, (xsp+14)
	ld	(xiz+34), xhl
	or	xhl, xhl
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip9
	; v10 does not spell this byte either
	ldw	(xiz+6), 10
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	stiw_da	(124220), 10
	ld	hl, 0:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue4
SeqByteBlock_StyleBitmapRef_Code_Skip9:
	ld	xbc, (xiz+34)
	ld	xwa, (xsp+24)
	ld	(xbc+12), xwa
	ld	wa, (xsp+28)
	ld	(xsp+4), wa
	ld	bc, (xsp+4)
	extz	xbc
	ld	xwa, (xsp+6)
	; v10 does not spell this byte either
	div	bc, (xwa+38)
	ld	(xsp+4), bc
	ld	xbc, (xiz+34)
	lda	xbc, (xbc+16)
	ld	wa, (xsp+4)
	; v10 does not spell this byte either
	cp	wa, (xsp+10)
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip2
	ld	wa, (xsp+4)
	jr	SeqByteBlock_StyleBitmapRef_Code_Join2
SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip2:
	ld	wa, (xsp+10)
SeqByteBlock_StyleBitmapRef_Code_Join2:
	ld	(xbc), wa
	ld	xwa, (xiz+34)
	ld	wa, (xwa+16)
	ld	(xsp+4), wa
	; v10 does not spell this byte either
	cpw	(xsp+30), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip10
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
	jr	SeqByteBlock_StyleBitmapRef_Code_Join3
SeqByteBlock_StyleBitmapRef_Code_Skip10:
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
SeqByteBlock_StyleBitmapRef_Code_Join3:
	ld	xwa, (xiz+34)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	resm	3, (xwa+22)
	ld	xbc, (xiz+34)
	ld	xwa, 0:i3
	ld	(xbc+12), xwa
	ld	xwa, (xiz+34)
	; v10 does not spell this byte either
	cpw	(xwa+20), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip3
	ld	hl, 0:i3
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper5_Join
SeqByteBlock_StyleBitmapRef_Code_Helper5_Skip3:
	ld	bc, (xsp+4)
	ld	xwa, (xsp+6)
	; v10 does not spell this byte either
	mul	bc, (xwa+38)
	ld	hl, bc
SeqByteBlock_StyleBitmapRef_Code_Helper5_Join:
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+6)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	div	bc, (xwa+40)
	sub	(xiz+44), bc
	ld	xwa, (xiz+34)
	ld	(xwa+22), 0
	ld	xwa, (xiz+34)
	; v10 does not spell this byte either
	cpw	(xwa+20), 35
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Epilogue4
	ld	xwa, (xiz+34)
	ldw	(xwa+20), 0
SeqByteBlock_StyleBitmapRef_Code_Epilogue4:
	pop	xiz
	lda	xsp, (xsp+12)
	ret
SeqByteBlock_StyleBitmapRef_Code_Helper6:
	dec	4, xsp
	pushw	iz
	ldw	(xsp+2), 0
	ld	wa, (xsp+18)
	ld	(xsp+4), wa
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cp	xbc, (xwa+22)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ormi16	(xwa+6), 32768
	ld	hl, 0:i3
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue5
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip:
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sub	xbc, (xwa+22)
	ld	wa, (xsp+18)
	extz	xwa
	cp	xwa, xbc
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip2
	ld	wa, (xsp+18)
	extz	xwa
	ld	xbc, xwa
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Join
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip2:
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+71)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	sub	xbc, (xwa+22)
SeqByteBlock_StyleBitmapRef_Code_Helper6_Join:
	ld	(xsp+18), bc
	; v10 does not spell this byte either
	cpw	(xsp+18), 0
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip12
SeqByteBlock_StyleBitmapRef_Code_Helper6_Loop:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	and	xbc, (xwa+22)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip3
	ld	xwa, (xsp+10)
	cpw	(xwa+6), 35
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip3
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip3
	; v10 does not spell this byte either
	cpw	(xsp+20), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip3
	ld	xwa, (xsp+10)
	ld	xbc, (xwa+30)
	ld	wa, (xsp+18)
	; v10 does not spell this byte either
	cp	wa, (xbc+38)
	jrl	nc, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip6
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip3:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip4
SeqByteBlock_StyleBitmapRef_Code_Helper6_Loop2:
	pushw	64
	ld	xwa, (xsp+12)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper5
	inc	6, xsp
	ld	wa, hl
	cp	wa, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip11
	ld	a, l
	exts	wa
	ld	(124220:24), wa
	ld	hl, (xsp+2)
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue5
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip4:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	; v10 does not spell this byte either
	bitm	0, (xwa+22)
	; v10 does not spell this byte either
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Loop2
SeqByteBlock_StyleBitmapRef_Code_Skip11:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	and	xbc, (xwa+22)
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	de, (xwa+38)
	sub	de, bc
	ld	wa, bc
	extz	xwa
	lda	xbc, (xwa+26)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	add	xbc, (xwa+34)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	; v10 does not spell this byte either
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip8
	; v10 does not spell this byte either
	cpw	(xsp+20), 0
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip8
	cp	(xsp+18), de
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip5
	ld	wa, (xsp+18)
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Join2
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip5:
	ld	wa, de
SeqByteBlock_StyleBitmapRef_Code_Helper6_Join2:
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
	; v10 does not spell this byte either
	cpw	(xsp+18), 0
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Join4
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip6:
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Helper
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpw	(xwa+6), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip7
	ld	hl, (xsp+2)
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue5
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip7:
	sub	(xsp+18), iz
	ld	wa, iz
	extz	xwa
	add	(xsp+14), xwa
	add	(xsp+2), iz
	ld	bc, iz
	extz	xbc
	ld	xwa, (xsp+10)
	add	(xwa+22), xbc
	jr	SeqByteBlock_StyleBitmapRef_Code_Join4
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip8:
	cp	(xsp+18), de
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip9
	ld	wa, (xsp+18)
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Join3
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip9:
	ld	wa, de
SeqByteBlock_StyleBitmapRef_Code_Helper6_Join3:
	ld	iz, wa
	cp	iz, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Join4
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip10
	cp	(xbc), 13
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip10
	inc	1, xbc
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Join4
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip10:
	decm	1, (xsp+18)
	incw	1, (xsp+2)
	ldb_spi	e, 228
	ld	xwa, (xsp+14)
	lda_dpi	xiy, 224
	ld	(xsp+14), xwa
	ld	xwa, (xsp+10)
	cp	(xwa+2), e
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Join4
	; v10 does not spell this byte either
	cpw	(xsp+20), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper6_Join4
	ldw	(xsp+18), 0
	ld	iz, 1:i3
SeqByteBlock_StyleBitmapRef_Code_Helper6_Join4:
	ld	xwa, (xsp+10)
	ld	xde, 1:i3
	add	(xwa+22), xde
	djnz16	iz, -68
SeqByteBlock_StyleBitmapRef_Code_Join4:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	and	xbc, (xwa+22)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip11
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+34)
	; v10 does not spell this byte either
	resm	3, (xwa+22)
	ld	xwa, (xsp+10)
	ld	xbc, 0:i3
	ld	(xwa+34), xbc
	; v10 does not spell this byte either
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip11:
	cpw	(xsp+18), 0
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper6_Loop
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip12:
	ld	wa, (xsp+2)
	.byte 0x9f	; v10 does not spell this byte either
	.byte 0x04	; v10 does not spell this byte either
	.byte 0xf0	; v10 does not spell this byte either
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip13
	ld	xwa, (xsp+10)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ormi16	(xwa+6), 32768
SeqByteBlock_StyleBitmapRef_Code_Helper6_Skip13:
	ld	hl, (xsp+2)
SeqByteBlock_StyleBitmapRef_Code_Epilogue5:
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper6
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper6
	lda	xsp, (xsp+12)
	ret
SeqByteBlock_StyleBitmapRef_Code_Helper7:
	dec	6, xsp
	pushw	iz
	ldw	(xsp+2), 0
	ldw	(xsp+6), 0
	cpw	(xsp+20), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	setm	7, (xwa+3)
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	setm	5, (xwa+64)
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip:
	cpw	(xsp+20), 0
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip14
SeqByteBlock_StyleBitmapRef_Code_Helper7_Loop:
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
	; v10 does not spell this byte either
	and	xbc, (xwa+22)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip2
	ld	xwa, (xsp+12)
	cpw	(xwa+6), 35
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip2
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip2
	cpw	(xsp+22), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip2
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+38)
	cp	(xsp+20), wa
	jrl	ge, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip6
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip2:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip12
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpw	(xsp+4), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip3
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+38)
	cp	(xsp+20), wa
	jr	ge, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip4
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip3:
	ldw	wa, 64
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper7_Join
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip4:
	ldw	wa, 96
SeqByteBlock_StyleBitmapRef_Code_Helper7_Join:
	pushw	wa
	ld	xwa, (xsp+14)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper5
	inc	6, xsp
	ld	wa, hl
	cp	wa, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip12
	ld	a, l
	exts	wa
	ld	(124220:24), wa
	ld	hl, (xsp+2)
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue6
SeqByteBlock_StyleBitmapRef_Code_Skip12:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
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
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_rr	xde, xwa, bc
	ld	xwa, (xsp+12)
	bitm	2, (xwa+3)
	; v10 does not spell this byte either
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip8
	; v10 does not spell this byte either
	cpw	(xsp+22), 0
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip8
	cp	(xsp+20), hl
	jr	ge, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip5
	ld	wa, (xsp+20)
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper7_Join2
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip5:
	ld	wa, hl
SeqByteBlock_StyleBitmapRef_Code_Helper7_Join2:
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
	; v10 does not spell this byte either
	cpw	(xsp+20), 0
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Join5
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip6:
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper6_Helper
	lda	xsp, (xsp+12)
	ld	iz, hl
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpw	(xwa+6), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip7
	ld	hl, (xsp+2)
	jrl	SeqByteBlock_StyleBitmapRef_Code_Epilogue6
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip7:
	sub	(xsp+20), iz
	ld	xwa, (xsp+16)
	lda_rr	xwa, xwa, iz
	ld	(xsp+16), xwa
	add	(xsp+2), iz
	ld	bc, iz
	exts	xbc
	ld	xwa, (xsp+12)
	add	(xwa+22), xbc
	jrl	SeqByteBlock_StyleBitmapRef_Code_Join5
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip8:
	cp	(xsp+20), hl
	jr	ge, SeqByteBlock_StyleBitmapRef_Code_Skip13
	ld	wa, (xsp+20)
	jr	SeqByteBlock_StyleBitmapRef_Code_Helper7_Join3
SeqByteBlock_StyleBitmapRef_Code_Skip13:
	ld	wa, hl
SeqByteBlock_StyleBitmapRef_Code_Helper7_Join3:
	ld	iz, wa
	cp	iz, 0:i3
	jrl	z, SeqByteBlock_StyleBitmapRef_Code_Join5
SeqByteBlock_StyleBitmapRef_Code_Helper7_Loop2:
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	bitm	2, (xwa+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip10
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpw	(xsp+6), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip9
	stib_dsp	232, 10
	ldw	(xsp+6), 0
	decm	1, (xsp+20)
	; v10 does not spell this byte either
	cpw	(xsp+22), 0
	jr	z, 95
	ldw	(xsp+20), 0
	ld	iz, 1:i3
	jr	86
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip9:
	ld	xwa, (xsp+16)
	.byte 0x80	; v10 does not spell this byte either
	push	xsp
	ldw	(110:8), 62736:io
	.byte 0xe8	; v10 does not spell this byte either
	nop
	decf
	ld	xwa, 1:i3
	add	(xsp+16), xwa
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ldw	(xsp+6), 1
	jr	15
	ld	xwa, (xsp+16)
	ldb_spi	c, 224
	lda_dpi	xhl, 232
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incw	1, (xsp+2)
	jr	42
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip10:
	ld	xwa, (xsp+16)
	ldb_spi	c, 224
	ld	(xde), c
	ld	(xsp+16), xwa
	decm	1, (xsp+20)
	incw	1, (xsp+2)
	ld	xwa, (xsp+12)
	ld	a, (xwa+2)
	cp_spib	a, 232
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip11
	; v10 does not spell this byte either
	cpw	(xsp+22), 0
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip11
	ldw	(xsp+20), 0
	ld	iz, 1:i3
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip11:
	ld	xwa, (xsp+12)
	ld	xbc, 1:i3
	add	(xwa+22), xbc
	sub	iz, 1
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Loop2
SeqByteBlock_StyleBitmapRef_Code_Join5:
	ld	xwa, (xsp+12)
	ld	xbc, (xwa+22)
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	cp	xbc, (xwa+71)
	jr	ule, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip12
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	ld	xbc, xwa
	ld	xwa, (xwa+22)
	ld	(xbc+71), xwa
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip12:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+30)
	ld	xbc, (xwa+4)
	ld	xwa, (xsp+12)
	; v10 does not spell this byte either
	and	xbc, (xwa+22)
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip13
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	resm	3, (xwa+22)
	ld	xwa, (xsp+12)
	ld	xbc, 0:i3
	ld	(xwa+34), xbc
	; v10 does not spell this byte either
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip13:
	cpw	(xsp+20), 0
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Helper7_Loop
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip14:
	ld	hl, (xsp+2)
SeqByteBlock_StyleBitmapRef_Code_Epilogue6:
	popw	iz
	inc	6, xsp
	ret
SeqChan_ProcessEventArg0:
	pushw	0
	pushm	(xsp+14)
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper7
	lda	xsp, (xsp+12)
	ret
SeqChan_ProcessEventArg1:
	pushw	1
	pushm	(xsp+14)
	ld	xwa, (xsp+12)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper7
	lda	xsp, (xsp+12)
	ret
SeqChan_ValidateAndDispatch:
	push	xiz
	ld	xiz, (xsp+8)
	ld	xwa, (xiz+34)
	or	xwa, xwa
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip15
	ld	xwa, (xiz+34)
	resm	3, (xwa+22)
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip15:
	cpib_da	(254690), 0
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Entry
	ld	hl, 0:i3
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue7
SeqByteBlock_StyleBitmapRef_Code_Entry:
	bitm	7, (xiz+3)
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip16
	push	xiz
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper2
	inc	4, xsp
	cp	hl, 0:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Epilogue7
SeqByteBlock_StyleBitmapRef_Code_Helper7_Skip16:
	ld	xwa, (xiz+18)
	decm8	1, (xwa+3)
	ld	(xiz+4), 0
	push	xiz
	calr	SeqStep_FileBufferFinal
	inc	4, xsp
SeqByteBlock_StyleBitmapRef_Code_Epilogue7:
	pop	xiz
	ret
SeqChan_TraverseAndProcess:
	dec	4, xsp
	push	xiz
	ldw	(xsp+6), 0
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+71)
	.byte 0xaf, 0x10, 0xf0
	jr	nc, SeqByteBlock_StyleBitmapRef_Code_Skip15
	ld	xwa, (xsp+12)
	.byte 0xb8, 0x03, 0xc9
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip14
	ldw	(xsp+6), 20
	jrl	SeqByteBlock_StyleBitmapRef_Code_Join6
SeqByteBlock_StyleBitmapRef_Code_Skip14:
	ld	xwa, (xsp+12)
	ld	xbc, xwa
	ld	xwa, (xwa+71)
	ld	(xbc+22), xwa
	pushw 32
	ld	xwa, (xsp+14)
	push	xwa
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper5
	inc	6, xsp
	ld	(xsp+6), hl
	ld	wa, (xsp+6)
	cp	wa, 0:i3
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Join6
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
	cp	wa, 0:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Join6
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+71), xbc
	ld	xwa, (xsp+12)
	.byte 0xb8, 0x03, 0xbf
SeqByteBlock_StyleBitmapRef_Code_Skip15:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	or	xwa, xwa
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip16
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+34)
	.byte 0x88, 0x16, 0x3c, 0xe7
	ld	xwa, (xsp+12)
	ld	xbc, 0:i3
	ld	(xwa+34), xbc
SeqByteBlock_StyleBitmapRef_Code_Skip16:
	ld	xwa, (xsp+12)
	ld	xbc, (xsp+16)
	ld	(xwa+22), xbc
	lda	xwa, (135706:24)
	ld	xiz, xwa
	ldw	(xsp+4), 0
	.byte 0x9f, 0x04, 0x3f, 0x0a, 0x00
	jr	ge, SeqByteBlock_StyleBitmapRef_Code_Join6
SeqByteBlock_StyleBitmapRef_Code_Loop2:
	ld	xwa, (xsp+12)
	ld	a, (xwa+5)
	.byte 0x8e, 0x17, 0xf1
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip17
	ld	a, (xiz+22)
	and	a, 3
	cp	a, 3:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip17
	push	xiz
	calr	SeqStep_FileBufferSetup
	inc	4, xsp
	or	(xsp+6), hl
	.byte 0x8e, 0x16, 0x3c, 0xe5
SeqByteBlock_StyleBitmapRef_Code_Skip17:
	incw	1, (xsp+4)
	lda	xiz, (xiz+538)
	.byte 0x9f, 0x04, 0x3f, 0x0a, 0x00
	jr	lt, SeqByteBlock_StyleBitmapRef_Code_Loop2
SeqByteBlock_StyleBitmapRef_Code_Join6:
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
	jrl	nz, SeqByteBlock_StyleBitmapRef_Code_Skip18
	pushw 0
	push	xiz
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper5
	inc	6, xsp
	ld	(xsp+4), hl
	.byte 0x9f, 0x04, 0x3f, 0x00, 0x00
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip18
	ld	xwa, (xiz+34)
	lda	xwa, (xwa+26)
	ld	(xsp+6), xwa
	pushw 228
	pushw 20522
	lda	xwa, (xsp+14)
	push	xwa
	call	Free_Compare2
	ld	(xsp+30), 16
	lda	xwa, (xsp+31)
	push	xwa
	ld	xwa, (xiz+10)
	ld	xwa, (xwa+24)
	call (xwa)
	ld	wa, (xiz+69)
	ld	(xsp+39), wa
	ld	xwa, 0:i3
	ld	(xsp+41), xwa
	ld	xbc, (xsp+18)
	ld	xwa, 32
	add	(xsp+18), xwa
	push	xbc
	lda	xwa, (xsp+26)
	push	xwa
	calr	SeqStep_FileSectorReturn
	ld	(xsp+31), 46
	ld	wa, (xiz+48)
	ld	(xsp+47), wa
	ld	xwa, (xsp+26)
	push	xwa
	lda	xwa, (xsp+34)
	push	xwa
	calr	SeqStep_FileSectorReturn
	lda	xsp, (xsp+28)
	ld	xwa, (xiz+34)
	.byte 0xb8, 0x16, 0xb9
	ld	xwa, (xiz+34)
	.byte 0xb8, 0x16, 0xb3
	ld	xwa, 0:i3
	ld	(xiz+71), xwa
	ld	(xiz+64), 16
	.byte 0xbe, 0x03, 0xbf
SeqByteBlock_StyleBitmapRef_Code_Skip18:
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
	calr	SeqByteBlock_StyleBitmapRef_Code_Helper2
	ld	(xsp+8), hl
	push	xiz
	calr	SeqStep_FileBufferFinal
	or	(xsp+12), hl
	ld	a, (xiz+5)
	extz	wa
	ld	bc, wa
	sla	bc, 2
	lda	xde, (0x210b4:24)
	ld	xwa, 0:i3
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
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip20
	cp	wa, 20
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Skip19
	cp	wa, 1:i3
	jr	nz, SeqByteBlock_StyleBitmapRef_Code_Skip21
	push	xiz
	calr	SeqStep_FileBufferFinal
	inc	4, xsp
	cp	hl, 0:i3
	jr	z, SeqByteBlock_StyleBitmapRef_Code_Join7
	ldw	hl, 0xffff
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue8
SeqByteBlock_StyleBitmapRef_Code_Skip19:
	ld	xwa, 4:i3
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
SeqByteBlock_StyleBitmapRef_Code_Join7:
	ld	hl, 0:i3
	jr	SeqByteBlock_StyleBitmapRef_Code_Epilogue8
SeqByteBlock_StyleBitmapRef_Code_Skip20:
	push	xiz
	calr	61237
	inc	4, xsp
	ld	(xiz+52), 229
	setm	7, (xiz+3)
	jr	SeqByteBlock_StyleBitmapRef_Code_Join7
SeqByteBlock_StyleBitmapRef_Code_Skip21:
	ldw	(0x1e53c:24), 18
	ldw	hl, 0xffff
SeqByteBlock_StyleBitmapRef_Code_Epilogue8:
	pop	xiz
	ret

SeqStep_CountValidSectors:
	push xiz
	ldiw_erp 0xfa, 0
	ldw (0x01e53c:24), 0x0000
	ld iz, 0:i3
	jr SeqStep_CountLoop_Compare

SeqStep_CountLoop_Body:
	pushw iz
	ld xwa, (xsp + 10)
	push xwa
	calr SeqStep_FileSectorError
	inc 6, xsp
	cp hl, 0:i3
	jr nz, SeqStep_CountLoop_CheckEnd
	inc1w_erp 0xfa

SeqStep_CountLoop_CheckEnd:
	cpw (0x1e53c:24), 0
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
	calr	SeqStep_CountValidSectors
	inc	4, xsp
	ld	bc, hl
	extz	xbc
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+30)
	ld	wa, (xwa+40)
	extz	xwa
	call	InitializeKubo_Helper
	ret
SeqStep_SectorCompareBlock:
	ld	xde, (xsp+4)
	cpw	(xsp+8), 0
	jr	z, SeqStep_SectorCompareBlock_Skip4
	ld	bc, (xsp+10)
	and	bc, 24
	ld	a, (xde+64)
	extz	wa
	and	wa, 24
	cp	wa, bc
	jr	z, SeqStep_SectorCompareBlock_Skip
	ldw	(0x1e53c:24), 13
	ldw	hl, 0xffff
	ret
SeqStep_SectorCompareBlock_Skip:
	ld	wa, (xsp+10)
	ld	(xde+64), a
	setm	7, (xde+3)
SeqStep_SectorCompareBlock_Skip4:
	ld	l, (xde+64)
	extz	hl
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
	jr	nz, SeqStep_SectorCompareBlock_Entry
	ldw	hl, 0xffff
	jr	SeqStep_SectorCompareBlock_Epilogue
SeqStep_SectorCompareBlock_Entry:
	pushm	(xsp+14)
	pushw	1
	push	xiz
	calr	SeqStep_SectorCompareBlock
	ld	(xsp+12), hl
	push	xiz
	call	FileClose
	lda	xsp, (xsp+12)
	ld	hl, (xsp+4)
SeqStep_SectorCompareBlock_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
	ld	hl, (xsp+8)
	ld	xbc, (xsp+4)
	ld	xwa, (xbc+30)
	ld	wa, (xwa+36)
	dec	8, wa
	cp	hl, wa
	jr	ule, SeqStep_SectorCompareBlock_Skip2
	ld	hl, 0:i3
	ret
SeqStep_SectorCompareBlock_Skip2:
	cp	hl, 0:i3
	jr	z, SeqStep_SectorCompareBlock_Skip3
	pushw	hl
	push	xbc
	calr	SeqStep_FileSectorError
	inc	6, xsp
	ret
SeqStep_SectorCompareBlock_Skip3:
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
	ld xwa, 0:i3
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
	ld	hl, 0:i3
	ret
SeqChan_ByteBlockB:
	ld	hl, 0:i3
	ret
SeqChan_ByteBlockC:
	push	xiz
	ld	xiz, (xsp+20)
	call	SeqChan_ByteBlockC_Helper
	cp	hl, 0:i3
	jr	z, SeqChan_ByteBlockC_Skip
	call	FDC_ClearDiskChangeStatus
	ld	hl, 6:i3
	jrl	SeqChan_ByteBlockC_Epilogue
SeqChan_ByteBlockC_Skip:
	call	FDC_ReadDiskType
	cp	l, 2:i3
	jr	nz, SeqChan_ByteBlockC_Skip3
	.byte 0x9f, 0x0c, 0x3f, 0x00, 0x00
	jr	nz, SeqChan_ByteBlockC_Skip3
	.byte 0x9f, 0x0e, 0x3f, 0x00, 0x00
	jr	nz, SeqChan_ByteBlockC_Skip3
	.byte 0x9f, 0x10, 0x3f, 0x01, 0x00
	jr	nz, SeqChan_ByteBlockC_Skip3
	ldw	(35188:16), 65535
	push	xiz
	.byte 0x0b, 0x01, 0x00, 0x0b, 0x01, 0x00, 0x0b, 0x00, 0x00, 0x0b, 0x00, 0x00
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 3
	calr	SeqStep_ParseVariableHeader
	lda	xsp, (xsp+16)
	ldw	(35188:16), 0
	cp	hl, 0:i3
	jr	nz, SeqChan_ByteBlockC_Skip2
	ld	(xiz+16), 2
	ld	hl, 0:i3
	jr	SeqChan_ByteBlockC_Epilogue
SeqChan_ByteBlockC_Skip2:
	pushw 512
	pushw 228
	pushw 20536
	push	xiz
	call	16713148
	lda	xsp, (xsp+10)
	ld	hl, 0:i3
	jr	SeqChan_ByteBlockC_Epilogue
SeqChan_ByteBlockC_Skip3:
	push	xiz
	.byte 0x9f, 0x16, 0x04, 0x9f, 0x16, 0x04, 0x9f, 0x14, 0x04, 0x9f, 0x18, 0x04
	ld	xwa, (xsp+20)
	ld	a, (xwa+4)
	extz	wa
	pushw	wa
	pushw 3
	calr	SeqStep_ParseVariableHeader
	lda	xsp, (xsp+16)
SeqChan_ByteBlockC_Epilogue:
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
	pushw	4
	calr	SeqStep_ParseVariableHeader
	lda	xsp, (xsp+16)
	ret
SeqChan_ByteBlockD_Helper:
	dec	2, xsp
	push	xiz
	ld	xiz, (xsp+14)
	ld	xbc, (xsp+10)
	ldw	(xsp+4), 0
	cpw	(xbc), 0
	jr	nz, SeqChan_ByteBlockD_Helper_Skip
	ld	hl, 0:i3
	jrl	SeqChan_ByteBlockD_Epilogue
SeqChan_ByteBlockD_Helper_Skip:
	incw	1, (0x2271e:24)
	ld	wa, (xbc)
	cp	wa, 49
	jr	z, SeqChan_ByteBlockD_Helper_Skip3
	cp	wa, 48
	jr	z, SeqChan_ByteBlockD_Helper_Skip3
	cp	wa, 6:i3
	jr	z, SeqChan_ByteBlockD_Helper_Skip2
	cp	wa, 51
	jr	z, SeqChan_ByteBlockD_Skip
	cp	wa, 53
	jr	z, SeqChan_ByteBlockD_Skip
	cp	wa, 47
	jr	nz, SeqChan_ByteBlockD_Skip3
	ldw (xbc), 31
	ld	hl, 0:i3
	jrl	SeqChan_ByteBlockD_Epilogue
SeqChan_ByteBlockD_Skip:
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 33
	ld	xwa, (xiz)
	push	xwa
	calr	SeqChan_ByteBlockA
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cp	hl, 0:i3
	jr	z, SeqChan_ByteBlockD_Entry
	ld	(xiz+20), hl
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Entry:
	ldw	(xsp+4), 1
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Helper_Skip2:
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 6
	ld	xwa, (xiz)
	ld	xwa, (xwa+26)
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	4, xsp
	cp	hl, 0:i3
	jr	z, SeqChan_ByteBlockD_Entry2
	ld	(xiz+20), hl
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Entry2:
	ldw	(xsp+4), 1
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Helper_Skip3:
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 32
	ld	xwa, (xiz)
	push	xwa
	calr	SeqChan_ByteBlockA
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cp	hl, 0:i3
	jr	z, SeqChan_ByteBlockD_Skip2
	ld	(xiz+20), hl
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Skip2:
	ld	hl, 0:i3
	jr	SeqChan_ByteBlockD_Epilogue
SeqChan_ByteBlockD_Skip3:
	ld	xwa, (xiz)
	resm	3, (xwa+2)
	ldw	(xbc), 36
	ld	xwa, (xiz)
	push	xwa
	calr	SeqChan_ByteBlockA
	ld	xwa, (xiz)
	push	xwa
	call	SeqByteBlock_StyleBitmapRef_0x736
	inc	8, xsp
	cp	hl, 0:i3
	jr	z, SeqChan_ByteBlockD_Helper_Skip4
	ld	(xiz+20), hl
	jr	SeqChan_ByteBlockD_Entry3
SeqChan_ByteBlockD_Helper_Skip4:
	ldw	(xsp+4), 1
SeqChan_ByteBlockD_Entry3:
	cpw_da	(141086), 1
	jr	lt, SeqChan_ByteBlockD_Helper_Skip5
	ld	hl, 0:i3
	jr	SeqChan_ByteBlockD_Epilogue
SeqChan_ByteBlockD_Helper_Skip5:
	ld	hl, (xsp+4)
SeqChan_ByteBlockD_Epilogue:
	pop	xiz
	inc	2, xsp
	ret
SeqChan_ByteBlockE:
	; framing ported from v10's source for the same label (same span length, statement for statement); 116 of 134 slots byte-identical
	lda	xsp, (xsp-12)
	pushw	iz
	ldw	(141086:24), 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	bc, (xwa+50)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	wa, qbc
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16712763
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	bc, (xwa+52)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	wa, qbc
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	hl, (xwa+52)
	ld	(xsp+8), hl
SeqChan_ByteBlockD_Helper_Loop:
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	; v10 does not spell this byte either
	or	xwa, xwa
	jrl	z, SeqChan_ByteBlockD_Helper_Skip7
SeqChan_ByteBlockD_Helper_Loop2:
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	; v10 does not spell this byte either
	sub	iz, (xsp+10)
	ld	xwa, (xsp+22)
	cp	(xwa+16), iz
	jr	nc, SeqChan_ByteBlockD_Helper_Skip6
	ld	xwa, (xsp+22)
	ld	iz, (xwa+16)
SeqChan_ByteBlockD_Helper_Skip6:
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
	calr	SeqChan_ByteBlockC
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cp	wa, 0:i3
	jr	nz, SeqChan_ByteBlockD_Helper_Skip8
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	; v10 does not spell this byte either
	cpw	(xwa+16), 0
	jr	z, SeqChan_ByteBlockD_Helper_Skip8
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	mul	bc, (xwa+38)
	.byte 0xa2	; v10 does not spell this byte either
	.byte 0x81	; v10 does not spell this byte either
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	; v10 does not spell this byte either
	cp	bc, (xwa+50)
	; v10 does not spell this byte either
	jr	c, SeqChan_ByteBlockD_Helper_Loop2
	; v10 does not spell this byte either
	ldw	(xsp+10), 0
	incw	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	; v10 does not spell this byte either
	cp	bc, (xwa+52)
	jrl	nz, SeqChan_ByteBlockD_Helper_Loop2
	ldw	(xsp+6), 0
	incw	1, (xsp+8)
	jrl	SeqChan_ByteBlockD_Helper_Loop2
SeqChan_ByteBlockD_Helper_Skip7:
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
	calr	SeqChan_ByteBlockC
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
SeqChan_ByteBlockD_Helper_Skip8:
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	SeqChan_ByteBlockD_Helper
	inc	8, xsp
	cp	hl, 0:i3
	jrl	nz, SeqChan_ByteBlockD_Helper_Loop
	ld	hl, (xsp+12)
	popw	iz
	lda	xsp, (xsp+12)
	ret
SeqChan_ByteBlockF:
	; framing ported from v10's source for the same label (same span length, statement for statement); 116 of 134 slots byte-identical
	lda	xsp, (xsp-12)
	pushw	iz
	ldw	(141086:24), 0
	ld	xwa, (xsp+22)
	ld	xwa, (xwa)
	ld	xwa, (xwa+26)
	ld	(xsp+2), xwa
	ld	xhl, (xsp+18)
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	bc, (xwa+50)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	wa, qbc
	ld	(xsp+10), wa
	ld	xwa, (xsp+2)
	ld	bc, (xwa+50)
	extz	xbc
	ld	xwa, xhl
	call	16712763
	ld	xbc, xhl
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	bc, (xwa+52)
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	ld	wa, qbc
	ld	(xsp+6), wa
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	div	hl, (xwa+52)
	ld	(xsp+8), hl
SeqChan_ByteBlockD_Helper_Loop3:
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+12)
	; v10 does not spell this byte either
	or	xwa, xwa
	jrl	z, SeqChan_ByteBlockD_Helper_Skip10
SeqChan_ByteBlockD_Helper_Loop4:
	ld	xwa, (xsp+2)
	ld	iz, (xwa+50)
	; v10 does not spell this byte either
	sub	iz, (xsp+10)
	ld	xwa, (xsp+22)
	cp	(xwa+16), iz
	jr	nc, SeqChan_ByteBlockD_Helper_Skip9
	ld	xwa, (xsp+22)
	ld	iz, (xwa+16)
SeqChan_ByteBlockD_Helper_Skip9:
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
	calr	SeqChan_ByteBlockD
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
	ld	wa, (xsp+12)
	cp	wa, 0:i3
	jr	nz, SeqChan_ByteBlockD_Helper_Skip11
	ld	xwa, (xsp+22)
	sub	(xwa+16), iz
	ld	xwa, (xsp+22)
	; v10 does not spell this byte either
	cpw	(xwa+16), 0
	jr	z, SeqChan_ByteBlockD_Helper_Skip11
	ld	xwa, (xsp+22)
	lda	xde, (xwa+12)
	ld	bc, iz
	ld	xwa, (xsp+2)
	; v10 does not spell this byte either
	mul	bc, (xwa+38)
	.byte 0xa2	; v10 does not spell this byte either
	.byte 0x81	; v10 does not spell this byte either
	ld	(xde), xbc
	add	(xsp+10), iz
	ld	xwa, (xsp+2)
	ld	bc, (xsp+10)
	; v10 does not spell this byte either
	cp	bc, (xwa+50)
	; v10 does not spell this byte either
	jr	c, SeqChan_ByteBlockD_Helper_Loop4
	; v10 does not spell this byte either
	ldw	(xsp+10), 0
	incw	1, (xsp+6)
	ld	xwa, (xsp+2)
	ld	bc, (xsp+6)
	; v10 does not spell this byte either
	cp	bc, (xwa+52)
	jrl	nz, SeqChan_ByteBlockD_Helper_Loop4
	ldw	(xsp+6), 0
	incw	1, (xsp+8)
	jrl	SeqChan_ByteBlockD_Helper_Loop4
SeqChan_ByteBlockD_Helper_Skip10:
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
	calr	SeqChan_ByteBlockD
	lda	xsp, (xsp+16)
	ld	(xsp+12), hl
SeqChan_ByteBlockD_Helper_Skip11:
	ld	xwa, (xsp+22)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	calr	SeqChan_ByteBlockD_Helper
	inc	8, xsp
	cp	hl, 0:i3
	jrl	nz, SeqChan_ByteBlockD_Helper_Loop3
	ld	hl, (xsp+12)
	popw	iz
	lda	xsp, (xsp+12)
	ret
FDC_ReturnZeroLong:
	ld	xwa, (xsp+4)
	ldw	(xwa), 0
	ret
FDC_ReturnAndPop:
	ld	hl, 1:i3
	ret

FDC_StoreDiskType:
	ld a, (xsp + 4)
	ld (0x03e3e4:24), a
	ldw (0x03e3e6:24), 0x0001
	ld (0x03e3be:24), 0x00
	ret

FDC_ClearDiskChangeStatus:
	ldw	(0x3e3e6:24), 0
	ld	a, (0x3e3e4:24)
	ld	(0x3e3e2:24), a
	ret
SeqChan_ByteBlockC_Helper:
	ld	hl, (0x3e3e6:24)
	ret

FDC_ReadDiskType:
	ld l, (0x03e3e4:24)
	ret

format_FD:
	extz wa
	cp wa, 3:i3
	jrl z, FDC_Format2HD_Start
	cp wa, 2:i3
	jr nz, FDC_Format_InvalidType
	jr FDC_Format2DD_Start

FDC_Format_InvalidType:
	ld hl, 0:i3
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
	cp wa, 6:i3
	jr z, FDC_SectorLen_0x06
	cp wa, 0x33
	jr z, FDC_SectorLen_0x21
	cp wa, 0x35
	jr z, FDC_SectorLen_0x21
	cp wa, 0x2f
	jr nz, FDC_SectorLen_0x24
	ldw (0x01e53c:24), 0x001f
	ret

FDC_SectorLen_0x21:
	ldw (0x01e53c:24), 0x0021
	ret

FDC_SectorLen_0x06:
	ldw (0x01e53c:24), 0x0006
	ret

FDC_SectorLen_0x20:
	ldw (0x01e53c:24), 0x0020
	ret

FDC_SectorLen_0x24:
	ldw (0x01e53c:24), 0x0024
	ret

FDC_Format2DD_Start:
	lda xsp, (xsp - 20)
	pushw_erp 0xfa
	ld wa, 0:i3
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
	ld hl, 0:i3
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
	ld hl, 0:i3
	jrl FDC_CmdFrame_Epilogue

FDC_Format2DD_AllocBuf:
	pushw	512
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, FDC_Format2DD_WriteBoot
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue
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
	jr	z, FDC_Format2DD_WriteFAT1	; -> 0xF51B78
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue	; -> 0xF51E86
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
	jr	z, FDC_Format2DD_WriteFAT2	; -> 0xF51BE5
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue	; -> 0xF51E86
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
	ld	hl, 0:i3
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
	ld	hl, 0:i3
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
	jr	z, FDC_Format2DD_WriteDataSec2	; -> 0xF51CCC
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue	; -> 0xF51E86
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
	ld	hl, 0:i3
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
	ld	hl, 0:i3
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
	jr	z, FDC_Format2DD_TrackInc	; -> 0xF51DA5
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue	; -> 0xF51E86
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
	jr	z, FDC_Format2DD_Side1Inc	; -> 0xF51DE4
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FDC_CmdFrame_Epilogue	; -> 0xF51E86
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
	call	SLIDE_Decompress_4K_Init_Helper
	inc	8, xsp
	cpib_erp	251, 0
	jr	nz, FDC_Format2DD_SetSectorAndRet	; -> 0xF51E7C
	ld	hl, 1:i3
	jr	FDC_CmdFrame_Epilogue	; -> 0xF51E86
FDC_Format2DD_SetSectorAndRet:
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	ld hl, 0:i3

FDC_CmdFrame_Epilogue:
	popw_erp 0xfa
	lda xsp, (xsp + 20)
	ret

FDC_Format2HD_Start:
	lda xsp, (xsp - 20)
	pushw_erp 0xfa
	ld wa, 0:i3
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
	ld hl, 0:i3
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
	ld hl, 0:i3
	jrl FdcOp_Epilogue20

FDC_Format2HD_AllocBuf:
	pushw	512
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	(xsp+2), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, FDC_Format2HD_WriteBoot
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20
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
	jr	z, FDC_Format2HD_WriteFAT1	; -> 0xF51F5E
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20	; -> 0xF521E1
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
	jr	z, FDC_Format2HD_InitTrackLoop	; -> 0xF51FCB
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20	; -> 0xF521E1
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
	jr	z, FDC_Format2HD_TrackInc	; -> 0xF5200B
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20	; -> 0xF521E1
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
	jr	z, FDC_Format2HD_Side2Inc	; -> 0xF520C2
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20	; -> 0xF521E1
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
	jr	z, FDC_Format2HD_Side1Inc	; -> 0xF5213F
	stb_erp	a, 251
	extz	wa
	calr	FDC_SetSectorLength
	ld	xwa, (xsp+2)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	hl, 0:i3
	jrl	FdcOp_Epilogue20	; -> 0xF521E1
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
	call	SLIDE_Decompress_4K_Init_Helper
	inc	8, xsp
	cpib_erp	251, 0
	jr	nz, FDC_Format2HD_SetSectorAndRet	; -> 0xF521D7
	ld	hl, 1:i3
	jr	FdcOp_Epilogue20	; -> 0xF521E1
FDC_Format2HD_SetSectorAndRet:
	stb_erp A, 0xfb
	extz wa
	calr FDC_SetSectorLength
	ld hl, 0:i3

FdcOp_Epilogue20:
	popw_erp 0xfa
	lda xsp, (xsp + 20)
	ret

GetMediaType:
	lda xsp, (xsp - 0x14)
	push QIZ
	call Reset_Floppy_Disk_Controller
	pushw 0x0400
	call SLIDE_Decompress_4K_Init_Helper2
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
	ldw (0x8974:16), 0xffff
	lds_erpb 0xfb, 0
	call Check_for_Floppy_Disk_Change
	cp l, 0:i3
	jr nz, GetMediaType_TryRecalib
	lds_erpb 0xfb, 1
	jrl t, GetMediaType_Epilogue
GetMediaType_TryRecalib:
	lda xwa, (Display_FontPalette_Table_0x24E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
	jr z, GetMediaType_TryFormat2HD
	ldib_erp 0xfb, 0
	jrl GetMediaType_Epilogue

GetMediaType_TryFormat2HD:
	lda xwa, (Display_FontPalette_Table_0x23E:24)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
	jr z, GetMediaType_ReadSector
	ldib_erp 0xfb, 0
	jrl GetMediaType_Epilogue

GetMediaType_ReadSector:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
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
	cp hl, 0:i3
	jr z, GetMediaType_Read2DDSector
	ldib_erp 0xfb, 0
	jr GetMediaType_Epilogue

GetMediaType_Read2DDSector:
	lda xwa, (xsp + 6)
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	cp hl, 0:i3
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
	cp hl, 0:i3
	jr nz, GetMediaType_Epilogue
	ldib_erp 0xfb, 5

GetMediaType_Epilogue:
	ldw (35188:16), 0

	ld xwa, (xsp + 2)

	push xwa

	call	SLIDE_Decompress_4K_Init_Helper

	stb_erp A, 0xfb

	extz wa

	pushw wa

	calr FDC_StoreDiskType

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
	cp wa, 0:i3
	jr mi, FileIO_ReadFreeSpaceViaFAT
	cp wa, 6:i3
	jr gt, FileIO_ReadFreeSpaceViaFAT
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x2AC:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (GetDiskFreeSpace_JumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

GetDiskFreeSpace_JumpTable:
	ld	hl, 0:i3
	jr	GetDiskFreeSpace_Epilogue
	ld	xwa, 0xb2400
	ld	(xiz), xwa
	jr	FileIO_ReadFreeSpaceViaFAT
	ld	xwa, 0x163e00
	ld	(xiz), xwa
	jr	FileIO_ReadFreeSpaceViaFAT
	ld	xwa, 737280
	ld	(xiz), xwa

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
	ld hl, 0:i3
	jr GetDiskFreeSpace_Epilogue

GetDiskFreeSpace_ReadFAT:
	push xiz
	call SeqStep_CalcTotalSectors
	ld xwa, (xsp + 8)
	ld (xwa), xhl
	push xiz
	call FileClose
	inc 8, xsp
	ld hl, 1:i3

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
	cp wa, 0:i3
	jr mi, FileIO_ReadVolumeLabelEntry
	cp wa, 6:i3
	jr gt, FileIO_ReadVolumeLabelEntry
	add wa, wa
	lda xix, (Display_FontPalette_Table_0x2C0:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (GetVolumeLabel_JumpTable:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

GetVolumeLabel_JumpTable:
	ld	xhl, 0:i3
	jrl	GetVolumeLabel_Return

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
	ld xhl, 0:i3
	jr GetVolumeLabel_Return

GetVolumeLabel_ReadDir:
	push xiz
	pushw 0x1
	pushw 0x20
	lda xwa, (xsp + 12)
	push xwa
	call FileRead
	lda xsp, (xsp + 12)
	cp hl, 1:i3
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
	ld	(141099:24), 0
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
	cp hl, 1:i3
	jr z, GetVolumeLabel_ScanEntry

GetVolumeLabel_NotFound:
	push xiz
	call FileClose
	inc 4, xsp
	ld xhl, 0:i3

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
	ld hl, 0:i3
	jr PathInfo_RetVal

PathInfo_BuildAndOpen:
	ld	(xsp+6), 0
	pushw	228
	pushw	20774
	lda	xwa, (xsp+10)
	push	xwa
	call	FileIO_CheckPathAndVolumeLabel_Helper
	ld	xwa, xiz
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	FileIO_CheckPathAndVolumeLabel_Helper
	pushw	228
	pushw	20778
	lda	xwa, (xsp+26)
	push	xwa
	call	FileOpen
	add	xsp, 24
	or	xhl, xhl
	jr	nz, PathInfo_CheckAttrib
	ld	hl, 0:i3
	jr	PathInfo_RetVal
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
	ld hl, 0:i3
	jr PathInfo_RetVal

PathInfo_FoundSubdir:
	ld hl, 1:i3

PathInfo_RetVal:
	pop xiz
	lda xsp, (xsp + 18)
	ret

FileIO_ParsePathComponents:
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xbc
	ld (xsp + 18), xwa
	ld de, 0:i3
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
	call	FileIO_CheckPathAndVolumeLabel_Helper
	inc	8, xsp
	ld	de, 0:i3
	ld	xwa, (xiz)
	inc	1, xwa
	ld	xhl, xwa
FileIO_ParseLoop_Advance:
	ld xwa, 1:i3
	add (xiz), xwa

FileIO_ParseLoop_Test:
	ld xwa, (xiz)
	cp (xwa), 0x0
	jr nz, FileIO_ParseLoop_CheckChar
	ld (xiz), xhl
	ld hl, 0:i3
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
	cp (0x03e3e4:24), 0x05
	jr nz, FindFirst_AllocHandle
	ld xwa, (xsp + 20)
	ld xbc, (xsp + 16)
	calr FindFirst_SndTable
	jrl FdcFile_Epilogue20

FindFirst_AllocHandle:
	pushw	8
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	(xsp+8), xhl
	ld	xwa, xhl
	or	xwa, xwa
	jr	nz, FindFirst_AllocPathBuf
	ld	xhl, 4294967295
	jrl	FdcFile_Epilogue20
FindFirst_AllocPathBuf:
	pushw	260
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, FindFirst_ParseAndOpen
	ld	xwa, (xsp+8)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	xhl, 4294967295
	jrl	FdcFile_Epilogue20
FindFirst_ParseAndOpen:
	ld	xwa, (xsp+20)
	ld	(xsp+12), xwa
	ld	xwa, xiz
	lda	xbc, (xsp+12)
	calr	FileIO_ParsePathComponents
	cp	hl, 0:i3
	jr	z, FindFirst_OpenDir
	ld	xwa, (xsp+8)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	ld	xwa, xiz
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	8, xsp
	ld	xhl, 4294967295
	jrl	FdcFile_Epilogue20
FindFirst_OpenDir:
	pushw	228
	pushw	20784
	ld	xwa, xiz
	push	xwa
	call	FileOpen
	inc	8, xsp
	ld	(xsp+4), xhl
	ld	xwa, (xsp+4)
	or	xwa, xwa
	jr	nz, FindFirst_AllocPattern
	ld	xwa, (xsp+8)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	ld	xwa, xiz
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	8, xsp
	ld	xhl, 4294967295
	jr	FdcFile_Epilogue20
FindFirst_AllocPattern:
	ld	xwa, xiz
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	ld	xwa, (xsp+16)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	1, hl
	pushw	hl
	call	SLIDE_Decompress_4K_Init_Helper2
	lda	xsp, (xsp+10)
	ld	xiz, xhl
	or	xiz, xiz
	jr	nz, FindFirst_CopyAndSearch
	ld	xwa, (xsp+8)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	ld	xhl, 4294967295
	jr	FdcFile_Epilogue20
FindFirst_CopyAndSearch:
	ld	xwa, (xsp+12)
	push	xwa
	push	xiz
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, (xsp+8)
	ld	(xwa+4), xiz
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+4)
	ld	(xwa), xbc
	ld	xwa, (xsp+8)
	ld	xbc, (xsp+16)
	calr	_findnext
	cp	hl, 0:i3
	jr	nz, FindFirst_FailAndClose
	ld	xhl, (xsp+8)
	jr	FdcFile_Epilogue20
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
	cp (0x03e3e4:24), 0x05
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
	call	FileClose
	ld	xwa, xiz
	ld	xwa, (xwa+4)
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	ld	xwa, xiz
	push	xwa
	call	SLIDE_Decompress_4K_Init_Helper
	lda	xsp, (xsp+12)
	ld	hl, 0:i3
FindClose_Return:
	pop xiz
	ret

_findnext:
	lda xsp, (xsp - 64)
	push xiz
	ld xiz, xbc
	cp (0x03e3e4:24), 0x05
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
	cp hl, 1:i3
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
	cp hl, 1:i3
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
	ld wa, 0:i3
	cp (xiz), 0x0
	jr nz, WildMatch_InitBuffer
	ld hl, 0:i3
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
	ld bc, 0:i3
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
	ld hl, 1:i3
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
	ld hl, 0:i3
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
	ldw (0x02272c:24), 0x0000
	lda xwa, (0x02272c:24)
	ld xiz, xwa
	call FileIO_ReadAllDirEntries
	ld xwa, xiz
	ld xbc, (xsp + 4)
	calr FileIO_ReadNextDirEntry
	cp hl, 0:i3
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
	ld hl, 0:i3
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
	cpib_da	(254956), 0
	jr	nz, SndTable_ByteBlock_ReadOps_Code_Entry
	ld	xbc, (0x2357a:24)
	push	xbc
	pushw	1024
	pushw	1
	push	xwa
	call	FileRead
	lda	xsp, (xsp+12)
	cp	hl, 0:i3
	jr	lt, SndTable_ByteBlock_ReadOps_Code_Skip
	ld	hl, 0:i3
	ret
SndTable_ByteBlock_ReadOps_Code_Skip:
	ld	xwa, (0x2357a:24)
	ld	wa, (xwa+6)
	and	wa, 0x7fff
	jr	nz, SndTable_ByteBlock_ReadOps_Skip
	ld	hl, 0:i3
	ret
SndTable_ByteBlock_ReadOps_Skip:
	ldw	hl, 0xffff
	ret
SndTable_ByteBlock_ReadOps_Code_Entry:
	cpib_da	(254956), 1
	jr	nz, SndTable_ByteBlock_ReadOps_Skip2
	calr	FDC_SectorCmd_ByteBlock
	extz	hl
	ret
SndTable_ByteBlock_ReadOps_Skip2:
	ldw	hl, 0xffff
	ret
	dec	2, xsp
	push	xiz
	ld	(0x2357e:24), 1
	ld	xwa, (0x3e3e8:24)
	ld	(0x2272e:24), xwa
	ld	xwa, (0x3e3ee:24)
	ldw	(xwa+2), 0
	ld	xwa, (0x3e3ee:24)
	ldw	(xwa+1030), 0
	ld	xbc, (0x3e3ee:24)
	ld	wa, 2:i3
	call	TaskMsg_Send
	ld	xwa, (0x3e3ee:24)
	lda	xwa, (xwa+1028)
	ld	xbc, xwa
	ld	wa, 2:i3
	call	TaskMsg_Send
	ldw	(xsp+4), 0
	ld	wa, (xsp+4)
	extz	xwa
	cp xwa, (141102:24)
	jrl	ugt, SndTable_ByteBlock_ReadOps_Code_Join
SndTable_ByteBlock_ReadOps_Loop:
	ld	wa, 2:i3
	call	TaskMsg_Receive
	ld	xiz, xhl
	cpw	(xiz+2), 0
	jr	z, SndTable_ByteBlock_ReadOps_Skip3
	ldw (xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	ld	wa, 3:i3
	call	TaskMsg_Send
	jr	SndTable_ByteBlock_ReadOps_Code_Join
SndTable_ByteBlock_ReadOps_Skip3:
	lda	xwa, (xiz+4)
	calr	SndTable_ByteBlock_ReadOps
	cp	hl, 0:i3
	jr	z, SndTable_ByteBlock_ReadOps_Skip4
	ldw (xiz), 0
	ldw (xiz+2), 65534
	ld	xwa, xiz
	ld	xbc, xwa
	ld	wa, 3:i3
	call	TaskMsg_Send
	jr	SndTable_ByteBlock_ReadOps_Code_Join
SndTable_ByteBlock_ReadOps_Skip4:
	ldw	(xiz), 1024
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, (0x2272e:24)
	sub	xbc, xwa
	cp	xbc, 1024
	jr	ugt, SndTable_ByteBlock_ReadOps_Code_Skip2
	ld	wa, (xsp+4)
	extz	xwa
	ld	xbc, (0x2272e:24)
	sub	xbc, xwa
	ld	(xiz), bc
SndTable_ByteBlock_ReadOps_Code_Skip2:
	ldw (xiz+2), 0
	ld	xwa, xiz
	ld	xbc, xwa
	ld	wa, 3:i3
	call	TaskMsg_Send
	addiw_da	(xsp+4), 1024
	ld	wa, (xsp+4)
	extz	xwa
	cp xwa, (141102:24)
	jrl	ule, SndTable_ByteBlock_ReadOps_Loop
SndTable_ByteBlock_ReadOps_Code_Join:
	ld	(0x2357e:24), 0
	call	Show_ScreenGroup_Entry_0x7A
	pop	xiz
	inc	2, xsp
	ret
	ld	xbc, xwa
	dec	1, xwa
	or	xbc, xbc
	ret	z
SndTable_ByteBlock_ReadOps_Code_Loop:
	ld	xbc, xwa
	dec	1, xwa
	or	xbc, xbc
	jr	nz, SndTable_ByteBlock_ReadOps_Code_Loop
	ret

TaskBuf_ReadNextByte:
	pushw iz
	cp (0x02358a:24), 0x01
	jrl nz, TaskBuf_Error
	cpw (0x23580:24), 0
	jr nz, TaskBuf_CheckPendingData
	ld wa, 3:i3
	call TaskMsg_Receive
	ld (0x023582:24), xhl
	ld wa, (xhl)
	ld (0x023580:24), wa
	ld xwa, (0x023582:24)
	inc 4, xwa
	ld (0x023586:24), xwa

TaskBuf_CheckPendingData:
	ld xwa, (0x023582:24)
	cpw (xwa + 2), 0x0
	jr z, TaskBuf_EmptyAndReturn
	ld (0x02358a:24), 0x02
	ld xwa, (0x023582:24)
	ld hl, (xwa + 2)
	jr TaskBuf_PopIzRet

TaskBuf_EmptyAndReturn:
	cpw (0x23580:24), 0
	jr nz, TaskBuf_ReadAndDecrement
	ld (0x02358a:24), 0x02
	ldw hl, 0xffff
	jr TaskBuf_PopIzRet

TaskBuf_ReadAndDecrement:
	ld xbc, (0x023586:24)
	ld xwa, 1:i3
	add (0x023586:24), xwa
	ld a, (xbc)
	ldb_erp A, 0xf8
	extz iz
	subw (0x23580:24), 1
	jr nz, TaskBuf_ReturnByte
	ld xwa, (0x023582:24)
	cpw (xwa), 0x400
	jr z, TaskBuf_SendBufferFull
	ld (0x02358a:24), 0x02
	ld hl, iz
	jr TaskBuf_PopIzRet

TaskBuf_SendBufferFull:
	ld xbc, (0x023582:24)
	ld wa, 2:i3
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
	ld wa, 2:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainQueue2_Done

FDC_DrainQueue2_Loop:
	ld wa, 2:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue2_Loop

FDC_DrainQueue2_Done:
	ld xwa, (0x023582:24)
	ldw (xwa + 2), 0xffff
	ld xbc, (0x023582:24)
	ld wa, 2:i3
	call TaskMsg_Send
	cp (0x02357e:24), 0x00
	jr z, FDC_DrainQueue3_Start

FDC_WaitQueueEmpty_Loop:
	cp (0x02357e:24), 0x00
	jr nz, FDC_WaitQueueEmpty_Loop

FDC_DrainQueue3_Start:
	ld (0x02358a:24), 0x02
	ld wa, 3:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainQueue2B_Start

FDC_DrainQueue3_Loop:
	ld wa, 3:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue3_Loop

FDC_DrainQueue2B_Start:
	ld wa, 2:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr z, FDC_DrainCloseFile

FDC_DrainQueue2B_Loop:
	ld wa, 2:i3
	call TaskMsg_TryReceive
	or xhl, xhl
	jr nz, FDC_DrainQueue2B_Loop

FDC_DrainCloseFile:
	cp (0x03e3ec:24), 0x00
	ret nz
	ld xwa, (0x02357a:24)
	push xwa
	call FileClose
	inc 4, xsp
	ret

SndTable_LookupA:
	ld (0x03e3ec:24), 0x00
	ldw (0x023580:24), 0x0000
	ld (0x02358a:24), 0x01
	lda xbc, (0x022d72:24)
	ld (0x03e3ee:24), xbc
	pushw 0xe4
	pushw 0x5132
	push xwa
	call FileOpen
	inc 8, xsp
	ld (0x02357a:24), xhl
	ld xwa, (0x02357a:24)
	or xwa, xwa
	jr nz, SndTable_LookupA_GotFile
	ld (0x02358a:24), 0x02
	ldw hl, 0xffff
	ret

SndTable_LookupA_GotFile:
	ld xwa, (0x02357a:24)
	ld xwa, (xwa + 71)
	ld (0x03e3e8:24), xwa
	ld wa, 2:i3
	call Show_ScreenGroup
	ld hl, 0:i3
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
	ld	wa, (0x2358c:24)
	ld	xbc, xiz
	calr	FDC_ExecuteSectorCommand
	incw	1, (0x2358c:24)
	cp	hl, 0:i3
	jr	nz, FDC_ExecuteSectorCommand_Epilogue
	ld	de, (0x2358c:24)
	lda	xwa, (xiz+512)
	ld	xbc, xwa
	ld	wa, de
	calr	FDC_ExecuteSectorCommand
	incw	1, (0x2358c:24)
FDC_ExecuteSectorCommand_Epilogue:
	pop	xiz
	ret

SndTable_LookupB:
	jrl TaskBuf_ReadNextByte

SndTable_LookupC:
	calr FDC_DrainQueuesAndReset
	ld (0x03e3ec:24), 0x00
	jrl FDC_RecalibrateCommand

SndTable_LookupD_CalcAddr:
	ld bc, wa
	muls bc, 0x2c
	lda xde, (0x0235a8:24)
	ldw_sri BC, 0x07, 0xe8, 0xe4
	ld (0x02358c:24), bc
	muls wa, 0x2c
	lda xbc, (0x0235a6:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	ld (0x02474e:24), wa
	ld wa, (0x02474e:24)
	extz xwa
	sll xwa, 9
	ld (0x03e3e8:24), xwa
	ld hl, 0:i3
	ret

SndTable_LookupD:
	ld (0x03e3ec:24), 0x01
	ldw (0x023580:24), 0x0000
	ld (0x02358a:24), 0x01
	lda xbc, (0x022d72:24)
	ld (0x03e3ee:24), xbc
	calr SndTable_LookupD_CalcAddr
	cp l, 0:i3
	jr z, SndTable_LookupD_ShowScreen
	ld (0x02358a:24), 0x02
	ld (0x03e3ec:24), 0x00
	ldw hl, 0xffff
	ret

SndTable_LookupD_ShowScreen:
	ld wa, 2:i3
	call Show_ScreenGroup
	ld hl, 0:i3
	ret

FDC_DetectDiskFormat:
	calr FDC_ResetHeadCommand
	cp hl, 0:i3
	jr z, FDC_DetectFormat_ReadSector
	cp hl, 0x31
	jr z, FDC_DetectFormat_ReturnOneB
	cp hl, 0x30
	jr z, FDC_DetectFormat_ReturnOneB
	cp hl, 0xfc
	jr nz, FDC_DetectFormat_ReturnOne
	ld hl, 2:i3
	ret

FDC_DetectFormat_ReturnOne:
	ld hl, 1:i3
	ret

FDC_DetectFormat_ReturnOneB:
	ld hl, 1:i3
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
	cp hl, 0:i3
	jr z, FDC_DetectSector_CheckPianoDisc
	cp hl, 0x31
	jr z, FDC_DetectSector_Return1
	cp hl, 0x30
	jr nz, FDC_DetectSector_Return1B

FDC_DetectSector_Return1:
	ld hl, 1:i3
	ret

FDC_DetectSector_Return2:
	ld hl, 2:i3
	ret

FDC_DetectSector_Return3:
	ld hl, 3:i3
	ret

FDC_DetectSector_Return1B:
	ld hl, 1:i3
	ret

FDC_DetectSector_CheckPianoDisc:
	pushw	11
	pushw	228
	pushw	20790
	lda	xwa, (148302:24)
	push	xwa
	call	SLIDE_Parse_Header_Helper
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, FDC_DetectSector_ReturnPD3
	ld	hl, 0:i3
	ret
FDC_DetectSector_ReturnPD3:
	ld hl, 3:i3
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
	ld iz, 0:i3
	cp iz, 7:i3
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
	cp iz, 7:i3
	jr lt, FileIO_ReadDir_SectorLoop

FileIO_ReadDir_CopyEntries:
	ld iz, 0:i3
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
	ld (0x024750:24), iz
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
	cp hl, 0:i3
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
	calr	AccBuf_ResetAndReload
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
	cp c, 0:i3
	jr nz, Seq_DispatcherTickReturn
	calr SeqTick_ReadControlState
	call Seq_ReadTempoLookup
	calr Seq_ProcessAllInputState
	call Rhythm_CompareAndTrigger
	and (0x3258:16), 0x9f
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
	jr	z, SeqCtl_CheckBit4
	or	a, 1
SeqCtl_CheckBit4:
	bit 5, w
	jr z, SeqCtl_CheckBit5
	or a, 0x2

SeqCtl_CheckBit5:
	ld	(12897:16), a
	xor	a, a
	bit	2, w
	jr	z, SeqCtl_CheckBit2
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
	calr	VoiceParam_ClampAndValidate
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
	ld h, 0x0:opc
	and l, 0xf
	or l, 0x80
	jr TableLoad_Return

VoiceParam_Clamp_CheckBank:
	cp h, 7:i3
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
	bit 2, (0x041e:16)
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
	bit 0, (0x31e7:16)
	jr z, AccInput_CheckRecordMode
	call AccTuning_DisableIfNoStyle
	bit 0, (0x32c7:16)
	jr nz, .Lc_f53166
	calr AccPedal_ProcessAllChanges
AccInput_ProcessWithPedal:
.Lc_f53166:
	calr AccChannel_CompareAndMarkDirty
	calr AccVoice_ProcessPedalChanges
	calr AccVoice_ProcessLeftPedalChanges
	calr AccPitch_CheckTransposeFlags
	calr AccChord_ProcessKeyChanges
	bit 0, (0x32c7:16)
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

	ld a, 0x1:opc

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
	bit 1, (0x323b:16)
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
	or	a, (12921:16)
	and	a, 63
	jrl	z, AccChord_ReadKeysRet	; -> 0xF5331C
	ld	a, (12860:16)
	cp	a, 0:i3
	jr	nz, AccChord_ReadKeysRet	; -> 0xF5331C
	ld	a, (12864:16)
	cp	a, (12860:16)
	jr	z, AccChord_ReadKeysRet	; -> 0xF5331C
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
	cp	a, (12865:16)
	jr	nz, AccChord_CompareNoteC	; -> 0xF532ED
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
	cp a, 0:i3
	jr z, AccDisplay_RefreshDone
	call BitMapOut_CheckDiskAndApply

AccDisplay_RefreshDone:
	pop xwa
	ret

AccState_ReadAccompParams:
	ld A, 0x00:opc
	ei 0x06
	ld (0x0464:16), a
	ld a, (0x0416:16)
	ld (0x31e4:16), a
	ld a, (0x0434:16)
	ld (0x3218:16), a
	ld a, (0x0435:16)
	ld (0x3217:16), a
	ld a, (0x0415:16)
