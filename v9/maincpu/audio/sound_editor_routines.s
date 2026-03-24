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
	jp	0xf0bbd6
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0bf46
	jp	0xf0bbe0

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
	jp	0xf0bd0e
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0d710
	jp	0xf0bd18

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
	jp	0xf0bc65
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0c6d9
	jp	0xf0bc6f

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
	jp	0xf0bc70
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0c707
	jp	0xf0bc7a

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
	jp	0xf0b630
	jp	0xf0bc7b
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0c735
	jp	0xf0bc85

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
	jp	0xf0b70f
	jp	0xf0bc86
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0c763
	jp	0xf0bc90

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
	jp	0xf0bc91
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0c791
	jp	0xf0bc9b

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
	jp	0xf0a786
	jp	0xf0bbe1
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf09ad0
	jp	0xf0bbeb

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
	jp	0xf0a89b
	jp	0xf0bbec
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf09afe
	jp	0xf0bbf6

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
	jp	0xf0a931
	jp	0xf0bbf7
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf09b2c
	jp	0xf0bc01

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
	jp	0xf0a9db
	jp	0xf0bc02
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf09b5a
	jp	0xf0bc0c

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
	jp	0xf0aae3
	jp	0xf0bc0d
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf03db3
	jp	0xf0bc17

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
	jp	0xf0ac33
	jp	0xf0bc18
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf03de1
	jp	0xf0bc22

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
	jp	0xf0acd4
	jp	0xf0bc23
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf03e0f
	jp	0xf0bc2d

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
	jp	0xf0add0
	jp	0xf0bc2e
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf03e3d
	jp	0xf0bc38

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
	jp	0xf0ae7b
	jp	0xf0bc39
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf03e6b
	jp	0xf0bc43

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
	jp	0xf0b04f
	jp	0xf0bc9c
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04e5e
	jp	0xf0bca6

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
	jp	0xf0b18b
	jp	0xf0bca7
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04e8c
	jp	0xf0bcb1

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
	jp	0xf0b1a6
	jp	0xf0bcb2
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04eba
	jp	0xf0bcbc

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
	jp	0xf0b1bd
	jp	0xf0bcbd
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04ee8
	jp	0xf0bcc7

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
	jp	0xf0b1d4
	jp	0xf0bcc8
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04f16
	jp	0xf0bcd2

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
	jp	0xf0b1e7
	jp	0xf0bcd3
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04f44
	jp	0xf0bcdd

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
	jp	0xf0b1f6
	jp	0xf0bcde
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04f72
	jp	0xf0bce8

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
	jp	0xf0b297
	jp	0xf0bce9
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04fa0
	jp	0xf0bcf3

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
	jp	0xf0b32d
	jp	0xf0bcf4
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04fce
	jp	0xf0bcfe

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
	jp	0xf0b3d7
	jp	0xf0bcff
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf04ffc
	jp	0xf0bd09

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
	jp	0xf0bad8
	jp	0xf0bd19
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0d7c8
	jp	0xf0bd23

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
	jp	0xf0ae81
	jp	0xf0bc4f
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0bd2f
	jp	0xf0bc59

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
	jp	0xf0b00b
	jp	0xf0bc5a
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0bd5d
	jp	0xf0bc64

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
	jp	0xf0bb7d
	jp	0xf0bd24
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0d73e
	jp	0xf0bd2e

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
	jp	0xf0bd0a
	ld	wa, (xsp+4)
	ld	bc, (xsp+6)
	jp	0xf0d76c
	jp	0xf0bd0b

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

