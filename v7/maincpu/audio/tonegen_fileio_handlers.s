; =============================================================================
; Tone Generator Config & File I/O Handlers (1K lines)
; =============================================================================
;
; ToneGen_Config initialization, DSP configuration entry setup,
; FileIO callback handlers, and audio mode dispatch. Late-ROM
; routines before the main audio control engine.
; =============================================================================

ToneGen_IncrementWrap128:
	inc	1, ix
	cp	ix, 128
	jr	c, 2
	lds	ix, 0
	ret
	cps	ix, 0
	jr	nz, 4
	ldw	ix, 127
	ret
	dec	1, ix
	ret
ToneGen_Config_AlignByte:
	ret

ToneGen_Config_InitAllEntries:
	ld xwa, 0xf9a0
	calr DSPCfg_InitAllEntries
	ld xwa, 0xfd60
	calr DSPCfg_InitAuxEntries
	call ToneGen_DispatchByMode
	jp SwbtWr_NullRet

ToneGen_Config_InitAllChannels:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0
	lda_24 xiz, (0x1ed400)

ToneGen_Config_InitChannelLoop:
	ld xwa, xiz
	calr DSPCfg_InitAllEntries
	incm 1, (xsp + 4)
	stb_dri H, 0xf9, 0xc0, 0x03
	cpw (xsp + 4), 0x50
	jr c, ToneGen_Config_InitChannelLoop
	pop xiz
	inc 2, xsp
	ret

ToneGen_LookupByVoiceIndex:
	cp	wa, 80
	ret	nc
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 4
	sub	xbc, xwa
	sll	xbc, 6
	lda_24	xwa, (0x1ed400)
	add	xwa, xbc
	calr	317
	ret

ToneGen_Config_InitAndChannels:
	calr ToneGen_Config_InitAllEntries
	jr ToneGen_Config_InitAllChannels

ToneGen_ApplyMaskTable:
	lda_24 xwa, (NakaInst_ExtDevice_Screens_0x2B0C)
	lda xbc, (xwa + 4)
	ld xde, xwa
	lda xhl, (xwa + 25)

ToneGen_ApplyMaskLoop:
	.incbin "includes/generated/v7_transplant_ToneGen_ApplyMaskLoop.bin"
ToneGen_DSPCfg_Initialize:
	calr ToneGen_DSPCfg_ResetAll
	jrl ToneGen_DSPCfg_ResetAllChannels
	lda_d16 xwa, (0xf480)
	jrl DSPCfg_InitAllEntries

ToneGen_InitAllChannelEntries_Skip:
	jr Voice_InitAllChannelEntries

Voice_InitAllChannelEntries:
	lda xsp, (xsp - 14)
	push xiz
	ldw (xsp + 10), 0x0

Voice_InitChannelLoop:
	ld wa, (xsp + 10)
	extz xwa
	ld xbc, NakaInst_ExtDevice_Screens_0x2B26
	add xbc, xwa
	ld a, (xbc)
	ld (xsp + 8), a
	extz wa
	call VoiceData_LookupPtrByIndex
	ld xiz, xhl
	cp xiz, 0xffffffff
	jr z, Voice_InitChannelNext
	ld a, (xsp + 8)
	extz wa
	call VoiceData_LookupPtrByChannel
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	cp xwa, 0xffffffff
	jr z, Voice_InitChannelNext
	lda xwa, (xsp + 12)
	ld c, (xiz)
	ld (xwa + 3), c
	ld c, (xiz + 1)
	ld (xwa + 4), c
	ld c, (xsp + 8)
	ld (xwa + 2), c
	call SndParam_ResolveVoiceEntry
	lda xbc, (xsp + 12)
	ld e, (xbc)
	extz de
	ld xwa, (xsp + 4)
	ld c, (xbc + 1)
	lda_dri XHL, 0x07, 0xe0, 0xe8

Voice_InitChannelNext:
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x17
	jr c, Voice_InitChannelLoop
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_CopyFromScratch:
	.incbin "includes/generated/v7_transplant_Voice_CopyFromScratch.bin"
ToneGen_DSPCfg_ResetAll:
	ld xwa, 0xf9a0
	calr DSPCfg_ResetEntryByTable
	ld xwa, 0xfd60
	jrl DSPCfg_ResetAuxEntries

ToneGen_DSPCfg_ResetAllChannels:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0
	lda_24 xiz, (0x1ed400)

ToneGen_DSPCfg_ResetChannelLoop:
	ld xwa, xiz
	calr DSPCfg_ResetEntryByTable
	incm 1, (xsp + 4)
	stb_dri H, 0xf9, 0xc0, 0x03
	cpw (xsp + 4), 0x50
	jr c, ToneGen_DSPCfg_ResetChannelLoop
	pop xiz
	inc 2, xsp
	ret

DSPCfg_ResetEntryByTable:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 0

DSPCfg_ResetEntryLoop:
	ld bc, iz
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, NakaInst_ExtDevice_Screens_0x2814
	add xbc, xwa
	ld xwa, (xsp + 2)
	calr DSPCfg_CopyEntryValues
	inc 1, iz
	cp iz, 0x2e
	jr c, DSPCfg_ResetEntryLoop
	popw iz
	inc 4, xsp
	ret

DSPCfg_InitAllEntries:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 0

DSPCfg_InitEntryLoop:
	.incbin "includes/generated/v7_transplant_DSPCfg_InitEntryLoop.bin"
DSPCfg_InitAuxEntries:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 0

; DSPCfg_InitAllEntries handler: entry 0
DSPCfg_Init_Entry0:
	ld bc, iz
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, NakaInst_ExtDevice_Screens_0x29E0
	add xbc, xwa
	ld xwa, (xsp + 2)
	calr DSPCfg_Init_Entry1
	inc 1, iz
	cp iz, 0x1e
	jr c, DSPCfg_Init_Entry0
	popw iz
	inc 4, xsp
	ret

; DSPCfg_InitAllEntries handler: entry 1
DSPCfg_Init_Entry1:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, (xbc)
	inc 2, xwa
	add (xsp + 4), xwa
	ld xiz, (xbc + 4)
	cp (xiz), 0xff
	jr z, DSPCfg_Init_Setup

; DSPCfg_InitAllEntries handler: entry 2
DSPCfg_Init_Entry2:
	ld xwa, (xsp + 4)
	ld xbc, xiz
	calr DSPCfg_Init_BoundsCheck
	extz xhl
	add xiz, xhl
	cp (xiz), 0xff
	jr nz, DSPCfg_Init_Entry2

; DSPCfg_InitAllEntries setup before dispatch
DSPCfg_Init_Setup:
	pop xiz
	inc 4, xsp
	ret

; DSPCfg_InitAllEntries bounds check and dispatch
DSPCfg_Init_BoundsCheck:
	ld e, (xbc)
	extz de
	cps de, 0
	jr mi, DSPCfg_Init_Finalize
	cp de, 0x8
	jr gt, DSPCfg_Init_Finalize
	add de, de
	lda_24 xix, (NakaInst_ExtDevice_Screens_0x2B3E)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda_24 xix, (DSPCfg_InitDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; DSPCfg_InitAllEntries dispatch
DSPCfg_InitDispatch:
	calr	45
	jr	42
	calr	58
	jr	37
	calr	73
	jr	32
	calr	86
	jr	27
	calr	126
	jr	22
	calr	166
	jr	17
	calr	252
	jr	12
	calr	330
	jr	7
	calr	343
	jr	2

; DSPCfg_InitAllEntries finalize after dispatch
DSPCfg_Init_Finalize:
	lds hl, 1
	ret

DSPCfg_InitDispatchData:
	ld	xde, xbc
	ld	l, (xde+1)
	extz	hl
	ld	c, (xde+2)
	.byte 0xc3
	reti
	.byte 0xe0
	sbc	xix, 0xe80eabdb
	.byte 0x8a
	ld	l, (xbc+1)
	extz	hl
	ld	a, (xbc+2)
	cpl	a
	.byte 0xc3
	reti
	sla	xwa, 201
	lds	hl, 3
	ret
	ld	xde, xbc
	ld	l, (xde+1)
	extz	hl
	ld	c, (xde+2)
	.byte 0xc3
	reti
	.byte 0xe0, 0xec
	cps	xhl, 3
	or	(xhl+14), xwa
	.byte 0x8a
	ld	a, (xbc+1)
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xwa
	ldw	de, 649
	ldb	l, 207
	.byte 0x89, 0x82
	cpdm8	905, a
	jr	ugt, 9
	ld	a, l
	.byte 0x82
	cpdm8	1161, a
	jr	nc, 9
	cpl	l
	and	(xde), l
	ld	a, (xbc+5)
	or	(xde), a
	lds	hl, 6
	ret
	ld	xde, xwa
	ld	a, (xbc+1)
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xwa
	ldw	de, 649
	ldb	l, 207
	.byte 0x89, 0x82
	cpdm8	905, a
	jr	ugt, 18
	ld	a, l
	.byte 0x82
	cpdm8	1161, a
	jr	c, 9
	cpl	l
	and	(xde), l
	ld	a, (xbc+5)
	or	(xde), a
	lds	hl, 6
	ret
	dec	6, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+1)
	extz	bc
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0xa8dc
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	ld	(xsp+6), c
	.byte 0xc7
	swi	0
	.byte 0x9b
	extz	iz
	ld	l, (xde+2)
	ld	h, l
	.byte 0x80, 0xc6
	lds32	xiy, 5
	cp	ix, iz
	jr	nc, 21
	ld	xbc, xiy
	add	xbc, xde
	cp	(xbc), h
	jr	nz, 5
	ld	a, (xsp+6)
	jr	22
	inc	1, ix
	inc	1, xiy
	cp	ix, iz
	jr	c, -21
	cpl	l
	and	(xwa), l
	ld	c, (xde+4)
	or	(xwa), c
	ld	xwa, (xsp+2)
	ld	a, (xwa)
	inc	5, a
	ld	l, a
	extz	hl
	popw	iz
	inc	6, xsp
	ret
	dec	4, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+1)
	extz	bc
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	ldw	wa, 0xa8dd
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	.byte 0xc7
	swi	0
	.byte 0x9b
	extz	iz
	ld	l, (xde+2)
	ld	h, l
	.byte 0x80, 0xc6
	lds32	xix, 5
	cp	iy, iz
	jr	nc, 27
	ld	xbc, xix
	add	xbc, xde
	cp	(xbc), h
	jr	nz, 11
	cpl	l
	and	(xwa), l
	ld	c, (xde+4)
	or	(xwa), c
	jr	8
	inc	1, iy
	inc	1, xix
	cp	iy, iz
	jr	c, -27
	ld	xwa, (xsp+2)
	ld	l, (xwa)
	inc	5, l
	extz	hl
	popw	iz
	inc	4, xsp
	ret
	ld	xde, xbc
	ld	l, (xde+1)
	extz	hl
	ld	c, (xde+2)
	.byte 0xf3
	reti
	.byte 0xe0, 0xec
	ld	xhl, 0x890eabdb
	.byte 0x01
	ldb	c, 217
	ccf
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	nop
	nop
	lds	hl, 2
	ret
	lda_d16	xwa, (0xf480)
	jrl	-718

DSPCfg_ResetAuxEntries:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	lds iz, 0

DSPCfg_ResetAuxEntryLoop:
	ld bc, iz
	extz xbc
	ld xwa, xbc
	sll xwa, 2
	add xwa, xbc
	add xwa, xwa
	ld xbc, NakaInst_ExtDevice_Screens_0x29E0
	add xbc, xwa
	ld xwa, (xsp + 2)
	calr DSPCfg_CopyEntryValues
	inc 1, iz
	cp iz, 0x1e
	jr c, DSPCfg_ResetAuxEntryLoop
	popw iz
	inc 4, xsp
	ret

DSPCfg_CopyEntryValues:
	ld xde, xbc
	ld xbc, (xde)
	add xwa, xbc
	ld c, (xde + 8)
	ld (xwa), c
	ld c, (xde + 9)
	ld (xwa + 1), c
	ret

DSPCfg_SyncBitmapData:
	.incbin "includes/generated/v7_transplant_DSPCfg_SyncBitmapData.bin"
SndParam_SyncDisplayBitmap:
	.incbin "includes/generated/v7_transplant_SndParam_SyncDisplayBitmap.bin"
SoundParam_NotifyMultipleChanges:
	.incbin "includes/generated/v7_transplant_SoundParam_NotifyMultipleChanges.bin"
ToneGen_DiffScanAndUpdate:
	.incbin "includes/generated/v7_transplant_ToneGen_DiffScanAndUpdate.bin"
ToneGen_DiffScanOuter:
	ld wa, iz
	extz xwa
	add xwa, xde
	ld a, (xwa)
	ld (xsp + 2), a
	ld (xsp + 6), 0x0
	inc 1, iz
	ld wa, iz
	extz xwa
	add xwa, xde
	ld a, (xwa)
	ld (xsp + 4), a
	cp (xsp + 4), 0x0
	jrl z, ToneGen_DiffOuterNext

ToneGen_DiffScanInner:
	inc 1, iz
	lda_d16 xde, (0xfd60)
	ld xwa, xde
	sub xwa, 0xf9a0
	ld hl, iz
	extz xhl
	add xhl, xwa
	lda_24 xwa, (0x03c8e4)
	add xhl, xwa
	ld wa, iz
	extz xwa
	add xwa, xde
	ld a, (xwa)
	cp a, (xhl)
	jr z, ToneGen_DiffInnerNext
	cp bc, 0x1f4
	jr c, ToneGen_DiffRecordChange
	extz xbc
	add xbc, (xsp + 8)
	ld (xbc), 0xff
	push xde
	push xhl
	push xix
	push xiz
	call SwbtWr_ReinitOutputBank
	pop xiz
	pop xix
	pop xhl
	pop xde
	lds bc, 0

ToneGen_DiffRecordChange:
	ld de, bc
	inc 1, bc
	extz xde
	add xde, (xsp + 8)
	ld a, (xsp + 2)
	ld (xde), a
	ld de, bc
	inc 1, bc
	extz xde
	add xde, (xsp + 8)
	ld a, (xsp + 6)
	ld (xde), a
	ld wa, bc
	inc 1, bc
	extz xwa
	ld xix, xwa
	add xix, (xsp + 8)
	lda_d16 xhl, (0xfd60)
	ld de, iz
	extz xde
	add xde, xhl
	ld a, (xde)
	ld (xix), a
	sub xhl, 0xf9a0
	ld xwa, xhl
	ld hl, iz
	extz xhl
	add xhl, xwa
	lda_24 xwa, (0x03c8e4)
	add xhl, xwa
	ld e, (xde)
	xor e, (xhl)
	ld wa, bc
	inc 1, bc
	extz xwa
	add xwa, (xsp + 8)
	ld (xwa), e

ToneGen_DiffInnerNext:
	incm8 1, (xsp + 6)
	decm8 1, (xsp + 4)
	jrl nz, ToneGen_DiffScanInner

ToneGen_DiffOuterNext:
	inc 1, iz

ToneGen_DiffScanCheckEnd:
	.incbin "includes/generated/v7_transplant_ToneGen_DiffScanCheckEnd.bin"
ToneGen_FileIO_SaveAndSync:
	.incbin "includes/generated/v7_transplant_ToneGen_FileIO_SaveAndSync.bin"
ToneGen_FileIO_RestoreFromBackup:
	.incbin "includes/generated/v7_transplant_ToneGen_FileIO_RestoreFromBackup.bin"
ToneGen_FlashVerify:
	lda_24 xhl, (NakaInst_ExtDevice_Screens_0x2B6E)
	ld xde, 0x3d3000
	lds bc, 0

ToneGen_FlashVerifyLoop:
	ldb_spi A, 0xec
	cp_spib A, 0xe8
	jr nz, ToneGen_FlashWriteAll
	inc 1, bc
	cps bc, 3
	jr c, ToneGen_FlashVerifyLoop
	ret

ToneGen_FlashWriteAll:
	.incbin "includes/generated/v7_transplant_ToneGen_FlashWriteAll.bin"
ToneGen_FlashWriteDone:
	pop xiz
	ret

ToneGen_FlashReadAndRestore:
	.incbin "includes/generated/v7_transplant_ToneGen_FlashReadAndRestore.bin"
DSPCfg_Param_CaseA:
	pop xiz
	ret

; DSP config parameter handler B
DSPCfg_Param_CaseB:
	.incbin "includes/generated/v7_transplant_DSPCfg_Param_CaseB.bin"
CtrlPanel_IndicatorJumpTable:
	extz wa
	cps wa, 0
	ret mi
	cp wa, 0x8
	ret gt
	add wa, wa
	lda_24 xix, (NakaInst_ExtDevice_Screens_0x2E3C)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (DSPCfg_Param_CaseC)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DSP config parameter handler C
DSPCfg_Param_CaseC:
	ret
	ld	xwa, 0x3d3400
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340e4
	lds	de, 2
	jr	67
	ld	xwa, 0x3d3410
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340e6
	ldw	de, 12
	.asciz "h1@ 4="
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340f2
	lds	de, 4
	.asciz "h @04="
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340f6
	lds	de, 4
	jr	15
	ld	xwa, 0x3d3440
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340fa
	lds	de, 6
	call	FlashWrite
	ret

Audio_DispatchCommand:
	extz wa
	cps wa, 0
	ret mi
	cp wa, 0x8
	ret gt
	add wa, wa
	lda_24 xix, (NakaInst_ExtDevice_Screens_0x2E4E)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (DSPCfg_Param_CaseD)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DSP config parameter handler D
DSPCfg_Param_CaseD:
	.incbin "includes/generated/v7_transplant_DSPCfg_Param_CaseD.bin"
PanelDisplay_DispatchByMode:
	extz wa
	cps wa, 0
	jrl mi, DSPCfg_Param_Default
	cp wa, 0x8
	jrl gt, DSPCfg_Param_Default
	add wa, wa
	lda_24 xix, (NakaInst_ExtDevice_Screens_0x2E60)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda_24 xix, (PanelDisplay_DispatchData)
	jp_ind 8, 0x07, 0xf0, 0xe0

PanelDisplay_DispatchData:
	ld	xde, 0x3d3400
	lda_24	xhl, (0x0340e4)
	lds	bc, 0
	ldb_spi	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 114
	inc	1, bc
	cps	bc, 2
	jr	c, -14
	jr	115
	ld	xde, 0x3d3410
	lda_24	xhl, (0x0340e6)
	lds	bc, 0
	ldb_spi	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 86
	inc	1, bc
	cp	bc, 12
	jr	c, -16
	.asciz "hUB 4="
	lda_24	xhl, (0x0340f2)
	lds	bc, 0
	.byte 0xc5, 0xec
	ldb	a, 197
	cp	xbc, xwa
	jr	nz, 56
	inc	1, bc
	cps	bc, 4
	jr	c, -14
	.asciz "h9B04="
	lda_24	xhl, (0x0340f6)
	lds	bc, 0
	ldb_spi	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 28
	inc	1, bc
	cps	bc, 4
	jr	c, 16777202
	jr	t, 0x1d
	.asciz "B@4="
	lda_24	xhl, (0x0340fa)
	lds	bc, 0
	.byte 0xc5, 0xec
	ldb	a, 197
	cp	xbc, xwa
	jr	z, 3
	lds	hl, 1
	ret
	inc	1, bc
	cps	bc, 6
	jr	c, -17

; DSP config parameter default handler
DSPCfg_Param_Default:
	lds hl, 0
	ret

Encoder_MarkInvalid:
	.incbin "includes/generated/v7_transplant_Encoder_MarkInvalid.bin"
Encoder_Stub1:
	ret

Encoder_Stub2:
	ret

Encoder_Stub3:
	ret

Encoder_AlignByte:
	ret

Encoder_ValueScanAndSync:
	.incbin "includes/generated/v7_transplant_Encoder_ValueScanAndSync.bin"
Encoder_ScanAndSync:
	calr Encoder_ReadNextEntry
	calr Encoder_PrepareCallback

Encoder_SyncLoop:
	.incbin "includes/generated/v7_transplant_Encoder_SyncLoop.bin"
Encoder_ReadNextEntry:
	.incbin "includes/generated/v7_transplant_Encoder_ReadNextEntry.bin"
Encoder_PrepareCallback:
	.incbin "includes/generated/v7_transplant_Encoder_PrepareCallback.bin"
Encoder_ResolveCallbackAddr:
	.incbin "includes/generated/v7_transplant_Encoder_ResolveCallbackAddr.bin"
FileIO_ProcessMaskAndShift:
	.incbin "includes/generated/v7_transplant_FileIO_ProcessMaskAndShift.bin"
FileIO_ShiftLeftLow:
	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftDone
	slla l

FileIO_ShiftDone:
	jr FileIO_CallbackHandler

FileIO_AudioControlStart:

; --- Audio Control, File I/O & MIDI Processing ---
