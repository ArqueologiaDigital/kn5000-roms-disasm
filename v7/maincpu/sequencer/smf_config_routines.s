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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	mul xwa, de
	ldto_werp DE, 0xe2
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld xhl, (FILEIO_BLOCK_BYTES:16)
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

; =============================================================================
; SMF_HeaderConstants -- constant pieces of the Standard MIDI File the
; sequencer writes (SMF export), 0x66 = 102 bytes, to SMF_ScanChannels.  Every
; piece is addressed through a positional alias (shared/positional_labels.s,
; `.set SMF_HeaderConstants_0xNN, SMF_HeaderConstants + NN`); readers are in
; sequencer/smf_event_processor.s.  Until 2026-09-25 the first 24 bytes were
; framed as instructions (`nop / swi 7 / pop sr / rcf / .asciz "MThd" ...`).
; =============================================================================
SMF_HeaderConstants:
	; +0x00: delta-time 0, meta event FF 03 (sequence/track name), length 16.
	; SMF_SetupActiveChannel (0xF27146) copies these 4 bytes (`ld bc, 4; ldir85`)
	; and then the 16-byte name from RAM 0xF280 (`ldw bc, 0x10; ldir85`).
	.byte 0x00, 0xff, 0x03, 0x10
	; +0x04 (SMF_SetupActiveChannel_Str_MThd): the MThd chunk -- "MThd", length 6,
	; format 0, 1 track, division 96 ticks per quarter note.  Copied whole to
	; RAM 0x13FA by SMF_SetupActiveChannel (`ld bc, 7; ldirw` = 7 words).
SMF_SetupActiveChannel_Str_MThd:
	.ascii "MThd"
	.byte 0x00, 0x00, 0x00, 0x06	; chunk length (big-endian)
	.byte 0x00, 0x00		; format 0
	.byte 0x00, 0x01		; one track
	.byte 0x00, 0x60		; 96 ticks per quarter note
	; +0x12 (SMF_SetupActiveChannel_Str_MTrk): "MTrk", copied after the MThd chunk
	; by SMF_SetupActiveChannel (`ld bc, 4; ldir85`).
SMF_SetupActiveChannel_Str_MTrk:
	.ascii "MTrk"
	; +0x16: four zero bytes that nothing reads -- SMF_SetupActiveChannel
	; writes the track-length placeholder from RAM words 0x0FA2/0x0FA4
	; instead (scripts/analysis/sequi_find_refs.py v7 0xF28226 -> none).
	.byte 0x00, 0x00, 0x00, 0x00
	; +0x1A (SMF_ScanAndProcessChannel_Data): 20 x 16-bit offsets indexed by the
	; PART-TYPE CODE a MIDI channel carries in RAM 0xF1A0[channel] (x2).
	; Readers SMF_ScanAndProcessChannel (0xF2727F), SMF_WriteVol_PanAndPitch (0xF274EB),
	; SMF_WriteRPN_FineTune (0xF2759F), SMF_WriteRPN_CoarseTune (0xF27661) and
	; SMF_WriteRPN_Transpose (0xF27719): `ld xix, SMF_ScanAndProcessChannel_Data`,
	; `ld hl, (xrr+rr)` (hl := table[code]); 0xFFFF skips the channel;
	; otherwise the offset is added to RAM 0xF460 (`lda xiy, (xrr+rr)`) to reach
	; that part's record.  The offsets are 0x36 + 26*k (k = 0..15), so the
	; records sit 26 bytes apart.  20 entries, pinned by the next piece at +0x42.
SMF_ScanAndProcessChannel_Data:
	.short 0x0036, 0x006a, 0x0050, 0x00ec, 0x0106	; codes 0-4
	.short 0x0120, 0x013a, 0x0154, 0x009e, 0x00b8	; codes 5-9
	.short 0x00d2, 0x0084, 0x01bc, 0xffff, 0xffff	; codes 10-14
	.short 0xffff, 0xffff, 0x016e, 0x0188, 0x01a2	; codes 15-19
	; +0x42 (SMF_Setup_WriteLoop_Data): delta 0 + SysEx F0 05 7E 7F 09 01 F7,
	; "General MIDI System On".  +0x4A (SMF_Setup_WriteLoop_Data_2): the same
	; with 09 02, "GM System Off".  SMF_Setup_WriteLoop (0xF27224) writes 8 bytes
	; of the first when RAM byte 0x10E4 is non-zero, of the second when it
	; is zero.
SMF_Setup_WriteLoop_Data:
	.byte 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09, 0x01, 0xf7
SMF_Setup_WriteLoop_Data_2:
	.byte 0x00, 0xf0, 0x05, 0x7e, 0x7f, 0x09, 0x02, 0xf7
	; +0x52 (SMF_ProgramChange_ProcessPatch_Data): 20 bytes, indexed by the same
	; part-type code.  SMF_ProgramChange_ProcessPatch (0xF27B68): L := 0xF1A0[ch],
	; `ld xix, SMF_ProgramChange_ProcessPatch_Data`, `ld l, (xrr+rr)` (L := table[L]),
	; stored at RAM 0x1A5C, the third byte of the 3-byte message built at
	; 0x1A5A before SndParam_InitBufferConverge.  0x7F exactly where the
	; offset table above holds 0xFFFF (codes 13-16).
SMF_ProgramChange_ProcessPatch_Data:
	.byte 0x00, 0x02, 0x01, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x04, 0x05	; codes 0-9
	.byte 0x06, 0x03, 0x0f, 0x7f, 0x7f, 0x7f, 0x7f, 0x0c, 0x0d, 0x0e	; codes 10-19

SMF_ScanChannels:
	xor xhl, xhl
	xor bc, bc

SMF_ScanChannels_Loop:
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_ScanChannels_Inactive
	push xde
	ld xde, 0xf250
	bit	7, (xde+hl)
	pop xde
	jr z, SMF_ScanChannels_Inactive
	xor b, b
	ld iy, bc
	push xix
	ld xix, 0xf1a0
	ld	a, (xix+iy)
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
	bit	7, (xde+iy)
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
	bit	7, (xix+hl)
	pop xix
	jr z, SMF_FindFree_Next
	xor xhl, xhl
	ld l, c
	push xix
	ld xix, 0xf1a0
	cp	(xix+hl), 0x10
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
	cp	(xix+iz), 0x10
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
	ld (xix+), WA
	djnz16 bc, SMF_ClearWork_Loop
	pop xix
	popw bc
	popw wa
	ret

SMF_CalcTempoRate:
	ldw de, 0x9
	ldw wa, 0x27c0
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
	ldw hl, 0x64
	xor de, de
	extz xwa
	muls xwa, hl
	ldto_werp DE, 0xe2
	ld (3948:16), wa
	ld (3950:16), de
	ret

SMF_OutputCommandSeq:
	ld xiy, 0x106e
	ld xix, (4376:16)

SMF_OutputCmd_ReadByte:
	ld A, (xiy+)
	ld (xix+), a
	pushw wa
	push xiy
	call SMF_WriteByte
	pop xiy
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (FILEIO_BLOCK_BYTES:16), xwa
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ldfr_werp DE, 0xe2
	div xwa, hl
	ldto_werp DE, 0xe2
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld A, (xiy+)
	ld (xix+), a
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
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	pushw wa
	pushw hl
	call SMF_WriteByte
	popw hl
	popw wa
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	pushw hl
	call SMF_WriteByte
	popw hl
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld (xix+), a
	call SMF_WriteByte
	push xwa
	push xbc
	ld xbc, 0:i3
	ld xwa, (FILEIO_BLOCK_BYTES:16)
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
	ld	a, (xhl+iy)
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
	ld (FILEIO_BLOCK_BYTES:16), xwa
	pop xwa
	call SMF_ClearOutputQueue
	xor hl, hl
	xor bc, bc
	xor iy, iy

SMF_ProcessCh_Loop:
	push xix
	ld xix, 0x11f9
	bit	7, (xix+hl)
	pop xix
	jr z, SMF_ProcessCh_Next
	push xix
	ld xix, 0x11f9
	lda	xix, (xix+hl)
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
	ld	(xde+iy), c
	ld xde, 0x11f9
	lda	xde, (xde+hl)
	ld wa, (xde + 3)
	ld xde, 0xfae
	lda	xde, (xde+iy)
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
	ld (FILEIO_BLOCK_BYTES:16), xhl
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
	cp	(xix+iy), 0x0f
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
	cp	(xix+iy), 0x0c
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
	ld	a, (xix+iy)
	pop xix
	xor xiy, xiy

SMF_Dispatch_DrumSearch:
	ld bc, iy
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), a
	pop xix
	jr z, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
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
	cp	(xix+iy), 0x0c
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
	ld	a, (xix+iy)
	pop xix
	xor xiy, xiy

SMF_Dispatch_Ch15Search:
	ld bc, iy
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_Dispatch_DrumFound
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), a
	pop xix
	jr z, SMF_Dispatch_Ch15Found
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
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
	ld	hl, (xde+hl)
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
	ld	a, (xde+hl)
	pop xde
	xor xhl, xhl

SMF_ProgChg_SearchPart:
	push xix
	ld xix, 0xf1a0
	cp	(xix+hl), a
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
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
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
	ld	a, (xde+hl)
	pop xde
	xor xhl, xhl

SMF_CtrlChg_SearchPart:
	push xix
	ld xix, 0xf1a0
	cp	(xix+hl), a
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
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
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

; -----------------------------------------------------------------------------
; SMF_PartAssignTable -- maps a value 0..15 read from the SMF event stream to
; a PART-TYPE CODE of the kind RAM 0xF1A0[channel] holds (0xFF = none).
; Reader: SMF_Event_ProgramChange (0xF2896F): after checking the value is 0..0xF,
; `ld xde, SMF_PartAssignTable` / `ld a, (xde+hl)` (A := table[value]), then
; search 0xF1A0[0..15] for that code to find the channel (0x7F if none).
; SMF_Event_ControlChange (0xF28A03) holds an identical lookup, but it is unreachable:
; it follows `jr SMF_CtrlChg_UseDefault` and nothing branches into it.
; Only entries 0-15 are reachable through that range check; entries 16-23
; (to SMF_EncodeTimeDelta, code) are read by nothing found
; (scripts/analysis/sequi_find_refs.py v7 --window 24 0xF28AB1).  The codes used
; (0..0x13) are the same 20 codes SMF_HeaderConstants' two tables index by.
; -----------------------------------------------------------------------------
SMF_PartAssignTable:
	.byte 0x00, 0x02, 0x01, 0x0b, 0x08, 0x09, 0x0a, 0x03	; values 0-7
	.byte 0x04, 0x05, 0x06, 0x07, 0x11, 0x12, 0xff, 0x13	; values 8-15
	.byte 0xff, 0x0c, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff	; 16-23: past the 0..15 check

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
	rlc h, 2
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
	ld (xix+), a
	djnz16 bc, SMF_ClearQueue_Loop
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
	lda	xiy, (xiy+de)
	lda	xix, (xix+de)
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
	ld (FILEIO_BLOCK_BYTES:16), xhl
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
	ld (FILEIO_BLOCK_BYTES:16), xhl
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
	ld	(xhl+iy), a
	ret

SMF_AdvanceMultipleEvents:
	ld bc, 2:i3

SMF_AdvanceMulti_Loop:
	pushw bc
	calr SMF_AdvancePosition
	popw bc
	djnz16 bc, SMF_AdvanceMulti_Loop
	calr SMF_GetNextEvent
	ret

SMF_ResolveChannel:
	xor h, h
	ld iy, hl
	cp (4324:16), 255
	jr nz, SMF_Resolve_NoDrum
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
	pop xix
	jr nz, SMF_Resolve_DrumCh9
	ld a, 0x9:opc
	jrl SMF_Resolve_Return

SMF_Resolve_DrumCh9:
	cp iy, 0x9
	jrl nz, SMF_Resolve_Return
	push xix
	ld xix, 0xf1a0
	ld	a, (xix+iy)
	pop xix
	xor xiy, xiy

SMF_Resolve_DrumSearch:
	ld bc, iy
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), a
	pop xix
	jr z, SMF_Resolve_DrumFound
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
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
	cp	(xix+iy), 0x0c
	pop xix
	jr nz, SMF_Resolve_Ch15Check
	ld a, 0xf:opc
	jr SMF_Resolve_Return

SMF_Resolve_Ch15Check:
	cp iy, 0xf
	jr nz, SMF_Resolve_Return
	push xix
	ld xix, 0xf1a0
	ld	a, (xix+iy)
	pop xix
	xor xiy, xiy

SMF_Resolve_Ch15Search:
	ld bc, iy
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), a
	pop xix
	jr z, SMF_Resolve_Ch15Found
	push xix
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
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
	ld	a, (xiy+hl)
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
	and	(xde+ix), 0x3f
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
	ldto_werp DE, 0xe2
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
	ldw (xix+), 0x0000
	djnz16 wa, SMF_ClearBuf_Loop
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
	cp	(xix+iy), 0x0c
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
	ld	a, (xix+iy)
	xor xiy, xiy

SMF_GlobalCh_SearchLoop:
	ld bc, iy
	ldfr_berp A, 0x3c
	ldfr_werp DE, 0x3e
	ld de, (0x00ffec:24)
	ld a, c
	scf
	xorcf_a_16 de
	ldto_werp DE, 0x3e
	ldto_berp A, 0x3c
	jr c, SMF_GlobalCh_Found
	ld xix, 0xf1a0
	cp	(xix+iy), a
	jr z, SMF_GlobalCh_Found
	ld xix, 0xf1a0
	cp	(xix+iy), 0x0c
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
	lda xde, (xde+199:16)
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
	ld	wa, (xhl+de)
	ld (0xf22f:16), wa
	pop xhl
	ldw de, 0xb1
	ld	wa, (xhl+de)
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
	ld (SEQ_ERROR_CODE:16), 0
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
	ld	w, (xix+hl)
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

; -----------------------------------------------------------------------------
; SMF_ChannelTranslationTable -- 64 bytes, indexed by the value in A.
; Reader: SMF_TranslateChannel (0xF29034): `ld xix, SMF_ChannelTranslationTable`,
; `ld w, (xix+hl)` (W := table[A]).  0xFF leaves A unchanged;
; otherwise A := W, except that with RAM byte 0x112A == 3 the inputs 0x0E and
; 0x10 give 0x17 and 0x18 instead.  Its 17 calr sites (SMF_SlotParam_*
; handlers) pass the (XIY+2) byte of a slot record; 16 of them treat bit 7 of
; the result as a flag (`and a, 0x7f; ormi8 (xiy), 4`) and store the low 7
; bits back into (XIY+2).
; 64 entries (inputs 0x00-0x3F), to SMF_ConfigSlot (code); the last 8 were a
; `.fill 8, 1, 0xff` until 2026-09-25.
; -----------------------------------------------------------------------------
SMF_ChannelTranslationTable:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07	; inputs 0x00-0x07
	.byte 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x41, 0x0e	; inputs 0x08-0x0f
	.byte 0x42, 0x0f, 0x48, 0x10, 0x90, 0x11, 0x50, 0x51	; inputs 0x10-0x17
	.byte 0x70, 0x71, 0x12, 0x13, 0x14, 0x15, 0x16, 0xff	; inputs 0x18-0x1f
	.byte 0x98, 0x40, 0xff, 0x52, 0x92, 0xff, 0x72, 0xff	; inputs 0x20-0x27
	.byte 0x99, 0xff, 0xff, 0xff, 0x80, 0xff, 0xff, 0xff	; inputs 0x28-0x2f
	.byte 0xff, 0xff, 0x53, 0xff, 0xff, 0xff, 0xff, 0x9a	; inputs 0x30-0x37
	.byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff	; inputs 0x38-0x3f

SMF_ConfigSlot:
	and (0x287b:16), 251
	xor w, w
	ld (SEQ_ERROR_CODE:16), 0
	ld (0x287d:16), wa
	ldw (0x287f:16), 1
	call SetWall_SlotResolve
	cp (SEQ_ERROR_CODE:16), 0
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
	ld	a, (xde+ix)
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
	cp (SEQ_ERROR_CODE:16), 0
	jr z, SMF_ConfigSlot_EventLoop
	jrl SMF_ConfigSlot_Return

SMF_ConfigSlot_DefaultHandler:
	push xhl
	ld xhl, (0x2881:16)
	ld	(xhl+iy), a
	pop xhl

SMF_ConfigSlot_WriteAndContinue:
	calr SMF_AdvanceWritePtr
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SMF_ConfigSlot_Return

SMF_ConfigSlot_AdvanceEvent:
	calr SMF_AdvanceReadPtr
	cp (SEQ_ERROR_CODE:16), 0
	jrl nz, SMF_ConfigSlot_Return
	push xde
	ld xde, (4349:16)
	bit	7, (xde+ix)
	pop xde
	jr nz, SMF_ConfigSlot_EventLoop
	push xde
	ld xde, (4349:16)
	ld	a, (xde+ix)
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
	ld	a, (xde+ix)
	pop xde
	ld	(xiy+hl), a
	cp hl, (4402:16)
	jr c, SMF_ConfigSlot_ReadDataLoop
	popw hl
	pop xiy
	cp (SEQ_ERROR_CODE:16), 0
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
	ld	(xhl+iy), a
	pop xhl

SMF_Config_WriteLoop:
	inc 1, hl
	push xix
	push xhl
	calr SMF_AdvanceWritePtr
	pop xhl
	pop xix
	ld	a, (xix+hl)
	push xhl
	ld xhl, (0x2881:16)
	ld	(xhl+iy), a
	pop xhl
	cp hl, (4402:16)
	jr c, SMF_Config_WriteLoop
	pop xhl
	pop xix
	cp (SEQ_ERROR_CODE:16), 0
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
	ld	bc, (xde+hl)
	ld (4412:16), bc
	ld bc, (0x288b:16)
	ld	(xde+hl), bc
	srl hl, 1
	ld xde, 0xcbe
	ld	c, (xde+hl)
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
	ld	(xde+hl), c
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
	ld	(xde+hl), bc
	srl hl, 1
	ld xde, 0xcbe
	ld c, (4414:16)
	ld	(xde+hl), c
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
	ld	(xhl+iy), a
	pop xhl
	ld wa, (0x2887:16)
	ld (0x289f:16), wa
	call SetWall_EventOutput
	call SetWall_EventAdvanceCheck

SMF_ConfigSlot_Return:
	ret

; SMF_AdvanceInPageChain (formerly SMF_ConfigSlot_CodeBlock) -- RAM 0x113F :=
; word 0x2887; word 0x1141 := IY + 1; once that passes 255, follow the link
; word at +3 of the record RAM 0x2881 points to: store it in 0x113F and
; 0x2887, turn it into an address through SMF_CalcPageAddress (0x100 bytes per
; page, base in RAM 0x1D5A), and either stop with RAM 0x287A := 2 (bit 7 of
; the new page's first byte clear) or continue there with 0x1141 := 5, IY := 5.
; NO CALLER FOUND (scripts/analysis/sequi_find_refs.py on its address).
SMF_AdvanceInPageChain:
	; framing ported from v10's source for the same label (same span length, statement for statement); 24 of 26 slots byte-identical
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
	bitm 7, (xhl)
	jr	nz, SMF_ConfigSlot_Skip
	ld	(SEQ_ERROR_CODE:16), 2
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
	ld (SEQ_ERROR_CODE:16), 2
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
	ld (SEQ_ERROR_CODE:16), 2
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
	ld xix, SndParamRam_DefaultImage
	ld	a, (xix+hl)
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
	ld xix, SndParamRam_DefaultImage
	ld	a, (xix+hl)
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

; -----------------------------------------------------------------------------
; SMF_SlotParam_Remap14To2 (was SMF_SlotParam_PortamentoTime; nothing found
; supports "PortamentoTime") -- a slot-parameter handler shaped like its
; neighbours (SMF_SlotParam_Sustain, ...): when RAM 0x112A is 2 or 3, RAM
; 0x2873 is 15, and the record at XIY has (XIY+2) = 0x14 and (XIY+3) = 4, it
; translates (XIY+2) through SMF_TranslateChannel (0xF29034), stores it back,
; sets (XIY+3) := 2 and bit 0 of RAM 0x113B.
; NOT CALLED: it is absent from the `calr SMF_SlotParam_*` chain that runs
; every other handler, and scripts/analysis/sequi_find_refs.py v7 0xF299BB finds
; no reference.  Was `.byte` until 2026-09-25.
; -----------------------------------------------------------------------------
SMF_SlotParam_Remap14To2:
	ld a, (0x112a:16)
	cp a, 2:i3
	jr z, SMF_SlotParam_Remap14To2_Match
	cp a, 3:i3
	jr nz, SMF_SlotParam_Remap14To2_Return
SMF_SlotParam_Remap14To2_Match:
	cp (0x2873:16), 15
	jr nz, SMF_SlotParam_Remap14To2_Return
	cp (xiy+2), 20
	jr nz, SMF_SlotParam_Remap14To2_Return
	cp (xiy+3), 4
	jr nz, SMF_SlotParam_Remap14To2_Return
	ld a, (xiy+2)
	calr SMF_TranslateChannel
	bit 7, a
	jr z, SMF_SlotParam_Remap14To2_Store
	and a, 127
	ormi8 (xiy), 4
SMF_SlotParam_Remap14To2_Store:
	ld (xiy+2), a
	ld (xiy+3), 2
	or (0x113b:16), 0x01
SMF_SlotParam_Remap14To2_Return:
	ret

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
	ld	a, (xix+hl)
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xad
	or (4411:16), 1
	jr SMF_SlotParam_RPNDone

SMF_SlotParam_RPN:
	push xix
	ld xix, SMF_SlotParam_RPN_Data
	ld l, (xiy + 3)
	ld	a, (xix+hl)
	pop xix
	ld (xiy + 3), a
	ld (xiy + 2), 0xae
	or (4411:16), 1

SMF_SlotParam_RPNDone:
	ret

; -----------------------------------------------------------------------------
; SMF_SlotParam_RPNReturn -- two identical 31-byte halves, remapping the byte
; at (XIY+3) of a slot record.
; Reader: SMF_SlotParam_BankLSBReturn (0xF29C95), for a record whose (XIY+2) is
; 0x39: with HL := 0 and L := (XIY+3), `ld r, (mem)`-style load A := (XIX+HL);
;   bit 5 of (XIY+3) clear: XIX = SMF_SlotParam_RPNReturn,       (XIY+2) := 0xAD
;   bit 5 of (XIY+3) set:   XIX = SMF_SlotParam_RPN_Data,  (XIY+2) := 0xAE
; and A is written back to (XIY+3).  62 bytes to SMF_SlotParam_NRPN (code).
; NOT RESOLVED: the second lookup uses the unmasked index, which has bit 5
; set, so it addresses +0x3F or beyond -- past this table.  Either (XIY+3)
; never has bit 5 set here in practice, or that lookup reads the following
; code.  What the remapped values mean is not established.
; -----------------------------------------------------------------------------
SMF_SlotParam_RPNReturn:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x17, 0x0e
	.byte 0x18, 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x12, 0x13, 0x14, 0x15, 0x16
	; +0x1F (SMF_SlotParam_RPN_Data): the same 31 bytes again
SMF_SlotParam_RPN_Data:
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x17, 0x0e
	.byte 0x18, 0x0f, 0x00, 0x10, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0x12, 0x13, 0x14, 0x15, 0x16
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
	ld	a, (xhl+iy)
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
	ld	(xde+hl), bc
	srl hl, 1
	ld xde, 0xf218
	ld bc, iy
	ld	(xde+hl), c
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

