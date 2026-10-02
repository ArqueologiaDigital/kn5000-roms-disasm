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
	ld xde, 0xab000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4
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
	ld xwa, 0xb8
	add xwa, xde
	ldw (xwa), 0x1
	ld xwa, 0xba
	add xwa, xde
	ldw (xwa), 0x2
	ld xwa, 0xbc
	add xwa, xde
	ld (xwa), 0x0
	ld xwa, 0xbf
	add xwa, xde
	ldw (xwa), 0x0

SoundBank_NextEntry1:
	popw bc
	inc 1, bc
	cp bc, 0xa
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
	ld xde, 0xab000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x0
	add xhl, xde
	xor iy, iy

SoundBank_InitTrack_ByteFields:
	ld xix, SoundBank_DefaultTrackData
	ld	a, (xix+iy)
	ld	(xhl+iy), a
	inc 1, iy
	cp iy, 7:i3
	jr ule, SoundBank_InitTrack_ByteFields
	ld a, (0x8e6a:16)
	ld	(xhl+iy), a
	ld xhl, 0x14
	add xhl, xde
	xor iy, iy

SoundBank_InitTrack_WordFields:
	ld xix, SoundBank_InitTrack_WordFields_Data
	ld	wa, (xix+iy)
	ld	(xhl+iy), wa
	add iy, 0x2
	cp iy, 0x8
	jr c, SoundBank_InitTrack_WordFields
	ld xix, 0x42
	add xix, xde
	xor wa, wa
	ld bc, 6:i3

SoundBank_InitTrack_ClearTail:
	ld (xix+), WA
	djnz16 bc, SoundBank_InitTrack_ClearTail
	popw bc
	inc 1, bc
	cp bc, 0xa
	jrl c, SoundBank_InitTrack_Loop
	pop xbc
	pop xwa
	pop xde
	pop xix
	ret

; 16-byte default image of the head of each of the 10 bank records at DRAM
; 0xAB000 + 0x800*k.  Read by SoundBank_InitTrack_ByteFields (0xF230C4):
; bytes +0..+7 ("ZZZZ", 0, 1, 8, 0) are copied to record +0..+7 (IY = 0..7,
; ld A,(XIX+IY) / ld (XHL+IY),A), then record +8 gets the byte at 0x8E6A;
; SoundBank_InitTrack_WordFields copies the four LE16 words at +8 (via
; SoundBank_InitTrack_WordFields_Data) to record +0x14..+0x1B.  TYPED 2026-09-25
; (lane seqeng): bytes +5..+15 were spelled normal / ld (0:8),0:io / nop /
; nop / normal / pushw iz / nop / ld w,5.
SoundBank_DefaultTrackData:	.asciz "ZZZZ"
	.byte 0x01, 0x08, 0x00
SoundBank_InitTrack_WordFields_Data:
	.short 0x0000, 0x0100, 0x002e, 0x0520

SoundBank_CopyChannelData:
	push xhl
	push xde
	push xwa
	push xbc
	xor bc, bc

SoundBank_CopyCh_Loop:
	pushw bc
	ld xde, 0xab000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4
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
	ld bc, 6:i3
	ld xix, 0x100
	add xix, xde
	ld xiy, 0xc1
	add xiy, xde
	cp (xiy), 0x20
	jr c, SoundBank_CopyCh_FromDefault
	ldir85
	jp SoundBank_CopyCh_InitRemaining

SoundBank_CopyCh_FromDefault:
	ld xiy, SoundBank_DefaultNamePadding_0xA
	ldir85

SoundBank_CopyCh_InitRemaining:
	ldw bc, 0xa
	ld xiy, SoundBank_DefaultNamePadding
	ldir85
	ld bc, 6:i3
	ld xix, 0xc1
	add xix, xde
	ld xiy, SoundBank_DefaultNamePadding
	ldir85
	pop xiy
	pop xix
	popw bc

SoundBank_NextEntry2:
	popw bc
	inc 1, bc
	cp bc, 0xa
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
	ld xde, 0xab000
	xor xwa, xwa
	ld wa, bc
	sla xwa, 11
	add xde, xwa
	ld xhl, 0x4
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
	ldw (xix), 0xffff
	pop xiy
	pop xix
	popw bc

SoundBank_NextEntry3:
	popw bc
	inc 1, bc
	cp bc, 0xa
	jrl c, SoundBank_InitFlags_Loop
	pop xbc
	pop xwa
	pop xde
	pop xhl
	ret

; Default name text: 10 spaces then 6 underscores.  Read by
; SoundBank_CopyChData (0xF23182) with ldir: when record
; byte +0xC1 is below 0x20 (no name), the 6 underscores at +0x0A
; (SoundBank_DefaultNamePadding_0xA) go to record +0x100; then 10 spaces
; from +0 follow them, and 6 spaces from +0 go to record +0xC1.
SoundBank_DefaultNamePadding:	.ascii "          ______"

SMF_SelectBankAndLoad:
	ld (4599:16), a
	ld (4600:16), c
	cp (4600:16), 2
	jr nz, SMF_SelectBank_AfterReset
	call SMF_ResetMidiChannelMap

SMF_SelectBank_AfterReset:
	push xiz
	push xix
	push xde
	call SetWall_LoadBankToToneGen
	ld a, (4599:16)
	cp a, (0xffe3:24)
	jrl z, SMF_SelectBank_AfterToneLoad
	ld a, (4599:16)
	ld (0x00ffe3:24), a
	call SoundBank_LoadToWorkRAM

SMF_SelectBank_AfterToneLoad:
	call SMF_InitSequencerState
	and (0x28b1:16), 254
	pop xde
	pop xix
	pop xiz
	ld hl, (6699:16)
	bit 15, hl
	jr nz, SMF_SelectBank_Return
	cp hl, 1:i3
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
	ld xix, 0x1a37
	ld xhl, xbc
	mul l, 0x2
	add xix, xhl
	ld (xix), 0x0
	ld (xix + 1), 0x0
	inc 1, bc
	cp bc, 0x10
	jr lt, SMF_ResetMidiChanMap_Loop
	ld xix, 0x1a37
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
	ld wa, (0xf22f:16)
	ld (0x286f:16), wa
	ld wa, (0xf231:16)
	ld (0x2871:16), wa
	xor xwa, xwa
	ld a, (0x00ffe3:24)
	sla xwa, 11
	ld xiy, 0xab000
	add xiy, xwa
	ld xix, 0xf180
	ldw bc, 0x800
	ldir85
	ld wa, (0x286f:16)
	ld (0xf22f:16), wa
	ld wa, (0x2871:16)
	ld (0xf231:16), wa
	ld wa, (0xf19e:16)
	ld (0x00ffec:24), wa
	xor wa, wa
	ld (0xf19e:16), wa
	ret

SMF_InitSequencerState:
	xor a, a
	ld (4323:16), a
	ld (4330:16), a
	ld (3830:16), a
	ld (4343:16), a
	call SeqTrack_ResetAllChannelSlots
	call SeqTrack_ScanActiveChannels
	call SeqTrack_ClearPlaybackBuffers
	call FileIO_ReadBlockToBuffer
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jrl lt, SeqPlay_ResetAndStop
	ldw (6699:16), 1
	ld xwa, 0x13fa
	ld (4376:16), xwa
	push xwa
	ld xwa, 0:i3
	ld (6883:16), xwa
	ld (6887:16), 0
	pop xwa

SMF_ReadMThd_Start:
	ld bc, 4:i3
	ld xiy, SMF_HeaderMagic_MThdMTrk

SMF_ReadMThd_ByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp A, (xiy+)
	jrl z, SMF_ReadMThd_Matched
	inc 1, (4343:16)
	cp (4343:16), 1
	jrl nz, SMF_ReadMThd_Mismatch
	ld xwa, 0x13fa
	add xwa, 0x80
	ld (4376:16), xwa
	jrl SMF_ReadMThd_Start

SMF_ReadMThd_Mismatch:
	ldw (6699:16), 49
	jrl SeqPlay_FloppyReady

SMF_ReadMThd_Matched:
	djnz16 bc, SMF_ReadMThd_ByteLoop
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
	call FloppyIO_ReadNextByte
	ld (3933:16), a
	call FloppyIO_ReadNextByte
	ld (3932:16), a
	call FloppyIO_ReadNextByte
	ld (3935:16), a
	call FloppyIO_ReadNextByte
	ld (3934:16), a
	call FloppyIO_ReadNextByte
	ld (3937:16), a
	bit 7, a
	jrl nz, SeqPlay_SetState48AndFloppyReady
	call FloppyIO_ReadNextByte
	ld (3936:16), a
	cpw (3936:16), 0
	jrl nz, FloppyIO_WaitReadComplete
	ldw (6699:16), 48
	jrl SeqPlay_FloppyReady

FloppyIO_WaitReadComplete:
	ld xbc, (6883:16)
	ld xwa, 0:i3
	cp xbc, xwa
	jp z, (SMF_AfterFloppyWait:24)
	call FloppyIO_ReadNextByte
	nop
	nop
	nop
	jp FloppyIO_WaitReadComplete

SMF_AfterFloppyWait:
	ld a, (4600:16)
	call SeqTrack_ClearPartParamBuffers
	cpw (3932:16), 0
	jrl z, FloppyIO_ReadAndValidateHeader
	cpw (3932:16), 1
	jrl nz, SeqPlay_SetState48AndFloppyReady
	cpw (3934:16), 1
	jrl z, FloppyIO_ReadAndValidateHeader
	call FloppyIO_SelectReadMode
	call FloppyIO_ConfigureSwitchboard
	call SeqPlay_PrepareAndScanChannels
	cp (4323:16), 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	cp (3830:16), 0
	jrl z, SeqPlay_FinishFloppyLoadAndStart
	cpw (6699:16), 49
	jrl SeqPlay_ResetAndStop

FloppyIO_ReadAndValidateHeader:
	call FloppyIO_SelectReadMode
	call FloppyIO_ConfigureSwitchboard
	ld bc, 4:i3
	ld xiy, SMF_HeaderMagic_MThdMTrk_0x4

SMF_ReadMTrk_ByteLoop:
	pushw bc
	push xiy
	call FloppyIO_ReadNextByte
	pop xiy
	popw bc
	cp A, (xiy+)
	jrl z, SMF_ReadMTrk_Matched
	ldw (6699:16), 49
	jrl SeqPlay_FloppyReady

SMF_ReadMTrk_Matched:
	djnz16 bc, SMF_ReadMTrk_ByteLoop
	ld xix, 0xfa2
	ld bc, 4:i3

SMF_ReadTrackData_Loop:
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
	jr lt, SMF_ReadTrackData_FloppyErr
	pop xbc
	pop xwa
	jp SMF_ReadTrackData_Continue

SMF_ReadTrackData_FloppyErr:
	pop xbc
	pop xwa
	jp SeqPlay_ResetAndStop

SMF_ReadTrackData_Continue:
	ld (xix+), a
	djnz16 bc, SMF_ReadTrackData_Loop
	call SeqPlay_CheckStartConditions
	call SeqPlay_RestoreVoiceState_Return
	xor wa, wa
	ld (0xf19e:16), wa
	ld (0x00ffec:24), wa
	call SeqTrack_AssignFloppyChannels
	cp (4323:16), 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	cp (3830:16), 0
	jrl nz, SeqPlay_ResetAndStop
	call SoundGen_InitAllVoiceChannels
	ld (4236:16), 0

SMF_ReadLoopWithRetry:
	call FloppyIO_ReadToTrackBuffer
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	cp xiy, 0xf
	jrl ule, SMF_TempoScaling_Loop
	call SeqTrack_UpdateChannelVolumes
	call FloppyIO_ReadNextByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	cp a, 0xff
	jrl nz, SMF_CheckSysEx
	call SMF_ParseTrackEvent
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	cp (4009:16), 255
	jrl z, SMF_ActivateVoicesAndFinish
	cp (4323:16), 0
	jrl z, SMF_ReadLoopWithRetry
	jrl Sequencer_ResetAfterFloppyIO

SMF_ActivateVoicesAndFinish:
	call Voice_ActivateAllChannels
	call SoundGen_ScanActiveVoiceBitmap
	call FloppyIO_ReturnReady
	jrl SeqPlay_FinishFloppyLoadAndStart

SMF_CheckSysEx:
	cp a, 0xf7
	jrl z, SMF_ProcessSysEx
	cp a, 0xf0
	jrl nz, SMF_CheckMidiStatus

SMF_ProcessSysEx:
	call SMF_ProcessSysExBlock
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	cp (4323:16), 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

SMF_RunningStatus_Read:
	call FloppyIO_ReadMidiEventBytes
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
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
	cp (4323:16), 0
	jrl nz, Sequencer_ResetAfterFloppyIO
	jrl SMF_ReadLoopWithRetry

