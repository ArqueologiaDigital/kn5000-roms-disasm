; =============================================================================
; SMF Tone Generation & Voice Synthesis Core (5K lines)
; =============================================================================
;
; Sequencer-driven tone generation: floppy I/O integration, SMF track
; event parsing, voice channel management, tone generator block writes,
; voice synthesis algorithm dispatch, and voice parameter updates.
; Sits in the ROM between SMF playback and SMF event processing.
; =============================================================================

Sequencer_ResetAfterFloppyIO:
	call FloppyIO_ReturnReady
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 0xf19e, xwa
	st16_24 0x00ffec, xwa
	stdi16 0xf19c, 0
	cpdi16 6699, 49
	jrl z, SeqPlay_ReadyStateTransition
	stdi16 6699, 31
	jrl SeqPlay_ReadyStateTransition

SeqPlay_ResetAndStop:
	call FloppyIO_ReturnReady
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 0xf19e, xwa
	st16_24 0x00ffec, xwa
	stdi16 0xf19c, 0
	push xhl
	ldda32 xhl, 6701
	stda16 6699, xhl
	pop xhl
	jrl SeqPlay_ReadyStateTransition

SeqPlay_SetState48AndFloppyReady:
	stdi16 6699, 48

SeqPlay_FloppyReady:
	call FloppyIO_ReturnReady
	jrl SeqPlay_ReadyStateTransition

SeqPlay_FinishFloppyLoadAndStart:
	call VoiceChannels_LoadPartMapAndInitPan
	stdi16 6699, 1
	call SeqPlay_DelayLoop_Outer
	call BitMapOut_RenderDisplay
	ld16_24 xwa, 0x00ffec
	stda16 0xf19e, xwa
	anddi8 0x28a7, 247
	call SeqPlay_CheckStartConditions
	call SeqPlay_InitChannelParams
	stdi16 0xf19c, 0
	call Audio_CheckSubsystemReady

SeqPlay_ReadyStateTransition:
	call SeqStep_PlaybackNop
	ret

SMF_HeaderMagic_MThdMTrk:	.ascii "MThdMTrk"

SeqTrack_ResetAllChannelSlots:
	ldw wa, 0xffff
	ld xix, 0x10b3
	ldw bc, 0x8

SeqTrack_ResetChannelSlots_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ResetChannelSlots_Loop
	xor wa, wa
	ldw bc, 0x28

SeqTrack_ClearRemaining_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ClearRemaining_Loop
	ret

SeqTrack_ScanActiveChannels:
	ld xhl, 0x11f9
	xor iy, iy
	xor a, a

SeqTrack_ScanActiveChannels_Loop:
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	add iy, 0x7
	cp iy, 0xe0
	jrl ule, SeqTrack_ScanActiveChannels_Loop
	ret

SeqTrack_ClearPlaybackBuffers:
	push xwa
	push xbc
	push xix
	xor wa, wa
	ld xix, 0xf72
	ldw bc, 0x8

SeqTrack_ClearPlaybackBuf1_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ClearPlaybackBuf1_Loop
	ld xix, 0xf82
	ldw bc, 0x8

SeqTrack_ClearPlaybackBuf2_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ClearPlaybackBuf2_Loop
	pop xix
	pop xbc
	pop xwa
	ret

; ============================================================================
; FloppyIO_ReadNextByte - Read the next byte from floppy disk buffer
; ============================================================================
; Input:  Implicit (reads from FDC buffer state)
; Output: A = next byte from floppy buffer
; Sequential byte reader for the floppy disk controller. Manages buffer
; refills when the current buffer is exhausted.
; ============================================================================
FloppyIO_ReadNextByte:
	push xix
	ldda32 xix, 4376
	ld_spib A, 0xf0
	cp xix, 0x17f9
	jrl ule, FloppyIO_ReadNextByte_StorePtr
	ld l, a
	pushw hl
	call FileIO_ReadBlockToFilePos
	popw hl
	ld a, l
	incdi16 1, 4327
	pushw wa
	push xhl
	pushw de
	ldda16 xwa, 4327
	xor de, de
	lds hl, 4
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	cps de, 0
	jrl nz, FloppyIO_ReadNextByte_DivDone

FloppyIO_ReadNextByte_DivDone:
	popw de
	pop xhl
	popw wa
	ld xix, 0x13fa

FloppyIO_ReadNextByte_StorePtr:
	stda32 4376, xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6883
	cp xwa, xbc
	jp_24 z, FloppyIO_ReadNextByte_UpdateRemaining
	cpdi8 6887, 1
	jp_24 z, FloppyIO_ReadNextByte_UpdateRemaining
	dec 1, xwa

FloppyIO_ReadNextByte_UpdateRemaining:
	stda32 6883, xwa
	pop xbc
	pop xwa
	pop xix
	ret

SeqTrack_ClearPartParamBuffers:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ldw bc, 0x10
	ld xix, 0xfae

SeqTrack_ClearPartParams_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ClearPartParams_Loop
	pop xix
	popw bc
	popw wa
	ret

FloppyIO_SelectReadMode:
	push xwa
	push xhl
	push xbc
	push xde
	push xix
	push xiy
	push xiz
	xor wa, wa
	cpdi8 4600, 0
	jr z, FloppyIO_SelectReadMode_ModeDefault
	cpdi8 4600, 1
	jr z, FloppyIO_SelectReadMode_Mode0
	ldb a, 0x2
	jp FloppyIO_SelectReadMode_Dispatch

FloppyIO_SelectReadMode_Mode0:
	ldb a, 0x0
	jp FloppyIO_SelectReadMode_Dispatch

FloppyIO_SelectReadMode_ModeDefault:
	ldb a, 0x1

FloppyIO_SelectReadMode_Dispatch:
	call SoundMode_DispatchRender
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

FloppyIO_SwitchboardChannelPtrs:
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

FloppyIO_ConfigureSwitchboard:
	cpdi8 4600, 0
	jrl z, FloppyIO_ConfigSwb_Mode0
	ldb c, 0x0
	anddi8 0xfdad, 251
	stdi8 0xf23d, 0
	jrl FloppyIO_ConfigSwb_QueueEvent

FloppyIO_ConfigSwb_Mode0:
	or a, 0x4
	ldb c, 0xff
	ordi8 0xfdad, 4
	stdi8 0xf23d, 255

FloppyIO_ConfigSwb_QueueEvent:
	call FloppyIO_ComputeSwitchboardAddr
	stdi8 4330, 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	xor a, a
	cpdi8 4600, 0
	jrl nz, FloppyIO_ConfigSwb_DispatchAndReinit
	ldb a, 0x4
	push xhl
	ld xhl, 0xf73d
	andmi8 (xhl), 0xf8
	pop xhl

FloppyIO_ConfigSwb_DispatchAndReinit:
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks
	ret

SeqPlay_PrepareAndScanChannels:
	call SeqPlay_CheckStartConditions
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 0xf19e, xwa
	st16_24 0x00ffec, xwa
	stda16 4237, xwa

SeqPlay_InitTrackLoop:
	stdi8 4009, 0
	call SMF_VoiceSetup_AssignToTrack
	call SeqTrack_ScanActiveChannels
	call SeqTrack_ClearTempoAccumulators
	call SeqTrack_ClearPlaybackBuffers
	call SMF_ReadAndValidateMTrkHeader
	cpdi8 3830, 0
	jrl z, SeqPlay_InitTrackLoop_Continue
	call FloppyIO_ReturnReady
	jrl SeqPlay_CheckLoadStatus

SeqPlay_InitTrackLoop_Continue:
	call SeqTrack_InitScoopAndSetWall
	incdi16 1, 4237
	ldda16 xwa, 4237
	cpda16 xwa, 3934
	jrl c, SeqPlay_InitTrackLoop
	call FloppyIO_ReturnReady
	cpdi8 3830, 0
	jrl nz, SeqPlay_CheckLoadStatus
	call SeqTrack_ValidateAndAssignVoices
	cpdi8 3830, 0
	jrl nz, SeqPlay_CheckLoadStatus
	call VoiceChannels_LoadPartMapAndInitPan

SeqPlay_CheckLoadStatus:
	ret

SeqTrack_AssignFloppyChannels:
	xor iy, iy
	xor ix, ix
	stdi8 5113, 0

SeqTrack_AssignChannel_Loop:
	cpdi16 0xf231, 16
	jrl c, SeqTrack_ErrorMark
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ldda16 xbc, 0x286d
	cp wa, bc
	jrl ugt, SeqTrack_ErrorMark
	cps wa, 0
	jrl z, SeqTrack_ErrorMark
	pushw wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ormi8 (xhl), 0x80
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	popw wa
	ld xhl, 0xf250
	or_srib_im 0x07, 0xec, 0xf4, 0x80
	push xhl
	st_dri3b C, 0x07, 0xec, 0xf4
	ldfr_lerp XHL, 0x38
	pop xhl
	st_dri3w WA, 0x39, 0x01, 0x00
	ld xhl, 0xc9e
	st_dri3w WA, 0x07, 0xec, 0xf0
	ld xhl, 0xcbe
	xor bc, bc
	ldda8 c, 5113
	push xiy
	ld iy, bc
	stiw_dri 0x07, 0xec, 0xf4, 0x05, 0x00
	pop xiy
	add iy, 0x3
	add ix, 0x2
	incdi8 1, 5113
	cpdi8 5113, 16
	jrl c, SeqTrack_AssignChannel_Loop
	jrl SeqTrack_AssignChannels_Done

SeqTrack_ErrorMark:
	stdi8 3830, 255
	stdi8 4323, 255

SeqTrack_AssignChannels_Done:
	ret

FloppyIO_ReadToTrackBuffer:
	ld xix, 0x106e

FloppyIO_ReadTrackBuf_ReadLoop:
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, FloppyIO_ReadTrackBuf_EarlyExit
	pop xbc
	pop xwa
	jp FloppyIO_ReadTrackBuf_StoreByte

FloppyIO_ReadTrackBuf_EarlyExit:
	pop xbc
	pop xwa
	jp FloppyIO_ReadTrackBuf_Done

FloppyIO_ReadTrackBuf_StoreByte:
	lda_dpi XBC, 0xf0
	bit 7, a
	jrl nz, FloppyIO_ReadTrackBuf_ReadLoop
	sub xix, 0x106e

FloppyIO_ReadTrackBuf_Done:
	ret

SeqTrack_DispatchPartEvt:
	call SeqTrack_ClearPartEventParams
	cps ix, 1
	jrl z, SeqTrack_DispatchPart_Mode1
	cps ix, 2
	jrl z, SeqTrack_DispatchPart_Mode2
	jrl SeqTrack_DispatchPart_Mode3

SeqTrack_DispatchPart_Mode1:
	ldda8 a, 4206
	and a, 0x7f
	stda8 4211, a
	jrl SeqTrack_DispatchPart_Done

SeqTrack_DispatchPart_Mode2:
	ldda8 a, 4206
	and a, 0x7f
	rrc a
	ld w, a
	and a, 0x7f
	and w, 0x80
	ldda8 l, 4207
	and l, 0x7f
	or l, w
	stda8 4212, a
	stda8 4211, l
	jrl SeqTrack_DispatchPart_Done

SeqTrack_DispatchPart_Mode3:
	ldda8 a, 4206
	and a, 0x7f
	rrc_i_8 a, 2
	ld w, a
	and a, 0x3f
	and w, 0xc0
	ldda8 l, 4207
	and l, 0x7f
	rrc l
	ld h, l
	and l, 0x7f
	and h, 0x80
	or l, w
	ldda8 c, 4208
	and c, 0x7f
	or c, h
	stda8 4213, a
	stda8 4212, l
	stda8 4211, c

SeqTrack_DispatchPart_Done:
	ret

SeqTrack_ComputeTempoScaling:
	stdi16 3946, 0
	sla iy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	ldda16 xbc, 4211
	ldda8 e, 4213
	xor d, d
	cps de, 0
	jrl z, SeqTrack_ComputeTempo_NoDelta
	pushw wa
	xor wa, wa
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	popw wa
	ldi_werp 0xea, 0
	ldi_werp 0xe6, 0
	add xde, xbc
	cpi_werp 0xea, 0
	jrl ule, SeqTrack_ComputeTempo_Phase2
	pushw wa
	ld wa, de
	lds de, 1
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	popw wa

SeqTrack_ComputeTempo_Phase2:
	ldi_werp 0xe2, 0
	ldi_werp 0xea, 0
	add xwa, xde
	cpi_werp 0xe2, 0
	jrl ule, SeqTrack_ComputeTempo_Phase3
	lds de, 1
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	sla xiy, 1
	push xix
	ld xix, 0xfae
	st_dri3w DE, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_Phase3:
	cpda16 xwa, 3936
	jrl c, SeqTrack_ComputeTempo_Phase3Store
	xor de, de
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	ld wa, de

SeqTrack_ComputeTempo_Phase3Store:
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	sla xiy, 1
	push xix
	ld xix, 0xfae
	st_dri3w WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_NoDelta:
	ldi_werp 0xe2, 0
	ldi_werp 0xe6, 0
	add xwa, xbc
	cpi_werp 0xe2, 0
	jrl ule, SeqTrack_ComputeTempo_NoDeltaDirect
	lds de, 1
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	push xix
	ld xix, 0xfae
	st_dri3w DE, 0x07, 0xf0, 0xf4
	pop xix
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_NoDeltaDirect:
	ldda16 xhl, 3936
	cp wa, hl
	jrl c, SeqTrack_ComputeTempo_NoDeltaStore
	xor de, de
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	adddm16 3946, xwa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	ld wa, de

SeqTrack_ComputeTempo_NoDeltaStore:
	sla iy, 1
	push xix
	ld xix, 0xfae
	st_dri3w WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1

SeqTrack_UpdateVolumesExit:
	ret

SeqTrack_UpdateChannelVolumes:
	xor xiy, xiy

SeqTrack_UpdateVolumes_Loop:
	push xix
	ld xix, 0x11f9
	bit_dri 7, 0x07, 0xf0, 0xf4
	pop xix
	jrl z, SeqTrack_UpdateVolumes_Next
	call SeqTrack_ComputeScaledDelta
	push xix
	ld xix, 0x11f9
	add xix, xiy
	add wa, (xix + 5)
	pop xix
	jrl ov, SeqTrack_UpdateVolumes_Clamp
	cp wa, 0x2fff
	jrl c, SeqTrack_UpdateVolumes_Store

SeqTrack_UpdateVolumes_Clamp:
	ldw wa, 0x2fff

SeqTrack_UpdateVolumes_Store:
	push xix
	ld xix, 0x11f9
	add xix, xiy
	ld (xix + 5), wa
	pop xix

SeqTrack_UpdateVolumes_Next:
	add xiy, 0x7
	cp xiy, 0xe0
	jrl ule, SeqTrack_UpdateVolumes_Loop
	ret

SMF_ParseTrackEvent:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Dispatch

SMF_ParseTrack_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Dispatch:
	stdi8 4009, 0
	cps a, 2
	jrl z, SMF_ParseTrack_MetaEvt02
	cps a, 3
	jrl z, SMF_ParseTrack_MetaEvt03
	cp a, 0x2f
	jrl z, SMF_ParseTrack_MetaEvt2F
	cp a, 0x51
	jrl z, SMF_ParseTrack_MetaEvt51
	cp a, 0x58
	jrl z, SMF_ParseTrack_MetaEvt58
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_ValidateExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_AdvanceAndReturn

SMF_ParseTrack_ValidateExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_AdvanceAndReturn:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt02:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta02_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta02_Advance

SMF_ParseTrack_Meta02_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta02_Advance:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt03:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta03_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta03_Advance

SMF_ParseTrack_Meta03_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta03_Advance:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt2F:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta2F_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta2F_EndOfTrack

SMF_ParseTrack_Meta2F_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta2F_EndOfTrack:
	stdi8 4009, 255
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt51:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta51_Read1_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta51_ReadByte2

SMF_ParseTrack_Meta51_Read1_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta51_ReadByte2:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta51_Read2_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta51_SetTempo

SMF_ParseTrack_Meta51_Read2_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta51_SetTempo:
	call SMF_SetTempoFromMetaEvent
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt58:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ParseTrack_Meta58_EarlyExit
	pop xbc
	pop xwa
	jp SMF_ParseTrack_Meta58_Advance

SMF_ParseTrack_Meta58_EarlyExit:
	pop xbc
	pop xwa
	jp Voice_NullRet

SMF_ParseTrack_Meta58_Advance:
	call Sequencer_AdvanceBlockPosition

Voice_NullRet:
	ret

Voice_ActivateAllChannels:
	xor hl, hl

Voice_ActivateChannels_Loop:
	ld iy, hl
	extz xiy
	sla iy, 1
	add iy, hl
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl z, Voice_ActivateChannels_Next
	ld iy, hl
	pushw hl
	call SoundGen_CaptureVoiceParams
	ldb a, 0x82
	call ToneGen_LoadBlockValidate
	call SoundGen_StoreVoiceParamsToTables
	popw hl

Voice_ActivateChannels_Next:
	inc 1, hl
	cp hl, 0xf
	jrl ule, Voice_ActivateChannels_Loop
	ret

SoundGen_ScanActiveVoiceBitmap:
	xor c, c

SoundGen_ScanBitmap_Loop:
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	jrl nc, SoundGen_ScanBitmap_Next
	stda8 0x2877, c
	incdi8 1, 0x2877
	pushw bc
	call Scoop_SpecialMode_ParamCheckBound
	popw bc

SoundGen_ScanBitmap_Next:
	inc 1, c
	cp c, 0xf
	jrl ule, SoundGen_ScanBitmap_Loop
	ret

FloppyIO_ReturnReady:
	ldb w, 0x1
	ret

SMF_ReadMidiEventToBuffer:
	stda8 4010, a
	xor bc, bc
	ld xix, 0xfab
	lda_dpi XBC, 0xf0
	inc 1, c

SMF_ReadMidiEvt_ReadLoop:
	pushw bc
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ReadMidiEvt_ReadFailed
	pop xbc
	pop xwa
	jp SMF_ReadMidiEvt_CheckSize

SMF_ReadMidiEvt_ReadFailed:
	pop xbc
	pop xwa
	jp SMF_ReadMidiEvt_Done

SMF_ReadMidiEvt_CheckSize:
	lda_dpi XBC, 0xf0
	inc 1, c
	ldda8 a, 4010
	and a, 0xf0
	ldb w, 0x2
	cp a, 0xd0
	jrl z, SMF_ReadMidiEvt_OneByteMsg
	cp a, 0xc0
	jrl nz, SMF_ReadMidiEvt_CheckComplete

SMF_ReadMidiEvt_OneByteMsg:
	ldb w, 0x1

SMF_ReadMidiEvt_CheckComplete:
	cp c, w
	jrl ule, SMF_ReadMidiEvt_ReadLoop
	call MidiEvent_DispatchSetA

SMF_ReadMidiEvt_Done:
	ret

FloppyIO_ReadMidiEventBytes:
	ld c, a
	ldda8 a, 4010
	ld l, a
	and l, 0xf0
	ld xix, 0xfab
	lda_dpi XBC, 0xf0
	xor h, h
	ld a, c

FloppyIO_ReadMidiEvtBytes_Loop:
	lda_dpi XBC, 0xf0
	inc 1, h
	ldb c, 0x1
	cp l, 0xd0
	jrl z, FloppyIO_ReadMidiEvtBytes_OneByteMsg
	cp l, 0xc0
	jrl nz, FloppyIO_ReadMidiEvtBytes_CheckDone

FloppyIO_ReadMidiEvtBytes_OneByteMsg:
	ldb c, 0x0

FloppyIO_ReadMidiEvtBytes_CheckDone:
	cp h, c
	jrl ugt, FloppyIO_ReadMidiEvtBytes_DispatchCheck
	pushw hl
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, FloppyIO_ReadMidiEvtBytes_ReadFailed
	pop xbc
	pop xwa
	jp FloppyIO_ReadMidiEvtBytes_Loop

FloppyIO_ReadMidiEvtBytes_ReadFailed:
	pop xbc
	pop xwa
	jp FloppyIO_ReadMidiEvtBytes_Exit
FloppyIO_ReadMidiEvtBytes_Trap:
	jrl	t, 0xffc3

FloppyIO_ReadMidiEvtBytes_DispatchCheck:
	cpdi16 3932, 0
	jrl z, FloppyIO_DispatchMidiEvent
	cpdi16 3934, 1
	jrl z, FloppyIO_DispatchMidiEvent
	call MidiEvent_DispatchSetB
	jrl FloppyIO_ReadMidiEvtBytes_Exit

FloppyIO_DispatchMidiEvent:
	call MidiEvent_DispatchSetA

FloppyIO_ReadMidiEvtBytes_Exit:
	ret

VoiceChannels_LoadPartMapAndInitPan:
	ld xiy, VoiceChannels_PartMapTable
	cpdi8 4600, 1
	jrl z, VoiceChannels_LoadPartMap_Mode1
	ld xiy, 0xf23e28

VoiceChannels_LoadPartMap_Mode1:
	ld xix, 0xf1a0
	ldw bc, 0x10
	ldir85
	stdi16 0xf290, 0xffff
	call VoiceChannels_InitPanFromPreset
	ret

VoiceChannels_PartMapTable:
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x0c, 0x06, 0x07, 0x11, 0x12, 0x13, 0x05

SeqPlay_DelayLoop_Outer:
	ldw bc, 0xc00

SeqPlay_DelayLoop_InnerInit:
	ldw hl, 0x3c0

SeqPlay_DelayLoop_Inner:
	djnz xhl, SeqPlay_DelayLoop_Inner
	djnz xbc, SeqPlay_DelayLoop_InnerInit
	ret

SeqPlay_InitChannelParams:
	push xiy
	push xde
	push xhl
	xor xhl, xhl
	xor xde, xde
	ldb a, 0x2
	ldb w, 0x80
	ldw bc, 0x10

SeqPlay_InitChannelParams_Loop:
	ld hl, de
	ld xix, FloppyIO_SwitchboardChannelPtrs
	sla hl, 2
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld (xiy + 11), a
	ld (xiy + 10), w
	inc 1, de
	djnz xbc, SeqPlay_InitChannelParams_Loop
	pop xhl
	pop xde
	pop xiy
	ret

FloppyIO_ComputeSwitchboardAddr:
	ld xhl, 0xab000
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	add xhl, xwa
	ld xix, xhl
	add xix, 0xbd
	ld (xix), c
	ret

SMF_VoiceSetup_AssignToTrack:
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	ld ix, iy
	cpdi16 0xf231, 16
	jrl c, SMF_VoiceSetup_Exit
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ldda16 xbc, 0x286d
	cp wa, bc
	jrl ugt, SMF_VoiceSetup_Exit
	cps wa, 0
	jrl z, SMF_VoiceSetup_Exit
	pushw wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ormi8 (xhl), 0x80
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	popw wa
	ld hl, iy
	sla iy, 1
	add iy, hl
	ld xhl, 0xf250
	or_srib_im 0x07, 0xec, 0xf4, 0x80
	ldfr_lerp XHL, 0x38
	st_dri3b C, 0x07, 0xec, 0xf4
	ld (xhl + 1), wa
	ldto_lerp XHL, 0x38
	ld xhl, 0xc9e
	sla ix, 1
	st_dri3w WA, 0x07, 0xec, 0xf0
	ld xhl, 0xcbe
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	stiw_dri 0x07, 0xec, 0xf4, 0x05, 0x00

SMF_VoiceSetup_Exit:
	ret

SeqTrack_ClearTempoAccumulators:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ldw bc, 0x10
	ld xix, 0xfae

SeqTrack_ClearTempoAccum_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, SeqTrack_ClearTempoAccum_Loop
	pop xix
	popw bc
	popw wa
	ret

SMF_ReadAndValidateMTrkHeader:
	lds bc, 4
	ld xiy, SMF_HeaderMagic_MTrk_Ref

SMF_MTrk_ReadByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_MTrk_ReadFailed
	pop xbc
	pop xwa
	jp SMF_MTrk_CompareSignature

SMF_MTrk_ReadFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_MTrk_CompareSignature:
	cp_spib A, 0xf4
	jrl z, SMF_MTrk_SignatureMatch
	stdi8 3830, 255
	stdi16 6699, 49
	jrl SMF_NullRet

SMF_MTrk_SignatureMatch:
	djnz xbc, SMF_MTrk_ReadByteLoop
	stdi8 6887, 1
	call FloppyIO_ReadNextByte
	stda8 6886, a
	call FloppyIO_ReadNextByte
	stda8 6885, a
	call FloppyIO_ReadNextByte
	stda8 6884, a
	call FloppyIO_ReadNextByte
	stda8 6883, a
	stdi8 6887, 0
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_MTrk_FileSizeReadFailed
	pop xbc
	pop xwa
	jp SMF_MTrk_FileSizeReady

SMF_MTrk_FileSizeReadFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_MTrk_FileSizeReady:
	stdi8 4236, 0

SMF_ProcessVoiceData:
	cpdi8 4323, 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_CheckFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_ReadTrackBuffer

SMF_VoiceData_CheckFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_ReadTrackBuffer:
	call FloppyIO_ReadToTrackBuffer
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_ReadTrackFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_DispatchAndParse

SMF_VoiceData_ReadTrackFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_DispatchAndParse:
	call SeqTrack_DispatchPartEvt
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	call SeqTrack_ComputeTempoScaling
	call SeqTrack_UpdateChannelVolumes
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_ParseFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_CheckMetaFlag

SMF_VoiceData_ParseFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_CheckMetaFlag:
	cp a, 0xff
	jrl nz, SMF_VoiceData_CheckSysEx
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_MetaParseFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_CheckEndOfTrack

SMF_VoiceData_MetaParseFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_CheckEndOfTrack:
	cpdi8 4009, 255
	jrl z, SMF_VoiceData_HandleEndOfTrack
	cpdi8 4323, 0
	jrl z, SMF_ProcessVoiceData
	stdi8 3830, 255
	jr SMF_EventFailureExit

SMF_VoiceData_HandleEndOfTrack:
	call SeqTrack_ReleaseVoiceAtEndOfTrack

SMF_VoiceData_DrainRemaining:
	ldda32 xbc, 6883
	lds32 xwa, 0
	cp xbc, xwa
	jp_24 z, SMF_VoiceData_DrainDone
	call FloppyIO_ReadNextByte
	nop
	nop
	nop
	jp SMF_VoiceData_DrainRemaining

SMF_VoiceData_DrainDone:
	jrl SMF_NullRet

SMF_VoiceData_CheckSysEx:
	cp a, 0xf7
	jrl z, SMF_VoiceData_HandleSysEx
	cp a, 0xf0
	jrl nz, SMF_VoiceData_CheckMidiStatus

SMF_VoiceData_HandleSysEx:
	call SMF_ProcessSysExBlock
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_SysExFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_SysExContinue

SMF_VoiceData_SysExFailed:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_SysExContinue:
	jrl SMF_ProcessVoiceData

SMF_VoiceData_CheckMidiStatus:
	bit 7, a
	jrl z, SMF_VoiceData_ReadMidiRunning
	call SMF_ReadMidiEventWithStatus
	cpdi8 4323, 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_MidiStatusFailed
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

SMF_VoiceData_MidiStatusFailed:
	pop xbc
	pop xwa

SMF_EventFailureExit:
	stdi8 3830, 255
	jrl SMF_NullRet

SMF_VoiceData_ReadMidiRunning:
	call FloppyIO_ReadMidiEventBytes
	cpdi8 4323, 0
	jrl nz, SMF_VoiceData_SetErrorFlag
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_VoiceData_RunningMidiFailed
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

SMF_VoiceData_RunningMidiFailed:
	pop xbc
	pop xwa

SMF_VoiceData_SetErrorFlag:
	stdi8 3830, 255

SMF_NullRet:
	ret

SMF_HeaderMagic_MTrk_Ref:	.ascii "MTrk"

SeqTrack_InitScoopAndSetWall:
	xor a, a
	lds hl, 1
	stda8 0x2877, a
	incdi8 1, 0x2877
	stda8 9858, l
	incdi8 1, 9858
	ldda8 a, 0x2877
	stda8 9860, a
	pushw wa
	push xhl
	call SetWall_ValidateAndApply
	pop xhl
	popw wa
	ret

SeqTrack_ValidateAndAssignVoices:
	cpdi16 0xf231, 16
	jrl nc, SeqTrack_AssignVoices_HaveDispatch
	stdi8 4323, 255
	jrl SoundGen_ResetVoiceBitmapAndFlag

SeqTrack_AssignVoices_HaveDispatch:
	ldda16 xde, 0xf251
	ld hl, de
	call ToneGen_CopyBlockToVoiceBuffer
	stda16 0x27d6, xiy
	pushw de
	lds hl, 1

SeqTrack_ClearVoiceSlots_Loop:
	pushw hl
	call VoiceChannel_ResetSlotByIndex
	popw hl
	inc 1, hl
	cp hl, 0x10
	jrl ule, SeqTrack_ClearVoiceSlots_Loop
	popw de
	call SeqTrack_AssignFloppyChannels
	cpdi8 3830, 0
	jrl nz, SoundGen_ResetBitmapDone
	call SoundGen_InitAllVoiceChannels
	stdi8 6650, 0

MidiSysEx_CmdDispatchLoop:
	call ToneGen_ReadAndDispatchVoiceBlock
	ldda8 a, 4211
	cp a, 0x81
	jrl z, MidiSysEx_Cmd_AllNotesOff
	cp a, 0x82
	jrl z, MidiSysEx_Cmd_AllSoundOff
	and a, 0xf0
	cp a, 0x90
	jrl z, MidiSysEx_Cmd_NoteOn
	cp a, 0xa0
	jrl z, MidiSysEx_Cmd_PolyPressure
	cp a, 0xb0
	jrl z, MidiSysEx_Cmd_ControlChange
	cp a, 0xc0
	jrl z, MidiSysEx_Cmd_ProgramChange
	cp a, 0xd0
	jrl z, MidiSysEx_Cmd_ChannelPressure
	cp a, 0xe0
	jrl z, MidiSysEx_Cmd_PitchBend
	cp a, 0xf0
	jrl z, MidiSysEx_Cmd_SystemMessage
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_AllNotesOff:
	ldb a, 0x81
	call ToneGen_WriteAllChannels
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_AllSoundOff:
	ldb a, 0x82
	call ToneGen_WriteAllChannels
	xor hl, hl
	xor iy, iy

MidiSysEx_AllSoundOff_VoiceLoop:
	pushw hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	call SoundGen_StoreVoiceParamsToTables
	popw iy
	popw hl
	inc 1, iy
	inc 1, hl
	cp iy, 0xf
	jrl ule, MidiSysEx_AllSoundOff_VoiceLoop
	call SoundGen_ScanActiveVoiceBitmap
	jrl SoundGen_ResetVoiceBitmapAndFlag

MidiSysEx_Cmd_NoteOn:
	ldda16 xiy, 4211
	and iy, 0xf
	anddi8 4211, 240
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 6
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_PolyPressure:
	cps hl, 3
	jrl z, MidiSysEx_PolyPressure_Mode3
	ldda16 xiy, 4211
	and iy, 0xf
	stdi8 4211, 128
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 4
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_PolyPressure_Mode3:
	ldda16 xiy, 4211
	and iy, 0xf
	stdi8 4211, 208
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ControlChange:
	xor hl, hl
	ldda8 l, 4213
	cp l, 0x7f
	jrl z, MidiSysEx_CmdDispatchLoop
	jrl MidiSysEx_CC_LookupPartMap

MidiSysEx_CC_LookupPartMap:
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	cpdi8 4600, 1
	jrl z, MidiSysEx_CC_PartMapSelected
	ld xix, 0xf2436b

MidiSysEx_CC_PartMapSelected:
	ld_srib3 A, 0x07, 0xf0, 0xec
	pop xix
	stda8 4213, a
	ld iy, hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 6
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ProgramChange:
	xor hl, hl
	ldda8 l, 4213
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	cpdi8 4600, 1
	jrl z, MidiSysEx_PgmChg_PartMapSelected
	ld xix, 0xf2436b

MidiSysEx_PgmChg_PartMapSelected:
	ld_srib3 A, 0x07, 0xf0, 0xec
	pop xix
	stda8 4213, a
	ld iy, hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 6
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ChannelPressure:
	ldda16 xiy, 4211
	and iy, 0xf
	stdi8 4211, 209
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_PitchBend:
	ldda16 xiy, 4211
	and iy, 0xf
	stdi8 4211, 210
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 4
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_SystemMessage:
	ldda16 xiy, 4211
	and iy, 0xf
	stdi8 4211, 211
	call SoundGen_CaptureVoiceParams
	pushw iy
	lds bc, 3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

SoundGen_ResetVoiceBitmapAndFlag:
	call ToneGen_SyncVoiceBitmapFromSlots
	ordi8 0x28b3, 16

SoundGen_ResetBitmapDone:
	ret

SeqTrack_ChannelMapIdentity:
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	9, 10
	pushw	3340
	ret
	retd	256
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	15, 10
	pushw	3340
	ret
	.byte 0x09

ToneGen_ComputeBlockPtr:
	push xiy
	ldda32 xiy, 7514
	extz xhl
	dec 1, xhl
	sla xhl, 8
	add xiy, xhl
	stda32 4349, xiy
	xor xhl, xhl
	pop xiy
	ret

SeqTrack_ClearPartEventParams:
	xor wa, wa
	stda16 4211, xwa
	stda16 4213, xwa
	ret

SoundGen_RefreshAllVoices:
	push xiy
	call SoundGen_CaptureVoiceParams
	pop xiy
	ldda16 xbc, 3946
	ldb a, 0x81

SoundGen_RefreshVoices_Loop:
	ldb a, 0x81
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_RefreshVoices_Done
	djnz xbc, SoundGen_RefreshVoices_Loop
	call ToneGen_WriteChannelRegs
	ordi8 4236, 1
	stdi8 4323, 0

SoundGen_RefreshVoices_Done:
	ret

SeqTrack_ComputeScaledDelta:
	ldda16 xwa, 3936
	cp wa, 0x60
	jrl z, SeqTrack_ScaledDelta_PassThrough
	ldda8 e, 4213
	ldda16 xwa, 4211
	cps e, 0
	jrl z, SeqTrack_ScaledDelta_NoDivide3
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xe2
	stda16 4333, xwa
	stda16 4335, xde
	xor w, w
	ldda8 a, 4213
	mul xwa, xhl
	ldto_werp DE, 0xe2
	addda16 xwa, 4335
	ld de, wa
	ldda16 xwa, 4333
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	jrl SeqTrack_ScaledDelta_Return

SeqTrack_ScaledDelta_NoDivide3:
	ldda16 xwa, 4211
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xe2
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	jrl SeqTrack_ScaledDelta_Return

SeqTrack_ScaledDelta_PassThrough:
	xor de, de
	ldda8 e, 4213
	ldda16 xwa, 4211

SeqTrack_ScaledDelta_Return:
	ret

Sequencer_ValidateFileData:
	call FloppyIO_ClearTrackParseBuffer
	call FloppyIO_ReadVariableLength
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, Sequencer_Validate_ReadFailed
	pop xbc
	pop xwa
	jp Sequencer_Validate_DispatchPart

Sequencer_Validate_ReadFailed:
	pop xbc
	pop xwa
	jp Sequencer_Validate_Done

Sequencer_Validate_DispatchPart:
	call SeqTrack_DispatchPartEvt

Sequencer_Validate_Done:
	ret

Sequencer_AdvanceBlockPosition:
	ldda32 xix, 4376
	addda32 xix, 4211
	cp xix, 0x17f9
	jrl ule, Sequencer_Advance_StorePtr
	push xix
	call FileIO_ReadBlockToFilePos
	pop xix
	incdi16 1, 4327
	pushw wa
	push xhl
	pushw de
	ldda16 xwa, 4327
	xor de, de
	lds hl, 4
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	cps de, 0
	jrl nz, Sequencer_Advance_DivDone

Sequencer_Advance_DivDone:
	popw de
	pop xhl
	popw wa
	sub xix, 0x400

Sequencer_Advance_StorePtr:
	stda32 4376, xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6883
	cp xwa, xbc
	jp_24 z, Sequencer_Advance_UpdateRemaining
	cpdi8 6887, 1
	jp_24 z, Sequencer_Advance_UpdateRemaining
	subda32 xwa, 4211

Sequencer_Advance_UpdateRemaining:
	stda32 6883, xwa
	pop xbc
	pop xwa
	stdi8 4323, 0
	ret

SMF_SetTempoFromMetaEvent:
	stdi8 3950, 0
	stda8 3951, a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SetTempo_ReadByte1Failed
	pop xbc
	pop xwa
	jp SMF_SetTempo_StoreByte1

SMF_SetTempo_ReadByte1Failed:
	pop xbc
	pop xwa
	jp SoundGen_NullRet

SMF_SetTempo_StoreByte1:
	stda8 3948, a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SetTempo_ReadByte2Failed
	pop xbc
	pop xwa
	jp SMF_SetTempo_ComputeBPM

SMF_SetTempo_ReadByte2Failed:
	pop xbc
	pop xwa
	jp SoundGen_NullRet

SMF_SetTempo_ComputeBPM:
	stda8 3949, a
	ldda8 h, 3951
	ldda8 l, 3948
	ldw wa, 0x9387
	lds de, 3
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2
	cp wa, 0x28
	jrl ugt, SMF_SetTempo_ClampMax
	ldw wa, 0x28
	jrl SoundGen_EncodeTempoByte

SMF_SetTempo_ClampMax:
	cp wa, 0x12c
	jrl c, SoundGen_EncodeTempoByte
	ldw wa, 0x12c

SoundGen_EncodeTempoByte:
	ld hl, wa
	ld w, a
	and a, 0x7f
	and w, 0x80
	rlc w
	and h, 0x1
	sla h, 1
	or w, h
	lds32 xiy, 7
	cpdi16 3932, 0
	jrl z, SoundGen_ApplyTempoToVoice
	cpdi16 3934, 1
	jrl z, SoundGen_ApplyTempoToVoice
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_ApplyTempoToVoice:
	pushw wa
	call SoundGen_CaptureVoiceParams
	popw wa
	ld bc, wa
	ldb a, 0x80
	cpdi16 3932, 0
	jrl z, SoundGen_UpdateTempoAndScale
	cpdi16 3934, 1
	jrl z, SoundGen_UpdateTempoAndScale
	ldb a, 0xa0
	ldb w, 0x7
	or a, w

SoundGen_UpdateTempoAndScale:
	pushw bc
	call SoundGen_UpdateAndRefresh
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_NullRet
	lds iy, 7
	cpdi16 3932, 0
	jrl z, SoundGen_ScaleAndWriteTempo
	cpdi16 3934, 1
	jrl z, SoundGen_ScaleAndWriteTempo
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_ScaleAndWriteTempo:
	sla iy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	pushw bc
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	popw bc
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_NullRet
	ld a, c
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, SoundGen_NullRet
	ld a, b
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullRet
	lds32 xiy, 7
	cpdi16 3932, 0
	jrl z, SoundGen_SetVoiceBitAndWriteRegs
	cpdi16 3934, 1
	jrl z, SoundGen_SetVoiceBitAndWriteRegs
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_SetVoiceBitAndWriteRegs:
	ld bc, iy
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	stcf_a_16 de
	st16_24 0x00ffec, xde
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0

SoundGen_NullRet:
	ret

SoundGen_CaptureVoiceParams:
	push xde
	sla xiy, 1
	ld xde, 0xc9e
	ld_sriw3 WA, 0x07, 0xe8, 0xf4
	stda16 0x28af, xwa
	srl xiy, 1
	ld xde, 0xcbe
	ld_srib3 A, 0x07, 0xe8, 0xf4
	xor w, w
	stda16 9830, xwa
	pop xde
	ret

ToneGen_LoadBlockValidate:
	push xhl
	ldda16 xhl, 0x28af
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ldda16 xiy, 9830
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	pop xhl
	ret

SoundGen_StoreVoiceParamsToTables:
	push xix
	ldda16 xwa, 9830
	ld xix, 0xf218
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	sla hl, 1
	ldda16 xwa, 0x28af
	ld xix, 0xf1f8
	st_dri3w WA, 0x07, 0xf0, 0xec
	pop xix
	ret

MidiEvent_DispatchSetA:
	ld xix, 0xfab
	ldda8 a, 4011
	pushw hl
	ldda16 xhl, 4012
	cp l, 0x7f
	jrl ule, MidiEvent_ClampVelocityA_Low
	ldb l, 0x7f

MidiEvent_ClampVelocityA_Low:
	cp h, 0x7f
	jrl ule, MidiEvent_ClampVelocityA_High
	ldb h, 0x7f

MidiEvent_ClampVelocityA_High:
	stda16 4012, xhl
	popw hl
	ld w, a
	and w, 0xf0
	cp w, 0x90
	jrl z, MidiEvent_NoteOnA
	cp w, 0xb0
	jrl z, MidiEvent_ControlChangeA
	cp w, 0x80
	jrl z, MidiEvent_NoteOffA
	cp w, 0xe0
	jrl z, MidiEvent_PitchBendA
	cp w, 0xc0
	jrl z, MidiEvent_ProgramChangeA
	cp w, 0xd0
	jrl z, MidiEvent_ChannelPressureA
	jrl MidiNoteOff_NullRetA

MidiEvent_ChannelPressureA:
	call MidiEvent_HandleChannelPressureA
	jrl MidiNoteOff_NullRetA

MidiEvent_NoteOnA:
	ld w, (xix + 2)
	cps w, 0
	jrl z, MidiEvent_NoteOffA
	call MidiNoteOn_FindFreeVoiceSlotA
	jrl MidiNoteOff_NullRetA

MidiEvent_NoteOffA:
	call MidiNoteOff_FindActiveVoiceA
	jrl MidiNoteOff_NullRetA

MidiEvent_ControlChangeA:
	call VoiceSynth_CommandDispatch
	jrl MidiNoteOff_NullRetA

MidiEvent_PitchBendA:
	call MidiEvent_HandlePitchBendA
	jrl MidiNoteOff_NullRetA

MidiEvent_ProgramChangeA:
	call MidiEvent_HandleProgramChangeA

MidiNoteOff_NullRetA:
	ret

MidiEvent_DispatchSetB:
	ld xix, 0xfab
	ldda8 a, 4011
	pushw hl
	ldda16 xhl, 4012
	cp l, 0x7f
	jrl ule, MidiEvent_ClampVelocityB_Low
	ldb l, 0x7f

MidiEvent_ClampVelocityB_Low:
	cp h, 0x7f
	jrl ule, MidiEvent_ClampVelocityB_High
	ldb h, 0x7f

MidiEvent_ClampVelocityB_High:
	stda16 4012, xhl
	popw hl
	ld w, a
	and w, 0xf0
	cp w, 0x90
	jrl z, MidiEvent_NoteOnB
	cp w, 0xb0
	jrl z, MidiEvent_ControlChangeB
	cp w, 0x80
	jrl z, MidiEvent_NoteOffB
	cp w, 0xe0
	jrl z, MidiEvent_PitchBendB
	cp w, 0xc0
	jrl z, MidiEvent_ProgramChangeB
	cp w, 0xd0
	jrl z, MidiEvent_ChannelPressureB
	jrl MidiNoteOff_NullRetB

MidiEvent_ChannelPressureB:
	call MidiEvent_HandleChannelPressureB
	jrl MidiNoteOff_NullRetB

MidiEvent_NoteOnB:
	ld w, (xix + 2)
	cps w, 0
	jrl z, MidiEvent_NoteOffB
	call MidiNoteOn_FindFreeVoiceSlotB
	jrl MidiNoteOff_NullRetB

MidiEvent_NoteOffB:
	call MidiNoteOff_FindActiveVoiceB
	jrl MidiNoteOff_NullRetB

MidiEvent_ControlChangeB:
	call VoiceParam_CommandDispatch
	jrl MidiNoteOff_NullRetB

MidiEvent_PitchBendB:
	call MidiEvent_HandlePitchBendB
	jrl MidiNoteOff_NullRetB

MidiEvent_ProgramChangeB:
	call MidiEvent_HandleProgramChangeB

MidiNoteOff_NullRetB:
	ret

SoundGen_ClampVoiceIndexMin1:
	extz xiy
	cp xiy, 0x1
	jrl ule, SoundGen_ClampVoice_Done
	lds32 xiy, 1

SoundGen_ClampVoice_Done:
	ret

SeqTrack_ReleaseVoiceAtEndOfTrack:
	ldda16 xhl, 4237
	ld iy, hl
	call SoundGen_ClampVoiceIndexMin1
	ld hl, iy
	sla iy, 1
	add iy, hl
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jrl z, SeqTrack_ReleaseVoice_Done
	ldda16 xiy, 4237
	ld hl, iy
	push xhl
	call SoundGen_ReadVoiceRegs
	ldb a, 0x82
	call ToneGen_LoadBlockValidate
	call SoundGen_StoreVoiceToTables_Clamped
	pop xhl

SeqTrack_ReleaseVoice_Done:
	ret

SMF_ReadMidiEventWithStatus:
	stda8 4010, a
	xor bc, bc
	ld xix, 0xfab
	lda_dpi XBC, 0xf0
	inc 1, c

SMF_ReadMidiStatus_ReadLoop:
	pushw bc
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_ReadMidiStatus_ReadFailed
	pop xbc
	pop xwa
	jp SMF_ReadMidiStatus_StoreByte

SMF_ReadMidiStatus_ReadFailed:
	pop xbc
	pop xwa
	jp SMF_ReadMidiStatus_Done

SMF_ReadMidiStatus_StoreByte:
	lda_dpi XBC, 0xf0
	inc 1, c
	ldda8 a, 4010
	and a, 0xf0
	ldb w, 0x2
	cp a, 0xd0
	jrl z, SMF_ReadMidiStatus_OneByteMsg
	cp a, 0xc0
	jrl nz, SMF_ReadMidiStatus_CheckComplete

SMF_ReadMidiStatus_OneByteMsg:
	ldb w, 0x1

SMF_ReadMidiStatus_CheckComplete:
	cp c, w
	jrl ule, SMF_ReadMidiStatus_ReadLoop
	call MidiEvent_DispatchSetB

SMF_ReadMidiStatus_Done:
	ret

SetWall_ValidateAndApply:
	stdi8 0x27d2, 0
	call SetWall_ParserInit
	ldda8 a, 0x2877
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 0x28a1
	jrl ugt, SetWall_ParamOutOfRange
	cpda8 a, 9858
	jrl z, SetWall_ParamOutOfRange
	ldda8 a, 9858
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 0x28a1
	jrl ugt, SetWall_ParamOutOfRange
	ldda8 a, 9860
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 0x28a1
	jrl ule, SetWall_ParamsValid

SetWall_ParamOutOfRange:
	stdi8 0x287a, 3
	jrl Scoop_NullRet

SetWall_ParamsValid:
	xor hl, hl
	stdi8 0x287a, 0
	anddi8 0x287b, 191
	ldda8 a, 0x2877
	call SetWall_SingleSlotResolve
	cpdi8 0x287a, 0
	jrl z, SetWall_SlotResolved
	jrl Scoop_NullRet

SetWall_SlotResolved:
	ldda16 xwa, 0x28af
	stda16 0x27d4, xwa
	ldda8 a, 9858
	call SetWall_SingleSlotResolve
	cpdi8 0x287a, 0
	jrl nz, Scoop_NullRet
	ldda16 xwa, 0x28af
	stda16 0x27d8, xwa
	ldda8 a, 9860
	cpda8 a, 0x2877
	jrl z, SetWall_InitVoiceSlots
	cpda8 a, 9858
	jrl z, SetWall_InitVoiceSlots
	ldda8 a, 0x2877
	pushw wa
	ldda8 a, 9860
	stda8 0x2877, a
	call Scoop_SpecialMode_ParamCheckBound
	popw wa
	stda8 0x2877, a

SetWall_InitVoiceSlots:
	xor xhl, xhl
	ldda8 l, 0x2877
	call VoiceChannel_ClearRegisters
	ld xix, 0x17fa
	nop
	ldda16 xwa, 0x27d4
	stda16 0x28af, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	stda16 0x27d6, xiy
	xor xhl, xhl
	ldda8 l, 9858
	call VoiceChannel_ClearRegisters
	ld xix, 0x18fa
	nop
	ldda16 xwa, 0x27d8
	stda16 0x28af, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	stda16 0x27da, xiy
	call DispatchHandler_JumpToSubHandler
	xor hl, hl
	ldda8 l, 9860
	dec 1, hl
	muls l, 0x3
	push xiy
	ld xiy, 0xf250
	or_srib_im 0x07, 0xf4, 0xec, 0x80
	inc 1, xhl
	st_dri3w IX, 0x07, 0xf4, 0xec
	pop xiy
	stda16 3308, xix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	stda32 0x2881, xhl
	lds ix, 5
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	call VoiceChannel_UpdateParamSet
	call ToneGen_ValidateVoiceCh2

Scoop_ProcessCompareLoop:
	cpdi8 0x27d2, 255
	jrl nz, Scoop_Compare_NotFinished
	jrl Scoop_NullRet

Scoop_Compare_NotFinished:
	cpdi8 0x27d2, 3
	jrl z, Scoop_Compare_Mode3
	jrl Scoop_Compare_BitTest

Scoop_Compare_Mode3:
	cp c, b
	jrl c, Scoop_Compare_LessThan
	jrl z, Scoop_Compare_Equal
	jrl ugt, Scoop_Compare_GreaterThan

Scoop_Compare_LessThan:
	call VoiceChannel_FindNextLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_Equal:
	call Scoop_HandleEqualCompare
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_GreaterThan:
	call ToneGen_AdvanceVoiceLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_BitTest:
	bitda 0, 0x27d2
	jrl z, Scoop_Compare_Bit1Test
	call ToneGen_AdvanceVoiceLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_Bit1Test:
	bitda 1, 0x27d2
	jrl z, Scoop_Compare_ValueCompare
	call VoiceChannel_FindNextLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_ValueCompare:
	ldda8 a, 0x27dc
	ldda8 w, 0x27de
	cp a, w
	jrl le, Scoop_Compare_FindNextValid
	call ToneGen_AdvanceAndValidateVoice
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_FindNextValid:
	call VoiceChannel_FindNextValid
	jrl Scoop_ProcessCompareLoop

Scoop_NullRet:
	ret

ToneGen_CopyBlockToVoiceBuffer:
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	pushw bc
	push xhl
	call ToneGen_ComputeBlockPtr
	xor xiy, xiy
	ldda32 xiy, 4349
	ld xix, 0x17fa
	ldw bc, 0x100
	ldir85
	pop xhl
	popw bc
	ld iy, hl
	lds wa, 1
	pushw bc
	push xhl
	call DispatchHandler_JumpSub
	pop xhl
	popw bc
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	xor xiy, xiy
	lds iy, 5
	ret

VoiceChannel_ResetSlotByIndex:
	push xix
	dec 1, hl
	ld iy, hl
	muls_erpb 0xf4, 0x03
	ld xix, 0xf250
	and_srib_im 0x07, 0xf0, 0xf4, 0x7f
	inc 1, iy
	stiw_dri 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld xix, 0xcbe
	stib_dri 0x07, 0xf0, 0xec, 0x05
	ld xix, 0xf218
	stib_dri 0x07, 0xf0, 0xec, 0x05
	sla hl, 1
	ld xix, 0xc9e
	stiw_dri 0x07, 0xf0, 0xec, 0xff, 0xff
	ld xix, 0xf1f8
	stiw_dri 0x07, 0xf0, 0xec, 0xff, 0xff
	pop xix
	ret

ToneGen_ReadAndDispatchVoiceBlock:
	xor hl, hl
	call VoiceChannel_ClearParamTable
	ldda16 xiy, 0x27d6
	push xix
	ld xix, 0x17fa
	ld_srib3 A, 0x07, 0xf0, 0xf4
	ld xix, 0x1073
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	pop xix
	cp a, 0x82
	jrl z, ToneGen_ReadVoiceBlock_Done

ToneGen_ReadVoiceBlock_Loop:
	inc 1, hl
	pushw hl
	call VoiceChannel_AdvancePosition
	popw hl
	ldda16 xiy, 0x27d6
	push xix
	ld xix, 0x17fa
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	bit 7, a
	jrl nz, ToneGen_ReadVoiceBlock_Done
	push xix
	ld xix, 0x1073
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	pop xix
	jrl ToneGen_ReadVoiceBlock_Loop

ToneGen_ReadVoiceBlock_Done:
	ret

ToneGen_WriteAllChannels:
	xor iy, iy

ToneGen_WriteAllCh_Loop:
	pushw wa
	pushw iy
	call SoundGen_CaptureVoiceParams
	popw iy
	popw wa
	pushw iy
	pushw wa
	pushw iy
	call ToneGen_WriteParamToBlock
	popw iy
	popw wa
	cp a, 0x81
	jrl nz, ToneGen_WriteAllChannels_Next
	pushw wa
	pushw iy
	call ToneGen_AdvancePosition
	popw iy
	popw wa
	cpdi8 4323, 0
	jrl z, ToneGen_WriteAllChannels_Next
	popw iy
	jrl ToneGen_WriteAllCh_Done

ToneGen_WriteAllChannels_Next:
	popw iy
	pushw wa
	pushw iy
	call ToneGen_WriteChannelRegs
	popw iy
	popw wa
	inc 1, iy
	cp iy, 0xf
	jrl ule, ToneGen_WriteAllCh_Loop

ToneGen_WriteAllCh_Done:
	ret

ToneGen_UpdateBlocks:
	ldda16 xhl, 0x28af
	pushw bc
	call ToneGen_ComputeBlockPtr
	popw bc
	xor ix, ix

ToneGen_UpdateBlocks_Loop:
	push xde
	ld xde, 0x1073
	ld_srib3 A, 0x07, 0xe8, 0xf0
	pop xde
	pushw bc
	push xix
	call ToneGen_WriteParamToBlock
	call ToneGen_AdvancePosition
	pop xix
	popw bc
	cpdi8 4323, 0
	jrl nz, ToneGen_UpdateBlocks_Done
	inc 1, ix
	djnz xbc, ToneGen_UpdateBlocks_Loop

ToneGen_UpdateBlocks_Done:
	ret

ToneGen_SetChannelFlag:
	ld bc, iy
	and bc, 0xf
	ld a, c
	scf
	stcfa_dd16 0xfa, 0x19
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	stcf_a_16 de
	st16_24 0x00ffec, xde
	ret

ToneGen_WriteChannelRegs:
	push xix
	ldda16 xwa, 0x28af
	sla iy, 1
	ld xix, 0xc9e
	st_dri3w WA, 0x07, 0xf0, 0xf4
	ldda16 xwa, 9830
	srl iy, 1
	ld xix, 0xcbe
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix
	ret

ToneGen_SyncVoiceBitmapFromSlots:
	push xix
	xor hl, hl
	xor bc, bc

ToneGen_SyncBitmap_Loop:
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jrl c, ToneGen_UpdateBlocks_NextChannel
	ld xix, 0xf250
	bit_dri 7, 0x07, 0xf0, 0xec
	jrl z, ToneGen_UpdateBlocks_NextChannel
	ld xix, 0xf250
	st_dri3b D, 0x07, 0xf0, 0xec
	ld wa, (xix + 1)
	ld iy, bc
	ld xix, 0xc9e
	sla iy, 1
	st_dri3w WA, 0x07, 0xf0, 0xf4
	srl iy, 1
	ld xix, 0xcbe
	stib_dri 0x07, 0xf0, 0xf4, 0x05

ToneGen_UpdateBlocks_NextChannel:
	inc 1, c
	add hl, 0x3
	cp c, 0xf
	jrl ule, ToneGen_SyncBitmap_Loop
	pop xix
	ret

; ============================================================================
; SoundGen_UpdateAndRefresh - Update sound generator parameters
; ============================================================================
; Two-step process: (1) loads data pointer/position from 10415/9830 and
; extracts parameters, (2) calls refresh routine. Called 91+ times from
; sound processing code in the accompaniment/style playback engine.
; ============================================================================
SoundGen_UpdateAndRefresh:
	call ToneGen_LoadBlockValidate
	call ToneGen_AdvPosForRefresh
	ret

FloppyIO_ClearTrackParseBuffer:
	xor wa, wa
	ld xix, 0x106e
	lds bc, 2

FloppyIO_ClearParseBuf_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, FloppyIO_ClearParseBuf_Loop
	ret

FloppyIO_ReadVariableLength:
	ld xix, 0x106e

FloppyIO_ReadVarLen_ReadLoop:
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, FloppyIO_ReadVarLen_ReadFailed
	pop xbc
	pop xwa
	jp FloppyIO_ReadVarLen_StoreByte

FloppyIO_ReadVarLen_ReadFailed:
	pop xbc
	pop xwa
	jp FloppyIO_ReadVarLen_Done

FloppyIO_ReadVarLen_StoreByte:
	lda_dpi XBC, 0xf0
	bit 7, a
	jrl nz, FloppyIO_ReadVarLen_ReadLoop
	sub xix, 0x106e

FloppyIO_ReadVarLen_Done:
	ret

SoundGen_ScalePitchByTempo:
	ldda16 xhl, 3936
	cp hl, 0x60
	jrl z, SoundGen_ScalePitch_NoScale
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xe2
	ldda16 xhl, 3936
	ldfr_werp DE, 0xe2
	div xwa, xhl
	ldto_werp DE, 0xe2

SoundGen_ScalePitch_NoScale:
	ret

MidiEvent_HandleChannelPressureA:
	ldda16 xiy, 4011
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xd0
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustainExitAlt
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
	jrl nz, ToneGen_SetSustainExitAlt
	ldda8 a, 4012
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustainExitAlt
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0

ToneGen_SetSustainExitAlt:
	ret

MidiNoteOn_FindFreeVoiceSlotA:
	ld xiy, 0x11f9

MidiNoteOn_ScanSlotsA_Loop:
	bitm 7, (xiy)
	jrl nz, MidiNoteOn_ScanSlotsA_NextSlot
	ld xix, xiy
	jrl MidiNoteOn_FoundFreeSlotA

MidiNoteOn_ScanSlotsA_NextSlot:
	add xiy, 0x7
	cp xiy, 0x12d9
	jrl ule, MidiNoteOn_ScanSlotsA_Loop
	stdi8 4323, 0
	jrl VoiceSynth_NullRet2

MidiNoteOn_FoundFreeSlotA:
	call SndParam_LookupChannelVoice
	cp a, 0xff
	jr nz, MidiNoteOn_SetupVoiceA
	stdi8 4323, 0
	jp VoiceSynth_NullRet2

MidiNoteOn_SetupVoiceA:
	ordi8 4236, 1
	ldda16 xiy, 4011
	and iy, 0xf
	extz xiy
	push xiy
	push xix
	call SoundGen_CaptureVoiceParams
	pop xix
	ldb a, 0x90
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
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
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
	cpdi8 4600, 2
	jr nz, MidiNoteOn_StandardNoteA
	ldda8 a, 4011
	and a, 0xf
	cp a, 0x9
	jrl nz, MidiNoteOn_NonDrumLookupA
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
	jp Scoop_ApplySoundParams

MidiNoteOn_NonDrumLookupA:
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
	ld_sriw3 WA, 0x07, 0xf0, 0xec
	ld c, w
	call SndParam_LookupByPartAndNote
	ldda8 a, 4012
	add a, l
	pop xde
	pop xbc
	pop xix
	jp Scoop_ApplySoundParams

MidiNoteOn_StandardNoteA:
	ldda8 a, 4012

Scoop_ApplySoundParams:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
	ldda8 a, 4013
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
	ldda8 a, 9830
	ld (xix + 2), a
	ldda16 xwa, 0x28af
	ld (xix + 3), wa
	xor a, a
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
	xor a, a
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet2
	call ToneGen_SetSustainBit
	push xix
	call ToneGen_WriteChannelRegs
	pop xix
	ldda8 a, 4011
	and a, 0xf
	or a, 0x80
	ld (xix), a
	ldda8 a, 4012
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	stdi8 4323, 0

VoiceSynth_NullRet2:
	ret

MidiNoteOff_FindActiveVoiceA:
	ld xiy, 0x11f9

MidiNoteOff_ScanActiveA_Loop:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceChkAlt
	ld a, (xiy)
	and a, 0xf
	ldda8 l, 4011
	and l, 0xf
	cp a, l
	jrl nz, ToneGen_LoopAdvanceChkAlt
	ldda8 l, 4012
	cp (xiy + 1), l
	jrl nz, ToneGen_LoopAdvanceChkAlt
	andmi8 (xiy), 0x7f
	ld ix, (xiy + 2)
	ld hl, (xiy + 3)
	and xix, 0xff
	push xhl
	push xiy
	call ToneGen_ComputeBlockPtr
	pop xiy
	ld wa, (xiy + 5)
	ldb l, 0x60
	divs8rr a, l
	cps a, 0
	jrl nz, Scoop_ApplyMatchedVoiceEntry
	cps w, 4
	jrl ugt, Scoop_ApplyMatchedVoiceEntry
	ldb w, 0x5

Scoop_ApplyMatchedVoiceEntry:
	ldda32 xhl, 4349
	lda_dri3 XWA, 0x07, 0xec, 0xf0
	pop xhl
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	stda16 0x28af, xhl
	stda16 9830, xix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	push xix
	push xiy
	ldda32 xix, 4349
	ldda16 xiy, 9830
	and iy, 0xff
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xiy
	pop xix
	popw_dd16 0x66, 0x26
	popw_dd16 0xaf, 0x28
	jrl MidiNoteOff_ReleaseVoiceA_Done

ToneGen_LoopAdvanceChkAlt:
	add xiy, 0x7
	cp xiy, 0x12d9
	jrl ule, MidiNoteOff_ScanActiveA_Loop

MidiNoteOff_ReleaseVoiceA_Done:
	ret

; Voice synthesis command dispatcher
; Dispatches on DRAM[4012] value: <0x10 uses algorithm table, others are direct handlers
VoiceSynth_CommandDispatch:
	ldda8 a, 4012
	cp a, 0x10
	jrl c, VoiceSynth_AlgoTableDispatch
	cp a, 0x20
	jrl z, VoiceSynth_Cmd_BankSelect
	cp a, 0x26
	jrl z, VoiceSynth_Cmd_DataEntry
	cp a, 0x40
	jrl z, VoiceSynth_Cmd_Pan
	cp a, 0x42
	jrl z, VoiceSynth_Cmd_Nop42
	cp a, 0x43
	jrl z, VoiceSynth_Cmd_Nop43
	cp a, 0x5b
	jrl z, VoiceSynth_Cmd_Reverb
	cp a, 0x5d
	jrl z, VoiceSynth_Cmd_Chorus
	cp a, 0x60
	jrl z, VoiceSynth_Cmd_NextParam
	cp a, 0x61
	jrl z, VoiceSynth_Cmd_PrevParam
	cp a, 0x62
	jrl z, Scoop_Cmd_ReleaseVoiceSlot
	cp a, 0x63
	jrl z, Scoop_Cmd_ReleaseVoiceSlot
	cp a, 0x64
	jrl z, VoiceSynth_Cmd_NoteOffByCh
	cp a, 0x65
	jrl z, VoiceSynth_Cmd_NoteOnByCh
	jrl VoiceSynth_NullRet

; Dispatch via VoiceSynth_Algorithm_Table (16-entry, call (xhl))
; Index: DRAM[4012] (0x00-0x0f), 32-bit function pointers
VoiceSynth_AlgoTableDispatch:
	ld l, a
	xor h, h
	sla l, 2
	extz xhl
	push xix
	ld xix, VoiceSynth_Algorithm_Table
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	call (xhl)
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_BankSelect:
	call VoiceSynth_HandleBankSelect
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_DataEntry:
	call VoiceSynth_HandleDataEntry
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_Pan:
	call VoiceSynth_HandlePan
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_Nop42:
	call VoiceSynth_HandleNop42
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_Nop43:
	call VoiceSynth_HandleNop43
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_Reverb:
	call VoiceSynth_HandleReverb
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_Chorus:
	call VoiceSynth_HandleChorus
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_NextParam:
	call VoiceChannel_SelectNextParam
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_PrevParam:
	call VoiceChannel_SelectPrevParam
	jrl VoiceSynth_NullRet

Scoop_Cmd_ReleaseVoiceSlot:
	call VoiceChannel_ClearChannelFlags
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_NoteOnByCh:
	call VoiceChannel_NoteOnByChannel
	jrl VoiceSynth_NullRet

VoiceSynth_Cmd_NoteOffByCh:
	call VoiceChannel_NoteOffByChannel

VoiceSynth_NullRet:
	ret

VoiceSynth_Algorithm_Table:
	.long VoiceSynth_Algo_SimpleStore
	.long VoiceSynth_Algo_MultiPath
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_ChannelConfig
	.long VoiceSynth_Algo_ConditionalUpdate
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_MultiStage
	.long VoiceSynth_Algo_PitchModulated
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null

MidiEvent_HandlePitchBendA:
	ldda16 xiy, 4011
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xd2
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet3
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
	jrl nz, VoiceSynth_NullRet3
	ldda8 a, 4012
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet3
	ldda8 a, 4013
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet3
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0

VoiceSynth_NullRet3:
	ret

MidiEvent_HandleProgramChangeA:
	ldda16 xiy, 4011
	and iy, 0xf
	extz xiy
	bitda 0, 4236
	jrl nz, MidiPgmChg_CheckModeA
	call VoiceChannel_ApplyParamByMode
	stdi8 4323, 0

MidiPgmChg_CheckModeA:
	cpdi8 4600, 0
	jr z, MidiPgmChg_Mode0_SetupA
	cpdi8 4600, 2
	jrl z, MidiPgmChg_Mode2_SetupA
	jrl MidiPgmChg_Mode1_SetupA

MidiPgmChg_Mode0_SetupA:
	push xix
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xf2436b
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6748, l
	pop xix
	ld xwa, 0x1a57
	call SndParam_ApplyVoiceValue
	push xiy
	push xhl
	call SoundGen_CaptureVoiceParams
	pop xhl
	ldb a, 0xc0
	ldda8 w, 6746
	and w, 0x80
	rlc w
	or a, w
	ldda8 w, 6747
	and w, 0x80
	rlc_i_8 w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	push xhl
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	pop xhl
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, 0xf2436b
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6746
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6747
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0
	jrl SoundGen_NullReturn

MidiPgmChg_Mode2_SetupA:
	push xix
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xf2436b
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6748, l
	pop xix
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1a57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, MidiPgmChg_Mode2_ApplyEnvelopeA
	ld xhl, 0x1a37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

MidiPgmChg_Mode2_ApplyEnvelopeA:
	push xiy
	push xhl
	call SoundGen_CaptureVoiceParams
	pop xhl
	ldb a, 0xc0
	ldda8 w, 6746
	and w, 0x80
	rlc w
	or a, w
	ldda8 w, 6747
	and w, 0x80
	rlc_i_8 w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	push xhl
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	pop xhl
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, 0xf2436b
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6746
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6747
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0
	jrl SoundGen_NullReturn

MidiPgmChg_Mode1_SetupA:
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xc0
	pop xiy
	push xix
	ld xix, 0xf72
	ld_srib3 W, 0x07, 0xf0, 0xf4
	pop xix
	push xiy
	and w, 0x1
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
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
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldb a, 0x0
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 4012
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, 0xf82
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	and a, 0x70
	srl a, 4
	call SoundGen_UpdateAndRefresh
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0
	jrl SoundGen_NullReturn

SoundGen_NullReturn:
	ret

MidiEvent_HandleChannelPressureB:
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1
	and xiy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ldda8 w, 4011
	and w, 0xf
	ldb a, 0xa0
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustain_Exit
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
	jrl nz, ToneGen_SetSustain_Exit
	ldda8 a, 4012
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustain_Exit
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0

ToneGen_SetSustain_Exit:
	ret

MidiNoteOn_FindFreeVoiceSlotB:
	ld xiy, 0x11f9

MidiNoteOn_ScanSlotsB_Loop:
	bitm 7, (xiy)
	jrl nz, MidiNoteOn_ScanSlotsB_NextSlot
	ld xix, xiy
	jrl MidiNoteOn_FoundFreeSlotB

MidiNoteOn_ScanSlotsB_NextSlot:
	add xiy, 0x7
	cp xiy, 0x12d9
	jrl ule, MidiNoteOn_ScanSlotsB_Loop
	jrl VoiceParam_NullRet2

MidiNoteOn_FoundFreeSlotB:
	call SndParam_LookupChannelVoice
	cp a, 0xff
	jr nz, MidiNoteOn_SetupVoiceB
	stdi8 4323, 0
	jp VoiceParam_NullRet2

MidiNoteOn_SetupVoiceB:
	ordi8 4236, 1
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	push xiy
	push xix
	call SoundGen_ReadVoiceRegs
	pop xix
	ldda8 w, 4011
	and w, 0xf
	ldb a, 0x90
	or a, w
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	push xiy
	push xix
	call SoundGen_ScalePitchByTempo
	pop xix
	pop xiy
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	cpdi8 4600, 2
	jr nz, MidiNoteOn_StandardNoteB
	ldda8 a, 4011
	and a, 0xf
	cp a, 0x9
	jrl nz, MidiNoteOn_NonDrumLookupB
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
	jp Scoop_ApplySoundParamsAlt

MidiNoteOn_NonDrumLookupB:
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
	ld_sriw3 WA, 0x07, 0xf0, 0xec
	ld c, w
	call SndParam_LookupByPartAndNote
	ldda8 a, 4012
	add a, l
	pop xde
	pop xbc
	pop xix
	jp Scoop_ApplySoundParamsAlt

MidiNoteOn_StandardNoteB:
	ldda8 a, 4012

Scoop_ApplySoundParamsAlt:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	ldda8 a, 4013
	cp a, 0x7f
	jrl ule, MidiNoteOn_ClampVelocityB
	ldb a, 0x7f

MidiNoteOn_ClampVelocityB:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	ldda8 a, 9830
	ld (xix + 2), a
	ldda16 xwa, 0x28af
	ld (xix + 3), wa
	xor a, a
	push xiy
	push xix
	pushw wa
	call SoundGen_UpdateAndRefresh
	popw wa
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	call ToneGen_SetSustainBit
	push xix
	call SoundGen_WriteVoiceParams
	pop xix
	ldda8 a, 4011
	and a, 0xf
	or a, 0x80
	ld (xix), a
	ldda8 a, 4012
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	stdi8 4323, 0

VoiceParam_NullRet2:
	ret

MidiNoteOff_FindActiveVoiceB:
	ld xiy, 0x11f9

MidiNoteOff_ScanActiveB_Loop:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceCheck
	ld a, (xiy)
	and a, 0xf
	ldda8 l, 4011
	and l, 0xf
	cp a, l
	jrl nz, ToneGen_LoopAdvanceCheck
	ldda8 l, 4012
	cp (xiy + 1), l
	jrl nz, ToneGen_LoopAdvanceCheck
	andmi8 (xiy), 0x7f
	ld ix, (xiy + 2)
	ld hl, (xiy + 3)
	and ix, 0xff
	push xhl
	push xiy
	call ToneGen_ComputeBlockPtr
	pop xiy
	ld wa, (xiy + 5)
	ldb l, 0x60
	divs8rr a, l
	cps a, 0
	jrl nz, Scoop_ApplyMatchedVoiceEntryAlt
	cps w, 4
	jrl ugt, Scoop_ApplyMatchedVoiceEntryAlt
	ldb w, 0x5

Scoop_ApplyMatchedVoiceEntryAlt:
	ldda32 xhl, 4349
	lda_dri3 XWA, 0x07, 0xec, 0xf0
	pop xhl
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	stda16 0x28af, xhl
	stda16 9830, xix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	ldda16 xix, 9830
	ldda32 xhl, 4349
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	popw_dd16 0x66, 0x26
	popw_dd16 0xaf, 0x28
	jrl MidiNoteOff_ReleaseVoiceB_Done

ToneGen_LoopAdvanceCheck:
	add iy, 0x7
	cp xiy, 0x12d9
	jrl ule, MidiNoteOff_ScanActiveB_Loop

MidiNoteOff_ReleaseVoiceB_Done:
	ret

; Voice parameter command dispatcher
; Dispatches on DRAM[4012] value: <0x10 uses read-update table, others are direct handlers
VoiceParam_CommandDispatch:
	ldda8 a, 4012
	cp a, 0x10
	jrl c, VoiceParam_ReadUpdateDispatch
	cp a, 0x20
	jrl z, VoiceParam_Cmd_BankSelect
	cp a, 0x26
	jrl z, VoiceParam_Cmd_DataEntry
	cp a, 0x40
	jrl z, VoiceParam_Cmd_Pan
	cp a, 0x42
	jrl z, VoiceParam_Cmd_Nop42
	cp a, 0x43
	jrl z, VoiceParam_Cmd_Nop43
	cp a, 0x5b
	jrl z, VoiceParam_Cmd_Reverb
	cp a, 0x5d
	jrl z, VoiceParam_Cmd_Chorus
	cp a, 0x60
	jrl z, VoiceParam_Cmd_NextParam
	cp a, 0x61
	jrl z, VoiceParam_Cmd_PrevParam
	cp a, 0x62
	jrl z, Scoop_CmdAlt_ReleaseVoiceSlot
	cp a, 0x63
	jrl z, Scoop_CmdAlt_ReleaseVoiceSlot
	cp a, 0x64
	jrl z, VoiceParam_Cmd_NoteOffByCh
	cp a, 0x65
	jrl z, VoiceParam_Cmd_NoteOnByCh
	jrl VoiceParam_NullRet

; Dispatch via VoiceParam_ReadUpdate_Table (16-entry, call (xhl))
; Index: DRAM[4012] (0x00-0x0f), 32-bit function pointers
VoiceParam_ReadUpdateDispatch:
	ld l, a
	xor h, h
	sla l, 2
	extz xhl
	push xix
	ld xix, VoiceParam_ReadUpdate_Table
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	call (xhl)
	jrl VoiceParam_NullRet

VoiceParam_Cmd_BankSelect:
	call VoiceParam_HandleBankSelect
	jrl VoiceParam_NullRet

VoiceParam_Cmd_DataEntry:
	call VoiceParam_HandleDataEntry
	jrl VoiceParam_NullRet

VoiceParam_Cmd_Pan:
	call VoiceParam_HandlePan
	jrl VoiceParam_NullRet

VoiceParam_Cmd_Nop42:
	call VoiceSynth_HandleNop42
	jrl VoiceParam_NullRet

VoiceParam_Cmd_Nop43:
	call VoiceSynth_HandleNop43
	jrl VoiceParam_NullRet

VoiceParam_Cmd_Reverb:
	call VoiceParam_HandleReverb
	jrl VoiceParam_NullRet

VoiceParam_Cmd_Chorus:
	call VoiceParam_HandleChorus
	jrl VoiceParam_NullRet

VoiceParam_Cmd_NextParam:
	call VoiceChannel_SelectNextParam
	jrl VoiceParam_NullRet

VoiceParam_Cmd_PrevParam:
	call VoiceChannel_SelectPrevParam
	jrl VoiceParam_NullRet

Scoop_CmdAlt_ReleaseVoiceSlot:
	call VoiceChannel_ClearChannelFlags
	jrl VoiceParam_NullRet

VoiceParam_Cmd_NoteOnByCh:
	call VoiceChannel_NoteOnByChannel
	jrl VoiceParam_NullRet

VoiceParam_Cmd_NoteOffByCh:
	call VoiceChannel_NoteOffByChannel

VoiceParam_NullRet:
	ret


VoiceParam_ReadUpdate_Table:
	.long VoiceSynth_Algo_DirectStore
	.long VoiceSynth_Algo_PitchShift
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceParam_ReadUpdate_6
	.long VoiceParam_ReadUpdate_7
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceParam_ReadUpdate_10
	.long VoiceParam_ReadUpdate_11
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null
	.long VoiceSynth_Algo_Null

MidiEvent_HandlePitchBendB:
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ldda8 w, 4011
	and w, 0xf
	ldb a, 0xe0
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet3
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
	jrl nz, VoiceParam_NullRet3
	push xiy
	ldda8 a, 4012
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet3
	push xiy
	ldda8 a, 4013
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet3
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0

VoiceParam_NullRet3:
	ret

MidiEvent_HandleProgramChangeB:
	ldda16 xiy, 4011
	and iy, 0xf
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	bitda 0, 4236
	jrl nz, MidiPgmChg_CheckModeB
	call VoiceChannel_ApplyParamByMode
	stdi8 4323, 0

MidiPgmChg_CheckModeB:
	cpdi8 4600, 0
	jr z, MidiPgmChg_Mode0_SetupB
	cpdi8 4600, 2
	jrl z, MidiPgmChg_Mode2_SetupB
	jrl MidiPgmChg_Mode1_SetupB

MidiPgmChg_Mode0_SetupB:
	push xix
	push xiy
	ldda16 xiy, 4011
	and iy, 0xf
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, VoiceParam_ChannelMapRemapped
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xiy
	pop xix
	stda8 6748, l
	ld xwa, 0x1a57
	call SndParam_ApplyVoiceValue
	push xiy
	push xhl
	call SoundGen_ReadVoiceRegs
	pop xhl
	ldb a, 0xc0
	ldda8 w, 6746
	and w, 0x80
	rlc w
	or a, w
	ldda8 w, 6747
	and w, 0x80
	rlc_i_8 w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	sla iy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	push xhl
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	pop xhl
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 4011
	and a, 0xf
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6746
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6747
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0
	jrl VoiceParam_NullReturn

MidiPgmChg_Mode2_SetupB:
	push xix
	push xiy
	ldda16 xiy, 4011
	and iy, 0xf
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xf4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, VoiceParam_ChannelMapRemapped
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xiy
	pop xix
	stda8 6748, l
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1a57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, MidiPgmChg_Mode2_ApplyEnvelopeB
	ld xhl, 0x1a37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

MidiPgmChg_Mode2_ApplyEnvelopeB:
	push xiy
	push xhl
	call SoundGen_ReadVoiceRegs
	pop xhl
	ldb a, 0xc0
	ldda8 w, 6746
	and w, 0x80
	rlc w
	or a, w
	ldda8 w, 6747
	and w, 0x80
	rlc_i_8 w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	sla iy, 1
	push xix
	ld xix, 0xfae
	ld_sriw3 WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	push xhl
	push xiy
	call SoundGen_ScalePitchByTempo
	pop xiy
	pop xhl
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 4011
	and a, 0xf
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6746
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6747
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0
	jrl VoiceParam_NullReturn

MidiPgmChg_Mode1_SetupB:
	push xiy
	call SoundGen_ReadVoiceRegs
	ldb a, 0xc0
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0xf72
	ld_srib3 W, 0x07, 0xf0, 0xf4
	pop xix
	and w, 0x1
	or a, w
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
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
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 4011
	and a, 0xf
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldb a, 0x0
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 4012
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	push xix
	push xiy
	ldda16 xiy, 4011
	and iy, 0xf
	ld xix, 0xf82
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xiy
	pop xix
	and a, 0x70
	srl a, 4
	call SoundGen_UpdateAndRefresh
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0
	jrl VoiceParam_NullReturn

VoiceParam_NullReturn:
	ret

VoiceParam_ChannelMapRemapped:
	nop
	.byte 0x01
	push_sr
	pop_sr
	.byte 0x04
	halt
	ei	7
	ldio	15, 10
	pushw	3340
	ret
	.byte 0x09

SoundGen_ReadVoiceRegs:
	push xde
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	sla iy, 1
	ld xde, 0xc9e
	ld_sriw3 WA, 0x07, 0xe8, 0xf4
	stda16 0x28af, xwa
	srl iy, 1
	ld xde, 0xcbe
	ld_srib3 A, 0x07, 0xe8, 0xf4
	xor w, w
	stda16 9830, xwa
	pop xde
	ret

SoundGen_StoreVoiceToTables_Clamped:
	push xix
	cps hl, 1
	jr ule, SoundGen_StoreVoice_AfterClamp
	lds hl, 1

SoundGen_StoreVoice_AfterClamp:
	ldda16 xwa, 9830
	ld xix, 0xf218
	lda_dri3 XBC, 0x07, 0xf0, 0xec
	sla hl, 1
	ldda16 xwa, 0x28af
	ld xix, 0xf1f8
	st_dri3w WA, 0x07, 0xf0, 0xec
	pop xix
	ret

VoiceChannel_ClearRegisters:
	dec 1, hl
	ld iy, hl
	muls_erpb 0xf4, 0x03
	push xix
	ld xix, 0xf250
	and_srib_im 0x07, 0xf0, 0xf4, 0x7f
	inc 1, iy
	stiw_dri 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld xix, 0xcbe
	stib_dri 0x07, 0xf0, 0xec, 0x05
	ld xix, 0xf218
	stib_dri 0x07, 0xf0, 0xec, 0x05
	sla hl, 1
	ld xix, 0xc9e
	stiw_dri 0x07, 0xf0, 0xec, 0xff, 0xff
	ld xix, 0xf1f8
	stiw_dri 0x07, 0xf0, 0xec, 0xff, 0xff
	pop xix
	ret

VoiceChannel_CopyParamBlock:
	pushw bc
	push xhl
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	ldda32 xiy, 4349
	ldw bc, 0x100
	ldir85
	ldda16 xiy, 0x28af
	lds wa, 1
	call DispatchHandler_JumpSub
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	pop xhl
	popw bc
	lds iy, 5
	ret

VoiceChannel_UpdateParamSet:
	anddi8 0x27d2, 254
	ldda16 xiy, 0x27d6
	push xix
	ld xix, 0x17fa
	ld_srib3 C, 0x07, 0xf0, 0xf4
	pop xix
	cp c, 0x82
	jr z, VoiceChannel_ParamSet_IsEnd
	cp c, 0x81
	jr nz, VoiceChannel_ParamSet_Validate

VoiceChannel_ParamSet_IsEnd:
	ordi8 0x27d2, 1
	jr VoiceChannel_ParamSet_Done

VoiceChannel_ParamSet_Validate:
	pushw bc
	push xix
	ld xix, 0x17fa
	nop
	call ToneGen_ValidateAndSelectVoice
	pop xix
	popw bc
	push xix
	ld xix, 0x17fa
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	stda8 0x27dc, a
	stda16 0x27d6, xiy

VoiceChannel_ParamSet_Done:
	ret

ToneGen_ValidateVoiceCh2:
	anddi8 0x27d2, 253
	ldda16 xiy, 0x27da
	push xix
	ld xix, 0x18fa
	ld_srib3 B, 0x07, 0xf0, 0xf4
	pop xix
	cp b, 0x82
	jr z, ToneGen_ValidateCh2_IsEnd
	cp b, 0x81
	jr nz, ToneGen_ValidateCh2_Validate

ToneGen_ValidateCh2_IsEnd:
	ordi8 0x27d2, 2
	jr ToneGen_ValidateCh2_Done

ToneGen_ValidateCh2_Validate:
	pushw bc
	push xix
	ld xix, 0x18fa
	nop
	call ToneGen_ValidateAndSelectVoice
	pop xix
	popw bc
	push xix
	ld xix, 0x18fa
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	stda8 0x27de, a
	stda16 0x27da, xiy

ToneGen_ValidateCh2_Done:
	ret

VoiceChannel_FindNextLoop:
	call VoiceChannel_FindNextValid
	bitda 0, 0x27d2
	jr z, VoiceChannel_FindNextLoop
	ret

Scoop_HandleEqualCompare:
	cp c, 0x82
	jr nz, Scoop_Equal_AdvanceAndRevalidate
	ldda32 xhl, 4349
	stib_dri 0x07, 0xec, 0xf0, 0x82
	stdi8 0x27d2, 255
	ldda16 xwa, 3308
	stda16 0x289f, xwa
	xor wa, wa
	ldda8 a, 9860
	stda16 0x287d, xwa
	call Scoop_AssignVoiceAfterMatch
	jr Scoop_Equal_Done

Scoop_Equal_AdvanceAndRevalidate:
	ldda32 xhl, 4349
	stib_dri 0x07, 0xec, 0xf0, 0x81
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xix
	ld xix, 0x17fa
	nop
	ldda16 xiy, 0x27d6
	call ToneGen_ValidateAndSelectVoice
	stda16 0x27d6, xiy
	call VoiceChannel_UpdateParamSet
	stda16 0x27d6, xiy
	ld xix, 0x18fa
	nop
	ldda16 xiy, 0x27da
	call ToneGen_ValidateAndSelectVoice
	stda16 0x27da, xiy
	call ToneGen_ValidateVoiceCh2
	stda16 0x27da, xiy
	pop xix

Scoop_Equal_Done:
	ret

ToneGen_AdvanceVoiceLoop:
	call ToneGen_AdvanceAndValidateVoice
	bitda 1, 0x27d2
	jr z, ToneGen_AdvanceVoiceLoop
	ret

VoiceChannel_FindNextValid:
	ldda32 xhl, 4349
	lda_dri3 XHL, 0x07, 0xec, 0xf0
	bitda 0, 0x27d2
	jr nz, VoiceChannel_ValidateAndLoop
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	ldda8 a, 0x27dc
	lda_dri3 XBC, 0x07, 0xec, 0xf0

VoiceChannel_ValidateAndLoop:
	push xix
	ld xix, 0x17fa
	nop
	ldda16 xiy, 0x27d6
	call ToneGen_ValidateAndSelectVoice
	stda16 0x27d6, xiy
	pop xix
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xde
	ld xde, 0x17fa
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jr nz, VoiceChannel_FindNext_StoreAndUpdate
	push xde
	ld xde, 0x17fa
	ld_srib3 A, 0x07, 0xe8, 0xf4
	pop xde
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	jr VoiceChannel_ValidateAndLoop

VoiceChannel_FindNext_StoreAndUpdate:
	stda16 0x27d6, xiy
	call VoiceChannel_UpdateParamSet
	ret

VoiceChannel_ClearParamTable:
	ld xix, 0x1073
	xor wa, wa
	lds bc, 4

VoiceChannel_ClearParam_Loop:
	st_dpiw WA, 0xf1
	djnz xbc, VoiceChannel_ClearParam_Loop
	ret

VoiceChannel_AdvancePosition:
	ldda16 xiy, 0x27d6
	ld xix, 0x17fa
	inc 1, iy
	cp iy, 0xff
	jr ule, VoiceChannel_StorePosition_Continue
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr nz, VoiceChannel_AdvPos_CheckBounds
	stdi8 0x287a, 2
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_CheckBounds:
	cpda16 xwa, 0x286d
	jr ule, VoiceChannel_AdvPos_LoadBlock
	stdi8 0x287a, 10
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_LoadBlock:
	stda16 0x28af, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, VoiceChannel_AdvPos_CopyBlock
	stdi8 0x287a, 11
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_CopyBlock:
	ldda16 xhl, 0x28af
	call ToneGen_CopyBlockToVoiceBuffer
	lds iy, 5

VoiceChannel_StorePosition_Continue:
	stda16 0x27d6, xiy
	ret

ToneGen_WriteParamToBlock:
	ldda16 xhl, 0x28af
	call ToneGen_ComputeBlockPtr
	ldda16 xiy, 9830
	and iy, 0xff
	extz xiy
	addda32 xiy, 4349
	ld (xiy), a
	ret

ToneGen_AdvancePosition:
	ldda16 xwa, 9830
	cp wa, 0xff
	jr nz, ToneGen_AdvPos_Increment
	cpdi16 0xf231, 0
	jr nz, ToneGen_AdvPos_DispatchLink
	stdi8 4323, 255
	jr ToneGen_AdvPos_Return

ToneGen_AdvPos_DispatchLink:
	call ToneGen_DispatchAndLinkBlock
	jr ToneGen_AdvPos_ClearError

ToneGen_AdvPos_Increment:
	inc 1, wa
	stda16 9830, xwa

ToneGen_AdvPos_ClearError:
	stdi8 4323, 0

ToneGen_AdvPos_Return:
	ret

ToneGen_AdvPosForRefresh:
	ldda16 xwa, 9830
	cp wa, 0xff
	jr nz, ToneGen_AdvRefresh_Increment
	cpdi16 0xf231, 0
	jr nz, ToneGen_AdvRefresh_DispatchLink
	stdi8 4323, 255
	jr ToneGen_AdvRefresh_Return

ToneGen_AdvRefresh_DispatchLink:
	call ToneGen_DispatchAndLinkBlock
	jr ToneGen_AdvRefresh_ClearError

ToneGen_AdvRefresh_Increment:
	inc 1, wa
	stda16 9830, xwa

ToneGen_AdvRefresh_ClearError:
	stdi8 4323, 0

ToneGen_AdvRefresh_Return:
	ret

ToneGen_SetSustainBit:
	pushw bc
	ldda16 xiy, 4011
	and iy, 0xf
	ld bc, iy
	xor b, b
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	stcf_a_16 de
	st16_24 0x00ffec, xde
	popw bc
	ret

ToneGen_AdvanceBlockPosition:
	ldda16 xwa, 9830
	cp wa, 0xff
	jr nz, ToneGen_AdvBlock_IncrementPos
	ldda16 xhl, 0x28af
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 0x28af, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	lds wa, 5
	jr ToneGen_AdvBlock_StorePos

ToneGen_AdvBlock_IncrementPos:
	inc 1, wa

ToneGen_AdvBlock_StorePos:
	stda16 9830, xwa
	ret

VoiceSynth_HandleBankSelect:
	ldda16 xiy, 4011
	and iy, 0xf
	extz xiy
	ldda8 a, 4013
	push xix
	ld xix, 0xf82
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix
	ret

VoiceSynth_HandleDataEntry:
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xix
	cp l, 0xff
	jr z, VoiceSynth_DataEntry_Done
	ld c, l
	xor h, h
	extz xhl
	sla hl, 2
	push xix
	ld xix, VoiceSynth_DataEntry_PtrTable
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	ldda8 a, 4013
	xor b, b
	ld ix, bc
	extz xix
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ld_srib3 E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceSynth_DataEntry_CheckSpec
	ld a, e

VoiceSynth_DataEntry_CheckSpec:
	cps c, 1
	jr nz, VoiceSynth_DataEntry_Done
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceSynth_DataEntry_Done:
	ret

VoiceSynth_DataEntry_PtrTable:
	.byte 0x1b, 0x1a, 0x00, 0x00
	.byte 0xfb, 0x19, 0x00, 0x00
	.byte 0x0b, 0x1a, 0x00, 0x00

VoiceSynth_HandlePan:
	bitda 0, 4236
	jr nz, VoiceSynth_Pan_SetDirection
	call VoiceChannel_SetPanDirection
	stdi8 4323, 0

VoiceSynth_Pan_SetDirection:
	stdi8 4233, 4
	xor a, a
	cpdi8 4013, 64
	jr c, VoiceSynth_Pan_StoreAndUpdate
	or a, 0x8

VoiceSynth_Pan_StoreAndUpdate:
	stda8 4234, a
	stdi8 4235, 8
	call VoiceChannel_UpdateWithPitch
	ret

VoiceSynth_HandleNop42:
	ret

VoiceSynth_HandleNop43:
	ret

VoiceSynth_HandleReverb:
	bitda 0, 4236
	jr nz, VoiceSynth_Reverb_SetParams
	call VoiceChannel_SetParamByte7
	stdi8 4323, 0

VoiceSynth_Reverb_SetParams:
	stdi8 4233, 7
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call VoiceChannel_UpdateWithPitch
	ret

VoiceSynth_HandleChorus:
	bitda 0, 4236
	jr nz, VoiceSynth_Chorus_SetParams
	call VoiceChannel_MergeParamByte5
	stdi8 4323, 0

VoiceSynth_Chorus_SetParams:
	stdi8 4233, 5
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call VoiceChannel_UpdateWithPitch
	ret

VoiceChannel_SelectNextParam:
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0xff
	jr z, VoiceChannel_NextParam_Done
	exts wa
	ld hl, wa
	extz xhl
	sla hl, 2
	push xix
	ld xix, VoiceSynth_DataEntry_PtrTable
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	ld_srib3 A, 0x07, 0xec, 0xf4
	inc 1, a
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ld_srib3 E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceChannel_NextParam_Clamped
	ld a, e

VoiceChannel_NextParam_Clamped:
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceChannel_NextParam_Done:
	ret

VoiceChannel_ParamLimitTable:
	.byte 0x0c, 0x7f, 0xff

VoiceChannel_SelectPrevParam:
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0xff
	jr z, VoiceChannel_PrevParam_Done
	exts wa
	ld hl, wa
	sla hl, 2
	push xix
	ld xix, VoiceSynth_DataEntry_PtrTable
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	ld_srib3 A, 0x07, 0xec, 0xf4
	cps a, 0
	jr z, VoiceChannel_PrevParam_AtZero
	dec 1, a

VoiceChannel_PrevParam_AtZero:
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceChannel_PrevParam_Done:
	ret

VoiceChannel_ClearChannelFlags:
	ldda8 c, 4011
	and c, 0xf
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ldda16 xde, 4239
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3c
	stda16 4239, xde
	ldto_werp DE, 0x3e
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ldda16 xde, 4241
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3c
	stda16 4241, xde
	ldto_werp DE, 0x3e
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_dri 0x07, 0xf0, 0xf4, 0xff
	pop xix
	ret

VoiceChannel_NoteOnByChannel:
	ldda16 xiy, 4011
	and iy, 0xf
	ldda8 a, 4013
	push xix
	ld xix, 0x1093
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0x7f
	jr z, VoiceChannel_NoteOn_ClearSlot
	ldda8 c, 4011
	and c, 0xf
	ldda16 xwa, 4239
	andda16 xwa, 4241
	ldfr_werp WA, 0x3e
	ld a, c
	scf
	xorcf_a_werp 0x3e
	jr nc, VoiceChannel_NoteOn_LookupBank
	ldda16 xde, 4239
	ld a, c
	scf
	stcf_a_16 de
	stda16 4239, xde
	ldda16 xde, 4241
	ld a, c
	scf
	xorcf_a_16 de
	jr c, VoiceChannel_NoteOn_Done

VoiceChannel_NoteOn_LookupBank:
	pushw bc
	call SoundGen_LookupChannelBankParams
	popw bc
	cp a, 0xff
	jr nz, VoiceChannel_NoteOn_Done

VoiceChannel_NoteOn_ClearSlot:
	ldda8 c, 4011
	and c, 0xf
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_dri 0x07, 0xf0, 0xf4, 0xff
	xor c, c
	ld xix, 0x10c3
	lda_dri3 XHL, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	lda_dri3 XHL, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_NoteOn_Done:
	ret

VoiceChannel_NoteOffByChannel:
	ldda16 xiy, 4011
	and iy, 0xf
	ldda8 a, 4013
	push xix
	ld xix, 0x10a3
	lda_dri3 XBC, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0x7f
	jr z, VoiceChannel_NoteOff_ClearSlot
	ldda8 c, 4011
	and c, 0xf
	ldda16 xwa, 4239
	andda16 xwa, 4241
	ldfr_werp WA, 0x3e
	ld a, c
	scf
	xorcf_a_werp 0x3e
	jr nc, VoiceChannel_NoteOff_LookupBank
	ldda16 xde, 4241
	ld a, c
	scf
	stcf_a_16 de
	stda16 4241, xde
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ldda16 xde, 4239
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, VoiceChannel_NoteOff_Done

VoiceChannel_NoteOff_LookupBank:
	pushw bc
	call SoundGen_LookupChannelBankParams
	popw bc
	cp a, 0xff
	jr nz, VoiceChannel_NoteOff_Done

VoiceChannel_NoteOff_ClearSlot:
	ldda8 c, 4011
	and c, 0xf
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_dri 0x07, 0xf0, 0xf4, 0xff
	xor c, c
	ld xix, 0x10c3
	lda_dri3 XHL, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	lda_dri3 XHL, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_NoteOff_Done:
	ret

VoiceChannel_ApplyParamByMode:
	push xiy
	call VoiceChannel_GetParamBlock
	cpdi8 4600, 0
	jr z, VoiceParam_ByMode_Mode0
	cpdi8 4600, 2
	jrl z, VoiceParam_ByMode_Mode2
	jrl VoiceParam_ByMode_Mode1

VoiceParam_ByMode_Mode0:
	push xix
	push xde
	xor de, de
	ldda8 e, 4011
	and e, 0xf
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xf2436b
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6748, l
	pop xde
	pop xix
	push xiy
	ld xwa, 0x1a57
	call SndParam_ApplyVoiceValue
	pop xiy
	ldda8 l, 6746
	ldda8 h, 6747
	ld (xiy + 256), l
	ld (xiy + 1), h
	jrl VoiceParam_ByMode_StoreAndReturn

VoiceParam_ByMode_Mode2:
	push xix
	push xde
	xor de, de
	ldda8 e, 4011
	and e, 0xf
	ld xix, 0xf82
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6743, l
	ld xix, 0xf72
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xf2436b
	ld_srib3 L, 0x07, 0xf0, 0xe8
	stda8 6748, l
	pop xde
	pop xix
	push xiy
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1a57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, VoiceParam_ByMode_Mode2_Apply
	ld xhl, 0x1a37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

VoiceParam_ByMode_Mode2_Apply:
	pop xiy
	ldda8 l, 6746
	ldda8 h, 6747
	ld (xiy + 256), l
	ld (xiy + 1), h
	jr VoiceParam_ByMode_StoreAndReturn

VoiceParam_ByMode_Mode1:
	ldda8 a, 4012
	xor hl, hl
	ldda8 l, 4011
	and l, 0xf
	push xix
	ld xix, 0xf72
	ld_srib3 C, 0x07, 0xf0, 0xec
	pop xix
	and c, 0x1
	rrc c
	and a, 0x7f
	or a, c
	ld (xiy + 256), a
	xor h, h
	ldda8 l, 4011
	and l, 0xf
	push xix
	ld xix, 0xf82
	ld_srib3 C, 0x07, 0xf0, 0xec
	pop xix
	ld l, (xiy + 1)
	and l, 0x80
	and c, 0x70
	srl c, 4
	or l, c
	ld (xiy + 1), l

VoiceParam_ByMode_StoreAndReturn:
	pop xiy
	ret

SoundGen_WriteVoiceParams:
	push xde
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	ldda16 xwa, 0x28af
	sla xiy, 1
	ld xde, 0xc9e
	st_dri3w WA, 0x07, 0xe8, 0xf4
	ldda16 xwa, 9830
	srl xiy, 1
	ld xde, 0xcbe
	lda_dri3 XBC, 0x07, 0xe8, 0xf4
	pop xde
	ret

VoiceParam_HandleBankSelect:
	ldda16 xiy, 4011
	and iy, 0xf
	ldda8 a, 4013
	push xde
	ld xde, 0xf82
	lda_dri3 XBC, 0x07, 0xe8, 0xf4
	pop xde
	ret

VoiceParam_HandleDataEntry:
	ldda16 xiy, 4011
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ld_srib3 L, 0x07, 0xf0, 0xf4
	pop xix
	cp l, 0xff
	jr z, VoiceParam_DataEntry_Done
	ld c, l
	xor h, h
	sla hl, 2
	push xix
	ld xix, VoiceSynth_DataEntry_PtrTable
	ld_sril3 XHL, 0x07, 0xf0, 0xec
	pop xix
	ldda8 a, 4013
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ld_srib3 E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceParam_DataEntry_CheckSpec
	ld a, e

VoiceParam_DataEntry_CheckSpec:
	cps c, 1
	jr nz, VoiceParam_DataEntry_Done
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	lda_dri3 XBC, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceParam_DataEntry_Done:
	ret

VoiceParam_HandlePan:
	bitda 0, 4236
	jr nz, VoiceParam_Pan_SetDirection
	call VoiceChannel_SetPanDirection
	stdi8 4323, 0

VoiceParam_Pan_SetDirection:
	stdi8 4233, 4
	xor a, a
	cpdi8 4013, 64
	jr c, VoiceParam_Pan_StoreAndUpdate
	ldb a, 0x8

VoiceParam_Pan_StoreAndUpdate:
	stda8 4234, a
	stdi8 4235, 8
	call SoundGen_ClampUpdateVoice
	ret

VoiceParam_HandleReverb:
	bitda 0, 4236
	jr nz, VoiceParam_Reverb_SetParams
	call VoiceChannel_SetParamByte7
	stdi8 4323, 0

VoiceParam_Reverb_SetParams:
	stdi8 4233, 7
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call SoundGen_ClampUpdateVoice
	ret

VoiceParam_HandleChorus:
	bitda 0, 4236
	jr nz, VoiceParam_Chorus_SetParams
	call VoiceChannel_MergeParamByte5
	stdi8 4323, 0

VoiceParam_Chorus_SetParams:
	stdi8 4233, 5
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call SoundGen_ClampUpdateVoice
	ret

ToneGen_AdvanceAndValidateVoice:
	ldda32 xhl, 4349
	lda_dri3 XDE, 0x07, 0xec, 0xf0
	bitda 1, 0x27d2
	jr nz, ToneGen_ValidateVoiceLoop
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	ldda8 a, 0x27de
	lda_dri3 XBC, 0x07, 0xec, 0xf0

ToneGen_ValidateVoiceLoop:
	push xix
	ld xix, 0x18fa
	nop
	ldda16 xiy, 0x27da
	call ToneGen_ValidateAndSelectVoice
	stda16 0x27da, xiy
	pop xix
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xix
	ld xix, 0x18fa
	bit_dri 7, 0x07, 0xf0, 0xf4
	pop xix
	jr nz, ToneGen_AdvValidate_StoreAndDone
	push xix
	ld xix, 0x18fa
	ld_srib3 A, 0x07, 0xf0, 0xf4
	pop xix
	lda_dri3 XBC, 0x07, 0xec, 0xf0
	jr ToneGen_ValidateVoiceLoop

ToneGen_AdvValidate_StoreAndDone:
	stda16 0x27da, xiy
	call ToneGen_ValidateVoiceCh2
	ret

VoiceSynth_Algo_SimpleStore:
	ldda16	iy, 4011
	and	iy, 15
	.byte 0xc1, 0xad, 0x0f
	.ascii "!<Dr"
	retd	0
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4, 0x41
	pop	xix
	ret
VoiceSynth_Algo_MultiPath:
	ldda16	iy, 4011
	and	iy, 15
	push	xiy
	call	SoundGen_CaptureVoiceParams
	ldb	a, 209
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 67
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 30
	ldda8	a, 4013
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 13
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	stdi8	4323, 0
	ret
VoiceSynth_Algo_Null:
	ret
VoiceSynth_Algo_ChannelConfig:
	ldda16	iy, 4011
	and	iy, 15
	push	xix
	ld	xix, 4275
	.byte 0xc3
	reti
	.byte 0xf0, 0xf4
	ldb	l, 92
	cp	l, 255
	jr	z, 66
	ld	c, l
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, VoiceSynth_DataEntry_PtrTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	ldda8	a, 4013
	xor	b, b
	ld	ix, bc
	push	xiy
	ld	xiy, VoiceChannel_ParamLimitTable
	.byte 0xc3
	reti
	.byte 0xf4, 0xf0
	ldb	e, 93
	cp	a, e
	jr	ule, 2
	ld	a, e
	cps	c, 1
	jr	nz, 8
	push	xhl
	push	xiy
	call	VoiceChannel_GetCombinedStatus
	pop	xiy
	pop	xhl
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0xf269cb1d
	ret
VoiceSynth_Algo_ConditionalUpdate:
	; --- Main routine: bit test, store, conditional call (49 bytes) ---
	bitda	0, 4236
	jr nz, VoiceSynth_ConditionalUpdate_SetParams
	call 0xf26c9e
	stdi8	4323, 0
VoiceSynth_ConditionalUpdate_SetParams:
	stdi8	4233, 3
	ldda8	a, 4013
	cpdi8	4600, 2
	jr nz, VoiceSynth_ConditionalUpdate_StoreAndCall
	call VoiceSynth_ConditionalUpdate_Helper
VoiceSynth_ConditionalUpdate_StoreAndCall:
	stda8	4234, a
	stdi8	4235, 127
	call VoiceChannel_UpdateWithPitch
	ret
VoiceSynth_ConditionalUpdate_Helper:
	; --- Helper: call FEEA13, copy L to A (7 bytes) ---
	call SndParam_CompactLookupStub
	ld a, l
	ret


VoiceSynth_Algo_MultiStage:
	ldda16	iy, 4011
	and	iy, 15
	extz	xiy
	call	SoundGen_CaptureVoiceParams
	push	xiy
	ldb	a, 176
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 150
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 113
	ldda8	l, 4011
	and	l, 15
	xor	h, h
	extz	xhl
	push	xix
	ld	xix, SeqTrack_ChannelMapIdentity
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 193
	swi	0
	scf
	push	xsp
	.byte 0x01
	jr	z, 10
	ld	xix, 0xf2436b
	.byte 0xc3
	reti
	.byte 0xf0, 0xec
	ldb	a, 92
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 60
	ldb	a, 8
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 45
	ldda8	a, 4013
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 28
	ldb	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 13
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	stdi8	4323, 0
	ret
VoiceSynth_Algo_PitchModulated:
	ldda16	iy, 4011
	and	iy, 15
	extz	xiy
	push	xiy
	call	SoundGen_CaptureVoiceParams
	ldb	a, 211
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 78
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 41
	ldda8	a, 4013
	.byte 0xc1
	swi	0
	scf
	push	xsp
	push_sr
	jr	nz, 4
	call	VoiceSynth_ConditionalUpdate_Helper
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 13
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	stdi8	4323, 0
	ret
VoiceSynth_Algo_DirectStore:
	ldda16	iy, 4011
	and	iy, 15
	.byte 0xc1, 0xad, 0x0f
	.ascii "!<Dr"
	retd	0
	.byte 0xf3
	reti
	.byte 0xf0, 0xf4, 0x41
	pop	xix
	ret
VoiceSynth_Algo_PitchShift:
	ldda16	iy, 4237
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	push	xiy
	call	SoundGen_ReadVoiceRegs
	ldda8	w, 4011
	and	w, 15
	ldb	a, 208
	or	a, w
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 67
	sla	iy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	iy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 30
	push	xiy
	ldda8	a, 4013
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jr	nz, 13
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	stdi8	4323, 0
	ret
VoiceParam_ReadUpdate_6:
	ldda16	iy, 4011
	and	iy, 15
	push	xix
	ld	xix, 4275
	.byte 0xc3
	reti
	.byte 0xf0, 0xf4
	ldb	l, 92
	cp	l, 255
	jr	z, 66
	ld	c, l
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, VoiceSynth_DataEntry_PtrTable
	.byte 0xe3
	reti
	.byte 0xf0, 0xec
	ldb	c, 92
	ldda8	a, 4013
	xor	b, b
	ld	ix, bc
	push	xiy
	ld	xiy, VoiceChannel_ParamLimitTable
	.byte 0xc3
	reti
	.byte 0xf4, 0xf0
	ldb	e, 93
	cp	a, e
	jr	ule, 2
	ld	a, e
	cps	c, 1
	jr	nz, 8
	push	xhl
	pushw	iy
	call	VoiceChannel_GetCombinedStatus
	popw	iy
	pop	xhl
	.byte 0xf3
	reti
	cp	xix, xix
	ld	xbc, 0xf269cb1d
	ret
VoiceParam_ReadUpdate_7:
	.byte 0xf1
	and	(xix+16), w
	jr	nz, 9
	call	0xf26c9e
	stdi8	4323, 0
	stdi8	4233, 3
	ldda8	a, 4013
	.byte 0xc1
	swi	0
	scf
	push	xsp
	push_sr
	jr	nz, 4
	call	VoiceSynth_ConditionalUpdate_Helper
	stda8	4234, a
	stdi8	4235, 127
	call	SoundGen_ClampUpdateVoice
	ret
VoiceParam_ReadUpdate_10:
	ldda16	iy, 4237
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	call	SoundGen_ReadVoiceRegs
	push	xiy
	ldb	a, 176
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 122
	sla	iy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	iy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 84
	ldda8	a, 4011
	and	a, 15
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 63
	ldb	a, 8
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 47
	ldda8	a, 4013
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 29
	ldb	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 13
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	stdi8	4323, 0
	ret
VoiceParam_ReadUpdate_11:
	ldda16	iy, 4237
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	push	xiy
	call	SoundGen_ReadVoiceRegs
	ldda8	w, 4011
	and	w, 15
	ldb	a, 240
	or	a, w
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 80
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	.byte 0xd3
	reti
	.byte 0xf0, 0xf4
	ldb	w, 92
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 42
	ldda8	a, 4013
	.byte 0xc1
	swi	0
	scf
	push	xsp
	push_sr
	jr	nz, 4
	call	VoiceSynth_ConditionalUpdate_Helper
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	.byte 0xc1, 0xe3
	rcf
	push	xsp
	nop
	jrl	nz, 13
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	stdi8	4323, 0
	ret

ToneGen_ValidateAndSelectVoice:
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	and iy, 0xff
	inc 1, iy
	cp iy, 0xff
	jr ugt, ToneGen_ValidateVoice_CheckLink
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_CheckLink:
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr nz, ToneGen_ValidateVoice_CheckBounds
	stdi8 0x287a, 2
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_CheckBounds:
	cpda16 xwa, 0x286d
	jr ule, ToneGen_ValidateVoice_LoadBlock
	stdi8 0x287a, 10
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_LoadBlock:
	stda16 0x28af, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, ToneGen_ValidateVoice_CopyParams
	stdi8 0x287a, 11
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_CopyParams:
	call VoiceChannel_CopyParamBlock

ToneGen_SaveVoiceState_Continue:
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	ret

Scoop_AssignVoiceAfterMatch:
	push xiy
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	ldda16 xhl, 0x287d
	dec 1, hl
	ld wa, ix
	ld xiy, 0xf218
	lda_dri3 XBC, 0x07, 0xf4, 0xec
	sla hl, 1
	ldda16 xwa, 0x289f
	ld xiy, 0xf1f8
	st_dri3w WA, 0x07, 0xf4, 0xec
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	pop xiy
	ret

VoiceChannel_AdvanceIndex:

