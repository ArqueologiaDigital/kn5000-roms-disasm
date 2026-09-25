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
	lda xbc, (0xfd05:16)
	lda xhl, (0xf9a0:16)
	sub xbc, xhl
	lda xde, (0x03c2c4:24)
	add xbc, xde
	cp (xbc), 0x3
	jr nz, EffectMode_CopyVoiceParams_Done
	lda xix, (0xfa04:16)
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


; =============================================================================
; EffectMode_ByteData_Block1..4 - four routines (CODE, despite the names)
;
; The same four routines as in v9/v10, with every RAM variable 0x9c lower in
; v7 (panel-event bytes 0xbfe1-0xbfe3 here, 0xc07d-0xc07f in v10).
; Block1: sets the word at 0x8cbc to 0xffff -- the value EffectMode_
;   CheckTransposeAndLookup caches there -- and jumps to
;   EffectMode_CheckTransposeChanged, i.e. forces the transpose re-check.
;   No reference to it was found in v10 (label uses, 32-bit pointers).
; Block2, Block3, Block4: panel-event callbacks, listed in
;   UIState_ConfigA_108, _072 and _105 (ui_widgets/widget_dispatch.s).  They
;   test the payload bytes (Block2: 0xbfe1 == 2, Block4: 0xbfe1 == 3, Block3:
;   0xbfe1 == 0 or 7) and react by posting event 0x1e0009a / part- or
;   mode-change events (Block2) or re-reading sound parameters 0x0400/0x0401/
;   0x028002 via AcApcToggleProc_Helper (v7's label for the routine v10
;   calls SndParam_LookupReadOnly) and calling EffectMode_CheckModeAndReinit
;   (Block3, Block4).
; Names kept: widget_dispatch.s (another lane) refers to Block2-4.  Block2 and
; Block4 were verbatim romslices until 2026-09-25.
; =============================================================================
EffectMode_ByteData_Block1:
	ldw	(36028:16), 65535
	jrl	EffectMode_CheckTransposeChanged
EffectMode_ByteData_Block2:
	cp	(0xbfe1:16), 2
	ret	nz
	ld	a, (0xbfe2:16)
	and	a, (0xbfe3:16)
	bit	0, a
	jrl	z, EffectMode_ByteData_Block2_Skip5
	cp	(0x8c98:16), 1
	jr	z, EffectMode_ByteData_Block2_Skip3
	ld	a, (0x8c9a:16)
	cp	a, 192
	jr	z, EffectMode_ByteData_Block2_Skip2
	cp	a, 193
	jr	z, EffectMode_ByteData_Block2_Skip
	cp	a, 194
	jr	z, EffectMode_ByteData_Block2_Skip
	cp	a, 195
	jr	z, EffectMode_ByteData_Block2_Skip
	cp	a, 197
	ret	nz
EffectMode_ByteData_Block2_Skip:
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	jr	EffectMode_ByteData_Block2_Join
EffectMode_ByteData_Block2_Skip2:
	cp	(0x8cb2:16), 0
	ret	nz
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	jp	UI_PostPartChangeEvent
EffectMode_ByteData_Block2_Skip3:
	cp	(0x8cb2:16), 0
	jr	z, EffectMode_ByteData_Block2_Skip4
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
EffectMode_ByteData_Block2_Join:
	call	UI_PostPartChangeEvent
	jr	EffectMode_ByteData_Block2_Join2
EffectMode_ByteData_Block2_Skip4:
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 18
	call	UI_PostPartChangeEvent
	ld	(0x8cb2:16), 0xf
	ret
EffectMode_ByteData_Block2_Skip5:
	cp	(0x8cb2:16), 0
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ldw	wa, 193
	call	UI_PostModeChangeEvent
EffectMode_ByteData_Block2_Join2:
	ld	(0x8cb2:16), 0
	ret
EffectMode_ByteData_Block3:
	ld	a, (0xbfe1:16)
	cp	a, 0:i3
	jr	nz, EffectMode_ByteData_Block3_Skip3
	cp	(0xbfe3:16), 0
	jr	z, EffectMode_ByteData_Block3_Join
	bit	7, (0xbfe2:16)
	jr	nz, EffectMode_ByteData_Block3_Join
	bit	4, (0x8cb6:16)
	jr	nz, EffectMode_ByteData_Block3_Join
	cp	(0x8c9a:16), 0xc0
	jr	nz, EffectMode_ByteData_Block3_Skip
	call	UI_PostTimerResetEvent
	jr	EffectMode_ByteData_Block3_Join
EffectMode_ByteData_Block3_Skip:
	ld	xwa, 1025
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, EffectMode_ByteData_Block3_Skip2
	cp	hl, 2:i3
	jr	nz, EffectMode_ByteData_Block3_Join
EffectMode_ByteData_Block3_Skip2:
	ld	xwa, 1024
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	z, EffectMode_ByteData_Block3_Join
	ld	xwa, 0x028002
	call	AcApcToggleProc_Helper
	ld	(0x8cb8:16), l
	set	7, (0xb746:16)
	set	3, (0x8cb6:16)
	calr	EffectMode_CheckModeAndReinit
	res	3, (0x8cb6:16)
EffectMode_ByteData_Block3_Join:
	res	4, (0x8cb6:16)
	ret
EffectMode_ByteData_Block3_Skip3:
	cp	a, 7:i3
	jr	nz, EffectMode_ByteData_Block3_Skip5
	ld	a, (0x8cb6:16)
	and	a, 0x28
	jr	z, EffectMode_ByteData_Block3_Skip5
	ld	xwa, 1025
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, EffectMode_ByteData_Block3_Skip4
	cp	hl, 2:i3
	jr	nz, EffectMode_ByteData_Block3_Skip5
EffectMode_ByteData_Block3_Skip4:
	ld	xwa, 1024
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	z, EffectMode_ByteData_Block3_Skip5
	ld	xwa, 0x028002
	call	AcApcToggleProc_Helper
	ld	(0x8cb8:16), l
	set	7, (0xb746:16)
	calr	EffectMode_CheckModeAndReinit
EffectMode_ByteData_Block3_Skip5:
	and	(0x8cb6:16), 0xd7
	ret
EffectMode_ByteData_Block4:
	cp	(0xbfe1:16), 3
	jr	nz, EffectMode_ByteData_Block4_Skip2
	ld	a, (0xbfe2:16)
	and	a, 7
	jr	z, EffectMode_ByteData_Block4_Skip2
	ld	a, (0x8cb6:16)
	and	a, 0x28
	jr	z, EffectMode_ByteData_Block4_Skip2
	ld	xwa, 1025
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, EffectMode_ByteData_Block4_Skip
	cp	hl, 2:i3
	jr	nz, EffectMode_ByteData_Block4_Skip2
EffectMode_ByteData_Block4_Skip:
	ld	xwa, 1024
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	z, EffectMode_ByteData_Block4_Skip2
	ld	xwa, 0x028002
	call	AcApcToggleProc_Helper
	ld	(0x8cb8:16), l
	set	7, (0xb746:16)
	calr	EffectMode_CheckModeAndReinit
EffectMode_ByteData_Block4_Skip2:
	and	(0x8cb6:16), 0xd7
	ret
EffectMode_ApplyTranspose:
	calr	EffectMode_ProcessPresetChange
	cp	(0x8c9a:16), 0xc0
	jr	nz, EffectMode_ApplyTranspose_StoreTimer
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e0009a
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	call	UI_PostPartChangeEvent
EffectMode_ApplyTranspose_StoreTimer:
	ld	(36018:16), 0
	jr	EffectMode_CheckTransposeAndLookup
EffectMode_CheckTransposeAndLookup:
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	bit	7, hl
	ret	nz
	calr	SndParam_LoadTransposeValues
	ld	(36028:16), hl
	ret
SndParam_LoadTransposeValues:
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(36942:16), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (36942:16)
	ld	(xwa+1), l
	ld	(xwa+2), 72
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	Rhythm_DispatchNote_Finalize
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	lda	xbc, (36946:16)
	ld	e, (xbc+1)
	extz	de
	ld	a, (xbc)
	extz	wa
	sll	wa, 8
	add	wa, de
	ld	hl, wa
	ret
EffectMode_TimerCountdown:
	ld a, (0x8cb2:16)
	cp a, 0:i3
	ret Z
	dec	1, a
	ld	(36018:16), a
	cp	a, 0:i3
	ret	nz
	cpw	(36026:16), 0
	jr	z, EffectMode_TimerCountdown_CheckMode
	push	xde
	push	xhl
	push	xix
	push	xiz
	calr	EffectMode_ApplyTranspose
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
EffectMode_TimerCountdown_CheckMode:
	ld	a, (35994:16)
	cp	a, 197
	jr	z, EffectMode_TimerCountdown_ResBit7
	cp	a, 194
	jr	z, EffectMode_TimerCountdown_ResBit7
	cp	a, 193
	jr	nz, EffectMode_TimerCountdown_SetBit7
EffectMode_TimerCountdown_ResBit7:
	res	7, (0xb746:16)	; resda 7, 0xb7e2 (v7 patched)

	ret



EffectMode_TimerCountdown_SetBit7:
	set	7, (0xb746:16)	; setda 7, 0xb7e2 (v7 patched)

	ret



EffectMode_CheckTransposeChanged:
	ld XWA,0x00028000
	call AcApcToggleProc_Helper
	bit 0x07,HL
	jr nz, EffectMode_TransposeInvalid
	calr	SndParam_LoadTransposeValues
	cp	hl, (0x8cbc:16)
	ret	z
	ld	(0x8cbc:16), hl
	jrl	BitMapOut_ApplyPatch_SkipHeader
EffectMode_TransposeInvalid:
	ldw	(0x8cbc:16), 0xffff
	ldw	(0x8cba:16), 0
	ret
EffectMode_ProcessPresetChange:
	dec	4, xsp
	push	xiz
	ld	bc, (0x8cba:16)
	ld	wa, bc
	cp	bc, 0:i3
	jr	z, EffectMode_ProcessPresetChange_CheckBit7
	dec	1, wa
	jr	EffectMode_ProcessPresetChange_Apply
EffectMode_ProcessPresetChange_CheckBit7:
	bit	7, (0xb746:16)
	jr	nz, EffectMode_ProcessPresetChange_Done
EffectMode_ProcessPresetChange_Apply:
	calr	EffectMode_ClampAndLookupPreset
	ld	xwa, xhl
	ld	(0x8cc4:16), xwa
	calr	EffectMode_UpdateDisplay
	lda	xwa, (0xfc5a:16)
	ld	(xsp+4), xwa
	sub	xwa, 63904
	lda	xbc, (0x03c2c4:24)
	ld	xiz, xwa
	add	xiz, xbc
	ld	xwa, (xsp+4)
	ld	xbc, xiz
	calr	EffectMode_CopyHoldPedalBits
	ld	xwa, (xsp+4)
	ld	xbc, xiz
	calr	EffectMode_SetRegionAndHold
	ld	xwa, xiz
	calr	EffectMode_Nop
	lda	xwa, (0xf9ef:16)
	sub	xwa, 63904
	lda	xbc, (0x03c2c4:24)
	add	xwa, xbc
	and	(xwa), 0x80
	ld	xwa, (xsp+4)
	ld	xbc, xiz
	calr	EffectMode_CopyPresetBits
	calr	EffectMode_ReinitSoundOutput
EffectMode_ProcessPresetChange_Done:
	res	7, (0xb746:16)	; resda 7, 0xb7e2 (v7 patched)

	pop xiz

	inc 4, xsp

	ret



EffectMode_CopyParamByte:
	lda	xwa, (0xfa07:16)
	lda	xde, (0xf9a0:16)
	sub	xwa, xde
	lda	xbc, (0x3c2c4:24)
	ld	xhl, xwa
	add	xhl, xbc
	lda	xwa, (0xfba7:16)
	sub	xwa, xde
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xhl), a
	ret

EffectMode_ClampAndLookupPreset:
	cp wa, 0x3e8
	jr ule, EffectMode_ClampAndLookup_Clamped
	ld wa, 1:i3

EffectMode_ClampAndLookup_Clamped:
	ld	c, (35996:16)
	cp	c, 194
	jr	z, EffectMode_LookupPreset_BankC2C5
	cp	c, 197
	jr	nz, EffectMode_LookupPreset_Bank7000
EffectMode_LookupPreset_BankC2C5:
	ld xbc, 0x986000	; = table_data STYLEREC_PTRTABLE_C2C5 (UI states 0xc2/0xc5); cross-ROM -- table_data assembles separately, constant stays literal
	jr EffectMode_LookupPreset_Compute

EffectMode_LookupPreset_Bank7000:
	ld xbc, 0x987000	; = table_data STYLEREC_PTRTABLE_DEFAULT (other UI states); cross-ROM -- table_data assembles separately, constant stays literal

EffectMode_LookupPreset_Compute:
	extz xwa
	sll xwa, 2
	add xwa, xbc
	ld xwa, (xwa)
	ld xhl, xwa
	add xhl, (xwa + 4)
	ret

EffectMode_DisplayPresetName:
	pushw	iz
	ld	c, (35996:16)
	cp	c, 192
	jr	z, EffectMode_DisplayName_ValidMode
	cp	c, 194
	jr	z, EffectMode_DisplayName_ValidMode
	cp	c, 197
	jr	nz, EffectMode_DisplayName_Done
EffectMode_DisplayName_ValidMode:
	ld	wa, (36026:16)
	ld	iz, wa
	cp	wa, 0:i3
	jr	z, EffectMode_DisplayName_CheckC2C5
	dec	1, iz
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
	ld xwa, 0x986000	; = table_data STYLEREC_PTRTABLE_C2C5 (UI states 0xc2/0xc5); cross-ROM -- table_data assembles separately, constant stays literal
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
	ld xwa, 0x987000	; = table_data STYLEREC_PTRTABLE_DEFAULT (other UI states); cross-ROM -- table_data assembles separately, constant stays literal

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
	lda	xwa, (63906:16)
	push	xwa
	call	16712982
	lda	xsp, (xsp+10)
	ldw	wa, 128
	call	16472167
EffectMode_DisplayName_Done:
	popw iz
	ret

EffectMode_SearchPresetTableC2C5:
	ld ix, 0:i3
	lda xhl, (WidgetStyleDataTable_0x36E:24)

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
	ld ix, 0:i3
	lda xhl, (WidgetStyleDataTable_0x4FA:24)

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
	cp ix, 5:i3
	jr c, EffectMode_SearchPresetTableC0_Loop
	ld xhl, 0xffffffff
	ret

EffectMode_UpdateDisplay:
	push	xiz
	ld	xiz, xwa
	calr	EffectMode_BackupParamBlock
	ld	a, (36022:16)
	bit	5, a
	jr	z, EffectMode_UpdateDisplay_NoPatch
	res	5, a
	ld	(36022:16), a
	ld	xwa, xiz
	calr	BitMapOut_ByteData_PatchTable
	jr	EffectMode_UpdateDisplay_CopyVoice
EffectMode_UpdateDisplay_NoPatch:
	calr EffectMode_UpdateBitFlags

EffectMode_UpdateDisplay_CopyVoice:
	ld xwa, xiz
	calr EffectMode_CopyVoiceParams
	pop xiz
	ret

EffectMode_UpdateBitFlags:
	lda	xsp, (xsp-48)
	push	xiz
	lda	xwa, (xsp+48)
	ld	(xsp+12), xwa
	lda	xwa, (63930:16)
	lda	xde, (63904:16)
	sub	xwa, xde
	lda	xbc, (246468:24)
	ld	(xsp+32), xwa
	add	(xsp+32), xbc
	ld	xwa, (xsp+32)
	ld	l, (xwa)
	and	l, 32
	ld	xix, (xsp+12)
	ld	(xix), l
	lda	xwa, (xix+1)
	ld	(xsp+24), xwa
	lda	xwa, (63956:16)
	sub	xwa, xde
	ld	(xsp+36), xwa
	add	(xsp+36), xbc
	ld	xwa, (xsp+36)
	ld	l, (xwa)
	and	l, 32
	ld	xwa, (xsp+24)
	ld	(xwa), l
	lda	xwa, (xix+2)
	ld	(xsp+20), xwa
	lda	xwa, (63982:16)
	sub	xwa, xde
	ld	(xsp+40), xwa
	add	(xsp+40), xbc
	ld	xwa, (xsp+40)
	ld	l, (xwa)
	and	l, 32
	ld	xwa, (xsp+20)
	ld	(xwa), l
	lda	xwa, (xix+3)
	ld	(xsp+16), xwa
	lda	xwa, (64008:16)
	sub	xwa, xde
	ld	(xsp+44), xwa
	add	(xsp+44), xbc
	ld	xwa, (xsp+44)
	ld	l, (xwa)
	and	l, 32
	ld	xwa, (xsp+16)
	ld	(xwa), l
	lda	xwa, (64770:16)
	sub	xwa, xde
	ld	(xsp+28), xwa
	add	(xsp+28), xbc
	ld	xwa, (xsp+28)
	ld	a, (xwa)
	and	a, 59
	ld	(xsp+4), a
	lda	xhl, (64623:16)
	sub	xhl, xde
	add	xhl, xbc
	ld	a, (xhl)
	and	a, 32
	ld	(xsp+6), a
	ld	xwa, (36036:16)
	ld	(xsp+8), xwa
	ld	iy, 0:i3
	jr	EffectMode_UpdateBitFlags_Loop
EffectMode_UpdateBitFlags_ProcessEntry:
	ld a, (xix + 4)
	extz wa
	ld xde, (xix)
	exts xwa
	add xwa, xde
	ld xiz, xbc
	add xiz, xwa
	ld w, 0x0:opc
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
	lda	xbc, (63904:16)
	lda	xwa, (64862:16)
	sub	xwa, xbc
	inc	2, xwa
	pushw	wa
	push	xbc
	pushw	3
	pushw	49860
	call	16713148
	lda	xsp, (xsp+10)
	ret
EffectMode_CopyHoldPedalBits:
	ld e, (35996:16)

	cp e, 0xc0

	ret z

	cp e, 0xc2

	ret z

	cp e, 0xc5

	ret z

	bit 2, (1056:16)

	ret z

	ld l, (xwa + 8)

	and l, 0xff

	ld e, (xwa + 9)

	and e, 0x1

	lda xwa, (xbc + 8)

	ld (xwa), 0x0

	lda xbc, (xbc + 9)

	res	0, (xbc)

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
	ld h, 0xa:opc
	cp l, 2:i3
	jr nz, EffectMode_SetRegion_Apply
	ld h, 0x9:opc
EffectMode_SetRegion_Apply:
	lda	xbc, (xiz+3)
	ld	a, (xbc)
	and	a, 248
	ld	(xbc), a
	or	a, h
	ld	(xbc), a
	set	1, (xiz+5)
	lda	xbc, (64770:16)
	ld	h, (xbc)
	and	h, 3
	sub	xbc, 63904
	lda	xde, (246468:24)
	add	xbc, xde
	ld	a, (xbc)
	and	a, 252
	ld	(xbc), a
	or	a, h
	ld	(xbc), a
	ld	a, (35996:16)
	cp	a, 194
	jr	z, EffectMode_CheckPedalType
	cp	a, 197
	jr	nz, EffectMode_PopIzRet
EffectMode_CheckPedalType:
	bit	2, (0x041e:16)
	jr	nz, EffectMode_PopIzRet
	ld	wa, (36026:16)
	bit	0, wa
	jr	z, EffectMode_SendPedalType_Bank1
	ld	xwa, 164097
	call	AcApcToggleProc_Helper
	cp	hl, 2:i3
	jr	z, EffectMode_PopIzRet
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	wa, 0:i3
	call	AccReplay_SendPedalType5
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	jr	EffectMode_PopIzRet
EffectMode_SendPedalType_Bank1:
	ld	xwa, 164097
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, EffectMode_PopIzRet
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	wa, 1:i3
	call	AccReplay_SendPedalType5
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
EffectMode_PopIzRet:
	pop xiz
	ret

EffectMode_Nop:
	ret

EffectMode_CopyPresetBits:
	ld xde, xbc

	bit	7, (0xb746:16)	; bitda 7, (0xb7e2) (v7 patched)

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
	ld	xwa, 770
	call	16567398
	ld	(36020:16), l
	ld	xwa, 770
	ld	bc, 1:i3
	ld	de, 0:i3
	call	16566832
	ldw	wa, 128
	ld	xbc, 246468
	call	16465864
	ldw	wa, 128
	call	16466337
	calr	-979
	res	4, (0x8cb6:16)
	cp	(36020:16), 1
	jr	z, 11
	ld	xwa, 770
	ld	bc, 0:i3
	ld	de, 0:i3
	jr	9
EffectMode_ReinitSound_NotifyBank1:
	ld xwa, 0x302
	ld bc, 1:i3
	ld de, 0:i3

EffectMode_ReinitSound_CallNotify:
	call	16566832
	jp	15668425
EffectMode_ReinitWithFlag:
	set 5, (0x8cb6:16)
	calr EffectMode_CheckModeAndReinit
	res 5, (0x8cb6:16)

	ret



EffectMode_CheckModeAndReinit:
	ld	c, (35994:16)
	cp	c, 120
	jr	z, SndOutput_ReinitByMode
	cp	c, 122
	jr	z, SndOutput_ReinitByMode
	ld	a, (35992:16)
	cp	a, 2:i3
	jr	z, SndOutput_ReinitByMode
	cp	a, 1:i3
	jr	z, SndOutput_ReinitByMode
	cp	c, 133
	jr	z, SndOutput_ReinitByMode
	cp	c, 129
	jr	z, SndOutput_ReinitByMode
	cp	c, 127
	jr	z, SndOutput_ReinitByMode
	cp	c, 96
	jr	z, SndOutput_ReinitByMode
	cp	a, 7:i3
	ret	nz
SndOutput_ReinitByMode:
	ld	xwa, 1025
	call	AcApcToggleProc_Helper
	cp	hl, 3:i3
	jr	z, SndOutput_ReinitByMode_TypeA
	cp	hl, 2:i3
	ret	nz
	jr	SndOutput_ReinitByMode_TypeB
SndOutput_ReinitByMode_TypeA:
	calr SndOutput_ReinitByMode_NotifyParam
	ret

SndOutput_ReinitByMode_TypeB:
	push	xiz
	ld	iz, (36028:16)
	ld	wa, (36026:16)
	ld	qiz, wa
	ldw	(36028:16), 65535
	calr	EffectMode_CheckTransposeChanged
	ld	bc, (36026:16)
	cp	bc, 0:i3
	jr	z, SndOutput_ReinitByMode_Restore
	dec	1, bc
	ld	a, (36024:16)
	extz	wa
	add	bc, wa
	ld	(36026:16), bc
	calr	EffectMode_ProcessPresetChange
	call	SwbtWr_ReinitOutputBank
SndOutput_ReinitByMode_Restore:
	ld	wa, qiz
	ld	(36026:16), wa
	ld	(36028:16), iz
	pop	xiz
	ret
SndOutput_ReinitByMode_NotifyParam:
	ld	c, (36024:16)
	inc	1, c
	extz	bc
	ld	xwa, 768
	ld	de, 3:i3
	call	16566832
	ld	a, (36022:16)
	bit	5, a
	jr	z, 7
	set	2, a
	ld	(36022:16), a
SndOutput_ReinitByMode_CheckBit3:
	ld	a, (36022:16)
	bit	3, a
	ret	z
	set	1, a
	ld	(36022:16), a
	ret
MainCPU_self_test_routines:
	set_dd8 1, 0x30
	bit_dd8 0, 0x30
	ret nz
	ld wa, 0:i3
	calr Test_DRAM_IC10_and_IC9
	extz hl
	ld wa, hl
	calr Test_SRAM_IC21
	extz hl
	ld wa, hl
	calr Report_test_result_by_blinking_LED
	calr A_Short_Pause
	ld wa, 0:i3
	calr Test_PROGRAM_and_TABLE_DATA_ROMs
	extz hl
	ld wa, hl
	calr Report_test_result_by_blinking_LED
	ld wa, 0:i3
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
	ld l, 0x0:opc

Report_BlinkLoop:
	res_dd8 1, 0x30
	ldw bc, 0x4000
	bit 0, a
	jr z, Report_BlinkLoop_ShortFlash
	ldw bc, 0xc000
	jr Report_BlinkLoop_FlashOn

Report_BlinkLoop_ShortFlash:
	cp bc, 0:i3
	jr z, Report_BlinkLoop_FlashOff

Report_BlinkLoop_FlashOn:
	ld e, 0x0:opc

Report_BlinkLoop_FlashDelay:
	inc 1, e
	cp e, 0x20
	jr c, Report_BlinkLoop_FlashDelay
	djnz xbc, Report_BlinkLoop_FlashOn

Report_BlinkLoop_FlashOff:
	set_dd8 1, 0x30
	ldw bc, 0x4000

Report_BlinkLoop_OffDelay:
	ld e, 0x0:opc

Report_BlinkLoop_OffDelayInner:
	inc 1, e
	cp e, 0x20
	jr c, Report_BlinkLoop_OffDelayInner
	djnz xbc, Report_BlinkLoop_OffDelay
	srl a, 1
	inc 1, l
	cp l, 3:i3
	jr ule, Report_BlinkLoop
	ret


A_Short_Pause:
	ld bc, 0:i3

ShortPause_OuterLoop:
	ld wa, 0:i3

ShortPause_InnerLoop:
	inc 1, wa
	cp wa, 0x100
	jr c, ShortPause_InnerLoop
	inc 1, bc
	cp bc, 0x1000
	jr c, ShortPause_OuterLoop
	ret

DramTest_Loop:
	ld wa, 0:i3

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
	lda xbc, (WidgetStyleDataTable_0x6FC:24)
	lda_dri XDE, 0x07, 0xe4, 0xe0
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
	inc	1, (xsp+4)
	cp (xsp + 4), 0x1
	jrl nz, DramTest_IC10IC9_NextChip
	ld l, (xsp + 14)
	extz hl
	pop xiz
	lda xsp, (xsp + 12)
	ret


Test_SRAM_IC21:
	ld l, 0x0:opc

SramTest_IC21_Loop:
	ld c, l
	extz bc
	muls bc, 0xa
	lda xde, (WidgetStyleDataTable_0x706:24)
	lda_dri XDE, 0x07, 0xe8, 0xe4
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
	cp l, 1:i3
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
	ld xix, 0:i3

RomTest_ProgramTableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	lda_dri XIZ, 0x07, 0xe4, 0xf4
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
	set	0, (xsp+20)

RomTest_ProgramROM_Verify:
	ld hl, (xde)
	ld xwa, (xsp + 8)
	cp (xwa), hl
	jr z, RomTest_PrepareTableDataTest
	set	1, (xsp+20)

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
	ld xix, 0:i3

RomTest_TableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	lda_dri XIZ, 0x07, 0xe4, 0xf4
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
	set	2, (xsp+20)

RomTest_TableData_Verify:
	ld xwa, (xsp + 8)
	ld wa, (xwa)
	cp wa, (xde)
	jr z, RomTest_Done
	set	3, (xsp+20)

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
	ld w, 0x0:opc

RhythmRomTest_OuterLoop:
	ld xiy, 0x400000
	ld xiz, 0:i3

RhythmRomTest_SumLoop:
	ld c, w
	extz bc
	add bc, bc
	lda_dri XDE, 0x07, 0xf0, 0xe4
	ld bc, (xde)
	ldw_erp BC, 0xe2
	ld_spiw BC, 0xf5
	addw_erp BC, 0xe2
	ld (xde), bc
	inc 1, xiz
	cp xiz, 0x100000
	jr c, RhythmRomTest_SumLoop
	inc 1, w
	cp w, 2:i3
	jr c, RhythmRomTest_OuterLoop
	ld bc, (xhl)
	cp bc, (xix)
	jr z, RhythmRomTest_Compare
	set 0, a

RhythmRomTest_Compare:
	lda xix, (WidgetStyleDataTable_0x6DA:24)
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
	ld wa, 1:i3
	call Flash_IdentifyAndValidateChip
	cp hl, 0xffff
	jr nz, CustomRomTest_PrepareChecksum
	set	1, (xsp+6)

CustomRomTest_PrepareChecksum:
	lda xhl, (xsp + 2)
	ldw (xhl), 0x0
	lda xde, (xhl + 2)
	ldw (xde), 0x0
	ldib_erp 0xe2, 0

CustomRomTest_OuterLoop:
	ld xix, 0x300000
	ld xiy, 0:i3

CustomRomTest_SumLoop:
	stb_erp A, 0xe2
	extz wa
	add wa, wa
	lda_dri XBC, 0x07, 0xec, 0xe0
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
	set	1, (xsp+6)

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
	ld bc, 0:i3
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cp l, 0:i3
	jr z, LcdTest_WriteOneVerify
	set	2, (xsp)

LcdTest_WriteOneVerify:
	; equivalent to "_VGA_WRITE 3c3h, 1" but with CALL instead of CALR
	ldw wa, 0x3c3
	ld bc, 1:i3
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cp l, 1:i3
	jr z, LcdTest_WriteZeroVerify
	set	2, (xsp)

LcdTest_WriteZeroVerify:
	; equivalent to "_VGA_WRITE 3c3h, 0" but with CALL instead of CALR
	ldw wa, 0x3c3
	ld bc, 0:i3
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cp l, 0:i3
	jr z, LcdTest_Done
	set	2, (xsp)

LcdTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

Test_Video_RAM_IC207:
	dec 2, xsp
	ld (xsp), a
	ld xhl, (WidgetStyleDataTable:24)
	call (xhl)
	ldw (0x1a0000:24), 0x5a5a; VRAM self-test pattern 1
	calr DramTest_Loop
	cpw (0x1a0000:24), 0x5a5a
	jr z, VramTest_Pattern2
	set	3, (xsp)

VramTest_Pattern2:
	ldw (0x1a0004:24), 0xa5a5; VRAM self-test pattern 2
	calr DramTest_Loop
	cpw (0x1a0004:24), 0xa5a5
	jr z, VramTest_Pattern3
	set	3, (xsp)

VramTest_Pattern3:
	ldw (0x1a0008:24), 0x5a5a
	calr DramTest_Loop
	cpw (0x1a0008:24), 0x5a5a
	jr z, VramTest_Done
	set	3, (xsp)

VramTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

SelfTest_FirmwareVersionCheck:
	push	qiz
	call	Get_Firmware_Version
	cp	l, 119
	jr	nz, SelfTest_InterCPU_Send
	ldw	wa, 251
	call	UI_PostModeChangeEvent
	call	SubCPU_PayloadErrorStore
	ld	(36070:16), 2
	jrl	EffectMode_PopRetFA
SelfTest_InterCPU_Send:
	ld	xwa, 61442
	ldw	bc, 8
	ld	xde, 36040
	call	InterCPU_E2_Send
	ld	xwa, 4194303
	jr	SelfTest_WaitBitLoop_Check
SelfTest_WaitBitLoop_Copy:
	ld xiy, 0x620
	ld xix, 0x620
	ldiw
	sub xwa, 0x1
	jr z, SelfTest_WaitDone_CountBits

SelfTest_WaitBitLoop_Check:
	bit 7, (1568:16)
	jr nz, SelfTest_WaitBitLoop_Copy

SelfTest_WaitDone_CountBits:
	ldib_erp 0xfa, 0
	ldib_erp	251, 0	; ld qizh, 0

SelfTest_CountBits_Loop:
	stb_erp	c, 251	; ld c, qizh
	extz	bc
	lda	xwa, (0x8cc8:16)
	extz	xbc
	add	xbc, xwa
	ld	a, (xbc)
	extz	wa
	calr	SelfTest_PopCount
	stb_erp	a, 250	; ld a, qizl
	add	a, l
	ldb_erp	a, 250	; ld qizl, a
	inc1b_erp	251	; inc 1, qizh
	cp_erpb	251, 8
	jr	c, SelfTest_CountBits_Loop
	cpib_erp	250, 2	; cp qizl, 2
	jr	nz, SelfTest_SramAndRom
	lda	xde, (0x8cc8:16)
	ld	c, (xde+3)
	lda	xwa, (xde+4)
	bit	0, c
	jr	z, SelfTest_CheckBit2
	bit	4, (xwa)
	jr	nz, SelfTest_Diagnostic_Skip
SelfTest_CheckBit2:
	bit 2, c
	jr z, SelfTest_CheckBit4
	bit	6, (xwa)
	jr z, SelfTest_CheckBit4
	ldw wa, 0xf5
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit4:
	inc 5, xde
	bit 4, c
	jr z, SelfTest_CheckBit5
	bit	0, (xde)
	jr z, SelfTest_CheckBit5
	ldw wa, 0xf6
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	jrl EffectMode_PopRetFA

SelfTest_CheckBit5:
	bit 5, c
	jr z, SelfTest_CheckBit7
	bit	1, (xde)
	jr z, SelfTest_CheckBit7
	ldw wa, 0xf7
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit7:
	bit 7, c
	jr z, SelfTest_CheckBitA1
	bit	3, (xde)
	jr z, SelfTest_CheckBitA1
	ldw wa, 0xf8
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA1:
	ld a, (xwa)
	bit 1, a
	jr z, SelfTest_CheckBitA3
	bit	5, (xde)
	jr z, SelfTest_CheckBitA3
	ldw wa, 0xf9
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA3:
	bit 3, a
	jrl z, EffectMode_PopRetFA
	bit	7, (xde)
	jrl z, EffectMode_PopRetFA
	ldw wa, 0xfc

EffectMode_UIPostModeChangeEvent:
	call UI_PostModeChangeEvent

SelfTest_Diagnostic_Skip:
	jrl EffectMode_PopRetFA

SelfTest_SramAndRom:
	ldib_erp	250, 0
	ld	wa, 0:i3
	calr	Test_SRAM_IC21
	cp	hl, 0:i3
	jr	z, SelfTest_SramAndRom_CheckROM	; -> 0xFB7063
	ld	xwa, 4294967295
	ld	xbc, 29360150
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263220
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457434
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, 15990785
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ldib_erp	250, 1
SelfTest_SramAndRom_CheckROM:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	CPanel_PanelDetection_Wrapper
	ld	(36064:16), a
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ld	a, (36064:16)
	cpl	a
	and	a, 9
	ld	(36064:16), a
	cp	a, 0:i3
	jr	z, EffectMode_PopRetFA	; -> 0xFB70CA
	cpib_erp	250, 0
	jr	nz, SelfTest_PostRomError	; -> 0xFB70AA
	ld	xwa, 4294967295
	ld	xbc, 29360150
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263220
	call	ApPostEvent
SelfTest_PostRomError:
	ld	xwa, 4294967295
	ld	xbc, 31457434
	ld	xde, 1:i3
	call	ApPostEvent
	ld	xwa, 15990791
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
EffectMode_PopRetFA:
	popw_erp 0xfa
	ret

SelfTest_PopCount:
	ld l, 0x0:opc
	ld c, 0x0:opc

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
	cp (0x8c9a:16), 0xfb
	jr nz, EffectMode_DispatchUpdate
	ld a, (0x8ce6:16)
	cp a, 2:i3
	jr z, EffectMode_ResetDiagMode
	ld a, (0x8ce4:16)
	bit 0x00,A
	jr z, EffectMode_CheckAndDispatch_Bit4Clear
	bit 0x04,A
	jr nz, EffectMode_DispatchUpdate
	set 0x04,A
	ld (0x8ce4:16), a
	ld a, (0x8ce6:16)
	cp a, 1:i3
	jr z, EffectMode_DispatchUpdate
	ld (0x8ce6:16), 0x01
	calr EffectMode_InitSwbWr_DiagMode
	calr EffectMode_SetAllLEDs
	jr t, EffectMode_DispatchUpdate
EffectMode_CheckAndDispatch_Bit4Clear:
	bit	4, a
	jr	z, EffectMode_DispatchUpdate
	res	4, a
	ld	(36068:16), a
	ld	a, (36070:16)
	cp	a, 0:i3
	jr	z, EffectMode_DispatchUpdate
	ld	(36070:16), 0
	calr	EffectMode_RestoreSwbWr_NormalMode
	calr	LED_SetAll_WithBlank
	ld	(58136:16), 16
	jr	EffectMode_DispatchUpdate
EffectMode_ResetDiagMode:
	ld	(36070:16), 0
	calr	LED_SetAll_WithBlank
	calr	EffectMode_RestoreSwbWr_NormalMode
EffectMode_DispatchUpdate:
	cp	(0x8c9a:16), 0xf8
	call_24	z, (EffectMode_HandleTimerEvents)
	cp	(0x8c9a:16), 0xf7
	call_24	z, (EffectMode_ModeChangeTransition)
	cp	(0x8c9a:16), 0xfb
	ret	nz
	calr	EffectMode_RunDiagSequence
	ret
EffectMode_InitSwbWr_DiagMode:
	lda xwa, (0xf9b6:16)

	stib_dsp 0xe0, 0x00

	andmi8 (xwa), 0x80

	lda xbc, (0xfdb6:16)

	andmi8 (xbc), 0xf0

	ld (xbc), 0x6

	ld e, (xwa)

	extz de

	pushw 0x7f

	ld wa, 0:i3

	ld bc, 1:i3

	call	16624211

	pushw 0xff

	ld wa, 0:i3

	ld bc, 0:i3

	ld de, 0:i3

	call	16624211

	pushw 0xf

	ldw wa, 0x93

	ld bc, 0:i3

	ld de, 6:i3

	call	16624211

	ret



EffectMode_RestoreSwbWr_NormalMode:
	lda xwa, (0xf9b6:16)

	stib_dsp 0xe0, 0x40

	andmi8 (xwa), 0x80

	and (0xfdb6:16), 240

	ld e, (xwa)

	extz de

	pushw 0x7f

	ld wa, 0:i3

	ld bc, 1:i3

	call	16624211

	pushw 0xff

	ld wa, 0:i3

	ld bc, 0:i3

	ldw de, 0x40

	call	16624211

	pushw 0xf

	ldw wa, 0x93

	ld bc, 0:i3

	ld de, 0:i3

	call	16624211

	ret



EffectMode_HandleTimerEvents:
	call	CtrlPanel_GetSelectionState
	cp	hl, 0:i3
	ret	nz
	ld	a, (36062:16)
	cp	a, 150
	jrl	z, EffectMode_TimerEvent_Step96
	cp	a, 120
	jrl	z, EffectMode_TimerEvent_Step78
	cp	a, 90
	jr	z, EffectMode_TimerEvent_Step5A
	cp	a, 60
	jr	z, EffectMode_TimerEvent_Step3C
	cp	a, 30
	jr	z, EffectMode_TimerEvent_Step1E
	cp	a, 0:i3
	jrl	nz, EffectMode_TimerEvent_Default
	ld	xwa, 16252940
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (36062:16)
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_TimerEvent_Step1E:
	ld	xwa, 16252942
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (36062:16)
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_TimerEvent_Step3C:
	ld	xwa, 16252944
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (36062:16)
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_TimerEvent_Step5A:
	ld	xwa, 16252934
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (36062:16)
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_TimerEvent_Step78:
	ld	xwa, 16252936
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	a, (36062:16)
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_TimerEvent_Step96:
	ld	xwa, 16252938
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	ld	(36062:16), 220
	ret
EffectMode_TimerEvent_Default:
	inc	1, a
	inc	1, a
	ld	(36062:16), a
	ret
EffectMode_RunDiagSequence:
	ld	a, (36062:16)
	cp	a, 0:i3
	jr	nz, EffectMode_DiagSeq_AnimFrame
	ld	xwa, 16252934
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	calr	A_Short_Pause
	calr	A_Short_Pause
	ld	xwa, 16252936
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	calr	A_Short_Pause
	calr	A_Short_Pause
	ld	xwa, 16252938
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	calr	A_Short_Pause
	calr	A_Short_Pause
	ld	xwa, 16252940
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	calr	A_Short_Pause
	calr	A_Short_Pause
	ld	xwa, 16252942
	ld	xbc, 29360129
	ld	xde, 0:i3
	call	ApPostEvent
	calr	A_Short_Pause
	calr	A_Short_Pause
	inc	1, (36062:16)
	ret
EffectMode_DiagSeq_AnimFrame:
	ld	c, (36060:16)
	cp	c, 0:i3
	jr	nz, EffectMode_DiagSeq_DecrementDelay	; -> 0xFB7385
	extz	wa
	lda	xbc, (15433350:24)
	ld	xde, 0:i3
	ld_rrb	e, xbc, wa
	add	xde, 27262976
	ld	xwa, 4294967295
	ld	xbc, 29360150
	call	ApPostEvent
	ld	a, (36062:16)
	cp	a, 5:i3
	jr	nz, EffectMode_DiagSeq_IncFrame	; -> 0xFB7379
	ld	(36062:16), 1
	jr	EffectMode_DiagSeq_SetDelay	; -> 0xFB737F
EffectMode_DiagSeq_IncFrame:
	inc	1, a
	ld	(36062:16), a
EffectMode_DiagSeq_SetDelay:
	ld	(36060:16), 30
	ret
EffectMode_DiagSeq_DecrementDelay:
	dec	1, c
	ld	(36060:16), c
	ret
EffectMode_ByteData_DiagEvents:
	push QIZ
	push XDE
	push XHL
	push XIX
	push XIZ
	call CPanel_PanelDetection_Wrapper
	ld (0x8ce0:16), a
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	ld a, (0x8ce0:16)
	cpl	a
	ldb_erp	a, 251	; ld qizh, a
	and	a, 9
	extz	wa
	calr	Report_test_result_by_blinking_LED
	stb_erp	a, 251	; ld a, qizh
	and	a, 9
	jr	nz, EffectMode_ByteData_DiagEvents_Skip
	ld	xwa, 0xf5000b
	ld	xbc, 0x1c00001
	ld	xde, 0:i3
	jr	EffectMode_ByteData_DiagEvents_Join
EffectMode_ByteData_DiagEvents_Skip:
	cp	a, 9
	jr	nz, EffectMode_ByteData_DiagEvents_Skip2
	ld	xwa, 0xf5000e
	ld	xbc, 0x1c00001
	ld	xde, 0:i3
	jr	EffectMode_ByteData_DiagEvents_Join
EffectMode_ByteData_DiagEvents_Skip2:
	bit_erpb	251, 0
	jr	z, EffectMode_ByteData_DiagEvents_Skip3
	ld	xwa, 0xf50011
	ld	xbc, 0x1c00001
	ld	xde, 0:i3
	jr	EffectMode_ByteData_DiagEvents_Join
EffectMode_ByteData_DiagEvents_Skip3:
	ld	xwa, 0xf50014
	ld	xbc, 0x1c00001
	ld	xde, 0:i3
EffectMode_ByteData_DiagEvents_Join:
	call	ApPostEvent
	pop	qiz
	ret
TEST3FUNC_Helper:
	ld	a, (0x8c9b:16)
	cp	a, (0x8c9a:16)
	ret	z
	ld	xwa, 16386
	ldw	bc, 128
	ld	de, 3:i3
	call	0xfccb5e
	call	DemoMode_Main_Operation_Helper
	ret
Voice_EmitNoteWithVelocity:
	cp	(0x8c9a:16), 0xf6
	ret	nz
	ld	(0x8ce8:16), a
	ld	(0x8cea:16), c
	ld	xwa, 0xffffffff
	ld	xbc, 0x1e20017
	ld	xde, 0:i3
	call	ApPostEvent
	ret
EffectMode_ModeChangeTransition:
	ld a, (0x8c9b:16)
	cp a, (0x8c9a:16)
	jrl z, EffectMode_MidiParseLoop
	calr EffectMode_SetAllLEDs
	push XDE
	push XHL
	push XIX
	push XIZ
	call CPanel_Poll
	call CPanel_Poll
	pop XIZ
	pop XIX
	pop XHL
	pop XDE
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	calr A_Short_Pause
	jr t, LED_SetAll_WithBlank
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
	lda xbc, (WidgetStyleDataTable_0x6BA:24)
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
	ld bc, 0:i3
	call Set_LEDs
	inc1b_erp 0xfb

LED_SetAll_BlankLoop:
	stb_erp A, 0xfb
	extz wa
	add wa, wa
	lda xbc, (WidgetStyleDataTable_0x6BA:24)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	cp wa, 0xffff
	jr nz, LED_SetAll_BlankOne
	popw_erp 0xfa
	ret


FDC_CommandAndPostEvent:
	lda xsp, (xsp - 0x10)
	lda XWA, (XSP)
	ldw (XWA), 0x0003
	push XWA
	call FDC_CommandEntry
	inc 4,XSP
	ld a, (0x8988:16)
	cp A,0xfc
	jr nz, FDC_PostEvent_Error
	ld XWA,0xffffffff
	ld XBC,0x01c0001e
	ld xde, 2:i3
	jr t, FDC_PostEvent_Send
FDC_PostEvent_Error:
	ld xwa, 0xffffffff
	ld xbc, 0x01c0001e
	ld	xde, 1:i3
FDC_PostEvent_Send:
	call ApPostEvent
	lda	xsp, (xsp+16)
	ret


EffectMode_MidiParseLoop:
	push	xiz
	lda	xiz, (36048:16)
	ld	xwa, xiz
	call	MIDI_ParseThreeByteParams
	cp	hl, 65535
	jr	z, EffectMode_MidiParse_Done
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
	ld xwa, 0:i3
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
	lda xde, (WidgetStyleDataTable_0x55A:24)
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
	ld c, 0x0:opc

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
	lda xix, (TEST2FUNC_DispatchReturn:24)
; Computed jump: target = TEST2FUNC_DispatchReturn + WidgetStyleDataTable_0x710[i], WidgetStyleDataTable_0x710 = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> TEST2FUNC_DispatchReturn
;   1 -> TableDispatch_Return3
;   2 -> TableDispatch_Return3
;   3 -> TableDispatch_Return3
;   4 -> TableDispatch_Return3
;   5 -> TableDispatch_Return3
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST2FUNC event dispatch return (6-entry, event 0x1c00013)
TEST2FUNC_DispatchReturn:
	calr	EffectMode_ByteData_DiagEvents

TableDispatch_Return3:
	ld xhl, 0:i3
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
	lda xix, (TEST3FUNC_DispatchReturn:24)
; Computed jump: target = TEST3FUNC_DispatchReturn + WidgetStyleDataTable_0x71C[i], WidgetStyleDataTable_0x71C = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> TEST3FUNC_DispatchReturn
;   1 -> TableDispatch_Return4
;   2 -> TableDispatch_Return4
;   3 -> TableDispatch_Return4
;   4 -> TableDispatch_Return4
;   5 -> TableDispatch_Return4
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST3FUNC event dispatch return (6-entry, event 0x1c00013)
TEST3FUNC_DispatchReturn:
	calr	TEST3FUNC_Helper

TableDispatch_Return4:
	ld xhl, 0:i3
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
	lda xix, (TEST4FUNC_DispatchReturn:24)
; Computed jump: target = TEST4FUNC_DispatchReturn + WidgetStyleDataTable_0x728[i], WidgetStyleDataTable_0x728 = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> TEST4FUNC_DispatchReturn
;   1 -> TableDispatch_Return5
;   2 -> TableDispatch_Return5
;   3 -> TableDispatch_Return5
;   4 -> TableDispatch_Return5
;   5 -> TableDispatch_Return5
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST4FUNC event dispatch return (6-entry, event 0x1c00013)
TEST4FUNC_DispatchReturn:
	calr	EffectMode_ModeChangeTransition

TableDispatch_Return5:
	ld xhl, 0:i3
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
	lda xix, (TEST6FUNC_DispatchReturn:24)
; Computed jump: target = TEST6FUNC_DispatchReturn + WidgetStyleDataTable_0x734[i], WidgetStyleDataTable_0x734 = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> TEST6FUNC_DispatchReturn
;   1 -> TableDispatch_Return
;   2 -> TableDispatch_Return
;   3 -> TableDispatch_Return
;   4 -> TableDispatch_Return
;   5 -> TableDispatch_Return
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST6FUNC event dispatch return (6-entry, event 0x1c00013)
TEST6FUNC_DispatchReturn:
	calr	FDC_CommandAndPostEvent

TableDispatch_Return:
	ld xhl, 0:i3
	ret

BitmapFinpic_ByteData:
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	ret	z
	ld	a, (49124:16)
	cp	a, (35998:16)
	ret	nz
	cp	(49121:16), 0
	ret	nz
	call	GetTitleNow
	cp	xhl, 27263222
	ret	nz
	ld	xwa, 4294967295
	ld	xbc, 29360139
	ld	xde, 0:i3
	call	ApPostEvent
	ret
BitmapFinpic:
	cp xbc, 0x1e000a3
	jr z, BitmapFinpic_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFinpic_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFinpic_GetDataPtr
	ld xhl, 0:i3
	ret

BitmapFinpic_GetDataPtr:
	lda xhl, (Bitmap_FadeInPicture:24)
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
	ld xhl, 0:i3
	ret

BitmapFinst_GetDataPtr:
	lda xhl, (Bitmap_FadeInText:24)
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
	ld xhl, 0:i3
	ret

BitmapFoutpic_GetDataPtr:
	lda xhl, (Bitmap_FadeOutPicture:24)
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
	ld xhl, 0:i3
	ret

BitmapFoutst_GetDataPtr:
	lda xhl, (Bitmap_FadeOutText:24)
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
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent

SystemInitMD_ReturnZero:
	ld xhl, 0:i3
	ret

SystemInitOkFunc:
	ld xwa, 0x410002
	ld xbc, 0x1e00090
	ld xde, 0:i3
	call SendEvent
	exts xhl
	ld (0x0340de:24), xhl
	cp (0x0340ea:24), 0x00
	jr nz, SystemInitOk_PostEvent
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	ld xde, xhl
	call MainFuncCall
	jr SystemInitOk_ReturnZero

SystemInitOk_PostEvent:
	ld xwa, 0x410007
	ld xbc, 0x1c00001
	ld xde, 0:i3
	call PostEvent

SystemInitOk_ReturnZero:
	ld xhl, 0:i3
	ret

SysIniNoFunc:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00041
	call PostEvent
	ld xhl, 0:i3
	ret

SysIniYesFunc:
	ld xde, (0x0340de:24)
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	call MainFuncCall
	ld xhl, 0:i3
	ret

SysSureShowHideFunc:
	ld xhl, 0:i3
	ret

AttnLngCheck:
	cp xbc, 0x1e0009f
	jr nz, AttnLngCheck_ReturnZero
	lda xhl, (NoteStr3_Blank_3_0x4:24)
	ret

AttnLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SysSureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SysSureLngCheck_ReturnZero
	lda xhl, (Str_Attention_EN_0xC:24)
	ret

SysSureLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret

SureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLngCheck_ReturnZero
	lda xhl, (Str_InitSettingWarn_IT_0x19A:24)
	ret

SureLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret

CtlIniLngCheck:
	cp xbc, 0x1e0009f
	jr nz, CtlIniLngCheck_ReturnZero
	lda xhl, (Str_AreYouSure_IT_0x46:24)
	ret

CtlIniLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret

PmemNormLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemNormLngCheck_ReturnZero
	lda xhl, (Str_FactoryResetDesc_EN3_0x156:24)
	ret

PmemNormLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret

PmemExpLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemExpLngCheck_ReturnZero
	lda xhl, (Str_StoreSoundBalance_DE_0x58:24)
	ret

PmemExpLngCheck_ReturnZero:
	ld xhl, 0:i3
	ret
PmemExpLng_Boundary:

AcMstSugAlpGridBoxProc:
	jp InheritedProc

MstSugAlpGridCheck:
	ld xhl, 0:i3
	ret
; === v7-specific block: AcMstStyleAlp_Boundary (497 bytes) ===
AcMstStyleAlp_Boundary:
	lda	xsp, (xsp-74)
	push	xiz
	ld	(xsp+66), xde
	ld	(xsp+70), xbc
	ld	(xsp+74), xwa
	ld	xbc, (xsp+70)
	cp	xbc, 0x1e0008d
	jrl	z, MasterSetup_ForwardToChild
	ld	xwa, (xsp+70)
	cp	xwa, 0x1e0008b
	jrl	z, MasterSetup_GetNameB_DrawString
	cp	xwa, 0x1e0008a
	jrl	z, MasterSetup_GetNameA
	cp	xwa, 0x1c00007
	jrl	z, AcMstStyleAlp_Boundary_Skip3
	cp	xwa, 0x1c00002
	jrl	z, AcMstStyleAlp_Boundary_Skip2
	cp	xwa, 0x1c00001
	jr	z, AcMstStyleAlp_Boundary_Skip
	sub	xbc, 0x1c00017
	cp	xbc, 0
	jrl	lt, MasterSetup_InheritedProc_Fallback
	cp	xbc, 6
	jrl	gt, MasterSetup_InheritedProc_Fallback
	add	xbc, xbc
	add	xbc, Str_StoreTotalSetting_DE_0x98
	ld	bc, (xbc)
	lda	xix, (0xfb78db:24)
	jp_rr	8, xix, bc	; jp t, xix+bc
AcMstStyleAlp_Boundary_Skip:
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	InheritedProc
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	xwa, (xsp+74)
	ld	xbc, 0x1e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, xiz
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+74)
	ld	xbc, 0x1c00018
	call	SetDialUp
	ld	xwa, (xsp+8)
	ld	bc, (xwa+26)
	ld	xwa, xiz
	srl	xwa, 0
	ld	qwa, 0
	add	wa, bc
	ld	de, wa
	extz	xde
	ld	xwa, (xsp+74)
	ld	xbc, 0x1c00017
	call	SetDialDown
	ld	wa, 1:i3
	call	SetDialEnable
	ld	de, iz
	ld	(xsp+60), de
	ld	xwa, (xsp+8)
	ld	xbc, (xwa+78)
	ld	xwa, (xwa+90)
	ld	wa, (xwa)
	muls	wa, 9
	sub	wa, 9
	add	wa, (xbc)
	add	de, wa
	muls	de, 6
	lda	xbc, (StyleSong_MasterTable_0x4:24)
	ld_rrw	de, xbc, de	; ld de, (xbc+de)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	jr	AcMstStyleAlp_Boundary_Join
AcMstStyleAlp_Boundary_Skip2:
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	InheritedProc
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20019
	ld	xde, 0:i3
AcMstStyleAlp_Boundary_Join:
	call	MainFuncCall
	jrl	SeqFile_ReturnZeroJmp2
AcMstStyleAlp_Boundary_Skip3:
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	InheritedProc
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	lda	xbc, (xwa+78)
	ld	xwa, (xsp+66)
	cp	xwa, 128
	jrl	z, MasterSetup_DialTurn_ScrollUp
	or	xwa, xwa
	jrl	nz, SeqFile_ReturnZeroJmp2
	ld	xbc, (xbc)
	cpw	(xbc), 0
	jr	z, AcMstStyleAlp_Boundary_Skip4
	ld	wa, (xbc)
	dec	1, wa
	ld	(xbc), wa
	muls	wa, 6
	lda	xbc, (StyleSong_MasterTable:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	AcMstStyleAlp_Boundary_Join2
AcMstStyleAlp_Boundary_Skip4:
	ld	xwa, (StyleSong_MasterTable_0x176A:24)
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+78)
	ldw	(xwa), 999
AcMstStyleAlp_Boundary_Join2:
	ld	xde, (xsp+8)
	ld	xbc, (xde+74)
	ld	a, (xsp+12)
	extz	wa
	ld	(xbc), wa
	ld	xwa, (xde+78)
	ld	iz, (xwa)
	cp	iz, 0:i3
	jr	z, MasterSetup_StringSearch_Done
	pushw	1
	ld	wa, iz
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	ld	xwa, StyleSong_MasterTable
	add	xwa, xbc
	ld	xwa, (xwa)
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	SLIDE_Parse_Header_Helper
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, MasterSetup_StringSearch_Done
	djnz16	iz, -46
; === end v7 block ===
MasterSetup_StringSearch_Done:
	cp iz, 0:i3
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
	ld xde, 0:i3
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
	ld	xix, xbc
	ld	xde, (xbc)
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+82)
	ld	bc, (xwa)
	add	bc, (xde)
	inc	1, bc
	ld	hl, bc
	lda	xbc, (xsp+12)
	cp	hl, 1000
	jr	nc, MasterSetup_ScrollUp_Overflow
	ld	hl, (xde)
	ld	wa, (xwa)
	add	wa, hl
	inc	1, wa
	ld	(xde), wa
	ld	xwa, (xix)
	ld	wa, (xwa)
	muls	wa, 6
	lda	xde, (15443092:24)
	ld_rrl	xwa, xde, wa
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	MasterSetup_ScrollUp_UpdateView
MasterSetup_ScrollUp_Overflow:
	ld	xwa, (15443092:24)
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+78)
	ldw	(xwa), 0
MasterSetup_ScrollUp_UpdateView:
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	ld iz, 0:i3
	jr MasterSetup_ScrollUp_Search_Check

MasterSetup_ScrollUp_Search_Loop:
	pushw	1
	add	wa, iz
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	ld	xwa, 15443092
	add	xwa, xbc
	ld	xwa, (xwa)
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	SLIDE_Parse_Header_Helper
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, MasterSetup_ScrollUp_Search_Done
	inc	1, iz
MasterSetup_ScrollUp_Search_Check:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3e8
	sub bc, wa
	cp iz, bc
	jr c, MasterSetup_ScrollUp_Search_Loop
MasterSetup_ScrollUp_Search_Done:
	ld	xhl, (xsp+8)
	lda	xbc, (xhl+82)
	ld	xwa, (xbc)
	ld	de, iz
	dec	1, de
	ld	(xwa), de
	ld	xde, (xhl+86)
	ld	xwa, (xbc)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 9
	inc	1, wa
	ld	(xde), wa
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+90)
	ldw	(xwa), 1
	ld	xwa, (xsp+74)
	ld	xbc, 29360143
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, (xsp+74)
	ld	xbc, 31457422
	ld	xde, 4294901760
	call	SendEvent
	ld	xwa, (xsp+8)
	ld	xwa, (xwa+70)
	ld	xbc, 29360152
	ld	xde, (xsp+66)
	jrl	SeqFile_CallApFunc
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	InheritedProc
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	xwa, (xsp+74)
	ld	xbc, 31457360
	ld	xde, (xsp+66)
	call	SendEvent
	or	xhl, xhl
	jrl	z, MasterSetup_FallbackEvent
	ld	xwa, (xsp+74)
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	cp	hl, 0:i3
	jrl	nz, MasterSetup_DialDown_SendPageEvent
	ld	xbc, (xsp+8)
	ld	xwa, (xbc+90)
	cpw	(xwa), 1
	jrl	nz, MasterSetup_DialDown_DecPage
	ld	xbc, (xbc+78)
	lda	xde, (xsp+12)
	lda	xhl, (15443092:24)
	cpw	(xbc), 0
	jr	z, MasterSetup_DialDown_Underflow
	ld	wa, (xbc)
	dec	1, wa
	ld	(xbc), wa
	muls	wa, 6
	ld_rrl	xwa, xhl, wa
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	jr	MasterSetup_DialDown_UpdateView
MasterSetup_DialDown_Underflow:
	ld XWA, (xhl + 0x176a)

	push xwa

	push xde

	call	Free_Compare2

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
	cp iz, 0:i3
	jr z, MasterSetup_DialDown_Search_Done

MasterSetup_DialDown_Search_Loop:
	pushw	1
	ld	wa, iz
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	ld	xwa, 15443092
	add	xwa, xbc
	ld	xwa, (xwa)
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	SLIDE_Parse_Header_Helper
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, MasterSetup_DialDown_Search_Done
	djnz16	iz, -46
MasterSetup_DialDown_Search_Done:
	cp iz, 0:i3
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
	ld xde, 0:i3
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
	decw	1, (xwa)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld	xwa, (xsp+74)
	ld	xbc, 31457425
	ld	xde, (xsp+66)
	call	SendEvent
	or	xhl, xhl
	jrl	z, SeqFile_ReturnZeroJmp2
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	ApFuncCall
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	SetAutoInc
	ld	xwa, (xsp+74)
	ld	xbc, 29360152
	ld	xde, (xsp+66)
	call	SetDialUp
	ld	xwa, (xsp+74)
	ld	xbc, 29360151
	ld	xde, (xsp+66)
	call	SetDialDown
	ld	wa, 1:i3
	jrl	MasterSetup_SetDialEnable
	ld	xwa, (xsp+74)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	call	InheritedProc
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	(xsp+8), xhl
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	xwa, (xsp+74)
	ld	xbc, 31457360
	ld	xde, (xsp+66)
	call	SendEvent
	or	xhl, xhl
	jrl	z, MstStyleAlp_FallbackDispatch
	ld	xwa, (xsp+74)
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xix, (xsp+8)
	ld	xde, (xix+82)
	ld	xbc, (xix+90)
	ld	wa, (xbc)
	muls	wa, 9
	dec	1, wa
	cp	wa, (xde)
	jrl	lt, MstStyleAlp_PageForward
	ld	wa, (xde)
	exts	xwa
	divs	wa, 9
	ld	wa, qwa
	cp	wa, hl
	jrl	nz, MstStyleAlp_SelectAndAutoInc
	lda	xix, (xix+78)
	ld	xwa, (xix)
	ld	bc, (xde)
	add	bc, (xwa)
	inc	1, bc
	ld	hl, bc
	lda	xbc, (15443092:24)
	cp	hl, 1000
	jr	nc, MstStyleAlp_OverflowCopy
	ld	hl, (xwa)
	ld	de, (xde)
	add	de, hl
	inc	1, de
	ld	(xwa), de
	ld	xwa, (xix)
	ld	wa, (xwa)
	muls	wa, 6
	ld_rrl	xwa, xbc, wa
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	MstStyleAlp_UpdateFocusIndex
MstStyleAlp_OverflowCopy:
	ld xwa, (xbc)

	push xwa

	lda xwa, (xsp + 16)

	push xwa

	call	Free_Compare2

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
	ld iz, 0:i3
	jr MstStyleAlp_CompareLoopCond

MstStyleAlp_CompareEntry:
	pushw	1
	add	wa, iz
	extz	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	ld	xwa, 15443092
	add	xwa, xbc
	ld	xwa, (xwa)
	push	xwa
	lda	xwa, (xsp+18)
	push	xwa
	call	SLIDE_Parse_Header_Helper
	add	xsp, 10
	cp	hl, 0:i3
	jr	nz, MstStyleAlp_CompareComplete
	inc	1, iz
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
	ld xde, 0:i3
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
	incw 1, (xbc)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld wa, 1:i3

MasterSetup_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_GetNameA:
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	xwa, (xhl+62)
	push	xwa
	ld	xwa, (xsp+70)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	SeqFile_ReturnZeroJmp2
MasterSetup_GetNameB_DrawString:
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, (xiz+66)
	push	xwa
	ld	xwa, (xsp+70)
	push	xwa
	call	Free_Compare2
	lda	xhl, (xsp+54)
	ldw	(xhl), 14
	lda	xbc, (xhl+2)
	ldw	(xbc), 46
	lda	xde, (xsp+58)
	ld	wa, (xhl)
	ld	(xde), wa
	ld	wa, (xhl)
	add	wa, 80
	ld	(xde+4), wa
	ld	wa, (xbc)
	ld	(xde+2), wa
	ld	wa, (xbc)
	add	wa, 19
	ld	(xde+6), wa
	ld	xwa, (xiz+86)
	pushw	(xwa)
	ld	xwa, (xiz+90)
	pushw	(xwa)
	ld	xwa, (xiz+74)
	pushw	(xwa)
	pushw	237
	pushw	3352
	lda	xwa, (xsp+30)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+22)
	lda	xwa, (xsp+50)
	lda	xbc, (xsp+46)
	lda	xde, (xsp+12)
	ld	xhl, 1:i3
	push	xhl
	pushw 251
	pushw 245
	call	DrawString
	jr	SeqFile_ReturnZeroJmp2
	ld	xwa, (xsp+74)
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+70)
	ld	xde, (xsp+66)
	jr	SeqFile_CallApFunc
MasterSetup_ForwardToChild:
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)

SeqFile_CallApFunc:
	call ApFuncCall

SeqFile_ReturnZeroJmp2:
	ld xhl, 0:i3
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
	lda xix, (MstStyleAlp_EventDispatch:24)
; Computed jump: target = MstStyleAlp_EventDispatch + Str_StoreTotalSetting_DE_0xCC[i], Str_StoreTotalSetting_DE_0xCC = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> MstStyleAlp_EventDispatch
;   0x1c00018 -> MstStyleAlp_EventDispatch
;   0x1c00019 -> MstStyleAlp_EventDispatch
;   0x1c0001a -> MstStyleAlp_EventDispatch
;   0x1c0001b -> EffectMode_SendEvent_Return
;   0x1c0001c -> EffectMode_SendEvent_Return
;   0x1c0001d -> EffectMode_SendEvent_Return
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyleAlpGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d58)
MstStyleAlp_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	ld	xde, 0:i3
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
	lda	xbc, (StyleSong_MasterTable_0x4:24)
	ld_rrw	de, xbc, de
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	call	MainFuncCall
	jrl	EffectMode_SendEvent_Return

MstStyleAlp_CellSelect:
	call GetFocusObject
	ld XWA,XHL
	call GetViewInstance
	ld (XSP+0x04),XHL
	lda xde, (xsp + 0x32)
	ld XWA,(XSP+0x3a)
	srl XWA, 0x00
	ld QWA,0
	ld (XDE),WA
	lda xbc, (xde + 0x02)
	ld XWA,(XSP+0x3a)
	ld (XBC),WA
	lda xwa, (xsp + 0x10)
	ld (XSP+0x0c),XWA
	ld (XDE+0x04),XWA
	ld XWA,(XSP+0x04)
	lda xix, (xwa + 0x5a)
	ld XHL,(XIX)
	lda xde, (xwa + 0x56)
	ld XIY,(XDE)
	lda xwa, (StyleSong_MasterTable:24)
	ld (XSP+0x08),XWA
	ld XIX,(XIX)
	ld XWA,(XSP+0x04)
	ld XIZ,(XWA+0x4e)
	ld WA,(XIX)
	muls WA,0x0009
	sub WA,0x0009
	ld IX,WA
	add IX,(XIZ)
	ld WA,(XIY)
	cp WA,(XHL)
	jrl nz, MstStyleAlp_CopyEntryAndPad
	ld XWA,(XSP+0x04)
	ld XHL,(XWA+0x52)
	ld XWA,(XDE)
	ld WA,(XWA)
	muls WA,0x0009
	sub WA,0x000a
	ld DE,(XHL)
	sub DE,WA
	ld WA,(XBC)
	cp WA,DE
	jr ge, MstStyleAlp_OverflowStr
	add WA,IX
	muls WA,0x0006
	ld BC,WA
	ld XWA,(XSP+0x08)
	ldl_dri xwa, 0x07, 0xe0, 0xe4
	push XWA
	ld XWA,(XSP+0x10)
	push XWA
	call Free_Compare2
	inc 0,XSP
	ld (XSP+0x0e),0x00
	jr t, MstStyleAlp_PadLoopCond
MstStyleAlp_AppendPadChar:
	pushw	1
	pushw	237
	pushw	3378
	lda	xwa, (xsp+22)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+14)
MstStyleAlp_PadLoopCond:
	ld	xwa, (xsp+4)
	ld	xbc, (xwa+78)
	ld	xwa, (xwa+90)
	ld	wa, (xwa)
	muls	wa, 9
	sub	wa, 9
	add	wa, (xbc)
	ld	bc, (xsp+52)
	add	bc, wa
	muls	bc, 6
	ld	wa, bc
	lda	xbc, (StyleSong_MasterTable:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+14)
	extz	wa
	cp	wa, bc
	jr	c, MstStyleAlp_AppendPadChar
	jrl	MstStyleAlp_FinalSendEvent
MstStyleAlp_OverflowStr:
	pushw	237
	pushw	3380
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	MstStyleAlp_FinalSendEvent
MstStyleAlp_CopyEntryAndPad:
	ld WA,(XBC)
	add WA,IX
	muls WA,0x0006
	ld BC,WA
	ld XWA,(XSP+0x08)
	ldl_dri xwa, 0x07, 0xe0, 0xe4
	push XWA
	ld XWA,(XSP+0x10)
	push XWA
	call Free_Compare2
	inc 0,XSP
	ld (XSP+0x0e),0x00
	jr t, MstStyleAlp_PadLoopCond2
MstStyleAlp_AppendPadChar2:
	pushw	1
	pushw	237
	pushw	3414
	lda	xwa, (xsp+22)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+14)
MstStyleAlp_PadLoopCond2:
	ld	xwa, (xsp+4)
	ld	xbc, (xwa+78)
	ld	xwa, (xwa+90)
	ld	wa, (xwa)
	muls	wa, 9
	sub	wa, 9
	add	wa, (xbc)
	ld	bc, (xsp+52)
	add	bc, wa
	muls	bc, 6
	ld	wa, bc
	lda	xbc, (StyleSong_MasterTable:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+14)
	extz	wa
	cp	wa, bc
	jr	c, MstStyleAlp_AppendPadChar2
MstStyleAlp_FinalSendEvent:
	ld wa, (xsp + 50)
	cp wa, 1:i3
	jr nz, EffectMode_SendEvent_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 50)
	ld xbc, 0x1e0008c
	call SendEvent

EffectMode_SendEvent_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 58)
	ret

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
	lda xix, (MstStyle_EventDispatch:24)
; Computed jump: target = MstStyle_EventDispatch + Str_StoreTotalSetting_DE_0xDA[i], Str_StoreTotalSetting_DE_0xDA = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcMstStyle1GridBoxProc_Evt1C00017
;   0x1c00018 -> AcMstStyle1GridBoxProc_Evt1C00018
;   0x1c00019 -> AcMstStyle1GridBoxProc_Evt1C00017
;   0x1c0001a -> AcMstStyle1GridBoxProc_Evt1C00018
;   0x1c0001b -> MstStyle_InheritedProc_Fallback
;   0x1c0001c -> MstStyle_ForwardToChild
;   0x1c0001d -> MstStyle_ForwardToChild
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
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xiz + 78)
	ldw (xwa), 0x1
	ld xwa, (xiz + 74)
	ldw (xwa), 0xa
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	ld iy, hl
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, iy
	ld (0x0340c4:24), wa
	jrl SeqFileAlt_ReturnZeroJmp
AcMstStyle1GridBoxProc_Evt1C00017:
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
	ld xde, 0:i3
	call SendEvent
	ld iy, hl
	cp iy, 0:i3
	jr nz, MstStyle_DialDown_Decrement
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 82)
	ld xwa, (xbc)
	cpw (xwa), 0x1
	jrl le, SeqFileAlt_ReturnZeroJmp
	decw	1, (xwa)
	ld xwa, (xbc)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld (0x0340c4:24), wa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld xde, 0:i3
	jr MstStyle_DialDown_PostEvent

MstStyle_DialDown_Decrement:
	decw 1, (0x340c4:24)
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
	ld xde, 0:i3

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
AcMstStyle1GridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
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
	incw 1, (xde)
	ld xwa, (xhl)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld (0x0340c4:24), wa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld xde, 0:i3
	jrl MstStyle_DialUp_PostEvent

MstStyle_DialUp_Increment:
	incw 1, (0x340c4:24)
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
	ld xde, 0:i3
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
	incw 1, (0x340c4:24)
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
	ld xde, 0:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	SeqFileAlt_ReturnZeroJmp
MstStyle_ForwardToChild:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall

SeqFileAlt_ReturnZeroJmp:
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1Grid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1Grid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0xFE
	ld wa, (xwa)
	lda xix, (MstStyle1Grid_EventDispatch:24)
; Computed jump: target = MstStyle1Grid_EventDispatch + Str_StoreTotalSetting_DE_0xFE[i], Str_StoreTotalSetting_DE_0xFE = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> MstStyle1Grid_EventDispatch
;   0x1c00018 -> MstStyle1Grid_EventDispatch
;   0x1c00019 -> MstStyle1Grid_EventDispatch
;   0x1c0001a -> MstStyle1Grid_EventDispatch
;   0x1c0001b -> MstStyle1Grid_Epilogue
;   0x1c0001c -> MstStyle1Grid_EventDispatch
;   0x1c0001d -> MstStyle1Grid_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1GridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d8a)
MstStyle1Grid_EventDispatch:
	jrl	t, MstStyle1Grid_Epilogue
MstStyle1Grid_CellSelect:
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	(xsp+4), xhl
	lda	xhl, (xsp+30)
	ld	xwa, (xsp+38)
	srl	xwa, 0
	ld	qwa, 0
	ld	(xhl), wa
	lda	xde, (xhl+2)
	ld	xwa, (xsp+38)
	ld	(xde), wa
	lda	xbc, (xsp+12)
	ld	(xhl+4), xbc
	ld	xwa, (xsp+4)
	lda	xix, (xwa+82)
	ld	xiy, (xix)
	lda	xhl, (xwa+78)
	ld	xiz, (xhl)
	lda	xwa, (15531172:24)
	ld	(xsp+8), xwa
	ld	xwa, (xix)
	ld	ix, (xwa)
	muls	ix, 10
	sub	ix, 10
	ld	wa, (xiz)
	cp	wa, (xiy)
	jrl	nz, MstStyle1Grid_BottomSection
	ld	xwa, (xsp+4)
	ld	xiy, (xwa+74)
	ld	xwa, (xhl)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	ld	hl, (xiy)
	sub	hl, wa
	ld	wa, (xde)
	cp	wa, hl
	jr	ge, MstStyle1Grid_OutOfRange
	add	ix, wa
	sla	ix, 3
	ld	xwa, (xsp+8)
	ld_rrl	xwa, xwa, ix
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+10), 0
	jr	MstStyle1Grid_PadLeft_Check
MstStyle1Grid_PadLeft_Loop:
	pushw	1
	pushw	237
	pushw	3444
	lda	xwa, (xsp+18)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+10)
MstStyle1Grid_PadLeft_Check:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+82)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	add	wa, (xsp+32)
	sla	wa, 3
	lda	xbc, (StyleGroup_LatinWorld_PairTable_0x2FA:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 16
	sub	bc, hl
	ld	a, (xsp+10)
	extz	wa
	cp	wa, bc
	jr	c, MstStyle1Grid_PadLeft_Loop
	jr	MstStyle1Grid_CheckPlayAudio
MstStyle1Grid_OutOfRange:
	pushw	237
	pushw	3446
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	jr	MstStyle1Grid_CheckPlayAudio
MstStyle1Grid_BottomSection:
	add	ix, (xde)
	sla	ix, 3
	ld	xwa, (xsp+8)
	ld_rrl	xwa, xwa, ix	; ld xwa, (xwa+ix)
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+10), 0
	jr	MstStyle1Grid_PadLeft_CheckB
MstStyle1Grid_PadLeft_LoopB:
	pushw	1
	pushw	237
	pushw	3464
	lda	xwa, (xsp+18)
	push	xwa
	call	0xff04b5
	lda	xsp, (xsp+10)
	inc	1, (xsp+10)
MstStyle1Grid_PadLeft_CheckB:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+82)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	add	wa, (xsp+32)
	sla	wa, 3
	lda	xbc, (StyleGroup_LatinWorld_PairTable_0x2FA:24)
	ld_rrl	xwa, xbc, wa	; ld xwa, (xbc+wa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 16
	sub	bc, hl
	ld	a, (xsp+10)
	extz	wa
	cp	wa, bc
	jr	c, MstStyle1Grid_PadLeft_LoopB
MstStyle1Grid_CheckPlayAudio:
	ld wa, (xsp + 30)
	cp wa, 1:i3
	jr nz, MstStyle1Grid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 30)
	ld xbc, 0x1e0008c
	call SendEvent

MstStyle1Grid_ReturnZero:
	ld xhl, 0:i3

MstStyle1Grid_Epilogue:
	pop xiz
	lda xsp, (xsp + 38)
	ret

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
	lda xix, (MstStyle1_EventDispatch:24)
; Computed jump: target = MstStyle1_EventDispatch + Str_StoreTotalSetting_DE_0x112[i], Str_StoreTotalSetting_DE_0x112 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcMstStyle1SubGridBoxProc_Evt1C00017
;   0x1c00018 -> AcMstStyle1SubGridBoxProc_Evt1C00018
;   0x1c00019 -> AcMstStyle1SubGridBoxProc_Evt1C00017
;   0x1c0001a -> AcMstStyle1SubGridBoxProc_Evt1C00018
;   0x1c0001b -> MstStyle1Sub_InheritedFallback
;   0x1c0001c -> MstStyle1Sub_ForwardToChild
;   0x1c0001d -> MstStyle1Sub_ForwardToChild
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 58)
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp
	ld wa, (0x0340c4:24)
	extz xwa
	sll xwa, 3
	lda xbc, (StyleGroup_LatinDance_Table:24)
	add xbc, xwa
	ld xde, (xbc)
	ld (0x0340d2:24), xde
	ld c, 0x0:opc

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
	cp c, 0:i3
	jr z, MstStyle1Sub_CountEntries_Adjust
	dec 1, c

MstStyle1Sub_CountEntries_Adjust:
	ld wa, (0x0340c4:24)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	ld (0x0340c6:24), wa
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
	ld wa, (0x0340c6:24)
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
	ld wa, (0x0340c6:24)
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
	ld wa, (0x0340c4:24)
	extz xwa
	sll xwa, 3
	lda xbc, (StyleGroup_LatinDance_Table:24)
	add xbc, xwa
	ld xde, (xbc)
	ld (0x0340d2:24), xde
	ld c, 0x0:opc

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
	cp c, 0:i3
	jr z, MstStyle1Sub_SubSel_Adjust
	dec 1, c

MstStyle1Sub_SubSel_Adjust:
	ld wa, (0x0340c4:24)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	ld (0x0340c6:24), wa
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
	ld wa, (0x0340c6:24)
	extz xwa
	div wa, 0xa
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000b
	ld xde, 0:i3
	call PostEvent
	jrl SeqFile_ReturnZeroJmp
AcMstStyle1SubGridBoxProc_Evt1C00017:
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
	ld xde, 0:i3
	call SendEvent
	lda xbc, (0x0340c8:24)
	cp hl, 0:i3
	jr nz, MstStyle1Sub_DialDown_Decrement
	ld xwa, (xsp + 8)
	lda xde, (xwa + 82)
	ld xwa, (xde)
	cpw (xwa), 0x1
	jrl le, SeqFile_ReturnZeroJmp
	decw	1, (xwa)
	ld xwa, (xde)
	ld wa, (xwa)
	muls wa, 0xa
	dec 1, wa
	ld (0x0340c6:24), wa
	ld de, (0x0340c4:24)
	extz xde
	add xbc, xde
	ld (xbc), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld wa, (0x0340c6:24)
	dec 1, wa
	ld (0x0340c6:24), wa
	ld de, (0x0340c4:24)
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
	ld wa, 1:i3
	jrl MstStyle1Sub_SetDialEnable
AcMstStyle1SubGridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
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
	ld bc, (0x0340c6:24)
	ld wa, (xiy)
	cp wa, (xix)
	jr ge, MstStyle1Sub_DialUp_CheckLimit
	lda xix, (0x0340c8:24)
	cp hl, 0x9
	jr nz, MstStyle1Sub_DialUp_Increment
	incw 1, (xiy)
	ld xwa, (xiz)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	ld (0x0340c6:24), wa
	ld bc, (0x0340c4:24)
	extz xbc
	add xix, xbc
	ld (xix), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld (0x0340c6:24), bc
	ld wa, (0x0340c4:24)
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
	ld (0x0340c6:24), bc
	ld wa, (0x0340c4:24)
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
	ld wa, 1:i3

MstStyle1Sub_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_GetNameA:
	ld	xwa, (xsp+66)
	call	GetViewInstance
	ld	xwa, (xhl+62)
	push	xwa
	ld	xwa, (xsp+62)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	SeqFile_ReturnZeroJmp
MstStyle1Sub_GetNameB_DrawString:
	ld XWA,(XSP+0x42)
	call GetViewInstance
	ld (XSP+0x08),XHL
	ld XWA,(XSP+0x08)
	ld XWA,(XWA+0x42)
	push XWA
	ld XWA,(XSP+0x3e)
	push XWA
	call Free_Compare2
	lda xhl, (xsp + 0x36)
	ldw (XHL), 0x00fe
	lda xbc, (xhl + 0x02)
	ldw (XBC), 0x0023
	lda xde, (xsp + 0x3a)
	ld WA,(XHL)
	ld (XDE),WA
	ld WA,(XHL)
	add WA,0x001e
	ld (XDE+0x04),WA
	ld WA,(XBC)
	ld (XDE+0x02),WA
	ld WA,(XBC)
	add WA,0x0013
	ld (XDE+0x06),WA
	ld XBC,(XSP+0x10)
	ld	xwa, (xbc+78)
	pushw	(xwa)
	ld	xwa, (xbc+82)
	pushw	(xwa)
	pushw	237
	pushw	3480
	lda	xwa, (xsp+28)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	lda	xwa, (xsp+50)
	lda	xbc, (xsp+46)
	lda	xde, (xsp+12)
	ld	xhl, 6:i3
	push	xhl
	pushw	255
	pushw	245
	call	DrawString
	jr	SeqFile_ReturnZeroJmp
MstStyle1Sub_ForwardToChild:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 62)
	ld xde, (xsp + 58)
	call ApFuncCall

SeqFile_ReturnZeroJmp:
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1SubGrid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1SubGrid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0x136
	ld wa, (xwa)
	lda xix, (MstStyle1Sub_EventDispatch:24)
; Computed jump: target = MstStyle1Sub_EventDispatch + Str_StoreTotalSetting_DE_0x136[i], Str_StoreTotalSetting_DE_0x136 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> MstStyle1Sub_EventDispatch
;   0x1c00018 -> MstStyle1Sub_EventDispatch
;   0x1c00019 -> MstStyle1Sub_EventDispatch
;   0x1c0001a -> MstStyle1Sub_EventDispatch
;   0x1c0001b -> MstStyle1SubGrid_Epilogue
;   0x1c0001c -> MstStyle1Sub_EventDispatch
;   0x1c0001d -> MstStyle1Sub_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1SubGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0dc2)
MstStyle1Sub_EventDispatch:
	jrl	t, MstStyle1SubGrid_Epilogue
MstStyle1SubGrid_CellSelect:
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	(xsp+4), xhl
	lda	xwa, (xsp+26)
	ld	xbc, xiz
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	lda	xbc, (xwa+2)
	ld	de, iz
	ld	(xbc), de
	lda	xde, (xsp+8)
	ld	(xwa+4), xde
	ld	xwa, (xsp+4)
	lda	xhl, (xwa+82)
	ld	xiy, (xhl)
	lda	xix, (xwa+78)
	ld	xiz, (xix)
	ld	xwa, (xhl)
	ld	hl, (xwa)
	muls	hl, 10
	sub	hl, 10
	ld	wa, (xiz)
	cp	wa, (xiy)
	jrl	nz, MstStyle1SubGrid_BottomSection
	ld	xwa, (xsp+4)
	ld	xiy, (xwa+74)
	ld	xwa, (xix)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	ld	ix, (xiy)
	sub	ix, wa
	ld	wa, (xbc)
	cp	wa, ix
	jr	gt, MstStyle1SubGrid_OutOfRange
	add	hl, wa
	exts	xhl
	sll	xhl, 3
	add	xhl, (213202:24)
	ld	xwa, (xhl)
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	ldib_erp	251, 0
	jr	MstStyle1SubGrid_PadLeft_Check
MstStyle1SubGrid_PadLeft_Loop:
	pushw 0x1

	pushw 0xed

	pushw 0xdac

	lda xwa, (xsp + 14)

	push xwa

	call	16712885

	lda xsp, (xsp + 10)

	inc1b_erp	251	; inc 1, qizh



MstStyle1SubGrid_PadLeft_Check:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+82)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	add	wa, (xsp+28)
	exts	xwa
	sll	xwa, 3
	add	xwa, (0x0340d2:24)
	ld	xwa, (xwa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 16
	sub	bc, hl
	stb_erp	a, 251	; ld a, qizh
	extz	wa
	cp	wa, bc
	jr	c, MstStyle1SubGrid_PadLeft_Loop
	jr	MstStyle1SubGrid_CheckPlayAudio
MstStyle1SubGrid_OutOfRange:
	pushw	237
	pushw	3502
	push	xde
	call	Free_Compare2
	inc	8, xsp
	jr	MstStyle1SubGrid_CheckPlayAudio
MstStyle1SubGrid_BottomSection:
	add	hl, (xbc)
	exts	xhl
	sll	xhl, 3
	add	xhl, (0x0340d2:24)
	ld	xwa, (xhl)
	push	xwa
	push	xde
	call	Free_Compare2
	inc	8, xsp
	ldib_erp	251, 0	; ld qizh, 0
	jr	MstStyle1SubGrid_PadLeft_CheckB
MstStyle1SubGrid_PadLeft_LoopB:
	pushw 0x1

	pushw 0xed

	pushw 0xdc0

	lda xwa, (xsp + 14)

	push xwa

	call	16712885

	lda xsp, (xsp + 10)

	inc1b_erp	251	; inc 1, qizh



MstStyle1SubGrid_PadLeft_CheckB:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+82)
	ld	wa, (xwa)
	muls	wa, 10
	sub	wa, 10
	add	wa, (xsp+28)
	exts	xwa
	sll	xwa, 3
	add	xwa, (0x0340d2:24)
	ld	xwa, (xwa)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 16
	sub	bc, hl
	stb_erp	a, 251	; ld a, qizh
	extz	wa
	cp	wa, bc
	jr	c, MstStyle1SubGrid_PadLeft_LoopB
MstStyle1SubGrid_CheckPlayAudio:
	ld wa, (xsp + 26)
	cp wa, 1:i3
	jr nz, MstStyle1SubGrid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 26)
	ld xbc, 0x1e0008c
	call SendEvent

MstStyle1SubGrid_ReturnZero:
	ld xhl, 0:i3

MstStyle1SubGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 30)
	ret

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
	lda xix, (MstStyle1Page_EventDispatch:24)
; Computed jump: target = MstStyle1Page_EventDispatch + Str_StoreTotalSetting_DE_0x178[i], Str_StoreTotalSetting_DE_0x178 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcMstStyle2GridBoxProc_Evt1C00017
;   0x1c00018 -> AcMstStyle2GridBoxProc_Evt1C00018
;   0x1c00019 -> AcMstStyle2GridBoxProc_Evt1C00017
;   0x1c0001a -> AcMstStyle2GridBoxProc_Evt1C00018
;   0x1c0001b -> MstStyle2_InheritedFallback
;   0x1c0001c -> MstStyle2_ForwardToChild
;   0x1c0001d -> MstStyle2_ForwardToChild
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 48)
	cp xwa, 0x4
	jrl z, MstStyle2_HandleSpecialEvent
	cp xwa, 0x3
	jrl z, MstStyle2_HandleSpecialEvent
	or xwa, xwa
	jrl nz, SeqData_ReturnZero
	ld wa, (0x0340c4:24)
	extz xwa
	sll xwa, 3
	lda xbc, (StyleGroup_LatinDance_Table:24)
	add xbc, xwa
	ld xde, (xbc)
	ld (0x0340d2:24), xde
	ld c, 0x0:opc

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
	cp c, 0:i3
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
	ld wa, (0x0340c6:24)
	srl wa, 1
	inc 1, wa
	ld (xbc), wa
	ld xbc, (xhl + 86)
	ld wa, (0x0340c6:24)
	ld (xbc), wa
	ld xwa, (xhl + 90)
	ldw (xwa), 0x1
	ld wa, (0x0340c6:24)
	bit 0, wa
	jrl nz, MstStyle2_InitOdd_Setup
	extz xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340d6:24), xhl
	ld c, 0x0:opc

MstStyle2_CountSubEntries_LoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_CountSubEntries_DoneA
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_CountSubEntries_LoopA

MstStyle2_CountSubEntries_DoneA:
	cp c, 0:i3
	jr z, MstStyle2_CountSubEntries_AdjA
	dec 1, c

MstStyle2_CountSubEntries_AdjA:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xwa, (xde)
	ld bc, (xwa)
	ld wa, (0x0340c6:24)
	cp bc, wa
	jr ule, MstStyle2_InitDone_PostEvent
	inc 1, wa
	extz xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xde, (xwa + 4)
	ld (0x0340da:24), xde
	ld c, 0x0:opc

MstStyle2_CountSubEntries_LoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_CountSubEntries_DoneB
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_CountSubEntries_LoopB

MstStyle2_CountSubEntries_DoneB:
	cp c, 0:i3
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
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	jrl MstStyle2_SendEvent_Done

MstStyle2_InitOdd_Setup:
	dec 1, wa
	extz xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xde, (xwa + 4)
	ld (0x0340d6:24), xde
	ld c, 0x0:opc

MstStyle2_InitOdd_CountLoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_InitOdd_CountDoneA
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_InitOdd_CountLoopA

MstStyle2_InitOdd_CountDoneA:
	cp c, 0:i3
	jr z, MstStyle2_InitOdd_CountAdjA
	dec 1, c

MstStyle2_InitOdd_CountAdjA:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 94)
	extz bc
	ld (xde), bc
	ld wa, (0x0340c6:24)
	extz xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xde, (xwa + 4)
	ld (0x0340da:24), xde
	ld c, 0x0:opc

MstStyle2_InitOdd_CountLoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_InitOdd_CountDoneB
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_InitOdd_CountLoopB

MstStyle2_InitOdd_CountDoneB:
	cp c, 0:i3
	jr z, MstStyle2_InitOdd_CountAdjB
	dec 1, c

MstStyle2_InitOdd_CountAdjB:
	ld xwa, (xsp + 8)
	ld xde, (xwa + 98)
	extz bc
	ld (xde), bc
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000b
	ld xde, 0:i3
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
	ld xde, 0:i3
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
	ld xde, 0:i3
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
	lda xbc, (0x0340c8:24)
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
	cp wa, 0:i3
	jr z, MstStyle2_DialDown_PageDec
	decw	1, (xix)
	ld wa, (0x0340c4:24)
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
	decw	1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340d6:24), xhl
	ld c, 0x0:opc

MstStyle2_PageDec_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageDec_CountDone
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_PageDec_CountLoop

MstStyle2_PageDec_CountDone:
	cp c, 0:i3
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
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340da:24), xhl
	ld c, 0x0:opc

MstStyle2_PageDec_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageDec_CountDone2
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_PageDec_CountLoop2

MstStyle2_PageDec_CountDone2:
	cp c, 0:i3
	jr z, MstStyle2_PageDec_CountAdj2
	dec 1, c

MstStyle2_PageDec_CountAdj2:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 98)
	extz bc
	ld (xhl), bc

MstStyle2_DialDown_UpdateAndPost:
	ld xwa, (xde)
	decw	1, (xwa)
	ld wa, (0x0340c4:24)
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	cp wa, 0:i3
	jr nz, MstStyle2_DialUp_PageInc
	incw 1, (xiy)
	ld wa, (0x0340c4:24)
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
	incw 1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340d6:24), xhl
	ld c, 0x0:opc

MstStyle2_PageInc_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageInc_CountDone
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_PageInc_CountLoop

MstStyle2_PageInc_CountDone:
	cp c, 0:i3
	jr z, MstStyle2_PageInc_CountAdj
	dec 1, c

MstStyle2_PageInc_CountAdj:
	ld xwa, (xsp + 4)
	ld xhl, (xwa + 94)
	extz bc
	ld (xhl), bc
	ld xwa, (xix)
	ld wa, (xwa)
	ld (0x0340bc:24), wa
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	ld (0x0340be:24), wa
	cp (0x340bc:24), wa
	jr le, MstStyle2_DialUp_UpdateAndPost
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340da:24), xhl
	ld c, 0x0:opc

MstStyle2_PageInc_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_PageInc_CountDone2
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_PageInc_CountLoop2

MstStyle2_PageInc_CountDone2:
	cp c, 0:i3
	jr z, MstStyle2_PageInc_CountAdj2
	dec 1, c

MstStyle2_PageInc_CountAdj2:
	ld xwa, (xsp + 8)
	ld xhl, (xwa + 98)
	extz bc
	ld (xhl), bc

MstStyle2_DialUp_UpdateAndPost:
	ld xwa, (xde)
	incw 1, (xwa)
	ld wa, (0x0340c4:24)
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
AcMstStyle2GridBoxProc_Evt1C00017:
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
	ld xde, 0:i3
	call SendEvent
	ld ix, hl
	lda xbc, (0x0340c8:24)
	cp ix, 0:i3
	jrl nz, MstStyle2_DialScrollUp_Middle
	ld xhl, (xsp + 8)
	lda xde, (xhl + 82)
	ld xwa, (xde)
	ld wa, (xwa)
	ld (0x0340bc:24), wa
	cp wa, 1:i3
	jrl le, MstStyle2_DialScroll_SetAutoInc
	lda xhl, (xhl + 86)
	ld xwa, (xhl)
	decw	1, (xwa)
	ld wa, (0x0340c4:24)
	extz xwa
	add xbc, xwa
	ld xwa, (xhl)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xde)
	decw	1, (xwa)
	ld xwa, (xde)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340d6:24), xhl
	ld c, 0x0:opc

MstStyle2_DialScrollDown_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScrollDown_CountDone
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_DialScrollDown_CountLoop

MstStyle2_DialScrollDown_CountDone:
	cp c, 0:i3
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
	add xwa, (0x340d2:24)
	ld xde, (xwa + 4)
	ld (0x0340da:24), xde
	ld c, 0x0:opc

MstStyle2_DialScrollDown_Count2Loop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScrollDown_Count2Done
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_DialScrollDown_Count2Loop

MstStyle2_DialScrollDown_Count2Done:
	cp c, 0:i3
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
	ld xde, 0:i3
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
	cp ix, 5:i3
	jr nz, MstStyle2_DialScrollUp_Simple
	ld xhl, (xsp + 4)
	lda xde, (xhl + 86)
	ld xwa, (xde)
	decw	1, (xwa)
	ld wa, (0x0340c4:24)
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
	ld wa, 1:i3
	jrl MstStyle2_SetDialEnable
AcMstStyle2GridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
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
	incw 1, (xwa)
	ld wa, (0x0340c4:24)
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
	ld (0x0340bc:24), wa
	ld xwa, (xbc + 78)
	ld wa, (xwa)
	ld (0x0340be:24), wa
	cp (0x340bc:24), wa
	jrl ge, MstStyle2_DialScroll_AutoInc
	ld xwa, (xix)
	incw 1, (xwa)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	add xwa, (0x340d2:24)
	ld xiy, (xwa + 4)
	ld (0x0340d6:24), xiy
	ld c, 0x0:opc

MstStyle2_DialScroll_CountLoopD:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xf4, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScroll_CountDoneD
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_DialScroll_CountLoopD

MstStyle2_DialScroll_CountDoneD:
	cp c, 0:i3
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
	add xwa, (0x340d2:24)
	ld xhl, (xwa + 4)
	ld (0x0340da:24), xhl
	ld c, 0x0:opc

MstStyle2_DialScroll_CountLoopE:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
	or xwa, xwa
	jr z, MstStyle2_DialScroll_CountDoneE
	inc 1, c
	cp c, 4:i3
	jr c, MstStyle2_DialScroll_CountLoopE

MstStyle2_DialScroll_CountDoneE:
	cp c, 0:i3
	jr z, MstStyle2_DialScroll_CountAdjE
	dec 1, c

MstStyle2_DialScroll_CountAdjE:
	ld xde, (xde)
	extz bc
	ld (xde), bc

MstStyle2_DialScroll_IncAndPost:
	lda xbc, (xiz + 86)
	ld xwa, (xbc)
	incw 1, (xwa)
	ld wa, (0x0340c4:24)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld wa, 1:i3

MstStyle2_SetDialEnable:
	call SetDialEnable
	jrl SeqData_ReturnZero

MstStyle2_GetNameA:
	ld	xwa, (xsp+56)
	call	GetViewInstance
	ld	xwa, (xhl+62)
	push	xwa
	ld	xwa, (xsp+52)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	SeqData_ReturnZero
MstStyle2_GetNameB_DrawString:
	ld XWA,(XSP+0x38)
	call GetViewInstance
	ld XIZ,XHL
	ld XWA,(XIZ+0x42)
	push XWA
	ld XWA,(XSP+0x34)
	push XWA
	call Free_Compare2
	lda xhl, (xsp + 0x2c)
	ldw (XHL), 0x000a
	lda xbc, (xhl + 0x02)
	ldw (XBC), 0x0032
	lda xde, (xsp + 0x30)
	ld WA,(XHL)
	ld (XDE),WA
	ld WA,(XHL)
	add WA,0x0094
	ld (XDE+0x04),WA
	ld WA,(XBC)
	ld (XDE+0x02),WA
	ld WA,(XBC)
	add WA,0x0014
	ld (XDE+0x06),WA
	ld XWA,(XIZ+0x52)
	ld WA,(XWA)
	sla WA, 0x01
	dec 2,WA
	exts XWA
	sll XWA, 0x03
	add	xwa, (213202:24)
	ld	xwa, (xwa)
	push	xwa
	pushw 237
	pushw 3536
	lda	xwa, (xsp+34)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+20)
	lda	xwa, (xsp+40)
	lda	xbc, (xsp+36)
	lda	xde, (xsp+18)
	ld	xhl, 0:i3
	push	xhl
	pushw 251
	pushw 245
	call	DrawString
	ld	xbc, (xiz+82)
	ld	xwa, (xiz+78)
	lda	xde, (xsp+18)
	ld	wa, (xwa)
	cp	wa, (xbc)
	jr	nz, MstStyle2_NameB_DrawLower
	ld	xhl, (xiz+74)
	ld	wa, (xbc)
	sla	wa, 1
	dec	1, wa
	cp	wa, (xhl)
	jr	le, MstStyle2_NameB_DrawCurrent
	pushw 237
	pushw 3540
	push	xde
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, 15535590
	jr	MstStyle2_NameB_Render
MstStyle2_NameB_DrawCurrent:
	exts	xwa
	sll	xwa, 3
	add	xwa, (213202:24)
	ld	xwa, (xwa)
	push	xwa
	pushw	237
	pushw	3564
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	ld	xwa, 15535600
	jr	MstStyle2_NameB_Render
MstStyle2_NameB_DrawLower:
	ld	wa, (xbc)
	sla	wa, 1
	dec	1, wa
	exts	xwa
	sll	xwa, 3
	add	xwa, (213202:24)
	ld	xwa, (xwa)
	push	xwa
	pushw	237
	pushw	3574
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	ld	xwa, 15535610
MstStyle2_NameB_Render:
	push	xwa
	lda	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xbc, (xsp+36)
	ldw	(xbc), 10
	lda	xhl, (xbc+2)
	ldw	(xhl), 130
	lda	xwa, (xsp+40)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 148
	ld	(xwa+4), de
	ld	de, (xhl)
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 20
	ld	(xwa+6), de
	lda	xde, (xsp+18)
	ld	xhl, 0:i3
	push	xhl
	pushw 251
	pushw 245
	call	DrawString
	lda	xbc, (xsp+36)
	ldw	(xbc), 267
	lda	xhl, (xbc+2)
	ldw	(xhl), 130
	lda	xwa, (xsp+40)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 44
	ld	(xwa+4), de
	ld	de, (xhl)
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 19
	ld	(xwa+6), de
	lda	xde, (xsp+12)
	ld	xhl, 0:i3
	push	xhl
	pushw 251
	pushw 245
	call	DrawString
	lda	xhl, (xsp+36)
	ldw	(xhl), 145
	lda	xbc, (xhl+2)
	ldw	(xbc), 32
	lda	xde, (xsp+40)
	ld	wa, (xhl)
	ld	(xde), wa
	ld	wa, (xhl)
	add	wa, 148
	ld	(xde+4), wa
	ld	wa, (xbc)
	ld	(xde+2), wa
	ld	wa, (xbc)
	add	wa, 20
	ld	(xde+6), wa
	ld	wa, (213188:24)
	extz	xwa
	sll	xwa, 3
	ld	xbc, 15531172
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	pushw 237
	pushw 3584
	lda	xwa, (xsp+26)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+40)
	lda	xbc, (xsp+36)
	lda	xde, (xsp+18)
	ld	xhl, 0:i3
	push	xhl
	pushw 255
	pushw 247
	call	DrawString
	jr	SeqData_ReturnZero
MstStyle2_ForwardToChild:
	ld xwa, (xsp + 56)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 52)
	ld xde, (xsp + 48)

Seq_ApplyFunctionAndReturn:
	call ApFuncCall

SeqData_ReturnZero:
	ld xhl, 0:i3
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
	lda xix, (MstGrid2_ScrollJumpTable:24)
; Computed jump: target = MstGrid2_ScrollJumpTable + Str_StoreTotalSetting_DE_0x238[i], Str_StoreTotalSetting_DE_0x238 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> MstGrid2_ScrollJumpTable
;   0x1c00018 -> MstGrid2_ScrollJumpTable
;   0x1c00019 -> MstGrid2_ScrollJumpTable
;   0x1c0001a -> MstGrid2_ScrollJumpTable
;   0x1c0001b -> MstGrid2_Return
;   0x1c0001c -> MstGrid2_Return
;   0x1c0001d -> MstGrid2_Return
	jp_ind 8, 0x07, 0xf0, 0xe0

MstGrid2_ScrollJumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+62), xhl
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	xbc, (xsp+62)
	ld	(xsp+56), bc
	cp	bc, 4:i3
	jr	ge, MstStyle2GridCheck_Skip
	ld	xwa, (xhl+94)
	cp	bc, (xwa)
	jrl	gt, MstGrid2_Return
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (0x340d6:24)
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	jr	MstStyle2GridCheck_Join
MstStyle2GridCheck_Skip:
	ld	xwa, (xhl+98)
	ld	wa, (xwa)
	inc	5, wa
	cp	bc, wa
	jrl	gt, MstGrid2_Return
	dec	5, bc
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (0x340da:24)
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
MstStyle2GridCheck_Join:
	call	MainFuncCall
	jrl	MstGrid2_Return

MstGrid2_CellSelect:
	call GetFocusObject
	ld XWA,XHL
	call GetViewInstance
	ld (XSP+0x08),XHL
	ld XIX,(XSP+0x08)
	ld (XSP+0x04),XIX
	lda xhl, (xsp + 0x36)
	ld XWA,(XSP+0x3e)
	srl XWA, 0x00
	ld QWA,0
	ld (XHL),WA
	lda xbc, (xhl + 0x02)
	ld XWA,(XSP+0x3e)
	ld DE,WA
	ld (XBC),DE
	lda xwa, (xsp + 0x14)
	ld (XSP+0x0c),XWA
	ld (XHL+0x04),XWA
	ld XHL,(XIX+0x52)
	ld XWA,XIX
	ld XIX,(XWA+0x4e)
	ld DE,(XBC)
	ld WA,DE
	exts XWA
	ld BC,DE
	dec 5,BC
	exts XBC
	ld XIY,XWA
	add XIY,XIY
	add XIY,XWA
	add XIY,XIY
	add	xiy, (213206:24)
	ld	xwa, xbc
	add	xwa, xwa
	add	xwa, xbc
	add	xwa, xwa
	ld	(xsp+16), xwa
	ld	xwa, (213210:24)
	add	(xsp+16), xwa
	ld	xwa, (xsp+8)
	ld	xbc, (xwa+98)
	ld	xiz, (xwa+94)
	ld	bc, (xbc)
	inc	5, bc
	ld	wa, (xhl)
	cp	wa, (xix)
	jrl	ge, MstGrid2_LowerSection
	cp	de, 4:i3
	jr	ge, MstGrid2_UpperHalf
	cp	de, (xiz)
	jr	gt, MstGrid2_OutOfRange_LowCol
	ld	xwa, (xiy)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+18), 0
	jr	MstGrid2_PadLeft_CheckA
MstGrid2_PadLeft_LoopA:
	pushw	1
	pushw	237
	pushw	3602
	lda	xwa, (xsp+26)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+18)
MstGrid2_PadLeft_CheckA:
	ld	wa, (xsp+56)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (213206:24)
	ld	xwa, (xbc)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+18)
	extz	wa
	cp	wa, bc
	jr	c, MstGrid2_PadLeft_LoopA
	jrl	MstGrid2_CheckPlayAudio
MstGrid2_OutOfRange_LowCol:
	ld xwa, Str_StoreTotalSetting_DE_0x188
	jrl MstGrid2_CopyFallback

MstGrid2_UpperHalf:
	cp	de, bc
	jr	gt, MstGrid2_OutOfRange_HighCol
	ld	xwa, (xsp+16)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+18), 0
	jr	MstGrid2_PadLeft_CheckB
MstGrid2_PadLeft_LoopB:
	pushw	1
	pushw	237
	pushw	3638
	lda	xwa, (xsp+26)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+18)
MstGrid2_PadLeft_CheckB:
	ld	wa, (xsp+56)
	dec	5, wa
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (213210:24)
	ld	xwa, (xbc)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+18)
	extz	wa
	cp	wa, bc
	jr	c, MstGrid2_PadLeft_LoopB
	jrl	MstGrid2_CheckPlayAudio
MstGrid2_OutOfRange_HighCol:
	ld xwa, Str_StoreTotalSetting_DE_0x1AC
	jrl	MstGrid2_CopyFallback

MstGrid2_LowerSection:
	cp	de, 4:i3
	jr	ge, MstGrid2_BottomRight
	cp	de, (xiz)
	jr	gt, MstGrid2_OutOfRange_LowCol2
	ld	xwa, (xiy)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+18), 0
	jr	MstGrid2_PadLeft_CheckC
MstGrid2_PadLeft_LoopC:
	pushw	1
	pushw	237
	pushw	3674
	lda	xwa, (xsp+26)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+18)
MstGrid2_PadLeft_CheckC:
	ld	wa, (xsp+56)
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (213206:24)
	ld	xwa, (xbc)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+18)
	extz	wa
	cp	wa, bc
	jr	c, MstGrid2_PadLeft_LoopC
	jrl	MstGrid2_CheckPlayAudio
MstGrid2_OutOfRange_LowCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1D0
	jrl	MstGrid2_CopyFallback

MstGrid2_BottomRight:
	ld	xwa, (xsp+8)
	ld	xhl, (xwa+74)
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+82)
	ld	wa, (xwa)
	sla	wa, 1
	dec	2, wa
	cp	wa, (xhl)
	jr	ge, MstGrid2_OutOfRange_BeyondMax
	cp	de, bc
	jr	gt, MstGrid2_OutOfRange_HighCol2
	ld	xwa, (xsp+16)
	ld	xwa, (xwa)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	(xsp+18), 0
	jr	MstGrid2_PadLeft_CheckD
MstGrid2_PadLeft_LoopD:
	pushw	1
	pushw	237
	pushw	3710
	lda	xwa, (xsp+26)
	push	xwa
	call	16712885
	lda	xsp, (xsp+10)
	inc	1, (xsp+18)
MstGrid2_PadLeft_CheckD:
	ld	wa, (xsp+56)
	dec	5, wa
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	add	xbc, (213210:24)
	ld	xwa, (xbc)
	push	xwa
	call	LyricsTrack_ReadAndParse_Helper2
	inc	4, xsp
	ldw	bc, 32
	sub	bc, hl
	ld	a, (xsp+18)
	extz	wa
	cp	wa, bc
	jr	c, MstGrid2_PadLeft_LoopD
	jr	MstGrid2_CheckPlayAudio
MstGrid2_OutOfRange_HighCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1F4
	jr MstGrid2_CopyFallback

MstGrid2_OutOfRange_BeyondMax:
	ld xwa, Str_StoreTotalSetting_DE_0x216

MstGrid2_CopyFallback:
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
MstGrid2_CheckPlayAudio:
	ld wa, (xsp + 54)
	cp wa, 1:i3
	jr nz, MstGrid2_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 54)
	ld xbc, 0x1e0008c
	call SendEvent

MstGrid2_Return:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 62)
	ret
MstGrid2_Boundary:

AcMstSong1GridBoxProc:
	jp InheritedProc

MstSong1GridCheck:
	ld xhl, 0:i3
	ret

AcMstSong2GridBoxProc:
	jp InheritedProc

MstSong2GridCheck:
	ld xhl, 0:i3
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
	ld xde, 1:i3
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
	incw 1, (xwa)
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
	decw	1, (xwa)
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
	ld xhl, 0:i3

MstStylePgCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret

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
	lda xix, (MstStyle2_EventDispatch:24)
; Computed jump: target = MstStyle2_EventDispatch + Str_StoreTotalSetting_DE_0x246[i], Str_StoreTotalSetting_DE_0x246 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcTchSensGridBoxProc_Evt1C00017
;   0x1c00018 -> AcTchSensGridBoxProc_Evt1C00018
;   0x1c00019 -> AcTchSensGridBoxProc_Evt1C00017
;   0x1c0001a -> AcTchSensGridBoxProc_Evt1C00018
;   0x1c0001b -> TchSens_InheritedFallback
;   0x1c0001c -> AcTchSensGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcTchSensGridBoxProc_Evt1C0001C
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl TchSens_SetDialEnable
AcTchSensGridBoxProc_Evt1C00017:
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
	ld xde, 0:i3
	call SendEvent
	cp hl, 4:i3
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
	ld wa, 1:i3
	jrl TchSens_SetDialEnable
AcTchSensGridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
	call SendEvent
	cp hl, 1:i3
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
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	TchSens_ReturnZeroJmp
AcTchSensGridBoxProc_Evt1C0001C:
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	TchSens_CallApFunc
TchSens_ForwardToChild:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

TchSens_CallApFunc:
	call ApFuncCall

TchSens_ReturnZeroJmp:
	ld xhl, 0:i3
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
	lda xix, (TchSensGrid_EventDispatch:24)
; Computed jump: target = TchSensGrid_EventDispatch + Str_StoreTotalSetting_DE_0x27C[i], Str_StoreTotalSetting_DE_0x27C = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> TchSensGrid_EventDispatch
;   0x1c00018 -> TchSensGridCheck_Evt1C00018
;   0x1c00019 -> TchSensGrid_EventDispatch
;   0x1c0001a -> TchSensGridCheck_Evt1C00018
;   0x1c0001b -> TchSensGrid_ReturnZero
;   0x1c0001c -> TchSensGridCheck_Evt1C0001C
;   0x1c0001d -> TchSensGridCheck_Evt1C0001C
	jp_ind 8, 0x07, 0xf0, 0xe0
TchSensGrid_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry
	cp	de, 1:i3
	jr	nz, TchSensGridCheck_Entry
	ld	xwa, 256
	ld	bc, 1:i3
	ld	de, 2:i3
	jrl	TchSensGridCheck_Join
TchSensGridCheck_Entry:
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry2
	cp	de, 4:i3
	jr	nz, TchSensGridCheck_Entry2
	ld	xwa, 260
	ld	bc, 1:i3
	ld	de, 2:i3
	jrl	TchSensGridCheck_Join
TchSensGridCheck_Entry2:
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry3
	cp	de, 5:i3
	jr	nz, TchSensGridCheck_Entry3
	ld	xwa, 258
	ld	bc, 1:i3
	ld	de, 2:i3
	jrl	TchSensGridCheck_Join
TchSensGridCheck_Entry3:
	cpw	(xwa), 1
	jrl	nz, TchSensGrid_ReturnZero
	cp	de, 6:i3
	jrl	nz, TchSensGrid_ReturnZero
	ld	xwa, 259
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	TchSensGridCheck_Join
TchSensGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry4
	cp	de, 1:i3
	jr	nz, TchSensGridCheck_Entry4
	ld	xwa, 256
	ldw	bc, 65535
	ld	de, 2:i3
	jr	TchSensGridCheck_Join
TchSensGridCheck_Entry4:
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry5
	cp	de, 4:i3
	jr	nz, TchSensGridCheck_Entry5
	ld	xwa, 260
	ldw	bc, 65535
	ld	de, 2:i3
	jr	TchSensGridCheck_Join
TchSensGridCheck_Entry5:
	cpw	(xwa), 1
	jr	nz, TchSensGridCheck_Entry6
	cp	de, 5:i3
	jr	nz, TchSensGridCheck_Entry6
	ld	xwa, 258
	ldw	bc, 65535
	ld	de, 2:i3
	jr	TchSensGridCheck_Join
TchSensGridCheck_Entry6:
	cpw	(xwa), 1
	jrl	nz, TchSensGrid_ReturnZero
	cp	de, 6:i3
	jrl	nz, TchSensGrid_ReturnZero
	ld	xwa, 259
	ldw	bc, 65535
	ld	de, 2:i3
TchSensGridCheck_Join:
	call	MainLswAdd
	jrl	TchSensGrid_ReturnZero
TchSensGridCheck_Evt1C0001C:
	lda	xix, (xde+4)
	ld	xwa, (xde)
	cp	xwa, 256
	jr	nz, TchSensGridCheck_Skip
	lda	xwa, (xsp+14)
	ldw	(xwa), 1
	ldw	(xwa+2), 1
	lda	xbc, (xsp+4)
	ld	(xwa+4), xbc
	pushw	(xix)
	pushw	237
	pushw	3808
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 31457420
	jrl	TchSensGrid_SendEvent
TchSensGridCheck_Skip:
	ld	xwa, (xde)
	cp	xwa, 260
	jr	nz, TchSensGridCheck_Skip3
	lda	xwa, (xsp+14)
	ldw	(xwa), 1
	ldw	(xwa+2), 4
	lda	xbc, (xsp+4)
	ld	(xwa+4), xbc
	ld	xwa, 15535848
	cpw	(xix), 0
	jr	z, TchSensGridCheck_Skip2
	ld	xwa, 15535844
TchSensGridCheck_Skip2:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 31457420
	jrl	TchSensGrid_SendEvent
TchSensGridCheck_Skip3:
	lda	xiy, (xsp+14)
	lda	xiz, (xsp+4)
	lda	xbc, (xiy+2)
	lda	xhl, (xiy+4)
	ld	xwa, (xde)
	cp	xwa, 258
	jr	nz, TchSensGridCheck_Skip4
	ldw	(xiy), 1
	ldw	(xbc), 5
	ld	(xhl), xiz
	pushw	(xix)
	pushw	237
	pushw	3820
	push	xiz
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 31457420
	jrl	TchSensGrid_SendEvent
TchSensGridCheck_Skip4:
	ld	xwa, (xde)
	cp	xwa, 259
	jrl	nz, TchSensGrid_ReturnZero
	ldw	(xiy), 1
	ldw	(xbc), 6
	ld	(xhl), xiz
	pushw	(xix)
	pushw	237
	pushw	3824
	push	xiz
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 31457420
	jrl	TchSensGrid_SendEvent
TchSensGrid_CellSelect:
	lda xbc, (xsp + 0x0e)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XBC),WA
	lda xwa, (xbc + 0x02)
	ld (XWA),DE
	lda xde, (xsp + 0x04)
	ld (XBC+0x04),XDE
	cpw (XBC), 0x0001
	jr nz, .Lc_fba51b
	cpw (XWA), 0x0001
	jr nz, .Lc_fba51b
	ld XWA,0x00000100
	call AcApcToggleProc_Helper
	pushw hl
	pushw 0x00ed
	pushw 0x0ef4
	lda xwa, (xsp + 0x0a)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0a)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x0e)
	ld XBC,0x01e0008c
	jrl t, TchSensGrid_SendEvent
TchSensGrid_CheckCell_1_4:
.Lc_fba51b:
	cpw (XBC), 0x0001
	jr nz, TchSensGrid_CheckCell_1_5
	cpw (XWA), 0x0004
	jr nz, TchSensGrid_CheckCell_1_5
	ld XWA,0x00000104
	call AcApcToggleProc_Helper
	ld XWA,Str_StoreTotalSetting_DE_0x270
	cp hl, 0:i3
	jr nz, TchSensGrid_Cell_1_4_Render
	ld XWA,Str_StoreTotalSetting_DE_0x26C
TchSensGrid_Cell_1_4_Render:
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 31457420
	jr	TchSensGrid_SendEvent
TchSensGrid_CheckCell_1_5:
	cpw	(xbc), 1
	jr	nz, TchSensGrid_CheckCell_1_6
	cpw	(xwa), 5
	jr	nz, TchSensGrid_CheckCell_1_6
	ld	xwa, 258
	call	AcApcToggleProc_Helper
	pushw	hl
	pushw	237
	pushw	3840
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
	jr	TchSensGrid_SendEvent
TchSensGrid_CheckCell_1_6:
	cpw	(xbc), 1
	jr	nz, TchSensGrid_ReturnZero
	cpw	(xwa), 6
	jr	nz, TchSensGrid_ReturnZero
	ld	xwa, 259
	call	AcApcToggleProc_Helper
	pushw	hl
	pushw	237
	pushw	3844
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, 0x1e0008c
TchSensGrid_SendEvent:
	call SendEvent

TchSensGrid_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 18)
	ret

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
	lda xix, (TchSens_EventDispatch:24)
; Computed jump: target = TchSens_EventDispatch + Str_StoreTotalSetting_DE_0x28A[i], Str_StoreTotalSetting_DE_0x28A = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcFSWAssGridBoxProc_Evt1C00017
;   0x1c00018 -> AcFSWAssGridBoxProc_Evt1C00018
;   0x1c00019 -> AcFSWAssGridBoxProc_Evt1C00017
;   0x1c0001a -> AcFSWAssGridBoxProc_Evt1C00018
;   0x1c0001b -> FSWAss_InheritedFallback
;   0x1c0001c -> AcFSWAssGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcFSWAssGridBoxProc_Evt1C0001C
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl FSWAss_SetDialEnable
AcFSWAssGridBoxProc_Evt1C00017:
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl FSWAss_SetDialEnable
AcFSWAssGridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
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
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	FSWAss_ReturnZeroJmp
AcFSWAssGridBoxProc_Evt1C0001C:
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	FSWAss_CallApFunc
FSWAss_ForwardToChild:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

FSWAss_CallApFunc:
	call ApFuncCall

FSWAss_ReturnZeroJmp:
	ld xhl, 0:i3
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
	lda_dri XSP, 0xfd, 0xf8, 0xfe
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
	lda xix, (FSWAssGrid_EventDispatch:24)
; Computed jump: target = FSWAssGrid_EventDispatch + CtrlAssignStr_Off_0x4A[i], CtrlAssignStr_Off_0x4A = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> FSWAssGrid_EventDispatch
;   0x1c00018 -> FSWAssGridCheck_Evt1C00018
;   0x1c00019 -> FSWAssGrid_EventDispatch
;   0x1c0001a -> FSWAssGridCheck_Evt1C00018
;   0x1c0001b -> AudioTable_ReturnZero
;   0x1c0001c -> FSWAssGridCheck_Evt1C0001C
;   0x1c0001d -> FSWAssGridCheck_Evt1C0001C
	jp_ind 8, 0x07, 0xf0, 0xe0
FSWAssGrid_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+260)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry
	cp	de, 2:i3
	jr	nz, FSWAssGridCheck_Entry
	ld	xwa, 10374
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10374
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10374
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry2
	cp	de, 3:i3
	jr	nz, FSWAssGridCheck_Entry2
	ld	xwa, 10376
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10376
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10376
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry2:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry3
	cp	de, 4:i3
	jr	nz, FSWAssGridCheck_Entry3
	ld	xwa, 10378
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10378
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10378
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry3:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry4
	cp	de, 5:i3
	jr	nz, FSWAssGridCheck_Entry4
	ld	xwa, 10380
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10380
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10380
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry4:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry5
	cp	de, 6:i3
	jr	nz, FSWAssGridCheck_Entry5
	ld	xwa, 10382
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10382
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10382
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry5:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry6
	cp	de, 7:i3
	jr	nz, FSWAssGridCheck_Entry6
	ld	xwa, 10384
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 28
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10384
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10384
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry6:
	cpw	(xwa), 1
	jrl	nz, AudioTable_ReturnZero
	cp	de, 8
	jrl	nz, AudioTable_ReturnZero
	ld	xwa, 10368
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 30
	jrl	nc, AudioTable_ReturnZero
	ld	xwa, 10368
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	inc	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10368
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+260)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry7
	cp	de, 2:i3
	jr	nz, FSWAssGridCheck_Entry7
	ld	xwa, 10374
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10374
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10374
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry7:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry8
	cp	de, 3:i3
	jr	nz, FSWAssGridCheck_Entry8
	ld	xwa, 10376
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10376
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10376
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry8:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry9
	cp	de, 4:i3
	jr	nz, FSWAssGridCheck_Entry9
	ld	xwa, 10378
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10378
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10378
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry9:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry10
	cp	de, 5:i3
	jr	nz, FSWAssGridCheck_Entry10
	ld	xwa, 10380
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10380
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10380
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry10:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry11
	cp	de, 6:i3
	jr	nz, FSWAssGridCheck_Entry11
	ld	xwa, 10382
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10382
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10382
	ld	de, 2:i3
	jrl	FSWAssGridCheck_Join
FSWAssGridCheck_Entry11:
	cpw	(xwa), 1
	jr	nz, FSWAssGridCheck_Entry12
	cp	de, 7:i3
	jr	nz, FSWAssGridCheck_Entry12
	ld	xwa, 10384
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 0:i3
	jrl	z, AudioTable_ReturnZero
	ld	xwa, 10384
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10384
	ld	de, 2:i3
	jr	FSWAssGridCheck_Join
FSWAssGridCheck_Entry12:
	cpw	(xwa), 1
	jrl	nz, AudioTable_ReturnZero
	cp	de, 8
	jrl	nz, AudioTable_ReturnZero
	ld	xwa, 10368
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	cp	l, 29
	jrl	ule, AudioTable_ReturnZero
	ld	xwa, 10368
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	calr	AudioTable_FindMatchIndex
	dec	1, l
	extz	hl
	lda	xbc, (15535908:24)
	ld_rrb	c, xbc, hl
	extz	bc
	ld	xwa, 10368
	ld	de, 2:i3
FSWAssGridCheck_Join:
	call	MainLswPut
	jrl	AudioTable_ReturnZero
FSWAssGridCheck_Evt1C0001C:
	lda	xix, (xde+4)
	lda	xiy, (xsp+4)
	ld	xwa, (xde)
	cp	xwa, 10374
	jr	nz, FSWAssGridCheck_Skip
	lda	xwa, (xsp+260)
	ldw	(xwa), 1
	ldw	(xwa+2), 2
	ld	(xwa+4), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4590
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip:
	lda	xhl, (xsp+260)
	lda	xbc, (xhl+4)
	ld	xwa, (xde)
	cp	xwa, 10376
	jr	nz, FSWAssGridCheck_Skip2
	ldw	(xhl), 1
	ldw	(xhl+2), 3
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4594
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip2:
	ld	xwa, (xde)
	cp	xwa, 10378
	jr	nz, FSWAssGridCheck_Skip3
	ldw	(xhl), 1
	ldw	(xhl+2), 4
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4598
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip3:
	ld	xwa, (xde)
	cp	xwa, 10380
	jr	nz, FSWAssGridCheck_Skip4
	ldw	(xhl), 1
	ldw	(xhl+2), 5
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4602
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip4:
	lda	xiz, (xhl+2)
	ld	xwa, (xde)
	cp	xwa, 10382
	jr	nz, FSWAssGridCheck_Skip5
	ldw	(xhl), 1
	ldw	(xiz), 6
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4606
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip5:
	ld	xwa, (xde)
	cp	xwa, 10384
	jr	nz, FSWAssGridCheck_Skip6
	ldw	(xhl), 1
	ldw	(xiz), 7
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4610
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGridCheck_Skip6:
	ld	xwa, (xde)
	cp	xwa, 10368
	jrl	nz, AudioTable_ReturnZero
	ldw	(xhl), 1
	ldw	(xiz), 8
	ld	(xbc), xiy
	ld	wa, (xix)
	extz	wa
	calr	AudioTable_FindMatchIndex
	extz	hl
	sla	hl, 2
	lda	xbc, (15535940:24)
	ld_rrl	xwa, xbc, hl
	push	xwa
	pushw 237
	pushw 4614
	lda	xwa, (xsp+12)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+260)
	ld	xbc, 31457420
	jrl	AudioTable_SendEventAndContinue
FSWAssGrid_CellSelect:
	lda XBC,(XSP+0x0104)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XBC),WA
	lda xwa, (xbc + 0x02)
	ld (XWA),DE
	lda xde, (xsp + 0x04)
	ld (XBC+0x04),XDE
	cpw (XBC), 0x0001
	jr nz, .Lc_fbaf8b
	cpw (XWA), 0x0002
	jr nz, .Lc_fbaf8b
	ld XWA,0x00002886
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x120a
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jrl t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_3:
.Lc_fbaf8b:
	cpw (XBC), 0x0001
	jr nz, .Lc_fbafdb
	cpw (XWA), 0x0003
	jr nz, .Lc_fbafdb
	ld XWA,0x00002888
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x120e
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jrl t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_4:
.Lc_fbafdb:
	cpw (XBC), 0x0001
	jr nz, .Lc_fbb02b
	cpw (XWA), 0x0004
	jr nz, .Lc_fbb02b
	ld XWA,0x0000288a
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x1212
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jrl t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_5:
.Lc_fbb02b:
	cpw (XBC), 0x0001
	jr nz, .Lc_fbb07b
	cpw (XWA), 0x0005
	jr nz, .Lc_fbb07b
	ld XWA,0x0000288c
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x1216
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jrl t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_6:
.Lc_fbb07b:
	cpw (XBC), 0x0001
	jr nz, .Lc_fbb0cb
	cpw (XWA), 0x0006
	jr nz, .Lc_fbb0cb
	ld XWA,0x0000288e
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x121a
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jrl t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_7:
.Lc_fbb0cb:
	cpw (XBC), 0x0001
	jr nz, .Lc_fbb11a
	cpw (XWA), 0x0007
	jr nz, .Lc_fbb11a
	ld XWA,0x00002890
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x121e
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
	jr t, AudioTable_SendEventAndContinue
FSWAssGrid_CheckCell_1_8:
.Lc_fbb11a:
	cpw (XBC), 0x0001
	jr nz, AudioTable_ReturnZero
	cpw (XWA), 0x0008
	jr nz, AudioTable_ReturnZero
	ld XWA,0x00002880
	call AcApcToggleProc_Helper
	extz HL
	ld WA,HL
	calr AudioTable_FindMatchIndex
	extz HL
	sla HL, 0x02
	lda xbc, (Str_StoreTotalSetting_DE_0x2B8:24)
	ldl_dri xwa, 0x07, 0xe4, 0xec
	push XWA
	pushw 0x00ed
	pushw 0x1222
	lda xwa, (xsp + 0x0c)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0104)
	ld XBC,0x01e0008c
AudioTable_SendEventAndContinue:
	call SendEvent

AudioTable_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda_dri XSP, 0xfd, 0x08, 0x01
	ret

AudioTable_FindMatchIndex:
	ld l, 0x0:opc
	lda xde, (Str_StoreTotalSetting_DE_0x298:24)

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
	lda xix, (FswAsIni_EventDispatch:24)
; Computed jump: target = FswAsIni_EventDispatch + CtrlAssignStr_Off_0x58[i], CtrlAssignStr_Off_0x58 = 16-bit offsets (6 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = index:
;   0 -> SeqLoadFunc_ReturnZero
;   1 -> FswAsIni_EventDispatch
;   2 -> SeqLoadFunc_ReturnZero
;   3 -> SeqLoadFunc_ReturnZero
;   4 -> SeqLoadFunc_ReturnZero
;   5 -> SeqLoadFunc_ReturnZero
	jp_ind 8, 0x07, 0xf0, 0xe8
; FswAsIniFunc event dispatch (6-entry, event 0x1c00013, table 0xed1234)
FswAsIni_EventDispatch:
	calr	FSWAss_CheckAndNotify
	calr	FSWAss_RefreshAllVoices

SeqLoadFunc_ReturnZero:
	ld xhl, 0:i3
	ret

FSWAss_CheckAndNotify:
	ld	xwa, 16512
	call	16567398
	cp	hl, 1:i3
	ret	nz
	ld	xwa, 16512
	ld	bc, 0:i3
	ld	de, 4:i3
	call	16566832
	ret
FSWAss_RefreshAllVoices:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	16641574
	call	16648347
	call	16647846
	call	16648638
	call	16648774
	call	16648855
	call	16693037
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
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
	cp bc, 2:i3
	jr z, PmemPageCtl_OK_AdvanceTo2
	cp bc, 1:i3
	jrl nz, SeqLoad_ReturnZeroJmp2
	incw 1, (xwa)
	ld (0x0340e2:24), 0x01
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr SeqLoad_PostEvent

PmemPageCtl_OK_AdvanceTo2:
	cp (0x0340e2:24), 0x01
	jr nz, PmemPageCtl_OK_ResetTo1
	ld (0x0340e2:24), 0x02
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr SeqLoad_PostEvent

PmemPageCtl_OK_ResetTo1:
	ldw (xwa), 0x1
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
	ld xde, 0:i3
	jr SeqLoad_PostEvent

PmemPageCtl_OK_Rotate:
	cp xiz, 0x90
	jr nz, SeqLoad_ReturnZeroJmp2
	ld xwa, (xwa)
	ld bc, (xwa)
	cp bc, 2:i3
	jr z, PmemPageCtl_OK_RotateReverse
	cp bc, 1:i3
	jr nz, SeqLoad_ReturnZeroJmp2
	ldw (xwa), 0x2
	ld (0x0340e2:24), 0x02
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	ld xde, 0:i3

SeqLoad_PostEvent:
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotateReverse:
	cp (0x0340e2:24), 0x01
	jr nz, PmemPageCtl_OK_RotatePost
	decw	1, (xwa)
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
	ld xde, 0:i3
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotatePost:
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	ld xde, 0:i3
	call PostEvent
	ld (0x0340e2:24), 0x01

SeqLoad_ReturnZeroJmp2:
	ld xhl, 0:i3

PmemPageCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret
PmemPageCtl_Boundary:

AcPmExpFilterGridBoxProc:
	lda_dri XSP, 0xfd, 0xdc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x20, 0x01
	stl_dri XBC, 0xfd, 0x24, 0x01
	ld xiz, xwa
	ld XBC, (xsp + 0x0124)
	cp xbc, 0x1c00007
	jrl z, PmExpFilter_OkHandler
	ld XWA, (xsp + 0x0124)
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
	lda xix, (PmemPageCtl_EventDispatch:24)
; Computed jump: target = PmemPageCtl_EventDispatch + ParamStr02_Vocalist_0x44[i], ParamStr02_Vocalist_0x44 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcPmExpFilterGridBoxProc_Evt1C00017
;   0x1c00018 -> AcPmExpFilterGridBoxProc_Evt1C00018
;   0x1c00019 -> AcPmExpFilterGridBoxProc_Evt1C00017
;   0x1c0001a -> AcPmExpFilterGridBoxProc_Evt1C00018
;   0x1c0001b -> PmExpFilter_DefaultInherited
;   0x1c0001c -> AcPmExpFilterGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcPmExpFilterGridBoxProc_Evt1C0001C
	jp_ind 8, 0x07, 0xf0, 0xe4

; IvPmemWindowPageCtl event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1420)
PmemPageCtl_EventDispatch:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl PmExpFilter_SetDialEnable

PmExpFilter_ShowHide:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, 0xffff0002
	call SendEvent
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_Repaint:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
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
	ld xde, 0:i3
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
	ld xde, 0:i3
	push xde
	pushw 0xfb
	pushw 0xf5
	ld xde, ParamStr02_Vocalist_0x20
	call DrawString
	ld (xsp + 10), 0x0
	cp (0x0340e2:24), 0x01
	jrl nz, PmExpFilter_DrawCellBank2
PmExpFilter_DrawCellBank1:
	lda	xbc, (xsp+280)
	ldw	(xbc), 0
	ld	a, (xsp+10)
	inc	2, a
	extz	wa
	ld	(xbc+2), wa
	lda	xde, (xsp+24)
	ld	(xbc+4), xde
	ld	a, (xsp+10)
	extz	wa
	sla	wa, 2
	lda	xbc, (15536704:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw	237
	pushw	5124
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+280)
	ld	xbc, 31457420
	call	SendEvent
	inc	1, (xsp+10)
	cp	(xsp+10), 9
	jr	c, PmExpFilter_DrawCellBank1
	lda	xwa, (xsp+16)
	ldw	(xwa+2), 6
	ldw	(xwa+6), 23
	ldw	(xwa), 245
	ldw	(xwa+4), 315
	ldw	bc, 193
	ldw	de, 243
	call	DrawDesignBox
	lda	xde, (xsp+16)
	ld	wa, (xde+4)
	sub	wa, (xde)
	exts	xwa
	divs	wa, 2
	ld	bc, (xde)
	add	bc, wa
	lda	xhl, (xsp+12)
	ld	(xhl), bc
	ld	bc, (xde+2)
	ld	wa, (xde+6)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	inc	1, bc
	ld	(xhl+2), bc
	pushw 237
	pushw 5128
	lda	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+16)
	lda	xbc, (xsp+12)
	lda	xde, (xsp+24)
	ld	xhl, 0:i3
	push	xhl
	pushw 0
	pushw 247
	jrl	PmExpFilter_DrawCentered
PmExpFilter_DrawCellBank2:
.Lc_fbb5f9:
	lda XBC,(XSP+0x0118)
	ldw (XBC), 0x0000
	ld A,(XSP+0x0a)
	inc 2,A
	extz WA
	ld (XBC+0x02),WA
	lda xde, (xsp + 0x18)
	ld (XBC+0x04),XDE
	ld A,(XSP+0x0a)
	extz WA
	sla WA, 0x02
	lda xbc, (ParamStr_Table_02:24)
	ldl_dri xwa, 0x07, 0xe4, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x1412
	push XDE
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda XDE,(XSP+0x0118)
	ld XBC,0x01e0008c
	call SendEvent
	inc	1, (xsp+10)
	cp	(xsp+10), 9
	jr	c, PmExpFilter_DrawCellBank2
	lda	xwa, (xsp+16)
	ldw	(xwa+2), 6
	ldw	(xwa+6), 23
	ldw	(xwa), 245
	ldw	(xwa+4), 315
	ldw	bc, 193
	ldw	de, 243
	call	DrawDesignBox
	lda	xde, (xsp+16)
	ld	wa, (xde+4)
	sub	wa, (xde)
	exts	xwa
	divs	wa, 2
	ld	bc, (xde)
	add	bc, wa
	lda	xhl, (xsp+12)
	ld	(xhl), bc
	ld	bc, (xde+2)
	ld	wa, (xde+6)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	inc	1, bc
	ld	(xhl+2), bc
	pushw 237
	pushw 5142
	lda	xwa, (xsp+28)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+16)
	lda	xbc, (xsp+12)
	lda	xde, (xsp+24)
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	247
PmExpFilter_DrawCentered:
	call DrawStringCentered
	jrl SeqLoad_ReturnZeroJmp
AcPmExpFilterGridBoxProc_Evt1C00017:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	cp (0x0340e2:24), 0x02
	jr nz, PmExpFilter_DecAndUpdate
	cp hl, 2:i3
	jr nz, PmExpFilter_DecAndUpdate
	ld (0x0340e2:24), 0x01
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jrl z, SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call ApFuncCall
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld XDE, (xsp + 0x0120)
	call SetDialDown
	ld wa, 1:i3
	jrl PmExpFilter_SetDialEnable
AcPmExpFilterGridBoxProc_Evt1C00018:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward2
	ld xwa, xiz
	ld xbc, 0x1e0008f
	ld xde, 0:i3
	call SendEvent
	ld a, (0x0340e2:24)
	cp a, 2:i3
	jr nz, PmExpFilter_CheckAdvBank
	cp hl, 0xa
	jrl z, SeqLoad_ReturnZeroJmp

PmExpFilter_CheckAdvBank:
	cp a, 1:i3
	jr nz, PmExpFilter_IncAndUpdate
	cp hl, 0xa
	jr nz, PmExpFilter_IncAndUpdate
	ld (0x0340e2:24), 0x02
	ld xwa, xiz
	ld xbc, 0x1c0000f
	ld xde, 0:i3
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
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward2:
	ld xwa, xiz
	ld xbc, 0x1e00091
	ld XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jrl z, SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call ApFuncCall
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1c00017
	ld XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld XDE, (xsp + 0x0120)
	call SetDialDown
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+292)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	SeqLoad_ReturnZeroJmp
AcPmExpFilterGridBoxProc_Evt1C0001C:
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+292)
	ld	xde, (xsp+288)
	jr	PmExpFilter_ForwardApFunc
PmExpFilter_ForwardToView:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)

PmExpFilter_ForwardApFunc:
	call ApFuncCall

SeqLoad_ReturnZeroJmp:
	ld xhl, 0:i3
	jr PmExpFilter_Epilogue

PmExpFilter_OkHandler:
	ld XWA, (xsp + 0x0120)
	cp xwa, 0xf
	jr nz, PmExpFilter_OK_InheritedFwd
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	ld xde, 0:i3
	call SendEvent
	jr PmExpFilter_OK_InheritedFwd

PmExpFilter_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

PmExpFilter_OK_InheritedFwd:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)
	jr PmExpFilter_CallInherited

PmExpFilter_DefaultInherited:
	ld xwa, xiz
	ld XBC, (xsp + 0x0124)
	ld XDE, (xsp + 0x0120)

PmExpFilter_CallInherited:
	call InheritedProc

PmExpFilter_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x24, 0x01
	ret

PmExpFilterGridCheck:
	lda_dri XSP, 0xfd, 0xf8, 0xfe
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
	lda xix, (PmExpFilter_EventDispatch:24)
; Computed jump: target = PmExpFilter_EventDispatch + ParamStr02_Vocalist_0xBE[i], ParamStr02_Vocalist_0xBE = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> PmExpFilter_EventDispatch
;   0x1c00018 -> PmExpFilterGridCheck_Evt1C00018
;   0x1c00019 -> PmExpFilter_EventDispatch
;   0x1c0001a -> PmExpFilterGridCheck_Evt1C00018
;   0x1c0001b -> SeqLoad_StoreReturnZero
;   0x1c0001c -> PmExpFilterGridCheck_Evt1C0001C
;   0x1c0001d -> PmExpFilterGridCheck_Evt1C0001C
	jp_ind 8, 0x07, 0xf0, 0xe0

; PmExpFilterGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed149a)
PmExpFilter_EventDispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 147 of 182 slots byte-identical
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xwa, 0xfd, 0x00, 0x01
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jrl	nz, SeqLoad_StoreReturnZero
	ld	c, (213218:24)
	ld	wa, de
	sla	wa, 2
	dec	8, wa
	cp	c, 2:i3
	jr	z, PmExpFilterGridCheck_Skip
	cp	c, 1:i3
	jrl	nz, SeqLoad_StoreReturnZero
	cp	de, 2:i3
	jrl	lt, SeqLoad_StoreReturnZero
	cp	de, 10
	jrl	gt, SeqLoad_StoreReturnZero
	lda	xbc, (ParamStr02_Vocalist_0x52:24)
	ld_rrl	xwa, xbc, wa
	ldw	bc, 65535
	ld	de, 2:i3
	jrl	PmExpFilterGridCheck_Join
PmExpFilterGridCheck_Skip:
	cp	de, 2:i3
	jrl	lt, SeqLoad_StoreReturnZero
	cp	de, 10
	jrl	gt, SeqLoad_StoreReturnZero
	lda	xbc, (ParamStr02_Vocalist_0x76:24)
	ld_rrl	xwa, xbc, wa
	ldw	bc, 65535
	ld	de, 2:i3
	jr	PmExpFilterGridCheck_Join
PmExpFilterGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xbc, 0xfd, 0x00, 0x01
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xbc), wa
	ld	(xbc+2), de
	ld	wa, de
	sla	wa, 2
	dec	8, wa
	cpw	(xbc), 1
	jrl	nz, SeqLoad_StoreReturnZero
	ld	c, (213218:24)
	cp	c, 2:i3
	jr	z, PmExpFilterGridCheck_Skip2
	cp	c, 1:i3
	jrl	nz, SeqLoad_StoreReturnZero
	cp	de, 2:i3
	jrl	lt, SeqLoad_StoreReturnZero
	cp	de, 10
	jrl	gt, SeqLoad_StoreReturnZero
	lda	xbc, (ParamStr02_Vocalist_0x52:24)
	ld_rrl	xwa, xbc, wa
	ld	bc, 1:i3
	ld	de, 2:i3
	jr	PmExpFilterGridCheck_Join
PmExpFilterGridCheck_Skip2:
	cp	de, 2:i3
	jrl	lt, SeqLoad_StoreReturnZero
	cp	de, 10
	jrl	gt, SeqLoad_StoreReturnZero
	lda	xbc, (ParamStr02_Vocalist_0x76:24)
	ld_rrl	xwa, xbc, wa
	ld	bc, 1:i3
	ld	de, 2:i3
PmExpFilterGridCheck_Join:
	call	MainLswAdd
	jrl	SeqLoad_StoreReturnZero
PmExpFilterGridCheck_Evt1C0001C:
	ld	a, (213218:24)
	cp	a, 2:i3
	jr	z, PmExpFilterGridCheck_Skip5
	cp	a, 1:i3
	jrl	nz, SeqLoad_StoreReturnZero
	ld	l, 0:opc
	lda	xix, (ParamStr02_Vocalist_0x52:24)
	ld	xwa, (xde)
PmExpFilterGridCheck_Loop:
	ld	c, l
	extz	bc
	sla	bc, 2
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpl_sri_rm	xwa, 0x07, 0xf0, 0xe4
	jr	nz, PmExpFilterGridCheck_Skip4
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xbc, 0xfd, 0x00, 0x01
	ldw	(xbc), 1
	inc	2, l
	extz	hl
	ld	(xbc+2), hl
	lda	xhl, (xsp)
	ld	(xbc+4), xhl
	ld	xwa, ParamStr02_Vocalist_0x9E
	cpw	(xde+4), 0
	jr	z, PmExpFilterGridCheck_Skip3
	ld	xwa, ParamStr02_Vocalist_0x9A
PmExpFilterGridCheck_Skip3:
	push	xwa
	push	xhl
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xde, 0xfd, 0x00, 0x01
	ld	xbc, 0x1e0008c
	jrl	PmExpFilterCheck_DoSend
PmExpFilterGridCheck_Skip4:
	inc	1, l
	cp	l, 9
	jr	c, PmExpFilterGridCheck_Loop
	jrl	SeqLoad_StoreReturnZero
PmExpFilterGridCheck_Skip5:
	ld	l, 0:opc
	lda	xix, (ParamStr02_Vocalist_0x76:24)
	ld	xwa, (xde)
PmExpFilterGridCheck_Loop2:
	ld	c, l
	extz	bc
	sla	bc, 2
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	cpl_sri_rm	xwa, 0x07, 0xf0, 0xe4
	jr	nz, PmExpFilterGridCheck_Skip7
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xbc, 0xfd, 0x00, 0x01
	ldw	(xbc), 1
	inc	2, l
	extz	hl
	ld	(xbc+2), hl
	lda	xhl, (xsp)
	ld	(xbc+4), xhl
	ld	xwa, ParamStr02_Vocalist_0xA6
	cpw	(xde+4), 0
	jr	z, PmExpFilterGridCheck_Skip6
	ld	xwa, ParamStr02_Vocalist_0xA2
PmExpFilterGridCheck_Skip6:
	push	xwa
	push	xhl
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	; v10 does not spell this byte either
	lda_dri	xde, 0xfd, 0x00, 0x01
	ld	xbc, 0x1e0008c
	jrl	PmExpFilterCheck_DoSend
PmExpFilterGridCheck_Skip7:
	inc	1, l
	cp	l, 9
	jr	c, PmExpFilterGridCheck_Loop2
	jrl	SeqLoad_StoreReturnZero
PmExpFilterCheck_CellDecode:
	lda_dri	xhl, 0xfd, 0x00, 0x01	; lda xhl, xsp+0x0100
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xhl), wa
	lda	xbc, (xhl+2)
	ld	wa, de
	ld	(xbc), wa
	lda	xde, (xsp)
	ld	(xhl+4), xde
	ld	wa, (xbc)
	ld	bc, wa
	sla	bc, 2
	cpw	(xhl), 1
	jrl	nz, SeqLoad_StoreReturnZero
	ld	l, (0x0340e2:24)
	dec	8, bc
	cp	l, 2:i3
	jr	z, PmExpFilterCheck_AltDecode
	cp	l, 1:i3
	jrl	nz, SeqLoad_StoreReturnZero
	cp	wa, 2:i3
	jrl	lt, SeqLoad_StoreReturnZero
	cp	wa, 10
	jrl	gt, SeqLoad_StoreReturnZero
	lda	xwa, (ParamStr02_Vocalist_0x52:24)
	ld_rrl	xwa, xwa, bc	; ld xwa, (xwa+bc)
	call	AcApcToggleProc_Helper
	ld	xwa, ParamStr02_Vocalist_0xAE
	cp	hl, 0:i3
	jr	nz, PmExpFilterCheck_SendNameA
	ld	xwa, ParamStr02_Vocalist_0xAA
PmExpFilterCheck_SendNameA:
	push	xwa
	lda	xwa, (xsp+4)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda_dri	xde, 0xfd, 0x00, 0x01	; lda xde, xsp+0x0100
	ld	xbc, 0x1e0008c
	jr	PmExpFilterCheck_DoSend
PmExpFilterCheck_AltDecode:
	cp	wa, 2:i3
	jr	lt, PmExpFilterCheck_PushDefault	; -> 0xFBBC1E
	cp	wa, 10
	jr	gt, PmExpFilterCheck_PushDefault	; -> 0xFBBC1E
	lda	xwa, (15537234:24)
	ld_rrl	xwa, xwa, bc
	call	AcApcToggleProc_Helper
	lda	xbc, (xsp)
	ld	xwa, 15537298
	cp	hl, 0:i3
	jr	nz, PmExpFilterCheck_PushNameB	; -> 0xFBBC1A
	ld	xwa, 15537294
PmExpFilterCheck_PushNameB:
	push xwa
	push xbc
	jr PmExpFilterCheck_StrcpySend

PmExpFilterCheck_PushDefault:
	pushw 0xed
	pushw 0x1496
	push xde

PmExpFilterCheck_StrcpySend:
	call	Free_Compare2

	inc 8, xsp

	call	GetFocusObject

	ld xwa, xhl

	lda_dri XDE, 0xfd, 0x00, 0x01

	ld xbc, 0x1e0008c



PmExpFilterCheck_DoSend:
	call SendEvent

SeqLoad_StoreReturnZero:
	ld xhl, 0:i3
	lda_dri XSP, 0xfd, 0x08, 0x01
	ret

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
	lda xix, (PmExpFilter2_EventDispatch:24)
; Computed jump: target = PmExpFilter2_EventDispatch + ParamStr02_Vocalist_0xCC[i], ParamStr02_Vocalist_0xCC = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> AcDispTimeSetGridBoxProc_Evt1C00017
;   0x1c00018 -> AcDispTimeSetGridBoxProc_Evt1C00018
;   0x1c00019 -> AcDispTimeSetGridBoxProc_Evt1C00017
;   0x1c0001a -> AcDispTimeSetGridBoxProc_Evt1C00018
;   0x1c0001b -> DispTimeSet_DefaultInherited
;   0x1c0001c -> AcDispTimeSetGridBoxProc_Evt1C0001C
;   0x1c0001d -> AcDispTimeSetGridBoxProc_Evt1C0001C
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
	ld xde, 0:i3
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
	ld wa, 1:i3
	jrl DispTimeSet_SetDialEnabled

DispTimeSet_SelectInit:
	ld	xwa, xiz
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	call	InheritedProc
	ld	xwa, (xsp+12)
	or	xwa, xwa
	jrl	nz, SeqSave_ReturnZeroJmp
	ld	wa, 5:i3
	call	PanelDisplay_DispatchByMode
	cp	hl, 0:i3
	jrl	z, SeqSave_ReturnZeroJmp
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	PostEvent
	ld	(32422:16), 72
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	PostEvent
	ld	xwa, 21102606
	ld	xbc, 31588373
	ld	xde, (xsp+12)
	call	MainFuncCall
	jrl	SeqSave_ReturnZeroJmp
AcDispTimeSetGridBoxProc_Evt1C00017:
	ld	xwa, xiz
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	call	InheritedProc
	ld	xwa, xiz
	ld	xbc, 31457360
	ld	xde, (xsp+12)
	call	SendEvent
	or	xhl, xhl
	jr	z, DispTimeSet_DialFallback
	ld	xwa, xiz
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	dec	1, hl
	extz	xhl
	add	xhl, 4294901760
	ld	xwa, xiz
	ld	xbc, 29360142
	ld	xde, xhl
	call	SendEvent
	ld	xwa, xiz
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	call	SetAutoInc
	jrl	SeqSave_ReturnZeroJmp
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
	ld wa, 1:i3
	jrl DispTimeSet_SetDialEnabled
AcDispTimeSetGridBoxProc_Evt1C00018:
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
	ld xde, 0:i3
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
	ld wa, 1:i3

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
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	SeqSave_ReturnZeroJmp
AcDispTimeSetGridBoxProc_Evt1C0001C:
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	DispTimeSet_CallApFunc
DispTimeSet_CellSelectFwd:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

DispTimeSet_CallApFunc:
	call ApFuncCall

SeqSave_ReturnZeroJmp:
	ld xhl, 0:i3
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
	lda xix, (DispTimeSet_EventDispatch:24)
; Computed jump: target = DispTimeSet_EventDispatch + FadeTimeStr_Off_0x38[i], FadeTimeStr_Off_0x38 = 16-bit offsets (7 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1c00017:
;   0x1c00017 -> DispTimeSet_EventDispatch
;   0x1c00018 -> DispTimeSetGridCheck_Evt1C00018
;   0x1c00019 -> DispTimeSet_EventDispatch
;   0x1c0001a -> DispTimeSetGridCheck_Evt1C00018
;   0x1c0001b -> DispTimeSet_ReturnZero
;   0x1c0001c -> DispTimeSetGridCheck_Evt1C0001C
;   0x1c0001d -> DispTimeSetGridCheck_Evt1C0001C
	jp_ind 8, 0x07, 0xf0, 0xe0
DispTimeSet_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xwa, (xsp+40)
	ld	xbc, xde
	srl	xbc, 0
	ld	qbc, 0
	ld	(xwa), bc
	ld	(xwa+2), de
	cpw	(xwa), 1
	jr	nz, DispTimeSetGridCheck_Entry
	cp	de, 2:i3
	jr	nz, DispTimeSetGridCheck_Entry
	lda	xwa, (xsp+8)
	lda	xbc, (213222:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry:
	cpw	(xwa), 1
	jr	nz, DispTimeSetGridCheck_Entry2
	cp	de, 3:i3
	jr	nz, DispTimeSetGridCheck_Entry2
	lda	xwa, (xsp+8)
	lda	xbc, (213224:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry2:
	cpw	(xwa), 1
	jr	nz, DispTimeSetGridCheck_Entry3
	cp	de, 4:i3
	jr	nz, DispTimeSetGridCheck_Entry3
	lda	xwa, (xsp+8)
	lda	xbc, (213226:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 2:i3
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry3:
	cpw	(xwa), 1
	jr	nz, DispTimeSetGridCheck_Entry4
	cp	de, 5:i3
	jr	nz, DispTimeSetGridCheck_Entry4
	lda	xwa, (xsp+8)
	lda	xbc, (213228:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 1:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry4:
	cpw	(xwa), 1
	jr	nz, DispTimeSetGridCheck_Entry5
	cp	de, 6:i3
	jr	nz, DispTimeSetGridCheck_Entry5
	lda	xwa, (xsp+8)
	lda	xbc, (213230:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 1:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry5:
	cpw	(xwa), 1
	jrl	nz, DispTimeSet_ReturnZero
	cp	de, 7:i3
	jrl	nz, DispTimeSet_ReturnZero
	lda	xwa, (xsp+8)
	lda	xbc, (213232:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 1:i3
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 1:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Evt1C00018:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 31457423
	ld	xde, 0:i3
	call	SendEvent
	ld	xde, xhl
	lda	xiy, (xsp+40)
	ld	xwa, xde
	srl	xwa, 0
	ld	qwa, 0
	ld	(xiy), wa
	ld	iz, de
	ld	(xiy+2), iz
	cpw	(xiy), 1
	jr	nz, DispTimeSetGridCheck_Entry6
	cp	iz, 2:i3
	jr	nz, DispTimeSetGridCheck_Entry6
	lda	xwa, (xsp+8)
	lda	xbc, (213222:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry6:
	cpw	(xiy), 1
	jr	nz, DispTimeSetGridCheck_Entry7
	cp	iz, 3:i3
	jr	nz, DispTimeSetGridCheck_Entry7
	lda	xwa, (xsp+8)
	lda	xbc, (213224:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry7:
	cpw	(xiy), 1
	jr	nz, DispTimeSetGridCheck_Entry8
	cp	iz, 4:i3
	jr	nz, DispTimeSetGridCheck_Entry8
	lda	xwa, (xsp+8)
	lda	xbc, (213226:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	ld	xbc, 2:i3
	ld	(xwa+6), xbc
	ld	xbc, 0:i3
	ld	(xwa+10), xbc
	jrl	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry8:
	cpw	(xiy), 1
	jr	nz, DispTimeSetGridCheck_Skip
	cp	iz, 5:i3
	jr	nz, DispTimeSetGridCheck_Skip
	lda	xwa, (xsp+8)
	lda	xbc, (213228:24)
	ld	(xwa), xbc
	ldw	(xwa+4), 1
	ld	xbc, 4294967295
	ld	(xwa+14), xbc
	ld	xbc, 12
	ld	(xwa+6), xbc
	ld	xbc, 1:i3
	ld	(xwa+10), xbc
	jr	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Skip:
	lda	xwa, (xsp+8)
	lda	xbc, (xwa+4)
	lda	xhl, (xwa+6)
	lda	xde, (xwa+10)
	lda	xix, (xwa+14)
	cpw	(xiy), 1
	jr	nz, DispTimeSetGridCheck_Entry9
	cp	iz, 6:i3
	jr	nz, DispTimeSetGridCheck_Entry9
	lda	xiy, (213230:24)
	ld	(xwa), xiy
	ldw	(xbc), 1
	ld	xbc, 4294967295
	ld	(xix), xbc
	ld	xbc, 12
	ld	(xhl), xbc
	ld	xbc, 1:i3
	ld	(xde), xbc
	jr	DispTimeSetGridCheck_Join
DispTimeSetGridCheck_Entry9:
	cpw	(xiy), 1
	jrl	nz, DispTimeSet_ReturnZero
	cp	iz, 7:i3
	jrl	nz, DispTimeSet_ReturnZero
	lda	xiy, (213232:24)
	ld	(xwa), xiy
	ldw	(xbc), 1
	ld	xbc, 4294967295
	ld	(xix), xbc
	ld	xbc, 12
	ld	(xhl), xbc
	ld	xbc, 1:i3
	ld	(xde), xbc
DispTimeSetGridCheck_Join:
	call	MainRamAdd
	jrl	DispTimeSet_ReturnZero
DispTimeSetGridCheck_Evt1C0001C:
	lda	xwa, (213222:24)
	lda	xiy, (xde+14)
	cp	xwa, (xde)
	jr	nz, DispTimeSetGridCheck_Skip2
	lda	xwa, (xsp+40)
	ldw	(xwa), 1
	ldw	(xwa+2), 2
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, 15537334
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw 237
	pushw 5458
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetGridCheck_Skip2:
	lda	xwa, (213224:24)
	cp	xwa, (xde)
	jr	nz, DispTimeSetGridCheck_Skip3
	lda	xwa, (xsp+40)
	ldw	(xwa), 1
	ldw	(xwa+2), 3
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, 15537334
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw 237
	pushw 5462
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetGridCheck_Skip3:
	lda	xbc, (213226:24)
	lda	xwa, (15537334:24)
	ld	(xsp+4), xwa
	cp	xbc, (xde)
	jr	nz, DispTimeSetGridCheck_Skip4
	lda	xwa, (xsp+40)
	ldw	(xwa), 1
	ldw	(xwa+2), 4
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, (xsp+4)
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw 237
	pushw 5466
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetGridCheck_Skip4:
	lda	xwa, (213228:24)
	cp	xwa, (xde)
	jr	nz, DispTimeSetGridCheck_Skip5
	lda	xwa, (xsp+40)
	ldw	(xwa), 1
	ldw	(xwa+2), 5
	lda	xbc, (xsp+30)
	ld	(xwa+4), xbc
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xde, (xsp+4)
	add	xde, xwa
	ld	xwa, (xde)
	push	xwa
	pushw 237
	pushw 5470
	push	xbc
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetGridCheck_Skip5:
	lda	xiz, (213230:24)
	lda	xhl, (xsp+40)
	lda	xix, (xsp+30)
	lda	xwa, (xhl+2)
	lda	xbc, (xhl+4)
	cp	xiz, (xde)
	jr	nz, DispTimeSetGridCheck_Skip6
	ldw	(xhl), 1
	ldw	(xwa), 6
	ld	(xbc), xix
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	pushw 237
	pushw 5474
	push	xix
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetGridCheck_Skip6:
	lda	xiz, (213232:24)
	cp	xiz, (xde)
	jrl	nz, DispTimeSet_ReturnZero
	ldw	(xhl), 1
	ldw	(xwa), 7
	ld	(xbc), xix
	ld	xwa, (xiy)
	sll	xwa, 2
	ld	xbc, (xsp+4)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	pushw 237
	pushw 5478
	push	xix
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, 31457420
	jrl	DispTimeSet_SendEventReturn
DispTimeSetCheck_CellDecode:
	lda xhl, (xsp + 0x28)
	ld XWA,XDE
	srl XWA, 0x00
	ld QWA,0
	ld (XHL),WA
	lda xwa, (xhl + 0x02)
	ld (XWA),DE
	lda xbc, (xsp + 0x1e)
	ld (XHL+0x04),XBC
	cpw (XHL), 0x0001
	jr nz, .Lc_fbc3fb
	cpw (XWA), 0x0002
	jr nz, .Lc_fbc3fb
	ld a, (0x0340e6:24)
	extz WA
	sla WA, 0x02
	lda xde, (ParamStr_Table_03:24)
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x156a
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
	jrl t, DispTimeSet_SendEventReturn
DispTimeSetCheck_TryRow3:
.Lc_fbc3fb:
	lda xde, (ParamStr_Table_03:24)
	cpw (XHL), 0x0001
	jr nz, .Lc_fbc43b
	cpw (XWA), 0x0003
	jr nz, .Lc_fbc43b
	ld a, (0x0340e8:24)
	extz WA
	sla WA, 0x02
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x156e
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
	jrl t, DispTimeSet_SendEventReturn
DispTimeSetCheck_TryRow4:
.Lc_fbc43b:
	cpw (XHL), 0x0001
	jr nz, .Lc_fbc476
	cpw (XWA), 0x0004
	jr nz, .Lc_fbc476
	ld a, (0x0340ea:24)
	extz WA
	sla WA, 0x02
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x1572
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
	jrl t, DispTimeSet_SendEventReturn
DispTimeSetCheck_TryRow5:
.Lc_fbc476:
	cpw (XHL), 0x0001
	jr nz, .Lc_fbc4b0
	cpw (XWA), 0x0005
	jr nz, .Lc_fbc4b0
	ld a, (0x0340ec:24)
	extz WA
	sla WA, 0x02
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x1576
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
	jr t, DispTimeSet_SendEventReturn
DispTimeSetCheck_TryRow6:
.Lc_fbc4b0:
	cpw (XHL), 0x0001
	jr nz, .Lc_fbc4ea
	cpw (XWA), 0x0006
	jr nz, .Lc_fbc4ea
	ld a, (0x0340ee:24)
	extz WA
	sla WA, 0x02
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x157a
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
	jr t, DispTimeSet_SendEventReturn
DispTimeSetCheck_TryRow7:
.Lc_fbc4ea:
	cpw (XHL), 0x0001
	jr nz, DispTimeSet_ReturnZero
	cpw (XWA), 0x0007
	jr nz, DispTimeSet_ReturnZero
	ld a, (0x0340f0:24)
	extz WA
	sla WA, 0x02
	ldl_dri xwa, 0x07, 0xe8, 0xe0
	push XWA
	pushw 0x00ed
	pushw 0x157e
	push XBC
	call Scoop_EventLoop_12Entry_Helper
	lda xsp, (xsp + 0x0c)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,0x01e0008c
DispTimeSet_SendEventReturn:
	call SendEvent

DispTimeSet_ReturnZero:
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	ret

MainTimeFlashFunc:
	cp	xbc, 31588373
	jr	z, MainTimeFlash_DispatchCmd
	cp	xbc, 31588372
	jr	nz, MainTimeFlash_ReturnZero
	ld	(32422:16), 40
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	ApPostEvent
	ld	wa, 5:i3
	call	CtrlPanel_IndicatorJumpTable
	ld	(32422:16), 35
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	ApPostEvent
	jr	MainTimeFlash_ReturnZero
MainTimeFlash_DispatchCmd:
	ld wa, 5:i3
	call Audio_DispatchCommand

MainTimeFlash_ReturnZero:
	ld xhl, 0:i3
	ret

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
	ld	xwa, xiz
	call	GetViewInstance
	cpib_da	(0x0340e6), 0
	jr	z, NormScreen_ClearBit
	ld	a, (36076:16)
	extz	wa
	bit	0, wa
	jr	z, NormScreen_ClearBit
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, 4294967295
	ld	xbc, 31457438
	ld	xde, 0:i3
	call	PostEvent
	ld	(32422:16), 36
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	PostEvent
	res	0, (0x8cec:16)
NormScreen_ClearBit:
	res	0, (0x8cec:16)	; resda 0, 0x8d88 (v7 patched)

	ld xwa, xiz

	ld xbc, (xsp + 8)

	ld xde, (xsp + 4)

	call	InheritedProc

	ld xhl, 0:i3



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
	ld	xwa, xiz
	ld	xde, (xsp+8)
	call	InheritedProc
	ld	xwa, xiz
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	lda	xbc, (xiz+22)
	ld	wa, 1:i3
	cp	hl, 1:i3
	jr	nz, IvWindowPgCtl_SetPageIndex
	ld	wa, 3:i3
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
	ld xde, 1:i3
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_Deselect:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	ld xde, 0:i3
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
	ld xde, 1:i3
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_DisableFunc:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	ld xde, 0:i3
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
	incw 1, (xwa)
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	ld xde, 1:i3
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	jr	IvWindowPgCtl_SendPageEvent

IvWindowPgCtl_TryNextPage:
	cpw	(xwa), 4
	jr	nz, IvWindowPgCtl_DisableAll
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+22)
	ld	wa, 1:i3
	cp	hl, 1:i3
	jr	nz, IvWindowPgCtl_SetNextPage
	ld	wa, 2:i3
IvWindowPgCtl_SetNextPage:
	ld xbc, (xbc)
	ld (xbc), wa
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	ld xde, 1:i3
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
	ld xde, 0:i3

UI_MainFuncCall_Execute:
	call MainFuncCall
	jr IvWindowPgCtl_ReturnZero

IvWindowPgCtl_JumpToEnd:
	ld XWA,0x000000c0
	call AcApcToggleProc_Helper
	cp hl, 1:i3
	jr nz, IvWindowPgCtl_JumpToStart
	ld XWA,(XSP+0x04)
	ld XWA,(XWA+0x16)
	cpw (XWA), 0x0003
	jr z, IvWindowPgCtl_ReturnZero
	ldw (XWA), 0x0003
	ld XWA,0x01400001
	ld XBC,0x01e000ab
	ld xde, 1:i3
	call MainFuncCall
	ld XWA,(XSP+0x04)
	ld XWA,(XWA+0x16)
	ld DE,(XWA)
	exts XDE
	ld XWA,0xffffffff
	ld XBC,0x01c0001e
	jr t, IvWindowPgCtl_DoSendEvent
IvWindowPgCtl_JumpToStart:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x1
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x1
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	ld xde, 1:i3
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
	ld xhl, 0:i3

IvWindowPgCtl_Epilogue:
	pop xiz
	inc 8, xsp
	ret

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
	ld xde, 0:i3
	jrl IvPageOverWr_SendAndReturn

IvPageOverWr_GetName:
	pushw	237
	pushw	5520
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	PmNamingCheck_CleanupRet
IvPageOverWr_PageSelect:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageSelect2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	ld xde, 0:i3
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
	ld xde, 0:i3
	jr IvPageOverWr_SendAndReturn

IvPageOverWr_PageChanged:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageChanged2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
	ld xde, 5:i3
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
	ld xde, 5:i3

IvPageOverWr_SendAndReturn:
	call SendEvent

PmNamingCheck_CleanupRet:
	ld xhl, 0:i3

IvPageOverWr_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

PmNamingCheck:
	lda	xsp, (xsp-22)
	push	xiz
	ld	(xsp+22), xde
	ld	xiz, xwa
	cp	xbc, 29360135
	jr	z, PmNaming_HandleKeyPress
	cp	xbc, 31457404
	jr	z, PmNaming_GetKeyLayout
	cp	xbc, 31457412
	jrl	z, PmBankNamingCheck_Ret
	cp	xbc, 31457338
	jrl	nz, PmBankNamingCheck_Ret
	ld	xwa, 768
	call	AcApcToggleProc_Helper
	extz	hl
	ld	wa, hl
	ld	xbc, (xsp+22)
	call	BitMapOut_UpdateDisplayWidget
	ld	xhl, xiz
	jrl	PmNaming_Epilogue
PmNaming_GetKeyLayout:
	ld xhl, 0x10
	jrl PmNaming_Epilogue

PmNaming_HandleKeyPress:
	ld	xwa, (xsp+22)
	cp	xwa, 11
	jr	nz, PmNaming_HandleF_Confirm
	ld	xwa, 768
	call	AcApcToggleProc_Helper
	cp	l, 0:i3
	jr	z, PmNaming_HandleF_Confirm
	call	GetNamingWindowID
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457338
	call	SendEvent
	ld	xwa, 768
	call	AcApcToggleProc_Helper
	extz	hl
	lda	xbc, (xsp+4)
	ld	wa, hl
	call	BitMapOut_UpdateWidget_TypeB
	call	GetNamingWindowID
	ld	xwa, xhl
	lda	xde, (xsp+4)
	ld	xbc, 31457338
	call	SendEvent
	lda	xwa, (xsp+4)
	push	xwa
	pushw	0
	pushw	63906
	call	Free_Compare2
	inc	8, xsp
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263185
	call	PostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457434
	ld	xde, 1:i3
	call	PostEvent
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
	ld xde, 1:i3
	call PostEvent

PmBankNamingCheck_Ret:
	ld xhl, 0:i3

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
	ld xde, 1:i3
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
	ld xde, 1:i3
	call PostEvent

MssNameFunc_CleanupRet:
	ld xhl, 0:i3

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
	lda xix, (MssName_EventDispatch:24)
; Computed jump: target = MssName_EventDispatch + FadeTimeStr_Off_0x62[i], FadeTimeStr_Off_0x62 = 16-bit offsets (10 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e0003e:
;   0x1e0003e -> MssNameFunc_Evt1E0003E
;   0x1e0003f -> MssNameFunc_Evt1E0003E
;   0x1e00040 -> MssName_ReturnZero
;   0x1e00041 -> MssName_ReturnZero
;   0x1e00042 -> MssName_ReturnZero
;   0x1e00043 -> MssNameFunc_Evt1E00043
;   0x1e00044 -> MssNameFunc_Evt1E0003E
;   0x1e00045 -> MssNameFunc_Evt1E00045
;   0x1e00046 -> MssNameFunc_Evt1E00046
;   0x1e00047 -> MssName_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4
; MssNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ac)
MssName_EventDispatch:
	ld	xiz, xde
	lda	xbc, (xiz+14)
	ld	xwa, (xbc)
	or	xwa, xwa
	jr	nz, MssNameFunc_Skip
	pushw	237
	pushw	5526
	ld	xwa, (xiz+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	MssNameFunc_Join2
MssNameFunc_Skip:
	dec	1, xwa
	cp	xwa, 800
	jr	le, MssNameFunc_Skip2
	ld	xwa, 2:i3
	ld	(xbc), xwa
MssNameFunc_Skip2:
	ld	xwa, (xbc)
	dec	1, xwa
	call	EffectMode_SearchPresetTableC0
	ld	xwa, (xiz+14)
	dec	1, xwa
	cp	xhl, 4294967295
	jr	z, MssNameFunc_Skip3
	pushw	16
	call	EffectMode_SearchPresetTableC0
	push	xhl
	ld	xwa, (xiz+18)
	push	xwa
	call	16712982
	pushw	2
	pushw	32
	ld	xwa, (xiz+18)
	lda	xwa, (xwa+16)
	push	xwa
	call	MssNameFunc_Helper2
	lda	xsp, (xsp+18)
	ld	xwa, 15537572
	jr	MssNameFunc_Join
MssNameFunc_Skip3:
	sll	xwa, 2
	add	xwa, 9990144
	ld	xbc, (xwa)
	ld	a, (xbc+42)
	extz	wa
	pushw	wa
	lda	xwa, (xbc+43)
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	16712982
	lda	xsp, (xsp+10)
	ld	xwa, 15537576
MssNameFunc_Join:
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	MssNameFunc_Helper
	inc	8, xsp
	ld	(xhl), 0
MssNameFunc_Join2:
	ld	xhl, (xsp+4)
	jr	MssNameFunc_Epilogue
MssNameFunc_Evt1E0003E:
	ld	xhl, 1:i3
	jr	MssNameFunc_Epilogue
MssNameFunc_Evt1E00043:
	ld	xhl, 512
	jr	MssNameFunc_Epilogue
MssNameFunc_Evt1E00045:
	lda	xhl, (36026:16)
	jr	MssNameFunc_Epilogue
MssNameFunc_Evt1E00046:
	ld	xhl, 2:i3
	jr	MssNameFunc_Epilogue
MssName_ReturnZero:
	ld xhl, 0:i3
MssNameFunc_Epilogue:
	pop xiz
	inc 4, xsp
	ret

AcPmBkNoBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
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
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcPmBkNoBox_Epilogue

AcPmBkNoBox_Init:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call SetLswFilter
	jrl UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_Focus:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call ResetLswFilter
	jr UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_ShowHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x300
	call MainLswGet
	jr UI_AcPmBkNoBoxProc_Return

AcPmBkNoBox_Match:
	ld	xwa, (xsp+260)
	ld	xde, xiz
	call	InheritedProc
	ld	xwa, (xiz)
	cp	xwa, 768
	jr	nz, UI_AcPmBkNoBoxProc_Return
	lda	xde, (xsp+4)
	ld	bc, (xiz+4)
	cp	bc, 0:i3
	jr	nz, AcPmBkNoBox_FormatBankNo
	pushw	237
	pushw	5568
	push	xde
	call	Free_Compare2
	inc	8, xsp
	jr	AcPmBkNoBox_SendConfirm
AcPmBkNoBox_FormatBankNo:
	dec	1, bc
	ld	wa, bc
	exts	xwa
	divs	wa, 8
	ld	wa, qwa
	inc	1, wa
	pushw	wa
	exts	xbc
	divs	bc, 8
	inc	1, bc
	pushw	bc
	pushw	237
	pushw	5578
	push	xde
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
AcPmBkNoBox_SendConfirm:
	lda xde, (xsp + 4)
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_AcPmBkNoBoxProc_Return:
	ld xhl, 0:i3

AcPmBkNoBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

AcBkNoBoxProc:
	lda_dri XSP, 0xfd, 0xfc, 0xfe
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
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jrl AcBkNoBox_Epilogue

AcBkNoBox_Init:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call SetLswFilter
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_Focus:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld XWA, (xsp + 0x0104)
	ld xbc, 0x300
	call ResetLswFilter
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_ShowHide:
	ld XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x300
	call MainLswGet
	jr UI_AcBkNoBoxProc_Return

AcBkNoBox_Match:
	ld	xwa, (xsp+260)
	ld	xde, xiz
	call	InheritedProc
	ld	xwa, (xiz)
	cp	xwa, 768
	jr	nz, UI_AcBkNoBoxProc_Return
	call	BitMapOut_PrepareRender_CheckBit1
	inc	1, l
	extz	hl
	pushw	hl
	pushw	237
	pushw	5586
	lda	xwa, (xsp+10)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, (xsp+260)
	ld	xbc, 29360143
	call	SendEvent
UI_AcBkNoBoxProc_Return:
	ld xhl, 0:i3

AcBkNoBox_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x04, 0x01
	ret

MsaModeScreenProc:
	lda	xsp, (xsp-24)
	push	xiz
	ld	(xsp+20), xde
	ld	xiz, xbc
	ld	(xsp+24), xwa
	cp	xiz, 29360135
	jrl	z, MsaMode_OK
	cp	xiz, 29360142
	jrl	z, MsaMode_Select
	cp	xiz, 29360141
	jrl	z, MsaMode_Paint
	cp	xiz, 29360156
	jr	z, MsaMode_Match
	cp	xiz, 29360139
	jr	z, MsaMode_Show
	cp	xiz, 29360129
	jrl	nz, MsaMode_Default
	ld	xwa, (xsp+20)
	cp	xwa, 4
	jr	z, MsaMode_Init_Forward
	cp	xwa, 3
	jr	nz, MsaMode_Init_Forward
	ld	xwa, 1024
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, MsaMode_Init_Forward
	ld	xwa, 1024
	ld	bc, 1:i3
	ld	de, 3:i3
	call	MainLswPut
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
	ld xde, 0:i3
	jr MsaMode_DispatchSelect

MsaMode_Paint:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	ld xbc, 0x1c0000e
	ld xde, 0:i3

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
	lda xbc, (NakaInst_Rock_Pop_0x2C:24)
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
	ld bc, 1:i3
	ld de, 2:i3
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	lda xbc, (NakaInst_Rock_Pop_0x2C:24)
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
	ld bc, 1:i3
	ld de, 2:i3
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
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, MsaMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	ld xde, 0:i3
	call SendEvent
	jr MsaMode_ReturnZero

MsaMode_OK_Cmd89:
	ld xwa, 0x401
	ld bc, 1:i3
	ld de, 1:i3
	jr MsaMode_OK_ModeChange

MsaMode_OK_Cmd8A:
	ld xwa, 0x401
	ld bc, 2:i3
	ld de, 1:i3
	jr MsaMode_OK_ModeChange

MsaMode_OK_Cmd8B:
	ld xwa, 0x401
	ld bc, 3:i3
	ld de, 1:i3

MsaMode_OK_ModeChange:
	call MainLswPut
	jr MsaMode_ReturnZero

MsaMode_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

MsaMode_ReturnZero:
	ld xhl, 0:i3
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

PmemModeBoxProc:
	lda_dri XSP, 0xfd, 0xe8, 0xfe
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
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	jrl PmemMode_ReturnZero

PmemMode_Show:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld xwa, 0x302
	call MainLswGet
	jrl PmemMode_ReturnZero

PmemMode_Match:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld XIX, (xsp + 0x0114)
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
	ld XWA, (xsp + 0x0118)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	jrl PmemMode_DispatchSelect

PmemMode_Paint:
	ld XWA, (xsp + 0x0118)

	ld xbc, xiz

	ld XDE, (xsp + 0x0114)

	call	InheritedProc	; call InheritedProc (v7 addr)

	lda_dri XWA, 0xfd, 0x0c, 0x01

	ldw (xwa + 2), 0x6

	ldw (xwa + 6), 0x17

	ldw (xwa), 0xf5

	ldw (xwa + 4), 0x13b

	ldw bc, 0xc1

	ldw de, 0xf3

	call	DrawDesignBox

	lda_dri XDE, 0xfd, 0x0c, 0x01

	ld wa, (xde + 4)

	sub wa, (xde)

	exts xwa

	divs wa, 0x2

	ld bc, (xde)

	add bc, wa

	lda_dri XHL, 0xfd, 0x08, 0x01

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

	call	Free_Compare2

	inc 8, xsp

	lda_dri XWA, 0xfd, 0x0c, 0x01

	lda_dri XBC, 0xfd, 0x08, 0x01

	lda xde, (xsp + 8)

	ld xhl, 0:i3

	push xhl

	pushw 0x0

	pushw 0xf7

	call	DrawStringCentered

	ld XWA, (xsp + 0x0118)

	ld xbc, 0x1c0000e

	ld xde, 0:i3



PmemMode_DispatchSelect:
	call SendEvent
	jrl PmemMode_ReturnZero

PmemMode_Select:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 40)
	lda xbc, (NakaInst_Rock_Pop_0x30:24)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_dri XBC, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
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
	ld bc, 1:i3
	ld de, 2:i3
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 36)
	lda xbc, (NakaInst_Rock_Pop_0x30:24)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	lda_dri XBC, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x0c, 0x01
	lda_dri XHL, 0xfd, 0x08, 0x01
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
	ld bc, 1:i3
	ld de, 2:i3
	call DrawDesignFrame
	jr PmemMode_ReturnZero

PmemMode_OK:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	call InheritedProc
	ld XWA, (xsp + 0x0118)
	call GetViewInstance
	ld XWA, (xsp + 0x0114)
	cp xwa, 0x8b
	jr z, PmemMode_OK_Cmd8B
	cp xwa, 0x89
	jr z, PmemMode_OK_Cmd89
	cp xwa, 0xf
	jr nz, PmemMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	ld xde, 0:i3
	call SendEvent
	or xhl, xhl
	jr z, PmemMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	ld xde, 0:i3
	call SendEvent
	jr PmemMode_OK_DefaultForward

PmemMode_OK_Cmd89:
	ld xwa, 0x302
	ld bc, 0:i3
	ld de, 1:i3
	jr PmemMode_OK_ModeChange

PmemMode_OK_Cmd8B:
	ld xwa, 0x302
	ld bc, 1:i3
	ld de, 1:i3

PmemMode_OK_ModeChange:
	call MainLswPut

PmemMode_ReturnZero:
	ld xhl, 0:i3
	jr PmemMode_Epilogue

PmemMode_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
	call PostEvent

PmemMode_OK_DefaultForward:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)
	jr PmemMode_CallHandler

PmemMode_Default:
	ld XWA, (xsp + 0x0118)
	ld xbc, xiz
	ld XDE, (xsp + 0x0114)

PmemMode_CallHandler:
	call InheritedProc

PmemMode_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x18, 0x01
	ret

AcPmBkEditBoxProc:
	lda_dri XSP, 0xfd, 0xce, 0xfe
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
	ld XWA, (xsp + 0x012e)
	ld (xwa), 0x0
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xwa, (xhl + 54)
	ld xwa, (xwa)
	ld w, 0x0:opc
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld XDE, (xsp + 0x012e)
	call MainFuncCall
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankChanged:
	ld XWA, (xsp + 0x012e)

	ld (xsp + 4), xwa

	ld a, (xwa)

	inc 1, a

	extz wa

	pushw wa

	pushw 0xed

	pushw 0x15e0

	ld xwa, (xsp + 14)

	push xwa

	call	Scoop_EventLoop_12Entry_Helper

	ld XWA, (xsp + 0x0138)

	inc 1, xwa

	push xwa

	lda xwa, (xsp + 60)

	push xwa

	call	FileIO_CheckPathAndVolumeLabel_Helper

	lda xsp, (xsp + 18)

	lda xde, (xsp + 46)

	ld XWA, (xsp + 0x0132)

	ld xbc, 0x1c0000f

	call	SendEvent

	ldib_erp 0xfb, 1



AcPmBkEdit_BankChanged_UpdateLoop:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	sll a, 3
	addb_erp A, 0xfb
	ld w, 0x0:opc
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20012
	ld XDE, (xsp + 0x012e)
	call MainFuncCall
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, AcPmBkEdit_BankChanged_UpdateLoop
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankEdit:
	lda xbc, (xsp + 0x0c)
	ldw (XBC), 0x0023
	ld XDE,(XSP+0x012e)
	ld A,(XDE)
	dec 1,A
	and A,0x07
	mul A,0x11
	add A,0x5a
	extz WA
	ld (XBC+0x02),WA
	lda xwa, (xsp + 0x10)
	ldw (XWA+0x02), 0x0055
	ldw (XWA+0x06), 0x00eb
	ldw (XWA), 0x0022
	ldw (XWA+0x04), 0x012c
	ld A,(XDE)
	dec 1,A
	and A,0x07
	inc 1,A
	extz WA
	pushw wa
	pushw 0x00ed
	pushw 0x15ea
	ld XWA,(XSP+0x0e)
	push XWA
	call Scoop_EventLoop_12Entry_Helper
	ld XWA,(XSP+0x0138)
	inc 2,XWA
	push XWA
	lda xwa, (xsp + 0x3c)
	push XWA
	call FileIO_CheckPathAndVolumeLabel_Helper
	lda xsp, (xsp + 0x12)
	lda xhl, (xsp + 0x2e)
	lda xwa, (xsp + 0x10)
	lda xde, (xsp + 0x0c)
	ld XIX,(XSP+0x012e)
	ld C,(XIX+0x01)
	cp C,(XIX)
	jr nz, AcPmBkEdit_BankEdit_DrawDiff
	ld xbc, 0:i3
	push XBC
	pushw 0x0009
	pushw 0x00f5
	ld XBC,XDE
	ld XDE,XHL
	jr t, AcPmBkEdit_BankEdit_DrawCall
AcPmBkEdit_BankEdit_DrawDiff:
	ld xbc, 0:i3
	push xbc
	pushw 0xff
	pushw 0xf5
	ld xbc, xde
	ld xde, xhl

AcPmBkEdit_BankEdit_DrawCall:
	call DrawStringLeftJustify
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_SetValue:
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00045
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 10), xhl
	call MainRamPut
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_AddDelta:
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00045
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 10), xhl
	call MainRamAdd
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_ShowHide:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00045
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00046
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 8)
	ld bc, hl
	call MainRamGet
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_Assign:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00045
	ld xde, 0:i3
	call ApFuncCall
	ld XDE, (xsp + 0x012e)
	ld xwa, (xde)
	cp xwa, xhl
	jrl nz, AcPmBkEdit_ReturnZero
	ld xbc, (xiz + 54)
	ld xwa, (xde + 14)
	ld (xbc), xwa
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1c0000f
	ld xde, 0:i3
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_AutoIncUp:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollUp:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollDown:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	ld xde, xhl
	jr AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_AutoIncDown:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	ld xde, 0:i3
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	ld xde, xhl

AcPmBkEdit_DispatchAndReturn:
	call SendEvent
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_OK:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc
	ld XWA, (xsp + 0x0132)
	call GetViewInstance
	ld XWA, (xsp + 0x012e)
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
	ld xde, 1:i3
	jrl AcPmBkEdit_OK_NavComplete

AcPmBkEdit_OK_Load:
	ld	xwa, 768
	call	AcApcToggleProc_Helper
	cp	l, 0:i3
	jr	z, AcPmBkEdit_OK_LoadEmpty
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263186
	call	PostEvent
	ld	xwa, 4294967295
	ld	xbc, 31457434
	ld	xde, 1:i3
	call	PostEvent
	jr	AcPmBkEdit_ReturnZero
AcPmBkEdit_OK_LoadEmpty:
	ld	(32422:16), 73
	ld	xwa, 4294967295
	ld	xbc, 29360150
	ld	xde, 27263214
	call	ApPostEvent
	jr	AcPmBkEdit_ReturnZero
AcPmBkEdit_OK_SaveDelete:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d0
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	ld xde, 0:i3
	call SendEvent
	cp hl, 0:i3
	jr z, AcPmBkEdit_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
	ld xde, 1:i3

AcPmBkEdit_OK_NavComplete:
	call PostEvent

AcPmBkEdit_ReturnZero:
	ld xhl, 0:i3
	jr AcPmBkEdit_Epilogue

AcPmBkEdit_Default:
	ld XWA, (xsp + 0x0132)
	ld XDE, (xsp + 0x012e)
	call InheritedProc

AcPmBkEdit_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x32, 0x01
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
	lda xix, (PmBkName_EventDispatch:24)
; Computed jump: target = PmBkName_EventDispatch + FadeTimeStr_Off_0xA4[i], FadeTimeStr_Off_0xA4 = 16-bit offsets (10 words, read
;   from the ROM by scripts/analysis/lane_uiproc_dispatch_tables.py); i = event - 0x1e0003e:
;   0x1e0003e -> PmBkNameFunc_Evt1E0003E
;   0x1e0003f -> PmBkNameFunc_Evt1E0003E
;   0x1e00040 -> PmBkName_ReturnZero
;   0x1e00041 -> PmBkName_ReturnZero
;   0x1e00042 -> PmBkName_ReturnZero
;   0x1e00043 -> PmBkNameFunc_Evt1E00043
;   0x1e00044 -> PmBkName_ReturnZero
;   0x1e00045 -> PmBkName_DataBytes
;   0x1e00046 -> PmBkNameFunc_Evt1E0003E
;   0x1e00047 -> PmBkName_EventDispatch
	jp_ind 8, 0x07, 0xf0, 0xe4
; PmBkNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ee)
PmBkName_EventDispatch:
	ret
PmBkNameFunc_Evt1E0003E:
	ld	xhl, 1:i3
	ret
PmBkNameFunc_Evt1E00043:
	ld	xhl, 9
	ret

PmBkName_ReturnZero:
	ld xhl, 0:i3
	ret

PmBkName_DataBytes:
	lda	xhl, (36012:16)
	ret
GmOnOffFunc:
	lda	xsp, (xsp-12)
	push	xiz
	ld	xiz, xwa
	cp	xbc, 0x1e00083
	jr	z, GmOnOff_GetBoundsRect
	cp	xbc, 0x1e0003f
	jrl	z, GmOnOff_DefaultReturn
	cp	xbc, 0x1e0003e
	jr	z, GmOnOff_Return1
	cp	xbc, 0x1e00041
	jr	z, GmOnOff_Return1
	cp	xbc, 0x1e00040
	jr	z, GmOnOff_Return0xC0
	cp	xbc, 0x1e00042
	jrl	nz, GmOnOff_DefaultReturn
	pushw	(xde+4)
	pushw	237
	pushw	5634
	ld	xwa, (xde+8)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jrl	VariScreen_CleanupRet
GmOnOff_Return0xC0:
	ld xhl, 0xc0
	jrl VariScreen_CleanupRet

GmOnOff_Return1:
	ld xhl, 1:i3
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
	ld xde, 3:i3
	jr GmOnOff_SendAndReturn

GmOnOff_CheckDesign:
	ld	c, (36004:16)
	or	c, (36006:16)
	or	c, (36008:16)
	jr	nz, GmOnOff_SendHideEvent
	ldw	bc, 245
	call	DrawBox
GmOnOff_SendHideEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c20006
	ld xde, 1:i3

GmOnOff_SendAndReturn:
	call SendEvent

GmOnOff_DefaultReturn:
	ld xhl, 0:i3

VariScreen_CleanupRet:
	pop xiz
	lda xsp, (xsp + 12)
	ret

VariScreenProc:
	lda_dri XSP, 0xfd, 0xca, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x2e, 0x02
	stl_dri XBC, 0xfd, 0x32, 0x02
	stl_dri XWA, 0xfd, 0x36, 0x02
	ld XWA, (xsp + 0x0232)
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
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)
	jrl VariScreen_CallInherited

VariScreen_RefreshAfterInit:
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)
	call InheritedProc
	ld XWA, (xsp + 0x0236)
	call GetViewInstance
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000b
	ld xde, 0:i3
	jrl VariScreen_SendAndReturn

VariScreen_HandleShow:
	; framing ported from v10's source for the same label (same span length, statement for statement); 42 of 50 slots byte-identical
	ld	xwa, (xsp+566)
	call	GetViewInstance
	ld	(xsp+24), xhl
	ld	xwa, (xsp+24)
	ld	(xsp+4), xwa
	ld	a, (35998:16)
	extz	wa
	ld	bc, 0:i3
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+31), l
	ld	a, (35998:16)
	extz	wa
	ldw	bc, 32
	call	DkMdlyPly_CheckState_Helper
	lda	xwa, (xsp+28)
	ld	(xwa+4), l
	ld	(xwa+2), (35998)	; differs from v10 here and llvm-objdump cannot read it
	call	16703515
	ld	xhl, (xsp+24)
	ld	xde, (xhl+56)
	lda	xbc, (xsp+28)
	ld	a, (xbc)
	extz	wa
	ld	(xde), wa
	ld	xde, (xhl+60)
	ld	a, (xbc+1)
	extz	wa
	ld	(xde), wa
	ld	a, (xbc)
	extz	wa
	call	VariScreenProc_Helper
	ld	xde, (xsp+24)
	ld	xbc, (xde+52)
	extz	hl
	ld	(xbc), hl
	ld	xbc, (xde+48)
	ld	a, (xsp+30)
	extz	wa
	ld	(xbc), wa
	ld	xbc, (xde+44)
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 10
	inc	1, wa
	ld	(xbc), wa
	ld	xwa, (xsp+566)
	ld	xbc, (xsp+562)
	ld	xde, (xsp+558)
VariScreen_CallInherited:
	call InheritedProc
	jrl FileBrowser_ReturnZero

VariScreen_HandlePaint:
	ld XWA,(XSP+0x0236)
	ld XBC,(XSP+0x0232)
	ld XDE,(XSP+0x022e)
	call InheritedProc
	ld XWA,(XSP+0x0236)
	call GetViewInstance
	ld (XSP+0x18),XHL
	lda XHL,(XSP+0x0222)
	ldw (XHL), 0x0004
	lda xde, (xhl + 0x02)
	ldw (XDE), 0x0002
	lda XWA,(XSP+0x0226)
	ld BC,(XHL)
	dec 2,BC
	ld (XWA),BC
	ld BC,(XHL)
	add BC,0x0019
	ld (XWA+0x04),BC
	ld BC,(XDE)
	dec 2,BC
	ld (XWA+0x02),BC
	ld BC,(XDE)
	add BC,0x0019
	ld (XWA+0x06),BC
	ldw BC, 0x00c0
	ldw DE, 0x00f0
	call DrawDesignBox
	lda XWA,(XSP+0x0222)
	ld XBC,0x0000008c
	call DrawIcons
	lda XBC,(XSP+0x0222)
	ldw (XBC), 0x0023
	lda xhl, (xbc + 0x02)
	ldw (XHL), 0x0008
	lda XWA,(XSP+0x0226)
	ld DE,(XBC)
	ld (XWA),DE
	ld DE,(XBC)
	add DE,0x0064
	ld (XWA+0x04),DE
	ld DE,(XHL)
	ld (XWA+0x02),DE
	ld DE,(XHL)
	add DE,0x0032
	ld	(xwa+6), de
	ld	xde, 4:i3
	push	xde
	pushw	255
	pushw	247
	ld	xde, FadeTimeStr_Off_0xBA
	call	DrawString
	ld	a, (0x8c9e:16)
	extz	wa
	ld	bc, 0:i3
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+31), l
	ld	a, (0x8c9e:16)
	extz	wa
	ldw	bc, 32
	call	DkMdlyPly_CheckState_Helper
	lda	xwa, (xsp+28)
	ld	(xwa+4), l
	ld	(xwa+2), (35998)
	call	0xfee01b
	ld	a, (xsp+28)
	extz	wa
	lda	xbc, (xsp+290)
	call	0xfede39
	lda	xbc, (xsp+546)
	ldw	(xbc), 104
	lda	xhl, (xbc+2)
	ldw	(xhl), 12
	lda	xwa, (xsp+550)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 128
	ld	(xwa+4), de
	ld	de, (xhl)
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 15
	ld	(xwa+6), de
	lda	xde, (xsp+290)
	ld	xhl, 0:i3
	push	xhl
	pushw	251
	pushw	247
	call	DrawString
	lda	xbc, (xsp+546)
	ldw	(xbc), 144
	lda	xhl, (xbc+2)
	ldw	(xhl), 0
	lda	xwa, (xsp+550)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 56
	ld	(xwa+4), de
	ld	de, (xhl)
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 15
	ld	(xwa+6), de
	ld	xde, (xsp+24)
	ld	xde, (xde+48)
	ld	de, (xde)
	muls	de, 7
	lda	xhl, (NakaInst_MEMORY_A_ECFDF4_0xA:24)
	exts	xde
	add	xde, xhl
	ld	xhl, 0:i3
	push	xhl
	pushw	255
	pushw	247
	call	DrawString
	ld	xwa, (xsp+566)
	ld	xbc, 0x1c0000f
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, (xsp+566)
	ld	xbc, 0x1c0000e
	ld	xde, 0:i3
VariScreen_SendAndReturn:
	call SendEvent
	jrl FileBrowser_ReturnZero

VariScreen_HandleSelect:
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)
	call InheritedProc
	ld XWA, (xsp + 0x0236)
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
	lda xhl, (0x03f214:24)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x26, 0x02
	lda_dri XHL, 0xfd, 0x22, 0x02
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
	ldw	(xbc), 311

VariScreen_DrawDesignArea:
	ld	bc, 0:i3
	ldw	de, 245
	call	DrawDesignBox
	lda	xwa, (xsp+28)
	ld	xhl, (xsp+24)
	ld	xbc, (xhl+56)
	ld	bc, (xbc)
	ld	(xwa), c
	lda	xde, (xhl+64)
	ld	xbc, (xde)
	ld	bc, (xbc)
	ld	(xwa+1), c
	ld	xbc, (xhl+48)
	ld	bc, (xbc)
	ld	(xwa+2), c
	ld	xbc, (xde)
	ld	bc, (xbc)
	extz	bc
	div	c, 10
	ld	c, b
	ld	(xwa+3), c
	call	SeMenu_SetDisplayValue_Helper
	lda	xbc, (xsp+28)
	ld	a, (xbc+3)
	extz	wa
	ld	c, (xbc+4)
	extz	bc
	lda	xde, (xsp+290)
	call	Display_BytecodeBlock_F_Helper2
	ld	(xsp+306), 0
	ld	(xsp+8), 9
	ld	xwa, (xsp+24)
	ld	xde, (xwa+52)
	ld	xhl, (xwa+44)
	ld	bc, (xhl)
	muls	bc, 10
	ld	wa, bc
	dec	1, wa
	ld	ix, (xde)
	sub	ix, wa
	jr	ge, VariScreen_SetHighlightColors
	sub	wa, (xde)
	ldw	de, 9
	sub	de, wa
	ld	(xsp+8), e
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
	lda xde, (0x03f214:24)
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
	lda xde, (0x03f214:24)
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
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawDefaultVoice

VariScreen_DrawNameLabel:
	lda_dri XDE, 0xfd, 0x26, 0x02
	lda_dri XHL, 0xfd, 0x22, 0x02
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
	decw	8, (xbc)
	ld	xwa, (xsp+24)
	ld	xwa, (xwa+44)
	ld	bc, (xwa)
	muls	bc, 10
	sub	bc, 10
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+64)
	ld	wa, (xwa)
	extz	wa
	div	a, 10
	ld	a, w
	inc	1, a
	extz	wa
	add	wa, bc
	pushw	wa
	pushw 237
	pushw 5642
	lda	xwa, (xsp+40)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xhl, (xsp+550)
	lda	xbc, (xsp+546)
	lda	xde, (xsp+34)
	ld	xwa, 3:i3
	push	xwa
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	ld	a, (xsp+20)
	extz	wa
	pushw	wa
	ld	xwa, xhl
	call	DrawStringLeftJustify
	lda	xbc, (xsp+546)
	lda	xde, (xbc+2)
	ld	wa, (xde)
	add	wa, 12
	ld	(xde), wa
	lda	xhl, (xsp+550)
	sub	wa, 15
	ld	(xhl+2), wa
	ld	wa, (xde)
	add	wa, 16
	ld	(xhl+6), wa
	lda	xwa, (xhl+4)
	cpw	(xbc), 0
	jr	nz, VariScreen_SetRightVoiceBounds
	ldw	(xhl), 16
	ldw	(xwa), 156
	jr	VariScreen_DrawVoiceString
VariScreen_SetRightVoiceBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawVoiceString:
	lda_dri XDE, 0xfd, 0x22, 0x01
	ld xwa, 1:i3
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
	lda_dri XHL, 0xfd, 0x26, 0x02
	lda_dri XBC, 0xfd, 0x22, 0x02
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
	lda_dri XDE, 0xfd, 0x22, 0x01
	ld xwa, 1:i3
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
	lda xhl, (0x03f214:24)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	lda_dri XWA, 0xfd, 0x26, 0x02
	lda_dri XHL, 0xfd, 0x22, 0x02
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
	ldw	(xbc), 311

VariScreen_DrawRightDesignBox:
	ldw	bc, 193
	ld	de, 7:i3
	call	DrawDesignBox
	lda	xwa, (xsp+28)
	ld	xhl, (xsp+24)
	ld	xbc, (xhl+56)
	ld	bc, (xbc)
	ld	(xwa), c
	lda	xde, (xhl+60)
	ld	xbc, (xde)
	ld	bc, (xbc)
	ld	(xwa+1), c
	ld	xbc, (xhl+48)
	ld	bc, (xbc)
	ld	(xwa+2), c
	ld	xbc, (xde)
	ld	bc, (xbc)
	extz	bc
	div	c, 10
	ld	c, b
	ld	(xwa+3), c
	call	SeMenu_SetDisplayValue_Helper
	lda	xbc, (xsp+28)
	ld	a, (xbc+3)
	extz	wa
	ld	c, (xbc+4)
	extz	bc
	lda	xde, (xsp+290)
	call	Display_BytecodeBlock_F_Helper2
	ld	(xsp+306), 0
	ld	(xsp+8), 9
	ld	xwa, (xsp+24)
	ld	xde, (xwa+52)
	ld	xhl, (xwa+44)
	ld	bc, (xhl)
	muls	bc, 10
	ld	wa, bc
	dec	1, wa
	ld	ix, (xde)
	sub	ix, wa
	jr	ge, VariScreen_SetRightHighlightColors
	sub	wa, (xde)
	ldw	de, 9
	sub	de, wa
	ld	(xsp+8), e
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
	lda xhl, (0x03f214:24)
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
	lda xde, (0x03f214:24)
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
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawRightNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawRightDefaultVoice

VariScreen_DrawRightNameLabel:
	lda_dri XDE, 0xfd, 0x26, 0x02
	lda_dri XHL, 0xfd, 0x22, 0x02
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
	decw	8, (xbc)
	ld	xde, (xsp+24)
	ld	xwa, (xde+44)
	ld	bc, (xwa)
	muls	bc, 10
	sub	bc, 10
	ld	xwa, (xde+60)
	ld	wa, (xwa)
	extz	wa
	div	a, 10
	ld	a, w
	inc	1, a
	extz	wa
	add	wa, bc
	pushw	wa
	pushw 237
	pushw 5646
	lda	xwa, (xsp+40)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xhl, (xsp+550)
	lda	xbc, (xsp+546)
	lda	xde, (xsp+34)
	ld	xwa, 3:i3
	push	xwa
	ld	a, (xsp+16)
	extz	wa
	pushw	wa
	ld	a, (xsp+20)
	extz	wa
	pushw	wa
	ld	xwa, xhl
	call	DrawStringLeftJustify
	lda	xbc, (xsp+546)
	lda	xde, (xbc+2)
	ld	wa, (xde)
	add	wa, 12
	ld	(xde), wa
	lda	xhl, (xsp+550)
	sub	wa, 15
	ld	(xhl+2), wa
	ld	wa, (xde)
	add	wa, 16
	ld	(xhl+6), wa
	lda	xwa, (xhl+4)
	cpw	(xbc), 0
	jr	nz, VariScreen_SetRightVoiceRightBounds
	ldw	(xhl), 16
	ldw	(xwa), 156
	jr	VariScreen_DrawRightVoiceString
VariScreen_SetRightVoiceRightBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawRightVoiceString:
	lda_dri XDE, 0xfd, 0x22, 0x01
	ld xwa, 1:i3
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
	lda_dri XDE, 0xfd, 0x26, 0x02
	lda_dri XBC, 0xfd, 0x22, 0x02
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
	lda_dri XHL, 0xfd, 0x22, 0x01
	ld xwa, 1:i3
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
	ld XWA,(XSP+0x0236)
	ld XBC,(XSP+0x0232)
	ld XDE,(XSP+0x022e)
	call InheritedProc
	ld XWA,(XSP+0x0236)
	call GetViewInstance
	ld (XSP+0x10),XHL
	ld XWA,(XSP+0x10)
	ld (XSP+0x04),XWA
	lda XWA,(XSP+0x0226)
	ldw (XWA+0x02), 0x0006
	ldw (XWA+0x06), 0x0017
	ldw (XWA), 0x00f5
	ldw (XWA+0x04), 0x013b
	ldw BC, 0x00c1
	ldw DE, 0x00f3
	call DrawDesignBox
	lda XDE,(XSP+0x0226)
	ld WA,(XDE+0x04)
	sub WA,(XDE)
	exts XWA
	divs WA,0x0002
	ld BC,(XDE)
	add BC,WA
	lda XHL,(XSP+0x0222)
	ld (XHL),BC
	ld BC,(XDE+0x02)
	ld WA,(XDE+0x06)
	sub WA,BC
	exts XWA
	divs WA,0x0002
	add BC,WA
	inc 1,BC
	ld (XHL+0x02),BC
	ld XBC,(XSP+0x10)
	ld XWA,(XBC+0x34)
	ld WA,(XWA)
	exts XWA
	divs WA,0x000a
	inc 1,WA
	pushw wa
	ld	xwa, (xbc+44)
	pushw	(xwa)
	pushw	237
	pushw	5650
	lda	xwa, (xsp+298)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+550)
	lda	xbc, (xsp+546)
	lda	xde, (xsp+290)
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringCentered
	ld	(xsp+8), 9
	ld	xwa, (xsp+16)
	ld	xbc, (xwa+52)
	ld	xwa, (xwa+44)
	ld	wa, (xwa)
	muls	wa, 10
	dec	1, wa
	ld	de, (xbc)
	sub	de, wa
	jr	ge, VariScreen_ConfirmRowReady
	sub	wa, (xbc)
	ldw	bc, 9
	sub	bc, wa
	ld	(xsp+8), c
VariScreen_ConfirmRowReady:
	ld (xsp + 10), 0x0
	cp (xsp + 8), 0x0
	jrl c, FileBrowser_ReturnZero

VariScreen_ConfirmLoopBody:
	lda xwa, (xsp + 0x1c)
	ld XDE,(XSP+0x10)
	ld XBC,(XDE+0x38)
	ld BC,(XBC)
	ld (XWA),C
	ld XBC,(XDE+0x2c)
	ld BC,(XBC)
	dec 1,BC
	mul C,0x0a
	add C,(XSP+0x0a)
	ld (XWA+0x01),C
	ld XBC,(XDE+0x30)
	ld BC,(XBC)
	ld (XWA+0x02),C
	call SeMenu_SetDisplayValue_Helper
	lda xbc, (xsp + 0x1c)
	ld A,(XBC+0x03)
	extz WA
	ld C,(XBC+0x04)
	extz BC
	lda XDE,(XSP+0x0122)
	call Display_BytecodeBlock_F_Helper2
	ld (XSP+0x0132),0x00
	ld (XSP+0x08),0x09
	ld XWA,(XSP+0x10)
	ld XDE,(XWA+0x34)
	ld XHL,(XWA+0x2c)
	ld BC,(XHL)
	muls BC,0x000a
	ld WA,BC
	dec 1,WA
	ld IX,(XDE)
	sub IX,WA
	jr ge, VariScreen_ConfirmHighlightColors
	sub WA,(XDE)
	ldw DE, 0x0009
	sub DE,WA
	ld (XSP+0x08),E
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
	lda xde, (0x03f214:24)
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
	lda xde, (0x03f214:24)
	ld l, (xsp + 10)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 16)
	ld xiz, (xwa + 56)
	lda_dri XIY, 0xfd, 0x26, 0x02
	lda_dri XIX, 0xfd, 0x22, 0x02
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
	decw	8, (xiy)
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+44)
	ld	bc, (xwa)
	muls	bc, 10
	sub	bc, 10
	ld	a, (xsp+10)
	inc	1, a
	extz	wa
	add	wa, bc
	pushw	wa
	pushw 237
	pushw 5662
	lda	xwa, (xsp+40)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+550)
	lda	xde, (xsp+546)
	lda	xhl, (xsp+34)
	ld	xbc, 3:i3
	push	xbc
	ld	c, (xsp+16)
	extz	bc
	pushw	bc
	ld	c, (xsp+20)
	extz	bc
	pushw	bc
	ld	xbc, xde
	ld	xde, xhl
	call	DrawStringLeftJustify
	lda	xde, (xsp+546)
	lda	xbc, (xde+2)
	ld	hl, (xbc)
	add	hl, 12
	ld	(xbc), hl
	lda	xwa, (xsp+550)
	sub	hl, 15
	ld	(xwa+2), hl
	ld	bc, (xbc)
	add	bc, 16
	ld	(xwa+6), bc
	lda	xbc, (xwa+4)
	cpw	(xde), 0
	jr	nz, VariScreen_ConfirmSetVoiceRightBounds
	ldw	(xwa), 16
	ldw	(xbc), 156
	jr	VariScreen_ConfirmDrawVoiceString
VariScreen_ConfirmSetVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_ConfirmDrawVoiceString:
	lda_dri XHL, 0xfd, 0x22, 0x01
	ld xbc, 1:i3
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
	lda_dri XDE, 0xfd, 0x22, 0x01
	ld xbc, 1:i3
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
	inc	1, (xsp+10)
	ld a, (xsp + 10)
	cp a, (xsp + 8)
	jrl ule, VariScreen_ConfirmLoopBody
	jrl FileBrowser_ReturnZero

VariScreen_HandleEnumNotify:
	ld XWA, (xsp + 0x0236)
	call GetViewInstance
	ld (xsp + 24), xhl
	ld XWA, (xsp + 0x022e)
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
	ld XWA, (xsp + 0x022e)
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
	lda xde, (0x03f214:24)
	ld XWA, (xsp + 0x022e)
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
	lda xde, (0x03f214:24)
	ld XWA, (xsp + 0x022e)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	lda_dri XBC, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_EnumDrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_EnumDrawDefaultVoice

VariScreen_EnumDrawNameLabel:
	lda_dri XDE, 0xfd, 0x26, 0x02
	lda_dri XHL, 0xfd, 0x22, 0x02
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
	decw	8, (xbc)
	ld	xwa, (xsp+24)
	ld	xwa, (xwa+44)
	ld	bc, (xwa)
	muls	bc, 10
	sub	bc, 10
	ld	xwa, (xsp+20)
	ld	a, (xwa)
	inc	1, a
	extz	wa
	add	wa, bc
	pushw	wa
	pushw 237
	pushw 5666
	lda	xwa, (xsp+40)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+550)
	lda	xde, (xsp+546)
	lda	xhl, (xsp+34)
	ld	xbc, 3:i3
	push	xbc
	ld	c, (xsp+16)
	extz	bc
	pushw	bc
	ld	c, (xsp+20)
	extz	bc
	pushw	bc
	ld	xbc, xde
	ld	xde, xhl
	call	DrawStringLeftJustify
	lda	xhl, (xsp+546)
	lda	xbc, (xhl+2)
	ld	de, (xbc)
	add	de, 12
	ld	(xbc), de
	lda	xwa, (xsp+550)
	sub	de, 15
	ld	(xwa+2), de
	ld	bc, (xbc)
	add	bc, 16
	ld	(xwa+6), bc
	lda	xbc, (xwa+4)
	cpw	(xhl), 0
	jr	nz, VariScreen_EnumSetVoiceRightBounds
	ldw	(xwa), 16
	ldw	(xbc), 156
	jr	VariScreen_EnumDrawVoiceString
VariScreen_EnumSetVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_EnumDrawVoiceString:
	ld XBC, (xsp + 0x022e)
	lda xde, (xbc + 1)
	ld xbc, 1:i3
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
	lda_dri XWA, 0xfd, 0x26, 0x02
	lda_dri XDE, 0xfd, 0x22, 0x02
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
	ld XBC, (xsp + 0x022e)
	lda xhl, (xbc + 1)
	ld xbc, 1:i3
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
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)
	call InheritedProc
	ld XWA, (xsp + 0x0236)
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
	ld XBC, (xsp + 0x022e)
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
	ld bc, 0:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange1:
	ld bc, 1:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange2:
	ld bc, 2:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange3:
	ld bc, 3:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_HalfRange4:
	ld bc, 4:i3
	calr VariScreen_IsHalfRangeAbove
	cp l, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow0:
	ld bc, 0:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	ld bc, 0:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow1:
	ld a, (xsp + 8)
	extz wa
	ld bc, 1:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	ld bc, 1:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow2:
	ld a, (xsp + 8)
	extz wa
	ld bc, 2:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	ld bc, 2:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jrl RVari_NotifyAndReturn

VariScreen_OK_CalcRow3:
	ld a, (xsp + 8)
	extz wa
	ld bc, 3:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jrl z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	ld bc, 3:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)
	jr RVari_NotifyAndReturn

VariScreen_OK_CalcRow4:
	ld a, (xsp + 8)
	extz wa
	ld bc, 4:i3
	calr VariScreen_CalcValidNoteRow
	cp l, 0:i3
	jr z, FileBrowser_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 64)
	ld xwa, (xwa + 60)
	ld wa, (xwa)
	ld (xbc), wa
	ld a, (xsp + 8)
	extz wa
	ld bc, 4:i3
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
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
	ld xde, 0:i3
	call SendEvent
	ld XWA, (xsp + 0x0236)

RVari_NotifyAndReturn:
	calr RVari_UpdateDisplayNotify

FileBrowser_ReturnZero:
	ld xhl, 0:i3
	jrl VariScreen_Epilogue

VariScreen_OK_PageScroll:
	ld XWA, (xsp + 0x022e)
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
	incw 1, (xbc)
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	jr VariScreen_OK_PageSendEvent

VariScreen_OK_PageScrollWrap:
	cp wa, 1:i3
	jr le, VariScreen_OK_PageScrollDown
	ldw (xbc), 0x1
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	ld xde, 0:i3

VariScreen_OK_PageSendEvent:
	call SendEvent

VariScreen_OK_PageScrollDown:
	ld XWA, (xsp + 0x022e)
	cp xwa, 0x90
	jr nz, VariScreen_OK_ForwardToInherited
	ld xwa, (xsp + 16)
	ld xbc, (xwa + 44)
	cpw (xbc), 0x1
	jr le, VariScreen_OK_PageScrollDownWrap
	decw	1, (xbc)
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	ld xde, 0:i3
	jr VariScreen_OK_PageDownSendEvent

VariScreen_OK_PageScrollDownWrap:
	ld xwa, (xsp + 16)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cp wa, 1:i3
	jr le, VariScreen_OK_ForwardToInherited
	ld (xbc), wa
	ld XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	ld xde, 0:i3

VariScreen_OK_PageDownSendEvent:
	call SendEvent

VariScreen_OK_ForwardToInherited:
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)
	jr VariScreen_CallInheritedAndReturn

VariScreen_DefaultHandler:
	ld XWA, (xsp + 0x0236)
	ld XBC, (xsp + 0x0232)
	ld XDE, (xsp + 0x022e)

VariScreen_CallInheritedAndReturn:
	call InheritedProc

VariScreen_Epilogue:
	pop xiz
	lda_dri XSP, 0xfd, 0x36, 0x02
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
	ld l, 0x0:opc
	ret

VariScreen_IsHalfRangeAbove:
	srl a, 1
	cp a, c
	scc8 nc, l
	ret

RVariScreenProc:
	lda	xsp, (xsp-552)
	push	xiz
	ld	(xsp+544), xde
	ld	(xsp+548), xbc
	ld	(xsp+552), xwa
	ld	xbc, (xsp+548)
	cp	xbc, 29360135
	jrl	z, RVari_OK	; -> 0xFC0721
	cp	xbc, 31588363
	jrl	z, RVari_EnumNotify	; -> 0xFC0310
	cp	xbc, 29360143
	jrl	z, RVari_Confirm	; -> 0xFBFCB7
	cp	xbc, 29360142
	jrl	z, RVari_Select	; -> 0xFBEFBE
	cp	xbc, 29360141
	jrl	z, RVari_Paint	; -> 0xFBEE6A
	cp	xbc, 29360139
	jrl	z, RVari_Show	; -> 0xFBEE52
	cp	xbc, 29360129
	jrl	nz, RVari_Default	; -> 0xFC11E6
	ld	xwa, (xsp+552)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(xsp+17), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (xsp+14)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	ld	xbc, (xiz+56)
	lda	xde, (xsp+14)
	ld	a, (xde)
	extz	wa
	ld	(xbc), wa
	ld	xhl, (xiz+60)
	lda	xbc, (xde+1)
	ld	a, (xbc)
	extz	wa
	ld	(xhl), wa
	ld	xhl, (xiz+64)
	ld	a, (xbc)
	extz	wa
	ld	(xhl), wa
	ld	a, (xde)
	extz	wa
	call	AccVoice_GetChannelCount_Wrap
	ld	xbc, (xiz+52)
	extz	hl
	ld	(xbc), hl
	ld	xwa, (xiz+48)
	ldw	(xwa), 72
	ld	xwa, (xiz+56)
	cpw	(xwa), 14	; llvm-mc cannot spell this byte
	jr	nz, RVari_Init_TypeNotE	; -> 0xFBEE28
	ld	xbc, (xiz+44)
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 40
	inc	1, wa
	ld	(xbc), wa
	jr	RVari_Init_ForwardEvent	; -> 0xFBEE3A
RVari_Init_TypeNotE:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	ld (xbc), wa

RVari_Init_ForwardEvent:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_Show:
	ld XWA, (xsp + 0x0228)
	ld XBC, (xsp + 0x0224)
	ld XDE, (xsp + 0x0220)
	call InheritedProc
	ld xhl, 0:i3
	jrl RVari_Epilogue

RVari_Paint:
	ld	xwa, (xsp+552)
	ld	xbc, (xsp+548)
	ld	xde, (xsp+544)
	call	InheritedProc
	ld	xwa, (xsp+552)
	call	GetViewInstance
	lda	xhl, (xsp+532)
	ldw	(xhl), 4
	lda	xde, (xhl+2)
	ldw	(xde), 2
	lda	xwa, (xsp+536)
	ld	bc, (xhl)
	dec	2, bc
	ld	(xwa), bc
	ld	bc, (xhl)
	add	bc, 25
	ld	(xwa+4), bc
	ld	bc, (xde)
	dec	2, bc
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 25
	ld	(xwa+6), bc
	ldw	bc, 192
	ldw	de, 240
	call	DrawDesignBox
	lda	xwa, (xsp+532)
	ld	xbc, 144
	call	DrawIcons
	lda	xbc, (xsp+532)
	ldw	(xbc), 35
	lda	xhl, (xbc+2)
	ldw	(xhl), 8
	lda	xwa, (xsp+536)
	ld	de, (xbc)
	ld	(xwa), de
	ld	de, (xbc)
	add	de, 100
	ld	(xwa+4), de
	ld	de, (xhl)
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 50
	ld	(xwa+6), de
	ld	xde, 4:i3
	push	xde
	pushw	255
	pushw	247
	ld	xde, 15537734
	call	DrawString
	ld	xwa, 163840
	call	AcApcToggleProc_Helper
	ld	(xsp+17), l
	ld	xwa, 163841
	call	AcApcToggleProc_Helper
	lda	xwa, (xsp+14)
	ld	(xwa+4), l
	ld	(xwa+2), 72
	call	SndParam_ResolveVoiceEntry
	ld	a, (xsp+14)
	extz	wa
	call	AccVoice_CopyFromROM_Wrap
	extz	xhl
	pushw	16
	push	xhl
	lda	xwa, (xsp+282)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	lda	xde, (xsp+276)
	ld	(xde+16), 0
	lda	xbc, (xsp+532)
	ldw	(xbc), 107
	lda	xix, (xbc+2)
	ldw	(xix), 0
	lda	xwa, (xsp+536)
	ld	hl, (xbc)
	ld	(xwa), hl
	ld	hl, (xbc)
	add	hl, 128
	ld	(xwa+4), hl
	ld	hl, (xix)
	ld	(xwa+2), hl
	ld	hl, (xix)
	add	hl, 15
	ld	(xwa+6), hl
	ld	xhl, 0:i3
	push	xhl
	pushw	251
	pushw	247
	call	DrawString
	ld	xwa, (xsp+552)
	ld	xbc, 29360143
	ld	xde, 0:i3
	call	SendEvent
	ld	xwa, (xsp+552)
	ld	xbc, 29360142
	ld	xde, 0:i3
	call	SendEvent
	ld	xhl, 0:i3
	jrl	RVari_Epilogue	; -> 0xFC11F9
RVari_Select:
	ld	xwa, (xsp+552)
	ld	xbc, (xsp+548)
	ld	xde, (xsp+544)
	call	InheritedProc
	ld	xwa, (xsp+552)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, (xhl+56)
	cpw	(xwa), 15
	jrl	nz, RVari_Select_CalcVisibleCount
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (NakaInst_Rock_Pop_0x24:24)
	ld_rrb	a, xbc, wa	; ld a, (xbc+wa)
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xwa, (xsp+536)
	lda	xde, (xsp+534)
	ld	bc, (xde)
	sub	bc, 15
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 16
	ld	(xwa+6), bc
	ldw	(xwa), 163
	ldw	(xwa+4), 311
	ld	bc, 0:i3
	ldw	de, 245
	call	DrawDesignBox
	ld	xwa, (xiz+56)
	ld	wa, (xwa)
	extz	wa
	ld	xbc, (xiz+64)
	ld	bc, (xbc)
	extz	bc
	call	AccVoice_DispatchWithChannel
	extz	xhl
	pushw	13
	push	xhl
	lda	xwa, (xsp+282)
	push	xwa
	call	0xff05bc
	lda	xsp, (xsp+10)
	ld	(xsp+289), 0
	ld	(xsp+10), 255
	ld	(xsp+12), 245
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	bc, qwa
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	cp	wa, bc
	jr	nz, RVari_Select_CheckSameBank
	ld	(xsp+10), 0
	ld	(xsp+12), 7
RVari_Select_CheckSameBank:
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (15531432:24)
	ld_rrb	a, xbc, wa
	extz	wa
	call	DrawEditSw
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (15531432:24)
	ld_rrb	a, xbc, wa
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xde, (xsp+536)
	lda	xbc, (xsp+534)
	ld	wa, (xbc)
	sub	wa, 15
	ld	(xde+2), wa
	ld	wa, (xbc)
	add	wa, 16
	ld	(xde+6), wa
	ldw	(xde), 163
	ldw	(xde+4), 190
	decw	8, (xbc)
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	sla	wa, 2
	lda	xbc, (15537702:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw	237
	pushw	5710
	lda	xwa, (xsp+28)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xhl, (xsp+536)
	lda	xbc, (xsp+532)
	lda	xde, (xsp+20)
	ld	xwa, 3:i3
	push	xwa
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	ld	a, (xsp+18)
	extz	wa
	pushw	wa
	ld	xwa, xhl
	call	DrawStringLeftJustify
	lda	xhl, (xsp+532)
	lda	xde, (xhl+2)
	ld	wa, (xde)
	add	wa, 12
	ld	(xde), wa
	lda	xbc, (xsp+536)
	sub	wa, 15
	ld	(xbc+2), wa
	ld	wa, (xde)
	add	wa, 16
	ld	(xbc+6), wa
	ldw	(xbc), 183
	ldw	(xbc+4), 331
	lda	xde, (xsp+276)
	ld	xwa, 1:i3
	push	xwa
	ld	a, (xsp+14)
	extz	wa
	pushw	wa
	ld	a, (xsp+18)
	extz	wa
	pushw	wa
	ld	xwa, xbc
	ld	xbc, xhl
	call	DrawStringLeftJustify
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (15531432:24)
	ld_rrb	a, xbc, wa
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xwa, (xsp+536)
	lda	xde, (xsp+534)
	ld	bc, (xde)
	sub	bc, 15
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 16
	ld	(xwa+6), bc
	ldw	(xwa), 163
	ldw	(xwa+4), 311
	ldw	bc, 193
	ld	de, 7:i3
	call	DrawDesignBox
	ld	xwa, (xiz+56)
	ld	wa, (xwa)
	extz	wa
	ld	xbc, (xiz+60)
	ld	bc, (xbc)
	extz	bc
	call	AccVoice_DispatchWithChannel
	extz	xhl
	pushw	13
	push	xhl
	lda	xwa, (xsp+282)
	push	xwa
	call	16713148
	lda	xsp, (xsp+10)
	ld	(xsp+289), 0
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (15531432:24)
	ld_rrb	a, xbc, wa
	extz	wa
	call	DrawEditSw
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	lda	xbc, (15531432:24)
	ld_rrb	a, xbc, wa
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xde, (xsp+536)
	lda	xbc, (xsp+534)
	ld	wa, (xbc)
	sub	wa, 15
	ld	(xde+2), wa
	ld	wa, (xbc)
	add	wa, 16
	ld	(xde+6), wa
	ldw	(xde), 163
	ldw	(xde+4), 190
	decw	8, (xbc)
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	ld	wa, qwa
	sla	wa, 2
	lda	xbc, (15537702:24)
	ld_rrl	xwa, xbc, wa
	push	xwa
	pushw	237
	pushw	5714
	lda	xwa, (xsp+28)
	push	xwa
	call	Scoop_EventLoop_12Entry_Helper
	lda	xsp, (xsp+12)
	lda	xwa, (xsp+536)
	lda	xbc, (xsp+532)
	lda	xde, (xsp+20)
	ld	xhl, 3:i3
	push	xhl
	pushw	0
	pushw	7
	call	DrawStringLeftJustify
	lda	xbc, (xsp+532)
	lda	xhl, (xbc+2)
	ld	de, (xhl)
	add	de, 12
	ld	(xhl), de
	lda	xwa, (xsp+536)
	sub	de, 15
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 16
	ld	(xwa+6), de
	ldw	(xwa), 183
	ldw	(xwa+4), 331
	lda	xde, (xsp+276)
	ld	xhl, 1:i3
	push	xhl
	pushw	0
	pushw	7
	call	DrawStringLeftJustify
	ld	xwa, (xiz+64)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	lda	xbc, (15531436:24)
	ld_rrb	a, xbc, wa
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xwa, (xsp+536)
	lda	xde, (xsp+534)
	ld	bc, (xde)
	sub	bc, 15
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 16
	ld	(xwa+6), bc
	ldw	(xwa), 8
	ldw	(xwa+4), 156
	ld	bc, 0:i3
	ldw	de, 245
	call	DrawDesignBox
	lda	xwa, (xsp+536)
	lda	xbc, (xsp+532)
	lda	xhl, (xbc+2)
	ld	de, (xhl)
	sub	de, 15
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 16
	ld	(xwa+6), de
	ldw	(xwa), 45
	ldw	(xwa+4), 172
	ld	xde, (xiz+64)
	ld	de, (xde)
	srl	e, 2
	extz	de
	sla	de, 2
	lda	xhl, (15531476:24)
	ld_rrl	xde, xhl, de
	ld	xhl, 1:i3
	push	xhl
	pushw	255
	pushw	247
	call	DrawStringLeftJustify
	ld	xwa, (xiz+60)
	ld	wa, (xwa)
	exts	xwa
	divs	wa, 4
	lda	xbc, (15531436:24)
	ld_rrb	a, xbc, wa
	extz	wa
	lda	xbc, (xsp+532)
	call	GetEditSwPoint
	lda	xwa, (xsp+536)
	lda	xde, (xsp+534)
	ld	bc, (xde)
	sub	bc, 15
	ld	(xwa+2), bc
	ld	bc, (xde)
	add	bc, 16
	ld	(xwa+6), bc
	ldw	(xwa), 8
	ldw	(xwa+4), 156
	ldw	bc, 193
	ld	de, 7:i3
	call	DrawDesignBox
	lda	xwa, (xsp+536)
	lda	xbc, (xsp+532)
	lda	xhl, (xbc+2)
	ld	de, (xhl)
	sub	de, 15
	ld	(xwa+2), de
	ld	de, (xhl)
	add	de, 16
	ld	(xwa+6), de
	ldw	(xwa), 45
	ldw	(xwa+4), 172
	ld	xde, (xiz+60)
	ld	de, (xde)
	srl	e, 2
	extz	de
	sla	de, 2
	lda	xhl, (15531476:24)
	ld_rrl	xde, xhl, de
	ld	xhl, 1:i3
	push	xhl
	pushw	0
	pushw	247
	call	DrawStringLeftJustify
	jrl	RVari_Select_ReturnZero
	.include "ui/rvari_routines.s"
