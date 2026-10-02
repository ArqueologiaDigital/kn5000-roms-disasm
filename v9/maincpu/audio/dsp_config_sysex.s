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
	ld a, 0x0:opc

SysEx_ClampVoiceIndex8_DoLookup:
	extz wa
	lda xbc, (SysEx_ClampVoiceIndex8_DoLookup_Data:24)
	ld	l, (xbc+wa)
	ret

SysEx_ApplyToSlot4B_Data:
	dec	2, xsp
	push	xiz
	ld	xwa, (0xbcac:16)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	SysEx_ClampVoiceIndex128
	ld	(xsp+4), l
	ld	xwa, 0x4b04
	call	DSPCfg_ReadParam_Map0
	ld qiz, hl
	cp qiz, 0
	jr lt, SysEx_ClampVoiceIndex8_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr le, SysEx_ClampVoiceIndex8_Join
SysEx_ClampVoiceIndex8_Loop:
	ld wa, iz
	exts	xwa
	add	xwa, 0x4b10
	call	DSPCfg_ResolveAndExtract
	cp	hl, 1:i3
	jr	z, SysEx_ClampVoiceIndex8_Skip
	cp	hl, 2:i3
	jr	nz, SysEx_ClampVoiceIndex8_Skip2
SysEx_ClampVoiceIndex8_Skip:
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4b10
	ld	c, (xsp+4)
	extz	bc
	call	DSPCfg_WriteParamFull
	jr	SysEx_ClampVoiceIndex8_Join
SysEx_ClampVoiceIndex8_Skip2:
	inc	1, iz
	cp iz, qiz
	jr	lt, SysEx_ClampVoiceIndex8_Loop
SysEx_ClampVoiceIndex8_Join:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ClampVoiceIndex8_Epilogue:
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex128:
	cp a, 0x80
	jr c, SysEx_ClampVoiceIndex128_DoLookup
	ld a, 0x0:opc

SysEx_ClampVoiceIndex128_DoLookup:
	extz wa
	lda xbc, (SysEx_ClampVoiceIndex128_DoLookup_Data:24)
	ld	l, (xbc+wa)
	ret

SysEx_ApplyToSlot49_Data:
	dec	2, xsp
	push	xiz
	ld	xwa, (0xbcac:16)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	SysEx_ClampVoiceIndex8_49
	extz	hl
	ld	xwa, 0x4900
	ld	bc, hl
	call	DSPCfg_WriteParamFull
	cp	hl, 0:i3
	jr	lt, SysEx_ClampVoiceIndex128_Epilogue
	ld	xwa, 0x4904
	call	DSPCfg_ReadParam_Map0
	ld qiz, hl
	cp qiz, 0
	jr lt, SysEx_ClampVoiceIndex128_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr le, SysEx_ClampVoiceIndex128_Skip2
SysEx_ClampVoiceIndex128_Loop:
	ld	a, (xsp+4)
	extz	wa
	ldto_berp c, 248
	extz	bc
	calr	SysEx_DispatchByChannel
	ld	bc, hl
	cp	bc, 0xd8f0
	jr	z, SysEx_ClampVoiceIndex128_Skip
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4910
	call	DSPCfg_WriteParamFull
SysEx_ClampVoiceIndex128_Skip:
	inc	1, iz
	cp iz, qiz
	jr	lt, SysEx_ClampVoiceIndex128_Loop
SysEx_ClampVoiceIndex128_Skip2:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ClampVoiceIndex128_Epilogue:
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex8_49:
	cp a, 0x8
	jr c, SysEx_ClampVoiceIndex8_49_DoLookup
	ld a, 0x0:opc

SysEx_ClampVoiceIndex8_49_DoLookup:
	extz wa
	lda xbc, (SysEx_ClampVoiceIndex8_49_DoLookup_Data:24)
	ld	l, (xbc+wa)
	ret

SysEx_ApplyToSlot49_Format_Data:
	dec	2, xsp
	push	xiz
	ld	xwa, (0xbcac:16)
	ldw	bc, 11
	call	SeqData_ReadFieldByIndex
	ld	(xsp+4), l
	ld	a, (xsp+4)
	extz	wa
	calr	SysEx_ClampVoiceIndex128_49
	ld	(xsp+4), l
	ld	xwa, 0x4904
	call	DSPCfg_ReadParam_Map0
	ld qiz, hl
	cp qiz, 0
	jr lt, SysEx_ApplyToSlot49_Format_Data_Epilogue
	ld	iz, 0:i3
	cp qiz, 0
	jr le, SysEx_ApplyToSlot49_Format_Data_Join
SysEx_ApplyToSlot49_Format_Data_Loop:
	ld wa, iz
	exts	xwa
	add	xwa, 0x4910
	call	DSPCfg_ResolveAndExtract
	cp	hl, 1:i3
	jr	z, SysEx_ApplyToSlot49_Format_Data_Skip
	cp	hl, 2:i3
	jr	nz, SysEx_ApplyToSlot49_Format_Data_Skip2
SysEx_ApplyToSlot49_Format_Data_Skip:
	ld	wa, iz
	exts	xwa
	add	xwa, 0x4910
	ld	c, (xsp+4)
	extz	bc
	call	DSPCfg_WriteParamFull
	jr	SysEx_ApplyToSlot49_Format_Data_Join
SysEx_ApplyToSlot49_Format_Data_Skip2:
	inc	1, iz
	cp iz, qiz
	jr	lt, SysEx_ApplyToSlot49_Format_Data_Loop
SysEx_ApplyToSlot49_Format_Data_Join:
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
SysEx_ApplyToSlot49_Format_Data_Epilogue:
	pop	xiz
	inc	2, xsp
	ret

SysEx_ClampVoiceIndex128_49:
	cp a, 0x80
	jr c, SysEx_ClampVoiceIndex128_49_DoLookup
	ld a, 0x0:opc

SysEx_ClampVoiceIndex128_49_DoLookup:
	extz wa
	lda xbc, (SysEx_ClampVoiceIndex128_49_DoLookup_Data:24)
	ld	l, (xbc+wa)
	ret

SysEx_DispatchByChannel:
	ldw hl, 0xd8f0
	ld e, c
	extz de
	add de, de
	extz wa
	cp wa, 0:i3
	ret mi
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda xix, (SysEx_DispatchByChannel_Data_9:24)
	ld	wa, (xix+wa)
	lda xix, (SysEx_ChannelHandler_4B_Data:24)
	jp	t, (xix+wa)

SysEx_ChannelHandler_4B_Data:
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_2
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_3
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_4
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 8
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_5
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 8
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_6
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_7
	jr	SysEx_DispatchByChannel_Entry
	cp	c, 7:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_Data_8
SysEx_DispatchByChannel_Entry:
	ld	hl, (xwa+de)
	ret

SysEx_DispatchByChannel_49:
	ldw hl, 0xd8f0
	ld e, c
	extz de
	add de, de
	extz wa
	cp wa, 0:i3
	ret mi
	cp wa, 7:i3
	ret gt
	add wa, wa
	lda xix, (SysEx_DispatchByChannel_49_Data_9:24)
	ld	wa, (xix+wa)
	lda xix, (SysEx_ChannelHandler_49_Data:24)
	jp	t, (xix+wa)

SysEx_ChannelHandler_49_Data:
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_2
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_3
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_4
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_5
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 5:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_6
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 6:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_7
	jr	SysEx_DispatchByChannel_49_Entry
	cp	c, 6:i3
	ret	nc
	ld	xwa, SysEx_DispatchByChannel_49_Data_8
SysEx_DispatchByChannel_49_Entry:
	ld	hl, (xwa+de)
	ret

SysEx_ValidateRolandHeader:
	cp c, 0xa
	ret ugt
	cp (xwa+), 0xf0
	ret nz
	inc 1, xwa
	cp (xwa+), 0x41
	ret nz
	inc 1, xwa
	cp (xwa+), 0x42
	ret nz
	cp (xwa+), 0x12
	ret nz
	cp (xwa+), 0x40
	ret nz
	cp (xwa+), 0x01
	ret nz
	cp c, 0:i3
	jr nz, SysEx_ValidateRolandHeader_NonZeroChan
	lda xbc, (0x00f180:24)
	add xbc, 0x2e0
	jr SysEx_ValidateRolandHeader_Dispatch

SysEx_ValidateRolandHeader_NonZeroChan:
	dec 1, c
	extz bc
	sla bc, 11
	ld de, bc
	exts xde
	lda xbc, (0x0ab000:24)
	add xbc, xde
	add xbc, 0x2e0

SysEx_ValidateRolandHeader_Dispatch:
	ld E, (xwa+)
	cp e, 0x3a
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
	lda xwa, (0xfc8e:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8
	extz hl
	ld xwa, 0x4b00
	ld bc, hl
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jr lt, SysEx_ApplyVoiceParam_4B_Return
	lda xwa, (0xfc8e:16)
	cp xwa, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_ReadSubParams
	ld a, (xwa)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8
	ld (0xfc8e:16), l

SysEx_ApplyVoiceParam_4B_ReadSubParams:
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr ge, SysEx_ApplyVoiceParam_4B_IterateSlots
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_SkipRestore:
	jr SysEx_ApplyVoiceParam_4B_Return

SysEx_ApplyVoiceParam_4B_IterateSlots:
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, SysEx_ApplyVoiceParam_4B_RestoreSlotId

SysEx_ApplyVoiceParam_4B_SlotLoop:
	ld a, (xsp + 10)
	extz wa
	ldto_berp C, 0xf8
	extz bc
	calr SysEx_DispatchByChannel_49
	ld bc, hl
	cp bc, 0xd8f0
	jr z, SysEx_ApplyVoiceParam_4B_SlotNext
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple

SysEx_ApplyVoiceParam_4B_SlotNext:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyVoiceParam_4B_SlotLoop

SysEx_ApplyVoiceParam_4B_RestoreSlotId:
	lda xbc, (0xfc8e:16)
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
	lda xwa, (0xfc8e:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex128
	ld (xsp + 10), l
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_128_ReadSub
	ld a, (xbc)
	ld (xsp + 4), a
	ld xwa, (xsp + 6)
	ld a, (xwa)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_128_ReadSub:
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr ge, SysEx_ApplyVoiceParam_4B_128_IterateSlots
	lda xbc, (0xfc8e:16)
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_4B_128_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_4B_128_SkipRestore:
	jr SysEx_ApplyVoiceParam_4B_128_Return

SysEx_ApplyVoiceParam_4B_128_IterateSlots:
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, SysEx_ApplyVoiceParam_4B_128_RestoreSlotId

SysEx_ApplyVoiceParam_4B_128_SlotLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ResolveAndExtract
	cp hl, 1:i3
	jr z, SysEx_ApplyVoiceParam_4B_128_WriteSlot
	cp hl, 2:i3
	jr nz, SysEx_ApplyVoiceParam_4B_128_SlotNext

SysEx_ApplyVoiceParam_4B_128_WriteSlot:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld c, (xsp + 10)
	extz bc
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	jr SysEx_ApplyVoiceParam_4B_128_RestoreSlotId

SysEx_ApplyVoiceParam_4B_128_SlotNext:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyVoiceParam_4B_128_SlotLoop

SysEx_ApplyVoiceParam_4B_128_RestoreSlotId:
	lda xbc, (0xfc8e:16)
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
	lda xwa, (0xfc74:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8_49
	extz hl
	ld xwa, 0x4900
	ld bc, hl
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jr lt, SysEx_ApplyVoiceParam_49_Return
	lda xwa, (0xfc74:16)
	cp xwa, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_ReadSubParams
	ld a, (xwa)
	ld (xsp + 4), a
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex8_49
	ld (0xfc74:16), l

SysEx_ApplyVoiceParam_49_ReadSubParams:
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr ge, SysEx_ApplyVoiceParam_49_IterateSlots
	lda xbc, (0xfc74:16)
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_SkipRestore:
	jr SysEx_ApplyVoiceParam_49_Return

SysEx_ApplyVoiceParam_49_IterateSlots:
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, SysEx_ApplyVoiceParam_49_RestoreSlotId

SysEx_ApplyVoiceParam_49_SlotLoop:
	ld a, (xsp + 10)
	extz wa
	ldto_berp C, 0xf8
	extz bc
	calr SysEx_DispatchByChannel
	ld bc, hl
	cp bc, 0xd8f0
	jr z, SysEx_ApplyVoiceParam_49_SlotNext
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	ld xde, (xsp + 6)
	call DSPCfg_WriteParamSimple

SysEx_ApplyVoiceParam_49_SlotNext:
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyVoiceParam_49_SlotLoop

SysEx_ApplyVoiceParam_49_RestoreSlotId:
	lda xbc, (0xfc74:16)
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
	lda xwa, (0xfc74:16)
	sub xwa, 0xf980
	add (xsp + 6), xwa
	ld a, (xsp + 10)
	extz wa
	calr SysEx_ClampVoiceIndex128_49
	ld (xsp + 10), l
	lda xbc, (0xfc74:16)
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
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr ge, SysEx_ApplyVoiceParam_49_128_IterateSlots
	lda xbc, (0xfc74:16)
	cp xbc, (xsp + 6)
	jr z, SysEx_ApplyVoiceParam_49_128_SkipRestore
	ld a, (xsp + 4)
	ld (xbc), a

SysEx_ApplyVoiceParam_49_128_SkipRestore:
	jr SysEx_ApplyVoiceParam_49_128_Return

SysEx_ApplyVoiceParam_49_128_IterateSlots:
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, SysEx_ApplyVoiceParam_49_128_RestoreSlotId

SysEx_ApplyVoiceParam_49_128_SlotLoop:
	ld wa, iz
	exts xwa
	add xwa, 0x4910
	call DSPCfg_ResolveAndExtract
	cp hl, 1:i3
	jr z, SysEx_ApplyVoiceParam_49_128_WriteSlot
	cp hl, 2:i3
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
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyVoiceParam_49_128_SlotLoop

SysEx_ApplyVoiceParam_49_128_RestoreSlotId:
	lda xbc, (0xfc74:16)
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
	ldw hl, 0xffff
	jrl AssswbWr_Return

SysEx_ApplyAndReloadPreset_Type61:
	ld xwa, 0x4900
	ld xde, 0xfc74
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jrl lt, AssswbWr_ReturnFail
	ld xwa, 0x4904
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jrl lt, AssswbWr_ReturnFail
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
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
	ld xde, 0xfc74
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyAndReloadPreset_Type61_Loop
	jr AssswbWr_ReturnFail

SysEx_ApplyAndReloadPreset_Type63:
	ld xwa, 0x4b00
	ld xde, 0xfc8e
	call DSPCfg_WriteParamSimple
	cp hl, 0:i3
	jr lt, AssswbWr_ReturnFail
	ld xwa, 0x4b04
	call DSPCfg_ReadParam_Map0
	ldfr_werp HL, 0xfa
	cpiw_erp 0xfa, 0
	jr lt, AssswbWr_ReturnFail
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, AssswbWr_ReturnFail

SysEx_ApplyAndReloadPreset_Type63_Loop:
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	call DSPCfg_ReadParam_Map1
	ld bc, hl
	ld wa, iz
	exts xwa
	add xwa, 0x4b10
	ld xde, 0xfc8e
	call DSPCfg_WriteParamSimple
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, SysEx_ApplyAndReloadPreset_Type63_Loop

AssswbWr_ReturnFail:
	ld hl, 0:i3

AssswbWr_Return:
	pop xiz
	ret
AssswbWr:
	ld hl, (0x90de:16)
	cp hl, 0x1fc
	jr nc, AssswbWr_BufferFull
	lda xix, (0xbd3c:16)
	extz xhl
	add xhl, xix
	ld (xhl+), a
	ld (xhl+), c
	ld (xhl+), e
	ld a, (xsp + 4)
	ld (xhl+), a
	ld (xhl), 0xff
	ld wa, (0x90de:16)
	inc 4, wa
	ld (0x90de:16), wa

AssswbWr_BufferFull:
	retd 0x2

AddswbWr:
	ld hl, (0x90e2:16)
	cp hl, 0xfc
	jr nc, AddswbWr_BufferFull
	lda xix, (0xbf39:16)
	extz xhl
	add xhl, xix
	ld (xhl+), a
	ld (xhl+), c
	ld (xhl+), e
	ld a, (xsp + 4)
	ld (xhl+), a
	ld (xhl), 0xff
	ld wa, (0x90e2:16)
	inc 4, wa
	ld (0x90e2:16), wa

AddswbWr_BufferFull:
	retd 0x2

SwbtWr:
	lda xix, (0xc039:16)
	ld xiy, xix
	lda xhl, (xix + 60)
	cp (xix), 0xff
	jr z, SwbtWr_CheckSpace

SwbtWr_ScanEnd:
	inc 4, xiy
	cp (xiy), 0xff
	jr nz, SwbtWr_ScanEnd

SwbtWr_CheckSpace:
	cp xiy, xhl
	jr nc, SwbtWr_Done
	ld (xiy+), a
	ld (xiy+), c
	ld (xiy+), e
	ld a, (xsp + 4)
	ld (xiy+), a
	ld (xiy), 0xff

SwbtWr_Done:
	retd 0x2

SwbtWr_CallProcessAll:
	push xiz
	calr SwbtWr_ProcessAll
	pop xiz
	ret

SwbtWr_SoundBankParamTable:
	.byte 0x3e, 0x1e, 0x3e, 0x00, 0x5e, 0x0e, 0x3e, 0x1e
	.byte 0x57, 0x00, 0x5e, 0x0e, 0x3e, 0x1e, 0x70, 0x00
	.byte 0x5e, 0x0e

SwbtWr_ProcessAll:
	ld xiy, 0xbf39
	ld xix, 0xbd3c
	ld bc, (0x90e2:16)
	srl bc, 1
	cp bc, 0:i3
	jr z, SwbtWr_ProcessAll_CompactDone
	ldirw

SwbtWr_ProcessAll_CompactDone:
	ld (xix), 0xff
	sub xix, 0xbd3c
	ld (0x90de:16), ix
	ld (0xbf39:16), 255
	ldw (0x90e2:16), 0
	ret

SwbtWr_InitBank1:
	ld xiy, SwbtWr_InitBank1_Data
	ld (0xc081:16), xiy
	ld xiy, SwbtBank1_PostCallbacks
	ld (0xc085:16), xiy
	ld xiy, 0xbd3c
	ld (0xc089:16), xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_InitBank2:
	ld xiy, Naka_RenderMode_A_Table
	ld (0xc081:16), xiy
	ld xiy, SwbtWr_InitBank2_Data
	ld (0xc085:16), xiy
	ld xiy, 0xbd3c
	ld (0xc089:16), xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_InitBank3:
	ld xiy, Naka_EventHandler_Table
	ld (0xc081:16), xiy
	ld xiy, SwbtBank3_PostCallbacks
	ld (0xc085:16), xiy
	ld xiy, 0xc039
	ld (0xc089:16), xiy
	calr SwbtWr_DispatchLoop_Init
	ret

SwbtWr_DispatchLoop_Init:
	ldw (0xc07b:16), 0

SwbtWr_DispatchLoop:
	ld xiy, (0xc089:16)
	add iy, (0xc07b:16)
	cp (xiy), 0xff
	jr z, SwbtWr_DispatchLoop_PostCallbacks
	ld xix, (0xc081:16)
	xor hl, hl
	ld l, (xiy)
	ld (0xc080:16), l
	cp l, 0xbf
	jr ugt, SwbtWr_DispatchLoop_NextEvent
	sla hl, 2
	ld	xhl, (xix+hl)
	ld wa, (xiy + 1)
	ld c, (xiy + 3)

SwbtWr_DispatchLoop_ScanCallbacks:
	cpw (xhl), 0xffff
	jr nz, SwbtWr_DispatchLoop_ExecuteCallback
	cpw (xhl + 2), 0xffff
	jr z, SwbtWr_DispatchLoop_NextEvent

SwbtWr_DispatchLoop_ExecuteCallback:
	ld (0xc07d:16), wa
	ld (0xc07f:16), c
	push_sd16w 0x7b, 0xc0
	push_sd16w 0x81, 0xc0
	push_sd16w 0x83, 0xc0
	push_sd16w 0x85, 0xc0
	push_sd16w 0x87, 0xc0
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
	popw_dd16 0x87, 0xc0
	popw_dd16 0x85, 0xc0
	popw_dd16 0x83, 0xc0
	popw_dd16 0x81, 0xc0
	popw_dd16 0x7b, 0xc0
	add xhl, 0x4
	jr SwbtWr_DispatchLoop_ScanCallbacks

SwbtWr_DispatchLoop_NextEvent:
	addw (0xc07b:16), 4
	jrl SwbtWr_DispatchLoop

SwbtWr_DispatchLoop_PostCallbacks:
	ld xix, (0xc085:16)

SwbtWr_PostCallback_Loop:
	cpw (xix), 0xffff
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
	cpw (0x90de:16), 507
	jr ugt, SwbtWr_QueueMainEvent_Done
	ld xhl, 0xbd3c
	add hl, (0x90de:16)
	ld (xhl), de
	ld (xhl + 2), wa
	ld (xhl + 4), 0xff
	add (0x90de:16), 4

SwbtWr_QueueMainEvent_Done:
	ret

SwbtWr_QueuePostEvent:
	cpw (0x90e2:16), 251
	jr ugt, SwbtWr_QueuePostEvent_Done
	ld xhl, 0xbf39
	add hl, (0x90e2:16)
	ld (xhl), de
	ld (xhl + 2), wa
	ld (xhl + 4), 0xff
	addw (0x90e2:16), 4

SwbtWr_QueuePostEvent_Done:
	ret

SwbtWr_TrailingBytecode:
	ld	xhl, 0xc039
SwbtWr_TrailingBytecode_Join:
	cp	(xhl), 255
	jr	z, SwbtWr_TrailingBytecode_Skip
	add	hl, 4
	jr	SwbtWr_TrailingBytecode_Join
SwbtWr_TrailingBytecode_Skip:
	cp	xhl, 0xc074
	jr	ugt, SwbtWr_TrailingBytecode_Return
	ld	(xhl), de
	ld	(xhl+2), wa
	ld	(xhl+4), 255
SwbtWr_TrailingBytecode_Return:
	ret

PreLswLoad:
	calr VoiceParam_SaveReverbChorus
	jp SndParam_SyncDisplayBitmap

PostLswLoad:
	cp wa, 0:i3
	jp lt, (Voice_CopyFromScratch:24)
	cp (0x0340f6:24), 0x00
	call z, (VoiceParam_RestoreReverbChorus:24)
	call ToneGen_DispatchByMode
	call SwbtWr_NullRet
	call ToneGen_Config_InitAllEntries
	call ToneGen_DSPCfg_ResetAll
	ld wa, 1:i3
	call BitMapOut_GetRenderMode_CheckBit3
	call SoundParam_NotifyMultipleChanges
	ld wa, 1:i3
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
	cp wa, 0:i3
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
	pushw_erp 0xfa
	lda xwa, (0xc08e:16)
	ld (xsp + 2), xwa
	ldib_erp 0xfb, 0

VoiceParam_SaveReverbChorus_Loop:
	ldto_berp A, 0xfb
	extz wa
	call VoiceData_LookupPtrByIndex
	lda xbc, (xhl + 12)
	ld xde, xbc
	inc 1, xde
	ld xwa, (xsp + 2)
	ld c, (xbc)
	ld (xwa+), c
	ld (xsp + 2), xwa
	ld c, (xde)
	ld (xwa+), c
	ld (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x19
	jr c, VoiceParam_SaveReverbChorus_Loop
	pushw 0xe
	pushw 0x0
	pushw 0xfd50
	ld xwa, (xsp + 8)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	popw_erp 0xfa
	inc 4, xsp
	ret

VoiceParam_RestoreReverbChorus:
	dec 4, xsp
	pushw_erp 0xfa
	lda xwa, (0xc08e:16)
	ld (xsp + 2), xwa
	ldib_erp 0xfb, 0

VoiceParam_RestoreReverbChorus_Loop:
	ldto_berp A, 0xfb
	extz wa
	call VoiceData_LookupPtrByIndex
	lda xde, (xhl + 12)
	ld xhl, xde
	inc 1, xhl
	andmi8 (xde), 0xf8
	ld xwa, (xsp + 2)
	ld C, (xwa+)
	ld (xsp + 2), xwa
	and c, 0x7
	or (xde), c
	ld xwa, (xsp + 2)
	ld C, (xwa+)
	ld (xhl), c
	ld (xsp + 2), xwa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x19
	jr c, VoiceParam_RestoreReverbChorus_Loop
	pushw 0xe
	ld xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xfd50
	call Mem_Copy
	lda xsp, (xsp + 10)
	popw_erp 0xfa
	inc 4, xsp
	ret

BitMapOut_ComputeRegionDelta:
	lda xwa, (0xfda2:16)
	lda xbc, (0xf980:16)
	sub xwa, xbc
	pushw wa
	push xbc
	pushw 0x0
	pushw 0xf460
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
	ld wa, 2:i3
	call BitMapOut_GetRenderMode_CheckBit3
	call BitMapOut_SaveDisplayToROM
	lda xbc, (0xfc5a:16)
	ld a, (xbc + 8)
	ldfr_berp A, 0xf9
	ld a, (xbc + 9)
	ldfr_berp A, 0xfb
	ldmi16 (xsp + 4), 0x8d3a
	lda xbc, (0xfd96:16)
	ld a, (xbc + 1)
	ld (xsp + 6), a
	ld a, (xbc + 11)
	ld (xsp + 8), a
	pushw 0x4
	pushw 0x0
	pushw 0xfc54
	lda xwa, (xsp + 40)
	push xwa
	call Mem_Copy
	pushw 0x18
	pushw 0x0
	pushw 0xfcdc
	lda xwa, (xsp + 26)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 20)
	calr VoiceParam_SaveReverbChorus
	lda xix, (0xf460:16)
	lda xbc, (0xf980:16)
	ld xhl, xbc
	lda xwa, (0xfd5e:16)
	sub xwa, xbc
	ld de, wa
	srl de, 1
	ld bc, 0:i3
	cp de, 0:i3
	jr ule, BitMapOut_CopyRegion_Done

BitMapOut_CopyRegion_Loop:
	ld WA, (xix+)
	ld (xhl+), WA
	inc 1, bc
	ld wa, bc
	cp wa, de
	jr c, BitMapOut_CopyRegion_Loop

BitMapOut_CopyRegion_Done:
	pushw 0x4
	lda xwa, (xsp + 36)
	push xwa
	pushw 0x0
	pushw 0xfc54
	call Mem_Copy
	pushw 0x18
	lda xwa, (xsp + 22)
	push xwa
	pushw 0x0
	pushw 0xfcdc
	call Mem_Copy
	lda xsp, (xsp + 20)
	cp (4596:16), 1
	jr nz, BitMapOut_SkipRestore
	cp (0x0340f7:24), 0x00
	jr nz, BitMapOut_MergeOutputFields

BitMapOut_SkipRestore:
	calr VoiceParam_RestoreReverbChorus

BitMapOut_MergeOutputFields:
	lda xix, (0xfd96:16)
	lda xbc, (xix + 1)
	lda xhl, (0xf980:16)
	ld xwa, xbc
	sub xwa, xhl
	lda xde, (0xf460:16)
	ld xiy, xde
	add xiy, xwa
	ld w, (xiy)
	res 7, w
	ld a, (xbc)
	and a, 0x80
	ldfr_berp A, 0xe2
	ld a, w
	orb_erp A, 0xe2
	ld w, a
	ld (xbc), w
	lda xbc, (xix + 11)
	ld xwa, xbc
	sub xwa, xhl
	add xde, xwa
	ld w, (xde)
	and w, 0xc0
	ld a, (xbc)
	and a, 0x3f
	ldfr_berp A, 0xe2
	orb_erp W, 0xe2
	ld (xbc), w
	lda xbc, (0xfc5a:16)
	ld a, (xbc + 5)
	ldfr_berp A, 0xf8
	ld a, (xbc + 6)
	ldfr_berp A, 0xfa
	ldto_berp A, 0xf9
	ld (xbc + 8), a
	ldto_berp A, 0xfb
	ld (xbc + 9), a
	mrdb5 0x8f, 0x04, 0x19, 0x3a, 0x8d
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
	ld bc, 5:i3
	ld de, 0:i3
	call AddswbWr
	ld w, (xsp + 6)
	and w, 0x80
	lda xbc, (0xfd97:16)
	ld a, (xbc)
	res 7, a
	ld (xbc), a
	or a, w
	ld (xbc), a
	ld e, a
	extz de
	pushw 0x7f
	ldw wa, 0x98
	ld bc, 1:i3
	call AddswbWr
	ld e, (0xfda1:16)
	ld c, e
	and c, 0xc0
	ld a, (xsp + 8)
	and a, 0xc0
	xor a, c
	extz de
	extz wa
	pushw wa
	ldw wa, 0x98
	ldw bc, 0xb
	call AddswbWr
	lda xbc, (0xfc5a:16)
	ldto_berp A, 0xf8
	and a, 0x3f
	ld (xbc + 5), a
	ldto_berp A, 0xfa
	and a, 0x3c
	ld (xbc + 6), a
	call PartSelect_UpdateDisplayState
	call ToneGen_DispatchByMode
	call SwbtWr_NullRet
	pushw 0x0
	ldw wa, 0x48
	ld bc, 7:i3
	ld de, 0:i3
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
	ld bc, 3:i3
	ld de, 4:i3
	call AddswbWr
	ld wa, 2:i3
	call BitMapOut_GetRenderMode_Return
	pop xiz
	lda xsp, (xsp + 34)
	ret

SeqOut_WriteTimedBytes:
	push xiz
	ld iz, (xsp + 8)
	ei 6
	cp (0xb7e0:16), 0; zero means MIDI
	jr nz, SeqOut_WriteTimedBytes_CompIface
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, iz
	jr c, SeqOut_WriteTimedBytes_BufferFull
	ld xwa, (xsp + 10)
	push xwa
	pushw iz
	call SeqBuf_MidiOut_WriteBytes
	inc 6, xsp
	ldfr_werp HL, 0xfa
	call MIDI_SC0_ENABLE_TX
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_BufferFull:
	ldi_erpw 0xfa, 0xff, 0xff
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_CompIface:
	ld a, (0xc1e4:16)
	cp a, 2:i3
	jr z, SeqOut_WriteTimedBytes_PC2Timing
	cp a, 1:i3
	jr z, SeqOut_WriteTimedBytes_SerialWrite
	cp a, 0:i3
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
	ldfr_werp HL, 0xfa
	calr SeqBuf3_EnableTx_Stub
	jr MIDI_SeqProcess_DisableIntReturn

SeqOut_WriteTimedBytes_PC2Timing:
	call SeqBuf3_GetTimingValue
	ldfr_werp HL, 0xfa

MIDI_SeqProcess_DisableIntReturn:
	ei 0
	ldto_werp HL, 0xfa
	pop xiz
	ret

MidiSeq_ReceiveAndForward:
	pushw iz
	ldw iz, 0xffff
	ei 6
	cp (0xb7e0:16), 0; zero means MIDI
	jr nz, MidiSeq_ReceiveAndForward_CompIface
	ld xwa, (xsp + 8)
	ld a, (xwa)
	extz wa
	call MIDI_RX_BYTE_DISPATCHER
	call SeqMain_GetTimingValue
	ld iz, hl
	jr MidiSeq_ReceiveAndForward_Exit

MidiSeq_ReceiveAndForward_CompIface:
	ld a, (0xc1e4:16)
	cp a, 2:i3
	jr z, MidiSeq_ReceiveAndForward_PC2Forward
	cp a, 1:i3
	jr z, MidiSeq_ReceiveAndForward_SerialTiming
	cp a, 0:i3
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
	cp (xwa), 0xfe
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
	cp (0xb7e0:16), 0; zero means MIDI
	jr nz, MidiSeq_SendMultiByte_CompIface
	call SeqMain_GetTimingValue
	ld (xsp + 2), hl
	jrl MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_CompIface:
	ld a, (0xc1e4:16)
	ld iz, (xsp + 8)
	cp a, 1:i3
	jr z, MidiSeq_SendMultiByte_SerialCountInit
	cp a, 2:i3
	jr z, MidiSeq_SendMultiByte_PC2CountInit
	cp a, 0:i3
	jr nz, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_PC2CountInit:
	ld wa, iz
	dec 1, iz
	cp wa, 0:i3
	jr z, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_PC2SendLoop:
	ld xwa, (xsp + 10)
	ld a, (xwa)
	extz wa
	call MIDI_RX_BYTE_DISPATCHER
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, 1:i3
	jr lt, MidiSeq_SendMultiByte_PC2NextByte
	ld xwa, (xsp + 10)
	cp (xwa), 0xfe
	jr z, MidiSeq_SendMultiByte_PC2NextByte
	ld a, (xwa)
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ld (xsp + 2), hl
	call MIDI_SC0_ENABLE_TX

MidiSeq_SendMultiByte_PC2NextByte:
	ld xwa, 1:i3
	add (xsp + 10), xwa
	ld wa, iz
	dec 1, iz
	cp wa, 0:i3
	jr nz, MidiSeq_SendMultiByte_PC2SendLoop
	jr MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_SerialCountInit:
	ld wa, iz
	dec 1, iz
	cp wa, 0:i3
	jr z, MidiSeq_SendMultiByte_Exit

MidiSeq_SendMultiByte_SerialSendLoop:
	call SeqBuf_MidiOut_GetTimingValue
	cp hl, 1:i3
	jr lt, MidiSeq_SendMultiByte_SerialNextByte
	ld xwa, (xsp + 10)
	cp (xwa), 0xfe
	jr z, MidiSeq_SendMultiByte_SerialNextByte
	ld a, (xwa)
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ld (xsp + 2), hl
	call MIDI_SC0_ENABLE_TX

MidiSeq_SendMultiByte_SerialNextByte:
	ld xwa, 1:i3
	add (xsp + 10), xwa
	ld wa, iz
	dec 1, iz
	cp wa, 0:i3
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
	cp hl, 0xffff
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
	pushw Midi_BankProgramTemplate@hi16
	pushw Midi_BankProgramTemplate@lo16
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xbc, (xiz + 5)
	ld xde, xbc
	cpw (xsp + 10), 0xffff
	jr z, MidiSysEx_ApplyChannel
	ld a, (xsp + 14)
	and a, 0xf
	or (xiz), a
	ld de, (xsp + 10)
	sra de, 7
	ld xwa, (xsp + 4)
	ld (xwa + 2), e
	ld de, (xsp + 10)
	and de, 0x7f
	ld (xwa + 4), e
	ld xde, (xsp + 4)
	ldw (xsp + 8), 0x7

MidiSysEx_ApplyChannel:
	ld a, (xsp + 14)
	and a, 0xf
	or (xbc), a
	ld c, (xsp + 12)
	res 7, c
	ld xwa, (xsp + 4)
	ld (xwa + 6), c
	push xde
	pushm (xsp + 12)
	calr SeqOut_WriteTimedBytes
	ld (1060:16), 0
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
	pushw_erp 0xfa
	ld xiy, MIDI_BroadcastControlChange_Data
	lda xix, (xsp + 2)
	ld bc, 3:i3
	ldirw
	ldi85
	ldib_erp 0xfb, 0

MIDI_BroadcastCC_MidiOutLoop:
	ldto_berp A, 0xfb
	or a, 0xb0
	ld (xsp + 2), a
	ei 6
	lda xwa, (xsp + 2)
	push xwa
	pushw 0x7
	call SeqBuf_MidiOut_WriteBytes
	inc 6, xsp
	ei 0
	call MIDI_SC0_ENABLE_TX
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, MIDI_BroadcastCC_MidiOutLoop
	ldib_erp 0xfb, 0

MIDI_BroadcastCC_CommLoop:
	lda xde, (xsp + 2)
	ldto_berp A, 0xfb
	or a, 0xb0
	ld (xde), a
	ld wa, 4:i3
	ld bc, 7:i3
	call sendCOMM
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x0f
	jr ule, MIDI_BroadcastCC_CommLoop
	ld (1060:16), 0
	popw_erp 0xfa
	inc 8, xsp
	ret

CompIface_SendActiveSensing:
	ld a, (0xb7e0:16)
	cp	a, 0:i3	; MIDI
	ret z
	cp	a, 3:i3	;  PC2
	jr z, CompIface_SendActiveSensing_PC2
	cp	a, 2:i3	;  PC1
	jr z, CompIface_SendActiveSensing_PC1MAC
	cp	a, 1:i3	;  MAC
	ret nz

CompIface_SendActiveSensing_PC1MAC:
	push	sr
	ei 0
	ld wa, 4:i3
	ld bc, 1:i3
	ld xde, CompIface_SendActiveSensing_PC1MAC_Data	;	PC1 or MAC (0F5h)
	call sendCOMM
	pop	sr
	ret

CompIface_SendActiveSensing_PC2:
	push	sr
	ei 0
	ld wa, 4:i3
	ld bc, 1:i3
	ld xde, CompIface_SendActiveSensing_PC2_Data	;	PC2 (0F4h)
	call sendCOMM
	pop	sr
	ret

MidiOut_RealtimeDispatch_Data:
	.byte 0xc1, 0x80, 0xc0
	push	xsp
	cp	(xwa-80), iz
	.byte 0xc1
	jrl	pl, 16320
	ret
	ret	nz
	ld	a, (0xc07f:16)
	and	a, 3
	ret	z
	ld	a, (0xc07e:16)
	and	a, 3
	ld	(0xc1e4:16), a
	ret

MidiOut_SerializeAndSend:
	pushw iz
	ld iz, 0:i3
	cp (0xb7e0:16), 0; zero means MIDI
	jrl z, MidiOut_SerializeAndSend_Exit

MidiOut_SerializeRealtimeLoop:
	cp iz, 0x108
	jrl nc, MidiOut_FlushBuffer
	res 4, (1065:16)
	ld a, (1065:16)
	and a, 0x1f
	jr z, MidiOut_ReadSysExByte
	bit 0, (1065:16)
	jr z, MidiOut_CheckStart
	res 0, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, MidiOut_SerializeRealtimeLoop
	ld wa, iz
	inc 1, iz
	lda xbc, (0xc0d2:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xf8
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckStart:
	lda xwa, (0xc0d2:16)
	bit 1, (1065:16)
	jr z, MidiOut_CheckContinue
	res 1, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xfa
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckContinue:
	bit 2, (1065:16)
	jr z, MidiOut_CheckStop
	res 2, (1065:16)
	bit 4, (0xfd50:16)
	jr nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xfb
	jr MidiOut_SerializeRealtimeLoop

MidiOut_CheckStop:
	bit 3, (1065:16)
	jr z, MidiOut_SerializeRealtimeLoop
	res 3, (1065:16)
	bit 4, (0xfd50:16)
	jrl nz, MidiOut_SerializeRealtimeLoop
	ld bc, iz
	inc 1, iz
	extz xbc
	add xbc, xwa
	ld (xbc), 0xfc
	jrl MidiOut_SerializeRealtimeLoop

MidiOut_ReadSysExByte:
	call SeqBuf3_ReadByte
	cp hl, 0xffff
	jr z, MidiOut_FlushBuffer
	ld wa, iz
	inc 1, iz
	lda xbc, (0xc0d2:16)
	extz xwa
	add xwa, xbc
	ld (xwa), l
	cp l, 0xf7
	jrl nz, MidiOut_SerializeRealtimeLoop

MidiOut_FlushBuffer:
	cp iz, 0:i3
	jr z, MidiOut_SerializeAndSend_Exit
	ei 0
	ld wa, 4:i3
	ld bc, iz
	ld xde, 0xc0d2
	call sendCOMM

MidiOut_SerializeAndSend_Exit:
	popw iz
	ret

MidiThru_Disable:
	res 6, (0xb7e2:16)
	ret

MidiThru_Enable:
	set 6, (0xb7e2:16)
	ret

GET_COMPUTER_INTERFACE_SELECTION:
	ld l, (0xb7e0:16)
	ret

CompIface_ProcessInput:
	bit 3, (0xc1f0:16)
	jrl z, CompIface_RampControl
	bit 2, (1054:16)
	jr z, CompIface_FilterBySource
	bit 2, (1057:16)
	jr z, CompIface_FilterBySource
	bit 4, (0xc1f0:16)
	jr z, CompIface_CheckUpDown
	bit 5, (0xc1f0:16)
	jr z, CompIface_CheckUpDown
	cpw (0x28a8:16), 0
	jr nz, CompIface_SetPedalBit
	jr CompIface_CallFilterA

CompIface_CheckUpDown:
	bit 4, (0xc1f0:16)
	jr z, CompIface_RampDown
	call AccWrap_PlayModeStartPlay
	set 7, (0x34cd:16)
	jr CompIface_PostProcess

CompIface_RampDown:
	bit 5, (0xc1f0:16)
	jr z, CompIface_PostProcess
	cpw (0x28a8:16), 0
	jr z, CompIface_RampDown_Start
	set 1, (9834:16)

CompIface_RampDown_Start:
	call AccWrap_PlayModeStopExpr
	jr CompIface_CallSync

CompIface_FilterBySource:
	bit 2, (1054:16)
	jr z, CompIface_FromSource2
	bit 4, (0xc1f0:16)
	jr z, CompIface_PostProcess
	call AccWrap_PlayModeDispatch
	jr CompIface_PostProcess

CompIface_FromSource2:
	bit 2, (1057:16)
	jr z, CompIface_PostProcess
	bit 5, (0xc1f0:16)
	jr z, CompIface_PostProcess
	call SeqState_GetFlags
	and hl, 0x7
	jr z, CompIface_Source2_ZeroCheck
	call SqTrSel_CaseG
	jr CompIface_PostProcess

CompIface_Source2_ZeroCheck:
	cpw (0x28a8:16), 0
	jr z, CompIface_CallFilterA

CompIface_SetPedalBit:
	set 1, (9834:16)

CompIface_CallFilterA:
	call AccWrap_PlayModeDispatch

CompIface_CallSync:
	call SeqPlay_StopAndResetAll

CompIface_PostProcess:
	call AccompSeq_StopSequence
	bit 6, (0xc1f0:16)
	ret z
	ld wa, (1033:16)
	sub wa, (0xc1ea:16)
	cp wa, (0xc1fc:16)
	ret ule
	ld xwa, 0x40c1
	ld bc, 0:i3
	ld de, 3:i3
	call SoundParam_NotifyChange
	res 3, (0xc1f0:16)
	ldw wa, 0x4e
	call CtrlPanel_SetIndicatorLED
	ret

CompIface_RampControl:
	ld wa, (1033:16)
	ld bc, wa
	sub bc, (0xc1ea:16)
	bit 0, (0xc1f0:16)
	jr z, CompIface_RampDown_Apply
	cp bc, 0xf
	ret c
	ld (0xc1ea:16), wa
	ld bc, (0xc1ee:16)
	extz xbc
	ld wa, (0xc1f8:16)
	extz xwa
	add xbc, xwa
	cp xbc, 0x7f00
	jr le, CompIface_RampUp_Clamp
	ld xbc, 0x7f00

CompIface_RampUp_Clamp:
	ld (0xc1ee:16), bc
	srl bc, 8
	ld (0xc1ec:16), c
	extz bc
	ld xwa, 0x4005
	ld de, 1:i3
	call SoundParam_NotifyChange
	cp (0xc1ec:16), 127
	ret nz
	res 0, (0xc1f0:16)
	ld xwa, 0x40c0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	ret

CompIface_RampDown_Apply:
	bit 1, (0xc1f0:16)
	ret z
	cp bc, 0xf
	ret c
	ld (0xc1ea:16), wa
	ld bc, (0xc1ee:16)
	extz xbc
	ld wa, (0xc1fa:16)
	extz xwa
	sub xbc, xwa
	jr ge, CompIface_RampDown_Clamp
	ld xbc, 0:i3

CompIface_RampDown_Clamp:
	ld (0xc1ee:16), bc
	srl bc, 8
	ld (0xc1ec:16), c
	extz bc
	ld xwa, 0x4005
	ld de, 1:i3
	call SoundParam_NotifyChange
	cp (0xc1ec:16), 0
	ret nz
	res 1, (0xc1f0:16)
	set 3, (0xc1f0:16)
	ldw wa, 0x4e
	ld bc, 1:i3
	ld de, 0:i3
	call CtrlPanel_IndicatorDispatch
	ret

CompIface_ResetPedal:
	bit 2, (0xc1f0:16)
	ret z
	res 2, (0xc1f0:16)
	ldw wa, 0x4d
	call CtrlPanel_SetIndicatorLED
	set 0, (0xc1f0:16)
	ret

CompIface_SetMax:
	ldw wa, 0x7f
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
	ld w, 0x0:opc
	extz xwa
	ld xbc, 0x1d4c0
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
	ld w, 0x0:opc
	extz xwa
	ld xbc, 0x1ef0
	call Math_MultiplyAccumulate
	ld xwa, xhl
	ld xbc, xiz
	call Math_DivideU32
	ld xbc, xhl
	ld xwa, 0x7f00
	call Math_DivideU32
	pop xiz
	ret

CompIface_WriteVolume:
	ld c, (0xc1ec:16)
	cp c, a
	ret z
	ld (0xc1ec:16), a
	ld c, a
	extz bc
	sll bc, 8
	ld (0xc1ee:16), bc
	ld c, a
	extz bc
	ld xwa, 0x4005
	ld de, 3:i3
	call SoundParam_NotifyChange
	ret

Audio_ConfigureDSP:
	and (0xc1f0:16), 243
	and (0xc1f0:16), 252
	ld xwa, 0x40c0
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	ldw wa, 0x4d
	call CtrlPanel_SetIndicatorLED
	ld xwa, 0x40c1
	ld bc, 0:i3
	ld de, 1:i3
	call SoundParam_NotifyChange
	ldw wa, 0x4e
	call CtrlPanel_SetIndicatorLED
	ldw wa, 0x7f
	jr CompIface_WriteVolume
DSPCfg_ProcessInput:
	ld c, (0xc080:16)
	ld e, (0xc07d:16)
	cp c, 0x48
	jrl z, DSPCfg_ScaleFactor_Dispatch
	ld a, (0xc07f:16)
	cp c, 0x70
	jrl z, DSPCfg_CompressorDispatch
	cp c, 0x98
	ret nz
	cp e, 0xb
	ret nz
	ld c, a
	and a, 0xc0
	ret z
	bit 0, (0xc1f0:16)
	jr z, DSPCfg_Chorus_Active
	bit 7, c
	jr z, DSPCfg_Reverb_CheckSustain
	bit 7, (0xc07e:16)
	jr nz, DSPCfg_Reverb_CheckSustain
	res 0, (0xc1f0:16)

DSPCfg_Reverb_CheckSustain:
	bit 6, (0xc07f:16)
	jrl z, DSPCfg_UpdateOutputVolume
	bit 6, (0xc07e:16)
	jrl z, DSPCfg_UpdateOutputVolume
	res 0, (0xc1f0:16)
	jrl DSPCfg_SetFadeBit

DSPCfg_Chorus_Active:
	bit 2, (0xc1f0:16)
	jr z, DSPCfg_FadeOut_Active
	bit 7, c
	jr z, DSPCfg_Chorus_CheckSustain
	bit 7, (0xc07e:16)
	jr nz, DSPCfg_Chorus_CheckSustain
	res 2, (0xc1f0:16)
	ldw wa, 0x4d
	call CtrlPanel_SetIndicatorLED

DSPCfg_Chorus_CheckSustain:
	bit 6, (0xc07f:16)
	jrl z, DSPCfg_UpdateOutputVolume
	bit 6, (0xc07e:16)
	jrl z, DSPCfg_UpdateOutputVolume
	res 2, (0xc1f0:16)
	ldw wa, 0x4d
	call CtrlPanel_SetIndicatorLED
	set 1, (0xc1f0:16)
	ldw wa, 0x7f
	calr CompIface_WriteVolume
	jrl DSPCfg_UpdateOutputVolume

DSPCfg_FadeOut_Active:
	bit 1, (0xc1f0:16)
	jr z, DSPCfg_EQ_Active
	bit 7, c
	jr z, DSPCfg_FadeOut_CheckSustain
	bit 7, (0xc07e:16)
	jr z, DSPCfg_FadeOut_CheckSustain
	set 0, (0xc1f0:16)
	res 1, (0xc1f0:16)

DSPCfg_FadeOut_CheckSustain:
	bit 6, (0xc07f:16)
	jr z, DSPCfg_UpdateOutputVolume
	bit 6, (0xc07e:16)
	jr nz, DSPCfg_UpdateOutputVolume
	res 1, (0xc1f0:16)
	jr DSPCfg_UpdateOutputVolume

DSPCfg_EQ_Active:
	bit 3, (0xc1f0:16)
	jr z, DSPCfg_Idle_EnableChorus
	bit 7, c
	jr z, DSPCfg_EQ_CheckSustain
	bit 7, (0xc07e:16)
	jr z, DSPCfg_EQ_CheckSustain
	set 0, (0xc1f0:16)
	res 3, (0xc1f0:16)
	ldw wa, 0x4e
	call CtrlPanel_SetIndicatorLED

DSPCfg_EQ_CheckSustain:
	bit 6, (0xc07f:16)
	jr z, DSPCfg_UpdateOutputVolume
	bit 6, (0xc07e:16)
	jr nz, DSPCfg_UpdateOutputVolume
	res 3, (0xc1f0:16)
	ldw wa, 0x4e
	call CtrlPanel_SetIndicatorLED
	jr DSPCfg_UpdateOutputVolume

DSPCfg_Idle_EnableChorus:
	bit 7, c
	jr z, DSPCfg_Idle_CheckSustain
	bit 7, (0xc07e:16)
	jr z, DSPCfg_Idle_CheckSustain
	set 2, (0xc1f0:16)
	ldw wa, 0x4d
	ld bc, 1:i3
	ld de, 0:i3
	call CtrlPanel_IndicatorDispatch
	ld wa, 0:i3
	calr CompIface_WriteVolume

DSPCfg_Idle_CheckSustain:
	bit 6, (0xc07f:16)
	jr z, DSPCfg_UpdateOutputVolume
	bit 6, (0xc07e:16)
	jr z, DSPCfg_UpdateOutputVolume

DSPCfg_SetFadeBit:
	set 1, (0xc1f0:16)

DSPCfg_UpdateOutputVolume:
	ld a, (0xc1f0:16)
	and a, 0x3
	jr nz, DSPCfg_CheckChorusMuted
	ldw wa, 0x7f
	calr CompIface_WriteVolume

DSPCfg_CheckChorusMuted:
	bit 2, (0xc1f0:16)
	ret z
	ld wa, 0:i3
	calr CompIface_WriteVolume
	ret

DSPCfg_CompressorDispatch:
	ld c, a
	and a, 0xff
	cp e, 7:i3
	jr z, DSPCfg_CompParam_SubType7
	cp e, 6:i3
	jr z, DSPCfg_CompParam_SubType6
	cp e, 5:i3
	ret nz
	cp a, 0:i3
	ret z
	ld xwa, 0x2a00
	call SndParam_LookupReadOnly
	ld (0xc1f2:16), l
	extz hl
	ld bc, (0xc1f6:16)
	ld wa, hl
	calr CompIface_ScaleAndNormalize
	ld (0xc1f8:16), hl
	ret

DSPCfg_CompParam_SubType6:
	cp a, 0:i3
	ret z
	ld xwa, 0x2a01
	call SndParam_LookupReadOnly
	ld (0xc1f4:16), l
	extz hl
	ld bc, (0xc1f6:16)
	ld wa, hl
	calr CompIface_ScaleAndNormalize
	ld (0xc1fa:16), hl
	ld bc, (0xc1f6:16)
	ld wa, 1:i3
	jrl DSPCfg_ScaleFactor_StoreResult

DSPCfg_CompParam_SubType7:
	bit 0, c
	jr z, DSPCfg_CompParam_Bit1
	ld xwa, 0x2a10
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 4
	and (0xc1f0:16), 239
	or (0xc1f0:16), hl

DSPCfg_CompParam_Bit1:
	bit 1, (0xc07f:16)
	jr z, DSPCfg_CompParam_Bit2
	ld xwa, 0x2a11
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 5
	and (0xc1f0:16), 223
	or (0xc1f0:16), hl

DSPCfg_CompParam_Bit2:
	bit 2, (0xc07f:16)
	ret z
	ld xwa, 0x2a12
	call SndParam_LookupReadOnly
	and hl, 0x1
	sla hl, 6
	and (0xc1f0:16), 191
	or (0xc1f0:16), hl
	ret

DSPCfg_ScaleFactor_Dispatch:
	cp e, 0x9
	jr z, DSPCfg_ScaleFactor_Update
	cp e, 0x8
	ret nz

DSPCfg_ScaleFactor_Update:
	ld xwa, 4:i3
	call SndParam_LookupReadOnly
	ld (0xc1f6:16), hl
	ld a, (0xc1f2:16)
	extz wa
	ld bc, hl
	calr CompIface_ScaleAndNormalize
	ld (0xc1f8:16), hl
	ld a, (0xc1f4:16)
	extz wa
	ld bc, (0xc1f6:16)
	calr CompIface_ScaleAndNormalize
	ld (0xc1fa:16), hl
	ld bc, (0xc1f6:16)
	ld wa, 1:i3

DSPCfg_ScaleFactor_StoreResult:
	calr CompIface_ScaleValue
	ld (0xc1fc:16), hl
	ret

DSPCfg_LookupMidiMap:
	extz xwa
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	jp VoiceData_LookupPtrByIndex

DSPCfg_ExtractFieldPair:
	ld xix, xde
	ld xde, xwa
	ld w, (xix + 4)
	ld a, w
	and a, 0xf0
	ldfr_berp A, 0xf4
	extz iy
	and w, 0xf
	ld a, w
	extz wa
	cp wa, 2:i3
	jr nz, DSPCfg_ExtractAdjustType2
	ld l, (xix + 5)
	and l, 0x1f

DSPCfg_ExtractAdjustType2:
	ld (xde), iy
	ld (xbc), wa
	ret

DSPCfg_ExtractFieldSingle:
	ld l, (xde + 4)
	ld e, l
	and e, 0xf0
	ldfr_berp E, 0xf0
	extz ix
	and l, 0xf
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
	ldfr_berp A, 0xe6
	lda xwa, (xsp + 10)
	ld bc, (xsp + 12)
	ld hl, bc
	srl hl, 8
	cp_erpb 0xe6, 0x76
	jrl z, DSPCfg_WriteParam_Type76
	cp_erpb 0xe6, 0x70
	jr z, DSPCfg_WriteParam_Type70
	and c, 0xff
	cp_erpb 0xe6, 0x67
	jr z, DSPCfg_WriteParam_Type64_67
	cp_erpb 0xe6, 0x64
	jr z, DSPCfg_WriteParam_Type64_67
	ld wa, (xsp + 12)
	ld (xiz), a

DSPCfg_WriteParam_SetMask:
	ld e, 0xff:opc

DSPCfg_WriteParam_Exit:
	ld xwa, (xsp + 22)
	ld bc, (xsp + 4)
	ld (xwa), bc
	ld xwa, (xsp + 18)
	ld (xwa), e
	ld hl, 0:i3
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
	and a, 0xf8
	add a, e
	ld (xiz), a
	ld wa, (xsp + 12)
	sla wa, 6
	and a, 0xc0
	ld e, a
	ld a, (xbc)
	and a, 0x3f
	add a, e
	ld (xbc), a
	jr DSPCfg_WriteParam_SetMask7

DSPCfg_WriteParam_Type70_Sub10:
	ld wa, (xsp + 12)
	sla wa, 3
	and a, 0xf8
	ld c, a
	ld a, (xiz)
	and a, 0x7
	add a, c
	ld (xiz), a
	ld e, 0xf8:opc
	jr DSPCfg_WriteParam_Exit

DSPCfg_WriteParam_Type70_Sub20:
	ld wa, (xsp + 12)
	and a, 0x3f
	ld e, a
	ld a, (xbc)
	and a, 0xc0
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
	and a, 0xf8
	add a, c
	ld (xiz), a
	ld wa, (xsp + 12)
	sla wa, 6
	and a, 0xc0
	ld e, a
	lda xbc, (xiz + 1)
	ld a, (xbc)
	and a, 0x3f
	add a, e
	ld (xbc), a

DSPCfg_WriteParam_SetMask7:
	ld e, 0x7:opc
	jrl DSPCfg_WriteParam_Exit

DSPCfg_WriteParam_Type76_Sub10:
	ld wa, (xsp + 12)
	and a, 0x3f
	ld c, a
	cpw (xsp + 8), 0x2
	jr nz, DSPCfg_WriteParam_Type76_NotType2
	ld (xiz), c
	jr DSPCfg_WriteParam_SetMask3F

DSPCfg_WriteParam_Type76_NotType2:
	lda xde, (xiz + 1)
	ld a, (xde)
	and a, 0xc0
	add a, c
	ld (xde), a

DSPCfg_WriteParam_IncCounter:
	incw 1, (xsp + 4)

DSPCfg_WriteParam_SetMask3F:
	ld e, 0x3f:opc
	jrl DSPCfg_WriteParam_Exit

DSPCfg_PackAddress:
	ld e, (xwa + 1)
	and e, 0xff
	extz de
	ld c, (xwa)
	extz bc
	sll bc, 8
	ld hl, bc
	ld l, 0x0:opc
	add hl, de
	ld bc, hl
	srl bc, 8
	cp bc, 0xf0
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
	ldiw_erp 0xfa, 0
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
	ldfr_berp A, 0xee
	lda xwa, (xsp + 10)
	cp_erpb 0xee, 0x76
	jr z, DSPCfg_ReadField_Type76
	ld hl, iz
	cp_erpb 0xee, 0x70
	jr z, DSPCfg_ReadField_Type70
	cp_erpb 0xee, 0x68
	jr z, DSPCfg_ReadField_Type68_Unsigned
	cp_erpb 0xee, 0x67
	jr z, DSPCfg_ReadField_GoWidth2
	cp_erpb 0xee, 0x64
	jr z, DSPCfg_ReadField_GoWidth2
	ld l, (xbc)
	exts hl

DSPCfg_ReadField_SetWidth1:
	ldiw_erp 0xfa, 1

DSPCfg_ReadField_StoreAndReturn:
	ld xwa, (xsp + 12)
	ldto_werp BC, 0xfa
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
	and hl, 0xff
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
	and wa, 0x1f
	ld hl, wa
	cpw (xsp + 6), 0x1
	jr nz, DSPCfg_ReadField_StoreAndReturn
	jr DSPCfg_ReadField_SetWidth2

DSPCfg_ReadField_Type70_Width16:
	ldw wa, 0xb
	jr DSPCfg_ReadField_Type76_ShiftAndMask

DSPCfg_ReadField_Type70_Width32:
	ld hl, iz
	and hl, 0x3f

DSPCfg_ReadField_SetWidth2:
	ldiw_erp 0xfa, 2
	jr DSPCfg_ReadField_StoreAndReturn

DSPCfg_ReadField_Type76:
	lda xbc, (xsp + 8)
	calr DSPCfg_ExtractFieldPair
	ld wa, (xsp + 10)
	cp wa, 0x10
	jr z, DSPCfg_ReadField_Type76_Width16
	ld wa, 6:i3

DSPCfg_ReadField_Type76_ShiftAndMask:
	ld bc, iz
	and a, 0xf
	jr z, DSPCfg_ReadField_Type76_Mask5Bits
	srla bc

DSPCfg_ReadField_Type76_Mask5Bits:
	and bc, 0x1f
	ld hl, bc
	jr DSPCfg_ReadField_StoreAndReturn

DSPCfg_ReadField_Type76_Width16:
	cpw (xsp + 8), 0x2
	jr nz, DSPCfg_ReadField_Type70_Width32
	ld wa, iz
	srl wa, 8
	and wa, 0x3f
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
	ld bc, 0:i3
	cpw (xsp + 10), 0x0
	jr ule, DSPCfg_WriteMultiField_AdvanceAddr

DSPCfg_WriteMultiField_AccumXWA:
	ld xwa, 1:i3
	add (xsp + 14), xwa
	inc 1, bc
	cp bc, (xsp + 10)
	jr c, DSPCfg_WriteMultiField_AccumXWA

DSPCfg_WriteMultiField_AdvanceAddr:
	ld xwa, xiz
	calr DSPCfg_PackAddress
	ld xiz, xhl
	incw 1, (xsp + 4)
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
	retd 0xa

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
	ld wa, 0:i3
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
	incw 1, (xsp + 4)
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
	ld xbc, DSPCfg_ReadViaTableLookup_Data
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
	ld hl, 0:i3
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
	ld xbc, DSPCfg_ReadViaTableLookup_Data
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
	and c, 0xff
	ldfr_berp C, 0xf4
	extz iy
	ld c, (xwa)
	exts bc
	ld ix, bc
	sla ix, 8
	or ix, iy
	lda xiy, (xwa + 2)
	ld c, (xiy + 1)
	and c, 0xff
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
	ldfr_berp C, 0xf4
	ld c, (xwa)
	exts bc
	ld (xhl), ix
	ld (xde), iz
	ld xwa, (xsp + 10)
	ld (xwa), bc
	ld xbc, (xsp + 6)
	ldto_berp A, 0xf4
	ld (xbc), a
	popw iz
	retd 0x8

DSPCfg_LookupAndExtract:
	dec 8, xsp
	extz xbc
	sll xbc, 2
	ld xde, DSPCfg_LookupAndExtract_PtrTable
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

DSPCfg_Data_001:
	extz	xwa
	ld	xbc, DspCfg_Data001_ByteTable
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret

DSPCfg_GetSlotCount:
	extz xwa
	ld xbc, DSPCfg_GetSlotCount_Data
	add xbc, xwa
	ld l, (xbc)
	extz hl
	ret

DSPCfg_Data_002:
	extz	xwa
	ld	xbc, DspCfg_Data002_ByteTable
	add	xbc, xwa
	ld	l, (xbc)
	extz	hl
	ret

DSPCfg_FindSlot63:
	dec 2, xsp
	push xiz
	ld iz, wa
	ldw (xsp + 4), 0xffff
	ld wa, iz
	calr DSPCfg_GetSlotCount
	ldfr_werp HL, 0xfa
	ld wa, iz
	exts xwa
	sll xwa, 2
	ld xbc, DSPCfg_ReadViaTableLookup_Data
	add xbc, xwa
	ld xwa, (xbc)
	ld iz, 0:i3
	cpiw_erp 0xfa, 0
	jr le, DSPCfg_FindSlot63_Return

DSPCfg_FindSlot63_Loop:
	cp (xwa + 2), 0x63
	jr nz, DSPCfg_FindSlot63_Next
	ld (xsp + 4), iz

DSPCfg_FindSlot63_Next:
	calr DSPCfg_PackAddress
	ld xwa, xhl
	inc 1, iz
	cpw_erp IZ, 0xfa
	jr lt, DSPCfg_FindSlot63_Loop

DSPCfg_FindSlot63_Return:
	ld hl, (xsp + 4)
	pop xiz
	inc 2, xsp
	ret

DSPCfg_Data_003:
	dec	8, xsp
	push	xiz
	ld	iz, wa
	ld	xwa, xbc
	calr	DSPCfg_GetParamCount
	sla	hl, 2
	lda	xbc, (DSPCfg_LookupAndExtract_PtrTable:24)
	mul	iz, 6
	ld	xwa, xiz
	add	xwa, (xbc+hl)
	lda	xbc, (xsp+10)
	lda	xde, (xsp+8)
	lda	xhl, (xsp+4)
	push	xhl
	lda	xhl, (xsp+10)
	push	xhl
	calr	DSPCfg_ExtractPairFromStruct
	ldw	hl, 0xffff
	cp	(xsp+6), 1
	jr	nz, DSPCfg_FindSlot63_Epilogue
	ld	hl, 0:i3
DSPCfg_FindSlot63_Epilogue:
	pop	xiz
	inc	8, xsp
	ret
	cp	wa, 4:i3
	jr	ge, DSPCfg_FindSlot63_Skip
	cp	wa, 0:i3
	jr	lt, DSPCfg_FindSlot63_Skip
	ld	hl, 0:i3
	jr	DSPCfg_FindSlot63_Return2
DSPCfg_FindSlot63_Skip:
	ldw	hl, 0xffff
DSPCfg_FindSlot63_Return2:
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
	add xwa, DspParamId4900_ByteMap
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
	ldw (xwa), 0xffff
	ld xwa, (xsp + 10)
	ldw (xwa), 0xffff
	ldw (xsp + 4), 0xffff

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
	cp xiz, 0x4f00
	jr ugt, DSPCfg_ResolveParamToSlot_OutOfRange
	cp xiz, 0x4900
	jr nc, DSPCfg_ResolveParamToSlot_Range49

DSPCfg_ResolveParamToSlot_OutOfRange:
	ldw hl, 0xffff
	jrl DSPCfg_ResolveParamToSlot_StoreResult

DSPCfg_ResolveParamToSlot_Range49:
	cp xiz, 0x4a00
	jr nc, DSPCfg_ResolveParamToSlot_Range4A
	ldw (xsp + 8), 0x0
	ld wa, 0:i3
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
	cp xiz, 0x4b00
	jr nc, DSPCfg_ResolveParamToSlot_Range4B
	ldw (xsp + 8), 0x1
	ld wa, 1:i3
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
	cp xiz, 0x4c00
	jr nc, DSPCfg_ResolveParamToSlot_Range4C
	ldw (xsp + 8), 0x1
	ld wa, 1:i3
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
	cp xiz, 0x4d00
	jr nc, DSPCfg_ResolveParamToSlot_Range4D
	ldw (xsp + 8), 0x4
	ld wa, 4:i3
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
	cp xiz, 0x4e00
	jr nc, DSPCfg_ResolveParamToSlot_Range4E
	ldw (xsp + 8), 0x2
	ld wa, 2:i3
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
	ld wa, 3:i3
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
	retd 0xc

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
	cp hl, 0:i3
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
	cp iz, 0:i3
	jr z, DSPCfg_ResolveWithFallback_CheckType
	ld wa, (xsp + 10)
	extz xwa
	sll xwa, 2
	ld xbc, DSPCfg_ResolveWithFallback_Data
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 12), xwa
	ld wa, (xsp + 8)
	extz xwa
	add xwa, xwa
	ld xbc, DspCfg_ResolveFallback_WordTable
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
	cp bc, 1:i3
	jr z, DSPCfg_ResolveWithFallback_Type1
	cp bc, 0:i3
	jr nz, DSPCfg_ResolveWithFallback_UnknownType
	ld (xsp + 2), wa
	jr DSPCfg_ResolveWithFallback_Return

DSPCfg_ResolveWithFallback_Type1:
	ld wa, (xsp + 6)
	ld xbc, (xsp + 12)
	calr DSPCfg_ReadViaTableLookup
	ld (xsp + 2), hl
	ld xwa, (xsp + 16)
	cp xwa, 0x491d
	jr nz, DSPCfg_ResolveWithFallback_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_ResolveWithFallback_SndParam4003
	cp hl, 0xf
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
	ldw (xsp + 2), 0xffff

DSPCfg_ResolveWithFallback_Return:
	ld hl, (xsp + 2)
	popw iz
	lda xsp, (xsp + 18)
	ret

DSPCfg_ReadParam_Map0:
	ld bc, 0:i3
	jrl DSPCfg_ResolveWithFallback

DSPCfg_ReadParam_Map1:
	ld bc, 1:i3
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
	ld xbc, DSPCfg_LookupAndExtract_PtrTable
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
	ldw hl, 0xfffe
	ld wa, (xsp + 10)
	ld (xsp + 2), wa
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_CheckMax:
	ld wa, (xsp + 2)
	cp wa, (xsp + 8)
	jr le, DSPCfg_ClampAndExtract_InRange
	ldw hl, 0xfffd
	ld wa, (xsp + 8)
	ld (xsp + 2), wa
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_InRange:
	ld hl, 0:i3
	jr DSPCfg_ClampAndExtract_Return

DSPCfg_ClampAndExtract_NoSlot:
	ldw hl, 0xffff

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
	ld xhl, DSPCfg_ReadViaTableLookup_Data
	add xhl, xde
	ld xde, (xhl)
	or xde, xde
	jr z, DSPCfg_ValidateSlotForWrite_Invalid
	cp bc, 4:i3
	jr z, DSPCfg_ValidateSlotForWrite_Slot4
	cp bc, 3:i3
	jr z, DSPCfg_ValidateSlotForWrite_Slot3
	cp bc, 2:i3
	jr z, DSPCfg_ValidateSlotForWrite_Slot2
	cp bc, 1:i3
	jr z, DSPCfg_ValidateSlotForWrite_Slot1
	cp bc, 0:i3
	jr nz, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x10
	jr c, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0x1b
	jr ugt, DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Invalid:
	ldw hl, 0xffff

DSPCfg_ValidateSlotForWrite_Ret:
	ret

DSPCfg_ValidateSlotForWrite_Slot1:
	cp wa, 0x9
	jr z, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0xa
	jr z, DSPCfg_ValidateSlotForWrite_Valid
	cp wa, 0x10
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x1b
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot2:
	cp wa, 0x39
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x3c
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot3:
	cp wa, 0x58
	jr c, DSPCfg_ValidateSlotForWrite_Invalid
	cp wa, 0x5b
	jr ugt, DSPCfg_ValidateSlotForWrite_Invalid
	jr DSPCfg_ValidateSlotForWrite_Valid

DSPCfg_ValidateSlotForWrite_Slot4:
	cp wa, 0x4f
	jr nz, DSPCfg_ValidateSlotForWrite_Invalid

DSPCfg_ValidateSlotForWrite_Valid:
	ld hl, 0:i3
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
	cp iz, 0:i3
	jrl nz, DSPCfg_WriteParamFull_Return
	ld wa, (xsp + 2)
	cp wa, 1:i3
	jr z, DSPCfg_WriteParamFull_Type1
	cp wa, 0:i3
	jrl nz, DSPCfg_WriteParamFull_UnknownType
	ld wa, (xsp + 18)
	ld bc, (xsp + 6)
	calr DSPCfg_ValidateSlotForWrite
	ld iz, hl
	cp iz, 0xffff
	jrl z, DSPCfg_WriteParamFull_Return
	ld wa, (xsp + 18)
	ld xbc, (xsp + 14)
	calr DSPCfg_StoreByte_ReturnZero
	ld iz, hl
	ld wa, (xsp + 6)
	extz xwa
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld bc, (xsp + 18)
	ld b, 0x0:opc
	ld e, c
	extz de
	pushw 0xff
	ld bc, 0:i3
	call AssswbWr
	jrl DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_Type1:
	ld wa, (xsp + 8)
	ld bc, (xsp + 4)
	lda xde, (xsp + 18)
	calr DSPCfg_ClampAndExtract
	ld iz, hl
	cp iz, 0xffff
	jr z, DSPCfg_WriteParamFull_Check491D
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	cp iz, 0:i3
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
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 12)
	inc 1, c
	extz bc
	ld de, (xsp + 18)
	ld d, 0x0:opc
	extz de
	ld l, (xsp + 10)
	extz hl
	pushw hl
	call AssswbWr

DSPCfg_WriteParamFull_Check491D:
	ld xwa, (xsp + 20)
	cp xwa, 0x491d
	jr nz, DSPCfg_WriteParamFull_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_WriteParamFull_Notify4003
	cp hl, 0xf
	jr nz, DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_Notify4003:
	ld bc, (xsp + 18)
	ld xwa, 0x4003
	ld de, 3:i3
	call SoundParam_NotifyChange
	jr DSPCfg_WriteParamFull_Return

DSPCfg_WriteParamFull_UnknownType:
	ldw iz, 0xffff

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
	cp iz, 0:i3
	jrl nz, DSPCfg_WriteParamSimple_Return
	ld wa, (xsp + 2)
	cp wa, 1:i3
	jr z, DSPCfg_WriteParamSimple_Type1
	cp wa, 0:i3
	jrl nz, DSPCfg_WriteParamSimple_UnknownType
	ld wa, (xsp + 22)
	ld bc, (xsp + 6)
	calr DSPCfg_ValidateSlotForWrite
	ld iz, hl
	cp iz, 0xffff
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
	cp iz, 0xffff
	jr z, DSPCfg_WriteParamSimple_Check491D
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 10)
	cp iz, 0:i3
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
	cp xwa, 0x491d
	jr nz, DSPCfg_WriteParamSimple_Return
	ld xwa, 0x4900
	calr DSPCfg_ReadParam_Map0
	cp hl, 0x35
	jr z, DSPCfg_WriteParamSimple_Notify4003
	cp hl, 0xf
	jr nz, DSPCfg_WriteParamSimple_Return

DSPCfg_WriteParamSimple_Notify4003:
	ld bc, (xsp + 22)
	ld xwa, 0x4003
	ld de, 3:i3
	call SoundParam_NotifyChange
	jr DSPCfg_WriteParamSimple_Return

DSPCfg_WriteParamSimple_UnknownType:
	ldw iz, 0xffff

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
	cp hl, 0:i3
	jr nz, DSPCfg_WriteParamDelta_Return
	ld wa, (xsp + 2)
	cp wa, 1:i3
	jr z, DSPCfg_WriteParamDelta_Type1
	cp wa, 0:i3
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
	ldw hl, 0xffff

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
	ld wa, 1:i3
	ld xbc, (xsp + 16)
	calr DSPCfg_StoreByte_ReturnZero
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	pushw 0xff
	ld bc, 0:i3
	ld de, 1:i3
	call AssswbWr
	ld xwa, (xsp + 16)
	calr DSPCfg_GetParamCount
	ld (xsp + 6), hl
	ld wa, (xsp + 6)
	sla wa, 2
	lda xbc, (DSPCfg_ResolveWithFallback_Data:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 8), xwa
	ld iz, 0:i3
	jr DSPCfg_WriteAllSlots_Direct_CheckCount

DSPCfg_WriteAllSlots_Direct_Loop:
	ld wa, iz
	ld xbc, (xsp + 8)
	calr DSPCfg_ReadViaTableLookup
	ldfr_werp HL, 0xfa
	lda xwa, (xsp + 14)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	ld wa, iz
	ldto_werp BC, 0xfa
	ld xde, (xsp + 24)
	calr DSPCfg_WriteViaTableLookup
	ld wa, (xsp + 20)
	extz xwa
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 14)
	inc 1, c
	extz bc
	ldto_werp DE, 0xfa
	ld d, 0x0:opc
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
	ldiw_erp 0xfa, 0
	ld xwa, (xsp + 16)
	calr DSPCfg_GetParamCount
	ld (xsp + 4), hl
	ld wa, (xsp + 4)
	sla wa, 2
	lda xbc, (DSPCfg_ResolveWithFallback_Data:24)
	ld	xwa, (xbc+wa)
	ld (xsp + 6), xwa
	ld iz, 0:i3
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
	cp hl, 0:i3
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
	ld xbc, DspBlock_ObjectCode_Table
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld c, (xsp + 12)
	inc 1, c
	extz bc
	ld de, (xsp + 14)
	ld d, 0x0:opc
	extz de
	ld l, (xsp + 10)
	extz hl
	pushw hl
	call AssswbWr
	ldi_erpw 0xfa, 0xff, 0xff

DSPCfg_WriteAllSlots_Clamped_Next:
	inc 1, iz

DSPCfg_WriteAllSlots_Clamped_CheckCount:
	ld wa, (xsp + 4)
	calr DSPCfg_GetSlotCount
	cp iz, hl
	jr c, DSPCfg_WriteAllSlots_Clamped_Loop
	ldto_werp HL, 0xfa
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
	ldfr_werp HL, 0xfa
	ld wa, iz
	ld xbc, (xsp + 4)
	calr DSPCfg_WriteAllSlots_Clamped
	ldto_werp WA, 0xfa
	add wa, hl
	ldiw_erp 0xfa, 0
	cp wa, 0:i3
	jr z, DSPCfg_WriteAllSlots_Combined_Done
	ldi_erpw 0xfa, 0xff, 0xff

DSPCfg_WriteAllSlots_Combined_Done:
	ldto_werp HL, 0xfa
	pop xiz
	inc 4, xsp
	ret
DSPCfg_Data_ParamDispatch:
	lda	xsp, (xsp-0xe)
	push	xiz
	ld	(xsp+0xe), xde
	ld	xde, xbc
	ld	xbc, xwa
	ld	qiz, 0
	ldw	(xsp+0x8), 0
	ld	l, (xbc+0x1)
	extz	hl
	ld	a, (xbc)
	extz	wa
	ld	iz, wa
	sll	iz, 8
	add	iz, hl
	ld	xwa, (xsp+0x22)
	ld	a, (xwa)
	ld	(xsp+0x4), a
	ld	a, (xde+0x2)
	ld	(xsp+0x6), a
	lda	xwa, (xsp+0xc)
	cp	(xsp+0x6), 118
	jrl	z, DSPCfg_Data_ParamDispatch_Skip4
	ld	hl, iz
	cp	(xsp+0x6), 112
	jr	z, DSPCfg_Data_ParamDispatch_Skip2
	cp	(xsp+0x6), 103
	jr	z, DSPCfg_Data_ParamDispatch_Skip
	cp	(xsp+0x6), 100
	jr	z, DSPCfg_Data_ParamDispatch_Skip
	ld	l, (xbc)
	exts	hl
	ld	qiz, 1
DSPCfg_Data_ParamDispatch_Join:
	ld	e, 255:opc
DSPCfg_Data_ParamDispatch_Loop2:
	ld	xwa, (xsp+0xe)
	ld	bc, qiz
	ld	(xwa), bc
	ld	xwa, (xsp+0x22)
	ld	c, (xsp+0x4)
	ld	(xwa), c
	ld	xwa, (xsp+0x1e)
	ld	(xwa), e
	ld	xbc, (xsp+0x1a)
	ld	a, (xsp+0x6)
	ld	(xbc), a
	ld	xbc, (xsp+0x16)
	ld	wa, (xsp+0x8)
	ld	(xbc), a
	pop	xiz
	lda	xsp, (xsp+0xe)
	retd	16
DSPCfg_Data_ParamDispatch_Skip:
	ld	qiz, 2
	jr	DSPCfg_Data_ParamDispatch_Join
DSPCfg_Data_ParamDispatch_Skip2:
	lda	xbc, (xsp+0x8)
	calr	DSPCfg_ExtractFieldSingle
	ld	wa, (xsp+0xc)
	cp	wa, 32
	jr	z, DSPCfg_Data_ParamDispatch_Loop
	cp	wa, 16
	jr	z, DSPCfg_Data_ParamDispatch_Skip3
	ld	wa, iz
	srl	wa, 6
	and	wa, 31
	ld	hl, wa
	ld	e, 7:opc
	cpw	(xsp+0x8), 1
	jr	nz, DSPCfg_Data_ParamDispatch_Loop2
	ld	qiz, 1
	incm8	1, (xsp+0x4)
	jr	DSPCfg_Data_ParamDispatch_Loop2
DSPCfg_Data_ParamDispatch_Skip3:
	ld	wa, iz
	srl	wa, 11
	and	wa, 31
	ld	hl, wa
	ld	e, 248:opc
	jr	DSPCfg_Data_ParamDispatch_Loop2
DSPCfg_Data_ParamDispatch_Loop:
	ld	hl, iz
	and	hl, 63
	ld	qiz, 1
	incm8	1, (xsp+0x4)
DSPCfg_Data_ParamDispatch_Join5:
	ld	e, 63:opc
	jrl	DSPCfg_Data_ParamDispatch_Loop2
DSPCfg_Data_ParamDispatch_Skip4:
	lda	xbc, (xsp+0xa)
	calr	DSPCfg_ExtractFieldPair
	ld	wa, (xsp+0xc)
	cp	wa, 16
	jr	z, DSPCfg_Data_ParamDispatch_Skip8
	ld	wa, iz
	srl	wa, 6
	and	wa, 31
	ld	hl, wa
	ld	e, 7:opc
	jrl	DSPCfg_Data_ParamDispatch_Loop2
DSPCfg_Data_ParamDispatch_Skip8:
	cpw	(xsp+0xa), 2
	jr	nz, DSPCfg_Data_ParamDispatch_Loop
	ld	wa, iz
	srl	wa, 8
	and	wa, 63
	ld	hl, wa
	ld	qiz, 1
	jr	DSPCfg_Data_ParamDispatch_Join5
DSPCfg_Data_ParamDispatch_Helper:
	lda	xsp, (xsp-0x18)
	pushw	iz
	ld	(xsp+0x10), e
	ld	(xsp+0x12), xbc
	ld	(xsp+0x16), xwa
	ldw	(xsp+0xe), 0
	ldw	iz, 0xffff
	ld	(xsp+0xa), 0
	ld	(xsp+0x8), 122
	ld	xwa, (xsp+0x1e)
	ld	a, (xwa)
	ld	(xsp+0x2), a
DSPCfg_Data_ParamDispatch_Helper_Loop:
	inc	1, iz
	ld	wa, (xsp+0xe)
	add	(xsp+0xa), a
	ld	a, (xsp+0x8)
	ld	(xsp+0x4), a
	lda	xde, (xsp+0xe)
	lda	xwa, (xsp+0xa)
	push	xwa
	lda	xwa, (xsp+0x10)
	push	xwa
	lda	xwa, (xsp+0x10)
	push	xwa
	lda	xwa, (xsp+0x12)
	push	xwa
	ld	xwa, (xsp+0x26)
	ld	xbc, (xsp+0x22)
	calr	DSPCfg_Data_ParamDispatch
	ld	bc, 0:i3
	cpw	(xsp+0xe), 0
	jr	ule, DSPCfg_Data_ParamDispatch_Skip5
DSPCfg_Data_ParamDispatch_Helper_Loop2:
	ld	xwa, 1:i3
	add	(xsp+0x16), xwa
	inc	1, bc
	cp	bc, (xsp+0xe)
	jr	c, DSPCfg_Data_ParamDispatch_Helper_Loop2
DSPCfg_Data_ParamDispatch_Skip5:
	ld	xwa, (xsp+0x12)
	calr	DSPCfg_PackAddress
	ld	(xsp+0x12), xhl
	ld	a, (xsp+0xa)
	cp	a, (xsp+0x10)
	jr	ugt, DSPCfg_Data_ParamDispatch_Helper_Skip
	ld	a, (xsp+0xa)
	cp	a, (xsp+0x10)
	jr	nz, DSPCfg_Data_ParamDispatch_Helper_Loop
	ld	a, (xsp+0x2)
	and	a, (xsp+0xc)
	jr	z, DSPCfg_Data_ParamDispatch_Helper_Loop
DSPCfg_Data_ParamDispatch_Helper_Skip:
	ld	a, (xsp+0xa)
	cp	a, (xsp+0x10)
	jr	ule, DSPCfg_Data_ParamDispatch_Helper_Skip3
	cp	(xsp+0x4), 112
	jr	nz, DSPCfg_Data_ParamDispatch_Helper_Skip2
	dec	3, iz
	jr	DSPCfg_Data_ParamDispatch_Helper_Join
DSPCfg_Data_ParamDispatch_Helper_Skip2:
	dec	1, iz
DSPCfg_Data_ParamDispatch_Helper_Join:
	cp	(xsp+0x6), 1
	jr	nz, DSPCfg_Data_ParamDispatch_Helper_Skip3
	inc	1, iz
DSPCfg_Data_ParamDispatch_Helper_Skip3:
	ld	a, (xsp+0xc)
	cpl	a
	and	a, (xsp+0x2)
	ld	c, a
	ld	xwa, (xsp+0x1e)
	ld	(xwa), c
	ld	hl, iz
	popw	iz
	lda	xsp, (xsp+0x18)
	retd	4
EffEdit_DSPConfigBlock_Helper:
	lda	xsp, (xsp-0xa)
	push	xiz
	ld	(xsp+0xa), e
	ld	(xsp+0xc), c
	ldw	(xsp+0x4), 0
	extz	wa
	sub	wa, 97
	cp	wa, 0:i3
	jr	lt, DSPCfg_Data_ParamDispatch_Skip6
	cp	wa, 5:i3
	jr	gt, DSPCfg_Data_ParamDispatch_Skip6
	add	wa, wa
	lda	xix, (DspCfg_OpLetter_JumpOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (DSPCfg_Data_ParamDispatch_Code:24)
	jp	t, (xix+wa)
DSPCfg_Data_ParamDispatch_Code:
	ld	xiz, 0x4900
	ld	wa, 0:i3
	jr	DSPCfg_Data_ParamDispatch_Join3
	ld	xiz, 0x4a00
	jr	DSPCfg_Data_ParamDispatch_Join2
	ld	xiz, 0x4b00
DSPCfg_Data_ParamDispatch_Join2:
	ld	wa, 1:i3
	jr	DSPCfg_Data_ParamDispatch_Join3
	ld	xiz, 0x4c00
	ld	wa, 4:i3
	jr	DSPCfg_Data_ParamDispatch_Join3
	ld	xiz, 0x4d00
	ld	wa, 2:i3
	jr	DSPCfg_Data_ParamDispatch_Join3
	ld	xiz, 0x4e00
	ld	wa, 3:i3
	jr	DSPCfg_Data_ParamDispatch_Join3
DSPCfg_Data_ParamDispatch_Skip6:
	ldw	(xsp+0x4), 0xffff
DSPCfg_Data_ParamDispatch_Join3:
	cp	(xsp+12), 1
	jr	c, DSPCfg_Data_ParamDispatch_Join4
	cp	(xsp+12), 17
	jr	nc, DSPCfg_Data_ParamDispatch_Join4
	calr	DSPCfg_LookupMidiMap
	ld	(xsp+6), xhl
	ld	xwa, (xsp+6)
	calr	DSPCfg_GetParamCount
	extz	xhl
	sll	xhl, 2
	ld	xbc, DSPCfg_ReadViaTableLookup_Data
	add	xbc, xhl
	ld	xbc, (xbc)
	ld	xwa, 1:i3
	add	(xsp+6), xwa
	ld	e, (xsp+12)
	dec	1, e
	extz	de
	lda	xwa, (xsp+10)
	push	xwa
	ld	xwa, (xsp+10)
	calr	DSPCfg_Data_ParamDispatch_Helper
	cp	hl, 0xffff
	jr	nz, DSPCfg_Data_ParamDispatch_Skip7
	ldw	(xsp+4), 65535
	jr	DSPCfg_Data_ParamDispatch_Join4
DSPCfg_Data_ParamDispatch_Skip7:
	add	hl, 16
	exts	xhl
	add	xiz, xhl
DSPCfg_Data_ParamDispatch_Join4:
	ld	xwa, (xsp+18)
	ld	(xwa), xiz
	ld	hl, (xsp+4)
	pop	xiz
	lda	xsp, (xsp+10)
	retd	4

DSPCfg_CheckParamTableEntry:
	ld hl, 0:i3
	cp wa, 0x63
	jr ugt, DSPCfg_CheckParamTableEntry_NotFound
	extz xwa
	sll xwa, 2
	ld xbc, DSPCfg_ReadViaTableLookup_Data
	add xbc, xwa
	ld xwa, (xbc)
	or xwa, xwa
	ret nz

DSPCfg_CheckParamTableEntry_NotFound:
	ldw hl, 0xffff
	ret

DSPCfg_ReadFieldSimple:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), xde
	ld xde, xbc
	ld xbc, xwa
	ldiw_erp 0xfa, 0
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
	ldiw_erp 0xfa, 1

DSPCfg_ReadFieldSimple_StoreReturn:
	ld xwa, (xsp + 10)
	ldto_werp BC, 0xfa
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
	ldiw_erp 0xfa, 2
	jr DSPCfg_ReadFieldSimple_StoreReturn

DSPCfg_ApplyParamStruct:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xwa
	ld xiz, (xsp + 22)
	ld a, (xiz)
	extz wa
	ld (xsp + 4), wa
	lda xbc, (DSPCfg_GetSlotCount_Data:24)
	ld wa, (xsp + 4)
	ld	a, (xbc+wa)
	extz wa
	ld (xsp + 6), wa
	ld wa, (xsp + 4)
	calr DSPCfg_CheckParamTableEntry
	ld (xsp + 8), hl
	cpw (xsp + 8), 0x0
	jrl nz, DSPCfg_ApplyParamStruct_Return
	cpw (xsp + 4), 0x10
	jr lt, DSPCfg_ApplyParamStruct_Normal
	cpw (xsp + 4), 0x1b
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
	ld xbc, DSPCfg_ReadViaTableLookup_Data
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 14), xwa
	ldw (xsp + 12), 0x0
	ld wa, (xsp + 6)
	cp wa, 0:i3
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
	ld wa, 0:i3
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
	incw 1, (xsp + 12)
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
	cp de, 0xf
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
	ld xwa, 2:i3
	jr DSPCfg_ApplyParamStruct_WriteLoop

DSPCfg_ApplyParamStruct_Offset1:
	ld xwa, 1:i3

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
	ld xbc, DSPCfg_ReadViaTableLookup_Data
	add xbc, xwa
	ld xwa, (xbc)
	ld (xsp + 14), xwa
	ldw (xsp + 12), 0x0
	ld wa, (xsp + 6)
	cp wa, 0:i3
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
	ld w, 0x0:opc
	ld (xiz), a
	sra hl, 8
	ld h, 0x0:opc
	ld (xiz + 1), l

DSPCfg_ApplyParamStruct_WriteSkip2Byte:
	ld wa, 0:i3
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
	incw 1, (xsp + 12)
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
	ld E, (xwa+)
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
	cp de, 0x1b
	jr gt, DSPCfg_ApplyParamStructFull_RangeCheck
	cp de, 0x10
	jrl ge, DSPCfg_EventType10to1B

DSPCfg_ApplyParamStructFull_RangeCheck:
	ld bc, (xsp + 30)
	dec 1, bc
	cp bc, 0:i3
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
	lda xix, (DspConfig_EventDispatch_JumpOffsets:24)
	ld	bc, (xix+bc)
	lda xix, (AssSwb_SwapEntriesAndDispatch:24)
	jp	t, (xix+bc)

AssSwb_SwapEntriesAndDispatch:
	ldw (xsp + 4), 0xffff
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
	ld (xwa), 0x1e
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
	ldfr_berp C, 0xea
	ld xbc, (xsp + 60)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	ld xbc, (xsp + 56)
	ld c, (xbc)
	ldfr_berp C, 0xf0
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xf4
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xf8
	ld (xwa), d
	ldto_berp A, 0xea
	ld (xhl), a
	ld xbc, (xsp + 68)
	ldto_berp A, 0xeb
	ld (xbc), a
	ld xbc, (xsp + 64)
	ldto_berp A, 0xf0
	ld (xbc), a
	ld xbc, (xsp + 60)
	ldto_berp A, 0xf4
	ld (xbc), a
	ld xbc, (xsp + 56)
	ldto_berp A, 0xf8
	ld (xbc), a
	ld xwa, (xsp + 52)
	ld (xwa), 0x5b
	ld xwa, (xsp + 48)
	ld (xwa), 0x98
	ld xwa, (xsp + 44)
	ld (xwa), 0x5c
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
	mul e, 0xc
	extz de
	div e, 0x5
	ld c, 0x63:opc
	cp e, 0x63
	jr ugt, DSPCfg_EventType36_ClampResult
	ld c, e

DSPCfg_EventType36_ClampResult:
	ld (xwa), c
	ld xde, (xsp + 56)
	ld c, (xsp + 50)
	ld (xde), c
	ld xbc, (xsp + 52)
	ld (xbc), 0x3c
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
	ld (xiy), 0x5a
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
	ld (xiy), 0x5a
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
	ld (xwa), 0x5a
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
	ld (xwa), 0x5a
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
	ldfr_berp C, 0xea
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
	ldfr_berp C, 0xee
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	ld xbc, (xsp + 44)
	ld b, (xbc)
	ldto_berp C, 0xeb
	ld (xwa), c
	ld (xix), b
	ld xwa, (xsp + 68)
	ld (xwa), 0x40
	ld xwa, (xsp + 64)
	ld (xwa), d
	ld (xiy), l
	ld (xiz), 0xa
	ld xwa, (xsp + 52)
	ld (xwa), 0xa
	ld xwa, (xsp + 48)
	ld (xwa), 0x3c
	ld xwa, (xsp + 44)
	ld (xwa), e
	ld xbc, (xsp + 40)
	ldto_berp A, 0xee
	ld (xbc), a
	ld xwa, (xsp + 36)
	ld (xwa), 0x48
	ld xwa, (xsp + 32)
	ld (xwa), 0x4f
	ld xwa, (xsp + 60)
	ldto_berp C, 0xea
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
	ld (xde), 0x5a
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
	ldfr_berp C, 0xea
	ld xbc, (xsp + 60)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	ld xbc, (xsp + 56)
	ld c, (xbc)
	ldfr_berp C, 0xf0
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xf4
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xf8
	ld (xwa), d
	ldto_berp A, 0xea
	ld (xhl), a
	ld xbc, (xsp + 68)
	ldto_berp A, 0xeb
	ld (xbc), a
	ld xbc, (xsp + 64)
	ldto_berp A, 0xf0
	ld (xbc), a
	ld xbc, (xsp + 60)
	ldto_berp A, 0xf4
	ld (xbc), a
	ld xbc, (xsp + 56)
	ldto_berp A, 0xf8
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
	ldfr_berp C, 0xea
	ld xbc, (xsp + 68)
	ld c, (xbc)
	ldfr_berp C, 0xee
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xe6
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
	ldfr_berp C, 0xe7
	ld xiz, (xsp + 36)
	ld c, (xiz)
	ldfr_berp C, 0xeb
	ld xiz, (xsp + 32)
	ld c, (xiz)
	ldfr_berp C, 0xef
	ldto_berp C, 0xee
	ld (xwa), c
	ld xiz, (xsp + 56)
	ldto_berp A, 0xe6
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
	ldto_berp C, 0xe7
	ld (xwa), c
	ld xwa, (xsp + 44)
	ldto_berp C, 0xeb
	ld (xwa), c
	ld xwa, (xsp + 40)
	ldto_berp C, 0xef
	ld (xwa), c
	ld xwa, (xsp + 36)
	ld (xwa), 0x0
	ld xwa, (xsp + 32)
	ld c, (xsp + 6)
	ld (xwa), c
	ld xwa, (xsp + 60)
	ldto_berp C, 0xea
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
	ldfr_berp C, 0xea
	ld xbc, (xsp + 52)
	ld c, (xbc)
	ldfr_berp C, 0xee
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	ld xbc, (xsp + 44)
	ld h, (xbc)
	lda xbc, (xwa + 9)
	ld (xsp + 20), xbc
	ld c, (xbc)
	ldfr_berp C, 0xef
	ld xbc, (xsp + 36)
	ld c, (xbc)
	ldfr_berp C, 0xf0
	ld xbc, (xsp + 32)
	ld b, (xbc)
	ld xiy, (xsp + 60)
	ld c, (xiy)
	ldfr_berp C, 0xe6
	ld (xwa), e
	ld xwa, (xsp + 40)
	ld (xwa), l
	ld xiy, (xsp + 68)
	ld (xiy), d
	ld xiy, (xsp + 64)
	ldto_berp A, 0xea
	ld (xiy), a
	ld xiy, (xsp + 28)
	ldto_berp A, 0xee
	ld (xiy), a
	ldto_berp C, 0xeb
	ld xwa, (xsp + 24)
	ld (xwa), c
	ld xwa, (xsp + 52)
	ld (xwa), h
	ld xwa, (xsp + 48)
	ldto_berp C, 0xef
	ld (xwa), c
	ld xwa, (xsp + 44)
	ld (xwa), 0x50
	ldto_berp C, 0xf0
	ld xwa, (xsp + 20)
	ld (xwa), c
	ld xwa, (xsp + 36)
	ld (xwa), b
	ld xwa, (xsp + 32)
	ldto_berp C, 0xe6
	ld (xwa), c
	ld xwa, (xsp + 60)
	ld (xwa), 0x5a
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
	ldfr_berp C, 0xea
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
	ldfr_berp C, 0xee
	ld xbc, (xsp + 44)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	lda xbc, (xwa + 9)
	ld (xsp + 24), xbc
	ld c, (xbc)
	ldfr_berp C, 0xef
	ld xbc, (xsp + 36)
	ld c, (xbc)
	ldfr_berp C, 0xf0
	lda xbc, (xwa + 11)
	ld (xsp + 20), xbc
	ld c, (xbc)
	ldfr_berp C, 0xf4
	ld xbc, (xsp + 60)
	ld b, (xbc)
	ldto_berp C, 0xea
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
	ldto_berp A, 0xee
	ld (xiz), a
	ld xiz, (xsp + 52)
	ldto_berp A, 0xeb
	ld (xiz), a
	ld xwa, (xsp + 48)
	ldto_berp C, 0xef
	ld (xwa), c
	ld xwa, (xsp + 44)
	ld (xwa), 0x50
	ldto_berp C, 0xf0
	ld xwa, (xsp + 24)
	ld (xwa), c
	ld xwa, (xsp + 36)
	ldto_berp C, 0xf4
	ld (xwa), c
	ld xwa, (xsp + 20)
	ld (xwa), b
	ld xwa, (xsp + 60)
	ld (xwa), 0x5a
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
	ldfr_berp C, 0xee
	ld xbc, (xsp + 64)
	ld c, (xbc)
	ldfr_berp C, 0xea
	lda xix, (xwa + 4)
	ld h, (xix)
	lda xiy, (xwa + 5)
	ld d, (xiy)
	ld xbc, (xsp + 52)
	ld l, (xbc)
	ld xbc, (xsp + 48)
	ld c, (xbc)
	ldfr_berp C, 0xeb
	ld xbc, (xsp + 44)
	ld c, (xbc)
	ldfr_berp C, 0xef
	ld (xwa), 0x2
	ld xbc, (xsp + 60)
	ld (xbc), 0x0
	ld xbc, (xsp + 68)
	ld (xbc), 0x63
	ld xiz, (xsp + 64)
	ldto_berp C, 0xee
	ld (xiz), c
	ldto_berp C, 0xea
	ld (xix), c
	ld (xiy), h
	ld xbc, (xsp + 52)
	ld (xbc), d
	ld xbc, (xsp + 48)
	ld (xbc), l
	ld xix, (xsp + 44)
	ldto_berp C, 0xeb
	ld (xix), c
	ldto_berp C, 0xef
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
	ldfr_berp C, 0xe7
	ld xde, (xsp + 68)
	ld c, (xde)
	ldfr_berp C, 0xeb
	ld xhl, (xsp + 64)
	ld c, (xhl)
	ldfr_berp C, 0xee
	lda xix, (xwa + 4)
	ld (xsp + 40), xix
	ld c, (xix)
	ldfr_berp C, 0xea
	lda xix, (xwa + 5)
	ld (xsp + 32), xix
	ld c, (xix)
	ldfr_berp C, 0xe6
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
	ld (xwa), 0x5b
	ld xiz, (xsp + 44)
	ld (xiz), 0x98
	ld xiz, (xsp + 68)
	ldto_berp C, 0xeb
	ld (xiz), c
	ld xiz, (xsp + 64)
	ldto_berp C, 0xee
	ld (xiz), c
	ld xiz, (xsp + 40)
	ldto_berp C, 0xea
	ld (xiz), c
	ld xiz, (xsp + 32)
	ldto_berp C, 0xe6
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
	ldto_berp C, 0xe7
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
	ldfr_berp C, 0xea
	lda xbc, (xwa + 3)
	ld (xsp + 48), xbc
	ld h, (xbc)
	lda xbc, (xwa + 4)
	ld (xsp + 44), xbc
	ld d, (xbc)
	lda xbc, (xwa + 5)
	ld (xsp + 40), xbc
	ld c, (xbc)
	ldfr_berp C, 0xee
	ld xbc, (xsp + 52)
	ld e, (xbc)
	lda xbc, (xwa + 7)
	ld (xsp + 32), xbc
	ld c, (xbc)
	ldfr_berp C, 0xeb
	lda xbc, (xwa + 8)
	ld (xsp + 28), xbc
	ld c, (xbc)
	ldfr_berp C, 0xe7
	lda xix, (xwa + 9)
	ld c, (xix)
	ldfr_berp C, 0xe6
	ld xiy, (xsp + 36)
	ld b, (xiy)
	ld xiy, (xsp + 56)
	ld (xiy), 0x63
	ld (xwa), 0x5b
	ld xiy, (xsp + 64)
	ld (xiy), 0x98
	ld xiy, (xsp + 68)
	ldto_berp C, 0xea
	ld (xiy), c
	ld xiy, (xsp + 48)
	ld (xiy), h
	ld xiy, (xsp + 44)
	ld (xiy), d
	ld xiy, (xsp + 40)
	ldto_berp C, 0xee
	ld (xiy), c
	ld xiy, (xsp + 52)
	ld (xiy), e
	ld xiy, (xsp + 32)
	ldto_berp C, 0xeb
	ld (xiy), c
	ldto_berp C, 0xe7
	ld xde, (xsp + 28)
	ld (xde), c
	ldto_berp C, 0xe6
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
	ldw	hl, 0xffff
	ret
	ldw	hl, 0xffff
	ret
	ldw	hl, 256
	ret
	ldw	hl, 256
	ret


	.include "boot/screen_group_dispatch.s"

AudioInit_ProcessModeChange:
	ld wa, (0xc594:16)
	bit 2, wa
	ret z
	call Audio_CheckInitStatus
	andw (0xc594:16), 0xfffb
	bit 1, (0xfc67:16)
	jr z, AudioModeChange_Handler
	ld wa, (0xc594:16)
	bit 4, wa
	jr nz, AudioModeChange_ClearVoiceFlags
	set 2, (0xc1fe:16)
	jr AudioModeChange_Handler

AudioModeChange_ClearVoiceFlags:
	ld (0xc1fe:16), 0

; Audio mode change handler
AudioModeChange_Handler:
	res 3, (0xc1fe:16)
	ld (0xc2b4:16), 255
	ld (0xc2bc:16), 255
	ld (0xc200:16), 255
	ld (0xc201:16), 255
	orw (0xc59c:16), 257
	ld a, (0x8d34:16)
	extz wa
	sla wa, 2
	lda xbc, (AudioModeChange_Handler_Data:24)
	ld	xhl, (xbc+wa)
	ld xbc, xhl
	lda xwa, (AudioInit_MixFallbackDefault_Code:24)
	cp xwa, xbc
	ret z
	ld wa, 0:i3
	call (xhl)
	call AudioInit_DrumRoutingCheck
	call AudioInit_DrumSaveReturn
	call AudioInit_VoiceParamCtrl
	call AudioInit_ClearPartFlags_ByMode
	call AudioInit_DispatchChanges
	ret

Audio_CheckSubsystemReady:
	call Audio_CheckInitStatus
	ld wa, (0xc598:16)
	and wa, 0x60
	call z, (AudioInit_RefreshToneBank:24)
	bit 1, (0xfc67:16)
	jr z, AudioSubsystem_Callback
	ld wa, (0xc594:16)
	bit 4, wa
	jr nz, AudioSubsystem_ClearVoiceFlags
	set 2, (0xc1fe:16)
	jr AudioSubsystem_Callback

AudioSubsystem_ClearVoiceFlags:
	ld (0xc1fe:16), 0

; Audio subsystem callback
AudioSubsystem_Callback:
	res 3, (0xc1fe:16)
	ld (0xc2b4:16), 255
	ld (0xc2bc:16), 255
	ld (0xc200:16), 255
	ld (0xc201:16), 255
	orw (0xc59c:16), 257
	ld a, (0x8d34:16)
	extz wa
	sla wa, 2
	lda xbc, (AudioModeChange_Handler_Data:24)
	ld	xhl, (xbc+wa)
	ld xbc, xhl
	lda xwa, (AudioInit_MixFallbackDefault_Code:24)
	cp xwa, xbc
	ret z
	ld wa, 0:i3
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
	cp a, 0:i3
	jr z, AudioDispatch_ClearAccFlags
	ld wa, (0xc598:16)
	bit 2, wa
	jr z, AudioDispatch_SetAccMode
	bit 0, (0x28b2:16)
	jr z, AudioDispatch_SetAccMode

AudioDispatch_ClearAccFlags:
	andw (0xc596:16), 0xfdff
	res 0, (0x3284:16)
	call AudioInit_RefreshToneBank
	ld (0xc5a0:16), 0
	jr AudioDispatch_CheckStereoMode

AudioDispatch_SetAccMode:
	orw (0xc596:16), 512
	call AccAutoPlay_PeriodicCheck
	ld wa, (0xc596:16)
	and wa, 0x7
	jr z, AudioDispatch_SetTimerBase
	ld (0xc5a0:16), 31
	jr AudioDispatch_CheckStereoMode

AudioDispatch_SetTimerBase:
	ld (0xc5a0:16), 16

AudioDispatch_CheckStereoMode:
	bit 1, (0xfc67:16)
	jr z, AudioVoice_Callback
	ld wa, (0xc594:16)
	bit 4, wa
	jr nz, AudioDispatch_ClearVoiceFlags
	set 2, (0xc1fe:16)
	jr AudioDispatch_SetBusyFlag

AudioDispatch_ClearVoiceFlags:
	ld (0xc1fe:16), 0

AudioDispatch_SetBusyFlag:
	orw (0xc59c:16), 1

; Audio voice callback dispatch
AudioVoice_Callback:
	ld a, (0x8d34:16)
	extz wa
	sla wa, 2
	lda xbc, (AudioModeChange_Handler_Data:24)
	ld	xhl, (xbc+wa)
	ld xbc, xhl
	lda xwa, (AudioInit_MixFallbackDefault_Code:24)
	cp xwa, xbc
	jr z, AudioVoice_SkipToDispatch
	ld wa, 0:i3
	call (xhl)
	call AudioInit_ClearPartFlags_ByMode

AudioVoice_SkipToDispatch:
	jp AudioInit_DispatchChanges

AudioMode_SetStereoFlags:
	bit 0, (0xfc69:16)
	ret z
	orw (0xc596:16), 128
	orw (0xc594:16), 4
	calr AudioInit_ProcessModeChange
	ret

AudioMode_ResetVoiceState:
	bit 1, (0xfc67:16)
	jr z, AudioVoiceReset_Handler
	ld wa, (0xc594:16)
	bit 4, wa
	jr nz, AudioVoiceReset_ClearFlags
	set 2, (0xc1fe:16)
	jr AudioVoiceReset_Handler

AudioVoiceReset_ClearFlags:
	ld (0xc1fe:16), 0

; Audio voice reset handler
AudioVoiceReset_Handler:
	res 3, (0xc1fe:16)
	ld (0xc2b4:16), 255
	ld (0xc2bc:16), 255
	ld (0xc200:16), 255
	ld (0xc201:16), 255
	orw (0xc59c:16), 257
	andw (0xc594:16), 0xfffd
	ld a, (0x8d34:16)
	extz wa
	sla wa, 2
	lda xbc, (AudioModeChange_Handler_Data:24)
	ld	xhl, (xbc+wa)
	ld xbc, xhl
	lda xwa, (AudioInit_MixFallbackDefault_Code:24)
	cp xwa, xbc
	ret z
	ld wa, 1:i3
	call (xhl)
	call AudioInit_DrumRoutingCheck
	call AudioInit_DrumSaveReturn
	call AudioInit_VoiceParamCtrl
	call AudioInit_ClearPartFlags_ByMode
	call AudioInit_DispatchChanges
	ret

AudioMode_ConfigureExternal:
	ld (0xc1fe:16), 0
	cp a, 0:i3
	jr z, AudioMode_ConfigExternal_Off
	orw (0xc594:16), 16
	jr AudioMode_ConfigExternal_Apply

AudioMode_ConfigExternal_Off:
	andw (0xc594:16), 0xffef
	bit 0, (0xfc66:16)
	jr z, AudioMode_ConfigExternal_CheckBit1
	set 0, (0xc1fe:16)

AudioMode_ConfigExternal_CheckBit1:
	bit 1, (0xfc66:16)
	jr z, AudioMode_ConfigExternal_CheckStereo
	set 1, (0xc1fe:16)

AudioMode_ConfigExternal_CheckStereo:
	bit 1, (0xfc67:16)
	jr z, AudioMode_ConfigExternal_NoStereo
	orw (0xc596:16), 32
	jr AudioMode_ConfigExternal_MergeFlags

AudioMode_ConfigExternal_NoStereo:
	andw (0xc596:16), 0xffdf
	ld wa, (0xc596:16)
	and wa, 0x7
	call z, (AudioInit_RefreshToneBank:24)

AudioMode_ConfigExternal_MergeFlags:
	res 2, (0xc1fe:16)
	ld a, (0xfc67:16)
	and a, 0x2
	ld c, a
	add a, c
	or (0xc1fe:16), a

AudioMode_ConfigExternal_Apply:
	orw (0xc594:16), 4
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
	cp (0xc080:16), 24
	ret ugt
	ld l, (0xc080:16)
	ld h, (0xc07d:16)
	ld e, (0xc07f:16)
	ld d, (0xc07e:16)
	ld a, l
	extz wa
	sla wa, 2
	lda xbc, (UIState_ProcessMidiEvent_Data:24)
	ld	xwa, (xbc+wa)
	ld a, h
	cp a, 0x16
	jrl z, UIStateEvt_TransposeUpdate
	cp a, 0xd
	jr z, UIStateEvt_VoiceAssign
	cp a, 0xc
	jr z, UIStateEvt_PartRouting
	cp a, 0:i3
	ret nz
	ld a, e
	and a, 0xff
	ret z
	orw (0xc594:16), 4
	ret

UIStateEvt_PartRouting:
	ld a, e
	and a, 0x7
	ret z
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	add wa, wa
	ld hl, wa
	add hl, 0x124
	lda xix, (0xc1fe:16)
	ld a, d
	and a, 0x7
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data_2:24)
	ld	a, (xbc+wa)
	and a, 0x7
	sla a, 1
	and	(xix+hl), 0xf1
	or	(xix+hl), a
	orw (0xc594:16), 4
	ret

UIStateEvt_VoiceAssign:
	ld a, e
	and a, 0xf
	jr z, UIStateEvt_ToneChange
	bit 6, d
	jr nz, UIStateEvt_VoiceAssign_Reset
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc222:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, d
	and a, 0xf
	ld (xix), a
	jr UIStateEvt_VoiceAssign_Notify

UIStateEvt_VoiceAssign_Reset:
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc222:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff

UIStateEvt_VoiceAssign_Notify:
	orw (0xc59c:16), 2048
	orw (0xc594:16), 4

UIStateEvt_ToneChange:
	bit 5, e
	jr z, UIStateEvt_DrumAssign
	bit 5, d
	jr z, UIStateEvt_ToneChange_Set
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc202:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	cp l, 0x13
	jr nz, Tone_WriteEndMarker
	ld (0xc218:16), 255
	jr Tone_WriteEndMarker

UIStateEvt_ToneChange_Set:
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc202:16)
	ld ix, wa
	extz xix
	add xix, xbc
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	ld (xix), a
	cp l, 0x13
	jr nz, Tone_WriteEndMarker
	ld (0xc218:16), 22

Tone_WriteEndMarker:
	orw (0xc59c:16), 4
	orw (0xc594:16), 4

UIStateEvt_DrumAssign:
	bit 6, e
	ret z
	bit 6, d
	jr z, UIStateEvt_DrumAssign_Set
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc222:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	jr UIStateEvt_DrumAssign_Notify

UIStateEvt_DrumAssign_Set:
	ld a, l
	extz wa
	lda xbc, (UIStateEvt_PartRouting_Data:24)
	ld	a, (xbc+wa)
	extz wa
	lda xbc, (0xc222:16)
	ld de, wa
	extz xde
	add xde, xbc
	ld a, l
	extz wa
	sla wa, 2
	lda xbc, (UIState_ProcessMidiEvent_Data:24)
	ld	xwa, (xbc+wa)
	ld a, (xwa + 13)
	and a, 0xf
	ld (xde), a

UIStateEvt_DrumAssign_Notify:
	orw (0xc59c:16), 8
	orw (0xc594:16), 4
	ret
UIStateEvt_TransposeUpdate:
	bit	0, e
	ret	z
	bit	0, d
	jr	z, UIStateEvt_TransposeUpdate_Clear
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	add	wa, wa
	ld	bc, wa
	add	bc, 228
	lda_d16	xde, (0xc1ff)
	ldb_d8	a, (0xfc6a)
	and	a, 255
	sub	a, 64
	ld	(xde+bc), a
	jr	UIStateEvt_TransposeUpdate_Apply
UIStateEvt_TransposeUpdate_Clear:
	ld	a, l
	extz	wa
	lda	xbc, (PartIndex_ByteMap:24)
	ld	a, (xbc+wa)
	extz	wa
	add	wa, wa
	add	wa, 228
	lda_d16	xbc, (0xc1ff)
	ld	(xbc+wa), 0x00
UIStateEvt_TransposeUpdate_Apply:
	orw	(0xc594:16), 4
	ret
UIStateEvt_ParamEdit_Data:
	pushw	iz
	ldb_d8	a, (0xc07d)
	extz	wa
	cp	wa, 0:i3
	jrl	mi, UIStateEvt_ParamEdit_Data_Epilogue
	cp	wa, 6:i3
	jrl	gt, UIStateEvt_ParamEdit_Data_Epilogue
	add	wa, wa
	lda	xix, (ParamEdit_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (UIStateEvt_TransposeUpdate_Apply_Code:24)
	jp	t, (xix+wa)
UIStateEvt_TransposeUpdate_Apply_Code:
	ldb_d8	a, (0xc07f)
	and	a, 7
	jrl	z, UIStateEvt_ParamEdit_Data_Entry
	ldw_d16	wa, (0xc598)
	bit	6, wa
	jr	z, UIStateEvt_ParamEdit_Data_Skip
	ldb_d8	a, (0xfc5e)
	and	a, 7
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	ld	iz, (xbc+wa)
	ldb_d8	a, (0xfc5d)
	and	a, 8
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	or	iz, (xbc+wa)
	jr	UIStateEvt_ParamEdit_Data_Join
UIStateEvt_ParamEdit_Data_Skip:
	ldw_d16	wa, (0xc598)
	and	wa, 34
	cp	wa, 32
	jr	nz, UIStateEvt_ParamEdit_Data_Skip2
	ld	iz, 2:i3
	ldb_d8	a, (0xfc5d)
	and	a, 8
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	or	iz, (xbc+wa)
	jr	UIStateEvt_ParamEdit_Data_Join
UIStateEvt_ParamEdit_Data_Skip2:
	ldb_d8	a, (0xfc5d)
	and	a, 15
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	ld	iz, (xbc+wa)
UIStateEvt_ParamEdit_Data_Join:
	ldw_d16	wa, (0xc596)
	and	wa, 6
	jr	z, UIStateEvt_ParamEdit_Data_Skip3
	ld	wa, iz
	and	wa, 6
	jr	z, UIStateEvt_ParamEdit_Data_Skip3
	ldw_d16	wa, (0xc596)
	and	wa, 7
	jr	nz, UIStateEvt_ParamEdit_Data_Skip4
UIStateEvt_ParamEdit_Data_Skip3:
	call	AudioInit_RefreshToneBank
UIStateEvt_ParamEdit_Data_Skip4:
	andw	(0xc596:16), 0xffe8
	or	(0xc596:16), iz
	orw	(0xc594:16), 4
	ldw_d16	wa, (0xc596)
	and	wa, 7
	jr	z, UIStateEvt_ParamEdit_Data_Skip5
	ld	(0xc5a0:16), 31
	jr	UIStateEvt_ParamEdit_Data_Entry
UIStateEvt_ParamEdit_Data_Skip5:
	ld	(0xc5a0:16), 16
UIStateEvt_ParamEdit_Data_Entry:
	bit	3, (0xc07f:16)
	jrl	z, UIStateEvt_ParamEdit_Data_Epilogue
	bit	3, (0xc07e:16)
	jr	z, UIStateEvt_ParamEdit_Data_Skip6
	orw	(0xc596:16), 16
	jr	UIStateEvt_ParamEdit_Data_Join2
UIStateEvt_ParamEdit_Data_Skip6:
	andw	(0xc596:16), 0xffef
UIStateEvt_ParamEdit_Data_Join2:
	orw	(0xc59a:16), 0x2000
	orw	(0xc594:16), 4
	jrl	UIStateEvt_ParamEdit_Data_Epilogue
	bit	6, (0xc07f:16)
	jr	z, UIStateEvt_ParamEdit_Data_Skip8
	bit	6, (0xc07e:16)
	jr	z, UIStateEvt_ParamEdit_Data_Skip7
	orw	(0xc596:16), 0x400
	jr	UIStateEvt_ParamEdit_Data_Join3
UIStateEvt_ParamEdit_Data_Skip7:
	andw	(0xc596:16), 0xfbff
UIStateEvt_ParamEdit_Data_Join3:
	orw	(0xc59a:16), 0x4000
	orw	(0xc594:16), 4
UIStateEvt_ParamEdit_Data_Skip8:
	bit	4, (0xc07f:16)
	jr	z, UIStateEvt_ParamEdit_Data_Skip10
	andw	(0xc596:16), 0xf7ff
	bit	4, (0xc07e:16)
	jr	z, UIStateEvt_ParamEdit_Data_Skip9
	orw	(0xc596:16), 0x800
	jr	UIStateEvt_ParamEdit_Data_Join4
UIStateEvt_ParamEdit_Data_Skip9:
	andw	(0xc596:16), 0xf7ff
UIStateEvt_ParamEdit_Data_Join4:
	orw	(0xc594:16), 4
UIStateEvt_ParamEdit_Data_Skip10:
	ldb_d8	a, (0xc07f)
	and	a, 7
	jrl	z, UIStateEvt_ParamEdit_Data_Epilogue
	ldw_d16	wa, (0xc598)
	bit	6, wa
	jr	z, UIStateEvt_ParamEdit_Data_Skip11
	ldb_d8	a, (0xfc5e)
	and	a, 7
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	ld	iz, (xbc+wa)
	ldb_d8	a, (0xfc5d)
	and	a, 8
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	or	iz, (xbc+wa)
	jr	UIStateEvt_ParamEdit_Data_Join5
UIStateEvt_ParamEdit_Data_Skip11:
	ldw_d16	wa, (0xc598)
	bit	5, wa
	jr	z, UIStateEvt_ParamEdit_Data_Skip12
	ld	iz, 2:i3
	ldb_d8	a, (0xfc5d)
	and	a, 8
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	or	iz, (xbc+wa)
	jr	UIStateEvt_ParamEdit_Data_Join5
UIStateEvt_ParamEdit_Data_Skip12:
	ldb_d8	a, (0xfc5d)
	and	a, 15
	extz	wa
	add	wa, wa
	lda	xbc, (ParamEdit_WordTable:24)
	ld	iz, (xbc+wa)
UIStateEvt_ParamEdit_Data_Join5:
	andw	(0xc596:16), 0xffe8
	or	(0xc596:16), iz
	orw	(0xc594:16), 4
	ldw_d16	wa, (0xc596)
	and	wa, 7
	jr	z, UIStateEvt_ParamEdit_Data_Skip13
	ld	(0xc5a0:16), 31
	jr	UIStateEvt_ParamEdit_Data_Epilogue
UIStateEvt_ParamEdit_Data_Skip13:
	ld	(0xc5a0:16), 16
	jr	110
	ldb_d8	a, (0xc07f)
	and	a, 252
	jr	z, 30
	bit	0, (0x3284:16)
	jr	nz, 18
	ldw_d16	wa, (0xc596)
	bit	9, wa
	jr	z, 9
	ldb_d8	a, (0xfc5f)
	and	a, 252
	jr	nz, 0
	orw	(0xc594:16), 4
	bit	1, (0xc07f:16)
	jr	z, 65
	bit	1, (0xfc5f:16)
	jr	z, 12
	ldw_d16	wa, (0xc596)
	bit	9, wa
	call	z, (0xfdf5f5:24)
	orw	(0xc594:16), 4
	jr	39
	ldb_d8	a, (0xc07f)
	and	a, 252
	jr	z, 30
	bit	0, (0x3284:16)
	jr	nz, 18
	ldw_d16	wa, (0xc596)
	bit	9, wa
	jr	z, 9
	ldb_d8	a, (0xfc5f)
	and	a, 252
	jr	nz, 0
	orw	(0xc594:16), 4
UIStateEvt_ParamEdit_Data_Epilogue:
	popw	iz
	ret
UIStateEvt_VolumeMixer_Data:
	ldb_d8	a, (0xc07d)
	extz	wa
	cp	wa, 0:i3
	ret	mi
	cp	wa, 5:i3
	ret	gt
	add	wa, wa
	lda	xix, (VolumeMixer_SwitchOffsets:24)
	ld	wa, (xix+wa)
	lda	xix, (UIStateEvt_TransposeUpdate_Apply_Code_2:24)
	jp	t, (xix+wa)
UIStateEvt_TransposeUpdate_Apply_Code_2:
	ldb_d8	a, (0xc07f)
	and	a, 31
	jr	z, UIStateEvt_VolumeMixer_Data_Skip
	and	(0xc1fe:16), 252
	ldb_d8	a, (0xc07e)
	and	a, 3
	or	(0xc1fe:16), a
	orw	(0xc594:16), 4
UIStateEvt_VolumeMixer_Data_Skip:
	ldw_d16	wa, (0xc594)
	bit	4, wa
	ret	z
	ld	(0xc1fe:16), 0
	orw	(0xc59a:16), 4
	ret
	ldb_d8	a, (0xc07f)
	and	a, 31
	jr	z, UIStateEvt_VolumeMixer_Data_Skip3
	bit	1, (0xc07e:16)
	jr	z, UIStateEvt_VolumeMixer_Data_Skip2
	orw	(0xc596:16), 32
	jr	UIStateEvt_VolumeMixer_Data_Join2
UIStateEvt_VolumeMixer_Data_Skip2:
	andw	(0xc596:16), 0xffdf
	ldw_d16	wa, (0xc596)
	and	wa, 7
	call	z, (0xfdf5f5:24)
UIStateEvt_VolumeMixer_Data_Join2:
	res	2, (0xc1fe:16)
	ldb_d8	a, (0xc07e)
	and	a, 2
	ld	c, a
	add	a, c
	or	(0xc1fe:16), a
	orw	(0xc594:16), 4
UIStateEvt_VolumeMixer_Data_Skip3:
	ldw_d16	wa, (0xc594)
	bit	4, wa
	ret	z
	ld	(0xc1fe:16), 0
	orw	(0xc59a:16), 4
	ret
	bit	0, (0xc07f:16)
	jr	z, UIStateEvt_VolumeMixer_Data_Entry2
	bit	0, (0xc07e:16)
	jr	z, UIStateEvt_VolumeMixer_Data_Entry
	orw	(0xc596:16), 128
	jr	UIStateEvt_VolumeMixer_Data_Join3
UIStateEvt_VolumeMixer_Data_Entry:
	andw	(0xc596:16), 0xff7f
UIStateEvt_VolumeMixer_Data_Join3:
	orw	(0xc594:16), 4
UIStateEvt_VolumeMixer_Data_Entry2:
	bit	1, (0xc07f:16)
	ret	z
	bit	1, (0xc07e:16)
	jr	z, UIStateEvt_VolumeMixer_Data_Skip4
	orw	(0xc596:16), 8
	jr	UIStateEvt_VolumeMixer_Data_Join4
UIStateEvt_VolumeMixer_Data_Skip4:
	andw	(0xc596:16), 0xfff7
UIStateEvt_VolumeMixer_Data_Join4:
	orw	(0xc594:16), 4
	ret
	ldb_d8	a, (0xc07f)
	and	a, 255
	ret	z
	ld	de, 0:i3
	cp	de, 26
	jr	ge, UIStateEvt_VolumeMixer_Data_Skip6
UIStateEvt_VolumeMixer_Data_Loop:
	ld	wa, de
	sla	wa, 2
	lda	xbc, (PartRecord_RamPtrTable:24)
	ld	xwa, (xbc+wa)
	bitm	0, (xwa+0x16)
	jr	z, UIStateEvt_VolumeMixer_Data_Skip5
	ld	wa, de
	add	wa, wa
	add	wa, 228
	lda_d16	xbc, (0xc1ff)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldb_d8	a, (0xc07e)
	and	a, 255
	sub	a, 64
	ld	(xhl), a
	jr	UIStateEvt_VolumeMixer_Data_Join
UIStateEvt_VolumeMixer_Data_Skip5:
	ld	wa, de
	add	wa, wa
	add	wa, 228
	lda_d16	xbc, (0xc1ff)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 0
UIStateEvt_VolumeMixer_Data_Join:
	inc	1, de
	cp	de, 26
	jr	lt, UIStateEvt_VolumeMixer_Data_Loop
UIStateEvt_VolumeMixer_Data_Skip6:
	orw	(0xc594:16), 4
	ret
	ldb_d8	a, (0xc07f)
	and	a, 255
	ret	z
	orw	(0xc594:16), 4
	ret
	ret
UIStateEvt_EffectSelect_Data:
	ldb_d8	a, (0xc07d)
	cp	a, 4:i3
	jrl	z, UIStateEvt_EffectSelect_Data_Skip4
	cp	a, 3:i3
	jrl	z, UIStateEvt_EffectSelect_Data_Skip3
	cp	a, 2:i3
	jrl	z, UIStateEvt_EffectSelect_Data_Skip2
	cp	a, 1:i3
	jr	z, UIStateEvt_EffectSelect_Data_Skip
	cp	a, 0:i3
	ret	nz
	ldb_d8	a, (0xc07f)
	and	a, 3
	jr	z, UIStateEvt_EffectSelect_Data_Join
	ldb_d8	a, (0xc07e)
	and	a, 3
	cp	a, 3:i3
	jr	z, UIStateEvt_EffectSelect_Data_Skip7
	cp	a, 2:i3
	jr	z, UIStateEvt_EffectSelect_Data_Skip6
	cp	a, 1:i3
	jr	z, UIStateEvt_EffectSelect_Data_Skip5
	cp	a, 0:i3
	jr	nz, UIStateEvt_EffectSelect_Data_Join
	ldb_d8	a, (0xfd03)
	res	7, a
	stb_d8	(0xc5a2), a
	orw	(0xc59a:16), 0x400
	jr	UIStateEvt_EffectSelect_Data_Join
UIStateEvt_EffectSelect_Data_Skip5:
	ld	(0xc5a2:16), 55
	orw	(0xc59a:16), 0x400
	jr	UIStateEvt_EffectSelect_Data_Join
UIStateEvt_EffectSelect_Data_Skip6:
	ld	(0xc5a2:16), 60
	orw	(0xc59a:16), 0x400
	jr	UIStateEvt_EffectSelect_Data_Join
UIStateEvt_EffectSelect_Data_Skip7:
	ld	(0xc5a2:16), 67
	orw	(0xc59a:16), 0x400
UIStateEvt_EffectSelect_Data_Join:
	orw	(0xc594:16), 4
	ret
UIStateEvt_EffectSelect_Data_Skip:
	ldb_d8	a, (0xc07f)
	res	7, a
	cp	a, 0:i3
	ret	z
	ldb_d8	a, (0xfd02)
	and	a, 3
	jr	nz, UIStateEvt_EffectSelect_Data_Skip8
	ldb_d8	a, (0xc07e)
	res	7, a
	stb_d8	(0xc5a2), a
UIStateEvt_EffectSelect_Data_Skip8:
	orw	(0xc59a:16), 0x400
	orw	(0xc594:16), 4
	ret
UIStateEvt_EffectSelect_Data_Skip2:
	ldb_d8	a, (0xc07f)
	and	a, 255
	ret	z
	bit	5, (0xfd50:16)
	ret	z
	ldb_d8	a, (0xc07e)
	and	a, 255
	extz	wa
	lda	xbc, (EffectSelect_StepTable:24)
	ld	e, (xbc+wa)
	ld	hl, 0:i3
	cp	hl, 26
	jr	nc, UIStateEvt_EffectSelect_Data_Skip9
UIStateEvt_EffectSelect_Data_Loop:
	ld	wa, hl
	add	wa, wa
	add	wa, 0x124
	lda_d16	xbc, (0xc1ff)
	extz	xwa
	add	xwa, xbc
	ld	c, e
	and	c, 15
	sla	c, 4
	andmi8	(xwa), 15
	or	(xwa), c
	inc	1, hl
	cp	hl, 26
	jr	c, UIStateEvt_EffectSelect_Data_Loop
UIStateEvt_EffectSelect_Data_Skip9:
	orw	(0xc594:16), 4
	ret
UIStateEvt_EffectSelect_Data_Skip3:
	ldb_d8	a, (0xc07f)
	and	a, 255
	ret	z
	ldb_d8	a, (0xc07e)
	and	a, 255
	stb_d8	(0xe9c0), a
	orw	(0xc594:16), 4
	ret
UIStateEvt_EffectSelect_Data_Skip4:
	ldb_d8	a, (0xc07f)
	and	a, 15
	ret	z
	ldb_d8	a, (0xc07e)
	and	a, 15
	stb_d8	(0xe9be), a
	orw	(0xc59a:16), 0x4000
	orw	(0xc594:16), 4
	ret
; --- Guard/dispatch: check flags, set/clear bits, conditional calls (54 bytes) ---
UIStateEvt_PlayModeGuard_Data:
	cp	(0xc07d:16), 2
	ret	nz
	bit	6, (0xc07e:16)
	jr	z, UIStateEvt_PlayModeGuard_ClearBit
	orw	(0xc596:16), 0x2000
	ret
UIStateEvt_PlayModeGuard_ClearBit:
	andw	(0xc596:16), 0xdfff
	call	Voice_UpdatePlayModeState
	cp	hl, 255
	call	nz, (0xfe12b8:24)
	call	NoteMap_FindBestMatch
	cp	hl, 255
	ret	z
	call	VoiceEvent_DispatchTable
	ret
UIStateEvt_ChannelConfig_Data:
	ldb_d8	a, (0xc07d)
	cp	a, 11
	jrl	z, UIStateEvt_ChannelConfig_Data_Skip5
	cp	a, 12
	jrl	z, UIStateEvt_ChannelConfig_Data_Skip5
	cp	a, 10
	jrl	z, UIStateEvt_ChannelConfig_Data_Skip5
	cp	a, 3:i3
	jrl	z, UIStateEvt_ChannelConfig_Data_Entry3
	cp	a, 2:i3
	jrl	z, UIStateEvt_ChannelConfig_Data_Entry2
	cp	a, 1:i3
	ret	z
	cp	a, 0:i3
	ret	nz
	bit	6, (0xc07f:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Entry
	orw	(0xc59c:16), 8
	orw	(0xc594:16), 4
UIStateEvt_ChannelConfig_Data_Entry:
	bit	5, (0xc07f:16)
	ret	z
	bit	5, (0xc07e:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Skip
	ld	de, 0:i3
	cp	de, 26
	jr	nc, UIStateEvt_ChannelConfig_Data_Join
UIStateEvt_ChannelConfig_Data_Loop2:
	ld	wa, de
	add	wa, wa
	add	wa, 0x124
	lda_d16	xbc, (0xc1ff)
	ld	hl, wa
	extz	xhl
	add	xhl, xbc
	ldb_d8	a, (0xfd04)
	and	a, 255
	extz	wa
	lda	xbc, (EffectSelect_StepTable:24)
	ld	a, (xbc+wa)
	and	a, 15
	sla	a, 4
	andmi8	(xhl), 15
	or	(xhl), a
	inc	1, de
	cp	de, 26
	jr	c, UIStateEvt_ChannelConfig_Data_Loop2
	jr	UIStateEvt_ChannelConfig_Data_Join
UIStateEvt_ChannelConfig_Data_Skip:
	ld	de, 0:i3
	cp	de, 26
	jr	nc, UIStateEvt_ChannelConfig_Data_Join
UIStateEvt_ChannelConfig_Data_Loop:
	ld	wa, de
	add	wa, wa
	add	wa, 0x124
	lda_d16	xbc, (0xc1ff)
	extz	xwa
	add	xwa, xbc
	andmi8	(xwa), 15
	inc	1, de
	cp	de, 26
	jr	c, UIStateEvt_ChannelConfig_Data_Loop
UIStateEvt_ChannelConfig_Data_Join:
	orw	(0xc594:16), 4
	ret
UIStateEvt_ChannelConfig_Data_Entry2:
	orw	(0xc594:16), 4
	ret
UIStateEvt_ChannelConfig_Data_Entry3:
	bit	0, (0xc07f:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Entry4
	bit	0, (0xc07e:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Skip4
	res	4, (0xc322:16)
	orw	(0xc59c:16), 8
	jr	UIStateEvt_ChannelConfig_Data_Join2
UIStateEvt_ChannelConfig_Data_Skip4:
	set	4, (0xc322:16)
	orw	(0xc59c:16), 8
UIStateEvt_ChannelConfig_Data_Join2:
	orw	(0xc594:16), 4
UIStateEvt_ChannelConfig_Data_Entry4:
	bit	2, (0xc07f:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Entry6
	bit	2, (0xc07e:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Entry5
	set	6, (0xc342:16)
	set	6, (0xc344:16)
	set	6, (0xc346:16)
	set	6, (0xc348:16)
	set	6, (0xc34a:16)
	set	6, (0xc34c:16)
	jr	UIStateEvt_ChannelConfig_Data_Join3
UIStateEvt_ChannelConfig_Data_Entry5:
	res	6, (0xc342:16)
	res	6, (0xc344:16)
	res	6, (0xc346:16)
	res	6, (0xc348:16)
	res	6, (0xc34a:16)
	res	6, (0xc34c:16)
	orw	(0xc59c:16), 8
UIStateEvt_ChannelConfig_Data_Join3:
	orw	(0xc594:16), 4
UIStateEvt_ChannelConfig_Data_Entry6:
	bit	6, (0xc07f:16)
	jr	z, UIStateEvt_ChannelConfig_Data_Entry7
	orw	(0xc59c:16), 8
	orw	(0xc594:16), 4
UIStateEvt_ChannelConfig_Data_Entry7:
	bit	7, (0xc07f:16)
	ret	z
	orw	(0xc59c:16), 8
	orw	(0xc594:16), 4
	ret
UIStateEvt_ChannelConfig_Data_Skip5:
	ld	xwa, 0x5000
	call	SndParam_LookupReadOnly
	cp	hl, 2:i3
	jr	z, UIStateEvt_ChannelConfig_Data_Skip3
	cp	hl, 1:i3
	jr	z, UIStateEvt_ChannelConfig_Data_Skip2
	cp	hl, 0:i3
	ret	nz
	ld	(0xc362:16), 0
	ld	(0xc363:16), 255
	ret
UIStateEvt_ChannelConfig_Data_Skip2:
	ld	xwa, 0x5001
	call	SndParam_LookupReadOnly
	stb_d8	(0xc362), l
	ld	(0xc363:16), 255
	ret
UIStateEvt_ChannelConfig_Data_Skip3:
	ld	(0xc362:16), 0
	ld	xwa, 0x5002
	call	SndParam_LookupReadOnly
	stb_d8	(0xc363), l
	ret
UIStateEvt_StubReturn:
	ret
	ret
UIStateEvt_MuteToggle_Data:
	ldb_d8	a, (0xc07d)
	cp	a, 16
	ret	nz
	bit	0, (0xc07f:16)
	ret	z
	bit	0, (0xc07e:16)
	jr	z, UIStateEvt_MuteToggle_Data_Skip
	orw	(0xc594:16), 1
	jr	UIStateEvt_MuteToggle_Data_Join
UIStateEvt_MuteToggle_Data_Skip:
	andw	(0xc594:16), 0xfffe
UIStateEvt_MuteToggle_Data_Join:
	orw	(0xc594:16), 4
	ret
	ret

; ============================================================================
; AudioInit_ConfigStereoVoice - Configure stereo voice routing and panning
; ============================================================================
; Input:  Voice index (from voice type table at 0xee8e62)
; Output: Updates audio config flags at address 50588
; Default handler in voice-source dispatch table. Routes voices by type:
; simple stereo (type < 3) or extended routing with panning configuration.
; ============================================================================
	.include "audio/audioinit_routines.s"
