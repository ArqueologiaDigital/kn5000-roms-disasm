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
	jr	c, ToneGen_IncrementWrap128_Return
	ld	ix, 0:i3
ToneGen_IncrementWrap128_Return:
	ret
	cp	ix, 0:i3
	jr	nz, ToneGen_IncrementWrap128_Skip
	ldw	ix, 127
	ret
ToneGen_IncrementWrap128_Skip:
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
	calr	DSPCfg_InitAllEntries
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
	ld	wa, 0:i3
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
	ld iz, 0:i3

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
	ld iz, 0:i3

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
	ld iz, 0:i3

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
	cp de, 0:i3
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
	ld hl, 1:i3
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
	ld	hl, 3:i3
	ret
	ld	xde, xbc
	ld	l, (xde+1)
	extz	hl
	ld	c, (xde+2)
	.byte 0xc3
	reti
	.byte 0xe0, 0xec
	cp	xhl, 3:i3
	or	(xhl+14), xwa
	.byte 0x8a
	ld	a, (xbc+1)
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xwa
	ldw	de, 649
	ld	l, 207:opc
	.byte 0x89, 0x82
	cp	(905:16), a
	jr	ugt, 9
	ld	a, l
	.byte 0x82
	cp	(1161:16), a
	jr	nc, 9
	cpl	l
	and	(xde), l
	ld	a, (xbc+5)
	or	(xde), a
	ld	hl, 6:i3
	ret
	ld	xde, xwa
	ld	a, (xbc+1)
	extz	wa
	.byte 0xf3
	reti
	or	xwa, xwa
	ldw	de, 649
	ld	l, 207:opc
	.byte 0x89, 0x82
	cp	(905:16), a
	jr	ugt, 18
	ld	a, l
	.byte 0x82
	cp	(1161:16), a
	jr	c, 9
	cpl	l
	and	(xde), l
	ld	a, (xbc+5)
	or	(xde), a
	ld	hl, 6:i3
	ret
	dec	6, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+1)
	extz	bc
	lda_rr xwa, xwa, bc
	ld ix, 0:i3
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	ld	(xsp+6), c
	ldb_erp c, 248
	extz	iz
	ld	l, (xde+2)
	ld	h, l
	.byte 0x80, 0xc6
	ld	xiy, 5:i3
	cp	ix, iz
	jr	nc, DSPCfg_Init_BoundsCheck_Skip2
DSPCfg_Init_BoundsCheck_Loop:
	ld	xbc, xiy
	add	xbc, xde
	cp	(xbc), h
	jr	nz, DSPCfg_Init_BoundsCheck_Skip
	ld	a, (xsp+6)
	jr	DSPCfg_Init_BoundsCheck_Join
DSPCfg_Init_BoundsCheck_Skip:
	inc	1, ix
	inc	1, xiy
	cp	ix, iz
	jr	c, DSPCfg_Init_BoundsCheck_Loop
DSPCfg_Init_BoundsCheck_Skip2:
	cpl	l
	and	(xwa), l
	ld	c, (xde+4)
	or	(xwa), c
	ld	xwa, (xsp+2)
	ld	a, (xwa)
DSPCfg_Init_BoundsCheck_Join:
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
	ld iy, 0:i3
	lda	xbc, (xde+3)
	ld	(xsp+2), xbc
	ld	c, (xbc)
	ldb_erp c, 248
	extz	iz
	ld	l, (xde+2)
	ld	h, l
	.byte 0x80, 0xc6
	ld	xix, 5:i3
	cp	iy, iz
	jr	nc, DSPCfg_Init_BoundsCheck_Join2
	ld	xbc, xix
	add	xbc, xde
	cp	(xbc), h
	jr	nz, DSPCfg_Init_BoundsCheck_Skip3
	cpl	l
	and	(xwa), l
	ld	c, (xde+4)
	or	(xwa), c
	jr	DSPCfg_Init_BoundsCheck_Join2
DSPCfg_Init_BoundsCheck_Skip3:
	inc	1, iy
	inc	1, xix
	cp	iy, iz
	jr	c, -27
DSPCfg_Init_BoundsCheck_Join2:
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
	ld	c, 217:opc
	ccf
	.byte 0xf3
	reti
	.byte 0xe0, 0xe4
	nop
	nop
	ld	hl, 2:i3
	ret
	lda	xwa, (0xf480:16)
	jrl	-718

DSPCfg_ResetAuxEntries:
	dec 4, xsp
	pushw iz
	ld (xsp + 2), xwa
	ld iz, 0:i3

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
	jrl	DSPCfg_CopyEntryValues_Join
DSPCfg_CopyEntryValues_Loop:
	ld	(xsp+6), 0
	ldb_spi	a, 248
	ld	(xsp+8), a
	ld	xwa, 2:i3
	add	(xsp+18), xwa
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	z, DSPCfg_CopyEntryValues_Join
DSPCfg_CopyEntryValues_Loop2:
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	.byte 0x86, 0xf1
	jr	z, DSPCfg_CopyEntryValues_Skip2
	cp	bc, 500
	jr	c, DSPCfg_CopyEntryValues_Skip
	extz	xbc
	.byte 0xaf, 0x0a, 0x81
	ld	(xbc), 255
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SwbtWr_ReinitOutputBank
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	bc, 0:i3
DSPCfg_CopyEntryValues_Skip:
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
DSPCfg_CopyEntryValues_Skip2:
	incm8	1, (xsp+6)
	decm8	1, (xsp+8)
	inc	1, xiz
	ld	xwa, 1:i3
	add	(xsp+18), xwa
	.byte 0x8f, 0x08, 0x3f, 0x00
	jr	nz, DSPCfg_CopyEntryValues_Loop2
DSPCfg_CopyEntryValues_Join:
	ldb_spi	a, 248
	ld	(xsp+4), a
	.byte 0x8f, 0x04, 0x3f, 0xff
	jrl	nz, DSPCfg_CopyEntryValues_Loop
	ld	wa, bc
	extz	xwa
	.byte 0xaf, 0x0e, 0x80
	ld	(xwa), 255
	ld	(36930:16), bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	ret
	ret
SndParam_SyncDisplayBitmap:
	ld xwa, 0:i3
	call AcApcToggleProc_Helper
	ld (0x8dd0:16), l
	ld XWA,0x00000102
	call AcApcToggleProc_Helper
	ld (0x8dd2:16), l
	ld XWA,0x00000103
	call AcApcToggleProc_Helper
	ld (0x8dd4:16), l
	ld XWA,0x00000300
	call AcApcToggleProc_Helper
	ld (0x8dd6:16), l
	ld XWA,0x00004006
	call AcApcToggleProc_Helper
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
	ld	xwa, 0:i3
	ld	de, 0:i3
	call	16566832
	ld	c, (36306:16)
	extz	bc
	ld	xwa, 258
	ld	de, 0:i3
	call	16566832
	ld	c, (36308:16)
	extz	bc
	ld	xwa, 259
	ld	de, 0:i3
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
	ld	iz, 0:i3
	jrl	ToneGen_DiffScanCheckEnd
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
	ld bc, 0:i3

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

	jrl lt, ToneGen_DiffScanOuter

	ld wa, bc

	extz xwa

	add xwa, (xsp + 12)

	ld (xwa), 0xff

	ld (36930:16), bc

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
	set 5, (0x8dda:16)
	calr SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call ToneGen_DispatchByMode
	call CtrlPanel_RefreshIndicatorState
	call SwbtWr_NullRet
	res 5, (0x8dda:16)
	ret
ToneGen_FlashVerify:
	lda xhl, (NakaInst_ExtDevice_Screens_0x2B6E:24)
	ld xde, 0x3d3000
	ld bc, 0:i3

ToneGen_FlashVerifyLoop:
	ldb_spi A, 0xec
	cp_spib A, 0xe8
	jr nz, ToneGen_FlashWriteAll
	inc 1, bc
	cp bc, 3:i3
	jr c, ToneGen_FlashVerifyLoop
	ret

ToneGen_FlashWriteAll:
	push	xiz
	ld	xwa, 4009984
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 15569722
	ldw	de, 250
	call	FlashWrite
	lda	xbc, (15569972:24)
	ld	xwa, 4010256
	push	xwa
	ld	wa, 1:i3
	ldw	de, 234
	call	FlashWrite
	lda	xbc, (15570206:24)
	ld	xwa, 4010512
	push	xwa
	ld	wa, 1:i3
	ldw	de, 234
	call	FlashWrite
	pushw	80
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, ToneGen_FlashWriteDone
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
	ld	wa, 1:i3
	ld	xbc, xiz
	ldw	de, 80
	call	FlashWrite
	push	xiz
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
ToneGen_FlashWriteDone:
	pop xiz
	ret

ToneGen_FlashReadAndRestore:
	push	xiz
	pushw	80
	call	SLIDE_Decompress_4K_Init_Helper2
	inc	2, xsp
	ld	xiz, xhl
	or	xiz, xiz
	jr	z, DSPCfg_Param_CaseA
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
	ld	wa, 1:i3
	ld	xbc, xiz
	ldw	de, 80
	call	FlashWrite
	push	xiz
	call	SLIDE_Decompress_4K_Init_Helper
	inc	4, xsp
	call	Gfx_ClearFrameBuffers
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
	cp wa, 0:i3
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
	ld	wa, 1:i3
	ld	xbc, 0x0340e4
	ld	de, 2:i3
	jr	CtrlPanel_IndicatorJumpTable_Join
	ld	xwa, 0x3d3410
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340e6
	ldw	de, 12
	.asciz "h1@ 4="
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340f2
	ld	de, 4:i3
	.asciz "h @04="
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340f6
	ld	de, 4:i3
	jr	CtrlPanel_IndicatorJumpTable_Join
	ld	xwa, 0x3d3440
	push	xwa
	ld	wa, 1:i3
	ld	xbc, 0x0340fa
	ld	de, 6:i3
CtrlPanel_IndicatorJumpTable_Join:
	call	FlashWrite
	ret

Audio_DispatchCommand:
	extz wa
	cp wa, 0:i3
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
	jr	Audio_DispatchCommand_Join
	pushw	12
	ld	xwa, 4011024
	push	xwa
	ld	xwa, 213222
	jr	Audio_DispatchCommand_Join
	pushw	4
	ld	xwa, 4011040
	push	xwa
	ld	xwa, 213234
Audio_DispatchCommand_Join:
	push	xwa
	jr	Audio_DispatchCommand_Join2
	pushw	4
	ld	xwa, 4011056
	push	xwa
	pushw	3
	pushw	16630
	jr	Audio_DispatchCommand_Join2
	pushw	6
	ld	xwa, 4011072
	push	xwa
	pushw	3
	pushw	16634
Audio_DispatchCommand_Join2:
	call	16713148
	lda	xsp, (xsp+10)
	ret
PanelDisplay_DispatchByMode:
	extz wa
	cp wa, 0:i3
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
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop:
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 2:i3
	jr	c, PanelDisplay_DispatchByMode_Loop
	jr	DSPCfg_Param_Default
	ld	xde, 0x3d3410
	lda	xhl, (0x0340e6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop2:
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 12
	jr	c, PanelDisplay_DispatchByMode_Loop2
	.asciz "hUB 4="
	lda	xhl, (0x0340f2:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop3:
	ldb_spi a, 236
	cp_spib a, 232
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop3
	.asciz "h9B04="
	lda	xhl, (0x0340f6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop4:
	ldb_spi	a, 236
	cp_spib a, 232
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop4
	jr	t, DSPCfg_Param_Default
	.asciz "B@4="
	lda	xhl, (0x0340fa:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop5:
	ldb_spi a, 236
	cp_spib a, 232
	jr	z, PanelDisplay_DispatchByMode_Skip2
PanelDisplay_DispatchByMode_Skip:
	ld	hl, 1:i3
	ret
PanelDisplay_DispatchByMode_Skip2:
	inc	1, bc
	cp	bc, 6:i3
	jr	c, PanelDisplay_DispatchByMode_Loop5

; DSP config parameter default handler
DSPCfg_Param_Default:
	ld hl, 0:i3
	ret

Encoder_MarkInvalid:
	ld	(49053:16), 255
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
	ld	(36336:16), 0
	ld	(36338:16), 0
	jr	Encoder_SyncLoop
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
	jr	nz, Encoder_ScanAndSync	; -> 0xFC4FA2
	ld	a, (36338:16)
	extz	wa
	sll	wa, 2
	lda	xbc, (49053:16)
	extz	xwa
	add	xwa, xbc
	ld	(xwa), 255
	call	MidiCC_ResetState
	jrl	VoiceEntry_FindMasterVolume	; -> 0xFC6172
Encoder_ReadNextEntry:
	.byte 0x1d, 0x84, 0x64, 0xfc	; call MidiCC_SyncForceResync (v7 addr)

	.byte 0xc1, 0xf0, 0x8d, 0x21	; ldb_d8 a, (0x8e8c) (v7 patched)

	extz wa

	muls wa, 0x3

	lda_dri XIY, 0x07, 0xec, 0xe0

	ld xix, 36316

	ldi85

	ldiw

	inc 1, (36336:16)

	ret



Encoder_PrepareCallback:
	push XIZ
	ld c, (0x8df4:16)
	extz BC
	sla BC, 0x02
	ld XWA,NakaInst_ExtDevice_Screens_0x3452
	cp (0x8c98:16), 0x14
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
