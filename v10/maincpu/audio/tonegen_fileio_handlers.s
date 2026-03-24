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
	lda_24 xiz, 0x1ed400

ToneGen_Config_InitChannelLoop:
	ld xwa, xiz
	calr DSPCfg_InitAllEntries
	incm 1, (xsp + 4)
	st_dri3b H, 0xf9, 0xc0, 0x03
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
	lda_24	xwa, 0x1ED400
	add	xwa, xbc
	calr	317
	ret

ToneGen_Config_InitAndChannels:
	calr ToneGen_Config_InitAllEntries
	jr ToneGen_Config_InitAllChannels

ToneGen_ApplyMaskTable:
	lda_24 xwa, 0xed92d8
	lda xbc, (xwa + 4)
	ld xde, xwa
	lda xhl, (xwa + 25)

ToneGen_ApplyMaskLoop:
	ld xix, (xde)
	ld a, (xbc)
	and (xix), a
	inc 5, xde
	inc 5, xbc
	cp xde, xhl
	jr c, ToneGen_ApplyMaskLoop
	lds wa, 0
	call BitMapOut_PrepareRender_CheckBit2
	pushw 0x10
	pushw 0x20
	pushw 0x0
	pushw 0xf9a2
	call Memset
	inc 8, xsp
	ret

ToneGen_DSPCfg_Initialize:
	calr ToneGen_DSPCfg_ResetAll
	jrl ToneGen_DSPCfg_ResetAllChannels
	ldada xwa, 0xF480
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
	ld xbc, 0xed92f2
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
	lda_dri3 XHL, 0x07, 0xe0, 0xe8

Voice_InitChannelNext:
	incm 1, (xsp + 10)
	cpw (xsp + 10), 0x17
	jr c, Voice_InitChannelLoop
	pop xiz
	lda xsp, (xsp + 14)
	ret

Voice_CopyFromScratch:
	pushw 0x620
	pushw 0x3
	pushw 0xc8e4
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 10)
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
	lda_24 xiz, 0x1ed400

ToneGen_DSPCfg_ResetChannelLoop:
	ld xwa, xiz
	calr DSPCfg_ResetEntryByTable
	incm 1, (xsp + 4)
	st_dri3b H, 0xf9, 0xc0, 0x03
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
	ld xbc, 0xed8fe0
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
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	add xde, xde
	ld xbc, 0xed8fe0
	add xbc, xde
	ld xwa, (xsp + 2)
	calr DSPCfg_Init_Entry1
	inc 1, iz
	cp iz, 0x2e
	jr c, DSPCfg_InitEntryLoop
	ldada xbc, 0xFC74
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	lds wa, 0
	call DSPCfg_WriteAllSlots_Combined
	ldada xbc, 0xFC8E
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	lds wa, 1
	call DSPCfg_WriteAllSlots_Combined
	ldada xbc, 0xFCC2
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	lds wa, 2
	call DSPCfg_WriteAllSlots_Combined
	ldada xbc, 0xFCDC
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	lds wa, 3
	call DSPCfg_WriteAllSlots_Combined
	ldada xbc, 0xFCA8
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	lds wa, 4
	call DSPCfg_WriteAllSlots_Combined
	popw iz
	inc 4, xsp
	ret

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
	ld xbc, 0xed91ac
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
	lda_24 xix, 0xed930a
	ld_sriw3 DE, 0x07, 0xf0, 0xe8
	lda_24 xix, DSPCfg_InitDispatch
	jp_dri 8, 0x07, 0xf0, 0xe8
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
	sbc	xix, 0xE80EABDB
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
	ldw	wa, 0xA8DC
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
	ldw	wa, 0xA8DD
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
	ld	xhl, 0x890EABDB
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
	ldada	xwa, 0xF480
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
	ld xbc, 0xed91ac
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
	ldada	xwa, 0xBD3C
	ld	(xsp+14), xwa
	ld	(xsp+10), xwa
	ldda16	bc, 0x90DE
	jrl	136
	ld	(xsp+6), 0
	.byte 0xc5
	swi	0
	ldb	a, 191
	ldio	65, 232
	.byte 0xaa
	add	(xsp+18), xwa
	.byte 0x8f
	ldio	63, 0
	jr	z, 115
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	.byte 0x86, 0xf1
	jr	z, 87
	cp	bc, 500
	jr	c, 22
	extz	xbc
	.byte 0xaf
	ldwio	129, 177
	swi	7
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	lds	bc, 0
	ld	de, bc
	inc	1, bc
	extz	xde
	.byte 0xaf
	ldwio	130, 1167
	ldb	a, 178
	ld	xbc, 0x61D98AD9
	extz	xde
	.byte 0xaf
	ldwio	130, 1679
	ldb	a, 178
	ld	xbc, 0x61D98AD9
	extz	xde
	.byte 0xaf
	ldwio	130, 8582
	ld	(xde), a
	ld	xwa, (xsp+18)
	ld	e, (xwa)
	.byte 0x86, 0xd5
	ld	wa, bc
	inc	1, bc
	extz	xwa
	.byte 0xaf
	ldwio	128, 0x45B0
	incm8	1, (xsp+6)
	decm8	1, (xsp+8)
	inc	1, xiz
	lds32	xwa, 1
	add	(xsp+18), xwa
	.byte 0x8f
	ldio	63, 0
	jr	nz, -115
	.byte 0xc5
	swi	0
	ldb	a, 191
	.byte 0x04
	ld	xbc, 0xFF3F048F
	jrl	nz, -149
	ld	wa, bc
	extz	xwa
	add	xwa, (xsp+14)
	ld	(xwa), 255
	stda16	0x90DE, bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	ret
	ret

SndParam_SyncDisplayBitmap:
	lds32 xwa, 0
	call SndParam_LookupReadOnly
	stda8 0x8E6C, l
	ld xwa, 0x102
	call SndParam_LookupReadOnly
	stda8 0x8E6E, l
	ld xwa, 0x103
	call SndParam_LookupReadOnly
	stda8 0x8E70, l
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	stda8 0x8E72, l
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	stda8 0x8E74, l
	pushw 0x620
	pushw 0x0
	pushw 0xf9a0
	pushw 0x3
	pushw 0xc8e4
	call Mem_Copy
	lda xsp, (xsp + 10)
	ldada xbc, 0xF9A0
	ldada xwa, 0xF9B6
	sub xwa, xbc
	lda_24 xde, 0x03c8e4
	add xwa, xde
	xormi8 (xwa), 0x1
	ldada xwa, 0xF9D0
	sub xwa, xbc
	add xwa, xde
	xormi8 (xwa), 0x1
	ldada xwa, 0xF9EA
	sub xwa, xbc
	add xwa, xde
	xormi8 (xwa), 0x1
	ldada xwa, 0xFD97
	sub xwa, xbc
	add xwa, xde
	ormi8 (xwa), 0x7f
	ret

SoundParam_NotifyMultipleChanges:
	ldda8 c, 0x8E6C
	extz bc
	lds32 xwa, 0
	lds de, 0
	call SoundParam_NotifyChange
	ldda8 c, 0x8E6E
	extz bc
	ld xwa, 0x102
	lds de, 0
	call SoundParam_NotifyChange
	ldda8 c, 0x8E70
	extz bc
	ld xwa, 0x103
	lds de, 0
	call SoundParam_NotifyChange
	call BitMapOut_DetectChanges
	jr ToneGen_DiffScanAndUpdate

ToneGen_DiffScanAndUpdate:
	lda xsp, (xsp - 14)
	pushw iz
	ldda16 xbc, 0x90DE
	ldada xwa, 0xBD3C
	ld (xsp + 12), xwa
	ld (xsp + 8), xwa
	lds iz, 0
	jrl ToneGen_DiffScanCheckEnd

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
	ldada xde, 0xFD60
	ld xwa, xde
	sub xwa, 0xf9a0
	ld hl, iz
	extz xhl
	add xhl, xwa
	lda_24 xwa, 0x03c8e4
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
	ldada xhl, 0xFD60
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
	lda_24 xwa, 0x03c8e4
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
	ldada xde, 0xFD60
	ldada xwa, 0xFFBE
	sub xwa, xde
	ld hl, iz
	extz xhl
	cp xhl, xwa
	jrl lt, ToneGen_DiffScanOuter
	ld wa, bc
	extz xwa
	add xwa, (xsp + 12)
	ld (xwa), 0xff
	stda16 0x90DE, xbc
	popw iz
	lda xsp, (xsp + 14)
	ret

ToneGen_FileIO_SaveAndSync:
	dec 4, xsp
	push xiz
	ld xiz, xwa
	calr SndParam_SyncDisplayBitmap
	lda xwa, (xsp + 4)
	ldmi16 (xwa), 0xfd50
	ldmi16 (xwa + 1), 0xfd52
	ldmi16 (xwa + 2), 0xfd54
	ldada xwa, 0xFDA2
	ldada xbc, 0xF9A0
	sub xwa, xbc
	pushw wa
	push xiz
	push xbc
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 4)
	mrib4 0x80, 0x19, 0x50, 0xfd
	mrdb5 0x88, 0x01, 0x19, 0x52, 0xfd
	mrdb5 0x88, 0x02, 0x19, 0x54, 0xfd
	call ToneGen_Config_InitAllEntries
	call ToneGen_InitAllChannelEntries_Skip
	calr SoundParam_NotifyMultipleChanges
	pop xiz
	inc 4, xsp
	ret

ToneGen_FileIO_RestoreFromBackup:
	calr SndParam_SyncDisplayBitmap
	pushw 0x620
	pushw 0x3
	pushw 0xcf04
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 10)
	setda 5, 0x8E76
	calr SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call ToneGen_DispatchByMode
	call CtrlPanel_RefreshIndicatorState
	call SwbtWr_NullRet
	resda 5, 0x8E76
	ret

ToneGen_FlashVerify:
	lda_24 xhl, 0xed933a
	ld xde, 0x3d3000
	lds bc, 0

ToneGen_FlashVerifyLoop:
	ld_spib A, 0xec
	cp_spib A, 0xe8
	jr nz, ToneGen_FlashWriteAll
	inc 1, bc
	cps bc, 3
	jr c, ToneGen_FlashVerifyLoop
	ret

ToneGen_FlashWriteAll:
	push xiz
	ld xwa, 0x3d3000
	push xwa
	lds wa, 1
	ld xbc, 0xed933a
	ldw de, 0xfa
	call FlashWrite
	lda_24 xbc, 0xed9434
	ld xwa, 0x3d3110
	push xwa
	lds wa, 1
	ldw de, 0xea
	call FlashWrite
	lda_24 xbc, 0xed951e
	ld xwa, 0x3d3210
	push xwa
	lds wa, 1
	ldw de, 0xea
	call FlashWrite
	pushw 0x50
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, ToneGen_FlashWriteDone
	pushw 0x0
	pushw 0x50
	push xiz
	call Memset
	pushw 0x2
	pushw 0xed
	pushw 0x931c
	push xiz
	call Mem_Copy
	pushw 0xc
	pushw 0xed
	pushw 0x9324
	lda xwa, (xiz + 16)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 28)
	pushw 0x4
	pushw 0xed
	pushw 0x9330
	lda xwa, (xiz + 32)
	push xwa
	call Mem_Copy
	pushw 0x4
	pushw 0xed
	pushw 0x9320
	lda xwa, (xiz + 48)
	push xwa
	call Mem_Copy
	pushw 0x6
	pushw 0xed
	pushw 0x9334
	lda xwa, (xiz + 64)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 30)
	ld xwa, 0x3d3400
	push xwa
	lds wa, 1
	ld xbc, xiz
	ldw de, 0x50
	call FlashWrite
	push xiz
	call Free
	inc 4, xsp

ToneGen_FlashWriteDone:
	pop xiz
	ret

ToneGen_FlashReadAndRestore:
	push xiz
	pushw 0x50
	call Malloc
	inc 2, xsp
	ld xiz, xhl
	or xiz, xiz
	jr z, DSPCfg_Param_CaseA
	pushw 0x0
	pushw 0x50
	push xiz
	call Memset
	pushw 0x2
	ld xwa, 0x3d3400
	push xwa
	push xiz
	call Mem_Copy
	pushw 0xc
	pushw 0xed
	pushw 0x9324
	lda xwa, (xiz + 16)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 28)
	pushw 0x4
	pushw 0xed
	pushw 0x9330
	lda xwa, (xiz + 32)
	push xwa
	call Mem_Copy
	pushw 0x4
	pushw 0xed
	pushw 0x9320
	lda xwa, (xiz + 48)
	push xwa
	call Mem_Copy
	pushw 0x6
	pushw 0xed
	pushw 0x9334
	lda xwa, (xiz + 64)
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 30)
	ld xwa, 0x3d3400
	push xwa
	lds wa, 1
	ld xbc, xiz
	ldw de, 0x50
	call FlashWrite
	push xiz
	call Free
	inc 4, xsp
	call Gfx_ClearFrameBuffers

; DSP config parameter handler A
DSPCfg_Param_CaseA:
	pop xiz
	ret

; DSP config parameter handler B
DSPCfg_Param_CaseB:
	pushw 0x2
	ld xwa, 0x3d3400
	push xwa
	pushw 0x3
	pushw 0x40e4
	call Mem_Copy
	pushw 0xc
	ld xwa, 0x3d3410
	push xwa
	pushw 0x3
	pushw 0x40e6
	call Mem_Copy
	pushw 0x4
	ld xwa, 0x3d3420
	push xwa
	pushw 0x3
	pushw 0x40f2
	call Mem_Copy
	lda xsp, (xsp + 30)
	pushw 0x4
	ld xwa, 0x3d3430
	push xwa
	pushw 0x3
	pushw 0x40f6
	call Mem_Copy
	pushw 0x6
	ld xwa, 0x3d3440
	push xwa
	pushw 0x3
	pushw 0x40fa
	call Mem_Copy
	lda xsp, (xsp + 20)
	ret

CtrlPanel_IndicatorJumpTable:
	extz wa
	cps wa, 0
	ret mi
	cp wa, 0x8
	ret gt
	add wa, wa
	lda_24 xix, 0xed9608
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, DSPCfg_Param_CaseC
	jp_dri 8, 0x07, 0xf0, 0xe0

; DSP config parameter handler C
DSPCfg_Param_CaseC:
	ret
	ld	xwa, 0x3D3400
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340E4
	lds	de, 2
	jr	67
	ld	xwa, 0x3D3410
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340E6
	ldw	de, 12
	.asciz "h1@ 4="
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340F2
	lds	de, 4
	.asciz "h @04="
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340F6
	lds	de, 4
	jr	15
	ld	xwa, 0x3D3440
	push	xwa
	lds	wa, 1
	ld	xbc, 0x0340FA
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
	lda_24 xix, 0xed961a
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, DSPCfg_Param_CaseD
	jp_dri 8, 0x07, 0xf0, 0xe0

; DSP config parameter handler D
DSPCfg_Param_CaseD:
	ret
	pushw	2
	ld	xwa, 0x3D3400
	push	xwa
	ld	xwa, 0x0340E4
	jr	30
	pushw	12
	ld	xwa, 0x3D3410
	push	xwa
	ld	xwa, 0x0340E6
	jr	14
	pushw	4
	.asciz "@ 4="
	push	xwa
	ld	xwa, 0x0340F2
	push	xwa
	jr	32
	pushw	4
	ld	xwa, 0x3D3430
	push	xwa
	pushw	3
	pushw	0x40F6
	jr	15
	pushw	6
	ld	xwa, 0x3D3440
	push	xwa
	pushw	3
	pushw	0x40FA
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret

PanelDisplay_DispatchByMode:
	extz wa
	cps wa, 0
	jrl mi, DSPCfg_Param_Default
	cp wa, 0x8
	jrl gt, DSPCfg_Param_Default
	add wa, wa
	lda_24 xix, 0xed962c
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, PanelDisplay_DispatchData
	jp_dri 8, 0x07, 0xf0, 0xe0

PanelDisplay_DispatchData:
	ld	xde, 0x3D3400
	lda_24	xhl, 0x0340E4
	lds	bc, 0
	ld_spib	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 114
	inc	1, bc
	cps	bc, 2
	jr	c, -14
	jr	115
	ld	xde, 0x3D3410
	lda_24	xhl, 0x0340E6
	lds	bc, 0
	ld_spib	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 86
	inc	1, bc
	cp	bc, 12
	jr	c, -16
	.asciz "hUB 4="
	lda_24	xhl, 0x0340F2
	lds	bc, 0
	.byte 0xc5, 0xec
	ldb	a, 197
	cp	xbc, xwa
	jr	nz, 56
	inc	1, bc
	cps	bc, 4
	jr	c, -14
	.asciz "h9B04="
	lda_24	xhl, 0x0340F6
	lds	bc, 0
	ld_spib	a, 236
	.byte 0xc5
	cp	xbc, xwa
	jr	nz, 28
	inc	1, bc
	cps	bc, 4
	jr	c, 16777202
	jr	t, 0x1d
	.asciz "B@4="
	lda_24	xhl, 0x0340FA
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
	stdi8 0xC039, 255
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
	stdi8 0x8E8C, 0
	stdi8 0x8E8E, 0
	jr Encoder_SyncLoop

Encoder_ScanAndSync:
	calr Encoder_ReadNextEntry
	calr Encoder_PrepareCallback

Encoder_SyncLoop:
	call MidiCC_SyncForceResync
	ldda8 a, 0x8E8C
	extz wa
	muls wa, 0x3
	ld_srib3 A, 0x07, 0xec, 0xe0
	stda8 0x8E90, a
	cp a, 0xff
	jr nz, Encoder_ScanAndSync
	ldda8 a, 0x8E8E
	extz wa
	sll wa, 2
	ldada xbc, 0xC039
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	call MidiCC_ResetState
	jrl VoiceEntry_FindMasterVolume

Encoder_ReadNextEntry:
	call MidiCC_SyncForceResync
	ldda8 a, 0x8E8C
	extz wa
	muls wa, 0x3
	st_dri3b E, 0x07, 0xec, 0xe0
	ld xix, 0x8e78
	ldi85
	ldiw
	incdi8 1, 0x8E8C
	ret

Encoder_PrepareCallback:
	push xiz
	ldda8 c, 0x8E90
	extz bc
	sla bc, 2
	ld xwa, 0xed9c1e
	cpdi8 0x8D34, 20
	jr nz, Encoder_ResolveCallbackAddr
	ld xwa, 0xed9c9e

Encoder_ResolveCallbackAddr:
	ld_sril3 XIZ, 0x07, 0xe0, 0xe4
	ldada xbc, 0x8E7C
	ld (xbc + 4), 0xaa
	ldmi16 (xbc + 5), 0x8e90
	ldada xde, 0x8E78
	ld a, (xde + 1)
	ld (xbc + 6), a
	ld a, (xde + 2)
	ld (xbc + 7), a
	jr FileIO_MainLoop

FileIO_ProcessMaskAndShift:
	ldada xhl, 0x8E78
	ld e, (xiz + 3)
	ld d, e
	and d, (xhl + 1)
	and e, (xhl + 2)
	ld l, e
	ld e, (xiz + 2)
	bit 4, e
	jr z, FileIO_AudioControlStart
	res 4, e
	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftLeftLow
	slla d

FileIO_ShiftLeftLow:
	ld a, e
	and a, 0xf
	jr z, FileIO_ShiftDone
	slla l

FileIO_ShiftDone:
	jr FileIO_CallbackHandler

FileIO_AudioControlStart:

; --- Audio Control, File I/O & MIDI Processing ---
