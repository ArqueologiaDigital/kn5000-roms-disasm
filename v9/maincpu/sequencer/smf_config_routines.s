; =============================================================================
; SMF Configuration
; =============================================================================
;
; SMF (Standard MIDI File) configuration and parameter setup.
; Manages playback settings, channel assignments, and tempo.
; =============================================================================

SMF_ProcessTimedEvent_Entry:
	ld l, (4215:16)

SMF_ProcessTimedEvent_Continue:
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
	jr lt, SMF_WriteLoop1_BufferEmpty
	pop xbc
	pop xwa
	jp SMF_WriteLoop1_Continue

SMF_WriteLoop1_BufferEmpty:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteLoop1_Continue:
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteLoop2_BufferEmpty
	pop xbc
	pop xwa
	jp SMF_WriteLoop2_Continue

SMF_WriteLoop2_BufferEmpty:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_WriteLoop2_Continue:
	jrl SMF_ProcessEventLoop

SMF_ProcessEventLoop_Entry:
	jrl SMF_ProcessEventLoop

SMF_IncrementPosition:
	push xwa
	push xde
	incw 1, (3946:16)
	ld wa, (3946:16)
	ldw de, 0x60
	mul xwa, xde
	stw_erp DE, 0xe2
	add (3938:16), wa
	ld (3940:16), de
	ldw (3946:16), 0
	pop xde
	pop xwa
	ld c, 0x0:opc
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_IncrPos_BufferEmpty
	pop xbc
	pop xwa
	jp SMF_IncrPos_WriteEndMarker

SMF_IncrPos_BufferEmpty:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_IncrPos_WriteEndMarker:
	ld a, 0xff:opc
	ld w, 0x2f:opc
	ld l, 0x0:opc
	call SMF_WriteByteLoop
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_EndMarker_BufferEmpty
	pop xbc
	pop xwa
	jp SMF_EndMarker_CheckPlayback

SMF_EndMarker_BufferEmpty:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_EndMarker_CheckPlayback:
	cpw (4347:16), 0
	jr nz, SMF_FinalizeAndStartPlayback
	call SMF_FlushToFile
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_Flush_BufferEmpty
	pop xbc
	pop xwa
	jp SMF_FinalizeAndStartPlayback

SMF_Flush_BufferEmpty:
	pop xbc
	pop xwa
	jp SMF_FlushAndFinalize

SMF_FinalizeAndStartPlayback:
	call SMF_CheckAndFlush
	call Vga_RestoreMultiPlaneDisplay
	ld a, (4599:16)
	ld (0x00ffe3:24), a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay
	ldw (6699:16), 2

SMF_Finalize_PopReturn:
	jr SMF_PopReturn

SMF_Finalize_RestoreAndPlay:
	call Vga_RestoreMultiPlaneDisplay
	ld a, (4599:16)
	ld (0x00ffe3:24), a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay
	jr SMF_PopReturn

; ============================================================================
; SMF_FlushAndFinalize - Flush pending SMF data and finalize channel
; ============================================================================
; Saves current SMF write position (stda16 6699, xhl), then calls timer/
; interrupt setup and SMF output finalization routines. All 65 call sites
; are tail-calls (JP) from channel processing when data has been consumed.
; This is the "done processing this channel" exit path.
; ============================================================================
SMF_FlushAndFinalize:
	push xhl
	ld xhl, (6701:16)
	ld (6699:16), hl
	pop xhl
	call Vga_RestoreMultiPlaneDisplay
	ld a, (4599:16)
	ld (0x00ffe3:24), a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay
	jr SMF_PopReturn

SMF_PopReturn:
	popw wa
	ret

SMF_HeaderConstants:
	nop
	swi 7
	pop sr
	rcf
	.asciz "MThd"
	nop
	nop
	ei	0
	nop
	nop
	normal
	nop
	.asciz "`MTrk"
	nop
	.byte 0x00, 0x00, 0x36, 0x00, 0x6a, 0x00, 0x50, 0x00
	.byte 0xec, 0x00, 0x06, 0x01, 0x20, 0x01, 0x3a, 0x01
	.byte 0x54, 0x01, 0x9e, 0x00, 0xb8, 0x00, 0xd2, 0x00
	.byte 0x84, 0x00, 0xbc, 0x01, 0xff, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0xff, 0xff, 0x6e, 0x01, 0x88, 0x01
	.byte 0xa2, 0x01, 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09
	.byte 0x01, 0xf7, 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09
	.byte 0x02, 0xf7, 0x00, 0x02, 0x01, 0x07, 0x08, 0x09
	.byte 0x0a, 0x0b, 0x04, 0x05, 0x06, 0x03, 0x0f, 0x7f
	.byte 0x7f, 0x7f, 0x7f, 0x0c, 0x0d, 0x0e

SMF_ScanChannels:
	xor xhl, xhl
	xor bc, bc

SMF_ScanChannels_Loop:
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_ScanChannels_Inactive
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xec
	pop xde
	jr z, SMF_ScanChannels_Inactive
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	cp a, 0x10
	jr z, SMF_ScanChannels_Inactive
	ld (0x2877:16), c
	push xhl
	pushw bc
	call SMF_DispatchEvent
	popw bc
	pop xhl
	jr SMF_ScanChannels_Next

SMF_ScanChannels_Inactive:
	ld (0x2877:16), c
	inc 1, (0x2877:16)
	push xhl
	pushw bc
	call Scoop_SpecialMode_ParamCheckBound
	popw bc
	pop xhl

SMF_ScanChannels_Next:
	add l, 0x3
	inc 1, c
	cp c, 0xf
	jr ule, SMF_ScanChannels_Loop
	ret

SMF_CountActiveChannels:
	xor xhl, xhl
	xor bc, bc

SMF_CountActive_Loop:
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	jr c, SMF_CountActive_Next
	xor wa, wa
	ld a, c
	sla a, 1
	add a, c
	ld iy, wa
	push xde
	ld xde, 0xf250
	bit_dri 7, 0x07, 0xe8, 0xf4
	pop xde
	jr z, SMF_CountActive_Next
	inc 1, l

SMF_CountActive_Next:
	inc 1, c
	cp c, 0xf
	jr ule, SMF_CountActive_Loop
	cp l, 2:i3
	jrl c, SMF_AssignReturn
	xor bc, bc

SMF_FindFreeChannel:
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	jr nc, SMF_FindFree_CheckPart

SMF_FindFree_Next:
	inc 1, c
	cp c, 0xf
	jr ule, SMF_FindFreeChannel

SMF_FindFree_CheckPart:
	ld l, c
	sla l, 1
	add l, c
	xor h, h
	push xix
	ld xix, 0xf250
	bit_dri 7, 0x07, 0xf0, 0xec
	pop xix
	jr z, SMF_FindFree_Next
	xor xhl, xhl
	ld l, c
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xec, 0x10
	pop xix
	jr z, SMF_FindFree_Next
	inc 1, c
	ld (0x2877:16), l
	inc 1, (0x2877:16)

SMF_AssignRemainingChannels:
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	jr c, SMF_AssignRemaining_Next
	xor b, b
	ld iz, bc
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf8, 0x10
	pop xix
	jr z, SMF_AssignRemaining_Next
	ld (9858:16), c
	inc 1, (9858:16)
	ld a, (0x2877:16)
	ld (9860:16), a
	push xhl
	pushw bc
	call SetWall_ValidateAndApply
	popw bc
	pop xhl

SMF_AssignRemaining_Next:
	inc 1, c
	cp c, 0xf
	jr ule, SMF_AssignRemainingChannels

SMF_AssignReturn:
	ret

SMF_ClearWorkArea:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ld xix, 0x11f9
	ldw bc, 0x100

SMF_ClearWork_Loop:
	stw_dpi WA, 0xf1
	djnz xbc, SMF_ClearWork_Loop
	pop xix
	popw bc
	popw wa
	ret

SMF_CalcTempoRate:
	ldw de, 0x9
	ldw wa, 0x27c0
	ldw_erp DE, 0xe2
	div xwa, xhl
	stw_erp DE, 0xe2
	ldw hl, 0x64
	xor de, de
	extz xwa
	muls xwa, xhl
	stw_erp DE, 0xe2
	ld (3948:16), wa
	ld (3950:16), de
	ret

SMF_OutputCommandSeq:
	ld xiy, 0x106e
	ld xix, (4376:16)

SMF_OutputCmd_ReadByte:
	ldb_spi A, 0xf4
	lda_dpi XBC, 0xf0
	pushw wa
	push xiy
	call SMF_WriteByte
	pop xiy
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck1
	pop xbc
	pop xwa
	jp SMF_OutputCmd_SendFF

SMF_OutputCmd_ErrorCheck1:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_SendFF:
	ld xix, (4376:16)
	bit 7, a
	jr nz, SMF_OutputCmd_ReadByte
	ld a, 0xff:opc
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck2
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Send51

SMF_OutputCmd_ErrorCheck2:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_Send51:
	ld xix, (4376:16)
	ld a, 0x51:opc
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck3
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Send03

SMF_OutputCmd_ErrorCheck3:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_Send03:
	ld xix, (4376:16)
	ld a, 0x3:opc
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck4
	pop xbc
	pop xwa
	jp SMF_OutputCmd_SendTempoH

SMF_OutputCmd_ErrorCheck4:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_SendTempoH:
	ld xix, (4376:16)
	ld a, (3950:16)
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck5
	pop xbc
	pop xwa
	jp SMF_OutputCmd_SendTempoM

SMF_OutputCmd_ErrorCheck5:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_SendTempoM:
	ld xix, (4376:16)
	ld a, (3949:16)
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck6
	pop xbc
	pop xwa
	jp SMF_OutputCmd_SendTempoL

SMF_OutputCmd_ErrorCheck6:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_SendTempoL:
	ld xix, (4376:16)
	ld a, (3948:16)
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_OutputCmd_ErrorCheck7
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Finalize

SMF_OutputCmd_ErrorCheck7:
	pop xbc
	pop xwa
	jp SMF_OutputCmd_Return

SMF_OutputCmd_Finalize:
	ld xix, (4376:16)

SMF_OutputCmd_Return:
	ret

SMF_WriteByte:
	push xhl
	pushw bc
	push xwa
	xor xwa, xwa
	ld xwa, 2:i3
	ld (6701:16), xwa
	pop xwa
	cp xix, 0x17f9
	jr ugt, SMF_WriteByte_SectorCheck
	ld (4376:16), xix
	jr SMF_WriteByte_Done

SMF_WriteByte_SectorCheck:
	cpw (4347:16), 0
	jr nz, SMF_WriteByte_NewSector
	ld c, a
	pushw bc
	call SMF_FlushToFile
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteByte_SectorError
	pop xbc
	pop xwa
	jp SMF_WriteByte_SectorOK

SMF_WriteByte_SectorError:
	pop xbc
	pop xwa
	jp SMF_WriteByte_Done

SMF_WriteByte_SectorOK:
	jr SMF_WriteByte_AllocSector

SMF_WriteByte_NewSector:
	ld c, a
	incw 1, (4327:16)
	pushw wa
	push xhl
	pushw bc
	pushw de
	ld wa, (4327:16)
	xor de, de
	ld hl, 4:i3
	ldw_erp DE, 0xe2
	div xwa, xhl
	stw_erp DE, 0xe2
	cp de, 0:i3
	jr nz, SMF_WriteByte_AlignCheck

SMF_WriteByte_AlignCheck:
	popw de
	popw bc
	pop xhl
	popw wa
	pushw bc
	call SMF_FileWriteAndClear
	popw bc
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteByte_AlignError
	pop xbc
	pop xwa
	jp SMF_WriteByte_AllocSector

SMF_WriteByte_AlignError:
	pop xbc
	pop xwa
	jp SMF_WriteByte_Done

SMF_WriteByte_AllocSector:
	incw 1, (4347:16)
	ld xwa, 0x13fa
	ld (4376:16), xwa
	ld xix, xwa
	ld a, c

SMF_WriteByte_Done:
	popw bc
	pop xhl
	ret

SMF_WriteByteLoop:
	push xiy
	ld xix, (4376:16)
	ld xiy, 0x106e
	pushw wa

SMF_WriteLoop_ReadByte:
	ldb_spi A, 0xf4
	lda_dpi XBC, 0xf0
	pushw wa
	pushw hl
	push xiy
	call SMF_WriteByte
	pop xiy
	popw hl
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteLoop_Error
	pop xbc
	pop xwa
	jp SMF_WriteLoop_Continue

SMF_WriteLoop_Error:
	pop xbc
	pop xwa
	popw wa
	jp SMF_WriteLoop_Done

SMF_WriteLoop_Continue:
	ld xix, (4376:16)
	bit 7, a
	jr nz, SMF_WriteLoop_ReadByte
	popw wa
	ld h, a
	lda_dpi XBC, 0xf0
	pushw wa
	pushw hl
	call SMF_WriteByte
	popw hl
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteLoop_SendFF
	pop xbc
	pop xwa
	jp SMF_WriteLoop_AfterFF

SMF_WriteLoop_SendFF:
	pop xbc
	pop xwa
	jp SMF_WriteLoop_Done

SMF_WriteLoop_AfterFF:
	ld xix, (4376:16)
	ld a, w
	lda_dpi XBC, 0xf0
	pushw hl
	call SMF_WriteByte
	popw hl
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteLoop_Send51
	pop xbc
	pop xwa
	jp SMF_WriteLoop_After51

SMF_WriteLoop_Send51:
	pop xbc
	pop xwa
	jp SMF_WriteLoop_Done

SMF_WriteLoop_After51:
	ld xix, (4376:16)
	and h, 0xf0
	cp h, 0xc0
	jr z, SMF_WriteLoop_Done
	cp h, 0xd0
	jr z, SMF_WriteLoop_Done
	ld a, l
	lda_dpi XBC, 0xf0
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (6701:16)
	cp xwa, xbc
	jr lt, SMF_WriteLoop_FinalError
	pop xbc
	pop xwa
	jp SMF_WriteLoop_Done

SMF_WriteLoop_FinalError:
	pop xbc
	pop xwa
	jp SMF_WriteLoop_Done

SMF_WriteLoop_Done:
	pop xiy
	ld xix, (4376:16)
	ret

SMF_ChannelHelperReturn:
	ret

SMF_GetNextEvent:
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld iy, (9830:16)
	ldb_sri A, 0x07, 0xec, 0xf4
	ret

SMF_AdvancePosition:
	ld wa, (9830:16)
	cp wa, 0xff
	jr nz, SMF_AdvancePos_Inc
	ld hl, (0x28af:16)
	call ToneGen_ComputeBlockPtr
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	ld (0x28af:16), wa
	ld wa, 5:i3
	jr SMF_AdvancePos_Store

SMF_AdvancePos_Inc:
	inc 1, wa

SMF_AdvancePos_Store:
	ld (9830:16), wa
	ret

SMF_CalcTimeDelta:
	pushw wa
	push xhl
	pushw de
	xor wa, wa
	ld (4229:16), wa
	ld (4231:16), a
	ld wa, (3938:16)
	xor b, b
	add wa, bc
	ld de, (3942:16)
	cp wa, de
	jr nc, SMF_TimeDelta_CheckFirst
	ld wa, de

SMF_TimeDelta_CheckFirst:
	sub wa, de
	ld (4229:16), wa
	bit 0, (4344:16)
	jr nz, SMF_TimeDelta_Store
	cp (6710:16), 0
	jr z, SMF_TimeDelta_Store
	addw (4229:16), 384
	ld (4344:16), 1

SMF_TimeDelta_Store:
	ld (3942:16), bc
	ld (3952:16), de
	popw de
	pop xhl
	popw wa
	call SMF_EncodeTimeDelta
	ret

SMF_ProcessChannels:
	push xwa
	xor xwa, xwa
	ld xwa, 2:i3
	ld (6701:16), xwa
	pop xwa
	call SMF_ClearOutputQueue
	xor hl, hl
	xor bc, bc
	xor iy, iy

SMF_ProcessCh_Loop:
	push xix
	ld xix, 0x11f9
	bit_dri 7, 0x07, 0xf0, 0xec
	pop xix
	jr z, SMF_ProcessCh_Next
	push xix
	ld xix, 0x11f9
	lda_dri XIX, 0x07, 0xf0, 0xec
	ld wa, (xix + 3)
	pop xix
	cp wa, (4229:16)
	jr ule, SMF_ProcessCh_MoveToOutput
	sub wa, (4229:16)
	push xix
	ld xix, 0x11f9
	extz xhl
	add xix, xhl
	ld (xix + 3), wa
	pop xix
	jr SMF_ProcessCh_Next

SMF_ProcessCh_MoveToOutput:
	push xde
	ld xde, 0xfae
	stb_dri C, 0x07, 0xe8, 0xf4
	ld xde, 0x11f9
	lda_dri XDE, 0x07, 0xe8, 0xec
	ld wa, (xde + 3)
	ld xde, 0xfae
	lda_dri XDE, 0x07, 0xe8, 0xf4
	ld (xde + 1), wa
	pop xde
	add iy, 0x3

SMF_ProcessCh_Next:
	add hl, 0x5
	inc 1, bc
	cp c, 0x20
	jr c, SMF_ProcessCh_Loop
	srl iy, 1
	cp iy, 0:i3
	jr z, SMF_ProcessCh_Finalize
	call SMF_SortOutputQueue

SMF_ProcessCh_Finalize:
	ldw (3938:16), 0
	ldw (3940:16), 0
	ret

SMF_SendChannelConfig:
	ld a, (4213:16)
	and a, 0xf
	or a, 0xb0
	call SMF_WriteByteLoop
	ret

SMF_FlushToFile:
	call SMF_FileWrite
	ret

SMF_CheckAndFlush:
	cpw (4347:16), 0
	jr z, SMF_CheckFlush_Return
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13fa
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	ld (6701:16), xhl
	pop xhl
	pop xbc
	pop xwa

SMF_CheckFlush_Return:
	ret

SMF_DispatchEvent:
	ld (4008:16), c
	xor b, b
	ld iy, bc
	and (4331:16), 254
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0f
	pop xix
	jr nz, SMF_Dispatch_CheckDrumMode
	or (4331:16), 1

SMF_Dispatch_CheckDrumMode:
	ld (4324:16), 0
	bit 2, (0xfdad:16)
	jrl z, SMF_Dispatch_NoDrumMode
	ld (4324:16), 255
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr nz, SMF_Dispatch_DrumChannel
	ld (4008:16), 9
	jrl SMF_HandleEventType

SMF_Dispatch_DrumChannel:
	cp iy, 0x9
	jrl nz, SMF_HandleEventType
	bit 0, (4331:16)
	jrl nz, SMF_HandleEventType
	push xix
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	xor xiy, xiy

SMF_Dispatch_DrumSearch:
	ld bc, iy
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xf4
	pop xix
	jr z, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr z, SMF_Dispatch_DrumFound
	inc 1, iy
	cp iy, 0xf
	jr ule, SMF_Dispatch_DrumSearch
	ld (4008:16), 127
	jrl SMF_HandleEventType

SMF_Dispatch_DrumFound:
	ld wa, iy
	ld (4008:16), a
	jr SMF_HandleEventType

SMF_Dispatch_NoDrumMode:
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr nz, SMF_Dispatch_Ch15Remap
	ld (4008:16), 15
	jr SMF_HandleEventType

SMF_Dispatch_Ch15Remap:
	cp iy, 0xf
	jr nz, SMF_HandleEventType
	bit 0, (4331:16)
	jr nz, SMF_HandleEventType
	push xix
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	xor xiy, xiy

SMF_Dispatch_Ch15Search:
	ld bc, iy
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xf4
	pop xix
	jr z, SMF_Dispatch_Ch15Found
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr z, SMF_Dispatch_Ch15Found
	inc 1, iy
	cp iy, 0xf
	jr ule, SMF_Dispatch_Ch15Search
	ld (4008:16), 127
	jr SMF_HandleEventType

SMF_Dispatch_Ch15Found:
	ld wa, iy
	ld (4008:16), a

SMF_HandleEventType:
	inc 1, hl
	push xde
	ld xde, 0xf250
	ldw_sri HL, 0x07, 0xe8, 0xec
	pop xde
	ld (0x28af:16), hl
	ldw (9830:16), 5
	calr SMF_GetNextEvent

SMF_EventType_Switch:
	cp a, 0x82
	jrl z, SMF_EventLoop_Return
	cp a, 0x84
	jr z, SMF_Event_NoteOff82
	cp a, 0xd0
	jr z, SMF_Event_PartD0
	cp a, 0xd1
	jr z, SMF_Event_PartD1
	cp a, 0xd2
	jr z, SMF_Event_PartD2
	cp a, 0xd3
	jr z, SMF_Event_PartD3
	cp a, 0x80
	jr z, SMF_Event_Part80
	and a, 0xf0
	cp a, 0x90
	jr z, SMF_Event_NoteOn
	cp a, 0xb0
	jrl z, SMF_Event_ControlChange
	cp a, 0xc0
	jr z, SMF_Event_ProgramChange
	jrl SMF_EventLoop_Continue

SMF_Event_NoteOff82:
	ld a, 0x82:opc
	calr SMF_LookupSongBank
	jrl SMF_EventLoop_Return

SMF_Event_PartD0:
	ld a, 0xa0:opc
	jr SMF_Event_OutputByte

SMF_Event_PartD1:
	ld a, 0xd0:opc
	jr SMF_Event_OutputByte

SMF_Event_PartD2:
	ld a, 0xe0:opc
	jr SMF_Event_OutputByte

SMF_Event_PartD3:
	ld a, 0xf0:opc
	jr SMF_Event_OutputByte

SMF_Event_Part80:
	ld a, 0xa0:opc
	jr SMF_Event_OutputByte

SMF_Event_NoteOn:
	ld a, 0x90:opc

SMF_Event_OutputByte:
	or a, (4008:16)
	pushw wa
	calr SMF_LookupSongBank
	popw wa
	and a, 0xf0
	cp a, 0x90
	jrl nz, SMF_EventLoop_Continue
	cp (4324:16), 0
	jrl z, SMF_EventLoop_Continue
	cp (4008:16), 9
	jrl nz, SMF_EventLoop_Continue
	jrl SMF_EventLoop_Continue

SMF_Event_ProgramChange:
	calr SMF_AdvanceMultipleEvents
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	calr SMF_AdvancePosition
	calr SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xaf, 0x28
	cp a, 0:i3
	jrl nz, SMF_EventLoop_Continue
	bit 0, (4331:16)
	jr z, SMF_ProgChg_UseDefault
	ld l, a
	push xhl
	calr SMF_GetNextEvent
	pop xhl
	ld e, (0x2877:16)
	xor d, d
	ld iy, de
	cp a, 0:i3
	jr c, SMF_ProgChg_NotFound
	cp a, 0xf
	jr ugt, SMF_ProgChg_NotFound
	cp l, 0:i3
	jr ugt, SMF_ProgChg_NotFound
	ld l, a
	xor h, h
	push xde
	ld xde, SMF_PartAssignTable
	ldb_sri A, 0x07, 0xe8, 0xec
	pop xde
	xor xhl, xhl

SMF_ProgChg_SearchPart:
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xec
	pop xix
	jr z, SMF_ProgChg_Found

SMF_ProgChg_SearchNext:
	inc 1, l
	cp l, 0xf
	jr ule, SMF_ProgChg_SearchPart

SMF_ProgChg_NotFound:
	ld a, 0x7f:opc
	jr SMF_ProgChg_Write

SMF_ProgChg_Found:
	ld c, l
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_ProgChg_SearchNext
	calr SMF_ResolveChannel
	jr SMF_ProgChg_Write

SMF_ProgChg_UseDefault:
	ld a, (4008:16)

SMF_ProgChg_Write:
	calr SMF_LookupSongBank
	jrl SMF_EventLoop_Continue

SMF_Event_ControlChange:
	calr SMF_AdvanceMultipleEvents
	push_sd16w 0xaf, 0x28
	push_sd16w 0x66, 0x26
	calr SMF_AdvancePosition
	calr SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xaf, 0x28
	ld l, a
	push xhl
	calr SMF_GetNextEvent
	pop xhl
	ld (4340:16), a
	cp a, 0:i3
	jr c, SMF_CtrlChg_NotFound
	cp a, 0xf
	jr ugt, SMF_CtrlChg_NotFound
	cp l, 3:i3
	jr c, SMF_CtrlChg_NotFound
	cp l, 0xb
	jr ugt, SMF_CtrlChg_NotFound
	cp l, 6:i3
	jr z, SMF_CtrlChg_NotFound
	jr SMF_CtrlChg_UseDefault
	bit 0, (4331:16)
	jr z, SMF_EventLoop_SpecialCC
	ld l, a
	xor h, h
	push xde
	ld xde, SMF_PartAssignTable
	ldb_sri A, 0x07, 0xe8, 0xec
	pop xde
	xor xhl, xhl

SMF_CtrlChg_SearchPart:
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xec
	pop xix
	jr z, SMF_CtrlChg_Found

SMF_CtrlChg_SearchNext:
	inc 1, l
	cp l, 0xf
	jr ule, SMF_CtrlChg_SearchPart

SMF_CtrlChg_NotFound:
	ld a, 0x7f:opc
	jr SMF_CtrlChg_Write

SMF_CtrlChg_Found:
	ld c, l
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_CtrlChg_SearchNext
	calr SMF_ResolveChannel
	jr SMF_CtrlChg_Write

SMF_CtrlChg_UseDefault:
	ld a, (4008:16)

SMF_CtrlChg_Write:
	calr SMF_LookupSongBank

SMF_EventLoop_Continue:
	calr SMF_AdvancePosition
	calr SMF_GetNextEvent
	bit 7, a
	jr z, SMF_EventLoop_Continue
	jrl SMF_EventType_Switch

SMF_EventLoop_SpecialCC:
	cp a, 0x50
	jr z, SMF_EventLoop_SkipCC
	cp a, 0x51
	jr nz, SMF_CtrlChg_UseDefault

SMF_EventLoop_SkipCC:
	jr SMF_EventLoop_Continue

SMF_EventLoop_Return:
	ret

SMF_PartAssignTable:
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0xff, 0x13
	.byte 0xff, 0x0c, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff

SMF_EncodeTimeDelta:
	ldw (4206:16), 0
	ldw (4208:16), 0
	cp (4231:16), 0
	jr nz, SMF_Encode_LargeValue
	cpw (4229:16), 127
	jrl ule, SMF_Encode_OneByte
	cpw (4229:16), 0x3fff
	jr ule, SMF_Encode_TwoBytes

SMF_Encode_LargeValue:
	cp (4231:16), 31
	jr ule, SMF_Encode_ThreeBytes
	ld (4231:16), 31
	ld (4230:16), 255
	ld (4229:16), 255

SMF_Encode_ThreeBytes:
	ld a, (4229:16)
	ld w, a
	and w, 0x80
	and a, 0x7f
	rlc w
	ld l, (4230:16)
	ld h, l
	and h, 0xc0
	rlc_i_8 h, 2
	sla l, 1
	and l, 0x1
	or l, w
	or l, 0x80
	ld c, (4231:16)
	sla c, 2
	or c, h
	or c, 0x80
	ld (4206:16), c
	ld (4207:16), l
	ld (4208:16), a
	jr SMF_Encode_Return

SMF_Encode_TwoBytes:
	ld a, (4229:16)
	ld w, a
	and a, 0x7f
	and w, 0x80
	rlc w
	ld l, (4230:16)
	ld h, l
	sla l, 1
	or l, w
	or l, 0x80
	xor c, c
	ld (4206:16), l
	ld (4207:16), a
	jr SMF_Encode_Return

SMF_Encode_OneByte:
	ld a, (4229:16)
	and a, 0x7f
	xor l, l
	xor c, c
	ld (4206:16), a

SMF_Encode_Return:
	ret

SMF_ClearOutputQueue:
	push xix
	ld xix, 0xfae
	ldw bc, 0x60
	ldw wa, 0xff

SMF_ClearQueue_Loop:
	lda_dpi XBC, 0xf0
	djnz xbc, SMF_ClearQueue_Loop
	pop xix
	ret

SMF_SortOutputQueue:
	cp iy, 0:i3
	jr z, SMF_Sort_Return
	xor de, de
	cp (4014:16), 255
	jr z, SMF_Sort_Return

SMF_Sort_OuterLoop:
	ld xiy, 0xfae
	ld xix, 0xfb1
	lda_dri XIY, 0x07, 0xf4, 0xe8
	lda_dri XIX, 0x07, 0xf0, 0xe8
	cp (xiy), 0xff
	jr z, SMF_Sort_Finalize
	ld wa, (xiy + 1)

SMF_Sort_InnerLoop:
	ld l, (xix)
	cp l, 0xff
	jr z, SMF_Sort_AdvanceOuter
	cp wa, (xix + 1)
	jr ugt, SMF_Sort_Swap
	add xix, 0x3
	cp xix, 0x100b
	jr ugt, SMF_Sort_AdvanceOuter
	jr SMF_Sort_InnerLoop

SMF_Sort_Swap:
	ld a, (xiy)
	ld l, (xix)
	ld (xiy), l
	ld (xix), a
	ld wa, (xiy + 1)
	ld hl, (xix + 1)
	ld (xiy + 1), hl
	ld (xix + 1), wa
	xor de, de
	jr SMF_Sort_OuterLoop

SMF_Sort_AdvanceOuter:
	add de, 0x3
	cp de, 0x60
	jr c, SMF_Sort_OuterLoop

SMF_Sort_Finalize:
	calr SMF_UpdateTempo

SMF_Sort_Return:
	ret

SMF_FileWrite:
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13fa
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	ld (6701:16), xhl
	pop xhl
	pop xbc
	pop xwa
	ret

SMF_FileWriteAndClear:
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13fa
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	ld (6701:16), xhl
	pop xhl
	pop xbc
	pop xwa
	call SMF_ClearFileBuffer
	ret

SMF_LookupSongBank:
	ld hl, (0x28af:16)
	extz xhl
	dec 1, xhl
	sla xhl, 8
	add xhl, (7514:16)
	ld iy, (9830:16)
	stb_dri A, 0x07, 0xec, 0xf4
	ret

SMF_AdvanceMultipleEvents:
	ld bc, 2:i3

SMF_AdvanceMulti_Loop:
	pushw bc
	calr SMF_AdvancePosition
	popw bc
	djnz xbc, SMF_AdvanceMulti_Loop
	calr SMF_GetNextEvent
	ret

SMF_ResolveChannel:
	xor h, h
	ld iy, hl
	cp (4324:16), 255
	jr nz, SMF_Resolve_NoDrum
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr nz, SMF_Resolve_DrumCh9
	ld a, 0x9:opc
	jrl SMF_Resolve_Return

SMF_Resolve_DrumCh9:
	cp iy, 0x9
	jrl nz, SMF_Resolve_Return
	push xix
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	xor xiy, xiy

SMF_Resolve_DrumSearch:
	ld bc, iy
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xf4
	pop xix
	jr z, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr z, SMF_Resolve_DrumFound
	inc 1, iy
	cp iy, 0xf
	jr ule, SMF_Resolve_DrumSearch
	ld a, 0x7f:opc
	jr SMF_Resolve_Return

SMF_Resolve_DrumFound:
	ld wa, iy
	jr SMF_Resolve_Return

SMF_Resolve_NoDrum:
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr nz, SMF_Resolve_Ch15Check
	ld a, 0xf:opc
	jr SMF_Resolve_Return

SMF_Resolve_Ch15Check:
	cp iy, 0xf
	jr nz, SMF_Resolve_Return
	push xix
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	pop xix
	xor xiy, xiy

SMF_Resolve_Ch15Search:
	ld bc, iy
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xf4
	pop xix
	jr z, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	pop xix
	jr z, SMF_Resolve_Ch15Found
	inc 1, iy
	cp iy, 0xf
	jr ule, SMF_Resolve_Ch15Search
	ld a, 0x7f:opc
	jr SMF_Resolve_Return

SMF_Resolve_Ch15Found:
	ld wa, iy
	jr SMF_Resolve_Return

SMF_Resolve_Return:
	ret

SMF_UpdateTempo:
	ld bc, (3942:16)
	ld xiy, 0xfae
	xor hl, hl

SMF_UpdateTempo_Loop:
	ldb_sri A, 0x07, 0xf4, 0xec
	cp a, 0xff
	jr z, SMF_UpdateTempo_Finalize
	xor w, w
	ld ix, wa
	extz xix
	sla ix, 2
	add ix, wa
	push xde
	ld xde, 0x11f9
	add xde, xix
	ld wa, (xde + 3)
	pop xde
	cp l, 0:i3
	jr nz, SMF_UpdateTempo_SubtractBase
	ld (4229:16), wa
	jr SMF_UpdateTempo_Encode

SMF_UpdateTempo_SubtractBase:
	ld de, wa
	sub de, (3942:16)
	cp de, 0:i3
	jr ge, SMF_UpdateTempo_ClampZero
	ld de, 0:i3

SMF_UpdateTempo_ClampZero:
	ld (4229:16), de

SMF_UpdateTempo_Encode:
	pushw wa
	push xhl
	pushw bc
	push xix
	calr SMF_EncodeTimeDelta
	pop xix
	popw bc
	pop xhl
	popw wa
	ld (3942:16), wa
	push xde
	ld xde, 0x11f9
	extz xix
	add xde, xix
	ld wa, (xde + 1)
	pop xde
	push xhl
	ld l, 0x0:opc
	pushw bc
	push xix
	calr SMF_WriteByteLoop
	pop xix
	popw bc
	pop xhl
	push xde
	ld xde, 0x11f9
	and_srib_im 0x07, 0xe8, 0xf0, 0x3f
	pop xde
	add hl, 0x3
	cp hl, 0x60
	jr nc, SMF_UpdateTempo_Finalize
	jr SMF_UpdateTempo_Loop

SMF_UpdateTempo_Finalize:
	ld wa, (3942:16)
	add wa, (3952:16)
	ld (3942:16), bc
	add bc, (3938:16)
	sub bc, wa
	ld (4229:16), bc
	calr SMF_EncodeTimeDelta
	ldw (3938:16), 0
	ldw (3940:16), 0
	ret

SMF_CalcFilePosition:
	xor wa, wa
	ld (4002:16), wa
	ld (4004:16), wa
	ld wa, (4347:16)
	mul wa, 0x400
	ld xhl, (4376:16)
	sub xhl, 0x13fa
	add xwa, xhl
	sub xwa, 0x16
	stw_erp DE, 0xe2
	ld (4002:16), d
	ld (4003:16), e
	ld (4004:16), w
	ld (4005:16), a
	ret

SMF_ClearFileBuffer:
	push xix
	push xwa
	ldw wa, 0x200
	ld xix, 0x13fa

SMF_ClearBuf_Loop:
	stiw_dsp 0xf1, 0x00, 0x00
	djnz xwa, SMF_ClearBuf_Loop
	pop xwa
	pop xix
	ret

SMF_ResolveGlobalChannel:
	push xix
	push xiy
	push xwa
	push xbc
	push xde
	xor iy, iy
	ld iy, (0x2877:16)
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	jr nz, SMF_GlobalCh_NoDrum

SMF_GlobalCh_DrumMode:
	cp (4324:16), 255
	jp nz, (SMF_GlobalCh_DrumCh15:24)
	ld (6881:16), 9
	jp SMF_GlobalCh_Return

SMF_GlobalCh_DrumCh15:
	ld (6881:16), 15
	jp SMF_GlobalCh_Return

SMF_GlobalCh_NoDrum:
	cp (4324:16), 255
	jp nz, (SMF_GlobalCh_NonDrumCh15:24)
	cp iy, 0x9
	jp z, (SMF_GlobalCh_FreeSearch:24)
	jp SMF_GlobalCh_Found

SMF_GlobalCh_NonDrumCh15:
	cp iy, 0xf
	jp z, (SMF_GlobalCh_FreeSearch:24)
	jp SMF_GlobalCh_Found

SMF_GlobalCh_FreeSearch:
	ld xix, 0xf1a0
	ldb_sri A, 0x07, 0xf0, 0xf4
	xor xiy, xiy

SMF_GlobalCh_SearchLoop:
	ld bc, iy
	ldb_erp A, 0x3c
	ldw_erp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	stw_erp DE, 0x3e
	stb_erp A, 0x3c
	jr c, SMF_GlobalCh_Found
	ld xix, 0xf1a0
	cpb_sri_mr A, 0x07, 0xf0, 0xf4
	jr z, SMF_GlobalCh_Found
	ld xix, 0xf1a0
	cpib_sri 0x07, 0xf0, 0xf4, 0x0c
	jr z, SMF_GlobalCh_Found
	inc 1, iy
	cp iy, 0xf
	jr ule, SMF_GlobalCh_SearchLoop
	jp SMF_GlobalCh_DrumMode

SMF_GlobalCh_Found:
	ld wa, iy
	ld (6881:16), a

SMF_GlobalCh_Return:
	pop xde
	pop xbc
	pop xwa
	pop xiy
	pop xix
	ret

SMF_LoadSongBank:
	call SMF_DetectFormat
	ld a, (4394:16)
	cp a, 0:i3
	jr z, SMF_LoadBank_Return
	ld xde, 0xab000
	lda_dri XDE, 0xe9, 0xc7, 0x00
	cp (4394:16), 1
	jr nz, SMF_LoadBank_ReadEntries
	ld (xde), 0x0

SMF_LoadBank_ReadEntries:
	ld a, (xde)
	xor xbc, xbc
	ld c, a
	ld xhl, xbc
	mul hl, 0x800
	add xhl, 0xab000
	push xhl
	ldw de, 0xaf
	ldw_sri WA, 0x07, 0xec, 0xe8
	ld (0xf22f:16), wa
	pop xhl
	ldw de, 0xb1
	ldw_sri WA, 0x07, 0xec, 0xe8
	ld (0xf231:16), wa
	ld (0x00ffe3:24), 0x00

SMF_LoadBank_EventLoop:
	calr SMF_SetupReadPointers
	calr SMF_ResetPlaybackState
	call SMF_SetupRead_Return
	inc 1, (0xffe3:24)
	cp (0x00ffe3:24), 0x0a
	jr c, SMF_LoadBank_EventLoop

SMF_LoadBank_Return:
	ret

SMF_SetupReadPointers:
	ld wa, (0xf22f:16)
	ld (0x286f:16), wa
	ld wa, (0xf231:16)
	ld (0x2871:16), wa
	call SongBank_LoadToWorkArea
	ret

SMF_ResetPlaybackState:
	and (4404:16), 254
	and (4404:16), 253
	and (4411:16), 254
	and (4411:16), 253
	and (4404:16), 251
	ld (4419:16), 0
	or (4393:16), 2
	xor a, a
	ld (3301:16), a
	calr SMF_DetectFormat
	ld a, (4394:16)
	cp a, 0:i3
	jr z, SMF_Parse_Complete

SMF_ParseEvents:
	call SetWall_ParserInit
	ld a, (3301:16)
	cp a, 0xf
	jr ugt, SMF_Parse_Complete
	ld c, (3301:16)
	ld wa, (0xf19e:16)
	ld (0x287a:16), 0
	and (0x287b:16), 191
	xor xhl, xhl
	ld l, (3301:16)
	ld xix, 0xf1a0
	add xix, xhl
	ld l, (xix)
	ld (0x2873:16), l
	cp l, 0xf
	jr nz, SMF_Parse_ClearAutoFlag
	or (4393:16), 1
	jr SMF_Parse_NextChannel

SMF_Parse_ClearAutoFlag:
	and (4393:16), 254
	xor h, h

SMF_Parse_NextChannel:
	ld a, (3301:16)
	inc 1, a
	calr SMF_ConfigSlot
	and (4393:16), 254
	and (4393:16), 251
	ld (4419:16), 0
	inc 1, (3301:16)
	jr SMF_ParseEvents

SMF_Parse_Complete:
	ld (3301:16), 0
	and (4393:16), 254
	and (4393:16), 253
	and (4393:16), 251
	and (4404:16), 254
	and (4404:16), 253
	and (4411:16), 254
	and (4411:16), 253
	and (4404:16), 251
	ld (4419:16), 0
	ret

SMF_TranslateChannel:
	push xix
	ld xix, SMF_ChannelTranslationTable
	xor hl, hl
	ld l, a
	ldb_sri W, 0x07, 0xf0, 0xec
	cp w, 0xff
	jr z, SMF_Translate_Return
	cp (4394:16), 3
	jr nz, SMF_Translate_Apply
	cp a, 0xe
	jr z, SMF_Translate_0xE
	cp a, 0x10
	jr nz, SMF_Translate_Apply
	ld w, 0x18:opc
	jr SMF_Translate_Apply

SMF_Translate_0xE:
	ld w, 0x17:opc

SMF_Translate_Apply:
	ld a, w

SMF_Translate_Return:
	pop xix
	ret

SMF_ChannelTranslationTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x41, 0x0e
	.byte 0x42, 0x0f, 0x48, 0x10, 0x90, 0x11, 0x50, 0x51
	.byte 0x70, 0x71, 0x12, 0x13, 0x14, 0x15, 0x16, 0xff
	.byte 0x98, 0x40, 0xff, 0x52, 0x92, 0xff, 0x72, 0xff
	.byte 0x99, 0xff, 0xff, 0xff, 0x80, 0xff, 0xff, 0xff
	.byte 0xff, 0xff, 0x53, 0xff, 0xff, 0xff, 0xff, 0x9a
	.fill 8, 1, 0xff

SMF_ConfigSlot:
	and (0x287b:16), 251
	xor w, w
	ld (0x287a:16), 0
	ld (0x287d:16), wa
	ldw (0x287f:16), 1
	call SetWall_SlotResolve
	cp (0x287a:16), 0
	jr z, SMF_ConfigSlot_Setup
	jrl SMF_ConfigSlot_Return

SMF_ConfigSlot_Setup:
	push xiy
	calr SMF_SetupSongBankRead
	pop xiy
	push xhl
	ld xhl, (4349:16)
	ld (0x2881:16), xhl
	pop xhl
	ld (0x2885:16), iy
	ld wa, (0x28af:16)
	ld (0x2887:16), wa
	ld (0x2889:16), iy
	ld (0x288b:16), wa
	ld ix, iy
	ld hl, (3376:16)

SMF_ConfigSlot_EventLoop:
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf0
	pop xde
	ld w, 0xf0:opc
	and w, a
	cp a, 0x82
	jrl z, SMF_ConfigSlot_EndOfTrack
	cp a, 0xd2
	jr z, SMF_ConfigSlot_TypeD2
	cp a, 0x80
	jr z, SMF_ConfigSlot_Type80
	cp w, 0xc0
	jr z, SMF_ConfigSlot_TypeC0
	cp w, 0xb0
	jr z, SMF_ConfigSlot_TypeB0
	jr SMF_ConfigSlot_DefaultHandler
	calr SMF_AdvanceReadPtr
	cp (0x287a:16), 0
	jr z, SMF_ConfigSlot_EventLoop
	jrl SMF_ConfigSlot_Return

SMF_ConfigSlot_DefaultHandler:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf4
	pop xhl

SMF_ConfigSlot_WriteAndContinue:
	calr SMF_AdvanceWritePtr
	cp (0x287a:16), 0
	jrl nz, SMF_ConfigSlot_Return

SMF_ConfigSlot_AdvanceEvent:
	calr SMF_AdvanceReadPtr
	cp (0x287a:16), 0
	jrl nz, SMF_ConfigSlot_Return
	push xde
	ld xde, (4349:16)
	bit_dri 7, 0x07, 0xe8, 0xf0
	pop xde
	jr nz, SMF_ConfigSlot_EventLoop
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf0
	pop xde
	jr SMF_ConfigSlot_DefaultHandler

SMF_ConfigSlot_TypeB0:
	ldw (4402:16), 5
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_TypeC0:
	ldw (4402:16), 4
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_TypeD2:
	ldw (4402:16), 2
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_Type80:
	ldw (4402:16), 3

SMF_ConfigSlot_StoreType:
	pushw wa
	ld (3310:16), a
	and (3310:16), 2
	ld a, (3310:16)
	sla a, 6
	ld (3310:16), a
	ld (4395:16), a
	and (4395:16), 1
	ld a, (4395:16)
	sla a, 7
	ld (4395:16), a
	popw wa
	push xiy
	pushw hl
	xor hl, hl
	ld xiy, 0x112c
	ld (xiy), a

SMF_ConfigSlot_ReadDataLoop:
	inc 1, hl
	push xiy
	pushw hl
	calr SMF_AdvanceReadPtr
	popw hl
	pop xiy
	push xde
	ld xde, (4349:16)
	ldb_sri A, 0x07, 0xe8, 0xf0
	pop xde
	stb_dri A, 0x07, 0xf4, 0xec
	cp hl, (4402:16)
	jr c, SMF_ConfigSlot_ReadDataLoop
	popw hl
	pop xiy
	cp (0x287a:16), 0
	jrl nz, SMF_ConfigSlot_Return
	and (4404:16), 254
	and (4404:16), 251
	and (4404:16), 253
	and (4411:16), 254
	and (4411:16), 253
	ld a, (4394:16)
	cp a, 1:i3
	jr z, SMF_Config_Format1
	cp a, 2:i3
	jr z, SMF_Config_Format2
	cp a, 3:i3
	jr z, SMF_Config_Format3
	cp a, 4:i3
	jp z, (SMF_Config_Format4or5:24)
	cp a, 5:i3
	jp z, (SMF_Config_Format4or5:24)
	jrl SMF_ConfigSlot_Return

SMF_Config_Format1:
	push xix
	push xiy
	ld xiy, 0x112c
	cpw (4402:16), 4
	jr nz, SMF_Config_Format1_Done
	calr SMF_SlotParam_PortamentoSwitch

SMF_Config_Format1_Done:
	pop xiy
	pop xix
	jr SMF_Config_ProcessSlotData

SMF_Config_Format2:
	push xix
	push xiy
	ld xiy, 0x112c
	cpw (4402:16), 5
	jr nz, SMF_Config_Format2_Done

SMF_Config_Format2_Done:
	pop xiy
	pop xix
	jr SMF_Config_ProcessSlotData

SMF_Config_Format3:
	push xix
	push xiy
	ld xiy, 0x112c
	cpw (4402:16), 5
	jr nz, SMF_Config_Format3_Done
	calr SMF_SlotChain_Fmt3Voice

SMF_Config_Format3_Done:
	pop xiy
	pop xix
	jr SMF_Config_ProcessSlotData

SMF_Config_ProcessSlotData:
	push xix
	push xiy
	ld xiy, 0x112c
	cpw (4402:16), 4
	jr z, SMF_Config_Count4
	cpw (4402:16), 5
	jr z, SMF_Config_Count5
	cpw (4402:16), 2
	jr z, SMF_Config_Count2
	cpw (4402:16), 3
	jr z, SMF_Config_Count3
	jr SMF_Config_PopAndContinue

SMF_Config_Count2:
	calr SMF_SlotParam_TypeD2Handler
	or (4404:16), 1
	jr SMF_Config_PopAndContinue

SMF_Config_Count3:
	calr SMF_SlotParam_Type80Handler
	jr SMF_Config_PopAndContinue

SMF_Config_Count5:
	calr SMF_SlotChain_CheckInstr
	calr SMF_SlotChain_CheckVoice
	calr SMF_SlotParam_Volume
	calr SMF_SlotParam_Pan
	calr SMF_SlotParam_Expression
	calr SMF_SlotParam_Reverb
	calr SMF_SlotParam_Chorus
	calr SMF_SlotParam_ModWheel
	calr SMF_SlotParam_PitchBend
	calr SMF_SlotParam_Aftertouch
	calr SMF_SlotParam_Sustain
	calr SMF_SlotParam_Sostenuto
	calr SMF_SlotParam_SoftPedal
	calr SMF_SlotParam_ReverbType
	calr SMF_SlotParam_ChorusType
	calr SMF_SlotParam_BankSelect
	calr SMF_SlotParam_BankSelectReturn
	calr SMF_SlotParam_BankLSBReturn
	calr SMF_SlotParam_NRPN
	and (4411:16), 254
	jr SMF_Config_PopAndContinue

SMF_Config_Count4:
	calr SMF_SlotParam_NRPNReturn
	or (4404:16), 1

SMF_Config_PopAndContinue:
	pop xiy
	pop xix
	jr SMF_Config_WriteOutput

SMF_Config_Format4or5:
	push xix
	push xiy
	ld xiy, 0x112c
	cpw (4402:16), 5
	jr z, SMF_Config_Format5_Handler
	jr SMF_Config_PopAndContinue

SMF_Config_Format5_Handler:
	call SMF_SlotParam_Format5Handler
	and (4411:16), 254
	jr SMF_Config_PopAndContinue

SMF_Config_WriteOutput:
	bit 1, (4404:16)
	jr nz, SMF_Config_HandleBit1
	push xix
	push xhl
	xor hl, hl
	ld xix, 0x112c
	ld a, (xix)
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf4
	pop xhl

SMF_Config_WriteLoop:
	inc 1, hl
	push xix
	push xhl
	calr SMF_AdvanceWritePtr
	pop xhl
	pop xix
	ldb_sri A, 0x07, 0xf0, 0xec
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf4
	pop xhl
	cp hl, (4402:16)
	jr c, SMF_Config_WriteLoop
	pop xhl
	pop xix
	cp (0x287a:16), 0
	jrl nz, SMF_ConfigSlot_Return
	bit 0, (4404:16)
	jr nz, SMF_Config_OutputOverride1
	bit 2, (4404:16)
	jr nz, SMF_Config_OutputOverride6
	jrl SMF_ConfigSlot_WriteAndContinue

SMF_Config_HandleBit1:
	and (4404:16), 253
	and (4404:16), 253
	jrl SMF_ConfigSlot_AdvanceEvent

SMF_Config_OutputOverride1:
	ld a, (3301:16)
	inc 1, a
	ld w, 0x1:opc
	jr SMF_Config_SaveAndRestore

SMF_Config_OutputOverride6:
	ld a, (3301:16)
	inc 1, a
	ld w, 0x6:opc

SMF_Config_SaveAndRestore:
	push xix
	push xiy
	push xhl
	push xbc
	xor xbc, xbc
	ld xiy, 0x1135
	xor hl, hl
	ld l, (3301:16)
	sll hl, 1
	push xde
	ld xde, 0xc9e
	ldw_sri BC, 0x07, 0xe8, 0xec
	ld (4412:16), bc
	ld bc, (0x288b:16)
	stw_dri BC, 0x07, 0xe8, 0xec
	srl hl, 1
	ld xde, 0xcbe
	ldb_sri C, 0x07, 0xe8, 0xec
	ld (4414:16), c
	ld bc, ix
	bit 2, (4404:16)
	jr z, SMF_Config_GetTableEntry
	push xix
	xor xix, xix
	ld xix, xbc
	calr SMF_AdvanceReadPtr
	ld xbc, xix
	pop xix

SMF_Config_GetTableEntry:
	stb_dri C, 0x07, 0xe8, 0xec
	pop xde
	cp a, 3:i3
	jr nz, SMF_Config_CallHandler
	nop

SMF_Config_CallHandler:
	call VoiceSlot_AssignWrapper
	xor hl, hl
	ld l, (3301:16)
	sll hl, 1
	push xde
	ld xde, 0xc9e
	ld bc, (4412:16)
	stw_dri BC, 0x07, 0xe8, 0xec
	srl hl, 1
	ld xde, 0xcbe
	ld c, (4414:16)
	stb_dri C, 0x07, 0xe8, 0xec
	pop xde
	pop xbc
	pop xhl
	pop xiy
	pop xix
	bit 2, (4404:16)
	jr z, SMF_Config_ClearFlags
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceReadPtr
	calr SMF_AdvanceWritePtr
	calr SMF_AdvanceWritePtr
	calr SMF_AdvanceWritePtr
	calr SMF_AdvanceWritePtr
	calr SMF_AdvanceWritePtr
	calr SMF_AdvanceWritePtr

SMF_Config_ClearFlags:
	and (4404:16), 254
	and (4404:16), 251
	jrl SMF_ConfigSlot_WriteAndContinue

SMF_ConfigSlot_EndOfTrack:
	push xhl
	ld xhl, (0x2881:16)
	stb_dri A, 0x07, 0xec, 0xf4
	pop xhl
	ld wa, (0x2887:16)
	ld (0x289f:16), wa
	call SetWall_EventOutput
	call SetWall_EventAdvanceCheck

SMF_ConfigSlot_Return:
	ret

SMF_ConfigSlot_CodeBlock:
	push	xhl
	push	xwa
	ld	wa, (10375:16)
	ld	(4415:16), wa
	ld	(4417:16), iy
	incw	1, (4417:16)
	cpw	(4417:16), 255
	jr	ule, SMF_ConfigSlot_Epilogue
	ld	xhl, (10369:16)
	ld	wa, (xhl+3)
	ld	(4415:16), wa
	ld	(10375:16), wa
	ld	hl, wa
	calr	SMF_CalcPageAddress
	ld	xhl, (4349:16)
	.byte 0xb3, 0xcf
	jr	nz, SMF_ConfigSlot_Skip
	ld	(10362:16), 2
	jr	SMF_ConfigSlot_Epilogue
SMF_ConfigSlot_Skip:
	ld	(10369:16), xhl
	ldw	(4417:16), 5
	ld	iy, 5:i3
SMF_ConfigSlot_Epilogue:
	pop	xwa
	pop	xhl
	ret

SMF_DetectFormat:
	ld (4394:16), 0
	ld xde, 0xab000
	lda xde, (xde + 4)
	ld a, (xde + 1)
	ld w, (xde + 2)
	cp a, 1:i3
	jr nz, SMF_Format_Return
	cp w, 3:i3
	jr z, SMF_Format_Version1
	cp w, 6:i3
	jr z, SMF_Format_Version4
	cp w, 7:i3
	jr z, SMF_Format_Version5
	jr SMF_Format_Return

SMF_Format_Version5:
	ld (4394:16), 5
	jr SMF_Format_Return

SMF_Format_Version4:
	ld (4394:16), 4
	jr SMF_Format_Return

SMF_Format_Version1:
	ld (4394:16), 1

SMF_Format_Return:
	ret

SMF_AdvanceReadPtr:
	inc 1, ix
	cp ix, 0xff
	jr ule, SMF_AdvanceRead_Return
	ld hl, (0x288b:16)
	calr SMF_CalcPageAddress
	ld xhl, (4349:16)
	ld wa, (xhl + 3)
	ld (0x288b:16), wa
	ld hl, wa
	calr SMF_CalcPageAddress
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SMF_AdvanceRead_NewPage
	ld (0x287a:16), 2
	jr SMF_AdvanceRead_Return

SMF_AdvanceRead_NewPage:
	ld ix, 5:i3

SMF_AdvanceRead_Return:
	ret

SMF_AdvanceWritePtr:
	ld xwa, (4349:16)
	push xwa
	inc 1, iy
	cp iy, 0xff
	jr ule, SMF_AdvanceWrite_Return
	ld xhl, (0x2881:16)
	ld wa, (xhl + 3)
	ld (0x2887:16), wa
	ld hl, wa
	calr SMF_CalcPageAddress
	ld xhl, (4349:16)
	bitm 7, (xhl)
	jr nz, SMF_AdvanceWrite_NewPage
	ld (0x287a:16), 2
	jr SMF_AdvanceWrite_Return

SMF_AdvanceWrite_NewPage:
	ld (0x2881:16), xhl
	ld iy, 5:i3

SMF_AdvanceWrite_Return:
	pop xwa
	ld (4349:16), xwa
	ret

SMF_CalcPageAddress:
	dec 1, hl
	extz xhl
	sla xhl, 8
	add xhl, (7514:16)
	ld (4349:16), xhl
	xor xhl, xhl
	ret

SMF_SlotChain_CheckInstr:
	bit 0, (4411:16)
	jr nz, SMF_SlotChain_InstrReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotChain_InstrReturn
	ld a, (xiy + 2)
	cp a, 0x1e
	jr ugt, SMF_SlotChain_InstrReturn
	cp a, 0x19
	jr ugt, SMF_SlotChain_ResolveInstr
	cp a, 0x16
	jr nc, SMF_SlotChain_InstrReturn
	cp a, 0x14
	jr z, SMF_SlotChain_InstrReturn
	cp a, 0x12
	jr z, SMF_SlotChain_InstrReturn

SMF_SlotChain_ResolveInstr:
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotChain_InstrReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotChain_StoreInstr
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotChain_StoreInstr:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	or (4411:16), 1

SMF_SlotChain_InstrReturn:
	ret

SMF_SlotChain_CheckVoice:
	bit 0, (4411:16)
	jr nz, SMF_SlotChain_VoiceReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotChain_VoiceReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotChain_VoiceReturn
	ld a, (xiy + 2)
	cp a, 0x1e
	jr ugt, SMF_SlotChain_VoiceReturn
	cp a, 0x19
	jr ugt, SMF_SlotChain_ResolveVoice
	cp a, 0x16
	jr nc, SMF_SlotChain_VoiceReturn
	cp a, 0x14
	jr z, SMF_SlotChain_VoiceReturn
	cp a, 0x12
	jr z, SMF_SlotChain_VoiceReturn

SMF_SlotChain_ResolveVoice:
	cp (xiy + 3), 0x2
	jr nz, SMF_SlotChain_VoiceReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotChain_StoreVoice
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotChain_StoreVoice:
	ld (xiy + 2), a
	ld (xiy + 3), 0x4
	calr SMF_SlotChain_ExtendedVoice
	or (4411:16), 1

SMF_SlotChain_VoiceReturn:
	ret

SMF_SlotChain_ExtendedVoice:
	cp (4394:16), 3
	jr z, SMF_SlotChain_ExtVoiceReturn
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 0x20
	jr nz, SMF_SlotChain_ExtVoiceReturn
	ld w, (xiy + 4)
	or w, (4395:16)
	and a, w
	and a, 0x20
	cp a, 0:i3
	jr z, SMF_SlotChain_ExtVoiceDefault
	xor hl, hl
	ld l, (xiy + 2)
	mul l, 0x20
	add hl, 0x5
	add hl, 0x2
	ld xix, Naka_ToshiParam_Table_0x8C
	ldb_sri A, 0x07, 0xf0, 0xec
	jr SMF_SlotChain_ExtVoiceStore

SMF_SlotChain_ExtVoiceDefault:
	ld a, 0x0:opc

SMF_SlotChain_ExtVoiceStore:
	ld (xiy + 4), a
	ld (xiy + 5), 0x7f
	ld (xiy + 3), 0x5

SMF_SlotChain_ExtVoiceReturn:
	ret

SMF_SlotChain_Fmt3Voice:
	ld a, (4394:16)
	cp a, 3:i3
	jr nz, SMF_SlotChain_Fmt3Return
	cp (0x2873:16), 15
	jr z, SMF_SlotChain_Fmt3Return
	cp (0x2873:16), 16
	jr z, SMF_SlotChain_Fmt3Return
	ld a, (xiy + 2)
	cp a, 0x1e
	jr ugt, SMF_SlotChain_Fmt3Return
	cp a, 0x19
	jr ugt, SMF_SlotChain_Fmt3CheckStep
	cp a, 0x16
	jr nc, SMF_SlotChain_Fmt3Return
	cp a, 0x14
	jr z, SMF_SlotChain_Fmt3Return
	cp a, 0x12
	jr z, SMF_SlotChain_Fmt3Return

SMF_SlotChain_Fmt3CheckStep:
	cp (xiy + 3), 0xc
	jr nz, SMF_SlotChain_Fmt3Return
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotChain_Fmt3Resolve
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotChain_Fmt3Resolve:
	ld (xiy + 2), a
	ld (xiy + 3), 0x5
	or (4411:16), 1

SMF_SlotChain_Fmt3Return:
	ret

SMF_SlotParam_Volume:
	bit 0, (4411:16)
	jrl nz, SMF_SlotParam_VolumeReturn
	cp (4394:16), 3
	jr z, SMF_SlotParam_VolumeWrite
	ld a, (xiy + 2)
	cp a, 0x1e
	jrl ugt, SMF_SlotParam_VolumeReturn
	cp a, 0x19
	jr ugt, SMF_SlotParam_VolumeImpl
	cp a, 0x16
	jrl nc, SMF_SlotParam_VolumeReturn
	cp a, 0x14
	jrl z, SMF_SlotParam_VolumeReturn
	cp a, 0x12
	jrl z, SMF_SlotParam_VolumeReturn

SMF_SlotParam_VolumeImpl:
	cp (xiy + 3), 0x3
	jrl nz, SMF_SlotParam_VolumeReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_VolumeCalc
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_VolumeCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	ld a, (4395:16)
	and a, (3310:16)
	bit 7, a
	jr nz, SMF_SlotParam_VolumeScale
	xor w, w
	ld (xiy + 4), w
	jr SMF_SlotParam_VolumeStore

SMF_SlotParam_VolumeScale:
	xor hl, hl
	ld l, (xiy + 2)
	mul l, 0x20
	add hl, 0x7
	add hl, 0x2
	ld xix, Naka_ToshiParam_Table_0x8C
	ldb_sri A, 0x07, 0xf0, 0xec
	ld (xiy + 4), a

SMF_SlotParam_VolumeStore:
	ld (xiy + 5), 0x7f
	andmi8 (xiy), 0xfc
	or (4411:16), 1
	jr SMF_SlotParam_VolumeReturn

SMF_SlotParam_VolumeWrite:
	ld a, (xiy + 2)
	cp a, 0x1e
	jr ugt, SMF_SlotParam_VolumeReturn
	cp a, 0x19
	jr ugt, SMF_SlotParam_VolumeOutput
	cp a, 0x16
	jr nc, SMF_SlotParam_VolumeReturn
	cp a, 0x14
	jr z, SMF_SlotParam_VolumeReturn
	cp a, 0x12
	jr z, SMF_SlotParam_VolumeReturn

SMF_SlotParam_VolumeOutput:
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_VolumeReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_VolumeDone
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_VolumeDone:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	or (4411:16), 1

SMF_SlotParam_VolumeReturn:
	ret

SMF_SlotParam_Pan:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_PanReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_PanReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_PanReturn
	cp (xiy + 2), 0x27
	jr nz, SMF_SlotParam_PanReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0x8
	or (4411:16), 1

SMF_SlotParam_PanReturn:
	ret

SMF_SlotParam_Expression:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ExprReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_ExprReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_ExprReturn
	cp (xiy + 2), 0x2b
	jr nz, SMF_SlotParam_ExprReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0x9
	or (4411:16), 1

SMF_SlotParam_ExprReturn:
	ret

SMF_SlotParam_Reverb:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ReverbReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_ReverbReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_ReverbReturn
	cp (xiy + 2), 0x29
	jr nz, SMF_SlotParam_ReverbReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0xb
	or (4411:16), 1

SMF_SlotParam_ReverbReturn:
	ret

SMF_SlotParam_Chorus:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ChorusReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_ChorusReturn
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_ChorusReturn
	cp (xiy + 2), 0x2a
	jr nz, SMF_SlotParam_ChorusReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0xa
	or (4411:16), 1

SMF_SlotParam_ChorusReturn:
	ret

SMF_SlotParam_ModWheel:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ModWheelReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_ModWheelImpl
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_ModWheelImpl
	cp (0x2873:16), 13
	jr z, SMF_SlotParam_ModWheelImpl
	cp (0x2873:16), 14
	jr nz, SMF_SlotParam_ModWheelReturn

SMF_SlotParam_ModWheelImpl:
	cp (xiy + 2), 0x12
	jr nz, SMF_SlotParam_ModWheelReturn
	cp (xiy + 3), 0x2
	jr nz, SMF_SlotParam_ModWheelReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_ModWheelCalc
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_ModWheelCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	or (4411:16), 1
	ld a, (xiy + 4)
	or a, (4395:16)
	ld w, (xiy + 5)
	or w, (3310:16)
	cp w, 4:i3
	jr z, SMF_SlotParam_ModWheelStore
	cp w, 3:i3
	jr nz, SMF_SlotParam_ModWheelReturn
	andmi8 (xiy + 4), 0xfb
	ld (xiy + 5), 0x7
	jr SMF_SlotParam_ModWheelReturn

SMF_SlotParam_ModWheelStore:
	ld (xiy + 5), 0x8
	bit 2, a
	jr z, SMF_SlotParam_ModWheelReturn
	ld (xiy + 4), 0x8

SMF_SlotParam_ModWheelReturn:
	ret

SMF_SlotParam_PitchBend:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_Detune
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_PitchBendImpl
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_PitchBendImpl
	cp (0x2873:16), 13
	jr z, SMF_SlotParam_PitchBendImpl
	cp (0x2873:16), 14
	jr nz, SMF_SlotParam_Detune

SMF_SlotParam_PitchBendImpl:
	cp (xiy + 2), 0x12
	jr nz, SMF_SlotParam_Detune
	cp (xiy + 3), 0xa
	jr nz, SMF_SlotParam_Detune
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_PitchBendCalc
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_PitchBendCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	or (4411:16), 1
	ld a, (xiy + 4)
	and a, 0x10
	cp a, 0:i3
	jr z, SMF_SlotParam_PitchBendStore
	ld a, 0x20:opc
	jr SMF_SlotParam_PitchBendReturn

SMF_SlotParam_PitchBendStore:
	ld a, 0x0:opc

SMF_SlotParam_PitchBendReturn:
	ld (xiy + 4), a
	ld a, (xiy + 5)
	cp a, 0x10
	jr nz, SMF_SlotParam_Detune
	ld (xiy + 5), 0x30
	call SMF_SlotParam_DetuneImpl
	or (4404:16), 4

SMF_SlotParam_Detune:
	ret

SMF_SlotParam_DetuneImpl:
	ld xix, 0x1135
	ld a, (xiy)
	ld (xix), a
	ld a, (xiy + 1)
	ld (xix + 1), a
	ld a, (xiy + 2)
	ld (xix + 2), a
	ld a, (xiy + 3)
	ld (xix + 3), a
	ld a, (xiy + 4)
	ld (xix + 4), a
	ld a, (xiy + 5)
	ld (xix + 5), a
	xor a, a
	ld (xiy), 0xb4
	ld (xiy + 2), 0x18
	ld (xiy + 3), 0x3
	ld (xiy + 4), a
	ld (xiy + 5), 0x7
	ret

SMF_SlotParam_Aftertouch:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_AftertouchReturn
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_AftertouchReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_AftertouchReturn
	cp (4394:16), 3
	jr z, SMF_SlotParam_AftertouchImpl
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_AftertouchReturn
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 0x80
	jr nz, SMF_SlotParam_AftertouchReturn
	ld (xiy + 2), 0x60
	ld (xiy + 2), 0x1
	jr SMF_SlotParam_AftertouchReturn

SMF_SlotParam_AftertouchImpl:
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_AftertouchReturn
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 0xc0
	jr nz, SMF_SlotParam_AftertouchReturn
	ld (xiy + 2), 0x60
	ld (xiy + 2), 0x1
	xor a, a
	ld (xiy + 5), a
	ormi8 (xiy), 0x2

SMF_SlotParam_AftertouchReturn:
	ret

SMF_SlotParam_PortamentoSwitch:
	and (4404:16), 253
	and (4411:16), 253
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_PortaReturn
	cp (xiy + 2), 0x12
	jr nz, SMF_SlotParam_PortaReturn
	cp (xiy + 3), 0x6
	jr z, SMF_SlotParam_PortaImpl
	cp (xiy + 3), 0x7
	jr nz, SMF_SlotParam_PortaReturn

SMF_SlotParam_PortaImpl:
	or (4404:16), 2
	or (4411:16), 2
	ld (4419:16), 1

SMF_SlotParam_PortaReturn:
	ret

SMF_SlotParam_PortamentoTime:
	.byte 0xc1, 0x2a, 0x11, 0x21, 0xc9, 0xda, 0x66, 0x04
	.byte 0xc9, 0xdb, 0x6e, 0x30, 0xc1, 0x73, 0x28, 0x3f
	.byte 0x0f, 0x6e, 0x29, 0x8d, 0x02, 0x3f, 0x14, 0x6e
	.byte 0x23, 0x8d, 0x03, 0x3f, 0x04, 0x6e, 0x1d, 0x8d
	.byte 0x02, 0x21, 0x1e, 0x54, 0xf6, 0xc9, 0x33, 0x07
	.byte 0x66, 0x06, 0xc9, 0xcc, 0x7f, 0x85, 0x3e, 0x04
	.byte 0xbd, 0x02, 0x41, 0xbd, 0x03, 0x00, 0x02, 0xc1
	.byte 0x3b, 0x11, 0x3e, 0x01, 0x0e

SMF_SlotParam_Sustain:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_SustainReturn
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_SustainReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SustainReturn
	cp (xiy + 3), 0x0
	jr nz, SMF_SlotParam_SustainReturn
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 3:i3
	jr nz, SMF_SlotParam_SustainReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SustainImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_SustainImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x0
	or (4411:16), 1

SMF_SlotParam_SustainReturn:
	ret

SMF_SlotParam_Sostenuto:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_SostenutoReturn1
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_SostenutoReturn1
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SostenutoReturn1
	cp (xiy + 3), 0xf
	jr nz, SMF_SlotParam_SostenutoReturn1
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SostenutoImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_SostenutoImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x1
	or (4411:16), 1

SMF_SlotParam_SostenutoReturn1:
	ret

SMF_SlotParam_SoftPedal:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_SoftPedalReturn
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_SoftPedalReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SoftPedalReturn
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_SoftPedalReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SoftPedalImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_SoftPedalImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x2
	or (4411:16), 1

SMF_SlotParam_SoftPedalReturn:
	ret

SMF_SlotParam_Format5Handler:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_Format5Return
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_Format5Impl
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_Format5Impl
	cp (0x2873:16), 13
	jr z, SMF_SlotParam_Format5Impl
	cp (0x2873:16), 14
	jr nz, SMF_SlotParam_Format5Return

SMF_SlotParam_Format5Impl:
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_Format5Return
	bitm 2, (xiy)
	jr z, SMF_SlotParam_Format5Return
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_Format5Return
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 0x3f
	jr z, SMF_SlotParam_Format5Check
	cp a, 0x40
	jr nz, SMF_SlotParam_Format5Return
	ld (xiy + 3), 0x0
	jr SMF_SlotParam_Format5Set

SMF_SlotParam_Format5Check:
	ld (xiy + 3), 0x1
	andmi8 (xiy + 4), 0x3f
	ld (xiy + 5), 0x7f
	andmi8 (xiy), 0xfd

SMF_SlotParam_Format5Set:
	or (4411:16), 1

SMF_SlotParam_Format5Return:
	ret

SMF_SlotParam_ReverbType:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ReverbTypeReturn
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_ReverbTypeImpl
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_ReverbTypeImpl
	cp (0x2873:16), 13
	jr z, SMF_SlotParam_ReverbTypeImpl
	cp (0x2873:16), 14
	jr nz, SMF_SlotParam_ReverbTypeReturn

SMF_SlotParam_ReverbTypeImpl:
	cp (xiy + 2), 0x20
	jr nz, SMF_SlotParam_ReverbTypeReturn
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_ReverbTypeReturn
	ld a, (xiy + 5)
	or a, (3310:16)
	cp a, 0x1f
	jr z, SMF_SlotParam_ReverbTypeCalc
	cp a, 0x40
	jr nz, SMF_SlotParam_ReverbTypeReturn
	ld (xiy + 3), 0x0
	jr SMF_SlotParam_ReverbTypeOutput

SMF_SlotParam_ReverbTypeCalc:
	ld (xiy + 3), 0x1
	andmi8 (xiy + 4), 0x1f
	ld (xiy + 5), 0x7f
	andmi8 (xiy), 0xfd

SMF_SlotParam_ReverbTypeOutput:
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_ReverbTypeDone
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_ReverbTypeDone:
	ld (xiy + 2), a
	or (4411:16), 1

SMF_SlotParam_ReverbTypeReturn:
	ret

SMF_SlotParam_ChorusType:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_ChorusTypeDone
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_ChorusTypeDone
	cp (xiy + 2), 0x20
	jr nz, SMF_SlotParam_ChorusTypeDone
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_ChorusTypeDone
	cp (xiy + 5), 0x7
	jr z, SMF_SlotParam_ChorusTypeCheck
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_ChorusTypeImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_ChorusTypeImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	or (4411:16), 1
	jr SMF_SlotParam_ChorusTypeDone

SMF_SlotParam_ChorusTypeCheck:
	ld (xiy + 2), 0x48
	ld (xiy + 3), 0x7
	ld a, (xiy + 4)
	sll a, 4
	ld (xiy + 4), a
	ld (xiy + 5), 0x30
	calr SMF_SlotParam_ChorusTypeReturn
	or (4411:16), 1
	or (4404:16), 4

SMF_SlotParam_ChorusTypeDone:
	ret

SMF_SlotParam_ChorusTypeReturn:
	ld xix, 0x1135
	ld a, (xiy)
	ld (xix), a
	ld a, (xiy + 1)
	ld (xix + 1), a
	ld a, (xiy + 2)
	ld (xix + 2), a
	ld a, (xiy + 3)
	ld (xix + 3), a
	ld a, (xiy + 4)
	ld (xix + 4), a
	ld a, (xiy + 5)
	ld (xix + 5), a
	ld (xiy), 0xb4
	ld (xiy + 2), 0x18
	ld (xiy + 3), 0x3
	ld (xiy + 4), 0x1
	ld (xiy + 5), 0x7
	ret

SMF_SlotParam_BankSelect:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_BankSelectDone
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_BankSelectDone
	cp (xiy + 2), 0x20
	jr nz, SMF_SlotParam_BankSelectDone
	cp (xiy + 3), 0x4
	jr nz, SMF_SlotParam_BankSelectDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_BankSelectImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_BankSelectImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x4
	or (4411:16), 1

SMF_SlotParam_BankSelectDone:
	ret

SMF_SlotParam_BankSelectReturn:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_BankLSBDone
	cp (0x2873:16), 0
	jr z, SMF_SlotParam_BankSelectLSB
	cp (0x2873:16), 2
	jr z, SMF_SlotParam_BankSelectLSB
	cp (0x2873:16), 1
	jr nz, SMF_SlotParam_BankLSBDone

SMF_SlotParam_BankSelectLSB:
	cp (xiy + 2), 0x37
	jr nz, SMF_SlotParam_BankLSBDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_BankLSBImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_BankLSBImpl:
	ld (xiy + 2), a
	or (4411:16), 1
	ld a, (xiy + 3)
	cp a, 0xe
	jr c, SMF_SlotParam_BankLSBDone
	cp a, 0x1d
	jr ugt, SMF_SlotParam_BankLSBDone
	sub a, 0xa
	ld (xiy + 3), a

SMF_SlotParam_BankLSBDone:
	ret

SMF_SlotParam_BankLSBReturn:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_RPNDone
	cp (xiy + 2), 0x39
	jr nz, SMF_SlotParam_RPNDone
	xor hl, hl
	bitm 5, (xiy + 3)
	jr nz, SMF_SlotParam_RPN
	push xix
	ld xix, SMF_SlotParam_RPNReturn
	ld l, (xiy + 3)
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xad
	or (4411:16), 1
	jr SMF_SlotParam_RPNDone

SMF_SlotParam_RPN:
	push xix
	ld xix, SMF_SlotParam_RPNReturn_0x1F
	ld l, (xiy + 3)
	ldb_sri A, 0x07, 0xf0, 0xec
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xae
	or (4411:16), 1

SMF_SlotParam_RPNDone:
	ret

SMF_SlotParam_RPNReturn:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x17, 0x0e
	.byte 0x18, 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00, 0x00
	.byte 0x00, 0x00, 0x12, 0x13, 0x14, 0x15, 0x16, 0x00
	.byte 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
	.byte 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x17, 0x0e, 0x18
	.byte 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00, 0x00, 0x00
	.byte 0x00, 0x12, 0x13, 0x14, 0x15, 0x16

SMF_SlotParam_NRPN:
	bit 0, (4411:16)
	jr nz, SMF_SlotParam_NRPNDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_NRPNImpl
	and a, 0x7f
	ormi8 (xiy), 0x4

SMF_SlotParam_NRPNImpl:
	ld (xiy + 2), a

SMF_SlotParam_NRPNDone:
	ret

SMF_SlotParam_NRPNReturn:
	bit 1, (4411:16)
	jr nz, SMF_SlotParam_DataEntryReturn
	ld a, (xiy + 3)
	srl a, 5
	and a, 0x3
	ld w, (xiy)
	and w, 0xc
	or a, w
	ld (4405:16), a
	andmi8 (xiy), 0xf1
	andmi8 (xiy + 3), 0x1f
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	ld (xiy + 2), a
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_DataEntry
	cp (4419:16), 1
	jr z, SMF_SlotParam_DataEntryReturn

SMF_SlotParam_DataEntry:
	ld a, (xiy + 4)
	ld w, (4405:16)
	ld (xiy + 4), w
	ld (4405:16), a

SMF_SlotParam_DataEntryReturn:
	ret

SMF_SlotParam_TypeD2Handler:
	cp (0x2873:16), 15
	jr z, SMF_SlotParam_TypeD2Return
	cp (0x2873:16), 16
	jr z, SMF_SlotParam_TypeD2Return
	ld a, (xiy + 2)
	cp a, 0x40
	jr nc, SMF_SlotParam_TypeD2Impl
	xor a, a
	jr SMF_SlotParam_TypeD2Done

SMF_SlotParam_TypeD2Impl:
	sub a, 0x40
	sla a, 1

SMF_SlotParam_TypeD2Done:
	ld (4405:16), a

SMF_SlotParam_TypeD2Return:
	ret

SMF_SlotParam_Type80Handler:
	ld a, (xiy + 2)
	ld w, a
	and a, 0x40
	srl a, 6
	ld l, (xiy + 3)
	ld h, l
	srl l, 2
	rl w
	and w, 0x7f
	sla h, 1
	or a, h
	and a, 0x3
	ld (xiy + 2), w
	ld (xiy + 3), a
	ret

SMF_SetupSongBankRead:
	push xhl
	ld xhl, (4349:16)
	ld (0x2881:16), xhl
	pop xhl
	ld wa, (0x28af:16)
	ld (0x2887:16), wa

SMF_SetupRead_Adjust:
	push xhl
	ld xhl, (0x2881:16)
	ldb_sri A, 0x07, 0xec, 0xf4
	pop xhl
	cp a, 0x82
	jr z, SMF_SetupRead_Finalize
	calr SMF_AdvanceWritePtr
	jr SMF_SetupRead_Adjust

SMF_SetupRead_Finalize:
	xor hl, hl
	ld l, (3301:16)
	sll hl, 1
	push xde
	ld xde, 0xf1f8
	ld bc, (0x2887:16)
	stw_dri BC, 0x07, 0xe8, 0xec
	srl hl, 1
	ld xde, 0xf218
	ld bc, iy
	stb_dri C, 0x07, 0xe8, 0xec
	pop xde
	ret

SMF_SetupRead_Return:
	ld wa, (0x00ffec:24)
	ld (0xf19e:16), wa
	ld xix, 0xab000
	xor xhl, xhl
	ld l, (0x00ffe3:24)
	sla xhl, 11
	add xix, xhl
	ld xiy, 0xf180
	ldw bc, 0x800
	ldir85
	ret

