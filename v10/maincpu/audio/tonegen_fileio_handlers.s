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
	lda xiz, (xiz+960)
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
	ld xix, (xde)
	ld a, (xbc)
	and (xix), a
	inc 5, xde
	inc 5, xbc
	cp xde, xhl
	jr c, ToneGen_ApplyMaskLoop
	ld wa, 0:i3
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
	ld	(xwa+de), c

Voice_InitChannelNext:
	incw 1, (xsp + 10)
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
	lda xiz, (0x1ed400:24)

ToneGen_DSPCfg_ResetChannelLoop:
	ld xwa, xiz
	calr DSPCfg_ResetEntryByTable
	incw 1, (xsp + 4)
	lda xiz, (xiz+960)
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
	ld wa, iz
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	add xde, xde
	ld xbc, NakaInst_ExtDevice_Screens_0x2814
	add xbc, xde
	ld xwa, (xsp + 2)
	calr DSPCfg_Init_Entry1
	inc 1, iz
	cp iz, 0x2e
	jr c, DSPCfg_InitEntryLoop
	lda xbc, (0xfc74:16)
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	ld wa, 0:i3
	call DSPCfg_WriteAllSlots_Combined
	lda xbc, (0xfc8e:16)
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	ld wa, 1:i3
	call DSPCfg_WriteAllSlots_Combined
	lda xbc, (0xfcc2:16)
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	ld wa, 2:i3
	call DSPCfg_WriteAllSlots_Combined
	lda xbc, (0xfcdc:16)
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	ld wa, 3:i3
	call DSPCfg_WriteAllSlots_Combined
	lda xbc, (0xfca8:16)
	sub xbc, 0xf9a0
	add xbc, (xsp + 2)
	ld wa, 4:i3
	call DSPCfg_WriteAllSlots_Combined
	popw iz
	inc 4, xsp
	ret

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
	ld	de, (xix+de)
	lda xix, (DSPCfg_InitDispatch:24)
	jp	t, (xix+de)
; DSPCfg_InitAllEntries dispatch
DSPCfg_InitDispatch:
	calr	DSPCfg_InitDispatchData
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper2
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper3
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper4
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper5
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper6
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper7
	jr	DSPCfg_Init_BoundsCheck_Return
	calr	DSPCfg_Init_BoundsCheck_Helper8
	jr	DSPCfg_Init_BoundsCheck_Return

; DSPCfg_InitAllEntries finalize after dispatch
DSPCfg_Init_Finalize:
	ld hl, 1:i3
DSPCfg_Init_BoundsCheck_Return:
	ret
DSPCfg_InitDispatchData:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	and	(xwa+hl), c
	ld	hl, 3:i3
	ret
DSPCfg_Init_BoundsCheck_Helper:
	ld	xde, xwa
	ld	l, (xbc+0x1)
	extz	hl
	ld	a, (xbc+0x2)
	cpl	a
	and	(xde+hl), a
	ld	hl, 3:i3
	ret
DSPCfg_Init_BoundsCheck_Helper2:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	or	(xwa+hl), c
	ld	hl, 3:i3
	ret
DSPCfg_Init_BoundsCheck_Helper3:
	ld	xde, xwa
	ld	a, (xbc+0x1)
	extz	wa
	lda_rr	xde, xde, wa
	ld	l, (xbc+0x2)
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x3), a
	jr	ugt, DSPCfg_InitDispatchData_Skip
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x4), a
	jr	nc, DSPCfg_InitDispatchData_Skip2
DSPCfg_InitDispatchData_Skip:
	cpl	l
	and	(xde), l
	ld	a, (xbc+0x5)
	or	(xde), a
DSPCfg_InitDispatchData_Skip2:
	ld	hl, 6:i3
	ret
DSPCfg_Init_BoundsCheck_Helper4:
	ld	xde, xwa
	ld	a, (xbc+0x1)
	extz	wa
	lda_rr	xde, xde, wa
	ld	l, (xbc+0x2)
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x3), a
	jr	ugt, DSPCfg_InitDispatchData_Skip3
	ld	a, l
	and	a, (xde)
	cp	(xbc+0x4), a
	jr	c, DSPCfg_InitDispatchData_Skip3
	cpl	l
	and	(xde), l
	ld	a, (xbc+0x5)
	or	(xde), a
DSPCfg_InitDispatchData_Skip3:
	ld	hl, 6:i3
	ret
DSPCfg_Init_BoundsCheck_Helper5:
	dec	6, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+0x1)
	extz	bc
	lda_rr	xwa, xwa, bc
	ld	ix, 0:i3
	lda	xbc, (xde+0x3)
	ld	(xsp+0x2), xbc
	ld	c, (xbc)
	ld	(xsp+0x6), c
	ldfr_berp	c, 248
	extz	iz
	ld	l, (xde+0x2)
	ld	h, l
	and	h, (xwa)
	ld	xiy, 5:i3
	cp	ix, iz
	jr	nc, DSPCfg_Init_BoundsCheck_Skip2
DSPCfg_Init_BoundsCheck_Loop:
	ld	xbc, xiy
	add	xbc, xde
	cp	(xbc), h
	jr	nz, DSPCfg_Init_BoundsCheck_Skip
	ld	a, (xsp+0x6)
	jr	DSPCfg_Init_BoundsCheck_Join
DSPCfg_Init_BoundsCheck_Skip:
	inc	1, ix
	inc	1, xiy
	cp	ix, iz
	jr	c, DSPCfg_Init_BoundsCheck_Loop
DSPCfg_Init_BoundsCheck_Skip2:
	cpl	l
	and	(xwa), l
	ld	c, (xde+0x4)
	or	(xwa), c
	ld	xwa, (xsp+0x2)
	ld	a, (xwa)
DSPCfg_Init_BoundsCheck_Join:
	inc	5, a
	ld	l, a
	extz	hl
	popw	iz
	inc	6, xsp
	ret
DSPCfg_Init_BoundsCheck_Helper6:
	dec	4, xsp
	pushw	iz
	ld	xde, xbc
	ld	c, (xde+0x1)
	extz	bc
	lda_rr	xwa, xwa, bc
	ld	iy, 0:i3
	lda	xbc, (xde+0x3)
	ld	(xsp+0x2), xbc
	ld	c, (xbc)
	ldfr_berp	c, 248
	extz	iz
	ld	l, (xde+0x2)
	ld	h, l
	and	h, (xwa)
	ld	xix, 5:i3
	cp	iy, iz
	jr	nc, DSPCfg_Init_BoundsCheck_Join2
DSPCfg_InitDispatchData_Loop:
	ld	xbc, xix
	add	xbc, xde
	cp	(xbc), h
	jr	nz, DSPCfg_Init_BoundsCheck_Skip3
	cpl	l
	and	(xwa), l
	ld	c, (xde+0x4)
	or	(xwa), c
	jr	DSPCfg_Init_BoundsCheck_Join2
DSPCfg_Init_BoundsCheck_Skip3:
	inc	1, iy
	inc	1, xix
	cp	iy, iz
	jr	c, DSPCfg_InitDispatchData_Loop
DSPCfg_Init_BoundsCheck_Join2:
	ld	xwa, (xsp+0x2)
	ld	l, (xwa)
	inc	5, l
	extz	hl
	popw	iz
	inc	4, xsp
	ret
DSPCfg_Init_BoundsCheck_Helper7:
	ld	xde, xbc
	ld	l, (xde+0x1)
	extz	hl
	ld	c, (xde+0x2)
	st_rrb	c, xwa, hl
	ld	hl, 3:i3
	ret
DSPCfg_Init_BoundsCheck_Helper8:
	ld	c, (xbc+0x1)
	extz	bc
	ld	(xwa+bc), 0x00
	ld	hl, 2:i3
	ret
	lda_d16	xwa, (0xf480)
	jrl	DSPCfg_ResetEntryByTable

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
	lda	xwa, (0xbd3c:16)
	ld	(xsp+14), xwa
	ld	(xsp+10), xwa
	ld	bc, (0x90de:16)
	jrl	DSPCfg_CopyEntryValues_Entry
	ld	(xsp+6), 0
	ld a, (xiz+)
	ld (xsp+8), a
	ld xwa, 2:i3
	add	(xsp+18), xwa
	.byte 0x8f
	ld	(63:8), 0:io
	jr	z, 115
	ld	xwa, (xsp+18)
	ld	a, (xwa)
	.byte 0x86, 0xf1
	jr	z, 87
	cp	bc, 500
	jr	c, 22
	extz	xbc
	.byte 0xaf
	ldw	(129:8), 177:io
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
	ld	bc, 0:i3
	ld	de, bc
	inc	1, bc
	extz	xde
	.byte 0xaf
	ldw	(130:8), 1167:io
	ld	a, 178:opc
	ld	xbc, 0x61d98ad9
	extz	xde
	.byte 0xaf
	ldw	(130:8), 1679:io
	ld	a, 178:opc
	ld	xbc, 0x61d98ad9
	extz	xde
	.byte 0xaf
	ldw	(130:8), 8582:io
	ld	(xde), a
	ld	xwa, (xsp+18)
	ld	e, (xwa)
	.byte 0x86, 0xd5
	ld	wa, bc
	inc	1, bc
	extz	xwa
	.byte 0xaf
	ldw	(128:8), 0x45b0:io
	incm8	1, (xsp+6)
	decm8	1, (xsp+8)
	inc	1, xiz
	ld	xwa, 1:i3
	add	(xsp+18), xwa
	.byte 0x8f
	ld	(63:8), 0:io
	jr	nz, -115
DSPCfg_CopyEntryValues_Entry:
	.byte 0xc5
	swi	0
	ld	a, 191:opc
	.byte 0x04
	ld	xbc, 0xff3f048f
	jrl	nz, -149
	ld	wa, bc
	extz	xwa
	add	xwa, (xsp+14)
	ld	(xwa), 255
	ld	(0x90de:16), bc
	pop	xiz
	lda	xsp, (xsp+18)
	ret
	ret
	ret

SndParam_SyncDisplayBitmap:
	ld xwa, 0:i3
	call SndParam_LookupReadOnly
	ld (0x8e6c:16), l
	ld xwa, 0x102
	call SndParam_LookupReadOnly
	ld (0x8e6e:16), l
	ld xwa, 0x103
	call SndParam_LookupReadOnly
	ld (0x8e70:16), l
	ld xwa, 0x300
	call SndParam_LookupReadOnly
	ld (0x8e72:16), l
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	ld (0x8e74:16), l
	pushw 0x620
	pushw 0x0
	pushw 0xf9a0
	pushw 0x3
	pushw 0xc8e4
	call Mem_Copy
	lda xsp, (xsp + 10)
	lda xbc, (0xf9a0:16)
	lda xwa, (0xf9b6:16)
	sub xwa, xbc
	lda xde, (0x03c8e4:24)
	add xwa, xde
	xormi8 (xwa), 0x1
	lda xwa, (0xf9d0:16)
	sub xwa, xbc
	add xwa, xde
	xormi8 (xwa), 0x1
	lda xwa, (0xf9ea:16)
	sub xwa, xbc
	add xwa, xde
	xormi8 (xwa), 0x1
	lda xwa, (0xfd97:16)
	sub xwa, xbc
	add xwa, xde
	ormi8 (xwa), 0x7f
	ret

SoundParam_NotifyMultipleChanges:
	ld c, (0x8e6c:16)
	extz bc
	ld xwa, 0:i3
	ld de, 0:i3
	call SoundParam_NotifyChange
	ld c, (0x8e6e:16)
	extz bc
	ld xwa, 0x102
	ld de, 0:i3
	call SoundParam_NotifyChange
	ld c, (0x8e70:16)
	extz bc
	ld xwa, 0x103
	ld de, 0:i3
	call SoundParam_NotifyChange
	call BitMapOut_DetectChanges
	jr ToneGen_DiffScanAndUpdate

ToneGen_DiffScanAndUpdate:
	lda xsp, (xsp - 14)
	pushw iz
	ld bc, (0x90de:16)
	lda xwa, (0xbd3c:16)
	ld (xsp + 12), xwa
	ld (xsp + 8), xwa
	ld iz, 0:i3
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
	ld (0x90de:16), bc
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
	lda xwa, (0xfda2:16)
	lda xbc, (0xf9a0:16)
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
	set 5, (0x8e76:16)
	calr SoundParam_NotifyMultipleChanges
	call SwbtWr_ReinitOutputBank
	call ToneGen_DispatchByMode
	call CtrlPanel_RefreshIndicatorState
	call SwbtWr_NullRet
	res 5, (0x8e76:16)
	ret

ToneGen_FlashVerify:
	lda xhl, (ToneGen_FlashVerify_Str_HK:24)
	ld xde, 0x3d3000
	ld bc, 0:i3

ToneGen_FlashVerifyLoop:
	ld A, (xhl+)
	cp A, (xde+)
	jr nz, ToneGen_FlashWriteAll
	inc 1, bc
	cp bc, 3:i3
	jr c, ToneGen_FlashVerifyLoop
	ret

ToneGen_FlashWriteAll:
	push xiz
	ld xwa, 0x3d3000
	push xwa
	ld wa, 1:i3
	ld xbc, ToneGen_FlashVerify_Str_HK
	ldw de, 0xfa
	call FlashWrite
	lda xbc, (NakaInst_ExtDevice_Screens_0x2C68:24)
	ld xwa, 0x3d3110
	push xwa
	ld wa, 1:i3
	ldw de, 0xea
	call FlashWrite
	lda xbc, (NakaInst_ExtDevice_Screens_0x2D52:24)
	ld xwa, 0x3d3210
	push xwa
	ld wa, 1:i3
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
	ld wa, 1:i3
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
	ld wa, 1:i3
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
	cp wa, 0:i3
	ret mi
	cp wa, 0x8
	ret gt
	add wa, wa
	lda xix, (NakaInst_ExtDevice_Screens_0x2E3C:24)
	ld	wa, (xix+wa)
	lda xix, (DSPCfg_Param_CaseC:24)
	jp	t, (xix+wa)

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
	ld	wa, (xix+wa)
	lda xix, (DSPCfg_Param_CaseD:24)
	jp	t, (xix+wa)

; DSP config parameter handler D
DSPCfg_Param_CaseD:
	ret
	pushw	2
	ld	xwa, 0x3d3400
	push	xwa
	ld	xwa, 0x0340e4
	jr	Audio_DispatchCommand_Join
	pushw	12
	ld	xwa, 0x3d3410
	push	xwa
	ld	xwa, 0x0340e6
	jr	Audio_DispatchCommand_Join
	pushw	4
	.asciz "@ 4="
	push	xwa
	ld	xwa, 0x0340f2
Audio_DispatchCommand_Join:
	push	xwa
	jr	Audio_DispatchCommand_Join2
	pushw	4
	ld	xwa, 0x3d3430
	push	xwa
	pushw	3
	pushw	0x40f6
	jr	Audio_DispatchCommand_Join2
	pushw	6
	ld	xwa, 0x3d3440
	push	xwa
	pushw	3
	pushw	0x40fa
Audio_DispatchCommand_Join2:
	call	Mem_Copy
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
	ld	wa, (xix+wa)
	lda xix, (PanelDisplay_DispatchData:24)
	jp	t, (xix+wa)

PanelDisplay_DispatchData:
	ld	xde, 0x3d3400
	lda	xhl, (0x0340e4:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 2:i3
	jr	c, PanelDisplay_DispatchByMode_Loop
	jr	DSPCfg_Param_Default
	ld	xde, 0x3d3410
	lda	xhl, (0x0340e6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop2:
	ld	a, (xhl+)
	cp	a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 12
	jr	c, PanelDisplay_DispatchByMode_Loop2
	.asciz "hUB 4="
	lda	xhl, (0x0340f2:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop3:
	ld a, (xhl+)
	cp a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop3
	.asciz "h9B04="
	lda	xhl, (0x0340f6:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop4:
	ld	a, (xhl+)
	cp a, (xde+)
	jr	nz, PanelDisplay_DispatchByMode_Skip
	inc	1, bc
	cp	bc, 4:i3
	jr	c, PanelDisplay_DispatchByMode_Loop4
	jr	t, DSPCfg_Param_Default
	.asciz "B@4="
	lda	xhl, (0x0340fa:24)
	ld	bc, 0:i3
PanelDisplay_DispatchByMode_Loop5:
	ld a, (xhl+)
	cp a, (xde+)
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
	ld (0xc039:16), 255
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
	ld (0x8e8c:16), 0
	ld (0x8e8e:16), 0
	jr Encoder_SyncLoop

Encoder_ScanAndSync:
	calr Encoder_ReadNextEntry
	calr Encoder_PrepareCallback

Encoder_SyncLoop:
	call MidiCC_SyncForceResync
	ld a, (0x8e8c:16)
	extz wa
	muls wa, 0x3
	ld	a, (xhl+wa)
	ld (0x8e90:16), a
	cp a, 0xff
	jr nz, Encoder_ScanAndSync
	ld a, (0x8e8e:16)
	extz wa
	sll wa, 2
	lda xbc, (0xc039:16)
	extz xwa
	add xwa, xbc
	ld (xwa), 0xff
	call MidiCC_ResetState
	jrl VoiceEntry_FindMasterVolume

Encoder_ReadNextEntry:
	call MidiCC_SyncForceResync
	ld a, (0x8e8c:16)
	extz wa
	muls wa, 0x3
	lda	xiy, (xhl+wa)
	ld xix, 0x8e78
	ldi85
	ldiw
	inc 1, (0x8e8c:16)
	ret

Encoder_PrepareCallback:
	push xiz
	ld c, (0x8e90:16)
	extz bc
	sla bc, 2
	ld xwa, Encoder_PrepareCallback_PtrTable
	cp (0x8d34:16), 20
	jr nz, Encoder_ResolveCallbackAddr
	ld xwa, Encoder_PrepareCallback_PtrTable_2

Encoder_ResolveCallbackAddr:
	ld	xiz, (xwa+bc)
	lda xbc, (0x8e7c:16)
	ld (xbc + 4), 0xaa
	ldmi16 (xbc + 5), 0x8e90
	lda xde, (0x8e78:16)
	ld a, (xde + 1)
	ld (xbc + 6), a
	ld a, (xde + 2)
	ld (xbc + 7), a
	jr FileIO_MainLoop

FileIO_ProcessMaskAndShift:
	lda xhl, (0x8e78:16)
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
