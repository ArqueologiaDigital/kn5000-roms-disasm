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
	lda xiz, (0x1ed400:24)

ToneGen_Config_InitChannelLoop:
	ld xwa, xiz
	calr DSPCfg_InitAllEntries
	incw 1, (xsp + 4)
	lda_dri XIZ, 0xf9, 0xc0, 0x03
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
	lda	xwa, (0x1ed400:24)
	add	xwa, xbc
	calr	317
	ret

ToneGen_Config_InitAndChannels:
	calr ToneGen_Config_InitAllEntries
	jr ToneGen_Config_InitAllChannels

ToneGen_ApplyMaskTable:
	lda xwa, (NakaInst_ExtDevice_Screens_0x2B0C:24)
	lda xbc, (xwa + 4)
	ld xde, xwa
	lda xhl, (xwa + 25)

ToneGen_ApplyMaskLoop:
	ld	xix, (xde)
	ld	a, (xbc)
	and	(xix), a
	inc	5, xde
	inc	5, xbc
	cp	xde, xhl
	jr	c, -14
	lds	wa, 0
	call	16472157
	pushw	16
	pushw	32
	pushw	0
	pushw	63906
	call	16713757
	inc	8, xsp
	ret
ToneGen_DSPCfg_Initialize:
	calr ToneGen_DSPCfg_ResetAll
	jrl ToneGen_DSPCfg_ResetAllChannels
	lda xwa, (0xf480:16)
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
	stb_dri C, 0x07, 0xe0, 0xe8

Voice_InitChannelNext:
	incw 1, (xsp + 10)
	cpw (xsp + 10), 0x17
	jr c, Voice_InitChannelLoop
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_CopyFromScratch:
	pushw	1568
	pushw	3
	pushw	51428
	pushw	0
	pushw	63904
	call	16713148
	lda	xsp, (xsp+10)
	ret
ToneGen_DSPCfg_ResetAll:
	ld xwa, 0xf9a0
	calr DSPCfg_ResetEntryByTable
	ld xwa, 0xfd60
	jrl DSPCfg_ResetAuxEntries

ToneGen_DSPCfg_ResetAllChannels:
	dec 2, xsp
	push xiz
	ldw (xsp + 4), 0x0
	lda xiz, (0x1ed400:24)

ToneGen_DSPCfg_ResetChannelLoop:
	ld xwa, xiz
	calr DSPCfg_ResetEntryByTable
	incw 1, (xsp + 4)
	lda_dri XIZ, 0xf9, 0xc0, 0x03
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
	.byte 0xde, 0x88, 0xe8, 0x12, 0xe8, 0x8a, 0xea, 0xee
	.byte 0x02, 0xe8, 0x82, 0xea, 0x82, 0x41, 0xe0, 0x8f
	.byte 0xed, 0x00, 0xea, 0x81, 0xaf, 0x02, 0x20, 0x1e
	.byte 0x99, 0x00, 0xde, 0x61, 0xde, 0xcf, 0x2e, 0x00
	.byte 0x67, 0xde, 0xf1, 0x74, 0xfc, 0x31, 0xe9, 0xca
	.byte 0xa0, 0xf9, 0x00, 0x00, 0xaf, 0x02, 0x81, 0xd8
	.byte 0xa8, 0x1d, 0xd3, 0xc4, 0xfd, 0xf1, 0x8e, 0xfc
	.byte 0x31, 0xe9, 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xaf
	.byte 0x02, 0x81, 0xd8, 0xa9, 0x1d, 0xd3, 0xc4, 0xfd
	.byte 0xf1, 0xc2, 0xfc, 0x31, 0xe9, 0xca, 0xa0, 0xf9
	.byte 0x00, 0x00, 0xaf, 0x02, 0x81, 0xd8, 0xaa, 0x1d
	.byte 0xd3, 0xc4, 0xfd, 0xf1, 0xdc, 0xfc, 0x31, 0xe9
	.byte 0xca, 0xa0, 0xf9, 0x00, 0x00, 0xaf, 0x02, 0x81
	.byte 0xd8, 0xab, 0x1d, 0xd3, 0xc4, 0xfd, 0xf1, 0xa8
	.byte 0xfc, 0x31, 0xe9, 0xca, 0xa0, 0xf9, 0x00, 0x00
	.byte 0xaf, 0x02, 0x81, 0xd8, 0xac, 0x1d, 0xd3, 0xc4
	.byte 0xfd, 0x4e, 0xef, 0x64, 0x0e
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
	lda xix, (NakaInst_ExtDevice_Screens_0x2B3E:24)
	ldw_sri DE, 0x07, 0xf0, 0xe8
	lda xix, (DSPCfg_InitDispatch:24)
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
	lda_rr xwa, xwa, bc
	lds ix, 0
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	ld	(xsp+6), c
	ldb_erp c, 248
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
	lda_rr xwa, xwa, bc
	lds iy, 0
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	ldb_erp c, 248
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
	lda	xwa, (0xf480:16)
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
	lda	xsp, (xsp-18)
	push	xiz
	ld	(xsp+18), xbc
	ld	xiz, xwa
	lda	xwa, (48288:16)
	ld	(xsp+14), xwa
	ld	(xsp+10), xwa
	ld	bc, (36930:16)
	jrl	136
	ld	(xsp+6), 0
	ldb_spi	a, 248
	ld	(xsp+8), a
	lds32	xwa, 2
	add	(xsp+18), xwa
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	z, 115
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	.byte 0x86, 0xf1
	jr	z, 87
	cp	bc, 500
	jr	c, 22
	extz	xbc
	.byte 0xaf, 0x0a, 0x81
	ld	(xbc), 255
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	15668425
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	lds	bc, 0
	ld	de, bc
	inc	1, bc
	extz	xde
	.byte 0xaf, 0x0a, 0x82
	ld	a, (xsp+4)
	ld	(xde), a
	ld	de, bc
	inc	1, bc
	extz	xde
	.byte 0xaf, 0x0a, 0x82
	ld	a, (xsp+6)
	ld	(xde), a
	ld	de, bc
	inc	1, bc
	extz	xde
	.byte 0xaf, 0x0a, 0x82
	ld	a, (xiz)
	ld	(xde), a
	ld	xwa, (xsp+18)
	ld	e, (xwa)
	.byte 0x86, 0xd5
	ld	wa, bc
	inc	1, bc
	extz	xwa
	.byte 0xaf, 0x0a, 0x80
	ld	(xwa), e
	incm8	1, (xsp+6)
	decm8	1, (xsp+8)
	inc	1, xiz
	lds32	xwa, 1
	add	(xsp+18), xwa
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, -115
	ldb_spi	a, 248
	ld	(xsp+4), a
	.byte 0x8f, 0x04, 0x3f, 0xff
	jrl	nz, -149
	ld	wa, bc
	extz	xwa
	.byte 0xaf, 0x0e, 0x80
	ld	(xwa), 255
	stda16	36930, bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	ret
	ret
SndParam_SyncDisplayBitmap:
	lds32 xwa, 0
	call 0xfccc66
	ld (0x8dd0:16), l
	ld XWA,0x00000102
	call 0xfccc66
	ld (0x8dd2:16), l
	ld XWA,0x00000103
	call 0xfccc66
	ld (0x8dd4:16), l
	ld XWA,0x00000300
	call 0xfccc66
	ld (0x8dd6:16), l
	ld XWA,0x00004006
	call 0xfccc66
	ld (0x8dd8:16), l
	pushw 0x0620
	pushw 0x0000
	pushw 0xf9a0
	pushw 0x0003
	pushw 0xc8e4
	call 0xff05bc
	lda xsp, (xsp + 0x0a)
	lda xbc, (0xf9a0:16)
	lda xwa, (0xf9b6:16)
	sub XWA,XBC
	lda xde, (0x03c8e4:24)
	add XWA,XDE
	.byte 0x80, 0x3d, 0x01, 0xf1, 0xd0, 0xf9, 0x30, 0xe9
	.byte 0xa0, 0xea, 0x80, 0x80, 0x3d, 0x01, 0xf1, 0xea
	.byte 0xf9, 0x30, 0xe9, 0xa0, 0xea, 0x80, 0x80, 0x3d
	.byte 0x01, 0xf1, 0x97, 0xfd, 0x30, 0xe9, 0xa0, 0xea
	.byte 0x80, 0x80, 0x3e, 0x7f, 0x0e
SoundParam_NotifyMultipleChanges:
	ld	c, (36304:16)
	extz	bc
	lds32	xwa, 0
	lds	de, 0
	call	16566832
	ld	c, (36306:16)
	extz	bc
	ld	xwa, 258
	lds	de, 0
	call	16566832
	ld	c, (36308:16)
	extz	bc
	ld	xwa, 259
	lds	de, 0
	call	16566832
	call	16469470
	jr	0
ToneGen_DiffScanAndUpdate:
	lda	xsp, (xsp-14)
	pushw	iz
	ld	bc, (36930:16)
	lda	xwa, (48288:16)
	ld	(xsp+12), xwa
	ld	(xsp+8), xwa
	lds	iz, 0
	jrl	202
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
	lda xde, (0xfd60:16)
	ld xwa, xde
	sub xwa, 0xf9a0
	ld hl, iz
	extz xhl
	add xhl, xwa
	lda xwa, (0x03c8e4:24)
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
	lda xhl, (0xfd60:16)
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
	lda xwa, (0x03c8e4:24)
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
	lda xde, (0xfd60:16)

	lda xwa, (0xffbe:16)

	sub xwa, xde

	ld hl, iz

	extz xhl

	cp xhl, xwa

	jrl lt, -221

	ld wa, bc

	extz xwa

	add xwa, (xsp + 12)

	ld (xwa), 0xff

	stda16 (36930), bc

	popw iz

	lda xsp, (xsp + 14)

	ret



ToneGen_FileIO_SaveAndSync:
	dec 4,XSP
	push XIZ
	ld XIZ,XWA
	calr SndParam_SyncDisplayBitmap
	lda xwa, (xsp + 0x04)
	.byte 0xb0, 0x14, 0x50, 0xfd, 0xb8, 0x01, 0x14, 0x52, 0xfd, 0xb8, 0x02, 0x14, 0x54, 0xfd
	lda	xwa, (64930:16)
	lda	xbc, (63904:16)
	sub	xwa, xbc
	pushw	wa
	push	xiz
	push	xbc
	call	16713148
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+4)
	.byte 0x80, 0x19, 0x50, 0xfd, 0x88, 0x01, 0x19, 0x52, 0xfd, 0x88, 0x02, 0x19, 0x54, 0xfd
	call	16532608
	call	16532768
	calr	-390
	pop	xiz
	inc	4, xsp
	ret
ToneGen_FileIO_RestoreFromBackup:
	calr SndParam_SyncDisplayBitmap
	pushw 0x0620
	pushw 0x0003
	pushw 0xcf04
	pushw 0x0000
	pushw 0xf9a0
	call 0xff05bc
	lda xsp, (xsp + 0x0a)
	setda 5, (0x8dda)
	calr SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call ToneGen_DispatchByMode
	call CtrlPanel_RefreshIndicatorState
	call SwbtWr_NullRet
	resda 5, (0x8dda)
	ret
ToneGen_FlashVerify:
	lda xhl, (NakaInst_ExtDevice_Screens_0x2B6E:24)
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
	push	xiz
	ld	xwa, 4009984
	push	xwa
	lds	wa, 1
	ld	xbc, 15569722
	ldw	de, 250
	call	15678482
	lda	xbc, (15569972:24)
	ld	xwa, 4010256
	push	xwa
	lds	wa, 1
	ldw	de, 234
	call	15678482
	lda	xbc, (15570206:24)
	ld	xwa, 4010512
	push	xwa
	lds	wa, 1
	ldw	de, 234
	call	15678482
	pushw	80
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 123
	pushw	0
	pushw	80
	push	xiz
	call	16713757
	pushw	2
	pushw	237
	pushw	37660
	push	xiz
	call	16713148
	pushw	12
	pushw	237
	pushw	37668
	lda	xwa, (xiz+16)
	push	xwa
	call	16713148
	lda	xsp, (xsp+28)
	pushw	4
	pushw	237
	pushw	37680
	lda	xwa, (xiz+32)
	push	xwa
	call	16713148
	pushw	4
	pushw	237
	pushw	37664
	lda	xwa, (xiz+48)
	push	xwa
	call	16713148
	pushw	6
	pushw	237
	pushw	37684
	lda	xwa, (xiz+64)
	push	xwa
	call	16713148
	lda	xsp, (xsp+30)
	ld	xwa, 4011008
	push	xwa
	lds	wa, 1
	ld	xbc, xiz
	ldw	de, 80
	call	15678482
	push	xiz
	call	16712469
	inc	4, xsp
ToneGen_FlashWriteDone:
	pop xiz
	ret

ToneGen_FlashReadAndRestore:
	push	xiz
	pushw	80
	call	16713379
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, 127
	pushw	0
	pushw	80
	push	xiz
	call	16713757
	pushw	2
	ld	xwa, 4011008
	push	xwa
	push	xiz
	call	16713148
	pushw	12
	pushw	237
	pushw	37668
	lda	xwa, (xiz+16)
	push	xwa
	call	16713148
	lda	xsp, (xsp+28)
	pushw	4
	pushw	237
	pushw	37680
	lda	xwa, (xiz+32)
	push	xwa
	call	16713148
	pushw	4
	pushw	237
	pushw	37664
	lda	xwa, (xiz+48)
	push	xwa
	call	16713148
	pushw	6
	pushw	237
	pushw	37684
	lda	xwa, (xiz+64)
	push	xwa
	call	16713148
	lda	xsp, (xsp+30)
	ld	xwa, 4011008
	push	xwa
	lds	wa, 1
	ld	xbc, xiz
	ldw	de, 80
	call	15678482
	push	xiz
	call	16712469
	inc	4, xsp
	call	16442410
DSPCfg_Param_CaseA:
	pop xiz
	ret

; DSP config parameter handler B
DSPCfg_Param_CaseB:
	pushw	2
	ld	xwa, 4011008
	push	xwa
	pushw	3
	pushw	16612
	call	16713148
	pushw	12
	ld	xwa, 4011024
	push	xwa
	pushw	3
	pushw	16614
	call	16713148
	pushw	4
	ld	xwa, 4011040
	push	xwa
	pushw	3
	pushw	16626
	call	16713148
	lda	xsp, (xsp+30)
	pushw	4
	ld	xwa, 4011056
	push	xwa
	pushw	3
	pushw	16630
	call	16713148
	pushw	6
	ld	xwa, 4011072
	push	xwa
	pushw	3
	pushw	16634
	call	16713148
	lda	xsp, (xsp+20)
	ret
CtrlPanel_IndicatorJumpTable:
	extz wa
	cps wa, 0
	ret mi
	cp wa, 0x8
	ret gt
	add wa, wa
	lda xix, (NakaInst_ExtDevice_Screens_0x2E3C:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (DSPCfg_Param_CaseC:24)
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
	lda xix, (NakaInst_ExtDevice_Screens_0x2E4E:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (DSPCfg_Param_CaseD:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DSP config parameter handler D
DSPCfg_Param_CaseD:
	ret
	pushw	2
	ld	xwa, 4011008
	push	xwa
	ld	xwa, 213220
	jr	30
	pushw	12
	ld	xwa, 4011024
	push	xwa
	ld	xwa, 213222
	jr	14
	pushw	4
	ld	xwa, 4011040
	push	xwa
	ld	xwa, 213234
	push	xwa
	jr	32
	pushw	4
	ld	xwa, 4011056
	push	xwa
	pushw	3
	pushw	16630
	jr	15
	pushw	6
	ld	xwa, 4011072
	push	xwa
	pushw	3
	pushw	16634
	call	16713148
	lda	xsp, (xsp+10)
	ret
PanelDisplay_DispatchByMode:
	extz wa
	cps wa, 0
	jrl mi, DSPCfg_Param_Default
	cp wa, 0x8
	jrl gt, DSPCfg_Param_Default
	add wa, wa
	lda xix, (NakaInst_ExtDevice_Screens_0x2E60:24)
	ldw_sri WA, 0x07, 0xf0, 0xe0
	lda xix, (PanelDisplay_DispatchData:24)
	jp_ind 8, 0x07, 0xf0, 0xe0

PanelDisplay_DispatchData:
	ld	xde, 0x3d3400
	lda	xhl, (0x0340e4:24)
	lds	bc, 0
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, 114
	inc	1, bc
	cps	bc, 2
	jr	c, -14
	jr	115
	ld	xde, 0x3d3410
	lda	xhl, (0x0340e6:24)
	lds	bc, 0
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, 86
	inc	1, bc
	cp	bc, 12
	jr	c, -16
	.asciz "hUB 4="
	lda	xhl, (0x0340f2:24)
	lds	bc, 0
	ldb_spi a, 236
	cp_spib a, 232
	jr	nz, 56
	inc	1, bc
	cps	bc, 4
	jr	c, -14
	.asciz "h9B04="
	lda	xhl, (0x0340f6:24)
	lds	bc, 0
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, 28
	inc	1, bc
	cps	bc, 4
	jr	c, -14
	jr	t, 0x1d
	.asciz "B@4="
	lda	xhl, (0x0340fa:24)
	lds	bc, 0
	ldb_spi a, 236
	cp_spib a, 232
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
	stdi8	(49053), 255
	ret
Encoder_Stub1:
	ret

Encoder_Stub2:
	ret

Encoder_Stub3:
	ret

Encoder_AlignByte:
	ret

Encoder_ValueScanAndSync:
	stdi8	(36336), 0
	stdi8	(36338), 0
	jr	6
Encoder_ScanAndSync:
	calr Encoder_ReadNextEntry
	calr Encoder_PrepareCallback

Encoder_SyncLoop:
	call	MidiCC_SyncForceResync
	ld	a, (36336:16)
	extz	wa
	muls	wa, 3
	ld_rrb	a, xhl, wa
	ld	(36340:16), a
	cp	a, 255
	jr	nz, -34	; -> 0xFC4FA2
	ld	a, (36338:16)
	extz	wa
	sll	wa, 2
	lda	xbc, (49053:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 255
	call	MidiCC_ResetState
	jrl	4499	; -> 0xFC6172
Encoder_ReadNextEntry:
	.byte 0x1d, 0x84, 0x64, 0xfc	; call MidiCC_SyncForceResync (v7 addr)

	.byte 0xc1, 0xf0, 0x8d, 0x21	; ldb_d8 a, (0x8e8c) (v7 patched)

	extz wa

	muls wa, 0x3

	lda_dri XIY, 0x07, 0xec, 0xe0

	ld xix, 36316

	ldi85

	ldiw

	incdi8 1, (36336)

	ret



Encoder_PrepareCallback:
	push XIZ
	ld c, (0x8df4:16)
	extz BC
	sla BC, 0x02
	ld XWA,NakaInst_ExtDevice_Screens_0x3452
	cpdi8 (0x8c98), 0x14
	jr nz, .Lc_fc501b
	ld XWA,NakaInst_ExtDevice_Screens_0x34D2
Encoder_ResolveCallbackAddr:
.Lc_fc501b:
	ldl_dri xiz, 0x07, 0xe0, 0xe4
	.byte 0xf1, 0xe0, 0x8d, 0x31, 0xb9, 0x04, 0x00, 0xaa
	.byte 0xb9, 0x05, 0x14, 0xf4, 0x8d, 0xf1, 0xdc, 0x8d
	.byte 0x32, 0x8a, 0x01, 0x21, 0xb9, 0x06, 0x41, 0x8a
	.byte 0x02, 0x21, 0xb9, 0x07, 0x41, 0x68, 0x5b
FileIO_ProcessMaskAndShift:
	.byte 0xf1, 0xdc, 0x8d, 0x33, 0x8e, 0x03, 0x25, 0xcd
	.byte 0x8c, 0x8b, 0x01, 0xc4, 0x8b, 0x02, 0xc5, 0xcd
	.byte 0x8f, 0x8e, 0x02, 0x25, 0xcd, 0x33, 0x04, 0x66
	.byte 0x17, 0xcd, 0x30, 0x04, 0xcd, 0x89, 0xc9, 0xcc
	.byte 0x0f, 0x66, 0x02, 0xcc, 0xfe
FileIO_ShiftLeftLow:
	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftDone
	slla l

FileIO_ShiftDone:
	jr FileIO_CallbackHandler

FileIO_AudioControlStart:

; --- Audio Control, File I/O & MIDI Processing ---
