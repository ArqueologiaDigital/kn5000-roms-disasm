; =============================================================================
; UI Mode Handlers (12K lines)
; =============================================================================
;
; Mode-specific UI handlers for Pmem (parametric memory), bank
; editor, filter grid, RVari (rhythm variation), and DSP effect
; editing modes.
; =============================================================================

EffectMode_CopyVoiceParams:
	pushw iz
	lda_d16 xbc, 0xfd05
	lda_d16 xhl, 0xf9a0
	sub xbc, xhl
	lda_24 xde, 0x03c2c4
	add xbc, xde
	cp (xbc), 0x3
	jr nz, EffectMode_CopyVoiceParams_Done
	lda_d16 xix, 0xfa04
	ld xbc, xix
	sub xbc, xhl
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 29)
	ld (xiy), c
	lda xbc, (xix + 1)
	sub xbc, xhl
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 30)
	ld (xiy), c
	lda xbc, (xix + 3)
	sub xbc, xhl
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 31)
	ld (xiy), c
	ld c, (xwa + 32)
	and c, 0xcf
	ldb_erp C, 0xf8
	lda xbc, (xix + 4)
	sub xbc, xhl
	ld xiy, xbc
	add xiy, xde
	ld c, (xiy)
	and c, 0x30
	ld (xiy), c
	orb_erp C, 0xf8
	ld (xiy), c
	lda xbc, (xix + 8)
	sub xbc, xhl
	add xbc, xde
	ld a, (xwa + 33)
	ld (xbc), a

EffectMode_CopyVoiceParams_Done:
	popw iz
	ret


EffectMode_ByteData_Block1:
	stdi16	0x8d58, 0xffff
	jrl	648
EffectMode_ByteData_Block2:
	.byte 0xc1
	jrl	pl, 0x3fc0
	push	sr
	ret	nz
	ldb_d8	a, 0xc07e
	andda8	a, 0xc07f
	bit	0, a
	jrl	z, 145
	.byte 0xc1
	ldw	ix, 0x3f8d
	.byte 0x01
	jr	z, 78
	ldb_d8	a, 0x8d36
	cp	a, 192
	jr	z, 40
	cp	a, 193
	jr	z, 15
	cp	a, 194
	jr	z, 10
	cp	a, 195
	jr	z, 5
	cp	a, 197
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	jr	54
	.byte 0xc1
	popw	iz
	.byte 0x8d
	push	xsp
	nop
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	jp	UI_PostPartChangeEvent
	.byte 0xc1
	popw	iz
	.byte 0x8d
	push	xsp
	nop
	jr	z, 24
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	call	UI_PostPartChangeEvent
	jr	59
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	lds32	xde, 0
	call	ApPostEvent
	ldw	wa, 18
	call	UI_PostPartChangeEvent
	stdi8	0x8d4e, 15
	ret
	.byte 0xc1
	popw	iz
	.byte 0x8d
	push	xsp
	nop
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	lds32	xde, 0
	call	ApPostEvent
	ldw	wa, 193
	call	UI_PostModeChangeEvent
	stdi8	0x8d4e, 0
	ret
EffectMode_ByteData_Block3:
	ldb_d8	a, 0xc07d
	cps	a, 0
	jr	nz, 95
	.byte 0xc1
	jrl	nc, 0x3fc0
	nop
	jr	z, 83
	.byte 0xf1
	jrl	nz, -12352
	jr	nz, 77
	.byte 0xf1, 0x52
	decm8	6, (xiy-52)
	ld	xsp, 0x3f8d36c1
	.byte 0xc0
	jr	nz, 6
	call	UI_PostTimerResetEvent
	jr	58
	ld	xwa, 1025
	call	SndParam_LookupReadOnly
	cps	hl, 3
	jr	z, 4
	cps	hl, 2
	jr	nz, 41
	ld	xwa, 1024
	call	SndParam_LookupReadOnly
	cps	hl, 0
	jr	z, 28
	ld	xwa, 0x28002
	call	SndParam_LookupReadOnly
	stb_d8	0x8d54, l
	.byte 0xf1, 0xe2, 0xb7
	ld	(xsp-15), de
	.byte 0x8d, 0xbb
	calr	1623
	.byte 0xf1, 0x52, 0x8d, 0xb3, 0xf1, 0x52, 0x8d, 0xb4
	ret
	cps	a, 7
	jr	nz, 59
	ldb_d8	a, 0x8d52
	.byte 0xc9, 0xcc
	.ascii "(f2@"
	.byte 0x01, 0x04
	nop
	nop
	call	SndParam_LookupReadOnly
	cps	hl, 3
	jr	z, 4
	cps	hl, 2
	jr	nz, 33
	ld	xwa, 1024
	call	SndParam_LookupReadOnly
	cps	hl, 0
	jr	z, 20
	ld	xwa, 0x28002
	call	SndParam_LookupReadOnly
	stb_d8	0x8d54, l
	.byte 0xf1, 0xe2, 0xb7, 0xbf
	calr	1551
	.byte 0xc1, 0x52, 0x8d
	push	xix
	.byte 0xd7
	ret
EffectMode_ByteData_Block4:
	.byte 0xc1
	jrl	pl, 0x3fc0
	pop	sr
	jr	nz, 68
	ldb_d8	a, 0xc07e
	and	a, 7
	jr	z, 59
	ldb_d8	a, 0x8d52
	and	a, 40
	jr	z, 50
	ld	xwa, 1025
	call	SndParam_LookupReadOnly
	cps	hl, 3
	jr	z, 4
	cps	hl, 2
	jr	nz, 33
	ld	xwa, 1024
	call	SndParam_LookupReadOnly
	cps	hl, 0
	jr	z, 20
	ld	xwa, 0x28002
	call	SndParam_LookupReadOnly
	stb_d8	0x8d54, l
	.byte 0xf1, 0xe2, 0xb7, 0xbf
	calr	1470
	.byte 0xc1, 0x52, 0x8d
	push	xix
	.byte 0xd7
	ret


EffectMode_ApplyTranspose:
	calr EffectMode_ProcessPresetChange
	cpdi8 0x8d36, 192
	jr nz, EffectMode_ApplyTranspose_StoreTimer
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 0
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent

EffectMode_ApplyTranspose_StoreTimer:
	stdi8 0x8d4e, 0
	jr EffectMode_CheckTransposeAndLookup

EffectMode_CheckTransposeAndLookup:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	bit 7, hl
	ret nz
	calr SndParam_LoadTransposeValues
	stda16 0x8d58, xhl
	ret

SndParam_LoadTransposeValues:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	stb_d8 0x90ea, l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda_d16 xwa, 0x90ea
	ld (xwa + 1), l
	ld (xwa + 2), 0x48
	push xde
	push xhl
	push xix
	push xiz
	call Rhythm_DispatchNote_Finalize
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda_d16 xbc, 0x90ee
	ld e, (xbc + 1)
	extz de
	ld a, (xbc)
	extz wa
	sll wa, 8
	add wa, de
	ld hl, wa
	ret

EffectMode_TimerCountdown:
	ldb_d8 a, 0x8d4e
	cps a, 0
	ret z
	dec 1, a
	stb_d8 0x8d4e, a
	cps a, 0
	ret nz
	cpdi16 0x8d56, 0
	jr z, EffectMode_TimerCountdown_CheckMode
	push xde
	push xhl
	push xix
	push xiz
	calr EffectMode_ApplyTranspose
	pop xiz
	pop xix
	pop xhl
	pop xde

EffectMode_TimerCountdown_CheckMode:
	ldb_d8 a, 0x8d36
	cp a, 0xc5
	jr z, EffectMode_TimerCountdown_ResBit7
	cp a, 0xc2
	jr z, EffectMode_TimerCountdown_ResBit7
	cp a, 0xc1
	jr nz, EffectMode_TimerCountdown_SetBit7

EffectMode_TimerCountdown_ResBit7:
	resda 7, 0xb7e2
	ret

EffectMode_TimerCountdown_SetBit7:
	setda 7, 0xb7e2
	ret

EffectMode_CheckTransposeChanged:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	bit 7, hl
	jr nz, EffectMode_TransposeInvalid
	calr SndParam_LoadTransposeValues
	cpda16 xhl, 0x8d58
	ret z
	stda16 0x8d58, xhl
	jrl BitMapOut_ApplyPatch_SkipHeader

EffectMode_TransposeInvalid:
	stdi16 0x8d58, 0xffff
	stdi16 0x8d56, 0
	ret

EffectMode_ProcessPresetChange:
	dec 4, xsp
	push xiz
	ldw_d16 xbc, 0x8d56
	ld wa, bc
	cps bc, 0
	jr z, EffectMode_ProcessPresetChange_CheckBit7
	dec 1, wa
	jr EffectMode_ProcessPresetChange_Apply

EffectMode_ProcessPresetChange_CheckBit7:
	bitda 7, 0xb7e2
	jr nz, EffectMode_ProcessPresetChange_Done

EffectMode_ProcessPresetChange_Apply:
	calr EffectMode_ClampAndLookupPreset
	ld xwa, xhl
	stda32 0x8d60, xwa
	calr EffectMode_UpdateDisplay
	lda_d16 xwa, 0xfc5a
	ld (xsp + 4), xwa
	sub xwa, 0xf9a0
	lda_24 xbc, 0x03c2c4
	ld xiz, xwa
	add xiz, xbc
	ld xwa, (xsp + 4)
	ld xbc, xiz
	calr EffectMode_CopyHoldPedalBits
	ld xwa, (xsp + 4)
	ld xbc, xiz
	calr EffectMode_SetRegionAndHold
	ld xwa, xiz
	calr EffectMode_Nop
	lda_d16 xwa, 0xf9ef
	sub xwa, 0xf9a0
	lda_24 xbc, 0x03c2c4
	add xwa, xbc
	andmi8 (xwa), 0x80
	ld xwa, (xsp + 4)
	ld xbc, xiz
	calr EffectMode_CopyPresetBits
	calr EffectMode_ReinitSoundOutput

EffectMode_ProcessPresetChange_Done:
	resda 7, 0xb7e2
	pop xiz
	inc 4, xsp
	ret

EffectMode_CopyParamByte:
	lda_d16	xwa, 0xfa07
	lda_d16	xde, 0xf9a0
	sub	xwa, xde
	lda_24	xbc, 0x3c2c4
	ld	xhl, xwa
	add	xhl, xbc
	lda_d16	xwa, 0xfba7
	sub	xwa, xde
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xhl), a
	ret

EffectMode_ClampAndLookupPreset:
	cp wa, 0x3e8
	jr ule, EffectMode_ClampAndLookup_Clamped
	lds wa, 1

EffectMode_ClampAndLookup_Clamped:
	ldb_d8 c, 0x8d38
	cp c, 0xc2
	jr z, EffectMode_LookupPreset_BankC2C5
	cp c, 0xc5
	jr nz, EffectMode_LookupPreset_Bank7000

EffectMode_LookupPreset_BankC2C5:
	ld xbc, 0x986000
	jr EffectMode_LookupPreset_Compute

EffectMode_LookupPreset_Bank7000:
	ld xbc, 0x987000

EffectMode_LookupPreset_Compute:
	extz xwa
	sll xwa, 2
	add xwa, xbc
	ld xwa, (xwa)
	ld xhl, xwa
	add xhl, (xwa + 4)
	ret

EffectMode_DisplayPresetName:
	pushw iz
	ldb_d8 c, 0x8d38
	cp c, 0xc0
	jr z, EffectMode_DisplayName_ValidMode
	cp c, 0xc2
	jr z, EffectMode_DisplayName_ValidMode
	cp c, 0xc5
	jr nz, EffectMode_DisplayName_Done

EffectMode_DisplayName_ValidMode:
	ldw_d16 xwa, 0x8d56
	ld iz, wa
	cps wa, 0
	jr z, EffectMode_DisplayName_CheckC2C5
	dec 1, iz

EffectMode_DisplayName_CheckC2C5:
	cp c, 0xc2
	jr z, EffectMode_DisplayName_LookupC2C5
	cp c, 0xc5
	jr nz, EffectMode_DisplayName_LookupC0

EffectMode_DisplayName_LookupC2C5:
	ld wa, iz
	calr EffectMode_SearchPresetTableC2C5
	cp xhl, 0xffffffff
	jr z, EffectMode_DisplayName_FallbackC2C5
	pushw 0x10
	ld wa, iz
	calr EffectMode_SearchPresetTableC2C5
	push xhl
	jr EffectMode_DisplayName_Render

EffectMode_DisplayName_FallbackC2C5:
	ld xwa, 0x986000
	jr EffectMode_DisplayName_DefaultLookup

EffectMode_DisplayName_LookupC0:
	ld wa, iz
	calr EffectMode_SearchPresetTableC0
	cp xhl, 0xffffffff
	jr z, EffectMode_DisplayName_FallbackC0
	pushw 0x10
	ld wa, iz
	calr EffectMode_SearchPresetTableC0
	push xhl
	jr EffectMode_DisplayName_Render

EffectMode_DisplayName_FallbackC0:
	ld xwa, 0x987000

EffectMode_DisplayName_DefaultLookup:
	ld bc, iz
	extz xbc
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xbc)
	pushw 0x10
	lda xwa, (xwa + 43)
	push xwa

EffectMode_DisplayName_Render:
	lda_d16 xwa, 0xf9a2
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ldw wa, 0x80
	call BitMapOut_GetRenderMode_CheckBit3

EffectMode_DisplayName_Done:
	popw iz
	ret

EffectMode_SearchPresetTableC2C5:
	lds ix, 0
	lda_24 xhl, WidgetStyleDataTable_0x36E

EffectMode_SearchPresetTableC2C5_Loop:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 3
	add xde, xbc
	add xde, xde
	ld xbc, xhl
	add xbc, xde
	cp wa, (xbc)
	jr nz, EffectMode_SearchPresetTableC2C5_Next
	lda xhl, (xbc + 2)
	ret

EffectMode_SearchPresetTableC2C5_Next:
	inc 1, ix
	cp ix, 0x16
	jr c, EffectMode_SearchPresetTableC2C5_Loop
	ld xhl, 0xffffffff
	ret

EffectMode_SearchPresetTableC0:
	lds ix, 0
	lda_24 xhl, WidgetStyleDataTable_0x4FA

EffectMode_SearchPresetTableC0_Loop:
	ld bc, ix
	extz xbc
	ld xde, xbc
	sll xde, 3
	add xde, xbc
	add xde, xde
	ld xbc, xhl
	add xbc, xde
	cp wa, (xbc)
	jr nz, EffectMode_SearchPresetTableC0_Next
	lda xhl, (xbc + 2)
	ret

EffectMode_SearchPresetTableC0_Next:
	inc 1, ix
	cps ix, 5
	jr c, EffectMode_SearchPresetTableC0_Loop
	ld xhl, 0xffffffff
	ret

EffectMode_UpdateDisplay:
	push xiz
	ld xiz, xwa
	calr EffectMode_BackupParamBlock
	ldb_d8 a, 0x8d52
	bit 5, a
	jr z, EffectMode_UpdateDisplay_NoPatch
	res 5, a
	stb_d8 0x8d52, a
	ld xwa, xiz
	calr BitMapOut_ByteData_PatchTable
	jr EffectMode_UpdateDisplay_CopyVoice

EffectMode_UpdateDisplay_NoPatch:
	calr EffectMode_UpdateBitFlags

EffectMode_UpdateDisplay_CopyVoice:
	ld xwa, xiz
	calr EffectMode_CopyVoiceParams
	pop xiz
	ret

EffectMode_UpdateBitFlags:
	lda xsp, (xsp - 48)
	push xiz
	lda xwa, (xsp + 48)
	ld (xsp + 12), xwa
	lda_d16 xwa, 0xf9ba
	lda_d16 xde, 0xf9a0
	sub xwa, xde
	lda_24 xbc, 0x03c2c4
	ld (xsp + 32), xwa
	add (xsp + 32), xbc
	ld xwa, (xsp + 32)
	ld l, (xwa)
	and l, 0x20
	ld xix, (xsp + 12)
	ld (xix), l
	lda xwa, (xix + 1)
	ld (xsp + 24), xwa
	lda_d16 xwa, 0xf9d4
	sub xwa, xde
	ld (xsp + 36), xwa
	add (xsp + 36), xbc
	ld xwa, (xsp + 36)
	ld l, (xwa)
	and l, 0x20
	ld xwa, (xsp + 24)
	ld (xwa), l
	lda xwa, (xix + 2)
	ld (xsp + 20), xwa
	lda_d16 xwa, 0xf9ee
	sub xwa, xde
	ld (xsp + 40), xwa
	add (xsp + 40), xbc
	ld xwa, (xsp + 40)
	ld l, (xwa)
	and l, 0x20
	ld xwa, (xsp + 20)
	ld (xwa), l
	lda xwa, (xix + 3)
	ld (xsp + 16), xwa
	lda_d16 xwa, 0xfa08
	sub xwa, xde
	ld (xsp + 44), xwa
	add (xsp + 44), xbc
	ld xwa, (xsp + 44)
	ld l, (xwa)
	and l, 0x20
	ld xwa, (xsp + 16)
	ld (xwa), l
	lda_d16 xwa, 0xfd02
	sub xwa, xde
	ld (xsp + 28), xwa
	add (xsp + 28), xbc
	ld xwa, (xsp + 28)
	ld a, (xwa)
	and a, 0x3b
	ld (xsp + 4), a
	lda_d16 xhl, 0xfc6f
	sub xhl, xde
	add xhl, xbc
	ld a, (xhl)
	and a, 0x20
	ld (xsp + 6), a
	ldda32 xwa, 0x8d60
	ld (xsp + 8), xwa
	lds iy, 0
	jr EffectMode_UpdateBitFlags_Loop

EffectMode_UpdateBitFlags_ProcessEntry:
	ld a, (xix + 4)
	extz wa
	ld xde, (xix)
	exts xwa
	add xwa, xde
	ld xiz, xbc
	add xiz, xwa
	ldb w, 0x0
	jr EffectMode_UpdateBitFlags_CheckCount

EffectMode_UpdateBitFlags_CopyByte:
	ld xde, (xsp + 8)
	ldb_spi A, 0xe8
	lda_dpi XBC, 0xf8
	ld (xsp + 8), xde
	inc 1, w

EffectMode_UpdateBitFlags_CheckCount:
	cp (xix + 5), w
	jr ugt, EffectMode_UpdateBitFlags_CopyByte
	inc 1, iy

EffectMode_UpdateBitFlags_Loop:
	ld de, iy
	extz xde
	ld xwa, xde
	add xwa, xwa
	add xwa, xde
	add xwa, xwa
	ld xix, WidgetStyleDataTable_0x2A8
	add xix, xwa
	ld xwa, (xix)
	cp xwa, 0xff
	jr nz, EffectMode_UpdateBitFlags_ProcessEntry
	ld xde, (xsp + 32)
	ld c, (xde)
	res 5, c
	ld (xde), c
	ld xwa, (xsp + 12)
	or c, (xwa)
	ld (xde), c
	ld xde, (xsp + 36)
	ld c, (xde)
	res 5, c
	ld (xde), c
	ld xwa, (xsp + 24)
	or c, (xwa)
	ld (xde), c
	ld xde, (xsp + 40)
	ld c, (xde)
	res 5, c
	ld (xde), c
	ld xwa, (xsp + 20)
	or c, (xwa)
	ld (xde), c
	ld xde, (xsp + 44)
	ld c, (xde)
	res 5, c
	ld (xde), c
	ld xwa, (xsp + 16)
	or c, (xwa)
	ld (xde), c
	ld xwa, (xsp + 28)
	ld c, (xwa)
	and c, 0xc4
	ld (xwa), c
	or c, (xsp + 4)
	ld (xwa), c
	ld a, (xhl)
	res 5, a
	ld (xhl), a
	or a, (xsp + 6)
	ld (xhl), a
	pop xiz
	lda xsp, (xsp + 48)
	ret

EffectMode_BackupParamBlock:
	lda_d16 xbc, 0xf9a0
	lda_d16 xwa, 0xfd5e
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	push xbc
	pushw 0x3
	pushw 0xc2c4
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

EffectMode_CopyHoldPedalBits:
	ldb_d8 e, 0x8d38
	cp e, 0xc0
	ret z
	cp e, 0xc2
	ret z
	cp e, 0xc5
	ret z
	bitda 2, 1056
	ret z
	ld l, (xwa + 8)
	and l, 0xff
	ld e, (xwa + 9)
	and e, 0x1
	lda xwa, (xbc + 8)
	ld (xwa), 0x0
	lda xbc, (xbc + 9)
	resm 0, (xbc)
	or (xwa), l
	or (xbc), e
	ret

EffectMode_SetRegionAndHold:
	push xiz
	ld xiz, xbc
	ld h, (xwa + 3)
	ld a, h
	and a, 0x7
	jr nz, EffectMode_SetRegion_Apply
	call Get_Region_Code
	ldb h, 0xa
	cps l, 2
	jr nz, EffectMode_SetRegion_Apply
	ldb h, 0x9

EffectMode_SetRegion_Apply:
	lda xbc, (xiz + 3)
	ld a, (xbc)
	and a, 0xf8
	ld (xbc), a
	or a, h
	ld (xbc), a
	setm 1, (xiz + 5)
	lda_d16 xbc, 0xfd02
	ld h, (xbc)
	and h, 0x3
	sub xbc, 0xf9a0
	lda_24 xde, 0x03c2c4
	add xbc, xde
	ld a, (xbc)
	and a, 0xfc
	ld (xbc), a
	or a, h
	ld (xbc), a
	ldb_d8 a, 0x8d38
	cp a, 0xc2
	jr z, EffectMode_CheckPedalType
	cp a, 0xc5
	jr nz, EffectMode_PopIzRet

EffectMode_CheckPedalType:
	bitda 2, 1054
	jr nz, EffectMode_PopIzRet
	ldw_d16 xwa, 0x8d56
	bit 0, wa
	jr z, EffectMode_SendPedalType_Bank1
	ld xwa, 0x28101
	call SndParam_LookupReadOnly
	cps hl, 2
	jr z, EffectMode_PopIzRet
	push xde
	push xhl
	push xix
	push xiz
	lds wa, 0
	call AccReplay_SendPedalType5
	pop xiz
	pop xix
	pop xhl
	pop xde
	jr EffectMode_PopIzRet

EffectMode_SendPedalType_Bank1:
	ld xwa, 0x28101
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, EffectMode_PopIzRet
	push xde
	push xhl
	push xix
	push xiz
	lds wa, 1
	call AccReplay_SendPedalType5
	pop xiz
	pop xix
	pop xhl
	pop xde

EffectMode_PopIzRet:
	pop xiz
	ret

EffectMode_Nop:
	ret

EffectMode_CopyPresetBits:
	ld xde, xbc
	bitda 7, 0xb7e2
	ret z
	ld c, (xwa)
	ld (xde), c
	ld c, (xwa + 1)
	res 7, c
	ldb_erp C, 0xf0
	lda xhl, (xde + 1)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	orb_erp C, 0xf0
	ld (xhl), c
	ld a, (xwa + 4)
	and a, 0x7
	ldb_erp A, 0xf0
	lda xbc, (xde + 4)
	ld a, (xbc)
	and a, 0xf8
	ld (xbc), a
	orb_erp A, 0xf0
	ld (xbc), a
	ret

EffectMode_ReinitSoundOutput:
	ld xwa, 0x302
	call SndParam_LookupReadOnly
	stb_d8 0x8d50, l
	ld xwa, 0x302
	lds bc, 1
	lds de, 0
	call SoundParam_NotifyChange
	ldw wa, 0x80
	ld xbc, 0x3c2c4
	call BitMapOut_CopyVoicePreset9
	ldw wa, 0x80
	call BitMapOut_SnapshotFromROM
	calr EffectMode_DisplayPresetName
	resda 4, 0x8d52
	cpdi8 0x8d50, 1
	jr z, EffectMode_ReinitSound_NotifyBank1
	ld xwa, 0x302
	lds bc, 0
	lds de, 0
	jr EffectMode_ReinitSound_CallNotify

EffectMode_ReinitSound_NotifyBank1:
	ld xwa, 0x302
	lds bc, 1
	lds de, 0

EffectMode_ReinitSound_CallNotify:
	call SoundParam_NotifyChange
	jp SwbtWr_ReinitOutputBank

EffectMode_ReinitWithFlag:
	setda 5, 0x8d52
	calr EffectMode_CheckModeAndReinit
	resda 5, 0x8d52
	ret

EffectMode_CheckModeAndReinit:
	ldb_d8 c, 0x8d36
	cp c, 0x78
	jr z, SndOutput_ReinitByMode
	cp c, 0x7a
	jr z, SndOutput_ReinitByMode
	ldb_d8 a, 0x8d34
	cps a, 2
	jr z, SndOutput_ReinitByMode
	cps a, 1
	jr z, SndOutput_ReinitByMode
	cp c, 0x85
	jr z, SndOutput_ReinitByMode
	cp c, 0x81
	jr z, SndOutput_ReinitByMode
	cp c, 0x7f
	jr z, SndOutput_ReinitByMode
	cp c, 0x60
	jr z, SndOutput_ReinitByMode
	cps a, 7
	ret nz

SndOutput_ReinitByMode:
	ld xwa, 0x401
	call SndParam_LookupReadOnly
	cps hl, 3
	jr z, SndOutput_ReinitByMode_TypeA
	cps hl, 2
	ret nz
	jr SndOutput_ReinitByMode_TypeB

SndOutput_ReinitByMode_TypeA:
	calr SndOutput_ReinitByMode_NotifyParam
	ret

SndOutput_ReinitByMode_TypeB:
	push xiz
	ldw_d16 xiz, 0x8d58
	ldw_d16 xwa, 0x8d56
	ldw_erp WA, 0xfa
	stdi16 0x8d58, 0xffff
	calr EffectMode_CheckTransposeChanged
	ldw_d16 xbc, 0x8d56
	cps bc, 0
	jr z, SndOutput_ReinitByMode_Restore
	dec 1, bc
	ldb_d8 a, 0x8d54
	extz wa
	add bc, wa
	stda16 0x8d56, xbc
	calr EffectMode_ProcessPresetChange
	call SwbtWr_ReinitOutputBank

SndOutput_ReinitByMode_Restore:
	stw_erp WA, 0xfa
	stda16 0x8d56, xwa
	stda16 0x8d58, xiz
	pop xiz
	ret

SndOutput_ReinitByMode_NotifyParam:
	ldb_d8 c, 0x8d54
	inc 1, c
	extz bc
	ld xwa, 0x300
	lds de, 3
	call SoundParam_NotifyChange
	ldb_d8 a, 0x8d52
	bit 5, a
	jr z, SndOutput_ReinitByMode_CheckBit3
	set 2, a
	stb_d8 0x8d52, a

SndOutput_ReinitByMode_CheckBit3:
	ldb_d8 a, 0x8d52
	bit 3, a
	ret z
	set 1, a
	stb_d8 0x8d52, a
	ret


MainCPU_self_test_routines:
	set_dd8 1, 0x30
	bit_dd8 0, 0x30
	ret nz
	lds wa, 0
	calr Test_DRAM_IC10_and_IC9
	extz hl
	ld wa, hl
	calr Test_SRAM_IC21
	extz hl
	ld wa, hl
	calr Report_test_result_by_blinking_LED
	calr A_Short_Pause
	lds wa, 0
	calr Test_PROGRAM_and_TABLE_DATA_ROMs
	extz hl
	ld wa, hl
	calr Report_test_result_by_blinking_LED
	lds wa, 0
	calr Test_Rhythm_data_ROM_IC14
	extz hl
	ld wa, hl
	calr Test_Custom_data_ROM_IC19
	extz hl
	ld wa, hl
	calr Test_LCD_Controller_IC206
	extz hl
	ld wa, hl
	calr Test_Video_RAM_IC207
	extz hl
	ld wa, hl
	calr Report_test_result_by_blinking_LED
	ret


Report_test_result_by_blinking_LED:
	ldb l, 0x0

Report_BlinkLoop:
	res_dd8 1, 0x30
	ldw bc, 0x4000
	bit 0, a
	jr z, Report_BlinkLoop_ShortFlash
	ldw bc, 0xc000
	jr Report_BlinkLoop_FlashOn

Report_BlinkLoop_ShortFlash:
	cps bc, 0
	jr z, Report_BlinkLoop_FlashOff

Report_BlinkLoop_FlashOn:
	ldb e, 0x0

Report_BlinkLoop_FlashDelay:
	inc 1, e
	cp e, 0x20
	jr c, Report_BlinkLoop_FlashDelay
	djnz xbc, Report_BlinkLoop_FlashOn

Report_BlinkLoop_FlashOff:
	set_dd8 1, 0x30
	ldw bc, 0x4000

Report_BlinkLoop_OffDelay:
	ldb e, 0x0

Report_BlinkLoop_OffDelayInner:
	inc 1, e
	cp e, 0x20
	jr c, Report_BlinkLoop_OffDelayInner
	djnz xbc, Report_BlinkLoop_OffDelay
	srl a, 1
	inc 1, l
	cps l, 3
	jr ule, Report_BlinkLoop
	ret


A_Short_Pause:
	lds bc, 0

ShortPause_OuterLoop:
	lds wa, 0

ShortPause_InnerLoop:
	inc 1, wa
	cp wa, 0x100
	jr c, ShortPause_InnerLoop
	inc 1, bc
	cp bc, 0x1000
	jr c, ShortPause_OuterLoop
	ret

DramTest_Loop:
	lds wa, 0

DramTest_DelayLoop:
	inc 1, wa
	cp wa, 0x10
	jr c, DramTest_DelayLoop
	ret


Test_DRAM_IC10_and_IC9:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 14), a
	ld (xsp + 4), 0x0

DramTest_IC10IC9_NextChip:
	ld a, (xsp + 4)
	extz wa
	muls wa, 0xa
	lda_24 xbc, WidgetStyleDataTable_0x6FC
	stb_dri B, 0x07, 0xe4, 0xe0
	ld xhl, (xde)
	ld xiz, (xde + 4)
	srl xiz, 3
	or xiz, xiz
	jr z, DramTest_IC10IC9_LoopEnd

DramTest_IC10IC9_WriteLoop:
	ld xwa, (xhl)
	ld (xsp + 6), xwa
	ld xwa, 0x5a5a5a5a
	ld (xhl), xwa
	ld xiy, xhl
	lda xix, (xsp + 10)
	ldiw
	ldiw
	lda xwa, (xsp + 10)
	ld xbc, xwa
	cpw (xwa), 0x5a5a
	jr z, DramTest_IC10IC9_Check5A_High
	ld a, (xde + 8)
	or (xsp + 14), a

DramTest_IC10IC9_Check5A_High:
	cpw (xbc + 2), 0x5a5a
	jr z, DramTest_IC10IC9_WriteA5
	ld a, (xde + 9)
	or (xsp + 14), a

DramTest_IC10IC9_WriteA5:
	ld xwa, (xsp + 6)
	stl_dpi XWA, 0xee
	ld xwa, (xhl)
	ld (xsp + 6), xwa
	ld xwa, 0xa5a5a5a5
	ld (xhl), xwa
	ld xiy, xhl
	lda xix, (xsp + 10)
	ldiw
	ldiw
	lda xwa, (xsp + 10)
	ld xbc, xwa
	cpw (xwa), 0xa5a5
	jr z, DramTest_IC10IC9_CheckA5_High
	ld a, (xde + 8)
	or (xsp + 14), a

DramTest_IC10IC9_CheckA5_High:
	cpw (xbc + 2), 0xa5a5
	jr z, DramTest_IC10IC9_RestoreAndNext
	ld a, (xde + 9)
	or (xsp + 14), a

DramTest_IC10IC9_RestoreAndNext:
	ld xwa, (xsp + 6)
	stl_dpi XWA, 0xee
	sub xiz, 0x1
	jr nz, DramTest_IC10IC9_WriteLoop

DramTest_IC10IC9_LoopEnd:
	incm8 1, (xsp + 4)
	cp (xsp + 4), 0x1
	jrl nz, DramTest_IC10IC9_NextChip
	ld l, (xsp + 14)
	extz hl
	pop xiz
	lda xsp, (xsp + 12)
	ret


Test_SRAM_IC21:
	ldb l, 0x0

SramTest_IC21_Loop:
	ld c, l
	extz bc
	muls bc, 0xa
	lda_24 xde, WidgetStyleDataTable_0x706
	stb_dri B, 0x07, 0xe8, 0xe4
	ld xiy, (xde)
	ld xbc, (xde + 4)
	srl xbc, 1
	ld xix, xbc
	or xix, xix
	jr z, SramTest_IC21_LoopEnd

SramTest_IC21_Write5A:
	ld w, (xiy)
	ld (xiy), 0x5a
	lda xbc, (xde + 8)
	cp (xiy), 0x5a
	jr z, SramTest_IC21_Verify5A
	or a, (xbc)

SramTest_IC21_Verify5A:
	lda_dpi XWA, 0xf4
	ld w, (xiy)
	ld (xiy), 0xa5
	cp (xiy), 0xa5
	jr z, SramTest_IC21_WriteA5
	or a, (xbc)

SramTest_IC21_WriteA5:
	lda_dpi XWA, 0xf4
	sub xix, 0x1
	jr nz, SramTest_IC21_Write5A

SramTest_IC21_LoopEnd:
	inc 1, l
	cps l, 1
	jr nz, SramTest_IC21_Loop
	ld l, a
	extz hl
	ret

Test_PROGRAM_and_TABLE_DATA_ROMs:
	lda xsp, (xsp - 18)
	push xiz
	ld (xsp + 20), a
	lda xbc, (xsp + 16)
	ldw (xbc), 0x0
	lda xwa, (xbc + 2)
	ld (xsp + 4), xwa
	ldw (xwa), 0x0
	lda xde, (xsp + 12)
	ldw (xde), 0x0
	lda xwa, (xde + 2)
	ld (xsp + 8), xwa
	ldw (xwa), 0x0
	ldib_erp 0xe2, 0

RomTest_ProgramTableData_OuterLoop:
	ld xhl, LED_patterns_indicating_firmware_version
	lds32 xix, 0

RomTest_ProgramTableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	stb_dri H, 0x07, 0xe4, 0xf4
	ld wa, (xiz)
	ldw_erp WA, 0xf6
	ld wa, (xhl)
	addw_erp WA, 0xf6
	ld (xiz), wa
	exts xiy
	add xiy, xde
	ld wa, (xiy)
	lda xiz, (xhl + 2)
	inc 4, xhl
	ld iz, (xiz)
	add iz, wa
	ld (xiy), iz
	inc 1, xix
	cp xix, 0x40000
	jr c, RomTest_ProgramTableData_SumLoop
	inc1b_erp 0xe2
	cpib_erp 0xe2, 2
	jr c, RomTest_ProgramTableData_OuterLoop
	ld hl, (xbc)
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	cp wa, hl
	jr z, RomTest_ProgramROM_Verify
	setm 0, (xsp + 20)

RomTest_ProgramROM_Verify:
	ld hl, (xde)
	ld xwa, (xsp + 8)
	cp (xwa), hl
	jr z, RomTest_PrepareTableDataTest
	setm 1, (xsp + 20)

RomTest_PrepareTableDataTest:
	ldw (xbc), 0x0
	ld xwa, (xsp + 4)
	ldw (xwa), 0x0
	ldw (xde), 0x0
	ld xwa, (xsp + 8)
	ldw (xwa), 0x0
	ldib_erp 0xe2, 0

RomTest_TableData_OuterLoop:
	ld xhl, 0x800000
	lds32 xix, 0

RomTest_TableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	stb_dri H, 0x07, 0xe4, 0xf4
	ld wa, (xiz)
	ldw_erp WA, 0xf6
	ld wa, (xhl)
	addw_erp WA, 0xf6
	ld (xiz), wa
	exts xiy
	add xiy, xde
	ld wa, (xiy)
	lda xiz, (xhl + 2)
	inc 4, xhl
	ld iz, (xiz)
	add iz, wa
	ld (xiy), iz
	inc 1, xix
	cp xix, 0x40000
	jr c, RomTest_TableData_SumLoop
	inc1b_erp 0xe2
	cpib_erp 0xe2, 2
	jr c, RomTest_TableData_OuterLoop
	ld xwa, (xsp + 4)
	ld wa, (xwa)
	cp wa, (xbc)
	jr z, RomTest_TableData_Verify
	setm 2, (xsp + 20)

RomTest_TableData_Verify:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	cp wa, (xde)
	jr z, RomTest_Done
	setm 3, (xsp + 20)

RomTest_Done:
	ld l, (xsp + 20)
	extz hl
	pop xiz
	lda xsp, (xsp + 18)
	ret

Test_Rhythm_data_ROM_IC14:
	dec 4, xsp
	push xiz
	lda xix, (xsp + 4)
	ldw (xix), 0x0
	lda xhl, (xix + 2)
	ldw (xhl), 0x0
	ldb w, 0x0

RhythmRomTest_OuterLoop:
	ld xiy, 0x400000
	lds32 xiz, 0

RhythmRomTest_SumLoop:
	ld c, w
	extz bc
	add bc, bc
	stb_dri B, 0x07, 0xf0, 0xe4
	ld bc, (xde)
	ldw_erp BC, 0xe2
	ld_spiw BC, 0xf5
	addw_erp BC, 0xe2
	ld (xde), bc
	inc 1, xiz
	cp xiz, 0x100000
	jr c, RhythmRomTest_SumLoop
	inc 1, w
	cps w, 2
	jr c, RhythmRomTest_OuterLoop
	ld bc, (xhl)
	cp bc, (xix)
	jr z, RhythmRomTest_Compare
	set 0, a

RhythmRomTest_Compare:
	lda_24 xix, WidgetStyleDataTable_0x6DA
	ld xiy, (xix)
	lda xbc, (xix + 4)
	ld xde, xbc
	lda xhl, (xbc + 4)

RhythmRomTest_ByteCompareLoop:
	ld c, (xiy)
	cp c, (xde)
	jr z, RhythmRomTest_ByteCompareNext
	or a, (xix + 8)

RhythmRomTest_ByteCompareNext:
	inc 1, xiy
	inc 1, xde
	cp xde, xhl
	jr c, RhythmRomTest_ByteCompareLoop
	ld l, a
	extz hl
	pop xiz
	inc 4, xsp
	ret

Test_Custom_data_ROM_IC19:
	dec 6, xsp
	pushw iz
	ld (xsp + 6), a
	lds wa, 1
	call Flash_IdentifyAndValidateChip
	cp hl, 0xffff
	jr nz, CustomRomTest_PrepareChecksum
	setm 1, (xsp + 6)

CustomRomTest_PrepareChecksum:
	lda xhl, (xsp + 2)
	ldw (xhl), 0x0
	lda xde, (xhl + 2)
	ldw (xde), 0x0
	ldib_erp 0xe2, 0

CustomRomTest_OuterLoop:
	ld xix, 0x300000
	lds32 xiy, 0

CustomRomTest_SumLoop:
	stb_erp A, 0xe2
	extz wa
	add wa, wa
	stb_dri A, 0x07, 0xec, 0xe0
	ld wa, (xbc)
	ld_spiw IZ, 0xf1
	add iz, wa
	ld (xbc), iz
	inc 1, xiy
	cp xiy, 0x40000
	jr c, CustomRomTest_SumLoop
	inc1b_erp 0xe2
	cpib_erp 0xe2, 2
	jr c, CustomRomTest_OuterLoop
	ld wa, (xde)
	cp wa, (xhl)
	jr z, CustomRomTest_Done
	setm 1, (xsp + 6)

CustomRomTest_Done:
	ld l, (xsp + 6)
	extz hl
	popw iz
	inc 6, xsp
	ret

Test_LCD_Controller_IC206:
	dec 2, xsp
	ld (xsp), a

	; equivalent to "_VGA_WRITE 3c3h, 0" but with CALL instead of CALR
	ldw wa, 0x3c3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cps l, 0
	jr z, LcdTest_WriteOneVerify
	setm 2, (xsp)

LcdTest_WriteOneVerify:
	; equivalent to "_VGA_WRITE 3c3h, 1" but with CALL instead of CALR
	ldw wa, 0x3c3
	lds bc, 1
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cps l, 1
	jr z, LcdTest_WriteZeroVerify
	setm 2, (xsp)

LcdTest_WriteZeroVerify:
	; equivalent to "_VGA_WRITE 3c3h, 0" but with CALL instead of CALR
	ldw wa, 0x3c3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cps l, 0
	jr z, LcdTest_Done
	setm 2, (xsp)

LcdTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

Test_Video_RAM_IC207:
	dec 2, xsp
	ld (xsp), a
	ldl_da xhl, WidgetStyleDataTable
	call (xhl)
	stiw_da 0x1a0000, 0x5a5a              ; VRAM self-test pattern 1
	calr DramTest_Loop
	cpw_da 0x1a0000, 0x5a5a
	jr z, VramTest_Pattern2
	setm 3, (xsp)

VramTest_Pattern2:
	stiw_da 0x1a0004, 0xa5a5              ; VRAM self-test pattern 2
	calr DramTest_Loop
	cpw_da 0x1a0004, 0xa5a5
	jr z, VramTest_Pattern3
	setm 3, (xsp)

VramTest_Pattern3:
	stiw_da 0x1a0008, 0x5a5a
	calr DramTest_Loop
	cpw_da 0x1a0008, 0x5a5a
	jr z, VramTest_Done
	setm 3, (xsp)

VramTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

SelfTest_FirmwareVersionCheck:
	pushw_erp 0xfa
	call Get_Firmware_Version
	cp l, 0x77
	jr nz, SelfTest_InterCPU_Send
	ldw wa, 0xfb
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	stdi8 0x8d82, 2
	jrl EffectMode_PopRetFA

SelfTest_InterCPU_Send:
	ld xwa, 0xf002
	ldw bc, 0x8
	ld xde, 0x8d64
	call InterCPU_E2_Send
	ld xwa, 0x3fffff
	jr SelfTest_WaitBitLoop_Check

SelfTest_WaitBitLoop_Copy:
	ld xiy, 0x620
	ld xix, 0x620
	ldiw
	sub xwa, 0x1
	jr z, SelfTest_WaitDone_CountBits

SelfTest_WaitBitLoop_Check:
	bitda 7, 1568
	jr nz, SelfTest_WaitBitLoop_Copy

SelfTest_WaitDone_CountBits:
	ldib_erp 0xfa, 0
	ldib_erp 0xfb, 0

SelfTest_CountBits_Loop:
	stb_erp C, 0xfb
	extz bc
	lda_d16 xwa, 0x8d64
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr SelfTest_PopCount
	stb_erp A, 0xfa
	add a, l
	ldb_erp A, 0xfa
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr c, SelfTest_CountBits_Loop
	cpib_erp 0xfa, 2
	jr nz, SelfTest_SramAndRom
	lda_d16 xde, 0x8d64
	ld c, (xde + 3)
	lda xwa, (xde + 4)
	bit 0, c
	jr z, SelfTest_CheckBit2
	bitm 4, (xwa)
	jr nz, SelfTest_Diagnostic_Skip

SelfTest_CheckBit2:
	bit 2, c
	jr z, SelfTest_CheckBit4
	bitm 6, (xwa)
	jr z, SelfTest_CheckBit4
	ldw wa, 0xf5
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit4:
	inc 5, xde
	bit 4, c
	jr z, SelfTest_CheckBit5
	bitm 0, (xde)
	jr z, SelfTest_CheckBit5
	ldw wa, 0xf6
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	jrl EffectMode_PopRetFA

SelfTest_CheckBit5:
	bit 5, c
	jr z, SelfTest_CheckBit7
	bitm 1, (xde)
	jr z, SelfTest_CheckBit7
	ldw wa, 0xf7
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit7:
	bit 7, c
	jr z, SelfTest_CheckBitA1
	bitm 3, (xde)
	jr z, SelfTest_CheckBitA1
	ldw wa, 0xf8
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA1:
	ld a, (xwa)
	bit 1, a
	jr z, SelfTest_CheckBitA3
	bitm 5, (xde)
	jr z, SelfTest_CheckBitA3
	ldw wa, 0xf9
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA3:
	bit 3, a
	jrl z, EffectMode_PopRetFA
	bitm 7, (xde)
	jrl z, EffectMode_PopRetFA
	ldw wa, 0xfc

EffectMode_UIPostModeChangeEvent:
	call UI_PostModeChangeEvent

SelfTest_Diagnostic_Skip:
	jrl EffectMode_PopRetFA

SelfTest_SramAndRom:
	ldib_erp 0xfa, 0
	lds wa, 0
	calr Test_SRAM_IC21
	cps hl, 0
	jr z, SelfTest_SramAndRom_CheckROM
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000f4
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call ApPostEvent
	ld xwa, SeqData_ScanTracks_OuterLoop_0xC
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldib_erp 0xfa, 1

SelfTest_SramAndRom_CheckROM:
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_PanelDetection_Wrapper
	stb_d8 0x8d7c, a
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldb_d8 a, 0x8d7c
	cpl a
	and a, 0x9
	stb_d8 0x8d7c, a
	cps a, 0
	jr z, EffectMode_PopRetFA
	cpib_erp 0xfa, 0
	jr nz, SelfTest_PostRomError
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	call DeleteEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000f4
	call ApPostEvent

SelfTest_PostRomError:
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call ApPostEvent
	ld xwa, SeqData_ScanTracks_InnerLoop_0x5
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent

EffectMode_PopRetFA:
	popw_erp 0xfa
	ret

SelfTest_PopCount:
	ldb l, 0x0
	ldb c, 0x0

SelfTest_PopCount_Loop:
	bit 0, a
	jr z, SelfTest_PopCount_ShiftNext
	inc 1, l

SelfTest_PopCount_ShiftNext:
	srl a, 1
	inc 1, c
	cp c, 0x8
	jr c, SelfTest_PopCount_Loop
	ret

EffectMode_CheckAndDispatch:
	cpdi8 0x8d36, 251
	jr nz, EffectMode_DispatchUpdate
	ldb_d8 a, 0x8d82
	cps a, 2
	jr z, EffectMode_ResetDiagMode
	ldb_d8 a, 0x8d80
	bit 0, a
	jr z, EffectMode_CheckAndDispatch_Bit4Clear
	bit 4, a
	jr nz, EffectMode_DispatchUpdate
	set 4, a
	stb_d8 0x8d80, a
	ldb_d8 a, 0x8d82
	cps a, 1
	jr z, EffectMode_DispatchUpdate
	stdi8 0x8d82, 1
	calr EffectMode_InitSwbWr_DiagMode
	calr EffectMode_SetAllLEDs
	jr EffectMode_DispatchUpdate

EffectMode_CheckAndDispatch_Bit4Clear:
	bit 4, a
	jr z, EffectMode_DispatchUpdate
	res 4, a
	stb_d8 0x8d80, a
	ldb_d8 a, 0x8d82
	cps a, 0
	jr z, EffectMode_DispatchUpdate
	stdi8 0x8d82, 0
	calr EffectMode_RestoreSwbWr_NormalMode
	calr LED_SetAll_WithBlank
	stdi8 0xe3de, 16
	jr EffectMode_DispatchUpdate

EffectMode_ResetDiagMode:
	stdi8 0x8d82, 0
	calr LED_SetAll_WithBlank
	calr EffectMode_RestoreSwbWr_NormalMode

EffectMode_DispatchUpdate:
	cpdi8 0x8d36, 248
	call_24 z, EffectMode_HandleTimerEvents
	cpdi8 0x8d36, 247
	call_24 z, EffectMode_ModeChangeTransition
	cpdi8 0x8d36, 251
	ret nz
	calr EffectMode_RunDiagSequence
	ret

EffectMode_InitSwbWr_DiagMode:
	lda_d16 xwa, 0xf9b6
	stib_dsp 0xe0, 0x00
	andmi8 (xwa), 0x80
	lda_d16 xbc, 0xfdb6
	andmi8 (xbc), 0xf0
	ld (xbc), 0x6
	ld e, (xwa)
	extz de
	pushw 0x7f
	lds wa, 0
	lds bc, 1
	call AddswbWr
	pushw 0xff
	lds wa, 0
	lds bc, 0
	lds de, 0
	call AddswbWr
	pushw 0xf
	ldw wa, 0x93
	lds bc, 0
	lds de, 6
	call AddswbWr
	ret

EffectMode_RestoreSwbWr_NormalMode:
	lda_d16 xwa, 0xf9b6
	stib_dsp 0xe0, 0x40
	andmi8 (xwa), 0x80
	anddi8 0xfdb6, 240
	ld e, (xwa)
	extz de
	pushw 0x7f
	lds wa, 0
	lds bc, 1
	call AddswbWr
	pushw 0xff
	lds wa, 0
	lds bc, 0
	ldw de, 0x40
	call AddswbWr
	pushw 0xf
	ldw wa, 0x93
	lds bc, 0
	lds de, 0
	call AddswbWr
	ret

EffectMode_HandleTimerEvents:
	call CtrlPanel_GetSelectionState
	cps hl, 0
	ret nz
	ldb_d8 a, 0x8d7a
	cp a, 0x96
	jrl z, EffectMode_TimerEvent_Step96
	cp a, 0x78
	jrl z, EffectMode_TimerEvent_Step78
	cp a, 0x5a
	jr z, EffectMode_TimerEvent_Step5A
	cp a, 0x3c
	jr z, EffectMode_TimerEvent_Step3C
	cp a, 0x1e
	jr z, EffectMode_TimerEvent_Step1E
	cps a, 0
	jrl nz, EffectMode_TimerEvent_Default
	ld xwa, AudioCtrl_PageHandler_0x11
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_TimerEvent_Step1E:
	ld xwa, AudioCtrl_PageHandler_0x13
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_TimerEvent_Step3C:
	ld xwa, AudioCtrl_PageHandler_0x15
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_TimerEvent_Step5A:
	ld xwa, AudioCtrl_PageHandler_0xB
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_TimerEvent_Step78:
	ld xwa, AudioCtrl_PageHandler_0xD
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_TimerEvent_Step96:
	ld xwa, AudioCtrl_PageHandler_0xF
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	stdi8 0x8d7a, 220
	ret

EffectMode_TimerEvent_Default:
	inc 1, a
	inc 1, a
	stb_d8 0x8d7a, a
	ret

EffectMode_RunDiagSequence:
	ldb_d8 a, 0x8d7a
	cps a, 0
	jr nz, EffectMode_DiagSeq_AnimFrame
	ld xwa, AudioCtrl_PageHandler_0xB
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, AudioCtrl_PageHandler_0xD
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, AudioCtrl_PageHandler_0xF
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, AudioCtrl_PageHandler_0x11
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, AudioCtrl_PageHandler_0x13
	ld xbc, 0x1c00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	incdi8 1, 0x8d7a
	ret

EffectMode_DiagSeq_AnimFrame:
	ldb_d8 c, 0x8d78
	cps c, 0
	jr nz, EffectMode_DiagSeq_DecrementDelay
	extz wa
	lda_24 xbc, WidgetStyleDataTable_0x554
	lds32 xde, 0
	ldb_sri E, 0x07, 0xe4, 0xe0
	add xde, 0x1a00000
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	call ApPostEvent
	ldb_d8 a, 0x8d7a
	cps a, 5
	jr nz, EffectMode_DiagSeq_IncFrame
	stdi8 0x8d7a, 1
	jr EffectMode_DiagSeq_SetDelay

EffectMode_DiagSeq_IncFrame:
	inc 1, a
	stb_d8 0x8d7a, a

EffectMode_DiagSeq_SetDelay:
	stdi8 0x8d78, 30
	ret

EffectMode_DiagSeq_DecrementDelay:
	dec 1, c
	stb_d8 0x8d78, c
	ret

EffectMode_ByteData_DiagEvents:
	push	qiz
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CPanel_PanelDetection_Wrapper
	stb_d8	0x8d7c, a
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ldb_d8	a, 0x8d7c
	cpl	a
	.byte 0xc7
	swi	3
	and	(xbc-55), ix
	push	216
	ccf
	calr	63353
	.byte 0xc7
	swi	3
	and	(xbc-55), d
	push	110
	ret
	ld	xwa, SeqStep_FileSectorPopReturn_0x35E
	ld	xbc, 0x1c00001
	lds32	xde, 0
	jr	51
	cp	a, 9
	jr	nz, 14
	ld	xwa, SeqStep_FileSectorPopReturn_0x361
	ld	xbc, 0x1c00001
	lds32	xde, 0
	jr	32
	.byte 0xc7
	swi	3
	ldw	hl, 0x6600
	ret
	ld	xwa, SeqStep_FileSectorPopReturn_0x364
	ld	xbc, 0x1c00001
	lds32	xde, 0
	jr	12
	ld	xwa, SeqStep_FileSectorPopReturn_0x367
	ld	xbc, 0x1c00001
	lds32	xde, 0
	call	ApPostEvent
	.byte 0xd7
	swi	2
	halt
	ret
	ldb_d8	a, 0x8d37
	.byte 0xc1
	ldw	iz, 0xf18d
	ret	z
	ld	xwa, 0x4002
	ldw	bc, 128
	lds	de, 3
	call	SndParam_LookupByKey
	call	Voice_InitializeAll
	ret

Voice_EmitNoteWithVelocity:
	cpdi8 0x8d36, 246
	ret nz
	stb_d8 0x8d84, a
	stb_d8 0x8d86, c
	ld xwa, 0xffffffff
	ld xbc, 0x1e20017
	lds32 xde, 0
	call ApPostEvent
	ret

EffectMode_ModeChangeTransition:
	ldb_d8 a, 0x8d37
	cpda8 a, 0x8d36
	jrl z, EffectMode_MidiParseLoop
	calr EffectMode_SetAllLEDs
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_Poll
	call CPanel_Poll
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	jr LED_SetAll_WithBlank

EffectMode_SetAllLEDs:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	jr EffectMode_SetAllLEDs_Loop

EffectMode_SetAllLEDs_SetOne:
	ld wa, bc
	srl wa, 8
	call Set_LEDs
	inc1b_erp 0xfb

EffectMode_SetAllLEDs_Loop:
	stb_erp A, 0xfb
	extz wa
	add wa, wa
	lda_24 xbc, WidgetStyleDataTable_0x6BA
	ldw_sri BC, 0x07, 0xe4, 0xe0
	cp bc, 0xffff
	jr nz, EffectMode_SetAllLEDs_SetOne
	popw_erp 0xfa
	ret

LED_SetAll_WithBlank:
	pushw_erp 0xfa
	ldib_erp 0xfb, 0
	jr LED_SetAll_BlankLoop

LED_SetAll_BlankOne:
	srl wa, 8
	lds bc, 0
	call Set_LEDs
	inc1b_erp 0xfb

LED_SetAll_BlankLoop:
	stb_erp A, 0xfb
	extz wa
	add wa, wa
	lda_24 xbc, WidgetStyleDataTable_0x6BA
	ldw_sri WA, 0x07, 0xe4, 0xe0
	cp wa, 0xffff
	jr nz, LED_SetAll_BlankOne
	popw_erp 0xfa
	ret


FDC_CommandAndPostEvent:
	; --- Stack-frame: alloc 16, conditional XDE setup, call dispatch (59 bytes) ---
	lda	xsp, (xsp-16)
	lda	xwa, (xsp)
	ldw	(xwa), 3
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldb_d8	a, 0x8a24
	cp a, 0xfc
	jr nz, FDC_PostEvent_Error
	ld xwa, 0xffffffff
	ld xbc, 0x01c0001e
	lds32	xde, 2
	jr t, FDC_PostEvent_Send
FDC_PostEvent_Error:
	ld xwa, 0xffffffff
	ld xbc, 0x01c0001e
	lds32	xde, 1
FDC_PostEvent_Send:
	call ApPostEvent
	lda	xsp, (xsp+16)
	ret


EffectMode_MidiParseLoop:
	push xiz
	lda_d16 xiz, 0x8d6c
	ld xwa, xiz
	call MIDI_ParseThreeByteParams
	cp hl, 0xffff
	jr z, EffectMode_MidiParse_Done

EffectMode_MidiParse_Continue:
	ld xwa, xiz
	calr EffectMode_MidiSetLEDs
	ld xwa, xiz
	call MIDI_ParseThreeByteParams
	cp hl, 0xffff
	jr nz, EffectMode_MidiParse_Continue

EffectMode_MidiParse_Done:
	pop xiz
	ret

EffectMode_MidiSetLEDs:
	push xiz
	ld xiz, xwa
	cp (xiz), 0x15
	jr ugt, EffectMode_MidiLED_Done
	lds32 xwa, 0
	ld a, (xiz + 2)
	call Util_FindLowestSetBit
	ld a, l
	add a, l
	ld c, a
	extz bc
	ld a, (xiz)
	extz wa
	sll wa, 4
	add wa, bc
	extz xwa
	lda_24 xde, WidgetStyleDataTable_0x55A
	ld xhl, xde
	add xhl, xwa
	ld l, (xhl)
	ld a, (xiz)
	extz wa
	sll wa, 4
	add wa, bc
	inc 1, wa
	extz xwa
	add xde, xwa
	ld c, (xde)
	ld a, (xiz + 2)
	and a, (xiz + 1)
	jr nz, EffectMode_MidiLED_HasMask
	ldb c, 0x0

EffectMode_MidiLED_HasMask:
	extz hl
	extz bc
	ld wa, hl
	call Set_LEDs

EffectMode_MidiLED_Done:
	pop xiz
	ret

TEST2FUNC:
	cp xbc, 0x1c00013
	jr nz, TableDispatch_Return3
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return3
	cp xde, 0x5
	jr ugt, TableDispatch_Return3
	add xde, xde
	add xde, WidgetStyleDataTable_0x710
	ld de, (xde)
	lda_24 xix, TEST2FUNC_DispatchReturn
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST2FUNC event dispatch return (6-entry, event 0x1c00013)
TEST2FUNC_DispatchReturn:
	calr	0xfdd8

TableDispatch_Return3:
	lds32 xhl, 0
	ret

TEST3FUNC:
	cp xbc, 0x1c00013
	jr nz, TableDispatch_Return4
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return4
	cp xde, 0x5
	jr ugt, TableDispatch_Return4
	add xde, xde
	add xde, WidgetStyleDataTable_0x71C
	ld de, (xde)
	lda_24 xix, TEST3FUNC_DispatchReturn
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST3FUNC event dispatch return (6-entry, event 0x1c00013)
TEST3FUNC_DispatchReturn:
	calr	0xfe19

TableDispatch_Return4:
	lds32 xhl, 0
	ret

TEST4FUNC:
	cp xbc, 0x1c00013
	jr nz, TableDispatch_Return5
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return5
	cp xde, 0x5
	jr ugt, TableDispatch_Return5
	add xde, xde
	add xde, WidgetStyleDataTable_0x728
	ld de, (xde)
	lda_24 xix, TEST4FUNC_DispatchReturn
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST4FUNC event dispatch return (6-entry, event 0x1c00013)
TEST4FUNC_DispatchReturn:
	calr	0xfe22

TableDispatch_Return5:
	lds32 xhl, 0
	ret

TEST6FUNC:
	cp xbc, 0x1c00013
	jr nz, TableDispatch_Return
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return
	cp xde, 0x5
	jr ugt, TableDispatch_Return
	add xde, xde
	add xde, WidgetStyleDataTable_0x734
	ld de, (xde)
	lda_24 xix, TEST6FUNC_DispatchReturn
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST6FUNC event dispatch return (6-entry, event 0x1c00013)
TEST6FUNC_DispatchReturn:
	calr	0xfe7e

TableDispatch_Return:
	lds32 xhl, 0
	ret

BitmapFinpic_ByteData:
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	ldb_d8	a, 0xc080
	.byte 0xc1
	push	xde
	.byte 0x8d, 0xf1
	ret	nz
	.byte 0xc1
	jrl	pl, 0x3fc0
	nop
	ret	nz
	call	GetTitleNow
	cp	xhl, 0x1a000f6
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x1c0000b
	lds32	xde, 0
	call	ApPostEvent
	ret

BitmapFinpic:
	cp xbc, 0x1e000a3
	jr z, BitmapFinpic_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFinpic_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFinpic_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFinpic_GetDataPtr:
	lda_24 xhl, Bitmap_FadeInPicture
	ret

BitmapFinpic_GetWidth:
	ld xhl, 0x70
	ret

BitmapFinpic_GetHeight:
	ld xhl, 0x19
	ret

BitmapFinst:
	cp xbc, 0x1e000a3
	jr z, BitmapFinst_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFinst_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFinst_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFinst_GetDataPtr:
	lda_24 xhl, Bitmap_FadeInText
	ret

BitmapFinst_GetWidth:
	ld xhl, 0x50
	ret

BitmapFinst_GetHeight:
	ld xhl, 0x12
	ret

BitmapFoutpic:
	cp xbc, 0x1e000a3
	jr z, BitmapFoutpic_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFoutpic_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFoutpic_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFoutpic_GetDataPtr:
	lda_24 xhl, Bitmap_FadeOutPicture
	ret

BitmapFoutpic_GetWidth:
	ld xhl, 0x71
	ret

BitmapFoutpic_GetHeight:
	ld xhl, 0x19
	ret

BitmapFoutst:
	cp xbc, 0x1e000a3
	jr z, BitmapFoutst_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFoutst_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFoutst_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFoutst_GetDataPtr:
	lda_24 xhl, Bitmap_FadeOutText
	ret

BitmapFoutst_GetWidth:
	ld xhl, 0x6c
	ret

BitmapFoutst_GetHeight:
	ld xhl, 0x14
	ret

SystemInitMDFunc:
	cp xbc, 0x1c00001
	jr nz, SystemInitMD_ReturnZero
	call GetTitleOld
	cp xhl, 0x1a000ee
	jr nz, SystemInitMD_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent

SystemInitMD_ReturnZero:
	lds32 xhl, 0
	ret

SystemInitOkFunc:
	ld xwa, 0x410002
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	exts xhl
	stl_da 0x0340de, xhl
	cpib_da 0x0340ea, 0x00
	jr nz, SystemInitOk_PostEvent
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	ld xde, xhl
	call MainFuncCall
	jr SystemInitOk_ReturnZero

SystemInitOk_PostEvent:
	ld xwa, 0x410007
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent

SystemInitOk_ReturnZero:
	lds32 xhl, 0
	ret

SysIniNoFunc:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00041
	call PostEvent
	lds32 xhl, 0
	ret

SysIniYesFunc:
	ldl_da xde, 0x0340de
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	call MainFuncCall
	lds32 xhl, 0
	ret

SysSureShowHideFunc:
	lds32 xhl, 0
	ret

AttnLngCheck:
	cp xbc, 0x1e0009f
	jr nz, AttnLngCheck_ReturnZero
	lda_24 xhl, NoteStr3_Blank_3_0x4
	ret

AttnLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SysSureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SysSureLngCheck_ReturnZero
	lda_24 xhl, Str_Attention_EN_0xC
	ret

SysSureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLngCheck_ReturnZero
	lda_24 xhl, Str_InitSettingWarn_IT_0x19A
	ret

SureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

CtlIniLngCheck:
	cp xbc, 0x1e0009f
	jr nz, CtlIniLngCheck_ReturnZero
	lda_24 xhl, Str_AreYouSure_IT_0x46
	ret

CtlIniLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemNormLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemNormLngCheck_ReturnZero
	lda_24 xhl, Str_FactoryResetDesc_EN3_0x156
	ret

PmemNormLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemExpLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemExpLngCheck_ReturnZero
	lda_24 xhl, Str_StoreSoundBalance_DE_0x58
	ret

PmemExpLngCheck_ReturnZero:
	lds32 xhl, 0
	ret
PmemExpLng_Boundary:

AcMstSugAlpGridBoxProc:
	jp InheritedProc

MstSugAlpGridCheck:
	lds32 xhl, 0
	ret
AcMstStyleAlp_Boundary:

AcMstStyleAlpGridBoxProc:
	lda xsp, (xsp - 74)
	push xiz
	ld (xsp + 66), xde
	ld (xsp + 70), xbc
	ld (xsp + 74), xwa
	ld xbc, (xsp + 70)
	cp xbc, 0x1e0008d
	jrl z, MasterSetup_ForwardToChild
	ld xwa, (xsp + 70)
	cp xwa, 0x1e0008b
	jrl z, MasterSetup_GetNameB_DrawString
	cp xwa, 0x1e0008a
	jrl z, MasterSetup_GetNameA
	cp xwa, 0x1c00007
	jrl z, MasterSetup_HandleDialTurn
	cp xwa, 0x1c00002
	jrl z, MasterSetup_HandleDialStop
	cp xwa, 0x1c00001
	jr z, MasterSetup_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, MasterSetup_InheritedProc_Fallback
	cp xbc, 0x6
	jrl gt, MasterSetup_InheritedProc_Fallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0x98
	ld bc, (xbc)
	lda_24 xix, MasterSetup_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; MasterSetup event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d24)
MasterSetup_EventDispatch:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 74)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00017
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld bc, iz
	ld (xsp + 60), bc
	ld xwa, (xsp + 66)
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp2
	ld xwa, (xsp + 8)
	ld xde, (xwa + 78)
	ld xwa, (xwa + 90)
	ld wa, (xwa)
	muls wa, 0x9
	sub wa, 0x9
	add wa, (xde)
	add bc, wa
	muls bc, 0x6
	ld wa, bc
	lda_24 xbc, StyleSong_MasterTable_0x4
	ldw_sri DE, 0x07, 0xe4, 0xe0
	extz xde
	ld xwa, 0x142000d
	ld xbc, 0x1e20018
	jr MasterSetup_CallMainFunc

MasterSetup_HandleDialStop:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, 0x142000d
	ld xbc, 0x1e20019
	lds32 xde, 0

MasterSetup_CallMainFunc:
	call MainFuncCall
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_HandleDialTurn:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	lda xbc, (xwa + 78)
	ld xwa, (xsp + 66)
	cp xwa, 0x80
	jrl z, MasterSetup_DialTurn_ScrollUp
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp2
	ld xbc, (xbc)
	cpw (xbc), 0x0
	jr z, MasterSetup_DialTurn_Underflow
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	muls wa, 0x6
	lda_24 xbc, StyleSong_MasterTable
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MasterSetup_DialTurn_UpdateView

MasterSetup_DialTurn_Underflow:
	ldl_da xwa, StyleSong_MasterTable_0x176A
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ldw (xwa), 0x3e7

MasterSetup_DialTurn_UpdateView:
	ld xde, (xsp + 8)
	ld xbc, (xde + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	ld xwa, (xde + 78)
	ld iz, (xwa)
	cps iz, 0
	jr z, MasterSetup_StringSearch_Done

MasterSetup_StringSearch_Loop:
	pushw 0x1
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, StyleSong_MasterTable
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, MasterSetup_StringSearch_Done
	djnz xiz, MasterSetup_StringSearch_Loop

MasterSetup_StringSearch_Done:
	cps iz, 0
	jr z, MasterSetup_StringSearch_Adjust
	inc 1, iz

MasterSetup_StringSearch_Adjust:
	ld xwa, (xsp + 8)
	lda xhl, (xwa + 82)
	ld xbc, (xhl)
	lda xde, (xwa + 78)
	ld xwa, (xde)
	ld wa, (xwa)
	sub wa, iz
	ld (xbc), wa
	ld xwa, (xde)
	ld (xwa), iz
	ld xde, (xsp + 4)
	ld xbc, (xde + 86)
	ld xwa, (xhl)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xde + 90)
	ldw (xwa), 0x1
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00017
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc

MasterSetup_DialTurn_ScrollUp:
	ld xix, xbc
	ld xde, (xbc)
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 82)
	ld bc, (xwa)
	add bc, (xde)
	inc 1, bc
	ld hl, bc
	lda xbc, (xsp + 12)
	cp hl, 0x3e8
	jr nc, MasterSetup_ScrollUp_Overflow
	ld hl, (xde)
	ld wa, (xwa)
	add wa, hl
	inc 1, wa
	ld (xde), wa
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0x6
	lda_24 xde, StyleSong_MasterTable
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	jr MasterSetup_ScrollUp_UpdateView

MasterSetup_ScrollUp_Overflow:
	ldl_da xwa, StyleSong_MasterTable
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ldw (xwa), 0x0

MasterSetup_ScrollUp_UpdateView:
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	lds iz, 0
	jr MasterSetup_ScrollUp_Search_Check

MasterSetup_ScrollUp_Search_Loop:
	pushw 0x1
	add wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, StyleSong_MasterTable
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, MasterSetup_ScrollUp_Search_Done
	inc 1, iz

MasterSetup_ScrollUp_Search_Check:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3e8
	sub bc, wa
	cp iz, bc
	jr c, MasterSetup_ScrollUp_Search_Loop

MasterSetup_ScrollUp_Search_Done:
	ld xhl, (xsp + 8)
	lda xbc, (xhl + 82)
	ld xwa, (xbc)
	ld de, iz
	dec 1, de
	ld (xwa), de
	ld xde, (xhl + 86)
	ld xwa, (xbc)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	inc 1, wa
	ld (xde), wa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 90)
	ldw (xwa), 0x1
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 74)
	ld xbc, 0x1e00050
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, MasterSetup_FallbackEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	jrl nz, MasterSetup_DialDown_SendPageEvent
	ld xbc, (xsp + 8)
	ld xwa, (xbc + 90)
	cpw (xwa), 0x1
	jrl nz, MasterSetup_DialDown_DecPage
	ld xbc, (xbc + 78)
	lda xde, (xsp + 12)
	lda_24 xhl, StyleSong_MasterTable
	cpw (xbc), 0x0
	jr z, MasterSetup_DialDown_Underflow
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	jr MasterSetup_DialDown_UpdateView

MasterSetup_DialDown_Underflow:
	ld_sril XWA, (xhl + 0x176a)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 78)
	ldw (xwa), 0x3e7

MasterSetup_DialDown_UpdateView:
	ld xde, (xsp + 8)
	ld xbc, (xde + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	ld xwa, (xde + 78)
	ld iz, (xwa)
	cps iz, 0
	jr z, MasterSetup_DialDown_Search_Done

MasterSetup_DialDown_Search_Loop:
	pushw 0x1
	ld wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, StyleSong_MasterTable
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, MasterSetup_DialDown_Search_Done
	djnz xiz, MasterSetup_DialDown_Search_Loop

MasterSetup_DialDown_Search_Done:
	cps iz, 0
	jr z, MasterSetup_DialDown_AdjustView
	inc 1, iz

MasterSetup_DialDown_AdjustView:
	ld xwa, (xsp + 8)
	lda xhl, (xwa + 82)
	ld xbc, (xhl)
	ld xix, (xsp + 4)
	lda xde, (xix + 78)
	ld xwa, (xde)
	ld wa, (xwa)
	sub wa, iz
	ld (xbc), wa
	ld xwa, (xde)
	ld (xwa), iz
	lda xde, (xix + 86)
	ld xbc, (xde)
	ld xwa, (xhl)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	inc 1, wa
	ld (xbc), wa
	ld xbc, (xix + 90)
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), wa
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	stw_erp DE, 0xe2
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc

MasterSetup_DialDown_DecPage:
	decm 1, (xwa)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0008
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc

MasterSetup_DialDown_SendPageEvent:
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call ApFuncCall
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_FallbackEvent:
	ld xwa, (xsp + 74)
	ld xbc, 0x1e00091
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, SeqFile_ReturnZeroJmp2
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call ApFuncCall
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00018
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00017
	ld xde, (xsp + 66)
	call SetDialDown
	lds wa, 1
	jrl MasterSetup_SetDialEnable
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 74)
	ld xbc, 0x1e00050
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyleAlp_FallbackDispatch
	ld xwa, (xsp + 74)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xix, (xsp + 8)
	ld xde, (xix + 82)
	ld xbc, (xix + 90)
	ld wa, (xbc)
	muls wa, 0x9
	dec 1, wa
	cp wa, (xde)
	jrl lt, MstStyleAlp_PageForward
	ld wa, (xde)
	exts xwa
	divs wa, 0x9
	stw_erp WA, 0xe2
	cp wa, hl
	jrl nz, MstStyleAlp_SelectAndAutoInc
	lda xix, (xix + 78)
	ld xwa, (xix)
	ld bc, (xde)
	add bc, (xwa)
	inc 1, bc
	ld hl, bc
	lda_24 xbc, StyleSong_MasterTable
	cp hl, 0x3e8
	jr nc, MstStyleAlp_OverflowCopy
	ld hl, (xwa)
	ld de, (xde)
	add de, hl
	inc 1, de
	ld (xwa), de
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MstStyleAlp_UpdateFocusIndex

MstStyleAlp_OverflowCopy:
	ld xwa, (xbc)
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ldw (xwa), 0x0

MstStyleAlp_UpdateFocusIndex:
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	lds iz, 0
	jr MstStyleAlp_CompareLoopCond

MstStyleAlp_CompareEntry:
	pushw 0x1
	add wa, iz
	extz xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	ld xwa, StyleSong_MasterTable
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xa
	cps hl, 0
	jr nz, MstStyleAlp_CompareComplete
	inc 1, iz

MstStyleAlp_CompareLoopCond:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3e8
	sub bc, wa
	cp iz, bc
	jr c, MstStyleAlp_CompareEntry

MstStyleAlp_CompareComplete:
	ld xwa, (xsp + 8)
	lda xbc, (xwa + 82)
	ld xwa, (xbc)
	ld de, iz
	dec 1, de
	ld (xwa), de
	ld xhl, (xsp + 4)
	ld xde, (xhl + 86)
	ld xwa, (xbc)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	inc 1, wa
	ld (xde), wa
	ld xwa, (xhl + 90)
	ldw (xwa), 0x1
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc

MstStyleAlp_PageForward:
	cp hl, 0x8
	jr nz, MstStyleAlp_SelectAndAutoInc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 86)
	ld wa, (xwa)
	cp wa, (xbc)
	jrl z, SeqFile_ReturnZeroJmp2
	incm 1, (xbc)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jrl SeqFile_CallApFunc

MstStyleAlp_SelectAndAutoInc:
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call ApFuncCall
	jrl SeqFile_ReturnZeroJmp2

MstStyleAlp_FallbackDispatch:
	ld xwa, (xsp + 74)
	ld xbc, 0x1e00091
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, SeqFile_ReturnZeroJmp2
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call ApFuncCall
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00018
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1c00017
	ld xde, (xsp + 66)
	call SetDialDown
	lds wa, 1

MasterSetup_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_GetNameA:
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	ld xwa, (xsp + 70)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_GetNameB_DrawString:
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 66)
	push xwa
	ld xwa, (xsp + 70)
	push xwa
	call Strcpy
	lda xhl, (xsp + 54)
	ldw (xhl), 0xe
	lda xbc, (xhl + 2)
	ldw (xbc), 0x2e
	lda xde, (xsp + 58)
	ld wa, (xhl)
	ld (xde), wa
	ld wa, (xhl)
	add wa, 0x50
	ld (xde + 4), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x13
	ld (xde + 6), wa
	ld xwa, (xiz + 86)
	pushm (xwa)
	ld xwa, (xiz + 90)
	pushm (xwa)
	ld xwa, (xiz + 74)
	pushm (xwa)
	pushw 0xed
	pushw 0xd18
	lda xwa, (xsp + 30)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 22)
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 12)
	lds32 xhl, 1
	push xhl
	pushw 0xfb
	pushw 0xf5
	call DrawString
	jr SeqFile_ReturnZeroJmp2
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jr SeqFile_CallApFunc

MasterSetup_ForwardToChild:
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)

SeqFile_CallApFunc:
	call ApFuncCall

SeqFile_ReturnZeroJmp2:
	lds32 xhl, 0
	jr MasterSetup_Epilogue

MasterSetup_InheritedProc_Fallback:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc

MasterSetup_Epilogue:
	pop xiz
	lda xsp, (xsp + 74)
	ret

MstStyleAlpGridCheck:
	lda xsp, (xsp - 58)
	push xiz
	ld (xsp + 58), xde
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, MstStyleAlp_CellSelect
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, EffectMode_SendEvent_Return
	cp xwa, 0x6
	jrl gt, EffectMode_SendEvent_Return
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0xCC
	ld wa, (xwa)
	lda_24 xix, MstStyleAlp_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyleAlpGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d58)
MstStyleAlp_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+58), xhl
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	xde, (xsp+58)
	ld	(xsp+52), de
	ld	xbc, (xhl+78)
	ld	xwa, (xhl+90)
	ld	wa, (xwa)
	muls	wa, 9
	sub	wa, 9
	add	wa, (xbc)
	add	de, wa
	muls	de, 6
	lda_24	xbc, StyleSong_MasterTable_0x4
	ld_rrw	de, xbc, de
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	call	MainFuncCall
	jrl	408

MstStyleAlp_CellSelect:
	call GetFocusObject
	ld xwa, xhl
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xde, (xsp + 50)
	ld xwa, (xsp + 58)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xde), wa
	lda xbc, (xde + 2)
	ld xwa, (xsp + 58)
	ld (xbc), wa
	lda xwa, (xsp + 16)
	ld (xsp + 12), xwa
	ld (xde + 4), xwa
	ld xwa, (xsp + 4)
	lda xix, (xwa + 90)
	ld xhl, (xix)
	lda xde, (xwa + 86)
	ld xiy, (xde)
	lda_24 xwa, StyleSong_MasterTable
	ld (xsp + 8), xwa
	ld xix, (xix)
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 78)
	ld wa, (xix)
	muls wa, 0x9
	sub wa, 0x9
	ld ix, wa
	add ix, (xiz)
	ld wa, (xiy)
	cp wa, (xhl)
	jrl nz, MstStyleAlp_CopyEntryAndPad
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 82)
	ld xwa, (xde)
	ld wa, (xwa)
	muls wa, 0x9
	sub wa, 0xa
	ld de, (xhl)
	sub de, wa
	ld wa, (xbc)
	cp wa, de
	jr ge, MstStyleAlp_OverflowStr
	add wa, ix
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 14), 0x0
	jr MstStyleAlp_PadLoopCond

MstStyleAlp_AppendPadChar:
	pushw 0x1
	pushw 0xed
	pushw 0xd32
	lda xwa, (xsp + 22)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 14)

MstStyleAlp_PadLoopCond:
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 78)
	ld xwa, (xwa + 90)
	ld wa, (xwa)
	muls wa, 0x9
	sub wa, 0x9
	add wa, (xbc)
	ld bc, (xsp + 52)
	add bc, wa
	muls bc, 0x6
	ld wa, bc
	lda_24 xbc, StyleSong_MasterTable
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 14)
	extz wa
	cp wa, bc
	jr c, MstStyleAlp_AppendPadChar
	jrl MstStyleAlp_FinalSendEvent

MstStyleAlp_OverflowStr:
	pushw 0xed
	pushw 0xd34
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MstStyleAlp_FinalSendEvent

MstStyleAlp_CopyEntryAndPad:
	ld wa, (xbc)
	add wa, ix
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 14), 0x0
	jr MstStyleAlp_PadLoopCond2

MstStyleAlp_AppendPadChar2:
	pushw 0x1
	pushw 0xed
	pushw 0xd56
	lda xwa, (xsp + 22)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 14)

MstStyleAlp_PadLoopCond2:
	ld xwa, (xsp + 4)
	ld xbc, (xwa + 78)
	ld xwa, (xwa + 90)
	ld wa, (xwa)
	muls wa, 0x9
	sub wa, 0x9
	add wa, (xbc)
	ld bc, (xsp + 52)
	add bc, wa
	muls bc, 0x6
	ld wa, bc
	lda_24 xbc, StyleSong_MasterTable
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 14)
	extz wa
	cp wa, bc
	jr c, MstStyleAlp_AppendPadChar2

MstStyleAlp_FinalSendEvent:
	ld wa, (xsp + 50)
	cps wa, 1
	jr nz, EffectMode_SendEvent_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 50)
	ld xbc, 0x1e0008c
	call SendEvent

EffectMode_SendEvent_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 58)
	ret
MstStyle1Grid_Boundary:

AcMstStyle1GridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1e0008d
	jrl z, MstStyle_ForwardToChild
	ld xwa, (xsp + 12)
	cp xwa, 0x1e0008b
	jrl z, MstStyle_GetNameB
	cp xwa, 0x1e0008a
	jrl z, MstStyle_GetNameA
	cp xwa, 0x1c00001
	jr z, MstStyle_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, MstStyle_InheritedProc_Fallback
	cp xbc, 0x6
	jrl gt, MstStyle_InheritedProc_Fallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0xDA
	ld bc, (xbc)
	lda_24 xix, MstStyle_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; MasterStyle event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d66)
MstStyle_EventDispatch:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 78)
	ldw (xwa), 0x1
	ld xwa, (xiz + 74)
	ldw (xwa), 0xa
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iy, hl
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, iy
	stw_da 0x0340c4, xwa
	jrl SeqFileAlt_ReturnZeroJmp
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle_FallbackEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iy, hl
	cps iy, 0
	jr nz, MstStyle_DialDown_Decrement
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 82)
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jrl le, SeqFileAlt_ReturnZeroJmp
	decm 1, (xwa)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	stw_da 0x0340c4, xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0009
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xffffffff
	ld xbc, 0x1c20005
	lds32 xde, 0
	jr MstStyle_DialDown_PostEvent

MstStyle_DialDown_Decrement:
	decdi16_24 1, 0x340c4
	ld wa, iy
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xffffffff
	ld xbc, 0x1c20005
	lds32 xde, 0

MstStyle_DialDown_PostEvent:
	call SendEvent
	jrl SeqFileAlt_ReturnZeroJmp

MstStyle_FallbackEvent:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, SeqFileAlt_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jrl MstStyle_SetAutoInc_Return
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle_DialUp_FallbackEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iy, hl
	lda xhl, (xiz + 82)
	ld xde, (xhl)
	ld xix, (xiz + 78)
	ld bc, iy
	inc 1, bc
	ld wa, (xde)
	cp wa, (xix)
	jrl ge, MstStyle_DialUp_CheckLimit
	cp iy, 0x9
	jr nz, MstStyle_DialUp_Increment
	incm 1, (xde)
	ld xwa, (xhl)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	stw_da 0x0340c4, xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xffffffff
	ld xbc, 0x1c20005
	lds32 xde, 0
	jrl MstStyle_DialUp_PostEvent

MstStyle_DialUp_Increment:
	incdi16_24 1, 0x340c4
	ld de, bc
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xffffffff
	ld xbc, 0x1c20005
	lds32 xde, 0
	jr MstStyle_DialUp_PostEvent

MstStyle_DialUp_CheckLimit:
	ld xwa, (xiz + 74)
	ld de, (xwa)
	ld wa, de
	exts xwa
	divs wa, 0xa
	muls wa, 0xa
	ld hl, wa
	exts xde
	divs de, 0xa
	stw_erp DE, 0xea
	add de, hl
	ld wa, bc
	cp bc, de
	jrl ge, SeqFileAlt_ReturnZeroJmp
	incdi16_24 1, 0x340c4
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xffffffff
	ld xbc, 0x1c20005
	lds32 xde, 0

MstStyle_DialUp_PostEvent:
	call SendEvent
	jr SeqFileAlt_ReturnZeroJmp

MstStyle_DialUp_FallbackEvent:
	ld xwa, (xsp + 16)
	ld xbc, 0x1e00091
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, SeqFileAlt_ReturnZeroJmp
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

MstStyle_SetAutoInc_Return:
	call SetAutoInc
	jr SeqFileAlt_ReturnZeroJmp

MstStyle_GetNameA:
	ld xwa, (xsp + 16)
	ld xiz, 0x3e
	jr MstStyle_GetName_Load

MstStyle_GetNameB:
	ld xwa, (xsp + 16)
	ld xiz, 0x42

MstStyle_GetName_Load:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jr SeqFileAlt_ReturnZeroJmp

MstStyle_ForwardToChild:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall

SeqFileAlt_ReturnZeroJmp:
	lds32 xhl, 0
	jr MstStyle_Epilogue

MstStyle_InheritedProc_Fallback:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc

MstStyle_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

MstStyle1GridCheck:
	lda xsp, (xsp - 38)
	push xiz
	ld (xsp + 38), xde
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jr z, MstStyle1Grid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1Grid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1Grid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0xFE
	ld wa, (xwa)
	lda_24 xix, MstStyle1Grid_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1GridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d8a)
MstStyle1Grid_EventDispatch:
	jrl	t, 0x0167

MstStyle1Grid_CellSelect:
	call GetFocusObject
	ld xwa, xhl
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xhl, (xsp + 30)
	ld xwa, (xsp + 38)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	lda xde, (xhl + 2)
	ld xwa, (xsp + 38)
	ld (xde), wa
	lda xbc, (xsp + 12)
	ld (xhl + 4), xbc
	ld xwa, (xsp + 4)
	lda xix, (xwa + 82)
	ld xiy, (xix)
	lda xhl, (xwa + 78)
	ld xiz, (xhl)
	lda_24 xwa, StyleGroup_LatinWorld_PairTable_0x2FA
	ld (xsp + 8), xwa
	ld xwa, (xix)
	ld ix, (xwa)
	muls ix, 0xa
	sub ix, 0xa
	ld wa, (xiz)
	cp wa, (xiy)
	jrl nz, MstStyle1Grid_BottomSection
	ld xwa, (xsp + 4)
	ld xiy, (xwa + 74)
	ld xwa, (xhl)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld hl, (xiy)
	sub hl, wa
	ld wa, (xde)
	cp wa, hl
	jr ge, MstStyle1Grid_OutOfRange
	add ix, wa
	sla ix, 3
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xf0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld (xsp + 10), 0x0
	jr MstStyle1Grid_PadLeft_Check

MstStyle1Grid_PadLeft_Loop:
	pushw 0x1
	pushw 0xed
	pushw 0xd74
	lda xwa, (xsp + 18)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 10)

MstStyle1Grid_PadLeft_Check:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, (xsp + 32)
	sla wa, 3
	lda_24 xbc, StyleGroup_LatinWorld_PairTable_0x2FA
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	ld a, (xsp + 10)
	extz wa
	cp wa, bc
	jr c, MstStyle1Grid_PadLeft_Loop
	jr MstStyle1Grid_CheckPlayAudio

MstStyle1Grid_OutOfRange:
	pushw 0xed
	pushw 0xd76
	push xbc
	call Strcpy
	inc 8, xsp
	jr MstStyle1Grid_CheckPlayAudio

MstStyle1Grid_BottomSection:
	add ix, (xde)
	sla ix, 3
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xe0, 0xf0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld (xsp + 10), 0x0
	jr MstStyle1Grid_PadLeft_CheckB

MstStyle1Grid_PadLeft_LoopB:
	pushw 0x1
	pushw 0xed
	pushw 0xd88
	lda xwa, (xsp + 18)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 10)

MstStyle1Grid_PadLeft_CheckB:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, (xsp + 32)
	sla wa, 3
	lda_24 xbc, StyleGroup_LatinWorld_PairTable_0x2FA
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	ld a, (xsp + 10)
	extz wa
	cp wa, bc
	jr c, MstStyle1Grid_PadLeft_LoopB

MstStyle1Grid_CheckPlayAudio:
	ld wa, (xsp + 30)
	cps wa, 1
	jr nz, MstStyle1Grid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 30)
	ld xbc, 0x1e0008c
	call SendEvent

MstStyle1Grid_ReturnZero:
	lds32 xhl, 0

MstStyle1Grid_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret
MstStyle1SubGrid_Boundary:

AcMstStyle1SubGridBoxProc:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 58), xde
	ld (xsp + 62), xbc
	ld (xsp + 66), xwa
	ld xbc, (xsp + 62)
	cp xbc, 0x1e0008d
	jrl z, MstStyle1Sub_ForwardToChild
	ld xwa, (xsp + 62)
	cp xwa, 0x1e0008b
	jrl z, MstStyle1Sub_GetNameB_DrawString
	cp xwa, 0x1e0008a
	jrl z, MstStyle1Sub_GetNameA
	cp xwa, 0x1c20005
	jrl z, MstStyle1Sub_HandleSubSelect
	cp xwa, 0x1c0000b
	jrl z, MstStyle1Sub_HandleScroll
	cp xwa, 0x1c00001
	jr z, MstStyle1_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, MstStyle1Sub_InheritedFallback
	cp xbc, 0x6
	jrl gt, MstStyle1Sub_InheritedFallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0x112
	ld bc, (xbc)
	lda_24 xix, MstStyle1_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; MstStyle1 event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d9e)
MstStyle1_EventDispatch:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 66)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00017
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 58)
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp
	ldw_da xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, StyleGroup_LatinDance_Table
	add xbc, xwa
	ld xde, (xbc)
	stl_da 0x0340d2, xde
	ldb c, 0x0

MstStyle1Sub_CountEntries_Loop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle1Sub_CountEntries_Done
	inc 1, c
	cp c, 0xff
	jr c, MstStyle1Sub_CountEntries_Loop

MstStyle1Sub_CountEntries_Done:
	cps c, 0
	jr z, MstStyle1Sub_CountEntries_Adjust
	dec 1, c

MstStyle1Sub_CountEntries_Adjust:
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	stw_da 0x0340c6, xwa
	ld xhl, (xsp + 8)
	ld xde, (xhl + 74)
	ld a, c
	extz wa
	ld (xde), wa
	ld xde, (xhl + 78)
	extz bc
	div c, 0xa
	inc 1, c
	extz bc
	ld (xde), bc
	ld xwa, xhl
	ld xbc, (xwa + 82)
	ldw_da xwa, 0x0340c6
	extz xwa
	div wa, 0xa
	inc 1, wa
	ld (xbc), wa
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_HandleScroll:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ldw_da xwa, 0x0340c6
	extz xwa
	div wa, 0xa
	stw_erp DE, 0xe2
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	call SendEvent
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_HandleSubSelect:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ldw_da xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, StyleGroup_LatinDance_Table
	add xbc, xwa
	ld xde, (xbc)
	stl_da 0x0340d2, xde
	ldb c, 0x0

MstStyle1Sub_SubSel_CountLoop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle1Sub_SubSel_CountDone
	inc 1, c
	cp c, 0xff
	jr c, MstStyle1Sub_SubSel_CountLoop

MstStyle1Sub_SubSel_CountDone:
	cps c, 0
	jr z, MstStyle1Sub_SubSel_Adjust
	dec 1, c

MstStyle1Sub_SubSel_Adjust:
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	stw_da 0x0340c6, xwa
	ld xde, (xhl + 74)
	ld a, c
	extz wa
	ld (xde), wa
	ld xde, (xhl + 78)
	extz bc
	div c, 0xa
	inc 1, c
	extz bc
	ld (xde), bc
	ld xbc, (xhl + 82)
	ldw_da xwa, 0x0340c6
	extz xwa
	div wa, 0xa
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call PostEvent
	jrl SeqFile_ReturnZeroJmp
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 66)
	ld xbc, 0x1e00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	lda_24 xbc, 0x0340c8
	cps hl, 0
	jr nz, MstStyle1Sub_DialDown_Decrement
	ld xwa, (xsp + 8)
	lda xde, (xwa + 82)
	ld xwa, (xde)
	cpw (xwa), 0x1
	jrl le, SeqFile_ReturnZeroJmp
	decm 1, (xwa)
	ld xwa, (xde)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	stw_da 0x0340c6, xwa
	ldw_da xde, 0x0340c4
	extz xde
	add xbc, xde
	ld (xbc), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0009
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	jr MstStyle1Sub_DialDown_SetAutoInc

MstStyle1Sub_DialDown_Decrement:
	ldw_da xwa, 0x0340c6
	dec 1, wa
	stw_da 0x0340c6, xwa
	ldw_da xde, 0x0340c4
	extz xde
	add xbc, xde
	ld (xbc), a
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)

MstStyle1Sub_DialDown_SetAutoInc:
	call SetAutoInc
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_FallbackEvent:
	ld xwa, (xsp + 66)
	ld xbc, 0x1e00091
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, SeqFile_ReturnZeroJmp
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call ApFuncCall
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00018
	ld xde, (xsp + 58)
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00017
	ld xde, (xsp + 58)
	call SetDialDown
	lds wa, 1
	jrl MstStyle1Sub_SetDialEnable
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 66)
	ld xbc, 0x1e00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_DialUp_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	lda xiz, (xwa + 82)
	ld xiy, (xiz)
	ld xix, (xwa + 78)
	ld wa, hl
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ldw_da xbc, 0x0340c6
	ld wa, (xiy)
	cp wa, (xix)
	jr ge, MstStyle1Sub_DialUp_CheckLimit
	lda_24 xix, 0x0340c8
	cp hl, 0x9
	jr nz, MstStyle1Sub_DialUp_Increment
	incm 1, (xiy)
	ld xwa, (xiz)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	stw_da 0x0340c6, xwa
	ldw_da xbc, 0x0340c4
	extz xbc
	add xix, xbc
	ld (xix), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	jr MstStyle1Sub_DialUp_SetAutoInc

MstStyle1Sub_DialUp_Increment:
	inc 1, bc
	stw_da 0x0340c6, xbc
	ldw_da xwa, 0x0340c4
	extz xwa
	add xix, xwa
	ld (xix), c
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	jr MstStyle1Sub_DialUp_SetAutoInc

MstStyle1Sub_DialUp_CheckLimit:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 74)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	stw_erp WA, 0xe2
	cp hl, wa
	jrl ge, SeqFile_ReturnZeroJmp
	inc 1, bc
	stw_da 0x0340c6, xbc
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xhl, 0x340c8
	add xhl, xwa
	ld (xhl), c
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)

MstStyle1Sub_DialUp_SetAutoInc:
	call SetAutoInc
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_DialUp_FallbackEvent:
	ld xwa, (xsp + 66)
	ld xbc, 0x1e00091
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, SeqFile_ReturnZeroJmp
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call ApFuncCall
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00018
	ld xde, (xsp + 58)
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1c00017
	ld xde, (xsp + 58)
	call SetDialDown
	lds wa, 1

MstStyle1Sub_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_GetNameA:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	ld xwa, (xsp + 62)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_GetNameB_DrawString:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 66)
	push xwa
	ld xwa, (xsp + 62)
	push xwa
	call Strcpy
	lda xhl, (xsp + 54)
	ldw (xhl), 0xfe
	lda xbc, (xhl + 2)
	ldw (xbc), 0x23
	lda xde, (xsp + 58)
	ld wa, (xhl)
	ld (xde), wa
	ld wa, (xhl)
	add wa, 0x1e
	ld (xde + 4), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x13
	ld (xde + 6), wa
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 78)
	pushm (xwa)
	ld xwa, (xbc + 82)
	pushm (xwa)
	pushw 0xed
	pushw 0xd98
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 20)
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 12)
	lds32 xhl, 6
	push xhl
	pushw 0xff
	pushw 0xf5
	call DrawString
	jr SeqFile_ReturnZeroJmp

MstStyle1Sub_ForwardToChild:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call ApFuncCall

SeqFile_ReturnZeroJmp:
	lds32 xhl, 0
	jr MstStyle1Sub_Epilogue

MstStyle1Sub_InheritedFallback:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc

MstStyle1Sub_Epilogue:
	pop xiz
	lda xsp, (xsp + 66)
	ret

MstStyle1SubGridCheck:
	lda xsp, (xsp - 30)
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jr z, MstStyle1SubGrid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1SubGrid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1SubGrid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0x136
	ld wa, (xwa)
	lda_24 xix, MstStyle1Sub_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1SubGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0dc2)
MstStyle1Sub_EventDispatch:
	jrl	t, 0x015b

MstStyle1SubGrid_CellSelect:
	call GetFocusObject
	ld xwa, xhl
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xwa, (xsp + 26)
	ld xbc, xiz
	srl xbc, 0
	ldiw_erp 0xe6, 0
	ld (xwa), bc
	lda xbc, (xwa + 2)
	ld de, iz
	ld (xbc), de
	lda xde, (xsp + 8)
	ld (xwa + 4), xde
	ld xwa, (xsp + 4)
	lda xhl, (xwa + 82)
	ld xiy, (xhl)
	lda xix, (xwa + 78)
	ld xiz, (xix)
	ld xwa, (xhl)
	ld hl, (xwa)
	muls hl, 0xa
	sub hl, 0xa
	ld wa, (xiz)
	cp wa, (xiy)
	jrl nz, MstStyle1SubGrid_BottomSection
	ld xwa, (xsp + 4)
	ld xiy, (xwa + 74)
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld ix, (xiy)
	sub ix, wa
	ld wa, (xbc)
	cp wa, ix
	jr gt, MstStyle1SubGrid_OutOfRange
	add hl, wa
	exts xhl
	sll xhl, 3
	addda32_24 xhl, 0x340d2
	ld xwa, (xhl)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ldib_erp 0xfb, 0
	jr MstStyle1SubGrid_PadLeft_Check

MstStyle1SubGrid_PadLeft_Loop:
	pushw 0x1
	pushw 0xed
	pushw 0xdac
	lda xwa, (xsp + 14)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	inc1b_erp 0xfb

MstStyle1SubGrid_PadLeft_Check:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, (xsp + 28)
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	stb_erp A, 0xfb
	extz wa
	cp wa, bc
	jr c, MstStyle1SubGrid_PadLeft_Loop
	jr MstStyle1SubGrid_CheckPlayAudio

MstStyle1SubGrid_OutOfRange:
	pushw 0xed
	pushw 0xdae
	push xde
	call Strcpy
	inc 8, xsp
	jr MstStyle1SubGrid_CheckPlayAudio

MstStyle1SubGrid_BottomSection:
	add hl, (xbc)
	exts xhl
	sll xhl, 3
	addda32_24 xhl, 0x340d2
	ld xwa, (xhl)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ldib_erp 0xfb, 0
	jr MstStyle1SubGrid_PadLeft_CheckB

MstStyle1SubGrid_PadLeft_LoopB:
	pushw 0x1
	pushw 0xed
	pushw 0xdc0
	lda xwa, (xsp + 14)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	inc1b_erp 0xfb

MstStyle1SubGrid_PadLeft_CheckB:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, (xsp + 28)
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	stb_erp A, 0xfb
	extz wa
	cp wa, bc
	jr c, MstStyle1SubGrid_PadLeft_LoopB

MstStyle1SubGrid_CheckPlayAudio:
	ld wa, (xsp + 26)
	cps wa, 1
	jr nz, MstStyle1SubGrid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 26)
	ld xbc, 0x1e0008c
	call SendEvent

MstStyle1SubGrid_ReturnZero:
	lds32 xhl, 0

MstStyle1SubGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 30)
	ret
MstStyle2Grid_Boundary:

AcMstStyle2GridBoxProc:
	lda xsp, (xsp - 56)
	push xiz
	ld (xsp + 48), xde
	ld (xsp + 52), xbc
	ld (xsp + 56), xwa
	ld xbc, (xsp + 52)
	cp xbc, 0x1e0008d
	jrl z, MstStyle2_ForwardToChild
	ld xwa, (xsp + 52)
	cp xwa, 0x1e0008b
	jrl z, MstStyle2_GetNameB_DrawString
	cp xwa, 0x1e0008a
	jrl z, MstStyle2_GetNameA
	cp xwa, 0x1c00007
	jrl z, MstStyle2_HandleDialTurn
	cp xwa, 0x1c00002
	jrl z, MstStyle2_HandleDialStop
	cp xwa, 0x1c00001
	jr z, MstStyle1Page_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, MstStyle2_InheritedFallback
	cp xbc, 0x6
	jrl gt, MstStyle2_InheritedFallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0x178
	ld bc, (xbc)
	lda_24 xix, MstStyle1Page_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; MstStyle1 subpage event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0e04)
MstStyle1Page_EventDispatch:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00017
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 48)
	cp xwa, 0x4
	jrl z, MstStyle2_HandleSpecialEvent
	cp xwa, 0x3
	jrl z, MstStyle2_HandleSpecialEvent
	or xwa, xwa
	jrl nz, SeqData_ReturnZero
	ldw_da xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, StyleGroup_LatinDance_Table
	add xbc, xwa
	ld xde, (xbc)
	stl_da 0x0340d2, xde
	ldb c, 0x0

MstStyle2_CountEntries_Loop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_CountEntries_Done
	inc 1, c
	cp c, 0xff
	jr c, MstStyle2_CountEntries_Loop

MstStyle2_CountEntries_Done:
	cps c, 0
	jr z, MstStyle2_CountEntries_Adjust
	dec 1, c

MstStyle2_CountEntries_Adjust:
	ld xix, (xsp + 8)
	lda xde, (xix + 74)
	ld xhl, (xde)
	ld a, c
	extz wa
	ld (xhl), wa
	ld xhl, (xix + 78)
	srl c, 1
	inc 1, c
	extz bc
	ld (xhl), bc
	ld xhl, (xsp + 4)
	ld xbc, (xhl + 82)
	ldw_da xwa, 0x0340c6
	srl wa, 1
	inc 1, wa
	ld (xbc), wa
	ld xbc, (xhl + 86)
	ldw_da xwa, 0x0340c6
	ld (xbc), wa
	ld xwa, (xhl + 90)
	ldw (xwa), 0x1
	ldw_da xwa, 0x0340c6
	bit 0, wa
	jrl nz, MstStyle2_InitOdd_Setup
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_CountSubEntries_DoneA
	inc 1, c
	cps c, 4
	jr c, MstStyle2_CountSubEntries_LoopA

MstStyle2_CountSubEntries_DoneA:
	cps c, 0
	jr z, MstStyle2_CountSubEntries_AdjA
	dec 1, c

MstStyle2_CountSubEntries_AdjA:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xwa, (xde)
	ld bc, (xwa)
	ldw_da xwa, 0x0340c6
	cp bc, wa
	jr ule, MstStyle2_InitDone_PostEvent
	inc 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xde, (xwa + 4)
	stl_da 0x0340da, xde
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_CountSubEntries_DoneB
	inc 1, c
	cps c, 4
	jr c, MstStyle2_CountSubEntries_LoopB

MstStyle2_CountSubEntries_DoneB:
	cps c, 0
	jr z, MstStyle2_CountSubEntries_AdjB
	dec 1, c

MstStyle2_CountSubEntries_AdjB:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 98)
	extz bc
	ld (xde), bc

MstStyle2_InitDone_PostEvent:
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	jrl MstStyle2_SendEvent_Done

MstStyle2_InitOdd_Setup:
	dec 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xde, (xwa + 4)
	stl_da 0x0340d6, xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_InitOdd_CountDoneA
	inc 1, c
	cps c, 4
	jr c, MstStyle2_InitOdd_CountLoopA

MstStyle2_InitOdd_CountDoneA:
	cps c, 0
	jr z, MstStyle2_InitOdd_CountAdjA
	dec 1, c

MstStyle2_InitOdd_CountAdjA:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 94)
	extz bc
	ld (xde), bc
	ldw_da xwa, 0x0340c6
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xde, (xwa + 4)
	stl_da 0x0340da, xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_InitOdd_CountDoneB
	inc 1, c
	cps c, 4
	jr c, MstStyle2_InitOdd_CountLoopB

MstStyle2_InitOdd_CountDoneB:
	cps c, 0
	jr z, MstStyle2_InitOdd_CountAdjB
	dec 1, c

MstStyle2_InitOdd_CountAdjB:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 98)
	extz bc
	ld (xde), bc
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0005

MstStyle2_SendEvent_Done:
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	call ApFuncCall
	jrl SeqData_ReturnZero

MstStyle2_HandleSpecialEvent:
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 48)
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	call SendEvent
	jrl SeqData_ReturnZero

MstStyle2_HandleDialStop:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, 0x142000d
	ld xbc, 0x1e20019
	lds32 xde, 0
	call MainFuncCall
	jrl SeqData_ReturnZero

MstStyle2_HandleDialTurn:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	lda_24 xbc, 0x0340c8
	lda xhl, (xwa + 82)
	lda xix, (xwa + 86)
	ld xwa, (xsp + 48)
	cp xwa, 0x80
	jrl z, MstStyle2_DialUp_Scroll
	or xwa, xwa
	jrl nz, SeqData_ReturnZero
	ld xde, xix
	ld xix, (xix)
	cpw (xix), 0x0
	jrl z, SeqData_ReturnZero
	ld wa, (xix)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr z, MstStyle2_DialDown_PageDec
	decm 1, (xix)
	ldw_da xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00017
	ld xde, (xsp + 48)
	jrl Seq_ApplyFunctionAndReturn

MstStyle2_DialDown_PageDec:
	ld xix, xhl
	ld xwa, (xhl)
	decm 1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageDec_CountDone
	inc 1, c
	cps c, 4
	jr c, MstStyle2_PageDec_CountLoop

MstStyle2_PageDec_CountDone:
	cps c, 0
	jr z, MstStyle2_PageDec_CountAdj
	dec 1, c

MstStyle2_PageDec_CountAdj:
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xhl, (xwa + 74)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	ld bc, wa
	dec 2, bc
	cp (xhl), bc
	jr le, MstStyle2_DialDown_UpdateAndPost
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340da, xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageDec_CountDone2
	inc 1, c
	cps c, 4
	jr c, MstStyle2_PageDec_CountLoop2

MstStyle2_PageDec_CountDone2:
	cps c, 0
	jr z, MstStyle2_PageDec_CountAdj2
	dec 1, c

MstStyle2_PageDec_CountAdj2:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 98)
	extz bc
	ld (xhl), bc

MstStyle2_DialDown_UpdateAndPost:
	ld xwa, (xde)
	decm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0005
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00017
	ld xde, (xsp + 48)
	jrl Seq_ApplyFunctionAndReturn

MstStyle2_DialUp_Scroll:
	ld xde, xix
	ld xiy, (xix)
	ld xwa, (xsp + 8)
	lda xix, (xwa + 74)
	ld xiz, (xix)
	ld wa, (xiy)
	cp wa, (xiz)
	jrl ge, SeqData_ReturnZero
	ld wa, (xiy)
	exts xwa
	divs wa, 0x2
	stw_erp WA, 0xe2
	cps wa, 0
	jr nz, MstStyle2_DialUp_PageInc
	incm 1, (xiy)
	ldw_da xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008e
	ld xde, 0xffff0005
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	jrl Seq_ApplyFunctionAndReturn

MstStyle2_DialUp_PageInc:
	ld xiy, xhl
	ld xwa, (xhl)
	incm 1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageInc_CountDone
	inc 1, c
	cps c, 4
	jr c, MstStyle2_PageInc_CountLoop

MstStyle2_PageInc_CountDone:
	cps c, 0
	jr z, MstStyle2_PageInc_CountAdj
	dec 1, c

MstStyle2_PageInc_CountAdj:
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xwa, (xix)
	ld wa, (xwa)
	stw_da 0x0340bc, xwa
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	stw_da 0x0340be, xwa
	cpdm16_24 0x340bc, xwa
	jr le, MstStyle2_DialUp_UpdateAndPost
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340da, xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageInc_CountDone2
	inc 1, c
	cps c, 4
	jr c, MstStyle2_PageInc_CountLoop2

MstStyle2_PageInc_CountDone2:
	cps c, 0
	jr z, MstStyle2_PageInc_CountAdj2
	dec 1, c

MstStyle2_PageInc_CountAdj2:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 98)
	extz bc
	ld (xhl), bc

MstStyle2_DialUp_UpdateAndPost:
	ld xwa, (xde)
	incm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	jrl Seq_ApplyFunctionAndReturn
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	ld xwa, (xsp + 56)
	ld xbc, 0x1e00050
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle2_FallbackEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld ix, hl
	lda_24 xbc, 0x0340c8
	cps ix, 0
	jrl nz, MstStyle2_DialScrollUp_Middle
	ld xhl, (xsp + 8)
	lda xde, (xhl + 82)
	ld xwa, (xde)
	ld wa, (xwa)
	stw_da 0x0340bc, xwa
	cps wa, 1
	jrl le, MstStyle2_DialScroll_SetAutoInc
	lda xhl, (xhl + 86)
	ld xwa, (xhl)
	decm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xhl)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xde)
	decm 1, (xwa)
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_DialScrollDown_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScrollDown_CountDone
	inc 1, c
	cps c, 4
	jr c, MstStyle2_DialScrollDown_CountLoop

MstStyle2_DialScrollDown_CountDone:
	cps c, 0
	jr z, MstStyle2_DialScrollDown_CountAdj
	dec 1, c

MstStyle2_DialScrollDown_CountAdj:
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xhl, (xwa + 74)
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 1
	ld bc, wa
	dec 2, bc
	cp (xhl), bc
	jr le, MstStyle2_DialScrollDown_PostEvent
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xde, (xwa + 4)
	stl_da 0x0340da, xde
	ldb c, 0x0

MstStyle2_DialScrollDown_Count2Loop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScrollDown_Count2Done
	inc 1, c
	cps c, 4
	jr c, MstStyle2_DialScrollDown_Count2Loop

MstStyle2_DialScrollDown_Count2Done:
	cps c, 0
	jr z, MstStyle2_DialScrollDown_Count2Adj
	dec 1, c

MstStyle2_DialScrollDown_Count2Adj:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 98)
	extz bc
	ld (xde), bc

MstStyle2_DialScrollDown_PostEvent:
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 98)
	ld wa, (xwa)
	inc 5, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00017
	ld xde, (xsp + 48)
	jr MstStyle2_DialScroll_CallFunc

MstStyle2_DialScrollUp_Middle:
	cps ix, 5
	jr nz, MstStyle2_DialScrollUp_Simple
	ld xhl, (xsp + 4)
	lda xde, (xhl + 86)
	ld xwa, (xde)
	decm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xhl + 94)
	ld de, (xwa)
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	jr MstStyle2_DialScrollUp_SendEvent

MstStyle2_DialScrollUp_Simple:
	dec 1, ix
	ld de, ix
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e

MstStyle2_DialScrollUp_SendEvent:
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)

MstStyle2_DialScroll_CallFunc:
	call ApFuncCall

MstStyle2_DialScroll_SetAutoInc:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call SetAutoInc
	jrl SeqData_ReturnZero

MstStyle2_FallbackEvent:
	ld xwa, (xsp + 56)
	ld xbc, 0x1e00091
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, SeqData_ReturnZero
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call ApFuncCall
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call SetAutoInc
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	call SetDialUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00017
	ld xde, (xsp + 48)
	call SetDialDown
	lds wa, 1
	jrl MstStyle2_SetDialEnable
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	ld xwa, (xsp + 56)
	ld xbc, 0x1e00050
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle2_DialScroll_FallbackUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld ix, hl
	lda xhl, (xiz + 94)
	ld xwa, (xhl)
	cp ix, (xwa)
	jr nz, MstStyle2_DialScrollUp_NextPage
	ld xbc, (xiz + 74)
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	cp (xbc), wa
	jrl le, MstStyle2_DialScroll_AutoInc
	lda xbc, (xiz + 86)
	ld xwa, (xbc)
	incm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0005
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	jrl MstStyle2_DialScroll_CallApFunc

MstStyle2_DialScrollUp_NextPage:
	ld xbc, (xsp + 4)
	lda xde, (xbc + 98)
	ld xwa, (xde)
	ld wa, (xwa)
	inc 5, wa
	cp wa, ix
	jrl nz, MstStyle2_DialScrollUp_SendSimple
	lda xix, (xbc + 82)
	ld xwa, (xix)
	ld wa, (xwa)
	stw_da 0x0340bc, xwa
	ld xwa, (xbc + 78)
	ld wa, (xwa)
	stw_da 0x0340be, xwa
	cpdm16_24 0x340bc, xwa
	jrl ge, MstStyle2_DialScroll_AutoInc
	ld xwa, (xix)
	incm 1, (xwa)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xiy, (xwa + 4)
	stl_da 0x0340d6, xiy
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopD:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xf4, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScroll_CountDoneD
	inc 1, c
	cps c, 4
	jr c, MstStyle2_DialScroll_CountLoopD

MstStyle2_DialScroll_CountDoneD:
	cps c, 0
	jr z, MstStyle2_DialScroll_CountAdjD
	dec 1, c

MstStyle2_DialScroll_CountAdjD:
	ld xhl, (xhl)
	extz bc
	ld (xhl), bc
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 74)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	ld bc, wa
	dec 2, bc
	cp (xhl), bc
	jr le, MstStyle2_DialScroll_IncAndPost
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xhl, (xwa + 4)
	stl_da 0x0340da, xhl
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopE:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScroll_CountDoneE
	inc 1, c
	cps c, 4
	jr c, MstStyle2_DialScroll_CountLoopE

MstStyle2_DialScroll_CountDoneE:
	cps c, 0
	jr z, MstStyle2_DialScroll_CountAdjE
	dec 1, c

MstStyle2_DialScroll_CountAdjE:
	ld xde, (xde)
	extz bc
	ld (xde), bc

MstStyle2_DialScroll_IncAndPost:
	lda xbc, (xiz + 86)
	ld xwa, (xbc)
	incm 1, (xwa)
	ldw_da xwa, 0x0340c4
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	jr MstStyle2_DialScroll_CallApFunc

MstStyle2_DialScrollUp_SendSimple:
	ld wa, ix
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)

MstStyle2_DialScroll_CallApFunc:
	call ApFuncCall

MstStyle2_DialScroll_AutoInc:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call SetAutoInc
	jrl SeqData_ReturnZero

MstStyle2_DialScroll_FallbackUp:
	ld xwa, (xsp + 56)
	ld xbc, 0x1e00091
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, SeqData_ReturnZero
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call ApFuncCall
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call SetAutoInc
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00018
	ld xde, (xsp + 48)
	call SetDialUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1c00017
	ld xde, (xsp + 48)
	call SetDialDown
	lds wa, 1

MstStyle2_SetDialEnable:
	call SetDialEnable
	jrl SeqData_ReturnZero

MstStyle2_GetNameA:
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	ld xwa, (xsp + 52)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl SeqData_ReturnZero

MstStyle2_GetNameB_DrawString:
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 66)
	push xwa
	ld xwa, (xsp + 52)
	push xwa
	call Strcpy
	lda xhl, (xsp + 44)
	ldw (xhl), 0xa
	lda xbc, (xhl + 2)
	ldw (xbc), 0x32
	lda xde, (xsp + 48)
	ld wa, (xhl)
	ld (xde), wa
	ld wa, (xhl)
	add wa, 0x94
	ld (xde + 4), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x14
	ld (xde + 6), wa
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xwa, (xwa)
	push xwa
	pushw 0xed
	pushw 0xdd0
	lda xwa, (xsp + 34)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 20)
	lda xwa, (xsp + 40)
	lda xbc, (xsp + 36)
	lda xde, (xsp + 18)
	lds32 xhl, 0
	push xhl
	pushw 0xfb
	pushw 0xf5
	call DrawString
	ld xbc, (xiz + 82)
	ld xwa, (xiz + 78)
	lda xde, (xsp + 18)
	ld wa, (xwa)
	cp wa, (xbc)
	jr nz, MstStyle2_NameB_DrawLower
	ld xhl, (xiz + 74)
	ld wa, (xbc)
	sla wa, 1
	dec 1, wa
	cp wa, (xhl)
	jr le, MstStyle2_NameB_DrawCurrent
	pushw 0xed
	pushw 0xdd4
	push xde
	call Strcpy
	inc 8, xsp
	ld xwa, Str_StoreTotalSetting_DE_0x15A
	jr MstStyle2_NameB_Render

MstStyle2_NameB_DrawCurrent:
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xwa, (xwa)
	push xwa
	pushw 0xed
	pushw 0xdec
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	ld xwa, Str_StoreTotalSetting_DE_0x164
	jr MstStyle2_NameB_Render

MstStyle2_NameB_DrawLower:
	ld wa, (xbc)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 0x340d2
	ld xwa, (xwa)
	push xwa
	pushw 0xed
	pushw 0xdf6
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	ld xwa, Str_StoreTotalSetting_DE_0x16E

MstStyle2_NameB_Render:
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 36)
	ldw (xbc), 0xa
	lda xhl, (xbc + 2)
	ldw (xhl), 0x82
	lda xwa, (xsp + 40)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x94
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x14
	ld (xwa + 6), de
	lda xde, (xsp + 18)
	lds32 xhl, 0
	push xhl
	pushw 0xfb
	pushw 0xf5
	call DrawString
	lda xbc, (xsp + 36)
	ldw (xbc), 0x10b
	lda xhl, (xbc + 2)
	ldw (xhl), 0x82
	lda xwa, (xsp + 40)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x2c
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lda xde, (xsp + 12)
	lds32 xhl, 0
	push xhl
	pushw 0xfb
	pushw 0xf5
	call DrawString
	lda xhl, (xsp + 36)
	ldw (xhl), 0x91
	lda xbc, (xhl + 2)
	ldw (xbc), 0x20
	lda xde, (xsp + 40)
	ld wa, (xhl)
	ld (xde), wa
	ld wa, (xhl)
	add wa, 0x94
	ld (xde + 4), wa
	ld wa, (xbc)
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x14
	ld (xde + 6), wa
	ldw_da xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	ld xbc, StyleGroup_LatinWorld_PairTable_0x2FA
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0xed
	pushw 0xe00
	lda xwa, (xsp + 26)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	lda xwa, (xsp + 40)
	lda xbc, (xsp + 36)
	lda xde, (xsp + 18)
	lds32 xhl, 0
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawString
	jr SeqData_ReturnZero

MstStyle2_ForwardToChild:
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)

Seq_ApplyFunctionAndReturn:
	call ApFuncCall

SeqData_ReturnZero:
	lds32 xhl, 0
	jr MstStyle2_Epilogue

MstStyle2_InheritedFallback:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc

MstStyle2_Epilogue:
	pop xiz
	lda xsp, (xsp + 56)
	ret

MstStyle2GridCheck:
	lda xsp, (xsp - 62)
	push xiz
	ld (xsp + 62), xde
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, MstGrid2_CellSelect
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstGrid2_Return
	cp xwa, 0x6
	jrl gt, MstGrid2_Return
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0x238
	ld wa, (xwa)
	lda_24 xix, MstGrid2_ScrollJumpTable
	jp_ind 8, 0x07, 0xf0, 0xe0

MstGrid2_ScrollJumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+62), xhl
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	xbc, (xsp+62)
	ld	(xsp+56), bc
	cps	bc, 4
	jr	ge, 42
	ld	xwa, (xhl+94)
	cp	bc, (xwa)
	jrl	gt, 683
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	addda32_24	xbc, 0x340d6
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	jr	46
	ld	xwa, (xhl+98)
	ld	wa, (xwa)
	inc	5, wa
	cp	bc, wa
	jrl	gt, 637
	dec	5, bc
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	addda32_24	xbc, 0x340da
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	call	MainFuncCall
	jrl	596

MstGrid2_CellSelect:
	call GetFocusObject
	ld xwa, xhl
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xix, (xsp + 8)
	ld (xsp + 4), xix
	lda xhl, (xsp + 54)
	ld xwa, (xsp + 62)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld xwa, (xsp + 62)
	ld de, wa
	ld (xbc), de
	lda xwa, (xsp + 20)
	ld (xsp + 12), xwa
	ld (xhl + 4), xwa
	ld xhl, (xix + 82)
	ld xwa, xix
	ld xix, (xwa + 78)
	ld de, (xbc)
	ld wa, de
	exts xwa
	ld bc, de
	dec 5, bc
	exts xbc
	ld xiy, xwa
	add xiy, xiy
	add xiy, xwa
	add xiy, xiy
	addda32_24 xiy, 0x340d6
	ld xwa, xbc
	add xwa, xwa
	add xwa, xbc
	add xwa, xwa
	ld (xsp + 16), xwa
	ldl_da xwa, 0x0340da
	add (xsp + 16), xwa
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 98)
	ld xiz, (xwa + 94)
	ld bc, (xbc)
	inc 5, bc
	ld wa, (xhl)
	cp wa, (xix)
	jrl ge, MstGrid2_LowerSection
	cps de, 4
	jr ge, MstGrid2_UpperHalf
	cp de, (xiz)
	jr gt, MstGrid2_OutOfRange_LowCol
	ld xwa, (xiy)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 18), 0x0
	jr MstGrid2_PadLeft_CheckA

MstGrid2_PadLeft_LoopA:
	pushw 0x1
	pushw 0xed
	pushw 0xe12
	lda xwa, (xsp + 26)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 18)

MstGrid2_PadLeft_CheckA:
	ld wa, (xsp + 56)
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	addda32_24 xbc, 0x340d6
	ld xwa, (xbc)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 18)
	extz wa
	cp wa, bc
	jr c, MstGrid2_PadLeft_LoopA
	jrl MstGrid2_CheckPlayAudio

MstGrid2_OutOfRange_LowCol:
	ld xwa, Str_StoreTotalSetting_DE_0x188
	jrl MstGrid2_CopyFallback

MstGrid2_UpperHalf:
	cp de, bc
	jr gt, MstGrid2_OutOfRange_HighCol
	ld xwa, (xsp + 16)
	ld xwa, (xwa)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 18), 0x0
	jr MstGrid2_PadLeft_CheckB

MstGrid2_PadLeft_LoopB:
	pushw 0x1
	pushw 0xed
	pushw 0xe36
	lda xwa, (xsp + 26)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 18)

MstGrid2_PadLeft_CheckB:
	ld wa, (xsp + 56)
	dec 5, wa
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	addda32_24 xbc, 0x340da
	ld xwa, (xbc)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 18)
	extz wa
	cp wa, bc
	jr c, MstGrid2_PadLeft_LoopB
	jrl MstGrid2_CheckPlayAudio

MstGrid2_OutOfRange_HighCol:
	ld xwa, Str_StoreTotalSetting_DE_0x1AC
	jrl MstGrid2_CopyFallback

MstGrid2_LowerSection:
	cps de, 4
	jr ge, MstGrid2_BottomRight
	cp de, (xiz)
	jr gt, MstGrid2_OutOfRange_LowCol2
	ld xwa, (xiy)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 18), 0x0
	jr MstGrid2_PadLeft_CheckC

MstGrid2_PadLeft_LoopC:
	pushw 0x1
	pushw 0xed
	pushw 0xe5a
	lda xwa, (xsp + 26)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 18)

MstGrid2_PadLeft_CheckC:
	ld wa, (xsp + 56)
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	addda32_24 xbc, 0x340d6
	ld xwa, (xbc)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 18)
	extz wa
	cp wa, bc
	jr c, MstGrid2_PadLeft_LoopC
	jrl MstGrid2_CheckPlayAudio

MstGrid2_OutOfRange_LowCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1D0
	jrl MstGrid2_CopyFallback

MstGrid2_BottomRight:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 74)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	cp wa, (xhl)
	jr ge, MstGrid2_OutOfRange_BeyondMax
	cp de, bc
	jr gt, MstGrid2_OutOfRange_HighCol2
	ld xwa, (xsp + 16)
	ld xwa, (xwa)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 18), 0x0
	jr MstGrid2_PadLeft_CheckD

MstGrid2_PadLeft_LoopD:
	pushw 0x1
	pushw 0xed
	pushw 0xe7e
	lda xwa, (xsp + 26)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 18)

MstGrid2_PadLeft_CheckD:
	ld wa, (xsp + 56)
	dec 5, wa
	exts xwa
	ld xbc, xwa
	add xbc, xbc
	add xbc, xwa
	add xbc, xbc
	addda32_24 xbc, 0x340da
	ld xwa, (xbc)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x20
	sub bc, hl
	ld a, (xsp + 18)
	extz wa
	cp wa, bc
	jr c, MstGrid2_PadLeft_LoopD
	jr MstGrid2_CheckPlayAudio

MstGrid2_OutOfRange_HighCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1F4
	jr MstGrid2_CopyFallback

MstGrid2_OutOfRange_BeyondMax:
	ld xwa, Str_StoreTotalSetting_DE_0x216

MstGrid2_CopyFallback:
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp

MstGrid2_CheckPlayAudio:
	ld wa, (xsp + 54)
	cps wa, 1
	jr nz, MstGrid2_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 54)
	ld xbc, 0x1e0008c
	call SendEvent

MstGrid2_Return:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 62)
	ret
MstGrid2_Boundary:

AcMstSong1GridBoxProc:
	jp InheritedProc

MstSong1GridCheck:
	lds32 xhl, 0
	ret
MstSong1Grid_Boundary:

AcMstSong2GridBoxProc:
	jp InheritedProc

MstSong2GridCheck:
	lds32 xhl, 0
	ret
MstSong2Grid_Boundary:

IvMstStyleWindowPgCtlProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1c00007
	jr z, MstStylePgCtl_HandleScroll
	cp xbc, 0x1c00001
	jr z, MstStylePgCtl_HandleInit
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jrl MstStylePgCtl_Epilogue

MstStylePgCtl_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	or xwa, xwa
	jrl nz, MstStylePgCtl_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 22)
	ldw (xwa), 0x1
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	lds32 xde, 1
	call SendEvent
	jr MstStylePgCtl_ReturnZero

MstStylePgCtl_HandleScroll:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xsp + 4)
	cp xwa, 0xb
	jr nz, MstStylePgCtl_HandleScrollDown
	ld xde, xbc
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jr nz, MstStylePgCtl_ReturnZero
	incm 1, (xwa)
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	jr MstStylePgCtl_SendPageEvent

MstStylePgCtl_HandleScrollDown:
	ld xwa, (xsp + 4)
	cp xwa, 0xf
	jr nz, MstStylePgCtl_ReturnZero
	ld xde, xbc
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jr z, MstStylePgCtl_ScrollDown_Exit
	decm 1, (xwa)
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e

MstStylePgCtl_SendPageEvent:
	call SendEvent
	jr MstStylePgCtl_ReturnZero

MstStylePgCtl_ScrollDown_Exit:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a000c1
	call PostEvent

MstStylePgCtl_ReturnZero:
	lds32 xhl, 0

MstStylePgCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret
TchSensGrid_Boundary:

AcTchSensGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, TchSens_ForwardToChild
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, TchSens_GetNameB
	cp xwa, 0x1e0008a
	jrl z, TchSens_GetNameA
	cp xwa, 0x1c00001
	jr z, MstStyle2_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, TchSens_InheritedFallback
	cp xbc, 0x6
	jrl gt, TchSens_InheritedFallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0x246
	ld bc, (xbc)
	lda_24 xix, MstStyle2_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; MstStyle2 event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0ed2)
MstStyle2_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl TchSens_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, TchSens_DialDown_Fallback
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cps hl, 4
	jr nz, TchSens_DialDown_Dec1
	dec 3, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	jr TchSens_DialDown_SendEvent

TchSens_DialDown_Dec1:
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl

TchSens_DialDown_SendEvent:
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl TchSens_ReturnZeroJmp

TchSens_DialDown_Fallback:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, TchSens_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl TchSens_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, TchSens_DialUp_Fallback
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cps hl, 1
	jr nz, TchSens_DialUp_Inc1
	inc 3, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	jr TchSens_DialUp_SendEvent

TchSens_DialUp_Inc1:
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl

TchSens_DialUp_SendEvent:
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl TchSens_ReturnZeroJmp

TchSens_DialUp_Fallback:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, TchSens_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

TchSens_SetDialEnable:
	call SetDialEnable
	jr TchSens_ReturnZeroJmp

TchSens_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3e
	jr TchSens_GetName_Load

TchSens_GetNameB:
	ld xwa, xiz
	ld xiz, 0x42

TchSens_GetName_Load:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr TchSens_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr TchSens_CallApFunc

TchSens_ForwardToChild:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

TchSens_CallApFunc:
	call ApFuncCall

TchSens_ReturnZeroJmp:
	lds32 xhl, 0
	jr TchSens_Epilogue

TchSens_InheritedFallback:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

TchSens_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

TchSensGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, TchSensGrid_CellSelect
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, TchSensGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, TchSensGrid_ReturnZero
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0x27C
	ld wa, (xwa)
	lda_24 xix, TchSensGrid_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; TchSensGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0f08)
TchSensGrid_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xde
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, 16
	cps	de, 1
	jr	nz, 12
	ld	xwa, 256
	lds	bc, 1
	lds	de, 2
	jrl	190
	cpw	(xwa), 1
	jr	nz, 16
	cps	de, 4
	jr	nz, 12
	ld	xwa, 260
	lds	bc, 1
	lds	de, 2
	jrl	168
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 16
	cps	de, 5
	jr	nz, 12
	ld	xwa, 258
	lds	bc, 1
	lds	de, 2
	jrl	146
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 652
	cps	de, 6
	jrl	nz, 647
	ld	xwa, 259
	lds	bc, 1
	lds	de, 2
	jr	123
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xde
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), de
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 16
	cps	de, 1
	jr	nz, 12
	ld	xwa, 256
	ldw	bc, 0xffff
	lds	de, 2
	jr	66
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 16
	cps	de, 4
	jr	nz, 12
	ld	xwa, 260
	ldw	bc, 0xffff
	lds	de, 2
	jr	44
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 16
	cps	de, 5
	jr	nz, 12
	ld	xwa, 258
	ldw	bc, 0xffff
	lds	de, 2
	jr	22
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 528
	cps	de, 6
	jrl	nz, 523
	ld	xwa, 259
	ldw	bc, 0xffff
	lds	de, 2
	call	MainLswAdd
	jrl	506
	lda	xix, (xde+4)
	ld	xwa, (xde)
	cp	xwa, 256
	jr	nz, 51
	lda	xwa, (xsp+14)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	.byte 0x01
	nop
	lda	xbc, (xsp+4)
	ld	(xwa+4), xbc
	.byte 0x94, 0x04
	pushw	237
	pushw	3808
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
	jrl	438
	ld	xwa, (xde)
	cp	xwa, 260
	jr	nz, 59
	lda	xwa, (xsp+14)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	.byte 0x04
	nop
	lda	xbc, (xsp+4)
	ld	(xwa+4), xbc
	ld	xwa, Str_StoreTotalSetting_DE_0x25C
	.byte 0x94
	push	xsp
	nop
	nop
	jr	z, 5
	ld	xwa, Str_StoreTotalSetting_DE_0x258
	push	xwa
	push	xbc
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
	jrl	369
	lda	xiy, (xsp+14)
	lda	xiz, (xsp+4)
	lda	xbc, (xiy+2)
	lda	xhl, (xiy+4)
	ld	xwa, (xde)
	cp	xwa, 258
	jr	nz, 43
	.byte 0xb5
	push	sr
	.byte 0x01
	nop
	.byte 0xb1
	push	sr
	halt
	nop
	ld	(xhl), xiz
	.byte 0x94, 0x04
	pushw	237
	pushw	3820
	push	xiz
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
	jrl	304
	ld	xwa, (xde)
	cp	xwa, 259
	jrl	nz, 297
	.byte 0xb5
	push	sr
	.byte 0x01
	nop
	.byte 0xb1
	push	sr
	di
	ld	(xhl), xiz
	.byte 0x94, 0x04
	pushw	237
	pushw	3824
	push	xiz
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
	jrl	250

TchSensGrid_CellSelect:
	lda xbc, (xsp + 14)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	cpw (xbc), 0x1
	jr nz, TchSensGrid_CheckCell_1_4
	cpw (xwa), 0x1
	jr nz, TchSensGrid_CheckCell_1_4
	ld xwa, 0x100
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xed
	pushw 0xef4
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c
	jrl TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_4:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_CheckCell_1_5
	cpw (xwa), 0x4
	jr nz, TchSensGrid_CheckCell_1_5
	ld xwa, 0x104
	call SndParam_LookupReadOnly
	ld xwa, Str_StoreTotalSetting_DE_0x270
	cps hl, 0
	jr nz, TchSensGrid_Cell_1_4_Render
	ld xwa, Str_StoreTotalSetting_DE_0x26C

TchSensGrid_Cell_1_4_Render:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c
	jr TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_5:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_CheckCell_1_6
	cpw (xwa), 0x5
	jr nz, TchSensGrid_CheckCell_1_6
	ld xwa, 0x102
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xed
	pushw 0xf00
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c
	jr TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_6:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_ReturnZero
	cpw (xwa), 0x6
	jr nz, TchSensGrid_ReturnZero
	ld xwa, 0x103
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xed
	pushw 0xf04
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1e0008c

TchSensGrid_SendEvent:
	call SendEvent

TchSensGrid_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret
FSWAssGrid_Boundary:

AcFSWAssGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, FSWAss_ForwardToChild
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, FSWAss_GetNameB
	cp xwa, 0x1e0008a
	jrl z, FSWAss_GetNameA
	cp xwa, 0x1c00001
	jr z, TchSens_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, FSWAss_InheritedFallback
	cp xbc, 0x6
	jrl gt, FSWAss_InheritedFallback
	add xbc, xbc
	add xbc, Str_StoreTotalSetting_DE_0x28A
	ld bc, (xbc)
	lda_24 xix, TchSens_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; TouchSensitivity event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0f16)
TchSens_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl FSWAss_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FSWAss_DialDown_Fallback
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FSWAss_ReturnZeroJmp

FSWAss_DialDown_Fallback:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FSWAss_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl FSWAss_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FSWAss_DialUp_Fallback
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FSWAss_ReturnZeroJmp

FSWAss_DialUp_Fallback:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, FSWAss_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

FSWAss_SetDialEnable:
	call SetDialEnable
	jr FSWAss_ReturnZeroJmp

FSWAss_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3e
	jr FSWAss_GetName_Load

FSWAss_GetNameB:
	ld xwa, xiz
	ld xiz, 0x42

FSWAss_GetName_Load:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr FSWAss_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr FSWAss_CallApFunc

FSWAss_ForwardToChild:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

FSWAss_CallApFunc:
	call ApFuncCall

FSWAss_ReturnZeroJmp:
	lds32 xhl, 0
	jr FSWAss_Epilogue

FSWAss_InheritedFallback:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

FSWAss_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

FSWAssGridCheck:
	stb_dri L, 0xfd, 0xf8, 0xfe
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, FSWAssGrid_CellSelect
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, AudioTable_ReturnZero
	cp xwa, 0x6
	jrl gt, AudioTable_ReturnZero
	add xwa, xwa
	add xwa, CtrlAssignStr_Off_0x4A
	ld wa, (xwa)
	lda_24 xix, FSWAssGrid_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; FSWAssGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1226)
FSWAssGrid_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+260)
	ld	xbc, xde
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), de
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 2
	jr	nz, 64
	ld	xwa, 0x2886
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2228
	cp	l, 28
	jrl	nc, 2213
	ld	xwa, 0x2886
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2206
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2886
	lds	de, 2
	jrl	997
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 3
	jr	nz, 64
	ld	xwa, 0x2888
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2154
	cp	l, 28
	jrl	nc, 2139
	ld	xwa, 0x2888
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2132
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2888
	lds	de, 2
	jrl	923
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 4
	jr	nz, 64
	ld	xwa, 0x288a
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2080
	cp	l, 28
	jrl	nc, 2065
	ld	xwa, 0x288a
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2058
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288a
	lds	de, 2
	jrl	849
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 5
	jr	nz, 64
	ld	xwa, 0x288c
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	2006
	cp	l, 28
	jrl	nc, 1991
	ld	xwa, 0x288c
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1984
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288c
	lds	de, 2
	jrl	775
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 6
	jr	nz, 64
	ld	xwa, 0x288e
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1932
	cp	l, 28
	jrl	nc, 1917
	ld	xwa, 0x288e
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1910
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288e
	lds	de, 2
	jrl	701
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 68
	cps	de, 7
	jr	nz, 64
	ld	xwa, 0x2890
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1858
	cp	l, 28
	jrl	nc, 1843
	ld	xwa, 0x2890
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1836
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2890
	lds	de, 2
	jrl	627
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 1794
	cp	de, 8
	jrl	nz, 1787
	ld	xwa, 0x2880
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1780
	cp	l, 30
	jrl	nc, 1765
	ld	xwa, 0x2880
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1758
	inc	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2880
	lds	de, 2
	jrl	549
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+260)
	.byte 0xea
	.long OscScope_FinalizeRender
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), de
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 67
	cps	de, 2
	jr	nz, 63
	ld	xwa, 0x2886
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1669
	cps	l, 0
	jrl	z, 1655
	ld	xwa, 0x2886
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1648
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2886
	lds	de, 2
	jrl	439
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 67
	cps	de, 3
	jr	nz, 63
	ld	xwa, 0x2888
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1596
	cps	l, 0
	jrl	z, 1582
	ld	xwa, 0x2888
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1575
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2888
	lds	de, 2
	jrl	366
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 67
	cps	de, 4
	jr	nz, 63
	ld	xwa, 0x288a
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1523
	cps	l, 0
	jrl	z, 1509
	ld	xwa, 0x288a
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1502
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288a
	lds	de, 2
	jrl	293
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 67
	cps	de, 5
	jr	nz, 63
	ld	xwa, 0x288c
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1450
	cps	l, 0
	jrl	z, 1436
	ld	xwa, 0x288c
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1429
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288c
	lds	de, 2
	jrl	220
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 67
	cps	de, 6
	jr	nz, 63
	ld	xwa, 0x288e
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1377
	cps	l, 0
	jrl	z, 1363
	ld	xwa, 0x288e
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1356
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x288e
	lds	de, 2
	jrl	147
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 66
	cps	de, 7
	jr	nz, 62
	ld	xwa, 0x2890
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1304
	cps	l, 0
	jrl	z, 1290
	ld	xwa, 0x2890
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1283
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2890
	lds	de, 2
	jr	75
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 1242
	cp	de, 8
	jrl	nz, 1235
	ld	xwa, 0x2880
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1228
	cp	l, 29
	jrl	ule, 1213
	ld	xwa, 0x2880
	call	SndParam_LookupReadOnly
	extz	hl
	ld	wa, hl
	calr	1206
	dec	1, l
	extz	hl
	lda_24	xbc, Str_StoreTotalSetting_DE_0x298
	.byte 0xc3
	reti
	.byte 0xe4, 0xec
	ldb	c, 217
	ccf
	ld	xwa, 0x2880
	lds	de, 2
	call	MainLswPut
	jrl	1167
	lda	xix, (xde+4)
	lda	xiy, (xsp+4)
	ld	xwa, (xde)
	cp	xwa, 0x2886
	jr	nz, 76
	lda	xwa, (xsp+260)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	push	sr
	nop
	ld	(xwa+4), xiy
	ld	wa, (xix)
	extz	wa
	calr	1136
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4590
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	1071
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	hl, 1211
	ldw	bc, 8354
	cp	xwa, 0x2888
	jr	nz, 70
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xbb
	push	sr
	push	sr
	pop	sr
	nop
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	1048
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4594
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	983
	ld	xwa, (xde)
	cp	xwa, 0x288a
	jr	nz, 70
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xbb
	push	sr
	push	sr
	.byte 0x04
	nop
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	968
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4598
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	903
	ld	xwa, (xde)
	cp	xwa, 0x288c
	jr	nz, 70
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xbb
	push	sr
	push	sr
	halt
	nop
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	888
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4602
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	823
	lda	xiz, (xhl+2)
	ld	xwa, (xde)
	cp	xwa, 0x288e
	jr	nz, 69
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xb6
	push	sr
	di
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	806
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4606
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	.byte 0xf3
	swi	5
	.byte 0x04, 0x01
	ldw	de, 0x8c41
	nop
	.byte 0xe0, 0x01
	jrl	741
	ld	xwa, (xde)
	cp	xwa, 0x2890
	jr	nz, 69
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xb6
	push	sr
	reti
	nop
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	727
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4610
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	662
	ld	xwa, (xde)
	cp	xwa, 0x2880
	jrl	nz, 655
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xb6
	push	sr
	ldio	0, 177
	jr	mi, -108
	ldb	w, 216
	ccf
	calr	647
	extz	hl
	sla	hl, 2
	lda_24	xbc, Str_StoreTotalSetting_DE_0x2B8
	.byte 0xe3
	reti
	.byte 0xe4, 0xec
	ldb	w, 56
	pushw	237
	pushw	4614
	lda	xwa, (xsp+12)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 0x1e0008c
	jrl	582

FSWAssGrid_CellSelect:
	stb_dri A, 0xfd, 0x04, 0x01
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_3
	cpw (xwa), 0x2
	jr nz, FSWAssGrid_CheckCell_1_3
	ld xwa, 0x2886
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x120a
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_3:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_4
	cpw (xwa), 0x3
	jr nz, FSWAssGrid_CheckCell_1_4
	ld xwa, 0x2888
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x120e
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_4:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_5
	cpw (xwa), 0x4
	jr nz, FSWAssGrid_CheckCell_1_5
	ld xwa, 0x288a
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x1212
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_5:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_6
	cpw (xwa), 0x5
	jr nz, FSWAssGrid_CheckCell_1_6
	ld xwa, 0x288c
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x1216
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_6:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_7
	cpw (xwa), 0x6
	jr nz, FSWAssGrid_CheckCell_1_7
	ld xwa, 0x288e
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x121a
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_7:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_8
	cpw (xwa), 0x7
	jr nz, FSWAssGrid_CheckCell_1_8
	ld xwa, 0x2890
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x121e
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c
	jr AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_8:
	cpw (xbc), 0x1
	jr nz, AudioTable_ReturnZero
	cpw (xwa), 0x8
	jr nz, AudioTable_ReturnZero
	ld xwa, 0x2880
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, Str_StoreTotalSetting_DE_0x2B8
	ld_sril3 XWA, 0x07, 0xe4, 0xec
	push xwa
	pushw 0xed
	pushw 0x1222
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x04, 0x01
	ld xbc, 0x1e0008c

AudioTable_SendEventAndContinue:
	call SendEvent

AudioTable_ReturnZero:
	lds32 xhl, 0
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret

AudioTable_FindMatchIndex:
	ldb l, 0x0
	lda_24 xde, Str_StoreTotalSetting_DE_0x298

AudioTable_FindMatch_Loop:
	ld c, l
	extz bc
	cpb_sri_rm A, 0x07, 0xe8, 0xe4
	ret z
	inc 1, l
	cp l, 0x1e
	jr c, AudioTable_FindMatch_Loop
	ret

FswAsIniFunc:
	cp xbc, 0x1c00013
	jr nz, SeqLoadFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SeqLoadFunc_ReturnZero
	cp xde, 0x5
	jr ugt, SeqLoadFunc_ReturnZero
	add xde, xde
	add xde, CtrlAssignStr_Off_0x58
	ld de, (xde)
	lda_24 xix, FswAsIni_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe8
; FswAsIniFunc event dispatch (6-entry, event 0x1c00013, table 0xed1234)
FswAsIni_EventDispatch:
	calr	6
	calr	30

SeqLoadFunc_ReturnZero:
	lds32 xhl, 0
	ret

FSWAss_CheckAndNotify:
	; --- Init/check function (27 bytes) ---
	ld xwa, 0x00004080
	call SndParam_LookupReadOnly
	cps	hl, 1
	ret nz
	ld xwa, 0x00004080
	lds	bc, 0
	lds	de, 4
	call SoundParam_NotifyChange
	ret
FSWAss_RefreshAllVoices:
	; --- Multi-call setup function (37 bytes) ---
	push xde
	push xhl
	push xix
	push xiz
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call NoteMap_SendAllNotesOff
	call Voice_InitTableGroup
	call Voice_InitTablePair
	call MIDI_SendAllSoundOff
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret


IvPmemWindow_Boundary:

IvPmemWindowPageCtlProc:
	dec 4, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xwa
	cp xbc, 0x1c00007
	jr z, PmemPageCtl_OK_PageSwitch
	cp xbc, 0x1c00001
	jr z, PmemPageCtl_InitForward
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	jrl PmemPageCtl_Epilogue

PmemPageCtl_InitForward:
	ld xwa, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	cp xiz, 0x4
	jr z, GridBox_NotifySelection
	cp xiz, 0x3
	jr z, GridBox_NotifySelection
	cp xiz, 0x5
	jr z, GridBox_NotifySelection
	or xiz, xiz
	jrl nz, SeqLoad_ReturnZeroJmp2

GridBox_NotifySelection:
	ld xwa, (xsp + 4)
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xbc)
	ldw (xwa), 0x1
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	call SendEvent
	jrl SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_PageSwitch:
	ld xwa, (xsp + 4)
	call GetViewInstance
	lda xwa, (xhl + 22)
	cp xiz, 0x10
	jr nz, PmemPageCtl_OK_Rotate
	ld xwa, (xwa)
	ld bc, (xwa)
	cps bc, 2
	jr z, PmemPageCtl_OK_AdvanceTo2
	cps bc, 1
	jrl nz, SeqLoad_ReturnZeroJmp2
	incm 1, (xwa)
	stib_da 0x0340e2, 0x01
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_AdvanceTo2:
	cpib_da 0x0340e2, 0x01
	jr nz, PmemPageCtl_OK_ResetTo1
	stib_da 0x0340e2, 0x02
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_ResetTo1:
	ldw (xwa), 0x1
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_Rotate:
	cp xiz, 0x90
	jr nz, SeqLoad_ReturnZeroJmp2
	ld xwa, (xwa)
	ld bc, (xwa)
	cps bc, 2
	jr z, PmemPageCtl_OK_RotateReverse
	cps bc, 1
	jr nz, SeqLoad_ReturnZeroJmp2
	ldw (xwa), 0x2
	stib_da 0x0340e2, 0x02
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0

SeqLoad_PostEvent:
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotateReverse:
	cpib_da 0x0340e2, 0x01
	jr nz, PmemPageCtl_OK_RotatePost
	decm 1, (xwa)
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotatePost:
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	stib_da 0x0340e2, 0x01

SeqLoad_ReturnZeroJmp2:
	lds32 xhl, 0

PmemPageCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret
PmemPageCtl_Boundary:

AcPmExpFilterGridBoxProc:
	stb_dri L, 0xfd, 0xdc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x20, 0x01
	stl_dri XBC, 0xfd, 0x24, 0x01
	ld xiz, xwa
	ld_sril XBC, (xsp + 0x0124)
	cp xbc, 0x1c00007
	jrl z, PmExpFilter_OkHandler
	ld_sril XWA, (xsp + 0x0124)
	cp xwa, 0x1e0008d
	jrl z, PmExpFilter_ForwardToView
	cp xwa, 0x1e0008b
	jrl z, PmExpFilter_GetNameB
	cp xwa, 0x1e0008a
	jrl z, PmExpFilter_GetNameA
	cp xwa, 0x1c0000f
	jrl z, PmExpFilter_Repaint
	cp xwa, 0x1c0000b
	jrl z, PmExpFilter_ShowHide
	cp xwa, 0x1c00001
	jr z, PmemPageCtl_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, PmExpFilter_DefaultInherited
	cp xbc, 0x6
	jrl gt, PmExpFilter_DefaultInherited
	add xbc, xbc
	add xbc, ParamStr02_Vocalist_0x44
	ld bc, (xbc)
	lda_24 xix, PmemPageCtl_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; IvPmemWindowPageCtl event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1420)
PmemPageCtl_EventDispatch:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl PmExpFilter_SetDialEnable

PmExpFilter_ShowHide:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, 0xffff0002
	call SendEvent
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_Repaint:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	lda xbc, (xsp + 12)
	ldw (xbc), 0x3a
	lda xhl, (xbc + 2)
	ldw (xhl), 0x23
	lda xwa, (xsp + 16)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x5c
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	lds32 xde, 0
	push xde
	pushw 0xfb
	pushw 0xf5
	ld xde, ParamStr02_Vocalist_0x14
	call DrawString
	lda xbc, (xsp + 12)
	ldw (xbc), 0xe0
	lda xhl, (xbc + 2)
	ldw (xhl), 0x23
	lda xwa, (xsp + 16)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x34
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	lds32 xde, 0
	push xde
	pushw 0xfb
	pushw 0xf5
	ld xde, ParamStr02_Vocalist_0x20
	call DrawString
	ld (xsp + 10), 0x0
	cpib_da 0x0340e2, 0x01
	jrl nz, PmExpFilter_DrawCellBank2

PmExpFilter_DrawCellBank1:
	stb_dri A, 0xfd, 0x18, 0x01
	ldw (xbc), 0x0
	ld a, (xsp + 10)
	inc 2, a
	extz wa
	ld (xbc + 2), wa
	lda xde, (xsp + 24)
	ld (xbc + 4), xde
	ld a, (xsp + 10)
	extz wa
	sla wa, 2
	lda_24 xbc, ParamStr_Table_01
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1404
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x18, 0x01
	ld xbc, 0x1e0008c
	call SendEvent
	incm8 1, (xsp + 10)
	cp (xsp + 10), 0x9
	jr c, PmExpFilter_DrawCellBank1
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xf5
	ldw (xwa + 4), 0x13b
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	lda xde, (xsp + 16)
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	lda xhl, (xsp + 12)
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	pushw 0xed
	pushw 0x1408
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 12)
	lda xde, (xsp + 24)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7
	jrl PmExpFilter_DrawCentered

PmExpFilter_DrawCellBank2:
	stb_dri A, 0xfd, 0x18, 0x01
	ldw (xbc), 0x0
	ld a, (xsp + 10)
	inc 2, a
	extz wa
	ld (xbc + 2), wa
	lda xde, (xsp + 24)
	ld (xbc + 4), xde
	ld a, (xsp + 10)
	extz wa
	sla wa, 2
	lda_24 xbc, ParamStr_Table_02
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1412
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x18, 0x01
	ld xbc, 0x1e0008c
	call SendEvent
	incm8 1, (xsp + 10)
	cp (xsp + 10), 0x9
	jr c, PmExpFilter_DrawCellBank2
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xf5
	ldw (xwa + 4), 0x13b
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	lda xde, (xsp + 16)
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	lda xhl, (xsp + 12)
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	pushw 0xed
	pushw 0x1416
	lda xwa, (xsp + 28)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 16)
	lda xbc, (xsp + 12)
	lda xde, (xsp + 24)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7

PmExpFilter_DrawCentered:
	call DrawStringCentered
	jrl SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cpib_da 0x0340e2, 0x02
	jr nz, PmExpFilter_DecAndUpdate
	cps hl, 2
	jr nz, PmExpFilter_DecAndUpdate
	stib_da 0x0340e2, 0x01
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, 0xffff000a
	jr PmExpFilter_SendSelEvent

PmExpFilter_DecAndUpdate:
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl

PmExpFilter_SendSelEvent:
	call SendEvent
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jrl z, SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call ApFuncCall
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1
	jrl PmExpFilter_SetDialEnable
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward2
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ldb_da a, 0x0340e2
	cps a, 2
	jr nz, PmExpFilter_CheckAdvBank
	cp hl, 0xa
	jrl z, SeqLoad_ReturnZeroJmp

PmExpFilter_CheckAdvBank:
	cps a, 1
	jr nz, PmExpFilter_IncAndUpdate
	cp hl, 0xa
	jr nz, PmExpFilter_IncAndUpdate
	stib_da 0x0340e2, 0x02
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, 0xffff0002
	jr PmExpFilter_SendSelEvent2

PmExpFilter_IncAndUpdate:
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl

PmExpFilter_SendSelEvent2:
	call SendEvent
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward2:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jrl z, SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call ApFuncCall
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1

PmExpFilter_SetDialEnable:
	call SetDialEnable
	jr SeqLoad_ReturnZeroJmp

PmExpFilter_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3e
	jr PmExpFilter_GetNameCommon

PmExpFilter_GetNameB:
	ld xwa, xiz
	ld xiz, 0x42

PmExpFilter_GetNameCommon:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld_sril XWA, (xsp + 0x0124)
	push xwa
	call Strcpy
	inc 8, xsp
	jr SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	jr PmExpFilter_ForwardApFunc

PmExpFilter_ForwardToView:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)

PmExpFilter_ForwardApFunc:
	call ApFuncCall

SeqLoad_ReturnZeroJmp:
	lds32 xhl, 0
	jr PmExpFilter_Epilogue

PmExpFilter_OkHandler:
	ld_sril XWA, (xsp + 0x0120)
	cp xwa, 0xf
	jr nz, PmExpFilter_OK_InheritedFwd
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	jr PmExpFilter_OK_InheritedFwd

PmExpFilter_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

PmExpFilter_OK_InheritedFwd:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	jr PmExpFilter_CallInherited

PmExpFilter_DefaultInherited:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)

PmExpFilter_CallInherited:
	call InheritedProc

PmExpFilter_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x24, 0x01
	ret

PmExpFilterGridCheck:
	stb_dri L, 0xfd, 0xf8, 0xfe
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, PmExpFilterCheck_CellDecode
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, SeqLoad_StoreReturnZero
	cp xwa, 0x6
	jrl gt, SeqLoad_StoreReturnZero
	add xwa, xwa
	add xwa, ParamStr02_Vocalist_0xBE
	ld wa, (xwa)
	lda_24 xix, PmExpFilter_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; PmExpFilterGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed149a)
PmExpFilter_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x30
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jrl	nz, 619
	ldb_da	c, 0x340e2
	ld	wa, de
	sla	wa, 2
	dec	8, wa
	cps	c, 2
	jr	z, 35
	cps	c, 1
	jrl	nz, 598
	cps	de, 2
	jrl	lt, 593
	cp	de, 10
	jrl	gt, 586
	lda_24	xbc, ParamStr02_Vocalist_0x52
	ld_rrl	xwa, xbc, wa
	ldw	bc, 0xffff
	lds	de, 2
	jrl	148
	cps	de, 2
	jrl	lt, 563
	cp	de, 10
	jrl	gt, 556
	lda_24	xbc, ParamStr02_Vocalist_0x76
	ld_rrl	xwa, xbc, wa
	ldw	bc, 0xffff
	lds	de, 2
	jr	119
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x31
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	(xbc+2), de
	ld	wa, de
	sla	wa, 2
	dec	8, wa
	cpw	(xbc), 1
	jrl	nz, 488
	ldb_da	c, 0x340e2
	cps	c, 2
	jr	z, 33
	cps	c, 1
	jrl	nz, 474
	cps	de, 2
	jrl	lt, 469
	cp	de, 10
	jrl	gt, 462
	lda_24	xbc, ParamStr02_Vocalist_0x52
	ld_rrl	xwa, xbc, wa
	lds	bc, 1
	lds	de, 2
	jr	26
	cps	de, 2
	jrl	lt, 441
	cp	de, 10
	jrl	gt, 434
	lda_24	xbc, ParamStr02_Vocalist_0x76
	ld_rrl	xwa, xbc, wa
	lds	bc, 1
	lds	de, 2
	call	MainLswAdd
	jrl	413
	ldb_da	a, 0x340e2
	cps	a, 2
	jr	z, 103
	cps	a, 1
	jrl	nz, 399
	ldb	l, 0
	lda_24	xix, ParamStr02_Vocalist_0x52
	ld	xwa, (xde)
	ld	c, l
	extz	bc
	sla	bc, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xe4, 0xf0
	jr	nz, 65
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x31
	ldw	(xbc), 1
	inc	2, l
	extz	hl
	ld	(xbc+2), hl
	lda	xhl, (xsp)
	ld	(xbc+4), xhl
	ld	xwa, ParamStr02_Vocalist_0x9E
	cpw	(xde+4), 0
	jr	z, 5
	ld	xwa, ParamStr02_Vocalist_0x9A
	push	xwa
	push	xhl
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x32
	ld	xbc, 0x1e0008c
	jrl	307
	inc	1, l
	cp	l, 9
	jr	c, -86
	jrl	301
	ldb	l, 0
	lda_24	xix, ParamStr02_Vocalist_0x76
	ld	xwa, (xde)
	ld	c, l
	extz	bc
	sla	bc, 2
	.byte 0xe3
	reti
	.byte 0xf0, 0xe4, 0xf0
	jr	nz, 65
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x31
	ldw	(xbc), 1
	inc	2, l
	extz	hl
	ld	(xbc+2), hl
	lda	xhl, (xsp)
	ld	(xbc+4), xhl
	ld	xwa, ParamStr02_Vocalist_0xA6
	cpw	(xde+4), 0
	jr	z, 5
	ld	xwa, ParamStr02_Vocalist_0xA2
	push	xwa
	push	xhl
	call	Strcpy
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	.byte 0xf3
	swi	5
	nop
	.byte 0x01, 0x32
	ld	xbc, 0x1e0008c
	jrl	209
	inc	1, l
	cp	l, 9
	jr	c, -86
	jrl	203

PmExpFilterCheck_CellDecode:
	stb_dri C, 0xfd, 0x00, 0x01
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld wa, de
	ld (xbc), wa
	lda xde, (xsp)
	ld (xhl + 4), xde
	ld wa, (xbc)
	ld bc, wa
	sla bc, 2
	cpw (xhl), 0x1
	jrl nz, SeqLoad_StoreReturnZero
	ldb_da l, 0x0340e2
	dec 8, bc
	cps l, 2
	jr z, PmExpFilterCheck_AltDecode
	cps l, 1
	jrl nz, SeqLoad_StoreReturnZero
	cps wa, 2
	jrl lt, SeqLoad_StoreReturnZero
	cp wa, 0xa
	jrl gt, SeqLoad_StoreReturnZero
	lda_24 xwa, ParamStr02_Vocalist_0x52
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	call SndParam_LookupReadOnly
	ld xwa, ParamStr02_Vocalist_0xAE
	cps hl, 0
	jr nz, PmExpFilterCheck_SendNameA
	ld xwa, ParamStr02_Vocalist_0xAA

PmExpFilterCheck_SendNameA:
	push xwa
	lda xwa, (xsp + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x00, 0x01
	ld xbc, 0x1e0008c
	jr PmExpFilterCheck_DoSend

PmExpFilterCheck_AltDecode:
	cps wa, 2
	jr lt, PmExpFilterCheck_PushDefault
	cp wa, 0xa
	jr gt, PmExpFilterCheck_PushDefault
	lda_24 xwa, ParamStr02_Vocalist_0x76
	ld_sril3 XWA, 0x07, 0xe0, 0xe4
	call SndParam_LookupReadOnly
	lda xbc, (xsp)
	ld xwa, ParamStr02_Vocalist_0xB6
	cps hl, 0
	jr nz, PmExpFilterCheck_PushNameB
	ld xwa, ParamStr02_Vocalist_0xB2

PmExpFilterCheck_PushNameB:
	push xwa
	push xbc
	jr PmExpFilterCheck_StrcpySend

PmExpFilterCheck_PushDefault:
	pushw 0xed
	pushw 0x1496
	push xde

PmExpFilterCheck_StrcpySend:
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	stb_dri B, 0xfd, 0x00, 0x01
	ld xbc, 0x1e0008c

PmExpFilterCheck_DoSend:
	call SendEvent

SeqLoad_StoreReturnZero:
	lds32 xhl, 0
	stb_dri L, 0xfd, 0x08, 0x01
	ret
PmExpFilterCheck_Boundary:

AcDispTimeSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1e0008d
	jrl z, DispTimeSet_CellSelectFwd
	ld xwa, (xsp + 16)
	cp xwa, 0x1e0008b
	jrl z, DispTimeSet_GetNameB
	cp xwa, 0x1e0008a
	jrl z, DispTimeSet_GetNameA
	cp xwa, 0x1c00002
	jrl z, DispTimeSet_SelectInit
	cp xwa, 0x1c00001
	jr z, PmExpFilter2_EventDispatch
	sub xbc, 0x1c00017
	cp xbc, 0x0
	jrl lt, DispTimeSet_DefaultInherited
	cp xbc, 0x6
	jrl gt, DispTimeSet_DefaultInherited
	add xbc, xbc
	add xbc, ParamStr02_Vocalist_0xCC
	ld bc, (xbc)
	lda_24 xix, PmExpFilter2_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4

; PmExpFilter event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed14a8)
PmExpFilter2_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1c00018
	call SetDialDown
	lds wa, 1
	jrl DispTimeSet_SetDialEnabled

DispTimeSet_SelectInit:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, (xsp + 12)
	or xwa, xwa
	jrl nz, SeqSave_ReturnZeroJmp
	lds wa, 5
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jrl z, SeqSave_ReturnZeroJmp
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	stdi8 0x7f42, 72
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	ld xwa, 0x142000e
	ld xbc, 0x1e20015
	ld xde, (xsp + 12)
	call MainFuncCall
	jrl SeqSave_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, DispTimeSet_DialFallback
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl SeqSave_ReturnZeroJmp

DispTimeSet_DialFallback:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, SeqSave_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl DispTimeSet_SetDialEnabled
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, DispTimeSet_DialFallback2
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl SeqSave_ReturnZeroJmp

DispTimeSet_DialFallback2:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, SeqSave_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

DispTimeSet_SetDialEnabled:
	call SetDialEnable
	jr SeqSave_ReturnZeroJmp

DispTimeSet_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3e
	jr DispTimeSet_GetNameCommon

DispTimeSet_GetNameB:
	ld xwa, xiz
	ld xiz, 0x42

DispTimeSet_GetNameCommon:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr SeqSave_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr DispTimeSet_CallApFunc

DispTimeSet_CellSelectFwd:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

DispTimeSet_CallApFunc:
	call ApFuncCall

SeqSave_ReturnZeroJmp:
	lds32 xhl, 0
	jr DispTimeSet_Epilogue

DispTimeSet_DefaultInherited:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

DispTimeSet_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

DispTimeSetGridCheck:
	lda xsp, (xsp - 44)
	push xiz
	ld xwa, xbc
	cp xbc, 0x1e0008d
	jrl z, DispTimeSetCheck_CellDecode
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, DispTimeSet_ReturnZero
	cp xwa, 0x6
	jrl gt, DispTimeSet_ReturnZero
	add xwa, xwa
	add xwa, FadeTimeStr_Off_0x38
	ld wa, (xwa)
	lda_24 xix, DispTimeSet_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; DispTimeSetGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1582)
DispTimeSet_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+40)
	ld	xbc, xde
	srl	xbc, 0
	.byte 0xd7, 0xe6, 0xa8
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, 40
	cps	de, 2
	jr	nz, 36
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340e6
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	555
	cpw	(xwa), 1
	jr	nz, 40
	cps	de, 3
	jr	nz, 36
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340e8
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	509
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 37
	cps	de, 4
	jr	nz, 33
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340ea
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	lds32	xbc, 2
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	466
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 40
	cps	de, 5
	jr	nz, 36
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340ec
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 1
	ld	(xwa+10), xbc
	jrl	420
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jr	nz, 40
	cps	de, 6
	jr	nz, 36
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340ee
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 1
	ld	(xwa+10), xbc
	jrl	374
	.byte 0x90
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 1199
	cps	de, 7
	jrl	nz, 1194
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340f0
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	lds32	xbc, 1
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 1
	ld	(xwa+10), xbc
	jrl	326
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	xde, xhl
	lda	xiy, (xsp+40)
	ld	xwa, xde
	srl	xwa, 0
	.byte 0xd7, 0xe2, 0xa8
	ld	(xiy), wa
	ld	iz, de
	ld	(xiy+2), iz
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jr	nz, 43
	cps	iz, 2
	jr	nz, 39
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340e6
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	240
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jr	nz, 43
	cps	iz, 3
	jr	nz, 39
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340e8
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	191
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jr	nz, 40
	cps	iz, 4
	jr	nz, 36
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340ea
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	lds32	xbc, 2
	ld	(xwa+6), xbc
	lds32	xbc, 0
	ld	(xwa+10), xbc
	jrl	145
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jr	nz, 42
	cps	iz, 5
	jr	nz, 38
	lda	xwa, (xsp+8)
	lda_24	xbc, 0x340ec
	ld	(xwa), xbc
	.byte 0xb8, 0x04
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	lds32	xbc, 1
	ld	(xwa+10), xbc
	jr	97
	lda	xwa, (xsp+8)
	lda	xbc, (xwa+4)
	lda	xhl, (xwa+6)
	lda	xde, (xwa+10)
	lda	xix, (xwa+14)
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jr	nz, 35
	cps	iz, 6
	jr	nz, 31
	lda_24	xiy, 0x340ee
	ld	(xwa), xiy
	.byte 0xb1
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xix), xbc
	ld	xbc, 12
	ld	(xhl), xbc
	lds32	xbc, 1
	ld	(xde), xbc
	jr	41
	.byte 0x95
	push	xsp
	.byte 0x01
	nop
	jrl	nz, 866
	cps	iz, 7
	jrl	nz, 861
	lda_24	xiy, 0x340f0
	ld	(xwa), xiy
	.byte 0xb1
	push	sr
	.byte 0x01
	nop
	ld	xbc, 0xffffffff
	ld	(xix), xbc
	ld	xbc, 12
	ld	(xhl), xbc
	lds32	xbc, 1
	ld	(xde), xbc
	call	MainRamAdd
	jrl	825
	lda_24	xwa, 0x340e6
	lda	xiy, (xde+14)
	.byte 0xa2, 0xf0
	jr	nz, 64
	lda	xwa, (xsp+40)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	push	sr
	nop
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, ParamStr_Table_03
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw	237
	pushw	5458
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	745
	lda_24	xwa, 0x340e8
	.byte 0xa2, 0xf0
	jr	nz, 64
	lda	xwa, (xsp+40)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	pop	sr
	nop
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, ParamStr_Table_03
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw	237
	pushw	5462
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	672
	lda_24	xbc, 0x340ea
	lda_24	xwa, ParamStr_Table_03
	ld	(xsp+4), xwa
	.byte 0xa2, 0xf1
	jr	nz, 62
	lda	xwa, (xsp+40)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	.byte 0x04
	nop
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, (xsp+4)
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw	237
	pushw	5466
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	593
	lda_24	xwa, 0x340ec
	.byte 0xa2, 0xf0
	jr	nz, 62
	lda	xwa, (xsp+40)
	.byte 0xb0
	push	sr
	.byte 0x01
	nop
	.byte 0xb8
	push	sr
	push	sr
	halt
	nop
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, (xsp+4)
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw	237
	pushw	5470
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	522
	lda_24	xiz, 0x340ee
	lda	xhl, (xsp+40)
	lda	xix, (xsp+30)
	lda	xwa, (xhl+2)
	lda	xbc, (xhl+4)
	.byte 0xa2, 0xf6
	jr	nz, 54
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xb0
	push	sr
	di
	ld	(xbc), xix
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	pushw	237
	pushw	5474
	push	xix
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	447
	lda_24	xiz, 0x340f0
	.byte 0xa2, 0xf6
	jrl	nz, 441
	.byte 0xb3
	push	sr
	.byte 0x01
	nop
	.byte 0xb0
	push	sr
	reti
	nop
	ld	(xbc), xix
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	pushw	237
	pushw	5478
	push	xix
	call	Sprintf_Locked
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 0x1e0008c
	jrl	383

DispTimeSetCheck_CellDecode:
	lda xhl, (xsp + 40)
	ld xwa, xde
	srl xwa, 0
	ldiw_erp 0xe2, 0
	ld (xhl), wa
	lda xwa, (xhl + 2)
	ld (xwa), de
	lda xbc, (xsp + 30)
	ld (xhl + 4), xbc
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow3
	cpw (xwa), 0x2
	jr nz, DispTimeSetCheck_TryRow3
	ldb_da a, 0x0340e6
	extz wa
	sla wa, 2
	lda_24 xde, ParamStr_Table_03
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x156a
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow3:
	lda_24 xde, ParamStr_Table_03
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow4
	cpw (xwa), 0x3
	jr nz, DispTimeSetCheck_TryRow4
	ldb_da a, 0x0340e8
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x156e
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow4:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow5
	cpw (xwa), 0x4
	jr nz, DispTimeSetCheck_TryRow5
	ldb_da a, 0x0340ea
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1572
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow5:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow6
	cpw (xwa), 0x5
	jr nz, DispTimeSetCheck_TryRow6
	ldb_da a, 0x0340ec
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1576
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c
	jr DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow6:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow7
	cpw (xwa), 0x6
	jr nz, DispTimeSetCheck_TryRow7
	ldb_da a, 0x0340ee
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x157a
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c
	jr DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow7:
	cpw (xhl), 0x1
	jr nz, DispTimeSet_ReturnZero
	cpw (xwa), 0x7
	jr nz, DispTimeSet_ReturnZero
	ldb_da a, 0x0340f0
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	push xwa
	pushw 0xed
	pushw 0x157e
	push xbc
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1e0008c

DispTimeSet_SendEventReturn:
	call SendEvent

DispTimeSet_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 44)
	ret

DispTimeSetOKFunc:
	cp xbc, 0x1c00007
	jr nz, DispTimeSetOK_ReturnZero
	ld xwa, 0x142000e
	ld xbc, 0x1e20014
	call MainFuncCall

DispTimeSetOK_ReturnZero:
	lds32 xhl, 0
	ret

MainTimeFlashFunc:
	cp xbc, 0x1e20015
	jr z, MainTimeFlash_DispatchCmd
	cp xbc, 0x1e20014
	jr nz, MainTimeFlash_ReturnZero
	stdi8 0x7f42, 40
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent
	lds wa, 5
	call CtrlPanel_IndicatorJumpTable
	stdi8 0x7f42, 35
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent
	jr MainTimeFlash_ReturnZero

MainTimeFlash_DispatchCmd:
	lds wa, 5
	call Audio_DispatchCommand

MainTimeFlash_ReturnZero:
	lds32 xhl, 0
	ret
MainTimeFlash_Boundary:

NormScreenProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c00001
	jr z, NormScreen_InitHandler
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr NormScreen_Epilogue

NormScreen_InitHandler:
	ld xwa, xiz
	call GetViewInstance
	cpib_da 0x0340e6, 0x00
	jr z, NormScreen_ClearBit
	ldb_d8 a, 0x8d88
	extz wa
	bit 0, wa
	jr z, NormScreen_ClearBit
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	stdi8 0x7f42, 36
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call PostEvent
	resda 0, 0x8d88

NormScreen_ClearBit:
	resda 0, 0x8d88
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	lds32 xhl, 0

NormScreen_Epilogue:
	pop xiz
	inc 8, xsp
	ret
NormScreen_Boundary:

IvWindowPageControlProc:
	dec 8, xsp
	push xiz
	ld (xsp + 8), xde
	ld xiz, xwa
	cp xbc, 0x1c00007
	jrl z, IvWindowPgCtl_OkHandler
	cp xbc, 0x1c20006
	jrl z, IvWindowPgCtl_PageChanged
	cp xbc, 0x1c00002
	jr z, IvWindowPgCtl_Deselect
	cp xbc, 0x1c00001
	jr z, IvWindowPgCtl_Init
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	jrl IvWindowPgCtl_Epilogue

IvWindowPgCtl_Init:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	lda xbc, (xiz + 22)
	lds wa, 1
	cps hl, 1
	jr nz, IvWindowPgCtl_SetPageIndex
	lds wa, 3

IvWindowPgCtl_SetPageIndex:
	ld xde, (xbc)
	ld (xde), wa
	ld xwa, (xbc)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c20004
	call SendEvent
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_Deselect:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 0
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_PageChanged:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xde, (xwa + 22)
	ld xbc, (xde)
	ld xwa, (xsp + 8)
	ld (xbc), wa
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x5
	jr ge, IvWindowPgCtl_DisableFunc
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_DisableFunc:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 0
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_OkHandler:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	cp xwa, 0xf
	jrl z, IvWindowPgCtl_JumpToEnd
	cp xwa, 0x8f
	jrl nz, IvWindowPgCtl_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x4
	jr ge, IvWindowPgCtl_TryNextPage
	incm 1, (xwa)
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	jr IvWindowPgCtl_SendPageEvent

IvWindowPgCtl_TryNextPage:
	cpw (xwa), 0x4
	jr nz, IvWindowPgCtl_DisableAll
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 22)
	lds wa, 1
	cps hl, 1
	jr nz, IvWindowPgCtl_SetNextPage
	lds wa, 2

IvWindowPgCtl_SetNextPage:
	ld xbc, (xbc)
	ld (xbc), wa
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e

IvWindowPgCtl_SendPageEvent:
	call SendEvent
	jrl IvWindowPgCtl_ReturnZero

IvWindowPgCtl_DisableAll:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 0

UI_MainFuncCall_Execute:
	call MainFuncCall
	jr IvWindowPgCtl_ReturnZero

IvWindowPgCtl_JumpToEnd:
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, IvWindowPgCtl_JumpToStart
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x3
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x3
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	jr IvWindowPgCtl_DoSendEvent

IvWindowPgCtl_JumpToStart:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x1
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x1
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e

IvWindowPgCtl_DoSendEvent:
	call SendEvent

IvWindowPgCtl_ReturnZero:
	lds32 xhl, 0

IvWindowPgCtl_Epilogue:
	pop xiz
	inc 8, xsp
	ret
IvWindowPgCtl_Boundary:

IvPageOverWrProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld (xsp + 12), xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1c0001e
	jrl z, IvPageOverWr_PageChanged
	cp xwa, 0x1c20004
	jr z, IvPageOverWr_PageSelect
	cp xwa, 0x1e0003a
	jr z, IvPageOverWr_GetName
	cp xwa, 0x1c0000d
	jr z, IvPageOverWr_KeyPress
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jrl IvPageOverWr_Epilogue

IvPageOverWr_KeyPress:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 12)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl IvPageOverWr_SendAndReturn

IvPageOverWr_GetName:
	pushw 0xed
	pushw 0x1590
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl PmNamingCheck_CleanupRet

IvPageOverWr_PageSelect:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageSelect2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	lds32 xde, 0
	call SendEvent

IvPageOverWr_PageSelect2:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (xiz + 22)
	exts xwa
	cp xwa, (xsp + 4)
	jr nz, PmNamingCheck_CleanupRet
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr IvPageOverWr_SendAndReturn

IvPageOverWr_PageChanged:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageChanged2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	lds32 xde, 5
	call SendEvent

IvPageOverWr_PageChanged2:
	ld xwa, (xsp + 12)
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld wa, (xiz + 22)
	exts xwa
	cp xwa, (xsp + 4)
	jr nz, PmNamingCheck_CleanupRet
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00001
	lds32 xde, 5

IvPageOverWr_SendAndReturn:
	call SendEvent

PmNamingCheck_CleanupRet:
	lds32 xhl, 0

IvPageOverWr_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PmNamingCheck:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xde
	ld xiz, xwa
	cp xbc, 0x1c00007
	jr z, PmNaming_HandleKeyPress
	cp xbc, 0x1e0007c
	jr z, PmNaming_GetKeyLayout
	cp xbc, 0x1e00084
	jrl z, PmBankNamingCheck_Ret
	cp xbc, 0x1e0003a
	jrl nz, PmBankNamingCheck_Ret
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	ld xbc, (xsp + 22)
	call BitMapOut_UpdateDisplayWidget
	ld xhl, xiz
	jrl PmNaming_Epilogue

PmNaming_GetKeyLayout:
	ld xhl, 0x10
	jrl PmNaming_Epilogue

PmNaming_HandleKeyPress:
	ld xwa, (xsp + 22)
	cp xwa, 0xb
	jr nz, PmNaming_HandleF_Confirm
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	cps l, 0
	jr z, PmNaming_HandleF_Confirm
	call GetNamingWindowID
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0003a
	call SendEvent
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	extz hl
	lda xbc, (xsp + 4)
	ld wa, hl
	call BitMapOut_UpdateWidget_TypeB
	call GetNamingWindowID
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0003a
	call SendEvent
	lda xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xf9a2
	call Strcpy
	inc 8, xsp
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d1
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call PostEvent

PmNaming_HandleF_Confirm:
	ld xwa, (xsp + 22)
	cp xwa, 0xf
	jr nz, PmBankNamingCheck_Ret
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d1
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call PostEvent

PmBankNamingCheck_Ret:
	lds32 xhl, 0

PmNaming_Epilogue:
	pop xiz
	lda xsp, (xsp + 22)
	ret

PmBankNamingCheck:
	lda xsp, (xsp - 22)
	push xiz
	ld (xsp + 22), xde
	ld xiz, xwa
	cp xbc, 0x1c00007
	jr z, PmBankNaming_HandleKeyPress
	cp xbc, 0x1e0007c
	jr z, PmBankNaming_GetKeyLayout
	cp xbc, 0x1e00084
	jrl z, MssNameFunc_CleanupRet
	cp xbc, 0x1e0003a
	jrl nz, MssNameFunc_CleanupRet
	call BitMapOut_PrepareRender_CheckBit1
	ld a, l
	ld xbc, (xsp + 22)
	call BitMapOut_UpdateWidget_PostDraw
	ld xhl, xiz
	jrl PmBankNaming_Epilogue

PmBankNaming_GetKeyLayout:
	ld xhl, 0x10
	jr PmBankNaming_Epilogue

PmBankNaming_HandleKeyPress:
	ld xwa, (xsp + 22)
	cp xwa, 0xb
	jr nz, PmBankNaming_HandleF_Confirm
	call GetNamingWindowID
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1e0003a
	call SendEvent
	call BitMapOut_PrepareRender_CheckBit1
	ld a, l
	lda xbc, (xsp + 4)
	call BitMapOut_UpdateWidget_Finalize
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d1
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call PostEvent

PmBankNaming_HandleF_Confirm:
	ld xwa, (xsp + 22)
	cp xwa, 0xf
	jr nz, MssNameFunc_CleanupRet
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d1
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call PostEvent

MssNameFunc_CleanupRet:
	lds32 xhl, 0

PmBankNaming_Epilogue:
	pop xiz
	lda xsp, (xsp + 22)
	ret

MssNameFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jrl lt, MssName_ReturnZero
	cp xbc, 0x9
	jrl gt, MssName_ReturnZero
	add xbc, xbc
	add xbc, FadeTimeStr_Off_0x62
	ld bc, (xbc)
	lda_24 xix, MssName_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4
; MssNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ac)
MssName_EventDispatch:
	ld	xiz, xde
	lda	xbc, (xiz+14)
	ld	xwa, (xbc)
	or	xwa, xwa
	jr	nz, 19
	pushw	237
	pushw	5526
	ld	xwa, (xiz+18)
	push	xwa
	call	Strcpy
	inc	8, xsp
	jrl	129
	dec	1, xwa
	cp	xwa, 800
	jr	le, 4
	lds32	xwa, 2
	ld	(xbc), xwa
	ld	xwa, (xbc)
	dec	1, xwa
	call	EffectMode_SearchPresetTableC0
	ld	xwa, (xiz+14)
	dec	1, xwa
	cp	xhl, 0xffffffff
	jr	z, 43
	pushw	16
	call	EffectMode_SearchPresetTableC0
	push	xhl
	ld	xwa, (xiz+18)
	push	xwa
	call	Strncpy
	pushw	2
	pushw	32
	ld	xwa, (xiz+18)
	lda	xwa, (xwa+16)
	push	xwa
	call	Sprintf_DataBlock_28E9
	lda	xsp, (xsp+18)
	ld	xwa, FadeTimeStr_Off_0x5A
	jr	37
	sll	xwa, 2
	add	xwa, 0x987000
	ld	xbc, (xwa)
	ld	a, (xbc+42)
	extz	wa
	pushw	wa
	lda	xwa, (xbc+43)
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	Strncpy
	lda	xsp, (xsp+10)
	ld	xwa, FadeTimeStr_Off_0x5E
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	TmFlash_CompareStrings
	inc	8, xsp
	ld	(xhl), 0
	ld	xhl, (xsp+4)
	jr	23
	lds32	xhl, 1
	jr	19
	ld	xhl, 512
	jr	12
	lda_d16	xhl, 0x8d56
	jr	6
	lds32	xhl, 2
	jr	2

MssName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret
MssName_Boundary:

AcPmBkNoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcPmBkNoBox_Match
	cp xbc, 0x1c0000c
	jr z, AcPmBkNoBox_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcPmBkNoBox_ShowHide
	cp xbc, 0x1c00002
	jr z, AcPmBkNoBox_Focus
	cp xbc, 0x1c00001
	jr z, AcPmBkNoBox_Init
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcPmBkNoBox_Epilogue

AcPmBkNoBox_Init:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call SetLswFilter
	jrl UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_Focus:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call ResetLswFilter
	jr UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_ShowHide:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x300
	call MainLswGet
	jr UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_Match:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x300
	jr nz, UI_AcPmBkNoBoxProc_Return
	lda xde, (xsp + 4)
	ld bc, (xiz + 4)
	cps bc, 0
	jr nz, AcPmBkNoBox_FormatBankNo
	pushw 0xed
	pushw 0x15c0
	push xde
	call Strcpy
	inc 8, xsp
	jr AcPmBkNoBox_SendConfirm

AcPmBkNoBox_FormatBankNo:
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0x8
	stw_erp WA, 0xe2
	inc 1, wa
	pushw wa
	exts xbc
	divs bc, 0x8
	inc 1, bc
	pushw bc
	pushw 0xed
	pushw 0x15ca
	push xde
	call Sprintf_Locked
	lda xsp, (xsp + 12)

AcPmBkNoBox_SendConfirm:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_AcPmBkNoBoxProc_Return:
	lds32 xhl, 0

AcPmBkNoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
AcPmBkNoBox_Boundary:

AcBkNoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	stl_dri XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c0001c
	jr z, AcBkNoBox_Match
	cp xbc, 0x1c0000c
	jr z, AcBkNoBox_ShowHide
	cp xbc, 0x1c0000b
	jr z, AcBkNoBox_ShowHide
	cp xbc, 0x1c00002
	jr z, AcBkNoBox_Focus
	cp xbc, 0x1c00001
	jr z, AcBkNoBox_Init
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcBkNoBox_Epilogue

AcBkNoBox_Init:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call SetLswFilter
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_Focus:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call ResetLswFilter
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_ShowHide:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x300
	call MainLswGet
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_Match:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xiz)
	cp xwa, 0x300
	jr nz, UI_AcBkNoBoxProc_Return
	call BitMapOut_PrepareRender_CheckBit1
	inc 1, l
	extz hl
	pushw hl
	pushw 0xed
	pushw 0x15d2
	lda xwa, (xsp + 10)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_AcBkNoBoxProc_Return:
	lds32 xhl, 0

AcBkNoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
AcBkNoBox_Boundary:

MsaModeScreenProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xbc
	ld (xsp + 24), xwa
	cp xiz, 0x1c00007
	jrl z, MsaMode_OK
	cp xiz, 0x1c0000e
	jrl z, MsaMode_Select
	cp xiz, 0x1c0000d
	jrl z, MsaMode_Paint
	cp xiz, 0x1c0001c
	jr z, MsaMode_Match
	cp xiz, 0x1c0000b
	jr z, MsaMode_Show
	cp xiz, 0x1c00001
	jrl nz, MsaMode_Default
	ld xwa, (xsp + 20)
	cp xwa, 0x4
	jr z, MsaMode_Init_Forward
	cp xwa, 0x3
	jr nz, MsaMode_Init_Forward
	ld xwa, 0x400
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, MsaMode_Init_Forward
	ld xwa, 0x400
	lds bc, 1
	lds de, 3
	call MainLswPut

MsaMode_Init_Forward:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	jrl MsaMode_ReturnZero

MsaMode_Show:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xwa, 0x401
	call MainLswGet
	jrl MsaMode_ReturnZero

MsaMode_Match:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xix, (xsp + 20)
	ld xwa, (xix)
	cp xwa, 0x401
	jrl nz, MsaMode_ReturnZero
	ld xde, (xhl + 48)
	lda xbc, (xhl + 44)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xix + 4)
	ld (xbc), wa
	ld xwa, (xsp + 24)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jr MsaMode_DispatchSelect

MsaMode_Paint:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	ld xbc, 0x1c0000e
	lds32 xde, 0

MsaMode_DispatchSelect:
	call SendEvent
	jrl MsaMode_ReturnZero

MsaMode_Select:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 48)
	lda_24 xbc, NakaInst_Rock_Pop_0x2C
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (xsp + 8)
	call GetEditSwPoint
	lda xwa, (xsp + 12)
	lda xhl, (xsp + 8)
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xb
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xb
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, MsaMode_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr MsaMode_Select_DrawHighlight1

MsaMode_Select_RightSide:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

MsaMode_Select_DrawHighlight1:
	pushw 0xf5
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	lda_24 xbc, NakaInst_Rock_Pop_0x2C
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda xbc, (xsp + 8)
	call GetEditSwPoint
	lda xwa, (xsp + 12)
	lda xhl, (xsp + 8)
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xb
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xb
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, MsaMode_Select_RightSide2
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr MsaMode_Select_DrawHighlight2

MsaMode_Select_RightSide2:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

MsaMode_Select_DrawHighlight2:
	pushw 0xf2
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	jrl MsaMode_ReturnZero

MsaMode_OK:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld xwa, (xsp + 20)
	cp xwa, 0x8b
	jr z, MsaMode_OK_Cmd8B
	cp xwa, 0x8a
	jr z, MsaMode_OK_Cmd8A
	cp xwa, 0x89
	jr z, MsaMode_OK_Cmd89
	cp xwa, 0xf
	jr nz, MsaMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, MsaMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	jr MsaMode_ReturnZero

MsaMode_OK_Cmd89:
	ld xwa, 0x401
	lds bc, 1
	lds de, 1
	jr MsaMode_OK_ModeChange

MsaMode_OK_Cmd8A:
	ld xwa, 0x401
	lds bc, 2
	lds de, 1
	jr MsaMode_OK_ModeChange

MsaMode_OK_Cmd8B:
	ld xwa, 0x401
	lds bc, 3
	lds de, 1

MsaMode_OK_ModeChange:
	call MainLswPut
	jr MsaMode_ReturnZero

MsaMode_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

MsaMode_ReturnZero:
	lds32 xhl, 0
	jr MsaMode_Epilogue

MsaMode_OK_DefaultForward:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	jr MsaMode_CallHandler

MsaMode_Default:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)

MsaMode_CallHandler:
	call InheritedProc

MsaMode_Epilogue:
	pop xiz
	lda xsp, (xsp + 24)
	ret
MsaMode_Boundary:

PmemModeBoxProc:
	stb_dri L, 0xfd, 0xe8, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x14, 0x01
	ld xiz, xbc
	stl_dri XWA, 0xfd, 0x18, 0x01
	cp xiz, 0x1c00007
	jrl z, PmemMode_OK
	cp xiz, 0x1c0000e
	jrl z, PmemMode_Select
	cp xiz, 0x1c0000d
	jrl z, PmemMode_Paint
	cp xiz, 0x1c0001c
	jr z, PmemMode_Match
	cp xiz, 0x1c0000b
	jr z, PmemMode_Show
	cp xiz, 0x1c00001
	jrl nz, PmemMode_Default
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	jrl PmemMode_ReturnZero

PmemMode_Show:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xwa, 0x302
	call MainLswGet
	jrl PmemMode_ReturnZero

PmemMode_Match:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld_sril XIX, (xsp + 0x0114)
	ld xwa, (xix)
	cp xwa, 0x302
	jrl nz, PmemMode_ReturnZero
	ld xde, (xhl + 40)
	lda xbc, (xhl + 36)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld wa, (xix + 4)
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl PmemMode_DispatchSelect

PmemMode_Paint:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	stb_dri W, 0xfd, 0x0c, 0x01
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xf5
	ldw (xwa + 4), 0x13b
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	stb_dri B, 0xfd, 0x0c, 0x01
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	stb_dri C, 0xfd, 0x08, 0x01
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	pushw 0xed
	pushw 0x15d6
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri A, 0xfd, 0x08, 0x01
	lda xde, (xsp + 8)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringCentered
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000e
	lds32 xde, 0

PmemMode_DispatchSelect:
	call SendEvent
	jrl PmemMode_ReturnZero

PmemMode_Select:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 40)
	lda_24 xbc, NakaInst_Rock_Pop_0x30
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri C, 0xfd, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xb
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xb
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmemMode_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr PmemMode_Select_DrawHighlight1

PmemMode_Select_RightSide:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

PmemMode_Select_DrawHighlight1:
	pushw 0xf5
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 36)
	lda_24 xbc, NakaInst_Rock_Pop_0x30
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri C, 0xfd, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xb
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xb
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmemMode_Select_RightSide2
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr PmemMode_Select_DrawHighlight2

PmemMode_Select_RightSide2:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

PmemMode_Select_DrawHighlight2:
	pushw 0xf2
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	jr PmemMode_ReturnZero

PmemMode_OK:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0118)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x0114)
	cp xwa, 0x8b
	jr z, PmemMode_OK_Cmd8B
	cp xwa, 0x89
	jr z, PmemMode_OK_Cmd89
	cp xwa, 0xf
	jr nz, PmemMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmemMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	jr PmemMode_OK_DefaultForward

PmemMode_OK_Cmd89:
	ld xwa, 0x302
	lds bc, 0
	lds de, 1
	jr PmemMode_OK_ModeChange

PmemMode_OK_Cmd8B:
	ld xwa, 0x302
	lds bc, 1
	lds de, 1

PmemMode_OK_ModeChange:
	call MainLswPut

PmemMode_ReturnZero:
	lds32 xhl, 0
	jr PmemMode_Epilogue

PmemMode_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

PmemMode_OK_DefaultForward:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	jr PmemMode_CallHandler

PmemMode_Default:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)

PmemMode_CallHandler:
	call InheritedProc

PmemMode_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x18, 0x01
	ret
PmemMode_Boundary:

AcPmBkEditBoxProc:
	stb_dri L, 0xfd, 0xce, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x2e, 0x01
	stl_dri XWA, 0xfd, 0x32, 0x01
	cp xbc, 0x1c00007
	jrl z, AcPmBkEdit_OK
	cp xbc, 0x1c00018
	jrl z, AcPmBkEdit_AutoIncDown
	cp xbc, 0x1c0001a
	jrl z, AcPmBkEdit_ScrollDown
	cp xbc, 0x1c00017
	jrl z, AcPmBkEdit_ScrollUp
	cp xbc, 0x1c00019
	jrl z, AcPmBkEdit_AutoIncUp
	cp xbc, 0x1c0001d
	jrl z, AcPmBkEdit_Assign
	cp xbc, 0x1c0000c
	jrl z, AcPmBkEdit_ShowHide
	cp xbc, 0x1c0000b
	jrl z, AcPmBkEdit_ShowHide
	cp xbc, 0x1e0003d
	jrl z, AcPmBkEdit_AddDelta
	cp xbc, 0x1e0003b
	jrl z, AcPmBkEdit_SetValue
	lda xwa, (xsp + 46)
	ld (xsp + 8), xwa
	cp xbc, 0x1c20003
	jrl z, AcPmBkEdit_BankEdit
	cp xbc, 0x1c20002
	jr z, AcPmBkEdit_BankChanged
	cp xbc, 0x1e0003a
	jrl nz, AcPmBkEdit_Default
	ld_sril XWA, (xsp + 0x012e)
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xwa, (xhl + 54)
	ld xwa, (xwa)
	ldb w, 0x0
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld_sril XDE, (xsp + 0x012e)
	call MainFuncCall
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankChanged:
	ld_sril XWA, (xsp + 0x012e)
	ld (xsp + 4), xwa
	ld a, (xwa)
	inc 1, a
	extz wa
	pushw wa
	pushw 0xed
	pushw 0x15e0
	ld xwa, (xsp + 14)
	push xwa
	call Sprintf_Locked
	ld_sril XWA, (xsp + 0x0138)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 60)
	push xwa
	call Strcat
	lda xsp, (xsp + 18)
	lda xde, (xsp + 46)
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1c0000f
	call SendEvent
	ldib_erp 0xfb, 1

AcPmBkEdit_BankChanged_UpdateLoop:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	sll a, 3
	addb_erp A, 0xfb
	ldb w, 0x0
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20012
	ld_sril XDE, (xsp + 0x012e)
	call MainFuncCall
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, AcPmBkEdit_BankChanged_UpdateLoop
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankEdit:
	lda xbc, (xsp + 12)
	ldw (xbc), 0x23
	ld_sril XDE, (xsp + 0x012e)
	ld a, (xde)
	dec 1, a
	and a, 0x7
	mul a, 0x11
	add a, 0x5a
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x55
	ldw (xwa + 6), 0xeb
	ldw (xwa), 0x22
	ldw (xwa + 4), 0x12c
	ld a, (xde)
	dec 1, a
	and a, 0x7
	inc 1, a
	extz wa
	pushw wa
	pushw 0xed
	pushw 0x15ea
	ld xwa, (xsp + 14)
	push xwa
	call Sprintf_Locked
	ld_sril XWA, (xsp + 0x0138)
	inc 2, xwa
	push xwa
	lda xwa, (xsp + 60)
	push xwa
	call Strcat
	lda xsp, (xsp + 18)
	lda xhl, (xsp + 46)
	lda xwa, (xsp + 16)
	lda xde, (xsp + 12)
	ld_sril XIX, (xsp + 0x012e)
	ld c, (xix + 1)
	cp c, (xix)
	jr nz, AcPmBkEdit_BankEdit_DrawDiff
	lds32 xbc, 0
	push xbc
	pushw 0x9
	pushw 0xf5
	ld xbc, xde
	ld xde, xhl
	jr AcPmBkEdit_BankEdit_DrawCall

AcPmBkEdit_BankEdit_DrawDiff:
	lds32 xbc, 0
	push xbc
	pushw 0xff
	pushw 0xf5
	ld xbc, xde
	ld xde, xhl

AcPmBkEdit_BankEdit_DrawCall:
	call DrawStringLeftJustify
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_SetValue:
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 10), xhl
	call MainRamPut
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_AddDelta:
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 10), xhl
	call MainRamAdd
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_ShowHide:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 8)
	ld bc, hl
	call MainRamGet
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_Assign:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld_sril XDE, (xsp + 0x012e)
	ld xwa, (xde)
	cp xwa, xhl
	jrl nz, AcPmBkEdit_ReturnZero
	ld xbc, (xiz + 54)
	ld xwa, (xde + 14)
	ld (xbc), xwa
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_AutoIncUp:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollUp:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollDown:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_AutoIncDown:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	ld xde, xhl

AcPmBkEdit_DispatchAndReturn:
	call SendEvent
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_OK:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x012e)
	cp xwa, 0x10
	jrl z, AcPmBkEdit_OK_SaveDelete
	cp xwa, 0x90
	jrl z, AcPmBkEdit_OK_SaveDelete
	cp xwa, 0xa
	jr z, AcPmBkEdit_OK_Load
	cp xwa, 0x9
	jrl nz, AcPmBkEdit_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	jrl AcPmBkEdit_OK_NavComplete

AcPmBkEdit_OK_Load:
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	cps l, 0
	jr z, AcPmBkEdit_OK_LoadEmpty
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d2
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1
	call PostEvent
	jr AcPmBkEdit_ReturnZero

AcPmBkEdit_OK_LoadEmpty:
	stdi8 0x7f42, 73
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000ee
	call ApPostEvent
	jr AcPmBkEdit_ReturnZero

AcPmBkEdit_OK_SaveDelete:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d0
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	jr z, AcPmBkEdit_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	lds32 xde, 1

AcPmBkEdit_OK_NavComplete:
	call PostEvent

AcPmBkEdit_ReturnZero:
	lds32 xhl, 0
	jr AcPmBkEdit_Epilogue

AcPmBkEdit_Default:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc

AcPmBkEdit_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x32, 0x01
	ret

PmBkNameFunc:
	ld xhl, xwa
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jr lt, PmBkName_ReturnZero
	cp xbc, 0x9
	jr gt, PmBkName_ReturnZero
	add xbc, xbc
	add xbc, FadeTimeStr_Off_0xA4
	ld bc, (xbc)
	lda_24 xix, PmBkName_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4
; PmBkNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ee)
PmBkName_EventDispatch:
	ret
	lds32	xhl, 1
	ret
	ld	xhl, 9
	ret

PmBkName_ReturnZero:
	lds32 xhl, 0
	ret

PmBkName_DataBytes:
	lda_d16	xhl, 0x8d48
	ret

GmOnOffFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1e00083
	jr z, GmOnOff_GetBoundsRect
	cp xbc, 0x1e0003f
	jrl z, GmOnOff_DefaultReturn
	cp xbc, 0x1e0003e
	jr z, GmOnOff_Return1
	cp xbc, 0x1e00041
	jr z, GmOnOff_Return1
	cp xbc, 0x1e00040
	jr z, GmOnOff_Return0xC0
	cp xbc, 0x1e00042
	jrl nz, GmOnOff_DefaultReturn
	pushm (xde + 4)
	pushw 0xed
	pushw 0x1602
	ld xwa, (xde + 8)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jrl VariScreen_CleanupRet

GmOnOff_Return0xC0:
	ld xhl, 0xc0
	jrl VariScreen_CleanupRet

GmOnOff_Return1:
	lds32 xhl, 1
	jrl VariScreen_CleanupRet

GmOnOff_GetBoundsRect:
	lda xix, (xsp + 4)
	ldw (xix), 0x10
	lda xhl, (xix + 2)
	ldw (xhl), 0x5f
	lda xwa, (xsp + 8)
	ld bc, (xix)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xix)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xhl)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 6), bc
	cp xde, 0x1
	jr nz, GmOnOff_CheckDesign
	ldw bc, 0xc4
	ldw de, 0xf0
	call DrawDesignBox
	lda xwa, (xsp + 4)
	ld xbc, 0x20
	call DrawIcons
	ld xwa, 0xffffffff
	ld xbc, 0x1c20006
	lds32 xde, 3
	jr GmOnOff_SendAndReturn

GmOnOff_CheckDesign:
	ldb_d8 c, 0x8d40
	orda8 c, 0x8d42
	orda8 c, 0x8d44
	jr nz, GmOnOff_SendHideEvent
	ldw bc, 0xf5
	call DrawBox

GmOnOff_SendHideEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c20006
	lds32 xde, 1

GmOnOff_SendAndReturn:
	call SendEvent

GmOnOff_DefaultReturn:
	lds32 xhl, 0

VariScreen_CleanupRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret
GmOnOff_Boundary:

VariScreenProc:
	stb_dri L, 0xfd, 0xca, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x2e, 0x02
	stl_dri XBC, 0xfd, 0x32, 0x02
	stl_dri XWA, 0xfd, 0x36, 0x02
	ld_sril XWA, (xsp + 0x0232)
	cp xwa, 0x1c00007
	jrl z, VariScreen_HandleOK
	cp xwa, 0x1e20005
	jrl z, VariScreen_HandleEnumNotify
	cp xwa, 0x1c0000f
	jrl z, VariScreen_HandleConfirm
	cp xwa, 0x1c0000e
	jrl z, VariScreen_HandleSelect
	cp xwa, 0x1c0000d
	jrl z, VariScreen_HandlePaint
	cp xwa, 0x1c0000b
	jr z, VariScreen_HandleShow
	cp xwa, 0x1c20007
	jr z, VariScreen_RefreshAfterInit
	cp xwa, 0x1c00001
	jrl nz, VariScreen_DefaultHandler
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	jrl VariScreen_CallInherited

VariScreen_RefreshAfterInit:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl VariScreen_SendAndReturn

VariScreen_HandleShow:
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	ld xwa, (xsp + 24)
	ld (xsp + 4), xwa
	ldb_d8 a, 0x8d3a
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 31), l
	ldb_d8 a, 0x8d3a
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 28)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8d3a
	call SndParam_FetchOscTableEntry
	ld xhl, (xsp + 24)
	ld xde, (xhl + 56)
	lda xbc, (xsp + 28)
	ld a, (xbc)
	extz wa
	ld (xde), wa
	ld xde, (xhl + 60)
	ld a, (xbc + 1)
	extz wa
	ld (xde), wa
	ld a, (xbc)
	extz wa
	call CharMap_ActivePreamb_Prologue2
	ld xde, (xsp + 24)
	ld xbc, (xde + 52)
	extz hl
	ld (xbc), hl
	ld xbc, (xde + 48)
	ld a, (xsp + 30)
	extz wa
	ld (xbc), wa
	ld xbc, (xde + 44)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)

VariScreen_CallInherited:
	call InheritedProc
	jrl FileBrowser_ReturnZero

VariScreen_HandlePaint:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	stb_dri C, 0xfd, 0x22, 0x02
	ldw (xhl), 0x4
	lda xde, (xhl + 2)
	ldw (xde), 0x2
	stb_dri W, 0xfd, 0x26, 0x02
	ld bc, (xhl)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xde)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x19
	ld (xwa + 6), bc
	ldw bc, 0xc0
	ldw de, 0xf0
	call DrawDesignBox
	stb_dri W, 0xfd, 0x22, 0x02
	ld xbc, 0x8c
	call DrawIcons
	stb_dri A, 0xfd, 0x22, 0x02
	ldw (xbc), 0x23
	lda xhl, (xbc + 2)
	ldw (xhl), 0x8
	stb_dri W, 0xfd, 0x26, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x64
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x32
	ld (xwa + 6), de
	lds32 xde, 4
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, FadeTimeStr_Off_0xBA
	call DrawString
	ldb_d8 a, 0x8d3a
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 31), l
	ldb_d8 a, 0x8d3a
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 28)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8d3a
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 28)
	extz wa
	stb_dri A, 0xfd, 0x22, 0x01
	call StoreDRAMInit_LoadDRAM
	stb_dri A, 0xfd, 0x22, 0x02
	ldw (xbc), 0x68
	lda xhl, (xbc + 2)
	ldw (xhl), 0xc
	stb_dri W, 0xfd, 0x26, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x80
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0xf
	ld (xwa + 6), de
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xhl, 0
	push xhl
	pushw 0xfb
	pushw 0xf7
	call DrawString
	stb_dri A, 0xfd, 0x22, 0x02
	ldw (xbc), 0x90
	lda xhl, (xbc + 2)
	ldw (xhl), 0x0
	stb_dri W, 0xfd, 0x26, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x38
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0xf
	ld (xwa + 6), de
	ld xde, (xsp + 24)
	ld xde, (xde + 48)
	ld de, (xde)
	muls de, 0x7
	lda_24 xhl, NakaInst_MEMORY_A_ECFDF4_0xA
	exts xde
	add xde, xhl
	lds32 xhl, 0
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawString
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0

VariScreen_SendAndReturn:
	call SendEvent
	jrl FileBrowser_ReturnZero

VariScreen_HandleSelect:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	ld xwa, (xsp + 24)
	ld (xsp + 4), xwa
	ld (xsp + 8), 0x9
	lda xde, (xwa + 52)
	ld xhl, (xde)
	lda xbc, (xwa + 44)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld hl, (xhl)
	sub hl, wa
	jr ge, VariScreen_CalcRowOffset
	ld xde, (xde)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_CalcRowOffset:
	ld xde, (xbc)
	ld xwa, (xsp + 24)
	ld xbc, (xwa + 64)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xde)
	jrl nz, VariScreen_DrawRightPanel
	ld e, (xsp + 8)
	srl e, 1
	extz de
	sla de, 2
	lda_24 xhl, 0x03f214
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightBounds
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr VariScreen_DrawDesignArea

VariScreen_SetRightBounds:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

VariScreen_DrawDesignArea:
	lds bc, 0
	ldw de, 0xf5
	call DrawDesignBox
	lda xwa, (xsp + 28)
	ld xhl, (xsp + 24)
	ld xbc, (xhl + 56)
	ld bc, (xbc)
	ld (xwa), c
	lda xde, (xhl + 64)
	ld xbc, (xde)
	ld bc, (xbc)
	ld (xwa + 1), c
	ld xbc, (xhl + 48)
	ld bc, (xbc)
	ld (xwa + 2), c
	ld xbc, (xde)
	ld bc, (xbc)
	extz bc
	div c, 0xa
	ld c, b
	ld (xwa + 3), c
	call SndParam_ApplyProgramChange
	lda xbc, (xsp + 28)
	ld a, (xbc + 3)
	extz wa
	ld c, (xbc + 4)
	extz bc
	stb_dri B, 0xfd, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_ind 0xfd, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 24)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xa
	ld wa, bc
	dec 1, wa
	ld ix, (xde)
	sub ix, wa
	jr ge, VariScreen_SetHighlightColors
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_SetHighlightColors:
	ld (xsp + 12), 0xff
	ld (xsp + 14), 0xf5
	ld xix, (xsp + 24)
	ld xde, (xix + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_DrawEditSwitch
	sub bc, 0xa
	ld xwa, (xix + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld a, w
	extz wa
	add wa, bc
	cp (xde), wa
	jr nz, VariScreen_DrawEditSwitch
	ld (xsp + 12), 0x0
	ld (xsp + 14), 0x7

VariScreen_DrawEditSwitch:
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawDefaultVoice

VariScreen_DrawNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightNameBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1e
	jr VariScreen_DrawNameString

VariScreen_SetRightNameBounds:
	ldw (xde), 0xa3
	ldw (xwa), 0xbe

VariScreen_DrawNameString:
	decm 8, (xbc)
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xed
	pushw 0x160a
	lda xwa, (xsp + 40)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	stb_dri C, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
	lda xde, (xsp + 34)
	lds32 xwa, 3
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	stb_dri A, 0xfd, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	add wa, 0xc
	ld (xde), wa
	stb_dri C, 0xfd, 0x26, 0x02
	sub wa, 0xf
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightVoiceBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9c
	jr VariScreen_DrawVoiceString

VariScreen_SetRightVoiceBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xwa, 1
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xhl
	jr VariScreen_CallDrawLeftJustify

VariScreen_DrawDefaultVoice:
	stb_dri C, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	sub wa, 0xf
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetDefVoiceRightBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9c
	jr VariScreen_DrawDefVoiceString

VariScreen_SetDefVoiceRightBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawDefVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xwa, 1
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xhl

VariScreen_CallDrawLeftJustify:
	call DrawStringLeftJustify

VariScreen_DrawRightPanel:
	ld xwa, (xsp + 24)
	ld xde, (xwa + 44)
	ld xbc, (xwa + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xde)
	jrl nz, FileBrowser_ReturnZero
	ld e, (xsp + 8)
	srl e, 1
	extz de
	sla de, 2
	lda_24 xhl, 0x03f214
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightPanelRightBounds
	ldw (xwa), 0x8
	ldw (xbc), 0x9c
	jr VariScreen_DrawRightDesignBox

VariScreen_SetRightPanelRightBounds:
	ldw (xwa), 0xa3
	ldw (xbc), 0x137

VariScreen_DrawRightDesignBox:
	ldw bc, 0xc1
	lds de, 7
	call DrawDesignBox
	lda xwa, (xsp + 28)
	ld xhl, (xsp + 24)
	ld xbc, (xhl + 56)
	ld bc, (xbc)
	ld (xwa), c
	lda xde, (xhl + 60)
	ld xbc, (xde)
	ld bc, (xbc)
	ld (xwa + 1), c
	ld xbc, (xhl + 48)
	ld bc, (xbc)
	ld (xwa + 2), c
	ld xbc, (xde)
	ld bc, (xbc)
	extz bc
	div c, 0xa
	ld c, b
	ld (xwa + 3), c
	call SndParam_ApplyProgramChange
	lda xbc, (xsp + 28)
	ld a, (xbc + 3)
	extz wa
	ld c, (xbc + 4)
	extz bc
	stb_dri B, 0xfd, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_ind 0xfd, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 24)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xa
	ld wa, bc
	dec 1, wa
	ld ix, (xde)
	sub ix, wa
	jr ge, VariScreen_SetRightHighlightColors
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_SetRightHighlightColors:
	ld (xsp + 12), 0xff
	ld (xsp + 14), 0xf5
	ld xwa, (xsp + 24)
	ld xde, (xwa + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_DrawRightEditSw
	ld hl, bc
	sub hl, 0xa
	ld bc, (xde)
	ld a, c
	extz wa
	div a, 0xa
	ld a, w
	extz wa
	add wa, hl
	cp bc, wa
	jr nz, VariScreen_DrawRightEditSw
	ld (xsp + 12), 0x0
	ld (xsp + 14), 0x7

VariScreen_DrawRightEditSw:
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xhl, 0x03f214
	ld wa, (xde)
	extz wa
	div a, 0xa
	ld e, w
	extz de
	ld_sril3 XWA, 0x07, 0xec, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xe8
	extz wa
	call DrawEditSw
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawRightNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawRightDefaultVoice

VariScreen_DrawRightNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightNameRightBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1e
	jr VariScreen_DrawRightNameString

VariScreen_SetRightNameRightBounds:
	ldw (xde), 0xa3
	ldw (xwa), 0xbe

VariScreen_DrawRightNameString:
	decm 8, (xbc)
	ld xde, (xsp + 24)
	ld xwa, (xde + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xde + 60)
	ld wa, (xwa)
	extz wa
	div a, 0xa
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xed
	pushw 0x160e
	lda xwa, (xsp + 40)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	stb_dri C, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
	lda xde, (xsp + 34)
	lds32 xwa, 3
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	stb_dri A, 0xfd, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	add wa, 0xc
	ld (xde), wa
	stb_dri C, 0xfd, 0x26, 0x02
	sub wa, 0xf
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightVoiceRightBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9c
	jr VariScreen_DrawRightVoiceString

VariScreen_SetRightVoiceRightBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawRightVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xwa, 1
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xhl
	jrl FileBrowser_DrawString

VariScreen_DrawRightDefaultVoice:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
	lda xhl, (xbc + 2)
	ld wa, (xhl)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xhl)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightDefVoiceRightBounds
	ldw (xde), 0x10
	ldw (xwa), 0x9c
	jr VariScreen_DrawRightDefVoiceString

VariScreen_SetRightDefVoiceRightBounds:
	ldw (xde), 0xab
	ldw (xwa), 0x137

VariScreen_DrawRightDefVoiceString:
	stb_dri C, 0xfd, 0x22, 0x01
	lds32 xwa, 1
	push xwa
	ld a, (xsp + 16)
	extz wa
	pushw wa
	ld a, (xsp + 20)
	extz wa
	pushw wa
	ld xwa, xde
	ld xde, xhl
	jrl FileBrowser_DrawString

VariScreen_HandleConfirm:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 16), xhl
	ld xwa, (xsp + 16)
	ld (xsp + 4), xwa
	stb_dri W, 0xfd, 0x26, 0x02
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xf5
	ldw (xwa + 4), 0x13b
	ldw bc, 0xc1
	ldw de, 0xf3
	call DrawDesignBox
	stb_dri B, 0xfd, 0x26, 0x02
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	stb_dri C, 0xfd, 0x22, 0x02
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	pushw wa
	ld xwa, (xbc + 44)
	pushm (xwa)
	pushw 0xed
	pushw 0x1612
	stb_dri W, 0xfd, 0x2a, 0x01
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringCentered
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 52)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld de, (xbc)
	sub de, wa
	jr ge, VariScreen_ConfirmRowReady
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 8), c

VariScreen_ConfirmRowReady:
	ld (xsp + 10), 0x0
	cp (xsp + 8), 0x0
	jrl c, FileBrowser_ReturnZero

VariScreen_ConfirmLoopBody:
	lda xwa, (xsp + 28)
	ld xde, (xsp + 16)
	ld xbc, (xde + 56)
	ld bc, (xbc)
	ld (xwa), c
	ld xbc, (xde + 44)
	ld bc, (xbc)
	dec 1, bc
	mul c, 0xa
	add c, (xsp + 10)
	ld (xwa + 1), c
	ld xbc, (xde + 48)
	ld bc, (xbc)
	ld (xwa + 2), c
	call SndParam_ApplyProgramChange
	lda xbc, (xsp + 28)
	ld a, (xbc + 3)
	extz wa
	ld c, (xbc + 4)
	extz bc
	stb_dri B, 0xfd, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_ind 0xfd, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 16)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xa
	ld wa, bc
	dec 1, wa
	ld ix, (xde)
	sub ix, wa
	jr ge, VariScreen_ConfirmHighlightColors
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_ConfirmHighlightColors:
	ld (xsp + 12), 0xff
	ld (xsp + 14), 0xf5
	ld xwa, (xsp + 16)
	ld xde, (xwa + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_ConfirmDrawEditSw
	sub bc, 0xa
	ld a, (xsp + 10)
	extz wa
	add wa, bc
	cp (xde), wa
	jr nz, VariScreen_ConfirmDrawEditSw
	ld (xsp + 12), 0x0
	ld (xsp + 14), 0x7

VariScreen_ConfirmDrawEditSw:
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld l, (xsp + 10)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld l, (xsp + 10)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 16)
	ld xiz, (xwa + 56)
	stb_dri E, 0xfd, 0x26, 0x02
	stb_dri D, 0xfd, 0x22, 0x02
	lda xbc, (xix + 2)
	lda xde, (xiy + 2)
	lda xwa, (xiy + 4)
	ld (xsp + 24), xwa
	lda xhl, (xiy + 6)
	cpw (xiz), 0x10
	jr z, VariScreen_ConfirmDrawNameLabel
	cpw (xiz), 0x11
	jrl nz, VariScreen_ConfirmDrawDefaultVoice

VariScreen_ConfirmDrawNameLabel:
	ld xiz, xiy
	ld xiy, xbc
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xhl), wa
	ld xwa, (xsp + 24)
	cpw (xix), 0x0
	jr nz, VariScreen_ConfirmSetNameRightBounds
	ldw (xiz), 0x8
	ldw (xwa), 0x1e
	jr VariScreen_ConfirmDrawNameAudio

VariScreen_ConfirmSetNameRightBounds:
	ldw (xiz), 0xa3
	ldw (xwa), 0xbe

VariScreen_ConfirmDrawNameAudio:
	decm 8, (xiy)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld a, (xsp + 10)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xed
	pushw 0x161e
	lda xwa, (xsp + 40)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri B, 0xfd, 0x22, 0x02
	lda xhl, (xsp + 34)
	lds32 xbc, 3
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xhl
	call DrawStringLeftJustify
	stb_dri B, 0xfd, 0x22, 0x02
	lda xbc, (xde + 2)
	ld hl, (xbc)
	add hl, 0xc
	ld (xbc), hl
	stb_dri W, 0xfd, 0x26, 0x02
	sub hl, 0xf
	ld (xwa + 2), hl
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, VariScreen_ConfirmSetVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9c
	jr VariScreen_ConfirmDrawVoiceString

VariScreen_ConfirmSetVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_ConfirmDrawVoiceString:
	stb_dri C, 0xfd, 0x22, 0x01
	lds32 xbc, 1
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xhl
	jr VariScreen_ConfirmDrawStringAndLoop

VariScreen_ConfirmDrawDefaultVoice:
	ld xwa, xiy
	ld (xsp + 20), xix
	ld iy, (xbc)
	sub iy, 0xf
	ld (xde), iy
	ld bc, (xbc)
	add bc, 0x10
	ld (xhl), bc
	ld xbc, (xsp + 24)
	cpw (xix), 0x0
	jr nz, VariScreen_ConfirmSetDefVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9c
	jr VariScreen_ConfirmDrawDefVoiceString

VariScreen_ConfirmSetDefVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_ConfirmDrawDefVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
	lds32 xbc, 1
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, (xsp + 28)

VariScreen_ConfirmDrawStringAndLoop:
	call DrawStringLeftJustify
	incm8 1, (xsp + 10)
	ld a, (xsp + 10)
	cp a, (xsp + 8)
	jrl ule, VariScreen_ConfirmLoopBody
	jrl FileBrowser_ReturnZero

VariScreen_HandleEnumNotify:
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	ld_sril XWA, (xsp + 0x022e)
	ld (xsp + 20), xwa
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 24)
	lda xde, (xwa + 52)
	ld xhl, (xde)
	lda xbc, (xwa + 44)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld hl, (xhl)
	sub hl, wa
	jr ge, VariScreen_EnumRowReady
	ld xde, (xde)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_EnumRowReady:
	ld (xsp + 12), 0xff
	ld (xsp + 14), 0xf5
	ld xde, (xbc)
	ld xwa, (xsp + 24)
	ld xbc, (xwa + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, (xde)
	jr nz, VariScreen_EnumHighlightColors
	ld de, (xde)
	muls de, 0xa
	sub de, 0xa
	ld_sril XWA, (xsp + 0x022e)
	ld a, (xwa)
	extz wa
	add wa, de
	cp (xbc), wa
	jr nz, VariScreen_EnumHighlightColors
	ld (xsp + 12), 0x0
	ld (xsp + 14), 0x7

VariScreen_EnumHighlightColors:
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld_sril XWA, (xsp + 0x022e)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	call DrawEditSw
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld_sril XWA, (xsp + 0x022e)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_EnumDrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_EnumDrawDefaultVoice

VariScreen_EnumDrawNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_EnumSetNameRightBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1e
	jr VariScreen_EnumDrawNameAudio

VariScreen_EnumSetNameRightBounds:
	ldw (xde), 0xa3
	ldw (xwa), 0xbe

VariScreen_EnumDrawNameAudio:
	decm 8, (xbc)
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xa
	sub bc, 0xa
	ld xwa, (xsp + 20)
	ld a, (xwa)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xed
	pushw 0x1622
	lda xwa, (xsp + 40)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 10)
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri B, 0xfd, 0x22, 0x02
	lda xhl, (xsp + 34)
	lds32 xbc, 3
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xhl
	call DrawStringLeftJustify
	stb_dri C, 0xfd, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld de, (xbc)
	add de, 0xc
	ld (xbc), de
	stb_dri W, 0xfd, 0x26, 0x02
	sub de, 0xf
	ld (xwa + 2), de
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_EnumSetVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9c
	jr VariScreen_EnumDrawVoiceString

VariScreen_EnumSetVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_EnumDrawVoiceString:
	ld_sril XBC, (xsp + 0x022e)
	lda xde, (xbc + 1)
	lds32 xbc, 1
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, xhl
	jr FileBrowser_DrawString

VariScreen_EnumDrawDefaultVoice:
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri B, 0xfd, 0x22, 0x02
	lda xhl, (xde + 2)
	ld bc, (xhl)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xhl)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, VariScreen_EnumSetDefVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9c
	jr VariScreen_EnumDrawDefVoiceString

VariScreen_EnumSetDefVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_EnumDrawDefVoiceString:
	ld_sril XBC, (xsp + 0x022e)
	lda xhl, (xbc + 1)
	lds32 xbc, 1
	push xbc
	ld c, (xsp + 16)
	extz bc
	pushw bc
	ld c, (xsp + 20)
	extz bc
	pushw bc
	ld xbc, xde
	ld xde, xhl

FileBrowser_DrawString:
	call DrawStringLeftJustify
	jrl FileBrowser_ReturnZero

VariScreen_HandleOK:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 16), xhl
	ld xde, (xsp + 16)
	ld (xsp + 4), xde
	ld (xsp + 8), 0x9
	lda xwa, (xde + 52)
	ld (xsp + 20), xwa
	ld xbc, (xwa)
	lda xwa, (xde + 44)
	ld (xsp + 24), xwa
	ld xwa, (xwa)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, VariScreen_OK_Dispatch
	ld xwa, (xsp + 20)
	ld xbc, (xwa)
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 8), c

VariScreen_OK_Dispatch:
	ld_sril XBC, (xsp + 0x022e)
	cp xbc, 0xc
	jrl z, VariScreen_OK_CalcRow4
	cp xbc, 0xb
	jrl z, VariScreen_OK_CalcRow3
	cp xbc, 0xa
	jrl z, VariScreen_OK_CalcRow2
	cp xbc, 0x9
	jrl z, VariScreen_OK_CalcRow1
	ld a, (xsp + 8)
	extz wa
	cp xbc, 0x8
	jrl z, VariScreen_OK_CalcRow0
	cp xbc, 0x8c
	jrl z, VariScreen_OK_HalfRange4
	cp xbc, 0x8b
	jrl z, VariScreen_OK_HalfRange3
	cp xbc, 0x8a
	jrl z, VariScreen_OK_HalfRange2
	cp xbc, 0x89
	jr z, VariScreen_OK_HalfRange1
	cp xbc, 0x88
	jrl nz, VariScreen_OK_PageScroll
	lds bc, 0
	calr VariScreen_IsHalfRangeAbove
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xde, (xwa + 64)
	ld xhl, (xsp + 4)
	lda xbc, (xhl + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xhl + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange1:
	lds bc, 1
	calr VariScreen_IsHalfRangeAbove
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xhl, (xsp + 16)
	ld xde, (xhl + 64)
	lda xbc, (xhl + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xhl + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0x9
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange2:
	lds bc, 2
	calr VariScreen_IsHalfRangeAbove
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xhl, (xsp + 16)
	ld xde, (xhl + 64)
	lda xbc, (xhl + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xhl + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 8, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange3:
	lds bc, 3
	calr VariScreen_IsHalfRangeAbove
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xhl, (xsp + 16)
	ld xde, (xhl + 64)
	lda xbc, (xhl + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xhl + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 7, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange4:
	lds bc, 4
	calr VariScreen_IsHalfRangeAbove
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xhl, (xsp + 16)
	ld xde, (xhl + 64)
	lda xbc, (xhl + 60)
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), wa
	ld xbc, (xbc)
	ld xwa, (xhl + 44)
	ld wa, (xwa)
	muls wa, 0xa
	dec 6, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow0:
	lds bc, 0
	calr VariScreen_CalcValidNoteRow
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	lds bc, 0
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow1:
	ld a, (xsp + 8)
	extz wa
	lds bc, 1
	calr VariScreen_CalcValidNoteRow
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	lds bc, 1
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow2:
	ld a, (xsp + 8)
	extz wa
	lds bc, 2
	calr VariScreen_CalcValidNoteRow
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	lds bc, 2
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow3:
	ld a, (xsp + 8)
	extz wa
	lds bc, 3
	calr VariScreen_CalcValidNoteRow
	cps l, 0
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	lds bc, 3
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	jr RVari_NotifyAndReturn

VariScreen_OK_CalcRow4:
	ld a, (xsp + 8)
	extz wa
	lds bc, 4
	calr VariScreen_CalcValidNoteRow
	cps l, 0
	jr z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	lds bc, 4
	calr VariScreen_CalcValidNoteRow
	extz hl
	ld xbc, (xsp + 16)
	ld xwa, (xbc + 44)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)

RVari_NotifyAndReturn:
	calr RVari_UpdateDisplayNotify

FileBrowser_ReturnZero:
	lds32 xhl, 0
	jrl VariScreen_Epilogue

VariScreen_OK_PageScroll:
	ld_sril XWA, (xsp + 0x022e)
	cp xwa, 0x10
	jr nz, VariScreen_OK_PageScrollDown
	ld xwa, (xsp + 24)
	ld xbc, (xwa)
	ld xwa, (xsp + 20)
	ld xwa, (xwa)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp (xbc), wa
	jr ge, VariScreen_OK_PageScrollWrap
	incm 1, (xbc)
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jr VariScreen_OK_PageSendEvent

VariScreen_OK_PageScrollWrap:
	cps wa, 1
	jr le, VariScreen_OK_PageScrollDown
	ldw (xbc), 0x1
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	lds32 xde, 0

VariScreen_OK_PageSendEvent:
	call SendEvent

VariScreen_OK_PageScrollDown:
	ld_sril XWA, (xsp + 0x022e)
	cp xwa, 0x90
	jr nz, VariScreen_OK_ForwardToInherited
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 44)
	cpw (xbc), 0x1
	jr le, VariScreen_OK_PageScrollDownWrap
	decm 1, (xbc)
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jr VariScreen_OK_PageDownSendEvent

VariScreen_OK_PageScrollDownWrap:
	ld xwa, (xsp + 16)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cps wa, 1
	jr le, VariScreen_OK_ForwardToInherited
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	lds32 xde, 0

VariScreen_OK_PageDownSendEvent:
	call SendEvent

VariScreen_OK_ForwardToInherited:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)
	jr VariScreen_CallInheritedAndReturn

VariScreen_DefaultHandler:
	ld_sril XWA, (xsp + 0x0236)
	ld_sril XBC, (xsp + 0x0232)
	ld_sril XDE, (xsp + 0x022e)

VariScreen_CallInheritedAndReturn:
	call InheritedProc

VariScreen_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x36, 0x02
	ret

VariScreen_CalcValidNoteRow:
	ld e, a
	srl e, 1
	add e, c
	ld c, e
	inc 1, c
	cp a, c
	jr c, CalcValidNoteRow_Invalid
	inc 1, e
	ld l, e
	ret

CalcValidNoteRow_Invalid:
	ldb l, 0x0
	ret

VariScreen_IsHalfRangeAbove:
	srl a, 1
	cp a, c
	scc8 nc, l
	ret
IsHalfRangeAbove_End:

RVariScreenProc:
	stb_dri L, 0xfd, 0xd8, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x20, 0x02
	stl_dri XBC, 0xfd, 0x24, 0x02
	stl_dri XWA, 0xfd, 0x28, 0x02
	ld_sril XBC, (xsp + 0x0224)
	cp xbc, 0x1c00007
	jrl z, RVari_OK
	cp xbc, 0x1e2000b
	jrl z, RVari_EnumNotify
	cp xbc, 0x1c0000f
	jrl z, RVari_Confirm
	cp xbc, 0x1c0000e
	jrl z, RVari_Select
	cp xbc, 0x1c0000d
	jrl z, RVari_Paint
	cp xbc, 0x1c0000b
	jrl z, RVari_Show
	cp xbc, 0x1c00001
	jrl nz, RVari_Default
	ld_sril XWA, (xsp + 0x0228)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 17), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 14)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	ld xbc, (xiz + 56)
	lda xde, (xsp + 14)
	ld a, (xde)
	extz wa
	ld (xbc), wa
	ld xhl, (xiz + 60)
	lda xbc, (xde + 1)
	ld a, (xbc)
	extz wa
	ld (xhl), wa
	ld xhl, (xiz + 64)
	ld a, (xbc)
	extz wa
	ld (xhl), wa
	ld a, (xde)
	extz wa
	call AccVoice_GetChannelCount_Wrap
	ld xbc, (xiz + 52)
	extz hl
	ld (xbc), hl
	ld xwa, (xiz + 48)
	ldw (xwa), 0x48
	ld xwa, (xiz + 56)
	cpw (xwa), 0xe
	jr nz, RVari_Init_TypeNotE
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x28
	inc 1, wa
	ld (xbc), wa
	jr RVari_Init_ForwardEvent

RVari_Init_TypeNotE:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	ld (xbc), wa

RVari_Init_ForwardEvent:
	ld_sril XWA, (xsp + 0x0228)
	ld_sril XBC, (xsp + 0x0224)
	ld_sril XDE, (xsp + 0x0220)
	call InheritedProc
	lds32 xhl, 0
	jrl RVari_Epilogue

RVari_Show:
	ld_sril XWA, (xsp + 0x0228)
	ld_sril XBC, (xsp + 0x0224)
	ld_sril XDE, (xsp + 0x0220)
	call InheritedProc
	lds32 xhl, 0
	jrl RVari_Epilogue

RVari_Paint:
	ld_sril XWA, (xsp + 0x0228)
	ld_sril XBC, (xsp + 0x0224)
	ld_sril XDE, (xsp + 0x0220)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0228)
	call GetViewInstance
	stb_dri C, 0xfd, 0x14, 0x02
	ldw (xhl), 0x4
	lda xde, (xhl + 2)
	ldw (xde), 0x2
	stb_dri W, 0xfd, 0x18, 0x02
	ld bc, (xhl)
	dec 2, bc
	ld (xwa), bc
	ld bc, (xhl)
	add bc, 0x19
	ld (xwa + 4), bc
	ld bc, (xde)
	dec 2, bc
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x19
	ld (xwa + 6), bc
	ldw bc, 0xc0
	ldw de, 0xf0
	call DrawDesignBox
	stb_dri W, 0xfd, 0x14, 0x02
	ld xbc, 0x90
	call DrawIcons
	stb_dri A, 0xfd, 0x14, 0x02
	ldw (xbc), 0x23
	lda xhl, (xbc + 2)
	ldw (xhl), 0x8
	stb_dri W, 0xfd, 0x18, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x64
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x32
	ld (xwa + 6), de
	lds32 xde, 4
	push xde
	pushw 0xff
	pushw 0xf7
	ld xde, VariationStr_V1_0x4
	call DrawString
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ld (xsp + 17), l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	lda xwa, (xsp + 14)
	ld (xwa + 4), l
	ld (xwa + 2), 0x48
	call SndParam_ResolveVoiceEntry
	ld a, (xsp + 14)
	extz wa
	call AccVoice_CopyFromROM_Wrap
	extz xhl
	pushw 0x10
	push xhl
	stb_dri W, 0xfd, 0x1a, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stb_dri B, 0xfd, 0x14, 0x01
	ld (xde + 16), 0x0
	stb_dri A, 0xfd, 0x14, 0x02
	ldw (xbc), 0x6b
	lda xix, (xbc + 2)
	ldw (xix), 0x0
	stb_dri W, 0xfd, 0x18, 0x02
	ld hl, (xbc)
	ld (xwa), hl
	ld hl, (xbc)
	add hl, 0x80
	ld (xwa + 4), hl
	ld hl, (xix)
	ld (xwa + 2), hl
	ld hl, (xix)
	add hl, 0xf
	ld (xwa + 6), hl
	lds32 xhl, 0
	push xhl
	pushw 0xfb
	pushw 0xf7
	call DrawString
	ld_sril XWA, (xsp + 0x0228)
	ld xbc, 0x1c0000f
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0228)
	ld xbc, 0x1c0000e
	lds32 xde, 0
	call SendEvent
	lds32 xhl, 0
	jrl RVari_Epilogue

RVari_Select:
	ld_sril XWA, (xsp + 0x0228)
	ld_sril XBC, (xsp + 0x0224)
	ld_sril XDE, (xsp + 0x0220)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0228)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xhl + 56)
	cpw (xwa), 0xf
	jrl nz, RVari_Select_CalcVisibleCount
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137
	lds bc, 0
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 64)
	ld bc, (xbc)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	stb_dri W, 0xfd, 0x1a, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x21, 0x01, 0x00
	ld (xsp + 10), 0xff
	ld (xsp + 12), 0xf5
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp BC, 0xe2
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	cp wa, bc
	jr nz, RVari_Select_CheckSameBank
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_Select_CheckSameBank:
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri B, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xa3
	ldw (xde + 4), 0xbe
	decm 8, (xbc)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	sla wa, 2
	lda_24 xbc, ParamStr_Table_04
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x164e
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	stb_dri C, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xde, (xsp + 20)
	lds32 xwa, 3
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xhl
	call DrawStringLeftJustify
	stb_dri C, 0xfd, 0x14, 0x02
	lda xde, (xhl + 2)
	ld wa, (xde)
	add wa, 0xc
	ld (xde), wa
	stb_dri A, 0xfd, 0x18, 0x02
	sub wa, 0xf
	ld (xbc + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xbc + 6), wa
	ldw (xbc), 0xb7
	ldw (xbc + 4), 0x14b
	stb_dri B, 0xfd, 0x14, 0x01
	lds32 xwa, 1
	push xwa
	ld a, (xsp + 14)
	extz wa
	pushw wa
	ld a, (xsp + 18)
	extz wa
	pushw wa
	ld xwa, xbc
	ld xbc, xhl
	call DrawStringLeftJustify
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137
	ldw bc, 0xc1
	lds de, 7
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 60)
	ld bc, (xbc)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xd
	push xhl
	stb_dri W, 0xfd, 0x1a, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x21, 0x01, 0x00
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, NakaInst_Rock_Pop_0x24
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri B, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xa3
	ldw (xde + 4), 0xbe
	decm 8, (xbc)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	sla wa, 2
	lda_24 xbc, ParamStr_Table_04
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1652
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xde, (xsp + 20)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	add de, 0xc
	ld (xhl), de
	stb_dri W, 0xfd, 0x18, 0x02
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b
	stb_dri B, 0xfd, 0x14, 0x01
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, NakaInst_Rock_Pop_0x28
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	lds bc, 0
	ldw de, 0xf5
	call DrawDesignBox
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2d
	ldw (xwa + 4), 0xac
	ld xde, (xiz + 64)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, SeqChan_Map_2ch_0x2
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 1
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawStringLeftJustify
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, NakaInst_Rock_Pop_0x28
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	ldw bc, 0xc1
	lds de, 7
	call DrawDesignBox
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2d
	ldw (xwa + 4), 0xac
	ld xde, (xiz + 60)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, SeqChan_Map_2ch_0x2
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringLeftJustify
	jrl RVari_Select_ReturnZero

	.include "ui/rvari_routines.s"
