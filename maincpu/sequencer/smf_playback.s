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
	call SoundBank_InitDefaultParams
	call SoundBank_CopyChannelData
	call SoundBank_InitPlaybackFlags
	call SMF_LoadSongBank
	call SoundBank_InitTrackParams
	ret

SoundBank_InitDefaultParams:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

SoundBank_InitDefaults_Loop:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, SoundBank_InitDefaults_Type1
	cp (xhl + 2), 0x3
	jr c, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

SoundBank_InitDefaults_Type1:
	cp (xhl + 1), 0x1
	jr nz, SoundBank_InitDefaults_Type2
	cp (xhl + 2), 0x0
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x2
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x5
	jr z, SoundBank_InitEntryDefaults
	cp (xhl + 2), 0x7
	jr z, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

SoundBank_InitDefaults_Type2:
	cp (xhl + 1), 0x2
	jr nz, SoundBank_InitDefaults_Type4
	cp (xhl + 2), 0x3
	jr c, SoundBank_InitEntryDefaults
	jr SoundBank_NextEntry1

SoundBank_InitDefaults_Type4:
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
	jrl c, SoundBank_InitDefaults_Loop
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

SoundBank_InitTrackParams:
	push xhl
	call SoundBank_InitTrackParams_Inner
	pop xhl
	ret

SoundBank_InitTrackParams_Inner:
	push xix
	push xde
	push xwa
	push xbc
	xor bc, bc

SoundBank_InitTrack_Loop:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x0	;	TODO: Fix ASL: LD XHL, 00000000h
	add xhl, xde
	xor iy, iy

SoundBank_InitTrack_ByteFields:
	ld xix, 0xF23124
	ld_srib3 A, 0x07, 0xF0, 0xF4
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	inc 1, iy
	cps iy, 7
	jr ule, SoundBank_InitTrack_ByteFields
	ldda8 a, 36458
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	ld xhl, 0x14
	add xhl, xde
	xor iy, iy

SoundBank_InitTrack_WordFields:
	ld xix, 0xF2312C
	ld_sriw3 WA, 0x07, 0xF0, 0xF4
	st_dri3w WA, 0x07, 0xEC, 0xF4
	add iy, 0x2
	cp iy, 0x8
	jr c, SoundBank_InitTrack_WordFields
	ld xix, 0x42
	add xix, xde
	xor wa, wa
	lds bc, 6

SoundBank_InitTrack_ClearTail:
	st_dpiw WA, 0xF1
	djnz xbc, SoundBank_InitTrack_ClearTail
	popw bc
	inc 1, bc
	cp bc, 0xA
	jrl c, SoundBank_InitTrack_Loop
	pop xbc
	pop xwa
	pop xde
	pop xix
	ret

SoundBank_DefaultTrackData:	.asciz "ZZZZ"
	normal
	ldio	0, 0
	nop
	nop
	normal
	pushw	iz
	nop
	ldb	w, 5

SoundBank_CopyChannelData:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

SoundBank_CopyCh_Loop:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, SoundBank_CopyCh_Type1
	cp (xhl + 2), 0x4
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

SoundBank_CopyCh_Type1:
	cp (xhl + 1), 0x1
	jr nz, SoundBank_CopyCh_Type2
	cp (xhl + 2), 0x8
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

SoundBank_CopyCh_Type2:
	cp (xhl + 1), 0x2
	jr nz, SoundBank_CopyCh_Type4
	cp (xhl + 2), 0x5
	jr nc, SoundBank_NextEntry2
	jr SoundBank_CopyChData

SoundBank_CopyCh_Type4:
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
	jr c, SoundBank_CopyCh_FromDefault
	ldir85
	jp SoundBank_CopyCh_InitRemaining

SoundBank_CopyCh_FromDefault:
	ld xiy, 0xF2324B
	ldir85

SoundBank_CopyCh_InitRemaining:
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
	jrl c, SoundBank_CopyCh_Loop
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

SoundBank_InitPlaybackFlags:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

SoundBank_InitFlags_Loop:
	pushw bc
	ld xde, 0xAB000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4	;	TODO: Fix ASL: LD XHL, 00000004h:32
	add xhl, xde
	cp (xhl + 1), 0x0
	jr nz, SoundBank_InitFlags_Type1
	cp (xhl + 2), 0x4
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

SoundBank_InitFlags_Type1:
	cp (xhl + 1), 0x1
	jr nz, SoundBank_InitFlags_Type2
	cp (xhl + 2), 0x8
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

SoundBank_InitFlags_Type2:
	cp (xhl + 1), 0x2
	jr nz, SoundBank_InitFlags_Type4
	cp (xhl + 2), 0x5
	jr nc, SoundBank_NextEntry3
	jr SoundBank_StoreChParam

SoundBank_InitFlags_Type4:
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
	jrl c, SoundBank_InitFlags_Loop
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

SoundBank_DefaultNamePadding:	.ascii "          ______"

SMF_SelectBankAndLoad:
	stda8 4599, a
	stda8 4600, c
	cpdi8 4600, 2
	jr nz, SMF_SelectBank_AfterReset
	call SMF_ResetMidiChannelMap

SMF_SelectBank_AfterReset:
	push xiz
	push xix
	push xde
	call SetWall_LoadBankToToneGen
	ldda8 a, 4599
	cpda8_24 a, 65507
	jrl z, SMF_SelectBank_AfterToneLoad
	ldda8 a, 4599
	st8_24 0x00ffe3, a
	call SoundBank_LoadToWorkRAM

SMF_SelectBank_AfterToneLoad:
	call SMF_InitSequencerState
	anddi8 10417, 254
	pop xde
	pop xix
	pop xiz
	ldda16 xhl, 6699
	bit 15, hl
	jr nz, SMF_SelectBank_Return
	cps hl, 1
	jr z, SMF_SelectBank_Return
	set 15, hl

SMF_SelectBank_Return:
	ret

SMF_ResetMidiChannelMap:
	push xbc
	push xhl
	push xix
	xor xbc, xbc

SMF_ResetMidiChanMap_Loop:
	ld xix, 0x1A37
	ld xhl, xbc
	mul l, 0x2
	add xix, xhl
	ld (xix), 0x0
	ld (xix + 1), 0x0
	inc 1, bc
	cp bc, 0x10
	jr lt, SMF_ResetMidiChanMap_Loop
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

SMF_InitSequencerState:
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

SMF_ReadMThd_Start:
	lds bc, 4
	ld xiy, 0xF236AF

SMF_ReadMThd_ByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp_spib A, 0xF4
	jrl z, SMF_ReadMThd_Matched
	incdi8 1, 4343
	cpdi8 4343, 1
	jrl nz, SMF_ReadMThd_Mismatch
	ld xwa, 0x13FA
	add xwa, 0x80
	stda32 4376, xwa
	jrl SMF_ReadMThd_Start

SMF_ReadMThd_Mismatch:
	stdi16 6699, 49
	jrl SeqPlay_FloppyReady

SMF_ReadMThd_Matched:
	djnz xbc, SMF_ReadMThd_ByteLoop
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

SMF_AfterFloppyWait:
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

SMF_ReadMTrk_ByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp_spib A, 0xF4
	jrl z, SMF_ReadMTrk_Matched
	stdi16 6699, 49
	jrl SeqPlay_FloppyReady

SMF_ReadMTrk_Matched:
	djnz xbc, SMF_ReadMTrk_ByteLoop
	ld xix, 0xFA2
	lds bc, 4

SMF_ReadTrackData_Loop:
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
	jr lt, SMF_ReadTrackData_FloppyErr
	pop xbc
	pop xwa
	jp SMF_ReadTrackData_Continue

SMF_ReadTrackData_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_ReadTrackData_Continue:
	lda_dpi XBC, 0xF0
	djnz xbc, SMF_ReadTrackData_Loop
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
	jr lt, SMF_MainLoop_FloppyErr1
	pop xbc
	pop xwa
	jp SMF_MainLoop_DispatchEvents

SMF_MainLoop_FloppyErr1:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_MainLoop_DispatchEvents:
	call SeqTrack_DispatchPartEvt
	xor xiy, xiy

SMF_TempoScaling_Loop:
	push xiy
	call SeqTrack_ComputeTempoScaling
	pop xiy
	inc 1, xiy
	cp xiy, 0xF
	jrl ule, SMF_TempoScaling_Loop
	call SeqTrack_UpdateChannelVolumes
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_MainLoop_FloppyErr2
	pop xbc
	pop xwa
	jp SMF_CheckMetaEvent

SMF_MainLoop_FloppyErr2:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_CheckMetaEvent:
	cp a, 0xFF
	jrl nz, SMF_CheckSysEx
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_MetaEvent_FloppyErr
	pop xbc
	pop xwa
	jp SMF_MetaEvent_CheckResult

SMF_MetaEvent_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_MetaEvent_CheckResult:
	cpdi8 4009, 255
	jrl z, SMF_ActivateVoicesAndFinish
	cpdi8 4323, 0
	jrl z, SMF_ReadLoopWithRetry
	jrl Sequencer_ResetAfterFloppyIO

SMF_ActivateVoicesAndFinish:
	call Voice_ActivateAllChannels
	call SoundGen_ScanActiveVoiceBitmap
	call FloppyIO_ReturnReady
	jrl SeqPlay_FinishFloppyLoadAndStart

SMF_CheckSysEx:
	cp a, 0xF7
	jrl z, SMF_ProcessSysEx
	cp a, 0xF0
	jrl nz, SMF_CheckMidiStatus

SMF_ProcessSysEx:
	call SMF_ProcessSysExBlock
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_SysEx_FloppyErr
	pop xbc
	pop xwa
	jp SMF_SysEx_ContinueLoop

SMF_SysEx_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_SysEx_ContinueLoop:
	jrl SMF_ReadLoopWithRetry

SMF_CheckMidiStatus:
	bit 7, a
	jrl z, SMF_RunningStatus_Read
	call SMF_ReadMidiEventToBuffer
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_MidiEvent_FloppyErr
	pop xbc
	pop xwa
	jp SMF_MidiEvent_CheckResult

SMF_MidiEvent_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_MidiEvent_CheckResult:
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

SMF_RunningStatus_Read:
	call FloppyIO_ReadMidiEventBytes
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
	cp xwa, xbc
	jr lt, SMF_RunningStatus_FloppyErr
	pop xbc
	pop xwa
	jp SMF_RunningStatus_CheckResult

SMF_RunningStatus_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_RunningStatus_CheckResult:
	cpdi8 4323, 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

