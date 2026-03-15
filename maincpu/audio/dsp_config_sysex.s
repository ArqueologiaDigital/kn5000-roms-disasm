; =============================================================================
; DSP Configuration & SysEx Processing
; =============================================================================
;
; DSP effect parameter handlers (reverb, chorus, EQ, compressor)
; and System Exclusive (SysEx) command processing. Manages effect
; presets and real-time parameter editing.
; =============================================================================

SysEx_ClampVoiceIndex8:
	cp a, 0x8
	jr c, SysEx_ClampVoiceIndex8_DoLookup
	ldb a, 0x0

SysEx_ClampVoiceIndex8_DoLookup:
	extz wa
	lda_24 xbc, 0xee33a4
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

SysEx_ApplyToSlot4B_Data:
	dec	2, xsp
	push	xiz
	ldda32	xwa, 48300
	ldw	bc, 11
	call	16604854
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	87
	ld	(xsp+4), l
	ld	xwa, 19204
	call	16631801
	ld	qiz, hl
	cp	qiz, 0
	jr	lt, 63
	lds	iz, 0
	cp	qiz, 0
	jr	le, 50
	ld	wa, iz
	exts	xwa
	add	xwa, 19216
	call	16631527
	cps	hl, 1
	jr	z, 4
	cps	hl, 2
	jr	nz, 21
	ld	wa, iz
	exts	xwa
	add	xwa, 19216
	ld	c, (xsp+4)
	extz	bc
	call	16632065
	jr	7
	inc	1, iz
	.byte 0xd7, 0xfa, 0xf6
	jr	lt, -50
	push	xiz
	call	15668467
	pop	xiz
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex128:
	cp a, 0x80
	jr c, SysEx_ClampVoiceIndex128_DoLookup
	ldb a, 0x0

SysEx_ClampVoiceIndex128_DoLookup:
	extz wa
	lda_24 xbc, 0xee33ac
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

SysEx_ApplyToSlot49_Data:
	dec	2, xsp
	push	xiz
	ldda32	xwa, 48300
	ldw	bc, 11
	call	16604854
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	93
	extz	hl
	ld	xwa, 18688
	ld	bc, hl
	call	16632065
	cps	hl, 0
	jr	lt, 72
	ld	xwa, 18692
	call	16631801
	ld	qiz, hl
	cp	qiz, 0
	jr	lt, 55
	lds	iz, 0
	cp	qiz, 0
	jr	le, 42
	ld	a, (xsp+4)
	extz	wa
	.byte 0xc7, 0xf8, 0x8b
	extz	bc
	calr	191
	ld	bc, hl
	cp	bc, 55536
	jr	z, 14
	ld	wa, iz
	exts	xwa
	add	xwa, 18704
	call	16632065
	inc	1, iz
	.byte 0xd7, 0xfa, 0xf6
	jr	lt, -42
	push	xiz
	call	15668467
	pop	xiz
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex8_49:
	cp a, 0x8
	jr c, SysEx_ClampVoiceIndex8_49_DoLookup
	ldb a, 0x0

SysEx_ClampVoiceIndex8_49_DoLookup:
	extz wa
	lda_24 xbc, 0xee342c
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

SysEx_ApplyToSlot49_Format_Data:
	dec	2, xsp
	push	xiz
	ldda32	xwa, 48300
	ldw	bc, 11
	call	16604854
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	87
	ld	(xsp+4), l
	ld	xwa, 18692
	call	16631801
	ld	qiz, hl
	cp	qiz, 0
	jr	lt, 63
	lds	iz, 0
	cp	qiz, 0
	jr	le, 50
	ld	wa, iz
	exts	xwa
	add	xwa, 18704
	call	16631527
	cps	hl, 1
	jr	z, 4
	cps	hl, 2
	jr	nz, 21
	ld	wa, iz
	exts	xwa
	add	xwa, 18704
	ld	c, (xsp+4)
	extz	bc
	call	16632065
	jr	7
	inc	1, iz
	.byte 0xd7, 0xfa, 0xf6
	jr	lt, -50
	push	xiz
	call	15668467
	pop	xiz
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex128_49:
	cp a, 0x80
	jr c, SysEx_ClampVoiceIndex128_49_DoLookup
	ldb a, 0x0

SysEx_ClampVoiceIndex128_49_DoLookup:
	extz wa
	lda_24 xbc, 0xee3434
	ld_srib3 L, 0x07, 0xE4, 0xE0
	ret

SysEx_DispatchByChannel:
	ldw hl, 0xD8F0
	ld e, c
	extz de
	add de, de
	extz wa
	cps wa, 0
	ret mi
	cps wa, 7
	ret gt
	add wa, wa
	lda_24 xix, 0xee3520
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfdad13
	jp_dri 8, 0x07, 0xF0, 0xE0

SysEx_ChannelHandler_4B_Data:
	cps	c, 5
	ret	nc
	ld	xwa, 15611060
	jr	77
	cps	c, 7
	ret	nc
	ld	xwa, 15611070
	jr	66
	cps	c, 5
	ret	nc
	ld	xwa, 15611084
	jr	55
	cps	c, 7
	ret	nc
	ld	xwa, 15611094
	jr	44
	cp	c, 8
	ret	nc
	ld	xwa, 15611108
	jr	32
	cp	c, 8
	ret	nc
	ld	xwa, 15611124
	jr	20
	cps	c, 7
	ret	nc
	ld	xwa, 15611140
	jr	9
	cps	c, 7
	ret	nc
	ld	xwa, 15611154
	.byte 0xd3, 0x07, 0xe0, 0xe8, 0x23
	ret

SysEx_DispatchByChannel_49:
	ldw hl, 0xD8F0
	ld e, c
	extz de
	add de, de
	extz wa
	cps wa, 0
	ret mi
	cps wa, 7
	ret gt
	add wa, wa
	lda_24 xix, 0xee3584
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xfdad9a
	jp_dri 8, 0x07, 0xF0, 0xE0

SysEx_ChannelHandler_49_Data:
	cps	c, 5
	ret	nc
	ld	xwa, 15611184
	jr	75
	cps	c, 5
	ret	nc
	ld	xwa, 15611194
	jr	64
	cps	c, 5
	ret	nc
	ld	xwa, 15611204
	jr	53
	cps	c, 5
	ret	nc
	ld	xwa, 15611214
	jr	42
	cps	c, 5
	ret	nc
	ld	xwa, 15611224
	jr	31
	cps	c, 5
	ret	nc
	ld	xwa, 15611234
	jr	20
	cps	c, 6
	ret	nc
	ld	xwa, 15611244
	jr	9
	cps	c, 6
	ret	nc
	ld	xwa, 15611256
	.byte 0xd3, 0x07, 0xe0, 0xe8, 0x23
	ret

SysEx_ValidateRolandHeader:
	cp c, 0xA
	ret ugt
	cp_spib_im 0xE0, 0xF0
	ret nz
	inc 1, xwa
	cp_spib_im 0xE0, 0x41
	ret nz
	inc 1, xwa
	cp_spib_im 0xE0, 0x42
	ret nz
	cp_spib_im 0xE0, 0x12
	ret nz
	cp_spib_im 0xE0, 0x40
	ret nz
	cp_spib_im 0xE0, 0x01
	ret nz
	cps c, 0
	jr nz, SysEx_ValidateRolandHeader_NonZeroChan
	lda_24 xbc, 0x00f180
	add xbc, 0x2E0
	jr SysEx_ValidateRolandHeader_Dispatch

SysEx_ValidateRolandHeader_NonZeroChan:
	dec 1, c
	extz bc
	sla bc, 11
	ld de, bc
	exts xde
	lda_24 xbc, 0x0ab000
	add xbc, xde
	add xbc, 0x2E0

SysEx_ValidateRolandHeader_Dispatch:
	ld_spib E, 0xE0
	cp e, 0x3A
	jr z, SysEx_ValidateRolandHeader_Cmd3A
	cp e, 0x38
	jr z, SysEx_ValidateRolandHeader_Cmd38
	cp e, 0x33
	jr z, SysEx_ValidateRolandHeader_Cmd33
	cp e, 0x30
	ret nz
	ld a, (xwa)
	extz wa
	jr SysEx_ApplyVoiceParam_4B

SysEx_ValidateRolandHeader_Cmd33:
	ld a, (xwa)
	extz wa
	jrl SysEx_ApplyVoiceParam_4B_128

SysEx_ValidateRolandHeader_Cmd38:
	ld a, (xwa)
	extz wa
	jrl SysEx_ApplyVoiceParam_49

SysEx_ValidateRolandHeader_Cmd3A:
	ld a, (xwa)
	extz wa
	calr SysEx_ApplyVoiceParam_49_128
	ret

SysEx_ApplyVoiceParam_4B:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ldada xwa, 64654
	sub xwa, 0xF980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8
	extz hl
	ld xwa, 0x4B00
	ld bc, hl
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jr lt, SysEx_ApplyVoiceParam_4B_Return
	ldada xwa, 64654
	cp xwa, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_ReadSubParams
	ld a, (xwa)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8
	stda8 64654, l

SysEx_ApplyVoiceParam_4B_ReadSubParams:
	ld xwa, 0x4B04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr ge, SysEx_ApplyVoiceParam_4B_IterateSlots
	ldada xbc, 64654
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_SkipRestore:
	jr SysEx_ApplyVoiceParam_4B_Return

SysEx_ApplyVoiceParam_4B_IterateSlots:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, SysEx_ApplyVoiceParam_4B_RestoreSlotId

SysEx_ApplyVoiceParam_4B_SlotLoop:
	ld a, (xsp + 10)
	extz wa
	ldto_berp C, 0xF8
	extz bc
	calr SysEx_DispatchByChannel_49
	ld bc, hl
	cp bc, 0xD8F0
	jr z, SysEx_ApplyVoiceParam_4B_SlotNext
	ld wa, iz
	exts xwa
	add xwa, 0x4B10
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple

SysEx_ApplyVoiceParam_4B_SlotNext:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyVoiceParam_4B_SlotLoop

SysEx_ApplyVoiceParam_4B_RestoreSlotId:
	ldada xbc, 64654
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_Return
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_Return:
	pop xiz
	inc 8, xsp
	ret

SysEx_ApplyVoiceParam_4B_128:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ldada xwa, 64654
	sub xwa, 0xF980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex128
	ld (xsp + 10), l
	ldada xbc, 64654
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_128_ReadSub
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_128_ReadSub:
	ld xwa, 0x4B04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr ge, SysEx_ApplyVoiceParam_4B_128_IterateSlots
	ldada xbc, 64654
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_128_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_128_SkipRestore:
	jr SysEx_ApplyVoiceParam_4B_128_Return

SysEx_ApplyVoiceParam_4B_128_IterateSlots:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, SysEx_ApplyVoiceParam_4B_128_RestoreSlotId

SysEx_ApplyVoiceParam_4B_128_SlotLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4B10
	call DSPCfg_ResolveAndExtract
	cps hl, 1
	jr z, SysEx_ApplyVoiceParam_4B_128_WriteSlot
	cps hl, 2
	jr nz, SysEx_ApplyVoiceParam_4B_128_SlotNext

SysEx_ApplyVoiceParam_4B_128_WriteSlot:
	ld wa, iz
	exts xwa
	add xwa, 0x4B10
	ld c, (xsp + 10)
	extz bc
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	jr SysEx_ApplyVoiceParam_4B_128_RestoreSlotId

SysEx_ApplyVoiceParam_4B_128_SlotNext:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyVoiceParam_4B_128_SlotLoop

SysEx_ApplyVoiceParam_4B_128_RestoreSlotId:
	ldada xbc, 64654
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_128_Return
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_128_Return:
	pop xiz
	inc 8, xsp
	ret

SysEx_ApplyVoiceParam_49:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ldada xwa, 64628
	sub xwa, 0xF980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8_49
	extz hl
	ld xwa, 0x4900
	ld bc, hl
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jr lt, SysEx_ApplyVoiceParam_49_Return
	ldada xwa, 64628
	cp xwa, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_ReadSubParams
	ld a, (xwa)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8_49
	stda8 64628, l

SysEx_ApplyVoiceParam_49_ReadSubParams:
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr ge, SysEx_ApplyVoiceParam_49_IterateSlots
	ldada xbc, 64628
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_SkipRestore:
	jr SysEx_ApplyVoiceParam_49_Return

SysEx_ApplyVoiceParam_49_IterateSlots:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, SysEx_ApplyVoiceParam_49_RestoreSlotId

SysEx_ApplyVoiceParam_49_SlotLoop:
	ld a, (xsp + 10)
	extz wa
	ldto_berp C, 0xF8
	extz bc
	calr SysEx_DispatchByChannel
	ld bc, hl
	cp bc, 0xD8F0
	jr z, SysEx_ApplyVoiceParam_49_SlotNext
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple

SysEx_ApplyVoiceParam_49_SlotNext:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyVoiceParam_49_SlotLoop

SysEx_ApplyVoiceParam_49_RestoreSlotId:
	ldada xbc, 64628
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_Return
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_Return:
	pop xiz
	inc 8, xsp
	ret

SysEx_ApplyVoiceParam_49_128:
	dec 8, xsp
	push xiz
	ld (xsp + 6), xbc
	ld (xsp + 10), a
	ldada xwa, 64628
	sub xwa, 0xF980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex128_49
	ld (xsp + 10), l
	ldada xbc, 64628
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_128_ReadSub
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_128_ReadSub:
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr ge, SysEx_ApplyVoiceParam_49_128_IterateSlots
	ldada xbc, 64628
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_128_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_128_SkipRestore:
	jr SysEx_ApplyVoiceParam_49_128_Return

SysEx_ApplyVoiceParam_49_128_IterateSlots:
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, SysEx_ApplyVoiceParam_49_128_RestoreSlotId

SysEx_ApplyVoiceParam_49_128_SlotLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ResolveAndExtract
	cps hl, 1
	jr z, SysEx_ApplyVoiceParam_49_128_WriteSlot
	cps hl, 2
	jr nz, SysEx_ApplyVoiceParam_49_128_SlotNext

SysEx_ApplyVoiceParam_49_128_WriteSlot:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld c, (xsp + 10)
	extz bc
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	jr SysEx_ApplyVoiceParam_49_128_RestoreSlotId

SysEx_ApplyVoiceParam_49_128_SlotNext:
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyVoiceParam_49_128_SlotLoop

SysEx_ApplyVoiceParam_49_128_RestoreSlotId:
	ldada xbc, 64628
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_128_Return
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_128_Return:
	pop xiz
	inc 8, xsp
	ret

SysEx_ApplyAndReloadPreset:
	push xiz
	extz bc
	cp a, 0x63
	jr z, SysEx_ApplyAndReloadPreset_Type63
	cp a, 0x61
	jr z, SysEx_ApplyAndReloadPreset_Type61
	ldw hl, 0xFFFF
	jrl AssswbWr_Return

SysEx_ApplyAndReloadPreset_Type61:
	ld xwa, 0x4900
	ld xde, 0xFC74
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jrl lt, AssswbWr_ReturnFail
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jrl lt, AssswbWr_ReturnFail
	lds iz, 0
	cpi_werp 0xFA, 0
	jrl le, AssswbWr_ReturnFail

SysEx_ApplyAndReloadPreset_Type61_Loop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, 0xFC74
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyAndReloadPreset_Type61_Loop
	jr AssswbWr_ReturnFail

SysEx_ApplyAndReloadPreset_Type63:
	ld xwa, 0x4B00
	ld xde, 0xFC8E
	call DSPCfg_WriteParamSimple
	cps hl, 0
	jr lt, AssswbWr_ReturnFail
	ld xwa, 0x4B04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xFA
	cpi_werp 0xFA, 0
	jr lt, AssswbWr_ReturnFail
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, AssswbWr_ReturnFail

SysEx_ApplyAndReloadPreset_Type63_Loop:
	ld wa, iz
	exts xwa
	add xwa, 0x4B10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4B10
	ld xde, 0xFC8E
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, SysEx_ApplyAndReloadPreset_Type63_Loop

AssswbWr_ReturnFail:
	lds hl, 0

AssswbWr_Return:
	pop xiz
	ret
AssswbWr:
	ldda16 xhl, 37086
	cp hl, 0x1FC
	jr nc, AssswbWr_BufferFull
	ldada xix, 48444
	extz xhl
	add xhl, xix
	lda_dpi XBC, 0xEC
	lda_dpi XHL, 0xEC
	lda_dpi XIY, 0xEC
	ld a, (xsp + 4)
	lda_dpi XBC, 0xEC
	ld (xhl), 0xFF
	ldda16 xwa, 37086
	inc 4, wa
	stda16 37086, xwa

AssswbWr_BufferFull:
	retd 0x2

AddswbWr:
	ldda16 xhl, 37090
	cp hl, 0xFC
	jr nc, AddswbWr_BufferFull
	ldada xix, 48953
	extz xhl
	add xhl, xix
	lda_dpi XBC, 0xEC
	lda_dpi XHL, 0xEC
	lda_dpi XIY, 0xEC
	ld a, (xsp + 4)
	lda_dpi XBC, 0xEC
	ld (xhl), 0xFF
	ldda16 xwa, 37090
	inc 4, wa
	stda16 37090, xwa

AddswbWr_BufferFull:
	retd 0x2

SwbtWr:
	ldada xix, 49209
	ld xiy, xix
	lda xhl, (xix + 60)
	cp (xix), 0xFF
	jr z, SwbtWr_CheckSpace

SwbtWr_ScanEnd:
	inc 4, xiy
	cp (xiy), 0xFF
	jr nz, SwbtWr_ScanEnd

SwbtWr_CheckSpace:
	cp xiy, xhl
	jr nc, SwbtWr_Done
	lda_dpi XBC, 0xF4
	lda_dpi XHL, 0xF4
	lda_dpi XIY, 0xF4
	ld a, (xsp + 4)
	lda_dpi XBC, 0xF4
	ld (xiy), 0xFF

SwbtWr_Done:
	retd 0x2

SwbtWr_CallProcessAll:
	push xiz
	calr SwbtWr_ProcessAll
	pop xiz
	ret

SwbtWr_SoundBankParamTable:
	push	xiz
	calr	62
	pop	xiz
	ret
	push	xiz
	calr	87
	pop	xiz
	ret
	push	xiz
	calr	112
	pop	xiz
	ret

SwbtWr_ProcessAll:
	ld xiy, 0xBF39
	ld xix, 0xBD3C
	ldda16 xbc, 37090
	srl bc, 1
	cps bc, 0
	jr z, SwbtWr_ProcessAll_CompactDone
	ldirw

SwbtWr_ProcessAll_CompactDone:
	ld (xix), 0xFF
	sub xix, 0xBD3C
	stda16 37086, xix
	stdi8 48953, 255
	stdi16 37090, 0
	ret

SwbtWr_InitBank1:
	ld xiy, 0xEE7786
	stda32 49281, xiy
	ld xiy, 0xEE7CA3
	stda32 49285, xiy
	ld xiy, 0xBD3C
	stda32 49289, xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_InitBank2:
	ld xiy, 0xEE7CA7
	stda32 49281, xiy
	ld xiy, 0xEE86B4
	stda32 49285, xiy
	ld xiy, 0xBD3C
	stda32 49289, xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_InitBank3:
	ld xiy, 0xEE86D0
	stda32 49281, xiy
	ld xiy, 0xEE8C79
	stda32 49285, xiy
	ld xiy, 0xC039
	stda32 49289, xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_DispatchLoop_Init:
	stdi16 49275, 0

SwbtWr_DispatchLoop:
	ldda32 xiy, 49289
	addda16 xiy, 49275
	cp (xiy), 0xFF
	jr z, SwbtWr_DispatchLoop_PostCallbacks
	ldda32 xix, 49281
	xor hl, hl
	ld l, (xiy)
	stda8 49280, l
	cp l, 0xBF
	jr ugt, SwbtWr_DispatchLoop_NextEvent
	sla hl, 2
	ld_sril3 XHL, 0x07, 0xF0, 0xEC
	ld wa, (xiy + 1)
	ld c, (xiy + 3)

SwbtWr_DispatchLoop_ScanCallbacks:
	cpw (xhl), 0xFFFF
	jr nz, SwbtWr_DispatchLoop_ExecuteCallback
	cpw (xhl + 2), 0xFFFF
	jr z, SwbtWr_DispatchLoop_NextEvent

SwbtWr_DispatchLoop_ExecuteCallback:
	stda16 49277, xwa
	stda8 49279, c
	push_sd16w 0x7B, 0xC0
	push_sd16w 0x81, 0xC0
	push_sd16w 0x83, 0xC0
	push_sd16w 0x85, 0xC0
	push_sd16w 0x87, 0xC0
	push xwa
	push xbc
	push xde
	push xhl
	push xiy
	push xix
	ld xde, (xhl)
	call (xde)
	pop xix
	pop xiy
	pop xhl
	pop xde
	pop xbc
	pop xwa
	popw_dd16 0x87, 0xC0
	popw_dd16 0x85, 0xC0
	popw_dd16 0x83, 0xC0
	popw_dd16 0x81, 0xC0
	popw_dd16 0x7B, 0xC0
	add xhl, 0x4
	jr SwbtWr_DispatchLoop_ScanCallbacks

SwbtWr_DispatchLoop_NextEvent:
	adddi16 49275, 4
	jrl SwbtWr_DispatchLoop

SwbtWr_DispatchLoop_PostCallbacks:
	ldda32 xix, 49285

SwbtWr_PostCallback_Loop:
	cpw (xix), 0xFFFF
	jr z, SwbtWr_PostCallback_Done
	push xix
	ld xix, (xix)
	call (xix)
	pop xix
	add xix, 0x4
	jr SwbtWr_PostCallback_Loop

SwbtWr_PostCallback_Done:
	ret

SwbtWr_QueueMainEvent:
	cpdi16 37086, 507
	jr ugt, SwbtWr_QueueMainEvent_Done
	ld xhl, 0xBD3C
	addda16 xhl, 37086
	ld (xhl), de
	ld (xhl + 2), wa
	ld (xhl + 4), 0xFF
	adddi8 37086, 4

SwbtWr_QueueMainEvent_Done:
	ret

SwbtWr_QueuePostEvent:
	cpdi16 37090, 251
	jr ugt, SwbtWr_QueuePostEvent_Done
	ld xhl, 0xBF39
	addda16 xhl, 37090
	ld (xhl), de
	ld (xhl + 2), wa
	ld (xhl + 4), 0xFF
	adddi16 37090, 4

SwbtWr_QueuePostEvent_Done:
	ret

SwbtWr_TrailingBytecode:
	ld	xhl, 49209
	cp	(xhl), 255
	jr	z, 6
	add	hl, 4
	jr	-11
	cp	xhl, 49268
	jr	ugt, 9
	ld	(xhl), de
	ld	(xhl+2), wa
	ld	(xhl+4), 255
	ret

PreLswLoad:
	calr VoiceParam_SaveReverbChorus
	jp SndParam_SyncDisplayBitmap

PostLswLoad:
	cps wa, 0
	jp_24 lt, 0xFC4D67
	cpi8_24 0x0340f6, 0x00
	call_24 z, 0xFDB4F9
	call ToneGen_DispatchByMode
	call SwbtWr_NullRet
	call ToneGen_Config_InitAllEntries
	call ToneGen_DSPCfg_ResetAll
	lds wa, 1
	call BitMapOut_GetRenderMode_CheckBit3
	call SoundParam_NotifyMultipleChanges
	lds wa, 1
	call BitMapOut_GetRenderMode_Return
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	call SeqTimer_UpdateTempoReg
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

PreLswSave:
	ret

PostLswSave:
	ret

PrePmLoad:
	ret

PostPmLoad:
	cps wa, 0
	ret lt
	call ToneGen_Config_InitAllChannels
	call ToneGen_DSPCfg_ResetAllChannels
	ret

PrePmSave:
	ret

PostPmSave:
	ret

PreMidiLoad:
	ret

PostMidiLoad:
	ret

PreMidiSave:
	ret

PostMidiSave:
	ret

VoiceParam_SaveReverbChorus:
	dec 4, xsp
	push_werp 0xFA
	ldada xwa, 49294
	ld (xsp + 2), xwa
	ldi_berp 0xFB, 0

VoiceParam_SaveReverbChorus_Loop:
	ldto_berp A, 0xFB
	extz wa
	call VoiceData_LookupPtrByIndex
	lda xbc, (xhl + 12)
	ld xde, xbc
	inc 1, xde
	ld xwa, (xsp + 2)
	ld c, (xbc)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	ld c, (xde)
	lda_dpi XHL, 0xE0
	ld (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x19
	jr c, VoiceParam_SaveReverbChorus_Loop
	pushw 0xE
	pushw 0x0
	pushw 0xFD50
	ld xwa, (xsp + 8)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	pop_werp 0xFA
	inc 4, xsp
	ret

VoiceParam_RestoreReverbChorus:
	dec 4, xsp
	push_werp 0xFA
	ldada xwa, 49294
	ld (xsp + 2), xwa
	ldi_berp 0xFB, 0

VoiceParam_RestoreReverbChorus_Loop:
	ldto_berp A, 0xFB
	extz wa
	call VoiceData_LookupPtrByIndex
	lda xde, (xhl + 12)
	ld xhl, xde
	inc 1, xhl
	andmi8 (xde), 0xF8
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xsp + 2), xwa
	and c, 0x7
	or (xde), c
	ld xwa, (xsp + 2)
	ld_spib C, 0xE0
	ld (xhl), c
	ld (xsp + 2), xwa
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x19
	jr c, VoiceParam_RestoreReverbChorus_Loop
	pushw 0xE
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xFD50
	call Mem_Copy
	lda xsp, (xsp + 10)
	pop_werp 0xFA
	inc 4, xsp
	ret

BitMapOut_ComputeRegionDelta:
	ldada xwa, 64930
	ldada xbc, 63872
	sub xwa, xbc
	pushw wa
	push xbc
	pushw 0x0
	pushw 0xF460
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

BitMapOut_PrepareAndRender:
	pushw iz
	ld iz, wa
	call Audio_ConfigureDSP
	ld wa, iz
	calr BitMapOut_RenderDisplay
	popw iz
	ret

BitMapOut_RenderDisplay:
	lda xsp, (xsp - 34)
	push xiz
	lds wa, 2
	call BitMapOut_GetRenderMode_CheckBit3
	call BitMapOut_SaveDisplayToROM
	ldada xbc, 64602
	ld a, (xbc + 8)
	ldfr_berp A, 0xF9
	ld a, (xbc + 9)
	ldfr_berp A, 0xFB
	ldmi16 (xsp + 4), 0x8D3A
	ldada xbc, 64918
	ld a, (xbc + 1)
	ld (xsp + 6), a
	ld a, (xbc + 11)
	ld (xsp + 8), a
	pushw 0x4
	pushw 0x0
	pushw 0xFC54
	lda xwa, (xsp + 40)
	push xwa
	call Mem_Copy
	pushw 0x18
	pushw 0x0
	pushw 0xFCDC
	lda xwa, (xsp + 26)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	calr VoiceParam_SaveReverbChorus
	ldada xix, 62560
	ldada xbc, 63872
	ld xhl, xbc
	ldada xwa, 64862
	sub xwa, xbc
	ld de, wa
	srl de, 1
	lds bc, 0
	cps de, 0
	jr ule, BitMapOut_CopyRegion_Done

BitMapOut_CopyRegion_Loop:
	ld_spiw WA, 0xF1
	st_dpiw WA, 0xED
	inc 1, bc
	ld wa, bc
	cp wa, de
	jr c, BitMapOut_CopyRegion_Loop

BitMapOut_CopyRegion_Done:
	pushw 0x4
	lda xwa, (xsp + 36)
	push xwa
	pushw 0x0
	pushw 0xFC54
	call Mem_Copy
	pushw 0x18
	lda xwa, (xsp + 22)
	push xwa
	pushw 0x0
	pushw 0xFCDC
	call Mem_Copy
	lda xsp, (xsp + 20)
	cpdi8 4596, 1
	jr nz, BitMapOut_SkipRestore
	cpi8_24 0x0340f7, 0x00
	jr nz, BitMapOut_MergeOutputFields

BitMapOut_SkipRestore:
	calr VoiceParam_RestoreReverbChorus

BitMapOut_MergeOutputFields:
	ldada xix, 64918
	lda xbc, (xix + 1)
	ldada xhl, 63872
	ld xwa, xbc
	sub xwa, xhl
	ldada xde, 62560
	ld xiy, xde
	add xiy, xwa
	ld w, (xiy)
	res 7, w
	ld a, (xbc)
	and a, 0x80
	ldfr_berp A, 0xE2
	ld a, w
	or_berp A, 0xE2
	ld w, a
	ld (xbc), w
	lda xbc, (xix + 11)
	ld xwa, xbc
	sub xwa, xhl
	add xde, xwa
	ld w, (xde)
	and w, 0xC0
	ld a, (xbc)
	and a, 0x3F
	ldfr_berp A, 0xE2
	or_berp W, 0xE2
	ld (xbc), w
	ldada xbc, 64602
	ld a, (xbc + 5)
	ldfr_berp A, 0xF8
	ld a, (xbc + 6)
	ldfr_berp A, 0xFA
	ldto_berp A, 0xF9
	ld (xbc + 8), a
	ldto_berp A, 0xFB
	ld (xbc + 9), a
	mrdb5 0x8F, 0x04, 0x19, 0x3A, 0x8D
	call ToneGen_InitAllChannelEntries_Skip
	call BitMapOut_DetectChanges
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pushw 0x0
	ldw wa, 0x48
	lds bc, 5
	lds de, 0
	call AddswbWr
	ld w, (xsp + 6)
	and w, 0x80
	ldada xbc, 64919
	ld a, (xbc)
	res 7, a
	ld (xbc), a
	or a, w
	ld (xbc), a
	ld e, a
	extz de
	pushw 0x7F
	ldw wa, 0x98
	lds bc, 1
	call AddswbWr
	ldda8 e, 64929
	ld c, e
	and c, 0xC0
	ld a, (xsp + 8)
	and a, 0xC0
	xor a, c
	extz de
	extz wa
	pushw wa
	ldw wa, 0x98
	ldw bc, 0xB
	call AddswbWr
	ldada xbc, 64602
	ldto_berp A, 0xF8
	and a, 0x3F
	ld (xbc + 5), a
	ldto_berp A, 0xFA
	and a, 0x3C
	ld (xbc + 6), a
	call PartSelect_UpdateDisplayState
	call ToneGen_DispatchByMode
	call SwbtWr_NullRet
	pushw 0x0
	ldw wa, 0x48
	lds bc, 7
	lds de, 0
	call AddswbWr
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_CallProcessAll
	pop xiz
	pop xix
	pop xhl
	pop xde
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	pushw 0x0
	ldw wa, 0x91
	lds bc, 3
	lds de, 4
	call AddswbWr
	lds wa, 2
	call BitMapOut_GetRenderMode_Return
	pop xiz
	lda xsp, (xsp + 34)
	ret

SeqOut_WriteTimedBytes:
	push xiz
	ld iz, (xsp + 8)
	ei 6
	cpdi8 47072, 0	; zero means MIDI
	jr nz, SeqOut_WriteTimedBytes_CompIface
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, iz
	jr c, SeqOut_WriteTimedBytes_BufferFull
	ld xwa, (xsp + 10)
	push xwa
	pushw iz
	call SeqBuf_MidiOut_WriteBytes
	inc 6, xsp
	ldfr_werp HL, 0xFA
	call MIDI_SC0_ENABLE_TX
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_BufferFull:
	ldi_erpw 0xFA, 0xFF, 0xFF
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_CompIface:
	ldda8 a, 49636
	cps a, 2
	jr z, SeqOut_WriteTimedBytes_PC2Timing
	cps a, 1
	jr z, SeqOut_WriteTimedBytes_SerialWrite
	cps a, 0
	jr nz, MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_SerialWrite:
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, iz
	jr c, MIDI_SeqProcess_DisableIntReturn
	ld xwa, (xsp + 10)
	push xwa
	pushw iz
	call SeqBuf3_WriteBytes
	inc 6, xsp
	ldfr_werp HL, 0xFA
	calr SeqBuf3_EnableTx_Stub
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_PC2Timing:
	call SeqBuf3_GetTimingValue
	ldfr_werp HL, 0xFA

MIDI_SeqProcess_DisableIntReturn:
	ei 0
	ldto_werp HL, 0xFA
	pop xiz
	ret

MidiSeq_ReceiveAndForward:
	pushw iz
	ldw iz, 0xFFFF
	ei 6
	cpdi8 47072, 0	; zero means MIDI
	jr nz, MidiSeq_ReceiveAndForward_CompIface
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	call MIDI_RX_BYTE_DISPATCHER
	call SeqMain_GetTimingValue
	ld iz, hl
	jr MidiSeq_ReceiveAndForward_Exit

MidiSeq_ReceiveAndForward_CompIface:
	ldda8 a, 49636
	cps a, 2
	jr z, MidiSeq_ReceiveAndForward_PC2Forward
	cps a, 1
	jr z, MidiSeq_ReceiveAndForward_SerialTiming
	cps a, 0
	jr nz, MidiSeq_ReceiveAndForward_Exit

MidiSeq_ReceiveAndForward_SerialTiming:
	call SeqBuf3_GetTimingValue
	ld iz, hl
	jr MidiSeq_ReceiveAndForward_Exit

MidiSeq_ReceiveAndForward_PC2Forward:
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, (xsp + 6)
	jr c, MidiSeq_ReceiveAndForward_Exit
	ld xwa, (xsp + 8)
	cp (xwa), 0xFE
	jr z, MidiSeq_ReceiveAndForward_Exit
	ld a, (xwa)
	extz wa
	pushw wa
	call SeqBuf3_WriteByte
	inc 2, xsp
	ld iz, hl

MidiSeq_ReceiveAndForward_Exit:
	ei 0
	ld hl, iz
	popw iz
	ret

MidiSeq_SendMultiByteWithTiming:
	dec 2, xsp
	pushw iz
	ei 6
	cpdi8 47072, 0	; zero means MIDI
	jr nz, MidiSeq_SendMultiByte_CompIface
	call SeqMain_GetTimingValue
	ld (xsp + 2), hl
	jrl MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_CompIface:
	ldda8 a, 49636
	ld iz, (xsp + 8)
	cps a, 1
	jr z, MidiSeq_SendMultiByte_SerialCountInit
	cps a, 2
	jr z, MidiSeq_SendMultiByte_PC2CountInit
	cps a, 0
	jr nz, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_PC2CountInit:
	ld wa, iz
	dec 1, iz
	cps wa, 0
	jr z, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_PC2SendLoop:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	extz wa
	call MIDI_RX_BYTE_DISPATCHER
	call SeqBuf_MidiOut_GetTimingValue
	cps hl, 1
	jr lt, MidiSeq_SendMultiByte_PC2NextByte
	ld xwa, (xsp + 10)
	cp (xwa), 0xFE
	jr z, MidiSeq_SendMultiByte_PC2NextByte
	ld a, (xwa)
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ld (xsp + 2), hl
	call MIDI_SC0_ENABLE_TX

MidiSeq_SendMultiByte_PC2NextByte:
	lds32 xwa, 1
	add (xsp + 10), xwa
	ld wa, iz
	dec 1, iz
	cps wa, 0
	jr nz, MidiSeq_SendMultiByte_PC2SendLoop
	jr MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_SerialCountInit:
	ld wa, iz
	dec 1, iz
	cps wa, 0
	jr z, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_SerialSendLoop:
	call SeqBuf_MidiOut_GetTimingValue
	cps hl, 1
	jr lt, MidiSeq_SendMultiByte_SerialNextByte
	ld xwa, (xsp + 10)
	cp (xwa), 0xFE
	jr z, MidiSeq_SendMultiByte_SerialNextByte
	ld a, (xwa)
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ld (xsp + 2), hl
	call MIDI_SC0_ENABLE_TX

MidiSeq_SendMultiByte_SerialNextByte:
	lds32 xwa, 1
	add (xsp + 10), xwa
	ld wa, iz
	dec 1, iz
	cps wa, 0
	jr nz, MidiSeq_SendMultiByte_SerialSendLoop

MidiSeq_SendMultiByte_Exit:
	ei 0
	ld hl, (xsp + 2)
	popw iz
	inc 2, xsp
	ret

SeqBuf_DspSysEx_DataReadLoop:
	dec 2, xsp

SeqBuf_DspSysEx_ReadAndForward_Loop:
	call SeqBuf_DspSysEx_ReadByte
	cp hl, 0xFFFF
	jr z, SeqBuf_DspSysEx_ReadAndForward_Done
	ld (xsp), l
	lda xwa, (xsp)
	push xwa
	pushw 0x1
	calr MidiSeq_SendMultiByteWithTiming
	inc 6, xsp
	jr SeqBuf_DspSysEx_ReadAndForward_Loop

SeqBuf_DspSysEx_ReadAndForward_Done:
	inc 2, xsp
	ret

SeqBuf3_EnableTx_Stub:
	ret

MidiSysEx_BuildAndSend:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 10), de
	ld (xsp + 12), c
	ld (xsp + 14), a
	ldw (xsp + 8), 0x2
	pushw 0x7
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	ld (xsp + 4), xiz
	or xiz, xiz
	jr z, MidiSysEx_BuildAndSend_Exit
	pushw 0x7
	pushw 0xEE
	pushw 0x4FB2
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 5)
	ld xde, xbc
	cpw (xsp + 10), 0xFFFF
	jr z, MidiSysEx_ApplyChannel
	ld a, (xsp + 14)
	and a, 0xF
	or (xiz), a
	ld de, (xsp + 10)
	sra de, 7
	ld xwa, (xsp + 4)
	ld (xwa + 2), e
	ld de, (xsp + 10)
	and de, 0x7F
	ld (xwa + 4), e
	ld xde, (xsp + 4)
	ldw (xsp + 8), 0x7

MidiSysEx_ApplyChannel:
	ld a, (xsp + 14)
	and a, 0xF
	or (xbc), a
	ld c, (xsp + 12)
	res 7, c
	ld xwa, (xsp + 4)
	ld (xwa + 6), c
	push xde
	pushm (xsp + 12)
	calr SeqOut_WriteTimedBytes
	stdi8 1060, 0
	ld xwa, (xsp + 10)
	push xwa
	call Free
	lda xsp, (xsp + 10)

MidiSysEx_BuildAndSend_Exit:
	pop xiz
	lda xsp, (xsp + 12)
	ret

MIDI_BroadcastControlChange:
	dec 8, xsp
	push_werp 0xFA
	ld xiy, 0xEE4FBA
	lda xix, (xsp + 2)
	lds bc, 3
	ldirw
	ldi85
	ldi_berp 0xFB, 0

MIDI_BroadcastCC_MidiOutLoop:
	ldto_berp A, 0xFB
	or a, 0xB0
	ld (xsp + 2), a
	ei 6
	lda xwa, (xsp + 2)
	push xwa
	pushw 0x7
	call SeqBuf_MidiOut_WriteBytes
	inc 6, xsp
	ei 0
	call MIDI_SC0_ENABLE_TX
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0F
	jr ule, MIDI_BroadcastCC_MidiOutLoop
	ldi_berp 0xFB, 0

MIDI_BroadcastCC_CommLoop:
	lda xde, (xsp + 2)
	ldto_berp A, 0xFB
	or a, 0xB0
	ld (xde), a
	lds wa, 4
	lds bc, 7
	call sendCOMM
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x0F
	jr ule, MIDI_BroadcastCC_CommLoop
	stdi8 1060, 0
	pop_werp 0xFA
	inc 8, xsp
	ret

CompIface_SendActiveSensing:
	ldda8 a, 47072
	cps a, 0	; MIDI
	ret z
	cps a, 3	;  PC2
	jr z, CompIface_SendActiveSensing_PC2
	cps a, 2	;  PC1
	jr z, CompIface_SendActiveSensing_PC1MAC
	cps a, 1	;  MAC
	ret nz

CompIface_SendActiveSensing_PC1MAC:
	push_sr
	ei 0
	lds wa, 4
	lds bc, 1
	ld xde, 0xEE4FC4	;	PC1 or MAC (0F5h)
	call sendCOMM
	pop_sr
	ret

CompIface_SendActiveSensing_PC2:
	push_sr
	ei 0
	lds wa, 4
	lds bc, 1
	ld xde, 0xEE4FC2	;	PC2 (0F4h)
	call sendCOMM
	pop_sr
	ret

MidiOut_RealtimeDispatch_Data:
	cpdi8	49280, 152
	ret	nz
	cpdi8	49277, 14
	ret	nz
	ldda8	a, 49279
	and	a, 3
	ret	z
	ldda8	a, 49278
	and	a, 3
	stda8	49636, a
	ret

MidiOut_SerializeAndSend:
	pushw iz
	lds iz, 0
	cpdi8 47072, 0	; zero means MIDI
	jrl z, MidiOut_SerializeAndSend_Exit

MidiOut_SerializeRealtimeLoop:
	cp iz, 0x108
	jrl nc, MidiOut_FlushBuffer
	resda 4, 1065
	ldda8 a, 1065
	and a, 0x1F
	jr z, MidiOut_ReadSysExByte
	bitda 0, 1065
	jr z, MidiOut_CheckStart
	resda 0, 1065
	bitda 4, 64848
	jr nz, MidiOut_SerializeRealtimeLoop
	ld wa, iz
	inc 1, iz
	ldada xbc, 49362
	extz xwa
	add xwa, xbc
	ld (xwa), 0xF8
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckStart:
	ldada xwa, 49362
	bitda 1, 1065
	jr z, MidiOut_CheckContinue
	resda 1, 1065
	bitda 4, 64848
	jr nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFA
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckContinue:
	bitda 2, 1065
	jr z, MidiOut_CheckStop
	resda 2, 1065
	bitda 4, 64848
	jr nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFB
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckStop:
	bitda 3, 1065
	jr z, MidiOut_SerializeRealtimeLoop
	resda 3, 1065
	bitda 4, 64848
	jrl nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xFC
	jrl MidiOut_SerializeRealtimeLoop

MidiOut_ReadSysExByte:
	call SeqBuf3_ReadByte
	cp hl, 0xFFFF
	jr z, MidiOut_FlushBuffer
	ld wa, iz
	inc 1, iz
	ldada xbc, 49362
	extz xwa
	add xwa, xbc
	ld (xwa), l
	cp l, 0xF7
	jrl nz, MidiOut_SerializeRealtimeLoop

MidiOut_FlushBuffer:
	cps iz, 0
	jr z, MidiOut_SerializeAndSend_Exit
	ei 0
	lds wa, 4
	ld bc, iz
	ld xde, 0xC0D2
	call sendCOMM

MidiOut_SerializeAndSend_Exit:
	popw iz
	ret

MidiThru_Disable:
	resda 6, 47074
	ret

MidiThru_Enable:
	setda 6, 47074
	ret

GET_COMPUTER_INTERFACE_SELECTION:
	ldda8 l, 47072
	ret

CompIface_ProcessInput:
	bitda 3, 49648
	jrl z, CompIface_RampControl
	bitda 2, 1054
	jr z, CompIface_FilterBySource
	bitda 2, 1057
	jr z, CompIface_FilterBySource
	bitda 4, 49648
	jr z, CompIface_CheckUpDown
	bitda 5, 49648
	jr z, CompIface_CheckUpDown
	cpdi16 10408, 0
	jr nz, CompIface_SetPedalBit
	jr CompIface_CallFilterA

CompIface_CheckUpDown:
	bitda 4, 49648
	jr z, CompIface_RampDown
	call AccWrap_PlayModeStartPlay
	setda 7, 13517
	jr CompIface_PostProcess

CompIface_RampDown:
	bitda 5, 49648
	jr z, CompIface_PostProcess
	cpdi16 10408, 0
	jr z, CompIface_RampDown_Start
	setda 1, 9834

CompIface_RampDown_Start:
	call AccWrap_PlayModeStopExpr
	jr CompIface_CallSync

CompIface_FilterBySource:
	bitda 2, 1054
	jr z, CompIface_FromSource2
	bitda 4, 49648
	jr z, CompIface_PostProcess
	call AccWrap_PlayModeDispatch
	jr CompIface_PostProcess

CompIface_FromSource2:
	bitda 2, 1057
	jr z, CompIface_PostProcess
	bitda 5, 49648
	jr z, CompIface_PostProcess
	call SeqState_GetFlags
	and hl, 0x7
	jr z, CompIface_Source2_ZeroCheck
	call SqTrSel_CaseG
	jr CompIface_PostProcess

CompIface_Source2_ZeroCheck:
	cpdi16 10408, 0
	jr z, CompIface_CallFilterA

CompIface_SetPedalBit:
	setda 1, 9834

CompIface_CallFilterA:
	call AccWrap_PlayModeDispatch

CompIface_CallSync:
	call SeqPlay_StopAndResetAll

CompIface_PostProcess:
	call AccompSeq_StopSequence
	bitda 6, 49648
	ret z
	ldda16 xwa, 1033
	subda16 xwa, 49642
	cpda16 xwa, 49660
	ret ule
	ld xwa, 0x40C1
	lds bc, 0
	lds de, 3
	call SoundParam_NotifyChange
	resda 3, 49648
	ldw wa, 0x4E
	call CtrlPanel_SetIndicatorLED
	ret

CompIface_RampControl:
	ldda16 xwa, 1033
	ld bc, wa
	subda16 xbc, 49642
	bitda 0, 49648
	jr z, CompIface_RampDown_Apply
	cp bc, 0xF
	ret c
	stda16 49642, xwa
	ldda16 xbc, 49646
	extz xbc
	ldda16 xwa, 49656
	extz xwa
	add xbc, xwa
	cp xbc, 0x7F00
	jr le, CompIface_RampUp_Clamp
	ld xbc, 0x7F00

CompIface_RampUp_Clamp:
	stda16 49646, xbc
	srl bc, 8
	stda8 49644, c
	extz bc
	ld xwa, 0x4005
	lds de, 1
	call SoundParam_NotifyChange
	cpdi8 49644, 127
	ret nz
	resda 0, 49648
	ld xwa, 0x40C0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	ret

CompIface_RampDown_Apply:
	bitda 1, 49648
	ret z
	cp bc, 0xF
	ret c
	stda16 49642, xwa
	ldda16 xbc, 49646
	extz xbc
	ldda16 xwa, 49658
	extz xwa
	sub xbc, xwa
	jr ge, CompIface_RampDown_Clamp
	lds32 xbc, 0

CompIface_RampDown_Clamp:
	stda16 49646, xbc
	srl bc, 8
	stda8 49644, c
	extz bc
	ld xwa, 0x4005
	lds de, 1
	call SoundParam_NotifyChange
	cpdi8 49644, 0
	ret nz
	resda 1, 49648
	setda 3, 49648
	ldw wa, 0x4E
	lds bc, 1
	lds de, 0
	call CtrlPanel_IndicatorDispatch
	ret

CompIface_ResetPedal:
	bitda 2, 49648
	ret z
	resda 2, 49648
	ldw wa, 0x4D
	call CtrlPanel_SetIndicatorLED
	setda 0, 49648
	ret

CompIface_SetMax:
	ldw wa, 0x7F
	calr CompIface_WriteVolume
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_CallProcessAll
	call SwbtWr_ReinitBothBanks
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

CompIface_ScaleValue:
	push xiz
	ld iz, bc
	extz xiz
	ldb w, 0x0
	extz xwa
	ld xbc, 0x1D4C0
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, xiz
	call Math_DivideU32
	pop xiz
	ret

CompIface_ScaleAndNormalize:
	push xiz
	ld iz, bc
	extz xiz
	ldb w, 0x0
	extz xwa
	ld xbc, 0x1EF0
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, xiz
	call Math_DivideU32
	ld xbc, xhl
	ld xwa, 0x7F00
	call Math_DivideU32
	pop xiz
	ret

CompIface_WriteVolume:
	ldda8 c, 49644
	cp c, a
	ret z
	stda8 49644, a
	ld c, a
	extz bc
	sll bc, 8
	stda16 49646, xbc
	ld c, a
	extz bc
	ld xwa, 0x4005
	lds de, 3
	call SoundParam_NotifyChange
	ret

Audio_ConfigureDSP:
	anddi8 49648, 243
	anddi8 49648, 252
	ld xwa, 0x40C0
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	ldw wa, 0x4D
	call CtrlPanel_SetIndicatorLED
	ld xwa, 0x40C1
	lds bc, 0
	lds de, 1
	call SoundParam_NotifyChange
	ldw wa, 0x4E
	call CtrlPanel_SetIndicatorLED
	ldw wa, 0x7F
	jr CompIface_WriteVolume
DSPCfg_ProcessInput:
	ldda8 c, 49280
	ldda8 e, 49277
	cp c, 0x48
	jrl z, DSPCfg_ScaleFactor_Dispatch
	ldda8 a, 49279
	cp c, 0x70
	jrl z, DSPCfg_CompressorDispatch
	cp c, 0x98
	ret nz
	cp e, 0xB
	ret nz
	ld c, a
	and a, 0xC0
	ret z
	bitda 0, 49648
	jr z, DSPCfg_Chorus_Active
	bit 7, c
	jr z, DSPCfg_Reverb_CheckSustain
	bitda 7, 49278
	jr nz, DSPCfg_Reverb_CheckSustain
	resda 0, 49648

DSPCfg_Reverb_CheckSustain:
	bitda 6, 49279
	jrl z, DSPCfg_UpdateOutputVolume
	bitda 6, 49278
	jrl z, DSPCfg_UpdateOutputVolume
	resda 0, 49648
	jrl DSPCfg_SetFadeBit

DSPCfg_Chorus_Active:
	bitda 2, 49648
	jr z, DSPCfg_FadeOut_Active
	bit 7, c
	jr z, DSPCfg_Chorus_CheckSustain
	bitda 7, 49278
	jr nz, DSPCfg_Chorus_CheckSustain
	resda 2, 49648
	ldw wa, 0x4D
	call CtrlPanel_SetIndicatorLED

DSPCfg_Chorus_CheckSustain:
	bitda 6, 49279
	jrl z, DSPCfg_UpdateOutputVolume
	bitda 6, 49278
	jrl z, DSPCfg_UpdateOutputVolume
	resda 2, 49648
	ldw wa, 0x4D
	call CtrlPanel_SetIndicatorLED
	setda 1, 49648
	ldw wa, 0x7F
	calr CompIface_WriteVolume
	jrl DSPCfg_UpdateOutputVolume

DSPCfg_FadeOut_Active:
	bitda 1, 49648
	jr z, DSPCfg_EQ_Active
	bit 7, c
	jr z, DSPCfg_FadeOut_CheckSustain
	bitda 7, 49278
	jr z, DSPCfg_FadeOut_CheckSustain
	setda 0, 49648
	resda 1, 49648

DSPCfg_FadeOut_CheckSustain:
	bitda 6, 49279
	jr z, DSPCfg_UpdateOutputVolume
	bitda 6, 49278
	jr nz, DSPCfg_UpdateOutputVolume
	resda 1, 49648
	jr DSPCfg_UpdateOutputVolume

DSPCfg_EQ_Active:
	bitda 3, 49648
	jr z, DSPCfg_Idle_EnableChorus
	bit 7, c
	jr z, DSPCfg_EQ_CheckSustain
	bitda 7, 49278
	jr z, DSPCfg_EQ_CheckSustain
	setda 0, 49648
	resda 3, 49648
	ldw wa, 0x4E
	call CtrlPanel_SetIndicatorLED

DSPCfg_EQ_CheckSustain:
	bitda 6, 49279
	jr z, DSPCfg_UpdateOutputVolume
	bitda 6, 49278
	jr nz, DSPCfg_UpdateOutputVolume
	resda 3, 49648
	ldw wa, 0x4E
	call CtrlPanel_SetIndicatorLED
	jr DSPCfg_UpdateOutputVolume

DSPCfg_Idle_EnableChorus:
	bit 7, c
	jr z, DSPCfg_Idle_CheckSustain
	bitda 7, 49278
	jr z, DSPCfg_Idle_CheckSustain
	setda 2, 49648
	ldw wa, 0x4D
	lds bc, 1
	lds de, 0
	call CtrlPanel_IndicatorDispatch
	lds wa, 0
	calr CompIface_WriteVolume

DSPCfg_Idle_CheckSustain:
	bitda 6, 49279
	jr z, DSPCfg_UpdateOutputVolume
	bitda 6, 49278
	jr z, DSPCfg_UpdateOutputVolume

DSPCfg_SetFadeBit:
	setda 1, 49648

DSPCfg_UpdateOutputVolume:
	ldda8 a, 49648
	and a, 0x3
	jr nz, DSPCfg_CheckChorusMuted
	ldw wa, 0x7F
	calr CompIface_WriteVolume

DSPCfg_CheckChorusMuted:
	bitda 2, 49648
	ret z
	lds wa, 0
	calr CompIface_WriteVolume
	ret

DSPCfg_CompressorDispatch:
	ld c, a
	and a, 0xFF
	cps e, 7
	jr z, DSPCfg_CompParam_SubType7
	cps e, 6
	jr z, DSPCfg_CompParam_SubType6
	cps e, 5
	ret nz
	cps a, 0
	ret z
	ld xwa, 0x2A00
	call SndParam_LookupReadOnly
	stda8 49650, l
	extz hl
	ldda16 xbc, 49654
	ld wa, hl
	calr CompIface_ScaleAndNormalize
	stda16 49656, xhl
	ret

DSPCfg_CompParam_SubType6:
	cps a, 0
	ret z
	ld xwa, 0x2A01
	call SndParam_LookupReadOnly
	stda8 49652, l
	extz hl
	ldda16 xbc, 49654
	ld wa, hl
	calr CompIface_ScaleAndNormalize
	stda16 49658, xhl
	ldda16 xbc, 49654
	lds wa, 1
	jrl DSPCfg_ScaleFactor_StoreResult

DSPCfg_CompParam_SubType7:
	bit 0, c
	jr z, DSPCfg_CompParam_Bit1
	ld xwa, 0x2A10
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 4
	anddi8 49648, 239
	orddm16 49648, xhl

DSPCfg_CompParam_Bit1:
	bitda 1, 49279
	jr z, DSPCfg_CompParam_Bit2
	ld xwa, 0x2A11
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 5
	anddi8 49648, 223
	orddm16 49648, xhl

DSPCfg_CompParam_Bit2:
	bitda 2, 49279
	ret z
	ld xwa, 0x2A12
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 6
	anddi8 49648, 191
	orddm16 49648, xhl
	ret

DSPCfg_ScaleFactor_Dispatch:
	cp e, 0x9
	jr z, DSPCfg_ScaleFactor_Update
	cp e, 0x8
	ret nz

DSPCfg_ScaleFactor_Update:
	lds32 xwa, 4
	call SndParam_LookupReadOnly
	stda16 49654, xhl
	ldda8 a, 49650
	extz wa
	ld bc, hl
	calr CompIface_ScaleAndNormalize
	stda16 49656, xhl
	ldda8 a, 49652
	extz wa
	ldda16 xbc, 49654
	calr CompIface_ScaleAndNormalize
	stda16 49658, xhl
	ldda16 xbc, 49654
	lds wa, 1

DSPCfg_ScaleFactor_StoreResult:
	calr CompIface_ScaleValue
	stda16 49660, xhl
	ret

DSPCfg_LookupMidiMap:
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	jp VoiceData_LookupPtrByIndex

DSPCfg_ExtractFieldPair:
	ld xix, xde
	ld xde, xwa
	ld w, (xix + 4)
	ld a, w
	and a, 0xF0
	ldfr_berp A, 0xF4
	extz iy
	and w, 0xF
	ld a, w
	extz wa
	cps wa, 2
	jr nz, DSPCfg_ExtractAdjustType2
	ld l, (xix + 5)
	and l, 0x1F

DSPCfg_ExtractAdjustType2:
	ld (xde), iy
	ld (xbc), wa
	ret

DSPCfg_ExtractFieldSingle:
	ld l, (xde + 4)
	ld e, l
	and e, 0xF0
	ldfr_berp E, 0xF0
	extz ix
	and l, 0xF
	extz hl
	ld (xwa), ix
	ld (xbc), hl
	ret

DSPCfg_WriteParam:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 12), de
	ld xde, xbc
	ld xiz, xwa
	ld xwa, (xsp + 22)
	ld wa, (xwa)
	ld (xsp + 4), wa
	ld a, (xde + 2)
	ldfr_berp A, 0xE6
	lda xwa, (xsp + 10)
	ld bc, (xsp + 12)
	ld hl, bc
	srl hl, 8
	cp_erpb 0xE6, 0x76
	jrl z, DSPCfg_WriteParam_Type76
	cp_erpb 0xE6, 0x70
	jr z, DSPCfg_WriteParam_Type70
	and c, 0xFF
	cp_erpb 0xE6, 0x67
	jr z, DSPCfg_WriteParam_Type64_67
	cp_erpb 0xE6, 0x64
	jr z, DSPCfg_WriteParam_Type64_67
	ld wa, (xsp + 12)
	ld (xiz), a

DSPCfg_WriteParam_SetMask:
	ldb e, 0xFF

DSPCfg_WriteParam_Exit:
	ld xwa, (xsp + 22)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ld xwa, (xsp + 18)
	ld (xwa), e
	lds hl, 0
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x8

DSPCfg_WriteParam_Type64_67:
	ld (xiz), l
	ld (xiz + 1), c
	jr DSPCfg_WriteParam_SetMask

DSPCfg_WriteParam_Type70:
	lda xbc, (xsp + 6)
	calr DSPCfg_ExtractFieldSingle
	ld wa, (xsp + 10)
	lda xbc, (xiz + 1)
	cp wa, 0x20
	jr z, DSPCfg_WriteParam_Type70_Sub20
	cp wa, 0x10
	jr z, DSPCfg_WriteParam_Type70_Sub10
	ld wa, (xsp + 12)
	sra wa, 2
	and a, 0x7
	ld e, a
	ld a, (xiz)
	and a, 0xF8
	add a, e
	ld (xiz), a
	ld wa, (xsp + 12)
	sla wa, 6
	and a, 0xC0
	ld e, a
	ld a, (xbc)
	and a, 0x3F
	add a, e
	ld (xbc), a
	jr DSPCfg_WriteParam_SetMask7

DSPCfg_WriteParam_Type70_Sub10:
	ld wa, (xsp + 12)
	sla wa, 3
	and a, 0xF8
	ld c, a
	ld a, (xiz)
	and a, 0x7
	add a, c
	ld (xiz), a
	ldb e, 0xF8
	jr DSPCfg_WriteParam_Exit

DSPCfg_WriteParam_Type70_Sub20:
	ld wa, (xsp + 12)
	and a, 0x3F
	ld e, a
	ld a, (xbc)
	and a, 0xC0
	add a, e
	ld (xbc), a
	jr DSPCfg_WriteParam_IncCounter

DSPCfg_WriteParam_Type76:
	lda xbc, (xsp + 8)
	calr DSPCfg_ExtractFieldPair
	ld wa, (xsp + 10)
	cp wa, 0x10
	jr z, DSPCfg_WriteParam_Type76_Sub10
	ld wa, (xsp + 12)
	sra wa, 2
	and a, 0x7
	ld c, a
	ld a, (xiz)
	and a, 0xF8
	add a, c
	ld (xiz), a
	ld wa, (xsp + 12)
	sla wa, 6
	and a, 0xC0
	ld e, a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	and a, 0x3F
	add a, e
	ld (xbc), a

DSPCfg_WriteParam_SetMask7:
	ldb e, 0x7
	jrl DSPCfg_WriteParam_Exit

DSPCfg_WriteParam_Type76_Sub10:
	ld wa, (xsp + 12)
	and a, 0x3F
	ld c, a
	cpw (xsp + 8), 0x2
	jr nz, DSPCfg_WriteParam_Type76_NotType2
	ld (xiz), c
	jr DSPCfg_WriteParam_SetMask3F

DSPCfg_WriteParam_Type76_NotType2:
	lda xde, (xiz + 1)
	ld a, (xde)
	and a, 0xC0
	add a, c
	ld (xde), a

DSPCfg_WriteParam_IncCounter:
	incm 1, (xsp + 4)

DSPCfg_WriteParam_SetMask3F:
	ldb e, 0x3F
	jrl DSPCfg_WriteParam_Exit

DSPCfg_PackAddress:
	ld e, (xwa + 1)
	and e, 0xFF
	extz de
	ld c, (xwa)
	extz bc
	sll bc, 8
	ld hl, bc
	ldb l, 0x0
	add hl, de
	ld bc, hl
	srl bc, 8
	cp bc, 0xF0
	jr z, DSPCfg_PackAddress_ReturnInput
	extz xhl
	add xwa, xhl

DSPCfg_PackAddress_ReturnInput:
	ld xhl, xwa
	ret

DSPCfg_ReadField:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 12), xde
	ld xde, xbc
	ld xbc, xwa
	ldi_werp 0xFA, 0
	ld l, (xbc + 1)
	extz hl
	ld a, (xbc)
	extz wa
	ld iz, wa
	sll iz, 8
	add iz, hl
	ld xwa, (xsp + 20)
	ld wa, (xwa)
	ld (xsp + 4), wa
	ld a, (xde + 2)
	ldfr_berp A, 0xEE
	lda xwa, (xsp + 10)
	cp_erpb 0xEE, 0x76
	jr z, DSPCfg_ReadField_Type76
	ld hl, iz
	cp_erpb 0xEE, 0x70
	jr z, DSPCfg_ReadField_Type70
	cp_erpb 0xEE, 0x68
	jr z, DSPCfg_ReadField_Type68_Unsigned
	cp_erpb 0xEE, 0x67
	jr z, DSPCfg_ReadField_GoWidth2
	cp_erpb 0xEE, 0x64
	jr z, DSPCfg_ReadField_GoWidth2
	ld l, (xbc)
	exts hl

DSPCfg_ReadField_SetWidth1:
	ldi_werp 0xFA, 1

DSPCfg_ReadField_StoreAndReturn:
	ld xwa, (xsp + 12)
	ldto_werp BC, 0xFA
	ld (xwa), bc
	ld xwa, (xsp + 20)
	ld bc, (xsp + 4)
	ld (xwa), bc
	pop xiz
	lda xsp, (xsp + 12)
	retd 0x4

DSPCfg_ReadField_GoWidth2:
	jr DSPCfg_ReadField_SetWidth2

DSPCfg_ReadField_Type68_Unsigned:
	ld l, (xbc)
	exts hl
	and hl, 0xFF
	jr DSPCfg_ReadField_SetWidth1

DSPCfg_ReadField_Type70:
	lda xbc, (xsp + 6)
	calr DSPCfg_ExtractFieldSingle
	ld wa, (xsp + 10)
	cp wa, 0x20
	jr z, DSPCfg_ReadField_Type70_Width32
	cp wa, 0x10
	jr z, DSPCfg_ReadField_Type70_Width16
	ld wa, iz
	srl wa, 6
	and wa, 0x1F
	ld hl, wa
	cpw (xsp + 6), 0x1
	jr nz, DSPCfg_ReadField_StoreAndReturn
	jr DSPCfg_ReadField_SetWidth2

DSPCfg_ReadField_Type70_Width16:
	ldw wa, 0xB
	jr DSPCfg_ReadField_Type76_ShiftAndMask

DSPCfg_ReadField_Type70_Width32:
	ld hl, iz
	and hl, 0x3F

DSPCfg_ReadField_SetWidth2:
	ldi_werp 0xFA, 2
	jr DSPCfg_ReadField_StoreAndReturn

DSPCfg_ReadField_Type76:
	lda xbc, (xsp + 8)
	calr DSPCfg_ExtractFieldPair
	ld wa, (xsp + 10)
	cp wa, 0x10
	jr z, DSPCfg_ReadField_Type76_Width16
	lds wa, 6

DSPCfg_ReadField_Type76_ShiftAndMask:
	ld bc, iz
	and a, 0xF
	jr z, DSPCfg_ReadField_Type76_Mask5Bits
	srla bc

DSPCfg_ReadField_Type76_Mask5Bits:
	and bc, 0x1F
	ld hl, bc
	jr DSPCfg_ReadField_StoreAndReturn

DSPCfg_ReadField_Type76_Width16:
	cpw (xsp + 8), 0x2
	jr nz, DSPCfg_ReadField_Type70_Width32
	ld wa, iz
	srl wa, 8
	and wa, 0x3F
	ld hl, wa
	jrl DSPCfg_ReadField_SetWidth1

DSPCfg_WriteMultiField:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 12), de
	ld xiz, xbc
	ld (xsp + 14), xwa
	ldw (xsp + 10), 0x0
	ldw (xsp + 8), 0x0
	ldw (xsp + 4), 0x0
	cpw (xsp + 12), 0x0
	jr ule, DSPCfg_WriteMultiField_Final

DSPCfg_WriteMultiField_Loop:
	ld wa, (xsp + 10)
	add (xsp + 8), wa
	lda xde, (xsp + 10)
	lda xwa, (xsp + 8)
	push xwa
	ld xwa, (xsp + 18)
	ld xbc, xiz
	calr DSPCfg_ReadField
	lds bc, 0
	cpw (xsp + 10), 0x0
	jr ule, DSPCfg_WriteMultiField_AdvanceAddr

DSPCfg_WriteMultiField_AccumXWA:
	lds32 xwa, 1
	add (xsp + 14), xwa
	inc 1, bc
	cp bc, (xsp + 10)
	jr c, DSPCfg_WriteMultiField_AccumXWA

DSPCfg_WriteMultiField_AdvanceAddr:
	ld xwa, xiz
	calr DSPCfg_PackAddress
	ld xiz, xhl
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (xsp + 12)
	jr c, DSPCfg_WriteMultiField_Loop

DSPCfg_WriteMultiField_Final:
	ld wa, (xsp + 10)
	add (xsp + 8), wa
	lda xwa, (xsp + 8)
	push xwa
	lda xwa, (xsp + 10)
	push xwa
	ld xwa, (xsp + 22)
	ld xbc, xiz
	ld de, (xsp + 38)
	calr DSPCfg_WriteParam
	ld xbc, (xsp + 26)
	ld wa, (xsp + 8)
	ld (xbc), a
	ld xbc, (xsp + 22)
	ld a, (xsp + 6)
	ld (xbc), a
	pop xiz
	lda xsp, (xsp + 14)
	retd 0xA

DSPCfg_ReadMultiField:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 10), de
	ld (xsp + 12), xbc
	ld xiz, xwa
	ldw (xsp + 8), 0x0
	ldw (xsp + 6), 0x0
	ldw (xsp + 4), 0x0
	cpw (xsp + 10), 0x0
	jr ule, DSPCfg_ReadMultiField_Final

DSPCfg_ReadMultiField_Loop:
	ld wa, (xsp + 8)
	add (xsp + 6), wa
	lda xde, (xsp + 8)
	lda xwa, (xsp + 6)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 16)
	calr DSPCfg_ReadField
	lds wa, 0
	cpw (xsp + 8), 0x0
	jr ule, DSPCfg_ReadMultiField_PackAndNext

DSPCfg_ReadMultiField_AdvancePtr:
	inc 1, xiz
	inc 1, wa
	cp wa, (xsp + 8)
	jr c, DSPCfg_ReadMultiField_AdvancePtr

DSPCfg_ReadMultiField_PackAndNext:
	ld xwa, (xsp + 12)
	calr DSPCfg_PackAddress
	ld (xsp + 12), xhl
	incm 1, (xsp + 4)
	ld wa, (xsp + 4)
	cp wa, (xsp + 10)
	jr c, DSPCfg_ReadMultiField_Loop

DSPCfg_ReadMultiField_Final:
	ld wa, (xsp + 8)
	add (xsp + 6), wa
	lda xde, (xsp + 8)
	lda xwa, (xsp + 6)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 16)
	calr DSPCfg_ReadField
	pop xiz
	lda xsp, (xsp + 12)
	ret

DSPCfg_GetParamCount:
	ld l, (xwa)
	extz hl
	ret

DSPCfg_ReadViaTableLookup:
	dec 2, xsp
	push xiz
	ld xiz, xbc
	ld (xsp + 4), wa
	ld xwa, xiz
	calr DSPCfg_GetParamCount
	exts xhl
	sll xhl, 2
	ld xbc, 0xEE75F6
	add xbc, xhl
	ld xbc, (xbc)
	lda xwa, (xiz + 1)
	ld de, (xsp + 4)
	calr DSPCfg_ReadMultiField
	pop xiz
	inc 2, xsp
	ret

DSPCfg_StoreByte_ReturnZero:
	ld (xbc), a
	lds hl, 0
	ret

DSPCfg_WriteViaTableLookup:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), bc
	ld (xsp + 6), wa
	ld xwa, xiz
	calr DSPCfg_GetParamCount
	exts xhl
	sll xhl, 2
	ld xbc, 0xEE75F6
	add xbc, xhl
	ld xbc, (xbc)
	lda xwa, (xiz + 1)
	pushm (xsp + 4)
	ld xde, (xsp + 18)
	push xde
	ld xde, (xsp + 18)
	push xde
	ld de, (xsp + 16)
	calr DSPCfg_WriteMultiField
	pop xiz
	inc 4, xsp
	retd 0x8

DSPCfg_ExtractPairFromStruct:
	pushw iz
	ld xhl, xbc
	ld c, (xwa + 1)
	and c, 0xFF
	ldfr_berp C, 0xF4
	extz iy
	ld c, (xwa)
	exts bc
	ld ix, bc
	sla ix, 8
	or ix, iy
	lda xiy, (xwa + 2)
	ld c, (xiy + 1)
	and c, 0xFF
	extz bc
	ld a, (xiy)
	exts wa
	ld iz, wa
	sla iz, 8
	or iz, bc
	lda xbc, (xiy + 2)
	ld xwa, xbc
	inc 1, xwa
	ld c, (xbc)
	ldfr_berp C, 0xF4
	ld c, (xwa)
	exts bc
	ld (xhl), ix
	ld (xde), iz
	ld xwa, (xsp + 10)
	ld (xwa), bc
	ld xbc, (xsp + 6)
	ldto_berp A, 0xF4
	ld (xbc), a
	popw iz
	retd 0x8

DSPCfg_LookupAndExtract:
	dec 8, xsp
	extz xbc
	sll xbc, 2
	ld xde, 0xEE6044
	add xde, xbc
	mul wa, 0x6
	add xwa, (xde)
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	lda xhl, (xsp + 2)
	push xhl
	lda xhl, (xsp + 4)
	push xhl
	calr DSPCfg_ExtractPairFromStruct
	ld hl, (xsp + 2)
	inc 8, xsp
	ret

DSPCfg_Data_FDC448:
	extz	xwa
	ld	xbc, 15623012
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret

DSPCfg_GetSlotCount:
	extz xwa
	ld xbc, 0xEE5FE0
	add xbc, xwa
	ld l, (xbc)
	extz hl
	ret

DSPCfg_Data_FDC464:
	extz	xwa
	ld	xbc, 15623016
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret

DSPCfg_FindSlot63:
	dec 2, xsp
	push xiz
	ld iz, wa
	ldw (xsp + 4), 0xFFFF
	ld wa, iz
	calr DSPCfg_GetSlotCount
	ldfr_werp HL, 0xFA
	ld wa, iz
	exts xwa
	sll xwa, 2
	ld xbc, 0xEE75F6
	add xbc, xwa
	ld xwa, (xbc)
	lds iz, 0
	cpi_werp 0xFA, 0
	jr le, DSPCfg_FindSlot63_Return

DSPCfg_FindSlot63_Loop:
	cp (xwa + 2), 0x63
	jr nz, DSPCfg_FindSlot63_Next
	ld (xsp + 4), iz

DSPCfg_FindSlot63_Next:
	calr DSPCfg_PackAddress
	ld xwa, xhl
	inc 1, iz
	cp_werp IZ, 0xFA
	jr lt, DSPCfg_FindSlot63_Loop

DSPCfg_FindSlot63_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

DSPCfg_Data_FDC4B7:
	dec	8, xsp
	push	xiz
	ld	iz, wa
	ld	xwa, xbc
	calr	-354
	.byte 0xdb, 0xec, 0x02
	lda_24	xbc, 15622212
	mul	iz, 6
	ld	xwa, xiz
	.byte 0xe3, 0x07, 0xe4, 0xec, 0x80
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	lda	xhl, (xsp+4)
	push	xhl
	lda	xhl, (xsp+10)
	push	xhl
	calr	-284
	ldw	hl, 65535
	cp	(xsp+6), 1
	jr	nz, 2
	lds	hl, 0
	pop	xiz
	inc	8, xsp
	ret
	cps	wa, 4
	jr	ge, 8
	cps	wa, 0
	jr	lt, 4
	lds	hl, 0
	jr	3
	ldw	hl, 65535
	ret

DSPCfg_DecodeParamIdRange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 6), xde
	ld (xsp + 10), xbc
	ld xiz, xwa
	ldw (xsp + 4), 0x0
	ld xwa, (xsp + 22)
	calr DSPCfg_GetParamCount
	ld xwa, xiz
	cp xiz, 0x4947
	jr ugt, DSPCfg_DecodeParamIdRange_Invalid
	cp xiz, 0x4940
	jr nc, DSPCfg_DecodeParamIdRange_4940
	cp xiz, 0x4927
	jr ugt, DSPCfg_DecodeParamIdRange_Invalid
	cp xiz, 0x4910
	jr nc, DSPCfg_DecodeParamIdRange_4910
	sub xwa, 0x4900
	cp xwa, 0x0
	jr c, DSPCfg_DecodeParamIdRange_Invalid
	cp xwa, 0x7
	jr ugt, DSPCfg_DecodeParamIdRange_Invalid
	add xwa, 0xEE6372
	ld c, (xwa)
	exts bc
	ld xwa, (xsp + 6)
	ld (xwa), bc
	jr DSPCfg_DecodeParamIdRange_Return

DSPCfg_DecodeParamIdRange_4910:
	ld xwa, (xsp + 6)
	ldw (xwa), 0x1
	ld xwa, 0x4910
	jr DSPCfg_DecodeParamIdRange_CalcOffset

DSPCfg_DecodeParamIdRange_4940:
	ld xwa, (xsp + 6)
	ldw (xwa), 0x4
	ld xwa, 0x4940

DSPCfg_DecodeParamIdRange_CalcOffset:
	ld xbc, xiz
	sub xbc, xwa
	ld xwa, (xsp + 10)
	ld (xwa), bc
	jr DSPCfg_DecodeParamIdRange_Return

DSPCfg_DecodeParamIdRange_Invalid:
	ld xwa, (xsp + 6)
	ldw (xwa), 0xFFFF
	ld xwa, (xsp + 10)
	ldw (xwa), 0xFFFF
	ldw (xsp + 4), 0xFFFF

DSPCfg_DecodeParamIdRange_Return:
	ld xwa, (xsp + 18)
	ld (xwa), hl
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x8

DSPCfg_ResolveParamToSlot:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 10), xde
	ld (xsp + 14), xbc
	ld xiz, xwa
	cp xiz, 0x4F00
	jr ugt, DSPCfg_ResolveParamToSlot_OutOfRange
	cp xiz, 0x4900
	jr nc, DSPCfg_ResolveParamToSlot_Range49

DSPCfg_ResolveParamToSlot_OutOfRange:
	ldw hl, 0xFFFF
	jrl DSPCfg_ResolveParamToSlot_StoreResult

DSPCfg_ResolveParamToSlot_Range49:
	cp xiz, 0x4A00
	jr nc, DSPCfg_ResolveParamToSlot_Range4A
	ldw (xsp + 8), 0x0
	lds wa, 0
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	jrl DSPCfg_ResolveParamToSlot_CallDecode

DSPCfg_ResolveParamToSlot_Range4A:
	cp xiz, 0x4B00
	jr nc, DSPCfg_ResolveParamToSlot_Range4B
	ldw (xsp + 8), 0x1
	lds wa, 1
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, xiz
	sub xwa, 0x200
	ld xbc, (xsp + 4)
	push xbc
	ld xbc, (xsp + 26)
	push xbc
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	jrl DSPCfg_ResolveParamToSlot_CallDecode

DSPCfg_ResolveParamToSlot_Range4B:
	cp xiz, 0x4C00
	jr nc, DSPCfg_ResolveParamToSlot_Range4C
	ldw (xsp + 8), 0x1
	lds wa, 1
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, xiz
	sub xwa, 0x200
	ld xbc, (xsp + 4)
	push xbc
	ld xbc, (xsp + 26)
	push xbc
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	jr DSPCfg_ResolveParamToSlot_CallDecode

DSPCfg_ResolveParamToSlot_Range4C:
	cp xiz, 0x4D00
	jr nc, DSPCfg_ResolveParamToSlot_Range4D
	ldw (xsp + 8), 0x4
	lds wa, 4
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, xiz
	sub xwa, 0x300
	ld xbc, (xsp + 4)
	push xbc
	ld xbc, (xsp + 26)
	push xbc
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	jr DSPCfg_ResolveParamToSlot_CallDecode

DSPCfg_ResolveParamToSlot_Range4D:
	cp xiz, 0x4E00
	jr nc, DSPCfg_ResolveParamToSlot_Range4E
	ldw (xsp + 8), 0x2
	lds wa, 2
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, xiz
	sub xwa, 0x400
	ld xbc, (xsp + 4)
	push xbc
	ld xbc, (xsp + 26)
	push xbc
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)
	jr DSPCfg_ResolveParamToSlot_CallDecode

DSPCfg_ResolveParamToSlot_Range4E:
	ldw (xsp + 8), 0x3
	lds wa, 3
	calr DSPCfg_LookupMidiMap
	ld (xsp + 4), xhl
	ld xwa, xiz
	sub xwa, 0x500
	ld xbc, (xsp + 4)
	push xbc
	ld xbc, (xsp + 26)
	push xbc
	ld xbc, (xsp + 38)
	ld xde, (xsp + 34)

DSPCfg_ResolveParamToSlot_CallDecode:
	calr DSPCfg_DecodeParamIdRange

DSPCfg_ResolveParamToSlot_StoreResult:
	ld xwa, (xsp + 14)
	ld xbc, (xsp + 4)
	ld (xwa), xbc
	ld xwa, (xsp + 10)
	ld bc, (xsp + 8)
	ld (xwa), bc
	pop xiz
	lda xsp, (xsp + 14)
	retd 0xC

DSPCfg_ResolveAndExtract:
	lda xsp, (xsp - 12)
	lda xde, (xsp + 4)
	lda xbc, (xsp + 2)
	push xbc
	lda xbc, (xsp + 4)
	push xbc
	lda xbc, (xsp + 14)
	push xbc
	lda xbc, (xsp + 20)
	calr DSPCfg_ResolveParamToSlot
	cps hl, 0
	jr nz, DSPCfg_ResolveAndExtract_Return
	ld wa, (xsp + 2)
	ld bc, (xsp + 6)
	calr DSPCfg_LookupAndExtract

DSPCfg_ResolveAndExtract_Return:
	lda xsp, (xsp + 12)
	ret

DSPCfg_ResolveWithFallback:
	lda xsp, (xsp - 18)
	pushw iz
	ld iz, bc
	ld (xsp + 16), xwa
	lda xde, (xsp + 8)
	lda xwa, (xsp + 6)
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	lda xbc, (xsp + 24)
	ld xwa, (xsp + 28)
	calr DSPCfg_ResolveParamToSlot
	ld (xsp + 2), hl
	cps iz, 0
	jr z, DSPCfg_ResolveWithFallback_CheckType
	ld wa, (xsp + 10)
	extz xwa
	sll xwa, 2
	ld xbc, 0xEE61D4
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 12), xwa
	ld wa, (xsp + 8)
	extz xwa
	add xwa, xwa
	ld xbc, 0xEE637A
	add xbc, xwa
	ld bc, (xbc)
	sll bc, 8
	extz xbc
	ld xwa, (xsp + 16)
	sub xwa, xbc
	lda xbc, (xsp + 6)
	lda xde, (xsp + 4)
	ld xhl, (xsp + 12)
	push xhl
	lda xhl, (xsp + 14)
	push xhl
	calr DSPCfg_DecodeParamIdRange
	ld (xsp + 2), hl

DSPCfg_ResolveWithFallback_CheckType:
	ld wa, (xsp + 10)
	cpw (xsp + 2), 0x0
	jr nz, DSPCfg_ResolveWithFallback_Return
	ld bc, (xsp + 4)
	cp bc, 0x9
	jr z, DSPCfg_ResolveWithFallback_Type9
	cp bc, 0x8
	jr z, DSPCfg_ResolveWithFallback_Type8
	cps bc, 1
	jr z, DSPCfg_ResolveWithFallback_Type1
	cps bc, 0
	jr nz, DSPCfg_ResolveWithFallback_UnknownType
	ld (xsp + 2), wa
	jr DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_Type1:
	ld wa, (xsp + 6)
	ld xbc, (xsp + 12)
	calr DSPCfg_ReadViaTableLookup
	ld (xsp + 2), hl
	ld xwa, (xsp + 16)
	cp xwa, 0x491D
	jr nz, DSPCfg_ResolveWithFallback_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_ResolveWithFallback_SndParam4003
	cp hl, 0xF
	jr nz, DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_SndParam4003:
	ld xwa, 0x4003
	call SndParam_LookupReadOnly
	ld (xsp + 2), hl
	jr DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_Type8:
	ld wa, (xsp + 10)
	calr DSPCfg_GetSlotCount
	ld (xsp + 2), hl
	jr DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_Type9:
	calr DSPCfg_FindSlot63
	ld (xsp + 2), hl
	jr DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_UnknownType:
	ldw (xsp + 2), 0xFFFF

DSPCfg_ResolveWithFallback_Return:
	ld hl, (xsp + 2)
	popw iz
	lda xsp, (xsp + 18)
	ret

DSPCfg_ReadParam_Map0:
	lds bc, 0
	jrl DSPCfg_ResolveWithFallback

DSPCfg_ReadParam_Map1:
	lds bc, 1
	jrl DSPCfg_ResolveWithFallback

DSPCfg_ClampAndExtract:
	lda xsp, (xsp - 16)
	pushw iz
	ld (xsp + 12), xde
	ld (xsp + 16), bc
	ld iz, wa
	ld xwa, (xsp + 12)
	ld wa, (xwa)
	ld (xsp + 2), wa
	ld wa, iz
	calr DSPCfg_GetSlotCount
	cp (xsp + 16), hl
	jr nc, DSPCfg_ClampAndExtract_NoSlot
	ld wa, iz
	extz xwa
	sll xwa, 2
	ld xbc, 0xEE6044
	add xbc, xwa
	ld wa, (xsp + 16)
	mul wa, 0x6
	add xwa, (xbc)
	lda xbc, (xsp + 10)
	lda xde, (xsp + 8)
	lda xhl, (xsp + 4)
	push xhl
	lda xhl, (xsp + 10)
	push xhl
	calr DSPCfg_ExtractPairFromStruct
	ld wa, (xsp + 2)
	cp wa, (xsp + 10)
	jr ge, DSPCfg_ClampAndExtract_CheckMax
	ldw hl, 0xFFFE
	ld wa, (xsp + 10)
	ld (xsp + 2), wa
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_CheckMax:
	ld wa, (xsp + 2)
	cp wa, (xsp + 8)
	jr le, DSPCfg_ClampAndExtract_InRange
	ldw hl, 0xFFFD
	ld wa, (xsp + 8)
	ld (xsp + 2), wa
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_InRange:
	lds hl, 0
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_NoSlot:
	ldw hl, 0xFFFF

DSPCfg_ClampAndExtract_Return:
	ld xwa, (xsp + 12)
	ld bc, (xsp + 2)
	ld (xwa), bc
	popw iz
	lda xsp, (xsp + 16)
	ret

DSPCfg_ValidateSlotForWrite:
	cp wa, 0x63
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	ld de, wa
	extz xde
	sll xde, 2
	ld xhl, 0xEE75F6
	add xhl, xde
	ld xde, (xhl)
	or xde, xde
	jr z, DSPCfg_ValidateSlotForWrite_Invalid
	cps bc, 4
	jr z, DSPCfg_ValidateSlotForWrite_Slot4
	cps bc, 3
	jr z, DSPCfg_ValidateSlotForWrite_Slot3
	cps bc, 2
	jr z, DSPCfg_ValidateSlotForWrite_Slot2
	cps bc, 1
	jr z, DSPCfg_ValidateSlotForWrite_Slot1
	cps bc, 0
	jr nz, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x10
	jr c, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0x1B
	jr ugt, DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Invalid:
	ldw hl, 0xFFFF

DSPCfg_ValidateSlotForWrite_Ret:
	ret

DSPCfg_ValidateSlotForWrite_Slot1:
	cp wa, 0x9
	jr z, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0xA
	jr z, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0x10
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x1B
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot2:
	cp wa, 0x39
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x3C
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot3:
	cp wa, 0x58
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x5B
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot4:
	cp wa, 0x4F
	jr nz, DSPCfg_ValidateSlotForWrite_Invalid

DSPCfg_ValidateSlotForWrite_Valid:
	lds hl, 0
	jr DSPCfg_ValidateSlotForWrite_Ret

DSPCfg_WriteParamFull:
	lda xsp, (xsp - 22)
	pushw iz
	ld (xsp + 18), bc
	ld (xsp + 20), xwa
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	lda xwa, (xsp + 6)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	lda xbc, (xsp + 26)
	ld xwa, (xsp + 32)
	calr DSPCfg_ResolveParamToSlot
	ld iz, hl
	cps iz, 0
	jrl nz, DSPCfg_WriteParamFull_Return
	ld wa, (xsp + 2)
	cps wa, 1
	jr z, DSPCfg_WriteParamFull_Type1
	cps wa, 0
	jrl nz, DSPCfg_WriteParamFull_UnknownType
	ld wa, (xsp + 18)
	ld bc, (xsp + 6)
	calr DSPCfg_ValidateSlotForWrite
	ld iz, hl
	cp iz, 0xFFFF
	jrl z, DSPCfg_WriteParamFull_Return
	ld wa, (xsp + 18)
	ld xbc, (xsp + 14)
	calr DSPCfg_StoreByte_ReturnZero
	ld iz, hl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld bc, (xsp + 18)
	ldb b, 0x0
	ld e, c
	extz de
	pushw 0xFF
	lds bc, 0
	call AssswbWr
	jrl DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_Type1:
	ld wa, (xsp + 8)
	ld bc, (xsp + 4)
	lda xde, (xsp + 18)
	calr DSPCfg_ClampAndExtract
	ld iz, hl
	cp iz, 0xFFFF
	jr z, DSPCfg_WriteParamFull_Check491D
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	cps iz, 0
	jr nz, DSPCfg_WriteParamFull_Type1_Clamped
	push xwa
	push xbc
	ld wa, (xsp + 12)
	ld bc, (xsp + 26)
	ld xde, (xsp + 22)
	calr DSPCfg_WriteViaTableLookup
	ld iz, hl
	jr DSPCfg_WriteParamFull_Type1_Notify

DSPCfg_WriteParamFull_Type1_Clamped:
	push xwa
	push xbc
	ld wa, (xsp + 12)
	ld bc, (xsp + 26)
	ld xde, (xsp + 22)
	calr DSPCfg_WriteViaTableLookup

DSPCfg_WriteParamFull_Type1_Notify:
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 12)
	inc 1, c
	extz bc
	ld de, (xsp + 18)
	ldb d, 0x0
	extz de
	ld l, (xsp + 10)
	extz hl
	pushw hl
	call AssswbWr

DSPCfg_WriteParamFull_Check491D:
	ld xwa, (xsp + 20)
	cp xwa, 0x491D
	jr nz, DSPCfg_WriteParamFull_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_WriteParamFull_Notify4003
	cp hl, 0xF
	jr nz, DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_Notify4003:
	ld bc, (xsp + 18)
	ld xwa, 0x4003
	lds de, 3
	call SoundParam_NotifyChange
	jr DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_UnknownType:
	ldw iz, 0xFFFF

DSPCfg_WriteParamFull_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp + 22)
	ret

DSPCfg_WriteParamSimple:
	lda xsp, (xsp - 26)
	pushw iz
	ld (xsp + 18), xde
	ld (xsp + 22), bc
	ld (xsp + 24), xwa
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	lda xwa, (xsp + 6)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	lda xbc, (xsp + 26)
	ld xwa, (xsp + 36)
	calr DSPCfg_ResolveParamToSlot
	ld iz, hl
	cps iz, 0
	jrl nz, DSPCfg_WriteParamSimple_Return
	ld wa, (xsp + 2)
	cps wa, 1
	jr z, DSPCfg_WriteParamSimple_Type1
	cps wa, 0
	jrl nz, DSPCfg_WriteParamSimple_UnknownType
	ld wa, (xsp + 22)
	ld bc, (xsp + 6)
	calr DSPCfg_ValidateSlotForWrite
	ld iz, hl
	cp iz, 0xFFFF
	jr z, DSPCfg_WriteParamSimple_Return
	ld wa, (xsp + 22)
	ld xbc, (xsp + 18)
	calr DSPCfg_StoreByte_ReturnZero
	ld iz, hl
	jr DSPCfg_WriteParamSimple_Return

DSPCfg_WriteParamSimple_Type1:
	ld wa, (xsp + 8)
	ld bc, (xsp + 4)
	lda xde, (xsp + 22)
	calr DSPCfg_ClampAndExtract
	ld iz, hl
	cp iz, 0xFFFF
	jr z, DSPCfg_WriteParamSimple_Check491D
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	cps iz, 0
	jr nz, DSPCfg_WriteParamSimple_Type1_Clamped
	push xwa
	push xbc
	ld wa, (xsp + 12)
	ld bc, (xsp + 30)
	ld xde, (xsp + 26)
	calr DSPCfg_WriteViaTableLookup
	ld iz, hl
	jr DSPCfg_WriteParamSimple_Check491D

DSPCfg_WriteParamSimple_Type1_Clamped:
	push xwa
	push xbc
	ld wa, (xsp + 12)
	ld bc, (xsp + 30)
	ld xde, (xsp + 26)
	calr DSPCfg_WriteViaTableLookup

DSPCfg_WriteParamSimple_Check491D:
	ld xwa, (xsp + 24)
	cp xwa, 0x491D
	jr nz, DSPCfg_WriteParamSimple_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_WriteParamSimple_Notify4003
	cp hl, 0xF
	jr nz, DSPCfg_WriteParamSimple_Return

DSPCfg_WriteParamSimple_Notify4003:
	ld bc, (xsp + 22)
	ld xwa, 0x4003
	lds de, 3
	call SoundParam_NotifyChange
	jr DSPCfg_WriteParamSimple_Return

DSPCfg_WriteParamSimple_UnknownType:
	ldw iz, 0xFFFF

DSPCfg_WriteParamSimple_Return:
	ld hl, iz
	popw iz
	lda xsp, (xsp + 26)
	ret

DSPCfg_WriteParamDelta:
	lda xsp, (xsp - 16)
	pushw iz
	ld iz, bc
	ld (xsp + 14), xwa
	lda xde, (xsp + 6)
	lda xwa, (xsp + 4)
	push xwa
	lda xwa, (xsp + 6)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	lda xbc, (xsp + 22)
	ld xwa, (xsp + 26)
	calr DSPCfg_ResolveParamToSlot
	cps hl, 0
	jr nz, DSPCfg_WriteParamDelta_Return
	ld wa, (xsp + 2)
	cps wa, 1
	jr z, DSPCfg_WriteParamDelta_Type1
	cps wa, 0
	jr nz, DSPCfg_WriteParamDelta_BadType
	ld xwa, (xsp + 10)
	calr DSPCfg_GetParamCount
	add iz, hl
	ld xwa, (xsp + 14)
	ld bc, iz
	jr DSPCfg_WriteParamDelta_CallWrite

DSPCfg_WriteParamDelta_Type1:
	ld wa, (xsp + 4)
	ld xbc, (xsp + 10)
	calr DSPCfg_ReadViaTableLookup
	add iz, hl
	ld xwa, (xsp + 14)
	ld bc, iz

DSPCfg_WriteParamDelta_CallWrite:
	calr DSPCfg_WriteParamFull
	jr DSPCfg_WriteParamDelta_Return

DSPCfg_WriteParamDelta_BadType:
	ldw hl, 0xFFFF

DSPCfg_WriteParamDelta_Return:
	popw iz
	lda xsp, (xsp + 16)
	ret

DSPCfg_WriteAllSlots_Direct:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), wa
	ld xwa, (xsp + 16)
	calr DSPCfg_GetParamCount
	ld wa, hl
	ld bc, (xsp + 20)
	calr DSPCfg_ValidateSlotForWrite
	ld (xsp + 4), hl
	cpw (xsp + 4), 0x0
	jrl z, DSPCfg_WriteAllSlots_Direct_Return
	lds wa, 1
	ld xbc, (xsp + 16)
	calr DSPCfg_StoreByte_ReturnZero
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	pushw 0xFF
	lds bc, 0
	lds de, 1
	call AssswbWr
	ld xwa, (xsp + 16)
	calr DSPCfg_GetParamCount
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	sla wa, 2
	lda_24 xbc, 0xee61d4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 8), xwa
	lds iz, 0
	jr DSPCfg_WriteAllSlots_Direct_CheckCount

DSPCfg_WriteAllSlots_Direct_Loop:
	ld wa, iz
	ld xbc, (xsp + 8)
	calr DSPCfg_ReadViaTableLookup
	ldfr_werp HL, 0xFA
	lda xwa, (xsp + 14)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	ld wa, iz
	ldto_werp BC, 0xFA
	ld xde, (xsp + 24)
	calr DSPCfg_WriteViaTableLookup
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 14)
	inc 1, c
	extz bc
	ldto_werp DE, 0xFA
	ldb d, 0x0
	extz de
	ld l, (xsp + 12)
	extz hl
	pushw hl
	call AssswbWr
	inc 1, iz

DSPCfg_WriteAllSlots_Direct_CheckCount:
	ld wa, (xsp + 6)
	calr DSPCfg_GetSlotCount
	cp iz, hl
	jr c, DSPCfg_WriteAllSlots_Direct_Loop

DSPCfg_WriteAllSlots_Direct_Return:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 18)
	ret

DSPCfg_WriteAllSlots_Clamped:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 16), xbc
	ld (xsp + 20), wa
	ldi_werp 0xFA, 0
	ld xwa, (xsp + 16)
	calr DSPCfg_GetParamCount
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	sla wa, 2
	lda_24 xbc, 0xee61d4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld (xsp + 6), xwa
	lds iz, 0
	jr DSPCfg_WriteAllSlots_Clamped_CheckCount

DSPCfg_WriteAllSlots_Clamped_Loop:
	ld wa, iz
	ld xbc, (xsp + 16)
	calr DSPCfg_ReadViaTableLookup
	ld (xsp + 14), hl
	ld wa, (xsp + 4)
	lda xde, (xsp + 14)
	ld bc, iz
	calr DSPCfg_ClampAndExtract
	cps hl, 0
	jr z, DSPCfg_WriteAllSlots_Clamped_Next
	ld wa, iz
	ld xbc, (xsp + 6)
	calr DSPCfg_ReadViaTableLookup
	ld (xsp + 14), hl
	lda xwa, (xsp + 12)
	push xwa
	lda xwa, (xsp + 14)
	push xwa
	ld bc, (xsp + 22)
	ld wa, iz
	ld xde, (xsp + 24)
	calr DSPCfg_WriteViaTableLookup
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, 0xEE636C
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 12)
	inc 1, c
	extz bc
	ld de, (xsp + 14)
	ldb d, 0x0
	extz de
	ld l, (xsp + 10)
	extz hl
	pushw hl
	call AssswbWr
	ldi_erpw 0xFA, 0xFF, 0xFF

DSPCfg_WriteAllSlots_Clamped_Next:
	inc 1, iz

DSPCfg_WriteAllSlots_Clamped_CheckCount:
	ld wa, (xsp + 4)
	calr DSPCfg_GetSlotCount
	cp iz, hl
	jr c, DSPCfg_WriteAllSlots_Clamped_Loop
	ldto_werp HL, 0xFA
	pop xiz
	lda xsp, (xsp + 18)
	ret

DSPCfg_WriteAllSlots_Combined:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xbc
	ld iz, wa
	ld wa, iz
	ld xbc, (xsp + 4)
	calr DSPCfg_WriteAllSlots_Direct
	ldfr_werp HL, 0xFA
	ld wa, iz
	ld xbc, (xsp + 4)
	calr DSPCfg_WriteAllSlots_Clamped
	ldto_werp WA, 0xFA
	add wa, hl
	ldi_werp 0xFA, 0
	cps wa, 0
	jr z, DSPCfg_WriteAllSlots_Combined_Done
	ldi_erpw 0xFA, 0xFF, 0xFF

DSPCfg_WriteAllSlots_Combined_Done:
	ldto_werp HL, 0xFA
	pop xiz
	inc 4, xsp
	ret

DSPCfg_Data_ParamDispatch:
	lda	xsp, (xsp-14)
	push	xiz
	ld	(xsp+14), xde
	ld	xde, xbc
	ld	xbc, xwa
	ld	qiz, 0
	.byte 0xbf, 0x08, 0x02, 0x00, 0x00
	ld	l, (xbc+1)
	extz	hl
	ld	a, (xbc)
	extz	wa
	ld	iz, wa
	.byte 0xde, 0xee, 0x08
	add	iz, hl
	ld	xwa, (xsp+34)
	ld	a, (xwa)
	ld	(xsp+4), a
	ld	a, (xde+2)
	ld	(xsp+6), a
	lda	xwa, (xsp+12)
	cp	(xsp+6), 118
	jrl	z, 159
	ld	hl, iz
	cp	(xsp+6), 112
	jr	z, 70
	cp	(xsp+6), 103
	jr	z, 59
	.byte 0x8f, 0x06
	.ascii "?df5Å"
	.byte 0x27, 0xdb, 0x13, 0xd7, 0xfa, 0xa9, 0x25, 0xff
	.byte 0xaf, 0x0e, 0x20, 0xd7, 0xfa, 0x89, 0xb0, 0x51
	.byte 0xaf, 0x22, 0x20, 0x8f, 0x04, 0x23, 0xb0, 0x43
	.byte 0xaf, 0x1e, 0x20, 0xb0, 0x45, 0xaf, 0x1a, 0x21
	.byte 0x8f, 0x06, 0x21, 0xb1, 0x41, 0xaf, 0x16, 0x21
	.byte 0x9f, 0x08, 0x20, 0xb1, 0x41, 0x5e, 0xbf, 0x0e
	.byte 0x37, 0x0f, 0x10, 0x00, 0xd7, 0xfa, 0xaa, 0x68
	.byte 0xcd, 0xbf, 0x08, 0x31, 0x1e, 0x96, 0xf2, 0x9f
	.byte 0x0c, 0x20, 0xd8, 0xcf, 0x20, 0x00, 0x66, 0x31
	.byte 0xd8, 0xcf, 0x10, 0x00, 0x66, 0x1c, 0xde, 0x88
	.byte 0xd8, 0xef, 0x06, 0xd8, 0xcc, 0x1f, 0x00, 0xd8
	.byte 0x8b, 0x25, 0x07, 0x9f, 0x08, 0x3f, 0x01, 0x00
	.byte 0x6e, 0xa6, 0xd7, 0xfa, 0xa9, 0x8f, 0x04, 0x61
	.byte 0x68, 0x9e, 0xde, 0x88, 0xd8, 0xef, 0x0b, 0xd8
	.byte 0xcc, 0x1f, 0x00, 0xd8, 0x8b, 0x25, 0xf8, 0x68
	.byte 0x8f, 0xde, 0x8b, 0xdb, 0xcc, 0x3f, 0x00, 0xd7
	.byte 0xfa, 0xa9, 0x8f, 0x04
	.ascii "a%?x~"
	.byte 0xff, 0xbf, 0x0a, 0x31, 0x1e, 0x1e, 0xf2
	.byte 0x9f, 0x0c, 0x20, 0xd8, 0xcf, 0x10, 0x00, 0x66
	.byte 0x10, 0xde, 0x88, 0xd8, 0xef, 0x06, 0xd8, 0xcc
	.byte 0x1f, 0x00, 0xd8, 0x8b, 0x25, 0x07, 0x78, 0x5f
	.byte 0xff, 0x9f, 0x0a, 0x3f, 0x02, 0x00, 0x6e, 0xc9
	.byte 0xde, 0x88, 0xd8, 0xef, 0x08, 0xd8, 0xcc, 0x3f
	.byte 0x00, 0xd8, 0x8b, 0xd7, 0xfa, 0xa9, 0x68, 0xc5
	.byte 0xbf, 0xe8, 0x37, 0x2e, 0xbf, 0x10, 0x45, 0xbf
	.byte 0x12, 0x61, 0xbf, 0x16, 0x60, 0xbf, 0x0e, 0x02
	.byte 0x00, 0x00, 0x36, 0xff, 0xff, 0xbf, 0x0a, 0x00
	.byte 0x00, 0xbf, 0x08, 0x00, 0x7a, 0xaf, 0x1e, 0x20
	.byte 0x80, 0x21, 0xbf, 0x02, 0x41, 0xde, 0x61, 0x9f
	.byte 0x0e, 0x20, 0x8f, 0x0a, 0x89, 0x8f, 0x08, 0x21
	.byte 0xbf, 0x04, 0x41, 0xbf, 0x0e, 0x32, 0xbf, 0x0a
	.byte 0x30, 0x38, 0xbf, 0x10, 0x30, 0x38, 0xbf, 0x10
	.byte 0x30, 0x38, 0xbf, 0x12, 0x30, 0x38, 0xaf, 0x26
	.byte 0x20, 0xaf, 0x22, 0x21, 0x1e, 0xa1, 0xfe, 0xd9
	.byte 0xa8, 0x9f, 0x0e, 0x3f, 0x00, 0x00, 0x63, 0x0c
	.byte 0xe8, 0xa9, 0xaf, 0x16, 0x88, 0xd9, 0x61, 0x9f
	.byte 0x0e, 0xf1, 0x67, 0xf4, 0xaf, 0x12, 0x20, 0x1e
	.byte 0xf9, 0xf2, 0xbf, 0x12, 0x63, 0x8f, 0x0a, 0x21
	.byte 0x8f, 0x10, 0xf1, 0x6b, 0x10, 0x8f, 0x0a, 0x21
	.byte 0x8f, 0x10, 0xf1, 0x6e, 0xa8, 0x8f, 0x02, 0x21
	.byte 0x8f, 0x0c, 0xc1, 0x66, 0xa0, 0x8f, 0x0a, 0x21
	.byte 0x8f, 0x10, 0xf1, 0x63, 0x14, 0x8f, 0x04, 0x3f
	.byte 0x70, 0x6e, 0x04, 0xde, 0x6b, 0x68, 0x02, 0xde
	.byte 0x69, 0x8f, 0x06, 0x3f, 0x01, 0x6e, 0x02, 0xde
	.byte 0x61, 0x8f, 0x0c, 0x21, 0xc9, 0x06, 0x8f, 0x02
	.byte 0xc1, 0xc9, 0x8b, 0xaf, 0x1e, 0x20, 0xb0, 0x43
	.byte 0xde, 0x8b, 0x4e, 0xbf, 0x18, 0x37, 0x0f, 0x04
	.byte 0x00, 0xbf, 0xf6, 0x37, 0x3e, 0xbf, 0x0a, 0x45
	.byte 0xbf, 0x0c, 0x43, 0xbf, 0x04, 0x02, 0x00, 0x00
	.byte 0xd8, 0x12, 0xd8, 0xca, 0x61, 0x00, 0xd8, 0xd8
	.byte 0x61, 0x4e, 0xd8, 0xdd, 0x6a, 0x4a, 0xd8, 0x80
	.byte 0xf2, 0x84, 0x63, 0xee, 0x34, 0xd3, 0x07, 0xf0
	.byte 0xe0, 0x20, 0xf2, 0xd3, 0xce, 0xfd, 0x34, 0xf3
	.byte 0x07, 0xf0, 0xe0, 0xd8, 0x46, 0x00, 0x49, 0x00
	.byte 0x00, 0xd8, 0xa8, 0x68, 0x30, 0x46, 0x00, 0x4a
	.byte 0x00, 0x00, 0x68, 0x05, 0x46, 0x00, 0x4b, 0x00
	.byte 0x00, 0xd8, 0xa9, 0x68, 0x20, 0x46, 0x00, 0x4c
	.byte 0x00, 0x00, 0xd8, 0xac, 0x68, 0x17, 0x46, 0x00
	.byte 0x4d, 0x00, 0x00, 0xd8, 0xaa, 0x68, 0x0e, 0x46
	.byte 0x00, 0x4e, 0x00, 0x00, 0xd8, 0xab, 0x68, 0x05
	.byte 0xbf, 0x04, 0x02, 0xff, 0xff, 0x8f, 0x0c, 0x3f
	.byte 0x01, 0x67, 0x4b, 0x8f, 0x0c, 0x3f, 0x11, 0x6f
	.byte 0x45, 0x1e, 0xab, 0xf0, 0xbf, 0x06, 0x63, 0xaf
	.byte 0x06, 0x20, 0x1e, 0x3b, 0xf4, 0xeb, 0x12, 0xeb
	.byte 0xee, 0x02, 0x41, 0xf6, 0x75, 0xee, 0x00, 0xeb
	.byte 0x81, 0xa1, 0x21, 0xe8, 0xa9, 0xaf, 0x06, 0x88
	.byte 0x8f, 0x0c, 0x25, 0xcd, 0x69, 0xda, 0x12, 0xbf
	.byte 0x0a, 0x30, 0x38, 0xaf, 0x0a, 0x20, 0x1e, 0x9f
	.byte 0xfe, 0xdb, 0xcf, 0xff, 0xff, 0x6e, 0x07, 0xbf
	.byte 0x04, 0x02, 0xff, 0xff, 0x68, 0x08, 0xdb, 0xc8
	.byte 0x10, 0x00, 0xeb, 0x13, 0xeb, 0x86, 0xaf, 0x12
	.byte 0x20, 0xb0, 0x66, 0x9f, 0x04, 0x23, 0x5e, 0xbf
	.byte 0x0a, 0x37, 0x0f, 0x04, 0x00

DSPCfg_CheckParamTableEntry:
	lds hl, 0
	cp wa, 0x63
	jr ugt, DSPCfg_CheckParamTableEntry_NotFound
	extz xwa
	sll xwa, 2
	ld xbc, 0xEE75F6
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	ret nz

DSPCfg_CheckParamTableEntry_NotFound:
	ldw hl, 0xFFFF
	ret

DSPCfg_ReadFieldSimple:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xde
	ld xde, xbc
	ld xbc, xwa
	ldi_werp 0xFA, 0
	ld l, (xbc + 1)
	extz hl
	ld a, (xbc)
	extz wa
	ld iz, wa
	sll iz, 8
	add iz, hl
	ld xwa, (xsp + 18)
	ld wa, (xwa)
	ld (xsp + 4), wa
	ld a, (xde + 2)
	cp a, 0x70
	jr z, DSPCfg_ReadFieldSimple_Type70
	cp a, 0x67
	jr z, DSPCfg_ReadFieldSimple_Type64_67
	cp a, 0x64
	jr z, DSPCfg_ReadFieldSimple_Type64_67
	ld l, (xbc)
	exts hl
	ldi_werp 0xFA, 1

DSPCfg_ReadFieldSimple_StoreReturn:
	ld xwa, (xsp + 10)
	ldto_werp BC, 0xFA
	ld (xwa), bc
	ld xwa, (xsp + 18)
	ld bc, (xsp + 4)
	ld (xwa), bc
	pop xiz
	lda xsp, (xsp + 10)
	retd 0x4

DSPCfg_ReadFieldSimple_Type64_67:
	ld hl, iz
	jr DSPCfg_ReadFieldSimple_SetWidth2

DSPCfg_ReadFieldSimple_Type70:
	lda xwa, (xsp + 8)
	lda xbc, (xsp + 6)
	calr DSPCfg_ExtractFieldSingle
	ld wa, (xsp + 8)
	ld hl, iz
	cp wa, 0x20
	jr z, DSPCfg_ReadFieldSimple_SetWidth2
	cp wa, 0x10
	jr z, DSPCfg_ReadFieldSimple_StoreReturn
	cpw (xsp + 6), 0x1
	jr nz, DSPCfg_ReadFieldSimple_StoreReturn

DSPCfg_ReadFieldSimple_SetWidth2:
	ldi_werp 0xFA, 2
	jr DSPCfg_ReadFieldSimple_StoreReturn

DSPCfg_ApplyParamStruct:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xwa
	ld xiz, (xsp + 22)
	ld a, (xiz)
	extz wa
	ld (xsp + 4), wa
	lda_24 xbc, 0xee5fe0
	ld wa, (xsp + 4)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	calr DSPCfg_CheckParamTableEntry
	ld (xsp + 8), hl
	cpw (xsp + 8), 0x0
	jrl nz, DSPCfg_ApplyParamStruct_Return
	cpw (xsp + 4), 0x10
	jr lt, DSPCfg_ApplyParamStruct_Normal
	cpw (xsp + 4), 0x1B
	jr gt, DSPCfg_ApplyParamStruct_Normal
	lda xde, (xiz + 5)
	ld a, (xde)
	ld (xiz + 6), a
	lda xbc, (xiz + 4)
	ld a, (xbc)
	ld (xde), a
	lda xde, (xiz + 3)
	ld a, (xde)
	ld (xbc), a
	lda xbc, (xiz + 2)
	ld a, (xbc)
	ld (xde), a
	ld (xbc), 0x0
	jrl DSPCfg_ApplyParamStruct_Return

DSPCfg_ApplyParamStruct_Normal:
	ldw (xsp + 20), 0x0
	ldw (xsp + 18), 0x0
	ld a, (xiz + 21)
	extz wa
	ld (xsp + 10), wa
	ld xwa, (xsp + 22)
	lda xiz, (xwa + 1)
	ld wa, (xsp + 4)
	exts xwa
	sll xwa, 2
	ld xbc, 0xEE75F6
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 14), xwa
	ldw (xsp + 12), 0x0
	ld wa, (xsp + 6)
	cps wa, 0
	jr ule, DSPCfg_ApplyParamStruct_CheckSpecial

DSPCfg_ApplyParamStruct_ReadLoop:
	ld wa, (xsp + 20)
	add (xsp + 18), wa
	lda xde, (xsp + 20)
	lda xwa, (xsp + 18)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 18)
	calr DSPCfg_ReadFieldSimple
	lds wa, 0
	cpw (xsp + 20), 0x0
	jr ule, DSPCfg_ApplyParamStruct_PackNext

DSPCfg_ApplyParamStruct_AdvancePtr:
	inc 1, xiz
	inc 1, wa
	cp wa, (xsp + 20)
	jr c, DSPCfg_ApplyParamStruct_AdvancePtr

DSPCfg_ApplyParamStruct_PackNext:
	ld xwa, (xsp + 14)
	calr DSPCfg_PackAddress
	ld (xsp + 14), xhl
	incm 1, (xsp + 12)
	ld wa, (xsp + 6)
	cp (xsp + 12), wa
	jr c, DSPCfg_ApplyParamStruct_ReadLoop

DSPCfg_ApplyParamStruct_CheckSpecial:
	ld de, (xsp + 4)
	ld bc, (xsp + 10)
	cpw (xsp + 4), 0x63
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x62
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x61
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x60
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x35
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0xF
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x23
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x22
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x21
	jr z, DSPCfg_ApplyParamStruct_Offset2
	cp de, 0x20
	jr nz, DSPCfg_ApplyParamStruct_Offset1

DSPCfg_ApplyParamStruct_Offset2:
	lds32 xwa, 2
	jr DSPCfg_ApplyParamStruct_WriteLoop

DSPCfg_ApplyParamStruct_Offset1:
	lds32 xwa, 1

DSPCfg_ApplyParamStruct_WriteLoop:
	ld xde, xiz
	sub xde, xwa
	ld (xde), c
	ldw (xsp + 20), 0x0
	ldw (xsp + 18), 0x0
	ld xwa, (xsp + 22)
	lda xiz, (xwa + 1)
	ld wa, (xsp + 4)
	exts xwa
	sll xwa, 2
	ld xbc, 0xEE75F6
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 14), xwa
	ldw (xsp + 12), 0x0
	ld wa, (xsp + 6)
	cps wa, 0
	jr ule, DSPCfg_ApplyParamStruct_Return

DSPCfg_ApplyParamStruct_WriteReadLoop:
	ld wa, (xsp + 20)
	add (xsp + 18), wa
	lda xde, (xsp + 20)
	lda xwa, (xsp + 18)
	push xwa
	ld xwa, xiz
	ld xbc, (xsp + 18)
	calr DSPCfg_ReadFieldSimple
	cpw (xsp + 20), 0x2
	jr nz, DSPCfg_ApplyParamStruct_WriteSkip2Byte
	ld wa, hl
	ldb w, 0x0
	ld (xiz), a
	sra hl, 8
	ldb h, 0x0
	ld (xiz + 1), l

DSPCfg_ApplyParamStruct_WriteSkip2Byte:
	lds wa, 0
	cpw (xsp + 20), 0x0
	jr ule, DSPCfg_ApplyParamStruct_WritePackNext

DSPCfg_ApplyParamStruct_WriteAdvancePtr:
	inc 1, xiz
	inc 1, wa
	cp wa, (xsp + 20)
	jr c, DSPCfg_ApplyParamStruct_WriteAdvancePtr

DSPCfg_ApplyParamStruct_WritePackNext:
	ld xwa, (xsp + 14)
	calr DSPCfg_PackAddress
	ld (xsp + 14), xhl
	incm 1, (xsp + 12)
	ld wa, (xsp + 6)
	cp (xsp + 12), wa
	jr c, DSPCfg_ApplyParamStruct_WriteReadLoop

DSPCfg_ApplyParamStruct_Return:
	ld hl, (xsp + 8)
	pop xiz
	lda xsp, (xsp + 22)
	ret

DSPCfg_ApplyParamStructFull:
	lda xsp, (xsp - 68)
	push xiz
	ldw (xsp + 4), 0x0
	ld_spib E, 0xE0
	extz de
	ld (xsp + 30), de
	lda xbc, (xwa - 1)
	ld (xsp + 56), xbc
	lda xbc, (xwa + 13)
	ld (xsp + 16), xbc
	lda xbc, (xwa + 2)
	ld (xsp + 68), xbc
	lda xbc, (xwa + 6)
	ld (xsp + 52), xbc
	lda xbc, (xwa + 10)
	ld (xsp + 36), xbc
	lda xbc, (xwa + 12)
	ld (xsp + 60), xbc
	cp de, 0x51
	jrl z, DSPCfg_EventType51
	lda xbc, (xwa + 3)
	ld (xsp + 64), xbc
	lda xbc, (xwa + 7)
	ld (xsp + 48), xbc
	cp de, 0x50
	jrl z, DSPCfg_EventType50
	lda xbc, (xwa + 8)
	ld (xsp + 44), xbc
	cp de, 0x46
	jrl z, DSPCfg_EventType46
	lda xbc, (xwa + 14)
	ld (xsp + 12), xbc
	lda xbc, (xwa + 15)
	ld (xsp + 8), xbc
	cp de, 0x44
	jrl z, DSPCfg_EventType44
	lda xbc, (xwa + 11)
	ld (xsp + 32), xbc
	cp de, 0x42
	jrl z, DSPCfg_EventType42
	lda xbc, (xwa + 9)
	ld (xsp + 40), xbc
	cp de, 0x40
	jrl z, DSPCfg_EventType40
	cp de, 0x36
	jrl z, DSPCfg_EventType36
	cp de, 0x35
	jrl z, DSPCfg_EventType35
	cp de, 0x34
	jrl z, DSPCfg_EventType34
	lda xbc, (xwa + 4)
	ld (xsp + 60), xbc
	lda xbc, (xwa + 5)
	ld (xsp + 56), xbc
	cp de, 0x32
	jrl z, DSPCfg_EventType32
	cp de, 0x30
	jrl z, DSPCfg_EventType30
	cp de, 0x1B
	jr gt, DSPCfg_ApplyParamStructFull_RangeCheck
	cp de, 0x10
	jrl ge, DSPCfg_EventType10to1B

DSPCfg_ApplyParamStructFull_RangeCheck:
	ld bc, (xsp + 30)
	dec 1, bc
	cps bc, 0
	jr lt, AssSwb_SwapEntriesAndDispatch
	cp bc, 0x8
	jr le, DspConfig_EventDispatch
	sub bc, 0x12
	cp bc, 0x9
	jr lt, AssSwb_SwapEntriesAndDispatch
	cp bc, 0x14
	jr gt, AssSwb_SwapEntriesAndDispatch

; DSP config event dispatch
DspConfig_EventDispatch:
	add bc, bc
	lda_24 xix, 0xee6390
	ld_sriw3 BC, 0x07, 0xF0, 0xE4
	lda_24 xix, 0xfdd2b3
	jp_dri 8, 0x07, 0xF0, 0xE4

AssSwb_SwapEntriesAndDispatch:
	ldw (xsp + 4), 0xFFFF
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld l, (xix)
	ld xbc, (xsp + 68)
	ld e, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), e
	ld (xix), c
	ld xwa, (xsp + 68)
	ld c, (xsp + 6)
	ld (xwa), c
	ld (xiy), l
	ld xwa, (xsp + 60)
	ld (xwa), 0x0
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld l, (xix)
	ld xbc, (xsp + 68)
	ld e, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), e
	ld (xix), c
	ld xwa, (xsp + 68)
	ld c, (xsp + 6)
	ld (xwa), c
	ld (xiy), l
	ld xwa, (xsp + 60)
	ld (xwa), 0x1
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xhl, (xwa + 1)
	ld e, (xhl)
	ld xix, (xsp + 68)
	ld c, (xix)
	ld (xwa), 0x1E
	ld (xhl), 0x56
	ld (xix), 0x5
	ld xwa, (xsp + 64)
	ld (xwa), 0x0
	ld xwa, (xsp + 60)
	ld (xwa), c
	ld xwa, (xsp + 56)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 52)
	ld (xwa), e
	ld xwa, (xsp + 48)
	ld (xwa), 0x1
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xhl, (xwa + 1)
	ld e, (xhl)
	ld xbc, (xsp + 68)
	ld d, (xbc)
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 60)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	ld xbc, (xsp + 56)
	ld c, (xbc)
	ldfr_berp C, 0xF0
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xF4
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xF8
	ld (xwa), d
	ldto_berp A, 0xEA
	ld (xhl), a
	ld xbc, (xsp + 68)
	ldto_berp A, 0xEB
	ld (xbc), a
	ld xbc, (xsp + 64)
	ldto_berp A, 0xF0
	ld (xbc), a
	ld xbc, (xsp + 60)
	ldto_berp A, 0xF4
	ld (xbc), a
	ld xbc, (xsp + 56)
	ldto_berp A, 0xF8
	ld (xbc), a
	ld xwa, (xsp + 52)
	ld (xwa), 0x5B
	ld xwa, (xsp + 48)
	ld (xwa), 0x98
	ld xwa, (xsp + 44)
	ld (xwa), 0x5C
	ld xwa, (xsp + 40)
	ld (xwa), 0x58
	ld xwa, (xsp + 36)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 32)
	ld (xwa), e
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld l, (xix)
	ld xbc, (xsp + 68)
	ld e, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), e
	ld (xix), c
	ld xwa, (xsp + 68)
	ld (xwa), 0x0
	ld c, (xsp + 6)
	ld (xiy), c
	ld xwa, (xsp + 60)
	ld (xwa), l
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 56), xbc
	ld c, (xbc)
	ld (xsp + 48), c
	ld xbc, (xsp + 68)
	ld (xsp + 52), xbc
	ld e, (xbc)
	ld xbc, (xsp + 64)
	ld (xsp + 68), xbc
	ld c, (xbc)
	ld (xsp + 50), c
	ld xbc, (xsp + 60)
	ld (xsp + 64), xbc
	ld c, (xbc)
	ld (xsp + 62), c
	mul e, 0xC
	extz de
	div e, 0x5
	ldb c, 0x63
	cp e, 0x63
	jr ugt, DSPCfg_EventType36_ClampResult
	ld c, e

DSPCfg_EventType36_ClampResult:
	ld (xwa), c
	ld xde, (xsp + 56)
	ld c, (xsp + 50)
	ld (xde), c
	ld xbc, (xsp + 52)
	ld (xbc), 0x3C
	ld xde, (xsp + 68)
	ld c, (xsp + 62)
	ld (xde), c
	ld xbc, (xsp + 64)
	ld (xbc), 0x0
	ld c, (xsp + 6)
	ld (xwa + 5), c
	ld c, (xsp + 48)
	ld (xwa + 6), c
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld e, (xix)
	ld xbc, (xsp + 68)
	ld d, (xbc)
	ld xbc, (xsp + 64)
	ld l, (xbc)
	ld xiy, (xsp + 60)
	ld c, (xiy)
	ld (xwa), 0x50
	ld (xix), d
	ld xwa, (xsp + 68)
	ld (xwa), l
	ld xwa, (xsp + 64)
	ld (xwa), c
	ld (xiy), 0x5A
	ld xwa, (xsp + 56)
	ld (xwa), 0x0
	ld xwa, (xsp + 52)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 48)
	ld (xwa), e
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld e, (xix)
	ld xbc, (xsp + 68)
	ld d, (xbc)
	ld xbc, (xsp + 64)
	ld l, (xbc)
	ld xiy, (xsp + 60)
	ld c, (xiy)
	ld (xwa), 0x50
	ld (xix), d
	ld xwa, (xsp + 68)
	ld (xwa), l
	ld xwa, (xsp + 64)
	ld (xwa), c
	ld (xiy), 0x5A
	ld xwa, (xsp + 56)
	ld (xwa), 0x0
	ld xwa, (xsp + 52)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 48)
	ld (xwa), e
	jrl DSPCfg_Epilogue

DSPCfg_EventType30:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld e, (xix)
	ld xbc, (xsp + 68)
	ld l, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), l
	ld (xix), c
	ld xwa, (xsp + 68)
	ld (xwa), 0x5A
	ld (xiy), 0x0
	ld xwa, (xsp + 60)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 56)
	ld (xwa), e
	jrl DSPCfg_Epilogue

DSPCfg_EventType32:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld e, (xix)
	ld xbc, (xsp + 68)
	ld l, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), l
	ld (xix), c
	ld xwa, (xsp + 68)
	ld (xwa), 0x5A
	ld (xiy), 0x0
	ld xwa, (xsp + 60)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 56)
	ld (xwa), e
	jrl DSPCfg_Epilogue

DSPCfg_EventType34:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld l, (xbc)
	ld (xwa), 0x2
	ld (xbc), 0x0
	ld xbc, (xsp + 68)
	ld (xbc), 0x63
	ld xde, (xsp + 64)
	ld c, (xsp + 6)
	ld (xde), c
	jrl DSPCfg_EventType36_StoreTail

DSPCfg_EventType35:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld c, (xix)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 68)
	ld h, (xbc)
	ld xbc, (xsp + 64)
	ld d, (xbc)
	lda xiy, (xwa + 4)
	ld l, (xiy)
	lda xiz, (xwa + 5)
	ld e, (xiz)
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	ld xbc, (xsp + 44)
	ld b, (xbc)
	ldto_berp C, 0xEB
	ld (xwa), c
	ld (xix), b
	ld xwa, (xsp + 68)
	ld (xwa), 0x40
	ld xwa, (xsp + 64)
	ld (xwa), d
	ld (xiy), l
	ld (xiz), 0xA
	ld xwa, (xsp + 52)
	ld (xwa), 0xA
	ld xwa, (xsp + 48)
	ld (xwa), 0x3C
	ld xwa, (xsp + 44)
	ld (xwa), e
	ld xbc, (xsp + 40)
	ldto_berp A, 0xEE
	ld (xbc), a
	ld xwa, (xsp + 36)
	ld (xwa), 0x48
	ld xwa, (xsp + 32)
	ld (xwa), 0x4F
	ld xwa, (xsp + 60)
	ldto_berp C, 0xEA
	ld (xwa), c
	ld xwa, (xsp + 16)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 12)
	ld (xwa), h
	ld xwa, (xsp + 8)
	ld (xwa), 0x0
	jrl DSPCfg_Epilogue

DSPCfg_EventType36:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xde, (xwa + 1)
	ld l, (xde)
	ld xix, (xsp + 68)
	ld c, (xix)
	ld (xwa), c
	ld (xde), 0x5A
	ld (xix), 0x0
	ld xde, (xsp + 64)
	ld c, (xsp + 6)
	ld (xde), c

DSPCfg_EventType36_StoreTail:
	ld (xwa + 4), l
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld l, (xix)
	ld xbc, (xsp + 68)
	ld e, (xbc)
	ld xiy, (xsp + 64)
	ld c, (xiy)
	ld (xwa), e
	ld (xix), c
	ld xwa, (xsp + 68)
	ld (xwa), 0x0
	ld c, (xsp + 6)
	ld (xiy), c
	ld xwa, (xsp + 60)
	ld (xwa), l
	jrl DSPCfg_Epilogue
	ld c, (xwa)
	ld (xsp + 6), c
	lda xhl, (xwa + 1)
	ld e, (xhl)
	ld xbc, (xsp + 68)
	ld d, (xbc)
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 60)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	ld xbc, (xsp + 56)
	ld c, (xbc)
	ldfr_berp C, 0xF0
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xF4
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xF8
	ld (xwa), d
	ldto_berp A, 0xEA
	ld (xhl), a
	ld xbc, (xsp + 68)
	ldto_berp A, 0xEB
	ld (xbc), a
	ld xbc, (xsp + 64)
	ldto_berp A, 0xF0
	ld (xbc), a
	ld xbc, (xsp + 60)
	ldto_berp A, 0xF4
	ld (xbc), a
	ld xbc, (xsp + 56)
	ldto_berp A, 0xF8
	ld (xbc), a
	ld xwa, (xsp + 52)
	ld (xwa), 0x12
	ld xwa, (xsp + 48)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 44)
	ld (xwa), e
	jrl DSPCfg_Epilogue

DSPCfg_EventType40:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 56), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 68)
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xE6
	lda xix, (xwa + 4)
	ld h, (xix)
	lda xiy, (xwa + 5)
	ld d, (xiy)
	ld xiz, (xsp + 52)
	ld b, (xiz)
	ld xiz, (xsp + 48)
	ld l, (xiz)
	ld xiz, (xsp + 44)
	ld e, (xiz)
	ld xiz, (xsp + 40)
	ld c, (xiz)
	ldfr_berp C, 0xE7
	ld xiz, (xsp + 36)
	ld c, (xiz)
	ldfr_berp C, 0xEB
	ld xiz, (xsp + 32)
	ld c, (xiz)
	ldfr_berp C, 0xEF
	ldto_berp C, 0xEE
	ld (xwa), c
	ld xiz, (xsp + 56)
	ldto_berp A, 0xE6
	ld (xiz), a
	ld xiz, (xsp + 68)
	ld (xiz), h
	ld xiz, (xsp + 64)
	ld (xiz), d
	ld (xix), b
	ld (xiy), l
	ld xwa, (xsp + 52)
	ld (xwa), e
	ld xwa, (xsp + 48)
	ldto_berp C, 0xE7
	ld (xwa), c
	ld xwa, (xsp + 44)
	ldto_berp C, 0xEB
	ld (xwa), c
	ld xwa, (xsp + 40)
	ldto_berp C, 0xEF
	ld (xwa), c
	ld xwa, (xsp + 36)
	ld (xwa), 0x0
	ld xwa, (xsp + 32)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 60)
	ldto_berp C, 0xEA
	ld (xwa), c
	jrl DSPCfg_Epilogue

DSPCfg_EventType42:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 40), xbc
	ld c, (xbc)
	ld (xsp + 58), c
	ld xbc, (xsp + 68)
	ld e, (xbc)
	ld xbc, (xsp + 64)
	ld l, (xbc)
	lda xbc, (xwa + 4)
	ld (xsp + 28), xbc
	ld d, (xbc)
	lda xbc, (xwa + 5)
	ld (xsp + 24), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	ld xbc, (xsp + 44)
	ld h, (xbc)
	lda xbc, (xwa + 9)
	ld (xsp + 20), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEF
	ld xbc, (xsp + 36)
	ld c, (xbc)
	ldfr_berp C, 0xF0
	ld xbc, (xsp + 32)
	ld b, (xbc)
	ld xiy, (xsp + 60)
	ld c, (xiy)
	ldfr_berp C, 0xE6
	ld (xwa), e
	ld xwa, (xsp + 40)
	ld (xwa), l
	ld xiy, (xsp + 68)
	ld (xiy), d
	ld xiy, (xsp + 64)
	ldto_berp A, 0xEA
	ld (xiy), a
	ld xiy, (xsp + 28)
	ldto_berp A, 0xEE
	ld (xiy), a
	ldto_berp C, 0xEB
	ld xwa, (xsp + 24)
	ld (xwa), c
	ld xwa, (xsp + 52)
	ld (xwa), h
	ld xwa, (xsp + 48)
	ldto_berp C, 0xEF
	ld (xwa), c
	ld xwa, (xsp + 44)
	ld (xwa), 0x50
	ldto_berp C, 0xF0
	ld xwa, (xsp + 20)
	ld (xwa), c
	ld xwa, (xsp + 36)
	ld (xwa), b
	ld xwa, (xsp + 32)
	ldto_berp C, 0xE6
	ld (xwa), c
	ld xwa, (xsp + 60)
	ld (xwa), 0x5A
	ld xwa, (xsp + 16)
	ld (xwa), 0x0
	ld xwa, (xsp + 12)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 8)
	ld c, (xsp + 58)
	ld (xwa), c
	jrl DSPCfg_Epilogue

DSPCfg_EventType44:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 40), xbc
	ld c, (xbc)
	ld (xsp + 58), c
	ld xbc, (xsp + 68)
	ld c, (xbc)
	ldfr_berp C, 0xEA
	ld xbc, (xsp + 64)
	ld h, (xbc)
	lda xbc, (xwa + 4)
	ld (xsp + 32), xbc
	ld d, (xbc)
	lda xbc, (xwa + 5)
	ld (xsp + 28), xbc
	ld l, (xbc)
	ld xbc, (xsp + 52)
	ld e, (xbc)
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 44)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	lda xbc, (xwa + 9)
	ld (xsp + 24), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEF
	ld xbc, (xsp + 36)
	ld c, (xbc)
	ldfr_berp C, 0xF0
	lda xbc, (xwa + 11)
	ld (xsp + 20), xbc
	ld c, (xbc)
	ldfr_berp C, 0xF4
	ld xbc, (xsp + 60)
	ld b, (xbc)
	ldto_berp C, 0xEA
	ld (xwa), c
	ld xwa, (xsp + 40)
	ld (xwa), h
	ld xwa, (xsp + 68)
	ld (xwa), d
	ld xwa, (xsp + 64)
	ld (xwa), l
	ld xwa, (xsp + 32)
	ld (xwa), e
	ld xiz, (xsp + 28)
	ldto_berp A, 0xEE
	ld (xiz), a
	ld xiz, (xsp + 52)
	ldto_berp A, 0xEB
	ld (xiz), a
	ld xwa, (xsp + 48)
	ldto_berp C, 0xEF
	ld (xwa), c
	ld xwa, (xsp + 44)
	ld (xwa), 0x50
	ldto_berp C, 0xF0
	ld xwa, (xsp + 24)
	ld (xwa), c
	ld xwa, (xsp + 36)
	ldto_berp C, 0xF4
	ld (xwa), c
	ld xwa, (xsp + 20)
	ld (xwa), b
	ld xwa, (xsp + 60)
	ld (xwa), 0x5A
	ld xwa, (xsp + 16)
	ld (xwa), 0x0
	ld xwa, (xsp + 12)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 8)
	ld c, (xsp + 58)
	ld (xwa), c
	jrl DSPCfg_Epilogue

DSPCfg_EventType46:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 60), xbc
	ld e, (xbc)
	ld xbc, (xsp + 68)
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xEA
	lda xix, (xwa + 4)
	ld h, (xix)
	lda xiy, (xwa + 5)
	ld d, (xiy)
	ld xbc, (xsp + 52)
	ld l, (xbc)
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xEB
	ld xbc, (xsp + 44)
	ld c, (xbc)
	ldfr_berp C, 0xEF
	ld (xwa), 0x2
	ld xbc, (xsp + 60)
	ld (xbc), 0x0
	ld xbc, (xsp + 68)
	ld (xbc), 0x63
	ld xiz, (xsp + 64)
	ldto_berp C, 0xEE
	ld (xiz), c
	ldto_berp C, 0xEA
	ld (xix), c
	ld (xiy), h
	ld xbc, (xsp + 52)
	ld (xbc), d
	ld xbc, (xsp + 48)
	ld (xbc), l
	ld xix, (xsp + 44)
	ldto_berp C, 0xEB
	ld (xix), c
	ldto_berp C, 0xEF
	ld (xwa + 9), c
	ld xhl, (xsp + 36)
	ld c, (xsp + 6)
	ld (xhl), c
	ld (xwa + 11), e
	jrl DSPCfg_Epilogue

DSPCfg_EventType10to1B:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xix, (xwa + 1)
	ld h, (xix)
	ld xbc, (xsp + 68)
	ld d, (xbc)
	ld xbc, (xsp + 64)
	ld l, (xbc)
	ld xbc, (xsp + 60)
	ld e, (xbc)
	ld xiy, (xsp + 56)
	ld c, (xiy)
	ld (xwa), h
	ld (xix), d
	ld xwa, (xsp + 68)
	ld (xwa), l
	ld xwa, (xsp + 64)
	ld (xwa), e
	ld xwa, (xsp + 60)
	ld (xwa), c
	ld c, (xsp + 6)
	ld (xiy), c
	jrl DSPCfg_Epilogue

DSPCfg_EventType50:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 44), xbc
	ld c, (xbc)
	ldfr_berp C, 0xE7
	ld xde, (xsp + 68)
	ld c, (xde)
	ldfr_berp C, 0xEB
	ld xhl, (xsp + 64)
	ld c, (xhl)
	ldfr_berp C, 0xEE
	lda xix, (xwa + 4)
	ld (xsp + 40), xix
	ld c, (xix)
	ldfr_berp C, 0xEA
	lda xix, (xwa + 5)
	ld (xsp + 32), xix
	ld c, (xix)
	ldfr_berp C, 0xE6
	ld xix, (xsp + 52)
	ld h, (xix)
	ld xix, (xsp + 48)
	ld d, (xix)
	lda xix, (xwa + 8)
	ld b, (xix)
	lda xiy, (xwa + 9)
	ld l, (xiy)
	ld xiz, (xsp + 36)
	ld e, (xiz)
	ld xiz, (xsp + 56)
	ld (xiz), 0x62
	ld (xwa), 0x5B
	ld xiz, (xsp + 44)
	ld (xiz), 0x98
	ld xiz, (xsp + 68)
	ldto_berp C, 0xEB
	ld (xiz), c
	ld xiz, (xsp + 64)
	ldto_berp C, 0xEE
	ld (xiz), c
	ld xiz, (xsp + 40)
	ldto_berp C, 0xEA
	ld (xiz), c
	ld xiz, (xsp + 32)
	ldto_berp C, 0xE6
	ld (xiz), c
	ld xiz, (xsp + 52)
	ld (xiz), h
	ld xiz, (xsp + 48)
	ld (xiz), d
	ld (xix), b
	ld (xiy), l
	ld xhl, (xsp + 36)
	ld (xhl), e
	ld c, (xsp + 6)
	ld (xwa + 11), c
	ld xwa, (xsp + 60)
	ldto_berp C, 0xE7
	ld (xwa), c
	ld xwa, (xsp + 16)
	ld (xwa), 0x0
	jrl DSPCfg_Epilogue

DSPCfg_EventType51:
	ld c, (xwa)
	ld (xsp + 6), c
	lda xbc, (xwa + 1)
	ld (xsp + 64), xbc
	ld l, (xbc)
	ld xbc, (xsp + 68)
	ld c, (xbc)
	ldfr_berp C, 0xEA
	lda xbc, (xwa + 3)
	ld (xsp + 48), xbc
	ld h, (xbc)
	lda xbc, (xwa + 4)
	ld (xsp + 44), xbc
	ld d, (xbc)
	lda xbc, (xwa + 5)
	ld (xsp + 40), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEE
	ld xbc, (xsp + 52)
	ld e, (xbc)
	lda xbc, (xwa + 7)
	ld (xsp + 32), xbc
	ld c, (xbc)
	ldfr_berp C, 0xEB
	lda xbc, (xwa + 8)
	ld (xsp + 28), xbc
	ld c, (xbc)
	ldfr_berp C, 0xE7
	lda xix, (xwa + 9)
	ld c, (xix)
	ldfr_berp C, 0xE6
	ld xiy, (xsp + 36)
	ld b, (xiy)
	ld xiy, (xsp + 56)
	ld (xiy), 0x63
	ld (xwa), 0x5B
	ld xiy, (xsp + 64)
	ld (xiy), 0x98
	ld xiy, (xsp + 68)
	ldto_berp C, 0xEA
	ld (xiy), c
	ld xiy, (xsp + 48)
	ld (xiy), h
	ld xiy, (xsp + 44)
	ld (xiy), d
	ld xiy, (xsp + 40)
	ldto_berp C, 0xEE
	ld (xiy), c
	ld xiy, (xsp + 52)
	ld (xiy), e
	ld xiy, (xsp + 32)
	ldto_berp C, 0xEB
	ld (xiy), c
	ldto_berp C, 0xE7
	ld xde, (xsp + 28)
	ld (xde), c
	ldto_berp C, 0xE6
	ld (xix), c
	ld xde, (xsp + 36)
	ld (xde), b
	ld c, (xsp + 6)
	ld (xwa + 11), c
	ld xwa, (xsp + 60)
	ld (xwa), l
	ld xwa, (xsp + 16)
	ld (xwa), 0x1

DSPCfg_Epilogue:
	ld hl, (xsp + 4)
	pop xiz
	lda xsp, (xsp + 68)
	ret

DSPCfg_ReturnValueTable:
	ret
	ldw	hl, 256
	ret
	ldw	hl, 65535
	ret
	ldw	hl, 65535
	ret
	ldw	hl, 256
	ret
	ldw	hl, 256
	ret


	.include "boot/screen_group_dispatch.s"

AudioInit_ProcessModeChange:
	ldda16 xwa, 50580
	bit 2, wa
	ret z
	call Audio_CheckInitStatus
	anddi16 50580, 65531
	bitda 1, 64615
	jr z, AudioModeChange_Handler
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioModeChange_ClearVoiceFlags
	setda 2, 49662
	jr AudioModeChange_Handler

AudioModeChange_ClearVoiceFlags:
	stdi8 49662, 0

; Audio mode change handler
AudioModeChange_Handler:
	resda 3, 49662
	stdi8 49844, 255
	stdi8 49852, 255
	stdi8 49664, 255
	stdi8 49665, 255
	ordi16 50588, 257
	ldda8 a, 36148
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8cf4
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ld xbc, xhl
	lda_24 xwa, 0xfdecef
	cp xwa, xbc
	ret z
	lds wa, 0
	call (xhl)
	call AudioInit_DrumRoutingCheck
	call AudioInit_DrumSaveReturn
	call AudioInit_VoiceParamCtrl
	call AudioInit_ClearPartFlags_ByMode
	call AudioInit_DispatchChanges
	ret

Audio_CheckSubsystemReady:
	call Audio_CheckInitStatus
	ldda16 xwa, 50584
	and wa, 0x60
	call_24 z, 0xFDF5F5
	bitda 1, 64615
	jr z, AudioSubsystem_Callback
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioSubsystem_ClearVoiceFlags
	setda 2, 49662
	jr AudioSubsystem_Callback

AudioSubsystem_ClearVoiceFlags:
	stdi8 49662, 0

; Audio subsystem callback
AudioSubsystem_Callback:
	resda 3, 49662
	stdi8 49844, 255
	stdi8 49852, 255
	stdi8 49664, 255
	stdi8 49665, 255
	ordi16 50588, 257
	ldda8 a, 36148
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8cf4
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ld xbc, xhl
	lda_24 xwa, 0xfdecef
	cp xwa, xbc
	ret z
	lds wa, 0
	call (xhl)
	call AudioInit_DrumRoutingCheck
	call AudioInit_DrumSaveReturn
	call AudioInit_VoiceParamCtrl
	call AudioInit_ClearPartFlags_ByMode
	call AudioInit_DispatchChanges
	ret

AudioInit_SelectAndDispatch:
	call AudioInit_SelectPriority
	jp AudioInit_DispatchChanges

AudioInit_CheckMIDIAndDispatch:
	call AudioInit_CheckMIDIStatus
	jp AudioInit_DispatchChanges

Audio_InitDispatchReturn:
	cps a, 0
	jr z, AudioDispatch_ClearAccFlags
	ldda16 xwa, 50584
	bit 2, wa
	jr z, AudioDispatch_SetAccMode
	bitda 0, 10418
	jr z, AudioDispatch_SetAccMode

AudioDispatch_ClearAccFlags:
	anddi16 50582, 65023
	resda 0, 12932
	call AudioInit_RefreshToneBank
	stdi8 50592, 0
	jr AudioDispatch_CheckStereoMode

AudioDispatch_SetAccMode:
	ordi16 50582, 512
	call AccAutoPlay_PeriodicCheck
	ldda16 xwa, 50582
	and wa, 0x7
	jr z, AudioDispatch_SetTimerBase
	stdi8 50592, 31
	jr AudioDispatch_CheckStereoMode

AudioDispatch_SetTimerBase:
	stdi8 50592, 16

AudioDispatch_CheckStereoMode:
	bitda 1, 64615
	jr z, AudioVoice_Callback
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioDispatch_ClearVoiceFlags
	setda 2, 49662
	jr AudioDispatch_SetBusyFlag

AudioDispatch_ClearVoiceFlags:
	stdi8 49662, 0

AudioDispatch_SetBusyFlag:
	ordi16 50588, 1

; Audio voice callback dispatch
AudioVoice_Callback:
	ldda8 a, 36148
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8cf4
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ld xbc, xhl
	lda_24 xwa, 0xfdecef
	cp xwa, xbc
	jr z, AudioVoice_SkipToDispatch
	lds wa, 0
	call (xhl)
	call AudioInit_ClearPartFlags_ByMode

AudioVoice_SkipToDispatch:
	jp AudioInit_DispatchChanges

AudioMode_SetStereoFlags:
	bitda 0, 64617
	ret z
	ordi16 50582, 128
	ordi16 50580, 4
	calr AudioInit_ProcessModeChange
	ret

AudioMode_ResetVoiceState:
	bitda 1, 64615
	jr z, AudioVoiceReset_Handler
	ldda16 xwa, 50580
	bit 4, wa
	jr nz, AudioVoiceReset_ClearFlags
	setda 2, 49662
	jr AudioVoiceReset_Handler

AudioVoiceReset_ClearFlags:
	stdi8 49662, 0

; Audio voice reset handler
AudioVoiceReset_Handler:
	resda 3, 49662
	stdi8 49844, 255
	stdi8 49852, 255
	stdi8 49664, 255
	stdi8 49665, 255
	ordi16 50588, 257
	anddi16 50580, 65533
	ldda8 a, 36148
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8cf4
	ld_sril3 XHL, 0x07, 0xE4, 0xE0
	ld xbc, xhl
	lda_24 xwa, 0xfdecef
	cp xwa, xbc
	ret z
	lds wa, 1
	call (xhl)
	call AudioInit_DrumRoutingCheck
	call AudioInit_DrumSaveReturn
	call AudioInit_VoiceParamCtrl
	call AudioInit_ClearPartFlags_ByMode
	call AudioInit_DispatchChanges
	ret

AudioMode_ConfigureExternal:
	stdi8 49662, 0
	cps a, 0
	jr z, AudioMode_ConfigExternal_Off
	ordi16 50580, 16
	jr AudioMode_ConfigExternal_Apply

AudioMode_ConfigExternal_Off:
	anddi16 50580, 65519
	bitda 0, 64614
	jr z, AudioMode_ConfigExternal_CheckBit1
	setda 0, 49662

AudioMode_ConfigExternal_CheckBit1:
	bitda 1, 64614
	jr z, AudioMode_ConfigExternal_CheckStereo
	setda 1, 49662

AudioMode_ConfigExternal_CheckStereo:
	bitda 1, 64615
	jr z, AudioMode_ConfigExternal_NoStereo
	ordi16 50582, 32
	jr AudioMode_ConfigExternal_MergeFlags

AudioMode_ConfigExternal_NoStereo:
	anddi16 50582, 65503
	ldda16 xwa, 50582
	and wa, 0x7
	call_24 z, 0xFDF5F5

AudioMode_ConfigExternal_MergeFlags:
	resda 2, 49662
	ldda8 a, 64615
	and a, 0x2
	ld c, a
	add a, c
	orddm8 49662, a

AudioMode_ConfigExternal_Apply:
	ordi16 50580, 4
	jrl AudioInit_ProcessModeChange
; ============================================================================
; UIState_ProcessMidiEvent - Process an incoming MIDI event in UI state
; ============================================================================
; Input:  MIDI event data
; Output: None
; Handles MIDI events (note on/off, control change, etc.) within the UI
; state machine, updating relevant display elements.
; ============================================================================
UIState_ProcessMidiEvent:
	cpdi8 49280, 24
	ret ugt
	ldda8 l, 49280
	ldda8 h, 49277
	ldda8 e, 49279
	ldda8 d, 49278
	ld a, l
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8d74
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, h
	cp a, 0x16
	jrl z, UIStateEvt_TransposeUpdate
	cp a, 0xD
	jr z, UIStateEvt_VoiceAssign
	cp a, 0xC
	jr z, UIStateEvt_PartRouting
	cps a, 0
	ret nz
	ld a, e
	and a, 0xFF
	ret z
	ordi16 50580, 4
	ret

UIStateEvt_PartRouting:
	ld a, e
	and a, 0x7
	ret z
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, wa
	ld hl, wa
	add hl, 0x124
	ldada xix, 49662
	ld a, d
	and a, 0x7
	extz wa
	lda_24 xbc, 0xee8e14
	ld_srib3 A, 0x07, 0xE4, 0xE0
	and a, 0x7
	sla a, 1
	and_srib_im 0x07, 0xF0, 0xEC, 0xF1
	or_srib_mr A, 0x07, 0xF0, 0xEC
	ordi16 50580, 4
	ret

UIStateEvt_VoiceAssign:
	ld a, e
	and a, 0xF
	jr z, UIStateEvt_ToneChange
	bit 6, d
	jr nz, UIStateEvt_VoiceAssign_Reset
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49698
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	and a, 0xF
	ld (xix), a
	jr UIStateEvt_VoiceAssign_Notify

UIStateEvt_VoiceAssign_Reset:
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld (xwa), 0xFF

UIStateEvt_VoiceAssign_Notify:
	ordi16 50588, 2048
	ordi16 50580, 4

UIStateEvt_ToneChange:
	bit 5, e
	jr z, UIStateEvt_DrumAssign
	bit 5, d
	jr z, UIStateEvt_ToneChange_Set
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49666
	extz xwa
	add xwa, xbc
	ld (xwa), 0xFF
	cp l, 0x13
	jr nz, Tone_WriteEndMarker
	stdi8 49688, 255
	jr Tone_WriteEndMarker

UIStateEvt_ToneChange_Set:
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49666
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	ld (xix), a
	cp l, 0x13
	jr nz, Tone_WriteEndMarker
	stdi8 49688, 22

Tone_WriteEndMarker:
	ordi16 50588, 4
	ordi16 50580, 4

UIStateEvt_DrumAssign:
	bit 6, e
	ret z
	bit 6, d
	jr z, UIStateEvt_DrumAssign_Set
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49698
	extz xwa
	add xwa, xbc
	ld (xwa), 0xFF
	jr UIStateEvt_DrumAssign_Notify

UIStateEvt_DrumAssign_Set:
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	ldada xbc, 49698
	ld de, wa
	extz xde
	add xde, xbc
	ld a, l
	extz wa
	sla wa, 2
	lda_24 xbc, 0xee8d74
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	ld a, (xwa + 13)
	and a, 0xF
	ld (xde), a

UIStateEvt_DrumAssign_Notify:
	ordi16 50588, 8
	ordi16 50580, 4
	ret

UIStateEvt_TransposeUpdate:
	bit 0, e
	ret z
	bit 0, d
	jr z, UIStateEvt_TransposeUpdate_Clear
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, wa
	ld bc, wa
	add bc, 0xE4
	ldada xde, 49663
	ldda8 a, 64618
	and a, 0xFF
	sub a, 0x40
	lda_dri3 XBC, 0x07, 0xE8, 0xE4
	jr UIStateEvt_TransposeUpdate_Apply

UIStateEvt_TransposeUpdate_Clear:
	ld a, l
	extz wa
	lda_24 xbc, 0xee8df4
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	add wa, wa
	add wa, 0xE4
	ldada xbc, 49663
	stib_dri 0x07, 0xE4, 0xE0, 0x00

UIStateEvt_TransposeUpdate_Apply:
	ordi16 50580, 4
	ret

UIStateEvt_ParamEdit_Data:
	pushw	iz
	ldda8	a, 49277
	extz	wa
	cps	wa, 0
	jrl	mi, 606
	cps	wa, 6
	jrl	gt, 601
	add	wa, wa
	lda_24	xix, 15633992
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20
	lda_24	xix, 16638671
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	ldda8	a, 49279
	and	a, 7
	jrl	z, 183
	ldda16	wa, 50584
	bit	6, wa
	jr	z, 44
	ldda8	a, 64606
	and	a, 7
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x26
	ldda8	a, 64605
	and	a, 8
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0xe6
	jr	60
	ldda16	wa, 50584
	and	wa, 34
	cp	wa, 32
	jr	nz, 25
	lds	iz, 2
	ldda8	a, 64605
	and	a, 8
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0xe6
	jr	21
	ldda8	a, 64605
	and	a, 15
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x26
	ldda16	wa, 50582
	and	wa, 6
	jr	z, 18
	ld	wa, iz
	and	wa, 6
	jr	z, 10
	ldda16	wa, 50582
	and	wa, 7
	jr	nz, 4
	call	16643573
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xe8, 0xff, 0xd1, 0x96, 0xc5, 0xee, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ldda16	wa, 50582
	and	wa, 7
	jr	z, 7
	stdi8	50592, 31
	jr	5
	stdi8	50592, 16
	.byte 0xf1, 0x7f, 0xc0, 0xcb
	jrl	z, 379
	.byte 0xf1, 0x7e, 0xc0, 0xcb
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x10, 0x00
	jr	6
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xef, 0xff, 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x20, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	jrl	344
	.byte 0xf1, 0x7f, 0xc0, 0xce
	jr	z, 32
	.byte 0xf1, 0x7e, 0xc0, 0xce
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x00, 0x04
	jr	6
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xff, 0xfb, 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x40, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xcc
	jr	z, 32
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xff, 0xf7, 0xf1, 0x7e, 0xc0, 0xcc
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x00, 0x08
	jr	6
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xff, 0xf7, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ldda8	a, 49279
	and	a, 7
	jrl	z, 258
	ldda16	wa, 50584
	bit	6, wa
	jr	z, 44
	ldda8	a, 64606
	and	a, 7
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x26
	ldda8	a, 64605
	and	a, 8
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0xe6
	jr	55
	ldda16	wa, 50584
	bit	5, wa
	jr	z, 25
	lds	iz, 2
	ldda8	a, 64605
	and	a, 8
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0xe6
	jr	21
	ldda8	a, 64605
	and	a, 15
	extz	wa
	add	wa, wa
	lda_24	xbc, 15633960
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x26, 0xd1, 0x96, 0xc5, 0x3c, 0xe8, 0xff, 0xd1, 0x96, 0xc5, 0xee, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ldda16	wa, 50582
	and	wa, 7
	jr	z, 7
	stdi8	50592, 31
	jr	117
	stdi8	50592, 16
	jr	110
	ldda8	a, 49279
	and	a, 252
	jr	z, 30
	.byte 0xf1, 0x84, 0x32, 0xc8
	jr	nz, 18
	ldda16	wa, 50582
	bit	9, wa
	jr	z, 9
	ldda8	a, 64607
	and	a, 252
	jr	nz, 0
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xc9
	jr	z, 65
	.byte 0xf1, 0x5f, 0xfc, 0xc9
	jr	z, 12
	ldda16	wa, 50582
	bit	9, wa
	.byte 0xf2, 0xf5, 0xf5, 0xfd, 0xe6, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	jr	39
	ldda8	a, 49279
	and	a, 252
	jr	z, 30
	.byte 0xf1, 0x84, 0x32, 0xc8
	jr	nz, 18
	ldda16	wa, 50582
	bit	9, wa
	jr	z, 9
	ldda8	a, 64607
	and	a, 252
	jr	nz, 0
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	popw	iz
	ret
UIStateEvt_VolumeMixer_Data:
	ldda8	a, 49277
	extz	wa
	cps	wa, 0
	.byte 0xb0, 0xf5
	cps	wa, 5
	ret	gt
	add	wa, wa
	lda_24	xix, 15634006
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20
	lda_24	xix, 16639288
	.byte 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	ldda8	a, 49279
	and	a, 31
	jr	z, 22
	.byte 0xc1, 0xfe, 0xc1, 0x3c, 0xfc
	ldda8	a, 49278
	and	a, 3
	.byte 0xc1, 0xfe, 0xc1, 0xe9, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ldda16	wa, 50580
	bit	4, wa
	ret	z
	stdi8	49662, 0
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 31
	jr	z, 58
	.byte 0xf1, 0x7e, 0xc0, 0xc9
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x20, 0x00
	jr	19
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xdf, 0xff
	ldda16	wa, 50582
	and	wa, 7
	.byte 0xf2, 0xf5, 0xf5, 0xfd, 0xe6, 0xf1, 0xfe, 0xc1, 0xb2
	ldda8	a, 49278
	and	a, 2
	ld	c, a
	add	a, c
	.byte 0xc1, 0xfe, 0xc1, 0xe9, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ldda16	wa, 50580
	bit	4, wa
	ret	z
	stdi8	49662, 0
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x04, 0x00
	ret
	.byte 0xf1, 0x7f, 0xc0, 0xc8
	jr	z, 26
	.byte 0xf1, 0x7e, 0xc0, 0xc8
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x80, 0x00
	jr	6
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0x7f, 0xff, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xc9
	ret	z
	.byte 0xf1, 0x7e, 0xc0, 0xc9
	jr	z, 8
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x08, 0x00
	jr	6
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xf7, 0xff, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 255
	ret	z
	lds	de, 0
	cp	de, 26
	jr	ge, 79
	ld	wa, de
	.byte 0xd8, 0xec, 0x02
	lda_24	xbc, 15633780
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0xb8, 0x16, 0xc8
	jr	z, 32
	ld	wa, de
	add	wa, wa
	add	wa, 228
	ldada	xbc, 49663
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 49278
	and	a, 255
	sub	a, 64
	ld	(xhl), a
	jr	19
	ld	wa, de
	add	wa, wa
	add	wa, 228
	ldada	xbc, 49663
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
	inc	1, de
	cp	de, 26
	jr	lt, -79
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 255
	ret	z
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ret
UIStateEvt_EffectSelect_Data:
	ldda8	a, 49277
	cps	a, 4
	jrl	z, 270
	cps	a, 3
	jrl	z, 238
	cps	a, 2
	jrl	z, 147
	cps	a, 1
	jr	z, 99
	cps	a, 0
	ret	nz
	ldda8	a, 49279
	and	a, 3
	jr	z, 79
	ldda8	a, 49278
	and	a, 3
	cps	a, 3
	jr	z, 57
	cps	a, 2
	jr	z, 40
	cps	a, 1
	jr	z, 23
	cps	a, 0
	jr	nz, 56
	ldda8	a, 64771
	res	7, a
	stda8	50594, a
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x04
	jr	37
	stdi8	50594, 55
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x04
	jr	24
	stdi8	50594, 60
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x04
	jr	11
	stdi8	50594, 67
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x04, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	res	7, a
	cps	a, 0
	ret	z
	ldda8	a, 64770
	and	a, 3
	jr	nz, 11
	ldda8	a, 49278
	res	7, a
	stda8	50594, a
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x04, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 255
	ret	z
	.byte 0xf1, 0x50, 0xfd, 0xcd
	ret	z
	ldda8	a, 49278
	and	a, 255
	extz	wa
	lda_24	xbc, 15633948
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x25
	lds	hl, 0
	cp	hl, 26
	jr	nc, 37
	ld	wa, hl
	add	wa, wa
	add	wa, 292
	ldada	xbc, 49663
	extz	xwa
	add	xwa, xbc
	ld	c, e
	and	c, 15
	.byte 0xcb, 0xec, 0x04, 0x80, 0x3c, 0x0f
	or	(xwa), c
	inc	1, hl
	cp	hl, 26
	jr	c, -37
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 255
	ret	z
	ldda8	a, 49278
	and	a, 255
	stda8	59840, a
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ldda8	a, 49279
	and	a, 15
	ret	z
	ldda8	a, 49278
	and	a, 15
	stda8	59838, a
	.byte 0xd1, 0x9a, 0xc5, 0x3e, 0x00, 0x40, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
UIStateEvt_PlayModeGuard_Data:
	; --- Guard/dispatch: check flags, set/clear bits, conditional calls (54 bytes) ---
	cpdi8	49277, 2
	ret nz
	.byte 0xf1, 0x7e, 0xc0, 0xce			; bit 6, (0xC07E)  [F1 prefix]
	jr z, UIStateEvt_PlayModeGuard_ClearBit
	.byte 0xd1, 0x96, 0xc5, 0x3e, 0x00, 0x20	; or (0xC596), 0x2000  [D1 prefix]
	ret
UIStateEvt_PlayModeGuard_ClearBit:
	.byte 0xd1, 0x96, 0xc5, 0x3c, 0xff, 0xdf	; and (0xC596), 0xDFFF  [D1 prefix]
	call Voice_UpdatePlayModeState
	cp hl, 0x00FF
	.byte 0xf2, 0xb8, 0x12, 0xfe, 0xee		; call nz, 0xFE12B8  [conditional call]
	call NoteMap_FindBestMatch
	cp hl, 0x00FF
	ret z
	call VoiceEvent_DispatchTable
	ret


UIStateEvt_ChannelConfig_Data:
	ldda8	a, 49277
	cp	a, 11
	jrl	z, 326
	cp	a, 12
	jrl	z, 320
	cp	a, 10
	jrl	z, 314
	cps	a, 3
	jrl	z, 158
	cps	a, 2
	jrl	z, 146
	cps	a, 1
	ret	z
	cps	a, 0
	ret	nz
	.byte 0xf1, 0x7f, 0xc0, 0xce
	jr	z, 12
	.byte 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xcd
	ret	z
	.byte 0xf1, 0x7e, 0xc0, 0xcd
	jr	z, 66
	lds	de, 0
	cp	de, 26
	jr	nc, 93
	ld	wa, de
	add	wa, wa
	add	wa, 292
	ldada	xbc, 49663
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldda8	a, 64772
	and	a, 255
	extz	wa
	lda_24	xbc, 15633948
	.byte 0xc3, 0x07, 0xe4, 0xe0, 0x21
	and	a, 15
	.byte 0xc9, 0xec, 0x04, 0x83, 0x3c, 0x0f
	or	(xhl), a
	inc	1, de
	cp	de, 26
	jr	c, -56
	jr	35
	lds	de, 0
	cp	de, 26
	jr	nc, 27
	ld	wa, de
	add	wa, wa
	add	wa, 292
	ldada	xbc, 49663
	extz	xwa
	add	xwa, xbc
	.byte 0x80, 0x3c, 0x0f
	inc	1, de
	cp	de, 26
	jr	c, -27
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	.byte 0xf1, 0x7f, 0xc0, 0xc8
	jr	z, 34
	.byte 0xf1, 0x7e, 0xc0, 0xc8
	jr	z, 12
	.byte 0xf1, 0x22, 0xc3, 0xb4, 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00
	jr	10
	.byte 0xf1, 0x22, 0xc3, 0xbc, 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xca
	jr	z, 68
	.byte 0xf1, 0x7e, 0xc0, 0xca
	jr	z, 26
	.byte 0xf1, 0x42, 0xc3, 0xbe, 0xf1, 0x44, 0xc3, 0xbe, 0xf1, 0x46, 0xc3, 0xbe, 0xf1, 0x48, 0xc3, 0xbe, 0xf1, 0x4a, 0xc3, 0xbe, 0xf1, 0x4c, 0xc3, 0xbe
	jr	30
	.byte 0xf1, 0x42, 0xc3, 0xb6, 0xf1, 0x44, 0xc3, 0xb6, 0xf1, 0x46, 0xc3, 0xb6, 0xf1, 0x48, 0xc3, 0xb6, 0xf1, 0x4a, 0xc3, 0xb6, 0xf1, 0x4c, 0xc3, 0xb6, 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xce
	jr	z, 12
	.byte 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00, 0xf1, 0x7f, 0xc0, 0xcf
	ret	z
	.byte 0xd1, 0x9c, 0xc5, 0x3e, 0x08, 0x00, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ld	xwa, 20480
	call	16569399
	cps	hl, 2
	jr	z, 38
	cps	hl, 1
	jr	z, 15
	cps	hl, 0
	ret	nz
	stdi8	50018, 0
	stdi8	50019, 255
	ret
	ld	xwa, 20481
	call	16569399
	stda8	50018, l
	stdi8	50019, 255
	ret
	stdi8	50018, 0
	ld	xwa, 20482
	call	16569399
	stda8	50019, l
	ret
UIStateEvt_StubReturn:
	.byte 0x0e, 0x0e
UIStateEvt_MuteToggle_Data:
	ldda8	a, 49277
	cp	a, 16
	ret	nz
	.byte 0xf1, 0x7f, 0xc0, 0xc8
	ret	z
	.byte 0xf1, 0x7e, 0xc0, 0xc8
	jr	z, 8
	.byte 0xd1, 0x94, 0xc5, 0x3e, 0x01, 0x00
	jr	6
	.byte 0xd1, 0x94, 0xc5, 0x3c, 0xfe, 0xff, 0xd1, 0x94, 0xc5, 0x3e, 0x04, 0x00
	ret
	ret

; ============================================================================
; AudioInit_ConfigStereoVoice - Configure stereo voice routing and panning
; ============================================================================
; Input:  Voice index (from voice type table at 0xEE8E62)
; Output: Updates audio config flags at address 50588
; Default handler in voice-source dispatch table. Routes voices by type:
; simple stereo (type < 3) or extended routing with panning configuration.
; ============================================================================
	.include "audio/audioinit_routines.s"
