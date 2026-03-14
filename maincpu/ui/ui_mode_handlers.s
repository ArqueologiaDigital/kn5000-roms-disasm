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
	ldada xbc, 64773
	ldada xhl, 63904
	sub xbc, xhl
	lda_24 xde, 0x03c2c4
	add xbc, xde
	cp (xbc), 0x3
	jr nz, EffectMode_CopyVoiceParams_Done
	ldada xix, 64004
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
	and c, 0xCF
	ldfr_berp C, 0xF8
	lda xbc, (xix + 4)
	sub xbc, xhl
	ld xiy, xbc
	add xiy, xde
	ld c, (xiy)
	and c, 0x30
	ld (xiy), c
	or_berp C, 0xF8
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
	.byte 0xf1, 0x58, 0x8d, 0x02, 0xff, 0xff, 0x78, 0x88
	.byte 0x02
EffectMode_ByteData_Block2:
	.byte 0xc1, 0x7d, 0xc0, 0x3f, 0x02, 0xb0, 0xfe
	.byte 0xc1, 0x7e, 0xc0, 0x21, 0xc1, 0x7f, 0xc0, 0xc1
	.byte 0xc9, 0x33, 0x00, 0x76, 0x91, 0x00, 0xc1, 0x34
	.byte 0x8d, 0x3f, 0x01, 0x66, 0x4e, 0xc1, 0x36, 0x8d
	.byte 0x21, 0xc9, 0xcf, 0xc0, 0x66, 0x28, 0xc9, 0xcf
	.byte 0xc1, 0x66, 0x0f, 0xc9, 0xcf, 0xc2, 0x66, 0x0a
	.byte 0xc9, 0xcf, 0xc3, 0x66, 0x05, 0xc9, 0xcf, 0xc5
	.byte 0xb0, 0xfe, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x9a, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x58
	.byte 0x9d, 0xfa, 0xd8, 0xa9, 0x68, 0x36, 0xc1, 0x4e
	.byte 0x8d, 0x3f, 0x00, 0xb0, 0xfe, 0x40, 0xff, 0xff
	.byte 0xff, 0xff, 0x41, 0x9a, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0xd8, 0xa9, 0x1b
	.byte 0x63, 0x94, 0xf9, 0xc1, 0x4e, 0x8d, 0x3f, 0x00
	.byte 0x66, 0x18, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x9a, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x58
	.byte 0x9d, 0xfa, 0xd8, 0xa9, 0x1d, 0x63, 0x94, 0xf9
	.byte 0x68, 0x3b, 0x40, 0xff, 0xff, 0xff, 0xff, 0x41
	.byte 0x9a, 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x58
	.byte 0x9d, 0xfa, 0x30, 0x12, 0x00, 0x1d, 0x63, 0x94
	.byte 0xf9, 0xf1, 0x4e, 0x8d, 0x00, 0x0f, 0x0e, 0xc1
	.byte 0x4e, 0x8d, 0x3f, 0x00, 0xb0, 0xf6, 0x40, 0xff
	.byte 0xff, 0xff, 0xff, 0x41, 0x9a, 0x00, 0xe0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0x30, 0xc1
	.byte 0x00, 0x1d, 0x90, 0x94, 0xf9, 0xf1, 0x4e, 0x8d
	.byte 0x00, 0x00, 0x0e
EffectMode_ByteData_Block3:
	.byte 0xc1, 0x7d, 0xc0, 0x21, 0xc9
	.byte 0xd8, 0x6e, 0x5f, 0xc1, 0x7f, 0xc0, 0x3f, 0x00
	.byte 0x66, 0x53, 0xf1, 0x7e, 0xc0, 0xcf, 0x6e, 0x4d
	.byte 0xf1, 0x52, 0x8d, 0xcc, 0x6e, 0x47, 0xc1, 0x36
	.byte 0x8d, 0x3f, 0xc0, 0x6e, 0x06, 0x1d, 0xfa, 0x94
	.byte 0xf9, 0x68, 0x3a, 0x40, 0x01, 0x04, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xdb, 0x66, 0x04
	.byte 0xdb, 0xda, 0x6e, 0x29, 0x40, 0x00, 0x04, 0x00
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0xd8, 0x66
	.byte 0x1c, 0x40, 0x02, 0x80, 0x02, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xf1, 0x54, 0x8d, 0x47, 0xf1, 0xe2
	.byte 0xb7, 0xbf, 0xf1, 0x52, 0x8d, 0xbb, 0x1e, 0x57
	.byte 0x06, 0xf1, 0x52, 0x8d, 0xb3, 0xf1, 0x52, 0x8d
	.byte 0xb4, 0x0e, 0xc9, 0xdf, 0x6e, 0x3b, 0xc1, 0x52
	.byte 0x8d, 0x21, 0xc9, 0xcc
	.ascii "(f2@"
	.byte 0x01, 0x04, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0xdb, 0x66, 0x04, 0xdb, 0xda, 0x6e, 0x21
	.byte 0x40, 0x00, 0x04, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xd8, 0x66, 0x14, 0x40, 0x02, 0x80
	.byte 0x02, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xf1, 0x54
	.byte 0x8d, 0x47, 0xf1, 0xe2, 0xb7, 0xbf, 0x1e, 0x0f
	.byte 0x06, 0xc1, 0x52, 0x8d, 0x3c, 0xd7, 0x0e
EffectMode_ByteData_Block4:
	.byte 0xc1
	.byte 0x7d, 0xc0, 0x3f, 0x03, 0x6e, 0x44, 0xc1, 0x7e
	.byte 0xc0, 0x21, 0xc9, 0xcc, 0x07, 0x66, 0x3b, 0xc1
	.byte 0x52, 0x8d, 0x21, 0xc9, 0xcc, 0x28, 0x66, 0x32
	.byte 0x40, 0x01, 0x04, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0xdb, 0x66, 0x04, 0xdb, 0xda, 0x6e
	.byte 0x21, 0x40, 0x00, 0x04, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0xd8, 0x66, 0x14, 0x40, 0x02
	.byte 0x80, 0x02, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xf1
	.byte 0x54, 0x8d, 0x47, 0xf1, 0xe2, 0xb7, 0xbf, 0x1e
	.byte 0xbe, 0x05, 0xc1, 0x52, 0x8d, 0x3c, 0xd7, 0x0e


EffectMode_ApplyTranspose:
	calr EffectMode_ProcessPresetChange
	cpdi8 36150, 192
	jr nz, EffectMode_ApplyTranspose_StoreTimer
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 0
	call ApPostEvent
	lds wa, 1
	call UI_PostPartChangeEvent

EffectMode_ApplyTranspose_StoreTimer:
	stdi8 36174, 0
	jr __jrt_nop_FB6C51
__jrt_nop_FB6C51:

EffectMode_CheckTransposeAndLookup:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	bit 7, hl
	ret nz
	calr SndParam_LoadTransposeValues
	stda16 36184, xhl
	ret

SndParam_LoadTransposeValues:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	stda8 37098, l
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	ldada xwa, 37098
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
	ldada xbc, 37102
	ld e, (xbc + 1)
	extz de
	ld a, (xbc)
	extz wa
	sll wa, 8
	add wa, de
	ld hl, wa
	ret

EffectMode_TimerCountdown:
	ldda8 a, 36174
	cps a, 0
	ret z
	dec 1, a
	stda8 36174, a
	cps a, 0
	ret nz
	cpdi16 36182, 0
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
	ldda8 a, 36150
	cp a, 0xC5
	jr z, EffectMode_TimerCountdown_ResBit7
	cp a, 0xC2
	jr z, EffectMode_TimerCountdown_ResBit7
	cp a, 0xC1
	jr nz, EffectMode_TimerCountdown_SetBit7

EffectMode_TimerCountdown_ResBit7:
	resda 7, 47074
	ret

EffectMode_TimerCountdown_SetBit7:
	setda 7, 47074
	ret

EffectMode_CheckTransposeChanged:
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	bit 7, hl
	jr nz, EffectMode_TransposeInvalid
	calr SndParam_LoadTransposeValues
	cpda16 xhl, 36184
	ret z
	stda16 36184, xhl
	jrl BitMapOut_ApplyPatch_SkipHeader

EffectMode_TransposeInvalid:
	stdi16 36184, 65535
	stdi16 36182, 0
	ret

EffectMode_ProcessPresetChange:
	dec 4, xsp
	push xiz
	ldda16 xbc, 36182
	ld wa, bc
	cps bc, 0
	jr z, EffectMode_ProcessPresetChange_CheckBit7
	dec 1, wa
	jr EffectMode_ProcessPresetChange_Apply

EffectMode_ProcessPresetChange_CheckBit7:
	bitda 7, 47074
	jr nz, EffectMode_ProcessPresetChange_Done

EffectMode_ProcessPresetChange_Apply:
	calr EffectMode_ClampAndLookupPreset
	ld xwa, xhl
	stda32 36192, xwa
	calr EffectMode_UpdateDisplay
	ldada xwa, 64602
	ld (xsp + 4), xwa
	sub xwa, 0xF9A0
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
	ldada xwa, 63983
	sub xwa, 0xF9A0
	lda_24 xbc, 0x03c2c4
	add xwa, xbc
	andmi8 (xwa), 0x80
	ld xwa, (xsp + 4)
	ld xbc, xiz
	calr EffectMode_CopyPresetBits
	calr EffectMode_ReinitSoundOutput

EffectMode_ProcessPresetChange_Done:
	resda 7, 47074
	pop xiz
	inc 4, xsp
	ret

EffectMode_CopyParamByte:
	ldada	xwa, 64007
	ldada	xde, 63904
	sub	xwa, xde
	lda_24	xbc, 246468
	ld	xhl, xwa
	add	xhl, xbc
	ldada	xwa, 64423
	sub	xwa, xde
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xhl), a
	ret

EffectMode_ClampAndLookupPreset:
	cp wa, 0x3E8
	jr ule, EffectMode_ClampAndLookup_Clamped
	lds wa, 1

EffectMode_ClampAndLookup_Clamped:
	ldda8 c, 36152
	cp c, 0xC2
	jr z, EffectMode_LookupPreset_BankC2C5
	cp c, 0xC5
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
	ldda8 c, 36152
	cp c, 0xC0
	jr z, EffectMode_DisplayName_ValidMode
	cp c, 0xC2
	jr z, EffectMode_DisplayName_ValidMode
	cp c, 0xC5
	jr nz, EffectMode_DisplayName_Done

EffectMode_DisplayName_ValidMode:
	ldda16 xwa, 36182
	ld iz, wa
	cps wa, 0
	jr z, EffectMode_DisplayName_CheckC2C5
	dec 1, iz

EffectMode_DisplayName_CheckC2C5:
	cp c, 0xC2
	jr z, EffectMode_DisplayName_LookupC2C5
	cp c, 0xC5
	jr nz, EffectMode_DisplayName_LookupC0

EffectMode_DisplayName_LookupC2C5:
	ld wa, iz
	calr EffectMode_SearchPresetTableC2C5
	cp xhl, 0xFFFFFFFF
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
	cp xhl, 0xFFFFFFFF
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
	ldada xwa, 63906
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
	lda_24 xhl, 0xeb7ca0

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
	ld xhl, 0xFFFFFFFF
	ret

EffectMode_SearchPresetTableC0:
	lds ix, 0
	lda_24 xhl, 0xeb7e2c

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
	ld xhl, 0xFFFFFFFF
	ret

EffectMode_UpdateDisplay:
	push xiz
	ld xiz, xwa
	calr EffectMode_BackupParamBlock
	ldda8 a, 36178
	bit 5, a
	jr z, EffectMode_UpdateDisplay_NoPatch
	res 5, a
	stda8 36178, a
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
	ldada xwa, 63930
	ldada xde, 63904
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
	ldada xwa, 63956
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
	ldada xwa, 63982
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
	ldada xwa, 64008
	sub xwa, xde
	ld (xsp + 44), xwa
	add (xsp + 44), xbc
	ld xwa, (xsp + 44)
	ld l, (xwa)
	and l, 0x20
	ld xwa, (xsp + 16)
	ld (xwa), l
	ldada xwa, 64770
	sub xwa, xde
	ld (xsp + 28), xwa
	add (xsp + 28), xbc
	ld xwa, (xsp + 28)
	ld a, (xwa)
	and a, 0x3B
	ld (xsp + 4), a
	ldada xhl, 64623
	sub xhl, xde
	add xhl, xbc
	ld a, (xhl)
	and a, 0x20
	ld (xsp + 6), a
	ldda32 xwa, 36192
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
	ld_spib A, 0xE8
	lda_dpi XBC, 0xF8
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
	ld xix, 0xEB7BDA
	add xix, xwa
	ld xwa, (xix)
	cp xwa, 0xFF
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
	and c, 0xC4
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
	ldada xbc, 63904
	ldada xwa, 64862
	sub xwa, xbc
	inc 2, xwa
	pushw wa
	push xbc
	pushw 0x3
	pushw 0xC2C4
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

EffectMode_CopyHoldPedalBits:
	ldda8 e, 36152
	cp e, 0xC0
	ret z
	cp e, 0xC2
	ret z
	cp e, 0xC5
	ret z
	bitda 2, 1056
	ret z
	ld l, (xwa + 8)
	and l, 0xFF
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
	ldb h, 0xA
	cps l, 2
	jr nz, EffectMode_SetRegion_Apply
	ldb h, 0x9

EffectMode_SetRegion_Apply:
	lda xbc, (xiz + 3)
	ld a, (xbc)
	and a, 0xF8
	ld (xbc), a
	or a, h
	ld (xbc), a
	setm 1, (xiz + 5)
	ldada xbc, 64770
	ld h, (xbc)
	and h, 0x3
	sub xbc, 0xF9A0
	lda_24 xde, 0x03c2c4
	add xbc, xde
	ld a, (xbc)
	and a, 0xFC
	ld (xbc), a
	or a, h
	ld (xbc), a
	ldda8 a, 36152
	cp a, 0xC2
	jr z, EffectMode_CheckPedalType
	cp a, 0xC5
	jr nz, EffectMode_PopIzRet

EffectMode_CheckPedalType:
	bitda 2, 1054
	jr nz, EffectMode_PopIzRet
	ldda16 xwa, 36182
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
	bitda 7, 47074
	ret z
	ld c, (xwa)
	ld (xde), c
	ld c, (xwa + 1)
	res 7, c
	ldfr_berp C, 0xF0
	lda xhl, (xde + 1)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	or_berp C, 0xF0
	ld (xhl), c
	ld a, (xwa + 4)
	and a, 0x7
	ldfr_berp A, 0xF0
	lda xbc, (xde + 4)
	ld a, (xbc)
	and a, 0xF8
	ld (xbc), a
	or_berp A, 0xF0
	ld (xbc), a
	ret

EffectMode_ReinitSoundOutput:
	ld xwa, 0x302
	call SndParam_LookupReadOnly
	stda8 36176, l
	ld xwa, 0x302
	lds bc, 1
	lds de, 0
	call SoundParam_NotifyChange
	ldw wa, 0x80
	ld xbc, 0x3C2C4
	call BitMapOut_CopyVoicePreset9
	ldw wa, 0x80
	call BitMapOut_SnapshotFromROM
	calr EffectMode_DisplayPresetName
	resda 4, 36178
	cpdi8 36176, 1
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
	setda 5, 36178
	calr EffectMode_CheckModeAndReinit
	resda 5, 36178
	ret

EffectMode_CheckModeAndReinit:
	ldda8 c, 36150
	cp c, 0x78
	jr z, SndOutput_ReinitByMode
	cp c, 0x7A
	jr z, SndOutput_ReinitByMode
	ldda8 a, 36148
	cps a, 2
	jr z, SndOutput_ReinitByMode
	cps a, 1
	jr z, SndOutput_ReinitByMode
	cp c, 0x85
	jr z, SndOutput_ReinitByMode
	cp c, 0x81
	jr z, SndOutput_ReinitByMode
	cp c, 0x7F
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
	ldda16 xiz, 36184
	ldda16 xwa, 36182
	ldfr_werp WA, 0xFA
	stdi16 36184, 65535
	calr EffectMode_CheckTransposeChanged
	ldda16 xbc, 36182
	cps bc, 0
	jr z, SndOutput_ReinitByMode_Restore
	dec 1, bc
	ldda8 a, 36180
	extz wa
	add bc, wa
	stda16 36182, xbc
	calr EffectMode_ProcessPresetChange
	call SwbtWr_ReinitOutputBank

SndOutput_ReinitByMode_Restore:
	ldto_werp WA, 0xFA
	stda16 36182, xwa
	stda16 36184, xiz
	pop xiz
	ret

SndOutput_ReinitByMode_NotifyParam:
	ldda8 c, 36180
	inc 1, c
	extz bc
	ld xwa, 0x300
	lds de, 3
	call SoundParam_NotifyChange
	ldda8 a, 36178
	bit 5, a
	jr z, SndOutput_ReinitByMode_CheckBit3
	set 2, a
	stda8 36178, a

SndOutput_ReinitByMode_CheckBit3:
	ldda8 a, 36178
	bit 3, a
	ret z
	set 1, a
	stda8 36178, a
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
	ldw bc, 0xC000
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
	muls wa, 0xA
	lda_24 xbc, 0xeb802e
	st_dri3b B, 0x07, 0xE4, 0xE0
	ld xhl, (xde)
	ld xiz, (xde + 4)
	srl xiz, 3
	or xiz, xiz
	jr z, DramTest_IC10IC9_LoopEnd

DramTest_IC10IC9_WriteLoop:
	ld xwa, (xhl)
	ld (xsp + 6), xwa
	ld xwa, 0x5A5A5A5A
	ld (xhl), xwa
	ld xiy, xhl
	lda xix, (xsp + 10)
	ldiw
	ldiw
	lda xwa, (xsp + 10)
	ld xbc, xwa
	cpw (xwa), 0x5A5A
	jr z, DramTest_IC10IC9_Check5A_High
	ld a, (xde + 8)
	or (xsp + 14), a

DramTest_IC10IC9_Check5A_High:
	cpw (xbc + 2), 0x5A5A
	jr z, DramTest_IC10IC9_WriteA5
	ld a, (xde + 9)
	or (xsp + 14), a

DramTest_IC10IC9_WriteA5:
	ld xwa, (xsp + 6)
	st_dpil XWA, 0xEE
	ld xwa, (xhl)
	ld (xsp + 6), xwa
	ld xwa, 0xA5A5A5A5
	ld (xhl), xwa
	ld xiy, xhl
	lda xix, (xsp + 10)
	ldiw
	ldiw
	lda xwa, (xsp + 10)
	ld xbc, xwa
	cpw (xwa), 0xA5A5
	jr z, DramTest_IC10IC9_CheckA5_High
	ld a, (xde + 8)
	or (xsp + 14), a

DramTest_IC10IC9_CheckA5_High:
	cpw (xbc + 2), 0xA5A5
	jr z, DramTest_IC10IC9_RestoreAndNext
	ld a, (xde + 9)
	or (xsp + 14), a

DramTest_IC10IC9_RestoreAndNext:
	ld xwa, (xsp + 6)
	st_dpil XWA, 0xEE
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
	muls bc, 0xA
	lda_24 xde, 0xeb8038
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld xiy, (xde)
	ld xbc, (xde + 4)
	srl xbc, 1
	ld xix, xbc
	or xix, xix
	jr z, SramTest_IC21_LoopEnd

SramTest_IC21_Write5A:
	ld w, (xiy)
	ld (xiy), 0x5A
	lda xbc, (xde + 8)
	cp (xiy), 0x5A
	jr z, SramTest_IC21_Verify5A
	or a, (xbc)

SramTest_IC21_Verify5A:
	lda_dpi XWA, 0xF4
	ld w, (xiy)
	ld (xiy), 0xA5
	cp (xiy), 0xA5
	jr z, SramTest_IC21_WriteA5
	or a, (xbc)

SramTest_IC21_WriteA5:
	lda_dpi XWA, 0xF4
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
	ldi_berp 0xE2, 0

RomTest_ProgramTableData_OuterLoop:
	ld xhl, 0xE00000
	lds32 xix, 0

RomTest_ProgramTableData_SumLoop:
	ldto_berp A, 0xE2
	extz wa
	sla wa, 1
	ld iy, wa
	st_dri3b H, 0x07, 0xE4, 0xF4
	ld wa, (xiz)
	ldfr_werp WA, 0xF6
	ld wa, (xhl)
	add_werp WA, 0xF6
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
	inc1_berp 0xE2
	cpi_berp 0xE2, 2
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
	ldi_berp 0xE2, 0

RomTest_TableData_OuterLoop:
	ld xhl, 0x800000
	lds32 xix, 0

RomTest_TableData_SumLoop:
	ldto_berp A, 0xE2
	extz wa
	sla wa, 1
	ld iy, wa
	st_dri3b H, 0x07, 0xE4, 0xF4
	ld wa, (xiz)
	ldfr_werp WA, 0xF6
	ld wa, (xhl)
	add_werp WA, 0xF6
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
	inc1_berp 0xE2
	cpi_berp 0xE2, 2
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
	st_dri3b B, 0x07, 0xF0, 0xE4
	ld bc, (xde)
	ldfr_werp BC, 0xE2
	ld_spiw BC, 0xF5
	add_werp BC, 0xE2
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
	lda_24 xix, 0xeb800c
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
	cp hl, 0xFFFF
	jr nz, CustomRomTest_PrepareChecksum
	setm 1, (xsp + 6)

CustomRomTest_PrepareChecksum:
	lda xhl, (xsp + 2)
	ldw (xhl), 0x0
	lda xde, (xhl + 2)
	ldw (xde), 0x0
	ldi_berp 0xE2, 0

CustomRomTest_OuterLoop:
	ld xix, 0x300000
	lds32 xiy, 0

CustomRomTest_SumLoop:
	ldto_berp A, 0xE2
	extz wa
	add wa, wa
	st_dri3b A, 0x07, 0xEC, 0xE0
	ld wa, (xbc)
	ld_spiw IZ, 0xF1
	add iz, wa
	ld (xbc), iz
	inc 1, xiy
	cp xiy, 0x40000
	jr c, CustomRomTest_SumLoop
	inc1_berp 0xE2
	cpi_berp 0xE2, 2
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
	ldw wa, 0x3C3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3C3
	call _Read_VGA_Register

	cps l, 0
	jr z, LcdTest_WriteOneVerify
	setm 2, (xsp)

LcdTest_WriteOneVerify:
	; equivalent to "_VGA_WRITE 3c3h, 1" but with CALL instead of CALR
	ldw wa, 0x3C3
	lds bc, 1
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3C3
	call _Read_VGA_Register

	cps l, 1
	jr z, LcdTest_WriteZeroVerify
	setm 2, (xsp)

LcdTest_WriteZeroVerify:
	; equivalent to "_VGA_WRITE 3c3h, 0" but with CALL instead of CALR
	ldw wa, 0x3C3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3C3
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
	ld32_24 xhl, 0xeb7932
	call (xhl)
	sti16_24 0x1a0000, 0x5a5a              ; VRAM self-test pattern 1
	calr DramTest_Loop
	cpdi16_24 1703936, 23130
	jr z, VramTest_Pattern2
	setm 3, (xsp)

VramTest_Pattern2:
	sti16_24 0x1a0004, 0xa5a5              ; VRAM self-test pattern 2
	calr DramTest_Loop
	cpdi16_24 1703940, 42405
	jr z, VramTest_Pattern3
	setm 3, (xsp)

VramTest_Pattern3:
	sti16_24 0x1a0008, 0x5a5a
	calr DramTest_Loop
	cpdi16_24 1703944, 23130
	jr z, VramTest_Done
	setm 3, (xsp)

VramTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

SelfTest_FirmwareVersionCheck:
	push_werp 0xFA
	call Get_Firmware_Version
	cp l, 0x77
	jr nz, SelfTest_InterCPU_Send
	ldw wa, 0xFB
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	stdi8 36226, 2
	jrl EffectMode_PopRetFA

SelfTest_InterCPU_Send:
	ld xwa, 0xF002
	ldw bc, 0x8
	ld xde, 0x8D64
	call InterCPU_E2_Send
	ld xwa, 0x3FFFFF
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
	ldi_berp 0xFA, 0
	ldi_berp 0xFB, 0

SelfTest_CountBits_Loop:
	ldto_berp C, 0xFB
	extz bc
	ldada xwa, 36196
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	calr SelfTest_PopCount
	ldto_berp A, 0xFA
	add a, l
	ldfr_berp A, 0xFA
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x08
	jr c, SelfTest_CountBits_Loop
	cpi_berp 0xFA, 2
	jr nz, SelfTest_SramAndRom
	ldada xde, 36196
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
	ldw wa, 0xF5
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit4:
	inc 5, xde
	bit 4, c
	jr z, SelfTest_CheckBit5
	bitm 0, (xde)
	jr z, SelfTest_CheckBit5
	ldw wa, 0xF6
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	jrl EffectMode_PopRetFA

SelfTest_CheckBit5:
	bit 5, c
	jr z, SelfTest_CheckBit7
	bitm 1, (xde)
	jr z, SelfTest_CheckBit7
	ldw wa, 0xF7
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit7:
	bit 7, c
	jr z, SelfTest_CheckBitA1
	bitm 3, (xde)
	jr z, SelfTest_CheckBitA1
	ldw wa, 0xF8
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA1:
	ld a, (xwa)
	bit 1, a
	jr z, SelfTest_CheckBitA3
	bitm 5, (xde)
	jr z, SelfTest_CheckBitA3
	ldw wa, 0xF9
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA3:
	bit 3, a
	jrl z, EffectMode_PopRetFA
	bitm 7, (xde)
	jrl z, EffectMode_PopRetFA
	ldw wa, 0xFC

EffectMode_UIPostModeChangeEvent:
	call UI_PostModeChangeEvent

SelfTest_Diagnostic_Skip:
	jrl EffectMode_PopRetFA

SelfTest_SramAndRom:
	ldi_berp 0xFA, 0
	lds wa, 0
	calr Test_SRAM_IC21
	cps hl, 0
	jr z, SelfTest_SramAndRom_CheckROM
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	call DeleteEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000F4
	call ApPostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0xF40001
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldi_berp 0xFA, 1

SelfTest_SramAndRom_CheckROM:
	push xde
	push xhl
	push xix
	push xiz
	call CPanel_PanelDetection_Wrapper
	stda8 36220, a
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldda8 a, 36220
	cpl a
	and a, 0x9
	stda8 36220, a
	cps a, 0
	jr z, EffectMode_PopRetFA
	cpi_berp 0xFA, 0
	jr nz, SelfTest_PostRomError
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	call DeleteEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000F4
	call ApPostEvent

SelfTest_PostRomError:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call ApPostEvent
	ld xwa, 0xF40007
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent

EffectMode_PopRetFA:
	pop_werp 0xFA
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
	cpdi8 36150, 251
	jr nz, EffectMode_DispatchUpdate
	ldda8 a, 36226
	cps a, 2
	jr z, EffectMode_ResetDiagMode
	ldda8 a, 36224
	bit 0, a
	jr z, EffectMode_CheckAndDispatch_Bit4Clear
	bit 4, a
	jr nz, EffectMode_DispatchUpdate
	set 4, a
	stda8 36224, a
	ldda8 a, 36226
	cps a, 1
	jr z, EffectMode_DispatchUpdate
	stdi8 36226, 1
	calr EffectMode_InitSwbWr_DiagMode
	calr EffectMode_SetAllLEDs
	jr EffectMode_DispatchUpdate

EffectMode_CheckAndDispatch_Bit4Clear:
	bit 4, a
	jr z, EffectMode_DispatchUpdate
	res 4, a
	stda8 36224, a
	ldda8 a, 36226
	cps a, 0
	jr z, EffectMode_DispatchUpdate
	stdi8 36226, 0
	calr EffectMode_RestoreSwbWr_NormalMode
	calr LED_SetAll_WithBlank
	stdi8 58334, 16
	jr EffectMode_DispatchUpdate

EffectMode_ResetDiagMode:
	stdi8 36226, 0
	calr LED_SetAll_WithBlank
	calr EffectMode_RestoreSwbWr_NormalMode

EffectMode_DispatchUpdate:
	cpdi8 36150, 248
	call_24 z, 0xFB79AA
	cpdi8 36150, 247
	call_24 z, 0xFB7BFF
	cpdi8 36150, 251
	ret nz
	calr EffectMode_RunDiagSequence
	ret

EffectMode_InitSwbWr_DiagMode:
	ldada xwa, 63926
	stib_dpi 0xE0, 0x00
	andmi8 (xwa), 0x80
	ldada xbc, 64950
	andmi8 (xbc), 0xF0
	ld (xbc), 0x6
	ld e, (xwa)
	extz de
	pushw 0x7F
	lds wa, 0
	lds bc, 1
	call AddswbWr
	pushw 0xFF
	lds wa, 0
	lds bc, 0
	lds de, 0
	call AddswbWr
	pushw 0xF
	ldw wa, 0x93
	lds bc, 0
	lds de, 6
	call AddswbWr
	ret

EffectMode_RestoreSwbWr_NormalMode:
	ldada xwa, 63926
	stib_dpi 0xE0, 0x40
	andmi8 (xwa), 0x80
	anddi8 64950, 240
	ld e, (xwa)
	extz de
	pushw 0x7F
	lds wa, 0
	lds bc, 1
	call AddswbWr
	pushw 0xFF
	lds wa, 0
	lds bc, 0
	ldw de, 0x40
	call AddswbWr
	pushw 0xF
	ldw wa, 0x93
	lds bc, 0
	lds de, 0
	call AddswbWr
	ret

EffectMode_HandleTimerEvents:
	call CtrlPanel_GetSelectionState
	cps hl, 0
	ret nz
	ldda8 a, 36218
	cp a, 0x96
	jrl z, EffectMode_TimerEvent_Step96
	cp a, 0x78
	jrl z, EffectMode_TimerEvent_Step78
	cp a, 0x5A
	jr z, EffectMode_TimerEvent_Step5A
	cp a, 0x3C
	jr z, EffectMode_TimerEvent_Step3C
	cp a, 0x1E
	jr z, EffectMode_TimerEvent_Step1E
	cps a, 0
	jrl nz, EffectMode_TimerEvent_Default
	ld xwa, 0xF8000C
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldda8 a, 36218
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_TimerEvent_Step1E:
	ld xwa, 0xF8000E
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldda8 a, 36218
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_TimerEvent_Step3C:
	ld xwa, 0xF80010
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldda8 a, 36218
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_TimerEvent_Step5A:
	ld xwa, 0xF80006
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldda8 a, 36218
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_TimerEvent_Step78:
	ld xwa, 0xF80008
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	ldda8 a, 36218
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_TimerEvent_Step96:
	ld xwa, 0xF8000A
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	stdi8 36218, 220
	ret

EffectMode_TimerEvent_Default:
	inc 1, a
	inc 1, a
	stda8 36218, a
	ret

EffectMode_RunDiagSequence:
	ldda8 a, 36218
	cps a, 0
	jr nz, EffectMode_DiagSeq_AnimFrame
	ld xwa, 0xF80006
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, 0xF80008
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, 0xF8000A
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, 0xF8000C
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	ld xwa, 0xF8000E
	ld xbc, 0x1C00001
	lds32 xde, 0
	call ApPostEvent
	calr A_Short_Pause
	calr A_Short_Pause
	incdi8 1, 36218
	ret

EffectMode_DiagSeq_AnimFrame:
	ldda8 c, 36216
	cps c, 0
	jr nz, EffectMode_DiagSeq_DecrementDelay
	extz wa
	lda_24 xbc, 0xeb7e86
	lds32 xde, 0
	ld_srib3 E, 0x07, 0xE4, 0xE0
	add xde, 0x1A00000
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	call ApPostEvent
	ldda8 a, 36218
	cps a, 5
	jr nz, EffectMode_DiagSeq_IncFrame
	stdi8 36218, 1
	jr EffectMode_DiagSeq_SetDelay

EffectMode_DiagSeq_IncFrame:
	inc 1, a
	stda8 36218, a

EffectMode_DiagSeq_SetDelay:
	stdi8 36216, 30
	ret

EffectMode_DiagSeq_DecrementDelay:
	dec 1, c
	stda8 36216, c
	ret

EffectMode_ByteData_DiagEvents:
	push	qiz
	.byte 0x3a, 0x3b, 0x3c, 0x3e
	.byte 0x1d
	.byte 0xdc, 0x3e, 0xfc, 0xf1, 0x7c, 0x8d, 0x41, 0x5e
	.byte 0x5c, 0x5b, 0x5a, 0xc1, 0x7c, 0x8d, 0x21, 0xc9
	.byte 0x06, 0xc7, 0xfb, 0x99, 0xc9, 0xcc, 0x09, 0xd8
	.byte 0x12, 0x1e, 0x79, 0xf7, 0xc7, 0xfb, 0x89, 0xc9
	.byte 0xcc, 0x09, 0x6e, 0x0e, 0x40, 0x0b, 0x00, 0xf5
	.byte 0x00, 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xa8
	.byte 0x68, 0x33, 0xc9, 0xcf, 0x09, 0x6e, 0x0e, 0x40
	.byte 0x0e, 0x00, 0xf5, 0x00, 0x41, 0x01, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa8, 0x68, 0x20, 0xc7, 0xfb, 0x33
	.byte 0x00, 0x66, 0x0e, 0x40, 0x11, 0x00, 0xf5, 0x00
	.byte 0x41, 0x01, 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x68
	.byte 0x0c, 0x40, 0x14, 0x00, 0xf5, 0x00, 0x41, 0x01
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa8, 0x1d, 0x58, 0x9d
	.byte 0xfa, 0xd7, 0xfa, 0x05, 0x0e, 0xc1, 0x37, 0x8d
	.byte 0x21, 0xc1, 0x36, 0x8d, 0xf1, 0xb0, 0xf6, 0x40
	.byte 0x02, 0x40, 0x00, 0x00, 0x31, 0x80, 0x00, 0xda
	.byte 0xab, 0x1d, 0x2f, 0xd3, 0xfc, 0x1d, 0x75, 0x0e
	.byte 0xfe, 0x0e

Voice_EmitNoteWithVelocity:
	cpdi8 36150, 246
	ret nz
	stda8 36228, a
	stda8 36230, c
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E20017
	lds32 xde, 0
	call ApPostEvent
	ret

EffectMode_ModeChangeTransition:
	ldda8 a, 36151
	cpda8 a, 36150
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
	push_werp 0xFA
	ldi_berp 0xFB, 0
	jr EffectMode_SetAllLEDs_Loop

EffectMode_SetAllLEDs_SetOne:
	ld wa, bc
	srl wa, 8
	call Set_LEDs
	inc1_berp 0xFB

EffectMode_SetAllLEDs_Loop:
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	lda_24 xbc, 0xeb7fec
	ld_sriw3 BC, 0x07, 0xE4, 0xE0
	cp bc, 0xFFFF
	jr nz, EffectMode_SetAllLEDs_SetOne
	pop_werp 0xFA
	ret

LED_SetAll_WithBlank:
	push_werp 0xFA
	ldi_berp 0xFB, 0
	jr LED_SetAll_BlankLoop

LED_SetAll_BlankOne:
	srl wa, 8
	lds bc, 0
	call Set_LEDs
	inc1_berp 0xFB

LED_SetAll_BlankLoop:
	ldto_berp A, 0xFB
	extz wa
	add wa, wa
	lda_24 xbc, 0xeb7fec
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	cp wa, 0xFFFF
	jr nz, LED_SetAll_BlankOne
	pop_werp 0xFA
	ret


FDC_CommandAndPostEvent:
	; --- Stack-frame: alloc 16, conditional XDE setup, call dispatch (59 bytes) ---
	lda	xsp, (xsp-16)
	lda	xwa, (xsp)
	.byte 0xb0, 0x02, 0x03, 0x00			; ld (xwa), 0x0003  [16-bit store]
	push xwa
	call FDC_CommandEntry
	inc 4, xsp
	ldda8	a, 35364
	cp a, 0xfc
	jr nz, FDC_PostEvent_Error
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C0001E
	lds32	xde, 2
	jr t, FDC_PostEvent_Send
FDC_PostEvent_Error:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x01C0001E
	lds32	xde, 1
FDC_PostEvent_Send:
	call ApPostEvent
	lda	xsp, (xsp+16)
	ret


EffectMode_MidiParseLoop:
	push xiz
	ldada xiz, 36204
	ld xwa, xiz
	call MIDI_ParseThreeByteParams
	cp hl, 0xFFFF
	jr z, EffectMode_MidiParse_Done

EffectMode_MidiParse_Continue:
	ld xwa, xiz
	calr EffectMode_MidiSetLEDs
	ld xwa, xiz
	call MIDI_ParseThreeByteParams
	cp hl, 0xFFFF
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
	lda_24 xde, 0xeb7e8c
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
	cp xbc, 0x1C00013
	jr nz, TableDispatch_Return3
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return3
	cp xde, 0x5
	jr ugt, TableDispatch_Return3
	add xde, xde
	add xde, 0xEB8042
	ld de, (xde)
	lda_24 xix, 0xfb7d72
	jp_dri 8, 0x07, 0xF0, 0xE8
; TEST2FUNC event dispatch return (6-entry, event 0x1C00013)
TEST2FUNC_DispatchReturn:
	calr	0xfdd8

TableDispatch_Return3:
	lds32 xhl, 0
	ret

TEST3FUNC:
	cp xbc, 0x1C00013
	jr nz, TableDispatch_Return4
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return4
	cp xde, 0x5
	jr ugt, TableDispatch_Return4
	add xde, xde
	add xde, 0xEB804E
	ld de, (xde)
	lda_24 xix, 0xfb7da6
	jp_dri 8, 0x07, 0xF0, 0xE8
; TEST3FUNC event dispatch return (6-entry, event 0x1C00013)
TEST3FUNC_DispatchReturn:
	calr	0xfe19

TableDispatch_Return4:
	lds32 xhl, 0
	ret

TEST4FUNC:
	cp xbc, 0x1C00013
	jr nz, TableDispatch_Return5
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return5
	cp xde, 0x5
	jr ugt, TableDispatch_Return5
	add xde, xde
	add xde, 0xEB805A
	ld de, (xde)
	lda_24 xix, 0xfb7dda
	jp_dri 8, 0x07, 0xF0, 0xE8
; TEST4FUNC event dispatch return (6-entry, event 0x1C00013)
TEST4FUNC_DispatchReturn:
	calr	0xfe22

TableDispatch_Return5:
	lds32 xhl, 0
	ret

TEST6FUNC:
	cp xbc, 0x1C00013
	jr nz, TableDispatch_Return
	dec 2, xde
	cp xde, 0x0
	jr c, TableDispatch_Return
	cp xde, 0x5
	jr ugt, TableDispatch_Return
	add xde, xde
	add xde, 0xEB8066
	ld de, (xde)
	lda_24 xix, 0xfb7e0e
	jp_dri 8, 0x07, 0xF0, 0xE8
; TEST6FUNC event dispatch return (6-entry, event 0x1C00013)
TEST6FUNC_DispatchReturn:
	calr	0xfe7e

TableDispatch_Return:
	lds32 xhl, 0
	ret

BitmapFinpic_ByteData:
	.byte 0x1d, 0x97, 0x07, 0xef, 0xdb, 0xd8, 0xb0, 0xf6
	.byte 0xc1, 0x80, 0xc0, 0x21, 0xc1, 0x3a, 0x8d, 0xf1
	.byte 0xb0, 0xfe, 0xc1, 0x7d, 0xc0, 0x3f, 0x00, 0xb0
	.byte 0xfe, 0x1d, 0x67, 0x58, 0xfa, 0xeb, 0xcf, 0xf6
	.byte 0x00, 0xa0, 0x01, 0xb0, 0xfe, 0x40, 0xff, 0xff
	.byte 0xff, 0xff, 0x41, 0x0b, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x58, 0x9d, 0xfa, 0x0e

BitmapFinpic:
	cp xbc, 0x1E000A3
	jr z, BitmapFinpic_GetHeight
	cp xbc, 0x1E000A2
	jr z, BitmapFinpic_GetWidth
	cp xbc, 0x1E000A1
	jr z, BitmapFinpic_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFinpic_GetDataPtr:
	lda_24 xhl, 0xeb8072
	ret

BitmapFinpic_GetWidth:
	ld xhl, 0x70
	ret

BitmapFinpic_GetHeight:
	ld xhl, 0x19
	ret

BitmapFinst:
	cp xbc, 0x1E000A3
	jr z, BitmapFinst_GetHeight
	cp xbc, 0x1E000A2
	jr z, BitmapFinst_GetWidth
	cp xbc, 0x1E000A1
	jr z, BitmapFinst_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFinst_GetDataPtr:
	lda_24 xhl, 0xeb8b62
	ret

BitmapFinst_GetWidth:
	ld xhl, 0x50
	ret

BitmapFinst_GetHeight:
	ld xhl, 0x12
	ret

BitmapFoutpic:
	cp xbc, 0x1E000A3
	jr z, BitmapFoutpic_GetHeight
	cp xbc, 0x1E000A2
	jr z, BitmapFoutpic_GetWidth
	cp xbc, 0x1E000A1
	jr z, BitmapFoutpic_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFoutpic_GetDataPtr:
	lda_24 xhl, 0xeb9102
	ret

BitmapFoutpic_GetWidth:
	ld xhl, 0x71
	ret

BitmapFoutpic_GetHeight:
	ld xhl, 0x19
	ret

BitmapFoutst:
	cp xbc, 0x1E000A3
	jr z, BitmapFoutst_GetHeight
	cp xbc, 0x1E000A2
	jr z, BitmapFoutst_GetWidth
	cp xbc, 0x1E000A1
	jr z, BitmapFoutst_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFoutst_GetDataPtr:
	lda_24 xhl, 0xeb9c24
	ret

BitmapFoutst_GetWidth:
	ld xhl, 0x6C
	ret

BitmapFoutst_GetHeight:
	ld xhl, 0x14
	ret

SystemInitMDFunc:
	cp xbc, 0x1C00001
	jr nz, SystemInitMD_ReturnZero
	call GetTitleOld
	cp xhl, 0x1A000EE
	jr nz, SystemInitMD_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	ld xde, 0x1800001
	call PostEvent

SystemInitMD_ReturnZero:
	lds32 xhl, 0
	ret

SystemInitOkFunc:
	ld xwa, 0x410002
	ld xbc, 0x1E00090
	lds32 xde, 0
	call SendEvent
	exts xhl
	st32_24 0x0340de, xhl
	cpi8_24 0x0340ea, 0x00
	jr nz, SystemInitOk_PostEvent
	ld xwa, 0x142000A
	ld xbc, 0x1E20013
	ld xde, xhl
	call MainFuncCall
	jr SystemInitOk_ReturnZero

SystemInitOk_PostEvent:
	ld xwa, 0x410007
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent

SystemInitOk_ReturnZero:
	lds32 xhl, 0
	ret

SysIniNoFunc:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00041
	call PostEvent
	lds32 xhl, 0
	ret

SysIniYesFunc:
	ld32_24 xde, 0x0340de
	ld xwa, 0x142000A
	ld xbc, 0x1E20013
	call MainFuncCall
	lds32 xhl, 0
	ret

SysSureShowHideFunc:
	lds32 xhl, 0
	ret

AttnLngCheck:
	cp xbc, 0x1E0009F
	jr nz, AttnLngCheck_ReturnZero
	lda_24 xhl, 0xed04c4
	ret

AttnLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SysSureLngCheck:
	cp xbc, 0x1E0009F
	jr nz, SysSureLngCheck_ReturnZero
	lda_24 xhl, 0xed051e
	ret

SysSureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SureLngCheck:
	cp xbc, 0x1E0009F
	jr nz, SureLngCheck_ReturnZero
	lda_24 xhl, 0xed073e
	ret

SureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

CtlIniLngCheck:
	cp xbc, 0x1E0009F
	jr nz, CtlIniLngCheck_ReturnZero
	lda_24 xhl, 0xed07b6
	ret

CtlIniLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemNormLngCheck:
	cp xbc, 0x1E0009F
	jr nz, PmemNormLngCheck_ReturnZero
	lda_24 xhl, 0xed0a74
	ret

PmemNormLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemExpLngCheck:
	cp xbc, 0x1E0009F
	jr nz, PmemExpLngCheck_ReturnZero
	lda_24 xhl, 0xed0b7c
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
	cp xbc, 0x1E0008D
	jrl z, MasterSetup_ForwardToChild
	ld xwa, (xsp + 70)
	cp xwa, 0x1E0008B
	jrl z, MasterSetup_GetNameB_DrawString
	cp xwa, 0x1E0008A
	jrl z, MasterSetup_GetNameA
	cp xwa, 0x1C00007
	jrl z, MasterSetup_HandleDialTurn
	cp xwa, 0x1C00002
	jrl z, MasterSetup_HandleDialStop
	cp xwa, 0x1C00001
	jr z, MasterSetup_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, MasterSetup_InheritedProc_Fallback
	cp xbc, 0x6
	jrl gt, MasterSetup_InheritedProc_Fallback
	add xbc, xbc
	add xbc, 0xED0D24
	ld bc, (xbc)
	lda_24 xix, 0xfb809c
	jp_dri 8, 0x07, 0xF0, 0xE4

; MasterSetup event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0D24)
MasterSetup_EventDispatch:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 74)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
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
	lda_24 xbc, 0xeba498
	ld_sriw3 DE, 0x07, 0xE4, 0xE0
	extz xde
	ld xwa, 0x142000D
	ld xbc, 0x1E20018
	jr MasterSetup_CallMainFunc

MasterSetup_HandleDialStop:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, 0x142000D
	ld xbc, 0x1E20019
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
	lda_24 xbc, 0xeba494
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr MasterSetup_DialTurn_UpdateView

MasterSetup_DialTurn_Underflow:
	ld32_24 xwa, 0xebbbfe
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ldw (xwa), 0x3E7

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
	ld xwa, 0xEBA494
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xA
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00017
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
	cp hl, 0x3E8
	jr nc, MasterSetup_ScrollUp_Overflow
	ld hl, (xde)
	ld wa, (xwa)
	add wa, hl
	inc 1, wa
	ld (xde), wa
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0x6
	lda_24 xde, 0xeba494
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	jr MasterSetup_ScrollUp_UpdateView

MasterSetup_ScrollUp_Overflow:
	ld32_24 xwa, 0xeba494
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
	ld xwa, 0xEBA494
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, MasterSetup_ScrollUp_Search_Done
	inc 1, iz

MasterSetup_ScrollUp_Search_Check:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3E8
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00018
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, MasterSetup_FallbackEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1E0008F
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
	lda_24 xhl, 0xeba494
	cpw (xbc), 0x0
	jr z, MasterSetup_DialDown_Underflow
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	ldw (xwa), 0x3E7

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
	ld xwa, 0xEBA494
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xA
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x9
	ldto_werp DE, 0xE2
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0008
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
	add xhl, 0xFFFF0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 66)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyleAlp_FallbackDispatch
	ld xwa, (xsp + 74)
	ld xbc, 0x1E0008F
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
	ldto_werp WA, 0xE2
	cp wa, hl
	jrl nz, MstStyleAlp_SelectAndAutoInc
	lda xix, (xix + 78)
	ld xwa, (xix)
	ld bc, (xde)
	add bc, (xwa)
	inc 1, bc
	ld hl, bc
	lda_24 xbc, 0xeba494
	cp hl, 0x3E8
	jr nc, MstStyleAlp_OverflowCopy
	ld hl, (xwa)
	ld de, (xde)
	add de, hl
	inc 1, de
	ld (xwa), de
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	ld xwa, 0xEBA494
	add xwa, xbc
	ld xwa, (xwa)
	push xwa
	lda xwa, (xsp + 18)
	push xwa
	call String_Compare
	add xsp, 0xA
	cps hl, 0
	jr nz, MstStyleAlp_CompareComplete
	inc 1, iz

MstStyleAlp_CompareLoopCond:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3E8
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
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
	add xhl, 0xFFFF0000
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
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
	ldw (xhl), 0xE
	lda xbc, (xhl + 2)
	ldw (xbc), 0x2E
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
	pushw 0xED
	pushw 0xD18
	lda xwa, (xsp + 30)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 22)
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 12)
	lds32 xhl, 1
	push xhl
	pushw 0xFB
	pushw 0xF5
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
	cp xbc, 0x1E0008D
	jrl z, MstStyleAlp_CellSelect
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, EffectMode_SendEvent_Return
	cp xwa, 0x6
	jrl gt, EffectMode_SendEvent_Return
	add xwa, xwa
	add xwa, 0xED0D58
	ld wa, (xwa)
	lda_24 xix, 0xfb8913
	jp_dri 8, 0x07, 0xF0, 0xE0

; MstStyleAlpGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0D58)
MstStyleAlp_EventDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x3a, 0x63, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x1d, 0x66, 0x62, 0xfa, 0xaf, 0x3a
	.byte 0x22, 0xbf, 0x34, 0x52, 0xab, 0x4e, 0x21, 0xab
	.byte 0x5a, 0x20, 0x90, 0x20, 0xd8, 0x09, 0x09, 0x00
	.byte 0xd8, 0xca, 0x09, 0x00, 0x91, 0x80, 0xd8, 0x82
	.byte 0xda, 0x09, 0x06, 0x00, 0xf2, 0x98, 0xa4, 0xeb
	.byte 0x31, 0xd3, 0x07, 0xe4, 0xe8, 0x22, 0xea, 0x12
	.byte 0x40, 0x0d, 0x00, 0x42, 0x01, 0x41, 0x18, 0x00
	.byte 0xe2, 0x01, 0x1d, 0x63, 0x4a, 0xfa, 0x78, 0x98
	.byte 0x01

MstStyleAlp_CellSelect:
	call GetFocusObject
	ld xwa, xhl
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xde, (xsp + 50)
	ld xwa, (xsp + 58)
	srl xwa, 0
	ldi_werp 0xE2, 0
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
	lda_24 xwa, 0xeba494
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
	sub wa, 0xA
	ld de, (xhl)
	sub de, wa
	ld wa, (xbc)
	cp wa, de
	jr ge, MstStyleAlp_OverflowStr
	add wa, ix
	muls wa, 0x6
	ld bc, wa
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 14), 0x0
	jr MstStyleAlp_PadLoopCond

MstStyleAlp_AppendPadChar:
	pushw 0x1
	pushw 0xED
	pushw 0xD32
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
	lda_24 xbc, 0xeba494
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	pushw 0xED
	pushw 0xD34
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
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	ld (xsp + 14), 0x0
	jr MstStyleAlp_PadLoopCond2

MstStyleAlp_AppendPadChar2:
	pushw 0x1
	pushw 0xED
	pushw 0xD56
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
	lda_24 xbc, 0xeba494
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	ld xbc, 0x1E0008C
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
	cp xbc, 0x1E0008D
	jrl z, MstStyle_ForwardToChild
	ld xwa, (xsp + 12)
	cp xwa, 0x1E0008B
	jrl z, MstStyle_GetNameB
	cp xwa, 0x1E0008A
	jrl z, MstStyle_GetNameA
	cp xwa, 0x1C00001
	jr z, MstStyle_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, MstStyle_InheritedProc_Fallback
	cp xbc, 0x6
	jrl gt, MstStyle_InheritedProc_Fallback
	add xbc, xbc
	add xbc, 0xED0D66
	ld bc, (xbc)
	lda_24 xix, 0xfb8b6d
	jp_dri 8, 0x07, 0xF0, 0xE4

; MasterStyle event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0D66)
MstStyle_EventDispatch:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 78)
	ldw (xwa), 0x1
	ld xwa, (xiz + 74)
	ldw (xwa), 0xA
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld iy, hl
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	add wa, iy
	st16_24 0x0340c4, xwa
	jrl SeqFileAlt_ReturnZeroJmp
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle_FallbackEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
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
	muls wa, 0xA
	dec 1, wa
	st16_24 0x0340c4, xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0009
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20005
	lds32 xde, 0
	jr MstStyle_DialDown_PostEvent

MstStyle_DialDown_Decrement:
	decdi16_24 1, 213188
	ld wa, iy
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20005
	lds32 xde, 0

MstStyle_DialDown_PostEvent:
	call SendEvent
	jrl SeqFileAlt_ReturnZeroJmp

MstStyle_FallbackEvent:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle_DialUp_FallbackEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
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
	muls wa, 0xA
	sub wa, 0xA
	st16_24 0x0340c4, xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20005
	lds32 xde, 0
	jrl MstStyle_DialUp_PostEvent

MstStyle_DialUp_Increment:
	incdi16_24 1, 213188
	ld de, bc
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20005
	lds32 xde, 0
	jr MstStyle_DialUp_PostEvent

MstStyle_DialUp_CheckLimit:
	ld xwa, (xiz + 74)
	ld de, (xwa)
	ld wa, de
	exts xwa
	divs wa, 0xA
	muls wa, 0xA
	ld hl, wa
	exts xde
	divs de, 0xA
	ldto_werp DE, 0xEA
	add de, hl
	ld wa, bc
	cp bc, de
	jrl ge, SeqFileAlt_ReturnZeroJmp
	incdi16_24 1, 213188
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20005
	lds32 xde, 0

MstStyle_DialUp_PostEvent:
	call SendEvent
	jr SeqFileAlt_ReturnZeroJmp

MstStyle_DialUp_FallbackEvent:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
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
	ld xiz, 0x3E
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
	cp xbc, 0x1E0008D
	jr z, MstStyle1Grid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, MstStyle1Grid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1Grid_Epilogue
	add xwa, xwa
	add xwa, 0xED0D8A
	ld wa, (xwa)
	lda_24 xix, 0xfb8ece
	jp_dri 8, 0x07, 0xF0, 0xE0

; MstStyle1GridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0D8A)
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
	ldi_werp 0xE2, 0
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
	lda_24 xwa, 0xecfca4
	ld (xsp + 8), xwa
	ld xwa, (xix)
	ld ix, (xwa)
	muls ix, 0xA
	sub ix, 0xA
	ld wa, (xiz)
	cp wa, (xiy)
	jrl nz, MstStyle1Grid_BottomSection
	ld xwa, (xsp + 4)
	ld xiy, (xwa + 74)
	ld xwa, (xhl)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	ld hl, (xiy)
	sub hl, wa
	ld wa, (xde)
	cp wa, hl
	jr ge, MstStyle1Grid_OutOfRange
	add ix, wa
	sla ix, 3
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xE0, 0xF0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld (xsp + 10), 0x0
	jr MstStyle1Grid_PadLeft_Check

MstStyle1Grid_PadLeft_Loop:
	pushw 0x1
	pushw 0xED
	pushw 0xD74
	lda xwa, (xsp + 18)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 10)

MstStyle1Grid_PadLeft_Check:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	add wa, (xsp + 32)
	sla wa, 3
	lda_24 xbc, 0xecfca4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	pushw 0xED
	pushw 0xD76
	push xbc
	call Strcpy
	inc 8, xsp
	jr MstStyle1Grid_CheckPlayAudio

MstStyle1Grid_BottomSection:
	add ix, (xde)
	sla ix, 3
	ld xwa, (xsp + 8)
	ld_sril3 XWA, 0x07, 0xE0, 0xF0
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld (xsp + 10), 0x0
	jr MstStyle1Grid_PadLeft_CheckB

MstStyle1Grid_PadLeft_LoopB:
	pushw 0x1
	pushw 0xED
	pushw 0xD88
	lda xwa, (xsp + 18)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	incm8 1, (xsp + 10)

MstStyle1Grid_PadLeft_CheckB:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	add wa, (xsp + 32)
	sla wa, 3
	lda_24 xbc, 0xecfca4
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
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
	ld xbc, 0x1E0008C
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
	cp xbc, 0x1E0008D
	jrl z, MstStyle1Sub_ForwardToChild
	ld xwa, (xsp + 62)
	cp xwa, 0x1E0008B
	jrl z, MstStyle1Sub_GetNameB_DrawString
	cp xwa, 0x1E0008A
	jrl z, MstStyle1Sub_GetNameA
	cp xwa, 0x1C20005
	jrl z, MstStyle1Sub_HandleSubSelect
	cp xwa, 0x1C0000B
	jrl z, MstStyle1Sub_HandleScroll
	cp xwa, 0x1C00001
	jr z, MstStyle1_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, MstStyle1Sub_InheritedFallback
	cp xbc, 0x6
	jrl gt, MstStyle1Sub_InheritedFallback
	add xbc, xbc
	add xbc, 0xED0D9E
	ld bc, (xbc)
	lda_24 xix, 0xfb90b1
	jp_dri 8, 0x07, 0xF0, 0xE4

; MstStyle1 event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0D9E)
MstStyle1_EventDispatch:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 66)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 58)
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp
	ld16_24 xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, 0xecfca8
	add xbc, xwa
	ld xde, (xbc)
	st32_24 0x0340d2, xde
	ldb c, 0x0

MstStyle1Sub_CountEntries_Loop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	or xwa, xwa
	jr z, MstStyle1Sub_CountEntries_Done
	inc 1, c
	cp c, 0xFF
	jr c, MstStyle1Sub_CountEntries_Loop

MstStyle1Sub_CountEntries_Done:
	cps c, 0
	jr z, MstStyle1Sub_CountEntries_Adjust
	dec 1, c

MstStyle1Sub_CountEntries_Adjust:
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xde, 0x340C8
	add xde, xwa
	ld a, (xde)
	extz wa
	st16_24 0x0340c6, xwa
	ld xhl, (xsp + 8)
	ld xde, (xhl + 74)
	ld a, c
	extz wa
	ld (xde), wa
	ld xde, (xhl + 78)
	extz bc
	div c, 0xA
	inc 1, c
	extz bc
	ld (xde), bc
	ld xwa, xhl
	ld xbc, (xwa + 82)
	ld16_24 xwa, 0x0340c6
	extz xwa
	div wa, 0xA
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
	ld16_24 xwa, 0x0340c6
	extz xwa
	div wa, 0xA
	ldto_werp DE, 0xE2
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
	call SendEvent
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_HandleSubSelect:
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld16_24 xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, 0xecfca8
	add xbc, xwa
	ld xde, (xbc)
	st32_24 0x0340d2, xde
	ldb c, 0x0

MstStyle1Sub_SubSel_CountLoop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	or xwa, xwa
	jr z, MstStyle1Sub_SubSel_CountDone
	inc 1, c
	cp c, 0xFF
	jr c, MstStyle1Sub_SubSel_CountLoop

MstStyle1Sub_SubSel_CountDone:
	cps c, 0
	jr z, MstStyle1Sub_SubSel_Adjust
	dec 1, c

MstStyle1Sub_SubSel_Adjust:
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xde, 0x340C8
	add xde, xwa
	ld a, (xde)
	extz wa
	st16_24 0x0340c6, xwa
	ld xde, (xhl + 74)
	ld a, c
	extz wa
	ld (xde), wa
	ld xde, (xhl + 78)
	extz bc
	div c, 0xA
	inc 1, c
	extz bc
	ld (xde), bc
	ld xbc, (xhl + 82)
	ld16_24 xwa, 0x0340c6
	extz xwa
	div wa, 0xA
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000B
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1E0008F
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
	muls wa, 0xA
	dec 1, wa
	st16_24 0x0340c6, xwa
	ld16_24 xde, 0x0340c4
	extz xde
	add xbc, xde
	ld (xbc), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0009
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	jr MstStyle1Sub_DialDown_SetAutoInc

MstStyle1Sub_DialDown_Decrement:
	ld16_24 xwa, 0x0340c6
	dec 1, wa
	st16_24 0x0340c6, xwa
	ld16_24 xde, 0x0340c4
	extz xde
	add xbc, xde
	ld (xbc), a
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 58)
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_DialUp_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1E0008F
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
	add xde, 0xFFFF0000
	ld16_24 xbc, 0x0340c6
	ld wa, (xiy)
	cp wa, (xix)
	jr ge, MstStyle1Sub_DialUp_CheckLimit
	lda_24 xix, 0x0340c8
	cp hl, 0x9
	jr nz, MstStyle1Sub_DialUp_Increment
	incm 1, (xiy)
	ld xwa, (xiz)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	st16_24 0x0340c6, xwa
	ld16_24 xbc, 0x0340c4
	extz xbc
	add xix, xbc
	ld (xix), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	jr MstStyle1Sub_DialUp_SetAutoInc

MstStyle1Sub_DialUp_Increment:
	inc 1, bc
	st16_24 0x0340c6, xbc
	ld16_24 xwa, 0x0340c4
	extz xwa
	add xix, xwa
	ld (xix), c
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
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
	divs wa, 0xA
	ldto_werp WA, 0xE2
	cp hl, wa
	jrl ge, SeqFile_ReturnZeroJmp
	inc 1, bc
	st16_24 0x0340c6, xbc
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xhl, 0x340C8
	add xhl, xwa
	ld (xhl), c
	ld xwa, (xsp + 66)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 66)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)

MstStyle1Sub_DialUp_SetAutoInc:
	call SetAutoInc
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_DialUp_FallbackEvent:
	ld xwa, (xsp + 66)
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 58)
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
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
	ldw (xhl), 0xFE
	lda xbc, (xhl + 2)
	ldw (xbc), 0x23
	lda xde, (xsp + 58)
	ld wa, (xhl)
	ld (xde), wa
	ld wa, (xhl)
	add wa, 0x1E
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
	pushw 0xED
	pushw 0xD98
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 20)
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 12)
	lds32 xhl, 6
	push xhl
	pushw 0xFF
	pushw 0xF5
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
	cp xbc, 0x1E0008D
	jr z, MstStyle1SubGrid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, MstStyle1SubGrid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1SubGrid_Epilogue
	add xwa, xwa
	add xwa, 0xED0DC2
	ld wa, (xwa)
	lda_24 xix, 0xfb962a
	jp_dri 8, 0x07, 0xF0, 0xE0

; MstStyle1SubGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0DC2)
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
	ldi_werp 0xE6, 0
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
	muls hl, 0xA
	sub hl, 0xA
	ld wa, (xiz)
	cp wa, (xiy)
	jrl nz, MstStyle1SubGrid_BottomSection
	ld xwa, (xsp + 4)
	ld xiy, (xwa + 74)
	ld xwa, (xix)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	ld ix, (xiy)
	sub ix, wa
	ld wa, (xbc)
	cp wa, ix
	jr gt, MstStyle1SubGrid_OutOfRange
	add hl, wa
	exts xhl
	sll xhl, 3
	addda32_24 xhl, 213202
	ld xwa, (xhl)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ldi_berp 0xFB, 0
	jr MstStyle1SubGrid_PadLeft_Check

MstStyle1SubGrid_PadLeft_Loop:
	pushw 0x1
	pushw 0xED
	pushw 0xDAC
	lda xwa, (xsp + 14)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	inc1_berp 0xFB

MstStyle1SubGrid_PadLeft_Check:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	add wa, (xsp + 28)
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	ldto_berp A, 0xFB
	extz wa
	cp wa, bc
	jr c, MstStyle1SubGrid_PadLeft_Loop
	jr MstStyle1SubGrid_CheckPlayAudio

MstStyle1SubGrid_OutOfRange:
	pushw 0xED
	pushw 0xDAE
	push xde
	call Strcpy
	inc 8, xsp
	jr MstStyle1SubGrid_CheckPlayAudio

MstStyle1SubGrid_BottomSection:
	add hl, (xbc)
	exts xhl
	sll xhl, 3
	addda32_24 xhl, 213202
	ld xwa, (xhl)
	push xwa
	push xde
	call Strcpy
	inc 8, xsp
	ldi_berp 0xFB, 0
	jr MstStyle1SubGrid_PadLeft_CheckB

MstStyle1SubGrid_PadLeft_LoopB:
	pushw 0x1
	pushw 0xED
	pushw 0xDC0
	lda xwa, (xsp + 14)
	push xwa
	call Strncat
	lda xsp, (xsp + 10)
	inc1_berp 0xFB

MstStyle1SubGrid_PadLeft_CheckB:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 82)
	ld wa, (xwa)
	muls wa, 0xA
	sub wa, 0xA
	add wa, (xsp + 28)
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xwa, (xwa)
	push xwa
	call Strlen
	inc 4, xsp
	ldw bc, 0x10
	sub bc, hl
	ldto_berp A, 0xFB
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
	ld xbc, 0x1E0008C
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
	cp xbc, 0x1E0008D
	jrl z, MstStyle2_ForwardToChild
	ld xwa, (xsp + 52)
	cp xwa, 0x1E0008B
	jrl z, MstStyle2_GetNameB_DrawString
	cp xwa, 0x1E0008A
	jrl z, MstStyle2_GetNameA
	cp xwa, 0x1C00007
	jrl z, MstStyle2_HandleDialTurn
	cp xwa, 0x1C00002
	jrl z, MstStyle2_HandleDialStop
	cp xwa, 0x1C00001
	jr z, MstStyle1Page_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, MstStyle2_InheritedFallback
	cp xbc, 0x6
	jrl gt, MstStyle2_InheritedFallback
	add xbc, xbc
	add xbc, 0xED0E04
	ld bc, (xbc)
	lda_24 xix, 0xfb9801
	jp_dri 8, 0x07, 0xF0, 0xE4

; MstStyle1 subpage event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0E04)
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
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 56)
	ld xbc, 0x1C00018
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 56)
	ld xbc, 0x1C00017
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	lda_24 xbc, 0xecfca8
	add xbc, xwa
	ld xde, (xbc)
	st32_24 0x0340d2, xde
	ldb c, 0x0

MstStyle2_CountEntries_Loop:
	ld a, c
	extz wa
	sla wa, 3
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	or xwa, xwa
	jr z, MstStyle2_CountEntries_Done
	inc 1, c
	cp c, 0xFF
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
	ld16_24 xwa, 0x0340c6
	srl wa, 1
	inc 1, wa
	ld (xbc), wa
	ld xbc, (xhl + 86)
	ld16_24 xwa, 0x0340c6
	ld (xbc), wa
	ld xwa, (xhl + 90)
	ldw (xwa), 0x1
	ld16_24 xwa, 0x0340c6
	bit 0, wa
	jrl nz, MstStyle2_InitOdd_Setup
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	ld16_24 xwa, 0x0340c6
	cp bc, wa
	jr ule, MstStyle2_InitDone_PostEvent
	inc 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xde, (xwa + 4)
	st32_24 0x0340da, xde
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
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
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
	jrl MstStyle2_SendEvent_Done

MstStyle2_InitOdd_Setup:
	dec 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xde, (xwa + 4)
	st32_24 0x0340d6, xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
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
	ld16_24 xwa, 0x0340c6
	extz xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xde, (xwa + 4)
	st32_24 0x0340da, xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
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
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0005

MstStyle2_SendEvent_Done:
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00018
	ld xde, (xsp + 48)
	call ApFuncCall
	jrl SeqData_ReturnZero

MstStyle2_HandleSpecialEvent:
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 48)
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	call SendEvent
	jrl SeqData_ReturnZero

MstStyle2_HandleDialStop:
	ld xwa, (xsp + 56)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)
	call InheritedProc
	ld xwa, 0x142000D
	ld xbc, 0x1E20019
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
	ldto_werp WA, 0xE2
	cps wa, 0
	jr z, MstStyle2_DialDown_PageDec
	decm 1, (xix)
	ld16_24 xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00017
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
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340da, xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xbc, 0x340C8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0005
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00017
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
	ldto_werp WA, 0xE2
	cps wa, 0
	jr nz, MstStyle2_DialUp_PageInc
	incm 1, (xiy)
	ld16_24 xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0005
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00018
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
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	st16_24 0x0340bc, xwa
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	st16_24 0x0340be, xwa
	cpdm16_24 213180, xwa
	jr le, MstStyle2_DialUp_UpdateAndPost
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340da, xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xbc, 0x340C8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00018
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle2_FallbackEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1E0008F
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
	st16_24 0x0340bc, xwa
	cps wa, 1
	jrl le, MstStyle2_DialScroll_SetAutoInc
	lda xhl, (xhl + 86)
	ld xwa, (xhl)
	decm 1, (xwa)
	ld16_24 xwa, 0x0340c4
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
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340d6, xhl
	ldb c, 0x0

MstStyle2_DialScrollDown_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	addda32_24 xwa, 213202
	ld xde, (xwa + 4)
	st32_24 0x0340da, xde
	ldb c, 0x0

MstStyle2_DialScrollDown_Count2Loop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 98)
	ld wa, (xwa)
	inc 5, wa
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00017
	ld xde, (xsp + 48)
	jr MstStyle2_DialScroll_CallFunc

MstStyle2_DialScrollUp_Middle:
	cps ix, 5
	jr nz, MstStyle2_DialScrollUp_Simple
	ld xhl, (xsp + 4)
	lda xde, (xhl + 86)
	ld xwa, (xde)
	decm 1, (xwa)
	ld16_24 xwa, 0x0340c4
	extz xwa
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xhl + 94)
	ld de, (xwa)
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	jr MstStyle2_DialScrollUp_SendEvent

MstStyle2_DialScrollUp_Simple:
	dec 1, ix
	ld de, ix
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E

MstStyle2_DialScrollUp_SendEvent:
	call SendEvent
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 70)
	ld xbc, 0x1C00018
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 48)
	call SetDialUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1C00017
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
	ld xbc, 0x1E00050
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle2_DialScroll_FallbackUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1E0008F
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xde, 0x340C8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0005
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1C00018
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
	st16_24 0x0340bc, xwa
	ld xwa, (xbc + 78)
	ld wa, (xwa)
	st16_24 0x0340be, xwa
	cpdm16_24 213180, xwa
	jrl ge, MstStyle2_DialScroll_AutoInc
	ld xwa, (xix)
	incm 1, (xwa)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xiy, (xwa + 4)
	st32_24 0x0340d6, xiy
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopD:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xF4, 0xE0
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
	addda32_24 xwa, 213202
	ld xhl, (xwa + 4)
	st32_24 0x0340da, xhl
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopE:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xEC, 0xE0
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	ld xde, 0x340C8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0000
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1C00018
	ld xde, (xsp + 48)
	jr MstStyle2_DialScroll_CallApFunc

MstStyle2_DialScrollUp_SendSimple:
	ld wa, ix
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 56)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xiz + 70)
	ld xbc, 0x1C00018
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00018
	ld xde, (xsp + 48)
	call SetDialUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1C00017
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
	ldw (xhl), 0xA
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
	addda32_24 xwa, 213202
	ld xwa, (xwa)
	push xwa
	pushw 0xED
	pushw 0xDD0
	lda xwa, (xsp + 34)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 20)
	lda xwa, (xsp + 40)
	lda xbc, (xsp + 36)
	lda xde, (xsp + 18)
	lds32 xhl, 0
	push xhl
	pushw 0xFB
	pushw 0xF5
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
	pushw 0xED
	pushw 0xDD4
	push xde
	call Strcpy
	inc 8, xsp
	ld xwa, 0xED0DE6
	jr MstStyle2_NameB_Render

MstStyle2_NameB_DrawCurrent:
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xwa, (xwa)
	push xwa
	pushw 0xED
	pushw 0xDEC
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	ld xwa, 0xED0DF0
	jr MstStyle2_NameB_Render

MstStyle2_NameB_DrawLower:
	ld wa, (xbc)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, 213202
	ld xwa, (xwa)
	push xwa
	pushw 0xED
	pushw 0xDF6
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	ld xwa, 0xED0DFA

MstStyle2_NameB_Render:
	push xwa
	lda xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 36)
	ldw (xbc), 0xA
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
	pushw 0xFB
	pushw 0xF5
	call DrawString
	lda xbc, (xsp + 36)
	ldw (xbc), 0x10B
	lda xhl, (xbc + 2)
	ldw (xhl), 0x82
	lda xwa, (xsp + 40)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x2C
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x13
	ld (xwa + 6), de
	lda xde, (xsp + 12)
	lds32 xhl, 0
	push xhl
	pushw 0xFB
	pushw 0xF5
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
	ld16_24 xwa, 0x0340c4
	extz xwa
	sll xwa, 3
	ld xbc, 0xECFCA4
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	pushw 0xED
	pushw 0xE00
	lda xwa, (xsp + 26)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	lda xwa, (xsp + 40)
	lda xbc, (xsp + 36)
	lda xde, (xsp + 18)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	pushw 0xF7
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
	cp xbc, 0x1E0008D
	jrl z, MstGrid2_CellSelect
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, MstGrid2_Return
	cp xwa, 0x6
	jrl gt, MstGrid2_Return
	add xwa, xwa
	add xwa, 0xED0EC4
	ld wa, (xwa)
	lda_24 xix, 0xfba3ff
	jp_dri 8, 0x07, 0xF0, 0xE0

MstGrid2_ScrollJumpTable:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x3e, 0x63, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x1d, 0x66, 0x62, 0xfa, 0xaf, 0x3e
	.byte 0x21, 0xbf, 0x38, 0x51, 0xd9, 0xdc, 0x69, 0x2a
	.byte 0xab, 0x5e, 0x20, 0x90, 0xf1, 0x7a, 0xab, 0x02
	.byte 0xd9, 0x88, 0xe8, 0x13, 0xe8, 0x89, 0xe9, 0x81
	.byte 0xe8, 0x81, 0xe9, 0x81, 0xe2, 0xd6, 0x40, 0x03
	.byte 0x81, 0x99, 0x04, 0x22, 0xea, 0x12, 0x40, 0x0d
	.byte 0x00, 0x42, 0x01, 0x41, 0x18, 0x00, 0xe2, 0x01
	.byte 0x68, 0x2e, 0xab, 0x62, 0x20, 0x90, 0x20, 0xd8
	.byte 0x65, 0xd8, 0xf1, 0x7a, 0x7d, 0x02, 0xd9, 0x6d
	.byte 0xd9, 0x88, 0xe8, 0x13, 0xe8, 0x89, 0xe9, 0x81
	.byte 0xe8, 0x81, 0xe9, 0x81, 0xe2, 0xda, 0x40, 0x03
	.byte 0x81, 0x99, 0x04, 0x22, 0xea, 0x12, 0x40, 0x0d
	.byte 0x00, 0x42, 0x01, 0x41, 0x18, 0x00, 0xe2, 0x01
	.byte 0x1d, 0x63, 0x4a, 0xfa, 0x78, 0x54, 0x02

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
	ldi_werp 0xE2, 0
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
	addda32_24 xiy, 213206
	ld xwa, xbc
	add xwa, xwa
	add xwa, xbc
	add xwa, xwa
	ld (xsp + 16), xwa
	ld32_24 xwa, 0x0340da
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
	pushw 0xED
	pushw 0xE12
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
	addda32_24 xbc, 213206
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
	ld xwa, 0xED0E14
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
	pushw 0xED
	pushw 0xE36
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
	addda32_24 xbc, 213210
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
	ld xwa, 0xED0E38
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
	pushw 0xED
	pushw 0xE5A
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
	addda32_24 xbc, 213206
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
	ld xwa, 0xED0E5C
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
	pushw 0xED
	pushw 0xE7E
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
	addda32_24 xbc, 213210
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
	ld xwa, 0xED0E80
	jr MstGrid2_CopyFallback

MstGrid2_OutOfRange_BeyondMax:
	ld xwa, 0xED0EA2

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
	ld xbc, 0x1E0008C
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
	cp xbc, 0x1C00007
	jr z, MstStylePgCtl_HandleScroll
	cp xbc, 0x1C00001
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	lds32 xde, 1
	call SendEvent
	jr MstStylePgCtl_ReturnZero

MstStylePgCtl_HandleScroll:
	ld xwa, xiz
	call GetViewInstance
	lda xbc, (xhl + 22)
	ld xwa, (xsp + 4)
	cp xwa, 0xB
	jr nz, MstStylePgCtl_HandleScrollDown
	ld xde, xbc
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jr nz, MstStylePgCtl_ReturnZero
	incm 1, (xwa)
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	jr MstStylePgCtl_SendPageEvent

MstStylePgCtl_HandleScrollDown:
	ld xwa, (xsp + 4)
	cp xwa, 0xF
	jr nz, MstStylePgCtl_ReturnZero
	ld xde, xbc
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jr z, MstStylePgCtl_ScrollDown_Exit
	decm 1, (xwa)
	ld xwa, (xde)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E

MstStylePgCtl_SendPageEvent:
	call SendEvent
	jr MstStylePgCtl_ReturnZero

MstStylePgCtl_ScrollDown_Exit:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A000C1
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
	cp xbc, 0x1E0008D
	jrl z, TchSens_ForwardToChild
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, TchSens_GetNameB
	cp xwa, 0x1E0008A
	jrl z, TchSens_GetNameA
	cp xwa, 0x1C00001
	jr z, MstStyle2_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, TchSens_InheritedFallback
	cp xbc, 0x6
	jrl gt, TchSens_InheritedFallback
	add xbc, xbc
	add xbc, 0xED0ED2
	ld bc, (xbc)
	lda_24 xix, 0xfba81c
	jp_dri 8, 0x07, 0xF0, 0xE4

; MstStyle2 event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0ED2)
MstStyle2_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl TchSens_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, TchSens_DialDown_Fallback
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	cps hl, 4
	jr nz, TchSens_DialDown_Dec1
	dec 3, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	jr TchSens_DialDown_SendEvent

TchSens_DialDown_Dec1:
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl TchSens_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, TchSens_DialUp_Fallback
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	cps hl, 1
	jr nz, TchSens_DialUp_Inc1
	inc 3, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	jr TchSens_DialUp_SendEvent

TchSens_DialUp_Inc1:
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

TchSens_SetDialEnable:
	call SetDialEnable
	jr TchSens_ReturnZeroJmp

TchSens_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3E
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
	cp xbc, 0x1E0008D
	jrl z, TchSensGrid_CellSelect
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, TchSensGrid_ReturnZero
	cp xwa, 0x6
	jrl gt, TchSensGrid_ReturnZero
	add xwa, xwa
	add xwa, 0xED0F08
	ld wa, (xwa)
	lda_24 xix, 0xfbaa9c
	jp_dri 8, 0x07, 0xF0, 0xE0

; TchSensGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0F08)
TchSensGrid_EventDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0x8a, 0xbf, 0x0e, 0x30, 0xea, 0x89
	.byte 0xe9, 0xef, 0x00, 0xd7, 0xe6, 0xa8, 0xb0, 0x51
	.byte 0xb8, 0x02, 0x52, 0x90, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x10, 0xda, 0xd9, 0x6e, 0x0c, 0x40, 0x00, 0x01
	.byte 0x00, 0x00, 0xd9, 0xa9, 0xda, 0xaa, 0x78, 0xbe
	.byte 0x00, 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x10, 0xda
	.byte 0xdc, 0x6e, 0x0c, 0x40, 0x04, 0x01, 0x00, 0x00
	.byte 0xd9, 0xa9, 0xda, 0xaa, 0x78, 0xa8, 0x00, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x10, 0xda, 0xdd, 0x6e
	.byte 0x0c, 0x40, 0x02, 0x01, 0x00, 0x00, 0xd9, 0xa9
	.byte 0xda, 0xaa, 0x78, 0x92, 0x00, 0x90, 0x3f, 0x01
	.byte 0x00, 0x7e, 0x8c, 0x02, 0xda, 0xde, 0x7e, 0x87
	.byte 0x02, 0x40, 0x03, 0x01, 0x00, 0x00, 0xd9, 0xa9
	.byte 0xda, 0xaa, 0x68, 0x7b, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xeb, 0x8a, 0xbf
	.byte 0x0e, 0x30, 0xea, 0x89, 0xe9, 0xef, 0x00, 0xd7
	.byte 0xe6, 0xa8, 0xb0, 0x51, 0xb8, 0x02, 0x52, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x10, 0xda, 0xd9, 0x6e
	.byte 0x0c, 0x40, 0x00, 0x01, 0x00, 0x00, 0x31, 0xff
	.byte 0xff, 0xda, 0xaa, 0x68, 0x42, 0x90, 0x3f, 0x01
	.byte 0x00, 0x6e, 0x10, 0xda, 0xdc, 0x6e, 0x0c, 0x40
	.byte 0x04, 0x01, 0x00, 0x00, 0x31, 0xff, 0xff, 0xda
	.byte 0xaa, 0x68, 0x2c, 0x90, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x10, 0xda, 0xdd, 0x6e, 0x0c, 0x40, 0x02, 0x01
	.byte 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xaa, 0x68
	.byte 0x16, 0x90, 0x3f, 0x01, 0x00, 0x7e, 0x10, 0x02
	.byte 0xda, 0xde, 0x7e, 0x0b, 0x02, 0x40, 0x03, 0x01
	.byte 0x00, 0x00, 0x31, 0xff, 0xff, 0xda, 0xaa, 0x1d
	.byte 0x42, 0xf9, 0xf9, 0x78, 0xfa, 0x01, 0xba, 0x04
	.byte 0x34, 0xa2, 0x20, 0xe8, 0xcf, 0x00, 0x01, 0x00
	.byte 0x00, 0x6e, 0x33, 0xbf, 0x0e, 0x30, 0xb0, 0x02
	.byte 0x01, 0x00, 0xb8, 0x02, 0x02, 0x01, 0x00, 0xbf
	.byte 0x04, 0x31, 0xb8, 0x04, 0x61, 0x94, 0x04, 0x0b
	.byte 0xed, 0x00, 0x0b, 0xe0, 0x0e, 0x39, 0x1d, 0x72
	.byte 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x0e, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0xb6, 0x01, 0xa2, 0x20
	.byte 0xe8, 0xcf, 0x04, 0x01, 0x00, 0x00, 0x6e, 0x3b
	.byte 0xbf, 0x0e, 0x30, 0xb0, 0x02, 0x01, 0x00, 0xb8
	.byte 0x02, 0x02, 0x04, 0x00, 0xbf, 0x04, 0x31, 0xb8
	.byte 0x04, 0x61, 0x40, 0xe8, 0x0e, 0xed, 0x00, 0x94
	.byte 0x3f, 0x00, 0x00, 0x66, 0x05, 0x40, 0xe4, 0x0e
	.byte 0xed, 0x00, 0x38, 0x39, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88
	.byte 0xbf, 0x0e, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01
	.byte 0x78, 0x71, 0x01, 0xbf, 0x0e, 0x35, 0xbf, 0x04
	.byte 0x36, 0xbd, 0x02, 0x31, 0xbd, 0x04, 0x33, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0x02, 0x01, 0x00, 0x00, 0x6e
	.byte 0x2b, 0xb5, 0x02, 0x01, 0x00, 0xb1, 0x02, 0x05
	.byte 0x00, 0xb3, 0x66, 0x94, 0x04, 0x0b, 0xed, 0x00
	.byte 0x0b, 0xec, 0x0e, 0x3e, 0x1d, 0x72, 0x0a, 0xff
	.byte 0xbf, 0x0a, 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb
	.byte 0x88, 0xbf, 0x0e, 0x32, 0x41, 0x8c, 0x00, 0xe0
	.byte 0x01, 0x78, 0x30, 0x01, 0xa2, 0x20, 0xe8, 0xcf
	.byte 0x03, 0x01, 0x00, 0x00, 0x7e, 0x29, 0x01, 0xb5
	.byte 0x02, 0x01, 0x00, 0xb1, 0x02, 0x06, 0x00, 0xb3
	.byte 0x66, 0x94, 0x04, 0x0b, 0xed, 0x00, 0x0b, 0xf0
	.byte 0x0e, 0x3e, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf
	.byte 0x0e, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78
	.byte 0xfa, 0x00

TchSensGrid_CellSelect:
	lda xbc, (xsp + 14)
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
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
	pushw 0xED
	pushw 0xEF4
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C
	jrl TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_4:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_CheckCell_1_5
	cpw (xwa), 0x4
	jr nz, TchSensGrid_CheckCell_1_5
	ld xwa, 0x104
	call SndParam_LookupReadOnly
	ld xwa, 0xED0EFC
	cps hl, 0
	jr nz, TchSensGrid_Cell_1_4_Render
	ld xwa, 0xED0EF8

TchSensGrid_Cell_1_4_Render:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C
	jr TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_5:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_CheckCell_1_6
	cpw (xwa), 0x5
	jr nz, TchSensGrid_CheckCell_1_6
	ld xwa, 0x102
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xED
	pushw 0xF00
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C
	jr TchSensGrid_SendEvent

TchSensGrid_CheckCell_1_6:
	cpw (xbc), 0x1
	jr nz, TchSensGrid_ReturnZero
	cpw (xwa), 0x6
	jr nz, TchSensGrid_ReturnZero
	ld xwa, 0x103
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xED
	pushw 0xF04
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C

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
	cp xbc, 0x1E0008D
	jrl z, FSWAss_ForwardToChild
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, FSWAss_GetNameB
	cp xwa, 0x1E0008A
	jrl z, FSWAss_GetNameA
	cp xwa, 0x1C00001
	jr z, TchSens_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, FSWAss_InheritedFallback
	cp xbc, 0x6
	jrl gt, FSWAss_InheritedFallback
	add xbc, xbc
	add xbc, 0xED0F16
	ld bc, (xbc)
	lda_24 xix, 0xfbadfc
	jp_dri 8, 0x07, 0xF0, 0xE4

; TouchSensitivity event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED0F16)
TchSens_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl FSWAss_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FSWAss_DialDown_Fallback
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FSWAss_ReturnZeroJmp

FSWAss_DialDown_Fallback:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl FSWAss_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, FSWAss_DialUp_Fallback
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl FSWAss_ReturnZeroJmp

FSWAss_DialUp_Fallback:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

FSWAss_SetDialEnable:
	call SetDialEnable
	jr FSWAss_ReturnZeroJmp

FSWAss_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3E
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
	st_dri3b L, 0xFD, 0xF8, 0xFE
	push xiz
	ld xwa, xbc
	cp xbc, 0x1E0008D
	jrl z, FSWAssGrid_CellSelect
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, AudioTable_ReturnZero
	cp xwa, 0x6
	jrl gt, AudioTable_ReturnZero
	add xwa, xwa
	add xwa, 0xED1226
	ld wa, (xwa)
	lda_24 xix, 0xfbb04c
	jp_dri 8, 0x07, 0xF0, 0xE0

; FSWAssGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED1226)
FSWAssGrid_EventDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0x8a
	lda	xwa, (xsp+260)
	.byte 0xea, 0x89, 0xe9, 0xef, 0x00, 0xd7, 0xe6, 0xa8
	.byte 0xb0, 0x51, 0xb8, 0x02, 0x52, 0x90, 0x3f, 0x01
	.byte 0x00, 0x6e, 0x44, 0xda, 0xda, 0x6e, 0x40, 0x40
	.byte 0x86, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0xb4, 0x08, 0xcf
	.byte 0xcf, 0x1c, 0x7f, 0xa5, 0x08, 0x40, 0x86, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0x9e, 0x08, 0xcf, 0x61, 0xdb
	.byte 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x86, 0x28
	.byte 0x00, 0x00, 0xda, 0xaa, 0x78, 0xe5, 0x03, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x44, 0xda, 0xdb, 0x6e
	.byte 0x40, 0x40, 0x88, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x6a
	.byte 0x08, 0xcf, 0xcf, 0x1c, 0x7f, 0x5b, 0x08, 0x40
	.byte 0x88, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x54, 0x08, 0xcf
	.byte 0x61, 0xdb, 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40
	.byte 0x88, 0x28, 0x00, 0x00, 0xda, 0xaa, 0x78, 0x9b
	.byte 0x03, 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x44, 0xda
	.byte 0xdc, 0x6e, 0x40, 0x40, 0x8a, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88
	.byte 0x1e, 0x20, 0x08, 0xcf, 0xcf, 0x1c, 0x7f, 0x11
	.byte 0x08, 0x40, 0x8a, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x0a
	.byte 0x08, 0xcf, 0x61, 0xdb, 0x12, 0xf2, 0x24, 0x0f
	.byte 0xed, 0x31, 0xc3, 0x07, 0xe4, 0xec, 0x23, 0xd9
	.byte 0x12, 0x40, 0x8a, 0x28, 0x00, 0x00, 0xda, 0xaa
	.byte 0x78, 0x51, 0x03, 0x90, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x44, 0xda, 0xdd, 0x6e, 0x40, 0x40, 0x8c, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0xd6, 0x07, 0xcf, 0xcf, 0x1c
	.byte 0x7f, 0xc7, 0x07, 0x40, 0x8c, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88
	.byte 0x1e, 0xc0, 0x07, 0xcf, 0x61, 0xdb, 0x12, 0xf2
	.byte 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07, 0xe4, 0xec
	.byte 0x23, 0xd9, 0x12, 0x40, 0x8c, 0x28, 0x00, 0x00
	.byte 0xda, 0xaa, 0x78, 0x07, 0x03, 0x90, 0x3f, 0x01
	.byte 0x00, 0x6e, 0x44, 0xda, 0xde, 0x6e, 0x40, 0x40
	.byte 0x8e, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x8c, 0x07, 0xcf
	.byte 0xcf, 0x1c, 0x7f, 0x7d, 0x07, 0x40, 0x8e, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0x76, 0x07, 0xcf, 0x61, 0xdb
	.byte 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x8e, 0x28
	.byte 0x00, 0x00, 0xda, 0xaa, 0x78, 0xbd, 0x02, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x44, 0xda, 0xdf, 0x6e
	.byte 0x40, 0x40, 0x90, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x42
	.byte 0x07, 0xcf, 0xcf, 0x1c, 0x7f, 0x33, 0x07, 0x40
	.byte 0x90, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x2c, 0x07, 0xcf
	.byte 0x61, 0xdb, 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40
	.byte 0x90, 0x28, 0x00, 0x00, 0xda, 0xaa, 0x78, 0x73
	.byte 0x02, 0x90, 0x3f, 0x01, 0x00, 0x7e, 0x02, 0x07
	.byte 0xda, 0xcf, 0x08, 0x00, 0x7e, 0xfb, 0x06, 0x40
	.byte 0x80, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0xf4, 0x06, 0xcf
	.byte 0xcf, 0x1e, 0x7f, 0xe5, 0x06, 0x40, 0x80, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0xde, 0x06, 0xcf, 0x61, 0xdb
	.byte 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x80, 0x28
	.byte 0x00, 0x00, 0xda, 0xaa, 0x78, 0x25, 0x02, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f, 0x00
	.byte 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96, 0xfa
	.byte 0xeb, 0x8a
	lda	xwa, (xsp+260)
	.byte 0xea
	.long OscScope_FinalizeRender
	.byte 0xd7, 0xe6, 0xa8, 0xb0
	.byte 0x51, 0xb8, 0x02, 0x52, 0x90, 0x3f, 0x01, 0x00
	.byte 0x6e, 0x43, 0xda, 0xda, 0x6e, 0x3f, 0x40, 0x86
	.byte 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb
	.byte 0x12, 0xdb, 0x88, 0x1e, 0x85, 0x06, 0xcf, 0xd8
	.byte 0x76, 0x77, 0x06, 0x40, 0x86, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88
	.byte 0x1e, 0x70, 0x06, 0xcf, 0x69, 0xdb, 0x12, 0xf2
	.byte 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07, 0xe4, 0xec
	.byte 0x23, 0xd9, 0x12, 0x40, 0x86, 0x28, 0x00, 0x00
	.byte 0xda, 0xaa, 0x78, 0xb7, 0x01, 0x90, 0x3f, 0x01
	.byte 0x00, 0x6e, 0x43, 0xda, 0xdb, 0x6e, 0x3f, 0x40
	.byte 0x88, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x3c, 0x06, 0xcf
	.byte 0xd8, 0x76, 0x2e, 0x06, 0x40, 0x88, 0x28, 0x00
	.byte 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb
	.byte 0x88, 0x1e, 0x27, 0x06, 0xcf, 0x69, 0xdb, 0x12
	.byte 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07, 0xe4
	.byte 0xec, 0x23, 0xd9, 0x12, 0x40, 0x88, 0x28, 0x00
	.byte 0x00, 0xda, 0xaa, 0x78, 0x6e, 0x01, 0x90, 0x3f
	.byte 0x01, 0x00, 0x6e, 0x43, 0xda, 0xdc, 0x6e, 0x3f
	.byte 0x40, 0x8a, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0xf3, 0x05
	.byte 0xcf, 0xd8, 0x76, 0xe5, 0x05, 0x40, 0x8a, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0xde, 0x05, 0xcf, 0x69, 0xdb
	.byte 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x8a, 0x28
	.byte 0x00, 0x00, 0xda, 0xaa, 0x78, 0x25, 0x01, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x43, 0xda, 0xdd, 0x6e
	.byte 0x3f, 0x40, 0x8c, 0x28, 0x00, 0x00, 0x1d, 0x37
	.byte 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0xaa
	.byte 0x05, 0xcf, 0xd8, 0x76, 0x9c, 0x05, 0x40, 0x8c
	.byte 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb
	.byte 0x12, 0xdb, 0x88, 0x1e, 0x95, 0x05, 0xcf, 0x69
	.byte 0xdb, 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3
	.byte 0x07, 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x8c
	.byte 0x28, 0x00, 0x00, 0xda, 0xaa, 0x78, 0xdc, 0x00
	.byte 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x43, 0xda, 0xde
	.byte 0x6e, 0x3f, 0x40, 0x8e, 0x28, 0x00, 0x00, 0x1d
	.byte 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e
	.byte 0x61, 0x05, 0xcf, 0xd8, 0x76, 0x53, 0x05, 0x40
	.byte 0x8e, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x4c, 0x05, 0xcf
	.byte 0x69, 0xdb, 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31
	.byte 0xc3, 0x07, 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40
	.byte 0x8e, 0x28, 0x00, 0x00, 0xda, 0xaa, 0x78, 0x93
	.byte 0x00, 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x42, 0xda
	.byte 0xdf, 0x6e, 0x3e, 0x40, 0x90, 0x28, 0x00, 0x00
	.byte 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12, 0xdb, 0x88
	.byte 0x1e, 0x18, 0x05, 0xcf, 0xd8, 0x76, 0x0a, 0x05
	.byte 0x40, 0x90, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4
	.byte 0xfc, 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0x03, 0x05
	.byte 0xcf, 0x69, 0xdb, 0x12, 0xf2, 0x24, 0x0f, 0xed
	.byte 0x31, 0xc3, 0x07, 0xe4, 0xec, 0x23, 0xd9, 0x12
	.byte 0x40, 0x90, 0x28, 0x00, 0x00, 0xda, 0xaa, 0x68
	.byte 0x4b, 0x90, 0x3f, 0x01, 0x00, 0x7e, 0xda, 0x04
	.byte 0xda, 0xcf, 0x08, 0x00, 0x7e, 0xd3, 0x04, 0x40
	.byte 0x80, 0x28, 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc
	.byte 0xdb, 0x12, 0xdb, 0x88, 0x1e, 0xcc, 0x04, 0xcf
	.byte 0xcf, 0x1d, 0x73, 0xbd, 0x04, 0x40, 0x80, 0x28
	.byte 0x00, 0x00, 0x1d, 0x37, 0xd4, 0xfc, 0xdb, 0x12
	.byte 0xdb, 0x88, 0x1e, 0xb6, 0x04, 0xcf, 0x69, 0xdb
	.byte 0x12, 0xf2, 0x24, 0x0f, 0xed, 0x31, 0xc3, 0x07
	.byte 0xe4, 0xec, 0x23, 0xd9, 0x12, 0x40, 0x80, 0x28
	.byte 0x00, 0x00, 0xda, 0xaa, 0x1d, 0x8a, 0xf8, 0xf9
	.byte 0x78, 0x8f, 0x04, 0xba, 0x04, 0x34, 0xbf, 0x04
	.byte 0x35, 0xa2, 0x20, 0xe8, 0xcf, 0x86, 0x28, 0x00
	.byte 0x00, 0x6e, 0x4c
	lda	xwa, (xsp+260)
	.byte 0xb0, 0x02, 0x01, 0x00, 0xb8, 0x02, 0x02, 0x02
	.byte 0x00, 0xb8, 0x04, 0x65, 0x94, 0x20, 0xd8, 0x12
	.byte 0x1e, 0x70, 0x04, 0xdb, 0x12, 0xdb, 0xec, 0x02
	.byte 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07, 0xe4
	.byte 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0xee
	.byte 0x11, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x2f, 0x04, 0xf3
	.byte 0xfd, 0x04, 0x01, 0x33, 0xbb, 0x04, 0x31, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0x88, 0x28, 0x00, 0x00, 0x6e
	.byte 0x46, 0xb3, 0x02, 0x01, 0x00, 0xbb, 0x02, 0x02
	.byte 0x03, 0x00, 0xb1, 0x65, 0x94, 0x20, 0xd8, 0x12
	.byte 0x1e, 0x18, 0x04, 0xdb, 0x12, 0xdb, 0xec, 0x02
	.byte 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07, 0xe4
	.byte 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0xf2
	.byte 0x11, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xd7, 0x03, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0x8a, 0x28, 0x00, 0x00, 0x6e
	.byte 0x46, 0xb3, 0x02, 0x01, 0x00, 0xbb, 0x02, 0x02
	.byte 0x04, 0x00, 0xb1, 0x65, 0x94, 0x20, 0xd8, 0x12
	.byte 0x1e, 0xc8, 0x03, 0xdb, 0x12, 0xdb, 0xec, 0x02
	.byte 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07, 0xe4
	.byte 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0xf6
	.byte 0x11, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x87, 0x03, 0xa2
	.byte 0x20, 0xe8, 0xcf, 0x8c, 0x28, 0x00, 0x00, 0x6e
	.byte 0x46, 0xb3, 0x02, 0x01, 0x00, 0xbb, 0x02, 0x02
	.byte 0x05, 0x00, 0xb1, 0x65, 0x94, 0x20, 0xd8, 0x12
	.byte 0x1e, 0x78, 0x03, 0xdb, 0x12, 0xdb, 0xec, 0x02
	.byte 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07, 0xe4
	.byte 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0xfa
	.byte 0x11, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72, 0x0a
	.byte 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x37, 0x03, 0xbb
	.byte 0x02, 0x36, 0xa2, 0x20, 0xe8, 0xcf, 0x8e, 0x28
	.byte 0x00, 0x00, 0x6e, 0x45, 0xb3, 0x02, 0x01, 0x00
	.byte 0xb6, 0x02, 0x06, 0x00, 0xb1, 0x65, 0x94, 0x20
	.byte 0xd8, 0x12, 0x1e, 0x26, 0x03, 0xdb, 0x12, 0xdb
	.byte 0xec, 0x02, 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3
	.byte 0x07, 0xe4, 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00
	.byte 0x0b, 0xfe, 0x11, 0xbf, 0x0c, 0x30, 0x38, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xf3, 0xfd, 0x04, 0x01
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xe5
	.byte 0x02, 0xa2, 0x20, 0xe8, 0xcf, 0x90, 0x28, 0x00
	.byte 0x00, 0x6e, 0x45, 0xb3, 0x02, 0x01, 0x00, 0xb6
	.byte 0x02, 0x07, 0x00, 0xb1, 0x65, 0x94, 0x20, 0xd8
	.byte 0x12, 0x1e, 0xd7, 0x02, 0xdb, 0x12, 0xdb, 0xec
	.byte 0x02, 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b
	.byte 0x02, 0x12, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72
	.byte 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x96, 0x02
	.byte 0xa2, 0x20, 0xe8, 0xcf, 0x80, 0x28, 0x00, 0x00
	.byte 0x7e, 0x8f, 0x02, 0xb3, 0x02, 0x01, 0x00, 0xb6
	.byte 0x02, 0x08, 0x00, 0xb1, 0x65, 0x94, 0x20, 0xd8
	.byte 0x12, 0x1e, 0x87, 0x02, 0xdb, 0x12, 0xdb, 0xec
	.byte 0x02, 0xf2, 0x44, 0x0f, 0xed, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xec, 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b
	.byte 0x06, 0x12, 0xbf, 0x0c, 0x30, 0x38, 0x1d, 0x72
	.byte 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88
	lda	xde, (xsp+260)
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x46, 0x02

FSWAssGrid_CellSelect:
	st_dri3b A, 0xFD, 0x04, 0x01
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
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
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x120A
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
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
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x120E
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_4:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_5
	cpw (xwa), 0x4
	jr nz, FSWAssGrid_CheckCell_1_5
	ld xwa, 0x288A
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x1212
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_5:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_6
	cpw (xwa), 0x5
	jr nz, FSWAssGrid_CheckCell_1_6
	ld xwa, 0x288C
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x1216
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
	jrl AudioTable_SendEventAndContinue

FSWAssGrid_CheckCell_1_6:
	cpw (xbc), 0x1
	jr nz, FSWAssGrid_CheckCell_1_7
	cpw (xwa), 0x6
	jr nz, FSWAssGrid_CheckCell_1_7
	ld xwa, 0x288E
	call SndParam_LookupReadOnly
	extz hl
	ld wa, hl
	calr AudioTable_FindMatchIndex
	extz hl
	sla hl, 2
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x121A
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
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
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x121E
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C
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
	lda_24 xbc, 0xed0f44
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	pushw 0xED
	pushw 0x1222
	lda xwa, (xsp + 12)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x04, 0x01
	ld xbc, 0x1E0008C

AudioTable_SendEventAndContinue:
	call SendEvent

AudioTable_ReturnZero:
	lds32 xhl, 0
	pop xiz
	st_dri3b L, 0xFD, 0x08, 0x01
	ret

AudioTable_FindMatchIndex:
	ldb l, 0x0
	lda_24 xde, 0xed0f24

AudioTable_FindMatch_Loop:
	ld c, l
	extz bc
	cp_srib_rm A, 0x07, 0xE8, 0xE4
	ret z
	inc 1, l
	cp l, 0x1E
	jr c, AudioTable_FindMatch_Loop
	ret

FswAsIniFunc:
	cp xbc, 0x1C00013
	jr nz, SeqLoadFunc_ReturnZero
	dec 2, xde
	cp xde, 0x0
	jr c, SeqLoadFunc_ReturnZero
	cp xde, 0x5
	jr ugt, SeqLoadFunc_ReturnZero
	add xde, xde
	add xde, 0xED1234
	ld de, (xde)
	lda_24 xix, 0xfbb987
	jp_dri 8, 0x07, 0xF0, 0xE8
; FswAsIniFunc event dispatch (6-entry, event 0x1C00013, table 0xED1234)
FswAsIni_EventDispatch:
	.byte 0x1e, 0x06, 0x00, 0x1e, 0x1e, 0x00

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
	cp xbc, 0x1C00007
	jr z, PmemPageCtl_OK_PageSwitch
	cp xbc, 0x1C00001
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
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
	sti8_24 0x0340e2, 0x01
	ld xwa, 0x450005
	ld xbc, 0x1C00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000D
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_AdvanceTo2:
	cpi8_24 0x0340e2, 0x01
	jr nz, PmemPageCtl_OK_ResetTo1
	sti8_24 0x0340e2, 0x02
	ld xwa, 0x45000D
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_ResetTo1:
	ldw (xwa), 0x1
	ld xwa, 0x45000D
	ld xbc, 0x1C00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1C00001
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
	sti8_24 0x0340e2, 0x02
	ld xwa, 0x450005
	ld xbc, 0x1C00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000D
	ld xbc, 0x1C00001
	lds32 xde, 0

SeqLoad_PostEvent:
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotateReverse:
	cpi8_24 0x0340e2, 0x01
	jr nz, PmemPageCtl_OK_RotatePost
	decm 1, (xwa)
	ld xwa, 0x45000D
	ld xbc, 0x1C00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotatePost:
	ld xwa, 0x45000D
	ld xbc, 0x1C00001
	lds32 xde, 0
	call PostEvent
	sti8_24 0x0340e2, 0x01

SeqLoad_ReturnZeroJmp2:
	lds32 xhl, 0

PmemPageCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret
PmemPageCtl_Boundary:

AcPmExpFilterGridBoxProc:
	st_dri3b L, 0xFD, 0xDC, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x20, 0x01
	st_dri3l XBC, 0xFD, 0x24, 0x01
	ld xiz, xwa
	ld_sril XBC, (xsp + 0x0124)
	cp xbc, 0x1C00007
	jrl z, PmExpFilter_OkHandler
	ld_sril XWA, (xsp + 0x0124)
	cp xwa, 0x1E0008D
	jrl z, PmExpFilter_ForwardToView
	cp xwa, 0x1E0008B
	jrl z, PmExpFilter_GetNameB
	cp xwa, 0x1E0008A
	jrl z, PmExpFilter_GetNameA
	cp xwa, 0x1C0000F
	jrl z, PmExpFilter_Repaint
	cp xwa, 0x1C0000B
	jrl z, PmExpFilter_ShowHide
	cp xwa, 0x1C00001
	jr z, PmemPageCtl_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, PmExpFilter_DefaultInherited
	cp xbc, 0x6
	jrl gt, PmExpFilter_DefaultInherited
	add xbc, xbc
	add xbc, 0xED1420
	ld bc, (xbc)
	lda_24 xix, 0xfbbbd2
	jp_dri 8, 0x07, 0xF0, 0xE4

; IvPmemWindowPageCtl event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED1420)
PmemPageCtl_EventDispatch:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl PmExpFilter_SetDialEnable

PmExpFilter_ShowHide:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0002
	call SendEvent
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_Repaint:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	lda xbc, (xsp + 12)
	ldw (xbc), 0x3A
	lda xhl, (xbc + 2)
	ldw (xhl), 0x23
	lda xwa, (xsp + 16)
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x5C
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	lds32 xde, 0
	push xde
	pushw 0xFB
	pushw 0xF5
	ld xde, 0xED13F0
	call DrawString
	lda xbc, (xsp + 12)
	ldw (xbc), 0xE0
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
	pushw 0xFB
	pushw 0xF5
	ld xde, 0xED13FC
	call DrawString
	ld (xsp + 10), 0x0
	cpi8_24 0x0340e2, 0x01
	jrl nz, PmExpFilter_DrawCellBank2

PmExpFilter_DrawCellBank1:
	st_dri3b A, 0xFD, 0x18, 0x01
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
	lda_24 xbc, 0xed1240
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1404
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x18, 0x01
	ld xbc, 0x1E0008C
	call SendEvent
	incm8 1, (xsp + 10)
	cp (xsp + 10), 0x9
	jr c, PmExpFilter_DrawCellBank1
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xF5
	ldw (xwa + 4), 0x13B
	ldw bc, 0xC1
	ldw de, 0xF3
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
	pushw 0xED
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
	pushw 0xF7
	jrl PmExpFilter_DrawCentered

PmExpFilter_DrawCellBank2:
	st_dri3b A, 0xFD, 0x18, 0x01
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
	lda_24 xbc, 0xed1318
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1412
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x18, 0x01
	ld xbc, 0x1E0008C
	call SendEvent
	incm8 1, (xsp + 10)
	cp (xsp + 10), 0x9
	jr c, PmExpFilter_DrawCellBank2
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xF5
	ldw (xwa + 4), 0x13B
	ldw bc, 0xC1
	ldw de, 0xF3
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
	pushw 0xED
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
	pushw 0xF7

PmExpFilter_DrawCentered:
	call DrawStringCentered
	jrl SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	cpi8_24 0x0340e2, 0x02
	jr nz, PmExpFilter_DecAndUpdate
	cps hl, 2
	jr nz, PmExpFilter_DecAndUpdate
	sti8_24 0x0340e2, 0x01
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF000A
	jr PmExpFilter_SendSelEvent

PmExpFilter_DecAndUpdate:
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1
	jrl PmExpFilter_SetDialEnable
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward2
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld8_24 a, 0x0340e2
	cps a, 2
	jr nz, PmExpFilter_CheckAdvBank
	cp hl, 0xA
	jrl z, SeqLoad_ReturnZeroJmp

PmExpFilter_CheckAdvBank:
	cps a, 1
	jr nz, PmExpFilter_IncAndUpdate
	cp hl, 0xA
	jr nz, PmExpFilter_IncAndUpdate
	sti8_24 0x0340e2, 0x02
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, 0xFFFF0002
	jr PmExpFilter_SendSelEvent2

PmExpFilter_IncAndUpdate:
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
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
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1

PmExpFilter_SetDialEnable:
	call SetDialEnable
	jr SeqLoad_ReturnZeroJmp

PmExpFilter_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3E
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
	cp xwa, 0xF
	jr nz, PmExpFilter_OK_InheritedFwd
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
	lds32 xde, 0
	call SendEvent
	jr PmExpFilter_OK_InheritedFwd

PmExpFilter_OK_Navigate:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00040
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
	st_dri3b L, 0xFD, 0x24, 0x01
	ret

PmExpFilterGridCheck:
	st_dri3b L, 0xFD, 0xF8, 0xFE
	ld xwa, xbc
	cp xbc, 0x1E0008D
	jrl z, PmExpFilterCheck_CellDecode
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, SeqLoad_StoreReturnZero
	cp xwa, 0x6
	jrl gt, SeqLoad_StoreReturnZero
	add xwa, xwa
	add xwa, 0xED149A
	ld wa, (xwa)
	lda_24 xix, 0xfbc173
	jp_dri 8, 0x07, 0xF0, 0xE0

; PmExpFilterGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED149A)
PmExpFilter_EventDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0x8a, 0xf3, 0xfd, 0x00, 0x01, 0x30
	.byte 0xea, 0x89, 0xe9, 0xef, 0x00, 0xd7, 0xe6, 0xa8
	.byte 0xb0, 0x51, 0xb8, 0x02, 0x52, 0x90, 0x3f, 0x01
	.byte 0x00, 0x7e, 0x6b, 0x02, 0xc2, 0xe2, 0x40, 0x03
	.byte 0x23, 0xda, 0x88, 0xd8, 0xec, 0x02, 0xd8, 0x68
	.byte 0xcb, 0xda, 0x66, 0x23, 0xcb, 0xd9, 0x7e, 0x56
	.byte 0x02, 0xda, 0xda, 0x71, 0x51, 0x02, 0xda, 0xcf
	.byte 0x0a, 0x00, 0x7a, 0x4a, 0x02, 0xf2, 0x2e, 0x14
	.byte 0xed, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x31
	.byte 0xff, 0xff, 0xda, 0xaa, 0x78, 0x94, 0x00, 0xda
	.byte 0xda, 0x71, 0x33, 0x02, 0xda, 0xcf, 0x0a, 0x00
	.byte 0x7a, 0x2c, 0x02, 0xf2, 0x52, 0x14, 0xed, 0x31
	.byte 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0x31, 0xff, 0xff
	.byte 0xda, 0xaa, 0x68, 0x77, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xeb, 0x8a, 0xf3
	.byte 0xfd, 0x00, 0x01, 0x31, 0xea, 0x88, 0xe8, 0xef
	.byte 0x00, 0xd7, 0xe2, 0xa8, 0xb1, 0x50, 0xb9, 0x02
	.byte 0x52, 0xda, 0x88, 0xd8, 0xec, 0x02, 0xd8, 0x68
	.byte 0x91, 0x3f, 0x01, 0x00, 0x7e, 0xe8, 0x01, 0xc2
	.byte 0xe2, 0x40, 0x03, 0x23, 0xcb, 0xda, 0x66, 0x21
	.byte 0xcb, 0xd9, 0x7e, 0xda, 0x01, 0xda, 0xda, 0x71
	.byte 0xd5, 0x01, 0xda, 0xcf, 0x0a, 0x00, 0x7a, 0xce
	.byte 0x01, 0xf2, 0x2e, 0x14, 0xed, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xe0, 0x20, 0xd9, 0xa9, 0xda, 0xaa, 0x68
	.byte 0x1a, 0xda, 0xda, 0x71, 0xb9, 0x01, 0xda, 0xcf
	.byte 0x0a, 0x00, 0x7a, 0xb2, 0x01, 0xf2, 0x52, 0x14
	.byte 0xed, 0x31, 0xe3, 0x07, 0xe4, 0xe0, 0x20, 0xd9
	.byte 0xa9, 0xda, 0xaa, 0x1d, 0x42, 0xf9, 0xf9, 0x78
	.byte 0x9d, 0x01, 0xc2, 0xe2, 0x40, 0x03, 0x21, 0xc9
	.byte 0xda, 0x66, 0x67, 0xc9, 0xd9, 0x7e, 0x8f, 0x01
	.byte 0x27, 0x00, 0xf2, 0x2e, 0x14, 0xed, 0x34, 0xa2
	.byte 0x20, 0xcf, 0x8b, 0xd9, 0x12, 0xd9, 0xec, 0x02
	.byte 0xe3, 0x07, 0xf0, 0xe4, 0xf0, 0x6e, 0x41, 0xf3
	.byte 0xfd, 0x00, 0x01, 0x31, 0xb1, 0x02, 0x01, 0x00
	.byte 0xcf, 0x62, 0xdb, 0x12, 0xb9, 0x02, 0x53, 0xb7
	.byte 0x33, 0xb9, 0x04, 0x63, 0x40, 0x7a, 0x14, 0xed
	.byte 0x00, 0x9a, 0x04, 0x3f, 0x00, 0x00, 0x66, 0x05
	.byte 0x40, 0x76, 0x14, 0xed, 0x00, 0x38, 0x3b, 0x1d
	.byte 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xf3, 0xfd, 0x00, 0x01, 0x32
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x33, 0x01
	.byte 0xcf, 0x61, 0xcf, 0xcf, 0x09, 0x67, 0xaa, 0x78
	.byte 0x2d, 0x01, 0x27, 0x00, 0xf2, 0x52, 0x14, 0xed
	.byte 0x34, 0xa2, 0x20, 0xcf, 0x8b, 0xd9, 0x12, 0xd9
	.byte 0xec, 0x02, 0xe3, 0x07, 0xf0, 0xe4, 0xf0, 0x6e
	.byte 0x41, 0xf3, 0xfd, 0x00, 0x01, 0x31, 0xb1, 0x02
	.byte 0x01, 0x00, 0xcf, 0x62, 0xdb, 0x12, 0xb9, 0x02
	.byte 0x53, 0xb7, 0x33, 0xb9, 0x04, 0x63, 0x40, 0x82
	.byte 0x14, 0xed, 0x00, 0x9a, 0x04, 0x3f, 0x00, 0x00
	.byte 0x66, 0x05, 0x40, 0x7e, 0x14, 0xed, 0x00, 0x38
	.byte 0x3b, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xf3, 0xfd, 0x00
	.byte 0x01, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78
	.byte 0xd1, 0x00, 0xcf, 0x61, 0xcf, 0xcf, 0x09, 0x67
	.byte 0xaa, 0x78, 0xcb, 0x00

PmExpFilterCheck_CellDecode:
	st_dri3b C, 0xFD, 0x00, 0x01
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
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
	ld8_24 l, 0x0340e2
	dec 8, bc
	cps l, 2
	jr z, PmExpFilterCheck_AltDecode
	cps l, 1
	jrl nz, SeqLoad_StoreReturnZero
	cps wa, 2
	jrl lt, SeqLoad_StoreReturnZero
	cp wa, 0xA
	jrl gt, SeqLoad_StoreReturnZero
	lda_24 xwa, 0xed142e
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	call SndParam_LookupReadOnly
	ld xwa, 0xED148A
	cps hl, 0
	jr nz, PmExpFilterCheck_SendNameA
	ld xwa, 0xED1486

PmExpFilterCheck_SendNameA:
	push xwa
	lda xwa, (xsp + 4)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x00, 0x01
	ld xbc, 0x1E0008C
	jr PmExpFilterCheck_DoSend

PmExpFilterCheck_AltDecode:
	cps wa, 2
	jr lt, PmExpFilterCheck_PushDefault
	cp wa, 0xA
	jr gt, PmExpFilterCheck_PushDefault
	lda_24 xwa, 0xed1452
	ld_sril3 XWA, 0x07, 0xE0, 0xE4
	call SndParam_LookupReadOnly
	lda xbc, (xsp)
	ld xwa, 0xED1492
	cps hl, 0
	jr nz, PmExpFilterCheck_PushNameB
	ld xwa, 0xED148E

PmExpFilterCheck_PushNameB:
	push xwa
	push xbc
	jr PmExpFilterCheck_StrcpySend

PmExpFilterCheck_PushDefault:
	pushw 0xED
	pushw 0x1496
	push xde

PmExpFilterCheck_StrcpySend:
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	st_dri3b B, 0xFD, 0x00, 0x01
	ld xbc, 0x1E0008C

PmExpFilterCheck_DoSend:
	call SendEvent

SeqLoad_StoreReturnZero:
	lds32 xhl, 0
	st_dri3b L, 0xFD, 0x08, 0x01
	ret
PmExpFilterCheck_Boundary:

AcDispTimeSetGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1E0008D
	jrl z, DispTimeSet_CellSelectFwd
	ld xwa, (xsp + 16)
	cp xwa, 0x1E0008B
	jrl z, DispTimeSet_GetNameB
	cp xwa, 0x1E0008A
	jrl z, DispTimeSet_GetNameA
	cp xwa, 0x1C00002
	jrl z, DispTimeSet_SelectInit
	cp xwa, 0x1C00001
	jr z, PmExpFilter2_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, DispTimeSet_DefaultInherited
	cp xbc, 0x6
	jrl gt, DispTimeSet_DefaultInherited
	add xbc, xbc
	add xbc, 0xED14A8
	ld bc, (xbc)
	lda_24 xix, 0xfbc47c
	jp_dri 8, 0x07, 0xF0, 0xE4

; PmExpFilter event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED14A8)
PmExpFilter2_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x142000E
	ld xbc, 0x1E20015
	ld xde, (xsp + 12)
	call MainFuncCall
	jrl SeqSave_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, DispTimeSet_DialFallback
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl SeqSave_ReturnZeroJmp

DispTimeSet_DialFallback:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl DispTimeSet_SetDialEnabled
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, DispTimeSet_DialFallback2
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	inc 1, hl
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl SeqSave_ReturnZeroJmp

DispTimeSet_DialFallback2:
	ld xwa, xiz
	ld xbc, 0x1E00091
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
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

DispTimeSet_SetDialEnabled:
	call SetDialEnable
	jr SeqSave_ReturnZeroJmp

DispTimeSet_GetNameA:
	ld xwa, xiz
	ld xiz, 0x3E
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
	cp xbc, 0x1E0008D
	jrl z, DispTimeSetCheck_CellDecode
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, DispTimeSet_ReturnZero
	cp xwa, 0x6
	jrl gt, DispTimeSet_ReturnZero
	add xwa, xwa
	add xwa, 0xED1582
	ld wa, (xwa)
	lda_24 xix, 0xfbc735
	jp_dri 8, 0x07, 0xF0, 0xE0

; DispTimeSetGridCheck event dispatch (7-entry, events 0x1C00017-0x1C0001D, table 0xED1582)
DispTimeSet_EventDispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0x8a, 0xbf, 0x28, 0x30, 0xea, 0x89
	.byte 0xe9, 0xef, 0x00, 0xd7, 0xe6, 0xa8, 0xb0, 0x51
	.byte 0xb8, 0x02, 0x52, 0x90, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x28, 0xda, 0xda, 0x6e, 0x24, 0xbf, 0x08, 0x30
	.byte 0xf2, 0xe6, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xb8
	.byte 0x04, 0x02, 0x01, 0x00, 0xe9, 0xa9, 0xb8, 0x0e
	.byte 0x61, 0x41, 0x0c, 0x00, 0x00, 0x00, 0xb8, 0x06
	.byte 0x61, 0xe9, 0xa8, 0xb8, 0x0a, 0x61, 0x78, 0x2b
	.byte 0x02, 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x28, 0xda
	.byte 0xdb, 0x6e, 0x24, 0xbf, 0x08, 0x30, 0xf2, 0xe8
	.byte 0x40, 0x03, 0x31, 0xb0, 0x61, 0xb8, 0x04, 0x02
	.byte 0x01, 0x00, 0xe9, 0xa9, 0xb8, 0x0e, 0x61, 0x41
	.byte 0x0c, 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0xe9
	.byte 0xa8, 0xb8, 0x0a, 0x61, 0x78, 0xfd, 0x01, 0x90
	.byte 0x3f, 0x01, 0x00, 0x6e, 0x25, 0xda, 0xdc, 0x6e
	.byte 0x21, 0xbf, 0x08, 0x30, 0xf2, 0xea, 0x40, 0x03
	.byte 0x31, 0xb0, 0x61, 0xb8, 0x04, 0x02, 0x01, 0x00
	.byte 0xe9, 0xa9, 0xb8, 0x0e, 0x61, 0xe9, 0xaa, 0xb8
	.byte 0x06, 0x61, 0xe9, 0xa8, 0xb8, 0x0a, 0x61, 0x78
	.byte 0xd2, 0x01, 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x28
	.byte 0xda, 0xdd, 0x6e, 0x24, 0xbf, 0x08, 0x30, 0xf2
	.byte 0xec, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xb8, 0x04
	.byte 0x02, 0x01, 0x00, 0xe9, 0xa9, 0xb8, 0x0e, 0x61
	.byte 0x41, 0x0c, 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61
	.byte 0xe9, 0xa9, 0xb8, 0x0a, 0x61, 0x78, 0xa4, 0x01
	.byte 0x90, 0x3f, 0x01, 0x00, 0x6e, 0x28, 0xda, 0xde
	.byte 0x6e, 0x24, 0xbf, 0x08, 0x30, 0xf2, 0xee, 0x40
	.byte 0x03, 0x31, 0xb0, 0x61, 0xb8, 0x04, 0x02, 0x01
	.byte 0x00, 0xe9, 0xa9, 0xb8, 0x0e, 0x61, 0x41, 0x0c
	.byte 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0xe9, 0xa9
	.byte 0xb8, 0x0a, 0x61, 0x78, 0x76, 0x01, 0x90, 0x3f
	.byte 0x01, 0x00, 0x7e, 0xaf, 0x04, 0xda, 0xdf, 0x7e
	.byte 0xaa, 0x04, 0xbf, 0x08, 0x30, 0xf2, 0xf0, 0x40
	.byte 0x03, 0x31, 0xb0, 0x61, 0xb8, 0x04, 0x02, 0x01
	.byte 0x00, 0xe9, 0xa9, 0xb8, 0x0e, 0x61, 0x41, 0x0c
	.byte 0x00, 0x00, 0x00, 0xb8, 0x06, 0x61, 0xe9, 0xa9
	.byte 0xb8, 0x0a, 0x61, 0x78, 0x46, 0x01, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0
	.byte 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xeb
	.byte 0x8a, 0xbf, 0x28, 0x35, 0xea, 0x88, 0xe8, 0xef
	.byte 0x00, 0xd7, 0xe2, 0xa8, 0xb5, 0x50, 0xda, 0x8e
	.byte 0xbd, 0x02, 0x56, 0x95, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x2b, 0xde, 0xda, 0x6e, 0x27, 0xbf, 0x08, 0x30
	.byte 0xf2, 0xe6, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xb8
	.byte 0x04, 0x02, 0x01, 0x00, 0x41, 0xff, 0xff, 0xff
	.byte 0xff, 0xb8, 0x0e, 0x61, 0x41, 0x0c, 0x00, 0x00
	.byte 0x00, 0xb8, 0x06, 0x61, 0xe9, 0xa8, 0xb8, 0x0a
	.byte 0x61, 0x78, 0xf0, 0x00, 0x95, 0x3f, 0x01, 0x00
	.byte 0x6e, 0x2b, 0xde, 0xdb, 0x6e, 0x27, 0xbf, 0x08
	.byte 0x30, 0xf2, 0xe8, 0x40, 0x03, 0x31, 0xb0, 0x61
	.byte 0xb8, 0x04, 0x02, 0x01, 0x00, 0x41, 0xff, 0xff
	.byte 0xff, 0xff, 0xb8, 0x0e, 0x61, 0x41, 0x0c, 0x00
	.byte 0x00, 0x00, 0xb8, 0x06, 0x61, 0xe9, 0xa8, 0xb8
	.byte 0x0a, 0x61, 0x78, 0xbf, 0x00, 0x95, 0x3f, 0x01
	.byte 0x00, 0x6e, 0x28, 0xde, 0xdc, 0x6e, 0x24, 0xbf
	.byte 0x08, 0x30, 0xf2, 0xea, 0x40, 0x03, 0x31, 0xb0
	.byte 0x61, 0xb8, 0x04, 0x02, 0x01, 0x00, 0x41, 0xff
	.byte 0xff, 0xff, 0xff, 0xb8, 0x0e, 0x61, 0xe9, 0xaa
	.byte 0xb8, 0x06, 0x61, 0xe9, 0xa8, 0xb8, 0x0a, 0x61
	.byte 0x78, 0x91, 0x00, 0x95, 0x3f, 0x01, 0x00, 0x6e
	.byte 0x2a, 0xde, 0xdd, 0x6e, 0x26, 0xbf, 0x08, 0x30
	.byte 0xf2, 0xec, 0x40, 0x03, 0x31, 0xb0, 0x61, 0xb8
	.byte 0x04, 0x02, 0x01, 0x00, 0x41, 0xff, 0xff, 0xff
	.byte 0xff, 0xb8, 0x0e, 0x61, 0x41, 0x0c, 0x00, 0x00
	.byte 0x00, 0xb8, 0x06, 0x61, 0xe9, 0xa9, 0xb8, 0x0a
	.byte 0x61, 0x68, 0x61, 0xbf, 0x08, 0x30, 0xb8, 0x04
	.byte 0x31, 0xb8, 0x06, 0x33, 0xb8, 0x0a, 0x32, 0xb8
	.byte 0x0e, 0x34, 0x95, 0x3f, 0x01, 0x00, 0x6e, 0x23
	.byte 0xde, 0xde, 0x6e, 0x1f, 0xf2, 0xee, 0x40, 0x03
	.byte 0x35, 0xb0, 0x65, 0xb1, 0x02, 0x01, 0x00, 0x41
	.byte 0xff, 0xff, 0xff, 0xff, 0xb4, 0x61, 0x41, 0x0c
	.byte 0x00, 0x00, 0x00, 0xb3, 0x61, 0xe9, 0xa9, 0xb2
	.byte 0x61, 0x68, 0x29, 0x95, 0x3f, 0x01, 0x00, 0x7e
	.byte 0x62, 0x03, 0xde, 0xdf, 0x7e, 0x5d, 0x03, 0xf2
	.byte 0xf0, 0x40, 0x03, 0x35, 0xb0, 0x65, 0xb1, 0x02
	.byte 0x01, 0x00, 0x41, 0xff, 0xff, 0xff, 0xff, 0xb4
	.byte 0x61, 0x41, 0x0c, 0x00, 0x00, 0x00, 0xb3, 0x61
	.byte 0xe9, 0xa9, 0xb2, 0x61, 0x1d, 0x8a, 0xfe, 0xf9
	.byte 0x78, 0x39, 0x03, 0xf2, 0xe6, 0x40, 0x03, 0x30
	.byte 0xba, 0x0e, 0x35, 0xa2, 0xf0, 0x6e, 0x40, 0xbf
	.byte 0x28, 0x30, 0xb0, 0x02, 0x01, 0x00, 0xb8, 0x02
	.byte 0x02, 0x02, 0x00, 0xbf, 0x1e, 0x31, 0xb8, 0x04
	.byte 0x61, 0xa5, 0x20, 0xe8, 0xee, 0x02, 0x42, 0xb6
	.byte 0x14, 0xed, 0x00, 0xe8, 0x82, 0xa2, 0x20, 0x38
	.byte 0x0b, 0xed, 0x00, 0x0b, 0x52, 0x15, 0x39, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x28, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xe9, 0x02, 0xf2
	.byte 0xe8, 0x40, 0x03, 0x30, 0xa2, 0xf0, 0x6e, 0x40
	.byte 0xbf, 0x28, 0x30, 0xb0, 0x02, 0x01, 0x00, 0xb8
	.byte 0x02, 0x02, 0x03, 0x00, 0xbf, 0x1e, 0x31, 0xb8
	.byte 0x04, 0x61, 0xa5, 0x20, 0xe8, 0xee, 0x02, 0x42
	.byte 0xb6, 0x14, 0xed, 0x00
	.byte 0xe8, 0x82, 0xa2, 0x20
	.byte 0x38, 0x0b, 0xed, 0x00
	.byte 0x0b, 0x56, 0x15, 0x39
	.byte 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x28, 0x32
	.byte 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xa0, 0x02
	.byte 0xf2, 0xea, 0x40, 0x03, 0x31, 0xf2, 0xb6, 0x14
	.byte 0xed, 0x30, 0xbf, 0x04, 0x60, 0xa2, 0xf1, 0x6e
	.byte 0x3e, 0xbf, 0x28, 0x30, 0xb0, 0x02, 0x01, 0x00
	.byte 0xb8, 0x02, 0x02, 0x04, 0x00, 0xbf, 0x1e, 0x31
	.byte 0xb8, 0x04, 0x61, 0xa5, 0x20, 0xe8, 0xee, 0x02
	.byte 0xaf, 0x04, 0x22, 0xe8, 0x82, 0xa2, 0x20, 0x38
	.byte 0x0b, 0xed, 0x00, 0x0b, 0x5a, 0x15, 0x39, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x28, 0x32, 0x41
	.byte 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x51, 0x02, 0xf2
	.byte 0xec, 0x40, 0x03, 0x30, 0xa2, 0xf0, 0x6e, 0x3e
	.byte 0xbf, 0x28, 0x30, 0xb0, 0x02, 0x01, 0x00, 0xb8
	.byte 0x02, 0x02, 0x05, 0x00, 0xbf, 0x1e, 0x31, 0xb8
	.byte 0x04, 0x61, 0xa5, 0x20, 0xe8, 0xee, 0x02, 0xaf
	.byte 0x04, 0x22, 0xe8, 0x82, 0xa2, 0x20, 0x38, 0x0b
	.byte 0xed, 0x00, 0x0b, 0x5e, 0x15, 0x39, 0x1d, 0x72
	.byte 0x0a, 0xff, 0xbf, 0x0c, 0x37, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0xbf, 0x28, 0x32, 0x41, 0x8c
	.byte 0x00, 0xe0, 0x01, 0x78, 0x0a, 0x02, 0xf2, 0xee
	.byte 0x40, 0x03, 0x36, 0xbf, 0x28, 0x33, 0xbf, 0x1e
	.byte 0x34, 0xbb, 0x02, 0x30, 0xbb, 0x04, 0x31, 0xa2
	.byte 0xf6, 0x6e, 0x36, 0xb3, 0x02, 0x01, 0x00, 0xb0
	.byte 0x02, 0x06, 0x00, 0xb1, 0x64, 0xa5, 0x20, 0xe8
	.byte 0xee, 0x02, 0xaf, 0x04, 0x21, 0xe8, 0x81, 0xa1
	.byte 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0x62, 0x15
	.byte 0x3c, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x28
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0xbf
	.byte 0x01, 0xf2, 0xf0, 0x40, 0x03, 0x36, 0xa2, 0xf6
	.byte 0x7e, 0xb9, 0x01, 0xb3, 0x02, 0x01, 0x00, 0xb0
	.byte 0x02, 0x07, 0x00, 0xb1, 0x64, 0xa5, 0x20, 0xe8
	.byte 0xee, 0x02, 0xaf, 0x04, 0x21, 0xe8, 0x81, 0xa1
	.byte 0x20, 0x38, 0x0b, 0xed, 0x00, 0x0b, 0x66, 0x15
	.byte 0x3c, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0c, 0x37
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf, 0x28
	.byte 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78, 0x7f
	.byte 0x01

DispTimeSetCheck_CellDecode:
	lda xhl, (xsp + 40)
	ld xwa, xde
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xhl), wa
	lda xwa, (xhl + 2)
	ld (xwa), de
	lda xbc, (xsp + 30)
	ld (xhl + 4), xbc
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow3
	cpw (xwa), 0x2
	jr nz, DispTimeSetCheck_TryRow3
	ld8_24 a, 0x0340e6
	extz wa
	sla wa, 2
	lda_24 xde, 0xed14b6
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x156A
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow3:
	lda_24 xde, 0xed14b6
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow4
	cpw (xwa), 0x3
	jr nz, DispTimeSetCheck_TryRow4
	ld8_24 a, 0x0340e8
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x156E
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow4:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow5
	cpw (xwa), 0x4
	jr nz, DispTimeSetCheck_TryRow5
	ld8_24 a, 0x0340ea
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1572
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow5:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow6
	cpw (xwa), 0x5
	jr nz, DispTimeSetCheck_TryRow6
	ld8_24 a, 0x0340ec
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1576
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jr DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow6:
	cpw (xhl), 0x1
	jr nz, DispTimeSetCheck_TryRow7
	cpw (xwa), 0x6
	jr nz, DispTimeSetCheck_TryRow7
	ld8_24 a, 0x0340ee
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x157A
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jr DispTimeSet_SendEventReturn

DispTimeSetCheck_TryRow7:
	cpw (xhl), 0x1
	jr nz, DispTimeSet_ReturnZero
	cpw (xwa), 0x7
	jr nz, DispTimeSet_ReturnZero
	ld8_24 a, 0x0340f0
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE8, 0xE0
	push xwa
	pushw 0xED
	pushw 0x157E
	push xbc
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C

DispTimeSet_SendEventReturn:
	call SendEvent

DispTimeSet_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 44)
	ret

DispTimeSetOKFunc:
	cp xbc, 0x1C00007
	jr nz, DispTimeSetOK_ReturnZero
	ld xwa, 0x142000E
	ld xbc, 0x1E20014
	call MainFuncCall

DispTimeSetOK_ReturnZero:
	lds32 xhl, 0
	ret

MainTimeFlashFunc:
	cp xbc, 0x1E20015
	jr z, MainTimeFlash_DispatchCmd
	cp xbc, 0x1E20014
	jr nz, MainTimeFlash_ReturnZero
	stdi8 32578, 40
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call ApPostEvent
	lds wa, 5
	call CtrlPanel_IndicatorJumpTable
	stdi8 32578, 35
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
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
	cp xwa, 0x1C00001
	jr z, NormScreen_InitHandler
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr NormScreen_Epilogue

NormScreen_InitHandler:
	ld xwa, xiz
	call GetViewInstance
	cpi8_24 0x0340e6, 0x00
	jr z, NormScreen_ClearBit
	ldda8 a, 36232
	extz wa
	bit 0, wa
	jr z, NormScreen_ClearBit
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 36
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	resda 0, 36232

NormScreen_ClearBit:
	resda 0, 36232
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
	cp xbc, 0x1C00007
	jrl z, IvWindowPgCtl_OkHandler
	cp xbc, 0x1C20006
	jrl z, IvWindowPgCtl_PageChanged
	cp xbc, 0x1C00002
	jr z, IvWindowPgCtl_Deselect
	cp xbc, 0x1C00001
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
	ld xwa, 0xC0
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20004
	call SendEvent
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_Deselect:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x5
	jr ge, IvWindowPgCtl_DisableFunc
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_DisableFunc:
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
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
	cp xwa, 0xF
	jrl z, IvWindowPgCtl_JumpToEnd
	cp xwa, 0x8F
	jrl nz, IvWindowPgCtl_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x4
	jr ge, IvWindowPgCtl_TryNextPage
	incm 1, (xwa)
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	jr IvWindowPgCtl_SendPageEvent

IvWindowPgCtl_TryNextPage:
	cpw (xwa), 0x4
	jr nz, IvWindowPgCtl_DisableAll
	ld xwa, 0xC0
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
	ld xbc, 0x1E000AB
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E

IvWindowPgCtl_SendPageEvent:
	call SendEvent
	jrl IvWindowPgCtl_ReturnZero

IvWindowPgCtl_DisableAll:
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 0

UI_MainFuncCall_Execute:
	call MainFuncCall
	jr IvWindowPgCtl_ReturnZero

IvWindowPgCtl_JumpToEnd:
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, IvWindowPgCtl_JumpToStart
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x3
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x3
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E
	jr IvWindowPgCtl_DoSendEvent

IvWindowPgCtl_JumpToStart:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x1
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x1
	ld xwa, 0x1400001
	ld xbc, 0x1E000AB
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001E

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
	cp xwa, 0x1C0001E
	jrl z, IvPageOverWr_PageChanged
	cp xwa, 0x1C20004
	jr z, IvPageOverWr_PageSelect
	cp xwa, 0x1E0003A
	jr z, IvPageOverWr_GetName
	cp xwa, 0x1C0000D
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
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jrl IvPageOverWr_SendAndReturn

IvPageOverWr_GetName:
	pushw 0xED
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
	ld xbc, 0x1E00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageSelect2
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00002
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
	ld xbc, 0x1C00001
	lds32 xde, 0
	jr IvPageOverWr_SendAndReturn

IvPageOverWr_PageChanged:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1E00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageChanged2
	ld xwa, (xiz + 24)
	ld xbc, 0x1C00002
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
	ld xbc, 0x1C00001
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
	cp xbc, 0x1C00007
	jr z, PmNaming_HandleKeyPress
	cp xbc, 0x1E0007C
	jr z, PmNaming_GetKeyLayout
	cp xbc, 0x1E00084
	jrl z, PmBankNamingCheck_Ret
	cp xbc, 0x1E0003A
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
	cp xwa, 0xB
	jr nz, PmNaming_HandleF_Confirm
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	cps l, 0
	jr z, PmNaming_HandleF_Confirm
	call GetNamingWindowID
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0003A
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
	ld xbc, 0x1E0003A
	call SendEvent
	lda xwa, (xsp + 4)
	push xwa
	pushw 0x0
	pushw 0xF9A2
	call Strcpy
	inc 8, xsp
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D1
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call PostEvent

PmNaming_HandleF_Confirm:
	ld xwa, (xsp + 22)
	cp xwa, 0xF
	jr nz, PmBankNamingCheck_Ret
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D1
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
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
	cp xbc, 0x1C00007
	jr z, PmBankNaming_HandleKeyPress
	cp xbc, 0x1E0007C
	jr z, PmBankNaming_GetKeyLayout
	cp xbc, 0x1E00084
	jrl z, MssNameFunc_CleanupRet
	cp xbc, 0x1E0003A
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
	cp xwa, 0xB
	jr nz, PmBankNaming_HandleF_Confirm
	call GetNamingWindowID
	ld xwa, xhl
	lda xde, (xsp + 4)
	ld xbc, 0x1E0003A
	call SendEvent
	call BitMapOut_PrepareRender_CheckBit1
	ld a, l
	lda xbc, (xsp + 4)
	call BitMapOut_UpdateWidget_Finalize
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D1
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call PostEvent

PmBankNaming_HandleF_Confirm:
	ld xwa, (xsp + 22)
	cp xwa, 0xF
	jr nz, MssNameFunc_CleanupRet
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D1
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
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
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jrl lt, MssName_ReturnZero
	cp xbc, 0x9
	jrl gt, MssName_ReturnZero
	add xbc, xbc
	add xbc, 0xED15AC
	ld bc, (xbc)
	lda_24 xix, 0xfbd32d
	jp_dri 8, 0x07, 0xF0, 0xE4
; MssNameFunc event dispatch (10-entry, event 0x1C00013, table 0xED15AC)
MssName_EventDispatch:
	.byte 0xea, 0x8e, 0xbe, 0x0e, 0x31, 0xa1, 0x20, 0xe8
	.byte 0xe0, 0x6e, 0x13, 0x0b, 0xed, 0x00, 0x0b, 0x96
	.byte 0x15, 0xae, 0x12, 0x20, 0x38, 0x1d, 0x4d, 0x0f
	.byte 0xff, 0xef, 0x60, 0x78, 0x81, 0x00, 0xe8, 0x69
	.byte 0xe8, 0xcf, 0x20, 0x03, 0x00, 0x00, 0x62, 0x04
	.byte 0xe8, 0xaa, 0xb1, 0x60, 0xa1, 0x20, 0xe8, 0x69
	.byte 0x1d, 0x97, 0x6e, 0xfb, 0xae, 0x0e, 0x20, 0xe8
	.byte 0x69, 0xeb, 0xcf, 0xff, 0xff, 0xff, 0xff, 0x66
	.byte 0x2b, 0x0b, 0x10, 0x00, 0x1d, 0x97, 0x6e, 0xfb
	.byte 0x3b, 0xae, 0x12, 0x20, 0x38, 0x1d, 0xf3, 0x0c
	.byte 0xff, 0x0b, 0x02, 0x00, 0x0b, 0x20, 0x00, 0xae
	.byte 0x12, 0x20, 0xb8, 0x10, 0x30, 0x38, 0x1d, 0xe9
	.byte 0x28, 0xff, 0xbf, 0x12, 0x37, 0x40, 0xa4, 0x15
	.byte 0xed, 0x00, 0x68, 0x25, 0xe8, 0xee, 0x02, 0xe8
	.byte 0xc8, 0x00, 0x70, 0x98, 0x00, 0xa0, 0x21, 0x89
	.byte 0x2a, 0x21, 0xd8, 0x12, 0x28, 0xb9, 0x2b, 0x30
	.byte 0x38, 0xae, 0x12, 0x20, 0x38, 0x1d, 0xf3, 0x0c
	.byte 0xff, 0xbf, 0x0a, 0x37, 0x40, 0xa8, 0x15, 0xed
	.byte 0x00, 0x38, 0xae, 0x12, 0x20, 0x38, 0x1d, 0x1d
	.byte 0x09, 0xff, 0xef, 0x60, 0xb3, 0x00, 0x00, 0xaf
	.byte 0x04, 0x23, 0x68, 0x17, 0xeb, 0xa9, 0x68, 0x13
	.byte 0x43, 0x00, 0x02, 0x00, 0x00, 0x68, 0x0c, 0xf1
	.byte 0x56, 0x8d, 0x33, 0x68, 0x06, 0xeb, 0xaa, 0x68
	.byte 0x02

MssName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret
MssName_Boundary:

AcPmBkNoBoxProc:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C0001C
	jr z, AcPmBkNoBox_Match
	cp xbc, 0x1C0000C
	jr z, AcPmBkNoBox_ShowHide
	cp xbc, 0x1C0000B
	jr z, AcPmBkNoBox_ShowHide
	cp xbc, 0x1C00002
	jr z, AcPmBkNoBox_Focus
	cp xbc, 0x1C00001
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
	pushw 0xED
	pushw 0x15C0
	push xde
	call Strcpy
	inc 8, xsp
	jr AcPmBkNoBox_SendConfirm

AcPmBkNoBox_FormatBankNo:
	dec 1, bc
	ld wa, bc
	exts xwa
	divs wa, 0x8
	ldto_werp WA, 0xE2
	inc 1, wa
	pushw wa
	exts xbc
	divs bc, 0x8
	inc 1, bc
	pushw bc
	pushw 0xED
	pushw 0x15CA
	push xde
	call Audio_SendCommand
	lda xsp, (xsp + 12)

AcPmBkNoBox_SendConfirm:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	call SendEvent

UI_AcPmBkNoBoxProc_Return:
	lds32 xhl, 0

AcPmBkNoBox_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret
AcPmBkNoBox_Boundary:

AcBkNoBoxProc:
	st_dri3b L, 0xFD, 0xFC, 0xFE
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xFD, 0x04, 0x01
	cp xbc, 0x1C0001C
	jr z, AcBkNoBox_Match
	cp xbc, 0x1C0000C
	jr z, AcBkNoBox_ShowHide
	cp xbc, 0x1C0000B
	jr z, AcBkNoBox_ShowHide
	cp xbc, 0x1C00002
	jr z, AcBkNoBox_Focus
	cp xbc, 0x1C00001
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
	pushw 0xED
	pushw 0x15D2
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1C0000F
	call SendEvent

UI_AcBkNoBoxProc_Return:
	lds32 xhl, 0

AcBkNoBox_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x04, 0x01
	ret
AcBkNoBox_Boundary:

MsaModeScreenProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xbc
	ld (xsp + 24), xwa
	cp xiz, 0x1C00007
	jrl z, MsaMode_OK
	cp xiz, 0x1C0000E
	jrl z, MsaMode_Select
	cp xiz, 0x1C0000D
	jrl z, MsaMode_Paint
	cp xiz, 0x1C0001C
	jr z, MsaMode_Match
	cp xiz, 0x1C0000B
	jr z, MsaMode_Show
	cp xiz, 0x1C00001
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
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jr MsaMode_DispatchSelect

MsaMode_Paint:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	ld xbc, 0x1C0000E
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
	lda_24 xbc, 0xecfdb0
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	lda xbc, (xsp + 8)
	call GetEditSwPoint
	lda xwa, (xsp + 12)
	lda xhl, (xsp + 8)
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xB
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xB
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, MsaMode_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr MsaMode_Select_DrawHighlight1

MsaMode_Select_RightSide:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

MsaMode_Select_DrawHighlight1:
	pushw 0xF5
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	lda_24 xbc, 0xecfdb0
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	lda xbc, (xsp + 8)
	call GetEditSwPoint
	lda xwa, (xsp + 12)
	lda xhl, (xsp + 8)
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xB
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xB
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, MsaMode_Select_RightSide2
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr MsaMode_Select_DrawHighlight2

MsaMode_Select_RightSide2:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

MsaMode_Select_DrawHighlight2:
	pushw 0xF2
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
	cp xwa, 0x8B
	jr z, MsaMode_OK_Cmd8B
	cp xwa, 0x8A
	jr z, MsaMode_OK_Cmd8A
	cp xwa, 0x89
	jr z, MsaMode_OK_Cmd89
	cp xwa, 0xF
	jr nz, MsaMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, MsaMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00040
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
	st_dri3b L, 0xFD, 0xE8, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x14, 0x01
	ld xiz, xbc
	st_dri3l XWA, 0xFD, 0x18, 0x01
	cp xiz, 0x1C00007
	jrl z, PmemMode_OK
	cp xiz, 0x1C0000E
	jrl z, PmemMode_Select
	cp xiz, 0x1C0000D
	jrl z, PmemMode_Paint
	cp xiz, 0x1C0001C
	jr z, PmemMode_Match
	cp xiz, 0x1C0000B
	jr z, PmemMode_Show
	cp xiz, 0x1C00001
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
	ld xbc, 0x1C0000E
	lds32 xde, 0
	jrl PmemMode_DispatchSelect

PmemMode_Paint:
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld_sril XDE, (xsp + 0x0114)
	call InheritedProc
	st_dri3b W, 0xFD, 0x0C, 0x01
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xF5
	ldw (xwa + 4), 0x13B
	ldw bc, 0xC1
	ldw de, 0xF3
	call DrawDesignBox
	st_dri3b B, 0xFD, 0x0C, 0x01
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	st_dri3b C, 0xFD, 0x08, 0x01
	ld (xhl), bc
	ld bc, (xde + 2)
	ld wa, (xde + 6)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	inc 1, bc
	ld (xhl + 2), bc
	pushw 0xED
	pushw 0x15D6
	lda xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b A, 0xFD, 0x08, 0x01
	lda xde, (xsp + 8)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	call DrawStringCentered
	ld_sril XWA, (xsp + 0x0118)
	ld xbc, 0x1C0000E
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
	lda_24 xbc, 0xecfdb4
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x08, 0x01
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xB
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xB
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmemMode_Select_RightSide
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr PmemMode_Select_DrawHighlight1

PmemMode_Select_RightSide:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

PmemMode_Select_DrawHighlight1:
	pushw 0xF5
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 36)
	lda_24 xbc, 0xecfdb4
	ld wa, (xwa)
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x08, 0x01
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x0C, 0x01
	st_dri3b C, 0xFD, 0x08, 0x01
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xB
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0xB
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, PmemMode_Select_RightSide2
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr PmemMode_Select_DrawHighlight2

PmemMode_Select_RightSide2:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

PmemMode_Select_DrawHighlight2:
	pushw 0xF2
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
	cp xwa, 0x8B
	jr z, PmemMode_OK_Cmd8B
	cp xwa, 0x89
	jr z, PmemMode_OK_Cmd89
	cp xwa, 0xF
	jr nz, PmemMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E0007A
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmemMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E00079
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
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00040
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
	st_dri3b L, 0xFD, 0x18, 0x01
	ret
PmemMode_Boundary:

AcPmBkEditBoxProc:
	st_dri3b L, 0xFD, 0xCE, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x2E, 0x01
	st_dri3l XWA, 0xFD, 0x32, 0x01
	cp xbc, 0x1C00007
	jrl z, AcPmBkEdit_OK
	cp xbc, 0x1C00018
	jrl z, AcPmBkEdit_AutoIncDown
	cp xbc, 0x1C0001A
	jrl z, AcPmBkEdit_ScrollDown
	cp xbc, 0x1C00017
	jrl z, AcPmBkEdit_ScrollUp
	cp xbc, 0x1C00019
	jrl z, AcPmBkEdit_AutoIncUp
	cp xbc, 0x1C0001D
	jrl z, AcPmBkEdit_Assign
	cp xbc, 0x1C0000C
	jrl z, AcPmBkEdit_ShowHide
	cp xbc, 0x1C0000B
	jrl z, AcPmBkEdit_ShowHide
	cp xbc, 0x1E0003D
	jrl z, AcPmBkEdit_AddDelta
	cp xbc, 0x1E0003B
	jrl z, AcPmBkEdit_SetValue
	lda xwa, (xsp + 46)
	ld (xsp + 8), xwa
	cp xbc, 0x1C20003
	jrl z, AcPmBkEdit_BankEdit
	cp xbc, 0x1C20002
	jr z, AcPmBkEdit_BankChanged
	cp xbc, 0x1E0003A
	jrl nz, AcPmBkEdit_Default
	ld_sril XWA, (xsp + 0x012e)
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xwa, (xhl + 54)
	ld xwa, (xwa)
	ldb w, 0x0
	extz xwa
	st_dri3l XWA, 0xFD, 0x2E, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1E20010
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
	pushw 0xED
	pushw 0x15E0
	ld xwa, (xsp + 14)
	push xwa
	call Audio_SendCommand
	ld_sril XWA, (xsp + 0x0138)
	inc 1, xwa
	push xwa
	lda xwa, (xsp + 60)
	push xwa
	call Strcat
	lda xsp, (xsp + 18)
	lda xde, (xsp + 46)
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1C0000F
	call SendEvent
	ldi_berp 0xFB, 1

AcPmBkEdit_BankChanged_UpdateLoop:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	sll a, 3
	add_berp A, 0xFB
	ldb w, 0x0
	extz xwa
	st_dri3l XWA, 0xFD, 0x2E, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1E20012
	ld_sril XDE, (xsp + 0x012e)
	call MainFuncCall
	inc1_berp 0xFB
	cp_erpb 0xFB, 0x08
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
	add a, 0x5A
	extz wa
	ld (xbc + 2), wa
	lda xwa, (xsp + 16)
	ldw (xwa + 2), 0x55
	ldw (xwa + 6), 0xEB
	ldw (xwa), 0x22
	ldw (xwa + 4), 0x12C
	ld a, (xde)
	dec 1, a
	and a, 0x7
	inc 1, a
	extz wa
	pushw wa
	pushw 0xED
	pushw 0x15EA
	ld xwa, (xsp + 14)
	push xwa
	call Audio_SendCommand
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
	pushw 0xF5
	ld xbc, xde
	ld xde, xhl
	jr AcPmBkEdit_BankEdit_DrawCall

AcPmBkEdit_BankEdit_DrawDiff:
	lds32 xbc, 0
	push xbc
	pushw 0xFF
	pushw 0xF5
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00044
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1E00044
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
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1E00046
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
	ld xbc, 0x1E00045
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
	ld xbc, 0x1C0000F
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
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003D
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollUp:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003D
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollDown:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003E
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003D
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
	ld xbc, 0x1E0003C
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1E0003F
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cpl_werp 0xEE
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1E0003D
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
	cp xwa, 0xA
	jr z, AcPmBkEdit_OK_Load
	cp xwa, 0x9
	jrl nz, AcPmBkEdit_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D3
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	jrl AcPmBkEdit_OK_NavComplete

AcPmBkEdit_OK_Load:
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	cps l, 0
	jr z, AcPmBkEdit_OK_LoadEmpty
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D2
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
	lds32 xde, 1
	call PostEvent
	jr AcPmBkEdit_ReturnZero

AcPmBkEdit_OK_LoadEmpty:
	stdi8 32578, 73
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call ApPostEvent
	jr AcPmBkEdit_ReturnZero

AcPmBkEdit_OK_SaveDelete:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000D0
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1E000AA
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	jr z, AcPmBkEdit_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009A
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
	st_dri3b L, 0xFD, 0x32, 0x01
	ret

PmBkNameFunc:
	ld xhl, xwa
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, PmBkName_ReturnZero
	cp xbc, 0x9
	jr gt, PmBkName_ReturnZero
	add xbc, xbc
	add xbc, 0xED15EE
	ld bc, (xbc)
	lda_24 xix, 0xfbe0ef
	jp_dri 8, 0x07, 0xF0, 0xE4
; PmBkNameFunc event dispatch (10-entry, event 0x1C00013, table 0xED15EE)
PmBkName_EventDispatch:
	.byte 0x0e, 0xeb, 0xa9, 0x0e, 0x43, 0x09, 0x00, 0x00
	.byte 0x00, 0x0e

PmBkName_ReturnZero:
	lds32 xhl, 0
	ret

PmBkName_DataBytes:
	.byte 0xf1, 0x48, 0x8d, 0x33, 0x0e

GmOnOffFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00083
	jr z, GmOnOff_GetBoundsRect
	cp xbc, 0x1E0003F
	jrl z, GmOnOff_DefaultReturn
	cp xbc, 0x1E0003E
	jr z, GmOnOff_Return1
	cp xbc, 0x1E00041
	jr z, GmOnOff_Return1
	cp xbc, 0x1E00040
	jr z, GmOnOff_Return0xC0
	cp xbc, 0x1E00042
	jrl nz, GmOnOff_DefaultReturn
	pushm (xde + 4)
	pushw 0xED
	pushw 0x1602
	ld xwa, (xde + 8)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jrl VariScreen_CleanupRet

GmOnOff_Return0xC0:
	ld xhl, 0xC0
	jrl VariScreen_CleanupRet

GmOnOff_Return1:
	lds32 xhl, 1
	jrl VariScreen_CleanupRet

GmOnOff_GetBoundsRect:
	lda xix, (xsp + 4)
	ldw (xix), 0x10
	lda xhl, (xix + 2)
	ldw (xhl), 0x5F
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
	ldw bc, 0xC4
	ldw de, 0xF0
	call DrawDesignBox
	lda xwa, (xsp + 4)
	ld xbc, 0x20
	call DrawIcons
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20006
	lds32 xde, 3
	jr GmOnOff_SendAndReturn

GmOnOff_CheckDesign:
	ldda8 c, 36160
	orda8 c, 36162
	orda8 c, 36164
	jr nz, GmOnOff_SendHideEvent
	ldw bc, 0xF5
	call DrawBox

GmOnOff_SendHideEvent:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C20006
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
	st_dri3b L, 0xFD, 0xCA, 0xFD
	push xiz
	st_dri3l XDE, 0xFD, 0x2E, 0x02
	st_dri3l XBC, 0xFD, 0x32, 0x02
	st_dri3l XWA, 0xFD, 0x36, 0x02
	ld_sril XWA, (xsp + 0x0232)
	cp xwa, 0x1C00007
	jrl z, VariScreen_HandleOK
	cp xwa, 0x1E20005
	jrl z, VariScreen_HandleEnumNotify
	cp xwa, 0x1C0000F
	jrl z, VariScreen_HandleConfirm
	cp xwa, 0x1C0000E
	jrl z, VariScreen_HandleSelect
	cp xwa, 0x1C0000D
	jrl z, VariScreen_HandlePaint
	cp xwa, 0x1C0000B
	jr z, VariScreen_HandleShow
	cp xwa, 0x1C20007
	jr z, VariScreen_RefreshAfterInit
	cp xwa, 0x1C00001
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
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jrl VariScreen_SendAndReturn

VariScreen_HandleShow:
	ld_sril XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	ld xwa, (xsp + 24)
	ld (xsp + 4), xwa
	ldda8 a, 36154
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 31), l
	ldda8 a, 36154
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 28)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8D3A
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
	divs wa, 0xA
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
	st_dri3b C, 0xFD, 0x22, 0x02
	ldw (xhl), 0x4
	lda xde, (xhl + 2)
	ldw (xde), 0x2
	st_dri3b W, 0xFD, 0x26, 0x02
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
	ldw bc, 0xC0
	ldw de, 0xF0
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x22, 0x02
	ld xbc, 0x8C
	call DrawIcons
	st_dri3b A, 0xFD, 0x22, 0x02
	ldw (xbc), 0x23
	lda xhl, (xbc + 2)
	ldw (xhl), 0x8
	st_dri3b W, 0xFD, 0x26, 0x02
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
	pushw 0xFF
	pushw 0xF7
	ld xde, 0xED1604
	call DrawString
	ldda8 a, 36154
	extz wa
	lds bc, 0
	call SndParam_LookupViaEncode
	ld (xsp + 31), l
	ldda8 a, 36154
	extz wa
	ldw bc, 0x20
	call SndParam_LookupViaEncode
	lda xwa, (xsp + 28)
	ld (xwa + 4), l
	ldmi16 (xwa + 2), 0x8D3A
	call SndParam_FetchOscTableEntry
	ld a, (xsp + 28)
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x01
	call StoreDRAMInit_LoadDRAM
	st_dri3b A, 0xFD, 0x22, 0x02
	ldw (xbc), 0x68
	lda xhl, (xbc + 2)
	ldw (xhl), 0xC
	st_dri3b W, 0xFD, 0x26, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x80
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0xF
	ld (xwa + 6), de
	st_dri3b B, 0xFD, 0x22, 0x01
	lds32 xhl, 0
	push xhl
	pushw 0xFB
	pushw 0xF7
	call DrawString
	st_dri3b A, 0xFD, 0x22, 0x02
	ldw (xbc), 0x90
	lda xhl, (xbc + 2)
	ldw (xhl), 0x0
	st_dri3b W, 0xFD, 0x26, 0x02
	ld de, (xbc)
	ld (xwa), de
	ld de, (xbc)
	add de, 0x38
	ld (xwa + 4), de
	ld de, (xhl)
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0xF
	ld (xwa + 6), de
	ld xde, (xsp + 24)
	ld xde, (xde + 48)
	ld de, (xde)
	muls de, 0x7
	lda_24 xhl, 0xecfdfe
	exts xde
	add xde, xhl
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	pushw 0xF7
	call DrawString
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	dec 1, wa
	ld hl, (xhl)
	sub hl, wa
	jr ge, VariScreen_CalcRowOffset
	ld xde, (xde)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xA
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
	divs wa, 0xA
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
	divs wa, 0xA
	ldto_werp BC, 0xE2
	ld_sril3 XWA, 0x07, 0xEC, 0xE8
	ld_srib3 A, 0x07, 0xE0, 0xE4
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightBounds
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr VariScreen_DrawDesignArea

VariScreen_SetRightBounds:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

VariScreen_DrawDesignArea:
	lds bc, 0
	ldw de, 0xF5
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
	div c, 0xA
	ld c, b
	ld (xwa + 3), c
	call SndParam_ApplyProgramChange
	lda xbc, (xsp + 28)
	ld a, (xbc + 3)
	extz wa
	ld c, (xbc + 4)
	extz bc
	st_dri3b B, 0xFD, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_dri 0xFD, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 24)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xA
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
	ld (xsp + 12), 0xFF
	ld (xsp + 14), 0xF5
	ld xix, (xsp + 24)
	ld xde, (xix + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xA
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_DrawEditSwitch
	sub bc, 0xA
	ld xwa, (xix + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xA
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
	div a, 0xA
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
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
	div a, 0xA
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawDefaultVoice

VariScreen_DrawNameLabel:
	st_dri3b B, 0xFD, 0x26, 0x02
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightNameBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1E
	jr VariScreen_DrawNameString

VariScreen_SetRightNameBounds:
	ldw (xde), 0xA3
	ldw (xwa), 0xBE

VariScreen_DrawNameString:
	decm 8, (xbc)
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xA
	sub bc, 0xA
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 64)
	ld wa, (xwa)
	extz wa
	div a, 0xA
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xED
	pushw 0x160A
	lda xwa, (xsp + 40)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	st_dri3b C, 0xFD, 0x26, 0x02
	st_dri3b A, 0xFD, 0x22, 0x02
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
	st_dri3b A, 0xFD, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	add wa, 0xC
	ld (xde), wa
	st_dri3b C, 0xFD, 0x26, 0x02
	sub wa, 0xF
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightVoiceBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9C
	jr VariScreen_DrawVoiceString

VariScreen_SetRightVoiceBounds:
	ldw (xhl), 0xAB
	ldw (xwa), 0x137

VariScreen_DrawVoiceString:
	st_dri3b B, 0xFD, 0x22, 0x01
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
	st_dri3b C, 0xFD, 0x26, 0x02
	st_dri3b A, 0xFD, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	sub wa, 0xF
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetDefVoiceRightBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9C
	jr VariScreen_DrawDefVoiceString

VariScreen_SetDefVoiceRightBounds:
	ldw (xhl), 0xAB
	ldw (xwa), 0x137

VariScreen_DrawDefVoiceString:
	st_dri3b B, 0xFD, 0x22, 0x01
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
	divs wa, 0xA
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
	divs wa, 0xA
	ldto_werp BC, 0xE2
	ld_sril3 XWA, 0x07, 0xEC, 0xE8
	ld_srib3 A, 0x07, 0xE0, 0xE4
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xde, (xhl + 2)
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightPanelRightBounds
	ldw (xwa), 0x8
	ldw (xbc), 0x9C
	jr VariScreen_DrawRightDesignBox

VariScreen_SetRightPanelRightBounds:
	ldw (xwa), 0xA3
	ldw (xbc), 0x137

VariScreen_DrawRightDesignBox:
	ldw bc, 0xC1
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
	div c, 0xA
	ld c, b
	ld (xwa + 3), c
	call SndParam_ApplyProgramChange
	lda xbc, (xsp + 28)
	ld a, (xbc + 3)
	extz wa
	ld c, (xbc + 4)
	extz bc
	st_dri3b B, 0xFD, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_dri 0xFD, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 24)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xA
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
	ld (xsp + 12), 0xFF
	ld (xsp + 14), 0xF5
	ld xwa, (xsp + 24)
	ld xde, (xwa + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xA
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_DrawRightEditSw
	ld hl, bc
	sub hl, 0xA
	ld bc, (xde)
	ld a, c
	extz wa
	div a, 0xA
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
	div a, 0xA
	ld e, w
	extz de
	ld_sril3 XWA, 0x07, 0xEC, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xE8
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
	div a, 0xA
	ld l, w
	extz hl
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawRightNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawRightDefaultVoice

VariScreen_DrawRightNameLabel:
	st_dri3b B, 0xFD, 0x26, 0x02
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_SetRightNameRightBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1E
	jr VariScreen_DrawRightNameString

VariScreen_SetRightNameRightBounds:
	ldw (xde), 0xA3
	ldw (xwa), 0xBE

VariScreen_DrawRightNameString:
	decm 8, (xbc)
	ld xde, (xsp + 24)
	ld xwa, (xde + 44)
	ld bc, (xwa)
	muls bc, 0xA
	sub bc, 0xA
	ld xwa, (xde + 60)
	ld wa, (xwa)
	extz wa
	div a, 0xA
	ld a, w
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xED
	pushw 0x160E
	lda xwa, (xsp + 40)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	st_dri3b C, 0xFD, 0x26, 0x02
	st_dri3b A, 0xFD, 0x22, 0x02
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
	st_dri3b A, 0xFD, 0x22, 0x02
	lda xde, (xbc + 2)
	ld wa, (xde)
	add wa, 0xC
	ld (xde), wa
	st_dri3b C, 0xFD, 0x26, 0x02
	sub wa, 0xF
	ld (xhl + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xhl + 6), wa
	lda xwa, (xhl + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightVoiceRightBounds
	ldw (xhl), 0x10
	ldw (xwa), 0x9C
	jr VariScreen_DrawRightVoiceString

VariScreen_SetRightVoiceRightBounds:
	ldw (xhl), 0xAB
	ldw (xwa), 0x137

VariScreen_DrawRightVoiceString:
	st_dri3b B, 0xFD, 0x22, 0x01
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
	st_dri3b B, 0xFD, 0x26, 0x02
	st_dri3b A, 0xFD, 0x22, 0x02
	lda xhl, (xbc + 2)
	ld wa, (xhl)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xhl)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xbc), 0x0
	jr nz, VariScreen_SetRightDefVoiceRightBounds
	ldw (xde), 0x10
	ldw (xwa), 0x9C
	jr VariScreen_DrawRightDefVoiceString

VariScreen_SetRightDefVoiceRightBounds:
	ldw (xde), 0xAB
	ldw (xwa), 0x137

VariScreen_DrawRightDefVoiceString:
	st_dri3b C, 0xFD, 0x22, 0x01
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
	st_dri3b W, 0xFD, 0x26, 0x02
	ldw (xwa + 2), 0x6
	ldw (xwa + 6), 0x17
	ldw (xwa), 0xF5
	ldw (xwa + 4), 0x13B
	ldw bc, 0xC1
	ldw de, 0xF3
	call DrawDesignBox
	st_dri3b B, 0xFD, 0x26, 0x02
	ld wa, (xde + 4)
	sub wa, (xde)
	exts xwa
	divs wa, 0x2
	ld bc, (xde)
	add bc, wa
	st_dri3b C, 0xFD, 0x22, 0x02
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
	divs wa, 0xA
	inc 1, wa
	pushw wa
	ld xwa, (xbc + 44)
	pushm (xwa)
	pushw 0xED
	pushw 0x1612
	st_dri3b W, 0xFD, 0x2A, 0x01
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b A, 0xFD, 0x22, 0x02
	st_dri3b B, 0xFD, 0x22, 0x01
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xF7
	call DrawStringCentered
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 52)
	ld xwa, (xwa + 44)
	ld wa, (xwa)
	muls wa, 0xA
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
	mul c, 0xA
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
	st_dri3b B, 0xFD, 0x22, 0x01
	call SndParam_ApplyProgramChangeAsync
	stib_dri 0xFD, 0x32, 0x01, 0x00
	ld (xsp + 8), 0x9
	ld xwa, (xsp + 16)
	ld xde, (xwa + 52)
	ld xhl, (xwa + 44)
	ld bc, (xhl)
	muls bc, 0xA
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
	ld (xsp + 12), 0xFF
	ld (xsp + 14), 0xF5
	ld xwa, (xsp + 16)
	ld xde, (xwa + 60)
	ld wa, (xde)
	exts xwa
	divs wa, 0xA
	inc 1, wa
	cp wa, (xhl)
	jr nz, VariScreen_ConfirmDrawEditSw
	sub bc, 0xA
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
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
	extz wa
	call DrawEditSw
	ld c, (xsp + 8)
	srl c, 1
	extz bc
	sla bc, 2
	lda_24 xde, 0x03f214
	ld l, (xsp + 10)
	extz hl
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 16)
	ld xiz, (xwa + 56)
	st_dri3b E, 0xFD, 0x26, 0x02
	st_dri3b D, 0xFD, 0x22, 0x02
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
	sub wa, 0xF
	ld (xde), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xhl), wa
	ld xwa, (xsp + 24)
	cpw (xix), 0x0
	jr nz, VariScreen_ConfirmSetNameRightBounds
	ldw (xiz), 0x8
	ldw (xwa), 0x1E
	jr VariScreen_ConfirmDrawNameAudio

VariScreen_ConfirmSetNameRightBounds:
	ldw (xiz), 0xA3
	ldw (xwa), 0xBE

VariScreen_ConfirmDrawNameAudio:
	decm 8, (xiy)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xA
	sub bc, 0xA
	ld a, (xsp + 10)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xED
	pushw 0x161E
	lda xwa, (xsp + 40)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b B, 0xFD, 0x22, 0x02
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
	st_dri3b B, 0xFD, 0x22, 0x02
	lda xbc, (xde + 2)
	ld hl, (xbc)
	add hl, 0xC
	ld (xbc), hl
	st_dri3b W, 0xFD, 0x26, 0x02
	sub hl, 0xF
	ld (xwa + 2), hl
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, VariScreen_ConfirmSetVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9C
	jr VariScreen_ConfirmDrawVoiceString

VariScreen_ConfirmSetVoiceRightBounds:
	ldw (xwa), 0xAB
	ldw (xbc), 0x137

VariScreen_ConfirmDrawVoiceString:
	st_dri3b C, 0xFD, 0x22, 0x01
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
	sub iy, 0xF
	ld (xde), iy
	ld bc, (xbc)
	add bc, 0x10
	ld (xhl), bc
	ld xbc, (xsp + 24)
	cpw (xix), 0x0
	jr nz, VariScreen_ConfirmSetDefVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9C
	jr VariScreen_ConfirmDrawDefVoiceString

VariScreen_ConfirmSetDefVoiceRightBounds:
	ldw (xwa), 0xAB
	ldw (xbc), 0x137

VariScreen_ConfirmDrawDefVoiceString:
	st_dri3b B, 0xFD, 0x22, 0x01
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
	muls wa, 0xA
	dec 1, wa
	ld hl, (xhl)
	sub hl, wa
	jr ge, VariScreen_EnumRowReady
	ld xde, (xde)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xA
	dec 1, wa
	sub wa, (xde)
	ldw de, 0x9
	sub de, wa
	ld (xsp + 8), e

VariScreen_EnumRowReady:
	ld (xsp + 12), 0xFF
	ld (xsp + 14), 0xF5
	ld xde, (xbc)
	ld xwa, (xsp + 24)
	ld xbc, (xwa + 60)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xA
	inc 1, wa
	cp wa, (xde)
	jr nz, VariScreen_EnumHighlightColors
	ld de, (xde)
	muls de, 0xA
	sub de, 0xA
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
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
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
	ld_sril3 XWA, 0x07, 0xE8, 0xE4
	ld_srib3 A, 0x07, 0xE0, 0xEC
	extz wa
	st_dri3b A, 0xFD, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_EnumDrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_EnumDrawDefaultVoice

VariScreen_EnumDrawNameLabel:
	st_dri3b B, 0xFD, 0x26, 0x02
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	lda xwa, (xde + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_EnumSetNameRightBounds
	ldw (xde), 0x8
	ldw (xwa), 0x1E
	jr VariScreen_EnumDrawNameAudio

VariScreen_EnumSetNameRightBounds:
	ldw (xde), 0xA3
	ldw (xwa), 0xBE

VariScreen_EnumDrawNameAudio:
	decm 8, (xbc)
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 44)
	ld bc, (xwa)
	muls bc, 0xA
	sub bc, 0xA
	ld xwa, (xsp + 20)
	ld a, (xwa)
	inc 1, a
	extz wa
	add wa, bc
	pushw wa
	pushw 0xED
	pushw 0x1622
	lda xwa, (xsp + 40)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b B, 0xFD, 0x22, 0x02
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
	st_dri3b C, 0xFD, 0x22, 0x02
	lda xbc, (xhl + 2)
	ld de, (xbc)
	add de, 0xC
	ld (xbc), de
	st_dri3b W, 0xFD, 0x26, 0x02
	sub de, 0xF
	ld (xwa + 2), de
	ld bc, (xbc)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xhl), 0x0
	jr nz, VariScreen_EnumSetVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9C
	jr VariScreen_EnumDrawVoiceString

VariScreen_EnumSetVoiceRightBounds:
	ldw (xwa), 0xAB
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
	st_dri3b W, 0xFD, 0x26, 0x02
	st_dri3b B, 0xFD, 0x22, 0x02
	lda xhl, (xde + 2)
	ld bc, (xhl)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xhl)
	add bc, 0x10
	ld (xwa + 6), bc
	lda xbc, (xwa + 4)
	cpw (xde), 0x0
	jr nz, VariScreen_EnumSetDefVoiceRightBounds
	ldw (xwa), 0x10
	ldw (xbc), 0x9C
	jr VariScreen_EnumDrawDefVoiceString

VariScreen_EnumSetDefVoiceRightBounds:
	ldw (xwa), 0xAB
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
	muls wa, 0xA
	dec 1, wa
	ld bc, (xbc)
	sub bc, wa
	jr ge, VariScreen_OK_Dispatch
	ld xwa, (xsp + 20)
	ld xbc, (xwa)
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	ld wa, (xwa)
	muls wa, 0xA
	dec 1, wa
	sub wa, (xbc)
	ldw bc, 0x9
	sub bc, wa
	ld (xsp + 8), c

VariScreen_OK_Dispatch:
	ld_sril XBC, (xsp + 0x022e)
	cp xbc, 0xC
	jrl z, VariScreen_OK_CalcRow4
	cp xbc, 0xB
	jrl z, VariScreen_OK_CalcRow3
	cp xbc, 0xA
	jrl z, VariScreen_OK_CalcRow2
	cp xbc, 0x9
	jrl z, VariScreen_OK_CalcRow1
	ld a, (xsp + 8)
	extz wa
	cp xbc, 0x8
	jrl z, VariScreen_OK_CalcRow0
	cp xbc, 0x8C
	jrl z, VariScreen_OK_HalfRange4
	cp xbc, 0x8B
	jrl z, VariScreen_OK_HalfRange3
	cp xbc, 0x8A
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
	muls wa, 0xA
	sub wa, 0xA
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0x9
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	dec 8, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	dec 7, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	dec 6, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0xA
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0xA
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0xA
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0xA
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	muls wa, 0xA
	sub wa, 0xA
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000E
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
	divs wa, 0xA
	inc 1, wa
	cp (xbc), wa
	jr ge, VariScreen_OK_PageScrollWrap
	incm 1, (xbc)
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000D
	lds32 xde, 0
	jr VariScreen_OK_PageSendEvent

VariScreen_OK_PageScrollWrap:
	cps wa, 1
	jr le, VariScreen_OK_PageScrollDown
	ldw (xbc), 0x1
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000D
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
	ld xbc, 0x1C0000D
	lds32 xde, 0
	jr VariScreen_OK_PageDownSendEvent

VariScreen_OK_PageScrollDownWrap:
	ld xwa, (xsp + 16)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xA
	inc 1, wa
	cps wa, 1
	jr le, VariScreen_OK_ForwardToInherited
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1C0000D
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
	st_dri3b L, 0xFD, 0x36, 0x02
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
	st_dri3b L, 0xFD, 0xD8, 0xFD
	push xiz
	st_dri3l XDE, 0xFD, 0x20, 0x02
	st_dri3l XBC, 0xFD, 0x24, 0x02
	st_dri3l XWA, 0xFD, 0x28, 0x02
	ld_sril XBC, (xsp + 0x0224)
	cp xbc, 0x1C00007
	jrl z, RVari_OK
	cp xbc, 0x1E2000B
	jrl z, RVari_EnumNotify
	cp xbc, 0x1C0000F
	jrl z, RVari_Confirm
	cp xbc, 0x1C0000E
	jrl z, RVari_Select
	cp xbc, 0x1C0000D
	jrl z, RVari_Paint
	cp xbc, 0x1C0000B
	jrl z, RVari_Show
	cp xbc, 0x1C00001
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
	cpw (xwa), 0xE
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
	divs wa, 0xA
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
	st_dri3b C, 0xFD, 0x14, 0x02
	ldw (xhl), 0x4
	lda xde, (xhl + 2)
	ldw (xde), 0x2
	st_dri3b W, 0xFD, 0x18, 0x02
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
	ldw bc, 0xC0
	ldw de, 0xF0
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x14, 0x02
	ld xbc, 0x90
	call DrawIcons
	st_dri3b A, 0xFD, 0x14, 0x02
	ldw (xbc), 0x23
	lda xhl, (xbc + 2)
	ldw (xhl), 0x8
	st_dri3b W, 0xFD, 0x18, 0x02
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
	pushw 0xFF
	pushw 0xF7
	ld xde, 0xED1646
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
	st_dri3b W, 0xFD, 0x1A, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	st_dri3b B, 0xFD, 0x14, 0x01
	ld (xde + 16), 0x0
	st_dri3b A, 0xFD, 0x14, 0x02
	ldw (xbc), 0x6B
	lda xix, (xbc + 2)
	ldw (xix), 0x0
	st_dri3b W, 0xFD, 0x18, 0x02
	ld hl, (xbc)
	ld (xwa), hl
	ld hl, (xbc)
	add hl, 0x80
	ld (xwa + 4), hl
	ld hl, (xix)
	ld (xwa + 2), hl
	ld hl, (xix)
	add hl, 0xF
	ld (xwa + 6), hl
	lds32 xhl, 0
	push xhl
	pushw 0xFB
	pushw 0xF7
	call DrawString
	ld_sril XWA, (xsp + 0x0228)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	ld_sril XWA, (xsp + 0x0228)
	ld xbc, 0x1C0000E
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
	cpw (xwa), 0xF
	jrl nz, RVari_Select_CalcVisibleCount
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b B, 0xFD, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0xA3
	ldw (xwa + 4), 0x137
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	ld xwa, (xiz + 56)
	ld wa, (xwa)
	extz wa
	ld xbc, (xiz + 64)
	ld bc, (xbc)
	extz bc
	call AccVoice_DispatchWithChannel
	extz xhl
	pushw 0xD
	push xhl
	st_dri3b W, 0xFD, 0x1A, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_dri 0xFD, 0x21, 0x01, 0x00
	ld (xsp + 10), 0xFF
	ld (xsp + 12), 0xF5
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp BC, 0xE2
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	cp wa, bc
	jr nz, RVari_Select_CheckSameBank
	ld (xsp + 10), 0x0
	ld (xsp + 12), 0x7

RVari_Select_CheckSameBank:
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b B, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xA3
	ldw (xde + 4), 0xBE
	decm 8, (xbc)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	sla wa, 2
	lda_24 xbc, 0xed1626
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x164E
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	st_dri3b C, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x14, 0x02
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
	st_dri3b C, 0xFD, 0x14, 0x02
	lda xde, (xhl + 2)
	ld wa, (xde)
	add wa, 0xC
	ld (xde), wa
	st_dri3b A, 0xFD, 0x18, 0x02
	sub wa, 0xF
	ld (xbc + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xbc + 6), wa
	ldw (xbc), 0xB7
	ldw (xbc + 4), 0x14B
	st_dri3b B, 0xFD, 0x14, 0x01
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
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b B, 0xFD, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0xA3
	ldw (xwa + 4), 0x137
	ldw bc, 0xC1
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
	pushw 0xD
	push xhl
	st_dri3b W, 0xFD, 0x1A, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_dri 0xFD, 0x21, 0x01, 0x00
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	lda_24 xbc, 0xecfda8
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b B, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xF
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xA3
	ldw (xde + 4), 0xBE
	decm 8, (xbc)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	ldto_werp WA, 0xE2
	sla wa, 2
	lda_24 xbc, 0xed1626
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0xED
	pushw 0x1652
	lda xwa, (xsp + 28)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 12)
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x14, 0x02
	lda xde, (xsp + 20)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	st_dri3b A, 0xFD, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	add de, 0xC
	ld (xhl), de
	st_dri3b W, 0xFD, 0x18, 0x02
	sub de, 0xF
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0xB7
	ldw (xwa + 4), 0x14B
	st_dri3b B, 0xFD, 0x14, 0x01
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, 0xecfdac
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b B, 0xFD, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9C
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xF
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2D
	ldw (xwa + 4), 0xAC
	ld xde, (xiz + 64)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, 0xecfdd4
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	lds32 xhl, 1
	push xhl
	pushw 0xFF
	pushw 0xF7
	call DrawStringLeftJustify
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, 0xecfdac
	ld_srib3 A, 0x07, 0xE4, 0xE0
	extz wa
	st_dri3b A, 0xFD, 0x14, 0x02
	call GetEditSwPoint
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b B, 0xFD, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xF
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9C
	ldw bc, 0xC1
	lds de, 7
	call DrawDesignBox
	st_dri3b W, 0xFD, 0x18, 0x02
	st_dri3b A, 0xFD, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xF
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2D
	ldw (xwa + 4), 0xAC
	ld xde, (xiz + 60)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, 0xecfdd4
	ld_sril3 XDE, 0x07, 0xEC, 0xE8
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0xF7
	call DrawStringLeftJustify
	jrl RVari_Select_ReturnZero

	.include "ui/rvari_routines.s"
