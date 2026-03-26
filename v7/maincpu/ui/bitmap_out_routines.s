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
	ldb_erp A, 0xf4
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
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_RenderA.bin"
BitMapOut_ByteData_RenderB:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_RenderB.bin"
BitMapOut_ByteData_RenderC:
	lds	wa, 0
	jrl	302
BitMapOut_ByteData_RenderD:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_RenderD.bin"
BitMapOut_ByteData_RenderE:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_RenderE.bin"
BitMapOut_CheckDiskAndApply:
	.incbin "includes/generated/v7_transplant_BitMapOut_CheckDiskAndApply.bin"
BitMapOut_ByteData_DiskCheck:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_DiskCheck.bin"
BitMapOut_StorePresetValue:
	.incbin "includes/generated/v7_transplant_BitMapOut_StorePresetValue.bin"
BitMapOut_SetDefaultTimer:
	.incbin "includes/generated/v7_transplant_BitMapOut_SetDefaultTimer.bin"
BitMapOut_DecrementTimer:
	.incbin "includes/generated/v7_transplant_BitMapOut_DecrementTimer.bin"
BitMapOut_ByteData_TransitionSeq:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_TransitionSeq.bin"
BitMapOut_ByteData_PresetCopy:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_PresetCopy.bin"
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xbc, (0xf9b6)
	ld (xsp + 68), xbc
	lda xbc, (xbc + 14)
	sub xbc, xhl
	ld (xsp + 56), xbc
	extz wa
	sla wa, 2
	lda_24 xbc, (WidgetStyleDataTable_0x10)
	stb_dri A, 0x07, 0xe4, 0xe0
	ld xwa, (xbc)
	ld xix, (xsp + 56)
	add xix, xwa
	lda xde, (xsp + 72)
	ld a, (xix)
	ld (xde), a
	lda_d16 xwa, (0xf9d0)
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
	lda_d16 xix, (0xf9ea)
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
	stb_dpi D, 0xf8
	ld wa, iy
	extz xwa
	add xwa, (xsp + 82)
	ld a, (xwa)
	ld (xix), a
	inc 1, iy

BitMapOut_CopyPreset9_CheckEnd:
	lda_d16 xwa, (0xfd5e)
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
	.incbin "includes/generated/v7_transplant_BitMapOut_Snapshot_Clamp50.bin"
BitMapOut_Snapshot_Execute:
	.incbin "includes/generated/v7_block_bitmapout_snapshot_execute.bin"
; === end v7 block ===
BitMapOut_RestoreFull_FieldLoop:
	inc 1, xiy
	ldb_spi A, 0xf4
	ldb_erp A, 0xe6
	inc 1, xhl
	inc 1, xhl
	lds bc, 0
	stb_erp E, 0xe6
	extz de
	cps de, 0
	jr ule, BitMapOut_RestoreFull_FieldDone

BitMapOut_RestoreFull_CopyField:
	stb_erp A, 0xe6
	lds32 xiz, 0
	ldb_erp A, 0xf8
	lda_d16 xwa, (0xf9ce)
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
	ldb_spi A, 0xec
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
	.incbin "includes/generated/v7_transplant_BitMapOut_RestoreFull_CheckEnd.bin"
BitMapOut_CopyPresetTable_Loop:
	.incbin "includes/generated/v7_transplant_BitMapOut_CopyPresetTable_Loop.bin"
BitMapOut_CopyPresetTable_Check:
	lda_d16 xhl, (0xfc74)
	lda_d16 xwa, (0xfca6)
	sub xwa, xhl
	ld de, bc
	extz xde
	cp xde, xwa
	jr le, BitMapOut_CopyPresetTable_Loop
	lds bc, 0
	jr BitMapOut_CopyExtTable_Check

BitMapOut_CopyExtTable_Loop:
	.incbin "includes/generated/v7_transplant_BitMapOut_CopyExtTable_Loop.bin"
BitMapOut_CopyExtTable_Check:
	.incbin "includes/generated/v7_block_bitmapout_copyexttable_check.bin"
; === end v7 block ===
BitMapOut_CopyROMToWorkspace:
	.incbin "includes/generated/v7_transplant_BitMapOut_CopyROMToWorkspace.bin"
BitMapOut_SelectiveFieldRestore:
	lda xsp, (xsp - 14)
	push xiz
	lda_d16 xwa, (0xfd96)
	ld (xsp + 6), xwa
	inc 7, xwa
	ld (xsp + 14), xwa
	bitm 0, (xwa)
	jrl z, BitMapOut_SelectRestore_CheckBit1
	lda_d16 xde, (0xf9a0)
	lda_d16 xbc, (0xfc5a)
	ld xwa, xbc
	sub xwa, xde
	lda_24 xhl, (0x03c8e4)
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
	ldb_erp A, 0xf0
	res_erpb 0xf0, 0x04
	stb_erp A, 0xf0
	ld (xiy), a
	ld xwa, xiy
	sub xwa, xde
	add xwa, xhl
	ld w, (xwa)
	and w, 0x10
	stb_erp A, 0xf0
	or a, w
	ldb_erp A, 0xf0
	ld (xiy), a
	lda xiy, (xbc + 7)
	ld a, (xiy)
	ldb_erp A, 0xf0
	and_erpb 0xf0, 0xcf
	stb_erp A, 0xf0
	ld (xiy), a
	ld xwa, xiy
	sub xwa, xde
	add xwa, xhl
	ld w, (xwa)
	and w, 0x30
	stb_erp A, 0xf0
	or a, w
	ldb_erp A, 0xf0
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xde, (0xfc5a)
	lda xbc, (xde + 8)
	ld xwa, xbc
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xde, (0xfd02)
	ld c, (xde)
	and c, 0xfc
	ld (xde), c
	lda_d16 xhl, (0xf9a0)
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xbc, (0xfd04)
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, (0x03c8e4)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_SelectRestore_CheckBit4:
	ld xwa, (xsp + 14)
	bitm 4, (xwa)
	jr z, BitMapOut_SelectRestore_CheckVolBit
	lda_d16 xde, (0xfc5d)
	ld c, (xde)
	and c, 0xf0
	ld (xde), c
	lda_d16 xhl, (0xf9a0)
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
	add xwa, xix
	ld a, (xwa)
	and a, 0xf
	or c, a
	ld (xde), c
	lda_d16 xde, (0xfc69)
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xwa, (0xfc74)
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xwa, (0xfc8e)
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xiy, (0xf9b6)
	lda xix, (xiy + 12)
	ld l, (xix)
	and l, 0xf8
	ld (xix), l
	lda_d16 xbc, (0xf9a0)
	ld xwa, xix
	sub xwa, xbc
	lda_24 xde, (0x03c8e4)
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
	lda_d16 xiy, (0xf9d0)
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
	lda_d16 xiy, (0xf9ea)
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
	lda_d16 xiy, (0xfa04)
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
	lda_d16 xiy, (0xfa1e)
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
	lda_d16 xiy, (0xfa38)
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
	lda_d16 xiy, (0xfa52)
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
	lda_d16 xiy, (0xfa6c)
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
	lda_d16 xiy, (0xfa86)
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
	lda_d16 xiy, (0xfaa0)
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
	lda_d16 xiy, (0xfaba)
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
	lda_d16 xiy, (0xfad4)
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
	lda_d16 xiy, (0xfaee)
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
	lda_d16 xiy, (0xfb08)
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
	lda_d16 xiy, (0xfb22)
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
	lda_d16 xiy, (0xfb3c)
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
	lda_d16 xiy, (0xfb56)
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
	lda_d16 xiy, (0xfb70)
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
	lda_d16 xiy, (0xfb8a)
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
	lda_d16 xiy, (0xfba4)
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
	lda_d16 xiy, (0xfbbe)
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
	lda_d16 xiy, (0xfbd8)
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
	lda_d16 xiy, (0xfc0c)
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
	lda_d16 xiy, (0xfd50)
	lda_d16 xwa, (0xfd5e)
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
	lda_d16 xbc, (0xf9a0)
	ld iz, hl
	add iz, de
	lda_d16 xix, (0xfa04)
	extz xiz
	add xiz, xix
	ld xwa, xiz
	sub xwa, xbc
	lda_24 xiy, (0x03c8e4)
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
	ldb_erp A, 0xea
	and_erpb 0xea, 0x07
	stb_erp A, 0xea
	ld (xiz), a
	ld xwa, xiz
	sub xwa, xbc
	add xwa, xiy
	ld w, (xwa)
	and w, 0xf8
	stb_erp A, 0xea
	or a, w
	ldb_erp A, 0xea
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
	lda_d16 xwa, (0xfa1c)
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xwa, (0xfd1c)
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xwa, (0xfd30)
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xhl, (0xf9a0)
	lda_d16 xde, (0xfc54)
	lda xbc, (xde + 1)
	ld xwa, xbc
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
	add xwa, xix
	ld a, (xwa)
	ld (xbc), a
	ld xwa, xde
	sub xwa, xhl
	add xwa, xix
	ld a, (xwa)
	ld (xde), a
	lda_d16 xwa, (0xfcdc)
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
	lda_d16 xde, (0xf9a0)
	lda_d16 xix, (0xfd02)
	lda xbc, (xix + 5)
	ld xwa, xbc
	sub xwa, xde
	lda_24 xhl, (0x03c8e4)
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
	lda_d16 xbc, (0xfd12)
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, (0x03c8e4)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckPanBit:
	ld xwa, (xsp + 10)
	bitm 5, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckCtrlBit
	lda_d16 xbc, (0xfc6a)
	ld xde, xbc
	sub xde, 0xf9a0
	lda_24 xwa, (0x03c8e4)
	add xde, xwa
	ld a, (xde)
	ld (xbc), a

BitMapOut_RestoreExtra_CheckCtrlBit:
	ld xwa, (xsp + 10)
	bitm 6, (xwa)
	jr z, BitMapOut_RestoreExtra_CheckLevelBit
	lda_d16 xhl, (0xf9a0)
	lda_d16 xwa, (0xfc4a)
	lda_24 xix, (0x03c8e4)
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
	lda_d16 xde, (0xfc6f)
	ld c, (xde)
	res 6, c
	ld (xde), c
	lda_d16 xhl, (0xf9a0)
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
	add xwa, xix
	ld a, (xwa)
	and a, 0x40
	or c, a
	ld (xde), c
	lda_d16 xwa, (0xfcc2)
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
	lda_d16 xde, (0xfc6f)
	ld c, (xde)
	res 5, c
	ld (xde), c
	lda_d16 xhl, (0xf9a0)
	ld xwa, xde
	sub xwa, xhl
	lda_24 xix, (0x03c8e4)
	add xwa, xix
	ld a, (xwa)
	and a, 0x20
	or c, a
	ld (xde), c
	lda_d16 xwa, (0xfca8)
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
	.incbin "includes/generated/v7_transplant_BitMapOut_SaveDisplayToROM.bin"
BitMapOut_DetectChanges:
	.incbin "includes/generated/v7_transplant_BitMapOut_DetectChanges.bin"
BitMapOut_DetectChanges_CheckMode:
	.incbin "includes/generated/v7_transplant_BitMapOut_DetectChanges_CheckMode.bin"
BitMapOut_DetectChanges_UseShortList:
	.incbin "includes/generated/v7_transplant_BitMapOut_DetectChanges_UseShortList.bin"
BitMapOut_DetectChanges_FullScan:
	.incbin "includes/generated/v7_transplant_BitMapOut_DetectChanges_FullScan.bin"
BitMapOut_DeltaEncode_Init:
	lds iz, 0
	jrl BitMapOut_DeltaEncode_CheckBounds

BitMapOut_DeltaEncode_ReadEntry:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_ReadEntry.bin"
BitMapOut_DeltaEncode_ScanLoop:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_ScanLoop.bin"
BitMapOut_DeltaEncode_BufferFull:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_BufferFull.bin"
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
	lda_d16 xwa, (0xf9a0)
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
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_CheckBounds.bin"
BitMapOut_DeltaEncode_StoreShortLen:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_StoreShortLen.bin"
BitMapOut_DeltaEncode_Return:
	popw iz
	lda xsp, (xsp + 10)
	ret

BitMapOut_DispatchIOChanges:
	bitda 7, (0xf9c4)
	call_24 z, BitMapOut_ApplyIOChange_Port0
	bitda 7, (0xf9c7)
	call_24 z, BitMapOut_ApplyIOChange_Port3
	bitda 7, (0xf9de)
	call_24 z, BitMapOut_ApplyIOChange_Port1
	bitda 7, (0xf9e1)
	call_24 z, BitMapOut_ApplyIOChange_Port4
	bitda 7, (0xf9f8)
	call_24 z, BitMapOut_ApplyIOChange_Port2
	bitda 7, (0xf9fb)
	ret nz
	calr BitMapOut_ApplyIOChange_Port5
	ret

BitMapOut_ApplyIOChange_Port0:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port0.bin"
BitMapOut_ApplyIOChange_Port1:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port1.bin"
BitMapOut_ApplyIOChange_Port2:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port2.bin"
BitMapOut_ApplyIOChange_Port3:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port3.bin"
BitMapOut_ApplyIOChange_Port4:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port4.bin"
BitMapOut_ApplyIOChange_Port5:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyIOChange_Port5.bin"
BitMapOut_DeltaEncode_TypeDefault:
	dec 8, xsp
	push xiz
	ld (xsp + 8), de
	ld (xsp + 10), a
	ld hl, (xsp + 16)
	ld xiy, (xsp + 18)
	lda_d16 xix, (0xf9a0)
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
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_TypeDefaultB.bin"
BitMapOut_DeltaEncode_TypeDefaultC:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_TypeDefaultC.bin"
BitMapOut_DeltaEncode_HelperCheckEnd:
	extz xwa
	add xwa, xiy
	ld (xwa), 0xff

BitMapOut_DeltaEncode_HelperReturn:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_HelperReturn.bin"
BitMapOut_DeltaEncode_Type48Handler:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 16), de
	ld (xsp + 18), a
	ld hl, (xsp + 24)
	ld xde, (xsp + 26)
	lda_d16 xix, (0xf9a0)
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
	lda_d16 xiz, (0xfc5a)
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
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_Type48Loop.bin"
BitMapOut_DeltaEncode_Type48End:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_Type48End.bin"
BitMapOut_DeltaEncode_Type48Epilog:
	extz xwa
	add xwa, xde
	ld (xwa), 0xff

BitMapOut_DeltaEncode_Type48Return:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x6

BitMapOut_DeltaEncode_Type90Handler:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_Type90Handler.bin"
BitMapOut_DeltaEncode_Type90PartB:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_Type90PartB.bin"
BitMapOut_DeltaEncode_Type90Loop:
	.incbin "includes/generated/v7_transplant_BitMapOut_DeltaEncode_Type90Loop.bin"
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
	lda_24 xhl, (WidgetStyleDataTable_0x15E)
	add xhl, xbc
	lda xde, (xsp + 2)
	ld a, (xde)
	ldb_erp A, 0xf0
	extz ix
	ld xbc, (xhl)
	ld a, (xde + 1)
	lda_dri XBC, 0x07, 0xe4, 0xf0
	inc 1, iz
	cp iz, 0x17
	jr c, BitMapOut_DeltaEncode_Type90Final
	popw iz
	inc 6, xsp
	ret

BitMapOut_RefreshDisplay_CheckDirty:
	.incbin "includes/generated/v7_transplant_BitMapOut_RefreshDisplay_CheckDirty.bin"
BitMapOut_RefreshDisplay_ClearDirty:
	.incbin "includes/generated/v7_transplant_BitMapOut_RefreshDisplay_ClearDirty.bin"
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
	.incbin "includes/generated/v7_transplant_BitMapOut_RefreshDisplay_Commit.bin"
BitMapOut_CalcDisplayMetrics:
	.incbin "includes/generated/v7_transplant_BitMapOut_CalcDisplayMetrics.bin"
BitMapOut_CalcMetrics_ComputeGrid:
	.incbin "includes/generated/v7_transplant_BitMapOut_CalcMetrics_ComputeGrid.bin"
BitMapOut_CalcMetrics_Done:
	pop xiz
	ret

BitMapOut_PrepareRenderState:
	.incbin "includes/generated/v7_transplant_BitMapOut_PrepareRenderState.bin"
BitMapOut_PrepareRender_SetParams:
	.incbin "includes/generated/v7_transplant_BitMapOut_PrepareRender_SetParams.bin"
BitMapOut_PrepareRender_CheckBit0:
	pop xiz
	ret

BitMapOut_PrepareRender_CheckBit1:
	.incbin "includes/generated/v7_transplant_BitMapOut_PrepareRender_CheckBit1.bin"
BitMapOut_PrepareRender_CheckBit2:
	.incbin "includes/generated/v7_transplant_BitMapOut_PrepareRender_CheckBit2.bin"
BitMapOut_GetRenderMode:
	.incbin "includes/generated/v7_transplant_BitMapOut_GetRenderMode.bin"
BitMapOut_GetRenderMode_CheckBit3:
	.incbin "includes/generated/v7_transplant_BitMapOut_GetRenderMode_CheckBit3.bin"
BitMapOut_GetRenderMode_Return:
	.incbin "includes/generated/v7_transplant_BitMapOut_GetRenderMode_Return.bin"
BitMapOut_ByteData_RenderState:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_RenderState.bin"
BitMapOut_ByteData_DisplayUpdate:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_DisplayUpdate.bin"
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
	lda_24 xbc, (WidgetStyleDataTable_0x10)
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	pushw 0x10
	lda_d16 xwa, (0xf9a2)
	sub xwa, 0xf980
	sub xwa, 0x20
	add xwa, xbc
	push xwa

BitMapOut_UpdateWidget_TypeA:
	.incbin "includes/generated/v7_transplant_BitMapOut_UpdateWidget_TypeA.bin"
BitMapOut_UpdateWidget_TypeB:
	.incbin "includes/generated/v7_transplant_BitMapOut_UpdateWidget_TypeB.bin"
BitMapOut_UpdateWidget_PostDraw:
	.incbin "includes/generated/v7_transplant_BitMapOut_UpdateWidget_PostDraw.bin"
BitMapOut_UpdateWidget_Finalize:
	.incbin "includes/generated/v7_transplant_BitMapOut_UpdateWidget_Finalize.bin"
BitMapOut_UpdateWidget_Done:
	.incbin "includes/generated/v7_transplant_BitMapOut_UpdateWidget_Done.bin"
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
	lda_24 xix, (BitMapOut_ByteData_WidgetTable)
	jp_ind 8, 0x07, 0xf0, 0xe8
BitMapOut_ByteData_WidgetTable:
	.incbin "includes/generated/v7_transplant_BitMapOut_ByteData_WidgetTable.bin"
BitMapOut_ApplyWidgetPatch:
	lds32 xhl, 0
	ret

BitMapOut_ApplyPatch_SkipHeader:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyPatch_SkipHeader.bin"
BitMapOut_ApplyPatch_Execute:
	lds iz, 0
	ldib_erp 0xfb, 0
	cps a, 0
	jr ule, BitMapOut_ApplyPatch_Store

BitMapOut_ApplyPatch_Loop:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyPatch_Loop.bin"
BitMapOut_ApplyPatch_Store:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyPatch_Store.bin"
BitMapOut_ApplyPatch_Done:
	pop xiz
	ret

BitMapOut_ApplyPatch_Return:
	.incbin "includes/generated/v7_transplant_BitMapOut_ApplyPatch_Return.bin"
BitMapOut_ByteData_PatchTable:
	push xiz
	lda_d16 xhl, (0xf9b6)
	lda_d16 xix, (0xf9a0)
	ld xbc, xhl
	sub xbc, xix
	lda_24 xde, (0x03c2c4)
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
	ldb_erp C, 0xf4
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
	lda_d16 xhl, (0xf9d0)
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
	ldb_erp C, 0xf4
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
	lda_d16 xhl, (0xf9ea)
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
	ldb_erp C, 0xf4
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
	lda_d16 xhl, (0xfb56)
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
	lda_d16 xhl, (0xfb70)
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
	lda_d16 xhl, (0xfb8a)
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
	lda_d16 xhl, (0xfba4)
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
	lda_d16 xhl, (0xfbbe)
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
	lda_d16 xhl, (0xfc26)
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
	lda_d16 xhl, (0xfc32)
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
	lda_d16 xhl, (0xfc3e)
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
	ldb_erp C, 0xf4
	lda_d16 xhl, (0xfc5e)
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	res 6, c
	ld (xhl), c
	orb_erp C, 0xf4
	ld (xhl), c
	ld c, (xwa + 76)
	and c, 0x1f
	ldb_erp C, 0xf4
	lda_d16 xhl, (0xfc66)
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
	ldb_erp C, 0xf4
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
	ldb_erp C, 0xf4
	inc 3, xhl
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	res 0, c
	ld (xhl), c
	orb_erp C, 0xf4
	ld (xhl), c
	lda_d16 xhl, (0xfc74)
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
	lda_d16 xhl, (0xfc8e)
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
	ldb_erp C, 0xf4
	lda_d16 xhl, (0xfc6f)
	sub xhl, xix
	add xhl, xde
	ld c, (xhl)
	and c, 0x3f
	ld (xhl), c
	orb_erp C, 0xf4
	ld (xhl), c
	lda_d16 xhl, (0xfcc2)
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
	ldb_erp C, 0xf4
	lda_d16 xhl, (0xfd02)
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
	ldb_erp A, 0xf4
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

