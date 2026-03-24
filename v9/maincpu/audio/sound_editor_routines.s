; =============================================================================
; sound_editor_routines.asm - Sound Editor Mode Routines
; =============================================================================
; This file contains the Sound Editor title and mode functions for the KN5000.
;
; The Sound Editor provides deep control over synthesizer parameters:
;   - Tone: Waveform selection, hybrid/random tones
;   - Pitch: Pitch control, envelopes, LFO
;   - Amplitude: Volume, envelopes, LFO
;   - Filter: LPF, HPF, BPF, BCF, 24dB modes, envelopes, LFO
;   - Digital Effects: Effect parameters
;   - Controllers: MIDI controller mappings
;   - Copy/Write: Patch management
;
; Routines included:
;   SeMenuModeFunc, SeMenuTitleFunc   - Main menu
;   SeEasyTitleFunc                   - Easy edit mode
;   SeTonTon1/2TitleFunc              - Tone selection
;   SeTonRan1/2TitleFunc              - Random tone
;   SeTonHyb1TitleFunc                - Hybrid tone
;   SePitPit1TitleFunc                - Pitch control
;   SePitEnv1/2TitleFunc              - Pitch envelopes
;   SePitLfo1TitleFunc                - Pitch LFO
;   SeAmpAmp1/2TitleFunc              - Amplitude control
;   SeAmpEnv1/2TitleFunc              - Amplitude envelopes
;   SeAmpLfo1TitleFunc                - Amplitude LFO
;   SeFilLpq1TitleFunc                - Low-pass filter
;   SeFilHpq1TitleFunc                - High-pass filter
;   SeFilL241TitleFunc                - 24dB low-pass
;   SeFilH241TitleFunc                - 24dB high-pass
;   SeFilBpf1TitleFunc                - Band-pass filter
;   SeFilBcf1TitleFunc                - Band-cut filter
;   SeFilFil2TitleFunc                - Filter 2
;   SeFilEnv1/2TitleFunc              - Filter envelopes
;   SeFilLfo1TitleFunc                - Filter LFO
;   SeDigEffTitleFunc                 - Digital effects
;   SeCtr2/3TitleFunc                 - Controllers
;   SeCopyTitleFunc                   - Copy function
;   SeWrtMemTitleFunc                 - Write to memory
;   SeWrtSndTitleFunc                 - Write sound
;
; =============================================================================

SeMenuModeFunc:
	cp xbc, 0x1c00013
	ret nz
	cp xde, 0x1
	jr z, SeMenuModeFunc_Handler
	or xde, xde
	ret nz
	jp InitializeSeMenuDefaults

SeMenuModeFunc_Handler:
	call UpdateSeMenuSelection
	ret

SeMenuTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAD8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeMenuTitleFunc_DisplayData:
	jp	UpdSeSel_ProcessStep
	jp	SeMenu_CopyWriteUpdate_Data_0x212_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x582_
	jp	SeMenu_CopyWriteUpdate_Data_0x21C_

SeEasyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAE8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeEasyTitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data
	jp	SeMenu_CopyWriteUpdate_Data_0x34A_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1D4C_
	jp	SeMenu_CopyWriteUpdate_Data_0x354_

SeTonTon1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAF8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon1TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate
	jp	SeMenu_CopyWriteUpdate_Data_0x2A1_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD15_
	jp	SeMenu_CopyWriteUpdate_Data_0x2AB_

SeTonTon2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB08_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonTon2TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data
	jp	SeMenu_CopyWriteUpdate_Data_0x2AC_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD43_
	jp	SeMenu_CopyWriteUpdate_Data_0x2B6_

SeTonRan1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB18_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan1TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data_0xDC_
	jp	SeMenu_CopyWriteUpdate_Data_0x2B7_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD71_
	jp	SeMenu_CopyWriteUpdate_Data_0x2C1_

SeTonRan2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB28_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan2TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data_0x1BB_
	jp	SeMenu_CopyWriteUpdate_Data_0x2C2_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD9F_
	jp	SeMenu_CopyWriteUpdate_Data_0x2CC_

SeTonHyb1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB38_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonHyb1TitleFunc_DisplayData:
	jp	SeMenu_ControllerUpdate
	jp	SeMenu_CopyWriteUpdate_Data_0x2CD_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xDCD_
	jp	SeMenu_CopyWriteUpdate_Data_0x2D7_

SePitPit1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB48_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitPit1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xE1_
	jp	SeMenu_CopyWriteUpdate_Data_0x21D_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x0D_
	jp	SeMenu_CopyWriteUpdate_Data_0x227_

SePitEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB58_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x1F6_
	jp	SeMenu_CopyWriteUpdate_Data_0x228_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x3B_
	jp	SeMenu_CopyWriteUpdate_Data_0x232_

SePitEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB68_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x28C_
	jp	SeMenu_CopyWriteUpdate_Data_0x233_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x69_
	jp	SeMenu_CopyWriteUpdate_Data_0x23D_

SePitLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB78_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x336_
	jp	SeMenu_CopyWriteUpdate_Data_0x23E_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x97_
	jp	SeMenu_CopyWriteUpdate_Data_0x248_

SeAmpAmp1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB88_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x43E_
	jp	SeMenu_CopyWriteUpdate_Data_0x249_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x33_
	jp	SeMenu_CopyWriteUpdate_Data_0x253_

SeAmpAmp2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB98_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x58E_
	jp	SeMenu_CopyWriteUpdate_Data_0x254_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x61_
	jp	SeMenu_CopyWriteUpdate_Data_0x25E_

SeAmpEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBA8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x62F_
	jp	SeMenu_CopyWriteUpdate_Data_0x25F_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x8F_
	jp	SeMenu_CopyWriteUpdate_Data_0x269_

SeAmpEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBB8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x72B_
	jp	SeMenu_CopyWriteUpdate_Data_0x26A_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0xBD_
	jp	SeMenu_CopyWriteUpdate_Data_0x274_

SeAmpLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBC8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x7D6_
	jp	SeMenu_CopyWriteUpdate_Data_0x275_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0xEB_
	jp	SeMenu_CopyWriteUpdate_Data_0x27F_

SeFilLpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBD8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLpq1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x9AA_
	jp	SeMenu_CopyWriteUpdate_Data_0x2D8_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x10DE_
	jp	SeMenu_CopyWriteUpdate_Data_0x2E2_

SeFilHpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBE8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilHpq1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xAE6_
	jp	SeMenu_CopyWriteUpdate_Data_0x2E3_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x110C_
	jp	SeMenu_CopyWriteUpdate_Data_0x2ED_

SeFilL241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBF8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilL241TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB01_
	jp	SeMenu_CopyWriteUpdate_Data_0x2EE_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x113A_
	jp	SeMenu_CopyWriteUpdate_Data_0x2F8_

SeFilH241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC08_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilH241TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB18_
	jp	SeMenu_CopyWriteUpdate_Data_0x2F9_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1168_
	jp	SeMenu_CopyWriteUpdate_Data_0x303_

SeFilBpf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC18_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBpf1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB2F_
	jp	SeMenu_CopyWriteUpdate_Data_0x304_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1196_
	jp	SeMenu_CopyWriteUpdate_Data_0x30E_

SeFilBcf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC28_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBcf1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB42_
	jp	SeMenu_CopyWriteUpdate_Data_0x30F_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x11C4_
	jp	SeMenu_CopyWriteUpdate_Data_0x319_

SeFilFil2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC38_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilFil2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB51_
	jp	SeMenu_CopyWriteUpdate_Data_0x31A_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x11F2_
	jp	SeMenu_CopyWriteUpdate_Data_0x324_

SeFilEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC48_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xBF2_
	jp	SeMenu_CopyWriteUpdate_Data_0x325_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1220_
	jp	SeMenu_CopyWriteUpdate_Data_0x32F_

SeFilEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC58_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xC88_
	jp	SeMenu_CopyWriteUpdate_Data_0x330_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x124E_
	jp	SeMenu_CopyWriteUpdate_Data_0x33A_

SeFilLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC68_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xD32_
	jp	SeMenu_CopyWriteUpdate_Data_0x33B_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x127C_
	jp	SeMenu_CopyWriteUpdate_Data_0x345_

SeDigEffTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC78_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeDigEffTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data_0x114_
	jp	SeMenu_CopyWriteUpdate_Data_0x355_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1E04_
	jp	SeMenu_CopyWriteUpdate_Data_0x35F_

SeCtr2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC88_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x7DC_
	jp	SeMenu_CopyWriteUpdate_Data_0x28B_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x36B_
	jp	SeMenu_CopyWriteUpdate_Data_0x295_

SeCtr3TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC98_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr3TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x966_
	jp	SeMenu_CopyWriteUpdate_Data_0x296_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x399_
	jp	SeMenu_CopyWriteUpdate_Data_0x2A0_

SeCopyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCA8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCopyTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data_0x1B9_
	jp	SeMenu_CopyWriteUpdate_Data_0x360_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1D7A_
	jp	SeMenu_CopyWriteUpdate_Data_0x36A_

SeWrtMemTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCB8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeWrtMemTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data
	jp	SeMenu_CopyWriteUpdate_Data_0x346_
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1DA8_
	jp	SeMenu_CopyWriteUpdate_Data_0x347_

SeWrtSndTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCC8_
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; End of Sound Editor routines

