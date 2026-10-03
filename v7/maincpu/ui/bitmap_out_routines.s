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
	ld xiz, 0:i3
	ld xwa, (xsp + 8)
	lda xde, (xwa + 20)
	ld xwa, (xde)
	cp xwa, 0x0
	jr ule, BitMapOut_BlitComplete
	ld xix, (xsp + 4)
	ld xwa, xix
	lda xhl, (xwa + 1)
	ld xbc, 0:i3

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
	cp	hl, 0:i3
	ret	z
	call	GetTitleNow
	cp	xhl, TITLE_TEST3
	ret	z
	cp	(SWBTWR_PAYLOAD_1:16), 0
	ret	nz
	calr	BitMapOut_ByteData_DiskCheck
	cp	l, 0:i3
	ret	nz
	ld	a, (SWBTWR_PAYLOAD_2:16)
	cp	a, 13
	jr	z, BitMapOut_ByteData_RenderA_Skip
	cp	a, 12
	jr	nz, BitMapOut_ByteData_RenderA_Skip2
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_DRAWBAR
	call	ApPostEvent
	ld	wa, 1:i3
	jr	BitMapOut_ByteData_RenderA_Join
BitMapOut_ByteData_RenderA_Skip:
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_ACCORDION
	call	ApPostEvent
	ld	wa, 1:i3
	jr	BitMapOut_ByteData_RenderA_Join
BitMapOut_ByteData_RenderA_Skip2:
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_SVARI
	call	ApPostEvent
	ld	wa, 1:i3
BitMapOut_ByteData_RenderA_Join:
	calr	BitMapOut_StorePresetValue
	ret
BitMapOut_ByteData_RenderB:
	dec	6, xsp
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	jrl	z, BitMapOut_ByteData_RenderB_Epilogue
	call	GetTitleNow
	cp	xhl, TITLE_TEST3
	jrl	z, BitMapOut_ByteData_RenderB_Epilogue
	ld	a, (SWBTWR_EVENT_TYPE:16)
	cp	a, (PART_SELECT:16)
	jrl	nz, BitMapOut_ByteData_RenderB_Epilogue
	cp	(SWBTWR_PAYLOAD_1:16), 0
	jr	nz, BitMapOut_ByteData_RenderB_Epilogue
	calr	BitMapOut_ByteData_DiskCheck
	cp	l, 0:i3
	jr	nz, BitMapOut_ByteData_RenderB_Epilogue
	call	GetTitleNow
	cp	xhl, TITLE_SVARI
	jr	nz, BitMapOut_ByteData_RenderB_Epilogue
	ld	a, (PART_SELECT:16)
	extz	wa
	ld	bc, 0:i3
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+3), l
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 32
	call	DkMdlyPly_CheckState_Helper
	lda	xwa, (xsp)
	ld	(xwa+4), l
	ld (xwa+2), (PART_SELECT)
	call	SndParam_ResolveVoiceEntry
	ld	a, (xsp+0:8)
	cp	a, 13
	jr	z, BitMapOut_ByteData_RenderB_Skip
	cp	a, 12
	jr	nz, BitMapOut_ByteData_RenderB_Skip2
BitMapOut_ByteData_RenderB_Skip:
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_EXIT
	ld	xde, 0:i3
	call	ApPostEvent
	jr	BitMapOut_ByteData_RenderB_Epilogue
BitMapOut_ByteData_RenderB_Skip2:
	ld	xwa, 4294967295
	ld	xbc, EVT_TVARI_PAINT
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_TVARI_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	calr	BitMapOut_StorePresetValue
BitMapOut_ByteData_RenderB_Epilogue:
	inc	6, xsp
	ret
BitMapOut_ByteData_RenderC:
	ld	wa, 0:i3
	jrl	BitMapOut_StorePresetValue
BitMapOut_ByteData_RenderD:
	; framing ported from v10's source for the same label (same span length, statement for statement); 49 of 76 slots byte-identical
	dec	6, xsp
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	jr	z, BitMapOut_ByteData_RenderD_Epilogue
	call	GetTitleNow
	cp xhl, TITLE_SVARI
	jr	nz, BitMapOut_ByteData_RenderD_Epilogue
	cp (SWBTWR_EVENT_TYPE:16), 144
	jr nz, BitMapOut_ByteData_RenderD_Epilogue
	cp (SWBTWR_PAYLOAD_1:16), 16	; (at +1) differs from v10 here
	jr	nz, BitMapOut_ByteData_RenderD_Epilogue
	ld	a, (PART_SELECT:16)
	extz	wa
	ld	bc, 0:i3
	call	DkMdlyPly_CheckState_Helper
	ld	(xsp+3), l
	ld	a, (PART_SELECT:16)
	extz	wa
	ldw	bc, 32
	call	DkMdlyPly_CheckState_Helper
	lda	xwa, (xsp)
	ld	(xwa+4), l
	ld (xwa+2), (PART_SELECT)	; (at +3) differs from v10 here
	call	SndParam_ResolveVoiceEntry
	ld	a, (xsp+0:8)
	cp	a, 13
	jr	z, BitMapOut_ByteData_RenderD_Skip
	cp	a, 12
	jr	nz, BitMapOut_ByteData_RenderD_Skip2
BitMapOut_ByteData_RenderD_Skip:
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_EXIT
	ld	xde, 0:i3
	call	ApPostEvent
	jr	BitMapOut_ByteData_RenderD_Epilogue
BitMapOut_ByteData_RenderD_Skip2:
	ld	xwa, 4294967295
	ld	xbc, EVT_TVARI_PAINT
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	calr	BitMapOut_StorePresetValue
BitMapOut_ByteData_RenderD_Epilogue:
	inc	6, xsp
	ret
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	ret	z
	cp (SWBTWR_PAYLOAD_1:16), 0	; (at +1) differs from v10 here
	ret	nz
	calr	BitMapOut_ByteData_DiskCheck
	cp	l, 0:i3
	ret	nz
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_RVARI
	call	ApPostEvent
	ld	wa, 1:i3
	calr	BitMapOut_StorePresetValue
	ret
BitMapOut_ByteData_RenderE:
	; framing ported from v10's source for the same label (same span length, statement for statement); 20 of 29 slots byte-identical
	call	Boot_CheckConfigFlag7
	cp	hl, 0:i3
	ret	z
	cp (SWBTWR_PAYLOAD_1:16), 0	; (at +1) differs from v10 here
	ret	nz
	cp (SWBTWR_EVENT_TYPE:16), 72
	ret	nz
	calr	BitMapOut_ByteData_DiskCheck
	cp	l, 0:i3
	ret	nz
	call	GetTitleNow
	cp	xhl, TITLE_RVARI
	ret	nz
	ld	xwa, 4294967295
	ld	xbc, EVT_SHOW
	call	DeleteEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SHOW
	ld	xde, 0:i3
	call	ApPostEvent
	ld	wa, 1:i3
	calr	BitMapOut_StorePresetValue
	ret
BitMapOut_CheckDiskAndApply:
	cp (ACTIVE_TITLE:16), 0x8a
	jp z, (Interrupt_ModeGuardCheck:24)
	ld XWA,0xffffffff
	ld XBC,EVT_CHORD_SHOW
	ld xde, 0:i3
	jp ApPostEvent
BitMapOut_ByteData_DiskCheck:
	ld	l, (36002:16)
	ret
BitMapOut_StorePresetValue:
	ld	(36002:16), a
	ret
BitMapOut_SetDefaultTimer:
	ld	(36000:16), 64
	ret
BitMapOut_DecrementTimer:
	call	GetTitleNow
	cp	xhl, TITLE_WELCOM
	jr	z, BitMapOut_SetDefaultTimer
	ld	a, (36000:16)
	cp	a, 0:i3
	ret	z
	dec	1, a
	ld	(36000:16), a
	cp	a, 0:i3
	ret	nz
	ld	xwa, 3:i3
	call	AcApcToggleProc_Helper
	ld	de, hl
	pushw	255
	ldw	wa, 112
	ld	bc, 2:i3
	call	AddswbWr
	ret
BitMapOut_ByteData_TransitionSeq:
	; framing ported from v10's source for the same label (same span length, statement for statement); 35 of 57 slots byte-identical
	call	GetTitleNow
	cp	xhl, TITLE_NORMAL
	ret	nz
	cp (SWBTWR_EVENT_TYPE:16), 152
	ret nz
	cp (SWBTWR_PAYLOAD_1:16), 11	; (at +1) differs from v10 here
	ret nz
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 192
	cp	a, 64
	jr	z, BitMapOut_ByteData_TransitionSeq_Skip
	cp	a, 128
	jr	nz, BitMapOut_ByteData_TransitionSeq_Skip2
	res 0, (36544:16)	; (at +1) differs from v10 here
	ldw wa, 96
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 4294967295
	ld	xbc, EVT_PAGE_SET
	ld	xde, 5:i3
	jr	BitMapOut_ByteData_TransitionSeq_Join
BitMapOut_ByteData_TransitionSeq_Skip:
	res 0, (36544:16)	; (at +1) differs from v10 here
	ldw wa, 96
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 4294967295
	ld	xbc, EVT_PAGE_SET
	ld	xde, 6:i3
	jr	BitMapOut_ByteData_TransitionSeq_Join
BitMapOut_ByteData_TransitionSeq_Skip2:
	set 0, (36544:16)	; (at +1) differs from v10 here
	ldw wa, 96
	call	CtrlPanel_SetIndicatorBit
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, BitMapOut_ByteData_TransitionSeq_Skip3
	ld	xwa, 4294967295
	ld	xbc, EVT_PAGE_SET
	ld	xde, 3:i3
	jr	BitMapOut_ByteData_TransitionSeq_Join
BitMapOut_ByteData_TransitionSeq_Skip3:
	ld	xwa, 4294967295
	ld	xbc, EVT_PAGE_SET
	ld	xde, 1:i3
BitMapOut_ByteData_TransitionSeq_Join:
	call	ApPostEvent
	ret
BitMapOut_ByteData_PresetCopy:
	push qiz
	cp (CURRENT_MODE:16), 14
	jr z, BitMapOut_ByteData_PresetCopy_Skip2
	bit 3, (36010:16)
	jr nz, BitMapOut_ByteData_PresetCopy_Skip2
	cp (SWBTWR_PAYLOAD_1:16), 1
	jr nz, BitMapOut_ByteData_PresetCopy_Skip2
	calr BitMapOut_GetRenderMode
	bit 1, l
	jr nz, BitMapOut_ByteData_PresetCopy_Join
	ldb_d8 a, (SWBTWR_PAYLOAD_2)
	res 7, a
	ldfr_berp a, 251
	cpib_erp 251, 0
	jr z, BitMapOut_ByteData_PresetCopy_Join
	dec1b_erp 251
	ldb_d8 a, (SWBTWR_PAYLOAD_3)
	res 7, a
	cp a, 0:i3
	jr z, BitMapOut_ByteData_PresetCopy_Join
	ld xwa, 769
	call AcApcToggleProc_Helper
	ldto_berp a, 251
	extz wa
	cp hl, 0:i3
	jr nz, BitMapOut_ByteData_PresetCopy_Skip
	calr BitMapOut_SnapshotFromROM
	jr BitMapOut_ByteData_PresetCopy_Join
BitMapOut_ByteData_PresetCopy_Skip:
	ld xbc, 63904
	calr BitMapOut_CopyVoicePreset9
BitMapOut_ByteData_PresetCopy_Join:
	ldw wa, 130
	calr BitMapOut_GetRenderMode_Return
BitMapOut_ByteData_PresetCopy_Skip2:
	res 3, (36010:16)
	pop qiz
	ret
BitMapOut_CopyVoicePreset9:
	lda xsp, (xsp - 82)
	push xiz
	ld (xsp + 82), xbc
	cp a, 0x80
	jr nz, BitMapOut_CopyPreset9_Clamp50
	ld a, 0x50:opc
	jr BitMapOut_CopyPreset9_Execute

BitMapOut_CopyPreset9_Clamp50:
	cp a, 0x50
	jrl ugt, BitMapOut_CopyPreset9_Done

BitMapOut_CopyPreset9_Execute:
	lda xhl, (0xf9a0:16)
	lda xbc, (0xf9b6:16)
	ld (xsp + 68), xbc
	lda xbc, (xbc + 14)
	sub xbc, xhl
	ld (xsp + 56), xbc
	extz wa
	sla wa, 2
	lda xbc, (BitMapOut_CopyPreset9_Execute_Data:24)
	lda	xbc, (xbc+wa)
	ld xwa, (xbc)
	ld xix, (xsp + 56)
	add xix, xwa
	lda xde, (xsp + 72)
	ld a, (xix)
	ld (xde), a
	lda xwa, (0xf9d0:16)
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
	lda xix, (0xf9ea:16)
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
	ld iy, 0:i3
	jr BitMapOut_CopyPreset9_CheckEnd

BitMapOut_CopyPreset9_StoreLoop:
	lda xix, (xiz+:1)
	ld wa, iy
	extz xwa
	add xwa, (xsp + 82)
	ld a, (xwa)
	ld (xix), a
	inc 1, iy

BitMapOut_CopyPreset9_CheckEnd:
	lda xwa, (0xfd5e:16)
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
	ld	a, (xsp)
	extz	wa
	ld	bc, wa
	sla	bc, 2
	lda	xde, (BitMapOut_CopyPreset9_Execute_Data:24)
	ld	xde, (xde+bc)
	cp	(xde), 0x78
	jr	nz, BitMapOut_Snapshot_PostProcess
	lda	xhl, (0xf9b4:16)
	sub	xhl, 0xf9a2
	ld	xbc, 0:i3
	ld	c, (xde + 1)
	cp	xbc, xhl
	jr	nz, BitMapOut_Snapshot_PostProcess
	ld	c, (0x8cb6:16)
	bit	2, c
	jr	nz, BitMapOut_Snapshot_RestoreFull
	bit	1, c
	jr	nz, BitMapOut_Snapshot_RestorePartial
	ld	xwa, 0x302
	call	AcApcToggleProc_Helper
	ld	a, (xsp)
	extz	wa
	cp	hl, 1:i3
	jr	nz, BitMapOut_Snapshot_RestoreFull
	calr	BitMapOut_RestoreVoiceFields
	jr	BitMapOut_Snapshot_PostProcess
BitMapOut_Snapshot_RestorePartial:
	calr	BitMapOut_PartialRestore
	jr	BitMapOut_Snapshot_PostProcess
BitMapOut_Snapshot_RestoreFull:
	calr	BitMapOut_RestoreFullVoice
BitMapOut_Snapshot_PostProcess:
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	ToneGen_DispatchByMode
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	calr	BitMapOut_DetectChanges
	bit	4, (0xfd50:16)
	jr	nz, BitMapOut_Snapshot_CheckActive
	bit	1, (0xfd2c:16)
	call	nz, (BitMapOut_DispatchIOChanges:24)
BitMapOut_Snapshot_CheckActive:
	ld	xwa, 0x302
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, BitMapOut_Snapshot_SetFlags
	bit	6, (0xfd9e:16)
	call	z, (MidiSysEx_SendAllParams:24)
BitMapOut_Snapshot_SetFlags:
	ld	a, (0x8cb6:16)
	set	4, a
	and	a, 0xf9
	ld	(0x8cb6:16), a
	inc	2, xsp
	ret
; v7's version of BitMapOut_RestoreVoiceFields: called from the same place in BitMapOut_Snapshot_Execute,
; same start (extz wa / calr BitMapOut_CopyROMToWorkspace), compiled with a smaller frame than v10's.
BitMapOut_RestoreVoiceFields:
	dec	2, xsp
	ld	(xsp), a
	ld	a, (xsp)
	extz	wa
	calr	BitMapOut_CopyROMToWorkspace
	lda	xhl, (0xfc5e:16)
	ld	c, (xhl)
	and	c, 248
	ld	(xhl), c
	ld	xwa, xhl
	sub	xwa, 63904
	lda	xix, (0x03c8e4:24)
	ld	xde, xwa
	add	xde, xix
	ld	a, (xde)
	and	a, 0x7
	or	c, a
	ld	(xhl), c
	lda	xwa, (0xfd0c:16)
	resm	7, (xwa)
	resm	7, (xwa + 1)
	resm	7, (xwa + 2)
	bit	3, (0x8cb6:16)
	jr	z, BitMapOut_RestoreVoiceFields_CheckNot80
	ld	c, (xhl)
	res	4, c
	ld	(xhl), c
	ld	a, (xde)
	and	a, 0x10
	or	c, a
	ld	(xhl), c
BitMapOut_RestoreVoiceFields_CheckNot80:
	cp	(xsp), 80
	call	nz, (BitMapOut_SelectiveFieldRestore:24)
	push	xde
	push	xhl
	push	xix
	push	xiz
	call	SeqTimer_UpdateTempoReg
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	inc	2, xsp
	ret
BitMapOut_RestoreFullVoice:
	lda	xsp, (xsp-16)
	push	xiz
	extz	wa
	sla	wa, 2
	lda	xbc, (BitMapOut_CopyPreset9_Execute_Data:24)
	exts	xwa
	add	xwa, xbc
	ld	(xsp + 0x10), xwa
	ld	(xsp + 0xc), xwa
	ld	xwa, (xsp + 0x10)
	ld	xhl, (xwa)
	lda	xwa, (0xf9a0:16)
	ld	(xsp + 0x4), xwa
	ld	xiy, xwa
	ld	ix, 0:i3
	jr	BitMapOut_RestoreFull_CheckEnd
; === end v7 block ===
BitMapOut_RestoreFull_FieldLoop:
	inc 1, xiy
	ld A, (xiy+)
	ldfr_berp A, 0xe6
	inc 1, xhl
	inc 1, xhl
	ld bc, 0:i3
	ldto_berp E, 0xe6
	extz de
	cp de, 0:i3
	jr ule, BitMapOut_RestoreFull_FieldDone

BitMapOut_RestoreFull_CopyField:
	ldto_berp A, 0xe6
	ld xiz, 0:i3
	ldfr_berp A, 0xf8
	lda xwa, (0xf9ce:16)
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
	ld A, (xhl+)
	ld (xiy+), a

BitMapOut_RestoreFull_NextField:
	inc 1, bc
	cp bc, de
	jr c, BitMapOut_RestoreFull_CopyField

BitMapOut_RestoreFull_FieldDone:
	add ix, bc
	inc 1, ix
	inc 1, ix

BitMapOut_RestoreFull_CheckEnd:
	lda_d16 xwa, (64584)
	sub xwa, (xsp+4)
	ld bc, ix
	extz xbc
	cp xbc, xwa
	jr lt, BitMapOut_RestoreFull_FieldLoop
	lda_d16 xde, (64606)
	ld c, (xde)
	and c, 7
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp+4)
	ld xix, (xsp+12)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	and a, 248
	or c, a
	ld (xde), c
	lda_d16 xbc, (64614)
	ld xde, xbc
	sub xde, (xsp+4)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xde, (xbc+1)
	ld xhl, xde
	sub xhl, (xsp+4)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	lda xde, (xbc+2)
	ld xhl, xde
	sub xhl, (xsp+4)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	ld (xde), a
	lda xde, (xbc+3)
	ld c, (xde)
	and c, 2
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp+4)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	res 1, a
	or c, a
	ld (xde), c
	lda_d16 xbc, (64770)
	ld (xsp+8), xbc
	sub xbc, (xsp+4)
	ld xwa, (xix)
	add xbc, xwa
	ld xwa, (xsp+8)
	ld c, (xbc)
	ld (xwa), c
	lda_d16 xbc, (64622)
	ld xde, xbc
	sub xde, (xsp+4)
	ld xwa, (xix)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a
	lda xde, (xbc+1)
	ld c, (xde)
	and c, 32
	ld (xde), c
	ld xhl, xde
	sub xhl, (xsp+4)
	ld xwa, (xix)
	add xhl, xwa
	ld a, (xhl)
	res 5, a
	or c, a
	ld (xde), c
	ld bc, 0:i3
	jr BitMapOut_CopyPresetTable_Check
BitMapOut_CopyPresetTable_Loop:
	ld de, bc

	extz xde

	add xde, xhl

	ld xhl, xde

	sub xhl, (xsp+4)	; sub xhl, (xsp + 12) (v7 displacement)

	ld xwa, (xsp+16)	; ld xwa, (xsp + 24) (v7 displacement)

	ld xwa, (xwa)

	add xhl, xwa

	ld a, (xhl)

	ld (xde), a

	inc 1, bc



BitMapOut_CopyPresetTable_Check:
	lda xhl, (0xfc74:16)
	lda xwa, (0xfca6:16)
	sub xwa, xhl
	ld de, bc
	extz xde
	cp xde, xwa
	jr le, BitMapOut_CopyPresetTable_Loop
	ld bc, 0:i3
	jr BitMapOut_CopyExtTable_Check

BitMapOut_CopyExtTable_Loop:
	lda xwa, (0xfcc2:16)

	ld de, bc

	extz xde

	add xde, xwa

	ld xhl, xde

	sub xhl, (xsp+4)	; sub xhl, (xsp + 12) (v7 displacement)

	ld xwa, (xsp+16)	; ld xwa, (xsp + 24) (v7 displacement)

	ld xwa, (xwa)

	add xhl, xwa

	ld a, (xhl)

	ld (xde), a

	inc 1, bc



BitMapOut_CopyExtTable_Check:
	.incbin "includes/romslices/v7_block_bitmapout_copyexttable_check.bin", 0, 0xb5
BitMapOut_PartialRestore:
	.incbin "includes/romslices/v7_block_bitmapout_copyexttable_check.bin", 0xb5, 134
; === end v7 block ===
BitMapOut_CopyROMToWorkspace:
	pushw	960
	extz	wa
	sla	wa, 2
	lda	xbc, (BitMapOut_CopyPreset9_Execute_Data:24)
	ld	xwa, (xbc+wa)
	push	xwa
	pushw	0
	pushw	63904
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
BitMapOut_SelectiveFieldRestore:
	lda xsp, (xsp - 14)
	push xiz
	lda xwa, (0xfd96:16)
	ld (xsp + 6), xwa
	inc 7, xwa
	ld (xsp + 14), xwa
	bitm 0, (xwa)
	jrl z, BitMapOut_SelectRestore_CheckBit1
	lda xde, (0xf9a0:16)
	lda xbc, (0xfc5a:16)
	ld xwa, xbc
	sub xwa, xde
	lda xhl, (0x03c8e4:24)
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
	lda xhl, (0xf9a0:16)
	lda xde, (0xfc5a:16)
	lda xbc, (xde + 8)
	ld xwa, xbc
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
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
	lda xde, (0xfd02:16)
	ld c, (xde)
	and c, 0xfc
	ld (xde), c
	lda xhl, (0xf9a0:16)
	ld xwa, xde
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
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
	lda xbc, (0xfd04:16)
	ld xde, xbc
	sub xde, 0xf9a0
	lda xwa, (0x03c8e4:24)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_SelectRestore_CheckBit4:
	ld xwa, (xsp + 14)
	bitm 4, (xwa)
	jr z, BitMapOut_SelectRestore_CheckVolBit
	lda xde, (0xfc5d:16)
	ld c, (xde)
	and c, 0xf0
	ld (xde), c
	lda xhl, (0xf9a0:16)
	ld xwa, xde
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
	add xwa, xix
	ld a, (xwa)
	and a, 0xf
	or c, a
	ld (xde), c
	lda xde, (0xfc69:16)
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
	lda xhl, (0xf9a0:16)
	lda xwa, (0xfc74:16)
	lda xix, (0x03c8e4:24)
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_SelectRestore_VolCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_SelectRestore_VolCopyLoop

BitMapOut_SelectRestore_CheckEffBit:
	ld xwa, (xsp + 14)
	bitm 7, (xwa)
	jr z, BitMapOut_RestoreVoiceChannels
	lda xhl, (0xf9a0:16)
	lda xwa, (0xfc8e:16)
	lda xix, (0x03c8e4:24)
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_SelectRestore_EffCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_SelectRestore_EffCopyLoop

BitMapOut_RestoreVoiceChannels:
	ld xwa, (xsp + 14)
	bitm 5, (xwa)
	jrl z, BitMapOut_RestoreChannels_CheckParts
	lda xiy, (0xf9b6:16)
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	lda xbc, (0xf9a0:16)
	ld xwa, xix
	sub xwa, xbc
	lda xde, (0x03c8e4:24)
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
	lda xiy, (0xf9d0:16)
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
	lda xiy, (0xf9ea:16)
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
	lda xiy, (0xfa04:16)
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
	lda xiy, (0xfa1e:16)
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
	lda xiy, (0xfa38:16)
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
	lda xiy, (0xfa52:16)
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
	lda xiy, (0xfa6c:16)
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
	lda xiy, (0xfa86:16)
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
	lda xiy, (0xfaa0:16)
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
	lda xiy, (0xfaba:16)
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
	lda xiy, (0xfad4:16)
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
	lda xiy, (0xfaee:16)
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
	lda xiy, (0xfb08:16)
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
	lda xiy, (0xfb22:16)
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
	lda xiy, (0xfb3c:16)
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
	lda xiy, (0xfb56:16)
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
	lda xiy, (0xfb70:16)
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
	lda xiy, (0xfb8a:16)
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
	lda xiy, (0xfba4:16)
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
	lda xiy, (0xfbbe:16)
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
	lda xiy, (0xfbd8:16)
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
	lda xiy, (0xfc0c:16)
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
	ld hl, 0:i3
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
	lda xiy, (0xfd50:16)
	lda xwa, (0xfd5e:16)
	sub xwa, xiy
	ld ix, hl
	extz xix
	cp xix, xwa
	jr le, BitMapOut_RestoreChannels_ByteLoop

BitMapOut_RestoreChannels_CheckParts:
	ld xwa, (xsp + 10)
	bitm 1, (xwa)
	jrl z, BitMapOut_RestoreExtra_CheckBit6
	ld de, 0:i3
	ldw (xsp + 4), 0x0

BitMapOut_RestoreParts_OuterLoop:
	ld hl, 0:i3

BitMapOut_RestoreParts_InnerLoop:
	lda xbc, (0xf9a0:16)
	ld iz, hl
	add iz, de
	lda xix, (0xfa04:16)
	extz xiz
	add xiz, xix
	ld xwa, xiz
	sub xwa, xbc
	lda xiy, (0x03c8e4:24)
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
	lda xwa, (0xfa1c:16)
	sub xwa, xiz
	ld iz, hl
	extz xiz
	cp xiz, xwa
	jr le, BitMapOut_RestoreParts_CopyByte
	add de, 0x1a
	incw 1, (xsp + 4)
	cpw (xsp + 4), 0xc
	jrl ule, BitMapOut_RestoreParts_OuterLoop

BitMapOut_RestoreExtra_CheckBit6:
	ld xwa, (xsp + 14)
	bitm 6, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckConfigBit
	lda xhl, (0xf9a0:16)
	lda xwa, (0xfd1c:16)
	lda xix, (0x03c8e4:24)
	ld xbc, xwa
	lda xde, (xwa + 14)

BitMapOut_RestoreExtra_AuxLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_AuxLoop

BitMapOut_RestoreExtra_CheckConfigBit:
	ld xwa, (xsp + 10)
	bitm 2, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckDataBit
	lda xhl, (0xf9a0:16)
	lda xwa, (0xfd30:16)
	lda xix, (0x03c8e4:24)
	ld xbc, xwa
	lda xde, (xwa + 30)

BitMapOut_RestoreExtra_ConfigLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_ConfigLoop

BitMapOut_RestoreExtra_CheckDataBit:
	ld xwa, (xsp + 10)
	bitm 3, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckMiscBit
	lda xhl, (0xf9a0:16)
	lda xde, (0xfc54:16)
	lda xbc, (xde + 1)
	ld xwa, xbc
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	ld xwa, xde
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	lda xwa, (0xfcdc:16)
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_DataTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_DataTableLoop

BitMapOut_RestoreExtra_CheckMiscBit:
	ld xwa, (xsp + 10)
	bitm 4, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckFlagBits
	lda xde, (0xf9a0:16)
	lda xix, (0xfd02:16)
	lda xbc, (xix + 5)
	ld xwa, xbc
	sub xwa, xde
	lda xhl, (0x03c8e4:24)
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
	lda xbc, (0xfd12:16)
	ld xde, xbc
	sub xde, 0xf9a0
	lda xwa, (0x03c8e4:24)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckPanBit:
	ld xwa, (xsp + 10)
	bitm 5, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckCtrlBit
	lda xbc, (0xfc6a:16)
	ld xde, xbc
	sub xde, 0xf9a0
	lda xwa, (0x03c8e4:24)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckCtrlBit:
	ld xwa, (xsp + 10)
	bitm 6, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckLevelBit
	lda xhl, (0xf9a0:16)
	lda xwa, (0xfc4a:16)
	lda xix, (0x03c8e4:24)
	ld xbc, xwa
	lda xde, (xwa + 8)

BitMapOut_RestoreExtra_CtrlCopyLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_CtrlCopyLoop

BitMapOut_RestoreExtra_CheckLevelBit:
	ld xwa, (xsp + 10)
	bitm 7, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckExpBit
	lda xde, (0xfc6f:16)
	ld c, (xde)
	res 6, c
	ld (xde), c
	lda xhl, (0xf9a0:16)
	ld xwa, xde
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
	add xwa, xix
	ld a, (xwa)
	and a, 0x40
	or c, a
	ld (xde), c
	lda xwa, (0xfcc2:16)
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_LevelTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_LevelTableLoop

BitMapOut_RestoreExtra_CheckExpBit:
	ld xwa, (xsp + 14)
	bitm 0, (xwa)
	jr z, BitMapOut_RestoreExtra_Done
	lda xde, (0xfc6f:16)
	ld c, (xde)
	res 5, c
	ld (xde), c
	lda xhl, (0xf9a0:16)
	ld xwa, xde
	sub xwa, xhl
	lda xix, (0x03c8e4:24)
	add xwa, xix
	ld a, (xwa)
	and a, 0x20
	or c, a
	ld (xde), c
	lda xwa, (0xfca8:16)
	ld xbc, xwa
	lda xde, (xwa + 24)

BitMapOut_RestoreExtra_ExpTableLoop:
	ld xwa, xbc
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xbc+), a
	cp xbc, xde
	jr ule, BitMapOut_RestoreExtra_ExpTableLoop

BitMapOut_RestoreExtra_Done:
	pop xiz
	lda xsp, (xsp + 14)
	ret

BitMapOut_SaveDisplayToROM:
	pushw	960
	pushw	0
	pushw	63904
	pushw	3
	pushw	51428
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
BitMapOut_DetectChanges:
	lda xsp, (xsp - 0x0a)
	pushw iz
	call Voice_InitAllChannelEntries
	calr BitMapOut_GetRenderMode
	bit 0x00,L
	jr nz, .Lc_fb4e26
	cp (CURRENT_MODE:16), 0x13
	jr z, .Lc_fb4e26
	lda xhl, (0xf9a0:16)
	lda xde, (0xfc5a:16)
	lda xbc, (xde + 0x05)
	ld XWA,XBC
	sub XWA,XHL
	lda xix, (0x03c8e4:24)
	add XWA,XIX
	ld W,(XWA)
	res 0x01,W
	ld A,(XBC)
	and A,0x02
	or A,W
	ld (XBC),A
	lda xbc, (xde + 0x06)
	ld XWA,XBC
	sub XWA,XHL
	add XWA,XIX
	ld A,(XWA)
	ld (XBC),A
BitMapOut_DetectChanges_CheckMode:
.Lc_fb4e26:
	bit 5, (0x8dda:16)
	jr nz, .Lc_fb4e34
	calr BitMapOut_GetRenderMode
	bit 0x00,L
	jr z, .Lc_fb4e45
BitMapOut_DetectChanges_UseShortList:
.Lc_fb4e34:
	ld hl, (0x9042:16)
	lda xwa, (SWBTWR_EVENT_QUEUE:16)
	ld (XSP+0x08),XWA
	set 2, (0x8caa:16)
	jr t, BitMapOut_DeltaEncode_Init
BitMapOut_DetectChanges_FullScan:
.Lc_fb4e45:
	calr BitMapOut_RefreshDisplay_ClearDirty
	calr BitMapOut_CalcDisplayMetrics
	calr BitMapOut_PrepareRenderState
	ld hl, (0x9046:16)
	lda xwa, (0xbe9d:16)
	ld (XSP+0x08),XWA
	res 2, (0x8caa:16)
BitMapOut_DeltaEncode_Init:
	ld iz, 0:i3
	jrl BitMapOut_DeltaEncode_CheckBounds

BitMapOut_DeltaEncode_ReadEntry:
	and (36010:16), 252	; anddi8 (0x8d46), 252 (v7 patched)

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

	jrl z, BitMapOut_DeltaEncode_NextEntry	; jrl z, BitMapOut_DeltaEncode_NextEntry (v7 displacement)



BitMapOut_DeltaEncode_ScanLoop:
	inc 1,IZ
	lda xde, (0xf9a0:16)
	ld IX,IZ
	extz XIX
	add XIX,XDE
	ld WA,IZ
	extz XWA
	ld XBC,0x0003c8e4
	add XBC,XWA
	ld A,(XBC)
	cp A,(XIX)
	jrl z, BitMapOut_DeltaEncode_NextByte
	ld BC,HL
	extz XBC
	add XBC,(XSP+0x08)
	ld a, (0x8caa:16)
	bit 0x02,A
	jr nz, BitMapOut_DeltaEncode_SlowTimeout
	inc 1,XDE
	lda xwa, (0xfba2:16)
	sub XWA,XDE
	ld DE,IZ
	extz XDE
	cp XDE,XWA
	jr gt, BitMapOut_DeltaEncode_BufferFull
	cp HL,0x00f4
	jr c, BitMapOut_DeltaEncode_EncodeChange
BitMapOut_DeltaEncode_BufferFull:
	ld	(xbc), 255
	ld	(36934:16), hl
	lda	xwa, (SWBTWR_EVENT_QUEUE:16)
	ld	(xsp+8), xwa
	ld	hl, (36930:16)
	ld	a, (36010:16)
	set	2, a
	ld	(36010:16), a
	jr	BitMapOut_DeltaEncode_EncodeChange
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
	ld hl, 0:i3

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
	lda xwa, (0xf9a0:16)
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
	lda xbc, (0xf9a0:16)
	lda xwa, (0xfd5e:16)
	sub XWA,XBC
	ld DE,IZ
	extz XDE
	cp XDE,XWA
	jrl lt, BitMapOut_DeltaEncode_ReadEntry
	ld WA,HL
	extz XWA
	add XWA,(XSP+0x08)
	ld (XWA),0xff
	bit 2, (0x8caa:16)
	jr nz, BitMapOut_DeltaEncode_StoreShortLen
	ld (0x9046:16), hl
	jr t, BitMapOut_DeltaEncode_Return
BitMapOut_DeltaEncode_StoreShortLen:
	ld	(36930:16), hl
BitMapOut_DeltaEncode_Return:
	popw iz
	lda xsp, (xsp + 10)
	ret

BitMapOut_DispatchIOChanges:
	bit 7, (0xf9c4:16)
	call z, (BitMapOut_ApplyIOChange_Port0:24)
	bit 7, (0xf9c7:16)
	call z, (BitMapOut_ApplyIOChange_Port3:24)
	bit 7, (0xf9de:16)
	call z, (BitMapOut_ApplyIOChange_Port1:24)
	bit 7, (0xf9e1:16)
	call z, (BitMapOut_ApplyIOChange_Port4:24)
	bit 7, (0xf9f8:16)
	call z, (BitMapOut_ApplyIOChange_Port2:24)
	bit 7, (0xf9fb:16)
	ret nz
	calr BitMapOut_ApplyIOChange_Port5
	ret

BitMapOut_ApplyIOChange_Port0:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 0
	ld	c, (36016:16)
	ld	(36016:16), 15
	ld	b, (36016:16)
	ld	a, (63941:16)
	and	a, 255
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 255
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	ld	(36016:16), 0
	ld	c, (36016:16)
	ld	(36016:16), 0
	ld	b, (36016:16)
	ld	a, (63940:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_ApplyIOChange_Port1:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 1
	ld	c, (36016:16)
	ld	(36016:16), 15
	ld	b, (36016:16)
	ld	a, (63967:16)
	and	a, 255
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 255
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	ld	(36016:16), 1
	ld	c, (36016:16)
	ld	(36016:16), 0
	ld	b, (36016:16)
	ld	a, (63966:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_ApplyIOChange_Port2:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 2
	ld	c, (36016:16)
	ld	(36016:16), 15
	ld	b, (36016:16)
	ld	a, (63993:16)
	and	a, 255
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 255
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	ld	(36016:16), 2
	ld	c, (36016:16)
	ld	(36016:16), 0
	ld	b, (36016:16)
	ld	a, (63992:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_ApplyIOChange_Port3:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 0
	ld	c, (36016:16)
	ld	(36016:16), 3
	ld	b, (36016:16)
	ld	a, (63943:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_ApplyIOChange_Port4:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 1
	ld	c, (36016:16)
	ld	(36016:16), 3
	ld	b, (36016:16)
	ld	a, (63969:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_ApplyIOChange_Port5:
	push	xde
	push	xhl
	push	xix
	push	xiz
	ld	(36016:16), 2
	ld	c, (36016:16)
	ld	(36016:16), 3
	ld	b, (36016:16)
	ld	a, (63995:16)
	res	7, a
	ld	(36016:16), a
	ld	e, (36016:16)
	ld	(36016:16), 127
	ld	d, (36016:16)
	call	MIDI_DispatchCC
	pop	xiz
	pop	xix
	pop	xhl
	pop	xde
	ret
BitMapOut_DeltaEncode_TypeDefault:
	dec 8, xsp
	push xiz
	ld (xsp + 8), de
	ld (xsp + 10), a
	ld hl, (xsp + 16)
	ld xiy, (xsp + 18)
	lda xix, (0xf9a0:16)
	ld de, (xsp + 8)
	extz xde
	add xde, xix
	cp c, 0:i3
	jrl z, BitMapOut_DeltaEncode_TypeDefaultC
	ld wa, (xsp + 8)
	extz xwa
	ld xiz, 0x3c8e4
	add xiz, xwa
	cp c, 1:i3
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
	ld (xsp+4), xix
	ld xbc, xde
	ld a, (xde)
	res 7, a
	cp a, w
	jrl z, BitMapOut_DeltaEncode_HelperReturn
	bit 0, (36010:16)
	jrl nz, BitMapOut_DeltaEncode_HelperReturn
	ld de, hl
	inc 1, hl
	extz xde
	add xde, xiy
	ld a, (xsp+10)
	ld (xde), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 1
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
	ld (xwa), 127
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ld a, (xsp+10)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xiy
	ld (xwa), 0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xiy
	ldw wa, 65535
	add wa, (xsp+8)
	extz xwa
	add xwa, (xsp+4)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	jr BitMapOut_DeltaEncode_HelperCheckEnd
BitMapOut_DeltaEncode_TypeDefaultC:
	set 0, (36010:16)	; setda 0, 0x8d46 (v7 patched)

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
	set 6, (36010:16)	; setda 6, 0x8d46 (v7 patched)

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
	lda xix, (0xf9a0:16)
	ld wa, (xsp + 16)
	extz xwa
	add xwa, xix
	ld (xsp + 12), xwa
	cp c, 0:i3
	jrl z, BitMapOut_DeltaEncode_Type48End
	ld iy, (xsp + 16)
	extz xiy
	ld xwa, 0x3c8e4
	add xwa, xiy
	ld (xsp + 8), xwa
	cp c, 1:i3
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
	lda xiz, (0xfc5a:16)
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
	ld xwa, (xsp+8)
	ld c, (xwa)
	res 7, c
	ld (xsp+4), xix
	ld xwa, (xsp+12)
	ld (xsp+8), xwa
	ld a, (xwa)
	res 7, a
	cp a, c
	jrl z, BitMapOut_DeltaEncode_Type48Return
	bit 0, (36010:16)
	jrl nz, BitMapOut_DeltaEncode_Type48Return
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp+18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 1
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld xwa, (xsp+8)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 127
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ld a, (xsp+18)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	extz xwa
	add xwa, xde
	ld (xwa), 0
	ld bc, hl
	inc 1, hl
	extz xbc
	add xbc, xde
	ldw wa, 65535
	add wa, (xsp+16)
	extz xwa
	add xwa, (xsp+4)
	ld a, (xwa)
	ld (xbc), a
	ld wa, hl
	inc 1, hl
	jr BitMapOut_DeltaEncode_Type48Epilog
BitMapOut_DeltaEncode_Type48End:
	set 0, (36010:16)	; setda 0, 0x8d46 (v7 patched)

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
	dec 4,XSP
	push XIZ
	ld HL,(XSP+0x0c)
	ld XIY,(XSP+0x0e)
	ld w, (0x8caa:16)
	lda_d16 xix, (63904)
	ld (xsp+4), xix
	ld ix, de
	extz xix
	add xix, (xsp+4)
	cp c, 0:i3
	jrl z, BitMapOut_DeltaEncode_Type90Loop
	cp c, 1:i3
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
	ld xbc, 248036
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
	ld	b, w
	bit	1, w
	jrl	nz, BitMapOut_DeltaEncode_Type90Epilog	; -> 0xFB5620
	set	1, b
	ld	(36010:16), b
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	(xiz), a
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	(xiz), c
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	w, (xix)
	ld	(xiz), w
	ld	ix, hl
	inc	1, hl
	extz	xix
	add	xix, xiy
	ld	(xix), 6
	ld	ix, hl
	inc	1, hl
	extz	xix
	add	xix, xiy
	ld	(xix), a
	ld	wa, hl
	inc	1, hl
	extz	xwa
	add	xwa, xiy
	dec	1, c
	ld	(xwa), c
	ld	bc, hl
	inc	1, hl
	extz	xbc
	add	xbc, xiy
	ldw	wa, 65535
	add	wa, de
	extz	xwa
	add xwa, (xsp+4)
	ld	a, (xwa)
	ld	(xbc), a
	ld	wa, hl
	inc	1, hl
	extz	xwa
	add	xwa, xiy
	ld	(xwa), 3
	jr	BitMapOut_DeltaEncode_Type90Epilog	; -> 0xFB5620
BitMapOut_DeltaEncode_Type90Loop:
	ld	b, w
	bit	1, w
	jr	nz, BitMapOut_DeltaEncode_Type90Epilog	; -> 0xFB5620
	set	1, b
	ld	(36010:16), b
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	(xiz), a
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	(xiz), c
	ld	iz, hl
	inc	1, hl
	extz	xiz
	add	xiz, xiy
	ld	w, (xix)
	ld	(xiz), w
	ld	ix, hl
	inc	1, hl
	extz	xix
	add	xix, xiy
	ld	(xix), 3
	ld	ix, hl
	inc	1, hl
	extz	xix
	add	xix, xiy
	ld	(xix), a
	ld	wa, hl
	inc	1, hl
	extz	xwa
	add	xwa, xiy
	inc	1, c
	ld	(xwa), c
	ld	bc, hl
	inc	1, hl
	extz	xbc
	add	xbc, xiy
	inc	1, de
	extz	xde
	add xde, (xsp+4)
	ld	a, (xde)
	ld	(xbc), a
	ld	wa, hl
	inc	1, hl
	extz	xwa
	add	xwa, xiy
	ld	(xwa), 6
BitMapOut_DeltaEncode_Type90Epilog:
	pop xiz
	inc 4, xsp
	retd 0x6

BitMapOut_DeltaEncode_Type90Return:
	dec 6, xsp
	pushw iz
	ld iz, 0:i3

BitMapOut_DeltaEncode_Type90Final:
	lda xwa, (xsp + 2)
	ld de, iz
	extz xde
	ld xbc, xde
	sll xbc, 3
	sub xbc, xde
	add xbc, xbc
	ld xde, BitMapOut_DeltaEncode_Type90Final_Data
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
	lda xhl, (BitMapOut_DeltaEncode_Type90Final_Data_2:24)
	add xhl, xbc
	lda xde, (xsp + 2)
	ld a, (xde)
	ldfr_berp A, 0xf0
	extz ix
	ld xbc, (xhl)
	ld a, (xde + 1)
	ld	(xbc+ix), a
	inc 1, iz
	cp iz, 0x17
	jr c, BitMapOut_DeltaEncode_Type90Final
	popw iz
	inc 6, xsp
	ret

BitMapOut_RefreshDisplay_CheckDirty:
	extz	wa
	ld	xbc, 63904
	jrl	BitMapOut_CopyVoicePreset9
	ret
BitMapOut_RefreshDisplay_ClearDirty:
	dec 8,XSP
	push XIZ
	ld de, (0x9046:16)
	lda xhl, (0xbe9d:16)
	lda xwa, (0xf9a0:16)
	ld (XSP+0x08),XWA
	lda xix, (0xfc66:16)
	ld XBC,XIX
	sub XBC,(XSP+0x08)
	lda xwa, (0x03c8e4:24)
	ld (XSP+0x04),XWA
	ld XIY,XBC
	add XIY,(XSP+0x04)
	ld A,(XIX)
	lda xbc, (xix + 0x01)
	cp A,(XIY)
	jr nz, BitMapOut_RefreshDisplay_UpdateRegs
	ld XWA,XBC
	sub XWA,(XSP+0x08)
	ld XIZ,XWA
	add XIZ,(XSP+0x04)
	ld A,(XBC)
	cp A,(XIZ)
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

	ld (36934:16), de

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
	push XIZ
	ld bc, (0x9046:16)
	ldw WA, 0x0100
	sub WA,BC
	cp WA,0x0008
	jr ule, BitMapOut_CalcMetrics_Done
	ld IY,BC
	lda xiz, (0xbe9d:16)
	lda xhl, (0xfd05:16)
	ld XWA,XHL
	sub XWA,0x0000f9a0
	lda xix, (0x03c8e4:24)
	ld XDE,XWA
	add XDE,XIX
	ld A,(XHL)
	cp A,(XDE)
	jr z, BitMapOut_CalcMetrics_ComputeGrid
	inc 1,IY
	extz XBC
	add XBC,XIZ
	ld (XBC),0x70
	ld WA,IY
	inc 1,IY
	extz XWA
	add XWA,XIZ
	ld (XWA),0x03
	ld BC,IY
	inc 1,IY
	extz XBC
	add XBC,XIZ
	ld A,(XHL)
	ld (XBC),A
	ld WA,IY
	inc 1,IY
	extz XWA
	add XWA,XIZ
	ld (XWA),0xff
BitMapOut_CalcMetrics_ComputeGrid:
	ld	wa, iy
	extz	xwa
	add	xwa, xiz
	ld	(xwa), 255
	ld	(36934:16), iy
	ld	a, (xhl)
	ld	(xde), a
BitMapOut_CalcMetrics_Done:
	pop xiz
	ret

BitMapOut_PrepareRenderState:
	push	xiz
	ld	bc, (36934:16)
	ldw	wa, 256
	sub	wa, bc
	cp	wa, 8
	jr	ule, BitMapOut_PrepareRender_CheckBit0
	ld	iy, bc
	lda	xix, (48797:16)
	lda	xhl, (64606:16)
	ld	xwa, xhl
	sub	xwa, 63904
	lda	xiz, (248036:24)
	ld	xde, xwa
	add	xde, xiz
	ld	w, (xde)
	and	w, 64
	ld	a, (xhl)
	and	a, 64
	cp	a, w
	jr	z, BitMapOut_PrepareRender_SetParams
	inc	1, iy
	extz	xbc
	add	xbc, xix
	ld	(xbc), 72
	ld	wa, iy
	inc	1, iy
	extz	xwa
	add	xwa, xix
	ld	(xwa), 4
	ld	bc, iy
	inc	1, iy
	extz	xbc
	add	xbc, xix
	ld	a, (xhl)
	and	a, 64
	ld	(xbc), a
	ld	wa, iy
	inc	1, iy
	extz	xwa
	add	xwa, xix
	ld	(xwa), 64
BitMapOut_PrepareRender_SetParams:
	ld	wa, iy
	extz	xwa
	add	xwa, xix
	ld	(xwa), 255
	ld	(36934:16), iy
	ld	c, (xde)
	res	6, c
	ld	(xde), c
	ld	a, (xhl)
	and	a, 64
	or	c, a
	ld	(xde), c
BitMapOut_PrepareRender_CheckBit0:
	pop xiz
	ret

BitMapOut_PrepareRender_CheckBit1:
	ld	l, (36012:16)
	ret
BitMapOut_PrepareRender_CheckBit2:
	ld	(36012:16), a
	ret
BitMapOut_GetRenderMode:
	ld	l, (36014:16)
	ret
BitMapOut_GetRenderMode_CheckBit3:
	lda	xbc, (36014:16)
	or	(xbc), a
	ld	l, (xbc)
	ret
BitMapOut_GetRenderMode_Return:
	lda xbc, (0x8cae:16)
	cpl A
	and A,(XBC)
	ld (XBC),A
	ld L,A
	ret
BitMapOut_ByteData_RenderState:
	push	xiz
	cp	(SWBTWR_PAYLOAD_1:16), 4
	jrl	nz, BitMapOut_ByteData_RenderState_Epilogue
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	and	a, 3
	cp	a, 1:i3
	jr	z, BitMapOut_ByteData_RenderState_Skip2
	cp	a, 2:i3
	jr	nz, BitMapOut_ByteData_RenderState_Skip4
	calr	BitMapOut_PrepareRender_CheckBit1
	ldfr_berp	l, 251
	inc1b_erp	251
	cp_erpb	251, 9
	jr	le, BitMapOut_ByteData_RenderState_Skip
	ldib_erp	251, 0
BitMapOut_ByteData_RenderState_Skip:
	ldto_berp	a, 251
	extz	wa
	jr	BitMapOut_ByteData_RenderState_Join
BitMapOut_ByteData_RenderState_Skip2:
	calr	BitMapOut_PrepareRender_CheckBit1
	ldfr_berp	l, 251
	dec1b_erp	251
	jr	ge, BitMapOut_ByteData_RenderState_Skip3
	ldi_erpb	251, 9
BitMapOut_ByteData_RenderState_Skip3:
	ldto_berp	a, 251
	extz	wa
BitMapOut_ByteData_RenderState_Join:
	calr	BitMapOut_PrepareRender_CheckBit2
BitMapOut_ByteData_RenderState_Skip4:
	call	GetTitleNow
	cp	xhl, TITLE_PMBKSEL
	jr	nz, BitMapOut_ByteData_RenderState_Skip5
	ldto_berp	e, 251
	exts	de
	exts	xde
	ld	xwa, 4294967295
	ld	xbc, EVT_SELE_DRAW
	jr	BitMapOut_ByteData_RenderState_Join2
BitMapOut_ByteData_RenderState_Skip5:
	call	GetTitleNow
	cp	xhl, TITLE_PMVIEW
	jr	nz, BitMapOut_ByteData_RenderState_Skip6
	pushw 18
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	calr	BitMapOut_PrepareRender_CheckBit1
	ld	(xiz), l
	calr	BitMapOut_PrepareRender_CheckBit1
	ld	a, l
	lda	xbc, (xiz+1)
	calr	BitMapOut_UpdateWidget_PostDraw
	ld	xwa, 4294967295
	ld	xbc, EVT_PMBK_NAME
	ld	xde, xiz
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
BitMapOut_ByteData_RenderState_Join2:
	call	ApPostEvent
BitMapOut_ByteData_RenderState_Skip6:
	ld	xwa, 0:i3
	ld	xbc, 0:i3
	ld	xde, 0:i3
	call	MainGetPmemName
BitMapOut_ByteData_RenderState_Epilogue:
	pop	xiz
	ret
BitMapOut_ByteData_DisplayUpdate:
	push	xiz
	ld	a, (SWBTWR_PAYLOAD_1:16)
	cp	a, 1:i3
	jr	nz, BitMapOut_ByteData_DisplayUpdate_Epilogue
	ld	a, (SWBTWR_PAYLOAD_3:16)
	res	7, a
	cp	a, 0:i3
	jr	z, BitMapOut_ByteData_DisplayUpdate_Skip
	ld	xwa, 768
	call	AcApcToggleProc_Helper
	cp	l, 0:i3
	jr	z, BitMapOut_ByteData_DisplayUpdate_Skip
	dec	1, l
	srl	l, 3
	extz	hl
	ld	wa, hl
	calr	BitMapOut_PrepareRender_CheckBit2
BitMapOut_ByteData_DisplayUpdate_Skip:
	call	GetTitleNow
	cp	xhl, TITLE_PMVIEW
	jr	nz, BitMapOut_ByteData_DisplayUpdate_Epilogue
	pushw	18
	call	Malloc
	inc	2, xsp
	ld	xiz, xhl
	calr	BitMapOut_PrepareRender_CheckBit1
	ld	(xiz), l
	calr	BitMapOut_PrepareRender_CheckBit1
	ld	a, l
	lda	xbc, (xiz+1)
	calr	BitMapOut_UpdateWidget_PostDraw
	ld	xwa, 4294967295
	ld	xbc, EVT_PMBK_NAME
	ld	xde, xiz
	call	ApPostEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_AUTO_FREE
	ld	xde, xiz
	call	ApPostEvent
BitMapOut_ByteData_DisplayUpdate_Epilogue:
	pop	xiz
	ret
BitMapOut_UpdateDisplayWidget:
	push xiz
	ld xiz, xbc
	cp a, 0:i3
	jr nz, BitMapOut_UpdateWidget_CheckType
	pushw 0x10
	pushw BitMapOut_UpdateDisplayWidget_Str_Non_Panel_Memory@hi16
	pushw BitMapOut_UpdateDisplayWidget_Str_Non_Panel_Memory@lo16
	jr BitMapOut_UpdateWidget_TypeA

BitMapOut_UpdateWidget_CheckType:
	dec 1, a
	extz wa
	sla wa, 2
	lda xbc, (BitMapOut_CopyPreset9_Execute_Data:24)
	ld	xbc, (xbc+wa)
	pushw 0x10
	lda xwa, (0xf9a2:16)
	sub xwa, 0xf980
	sub xwa, 0x20
	add xwa, xbc
	push xwa

BitMapOut_UpdateWidget_TypeA:
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xiz+16), 0
	pop	xiz
	ret
BitMapOut_UpdateWidget_TypeB:
	cp a, 0:i3
	ret Z
	dec 1,A
	extz WA
	sla wa, 2
	lda xde, (BitMapOut_CopyPreset9_Execute_Data:24)
	ld	xde, (xde+wa)
	pushw 0x0010
	push XBC
	lda xwa, (0xf9a2:16)
	sub XWA,0x0000f980
	sub XWA,0x00000020
	add XWA,XDE
	push XWA
	call Mem_Copy
	lda xsp, (xsp + 0x0a)
	ret
BitMapOut_UpdateWidget_PostDraw:
	push	xiz
	ld	xiz, xbc
	pushw	16
	sll	a, 4
	extz	wa
	lda	xbc, (2020192:24)
	exts	xwa
	add	xwa, xbc
	push	xwa
	push	xiz
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ld	(xiz+16), 0
	pop	xiz
	ret
BitMapOut_UpdateWidget_Finalize:
	pushw	16
	push	xbc
	sll	a, 4
	extz	wa
	lda	xbc, (2020192:24)
	exts	xwa
	add	xwa, xbc
	push	xwa
	call	Mem_Copy
	lda	xsp, (xsp+10)
	ret
BitMapOut_UpdateWidget_Done:
	call	GetTitleNow
	cp	xhl, TITLE_PMBKSEL
	jr	z, BitMapOut_UpdateWidget_Done_Skip
	call	GetTitleNow
	cp	xhl, TITLE_PMVIEW
	jr	z, BitMapOut_UpdateWidget_Done_Skip
	call	GetTitleNow
	cp	xhl, TITLE_PMBKNAME
	jr	z, BitMapOut_UpdateWidget_Done_Skip
	call	GetTitleNow
	cp	xhl, TITLE_PMNAME
	jr	z, BitMapOut_UpdateWidget_Done_Skip
	cp	(SWBTWR_PAYLOAD_1:16), 5
	ret	nz
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	bit	5, a
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_PMBKSEL
	call	ApPostEvent
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_HOLD
	ld	xde, 1:i3
	jr	BitMapOut_UpdateWidget_Done_Join
BitMapOut_UpdateWidget_Done_Skip:
	cp	(SWBTWR_PAYLOAD_1:16), 5
	ret	nz
	ld	a, (SWBTWR_PAYLOAD_2:16)
	and	a, (SWBTWR_PAYLOAD_3:16)
	bit	5, a
	ret	z
	ld	xwa, 0xffffffff
	ld	xbc, EVT_SET_HOLD
	ld	xde, 0:i3
BitMapOut_UpdateWidget_Done_Join:
	call	ApPostEvent
	ret
FileIO_ByteBlock_DemoProc1_Helper4:
	ret
FileIO_ByteBlock_DemoProc1_Helper5:
	extz	wa
	cp	bc, 0:i3
	jp	lt, (VoiceData_InitAndCopyParams:24)
	jp	ToneGen_LookupByVoiceIndex
LoadRegion1_OpenSuccess_Helper:
	ret
LoadRegion1_OpenSuccess_Helper2:
	dec 2,XSP
	push QIZ
	ld (XSP+0x02),A
	cp bc, 0:i3
	jr ge, .Lc_fb5b1a
	ld A,(XSP+0x02)
	extz WA
	call VoiceData_ExtendedParamSetup
	jr t, .Lc_fb5b39
.Lc_fb5b1a:
	lds_erpb 0xfb, 0
.Lc_fb5b1d:
BitMapOut_UpdateWidget_Finalize_Loop:
	ld_erpb_rr c, 0xfb
	extz BC
	ld A,(XSP+0x02)
	extz WA
	sll WA, 0x03
	add WA,BC
	call ToneGen_LookupByVoiceIndex
	incb_erp 0xfb, 1
	cp_erpb 0xfb, 0x08
	jr c, .Lc_fb5b1d
.Lc_fb5b39:
	pop QIZ
	inc 2,XSP
	ret
OneTchFUNC:
	cp xbc, EVT_ACTIVATE_STATE
	jr nz, BitMapOut_ApplyWidgetPatch
	dec 2, xde
	cp xde, 0x0
	jr c, BitMapOut_ApplyWidgetPatch
	cp xde, 0x5
	jr ugt, BitMapOut_ApplyWidgetPatch
	add xde, xde
	add xde, OneTchFUNC_Data
	ld de, (xde)
	lda xix, (BitMapOut_ByteData_WidgetTable:24)
	jp	t, (xix+de)
BitMapOut_ByteData_WidgetTable:
	res 7, (46918:16)	; resda	7, 0xb7e2 (v7 patched)

	push	xde

	push	xhl

	push	xix

	push	xiz

	ldw (36028:16), 65535

	calr	EffectMode_CheckTransposeChanged

	pop	xiz

	pop	xix

	pop	xhl

	pop	xde

	calr	BitMapOut_ApplyPatch_Return



BitMapOut_ApplyWidgetPatch:
	ld xhl, 0:i3
	ret

BitMapOut_ApplyPatch_SkipHeader:
	push	xiz
	calr	BitMapOut_ApplyPatch_Return
	ld	a, (36032:16)
	cp	a, 128
	jr	c, BitMapOut_ApplyPatch_Execute
	ldw	(36026:16), 0
	jr	BitMapOut_ApplyPatch_Done
BitMapOut_ApplyPatch_Execute:
	ld iz, 0:i3
	ldib_erp 0xfb, 0
	cp a, 0:i3
	jr ule, BitMapOut_ApplyPatch_Store

BitMapOut_ApplyPatch_Loop:
	ldto_berp	a, 251
	extz	wa
	call	AccVoice_GetChannelCount_Wrap
	extz	hl
	add	iz, hl
	inc	1, iz
	inc1b_erp	251
	ldto_berp	a, 251
	cp	a, (36032:16)
	jr	c, BitMapOut_ApplyPatch_Loop
BitMapOut_ApplyPatch_Store:
	ld	a, (36034:16)
	extz	wa
	ld	bc, iz
	add	bc, wa
	sll	bc, 2
	inc	2, bc
	ld	(36026:16), bc
BitMapOut_ApplyPatch_Done:
	pop xiz
	ret

BitMapOut_ApplyPatch_Return:
	push QIZ
	ld XWA,0x00028000
	call AcApcToggleProc_Helper
	ldfr_berp l, 251
	ld xwa, 163841
	call AcApcToggleProc_Helper
	lda_d16 xbc, (36942)
	ldto_berp a, 251
	ld (xbc), a
	ld (xbc+1), l
	ld (xbc+2), 72
	push xde
	push xhl
	push xix
	push xiz
	call Rhythm_DispatchNote_Finalize
	pop xiz
	pop xix
	pop xhl
	pop xde
	lda_d16 xwa, (36946)
	ld (36032), (xwa)
	ld (36034), (xwa+1)
	pop qiz
	ret
BitMapOut_ByteData_PatchTable:
	push xiz
	lda xhl, (0xf9b6:16)
	lda xix, (0xf9a0:16)
	ld xbc, xhl
	sub xbc, xix
	lda xde, (0x03c2c4:24)
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
	orb_erp C, 0xf4
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
	lda xhl, (0xf9d0:16)
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
	orb_erp C, 0xf4
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
	lda xhl, (0xf9ea:16)
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
	orb_erp C, 0xf4
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
	lda xhl, (0xfb56:16)
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
	lda xhl, (0xfb70:16)
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
	lda xhl, (0xfb8a:16)
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
	lda xhl, (0xfba4:16)
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
	lda xhl, (0xfbbe:16)
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
	lda xhl, (0xfc26:16)
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
	lda xhl, (0xfc32:16)
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
	lda xhl, (0xfc3e:16)
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
	lda xhl, (0xfc5e:16)
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	res 6, c
	ld (xhl), c
	orb_erp C, 0xf4
	ld (xhl), c
	ld c, (xwa + 76)
	and c, 0x1f
	ldfr_berp C, 0xf4
	lda xhl, (0xfc66:16)
	ld xbc, xhl
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	and c, 0xe0
	ld (xiz), c
	orb_erp C, 0xf4
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
	orb_erp C, 0xf4
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
	orb_erp C, 0xf4
	ld (xhl), c
	lda xhl, (0xfc74:16)
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
	lda xhl, (0xfc8e:16)
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
	lda xhl, (0xfc6f:16)
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	and c, 0x3f
	ld (xhl), c
	orb_erp C, 0xf4
	ld (xhl), c
	lda xhl, (0xfcc2:16)
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
	lda xhl, (0xfd02:16)
	ld xbc, xhl
	sub xbc, xix
	ld xiz, xbc
	add xiz, xde
	ld c, (xiz)
	res 2, c
	ld (xiz), c
	orb_erp C, 0xf4
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
	orb_erp A, 0xf4
	ld (xbc), a
	pop xiz
	ret

