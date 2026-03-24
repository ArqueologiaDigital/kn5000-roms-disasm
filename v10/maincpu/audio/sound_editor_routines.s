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
	ld xiy, GUI_DisplayStructData_0xAD8
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
	jp	SeMenu_CopyWriteUpdate_Data_0x212
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x582
	jp	SeMenu_CopyWriteUpdate_Data_0x21C

SeEasyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAE8
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
	jp	SeMenu_CopyWriteUpdate_Data_0x34A
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1D4C
	jp	SeMenu_CopyWriteUpdate_Data_0x354

SeTonTon1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xAF8
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
	jp	SeMenu_CopyWriteUpdate_Data_0x2A1
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD15
	jp	SeMenu_CopyWriteUpdate_Data_0x2AB

SeTonTon2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB08
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
	jp	SeMenu_CopyWriteUpdate_Data_0x2AC
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD43
	jp	SeMenu_CopyWriteUpdate_Data_0x2B6

SeTonRan1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB18
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan1TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data_0xDC
	jp	SeMenu_CopyWriteUpdate_Data_0x2B7
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD71
	jp	SeMenu_CopyWriteUpdate_Data_0x2C1

SeTonRan2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB28
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeTonRan2TitleFunc_DisplayData:
	jp	SeMenu_AltUpdate_Data_0x1BB
	jp	SeMenu_CopyWriteUpdate_Data_0x2C2
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xD9F
	jp	SeMenu_CopyWriteUpdate_Data_0x2CC

SeTonHyb1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB38
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
	jp	SeMenu_CopyWriteUpdate_Data_0x2CD
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0xDCD
	jp	SeMenu_CopyWriteUpdate_Data_0x2D7

SePitPit1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB48
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitPit1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xE1
	jp	SeMenu_CopyWriteUpdate_Data_0x21D
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0xD
	jp	SeMenu_CopyWriteUpdate_Data_0x227

SePitEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB58
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x1F6
	jp	SeMenu_CopyWriteUpdate_Data_0x228
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x3B
	jp	SeMenu_CopyWriteUpdate_Data_0x232

SePitEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB68
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x28C
	jp	SeMenu_CopyWriteUpdate_Data_0x233
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x69
	jp	SeMenu_CopyWriteUpdate_Data_0x23D

SePitLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB78
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SePitLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x336
	jp	SeMenu_CopyWriteUpdate_Data_0x23E
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_RefreshPartDisplay_Data_0x97
	jp	SeMenu_CopyWriteUpdate_Data_0x248

SeAmpAmp1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB88
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x43E
	jp	SeMenu_CopyWriteUpdate_Data_0x249
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x33
	jp	SeMenu_CopyWriteUpdate_Data_0x253

SeAmpAmp2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xB98
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpAmp2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x58E
	jp	SeMenu_CopyWriteUpdate_Data_0x254
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x61
	jp	SeMenu_CopyWriteUpdate_Data_0x25E

SeAmpEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBA8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x62F
	jp	SeMenu_CopyWriteUpdate_Data_0x25F
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x8F
	jp	SeMenu_CopyWriteUpdate_Data_0x269

SeAmpEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBB8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x72B
	jp	SeMenu_CopyWriteUpdate_Data_0x26A
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0xBD
	jp	SeMenu_CopyWriteUpdate_Data_0x274

SeAmpLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBC8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeAmpLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x7D6
	jp	SeMenu_CopyWriteUpdate_Data_0x275
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0xEB
	jp	SeMenu_CopyWriteUpdate_Data_0x27F

SeFilLpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBD8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLpq1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x9AA
	jp	SeMenu_CopyWriteUpdate_Data_0x2D8
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x10DE
	jp	SeMenu_CopyWriteUpdate_Data_0x2E2

SeFilHpq1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBE8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilHpq1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xAE6
	jp	SeMenu_CopyWriteUpdate_Data_0x2E3
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x110C
	jp	SeMenu_CopyWriteUpdate_Data_0x2ED

SeFilL241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xBF8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilL241TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB01
	jp	SeMenu_CopyWriteUpdate_Data_0x2EE
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x113A
	jp	SeMenu_CopyWriteUpdate_Data_0x2F8

SeFilH241TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC08
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilH241TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB18
	jp	SeMenu_CopyWriteUpdate_Data_0x2F9
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1168
	jp	SeMenu_CopyWriteUpdate_Data_0x303

SeFilBpf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC18
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBpf1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB2F
	jp	SeMenu_CopyWriteUpdate_Data_0x304
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1196
	jp	SeMenu_CopyWriteUpdate_Data_0x30E

SeFilBcf1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC28
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilBcf1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB42
	jp	SeMenu_CopyWriteUpdate_Data_0x30F
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x11C4
	jp	SeMenu_CopyWriteUpdate_Data_0x319

SeFilFil2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC38
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilFil2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xB51
	jp	SeMenu_CopyWriteUpdate_Data_0x31A
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x11F2
	jp	SeMenu_CopyWriteUpdate_Data_0x324

SeFilEnv1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC48
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xBF2
	jp	SeMenu_CopyWriteUpdate_Data_0x325
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x1220
	jp	SeMenu_CopyWriteUpdate_Data_0x32F

SeFilEnv2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC58
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilEnv2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xC88
	jp	SeMenu_CopyWriteUpdate_Data_0x330
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x124E
	jp	SeMenu_CopyWriteUpdate_Data_0x33A

SeFilLfo1TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC68
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeFilLfo1TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0xD32
	jp	SeMenu_CopyWriteUpdate_Data_0x33B
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	Scoop_SoundEditorData_0x127C
	jp	SeMenu_CopyWriteUpdate_Data_0x345

SeDigEffTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC78
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeDigEffTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data_0x114
	jp	SeMenu_CopyWriteUpdate_Data_0x355
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1E04
	jp	SeMenu_CopyWriteUpdate_Data_0x35F

SeCtr2TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC88
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr2TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x7DC
	jp	SeMenu_CopyWriteUpdate_Data_0x28B
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x36B
	jp	SeMenu_CopyWriteUpdate_Data_0x295

SeCtr3TitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xC98
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCtr3TitleFunc_DisplayData:
	jp	UpdSeSel_ExtendedOps_Data_0x966
	jp	SeMenu_CopyWriteUpdate_Data_0x296
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x399
	jp	SeMenu_CopyWriteUpdate_Data_0x2A0

SeCopyTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCA8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

SeCopyTitleFunc_DisplayData:
	jp	SeMenu_CopyWriteUpdate_Data_0x1B9
	jp	SeMenu_CopyWriteUpdate_Data_0x360
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1D7A
	jp	SeMenu_CopyWriteUpdate_Data_0x36A

SeWrtMemTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCB8
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
	jp	SeMenu_CopyWriteUpdate_Data_0x346
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	SeMenu_CopyWriteUpdate_Data_0x1DA8
	jp	SeMenu_CopyWriteUpdate_Data_0x347

SeWrtSndTitleFunc:
	lda xsp, (xsp - 16)
	ld xhl, xbc
	ld xiy, GUI_DisplayStructData_0xCC8
	ld xix, xsp
	ldw bc, 0x8
	ldirw
	lda xwa, (xsp)
	ld xbc, xhl
	call DirmdEmulator_Entry
	lda xsp, (xsp + 16)
	ret

; End of Sound Editor routines

