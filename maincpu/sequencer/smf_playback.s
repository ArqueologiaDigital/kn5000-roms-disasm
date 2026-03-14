; ==========================================================================
; SMF (Standard MIDI File) Playback Routines
;
; Handles loading, parsing, and playback of SMF song data from the
; sequencer. Includes song bank management, track initialization,
; loop control, and floppy I/O integration for song loading.
;
; Key routines:
;   SMF_InitSongPlayback    - Initialize song playback state
;   SMF_LoadSongBank        - Load song bank data
;   SMF_ReadLoopWithRetry   - Main read loop with retry logic
; ==========================================================================

SMF_InitSongPlayback:
	call LABEL_F23005
	call LABEL_F23134
	call LABEL_F231D3
	call SMF_LoadSongBank
	call LABEL_F2309F
	ret

LABEL_F23005:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

LABEL_F2300B:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, LABEL_F2302F
	cp (xhl + 2), 0x3
	jr c, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

LABEL_F2302F:
	cp (xhl + 1), 0x1
	jr nz, LABEL_F2304F
	cp (xhl + 2), 0x0
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x2
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x5
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x7
	jr z, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

LABEL_F2304F:
	cp (xhl + 1), 0x2
	jr nz, LABEL_F2305D
	cp (xhl + 2), 0x3
	jr c, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

LABEL_F2305D:
	cp (xhl + 1), 0x4
	jr nz, SoundBank_NextEntry1
	jr SoundBank_NextEntry1

SoundBank_InitEntryDefaults:
	ld xwa, 0xB8
	add xwa, xde
	ldw (xwa), 0x1
	ld xwa, 0xBA
	add xwa, xde
	ldw (xwa), 0x2
	ld xwa, 0xBC
	add xwa, xde
	ld (xwa), 0x0
	ld xwa, 0xBF
	add xwa, xde
	ldw (xwa), 0x0

SoundBank_NextEntry1:
	popw bc
	inc 1, bc
	cp bc, 0xA
	jrl c, LABEL_F2300B
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

LABEL_F2309F:
	push xhl
	call LABEL_F230A6
	pop xhl
	ret

LABEL_F230A6:
	push xix
	push xde
	push xwa
	push xbc
	xor bc, bc

LABEL_F230AC:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x0	;	TODO: Fix ASL: LD XHL, 00000000h
	add xhl, xde
	xor iy, iy

LABEL_F230C4:
	ld xix, 0xF23124
	ld_srib3 A, 0x07, 0xF0, 0xF4
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	inc 1, iy
	cps iy, 7
	jr ule, LABEL_F230C4
	ldda8 a, 36458
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	ld xhl, 0x14
	add xhl, xde
	xor iy, iy

LABEL_F230EB:
	ld xix, 0xF2312C
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	st_dri3w WA, 0x07, 0xEC, 0xF4
	add iy, 0x2
	cp iy, 0x8
	jr c, LABEL_F230EB
	ld xix, 0x42
	add xix, xde
	xor wa, wa
	lds bc, 6

LABEL_F2310F:
	st_dpiw WA, 0xF1
	djnz xbc, LABEL_F2310F
	popw bc
	inc 1, bc
	cp bc, 0xA
	jrl c, LABEL_F230AC
	pop xbc
	pop xwa
	pop xde
	pop xix
	ret

LABEL_F23124:	.asciz "ZZZZ"
	.byte 0x01, 0x08, 0x00
	.byte 0x00, 0x00, 0x00, 0x01, 0x2e, 0x00, 0x20, 0x05

LABEL_F23134:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

LABEL_F2313A:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, LABEL_F2315E
	cp (xhl + 2), 0x4
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

LABEL_F2315E:
	cp (xhl + 1), 0x1
	jr nz, LABEL_F2316C
	cp (xhl + 2), 0x8
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

LABEL_F2316C:
	cp (xhl + 1), 0x2
	jr nz, LABEL_F2317A
	cp (xhl + 2), 0x5
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

LABEL_F2317A:
	cp (xhl + 1), 0x4
	jr nz, SoundBank_NextEntry2
	jr SoundBank_NextEntry2

SoundBank_CopyChData:
	pushw bc
	push xix
	push xiy
	lds bc, 6
	ld xix, 0x100
	add xix, xde
	ld xiy, 0xC1
	add xiy, xde
	cp (xiy), 0x20
	jr c, LABEL_F231A0
	ldir85
	jp LABEL_F231A7

LABEL_F231A0:
	ld xiy, 0xF2324B
	ldir85

LABEL_F231A7:
	ldw bc, 0xA
	ld xiy, 0xF23241
	ldir85
	lds bc, 6
	ld xix, 0xC1
	add xix, xde
	ld xiy, 0xF23241
	ldir85
	pop xiy
	pop xix
	popw bc

SoundBank_NextEntry2:
	popw bc
	inc 1, bc
	cp bc, 0xA
	jrl c, LABEL_F2313A
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

LABEL_F231D3:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

LABEL_F231D9:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, LABEL_F231FD
	cp (xhl + 2), 0x4
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

LABEL_F231FD:
	cp (xhl + 1), 0x1
	jr nz, LABEL_F2320B
	cp (xhl + 2), 0x8
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

LABEL_F2320B:
	cp (xhl + 1), 0x2
	jr nz, LABEL_F23219
	cp (xhl + 2), 0x5
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

LABEL_F23219:
	cp (xhl + 1), 0x4
	jr nz, SoundBank_NextEntry3
	jr SoundBank_NextEntry3

SoundBank_StoreChParam:
	pushw bc
	push xix
	push xiy
	ld xix, 0x110
	add xix, xde
	ldw (xix), 0xFFFF
	pop xiy
	pop xix
	popw bc

SoundBank_NextEntry3:
	popw bc
	inc 1, bc
	cp bc, 0xA
	jrl c, LABEL_F231D9
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

LABEL_F23241:	.ascii "          ______"

LABEL_F23251:
	stda8 4599, a
	stda8 4600, c
	cpdi8 4600, 2
	jr nz, LABEL_F23264
	call LABEL_F232A1

LABEL_F23264:
	push xiz
	push xix
	push xde
	call SetWall_LoadBankToToneGen
	ldda8 a, 4599
	cpda8_24 a, 65507
	jrl z, LABEL_F23284
	ldda8 a, 4599
	st8_24 0x00ffe3, a
	call SoundBank_LoadToWorkRAM

LABEL_F23284:
	call LABEL_F23324
	anddi8 10417, 254
	pop xde
	pop xix
	pop xiz
	ldda16 xhl, 6699
	bit 15, hl
	jr nz, LABEL_F232A0
	cps hl, 1
	jr z, LABEL_F232A0
	set 15, hl

LABEL_F232A0:
	ret

LABEL_F232A1:
	push xbc
	push xhl
	push xix
	xor xbc, xbc

LABEL_F232A6:
	ld xix, 0x1A37
	ld xhl, xbc
	mul l, 0x2
	add xix, xhl
	ld (xix), 0x0
	ld (xix + 1), 0x0
	inc 1, bc
	cp bc, 0x10
	jr lt, LABEL_F232A6
	ld xix, 0x1A37
	ldw hl, 0x9
	mul l, 0x2
	add xix, xhl
	ld (xix), 0x0
	ld (xix + 1), 0x78
	pop xix
	pop xhl
	pop xbc
	ret

SoundBank_LoadToWorkRAM:
	ldda16 xwa, 61999
	stda16 10351, xwa
	ldda16 xwa, 62001
	stda16 10353, xwa
	xor xwa, xwa
	ld8_24 a, 0x00ffe3
	sla xwa, 11
	ld xiy, 0xAB000
	add xiy, xwa
	ld xix, 0xF180
	ldw bc, 0x800
	ldir85
	ldda16 xwa, 10351
	stda16 61999, xwa
	ldda16 xwa, 10353
	stda16 62001, xwa
	ldda16 xwa, 61854
	st16_24 0x00ffec, xwa
	xor wa, wa
	stda16 61854, xwa
	ret

LABEL_F23324:
	xor a, a
	stda8 4323, a
	stda8 4330, a
	stda8 3830, a
	stda8 4343, a
	call SeqTrack_ResetAllChannelSlots
	call SeqTrack_ScanActiveChannels
	call SeqTrack_ClearPlaybackBuffers
	call FileIO_ReadBlockToBuffer
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jrl lt, SeqPlay_ResetAndStop
	stdi16 6699, 1
	ld xwa, 0x13FA
	stda32 4376, xwa
	push xwa
	lds32 xwa, 0
	stda32 6883, xwa
	stdi8 6887, 0
	pop xwa

LABEL_F2336D:
	lds bc, 4
	ld xiy, 0xF236AF

LABEL_F23374:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp_spib A, 0xF4
	jrl z, LABEL_F233A9
	incdi8 1, 4343
	cpdi8 4343, 1
	jrl nz, LABEL_F233A0
	ld xwa, 0x13FA
	add xwa, 0x80
	stda32 4376, xwa
	jrl LABEL_F2336D

LABEL_F233A0:
	stdi16 6699, 49
	jrl SeqPlay_FloppyReady

LABEL_F233A9:
	djnz xbc, LABEL_F23374
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
	call FloppyIO_ReadNextByte
	stda8 3933, a
	call FloppyIO_ReadNextByte
	stda8 3932, a
	call FloppyIO_ReadNextByte
	stda8 3935, a
	call FloppyIO_ReadNextByte
	stda8 3934, a
	call FloppyIO_ReadNextByte
	stda8 3937, a
	bit 7, a
	jrl nz, SeqPlay_SetState48AndFloppyReady
	call FloppyIO_ReadNextByte
	stda8 3936, a
	cpdi16 3936, 0
	jrl nz, FloppyIO_WaitReadComplete
	stdi16 6699, 48
	jrl SeqPlay_FloppyReady

FloppyIO_WaitReadComplete:
	ldda32 xbc, 6883
	lds32 xwa, 0
	cp xbc, xwa
	jp_24 z, 0xF23436
	call FloppyIO_ReadNextByte
	nop
	nop
	nop
	jp FloppyIO_WaitReadComplete

LABEL_F23436:
	ldda8 a, 4600
	call SeqTrack_ClearPartParamBuffers
	cpdi16 3932, 0
	jrl z, FloppyIO_ReadAndValidateHeader
	cpdi16 3932, 1
	jrl nz, SeqPlay_SetState48AndFloppyReady
	cpdi16 3934, 1
	jrl z, FloppyIO_ReadAndValidateHeader
	call FloppyIO_SelectReadMode
	call FloppyIO_ConfigureSwitchboard
	call SeqPlay_PrepareAndScanChannels
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	cpdi8 3830, 0
	jrl z, SeqPlay_FinishFloppyLoadAndStart
	cpdi16 6699, 49
	jrl SeqPlay_ResetAndStop

FloppyIO_ReadAndValidateHeader:
	call FloppyIO_SelectReadMode
	call FloppyIO_ConfigureSwitchboard
	lds bc, 4
	ld xiy, 0xF236B3

LABEL_F2348D:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp_spib A, 0xF4
	jrl z, LABEL_F234A4
	stdi16 6699, 49
	jrl SeqPlay_FloppyReady

LABEL_F234A4:
	djnz xbc, LABEL_F2348D
	ld xix, 0xFA2
	lds bc, 4

LABEL_F234AE:
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
	jr lt, LABEL_F234C8
	pop xbc
	pop xwa
	jp LABEL_F234CE

LABEL_F234C8:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F234CE:
	lda_dpi XBC, 0xF0
	djnz xbc, LABEL_F234AE
	call SeqPlay_CheckStartConditions
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	stda16 61854, xwa
	st16_24 0x00ffec, xwa
	call SeqTrack_AssignFloppyChannels
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	cpdi8 3830, 0
	jrl nz, SeqPlay_ResetAndStop
	call SoundGen_InitAllVoiceChannels
	stdi8 4236, 0

SMF_ReadLoopWithRetry:
	call FloppyIO_ReadToTrackBuffer
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F2351A
	pop xbc
	pop xwa
	jp LABEL_F23520

LABEL_F2351A:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F23520:
	call SeqTrack_DispatchPartEvt
	xor xiy, xiy

LABEL_F23526:
	push xiy
	call SeqTrack_ComputeTempoScaling
	pop xiy
	inc 1, xiy
	cp xiy, 0xF
	jrl ule, LABEL_F23526
	call SeqTrack_UpdateChannelVolumes
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23551
	pop xbc
	pop xwa
	jp LABEL_F23557

LABEL_F23551:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F23557:
	cp a, 0xFF
	jrl nz, LABEL_F2359B
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23573
	pop xbc
	pop xwa
	jp LABEL_F23579

LABEL_F23573:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F23579:
	cpdi8 4009, 255
	jrl z, LABEL_F2358C
	cpdi8 4323, 0
	jrl z, SMF_ReadLoopWithRetry
	jrl Sequencer_ResetAfterFloppyIO

LABEL_F2358C:
	call Voice_ActivateAllChannels
	call SoundGen_ScanActiveVoiceBitmap
	call FloppyIO_ReturnReady
	jrl SeqPlay_FinishFloppyLoadAndStart

LABEL_F2359B:
	cp a, 0xF7
	jrl z, LABEL_F235A7
	cp a, 0xF0
	jrl nz, LABEL_F235C6

LABEL_F235A7:
	call SMF_ProcessSysExBlock
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F235BD
	pop xbc
	pop xwa
	jp LABEL_F235C3

LABEL_F235BD:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F235C3:
	jrl SMF_ReadLoopWithRetry

LABEL_F235C6:
	bit 7, a
	jrl z, LABEL_F235F3
	call SMF_ReadMidiEventToBuffer
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F235E2
	pop xbc
	pop xwa
	jp LABEL_F235E8

LABEL_F235E2:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F235E8:
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

LABEL_F235F3:
	call FloppyIO_ReadMidiEventBytes
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, LABEL_F23609
	pop xbc
	pop xwa
	jp LABEL_F2360F

LABEL_F23609:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

LABEL_F2360F:
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

