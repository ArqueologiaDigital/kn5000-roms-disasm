; =============================================================================
; SMF Configuration
; =============================================================================
;
; SMF (Standard MIDI File) configuration and parameter setup.
; Manages playback settings, channel assignments, and tempo.
; =============================================================================

SMF_ProcessTimedEvent_Entry:
	ldda8 l, 4215

SMF_ProcessTimedEvent_Continue:
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
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	incdi16 1, 3946
	ldda16 xwa, 3946
	ldw de, 0x60
	mul xwa, xde
	ldto_werp DE, 0xE2
	adddm16 3938, xwa
	stda16 3940, xde
	stdi16 3946, 0
	pop xde
	pop xwa
	ldb c, 0x0
	call SMF_CalcTimeDelta
	call SMF_ProcessChannels
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldb a, 0xFF
	ldb w, 0x2F
	ldb l, 0x0
	call SMF_WriteByteLoop
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	cpdi16 4347, 0
	jr nz, SMF_FinalizeAndStartPlayback
	call SMF_FlushToFile
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda8 a, 4599
	st8_24 0x00ffe3, a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay
	stdi16 6699, 2

SMF_Finalize_PopReturn:
	jr SMF_PopReturn

SMF_Finalize_RestoreAndPlay:
	call Vga_RestoreMultiPlaneDisplay
	ldda8 a, 4599
	st8_24 0x00ffe3, a
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
	ldda32 xhl, 6701
	stda16 6699, xhl
	pop xhl
	call Vga_RestoreMultiPlaneDisplay
	ldda8 a, 4599
	st8_24 0x00ffe3, a
	call SoundBank_LoadToWorkRAM
	call SeqPlay_StartWithDisplay
	jr __jrt_nop_F28238
__jrt_nop_F28238:

SMF_PopReturn:
	popw wa
	ret

SMF_HeaderConstants:
	nop
	swi	7
	.byte 0x03
	rcf
	.asciz "MThd"
	.byte 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01
	.byte 0x00
	.asciz "`MTrk"
	.byte 0x00
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
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_ScanChannels_Inactive
	push xde
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xEC
	pop xde
	jr z, SMF_ScanChannels_Inactive
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	cp a, 0x10
	jr z, SMF_ScanChannels_Inactive
	stda8 10359, c
	push xhl
	pushw bc
	call SMF_DispatchEvent
	popw bc
	pop xhl
	jr SMF_ScanChannels_Next

SMF_ScanChannels_Inactive:
	stda8 10359, c
	incdi8 1, 10359
	push xhl
	pushw bc
	call Scoop_SpecialMode_ParamCheckBound
	popw bc
	pop xhl

SMF_ScanChannels_Next:
	add l, 0x3
	inc 1, c
	cp c, 0xF
	jr ule, SMF_ScanChannels_Loop
	ret

SMF_CountActiveChannels:
	xor xhl, xhl
	xor bc, bc

SMF_CountActive_Loop:
	ld16_24 xde, 0x00ffec
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
	ld xde, 0xF250
	bit_dri 7, 0x07, 0xE8, 0xF4
	pop xde
	jr z, SMF_CountActive_Next
	inc 1, l

SMF_CountActive_Next:
	inc 1, c
	cp c, 0xF
	jr ule, SMF_CountActive_Loop
	cps l, 2
	jrl c, SMF_AssignReturn
	xor bc, bc

SMF_FindFreeChannel:
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	jr nc, SMF_FindFree_CheckPart

SMF_FindFree_Next:
	inc 1, c
	cp c, 0xF
	jr ule, SMF_FindFreeChannel

SMF_FindFree_CheckPart:
	ld l, c
	sla l, 1
	add l, c
	xor h, h
	push xix
	ld xix, 0xF250
	bit_dri 7, 0x07, 0xF0, 0xEC
	pop xix
	jr z, SMF_FindFree_Next
	xor xhl, xhl
	ld l, c
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xEC, 0x10
	pop xix
	jr z, SMF_FindFree_Next
	inc 1, c
	stda8 10359, l
	incdi8 1, 10359

SMF_AssignRemainingChannels:
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	jr c, SMF_AssignRemaining_Next
	xor b, b
	ld iz, bc
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF8, 0x10
	pop xix
	jr z, SMF_AssignRemaining_Next
	stda8 9858, c
	incdi8 1, 9858
	ldda8 a, 10359
	stda8 9860, a
	push xhl
	pushw bc
	call SetWall_ValidateAndApply
	popw bc
	pop xhl

SMF_AssignRemaining_Next:
	inc 1, c
	cp c, 0xF
	jr ule, SMF_AssignRemainingChannels

SMF_AssignReturn:
	ret

SMF_ClearWorkArea:
	pushw wa
	pushw bc
	push xix
	xor wa, wa
	ld xix, 0x11F9
	ldw bc, 0x100

SMF_ClearWork_Loop:
	st_dpiw WA, 0xF1
	djnz xbc, SMF_ClearWork_Loop
	pop xix
	popw bc
	popw wa
	ret

SMF_CalcTempoRate:
	ldw de, 0x9
	ldw wa, 0x27C0
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	ldw hl, 0x64
	xor de, de
	extz xwa
	muls xwa, xhl
	ldto_werp DE, 0xE2
	stda16 3948, xwa
	stda16 3950, xde
	ret

SMF_OutputCommandSeq:
	ld xiy, 0x106E
	ldda32 xix, 4376

SMF_OutputCmd_ReadByte:
	ld_spib A, 0xF4
	lda_dpi XBC, 0xF0
	pushw wa
	push xiy
	call SMF_WriteByte
	pop xiy
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	bit 7, a
	jr nz, SMF_OutputCmd_ReadByte
	ldb a, 0xFF
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ldb a, 0x51
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ldb a, 0x3
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ldda8 a, 3950
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ldda8 a, 3949
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ldda8 a, 3948
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376

SMF_OutputCmd_Return:
	ret

SMF_WriteByte:
	push xhl
	pushw bc
	push xwa
	xor xwa, xwa
	lds32 xwa, 2
	stda32 6701, xwa
	pop xwa
	cp xix, 0x17F9
	jr ugt, SMF_WriteByte_SectorCheck
	stda32 4376, xix
	jr SMF_WriteByte_Done

SMF_WriteByte_SectorCheck:
	cpdi16 4347, 0
	jr nz, SMF_WriteByte_NewSector
	ld c, a
	pushw bc
	call SMF_FlushToFile
	popw bc
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	incdi16 1, 4327
	pushw wa
	push xhl
	pushw bc
	pushw de
	ldda16 xwa, 4327
	xor de, de
	lds hl, 4
	ldfr_werp DE, 0xE2
	div xwa, xhl
	ldto_werp DE, 0xE2
	cps de, 0
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
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	incdi16 1, 4347
	ld xwa, 0x13FA
	stda32 4376, xwa
	ld xix, xwa
	ld a, c

SMF_WriteByte_Done:
	popw bc
	pop xhl
	ret

SMF_WriteByteLoop:
	push xiy
	ldda32 xix, 4376
	ld xiy, 0x106E
	pushw wa

SMF_WriteLoop_ReadByte:
	ld_spib A, 0xF4
	lda_dpi XBC, 0xF0
	pushw wa
	pushw hl
	push xiy
	call SMF_WriteByte
	pop xiy
	popw hl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	bit 7, a
	jr nz, SMF_WriteLoop_ReadByte
	popw wa
	ld h, a
	lda_dpi XBC, 0xF0
	pushw wa
	pushw hl
	call SMF_WriteByte
	popw hl
	popw wa
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ld a, w
	lda_dpi XBC, 0xF0
	pushw hl
	call SMF_WriteByte
	popw hl
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	and h, 0xF0
	cp h, 0xC0
	jr z, SMF_WriteLoop_Done
	cp h, 0xD0
	jr z, SMF_WriteLoop_Done
	ld a, l
	lda_dpi XBC, 0xF0
	call SMF_WriteByte
	push xwa
	push xbc
	lds32 xbc, 0
	ldda32 xwa, 6701
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
	ldda32 xix, 4376
	ret

SMF_ChannelHelperReturn:
	ret

SMF_GetNextEvent:
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ldda16 xiy, 9830
	ld_srib3 A, 0x07, 0xEC, 0xF4
	ret

SMF_AdvancePosition:
	ldda16 xwa, 9830
	cp wa, 0xFF
	jr nz, SMF_AdvancePos_Inc
	ldda16 xhl, 10415
	call ToneGen_ComputeBlockPtr
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 10415, xwa
	lds wa, 5
	jr SMF_AdvancePos_Store

SMF_AdvancePos_Inc:
	inc 1, wa

SMF_AdvancePos_Store:
	stda16 9830, xwa
	ret

SMF_CalcTimeDelta:
	pushw wa
	push xhl
	pushw de
	xor wa, wa
	stda16 4229, xwa
	stda8 4231, a
	ldda16 xwa, 3938
	xor b, b
	add wa, bc
	ldda16 xde, 3942
	cp wa, de
	jr nc, SMF_TimeDelta_CheckFirst
	ld wa, de

SMF_TimeDelta_CheckFirst:
	sub wa, de
	stda16 4229, xwa
	bitda 0, 4344
	jr nz, SMF_TimeDelta_Store
	cpdi8 6710, 0
	jr z, SMF_TimeDelta_Store
	adddi16 4229, 384
	stdi8 4344, 1

SMF_TimeDelta_Store:
	stda16 3942, xbc
	stda16 3952, xde
	popw de
	pop xhl
	popw wa
	call SMF_EncodeTimeDelta
	ret

SMF_ProcessChannels:
	push xwa
	xor xwa, xwa
	lds32 xwa, 2
	stda32 6701, xwa
	pop xwa
	call SMF_ClearOutputQueue
	xor hl, hl
	xor bc, bc
	xor iy, iy

SMF_ProcessCh_Loop:
	push xix
	ld xix, 0x11F9
	bit_dri 7, 0x07, 0xF0, 0xEC
	pop xix
	jr z, SMF_ProcessCh_Next
	push xix
	ld xix, 0x11F9
	st_dri3b D, 0x07, 0xF0, 0xEC
	ld wa, (xix + 3)
	pop xix
	cpda16 xwa, 4229
	jr ule, SMF_ProcessCh_MoveToOutput
	subda16 xwa, 4229
	push xix
	ld xix, 0x11F9
	extz xhl
	add xix, xhl
	ld (xix + 3), wa
	pop xix
	jr SMF_ProcessCh_Next

SMF_ProcessCh_MoveToOutput:
	push xde
	ld xde, 0xFAE
	lda_dri3 XHL, 0x07, 0xE8, 0xF4
	ld xde, 0x11F9
	st_dri3b B, 0x07, 0xE8, 0xEC
	ld wa, (xde + 3)
	ld xde, 0xFAE
	st_dri3b B, 0x07, 0xE8, 0xF4
	ld (xde + 1), wa
	pop xde
	add iy, 0x3

SMF_ProcessCh_Next:
	add hl, 0x5
	inc 1, bc
	cp c, 0x20
	jr c, SMF_ProcessCh_Loop
	srl iy, 1
	cps iy, 0
	jr z, SMF_ProcessCh_Finalize
	call SMF_SortOutputQueue

SMF_ProcessCh_Finalize:
	stdi16 3938, 0
	stdi16 3940, 0
	ret

SMF_SendChannelConfig:
	ldda8 a, 4213
	and a, 0xF
	or a, 0xB0
	call SMF_WriteByteLoop
	ret

SMF_FlushToFile:
	call SMF_FileWrite
	ret

SMF_CheckAndFlush:
	cpdi16 4347, 0
	jr z, SMF_CheckFlush_Return
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13FA
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	stda32 6701, xhl
	pop xhl
	pop xbc
	pop xwa

SMF_CheckFlush_Return:
	ret

SMF_DispatchEvent:
	stda8 4008, c
	xor b, b
	ld iy, bc
	anddi8 4331, 254
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0F
	pop xix
	jr nz, SMF_Dispatch_CheckDrumMode
	ordi8 4331, 1

SMF_Dispatch_CheckDrumMode:
	stdi8 4324, 0
	bitda 2, 64941
	jrl z, SMF_Dispatch_NoDrumMode
	stdi8 4324, 255
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr nz, SMF_Dispatch_DrumChannel
	stdi8 4008, 9
	jrl SMF_HandleEventType

SMF_Dispatch_DrumChannel:
	cp iy, 0x9
	jrl nz, SMF_HandleEventType
	bitda 0, 4331
	jrl nz, SMF_HandleEventType
	push xix
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	xor xiy, xiy

SMF_Dispatch_DrumSearch:
	ld bc, iy
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xF4
	pop xix
	jr z, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr z, SMF_Dispatch_DrumFound
	inc 1, iy
	cp iy, 0xF
	jr ule, SMF_Dispatch_DrumSearch
	stdi8 4008, 127
	jrl SMF_HandleEventType

SMF_Dispatch_DrumFound:
	ld wa, iy
	stda8 4008, a
	jr SMF_HandleEventType

SMF_Dispatch_NoDrumMode:
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr nz, SMF_Dispatch_Ch15Remap
	stdi8 4008, 15
	jr SMF_HandleEventType

SMF_Dispatch_Ch15Remap:
	cp iy, 0xF
	jr nz, SMF_HandleEventType
	bitda 0, 4331
	jr nz, SMF_HandleEventType
	push xix
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	xor xiy, xiy

SMF_Dispatch_Ch15Search:
	ld bc, iy
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xF4
	pop xix
	jr z, SMF_Dispatch_Ch15Found
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr z, SMF_Dispatch_Ch15Found
	inc 1, iy
	cp iy, 0xF
	jr ule, SMF_Dispatch_Ch15Search
	stdi8 4008, 127
	jr SMF_HandleEventType

SMF_Dispatch_Ch15Found:
	ld wa, iy
	stda8 4008, a

SMF_HandleEventType:
	inc 1, hl
	push xde
	ld xde, 0xF250
	ld_sriw3 HL, 0x07, 0xE8, 0xEC
	pop xde
	stda16 10415, xhl
	stdi16 9830, 5
	calr SMF_GetNextEvent

SMF_EventType_Switch:
	cp a, 0x82
	jrl z, SMF_EventLoop_Return
	cp a, 0x84
	jr z, SMF_Event_NoteOff82
	cp a, 0xD0
	jr z, SMF_Event_PartD0
	cp a, 0xD1
	jr z, SMF_Event_PartD1
	cp a, 0xD2
	jr z, SMF_Event_PartD2
	cp a, 0xD3
	jr z, SMF_Event_PartD3
	cp a, 0x80
	jr z, SMF_Event_Part80
	and a, 0xF0
	cp a, 0x90
	jr z, SMF_Event_NoteOn
	cp a, 0xB0
	jrl z, SMF_Event_ControlChange
	cp a, 0xC0
	jr z, SMF_Event_ProgramChange
	jrl SMF_EventLoop_Continue

SMF_Event_NoteOff82:
	ldb a, 0x82
	calr SMF_LookupSongBank
	jrl SMF_EventLoop_Return

SMF_Event_PartD0:
	ldb a, 0xA0
	jr SMF_Event_OutputByte

SMF_Event_PartD1:
	ldb a, 0xD0
	jr SMF_Event_OutputByte

SMF_Event_PartD2:
	ldb a, 0xE0
	jr SMF_Event_OutputByte

SMF_Event_PartD3:
	ldb a, 0xF0
	jr SMF_Event_OutputByte

SMF_Event_Part80:
	ldb a, 0xA0
	jr SMF_Event_OutputByte

SMF_Event_NoteOn:
	ldb a, 0x90

SMF_Event_OutputByte:
	orda8 a, 4008
	pushw wa
	calr SMF_LookupSongBank
	popw wa
	and a, 0xF0
	cp a, 0x90
	jrl nz, SMF_EventLoop_Continue
	cpdi8 4324, 0
	jrl z, SMF_EventLoop_Continue
	cpdi8 4008, 9
	jrl nz, SMF_EventLoop_Continue
	jrl SMF_EventLoop_Continue

SMF_Event_ProgramChange:
	calr SMF_AdvanceMultipleEvents
	push_sd16w 0xAF, 0x28
	push_sd16w 0x66, 0x26
	calr SMF_AdvancePosition
	calr SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xAF, 0x28
	cps a, 0
	jrl nz, SMF_EventLoop_Continue
	bitda 0, 4331
	jr z, SMF_ProgChg_UseDefault
	ld l, a
	push xhl
	calr SMF_GetNextEvent
	pop xhl
	ldda8 e, 10359
	xor d, d
	ld iy, de
	cps a, 0
	jr c, SMF_ProgChg_NotFound
	cp a, 0xF
	jr ugt, SMF_ProgChg_NotFound
	cps l, 0
	jr ugt, SMF_ProgChg_NotFound
	ld l, a
	xor h, h
	push xde
	ld xde, 0xF28ADB
	ld_srib3 A, 0x07, 0xE8, 0xEC
	pop xde
	xor xhl, xhl

SMF_ProgChg_SearchPart:
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xEC
	pop xix
	jr z, SMF_ProgChg_Found

SMF_ProgChg_SearchNext:
	inc 1, l
	cp l, 0xF
	jr ule, SMF_ProgChg_SearchPart

SMF_ProgChg_NotFound:
	ldb a, 0x7F
	jr SMF_ProgChg_Write

SMF_ProgChg_Found:
	ld c, l
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_ProgChg_SearchNext
	calr SMF_ResolveChannel
	jr SMF_ProgChg_Write

SMF_ProgChg_UseDefault:
	ldda8 a, 4008

SMF_ProgChg_Write:
	calr SMF_LookupSongBank
	jrl SMF_EventLoop_Continue

SMF_Event_ControlChange:
	calr SMF_AdvanceMultipleEvents
	push_sd16w 0xAF, 0x28
	push_sd16w 0x66, 0x26
	calr SMF_AdvancePosition
	calr SMF_GetNextEvent
	popw_dd16 0x66, 0x26
	popw_dd16 0xAF, 0x28
	ld l, a
	push xhl
	calr SMF_GetNextEvent
	pop xhl
	stda8 4340, a
	cps a, 0
	jr c, SMF_CtrlChg_NotFound
	cp a, 0xF
	jr ugt, SMF_CtrlChg_NotFound
	cps l, 3
	jr c, SMF_CtrlChg_NotFound
	cp l, 0xB
	jr ugt, SMF_CtrlChg_NotFound
	cps l, 6
	jr z, SMF_CtrlChg_NotFound
	jr SMF_CtrlChg_UseDefault
	bitda 0, 4331
	jr z, SMF_EventLoop_SpecialCC
	ld l, a
	xor h, h
	push xde
	ld xde, 0xF28ADB
	ld_srib3 A, 0x07, 0xE8, 0xEC
	pop xde
	xor xhl, xhl

SMF_CtrlChg_SearchPart:
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xEC
	pop xix
	jr z, SMF_CtrlChg_Found

SMF_CtrlChg_SearchNext:
	inc 1, l
	cp l, 0xF
	jr ule, SMF_CtrlChg_SearchPart

SMF_CtrlChg_NotFound:
	ldb a, 0x7F
	jr SMF_CtrlChg_Write

SMF_CtrlChg_Found:
	ld c, l
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_CtrlChg_SearchNext
	calr SMF_ResolveChannel
	jr SMF_CtrlChg_Write

SMF_CtrlChg_UseDefault:
	ldda8 a, 4008

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
	nop
	.byte 0x02, 0x01, 0x0b, 0x08, 0x09
	ldwio	3, 1284
	ei	0x07
	scf
	ccf
	swi	7
	zcf
	swi	7
	incf
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7
	swi	7

SMF_EncodeTimeDelta:
	stdi16 4206, 0
	stdi16 4208, 0
	cpdi8 4231, 0
	jr nz, SMF_Encode_LargeValue
	cpdi16 4229, 127
	jrl ule, SMF_Encode_OneByte
	cpdi16 4229, 16383
	jr ule, SMF_Encode_TwoBytes

SMF_Encode_LargeValue:
	cpdi8 4231, 31
	jr ule, SMF_Encode_ThreeBytes
	stdi8 4231, 31
	stdi8 4230, 255
	stdi8 4229, 255

SMF_Encode_ThreeBytes:
	ldda8 a, 4229
	ld w, a
	and w, 0x80
	and a, 0x7F
	rlc w
	ldda8 l, 4230
	ld h, l
	and h, 0xC0
	rlc_i_8 h, 2
	sla l, 1
	and l, 0x1
	or l, w
	or l, 0x80
	ldda8 c, 4231
	sla c, 2
	or c, h
	or c, 0x80
	stda8 4206, c
	stda8 4207, l
	stda8 4208, a
	jr SMF_Encode_Return

SMF_Encode_TwoBytes:
	ldda8 a, 4229
	ld w, a
	and a, 0x7F
	and w, 0x80
	rlc w
	ldda8 l, 4230
	ld h, l
	sla l, 1
	or l, w
	or l, 0x80
	xor c, c
	stda8 4206, l
	stda8 4207, a
	jr SMF_Encode_Return

SMF_Encode_OneByte:
	ldda8 a, 4229
	and a, 0x7F
	xor l, l
	xor c, c
	stda8 4206, a

SMF_Encode_Return:
	ret

SMF_ClearOutputQueue:
	push xix
	ld xix, 0xFAE
	ldw bc, 0x60
	ldw wa, 0xFF

SMF_ClearQueue_Loop:
	lda_dpi XBC, 0xF0
	djnz xbc, SMF_ClearQueue_Loop
	pop xix
	ret

SMF_SortOutputQueue:
	cps iy, 0
	jr z, SMF_Sort_Return
	xor de, de
	cpdi8 4014, 255
	jr z, SMF_Sort_Return

SMF_Sort_OuterLoop:
	ld xiy, 0xFAE
	ld xix, 0xFB1
	st_dri3b E, 0x07, 0xF4, 0xE8
	st_dri3b D, 0x07, 0xF0, 0xE8
	cp (xiy), 0xFF
	jr z, SMF_Sort_Finalize
	ld wa, (xiy + 1)

SMF_Sort_InnerLoop:
	ld l, (xix)
	cp l, 0xFF
	jr z, SMF_Sort_AdvanceOuter
	cp wa, (xix + 1)
	jr ugt, SMF_Sort_Swap
	add xix, 0x3
	cp xix, 0x100B
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
	ld xwa, 0x13FA
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	stda32 6701, xhl
	pop xhl
	pop xbc
	pop xwa
	ret

SMF_FileWriteAndClear:
	push xwa
	push xbc
	push xhl
	ld xwa, 0x13FA
	ld xbc, 0x400
	call FileIO_WriteByte_Impl
	stda32 6701, xhl
	pop xhl
	pop xbc
	pop xwa
	call SMF_ClearFileBuffer
	ret

SMF_LookupSongBank:
	ldda16 xhl, 10415
	extz xhl
	dec 1, xhl
	sla xhl, 8
	addda32 xhl, 7514
	ldda16 xiy, 9830
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	ret

SMF_AdvanceMultipleEvents:
	lds bc, 2

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
	cpdi8 4324, 255
	jr nz, SMF_Resolve_NoDrum
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr nz, SMF_Resolve_DrumCh9
	ldb a, 0x9
	jrl SMF_Resolve_Return

SMF_Resolve_DrumCh9:
	cp iy, 0x9
	jrl nz, SMF_Resolve_Return
	push xix
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	xor xiy, xiy

SMF_Resolve_DrumSearch:
	ld bc, iy
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xF4
	pop xix
	jr z, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr z, SMF_Resolve_DrumFound
	inc 1, iy
	cp iy, 0xF
	jr ule, SMF_Resolve_DrumSearch
	ldb a, 0x7F
	jr SMF_Resolve_Return

SMF_Resolve_DrumFound:
	ld wa, iy
	jr SMF_Resolve_Return

SMF_Resolve_NoDrum:
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr nz, SMF_Resolve_Ch15Check
	ldb a, 0xF
	jr SMF_Resolve_Return

SMF_Resolve_Ch15Check:
	cp iy, 0xF
	jr nz, SMF_Resolve_Return
	push xix
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	pop xix
	xor xiy, xiy

SMF_Resolve_Ch15Search:
	ld bc, iy
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xF4
	pop xix
	jr z, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	pop xix
	jr z, SMF_Resolve_Ch15Found
	inc 1, iy
	cp iy, 0xF
	jr ule, SMF_Resolve_Ch15Search
	ldb a, 0x7F
	jr SMF_Resolve_Return

SMF_Resolve_Ch15Found:
	ld wa, iy
	jr __jrt_nop_F28D6B
__jrt_nop_F28D6B:

SMF_Resolve_Return:
	ret

SMF_UpdateTempo:
	ldda16 xbc, 3942
	ld xiy, 0xFAE
	xor hl, hl

SMF_UpdateTempo_Loop:
	ld_srib3 A, 0x07, 0xF4, 0xEC
	cp a, 0xFF
	jr z, SMF_UpdateTempo_Finalize
	xor w, w
	ld ix, wa
	extz xix
	sla ix, 2
	add ix, wa
	push xde
	ld xde, 0x11F9
	add xde, xix
	ld wa, (xde + 3)
	pop xde
	cps l, 0
	jr nz, SMF_UpdateTempo_SubtractBase
	stda16 4229, xwa
	jr SMF_UpdateTempo_Encode

SMF_UpdateTempo_SubtractBase:
	ld de, wa
	subda16 xde, 3942
	cps de, 0
	jr ge, SMF_UpdateTempo_ClampZero
	lds de, 0

SMF_UpdateTempo_ClampZero:
	stda16 4229, xde

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
	stda16 3942, xwa
	push xde
	ld xde, 0x11F9
	extz xix
	add xde, xix
	ld wa, (xde + 1)
	pop xde
	push xhl
	ldb l, 0x0
	pushw bc
	push xix
	calr SMF_WriteByteLoop
	pop xix
	popw bc
	pop xhl
	push xde
	ld xde, 0x11F9
	and_srib_im 0x07, 0xE8, 0xF0, 0x3F
	pop xde
	add hl, 0x3
	cp hl, 0x60
	jr nc, SMF_UpdateTempo_Finalize
	jr SMF_UpdateTempo_Loop

SMF_UpdateTempo_Finalize:
	ldda16 xwa, 3942
	addda16 xwa, 3952
	stda16 3942, xbc
	addda16 xbc, 3938
	sub bc, wa
	stda16 4229, xbc
	calr SMF_EncodeTimeDelta
	stdi16 3938, 0
	stdi16 3940, 0
	ret

SMF_CalcFilePosition:
	xor wa, wa
	stda16 4002, xwa
	stda16 4004, xwa
	ldda16 xwa, 4347
	mul wa, 0x400
	ldda32 xhl, 4376
	sub xhl, 0x13FA
	add xwa, xhl
	sub xwa, 0x16
	ldto_werp DE, 0xE2
	stda8 4002, d
	stda8 4003, e
	stda8 4004, w
	stda8 4005, a
	ret

SMF_ClearFileBuffer:
	push xix
	push xwa
	ldw wa, 0x200
	ld xix, 0x13FA

SMF_ClearBuf_Loop:
	stiw_dpi 0xF1, 0x00, 0x00
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
	ldda16 xiy, 10359
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	jr nz, SMF_GlobalCh_NoDrum

SMF_GlobalCh_DrumMode:
	cpdi8 4324, 255
	jp_24 nz, 0xF28E91
	stdi8 6881, 9
	jp SMF_GlobalCh_Return

SMF_GlobalCh_DrumCh15:
	stdi8 6881, 15
	jp SMF_GlobalCh_Return

SMF_GlobalCh_NoDrum:
	cpdi8 4324, 255
	jp_24 nz, 0xF28EB1
	cp iy, 0x9
	jp_24 z, 0xF28EBE
	jp SMF_GlobalCh_Found

SMF_GlobalCh_NonDrumCh15:
	cp iy, 0xF
	jp_24 z, 0xF28EBE
	jp SMF_GlobalCh_Found

SMF_GlobalCh_FreeSearch:
	ld xix, 0xF1A0
	ld_srib3 A, 0x07, 0xF0, 0xF4
	xor xiy, xiy

SMF_GlobalCh_SearchLoop:
	ld bc, iy
	ldfr_berp A, 0x3C
	ldfr_werp DE, 0x3E
	ld16_24 xde, 0x00ffec
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3E
	ldto_berp A, 0x3C
	jr c, SMF_GlobalCh_Found
	ld xix, 0xF1A0
	cp_srib_mr A, 0x07, 0xF0, 0xF4
	jr z, SMF_GlobalCh_Found
	ld xix, 0xF1A0
	cp_srib_im 0x07, 0xF0, 0xF4, 0x0C
	jr z, SMF_GlobalCh_Found
	inc 1, iy
	cp iy, 0xF
	jr ule, SMF_GlobalCh_SearchLoop
	jp SMF_GlobalCh_DrumMode

SMF_GlobalCh_Found:
	ld wa, iy
	stda8 6881, a

SMF_GlobalCh_Return:
	pop xde
	pop xbc
	pop xwa
	pop xiy
	pop xix
	ret

SMF_LoadSongBank:
	call SMF_DetectFormat
	ldda8 a, 4394
	cps a, 0
	jr z, SMF_LoadBank_Return
	ld xde, 0xAB000
	st_dri3b B, 0xE9, 0xC7, 0x00
	cpdi8 4394, 1
	jr nz, SMF_LoadBank_ReadEntries
	ld (xde), 0x0

SMF_LoadBank_ReadEntries:
	ld a, (xde)
	xor xbc, xbc
	ld c, a
	ld xhl, xbc
	mul hl, 0x800
	add xhl, 0xAB000
	push xhl
	ldw de, 0xAF
	ld_sriw3 WA, 0x07, 0xEC, 0xE8
	stda16 61999, xwa
	pop xhl
	ldw de, 0xB1
	ld_sriw3 WA, 0x07, 0xEC, 0xE8
	stda16 62001, xwa
	sti8_24 0x00ffe3, 0x00

SMF_LoadBank_EventLoop:
	calr SMF_SetupReadPointers
	calr SMF_ResetPlaybackState
	call SMF_SetupRead_Return
	incdi8_24 1, 65507
	cpi8_24 0x00ffe3, 0x0a
	jr c, SMF_LoadBank_EventLoop

SMF_LoadBank_Return:
	ret

SMF_SetupReadPointers:
	ldda16 xwa, 61999
	stda16 10351, xwa
	ldda16 xwa, 62001
	stda16 10353, xwa
	call SongBank_LoadToWorkArea
	ret

SMF_ResetPlaybackState:
	anddi8 4404, 254
	anddi8 4404, 253
	anddi8 4411, 254
	anddi8 4411, 253
	anddi8 4404, 251
	stdi8 4419, 0
	ordi8 4393, 2
	xor a, a
	stda8 3301, a
	calr SMF_DetectFormat
	ldda8 a, 4394
	cps a, 0
	jr z, SMF_Parse_Complete

SMF_ParseEvents:
	call SetWall_ParserInit
	ldda8 a, 3301
	cp a, 0xF
	jr ugt, SMF_Parse_Complete
	ldda8 c, 3301
	ldda16 xwa, 61854
	stdi8 10362, 0
	anddi8 10363, 191
	xor xhl, xhl
	ldda8 l, 3301
	ld xix, 0xF1A0
	add xix, xhl
	ld l, (xix)
	stda8 10355, l
	cp l, 0xF
	jr nz, SMF_Parse_ClearAutoFlag
	ordi8 4393, 1
	jr SMF_Parse_NextChannel

SMF_Parse_ClearAutoFlag:
	anddi8 4393, 254
	xor h, h

SMF_Parse_NextChannel:
	ldda8 a, 3301
	inc 1, a
	calr SMF_ConfigSlot
	anddi8 4393, 254
	anddi8 4393, 251
	stdi8 4419, 0
	incdi8 1, 3301
	jr SMF_ParseEvents

SMF_Parse_Complete:
	stdi8 3301, 0
	anddi8 4393, 254
	anddi8 4393, 253
	anddi8 4393, 251
	anddi8 4404, 254
	anddi8 4404, 253
	anddi8 4411, 254
	anddi8 4411, 253
	anddi8 4404, 251
	stdi8 4419, 0
	ret

SMF_TranslateChannel:
	push xix
	ld xix, 0xF2908D
	xor hl, hl
	ld l, a
	ld_srib3 W, 0x07, 0xF0, 0xEC
	cp w, 0xFF
	jr z, SMF_Translate_Return
	cpdi8 4394, 3
	jr nz, SMF_Translate_Apply
	cp a, 0xE
	jr z, SMF_Translate_0xE
	cp a, 0x10
	jr nz, SMF_Translate_Apply
	ldb w, 0x18
	jr SMF_Translate_Apply

SMF_Translate_0xE:
	ldb w, 0x17

SMF_Translate_Apply:
	ld a, w

SMF_Translate_Return:
	pop xix
	ret

SMF_ChannelTranslationTable:
	nop
	.byte 0x01, 0x02, 0x03, 0x04
	halt
	ei	0x07
	ldio	9, 10
	pushw 3340
	ld	xbc, 1208959502
	rcf
	.byte 0x90, 0x11, 0x50, 0x51
	jrl	f, 4721
	zcf
	push_a
	pop_a
	ex_ff
	swi	7
	.byte 0x98, 0x40, 0xff, 0x52, 0x92, 0xff
	jrl	le, -26113
	swi	7
	swi	7
	swi	7
	cp	(xwa), l
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x53
	swi	7
	swi	7
	swi	7
	swi	7
	.byte 0x9a
	.fill 8, 1, 0xff

SMF_ConfigSlot:
	anddi8 10363, 251
	xor w, w
	stdi8 10362, 0
	stda16 10365, xwa
	stdi16 10367, 1
	call SetWall_SlotResolve
	cpdi8 10362, 0
	jr z, SMF_ConfigSlot_Setup
	jrl SMF_ConfigSlot_Return

SMF_ConfigSlot_Setup:
	push xiy
	calr SMF_SetupSongBankRead
	pop xiy
	push xhl
	ldda32 xhl, 4349
	stda32 10369, xhl
	pop xhl
	stda16 10373, xiy
	ldda16 xwa, 10415
	stda16 10375, xwa
	stda16 10377, xiy
	stda16 10379, xwa
	ld ix, iy
	ldda16 xhl, 3376

SMF_ConfigSlot_EventLoop:
	push xde
	ldda32 xde, 4349
	ld_srib3 A, 0x07, 0xE8, 0xF0
	pop xde
	ldb w, 0xF0
	and w, a
	cp a, 0x82
	jrl z, SMF_ConfigSlot_EndOfTrack
	cp a, 0xD2
	jr z, SMF_ConfigSlot_TypeD2
	cp a, 0x80
	jr z, SMF_ConfigSlot_Type80
	cp w, 0xC0
	jr z, SMF_ConfigSlot_TypeC0
	cp w, 0xB0
	jr z, SMF_ConfigSlot_TypeB0
	jr SMF_ConfigSlot_DefaultHandler
	calr SMF_AdvanceReadPtr
	cpdi8 10362, 0
	jr z, SMF_ConfigSlot_EventLoop
	jrl SMF_ConfigSlot_Return

SMF_ConfigSlot_DefaultHandler:
	push xhl
	ldda32 xhl, 10369
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pop xhl

SMF_ConfigSlot_WriteAndContinue:
	calr SMF_AdvanceWritePtr
	cpdi8 10362, 0
	jrl nz, SMF_ConfigSlot_Return

SMF_ConfigSlot_AdvanceEvent:
	calr SMF_AdvanceReadPtr
	cpdi8 10362, 0
	jrl nz, SMF_ConfigSlot_Return
	push xde
	ldda32 xde, 4349
	bit_dri 7, 0x07, 0xE8, 0xF0
	pop xde
	jr nz, SMF_ConfigSlot_EventLoop
	push xde
	ldda32 xde, 4349
	ld_srib3 A, 0x07, 0xE8, 0xF0
	pop xde
	jr SMF_ConfigSlot_DefaultHandler

SMF_ConfigSlot_TypeB0:
	stdi16 4402, 5
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_TypeC0:
	stdi16 4402, 4
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_TypeD2:
	stdi16 4402, 2
	jr SMF_ConfigSlot_StoreType

SMF_ConfigSlot_Type80:
	stdi16 4402, 3

SMF_ConfigSlot_StoreType:
	pushw wa
	stda8 3310, a
	anddi8 3310, 2
	ldda8 a, 3310
	sla a, 6
	stda8 3310, a
	stda8 4395, a
	anddi8 4395, 1
	ldda8 a, 4395
	sla a, 7
	stda8 4395, a
	popw wa
	push xiy
	pushw hl
	xor hl, hl
	ld xiy, 0x112C
	ld (xiy), a

SMF_ConfigSlot_ReadDataLoop:
	inc 1, hl
	push xiy
	pushw hl
	calr SMF_AdvanceReadPtr
	popw hl
	pop xiy
	push xde
	ldda32 xde, 4349
	ld_srib3 A, 0x07, 0xE8, 0xF0
	pop xde
	lda_dri3 XBC, 0x07, 0xF4, 0xEC
	cpda16 xhl, 4402
	jr c, SMF_ConfigSlot_ReadDataLoop
	popw hl
	pop xiy
	cpdi8 10362, 0
	jrl nz, SMF_ConfigSlot_Return
	anddi8 4404, 254
	anddi8 4404, 251
	anddi8 4404, 253
	anddi8 4411, 254
	anddi8 4411, 253
	ldda8 a, 4394
	cps a, 1
	jr z, SMF_Config_Format1
	cps a, 2
	jr z, SMF_Config_Format2
	cps a, 3
	jr z, SMF_Config_Format3
	cps a, 4
	jp_24 z, 0xF29306
	cps a, 5
	jp_24 z, 0xF29306
	jrl SMF_ConfigSlot_Return

SMF_Config_Format1:
	push xix
	push xiy
	ld xiy, 0x112C
	cpdi16 4402, 4
	jr nz, SMF_Config_Format1_Done
	calr SMF_SlotParam_PortamentoSwitch

SMF_Config_Format1_Done:
	pop xiy
	pop xix
	jr SMF_Config_ProcessSlotData

SMF_Config_Format2:
	push xix
	push xiy
	ld xiy, 0x112C
	cpdi16 4402, 5
	jr nz, SMF_Config_Format2_Done

SMF_Config_Format2_Done:
	pop xiy
	pop xix
	jr SMF_Config_ProcessSlotData

SMF_Config_Format3:
	push xix
	push xiy
	ld xiy, 0x112C
	cpdi16 4402, 5
	jr nz, SMF_Config_Format3_Done
	calr SMF_SlotChain_Fmt3Voice

SMF_Config_Format3_Done:
	pop xiy
	pop xix
	jr __jrt_nop_F29282
__jrt_nop_F29282:

SMF_Config_ProcessSlotData:
	push xix
	push xiy
	ld xiy, 0x112C
	cpdi16 4402, 4
	jr z, SMF_Config_Count4
	cpdi16 4402, 5
	jr z, SMF_Config_Count5
	cpdi16 4402, 2
	jr z, SMF_Config_Count2
	cpdi16 4402, 3
	jr z, SMF_Config_Count3
	jr SMF_Config_PopAndContinue

SMF_Config_Count2:
	calr SMF_SlotParam_TypeD2Handler
	ordi8 4404, 1
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
	anddi8 4411, 254
	jr SMF_Config_PopAndContinue

SMF_Config_Count4:
	calr SMF_SlotParam_NRPNReturn
	ordi8 4404, 1

SMF_Config_PopAndContinue:
	pop xiy
	pop xix
	jr SMF_Config_WriteOutput

SMF_Config_Format4or5:
	push xix
	push xiy
	ld xiy, 0x112C
	cpdi16 4402, 5
	jr z, SMF_Config_Format5_Handler
	jr SMF_Config_PopAndContinue

SMF_Config_Format5_Handler:
	call SMF_SlotParam_Format5Handler
	anddi8 4411, 254
	jr SMF_Config_PopAndContinue

SMF_Config_WriteOutput:
	bitda 1, 4404
	jr nz, SMF_Config_HandleBit1
	push xix
	push xhl
	xor hl, hl
	ld xix, 0x112C
	ld a, (xix)
	push xhl
	ldda32 xhl, 10369
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pop xhl

SMF_Config_WriteLoop:
	inc 1, hl
	push xix
	push xhl
	calr SMF_AdvanceWritePtr
	pop xhl
	pop xix
	ld_srib3 A, 0x07, 0xF0, 0xEC
	push xhl
	ldda32 xhl, 10369
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pop xhl
	cpda16 xhl, 4402
	jr c, SMF_Config_WriteLoop
	pop xhl
	pop xix
	cpdi8 10362, 0
	jrl nz, SMF_ConfigSlot_Return
	bitda 0, 4404
	jr nz, SMF_Config_OutputOverride1
	bitda 2, 4404
	jr nz, SMF_Config_OutputOverride6
	jrl SMF_ConfigSlot_WriteAndContinue

SMF_Config_HandleBit1:
	anddi8 4404, 253
	anddi8 4404, 253
	jrl SMF_ConfigSlot_AdvanceEvent

SMF_Config_OutputOverride1:
	ldda8 a, 3301
	inc 1, a
	ldb w, 0x1
	jr SMF_Config_SaveAndRestore

SMF_Config_OutputOverride6:
	ldda8 a, 3301
	inc 1, a
	ldb w, 0x6

SMF_Config_SaveAndRestore:
	push xix
	push xiy
	push xhl
	push xbc
	xor xbc, xbc
	ld xiy, 0x1135
	xor hl, hl
	ldda8 l, 3301
	sll hl, 1
	push xde
	ld xde, 0xC9E
	ld_sriw3 BC, 0x07, 0xE8, 0xEC
	stda16 4412, xbc
	ldda16 xbc, 10379
	st_dri3w BC, 0x07, 0xE8, 0xEC
	srl hl, 1
	ld xde, 0xCBE
	ld_srib3 C, 0x07, 0xE8, 0xEC
	stda8 4414, c
	ld bc, ix
	bitda 2, 4404
	jr z, SMF_Config_GetTableEntry
	push xix
	xor xix, xix
	ld xix, xbc
	calr SMF_AdvanceReadPtr
	ld xbc, xix
	pop xix

SMF_Config_GetTableEntry:
	lda_dri3 XHL, 0x07, 0xE8, 0xEC
	pop xde
	cps a, 3
	jr nz, SMF_Config_CallHandler
	nop

SMF_Config_CallHandler:
	call VoiceSlot_AssignWrapper
	xor hl, hl
	ldda8 l, 3301
	sll hl, 1
	push xde
	ld xde, 0xC9E
	ldda16 xbc, 4412
	st_dri3w BC, 0x07, 0xE8, 0xEC
	srl hl, 1
	ld xde, 0xCBE
	ldda8 c, 4414
	lda_dri3 XHL, 0x07, 0xE8, 0xEC
	pop xde
	pop xbc
	pop xhl
	pop xiy
	pop xix
	bitda 2, 4404
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
	anddi8 4404, 254
	anddi8 4404, 251
	jrl SMF_ConfigSlot_WriteAndContinue

SMF_ConfigSlot_EndOfTrack:
	push xhl
	ldda32 xhl, 10369
	lda_dri3 XBC, 0x07, 0xEC, 0xF4
	pop xhl
	ldda16 xwa, 10375
	stda16 10399, xwa
	call SetWall_EventOutput
	call SetWall_EventAdvanceCheck

SMF_ConfigSlot_Return:
	ret

SMF_ConfigSlot_CodeBlock:
	push	xhl
	push	xwa
	ldda16	wa, 10375
	stda16	4415, wa
	stda16	4417, iy
	incdi16	1, 4417
	cpdi16	4417, 255
	jr	ule, 47
	ldda32	xhl, 10369
	ld	wa, (xhl+3)
	stda16	4415, wa
	stda16	10375, wa
	ld	hl, wa
	calr	192
	ldda32	xhl, 4349
	.byte 0xb3, 0xcf
	jr	nz, 7
	stdi8	10362, 2
	jr	12
	stda32	10369, xhl
	stdi16	4417, 5
	lds	iy, 5
	pop	xwa
	pop	xhl
	ret

SMF_DetectFormat:
	stdi8 4394, 0
	ld xde, 0xAB000
	lda xde, (xde + 4)
	ld a, (xde + 1)
	ld w, (xde + 2)
	cps a, 1
	jr nz, SMF_Format_Return
	cps w, 3
	jr z, SMF_Format_Version1
	cps w, 6
	jr z, SMF_Format_Version4
	cps w, 7
	jr z, SMF_Format_Version5
	jr SMF_Format_Return

SMF_Format_Version5:
	stdi8 4394, 5
	jr SMF_Format_Return

SMF_Format_Version4:
	stdi8 4394, 4
	jr SMF_Format_Return

SMF_Format_Version1:
	stdi8 4394, 1

SMF_Format_Return:
	ret

SMF_AdvanceReadPtr:
	inc 1, ix
	cp ix, 0xFF
	jr ule, SMF_AdvanceRead_Return
	ldda16 xhl, 10379
	calr SMF_CalcPageAddress
	ldda32 xhl, 4349
	ld wa, (xhl + 3)
	stda16 10379, xwa
	ld hl, wa
	calr SMF_CalcPageAddress
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, SMF_AdvanceRead_NewPage
	stdi8 10362, 2
	jr SMF_AdvanceRead_Return

SMF_AdvanceRead_NewPage:
	lds ix, 5

SMF_AdvanceRead_Return:
	ret

SMF_AdvanceWritePtr:
	ldda32 xwa, 4349
	push xwa
	inc 1, iy
	cp iy, 0xFF
	jr ule, SMF_AdvanceWrite_Return
	ldda32 xhl, 10369
	ld wa, (xhl + 3)
	stda16 10375, xwa
	ld hl, wa
	calr SMF_CalcPageAddress
	ldda32 xhl, 4349
	bitm 7, (xhl)
	jr nz, SMF_AdvanceWrite_NewPage
	stdi8 10362, 2
	jr SMF_AdvanceWrite_Return

SMF_AdvanceWrite_NewPage:
	stda32 10369, xhl
	lds iy, 5

SMF_AdvanceWrite_Return:
	pop xwa
	stda32 4349, xwa
	ret

SMF_CalcPageAddress:
	dec 1, hl
	extz xhl
	sla xhl, 8
	addda32 xhl, 7514
	stda32 4349, xhl
	xor xhl, xhl
	ret

SMF_SlotChain_CheckInstr:
	bitda 0, 4411
	jr nz, SMF_SlotChain_InstrReturn
	cpdi8 10355, 16
	jr z, SMF_SlotChain_InstrReturn
	ld a, (xiy + 2)
	cp a, 0x1E
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotChain_StoreInstr:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	ordi8 4411, 1

SMF_SlotChain_InstrReturn:
	ret

SMF_SlotChain_CheckVoice:
	bitda 0, 4411
	jr nz, SMF_SlotChain_VoiceReturn
	cpdi8 10355, 15
	jr z, SMF_SlotChain_VoiceReturn
	cpdi8 10355, 16
	jr z, SMF_SlotChain_VoiceReturn
	ld a, (xiy + 2)
	cp a, 0x1E
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotChain_StoreVoice:
	ld (xiy + 2), a
	ld (xiy + 3), 0x4
	calr SMF_SlotChain_ExtendedVoice
	ordi8 4411, 1

SMF_SlotChain_VoiceReturn:
	ret

SMF_SlotChain_ExtendedVoice:
	cpdi8 4394, 3
	jr z, SMF_SlotChain_ExtVoiceReturn
	ld a, (xiy + 5)
	orda8 a, 3310
	cp a, 0x20
	jr nz, SMF_SlotChain_ExtVoiceReturn
	ld w, (xiy + 4)
	orda8 w, 4395
	and a, w
	and a, 0x20
	cps a, 0
	jr z, SMF_SlotChain_ExtVoiceDefault
	xor hl, hl
	ld l, (xiy + 2)
	mul l, 0x20
	add hl, 0x5
	add hl, 0x2
	ld xix, 0xEDB3FC
	ld_srib3 A, 0x07, 0xF0, 0xEC
	jr SMF_SlotChain_ExtVoiceStore

SMF_SlotChain_ExtVoiceDefault:
	ldb a, 0x0

SMF_SlotChain_ExtVoiceStore:
	ld (xiy + 4), a
	ld (xiy + 5), 0x7F
	ld (xiy + 3), 0x5

SMF_SlotChain_ExtVoiceReturn:
	ret

SMF_SlotChain_Fmt3Voice:
	ldda8 a, 4394
	cps a, 3
	jr nz, SMF_SlotChain_Fmt3Return
	cpdi8 10355, 15
	jr z, SMF_SlotChain_Fmt3Return
	cpdi8 10355, 16
	jr z, SMF_SlotChain_Fmt3Return
	ld a, (xiy + 2)
	cp a, 0x1E
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
	cp (xiy + 3), 0xC
	jr nz, SMF_SlotChain_Fmt3Return
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotChain_Fmt3Resolve
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotChain_Fmt3Resolve:
	ld (xiy + 2), a
	ld (xiy + 3), 0x5
	ordi8 4411, 1

SMF_SlotChain_Fmt3Return:
	ret

SMF_SlotParam_Volume:
	bitda 0, 4411
	jrl nz, SMF_SlotParam_VolumeReturn
	cpdi8 4394, 3
	jr z, SMF_SlotParam_VolumeWrite
	ld a, (xiy + 2)
	cp a, 0x1E
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_VolumeCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	ldda8 a, 4395
	andda8 a, 3310
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
	ld xix, 0xEDB3FC
	ld_srib3 A, 0x07, 0xF0, 0xEC
	ld (xiy + 4), a

SMF_SlotParam_VolumeStore:
	ld (xiy + 5), 0x7F
	andmi8 (xiy), 0xFC
	ordi8 4411, 1
	jr SMF_SlotParam_VolumeReturn

SMF_SlotParam_VolumeWrite:
	ld a, (xiy + 2)
	cp a, 0x1E
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_VolumeDone:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	ordi8 4411, 1

SMF_SlotParam_VolumeReturn:
	ret

SMF_SlotParam_Pan:
	bitda 0, 4411
	jr nz, SMF_SlotParam_PanReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_PanReturn
	cpdi8 10355, 16
	jr z, SMF_SlotParam_PanReturn
	cp (xiy + 2), 0x27
	jr nz, SMF_SlotParam_PanReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0x8
	ordi8 4411, 1

SMF_SlotParam_PanReturn:
	ret

SMF_SlotParam_Expression:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ExprReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_ExprReturn
	cpdi8 10355, 16
	jr z, SMF_SlotParam_ExprReturn
	cp (xiy + 2), 0x2B
	jr nz, SMF_SlotParam_ExprReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0x9
	ordi8 4411, 1

SMF_SlotParam_ExprReturn:
	ret

SMF_SlotParam_Reverb:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ReverbReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_ReverbReturn
	cpdi8 10355, 16
	jr z, SMF_SlotParam_ReverbReturn
	cp (xiy + 2), 0x29
	jr nz, SMF_SlotParam_ReverbReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0xB
	ordi8 4411, 1

SMF_SlotParam_ReverbReturn:
	ret

SMF_SlotParam_Chorus:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ChorusReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_ChorusReturn
	cpdi8 10355, 16
	jr z, SMF_SlotParam_ChorusReturn
	cp (xiy + 2), 0x2A
	jr nz, SMF_SlotParam_ChorusReturn
	ld a, (xiy + 3)
	ld (xiy + 2), a
	ld (xiy + 3), 0xA
	ordi8 4411, 1

SMF_SlotParam_ChorusReturn:
	ret

SMF_SlotParam_ModWheel:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ModWheelReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_ModWheelImpl
	cpdi8 10355, 16
	jr z, SMF_SlotParam_ModWheelImpl
	cpdi8 10355, 13
	jr z, SMF_SlotParam_ModWheelImpl
	cpdi8 10355, 14
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_ModWheelCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	ordi8 4411, 1
	ld a, (xiy + 4)
	orda8 a, 4395
	ld w, (xiy + 5)
	orda8 w, 3310
	cps w, 4
	jr z, SMF_SlotParam_ModWheelStore
	cps w, 3
	jr nz, SMF_SlotParam_ModWheelReturn
	andmi8 (xiy + 4), 0xFB
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
	bitda 0, 4411
	jr nz, SMF_SlotParam_Detune
	cpdi8 10355, 15
	jr z, SMF_SlotParam_PitchBendImpl
	cpdi8 10355, 16
	jr z, SMF_SlotParam_PitchBendImpl
	cpdi8 10355, 13
	jr z, SMF_SlotParam_PitchBendImpl
	cpdi8 10355, 14
	jr nz, SMF_SlotParam_Detune

SMF_SlotParam_PitchBendImpl:
	cp (xiy + 2), 0x12
	jr nz, SMF_SlotParam_Detune
	cp (xiy + 3), 0xA
	jr nz, SMF_SlotParam_Detune
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_PitchBendCalc
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_PitchBendCalc:
	ld (xiy + 2), a
	ld (xiy + 3), 0x7
	ordi8 4411, 1
	ld a, (xiy + 4)
	and a, 0x10
	cps a, 0
	jr z, SMF_SlotParam_PitchBendStore
	ldb a, 0x20
	jr SMF_SlotParam_PitchBendReturn

SMF_SlotParam_PitchBendStore:
	ldb a, 0x0

SMF_SlotParam_PitchBendReturn:
	ld (xiy + 4), a
	ld a, (xiy + 5)
	cp a, 0x10
	jr nz, SMF_SlotParam_Detune
	ld (xiy + 5), 0x30
	call SMF_SlotParam_DetuneImpl
	ordi8 4404, 4

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
	ld (xiy), 0xB4
	ld (xiy + 2), 0x18
	ld (xiy + 3), 0x3
	ld (xiy + 4), a
	ld (xiy + 5), 0x7
	ret

SMF_SlotParam_Aftertouch:
	bitda 0, 4411
	jr nz, SMF_SlotParam_AftertouchReturn
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_AftertouchReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_AftertouchReturn
	cpdi8 4394, 3
	jr z, SMF_SlotParam_AftertouchImpl
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_AftertouchReturn
	ld a, (xiy + 5)
	orda8 a, 3310
	cp a, 0x80
	jr nz, SMF_SlotParam_AftertouchReturn
	ld (xiy + 2), 0x60
	ld (xiy + 2), 0x1
	jr SMF_SlotParam_AftertouchReturn

SMF_SlotParam_AftertouchImpl:
	cp (xiy + 3), 0x3
	jr nz, SMF_SlotParam_AftertouchReturn
	ld a, (xiy + 5)
	orda8 a, 3310
	cp a, 0xC0
	jr nz, SMF_SlotParam_AftertouchReturn
	ld (xiy + 2), 0x60
	ld (xiy + 2), 0x1
	xor a, a
	ld (xiy + 5), a
	ormi8 (xiy), 0x2

SMF_SlotParam_AftertouchReturn:
	ret

SMF_SlotParam_PortamentoSwitch:
	anddi8 4404, 253
	anddi8 4411, 253
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_PortaReturn
	cp (xiy + 2), 0x12
	jr nz, SMF_SlotParam_PortaReturn
	cp (xiy + 3), 0x6
	jr z, SMF_SlotParam_PortaImpl
	cp (xiy + 3), 0x7
	jr nz, SMF_SlotParam_PortaReturn

SMF_SlotParam_PortaImpl:
	ordi8 4404, 2
	ordi8 4411, 2
	stdi8 4419, 1

SMF_SlotParam_PortaReturn:
	ret

SMF_SlotParam_PortamentoTime:
	ldda8	a, 4394
	cps	a, 2
	jr	z, 4
	cps	a, 3
	jr	nz, 48
	cpdi8	10355, 15
	jr	nz, 41
	cp	(xiy+2), 20
	jr	nz, 35
	cp	(xiy+3), 4
	jr	nz, 29
	ld	a, (xiy+2)
	calr	-2476
	bit	7, a
	jr	z, 6
	and	a, 127
	.byte 0x85, 0x3e, 0x04
	ld	(xiy+2), a
	ld	(xiy+3), 2
	.byte 0xc1, 0x3b, 0x11, 0x3e, 0x01
	ret

SMF_SlotParam_Sustain:
	bitda 0, 4411
	jr nz, SMF_SlotParam_SustainReturn
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_SustainReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SustainReturn
	cp (xiy + 3), 0x0
	jr nz, SMF_SlotParam_SustainReturn
	ld a, (xiy + 5)
	orda8 a, 3310
	cps a, 3
	jr nz, SMF_SlotParam_SustainReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SustainImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_SustainImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x0
	ordi8 4411, 1

SMF_SlotParam_SustainReturn:
	ret

SMF_SlotParam_Sostenuto:
	bitda 0, 4411
	jr nz, SMF_SlotParam_SostenutoReturn1
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_SostenutoReturn1
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SostenutoReturn1
	cp (xiy + 3), 0xF
	jr nz, SMF_SlotParam_SostenutoReturn1
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SostenutoImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_SostenutoImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x1
	ordi8 4411, 1

SMF_SlotParam_SostenutoReturn1:
	ret

SMF_SlotParam_SoftPedal:
	bitda 0, 4411
	jr nz, SMF_SlotParam_SoftPedalReturn
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_SoftPedalReturn
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_SoftPedalReturn
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_SoftPedalReturn
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_SoftPedalImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_SoftPedalImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x2
	ordi8 4411, 1

SMF_SlotParam_SoftPedalReturn:
	ret

SMF_SlotParam_Format5Handler:
	bitda 0, 4411
	jr nz, SMF_SlotParam_Format5Return
	cpdi8 10355, 15
	jr z, SMF_SlotParam_Format5Impl
	cpdi8 10355, 16
	jr z, SMF_SlotParam_Format5Impl
	cpdi8 10355, 13
	jr z, SMF_SlotParam_Format5Impl
	cpdi8 10355, 14
	jr nz, SMF_SlotParam_Format5Return

SMF_SlotParam_Format5Impl:
	cp (xiy + 2), 0x18
	jr nz, SMF_SlotParam_Format5Return
	bitm 2, (xiy)
	jr z, SMF_SlotParam_Format5Return
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_Format5Return
	ld a, (xiy + 5)
	orda8 a, 3310
	cp a, 0x3F
	jr z, SMF_SlotParam_Format5Check
	cp a, 0x40
	jr nz, SMF_SlotParam_Format5Return
	ld (xiy + 3), 0x0
	jr SMF_SlotParam_Format5Set

SMF_SlotParam_Format5Check:
	ld (xiy + 3), 0x1
	andmi8 (xiy + 4), 0x3F
	ld (xiy + 5), 0x7F
	andmi8 (xiy), 0xFD

SMF_SlotParam_Format5Set:
	ordi8 4411, 1

SMF_SlotParam_Format5Return:
	ret

SMF_SlotParam_ReverbType:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ReverbTypeReturn
	cpdi8 10355, 15
	jr z, SMF_SlotParam_ReverbTypeImpl
	cpdi8 10355, 16
	jr z, SMF_SlotParam_ReverbTypeImpl
	cpdi8 10355, 13
	jr z, SMF_SlotParam_ReverbTypeImpl
	cpdi8 10355, 14
	jr nz, SMF_SlotParam_ReverbTypeReturn

SMF_SlotParam_ReverbTypeImpl:
	cp (xiy + 2), 0x20
	jr nz, SMF_SlotParam_ReverbTypeReturn
	cp (xiy + 3), 0x1
	jr nz, SMF_SlotParam_ReverbTypeReturn
	ld a, (xiy + 5)
	orda8 a, 3310
	cp a, 0x1F
	jr z, SMF_SlotParam_ReverbTypeCalc
	cp a, 0x40
	jr nz, SMF_SlotParam_ReverbTypeReturn
	ld (xiy + 3), 0x0
	jr SMF_SlotParam_ReverbTypeOutput

SMF_SlotParam_ReverbTypeCalc:
	ld (xiy + 3), 0x1
	andmi8 (xiy + 4), 0x1F
	ld (xiy + 5), 0x7F
	andmi8 (xiy), 0xFD

SMF_SlotParam_ReverbTypeOutput:
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_ReverbTypeDone
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_ReverbTypeDone:
	ld (xiy + 2), a
	ordi8 4411, 1

SMF_SlotParam_ReverbTypeReturn:
	ret

SMF_SlotParam_ChorusType:
	bitda 0, 4411
	jr nz, SMF_SlotParam_ChorusTypeDone
	cpdi8 10355, 15
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
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_ChorusTypeImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x3
	ordi8 4411, 1
	jr SMF_SlotParam_ChorusTypeDone

SMF_SlotParam_ChorusTypeCheck:
	ld (xiy + 2), 0x48
	ld (xiy + 3), 0x7
	ld a, (xiy + 4)
	sll a, 4
	ld (xiy + 4), a
	ld (xiy + 5), 0x30
	calr SMF_SlotParam_ChorusTypeReturn
	ordi8 4411, 1
	ordi8 4404, 4

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
	ld (xiy), 0xB4
	ld (xiy + 2), 0x18
	ld (xiy + 3), 0x3
	ld (xiy + 4), 0x1
	ld (xiy + 5), 0x7
	ret

SMF_SlotParam_BankSelect:
	bitda 0, 4411
	jr nz, SMF_SlotParam_BankSelectDone
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_BankSelectDone
	cp (xiy + 2), 0x20
	jr nz, SMF_SlotParam_BankSelectDone
	cp (xiy + 3), 0x4
	jr nz, SMF_SlotParam_BankSelectDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_BankSelectImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_BankSelectImpl:
	ld (xiy + 2), a
	ld (xiy + 3), 0x4
	ordi8 4411, 1

SMF_SlotParam_BankSelectDone:
	ret

SMF_SlotParam_BankSelectReturn:
	bitda 0, 4411
	jr nz, SMF_SlotParam_BankLSBDone
	cpdi8 10355, 0
	jr z, SMF_SlotParam_BankSelectLSB
	cpdi8 10355, 2
	jr z, SMF_SlotParam_BankSelectLSB
	cpdi8 10355, 1
	jr nz, SMF_SlotParam_BankLSBDone

SMF_SlotParam_BankSelectLSB:
	cp (xiy + 2), 0x37
	jr nz, SMF_SlotParam_BankLSBDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_BankLSBImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_BankLSBImpl:
	ld (xiy + 2), a
	ordi8 4411, 1
	ld a, (xiy + 3)
	cp a, 0xE
	jr c, SMF_SlotParam_BankLSBDone
	cp a, 0x1D
	jr ugt, SMF_SlotParam_BankLSBDone
	sub a, 0xA
	ld (xiy + 3), a

SMF_SlotParam_BankLSBDone:
	ret

SMF_SlotParam_BankLSBReturn:
	bitda 0, 4411
	jr nz, SMF_SlotParam_RPNDone
	cp (xiy + 2), 0x39
	jr nz, SMF_SlotParam_RPNDone
	xor hl, hl
	bitm 5, (xiy + 3)
	jr nz, SMF_SlotParam_RPN
	push xix
	ld xix, 0xF29D0B
	ld l, (xiy + 3)
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xAD
	ordi8 4411, 1
	jr SMF_SlotParam_RPNDone

SMF_SlotParam_RPN:
	push xix
	ld xix, 0xF29D2A
	ld l, (xiy + 3)
	ld_srib3 A, 0x07, 0xF0, 0xEC
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xAE
	ordi8 4411, 1

SMF_SlotParam_RPNDone:
	ret

SMF_SlotParam_RPNReturn:
	nop
	.byte 0x01, 0x02, 0x03, 0x04
	halt
	ei	0x07
	ldio	9, 10
	pushw 3340
	ldf	14
	push_f
	retd	0x1000
	nop
	scf
	nop
	nop
	nop
	nop
	ccf
	zcf
	push_a
	pop_a
	ex_ff
	nop
	.byte 0x01, 0x02, 0x03, 0x04
	halt
	ei	0x07
	ldio	9, 10
	pushw 3340
	ldf	14
	push_f
	retd	0x1000
	nop
	scf
	nop
	nop
	nop
	nop
	ccf
	zcf
	push_a
	pop_a
	ex_ff

SMF_SlotParam_NRPN:
	bitda 0, 4411
	jr nz, SMF_SlotParam_NRPNDone
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_NRPNImpl
	and a, 0x7F
	ormi8 (xiy), 0x4

SMF_SlotParam_NRPNImpl:
	ld (xiy + 2), a

SMF_SlotParam_NRPNDone:
	ret

SMF_SlotParam_NRPNReturn:
	bitda 1, 4411
	jr nz, SMF_SlotParam_DataEntryReturn
	ld a, (xiy + 3)
	srl a, 5
	and a, 0x3
	ld w, (xiy)
	and w, 0xC
	or a, w
	stda8 4405, a
	andmi8 (xiy), 0xF1
	andmi8 (xiy + 3), 0x1F
	ld a, (xiy + 2)
	calr SMF_TranslateChannel
	ld (xiy + 2), a
	cpdi8 10355, 15
	jr nz, SMF_SlotParam_DataEntry
	cpdi8 4419, 1
	jr z, SMF_SlotParam_DataEntryReturn

SMF_SlotParam_DataEntry:
	ld a, (xiy + 4)
	ldda8 w, 4405
	ld (xiy + 4), w
	stda8 4405, a

SMF_SlotParam_DataEntryReturn:
	ret

SMF_SlotParam_TypeD2Handler:
	cpdi8 10355, 15
	jr z, SMF_SlotParam_TypeD2Return
	cpdi8 10355, 16
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
	stda8 4405, a

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
	and w, 0x7F
	sla h, 1
	or a, h
	and a, 0x3
	ld (xiy + 2), w
	ld (xiy + 3), a
	ret

SMF_SetupSongBankRead:
	push xhl
	ldda32 xhl, 4349
	stda32 10369, xhl
	pop xhl
	ldda16 xwa, 10415
	stda16 10375, xwa

SMF_SetupRead_Adjust:
	push xhl
	ldda32 xhl, 10369
	ld_srib3 A, 0x07, 0xEC, 0xF4
	pop xhl
	cp a, 0x82
	jr z, SMF_SetupRead_Finalize
	calr SMF_AdvanceWritePtr
	jr SMF_SetupRead_Adjust

SMF_SetupRead_Finalize:
	xor hl, hl
	ldda8 l, 3301
	sll hl, 1
	push xde
	ld xde, 0xF1F8
	ldda16 xbc, 10375
	st_dri3w BC, 0x07, 0xE8, 0xEC
	srl hl, 1
	ld xde, 0xF218
	ld bc, iy
	lda_dri3 XHL, 0x07, 0xE8, 0xEC
	pop xde
	ret

SMF_SetupRead_Return:
	ld16_24 xwa, 0x00ffec
	stda16 61854, xwa
	ld xix, 0xAB000
	xor xhl, xhl
	ld8_24 l, 0x00ffe3
	sla xhl, 11
	add xix, xhl
	ld xiy, 0xF180
	ldw bc, 0x800
	ldir85
	ret

