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
	stda16 61854, xwa
	st16_24 0x00ffec, xwa
	stdi16 61852, 0
	cpdi16 6699, 49
	jrl z, SeqPlay_ReadyStateTransition
	stdi16 6699, 31
	jrl SeqPlay_ReadyStateTransition

SeqPlay_ResetAndStop:
	call FloppyIO_ReturnReady
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 61854, xwa
	st16_24 0x00ffec, xwa
	stdi16 61852, 0
	push xhl
	ldda32 xhl, 6701
	stda16 6699, xhl
	pop xhl
	jrl SeqPlay_ReadyStateTransition

LABEL_F2366B:
	stdi16 6699, 48

SeqPlay_FloppyReady:
	call FloppyIO_ReturnReady
	jrl SeqPlay_ReadyStateTransition

SeqPlay_FinishFloppyLoadAndStart:
	call VoiceChannels_LoadPartMapAndInitPan
	stdi16 6699, 1
	call LABEL_F23E38
	call BitMapOut_RenderDisplay
	ld16_24 xwa, 0x00ffec
	stda16 61854, xwa
	anddi8 10407, 247
	call SeqPlay_CheckStartConditions
	call LABEL_F23E45
	stdi16 61852, 0
	call Audio_CheckSubsystemReady

SeqPlay_ReadyStateTransition:
	call SeqStep_PlaybackNop
	ret

LABEL_F236AF:	.ascii "MThdMTrk"

LABEL_F236B7:
	ldw wa, 0xFFFF
	ld xix, 0x10B3
	ldw bc, 0x8

LABEL_F236C2:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F236C2
	xor wa, wa
	ldw bc, 0x28

LABEL_F236CD:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F236CD
	ret

SeqTrack_ScanActiveChannels:
	ld xhl, 0x11F9
	xor iy, iy
	xor a, a

LABEL_F236DD:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	add iy, 0x7
	cp iy, 0xE0
	jrl ule, LABEL_F236DD
	ret

SeqTrack_ClearPlaybackBuffers:
	push xwa
	push xbc
	push xix
	xor wa, wa
	ld xix, 0xF72
	ldw bc, 0x8

LABEL_F236FB:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F236FB
	ld xix, 0xF82
	ldw bc, 0x8

LABEL_F23709:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F23709
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
	ld_spib A, 0xF0
	cp xix, 0x17F9
	jrl ule, LABEL_F23752
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
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	cps de, 0
	jrl nz, LABEL_F2374A

LABEL_F2374A:
	popw de
	pop xhl
	popw wa
	ld xix, 0x13FA

LABEL_F23752:
	stda32 4376, xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6883
	cp xwa, xbc
	jp_24 z, 0xF23771
	cpdi8 6887, 1
	jp_24 z, 0xF23771
	dec 1, xwa

LABEL_F23771:
	stda32 6883, xwa
	pop xbc
	pop xwa
	pop xix
	ret

LABEL_F23779:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ldw bc, 0x10
	ld xix, 0xFAE

LABEL_F23786:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F23786
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
	jr z, LABEL_F237B3
	cpdi8 4600, 1
	jr z, LABEL_F237AD
	ldb a, 0x2
	jp LABEL_F237B5

LABEL_F237AD:
	ldb a, 0x0
	jp LABEL_F237B5

LABEL_F237B3:
	ldb a, 0x1

LABEL_F237B5:
	call LABEL_FD857A
	pop xiz
	pop xiy
	pop xix
	pop xde
	pop xbc
	pop xhl
	pop xwa
	ret

LABEL_F237C1:
	.byte 0x96, 0xf4, 0x00, 0x00, 0xb0, 0xf4, 0x00, 0x00
	.byte 0xca, 0xf4, 0x00, 0x00, 0xe4, 0xf4, 0x00, 0x00
	.byte 0xfe, 0xf4, 0x00, 0x00, 0x18, 0xf5, 0x00, 0x00
	.byte 0x32, 0xf5, 0x00, 0x00, 0x4c, 0xf5, 0x00, 0x00
	.byte 0x66, 0xf5, 0x00, 0x00, 0x80, 0xf5, 0x00, 0x00
	.byte 0x9a, 0xf5, 0x00, 0x00, 0xb4, 0xf5, 0x00, 0x00
	.byte 0xce, 0xf5, 0x00, 0x00, 0xe8, 0xf5, 0x00, 0x00
	.byte 0x02, 0xf6, 0x00, 0x00, 0x1c, 0xf6, 0x00, 0x00

FloppyIO_ConfigureSwitchboard:
	cpdi8 4600, 0
	jrl z, LABEL_F23818
	ldb c, 0x0
	anddi8 64941, 251
	stdi8 62013, 0
	jrl LABEL_F23827

LABEL_F23818:
	or a, 0x4
	ldb c, 0xFF
	ordi8 64941, 4
	stdi8 62013, 255

LABEL_F23827:
	call LABEL_F23E71
	stdi8 4330, 1
	ldb e, 0x91
	ldb d, 0x3
	ldb w, 0x4
	xor a, a
	cpdi8 4600, 0
	jrl nz, LABEL_F2384C
	ldb a, 0x4
	push xhl
	ld xhl, 0xF73D
	andmi8 (xhl), 0xF8
	pop xhl

LABEL_F2384C:
	call SwbtWr_QueueMainEvent
	call SwbtWr_ReinitBothBanks
	ret

LABEL_F23855:
	call SeqPlay_CheckStartConditions
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 61854, xwa
	st16_24 0x00ffec, xwa
	stda16 4237, xwa

LABEL_F2386C:
	stdi8 4009, 0
	call LABEL_F23E8D
	call SeqTrack_ScanActiveChannels
	call LABEL_F23F13
	call SeqTrack_ClearPlaybackBuffers
	call LABEL_F23F2A
	cpdi8 3830, 0
	jrl z, LABEL_F23894
	call FloppyIO_ReturnReady
	jrl SeqPlay_CheckLoadStatus

LABEL_F23894:
	call LABEL_F24112
	incdi16 1, 4237
	ldda16 xwa, 4237
	cpda16 xwa, 3934
	jrl c, LABEL_F2386C
	call FloppyIO_ReturnReady
	cpdi8 3830, 0
	jrl nz, SeqPlay_CheckLoadStatus
	call LABEL_F24137
	cpdi8 3830, 0
	jrl nz, SeqPlay_CheckLoadStatus
	call VoiceChannels_LoadPartMapAndInitPan

SeqPlay_CheckLoadStatus:
	ret

SeqTrack_AssignFloppyChannels:
	xor iy, iy
	xor ix, ix
	stdi8 5113, 0

LABEL_F238CD:
	cpdi16 62001, 16
	jrl c, SeqTrack_ErrorMark
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ldda16 xbc, 10349
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
	ldw (xhl + 3), 0xFFFF
	popw wa
	ld xhl, 0xF250
	or_srib_im 0x07, 0xEC, 0xF4, 0x80
	push xhl
	st_dri3b C, 0x07, 0xEC, 0xF4
	ldfr_lerp XHL, 0x38
	pop xhl
	st_dri3w WA, 0x39, 0x01, 0x00
	ld xhl, 0xC9E
	st_dri3w WA, 0x07, 0xEC, 0xF0
	ld xhl, 0xCBE
	xor bc, bc
	ldda8 c, 5113
	push xiy
	ld iy, bc
	stiw_dri 0x07, 0xEC, 0xF4, 0x05, 0x00
	pop xiy
	add iy, 0x3
	add ix, 0x2
	incdi8 1, 5113
	cpdi8 5113, 16
	jrl c, LABEL_F238CD
	jrl LABEL_F23962

SeqTrack_ErrorMark:
	stdi8 3830, 255
	stdi8 4323, 255

LABEL_F23962:
	ret

FloppyIO_ReadToTrackBuffer:
	ld xix, 0x106E

LABEL_F23968:
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23980
	pop xbc
	pop xwa
	jp LABEL_F23986

LABEL_F23980:
	pop xbc
	pop xwa
	jp LABEL_F23995

LABEL_F23986:
	lda_dpi XBC, 0xF0
	bit 7, a
	jrl nz, LABEL_F23968
	sub xix, 0x106E

LABEL_F23995:
	ret

SeqTrack_DispatchPartEvt:
	call LABEL_F24391
	cps ix, 1
	jrl z, LABEL_F239A7
	cps ix, 2
	jrl z, LABEL_F239B5
	jrl LABEL_F239DB

LABEL_F239A7:
	ldda8 a, 4206
	and a, 0x7F
	stda8 4211, a
	jrl LABEL_F23A16

LABEL_F239B5:
	ldda8 a, 4206
	and a, 0x7F
	rrc a
	ld w, a
	and a, 0x7F
	and w, 0x80
	ldda8 l, 4207
	and l, 0x7F
	or l, w
	stda8 4212, a
	stda8 4211, l
	jrl LABEL_F23A16

LABEL_F239DB:
	ldda8 a, 4206
	and a, 0x7F
	rrc_i_8 a, 2
	ld w, a
	and a, 0x3F
	and w, 0xC0
	ldda8 l, 4207
	and l, 0x7F
	rrc l
	ld h, l
	and l, 0x7F
	and h, 0x80
	or l, w
	ldda8 c, 4208
	and c, 0x7F
	or c, h
	stda8 4213, a
	stda8 4212, l
	stda8 4211, c

LABEL_F23A16:
	ret

SeqTrack_ComputeTempoScaling:
	stdi16 3946, 0
	sla iy, 1
	push xix
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	pop xix
	srl iy, 1
	ldda16 xbc, 4211
	ldda8 e, 4213
	xor d, d
	cps de, 0
	jrl z, LABEL_F23AE7
	pushw wa
	xor wa, wa
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	adddm16 3946, xwa
	popw wa
	ldi_werp 0xEA, 0
	ldi_werp 0xE6, 0
	add xde, xbc
	cpi_werp 0xEA, 0
	jrl ule, LABEL_F23A76
	pushw wa
	ld wa, de
	lds de, 1
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	adddm16 3946, xwa
	popw wa

LABEL_F23A76:
	ldi_werp 0xE2, 0
	ldi_werp 0xEA, 0
	add xwa, xde
	cpi_werp 0xE2, 0
	jrl ule, LABEL_F23AB1
	lds de, 1
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
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
	ld xix, 0xFAE
	st_dri3w DE, 0x07, 0xF0, 0xF4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

LABEL_F23AB1:
	cpda16 xwa, 3936
	jrl c, LABEL_F23AC8
	xor de, de
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	adddm16 3946, xwa
	ld wa, de

LABEL_F23AC8:
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	sla xiy, 1
	push xix
	ld xix, 0xFAE
	st_dri3w WA, 0x07, 0xF0, 0xF4
	pop xix
	srl xiy, 1
	jrl SeqTrack_UpdateVolumesExit

LABEL_F23AE7:
	ldi_werp 0xE2, 0
	ldi_werp 0xE6, 0
	add xwa, xbc
	cpi_werp 0xE2, 0
	jrl ule, LABEL_F23B20
	lds de, 1
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	adddm16 3946, xwa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	push xix
	ld xix, 0xFAE
	st_dri3w DE, 0x07, 0xF0, 0xF4
	pop xix
	jrl SeqTrack_UpdateVolumesExit

LABEL_F23B20:
	ldda16 xhl, 3936
	cp wa, hl
	jrl c, LABEL_F23B43
	xor de, de
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	adddm16 3946, xwa
	pushw wa
	pushw de
	push xiy
	call SoundGen_RefreshAllVoices
	pop xiy
	popw de
	popw wa
	ld wa, de

LABEL_F23B43:
	sla iy, 1
	push xix
	ld xix, 0xFAE
	st_dri3w WA, 0x07, 0xF0, 0xF4
	pop xix
	srl iy, 1

SeqTrack_UpdateVolumesExit:
	ret

SeqTrack_UpdateChannelVolumes:
	xor xiy, xiy

LABEL_F23B58:
	push xix
	ld xix, 0x11F9
	bit_dri 7, 0x07, 0xF0, 0xF4
	pop xix
	jrl z, LABEL_F23B90
	call LABEL_F243CC
	push xix
	ld xix, 0x11F9
	add xix, xiy
	add wa, (xix + 5)
	pop xix
	jrl ov, LABEL_F23B81
	cp wa, 0x2FFF
	jrl c, LABEL_F23B84

LABEL_F23B81:
	ldw wa, 0x2FFF

LABEL_F23B84:
	push xix
	ld xix, 0x11F9
	add xix, xiy
	ld (xix + 5), wa
	pop xix

LABEL_F23B90:
	add xiy, 0x7
	cp xiy, 0xE0
	jrl ule, LABEL_F23B58
	ret

SMF_ParseTrackEvent:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23BB6
	pop xbc
	pop xwa
	jp LABEL_F23BBC

LABEL_F23BB6:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23BBC:
	stdi8 4009, 0
	cps a, 2
	jrl z, LABEL_F23C00
	cps a, 3
	jrl z, LABEL_F23C23
	cp a, 0x2F
	jrl z, LABEL_F23C46
	cp a, 0x51
	jrl z, LABEL_F23C6A
	cp a, 0x58
	jrl z, LABEL_F23CA9
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23BF3
	pop xbc
	pop xwa
	jp LABEL_F23BF9

LABEL_F23BF3:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23BF9:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

LABEL_F23C00:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23C16
	pop xbc
	pop xwa
	jp LABEL_F23C1C

LABEL_F23C16:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23C1C:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

LABEL_F23C23:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23C39
	pop xbc
	pop xwa
	jp LABEL_F23C3F

LABEL_F23C39:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23C3F:
	call Sequencer_AdvanceBlockPosition
	jrl Voice_NullRet

LABEL_F23C46:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23C5C
	pop xbc
	pop xwa
	jp LABEL_F23C62

LABEL_F23C5C:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23C62:
	stdi8 4009, 255
	jrl Voice_NullRet

LABEL_F23C6A:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23C80
	pop xbc
	pop xwa
	jp LABEL_F23C86

LABEL_F23C80:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23C86:
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23C9C
	pop xbc
	pop xwa
	jp LABEL_F23CA2

LABEL_F23C9C:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23CA2:
	call LABEL_F244CC
	jrl Voice_NullRet

LABEL_F23CA9:
	call Sequencer_ValidateFileData
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23CBF
	pop xbc
	pop xwa
	jp LABEL_F23CC5

LABEL_F23CBF:
	pop xbc
	pop xwa
	jp Voice_NullRet

LABEL_F23CC5:
	call Sequencer_AdvanceBlockPosition

Voice_NullRet:
	ret

LABEL_F23CCA:
	xor hl, hl

LABEL_F23CCC:
	ld iy, hl
	extz xiy
	sla iy, 1
	add iy, hl
	push xde
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xF4
	pop xde
	jrl z, LABEL_F23CF6
	ld iy, hl
	pushw hl
	call SoundGen_CaptureVoiceParams
	ldb a, 0x82
	call ToneGen_LoadBlockValidate
	call SoundGen_StoreVoiceParamsToTables
	popw hl

LABEL_F23CF6:
	inc 1, hl
	cp hl, 0xF
	jrl ule, LABEL_F23CCC
	ret

SoundGen_ScanActiveVoiceBitmap:
	xor c, c

LABEL_F23D02:
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	jrl nc, LABEL_F23D1D
	stda8 10359, c
	incdi8 1, 10359
	pushw bc
	call Scoop_SpecialMode_ParamCheckBound
	popw bc

LABEL_F23D1D:
	inc 1, c
	cp c, 0xF
	jrl ule, LABEL_F23D02
	ret

FloppyIO_ReturnReady:
	ldb w, 0x1
	ret

LABEL_F23D29:
	stda8 4010, a
	xor bc, bc
	ld xix, 0xFAB
	lda_dpi XBC, 0xF0
	inc 1, c

LABEL_F23D39:
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
	jr lt, LABEL_F23D53
	pop xbc
	pop xwa
	jp LABEL_F23D59

LABEL_F23D53:
	pop xbc
	pop xwa
	jp LABEL_F23D7E

LABEL_F23D59:
	lda_dpi XBC, 0xF0
	inc 1, c
	ldda8 a, 4010
	and a, 0xF0
	ldb w, 0x2
	cp a, 0xD0
	jrl z, LABEL_F23D73
	cp a, 0xC0
	jrl nz, LABEL_F23D75

LABEL_F23D73:
	ldb w, 0x1

LABEL_F23D75:
	cp c, w
	jrl ule, LABEL_F23D39
	call MidiEvent_DispatchSetA

LABEL_F23D7E:
	ret

FloppyIO_ReadMidiEventBytes:
	ld c, a
	ldda8 a, 4010
	ld l, a
	and l, 0xF0
	ld xix, 0xFAB
	lda_dpi XBC, 0xF0
	xor h, h
	ld a, c

LABEL_F23D96:
	lda_dpi XBC, 0xF0
	inc 1, h
	ldb c, 0x1
	cp l, 0xD0
	jrl z, LABEL_F23DA9
	cp l, 0xC0
	jrl nz, LABEL_F23DAB

LABEL_F23DA9:
	ldb c, 0x0

LABEL_F23DAB:
	cp h, c
	jrl ugt, LABEL_F23DD3
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
	jr lt, LABEL_F23DCA
	pop xbc
	pop xwa
	jp LABEL_F23D96

LABEL_F23DCA:
	pop xbc
	pop xwa
	jp LABEL_F23DF0
LABEL_F23DD0:
	jrl	t, 0xffc3

LABEL_F23DD3:
	cpdi16 3932, 0
	jrl z, FloppyIO_DispatchMidiEvent
	cpdi16 3934, 1
	jrl z, FloppyIO_DispatchMidiEvent
	call MidiEvent_DispatchSetB
	jrl LABEL_F23DF0

FloppyIO_DispatchMidiEvent:
	call MidiEvent_DispatchSetA

LABEL_F23DF0:
	ret

VoiceChannels_LoadPartMapAndInitPan:
	ld xiy, 0xF23E18
	cpdi8 4600, 1
	jrl z, LABEL_F23E03
	ld xiy, 0xF23E28

LABEL_F23E03:
	ld xix, 0xF1A0
	ldw bc, 0x10
	ldir85
	stdi16 62096, 65535
	call VoiceChannels_InitPanFromPreset
	ret

LABEL_F23E18:
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0x13, 0x0c
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x0c, 0x06, 0x07, 0x11, 0x12, 0x13, 0x05

LABEL_F23E38:
	ldw bc, 0xC00

LABEL_F23E3B:
	ldw hl, 0x3C0

LABEL_F23E3E:
	djnz xhl, LABEL_F23E3E
	djnz xbc, LABEL_F23E3B
	ret

LABEL_F23E45:
	push xiy
	push xde
	push xhl
	xor xhl, xhl
	xor xde, xde
	ldb a, 0x2
	ldb w, 0x80
	ldw bc, 0x10

LABEL_F23E53:
	ld hl, de
	ld xix, 0xF237C1
	sla hl, 2
	ld_sril3 XIY, 0x07, 0xF0, 0xEC
	ld (xiy + 11), a
	ld (xiy + 10), w
	inc 1, de
	djnz xbc, LABEL_F23E53
	pop xhl
	pop xde
	pop xiy
	ret

LABEL_F23E71:
	ld xhl, 0xAB000
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	add xhl, xwa
	ld xix, xhl
	add xix, 0xBD
	ld (xix), c
	ret

LABEL_F23E8D:
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	ld ix, iy
	cpdi16 62001, 16
	jrl c, SMF_VoiceSetup_Exit
	push xiy
	push xix
	call DispatchHandler_JumpToSubHandler
	ld wa, ix
	pop xix
	pop xiy
	ldda16 xbc, 10349
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
	ldw (xhl + 3), 0xFFFF
	popw wa
	ld hl, iy
	sla iy, 1
	add iy, hl
	ld xhl, 0xF250
	or_srib_im 0x07, 0xEC, 0xF4, 0x80
	ldfr_lerp XHL, 0x38
	st_dri3b C, 0x07, 0xEC, 0xF4
	ld (xhl + 1), wa
	ldto_lerp XHL, 0x38
	ld xhl, 0xC9E
	sla ix, 1
	st_dri3w WA, 0x07, 0xEC, 0xF0
	ld xhl, 0xCBE
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	stiw_dri 0x07, 0xEC, 0xF4, 0x05, 0x00

SMF_VoiceSetup_Exit:
	ret

LABEL_F23F13:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ldw bc, 0x10
	ld xix, 0xFAE

LABEL_F23F20:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F23F20
	pop xix
	popw bc
	popw wa
	ret

LABEL_F23F2A:
	lds bc, 4
	ld xiy, 0xF2410E

LABEL_F23F31:
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
	jr lt, LABEL_F23F4B
	pop xbc
	pop xwa
	jp LABEL_F23F55

LABEL_F23F4B:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F23F55:
	cp_spib A, 0xF4
	jrl z, LABEL_F23F69
	stdi8 3830, 255
	stdi16 6699, 49
	jrl SMF_NullRet

LABEL_F23F69:
	djnz xbc, LABEL_F23F31
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
	jr lt, LABEL_F23FA8
	pop xbc
	pop xwa
	jp LABEL_F23FB2

LABEL_F23FA8:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F23FB2:
	stdi8 4236, 0

SMF_ProcessVoiceData:
	cpdi8 4323, 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23FD1
	pop xbc
	pop xwa
	jp LABEL_F23FDB

LABEL_F23FD1:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F23FDB:
	call FloppyIO_ReadToTrackBuffer
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23FF1
	pop xbc
	pop xwa
	jp LABEL_F23FFB

LABEL_F23FF1:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F23FFB:
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
	jr lt, LABEL_F24025
	pop xbc
	pop xwa
	jp LABEL_F2402F

LABEL_F24025:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F2402F:
	cp a, 0xFF
	jrl nz, LABEL_F2408B
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F2404B
	pop xbc
	pop xwa
	jp LABEL_F24055

LABEL_F2404B:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F24055:
	cpdi8 4009, 255
	jrl z, LABEL_F2406C
	cpdi8 4323, 0
	jrl z, SMF_ProcessVoiceData
	stdi8 3830, 255
	jr SMF_EventFailureExit

LABEL_F2406C:
	call LABEL_F247B4

LABEL_F24070:
	ldda32 xbc, 6883
	lds32 xwa, 0
	cp xbc, xwa
	jp_24 z, 0xF24088
	call FloppyIO_ReadNextByte
	nop
	nop
	nop
	jp LABEL_F24070

LABEL_F24088:
	jrl SMF_NullRet

LABEL_F2408B:
	cp a, 0xF7
	jrl z, LABEL_F24097
	cp a, 0xF0
	jrl nz, LABEL_F240BA

LABEL_F24097:
	call SMF_ProcessSysExBlock
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F240AD
	pop xbc
	pop xwa
	jp LABEL_F240B7

LABEL_F240AD:
	pop xbc
	pop xwa
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F240B7:
	jrl SMF_ProcessVoiceData

LABEL_F240BA:
	bit 7, a
	jrl z, LABEL_F240E8
	call LABEL_F247EB
	cpdi8 4323, 0
	jrl nz, SMF_EventFailureExit
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F240DE
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

LABEL_F240DE:
	pop xbc
	pop xwa

SMF_EventFailureExit:
	stdi8 3830, 255
	jrl SMF_NullRet

LABEL_F240E8:
	call FloppyIO_ReadMidiEventBytes
	cpdi8 4323, 0
	jrl nz, LABEL_F24108
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F24106
	pop xbc
	pop xwa
	jp SMF_ProcessVoiceData

LABEL_F24106:
	pop xbc
	pop xwa

LABEL_F24108:
	stdi8 3830, 255

SMF_NullRet:
	ret

LABEL_F2410E:	.ascii "MTrk"

LABEL_F24112:
	xor a, a
	lds hl, 1
	stda8 10359, a
	incdi8 1, 10359
	stda8 9858, l
	incdi8 1, 9858
	ldda8 a, 10359
	stda8 9860, a
	pushw wa
	push xhl
	call SetWall_ValidateAndApply
	pop xhl
	popw wa
	ret

LABEL_F24137:
	cpdi16 62001, 16
	jrl nc, LABEL_F24148
	stdi8 4323, 255
	jrl SoundGen_ResetVoiceBitmapAndFlag

LABEL_F24148:
	ldda16 xde, 62033
	ld hl, de
	call ToneGen_CopyBlockToVoiceBuffer
	stda16 10198, xiy
	pushw de
	lds hl, 1

LABEL_F24159:
	pushw hl
	call LABEL_F24A34
	popw hl
	inc 1, hl
	cp hl, 0x10
	jrl ule, LABEL_F24159
	popw de
	call SeqTrack_AssignFloppyChannels
	cpdi8 3830, 0
	jrl nz, LABEL_F2435A
	call SoundGen_InitAllVoiceChannels
	stdi8 6650, 0

MidiSysEx_CmdDispatchLoop:
	call LABEL_F24A84
	ldda8 a, 4211
	cp a, 0x81
	jrl z, LABEL_F241C2
	cp a, 0x82
	jrl z, LABEL_F241CB
	and a, 0xF0
	cp a, 0x90
	jrl z, LABEL_F241F3
	cp a, 0xA0
	jrl z, LABEL_F24217
	cp a, 0xB0
	jrl z, LABEL_F24264
	cp a, 0xC0
	jrl z, LABEL_F242A9
	cp a, 0xD0
	jrl z, LABEL_F242E5
	cp a, 0xE0
	jrl z, LABEL_F24309
	cp a, 0xF0
	jrl z, LABEL_F2432D
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F241C2:
	ldb a, 0x81
	call ToneGen_WriteAllChannels
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F241CB:
	ldb a, 0x82
	call ToneGen_WriteAllChannels
	xor hl, hl
	xor iy, iy

LABEL_F241D5:
	pushw hl
	pushw iy
	call SoundGen_CaptureVoiceParams
	call SoundGen_StoreVoiceParamsToTables
	popw iy
	popw hl
	inc 1, iy
	inc 1, hl
	cp iy, 0xF
	jrl ule, LABEL_F241D5
	call SoundGen_ScanActiveVoiceBitmap
	jrl SoundGen_ResetVoiceBitmapAndFlag

LABEL_F241F3:
	ldda16 xiy, 4211
	and iy, 0xF
	anddi8 4211, 240
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 6
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F24217:
	cps hl, 3
	jrl z, LABEL_F24240
	ldda16 xiy, 4211
	and iy, 0xF
	stdi8 4211, 128
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 4
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F24240:
	ldda16 xiy, 4211
	and iy, 0xF
	stdi8 4211, 208
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F24264:
	xor hl, hl
	ldda8 l, 4213
	cp l, 0x7F
	jrl z, MidiSysEx_CmdDispatchLoop
	jrl LABEL_F24273

LABEL_F24273:
	push xix
	ld xix, 0xF2435B
	cpdi8 4600, 1
	jrl z, LABEL_F24286
	ld xix, 0xF2436B

LABEL_F24286:
	ld_srib3 A, 0x07, 0xF0, 0xEC
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

LABEL_F242A9:
	xor hl, hl
	ldda8 l, 4213
	push xix
	ld xix, 0xF2435B
	cpdi8 4600, 1
	jrl z, LABEL_F242C2
	ld xix, 0xF2436B

LABEL_F242C2:
	ld_srib3 A, 0x07, 0xF0, 0xEC
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

LABEL_F242E5:
	ldda16 xiy, 4211
	and iy, 0xF
	stdi8 4211, 209
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 3
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F24309:
	ldda16 xiy, 4211
	and iy, 0xF
	stdi8 4211, 210
	pushw iy
	call SoundGen_CaptureVoiceParams
	lds bc, 4
	call ToneGen_UpdateBlocks
	popw iy
	call ToneGen_SetChannelFlag
	call ToneGen_WriteChannelRegs
	jrl MidiSysEx_CmdDispatchLoop

LABEL_F2432D:
	ldda16 xiy, 4211
	and iy, 0xF
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
	call LABEL_F24B8C
	ordi8 10419, 16

LABEL_F2435A:
	ret

LABEL_F2435B:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x0f, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x09

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

LABEL_F24391:
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

LABEL_F243A8:
	ldb a, 0x81
	pushw bc
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	popw bc
	cpdi8 4323, 0
	jrl nz, LABEL_F243CB
	djnz xbc, LABEL_F243A8
	call ToneGen_WriteChannelRegs
	ordi8 4236, 1
	stdi8 4323, 0

LABEL_F243CB:
	ret

LABEL_F243CC:
	ldda16 xwa, 3936
	cp wa, 0x60
	jrl z, LABEL_F24433
	ldda8 e, 4213
	ldda16 xwa, 4211
	cps e, 0
	jrl z, LABEL_F24418
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xE2
	stda16 4333, xwa
	stda16 4335, xde
	xor w, w
	ldda8 a, 4213
	mul xwa, xhl
	ldto_werp DE, 0xE2
	addda16 xwa, 4335
	ld de, wa
	ldda16 xwa, 4333
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	jrl LABEL_F2443D

LABEL_F24418:
	ldda16 xwa, 4211
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xE2
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	jrl LABEL_F2443D

LABEL_F24433:
	xor de, de
	ldda8 e, 4213
	ldda16 xwa, 4211

LABEL_F2443D:
	ret

Sequencer_ValidateFileData:
	call LABEL_F24BF8
	call LABEL_F24C08
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F24458
	pop xbc
	pop xwa
	jp LABEL_F2445E

LABEL_F24458:
	pop xbc
	pop xwa
	jp LABEL_F24462

LABEL_F2445E:
	call SeqTrack_DispatchPartEvt

LABEL_F24462:
	ret

Sequencer_AdvanceBlockPosition:
	ldda32 xix, 4376
	addda32 xix, 4211
	cp xix, 0x17F9
	jrl ule, LABEL_F2449F
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
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	cps de, 0
	jrl nz, LABEL_F24496

LABEL_F24496:
	popw de
	pop xhl
	popw wa
	sub xix, 0x400

LABEL_F2449F:
	stda32 4376, xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6883
	cp xwa, xbc
	jp_24 z, 0xF244C0
	cpdi8 6887, 1
	jp_24 z, 0xF244C0
	subda32 xwa, 4211

LABEL_F244C0:
	stda32 6883, xwa
	pop xbc
	pop xwa
	stdi8 4323, 0
	ret

LABEL_F244CC:
	stdi8 3950, 0
	stda8 3951, a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F244EB
	pop xbc
	pop xwa
	jp LABEL_F244F1

LABEL_F244EB:
	pop xbc
	pop xwa
	jp SoundGen_NullRet

LABEL_F244F1:
	stda8 3948, a
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F2450B
	pop xbc
	pop xwa
	jp LABEL_F24511

LABEL_F2450B:
	pop xbc
	pop xwa
	jp SoundGen_NullRet

LABEL_F24511:
	stda8 3949, a
	ldda8 h, 3951
	ldda8 l, 3948
	ldw wa, 0x9387
	lds de, 3
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	cp wa, 0x28
	jrl ugt, LABEL_F24537
	ldw wa, 0x28
	jrl SoundGen_EncodeTempoByte

LABEL_F24537:
	cp wa, 0x12C
	jrl c, SoundGen_EncodeTempoByte
	ldw wa, 0x12C

SoundGen_EncodeTempoByte:
	ld hl, wa
	ld w, a
	and a, 0x7F
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
	ldb a, 0xA0
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	ld xde, 0xC9E
	ld_sriw3 WA, 0x07, 0xE8, 0xF4
	stda16 10415, xwa
	srl xiy, 1
	ld xde, 0xCBE
	ld_srib3 A, 0x07, 0xE8, 0xF4
	xor w, w
	stda16 9830, xwa
	pop xde
	ret

ToneGen_LoadBlockValidate:
	push xhl
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ldda16 xiy, 9830
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pop xhl
	ret

SoundGen_StoreVoiceParamsToTables:
	push xix
	ldda16 xwa, 9830
	ld xix, 0xF218
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	sla hl, 1
	ldda16 xwa, 10415
	ld xix, 0xF1F8
	st_dri3w WA, 0x07, 0xF0, 0xEC
	pop xix
	ret

MidiEvent_DispatchSetA:
	ld xix, 0xFAB
	ldda8 a, 4011
	pushw hl
	ldda16 xhl, 4012
	cp l, 0x7F
	jrl ule, LABEL_F246BE
	ldb l, 0x7F

LABEL_F246BE:
	cp h, 0x7F
	jrl ule, LABEL_F246C6
	ldb h, 0x7F

LABEL_F246C6:
	stda16 4012, xhl
	popw hl
	ld w, a
	and w, 0xF0
	cp w, 0x90
	jrl z, LABEL_F246FE
	cp w, 0xB0
	jrl z, LABEL_F24714
	cp w, 0x80
	jrl z, MidiEvent_NoteOffA
	cp w, 0xE0
	jrl z, LABEL_F2471B
	cp w, 0xC0
	jrl z, LABEL_F24722
	cp w, 0xD0
	jrl z, LABEL_F246F7
	jrl MidiNoteOff_NullRetA

LABEL_F246F7:
	call LABEL_F24C5B
	jrl MidiNoteOff_NullRetA

LABEL_F246FE:
	ld w, (xix + 2)
	cps w, 0
	jrl z, MidiEvent_NoteOffA
	call LABEL_F24CBF
	jrl MidiNoteOff_NullRetA

MidiEvent_NoteOffA:
	call LABEL_F24E3B
	jrl MidiNoteOff_NullRetA

LABEL_F24714:
	call VoiceSynth_CommandDispatch
	jrl MidiNoteOff_NullRetA

LABEL_F2471B:
	call LABEL_F24FE0
	jrl MidiNoteOff_NullRetA

LABEL_F24722:
	call LABEL_F25056

MidiNoteOff_NullRetA:
	ret

MidiEvent_DispatchSetB:
	ld xix, 0xFAB
	ldda8 a, 4011
	pushw hl
	ldda16 xhl, 4012
	cp l, 0x7F
	jrl ule, LABEL_F2473D
	ldb l, 0x7F

LABEL_F2473D:
	cp h, 0x7F
	jrl ule, LABEL_F24745
	ldb h, 0x7F

LABEL_F24745:
	stda16 4012, xhl
	popw hl
	ld w, a
	and w, 0xF0
	cp w, 0x90
	jrl z, LABEL_F2477D
	cp w, 0xB0
	jrl z, LABEL_F24793
	cp w, 0x80
	jrl z, MidiEvent_NoteOffB
	cp w, 0xE0
	jrl z, LABEL_F2479A
	cp w, 0xC0
	jrl z, LABEL_F247A1
	cp w, 0xD0
	jrl z, LABEL_F24776
	jrl MidiNoteOff_NullRetB

LABEL_F24776:
	call LABEL_F2535F
	jrl MidiNoteOff_NullRetB

LABEL_F2477D:
	ld w, (xix + 2)
	cps w, 0
	jrl z, MidiEvent_NoteOffB
	call LABEL_F253D2
	jrl MidiNoteOff_NullRetB

MidiEvent_NoteOffB:
	call LABEL_F25560
	jrl MidiNoteOff_NullRetB

LABEL_F24793:
	call VoiceParam_CommandDispatch
	jrl MidiNoteOff_NullRetB

LABEL_F2479A:
	call LABEL_F256F9
	jrl MidiNoteOff_NullRetB

LABEL_F247A1:
	call LABEL_F2577A

MidiNoteOff_NullRetB:
	ret

SoundGen_ClampVoiceIndexMin1:
	extz xiy
	cp xiy, 0x1
	jrl ule, LABEL_F247B3
	lds32 xiy, 1

LABEL_F247B3:
	ret

LABEL_F247B4:
	ldda16 xhl, 4237
	ld iy, hl
	call SoundGen_ClampVoiceIndexMin1
	ld hl, iy
	sla iy, 1
	add iy, hl
	push xde
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xF4
	pop xde
	jrl z, LABEL_F247EA
	ldda16 xiy, 4237
	ld hl, iy
	push xhl
	call SoundGen_ReadVoiceRegs
	ldb a, 0x82
	call ToneGen_LoadBlockValidate
	call LABEL_F25AE3
	pop xhl

LABEL_F247EA:
	ret

LABEL_F247EB:
	stda8 4010, a
	xor bc, bc
	ld xix, 0xFAB
	lda_dpi XBC, 0xF0
	inc 1, c

LABEL_F247FB:
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
	jr lt, LABEL_F24815
	pop xbc
	pop xwa
	jp LABEL_F2481B

LABEL_F24815:
	pop xbc
	pop xwa
	jp LABEL_F24840

LABEL_F2481B:
	lda_dpi XBC, 0xF0
	inc 1, c
	ldda8 a, 4010
	and a, 0xF0
	ldb w, 0x2
	cp a, 0xD0
	jrl z, LABEL_F24835
	cp a, 0xC0
	jrl nz, LABEL_F24837

LABEL_F24835:
	ldb w, 0x1

LABEL_F24837:
	cp c, w
	jrl ule, LABEL_F247FB
	call MidiEvent_DispatchSetB

LABEL_F24840:
	ret

SetWall_ValidateAndApply:
	stdi8 10194, 0
	call SetWall_ParserInit
	ldda8 a, 10359
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 10401
	jrl ugt, SetWall_ParamOutOfRange
	cpda8 a, 9858
	jrl z, SetWall_ParamOutOfRange
	ldda8 a, 9858
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 10401
	jrl ugt, SetWall_ParamOutOfRange
	ldda8 a, 9860
	cps a, 1
	jrl c, SetWall_ParamOutOfRange
	cpda8 a, 10401
	jrl ule, LABEL_F24889

SetWall_ParamOutOfRange:
	stdi8 10362, 3
	jrl Scoop_NullRet

LABEL_F24889:
	xor hl, hl
	stdi8 10362, 0
	anddi8 10363, 191
	ldda8 a, 10359
	call SetWall_SingleSlotResolve
	cpdi8 10362, 0
	jrl z, LABEL_F248A8
	jrl Scoop_NullRet

LABEL_F248A8:
	ldda16 xwa, 10415
	stda16 10196, xwa
	ldda8 a, 9858
	call SetWall_SingleSlotResolve
	cpdi8 10362, 0
	jrl nz, Scoop_NullRet
	ldda16 xwa, 10415
	stda16 10200, xwa
	ldda8 a, 9860
	cpda8 a, 10359
	jrl z, SetWall_InitVoiceSlots
	cpda8 a, 9858
	jrl z, SetWall_InitVoiceSlots
	ldda8 a, 10359
	pushw wa
	ldda8 a, 9860
	stda8 10359, a
	call Scoop_SpecialMode_ParamCheckBound
	popw wa
	stda8 10359, a

SetWall_InitVoiceSlots:
	xor xhl, xhl
	ldda8 l, 10359
	call VoiceChannel_ClearRegisters
	ld xix, 0x17FA
	nop
	ldda16 xwa, 10196
	stda16 10415, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	stda16 10198, xiy
	xor xhl, xhl
	ldda8 l, 9858
	call VoiceChannel_ClearRegisters
	ld xix, 0x18FA
	nop
	ldda16 xwa, 10200
	stda16 10415, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	call VoiceChannel_CopyParamBlock
	stda16 10202, xiy
	call DispatchHandler_JumpToSubHandler
	xor hl, hl
	ldda8 l, 9860
	dec 1, hl
	muls l, 0x3
	push xiy
	ld xiy, 0xF250
	or_srib_im 0x07, 0xF4, 0xEC, 0x80
	inc 1, xhl
	st_dri3w IX, 0x07, 0xF4, 0xEC
	pop xiy
	stda16 3308, xix
	ld hl, ix
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	stda32 10369, xhl
	lds ix, 5
	ldw (xhl + 1), 0x0
	ldw (xhl + 3), 0xFFFF
	call VoiceChannel_UpdateParamSet
	call ToneGen_ValidateVoiceCh2

Scoop_ProcessCompareLoop:
	cpdi8 10194, 255
	jrl nz, LABEL_F24990
	jrl Scoop_NullRet

LABEL_F24990:
	cpdi8 10194, 3
	jrl z, LABEL_F2499B
	jrl LABEL_F249BB

LABEL_F2499B:
	cp c, b
	jrl c, LABEL_F249A6
	jrl z, LABEL_F249AD
	jrl ugt, LABEL_F249B4

LABEL_F249A6:
	call VoiceChannel_FindNextLoop
	jrl Scoop_ProcessCompareLoop

LABEL_F249AD:
	call LABEL_F25C2A
	jrl Scoop_ProcessCompareLoop

LABEL_F249B4:
	call ToneGen_AdvanceVoiceLoop
	jrl Scoop_ProcessCompareLoop

LABEL_F249BB:
	bitda 0, 10194
	jrl z, LABEL_F249C9
	call ToneGen_AdvanceVoiceLoop
	jrl Scoop_ProcessCompareLoop

LABEL_F249C9:
	bitda 1, 10194
	jrl z, LABEL_F249D7
	call VoiceChannel_FindNextLoop
	jrl Scoop_ProcessCompareLoop

LABEL_F249D7:
	ldda8 a, 10204
	ldda8 w, 10206
	cp a, w
	jrl le, LABEL_F249EB
	call ToneGen_AdvanceAndValidateVoice
	jrl Scoop_ProcessCompareLoop

LABEL_F249EB:
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
	ld xix, 0x17FA
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

LABEL_F24A34:
	push xix
	dec 1, hl
	ld iy, hl
	muls_erpb 0xF4, 0x03
	ld xix, 0xF250
	and_srib_im 0x07, 0xF0, 0xF4, 0x7F
	inc 1, iy
	stiw_dri 0x07, 0xF0, 0xF4, 0xFF, 0xFF
	ld xix, 0xCBE
	stib_dri 0x07, 0xF0, 0xEC, 0x05
	ld xix, 0xF218
	stib_dri 0x07, 0xF0, 0xEC, 0x05
	sla hl, 1
	ld xix, 0xC9E
	stiw_dri 0x07, 0xF0, 0xEC, 0xFF, 0xFF
	ld xix, 0xF1F8
	stiw_dri 0x07, 0xF0, 0xEC, 0xFF, 0xFF
	pop xix
	ret

LABEL_F24A84:
	xor hl, hl
	call VoiceChannel_ClearParamTable
	ldda16 xiy, 10198
	push xix
	ld xix, 0x17FA
	ld_srib3 A, 0x07, 0xF0, 0xF4
	ld xix, 0x1073
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	pop xix
	cp a, 0x82
	jrl z, LABEL_F24AD7

LABEL_F24AAA:
	inc 1, hl
	pushw hl
	call LABEL_F25D20
	popw hl
	ldda16 xiy, 10198
	push xix
	ld xix, 0x17FA
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	bit 7, a
	jrl nz, LABEL_F24AD7
	push xix
	ld xix, 0x1073
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	pop xix
	jrl LABEL_F24AAA

LABEL_F24AD7:
	ret

ToneGen_WriteAllChannels:
	xor iy, iy

LABEL_F24ADA:
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
	jrl LABEL_F24B17

ToneGen_WriteAllChannels_Next:
	popw iy
	pushw wa
	pushw iy
	call ToneGen_WriteChannelRegs
	popw iy
	popw wa
	inc 1, iy
	cp iy, 0xF
	jrl ule, LABEL_F24ADA

LABEL_F24B17:
	ret

ToneGen_UpdateBlocks:
	ldda16 xhl, 10415
	pushw bc
	call ToneGen_ComputeBlockPtr
	popw bc
	xor ix, ix

LABEL_F24B24:
	push xde
	ld xde, 0x1073
	ld_srib3 A, 0x07, 0xE8, 0xF0
	pop xde
	pushw bc
	push xix
	call ToneGen_WriteParamToBlock
	call ToneGen_AdvancePosition
	pop xix
	popw bc
	cpdi8 4323, 0
	jrl nz, LABEL_F24B49
	inc 1, ix
	djnz xbc, LABEL_F24B24

LABEL_F24B49:
	ret

ToneGen_SetChannelFlag:
	ld bc, iy
	and bc, 0xF
	ld a, c
	scf
	stcfa_dd16 0xFA, 0x19
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	stcf_a_16 de
	st16_24 0x00ffec, xde
	ret

ToneGen_WriteChannelRegs:
	push xix
	ldda16 xwa, 10415
	sla iy, 1
	ld xix, 0xC9E
	st_dri3w WA, 0x07, 0xF0, 0xF4
	ldda16 xwa, 9830
	srl iy, 1
	ld xix, 0xCBE
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix
	ret

LABEL_F24B8C:
	push xix
	xor hl, hl
	xor bc, bc

LABEL_F24B91:
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jrl c, ToneGen_UpdateBlocks_NextChannel
	ld xix, 0xF250
	bit_dri 7, 0x07, 0xF0, 0xEC
	jrl z, ToneGen_UpdateBlocks_NextChannel
	ld xix, 0xF250
	st_dri3b D, 0x07, 0xF0, 0xEC
	ld wa, (xix + 1)
	ld iy, bc
	ld xix, 0xC9E
	sla iy, 1
	st_dri3w WA, 0x07, 0xF0, 0xF4
	srl iy, 1
	ld xix, 0xCBE
	stib_dri 0x07, 0xF0, 0xF4, 0x05

ToneGen_UpdateBlocks_NextChannel:
	inc 1, c
	add hl, 0x3
	cp c, 0xF
	jrl ule, LABEL_F24B91
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
	call LABEL_F25DBA
	ret

LABEL_F24BF8:
	xor wa, wa
	ld xix, 0x106E
	lds bc, 2

LABEL_F24C01:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F24C01
	ret

LABEL_F24C08:
	ld xix, 0x106E

LABEL_F24C0D:
	push xix
	call FloppyIO_ReadNextByte
	pop xix
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F24C25
	pop xbc
	pop xwa
	jp LABEL_F24C2B

LABEL_F24C25:
	pop xbc
	pop xwa
	jp LABEL_F24C3A

LABEL_F24C2B:
	lda_dpi XBC, 0xF0
	bit 7, a
	jrl nz, LABEL_F24C0D
	sub xix, 0x106E

LABEL_F24C3A:
	ret

SoundGen_ScalePitchByTempo:
	ldda16 xhl, 3936
	cp hl, 0x60
	jrl z, LABEL_F24C5A
	ldw hl, 0x60
	mul xwa, xhl
	ldto_werp DE, 0xE2
	ldda16 xhl, 3936
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2

LABEL_F24C5A:
	ret

LABEL_F24C5B:
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xD0
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustainExitAlt
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

LABEL_F24CBF:
	ld xiy, 0x11F9

LABEL_F24CC4:
	bitm 7, (xiy)
	jrl nz, LABEL_F24CCE
	ld xix, xiy
	jrl LABEL_F24CE5

LABEL_F24CCE:
	add xiy, 0x7
	cp xiy, 0x12D9
	jrl ule, LABEL_F24CC4
	stdi8 4323, 0
	jrl VoiceSynth_NullRet2

LABEL_F24CE5:
	call SndParam_LookupChannelVoice
	cp a, 0xFF
	jr nz, LABEL_F24CF7
	stdi8 4323, 0
	jp VoiceSynth_NullRet2

LABEL_F24CF7:
	ordi8 4236, 1
	ldda16 xiy, 4011
	and iy, 0xF
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	jr nz, LABEL_F24DB9
	ldda8 a, 4011
	and a, 0xF
	cp a, 0x9
	jrl nz, LABEL_F24D8C
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
	jp Scoop_ApplySoundParams

LABEL_F24D8C:
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
	ld_sriw3 WA, 0x07, 0xF0, 0xEC
	ld c, w
	call SndParam_LookupByPartAndNote
	ldda8 a, 4012
	add a, l
	pop xde
	pop xbc
	pop xix
	jp Scoop_ApplySoundParams

LABEL_F24DB9:
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
	ldda16 xwa, 10415
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
	and a, 0xF
	or a, 0x80
	ld (xix), a
	ldda8 a, 4012
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	stdi8 4323, 0

VoiceSynth_NullRet2:
	ret

LABEL_F24E3B:
	ld xiy, 0x11F9

LABEL_F24E40:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceChkAlt
	ld a, (xiy)
	and a, 0xF
	ldda8 l, 4011
	and l, 0xF
	cp a, l
	jrl nz, ToneGen_LoopAdvanceChkAlt
	ldda8 l, 4012
	cp (xiy + 1), l
	jrl nz, ToneGen_LoopAdvanceChkAlt
	andmi8 (xiy), 0x7F
	ld ix, (xiy + 2)
	ld hl, (xiy + 3)
	and xix, 0xFF
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
	lda_dri3 XWA, 0x07, 0xEC, 0xF0
	pop xhl
	push_sd16w 0xAF, 0x28
	push_sd16w 0x66, 0x26
	stda16 10415, xhl
	stda16 9830, xix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	push xix
	push xiy
	ldda32 xix, 4349
	ldda16 xiy, 9830
	and iy, 0xFF
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xiy
	pop xix
	popw_dd16 0x66, 0x26
	popw_dd16 0xAF, 0x28
	jrl LABEL_F24ED8

ToneGen_LoopAdvanceChkAlt:
	add xiy, 0x7
	cp xiy, 0x12D9
	jrl ule, LABEL_F24E40

LABEL_F24ED8:
	ret

; Voice synthesis command dispatcher
; Dispatches on DRAM[4012] value: <0x10 uses algorithm table, others are direct handlers
VoiceSynth_CommandDispatch:
	ldda8 a, 4012
	cp a, 0x10
	jrl c, VoiceSynth_AlgoTableDispatch
	cp a, 0x20
	jrl z, LABEL_F24F4E
	cp a, 0x26
	jrl z, LABEL_F24F55
	cp a, 0x40
	jrl z, LABEL_F24F5C
	cp a, 0x42
	jrl z, LABEL_F24F63
	cp a, 0x43
	jrl z, LABEL_F24F6A
	cp a, 0x5B
	jrl z, LABEL_F24F71
	cp a, 0x5D
	jrl z, LABEL_F24F78
	cp a, 0x60
	jrl z, LABEL_F24F7F
	cp a, 0x61
	jrl z, LABEL_F24F86
	cp a, 0x62
	jrl z, Scoop_Cmd_ReleaseVoiceSlot
	cp a, 0x63
	jrl z, Scoop_Cmd_ReleaseVoiceSlot
	cp a, 0x64
	jrl z, LABEL_F24F9B
	cp a, 0x65
	jrl z, LABEL_F24F94
	jrl VoiceSynth_NullRet

; Dispatch via VoiceSynth_Algorithm_Table (16-entry, call (xhl))
; Index: DRAM[4012] (0x00-0x0F), 32-bit function pointers
VoiceSynth_AlgoTableDispatch:
	ld l, a
	xor h, h
	sla l, 2
	extz xhl
	push xix
	ld xix, 0xF24FA0
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	call (xhl)
	jrl VoiceSynth_NullRet

LABEL_F24F4E:
	call LABEL_F25E31
	jrl VoiceSynth_NullRet

LABEL_F24F55:
	call LABEL_F25E4C
	jrl VoiceSynth_NullRet

LABEL_F24F5C:
	call LABEL_F25EB8
	jrl VoiceSynth_NullRet

LABEL_F24F63:
	call LABEL_F25EE6
	jrl VoiceSynth_NullRet

LABEL_F24F6A:
	call LABEL_F25EE7
	jrl VoiceSynth_NullRet

LABEL_F24F71:
	call LABEL_F25EE8
	jrl VoiceSynth_NullRet

LABEL_F24F78:
	call LABEL_F25F0E
	jrl VoiceSynth_NullRet

LABEL_F24F7F:
	call VoiceChannel_SelectNextParam
	jrl VoiceSynth_NullRet

LABEL_F24F86:
	call VoiceChannel_SelectPrevParam
	jrl VoiceSynth_NullRet

Scoop_Cmd_ReleaseVoiceSlot:
	call VoiceChannel_ClearChannelFlags
	jrl VoiceSynth_NullRet

LABEL_F24F94:
	call VoiceChannel_NoteOnByChannel
	jrl VoiceSynth_NullRet

LABEL_F24F9B:
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

LABEL_F24FE0:
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xD2
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceSynth_NullRet3
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

LABEL_F25056:
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	bitda 0, 4236
	jrl nz, LABEL_F25070
	call VoiceChannel_ApplyParamByMode
	stdi8 4323, 0

LABEL_F25070:
	cpdi8 4600, 0
	jr z, LABEL_F25082
	cpdi8 4600, 2
	jrl z, LABEL_F25181
	jrl LABEL_F252A7

LABEL_F25082:
	push xix
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF2436B
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6748, l
	pop xix
	ld xwa, 0x1A57
	call SndParam_ApplyVoiceValue
	push xiy
	push xhl
	call SoundGen_CaptureVoiceParams
	pop xhl
	ldb a, 0xC0
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	ld xix, 0xF2436B
	ld_srib3 A, 0x07, 0xF0, 0xF4
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
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6747
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0
	jrl SoundGen_NullReturn

LABEL_F25181:
	push xix
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF2436B
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6748, l
	pop xix
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1A57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, LABEL_F251E5
	ld xhl, 0x1A37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

LABEL_F251E5:
	push xiy
	push xhl
	call SoundGen_CaptureVoiceParams
	pop xhl
	ldb a, 0xC0
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	ld xix, 0xF2436B
	ld_srib3 A, 0x07, 0xF0, 0xF4
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
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	ldda8 a, 6747
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, SoundGen_NullReturn
	call ToneGen_SetSustainBit
	call ToneGen_WriteChannelRegs
	stdi8 4323, 0
	jrl SoundGen_NullReturn

LABEL_F252A7:
	push xiy
	call SoundGen_CaptureVoiceParams
	ldb a, 0xC0
	pop xiy
	push xix
	ld xix, 0xF72
	ld_srib3 W, 0x07, 0xF0, 0xF4
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
	jrl nz, SoundGen_NullReturn
	push xix
	ld xix, 0xF2435B
	ld_srib3 A, 0x07, 0xF0, 0xF4
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
	ld xix, 0xF82
	ld_srib3 A, 0x07, 0xF0, 0xF4
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

LABEL_F2535F:
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1
	and xiy, 0xF
	push xiy
	call SoundGen_ReadVoiceRegs
	ldda8 w, 4011
	and w, 0xF
	ldb a, 0xA0
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, ToneGen_SetSustain_Exit
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

LABEL_F253D2:
	ld xiy, 0x11F9

LABEL_F253D7:
	bitm 7, (xiy)
	jrl nz, LABEL_F253E1
	ld xix, xiy
	jrl LABEL_F253F3

LABEL_F253E1:
	add xiy, 0x7
	cp xiy, 0x12D9
	jrl ule, LABEL_F253D7
	jrl VoiceParam_NullRet2

LABEL_F253F3:
	call SndParam_LookupChannelVoice
	cp a, 0xFF
	jr nz, LABEL_F25405
	stdi8 4323, 0
	jp VoiceParam_NullRet2

LABEL_F25405:
	ordi8 4236, 1
	ldda16 xiy, 4237
	extz xiy
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xF
	push xiy
	push xix
	call SoundGen_ReadVoiceRegs
	pop xix
	ldda8 w, 4011
	and w, 0xF
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	jr nz, LABEL_F254D6
	ldda8 a, 4011
	and a, 0xF
	cp a, 0x9
	jrl nz, LABEL_F254A9
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
	jp Scoop_ApplySoundParamsAlt

LABEL_F254A9:
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
	ld_sriw3 WA, 0x07, 0xF0, 0xEC
	ld c, w
	call SndParam_LookupByPartAndNote
	ldda8 a, 4012
	add a, l
	pop xde
	pop xbc
	pop xix
	jp Scoop_ApplySoundParamsAlt

LABEL_F254D6:
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
	cp a, 0x7F
	jrl ule, LABEL_F254F6
	ldb a, 0x7F

LABEL_F254F6:
	push xiy
	push xix
	call SoundGen_UpdateAndRefresh
	pop xix
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet2
	ldda8 a, 9830
	ld (xix + 2), a
	ldda16 xwa, 10415
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
	and a, 0xF
	or a, 0x80
	ld (xix), a
	ldda8 a, 4012
	ld (xix + 1), a
	xor wa, wa
	ld (xix + 5), wa
	stdi8 4323, 0

VoiceParam_NullRet2:
	ret

LABEL_F25560:
	ld xiy, 0x11F9

LABEL_F25565:
	bitm 7, (xiy)
	jrl z, ToneGen_LoopAdvanceCheck
	ld a, (xiy)
	and a, 0xF
	ldda8 l, 4011
	and l, 0xF
	cp a, l
	jrl nz, ToneGen_LoopAdvanceCheck
	ldda8 l, 4012
	cp (xiy + 1), l
	jrl nz, ToneGen_LoopAdvanceCheck
	andmi8 (xiy), 0x7F
	ld ix, (xiy + 2)
	ld hl, (xiy + 3)
	and ix, 0xFF
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
	lda_dri3 XWA, 0x07, 0xEC, 0xF0
	pop xhl
	push_sd16w 0xAF, 0x28
	push_sd16w 0x66, 0x26
	stda16 10415, xhl
	stda16 9830, xix
	pushw wa
	call ToneGen_AdvanceBlockPosition
	popw wa
	ldda16 xix, 9830
	ldda32 xhl, 4349
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	popw_dd16 0x66, 0x26
	popw_dd16 0xAF, 0x28
	jrl LABEL_F255F1

ToneGen_LoopAdvanceCheck:
	add iy, 0x7
	cp xiy, 0x12D9
	jrl ule, LABEL_F25565

LABEL_F255F1:
	ret

; Voice parameter command dispatcher
; Dispatches on DRAM[4012] value: <0x10 uses read-update table, others are direct handlers
VoiceParam_CommandDispatch:
	ldda8 a, 4012
	cp a, 0x10
	jrl c, VoiceParam_ReadUpdateDispatch
	cp a, 0x20
	jrl z, LABEL_F25667
	cp a, 0x26
	jrl z, LABEL_F2566E
	cp a, 0x40
	jrl z, LABEL_F25675
	cp a, 0x42
	jrl z, LABEL_F2567C
	cp a, 0x43
	jrl z, LABEL_F25683
	cp a, 0x5B
	jrl z, LABEL_F2568A
	cp a, 0x5D
	jrl z, LABEL_F25691
	cp a, 0x60
	jrl z, LABEL_F25698
	cp a, 0x61
	jrl z, LABEL_F2569F
	cp a, 0x62
	jrl z, Scoop_CmdAlt_ReleaseVoiceSlot
	cp a, 0x63
	jrl z, Scoop_CmdAlt_ReleaseVoiceSlot
	cp a, 0x64
	jrl z, LABEL_F256B4
	cp a, 0x65
	jrl z, LABEL_F256AD
	jrl VoiceParam_NullRet

; Dispatch via VoiceParam_ReadUpdate_Table (16-entry, call (xhl))
; Index: DRAM[4012] (0x00-0x0F), 32-bit function pointers
VoiceParam_ReadUpdateDispatch:
	ld l, a
	xor h, h
	sla l, 2
	extz xhl
	push xix
	ld xix, 0xF256B9
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	call (xhl)
	jrl VoiceParam_NullRet

LABEL_F25667:
	call LABEL_F262A5
	jrl VoiceParam_NullRet

LABEL_F2566E:
	call LABEL_F262BE
	jrl VoiceParam_NullRet

LABEL_F25675:
	call LABEL_F2631A
	jrl VoiceParam_NullRet

LABEL_F2567C:
	call LABEL_F25EE6
	jrl VoiceParam_NullRet

LABEL_F25683:
	call LABEL_F25EE7
	jrl VoiceParam_NullRet

LABEL_F2568A:
	call LABEL_F26347
	jrl VoiceParam_NullRet

LABEL_F25691:
	call LABEL_F2636D
	jrl VoiceParam_NullRet

LABEL_F25698:
	call VoiceChannel_SelectNextParam
	jrl VoiceParam_NullRet

LABEL_F2569F:
	call VoiceChannel_SelectPrevParam
	jrl VoiceParam_NullRet

Scoop_CmdAlt_ReleaseVoiceSlot:
	call VoiceChannel_ClearChannelFlags
	jrl VoiceParam_NullRet

LABEL_F256AD:
	call VoiceChannel_NoteOnByChannel
	jrl VoiceParam_NullRet

LABEL_F256B4:
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

LABEL_F256F9:
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xF
	push xiy
	call SoundGen_ReadVoiceRegs
	ldda8 w, 4011
	and w, 0xF
	ldb a, 0xE0
	or a, w
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullRet3
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

LABEL_F2577A:
	ldda16 xiy, 4011
	and iy, 0xF
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	and iy, 0xF
	bitda 0, 4236
	jrl nz, LABEL_F2579E
	call VoiceChannel_ApplyParamByMode
	stdi8 4323, 0

LABEL_F2579E:
	cpdi8 4600, 0
	jr z, LABEL_F257B0
	cpdi8 4600, 2
	jrl z, LABEL_F258B4
	jrl LABEL_F259DF

LABEL_F257B0:
	push xix
	push xiy
	ldda16 xiy, 4011
	and iy, 0xF
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF25AA4
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xiy
	pop xix
	stda8 6748, l
	ld xwa, 0x1A57
	call SndParam_ApplyVoiceValue
	push xiy
	push xhl
	call SoundGen_ReadVoiceRegs
	pop xhl
	ldb a, 0xC0
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	and a, 0xF
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
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6747
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0
	jrl VoiceParam_NullReturn

LABEL_F258B4:
	push xix
	push xiy
	ldda16 xiy, 4011
	and iy, 0xF
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xF4
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF25AA4
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xiy
	pop xix
	stda8 6748, l
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1A57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, LABEL_F25922
	ld xhl, 0x1A37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

LABEL_F25922:
	push xiy
	push xhl
	call SoundGen_ReadVoiceRegs
	pop xhl
	ldb a, 0xC0
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
	ld xix, 0xFAE
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
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
	and a, 0xF
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
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 6747
	and a, 0x7F
	push xiy
	call SoundGen_UpdateAndRefresh
	pop xiy
	cpdi8 4323, 0
	jrl nz, VoiceParam_NullReturn
	call ToneGen_SetSustainBit
	call SoundGen_WriteVoiceParams
	stdi8 4323, 0
	jrl VoiceParam_NullReturn

LABEL_F259DF:
	push xiy
	call SoundGen_ReadVoiceRegs
	ldb a, 0xC0
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0xF72
	ld_srib3 W, 0x07, 0xF0, 0xF4
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
	jrl nz, VoiceParam_NullReturn
	ldda8 a, 4011
	and a, 0xF
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
	and iy, 0xF
	ld xix, 0xF82
	ld_srib3 A, 0x07, 0xF0, 0xF4
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

LABEL_F25AA4:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x0f, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x09

SoundGen_ReadVoiceRegs:
	push xde
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	sla iy, 1
	ld xde, 0xC9E
	ld_sriw3 WA, 0x07, 0xE8, 0xF4
	stda16 10415, xwa
	srl iy, 1
	ld xde, 0xCBE
	ld_srib3 A, 0x07, 0xE8, 0xF4
	xor w, w
	stda16 9830, xwa
	pop xde
	ret

LABEL_F25AE3:
	push xix
	cps hl, 1
	jr ule, LABEL_F25AEA
	lds hl, 1

LABEL_F25AEA:
	ldda16 xwa, 9830
	ld xix, 0xF218
	lda_dri3 XBC, 0x07, 0xF0, 0xEC
	sla hl, 1
	ldda16 xwa, 10415
	ld xix, 0xF1F8
	st_dri3w WA, 0x07, 0xF0, 0xEC
	pop xix
	ret

VoiceChannel_ClearRegisters:
	dec 1, hl
	ld iy, hl
	muls_erpb 0xF4, 0x03
	push xix
	ld xix, 0xF250
	and_srib_im 0x07, 0xF0, 0xF4, 0x7F
	inc 1, iy
	stiw_dri 0x07, 0xF0, 0xF4, 0xFF, 0xFF
	ld xix, 0xCBE
	stib_dri 0x07, 0xF0, 0xEC, 0x05
	ld xix, 0xF218
	stib_dri 0x07, 0xF0, 0xEC, 0x05
	sla hl, 1
	ld xix, 0xC9E
	stiw_dri 0x07, 0xF0, 0xEC, 0xFF, 0xFF
	ld xix, 0xF1F8
	stiw_dri 0x07, 0xF0, 0xEC, 0xFF, 0xFF
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
	ldda16 xiy, 10415
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
	anddi8 10194, 254
	ldda16 xiy, 10198
	push xix
	ld xix, 0x17FA
	ld_srib3 C, 0x07, 0xF0, 0xF4
	pop xix
	cp c, 0x82
	jr z, LABEL_F25BAC
	cp c, 0x81
	jr nz, LABEL_F25BB3

LABEL_F25BAC:
	ordi8 10194, 1
	jr LABEL_F25BD5

LABEL_F25BB3:
	pushw bc
	push xix
	ld xix, 0x17FA
	nop
	call ToneGen_ValidateAndSelectVoice
	pop xix
	popw bc
	push xix
	ld xix, 0x17FA
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	stda8 10204, a
	stda16 10198, xiy

LABEL_F25BD5:
	ret

ToneGen_ValidateVoiceCh2:
	anddi8 10194, 253
	ldda16 xiy, 10202
	push xix
	ld xix, 0x18FA
	ld_srib3 B, 0x07, 0xF0, 0xF4
	pop xix
	cp b, 0x82
	jr z, LABEL_F25BF5
	cp b, 0x81
	jr nz, LABEL_F25BFC

LABEL_F25BF5:
	ordi8 10194, 2
	jr LABEL_F25C1E

LABEL_F25BFC:
	pushw bc
	push xix
	ld xix, 0x18FA
	nop
	call ToneGen_ValidateAndSelectVoice
	pop xix
	popw bc
	push xix
	ld xix, 0x18FA
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	stda8 10206, a
	stda16 10202, xiy

LABEL_F25C1E:
	ret

VoiceChannel_FindNextLoop:
	call VoiceChannel_FindNextValid
	bitda 0, 10194
	jr z, VoiceChannel_FindNextLoop
	ret

LABEL_F25C2A:
	cp c, 0x82
	jr nz, LABEL_F25C56
	ldda32 xhl, 4349
	stib_dri 0x07, 0xEC, 0xF0, 0x82
	stdi8 10194, 255
	ldda16 xwa, 3308
	stda16 10399, xwa
	xor wa, wa
	ldda8 a, 9860
	stda16 10365, xwa
	call LABEL_F268AF
	jr LABEL_F25C9E

LABEL_F25C56:
	ldda32 xhl, 4349
	stib_dri 0x07, 0xEC, 0xF0, 0x81
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xix
	ld xix, 0x17FA
	nop
	ldda16 xiy, 10198
	call ToneGen_ValidateAndSelectVoice
	stda16 10198, xiy
	call VoiceChannel_UpdateParamSet
	stda16 10198, xiy
	ld xix, 0x18FA
	nop
	ldda16 xiy, 10202
	call ToneGen_ValidateAndSelectVoice
	stda16 10202, xiy
	call ToneGen_ValidateVoiceCh2
	stda16 10202, xiy
	pop xix

LABEL_F25C9E:
	ret

ToneGen_AdvanceVoiceLoop:
	call ToneGen_AdvanceAndValidateVoice
	bitda 1, 10194
	jr z, ToneGen_AdvanceVoiceLoop
	ret

VoiceChannel_FindNextValid:
	ldda32 xhl, 4349
	lda_dri3 XHL, 0x07, 0xEC, 0xF0
	bitda 0, 10194
	jr nz, VoiceChannel_ValidateAndLoop
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	ldda8 a, 10204
	lda_dri3 XBC, 0x07, 0xEC, 0xF0

VoiceChannel_ValidateAndLoop:
	push xix
	ld xix, 0x17FA
	nop
	ldda16 xiy, 10198
	call ToneGen_ValidateAndSelectVoice
	stda16 10198, xiy
	pop xix
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xde
	ld xde, 0x17FA
	bit_dri 7, 0x07, 0xE8, 0xF4
	pop xde
	jr nz, LABEL_F25D07
	push xde
	ld xde, 0x17FA
	ld_srib3 A, 0x07, 0xE8, 0xF4
	pop xde
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	jr VoiceChannel_ValidateAndLoop

LABEL_F25D07:
	stda16 10198, xiy
	call VoiceChannel_UpdateParamSet
	ret

VoiceChannel_ClearParamTable:
	ld xix, 0x1073
	xor wa, wa
	lds bc, 4

LABEL_F25D19:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F25D19
	ret

LABEL_F25D20:
	ldda16 xiy, 10198
	ld xix, 0x17FA
	inc 1, iy
	cp iy, 0xFF
	jr ule, VoiceChannel_StorePosition_Continue
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr nz, LABEL_F25D41
	stdi8 10362, 2
	jr VoiceChannel_StorePosition_Continue

LABEL_F25D41:
	cpda16 xwa, 10349
	jr ule, LABEL_F25D4E
	stdi8 10362, 10
	jr VoiceChannel_StorePosition_Continue

LABEL_F25D4E:
	stda16 10415, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, LABEL_F25D67
	stdi8 10362, 11
	jr VoiceChannel_StorePosition_Continue

LABEL_F25D67:
	ldda16 xhl, 10415
	call ToneGen_CopyBlockToVoiceBuffer
	lds iy, 5

VoiceChannel_StorePosition_Continue:
	stda16 10198, xiy
	ret

ToneGen_WriteParamToBlock:
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda16 xiy, 9830
	and iy, 0xFF
	extz xiy
	addda32 xiy, 4349
	ld (xiy), a
	ret

ToneGen_AdvancePosition:
	ldda16 xwa, 9830
	cp wa, 0xFF
	jr nz, LABEL_F25DAE
	cpdi16 62001, 0
	jr nz, LABEL_F25DA8
	stdi8 4323, 255
	jr LABEL_F25DB9

LABEL_F25DA8:
	call ToneGen_DispatchAndLinkBlock
	jr LABEL_F25DB4

LABEL_F25DAE:
	inc 1, wa
	stda16 9830, xwa

LABEL_F25DB4:
	stdi8 4323, 0

LABEL_F25DB9:
	ret

LABEL_F25DBA:
	ldda16 xwa, 9830
	cp wa, 0xFF
	jr nz, LABEL_F25DD9
	cpdi16 62001, 0
	jr nz, LABEL_F25DD3
	stdi8 4323, 255
	jr LABEL_F25DE4

LABEL_F25DD3:
	call ToneGen_DispatchAndLinkBlock
	jr LABEL_F25DDF

LABEL_F25DD9:
	inc 1, wa
	stda16 9830, xwa

LABEL_F25DDF:
	stdi8 4323, 0

LABEL_F25DE4:
	ret

ToneGen_SetSustainBit:
	pushw bc
	ldda16 xiy, 4011
	and iy, 0xF
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
	cp wa, 0xFF
	jr nz, LABEL_F25E2A
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 10415, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	lds wa, 5
	jr LABEL_F25E2C

LABEL_F25E2A:
	inc 1, wa

LABEL_F25E2C:
	stda16 9830, xwa
	ret

LABEL_F25E31:
	ldda16 xiy, 4011
	and iy, 0xF
	extz xiy
	ldda8 a, 4013
	push xix
	ld xix, 0xF82
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix
	ret

LABEL_F25E4C:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x10B3
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xix
	cp l, 0xFF
	jr z, LABEL_F25EAB
	ld c, l
	xor h, h
	extz xhl
	sla hl, 2
	push xix
	ld xix, 0xF25EAC
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	ldda8 a, 4013
	xor b, b
	ld ix, bc
	extz xix
	push xiy
	ld xiy, 0xF25F89
	ld_srib3 E, 0x07, 0xF4, 0xF0
	pop xiy
	cp a, e
	jr ule, LABEL_F25E96
	ld a, e

LABEL_F25E96:
	cps c, 1
	jr nz, LABEL_F25EAB
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call VoiceChannel_LookupParams

LABEL_F25EAB:
	ret

LABEL_F25EAC:
	.byte 0x1b, 0x1a, 0x00, 0x00
	.byte 0xfb, 0x19, 0x00, 0x00
	.byte 0x0b, 0x1a, 0x00, 0x00

LABEL_F25EB8:
	bitda 0, 4236
	jr nz, LABEL_F25EC7
	call VoiceChannel_SetPanDirection
	stdi8 4323, 0

LABEL_F25EC7:
	stdi8 4233, 4
	xor a, a
	cpdi8 4013, 64
	jr c, LABEL_F25ED8
	or a, 0x8

LABEL_F25ED8:
	stda8 4234, a
	stdi8 4235, 8
	call VoiceChannel_UpdateWithPitch
	ret

LABEL_F25EE6:
	ret

LABEL_F25EE7:
	ret

LABEL_F25EE8:
	bitda 0, 4236
	jr nz, LABEL_F25EF7
	call VoiceChannel_SetParamByte7
	stdi8 4323, 0

LABEL_F25EF7:
	stdi8 4233, 7
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call VoiceChannel_UpdateWithPitch
	ret

LABEL_F25F0E:
	bitda 0, 4236
	jr nz, LABEL_F25F1D
	call VoiceChannel_MergeParamByte5
	stdi8 4323, 0

LABEL_F25F1D:
	stdi8 4233, 5
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call VoiceChannel_UpdateWithPitch
	ret

VoiceChannel_SelectNextParam:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x10B3
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	cp a, 0xFF
	jr z, LABEL_F25F88
	exts wa
	ld hl, wa
	extz xhl
	sla hl, 2
	push xix
	ld xix, 0xF25EAC
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	ld_srib3 A, 0x07, 0xEC, 0xF4
	inc 1, a
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, 0xF25F89
	ld_srib3 E, 0x07, 0xF4, 0xF0
	pop xiy
	cp a, e
	jr ule, LABEL_F25F7F
	ld a, e

LABEL_F25F7F:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call VoiceChannel_LookupParams

LABEL_F25F88:
	ret

LABEL_F25F89:
	.byte 0x0c, 0x7f, 0xff

VoiceChannel_SelectPrevParam:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x10B3
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	cp a, 0xFF
	jr z, LABEL_F25FCC
	exts wa
	ld hl, wa
	sla hl, 2
	push xix
	ld xix, 0xF25EAC
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	ld_srib3 A, 0x07, 0xEC, 0xF4
	cps a, 0
	jr z, LABEL_F25FC3
	dec 1, a

LABEL_F25FC3:
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call VoiceChannel_LookupParams

LABEL_F25FCC:
	ret

VoiceChannel_ClearChannelFlags:
	ldda8 c, 4011
	and c, 0xF
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ldda16 xde, 4239
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3C
	stda16 4239, xde
	ldto_werp DE, 0x3E
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ldda16 xde, 4241
	ld a, c
	rcf
	stcf_a_16 de
	ldto_berp A, 0x3C
	stda16 4241, xde
	ldto_werp DE, 0x3E
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10B3
	stib_dri 0x07, 0xF0, 0xF4, 0xFF
	pop xix
	ret

VoiceChannel_NoteOnByChannel:
	ldda16 xiy, 4011
	and iy, 0xF
	ldda8 a, 4013
	push xix
	ld xix, 0x1093
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix
	cp a, 0x7F
	jr z, LABEL_F26072
	ldda8 c, 4011
	and c, 0xF
	ldda16 xwa, 4239
	andda16 xwa, 4241
	ldfr_werp WA, 0x3E
	ld a, c
	scf
	xorcf_a_werp 0x3E
	jr nc, LABEL_F26067
	ldda16 xde, 4239
	ld a, c
	scf
	stcf_a_16 de
	stda16 4239, xde
	ldda16 xde, 4241
	ld a, c
	scf
	xorcf_a_16 de
	jr c, LABEL_F260A0

LABEL_F26067:
	pushw bc
	call SoundGen_LookupChannelBankParams
	popw bc
	cp a, 0xFF
	jr nz, LABEL_F260A0

LABEL_F26072:
	ldda8 c, 4011
	and c, 0xF
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10B3
	stib_dri 0x07, 0xF0, 0xF4, 0xFF
	xor c, c
	ld xix, 0x10C3
	lda_dri3 XHL, 0x07, 0xF0, 0xF4
	ld xix, 0x10D3
	lda_dri3 XHL, 0x07, 0xF0, 0xF4
	pop xix

LABEL_F260A0:
	ret

VoiceChannel_NoteOffByChannel:
	ldda16 xiy, 4011
	and iy, 0xF
	ldda8 a, 4013
	push xix
	ld xix, 0x10A3
	lda_dri3 XBC, 0x07, 0xF0, 0xF4
	pop xix
	cp a, 0x7F
	jr z, LABEL_F26107
	ldda8 c, 4011
	and c, 0xF
	ldda16 xwa, 4239
	andda16 xwa, 4241
	ldfr_werp WA, 0x3E
	ld a, c
	scf
	xorcf_a_werp 0x3E
	jr nc, LABEL_F260FC
	ldda16 xde, 4241
	ld a, c
	scf
	stcf_a_16 de
	stda16 4241, xde
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ldda16 xde, 4239
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, LABEL_F26135

LABEL_F260FC:
	pushw bc
	call SoundGen_LookupChannelBankParams
	popw bc
	cp a, 0xFF
	jr nz, LABEL_F26135

LABEL_F26107:
	ldda8 c, 4011
	and c, 0xF
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0x10B3
	stib_dri 0x07, 0xF0, 0xF4, 0xFF
	xor c, c
	ld xix, 0x10C3
	lda_dri3 XHL, 0x07, 0xF0, 0xF4
	ld xix, 0x10D3
	lda_dri3 XHL, 0x07, 0xF0, 0xF4
	pop xix

LABEL_F26135:
	ret

VoiceChannel_ApplyParamByMode:
	push xiy
	call VoiceChannel_GetParamBlock
	cpdi8 4600, 0
	jr z, LABEL_F2614D
	cpdi8 4600, 2
	jrl z, LABEL_F261A8
	jrl LABEL_F26229

LABEL_F2614D:
	push xix
	push xde
	xor de, de
	ldda8 e, 4011
	and e, 0xF
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF2436B
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6748, l
	pop xde
	pop xix
	push xiy
	ld xwa, 0x1A57
	call SndParam_ApplyVoiceValue
	pop xiy
	ldda8 l, 6746
	ldda8 h, 6747
	ld (xiy + 256), l
	ld (xiy + 1), h
	jrl LABEL_F26276

LABEL_F261A8:
	push xix
	push xde
	xor de, de
	ldda8 e, 4011
	and e, 0xF
	ld xix, 0xF82
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6743, l
	ld xix, 0xF72
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6744, l
	ldda8 l, 4012
	stda8 6745, l
	ld xix, 0xF2436B
	ld_srib3 L, 0x07, 0xF0, 0xE8
	stda8 6748, l
	pop xde
	pop xix
	push xiy
	call VoiceChannel_StoreVoiceIdx
	ld xwa, 0x1A57
	call SndParam_LookupOscEnvelope
	cpdi16 6751, 9
	jr z, LABEL_F26218
	ld xhl, 0x1A37
	ldda16 xbc, 6751
	mul c, 0x2
	add xhl, xbc
	ldda8 a, 6746
	ld (xhl), a
	ldda8 a, 6747
	ld (xhl + 1), a

LABEL_F26218:
	pop xiy
	ldda8 l, 6746
	ldda8 h, 6747
	ld (xiy + 256), l
	ld (xiy + 1), h
	jr LABEL_F26276

LABEL_F26229:
	ldda8 a, 4012
	xor hl, hl
	ldda8 l, 4011
	and l, 0xF
	push xix
	ld xix, 0xF72
	ld_srib3 C, 0x07, 0xF0, 0xEC
	pop xix
	and c, 0x1
	rrc c
	and a, 0x7F
	or a, c
	ld (xiy + 256), a
	xor h, h
	ldda8 l, 4011
	and l, 0xF
	push xix
	ld xix, 0xF82
	ld_srib3 C, 0x07, 0xF0, 0xEC
	pop xix
	ld l, (xiy + 1)
	and l, 0x80
	and c, 0x70
	srl c, 4
	or l, c
	ld (xiy + 1), l

LABEL_F26276:
	pop xiy
	ret

SoundGen_WriteVoiceParams:
	push xde
	ldda16 xiy, 4237
	call SoundGen_ClampVoiceIndexMin1
	ldda16 xwa, 10415
	sla xiy, 1
	ld xde, 0xC9E
	st_dri3w WA, 0x07, 0xE8, 0xF4
	ldda16 xwa, 9830
	srl xiy, 1
	ld xde, 0xCBE
	lda_dri3 XBC, 0x07, 0xE8, 0xF4
	pop xde
	ret

LABEL_F262A5:
	ldda16 xiy, 4011
	and iy, 0xF
	ldda8 a, 4013
	push xde
	ld xde, 0xF82
	lda_dri3 XBC, 0x07, 0xE8, 0xF4
	pop xde
	ret

LABEL_F262BE:
	ldda16 xiy, 4011
	and iy, 0xF
	push xix
	ld xix, 0x10B3
	ld_srib3 L, 0x07, 0xF0, 0xF4
	pop xix
	cp l, 0xFF
	jr z, LABEL_F26319
	ld c, l
	xor h, h
	sla hl, 2
	push xix
	ld xix, 0xF25EAC
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	pop xix
	ldda8 a, 4013
	xor b, b
	ld ix, bc
	push xiy
	ld xiy, 0xF25F89
	ld_srib3 E, 0x07, 0xF4, 0xF0
	pop xiy
	cp a, e
	jr ule, LABEL_F26304
	ld a, e

LABEL_F26304:
	cps c, 1
	jr nz, LABEL_F26319
	push xhl
	push xiy
	call VoiceChannel_GetCombinedStatus
	pop xiy
	pop xhl
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	call VoiceChannel_LookupParams

LABEL_F26319:
	ret

LABEL_F2631A:
	bitda 0, 4236
	jr nz, LABEL_F26329
	call VoiceChannel_SetPanDirection
	stdi8 4323, 0

LABEL_F26329:
	stdi8 4233, 4
	xor a, a
	cpdi8 4013, 64
	jr c, LABEL_F26339
	ldb a, 0x8

LABEL_F26339:
	stda8 4234, a
	stdi8 4235, 8
	call SoundGen_ClampUpdateVoice
	ret

LABEL_F26347:
	bitda 0, 4236
	jr nz, LABEL_F26356
	call VoiceChannel_SetParamByte7
	stdi8 4323, 0

LABEL_F26356:
	stdi8 4233, 7
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call SoundGen_ClampUpdateVoice
	ret

LABEL_F2636D:
	bitda 0, 4236
	jr nz, LABEL_F2637C
	call VoiceChannel_MergeParamByte5
	stdi8 4323, 0

LABEL_F2637C:
	stdi8 4233, 5
	ldda8 a, 4013
	stda8 4234, a
	stdi8 4235, 127
	call SoundGen_ClampUpdateVoice
	ret

ToneGen_AdvanceAndValidateVoice:
	ldda32 xhl, 4349
	lda_dri3 XDE, 0x07, 0xEC, 0xF0
	bitda 1, 10194
	jr nz, ToneGen_ValidateVoiceLoop
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	ldda8 a, 10206
	lda_dri3 XBC, 0x07, 0xEC, 0xF0

ToneGen_ValidateVoiceLoop:
	push xix
	ld xix, 0x18FA
	nop
	ldda16 xiy, 10202
	call ToneGen_ValidateAndSelectVoice
	stda16 10202, xiy
	pop xix
	call VoiceChannel_AdvanceIndex
	ldda32 xhl, 4349
	push xix
	ld xix, 0x18FA
	bit_dri 7, 0x07, 0xF0, 0xF4
	pop xix
	jr nz, LABEL_F263F0
	push xix
	ld xix, 0x18FA
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	lda_dri3 XBC, 0x07, 0xEC, 0xF0
	jr ToneGen_ValidateVoiceLoop

LABEL_F263F0:
	stda16 10202, xiy
	call ToneGen_ValidateVoiceCh2
	ret

VoiceSynth_Algo_SimpleStore:
	.byte 0xd1, 0xab, 0x0f, 0x25, 0xdd, 0xcc, 0x0f, 0x00
	.byte 0xc1, 0xad, 0x0f
	.ascii "!<Dr"
	.byte 0x0f
	.byte 0x00, 0x00, 0xf3, 0x07, 0xf0, 0xf4, 0x41, 0x5c
	.byte 0x0e
VoiceSynth_Algo_MultiPath:
	.byte 0xd1, 0xab, 0x0f, 0x25, 0xdd, 0xcc, 0x0f
	.byte 0x00, 0x3d, 0x1d, 0x47, 0x46, 0xf2, 0x21, 0xd1
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x6e, 0x43, 0xed, 0xec, 0x01, 0x3c
	.byte 0x44, 0xae, 0x0f, 0x00, 0x00, 0xd3, 0x07, 0xf0
	.byte 0xf4, 0x20, 0x5c, 0xed, 0xef, 0x01, 0x3d, 0x1d
	.byte 0x3b, 0x4c, 0xf2, 0x5d, 0x3d, 0x1d, 0xef, 0x4b
	.byte 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x6e
	.byte 0x1e, 0xc1, 0xad, 0x0f, 0x21, 0x3d, 0x1d, 0xef
	.byte 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00
	.byte 0x6e, 0x0d, 0x1d, 0xe5, 0x5d, 0xf2, 0x1d, 0x67
	.byte 0x4b, 0xf2, 0xf1, 0xe3, 0x10, 0x00, 0x00, 0x0e
VoiceSynth_Algo_Null:
	.byte 0x0e
VoiceSynth_Algo_ChannelConfig:
	.byte 0xd1, 0xab, 0x0f, 0x25, 0xdd, 0xcc, 0x0f
	.byte 0x00, 0x3c, 0x44, 0xb3, 0x10, 0x00, 0x00, 0xc3
	.byte 0x07, 0xf0, 0xf4, 0x27, 0x5c, 0xcf, 0xcf, 0xff
	.byte 0x66, 0x42, 0xcf, 0x8b, 0xce, 0xd6, 0xdb, 0xec
	.byte 0x02, 0x3c, 0x44, 0xac, 0x5e, 0xf2, 0x00, 0xe3
	.byte 0x07, 0xf0, 0xec, 0x23, 0x5c, 0xc1, 0xad, 0x0f
	.byte 0x21, 0xca, 0xd2, 0xd9, 0x8c, 0x3d, 0x45, 0x89
	.byte 0x5f, 0xf2, 0x00, 0xc3, 0x07, 0xf4, 0xf0, 0x25
	.byte 0x5d, 0xcd, 0xf1, 0x63, 0x02, 0xcd, 0x89, 0xcb
	.byte 0xd9, 0x6e, 0x08, 0x3b, 0x3d, 0x1d, 0x86, 0x69
	.byte 0xf2, 0x5d, 0x5b, 0xf3, 0x07, 0xec, 0xf4, 0x41
	.byte 0x1d, 0xcb, 0x69, 0xf2, 0x0e
VoiceSynth_Algo_ConditionalUpdate:
	; --- Main routine: bit test, store, conditional call (49 bytes) ---
	.byte 0xf1, 0x8c, 0x10, 0xc8			; bit 0, (0x108C)  [F1 prefix]
	jr nz, VoiceSynth_ConditionalUpdate_SetParams
	call 0xF26C9E
	stdi8	4323, 0
VoiceSynth_ConditionalUpdate_SetParams:
	stdi8	4233, 3
	ldda8	a, 4013
	.byte 0xc1, 0xf8, 0x11, 0x3f, 0x02		; cp (0x11F8), 0x02  [C1 prefix]
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
	.byte 0xd1, 0xab, 0x0f
	.byte 0x25, 0xdd, 0xcc, 0x0f, 0x00, 0xed, 0x12, 0x1d
	.byte 0x47, 0x46, 0xf2, 0x3d, 0x21, 0xb0, 0x1d, 0xef
	.byte 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00
	.byte 0x7e, 0x96, 0x00, 0xed, 0xec, 0x01, 0x3c, 0x44
	.byte 0xae, 0x0f, 0x00, 0x00, 0xd3, 0x07, 0xf0, 0xf4
	.byte 0x20, 0x5c, 0xed, 0xef, 0x01, 0x3d, 0x1d, 0x3b
	.byte 0x4c, 0xf2, 0x5d, 0x3d, 0x1d, 0xef, 0x4b, 0xf2
	.byte 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x6e, 0x71
	.byte 0xc1, 0xab, 0x0f, 0x27, 0xcf, 0xcc, 0x0f, 0xce
	.byte 0xd6, 0xeb, 0x12
	.byte 0x3c, 0x44, 0x5b, 0x43
	.byte 0xf2
	.byte 0x00, 0xc3, 0x07, 0xf0, 0xec, 0x21, 0xc1, 0xf8
	.byte 0x11, 0x3f, 0x01, 0x66, 0x0a, 0x44, 0x6b, 0x43
	.byte 0xf2, 0x00, 0xc3, 0x07, 0xf0, 0xec, 0x21, 0x5c
	.byte 0x3d, 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3
	.byte 0x10, 0x3f, 0x00, 0x6e, 0x3c, 0x21, 0x08, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x6e, 0x2d, 0xc1, 0xad, 0x0f, 0x21
	.byte 0x3d, 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3
	.byte 0x10, 0x3f, 0x00, 0x6e, 0x1c, 0x21, 0x7f, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x6e, 0x0d, 0x1d, 0xe5, 0x5d, 0xf2
	.byte 0x1d, 0x67, 0x4b, 0xf2, 0xf1, 0xe3, 0x10, 0x00
	.byte 0x00, 0x0e
VoiceSynth_Algo_PitchModulated:
	.byte 0xd1, 0xab, 0x0f, 0x25, 0xdd, 0xcc
	.byte 0x0f, 0x00, 0xed, 0x12, 0x3d, 0x1d, 0x47, 0x46
	.byte 0xf2, 0x21, 0xd3, 0x1d, 0xef, 0x4b, 0xf2, 0x5d
	.byte 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x6e, 0x4e, 0xed
	.byte 0xec, 0x01, 0x3c, 0x44, 0xae, 0x0f, 0x00, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xf4, 0x20, 0x5c, 0xed, 0xef
	.byte 0x01, 0x3d, 0x1d, 0x3b, 0x4c, 0xf2, 0x5d, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x6e, 0x29, 0xc1, 0xad, 0x0f, 0x21
	.byte 0xc1, 0xf8, 0x11, 0x3f, 0x02, 0x6e, 0x04, 0x1d
	.byte 0xff, 0x64, 0xf2, 0x3d, 0x1d, 0xef, 0x4b, 0xf2
	.byte 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x6e, 0x0d
	.byte 0x1d, 0xe5, 0x5d, 0xf2, 0x1d, 0x67, 0x4b, 0xf2
	.byte 0xf1, 0xe3, 0x10, 0x00, 0x00, 0x0e
VoiceSynth_Algo_DirectStore:
	.byte 0xd1, 0xab
	.byte 0x0f, 0x25, 0xdd, 0xcc, 0x0f, 0x00, 0xc1, 0xad
	.byte 0x0f
	.ascii "!<Dr"
	.byte 0x0f, 0x00, 0x00
	.byte 0xf3, 0x07, 0xf0, 0xf4, 0x41, 0x5c, 0x0e
VoiceSynth_Algo_PitchShift:
	.byte 0xd1
	.byte 0x8d, 0x10, 0x25, 0x1d, 0xa6, 0x47, 0xf2, 0xdd
	.byte 0xcc, 0x0f, 0x00, 0x3d, 0x1d, 0xb4, 0x5a, 0xf2
	.byte 0xc1, 0xab, 0x0f, 0x20, 0xc8, 0xcc, 0x0f, 0x21
	.byte 0xd0, 0xc8, 0xe1, 0x1d, 0xef, 0x4b, 0xf2, 0x5d
	.byte 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x6e, 0x43, 0xdd
	.byte 0xec, 0x01, 0x3c, 0x44, 0xae, 0x0f, 0x00, 0x00
	.byte 0xd3, 0x07, 0xf0, 0xf4, 0x20, 0x5c, 0xdd, 0xef
	.byte 0x01, 0x3d, 0x1d, 0x3b, 0x4c, 0xf2, 0x5d, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x6e, 0x1e, 0x3d, 0xc1, 0xad, 0x0f
	.byte 0x21, 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3
	.byte 0x10, 0x3f, 0x00, 0x6e, 0x0d, 0x1d, 0xe5, 0x5d
	.byte 0xf2, 0x1d, 0x78, 0x62, 0xf2, 0xf1, 0xe3, 0x10
	.byte 0x00, 0x00, 0x0e
VoiceParam_ReadUpdate_6:
	.byte 0xd1, 0xab, 0x0f, 0x25, 0xdd
	.byte 0xcc, 0x0f, 0x00, 0x3c, 0x44, 0xb3, 0x10, 0x00
	.byte 0x00, 0xc3, 0x07, 0xf0, 0xf4, 0x27, 0x5c, 0xcf
	.byte 0xcf, 0xff, 0x66, 0x42, 0xcf, 0x8b, 0xce, 0xd6
	.byte 0xdb, 0xec, 0x02, 0x3c, 0x44, 0xac, 0x5e, 0xf2
	.byte 0x00, 0xe3, 0x07, 0xf0, 0xec, 0x23, 0x5c, 0xc1
	.byte 0xad, 0x0f, 0x21, 0xca, 0xd2, 0xd9, 0x8c, 0x3d
	.byte 0x45, 0x89, 0x5f, 0xf2, 0x00, 0xc3, 0x07, 0xf4
	.byte 0xf0, 0x25, 0x5d, 0xcd, 0xf1, 0x63, 0x02, 0xcd
	.byte 0x89, 0xcb, 0xd9, 0x6e, 0x08, 0x3b, 0x2d, 0x1d
	.byte 0x86, 0x69, 0xf2, 0x4d, 0x5b, 0xf3, 0x07, 0xec
	.byte 0xf4, 0x41, 0x1d, 0xcb, 0x69, 0xf2, 0x0e
VoiceParam_ReadUpdate_7:
	.byte 0xf1
	.byte 0x8c, 0x10, 0xc8, 0x6e, 0x09, 0x1d, 0x9e, 0x6c
	.byte 0xf2, 0xf1, 0xe3, 0x10, 0x00, 0x00, 0xf1, 0x89
	.byte 0x10, 0x00, 0x03, 0xc1, 0xad, 0x0f, 0x21, 0xc1
	.byte 0xf8, 0x11, 0x3f, 0x02, 0x6e, 0x04, 0x1d, 0xff
	.byte 0x64, 0xf2, 0xf1, 0x8a, 0x10, 0x41, 0xf1, 0x8b
	.byte 0x10, 0x00, 0x7f, 0x1d, 0xe6, 0x6a, 0xf2, 0x0e
VoiceParam_ReadUpdate_10:
	.byte 0xd1, 0x8d, 0x10, 0x25, 0x1d, 0xa6, 0x47, 0xf2
	.byte 0xdd, 0xcc, 0x0f, 0x00, 0x1d, 0xb4, 0x5a, 0xf2
	.byte 0x3d, 0x21, 0xb0, 0x1d, 0xef, 0x4b, 0xf2, 0x5d
	.byte 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x7e, 0x7a, 0x00
	.byte 0xdd, 0xec, 0x01, 0x3c, 0x44, 0xae, 0x0f, 0x00
	.byte 0x00, 0xd3, 0x07, 0xf0, 0xf4, 0x20, 0x5c, 0xdd
	.byte 0xef, 0x01, 0x3d, 0x1d, 0x3b, 0x4c, 0xf2, 0x5d
	.byte 0x3d, 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3
	.byte 0x10, 0x3f, 0x00, 0x7e, 0x54, 0x00, 0xc1, 0xab
	.byte 0x0f, 0x21, 0xc9, 0xcc, 0x0f, 0x3d, 0x1d, 0xef
	.byte 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00
	.byte 0x7e, 0x3f, 0x00, 0x21, 0x08, 0x3d, 0x1d, 0xef
	.byte 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00
	.byte 0x7e, 0x2f, 0x00, 0xc1, 0xad, 0x0f, 0x21, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x7e, 0x1d, 0x00, 0x21, 0x7f, 0x3d
	.byte 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10
	.byte 0x3f, 0x00, 0x7e, 0x0d, 0x00, 0x1d, 0xe5, 0x5d
	.byte 0xf2, 0x1d, 0x78, 0x62, 0xf2, 0xf1, 0xe3, 0x10
	.byte 0x00, 0x00, 0x0e
VoiceParam_ReadUpdate_11:
	.byte 0xd1, 0x8d, 0x10, 0x25, 0x1d
	.byte 0xa6, 0x47, 0xf2, 0xdd, 0xcc, 0x0f, 0x00, 0x3d
	.byte 0x1d, 0xb4, 0x5a, 0xf2, 0xc1, 0xab, 0x0f, 0x20
	.byte 0xc8, 0xcc, 0x0f, 0x21, 0xf0, 0xc8, 0xe1, 0x1d
	.byte 0xef, 0x4b, 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f
	.byte 0x00, 0x7e, 0x50, 0x00, 0xed, 0xec, 0x01, 0x3c
	.byte 0x44, 0xae, 0x0f, 0x00, 0x00, 0xd3, 0x07, 0xf0
	.byte 0xf4, 0x20, 0x5c, 0xed, 0xef, 0x01, 0x3d, 0x1d
	.byte 0x3b, 0x4c, 0xf2, 0x5d, 0x3d, 0x1d, 0xef, 0x4b
	.byte 0xf2, 0x5d, 0xc1, 0xe3, 0x10, 0x3f, 0x00, 0x7e
	.byte 0x2a, 0x00, 0xc1, 0xad, 0x0f, 0x21, 0xc1, 0xf8
	.byte 0x11, 0x3f, 0x02, 0x6e, 0x04, 0x1d, 0xff, 0x64
	.byte 0xf2, 0x3d, 0x1d, 0xef, 0x4b, 0xf2, 0x5d, 0xc1
	.byte 0xe3, 0x10, 0x3f, 0x00, 0x7e, 0x0d, 0x00, 0x1d
	.byte 0xe5, 0x5d, 0xf2, 0x1d, 0x78, 0x62, 0xf2, 0xf1
	.byte 0xe3, 0x10, 0x00, 0x00, 0x0e

ToneGen_ValidateAndSelectVoice:
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	and iy, 0xFF
	inc 1, iy
	cp iy, 0xFF
	jr ugt, LABEL_F26868
	jr ToneGen_SaveVoiceState_Continue

LABEL_F26868:
	ld wa, (xix + 3)
	cp wa, 0xFFFF
	jr nz, LABEL_F26878
	stdi8 10362, 2
	jr ToneGen_SaveVoiceState_Continue

LABEL_F26878:
	cpda16 xwa, 10349
	jr ule, LABEL_F26885
	stdi8 10362, 10
	jr ToneGen_SaveVoiceState_Continue

LABEL_F26885:
	stda16 10415, xwa
	ld hl, wa
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, LABEL_F2689E
	stdi8 10362, 11
	jr ToneGen_SaveVoiceState_Continue

LABEL_F2689E:
	call VoiceChannel_CopyParamBlock

ToneGen_SaveVoiceState_Continue:
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	ret

LABEL_F268AF:
	push xiy
	push xiz
	ldda32 xiz, 4349
	ldfr_lerp XIZ, 0x38
	pop xiz
	push_lerp 0x38
	ldda16 xhl, 10365
	dec 1, hl
	ld wa, ix
	ld xiy, 0xF218
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	sla hl, 1
	ldda16 xwa, 10399
	ld xiy, 0xF1F8
	st_dri3w WA, 0x07, 0xF4, 0xEC
	pop_lerp 0x38
	push xiz
	ldto_lerp XIZ, 0x38
	stda32 4349, xiz
	pop xiz
	pop xiy
	ret

VoiceChannel_AdvanceIndex:

