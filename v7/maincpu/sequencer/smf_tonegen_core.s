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
	ld (0xf19e:16), wa
	ld (0x00ffec:24), wa
	ldw (0xf19c:16), 0
	cpw (6699:16), 49
	jrl z, SeqPlay_ReadyStateTransition
	ldw (6699:16), 31
	jrl SeqPlay_ReadyStateTransition

SeqPlay_ResetAndStop:
	call FloppyIO_ReturnReady
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	ld (0xf19e:16), wa
	ld (0x00ffec:24), wa
	ldw (0xf19c:16), 0
	push xhl
	ld xhl, (6701:16)
	ld (6699:16), hl
	pop xhl
	jrl SeqPlay_ReadyStateTransition

SeqPlay_SetState48AndFloppyReady:
	ldw (6699:16), 48

SeqPlay_FloppyReady:
	call FloppyIO_ReturnReady
	jrl SeqPlay_ReadyStateTransition

SeqPlay_FinishFloppyLoadAndStart:
	call VoiceChannels_LoadPartMapAndInitPan
	ldw (0x1a2b:16), 0x0001
	call SeqPlay_DelayLoop_Outer
	call 0xfdadae
	ld wa, (0x00ffec:24)
	ld (0xf19e:16), wa
	and (0x28a7:16), 0xf7
	call SeqPlay_CheckStartConditions
	call SeqPlay_InitChannelParams
	ldw (0xf19c:16), 0x0000
	call 0xfdd69e
SeqPlay_ReadyStateTransition:
	call SeqStep_PlaybackNop
	ret

; Standard MIDI File chunk IDs "MThd" (+0) and "MTrk" (+4), compared
; against bytes read from the file: read by smf_playback.s via
; `ld xiy, SMF_HeaderMagic_MThdMTrk` (header chunk) and
; `ld xiy, SMF_HeaderMagic_MThdMTrk_0x4` (track chunk).
SMF_HeaderMagic_MThdMTrk:	.ascii "MThdMTrk"

SeqTrack_ResetAllChannelSlots:
	ldw wa, 0xffff
	ld xix, 0x10b3
	ldw bc, 0x8

SeqTrack_ResetChannelSlots_Loop:
	ld (xix+), WA
	djnz16 bc, SeqTrack_ResetChannelSlots_Loop
	xor wa, wa
	ldw bc, 0x28

SeqTrack_ClearRemaining_Loop:
	ld (xix+), WA
	djnz16 bc, SeqTrack_ClearRemaining_Loop
	ret

SeqTrack_ScanActiveChannels:
	ld xhl, 0x11f9
	xor iy, iy
	xor a, a

SeqTrack_ScanActiveChannels_Loop:
	stb_dri A, 0x07, 0xec, 0xf4
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
	ld (xix+), WA
	djnz16 bc, SeqTrack_ClearPlaybackBuf1_Loop
	ld xix, 0xf82
	ldw bc, 0x8

SeqTrack_ClearPlaybackBuf2_Loop:
	ld (xix+), WA
	djnz16 bc, SeqTrack_ClearPlaybackBuf2_Loop
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
	ld xix, (4376:16)
	ld A, (xix+)
	cp xix, 0x17f9
	jrl ule, FloppyIO_ReadNextByte_StorePtr
	ld l, a
	pushw hl
	call FileIO_ReadBlockToFilePos
	popw hl
	ld a, l
	incw 1, (4327:16)
	pushw wa
	push xhl
	pushw de
	ld wa, (4327:16)
	xor de, de
	ld hl, 4:i3
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	cp de, 0:i3
	jrl nz, FloppyIO_ReadNextByte_DivDone

FloppyIO_ReadNextByte_DivDone:
	popw de
	pop xhl
	popw wa
	ld xix, 0x13fa

FloppyIO_ReadNextByte_StorePtr:
	ld (4376:16), xix
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6883:16)
	cp xwa, xbc
	jp z, (FloppyIO_ReadNextByte_UpdateRemaining:24)
	cp (6887:16), 1
	jp z, (FloppyIO_ReadNextByte_UpdateRemaining:24)
	dec 1, xwa

FloppyIO_ReadNextByte_UpdateRemaining:
	ld (6883:16), xwa
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
	ld (xix+), WA
	djnz16 bc, SeqTrack_ClearPartParams_Loop
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
	cp (4600:16), 0
	jr z, FloppyIO_SelectReadMode_ModeDefault
	cp (4600:16), 1
	jr z, FloppyIO_SelectReadMode_Mode0
	ld a, 0x2:opc
	jp FloppyIO_SelectReadMode_Dispatch

FloppyIO_SelectReadMode_Mode0:
	ld a, 0x0:opc
	jp FloppyIO_SelectReadMode_Dispatch

FloppyIO_SelectReadMode_ModeDefault:
	ld a, 0x1:opc

FloppyIO_SelectReadMode_Dispatch:
	call	16612777
	pop	xiz
	pop	xiy
	pop	xix
	pop	xde
	pop	xbc
	pop	xhl
	pop	xwa
	ret
ChannelRecord_PtrTable:
; 16 x 32-bit pointers to the sixteen 26-byte (0x1A) channel records at RAM 0xF496 + 26*k, k = 0..15 (the
; same 64 bytes as VoiceChannel_ParamTable1 +0x00, a second copy).
; Read by SeqPlay_InitChannelParams (0xF23E1B): for DE = 0..15,
; XIY = long [this + DE*4], then record field +11 = 2 and field +10 = 0x80.
; Stride 4, 16 entries (the loop count BC = 0x10).  Renamed 2026-09-25 from
; FloppyIO_SwitchboardChannelPtrs: nothing here is floppy- or switchboard-specific.  TYPED 2026-09-25 (lane
; seqeng); was spelled as nop / ret ov / swi 6 / push_f ... around .byte.
	.long 0x0000f496, 0x0000f4b0, 0x0000f4ca, 0x0000f4e4
	.long 0x0000f4fe, 0x0000f518, 0x0000f532, 0x0000f54c
	.long 0x0000f566, 0x0000f580, 0x0000f59a, 0x0000f5b4
	.long 0x0000f5ce, 0x0000f5e8, 0x0000f602, 0x0000f61c

FloppyIO_ConfigureSwitchboard:
	cp (4600:16), 0
	jrl z, FloppyIO_ConfigSwb_Mode0
	ld c, 0x0:opc
	and (0xfdad:16), 251
	ld (0xf23d:16), 0
	jrl FloppyIO_ConfigSwb_QueueEvent

FloppyIO_ConfigSwb_Mode0:
	or a, 0x4
	ld c, 0xff:opc
	or (0xfdad:16), 4
	ld (0xf23d:16), 255

FloppyIO_ConfigSwb_QueueEvent:
	call FloppyIO_ComputeSwitchboardAddr
	ld (4330:16), 1
	ld e, 0x91:opc
	ld d, 0x3:opc
	ld w, 0x4:opc
	xor a, a
	cp (4600:16), 0
	jrl nz, FloppyIO_ConfigSwb_DispatchAndReinit
	ld a, 0x4:opc
	push xhl
	ld xhl, 0xf73d
	andmi8 (xhl), 0xf8
	pop xhl

FloppyIO_ConfigSwb_DispatchAndReinit:
	call	16624640
	call	SwbtWr_ReinitBothBanks
	ret
SeqPlay_PrepareAndScanChannels:
	call SeqPlay_CheckStartConditions
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	ld (0xf19e:16), wa
	ld (0x00ffec:24), wa
	ld (4237:16), wa

SeqPlay_InitTrackLoop:
	ld (4009:16), 0
	call SMF_VoiceSetup_AssignToTrack
	call SeqTrack_ScanActiveChannels
	call SeqTrack_ClearTempoAccumulators
	call SeqTrack_ClearPlaybackBuffers
	call SMF_ReadAndValidateMTrkHeader
	cp (3830:16), 0
	jrl z, SeqPlay_InitTrackLoop_Continue
	call FloppyIO_ReturnReady
	jrl SeqPlay_CheckLoadStatus

SeqPlay_InitTrackLoop_Continue:
	call SeqTrack_InitScoopAndSetWall
	incw 1, (4237:16)
	ld wa, (4237:16)
	cp wa, (3934:16)
	jrl c, SeqPlay_InitTrackLoop
	call FloppyIO_ReturnReady
	cp (3830:16), 0
	jrl nz, SeqPlay_CheckLoadStatus
	call SeqTrack_ValidateAndAssignVoices
	cp (3830:16), 0
	jrl nz, SeqPlay_CheckLoadStatus
	call VoiceChannels_LoadPartMapAndInitPan

SeqPlay_CheckLoadStatus:
	ret

SeqTrack_AssignFloppyChannels:
	xor iy, iy
	xor ix, ix
	ld (5113:16), 0

SeqTrack_AssignChannel_Loop:
	cpw (0xf231:16), 16
	jrl c, SeqTrack_ErrorMark
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ld bc, (0x286d:16)
	cp wa, bc
	jrl ugt, SeqTrack_ErrorMark
	cp wa, 0:i3
	jrl z, SeqTrack_ErrorMark
	pushw wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ormi8 (xhl), 0x80
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	popw wa
	ld xhl, 0xf250
	or_srib_im 0x07, 0xec, 0xf4, 0x80
	push xhl
	lda_dri XHL, 0x07, 0xec, 0xf4
	ldfr_lerp XHL, 0x38
	pop xhl
	stw_dri WA, 0x39, 0x01, 0x00
	ld xhl, 0xc9e
	stw_dri WA, 0x07, 0xec, 0xf0
	ld xhl, 0xcbe
	xor bc, bc
	ld c, (5113:16)
	push xiy
	ld iy, bc
	stiw_ind 0x07, 0xec, 0xf4, 0x05, 0x00
	pop xiy
	add iy, 0x3
	add ix, 0x2
	inc 1, (5113:16)
	cp (5113:16), 16
	jrl c, SeqTrack_AssignChannel_Loop
	jrl SeqTrack_AssignChannels_Done

SeqTrack_ErrorMark:
	ld (3830:16), 255
	ld (4323:16), 255

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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (xix+), a
	bit 7, a
	jrl nz, FloppyIO_ReadTrackBuf_ReadLoop
	sub xix, 0x106e

FloppyIO_ReadTrackBuf_Done:
	ret

SeqTrack_DispatchPartEvt:
	call SeqTrack_ClearPartEventParams
	cp ix, 1:i3
	jrl z, SeqTrack_DispatchPart_Mode1
	cp ix, 2:i3
	jrl z, SeqTrack_DispatchPart_Mode2
	jrl SeqTrack_DispatchPart_Mode3

SeqTrack_DispatchPart_Mode1:
	ld a, (4206:16)
	and a, 0x7f
	ld (4211:16), a
	jrl SeqTrack_DispatchPart_Done

SeqTrack_DispatchPart_Mode2:
	ld a, (4206:16)
	and a, 0x7f
	rrc a
	ld w, a
	and a, 0x7f
	and w, 0x80
	ld l, (4207:16)
	and l, 0x7f
	or l, w
	ld (4212:16), a
	ld (4211:16), l
	jrl SeqTrack_DispatchPart_Done

SeqTrack_DispatchPart_Mode3:
	ld a, (4206:16)
	and a, 0x7f
	rrc a, 2
	ld w, a
	and a, 0x3f
	and w, 0xc0
	ld l, (4207:16)
	and l, 0x7f
	rrc l
	ld h, l
	and l, 0x7f
	and h, 0x80
	or l, w
	ld c, (4208:16)
	and c, 0x7f
	or c, h
	ld (4213:16), a
	ld (4212:16), l
	ld (4211:16), c

SeqTrack_DispatchPart_Done:
	ret

SeqTrack_ComputeTempoScaling:
	ldw (3946:16), 0
	sla iy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
	pop xix
	srl iy, 1
	ld bc, (4211:16)
	ld e, (4213:16)
	xor d, d
	cp de, 0:i3
	jrl z, SeqTrack_ComputeTempo_NoDelta
	pushw wa
	xor wa, wa
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
	popw wa
	ldiw_erp 0xea, 0
	ldiw_erp 0xe6, 0
	add xde, xbc
	cpiw_erp 0xea, 0
	jrl ule, SeqTrack_ComputeTempo_Phase2
	pushw wa
	ld wa, de
	ld de, 1:i3
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
	popw wa

SeqTrack_ComputeTempo_Phase2:
	ldiw_erp 0xe2, 0
	ldiw_erp 0xea, 0
	add xwa, xde
	cpiw_erp 0xe2, 0
	jrl ule, SeqTrack_ComputeTempo_Phase3
	ld de, 1:i3
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
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
	stw_dri DE, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_Phase3:
	cp wa, (3936:16)
	jrl c, SeqTrack_ComputeTempo_Phase3Store
	xor de, de
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
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
	stw_dri WA, 0x07, 0xf0, 0xf4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_NoDelta:
	ldiw_erp 0xe2, 0
	ldiw_erp 0xe6, 0
	add xwa, xbc
	cpiw_erp 0xe2, 0
	jrl ule, SeqTrack_ComputeTempo_NoDeltaDirect
	ld de, 1:i3
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	push xix
	ld xix, 0xfae
	stw_dri DE, 0x07, 0xf0, 0xf4
	pop xix
	jrl SeqTrack_UpdateVolumesExit

SeqTrack_ComputeTempo_NoDeltaDirect:
	ld hl, (3936:16)
	cp wa, hl
	jrl c, SeqTrack_ComputeTempo_NoDeltaStore
	xor de, de
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	add (3946:16), wa
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
	stw_dri WA, 0x07, 0xf0, 0xf4
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (4009:16), 0
	cp a, 2:i3
	jrl z, SMF_ParseTrack_MetaEvt02
	cp a, 3:i3
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (4009:16), 255
	jrl Voice_NullRet

SMF_ParseTrack_MetaEvt51:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld a, 0x82:opc
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
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	jrl nc, SoundGen_ScanBitmap_Next
	ld (0x2877:16), c
	inc 1, (0x2877:16)
	pushw bc
	call Scoop_SpecialMode_ParamCheckBound
	popw bc

SoundGen_ScanBitmap_Next:
	inc 1, c
	cp c, 0xf
	jrl ule, SoundGen_ScanBitmap_Loop
	ret

FloppyIO_ReturnReady:
	ld w, 0x1:opc
	ret

SMF_ReadMidiEventToBuffer:
	ld (4010:16), a
	xor bc, bc
	ld xix, 0xfab
	ld (xix+), a
	inc 1, c

SMF_ReadMidiEvt_ReadLoop:
	pushw bc
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (xix+), a
	inc 1, c
	ld a, (4010:16)
	and a, 0xf0
	ld w, 0x2:opc
	cp a, 0xd0
	jrl z, SMF_ReadMidiEvt_OneByteMsg
	cp a, 0xc0
	jrl nz, SMF_ReadMidiEvt_CheckComplete

SMF_ReadMidiEvt_OneByteMsg:
	ld w, 0x1:opc

SMF_ReadMidiEvt_CheckComplete:
	cp c, w
	jrl ule, SMF_ReadMidiEvt_ReadLoop
	call MidiEvent_DispatchSetA

SMF_ReadMidiEvt_Done:
	ret

FloppyIO_ReadMidiEventBytes:
	ld c, a
	ld a, (4010:16)
	ld l, a
	and l, 0xf0
	ld xix, 0xfab
	ld (xix+), a
	xor h, h
	ld a, c

FloppyIO_ReadMidiEvtBytes_Loop:
	ld (xix+), a
	inc 1, h
	ld c, 0x1:opc
	cp l, 0xd0
	jrl z, FloppyIO_ReadMidiEvtBytes_OneByteMsg
	cp l, 0xc0
	jrl nz, FloppyIO_ReadMidiEvtBytes_CheckDone

FloppyIO_ReadMidiEvtBytes_OneByteMsg:
	ld c, 0x0:opc

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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	jrl	t, FloppyIO_ReadMidiEvtBytes_Loop

FloppyIO_ReadMidiEvtBytes_DispatchCheck:
	cpw (3932:16), 0
	jrl z, FloppyIO_DispatchMidiEvent
	cpw (3934:16), 1
	jrl z, FloppyIO_DispatchMidiEvent
	call MidiEvent_DispatchSetB
	jrl FloppyIO_ReadMidiEvtBytes_Exit

FloppyIO_DispatchMidiEvent:
	call MidiEvent_DispatchSetA

FloppyIO_ReadMidiEvtBytes_Exit:
	ret

VoiceChannels_LoadPartMapAndInitPan:
	ld xiy, VoiceChannels_PartMapTable
	cp (4600:16), 1
	jrl z, VoiceChannels_LoadPartMap_Mode1
	ld xiy, VoiceChannels_PartMapTable_0x10

VoiceChannels_LoadPartMap_Mode1:
	ld xix, 0xf1a0
	ldw bc, 0x10
	ldir85
	ldw (0xf290:16), 0xffff
	call VoiceChannels_InitPanFromPreset
	ret

VoiceChannels_PartMapTable:
; Two 16-byte MIDI-channel -> part-number maps (values 0x00..0x13).
; Read by VoiceChannels_LoadPartMapAndInitPan (0xF23DC7):
; XIY = this table when the byte at 0x11F8 is 1, else +0x10
; (VoiceChannels_PartMapTable_0x10); ldir copies BC = 16 bytes to RAM 0xF1A0.
; The +0x10 map equals the +0x00 map with entries 9 and 15 swapped
; (0x05 <-> 0x0C), the same channel-10/16 exchange VoiceChannel_ParamTable1
; and SeqTrack_ChannelMapIdentity make in that mode.
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03, 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03, 0x04, 0x0c, 0x06, 0x07, 0x11, 0x12, 0x13, 0x05

SeqPlay_DelayLoop_Outer:
	ldw bc, 0xc00

SeqPlay_DelayLoop_InnerInit:
	ldw hl, 0x3c0

SeqPlay_DelayLoop_Inner:
	djnz16 hl, SeqPlay_DelayLoop_Inner
	djnz16 bc, SeqPlay_DelayLoop_InnerInit
	ret

SeqPlay_InitChannelParams:
	push xiy
	push xde
	push xhl
	xor xhl, xhl
	xor xde, xde
	ld a, 0x2:opc
	ld w, 0x80:opc
	ldw bc, 0x10

SeqPlay_InitChannelParams_Loop:
	ld hl, de
	ld xix, ChannelRecord_PtrTable
	sla hl, 2
	ld_sril3 XIY, 0x07, 0xf0, 0xec
	ld (xiy + 11), a
	ld (xiy + 10), w
	inc 1, de
	djnz16 bc, SeqPlay_InitChannelParams_Loop
	pop xhl
	pop xde
	pop xiy
	ret

FloppyIO_ComputeSwitchboardAddr:
	ld xhl, 0xab000
	xor xwa, xwa
	ld a, (0x00ffe3:24)
	sla xwa, 11
	add xhl, xwa
	ld xix, xhl
	add xix, 0xbd
	ld (xix), c
	ret

SMF_VoiceSetup_AssignToTrack:
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	ld ix, iy
	cpw (0xf231:16), 16
	jrl c, SMF_VoiceSetup_Exit
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ld bc, (0x286d:16)
	cp wa, bc
	jrl ugt, SMF_VoiceSetup_Exit
	cp wa, 0:i3
	jrl z, SMF_VoiceSetup_Exit
	pushw wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
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
	lda_dri XHL, 0x07, 0xec, 0xf4
	ld (xhl + 1), wa
	ldto_lerp XHL, 0x38
	ld xhl, 0xc9e
	sla ix, 1
	stw_dri WA, 0x07, 0xec, 0xf0
	ld xhl, 0xcbe
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	stiw_ind 0x07, 0xec, 0xf4, 0x05, 0x00

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
	ld (xix+), WA
	djnz16 bc, SeqTrack_ClearTempoAccum_Loop
	pop xix
	popw bc
	popw wa
	ret

SMF_ReadAndValidateMTrkHeader:
	ld bc, 4:i3
	ld xiy, SMF_HeaderMagic_MTrk_Ref

SMF_MTrk_ReadByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_MTrk_ReadFailed
	pop xbc
	pop xwa
	jp SMF_MTrk_CompareSignature

SMF_MTrk_ReadFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_MTrk_CompareSignature:
	cp A, (xiy+)
	jrl z, SMF_MTrk_SignatureMatch
	ld (3830:16), 255
	ldw (6699:16), 49
	jrl SMF_NullRet

SMF_MTrk_SignatureMatch:
	djnz16 bc, SMF_MTrk_ReadByteLoop
	ld (6887:16), 1
	call FloppyIO_ReadNextByte
	ld (6886:16), a
	call FloppyIO_ReadNextByte
	ld (6885:16), a
	call FloppyIO_ReadNextByte
	ld (6884:16), a
	call FloppyIO_ReadNextByte
	ld (6883:16), a
	ld (6887:16), 0
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_MTrk_FileSizeReadFailed
	pop xbc
	pop xwa
	jp SMF_MTrk_FileSizeReady

SMF_MTrk_FileSizeReadFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_MTrk_FileSizeReady:
	ld (4236:16), 0

SMF_ProcessVoiceData:
	cp (4323:16), 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_CheckFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_ReadTrackBuffer

SMF_VoiceData_CheckFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_ReadTrackBuffer:
	call FloppyIO_ReadToTrackBuffer
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_ReadTrackFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_DispatchAndParse

SMF_VoiceData_ReadTrackFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_DispatchAndParse:
	call SeqTrack_DispatchPartEvt
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	call SeqTrack_ComputeTempoScaling
	call SeqTrack_UpdateChannelVolumes
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_ParseFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_CheckMetaFlag

SMF_VoiceData_ParseFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_CheckMetaFlag:
	cp a, 0xff
	jrl nz, SMF_VoiceData_CheckSysEx
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_MetaParseFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_CheckEndOfTrack

SMF_VoiceData_MetaParseFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_CheckEndOfTrack:
	cp (4009:16), 255
	jrl z, SMF_VoiceData_HandleEndOfTrack
	cp (4323:16), 0
	jrl z, SMF_ProcessVoiceData
	ld (3830:16), 255
	jr SMF_EventFailureExit

SMF_VoiceData_HandleEndOfTrack:
	call SeqTrack_ReleaseVoiceAtEndOfTrack

SMF_VoiceData_DrainRemaining:
	ld xbc, (6883:16)
	ld xwa, 0:i3
	cp xbc, xwa
	jp z, (SMF_VoiceData_DrainDone:24)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_SysExFailed
	pop xbc
	pop xwa
	jp SMF_VoiceData_SysExContinue

SMF_VoiceData_SysExFailed:
	pop xbc
	pop xwa
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_SysExContinue:
	jrl SMF_ProcessVoiceData

SMF_VoiceData_CheckMidiStatus:
	bit 7, a
	jrl z, SMF_VoiceData_ReadMidiRunning
	call SMF_ReadMidiEventWithStatus
	cp (4323:16), 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_MidiStatusFailed
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

SMF_VoiceData_MidiStatusFailed:
	pop xbc
	pop xwa

SMF_EventFailureExit:
	ld (3830:16), 255
	jrl SMF_NullRet

SMF_VoiceData_ReadMidiRunning:
	call FloppyIO_ReadMidiEventBytes
	cp (4323:16), 0
	jrl nz, SMF_VoiceData_SetErrorFlag
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_VoiceData_RunningMidiFailed
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

SMF_VoiceData_RunningMidiFailed:
	pop xbc
	pop xwa

SMF_VoiceData_SetErrorFlag:
	ld (3830:16), 255

SMF_NullRet:
	ret

; SMF track-chunk ID "MTrk".  Read by SMF_ReadAndValidateMTrkHeader
; (0xF23F00): BC = 4 bytes, XIY = this, each byte
; from FloppyIO_ReadNextByte is compared with (XIY).
SMF_HeaderMagic_MTrk_Ref:	.ascii "MTrk"

SeqTrack_InitScoopAndSetWall:
	xor a, a
	ld hl, 1:i3
	ld (0x2877:16), a
	inc 1, (0x2877:16)
	ld (9858:16), l
	inc 1, (9858:16)
	ld a, (0x2877:16)
	ld (9860:16), a
	pushw wa
	push xhl
	call SetWall_ValidateAndApply
	pop xhl
	popw wa
	ret

SeqTrack_ValidateAndAssignVoices:
	cpw (0xf231:16), 16
	jrl nc, SeqTrack_AssignVoices_HaveDispatch
	ld (4323:16), 255
	jrl SoundGen_ResetVoiceBitmapAndFlag

SeqTrack_AssignVoices_HaveDispatch:
	ld de, (0xf251:16)
	ld hl, de
	call ToneGen_CopyBlockToVoiceBuffer
	ld (0x27d6:16), iy
	pushw de
	ld hl, 1:i3

SeqTrack_ClearVoiceSlots_Loop:
	pushw hl
	call VoiceChannel_ResetSlotByIndex
	popw hl
	inc 1, hl
	cp hl, 0x10
	jrl ule, SeqTrack_ClearVoiceSlots_Loop
	popw de
	call SeqTrack_AssignFloppyChannels
	cp (3830:16), 0
	jrl nz, SoundGen_ResetBitmapDone
	call SoundGen_InitAllVoiceChannels
	ld (6650:16), 0

MidiSysEx_CmdDispatchLoop:
	call ToneGen_ReadAndDispatchVoiceBlock
	ld a, (4211:16)
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
	ld a, 0x81:opc
	call ToneGen_WriteAllChannels
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_AllSoundOff:
	ld a, 0x82:opc
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
	ld iy, (4211:16)
	and iy, 0xf
	and (4211:16), 240
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 6:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_PolyPressure:
	cp hl, 3:i3
	jrl z, MidiSysEx_PolyPressure_Mode3
	ld iy, (4211:16)
	and iy, 0xf
	ld (4211:16), 128
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 4:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_PolyPressure_Mode3:
	ld iy, (4211:16)
	and iy, 0xf
	ld (4211:16), 208
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 3:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ControlChange:
	xor hl, hl
	ld l, (4213:16)
	cp l, 0x7f
	jrl z, MidiSysEx_CmdDispatchLoop
	jrl MidiSysEx_CC_LookupPartMap

MidiSysEx_CC_LookupPartMap:
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	cp (4600:16), 1
	jrl z, MidiSysEx_CC_PartMapSelected
	ld xix, SeqTrack_ChannelMapIdentity_0x10

MidiSysEx_CC_PartMapSelected:
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ld (4213:16), a
	ld iy, hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 6:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ProgramChange:
	xor hl, hl
	ld l, (4213:16)
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	cp (4600:16), 1
	jrl z, MidiSysEx_PgmChg_PartMapSelected
	ld xix, SeqTrack_ChannelMapIdentity_0x10

MidiSysEx_PgmChg_PartMapSelected:
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ld (4213:16), a
	ld iy, hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 6:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_ChannelPressure:
	ld iy, (4211:16)
	and iy, 0xf
	ld (4211:16), 209
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 3:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_PitchBend:
	ld iy, (4211:16)
	and iy, 0xf
	ld (4211:16), 210
	pushw iy
	call SoundGen_CaptureVoiceParams
	ld bc, 4:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

MidiSysEx_Cmd_SystemMessage:
	ld iy, (4211:16)
	and iy, 0xf
	ld (4211:16), 211
	call SoundGen_CaptureVoiceParams
	pushw iy
	ld bc, 3:i3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

SoundGen_ResetVoiceBitmapAndFlag:
	call ToneGen_SyncVoiceBitmapFromSlots
	or (0x28b3:16), 16

SoundGen_ResetBitmapDone:
	ret

SeqTrack_ChannelMapIdentity:
; Two 16-byte MIDI-channel maps: +0x00 is the identity 0..15, +0x10 is the
; identity with entries 9 and 15 swapped.  Read by MidiSysEx_CC_LookupPartMap
; (0xF24249) and MidiSysEx_Cmd_ProgramChange
; (0xF2427F): XIX = this table when the byte at 0x11F8
; is 1, else +0x10 (SeqTrack_ChannelMapIdentity_0x10), then ld A,(XIX+HL)
; with HL = the channel byte at 0x1075, and A is written back there -- the
; channel is remapped in place.  TYPED 2026-09-25 (lane seqeng); was spelled
; nop / normal / push sr / pop sr / max / halt / ei 7 / ... / .byte 0x09.
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x0f, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x09

ToneGen_ComputeBlockPtr:
	push xiy
	ld xiy, (7514:16)
	extz xhl
	dec 1, xhl
	sla xhl, 8
	add xiy, xhl
	ld (4349:16), xiy
	xor xhl, xhl
	pop xiy
	ret

SeqTrack_ClearPartEventParams:
	xor wa, wa
	ld (4211:16), wa
	ld (4213:16), wa
	ret

SoundGen_RefreshAllVoices:
	push xiy
	call SoundGen_CaptureVoiceParams
	pop xiy
	ld bc, (3946:16)
	ld a, 0x81:opc

SoundGen_RefreshVoices_Loop:
	ld a, 0x81:opc
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cp (4323:16), 0
	jrl nz, SoundGen_RefreshVoices_Done
	djnz16 bc, SoundGen_RefreshVoices_Loop
	call ToneGen_WriteChannelRegs
	or (4236:16), 1
	ld (4323:16), 0

SoundGen_RefreshVoices_Done:
	ret

SeqTrack_ComputeScaledDelta:
	ld wa, (3936:16)
	cp wa, 0x60
	jrl z, SeqTrack_ScaledDelta_PassThrough
	ld e, (4213:16)
	ld wa, (4211:16)
	cp e, 0:i3
	jrl z, SeqTrack_ScaledDelta_NoDivide3
	ldw hl, 0x60
	mul xwa, hl
	ldto_werp DE, 0xe2
	ld (4333:16), wa
	ld (4335:16), de
	xor w, w
	ld a, (4213:16)
	mul xwa, hl
	ldto_werp DE, 0xe2
	add wa, (4335:16)
	ld de, wa
	ld wa, (4333:16)
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	jrl SeqTrack_ScaledDelta_Return

SeqTrack_ScaledDelta_NoDivide3:
	ld wa, (4211:16)
	ldw hl, 0x60
	mul xwa, hl
	ldto_werp DE, 0xe2
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	jrl SeqTrack_ScaledDelta_Return

SeqTrack_ScaledDelta_PassThrough:
	xor de, de
	ld e, (4213:16)
	ld wa, (4211:16)

SeqTrack_ScaledDelta_Return:
	ret

Sequencer_ValidateFileData:
	call FloppyIO_ClearTrackParseBuffer
	call FloppyIO_ReadVariableLength
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xix, (4376:16)
	add xix, (4211:16)
	cp xix, 0x17f9
	jrl ule, Sequencer_Advance_StorePtr
	push xix
	call FileIO_ReadBlockToFilePos
	pop xix
	incw 1, (4327:16)
	pushw wa
	push xhl
	pushw de
	ld wa, (4327:16)
	xor de, de
	ld hl, 4:i3
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	cp de, 0:i3
	jrl nz, Sequencer_Advance_DivDone

Sequencer_Advance_DivDone:
	popw de
	pop xhl
	popw wa
	sub xix, 0x400

Sequencer_Advance_StorePtr:
	ld (4376:16), xix
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6883:16)
	cp xwa, xbc
	jp z, (Sequencer_Advance_UpdateRemaining:24)
	cp (6887:16), 1
	jp z, (Sequencer_Advance_UpdateRemaining:24)
	sub xwa, (4211:16)

Sequencer_Advance_UpdateRemaining:
	ld (6883:16), xwa
	pop xbc
	pop xwa
	ld (4323:16), 0
	ret

SMF_SetTempoFromMetaEvent:
	ld (3950:16), 0
	ld (3951:16), a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (3948:16), a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (3949:16), a
	ld h, (3951:16)
	ld l, (3948:16)
	ldw wa, 0x9387
	ld de, 3:i3
	ldfr_werp DE, 0xe2
	div xwa, hl
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
	ld xiy, 7:i3
	cpw (3932:16), 0
	jrl z, SoundGen_ApplyTempoToVoice
	cpw (3934:16), 1
	jrl z, SoundGen_ApplyTempoToVoice
	ld iy, (4237:16)
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_ApplyTempoToVoice:
	pushw wa
	call SoundGen_CaptureVoiceParams
	popw wa
	ld bc, wa
	ld a, 0x80:opc
	cpw (3932:16), 0
	jrl z, SoundGen_UpdateTempoAndScale
	cpw (3934:16), 1
	jrl z, SoundGen_UpdateTempoAndScale
	ld a, 0xa0:opc
	ld w, 0x7:opc
	or a, w

SoundGen_UpdateTempoAndScale:
	pushw bc
	call SoundGen_UpdateAndRefresh
	popw bc
	cp (4323:16), 0
	jrl nz, SoundGen_NullRet
	ld iy, 7:i3
	cpw (3932:16), 0
	jrl z, SoundGen_ScaleAndWriteTempo
	cpw (3934:16), 1
	jrl z, SoundGen_ScaleAndWriteTempo
	ld iy, (4237:16)
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_ScaleAndWriteTempo:
	sla iy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
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
	cp (4323:16), 0
	jrl nz, SoundGen_NullRet
	ld a, c
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cp (4323:16), 0
	jrl nz, SoundGen_NullRet
	ld a, b
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullRet
	ld xiy, 7:i3
	cpw (3932:16), 0
	jrl z, SoundGen_SetVoiceBitAndWriteRegs
	cpw (3934:16), 1
	jrl z, SoundGen_SetVoiceBitAndWriteRegs
	ld iy, (4237:16)
	extz xiy
	call SoundGen_ClampVoiceIndexMin1

SoundGen_SetVoiceBitAndWriteRegs:
	ld bc, iy
	ld de, (0x00ffec:24)
	ld a, c
	scf
	stcf_a_16 de
	ld (0x00ffec:24), de
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0

SoundGen_NullRet:
	ret

SoundGen_CaptureVoiceParams:
	push xde
	sla xiy, 1
	ld xde, 0xc9e
	ldw_sri WA, 0x07, 0xe8, 0xf4
	ld (0x28af:16), wa
	srl xiy, 1
	ld xde, 0xcbe
	ldb_sri A, 0x07, 0xe8, 0xf4
	xor w, w
	ld (9830:16), wa
	pop xde
	ret

ToneGen_LoadBlockValidate:
	push xhl
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld iy, (9830:16)
	stb_dri A, 0x07, 0xec, 0xf4
	pop xhl
	ret

SoundGen_StoreVoiceParamsToTables:
	push xix
	ld wa, (9830:16)
	ld xix, 0xf218
	stb_dri A, 0x07, 0xf0, 0xec
	sla hl, 1
	ld wa, (0x28af:16)
	ld xix, 0xf1f8
	stw_dri WA, 0x07, 0xf0, 0xec
	pop xix
	ret

MidiEvent_DispatchSetA:
	ld xix, 0xfab
	ld a, (4011:16)
	pushw hl
	ld hl, (4012:16)
	cp l, 0x7f
	jrl ule, MidiEvent_ClampVelocityA_Low
	ld l, 0x7f:opc

MidiEvent_ClampVelocityA_Low:
	cp h, 0x7f
	jrl ule, MidiEvent_ClampVelocityA_High
	ld h, 0x7f:opc

MidiEvent_ClampVelocityA_High:
	ld (4012:16), hl
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
	cp w, 0:i3
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
	ld a, (4011:16)
	pushw hl
	ld hl, (4012:16)
	cp l, 0x7f
	jrl ule, MidiEvent_ClampVelocityB_Low
	ld l, 0x7f:opc

MidiEvent_ClampVelocityB_Low:
	cp h, 0x7f
	jrl ule, MidiEvent_ClampVelocityB_High
	ld h, 0x7f:opc

MidiEvent_ClampVelocityB_High:
	ld (4012:16), hl
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
	cp w, 0:i3
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
	ld xiy, 1:i3

SoundGen_ClampVoice_Done:
	ret

SeqTrack_ReleaseVoiceAtEndOfTrack:
	ld hl, (4237:16)
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
	ld iy, (4237:16)
	ld hl, iy
	push xhl
	call SoundGen_ReadVoiceRegs
	ld a, 0x82:opc
	call ToneGen_LoadBlockValidate
	call SoundGen_StoreVoiceToTables_Clamped
	pop xhl

SeqTrack_ReleaseVoice_Done:
	ret

SMF_ReadMidiEventWithStatus:
	ld (4010:16), a
	xor bc, bc
	ld xix, 0xfab
	ld (xix+), a
	inc 1, c

SMF_ReadMidiStatus_ReadLoop:
	pushw bc
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (xix+), a
	inc 1, c
	ld a, (4010:16)
	and a, 0xf0
	ld w, 0x2:opc
	cp a, 0xd0
	jrl z, SMF_ReadMidiStatus_OneByteMsg
	cp a, 0xc0
	jrl nz, SMF_ReadMidiStatus_CheckComplete

SMF_ReadMidiStatus_OneByteMsg:
	ld w, 0x1:opc

SMF_ReadMidiStatus_CheckComplete:
	cp c, w
	jrl ule, SMF_ReadMidiStatus_ReadLoop
	call MidiEvent_DispatchSetB

SMF_ReadMidiStatus_Done:
	ret

SetWall_ValidateAndApply:
	ld (0x27d2:16), 0
	call SetWall_ParserInit
	ld a, (0x2877:16)
	cp a, 1:i3
	jrl c, SetWall_ParamOutOfRange
	cp a, (0x28a1:16)
	jrl ugt, SetWall_ParamOutOfRange
	cp a, (9858:16)
	jrl z, SetWall_ParamOutOfRange
	ld a, (9858:16)
	cp a, 1:i3
	jrl c, SetWall_ParamOutOfRange
	cp a, (0x28a1:16)
	jrl ugt, SetWall_ParamOutOfRange
	ld a, (9860:16)
	cp a, 1:i3
	jrl c, SetWall_ParamOutOfRange
	cp a, (0x28a1:16)
	jrl ule, SetWall_ParamsValid

SetWall_ParamOutOfRange:
	ld (0x287a:16), 3
	jrl Scoop_NullRet

SetWall_ParamsValid:
	xor hl, hl
	ld (0x287a:16), 0
	and (0x287b:16), 191
	ld a, (0x2877:16)
	call SetWall_SingleSlotResolve
	cp (0x287a:16), 0
	jrl z, SetWall_SlotResolved
	jrl Scoop_NullRet

SetWall_SlotResolved:
	ld wa, (0x28af:16)
	ld (0x27d4:16), wa
	ld a, (9858:16)
	call SetWall_SingleSlotResolve
	cp (0x287a:16), 0
	jrl nz, Scoop_NullRet
	ld wa, (0x28af:16)
	ld (0x27d8:16), wa
	ld a, (9860:16)
	cp a, (0x2877:16)
	jrl z, SetWall_InitVoiceSlots
	cp a, (9858:16)
	jrl z, SetWall_InitVoiceSlots
	ld a, (0x2877:16)
	pushw wa
	ld a, (9860:16)
	ld (0x2877:16), a
	call Scoop_SpecialMode_ParamCheckBound
	popw wa
	ld (0x2877:16), a

SetWall_InitVoiceSlots:
	xor xhl, xhl
	ld l, (0x2877:16)
	call VoiceChannel_ClearRegisters
	ld xix, 0x17fa
	nop
	ld wa, (0x27d4:16)
	ld (0x28af:16), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	ld (0x27d6:16), iy
	xor xhl, xhl
	ld l, (9858:16)
	call VoiceChannel_ClearRegisters
	ld xix, 0x18fa
	nop
	ld wa, (0x27d8:16)
	ld (0x28af:16), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	ld (0x27da:16), iy
	call DispatchHandler_JumpToSubHandler
	xor hl, hl
	ld l, (9860:16)
	dec 1, hl
	muls l, 0x3
	push xiy
	ld xiy, 0xf250
	or_srib_im 0x07, 0xf4, 0xec, 0x80
	inc 1, xhl
	stw_dri IX, 0x07, 0xf4, 0xec
	pop xiy
	ld (3308:16), ix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld (0x2881:16), xhl
	ld ix, 5:i3
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xffff
	call VoiceChannel_UpdateParamSet
	call ToneGen_ValidateVoiceCh2

Scoop_ProcessCompareLoop:
	cp (0x27d2:16), 255
	jrl nz, Scoop_Compare_NotFinished
	jrl Scoop_NullRet

Scoop_Compare_NotFinished:
	cp (0x27d2:16), 3
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
	bit 0, (0x27d2:16)
	jrl z, Scoop_Compare_Bit1Test
	call ToneGen_AdvanceVoiceLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_Bit1Test:
	bit 1, (0x27d2:16)
	jrl z, Scoop_Compare_ValueCompare
	call VoiceChannel_FindNextLoop
	jrl Scoop_ProcessCompareLoop

Scoop_Compare_ValueCompare:
	ld a, (0x27dc:16)
	ld w, (0x27de:16)
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
	ld xiz, (4349:16)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	pushw bc
	push xhl
	call ToneGen_ComputeBlockPtr
	xor xiy, xiy
	ld xiy, (4349:16)
	ld xix, 0x17fa
	ldw bc, 0x100
	ldir85
	pop xhl
	popw bc
	ld iy, hl
	ld wa, 1:i3
	pushw bc
	push xhl
	call DispatchHandler_JumpSub
	pop xhl
	popw bc
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	xor xiy, xiy
	ld iy, 5:i3
	ret

VoiceChannel_ResetSlotByIndex:
	push xix
	dec 1, hl
	ld iy, hl
	muls_erpb 0xf4, 0x03
	ld xix, 0xf250
	and_srib_im 0x07, 0xf0, 0xf4, 0x7f
	inc 1, iy
	stiw_ind 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld xix, 0xcbe
	stib_ind 0x07, 0xf0, 0xec, 0x05
	ld xix, 0xf218
	stib_ind 0x07, 0xf0, 0xec, 0x05
	sla hl, 1
	ld xix, 0xc9e
	stiw_ind 0x07, 0xf0, 0xec, 0xff, 0xff
	ld xix, 0xf1f8
	stiw_ind 0x07, 0xf0, 0xec, 0xff, 0xff
	pop xix
	ret

ToneGen_ReadAndDispatchVoiceBlock:
	xor hl, hl
	call VoiceChannel_ClearParamTable
	ld iy, (0x27d6:16)
	push xix
	ld xix, 0x17fa
	ldb_sri A, 0x07, 0xf0, 0xf4
	ld xix, 0x1073
	stb_dri A, 0x07, 0xf0, 0xec
	pop xix
	cp a, 0x82
	jrl z, ToneGen_ReadVoiceBlock_Done

ToneGen_ReadVoiceBlock_Loop:
	inc 1, hl
	pushw hl
	call VoiceChannel_AdvancePosition
	popw hl
	ld iy, (0x27d6:16)
	push xix
	ld xix, 0x17fa
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	bit 7, a
	jrl nz, ToneGen_ReadVoiceBlock_Done
	push xix
	ld xix, 0x1073
	stb_dri A, 0x07, 0xf0, 0xec
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
	cp (4323:16), 0
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
	ld hl, (0x28af:16)
	pushw bc
	call ToneGen_ComputeBlockPtr
	popw bc
	xor ix, ix

ToneGen_UpdateBlocks_Loop:
	push xde
	ld xde, 0x1073
	ldb_sri A, 0x07, 0xe8, 0xf0
	pop xde
	pushw bc
	push xix
	call ToneGen_WriteParamToBlock
	call ToneGen_AdvancePosition
	pop xix
	popw bc
	cp (4323:16), 0
	jrl nz, ToneGen_UpdateBlocks_Done
	inc 1, ix
	djnz16 bc, ToneGen_UpdateBlocks_Loop

ToneGen_UpdateBlocks_Done:
	ret

ToneGen_SetChannelFlag:
	ld bc, iy
	and bc, 0xf
	ld a, c
	scf
	stcfa_dd16 0xfa, 0x19
	ld de, (0x00ffec:24)
	ld a, c
	scf
	stcf_a_16 de
	ld (0x00ffec:24), de
	ret

ToneGen_WriteChannelRegs:
	push xix
	ld wa, (0x28af:16)
	sla iy, 1
	ld xix, 0xc9e
	stw_dri WA, 0x07, 0xf0, 0xf4
	ld wa, (9830:16)
	srl iy, 1
	ld xix, 0xcbe
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix
	ret

ToneGen_SyncVoiceBitmapFromSlots:
	push xix
	xor hl, hl
	xor bc, bc

ToneGen_SyncBitmap_Loop:
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
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
	lda_dri XIX, 0x07, 0xf0, 0xec
	ld wa, (xix + 1)
	ld iy, bc
	ld xix, 0xc9e
	sla iy, 1
	stw_dri WA, 0x07, 0xf0, 0xf4
	srl iy, 1
	ld xix, 0xcbe
	stib_ind 0x07, 0xf0, 0xf4, 0x05

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
	ld bc, 2:i3

FloppyIO_ClearParseBuf_Loop:
	ld (xix+), WA
	djnz16 bc, FloppyIO_ClearParseBuf_Loop
	ret

FloppyIO_ReadVariableLength:
	ld xix, 0x106e

FloppyIO_ReadVarLen_ReadLoop:
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld (xix+), a
	bit 7, a
	jrl nz, FloppyIO_ReadVarLen_ReadLoop
	sub xix, 0x106e

FloppyIO_ReadVarLen_Done:
	ret

SoundGen_ScalePitchByTempo:
	ld hl, (3936:16)
	cp hl, 0x60
	jrl z, SoundGen_ScalePitch_NoScale
	ldw hl, 0x60
	mul xwa, hl
	ldto_werp DE, 0xe2
	ld hl, (3936:16)
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2

SoundGen_ScalePitch_NoScale:
	ret

MidiEvent_HandleChannelPressureA:
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ld a, 0xd0:opc
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, ToneGen_SetSustainExitAlt
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
	jrl nz, ToneGen_SetSustainExitAlt
	ld a, (4012:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, ToneGen_SetSustainExitAlt
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0

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
	ld (4323:16), 0
	jrl VoiceSynth_NullRet2

MidiNoteOn_FoundFreeSlotA:
	call SndParam_LookupChannelVoice
	cp a, 0xff
	jr nz, MidiNoteOn_SetupVoiceA
	ld (4323:16), 0
	jp VoiceSynth_NullRet2
MidiNoteOn_SetupVoiceA:
	ordi8	(4236), 1
	ld	iy, (4011:16)
	and	iy, 15
	extz	xiy
	push	xiy
	push	xix
	call	SoundGen_CaptureVoiceParams
	pop	xix
	ld	a, 144:opc
	push	xix
	call	SoundGen_UpdateAndRefresh
	pop	xix
	pop	xiy
	cp	(4323:16), 0
	jrl	nz, VoiceSynth_NullRet2
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw	wa, xix, iy
	pop	xix
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	push	xix
	call	SoundGen_UpdateAndRefresh
	pop	xix
	pop	xiy
	cp	(4323:16), 0
	jrl	nz, VoiceSynth_NullRet2
	cp	(4600:16), 2
	jr	nz, MidiNoteOn_StandardNoteA
	ld	a, (4011:16)
	and	a, 15
	cp	a, 9
	jrl	nz, MidiNoteOn_NonDrumLookupA
	push	xix
	push	xbc
	push	xde
	xor	xhl, xhl
	ld	l, a
	mul	l, 2
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xix, 6711
	ld	a, 4:opc
	ld_rrw	bc, xix, hl
	ld	e, b
	xor	hl, hl
	ld	l, (4012:16)
	pushw	hl
	call	ApplyProgramChangeAs_Block_Code_Sub
	ld	a, l
	pop	xde
	pop	xbc
	pop	xix
	jp	Scoop_ApplySoundParams
MidiNoteOn_NonDrumLookupA:
	push	xix
	push	xbc
	push	xde
	xor	xhl, xhl
	ld	l, a
	mul	l, 2
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xix, 6711
	ld_rrw	wa, xix, hl
	ld	c, w
	call	MidiNoteOn_SetupVoiceA_Code_Helper
	ld	a, (4012:16)
	add	a, l
	pop	xde
	pop	xbc
	pop	xix
	jp	Scoop_ApplySoundParams
MidiNoteOn_StandardNoteA:
	ld a, (4012:16)

Scoop_ApplySoundParams:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet2
	ld a, (4013:16)
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet2
	ld a, (9830:16)
	ld (xix + 2), a
	ld wa, (0x28af:16)
	ld (xix + 3), wa
	xor a, a
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet2
	xor a, a
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet2
	call ToneGen_SetSustainBit
	push xix
	call ToneGen_WriteChannelRegs
	pop xix
	ld a, (4011:16)
	and a, 0xf
	or a, 0x80
	ld (xix), a
	ld a, (4012:16)
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	ld (4323:16), 0

VoiceSynth_NullRet2:
	ret

MidiNoteOff_FindActiveVoiceA:
	ld xiy, 0x11f9

MidiNoteOff_ScanActiveA_Loop:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceChkAlt
	ld a, (xiy)
	and a, 0xf
	ld l, (4011:16)
	and l, 0xf
	cp a, l
	jrl nz, ToneGen_LoopAdvanceChkAlt
	ld l, (4012:16)
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
	ld l, 0x60:opc
	divs wa, l
	cp a, 0:i3
	jrl nz, Scoop_ApplyMatchedVoiceEntry
	cp w, 4:i3
	jrl ugt, Scoop_ApplyMatchedVoiceEntry
	ld w, 0x5:opc

Scoop_ApplyMatchedVoiceEntry:
	ld xhl, (4349:16)
	stb_dri W, 0x07, 0xec, 0xf0
	pop xhl
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	ld (0x28af:16), hl
	ld (9830:16), ix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	push xix
	push xiy
	ld xix, (4349:16)
	ld iy, (9830:16)
	and iy, 0xff
	stb_dri A, 0x07, 0xf0, 0xf4
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
	ld a, (4012:16)
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

; VoiceSynth_Algorithm_Table: 16 x 32-bit handler pointers (stride 4).
; Read by VoiceSynth_AlgoTableDispatch (0xF24F0A):
; XHL = long [this + 4*A] then `call (xhl)`, reached from
; VoiceSynth_CommandDispatch (0xF24EAF) when the byte
; at 0x0FAC is < 0x10.  0x0FAC/0x0FAD are clamped to 0x7F as a pair by
; MidiEvent_ClampVelocityA_High (7-bit data bytes); the dispatcher's other cases
; are 0x20, 0x26, 0x40, 0x42, 0x43, 0x5B, 0x5D, 0x60-0x65, which are the
; MIDI control-change numbers bank-select LSB, data-entry LSB, hold,
; sostenuto, soft, reverb, chorus, data inc/dec, NRPN and RPN select --
; so [INFERENCE] this table serves CC 0..15, and its non-null entries are
; CC 0 (bank select MSB), 1 (modulation), 6 (data entry MSB), 7 (volume),
; 10 (pan) and 11 (expression).
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
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ld a, 0xd2:opc
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet3
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
	jrl nz, VoiceSynth_NullRet3
	ld a, (4012:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet3
	ld a, (4013:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceSynth_NullRet3
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0

VoiceSynth_NullRet3:
	ret

MidiEvent_HandleProgramChangeA:
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	bit 0, (4236:16)
	jrl nz, MidiPgmChg_CheckModeA
	call VoiceChannel_ApplyParamByMode
	ld (4323:16), 0

MidiPgmChg_CheckModeA:
	cp (4600:16), 0
	jr z, MidiPgmChg_Mode0_SetupA
	cp (4600:16), 2
	jrl z, MidiPgmChg_Mode2_SetupA
	jrl MidiPgmChg_Mode1_SetupA

MidiPgmChg_Mode0_SetupA:
	push	xix
	ld	xix, 3970
	ld_rrb	l, xix, iy
	stb_d8	(6743), l
	ld	xix, 3954
	ld_rrb	l, xix, iy
	stb_d8	(6744), l
	ldb_d8	l, (4012)
	stb_d8	(6745), l
	ld	xix, SeqTrack_ChannelMapIdentity_0x10
	ld_rrb	l, xix, iy
	stb_d8	(6748), l
	pop	xix
	ld	xwa, 6743
	call	16703893
	push	xiy
	push	xhl
	call	SoundGen_CaptureVoiceParams
	pop	xhl
	ld	a, 192:opc
	ldb_d8	w, (6746)
	and	w, 128
	rlc	w
	or	a, w
	ldb_d8	w, (6747)
	and	w, 128
	.byte 0xc8, 0xe8, 0x02	; rlc 0x02,w
	or	a, w
	push	xhl
	call	SoundGen_UpdateAndRefresh
	pop	xhl
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw	wa, xix, iy
	pop	xix
	srl	xiy, 1
	push	xhl
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	pop	xhl
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	push	xix
	ld	xix, SeqTrack_ChannelMapIdentity_0x10
	ld_rrb	a, xix, iy
	pop	xix
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	xor	a, a
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	ldb_d8	a, (6746)
	and	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	ldb_d8	a, (6747)
	and	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, SoundGen_NullReturn
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	stdi8	(4323), 0
	jrl	SoundGen_NullReturn
MidiPgmChg_Mode2_SetupA:
	push XIX
	ld XIX,0x00000f82
	ldb_dri l, 0x07, 0xf0, 0xf4
	ld (0x1a57:16), l
	ld XIX,0x00000f72
	ldb_dri l, 0x07, 0xf0, 0xf4
	ld (0x1a58:16), l
	ld l, (0x0fac:16)
	ld (0x1a59:16), l
	ld XIX,SeqTrack_ChannelMapIdentity_0x10
	ldb_dri l, 0x07, 0xf0, 0xf4
	ld (0x1a5c:16), l
	pop XIX
	call VoiceChannel_StoreVoiceIdx
	ld XWA,0x00001a57
	call MidiPgmChg_Mode0_SetupA_Code_Helper
	cpw (0x1a5f:16), 0x0009
	jr z, MidiPgmChg_Mode2_ApplyEnvelopeA
	ld XHL,0x00001a37
	ld bc, (0x1a5f:16)
	mul C,0x02
	add XHL,XBC
	ld a, (0x1a5a:16)
	ld (XHL),A
	ld a, (0x1a5b:16)
	ld (XHL+0x01),A
MidiPgmChg_Mode2_ApplyEnvelopeA:
	push xiy
	push xhl
	call SoundGen_CaptureVoiceParams
	pop xhl
	ld a, 0xc0:opc
	ld w, (6746:16)
	and w, 0x80
	rlc w
	or a, w
	ld w, (6747:16)
	and w, 0x80
	rlc w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	sla xiy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
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
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, SeqTrack_ChannelMapIdentity_0x10
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	ld a, (6746:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	ld a, (6747:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0
	jrl SoundGen_NullReturn

MidiPgmChg_Mode1_SetupA:
	push xiy
	call SoundGen_CaptureVoiceParams
	ld a, 0xc0:opc
	pop xiy
	push xix
	ld xix, 0xf72
	ldb_sri W, 0x07, 0xf0, 0xf4
	pop xix
	push xiy
	and w, 0x1
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
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
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, SeqTrack_ChannelMapIdentity
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	ld a, 0x0:opc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	ld a, (4012:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, 0xf82
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	and a, 0x70
	srl a, 4
	call SoundGen_UpdateAndRefresh
	cp (4323:16), 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	ld (4323:16), 0
	jrl SoundGen_NullReturn

SoundGen_NullReturn:
	ret

MidiEvent_HandleChannelPressureB:
	ld iy, (4237:16)
	extz xiy
	call SoundGen_ClampVoiceIndexMin1
	and xiy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ld w, (4011:16)
	and w, 0xf
	ld a, 0xa0:opc
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, ToneGen_SetSustain_Exit
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
	jrl nz, ToneGen_SetSustain_Exit
	ld a, (4012:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, ToneGen_SetSustain_Exit
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	ld (4323:16), 0

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
	ld (4323:16), 0
	jp VoiceParam_NullRet2
MidiNoteOn_SetupVoiceB:
	ordi8	(4236), 1
	ld	iy, (4237:16)
	extz	xiy
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	push	xiy
	push	xix
	call	SoundGen_ReadVoiceRegs
	pop	xix
	ld	w, (4011:16)
	and	w, 15
	ld	a, 144:opc
	or	a, w
	push	xix
	call	SoundGen_UpdateAndRefresh
	pop	xix
	pop	xiy
	cp	(4323:16), 0
	jrl	nz, VoiceParam_NullRet2
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw	wa, xix, iy
	pop	xix
	srl	xiy, 1
	push	xiy
	push	xix
	call	SoundGen_ScalePitchByTempo
	pop	xix
	pop	xiy
	push	xiy
	push	xix
	call	SoundGen_UpdateAndRefresh
	pop	xix
	pop	xiy
	cp	(4323:16), 0
	jrl	nz, VoiceParam_NullRet2
	cp	(4600:16), 2
	jr	nz, MidiNoteOn_StandardNoteB
	ld	a, (4011:16)
	and	a, 15
	cp	a, 9
	jrl	nz, MidiNoteOn_NonDrumLookupB
	push	xix
	push	xbc
	push	xde
	xor	xhl, xhl
	ld	l, a
	mul	l, 2
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xix, 6711
	ld	a, 4:opc
	ld_rrw	bc, xix, hl
	ld	e, b
	xor	hl, hl
	ld	l, (4012:16)
	pushw	hl
	call	ApplyProgramChangeAs_Block_Code_Sub
	ld	a, l
	pop	xde
	pop	xbc
	pop	xix
	jp	Scoop_ApplySoundParamsAlt
MidiNoteOn_NonDrumLookupB:
	push	xix
	push	xbc
	push	xde
	xor	xhl, xhl
	ld	l, a
	mul	l, 2
	xor	xwa, xwa
	xor	xbc, xbc
	xor	xde, xde
	ld	xix, 6711
	ld_rrw	wa, xix, hl
	ld	c, w
	call	MidiNoteOn_SetupVoiceA_Code_Helper
	ld	a, (4012:16)
	add	a, l
	pop	xde
	pop	xbc
	pop	xix
	jp	Scoop_ApplySoundParamsAlt
MidiNoteOn_StandardNoteB:
	ld a, (4012:16)

Scoop_ApplySoundParamsAlt:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet2
	ld a, (4013:16)
	cp a, 0x7f
	jrl ule, MidiNoteOn_ClampVelocityB
	ld a, 0x7f:opc

MidiNoteOn_ClampVelocityB:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet2
	ld a, (9830:16)
	ld (xix + 2), a
	ld wa, (0x28af:16)
	ld (xix + 3), wa
	xor a, a
	push xiy
	push xix
	pushw wa
	call SoundGen_UpdateAndRefresh
	popw wa
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet2
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet2
	call ToneGen_SetSustainBit
	push xix
	call SoundGen_WriteVoiceParams
	pop xix
	ld a, (4011:16)
	and a, 0xf
	or a, 0x80
	ld (xix), a
	ld a, (4012:16)
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	ld (4323:16), 0

VoiceParam_NullRet2:
	ret

MidiNoteOff_FindActiveVoiceB:
	ld xiy, 0x11f9

MidiNoteOff_ScanActiveB_Loop:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceCheck
	ld a, (xiy)
	and a, 0xf
	ld l, (4011:16)
	and l, 0xf
	cp a, l
	jrl nz, ToneGen_LoopAdvanceCheck
	ld l, (4012:16)
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
	ld l, 0x60:opc
	divs wa, l
	cp a, 0:i3
	jrl nz, Scoop_ApplyMatchedVoiceEntryAlt
	cp w, 4:i3
	jrl ugt, Scoop_ApplyMatchedVoiceEntryAlt
	ld w, 0x5:opc

Scoop_ApplyMatchedVoiceEntryAlt:
	ld xhl, (4349:16)
	stb_dri W, 0x07, 0xec, 0xf0
	pop xhl
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	ld (0x28af:16), hl
	ld (9830:16), ix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	ld ix, (9830:16)
	ld xhl, (4349:16)
	stb_dri A, 0x07, 0xec, 0xf0
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
	ld a, (4012:16)
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


; VoiceParam_ReadUpdate_Table: 16 x 32-bit handler pointers (stride 4),
; the second-set twin of VoiceSynth_Algorithm_Table.  Read by
; VoiceParam_ReadUpdateDispatch (0xF25623): XHL =
; long [this + 4*A], `call (xhl)`, for A = byte at 0x0FAC < 0x10; its
; caller's other cases are the same CC numbers as VoiceSynth_CommandDispatch
; ([INFERENCE] CC 0..15, non-null at 0, 1, 6, 7, 10 and 11 as there).
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
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	push xiy
	call SoundGen_ReadVoiceRegs
	ld w, (4011:16)
	and w, 0xf
	ld a, 0xe0:opc
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet3
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
	jrl nz, VoiceParam_NullRet3
	push xiy
	ld a, (4012:16)
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet3
	push xiy
	ld a, (4013:16)
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullRet3
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	ld (4323:16), 0

VoiceParam_NullRet3:
	ret

MidiEvent_HandleProgramChangeB:
	ld iy, (4011:16)
	and iy, 0xf
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xf
	bit 0, (4236:16)
	jrl nz, MidiPgmChg_CheckModeB
	call VoiceChannel_ApplyParamByMode
	ld (4323:16), 0

MidiPgmChg_CheckModeB:
	cp (4600:16), 0
	jr z, MidiPgmChg_Mode0_SetupB
	cp (4600:16), 2
	jrl z, MidiPgmChg_Mode2_SetupB
	jrl MidiPgmChg_Mode1_SetupB

MidiPgmChg_Mode0_SetupB:
	push	xix
	push	xiy
	ldw_d16	iy, (4011)
	and	iy, 15
	ld	xix, 3970
	ld_rrb	l, xix, iy
	stb_d8	(6743), l
	ld	xix, 3954
	ld_rrb	l, xix, iy
	stb_d8	(6744), l
	ldb_d8	l, (4012)
	stb_d8	(6745), l
	ld	xix, VoiceParam_ChannelMapRemapped
	ld_rrb	l, xix, iy
	pop	xiy
	pop	xix
	stb_d8	(6748), l
	ld	xwa, 6743
	call	16703893
	push	xiy
	push	xhl
	call	SoundGen_ReadVoiceRegs
	pop	xhl
	ld	a, 192:opc
	ldb_d8	w, (6746)
	and	w, 128
	rlc	w
	or	a, w
	ldb_d8	w, (6747)
	and	w, 128
	.byte 0xc8, 0xe8, 0x02	; rlc 0x02,w
	or	a, w
	push	xhl
	call	SoundGen_UpdateAndRefresh
	pop	xhl
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	sla	iy, 1
	push	xix
	ld	xix, 4014
	ld_rrw	wa, xix, iy
	pop	xix
	srl	iy, 1
	push	xhl
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	pop	xhl
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	ldb_d8	a, (4011)
	and	a, 15
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	xor	a, a
	push	xhl
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	pop	xhl
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	ldb_d8	a, (6746)
	and	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	ldb_d8	a, (6747)
	and	a, 127
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_NullReturn
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	stdi8	(4323), 0
	jrl	VoiceParam_NullReturn
MidiPgmChg_Mode2_SetupB:
	push XIX
	push XIY
	ld iy, (0x0fab:16)
	and IY,0x000f
	ld XIX,0x00000f82
	ldb_dri l, 0x07, 0xf0, 0xf4
	ld (0x1a57:16), l
	ld XIX,0x00000f72
	ldb_dri l, 0x07, 0xf0, 0xf4
	ld (0x1a58:16), l
	ld l, (0x0fac:16)
	ld (0x1a59:16), l
	ld XIX,VoiceParam_ChannelMapRemapped
	ldb_dri l, 0x07, 0xf0, 0xf4
	pop XIY
	pop XIX
	ld (0x1a5c:16), l
	call VoiceChannel_StoreVoiceIdx
	ld XWA,0x00001a57
	call MidiPgmChg_Mode0_SetupA_Code_Helper
	cpw (0x1a5f:16), 0x0009
	jr z, MidiPgmChg_Mode2_ApplyEnvelopeB
	ld XHL,0x00001a37
	ld bc, (0x1a5f:16)
	mul C,0x02
	add XHL,XBC
	ld a, (0x1a5a:16)
	ld (XHL),A
	ld a, (0x1a5b:16)
	ld (XHL+0x01),A
MidiPgmChg_Mode2_ApplyEnvelopeB:
	push xiy
	push xhl
	call SoundGen_ReadVoiceRegs
	pop xhl
	ld a, 0xc0:opc
	ld w, (6746:16)
	and w, 0x80
	rlc w
	or a, w
	ld w, (6747:16)
	and w, 0x80
	rlc w, 2
	or a, w
	push xhl
	call SoundGen_UpdateAndRefresh
	pop xhl
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	sla iy, 1
	push xix
	ld xix, 0xfae
	ldw_sri WA, 0x07, 0xf0, 0xf4
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
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	ld a, (4011:16)
	and a, 0xf
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	xor a, a
	push xhl
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	pop xhl
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	ld a, (6746:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	ld a, (6747:16)
	and a, 0x7f
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	ld (4323:16), 0
	jrl VoiceParam_NullReturn

MidiPgmChg_Mode1_SetupB:
	push xiy
	call SoundGen_ReadVoiceRegs
	ld a, 0xc0:opc
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0xf72
	ldb_sri W, 0x07, 0xf0, 0xf4
	pop xix
	and w, 0x1
	or a, w
	pop xiy
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
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
	jrl nz, VoiceParam_NullReturn
	ld a, (4011:16)
	and a, 0xf
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	ld a, 0x0:opc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	ld a, (4012:16)
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	push xix
	push xiy
	ld iy, (4011:16)
	and iy, 0xf
	ld xix, 0xf82
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xiy
	pop xix
	and a, 0x70
	srl a, 4
	call SoundGen_UpdateAndRefresh
	cp (4323:16), 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	ld (4323:16), 0
	jrl VoiceParam_NullReturn

VoiceParam_NullReturn:
	ret

VoiceParam_ChannelMapRemapped:
; 16-byte MIDI-channel map: identity with entries 9 and 15 swapped (a
; third copy of SeqTrack_ChannelMapIdentity +0x10).  Read with
; `ld xix, VoiceParam_ChannelMapRemapped / ld L,(XIX+IY)`, IY = MIDI channel,
; by MidiPgmChg_Mode0_SetupB (0xF25786) and
; MidiPgmChg_Mode2_SetupB (0xF2588A); the result goes to
; the byte at 0x1A5C.  TYPED 2026-09-25 (lane seqeng); was spelled as
; nop / normal / push sr / ... mnemonics.
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x0f, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x09

SoundGen_ReadVoiceRegs:
	push xde
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	sla iy, 1
	ld xde, 0xc9e
	ldw_sri WA, 0x07, 0xe8, 0xf4
	ld (0x28af:16), wa
	srl iy, 1
	ld xde, 0xcbe
	ldb_sri A, 0x07, 0xe8, 0xf4
	xor w, w
	ld (9830:16), wa
	pop xde
	ret

SoundGen_StoreVoiceToTables_Clamped:
	push xix
	cp hl, 1:i3
	jr ule, SoundGen_StoreVoice_AfterClamp
	ld hl, 1:i3

SoundGen_StoreVoice_AfterClamp:
	ld wa, (9830:16)
	ld xix, 0xf218
	stb_dri A, 0x07, 0xf0, 0xec
	sla hl, 1
	ld wa, (0x28af:16)
	ld xix, 0xf1f8
	stw_dri WA, 0x07, 0xf0, 0xec
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
	stiw_ind 0x07, 0xf0, 0xf4, 0xff, 0xff
	ld xix, 0xcbe
	stib_ind 0x07, 0xf0, 0xec, 0x05
	ld xix, 0xf218
	stib_ind 0x07, 0xf0, 0xec, 0x05
	sla hl, 1
	ld xix, 0xc9e
	stiw_ind 0x07, 0xf0, 0xec, 0xff, 0xff
	ld xix, 0xf1f8
	stiw_ind 0x07, 0xf0, 0xec, 0xff, 0xff
	pop xix
	ret

VoiceChannel_CopyParamBlock:
	pushw bc
	push xhl
	push xiz
	ld xiz, (4349:16)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	ld xiy, (4349:16)
	ldw bc, 0x100
	ldir85
	ld iy, (0x28af:16)
	ld wa, 1:i3
	call DispatchHandler_JumpSub
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	pop xhl
	popw bc
	ld iy, 5:i3
	ret

VoiceChannel_UpdateParamSet:
	and (0x27d2:16), 254
	ld iy, (0x27d6:16)
	push xix
	ld xix, 0x17fa
	ldb_sri C, 0x07, 0xf0, 0xf4
	pop xix
	cp c, 0x82
	jr z, VoiceChannel_ParamSet_IsEnd
	cp c, 0x81
	jr nz, VoiceChannel_ParamSet_Validate

VoiceChannel_ParamSet_IsEnd:
	or (0x27d2:16), 1
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
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	ld (0x27dc:16), a
	ld (0x27d6:16), iy

VoiceChannel_ParamSet_Done:
	ret

ToneGen_ValidateVoiceCh2:
	and (0x27d2:16), 253
	ld iy, (0x27da:16)
	push xix
	ld xix, 0x18fa
	ldb_sri B, 0x07, 0xf0, 0xf4
	pop xix
	cp b, 0x82
	jr z, ToneGen_ValidateCh2_IsEnd
	cp b, 0x81
	jr nz, ToneGen_ValidateCh2_Validate

ToneGen_ValidateCh2_IsEnd:
	or (0x27d2:16), 2
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
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	ld (0x27de:16), a
	ld (0x27da:16), iy

ToneGen_ValidateCh2_Done:
	ret

VoiceChannel_FindNextLoop:
	call VoiceChannel_FindNextValid
	bit 0, (0x27d2:16)
	jr z, VoiceChannel_FindNextLoop
	ret

Scoop_HandleEqualCompare:
	cp c, 0x82
	jr nz, Scoop_Equal_AdvanceAndRevalidate
	ld xhl, (4349:16)
	stib_ind 0x07, 0xec, 0xf0, 0x82
	ld (0x27d2:16), 255
	ld wa, (3308:16)
	ld (0x289f:16), wa
	xor wa, wa
	ld a, (9860:16)
	ld (0x287d:16), wa
	call Scoop_AssignVoiceAfterMatch
	jr Scoop_Equal_Done

Scoop_Equal_AdvanceAndRevalidate:
	ld xhl, (4349:16)
	stib_ind 0x07, 0xec, 0xf0, 0x81
	call VoiceChannel_AdvanceIndex
	ld xhl, (4349:16)
	push xix
	ld xix, 0x17fa
	nop
	ld iy, (0x27d6:16)
	call ToneGen_ValidateAndSelectVoice
	ld (0x27d6:16), iy
	call VoiceChannel_UpdateParamSet
	ld (0x27d6:16), iy
	ld xix, 0x18fa
	nop
	ld iy, (0x27da:16)
	call ToneGen_ValidateAndSelectVoice
	ld (0x27da:16), iy
	call ToneGen_ValidateVoiceCh2
	ld (0x27da:16), iy
	pop xix

Scoop_Equal_Done:
	ret

ToneGen_AdvanceVoiceLoop:
	call ToneGen_AdvanceAndValidateVoice
	bit 1, (0x27d2:16)
	jr z, ToneGen_AdvanceVoiceLoop
	ret

VoiceChannel_FindNextValid:
	ld xhl, (4349:16)
	stb_dri C, 0x07, 0xec, 0xf0
	bit 0, (0x27d2:16)
	jr nz, VoiceChannel_ValidateAndLoop
	call VoiceChannel_AdvanceIndex
	ld xhl, (4349:16)
	ld a, (0x27dc:16)
	stb_dri A, 0x07, 0xec, 0xf0

VoiceChannel_ValidateAndLoop:
	push xix
	ld xix, 0x17fa
	nop
	ld iy, (0x27d6:16)
	call ToneGen_ValidateAndSelectVoice
	ld (0x27d6:16), iy
	pop xix
	call VoiceChannel_AdvanceIndex
	ld xhl, (4349:16)
	push xde
	ld xde, 0x17fa
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jr nz, VoiceChannel_FindNext_StoreAndUpdate
	push xde
	ld xde, 0x17fa
	ldb_sri A, 0x07, 0xe8, 0xf4
	pop xde
	stb_dri A, 0x07, 0xec, 0xf0
	jr VoiceChannel_ValidateAndLoop

VoiceChannel_FindNext_StoreAndUpdate:
	ld (0x27d6:16), iy
	call VoiceChannel_UpdateParamSet
	ret

VoiceChannel_ClearParamTable:
	ld xix, 0x1073
	xor wa, wa
	ld bc, 4:i3

VoiceChannel_ClearParam_Loop:
	ld (xix+), WA
	djnz16 bc, VoiceChannel_ClearParam_Loop
	ret

VoiceChannel_AdvancePosition:
	ld iy, (0x27d6:16)
	ld xix, 0x17fa
	inc 1, iy
	cp iy, 0xff
	jr ule, VoiceChannel_StorePosition_Continue
	ld wa, (xix + 3)
	cp wa, 0xffff
	jr nz, VoiceChannel_AdvPos_CheckBounds
	ld (0x287a:16), 2
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_CheckBounds:
	cp wa, (0x286d:16)
	jr ule, VoiceChannel_AdvPos_LoadBlock
	ld (0x287a:16), 10
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_LoadBlock:
	ld (0x28af:16), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, VoiceChannel_AdvPos_CopyBlock
	ld (0x287a:16), 11
	jr VoiceChannel_StorePosition_Continue

VoiceChannel_AdvPos_CopyBlock:
	ld hl, (0x28af:16)
	call ToneGen_CopyBlockToVoiceBuffer
	ld iy, 5:i3

VoiceChannel_StorePosition_Continue:
	ld (0x27d6:16), iy
	ret

ToneGen_WriteParamToBlock:
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld iy, (9830:16)
	and iy, 0xff
	extz xiy
	add xiy, (4349:16)
	ld (xiy), a
	ret

ToneGen_AdvancePosition:
	ld wa, (9830:16)
	cp wa, 0xff
	jr nz, ToneGen_AdvPos_Increment
	cpw (0xf231:16), 0
	jr nz, ToneGen_AdvPos_DispatchLink
	ld (4323:16), 255
	jr ToneGen_AdvPos_Return

ToneGen_AdvPos_DispatchLink:
	call ToneGen_DispatchAndLinkBlock
	jr ToneGen_AdvPos_ClearError

ToneGen_AdvPos_Increment:
	inc 1, wa
	ld (9830:16), wa

ToneGen_AdvPos_ClearError:
	ld (4323:16), 0

ToneGen_AdvPos_Return:
	ret

ToneGen_AdvPosForRefresh:
	ld wa, (9830:16)
	cp wa, 0xff
	jr nz, ToneGen_AdvRefresh_Increment
	cpw (0xf231:16), 0
	jr nz, ToneGen_AdvRefresh_DispatchLink
	ld (4323:16), 255
	jr ToneGen_AdvRefresh_Return

ToneGen_AdvRefresh_DispatchLink:
	call ToneGen_DispatchAndLinkBlock
	jr ToneGen_AdvRefresh_ClearError

ToneGen_AdvRefresh_Increment:
	inc 1, wa
	ld (9830:16), wa

ToneGen_AdvRefresh_ClearError:
	ld (4323:16), 0

ToneGen_AdvRefresh_Return:
	ret

ToneGen_SetSustainBit:
	pushw bc
	ld iy, (4011:16)
	and iy, 0xf
	ld bc, iy
	xor b, b
	ld de, (0x00ffec:24)
	ld a, c
	scf
	stcf_a_16 de
	ld (0x00ffec:24), de
	popw bc
	ret

ToneGen_AdvanceBlockPosition:
	ld wa, (9830:16)
	cp wa, 0xff
	jr nz, ToneGen_AdvBlock_IncrementPos
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	ld (0x28af:16), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld wa, 5:i3
	jr ToneGen_AdvBlock_StorePos

ToneGen_AdvBlock_IncrementPos:
	inc 1, wa

ToneGen_AdvBlock_StorePos:
	ld (9830:16), wa
	ret

VoiceSynth_HandleBankSelect:
	ld iy, (4011:16)
	and iy, 0xf
	extz xiy
	ld a, (4013:16)
	push xix
	ld xix, 0xf82
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix
	ret

VoiceSynth_HandleDataEntry:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ldb_sri L, 0x07, 0xf0, 0xf4
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
	ld a, (4013:16)
	xor b, b
	ld ix, bc
	extz xix
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ldb_sri E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceSynth_DataEntry_CheckSpec
	ld a, e

VoiceSynth_DataEntry_CheckSpec:
	cp c, 1:i3
	jr nz, VoiceSynth_DataEntry_Done
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	stb_dri A, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceSynth_DataEntry_Done:
	ret

VoiceSynth_DataEntry_PtrTable:
; Three 32-bit pointers to 16-byte per-channel RAM arrays (0x1A1B, 0x19FB,
; 0x1A0B), selected by the per-channel parameter index 0..2 kept in the byte
; array at 0x10B3 (0xFF = none selected).  Read by VoiceSynth_HandleDataEntry
; (0xF25E22), VoiceChannel_SelectNextParam
; (0xF25F0A) and VoiceChannel_SelectPrevParam
; (0xF25F62): XHL = long [this + 4*index], then the
; array element (XHL+IY), IY = channel, is written with the data byte
; clamped to VoiceChannel_ParamLimitTable[index].  Stride 4, 3 entries
; (index <= 2 is enforced where 0x10B3 is written).
; [INFERENCE] the three are the GM registered parameters 0/1/2 (pitch-bend
; sensitivity, fine tune, coarse tune): the dispatcher that reaches
; VoiceSynth_HandleDataEntry compares the same byte against the CC numbers
; of data entry, data inc/dec and (N)RPN select, and entry 0 is limited to
; 12 (one octave of bend range).  Not confirmed against a manual.
	.long 0x00001a1b
	.long 0x000019fb
	.long 0x00001a0b

VoiceSynth_HandlePan:
	bit 0, (4236:16)
	jr nz, VoiceSynth_Pan_SetDirection
	call VoiceChannel_SetPanDirection
	ld (4323:16), 0

VoiceSynth_Pan_SetDirection:
	ld (4233:16), 4
	xor a, a
	cp (4013:16), 64
	jr c, VoiceSynth_Pan_StoreAndUpdate
	or a, 0x8

VoiceSynth_Pan_StoreAndUpdate:
	ld (4234:16), a
	ld (4235:16), 8
	call VoiceChannel_UpdateWithPitch
	ret

VoiceSynth_HandleNop42:
	ret

VoiceSynth_HandleNop43:
	ret

VoiceSynth_HandleReverb:
	bit 0, (4236:16)
	jr nz, VoiceSynth_Reverb_SetParams
	call VoiceChannel_SetParamByte7
	ld (4323:16), 0

VoiceSynth_Reverb_SetParams:
	ld (4233:16), 7
	ld a, (4013:16)
	ld (4234:16), a
	ld (4235:16), 127
	call VoiceChannel_UpdateWithPitch
	ret

VoiceSynth_HandleChorus:
	bit 0, (4236:16)
	jr nz, VoiceSynth_Chorus_SetParams
	call VoiceChannel_MergeParamByte5
	ld (4323:16), 0

VoiceSynth_Chorus_SetParams:
	ld (4233:16), 5
	ld a, (4013:16)
	ld (4234:16), a
	ld (4235:16), 127
	call VoiceChannel_UpdateWithPitch
	ret

VoiceChannel_SelectNextParam:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ldb_sri A, 0x07, 0xf0, 0xf4
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
	ldb_sri A, 0x07, 0xec, 0xf4
	inc 1, a
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ldb_sri E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceChannel_NextParam_Clamped
	ld a, e

VoiceChannel_NextParam_Clamped:
	stb_dri A, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceChannel_NextParam_Done:
	ret

VoiceChannel_ParamLimitTable:
; Upper limits (12, 127, 255) for the three per-channel parameters of
; VoiceSynth_DataEntry_PtrTable, same index.  Read by
; VoiceSynth_HandleDataEntry / VoiceChannel_SelectNextParam /
; VoiceChannel_SelectPrevParam as `ld xiy, VoiceChannel_ParamLimitTable /
; ld E,(XIY+IX)`, IX = index; a value above E is replaced by E.
	.byte 0x0c, 0x7f, 0xff

VoiceChannel_SelectPrevParam:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ldb_sri A, 0x07, 0xf0, 0xf4
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
	ldb_sri A, 0x07, 0xec, 0xf4
	cp a, 0:i3
	jr z, VoiceChannel_PrevParam_AtZero
	dec 1, a

VoiceChannel_PrevParam_AtZero:
	stb_dri A, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceChannel_PrevParam_Done:
	ret

VoiceChannel_ClearChannelFlags:
	ld c, (4011:16)
	and c, 0xf
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (4239:16)
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3c
	ld (4239:16), de
	ldto_werp DE, 0x3e
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (4241:16)
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3c
	ld (4241:16), de
	ldto_werp DE, 0x3e
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_ind 0x07, 0xf0, 0xf4, 0xff
	pop xix
	ret

VoiceChannel_NoteOnByChannel:
	ld iy, (4011:16)
	and iy, 0xf
	ld a, (4013:16)
	push xix
	ld xix, 0x1093
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0x7f
	jr z, VoiceChannel_NoteOn_ClearSlot
	ld c, (4011:16)
	and c, 0xf
	ld wa, (4239:16)
	and wa, (4241:16)
	ldfr_werp WA, 0x3e
	ld a, c
	scf
	xorcfw_erp 0x3e
	jr nc, VoiceChannel_NoteOn_LookupBank
	ld de, (4239:16)
	ld a, c
	scf
	stcf_a_16 de
	ld (4239:16), de
	ld de, (4241:16)
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
	ld c, (4011:16)
	and c, 0xf
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_ind 0x07, 0xf0, 0xf4, 0xff
	xor c, c
	ld xix, 0x10c3
	stb_dri C, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	stb_dri C, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_NoteOn_Done:
	ret

VoiceChannel_NoteOffByChannel:
	ld iy, (4011:16)
	and iy, 0xf
	ld a, (4013:16)
	push xix
	ld xix, 0x10a3
	stb_dri A, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0x7f
	jr z, VoiceChannel_NoteOff_ClearSlot
	ld c, (4011:16)
	and c, 0xf
	ld wa, (4239:16)
	and wa, (4241:16)
	ldfr_werp WA, 0x3e
	ld a, c
	scf
	xorcfw_erp 0x3e
	jr nc, VoiceChannel_NoteOff_LookupBank
	ld de, (4241:16)
	ld a, c
	scf
	stcf_a_16 de
	ld (4241:16), de
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (4239:16)
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
	ld c, (4011:16)
	and c, 0xf
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10b3
	stib_ind 0x07, 0xf0, 0xf4, 0xff
	xor c, c
	ld xix, 0x10c3
	stb_dri C, 0x07, 0xf0, 0xf4
	ld xix, 0x10d3
	stb_dri C, 0x07, 0xf0, 0xf4
	pop xix

VoiceChannel_NoteOff_Done:
	ret

VoiceChannel_ApplyParamByMode:
	push xiy
	call VoiceChannel_GetParamBlock
	cp (4600:16), 0
	jr z, VoiceParam_ByMode_Mode0
	cp (4600:16), 2
	jrl z, VoiceParam_ByMode_Mode2
	jrl VoiceParam_ByMode_Mode1

VoiceParam_ByMode_Mode0:
	push	xix
	push	xde
	xor	de, de
	ld	e, (4011:16)
	and	e, 15
	ld	xix, 3970
	ld_rrb	l, xix, de
	ld	(6743:16), l
	ld	xix, 3954
	ld_rrb	l, xix, de
	ld	(6744:16), l
	ld	l, (4012:16)
	ld	(6745:16), l
	ld	xix, SeqTrack_ChannelMapIdentity_0x10
	ld_rrb	l, xix, de
	ld	(6748:16), l
	pop	xde
	pop	xix
	push	xiy
	ld	xwa, 6743
	call	16703893
	pop	xiy
	ld	l, (6746:16)
	ld	h, (6747:16)
	ld	(xiy+0:8), l
	ld	(xiy+1), h
	jrl	VoiceParam_ByMode_StoreAndReturn	; -> 0xF2624C
VoiceParam_ByMode_Mode2:
	push XIX
	push XDE
	xor DE,DE
	ld e, (0x0fab:16)
	and E,0x0f
	ld XIX,0x00000f82
	ldb_dri l, 0x07, 0xf0, 0xe8
	ld (0x1a57:16), l
	ld XIX,0x00000f72
	ldb_dri l, 0x07, 0xf0, 0xe8
	ld (0x1a58:16), l
	ld l, (0x0fac:16)
	ld (0x1a59:16), l
	ld XIX,SeqTrack_ChannelMapIdentity_0x10
	ldb_dri l, 0x07, 0xf0, 0xe8
	ld (0x1a5c:16), l
	pop XDE
	pop XIX
	push XIY
	call VoiceChannel_StoreVoiceIdx
	ld XWA,0x00001a57
	call MidiPgmChg_Mode0_SetupA_Code_Helper
	cpw (0x1a5f:16), 0x0009
	jr z, VoiceParam_ByMode_Mode2_Apply
	ld XHL,0x00001a37
	ld bc, (0x1a5f:16)
	mul C,0x02
	add XHL,XBC
	ld a, (0x1a5a:16)
	ld (XHL),A
	ld a, (0x1a5b:16)
	ld (XHL+0x01),A
VoiceParam_ByMode_Mode2_Apply:
	pop xiy
	ld l, (6746:16)
	ld h, (6747:16)
	ld (xiy + 0:8), l
	ld (xiy + 1), h
	jr VoiceParam_ByMode_StoreAndReturn

VoiceParam_ByMode_Mode1:
	ld a, (4012:16)
	xor hl, hl
	ld l, (4011:16)
	and l, 0xf
	push xix
	ld xix, 0xf72
	ldb_sri C, 0x07, 0xf0, 0xec
	pop xix
	and c, 0x1
	rrc c
	and a, 0x7f
	or a, c
	ld (xiy + 0:8), a
	xor h, h
	ld l, (4011:16)
	and l, 0xf
	push xix
	ld xix, 0xf82
	ldb_sri C, 0x07, 0xf0, 0xec
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
	ld iy, (4237:16)
	call SoundGen_ClampVoiceIndexMin1
	ld wa, (0x28af:16)
	sla xiy, 1
	ld xde, 0xc9e
	stw_dri WA, 0x07, 0xe8, 0xf4
	ld wa, (9830:16)
	srl xiy, 1
	ld xde, 0xcbe
	stb_dri A, 0x07, 0xe8, 0xf4
	pop xde
	ret

VoiceParam_HandleBankSelect:
	ld iy, (4011:16)
	and iy, 0xf
	ld a, (4013:16)
	push xde
	ld xde, 0xf82
	stb_dri A, 0x07, 0xe8, 0xf4
	pop xde
	ret

VoiceParam_HandleDataEntry:
	ld iy, (4011:16)
	and iy, 0xf
	push xix
	ld xix, 0x10b3
	ldb_sri L, 0x07, 0xf0, 0xf4
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
	ld a, (4013:16)
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, VoiceChannel_ParamLimitTable
	ldb_sri E, 0x07, 0xf4, 0xf0
	pop xiy
	cp a, e
	jr ule, VoiceParam_DataEntry_CheckSpec
	ld a, e

VoiceParam_DataEntry_CheckSpec:
	cp c, 1:i3
	jr nz, VoiceParam_DataEntry_Done
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	stb_dri A, 0x07, 0xec, 0xf4
	call VoiceChannel_LookupParams

VoiceParam_DataEntry_Done:
	ret

VoiceParam_HandlePan:
	bit 0, (4236:16)
	jr nz, VoiceParam_Pan_SetDirection
	call VoiceChannel_SetPanDirection
	ld (4323:16), 0

VoiceParam_Pan_SetDirection:
	ld (4233:16), 4
	xor a, a
	cp (4013:16), 64
	jr c, VoiceParam_Pan_StoreAndUpdate
	ld a, 0x8:opc

VoiceParam_Pan_StoreAndUpdate:
	ld (4234:16), a
	ld (4235:16), 8
	call SoundGen_ClampUpdateVoice
	ret

VoiceParam_HandleReverb:
	bit 0, (4236:16)
	jr nz, VoiceParam_Reverb_SetParams
	call VoiceChannel_SetParamByte7
	ld (4323:16), 0

VoiceParam_Reverb_SetParams:
	ld (4233:16), 7
	ld a, (4013:16)
	ld (4234:16), a
	ld (4235:16), 127
	call SoundGen_ClampUpdateVoice
	ret

VoiceParam_HandleChorus:
	bit 0, (4236:16)
	jr nz, VoiceParam_Chorus_SetParams
	call VoiceChannel_MergeParamByte5
	ld (4323:16), 0

VoiceParam_Chorus_SetParams:
	ld (4233:16), 5
	ld a, (4013:16)
	ld (4234:16), a
	ld (4235:16), 127
	call SoundGen_ClampUpdateVoice
	ret

ToneGen_AdvanceAndValidateVoice:
	ld xhl, (4349:16)
	stb_dri B, 0x07, 0xec, 0xf0
	bit 1, (0x27d2:16)
	jr nz, ToneGen_ValidateVoiceLoop
	call VoiceChannel_AdvanceIndex
	ld xhl, (4349:16)
	ld a, (0x27de:16)
	stb_dri A, 0x07, 0xec, 0xf0

ToneGen_ValidateVoiceLoop:
	push xix
	ld xix, 0x18fa
	nop
	ld iy, (0x27da:16)
	call ToneGen_ValidateAndSelectVoice
	ld (0x27da:16), iy
	pop xix
	call VoiceChannel_AdvanceIndex
	ld xhl, (4349:16)
	push xix
	ld xix, 0x18fa
	bit_dri 7, 0x07, 0xf0, 0xf4
	pop xix
	jr nz, ToneGen_AdvValidate_StoreAndDone
	push xix
	ld xix, 0x18fa
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	stb_dri A, 0x07, 0xec, 0xf0
	jr ToneGen_ValidateVoiceLoop

ToneGen_AdvValidate_StoreAndDone:
	ld (0x27da:16), iy
	call ToneGen_ValidateVoiceCh2
	ret

VoiceSynth_Algo_SimpleStore:
	ld	iy, (4011:16)
	and	iy, 15
	ldb_d8	a, (4013)
	push	xix
	ld	xix, 3954
	st_rrb	a, xix, iy
	pop	xix
	ret
VoiceSynth_Algo_MultiPath:
	ld	iy, (4011:16)
	and	iy, 15
	push	xiy
	call	SoundGen_CaptureVoiceParams
	ld	a, 209:opc
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiPath_Return
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiPath_Return
	ld	a, (4013:16)
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiPath_Return
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	ld	(4323:16), 0
VoiceSynth_Algo_MultiPath_Return:
	ret
VoiceSynth_Algo_Null:
	ret
VoiceSynth_Algo_ChannelConfig:
	ld	iy, (4011:16)
	and	iy, 15
	push	xix
	ld	xix, 4275
	ld_rrb	l, xix, iy
	pop	xix
	cp	l, 255
	jr	z, VoiceSynth_Algo_ChannelConfig_Return
	ld	c, l
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, VoiceSynth_DataEntry_PtrTable
	ld_rrl	xhl, xix, hl
	pop	xix
	ld	a, (4013:16)
	xor	b, b
	ld	ix, bc
	push	xiy
	ld	xiy, VoiceChannel_ParamLimitTable
	ld_rrb	e, xiy, ix
	pop	xiy
	cp	a, e
	jr	ule, VoiceSynth_Algo_ChannelConfig_Skip
	ld	a, e
VoiceSynth_Algo_ChannelConfig_Skip:
	cp	c, 1:i3
	jr	nz, VoiceSynth_Algo_ChannelConfig_Skip2
	push	xhl
	push	xiy
	call	VoiceChannel_GetCombinedStatus
	pop	xiy
	pop	xhl
VoiceSynth_Algo_ChannelConfig_Skip2:
	st_rrb	a, xhl, iy
	call	VoiceChannel_LookupParams
VoiceSynth_Algo_ChannelConfig_Return:
	ret
VoiceSynth_Algo_ConditionalUpdate:
	; --- Main routine: bit test, store, conditional call (49 bytes) ---
	bit	0, (4236:16)
	jr nz, VoiceSynth_ConditionalUpdate_SetParams
	call VoiceChannel_SetRecordField3
	ld	(4323:16), 0
VoiceSynth_ConditionalUpdate_SetParams:
	ld	(4233:16), 3
	ld	a, (4013:16)
	cp	(4600:16), 2
	jr nz, VoiceSynth_ConditionalUpdate_StoreAndCall
	call VoiceSynth_ConditionalUpdate_Helper
VoiceSynth_ConditionalUpdate_StoreAndCall:
	ld	(4234:16), a
	ld	(4235:16), 127
	call VoiceChannel_UpdateWithPitch
	ret
VoiceSynth_ConditionalUpdate_Helper:
	call	16704068
	ld	a, l
	ret
VoiceSynth_Algo_MultiStage:
	ld	iy, (4011:16)
	and	iy, 15
	extz	xiy
	call	SoundGen_CaptureVoiceParams
	push	xiy
	ld	a, 176:opc
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceSynth_Algo_MultiStage_Return
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiStage_Return
	ld	l, (4011:16)
	and	l, 15
	xor	h, h
	extz	xhl
	push	xix
	ld	xix, SeqTrack_ChannelMapIdentity
	ld_rrb	a, xix, hl
	cpdi8	(4600), 1
	jr	z, VoiceSynth_Algo_MultiStage_Skip
	ld	xix, SeqTrack_ChannelMapIdentity_0x10
	ld_rrb a, xix, hl
VoiceSynth_Algo_MultiStage_Skip:
	pop xix
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiStage_Return
	ld	a, 8:opc
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiStage_Return
	ld	a, (4013:16)
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiStage_Return
	ld	a, 127:opc
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_MultiStage_Return
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	ld	(4323:16), 0
VoiceSynth_Algo_MultiStage_Return:
	ret
VoiceSynth_Algo_PitchModulated:
	ld	iy, (4011:16)
	and	iy, 15
	extz	xiy
	push	xiy
	call	SoundGen_CaptureVoiceParams
	ld	a, 211:opc
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchModulated_Return
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchModulated_Return
	ld	a, (4013:16)
	cpdi8	(4600), 2
	jr	nz, VoiceSynth_Algo_PitchModulated_Skip
	call	VoiceSynth_ConditionalUpdate_Helper
VoiceSynth_Algo_PitchModulated_Skip:
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchModulated_Return
	call	ToneGen_SetSustainBit
	call	ToneGen_WriteChannelRegs
	ld	(4323:16), 0
VoiceSynth_Algo_PitchModulated_Return:
	ret
VoiceSynth_Algo_DirectStore:
	ld	iy, (4011:16)
	and	iy, 15
	ldb_d8	a, (4013)
	push	xix
	ld	xix, 3954
	st_rrb	a, xix, iy
	pop	xix
	ret
VoiceSynth_Algo_PitchShift:
	ld	iy, (4237:16)
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	push	xiy
	call	SoundGen_ReadVoiceRegs
	ld	w, (4011:16)
	and	w, 15
	ld	a, 208:opc
	or	a, w
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchShift_Return
	sla	iy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	iy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchShift_Return
	push	xiy
	ld	a, (4013:16)
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jr	nz, VoiceSynth_Algo_PitchShift_Return
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	ld	(4323:16), 0
VoiceSynth_Algo_PitchShift_Return:
	ret
VoiceParam_ReadUpdate_6:
	ld	iy, (4011:16)
	and	iy, 15
	push	xix
	ld	xix, 4275
	ld_rrb	l, xix, iy
	pop	xix
	cp	l, 255
	jr	z, VoiceParam_ReadUpdate_6_Return
	ld	c, l
	xor	h, h
	sla	hl, 2
	push	xix
	ld	xix, VoiceSynth_DataEntry_PtrTable
	ld_rrl	xhl, xix, hl
	pop	xix
	ld	a, (4013:16)
	xor	b, b
	ld	ix, bc
	push	xiy
	ld	xiy, VoiceChannel_ParamLimitTable
	ld_rrb	e, xiy, ix
	pop	xiy
	cp	a, e
	jr	ule, VoiceParam_ReadUpdate_6_Skip
	ld	a, e
VoiceParam_ReadUpdate_6_Skip:
	cp	c, 1:i3
	jr	nz, VoiceParam_ReadUpdate_6_Skip2
	push	xhl
	pushw	iy
	call	VoiceChannel_GetCombinedStatus
	popw	iy
	pop	xhl
VoiceParam_ReadUpdate_6_Skip2:
	st_rrb	a, xhl, iy
	call	VoiceChannel_LookupParams
VoiceParam_ReadUpdate_6_Return:
	ret
VoiceParam_ReadUpdate_7:
	bitda	0, (4236)
	jr	nz, VoiceParam_ReadUpdate_7_Skip
	call	VoiceChannel_SetRecordField3
	ld	(4323:16), 0
VoiceParam_ReadUpdate_7_Skip:
	ld	(4233:16), 3
	ld	a, (4013:16)
	cpdi8	(4600), 2
	jr	nz, VoiceParam_ReadUpdate_7_Skip2
	call	VoiceSynth_ConditionalUpdate_Helper
VoiceParam_ReadUpdate_7_Skip2:
	ld	(4234:16), a
	ld	(4235:16), 127
	call	SoundGen_ClampUpdateVoice
	ret
VoiceParam_ReadUpdate_10:
	ld	iy, (4237:16)
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	call	SoundGen_ReadVoiceRegs
	push	xiy
	ld	a, 176:opc
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	sla	iy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	iy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	ld	a, (4011:16)
	and	a, 15
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	ld	a, 8:opc
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	ld	a, (4013:16)
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	ld	a, 127:opc
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_10_Return
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	ld	(4323:16), 0
VoiceParam_ReadUpdate_10_Return:
	ret
VoiceParam_ReadUpdate_11:
	ld	iy, (4237:16)
	call	SoundGen_ClampVoiceIndexMin1
	and	iy, 15
	push	xiy
	call	SoundGen_ReadVoiceRegs
	ld	w, (4011:16)
	and	w, 15
	ld	a, 240:opc
	or	a, w
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_11_Return
	sla	xiy, 1
	push	xix
	ld	xix, 4014
	ld_rrw wa, xix, iy
	pop xix
	srl	xiy, 1
	push	xiy
	call	SoundGen_ScalePitchByTempo
	pop	xiy
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_11_Return
	ld	a, (4013:16)
	cpdi8	(4600), 2
	jr	nz, VoiceParam_ReadUpdate_11_Skip
	call	VoiceSynth_ConditionalUpdate_Helper
VoiceParam_ReadUpdate_11_Skip:
	push	xiy
	call	SoundGen_UpdateAndRefresh
	pop	xiy
	cpdi8	(4323), 0
	jrl	nz, VoiceParam_ReadUpdate_11_Return
	call	ToneGen_SetSustainBit
	call	SoundGen_WriteVoiceParams
	ld	(4323:16), 0
VoiceParam_ReadUpdate_11_Return:
	ret

ToneGen_ValidateAndSelectVoice:
	push xiz
	ld xiz, (4349:16)
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
	ld (0x287a:16), 2
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_CheckBounds:
	cp wa, (0x286d:16)
	jr ule, ToneGen_ValidateVoice_LoadBlock
	ld (0x287a:16), 10
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_LoadBlock:
	ld (0x28af:16), wa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, ToneGen_ValidateVoice_CopyParams
	ld (0x287a:16), 11
	jr ToneGen_SaveVoiceState_Continue

ToneGen_ValidateVoice_CopyParams:
	call VoiceChannel_CopyParamBlock

ToneGen_SaveVoiceState_Continue:
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	ret

Scoop_AssignVoiceAfterMatch:
	push xiy
	push xiz
	ld xiz, (4349:16)
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	ld hl, (0x287d:16)
	dec 1, hl
	ld wa, ix
	ld xiy, 0xf218
	stb_dri A, 0x07, 0xf4, 0xec
	sla hl, 1
	ld wa, (0x289f:16)
	ld xiy, 0xf1f8
	stw_dri WA, 0x07, 0xf4, 0xec
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	ld (4349:16), xiz
	pop xiz
	pop xiy
	ret

VoiceChannel_AdvanceIndex:

