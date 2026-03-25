; =============================================================================
; Bitmap Output Routines
; =============================================================================
;
; Bitmap blitting and palette loading for VGA display.
; Handles bitmap decompression and rendering to the framebuffer.
; =============================================================================

BitMapOut_PaletteLoadLoop:
	lda xwa, (xiz + 54)
	ld (xsp + 12), xwa
	ld xwa, (xsp + 16)
	add (xsp + 12), xwa
	ld xwa, (xsp + 12)
	ld c, (xwa + 2)
	srl c, 4
	extz bc
	ldw wa, 0x3c9
	calr _Write_VGA_Register
	ld xwa, (xsp + 12)
	ld c, (xwa + 1)
	srl c, 4
	extz bc
	ldw wa, 0x3c9
	calr _Write_VGA_Register
	ld xwa, (xsp + 12)
	ld c, (xwa)
	srl c, 4
	extz bc
	ldw wa, 0x3c9
	calr _Write_VGA_Register
	inc 4, xiz
	cp xiz, 0x400
	jr c, BitMapOut_PaletteLoadLoop
	lds32 xiz, 0
	ld xwa, (xsp + 8)
	lda xde, (xwa + 20)
	ld xwa, (xde)
	cp xwa, 0x0
	jr ule, BitMapOut_BlitComplete
	ld xix, (xsp + 4)
	ld xwa, xix
	lda xhl, (xwa + 1)
	lds32 xbc, 0

BitMapOut_PixelBlitLoop:
	ld a, (xix)
	ldfr_berp A, 0xf4
	extz iy
	ld a, (xhl)
	extz wa
	sll iy, 8
	or iy, wa
	ld xwa, 0x1a0000
	add xwa, xbc
	ld (xwa), iy
	inc 1, xiz
	inc 2, xbc
	cp xiz, (xde)
	jr c, BitMapOut_PixelBlitLoop

BitMapOut_BlitComplete:
	pop xiz
	lda xsp, (xsp + 16)
	ret

BitMapOut_ByteData_RenderA:
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	call	GetTitleNow
	cp	xhl, 0x01a000f6
	ret	z
	.byte 0xc1
	jrl	pl, 16320
	nop
	ret	nz
	calr	605
	cps	l, 0
	ret	nz
	ldda8	a, 0xc07e
	cp	a, 13
	jr	z, 42
	cp	a, 12
	jr	nz, 74
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000ea
	call	ApPostEvent
	lds	wa, 1
	jr	72
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000eb
	call	ApPostEvent
	lds	wa, 1
	jr	35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000e8
	call	ApPostEvent
	lds	wa, 1
	calr	480
	ret
BitMapOut_ByteData_RenderB:
	dec	6, xsp
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	jrl	z, 158
	call	GetTitleNow
	cp	xhl, 0x01a000f6
	jrl	z, 145
	ldda8	a, 0xc080
	.byte 0xc1
	push	xde
	.byte 0x8d
	stdi8	0x867e, 193
	jrl	pl, 16320
	nop
	jr	nz, 127
	calr	429
	cps	l, 0
	jr	nz, 120
	call	GetTitleNow
	cp	xhl, 0x01a000e8
	jr	nz, 108
	ldda8	a, 0x8d3a
	extz	wa
	lds	bc, 0
	call	SndParam_LookupViaEncode
	ld	(xsp+3), l
	ldda8	a, 0x8d3a
	extz	wa
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	lda	xwa, (xsp)
	ld	(xwa+4), l
	.byte 0xb8
	push	sr
	push_a
	push	xde
	.byte 0x8d
	call	SndParam_ResolveVoiceEntry
	.byte 0x8f
	nop
	ldb	a, 201
	.byte 0xcf
	decf
	jr	z, 5
	cp	a, 12
	jr	nz, 18
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e00079
	lds32	xde, 0
	call	ApPostEvent
	jr	35
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20007
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20007
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	calr	310
	inc	6, xsp
	ret
BitMapOut_ByteData_RenderC:
	lds	wa, 0
	jrl	302
BitMapOut_ByteData_RenderD:
	dec	6, xsp
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	jr	z, 120
	call	GetTitleNow
	.long DrawbarSlider_ConfigData
	.byte 0xa0, 0x01
	jr	nz, 108
	.byte 0xc1, 0x80, 0xc0
	push	xsp
	decm	6, (xwa)
	jr	mi, -63
	jrl	pl, 16320
	rcf
	jr	nz, 94
	ldda8	a, 0x8d3a
	extz	wa
	lds	bc, 0
	call	SndParam_LookupViaEncode
	ld	(xsp+3), l
	ldda8	a, 0x8d3a
	extz	wa
	ldw	bc, 32
	call	SndParam_LookupViaEncode
	lda	xwa, (xsp)
	ld	(xwa+4), l
	.byte 0xb8
	push	sr
	push_a
	push	xde
	.byte 0x8d
	call	SndParam_ResolveVoiceEntry
	.byte 0x8f
	nop
	ldb	a, 201
	.byte 0xcf
	decf
	jr	z, 5
	cp	a, 12
	jr	nz, 18
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e00079
	lds32	xde, 0
	call	ApPostEvent
	jr	21
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20007
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	calr	172
	inc	6, xsp
	ret
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	.byte 0xc1
	jrl	pl, 16320
	nop
	ret	nz
	calr	146
	cps	l, 0
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000e9
	call	ApPostEvent
	lds	wa, 1
	calr	109
	ret
BitMapOut_ByteData_RenderE:
	call	Boot_CheckConfigFlag7
	cps	hl, 0
	ret	z
	.byte 0xc1
	jrl	pl, 16320
	nop
	ret	nz
	.byte 0xc1, 0x80, 0xc0
	push	xsp
	popw	wa
	ret	nz
	calr	78
	cps	l, 0
	ret	nz
	call	GetTitleNow
	cp	xhl, 0x01a000e9
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00001
	call	DeleteEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00001
	lds32	xde, 0
	call	ApPostEvent
	lds	wa, 1
	calr	32
	ret

BitMapOut_CheckDiskAndApply:
	cpdi8 0x8d38, 138
	jp_24 z, Interrupt_ModeGuardCheck
	ld xwa, 0xffffffff
	ld xbc, 0x1c20000
	lds32 xde, 0
	jp ApPostEvent
BitMapOut_ByteData_DiskCheck:
	ldda8	l, 0x8d3e
	ret

BitMapOut_StorePresetValue:
	stda8 0x8d3e, a
	ret

BitMapOut_SetDefaultTimer:
	stdi8 0x8d3c, 64
	ret

BitMapOut_DecrementTimer:
	call GetTitleNow
	cp xhl, 0x1a000ef
	jr z, BitMapOut_SetDefaultTimer
	ldda8 a, 0x8d3c
	cps a, 0
	ret z
	dec 1, a
	stda8 0x8d3c, a
	cps a, 0
	ret nz
	lds32 xwa, 3
	call SndParam_LookupReadOnly
	ld de, hl
	pushw 0xff
	ldw wa, 0x70
	lds bc, 2
	call AddswbWr
	ret

BitMapOut_ByteData_TransitionSeq:
	call	GetTitleNow
	cp	xhl, 0x01a00001
	ret	nz
	.byte 0xc1, 0x80, 0xc0
	push	xsp
	cp	(xwa-80), iz
	.byte 0xc1
	jrl	pl, 16320
	pushw	0xfeb0
	ldda8	a, 0xc07e
	andda8	a, 0xc07f
	and	a, 192
	cp	a, 64
	jr	z, 30
	cp	a, 128
	jr	nz, 50
	.byte 0xf1
	pop	xix
	.byte 0x8f
	lda	xwa, (xwa)
	jr	f, 0
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20006
	lds32	xde, 5
	jr	75
	.byte 0xf1
	pop	xix
	.byte 0x8f
	lda	xwa, (xwa)
	jr	f, 0
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20006
	lds32	xde, 6
	jr	50
	.byte 0xf1
	pop	xix
	.byte 0x8f
	ld	(xwa+48), xwa
	nop
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 192
	call	SndParam_LookupReadOnly
	cps	hl, 1
	jr	nz, 14
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20006
	lds32	xde, 3
	jr	12
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20006
	lds32	xde, 1
	call	ApPostEvent
	ret
BitMapOut_ByteData_PresetCopy:
	.byte 0xd7
	swi	2
	.byte 0x04, 0xc1
	ldw	ix, 0x3f8d
	ret
	jr	z, 87
	.byte 0xf1
	ld	xiz, 0x516ecb8d
	.byte 0xc1
	jrl	pl, 16320
	.byte 0x01
	jr	nz, 74
	calr	7325
	bit	1, l
	jr	nz, 60
	ldda8	a, 0xc07e
	res	7, a
	.byte 0xc7
	swi	3
	cp	(xbc-57), hl
	inc	6, wa
	pushw	iy
	.byte 0xc7
	swi	3
	jr	ge, -63
	jrl	nc, 8640
	res	7, a
	cps	a, 0
	jr	z, 31
	ld	xwa, 769
	call	SndParam_LookupReadOnly
	.byte 0xc7
	swi	3
	.byte 0x89
	extz	wa
	cps	hl, 0
	jr	nz, 5
	calr	497
	jr	8
	ld	xbc, 0xf9a0
	calr	14
	ldw	wa, 130
	calr	7268
	.byte 0xf1
	ld	xiz, 0xfad7b38d
	halt
	ret

BitMapOut_CopyVoicePreset9:
	lda xsp, (xsp - 82)
	push xiz
	ld (xsp + 82), xbc
	cp a, 0x80
	jr nz, BitMapOut_CopyPreset9_Clamp50
	ldb a, 0x50
	jr BitMapOut_CopyPreset9_Execute

BitMapOut_CopyPreset9_Clamp50:
	cp a, 0x50
	jrl ugt, BitMapOut_CopyPreset9_Done

BitMapOut_CopyPreset9_Execute:
	ldada xhl, 0xf9a0
	ldada xbc, 0xf9b6
	ld (xsp + 68), xbc
	lda xbc, (xbc + 14)
	sub xbc, xhl
	ld (xsp + 56), xbc
	extz wa
	sla wa, 2
	lda_24 xbc, WidgetStyleDataTable_0x10
	st_dri3b A, 0x07, 0xe4, 0xe0
	ld xwa, (xbc)
	ld xix, (xsp + 56)
	add xix, xwa
	lda xde, (xsp + 72)
	ld a, (xix)
	ld (xde), a
	ldada xwa, 0xf9d0
	ld (xsp + 64), xwa
	lda xwa, (xwa + 14)
	sub xwa, xhl
	ld (xsp + 44), xwa
	ld xwa, (xbc)
	ld xiy, (xsp + 44)
	add xiy, xwa
	lda xwa, (xde + 1)
	ld (xsp + 32), xwa
	ld xix, xwa
	ld a, (xiy)
	ld (xix), a
	ldada xix, 0xf9ea
	lda xwa, (xix + 14)
	sub xwa, xhl
	ld (xsp + 36), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 36)
	add xiz, xwa
	lda xwa, (xde + 2)
	ld (xsp + 28), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	ld xwa, (xsp + 68)
	lda xwa, (xwa + 15)
	sub xwa, xhl
	ld (xsp + 60), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 60)
	add xiz, xwa
	lda xwa, (xde + 3)
	ld (xsp + 24), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	ld xwa, (xsp + 64)
	lda xwa, (xwa + 15)
	sub xwa, xhl
	ld (xsp + 52), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 52)
	add xiz, xwa
	lda xwa, (xde + 4)
	ld (xsp + 20), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	lda xwa, (xix + 15)
	sub xwa, xhl
	ld (xsp + 40), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 40)
	add xiz, xwa
	lda xwa, (xde + 5)
	ld (xsp + 16), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	ld xwa, (xsp + 68)
	lda xwa, (xwa + 17)
	sub xwa, xhl
	ld (xsp + 68), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 68)
	add xiz, xwa
	lda xwa, (xde + 6)
	ld (xsp + 12), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	ld xwa, (xsp + 64)
	lda xwa, (xwa + 17)
	sub xwa, xhl
	ld (xsp + 64), xwa
	ld xwa, (xbc)
	ld xiz, (xsp + 64)
	add xiz, xwa
	lda xwa, (xde + 7)
	ld (xsp + 8), xwa
	ld xiy, xwa
	ld a, (xiz)
	ld (xiy), a
	lda xwa, (xix + 17)
	sub xwa, xhl
	ld (xsp + 48), xwa
	ld xwa, (xbc)
	ld xiy, (xsp + 48)
	add xiy, xwa
	lda xwa, (xde + 8)
	ld (xsp + 4), xwa
	ld xix, xwa
	ld a, (xiy)
	ld (xix), a
	ld xiz, (xbc)
	lds iy, 0
	jr BitMapOut_CopyPreset9_CheckEnd

BitMapOut_CopyPreset9_StoreLoop:
	st_dpib D, 0xf8
	ld wa, iy
	extz xwa
	add xwa, (xsp + 82)
	ld a, (xwa)
	ld (xix), a
	inc 1, iy

BitMapOut_CopyPreset9_CheckEnd:
	ldada xwa, 0xfd5e
	sub xwa, xhl
	ld ix, iy
	extz xix
	cp xix, xwa
	jr le, BitMapOut_CopyPreset9_StoreLoop
	ld xwa, (xbc)
	ld xhl, (xsp + 56)
	add xhl, xwa
	ld a, (xde)
	ld (xhl), a
	ld xwa, (xbc)
	ld xde, (xsp + 44)
	add xde, xwa
	ld xwa, (xsp + 32)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 36)
	add xde, xwa
	ld xwa, (xsp + 28)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 60)
	add xde, xwa
	ld xwa, (xsp + 24)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 52)
	add xde, xwa
	ld xwa, (xsp + 20)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 40)
	add xde, xwa
	ld xwa, (xsp + 16)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 68)
	add xde, xwa
	ld xwa, (xsp + 12)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xde, (xsp + 64)
	add xde, xwa
	ld xwa, (xsp + 8)
	ld a, (xwa)
	ld (xde), a
	ld xwa, (xbc)
	ld xbc, (xsp + 48)
	add xbc, xwa
	ld xwa, (xsp + 4)
	ld a, (xwa)
	ld (xbc), a

BitMapOut_CopyPreset9_Done:
	pop xiz
	lda xsp, (xsp + 82)
	ret

BitMapOut_SnapshotFromROM:
	dec 2, xsp
	ld (xsp), a
	calr BitMapOut_SaveDisplayToROM
	cp (xsp), 0x80
	jr nz, BitMapOut_Snapshot_Clamp50
	ld (xsp), 0x50
	jr BitMapOut_Snapshot_Execute

BitMapOut_Snapshot_Clamp50:
	cp (xsp), 0x50
	jrl ugt, BitMapOut_Snapshot_SetFlags

BitMapOut_Snapshot_Execute:
	ld a, (xsp)
	extz wa
	ld bc, wa
	sla bc, 2
	lda_24 xde, WidgetStyleDataTable_0x10
	ld_sril3 XDE, 0x07, 0xe8, 0xe4
	cp (xde), 0x78
	jr nz, BitMapOut_Snapshot_PostProcess
	ldada xhl, 0xf9b4
	sub xhl, 0xf9a2
	lds32 xbc, 0
	ld c, (xde + 1)
	cp xbc, xhl
	jr nz, BitMapOut_Snapshot_PostProcess
	ldda8 c, 0x8d52
	bit 2, c
	jr nz, BitMapOut_Snapshot_RestoreFull
	bit 1, c
	jr nz, BitMapOut_Snapshot_RestorePartial
	ld xwa, 0x302
	call SndParam_LookupReadOnly
	ld a, (xsp)
	extz wa
	cps hl, 1
	jr nz, BitMapOut_Snapshot_RestoreFull
	calr BitMapOut_RestoreVoiceFields
	jr BitMapOut_Snapshot_PostProcess

BitMapOut_Snapshot_RestorePartial:
	calr BitMapOut_PartialRestore
	jr BitMapOut_Snapshot_PostProcess

BitMapOut_Snapshot_RestoreFull:
	calr BitMapOut_RestoreFullVoice

BitMapOut_Snapshot_PostProcess:
	push xde
	push xhl
	push xix
	push xiz
	call ToneGen_DispatchByMode
	pop xiz
	pop xix
	pop xhl
	pop xde
	calr BitMapOut_DetectChanges
	bitda 4, 0xfd50
	jr nz, BitMapOut_Snapshot_CheckActive
	bitda 1, 0xfd2c
	call_24 nz, BitMapOut_DispatchIOChanges

BitMapOut_Snapshot_CheckActive:
	ld xwa, 0x302
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, BitMapOut_Snapshot_SetFlags
	bitda 6, 0xfd9e
	call_24 z, MidiSysEx_SendAllParams

BitMapOut_Snapshot_SetFlags:
	ldda8 a, 0x8d52
	set 4, a
	and a, 0xf9
	stda8 0x8d52, a
	inc 2, xsp
	ret

BitMapOut_RestoreVoiceFields:
	lda xsp, (xsp - 14)
	push xiz
	ld (xsp + 16), a
	ld a, (xsp + 16)
	extz wa
	calr BitMapOut_CopyROMToWorkspace
	ldada xbc, 0xf9a0
	ldada xwa, 0xfb56
	ld (xsp + 8), xwa
	sub xwa, xbc
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld xde, (xsp + 8)
	ld a, (xwa)
	lda_dpi XBC, 0xe8
	ld xwa, xde
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	ldada xwa, 0xfb70
	ld (xsp + 4), xwa
	sub xwa, xbc
	add xwa, xix
	ld xde, (xsp + 4)
	ld a, (xwa)
	lda_dpi XBC, 0xe8
	ld xwa, xde
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	ldada xde, 0xfb8a
	ld xwa, xde
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	lda xhl, (xde + 1)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xhl), a
	ldada xhl, 0xfba4
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xhl), a
	lda xiy, (xhl + 1)
	ld xwa, xiy
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xiy), a
	ldada xwa, 0xfbbe
	ld (xsp + 12), xwa
	sub xwa, xbc
	add xwa, xix
	ld xiy, (xsp + 12)
	ld a, (xwa)
	lda_dpi XBC, 0xf4
	ld xwa, xiy
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	ld (xiy), a
	ld xwa, (xsp + 8)
	lda xiz, (xwa + 4)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0xb7
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	and w, 0x48
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	ld xwa, (xsp + 4)
	lda xiz, (xwa + 4)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0xb7
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	and w, 0x48
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	lda xiz, (xde + 4)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0xb7
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	and w, 0x48
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	lda xiz, (xhl + 4)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0xb7
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	and w, 0x48
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	ld xwa, (xsp + 12)
	lda xiz, (xwa + 4)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0xb7
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	and w, 0x48
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	ld xwa, (xsp + 8)
	lda xiz, (xwa + 8)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0x80
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	res 7, w
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	ld xwa, (xsp + 4)
	lda xiz, (xwa + 8)
	ld a, (xiz)
	ldfr_berp A, 0xf4
	and_erpb 0xf4, 0x80
	ldto_berp A, 0xf4
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xix
	ld w, (xwa)
	res 7, w
	ldto_berp A, 0xf4
	or a, w
	ldfr_berp A, 0xf4
	ld (xiz), a
	lda xiy, (xde + 8)
	ld e, (xiy)
	and e, 0x80
	ld (xiy), e
	ld xwa, xiy
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	res 7, a
	or e, a
	ld (xiy), e
	inc 8, xhl
	ld e, (xhl)
	and e, 0x80
	ld (xhl), e
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	res 7, a
	or e, a
	ld (xhl), e
	ld xwa, (xsp + 12)
	lda xhl, (xwa + 8)
	ld e, (xhl)
	and e, 0x80
	ld (xhl), e
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xix
	ld a, (xwa)
	res 7, a
	or e, a
	ld (xhl), e
	ldada xiy, 0xfc5e
	ld e, (xiy)
	and e, 0xf8
	ld (xiy), e
	ld xhl, xiy
	sub xhl, xbc
	add xhl, xix
	ld a, (xhl)
	and a, 0x7
	or e, a
	ld (xiy), e
	ldada xwa, 0xfd0c
	resm 7, (xwa)
	resm 7, (xwa + 1)
	resm 7, (xwa + 2)
	bitda 3, 0x8d52
	jr z, BitMapOut_RestoreFields_PostCheck
	ld c, (xiy)
	res 4, c
	ld (xiy), c
	ld a, (xhl)
	and a, 0x10
	or c, a
	ld (xiy), c

BitMapOut_RestoreFields_PostCheck:
	cp (xsp + 16), 0x50
	call_24 nz, BitMapOut_SelectiveFieldRestore
	push xde
	push xhl
	push xix
	push xiz
	call SeqTimer_UpdateTempoReg
	pop xiz
	pop xix
	pop xhl
	pop xde
	pop xiz
	lda xsp, (xsp + 14)
	ret

BitMapOut_RestoreFullVoice:
	lda xsp, (xsp - 24)
	push xiz
	extz wa
	sla wa, 2
	lda_24 xbc, WidgetStyleDataTable_0x10
	exts xwa
	add xwa, xbc
	ld (xsp + 24), xwa
	ld (xsp + 20), xwa
	ld xwa, (xsp + 24)
	ld xhl, (xwa)
	ldada xwa, 0xf9a0
	ld (xsp + 12), xwa
	ld xiy, xwa
	lds ix, 0
	jr BitMapOut_RestoreFull_CheckEnd

BitMapOut_RestoreFull_FieldLoop:
	inc 1, xiy
	ld_spib A, 0xf4
	ldfr_berp A, 0xe6
	inc 1, xhl
	inc 1, xhl
	lds bc, 0
	ldto_berp E, 0xe6
	extz de
	cps de, 0
	jr ule, BitMapOut_RestoreFull_FieldDone

BitMapOut_RestoreFull_CopyField:
	ldto_berp A, 0xe6
	lds32 xiz, 0
	ldfr_berp A, 0xf8
	ldada xwa, 0xf9ce
	sub xwa, 0xf9b6
	cp bc, 0xc
	jr nz, BitMapOut_RestoreFull_CheckType0D
	cp xiz, xwa
	jr nz, BitMapOut_RestoreFull_CheckType0D
	andmi8 (xiy), 0x7
	ld a, (xhl)
	and a, 0xf8
	or (xiy), a
	jr BitMapOut_RestoreFull_SkipField

BitMapOut_RestoreFull_CheckType0D:
	cp bc, 0xd
	jr nz, BitMapOut_RestoreFull_DefaultCopy
	cp xiz, xwa
	jr nz, BitMapOut_RestoreFull_DefaultCopy

BitMapOut_RestoreFull_SkipField:
	inc 1, xiy
	inc 1, xhl
	jr BitMapOut_RestoreFull_NextField

BitMapOut_RestoreFull_DefaultCopy:
	ld_spib A, 0xec
	lda_dpi XBC, 0xf4

BitMapOut_RestoreFull_NextField:
	inc 1, bc
	cp bc, de
	jr c, BitMapOut_RestoreFull_CopyField

BitMapOut_RestoreFull_FieldDone:
	add ix, bc
	inc 1, ix
	inc 1, ix

BitMapOut_RestoreFull_CheckEnd:
	ldada xwa, 0xfc48
	sub xwa, (xsp + 12)
	ld bc, ix
	extz xbc
	cp xbc, xwa
	jr lt, BitMapOut_RestoreFull_FieldLoop
	ldada xde, 0xfc5e
	ld c, (xde)
	and c, 0x7
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xix, (xsp + 20)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	and a, 0xf8
	or c, a
	ld (xde), c
	ldada xbc, 0xfc66
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xde, (xbc + 1)
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	lda xde, (xbc + 2)
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	lda xde, (xbc + 3)
	ld c, (xde)
	and c, 0x2
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	res 1, a
	or c, a
	ld (xde), c
	ldada xbc, 0xfd02
	ld (xsp + 16), xbc
	sub xbc, (xsp + 12)
	ld xwa, (xix)
	add xbc, xwa
	ld xwa, (xsp + 16)
	ld c, (xbc)
	ld (xwa), c
	ldada xbc, 0xfc6e
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xde, (xbc + 1)
	ld c, (xde)
	and c, 0x20
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	res 5, a
	or c, a
	ld (xde), c
	lds bc, 0
	jr BitMapOut_CopyPresetTable_Check

BitMapOut_CopyPresetTable_Loop:
	ld de, bc
	extz xde
	add xde, xhl
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	inc 1, bc

BitMapOut_CopyPresetTable_Check:
	ldada xhl, 0xfc74
	ldada xwa, 0xfca6
	sub xwa, xhl
	ld de, bc
	extz xde
	cp xde, xwa
	jr le, BitMapOut_CopyPresetTable_Loop
	lds bc, 0
	jr BitMapOut_CopyExtTable_Check

BitMapOut_CopyExtTable_Loop:
	ldada xwa, 0xfcc2
	ld de, bc
	extz xde
	add xde, xwa
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	inc 1, bc

BitMapOut_CopyExtTable_Check:
	ldda8 a, 0xfcc1
	extz wa
	cp bc, wa
	jr c, BitMapOut_CopyExtTable_Loop
	lds bc, 0
	jr BitMapOut_CopyAuxTable_Check

BitMapOut_CopyAuxTable_Loop:
	ldada xwa, 0xfcf6
	ld de, bc
	extz xde
	add xde, xwa
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xsp + 24)
	ld xwa, (xwa)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	inc 1, bc

BitMapOut_CopyAuxTable_Check:
	ldda8 a, 0xfcf5
	extz wa
	cp bc, wa
	jr c, BitMapOut_CopyAuxTable_Loop
	ld xhl, (xsp + 16)
	lda xbc, (xhl + 3)
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xix, (xsp + 20)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xbc, (xhl + 1)
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xbc, (xhl + 4)
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	ldada xbc, 0xfd0c
	lda xde, (xbc + 3)
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	lda xde, (xbc + 6)
	ld xhl, xde
	sub xhl, (xsp + 12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	inc 7, xbc
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	ldada xbc, 0xfd2c
	ld xde, xbc
	sub xde, (xsp + 12)
	ld xhl, xix
	ld xwa, (xhl)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	ldada xwa, 0xfb56
	ld (xsp + 20), xwa
	sub xwa, (xsp + 12)
	lda_24 xde, 0x03c8e4
	ld xbc, xwa
	add xbc, xde
	ld xhl, (xsp + 20)
	ld c, (xbc)
	ld (xhl), c
	lda xbc, (xhl + 1)
	ld xwa, xbc
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ldada xbc, 0xfb70
	ld (xsp + 16), xbc
	sub xbc, (xsp + 12)
	add xbc, xde
	ld xwa, (xsp + 16)
	ld c, (xbc)
	ld (xwa), c
	lda xbc, (xwa + 1)
	ld xwa, xbc
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ldada xwa, 0xfb8a
	ld (xsp + 8), xwa
	sub xwa, (xsp + 12)
	add xwa, xde
	ld xbc, (xsp + 8)
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	ld xwa, xbc
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ldada xwa, 0xfba4
	ld (xsp + 4), xwa
	sub xwa, (xsp + 12)
	add xwa, xde
	ld xiy, (xsp + 4)
	ld a, (xwa)
	ld (xiy), a
	lda xbc, (xiy + 1)
	ld xwa, xbc
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	ldada xwa, 0xfbbe
	ld (xsp + 24), xwa
	sub xwa, (xsp + 12)
	add xwa, xde
	ld xix, (xsp + 24)
	ld a, (xwa)
	ld (xix), a
	lda xbc, (xix + 1)
	ld xwa, xbc
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	ld (xbc), a
	inc 4, xhl
	ld c, (xhl)
	and c, 0xb7
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	and a, 0x48
	or c, a
	ld (xhl), c
	ld xwa, (xsp + 16)
	lda xhl, (xwa + 4)
	ld c, (xhl)
	and c, 0xb7
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	and a, 0x48
	or c, a
	ld (xhl), c
	ld xwa, (xsp + 8)
	lda xhl, (xwa + 4)
	ld c, (xhl)
	and c, 0xb7
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	and a, 0x48
	or c, a
	ld (xhl), c
	lda xhl, (xiy + 4)
	ld c, (xhl)
	and c, 0xb7
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	and a, 0x48
	or c, a
	ld (xhl), c
	lda xhl, (xix + 4)
	ld c, (xhl)
	and c, 0xb7
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	and a, 0x48
	or c, a
	ld (xhl), c
	ld xwa, (xsp + 20)
	lda xhl, (xwa + 8)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	res 7, a
	or c, a
	ld (xhl), c
	ld xwa, (xsp + 16)
	lda xhl, (xwa + 8)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	res 7, a
	or c, a
	ld (xhl), c
	ld xwa, (xsp + 8)
	lda xhl, (xwa + 8)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	res 7, a
	or c, a
	ld (xhl), c
	lda xhl, (xiy + 8)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	res 7, a
	or c, a
	ld (xhl), c
	lda xhl, (xix + 8)
	ld c, (xhl)
	and c, 0x80
	ld (xhl), c
	ld xwa, xhl
	sub xwa, (xsp + 12)
	add xwa, xde
	ld a, (xwa)
	res 7, a
	or c, a
	ld (xhl), c
	pop xiz
	lda xsp, (xsp + 24)
	ret

BitMapOut_PartialRestore:
	extz wa
	calr BitMapOut_CopyROMToWorkspace
	push xde
	push xhl
	push xix
	push xiz
	call SeqTimer_UpdateTempoReg
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldada xbc, 0xf9a0
	ldada xix, 0xfc5a
	ld xwa, xix
	sub xwa, xbc
	lda_24 xde, 0x03c8e4
	add xwa, xde
	ld a, (xwa)
	ld (xix), a
	lda xhl, (xix + 1)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	lda xhl, (xix + 7)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	inc 4, xix
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	ldada xix, 0xfd0c
	lda xhl, (xix + 8)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	lda xhl, (xix + 9)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	lda xhl, (xix + 10)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ret

BitMapOut_CopyROMToWorkspace:
	pushw 0x3c0
	extz wa
	sla wa, 2
	lda_24 xbc, WidgetStyleDataTable_0x10
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0x0
	pushw 0xf9a0
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

BitMapOut_SelectiveFieldRestore:
	lda xsp, (xsp - 14)
	push xiz
	ldada xwa, 0xfd96
	ld (xsp + 6), xwa
	inc 7, xwa
	ld (xsp + 14), xwa
	bitm 0, (xwa)
	jrl z, BitMapOut_SelectRestore_CheckBit1
	ldada xde, 0xf9a0
	ldada xbc, 0xfc5a
	ld xwa, xbc
	sub xwa, xde
	lda_24 xhl, 0x03c8e4
	add xwa, xhl
	ld a, (xwa)
	ld (xbc), a
	lda xix, (xbc + 1)
	ld xwa, xix
	sub xwa, xde
	add xwa, xhl
	ld a, (xwa)
	ld (xix), a
	lda xiy, (xbc + 4)
	ld a, (xiy)
	ldfr_berp A, 0xf0
	res_erpb 0xf0, 0x04
	ldto_berp A, 0xf0
	ld (xiy), a
	ld xwa, xiy
	sub xwa, xde
	add xwa, xhl
	ld w, (xwa)
	and w, 0x10
	ldto_berp A, 0xf0
	or a, w
	ldfr_berp A, 0xf0
	ld (xiy), a
	lda xiy, (xbc + 7)
	ld a, (xiy)
	ldfr_berp A, 0xf0
	and_erpb 0xf0, 0xcf
	ldto_berp A, 0xf0
	ld (xiy), a
	ld xwa, xiy
	sub xwa, xde
	add xwa, xhl
	ld w, (xwa)
	and w, 0x30
	ldto_berp A, 0xf0
	or a, w
	ldfr_berp A, 0xf0
	ld (xiy), a
	lda xix, (xbc + 5)
	ld c, (xix)
	res 1, c
	ld (xix), c
	ld xwa, xix
	sub xwa, xde
	add xwa, xhl
	ld a, (xwa)
	and a, 0x2
	or c, a
	ld (xix), c

BitMapOut_SelectRestore_CheckBit1:
	ld xwa, (xsp + 14)
	bitm 1, (xwa)
	jr z, BitMapOut_SelectRestore_CheckBit2
	ldada xhl, 0xf9a0
	ldada xde, 0xfc5a
	lda xbc, (xde + 8)
	ld xwa, xbc
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	lda xbc, (xde + 9)
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a

BitMapOut_SelectRestore_CheckBit2:
	ld xwa, (xsp + 14)
	bitm 2, (xwa)
	jr z, BitMapOut_SelectRestore_CheckBit3
	ldada xde, 0xfd02
	ld c, (xde)
	and c, 0xfc
	ld (xde), c
	ldada xhl, 0xf9a0
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	and a, 0x3
	or c, a
	ld (xde), c
	lda xbc, (xde + 1)
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a

BitMapOut_SelectRestore_CheckBit3:
	ld xwa, (xsp + 14)
	bitm 3, (xwa)
	jr z, BitMapOut_SelectRestore_CheckBit4
	ldada xbc, 0xfd04
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, 0x03c8e4
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_SelectRestore_CheckBit4:
	ld xwa, (xsp + 14)
	bitm 4, (xwa)
	jr z, BitMapOut_SelectRestore_CheckVolBit
	ldada xde, 0xfc5d
	ld c, (xde)
	and c, 0xf0
	ld (xde), c
	ldada xhl, 0xf9a0
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	and a, 0xf
	or c, a
	ld (xde), c
	ldada xde, 0xfc69
	ld c, (xde)
	and c, 0xfc
	ld (xde), c
	ld xwa, xde
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	and a, 0x3
	or c, a
	ld (xde), c

BitMapOut_SelectRestore_CheckVolBit:
	ld xwa, (xsp + 6)
	inc 8, xwa
	ld (xsp + 10), xwa
	bitm 0, (xwa)
	jr z, BitMapOut_SelectRestore_CheckEffBit
	ldada xhl, 0xf9a0
	ldada xwa, 0xfc74
	lda_24 xix, 0x03c8e4
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_SelectRestore_VolCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_SelectRestore_VolCopyLoop

BitMapOut_SelectRestore_CheckEffBit:
	ld xwa, (xsp + 14)
	bitm 7, (xwa)
	jr z, BitMapOut_RestoreVoiceChannels
	ldada xhl, 0xf9a0
	ldada xwa, 0xfc8e
	lda_24 xix, 0x03c8e4
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_SelectRestore_EffCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_SelectRestore_EffCopyLoop

BitMapOut_RestoreVoiceChannels:
	ld xwa, (xsp + 14)
	bitm 5, (xwa)
	jrl z, BitMapOut_RestoreChannels_CheckParts
	ldada xiy, 0xf9b6
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ldada xbc, 0xf9a0
	ld xwa, xix
	sub xwa, xbc
	lda_24 xde, 0x03c8e4
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xf9d0
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xf9ea
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa04
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa1e
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa38
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa52
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa6c
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfa86
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfaa0
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfaba
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfad4
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfaee
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb08
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb22
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb3c
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb56
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb70
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfb8a
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfba4
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfbbe
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfbd8
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	ldada xiy, 0xfc0c
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	and a, 0x7
	or l, a
	ld (xix), l
	lda xhl, (xiy + 13)
	ld xwa, xhl
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xhl), a
	lds hl, 0
	jr BitMapOut_RestoreChannels_CheckEnd

BitMapOut_RestoreChannels_ByteLoop:
	ld ix, hl
	extz xix
	add xix, xiy
	ld xwa, xix
	sub xwa, xbc
	add xwa, xde
	ld a, (xwa)
	ld (xix), a
	inc 1, hl

BitMapOut_RestoreChannels_CheckEnd:
	ldada xiy, 0xfd50
	ldada xwa, 0xfd5e
	sub xwa, xiy
	ld ix, hl
	extz xix
	cp xix, xwa
	jr le, BitMapOut_RestoreChannels_ByteLoop

BitMapOut_RestoreChannels_CheckParts:
	ld xwa, (xsp + 10)
	bitm 1, (xwa)
	jrl z, BitMapOut_RestoreExtra_CheckBit6
	lds de, 0
	ldw (xsp + 4), 0x0

BitMapOut_RestoreParts_OuterLoop:
	lds hl, 0

BitMapOut_RestoreParts_InnerLoop:
	ldada xbc, 0xf9a0
	ld iz, hl
	add iz, de
	ldada xix, 0xfa04
	extz xiz
	add xiz, xix
	ld xwa, xiz
	sub xwa, xbc
	lda_24 xiy, 0x03c8e4
	add xwa, xiy
	ld a, (xwa)
	ld (xiz), a
	inc 1, hl
	cp hl, 0xc
	jr ule, BitMapOut_RestoreParts_InnerLoop
	ld iz, de
	add iz, 0xc
	extz xiz
	add xiz, xix
	ld a, (xiz)
	ldfr_berp A, 0xea
	and_erpb 0xea, 0x07
	ldto_berp A, 0xea
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xiy
	ld w, (xwa)
	and w, 0xf8
	ldto_berp A, 0xea
	or a, w
	ldfr_berp A, 0xea
	ld (xiz), a
	inc 2, hl
	jr BitMapOut_RestoreParts_CheckPartEnd

BitMapOut_RestoreParts_CopyByte:
	ld iz, hl
	add iz, de
	extz xiz
	add xiz, xix
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xiy
	ld a, (xwa)
	ld (xiz), a
	inc 1, hl

BitMapOut_RestoreParts_CheckPartEnd:
	lda xiz, (xix + 14)
	ldada xwa, 0xfa1c
	sub xwa, xiz
	ld iz, hl
	extz xiz
	cp xiz, xwa
	jr le, BitMapOut_RestoreParts_CopyByte
	add de, 0x1a
	incm 1, (xsp + 4)
	cpw (xsp + 4), 0xc
	jrl ule, BitMapOut_RestoreParts_OuterLoop

BitMapOut_RestoreExtra_CheckBit6:
	ld xwa, (xsp + 14)
	bitm 6, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckConfigBit
	ldada xhl, 0xf9a0
	ldada xwa, 0xfd1c
	lda_24 xix, 0x03c8e4
	ld xbc, xwa
	lda xde, (xwa + 14)

BitMapOut_RestoreExtra_AuxLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_AuxLoop

BitMapOut_RestoreExtra_CheckConfigBit:
	ld xwa, (xsp + 10)
	bitm 2, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckDataBit
	ldada xhl, 0xf9a0
	ldada xwa, 0xfd30
	lda_24 xix, 0x03c8e4
	ld xbc, xwa
	lda xde, (xwa + 30)

BitMapOut_RestoreExtra_ConfigLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_ConfigLoop

BitMapOut_RestoreExtra_CheckDataBit:
	ld xwa, (xsp + 10)
	bitm 3, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckMiscBit
	ldada xhl, 0xf9a0
	ldada xde, 0xfc54
	lda xbc, (xde + 1)
	ld xwa, xbc
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	ld xwa, xde
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	ldada xwa, 0xfcdc
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_DataTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_DataTableLoop

BitMapOut_RestoreExtra_CheckMiscBit:
	ld xwa, (xsp + 10)
	bitm 4, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckFlagBits
	ldada xde, 0xf9a0
	ldada xix, 0xfd02
	lda xbc, (xix + 5)
	ld xwa, xbc
	sub xwa, xde
	lda_24 xhl, 0x03c8e4
	add xwa, xhl
	ld a, (xwa)
	ld (xbc), a
	lda xbc, (xix + 6)
	ld xwa, xbc
	sub xwa, xde
	add xwa, xhl
	ld a, (xwa)
	ld (xbc), a
	lda xbc, (xix + 7)
	ld xwa, xbc
	sub xwa, xde
	add xwa, xhl
	ld a, (xwa)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckFlagBits:
	ld xwa, (xsp + 6)
	lda xwa, (xwa + 9)
	ld (xsp + 14), xwa
	bitm 1, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckPanBit
	ldada xbc, 0xfd12
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, 0x03c8e4
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckPanBit:
	ld xwa, (xsp + 10)
	bitm 5, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckCtrlBit
	ldada xbc, 0xfc6a
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, 0x03c8e4
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckCtrlBit:
	ld xwa, (xsp + 10)
	bitm 6, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckLevelBit
	ldada xhl, 0xf9a0
	ldada xwa, 0xfc4a
	lda_24 xix, 0x03c8e4
	ld xbc, xwa
	lda xde, (xwa + 8)

BitMapOut_RestoreExtra_CtrlCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_CtrlCopyLoop

BitMapOut_RestoreExtra_CheckLevelBit:
	ld xwa, (xsp + 10)
	bitm 7, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckExpBit
	ldada xde, 0xfc6f
	ld c, (xde)
	res 6, c
	ld (xde), c
	ldada xhl, 0xf9a0
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	and a, 0x40
	or c, a
	ld (xde), c
	ldada xwa, 0xfcc2
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_LevelTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_LevelTableLoop

BitMapOut_RestoreExtra_CheckExpBit:
	ld xwa, (xsp + 14)
	bitm 0, (xwa)
	jr z, BitMapOut_RestoreExtra_Done
	ldada xde, 0xfc6f
	ld c, (xde)
	res 5, c
	ld (xde), c
	ldada xhl, 0xf9a0
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld a, (xwa)
	and a, 0x20
	or c, a
	ld (xde), c
	ldada xwa, 0xfca8
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_ExpTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	lda_dpi XBC, 0xe4
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_ExpTableLoop

BitMapOut_RestoreExtra_Done:
	pop xiz
	lda xsp, (xsp + 14)
	ret

BitMapOut_SaveDisplayToROM:
	pushw 0x3c0
	pushw 0x0
	pushw 0xf9a0
	pushw 0x3
	pushw 0xc8e4
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

BitMapOut_DetectChanges:
	lda xsp, (xsp - 10)
	pushw iz
	call Voice_InitAllChannelEntries
	calr BitMapOut_GetRenderMode
	bit 0, l
	jr nz, BitMapOut_DetectChanges_CheckMode
	cpdi8 0x8d34, 19
	jr z, BitMapOut_DetectChanges_CheckMode
	ldada xhl, 0xf9a0
	ldada xde, 0xfc5a
	lda xbc, (xde + 5)
	ld xwa, xbc
	sub xwa, xhl
	lda_24 xix, 0x03c8e4
	add xwa, xix
	ld w, (xwa)
	res 1, w
	ld a, (xbc)
	and a, 0x2
	or a, w
	ld (xbc), a
	lda xbc, (xde + 6)
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a

BitMapOut_DetectChanges_CheckMode:
	bitda 5, 0x8e76
	jr nz, BitMapOut_DetectChanges_UseShortList
	calr BitMapOut_GetRenderMode
	bit 0, l
	jr z, BitMapOut_DetectChanges_FullScan

BitMapOut_DetectChanges_UseShortList:
	ldda16 xhl, 0x90de
	ldada xwa, 0xbd3c
	ld (xsp + 8), xwa
	setda 2, 0x8d46
	jr BitMapOut_DeltaEncode_Init

BitMapOut_DetectChanges_FullScan:
	calr BitMapOut_RefreshDisplay_ClearDirty
	calr BitMapOut_CalcDisplayMetrics
	calr BitMapOut_PrepareRenderState
	ldda16 xhl, 0x90e2
	ldada xwa, 0xbf39
	ld (xsp + 8), xwa
	resda 2, 0x8d46

BitMapOut_DeltaEncode_Init:
	lds iz, 0
	jrl BitMapOut_DeltaEncode_CheckBounds

BitMapOut_DeltaEncode_ReadEntry:
	anddi8 0x8d46, 252
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld (xsp + 2), a
	ld (xsp + 6), 0x0
	inc 1, iz
	ld wa, iz
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	ld (xsp + 4), a
	cp (xsp + 4), 0x0
	jrl z, BitMapOut_DeltaEncode_NextEntry

BitMapOut_DeltaEncode_ScanLoop:
	inc 1, iz
	ldada xde, 0xf9a0
	ld ix, iz
	extz xix
	add xix, xde
	ld wa, iz
	extz xwa
	ld xbc, 0x3c8e4
	add xbc, xwa
	ld a, (xbc)
	cp a, (xix)
	jrl z, BitMapOut_DeltaEncode_NextByte
	ld bc, hl
	extz xbc
	add xbc, (xsp + 8)
	ldda8 a, 0x8d46
	bit 2, a
	jr nz, BitMapOut_DeltaEncode_SlowTimeout
	inc 1, xde
	ldada xwa, 0xfba2
	sub xwa, xde
	ld de, iz
	extz xde
	cp xde, xwa
	jr gt, BitMapOut_DeltaEncode_BufferFull
	cp hl, 0xf4
	jr c, BitMapOut_DeltaEncode_EncodeChange

BitMapOut_DeltaEncode_BufferFull:
	ld (xbc), 0xff
	stda16 0x90e2, xhl
	ldada xwa, 0xbd3c
	ld (xsp + 8), xwa
	ldda16 xhl, 0x90de
	ldda8 a, 0x8d46
	set 2, a
	stda8 0x8d46, a
	jr BitMapOut_DeltaEncode_EncodeChange

BitMapOut_DeltaEncode_SlowTimeout:
	cp hl, 0x1f4
	jr c, BitMapOut_DeltaEncode_EncodeChange
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
	lds hl, 0

BitMapOut_DeltaEncode_EncodeChange:
	ld a, (xsp + 2)
	extz wa
	ld c, (xsp + 6)
	extz bc
	cp (xsp + 2), 0x1f
	jr ugt, BitMapOut_DeltaEncode_Type48
	ld xde, (xsp + 8)
	push xde
	pushw hl
	ld de, iz
	calr BitMapOut_DeltaEncode_TypeDefault
	jr BitMapOut_DeltaEncode_NextByte

BitMapOut_DeltaEncode_Type48:
	cp (xsp + 2), 0x48
	jr nz, BitMapOut_DeltaEncode_Type90
	ld xde, (xsp + 8)
	push xde
	pushw hl
	ld de, iz
	calr BitMapOut_DeltaEncode_Type48Handler
	jr BitMapOut_DeltaEncode_NextByte

BitMapOut_DeltaEncode_Type90:
	cp (xsp + 2), 0x90
	jr nz, BitMapOut_DeltaEncode_GenericByte
	ld xde, (xsp + 8)
	push xde
	pushw hl
	ld de, iz
	calr BitMapOut_DeltaEncode_Type90Handler
	jr BitMapOut_DeltaEncode_NextByte

BitMapOut_DeltaEncode_GenericByte:
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, (xsp + 8)
	ld a, (xsp + 2)
	ld (xbc), a
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, (xsp + 8)
	ld a, (xsp + 6)
	ld (xbc), a
	ld de, hl
	inc 1, hl
	extz xde
	add xde, (xsp + 8)
	ldada xwa, 0xf9a0
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld a, (xbc)
	ld (xde), a
	ld wa, iz
	extz xwa
	ld xde, 0x3c8e4
	add xde, xwa
	ld a, (xde)
	xor a, (xbc)
	ld c, a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, (xsp + 8)
	ld (xwa), c

BitMapOut_DeltaEncode_NextByte:
	incm8 1, (xsp + 6)
	decm8 1, (xsp + 4)
	jrl nz, BitMapOut_DeltaEncode_ScanLoop

BitMapOut_DeltaEncode_NextEntry:
	inc 1, iz

BitMapOut_DeltaEncode_CheckBounds:
	ldada xbc, 0xf9a0
	ldada xwa, 0xfd5e
	sub xwa, xbc
	ld de, iz
	extz xde
	cp xde, xwa
	jrl lt, BitMapOut_DeltaEncode_ReadEntry
	ld wa, hl
	extz xwa
	add xwa, (xsp + 8)
	ld (xwa), 0xff
	bitda 2, 0x8d46
	jr nz, BitMapOut_DeltaEncode_StoreShortLen
	stda16 0x90e2, xhl
	jr BitMapOut_DeltaEncode_Return

BitMapOut_DeltaEncode_StoreShortLen:
	stda16 0x90de, xhl

BitMapOut_DeltaEncode_Return:
	popw iz
	lda xsp, (xsp + 10)
	ret

BitMapOut_DispatchIOChanges:
	bitda 7, 0xf9c4
	call_24 z, BitMapOut_ApplyIOChange_Port0
	bitda 7, 0xf9c7
	call_24 z, BitMapOut_ApplyIOChange_Port3
	bitda 7, 0xf9de
	call_24 z, BitMapOut_ApplyIOChange_Port1
	bitda 7, 0xf9e1
	call_24 z, BitMapOut_ApplyIOChange_Port4
	bitda 7, 0xf9f8
	call_24 z, BitMapOut_ApplyIOChange_Port2
	bitda 7, 0xf9fb
	ret nz
	calr BitMapOut_ApplyIOChange_Port5
	ret

BitMapOut_ApplyIOChange_Port0:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 0
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 15
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9c5
	and a, 0xff
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 255
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	stdi8 0x8d4c, 0
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 0
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9c4
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_ApplyIOChange_Port1:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 1
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 15
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9df
	and a, 0xff
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 255
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	stdi8 0x8d4c, 1
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 0
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9de
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_ApplyIOChange_Port2:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 2
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 15
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9f9
	and a, 0xff
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 255
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	stdi8 0x8d4c, 2
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 0
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9f8
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_ApplyIOChange_Port3:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 0
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 3
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9c7
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_ApplyIOChange_Port4:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 1
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 3
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9e1
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_ApplyIOChange_Port5:
	push xde
	push xhl
	push xix
	push xiz
	stdi8 0x8d4c, 2
	ldda8 c, 0x8d4c
	stdi8 0x8d4c, 3
	ldda8 b, 0x8d4c
	ldda8 a, 0xf9fb
	res 7, a
	stda8 0x8d4c, a
	ldda8 e, 0x8d4c
	stdi8 0x8d4c, 127
	ldda8 d, 0x8d4c
	call MIDI_DispatchCC
	pop xiz
	pop xix
	pop xhl
	pop xde
	ret

BitMapOut_DeltaEncode_TypeDefault:
	dec 8, xsp
	push xiz
	ld (xsp + 8), de
	ld (xsp + 10), a
	ld hl, (xsp + 16)
	ld xiy, (xsp + 18)
	ldada xix, 0xf9a0
	ld de, (xsp + 8)
	extz xde
	add xde, xix
	cps c, 0
	jrl z, BitMapOut_DeltaEncode_TypeDefaultC
	ld wa, (xsp + 8)
	extz xwa
	ld xiz, 0x3c8e4
	add xiz, xwa
	cps c, 1
	jr z, BitMapOut_DeltaEncode_TypeDefaultB
	ld wa, hl
	inc 1, hl
	extz xwa
	ld xix, xwa
	add xix, xiy
	ld a, (xsp + 10)
	ld (xix), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), c
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xde)
	ld (xbc), a
	ld c, (xiz)
	xor c, (xde)
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), c
	jrl BitMapOut_DeltaEncode_HelperReturn

BitMapOut_DeltaEncode_TypeDefaultB:
	ld w, (xiz)
	res 7, w
	ld (xsp + 4), xix
	ld xbc, xde
	ld a, (xde)
	res 7, a
	cp a, w
	jrl z, BitMapOut_DeltaEncode_HelperReturn
	bitda 0, 0x8d46
	jrl nz, BitMapOut_DeltaEncode_HelperReturn
	ld de, hl
	inc 1, hl
	extz xde
	add xde, xiy
	ld a, (xsp + 10)
	ld (xde), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x1
	ld de, hl
	inc 1, hl
	extz xde
	add xde, xiy
	ld a, (xbc)
	ld (xde), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x7f
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xsp + 10)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ldw wa, 0xffff
	add wa, (xsp + 8)
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	jr BitMapOut_DeltaEncode_HelperCheckEnd

BitMapOut_DeltaEncode_TypeDefaultC:
	setda 0, 0x8d46
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xsp + 10)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x1
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld wa, (xsp + 8)
	inc 1, wa
	extz xwa
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x7f
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xsp + 10)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xde)
	ld (xbc), a
	ld wa, hl
	inc 1, hl

BitMapOut_DeltaEncode_HelperCheckEnd:
	extz xwa
	add xwa, xiy
	ld (xwa), 0xff

BitMapOut_DeltaEncode_HelperReturn:
	setda 6, 0x8d46
	pop xiz
	inc 8, xsp
	retd 0x6

BitMapOut_DeltaEncode_Type48Handler:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), de
	ld (xsp + 18), a
	ld hl, (xsp + 24)
	ld xde, (xsp + 26)
	ldada xix, 0xf9a0
	ld wa, (xsp + 16)
	extz xwa
	add xwa, xix
	ld (xsp + 12), xwa
	cps c, 0
	jrl z, BitMapOut_DeltaEncode_Type48End
	ld iy, (xsp + 16)
	extz xiy
	ld xwa, 0x3c8e4
	add xwa, xiy
	ld (xsp + 8), xwa
	cps c, 1
	jr z, BitMapOut_DeltaEncode_Type48Loop
	ld wa, hl
	inc 1, hl
	extz xwa
	ld xiy, xwa
	add xiy, xde
	ld a, (xsp + 18)
	ld (xiy), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), c
	ld xiy, xix
	ldada xiz, 0xfc5a
	lda xwa, (xiz + 5)
	sub xwa, xix
	ld bc, (xsp + 16)
	extz xbc
	cp xbc, xwa
	jr z, BitMapOut_DeltaEncode_Type48PartB
	lda xwa, (xiz + 6)
	sub xwa, xiy
	cp xbc, xwa
	jr nz, BitMapOut_DeltaEncode_Type48Scan

BitMapOut_DeltaEncode_Type48PartB:
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x0
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x0
	jrl BitMapOut_DeltaEncode_Type48Return

BitMapOut_DeltaEncode_Type48Scan:
	ld wa, hl
	inc 1, hl
	extz xwa
	ld xix, xwa
	add xix, xde
	ld bc, (xsp + 16)
	extz xbc
	add xbc, xiy
	ld a, (xbc)
	ld (xix), a
	ld xwa, (xsp + 8)
	ld a, (xwa)
	xor a, (xbc)
	ld c, a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), c
	jrl BitMapOut_DeltaEncode_Type48Return

BitMapOut_DeltaEncode_Type48Loop:
	ld xwa, (xsp + 8)
	ld c, (xwa)
	res 7, c
	ld (xsp + 4), xix
	ld xwa, (xsp + 12)
	ld (xsp + 8), xwa
	ld a, (xwa)
	res 7, a
	cp a, c
	jrl z, BitMapOut_DeltaEncode_Type48Return
	bitda 0, 0x8d46
	jrl nz, BitMapOut_DeltaEncode_Type48Return
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp + 18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x1
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld xwa, (xsp + 8)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x7f
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp + 18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ldw wa, 0xffff
	add wa, (xsp + 16)
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	jr BitMapOut_DeltaEncode_Type48Epilog

BitMapOut_DeltaEncode_Type48End:
	setda 0, 0x8d46
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp + 18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x1
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld wa, (xsp + 16)
	inc 1, wa
	extz xwa
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x7f
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp + 18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0x0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld xwa, (xsp + 12)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl

BitMapOut_DeltaEncode_Type48Epilog:
	extz xwa
	add xwa, xde
	ld (xwa), 0xff

BitMapOut_DeltaEncode_Type48Return:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x6

BitMapOut_DeltaEncode_Type90Handler:
	dec 4, xsp
	push xiz
	ld hl, (xsp + 12)
	ld xiy, (xsp + 14)
	ldda8 w, 0x8d46
	ldada xix, 0xf9a0
	ld (xsp + 4), xix
	ld ix, de
	extz xix
	add xix, (xsp + 4)
	cps c, 0
	jrl z, BitMapOut_DeltaEncode_Type90Loop
	cps c, 1
	jr z, BitMapOut_DeltaEncode_Type90PartB
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld (xiz), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), c
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xix)
	ld (xbc), a
	extz xde
	ld xbc, 0x3c8e4
	add xbc, xde
	ld c, (xbc)
	xor c, (xix)
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), c
	jrl BitMapOut_DeltaEncode_Type90Epilog

BitMapOut_DeltaEncode_Type90PartB:
	ld b, w
	bit 1, w
	jrl nz, BitMapOut_DeltaEncode_Type90Epilog
	set 1, b
	stda8 0x8d46, b
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld (xiz), a
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld (xiz), c
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld w, (xix)
	ld (xiz), w
	ld ix, hl
	inc 1, hl
	extz xix
	add xix, xiy
	ld (xix), 0x6
	ld ix, hl
	inc 1, hl
	extz xix
	add xix, xiy
	ld (xix), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	dec 1, c
	ld (xwa), c
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ldw wa, 0xffff
	add wa, de
	extz xwa
	add xwa, (xsp + 4)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x3
	jr BitMapOut_DeltaEncode_Type90Epilog

BitMapOut_DeltaEncode_Type90Loop:
	ld b, w
	bit 1, w
	jr nz, BitMapOut_DeltaEncode_Type90Epilog
	set 1, b
	stda8 0x8d46, b
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld (xiz), a
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld (xiz), c
	ld iz, hl
	inc 1, hl
	extz xiz
	add xiz, xiy
	ld w, (xix)
	ld (xiz), w
	ld ix, hl
	inc 1, hl
	extz xix
	add xix, xiy
	ld (xix), 0x3
	ld ix, hl
	inc 1, hl
	extz xix
	add xix, xiy
	ld (xix), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	inc 1, c
	ld (xwa), c
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	inc 1, de
	extz xde
	add xde, (xsp + 4)
	ld a, (xde)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0x6

BitMapOut_DeltaEncode_Type90Epilog:
	pop xiz
	inc 4, xsp
	retd 0x6

BitMapOut_DeltaEncode_Type90Return:
	dec 6, xsp
	pushw iz
	lds iz, 0

BitMapOut_DeltaEncode_Type90Final:
	lda xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, xde
	sll xbc, 3
	sub xbc, xde
	add xbc, xbc
	ld xde, WidgetStyleDataTable_0x154
	add xde, xbc
	ld xbc, (xde)
	ld c, (xbc)
	and c, 0xff
	ld (xwa + 3), c
	ld xbc, (xde + 4)
	ld c, (xbc)
	res 7, c
	ld (xwa + 4), c
	ld c, (xde + 8)
	ld (xwa + 2), c
	call SndParam_ResolveVoiceEntry
	ld wa, iz
	extz xwa
	ld xbc, xwa
	sll xbc, 3
	sub xbc, xwa
	add xbc, xbc
	lda_24 xhl, WidgetStyleDataTable_0x15E
	add xhl, xbc
	lda xde, (xsp + 2)
	ld a, (xde)
	ldfr_berp A, 0xf0
	extz ix
	ld xbc, (xhl)
	ld a, (xde + 1)
	lda_dri3 XBC, 0x07, 0xe4, 0xf0
	inc 1, iz
	cp iz, 0x17
	jr c, BitMapOut_DeltaEncode_Type90Final
	popw iz
	inc 6, xsp
	ret

BitMapOut_RefreshDisplay_CheckDirty:
	extz	wa
	ld	xbc, 0xf9a0
	.byte 0x78
	jrl	mi, 0x0ee5

BitMapOut_RefreshDisplay_ClearDirty:
	dec 8, xsp
	push xiz
	ldda16 xde, 0x90e2
	ldada xhl, 0xbf39
	ldada xwa, 0xf9a0
	ld (xsp + 8), xwa
	ldada xix, 0xfc66
	ld xbc, xix
	sub xbc, (xsp + 8)
	lda_24 xwa, 0x03c8e4
	ld (xsp + 4), xwa
	ld xiy, xbc
	add xiy, (xsp + 4)
	ld a, (xix)
	lda xbc, (xix + 1)
	cp a, (xiy)
	jr nz, BitMapOut_RefreshDisplay_UpdateRegs
	ld xwa, xbc
	sub xwa, (xsp + 8)
	ld xiz, xwa
	add xiz, (xsp + 4)
	ld a, (xbc)
	cp a, (xiz)
	jr z, BitMapOut_RefreshDisplay_Commit

BitMapOut_RefreshDisplay_UpdateRegs:
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x90
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x0
	ld wa, de
	inc 1, de
	extz xwa
	ld xiz, xwa
	add xiz, xhl
	ld a, (xix)
	ld (xiz), a
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x3
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x90
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x1
	ld wa, de
	inc 1, de
	extz xwa
	ld xiz, xwa
	add xiz, xhl
	ld a, (xbc)
	ld (xiz), a
	ld wa, de
	inc 1, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0x6

BitMapOut_RefreshDisplay_Commit:
	ld wa, de
	extz xwa
	add xwa, xhl
	ld (xwa), 0xff
	stda16 0x90e2, xde
	ld a, (xix)
	ld (xiy), a
	lda xbc, (xix + 1)
	ld xde, xbc
	sub xde, (xsp + 8)
	add xde, (xsp + 4)
	ld a, (xbc)
	ld (xde), a
	pop xiz
	inc 8, xsp
	ret

BitMapOut_CalcDisplayMetrics:
	push xiz
	ldda16 xbc, 0x90e2
	ldw wa, 0x100
	sub wa, bc
	cp wa, 0x8
	jr ule, BitMapOut_CalcMetrics_Done
	ld iy, bc
	ldada xiz, 0xbf39
	ldada xhl, 0xfd05
	ld xwa, xhl
	sub xwa, 0xf9a0
	lda_24 xix, 0x03c8e4
	ld xde, xwa
	add xde, xix
	ld a, (xhl)
	cp a, (xde)
	jr z, BitMapOut_CalcMetrics_ComputeGrid
	inc 1, iy
	extz xbc
	add xbc, xiz
	ld (xbc), 0x70
	ld wa, iy
	inc 1, iy
	extz xwa
	add xwa, xiz
	ld (xwa), 0x3
	ld bc, iy
	inc 1, iy
	extz xbc
	add xbc, xiz
	ld a, (xhl)
	ld (xbc), a
	ld wa, iy
	inc 1, iy
	extz xwa
	add xwa, xiz
	ld (xwa), 0xff

BitMapOut_CalcMetrics_ComputeGrid:
	ld wa, iy
	extz xwa
	add xwa, xiz
	ld (xwa), 0xff
	stda16 0x90e2, xiy
	ld a, (xhl)
	ld (xde), a

BitMapOut_CalcMetrics_Done:
	pop xiz
	ret

BitMapOut_PrepareRenderState:
	push xiz
	ldda16 xbc, 0x90e2
	ldw wa, 0x100
	sub wa, bc
	cp wa, 0x8
	jr ule, BitMapOut_PrepareRender_CheckBit0
	ld iy, bc
	ldada xix, 0xbf39
	ldada xhl, 0xfc5e
	ld xwa, xhl
	sub xwa, 0xf9a0
	lda_24 xiz, 0x03c8e4
	ld xde, xwa
	add xde, xiz
	ld w, (xde)
	and w, 0x40
	ld a, (xhl)
	and a, 0x40
	cp a, w
	jr z, BitMapOut_PrepareRender_SetParams
	inc 1, iy
	extz xbc
	add xbc, xix
	ld (xbc), 0x48
	ld wa, iy
	inc 1, iy
	extz xwa
	add xwa, xix
	ld (xwa), 0x4
	ld bc, iy
	inc 1, iy
	extz xbc
	add xbc, xix
	ld a, (xhl)
	and a, 0x40
	ld (xbc), a
	ld wa, iy
	inc 1, iy
	extz xwa
	add xwa, xix
	ld (xwa), 0x40

BitMapOut_PrepareRender_SetParams:
	ld wa, iy
	extz xwa
	add xwa, xix
	ld (xwa), 0xff
	stda16 0x90e2, xiy
	ld c, (xde)
	res 6, c
	ld (xde), c
	ld a, (xhl)
	and a, 0x40
	or c, a
	ld (xde), c

BitMapOut_PrepareRender_CheckBit0:
	pop xiz
	ret

BitMapOut_PrepareRender_CheckBit1:
	ldda8 l, 0x8d48
	ret

BitMapOut_PrepareRender_CheckBit2:
	stda8 0x8d48, a
	ret

BitMapOut_GetRenderMode:
	ldda8 l, 0x8d4a
	ret

BitMapOut_GetRenderMode_CheckBit3:
	ldada xbc, 0x8d4a
	or (xbc), a
	ld l, (xbc)
	ret

BitMapOut_GetRenderMode_Return:
	ldada xbc, 0x8d4a
	cpl a
	and a, (xbc)
	ld (xbc), a
	ld l, a
	ret

BitMapOut_ByteData_RenderState:
	push	xiz
	.byte 0xc1
	jrl	pl, 16320
	.byte 0x04
	jrl	nz, 179
	ldda8	a, 0xc07e
	andda8	a, 0xc07f
	and	a, 3
	cps	a, 1
	jr	z, 29
	cps	a, 2
	jr	nz, 48
	calr	65468
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	jr	lt, -57
	swi	3
	muls	l, 98
	pop	sr
	.byte 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x89
	extz	wa
	jr	20
	calr	65443
	.byte 0xc7
	swi	3
	cp	(xsp-57), hl
	jr	ge, 105
	.byte 0x04, 0xc7
	swi	3
	pop	sr
	push	199
	swi	3
	.byte 0x89
	extz	wa
	calr	65428
	call	GetTitleNow
	cp	xhl, 0x01a000d0
	jr	nz, 19
	.byte 0xc7
	swi	3
	.byte 0x8d
	exts	de
	exts	xde
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c0000e
	jr	67
	call	GetTitleNow
	cp	xhl, 0x01a000d1
	jr	nz, 59
	pushw	18
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	calr	65366
	ld	(xiz), l
	calr	65361
	ld	a, l
	lda	xbc, (xiz+1)
	calr	285
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20002
	ld	xde, xiz
	call	ApPostEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e00023
	ld	xde, xiz
	call	ApPostEvent
	lds32	xwa, 0
	lds32	xbc, 0
	lds32	xde, 0
	call	MainGetPmemName
	pop	xiz
	ret
BitMapOut_ByteData_DisplayUpdate:
	push xiz
	.byte 0xc1
	jrl	pl, 8640
	cps	a, 1
	jr	nz, 107
	ldda8	a, 0xc07f
	res	7, a
	cps	a, 0
	jr	z, 25
	ld	xwa, 768
	call	SndParam_LookupReadOnly
	cps	l, 0
	jr	z, 12
	dec	1, l
	srl	l, 3
	extz	hl
	ld	wa, hl
	calr	65269
	call	GetTitleNow
	cp	xhl, 0x01a000d1
	jr	nz, 59
	pushw	18
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	calr	65238
	ld	(xiz), l
	calr	65233
	ld	a, l
	lda	xbc, (xiz+1)
	calr	157
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c20002
	ld	xde, xiz
	call	ApPostEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e00023
	ld	xde, xiz
	call	ApPostEvent
	pop	xiz
	ret

BitMapOut_UpdateDisplayWidget:
	push xiz
	ld xiz, xbc
	cps a, 0
	jr nz, BitMapOut_UpdateWidget_CheckType
	pushw 0x10
	pushw 0xeb
	pushw 0x7bc8
	jr BitMapOut_UpdateWidget_TypeA

BitMapOut_UpdateWidget_CheckType:
	dec 1, a
	extz wa
	sla wa, 2
	lda_24 xbc, WidgetStyleDataTable_0x10
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	pushw 0x10
	ldada xwa, 0xf9a2
	sub xwa, 0xf980
	sub xwa, 0x20
	add xwa, xbc
	push xwa

BitMapOut_UpdateWidget_TypeA:
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 16), 0x0
	pop xiz
	ret

BitMapOut_UpdateWidget_TypeB:
	cps a, 0
	ret z
	dec 1, a
	extz wa
	sla wa, 2
	lda_24 xde, WidgetStyleDataTable_0x10
	ld_sril3 XDE, 0x07, 0xe8, 0xe0
	pushw 0x10
	push xbc
	ldada xwa, 0xf9a2
	sub xwa, 0xf980
	sub xwa, 0x20
	add xwa, xde
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

BitMapOut_UpdateWidget_PostDraw:
	push xiz
	ld xiz, xbc
	pushw 0x10
	sll a, 4
	extz wa
	lda_24 xbc, 0x1ed360
	exts xwa
	add xwa, xbc
	push xwa
	push xiz
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld (xiz + 16), 0x0
	pop xiz
	ret

BitMapOut_UpdateWidget_Finalize:
	pushw 0x10
	push xbc
	sll a, 4
	extz wa
	lda_24 xbc, 0x1ed360
	exts xwa
	add xwa, xbc
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ret

BitMapOut_UpdateWidget_Done:
	call	GetTitleNow
	cp	xhl, 0x01a000d0
	jr	z, 89
	call	GetTitleNow
	cp	xhl, 0x01a000d1
	jr	z, 77
	call	GetTitleNow
	cp	xhl, 0x01a000d3
	jr	z, 65
	call	GetTitleNow
	cp	xhl, 0x01a000d2
	jr	z, 53
	.byte 0xc1
	jrl	pl, 16320
	halt
	ret	nz
	ldda8	a, 0xc07e
	andda8	a, 0xc07f
	bit	5, a
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, 0x01c00016
	ld	xde, 0x01a000d0
	call	ApPostEvent
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e0009a
	lds32	xde, 1
	jr	32
	.byte 0xc1
	jrl	pl, 16320
	halt
	ret	nz
	ldda8	a, 0xc07e
	andda8	a, 0xc07f
	bit	5, a
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, 0x01e0009a
	lds32	xde, 0
	call	ApPostEvent
	ret
	ret
	extz	wa
	cps	bc, 0
	.byte 0xf2
	scc16	pl, wa
	swi	4
	.byte 0xd1
	jp	ToneGen_LookupByVoiceIndex
	ret
	dec	2, xsp
	.byte 0xd7
	swi	2
	.byte 0x04
	ld	(xsp+2), a
	cps	bc, 0
	jr	ge, 11
	ld	a, (xsp+2)
	extz	wa
	call	VoiceData_ExtendedParamSetup
	jr	31
	.byte 0xc7
	swi	3
	cp	(xwa-57), xhl
	.byte 0x8b
	extz	bc
	ld	a, (xsp+2)
	extz	wa
	sll	wa, 3
	add	wa, bc
	call	ToneGen_LookupByVoiceIndex
	.byte 0xc7
	swi	3
	jr	lt, -57
	swi	3
	mul	l, 103
	.byte 0xe4, 0xd7
	swi	2
	halt
	inc	2, xsp
	ret

OneTchFUNC:
	cp xbc, 0x1c00013
	jr nz, BitMapOut_ApplyWidgetPatch
	dec 2, xde
	cp xde, 0x0
	jr c, BitMapOut_ApplyWidgetPatch
	cp xde, 0x5
	jr ugt, BitMapOut_ApplyWidgetPatch
	add xde, xde
	add xde, WidgetStyleDataTable_0x362
	ld de, (xde)
	lda_24 xix, BitMapOut_ByteData_WidgetTable
	jp_dri 8, 0x07, 0xf0, 0xe8
BitMapOut_ByteData_WidgetTable:
	resda	7, 0xb7e2
	push	xde
	push	xhl
	push	xix
	push	xiz
	stdi16	0x8d58, 0xffff
	calr	2476
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	0x0051

BitMapOut_ApplyWidgetPatch:
	lds32 xhl, 0
	ret

BitMapOut_ApplyPatch_SkipHeader:
	push xiz
	calr BitMapOut_ApplyPatch_Return
	ldda8 a, 0x8d5c
	cp a, 0x80
	jr c, BitMapOut_ApplyPatch_Execute
	stdi16 0x8d56, 0
	jr BitMapOut_ApplyPatch_Done

BitMapOut_ApplyPatch_Execute:
	lds iz, 0
	ldi_berp 0xfb, 0
	cps a, 0
	jr ule, BitMapOut_ApplyPatch_Store

BitMapOut_ApplyPatch_Loop:
	ldto_berp A, 0xfb
	extz wa
	call AccVoice_GetChannelCount_Wrap
	extz hl
	add iz, hl
	inc 1, iz
	inc1_berp 0xfb
	ldto_berp A, 0xfb
	cpda8 a, 0x8d5c
	jr c, BitMapOut_ApplyPatch_Loop

BitMapOut_ApplyPatch_Store:
	ldda8 a, 0x8d5e
	extz wa
	ld bc, iz
	add bc, wa
	sll bc, 2
	inc 2, bc
	stda16 0x8d56, xbc

BitMapOut_ApplyPatch_Done:
	pop xiz
	ret

BitMapOut_ApplyPatch_Return:
	push_werp 0xfa
	ld xwa, 0x28000
	call SndParam_LookupReadOnly
	ldfr_berp L, 0xfb
	ld xwa, 0x28001
	call SndParam_LookupReadOnly
	ldada xbc, 0x90ea
	ldto_berp A, 0xfb
	ld (xbc), a
	ld (xbc + 1), l
	ld (xbc + 2), 0x48
	push xde
	push xhl
	push xix
	push xiz
	call Rhythm_DispatchNote_Finalize
	pop xiz
	pop xix
	pop xhl
	pop xde
	ldada xwa, 0x90ee
	mrib4 0x80, 0x19, 0x5c, 0x8d
	mrdb5 0x88, 0x01, 0x19, 0x5e, 0x8d
	pop_werp 0xfa
	ret

BitMapOut_ByteData_PatchTable:
	push xiz
	ldada xhl, 0xf9b6
	ldada xix, 0xf9a0
	ld xbc, xhl
	sub xbc, xix
	lda_24 xde, 0x03c2c4
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 1)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 2)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 3)
	ld (xiy), c
	ld c, (xwa + 4)
	and c, 0xcf
	ldfr_berp C, 0xf4
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0x30
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 5)
	ld (xiy), c
	lda xbc, (xhl + 7)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 7)
	ld (xiy), c
	lda xbc, (xhl + 8)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 8)
	ld (xiy), c
	lda xhl, (xhl + 9)
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 9)
	ld (xhl), c
	ldada xhl, 0xf9d0
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 10)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 11)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 12)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 13)
	ld (xiy), c
	ld c, (xwa + 14)
	and c, 0xcf
	ldfr_berp C, 0xf4
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0x30
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 15)
	ld (xiy), c
	lda xbc, (xhl + 7)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 17)
	ld (xiy), c
	lda xbc, (xhl + 8)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 18)
	ld (xiy), c
	lda xhl, (xhl + 9)
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 19)
	ld (xhl), c
	ldada xhl, 0xf9ea
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 20)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 21)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 22)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 23)
	ld (xiy), c
	ld c, (xwa + 24)
	and c, 0xcf
	ldfr_berp C, 0xf4
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0x30
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 25)
	ld (xiy), c
	lda xbc, (xhl + 7)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 27)
	ld (xiy), c
	inc 8, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 28)
	ld (xhl), c
	ldada xhl, 0xfb56
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 34)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 35)
	ld (xhl), c
	ldada xhl, 0xfb70
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 36)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 37)
	ld (xhl), c
	ldada xhl, 0xfb8a
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 38)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 39)
	ld (xhl), c
	ldada xhl, 0xfba4
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 40)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 41)
	ld (xhl), c
	ldada xhl, 0xfbbe
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 42)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 43)
	ld (xhl), c
	ldada xhl, 0xfc26
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 44)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 45)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 46)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 47)
	ld (xiy), c
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 48)
	ld (xiy), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 49)
	ld (xiy), c
	lda xbc, (xhl + 6)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 50)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 51)
	ld (xhl), c
	ldada xhl, 0xfc32
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 52)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 53)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 54)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 55)
	ld (xiy), c
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 56)
	ld (xiy), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 57)
	ld (xiy), c
	lda xbc, (xhl + 6)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 58)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 59)
	ld (xhl), c
	ldada xhl, 0xfc3e
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 60)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 61)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 62)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 63)
	ld (xiy), c
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 64)
	ld (xiy), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 65)
	ld (xiy), c
	lda xbc, (xhl + 6)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 66)
	ld (xiy), c
	inc 7, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 67)
	ld (xhl), c
	ld c, (xwa + 72)
	and c, 0x40
	ldfr_berp C, 0xf4
	ldada xhl, 0xfc5e
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	res 6, c
	ld (xhl), c
	or_berp C, 0xf4
	ld (xhl), c
	ld c, (xwa + 76)
	and c, 0x1f
	ldfr_berp C, 0xf4
	ldada xhl, 0xfc66
	ld xbc, xhl
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0xe0
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	ld c, (xwa + 77)
	and c, 0x1f
	ldfr_berp C, 0xf4
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0xe0
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 78)
	ld (xiy), c
	ld c, (xwa + 79)
	and c, 0x1
	ldfr_berp C, 0xf4
	inc 3, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	res 0, c
	ld (xhl), c
	or_berp C, 0xf4
	ld (xhl), c
	ldada xhl, 0xfc74
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 81)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 82)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 83)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 84)
	ld (xiy), c
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 85)
	ld (xiy), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 86)
	ld (xiy), c
	lda xbc, (xhl + 6)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 87)
	ld (xiy), c
	lda xbc, (xhl + 7)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 88)
	ld (xiy), c
	lda xbc, (xhl + 8)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 89)
	ld (xiy), c
	lda xbc, (xhl + 9)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 90)
	ld (xiy), c
	lda xbc, (xhl + 10)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 91)
	ld (xiy), c
	lda xbc, (xhl + 11)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 92)
	ld (xiy), c
	lda xbc, (xhl + 12)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 93)
	ld (xiy), c
	lda xbc, (xhl + 13)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 94)
	ld (xiy), c
	lda xbc, (xhl + 14)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 95)
	ld (xiy), c
	lda xbc, (xhl + 15)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 96)
	ld (xiy), c
	lda xbc, (xhl + 16)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 97)
	ld (xiy), c
	lda xhl, (xhl + 17)
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 98)
	ld (xhl), c
	ldada xhl, 0xfc8e
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 99)
	ld (xiy), c
	lda xbc, (xhl + 1)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 100)
	ld (xiy), c
	lda xbc, (xhl + 2)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 101)
	ld (xiy), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 102)
	ld (xiy), c
	lda xbc, (xhl + 4)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 103)
	ld (xiy), c
	lda xbc, (xhl + 5)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 104)
	ld (xiy), c
	lda xbc, (xhl + 6)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 105)
	ld (xiy), c
	lda xbc, (xhl + 7)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 106)
	ld (xiy), c
	inc 8, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 107)
	ld (xhl), c
	ld c, (xwa + 80)
	and c, 0xc0
	ldfr_berp C, 0xf4
	ldada xhl, 0xfc6f
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	and c, 0x3f
	ld (xhl), c
	or_berp C, 0xf4
	ld (xhl), c
	ldada xhl, 0xfcc2
	ld xbc, xhl
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 108)
	ld (xiy), c
	inc 1, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xwa + 109)
	ld (xhl), c
	ld c, (xwa + 110)
	and c, 0x4
	ldfr_berp C, 0xf4
	ldada xhl, 0xfd02
	ld xbc, xhl
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	res 2, c
	ld (xiz), c
	or_berp C, 0xf4
	ld (xiz), c
	lda xbc, (xhl + 3)
	sub xbc, xix
	ld xiy, xbc
	add xiy, xde
	ld c, (xwa + 111)
	ld (xiy), c
	ld a, (xwa + 112)
	and a, 0xf
	ldfr_berp A, 0xf4
	lda xbc, (xhl + 4)
	sub xbc, xix
	add xbc, xde
	ld a, (xbc)
	and a, 0xf0
	ld (xbc), a
	or_berp A, 0xf4
	ld (xbc), a
	pop xiz
	ret

