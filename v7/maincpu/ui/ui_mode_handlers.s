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
	lda_d16 xbc, (0xfd05)
	lda_d16 xhl, (0xf9a0)
	sub xbc, xhl
	lda_24 xde, (0x03c2c4)
	add xbc, xde
	cp (xbc), 0x3
	jr nz, EffectMode_CopyVoiceParams_Done
	lda_d16 xix, (0xfa04)
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


EffectMode_ByteData_Block1:
	.incbin "includes/generated/v7_transplant_EffectMode_ByteData_Block1.bin"
EffectMode_ByteData_Block2:
	.incbin "includes/generated/v7_transplant_EffectMode_ByteData_Block2.bin"
EffectMode_ByteData_Block3:
	.incbin "includes/generated/v7_transplant_EffectMode_ByteData_Block3.bin"
EffectMode_ByteData_Block4:
	.incbin "includes/generated/v7_transplant_EffectMode_ByteData_Block4.bin"
EffectMode_ApplyTranspose:
	.incbin "includes/generated/v7_transplant_EffectMode_ApplyTranspose.bin"
EffectMode_ApplyTranspose_StoreTimer:
	.incbin "includes/generated/v7_transplant_EffectMode_ApplyTranspose_StoreTimer.bin"
EffectMode_CheckTransposeAndLookup:
	.incbin "includes/generated/v7_transplant_EffectMode_CheckTransposeAndLookup.bin"
SndParam_LoadTransposeValues:
	.incbin "includes/generated/v7_transplant_SndParam_LoadTransposeValues.bin"
EffectMode_TimerCountdown:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerCountdown.bin"
EffectMode_TimerCountdown_CheckMode:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerCountdown_CheckMode.bin"
EffectMode_TimerCountdown_ResBit7:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerCountdown_ResBit7.bin"
EffectMode_TimerCountdown_SetBit7:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerCountdown_SetBit7.bin"
EffectMode_CheckTransposeChanged:
	.incbin "includes/generated/v7_transplant_EffectMode_CheckTransposeChanged.bin"
EffectMode_TransposeInvalid:
	.incbin "includes/generated/v7_transplant_EffectMode_TransposeInvalid.bin"
EffectMode_ProcessPresetChange:
	.incbin "includes/generated/v7_transplant_EffectMode_ProcessPresetChange.bin"
EffectMode_ProcessPresetChange_CheckBit7:
	.incbin "includes/generated/v7_transplant_EffectMode_ProcessPresetChange_CheckBit7.bin"
EffectMode_ProcessPresetChange_Apply:
	.incbin "includes/generated/v7_transplant_EffectMode_ProcessPresetChange_Apply.bin"
EffectMode_ProcessPresetChange_Done:
	.incbin "includes/generated/v7_transplant_EffectMode_ProcessPresetChange_Done.bin"
EffectMode_CopyParamByte:
	lda_d16	xwa, (0xfa07)
	lda_d16	xde, (0xf9a0)
	sub	xwa, xde
	lda_24	xbc, (0x3c2c4)
	ld	xhl, xwa
	add	xhl, xbc
	lda_d16	xwa, (0xfba7)
	sub	xwa, xde
	add	xwa, xbc
	ld	a, (xwa)
	ld	(xhl), a
	ret

EffectMode_ClampAndLookupPreset:
	cp wa, 0x3e8
	jr ule, EffectMode_ClampAndLookup_Clamped
	lds wa, 1

EffectMode_ClampAndLookup_Clamped:
	.incbin "includes/generated/v7_transplant_EffectMode_ClampAndLookup_Clamped.bin"
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
	.incbin "includes/generated/v7_transplant_EffectMode_DisplayPresetName.bin"
EffectMode_DisplayName_ValidMode:
	.incbin "includes/generated/v7_transplant_EffectMode_DisplayName_ValidMode.bin"
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
	ld xwa, 0x986000
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
	.incbin "includes/generated/v7_transplant_EffectMode_DisplayName_Render.bin"
EffectMode_DisplayName_Done:
	popw iz
	ret

EffectMode_SearchPresetTableC2C5:
	lds ix, 0
	lda_24 xhl, (WidgetStyleDataTable_0x36E)

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
	lds ix, 0
	lda_24 xhl, (WidgetStyleDataTable_0x4FA)

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
	ld xhl, 0xffffffff
	ret

EffectMode_UpdateDisplay:
	.incbin "includes/generated/v7_transplant_EffectMode_UpdateDisplay.bin"
EffectMode_UpdateDisplay_NoPatch:
	calr EffectMode_UpdateBitFlags

EffectMode_UpdateDisplay_CopyVoice:
	ld xwa, xiz
	calr EffectMode_CopyVoiceParams
	pop xiz
	ret

EffectMode_UpdateBitFlags:
	.incbin "includes/generated/v7_transplant_EffectMode_UpdateBitFlags.bin"
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
	.incbin "includes/generated/v7_transplant_EffectMode_BackupParamBlock.bin"
EffectMode_CopyHoldPedalBits:
	.incbin "includes/generated/v7_transplant_EffectMode_CopyHoldPedalBits.bin"
EffectMode_SetRegionAndHold:
	push xiz
	ld xiz, xbc
	ld h, (xwa + 3)
	ld a, h
	and a, 0x7
	jr nz, EffectMode_SetRegion_Apply
	call Get_Region_Code
	ldb h, 0xa
	cps l, 2
	jr nz, EffectMode_SetRegion_Apply
	ldb h, 0x9

EffectMode_SetRegion_Apply:
	.incbin "includes/generated/v7_transplant_EffectMode_SetRegion_Apply.bin"
EffectMode_CheckPedalType:
	.incbin "includes/generated/v7_transplant_EffectMode_CheckPedalType.bin"
EffectMode_SendPedalType_Bank1:
	.incbin "includes/generated/v7_transplant_EffectMode_SendPedalType_Bank1.bin"
EffectMode_PopIzRet:
	pop xiz
	ret

EffectMode_Nop:
	ret

EffectMode_CopyPresetBits:
	.incbin "includes/generated/v7_transplant_EffectMode_CopyPresetBits.bin"
EffectMode_ReinitSoundOutput:
	.incbin "includes/generated/v7_transplant_EffectMode_ReinitSoundOutput.bin"
EffectMode_ReinitSound_NotifyBank1:
	ld xwa, 0x302
	lds bc, 1
	lds de, 0

EffectMode_ReinitSound_CallNotify:
	.incbin "includes/generated/v7_transplant_EffectMode_ReinitSound_CallNotify.bin"
EffectMode_ReinitWithFlag:
	.incbin "includes/generated/v7_transplant_EffectMode_ReinitWithFlag.bin"
EffectMode_CheckModeAndReinit:
	.incbin "includes/generated/v7_transplant_EffectMode_CheckModeAndReinit.bin"
SndOutput_ReinitByMode:
	.incbin "includes/generated/v7_transplant_SndOutput_ReinitByMode.bin"
SndOutput_ReinitByMode_TypeA:
	calr SndOutput_ReinitByMode_NotifyParam
	ret

SndOutput_ReinitByMode_TypeB:
	.incbin "includes/generated/v7_transplant_SndOutput_ReinitByMode_TypeB.bin"
SndOutput_ReinitByMode_Restore:
	.incbin "includes/generated/v7_transplant_SndOutput_ReinitByMode_Restore.bin"
SndOutput_ReinitByMode_NotifyParam:
	.incbin "includes/generated/v7_transplant_SndOutput_ReinitByMode_NotifyParam.bin"
SndOutput_ReinitByMode_CheckBit3:
	.incbin "includes/generated/v7_transplant_SndOutput_ReinitByMode_CheckBit3.bin"
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
	ldw bc, 0xc000
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
	muls wa, 0xa
	lda_24 xbc, (WidgetStyleDataTable_0x6FC)
	stb_dri B, 0x07, 0xe4, 0xe0
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
	muls bc, 0xa
	lda_24 xde, (WidgetStyleDataTable_0x706)
	stb_dri B, 0x07, 0xe8, 0xe4
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
	ldib_erp 0xe2, 0

RomTest_ProgramTableData_OuterLoop:
	ld xhl, LED_patterns_indicating_firmware_version
	lds32 xix, 0

RomTest_ProgramTableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	stb_dri H, 0x07, 0xe4, 0xf4
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
	ldib_erp 0xe2, 0

RomTest_TableData_OuterLoop:
	ld xhl, 0x800000
	lds32 xix, 0

RomTest_TableData_SumLoop:
	stb_erp A, 0xe2
	extz wa
	sla wa, 1
	ld iy, wa
	stb_dri H, 0x07, 0xe4, 0xf4
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
	stb_dri B, 0x07, 0xf0, 0xe4
	ld bc, (xde)
	ldw_erp BC, 0xe2
	ld_spiw BC, 0xf5
	addw_erp BC, 0xe2
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
	lda_24 xix, (WidgetStyleDataTable_0x6DA)
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
	cp hl, 0xffff
	jr nz, CustomRomTest_PrepareChecksum
	setm 1, (xsp + 6)

CustomRomTest_PrepareChecksum:
	lda xhl, (xsp + 2)
	ldw (xhl), 0x0
	lda xde, (xhl + 2)
	ldw (xde), 0x0
	ldib_erp 0xe2, 0

CustomRomTest_OuterLoop:
	ld xix, 0x300000
	lds32 xiy, 0

CustomRomTest_SumLoop:
	stb_erp A, 0xe2
	extz wa
	add wa, wa
	stb_dri A, 0x07, 0xec, 0xe0
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
	ldw wa, 0x3c3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cps l, 0
	jr z, LcdTest_WriteOneVerify
	setm 2, (xsp)

LcdTest_WriteOneVerify:
	; equivalent to "_VGA_WRITE 3c3h, 1" but with CALL instead of CALR
	ldw wa, 0x3c3
	lds bc, 1
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
	call _Read_VGA_Register

	cps l, 1
	jr z, LcdTest_WriteZeroVerify
	setm 2, (xsp)

LcdTest_WriteZeroVerify:
	; equivalent to "_VGA_WRITE 3c3h, 0" but with CALL instead of CALR
	ldw wa, 0x3c3
	lds bc, 0
	call _Write_VGA_Register

	; equivalent to "_VGA_READ 3c3h" but with CALL instead of CALR
	ldw wa, 0x3c3
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
	ldl_da xhl, (WidgetStyleDataTable)
	call (xhl)
	stiw_da (0x1a0000), 0x5a5a; VRAM self-test pattern 1
	calr DramTest_Loop
	cpw_da (0x1a0000), 0x5a5a
	jr z, VramTest_Pattern2
	setm 3, (xsp)

VramTest_Pattern2:
	stiw_da (0x1a0004), 0xa5a5; VRAM self-test pattern 2
	calr DramTest_Loop
	cpw_da (0x1a0004), 0xa5a5
	jr z, VramTest_Pattern3
	setm 3, (xsp)

VramTest_Pattern3:
	stiw_da (0x1a0008), 0x5a5a
	calr DramTest_Loop
	cpw_da (0x1a0008), 0x5a5a
	jr z, VramTest_Done
	setm 3, (xsp)

VramTest_Done:
	ld l, (xsp)
	extz hl
	inc 2, xsp
	ret

SelfTest_FirmwareVersionCheck:
	.incbin "includes/generated/v7_transplant_SelfTest_FirmwareVersionCheck.bin"
SelfTest_InterCPU_Send:
	.incbin "includes/generated/v7_transplant_SelfTest_InterCPU_Send.bin"
SelfTest_WaitBitLoop_Copy:
	ld xiy, 0x620
	ld xix, 0x620
	ldiw
	sub xwa, 0x1
	jr z, SelfTest_WaitDone_CountBits

SelfTest_WaitBitLoop_Check:
	bitda 7, (1568)
	jr nz, SelfTest_WaitBitLoop_Copy

SelfTest_WaitDone_CountBits:
	ldib_erp 0xfa, 0
	ldib_erp 0xfb, 0

SelfTest_CountBits_Loop:
	.incbin "includes/generated/v7_transplant_SelfTest_CountBits_Loop.bin"
SelfTest_CheckBit2:
	bit 2, c
	jr z, SelfTest_CheckBit4
	bitm 6, (xwa)
	jr z, SelfTest_CheckBit4
	ldw wa, 0xf5
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit4:
	inc 5, xde
	bit 4, c
	jr z, SelfTest_CheckBit5
	bitm 0, (xde)
	jr z, SelfTest_CheckBit5
	ldw wa, 0xf6
	call UI_PostModeChangeEvent
	call SubCPU_PayloadErrorStore
	jrl EffectMode_PopRetFA

SelfTest_CheckBit5:
	bit 5, c
	jr z, SelfTest_CheckBit7
	bitm 1, (xde)
	jr z, SelfTest_CheckBit7
	ldw wa, 0xf7
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBit7:
	bit 7, c
	jr z, SelfTest_CheckBitA1
	bitm 3, (xde)
	jr z, SelfTest_CheckBitA1
	ldw wa, 0xf8
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA1:
	ld a, (xwa)
	bit 1, a
	jr z, SelfTest_CheckBitA3
	bitm 5, (xde)
	jr z, SelfTest_CheckBitA3
	ldw wa, 0xf9
	jr EffectMode_UIPostModeChangeEvent

SelfTest_CheckBitA3:
	bit 3, a
	jrl z, EffectMode_PopRetFA
	bitm 7, (xde)
	jrl z, EffectMode_PopRetFA
	ldw wa, 0xfc

EffectMode_UIPostModeChangeEvent:
	call UI_PostModeChangeEvent

SelfTest_Diagnostic_Skip:
	jrl EffectMode_PopRetFA

SelfTest_SramAndRom:
	.incbin "includes/generated/v7_transplant_SelfTest_SramAndRom.bin"
SelfTest_SramAndRom_CheckROM:
	.incbin "includes/generated/v7_transplant_SelfTest_SramAndRom_CheckROM.bin"
SelfTest_PostRomError:
	.incbin "includes/generated/v7_transplant_SelfTest_PostRomError.bin"
EffectMode_PopRetFA:
	popw_erp 0xfa
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
	.incbin "includes/generated/v7_transplant_EffectMode_CheckAndDispatch.bin"
EffectMode_CheckAndDispatch_Bit4Clear:
	.incbin "includes/generated/v7_transplant_EffectMode_CheckAndDispatch_Bit4Clear.bin"
EffectMode_ResetDiagMode:
	.incbin "includes/generated/v7_transplant_EffectMode_ResetDiagMode.bin"
EffectMode_DispatchUpdate:
	.incbin "includes/generated/v7_transplant_EffectMode_DispatchUpdate.bin"
EffectMode_InitSwbWr_DiagMode:
	.incbin "includes/generated/v7_transplant_EffectMode_InitSwbWr_DiagMode.bin"
EffectMode_RestoreSwbWr_NormalMode:
	.incbin "includes/generated/v7_transplant_EffectMode_RestoreSwbWr_NormalMode.bin"
EffectMode_HandleTimerEvents:
	.incbin "includes/generated/v7_transplant_EffectMode_HandleTimerEvents.bin"
EffectMode_TimerEvent_Step1E:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Step1E.bin"
EffectMode_TimerEvent_Step3C:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Step3C.bin"
EffectMode_TimerEvent_Step5A:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Step5A.bin"
EffectMode_TimerEvent_Step78:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Step78.bin"
EffectMode_TimerEvent_Step96:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Step96.bin"
EffectMode_TimerEvent_Default:
	.incbin "includes/generated/v7_transplant_EffectMode_TimerEvent_Default.bin"
EffectMode_RunDiagSequence:
	.incbin "includes/generated/v7_transplant_EffectMode_RunDiagSequence.bin"
EffectMode_DiagSeq_AnimFrame:
	.incbin "includes/generated/v7_transplant_EffectMode_DiagSeq_AnimFrame.bin"
EffectMode_DiagSeq_IncFrame:
	.incbin "includes/generated/v7_transplant_EffectMode_DiagSeq_IncFrame.bin"
EffectMode_DiagSeq_SetDelay:
	.incbin "includes/generated/v7_transplant_EffectMode_DiagSeq_SetDelay.bin"
EffectMode_DiagSeq_DecrementDelay:
	.incbin "includes/generated/v7_transplant_EffectMode_DiagSeq_DecrementDelay.bin"
EffectMode_ByteData_DiagEvents:
	.incbin "includes/generated/v7_transplant_EffectMode_ByteData_DiagEvents.bin"
Voice_EmitNoteWithVelocity:
	.incbin "includes/generated/v7_transplant_Voice_EmitNoteWithVelocity.bin"
EffectMode_ModeChangeTransition:
	.incbin "includes/generated/v7_transplant_EffectMode_ModeChangeTransition.bin"
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
	lda_24 xbc, (WidgetStyleDataTable_0x6BA)
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
	lds bc, 0
	call Set_LEDs
	inc1b_erp 0xfb

LED_SetAll_BlankLoop:
	stb_erp A, 0xfb
	extz wa
	add wa, wa
	lda_24 xbc, (WidgetStyleDataTable_0x6BA)
	ldw_sri WA, 0x07, 0xe4, 0xe0
	cp wa, 0xffff
	jr nz, LED_SetAll_BlankOne
	popw_erp 0xfa
	ret


FDC_CommandAndPostEvent:
	.incbin "includes/generated/v7_transplant_FDC_CommandAndPostEvent.bin"
FDC_PostEvent_Error:
	ld xwa, 0xffffffff
	ld xbc, 0x01c0001e
	lds32	xde, 1
FDC_PostEvent_Send:
	call ApPostEvent
	lda	xsp, (xsp+16)
	ret


EffectMode_MidiParseLoop:
	.incbin "includes/generated/v7_transplant_EffectMode_MidiParseLoop.bin"
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
	lda_24 xde, (WidgetStyleDataTable_0x55A)
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
	lda_24 xix, (TEST2FUNC_DispatchReturn)
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST2FUNC event dispatch return (6-entry, event 0x1c00013)
TEST2FUNC_DispatchReturn:
	calr	0xfdd8

TableDispatch_Return3:
	lds32 xhl, 0
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
	lda_24 xix, (TEST3FUNC_DispatchReturn)
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST3FUNC event dispatch return (6-entry, event 0x1c00013)
TEST3FUNC_DispatchReturn:
	calr	0xfe19

TableDispatch_Return4:
	lds32 xhl, 0
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
	lda_24 xix, (TEST4FUNC_DispatchReturn)
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST4FUNC event dispatch return (6-entry, event 0x1c00013)
TEST4FUNC_DispatchReturn:
	calr	0xfe22

TableDispatch_Return5:
	lds32 xhl, 0
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
	lda_24 xix, (TEST6FUNC_DispatchReturn)
	jp_ind 8, 0x07, 0xf0, 0xe8
; TEST6FUNC event dispatch return (6-entry, event 0x1c00013)
TEST6FUNC_DispatchReturn:
	calr	0xfe7e

TableDispatch_Return:
	lds32 xhl, 0
	ret

BitmapFinpic_ByteData:
	.incbin "includes/generated/v7_transplant_BitmapFinpic_ByteData.bin"
BitmapFinpic:
	cp xbc, 0x1e000a3
	jr z, BitmapFinpic_GetHeight
	cp xbc, 0x1e000a2
	jr z, BitmapFinpic_GetWidth
	cp xbc, 0x1e000a1
	jr z, BitmapFinpic_GetDataPtr
	lds32 xhl, 0
	ret

BitmapFinpic_GetDataPtr:
	lda_24 xhl, (Bitmap_FadeInPicture)
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
	lds32 xhl, 0
	ret

BitmapFinst_GetDataPtr:
	lda_24 xhl, (Bitmap_FadeInText)
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
	lds32 xhl, 0
	ret

BitmapFoutpic_GetDataPtr:
	lda_24 xhl, (Bitmap_FadeOutPicture)
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
	lds32 xhl, 0
	ret

BitmapFoutst_GetDataPtr:
	lda_24 xhl, (Bitmap_FadeOutText)
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
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009e
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1c00014
	ld xde, 0x1800001
	call PostEvent

SystemInitMD_ReturnZero:
	lds32 xhl, 0
	ret

SystemInitOkFunc:
	ld xwa, 0x410002
	ld xbc, 0x1e00090
	lds32 xde, 0
	call SendEvent
	exts xhl
	stl_da (0x0340de), xhl
	cpib_da (0x0340ea), 0x00
	jr nz, SystemInitOk_PostEvent
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	ld xde, xhl
	call MainFuncCall
	jr SystemInitOk_ReturnZero

SystemInitOk_PostEvent:
	ld xwa, 0x410007
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent

SystemInitOk_ReturnZero:
	lds32 xhl, 0
	ret

SysIniNoFunc:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00041
	call PostEvent
	lds32 xhl, 0
	ret

SysIniYesFunc:
	ldl_da xde, (0x0340de)
	ld xwa, 0x142000a
	ld xbc, 0x1e20013
	call MainFuncCall
	lds32 xhl, 0
	ret

SysSureShowHideFunc:
	lds32 xhl, 0
	ret

AttnLngCheck:
	cp xbc, 0x1e0009f
	jr nz, AttnLngCheck_ReturnZero
	lda_24 xhl, (NoteStr3_Blank_3_0x4)
	ret

AttnLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SysSureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SysSureLngCheck_ReturnZero
	lda_24 xhl, (Str_Attention_EN_0xC)
	ret

SysSureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

SureLngCheck:
	cp xbc, 0x1e0009f
	jr nz, SureLngCheck_ReturnZero
	lda_24 xhl, (Str_InitSettingWarn_IT_0x19A)
	ret

SureLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

CtlIniLngCheck:
	cp xbc, 0x1e0009f
	jr nz, CtlIniLngCheck_ReturnZero
	lda_24 xhl, (Str_AreYouSure_IT_0x46)
	ret

CtlIniLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemNormLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemNormLngCheck_ReturnZero
	lda_24 xhl, (Str_FactoryResetDesc_EN3_0x156)
	ret

PmemNormLngCheck_ReturnZero:
	lds32 xhl, 0
	ret

PmemExpLngCheck:
	cp xbc, 0x1e0009f
	jr nz, PmemExpLngCheck_ReturnZero
	lda_24 xhl, (Str_StoreSoundBalance_DE_0x58)
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
; === v7-specific block: AcMstStyleAlp_Boundary (497 bytes) ===
AcMstStyleAlp_Boundary:
	.incbin "includes/generated/v7_block_acmststylealp_boundary.bin"
; === end v7 block ===
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	.incbin "includes/generated/v7_transplant_MasterSetup_DialTurn_ScrollUp.bin"
MasterSetup_ScrollUp_Overflow:
	.incbin "includes/generated/v7_transplant_MasterSetup_ScrollUp_Overflow.bin"
MasterSetup_ScrollUp_UpdateView:
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	lds iz, 0
	jr MasterSetup_ScrollUp_Search_Check

MasterSetup_ScrollUp_Search_Loop:
	.incbin "includes/generated/v7_transplant_MasterSetup_ScrollUp_Search_Loop.bin"
MasterSetup_ScrollUp_Search_Check:
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 78)
	ld wa, (xwa)
	ldw bc, 0x3e8
	sub bc, wa
	cp iz, bc
	jr c, MasterSetup_ScrollUp_Search_Loop

MasterSetup_ScrollUp_Search_Done:
	.incbin "includes/generated/v7_transplant_MasterSetup_ScrollUp_Search_Done.bin"
MasterSetup_DialDown_Underflow:
	.incbin "includes/generated/v7_transplant_MasterSetup_DialDown_Underflow.bin"
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
	.incbin "includes/generated/v7_transplant_MasterSetup_DialDown_Search_Loop.bin"
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	decm 1, (xwa)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	.incbin "includes/generated/v7_transplant_MasterSetup_FallbackEvent.bin"
MstStyleAlp_OverflowCopy:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_OverflowCopy.bin"
MstStyleAlp_UpdateFocusIndex:
	ld xwa, (xsp + 8)
	ld xbc, (xwa + 74)
	ld a, (xsp + 12)
	extz wa
	ld (xbc), wa
	lds iz, 0
	jr MstStyleAlp_CompareLoopCond

MstStyleAlp_CompareEntry:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_CompareEntry.bin"
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
	lds32 xde, 0
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
	incm 1, (xbc)
	ld xwa, (xsp + 74)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lds wa, 1

MasterSetup_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp2

MasterSetup_GetNameA:
	.incbin "includes/generated/v7_transplant_MasterSetup_GetNameA.bin"
MasterSetup_GetNameB_DrawString:
	.incbin "includes/generated/v7_transplant_MasterSetup_GetNameB_DrawString.bin"
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
	lda_24 xix, (MstStyleAlp_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyleAlpGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d58)
MstStyleAlp_EventDispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
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
	lda_24	xbc, (StyleSong_MasterTable_0x4)
	ld_rrw	de, xbc, de
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	call	MainFuncCall
	jrl	408

MstStyleAlp_CellSelect:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_CellSelect.bin"
MstStyleAlp_AppendPadChar:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_AppendPadChar.bin"
MstStyleAlp_PadLoopCond:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_PadLoopCond.bin"
MstStyleAlp_OverflowStr:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_OverflowStr.bin"
MstStyleAlp_CopyEntryAndPad:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_CopyEntryAndPad.bin"
MstStyleAlp_AppendPadChar2:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_AppendPadChar2.bin"
MstStyleAlp_PadLoopCond2:
	.incbin "includes/generated/v7_transplant_MstStyleAlp_PadLoopCond2.bin"
MstStyleAlp_FinalSendEvent:
	ld wa, (xsp + 50)
	cps wa, 1
	jr nz, EffectMode_SendEvent_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 50)
	ld xbc, 0x1e0008c
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
	lda_24 xix, (MstStyle_EventDispatch)
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
	lds32 xde, 0
	call SendEvent
	ld xwa, (xiz + 78)
	ldw (xwa), 0x1
	ld xwa, (xiz + 74)
	ldw (xwa), 0xa
	ld xwa, (xsp + 16)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ld iy, hl
	ld xwa, (xiz + 82)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	add wa, iy
	stw_da (0x0340c4), xwa
	jrl SeqFileAlt_ReturnZeroJmp
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
	muls wa, 0xa
	dec 1, wa
	stw_da (0x0340c4), xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lds32 xde, 0
	jr MstStyle_DialDown_PostEvent

MstStyle_DialDown_Decrement:
	decdi16_24 1, (0x340c4)
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
	lds32 xde, 0

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
	muls wa, 0xa
	sub wa, 0xa
	stw_da (0x0340c4), xwa
	ld xwa, (xsp + 16)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lds32 xde, 0
	jrl MstStyle_DialUp_PostEvent

MstStyle_DialUp_Increment:
	incdi16_24 1, (0x340c4)
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
	lds32 xde, 0
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
	incdi16_24 1, (0x340c4)
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
	lds32 xde, 0

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
	.incbin "includes/generated/v7_transplant_MstStyle_GetName_Load.bin"
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
	cp xbc, 0x1e0008d
	jr z, MstStyle1Grid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1Grid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1Grid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0xFE
	ld wa, (xwa)
	lda_24 xix, (MstStyle1Grid_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1GridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0d8a)
MstStyle1Grid_EventDispatch:
	jrl	t, 0x0167

MstStyle1Grid_CellSelect:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_CellSelect.bin"
MstStyle1Grid_PadLeft_Loop:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_PadLeft_Loop.bin"
MstStyle1Grid_PadLeft_Check:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_PadLeft_Check.bin"
MstStyle1Grid_OutOfRange:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_OutOfRange.bin"
MstStyle1Grid_BottomSection:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_BottomSection.bin"
MstStyle1Grid_PadLeft_LoopB:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_PadLeft_LoopB.bin"
MstStyle1Grid_PadLeft_CheckB:
	.incbin "includes/generated/v7_transplant_MstStyle1Grid_PadLeft_CheckB.bin"
MstStyle1Grid_CheckPlayAudio:
	ld wa, (xsp + 30)
	cps wa, 1
	jr nz, MstStyle1Grid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 30)
	ld xbc, 0x1e0008c
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
	lda_24 xix, (MstStyle1_EventDispatch)
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
	lds32 xde, 0
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
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 58)
	or xwa, xwa
	jrl nz, SeqFile_ReturnZeroJmp
	ldw_da xwa, (0x0340c4)
	extz xwa
	sll xwa, 3
	lda_24 xbc, (StyleGroup_LatinDance_Table)
	add xbc, xwa
	ld xde, (xbc)
	stl_da (0x0340d2), xde
	ldb c, 0x0

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
	cps c, 0
	jr z, MstStyle1Sub_CountEntries_Adjust
	dec 1, c

MstStyle1Sub_CountEntries_Adjust:
	ldw_da xwa, (0x0340c4)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	stw_da (0x0340c6), xwa
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
	ldw_da xwa, (0x0340c6)
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
	ldw_da xwa, (0x0340c6)
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
	ldw_da xwa, (0x0340c4)
	extz xwa
	sll xwa, 3
	lda_24 xbc, (StyleGroup_LatinDance_Table)
	add xbc, xwa
	ld xde, (xbc)
	stl_da (0x0340d2), xde
	ldb c, 0x0

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
	cps c, 0
	jr z, MstStyle1Sub_SubSel_Adjust
	dec 1, c

MstStyle1Sub_SubSel_Adjust:
	ldw_da xwa, (0x0340c4)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld a, (xde)
	extz wa
	stw_da (0x0340c6), xwa
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
	ldw_da xwa, (0x0340c6)
	extz xwa
	div wa, 0xa
	inc 1, wa
	ld (xbc), wa
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000b
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
	ld xbc, 0x1e00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	lda_24 xbc, (0x0340c8)
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
	muls wa, 0xa
	dec 1, wa
	stw_da (0x0340c6), xwa
	ldw_da xde, (0x0340c4)
	extz xde
	add xbc, xde
	ld (xbc), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	ldw_da xwa, (0x0340c6)
	dec 1, wa
	stw_da (0x0340c6), xwa
	ldw_da xde, (0x0340c4)
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
	ld xbc, 0x1e00050
	ld xde, (xsp + 58)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle1Sub_DialUp_FallbackEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1e0008f
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
	add xde, 0xffff0000
	ldw_da xbc, (0x0340c6)
	ld wa, (xiy)
	cp wa, (xix)
	jr ge, MstStyle1Sub_DialUp_CheckLimit
	lda_24 xix, (0x0340c8)
	cp hl, 0x9
	jr nz, MstStyle1Sub_DialUp_Increment
	incm 1, (xiy)
	ld xwa, (xiz)
	ld wa, (xwa)
	muls wa, 0xa
	sub wa, 0xa
	stw_da (0x0340c6), xwa
	ldw_da xbc, (0x0340c4)
	extz xbc
	add xix, xbc
	ld (xix), a
	ld xwa, (xsp + 66)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	stw_da (0x0340c6), xbc
	ldw_da xwa, (0x0340c4)
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
	stw_da (0x0340c6), xbc
	ldw_da xwa, (0x0340c4)
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
	lds wa, 1

MstStyle1Sub_SetDialEnable:
	call SetDialEnable
	jrl SeqFile_ReturnZeroJmp

MstStyle1Sub_GetNameA:
	.incbin "includes/generated/v7_transplant_MstStyle1Sub_GetNameA.bin"
MstStyle1Sub_GetNameB_DrawString:
	.incbin "includes/generated/v7_transplant_MstStyle1Sub_GetNameB_DrawString.bin"
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
	cp xbc, 0x1e0008d
	jr z, MstStyle1SubGrid_CellSelect
	lds32 xhl, 0
	sub xwa, 0x1c00017
	cp xwa, 0x0
	jrl lt, MstStyle1SubGrid_Epilogue
	cp xwa, 0x6
	jrl gt, MstStyle1SubGrid_Epilogue
	add xwa, xwa
	add xwa, Str_StoreTotalSetting_DE_0x136
	ld wa, (xwa)
	lda_24 xix, (MstStyle1Sub_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; MstStyle1SubGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0dc2)
MstStyle1Sub_EventDispatch:
	jrl	t, 0x015b

MstStyle1SubGrid_CellSelect:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_CellSelect.bin"
MstStyle1SubGrid_PadLeft_Loop:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_PadLeft_Loop.bin"
MstStyle1SubGrid_PadLeft_Check:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_PadLeft_Check.bin"
MstStyle1SubGrid_OutOfRange:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_OutOfRange.bin"
MstStyle1SubGrid_BottomSection:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_BottomSection.bin"
MstStyle1SubGrid_PadLeft_LoopB:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_PadLeft_LoopB.bin"
MstStyle1SubGrid_PadLeft_CheckB:
	.incbin "includes/generated/v7_transplant_MstStyle1SubGrid_PadLeft_CheckB.bin"
MstStyle1SubGrid_CheckPlayAudio:
	ld wa, (xsp + 26)
	cps wa, 1
	jr nz, MstStyle1SubGrid_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 26)
	ld xbc, 0x1e0008c
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
	lda_24 xix, (MstStyle1Page_EventDispatch)
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
	lds32 xde, 0
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
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 48)
	cp xwa, 0x4
	jrl z, MstStyle2_HandleSpecialEvent
	cp xwa, 0x3
	jrl z, MstStyle2_HandleSpecialEvent
	or xwa, xwa
	jrl nz, SeqData_ReturnZero
	ldw_da xwa, (0x0340c4)
	extz xwa
	sll xwa, 3
	lda_24 xbc, (StyleGroup_LatinDance_Table)
	add xbc, xwa
	ld xde, (xbc)
	stl_da (0x0340d2), xde
	ldb c, 0x0

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
	ldw_da xwa, (0x0340c6)
	srl wa, 1
	inc 1, wa
	ld (xbc), wa
	ld xbc, (xhl + 86)
	ldw_da xwa, (0x0340c6)
	ld (xbc), wa
	ld xwa, (xhl + 90)
	ldw (xwa), 0x1
	ldw_da xwa, (0x0340c6)
	bit 0, wa
	jrl nz, MstStyle2_InitOdd_Setup
	extz xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340d6), xhl
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	ldw_da xwa, (0x0340c6)
	cp bc, wa
	jr ule, MstStyle2_InitDone_PostEvent
	inc 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xde, (xwa + 4)
	stl_da (0x0340da), xde
	ldb c, 0x0

MstStyle2_CountSubEntries_LoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
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
	ld xbc, 0x1c0000b
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000e
	ld xde, 0xffff0000
	jrl MstStyle2_SendEvent_Done

MstStyle2_InitOdd_Setup:
	dec 1, wa
	extz xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xde, (xwa + 4)
	stl_da (0x0340d6), xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopA:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
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
	ldw_da xwa, (0x0340c6)
	extz xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xde, (xwa + 4)
	stl_da (0x0340da), xde
	ldb c, 0x0

MstStyle2_InitOdd_CountLoopB:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
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
	ld xbc, 0x1c0000b
	lds32 xde, 0
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
	lds32 xde, 0
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
	lda_24 xbc, (0x0340c8)
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
	cps wa, 0
	jr z, MstStyle2_DialDown_PageDec
	decm 1, (xix)
	ldw_da xwa, (0x0340c4)
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
	decm 1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340d6), xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340da), xhl
	ldb c, 0x0

MstStyle2_PageDec_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	ldw_da xwa, (0x0340c4)
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	cps wa, 0
	jr nz, MstStyle2_DialUp_PageInc
	incm 1, (xiy)
	ldw_da xwa, (0x0340c4)
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
	incm 1, (xwa)
	ld xwa, (xhl)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340d6), xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	stw_da (0x0340bc), xwa
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	stw_da (0x0340be), xwa
	cpdm16_24 (0x340bc), xwa
	jr le, MstStyle2_DialUp_UpdateAndPost
	ld xwa, (xiy)
	ld wa, (xwa)
	sla wa, 1
	dec 1, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340da), xhl
	ldb c, 0x0

MstStyle2_PageInc_CountLoop2:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	ldw_da xwa, (0x0340c4)
	extz xwa
	ld xbc, 0x340c8
	add xbc, xwa
	ld xwa, (xde)
	ld wa, (xwa)
	ld (xbc), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lds32 xde, 0
	call SendEvent
	ld ix, hl
	lda_24 xbc, (0x0340c8)
	cps ix, 0
	jrl nz, MstStyle2_DialScrollUp_Middle
	ld xhl, (xsp + 8)
	lda xde, (xhl + 82)
	ld xwa, (xde)
	ld wa, (xwa)
	stw_da (0x0340bc), xwa
	cps wa, 1
	jrl le, MstStyle2_DialScroll_SetAutoInc
	lda xhl, (xhl + 86)
	ld xwa, (xhl)
	decm 1, (xwa)
	ldw_da xwa, (0x0340c4)
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
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340d6), xhl
	ldb c, 0x0

MstStyle2_DialScrollDown_CountLoop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	addda32_24 xwa, (0x340d2)
	ld xde, (xwa + 4)
	stl_da (0x0340da), xde
	ldb c, 0x0

MstStyle2_DialScrollDown_Count2Loop:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xe8, 0xe0
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
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	cps ix, 5
	jr nz, MstStyle2_DialScrollUp_Simple
	ld xhl, (xsp + 4)
	lda xde, (xhl + 86)
	ld xwa, (xde)
	decm 1, (xwa)
	ldw_da xwa, (0x0340c4)
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
	ld xbc, 0x1e00050
	ld xde, (xsp + 48)
	call SendEvent
	or xhl, xhl
	jrl z, MstStyle2_DialScroll_FallbackUp
	ld xwa, (xsp + 56)
	ld xbc, 0x1e0008f
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
	ldw_da xwa, (0x0340c4)
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
	stw_da (0x0340bc), xwa
	ld xwa, (xbc + 78)
	ld wa, (xwa)
	stw_da (0x0340be), xwa
	cpdm16_24 (0x340bc), xwa
	jrl ge, MstStyle2_DialScroll_AutoInc
	ld xwa, (xix)
	incm 1, (xwa)
	ld xwa, (xix)
	ld wa, (xwa)
	sla wa, 1
	dec 2, wa
	exts xwa
	sll xwa, 3
	addda32_24 xwa, (0x340d2)
	ld xiy, (xwa + 4)
	stl_da (0x0340d6), xiy
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopD:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xf4, 0xe0
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
	addda32_24 xwa, (0x340d2)
	ld xhl, (xwa + 4)
	stl_da (0x0340da), xhl
	ldb c, 0x0

MstStyle2_DialScroll_CountLoopE:
	ld a, c
	extz wa
	muls wa, 0x6
	ld_sril3 XWA, 0x07, 0xec, 0xe0
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
	ldw_da xwa, (0x0340c4)
	extz xwa
	ld xde, 0x340c8
	add xde, xwa
	ld xwa, (xbc)
	ld wa, (xwa)
	ld (xde), a
	ld xwa, (xsp + 56)
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	lds wa, 1

MstStyle2_SetDialEnable:
	call SetDialEnable
	jrl SeqData_ReturnZero

MstStyle2_GetNameA:
	.incbin "includes/generated/v7_transplant_MstStyle2_GetNameA.bin"
MstStyle2_GetNameB_DrawString:
	.incbin "includes/generated/v7_transplant_MstStyle2_GetNameB_DrawString.bin"
MstStyle2_NameB_DrawCurrent:
	.incbin "includes/generated/v7_transplant_MstStyle2_NameB_DrawCurrent.bin"
MstStyle2_NameB_DrawLower:
	.incbin "includes/generated/v7_transplant_MstStyle2_NameB_DrawLower.bin"
MstStyle2_NameB_Render:
	.incbin "includes/generated/v7_transplant_MstStyle2_NameB_Render.bin"
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
	lda_24 xix, (MstGrid2_ScrollJumpTable)
	jp_ind 8, 0x07, 0xf0, 0xe0

MstGrid2_ScrollJumpTable:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, 0x1e0008f
	lds32	xde, 0
	call	SendEvent
	ld	(xsp+62), xhl
	call	GetFocusObject
	ld	xwa, xhl
	call	GetViewInstance
	ld	xbc, (xsp+62)
	ld	(xsp+56), bc
	cps	bc, 4
	jr	ge, 42
	ld	xwa, (xhl+94)
	cp	bc, (xwa)
	jrl	gt, 683
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	addda32_24	xbc, (0x340d6)
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	jr	46
	ld	xwa, (xhl+98)
	ld	wa, (xwa)
	inc	5, wa
	cp	bc, wa
	jrl	gt, 637
	dec	5, bc
	ld	wa, bc
	exts	xwa
	ld	xbc, xwa
	add	xbc, xbc
	add	xbc, xwa
	add	xbc, xbc
	addda32_24	xbc, (0x340da)
	ld	de, (xbc+4)
	extz	xde
	ld	xwa, 0x142000d
	ld	xbc, 0x1e20018
	call	MainFuncCall
	jrl	596

MstGrid2_CellSelect:
	.incbin "includes/generated/v7_transplant_MstGrid2_CellSelect.bin"
MstGrid2_PadLeft_LoopA:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_LoopA.bin"
MstGrid2_PadLeft_CheckA:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_CheckA.bin"
MstGrid2_OutOfRange_LowCol:
	ld xwa, Str_StoreTotalSetting_DE_0x188
	jrl MstGrid2_CopyFallback

MstGrid2_UpperHalf:
	.incbin "includes/generated/v7_transplant_MstGrid2_UpperHalf.bin"
MstGrid2_PadLeft_LoopB:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_LoopB.bin"
MstGrid2_PadLeft_CheckB:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_CheckB.bin"
MstGrid2_OutOfRange_HighCol:
	ld xwa, Str_StoreTotalSetting_DE_0x1AC
	jrl MstGrid2_CopyFallback

MstGrid2_LowerSection:
	.incbin "includes/generated/v7_transplant_MstGrid2_LowerSection.bin"
MstGrid2_PadLeft_LoopC:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_LoopC.bin"
MstGrid2_PadLeft_CheckC:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_CheckC.bin"
MstGrid2_OutOfRange_LowCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1D0
	jrl MstGrid2_CopyFallback

MstGrid2_BottomRight:
	.incbin "includes/generated/v7_transplant_MstGrid2_BottomRight.bin"
MstGrid2_PadLeft_LoopD:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_LoopD.bin"
MstGrid2_PadLeft_CheckD:
	.incbin "includes/generated/v7_transplant_MstGrid2_PadLeft_CheckD.bin"
MstGrid2_OutOfRange_HighCol2:
	ld xwa, Str_StoreTotalSetting_DE_0x1F4
	jr MstGrid2_CopyFallback

MstGrid2_OutOfRange_BeyondMax:
	ld xwa, Str_StoreTotalSetting_DE_0x216

MstGrid2_CopyFallback:
	.incbin "includes/generated/v7_transplant_MstGrid2_CopyFallback.bin"
MstGrid2_CheckPlayAudio:
	ld wa, (xsp + 54)
	cps wa, 1
	jr nz, MstGrid2_Return
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 54)
	ld xbc, 0x1e0008c
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
	lds32 xde, 1
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
	incm 1, (xwa)
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
	decm 1, (xwa)
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
	lda_24 xix, (MstStyle2_EventDispatch)
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
	lds32 xde, 0
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
	lds wa, 1
	jrl TchSens_SetDialEnable
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
	lds32 xde, 0
	call SendEvent
	cps hl, 4
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
	lds wa, 1
	jrl TchSens_SetDialEnable
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
	lds32 xde, 0
	call SendEvent
	cps hl, 1
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
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_TchSens_GetName_Load.bin"
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
	lda_24 xix, (TchSensGrid_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; TchSensGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed0f08)
TchSensGrid_EventDispatch:
	.incbin "includes/generated/v7_transplant_TchSensGrid_EventDispatch.bin"
TchSensGrid_CellSelect:
	.incbin "includes/generated/v7_transplant_TchSensGrid_CellSelect.bin"
TchSensGrid_CheckCell_1_4:
	.incbin "includes/generated/v7_transplant_TchSensGrid_CheckCell_1_4.bin"
TchSensGrid_Cell_1_4_Render:
	.incbin "includes/generated/v7_transplant_TchSensGrid_Cell_1_4_Render.bin"
TchSensGrid_CheckCell_1_5:
	.incbin "includes/generated/v7_transplant_TchSensGrid_CheckCell_1_5.bin"
TchSensGrid_CheckCell_1_6:
	.incbin "includes/generated/v7_transplant_TchSensGrid_CheckCell_1_6.bin"
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
	lda_24 xix, (TchSens_EventDispatch)
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
	lds32 xde, 0
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
	lds wa, 1
	jrl FSWAss_SetDialEnable
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
	lds32 xde, 0
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
	lds wa, 1
	jrl FSWAss_SetDialEnable
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
	lds32 xde, 0
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
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_FSWAss_GetName_Load.bin"
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
	stb_dri L, 0xfd, 0xf8, 0xfe
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
	lda_24 xix, (FSWAssGrid_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; FSWAssGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1226)
FSWAssGrid_EventDispatch:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_EventDispatch.bin"
FSWAssGrid_CellSelect:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CellSelect.bin"
FSWAssGrid_CheckCell_1_3:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_3.bin"
FSWAssGrid_CheckCell_1_4:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_4.bin"
FSWAssGrid_CheckCell_1_5:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_5.bin"
FSWAssGrid_CheckCell_1_6:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_6.bin"
FSWAssGrid_CheckCell_1_7:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_7.bin"
FSWAssGrid_CheckCell_1_8:
	.incbin "includes/generated/v7_transplant_FSWAssGrid_CheckCell_1_8.bin"
AudioTable_SendEventAndContinue:
	call SendEvent

AudioTable_ReturnZero:
	lds32 xhl, 0
	pop xiz
	stb_dri L, 0xfd, 0x08, 0x01
	ret

AudioTable_FindMatchIndex:
	ldb l, 0x0
	lda_24 xde, (Str_StoreTotalSetting_DE_0x298)

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
	lda_24 xix, (FswAsIni_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe8
; FswAsIniFunc event dispatch (6-entry, event 0x1c00013, table 0xed1234)
FswAsIni_EventDispatch:
	calr	6
	calr	30

SeqLoadFunc_ReturnZero:
	lds32 xhl, 0
	ret

FSWAss_CheckAndNotify:
	.incbin "includes/generated/v7_transplant_FSWAss_CheckAndNotify.bin"
FSWAss_RefreshAllVoices:
	.incbin "includes/generated/v7_transplant_FSWAss_RefreshAllVoices.bin"
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
	cps bc, 2
	jr z, PmemPageCtl_OK_AdvanceTo2
	cps bc, 1
	jrl nz, SeqLoad_ReturnZeroJmp2
	incm 1, (xwa)
	stib_da (0x0340e2), 0x01
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_AdvanceTo2:
	cpib_da (0x0340e2), 0x01
	jr nz, PmemPageCtl_OK_ResetTo1
	stib_da (0x0340e2), 0x02
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr SeqLoad_PostEvent

PmemPageCtl_OK_ResetTo1:
	ldw (xwa), 0x1
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
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
	stib_da (0x0340e2), 0x02
	ld xwa, 0x450005
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0

SeqLoad_PostEvent:
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotateReverse:
	cpib_da (0x0340e2), 0x01
	jr nz, PmemPageCtl_OK_RotatePost
	decm 1, (xwa)
	ld xwa, 0x45000d
	ld xbc, 0x1c00002
	lds32 xde, 0
	call PostEvent
	ld xwa, 0x450005
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	jr SeqLoad_ReturnZeroJmp2

PmemPageCtl_OK_RotatePost:
	ld xwa, 0x45000d
	ld xbc, 0x1c00001
	lds32 xde, 0
	call PostEvent
	stib_da (0x0340e2), 0x01

SeqLoad_ReturnZeroJmp2:
	lds32 xhl, 0

PmemPageCtl_Epilogue:
	pop xiz
	inc 4, xsp
	ret
PmemPageCtl_Boundary:

AcPmExpFilterGridBoxProc:
	stb_dri L, 0xfd, 0xdc, 0xfe
	push xiz
	stl_dri XDE, 0xfd, 0x20, 0x01
	stl_dri XBC, 0xfd, 0x24, 0x01
	ld xiz, xwa
	ld_sril XBC, (xsp + 0x0124)
	cp xbc, 0x1c00007
	jrl z, PmExpFilter_OkHandler
	ld_sril XWA, (xsp + 0x0124)
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
	lda_24 xix, (PmemPageCtl_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4

; IvPmemWindowPageCtl event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1420)
PmemPageCtl_EventDispatch:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
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
	lds wa, 1
	jrl PmExpFilter_SetDialEnable

PmExpFilter_ShowHide:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1c0000e
	ld xde, 0xffff0002
	call SendEvent
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_Repaint:
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
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
	lds32 xde, 0
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
	lds32 xde, 0
	push xde
	pushw 0xfb
	pushw 0xf5
	ld xde, ParamStr02_Vocalist_0x20
	call DrawString
	ld (xsp + 10), 0x0
	cpib_da (0x0340e2), 0x01
	jrl nz, PmExpFilter_DrawCellBank2

PmExpFilter_DrawCellBank1:
	.incbin "includes/generated/v7_transplant_PmExpFilter_DrawCellBank1.bin"
PmExpFilter_DrawCellBank2:
	.incbin "includes/generated/v7_transplant_PmExpFilter_DrawCellBank2.bin"
PmExpFilter_DrawCentered:
	call DrawStringCentered
	jrl SeqLoad_ReturnZeroJmp
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	cpib_da (0x0340e2), 0x02
	jr nz, PmExpFilter_DecAndUpdate
	cps hl, 2
	jr nz, PmExpFilter_DecAndUpdate
	stib_da (0x0340e2), 0x01
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward:
	ld xwa, xiz
	ld xbc, 0x1e00091
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
	ld xbc, 0x1c00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1
	jrl PmExpFilter_SetDialEnable
	ld xwa, xiz
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1e00050
	ld_sril XDE, (xsp + 0x0120)
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_FallbackForward2
	ld xwa, xiz
	ld xbc, 0x1e0008f
	lds32 xde, 0
	call SendEvent
	ldb_da a, (0x0340e2)
	cps a, 2
	jr nz, PmExpFilter_CheckAdvBank
	cp hl, 0xa
	jrl z, SeqLoad_ReturnZeroJmp

PmExpFilter_CheckAdvBank:
	cps a, 1
	jr nz, PmExpFilter_IncAndUpdate
	cp hl, 0xa
	jr nz, PmExpFilter_IncAndUpdate
	stib_da (0x0340e2), 0x02
	ld xwa, xiz
	ld xbc, 0x1c0000f
	lds32 xde, 0
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
	ld_sril XBC, (xsp + 0x0124)
	ld_sril XDE, (xsp + 0x0120)
	call SetAutoInc
	jrl SeqLoad_ReturnZeroJmp

PmExpFilter_FallbackForward2:
	ld xwa, xiz
	ld xbc, 0x1e00091
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
	ld xbc, 0x1c00017
	ld_sril XDE, (xsp + 0x0120)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1c00018
	ld_sril XDE, (xsp + 0x0120)
	call SetDialDown
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_PmExpFilter_GetNameCommon.bin"
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
	cp xwa, 0xf
	jr nz, PmExpFilter_OK_InheritedFwd
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmExpFilter_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
	lds32 xde, 0
	call SendEvent
	jr PmExpFilter_OK_InheritedFwd

PmExpFilter_OK_Navigate:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
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
	stb_dri L, 0xfd, 0x24, 0x01
	ret

PmExpFilterGridCheck:
	stb_dri L, 0xfd, 0xf8, 0xfe
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
	lda_24 xix, (PmExpFilter_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; PmExpFilterGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed149a)
PmExpFilter_EventDispatch:
	.incbin "includes/generated/v7_transplant_PmExpFilter_EventDispatch.bin"
PmExpFilterCheck_CellDecode:
	.incbin "includes/generated/v7_transplant_PmExpFilterCheck_CellDecode.bin"
PmExpFilterCheck_SendNameA:
	.incbin "includes/generated/v7_transplant_PmExpFilterCheck_SendNameA.bin"
PmExpFilterCheck_AltDecode:
	.incbin "includes/generated/v7_transplant_PmExpFilterCheck_AltDecode.bin"
PmExpFilterCheck_PushNameB:
	push xwa
	push xbc
	jr PmExpFilterCheck_StrcpySend

PmExpFilterCheck_PushDefault:
	pushw 0xed
	pushw 0x1496
	push xde

PmExpFilterCheck_StrcpySend:
	.incbin "includes/generated/v7_transplant_PmExpFilterCheck_StrcpySend.bin"
PmExpFilterCheck_DoSend:
	call SendEvent

SeqLoad_StoreReturnZero:
	lds32 xhl, 0
	stb_dri L, 0xfd, 0x08, 0x01
	ret
PmExpFilterCheck_Boundary:

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
	lda_24 xix, (PmExpFilter2_EventDispatch)
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
	lds32 xde, 0
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
	lds wa, 1
	jrl DispTimeSet_SetDialEnabled

DispTimeSet_SelectInit:
	.incbin "includes/generated/v7_transplant_DispTimeSet_SelectInit.bin"
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
	lds wa, 1
	jrl DispTimeSet_SetDialEnabled
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
	lds32 xde, 0
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
	lds wa, 1

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
	.incbin "includes/generated/v7_transplant_DispTimeSet_GetNameCommon.bin"
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
	lda_24 xix, (DispTimeSet_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe0

; DispTimeSetGridCheck event dispatch (7-entry, events 0x1c00017-0x1c0001d, table 0xed1582)
DispTimeSet_EventDispatch:
	.incbin "includes/generated/v7_transplant_DispTimeSet_EventDispatch.bin"
DispTimeSetCheck_CellDecode:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_CellDecode.bin"
DispTimeSetCheck_TryRow3:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_TryRow3.bin"
DispTimeSetCheck_TryRow4:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_TryRow4.bin"
DispTimeSetCheck_TryRow5:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_TryRow5.bin"
DispTimeSetCheck_TryRow6:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_TryRow6.bin"
DispTimeSetCheck_TryRow7:
	.incbin "includes/generated/v7_transplant_DispTimeSetCheck_TryRow7.bin"
DispTimeSet_SendEventReturn:
	call SendEvent

DispTimeSet_ReturnZero:
	lds32 xhl, 0
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
	lds32 xhl, 0
	ret

MainTimeFlashFunc:
	.incbin "includes/generated/v7_transplant_MainTimeFlashFunc.bin"
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
	cp xwa, 0x1c00001
	jr z, NormScreen_InitHandler
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr NormScreen_Epilogue

NormScreen_InitHandler:
	.incbin "includes/generated/v7_transplant_NormScreen_InitHandler.bin"
NormScreen_ClearBit:
	.incbin "includes/generated/v7_transplant_NormScreen_ClearBit.bin"
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
	.incbin "includes/generated/v7_transplant_IvWindowPgCtl_Init.bin"
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
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_Deselect:
	ld xwa, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x5
	jr ge, IvWindowPgCtl_DisableFunc
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	jrl UI_MainFuncCall_Execute

IvWindowPgCtl_DisableFunc:
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
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
	cp xwa, 0xf
	jrl z, IvWindowPgCtl_JumpToEnd
	cp xwa, 0x8f
	jrl nz, IvWindowPgCtl_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x4
	jr ge, IvWindowPgCtl_TryNextPage
	incm 1, (xwa)
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
	call MainFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	ld de, (xwa)
	exts xde
	ld xwa, 0xffffffff
	ld xbc, 0x1c0001e
	jr IvWindowPgCtl_SendPageEvent

IvWindowPgCtl_TryNextPage:
	.incbin "includes/generated/v7_transplant_IvWindowPgCtl_TryNextPage.bin"
IvWindowPgCtl_SetNextPage:
	ld xbc, (xbc)
	ld (xbc), wa
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
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
	lds32 xde, 0

UI_MainFuncCall_Execute:
	call MainFuncCall
	jr IvWindowPgCtl_ReturnZero

IvWindowPgCtl_JumpToEnd:
	.incbin "includes/generated/v7_transplant_IvWindowPgCtl_JumpToEnd.bin"
IvWindowPgCtl_JumpToStart:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 22)
	cpw (xwa), 0x1
	jr z, IvWindowPgCtl_ReturnZero
	ldw (xwa), 0x1
	ld xwa, 0x1400001
	ld xbc, 0x1e000ab
	lds32 xde, 1
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
	lds32 xde, 0
	jrl IvPageOverWr_SendAndReturn

IvPageOverWr_GetName:
	.incbin "includes/generated/v7_transplant_IvPageOverWr_GetName.bin"
IvPageOverWr_PageSelect:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageSelect2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
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
	ld xbc, 0x1c00001
	lds32 xde, 0
	jr IvPageOverWr_SendAndReturn

IvPageOverWr_PageChanged:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 24)
	ld xbc, 0x1e00094
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, IvPageOverWr_PageChanged2
	ld xwa, (xiz + 24)
	ld xbc, 0x1c00002
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
	ld xbc, 0x1c00001
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
	.incbin "includes/generated/v7_transplant_PmNamingCheck.bin"
PmNaming_GetKeyLayout:
	ld xhl, 0x10
	jrl PmNaming_Epilogue

PmNaming_HandleKeyPress:
	.incbin "includes/generated/v7_transplant_PmNaming_HandleKeyPress.bin"
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
	lds32 xde, 1
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
	sub xbc, 0x1e0003e
	cp xbc, 0x0
	jrl lt, MssName_ReturnZero
	cp xbc, 0x9
	jrl gt, MssName_ReturnZero
	add xbc, xbc
	add xbc, FadeTimeStr_Off_0x62
	ld bc, (xbc)
	lda_24 xix, (MssName_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4
; MssNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ac)
MssName_EventDispatch:
	.incbin "includes/generated/v7_transplant_MssName_EventDispatch.bin"
MssName_ReturnZero:
	lds32 xhl, 0
	pop xiz
	inc 4, xsp
	ret
MssName_Boundary:

AcPmBkNoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
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
	.incbin "includes/generated/v7_transplant_AcPmBkNoBox_Match.bin"
AcPmBkNoBox_FormatBankNo:
	.incbin "includes/generated/v7_transplant_AcPmBkNoBox_FormatBankNo.bin"
AcPmBkNoBox_SendConfirm:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_AcPmBkNoBoxProc_Return:
	lds32 xhl, 0

AcPmBkNoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
AcPmBkNoBox_Boundary:

AcBkNoBoxProc:
	stb_dri L, 0xfd, 0xfc, 0xfe
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
	.incbin "includes/generated/v7_transplant_AcBkNoBox_Match.bin"
UI_AcBkNoBoxProc_Return:
	lds32 xhl, 0

AcBkNoBox_Epilogue:
	pop xiz
	stb_dri L, 0xfd, 0x04, 0x01
	ret
AcBkNoBox_Boundary:

MsaModeScreenProc:
	.incbin "includes/generated/v7_transplant_MsaModeScreenProc.bin"
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
	lds32 xde, 0
	jr MsaMode_DispatchSelect

MsaMode_Paint:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	ld xbc, 0x1c0000e
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
	lda_24 xbc, (NakaInst_Rock_Pop_0x2C)
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
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 44)
	lda_24 xbc, (NakaInst_Rock_Pop_0x2C)
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
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, MsaMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
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
	stb_dri L, 0xfd, 0xe8, 0xfe
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
	ld xbc, 0x1c0000e
	lds32 xde, 0
	jrl PmemMode_DispatchSelect

PmemMode_Paint:
	.incbin "includes/generated/v7_transplant_PmemMode_Paint.bin"
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
	lda_24 xbc, (NakaInst_Rock_Pop_0x30)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri C, 0xfd, 0x08, 0x01
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
	lds bc, 1
	lds de, 2
	call DrawDesignFrame
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 36)
	lda_24 xbc, (NakaInst_Rock_Pop_0x30)
	ld wa, (xwa)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x08, 0x01
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x0c, 0x01
	stb_dri C, 0xfd, 0x08, 0x01
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
	cp xwa, 0x8b
	jr z, PmemMode_OK_Cmd8B
	cp xwa, 0x89
	jr z, PmemMode_OK_Cmd89
	cp xwa, 0xf
	jr nz, PmemMode_OK_DefaultForward
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e0007a
	lds32 xde, 0
	call SendEvent
	or xhl, xhl
	jr z, PmemMode_OK_Navigate
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e00079
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
	ld xwa, 0xffffffff
	ld xbc, 0x1c00015
	ld xde, 0x1a00040
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
	stb_dri L, 0xfd, 0x18, 0x01
	ret
PmemMode_Boundary:

AcPmBkEditBoxProc:
	stb_dri L, 0xfd, 0xce, 0xfe
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
	ld_sril XWA, (xsp + 0x012e)
	ld (xwa), 0x0
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xwa, (xhl + 54)
	ld xwa, (xwa)
	ldb w, 0x0
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20010
	ld_sril XDE, (xsp + 0x012e)
	call MainFuncCall
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankChanged:
	.incbin "includes/generated/v7_transplant_AcPmBkEdit_BankChanged.bin"
AcPmBkEdit_BankChanged_UpdateLoop:
	ld xwa, (xsp + 4)
	ld a, (xwa)
	sll a, 3
	addb_erp A, 0xfb
	ldb w, 0x0
	extz xwa
	stl_dri XWA, 0xfd, 0x2e, 0x01
	ld xwa, 0x1420008
	ld xbc, 0x1e20012
	ld_sril XDE, (xsp + 0x012e)
	call MainFuncCall
	inc1b_erp 0xfb
	cp_erpb 0xfb, 0x08
	jr ule, AcPmBkEdit_BankChanged_UpdateLoop
	jrl AcPmBkEdit_ReturnZero

AcPmBkEdit_BankEdit:
	.incbin "includes/generated/v7_transplant_AcPmBkEdit_BankEdit.bin"
AcPmBkEdit_BankEdit_DrawDiff:
	lds32 xbc, 0
	push xbc
	pushw 0xff
	pushw 0xf5
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
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
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
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 24), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00046
	lds32 xde, 0
	call ApFuncCall
	lda xwa, (xsp + 24)
	ld (xwa + 4), hl
	ld_sril XBC, (xsp + 0x012e)
	ld (xwa + 14), xbc
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00043
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 30), xhl
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 50)
	ld xbc, 0x1e00044
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
	ld xbc, 0x1e00045
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 8), xhl
	ld xwa, (xiz + 50)
	ld xbc, 0x1e00046
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
	ld xbc, 0x1e00045
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
	ld xbc, 0x1c0000f
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
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollUp:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
	jrl AcPmBkEdit_DispatchAndReturn

AcPmBkEdit_ScrollDown:
	ld_sril XWA, (xsp + 0x0132)
	ld_sril XDE, (xsp + 0x012e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0132)
	call GetViewInstance
	ld xiz, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003e
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
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
	ld xbc, 0x1e0003c
	ld_sril XDE, (xsp + 0x012e)
	call SendEvent
	or xhl, xhl
	jrl z, AcPmBkEdit_ReturnZero
	ld xwa, (xiz + 50)
	ld xbc, 0x1e0003f
	lds32 xde, 0
	call ApFuncCall
	cpl hl
	cplw_erp 0xee
	inc 1, xhl
	ld_sril XWA, (xsp + 0x0132)
	ld xbc, 0x1e0003d
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
	lds32 xde, 1
	jrl AcPmBkEdit_OK_NavComplete

AcPmBkEdit_OK_Load:
	.incbin "includes/generated/v7_transplant_AcPmBkEdit_OK_Load.bin"
AcPmBkEdit_OK_LoadEmpty:
	.incbin "includes/generated/v7_transplant_AcPmBkEdit_OK_LoadEmpty.bin"
AcPmBkEdit_OK_SaveDelete:
	ld xwa, 0xffffffff
	ld xbc, 0x1c00016
	ld xde, 0x1a000d0
	call PostEvent
	call GetTitleNow
	ld xwa, xhl
	ld xbc, 0x1e000aa
	lds32 xde, 0
	call SendEvent
	cps hl, 0
	jr z, AcPmBkEdit_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, 0x1e0009a
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
	stb_dri L, 0xfd, 0x32, 0x01
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
	lda_24 xix, (PmBkName_EventDispatch)
	jp_ind 8, 0x07, 0xf0, 0xe4
; PmBkNameFunc event dispatch (10-entry, event 0x1c00013, table 0xed15ee)
PmBkName_EventDispatch:
	ret
	lds32	xhl, 1
	ret
	ld	xhl, 9
	ret

PmBkName_ReturnZero:
	lds32 xhl, 0
	ret

PmBkName_DataBytes:
	.incbin "includes/generated/v7_transplant_PmBkName_DataBytes.bin"
GmOnOffFunc:
	.incbin "includes/generated/v7_transplant_GmOnOffFunc.bin"
GmOnOff_Return0xC0:
	ld xhl, 0xc0
	jrl VariScreen_CleanupRet

GmOnOff_Return1:
	lds32 xhl, 1
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
	lds32 xde, 3
	jr GmOnOff_SendAndReturn

GmOnOff_CheckDesign:
	.incbin "includes/generated/v7_transplant_GmOnOff_CheckDesign.bin"
GmOnOff_SendHideEvent:
	ld xwa, 0xffffffff
	ld xbc, 0x1c20006
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
	stb_dri L, 0xfd, 0xca, 0xfd
	push xiz
	stl_dri XDE, 0xfd, 0x2e, 0x02
	stl_dri XBC, 0xfd, 0x32, 0x02
	stl_dri XWA, 0xfd, 0x36, 0x02
	ld_sril XWA, (xsp + 0x0232)
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
	ld xbc, 0x1c0000b
	lds32 xde, 0
	jrl VariScreen_SendAndReturn

VariScreen_HandleShow:
	.incbin "includes/generated/v7_transplant_VariScreen_HandleShow.bin"
VariScreen_CallInherited:
	call InheritedProc
	jrl FileBrowser_ReturnZero

VariScreen_HandlePaint:
	.incbin "includes/generated/v7_transplant_VariScreen_HandlePaint.bin"
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
	lda_24 xhl, (0x03f214)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
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
	ldw (xbc), 0x137

VariScreen_DrawDesignArea:
	.incbin "includes/generated/v7_transplant_VariScreen_DrawDesignArea.bin"
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
	lda_24 xde, (0x03f214)
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
	lda_24 xde, (0x03f214)
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
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawDefaultVoice

VariScreen_DrawNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
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
	.incbin "includes/generated/v7_transplant_VariScreen_DrawNameString.bin"
VariScreen_SetRightVoiceBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
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
	stb_dri C, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
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
	stb_dri B, 0xfd, 0x22, 0x01
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
	divs wa, 0xa
	inc 1, wa
	cp wa, (xde)
	jrl nz, FileBrowser_ReturnZero
	ld e, (xsp + 8)
	srl e, 1
	extz de
	sla de, 2
	lda_24 xhl, (0x03f214)
	ld wa, (xbc)
	exts xwa
	divs wa, 0xa
	stw_erp BC, 0xe2
	ld_sril3 XWA, 0x07, 0xec, 0xe8
	ldb_sri A, 0x07, 0xe0, 0xe4
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
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
	ldw (xbc), 0x137

VariScreen_DrawRightDesignBox:
	.incbin "includes/generated/v7_transplant_VariScreen_DrawRightDesignBox.bin"
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
	lda_24 xhl, (0x03f214)
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
	lda_24 xde, (0x03f214)
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
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_DrawRightNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_DrawRightDefaultVoice

VariScreen_DrawRightNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
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
	.incbin "includes/generated/v7_transplant_VariScreen_DrawRightNameString.bin"
VariScreen_SetRightVoiceRightBounds:
	ldw (xhl), 0xab
	ldw (xwa), 0x137

VariScreen_DrawRightVoiceString:
	stb_dri B, 0xfd, 0x22, 0x01
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
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri A, 0xfd, 0x22, 0x02
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
	stb_dri C, 0xfd, 0x22, 0x01
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
	.incbin "includes/generated/v7_transplant_VariScreen_HandleConfirm.bin"
VariScreen_ConfirmRowReady:
	ld (xsp + 10), 0x0
	cp (xsp + 8), 0x0
	jrl c, FileBrowser_ReturnZero

VariScreen_ConfirmLoopBody:
	.incbin "includes/generated/v7_transplant_VariScreen_ConfirmLoopBody.bin"
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
	lda_24 xde, (0x03f214)
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
	lda_24 xde, (0x03f214)
	ld l, (xsp + 10)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 16)
	ld xiz, (xwa + 56)
	stb_dri E, 0xfd, 0x26, 0x02
	stb_dri D, 0xfd, 0x22, 0x02
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
	.incbin "includes/generated/v7_transplant_VariScreen_ConfirmDrawNameAudio.bin"
VariScreen_ConfirmSetVoiceRightBounds:
	ldw (xwa), 0xab
	ldw (xbc), 0x137

VariScreen_ConfirmDrawVoiceString:
	stb_dri C, 0xfd, 0x22, 0x01
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
	stb_dri B, 0xfd, 0x22, 0x01
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
	lda_24 xde, (0x03f214)
	ld_sril XWA, (xsp + 0x022e)
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
	lda_24 xde, (0x03f214)
	ld_sril XWA, (xsp + 0x022e)
	ld l, (xwa)
	extz hl
	ld_sril3 XWA, 0x07, 0xe8, 0xe4
	ldb_sri A, 0x07, 0xe0, 0xec
	extz wa
	stb_dri A, 0xfd, 0x22, 0x02
	call GetEditSwPoint
	ld xwa, (xsp + 24)
	ld xwa, (xwa + 56)
	cpw (xwa), 0x10
	jr z, VariScreen_EnumDrawNameLabel
	cpw (xwa), 0x11
	jrl nz, VariScreen_EnumDrawDefaultVoice

VariScreen_EnumDrawNameLabel:
	stb_dri B, 0xfd, 0x26, 0x02
	stb_dri C, 0xfd, 0x22, 0x02
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
	.incbin "includes/generated/v7_transplant_VariScreen_EnumDrawNameAudio.bin"
VariScreen_EnumSetVoiceRightBounds:
	ldw (xwa), 0xab
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
	stb_dri W, 0xfd, 0x26, 0x02
	stb_dri B, 0xfd, 0x22, 0x02
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
	ld_sril XBC, (xsp + 0x022e)
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
	muls wa, 0xa
	sub wa, 0xa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0x9
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	dec 8, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	dec 7, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	dec 6, wa
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	muls wa, 0xa
	sub wa, 0xa
	ld de, wa
	add de, hl
	ld xwa, (xbc + 60)
	ld (xwa), de
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000e
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
	divs wa, 0xa
	inc 1, wa
	cp (xbc), wa
	jr ge, VariScreen_OK_PageScrollWrap
	incm 1, (xbc)
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jr VariScreen_OK_PageSendEvent

VariScreen_OK_PageScrollWrap:
	cps wa, 1
	jr le, VariScreen_OK_PageScrollDown
	ldw (xbc), 0x1
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
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
	ld xbc, 0x1c0000d
	lds32 xde, 0
	jr VariScreen_OK_PageDownSendEvent

VariScreen_OK_PageScrollDownWrap:
	ld xwa, (xsp + 16)
	ld xwa, (xwa + 52)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
	inc 1, wa
	cps wa, 1
	jr le, VariScreen_OK_ForwardToInherited
	ld (xbc), wa
	ld_sril XWA, (xsp + 0x0236)
	ld xbc, 0x1c0000d
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
	stb_dri L, 0xfd, 0x36, 0x02
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
	.incbin "includes/generated/v7_transplant_RVariScreenProc.bin"
RVari_Init_TypeNotE:
	ld xbc, (xiz + 44)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0xa
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
	.incbin "includes/generated/v7_transplant_RVari_Paint.bin"
RVari_Select:
	.incbin "includes/generated/v7_transplant_RVari_Select.bin"
RVari_Select_CheckSameBank:
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, (NakaInst_Rock_Pop_0x24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, (NakaInst_Rock_Pop_0x24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri B, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xa3
	ldw (xde + 4), 0xbe
	decm 8, (xbc)
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	sla wa, 2
	lda_24 xbc, (ParamStr_Table_04)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x164e
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	stb_dri C, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
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
	stb_dri C, 0xfd, 0x14, 0x02
	lda xde, (xhl + 2)
	ld wa, (xde)
	add wa, 0xc
	ld (xde), wa
	stb_dri A, 0xfd, 0x18, 0x02
	sub wa, 0xf
	ld (xbc + 2), wa
	ld wa, (xde)
	add wa, 0x10
	ld (xbc + 6), wa
	ldw (xbc), 0xb7
	ldw (xbc + 4), 0x14b
	stb_dri B, 0xfd, 0x14, 0x01
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
	stw_erp WA, 0xe2
	lda_24 xbc, (NakaInst_Rock_Pop_0x24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0xa3
	ldw (xwa + 4), 0x137
	ldw bc, 0xc1
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
	pushw 0xd
	push xhl
	stb_dri W, 0xfd, 0x1a, 0x01
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	stib_ind 0xfd, 0x21, 0x01, 0x00
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, (NakaInst_Rock_Pop_0x24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	call DrawEditSw
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	lda_24 xbc, (NakaInst_Rock_Pop_0x24)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri B, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x16, 0x02
	ld wa, (xbc)
	sub wa, 0xf
	ld (xde + 2), wa
	ld wa, (xbc)
	add wa, 0x10
	ld (xde + 6), wa
	ldw (xde), 0xa3
	ldw (xde + 4), 0xbe
	decm 8, (xbc)
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	stw_erp WA, 0xe2
	sla wa, 2
	lda_24 xbc, (ParamStr_Table_04)
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	pushw 0xed
	pushw 0x1652
	lda xwa, (xsp + 28)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xde, (xsp + 20)
	lds32 xhl, 3
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	add de, 0xc
	ld (xhl), de
	stb_dri W, 0xfd, 0x18, 0x02
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0xb7
	ldw (xwa + 4), 0x14b
	stb_dri B, 0xfd, 0x14, 0x01
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0x7
	call DrawStringLeftJustify
	ld xwa, (xiz + 64)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, (NakaInst_Rock_Pop_0x28)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	lds bc, 0
	ldw de, 0xf5
	call DrawDesignBox
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2d
	ldw (xwa + 4), 0xac
	ld xde, (xiz + 64)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, (SeqChan_Map_2ch_0x2)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 1
	push xhl
	pushw 0xff
	pushw 0xf7
	call DrawStringLeftJustify
	ld xwa, (xiz + 60)
	ld wa, (xwa)
	exts xwa
	divs wa, 0x4
	lda_24 xbc, (NakaInst_Rock_Pop_0x28)
	ldb_sri A, 0x07, 0xe4, 0xe0
	extz wa
	stb_dri A, 0xfd, 0x14, 0x02
	call GetEditSwPoint
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri B, 0xfd, 0x16, 0x02
	ld bc, (xde)
	sub bc, 0xf
	ld (xwa + 2), bc
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ldw (xwa), 0x8
	ldw (xwa + 4), 0x9c
	ldw bc, 0xc1
	lds de, 7
	call DrawDesignBox
	stb_dri W, 0xfd, 0x18, 0x02
	stb_dri A, 0xfd, 0x14, 0x02
	lda xhl, (xbc + 2)
	ld de, (xhl)
	sub de, 0xf
	ld (xwa + 2), de
	ld de, (xhl)
	add de, 0x10
	ld (xwa + 6), de
	ldw (xwa), 0x2d
	ldw (xwa + 4), 0xac
	ld xde, (xiz + 60)
	ld de, (xde)
	srl e, 2
	extz de
	sla de, 2
	lda_24 xhl, (SeqChan_Map_2ch_0x2)
	ld_sril3 XDE, 0x07, 0xec, 0xe8
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0xf7
	call DrawStringLeftJustify
	jrl RVari_Select_ReturnZero

	.include "ui/rvari_routines.s"
